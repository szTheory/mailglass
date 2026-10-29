---
phase: 178
review: 178-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: fixed
    title: "mailglass_admin package allowlist missing six shipped files (Mix Task Tests would fail on the candidate)"
  - id: WR-02
    severity: warning
    disposition: fixed
    title: "Two browser pins still expect the old exact selector link name"
  - id: WR-03
    severity: warning
    disposition: fixed
    title: "The deliveries axe producer opens a Delivery that has no replay control"
  - id: IN-01
    severity: info
    disposition: rejected
    title: "A retained-input test passes by skipping on a clean checkout"
open: 0
total: 4
recorded: 2026-10-29
---

# Phase 178: Code Review Disposition

| Finding | Severity | Disposition | Commit and covering test, or reason |
|---------|----------|-------------|-------------------------------------|
| WR-01 | warning | fixed | `0c2d999b` (`chore(publish): refresh mailglass_admin package allowlist for phase 175-178 files`). Covering test: `mix mailglass.publish.check --allowlist-only`, a step of the `mix_task_tests` CI Green need. It failed with `[conflict] compare allowlist` before the commit and reports `conflict=0` for core, admin and inbound after it. Re-run after the fix: `mix verify.mix_tasks` (89 tests, 0 failures), `mix mailglass.publish.check --allowlist-only` (exit 0), `mix verify.support_contract.admin --seed 0` (1204 tests, 0 failures). |
| WR-02 | warning | fixed | `de8e21b8` (`test(178-08): fix Preview picker link pins and the deliveries axe opener`). Covering tests: `flows.spec.js` "Preview edge: index redirects into the unified scenario layout at 320" and `structural.spec.js` "Operator replay modal, nav, preview theme controls, and preview summary controls meet target-size floor", both red in the first full run (each failed on attempt and retry) and green after the fix; the full Operator Browser Gate then reported 310 passed, 1 skipped (guarded), 0 failed, 0 flaky. |
| WR-03 | warning | fixed | `de8e21b8`. Covering tests: `axe-baseline.spec.js` "scan deliveries / light", "/ dark", "/ system", red at 90 s per attempt before and about 1 s each after; the full Operator Browser Gate run is the covering run (376 s against 1257 s for the run that carried the timeouts). |
| IN-01 | info | rejected | The skip is explicit (`skip: "skip: retained 174 inputs absent"`) and reports as skipped, not passed. The retained directory is untracked local evidence. The file is not in any `ci.yml` step, and every other case in it runs from synthetic inputs. Committing the retained evidence directory would grow the repository for no gate benefit. |

Dispositions used here: `fixed` (a commit and a covering test are named) and `rejected` (a reason is given). No finding is `open`, `deferred` or `skipped`.

## Gate-integrity check (T-178-21)

`git diff --stat 61e90275..HEAD -- mailglass_admin/docs/axe-baseline.json mailglass_admin/docs/storybook-axe-approved.json scripts/check_phase174_evidence.cjs .github/workflows config/quality config/test_exceptions.exs .tool-versions .planning/release-target.json` prints nothing, so no axe baseline, evidence-checker case set, workflow, CI policy, exception ledger, toolchain pin or release ledger changed in the phase diff. No gate was weakened, skipped or re-baselined to make the local run green.
