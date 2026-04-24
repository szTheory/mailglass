defmodule Mailglass.Properties.WebhookTenantResolutionTest do
  @moduledoc """
  TEST-03 D-27 #3: tenant resolution via `Mailglass.Tenancy.SingleTenant`
  + `Mailglass.Tenancy.ResolveFromPath` stamps correctly across the
  random-context space; a dispatcher backed by a bad resolver surfaces
  `{:error, _}` cleanly (rescuable as `%TenancyError{type:
  :webhook_tenant_unresolved}` in `Mailglass.Webhook.Plug`).

  ## Three describe blocks cover the three resolver shapes

    1. `SingleTenant` always returns `{:ok, "default"}` regardless of
       context — the zero-config posture.
    2. `ResolveFromPath` returns `{:ok, tid}` for any non-empty
       `path_params["tenant_id"]` binary, `{:error, :missing_path_param}`
       otherwise.
    3. A synthetic `BadTenancy` module returning `{:error, :broken}` flows
       through `Mailglass.Tenancy.resolve_webhook_tenant/1` cleanly; the
       Plug-level conversion to `%TenancyError{type:
       :webhook_tenant_unresolved}` is a separate boundary contract
       verified by `Mailglass.Webhook.PlugTest` (Plan 04-04).
  """

  use ExUnit.Case, async: false
  use ExUnitProperties

  alias Mailglass.{Tenancy, TenancyError}
  alias Mailglass.Tenancy.{ResolveFromPath, SingleTenant}

  @moduletag :property
  @moduletag timeout: :infinity

  describe "SingleTenant.resolve_webhook_tenant/1 always returns {:ok, \"default\"}" do
    property "for any context map" do
      check all(
              provider <- member_of([:postmark, :sendgrid]),
              raw_body <- string(:alphanumeric, max_length: 100),
              max_runs: 100
            ) do
        ctx = %{
          provider: provider,
          conn: nil,
          raw_body: raw_body,
          headers: [],
          path_params: %{},
          verified_payload: nil
        }

        assert {:ok, "default"} = SingleTenant.resolve_webhook_tenant(ctx)
      end
    end
  end

  describe "ResolveFromPath.resolve_webhook_tenant/1 stamps path_params[\"tenant_id\"]" do
    property "returns {:ok, tid} when tenant_id is non-empty binary" do
      check all(
              tid <- string(:alphanumeric, min_length: 1, max_length: 50),
              provider <- member_of([:postmark, :sendgrid]),
              max_runs: 100
            ) do
        ctx = %{
          provider: provider,
          conn: nil,
          raw_body: "",
          headers: [],
          path_params: %{"tenant_id" => tid},
          verified_payload: nil
        }

        assert {:ok, ^tid} = ResolveFromPath.resolve_webhook_tenant(ctx)
      end
    end

    property "returns {:error, :missing_path_param} for absent or empty tenant_id" do
      check all(
              shape <-
                member_of([
                  %{},
                  %{"tenant_id" => ""},
                  %{"other" => "value"},
                  %{"tenant" => "not-the-right-key"}
                ]),
              max_runs: 50
            ) do
        ctx = %{
          provider: :postmark,
          conn: nil,
          raw_body: "",
          headers: [],
          path_params: shape,
          verified_payload: nil
        }

        assert {:error, :missing_path_param} =
                 ResolveFromPath.resolve_webhook_tenant(ctx)
      end
    end
  end

  describe "Tenancy dispatcher + bad resolver surfaces {:error, _} cleanly" do
    defmodule BadTenancy do
      @moduledoc false
      @behaviour Mailglass.Tenancy

      @impl Mailglass.Tenancy
      def scope(q, _), do: q

      @impl Mailglass.Tenancy
      def resolve_webhook_tenant(_ctx), do: {:error, :always_broken}
    end

    property "Tenancy.resolve_webhook_tenant returns {:error, _} without raising" do
      check all(
              provider <- member_of([:postmark, :sendgrid]),
              max_runs: 50
            ) do
        Application.put_env(:mailglass, :tenancy, BadTenancy)

        try do
          ctx = %{
            provider: provider,
            conn: nil,
            raw_body: "",
            headers: [],
            path_params: %{},
            verified_payload: nil
          }

          assert {:error, :always_broken} = Tenancy.resolve_webhook_tenant(ctx)
        after
          Application.delete_env(:mailglass, :tenancy)
        end
      end
    end

    test "TenancyError.new(:webhook_tenant_unresolved, ...) carries the expected contract" do
      # Boundary test (not a property): the Plug rescue clause converts
      # `{:error, _}` from the dispatcher into the closed-atom error.
      # `plug_test.exs` covers that path end-to-end; this test pins the
      # TenancyError shape so the Plug's rescue assumptions hold.
      err =
        TenancyError.new(:webhook_tenant_unresolved,
          context: %{provider: :postmark, reason: :always_broken}
        )

      assert err.type == :webhook_tenant_unresolved
      assert Exception.message(err) =~ "Webhook tenant resolution failed"
    end
  end
end
