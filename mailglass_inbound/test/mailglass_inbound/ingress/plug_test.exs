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
      Process.put(:mailglass_inbound_execution_order, [:persist | Process.get(:mailglass_inbound_execution_order, [])])

      case Process.get(:mailglass_inbound_persist_error) do
        nil ->
          status = Process.get(:mailglass_inbound_persist_status, :inserted)

          {:ok,
           %{
             status: status,
             message: handoff.message,
             inbound_record: %{id: "record-123", tenant_id: handoff.tenant_id},
             inbound_evidence: %{id: "evidence-123"},
             route: %{status: :matched, mailbox: SupportMailbox}
           }}

        reason ->
          {:error, reason}
      end
    end
  end

  defmodule FakeExecution do
    def dispatch(result, _opts \\ []) do
      Process.put(:mailglass_inbound_last_execution_result, result)
      Process.put(:mailglass_inbound_execution_order, [:dispatch | Process.get(:mailglass_inbound_execution_order, [])])

      case Process.get(:mailglass_inbound_execution_outcome, :accept) do
        :accept -> {:ok, %{status: :queued, mode: :oban}}
        :ignore -> {:ok, %{status: :queued, mode: :task_supervisor, durability: :best_effort}}
        :no_match -> {:ok, %{status: :queued, mode: :oban}}
        :reject -> {:ok, %{status: :queued, mode: :oban}}
        :bounce -> {:ok, %{status: :queued, mode: :oban}}
        :failed -> {:error, :dispatch_failed}
      end
    end
  end

  # Stub provider injected via the plug's `:provider_module` opts seam so the
  # widened verify-result branches (D-46-06) and the dual SignatureError rescue
  # (D-46-19) can be exercised without the real Mailgun/SES providers (Plans
  # 02/03). The verify outcome is process-dictionary driven.
  defmodule StubProvider do
    # A test double, not a full behaviour implementation: the plug dispatches the
    # struct-arity verify!/2 + normalize/1 for :mailgun/:ses, which is all this
    # stub needs to provide. Declaring @behaviour would force the legacy
    # normalize/2 arity it never uses.
    def verify!(%MailglassInbound.Ingress.Request{}, _config) do
      case Process.get(:mailglass_inbound_stub_verify, {:ok, %{auth: :stub}}) do
        {:raise, :inbound} ->
          raise MailglassInbound.SignatureError.new(:bad_signature, provider: :mailgun)

        {:raise, :core} ->
          raise Mailglass.SignatureError.new(:bad_signature, provider: :ses)

        {:raise, :s3, type} ->
          # CR-02: SES verify!/2 raises S3FetchError on retry exhaustion /
          # non-retryable S3 error. `:cause` carries the raw recipient-adjacent
          # S3 fragment so the test can prove it never leaks into the response.
          raise %MailglassInbound.S3FetchError{
            type: type,
            message: "stub S3 fetch failure",
            cause: {:s3, "bob@secret.example", "Confidential merger terms"},
            context: %{bucket: "secret-bucket"}
          }

        other ->
          other
      end
    end

    def normalize(%MailglassInbound.Ingress.Request{} = request) do
      %{
        message: %MailglassInbound.InboundMessage{
          provider: request.provider,
          provider_message_id: "stub-message-1",
          envelope_recipient: "support@example.com",
          to: [%{address: "support@example.com", name: nil}]
        },
        evidence: %{verification_facts: %{}}
      }
    end
  end

  # WR-04: a stub that records the config map the plug threads into verify!/2, so
  # we can prove resolve_config!(:ses, ...) now carries the documented
  # :s3_retry_opts tuning knob (previously dropped, making it dead config).
  defmodule ConfigCaptureProvider do
    def verify!(%MailglassInbound.Ingress.Request{}, config) do
      Process.put(:mailglass_inbound_captured_config, config)
      {:replay}
    end

    def normalize(%MailglassInbound.Ingress.Request{} = request) do
      %{message: %MailglassInbound.InboundMessage{provider: request.provider}, evidence: %{}}
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
    Process.delete(:mailglass_inbound_last_execution_result)
    Process.delete(:mailglass_inbound_execution_order)
    Process.delete(:mailglass_inbound_execution_outcome)
    Process.delete(:mailglass_inbound_stub_verify)
    Process.delete(:mailglass_inbound_persist_error)

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
          persistence: FakePersistence,
          execution: FakeExecution
        )
      )

    body = Jason.decode!(conn.resp_body)
    handoff = Process.get(:mailglass_inbound_last_handoff)
    execution_result = Process.get(:mailglass_inbound_last_execution_result)

    assert conn.status == 200
    assert body["status"] == "inserted"
    assert body["route"] == "matched"
    assert Enum.reverse(Process.get(:mailglass_inbound_execution_order)) == [:persist, :dispatch]
    assert handoff.tenant_id == "tenant-123"
    assert handoff.message.tenant_id == "tenant-123"
    assert handoff.message.provider == :postmark
    assert handoff.message.envelope_recipient == "support@example.com"
    assert handoff.evidence.verification_facts.auth == :basic_auth
    assert execution_result.inbound_record.id == "record-123"
    assert execution_result.inbound_evidence.id == "evidence-123"
    assert execution_result.route == %{status: :matched, mailbox: SupportMailbox}
  end

  test "maps duplicate persistence outcomes to 200 without pretending it is new work" do
    Process.put(:mailglass_inbound_persist_status, :duplicate)

    conn =
      conn_with_auth(postmark_payload())
      |> Map.put(:path_params, %{"tenant_id" => "tenant-123"})

    conn =
      IngressPlug.call(
        conn,
        IngressPlug.init(
          provider: :postmark,
          router: TestRouter,
          persistence: FakePersistence,
          execution: FakeExecution
        )
      )

    assert conn.status == 200
    assert Jason.decode!(conn.resp_body)["status"] == "duplicate"
    assert Process.get(:mailglass_inbound_last_execution_result) == nil
  end

  test "does not execute the mailbox a second time for sendgrid duplicates" do
    Process.put(:mailglass_inbound_persist_status, :duplicate)

    conn =
      sendgrid_conn(sendgrid_params())
      |> Map.put(:path_params, %{"tenant_id" => "tenant-123"})

    conn =
      IngressPlug.call(
        conn,
        IngressPlug.init(
          provider: :sendgrid,
          router: TestRouter,
          persistence: FakePersistence,
          execution: FakeExecution
        )
      )

    assert conn.status == 200
    assert Jason.decode!(conn.resp_body)["status"] == "duplicate"
    assert Process.get(:mailglass_inbound_last_execution_result) == nil
  end

  test "persist failure returns a static PII-free 500 body (no changeset/inspect leak)" do
    # A transient persist failure returns an `%Ecto.Changeset{}` whose `changes`
    # carry recipient PII. The branch MUST NOT interpolate it into the response.
    pii_changeset =
      {%{}, %{from: :string, to: :string, subject: :string}}
      |> Ecto.Changeset.cast(
        %{from: "alice@secret.example", to: "bob@secret.example", subject: "Confidential merger terms"},
        [:from, :to, :subject]
      )
      |> Ecto.Changeset.add_error(:subject, "is invalid")

    Process.put(:mailglass_inbound_persist_error, pii_changeset)

    conn =
      conn_with_auth(postmark_payload())
      |> Map.put(:path_params, %{"tenant_id" => "tenant-123"})

    conn =
      IngressPlug.call(
        conn,
        IngressPlug.init(
          provider: :postmark,
          router: TestRouter,
          persistence: FakePersistence,
          execution: FakeExecution
        )
      )

    # Status stays 500 (correct retry signal for all four providers).
    assert conn.status == 500

    body = Jason.decode!(conn.resp_body)
    assert body["status"] == "error"
    # Static closed code — NOT the changeset, NOT inspect(reason).
    assert body["reason"] == "persist_failed"

    # No recipient PII reaches the provider in the response body.
    refute conn.resp_body =~ "alice@secret.example"
    refute conn.resp_body =~ "bob@secret.example"
    refute conn.resp_body =~ "Confidential merger terms"
    refute conn.resp_body =~ "Ecto.Changeset"
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
        IngressPlug.init(
          provider: :sendgrid,
          router: TestRouter,
          persistence: FakePersistence,
          execution: FakeExecution
        )
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

  test "acknowledges 200 after durable receive truth for semantic and failed execution outcomes" do
    for outcome <- [:ignore, :reject, :bounce, :failed] do
      Process.put(:mailglass_inbound_execution_outcome, outcome)

      conn =
        conn_with_auth(postmark_payload())
        |> Map.put(:path_params, %{"tenant_id" => "tenant-123"})

      conn =
        IngressPlug.call(
          conn,
          IngressPlug.init(
            provider: :postmark,
            router: TestRouter,
            persistence: FakePersistence,
            execution: FakeExecution
          )
        )

      assert conn.status == 200
      assert Jason.decode!(conn.resp_body)["status"] == "inserted"
    end
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

  # ---- Phase 46: four-provider allowlist (MGUN-04, D-46-05) ----

  test "init/1 accepts all four providers and rejects unknown ones" do
    assert is_list(IngressPlug.init(provider: :postmark))
    assert is_list(IngressPlug.init(provider: :sendgrid))
    assert is_list(IngressPlug.init(provider: :mailgun))
    assert is_list(IngressPlug.init(provider: :ses))

    assert_raise ArgumentError, fn -> IngressPlug.init(provider: :cloudflare) end
  end

  # ---- Phase 46: widened do_call result contract (D-46-06) ----

  test "a {:replay} verify return is a 200 no-op with no InboundRecord" do
    Process.put(:mailglass_inbound_stub_verify, {:replay})

    conn = stub_provider_conn(:mailgun)

    conn =
      IngressPlug.call(
        conn,
        IngressPlug.init(
          provider: :mailgun,
          provider_module: StubProvider,
          persistence: FakePersistence,
          execution: FakeExecution
        )
      )

    assert conn.status == 200
    assert Jason.decode!(conn.resp_body)["status"] == "replay"
    # No persistence, no execution — replay creates no state (T-46-02).
    assert Process.get(:mailglass_inbound_last_handoff) == nil
    assert Process.get(:mailglass_inbound_last_execution_result) == nil
  end

  test "a {:control_plane, 200} verify return is a 200 no-op with no InboundRecord" do
    Process.put(:mailglass_inbound_stub_verify, {:control_plane, 200})

    conn = stub_provider_conn(:ses)

    conn =
      IngressPlug.call(
        conn,
        IngressPlug.init(
          provider: :ses,
          provider_module: StubProvider,
          persistence: FakePersistence,
          execution: FakeExecution
        )
      )

    assert conn.status == 200
    assert Jason.decode!(conn.resp_body)["status"] == "control_plane"
    assert Process.get(:mailglass_inbound_last_handoff) == nil
    assert Process.get(:mailglass_inbound_last_execution_result) == nil
  end

  test "an {:ok, facts} verify return persists as today" do
    Process.put(:mailglass_inbound_stub_verify, {:ok, %{auth: :hmac}})

    conn = stub_provider_conn(:mailgun)

    conn =
      IngressPlug.call(
        conn,
        IngressPlug.init(
          provider: :mailgun,
          provider_module: StubProvider,
          persistence: FakePersistence,
          execution: FakeExecution
        )
      )

    handoff = Process.get(:mailglass_inbound_last_handoff)

    assert conn.status == 200
    assert Jason.decode!(conn.resp_body)["status"] == "inserted"
    assert handoff.tenant_id == "tenant-123"
    assert handoff.message.provider == :mailgun
    assert handoff.evidence.verification_facts.auth == :hmac
    assert Process.get(:mailglass_inbound_last_execution_result).inbound_record.id == "record-123"
  end

  # ---- Phase 46: dual SignatureError rescue (D-46-19, T-46-01) ----

  test "a stub raising MailglassInbound.SignatureError maps to 401" do
    Process.put(:mailglass_inbound_stub_verify, {:raise, :inbound})

    conn = stub_provider_conn(:mailgun)

    conn =
      IngressPlug.call(
        conn,
        IngressPlug.init(provider: :mailgun, provider_module: StubProvider, persistence: FakePersistence)
      )

    assert conn.status == 401
    assert Jason.decode!(conn.resp_body)["status"] == "rejected"
    assert Jason.decode!(conn.resp_body)["reason"] == "bad_signature"
    assert Process.get(:mailglass_inbound_last_handoff) == nil
  end

  test "a stub raising core Mailglass.SignatureError maps to 401" do
    Process.put(:mailglass_inbound_stub_verify, {:raise, :core})

    conn = stub_provider_conn(:ses)

    conn =
      IngressPlug.call(
        conn,
        IngressPlug.init(provider: :ses, provider_module: StubProvider, persistence: FakePersistence)
      )

    assert conn.status == 401
    assert Jason.decode!(conn.resp_body)["status"] == "rejected"
    assert Jason.decode!(conn.resp_body)["reason"] == "bad_signature"
    assert Process.get(:mailglass_inbound_last_handoff) == nil
  end

  # ---- Phase 46: S3FetchError rescue (CR-02, T-46-24) ----

  test "a stub raising S3FetchError :s3_object_not_ready maps to 500 (transient, SNS redelivers)" do
    Process.put(:mailglass_inbound_stub_verify, {:raise, :s3, :s3_object_not_ready})

    conn = stub_provider_conn(:ses)

    conn =
      IngressPlug.call(
        conn,
        IngressPlug.init(provider: :ses, provider_module: StubProvider, persistence: FakePersistence)
      )

    body = Jason.decode!(conn.resp_body)

    # Transient -> 500 so the handler does NOT ack and SNS redelivers.
    assert conn.status == 500
    assert body["status"] == "s3_fetch_error"
    assert body["reason"] == "s3_object_not_ready"

    # No record was persisted on the verify-time S3 failure.
    assert Process.get(:mailglass_inbound_last_handoff) == nil

    # PII-free body: the S3FetchError :cause carries recipient-adjacent fragments
    # that must NEVER reach the provider in the response.
    refute conn.resp_body =~ "bob@secret.example"
    refute conn.resp_body =~ "Confidential merger terms"
    refute conn.resp_body =~ "secret-bucket"
  end

  test "a stub raising S3FetchError :s3_fetch_failed maps to 422 (permanent, stops redelivery storm)" do
    Process.put(:mailglass_inbound_stub_verify, {:raise, :s3, :s3_fetch_failed})

    conn = stub_provider_conn(:ses)

    conn =
      IngressPlug.call(
        conn,
        IngressPlug.init(provider: :ses, provider_module: StubProvider, persistence: FakePersistence)
      )

    body = Jason.decode!(conn.resp_body)

    # Permanent -> 422 (non-retryable): retrying will not help.
    assert conn.status == 422
    assert body["status"] == "s3_fetch_error"
    assert body["reason"] == "s3_fetch_failed"

    assert Process.get(:mailglass_inbound_last_handoff) == nil

    refute conn.resp_body =~ "bob@secret.example"
    refute conn.resp_body =~ "Confidential merger terms"
    refute conn.resp_body =~ "secret-bucket"
  end

  # ---- Phase 46: SES config threads :s3_retry_opts (WR-04) ----

  test "resolve_config!(:ses, ...) threads :s3_retry_opts from opts config into verify config" do
    Process.delete(:mailglass_inbound_captured_config)
    retry_opts = [attempts: 5, backoff_ms: [0, 0, 0, 0]]

    conn = stub_provider_conn(:ses)

    IngressPlug.call(
      conn,
      IngressPlug.init(
        provider: :ses,
        provider_module: ConfigCaptureProvider,
        persistence: FakePersistence,
        config: [s3_fetcher: nil, cert_cache_ttl_seconds: 60, s3_retry_opts: retry_opts]
      )
    )

    captured = Process.get(:mailglass_inbound_captured_config)

    assert is_map(captured)
    assert captured[:s3_retry_opts] == retry_opts
  end

  test "resolve_config!(:ses, ...) defaults :s3_retry_opts to [] when unset" do
    Process.delete(:mailglass_inbound_captured_config)

    conn = stub_provider_conn(:ses)

    IngressPlug.call(
      conn,
      IngressPlug.init(
        provider: :ses,
        provider_module: ConfigCaptureProvider,
        persistence: FakePersistence,
        config: [s3_fetcher: nil, cert_cache_ttl_seconds: 60]
      )
    )

    captured = Process.get(:mailglass_inbound_captured_config)

    assert captured[:s3_retry_opts] == []
  end

  # ---- Phase 49: post-verify ingress rate limiter (IOPS-04, D-49-14) ----

  # A stub whose normalized message carries both a `from` (so the limiter can
  # derive sender_domain) and an envelope_recipient (the recipient bucket key),
  # exercising the real RateLimiter.check/3 in persist_and_respond/5.
  defmodule RateLimitedProvider do
    def verify!(%MailglassInbound.Ingress.Request{}, _config), do: {:ok, %{auth: :stub}}

    def normalize(%MailglassInbound.Ingress.Request{} = request) do
      %{
        message: %MailglassInbound.InboundMessage{
          provider: request.provider,
          provider_message_id: "rl-message-1",
          envelope_recipient: "support@example.com",
          from: [%{address: "flooder@spam.example", name: "Flooder"}],
          to: [%{address: "support@example.com", name: nil}]
        },
        evidence: %{verification_facts: %{}}
      }
    end
  end

  describe "ingress rate limiter (post-verify)" do
    setup do
      prior_rate_limit = Application.get_env(:mailglass_inbound, :rate_limit)

      on_exit(fn ->
        if is_nil(prior_rate_limit) do
          Application.delete_env(:mailglass_inbound, :rate_limit)
        else
          Application.put_env(:mailglass_inbound, :rate_limit, prior_rate_limit)
        end
      end)

      # Tiny tenant capacity so the limiter trips on the 2nd verified request.
      Application.put_env(:mailglass_inbound, :rate_limit,
        tenant: [capacity: 1, per_minute: 60],
        recipient: [capacity: 1000, per_minute: 60],
        sender_domain: [capacity: 1000, per_minute: 60]
      )

      :ets.delete_all_objects(:mailglass_inbound_rate_limit)
      :ok
    end

    test "an over-limit verified request returns 429 with a retry-after header and bucket type" do
      opts =
        IngressPlug.init(
          provider: :mailgun,
          provider_module: RateLimitedProvider,
          persistence: FakePersistence,
          execution: FakeExecution
        )

      # First request is allowed.
      first = IngressPlug.call(stub_provider_conn(:mailgun), opts)
      assert first.status == 200

      # Second request trips the tenant bucket → 429.
      second = IngressPlug.call(stub_provider_conn(:mailgun), opts)

      assert second.status == 429
      body = Jason.decode!(second.resp_body)
      assert body["status"] == "rate_limited"
      assert body["bucket"] == "tenant"

      retry_after = Plug.Conn.get_resp_header(second, "retry-after")
      assert [value] = retry_after
      assert String.to_integer(value) >= 1
    end

    test "a forged request returns 401 and consumes no rate budget (limiter is post-verify)" do
      opts =
        IngressPlug.init(
          provider: :mailgun,
          provider_module: StubProvider,
          persistence: FakePersistence,
          execution: FakeExecution
        )

      Process.put(:mailglass_inbound_stub_verify, {:raise, :inbound})

      # Flood with forgeries — none should consume the tenant's budget.
      for _i <- 1..5 do
        conn = IngressPlug.call(stub_provider_conn(:mailgun), opts)
        assert conn.status == 401
      end

      # The budget is intact: a verified request through a separate provider
      # using the SAME tenant still succeeds (capacity: 1 was never burned).
      verified_opts =
        IngressPlug.init(
          provider: :mailgun,
          provider_module: RateLimitedProvider,
          persistence: FakePersistence,
          execution: FakeExecution
        )

      verified = IngressPlug.call(stub_provider_conn(:mailgun), verified_opts)
      assert verified.status == 200
    end

    test "the rate_limit stop telemetry carries bucket TYPE only (no PII value keys)" do
      ref =
        :telemetry_test.attach_event_handlers(self(), [
          [:mailglass_inbound, :ingress, :rate_limit, :stop]
        ])

      opts =
        IngressPlug.init(
          provider: :mailgun,
          provider_module: RateLimitedProvider,
          persistence: FakePersistence,
          execution: FakeExecution
        )

      # First allowed, second trips → emits the rate_limit span.
      IngressPlug.call(stub_provider_conn(:mailgun), opts)
      IngressPlug.call(stub_provider_conn(:mailgun), opts)

      assert_receive {[:mailglass_inbound, :ingress, :rate_limit, :stop], ^ref, _measurements, meta}

      assert meta[:bucket] in [:tenant, :recipient, :sender_domain]

      # PII value keys must NEVER appear in the telemetry meta.
      refute Map.has_key?(meta, :recipient)
      refute Map.has_key?(meta, :sender)
      refute Map.has_key?(meta, :to)
      refute Map.has_key?(meta, :from)
      refute Map.has_key?(meta, :email)

      :telemetry.detach(ref)
    end
  end

  defp stub_provider_conn(provider) do
    Plug.Test.conn(:post, "/inbound/tenant-123/#{provider}", "")
    |> Plug.Conn.put_req_header("content-type", "application/json")
    |> Plug.Conn.put_private(:raw_body, "{}")
    |> Map.put(:params, %{})
    |> Map.put(:path_params, %{"tenant_id" => "tenant-123"})
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
