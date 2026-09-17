defmodule Mailglass.ClockTest do
  use ExUnit.Case, async: true

  alias Mailglass.Clock
  alias Mailglass.Clock.Frozen

  setup do
    # Clean up any frozen clock state after each test
    on_exit(fn -> Frozen.unfreeze() end)
    :ok
  end

  describe "Clock.utc_now/0 three-tier resolution" do
    test "with no frozen time delegates to Clock.System (returns a DateTime within 1s of DateTime.utc_now/0)" do
      before = DateTime.utc_now()
      result = Clock.utc_now()
      after_ = DateTime.utc_now()

      assert %DateTime{} = result
      assert DateTime.compare(before, result) in [:lt, :eq]
      assert DateTime.compare(result, after_) in [:lt, :eq]
    end

    test "inside Clock.Frozen.freeze/1 returns exactly the frozen time" do
      frozen_at = ~U[2026-01-01 00:00:00Z]
      Frozen.freeze(frozen_at)
      assert Clock.utc_now() == frozen_at
    end

    test "advance/1 after freeze returns the frozen time + the given ms" do
      frozen_at = ~U[2026-01-01 00:00:00Z]
      Frozen.freeze(frozen_at)
      advanced = Frozen.advance(5_000)

      expected = DateTime.add(frozen_at, 5_000, :millisecond)
      assert advanced == expected
      assert Clock.utc_now() == expected
    end

    test "advance/1 when no freeze active seeds from DateTime.utc_now/0 then adds ms" do
      # No freeze active; advance seeds from wall clock
      before = DateTime.utc_now()
      advanced = Frozen.advance(5_000)
      after_ = DateTime.utc_now()

      # The advanced value should be ~5s ahead of before
      assert DateTime.compare(advanced, before) == :gt
      # And it should be larger than after_ - 5s (to handle timing slack)
      lower_bound = DateTime.add(after_, 4_000, :millisecond)
      assert DateTime.compare(advanced, lower_bound) in [:gt, :eq]
    end

    test "unfreeze/0 clears the key; subsequent utc_now/0 falls back to impl" do
      Frozen.freeze(~U[2026-01-01 00:00:00Z])
      assert Clock.utc_now() == ~U[2026-01-01 00:00:00Z]

      :ok = Frozen.unfreeze()
      result = Clock.utc_now()

      # After unfreeze, should be close to wall clock
      assert %DateTime{} = result
      refute result == ~U[2026-01-01 00:00:00Z]
    end

    test "per-process isolation: one process freezes, a second spawned task reads unfrozen time" do
      # Freeze in the current process
      Frozen.freeze(~U[2026-01-01 00:00:00Z])

      # Spawn a new process; it should NOT see the frozen time
      task_result =
        Task.async(fn ->
          Clock.utc_now()
        end)
        |> Task.await()

      # The current process still returns frozen time
      assert Clock.utc_now() == ~U[2026-01-01 00:00:00Z]

      # The task process returns wall clock time (not frozen)
      assert %DateTime{} = task_result
      refute task_result == ~U[2026-01-01 00:00:00Z]
    end

    # The runtime-impl-override test lives in Mailglass.ClockRuntimeImplTest
    # below, which is async: false. See the note there.
  end
end

defmodule Mailglass.ClockRuntimeImplTest do
  # MUST stay async: false.
  #
  # Tier 1 of Clock's resolution (the frozen-at process key) is per-process and
  # safe to exercise concurrently. Tier 2 is `config :mailglass, :clock`, which
  # is GLOBAL application state: while it is set, every concurrently running
  # process resolves Clock.utc_now/0 through the fake.
  #
  # This test was previously async: true, and the fake returns 2099. Any async
  # test that windows on Clock.utc_now/0 and happened to overlap it saw `since`
  # in the year 2099 and matched nothing. That is what reddened
  # `Mailglass.Operator.DeliveriesTest` "list_providers/2 returns distinct
  # providers for one tenant and time window" — it asserted
  # ["postmark", "sendgrid"] and got []. It passed locally and on most CI runs
  # because it needs the two to overlap.
  #
  # ExUnit runs async tests concurrently and sync tests serially afterwards, so
  # async: false is what makes the global mutation safe. Do not "optimize" it.
  use ExUnit.Case, async: false

  alias Mailglass.Clock

  defmodule FakeClockImpl do
    def utc_now, do: ~U[2099-12-31 23:59:59Z]
  end

  test "runtime impl override: Application.put_env(:mailglass, :clock, FakeImpl) routes utc_now/0 through FakeImpl" do
    Application.put_env(:mailglass, :clock, FakeClockImpl)
    on_exit(fn -> Application.delete_env(:mailglass, :clock) end)

    assert Clock.utc_now() == ~U[2099-12-31 23:59:59Z]
  end

  test "no async: true test module sets the global :clock impl" do
    files = Path.wildcard("test/**/*_test.exs")

    # Scan per MODULE, not per file: one file may hold both an async: true
    # module and an async: false one, as this file does.
    offenders =
      for path <- files,
          module_source <- String.split(File.read!(path), ~r/^defmodule /m),
          module_source =~ ~r/Application\.put_env\(\s*:mailglass\s*,\s*:clock\b/,
          module_source =~ ~r/use\s+ExUnit\.Case[^\n]*async:\s*true/,
          do: path

    # Anti-vacuity: the scan must actually reach this file, and the splitter must
    # actually separate this file's two modules — otherwise the guard would pass
    # by looking at nothing, or by lumping them together.
    assert "test/mailglass/clock_test.exs" in files

    assert length(String.split(File.read!("test/mailglass/clock_test.exs"), ~r/^defmodule /m)) == 3

    assert offenders == [],
           "config :mailglass, :clock is GLOBAL — an async: true module that sets it " <>
             "shifts Clock.utc_now/0 for every concurrently running test, silently " <>
             "emptying any time-windowed query. Move the test to an async: false " <>
             "module. Offending files: #{inspect(offenders)}"
  end
end
