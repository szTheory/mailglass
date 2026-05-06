defmodule MailglassInbound.Ingress.Plug do
  @moduledoc """
  Public inbound ingress plug for `mailglass_inbound`.

  The plug verifies provider requests first, resolves tenant scope second, then
  normalizes and persists the canonical inbound message without executing any mailbox.
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

          send_json(conn, 200, %{
            status: Atom.to_string(result.status),
            route: route_status(result.route)
          })

        {:error, reason} ->
          send_json(conn, 500, %{status: "error", reason: inspect(reason)})
      end
    rescue
      e in SignatureError ->
        send_json(conn, 401, %{status: "rejected", reason: Atom.to_string(e.type)})

      e in TenancyError ->
        send_json(conn, 422, %{status: "tenant_unresolved", reason: Atom.to_string(e.type)})

      e in ConfigError ->
        send_json(conn, 500, %{
          status: "config_error",
          reason: Atom.to_string(e.type),
          message: Exception.message(e)
        })
    end
  end

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
