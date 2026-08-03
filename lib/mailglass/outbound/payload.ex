defmodule Mailglass.Outbound.Payload do
  use Mailglass.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Mailglass.{Repo, Tenancy}
  alias Mailglass.Outbound.Envelope

  schema "mailglass_outbound_payloads" do
    field(:tenant_id, :string)
    field(:delivery_id, Ecto.UUID)
    field(:envelope_version, :integer)
    field(:envelope_digest, :string)
    field(:envelope, :map)
    field(:scrubbed_at, :utc_datetime_usec)
    field(:expires_at, :utc_datetime_usec)
    timestamps(type: :utc_datetime_usec)
  end

  def changeset(payload, attrs),
    do:
      payload
      |> cast(attrs, [
        :tenant_id,
        :delivery_id,
        :envelope_version,
        :envelope_digest,
        :envelope,
        :scrubbed_at,
        :expires_at
      ])
      |> validate_required([
        :tenant_id,
        :delivery_id,
        :envelope_version,
        :envelope_digest,
        :envelope
      ])
      |> unique_constraint(:delivery_id, name: :mailglass_outbound_payloads_delivery_id_idx)

  def from_envelope(tenant_id, delivery_id, envelope, _opts \\ []) do
    changeset(%__MODULE__{}, %{
      tenant_id: tenant_id,
      delivery_id: delivery_id,
      envelope_version: Envelope.version(),
      envelope_digest: Envelope.digest(envelope),
      envelope: envelope
    })
  end

  def fetch_for_delivery(tenant_id, delivery_id) do
    query =
      from(p in __MODULE__, where: p.tenant_id == ^tenant_id and p.delivery_id == ^delivery_id)

    case Repo.one(Tenancy.scope(query, tenant_id)) do
      nil ->
        {:error, :not_found}

      %__MODULE__{} = payload ->
        case Envelope.digest(payload.envelope) do
          digest when is_binary(digest) and digest == payload.envelope_digest ->
            Envelope.load(payload.envelope)

          _ when payload.envelope_version == 1 ->
            # jsonb discarded the original numeric spelling. A mismatched V1
            # digest cannot distinguish corruption from a pre-V2 finite float,
            # so fail terminally instead of guessing or retrying indefinitely.
            {:error, :legacy_integrity_unverifiable}

          _ ->
            {:error, :integrity_failed}
        end

      _ ->
        {:error, :integrity_failed}
    end
  end
end
