defmodule Mailglass.Outbound.Delivery do
  @moduledoc """
  One row per (Message, recipient, provider) tuple. Mutable: projection
  columns are updated by `Mailglass.Outbound.Projector` (Plan 06).

  Field order per CONTEXT.md "Claude's Discretion":
  id → tenant_id → foreign keys → state → metadata/flags → timestamps.

  `@primary_key` is UUIDv7 via the `Mailglass.Schema` macro.

  ## Atom Sets

  - `:stream` — `:transactional | :operational | :bulk` (D-10)
  - `:last_event_type` — full Anymail event taxonomy + mailglass
    internal `:dispatched` / `:suppressed` (D-14 project-level)

  ## Projection columns (D-13)

  `dispatched_at`, `delivered_at`, `bounced_at`, `complained_at`,
  `suppressed_at`, `terminal`, `last_event_type`, `last_event_at` are the
  only Elixir-modifiable facts. `Mailglass.Outbound.Projector` (Plan 06)
  owns writes to these columns; `metadata` is a free-form jsonb bag for
  adopter-supplied non-PII extras.

  ## Optimistic locking (D-18)

  `:lock_version` defaults to `1`. Consumers chain
  `Ecto.Changeset.optimistic_lock(:lock_version)` onto the changeset when
  updating — concurrent dispatch attempts raise `Ecto.StaleEntryError` on
  the loser.
  """
  use Mailglass.Schema
  import Ecto.Changeset

  @event_types [
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
    :unknown,
    :dispatched,
    :suppressed
  ]

  @streams [:transactional, :operational, :bulk]

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          tenant_id: String.t() | nil,
          mailable: String.t() | nil,
          stream: :transactional | :operational | :bulk | nil,
          recipient: String.t() | nil,
          recipient_domain: String.t() | nil,
          provider: String.t() | nil,
          provider_message_id: String.t() | nil,
          last_event_type: atom() | nil,
          last_event_at: DateTime.t() | nil,
          terminal: boolean() | nil,
          dispatched_at: DateTime.t() | nil,
          delivered_at: DateTime.t() | nil,
          bounced_at: DateTime.t() | nil,
          complained_at: DateTime.t() | nil,
          suppressed_at: DateTime.t() | nil,
          metadata: map(),
          lock_version: integer() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "mailglass_deliveries" do
    field(:tenant_id, :string)
    field(:mailable, :string)
    field(:stream, Ecto.Enum, values: @streams)
    field(:recipient, :string)
    field(:recipient_domain, :string)
    field(:provider, :string)
    field(:provider_message_id, :string)
    field(:last_event_type, Ecto.Enum, values: @event_types)
    field(:last_event_at, :utc_datetime_usec)
    field(:terminal, :boolean, default: false)
    field(:dispatched_at, :utc_datetime_usec)
    field(:delivered_at, :utc_datetime_usec)
    field(:bounced_at, :utc_datetime_usec)
    field(:complained_at, :utc_datetime_usec)
    field(:suppressed_at, :utc_datetime_usec)
    field(:metadata, :map, default: %{})
    field(:lock_version, :integer, default: 1)
    timestamps(type: :utc_datetime_usec)
  end

  @required ~w[tenant_id mailable stream recipient last_event_type last_event_at]a
  @cast @required ++
          ~w[recipient_domain provider provider_message_id terminal
             dispatched_at delivered_at bounced_at complained_at
             suppressed_at metadata]a

  @doc """
  Builds a changeset for a new `%Delivery{}` from an attr map.

  Auto-populates `:recipient_domain` from `:recipient` (denormalization
  per D-13) — a cheap cast-time computation that saves a `SPLIT_PART()`
  at query time for rate-limit and analytics reads.
  """
  @doc since: "0.1.0"
  @spec changeset(map()) :: Ecto.Changeset.t()
  @spec changeset(t(), map()) :: Ecto.Changeset.t()
  def changeset(attrs) when is_map(attrs), do: changeset(%__MODULE__{}, attrs)

  def changeset(%__MODULE__{} = delivery, attrs) when is_map(attrs) do
    delivery
    |> cast(attrs, @cast)
    |> validate_required(@required)
    |> put_recipient_domain()
  end

  # Denormalize the recipient domain on insert. Cheap, and saves a
  # SPLIT_PART() at query time for rate-limit + analytics reads.
  defp put_recipient_domain(changeset) do
    cond do
      get_change(changeset, :recipient_domain) ->
        changeset

      email = get_change(changeset, :recipient) ->
        case String.split(email, "@", parts: 2) do
          [_local, domain] ->
            put_change(changeset, :recipient_domain, String.downcase(domain))

          _ ->
            add_error(changeset, :recipient, "must contain an @")
        end

      true ->
        changeset
    end
  end

  @doc "Closed event-type atom set. Tested against api_stability.md (Phase 6 check)."
  @doc since: "0.1.0"
  @spec __event_types__() :: [atom()]
  def __event_types__, do: @event_types

  @doc "Closed stream atom set."
  @doc since: "0.1.0"
  @spec __streams__() :: [atom()]
  def __streams__, do: @streams
end
