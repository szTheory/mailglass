defmodule Mailglass.Webhook.Plug do
  @moduledoc """
  Single-ingress webhook orchestrator (CONTEXT D-10).

  Plugged at adopter-mounted paths via `Mailglass.Webhook.Router`
  (Plan 05). Owns the full request lifecycle:

    1. Extract `raw_body` from `conn.private[:raw_body]` (populated by
       `Mailglass.Webhook.CachingBodyReader` in the adopter's
       `Plug.Parsers` `:body_reader`)
    2. Dispatch to `Mailglass.Webhook.Provider` impl per route opts
       (`provider: :postmark | :sendgrid`)
    3. `Provider.verify!/3` — raises `%SignatureError{}` on failure
    4. `Mailglass.Tenancy.resolve_webhook_tenant/1` (D-12) — runs
       AFTER verify (D-13)
    5. `Mailglass.Tenancy.with_tenant/2` BLOCK form — clean tenant
       cleanup on raise (Pitfall 7)
    6. `Provider.normalize/2` — pure, returns `[%Event{}]`
    7. `Mailglass.Webhook.Ingest.ingest_multi/3` — single Ecto.Multi
       inside `Repo.transact/1` (Plan 06, forward-declared)
    8. Post-commit: `Mailglass.Outbound.Projector.broadcast_delivery_updated/3`
       per matched delivery (Phase 3 D-04 — Plan 06 returns the
       `events_with_deliveries` 3-tuples for this loop)
    9. `send_resp(conn, 200, "")`

  ## Response code matrix (CONTEXT D-10 + D-14 + D-21)

  | Outcome | Status | Notes |
  |---------|--------|-------|
  | Success | 200 | Normal happy path |
  | Duplicate replay (UNIQUE collision) | 200 | Idempotent — provider sees no error |
  | %SignatureError{} (any of 7+ atoms) | 401 | Logger.warning with provider + atom |
  | %TenancyError{:webhook_tenant_unresolved} | 422 | Distinct from signature failure |
  | %ConfigError{:webhook_caching_body_reader_missing} | 500 | Adopter wiring gap |
  | %ConfigError{:webhook_verification_key_missing} | 500 | Missing provider secret |
  | Ingest {:error, reason} | 500 | Logger.error with reason atom only |

  ## Telemetry (CONTEXT D-22 — Plan 08 ships full helpers)

  Emits `[:mailglass, :webhook, :ingest, :start | :stop | :exception]`
  around the entire call/2 body. Stop metadata follows D-23 whitelist:
  `%{provider, tenant_id, status, event_count, duplicate, failure_reason}`
  — never IP, headers, or payload bytes.

  Also emits `[:mailglass, :webhook, :signature, :verify, :start | :stop |
  :exception]` around `Provider.verify!/3`.

  ## Failure log discipline (CONTEXT D-24)

  `Logger.warning` on signature failure includes `provider` + atom
  `reason` only. Never the source IP, headers, or payload excerpts.
  Adopters wanting IP-based abuse triage attach their own telemetry
  handler on `[:mailglass, :webhook, :signature, :verify, :stop]`
  with `status: :failed` and pull `conn.remote_ip` from their own
  plug lineage.

  ## Forward-declared contracts

  `Mailglass.Webhook.Ingest.ingest_multi/3` is shipped by Plan 06
  (Wave 3). This module references it directly; the `@compile
  {:no_warn_undefined, ...}` attribute below suppresses the warning
  during `mix compile --warnings-as-errors` until Plan 06 lands.
  """

  @behaviour Plug

  import Plug.Conn

  require Logger

  alias Mailglass.{ConfigError, SignatureError, TenancyError}
  alias Mailglass.Outbound.Projector
  alias Mailglass.Tenancy

  # Forward-reference to Plan 06's Ingest Multi. Referenced at runtime;
  # silenced at compile time so `--warnings-as-errors` stays green before
  # Plan 06 ships the module.
  @compile {:no_warn_undefined, [Mailglass.Webhook.Ingest]}

  @valid_providers [:postmark, :sendgrid]

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

    Mailglass.Telemetry.span(
      [:mailglass, :webhook, :ingest],
      %{provider: provider, status: :pending},
      fn -> do_call(conn, provider, opts) end
    )
  end

  # ---- Internal — Plug call body ----

  defp do_call(conn, provider, _opts) do
    try do
      {raw_body, headers} = extract_headers_and_raw_body!(conn)
      config = resolve_config!(provider, conn)

      # Step 1: verify FIRST (D-13)
      verify_with_telemetry!(provider, raw_body, headers, config)

      # Step 2: resolve tenant (D-12 — runs AFTER verify per D-13)
      tenant_id = resolve_tenant!(provider, conn, raw_body, headers)

      # Step 3: ingest under tenant scope (Pitfall 7 — block form)
      Tenancy.with_tenant(tenant_id, fn ->
        events =
          provider
          |> provider_module()
          |> apply(:normalize, [raw_body, headers])

        ingest_and_respond(conn, provider, raw_body, events, tenant_id)
      end)
    rescue
      e in SignatureError ->
        Logger.warning(
          "Webhook signature failed: provider=#{provider} reason=#{e.type}"
        )

        conn = send_resp(conn, 401, "")

        {conn,
         %{
           provider: provider,
           status: :signature_failed,
           failure_reason: e.type
         }}

      e in TenancyError ->
        Logger.warning(
          "Webhook tenant resolution failed: provider=#{provider} reason=#{e.type}"
        )

        conn = send_resp(conn, 422, "")

        {conn,
         %{
           provider: provider,
           status: :tenant_unresolved,
           failure_reason: e.type
         }}

      e in ConfigError ->
        Logger.error(
          "[mailglass] Webhook config error: provider=#{provider} " <>
            "reason=#{e.type} message=#{Exception.message(e)}"
        )

        conn = send_resp(conn, 500, "")

        {conn,
         %{
           provider: provider,
           status: :config_error,
           failure_reason: e.type
         }}
    end
  end

  # Step 1a: extract raw bytes + headers; fail fast if CachingBodyReader
  # not wired. Raises ConfigError with :webhook_caching_body_reader_missing
  # (per Phase 4 D-21 revision B4) — distinct from
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
    env = Application.get_env(:mailglass, :postmark, [])

    %{
      basic_auth: env[:basic_auth],
      ip_allowlist: env[:ip_allowlist] || [],
      remote_ip: conn.remote_ip
    }
  end

  defp resolve_config!(:sendgrid, _conn) do
    env = Application.get_env(:mailglass, :sendgrid, [])

    %{
      public_key: env[:public_key],
      timestamp_tolerance_seconds: env[:timestamp_tolerance_seconds] || 300
    }
  end

  # Step 2: telemetry-wrapped Provider.verify!/3 (CONTEXT D-22 inner span).
  # Uses Mailglass.Telemetry.span/3 (the D-27-compliant wrapper) from day
  # one per revision B3; Plan 08 extracts a named helper wrapping the same
  # primitive without any behavioural change.
  defp verify_with_telemetry!(provider, raw_body, headers, config) do
    Mailglass.Telemetry.span(
      [:mailglass, :webhook, :signature, :verify],
      %{provider: provider, status: :pending},
      fn ->
        module = provider_module(provider)
        apply(module, :verify!, [raw_body, headers, config])
        :ok
      end
    )
  end

  # Step 3: tenant resolution via Mailglass.Tenancy.resolve_webhook_tenant/1
  # (Plan 05 formalizes the @optional_callback; this plan ships a stub
  # dispatcher that returns {:ok, "default"} for SingleTenant).
  defp resolve_tenant!(provider, conn, raw_body, headers) do
    ctx = %{
      provider: provider,
      conn: conn,
      raw_body: raw_body,
      headers: headers,
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

  # Step 4: normalize → ingest → respond
  #
  # Plan 06 contract (see Plan 06's finalize_changes/2): ingest_multi/3
  # returns `{:ok, %{webhook_event: %WebhookEvent{}, duplicate: boolean,
  # events_with_deliveries: [{event, delivery, orphan?}, ...],
  # orphan_event_count: int}}`.
  #
  # Local name `result` (per revision W5) over `changes` to avoid shadowing
  # Ecto.Multi's "changes" terminology that the Ingest module uses
  # internally.
  defp ingest_and_respond(conn, provider, raw_body, events, tenant_id) do
    case Mailglass.Webhook.Ingest.ingest_multi(provider, raw_body, events) do
      {:ok, %{duplicate: true} = result} ->
        broadcast_post_commit(result)

        conn = send_resp(conn, 200, "")

        {conn,
         %{
           provider: provider,
           tenant_id: tenant_id,
           status: :duplicate,
           event_count: length(events),
           duplicate: true
         }}

      {:ok, result} ->
        broadcast_post_commit(result)

        conn = send_resp(conn, 200, "")

        {conn,
         %{
           provider: provider,
           tenant_id: tenant_id,
           status: :ok,
           event_count: length(events),
           duplicate: false
         }}

      {:error, reason} ->
        Logger.error(
          "[mailglass] Webhook ingest failed: provider=#{provider} reason=#{inspect(reason)}"
        )

        conn = send_resp(conn, 500, "")

        {conn,
         %{
           provider: provider,
           tenant_id: tenant_id,
           status: :ingest_failed,
           event_count: length(events)
         }}
    end
  end

  # Post-commit broadcast — runs AFTER Repo.transact returns {:ok, _}
  # (Phase 3 D-04 invariant). Per Plan 06 finalize_changes/2 (revision B7),
  # `events_with_deliveries` is a list of 3-tuples:
  # `{inserted_event, delivery_or_nil, orphan?}`. Orphans are skipped here
  # (delivery is nil — there is nothing to broadcast against; Plan 07's
  # Reconciler later emits a :reconciled event when the matching Delivery
  # commits per D-18 append-only).
  defp broadcast_post_commit(%{events_with_deliveries: events_with_deliveries})
       when is_list(events_with_deliveries) do
    Enum.each(events_with_deliveries, fn
      {_event, nil, true} ->
        :ok

      {event, delivery, false} ->
        Projector.broadcast_delivery_updated(delivery, event.type, %{
          event_id: event.id,
          provider: event.provider
        })
    end)
  end

  defp broadcast_post_commit(_), do: :ok

  # Static dispatch — exhaustive case per CONTEXT D-01 (init/1 validates
  # that provider is in @valid_providers at mount time, so the defp
  # clauses are exhaustive for all reachable call sites).
  defp provider_module(:postmark), do: Mailglass.Webhook.Providers.Postmark
  defp provider_module(:sendgrid), do: Mailglass.Webhook.Providers.SendGrid
end
