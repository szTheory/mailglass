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

  ## Test sandbox discipline

  A **shared, non-transactional** checkout through the sanctioned door
  (`Mailglass.TestSupport.SandboxOwnership.checkout!/1`):

    * `sandbox: false` keeps every write committed and unwrapped — exactly the
      semantics the pool-wide `:auto` mode this module used before gave it.
    * `shared: true` keeps the connection reachable from ExUnit's `on_exit`
      process, which is not the test process and would otherwise have no owner
      to borrow (the pool sits at `:manual` between modules).
    * `ownership_timeout:` is the whole point of the checkout — see below.
    * `TRUNCATE ... CASCADE` between iterations (the append-only trigger
      forbids UPDATE/DELETE, so TRUNCATE is the only bulk-wipe path).

  ### Why an explicit checkout at all (CI run `30564591156`, seed 961019)

  Under pool-wide `:auto` this module failed on the
  `Elixir 1.18 / OTP 27 / schema mailglass` advisory lane with

      ** (DBConnection.ConnectionError) owner #PID<0.6174.0> (:erlang) timed
         out because it owned the connection for longer than 120000ms
         (set via the :ownership_timeout option)

  after 514 of the property's 1000 runs. **This is not an ownership leak** —
  that run's `already_shared` tally was exactly 0. In `:auto` mode the
  ownership manager builds the proxy itself (`manager.ex:225-227`, the
  `:not_found when mode == :auto` clause) from `checkout_opts`, which it
  captured from the REPO's pool options back at init (`manager.ex:99`).
  `config/test.exs` sets no `:ownership_timeout`, so the bound is
  `proxy.ex:9`'s 120s default and there is **no per-module seam to raise it**:
  the only lever is repo config, which would raise the leak-detection ceiling
  for all 1500+ tests to accommodate this one. The module's
  `@moduletag timeout: :infinity` lifts ExUnit's clock and never
  db_connection's, which is why nothing here noticed.

  An explicit checkout does have that seam — `sandbox.ex:556-557` merges a
  caller's `:ownership_timeout` over the pool options for that owner alone —
  and Ecto documents precisely this remedy: *"if this is an issue for only a
  handful of long-running tests, you can pass an `:ownership_timeout` option
  when calling `Ecto.Adapters.SQL.Sandbox.checkout/2` instead of setting a
  longer timeout globally in your config"* (`sandbox.ex:262-264`).

  Verified live rather than assumed: re-running this property with the bound
  temporarily set to `2_000` fails in 2.0s with the identical exception
  (`... longer than 2000ms (set via the :ownership_timeout option)`), so the
  option demonstrably governs this owner.

  ### The bound, and the headroom behind it

  Measured end-to-end at seed 961019 — full 1000 runs, 0 failures:

    * **62.4s / 66.1s / 73.4s** across three runs on the gating toolchain
      (Elixir 1.18.4 / OTP 27, 2-vCPU container + containerized Postgres:
      `make toolchain`, see CONTRIBUTING.md).
    * **33.4s** on a 1.19.5 / OTP 28 developer box.

  The GitHub runner that failed is slower than either: 514 runs inside its 120s
  bound is 233ms/run, which projects the whole property at **~233s** there.
  Ten minutes is ~2.6x that worst observed rate and ~8x the slowest measured
  gating-toolchain run. It is also the bound
  `webhook_idempotency_convergence_test.exs` already uses for its own 1000-run
  property, so the two siblings share one number and one rationale. A property
  that genuinely hangs still dies — it just dies on evidence rather than on
  runner load.

  ### Why `sandbox: false`, and not the sibling's transactional checkout

  `webhook_idempotency_convergence_test.exs` uses a plain
  `checkout!(shared: true, ...)`, which wraps the test in a sandbox
  transaction. That shape was tried here first and **passes** — the comment
  this module used to carry, claiming a transaction "thrashes the sandbox
  transaction or deadlocks on connection reuse", was never true and has been
  deleted rather than carried forward. It was still rejected, for two reasons
  in this order:

    1. **It changes the semantics of the code under test.** Every
       `Events.append/1` here commits today; inside a sandbox transaction they
       become nested and are discarded wholesale at checkin. `sandbox: false`
       preserves the committed, non-transactional behavior `:auto` gave this
       module, so the only thing this change alters is who owns the connection
       and for how long — not what the property exercises.
    2. **It costs 1.5x-1.9x.** Same seed, same boxes: 96.6s vs 66.1s on the
       gating toolchain, 64.0s vs 33.4s on the developer box. The property
       issues 3 TRUNCATEs per iteration (3000 in total), and inside a
       transaction block Postgres cannot truncate in place — it writes a fresh
       relfilenode per TRUNCATE and holds the previous one until the
       transaction ends.

  ### Release verification stays at the default bound

  Deliberately no `:settle_attempts` / `:settle_interval_ms` override. The
  sibling needs 600/10ms (~6s) because its checkin unwinds a large transaction
  before the ownership manager can process the owner's `:DOWN`. This checkout
  has no transaction to unwind, and `checkout!/1`'s default ~150ms bound
  converged on two consecutive gating-toolchain runs. Widening a verification
  bound that is not being exceeded would only make a future genuine leak slower
  to report.
  """

  use ExUnit.Case, async: false

  use ExUnitProperties

  import Ecto.Query

  alias Mailglass.Events
  alias Mailglass.Events.Event
  alias Mailglass.TestRepo
  alias Mailglass.TestSupport.SandboxOwnership

  @moduletag timeout: :infinity

  setup context do
    # context: — the shared-mode async guard reads `:async` straight out of the
    # ExUnit context (supplied by construction, never inferred from a process
    # label, which `ExUnit.Runner` only sets from Elixir 1.19.0 while every
    # gating CI lane runs 1.18.4).
    #
    # sandbox: false / ownership_timeout: / no settle override — all four
    # choices, and the measurements behind them, are in the moduledoc under
    # "Test sandbox discipline".
    _owner =
      SandboxOwnership.checkout!(
        repo: TestRepo,
        shared: true,
        sandbox: false,
        context: context,
        ownership_timeout: 10 * 60_000
      )

    # Wipe committed residue from other modules so this property starts clean.
    TestRepo.query!("TRUNCATE TABLE mailglass_events CASCADE", [])

    # Registered AFTER checkout!/1's release, so it runs BEFORE it (reverse
    # on_exit ordering) — the connection is still owned and still shared, which
    # is what lets this run from ExUnit's separate on_exit process at all.
    # Writes here are committed (sandbox: false), so this cleanup is real work,
    # not a statement a rollback would discard.
    on_exit(fn ->
      TestRepo.query!("TRUNCATE TABLE mailglass_events CASCADE", [])
    end)

    :ok
  end

  # Restrict to a subset of event types to keep generator cardinality sane.
  @event_types [:queued, :dispatched, :delivered, :bounced, :complained, :opened]

  property "convergence: apply_all(events) == apply_all(replays_shuffled)" do
    check all(
            events <- list_of(event_attrs_gen(), min_length: 1, max_length: 20),
            replay_count <- integer(1..10),
            max_runs: 1000
          ) do
      # Wipe events table between iterations to isolate state.
      # (The trigger prevents UPDATE/DELETE only; we need TRUNCATE with
      # CASCADE via raw SQL because DELETE fires the trigger.)
      TestRepo.query!("TRUNCATE TABLE mailglass_events CASCADE", [])

      # Pass 1: apply each event exactly once.
      fresh_keys = Enum.map(events, &apply_and_key/1)
      fresh_snapshot = snapshot()

      # Wipe + Pass 2: apply N replays of the sequence, shuffled.
      TestRepo.query!("TRUNCATE TABLE mailglass_events CASCADE", [])

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
