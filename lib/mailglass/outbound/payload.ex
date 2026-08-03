defmodule Mailglass.Outbound.Payload do
  @moduledoc """
  Durable, privacy-bounded storage for outbound delivery envelopes.

  Payload rows retain dispatch content only while it is needed and transition
  to content-free lifecycle tombstones after settlement or expiry.
  """

  use Mailglass.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Mailglass.{Clock, Repo, Tenancy}
  alias Mailglass.Outbound.Envelope
  alias Mailglass.Outbound.PayloadLifecycle

  @lifecycle_states [
    :recoverable,
    :dispatching,
    :scrubbed,
    :expired,
    :terminal,
    :discarded,
    :abandoned,
    :uncertain,
    :legacy
  ]
  @reason_classes [
    :dispatch_claimed,
    :accepted,
    :retention_expired,
    :provider_client_rejected,
    :pre_dispatch_failure,
    :payload_missing,
    :payload_corrupt,
    :payload_unsupported_version,
    :payload_expired,
    :payload_scrubbed,
    :job_discarded,
    :job_abandoned,
    :provider_acceptance_unknown,
    :legacy_queued
  ]

  schema "mailglass_outbound_payloads" do
    field(:tenant_id, :string)
    field(:delivery_id, Ecto.UUID)
    field(:envelope_version, :integer)
    field(:envelope_digest, :string)
    field(:envelope, :map)
    field(:scrubbed_at, :utc_datetime_usec)
    field(:expires_at, :utc_datetime_usec)
    field(:lifecycle_state, Ecto.Enum, values: @lifecycle_states, default: :recoverable)
    field(:reason_class, Ecto.Enum, values: @reason_classes)
    field(:claimed_at, :utc_datetime_usec)
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
        :expires_at,
        :lifecycle_state,
        :reason_class,
        :claimed_at
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

      %__MODULE__{lifecycle_state: :recoverable} = payload ->
        case PayloadLifecycle.recovery_eligibility(payload) do
          :claimable -> load_envelope(payload)
          :expired -> {:error, :expired}
        end

      %__MODULE__{lifecycle_state: :scrubbed} ->
        {:error, :scrubbed}

      %__MODULE__{lifecycle_state: :expired} ->
        {:error, :expired}

      %__MODULE__{lifecycle_state: :dispatching} ->
        {:error, :dispatching}

      %__MODULE__{} ->
        {:error, :unavailable}

      _ ->
        {:error, :integrity_failed}
    end
  end

  @doc false
  def load_claimed(%__MODULE__{lifecycle_state: :dispatching} = payload), do: load_envelope(payload)
  def load_claimed(_payload), do: {:error, :integrity_failed}

  defp load_envelope(%__MODULE__{} = payload) do
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
  end

  @doc false
  @spec claim(String.t(), Ecto.UUID.t()) :: {:ok, %__MODULE__{}} | {:error, term()}
  def claim(tenant_id, delivery_id) do
    query =
      from(p in __MODULE__,
        where:
          p.tenant_id == ^tenant_id and p.delivery_id == ^delivery_id and
            p.lifecycle_state == :recoverable
      )
      |> Tenancy.scope(tenant_id)

    now = Clock.utc_now()

    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.update_all(
        :claim,
        query,
        [set: [lifecycle_state: :dispatching, reason_class: :dispatch_claimed, claimed_at: now]],
        Repo.multi_opts()
      )
      |> Ecto.Multi.run(:payload, fn repo, %{claim: {count, _}} ->
        case count do
          1 ->
            {:ok,
             repo.one!(
               from(p in __MODULE__, where: p.delivery_id == ^delivery_id),
               Repo.multi_opts()
             )}

          _ ->
            {:error, claim_error(tenant_id, delivery_id)}
        end
      end)

    case Repo.multi(multi) do
      {:ok, %{payload: payload}} -> {:ok, payload}
      {:error, :payload, reason, _} -> {:error, reason}
      {:error, _step, reason, _} -> {:error, reason}
    end
  end

  @doc false
  def scrub_changeset(%__MODULE__{} = payload) do
    payload
    |> change(%{
      lifecycle_state: :scrubbed,
      reason_class: :accepted,
      envelope: nil,
      scrubbed_at: Clock.utc_now(),
      claimed_at: nil
    })
  end

  @doc false
  def settle_changeset(%__MODULE__{} = payload, state, reason) do
    attrs = %{lifecycle_state: state, reason_class: reason, claimed_at: nil}

    case PayloadLifecycle.expires_at(state) do
      nil -> change(payload, attrs)
      expires_at -> change(payload, Map.put(attrs, :expires_at, expires_at))
    end
  end

  @doc false
  def retry_changeset(%__MODULE__{} = payload) do
    change(payload, %{lifecycle_state: :recoverable, reason_class: nil, claimed_at: nil})
  end

  defp claim_error(tenant_id, delivery_id) do
    query =
      from(p in __MODULE__, where: p.tenant_id == ^tenant_id and p.delivery_id == ^delivery_id)
      |> Tenancy.scope(tenant_id)

    case Repo.one(query) do
      nil -> :not_found
      %{lifecycle_state: :dispatching} -> :already_dispatching
      %{lifecycle_state: :terminal, reason_class: reason} -> {:terminal, reason}
      %{lifecycle_state: :scrubbed} -> :already_scrubbed
      %{lifecycle_state: state} -> state
    end
  end
end
