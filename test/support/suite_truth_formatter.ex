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
  `Mailglass.TestSupport.SandboxOwnership.probe/1` rather than
  re-implementing it (D-09), so the negative-control tests in
  `suite_truth_formatter_test.exs` exercise the real code path.

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
      probe_fun: &SandboxOwnership.probe/1
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
    {:noreply, %{state | boot_schema: Mailglass.Config.schema()}}
  end

  def handle_cast({:module_finished, %ExUnit.TestModule{} = test_module}, state) do
    if async_false?(test_module) do
      {:noreply, probe_module_boundary(test_module, state)}
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

  # D-10: this healing call is safe ONLY because `ExUnit.Runner.async_loop/4`
  # waits for `map_size(running) == 0` before spawning any `async: false`
  # module — sync modules run strictly after, and strictly serially to,
  # async modules. `SandboxOwnership.probe/1` calls
  # `Sandbox.mode(repo, :manual)`, which checks in EVERY live connection; were
  # this called while an async module's connection was still checked out, it
  # would rip that connection out from under a running test. The reliance is
  # exercised on both the 1.18/OTP 27 and 1.19/OTP 28 legs (see the advisory
  # matrix), so a future Elixir scheduling change surfaces as a matrix
  # divergence rather than silent corruption.
  defp probe_module_boundary(%ExUnit.TestModule{name: name}, state) do
    case state.probe_fun.(Mailglass.TestRepo) do
      :ok ->
        state

      {:leaked, result} ->
        violation = %{module: name, class: :pool_mode_leaked, result: result}
        %{state | violations: [violation | state.violations]}
    end
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
