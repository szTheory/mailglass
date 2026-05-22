defmodule MailglassInbound.Telemetry do
  @moduledoc """
  The single span surface for `mailglass_inbound` (D-45-01).

  Mirrors `Mailglass.Webhook.Telemetry`: every inbound `:telemetry.span/3` call
  lives here so the extended `NoPiiInTelemetry` check (enabled for inbound in
  Plan 01) has exactly ONE module to audit, plus the four call sites. Callers
  MUST NOT reach for `:telemetry.span/3` directly — use the named helpers below.

  ## Events emitted

  | Event | Type | Stop metadata keys (D-45-03 whitelist) |
  |-------|------|----------------------------------------|
  | `[:mailglass_inbound, :ingress, :request, :start \\| :stop \\| :exception]` | full span | `provider, tenant_id, status, byte_size` |
  | `[:mailglass_inbound, :route, :match, :start \\| :stop \\| :exception]` | full span | `mailbox, candidate_count, status` |
  | `[:mailglass_inbound, :persist, :record, :start \\| :stop \\| :exception]` | full span | `provider, tenant_id, operation, record_type` |
  | `[:mailglass_inbound, :execution, :run, :start \\| :stop \\| :exception]` | full span | `mailbox, outcome, source` |

  Every helper is a full `:start`/`:stop`/`:exception` span via `:telemetry.span/3`.
  There is no single-emit (fire-and-forget) helper here — inbound emits via spans
  only. `:telemetry.span/3` supplies `:duration` in its `:stop` measurements
  automatically; callers MUST NOT hand-compute latency into metadata.

  ## Per-request stop metadata enrichment

  Each helper accepts a zero-arity function returning either:

    * `result` — bare value; stop metadata equals the `metadata` argument passed
      at call time (before the outcome is known).
    * `{result, stop_metadata}` — tuple; stop metadata is the returned map. Used
      by the call sites to attach the classified `:status`, `:operation`,
      `:outcome`, `:mailbox` onto the `:stop` event after the inner function
      returns. Start metadata is always the `metadata` argument at call time.

  ## Whitelist discipline (D-45-03)

  The ONLY allowed metadata keys across all four spans:

      provider, tenant_id, status, latency, byte_size, mailbox, candidate_count,
      outcome, source, operation, record_type

  **NEVER include in any metadata map:**

      :to, :from, :cc, :bcc, :subject, :body, :html_body, :headers,
      :recipient, :sender, :email

  `NoPiiInTelemetry` (extended to inbound in Plan 01) lints THIS module plus every
  caller against the forbidden-key set.

  ## Handler isolation (TELE-05)

  `:telemetry.span/3` wraps each attached handler in a try/catch. A handler that
  raises is detached automatically and `[:telemetry, :handler, :failure]` is
  emitted — the caller's inbound pipeline is unaffected. `mailglass_inbound` does
  **not** add a parallel try/rescue around business code (that would duplicate or,
  worse, swallow the meta-event operators rely on). TELE-05 comes for free from
  routing every span through `:telemetry.span/3`.
  """

  @doc """
  Wrap the entire inbound ingress path in a
  `[:mailglass_inbound, :ingress, :request, *]` span.

  Stop metadata SHOULD include `:provider`, `:tenant_id`, `:status`,
  `:byte_size`. NEVER include PII (see the module doc whitelist). Latency is
  supplied by `:telemetry.span/3` in its measurements — do not put it in metadata.

  `fun` may return a bare `result` OR `{result, stop_metadata}` — see the
  moduledoc's "Per-request stop metadata enrichment" section.
  """
  @doc since: "0.2.0"
  @spec ingress_span(map(), (-> result | {result, map()})) :: result when result: term()
  def ingress_span(metadata, fun) when is_map(metadata) and is_function(fun, 0) do
    span([:mailglass_inbound, :ingress, :request], metadata, fun)
  end

  @doc """
  Wrap `MailglassInbound.Router.Matcher.match/2` in a
  `[:mailglass_inbound, :route, :match, *]` span.

  Stop metadata SHOULD include `:mailbox` + `:candidate_count` on a match, or
  `:status` (`:no_match`) + `:candidate_count` on a miss. All PII-free.

  `fun` may return a bare `result` OR `{result, stop_metadata}`.
  """
  @doc since: "0.2.0"
  @spec route_span(map(), (-> result | {result, map()})) :: result when result: term()
  def route_span(metadata, fun) when is_map(metadata) and is_function(fun, 0) do
    span([:mailglass_inbound, :route, :match], metadata, fun)
  end

  @doc """
  Wrap the `repo.transact` in `MailglassInbound.Ingress.Persist.persist/2` in a
  `[:mailglass_inbound, :persist, :record, *]` span.

  Stop metadata SHOULD include `:provider`, `:tenant_id`, `:operation`
  (`:insert` | `:dedup_skip`), `:record_type`. All PII-free.

  `fun` may return a bare `result` OR `{result, stop_metadata}`.
  """
  @doc since: "0.2.0"
  @spec persist_span(map(), (-> result | {result, map()})) :: result when result: term()
  def persist_span(metadata, fun) when is_map(metadata) and is_function(fun, 0) do
    span([:mailglass_inbound, :persist, :record], metadata, fun)
  end

  @doc """
  Wrap the body of `MailglassInbound.Execution.execute/2` in a
  `[:mailglass_inbound, :execution, :run, *]` span.

  This is the single synchronous sync point both the Oban and Task.Supervisor
  async paths funnel through, so the span covers both (D-45-02, RESEARCH Pitfall 5
  — wrap `execute/2`, never `dispatch/2`).

  Stop metadata SHOULD include `:mailbox`, `:outcome`, `:source`. All PII-free.

  `fun` may return a bare `result` OR `{result, stop_metadata}`.
  """
  @doc since: "0.2.0"
  @spec execution_span(map(), (-> result | {result, map()})) :: result when result: term()
  def execution_span(metadata, fun) when is_map(metadata) and is_function(fun, 0) do
    span([:mailglass_inbound, :execution, :run], metadata, fun)
  end

  # Shared full-span implementation. Calls `:telemetry.span/3` directly (the
  # webhook analog's body is `defp`, so this is COPIED, not cross-called). The
  # call sites classify the outcome AFTER the inner fn returns and attach the
  # classified `:status`/`:operation`/`:outcome`/`:mailbox` onto the `:stop`
  # event — which a fixed-at-call-time wrapper cannot express.
  #
  # TELE-05 handler isolation is preserved: `:telemetry.span/3` wraps each
  # attached handler in a try/catch; a handler that raises is auto-detached and
  # emits `[:telemetry, :handler, :failure]` — a handler crash cannot propagate
  # into the inbound pipeline.
  defp span(event_prefix, metadata, fun) do
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
