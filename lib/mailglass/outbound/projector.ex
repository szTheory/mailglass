defmodule Mailglass.Outbound.Projector do
  @moduledoc """
  The single place where `mailglass_deliveries` projection columns are
  updated (D-14). Consumed by Phase 3 dispatch, Phase 4 webhook ingest,
  and Phase 4+ orphan reconciliation. No projection update happens
  outside this module — a Phase 6 candidate Credo check
  (`NoProjectorOutsideOutbound`) will enforce at lint time.

  ## App-level monotonic rule (D-15)

  - `last_event_at` — `max(current, event.occurred_at)`; monotonic.
  - `last_event_type` — advances together with `last_event_at`. The two
    fields are a joined "latest observed event" pointer: an earlier
    out-of-order event moves neither. This keeps the denormalized
    summary internally consistent with the event-ledger truth (WR-02).
  - `dispatched_at` / `delivered_at` / `bounced_at` / `complained_at` /
    `suppressed_at` — set ONCE when the matching event type arrives;
    never overwritten. Note that `:rejected` and `:failed` events DO
    flip `terminal` but have no corresponding `*_at` column (D-13
    scoped five lifecycle timestamps) — querying "when did this
    delivery fail?" joins the event ledger on (delivery_id, type)
    rather than reading a single column on `mailglass_deliveries`
    (IN-07).
  - `terminal` — flips `false → true` on any of
    `:delivered | :bounced | :complained | :rejected | :failed |
    :suppressed`. Never flips back.

  Why app-enforced: provider event ordering is non-monotonic in
  practice (`:opened` arriving before `:delivered` is routine during
  webhook batches). DB CHECK constraints on lifecycle ordering would
  cause production failures on valid provider behavior.

  ## Optimistic locking (D-18)

  Every returned changeset chains `Ecto.Changeset.optimistic_lock(:lock_version)`.
  Concurrent dispatch attempts on the same delivery raise
  `Ecto.StaleEntryError` on the loser. Phase 3's dispatch worker adds
  the single-retry; Phase 2 proves the mechanism works.

  ## Telemetry

  Emits `[:mailglass, :persist, :delivery, :update_projections, :*]` with
  `tenant_id` + `delivery_id` metadata per Phase 1 D-31 whitelist.
  """

  alias Mailglass.Events.Event
  alias Mailglass.Outbound.Delivery

  @terminal_event_types ~w[delivered bounced complained rejected failed suppressed]a

  @doc """
  Returns a changeset that applies D-15 monotonic projection updates for
  the given `%Delivery{}` against `%Event{}`. The changeset chains
  `Ecto.Changeset.optimistic_lock(:lock_version)` so concurrent updates
  on the same delivery raise `Ecto.StaleEntryError` on the loser.
  """
  @doc since: "0.1.0"
  @spec update_projections(Delivery.t(), Event.t()) :: Ecto.Changeset.t()
  def update_projections(%Delivery{} = delivery, %Event{} = event) do
    Mailglass.Telemetry.persist_span(
      [:delivery, :update_projections],
      %{tenant_id: delivery.tenant_id, delivery_id: delivery.id},
      fn ->
        delivery
        |> Ecto.Changeset.change()
        |> maybe_advance_last_event(event)
        |> maybe_set_once_timestamp(event)
        |> maybe_flip_terminal(event)
        |> Ecto.Changeset.optimistic_lock(:lock_version)
      end
    )
  end

  # `last_event_at` + `last_event_type` advance together, only when the
  # incoming event's `occurred_at` is strictly greater than the current
  # stamp (monotonic max). An earlier out-of-order event moves neither —
  # keeping the two fields internally consistent so the denormalized
  # summary never disagrees with the event ledger about which event is
  # "latest" (WR-02). If only a type arrives (no timestamp), neither
  # field moves; if only a timestamp arrives (no type), neither field
  # moves.
  defp maybe_advance_last_event(changeset, %Event{type: type, occurred_at: occurred_at})
       when not is_nil(type) and not is_nil(occurred_at) do
    current_at = Ecto.Changeset.get_field(changeset, :last_event_at)

    if is_nil(current_at) or DateTime.compare(occurred_at, current_at) == :gt do
      changeset
      |> Ecto.Changeset.put_change(:last_event_at, occurred_at)
      |> Ecto.Changeset.put_change(:last_event_type, type)
    else
      changeset
    end
  end

  defp maybe_advance_last_event(changeset, _), do: changeset

  # Lifecycle timestamps (`dispatched_at`, `delivered_at`, etc.) are set
  # ONCE when the matching event type arrives and never overwritten.
  # Late events of the same type (duplicates, reorders) preserve the
  # first occurrence.
  defp maybe_set_once_timestamp(changeset, %Event{type: type, occurred_at: occurred_at})
       when not is_nil(occurred_at) do
    case timestamp_field_for(type) do
      nil ->
        changeset

      field ->
        case Ecto.Changeset.get_field(changeset, field) do
          nil -> Ecto.Changeset.put_change(changeset, field, occurred_at)
          _set -> changeset
        end
    end
  end

  defp maybe_set_once_timestamp(changeset, _), do: changeset

  defp timestamp_field_for(:dispatched), do: :dispatched_at
  defp timestamp_field_for(:delivered), do: :delivered_at
  defp timestamp_field_for(:bounced), do: :bounced_at
  defp timestamp_field_for(:complained), do: :complained_at
  defp timestamp_field_for(:suppressed), do: :suppressed_at
  defp timestamp_field_for(_), do: nil

  # `terminal` is a one-way latch: false → true on a terminal event; never
  # reversed. A late `:opened` after `:bounced` leaves `terminal` intact.
  defp maybe_flip_terminal(changeset, %Event{type: type}) when type in @terminal_event_types do
    case Ecto.Changeset.get_field(changeset, :terminal) do
      false -> Ecto.Changeset.put_change(changeset, :terminal, true)
      true -> changeset
      nil -> Ecto.Changeset.put_change(changeset, :terminal, true)
    end
  end

  defp maybe_flip_terminal(changeset, _), do: changeset
end
