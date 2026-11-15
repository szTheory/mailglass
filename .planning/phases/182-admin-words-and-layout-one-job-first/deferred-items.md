# Phase 182 deferred items

Out-of-scope discoveries logged by plan executors. Nothing here was fixed by the plan that found it.

## 182-01

### Phase164RepositoryTruthTest fails in a checkout that has a local `.gsd/.gitignore`

- **Test:** `test/scripts/phase_164_repository_truth_test.exs`, "git runtime rules do not conceal the retired finalize-phase extension paths" (`refute ignored?(".gsd/extensions/finalize-phase/index.ts")`).
- **Seen in:** `mix test test/mailglass/operator test/scripts test/mailglass/docs_contract_test.exs --seed 0` (752 tests, 1 failure) on the executor's working tree at 2026-11-15.
- **Cause:** an untracked local file `.gsd/.gitignore` (contents `*`, mtime 2026-10-07) makes `git check-ignore` report the finalize-phase path as ignored. `git check-ignore -v` names `.gsd/.gitignore:1:*`.
- **Not caused by 182-01:** in a fresh `git clone --local` of this repository checked out at the plan's last commit (`92e18c3c`), all five assertions of that test hold (`.gsd/gsd.db`, `.gsd/exec/probe` and `.gsd/extensions/other/index.ts` are ignored; `.gsd/extensions/finalize-phase/index.ts` is not). Plan 182-01 changed no `.gitignore` and no file under `.gsd/`.
- **Disposition:** environment-specific to this working tree. The owner can remove or narrow the local `.gsd/.gitignore` if the test should pass here; it was not touched.

## 182-04

### The Failed webhook attempts support card draws an empty card on a nil count

- **Where:** `mailglass_admin/lib/mailglass_admin/operator/support_cards.ex:149`, `:if={@support_summary && @support_summary.failed_ingest.count > 0}`.
- **Cause:** in Elixir `nil > 0` is `true` (an atom sorts above any number). `failed_ingest: %{count: nil, ...}` is the real "read failed" value (`operator_live.ex` builds it when the read fails), so the Tier-1 card draws with an empty number instead of falling through to the "unavailable" row. The sibling orphan card had the same gate and was fixed in 182-04 because the new sentence would have raised on nil.
- **Not fixed here:** it is a pre-existing defect in a card this plan's words work does not change. A one-line fix (`(summary_count(@support_summary, :failed_ingest) || 0) > 0`) plus a nil-count render test would close it.

## 182-05

### The demo Storybook nav specimens still carry the sample label "Deliveries"

- **Where:** `reference/demo_app/storybook/primitives/nav_link.story.exs` (lines 33, 38) and `nav_pill.story.exs` (lines 31, 35).
- **Why it stayed:** 182-05 edits spec and test files only, and a story's `label:` is a sample attribute of the primitive, not an Admin screen. `persona-screenshots.spec.js` now reads the label from the story source, so it pins no screen word and stays green whichever label the story carries.
- **Fix when wanted:** change the four labels to `Activity` (a demo Storybook edit, no lib change). Nothing in a required lane reads them.

### Three e2e specs write screenshots into tracked, archived `.planning/milestones` paths

- **Where:** `mailglass_admin/e2e/structural.spec.js` (`.../168-.../artifacts/review-fix/*.png`), `mailglass_admin/e2e/phase169-journey.spec.js` (`.../169-.../artifacts/after/*.png`), and a demo spec in the evidence run (`.../172-.../artifacts/browser-evidence/invoice-preview-{320,375}.png`).
- **Effect:** every full run of those lanes dirties 4, 20 and 2 tracked PNGs of archived milestones. 182-05 restored them with `git checkout -- <paths>` after each run and never staged them (T-182-16). A careless `git add -A` after a lane run would rewrite archived evidence.
- **Not fixed here:** moving the output paths changes what the archived phases' evidence checks read, so it needs its own decision.
