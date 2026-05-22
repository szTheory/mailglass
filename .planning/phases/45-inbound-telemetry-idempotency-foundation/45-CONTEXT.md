# Phase 45: Inbound Telemetry + Idempotency Foundation - Context

**Gathered:** 2026-05-22 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Make `mailglass_inbound` observable, debuggable, and idempotent-by-construction so
the rest of v1.2 can build on it. Three deliverables, no more:

1. **4-level `:telemetry` spans** across every inbound stage — ingress, route,
   execute, persist — with PII-free metadata and raise-safe handlers.
2. **A shared `MailglassInbound.MIME` parser** that turns raw RFC 5322 bodies into
   a stable internal representation, gated through `Mailglass.OptionalDeps.GenSmtp`,
   never raising on malformed input.
3. **A StreamData 1000-replay convergence property** proving the real
   persist+route+execute write path is idempotent (one `InboundRecord` + one
   `ExecutionRun` per unique payload).

In scope: TELE-01..08, MIME-01, MIME-02, MIME-04.

Out of scope (later phases): wiring MIME into any provider (Mailgun/SES = Phase 46),
the admin LiveView that *consumes* TELE-07 (Phase 48), `mailglass.inbound.doctor`
MIME-availability reporting (MIME-03 = Phase 49). This phase ships the *producers*
and *proofs*, not the consumers.
</domain>

<decisions>
## Implementation Decisions

### Telemetry emission mechanism + span placement
- **D-45-01:** Reuse the core wrapper `Mailglass.Telemetry.span/3` for fixed-metadata
  spans, and add a co-located `MailglassInbound.Telemetry` module that mirrors
  `Mailglass.Webhook.Telemetry.span_with_enrichment/3` (calls `:telemetry.span/3`
  directly, accepts a fn returning `result` or `{result, stop_metadata}`) for the
  outcome-dependent stop metadata required by TELE-01..04. Keep emission in a single
  inbound telemetry module so the extended `NoPIIInTelemetry` Credo check has one
  surface to audit.
- **D-45-02:** Span wrap points are fixed:
  - **ingress** (`[:mailglass_inbound, :ingress, :request, *]`) wraps the body of
    `MailglassInbound.Ingress.Plug.call/2`.
  - **route** (`[:mailglass_inbound, :route, :match, *]`) wraps
    `MailglassInbound.Router.Matcher.match/2`.
  - **persist** (`[:mailglass_inbound, :persist, :record, *]`) wraps the
    `repo.transact` in `MailglassInbound.Ingress.Persist.persist/2`; operation
    metadata derives from result status (`:inserted` → `insert`, `:duplicate` →
    `dedup_skip`).
  - **execution** (`[:mailglass_inbound, :execution, :run, *]`) wraps
    `MailglassInbound.Execution.execute/2` — NOT `dispatch/2`. Wrapping `execute/2`
    is the single point that covers both the Oban worker path and the
    `Task.Supervisor` fallback, and it is where the `:accept|:reject|:ignore|{:bounce,_}`
    outcome and `:fresh|:replay` source are actually computed.
- **D-45-03:** Metadata is PII-free per the project contract: allowed = provider,
  tenant_id, status, latency, byte_size, matched-mailbox identity / no-match /
  candidate count, mailbox module, outcome, source, operation, record_type. Never
  recipient, sender, body, html_body, subject, headers, email, to, from.
- **D-45-04:** Handler raise-safety (TELE-05) comes for free from `:telemetry.span/3`
  semantics (the telemetry library isolates handler exceptions). Mirror the outbound
  contract; do not add custom rescue logic around business code to "protect" it.

### TELE-06 — extending the NoPIIInTelemetry Credo check
- **D-45-05:** Extend the existing `NoPIIInTelemetry` Credo check
  (`credo_checks/no_pii_in_telemetry_meta.ex`) to cover `mailglass_inbound/`.
  Planner/researcher must determine whether this is a `.credo.exs` path-scope change,
  a check-internal path list, or both, and verify the boundary check correctly
  cross-package classifies inbound modules (this is called out as a "hardest sub-task"
  in ROADMAP.md).

### TELE-07 — inbound telemetry surfaced to admin PubSub
- **D-45-06:** Inbound surfaces record-inserted events by broadcasting **directly**
  on `Phoenix.PubSub` (server `Mailglass.PubSub`), **post-commit**, after
  `Ingress.Persist.persist/2` returns `:inserted`. This mirrors the outbound
  `Mailglass.Outbound.Projector` direct-broadcast pattern. Do **not** build a
  telemetry-handler→PubSub bridge (none exists in the codebase; the telemetry spans
  and the PubSub broadcast are separate mechanisms). The post-commit-broadcast
  invariant must hold — never broadcast inside the persist transaction.
- **D-45-07:** Exactly **one** new topic, per-tenant. No topic explosion. Topic
  string default: `"mailglass:inbound:" <> tenant_id` — matches the existing
  `mailglass:`-prefixed per-tenant shape of `Mailglass.PubSub.Topics.events/1` and
  passes `LINT-06 PrefixedPubSubTopics`.
- **D-45-08:** The topic-builder function lives in a new
  `MailglassInbound.PubSub.Topics` module (e.g. `inbound_record_inserted/1`) so the
  inbound package never hard-codes a literal topic string at the broadcast call site
  (which `LINT-06` would flag) and so no inbound→admin compile-time dependency is
  created. `mailglass_admin` stays a pure **consumer**: its
  `MailglassAdmin.PubSub.Topics` (Phase 48) subscribes to the same string. No
  inbound↔admin dependency edge.

### TELE-08 — 1000-replay convergence property
- **D-45-09:** Structurally mirror `Mailglass.Properties.WebhookIdempotencyConvergenceTest`:
  `use ExUnit.Case, async: false` + `use ExUnitProperties` (NOT `DataCase` — its
  per-test transaction deadlocks against the inter-iteration TRUNCATE),
  `Sandbox.start_owner!(shared: true, ownership_timeout: 10 * 60_000)`,
  `TRUNCATE … CASCADE` between iterations (append-only trigger forbids UPDATE/DELETE),
  `max_runs: 1000`, `@moduletag timeout: :infinity`, `@moduletag :property`.
- **D-45-10:** Drive the **real** write path through synchronous
  `MailglassInbound.Execution.execute/2` (which already exists, distinct from async
  `dispatch/2`). Do NOT drive `dispatch/2` — Oban may not be started in test env and
  `Task.Supervisor` children run detached, making `ExecutionRun` counts
  non-deterministic across 1000 runs.
- **D-45-11:** Assert the single-row invariant: exactly one `InboundRecord` per
  unique `(tenant_id, provider, provider_message_id)` AND exactly one `ExecutionRun`
  per inserted record after N replays. Dedupe is anchored on the existing unique
  index `mailglass_inbound_records_postmark_idempotency_idx`; replays return
  `:duplicate`, and `Execution.execute/2` short-circuits `%{status: :duplicate}` to
  `:skipped` (zero extra `ExecutionRun` rows).
- **D-45-12:** Generator idiom (research-confirmed against the in-repo outbound
  test): `gen all`, draw `provider_message_id` from a small `member_of` pool (≤4
  ids) over a `list_of(payload, max_length: 10)` so collisions occur across list
  elements, combined with an `integer(1..10)` replay multiplier. Generate Postmark-
  style string-keyed JSON payloads with `MessageID` as the dedupe key.

### MIME parser + gen_smtp backend + error type
- **D-45-13:** `MailglassInbound.MIME` is net-new (no existing internal
  representation to reuse). Parse via `:mimemail.decode/1` from gen_smtp 1.3.0,
  gated through `Mailglass.OptionalDeps.GenSmtp`. The gateway must be **extended** —
  today it exposes only `available?/0`; add the parse seam there, not as scattered
  `Code.ensure_loaded?` calls.
- **D-45-14:** Decoded shape is the gen_smtp 5-tuple
  `{Type, SubType, Headers, Parameters, Body}` where `Parameters` is a **map** with
  `transfer_encoding`, `content_type_params`, `disposition`, `disposition_params`.
  Multipart `Body` is a list of nested tuples (recurse); `message/rfc822` body is a
  single tuple; leaf body is a binary. Classify attachment vs inline from
  `Parameters.disposition` (`<<"attachment">>` vs `<<"inline">>`); filename from
  `disposition_params["filename"]` then `content_type_params["name"]`. Do NOT depend
  on the `decode_attachment(s)` option — its spelling is inconsistent in 1.3.0 and
  the toggle is unreliable; treat attachment decoding as always-on.
- **D-45-15:** MIME-04 never-raise: `:mimemail.decode/1` **raises** via *two*
  mechanisms — `erlang:error/1` (`non_mime`, `no_boundary`, `missing_boundary`,
  `unterminated_quotes`, …) AND `throw/1` (`bad_content_type`, `bad_disposition`).
  Wrap in `try/rescue` **and** `catch :throw`, and consider `catch :exit` (iconv).
  Pass `{allow_missing_version, true}` (default) so messages lacking `MIME-Version`
  parse; consider `{encoding, none}` to skip iconv transcoding and avoid eiconv
  dependency surprises. Return `{:error, struct}` on any failure, never raise.
- **D-45-16:** Add a new `MailglassInbound.MIMEError` defexception following the
  canonical error shape used by every existing error struct (`[:type, :message,
  :cause, :context]`), with closed `:type` set `[:inbound_mime_invalid,
  :gen_smtp_unavailable]`. `:inbound_mime_invalid` exists in no current error struct
  and `Mailglass.Error` is a behaviour/namespace with no parent struct, so this is a
  documented public-contract addition: CHANGELOG entry + `@since` + the
  `__types__/0`-style test assertion, minor version bump.
- **D-45-17:** Degraded fallback (MIME-02): when
  `Mailglass.OptionalDeps.GenSmtp.available?/0` is false, return a structured
  `{:error, %MailglassInbound.MIMEError{type: :gen_smtp_unavailable}}` (or a
  documented minimal headers+raw-body representation). Document the degraded path.
  The mandatory `mix compile --no-optional-deps --warnings-as-errors` CI lane must
  pass — all `:mimemail` references go through the gateway, never bare (else
  `NoBareOptionalDepReference` flags them).
- **D-45-18:** MIME parser is built **standalone** in Phase 45 and NOT wired into
  Postmark/SendGrid normalization (which are JSON-based and working). First consumer
  is Phase 46 (Mailgun/SES raw-MIME ingress). Wiring it into existing providers now
  would expand scope and risk regressing the working JSON normalize path.

### the agent's Discretion
- Exact internal function names/signatures of `MailglassInbound.Telemetry` and the
  `Mailglass.OptionalDeps.GenSmtp` parse seam.
- Exact internal representation struct(s) returned by `MailglassInbound.MIME`
  (headers/parts/attachments/inline) — as long as it is stable and documented.
- Exact mechanics of the `NoPIIInTelemetry` cross-package scoping (config vs check
  internals), provided the check passes across both packages.
- Exact StreamData generator helper shapes, provided the convergence invariant in
  D-45-11 holds.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and locked posture
- `.planning/ROADMAP.md` — Phase 45 goal, success criteria, hardest sub-tasks; Phase
  46 dependency on the MIME module.
- `.planning/REQUIREMENTS.md` — TELE-01..08, MIME-01, MIME-02, MIME-04 wording.
- `.planning/PROJECT.md` — telemetry-no-PII, append-only events, optional-dep gateway,
  one-maintainer honesty constraints.
- `.planning/METHODOLOGY.md` — decisive-by-default, honest-surface, recommendation-first.
- `.planning/STATE.md` — current v1.2 milestone position.
- `.planning/milestones/v1.1-phases/40-postmark-ingress-and-replayable-persistence/40-CONTEXT.md`
  — persistence/replay model (canonical row + evidence row; `(tenant_id, provider,
  provider_message_id)` dedupe anchor) inherited by this phase.
- `.planning/milestones/v1.1-phases/42-async-execution-and-adopter-proof/42-CONTEXT.md`
  — async execution model (Oban + bounded Task.Supervisor fallback) the execution
  span must wrap.

### Outbound patterns to mirror (code anchors)
- `lib/mailglass/telemetry.ex` — `Mailglass.Telemetry.span/3` fixed-metadata wrapper.
- `lib/mailglass/webhook/telemetry.ex` — `span_with_enrichment/3` enrichment wrapper
  + the single-module lint requirement (moduledoc).
- `lib/mailglass/outbound/projector.ex` — direct post-commit `Phoenix.PubSub.broadcast`
  + `safe_broadcast/2`; the TELE-07 pattern to mirror.
- `lib/mailglass/pub_sub/topics.ex` — `mailglass:`-prefixed per-tenant topic shape.
- `mailglass_admin/lib/mailglass_admin/pub_sub/topics.ex` — admin consumer topic
  module (Phase 48 contract); admin stays pure consumer.
- `test/mailglass/properties/webhook_idempotency_convergence_test.exs` — convergence
  proof structure (sandbox, TRUNCATE, max_runs:1000, generator idiom) to mirror.
- `test/mailglass/properties/idempotency_convergence_test.exs` — alternate sandbox flip
  precedent.
- `credo_checks/no_pii_in_telemetry_meta.ex` — the check to extend to inbound.
- `credo_checks/telemetry_event_convention.ex`, `credo_checks/prefixed_pub_sub_topics.ex`
  — conventions (LINT-06) the new topic must satisfy.
- `.credo.exs` — how checks are path-scoped across packages.
- `lib/mailglass/optional_deps/gen_smtp.ex`, `lib/mailglass/optional_deps.ex` — gateway
  to extend with the MIME parse seam.
- `lib/mailglass/error.ex` and existing error structs (e.g. `lib/mailglass/errors/config_error.ex`)
  — canonical error shape + closed-type discipline the new MIMEError must follow.

### Inbound pipeline (wrap points + persistence)
- `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` — ingress span wrap +
  post-commit broadcast site.
- `mailglass_inbound/lib/mailglass_inbound/router/matcher.ex` — route span wrap.
- `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex` — persist span wrap;
  dedupe index + duplicate guard.
- `mailglass_inbound/lib/mailglass_inbound/execution.ex` — `execute/2` (sync, wrap
  here) vs `dispatch/2` (async); outcome classification.
- `mailglass_inbound/lib/mailglass_inbound/execution/worker.ex` — Oban worker path.
- `mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_record.ex`,
  `.../execution_run.ex`, `.../replay_run.ex` — schemas the convergence proof asserts on.
- `mailglass_inbound/lib/mailglass_inbound/ingress/providers/postmark.ex` — current
  JSON normalize path (MIME must NOT be wired in here).

### Official ecosystem references
- gen_smtp 1.3.0 `mimemail.erl` source —
  `https://raw.githubusercontent.com/gen-smtp/gen_smtp/1.3.0/src/mimemail.erl`
  (`decode/1,2`, options, the `erlang:error`/`throw` clauses).
- `https://hexdocs.pm/gen_smtp/mimemail.html` — mimemail type/option docs.
- `https://hexdocs.pm/stream_data/` — `gen all`, `bind/2`, `member_of/1`,
  `uniq_list_of/2` for the convergence generator.
- `https://postmarkapp.com/developer/webhooks/inbound-webhook` — Postmark inbound
  payload shape (`MessageID` dedupe key) for the generator.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Mailglass.Telemetry.span/3` + `Mailglass.Webhook.Telemetry.span_with_enrichment/3`
  give both telemetry shapes inbound needs — no new emission primitive required.
- `Mailglass.Outbound.Projector` is the exact post-commit direct-broadcast pattern
  TELE-07 should copy (including `safe_broadcast/2`).
- `WebhookIdempotencyConvergenceTest` is a complete structural template for TELE-08.
- `Mailglass.OptionalDeps.GenSmtp` already exists as the gateway — extend it, don't
  create a new optional-dep mechanism.
- The existing error structs provide a canonical `[:type, :message, :cause, :context]`
  shape + closed-type/`__types__` test discipline for the new `MailglassInbound.MIMEError`.
- `MailglassInbound.Execution` already separates sync `execute/2` from async
  `dispatch/2`, so the convergence proof has a deterministic entry point already.

### Established Patterns
- Telemetry events on `[:mailglass(_inbound), :domain, :resource, :action, :start|:stop|:exception]`,
  metadata whitelisted to counts/statuses/IDs/latencies, never PII.
- Optional deps gated through a single `Mailglass.OptionalDeps.*` module with
  `available?/0` + degraded fallback; bare references banned (`NoBareOptionalDepReference`).
- PubSub: typed topic builders only, `mailglass:`-prefixed, per-tenant (`LINT-06`).
- Append-only `mailglass_events`/inbound tables — tests TRUNCATE CASCADE, never UPDATE/DELETE.
- Admin package is a pure PubSub consumer; producers live in core/inbound.

### Integration Points
- Inbound telemetry module → `:telemetry`/`Mailglass.Telemetry` (core hard-dep).
- Inbound post-commit broadcast → `Phoenix.PubSub` server `Mailglass.PubSub` (shared);
  admin LiveView (Phase 48) subscribes to the same per-tenant string.
- `MailglassInbound.MIME` → `Mailglass.OptionalDeps.GenSmtp` → `:mimemail` (Phase 46
  Mailgun/SES is the first consumer).
- `MailglassInbound.MIMEError` → core error contract (CHANGELOG/`@since`/closed-type test).

</code_context>

<specifics>
## Specific Ideas

- Mental model: this phase makes inbound the *observable, idempotent sibling* of the
  outbound webhook ingest seam — same telemetry shapes, same convergence proof, same
  optional-dep gateway discipline. Reuse, don't reinvent.
- The single highest-risk correction surfaced in research: `:mimemail.decode/1`
  raises through both `:error` and `:throw` — a `rescue`-only wrapper would still let
  `bad_content_type`/`bad_disposition` escape and violate MIME-04.
- The two cross-boundary contract calls (the `inbound_record_inserted/1` topic string
  and the new `MIMEError` type) are public API; they are locked here to the
  recommended defaults (D-45-07/08 and D-45-16) and confirmed by the project owner.

</specifics>

<deferred>
## Deferred Ideas

- Wiring `MailglassInbound.MIME` into a provider normalize path → Phase 46
  (Mailgun/SES raw-MIME ingress).
- The admin LiveView that subscribes to the TELE-07 topic → Phase 48.
- `mailglass.inbound.doctor` reporting MIME backend availability (MIME-03) → Phase 49.
- Broader MIME fuzzing / attachment-shape property tests beyond the dedupe
  convergence proof — not needed for this phase's idempotency goal.

</deferred>

---

*Phase: 45-inbound-telemetry-idempotency-foundation*
*Context gathered: 2026-05-22 (assumptions mode)*
