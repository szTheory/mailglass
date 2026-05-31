---
phase: 62
slug: close-gap-evid-02-evid-03-current-release-trust-proof
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-31
---

# Phase 62 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5) |
| **Config file** | `.credo.exs` for lint; ExUnit via Mix defaults |
| **Quick run command** | `MIX_ENV=test mix test test/mailglass/publish/ci_trust_lane_contract_test.exs` |
| **Full suite command** | `MIX_ENV=test mix test test/mailglass/publish/ci_trust_lane_contract_test.exs test/mailglass/publish/post_publish_smoke_contract_test.exs test/mailglass/publish/maintaining_release_gate_contract_test.exs test/scripts/required_checks_test.exs test/mailglass/install/install_first_preview_smoke_test.exs` |
| **Estimated runtime** | ~60 seconds |

---

## Sampling Rate

- **After every task commit:** Run `MIX_ENV=test mix test test/mailglass/publish/ci_trust_lane_contract_test.exs test/mailglass/publish/post_publish_smoke_contract_test.exs`
- **After every plan wave:** Run full suite command above plus `actionlint .github/workflows/ci.yml .github/workflows/post-publish-smoke.yml`
- **Before `$gsd-verify-work`:** Full suite, targeted lock/version grep, and `(cd reference/host_app && bash ../../scripts/check_clean_baseline_hex_only.sh)` must be green
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 62-01-01 | 01 | 1 | EVID-02/EVID-03 | T-62-01 | Reference host resolves sibling packages from Hex at `mailglass` 1.3.0, `mailglass_admin` 1.3.0, and `mailglass_inbound` 0.3.0 | source + script | `rg -n '"mailglass": \\{:hex, :mailglass, "1\\.3\\.0"|"mailglass_admin": \\{:hex, :mailglass_admin, "1\\.3\\.0"|"mailglass_inbound": \\{:hex, :mailglass_inbound, "0\\.3\\.0"' reference/host_app/mix.lock && (cd reference/host_app && bash ../../scripts/check_clean_baseline_hex_only.sh)` | yes | pending |
| 62-01-02 | 01 | 1 | EVID-02 | T-62-02 | Clean-baseline guard fails stale Hex versions and reports expected vs actual version | contract | `MIX_ENV=test mix test test/mailglass/publish/ci_trust_lane_contract_test.exs` | yes | pending |
| 62-01-03 | 01 | 1 | EVID-03/OPS-02 | T-62-03 | Published trust and release-gate contracts still invoke the Hex/version guard, trust runner, and checkpoint validator without workflow topology drift | contract + lint | `MIX_ENV=test mix test test/mailglass/publish/post_publish_smoke_contract_test.exs test/mailglass/publish/maintaining_release_gate_contract_test.exs test/scripts/required_checks_test.exs && actionlint .github/workflows/ci.yml .github/workflows/post-publish-smoke.yml` | yes | pending |

*Status: pending · green · red · flaky*

---

## Wave 0 Requirements

- [ ] Extend or add focused contract coverage proving `scripts/check_clean_baseline_hex_only.sh` enforces exact expected versions, not Hex source only.
- [ ] Confirm no unrelated lockfile churn beyond `mailglass`, `mailglass_admin`, `mailglass_inbound`, or explicitly reviewed resolver-required patches.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Future live post-publish green-run evidence | EVID-03/OPS-02 | Requires a release workflow run after local drift closure | Observe and record the future green `post-publish-smoke` run and artifact in milestone audit evidence after Phase 62 implementation lands. |
| Live GitHub branch-protection proof | EVID-01 | Credentialed maintainer/server-side operation out of Phase 62 local scope | Preserve as residual audit item; do not plan credentialed branch-protection changes in this phase. |

---

## Validation Sign-Off

- [x] All planned behaviors have automated source/script/contract verification hooks
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers the known missing guard-contract reference
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-31 for planning input
