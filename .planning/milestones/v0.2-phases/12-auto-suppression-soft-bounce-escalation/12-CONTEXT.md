# Phase 12: Auto-Suppression + Soft-Bounce Escalation - Context

**Gathered:** 2026-04-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Automatically project suppression state from webhook events and soft-bounce history without breaking the append-only event model or tenant isolation guarantees.

This phase delivers:
- Auto-suppression inserts from webhook-driven `:bounced`, `:complained`, and `:unsubscribed` events
- Async soft-bounce escalation from repeated `:deferred` events
- A per-tenant suppression resync task
- Stronger pre-send suppression enforcement
- Permanent complaint rows enforced structurally

This phase does **not** add:
- Preference-center UX
- Provider-specific suppression mirroring beyond mailglass's normalized event model
- Domain-wide automatic suppressions
- Arbitrary policy callbacks or a generic rules engine

</domain>

<decisions>
## Implementation Decisions

### Event-to-suppression scope policy

- **D-12-01:** Auto-suppression uses a **mixed scope model** by event type, not a one-size-fits-all address block.
- **D-12-02:** `:unsubscribed` projects to `scope: :address_stream` using the originating delivery's `stream`.
- **D-12-03:** `:complained` projects to `scope: :address`.
- **D-12-04:** hard `:bounced` projects to `scope: :address`.
- **D-12-05:** Domain-wide auto-suppression is explicitly out of scope for Phase 12. Domain scope remains available only for manual/operator policy rows.
- **D-12-06:** mailglass should not mirror provider-specific unsubscribe group/category semantics. Normalize to mailglass stream semantics only.

**Why:** This is the best least-surprise behavior for a Phoenix email library. A bulk unsubscribe should not block password resets or receipts, but a complaint or hard bounce is an address-level deliverability signal and should block broadly.

### Event-to-reason translation

- **D-12-07:** Keep event taxonomy and suppression reasons as separate closed sets with an explicit translation layer:
  - `:complained -> :complaint`
  - `:unsubscribed -> :unsubscribe`
  - hard `:bounced -> :hard_bounce`
- **D-12-08:** The roadmap/requirements wording around `reason: :complained` is incorrect relative to the current schema and must be corrected during planning/implementation.
- **D-12-09:** Auto-suppression logic must centralize this translation in one place. No scattered ad hoc mappings.

**Why:** The current code already distinguishes event types from suppression reasons. Keeping that split is fine, but only if the conversion is explicit and singular.

### Soft-bounce escalation policy

- **D-12-10:** Count only `:deferred` events toward soft-bounce escalation. Do **not** reinterpret hard `:bounced` events as soft.
- **D-12-11:** The default escalation policy remains `{count: 5, window_days: 7, action: :hard_suppress}`.
- **D-12-12:** Support only a **narrow** config escape hatch in v0.2:
  - `:hard_suppress`
  - `{:suppress_for, days: pos_integer()}`
- **D-12-13:** Do not add arbitrary callbacks, custom modules, or policy DSLs in this phase.
- **D-12-14:** Soft-bounce escalation runs asynchronously via Oban only. No synchronous evaluation inside the webhook request cycle.
- **D-12-15:** Escalation rows must be distinguishable from true hard-bounce rows via source and/or metadata so later removal policy can treat them differently without ambiguity.

**Why:** This keeps the default conservative, keeps the public surface small, and avoids turning mailglass into a generalized policy engine.

### Manual removal policy

- **D-12-16:** `:complaint` suppressions are non-removable through the generic public API/operator tooling.
- **D-12-17:** `:unsubscribe` suppressions are also non-removable through the generic public API/operator tooling.
- **D-12-18:** `:hard_bounce`, soft-bounce escalation rows, `:manual`, and operator-authored `:policy` rows are removable.
- **D-12-19:** Removal must be explicit and auditable. No silent delete paths.
- **D-12-20:** A future fresh-consent or resubscribe flow is distinct from generic suppression removal and is out of scope for this phase.

**Why:** This separates consent/abuse suppressions from deliverability suppressions. It matches the project's audit-led posture while still allowing recovery from transient or operator-created blocks.

### Resync operator contract

- **D-12-21:** `mix mailglass.suppressions.resync` requires `--tenant-id`. This is mandatory and non-negotiable.
- **D-12-22:** The task should use concise default output, with optional `--dry-run` and `--verbose`.
- **D-12-23:** `--dry-run` must reuse the exact same candidate-selection path as apply mode and report `would_insert`.
- **D-12-24:** Do not add `--quiet` in this phase.
- **D-12-25:** The task must stamp tenant context explicitly and scope all reads/writes through `Tenancy.scope/2`. Do not rely on ambient `Tenancy.current/0`.
- **D-12-26:** Default scan window remains last 90 days, with `--from` / `--to` ISO-8601 overrides.

**Why:** This matches the current Mix-task tone in mailglass: strict CLI validation, fail-loud behavior, and concise operator-readable output.

### Downstream agent discretion

- **D-12-27:** Default to agent discretion for routine implementation choices in this phase.
- **D-12-28:** Downstream agents should only escalate to the user when a decision would materially alter:
  - public API shape
  - compliance semantics
  - persistence invariants
  - tenant isolation guarantees
  - user-visible behavior that violates least surprise
- **D-12-29:** If multiple implementation approaches satisfy the locked decisions above, prefer the most idiomatic Elixir/Ecto/Phoenix approach with the smallest surface area and clearest operator UX.

### the agent's Discretion

- Exact Oban worker naming, queue name, and internal module layout
- Exact telemetry metadata keys, as long as they remain whitelist-safe and non-PII
- The precise storage shape used to mark soft-bounce escalation rows, as long as they remain distinguishable from true hard-bounce rows
- The exact formatting of `mix mailglass.suppressions.resync` default and verbose output
- Whether the narrow soft-bounce config escape hatch lands as one config key or a small validated keyword subtree

</decisions>

<specifics>
## Specific Ideas

- A bulk unsubscribe should feel like "stop this class of mail," not "silently block all future email forever."
- Complaint and hard-bounce handling should be boring, strict, and hard to misuse.
- Soft-bounce logic should be conservative by default, but not so magical that operators cannot understand or override it.
- Repair tooling should feel like a normal Mix task, not a mini admin console.
- Great DX here means:
  - clear structured errors
  - explicit operator actions
  - no hidden cross-tenant behavior
  - no policy engine disguised as configuration

### Examples

- **Unsubscribe example:** `alice@example.com` unsubscribes from a `:bulk` delivery. mailglass inserts an `:address_stream` suppression for `:bulk`. Password resets on `:transactional` still send.
- **Complaint example:** `bob@example.com` triggers a spam complaint. mailglass inserts an address-wide suppression with no expiry and generic removal rejects it.
- **Soft-bounce example:** `carol@example.com` accumulates 5 `:deferred` events inside 7 days. Oban inserts a suppression row marked as escalation-derived, using the configured action.
- **Resync example:** `mix mailglass.suppressions.resync --tenant-id acme --dry-run` prints a concise preview with `scanned`, `would_insert`, and `existing`, then `--verbose` can show more detail when needed.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 12 requirements
- `.planning/ROADMAP.md` — Phase 12 goal, success criteria, and six planned work items
- `.planning/REQUIREMENTS.md` — `SUPP-01` through `SUPP-05`
- `.planning/STATE.md` — active milestone state and Phase 12 correction notes

### Prior phase context
- `.planning/phases/11-rfc-8058-list-unsubscribe/11-CONTEXT.md` — unsubscribe lifecycle decisions that feed `:unsubscribed` auto-suppression behavior
- `.planning/phases/08-release-engineering-hardening/08-CONTEXT.md` — recent example of context style and decision rigor

### Core code paths
- `lib/mailglass/webhook/ingest.ex` — event-first `Ecto.Multi` shape that Phase 12 must preserve
- `lib/mailglass/webhook/providers/postmark.ex` — `:deferred`, `:complained`, `:unsubscribed`, and hard-bounce mapping behavior
- `lib/mailglass/webhook/providers/sendgrid.ex` — same for SendGrid
- `lib/mailglass/suppression.ex` — pre-send suppression facade
- `lib/mailglass/suppression/entry.ex` — suppression scopes and reasons
- `lib/mailglass/suppression_store/ecto.ex` — current read/write semantics including expiry handling
- `lib/mailglass/outbound/delivery.ex` — delivery stream field used by `:address_stream` suppressions
- `lib/mailglass/tenancy.ex` — tenant scoping and stamping rules
- `lib/mix/tasks/mailglass.reconcile.ex` — example Mix-task operator contract
- `lib/mix/tasks/mailglass.gen.unsubscribe.ex` — example strict CLI validation and concise output style

### Test anchors
- `test/mailglass/properties/webhook_idempotency_convergence_test.exs` — replay convergence expectations
- `test/mailglass/suppression_store/ecto_test.exs` — scope semantics and expiry behavior
- `test/mailglass/suppression_test.exs` — current pre-send blocked behavior

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `Mailglass.Webhook.Ingest` already owns the correct event-first transaction boundary. Phase 12 should extend that Multi rather than introducing a second write path.
- `Mailglass.Suppression.Entry` already has the right scope set for the recommended design: `:address`, `:domain`, `:address_stream`.
- `Mailglass.SuppressionStore.Ecto` already supports expiry semantics, making a narrow temporary-escalation option feasible without new primitives.
- `Mailglass.OptionalDeps.Oban` already provides the right optional-dep gateway for async escalation work.
- Existing Mix tasks already establish the operator UX baseline: strict args, readable output, fail loud.

### Established Patterns

- mailglass prefers normalized, provider-agnostic domain behavior over mirroring raw ESP semantics.
- The codebase consistently uses explicit tenant scoping and treats ambient tenant defaults as a footgun outside carefully bounded contexts.
- Public error handling is structured and closed-set driven, so suppression removal and pre-send failures should continue that style.
- Optional behavior is gated narrowly through config and optional-dep modules, not broad extension callbacks.

### Integration Points

- Auto-suppression should attach after projector application inside webhook ingest, never before event append.
- `:unsubscribed` suppression scope depends on the delivery's stored `stream`, so delivery lookup/projection shape matters.
- Soft-bounce escalation should query `mailglass_events` by tenant/address/time window and then write to `mailglass_suppressions` through the same normalized store path.
- Resync should project from `mailglass_events` into `mailglass_suppressions` with idempotent inserts and explicit tenant stamping.

</code_context>

<deferred>
## Deferred Ideas

- Fresh-consent / resubscribe workflow for previously unsubscribed recipients
- Provider-specific unsubscribe-group/category mirroring
- Domain-wide automatic suppressions
- Arbitrary suppression policy callbacks or a generalized rules DSL
- Richer support/admin UX for suppression management beyond concise Mix-task/operator flows
- Project-wide GSD methodology codification of the "decisive by default, escalate only on high-impact surprises" preference if later desired outside this phase

</deferred>

---

*Phase: 12-auto-suppression-soft-bounce-escalation*
*Context gathered: 2026-04-28*
