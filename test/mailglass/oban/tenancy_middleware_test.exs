defmodule Mailglass.Oban.TenancyMiddlewareTest do
  use ExUnit.Case, async: true

  # The middleware is conditionally compiled against `Oban.Worker`. When
  # Oban is absent (which it is in CI's `--no-optional-deps` lane), the
  # module does not exist. `@moduletag` documents the dep; the runtime
  # check below keeps this file compilable either way.
  @moduletag :oban

  setup do
    unless Code.ensure_loaded?(Mailglass.Oban.TenancyMiddleware) do
      # If Oban.Worker isn't loaded in this runtime, the module wasn't
      # compiled — short-circuit. With `:oban` as an optional dep in
      # mix.exs, it IS loaded in the :test env unless `--no-optional-deps`
      # is passed.
      :ignore
    end

    on_exit(fn -> Process.delete(:mailglass_tenant_id) end)
    Process.delete(:mailglass_tenant_id)
    :ok
  end

  describe "call/2 (Oban Pro middleware shape)" do
    test "wraps next.(job) in with_tenant when args carry mailglass_tenant_id" do
      job = %{args: %{"mailglass_tenant_id" => "job-tenant"}}

      result =
        Mailglass.Oban.TenancyMiddleware.call(job, fn ^job ->
          # Inside next/1, Tenancy.current/0 should return the job's tenant
          Mailglass.Tenancy.current()
        end)

      assert result == "job-tenant"
      # After: process dict is restored (nil — no prior stamp)
      refute Process.get(:mailglass_tenant_id)
    end

    test "passes through unchanged when mailglass_tenant_id is missing" do
      job = %{args: %{"other_key" => "x"}}

      result =
        Mailglass.Oban.TenancyMiddleware.call(job, fn ^job ->
          # Unstamped — falls back to SingleTenant default
          Mailglass.Tenancy.current()
        end)

      assert result == "default"
    end

    test "passes through when mailglass_tenant_id is not a string" do
      job = %{args: %{"mailglass_tenant_id" => 42}}

      result =
        Mailglass.Oban.TenancyMiddleware.call(job, fn ^job ->
          Mailglass.Tenancy.current()
        end)

      # Guard failed (not is_binary) — default resolver kicks in
      assert result == "default"
    end

    test "restores prior tenant even if next/1 raises" do
      Mailglass.Tenancy.put_current("outer")
      job = %{args: %{"mailglass_tenant_id" => "job-tenant"}}

      assert_raise RuntimeError, fn ->
        Mailglass.Oban.TenancyMiddleware.call(job, fn _ -> raise "boom" end)
      end

      # Tenant restored to outer (matches with_tenant/2 contract)
      assert Mailglass.Tenancy.current() == "outer"
    end
  end

  describe "wrap_perform/2 (OSS Oban adopter surface)" do
    test "wraps fun in with_tenant when args carry mailglass_tenant_id" do
      job = %{args: %{"mailglass_tenant_id" => "job-tenant"}}

      result =
        Mailglass.Oban.TenancyMiddleware.wrap_perform(job, fn ->
          Mailglass.Tenancy.current()
        end)

      assert result == "job-tenant"
      refute Process.get(:mailglass_tenant_id)
    end

    test "invokes fun unchanged when mailglass_tenant_id is missing" do
      job = %{args: %{"other_key" => "x"}}

      result =
        Mailglass.Oban.TenancyMiddleware.wrap_perform(job, fn ->
          Mailglass.Tenancy.current()
        end)

      assert result == "default"
    end

    test "invokes fun unchanged when mailglass_tenant_id is not a string" do
      job = %{args: %{"mailglass_tenant_id" => 42}}

      result =
        Mailglass.Oban.TenancyMiddleware.wrap_perform(job, fn ->
          Mailglass.Tenancy.current()
        end)

      assert result == "default"
    end

    test "restores prior tenant even if fun raises" do
      Mailglass.Tenancy.put_current("outer")
      job = %{args: %{"mailglass_tenant_id" => "job-tenant"}}

      assert_raise RuntimeError, fn ->
        Mailglass.Oban.TenancyMiddleware.wrap_perform(job, fn -> raise "boom" end)
      end

      assert Mailglass.Tenancy.current() == "outer"
    end
  end
end
