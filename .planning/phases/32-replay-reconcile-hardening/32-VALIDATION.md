---
phase: 32
slug: replay-reconcile-hardening
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-05
---

# Phase 32 — Validation Strategy

> Per-phase validation contract for replay/reconcile hardening, operator wording, and maintenance-fallback regression coverage.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix.LiveViewTest |
| **Config file** | `config/test.exs` and `mailglass_admin/config/test.exs` |
| **Quick run command** | `mix test test/mailglass/webhook/replay_test.exs test/mailglass/webhook/reconciler_test.exs test/mailglass/operator/timeline_test.exs --warnings-as-errors` and `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors` and `cd mailglass_admin && mix test --warnings-as-errors` |
| **Estimated runtime** | ~30s quick / ~90s full phase scope |

---

## Sampling Rate

- **After every task commit:** run the smallest replay/reconcile command for the files just changed
- **After every plan wave:** rerun the quick phase commands in both projects
- **Before `$gsd-verify-work`:** rerun the full suite commands in both projects
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 32-01-01 | 01 | 1 | MAT-01 | T-32-01, T-32-02 | replay actions deny stale-auth and unauthorized actors before any replay audit rows are appended | LiveView integration | `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 32-01-02 | 01 | 1 | MAT-01 | T-32-03 | replay target resolution distinguishes exact, ambiguous, and unavailable states without implicit selection | LiveView integration | `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 32-02-01 | 02 | 2 | MAT-01 | T-32-04, T-32-05 | operator header/timeline wording separates availability, outcome, and effect without exposing raw audit atoms as final copy | LiveView integration / component regression | `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 32-02-02 | 02 | 2 | MAT-01 | T-32-02, T-32-05 | replay writes requested/succeeded/failed durable audit facts and distinguishes `:replayed` vs `:noop` | Core integration | `mix test test/mailglass/webhook/replay_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 32-03-01 | 03 | 3 | MAT-01 | T-32-06 | reconcile appends `:reconciled` events, remains idempotent, and preserves append-only orphan semantics | Core integration | `mix test test/mailglass/webhook/reconciler_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 32-03-02 | 03 | 3 | MAT-01 | T-32-06, T-32-07 | the Oban-present and Oban-absent reconcile maintenance path matches task behavior, warnings, and docs | Mix task / optional-dep regression | `mix test test/mix/tasks/mailglass_reconcile_test.exs --warnings-as-errors` | ❌ Wave 0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/mix/tasks/mailglass_reconcile_test.exs` — lock the intended Oban-present and Oban-absent fallback semantics
- [ ] Expand `mailglass_admin/test/mailglass_admin/operator_live_test.exs` — lock `ready | choice required | unavailable` and `completed + effect` wording
- [ ] Add focused header/timeline presenter assertions so raw atoms like `:webhook_replay_succeeded` do not leak as final operator copy

---

## Manual-Only Verifications

All phase behaviors are expected to have automated verification.

---

## Threat Model

| ID | Threat | STRIDE | Mitigation | ASVS |
|----|--------|--------|------------|------|
| T-32-01 | stale-auth or unauthorized operator triggers a destructive replay | Spoofing / Elevation of Privilege | action-time `MailglassAdmin.Auth.authorize/2` on `:destructive_action` with no replay audit rows on denial | V2, V3, V4 |
| T-32-02 | cross-tenant replay of another tenant's webhook row | Elevation of Privilege | tenant-scoped target lookup must fail before replay work starts | V4 |
| T-32-03 | ambiguous replay target is guessed automatically | Tampering | preserve ambiguity as `choice required` and require explicit target identity | V5 |
| T-32-04 | operator wording overclaims no-op replay results | Repudiation | presenter mapping uses `completed` plus effect labels like `new work` / `no change` | V1 |
| T-32-05 | raw audit atoms or failure metadata leak directly into operator copy | Information Disclosure | map durable facts through presenter-level wording and keep telemetry/audit metadata PII-free | V1, V5 |
| T-32-06 | reconcile fallback behavior drifts between Oban worker, CLI, warnings, and docs | Denial of Service | one canonical reconcile path with regression tests around optional-dep fallback behavior | V1, V4 |
| T-32-07 | duplicate reconcile side effects rely only on worker scheduling | Tampering / Repudiation | keep append-only idempotency keys and do not trust Oban uniqueness alone | V4 |

---

## Validation Sign-Off

- [x] All tasks have automated verification or explicit Wave 0 coverage
- [x] Sampling continuity: no 3 consecutive tasks without automated verification
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-05
