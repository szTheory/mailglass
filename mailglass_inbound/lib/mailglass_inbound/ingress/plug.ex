defmodule MailglassInbound.Ingress.Plug do
  @moduledoc """
  Public inbound ingress plug for `mailglass_inbound`.

  The plug verifies provider requests first, resolves tenant scope second, then
  normalizes and persists the canonical inbound message without executing any mailbox.

  ## Telemetry + post-commit broadcast

  The whole request is wrapped in a `[:mailglass_inbound, :ingress, :request, *]`
  span via `MailglassInbound.Telemetry`.

  After `Persist.persist/2` returns `{:ok, %{status: :inserted}}` — i.e. AFTER the
  `repo.transact` inside `Persist.persist/2` has committed — the plug broadcasts a
  PII-free `{:inbound_record_inserted, record_id, %{provider:, record_type:}}`
  message on `Mailglass.PubSub` to the per-tenant topic from
  `MailglassInbound.PubSub.Topics.inbound_record_inserted/1`. The broadcast runs
  OUTSIDE the transaction and never rolls it back:
  the committed `InboundRecord` is the durable source of truth, PubSub is the
  realtime fan-out for the admin LiveView. A `:duplicate` result
  broadcasts nothing.
  """

  @behaviour Plug

  # Mailgun/SES ingress providers are forward references in this module.
  # Suppress the not-yet-defined warning so the contract compiles
  # warning-free now; the plug only resolves these modules when a
  # :mailgun/:ses request is actually dispatched.
  @compile {:no_warn_undefined,
            [MailglassInbound.Ingress.Providers.Mailgun, MailglassInbound.Ingress.Providers.SES]}

  import Plug.Conn

  alias Mailglass.{ConfigError, SignatureError, Tenancy, TenancyError}
  # Inbound signature error raised by the Mailgun/SES providers.
  # Aliased here so the rescue clause can catch both it and core's SignatureError.
  alias MailglassInbound.SignatureError, as: InboundSignatureError
  # SES verify!/2 fetches the raw MIME body from S3 during verification; on retry
  # exhaustion or a non-retryable S3 error it raises S3FetchError. Aliased so the
  # rescue clause can catch it and map transient vs permanent to the right
  # response (CR-02) instead of letting it escape as an uncontrolled 500.
  alias MailglassInbound.S3FetchError
  alias MailglassInbound.Execution
  alias MailglassInbound.Ingress.Request

  @impl Plug
  def init(opts) when is_list(opts) do
    provider = Keyword.get(opts, :provider, :postmark)

    unless provider in [:postmark, :sendgrid, :mailgun, :ses] do
      raise ArgumentError,
            "MailglassInbound.Ingress.Plug supports provider: :postmark, :sendgrid, :mailgun, or :ses only"
    end

    opts
  end

  @impl Plug
  def call(conn, opts) do
    provider = Keyword.get(opts, :provider, :postmark)

    MailglassInbound.Telemetry.ingress_span(%{provider: provider}, fn ->
      do_call(conn, provider, opts)
    end)
  end

  defp do_call(conn, provider, opts) do
    try do
      request = build_request!(provider, conn)
      config = resolve_config!(provider, conn, opts)

      # Verify signature before tenant lookup to fail closed on spoofed payloads.
      # For SES, verify runs before resolve_tenant!.
      # resolve_tenant!. For SES this means the bounded S3 GetObject (with up to
      # the configured backoff) happens inside verify_request!, before the tenant
      # is resolved. This ordering is deliberate and safe:
      #
      #   * Signature is verified FIRST inside verify_envelope! (X.509), so only
      #     authentic SNS messages ever reach the S3 fetch — a forgery is rejected
      #     with no network I/O. Verify-before-tenant is a security invariant;
      #     we never do tenant work for an unauthenticated request.
      #   * The S3 fetch is part of verification because the verified SNS payload
      #     is what names the bucket/objectKey (single fetch, no double fetch).
      #   * The fetch cost is BOUNDED and now CONFIGURABLE: the retry attempts +
      #     backoff are tunable per deployment via :s3_retry_opts, which the SES
      #     resolve_config! threads into the provider (WR-04). A deployment that
      #     cannot afford holding a request process across the default backoff can
      #     shrink it (e.g. attempts: 1) from app config.
      #
      # The residual cost — an authentic message for an unresolvable tenant pays
      # the fetch before the 422 — is accepted: it requires a valid SNS signature
      # for the configured topic, so it is not an unauthenticated DoS vector.
      #
      # Widened verify result contract (mirrors core
      # lib/mailglass/webhook/plug.ex:119-161). Verify can now express
      # non-persisting verified outcomes:
      #   * {:replay}            — Mailgun replay hit → 200 no-op, NO record (T-46-02)
      #   * {:control_plane, _}  — SES SNS Subscription/Unsubscribe confirmation
      #                            → 200 no-op, NO record (T-46-02)
      #   * {:ok, facts}         — verified (Mailgun/SES struct arity) → persist
      #   * facts (bare map)     — verified (legacy Postmark/SendGrid) → persist
      # Replay and control-plane MUST be 200 no-ops — never SignatureError/401
      # (providers retry-storm on non-200; T-46-03). Forgery raises and is caught
      # by the rescue below (→ 401).
      case verify_request!(provider, request, config, opts) do
        {:replay} ->
          resp = send_json(conn, 200, %{status: "replay"})
          {resp, %{provider: provider, status: :replay}}

        {:control_plane, _http_status} ->
          resp = send_json(conn, 200, %{status: "control_plane"})
          {resp, %{provider: provider, status: :control_plane}}

        {:ok, facts} when is_map(facts) ->
          persist_and_respond(conn, provider, request, facts, opts)

        facts when is_map(facts) ->
          # Legacy bare-map return from Postmark/SendGrid verify! (unchanged
          # shipped-v1.1 providers). Treated as a successful, persisting verify.
          persist_and_respond(conn, provider, request, facts, opts)
      end
    rescue
      # Signature failures are terminal typed errors; do not recover in the plug.
      # Postmark/SendGrid raise core's
      # Mailglass.SignatureError; Mailgun/SES raise the net-new
      # MailglassInbound.SignatureError. Both map to 401 with no recovery
      # (T-46-01) — a forged-signature path must NEVER escape as a 500. Both
      # structs expose a `.type` atom, so the body is identical.
      e in [SignatureError, InboundSignatureError] ->
        resp = send_json(conn, 401, %{status: "rejected", reason: Atom.to_string(e.type)})
        {resp, %{provider: provider, status: :rejected}}

      # CR-02: SES verify!/2 fetches the raw MIME from S3 inside verification;
      # retry exhaustion or a non-retryable S3 error raises S3FetchError. Without
      # this clause it escaped the rescue allowlist and the telemetry span,
      # producing an uncontrolled 500 (only correct by accident) and collapsing
      # the transient/permanent distinction so a permanently-failing object would
      # trigger infinite SNS redelivery. Map the two closed types explicitly:
      #
      #   * :s3_object_not_ready  -> 500 (transient; the handler does NOT ack, so
      #                              SNS redelivers and the dedupe layer absorbs
      #                              the duplicate — the designed safety net).
      #   * :s3_fetch_failed      -> 422 (permanent; retry will not help, so a
      #                              non-retryable status stops the redelivery
      #                              storm). SNS treats non-2xx as failure either
      #                              way, but 422 documents the permanent intent.
      #
      # The `e.type` rides the PII-free telemetry stop-meta as `error_kind`; the
      # response body carries only the closed-type atom name, never PII.
      e in S3FetchError ->
        status = if e.type == :s3_object_not_ready, do: 500, else: 422

        resp =
          send_json(conn, status, %{status: "s3_fetch_error", reason: Atom.to_string(e.type)})

        {resp, %{provider: provider, status: :s3_fetch_error, error_kind: e.type}}

      e in TenancyError ->
        resp = send_json(conn, 422, %{status: "tenant_unresolved", reason: Atom.to_string(e.type)})
        {resp, %{provider: provider, status: :tenant_unresolved}}

      e in ConfigError ->
        resp =
          send_json(conn, 500, %{
            status: "config_error",
            reason: Atom.to_string(e.type),
            message: Exception.message(e)
          })

        {resp, %{provider: provider, status: :config_error}}
    end
  end

  # The persisting verify path (`{:ok, facts}` / legacy bare-map).
  # Resolves tenant → normalizes → builds the handoff → persists → dispatches.
  # Extracted verbatim from the pre-widening `do_call/2` body so the persist +
  # PII-safe egress behavior is unchanged for Postmark/SendGrid.
  defp persist_and_respond(conn, provider, request, verification_facts, opts) do
    tenant_id = resolve_tenant!(provider, conn, request)
    normalized = normalize_request!(provider, request, opts)

    # Post-verify rate limiter. This branch is reached only on
    # a successful verify ({:ok, facts} / legacy bare-map), so a forged-payload
    # flood is rejected with 401 BEFORE any budget is read — the limiter is never
    # an unauthenticated-DoS amplifier (T-49-01). It sits after resolve_tenant!
    # (needs tenant_id) and after normalize (needs the recipient + sender_domain),
    # before persist. On trip it NEVER raises — it returns the {resp, meta} 429
    # tuple, mirroring the TenancyError egress idiom; a raise would escape the
    # rescue allowlist as a 500 and trigger provider retry storms (T-49-03).
    case check_rate_limit(conn, provider, tenant_id, normalized.message) do
      :ok ->
        persist_and_dispatch(conn, provider, request, tenant_id, normalized, verification_facts, opts)

      {:rate_limited, resp, meta} ->
        {resp, meta}
    end
  end

  # Run the three-bucket post-verify limiter inside the dedicated rate_limit span
  # (single-span-surface invariant — emit from MailglassInbound.Telemetry, never
  # inline). Returns :ok to proceed, or {:rate_limited, resp, meta} to short out.
  defp check_rate_limit(conn, provider, tenant_id, message) do
    recipient = rate_limit_recipient(message)
    sender_domain = rate_limit_sender_domain(message)

    case MailglassInbound.RateLimiter.check(tenant_id, recipient, sender_domain) do
      :ok ->
        :ok

      {:error, %Mailglass.RateLimitError{} = err} ->
        bucket = bucket_type(err)
        retry_after_s = max(1, ceil(err.retry_after_ms / 1000))

        # PII-free stop meta: bucket TYPE + limit + retry_after only — never the
        # recipient/sender VALUE.
        meta = %{
          provider: provider,
          tenant_id: tenant_id,
          status: :rate_limited,
          bucket: bucket,
          limit: err.context[:limit],
          retry_after: retry_after_s
        }

        # Emit the rate_limit span from the single-span surface (never inline).
        # The inner fn returns {resp, meta} so :telemetry.span stamps the
        # classified PII-free stop meta; the span itself returns `resp`.
        resp =
          MailglassInbound.Telemetry.rate_limit(meta, fn ->
            resp =
              conn
              |> put_resp_header("retry-after", Integer.to_string(retry_after_s))
              |> send_json(429, %{status: "rate_limited", bucket: Atom.to_string(bucket)})

            {resp, meta}
          end)

        {:rate_limited, resp, meta}
    end
  end

  # Map the RateLimitError back to the inbound bucket type for the 429 body +
  # telemetry. The limiter stamps the bucket TYPE into err.context[:bucket]
  # (PII-free); fall back to the closed @types if absent.
  defp bucket_type(%Mailglass.RateLimitError{context: %{bucket: bucket}})
       when bucket in [:tenant, :recipient, :sender_domain],
       do: bucket

  defp bucket_type(%Mailglass.RateLimitError{type: :per_tenant}), do: :tenant
  defp bucket_type(%Mailglass.RateLimitError{}), do: :recipient

  # Recipient bucket key: envelope recipient, else first `to` address. May be the
  # full address (routing identity, node-local ETS, never logged).
  defp rate_limit_recipient(%{envelope_recipient: r}) when is_binary(r) and r != "", do: r

  defp rate_limit_recipient(%{to: [%{address: addr} | _]}) when is_binary(addr), do: addr
  defp rate_limit_recipient(_message), do: nil

  # Sender bucket key: the domain of the first `from` address, never the full
  # sender address.
  defp rate_limit_sender_domain(%{from: [%{address: addr} | _]}) when is_binary(addr) do
    case String.split(addr, "@", parts: 2) do
      [_local, domain] -> String.downcase(domain)
      _ -> nil
    end
  end

  defp rate_limit_sender_domain(_message), do: nil

  # The persisting tail, extracted so the rate-limit short-circuit can return
  # before persist without duplicating the persist + dispatch + egress logic.
  defp persist_and_dispatch(conn, provider, request, tenant_id, normalized, verification_facts, opts) do
    handoff = build_handoff(normalized, provider, tenant_id, verification_facts)

    persistence = Keyword.get(opts, :persistence, MailglassInbound.Ingress.Persist)
    execution = Keyword.get(opts, :execution, Execution)

    case persistence.persist(handoff, persistence_opts(opts)) do
      {:ok, result} ->
        maybe_execute(execution, result)

        resp =
          send_json(conn, 200, %{
            status: Atom.to_string(result.status),
            route: route_status(result.route)
          })

        {resp,
         %{
           provider: provider,
           tenant_id: tenant_id,
           status: result.status,
           byte_size: request_byte_size(request)
         }}

      {:error, reason} ->
        # PII-safe egress (TELE-06). `reason` is the `{:error, term}` from
        # Persist.persist/2 — typically an `%Ecto.Changeset{}` whose `changes`
        # carry recipient PII (subject/from/to/cc/bcc/reply_to/text_body/
        # html_body). NEVER interpolate it into the response body: that would
        # leak recipient email contents to the provider on a transient DB
        # failure. Mirror the core webhook plug's static-500 posture
        # (lib/mailglass/webhook/plug.ex returns `send_resp(conn, 500, "")` on
        # its config-error branch) — the JSON-shaped equivalent is a static
        # closed code. Status stays 500: it is the correct retry signal for all
        # four providers (Postmark/Mailgun/SES retry non-2xx; SendGrid Inbound
        # Parse DROPS 4xx with no retry, so downgrading would permanently lose
        # the email on a transient error). A DB error is operational, not an
        # Anymail rejection.
        log_persist_failure(reason)
        resp = send_json(conn, 500, %{status: "error", reason: "persist_failed"})

        # Adopter DX detail rides the telemetry stop-meta as a PII-free
        # classified atom — NOT the response body, and NOT the raw `reason`.
        # This is an `{:error, _}` tuple (not a raise), so `:stop` enrichment is
        # the right channel; the full-fidelity record already lives in the
        # committed tenant-scoped `InboundEvidence` row.
        {resp,
         %{
           provider: provider,
           tenant_id: tenant_id,
           status: :error,
           error_kind: classify_persist_error(reason),
           byte_size: request_byte_size(request)
         }}
    end
  end

  # Map a persist failure term to a PII-free atom for the telemetry stop-meta.
  # `%Ecto.Changeset{}` carries recipient PII in `.changes`, so we collapse it to
  # a closed code rather than echoing it. Already-safe atom codes pass through.
  defp classify_persist_error(%Ecto.Changeset{}), do: :changeset_invalid
  defp classify_persist_error(:not_found), do: :not_found
  defp classify_persist_error(reason) when is_atom(reason), do: reason
  defp classify_persist_error(_reason), do: :unknown

  # Optional scrubbed adopter-DX log. Logs ONLY changeset field names + their
  # validation messages via `Ecto.Changeset.traverse_errors/2` — NEVER the
  # `changes` values (which carry recipient PII). No `inspect` of the changeset,
  # no body/recipient interpolation, so this stays below the NoFullResponseInLogs
  # / NoPiiInResponseBody bar. The durable record is the committed
  # `InboundEvidence` row; this is debuggability only.
  defp log_persist_failure(%Ecto.Changeset{} = changeset) do
    require Logger

    field_errors =
      changeset
      |> Ecto.Changeset.traverse_errors(fn {msg, _opts} -> msg end)
      |> Map.keys()
      |> Enum.sort()
      |> Enum.join(",")

    Logger.error("[mailglass_inbound] inbound persist failed: changeset_invalid fields=#{field_errors}")
    :ok
  end

  defp log_persist_failure(reason) do
    require Logger

    Logger.error("[mailglass_inbound] inbound persist failed: #{classify_persist_error(reason)}")
    :ok
  end

  defp request_byte_size(%Request{raw_body: raw_body}) when is_binary(raw_body),
    do: byte_size(raw_body)

  defp request_byte_size(%Request{raw_mime: raw_mime}) when is_binary(raw_mime),
    do: byte_size(raw_mime)

  defp request_byte_size(_request), do: 0

  defp build_request!(:postmark, conn) do
    raw_body = extract_raw_body!(conn)

    %Request{
      provider: :postmark,
      raw_body: raw_body,
      headers: conn.req_headers,
      params: conn.params,
      content_type: List.first(get_req_header(conn, "content-type"))
    }
  end

  defp build_request!(:sendgrid, conn) do
    params = conn.params || %{}

    %Request{
      provider: :sendgrid,
      raw_body: conn.private[:raw_body],
      headers: conn.req_headers,
      params: params,
      raw_mime: params["email"],
      content_type: List.first(get_req_header(conn, "content-type"))
    }
  end

  # Mailgun inbound routes POST form fields (urlencoded, or multipart when
  # attachments are present); the HMAC triple + payload arrive as top-level form
  # fields in `conn.params`. Raw-body capture mirrors SendGrid.
  defp build_request!(:mailgun, conn) do
    %Request{
      provider: :mailgun,
      raw_body: conn.private[:raw_body],
      headers: conn.req_headers,
      params: conn.params || %{},
      content_type: List.first(get_req_header(conn, "content-type"))
    }
  end

  # SES delivers the SNS JSON envelope as the request body; raw-body capture
  # mirrors SendGrid. The SNS payload itself is parsed by the provider's verify
  # seam.
  defp build_request!(:ses, conn) do
    %Request{
      provider: :ses,
      raw_body: conn.private[:raw_body],
      headers: conn.req_headers,
      params: conn.params || %{},
      content_type: List.first(get_req_header(conn, "content-type"))
    }
  end

  defp extract_raw_body!(conn) do
    case conn.private[:raw_body] do
      raw when is_binary(raw) -> raw

      _ ->
        raise ConfigError.new(:webhook_caching_body_reader_missing,
                context: %{
                  hint:
                    "configure Plug.Parsers with body_reader: {MailglassInbound.Ingress.CachingBodyReader, :read_body, []}"
                }
              )
    end
  end

  defp resolve_config!(:postmark, conn, opts) do
    config =
      case Keyword.get(opts, :config) do
        nil -> Application.get_env(:mailglass_inbound, :postmark, [])
        value -> value
      end

    %{
      basic_auth: config[:basic_auth],
      ip_allowlist: config[:ip_allowlist] || [],
      remote_ip: conn.remote_ip
    }
  end

  defp resolve_config!(:sendgrid, _conn, opts) do
    config =
      case Keyword.get(opts, :config) do
        nil -> Application.get_env(:mailglass_inbound, :sendgrid, [])
        value -> value
      end

    %{basic_auth: config[:basic_auth]}
  end

  # Mailgun config surfaces the HMAC signing key. The opts `:config`
  # override wins, else app env. Provider verify! raises ConfigError when absent.
  defp resolve_config!(:mailgun, _conn, opts) do
    config =
      case Keyword.get(opts, :config) do
        nil -> Application.get_env(:mailglass_inbound, :mailgun, [])
        value -> value
      end

    %{signing_key: config[:signing_key]}
  end

  # SES config surfaces the S3Fetcher module seam and an optional cert-cache TTL.
  # The opts `:config` override wins, else app env.
  defp resolve_config!(:ses, _conn, opts) do
    config =
      case Keyword.get(opts, :config) do
        nil -> Application.get_env(:mailglass_inbound, :ses, [])
        value -> value
      end

    %{
      s3_fetcher: config[:s3_fetcher],
      cert_cache_ttl_seconds: config[:cert_cache_ttl_seconds],
      # WR-04: thread the documented retry tuning knob into the config map.
      # `fetch_s3_body!` reads `Map.get(config, :s3_retry_opts, [])`, but this
      # resolver previously never copied it from app env / opts — so the real
      # plug path always used the hardcoded default (3 attempts, [250,1000,2000]
      # backoff) and adopter-configured retry opts were silently ignored.
      s3_retry_opts: config[:s3_retry_opts] || []
    }
  end

  defp verify_request!(:postmark, request, config, opts) do
    resolve_provider_module(:postmark, opts).verify!(request.raw_body, request.headers, config)
  end

  defp verify_request!(:sendgrid, request, config, opts) do
    resolve_provider_module(:sendgrid, opts).verify!(request, config)
  end

  # Mailgun/SES use the widened struct arity verify!(%Request{}, config) and may
  # return {:ok, facts} | {:replay} | {:control_plane, status}.
  defp verify_request!(:mailgun, request, config, opts) do
    resolve_provider_module(:mailgun, opts).verify!(request, config)
  end

  defp verify_request!(:ses, request, config, opts) do
    resolve_provider_module(:ses, opts).verify!(request, config)
  end

  defp normalize_request!(:postmark, request, opts) do
    resolve_provider_module(:postmark, opts).normalize(request.raw_body, request.headers)
  end

  defp normalize_request!(:sendgrid, request, opts) do
    resolve_provider_module(:sendgrid, opts).normalize(request)
  end

  defp normalize_request!(:mailgun, request, opts) do
    resolve_provider_module(:mailgun, opts).normalize(request)
  end

  defp normalize_request!(:ses, request, opts) do
    resolve_provider_module(:ses, opts).normalize(request)
  end

  # Test seam: an opts `:provider_module` override lets tests inject a stub
  # provider to exercise the widened verify-result branches (replay /
  # control-plane / persist) without the real Mailgun/SES providers (which land
  # in Plans 02/03). In production, opts carries no `:provider_module`, so this
  # falls back to the hardcoded `provider_module/1` dispatch.
  defp resolve_provider_module(provider, opts) do
    case Keyword.get(opts, :provider_module) do
      mod when is_atom(mod) and not is_nil(mod) -> mod
      _ -> provider_module(provider)
    end
  end

  defp resolve_tenant!(provider, conn, request) do
    ctx = %{
      provider: provider,
      conn: conn,
      raw_body: request.raw_body,
      headers: request.headers,
      path_params: conn.path_params,
      verified_payload: nil
    }

    case Tenancy.resolve_webhook_tenant(ctx) do
      {:ok, tenant_id} when is_binary(tenant_id) ->
        tenant_id

      {:error, reason} ->
        raise TenancyError.new(:webhook_tenant_unresolved,
                context: %{provider: provider, reason: reason}
              )
    end
  end

  defp build_handoff(normalized, provider, tenant_id, verification_facts) do
    message =
      normalized.message
      |> Map.put(:tenant_id, tenant_id)
      |> Map.put(:provider, provider)

    evidence =
      normalized.evidence
      |> Map.update(:verification_facts, verification_facts, &Map.merge(&1, verification_facts))

    %{
      tenant_id: tenant_id,
      provider: provider,
      message: message,
      evidence: evidence
    }
  end

  defp persistence_opts(opts) do
    []
    |> maybe_put(:router, Keyword.get(opts, :router))
    |> maybe_put(:routes, Keyword.get(opts, :routes))
    |> maybe_put(:repo, Keyword.get(opts, :repo))
  end

  defp maybe_put(opts, _key, nil), do: opts
  defp maybe_put(opts, key, value), do: Keyword.put(opts, key, value)

  defp route_status(%{status: status}) when is_atom(status), do: Atom.to_string(status)
  defp route_status(_), do: "unknown"

  defp maybe_execute(_execution, %{status: :duplicate}), do: :ok

  defp maybe_execute(execution, %{status: :inserted} = result) do
    _ = execution.dispatch(result)
    _ = broadcast_inbound_inserted(result)
    :ok
  end

  # Post-commit fan-out. This runs in `maybe_execute/2`, which
  # the plug only reaches AFTER `persistence.persist/2` returns — i.e. AFTER the
  # `repo.transact` inside `Persist.persist/2` has committed. The broadcast NEVER
  # runs on a rolled-back transaction: the persisted `InboundRecord` is the
  # durable source of truth, PubSub is the realtime fan-out. Only the `:inserted`
  # branch broadcasts; `:duplicate` stays a no-op.
  #
  # The topic comes from `MailglassInbound.PubSub.Topics.inbound_record_inserted/1`
  # (never a literal string); the payload is PII-free
  # (record id + provider + record_type only).
  defp broadcast_inbound_inserted(%{
         inbound_record: %{id: record_id, tenant_id: tenant_id},
         message: %{provider: provider}
       })
       when is_binary(tenant_id) do
    topic = MailglassInbound.PubSub.Topics.inbound_record_inserted(tenant_id)
    payload = {:inbound_record_inserted, record_id, %{provider: provider, record_type: "inbound_record"}}

    safe_broadcast(topic, payload)
  end

  defp broadcast_inbound_inserted(_result), do: :ok

  # Copied verbatim from `Mailglass.Outbound.Projector.safe_broadcast/2`, changing
  # only the log tag to `[mailglass_inbound]`. The rescue list and the
  # `catch :exit` clause are both load-bearing: PubSub may be unreachable at
  # shutdown/partition, and the committed row is the durable source of truth, so a
  # broadcast failure must never crash the already-committed inbound pipeline.
  defp safe_broadcast(topic, payload) do
    Phoenix.PubSub.broadcast(Mailglass.PubSub, topic, payload)
  rescue
    e in [ArgumentError, RuntimeError] ->
      require Logger

      Logger.debug("[mailglass_inbound] PubSub broadcast failed (non-fatal): #{Exception.message(e)}")

      :ok
  catch
    :exit, reason ->
      require Logger

      Logger.debug("[mailglass_inbound] PubSub broadcast exited (non-fatal): #{inspect(reason)}")

      :ok
  end

  defp send_json(conn, status, payload) do
    body = Jason.encode!(payload)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, body)
  end

  defp provider_module(:postmark), do: MailglassInbound.Ingress.Providers.Postmark
  defp provider_module(:sendgrid), do: MailglassInbound.Ingress.Providers.Sendgrid
  # Mailgun/SES providers land in Plans 02/03 (referenced by name; the plug only
  # resolves them when a :mailgun/:ses request is actually dispatched).
  defp provider_module(:mailgun), do: MailglassInbound.Ingress.Providers.Mailgun
  defp provider_module(:ses), do: MailglassInbound.Ingress.Providers.SES
end
