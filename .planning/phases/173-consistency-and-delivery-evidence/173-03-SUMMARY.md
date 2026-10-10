---
phase: 173-consistency-and-delivery-evidence
plan: 03
subsystem: delivery-evidence
tags: [playwright, preview, css-provenance, github-actions, gsd]
requires:
  - phase: 173-02
    provides: Committed consistency baseline and prior-plan evidence
provides:
  - Focused working-preview readiness assertion and served Admin CSS identity
  - Candidate review runbook and fake-CLI-tested exact-SHA gate
  - Partial exact-candidate runtime record with owner dirt and missing CI evidence
affects: [UIQ-03, phase-173-delivery]
tech-stack:
  added: []
  patterns:
    - Capture the exact candidate SHA in a clean detached worktree and keep owner dirt as path/status metadata.
    - Compare source, built, and served CSS identities separately and keep browser/capture jobs advisory.
key-files:
  created:
    - .planning/phases/173-consistency-and-delivery-evidence/173-DELIVERY.md
    - reference/demo_app/assets/scripts/check-phase173-delivery-docs.test.cjs
    - scripts/check_phase173_candidate.sh
    - scripts/test_check_phase173_candidate.sh
  modified:
    - reference/demo_app/assets/e2e/persona-screenshots.spec.js
decisions:
  - Keep UIQ-03 incomplete while the exact candidate lacks required CI Green and accepted owner-dirty inputs remain excluded.
  - Preserve the owner-modified README without staging it; auto-review rejected staging because it contained pre-existing owner dirt.
  - Preserve the retained review Compose project and candidate worktree for owner feedback.
metrics:
  duration: "~2h 20m across resumed execution; exact start time was not captured"
  completed: "2026-10-09"
  tasks: 3
  files: 5 committed plan-owned files, plus the owner-dirty README change left uncommitted
  commits: 4
plan_head_before: aa3e7450dc355de5284ed5a1702d97fa590c3ebd
plan_head_after: cc1da30c076136e7b172f9f08e85d7167bff1477
status: incomplete
actuals:
  tokens: 10974
  tasks: 3
  commits: 4
---

# Phase 173 Plan 03: Working Preview and Candidate Delivery Evidence

The focused readiness test and candidate delivery gate are committed, and an isolated candidate preview serves the exact recorded CSS bundle; required exact-SHA CI and owner-dirty acceptance inputs remain outstanding.

## Accomplishments

- Added a focused Playwright check for the working preview, Gallery, curated Storybook route, keyboard access, and exact built-versus-served CSS bytes. The check passed against the disposable synthetic Compose project at `http://127.0.0.1:49321`; that exact temporary project was removed afterward.
- Added the delivery walkthrough, a documentation contract, and a fake-CLI contract for detached candidate identity, clean status, prior-summary ancestry, owner dirt exclusion, route and CSS checks, CI status, and scoped resource retention.
- Created the final detached candidate at `cc1da30c076136e7b172f9f08e85d7167bff1477`. Its retained review preview is `http://127.0.0.1:62253/dev/mail`, Compose project `mailglass-phase173-review-cc1da30c-20261010021410-75986-3730`, and worktree `/private/tmp/mailglass-phase173.cZOaLkQ5/candidate`.
- The five candidate routes returned successfully. Source CSS SHA-256 is `218a8b6932504a29f92f21d1ac3518e6a5e0fac6f67a86e179defc2c1b958f05`; built and served CSS SHA-256 both equal `91c0b80fd5d2d9dd42d6501b615f3167b5f25a13beed92894e11fdfa1b6abff1`. The versioned served path is `/dev/mail/css-7ad717cac50971a2b37f819f8c45975e`.
- After the first candidate attempt recorded absent dependencies, the owner fetched only committed-lockfile dependencies into ignored candidate directories and reran the regression gate in this same exact candidate with browser process access: 79 core, 599 Admin, 480 inbound, and 30 Playwright checks passed. `mix verify.preview` was also attempted; it failed on the existing `Mailglass.Webhook.WebhookEvent` test-support boundary warning. The source and built CSS files have no Phase 173 diff from the Plan 01 base, so the served-byte comparison is direct proof of identity despite that separate check failure.

## Commits

| Task | Commit | Files |
| --- | --- | --- |
| Task 1: Working-preview readiness | `6b290f1b` | `persona-screenshots.spec.js` |
| Task 2: Runbook and candidate gate, clean deliverables | `9e942cda` | Runbook, content contract, candidate gate, fake-CLI contract |
| Task 2: Accept plain task hashes in prior summaries | `2ea9fe3a` | Candidate gate |
| Task 2: Support alternate prior-summary commit formats | `cc1da30c` | Candidate gate |

Task 2 remains partial. `reference/demo_app/README.md` was already owner-modified. Auto-review rejected staging it because that could include unrelated owner changes; no alternate staging path was attempted. Its intended Plan 03 entry-point change therefore remains uncommitted.

## Verification and Delivery Status

- `npm --prefix reference/demo_app/assets run test:e2e -- e2e/persona-screenshots.spec.js --grep "working preview readiness"` — passed on the authorized disposable synthetic preview.
- `node --test --test-reporter=spec reference/demo_app/assets/scripts/check-phase173-delivery-docs.test.cjs` — 4 passed.
- `bash scripts/test_check_phase173_candidate.sh` — passed, including exact-SHA mismatch, dirty candidate, ancestry, owner dirt, HTTP/CSS, CI failure, retention, and no remote-write cases.
- Final candidate readiness and built-versus-served CSS identity — passed. The ignored `delivery-candidate.json` at the candidate evidence path records the first run as incomplete: it had no local dependency cache, no exact-SHA CI, and excluded required owner-dirty acceptance inputs. The subsequent owner-run regression gate passed after fetching locked dependencies; this later result does not rewrite the captured JSON.
- Exact-SHA `CI Green` — missing for `cc1da30c076136e7b172f9f08e85d7167bff1477`. The read-only query found no matching run. Advisory jobs were empty.
- UIQ-03 remains incomplete. Owner-dirty acceptance paths recorded by status only include the Plan 168 delivery captures; `lib/mailglass/compliance/unsubscribe_html/state.html.heex`; `lib/mailglass/components.ex`; `reference/demo_app/README.md`; `reference/demo_app/assets/e2e/demo.spec.js`; the demo component mailer and preview-scenario test; and the listed core compliance, button, and content tests. The prohibited `demo.spec.js` was never read, imported, edited, staged, or executed.
- The earlier feedback preview and listener on port 4002 were left untouched. The final candidate Compose project and worktree remain retained for owner review. Two earlier failed intermediate worktrees were removed by their exact unique paths.
- The 320px Gallery overflow remains explicitly deferred from Plan 02; it is not recorded as a pass.

## Deviations and Incomplete Gates

- **Candidate parser compatibility:** The first candidate checks exposed committed summaries that store RED/GREEN hashes without backticks and summaries using a `Completed Tasks` section. The gate was updated to validate both formats. These fixes are committed as `2ea9fe3a` and `cc1da30c`.
- **README staging blocked:** The required README edit could not be committed without staging an owner-dirty file. This leaves Task 2 and the documented entry point incomplete.
- **Required CI absent:** No exact-SHA `CI Green` run exists. UIQ-03 must remain incomplete until required CI and owner-dirty acceptance evidence are resolved through the appropriate workflow.
- **Asset check warning:** `mix verify.preview` fails on the existing `Mailglass.Webhook.WebhookEvent` test-support boundary warning. This is separate from the matching source/build/served CSS hashes and is not represented as a passing asset check.

## Self-Check: PASSED

- The summary path exists.
- Task commits `6b290f1b`, `9e942cda`, `2ea9fe3a`, and `cc1da30c` are ancestors of the recorded plan head after.
- The task commit range is measured as four commits from `aa3e7450dc355de5284ed5a1702d97fa590c3ebd` through `cc1da30c076136e7b172f9f08e85d7167bff1477`.
