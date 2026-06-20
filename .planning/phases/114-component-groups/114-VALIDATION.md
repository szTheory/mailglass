---
phase: 114
slug: component-groups
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-20
---

# Phase 114 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Zero-Node, structural-proof only (D-11): ExUnit (Floki/component/live) + Playwright
> geometry + `check-conformance.sh` grep gates + committed-CSS cleanliness. No pixel-diff,
> no screenshot baseline, no new asset pipeline, no runtime dependency.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (in-tree) + Floki 0.38.4 + Playwright (`mailglass_admin/e2e/`) |
| **Config file** | `mailglass_admin/test/` (ExUnit); `mailglass_admin/e2e/` (Playwright) |
| **Quick run command** | `cd mailglass_admin && mix test test/mailglass_admin/group_nesting_test.exs && bash scripts/check-conformance.sh` |
| **Full suite command** | `cd mailglass_admin && mix test` + `bash scripts/check-conformance.sh` + e2e structural run (`npx playwright test e2e/structural.spec.js`) |
| **Estimated runtime** | ~30 seconds (scoped ExUnit + grep); ~2 min (full admin + e2e) |

---

## Sampling Rate

- **After every task commit:** Run `bash scripts/check-conformance.sh` (fast, deterministic) + the new Floki nesting test.
- **After every plan wave:** Run full `mix test` (admin) + the e2e structural lane.
- **Before `/gsd-verify-work`:** All three lanes green.
- **Max feedback latency:** ~30 seconds for the per-task quick run.

> Per MEMORY: bare `mix test` has ~57 unrelated Oban failures in worktrees and a known
> `voice_test` dep-JS "Oops" false-positive — scope to the named files; do not weaken those tests.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 114-XX | TBD | 0 | GROUP-02 | — | N/A | unit (Floki) | `mix test test/mailglass_admin/group_nesting_test.exs` | ❌ W0 (new file) | ⬜ pending |
| 114-XX | TBD | 0 | GROUP-01/03 | — | N/A | e2e geometry | `npx playwright test e2e/structural.spec.js -g "Group"` | ❌ W0 (add assertions) | ⬜ pending |
| 114-XX | TBD | 1 | GROUP-01/02 | — | N/A | grep gate | `bash scripts/check-conformance.sh` | ✅ extend (SPACE-GATE + GROUP-GATE) | ⬜ pending |
| 114-XX | TBD | 1 | GROUP-01 | — | N/A | live smoke | `mix test` (specimen↔reality binding) | ❌ W0 | ⬜ pending |

*Final task IDs assigned by the planner. Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/mailglass_admin/group_nesting_test.exs` — Floki top-down ancestor-depth proof for GROUP-02 (Floki 0.38.4 has no parent API → recurse over `{tag, attrs, children}`; elevation-class set `bg-base-200 | bg-base-100 | shadow-raised`, counted once per node; assert ≤2 within each `data-region`).
- [ ] `e2e/structural.spec.js` — new `Group:` describe block: `[data-group-card]` direct-sibling-only shared-left-edge `boundingBox().x` equality (±1px, `Math.round`), computed padding-floor (≥ semantic token), and `assertNoElementHorizontalOverflow` at 320 + 1280 (`PRIMITIVE_VIEWPORTS`).
- [ ] `gallery_live.ex` — three composed-group specimens + dispatcher entries with stable `data-testid`, `data-region` (composed-group root) + `data-group-card` (each shell), calling the SAME group-assembling function the live views call.
- [ ] `scripts/check-conformance.sh` — SPACE-GATE (word-boundary-anchored, file-scoped to the 8 group files per the FORM-DRIFT-GATE precedent) + GROUP-GATE box-prison tripwire + `card` shell added to the PRIMITIVE-DRIFT-GATE loop.
- [ ] One live-view smoke assertion binding specimen↔reality (the specimen must invoke the same composed-group function `operator_live.ex`/`inbound_live.ex` call, not a hand-copied tree).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| (none) | — | All GROUP-01..03 behaviors are structurally provable (Floki depth, Playwright geometry, grep token discipline). | N/A |

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
