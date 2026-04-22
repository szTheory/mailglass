defmodule Mailglass.Properties.IdempotencyConvergenceTest do
  @moduledoc """
  Property test for PERSIST-03 / MAIL-03.

  > Generate 1000 sequences of (webhook_event, replay_count_1..10) and
  > assert that applying any sequence converges to the same final state
  > as applying each event once. (ROADMAP Phase 2 success criterion 2)

  Tests the combined behavior of:
  1. `Mailglass.Events.append/1` with `:idempotency_key`
  2. UNIQUE partial index `mailglass_events_idempotency_key_idx`
  3. `on_conflict: :nothing` + `{:unsafe_fragment, ...}` conflict target
  4. Replay detection + refetch via the `inserted_at: nil` sentinel
     (UUIDv7 variant of the `id: nil` footgun — see Mailglass.Events
     moduledoc "The replay-detection sentinel")

  The "same final state" assertion compares the row set by
  `(idempotency_key)` — after applying each input once vs applying each
  input N times shuffled, the persisted set MUST be identical.
  """

  # Note: intentionally NOT using Mailglass.DataCase. DataCase sets
  # sandbox mode to :manual and starts a per-test sandbox owner, but
  # this property test runs 1000 iterations with a TRUNCATE between
  # each — that either thrashes the sandbox transaction or deadlocks
  # on connection reuse. Following the same sandbox-mode flip as
  # Plan 02's migration_test (mode: :auto in setup, restore :manual
  # on_exit) so each iteration gets a real connection and the
  # TRUNCATE commits. Async is false because mode :auto disables
  # ownership tracking for the duration.
  use ExUnit.Case, async: false

  use ExUnitProperties

  import Ecto.Query

  alias Ecto.Adapters.SQL.Sandbox
  alias Mailglass.Events
  alias Mailglass.Events.Event
  alias Mailglass.TestRepo

  setup do
    Sandbox.mode(TestRepo, :auto)

    # Wipe any residue from other tests so this property starts clean.
    TestRepo.query!("TRUNCATE TABLE mailglass_events", [])

    on_exit(fn ->
      # Leave the events table empty for the next test run and restore
      # :manual mode so DataCase-using tests in the same suite remain
      # isolated under the sandbox pattern.
      TestRepo.query!("TRUNCATE TABLE mailglass_events", [])
      Sandbox.mode(TestRepo, :manual)
    end)

    :ok
  end

  # Restrict to a subset of event types to keep generator cardinality sane.
  @event_types [:queued, :dispatched, :delivered, :bounced, :complained, :opened]

  @tag timeout: :infinity
  property "convergence: apply_all(events) == apply_all(replays_shuffled)" do
    check all(
            events <- list_of(event_attrs_gen(), min_length: 1, max_length: 20),
            replay_count <- integer(1..10),
            max_runs: 1000
          ) do
      # Wipe events table between iterations to isolate state.
      # (The trigger prevents UPDATE/DELETE only; we need TRUNCATE with
      # CASCADE via raw SQL because DELETE fires the trigger.)
      TestRepo.query!("TRUNCATE TABLE mailglass_events", [])

      # Pass 1: apply each event exactly once.
      fresh_keys = Enum.map(events, &apply_and_key/1)
      fresh_snapshot = snapshot()

      # Wipe + Pass 2: apply N replays of the sequence, shuffled.
      TestRepo.query!("TRUNCATE TABLE mailglass_events", [])

      replayed =
        events
        |> List.duplicate(replay_count)
        |> List.flatten()
        |> Enum.shuffle()

      Enum.each(replayed, &apply_and_key/1)
      replayed_snapshot = snapshot()

      # The keyed snapshots (by idempotency_key) must be identical in both passes.
      assert Enum.sort(fresh_keys) == Enum.sort(Map.keys(fresh_snapshot))

      assert fresh_snapshot == replayed_snapshot,
             """
             Convergence failed!
             fresh keys: #{inspect(Map.keys(fresh_snapshot) |> Enum.sort())}
             replayed keys: #{inspect(Map.keys(replayed_snapshot) |> Enum.sort())}
             """
    end
  end

  defp event_attrs_gen do
    gen all(
          type <- member_of(@event_types),
          key_raw <- string(:alphanumeric, min_length: 8, max_length: 32),
          occurred_offset_sec <- integer(-60..60)
        ) do
      %{
        type: type,
        tenant_id: "prop-test-tenant",
        occurred_at: DateTime.add(DateTime.utc_now(), occurred_offset_sec, :second),
        # Disambiguate by type so the same raw key across different types
        # produces distinct idempotency keys. Prevents spurious "replay-of-
        # different-type" coincidence collisions from failing the
        # convergence assertion (IN-02).
        idempotency_key: "#{type}-#{key_raw}",
        raw_payload: %{},
        normalized_payload: %{},
        metadata: %{}
      }
    end
  end

  # Returns the idempotency_key used for this event.
  defp apply_and_key(%{idempotency_key: key} = attrs) do
    {:ok, _event} = Events.append(attrs)
    key
  end

  # Snapshot as Map{idempotency_key => event_type_atom}. Comparing
  # snapshots (not row structs) tolerates inserted_at drift while proving
  # convergence on the stable fields.
  defp snapshot do
    TestRepo.all(
      from(e in Event,
        where: not is_nil(e.idempotency_key),
        select: {e.idempotency_key, e.type}
      )
    )
    |> Map.new()
  end
end
