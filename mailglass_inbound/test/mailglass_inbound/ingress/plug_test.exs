defmodule MailglassInbound.Ingress.PlugTest do
  use ExUnit.Case, async: false

  alias MailglassInbound.Ingress.Plug, as: IngressPlug

  defmodule TenantResolver do
    @behaviour Mailglass.Tenancy

    def scope(query, _context), do: query
    def resolve_outbound_adapter_ref(_context), do: :default

    def resolve_webhook_tenant(%{path_params: %{"tenant_id" => tenant_id}})
        when is_binary(tenant_id) and tenant_id != "" do
      Process.put(:mailglass_inbound_tenant_resolved, true)
      {:ok, tenant_id}
    end

    def resolve_webhook_tenant(_context), do: {:error, :missing_path_param}
  end

  defmodule SupportMailbox do
    @behaviour MailglassInbound.Mailbox
    def process(_message), do: :accept
  end

  defmodule TestRouter do
    use MailglassInbound.Router

    route SupportMailbox, recipient: "support@example.com"
  end

  defmodule FakePersistence do
    def persist(handoff, opts) do
      Process.put(:mailglass_inbound_last_handoff, handoff)
      Process.put(:mailglass_inbound_last_persist_opts, opts)

      status = Process.get(:mailglass_inbound_persist_status, :inserted)

      {:ok,
       %{
         status: status,
         route: %{status: :matched, mailbox: SupportMailbox}
       }}
    end
  end

  setup do
    prior_tenancy = Application.get_env(:mailglass, :tenancy)
    prior_postmark = Application.get_env(:mailglass_inbound, :postmark)
    prior_sendgrid = Application.get_env(:mailglass_inbound, :sendgrid)

    Application.put_env(:mailglass, :tenancy, TenantResolver)

    Application.put_env(:mailglass_inbound, :postmark,
      basic_auth: {"postmark", "secret"},
      ip_allowlist: []
    )

    Application.put_env(:mailglass_inbound, :sendgrid,
      basic_auth: {"sendgrid", "secret"}
    )

    Process.delete(:mailglass_inbound_last_handoff)
    Process.delete(:mailglass_inbound_last_persist_opts)
    Process.delete(:mailglass_inbound_persist_status)
    Process.delete(:mailglass_inbound_tenant_resolved)

    on_exit(fn ->
      if is_nil(prior_tenancy) do
        Application.delete_env(:mailglass, :tenancy)
      else
        Application.put_env(:mailglass, :tenancy, prior_tenancy)
      end

      if is_nil(prior_postmark) do
        Application.delete_env(:mailglass_inbound, :postmark)
      else
        Application.put_env(:mailglass_inbound, :postmark, prior_postmark)
      end

      if is_nil(prior_sendgrid) do
        Application.delete_env(:mailglass_inbound, :sendgrid)
      else
        Application.put_env(:mailglass_inbound, :sendgrid, prior_sendgrid)
      end
    end)

    :ok
  end

  test "verifies first, resolves tenant, normalizes, and hands off to persistence" do
    conn =
      conn_with_auth(postmark_payload())
      |> Map.put(:path_params, %{"tenant_id" => "tenant-123"})

    conn =
      IngressPlug.call(
        conn,
        IngressPlug.init(
          provider: :postmark,
          router: TestRouter,
          persistence: FakePersistence
        )
      )

    body = Jason.decode!(conn.resp_body)
    handoff = Process.get(:mailglass_inbound_last_handoff)

    assert conn.status == 200
    assert body["status"] == "inserted"
    assert body["route"] == "matched"
    assert handoff.tenant_id == "tenant-123"
    assert handoff.message.tenant_id == "tenant-123"
    assert handoff.message.provider == :postmark
    assert handoff.message.envelope_recipient == "support@example.com"
    assert handoff.evidence.verification_facts.auth == :basic_auth
  end

  test "maps duplicate persistence outcomes to 200 without pretending it is new work" do
    Process.put(:mailglass_inbound_persist_status, :duplicate)

    conn =
      conn_with_auth(postmark_payload())
      |> Map.put(:path_params, %{"tenant_id" => "tenant-123"})

    conn =
      IngressPlug.call(
        conn,
        IngressPlug.init(provider: :postmark, router: TestRouter, persistence: FakePersistence)
      )

    assert conn.status == 200
    assert Jason.decode!(conn.resp_body)["status"] == "duplicate"
  end

  test "returns 401 on auth failure" do
    conn =
      Plug.Test.conn(:post, "/inbound/tenant-123/postmark", postmark_payload())
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> Plug.Conn.put_req_header("authorization", basic_auth("wrong", "secret"))
      |> Plug.Conn.put_private(:raw_body, postmark_payload())
      |> Map.put(:path_params, %{"tenant_id" => "tenant-123"})

    conn = IngressPlug.call(conn, IngressPlug.init(provider: :postmark, persistence: FakePersistence))

    assert conn.status == 401
    assert Jason.decode!(conn.resp_body)["reason"] == "bad_credentials"
  end

  test "returns 500 when the inbound body reader was not wired" do
    conn =
      Plug.Test.conn(:post, "/inbound/tenant-123/postmark", postmark_payload())
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> Plug.Conn.put_req_header("authorization", basic_auth("postmark", "secret"))
      |> Map.put(:path_params, %{"tenant_id" => "tenant-123"})

    conn = IngressPlug.call(conn, IngressPlug.init(provider: :postmark, persistence: FakePersistence))

    assert conn.status == 500
    assert Jason.decode!(conn.resp_body)["reason"] == "webhook_caching_body_reader_missing"
  end

  test "returns 422 when tenant resolution fails after verification" do
    conn = conn_with_auth(postmark_payload())
    conn = IngressPlug.call(conn, IngressPlug.init(provider: :postmark, persistence: FakePersistence))

    assert conn.status == 422
    assert Jason.decode!(conn.resp_body)["reason"] == "webhook_tenant_unresolved"
  end

  test "supports sendgrid through the shared ingress seam and verifies before tenant resolution" do
    conn =
      sendgrid_conn(sendgrid_params())
      |> Map.put(:path_params, %{"tenant_id" => "tenant-123"})

    conn =
      IngressPlug.call(
        conn,
        IngressPlug.init(provider: :sendgrid, router: TestRouter, persistence: FakePersistence)
      )

    body = Jason.decode!(conn.resp_body)
    handoff = Process.get(:mailglass_inbound_last_handoff)

    assert conn.status == 200
    assert body["status"] == "inserted"
    assert body["route"] == "matched"
    assert Process.get(:mailglass_inbound_tenant_resolved) == true
    assert handoff.message.provider == :sendgrid
    assert handoff.message.provider_message_id == nil
    assert handoff.message.message_id == "<rfc-message@example.com>"
    assert handoff.message.envelope_recipient == "support@example.com"
    assert handoff.evidence.verification_facts.auth == :basic_auth
    assert handoff.evidence.raw_mime == sendgrid_raw_mime()
  end

  test "returns 401 on sendgrid auth failure without resolving tenant" do
    conn =
      Plug.Test.conn(:post, "/inbound/tenant-123/sendgrid", sendgrid_params())
      |> Plug.Conn.put_req_header("authorization", basic_auth("wrong", "secret"))
      |> Plug.Conn.put_req_header("content-type", "multipart/form-data; boundary=boundary42")
      |> Map.put(:params, sendgrid_params())
      |> Map.put(:path_params, %{"tenant_id" => "tenant-123"})

    conn = IngressPlug.call(conn, IngressPlug.init(provider: :sendgrid, persistence: FakePersistence))

    assert conn.status == 401
    assert Jason.decode!(conn.resp_body)["reason"] == "bad_credentials"
    refute Process.get(:mailglass_inbound_tenant_resolved)
  end

  test "returns 500 when sendgrid raw mime delivery is not configured" do
    conn =
      sendgrid_conn(Map.delete(sendgrid_params(), "email"))
      |> Map.put(:path_params, %{"tenant_id" => "tenant-123"})

    conn = IngressPlug.call(conn, IngressPlug.init(provider: :sendgrid, persistence: FakePersistence))

    body = Jason.decode!(conn.resp_body)

    assert conn.status == 500
    assert body["reason"] == "invalid"
    assert body["message"] =~ "raw MIME"
  end

  test "returns 500 when sendgrid verification config is missing" do
    Application.delete_env(:mailglass_inbound, :sendgrid)

    conn =
      sendgrid_conn(sendgrid_params())
      |> Map.put(:path_params, %{"tenant_id" => "tenant-123"})

    conn = IngressPlug.call(conn, IngressPlug.init(provider: :sendgrid, persistence: FakePersistence))

    assert conn.status == 500
    assert Jason.decode!(conn.resp_body)["reason"] == "webhook_verification_key_missing"
  end

  defp conn_with_auth(body) do
    Plug.Test.conn(:post, "/inbound/tenant-123/postmark", body)
    |> Plug.Conn.put_req_header("content-type", "application/json")
    |> Plug.Conn.put_req_header("authorization", basic_auth("postmark", "secret"))
    |> Plug.Conn.put_private(:raw_body, body)
  end

  defp basic_auth(user, pass) do
    "Basic " <> Base.encode64("#{user}:#{pass}")
  end

  defp postmark_payload do
    Jason.encode!(%{
      "FromFull" => [%{"Email" => "sender@example.com", "Name" => "Sender"}],
      "ToFull" => [%{"Email" => "support@example.com", "Name" => "Support"}],
      "ReplyToFull" => [%{"Email" => "reply@example.com", "Name" => "Reply"}],
      "Subject" => "Support request",
      "MessageID" => "pm-message-123",
      "OriginalRecipient" => "support@example.com",
      "TextBody" => "Plain body",
      "HtmlBody" => "<p>HTML body</p>",
      "Headers" => [
        %{"Name" => "Message-Id", "Value" => "<rfc-message@example.com>"},
        %{"Name" => "Date", "Value" => "2026-05-06T12:00:00Z"}
      ],
      "Attachments" => []
    })
  end

  defp sendgrid_conn(params) do
    Plug.Test.conn(:post, "/inbound/tenant-123/sendgrid", params)
    |> Plug.Conn.put_req_header("authorization", basic_auth("sendgrid", "secret"))
    |> Plug.Conn.put_req_header("content-type", "multipart/form-data; boundary=boundary42")
    |> Map.put(:params, params)
  end

  defp sendgrid_params do
    %{
      "email" => sendgrid_raw_mime(),
      "from" => "Sender <sender@example.com>",
      "to" => "Support <support@example.com>",
      "subject" => "Support request",
      "spam_score" => "0.001",
      "envelope" => Jason.encode!(%{"to" => ["support@example.com"]})
    }
  end

  defp sendgrid_raw_mime do
    [
      "From: Sender <sender@example.com>\r\n",
      "To: Support <support@example.com>\r\n",
      "Reply-To: Reply <reply@example.com>\r\n",
      "Subject: Support request\r\n",
      "Message-ID: <rfc-message@example.com>\r\n",
      "Date: Tue, 06 May 2026 12:00:00 +0000\r\n",
      "MIME-Version: 1.0\r\n",
      "Content-Type: multipart/alternative; boundary=alt42\r\n",
      "\r\n",
      "--alt42\r\n",
      "Content-Type: text/plain; charset=UTF-8\r\n",
      "\r\n",
      "Plain body\r\n",
      "--alt42\r\n",
      "Content-Type: text/html; charset=UTF-8\r\n",
      "\r\n",
      "<p>HTML body</p>\r\n",
      "--alt42--\r\n"
    ]
    |> IO.iodata_to_binary()
  end
end
