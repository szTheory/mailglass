defmodule Mailglass.TestSupport.SuiteTruthFormatterTest do
  # async: true — this test drives the formatter's `handle_cast/2` clauses
  # directly with synthetic payloads and an injectable `probe_fun`. It must
  # NOT itself acquire the Sandbox (that is exactly what the formatter under
  # test observes), so `use ExUnit.Case, async: true` — never `Mailglass.DataCase`.
  use ExUnit.Case, async: true

  alias Mailglass.TestSupport.SuiteTruthFormatter

  defp async_module(name, async?) do
    %ExUnit.TestModule{name: name, tags: %{async: async?}, state: nil, tests: []}
  end

  test "an async: true module boundary produces no probe call and no violation" do
    state =
      SuiteTruthFormatter.new_state(
        probe_fun: fn _repo -> flunk("probe must not be called for async: true modules") end
      )

    {:noreply, new_state} =
      SuiteTruthFormatter.handle_cast(
        {:module_finished, async_module(SomeAsyncTrueModule, true)},
        state
      )

    assert new_state.violations == []
  end

  test "an async: false boundary whose probe returns {:leaked, :already_shared} produces exactly one violation naming that module" do
    state =
      SuiteTruthFormatter.new_state(probe_fun: fn _repo -> {:leaked, :already_shared} end)

    {:noreply, new_state} =
      SuiteTruthFormatter.handle_cast(
        {:module_finished, async_module(LeakyModule, false)},
        state
      )

    assert [violation] = new_state.violations
    assert violation.module == LeakyModule
    assert violation.class == :pool_mode_leaked
    assert violation.result == :already_shared
  end

  test "an async: false boundary whose probe returns :ok produces no violation" do
    state = SuiteTruthFormatter.new_state(probe_fun: fn _repo -> :ok end)

    {:noreply, new_state} =
      SuiteTruthFormatter.handle_cast(
        {:module_finished, async_module(CleanModule, false)},
        state
      )

    assert new_state.violations == []
  end

  test ":suite_finished on an empty accumulator returns {:noreply, state} without raising" do
    state = SuiteTruthFormatter.new_state()

    assert {:noreply, ^state} = SuiteTruthFormatter.handle_cast({:suite_finished, %{}}, state)
  end

  test ":suite_started captures Mailglass.Config.schema() as :boot_schema" do
    state = SuiteTruthFormatter.new_state()

    {:noreply, new_state} = SuiteTruthFormatter.handle_cast({:suite_started, []}, state)

    assert new_state.boot_schema == Mailglass.Config.schema()
  end

  test "an unknown future event never crashes the formatter (catch-all clause)" do
    state = SuiteTruthFormatter.new_state()

    assert {:noreply, ^state} =
             SuiteTruthFormatter.handle_cast({:some_future_event, %{}}, state)
  end
end
