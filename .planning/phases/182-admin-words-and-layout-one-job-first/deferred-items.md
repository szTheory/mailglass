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

## 182-06

### Inbound outcome help and the support-card help strings still say "message"

- **Where:** `mailglass_admin/lib/mailglass_admin/components.ex` (`outcome_help(:inbound, ...)` and the generic `outcome_help(_, _)` fallback), `mailglass_admin/lib/mailglass_admin/operator_live.ex` (the Failed/Bounced/Rejected/Delayed support-card help, `"The provider reported that these messages could not be delivered."` and its siblings).
- **Why it stayed:** the BRADM-07 review rejected only delivery screens, so 182-06 changed only the delivery outcome help and the Awaiting confirmation tile. The support-card strings are pinned by the evidence-bound `reference/persona_spec/quick_view_scenarios.json` (line 1504), which this plan must not edit; the inbound screens are not among the 14 captured scenarios. The brand book (`voice.terms`) prefers "email" (and "inbound email") to "message" on screens, so a later words pass can finish the sweep together with a re-baselined persona file.

### The Activity list at 1440 shows a scrolling table whose last visible row is partly hidden in a full-page screenshot

- **Where:** `deliveries__northstar__default__1440__light` (the iteration-1 judge `b` flagged it under R-HIER-1; after the rubric said a list that scrolls inside its own bordered area is not cut-off content, both judges passed it).
- **Not fixed here:** it is the existing bordered, scrollable table with the pagination bar under it, not a regression of this phase. If the owner wants the whole page to scroll instead, that is a layout change with a bundle rebuild.

### `mix verify.support_contract.admin` with `MIX_BUILD_PATH` pointing at a fresh temp directory fails to compile `premailex`

- **Seen:** `MIX_BUILD_PATH="$(mktemp -d)/test" mix verify.support_contract.admin` stops with `could not read file ".../test/lib/premailex/priv/entities.txt"` (the dependency reads its own `priv` at compile time and the override build path has no `priv` link yet). Pre-seeding the link by hand did not help.
- **Workaround used for the cold proof:** the admin `_build/test` directory was moved aside, the lane was run (a true cold compile, 1756 tests, 0 failures), and the warm build was restored. The same quirk is why `MIX_DEPS_PATH`/`MIX_BUILD_PATH` overrides are unreliable on this machine.
