defmodule MailglassInbound.InboundRecords.InboundRecord do
  @moduledoc """
  Canonical normalized inbound row.

  This schema stores adopter-facing truth only. Raw provider payloads, raw MIME,
  verification facts, parse warnings, and replay execution data live in
  package-local sibling tables.
  """

  use MailglassInbound.Schema

  import Ecto.Changeset

  alias MailglassInbound.InboundRecords.InboundEvidence
  alias MailglassInbound.InboundRecords.ReplayRun

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          tenant_id: String.t() | nil,
          provider: String.t() | nil,
          provider_message_id: String.t() | nil,
          message_id: String.t() | nil,
          envelope_recipient: String.t() | nil,
          from: [map()],
          to: [map()],
          cc: [map()],
          bcc: [map()],
          reply_to: [map()],
          subject: String.t() | nil,
          headers: map(),
          sent_at: DateTime.t() | nil,
          received_at: DateTime.t() | nil,
          text_body: String.t() | nil,
          html_body: String.t() | nil,
          attachments: [map()],
          suppression_flagged: boolean(),
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "mailglass_inbound_records" do
    field :tenant_id, :string
    field :provider, :string
    field :provider_message_id, :string
    field :message_id, :string
    field :envelope_recipient, :string
    field :from, {:array, :map}, default: []
    field :to, {:array, :map}, default: []
    field :cc, {:array, :map}, default: []
    field :bcc, {:array, :map}, default: []
    field :reply_to, {:array, :map}, default: []
    field :subject, :string
    field :headers, :map, default: %{}
    field :sent_at, :utc_datetime_usec
    field :received_at, :utc_datetime_usec
    field :text_body, :string
    field :html_body, :string
    field :attachments, {:array, :map}, default: []
    # IOPS-05 (the design contract): diagnostic suppression flag, set once at INSERT by
    # `Ingress.Persist`. Settable (in @cast) but never required — it defaults to
    # false so a row inserted before the column existed reads false, never nil.
    field :suppression_flagged, :boolean, default: false

    has_one :evidence, InboundEvidence
    has_many :replay_runs, ReplayRun

    timestamps()
  end

  @required ~w[tenant_id provider received_at]a
  @cast @required ++
          ~w[provider_message_id message_id envelope_recipient from to cc bcc reply_to subject
             headers sent_at text_body html_body attachments suppression_flagged]a

  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> cast(attrs, @cast)
    |> validate_required(@required)
    |> unique_constraint(:provider_message_id,
      name: :mailglass_inbound_records_postmark_idempotency_idx
    )
  end
end
