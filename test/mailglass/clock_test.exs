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

    test "runtime impl override: Application.put_env(:mailglass, :clock, FakeImpl) routes utc_now/0 through FakeImpl" do
      # Define a fake impl module
      defmodule FakeClockImpl do
        def utc_now, do: ~U[2099-12-31 23:59:59Z]
      end

      Application.put_env(:mailglass, :clock, FakeClockImpl)
      on_exit(fn -> Application.delete_env(:mailglass, :clock) end)

      assert Clock.utc_now() == ~U[2099-12-31 23:59:59Z]
    end
  end
end
