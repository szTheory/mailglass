defmodule MailglassInbound.Ingress.Plug do
  @moduledoc """
  Public inbound ingress plug for `mailglass_inbound`.

  The plug verifies provider requests first, resolves tenant scope second, then
  normalizes and persists the canonical inbound message without executing any mailbox.

  ## Telemetry + post-commit broadcast

  The whole request is wrapped in a `[:mailglass_inbound, :ingress, :request, *]`
  span via `MailglassInbound.Telemetry` (TELE-01).

  After `Persist.persist/2` returns `{:ok, %{status: :inserted}}` — i.e. AFTER the
  `repo.transact` inside `Persist.persist/2` has committed — the plug broadcasts a
  PII-free `{:inbound_record_inserted, record_id, %{provider:, record_type:}}`
  message on `Mailglass.PubSub` to the per-tenant topic from
  `MailglassInbound.PubSub.Topics.inbound_record_inserted/1` (TELE-07, D-45-06,
  D-45-07). The broadcast runs OUTSIDE the transaction and never rolls it back:
  the committed `InboundRecord` is the durable source of truth, PubSub is the
  realtime fan-out for the Phase 48 admin LiveView. A `:duplicate` result
  broadcasts nothing.
  """

  @behaviour Plug

  import Plug.Conn

  alias Mailglass.{ConfigError, SignatureError, Tenancy, TenancyError}
  alias MailglassInbound.Execution
  alias MailglassInbound.Ingress.Request

  @impl Plug
  def init(opts) when is_list(opts) do
    provider = Keyword.get(opts, :provider, :postmark)

    unless provider in [:postmark, :sendgrid] do
      raise ArgumentError,
            "MailglassInbound.Ingress.Plug currently supports provider: :postmark or :sendgrid only"
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
      verification_facts = verify_request!(provider, request, config)
      tenant_id = resolve_tenant!(provider, conn, request)
      normalized = normalize_request!(provider, request)
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
    rescue
      e in SignatureError ->
        resp = send_json(conn, 401, %{status: "rejected", reason: Atom.to_string(e.type)})
        {resp, %{provider: provider, status: :rejected}}

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

  defp verify_request!(:postmark, request, config) do
    provider_module(:postmark).verify!(request.raw_body, request.headers, config)
  end

  defp verify_request!(:sendgrid, request, config) do
    provider_module(:sendgrid).verify!(request, config)
  end

  defp normalize_request!(:postmark, request) do
    provider_module(:postmark).normalize(request.raw_body, request.headers)
  end

  defp normalize_request!(:sendgrid, request) do
    provider_module(:sendgrid).normalize(request)
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

  # Post-commit fan-out (TELE-07, D-45-06). This runs in `maybe_execute/2`, which
  # the plug only reaches AFTER `persistence.persist/2` returns — i.e. AFTER the
  # `repo.transact` inside `Persist.persist/2` has committed. The broadcast NEVER
  # runs on a rolled-back transaction: the persisted `InboundRecord` is the
  # durable source of truth, PubSub is the realtime fan-out. Only the `:inserted`
  # branch broadcasts; `:duplicate` stays a no-op.
  #
  # The topic comes from `MailglassInbound.PubSub.Topics.inbound_record_inserted/1`
  # (never a literal string — LINT-06 / D-45-08); the payload is PII-free
  # (record id + provider + record_type only — D-45-03).
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
  # broadcast failure must never crash the already-committed inbound pipeline
  # (D-45-06, threat T-45-08).
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
end
