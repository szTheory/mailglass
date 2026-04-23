defmodule Mailglass.Webhook.PlugTest do
  @moduledoc """
  Integration tests for `Mailglass.Webhook.Plug` (Plan 04-04).

  Covers the response-code matrix + Logger discipline + telemetry
  metadata whitelist (D-23). Happy-path tests that require
  `Mailglass.Webhook.Ingest.ingest_multi/3` (Plan 06 / Wave 3) are
  tagged `@tag :requires_plan_06` and excluded until that plan lands.

  Verified paths here (Wave 2A):

    * `init/1` — valid + invalid provider validation
    * `call/2` — 401 on Postmark Basic Auth failure + Logger discipline
    * `call/2` — 401 on SendGrid bit-flipped body
    * `call/2` — 422 on tenant-unresolved (via adopter tenancy stub)
    * `call/2` — 500 on missing CachingBodyReader (`raw_body` nil)
    * `call/2` — 500 on missing Postmark `basic_auth` config
    * `call/2` — telemetry `:start` + `:stop` fire on signature-failure
      path with metadata whitelist compliance (no PII)
  """

  # async: false because WebhookCase setup mutates :mailglass Application env.
  use Mailglass.WebhookCase, async: false

  import ExUnit.CaptureLog

  alias Mailglass.Webhook.Plug, as: WebhookPlug

  describe "init/1" do
    test "valid :postmark provider opt survives init" do
      assert Keyword.get(WebhookPlug.init(provider: :postmark), :provider) == :postmark
    end

    test "valid :sendgrid provider opt survives init" do
      assert Keyword.get(WebhookPlug.init(provider: :sendgrid), :provider) == :sendgrid
    end

    test "raises ArgumentError on unknown provider" do
      assert_raise ArgumentError, ~r/unknown :provider/, fn ->
        WebhookPlug.init(provider: :mailgun)
      end
    end

    test "raises KeyError when :provider opt missing" do
      assert_raise KeyError, fn -> WebhookPlug.init([]) end
    end
  end

  describe "call/2 response code matrix — 401 signature failure" do
    test "401 on Postmark Basic Auth mismatch + Logger.warning discipline" do
      body = Mailglass.WebhookFixtures.load_postmark_fixture("delivered")

      # Build conn manually with WRONG credentials.
      {h, v} = Mailglass.WebhookFixtures.postmark_basic_auth_header("wrong_user", "wrong_pass")

      conn =
        :post
        |> Plug.Test.conn("/webhooks/postmark", body)
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> Plug.Conn.put_private(:raw_body, body)
        |> Plug.Conn.put_req_header(h, v)

      {result, log} =
        with_log(fn ->
          WebhookPlug.call(conn, WebhookPlug.init(provider: :postmark))
        end)

      assert result.status == 401

      # D-24 discipline: provider + atom, nothing else.
      assert log =~ "Webhook signature failed"
      assert log =~ "provider=postmark"
      assert log =~ "reason=bad_credentials"

      # Critical: no PII leak in the log output (T-04-04 mitigation).
      refute log =~ "127.0.0.1"
      refute log =~ "wrong_user"
      refute log =~ "wrong_pass"
      refute log =~ body
    end

    test "401 on SendGrid bit-flipped body", %{sendgrid_keypair: {_pub, priv}} do
      body = Mailglass.WebhookFixtures.load_sendgrid_fixture("single_event")
      ts = Integer.to_string(System.system_time(:second))
      sig = Mailglass.WebhookFixtures.sign_sendgrid_payload(ts, body, priv)

      # Tamper the body AFTER signing — the signature now covers a different
      # payload than what arrives on the wire.
      tampered = String.replace(body, "delivered", "DeliveRed")

      conn =
        :post
        |> Plug.Test.conn("/webhooks/sendgrid", tampered)
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> Plug.Conn.put_private(:raw_body, tampered)
        |> Plug.Conn.put_req_header("x-twilio-email-event-webhook-signature", sig)
        |> Plug.Conn.put_req_header("x-twilio-email-event-webhook-timestamp", ts)

      {result, _log} =
        with_log(fn ->
          WebhookPlug.call(conn, WebhookPlug.init(provider: :sendgrid))
        end)

      assert result.status == 401
    end

    test "401 on missing SendGrid signature header" do
      body = Mailglass.WebhookFixtures.load_sendgrid_fixture("single_event")

      conn =
        :post
        |> Plug.Test.conn("/webhooks/sendgrid", body)
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> Plug.Conn.put_private(:raw_body, body)

      {result, log} =
        with_log(fn ->
          WebhookPlug.call(conn, WebhookPlug.init(provider: :sendgrid))
        end)

      assert result.status == 401
      assert log =~ "provider=sendgrid"
      assert log =~ "reason=missing_header"
    end
  end

  describe "call/2 response code matrix — 422 tenant unresolved" do
    # Stub Tenancy module that returns {:error, :no_tenant_match} from
    # resolve_webhook_tenant/1 — exercises the 422 rescue clause directly.
    defmodule UnresolvedTenancy do
      @moduledoc false
      @behaviour Mailglass.Tenancy

      @impl Mailglass.Tenancy
      def scope(query, _context), do: query

      def resolve_webhook_tenant(_context), do: {:error, :no_tenant_match}
    end

    test "422 on tenant-unresolved + Logger.warning discipline" do
      prior = Application.get_env(:mailglass, :tenancy)
      Application.put_env(:mailglass, :tenancy, UnresolvedTenancy)

      on_exit(fn ->
        if is_nil(prior) do
          Application.delete_env(:mailglass, :tenancy)
        else
          Application.put_env(:mailglass, :tenancy, prior)
        end
      end)

      body = Mailglass.WebhookFixtures.load_postmark_fixture("delivered")
      conn = Mailglass.WebhookCase.mailglass_webhook_conn(:postmark, body)

      {result, log} =
        with_log(fn ->
          WebhookPlug.call(conn, WebhookPlug.init(provider: :postmark))
        end)

      assert result.status == 422

      # Logger message format: provider + atom reason only.
      assert log =~ "Webhook tenant resolution failed"
      assert log =~ "provider=postmark"
      assert log =~ "reason=webhook_tenant_unresolved"

      # No PII in the log.
      refute log =~ "127.0.0.1"
      refute log =~ body
    end
  end

  describe "call/2 response code matrix — 500 config errors" do
    test "500 on missing CachingBodyReader (conn.private[:raw_body] nil)" do
      # Build conn WITHOUT put_private(:raw_body, ...) — simulates adopter
      # forgetting to wire Plug.Parsers' :body_reader.
      conn =
        :post
        |> Plug.Test.conn("/webhooks/postmark", "{}")
        |> Plug.Conn.put_req_header("content-type", "application/json")

      # deliberately NO put_private(:raw_body, ...)

      {result, log} =
        with_log(fn ->
          WebhookPlug.call(conn, WebhookPlug.init(provider: :postmark))
        end)

      assert result.status == 500

      # Log references the distinct atom (B4) — adopters can distinguish
      # plug-wiring gap from missing-secret with a single atom grep.
      assert log =~ "Webhook config error"
      assert log =~ "provider=postmark"
      assert log =~ "reason=webhook_caching_body_reader_missing"
    end

    test "500 on missing Postmark basic_auth config" do
      # Override :postmark config to omit :basic_auth — the Postmark
      # verifier raises %ConfigError{:webhook_verification_key_missing}
      # which the Plug rescues as 500.
      prior = Application.get_env(:mailglass, :postmark)

      Application.put_env(:mailglass, :postmark,
        enabled: true,
        ip_allowlist: []
      )

      on_exit(fn ->
        if is_nil(prior) do
          Application.delete_env(:mailglass, :postmark)
        else
          Application.put_env(:mailglass, :postmark, prior)
        end
      end)

      body = Mailglass.WebhookFixtures.load_postmark_fixture("delivered")

      # Build conn WITHOUT an auth header — the verifier will fail on the
      # missing-config path before it inspects the header.
      conn =
        :post
        |> Plug.Test.conn("/webhooks/postmark", body)
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> Plug.Conn.put_private(:raw_body, body)

      {result, log} =
        with_log(fn ->
          WebhookPlug.call(conn, WebhookPlug.init(provider: :postmark))
        end)

      assert result.status == 500
      assert log =~ "provider=postmark"
      assert log =~ "reason=webhook_verification_key_missing"
    end
  end

  describe "call/2 telemetry" do
    test "emits [:mailglass, :webhook, :ingest, :start | :stop] with whitelisted metadata" do
      handler_id = "plug-test-#{System.unique_integer()}"
      test_pid = self()

      :telemetry.attach_many(
        handler_id,
        [
          [:mailglass, :webhook, :ingest, :start],
          [:mailglass, :webhook, :ingest, :stop]
        ],
        fn event, measurements, meta, _ ->
          send(test_pid, {:telemetry, event, measurements, meta})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      # Exercise the signature-failure path — still emits :start + :stop
      # around the outer plug span (the inner verify span emits its own
      # :exception event, but the outer span returns normally with a 401
      # response). This avoids depending on Plan 06's ingest_multi/3.
      body = Mailglass.WebhookFixtures.load_postmark_fixture("delivered")
      {h, v} = Mailglass.WebhookFixtures.postmark_basic_auth_header("wrong", "creds")

      conn =
        :post
        |> Plug.Test.conn("/webhooks/postmark", body)
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> Plug.Conn.put_private(:raw_body, body)
        |> Plug.Conn.put_req_header(h, v)

      with_log(fn ->
        WebhookPlug.call(conn, WebhookPlug.init(provider: :postmark))
      end)

      assert_receive {:telemetry, [:mailglass, :webhook, :ingest, :start], _, start_meta}, 250
      assert_receive {:telemetry, [:mailglass, :webhook, :ingest, :stop], _, stop_meta}, 250

      assert start_meta.provider == :postmark

      # D-23 metadata whitelist enforcement — no PII keys in either phase.
      for meta <- [start_meta, stop_meta] do
        refute Map.has_key?(meta, :ip)
        refute Map.has_key?(meta, :user_agent)
        refute Map.has_key?(meta, :remote_ip)
        refute Map.has_key?(meta, :raw_body)
        refute Map.has_key?(meta, :headers)
        refute Map.has_key?(meta, :body)
      end
    end
  end

  describe "Mailglass.Tenancy.resolve_webhook_tenant/1 dispatcher stub" do
    test "returns {:ok, \"default\"} for SingleTenant (Plan 05 precondition)" do
      prior = Application.get_env(:mailglass, :tenancy)
      # SingleTenant has no resolve_webhook_tenant/1 impl at this plan's
      # ship time (Plan 05 adds it). The dispatcher's function_exported?
      # fallback returns the string "default".
      Application.put_env(:mailglass, :tenancy, Mailglass.Tenancy.SingleTenant)

      on_exit(fn ->
        if is_nil(prior) do
          Application.delete_env(:mailglass, :tenancy)
        else
          Application.put_env(:mailglass, :tenancy, prior)
        end
      end)

      ctx = %{
        provider: :postmark,
        conn: nil,
        raw_body: "",
        headers: [],
        path_params: %{},
        verified_payload: nil
      }

      assert {:ok, "default"} = Mailglass.Tenancy.resolve_webhook_tenant(ctx)
    end
  end
end
