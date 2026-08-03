defmodule Mailglass.Compliance.UnsubscribeTest do
  use ExUnit.Case, async: false

  alias Mailglass.Config
  alias Mailglass.Compliance.Unsubscribe
  alias Mailglass.Lifecycle
  alias Mailglass.Tenancy
  alias Mailglass.TestSupport.SandboxOwnership

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
    # `with_app_env!/2` replaces a hand-rolled
    # `on_exit(fn -> Application.put_all_env(mailglass: prior) end)`. That
    # idiom MERGES, so it could never remove `config :mailglass, :compliance`
    # (absent from every `config/*.exs`, set by every test below) — and on any
    # run where a sibling module had already deleted `:tenancy`, it could not
    # remove `TenantWithComplianceHost` either, leaking a resolver whose
    # `scope/2` applies `as: :scoped` into every later caller of
    # `SupportSummary.orphan_backlog_summary/2`. See that function's @doc.
    SandboxOwnership.with_app_env!(:mailglass)
    on_exit(&Mailglass.Tenancy.clear/0)

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

    test "lifecycle callback and compliance key retain their compatible public shape" do
      lifecycle_docs = File.read!("lib/mailglass/lifecycle.ex") |> String.replace("\n", " ")
      config_source = File.read!("lib/mailglass/config.ex")

      assert lifecycle_docs =~ "handle_event(Ecto.Multi.t(), map()) ::"
      assert lifecycle_docs =~ "after the primary event and suppression convergence commits"
      assert Regex.match?(~r/separate,\s+best-effort transaction/, lifecycle_docs)
      assert config_source =~ "lifecycle: ["
      assert config_source =~ "after the primary convergence commits"
      assert config_source =~ "as a separate, best-effort transaction"
      refute config_source =~ "transaction-local unsubscribe side effects"
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

  describe "token service" do
    @describetag :token_service

    setup do
      Application.delete_env(:mailglass, :tenancy)

      Application.put_env(:mailglass, :tracking, endpoint: "tracking-endpoint-secret-123")

      Application.put_env(:mailglass, :compliance,
        endpoint: "current-secret-key-base-123",
        host: "unsubscribe.example.com",
        scheme: "https",
        mount_path: "/mailglass/unsubscribe",
        previous_secrets: [],
        redirect: nil,
        max_age: 60
      )

      :ok
    end

    test "signs only the delivery id and verifies against the current endpoint" do
      token = Unsubscribe.sign_token("delivery-123")

      assert is_binary(token)
      refute String.contains?(token, "delivery-123")

      assert {:ok, %{delivery_id: "delivery-123"}} = Unsubscribe.verify_token(token)
    end

    test "falls back to configured previous raw secrets when current verification fails" do
      Application.put_env(:mailglass, :compliance,
        endpoint: "rotated-secret-key-base-123",
        host: "unsubscribe.example.com",
        scheme: "https",
        mount_path: "/mailglass/unsubscribe",
        previous_secrets: ["legacy-secret-key-base-123"],
        redirect: nil,
        max_age: 60
      )

      token =
        Phoenix.Token.sign(
          "legacy-secret-key-base-123",
          "mailglass_unsubscribe_v1",
          "delivery-legacy"
        )

      assert {:ok, %{delivery_id: "delivery-legacy"}} = Unsubscribe.verify_token(token)
    end

    test "returns structured outcomes for invalid and expired tokens" do
      assert {:error, :invalid} = Unsubscribe.verify_token("garbage-token")

      Application.put_env(:mailglass, :compliance,
        endpoint: "current-secret-key-base-123",
        host: "unsubscribe.example.com",
        scheme: "https",
        mount_path: "/mailglass/unsubscribe",
        previous_secrets: [],
        redirect: nil,
        max_age: 1
      )

      token = Unsubscribe.sign_token("delivery-expired")
      Process.sleep(1_100)

      assert {:error, :expired} = Unsubscribe.verify_token(token)
    end

    test "builds unsubscribe URLs from the compliance config" do
      assert url = Unsubscribe.unsubscribe_url("delivery-123", %{tenant_id: "tenant-1"})
      assert String.starts_with?(url, "https://unsubscribe.example.com/mailglass/unsubscribe/")

      assert {:ok, %{delivery_id: "delivery-123"}} =
               url |> String.split("/") |> List.last() |> Unsubscribe.verify_token()
    end

    test "tokens signed before endpoint rotation still verify via previous_secrets" do
      token = Unsubscribe.sign_token("delivery-rotated")

      Application.put_env(:mailglass, :compliance,
        endpoint: "rotated-secret-key-base-123",
        host: "unsubscribe.example.com",
        scheme: "https",
        mount_path: "/mailglass/unsubscribe",
        previous_secrets: ["current-secret-key-base-123"],
        redirect: nil,
        max_age: 60
      )

      assert {:ok, %{delivery_id: "delivery-rotated"}} = Unsubscribe.verify_token(token)
    end

    test "tampered tokens return a structured invalid outcome" do
      token = Unsubscribe.sign_token("delivery-123")

      assert {:error, :invalid} = Unsubscribe.verify_token(tamper_signature!(token))
    end

    test "tenant compliance_host override wins and :default falls back to global host" do
      Application.put_env(:mailglass, :tenancy, TenantWithComplianceHost)

      tenant_url = Unsubscribe.unsubscribe_url("delivery-tenant", %{tenant_id: "tenant-1"})
      assert String.starts_with?(tenant_url, "https://tenant.example.com/mailglass/unsubscribe/")

      Application.delete_env(:mailglass, :tenancy)

      default_url = Unsubscribe.unsubscribe_url("delivery-default", %{tenant_id: "tenant-1"})

      assert String.starts_with?(
               default_url,
               "https://unsubscribe.example.com/mailglass/unsubscribe/"
             )
    end

    test "rejects unsubscribe URLs longer than 900 bytes" do
      Application.put_env(:mailglass, :compliance,
        endpoint: "current-secret-key-base-123",
        host: String.duplicate("a", 860) <> ".example.com",
        scheme: "https",
        mount_path: "/mailglass/unsubscribe",
        previous_secrets: [],
        redirect: nil,
        max_age: 60
      )

      err =
        assert_raise Mailglass.ConfigError, fn ->
          Unsubscribe.unsubscribe_url("delivery-123", %{})
        end

      assert err.type == :invalid
      assert err.context[:reason] == :unsubscribe_url_too_long
      assert err.context[:max_bytes] == 900
    end
  end

  defp tamper_signature!(token) when is_binary(token) do
    token
    |> String.split(".")
    |> List.update_at(-1, &mutate_segment!/1)
    |> Enum.join(".")
  end

  defp mutate_segment!(segment) when is_binary(segment) and segment != "" do
    replacement = if String.first(segment) == "A", do: "B", else: "A"
    String.replace_prefix(segment, String.first(segment), replacement)
  end
end
