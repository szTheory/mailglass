defmodule Mailglass.TenancyTest do
  # async-safe: the process dict is per-process; each test gets its own slate.
  use ExUnit.Case, async: true

  alias Mailglass.Tenancy
  alias Mailglass.TenancyError

  setup do
    # Each test starts with a clean process-dict slate so `current/0`
    # exercises the resolver-default code path until the test stamps.
    on_exit(fn -> Process.delete(:mailglass_tenant_id) end)
    Process.delete(:mailglass_tenant_id)
    :ok
  end

  describe "put_current/1 + current/0" do
    test "put_current stamps process dict; current reads it" do
      assert Tenancy.put_current("tenant-a") == :ok
      assert Tenancy.current() == "tenant-a"
    end

    test "put_current(nil) deletes the stamp" do
      Tenancy.put_current("tenant-a")
      assert :ok = Tenancy.put_current(nil)
      # current/0 falls back to SingleTenant default "default"
      assert Tenancy.current() == "default"
    end

    test "put_current rejects non-binary tenant_ids" do
      assert_raise FunctionClauseError, fn -> Tenancy.put_current(42) end
      assert_raise FunctionClauseError, fn -> Tenancy.put_current(:atom) end
    end
  end

  describe "current/0 fallback to SingleTenant default" do
    test "returns 'default' when unstamped and SingleTenant is configured" do
      # config/test.exs sets tenancy: Mailglass.Tenancy.SingleTenant
      assert Tenancy.current() == "default"
    end
  end

  describe "with_tenant/2" do
    test "scopes tenant for the block and restores prior value" do
      Tenancy.put_current("outer")

      result =
        Tenancy.with_tenant("inner", fn ->
          assert Tenancy.current() == "inner"
          :ok_from_block
        end)

      assert result == :ok_from_block
      assert Tenancy.current() == "outer"
    end

    test "restores nil when no prior value was set" do
      refute Process.get(:mailglass_tenant_id)

      Tenancy.with_tenant("temp", fn ->
        assert Tenancy.current() == "temp"
        :ok
      end)

      # After: process dict is clean; current falls back to SingleTenant default.
      refute Process.get(:mailglass_tenant_id)
      assert Tenancy.current() == "default"
    end

    test "restores prior value on exception" do
      Tenancy.put_current("outer")

      assert_raise RuntimeError, fn ->
        Tenancy.with_tenant("inner", fn -> raise "boom" end)
      end

      assert Tenancy.current() == "outer"
    end
  end

  describe "tenant_id!/0" do
    test "returns the stamped tenant when set" do
      Tenancy.put_current("tenant-a")
      assert Tenancy.tenant_id!() == "tenant-a"
    end

    test "raises TenancyError when unstamped — does NOT fall back to SingleTenant default" do
      # Clean slate — tenant_id!/0 does NOT use default_tenant/0
      Process.delete(:mailglass_tenant_id)

      err = assert_raise TenancyError, fn -> Tenancy.tenant_id!() end
      assert err.type == :unstamped
      assert err.message =~ "Tenant context is not stamped"
    end
  end

  describe "scope/2" do
    test "SingleTenant scope returns query unchanged" do
      import Ecto.Query
      query = from(d in "mailglass_deliveries", select: d.id)
      assert Tenancy.scope(query, "any-tenant") == query
    end

    test "scope/1 uses current/0 as the default context" do
      import Ecto.Query
      query = from(d in "mailglass_deliveries", select: d.id)
      # SingleTenant is a no-op regardless of context, but this exercises
      # the default-argument path.
      assert Tenancy.scope(query) == query
    end
  end

  describe "assert_stamped!/0" do
    test "returns :ok when a tenant is stamped" do
      Tenancy.put_current("tenant-a")
      assert Tenancy.assert_stamped!() == :ok
    end

    test "raises TenancyError{type: :unstamped} when no tenant is stamped" do
      Process.delete(:mailglass_tenant_id)
      err = assert_raise TenancyError, fn -> Tenancy.assert_stamped!() end
      assert err.type == :unstamped
    end

    test "raises even when resolver is SingleTenant (unlike current/0 which returns 'default')" do
      # Ensure we're using SingleTenant resolver (test.exs default)
      # and the process dict is clean
      Process.delete(:mailglass_tenant_id)

      # current/0 returns "default" via SingleTenant — assert_stamped!/0 must raise anyway
      assert Tenancy.current() == "default"
      assert_raise TenancyError, fn -> Tenancy.assert_stamped!() end
    end
  end

  describe "behaviour contract" do
    # Flaky ~1 in 3 runs: `function_exported?/3` returns false when the target
    # module is not yet loaded in the calling process's code cache. See
    # `.planning/phases/02-persistence-tenancy/deferred-items.md §"Pre-existing
    # flaky test"` — architectural fix deferred to Phase 6 alongside
    # LINT-03/LINT-09. Excluded from CI via `--exclude flaky` in
    # `mix verify.phase_02` / `verify.cold_start`.
    @tag :flaky
    test "SingleTenant implements @behaviour Mailglass.Tenancy" do
      # Compile-time: if SingleTenant didn't implement scope/2, the
      # @impl annotation would have raised. Runtime sanity check:
      assert function_exported?(Mailglass.Tenancy.SingleTenant, :scope, 2)
    end
  end
end
