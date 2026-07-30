defmodule Mailglass.TestSupport.SuiteTruthFormatter do
  @moduledoc """
  ExUnit formatter that observes every `async: false` module boundary in a
  `mix test` run and names any module that leaks the Sandbox pool's ownership
  mode, the instant it happens (HARNESS-01, D-08, D-09).

  Background: an ExUnit formatter is a plain `GenServer` registered via
  `ExUnit.configure(formatters: [...])`. ExUnit routes every event —
  `:suite_started`, `:module_started`, `:module_finished`, `:test_started`,
  `:test_finished`, `:suite_finished` — through `handle_cast/2` regardless of
  which `ExUnit.CaseTemplate` (or none) a module uses. That is the property
  this phase needs: zero opt-in. A new test file that forgets to register a
  cleanup callback is still observed the day it is written.

  This formatter delegates every pool judgment to
  `Mailglass.TestSupport.SandboxOwnership.probe/1` and
  `SandboxOwnership.baseline_tables_present?/1` rather than re-implementing
  them (D-09), so the negative-control tests in `suite_truth_formatter_test.exs`
  exercise the real code path.

  At every `async: false` module boundary this formatter inventories all
  three leak classes named in D-31 (`143-CONTEXT.md`):

  - **Class C — `:pool_mode_leaked`.** The Sandbox pool's ownership mode is
    not `:manual` (`SandboxOwnership.probe/1`).
  - **Class B — `:config_schema_drift`.** `Mailglass.Config.schema()` no
    longer equals the value captured at `:suite_started`.
  - **Class A — `:baseline_missing`.** One or more of the three baseline
    relations the CI logs name are absent from the current schema
    (`SandboxOwnership.baseline_tables_present?/1`).

  Every class also has a `:cannot_verify` outcome for when the check itself
  could not run — never silently treated as a pass.

  At every `:test_finished` event this formatter ALSO classifies each
  failure into the closed D-17 signature set (`signature/1`) and tallies it —
  the `:already_shared` count (raw badmatch AND the composed
  `SandboxOwnership.LeakError`, combined) is the count HARNESS-01's
  regression guard asserts is exactly zero. See `signature/1`'s own docs for
  the closed atom set and why every clause matches structurally, never by
  message string (CLAUDE.md).

  ## State

  - `:violations` — list of violation records, newest first. Each record is
    `%{module: module(), class: atom(), result: term()}`.
  - `:boot_schema` — the value of `Mailglass.Config.schema()` captured at
    `:suite_started`. `nil` until that event fires.
  - `:trace?` — whether `System.get_env("MAILGLASS_SANDBOX_TRACE") == "1"`.
    Only when true does `:suite_finished` print the accumulated ledger.
  - `:probe_fun` — `(module() -> :ok | {:leaked, term()})`, defaults to
    `&SandboxOwnership.probe/1`. Overridable via `new_state/1` so tests can
    drive the leaked path without a real Sandbox leak — the same seam
    `Mailglass.TestSupport.CitextProbe` exposes as `probe_fun:`.
  - `:schema_fun` — `(-> String.t())`, defaults to `&Mailglass.Config.schema/0`.
    Called BOTH at `:suite_started` (to capture `:boot_schema`) and at every
    `:module_finished` boundary (to detect drift) — a single seam so tests
    can inject a synthetic schema sequence without touching real Application
    env or `:persistent_term`.
  - `:baseline_fun` — `(module() -> true | {false, [String.t()]} |
    {:cannot_verify, term()})`, defaults to
    `&SandboxOwnership.baseline_tables_present?/1`. Overridable so tests can
    drive the missing/`:cannot_verify` paths without a real Postgres query.
  - `:signature_tally` — `%{atom() => pos_integer()}`, one of `signature/1`'s
    closed atom set per key, incremented at every `:test_finished` failure.
    Absent keys mean zero, never a stored zero.

  ## Cross-process read path (D-17, D-09) — how `SuiteFloor.check/1` reads this state

  `SuiteFloor.check/1` runs in a different process (the `mix test` runner,
  via `ExUnit.after_suite/1`) than this GenServer, and needs
  `:signature_tally`/`:violations` to build the counts it asserts on.

  **A name-registered `:sys.get_state/1` read (mirroring
  `SandboxOwnership.probe/1`'s idiom for the ownership manager) does NOT
  work here — confirmed empirically, not merely reasoned about, by
  decompiling `ExUnit.Runner`'s abstract code.** `ExUnit.Runner.run/2` calls
  `ExUnit.EventManager.stop/1` — which `DynamicSupervisor.stop/1`s the
  supervisor every formatter (including this one) was started under —
  BEFORE it invokes the configured `:after_suite` callbacks. By the time
  `SuiteFloor.check/1` runs, this GenServer is already terminated; a
  name-registered pid lookup always returns `nil`, every time, not merely
  under contention. A first draft of this module registered a name and
  called `:sys.get_state/1` from `SuiteFloor.check/1`, ran it against a real
  suite, and observed `current_state/0` return `:unavailable` on every run —
  the dead-process read is not a hypothetical, it is what actually happens.

  Instead, `handle_cast({:suite_finished, ...})` — the LAST event this
  formatter receives while still alive — persists a final snapshot
  (`%{signature_tally:, violations:}`) to `:persistent_term`, an idiom
  already established in this codebase (`SandboxOwnership.with_schema!/2`).
  `:persistent_term` outlives any individual process, including this one
  once `EventManager.stop/1` terminates it. This remains a SINGLE source of
  truth, not a duplicate one: this formatter is still the only place
  classification/tallying happens: only the READ boundary changed, from a
  live-process peek (impossible given the ordering above) to a
  process-independent snapshot written at the one point in this GenServer's
  own lifecycle guaranteed to be final. `current_state/0` is the documented
  read accessor; `SuiteFloor.check/1` is its one documented caller. Ordering
  safety: `:suite_finished` is ExUnit's LAST event, firing only after every
  test in every module (including this formatter's own unit tests in
  `suite_truth_formatter_test.exs`, which call `handle_cast/2` directly with
  synthetic state) has completed — so the real, live formatter's write is
  always the final write this key receives before `check/1` reads it,
  regardless of what any unit test wrote earlier in the same run.

  ## Divergences from `ExUnit.CLIFormatter`

  1. This formatter never prints test/failure output — `ExUnit.CLIFormatter`
     stays registered alongside it and owns that job (D-09; the `--formatter`
     CLI flag is deliberately never used here because it *replaces* the
     default formatter list rather than adding to it).
  2. Silent by default. The ledger only prints under
     `MAILGLASS_SANDBOX_TRACE=1` — this instrument is diagnostic, not part of
     the suite's normal output.
  3. Never emits test data, recipient addresses, subjects, or bound
     query-parameter values (T-143-01). Ledger records carry only module
     names, class atoms, and probe results (pool modes / schema names /
     counts), the same whitelist CLAUDE.md imposes on telemetry metadata.
  """

  use GenServer

  alias Mailglass.TestSupport.SandboxOwnership

  @persistent_term_key {__MODULE__, :final_state}

  # ──────────────────────────────────────────────────────────────
  # Public API
  # ──────────────────────────────────────────────────────────────

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  # Builds a fresh accumulator state, for use by both `init/1` and (with
  # overrides) by tests that want to drive `handle_cast/2` directly without a
  # real Sandbox leak. See `citext_probe.ex`'s `probe_fun:` seam for the same
  # idiom.
  @doc false
  @spec new_state(keyword()) :: map()
  def new_state(overrides \\ []) do
    %{
      violations: [],
      boot_schema: nil,
      trace?: trace_enabled?(),
      probe_fun: &SandboxOwnership.probe/1,
      schema_fun: &Mailglass.Config.schema/0,
      baseline_fun: &SandboxOwnership.baseline_tables_present?/1,
      signature_tally: %{}
    }
    |> Map.merge(Map.new(overrides))
  end

  @doc """
  Reads the final snapshot this formatter persisted at `:suite_finished` —
  see the moduledoc's "Cross-process read path" section for why this reads
  `:persistent_term` rather than a live process (`:suite_finished` is the
  last point this GenServer is guaranteed alive; `SuiteFloor.check/1` always
  runs after `ExUnit.EventManager.stop/1` has already terminated it).
  Returns `:unavailable` (never a default empty state) when no run has
  reached `:suite_finished` yet, so a caller that cannot observe this
  formatter's tally reports "unverifiable," never a silent zero.
  `SuiteFloor.check/1` is this function's one documented caller.
  """
  @spec current_state() :: map() | :unavailable
  def current_state do
    :persistent_term.get(@persistent_term_key, :unavailable)
  end

  defp trace_enabled?, do: System.get_env("MAILGLASS_SANDBOX_TRACE") == "1"

  # ──────────────────────────────────────────────────────────────
  # GenServer / ExUnit.Formatter callbacks
  # ──────────────────────────────────────────────────────────────

  @impl true
  def init(_opts), do: {:ok, new_state()}

  @impl true
  def handle_cast({:suite_started, _opts}, state) do
    {:noreply, %{state | boot_schema: state.schema_fun.()}}
  end

  def handle_cast({:module_finished, %ExUnit.TestModule{} = test_module}, state) do
    if async_false?(test_module) do
      state =
        state
        |> probe_pool_mode(test_module)
        |> probe_config_schema_drift(test_module)
        |> probe_baseline_tables(test_module)

      {:noreply, state}
    else
      {:noreply, state}
    end
  end

  # D-17: classify every failure this test carried and tally it. Must sit
  # BEFORE the catch-all %ExUnit.Test{} clause below (first-match-wins).
  def handle_cast({:test_finished, %ExUnit.Test{state: {:failed, failures}}}, state) do
    updated_tally =
      Enum.reduce(failures, state.signature_tally, fn failure, tally ->
        Map.update(tally, signature(failure), 1, &(&1 + 1))
      end)

    {:noreply, %{state | signature_tally: updated_tally}}
  end

  def handle_cast({:test_finished, %ExUnit.Test{}}, state) do
    {:noreply, state}
  end

  def handle_cast({:suite_finished, _times_us}, state) do
    # D-17/D-09: the last point this GenServer is guaranteed alive — see the
    # moduledoc's "Cross-process read path" section. `SuiteFloor.check/1`
    # runs after this process is already terminated, so the final tally must
    # cross the boundary here, not be peeked at from a later, dead process.
    :persistent_term.put(@persistent_term_key, %{
      signature_tally: state.signature_tally,
      violations: state.violations
    })

    if state.trace? do
      print_ledger(state.violations)
    end

    {:noreply, state}
  end

  # Catch-all: an unknown future ExUnit event (or a deprecated
  # `:case_started`/`:case_finished`) must never crash the run.
  def handle_cast(_event, state), do: {:noreply, state}

  # ──────────────────────────────────────────────────────────────
  # Internal
  # ──────────────────────────────────────────────────────────────

  defp async_false?(%ExUnit.TestModule{tags: tags}), do: tags[:async] == false

  # `SandboxOwnership.probe/1` is a pure read (`:sys.get_state/1` on the
  # ownership manager) — it never mutates the pool, so calling it here has no
  # effect on which connections are checked out or on the run's pass/fail
  # status. This is deliberate: an earlier version of `probe/1` called
  # `Sandbox.mode(repo, :manual)` directly, which both detects AND heals in
  # one call (it checks in every live connection unconditionally) — that
  # collapsed detection into healing, made `{:leaked, term}` unreachable (the
  # underlying call always replies `:ok`), and would have silently masked
  # every leak this phase exists to expose. See `sandbox_ownership.ex`'s
  # moduledoc for the full account.
  #
  # D-10 (carried forward for whoever adds a heal step later, e.g. Wave 2's
  # `SandboxOwnership.checkout!/1`): any FUTURE call that heals by resetting
  # pool mode is safe ONLY because `ExUnit.Runner.async_loop/4` waits for
  # `map_size(running) == 0` before spawning any `async: false` module — sync
  # modules run strictly after, and strictly serially to, async modules. Such
  # a call must never run while an async module's connection is still checked
  # out. This probe does not heal, so that constraint is not yet exercised by
  # this module — record it here so it isn't lost when healing is added.
  defp probe_pool_mode(state, %ExUnit.TestModule{name: name}) do
    case state.probe_fun.(Mailglass.TestRepo) do
      :ok -> state
      {:leaked, result} -> add_violation(state, name, :pool_mode_leaked, result)
    end
  end

  # Class B (D-31). `schema_fun` is a pure read
  # (`Mailglass.Config.schema/0`'s `:persistent_term` getter, or its
  # test-injected replacement) — this check never mutates the cache, never
  # calls `Application.put_env/3`, and never re-derives/re-validates
  # anything. Widening to "just re-read and warm the cache to make it agree"
  # would be the exact same detect-and-heal collapse `probe/1` was fixed for
  # in Class C, in a new class.
  #
  # `nil` `:boot_schema` means `:suite_started` never fired on this state
  # (only possible when a test drives `handle_cast/2` directly without it) —
  # skip rather than manufacture a drift violation against an unset baseline.
  defp probe_config_schema_drift(%{boot_schema: nil} = state, _test_module), do: state

  defp probe_config_schema_drift(state, %ExUnit.TestModule{name: name}) do
    observed = state.schema_fun.()

    if observed == state.boot_schema do
      state
    else
      add_violation(state, name, :config_schema_drift, %{
        boot: state.boot_schema,
        observed: observed
      })
    end
  end

  # Class A (D-31). Order matters: this runs AFTER `probe_config_schema_drift/2`
  # above. A drifted `Config.schema()` (Class B) would make THIS query look
  # for the baseline relations in the wrong schema — reporting a false
  # `:baseline_missing` for a schema that was simply never the one holding
  # them, misattributing a Class B bug as a Class A one. Checking B first
  # means a genuine Class A finding is only ever reported once the schema
  # itself is confirmed unchanged since boot.
  #
  # `baseline_fun` (`SandboxOwnership.baseline_tables_present?/1` by default)
  # is read-only — never `CREATE TABLE`, never a migration. See that
  # function's moduledoc for why it never mutates the pool either.
  defp probe_baseline_tables(state, %ExUnit.TestModule{name: name}) do
    case state.baseline_fun.(Mailglass.TestRepo) do
      true ->
        state

      {false, missing} ->
        add_violation(state, name, :baseline_missing, missing)

      {:cannot_verify, sqlstate_or_term} ->
        add_violation(state, name, :cannot_verify, sqlstate_or_term)
    end
  end

  defp add_violation(state, module, class, result) do
    violation = %{module: module, class: class, result: result}
    %{state | violations: [violation | state.violations]}
  end

  # ──────────────────────────────────────────────────────────────
  # D-17: the failure-signature classifier
  # ──────────────────────────────────────────────────────────────

  @doc """
  Classifies a single ExUnit failure entry — the `{kind, reason, stacktrace}`
  shape carried by `%ExUnit.Test{}.state`'s `{:failed, failures}` list — into
  one of a closed atom set: `:already_shared`, `:undefined_table`,
  `:config_schema_drift`, `:sandbox_ownership`, `:citext_probe`, `:other`.

  Every clause matches STRUCTURALLY (struct type, stacktrace frame identity)
  — no clause inspects an exception's own rendered display text or does
  substring/regex matching against it (CLAUDE.md: "Don't pattern-match
  errors by message string. Match the struct.").

  ## The `:already_shared` pair (D-17's highest-risk vacuity)

  Two clauses return `:already_shared`, commented as a pair so neither can be
  deleted without the reader seeing the other:

    1. The VERBATIM nested term captured from CI run `30464215272`, job
       `90617762038` (`143-MECHANISM.md` § "The exact failure term"): an
       outer `MatchError` whose `:term` is `{:error, {{:badmatch,
       :already_shared}, _stack}}`. A clause matching `{:badmatch,
       :already_shared}` at the TOP LEVEL matches nothing — the unlinked
       `Agent.start/1` in `ecto_sql/lib/ecto/adapters/sql/sandbox.ex:452`
       wraps it one level deeper, and the outer `{:ok, pid} =` at `:451` is
       what actually raises.
    2. The composed `SandboxOwnership.LeakError` — `checkout!/1` (plan
       `143-04`) replaces the raw badmatch term with this struct at the
       confirmed leak sites. Counting only clause 1 would make this tally
       read zero the moment `checkout!/1` is adopted, while the leak keeps
       happening under a name nothing is watching — ROADMAP criterion 3
       ("`:already_shared` count is exactly zero") would pass vacuously.
  """
  @spec signature({atom(), term(), term()}) ::
          :already_shared
          | :undefined_table
          | :config_schema_drift
          | :sandbox_ownership
          | :citext_probe
          | :other
  def signature({:error, %MatchError{term: {:error, {{:badmatch, :already_shared}, _stack}}}, _}),
    do: :already_shared

  # Pair with the clause above — see this function's @doc.
  def signature({:error, %SandboxOwnership.LeakError{}, _stacktrace}),
    do: :already_shared

  # Splits `:undefined_table` from `:config_schema_drift` so Class B (D-31)
  # is legible instead of hiding inside a generic "table missing" count —
  # the same argument D-17 makes for `:already_shared` vs. "43 failures."
  # Postgres exposes the missing relation's name only in the free-text
  # `postgres.message` field (no structured `table`/`schema` field exists for
  # `undefined_table`); `schema_qualified_foreign_prefix?/1` reads that raw
  # driver field directly, never the exception's own composed display text
  # (a longer, differently-shaped string).
  def signature({:error, %Postgrex.Error{postgres: %{code: :undefined_table}} = error, _}) do
    if schema_qualified_foreign_prefix?(error), do: :config_schema_drift, else: :undefined_table
  end

  def signature({:error, %DBConnection.OwnershipError{}, _stacktrace}),
    do: :sandbox_ownership

  # The CitextProbe permanent-fault error (`test/support/citext_probe.ex`'s
  # `do_probe/4` exhaustion raise) has no dedicated exception struct — it is
  # a plain `raise "string"`, i.e. `%RuntimeError{}`. To classify it without
  # a message-string match, check for a stacktrace frame naming
  # `Mailglass.TestSupport.CitextProbe` (structural: code identity, not
  # message content) rather than the exception's message text. An arbitrary
  # RuntimeError with no such frame falls through to `:other`, exactly as it
  # should — see `citext_probe_frame?/1`.
  def signature({:error, %RuntimeError{}, stacktrace}) do
    if citext_probe_frame?(stacktrace), do: :citext_probe, else: :other
  end

  def signature(_), do: :other

  defp schema_qualified_foreign_prefix?(%Postgrex.Error{postgres: %{message: message}})
       when is_binary(message) do
    case Regex.run(~r/^relation "([^"]+)"/, message) do
      [_, qualified] ->
        case String.split(qualified, ".", parts: 2) do
          [prefix, _table] -> prefix != Mailglass.Config.schema()
          _ -> false
        end

      nil ->
        false
    end
  end

  defp schema_qualified_foreign_prefix?(_error), do: false

  defp citext_probe_frame?(stacktrace) when is_list(stacktrace) do
    Enum.any?(stacktrace, fn
      {Mailglass.TestSupport.CitextProbe, _fun, _arity, _location} -> true
      _ -> false
    end)
  end

  defp citext_probe_frame?(_stacktrace), do: false

  defp print_ledger(violations) do
    ordered = Enum.reverse(violations)

    IO.puts([
      "\n== Mailglass.TestSupport.SuiteTruthFormatter ledger (",
      Integer.to_string(length(ordered)),
      " record(s)) =="
    ])

    Enum.each(ordered, fn %{module: module, class: class, result: result} ->
      IO.puts("  #{inspect(module)} — #{class} — #{inspect(result)}")
    end)
  end
end
