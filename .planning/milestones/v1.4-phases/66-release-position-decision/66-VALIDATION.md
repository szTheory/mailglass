---
phase: 66
slug: release-position-decision
status: audited
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-01
---

# Phase 66 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir built-in) |
| **Config file** | `mix.exs`, `mailglass_inbound/mix.exs` |
| **Quick run command** | `rg -n "1\\.0\\.0|0\\.4\\.0|mix verify\\.stability_contract|mix mailglass\\.publish\\.check --package mailglass_inbound|api_stability\\.md|compatibility-and-deprecations\\.md|release-position decision|feature-growth" .planning/phases/66-release-position-decision mailglass_inbound/CHANGELOG.md .planning/STATE.md .planning/ROADMAP.md` |
| **Full release-gate command** | `mix verify.stability_contract && mix mailglass.publish.check --package mailglass_inbound` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Estimated runtime** | ~120 seconds |

---

## Sampling Rate

- **After every task commit:** Run the quick `rg` smoke command for release-position, changelog, and verification-command references; run `mix verify.stability_contract` when the task touches contract, docs, version, release, or planning-state truth.
- **After every plan wave:** Run `mix verify.stability_contract && mix mailglass.publish.check --package mailglass_inbound`.
- **Before `$gsd-verify-work`:** Both release-blocking lanes must be green and their outputs captured in phase artifacts.
- **Max feedback latency:** 180 seconds for the core stability/publish gate pair.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 66-01-01 | 01 | 1 | REL-01 | T-66-01 | Release decision is based on fresh green stability and publish evidence, not stale assumptions. | integration/process | `rg -n "mix verify\\.stability_contract|mix mailglass\\.publish\\.check --package mailglass_inbound|0\\.3\\.0|1\\.0\\.0" .planning/phases/66-release-position-decision/66-VERIFICATION.md .planning/phases/66-release-position-decision/66-RELEASE-POSITION.md && mix verify.stability_contract && mix mailglass.publish.check --package mailglass_inbound` | yes | green |
| 66-01-02 | 01 | 1 | REL-02 | T-66-02 | Release notes summarize compatibility posture without duplicating or contradicting canonical contract docs. | docs contract | `rg -n "adopter action required|mix verify\\.stability_contract|mix mailglass\\.publish\\.check --package mailglass_inbound|api_stability\\.md|compatibility-and-deprecations\\.md" mailglass_inbound/CHANGELOG.md && mix verify.stability_contract` | yes | green |
| 66-01-03 | 01 | 1 | REL-03 | T-66-03 | Planning state continues blocking broad feature-growth until the release-position decision is closed. | governance/manual | `rg -n "release-position decision|feature-growth|release ceremony|maintenance" .planning/STATE.md .planning/ROADMAP.md` | yes | green |
| 66-02-01 | 02 | 2 | REL-01, REL-02 | T-66-04, T-66-05 | Candidate version truth, README/install pins, changelog, and publish summary remain aligned to the chosen release position. | integration/docs contract | `jq -r '.version, .manifest_version, .source_ref' .planning/publish/mailglass_inbound-publish-summary.json && rg -n '@version "|~> 1\\.0|adopter action required|api_stability\\.md|compatibility-and-deprecations\\.md' mailglass_inbound/mix.exs mailglass_inbound/README.md mailglass_inbound/docs/inbound-install.md mailglass_inbound/CHANGELOG.md && mix verify.stability_contract && mix mailglass.publish.check --package mailglass_inbound` | yes | green |
| 66-02-02 | 02 | 2 | REL-03 | T-66-06 | Planning state preserves the release-governance gate and routes next work to release ceremony/maintenance rather than broad feature growth. | governance/process | `rg -n "release-position decision|feature-growth|release ceremony|maintenance" .planning/STATE.md .planning/ROADMAP.md` | yes | green |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Confirm the final binary release posture is explicit and supported by captured evidence. | REL-01 | The decision is a governance artifact derived from command evidence and cannot be fully inferred by tests. | Read the final release-position artifact and verify it states either `1.0.0` promotion or final `0.x` fallback, cites fresh command evidence, and names the blocker if fallback is chosen. |
| Confirm feature-growth work remains blocked until Phase 66 is closed. | REL-03 | Planning-state language is a project governance constraint, not a runtime behavior. | Run the `rg` command above and inspect `.planning/STATE.md` / `.planning/ROADMAP.md` for explicit release-position gating language. |

---

## Validation Audit 2026-06-01

| Metric | Count |
|--------|-------|
| Gaps found | 2 |
| Resolved | 2 |
| Escalated | 0 |

### Gap Resolution

| Gap | Resolution |
|-----|------------|
| Per-task map still marked executed Phase 66 tasks as `pending`. | Updated task statuses to `green` after cross-checking Phase 66 verification artifacts, release-position artifacts, release notes, version-truth files, publish summary, and planning-state evidence. |
| Plan 02 validation coverage was implicit but not represented in the per-task map. | Added Plan 02 rows for candidate-version parity, operational release notes, publish-proof refresh, and feature-growth gate preservation. |

### Audit Evidence

- `66-VERIFICATION.md` records green final candidate-version results for `mix verify.stability_contract` and `mix mailglass.publish.check --package mailglass_inbound`.
- `66-RELEASE-POSITION.md` records the active `mailglass_inbound` `1.0.0` promotion path and cites Phase 63, Phase 64, Phase 65, and Phase 66 evidence.
- `mailglass_inbound/CHANGELOG.md` records adopter action, verification commands, behavior/operator impact, and canonical compatibility links.
- `.planning/publish/mailglass_inbound-publish-summary.json` records `version=1.0.0`, `manifest_version=1.0.0`, and `source_ref=v1.0.0`.
- `.planning/STATE.md` and `.planning/ROADMAP.md` preserve release-position gating and post-phase release ceremony/maintenance posture.

No new test files were generated because the audit found validation-record gaps, not missing behavioral coverage.

---

## Validation Sign-Off

- [x] All tasks have automated verify or explicit manual governance verification.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Fast smoke feedback latency < 30s; full release-gate feedback latency < 180s.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** audited 2026-06-01
