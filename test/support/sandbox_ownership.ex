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
  defexception [:caller, :mode]

  @impl true
  def message(%__MODULE__{caller: caller, mode: mode}) do
    "Mailglass.TestSupport.SandboxOwnership: #{inspect(caller)} released a Sandbox " <>
      "owner but the pool is still #{inspect(mode)}, not :manual. Either stop_owner/1 " <>
      "did not check the connection in, or another process re-shared the pool before " <>
      "the release could be observed. Find what re-acquired shared mode after " <>
      "#{inspect(caller)}'s release should have restored :manual."
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
  - `unsandboxed/2` — the preferred forward idiom for a single committed write.
  - `probe/1` — read-only pool-mode observation (never mutates).
  - `assert_manual!/3` — raises `LeakError` when the pool is not `:manual`.
  - `live_holder/0` — the current shared-owner pid, or `nil`.
  - `baseline_tables_present?/1` — read-only baseline-relation check (Class A).

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
     mode, `:async_adapter`/`:async_adapter_impl`, the adapter. This stays
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

      # In `Mailglass.TestSupport.SuiteTruthFormatter`'s `:module_finished` handler:
      Mailglass.TestSupport.SandboxOwnership.probe(Mailglass.TestRepo)
      Mailglass.TestSupport.SandboxOwnership.baseline_tables_present?(Mailglass.TestRepo)
  """

  alias Mailglass.TestSupport.SandboxOwnership.LeakError

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
  """
  @spec checkout!(keyword()) :: pid()
  def checkout!(opts \\ []) do
    {repo, opts} = Keyword.pop(opts, :repo, Mailglass.TestRepo)
    {calling_module_fun, opts} = Keyword.pop(opts, :calling_module_fun, &calling_test_module/0)
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
      if shared?, do: assert_manual!(repo, calling_module_fun.() || __MODULE__)
    end)

    owner
  end

  defp guard_shared_checkout_from_async!(calling_module_fun) do
    case calling_module_fun.() do
      module when is_atom(module) and not is_nil(module) ->
        if async_module?(module) do
          raise """
          Mailglass.TestSupport.SandboxOwnership: `checkout!(shared: true)` MUST NOT \
          be called from an async: true module (#{inspect(module)}). Shared mode is \
          process-global pool state — concurrent async tests sharing it would stomp \
          each other. Pass `shared: false` instead (or, for cross-process delivery, \
          use `Ecto.Adapters.SQL.Sandbox.allow/3` from an owned, non-shared checkout).
          """
        end

      _ ->
        :ok
    end
  end

  defp calling_test_module do
    case Process.get(:"$process_label") do
      {module, test_name} when is_atom(module) and is_atom(test_name) -> module
      _ -> nil
    end
  end

  defp async_module?(module) do
    function_exported?(module, :__ex_unit__, 1) and
      match?(%{async?: true}, module.__ex_unit__(:config))
  end

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
      Ecto.Adapters.SQL.Sandbox.mode(repo, :manual)
    end)

    :ok
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
  """
  @spec assert_manual!(module(), term(), keyword()) :: :ok
  def assert_manual!(repo \\ Mailglass.TestRepo, caller, opts \\ []) do
    probe_fun = Keyword.get(opts, :probe_fun, &probe/1)

    case probe_fun.(repo) do
      :ok -> :ok
      {:leaked, mode} -> raise LeakError, caller: caller, mode: mode
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

  @baseline_relations ~w(mailglass_deliveries mailglass_suppressions mailglass_webhook_events)

  @doc """
  Checks whether the three CI-log-named baseline relations
  (`mailglass_deliveries`, `mailglass_suppressions`, `mailglass_webhook_events`)
  exist in the schema `Mailglass.Config.schema()` currently resolves to —
  Class A (D-31): the migration baseline was torn down and not restored.

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

    * `true` — all three relations are present in the current schema.
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
end
