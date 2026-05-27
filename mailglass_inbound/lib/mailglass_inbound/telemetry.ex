defmodule MailglassInbound.Telemetry do
  @moduledoc """
  The single span surface for `mailglass_inbound` (the design contract).

  Mirrors `Mailglass.Webhook.Telemetry`: every inbound `:telemetry.span/3` call
  lives here so the extended `NoPiiInTelemetry` check (enabled for inbound in
  this plan) has exactly ONE module to audit, plus the four call sites. Callers
  MUST NOT reach for `:telemetry.span/3` directly — use the named helpers below.

  ## Events emitted

  | Event | Type | Stop metadata keys (the design contract whitelist) |
  |-------|------|----------------------------------------|
  | `[:mailglass_inbound, :ingress, :request, :start \\| :stop \\| :exception]` | full span | `provider, tenant_id, status, byte_size` |
  | `[:mailglass_inbound, :route, :match, :start \\| :stop \\| :exception]` | full span | `mailbox, candidate_count, status` |
  | `[:mailglass_inbound, :persist, :record, :start \\| :stop \\| :exception]` | full span | `provider, tenant_id, operation, record_type` |
  | `[:mailglass_inbound, :execution, :run, :start \\| :stop \\| :exception]` | full span | `mailbox, outcome, source` |
  | `[:mailglass_inbound, :ingress, :rate_limit, :start \\| :stop \\| :exception]` | full span | `provider, tenant_id, bucket, limit, retry_after` |
  | `[:mailglass_inbound, :ingress, :suppression_flag, :start \\| :stop \\| :exception]` | full span | `provider, tenant_id, flagged` |
  | `[:mailglass_inbound, :prune, :sweep, :start \\| :stop \\| :exception]` | full span | `status, records_deleted, evidence_deleted, fresh_runs_deleted, replay_runs_deleted` |

  > **Event-name convention note (the design contract deviation):** the CONTEXT named the
  > rate-limit event `[:mailglass_inbound, :rate_limit, :stop]` and the prune event
  > `[:mailglass_inbound, :prune, :stop]` (3 final segments). The locked
  > `[root, domain, resource, action]` 4-segment telemetry convention
  > (`TelemetryEventConvention`, enforced at lint time) requires 4 final segments,
  > so these ship as `[:mailglass_inbound, :ingress, :rate_limit, *]` (rate-limit is
  > an ingress-path event, beside `:suppression_flag`) and
  > `[:mailglass_inbound, :prune, :sweep, *]`. Same resource name, convention-compliant.

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

  ## Whitelist discipline (the design contract)

  The ONLY allowed metadata keys across all spans:

      provider, tenant_id, status, latency, byte_size, mailbox, candidate_count,
      outcome, source, operation, record_type,
      bucket, limit, retry_after, flagged,
      records_deleted, evidence_deleted, fresh_runs_deleted, replay_runs_deleted
  Inbound telemetry metadata must never include raw payload or recipient PII.

  The Phase-49 additions (`bucket, limit, retry_after, flagged` + the per-table
  prune counts) are all counts/types/statuses — never PII (the design contract/23/29). The
  rate-limit + suppression-flag spans carry the bucket TYPE and a boolean flag,
  never the recipient/sender value.

  **NEVER include in any metadata map:**

      :to, :from, :cc, :bcc, :subject, :body, :html_body, :headers,
      :recipient, :sender, :email

  `NoPiiInTelemetry` (extended to inbound in this plan) lints THIS module plus every
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
  async paths funnel through, so the span covers both (the design contract, RESEARCH Pitfall 5
  — wrap `execute/2`, never `dispatch/2`).

  Stop metadata SHOULD include `:mailbox`, `:outcome`, `:source`. All PII-free.

  `fun` may return a bare `result` OR `{result, stop_metadata}`.
  """
  @doc since: "0.2.0"
  @spec execution_span(map(), (-> result | {result, map()})) :: result when result: term()
  def execution_span(metadata, fun) when is_map(metadata) and is_function(fun, 0) do
    span([:mailglass_inbound, :execution, :run], metadata, fun)
  end

  @doc """
  Wrap the post-verify rate-limit check in a
  `[:mailglass_inbound, :ingress, :rate_limit, *]` span (IOPS-04, the design contract). The
  rate limiter is an ingress-path event, so it lives under the `:ingress` domain
  (beside `:suppression_flag`) to satisfy the 4-segment event convention.

  Stop metadata SHOULD include `:provider`, `:tenant_id`, and on a trip the
  bucket `:bucket` TYPE (`:tenant | :recipient | :sender_domain`), `:limit`
  (capacity), and `:retry_after` (seconds). It MUST NOT carry the recipient or
  sender VALUE — only the bucket type (the design contract).

  `fun` may return a bare `result` OR `{result, stop_metadata}`.
  """
  @doc since: "1.2.0"
  @spec rate_limit(map(), (-> result | {result, map()})) :: result when result: term()
  def rate_limit(metadata, fun) when is_map(metadata) and is_function(fun, 0) do
    span([:mailglass_inbound, :ingress, :rate_limit], metadata, fun)
  end

  @doc """
  Wrap the inbound suppression-flag computation in a
  `[:mailglass_inbound, :ingress, :suppression_flag, *]` span (IOPS-05, the design contract).
  Consumed by this plan.

  Stop metadata SHOULD include `:flagged` (boolean), `:tenant_id`, `:provider` —
  never the address. No auto-bounce, no auto-suppression: the flag is diagnostic
  signal only.

  `fun` may return a bare `result` OR `{result, stop_metadata}`.
  """
  @doc since: "1.2.0"
  @spec suppression_flag(map(), (-> result | {result, map()})) :: result when result: term()
  def suppression_flag(metadata, fun) when is_map(metadata) and is_function(fun, 0) do
    span([:mailglass_inbound, :ingress, :suppression_flag], metadata, fun)
  end

  @doc """
  Wrap a retention prune sweep in a `[:mailglass_inbound, :prune, :sweep, *]`
  span (IOPS-03, the design contract). Consumed by this plan. The `:sweep` resource segment
  satisfies the 4-segment event convention.

  Stop metadata SHOULD include the per-table counts `:records_deleted`,
  `:evidence_deleted`, `:fresh_runs_deleted`, `:replay_runs_deleted`, and a
  `:status`. Counts only — no PII.

  `fun` may return a bare `result` OR `{result, stop_metadata}`.
  """
  @doc since: "1.2.0"
  @spec prune(map(), (-> result | {result, map()})) :: result when result: term()
  def prune(metadata, fun) when is_map(metadata) and is_function(fun, 0) do
    span([:mailglass_inbound, :prune, :sweep], metadata, fun)
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
