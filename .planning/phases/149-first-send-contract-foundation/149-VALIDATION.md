---
phase: 149
slug: first-send-contract-foundation
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-08-02
---

# Phase 149 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit under Mix 1.19.5 / OTP 28 |
| **Config file** | `test/test_helper.exs`, `config/test.exs` |
| **Quick run command** | `mix test test/mailglass/outbound/preflight_test.exs test/mailglass/outbound/deliver_later_test.exs test/mailglass/renderer_test.exs test/mailglass/tenancy_test.exs --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Estimated runtime** | Measure on the first execution of each focused command; keep focused feedback below 60 seconds |

---

## Sampling Rate

- **After every task commit:** Run the focused test file(s) named by that task's `<automated>` verification.
- **After every plan wave:** Run `mix test test/mailglass/outbound/preflight_test.exs test/mailglass/outbound/deliver_later_test.exs test/mailglass/renderer_test.exs test/mailglass/tenancy_test.exs --warnings-as-errors`.
- **Before `$gsd-verify-work`:** `mix test --warnings-as-errors` must be green.
- **Max feedback latency:** 60 seconds for focused checks; record and split any slower task-level command.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 149-01-01 | 149-01 | 1 | FIRST-01 | T-149-01 | Only configured `SingleTenant` may normalize an unstamped caller to tenant `"default"` | integration | `mix test test/mailglass/outbound/preflight_test.exs test/mailglass/outbound/deliver_later_test.exs --warnings-as-errors` | ✅ extend | ⬜ pending |
| 149-01-02 | 149-01 | 1 | FIRST-02 | T-149-01 | Custom tenancy remains fail-closed for missing, invalid, or unrestorable context | unit + integration | `mix test test/mailglass/tenancy_test.exs test/mailglass/outbound/preflight_test.exs --warnings-as-errors` | ✅ extend | ⬜ pending |
| 149-02-01 | 149-02 | 2 | FIRST-03 | T-149-02 | Every zero- or multi-recipient shape across `to`/`cc`/`bcc` is rejected without selecting or dropping an address | unit | `mix test test/mailglass/outbound/preflight_test.exs --warnings-as-errors` | ✅ extend | ⬜ pending |
| 149-02-02 | 149-02 | 2 | FIRST-04 / FIRST-07 | T-149-03 / T-149-04 | Recipient/body rejection precedes rendering, limits, persistence, jobs, and provider dispatch; unsupported shapes use bounded non-PII errors | unit + integration | `mix test test/mailglass/outbound/preflight_test.exs test/mailglass/outbound/deliver_later_test.exs --warnings-as-errors` | ✅ extend | ⬜ pending |
| 149-03-01 | 149-03 | 3 | FIRST-05 | T-149-04 | Explicit plaintext survives and text-only messages remain sendable | unit + integration | `mix test test/mailglass/renderer_test.exs test/mailglass/outbound/preflight_test.exs --warnings-as-errors` | ✅ extend | ⬜ pending |
| 149-03-02 | 149-03 | 3 | FIRST-06 | T-149-04 | Plaintext generation and CSS inlining settings behave identically across render, sync, async, and preview | unit + integration + LiveView | `mix test test/mailglass/renderer_test.exs test/mailglass/outbound_test.exs test/mailglass/outbound/deliver_later_test.exs mailglass_admin/test/mailglass_admin/preview_live_test.exs --warnings-as-errors` | ✅ extend | ⬜ pending |
| 149-04-01 | 149-04 | 4 | FIRST-01..FIRST-07 | T-149-01 / T-149-02 / T-149-04 | Stable API, authoring, and tenancy docs match the tested typed-error and preflight contract | docs + contract regression | `mix docs && mix test test/mailglass/outbound/preflight_test.exs --warnings-as-errors` | ✅ extend | ⬜ pending |
| 149-04-02 | 149-04 | 4 | FIRST-01 / FIRST-05 / FIRST-06 | T-149-04 | Getting-started, jobs, and preview docs match tested renderer behavior without future-phase claims | docs + integration | `mix docs && mix test test/mailglass/renderer_test.exs mailglass_admin/test/mailglass_admin/preview_live_test.exs --warnings-as-errors` | ✅ extend | ⬜ pending |

*Task IDs, plans, and waves are reconciled after PLAN.md generation. Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky.*

## Spec-less Edge-Probe Disposition — 11 Rows

This is the canonical no-silent-drop mapping for the deterministic fallback report generated from FIRST-01 through FIRST-07. Every original row appears exactly once. All rows are covered by executable phase work; none is deferred to Phase 150 or 151.

| Row | Requirement | Category | Original probe | Disposition | Concrete task / automated test | Observable must-have |
|---|---|---|---|---|---|---|
| EP-01 | FIRST-01 | unclassified | unclassified — review manually | COVERED | 149-01-01 — `mix test test/mailglass/outbound/preflight_test.exs test/mailglass/outbound/deliver_later_test.exs --warnings-as-errors` | Unstamped SingleTenant sync and durable-async selection both persist tenant `"default"`. |
| EP-02 | FIRST-02 | unclassified | unclassified — review manually | COVERED | 149-01-02 — `mix test test/mailglass/tenancy_test.exs test/mailglass/outbound/preflight_test.exs --warnings-as-errors` | Missing, invalid, and worker-restoration-loss custom context returns typed `:unstamped` and creates no send side effect. |
| EP-03 | FIRST-03 | adjacency | When two things are exactly equal or just touch, do they merge, collide, or separate? | COVERED | 149-02-01 — `mix test test/mailglass/outbound/preflight_test.exs --warnings-as-errors` | Exactly one entry passes; two byte-equal addresses remain two entries and reject without deduplication. |
| EP-04 | FIRST-03 | empty | What is the result for empty, single-element, or null input? | COVERED | 149-02-01 — `mix test test/mailglass/outbound/preflight_test.exs --warnings-as-errors` | Nil/empty collections count as zero and reject; one entry in any one native recipient field passes. |
| EP-05 | FIRST-03 | ordering | When elements compare equal, is output order specified and stable? | COVERED | 149-02-01 — `mix test test/mailglass/outbound/preflight_test.exs --warnings-as-errors` | Preflight neither sorts nor selects; original to/cc/bcc contents and order remain unchanged on pass and rejection. |
| EP-06 | FIRST-04 | boundary | What happens exactly at each min/max/threshold — and one step either side? | COVERED | 149-02-01/149-02-02 — `mix test test/mailglass/outbound/preflight_test.exs test/mailglass/outbound/deliver_later_test.exs --warnings-as-errors` | Counts 0/1/2 and a larger count pin the exact recipient threshold, and every rejected count produces zero named effects. |
| EP-07 | FIRST-04 | precision | Where can precision loss, overflow, or rounding/tie-breaking occur — and what is the exact contract (e.g. half-up vs half-to-even, ceil/floor/truncate)? | COVERED | 149-02-01/149-02-02 — `mix test test/mailglass/outbound/preflight_test.exs test/mailglass/outbound/deliver_later_test.exs --warnings-as-errors` | Cardinality uses the exact integer entry count with no rounding/coercion; rejection leaves exact zero deltas for rows, jobs/tasks, limiter use, render events, and Fake deliveries. |
| EP-08 | FIRST-05 | empty | What is the result for empty, single-element, or null input? | COVERED | 149-02-02/149-03-01 — `mix test test/mailglass/outbound/preflight_test.exs test/mailglass/renderer_test.exs --warnings-as-errors` | Both bodies absent/blank reject; one supported nonblank body passes; blank text on HTML-only input is absent for conditional generation. |
| EP-09 | FIRST-05 | encoding | Whose definition of length/equality applies — bytes, code points, grapheme clusters, or normalized form? | COVERED | 149-02-02/149-03-01 — `mix test test/mailglass/outbound/preflight_test.exs test/mailglass/renderer_test.exs --warnings-as-errors` | Bodies must be valid UTF-8; valid authored Unicode plaintext is preserved byte-for-byte without normalization. |
| EP-10 | FIRST-06 | unclassified | unclassified — review manually | COVERED | 149-03-01/149-03-02 — `mix test test/mailglass/renderer_test.exs test/mailglass/outbound_test.exs test/mailglass/outbound/deliver_later_test.exs mailglass_admin/test/mailglass_admin/preview_live_test.exs --warnings-as-errors` | Plaintext and CSS switches expose the same truth table in direct, sync, async-preparation, and preview consumers. |
| EP-11 | FIRST-07 | unclassified | unclassified — review manually | COVERED | 149-02-02 — `mix test test/mailglass/outbound/preflight_test.exs test/mailglass/outbound/deliver_later_test.exs --warnings-as-errors` | Every invalid body/envelope shape returns bounded typed preflight error with zero Delivery/Event rows, jobs/tasks, render work, limiter use, or Fake dispatch. |

---

## Planned Verification Work (No Wave 0 Dependency)

No pre-execution Wave 0 scaffold is required because every target test file and assertion surface already exists. The following work remains pending in its owning execution wave:

- [ ] Wave 2 / Task 149-02-02 confirms or adds a test-local stable assertion seam proving preflight rejection inserts zero Oban jobs.
- [ ] Wave 3 / Task 149-03-02 extends `mailglass_admin/test/mailglass_admin/preview_live_test.exs` test-first with config-isolated renderer-parity regressions for `renderer.plaintext` and `renderer.css_inliner`.
- [ ] Wave 3 / Tasks 149-03-01 and 149-03-02 add config-isolated renderer tests that restore application environment and relevant Mailglass config cache state after every case.

---

## Manual-Only Verifications

All phase behaviors have automated verification. Any Task.Supervisor/Fake-adapter ownership warnings observed during research must remain non-failing and must not replace row/job/provider side-effect assertions.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verification; no Wave 0 dependency is claimed
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Planned Wave 2/3 coverage is assigned test-first inside the corresponding implementation tasks
- [x] No watch-mode flags
- [x] Feedback latency target is below 60s for focused checks and must be measured during execution
- [x] Per-task map reconciled to final PLAN task IDs
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
