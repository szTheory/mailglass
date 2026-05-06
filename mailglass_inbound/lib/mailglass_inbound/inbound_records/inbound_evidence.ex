defmodule MailglassInbound.InboundRecords.InboundEvidence do
  @moduledoc """
  Raw evidence row linked to one canonical inbound record.

  Stores provider-shaped payloads and debug material needed for replay,
  verification, and support without contaminating the canonical normalized row.
  """

  use MailglassInbound.Schema

  import Ecto.Changeset

  alias MailglassInbound.InboundRecords.InboundRecord
  alias MailglassInbound.InboundRecords.ReplayRun

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          tenant_id: String.t() | nil,
          inbound_record_id: Ecto.UUID.t() | nil,
          provider: String.t() | nil,
          raw_payload: map(),
          raw_headers: map(),
          raw_mime: binary() | nil,
          verification_facts: map(),
          parse_warnings: map(),
          attachment_blobs: map(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "mailglass_inbound_evidence" do
    field :tenant_id, :string
    field :provider, :string
    field :raw_payload, :map, default: %{}, redact: true
    field :raw_headers, :map, default: %{}
    field :raw_mime, :binary, redact: true
    field :verification_facts, :map, default: %{}
    field :parse_warnings, :map, default: %{}
    field :attachment_blobs, :map, default: %{}

    belongs_to :inbound_record, InboundRecord
    has_many :replay_runs, ReplayRun

    timestamps()
  end

  @required ~w[tenant_id inbound_record_id provider]a
  @cast @required ++ ~w[raw_payload raw_headers raw_mime verification_facts parse_warnings attachment_blobs]a

  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> cast(attrs, @cast)
    |> validate_required(@required)
    |> foreign_key_constraint(:inbound_record_id)
  end
end
