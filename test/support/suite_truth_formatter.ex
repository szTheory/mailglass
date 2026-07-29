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
      baseline_fun: &SandboxOwnership.baseline_tables_present?/1
    }
    |> Map.merge(Map.new(overrides))
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

  def handle_cast({:test_finished, %ExUnit.Test{}}, state) do
    # Signature tally lands in plan 143-09; nothing to do here yet.
    {:noreply, state}
  end

  def handle_cast({:suite_finished, _times_us}, state) do
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
