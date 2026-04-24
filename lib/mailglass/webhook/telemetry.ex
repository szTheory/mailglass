defmodule Mailglass.Webhook.Telemetry do
  @moduledoc """
  Co-located span helpers for the webhook ingest surface (CONTEXT D-22).

  Mirrors `Mailglass.Telemetry.send_span/2` placement convention
  (Phase 3 D-26): per-domain helpers live in their own module under
  the domain's `lib/` directory. The helpers in this module are the
  single-module surface for the webhook telemetry contract, which
  means Phase 6 `LINT-02` (`NoPiiInTelemetryMeta`) has exactly one
  module to lint (plus the call sites).

  ## Events emitted

  | Event | Type | Stop metadata keys (D-23 whitelist) |
  |-------|------|--------------------------------------|
  | `[:mailglass, :webhook, :ingest, :start \\| :stop \\| :exception]` | full span | `provider, tenant_id, status, event_count, duplicate, failure_reason, delivery_id_matched` |
  | `[:mailglass, :webhook, :signature, :verify, :start \\| :stop \\| :exception]` | full span | `provider, status, failure_reason` |
  | `[:mailglass, :webhook, :normalize, :stop]` | single emit | `provider, event_type, mapped` |
  | `[:mailglass, :webhook, :orphan, :stop]` | single emit | `provider, event_type, tenant_id, age_seconds` |
  | `[:mailglass, :webhook, :duplicate, :stop]` | single emit | `provider, event_type` |
  | `[:mailglass, :webhook, :reconcile, :start \\| :stop \\| :exception]` | full span | `tenant_id, scanned_count, linked_count, remaining_orphan_count, status` |

  Single-emit helpers delegate to `Mailglass.Telemetry.execute/3`
  (Phase 1). Full-span helpers call `:telemetry.span/3` directly
  because the Plug needs per-request stop metadata enrichment
  (`status`, `failure_reason`, `event_count`, `duplicate`) — the
  `Mailglass.Telemetry.span/3` wrapper closes metadata at call time,
  which cannot express "I know the status once the inner function
  returns." `:telemetry.span/3` itself provides D-27 handler
  isolation: handlers that raise are auto-detached and
  `[:telemetry, :handler, :failure]` fires — a handler crash cannot
  propagate into the webhook pipeline. Callers MUST NOT reach for
  `:telemetry.span/3` directly; use the helpers below so LINT-02
  has a single module surface to lint.

  ## Per-request stop metadata enrichment

  The full-span helpers (`ingest_span/2`, `verify_span/2`,
  `reconcile_span/2`) accept a zero-arity function returning either:

    * `result` — bare value; stop metadata equals the `metadata`
      argument passed at call time.
    * `{result, stop_metadata}` — tuple; stop metadata is the
      returned map. Used by the Plug to attach `:status`,
      `:failure_reason`, `:event_count`, `:duplicate` onto the
      `:stop` event after classifying the outcome.

  Start metadata is always the `metadata` argument at call time
  (before outcome is known).

  ## Whitelist discipline (D-23)

  **NEVER include in any metadata map:**

    * `:ip`, `:remote_ip`, `:user_agent`
    * `:to`, `:from`, `:subject`, `:body`, `:html_body`, `:headers`,
      `:recipient`, `:email`
    * `:raw_payload`, `:raw_body`

  Adopters wanting IP-based abuse triage attach their own handler on
  `[:mailglass, :webhook, :signature, :verify, :stop]` and pull
  `conn.remote_ip` from their own plug lineage (see
  `guides/webhooks.md`).

  Phase 6 `LINT-02` (`NoPiiInTelemetryMeta`) lints THIS module plus
  every caller against the forbidden-key set.

  ## `LINT-10` single-emit exception

  The three single-emit helpers (`normalize_emit/1`, `orphan_emit/1`,
  `duplicate_emit/1`) are deliberate exceptions to the "every event
  is a full `:start`/`:stop`/`:exception` span" rule. They preserve
  the 4-level path structure (`[:mailglass, :webhook, :action, :stop]`)
  but skip the start/exception pair because they fire from INSIDE the
  larger `[:mailglass, :webhook, :ingest, *]` span (which IS a full
  span) and represent per-event signals inside a wrapped operation.
  Phase 6 `LINT-10` whitelists these three event paths.
  """

  alias Mailglass.Telemetry

  @doc """
  Wrap the entire webhook ingest path in a `[:mailglass, :webhook, :ingest, *]` span.

  Stop metadata SHOULD include `:provider`, `:tenant_id`, `:status`,
  `:event_count`, `:duplicate`, `:delivery_id_matched`. NEVER include
  PII (see the module doc whitelist).

  `fun` may return a bare `result` OR `{result, stop_metadata}` — see
  the moduledoc's "Per-request stop metadata enrichment" section.
  """
  @doc since: "0.1.0"
  @spec ingest_span(map(), (-> result | {result, map()})) :: result when result: term()
  def ingest_span(metadata, fun) when is_map(metadata) and is_function(fun, 0) do
    span_with_enrichment([:mailglass, :webhook, :ingest], metadata, fun)
  end

  @doc """
  Wrap `Provider.verify!/3` in a `[:mailglass, :webhook, :signature, :verify, *]` span.

  Stop metadata SHOULD include `:provider`, `:status`, `:failure_reason`.

  `fun` may return a bare `result` OR `{result, stop_metadata}`.
  """
  @doc since: "0.1.0"
  @spec verify_span(map(), (-> result | {result, map()})) :: result when result: term()
  def verify_span(metadata, fun) when is_map(metadata) and is_function(fun, 0) do
    span_with_enrichment([:mailglass, :webhook, :signature, :verify], metadata, fun)
  end

  @doc """
  Single-emit per-event normalize signal
  (`[:mailglass, :webhook, :normalize, :stop]`).

  Metadata SHOULD include `:provider`, `:event_type`, `:mapped`.
  Alertable on sustained `mapped: false` rate (D-22).
  """
  @doc since: "0.1.0"
  @spec normalize_emit(map()) :: :ok
  def normalize_emit(metadata) when is_map(metadata) do
    Telemetry.execute([:mailglass, :webhook, :normalize, :stop], %{count: 1}, metadata)
  end

  @doc """
  Single-emit per-event orphan signal
  (`[:mailglass, :webhook, :orphan, :stop]`).

  Metadata SHOULD include `:provider`, `:event_type`, `:tenant_id`,
  `:age_seconds`. Fires once per normalized event that lands without
  a matching Delivery. Plan 07 Reconciler closes the race by
  appending a `:reconciled` event when the matching Delivery surfaces.
  """
  @doc since: "0.1.0"
  @spec orphan_emit(map()) :: :ok
  def orphan_emit(metadata) when is_map(metadata) do
    Telemetry.execute([:mailglass, :webhook, :orphan, :stop], %{count: 1}, metadata)
  end

  @doc """
  Single-emit per-ingest duplicate signal
  (`[:mailglass, :webhook, :duplicate, :stop]`).

  Metadata SHOULD include `:provider`, `:event_type`. Lets adopters
  distinguish provider retry storms from real traffic cheaply via
  Grafana panels on the emit rate (D-24 alternative to log-scraping).
  """
  @doc since: "0.1.0"
  @spec duplicate_emit(map()) :: :ok
  def duplicate_emit(metadata) when is_map(metadata) do
    Telemetry.execute([:mailglass, :webhook, :duplicate, :stop], %{count: 1}, metadata)
  end

  @doc """
  Wrap `Mailglass.Webhook.Reconciler.reconcile/2` in a
  `[:mailglass, :webhook, :reconcile, *]` span.

  Stop metadata SHOULD include `:tenant_id`, `:scanned_count`,
  `:linked_count`, `:remaining_orphan_count`, `:status`.

  `fun` may return a bare `result` OR `{result, stop_metadata}`.
  """
  @doc since: "0.1.0"
  @spec reconcile_span(map(), (-> result | {result, map()})) :: result when result: term()
  def reconcile_span(metadata, fun) when is_map(metadata) and is_function(fun, 0) do
    span_with_enrichment([:mailglass, :webhook, :reconcile], metadata, fun)
  end

  # Shared full-span implementation. Calls `:telemetry.span/3` directly
  # (not `Mailglass.Telemetry.span/3`) because this supports per-request
  # stop metadata enrichment — the Plug's `do_call/3` classifies outcome
  # after the inner fn returns and needs the stop event to carry the
  # classified `:status`, `:failure_reason`, `:event_count`, `:duplicate`
  # values, which the fixed-at-call-time wrapper cannot express.
  #
  # D-27 handler isolation is still preserved: `:telemetry.span/3` wraps
  # each attached handler in a try/catch; a handler that raises is
  # auto-detached and emits `[:telemetry, :handler, :failure]` — a handler
  # crash cannot propagate into the webhook pipeline.
  defp span_with_enrichment(event_prefix, metadata, fun) do
    :telemetry.span(event_prefix, metadata, fn ->
      case fun.() do
        {result, %{} = stop_metadata} ->
          {result, stop_metadata}

        result ->
          {result, metadata}
      end
    end)
  end
end
