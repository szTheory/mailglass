---
phase: 130
slug: supply-chain-workflow-hygiene
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-01
---

# Phase 130 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> This is a CI/tooling phase — "validation" = ExUnit contract/meta-tests + simulated-advisory
> tests + gate assertions that prove each guard behaves (advisory-on-PR, block-at-publish, fail-open).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) + YAML/shell assertions |
| **Config file** | `mix.exs` (root); `test/support/ci_lanes.ex` (lane manifest) |
| **Quick run command** | `mix test test/mailglass/publish/ test/mailglass/ci_parity_drift_test.exs` |
| **Full suite command** | `mix test` (root package) |
| **Estimated runtime** | ~60–120 seconds |

---

## Sampling Rate

- **After every task commit:** Run the relevant targeted test (per-task command below)
- **After every plan wave:** Run `mix test test/mailglass/publish/ test/mailglass/ci_parity_drift_test.exs`
- **Before `/gsd-verify-work`:** publish.check + CILanes parity tests green; `actionlint` self-check + `mix deps.audit` runnable locally
- **Max feedback latency:** ~120 seconds

---

## Per-Task Verification Map

*(Task IDs are illustrative — the planner assigns final IDs. Every SUPPLY item maps to at least one automated observable.)*

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 130-01-* | 01 | 1 | SUPPLY-01 | — | mix_audit advisory PR lane cannot red a PR; publish gate blocks on unfixable advisory | unit + gate | `mix test test/mailglass/publish/` | ✅ | ⬜ pending |
| 130-01-* | 01 | 1 | SUPPLY-01 | — | new `deps_audit_advisory` lane registered in CILanes + parity test green | unit | `mix test test/mailglass/ci_parity_drift_test.exs` | ✅ | ⬜ pending |
| 130-01-* | 01 | 1 | SUPPLY-03 | — | stale allowlist entry → loud warn always + publish block; OSV outage → fail-open | unit | `mix test test/mailglass/publish/*audit*` | ✅ | ⬜ pending |
| 130-02-* | 02 | 1 | SUPPLY-02 | — | dependabot watches admin+inbound sibling locks, not reference/ | source assert | `grep -c 'directory:' .github/dependabot.yml` (==4) | ✅ | ⬜ pending |
| 130-02-* | 02 | 1 | SUPPLY-04 | — | actionlint fails a malformed workflow PR; dependency-review advisory step present | source + behavior | `actionlint` on a fixture bad workflow exits non-zero | ✅ | ⬜ pending |
| 130-02-* | 02 | 1 | SUPPLY-05 | — | 1.19/OTP28 row runs push+cron only (never PR), never blocks; LD-13 invariant documented | source assert | `grep` job `if:` guard + advisory-set membership | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `:mix_audit` dependency added (root package) — required before `mix deps.audit` runs
- [ ] Simulated/fixture unfixable-advisory seam in the publish.check audit path (for the PR-vs-publish asymmetry test) — extend the existing `AuditAllowlistTest` seam rather than adding a new harness

*If the existing `AuditAllowlistTest` + `ci_parity_drift_test.exs` seams cover the assertions, no new framework work is needed — only new test cases.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| A real green CI run of the new advisory lane on a pushed `phase/130` branch | SUPPLY-01/05 | GitHub Actions triggers can't be fully simulated in ExUnit | Push `phase/130`, confirm `deps_audit_advisory` + advisory-matrix rows are non-required and green/non-blocking |
| OSV.dev live API response for the cowlib advisory ID | SUPPLY-03 | Depends on third-party API shape (research open question) | Verify `osv_get/1` resolves the real advisory ID; confirm fail-open on forced network error |

*Everything else has an automated observable (ExUnit or source/grep assertion).*

---

## Validation Sign-Off

- [ ] Every SUPPLY-01..05 requirement has an automated observable or a documented manual verification
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers the mix_audit dep + simulated-advisory seam
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
