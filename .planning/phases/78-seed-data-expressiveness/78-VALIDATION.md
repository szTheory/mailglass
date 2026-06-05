---
phase: 78
slug: seed-data-expressiveness
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-04
---

# Phase 78 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Playwright 1.59.1 (e2e) + ExUnit (integration) |
| **Config file** | `mailglass_admin/playwright.config.cjs` · `reference/demo_app/assets/playwright.config.cjs` |
| **Quick run command** | `mix test test/mailglass_admin/operator_live_test.exs` (from `mailglass_admin/`) |
| **Full suite command** | `mix verify.preview` (from `mailglass_admin/`) + `npm run test:e2e` (from `reference/demo_app/assets/`) + `npm run test:operator-browser` (from `mailglass_admin/`) |
| **Estimated runtime** | ~120 seconds (ExUnit ~30s; each Playwright suite ~30–45s) |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/mailglass_admin/operator_live_test.exs` (covers support-card rendering from `summarize_tenant/1`)
- **After every plan wave:** Run `mix verify.preview` in `mailglass_admin/` + `npm run test:e2e` in `reference/demo_app/assets/`
- **Before `/gsd:verify-work`:** Full `npm run test:operator-browser` green — excluding the known pre-existing `operator.spec.js:104` failure per D-10 (failure count must not increase)
- **Max feedback latency:** ~120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 78-01-* | 01 (demo breadth) | 1 | SEED-01 | — / N/A | N/A — synthetic demo data only | integration | `mix test test/mailglass_admin/operator_live_test.exs` | ✅ | ⬜ pending |
| 78-01-* | 01 (demo breadth) | 1 | SEED-01 | — / N/A | N/A | e2e | `npm run test:e2e` (demo) | ✅ | ⬜ pending |
| 78-02-* | 02 (operator depth: inbound + empty tenant) | 1 | SEED-01 | — / N/A | N/A | e2e | `npm run test:operator-browser` | ✅ | ⬜ pending |
| 78-0X-* | (same-commit assertions) | 2 | SEED-02 | — / N/A | N/A | e2e | `npm run test:e2e` + `npm run test:operator-browser` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Note: exact task IDs are assigned by the planner; the rows above bind requirements to their observing commands. All "File Exists ✅" — no Wave 0 test files needed.*

---

## Requirement → Observable Map (from RESEARCH §Validation Architecture)

| Req ID | Behavior | Test Type | Automated Command | Notes |
|--------|----------|-----------|-------------------|-------|
| SEED-01 | All 14 outbound event-type badges seeded (8 currently missing: `:queued`, `:rejected`, `:autoresponded`, `:opened`, `:clicked`, `:complained`, `:unsubscribed`, `:subscribed`) | Visual/e2e | `npm run test:operator-browser` (demo tenant) | Additive via `event!/4`; timeline renders each badge branch |
| SEED-01 | All 6 inbound outcome badges seeded (2 missing: `:ignore`, `:failed`) | Visual/e2e | `npm run test:e2e` (demo) | `:failed` requires `execution_failure:` key via `normalize_execution_attrs/1` |
| SEED-01 | Orphan-backlog Tier-1 support card present | Integration | `mix test test/mailglass_admin/operator_live_test.exs` | From `summarize_tenant/1` |
| SEED-01 | Failed-ingest Tier-1 card present | Integration | Same | Requires `WebhookEvent` with `status: :failed` |
| SEED-01 | Replay-outcome card — all 3 branches (`:replayed`, `:replay_noop`, `:replay_failed`) | Integration | Same | `:webhook_replay_succeeded` + `metadata["outcome"]` / `:webhook_replay_failed` |
| SEED-01 | Reconcile-facts card — BOTH branches (reconciled + still-unmatched) | Integration | Same | Two distinct orphan events; one covered by a `:reconciled` event, one not (`NOT EXISTS` on `reconciled_from_event_id`) |
| SEED-01 | Empty-result tenant zero-state reachable | e2e | Navigate `?tenant_id=<empty>` — empty list assertion | Second tenant, zero rows |
| SEED-01 | Truncation stress rows (recipient ~80ch, subject ~150ch) | e2e | `npm run test:operator-browser` / `npm run test:e2e` | Tailwind `truncate` single-line ellipsis |
| SEED-02 | `demo.spec.js` passes after seed expansion | e2e | `npm run test:e2e` | No assertion value changes needed (breadth-tolerant) |
| SEED-02 | `operator.spec.js` passes after seed expansion + un-skip line 254 | e2e | `npm run test:operator-browser` | Row indices 0–3 protected by append-older (D-07) |
| SEED-02 | Pre-existing `operator.spec.js:104` failure not regressed | e2e | Failure-count check | **D-10 — EXCLUDED from pass criteria; Phase 79 debt** |

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements.* No new test files. The un-skip of `operator.spec.js:254` is a spec modification, not a new file. No bundle rebuild (data-only changes).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Empty-tenant zero-state visual confirmation | SEED-01 | No dedicated automated assertion for the empty-tenant URL today | Navigate operator with `?tenant_id=<empty-tenant>`; confirm empty deliveries list, empty inbound, all-zero support cards, and that the blank-`tenant_id` "Select a tenant…" overview remains separately reachable |
| Full 14-badge visual sweep | SEED-01 | Playwright asserts row/timeline presence, not every badge color | Open the demo operator timeline on the northstar tenant; eyeball each of the 14 event-type badges renders with its color (one-time, optional — screenshot→LLM-critique loop is local/ad-hoc per v1.7 scope) |

*All other phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (none — existing infra covers all)
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
