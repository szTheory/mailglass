---
phase: 45-inbound-telemetry-idempotency-foundation
plan: 02
subsystem: telemetry
tags: [telemetry, pubsub, mailglass_inbound, observability, spans, broadcast]

# Dependency graph
requires:
  - phase: 45-01
    provides: MailglassInbound.TestRepo + inbound config, cross-package Credo coverage (NoPIIInTelemetry + LINT-06 live for inbound), api_stability inventory naming PubSub.Topics
provides:
  - MailglassInbound.Telemetry (single inbound span surface, four named helpers, spans only)
  - MailglassInbound.PubSub.Topics.inbound_record_inserted/1 (typed per-tenant topic builder)
  - four wired inbound spans (ingress/route/persist/execution) with PII-free metadata
  - post-commit Mailglass.PubSub broadcast on :inserted via the typed builder
  - inbound telemetry coverage + raise-safety + broadcast test suite (TELE-01..05, TELE-07)
affects: [45-04 replay convergence property, Phase 48 inbound admin LiveView (subscribes to inbound_record_inserted topic)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Inbound mirrors the outbound seam: single span-surface module (MailglassInbound.Telemetry mirrors Mailglass.Webhook.Telemetry) so NoPIIInTelemetry has one audit module + call sites"
    - "Outcome-enrichment span: the fn returns {result, stop_metadata} so :stop carries the classified outcome the fixed-at-call-time wrapper cannot express"
    - "Post-commit PubSub broadcast outside repo.transact via a typed topic builder + safe_broadcast/2 (rescue + catch :exit), mirroring Outbound.Projector"

key-files:
  created:
    - mailglass_inbound/lib/mailglass_inbound/telemetry.ex
    - mailglass_inbound/lib/mailglass_inbound/pub_sub/topics.ex
    - mailglass_inbound/test/mailglass_inbound/telemetry_test.exs
    - mailglass_inbound/test/mailglass_inbound/pub_sub/topics_test.exs
  modified:
    - mailglass_inbound/lib/mailglass_inbound/router/matcher.ex
    - mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex
    - mailglass_inbound/lib/mailglass_inbound/execution.ex
    - mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex

key-decisions:
  - "execution_span/persist_span/route_span fns must return an explicit {actual_result, stop_metadata} tuple even when actual_result is itself a 2-tuple like {:ok, map} — otherwise the enrichment helper mis-parses {:ok, normalized_result} as {result, stop_metadata}. Caught by the existing mailbox_execution_test (return value must stay {:ok, map}, not :ok)."
  - "ingress span wraps a new private do_call/3 (the old call/2 body) so the span fn can return {conn, stop_metadata} from every branch (success, error, and all three rescue clauses) without restructuring the rescue handling."
  - "telemetry_test starts Phoenix.PubSub named Mailglass.PubSub via start_supervised! only if not already running — the inbound app supervises just a Task.Supervisor and does not start the core PubSub, so the broadcast assertions need a server."
  - "byte_size in ingress stop meta falls back across raw_body (postmark) -> raw_mime (sendgrid) -> 0, so the metric is populated for both providers without retaining body content."

patterns-established:
  - "Inbound span helpers are the only inbound :telemetry.span/3 call sites (D-45-01); the four wrap sites call the named helpers, never :telemetry.span directly."
  - "Latency is supplied by :telemetry.span/3 (:duration in :stop measurements); call sites never hand-compute latency into metadata."

requirements-completed: [TELE-01, TELE-02, TELE-03, TELE-04, TELE-05, TELE-07]

# Metrics
duration: 22min
completed: 2026-05-23
---

# Phase 45 Plan 02: Inbound Telemetry + Idempotency Foundation (Span Surface + Broadcast) Summary

**The single `MailglassInbound.Telemetry` span surface plus the four wired spans (ingress/route/persist/execution) with PII-free metadata, a typed per-tenant PubSub topic builder, and the post-commit record-inserted broadcast — the "mirror the outbound seam" core that makes `mailglass_inbound` observable and feeds the Phase 48 admin LiveView.**

## Performance

- **Duration:** ~22 min
- **Tasks:** 3
- **Files changed:** 8 (4 created, 4 modified) — zero `mix.lock` churn committed

## Accomplishments
- `MailglassInbound.Telemetry` is the single inbound span surface (D-45-01): four named helpers (`ingress_span/2`, `route_span/2`, `persist_span/2`, `execution_span/2`), spans only (no single-emit), copying the `span_with_enrichment/3` body from `Mailglass.Webhook.Telemetry` verbatim (the analog is `defp`, so it cannot be cross-called). `grep -c ":telemetry.execute"` returns 0.
- All four spans are wired at their fixed D-45-02 sites with PII-free stop metadata:
  - **ingress** `[:mailglass_inbound, :ingress, :request, *]` — `{provider, tenant_id, status, byte_size}` (latency from the span)
  - **route** `[:mailglass_inbound, :route, :match, *]` — `{mailbox, candidate_count}` on match, `{status: :no_match, candidate_count}` on miss
  - **persist** `[:mailglass_inbound, :persist, :record, *]` — `{provider, tenant_id, operation (:insert|:dedup_skip), record_type}`
  - **execution** `[:mailglass_inbound, :execution, :run, *]` — `{mailbox, outcome, source}`; wraps `execute/2` (covers both Oban and Task.Supervisor paths), NOT `dispatch/2`
- The `:duplicate` short-circuit at `execution.ex:62` is intact — it still returns `{:ok, %{status: :skipped}}` and emits NO execution span (zero extra ExecutionRun — the D-45-11 convergence invariant the Plan 04 property relies on).
- `MailglassInbound.PubSub.Topics.inbound_record_inserted/1` returns `mailglass:inbound:<tenant>` (D-45-07) with an `is_binary` guard and `@doc since: "0.2.0"`.
- `Ingress.Plug` broadcasts `{:inbound_record_inserted, record_id, %{provider:, record_type: "inbound_record"}}` on `Mailglass.PubSub` post-commit, ONLY on `:inserted`, via the typed builder (never a literal string — LINT-06 / D-45-08). `safe_broadcast/2` copied from `Outbound.Projector` (rescue `ArgumentError`/`RuntimeError` + `catch :exit`) so PubSub unavailability never crashes the already-committed pipeline.
- Telemetry handler raise-safety (TELE-05) is free: `:telemetry.span/3` isolates a raising handler and auto-detaches it. The test attaches a raising handler to the ingress stop event and asserts the pipeline still returns 200/`inserted`.

## Task Commits

Each task was committed atomically:

1. **Task 1: MailglassInbound.Telemetry span surface + PubSub.Topics builder** — `2531dbb` (feat)
2. **Task 2: Wrap the four span sites (route/persist/execution + ingress)** — `e29fabd` (feat)
3. **Task 3: Post-commit broadcast (TELE-07) + telemetry coverage & raise-safety tests (TELE-05)** — `e6f6f21` (feat)

**Plan metadata (this SUMMARY):** committed separately below (worktree mode — STATE.md/ROADMAP.md are the orchestrator's to write post-merge).

## Files Created/Modified
- `mailglass_inbound/lib/mailglass_inbound/telemetry.ex` (created) — the single inbound span surface, four named helpers, copied enrichment body, full whitelist + handler-isolation moduledoc
- `mailglass_inbound/lib/mailglass_inbound/pub_sub/topics.ex` (created) — `inbound_record_inserted/1` typed builder with the LINT-06 prefix note
- `mailglass_inbound/lib/mailglass_inbound/router/matcher.ex` (modified) — `match/2` wrapped in `route_span`, `route_stop_metadata/2` helper
- `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex` (modified) — `repo.transact` wrapped in `persist_span`, `persist_operation/1` helper
- `mailglass_inbound/lib/mailglass_inbound/execution.ex` (modified) — `execute/2` `:inserted` body wrapped in `execution_span`; `:duplicate` short-circuit untouched
- `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` (modified) — `call/2` body extracted to `do_call/3` and wrapped in `ingress_span`; `broadcast_inbound_inserted/1` + `safe_broadcast/2`; post-commit prose in moduledoc
- `mailglass_inbound/test/mailglass_inbound/telemetry_test.exs` (created) — TELE-01..05 + TELE-07 coverage
- `mailglass_inbound/test/mailglass_inbound/pub_sub/topics_test.exs` (created) — exact topic string + binary guard

## Decisions Made
See `key-decisions` in frontmatter. The load-bearing one: the enrichment helper pattern-matches `{result, %{} = stop_metadata}`, so any span fn whose real result is itself `{:ok, some_map}` (execution, persist, route) MUST return an explicit `{actual_result, stop_metadata}` tuple — otherwise `{:ok, normalized_result}` is silently mis-parsed as `result = :ok`. The RED for this was the existing `mailbox_execution_test` going from `{:ok, %{outcome: ...}}` to `:ok`; fixed by returning the explicit tuple in `execute/2`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Execution span fn returned the result un-tupled, collapsing `{:ok, map}` to `:ok`**
- **Found during:** Task 2
- **Issue:** The first `execution_span` wrap returned the bare `{:ok, normalized_result}` from the fn. The enrichment helper matches `{result, %{} = stop_metadata}`, so it read `result = :ok` and `stop_metadata = normalized_result` — `execute/2` then returned `:ok` instead of `{:ok, %{outcome: ...}}`. Four `mailbox_execution_test` cases failed (the planned "return values unchanged" guard caught it).
- **Fix:** Return an explicit `{result, stop_metadata}` tuple from the span fn. Applied the same explicit-tuple discipline to the persist and route spans (they too return 2-tuple results).
- **Files modified:** mailglass_inbound/lib/mailglass_inbound/execution.ex
- **Verification:** Full inbound suite back to 0 failures (68, then 78 with the new tests).
- **Committed in:** e29fabd

**2. [Rule 3 - Blocking] Mailglass.PubSub not started in inbound test env**
- **Found during:** Task 3
- **Issue:** The broadcast goes to `Mailglass.PubSub`, but the inbound app supervises only a `Task.Supervisor` and the inbound `test_helper.exs` does not start the core PubSub. The broadcast assertions had no server to fan out through.
- **Fix:** The telemetry_test `setup` starts `{Phoenix.PubSub, name: Mailglass.PubSub}` via `start_supervised!` only when not already running. Kept out of `test_helper.exs` (not in this plan's file list) to avoid touching shared test bootstrap that other Wave-1 plans may also edit.
- **Files modified:** mailglass_inbound/test/mailglass_inbound/telemetry_test.exs
- **Verification:** broadcast assert_receive / refute_receive pass.
- **Committed in:** e6f6f21

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking). No scope creep — both were necessary to complete the planned wrapping/testing.
**Impact on plan:** None on scope. The bug fix established the explicit-tuple discipline now documented as a pattern.

## Issues Encountered
- **Worktree `mix deps.get` rewrites the core `mix.lock` (same as 45-01).** Running `mix deps.get` at the worktree root (needed for `mix credo` / core-dep compilation) re-resolved several core deps (db_connection, decimal, plug_crypto, …) to newer versions under the local Elixir 1.19/OTP 28 toolchain. This is out of scope for 45-02. The committed core `mix.lock` was restored to the phase base (`md5 289613a4…`) before every staging step; the diff for all three commits contains zero `mix.lock` changes. The inbound `mix.lock` was unchanged throughout (no new deps this plan).
- **TELE-05 test emits a `:telemetry` handler-failure log line.** The raising-handler test deliberately raises inside an attached handler; `:telemetry.span/3` catches it, logs `[:telemetry, :handler, :failure]` (visible as a stacktrace in test output), and auto-detaches the handler. This is the contract being proven, not a test failure — the test asserts the pipeline still returns 200/`inserted` and passes.

## Threat Flags
None — no new security-relevant surface beyond the plan's threat model. The mitigations land as designed: telemetry metadata whitelist (T-45-04, asserted PII-free by the new tests + NoPIIInTelemetry), PubSub payload PII-free (T-45-05), tenant-scoped topic (T-45-06), raising-handler isolation (T-45-07), `safe_broadcast/2` accepting PubSub-down (T-45-08), and builder-not-literal at the broadcast site (T-45-09).

## Known Stubs
None — every span site is wired to real metadata derived from existing computed values, and the broadcast carries the real committed record id + provider. No placeholder/empty data.

## Self-Check: PASSED

- All 4 created files present on disk; all 4 modified files present.
- All 3 task commits present in git history (2531dbb, e29fabd, e6f6f21).
- Core `mix.lock` confirmed identical to phase base (md5 289613a4…) — no dependency churn committed.
- Full inbound suite: 78 tests, 0 failures. `mix credo --strict`: 0 issues across 365 files.

---
*Phase: 45-inbound-telemetry-idempotency-foundation*
*Completed: 2026-05-23*
