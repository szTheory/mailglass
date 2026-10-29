# Phase 178 automated proof and reproduction

This record closes the Phase 178 machine-observable requirements named below against retained tests and retained story scenarios. It does not claim provider delivery, hosted CI execution, or an owner aesthetic verdict. Deterministic acceptance is automated under METHODOLOGY.md D-52. Later plans append the fidelity and ledger sections (178-07) and the prohibition contract (178-11); hosted sections come after the candidate.

## Reproduce and check

Run from the repository root. Every `mix` command needs the toolchain pin `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27`; `.tool-versions` is the CI contract and is not edited.

```sh
# Preview authoring form and selector (merge-blocking)
cd mailglass_admin && mix test test/mailglass_admin/preview_live_test.exs test/mailglass_admin/voice_test.exs test/mailglass_admin/preview/scenario_label_test.exs test/mailglass_admin/discovery_test.exs test/mix/tasks/mailglass_admin.preview.capture_test.exs --seed 0

# Retained Preview authoring stories and the feedback ledger (merge-blocking)
cd mailglass_admin && mix test test/mailglass_admin/quick_view_projection_test.exs test/mailglass_admin/feedback_ledger_test.exs --seed 0

# STORY-07 accounting and doc-truth tests: every "accounting" case (merge-blocking)
cd mailglass_admin && mix test test/mailglass_admin/feedback_ledger_test.exs --seed 0 --trace | grep -i accounting

# The whole admin lane, which includes every file above
cd mailglass_admin && mix verify.support_contract.admin --seed 0

# Operator browser evidence (Chromium, advisory lane). Confirm the artifact guard is empty
# before and after: git status --porcelain -- mailglass_admin/priv/static \
#   .planning/milestones/v2.9-phases/168-shared-workspace-and-usable-baseline/artifacts \
#   .planning/milestones/v2.9-phases/169-outbound-investigation-and-recovery/artifacts
cd mailglass_admin && CI=1 BROWSER_SERVER_PORT=4132 npx playwright test --config=playwright.config.cjs e2e/structural.spec.js e2e/flows.spec.js e2e/phase177-return-navigation.spec.js --grep "Phase 171|Phase 177|Phase 178|Preview:" --workers=1

# Retained story inventory (advisory). Always an isolated demo built from a committed SHA,
# never the owner's review demo on :4015 (a demo spec reset there would truncate its database).
bash scripts/check_phase178_candidate.sh --sha "$(git rev-parse HEAD)" --route /dev/storybook/preview_authoring --route /dev/mail --record "$PWD/reference/demo_app/tmp/phase178_candidate/stories.json"
(cd reference/demo_app/assets && DEMO_BASE_URL="$(node -e 'process.stdout.write(require(process.argv[1]).base_url)' "$PWD/../tmp/phase178_candidate/stories.json")" npx playwright test --config=playwright.config.cjs e2e/phase178-stories.spec.js --workers=1)
bash scripts/check_phase178_candidate.sh --teardown "$PWD/reference/demo_app/tmp/phase178_candidate/stories.json"
```

The launcher builds from the committed `HEAD`, and the story spec reads the manifest from the working tree, so commit story and manifest edits before the run and keep both in step. Demo runs bump `swoosh` in `reference/demo_app/mix.lock`; confirm `git diff --quiet -- reference/demo_app/mix.lock` before a run and `git checkout -- reference/demo_app/mix.lock` after it.

## Preview authoring (PRVUX-05, PRVUX-06)

The Preview assigns form ends with one bordered, aligned Restore defaults action whose handler is unchanged (plan 178-01). The five generic per-field type helpers are gone; one form-level note describes the read-only values that sit beside editable ones, and an all-read-only scenario says so instead.

Merge-blocking evidence:

- **Restore defaults and the note.** `mailglass_admin/test/mailglass_admin/preview_live_test.exs`: "the assigns form ends with one Restore defaults action using the secondary classes", "one form-level note describes read-only values and each display references it", "every typed_values page state resolves its aria references". `mailglass_admin/test/mailglass_admin/voice_test.exs` keeps the verb and noun pin.
- **Retained stories.** `mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs` (tag `phase178`) renders `preview-authoring-typed-values`, `-no-editable` and `-field-error` through the production `AssignsForm.assigns_form/1` from manifest facts (stories at `/dev/storybook/preview_authoring`). Typed values: "Phase 178 Preview authoring typed values decode to the HappyMailer scenario defaults" and "Phase 178 Preview authoring typed values story render shows the live route's field set" (the story render and the live `/dev/mail/MailglassAdmin.Fixtures.HappyMailer/typed_values` route show the same label and control kind per field). No editable values: "Phase 178 Preview authoring no_editable renders the no-editable message and no note". Field error: "Phase 178 Preview authoring field_error renders the specific error with an error-only describedby".
- **Pure-only boundary (D-09).** Every `preview-authoring-*` row carries `proof_boundary: story-render-only`; the only live check is the pure-to-live field-set equality above, which persists nothing. No persisted projection-agreement check exists for Preview, by decision.

Advisory evidence (Chromium, `operator_browser_gate` runs `npm run test:operator-browser` but is not in the `CI Green` aggregate): `mailglass_admin/e2e/structural.spec.js` "Preview: Phase 178 restore defaults geometry, border and focus" (390, 639, 640 and 1280px, light and dark), "Preview: Phase 178 restore defaults under reduced motion", "Preview: Phase 178 axe cell matches the committed baseline", and "Preview assigns and operator replay radios keep explicit labels and descriptions".

Retained scenario ids: `preview-authoring-typed-values`, `preview-authoring-no-editable`, `preview-authoring-field-error`.

Limits: stories prove rendering only; editing, parsing, validation and Restore defaults run on the real route. Browser evidence is Chromium-only. Story fixtures are synthetic (the HappyMailer defaults and the demo `AccountMailer`).

## Readable scenario selector (PRVUX-07)

The selector trigger reads the humanized scenario first, the Mailable second, and the exact `Module.scenario` identity as visible wrapping monospace text (plan 178-04). Options show the humanized label with the raw atom beneath. Scenarios that humanize to the same label fall back to their raw atoms; Mailables that share a leaf are told apart by the shortest unique namespace suffix. Every URL is byte-identical to the previous `scenario_path/6` output.

Merge-blocking evidence:

- **Label table.** `mailglass_admin/test/mailglass_admin/preview/scenario_label_test.exs` (24 tests): humanize, scenario and Mailable collisions (case, NFC and NFD, leaf across namespaces, `:no_previews` and error entries), unique `{module_label, primary}` pairs, no atom creation, hostile names escaped.
- **Markup and URLs.** `mailglass_admin/test/mailglass_admin/preview_live_test.exs`: "compact picker exposes long non-ASCII scenario identity without truncation", "option hrefs are the unchanged scenario_path/6 output, with and without return context", "no option span truncates and each wraps", "the two long Unicode scenarios are distinguishable by visible primary text".
- **Retained stories.** `quick_view_projection_test.exs` (tag `phase178`) renders `preview-authoring-typed-values`, `-long-unicode` and `-duplicate-label` through the production `Sidebar.menu/1`. Long Unicode: "Phase 178 Preview authoring long_unicode shows the raw atom in the technical line" (humanized primary without a double space, raw atom inside `preview-email-menu-active-technical`). Collisions: "Phase 178 Preview authoring duplicate_label opens the menu with distinct primaries and Mailable labels" (`<details open>`, two different visible primaries, two different Mailable group labels).

Advisory evidence (Chromium, same lane): `mailglass_admin/e2e/structural.spec.js` "Preview: Phase 178 selector distinguishes duplicate long Unicode scenarios at 320px and 390px" (wrap without page overflow, options at least 44px tall, Enter and Space open the menu, keyboard selection), "Preview: Phase 178 selector identity reads in light and dark" (identity contrast at least 4.5:1: 5.26 light, 10.30 dark for the technical line) and "Preview: Phase 178 selector under reduced motion". The affordance rotation is not a limit: that last case proves its transition is suppressed to 0.01ms, and the polling check reads the final rotated state.

Retained scenario ids: `preview-authoring-typed-values`, `preview-authoring-long-unicode`, `preview-authoring-duplicate-label`.

Limits: stories prove rendering only; the open menu, keyboard selection and navigation run on the real route. Browser evidence is Chromium-only. The colliding long Unicode names are a synthetic fixture (the sixth `HappyMailer` scenario), not a real adopter Mailable.

## Retained stories (STORY-07)

The table below is the story accounting for all 12 owner-feedback rows in `reference/persona_spec/quick_view_scenarios.json`. A scenario is story-backed when it is `rendered` with a `story_path`; a row links a scenario when the row lists it or the scenario lists the row. The table is computed by `MailglassAdmin.TestSupport.FeedbackLedger.story_accounting/2` and held equal to this text by the doc-truth case in `mailglass_admin/test/mailglass_admin/feedback_ledger_test.exs` (the "accounting" tests), so a missing, failed or zero-story case is counted and visible: a row with no story and no connected-only boundary fails the lane.

| Feedback | Requirement(s) | Story-backed scenarios | Linked without story render | Boundary |
| --- | --- | --- | --- | --- |
| fb-health-crowding | OUTUX-06 | 5 | 0 | story-render-only |
| fb-preview-reset | PRVUX-05, PRVUX-06 | 3 | 0 | story-render-only |
| fb-preview-identity | PRVUX-07 | 3 | 0 | story-render-only |
| fb-account-context | UXF-09, UXF-10 | 6 | 0 | story-render-only |
| fb-auto-apply-filters | FILTER-01, FILTER-02, FILTER-03, FILTER-04 | 0 | 0 | connected-real-route-only |
| fb-quiet-quick-view-arrows | UXF-11 | 9 | 2 | connected-real-route-only, story-render-and-connected-route, story-render-and-persisted-projection, story-render-connected-route-and-persisted-projection, story-render-only |
| fb-raw-source-hierarchy | INUX-06 | 4 | 0 | story-render-only |
| fb-suppression-refresh | OUTUX-07, OUTUX-08 | 4 | 0 | story-render-and-connected-route, story-render-only |
| fb-inbound-addresses | INUX-05 | 7 | 0 | story-render-only |
| fb-storybook-fidelity | STORY-03, STORY-04, STORY-05, STORY-06, STORY-07 | 22 | 2 | connected-real-route-only, story-render-and-connected-route, story-render-and-persisted-projection, story-render-connected-route-and-persisted-projection, story-render-only |
| fb-replay-review | REPLAY-04, REPLAY-05, REPLAY-06, REPLAY-07, REPLAY-08 | 5 | 0 | story-render-and-connected-route, story-render-only |
| fb-technical-details | UXF-12 | 2 | 0 | story-render-and-connected-route, story-render-and-persisted-projection |

Preview is pure-only (story-render-only) by decision D-09. Its five retained scenarios (`preview-authoring-*`) carry `proof_boundary: story-render-only`, and no persisted projection-agreement check is written for Preview. The one live check is the typed-values field-set equality test, "Phase 178 Preview authoring typed values story render shows the live route's field set", which compares the story render with `/dev/mail/MailglassAdmin.Fixtures.HappyMailer/typed_values` and persists nothing.

Filters (FILTER-01 to FILTER-04) are connected-only by decision: the row has no story-backed scenario and carries the `connected-real-route-only` boundary, and its proof is the real-route browser file `mailglass_admin/e2e/phase176-filters.spec.js`. It is the only row with zero stories.

The composed Delivery job is the Phase 175 Delivery investigation path: 9 `delivery-investigation-*` scenarios (stories at `/dev/storybook/delivery_investigation`), at least one of which, `delivery-investigation-fjordline-long-unicode` (`proof_boundary: story-render-and-persisted-projection`), agrees with the persisted projection. The merge-blocking projection-agreement tests already exist in `mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs` and are not duplicated here: "Phase 175 Northstar and Fjordline facts match scoped Delivery projections" and "Fjordline Delivery pure facts match the tenant-scoped production projection".

### Linked scenarios without a story render (STORY-07)

These scenarios are linked by a feedback row but have no story render, so they are counted boundaries rather than stories. Each carries a non-empty `proof_boundary`, asserted by the same accounting tests, and the table is generated from `FeedbackLedger.unrendered_linked_scenarios/2`, never typed by hand.

| Scenario | Feedback | Rendered | Story path | Boundary |
| --- | --- | --- | --- | --- |
| qv-delivery-empty | fb-quiet-quick-view-arrows, fb-storybook-fidelity | false | null | connected-real-route-only |
| qv-inbound-empty | fb-quiet-quick-view-arrows, fb-storybook-fidelity | false | null | connected-real-route-only |

Linked scenarios without a story render: 2

## Storybook fidelity and real zoom (UIQ-06)

The last open owner-feedback row, `fb-storybook-fidelity`, is closed (`automated`, `pending_phases` removed) on two receipts: a computed font-role comparison for the StatCard story (plan 178-07) and actual-200% browser zoom at 320 CSS px for every area the milestone deferred (plan 178-06). The owner's todo said Storybook's `.psb-sandbox` rendered the StatCard in a serif face; the question was never answered by an assertion until now.

### StatCard font roles

Advisory demo case `reference/demo_app/assets/e2e/phase178-stories.spec.js` "Phase 178 StatCard story uses the production font roles". The StatCard is a `:component` story with no iframe container, so PhoenixStorybook renders each variation inline inside `.psb-sandbox` in the explorer page (the element the todo blames for the serif face). For the `neutral_light` and `neutral_dark` variation blocks (`#neutral-light-component`, `#neutral-dark-component`) of `/dev/storybook/primitives/stat_card` the case reads the computed `font-family` and `font-weight` of three roles: the `data-theme` root (UI text), the label span and the `p.mono` value. It reads the same three roles from the production Admin gallery cell `gallery-stat_card-neutral` at `/dev/mail/gallery`, in the matching light and dark wrappers. Both pages are served by the same isolated demo from the same admin CSS bytes, so the comparison does not hard-code family names. It asserts, per role and theme:

- the first family and the weight equal production's;
- the first family is one of Inter, Inter Tight or IBM Plex Mono and is not a serif generic;
- the `.psb-sandbox` ancestor itself resolves to the production UI face (a run with `.psb-sandbox { font-family: Georgia, serif }` injected fails this assertion: expected "Inter", received "Georgia");
- `document.fonts.check` is true for the face in use and that face reports `loaded` (the case calls `document.fonts.load` first, because `check` alone is true when no face matches).

**Receipt** (gate G178-07-DEMO, isolated demo built from committed `890a7e67`, record `reference/demo_app/tmp/phase178_candidate/statcard-1793282939.json`, 2 passed in the Playwright run, wall 112 s against the 900 s bound, teardown left no `mailglass-phase178-review-*` container and the owner's review demo containers unchanged at 2). Computed first family and weight, identical in the story and in production for both themes:

| Role | Story first family | Production first family | Weight (story = production) |
| --- | --- | --- | --- |
| UI text (theme root) | Inter | Inter | 400 |
| Label | Inter | Inter | 700 |
| Value | IBM Plex Mono | IBM Plex Mono | 700 |

All three faces report `document.fonts.check` true and a `loaded` face. The full stacks differ after the first family (the story reports `Inter, system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", sans-serif`, the production gallery `Inter, system-ui, -apple-system, sans-serif`); the assertion is on the first family, which is what decides the rendered face once it is loaded. No serif appears in either. Before the receipt existed nothing asserted this; at this revision the serif the owner saw does not reproduce, so the story template and the demo Storybook setup needed no change and `mailglass_admin/priv/static/app.css` is untouched.

### Real zoom

Chromium tab zoom is applied through the repository's zoom extension (`mailglass_admin/e2e/support/real-zoom.cjs`), not CSS `zoom` or a DPR override. Every case reports tab zoom 2, initial `{devicePixelRatio: 2, innerWidth: 1440}` and effective `{devicePixelRatio: 4, innerWidth: 320}`, with `documentWidth <= 320` asserted per route and pushed as a `real-zoom` test annotation. Results from 178-06 (`178-06-SUMMARY.md`):

| Case | Where | Result |
| --- | --- | --- |
| Delivery quick view keeps position, arrows and Close usable | `mailglass_admin/e2e/phase178-real-zoom.spec.js` | pass (0.5-0.7 s) |
| Inbound quick view keeps position, arrows and Close usable | `phase178-real-zoom.spec.js` | pass (0.7-0.8 s) |
| Health overview keeps verdict, issue rows and Refresh readable | `phase178-real-zoom.spec.js` | pass (0.4-0.5 s) |
| Account control opens and lists Accounts | `phase178-real-zoom.spec.js` | pass (0.2 s) |
| Filters on Deliveries and Inbound apply without overflow | `phase178-real-zoom.spec.js` | pass (0.8-1.1 s) |
| Phase 171 actual 200% zoom, now also Restore defaults and the technical identity line | `mailglass_admin/e2e/structural.spec.js` | pass (0.8 s) |

The two Phase 176 `style.zoom` cases are labelled "CSS zoom 2x" and are not counted as real zoom. The Storybook fidelity receipt limit says it applies no browser zoom and points to `phase178-real-zoom.spec.js`. The target scan has teeth: raising the 44 px threshold in `undersizedTargets` made the Delivery case fail naming `operator-quick-view-next`, `operator-detail-back`, `operator-quick-view-full` and the copy buttons.

### CI lanes

Both lanes are advisory and neither is in the `CI Green` aggregate.

- **Demo Browser Evidence** (Docker Compose, Chromium): runs the demo Playwright suite under `reference/demo_app/assets/e2e/`, which includes the StatCard case and the retained Preview authoring stories case.
- **Operator Browser Gate** (`npm run test:operator-browser`, Chromium): runs `mailglass_admin/e2e/`, which includes `phase178-real-zoom.spec.js` and the extended Phase 171 case. It adds one Chromium launch for the persistent real-zoom context.

### Width selection

The phase's browser cases use 320, 390, 639, 640 and 1280 px rather than the 768 and 1440 px landmarks:

- 320: the WCAG 1.4.10 reflow width, and the effective CSS width of real 2x zoom on a 640 px viewport (178-06).
- 390: a current common phone width, for the narrow selector and the full-width Restore defaults button.
- 639 and 640: the two sides of the committed bundle's only layout breakpoint on the repaired Preview surfaces, `@media (min-width: 40rem)` (sm), where Restore defaults changes from full width to end-aligned (178-01).
- 1280: the desktop landmark for end alignment above the breakpoint, also on the padded side of the sidebar's `md:p-lg`.
- 768 is not a separate width because the only md rule on the repaired surfaces is `md:p-lg` padding in `sidebar.ex` (`assigns_form.ex` has none), which the 639/640 and 1280 runs already cover on both sides. Re-checked at execution time with `grep -o 'md:[a-z0-9-]*\|lg:[a-z0-9-]*' mailglass_admin/lib/mailglass_admin/preview/sidebar.ex mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex`, which printed only `md:p-lg`.
- 1440 is the launch viewport of the real-zoom recipe before it is resized to 640, and desktop alignment is already proven at 1280 under the same min-width rule.

### Hook receipts

Determination for ROADMAP success criterion 4: this phase adds or changes no hook.

The repaired surfaces carry no `phx-hook`. `reset_assigns` is a server `phx-click` event, not a hook.

```sh
$ grep -n 'phx-hook' mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex mailglass_admin/lib/mailglass_admin/preview/sidebar.ex
$ echo $?
1
```

The grep prints nothing and exits 1. The Preview-area hooks `PreviewTabs` and `PreviewPanelScroll` (`mailglass_admin/lib/mailglass_admin/preview/tabs.ex:40` and `:71`, implemented in `mailglass_admin/priv/static/hooks.js`) are untouched since `phase_base_sha` `61e90275f01f9927d2f8ab3bbfd3ba7f9099dffc` (from `178-01-SUMMARY.md`):

```sh
$ grep -n 'phx-hook' mailglass_admin/lib/mailglass_admin/preview/tabs.ex
40:        phx-hook="PreviewTabs"
71:        phx-hook="PreviewPanelScroll"
$ git diff --quiet 61e90275f01f9927d2f8ab3bbfd3ba7f9099dffc HEAD -- mailglass_admin/lib/mailglass_admin/preview/tabs.ex mailglass_admin/priv/static/hooks.js
$ echo $?
0
```

Their existing receipts (Phase 174 `hooks.json` and the Admin `flows.spec.js` cases) are therefore unchanged and need no new real-route receipt.

Limits: Chromium only, headless, synthetic data. The StatCard receipt reads the neutral variation in light and dark, not all 13 variations. Real zoom is Chromium tab zoom at 320 CSS px and says nothing about Safari or Firefox text scaling.

## Feedback ledger (UIQ-04)

`reference/persona_spec/quick_view_scenarios.json` carries 12 owner-feedback rows. Phase 178 closes the ledger: every row is `automated` or `resolved`, none is `pending` or `partial`, and a merge-blocking test keeps it that way.

### The rule (D-08)

A row is judged by its own contents, never by the phase that owns it. `MailglassAdmin.TestSupport.FeedbackLedger.rule_violations/3` requires, for every row whose status is not `pending`:

1. `scenario_ids` is non-empty and every id exists, or the row carries `proof_boundary: "connected-real-route-only"` (only `fb-auto-apply-filters` does);
2. `evidence_pointer` is `path` or `path#anchor` with no whitespace, absolute path, `..` segment or glob character, resolves to exactly one regular file, and, with an anchor, matches a markdown heading slug in that file.

`link_violations/2` also requires each listed scenario to exist and list the row id in its own `feedback_ids`. `owner_phase` is read nowhere, and a source-scan test pins that (with its own teeth).

### Merge-blocking test and its teeth

`mailglass_admin/test/mailglass_admin/feedback_ledger_test.exs` runs in the admin lane (`mix verify.support_contract.admin`). The real-manifest cases pin the 12 ids in order, the rule, the back-links, unique ids, the connected-only boundary, and the phase-close invariant **"Phase 178 ledger: no feedback row is pending or partial"**, which asserts `FeedbackLedger.open_rows/1` on the real manifest equals `%{pending: [], partial: []}`. The previous assertion named `fb-storybook-fidelity` as the one open row; it is replaced, so a row cannot reopen or hide without failing the lane. The `detectors have teeth` cases feed fixture rows and a throwaway repository root to each detector (bare row, other boundary value, missing path, bad anchor, prose pointer, unknown scenario, missing back-link, duplicate ids, `owner_phase` variation, absolute, traversing and glob pointers) and assert the exact violation, so each check can fail. Plan 178-02 proved the rule against 13 mutations.

### Dual-location resolver

A `.planning/phases/<dir>/...` pointer resolves in exactly one place: the live phase directory or one `.planning/milestones/v*-phases/<dir>/...` archive. Present in two places is `:ambiguous`, in none is `:missing`. The ledger therefore survives milestone archival without editing pointers, and the Phase 178 pointers below work both before and after this milestone is archived.

### Replaced demo assertion

The advisory demo case in `reference/demo_app/assets/e2e/quick-views.spec.js` once required the Phase 176 to 178 rows to be `pending`, which failed the moment they closed. It now holds phase-independent structural checks only (a known status, no whitespace in a non-pending pointer) and defers the full rule to the ExUnit file above (plan 178-02).

### Final status

| Feedback | Requirement(s) | Status | Evidence pointer |
| --- | --- | --- | --- |
| fb-health-crowding | OUTUX-06 | automated | `.planning/phases/177-readable-health-and-coherent-account-navigation/177-AUTOMATION.md#health-composition-outux-06` |
| fb-preview-reset | PRVUX-05, PRVUX-06 | automated | `.planning/phases/178-preview-authoring-and-milestone-review/178-AUTOMATION.md#preview-authoring-prvux-05-prvux-06` |
| fb-preview-identity | PRVUX-07 | automated | `.planning/phases/178-preview-authoring-and-milestone-review/178-AUTOMATION.md#readable-scenario-selector-prvux-07` |
| fb-account-context | UXF-09, UXF-10 | automated | `.planning/phases/177-readable-health-and-coherent-account-navigation/177-AUTOMATION.md#account-scope-and-preview-return-uxf-09-uxf-10` |
| fb-auto-apply-filters | FILTER-01 to FILTER-04 | automated | `.planning/phases/176-direct-filters-and-useful-inbound-evidence/176-VERIFICATION.md#observable-truths-roadmap-success-criteria` |
| fb-quiet-quick-view-arrows | UXF-11 | resolved | `mailglass_admin/docs/phase174-review.md#feedback-disposition` |
| fb-raw-source-hierarchy | INUX-06 | automated | `.planning/phases/176-direct-filters-and-useful-inbound-evidence/176-VERIFICATION.md#requirements-coverage` |
| fb-suppression-refresh | OUTUX-07, OUTUX-08 | automated | `.planning/phases/175-delivery-investigation-and-safe-replay/175-AUTOMATION.md#suppression-refresh-and-policy-outux-07-outux-08` |
| fb-inbound-addresses | INUX-05 | automated | `.planning/phases/176-direct-filters-and-useful-inbound-evidence/176-VERIFICATION.md#requirements-coverage` |
| fb-storybook-fidelity | STORY-03 to STORY-07 | automated | `.planning/phases/178-preview-authoring-and-milestone-review/178-AUTOMATION.md#storybook-fidelity-and-real-zoom-uiq-06` |
| fb-replay-review | REPLAY-04 to REPLAY-08 | automated | `.planning/phases/175-delivery-investigation-and-safe-replay/175-AUTOMATION.md#replay-path-replay-04-through-replay-08` |
| fb-technical-details | UXF-12 | automated | `.planning/phases/175-delivery-investigation-and-safe-replay/175-AUTOMATION.md#technical-evidence-uxf-12` |

The Phase 174 review guide (`mailglass_admin/docs/phase174-review.md`) restates each row's status and pointer in its Feedback disposition table, and its replay command now uses the installed Erlang pin `ASDF_ERLANG_VERSION=27.3.4.15` with Elixir `1.18.4-otp-27`, matching the toolchain note under "Reproduce and check" above (D-11; `.tool-versions` is unchanged).

Limits: the ledger proves that each pointer resolves to a real file and heading and that scenarios link both ways; it does not judge whether the target section's evidence is sufficient. Sufficiency is each owning phase's automated record.

## Prohibition contract (D-15)

Every Phase 178 must-NOT is a mutation-proven, merge-blocking test, so none routes to owner review (D-52, METHODOLOGY 2026-10-27 clause). The contract is `mailglass_admin/test/mailglass_admin/phase178_prohibition_contract_test.exs` (`MailglassAdmin.Phase178ProhibitionContractTest`, `use MailglassAdmin.LiveViewCase, async: false` because P5 needs a live view, `@moduletag :phase178`). It has 21 tests: 8 detector-teeth cases that feed each detector a known violation and a known clean fixture, and 13 clean-state cases on real renders (component renders, the live typed_values page, the open and closed selector menu), the real feedback manifest, and the real e2e spec sources.

### Rules

| Rule | Prohibition | Detector | Clean-state tests |
| --- | --- | --- | --- |
| P1 | No generic per-field type helper string ("Text value.", "Whole number.", "Decimal number.", "Toggle on or off.", "Date.") and no editable `assigns-*-help` id or reference | `generic_helper_violations/1` | `P1: ... assigns_form/1 renders none for typed, editable-only, read-only, mixed and error states`; `... the typed_values page renders none on mount, after an invalid edit and after Restore defaults`; `... the selector menu renders no generic helper or -help id` |
| P2 | No dangling `aria-describedby` or `aria-labelledby` id | `dangling_id_violations/1` | `P2: ... assigns_form/1 resolves every reference in every state`; `... the selector menu resolves every reference, closed and open`; `... every typed_values page state resolves its references` |
| P3 | The selected scenario's exact technical identity is visible text in the trigger, never only a `title` | `title_only_identity_violations/2` | `P3: ... every fixture scenario shows ScenarioLabel.technical/2 in the trigger text` (all HappyMailer scenarios plus the render-error entry); `... the live scenario page shows the identity in the trigger` |
| P4 | No raw scenario atom is the only primary label of a non-colliding scenario | `raw_primary_violations/2` | `P4: ... the open menu never shows a raw atom as the primary of a non-colliding option`; `... non-colliding primaries equal ScenarioLabel.humanize/1 and colliding ones keep the atom` |
| P5 | The `reset_assigns` event name and its restore/clear behavior are unchanged | `reset_violations/3` | `P5: reset_assigns is unchanged Restore defaults fires reset_assigns, restores the default and clears every field error` |
| P6 | No feedback row is pending or partial at phase close | `FeedbackLedger.open_rows/1` on `QuickViewScenarios.feedback/0` | `P6: ... the real manifest has no open row` |
| P7 | No test that uses `style.zoom` says real zoom, actual 200% or 200% zoom | `css_zoom_label_violations/1` (spec files to `[{file, title}]`) | `P7: ... no spec in the Admin or demo e2e trees labels CSS zoom as real zoom` |

Scope notes. P1 limits the `-help` id family to the assigns form (`assigns-*-help`); `preview-backdrop-help` is a different control and is legitimate. P4 derives collisions from `ScenarioLabel.humanize/1` alone, never from the label table under test, and the clean-state test asserts the fixture really contains a colliding pair. P7 splits each spec at `test(` and `test.describe(` boundaries, flags a block that contains `style.zoom` together with one of the phrases in its title or string literals, and asserts that it read more than 15 spec files and at least one `style.zoom` use (T-178-19, no vacuous scan). P5's clean-state test first asserts that the invalid edit produced a draft and a field error, so the restore it checks is not vacuous.

### Mutation proofs

Each mutation was applied to committed source (HEAD `a6596155`), the contract was run with `--seed 0`, and the file was reverted with `git checkout HEAD -- <that file>` only (no `git checkout .`, no `git stash`). After each revert `git diff --quiet HEAD -- <file>` exited 0.

| Rule | File mutated | Mutation | Failing test(s) | Revert command |
| --- | --- | --- | --- | --- |
| P1 | `mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex` | Re-added `<p id={@control_id <> "-help"}>Whole number.</p>` to the integer field | `P1: ... assigns_form/1 renders none for typed, editable-only, read-only, mixed and error states`; `P1: ... the typed_values page renders none on mount, after an invalid edit and after Restore defaults` (21 tests, 2 failures) | `git checkout HEAD -- mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex` |
| P2 | `mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex` | Read-only field `aria-describedby` points at the non-rendered `preview-assigns-missing` | `P2: ... assigns_form/1 resolves every reference in every state`; `P2: ... every typed_values page state resolves its references` (21 tests, 2 failures) | `git checkout HEAD -- mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex` |
| P3 | `mailglass_admin/lib/mailglass_admin/preview/sidebar.ex` | Technical identity span emptied and the identity moved to `title={@identity.technical}` | `P3: ... every fixture scenario shows ScenarioLabel.technical/2 in the trigger text`; `P3: ... the live scenario page shows the identity in the trigger` (21 tests, 2 failures) | `git checkout HEAD -- mailglass_admin/lib/mailglass_admin/preview/sidebar.ex` |
| P4 | `mailglass_admin/lib/mailglass_admin/preview/sidebar.ex` | Option primary renders `Atom.to_string(scenario_name)` instead of `ScenarioLabel.scenario_label/3` | `P4: ... the open menu never shows a raw atom as the primary of a non-colliding option`; `P4: ... non-colliding primaries equal ScenarioLabel.humanize/1 and colliding ones keep the atom` (21 tests, 2 failures) | `git checkout HEAD -- mailglass_admin/lib/mailglass_admin/preview/sidebar.ex` |
| P5 | `mailglass_admin/lib/mailglass_admin/preview_live.ex` | Dropped `assign(:field_errors, %{})` from the `reset_assigns` handler | `P5: reset_assigns is unchanged Restore defaults fires reset_assigns, restores the default and clears every field error` (21 tests, 1 failure) | `git checkout HEAD -- mailglass_admin/lib/mailglass_admin/preview_live.ex` |
| P6 | `reference/persona_spec/quick_view_scenarios.json` | `fb-health-crowding` status set from `automated` to `partial` | `P6: ... the real manifest has no open row` (21 tests, 1 failure) | `git checkout HEAD -- reference/persona_spec/quick_view_scenarios.json` |
| P7 | `mailglass_admin/e2e/phase176-filters.spec.js` | Renamed "under CSS zoom 2x" to "under 200% zoom" in the 500-character query test title | `P7: ... no spec in the Admin or demo e2e trees labels CSS zoom as real zoom` (21 tests, 1 failure) | `git checkout HEAD -- mailglass_admin/e2e/phase176-filters.spec.js` |

With every mutation reverted, `git diff --quiet HEAD -- mailglass_admin/lib reference/persona_spec mailglass_admin/e2e reference/demo_app/assets/e2e mailglass_admin/test/mailglass_admin/phase178_prohibition_contract_test.exs` exits 0 and the contract reports 21 tests, 0 failures.

### Lane

Support Contract Admin (required) runs the whole admin suite through `mix verify.support_contract.admin`, which includes this file. To reproduce the contract alone:

```sh
cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/phase178_prohibition_contract_test.exs --seed 0 --warnings-as-errors
```
