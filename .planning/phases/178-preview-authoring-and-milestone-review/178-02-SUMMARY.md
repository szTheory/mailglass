---
phase: 178-preview-authoring-and-milestone-review
plan: "02"
subsystem: testing
tags: [exunit, feedback-ledger, persona-spec, playwright, mutation-proof, mailglass_admin]

requires:
  - phase: 176-direct-filters-and-useful-inbound-evidence
    provides: "176-VERIFICATION.md headings and the phase176-filters.spec.js connected cases the closed rows point at"
provides:
  - "MailglassDemo.QuickViewScenarios.feedback/0 accessor for the feedback ledger"
  - "MailglassAdmin.TestSupport.FeedbackLedger: pure detectors (repo_root/0, slug/1, resolve_pointer/2, rule_violations/3, open_rows/1, link_violations/2, duplicate_ids/1) reused by plans 178-07 and 178-11"
  - "Merge-blocking, phase-independent D-08 ledger rule in feedback_ledger_test.exs (@moduletag :phase178), run by the full mix test lane"
  - "fb-auto-apply-filters, fb-raw-source-hierarchy, fb-inbound-addresses closed with current-source dispositions"
affects: [178-05, 178-07, 178-11]

phase_base_sha: 59e3bf22c761795824a33100540d2b810e2d720e
plan_head_before: 59e3bf22c761795824a33100540d2b810e2d720e
plan_head_after: 5dbad6051b308c901008ac1579dff9e22211a580

actuals:
  tokens: 8700
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Exactly-one-must-exist pointer resolver: live .planning/phases/<dir> or a globbed .planning/milestones/v*-phases/<dir> archive, named error when absent or ambiguous"
    - "GitHub-style heading slugs with repeat suffixes and fenced-code skipping for anchor checks"
    - "Throwaway repository-root fixtures under System.tmp_dir!/0 for resolver teeth tests"

key-files:
  created:
    - mailglass_admin/test/support/feedback_ledger.ex
    - mailglass_admin/test/mailglass_admin/feedback_ledger_test.exs
  modified:
    - reference/persona_spec/quick_view_scenarios.ex
    - reference/persona_spec/quick_view_scenarios.json
    - reference/demo_app/assets/e2e/quick-views.spec.js

key-decisions:
  - "The rule never reads owner_phase; a source scan of feedback_ledger.ex (with its own teeth test) enforces it"
  - "Archive roots are globbed (.planning/milestones/v*-phases), never hard-coded, so the v2.10 archive cannot break the test"
  - "Pointers with whitespace, glob characters, absolute paths or .. segments are rejected before any file read (T-178-05)"
  - "unrendered scenarios linked by fb-storybook-fidelity (qv-delivery-empty, qv-inbound-empty) are back-linked but not counted as stories; plan 178-05 owns that accounting"

requirements-completed: ["UIQ-04"]

coverage:
  - id: D1
    description: "Phase-independent ledger rule: every non-pending row has existing scenario ids or the connected-only boundary, and an evidence_pointer that resolves to a real file and heading"
    requirement: "UIQ-04"
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/feedback_ledger_test.exs#Phase 178 ledger: every non-pending row satisfies the D-08 rule"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/feedback_ledger_test.exs#Phase 178 ledger: the rule functions do not reference owner_phase"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every rule, the pointer resolver (live, archive-only, ambiguous, traversal), open-row detector, back-link check and duplicate-id check have fail-first teeth"
    requirement: "UIQ-04"
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/feedback_ledger_test.exs#detectors have teeth (fail-first proof)"
        status: pass
      - kind: command
        ref: "13 single-line mutations of feedback_ledger.ex each failed 1-4 tests (table below); file restored byte-for-byte"
        status: pass
    human_judgment: false
  - id: D3
    description: "Filters, Inbound address and raw-source rows closed; 12 rows in order; open rows are exactly fb-preview-reset, fb-preview-identity (pending) and fb-storybook-fidelity (partial); link_violations is [] on the real manifest"
    requirement: "UIQ-04"
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/feedback_ledger_test.exs#Phase 178 ledger: open rows are exactly the three named ones, so none can hide"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/feedback_ledger_test.exs#Phase 178 ledger: every row links only to scenarios that link back"
        status: pass
    human_judgment: false
  - id: D4
    description: "quick-views.spec.js no longer asserts any phase-number status set; the 12-row and non-empty assertions are unchanged and the test passes without a demo server"
    requirement: "UIQ-04"
    verification:
      - kind: command
        ref: "DEMO_BASE_URL=http://127.0.0.1:9 npx playwright test --config=playwright.config.cjs e2e/quick-views.spec.js -g 'Phase174 delivery scenario manifest' --workers=1 (1 passed)"
        status: pass
    human_judgment: false

duration: 6 min
completed: 2026-10-29
status: complete
---

# Phase 178 Plan 02: Phase-independent feedback ledger rule Summary

**A merge-blocking ExUnit rule now checks every non-pending owner-feedback row by scenario links and a resolvable `path#anchor` evidence pointer, never by phase number, with 13 mutations proving it can fail.**

## Accomplishments

- `MailglassDemo.QuickViewScenarios.feedback/0` exposes the ledger to the admin test build (already compiled in through `elixirc_paths(:test)`).
- `MailglassAdmin.TestSupport.FeedbackLedger` holds the pure, total detectors. `resolve_pointer/2` resolves `.planning/phases/<dir>/...` in exactly one of the live tree or any globbed `.planning/milestones/v*-phases/` archive, and returns a named error (`:missing`, `:ambiguous`, `:outside_repo`, `:prose_pointer`, `:invalid_path`, `:empty_anchor`, `{:anchor_not_found, a}`) otherwise.
- `feedback_ledger_test.exs` (32 tests, `@moduletag :phase178`) covers the real manifest (clean rule, exact 12 ordered ids, exact open-row set, back-links, unique ids, per-row closure checks) and the detectors with hand-built rows and temporary repository roots.
- Three stale Phase 176 rows are closed on current-source evidence, and the stale `["175","176","177","178"]` status assertion in `quick-views.spec.js` is replaced by phase-independent structural checks.

## Task Commits

| Task | Commit | What |
| --- | --- | --- |
| 178-02-01 (tracer) | `3edf22b3` | `feedback/0`, `FeedbackLedger`, clean-state / ordered-id / source-scan tests, filters row closed, prose pointers normalised, demo assertion replaced |
| 178-02-02 (tdd) | `5dbad605` | Inbound address and raw-source rows closed, 11 inbound-evidence plus 4 qv-* back-links, full teeth suite |

## Rule definition (D-08)

For every row whose `status` is not `pending`:

1. `scenario_ids` is non-empty and every id exists, **or** the row carries `proof_boundary: "connected-real-route-only"` (only `fb-auto-apply-filters` does).
2. `evidence_pointer` is `path` or `path#anchor`, contains no whitespace, has no absolute path, `..` segment or glob character, resolves to exactly one regular file, and, with an anchor, matches a markdown heading slug in that file.

`link_violations/2` additionally requires each listed scenario to exist and list the row id in its own `feedback_ids`. `open_rows/1` lists `pending` and `partial` rows regardless of the rule so an open row cannot hide. `owner_phase` is not read anywhere.

## Before / after row status

| Row | Before | After | Pointer (after) |
| --- | --- | --- | --- |
| fb-auto-apply-filters | pending | automated (boundary connected-real-route-only, scenario_ids []) | `176-VERIFICATION.md#observable-truths-roadmap-success-criteria` |
| fb-raw-source-hierarchy | pending | automated (4 evidence scenarios) | `176-VERIFICATION.md#requirements-coverage` |
| fb-inbound-addresses | pending | automated (7 contact scenarios) | `176-VERIFICATION.md#requirements-coverage` |
| fb-quiet-quick-view-arrows | resolved | resolved (prose moved to disposition) | `mailglass_admin/docs/phase174-review.md#feedback-disposition` |
| fb-storybook-fidelity | partial | partial (prose moved to disposition) | `mailglass_admin/docs/phase174-review.md#feedback-disposition` |
| fb-preview-reset, fb-preview-identity | pending | pending (plans 178-05 and 178-07 close them) | prose, skipped by the rule |
| fb-health-crowding, fb-account-context, fb-suppression-refresh, fb-replay-review, fb-technical-details | automated | unchanged | unchanged |

Pending count 5 to 2 on the manifest (the acceptance counter dropped 5 to 4 after task 1, then to 2). Back-links added: 7 contact scenarios gain `fb-inbound-addresses`, 4 `inbound-evidence-evidence-*` gain `fb-raw-source-hierarchy`, and `qv-delivery-first`, `qv-delivery-last`, `qv-delivery-empty`, `qv-inbound-empty` gain `fb-storybook-fidelity`. `qv-delivery-empty` and `qv-inbound-empty` are not story-rendered; the back-link does not count them as stories (plan 178-05 task 3 lists them as explicit boundaries).

## Teeth: red and green counts

- Task 2 teeth were written first and run against the task 1 manifest: 32 tests, 5 failures, all five real-manifest state assertions (`link_violations` four missing back-links, `open_rows` listing the two still-pending Inbound rows, both Inbound back-link tests, the four-scenario `feedback_ids` check). After the manifest edits: 32 tests, 0 failures; together with `quick_view_projection_test.exs` 46 tests, 0 failures.
- `resolve_pointer/2`, `rule_violations/3`, `open_rows/1`, `link_violations/2` and `duplicate_ids/1` were implemented in task 1 (the ledger module is one coherent unit), so their teeth could not go red by absence. They are mutation-proven instead; each single-line mutation of `feedback_ledger.ex` was run against the green suite and the file restored afterward:

| Mutation | Failing tests |
| --- | --- |
| pending rows checked by the rule | 2 |
| pointer check dropped | 4 |
| anchor check dropped | 2 |
| `link_violations` returns [] | 1 |
| `duplicate_ids` returns [] | 1 |
| archive roots ignored | 3 |
| ambiguous picks first | 2 |
| traversal / absolute guard removed | 2 |
| rule consults `owner_phase` | 2 |
| prose pointer allowed | 1 |
| empty-scenario check dropped | 3 |
| unknown scenario unchecked | 1 |
| boundary escape ignored | 2 |

## Verification commands (all green)

```bash
export ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27
cd mailglass_admin && mix test test/mailglass_admin/feedback_ledger_test.exs test/mailglass_admin/quick_view_projection_test.exs --seed 0   # 46 tests, 0 failures
cd mailglass_admin && mix test --warnings-as-errors --seed 0                                                                          # 1127 tests, 0 failures, 1 excluded
cd mailglass_admin && mix format --check-formatted test/support/feedback_ledger.ex test/mailglass_admin/feedback_ledger_test.exs ../reference/persona_spec/quick_view_scenarios.ex
cd reference/demo_app/assets && DEMO_BASE_URL=http://127.0.0.1:9 npx playwright test --config=playwright.config.cjs e2e/quick-views.spec.js -g "Phase174 delivery scenario manifest" --workers=1   # 1 passed
node --test scripts/check_phase174_evidence.test.cjs scripts/check_phase175_evidence.test.cjs mailglass_admin/e2e/support/storybook-axe.test.cjs   # 40 pass
node -e '...'   # pending rows === 2, feedback rows === 12, whole-manifest back-link scan prints nothing
```

## Deviations from Plan

### Auto-fixed Issues

None for code. Two notes on execution:

1. **Commit trailer.** The plan text names `Co-Authored-By: Claude Opus 5.5`; the commits carry `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`, the model that actually authored them, matching the session attribution instruction and the 178-01 commits. Explicit-path staging was followed exactly; `gsd-sdk query commit` was not used.
2. **Task 2 red proof is partial by construction.** `link_violations/2` and `duplicate_ids/1` were already implemented in task 1, so the task 2 red run only failed on manifest state (5 failures). The detector teeth are proven by the 13-mutation table instead, which is stronger than an absent-function red.

**Total deviations:** 0 behavioural; 2 process notes. **Impact:** none on the plan's outcome.

## Issues Encountered

- Plan `<automated>` blocks and my first commit attempt relied on shell word-splitting of a variable, which silently misbehaves under zsh; commits were redone under `bash -c` with arrays (no partial state was committed).
- `warning: MailglassDemo.QuickViewScenarios is not included in any boundary` appears when the admin test build compiles the persona spec. It predates this plan (the module has never declared `use Boundary`, unlike `personas.ex`), does not fail `mix test --warnings-as-errors` (exit 0 verified), and is out of scope; noted for a future hygiene pass.

## Known Stubs

None.

## Threat Flags

None. The pointer resolver adds only a read-only test-support path; T-178-04 (unsupported evidence claims) and T-178-05 (traversal) are mitigated and tested (`../../etc/hosts`, `docs/../../etc/hosts`, `/etc/hosts` all return `:outside_repo`).

## Self-Check: PASSED

- FOUND: mailglass_admin/test/support/feedback_ledger.ex
- FOUND: mailglass_admin/test/mailglass_admin/feedback_ledger_test.exs
- FOUND: commits 3edf22b3 and 5dbad605 are ancestors of HEAD
- Acceptance greps: `automatedPhase175Feedback` 0, phase-number array 0, test title 1, `def feedback` 1.
