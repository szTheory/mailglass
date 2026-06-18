---
phase: 109
slug: foundations-gate-tightening
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-18
---

# Phase 109 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Mix/ExUnit plus Playwright Test |
| **Config file** | `mailglass_admin/playwright.config.cjs` |
| **Quick run command** | `bash mailglass_admin/scripts/check-conformance.sh && cd mailglass_admin && mix test test/mailglass_admin/ratchet_baseline_test.exs --warnings-as-errors` |
| **Full suite command** | `cd mailglass_admin && mix verify.preview && npm run test:operator-browser` |
| **Estimated runtime** | ~90-240 seconds after deps and browsers are present |

---

## Sampling Rate

- **After every task commit:** Run the focused gate for the file family touched:
  `bash mailglass_admin/scripts/check-conformance.sh` for token/HEEx/gate work,
  `cd mailglass_admin && mix test test/mailglass_admin/ratchet_baseline_test.exs --warnings-as-errors`
  for ratchet schema/baseline work, or
  `cd mailglass_admin && npm run test:operator-browser -- --grep "<focused structural grep>"`
  for Playwright structural work.
- **After every plan wave:** Run
  `cd mailglass_admin && mix verify.support_contract.admin` and
  `bash mailglass_admin/scripts/check-conformance.sh`.
- **Before `/gsd:verify-work`:** Run
  `cd mailglass_admin && mix verify.preview && npm run test:operator-browser`.
- **Max feedback latency:** Keep focused checks under 5 minutes; run full suite only at wave/phase gates.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 109-REL-01 | TBD | 1 | REL-01 | T-109-01 | PR #86 baseline is merged before local uplift code lands; post-merge required CI is green or advisory failures are documented separately. | SCM/CI | `gh pr view 86 --json state,mergedAt,mergeCommit,statusCheckRollup` and `gh run list --workflow CI --branch main --limit 1` | yes | pending |
| 109-FND-01 | TBD | 1 | FND-01 | T-109-02 | Modal/toast stacking uses semantic layers and literal `z-*` HEEx utilities are rejected. | grep + Playwright | `bash mailglass_admin/scripts/check-conformance.sh`; `cd mailglass_admin && npm run test:operator-browser -- --grep "replay modal"` | needs extension | pending |
| 109-FND-02 | TBD | 1 | FND-02 | T-109-03 | Focus, motion, elevation, and overlay values use semantic tokens/utilities with no copied raw focus-ring idioms. | grep + browser | `bash mailglass_admin/scripts/check-conformance.sh`; `cd mailglass_admin && npm run test:operator-browser -- --grep "visible focus"` | needs extension | pending |
| 109-FND-03 | TBD | 1 | FND-03 | T-109-04 | Type, spacing, radius, shadow, border, and color one-offs fail the conformance lane. | grep + bundle | `bash mailglass_admin/scripts/check-conformance.sh && cd mailglass_admin && mix verify.preview` | needs extension | pending |
| 109-FND-04 | TBD | 2 | FND-04 | T-109-05 | `system` is CSS/root-layer behavior only: no explicit `data-theme`, no JS hook, no picker UI. | ExUnit + Playwright | `cd mailglass_admin && mix test test/mailglass_admin/preview_live_test.exs --warnings-as-errors`; `cd mailglass_admin && npm run test:operator-browser -- --grep "system"` | needs extension | pending |
| 109-FND-05 | TBD | 2 | FND-05 | T-109-06 | Tightened gates, ratchet schema v3/system axis, and WCAG 2.2 structural checks prove green before any pillar re-score. | shell + ExUnit + Playwright | `bash mailglass_admin/scripts/check-conformance.sh`; `cd mailglass_admin && mix test test/mailglass_admin/ratchet_baseline_test.exs --warnings-as-errors`; `cd mailglass_admin && npm run test:operator-browser` | needs extension | pending |

*Status: pending, green, red, flaky.*

---

## Wave 0 Requirements

- [ ] `mailglass_admin/scripts/check-conformance.sh` - add Z-INDEX, FOCUS-RING, SCOPE/isolation, and wider TYPE/SPACING hard gates after current violations are consolidated.
- [ ] `mailglass_admin/test/mailglass_admin/ratchet_baseline_test.exs` - bump theme/schema expectations to include `system`.
- [ ] `mailglass_admin/docs/ui-baseline-scores.json` - seed `system` cells in both `prior` and `current` by copying existing light/dark scores; do not re-score pillars.
- [ ] `mailglass_admin/e2e/structural.spec.js` - add system-theme, WCAG 2.2 focus-not-obscured/target-size, and modal panel-above-scrim assertions.
- [ ] Local dependency readiness - run `cd mailglass_admin && mix deps.get` before ExUnit validation if stale `floki` or `premailex` lock mismatches recur.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| PR #86 admin merge decision | REL-01 | Requires repository admin authority and branch-protection override judgment. | Before uplift code commits, run `gh pr view 86 --json state,mergeable,reviewDecision,statusCheckRollup`, merge with the approved admin path, then confirm the merge SHA's required checks or latest main CI. |
| Advisory main CI failures | REL-01 | Scheduled/advisory failures may not block the phase but must be explicitly classified. | If main has red non-required scheduled jobs after PR #86 merges, document the job name, SHA, and why it is unrelated before starting token/gate commits. |

---

## Validation Sign-Off

- [x] All requirements have an automated verification path or an explicit manual checkpoint
- [x] Sampling continuity: no 3 consecutive tasks may proceed without an automated focused check
- [x] Wave 0 covers all missing gate/test extensions
- [x] No watch-mode flags
- [x] Feedback latency target is under 5 minutes for focused checks
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending planner/checker verification
