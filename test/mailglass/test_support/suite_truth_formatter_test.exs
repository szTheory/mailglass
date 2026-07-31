defmodule Mailglass.TestSupport.SuiteTruthFormatterTest do
  # async: true — this test drives the formatter's `handle_cast/2` clauses
  # directly with synthetic payloads and injectable seams (`probe_fun`,
  # `schema_fun`, `baseline_fun`). It must NOT itself acquire the Sandbox or
  # touch the real database/schema config (that is exactly what the
  # formatter under test observes), so `use ExUnit.Case, async: true` —
  # never `Mailglass.DataCase`. Every test below builds on `quiet_state/1`,
  # which stubs all three seams to their "nothing wrong" outcome so no test
  # accidentally performs real DB manipulation just because it forgot to
  # override an unrelated seam.
  use ExUnit.Case, async: true

  alias Mailglass.TestSupport.SuiteTruthFormatter

  defp async_module(name, async?) do
    %ExUnit.TestModule{name: name, tags: %{async: async?}, state: nil, tests: []}
  end

  # A fully quiet state: pool clean, schema unchanged since boot, baseline
  # present. Every test overrides only the one seam it's exercising, so a
  # forgotten override can never reach the real Sandbox/Postgres/persistent_term.
  defp quiet_state(overrides \\ []) do
    base = [
      probe_fun: fn _repo -> :ok end,
      schema_fun: fn -> "public" end,
      baseline_fun: fn _repo -> true end,
      boot_schema: "public"
    ]

    SuiteTruthFormatter.new_state(Keyword.merge(base, overrides))
  end

  describe "Class C — pool_mode_leaked" do
    test "an async: true module boundary produces no probe call and no violation" do
      state =
        quiet_state(
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
      state = quiet_state(probe_fun: fn _repo -> {:leaked, :already_shared} end)

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
      state = quiet_state()

      {:noreply, new_state} =
        SuiteTruthFormatter.handle_cast(
          {:module_finished, async_module(CleanModule, false)},
          state
        )

      assert new_state.violations == []
    end
  end

  describe "Class B — config_schema_drift" do
    test "an async: false boundary whose schema_fun still matches :boot_schema produces no violation" do
      state = quiet_state(boot_schema: "public", schema_fun: fn -> "public" end)

      {:noreply, new_state} =
        SuiteTruthFormatter.handle_cast(
          {:module_finished, async_module(SchemaStableModule, false)},
          state
        )

      assert new_state.violations == []
    end

    test "an async: false boundary whose schema_fun drifted from :boot_schema produces exactly one :config_schema_drift violation naming boot and observed" do
      state = quiet_state(boot_schema: "public", schema_fun: fn -> "mailglass" end)

      {:noreply, new_state} =
        SuiteTruthFormatter.handle_cast(
          {:module_finished, async_module(SchemaDriftedModule, false)},
          state
        )

      assert [violation] = new_state.violations
      assert violation.module == SchemaDriftedModule
      assert violation.class == :config_schema_drift
      assert violation.result == %{boot: "public", observed: "mailglass"}
    end

    test "Class B is skipped (not manufactured as a drift) when :boot_schema is nil" do
      state = quiet_state(boot_schema: nil, schema_fun: fn -> "public" end)

      {:noreply, new_state} =
        SuiteTruthFormatter.handle_cast(
          {:module_finished, async_module(NoBootSchemaModule, false)},
          state
        )

      assert new_state.violations == []
    end
  end

  describe "Class A — baseline_missing / cannot_verify" do
    test "an async: false boundary whose baseline_fun returns true produces no violation" do
      state = quiet_state(baseline_fun: fn _repo -> true end)

      {:noreply, new_state} =
        SuiteTruthFormatter.handle_cast(
          {:module_finished, async_module(BaselinePresentModule, false)},
          state
        )

      assert new_state.violations == []
    end

    test "an async: false boundary whose baseline_fun reports missing relations produces exactly one :baseline_missing violation naming them" do
      state =
        quiet_state(baseline_fun: fn _repo -> {false, ["mailglass_webhook_events"]} end)

      {:noreply, new_state} =
        SuiteTruthFormatter.handle_cast(
          {:module_finished, async_module(BaselineTornDownModule, false)},
          state
        )

      assert [violation] = new_state.violations
      assert violation.module == BaselineTornDownModule
      assert violation.class == :baseline_missing
      assert violation.result == ["mailglass_webhook_events"]
    end

    # A synthetic `:cannot_verify` baseline result must produce a named
    # violation — not merely "no crash". Asserted by class and by the
    # carried SQLSTATE/term, per the plan's anti-vacuity requirement.
    test "an async: false boundary whose baseline_fun cannot verify produces exactly one :cannot_verify violation carrying the underlying SQLSTATE" do
      state =
        quiet_state(baseline_fun: fn _repo -> {:cannot_verify, "42P01"} end)

      {:noreply, new_state} =
        SuiteTruthFormatter.handle_cast(
          {:module_finished, async_module(BaselineUnverifiableModule, false)},
          state
        )

      assert [violation] = new_state.violations
      assert violation.module == BaselineUnverifiableModule
      assert violation.class == :cannot_verify
      assert violation.result == "42P01"
    end
  end

  describe "all three classes on one boundary" do
    test "a single async: false module can accumulate one violation per leaked class, oldest last" do
      state =
        quiet_state(
          probe_fun: fn _repo -> {:leaked, :already_shared} end,
          boot_schema: "public",
          schema_fun: fn -> "mailglass" end,
          baseline_fun: fn _repo -> {false, ["mailglass_deliveries"]} end
        )

      {:noreply, new_state} =
        SuiteTruthFormatter.handle_cast(
          {:module_finished, async_module(TripleLeakModule, false)},
          state
        )

      classes = Enum.map(new_state.violations, & &1.class)
      # newest first: pool mode probed first, then schema drift, then baseline
      assert classes == [:baseline_missing, :config_schema_drift, :pool_mode_leaked]
    end
  end

  describe "suite lifecycle" do
    test ":suite_finished on an empty accumulator returns {:noreply, state} without raising" do
      state = quiet_state()

      assert {:noreply, ^state} = SuiteTruthFormatter.handle_cast({:suite_finished, %{}}, state)
    end

    test ":suite_started captures schema_fun's return value as :boot_schema" do
      state = quiet_state(boot_schema: nil, schema_fun: fn -> "public" end)

      {:noreply, new_state} = SuiteTruthFormatter.handle_cast({:suite_started, []}, state)

      assert new_state.boot_schema == "public"
    end

    test "an unknown future event never crashes the formatter (catch-all clause)" do
      state = quiet_state()

      assert {:noreply, ^state} =
               SuiteTruthFormatter.handle_cast({:some_future_event, %{}}, state)
    end
  end
end
