defmodule Mailglass.Events.Event do
  @moduledoc """
  Append-only row in `mailglass_events`.

  Exposes `changeset/1` for INSERTS only. There is NO update/delete
  helper — the `mailglass_events_immutable_trigger` (Plan 02) raises
  SQLSTATE 45A01 on any UPDATE/DELETE; `Mailglass.Repo.transact/1`
  (Plan 01) translates to `Mailglass.EventLedgerImmutableError`.

  Absence of an update helper also prevents code that looks like it
  could work but blows up in production.

  ## Atom Sets

  - `:type` — full Anymail taxonomy + mailglass internal `:dispatched`
    and `:suppressed` (D-14 project-level).
  - `:reject_reason` — `:invalid | :bounced | :timed_out | :blocked |
    :spam | :unsubscribed | :other` (nullable; D-14).

  ## Relationships

  `delivery_id` is a logical `:binary_id` reference — NO FK to
  `mailglass_deliveries` (ARCHITECTURE §4.3; Pitfall 4 in RESEARCH).
  Orphan webhooks insert with `delivery_id: nil` and are linked later
  by `Mailglass.Events.Reconciler` (Plan 05).

  ## Idempotency

  `:idempotency_key` is a nullable string backed by a partial UNIQUE
  index (`mailglass_events_idempotency_key_idx WHERE idempotency_key IS
  NOT NULL`). Plan 05's `Events.append/1` will pass
  `on_conflict: :nothing, conflict_target: {:unsafe_fragment,
  "(idempotency_key) WHERE idempotency_key IS NOT NULL"}` — replays are
  no-ops.
  """
  use Mailglass.Schema
  import Ecto.Changeset

  @anymail_event_types [
    :queued,
    :sent,
    :rejected,
    :failed,
    :bounced,
    :deferred,
    :delivered,
    :autoresponded,
    :opened,
    :clicked,
    :complained,
    :unsubscribed,
    :subscribed,
    :unknown
  ]

  @mailglass_internal_types [:dispatched, :suppressed]
  @event_types @anymail_event_types ++ @mailglass_internal_types

  @reject_reasons [:invalid, :bounced, :timed_out, :blocked, :spam, :unsubscribed, :other]

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          tenant_id: String.t() | nil,
          delivery_id: Ecto.UUID.t() | nil,
          type: atom() | nil,
          occurred_at: DateTime.t() | nil,
          idempotency_key: String.t() | nil,
          reject_reason: atom() | nil,
          raw_payload: map() | nil,
          normalized_payload: map(),
          metadata: map(),
          trace_id: String.t() | nil,
          needs_reconciliation: boolean() | nil,
          inserted_at: DateTime.t() | nil
        }

  schema "mailglass_events" do
    field(:tenant_id, :string)
    field(:delivery_id, :binary_id)
    field(:type, Ecto.Enum, values: @event_types)
    field(:occurred_at, :utc_datetime_usec)
    field(:idempotency_key, :string)
    field(:reject_reason, Ecto.Enum, values: @reject_reasons)
    field(:raw_payload, :map)
    field(:normalized_payload, :map, default: %{})
    field(:metadata, :map, default: %{})
    field(:trace_id, :string)
    field(:needs_reconciliation, :boolean, default: false)
    field(:inserted_at, :utc_datetime_usec, read_after_writes: true)
  end

  @required ~w[tenant_id type occurred_at]a
  @cast @required ++
          ~w[delivery_id idempotency_key reject_reason raw_payload
             normalized_payload metadata trace_id needs_reconciliation]a

  @doc """
  Builds an INSERT-only changeset for a new `%Event{}`.

  Intentionally the only public mutation point. No update or delete
  helper is exposed — UPDATE and DELETE at the Repo layer raise
  `Mailglass.EventLedgerImmutableError` via the DB trigger, and the
  Elixir surface deliberately offers no path that looks like it could
  work.
  """
  @doc since: "0.1.0"
  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> cast(attrs, @cast)
    |> validate_required(@required)
  end

  @doc "Closed type atom set (Anymail taxonomy + internal). Cross-checked in api_stability.md."
  @doc since: "0.1.0"
  @spec __types__() :: [atom()]
  def __types__, do: @event_types

  @doc "Closed reject_reason atom set."
  @doc since: "0.1.0"
  @spec __reject_reasons__() :: [atom()]
  def __reject_reasons__, do: @reject_reasons
end
