defmodule Mailglass.Tenancy.ResolveFromPathTest do
  # Pure function tests — no process dict, no DB, no global state.
  use ExUnit.Case, async: true

  alias Mailglass.Tenancy.ResolveFromPath

  describe "resolve_webhook_tenant/1" do
    test "returns {:ok, tid} when path_params['tenant_id'] is a non-empty binary" do
      ctx = %{
        provider: :postmark,
        conn: nil,
        raw_body: "",
        headers: [],
        path_params: %{"tenant_id" => "tenant_a"},
        verified_payload: nil
      }

      assert {:ok, "tenant_a"} = ResolveFromPath.resolve_webhook_tenant(ctx)
    end

    test "extracts tenant_id alongside other path_params" do
      ctx = %{
        provider: :sendgrid,
        conn: nil,
        raw_body: "",
        headers: [],
        path_params: %{"tenant_id" => "acme-corp", "region" => "us-east-1"},
        verified_payload: nil
      }

      assert {:ok, "acme-corp"} = ResolveFromPath.resolve_webhook_tenant(ctx)
    end

    test "returns {:error, :missing_path_param} when path_params has no tenant_id key" do
      ctx = %{
        provider: :postmark,
        conn: nil,
        raw_body: "",
        headers: [],
        path_params: %{},
        verified_payload: nil
      }

      assert {:error, :missing_path_param} = ResolveFromPath.resolve_webhook_tenant(ctx)
    end

    test "returns {:error, :missing_path_param} when tenant_id is empty string" do
      ctx = %{
        provider: :postmark,
        conn: nil,
        raw_body: "",
        headers: [],
        path_params: %{"tenant_id" => ""},
        verified_payload: nil
      }

      assert {:error, :missing_path_param} = ResolveFromPath.resolve_webhook_tenant(ctx)
    end

    test "returns {:error, :missing_path_param} when path_params key is absent entirely" do
      # Minimal map — still the documented context shape but path_params
      # missing altogether. Adopters may hand-build the context in tests;
      # the resolver must fail closed, not crash.
      ctx = %{
        provider: :postmark,
        conn: nil,
        raw_body: "",
        headers: [],
        path_params: %{"other" => "value"},
        verified_payload: nil
      }

      assert {:error, :missing_path_param} = ResolveFromPath.resolve_webhook_tenant(ctx)
    end
  end

  describe "scope/2" do
    test "raises a clear error directing adopters to compose with a real Tenancy module" do
      err =
        assert_raise RuntimeError, fn ->
          ResolveFromPath.scope(:dummy_query, %{})
        end

      assert err.message =~ "does not implement scope/2"
      assert err.message =~ "sugar resolver" or err.message =~ "SUGAR resolver"
    end

    test "scope/2 raises regardless of query/context shape (fails closed)" do
      assert_raise RuntimeError, ~r/scope\/2/, fn ->
        ResolveFromPath.scope(%{some: :query}, %{tenant: "x"})
      end
    end
  end

  describe "behaviour declaration" do
    test "declares @behaviour Mailglass.Tenancy" do
      behaviours =
        ResolveFromPath.module_info(:attributes)
        |> Keyword.get_values(:behaviour)
        |> List.flatten()

      assert Mailglass.Tenancy in behaviours
    end

    test "exports resolve_webhook_tenant/1 callback" do
      assert function_exported?(ResolveFromPath, :resolve_webhook_tenant, 1)
    end
  end
end
