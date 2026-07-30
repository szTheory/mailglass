defmodule Mailglass.TestSupport.SandboxOwnership.LeakError do
  @moduledoc """
  Raised by `Mailglass.TestSupport.SandboxOwnership.assert_manual!/3` when the
  Sandbox pool is not `:manual` at the point a release was expected to have
  restored it.

  **Load-bearing for D-17's classifier (Wave 3, plan `143-08`):** `checkout!/1`
  replaces the raw `{:badmatch, :already_shared}` term at the confirmed leak
  sites with this composed error. If the Wave-3 signature tally counted only
  the raw badmatch term, the signature would simply move house the moment
  `checkout!/1` is adopted, and ROADMAP criterion 3 ("`:already_shared` count
  is exactly zero") would pass vacuously — the leak would still be happening,
  just reported under a name nothing is watching. The tally MUST count this
  exception alongside the raw term.
  """
  defexception [:caller, :mode, :refused_with]

  # The release-verification shape: `assert_manual!/3` observed a non-`:manual`
  # pool after a release should have restored it.
  @impl true
  def message(%__MODULE__{caller: caller, mode: mode, refused_with: nil}) do
    "Mailglass.TestSupport.SandboxOwnership: #{inspect(caller)} released a Sandbox " <>
      "owner but the pool is still #{inspect(mode)}, not :manual. Either stop_owner/1 " <>
      "did not check the connection in, or another process re-shared the pool before " <>
      "the release could be observed. Find what re-acquired shared mode after " <>
      "#{inspect(caller)}'s release should have restored :manual."
  end

  # The refused-write shape: `mode_manual!/2`'s `Sandbox.mode(repo, :manual)`
  # returned something other than `:ok`. Deliberately a separate clause rather
  # than reusing the wording above — a refusal code (`:already_shared` /
  # `:not_owner` / `:not_found`) is NOT a pool mode, and rendering it in the
  # "the pool is still <mode>" sentence would report a fact nobody observed.
  @impl true
  def message(%__MODULE__{caller: caller, refused_with: refusal}) do
    "Mailglass.TestSupport.SandboxOwnership: #{inspect(caller)} called " <>
      "Sandbox.mode(repo, :manual) and the ownership manager refused with " <>
      "#{inspect(refusal)} instead of :ok. Ecto documents this write as always " <>
      "successful for :manual (sandbox.ex:501-503), and db_connection's manager " <>
      "returns :ok on both of its :manual clauses (manager.ex:165-172), so this " <>
      "return means the pool is in a state this harness does not model — the mode " <>
      "was NOT established, and every later checkout is running against an unknown " <>
      "pool. Refusing to report :ok for a write that did not take effect."
  end
end

defmodule Mailglass.TestSupport.SandboxOwnership.ScratchSchemaError do
  @moduledoc """
  Raised by `Mailglass.TestSupport.SandboxOwnership.scratch_schema!/2` when a
  module declares a *scratch* schema prefix that is not actually scratch — it
  names either the live schema `Mailglass.Config.schema/0` currently resolves
  to, or the shared `public` schema.

  **Why this exception exists (D-31 Class A).** Five `async: false` modules
  hardcoded `@prefix "mailglass"` as their scratch prefix and ran
  `DROP SCHEMA IF EXISTS mailglass CASCADE` in setup and again in `on_exit`.
  On the default `public` axis that scratch schema is disjoint from the
  baseline, so the drop is harmless. Under
  `MAILGLASS_SCHEMA=mailglass` the scratch prefix IS the live baseline schema,
  so those modules CASCADE-dropped the migration baseline out from under the
  rest of the run. The suite then failed with
  `(Postgrex.Error) ERROR 42P01 (undefined_table)` in six or seven wholly
  unrelated victim modules hundreds of tests later — a misattribution that
  cost two full diagnosis cycles.

  This exception ends that class of misattribution by name: it fires at the
  module that would corrupt the baseline, before a single DDL statement runs,
  and it names both that module and the live schema it was about to destroy.
  """
  defexception [:caller, :requested, :live_schema, :reason]

  @impl true
  def message(%__MODULE__{
        caller: caller,
        requested: requested,
        live_schema: live_schema,
        reason: reason
      }) do
    "Mailglass.TestSupport.SandboxOwnership: #{inspect(caller)} declared " <>
      "#{inspect(requested)} as a SCRATCH schema, but #{scratch_violation(reason, live_schema)} " <>
      "A scratch schema is one this module may CREATE, migrate into, and " <>
      "DROP ... CASCADE without consequence for any other module in the run. " <>
      "Pick a name unique to this module and disjoint from both \"public\" and " <>
      "the live schema — the naming precedent is " <>
      "`mailglass_shipped_path_test` in " <>
      "test/mailglass/shipped_migration_divergence_test.exs. Refusing to " <>
      "proceed: the DROP SCHEMA below would have destroyed the migration " <>
      "baseline and surfaced as a 42P01 cascade in unrelated modules."
  end

  defp scratch_violation(:live_schema, live_schema) do
    "that is the LIVE schema Mailglass.Config.schema/0 currently resolves to " <>
      "(#{inspect(live_schema)}) — the schema holding this run's migration baseline."
  end

  defp scratch_violation(:public, _live_schema) do
    "\"public\" is the shared ambient schema (it holds the citext extension and, " <>
      "on the default axis, the migration baseline itself) — never scratch."
  end
end

defmodule Mailglass.TestSupport.SandboxOwnership.BaselineError do
  @moduledoc """
  Raised by `Mailglass.TestSupport.SandboxOwnership.assert_baseline_intact!/2`
  when the migration baseline relations are absent from the schema
  `Mailglass.Config.schema/0` resolves to, or when their presence could not be
  observed at all (D-31 Class A).

  Attribution is the whole point: this raises at the boundary of the module
  that broke (or failed to restore) the baseline, naming that module and the
  missing relations, instead of letting an unrelated module hundreds of tests
  later fail with `42P01 (undefined_table)`.

  A `:cannot_verify` result raises just as loudly as a `{false, missing}` one —
  a check that cannot observe its subject must never report success.
  """
  defexception [:caller, :schema, :missing, :reason]

  @impl true
  def message(%__MODULE__{caller: caller, schema: schema, missing: missing, reason: nil}) do
    "Mailglass.TestSupport.SandboxOwnership: #{inspect(caller)} left the migration " <>
      "baseline incomplete — #{inspect(missing)} absent from schema #{inspect(schema)}. " <>
      "The next module to query these relations would have failed with 42P01 for a " <>
      "reason that had nothing to do with it; failing here instead, at the module that " <>
      "actually broke the baseline. Rebuild a clean local baseline with " <>
      "`MIX_ENV=test mix ecto.drop -r Mailglass.TestRepo && MIX_ENV=test mix ecto.create " <>
      "-r Mailglass.TestRepo`, or investigate why the migrator considered these " <>
      "relations already applied."
  end

  @impl true
  def message(%__MODULE__{caller: caller, schema: schema, reason: reason}) do
    "Mailglass.TestSupport.SandboxOwnership: #{inspect(caller)} could not verify the " <>
      "migration baseline in schema #{inspect(schema)} — the verification probe itself " <>
      "failed (#{inspect(reason)}). A check that cannot observe its subject must never " <>
      "report success, so this is a failure, not a pass."
  end
end

defmodule Mailglass.TestSupport.SandboxOwnership.SearchPathError do
  @moduledoc """
  Raised by `Mailglass.TestSupport.SandboxOwnership.with_search_path!/3` when
  the temporary `search_path` override could not be restored on the connection
  it was applied to (D-31 Class A, the confirmed root cause).

  A `SET search_path` statement without `LOCAL` is a SESSION-level write: it
  persists on the physical Postgres connection for that connection's whole
  lifetime. Under Sandbox `:auto` mode every query checks a connection out of
  the 10-slot pool and hands it straight back, so an unrestored override
  returns to the pool poisoned, and the next unrelated test to draw that
  connection raises `42P01 (undefined_table)` on an unqualified relation name.
  Seven such victim modules, none of them at fault, cost two full diagnosis
  cycles before the real culprit was found.

  This exception ends that misattribution by name: it fires at the module that
  owns the override, at the moment the restore is observed to have failed,
  rather than letting an innocent module fail later.
  """
  defexception [:caller, :expected, :actual]

  @impl true
  def message(%__MODULE__{caller: caller, expected: expected, actual: actual}) do
    "Mailglass.TestSupport.SandboxOwnership: #{inspect(caller)} failed to restore this " <>
      "connection's search_path — expected #{inspect(expected)}, got #{inspect(actual)}. " <>
      "This connection is about to go back into the pool poisoned, and the next unrelated " <>
      "test to draw it will fail with a 42P01 that has nothing to do with it. Failing here " <>
      "instead, at the module that broke it."
  end
end

defmodule Mailglass.TestSupport.SandboxOwnership do
  @moduledoc """
  The one sanctioned door for Ecto Sandbox ownership acquisition and release
  in this harness (HARNESS-01, D-06, D-08).

  Background: `db_connection`'s ownership manager (`manager.ex:148-172`) can end
  up holding `{:shared, pid}` after a test raised between acquiring shared mode
  and registering its `on_exit` release — the pool never gets checked back in.
  The next `async: false` module's `Ecto.Adapters.SQL.Sandbox.start_owner!(shared:
  true)` then raises `{:badmatch, :already_shared}` at
  `ecto_sql/lib/ecto/adapters/sql/sandbox.ex:458`, 200+ failures away from the
  test that actually leaked. Both confirmed leak sites
  (`test/support/mailer_case.ex:93→99` and
  `test/mailglass/properties/webhook_idempotency_convergence_test.exs:52→58`)
  share one shape: **acquire, then work that can raise, then register
  release** — with the release registered last, so a raise in the middle
  loses it entirely.

  `checkout!/1` makes that ordering structurally impossible to re-type: the
  release is registered on the statement immediately following acquisition,
  so every later statement sits below it and a raise there still releases.

  `Mailglass.TestSupport.SuiteTruthFormatter` calls `probe/1` at every
  `:module_finished` boundary of an `async: false` module so a leak that
  slips past `checkout!/1` anyway is named the instant it happens, rather
  than inferred from a distant victim.

  ## Public surface

  - `checkout!/1` — the sanctioned acquire, with the release registered first.
  - `unsandboxed_module/1` — a `setup` callback switching the whole module to
    pool-wide `:auto` mode, with the revert registered first.
  - `with_schema!/2` — overrides `Mailglass.Config.schema/0`, with the restore
    registered before the override is even applied (D-31 Class B).
  - `with_search_path!/3` — the ONLY sanctioned `search_path` override: pins one
    pooled connection, restores it, and verifies the restore landed (D-31
    Class A). `Mailglass.Credo.NoRawSearchPathMutation` fails the build on any
    raw `search_path` write under `test/` outside this door.
  - `scratch_schema!/2` — the sanctioned declaration of a throwaway schema
    prefix, raising `ScratchSchemaError` when the requested name is the live
    schema or `public` (D-31 Class A).
  - `assert_baseline_intact!/2` — read-only baseline verification that raises
    `BaselineError`, naming the calling module (D-31 Class A).
  - `unsandboxed/2` — the preferred forward idiom for a single committed write.
  - `mode_manual!/2` — the raw `Sandbox.mode(repo, :manual)` write, for the
    two narrow callers (suite boot; a pre-release healing revert) that need
    it directly rather than through an acquire/release pairing. Raises
    `LeakError` when the ownership manager refuses the write, rather than
    returning the refusal for its callers to discard.
  - `probe/1` — read-only pool-mode observation (never mutates).
  - `assert_manual!/3` — raises `LeakError` when the pool is not `:manual`.
  - `live_holder/0` — the current shared-owner pid, or `nil`.
  - `baseline_tables_present?/1` — read-only baseline-relation check (Class A).
    Prefer `assert_baseline_intact!/2` at a test call site; the predicate form
    exists for `Mailglass.TestSupport.SuiteTruthFormatter`, which records a
    violation rather than raising.
  - `reloading_flat_migrations/1` — scopes `ignore_module_conflict` around a
    flat-`priv/repo/migrations/` reload (HARNESS-02's redefining-module
    blocker), restored in an `after` block.

  ## Why `probe/1` reads `:sys.get_state/1` instead of calling `Sandbox.mode/2`

  An earlier version of this module called
  `Ecto.Adapters.SQL.Sandbox.mode(repo, :manual)` and matched its return value,
  reasoning that "the return value alone can't distinguish already-manual from
  leaked-and-healed, but at least it's *some* signal." That reasoning was
  wrong, and fatally so for this phase: `manager.ex:161-172`'s catch-all
  clause matches ANY current mode and always replies `:ok` — there is no
  input for which that call returns anything else. A probe built on it can
  *never* observe a leak; the ledger would read `0 record(s)` forever whether
  or not leaks occur, and the call itself checks in every live connection and
  overwrites the pool's mode on every single `async: false` module boundary —
  a suite-wide auto-heal that would mask the exact bug HARNESS-01 exists to
  expose. Confirmed live: putting the pool in `{:shared, pid}` and calling
  that version of `probe/1` returned `:ok`, and the leak was gone afterward.

  There is no public, read-only "what mode is this pool in?" function on
  either `Ecto.Adapters.SQL.Sandbox` or `DBConnection.Ownership` — `mode/2` is
  the only exposed entry point, and it is a write. `probe/1` instead reads the
  ownership manager's own process state directly via `:sys.get_state/1`, which
  sends no `GenServer.call` message and triggers no `handle_call` clause — it
  is the OTP-sanctioned way to inspect a process's state without a side
  effect. The state map's `:mode` key (`manager.ex:105-115`, `:auto | :manual
  | {:shared, pid}`) is `@moduledoc false`/private to `db_connection`, so this
  coupling is deliberate and version-pinned; confirmed empirically against
  this repo's `mix.lock` `db_connection` version: `:manual` on a clean pool,
  `{:shared, pid}` on a leaked one, unchanged across repeated reads, and a
  leak observed this way is *still* there afterward (a second
  `start_owner!(shared: true)` still raises `{:badmatch, :already_shared}`).

  The ownership manager's pid is looked up the same way `Sandbox` itself does
  internally (`sandbox.ex:636-651`'s private `lookup_meta!/1`), via the public
  `Ecto.Adapter.lookup_meta/1`.

  **Healing is deliberately split from observation.** `probe/1` never mutates
  the pool. `checkout!/1`'s `on_exit` and `unsandboxed_module/1`'s revert are
  the two explicit, opt-in heal steps — a heal is never a side effect of
  calling `probe/1` or `assert_manual!/3`.

  ## Async policy — exactly three reasons earn `async: false`

  1. **Pool-mode mutation** — `checkout!(shared: true)` or
     `unsandboxed_module/1`.
  2. **`Application.put_env/3` on a key the code under test reads** — Oban.Testing
     mode, `:async_adapter`/`:async_adapter_impl`, the adapter, and
     `config :mailglass, :schema` (via `with_schema!/2`). This stays
     convention plus the existing I-12 guard (`mailer_case.ex:84-91`); nothing
     here makes it mechanical.
  3. **Committed non-transactional DB state** — DDL, `TRUNCATE`, migrations.

  **Cross-process delivery is explicitly NOT a reason.**
  `Ecto.Adapters.SQL.Sandbox.allow/3` covers it from an owned, non-shared
  checkout. Reasons 1 and 3 are mechanical: `checkout!(shared: true)` and
  `unsandboxed_module/1` both raise when called from a module whose `async`
  tag is `true` — see "Async guards" below.

  **Phase 143 changes no file's `async:` value.** SEED-007 forbids
  serializing the bug away, and HARNESS-02's four-leg evidence is only
  interpretable if the async/sync split is byte-identical before and after.

  ## Async guards

  Both `checkout!(shared: true)` and `unsandboxed_module/1` raise when called
  from a module whose `async` tag is `true`, in the shape of the existing
  I-12 guard (`mailer_case.ex:84-91`): who raised, the rule as a MUST, the
  one-sentence reason naming the global state, and the one-line edit that
  fixes it — nothing else.

  `unsandboxed_module/1` reads its module's `async` tag directly from the
  `setup` context it is called with (ExUnit merges `:async` into that map).
  `checkout!/1` is not itself a `setup` callback, so it has no context
  argument to read; it instead reads the *calling test's* module off
  `Process.get(:"$process_label")` — the `{module, test_name}` pair ExUnit's
  own `Runner` sets on the test process before `setup` runs — and asks that
  module's own compiler-generated `__ex_unit__(:config).async?` (the same
  function `ExUnit.Case.__after_compile__/2` itself calls to register the
  module). Both are deliberate, version-pinned couplings to ExUnit internals,
  confirmed empirically against this repo's Elixir version, in the same
  spirit as `probe/1`'s `:sys.get_state/1` coupling above — there is no
  public "which module owns the currently-running test" API.
  **Accepted limitation:** if that process-label lookup cannot resolve a
  module (e.g. `checkout!/1` called from a process ExUnit did not label),
  the guard does not fire; it fails open, not closed. It is a convenience
  check, not the enforcement backbone — the Credo check
  `Mailglass.Credo.NoRawSandboxOwnership` (plan `143-08`) is the fail-closed
  static prevention layer.

  Both guards expose an injectable seam (`:calling_module_fun` on
  `checkout!/1`; a plain map on `unsandboxed_module/1`, since its context
  argument already is one) so the raise and pass-through paths are testable
  without needing a real async module to call from, mirroring
  `Mailglass.TestSupport.CitextProbe`'s `probe_fun:` idiom.

  ## Usage

      # In a CaseTemplate `setup` block:
      pid = Mailglass.TestSupport.SandboxOwnership.checkout!(shared: not tags[:async])

      # A new test needing committed, non-transactional writes:
      Mailglass.TestSupport.SandboxOwnership.unsandboxed(fn -> ... end)

      # A file that genuinely needs pool-wide :auto (migrations, schema drop/recreate):
      setup :unsandboxed_module

      # A file that stands up a throwaway schema of its own, and overrides
      # `config :mailglass, :schema` to point at it. scratch_schema!/2 comes
      # FIRST — see its own docs for why the ordering is load-bearing:
      prefix = Mailglass.TestSupport.SandboxOwnership.scratch_schema!(@prefix, caller: __MODULE__)
      Mailglass.TestSupport.SandboxOwnership.with_schema!(prefix)

      # In that same file's `on_exit`, after tearing the scratch schema down:
      Mailglass.TestSupport.SandboxOwnership.assert_baseline_intact!(__MODULE__)

      # In `Mailglass.TestSupport.SuiteTruthFormatter`'s `:module_finished` handler:
      Mailglass.TestSupport.SandboxOwnership.probe(Mailglass.TestRepo)
      Mailglass.TestSupport.SandboxOwnership.baseline_tables_present?(Mailglass.TestRepo)
  """

  alias Mailglass.TestSupport.SandboxOwnership.BaselineError
  alias Mailglass.TestSupport.SandboxOwnership.LeakError
  alias Mailglass.TestSupport.SandboxOwnership.ScratchSchemaError
  alias Mailglass.TestSupport.SandboxOwnership.SearchPathError

  @doc """
  Checks out the Sandbox pool for the calling test, registering the release
  on the statement immediately following acquisition.

  Takes the same option list `Ecto.Adapters.SQL.Sandbox.start_owner!/2`
  takes, plus an optional `:repo` (default `Mailglass.TestRepo`). Returns the
  owner pid.

  **The non-negotiable invariant (D-06):** the `on_exit` release is
  registered on the line immediately after `start_owner!/2` returns — every
  other statement this function performs happens BELOW that registration, so
  a raise anywhere below still releases the owner. This is exactly the
  ordering both confirmed leak sites got wrong (acquire, then work that can
  raise, then register release — release lost when the middle step raised).
  Every Ecto return value this function touches is matched, never discarded:
  `on_exit`'s `Sandbox.stop_owner/1` result is matched against `:ok`, and when
  the checkout was shared the release is followed by `assert_manual!/3` so
  the release is *verified*, not assumed.

  Raises `checkout!(shared: true)` from a module whose `async` tag is `true`
  (see "Async guards" in the moduledoc) — shared mode is process-global pool
  state, and concurrent async tests sharing it would stomp each other.

  Accepts optional `:settle_attempts` / `:settle_interval_ms`, forwarded to
  `assert_manual!/3`'s `:attempts` / `:interval_ms` (defaults: 30 / 5ms, the
  same ~150ms bound `assert_manual!/3` itself defaults to). A caller whose
  own workload does heavy pool churn before releasing (many transactions
  through a shared connection, e.g. a 1000-run property test) can widen this:
  empirically, `db_connection`'s ownership manager takes longer than ~150ms
  to process the owner's `:DOWN` message when its own mailbox is backed up
  from that churn — confirmed live against
  `webhook_idempotency_convergence_test.exs`'s real workload, which converged
  in 564ms-1131ms across repeated clean (uncontended) runs, consistently
  exceeding the default bound. This is the same benign, bounded settle delay
  `assert_manual!/3`'s moduledoc describes, not a persistent leak — a caller
  that genuinely never converges still raises `LeakError` once ITS bound is
  exhausted, exactly as before.
  """
  @spec checkout!(keyword()) :: pid()
  def checkout!(opts \\ []) do
    {repo, opts} = Keyword.pop(opts, :repo, Mailglass.TestRepo)
    {calling_module_fun, opts} = Keyword.pop(opts, :calling_module_fun, &calling_test_module/0)
    {settle_attempts, opts} = Keyword.pop(opts, :settle_attempts, 30)
    {settle_interval_ms, opts} = Keyword.pop(opts, :settle_interval_ms, 5)
    shared? = Keyword.get(opts, :shared, false)

    if shared?, do: guard_shared_checkout_from_async!(calling_module_fun)

    owner = Ecto.Adapters.SQL.Sandbox.start_owner!(repo, opts)

    # INVARIANT (D-06): this on_exit registration is the very next statement
    # after acquisition. Every statement this function performs after this
    # point sits below it, so a raise anywhere below still releases the
    # owner — this is the exact acquire/release ordering both confirmed leak
    # sites (mailer_case.ex:93->99, webhook_idempotency_convergence_test.exs:
    # 52->58) got wrong. Do not move work above this line.
    ExUnit.Callbacks.on_exit(fn ->
      :ok = Ecto.Adapters.SQL.Sandbox.stop_owner(owner)

      if shared? do
        assert_manual!(repo, calling_module_fun.() || __MODULE__,
          attempts: settle_attempts,
          interval_ms: settle_interval_ms
        )
      end
    end)

    owner
  end

  # FAIL-CLOSED (D-31). Every branch that cannot establish the calling module's
  # async-ness raises instead of falling through to `:ok`. The previous shape
  # had two silent-pass holes, both of the "a check that cannot observe its
  # subject reported success" class this milestone exists to remove:
  #
  #   1. `calling_test_module/0` returns nil whenever no `{module, test_name}`
  #      process label is set. `ExUnit.Runner` sets that label in
  #      `spawn_test_monitor/4` ONLY for the per-test process (verified by
  #      decompiling `ExUnit.Runner` on 1.19.5: exactly one `Process.set_label`
  #      call site in the whole module). A `setup_all` process, an
  #      `on_exit` runner process, and any `Task`/`GenServer` therefore carry
  #      no label — so a `checkout!(shared: true)` from a `setup_all` block
  #      used to skip the guard entirely and report success.
  #   2. A module that does not export `__ex_unit__/1` made `async_module?/1`
  #      return false, which is indistinguishable from a genuine `async: false`.
  #
  # Neither hole has a live call site today (audited: every `checkout!(shared:
  # true)` in this repo runs from a labelled test process — `mailer_case.ex:93`,
  # `data_case.ex:35`, `webhook_idempotency_convergence_test.exs:60`,
  # `sandbox_ownership_test.exs`). That is exactly when a hole is cheapest to
  # close, and the injectable `:calling_module_fun` is the sanctioned door for
  # any future caller that legitimately runs outside a labelled test process.
  defp guard_shared_checkout_from_async!(calling_module_fun) do
    module = calling_module_fun.()

    case async_classification(module) do
      :sync ->
        :ok

      :async ->
        raise """
        Mailglass.TestSupport.SandboxOwnership: `checkout!(shared: true)` MUST NOT \
        be called from an async: true module (#{inspect(module)}). Shared mode is \
        process-global pool state — concurrent async tests sharing it would stomp \
        each other. Pass `shared: false` instead (or, for cross-process delivery, \
        use `Ecto.Adapters.SQL.Sandbox.allow/3` from an owned, non-shared checkout).
        """

      :unknown ->
        raise """
        Mailglass.TestSupport.SandboxOwnership: `checkout!(shared: true)` could not \
        determine whether its caller is an async: true module — the calling module \
        resolved to #{inspect(module)}, which carries no ExUnit async configuration. \
        Shared mode is process-global pool state, so acquiring it without that check \
        would put the pool into shared mode on the word of a guard that never ran. \
        A guard that cannot observe its subject must not report success, so this \
        raises rather than proceeding.

        The usual cause is calling `checkout!(shared: true)` from a process ExUnit \
        did not label with `{module, test_name}` — a `setup_all` block, an `on_exit` \
        callback, or a spawned Task. Prefer moving the call into a per-test `setup`. \
        If the caller genuinely belongs outside a labelled test process, name the \
        module explicitly:

            checkout!(shared: true, calling_module_fun: fn -> __MODULE__ end)
        """
    end
  end

  defp calling_test_module do
    case Process.get(:"$process_label") do
      {module, test_name} when is_atom(module) and is_atom(test_name) -> module
      _ -> nil
    end
  end

  # Three-way on purpose: `:unknown` is a distinct outcome from `:sync`, so an
  # unanswerable question can never be silently answered "no".
  defp async_classification(module) when is_atom(module) and not is_nil(module) do
    if Code.ensure_loaded?(module) and function_exported?(module, :__ex_unit__, 1) do
      case module.__ex_unit__(:config) do
        %{async?: true} -> :async
        %{async?: false} -> :sync
        _ -> :unknown
      end
    else
      :unknown
    end
  end

  defp async_classification(_unresolved), do: :unknown

  @doc """
  `setup` callback that switches `repo`'s pool to pool-wide `:auto` mode for
  the whole module and registers the revert to `:manual` on the immediately
  following statement.

  Takes the `setup` context map ExUnit passes to every `setup` callback
  (which already carries `:async` and `:repo` may be supplied via the same
  map when a test needs a non-default repo).

  **Ordering guarantee, load-bearing for plan `143-06`'s migrations:**
  `ExUnit`'s `on_exit` callbacks run in reverse registration order. Because
  the revert here is registered FIRST — before any `on_exit` the calling
  module's own `setup` chain registers afterward — it runs LAST. This
  preserves today's semantics for the nine `:auto`-mode files exactly: each
  file's own baseline-restore `on_exit` (registered later) still runs while
  `:auto` is in effect, because this revert has not run yet.

  Raises when the calling module's `async` tag is `true` — pool-wide `:auto`
  mode checks in every live connection
  (`deps/ecto_sql/lib/ecto/adapters/sql/sandbox.ex:498-501`), and running it
  while async modules are live would check connections out from under them.
  """
  @spec unsandboxed_module(map()) :: :ok
  def unsandboxed_module(context) when is_map(context) do
    if Map.get(context, :async, false) do
      raise """
      Mailglass.TestSupport.SandboxOwnership: `setup :unsandboxed_module` MUST run \
      with `async: false` (#{inspect(Map.get(context, :module))}). Pool-wide :auto \
      mode checks in every live connection — running it while async: true modules \
      are live would check connections out from under them. Add `async: false` to \
      this module's `use ..., async: false`.
      """
    end

    repo = Map.get(context, :repo, Mailglass.TestRepo)

    :ok = Ecto.Adapters.SQL.Sandbox.mode(repo, :auto)

    ExUnit.Callbacks.on_exit(fn ->
      # Routed through `mode_manual!/2` rather than calling
      # `Ecto.Adapters.SQL.Sandbox.mode/2` raw: this revert used to discard its
      # return value, so a refusal would have left the pool in `:auto` for
      # every later module while this callback reported nothing — the same
      # discarded-signal defect `mode_manual!/2` was just hardened against.
      # The acquire on the line above already matches `:ok`; the release now
      # does too.
      mode_manual!(repo, caller: Map.get(context, :module, __MODULE__))
    end)

    :ok
  end

  @doc """
  Returns `name` unchanged after asserting it is genuinely a **scratch**
  schema — one the calling module may `CREATE SCHEMA`, migrate into, and
  `DROP SCHEMA ... CASCADE` without consequence for any other module in the
  run — and raises `ScratchSchemaError` otherwise (D-31 Class A).

  Two names are refused:

    * the live schema `Mailglass.Config.schema/0` currently resolves to —
      the schema holding this run's migration baseline; and
    * `"public"` — the shared ambient schema (it owns the `citext` extension,
      and on the default axis the baseline itself), which is never scratch
      even on an axis where it is not the live schema.

  **Why this is a raise and not a rename-and-continue.** Silently substituting
  a safe name would make the guard invisible: the module would keep asserting
  against a prefix it did not declare, and the next person to hardcode
  `"mailglass"` would get a passing suite with no signal. A raise attributes
  the fault to the module that would have caused it, before any DDL runs.

  **Ordering is load-bearing: call this BEFORE `with_schema!/2`, never after.**
  `with_schema!/2` makes `Mailglass.Config.schema/0` return the scratch name
  for the rest of the test, at which point the scratch name IS the resolved
  schema and this function would refuse it. That is deliberate fail-closed
  behavior, not a false positive to work around — the invariant this function
  protects is "the schema the REST OF THE SUITE needs", and the only moment a
  caller can observe that value is before its own override lands. Placing this
  call as the first statement of `setup` satisfies the ordering naturally.

  Accepts `:caller` (default: the calling test's module, resolved the same way
  `checkout!/1` resolves it — see "Async guards" in the moduledoc) so the raise
  names the module at fault, and `:schema_fun` (default
  `&Mailglass.Config.schema/0`), mirroring `with_schema!/2`'s own injectable
  seam so both raise paths are testable without manufacturing a real axis.
  """
  @spec scratch_schema!(String.t(), keyword()) :: String.t()
  def scratch_schema!(name, opts \\ []) when is_binary(name) do
    schema_fun = Keyword.get(opts, :schema_fun, &Mailglass.Config.schema/0)
    caller = Keyword.get(opts, :caller) || calling_test_module() || __MODULE__
    live_schema = schema_fun.()

    reason =
      cond do
        name == live_schema -> :live_schema
        name == "public" -> :public
        true -> nil
      end

    if reason do
      raise ScratchSchemaError,
        caller: caller,
        requested: name,
        live_schema: live_schema,
        reason: reason
    end

    name
  end

  @doc """
  Overrides `Mailglass.Config.schema/0` to `schema` for the calling test,
  registering the restore to the CAPTURED boot value on the statement
  immediately following capture — before the override is even applied
  (D-11's sanctioned reason two; D-31 Class B).

  **The non-negotiable invariant (D-31 Class B):** every confirmed Class B
  candidate got the ordering backwards — override first, then work that can
  raise (DROP SCHEMA, migrate), then a TRAILING `on_exit` restore that a
  mid-setup raise skips entirely, leaving `Mailglass.Config.schema/0` drifted
  for every later module in the run. This function inverts that ordering:
  capture, register the restore, THEN override. A raise anywhere after this
  function returns still restores the boot schema, because the restore was
  already registered before the raising statement ever ran.

  The restore goes through the exact write path the override uses —
  `Application.put_env/3` plus a `:persistent_term` cache erase — so
  `Mailglass.Config.schema/0` re-reads and re-validates through its
  documented cache-write boundary (`warm_schema/0`) the next time it is
  called. This module never writes `Mailglass.Config`'s cache directly.

  After applying the override, asserts it took effect —
  `Mailglass.Config.schema/0` must equal `schema` — and raises a composed
  message naming the mismatch if it does not. A setup that cannot establish
  its own precondition must not proceed.

  Accepts an optional `:repo` (default `Mailglass.TestRepo`), reserved for a
  future per-repo schema seam; the override itself always targets the single
  process-global `:mailglass, :schema` Application env key regardless of
  `:repo`. Also accepts an injectable `:schema_fun` (default
  `&Mailglass.Config.schema/0`), mirroring `assert_manual!/3`'s `probe_fun:`
  idiom, used ONLY for the post-override verification read — so the "did not
  take effect" raise path is testable with a synthetic mismatch rather than
  by manufacturing a real Application-env race.
  """
  @spec with_schema!(String.t(), keyword()) :: :ok
  def with_schema!(schema, opts \\ []) when is_binary(schema) do
    schema_fun = Keyword.get(opts, :schema_fun, &Mailglass.Config.schema/0)
    original = schema_fun.()

    # INVARIANT (D-31 Class B): this on_exit registration is the very next
    # statement after capturing the original value — before the override
    # below is even applied. Every statement after this point (including the
    # override itself, and every statement the caller performs afterward)
    # sits below it, so a raise anywhere below still restores the boot
    # schema. This is the exact ordering the confirmed Class B candidates
    # got wrong (override, then work that can raise, then a trailing restore
    # that's skipped).
    ExUnit.Callbacks.on_exit(fn ->
      Application.put_env(:mailglass, :schema, original)
      :persistent_term.erase({Mailglass.Config, :schema})
    end)

    Application.put_env(:mailglass, :schema, schema)
    :persistent_term.erase({Mailglass.Config, :schema})

    applied = schema_fun.()

    unless applied == schema do
      raise """
      Mailglass.TestSupport.SandboxOwnership: with_schema!(#{inspect(schema)}) did not \
      take effect — Mailglass.Config.schema/0 still returns #{inspect(applied)}. The \
      Application env override or the persistent_term cache invalidation did not reach \
      Config.schema/0's cache-write boundary; investigate whatever else touches \
      `config :mailglass, :schema` around this call.
      """
    end

    _ = Keyword.get(opts, :repo, Mailglass.TestRepo)

    :ok
  end

  @doc """
  Runs `fun` with `repo`'s connection `search_path` overridden to
  `search_path`, restores the prior value ON THAT SAME CONNECTION, and
  VERIFIES the restore landed. Returns `fun`'s value.

  This is the one sanctioned door for a `search_path` override in test code.
  `Mailglass.Credo.NoRawSearchPathMutation` fails the build on any raw
  `search_path` write under `test/` outside this module — the prevention half
  of the two-layer guard whose absence let this defect class recur.

  **The failure mode this replaces (D-31 Class A, confirmed root cause).** A
  bare `TestRepo.query!("SET search_path TO public")` with no scoping was the
  true cause of the 42P01 cascade on the `MAILGLASS_SCHEMA=mailglass` axis —
  NOT the baseline drop that was fixed alongside it. Three facts combine:

    1. A `SET` without `LOCAL` is a SESSION-level write. It persists on the
       physical Postgres connection for that connection's whole lifetime.
    2. In Sandbox `:auto` mode every `repo.query` checks a connection out of
       the 10-slot pool and returns it, so the poisoned connection goes
       straight back into the pool. A trailing `RESET` issued from `on_exit`
       is a SEPARATE checkout that could — and under any concurrency did —
       land on a DIFFERENT connection than the poisoned one.
    3. `config/test.exs` + `test/test_helper.exs` give pool connections a
       startup `search_path` of `"<schema>, public"`, and the whole rest of
       the suite relies on it to resolve unqualified relation names. A
       connection stuck at `search_path = public` therefore raises
       `42P01 (undefined_table) relation "mailglass_deliveries" does not
       exist` for whatever unrelated test later drew it — a failure attributed
       to an innocent module hundreds of tests away. Confirmed live with a
       throwaway probe: after ONE unscoped `SET`, all 40 subsequent pool
       checkouts observed `"public"`.

  `Ecto.Repo.checkout/2` pins ONE connection for the whole block, so the
  override, the code under test, and the restore all ride the same connection.
  The `after` clause guarantees the restore even when `fun` raises, and the
  post-restore read makes it VERIFIED rather than assumed — a restore that
  cannot be observed to have worked must not be reported as success (D-31).

  **Why not `SET LOCAL`?** It is transaction-scoped rather than session-scoped,
  so it cannot poison the pool — but it is not the safe form either. `SET
  LOCAL` persists for the remainder of the transaction, and `Ecto.Migrator`
  inserts its `schema_migrations` version row inside that same transaction
  AFTER the migration body, so a `LOCAL` pin inside a migration redirects
  Ecto's own bookkeeping INSERT to a path holding no `schema_migrations`
  table. That is a second, separately-observed 42P01 class (four failures in
  `shipped_migration_divergence_test.exs` on the mailglass axis), which is why
  the Credo check bans both spellings and points here instead.

  Options: `:repo` (default `Mailglass.TestRepo`) and `:caller` (default: the
  calling test's module, resolved the same way `checkout!/1` resolves it) so
  the raise names the module at fault. Also accepts an injectable
  `:search_path_fun` (default `&SHOW search_path` against `repo`) used ONLY for
  the post-restore verification read, mirroring `with_schema!/2`'s `:schema_fun`
  idiom — so the "restore did not land" raise path is testable with a synthetic
  mismatch rather than by genuinely poisoning the suite's connection pool.
  """
  @spec with_search_path!(String.t(), (-> result), keyword()) :: result when result: var
  def with_search_path!(search_path, fun, opts \\ [])
      when is_binary(search_path) and is_function(fun, 0) do
    repo = Keyword.get(opts, :repo, Mailglass.TestRepo)
    caller = Keyword.get(opts, :caller) || calling_test_module() || __MODULE__
    search_path_fun = Keyword.get(opts, :search_path_fun, &current_search_path/1)

    repo.checkout(fn ->
      prior = current_search_path(repo)

      try do
        _ = repo.query!("SET search_path TO #{search_path}", [])
        fun.()
      after
        _ = repo.query!("SET search_path TO #{prior}", [])

        restored = search_path_fun.(repo)

        unless restored == prior do
          raise SearchPathError, caller: caller, expected: prior, actual: restored
        end
      end
    end)
  end

  defp current_search_path(repo) do
    %{rows: [[value]]} = repo.query!("SHOW search_path", [])
    value
  end

  @doc """
  Directly sets `repo`'s Sandbox pool to `:manual` mode via
  `Ecto.Adapters.SQL.Sandbox.mode/2`.

  This is the one raw write `Mailglass.Credo.NoRawSandboxOwnership` (plan
  `143-08`) allows to happen only from behind this door. It has exactly two
  legitimate callers, both migrated to route through it rather than call
  `Ecto.Adapters.SQL.Sandbox.mode/2` directly:

    * `test/test_helper.exs`'s suite-wide boot: the pool starts in Sandbox's
      own default mode, and `Sandbox.checkout/checkin` need `:manual` set
      before any test can check out an owner at all. This is not a release —
      no owner exists yet at this point in boot.
    * A pre-release healing call in `deliver_many_test.exs` and
      `deliver_later_test.exs`: both `use Mailglass.DataCase, async: false`
      and rely on `DataCase`'s own `checkout!(shared: true)` for the actual
      acquire/release pairing. ExUnit runs `on_exit` callbacks in reverse
      registration order, and each of these files' own `setup` block
      registers its `on_exit` AFTER `DataCase`'s composed setup already
      registered `checkout!/1`'s release — so this call runs BEFORE that
      release, reverting the pool to `:manual` a moment early so
      `Task.Supervisor` background work has already settled.
      `checkout!/1`'s own release (which runs immediately after this, and
      DOES verify via `assert_manual!/3`) is still the operation that owns
      the acquire/release invariant for these two files; this call is a
      convenience revert, not a second release path.

  Neither caller acquires or releases an owner through this function — it
  performs no `start_owner!`/`stop_owner` pairing of its own, so it does not
  reintroduce the ordering bug `checkout!/1` exists to prevent. New test code
  needing pool-mode mutation almost certainly wants `checkout!/1` instead;
  this function exists only for the two caller shapes documented above.

  **Why the `!` is real (D-17).** `Ecto.Adapters.SQL.Sandbox.mode/2` is spec'd
  `:ok | :already_shared | :not_owner | :not_found`, and this function
  previously returned that value verbatim while claiming `:ok` in its own
  `@spec` — a `!`-suffixed function handing back a non-success as if it were a
  result nobody has to look at. All three call sites discard the return, so a
  refusal was being dropped on the floor: `test_helper.exs` would have booted
  the whole suite against a pool whose mode was never established, and the two
  `deliver_*` reverts would have reported a heal that did not happen. The
  contract is now succeed-or-raise, and the `@spec` is true by construction
  rather than by hope.

  A non-raising variant is deliberately NOT provided: no call site in this repo
  pattern-matches the result (verified across `test/test_helper.exs:168`,
  `deliver_many_test.exs:45`, `deliver_later_test.exs:63`), and a silent
  variant would immediately recreate the discarded-signal defect this change
  removes. The refusal is raised as `LeakError` — not a bespoke exception —
  so `SuiteTruthFormatter.signature/1` folds it into the same
  `:already_shared` tally D-17 requires to be exactly zero. A refusal reported
  under a name nothing is watching is the vacuity that error exists to prevent.

  Both refusal paths are documented as unreachable on today's dependency
  versions (Ecto: "this is always successful for `:auto` and `:manual` modes";
  db_connection `manager.ex:165-172`: both `:manual` clauses reply `:ok`), which
  is precisely why the check is cheap and why leaving it out was tempting. An
  unreachable branch that would be catastrophic if reached is exactly the
  branch worth spending three lines on.

  Accepts an injectable `:mode_fun` (default
  `&Ecto.Adapters.SQL.Sandbox.mode/2`) and `:caller`, mirroring
  `assert_manual!/3`'s `probe_fun:` and `with_schema!/2`'s `schema_fun:`
  idioms, so the raise path is provable from a synthetic refusal without
  corrupting the live pool.
  """
  @spec mode_manual!(module(), keyword()) :: :ok
  def mode_manual!(repo \\ Mailglass.TestRepo, opts \\ []) do
    mode_fun = Keyword.get(opts, :mode_fun, &Ecto.Adapters.SQL.Sandbox.mode/2)
    caller = Keyword.get(opts, :caller) || calling_test_module() || __MODULE__

    case mode_fun.(repo, :manual) do
      :ok -> :ok
      refusal -> raise LeakError, caller: caller, refused_with: refusal
    end
  end

  @doc """
  Runs `fun` outside the Sandbox transaction via
  `Ecto.Adapters.SQL.Sandbox.unboxed_run/2` — the preferred forward idiom
  (D-12) for a new test needing committed, non-transactional writes.

  Process-local rather than pool-global, which removes the acquire/release
  bug class entirely for the caller. It cannot replace pool-wide `:auto`
  (`unsandboxed_module/1`) where `Ecto.Migrator.with_repo/2` spawns a process
  this function's caller-local lift does not cover — `unboxed_run/2` only
  lifts the sandbox for the calling process's own checkout, and a
  `with_repo`-spawned task never inherits it.
  """
  @spec unsandboxed(module(), (-> result)) :: result when result: var
  def unsandboxed(repo \\ Mailglass.TestRepo, fun) when is_function(fun, 0) do
    Ecto.Adapters.SQL.Sandbox.unboxed_run(repo, fun)
  end

  @doc """
  Reads `repo`'s Sandbox pool ownership mode without mutating it.

  Returns `:ok` when the pool is already `:manual` (the expected steady state
  between `async: false` module boundaries). Returns `{:leaked, mode}` for any
  other observed mode — `{:shared, pid}` (the ownership-leak class HARNESS-01
  names) or `:auto` (a module that switched pool-wide auto mode and never
  restored it). A probe that cannot observe its subject must never report
  green: if the ownership manager cannot be found for `repo` at all, that is
  reported as `{:leaked, :cannot_verify}` rather than treated as `:ok`.
  """
  @spec probe(module()) :: :ok | {:leaked, term()}
  def probe(repo \\ Mailglass.TestRepo) do
    case current_mode(repo) do
      :manual -> :ok
      other -> {:leaked, other}
    end
  end

  defp current_mode(repo) do
    case Ecto.Adapter.lookup_meta(repo) do
      %{pid: manager_pid} when is_pid(manager_pid) ->
        %{mode: mode} = :sys.get_state(manager_pid)
        mode

      _ ->
        :cannot_verify
    end
  rescue
    # `:sys.get_state/1` raises if the manager pid is gone (e.g. the repo was
    # stopped between checkout and probe). Report it, never report green.
    _ -> :cannot_verify
  end

  @doc """
  Probes `repo` and raises `LeakError` (naming `caller`) when the pool is not
  `:manual`. Returns `:ok` when it is.

  Accepts an injectable `:probe_fun` (default `&probe/1`), mirroring
  `Mailglass.TestSupport.CitextProbe`'s `probe_fun:` idiom, so the raise path
  is testable without manufacturing a real leak.

  **Bounded settle window (`:attempts`/`:interval_ms`), confirmed empirically
  against the real pool:** `stop_owner/1`'s heal is NOT synchronous with its
  own return. `GenServer.stop/1` confirms the owner Agent itself has
  terminated, but the ownership manager's `unshare/2` (`manager.ex:242`) only
  runs after its own monitor on the checkout proxy fires — one more
  message-passing hop AFTER the agent is confirmed dead. Calling
  `assert_manual!/3` in the same breath as `stop_owner/1` returning (exactly
  what `checkout!/1`'s `on_exit` does) can observe a transient, already-
  releasing `{:shared, pid}` that clears within single-digit milliseconds.
  Retrying briefly (default 30 attempts, 5ms apart — ~150ms bound, comfortably
  above the ~50ms observed live) absorbs that benign propagation delay
  without masking a genuine leak: a mode that has NOT healed within the bound
  still raises exactly as before. This is verification, not tolerance — the
  bound is a ceiling, not a retry-until-green loop.

  **Exhausting the bound is classified, not assumed (CI run `30555218236`,
  job `90913824954`, seed 79310).** That advisory leg failed with exactly one
  failure — this function raising `LeakError` from inside `checkout!/1`'s own
  `on_exit`, reporting `{:shared, #PID<0.6430.0>}` after the bound ran out.
  The bound alone cannot tell the two states it was conflating apart, and only
  one of them is HARNESS-01's leak:

    * **Holder ALIVE** — the pool is genuinely blocked. `manager.ex:153-154`
      replies `:already_shared` to the next `start_owner!(shared: true)`, which
      badmatches at `sandbox.ex:458`. This is the leak, and it raises.
    * **Holder DEAD** — `manager.ex:156-157` transparently replaces a dead
      shared owner (`share_and_reply/3`), so the next shared acquisition
      SUCCEEDS. The manager simply has not processed the proxy's `:DOWN` yet;
      `handle_info({:DOWN, ...})` (`manager.ex:241-243`) runs `owner_down/2`
      and `unshare/2` together, so this state is transient and self-clearing
      by construction. It cannot block anything.

  `checkout!/1`'s `on_exit` calls `stop_owner/1` — a synchronous
  `GenServer.stop/1` — immediately before calling this function, so its own
  owner is *guaranteed dead* by the time this runs. On a fast box the manager
  catches up inside 150ms and the pool reads `:manual`; on a loaded 2-core CI
  runner, after a module that pushed ~800 statements through the shared
  connection (`webhook_signature_failure_test.exs` runs 200 property
  iterations × 4 statements), it does not. Whether the assertion passed was
  therefore decided by runner load, not by whether anything leaked.

  So the exhausted-bound branch now reads the holder's liveness — the same
  discriminator `manager.ex:153` itself uses, and the same mode-then-liveness
  read `live_holder/1` already performs. This is a **narrowing** of what counts
  as success, expressed exactly: the predicate verified is the one this
  function exists to protect — *"the next `start_owner!(shared: true)` will not
  collide"* — rather than the strictly-stronger-but-partly-irrelevant proxy
  *"the mode field currently reads `:manual`"*. It can never green-light a live
  holder, which is the only state that blocks anything. It is deliberately NOT
  a widened timeout: widening the bound would have made the same flake rarer
  while leaving the verdict decided by load, and would have edged toward the
  120s `ownership_timeout` at which a genuine leak self-heals — masking the
  real class. The bound is unchanged at ~150ms.
  """
  @spec assert_manual!(module(), term(), keyword()) :: :ok
  def assert_manual!(repo \\ Mailglass.TestRepo, caller, opts \\ []) do
    probe_fun = Keyword.get(opts, :probe_fun, &probe/1)
    attempts = Keyword.get(opts, :attempts, 30)
    interval_ms = Keyword.get(opts, :interval_ms, 5)

    do_assert_manual!(repo, caller, probe_fun, attempts, interval_ms)
  end

  defp do_assert_manual!(repo, caller, probe_fun, attempts, interval_ms) do
    case probe_fun.(repo) do
      :ok ->
        :ok

      # The full bound is always spent first — a clean `:manual` reading is
      # preferred, and the liveness proof below is only ever the fallback.
      {:leaked, _mode} when attempts > 1 ->
        Process.sleep(interval_ms)
        do_assert_manual!(repo, caller, probe_fun, attempts - 1, interval_ms)

      # Bound exhausted on a shared mode: classify instead of guessing. A DEAD
      # holder is provably not the collision class — `manager.ex:156-157`
      # replaces it and the next `start_owner!(shared: true)` succeeds — so
      # this is a verified pass, not a silent one. A LIVE holder falls through
      # to the raise below. See this function's @doc for the CI evidence
      # (run 30555218236) and why this is a narrowing rather than a widened
      # timeout.
      {:leaked, {:shared, holder}} when is_pid(holder) ->
        if Process.alive?(holder) do
          raise LeakError, caller: caller, mode: {:shared, holder}
        else
          :ok
        end

      # Every other unhealed mode (`:auto`, `:cannot_verify`, anything a future
      # db_connection adds) still raises. Non-observation must never read as
      # success.
      {:leaked, mode} ->
        raise LeakError, caller: caller, mode: mode
    end
  end

  @doc """
  Returns the currently-registered shared owner pid when `repo`'s pool is
  genuinely shared and that pid is alive, otherwise `nil`.

  Keyed on **pool mode**, not on agent liveness: after a timeout-driven heal
  (or a `mode(:auto)`/`mode(:manual)` cycle) the leaked owner Agent can still
  be *alive* while holding no connection and no mode — a liveness-keyed
  reader would misreport a healed pool as still having a live holder. Reading
  the mode first means a healed pool reports `nil` even while the zombie
  Agent lingers.
  """
  @spec live_holder(module()) :: pid() | nil
  def live_holder(repo \\ Mailglass.TestRepo) do
    case current_mode(repo) do
      {:shared, pid} when is_pid(pid) -> if Process.alive?(pid), do: pid, else: nil
      _ -> nil
    end
  end

  # ENUMERATED FROM THE SHIPPED INSTALL MIGRATION, not from a CI log excerpt.
  # `Mailglass.Migration.up/1` dispatches v01..v05
  # (`lib/mailglass/migrations/postgres/`), and exactly four `create table`
  # calls exist across all five steps:
  #
  #   v01.ex:21  create table(:mailglass_deliveries, prefix: prefix)
  #   v01.ex:77  create table(:mailglass_events, prefix: prefix)
  #   v01.ex:163 create table(:mailglass_suppressions, prefix: prefix)
  #   v02.ex:28  create table(:mailglass_webhook_events, prefix: prefix)
  #
  # v03/v04/v05 add columns, indexes and constraints only — no further tables.
  # Re-derive this list with:
  #   grep -rn 'create table' lib/mailglass/migrations/
  #
  # `mailglass_events` was ABSENT from this list until the 143 gap-closure pass,
  # which is why every `baseline_tables_present?/1` call site reported a restore
  # it had not actually verified: the append-only ledger — the first relation CI
  # named as missing — was the one relation the probe could not observe. A check
  # that cannot observe its subject must not report success, and an incomplete
  # subject list is exactly that failure wearing a `true`.
  @baseline_relations ~w(mailglass_deliveries mailglass_events mailglass_suppressions mailglass_webhook_events)

  @doc """
  Checks whether all four baseline relations the shipped install migration
  creates (`mailglass_deliveries`, `mailglass_events`, `mailglass_suppressions`,
  `mailglass_webhook_events`) exist in the schema `Mailglass.Config.schema()`
  currently resolves to — Class A (D-31): the migration baseline was torn down
  and not restored.

  Prefer `assert_baseline_intact!/2` from a test call site: it raises, naming
  the calling module and the absent relations, rather than returning a value a
  caller can forget to inspect. This predicate form exists for
  `Mailglass.TestSupport.SuiteTruthFormatter`, which records a violation
  instead of raising.

  Read-only. Queries Postgres' `information_schema.tables` catalog — never
  `CREATE TABLE`, never a migration, never anything that could make an
  absent relation "found" as a side effect of looking. Runs through
  `Ecto.Adapters.SQL.Sandbox.unboxed_run/2` so a caller with no `Sandbox`
  checkout of its own (the formatter's own `GenServer` process, which
  belongs to no test) can run the query at all — confirmed live to leave
  the pool's ownership mode unchanged before and after, and it never
  commits, rolls back, or restores anything in the sandboxed test
  transaction itself.

  Returns:

    * `true` — all four relations are present in the current schema.
    * `{false, missing}` — `missing` is the subset of `@baseline_relations`
      not found. Never merely `false`, so the formatter can name exactly
      what's absent without a second query.
    * `{:cannot_verify, sqlstate_or_term}` — the query itself failed. A
      probe that cannot observe its subject must never report `true`.
  """
  @spec baseline_tables_present?(module()) ::
          true | {false, [String.t()]} | {:cannot_verify, term()}
  def baseline_tables_present?(repo \\ Mailglass.TestRepo) do
    schema = Mailglass.Config.schema()

    Ecto.Adapters.SQL.Sandbox.unboxed_run(repo, fn ->
      Ecto.Adapters.SQL.query(
        repo,
        "SELECT table_name FROM information_schema.tables " <>
          "WHERE table_schema = $1 AND table_name = ANY($2::text[])",
        [schema, @baseline_relations],
        []
      )
    end)
    |> classify_baseline_result()
  rescue
    error -> {:cannot_verify, error}
  end

  defp classify_baseline_result({:ok, %{rows: rows}}) do
    present = rows |> List.flatten() |> MapSet.new()
    missing = Enum.reject(@baseline_relations, &MapSet.member?(present, &1))

    if missing == [], do: true, else: {false, missing}
  end

  defp classify_baseline_result({:error, %Postgrex.Error{postgres: %{pg_code: pg_code}}}) do
    {:cannot_verify, pg_code}
  end

  defp classify_baseline_result({:error, error}) do
    {:cannot_verify, error}
  end

  @doc """
  Asserts every baseline relation is present in the schema
  `Mailglass.Config.schema/0` resolves to, raising `BaselineError` (naming
  `caller`) when any is absent OR when their presence could not be observed.
  Returns `:ok` otherwise.

  This is the raising counterpart to `baseline_tables_present?/1`, and the form
  every test call site should use. Four modules previously hand-rolled the same
  three-clause `case` around the predicate, each with its own message wording;
  one of the four also wrapped it in an axis guard that skipped the check
  entirely on the axis where it mattered most. Collapsing them onto one
  function makes the "cannot verify" branch impossible to omit by accident.

  Read-only, deliberately: it observes and reports, it never restores. Healing
  a baseline as a side effect of looking at it is the exact behavior D-31
  forbids, because it turns a reproducible corruption into an invisible one.
  A caller that genuinely needs to restore the baseline (because it tore the
  baseline itself down by design) restores first, then calls this to verify the
  restore actually landed.

  Accepts an injectable `:baseline_fun` (default `&baseline_tables_present?/1`)
  and `:schema_fun` (default `&Mailglass.Config.schema/0`), mirroring
  `assert_manual!/3`'s `probe_fun:` idiom, so both raise paths are testable
  without dropping real tables.
  """
  @spec assert_baseline_intact!(module(), term(), keyword()) :: :ok
  def assert_baseline_intact!(repo \\ Mailglass.TestRepo, caller, opts \\ []) do
    baseline_fun = Keyword.get(opts, :baseline_fun, &baseline_tables_present?/1)
    schema_fun = Keyword.get(opts, :schema_fun, &Mailglass.Config.schema/0)

    case baseline_fun.(repo) do
      true ->
        :ok

      {false, missing} ->
        raise BaselineError, caller: caller, schema: schema_fun.(), missing: missing

      {:cannot_verify, reason} ->
        raise BaselineError, caller: caller, schema: schema_fun.(), reason: reason
    end
  end

  @doc """
  Runs `fun` with `Code.put_compiler_option(:ignore_module_conflict, true)`
  scoped to the call, restoring the prior value in an `after` block —
  HARNESS-02's `redefining module Mailglass.TestRepo.Migrations.*` blocker.

  Every migration-restore call site that re-scans the FLAT
  `priv/repo/migrations/` directory via `Ecto.Migrator.run/4` (as opposed to
  an inline, in-test `Ecto.Migration` module defined once) reloads
  already-compiled modules the very first `mix compile` or `test_helper.exs`
  boot already loaded into memory. BEAM warns on redefining an
  already-loaded module every time this happens, and
  `--warnings-as-errors` aborts the run AFTER a fully successful execution
  — `mix test test/mailglass/upgrade_v2_schema_migration_test.exs
  --warnings-as-errors` reports "6 tests, 0 failures" and then aborts on
  exactly this warning class.

  Scoped, not global: the option is set immediately before `fun.()` runs and
  restored to whatever it was before in an `after` block, so a genuine
  redefinition warning anywhere else in the same test run (a real bug this
  milestone exists to catch) is still reported normally.
  """
  @spec reloading_flat_migrations((-> result)) :: result when result: var
  def reloading_flat_migrations(fun) when is_function(fun, 0) do
    prior = Code.get_compiler_option(:ignore_module_conflict)
    Code.put_compiler_option(:ignore_module_conflict, true)

    try do
      fun.()
    after
      Code.put_compiler_option(:ignore_module_conflict, prior)
    end
  end
end
