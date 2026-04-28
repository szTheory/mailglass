defmodule Mailglass.Compliance.UnsubscribeTest do
  use ExUnit.Case, async: false

  alias Mailglass.Config
  alias Mailglass.Lifecycle
  alias Mailglass.Tenancy

  defmodule TestLifecycle do
    @behaviour Mailglass.Lifecycle

    @impl true
    def handle_event(multi, _attrs), do: multi
  end

  defmodule TenantWithComplianceHost do
    @behaviour Mailglass.Tenancy

    import Ecto.Query

    @impl true
    def scope(queryable, _context), do: from(row in queryable, as: :scoped)

    @impl true
    def compliance_host(_context), do: {:ok, "tenant.example.com"}
  end

  setup do
    prior_mailglass = Application.get_all_env(:mailglass)

    on_exit(fn ->
      Application.put_all_env(mailglass: prior_mailglass)
      Mailglass.Tenancy.clear()
    end)

    :ok
  end

  describe "compliance config contract" do
    @describetag :config_contract

    test "returns validated compliance defaults and accessors" do
      Application.put_env(:mailglass, :compliance, [])
      Application.put_env(:mailglass, :tracking, endpoint: "tracking-endpoint")

      assert compliance = Config.compliance()
      assert compliance[:host] == nil
      assert compliance[:scheme] == "https"
      assert compliance[:mount_path] == "/mailglass/unsubscribe"
      assert compliance[:previous_secrets] == []
      assert compliance[:redirect] == nil
      assert compliance[:max_age] == 2 * 365 * 86_400
      assert compliance[:lifecycle] == Mailglass.Lifecycle.Noop

      assert Config.compliance_endpoint() == "tracking-endpoint"
      assert Config.compliance_host() == nil
      assert Config.compliance_scheme() == "https"
      assert Config.compliance_mount_path() == "/mailglass/unsubscribe"
      assert Config.compliance_previous_secrets() == []
      assert Config.compliance_redirect() == nil
      assert Config.compliance_max_age() == 2 * 365 * 86_400
      assert Config.compliance_lifecycle() == Mailglass.Lifecycle.Noop
    end

    test "allows explicit compliance endpoint and lifecycle override" do
      Application.put_env(:mailglass, :tracking, endpoint: "tracking-endpoint")

      Application.put_env(:mailglass, :compliance,
        endpoint: "compliance-endpoint",
        host: "unsubscribe.example.com",
        scheme: "http",
        mount_path: "/custom/unsub",
        previous_secrets: ["old-secret"],
        redirect: "/settings/unsubscribe",
        max_age: 86_400,
        lifecycle: TestLifecycle
      )

      assert Config.compliance_endpoint() == "compliance-endpoint"
      assert Config.compliance_host() == "unsubscribe.example.com"
      assert Config.compliance_scheme() == "http"
      assert Config.compliance_mount_path() == "/custom/unsub"
      assert Config.compliance_previous_secrets() == ["old-secret"]
      assert Config.compliance_redirect() == "/settings/unsubscribe"
      assert Config.compliance_max_age() == 86_400
      assert Config.compliance_lifecycle() == TestLifecycle
    end
  end

  describe "lifecycle and tenancy contracts" do
    @describetag :config_contract

    test "Mailglass.Lifecycle exposes a no-op default implementation" do
      multi = Ecto.Multi.new()

      assert function_exported?(Lifecycle, :handle_event, 2)
      assert Lifecycle.handle_event(multi, %{event: :unsubscribed}) == multi
      assert function_exported?(Mailglass.Lifecycle.Noop, :handle_event, 2)
      assert Mailglass.Lifecycle.Noop.handle_event(multi, %{event: :unsubscribed}) == multi
    end

    test "Mailglass.Tenancy exposes optional compliance_host/1 override" do
      Application.put_env(:mailglass, :tenancy, TenantWithComplianceHost)

      assert Tenancy.compliance_host(%{tenant_id: "tenant-1"}) == {:ok, "tenant.example.com"}
    end

    test "Mailglass.Tenancy falls back to :default when no override is exported" do
      Application.delete_env(:mailglass, :tenancy)

      assert Tenancy.compliance_host(%{tenant_id: "tenant-1"}) == :default
    end
  end
end
