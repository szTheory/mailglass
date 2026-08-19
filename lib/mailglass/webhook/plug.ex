defmodule Mailglass.Webhook.Plug do
  @moduledoc """
  Single-ingress webhook orchestrator.

  Plugged at adopter-mounted paths via `Mailglass.Webhook.Router`.
  Owns the full request lifecycle:

    1. Extract `raw_body` from `conn.private[:raw_body]` (populated by
       `Mailglass.Webhook.CachingBodyReader` in the adopter's
       `Plug.Parsers` `:body_reader`)
    2. Dispatch to `Mailglass.Webhook.Provider` impl per route opts
       (`provider: :postmark | :sendgrid | :mailgun`)
    3. `Provider.verify!/3` — raises `%SignatureError{}` on failure
    4. `Mailglass.Tenancy.resolve_webhook_tenant/1` — runs after verify
    5. `Mailglass.Tenancy.with_tenant/2` BLOCK form — clean tenant
       cleanup on raise (Pitfall 7)
    6. `Provider.normalize/2` — pure, returns `[%Event{}]`
    7. `Mailglass.Webhook.Ingest.ingest_multi/3` — single Ecto.Multi
       inside `Repo.transact/1`
    8. Post-commit: `Mailglass.Outbound.Projector.broadcast_delivery_updated/3`
       per matched delivery (`events_with_deliveries` 3-tuples)
    9. `send_resp(conn, 200, "")`

  ## Response code matrix

  | Outcome | Status | Notes |
  |---------|--------|-------|
  | Success | 200 | Normal happy path |
  | Duplicate replay (UNIQUE collision) | 200 | Idempotent — provider sees no error |
  | %SignatureError{} (any of 7+ atoms) | 401 | Logger.warning with provider + atom |
  | %TenancyError{:webhook_tenant_unresolved} | 422 | Distinct from signature failure |
  | %ConfigError{:webhook_caching_body_reader_missing} | 500 | Adopter wiring gap |
  | %ConfigError{:webhook_verification_key_missing} | 500 | Missing provider secret |
  | Ingest {:error, reason} | 500 | Logger.error with reason atom only |

  ## Telemetry

  Emits `[:mailglass, :webhook, :ingest, :start | :stop | :exception]`
  around the entire call/2 body via
  `Mailglass.Webhook.Telemetry.ingest_span/2`. Stop metadata
  is intentionally whitelisted:
  `%{provider, tenant_id, status, event_count, duplicate, failure_reason}`
  — never IP, headers, or payload bytes.

  Also emits `[:mailglass, :webhook, :signature, :verify, :start | :stop |
  :exception]` around `Provider.verify!/3` via
  `Mailglass.Webhook.Telemetry.verify_span/2`.

  ## Failure log discipline

  `Logger.warning` on signature failure includes `provider` + atom
  `reason` only. Never the source IP, headers, or payload excerpts.
  Adopters wanting IP-based abuse triage attach their own telemetry
  handler on `[:mailglass, :webhook, :signature, :verify, :stop]`
  with `status: :failed` and pull `conn.remote_ip` from their own
  plug lineage.

  ## Forward-declared contracts

  `Mailglass.Webhook.Ingest.ingest_multi/3` is referenced directly; the
  `@compile {:no_warn_undefined, ...}` attribute below suppresses
  compile warnings until the module is available.
  """

  @behaviour Plug

  import Plug.Conn

  require Logger

  alias Mailglass.{ConfigError, TenancyError}
  alias Mailglass.Outbound.Projector
  alias Mailglass.Tenancy
  alias Mailglass.Webhook.Telemetry, as: WebhookTelemetry
  alias Mailglass.Webhook.Pipeline
  alias Mailglass.Webhook.VerifiedRequest

  # Forward reference to the ingest module. Referenced at runtime and
  # silenced at compile time so `--warnings-as-errors` stays green
  # before the module exists.
  @compile {:no_warn_undefined, [Mailglass.Webhook.Ingest]}

  @valid_providers [:postmark, :sendgrid, :mailgun, :ses, :resend]

  @impl Plug
  def init(opts) when is_list(opts) do
    provider = Keyword.fetch!(opts, :provider)

    unless provider in @valid_providers do
      raise ArgumentError,
            "Mailglass.Webhook.Plug: unknown :provider #{inspect(provider)} " <>
              "(valid: #{inspect(@valid_providers)})"
    end

    Keyword.put(opts, :provider, provider)
  end

  @impl Plug
  def call(conn, opts) do
    provider = Keyword.fetch!(opts, :provider)

    # `do_call/3` returns `{conn, stop_metadata}` and `ingest_span/2`
    # attaches that metadata to the `:stop` event. The first tuple
    # element (conn) is returned to `Plug.call/2`.
    WebhookTelemetry.ingest_span(
      %{provider: provider, status: :pending},
      fn -> do_call(conn, provider, opts) end
    )
  end

  # ---- Internal — Plug call body ----
  #
  # Returns `{%Plug.Conn{}, stop_metadata}`. The `:telemetry.span/3` wrapper
  # in `call/2` extracts the conn as the `result` and attaches the
  # stop_metadata to the `:stop` event.

  defp do_call(conn, provider, opts) do
    try do
      {raw_body, headers} = extract_headers_and_raw_body!(conn)
      config = resolve_config!(provider, conn)

      # Decode the untrusted outer JSON exactly once. Raw bytes remain the
      # authoritative signature/evidence input; the decoded value is reused
      # only after (or as part of) provider verification.
      request = VerifiedRequest.decode(raw_body, Keyword.get(opts, :json_decoder, &Jason.decode/1))

      outcome =
        Pipeline.run(provider, request, headers, %{
          verify: fn pipeline_provider, pipeline_request, pipeline_headers ->
            verify_with_telemetry!(pipeline_provider, pipeline_request, pipeline_headers, config)
          end,
          resolve_tenant: fn pipeline_provider, pipeline_request, pipeline_headers ->
            resolve_tenant!(pipeline_provider, conn, pipeline_request, pipeline_headers)
          end,
          with_tenant: &Tenancy.with_tenant/2,
          normalize: fn pipeline_provider, pipeline_request, pipeline_headers ->
            normalize_decoded(pipeline_provider, pipeline_request.decoded, pipeline_headers)
          end,
          ingest: fn pipeline_provider, pipeline_request, events ->
            Mailglass.Webhook.Ingest.ingest_multi(
              pipeline_provider,
              pipeline_request.raw_body,
              pipeline_request.decoded,
              events
            )
          end,
          broadcast: &broadcast_post_commit/1
        })

      render_outcome(conn, provider, outcome)
    rescue
      e in ConfigError ->
        render_outcome(conn, provider, {:config_error, e.type})
    end
  end

  defp render_outcome(conn, provider, {:replay}) do
    {send_resp(conn, 200, ""),
     %{provider: provider, status: :replay, duplicate: true, event_count: 0}}
  end

  defp render_outcome(conn, provider, {:control_plane, outcome}) do
    Logger.info("[mailglass] SNS control-plane: provider=#{provider} outcome=#{outcome}")
    {send_resp(conn, 200, ""), %{provider: provider, status: :control_plane, outcome: outcome}}
  end

  defp render_outcome(conn, provider, {:ingested, tenant_id, event_count, duplicate}) do
    status = if duplicate, do: :duplicate, else: :ok

    {send_resp(conn, 200, ""),
     %{
       provider: provider,
       tenant_id: tenant_id,
       status: status,
       event_count: event_count,
       duplicate: duplicate
     }}
  end

  defp render_outcome(conn, provider, {:ingest_failed, tenant_id, event_count}) do
    Logger.error("[mailglass] Webhook ingest failed: provider=#{provider}")

    {send_resp(conn, 500, ""),
     %{provider: provider, tenant_id: tenant_id, status: :ingest_failed, event_count: event_count}}
  end

  defp render_outcome(conn, provider, {:signature_failed, type}) do
    Logger.warning("Webhook signature failed: provider=#{provider} reason=#{type}")

    {send_resp(conn, 401, ""),
     %{provider: provider, status: :signature_failed, failure_reason: type}}
  end

  defp render_outcome(conn, provider, {:tenant_unresolved, type}) do
    Logger.warning("Webhook tenant resolution failed: provider=#{provider} reason=#{type}")

    {send_resp(conn, 422, ""),
     %{provider: provider, status: :tenant_unresolved, failure_reason: type}}
  end

  defp render_outcome(conn, provider, {:config_error, type}) do
    Logger.error("[mailglass] Webhook config error: provider=#{provider} reason=#{type}")
    {send_resp(conn, 500, ""), %{provider: provider, status: :config_error, failure_reason: type}}
  end

  # Step 1a: extract raw bytes + headers; fail fast if CachingBodyReader
  # is not wired. Raises ConfigError with :webhook_caching_body_reader_missing,
  # which is distinct from
  # :webhook_verification_key_missing which is used when the provider's
  # signing key secret is missing from Application env. Distinct atoms so
  # adopter Logger parsing / Grafana alerts can differentiate "setup gap"
  # from "missing secret".
  defp extract_headers_and_raw_body!(conn) do
    case conn.private[:raw_body] do
      binary when is_binary(binary) ->
        {binary, conn.req_headers}

      nil ->
        raise ConfigError.new(:webhook_caching_body_reader_missing,
                context: %{
                  hint:
                    "conn.private[:raw_body] is missing — configure Plug.Parsers " <>
                      "with body_reader: {Mailglass.Webhook.CachingBodyReader, :read_body, []} " <>
                      "in your endpoint.ex"
                }
              )
    end
  end

  # Step 1b: resolve per-tenant config (Application env at v0.1; v0.5 may
  # add per-route MFA).
  defp resolve_config!(:postmark, conn) do
    env = Mailglass.Config.webhook_provider(:postmark)

    %{
      basic_auth: env[:basic_auth],
      ip_allowlist: env[:ip_allowlist] || [],
      remote_ip: conn.remote_ip
    }
  end

  defp resolve_config!(:sendgrid, _conn) do
    env = Mailglass.Config.webhook_provider(:sendgrid)

    %{
      public_key: env[:public_key],
      timestamp_tolerance_seconds: env[:timestamp_tolerance_seconds] || 300
    }
  end

  defp resolve_config!(:mailgun, _conn) do
    env = Mailglass.Config.webhook_provider(:mailgun)

    %{
      signing_key: env[:signing_key],
      timestamp_tolerance_seconds: env[:timestamp_tolerance_seconds] || 28_800,
      future_skew_seconds: env[:future_skew_seconds] || 300,
      replay_cache_ttl_seconds: env[:replay_cache_ttl_seconds] || 28_800
    }
  end

  defp resolve_config!(:ses, _conn) do
    env = Mailglass.Config.webhook_provider(:ses)

    %{
      cert_cache_ttl_seconds: env[:cert_cache_ttl_seconds] || 86_400
    }
  end

  defp resolve_config!(:resend, _conn) do
    env = Mailglass.Config.webhook_provider(:resend)

    %{
      secret: env[:secret],
      timestamp_tolerance_seconds: env[:timestamp_tolerance_seconds] || 300
    }
  end

  # Step 2: telemetry-wrapped Provider.verify!/3 inner span.
  # On success the inner function returns `:ok`; on
  # signature failure the `verify!/3` call raises %SignatureError{} which
  # :telemetry.span/3 (inside `verify_span/2`) reports via the :exception
  # event and re-raises — the outer SignatureError rescue in do_call/3
  # catches it and classifies the 401 response.
  defp verify_with_telemetry!(provider, %VerifiedRequest{} = request, headers, config) do
    WebhookTelemetry.verify_span(
      %{provider: provider, status: :pending},
      fn ->
        verify_decoded!(provider, request, headers, config)
      end
    )
  end

  # Step 3: tenant resolution via Mailglass.Tenancy.resolve_webhook_tenant/1.
  defp resolve_tenant!(provider, conn, %VerifiedRequest{} = request, headers) do
    ctx = %{
      provider: provider,
      conn: conn,
      raw_body: request.raw_body,
      headers: headers,
      path_params: conn.path_params,
      # Preserve the adopter-facing v0.1 contract: existing resolvers may
      # legitimately pattern-match this reserved field as nil. The decoded
      # value has its own additive key so parse-once consumers do not break
      # those callbacks.
      verified_payload: nil,
      decoded_payload: VerifiedRequest.payload_or_nil(request)
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

  # Post-commit broadcast — runs after Repo.transact returns {:ok, _}.
  # `events_with_deliveries` is a list of 3-tuples:
  # `{inserted_event, delivery_or_nil, orphan?}`. Orphans are skipped here
  # (delivery is nil, so there is nothing to broadcast against). The
  # reconciler later emits a :reconciled event when the matching delivery
  # is committed.
  defp broadcast_post_commit(%{events_with_deliveries: events_with_deliveries})
       when is_list(events_with_deliveries) do
    Enum.each(events_with_deliveries, fn
      {_event, nil, true} ->
        :ok

      {event, delivery, false} ->
        # In Events.append_multi/3, a nil inserted_at signals a
        # conflict-replay (the row already exists). Skip broadcast so
        # LiveView/TestAssertions don't see duplicate signals for the same
        # webhook delivery.
        if is_nil(event.inserted_at) do
          :ok
        else
          Projector.broadcast_delivery_updated(delivery, event.type, %{
            event_id: event.id,
            provider: event.metadata["provider"]
          })
        end
    end)
  end

  defp broadcast_post_commit(_), do: :ok

  # Static dispatch — init/1 validates that provider is in @valid_providers
  # at mount time, so these clauses are exhaustive for all reachable calls.
  defp provider_module(:postmark), do: Mailglass.Webhook.Providers.Postmark
  defp provider_module(:sendgrid), do: Mailglass.Webhook.Providers.SendGrid
  defp provider_module(:mailgun), do: Mailglass.Webhook.Providers.Mailgun
  defp provider_module(:ses), do: Mailglass.Webhook.Providers.SES
  defp provider_module(:resend), do: Mailglass.Webhook.Providers.Resend

  defp verify_decoded!(:mailgun, %VerifiedRequest{decoded: decoded}, headers, config),
    do: Mailglass.Webhook.Providers.Mailgun.verify_decoded!(decoded, headers, config)

  defp verify_decoded!(:ses, %VerifiedRequest{decoded: decoded}, headers, config),
    do: Mailglass.Webhook.Providers.SES.verify_decoded!(decoded, headers, config)

  defp verify_decoded!(provider, %VerifiedRequest{raw_body: raw_body}, headers, config) do
    provider
    |> provider_module()
    |> apply(:verify!, [raw_body, headers, config])
  end

  defp normalize_decoded(provider, decoded, headers) do
    provider
    |> provider_module()
    |> apply(:normalize_decoded, [decoded, headers])
  end
end
