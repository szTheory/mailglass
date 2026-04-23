defmodule Mailglass.RateLimiterSupervisionTest do
  use ExUnit.Case, async: false

  alias Mailglass.RateLimiter
  alias Mailglass.RateLimiter.{Supervisor, TableOwner}

  describe "RateLimiter.Supervisor structure (Test 10)" do
    test "strategy is :one_for_one with TableOwner as only child" do
      # Supervisor is running (started by Mailglass.Application)
      sup_pid = Process.whereis(Supervisor)
      assert is_pid(sup_pid), "RateLimiter.Supervisor must be running"

      children = Elixir.Supervisor.which_children(sup_pid)
      assert length(children) == 1

      [{child_id, _child_pid, :worker, _modules}] = children
      assert child_id == TableOwner
    end
  end

  describe "TableOwner crash + restart (Test 9)" do
    test "after killing TableOwner, supervisor restarts it and RateLimiter.check succeeds" do
      # Pre-condition: TableOwner is running
      owner_pid = Process.whereis(TableOwner)
      assert is_pid(owner_pid), "TableOwner must be running before kill"

      # Seed a rate-limit entry to confirm state exists
      Application.put_env(:mailglass, :rate_limit, default: [capacity: 100, per_minute: 100])
      :ets.delete_all_objects(:mailglass_rate_limit)
      assert :ok = RateLimiter.check("tenant-crash", "crash.com", :operational)
      assert length(:ets.lookup(:mailglass_rate_limit, {"tenant-crash", "crash.com"})) == 1

      # Kill the TableOwner
      Process.exit(owner_pid, :kill)

      # Poll until a new TableOwner is registered (max 500ms)
      new_owner_pid =
        Enum.find_value(1..50, fn _i ->
          Process.sleep(10)
          pid = Process.whereis(TableOwner)
          if pid && pid != owner_pid, do: pid
        end)

      assert is_pid(new_owner_pid), "TableOwner should restart within 500ms"
      assert new_owner_pid != owner_pid, "Restarted TableOwner should be a new process"

      # ETS counters reset — prior entry should be gone
      assert :ets.lookup(:mailglass_rate_limit, {"tenant-crash", "crash.com"}) == []

      # Subsequent check should work fine (fresh bucket)
      assert :ok = RateLimiter.check("tenant-crash", "crash.com", :operational)
    end
  end
end
