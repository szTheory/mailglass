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

## Local gate and candidate freeze (UIQ-08)

gate_head_sha: dd392b87a5c99895495f046241242b3eb35c5e64
local_pilot_evidence_dir: reference/demo_app/tmp/demo_browser_evidence/mailglass-evidence-20261029151132-99671-6585
operator_local_wall_s: 376
operator_executed_count: 311
operator_baseline_count: 230
operator_projection_method: count
operator_projected_hosted_s: 1203
operator_timeout_disposition: within margin (1203 s of 1440 s)

Run on 2026-10-29 from `/Users/jon/projects/mailglass` with `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27`. `gate_head_sha` is the commit the whole table was last measured on (see "Fixes made by the gate"). Every later commit in this plan touches `.planning` only. No remote write happened: `origin/gsd/v2.10-ui-repairs-storybook` was `25dc21cff0948eb75c0b00ec39cc06f4bb410e06` before and after, and `gh run list --branch gsd/v2.10-ui-repairs-storybook` returned `[]` before.

### Operator Browser Gate timeout projection (W-4)

- **Baseline.** Hosted run 40414024714, job 121891818074, read read-only with `gh api --allow-escape-sequences repos/szTheory/mailglass/actions/jobs/121891818074/logs`: `Running 230 tests using 1 worker`, 229 passed and 1 skipped, 11.0 minutes of test time, 889 s for the job. The plan's stand-in figure of about 211 tests was approximate; the log says 230, which is what `operator_baseline_count` records.
- **Method.** `count`. No prior phase record carries a local operator-suite wall time at the baseline commit (the Phase 177 gate recorded counts, not seconds), so the ratio method is unavailable. Projection: ceil(889 x 311 / 230) = 1203 s, below the 1440 s limit (0.8 x the 1800 s `timeout-minutes` at `ci.yml:957`).
- **Measured.** The accepted local run executed all 311 tests in 376 s with one worker and `CI=1` (310 passed, 1 skipped, 0 failed, 0 flaky). The first full run took 1257 s and is not the figure of record: it carried six 90 s timeouts (see "Fixes made by the gate"), which pushed it past the test server's 20 minute sandbox-owner lifetime (`OperatorBrowserServer`, `@server_ownership_timeout`), and every case after that minute failed with a DB ownership error.
- **Second bound.** The 20 minute sandbox-owner lifetime is a cliff that is separate from the 30 minute job limit. The hosted test portion projects to about 660 s x 311 / 230 = 892 s, which leaves about 300 s of margin to that cliff. Anything that adds roughly 5 minutes of timeouts to the hosted lane (as the six axe timeouts did locally) would cross it. The cause of those timeouts is fixed in this plan.

### Fixes made by the gate

The full operator suite found two real regressions that the earlier plans' targeted greps never ran, and a red that spent the lane's time budget. Each is a test or support change, committed with its covering run; none edits a baseline, a checker case set, a workflow or a policy file.

| Finding | Cause | Fix | Covering run |
| --- | --- | --- | --- |
| `mix mailglass.publish.check --allowlist-only` conflict for `mailglass_admin` (Mix Task Tests, a CI Green need) | Six shipped files absent from `.planning/publish/mailglass_admin-files.expected` | `0c2d999b`: allowlist now equals the packaged file list (six lines added, none removed) | `mix mailglass.publish.check --allowlist-only`: `conflict=0` for core, admin and inbound |
| `flows.spec.js` "Preview edge: index redirects into the unified scenario layout at 320" and `structural.spec.js` "Operator replay modal, nav, preview theme controls, and preview summary controls meet target-size floor" | Phase 178 renders each selector option as a humanized label with the raw atom beneath it, so the link's accessible name became `Welcome default welcome_default` and the exact `welcome_default` name pins no longer matched | `de8e21b8`: both pins match `/^Welcome default\s+welcome_default$/` | Both cases pass; full suite 310 passed |
| `axe-baseline.spec.js` "scan deliveries / light, dark, system" timed out at `operator-replay-open` (90 s per attempt, one retry each, 9 minutes in total) | The opener clicked the first visible Delivery row, which has no replay control; `flows.spec.js` replay cases select the fourth visible row. The same red was reproduced at `03e2cc35` by plan 177-07 | `de8e21b8`: the opener selects the fourth visible row. The three scans now finish in about 1 s each | Three scans pass; full suite 310 passed |
| Demo isolated launch exited at start-up (`mix deps.get --check-locked`: floki 0.38.4 => 0.38.5, released the same day) | Upstream release after the earlier lock refresh (`8c02bf7e`). The hosted Demo Browser Evidence job runs the same step | `dd392b87`: one `reference/demo_app/mix.lock` line, floki only | Pilot passes on `dd392b87`; demo ExUnit 37 tests, 0 failures |

Limit: the demo lock can drift again between this freeze and the hosted run, because the reference baselines use `~>` against Hex. A hosted `Demo Browser Evidence` red at `mix deps.get --check-locked` would be that drift, not a regression in the candidate.

### Pre-existing and local-only reds

- **`test/scripts/phase_164_repository_truth_test.exs:261`** ("git runtime rules do not conceal the retired finalize-phase extension paths") fails in the root suite and in `mix verify.ci_lane_contract`. It is local-only, with the four proofs recorded in `178-12-SUMMARY.md`, re-observed at this gate: `git ls-files .gsd` prints nothing; `git ls-files --error-unmatch .gsd/.gitignore` exits 1; `git check-ignore --no-index -v .gsd/extensions/finalize-phase/index.ts` prints `.gsd/.gitignore:1:*`; `.gitignore:59` is `!/.gsd/extensions/finalize-phase/`. A CI checkout has no `.gsd/.gitignore`, so the case cannot fail there. It is the only failure in 2246 core tests.
- **Advisory reds proven pre-existing:** none remain. The three `axe-baseline.spec.js` "scan deliveries" timeouts reproduced at the start of this gate and are fixed above, so there is no `preexisting_advisory_red` line in `178-08-SUMMARY.md`.
- **EEF-CVE-2026-43966** (cowlib): `mix mailglass.audit --kind hex` reports it for `mailglass_admin` as `an accepted-allowlist finding` (the committed ledger `lib/mailglass/supply_chain/accepted_advisories.ex`) and both audit lanes exit 0. The `reference/demo_app` `mix deps.update` also prints the same advisory. It is recorded here and not chased.
- Admin-package credo findings and 10 unformatted admin files from the Phase 177 gate are not CI Green inputs and were not re-run.

### Expected and executed counts

| Suite | Expected (`npx playwright test --list`) | Research baseline | Executed | Explanation of the difference |
| --- | --- | --- | --- | --- |
| Operator (`mailglass_admin`, 18 files) | 311 | 300 in 17 files | 311: 310 passed, 1 skipped, 0 failed, 0 flaky | +11 tests, +1 file: `phase178-real-zoom.spec.js` (5 cases) and six `Phase 178` cases in `structural.spec.js` (selector duplicate Unicode, selector light and dark, selector reduced motion, axe cell, Restore defaults geometry, Restore defaults reduced motion). The one skip is `structural.spec.js` "header-anchored overlay transform-origin is top-edge IF such an overlay exists (guarded, D-07)", which calls `test.skip(true, ...)` by design when no header-anchored overlay exists. |
| Demo (`reference/demo_app/assets`, 14 files) | 111 | 109 in 13 files | 111 in the cold condition and 111 in the warm condition, 0 skipped, 0 unexpected, 0 flaky (`phase174/{cold,warm}/playwright-report.json`) | +2 tests, +1 file: `phase178-stories.spec.js` (2 cases) |

### Gate table

Placement is the `ci.yml` job. `CI Green` needs are required; the operator and demo lanes are advisory (outside the aggregate).

| Gate or job id | Command | Result | Expected | Executed | Wall | CI lane and placement |
| --- | --- | --- | --- | --- | --- | --- |
| `format_check` | `mix format --check-formatted` | pass | n/a | n/a | 1 s | Format Check, required (CI Green need) |
| `compile_warnings` | `mix compile --warnings-as-errors` | pass | n/a | n/a | 1 s (warm build) | Compile Warnings, required |
| `compile_no_optional_deps` | `MIX_BUILD_PATH=<repo>/_build/phase178-noopt mix compile --no-optional-deps --warnings-as-errors` | pass | n/a | 202 files compiled | 38 s | Compile No Optional Deps, required. The plan's `/tmp` build path fails (Mix writes a relative `priv` symlink, so premailex cannot read `priv/entities.txt`); a gitignored directory under `_build` has the same depth as `_build/dev`, kept the shared build clean, and was removed afterwards |
| `inbound_compile_no_optional_deps` | not run | not affected | n/a | n/a | n/a | Inbound Compile No Optional Deps, required. `git diff --name-only origin/main...gate_head_sha -- lib mix.exs mix.lock config mailglass_inbound` prints nothing |
| `installer_host_smoke` | `DEP_MODE=path MAILGLASS_PATH=<repo> bash scripts/consumer_install_smoke.sh` (with `MIX_HOME` pointing at a scratch directory, so the lane's own `local.hex`, `local.rebar` and `archive.install phx_new` steps did not touch the owner's toolchain) | pass | n/a | `GET /dev/mail/ -> HTTP 200` | 60 s | Installer Host Smoke, required. Affected: `mailglass_admin/lib` changed and the generated host depends on it by path. `generated_ecto_host_proof.sh` was not run: its path mode installs core and inbound only, and both are unchanged |
| `installer_golden_gate` | not run | not affected | n/a | n/a | n/a | Installer Golden Gate, required. The lane runs `test/mailglass/install/install_golden_test.exs`; `git diff --name-only origin/main...gate_head_sha -- lib mix.exs mix.lock config priv test/mailglass/install test/support` prints nothing |
| `mix_task_tests` | `mix verify.mix_tasks && mix mailglass.publish.check --allowlist-only && mix verify.ci_lane_contract` | pass; local-only red in the lane-contract run | n/a | `verify.mix_tasks` 89 tests, 0 failures; allowlists `conflict=0` for three packages (after `0c2d999b`); `verify.ci_lane_contract` 507 tests, 1 failure (`phase_164:261`, local-only) | 8 s + 220 s | Mix Task Tests, required |
| `support_contract_core` | `mix verify.support_contract.core` | pass | n/a | 1 property, 140 tests, 0 failures, 1 skipped | 2 s | Support Contract Core, required |
| `support_contract_admin` | `cd mailglass_admin && mix verify.support_contract.admin --seed 0` | pass | n/a | 1204 tests, 0 failures, 1 excluded (re-run on `gate_head_sha`) | 19 s | Support Contract Admin, required |
| `inbound_test` | `cd mailglass_inbound && mix test --exclude property --seed 0` and `mix test --only property --seed 0` | pass | n/a | 3 properties, 480 tests, 0 failures, 3 excluded; then 480 excluded and 0 failures for the property selection (the DB-pool flake did not appear) | 5 s + 51 s | Inbound Test, required |
| `core_deterministic_suite` | `MAILGLASS_SUITE_FLOOR=1 mix test --warnings-as-errors --seed 0` | local-only red | floor 1576 | 23 properties, 2246 tests, 1 failure (`phase_164:261`), 27 excluded, 7 skipped; 2235 executed (659 above the floor, advisory nudge only) | 388 s | Core Deterministic Suite, required. Re-run on `gate_head_sha` |
| `credo_strict` | `bash scripts/check_credo_suppressions.sh && mix run scripts/check_static_analysis_exceptions.exs && mix credo --strict` | pass | n/a | 81 checks, 564 files, no issues | 4 s | Credo Strict, required |
| `conformance_gates` | `bash scripts/check_motion_conformance.sh && bash mailglass_admin/scripts/check-conformance.sh && bash mailglass_admin/scripts/check-conformance-advisory.sh` | pass | n/a | n/a | 1 s | Design System Conformance, required |
| `docs_warnings_as_errors` | `mix docs --warnings-as-errors && mix mailglass.docs.check` | pass | n/a | `Tier 1 docs match the stability contract` | 2 s | Docs Warnings as Errors, required |
| `dialyzer` | not run | not affected | n/a | n/a | n/a | Dialyzer, required. `git diff --name-only origin/main...gate_head_sha -- lib mix.exs mix.lock config .dialyzer_ignore.exs scripts/check_dialyzer_ignore.sh` prints nothing |
| `inbound_dialyzer` | not run | not affected | n/a | n/a | n/a | Inbound Dialyzer, required. The same paths plus `mailglass_inbound` print nothing |
| `trust_lane_repo_head` | not run | not affected | n/a | n/a | n/a | Trust Lane Repo Head, required. It builds the published Admin and the workspace inbound; `git diff --name-only origin/main...gate_head_sha -- lib mix.exs mix.lock config mailglass_inbound reference/host_app scripts/check_trust_runner_checkpoint.sh` prints nothing |
| `hex_audit` | `mix mailglass.audit --kind hex` | pass | n/a | `all findings accepted` (EEF-CVE-2026-43966 on the committed allowlist) | 10 s | Hex Audit, required |
| `deps_audit_advisory` | `mix mailglass.audit --kind deps` | pass | n/a | `all findings accepted` | 2 s | Deps Audit, required (CI Green need) |
| `operator_browser_gate` | `cd mailglass_admin && CI=1 BROWSER_SERVER_PORT=4132 npx playwright test --config=playwright.config.cjs --workers=1` (artifact guard empty before; restored after) | pass | 311 | 310 passed, 1 skipped (guarded), 0 failed, 0 flaky | 376 s | Operator Browser Gate, advisory |
| `demo_exunit` | `cd reference/demo_app && MIX_ENV=test mix test --seed 0` (lock restored, no drift) | pass | n/a | 37 tests, 0 failures | 3 s | Reference demo suite (not a CI Green need) |
| `demo_browser_evidence` | `bash scripts/run_demo_browser_evidence.sh --phase174 --phase175 --pilot` | pass | 111 | 111 cold and 111 warm, 0 skipped, 0 failed, 0 flaky; 26 passed per condition for the Storybook axe | 500 s | Demo Browser Evidence, advisory |
| `pilot_checkers` | `node scripts/check_phase174_evidence.cjs --evidence-dir <local_pilot_evidence_dir> --pilot` and `node scripts/check_phase175_evidence.cjs ...` | pass (both exit 0) | n/a | execution.json `source_revision` equals `gate_head_sha` | 1 s | Demo Browser Evidence, advisory |
| `node_checker_tests` | `node --test test_js/phase173-baselines.test.cjs scripts/check_phase174_evidence.test.cjs scripts/check_phase175_evidence.test.cjs scripts/phase174-review-claims.test.cjs mailglass_admin/e2e/support/storybook-axe.test.cjs scripts/phase178_cost_disposition.test.cjs`, `node --test test_js/ci-monitor.test.cjs`, `bash scripts/test_check_phase178_candidate.sh` | pass | n/a | 57 + 5 node tests, 0 failures; 11 launcher checks pass | 2 s | Demo Browser Evidence and Operator Browser Gate setup steps, advisory |
| `gsd_regression_gate` | `bash scripts/gsd-regression-gate.sh` (then `git checkout -- mailglass_admin/priv/static/app.css`; the v2.9 artifact directories restored by the script) | pass | n/a | core 81 tests, admin 1204, inbound 480, browser subset 37, node 42; 0 failures | 67 s | Phase gate, not a CI lane |

Not run, with the reason: `generated_ecto_host_proof.sh` (core and inbound unchanged), and the admin-package credo and format findings (not CI Green inputs).

### Candidate freeze

candidate_sha: 2bdf18161182beeb286435b556f26e205976e658

- **Commit subject:** `docs(178-08): phase diff review and dispositions`. The review (4 findings: 3 warnings fixed, 1 info rejected; see `178-REVIEW-DISPOSITION.md`) produced no source change after `gate_head_sha`, so no gate was re-run for it beyond the admin suite (1204 tests, 0 failures).
- **No source change since the gate:** `git diff --quiet dd392b87a5c99895495f046241242b3eb35c5e64 2bdf18161182beeb286435b556f26e205976e658 -- . ':(exclude).planning'` exits 0, and `git status --porcelain -- mailglass_admin reference scripts test lib mailglass_inbound config` prints nothing.
- **Remote refs (read-only `git fetch origin main gsd/v2.10-ui-repairs-storybook`):** `origin/main` is `8328093e4a07d28251ec7f02dd0f37cda2fd6a7b` and `origin/gsd/v2.10-ui-repairs-storybook` is `25dc21cff0948eb75c0b00ec39cc06f4bb410e06`, the same value as before the plan (`git ls-remote` agrees).
- **Ancestor checks:** `git merge-base --is-ancestor origin/main <candidate_sha>` exits 0; `git merge-base --is-ancestor origin/gsd/v2.10-ui-repairs-storybook <candidate_sha>` exits 0. The push in plan 178-09 is therefore a plain fast-forward.
- **Commits ahead:** 351 ahead of `origin/main`, 52 ahead of `origin/gsd/v2.10-ui-repairs-storybook`.
- **Remote actions taken by this plan: none.** No push, pull request, workflow dispatch, rerun or merge. `gh run list --branch gsd/v2.10-ui-repairs-storybook` returned `[]` before and after.
- The commit that records this freeze comes after the candidate and is never pushed.

## Gap closure: re-gate and re-freeze (UIQ-06, UIQ-07, UIQ-08)

rerun_gate_head_sha: baf5685e1a9b943d41b884b007fdea5fa45fa498
rerun_local_pilot_evidence_dir: reference/demo_app/tmp/demo_browser_evidence/mailglass-evidence-20261101214833-39818-11964
rerun_lock_refresh: phoenix_html 4.3.0 => 4.4.0
rerun_operator_list_count: 311
rerun_operator_named_skips: 1 | header-anchored overlay transform-origin is top-edge IF such an overlay exists (guarded, D-07)
rerun_demo_list_count: 111
rerun_demo_receipt_expected_total: 169
rerun_operator_executed_count: 311
rerun_operator_projected_hosted_s: 1203
rerun_operator_timeout_disposition: within margin (1203 s of 1440 s)
rerun_branch_sha_before: 2bdf18161182beeb286435b556f26e205976e658

The re-gate runs at `rerun_gate_head_sha`; all saved gate logs are in `reference/demo_app/tmp/phase178_candidate/rerun-gate/` and begin with that SHA. `expected.json` is `reference/demo_app/tmp/phase178_candidate/rerun-disposition-inputs/expected.json`. Operator counts use the Playwright end-of-run summary lines: 311 executed as 310 passed plus the one named guarded skip, 0 failed and 0 flaky. Demo counts use the local pilot `phase174/cost.json` expected/executed receipt per condition: 111 Demo cases plus 6 hooks, 26 fidelity and 26 axe cases equals 169; this receipt total is a different unit from the Demo `--list` count of 111. Cold and warm each match `{demo: 111, hooks: 6, fidelity: 26, axe: 26, total: 169}`.

| Gate | Command | Saved log | Result | Expected | Executed | Wall | CI lane and placement |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Gate integrity | `git diff --stat 61e90275..<rerun_gate_head_sha> -- <178-08-02 gate-integrity list>` | `rerun-gate/gate-integrity.log` | pass; no protected-path diff | n/a | n/a | 0 s | Candidate integrity, local |
| Node lists | `node --test test_js/phase173-baselines.test.cjs scripts/check_phase174_evidence.test.cjs scripts/check_phase175_evidence.test.cjs scripts/phase174-review-claims.test.cjs mailglass_admin/e2e/support/storybook-axe.test.cjs scripts/phase178_cost_disposition.test.cjs`; `node --test test_js/ci-monitor.test.cjs`; `bash scripts/test_check_phase178_candidate.sh` | `rerun-gate/node-lists.log` | pass | 63 + 5 + 11 checks | 63 + 5 + 11 pass | 3 s | Demo evidence / Operator setup, advisory |
| Node CI monitor | `node --test test_js/ci-monitor.test.cjs` | `rerun-gate/node-ci-monitor.log` | pass | 5 | 5 pass | 0 s | Operator Browser Gate setup, advisory |
| Candidate self-test | `bash scripts/test_check_phase178_candidate.sh` | `rerun-gate/candidate-selftest.log` | pass | 11 | 11 pass | 1 s | Candidate runner, local |
| CI require guard | `mix test test/scripts/ci_node_test_requires_contract_test.exs` | `rerun-gate/require-guard-contract.log` | pass | 4 | 4 tests, 0 failures | 2 s | Mix Task Tests / Core Deterministic Suite, required |
| CI lane contract | `mix verify.ci_lane_contract` | `rerun-gate/ci-lane-contract.log` | expected local-only red: `phase_164_repository_truth_test.exs:261` (`.gsd/.gitignore` is local-only) | 511 | 480 executed, 1 known failure, 31 excluded | 329 s | Mix Task Tests / Core Deterministic Suite, required; four proofs in `178-12-SUMMARY.md` |
| Format | `mix format --check-formatted` | `rerun-gate/format.log` | pass | n/a | clean | 0 s | Format Check, required |
| Credo | `bash scripts/check_credo_suppressions.sh && mix run scripts/check_static_analysis_exceptions.exs && mix credo --strict` | `rerun-gate/credo.log` | pass | 81 checks | 565 files, no issues | 4 s | Credo Strict, required |
| Admin suite | `cd mailglass_admin && mix verify.support_contract.admin --seed 0` | `rerun-gate/admin-suite.log` | pass | n/a | 1205 tests, 0 failures, 1 excluded | 19 s | Support Contract Admin, required |
| Operator suite | `cd mailglass_admin && CI=1 ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm run test:operator-browser` | `rerun-gate/operator-suite.log` | pass | 311 | 310 passed, 1 named guarded skip, 0 failed, 0 flaky | 397 s | Operator Browser Gate, advisory |
| Operator list | `cd mailglass_admin && npx playwright test --config=playwright.config.cjs --list` | `rerun-gate/operator-list.log` | pass | 311 | 311 tests in 18 files | 1 s | Operator Browser Gate, advisory |
| Demo list | `cd reference/demo_app/assets && npx playwright test --list` | `rerun-gate/demo-list.log` | pass | 111 | 111 tests in 14 files | 1 s | Demo Browser Evidence, advisory |
| Demo lock | `cd reference/demo_app && mix deps.get --check-locked` | `rerun-gate/lock-check.log` | pass; known cowlib advisory only | n/a | lock matches | 2 s | Demo Browser Evidence, advisory |
| Demo cold/warm pilot | `bash scripts/run_demo_browser_evidence.sh --phase174 --phase175 --pilot` | `rerun-gate/pilot.log` | pass | 169 per condition | 169 cold and 169 warm; 111 Demo, 6 hooks, 26 fidelity, 26 axe each | 612 s | Demo Browser Evidence, advisory |
| Pilot receipts | Both Phase 174/175 pilot checkers, plus exact-revision and Phase 178 story report checks | `rerun-gate/pilot-checkers.log` | pass | both Phase 178 stories in each report | checkers pass; cold/warm story specs `ok: true`; `source_revision` matches G | 0 s | Demo Browser Evidence, advisory |

### Not-affected CI lanes

Each command below is `git diff --name-only dd392b87a5c99895495f046241242b3eb35c5e64..baf5685e1a9b943d41b884b007fdea5fa45fa498 -- <paths>` and produced no output (empty changed-path set):

| Lane | Paths checked | Result |
| --- | --- | --- |
| Compile Warnings / Compile No Optional Deps | `lib mix.exs mix.lock config` | not affected |
| Inbound Compile No Optional Deps | `lib mix.exs mix.lock config mailglass_inbound` | not affected |
| Installer Host Smoke | `lib mix.exs mix.lock config mailglass_admin/lib mailglass_admin/mix.exs mailglass_admin/mix.lock` | not affected |
| Installer Golden Gate | `lib mix.exs mix.lock config priv test/mailglass/install test/support` | not affected |
| Inbound Test | `mailglass_inbound` | not affected |
| Dialyzer | `lib mix.exs mix.lock config .dialyzer_ignore.exs scripts/check_dialyzer_ignore.sh` | not affected |
| Inbound Dialyzer | `lib mix.exs mix.lock config .dialyzer_ignore.exs scripts/check_dialyzer_ignore.sh mailglass_inbound` | not affected |
| Trust Lane Repo Head | `lib mix.exs mix.lock config mailglass_inbound reference/host_app scripts/check_trust_runner_checkpoint.sh` | not affected |
| Design System Conformance | `mailglass_admin/assets/css mailglass_admin/priv/static mailglass_admin/scripts/check-conformance.sh mailglass_admin/scripts/check-conformance-advisory.sh` | not affected |

The Operator build left `mailglass_admin/priv/static` clean. The Demo lock change is limited to the named `phoenix_html` refresh and is committed as `chore(deps):`.

### Re-frozen candidate

rerun_candidate_sha: 255422cbe6e16c570ccb465246c2394fa3190866

- **Commit subject:** `docs(178-15): point acceptance closure at gap plans`.
- **No source changed after the gate:** `git diff --quiet baf5685e1a9b943d41b884b007fdea5fa45fa498 255422cbe6e16c570ccb465246c2394fa3190866 -- . ':(exclude).planning'` exits 0, and `git status --porcelain -- mailglass_admin reference scripts test lib test_js` prints nothing. `mailglass_admin/priv/static` and `reference/demo_app/mix.lock` are clean.
- **Remote refs, read-only:** after `git fetch origin main gsd/v2.10-ui-repairs-storybook`, `origin/main` is `8328093e4a07d28251ec7f02dd0f37cda2fd6a7b` and `origin/gsd/v2.10-ui-repairs-storybook` is `2bdf18161182beeb286435b556f26e205976e658`. `git ls-remote` agrees with both values, and the branch equals `rerun_branch_sha_before`.
- **Ancestor checks:** `git merge-base --is-ancestor origin/main 255422cbe6e16c570ccb465246c2394fa3190866` and the same check for `origin/gsd/v2.10-ui-repairs-storybook` both exit 0. The candidate is a plain fast-forward from both refs.
- **Commits ahead:** 396 ahead of `origin/main`, 45 ahead of `origin/gsd/v2.10-ui-repairs-storybook`.
- **Source commits the push would add to the branch:**

  ```text
  ea1e09b1 test(178-15): isolate workspace evidence sync markers
  5d625006 test(178-15): reduce CI contract parser nesting
  ad10d639 test(178-15): stabilize Demo theme screenshot captures
  1cc410df test(178-15): allow time for loader contract checks
  397c8391 test(178-15): wait for browser fixtures before readiness
  f90c37e6 chore(deps): refresh reference/demo_app lock (phoenix_html 4.3.0 => 4.4.0)
  5ee9a173 test(178-14): self-diagnosing scroll-access helper
  befeb47e test(178-13): measure a recorded advisory Operator red in the cost disposition
  33e485a5 test(178-13): reproduce disposition refusing a recorded advisory Operator red
  a6a136e0 test(178-13): count each hosted Operator summary line once
  b2102ced test(178-13): reproduce hosted Operator summary double count
  534a6898 test(178-13): prove the require guard's teeth with hermetic fixtures
  92704fc2 test(178-13): load Playwright lazily in the Storybook axe supplement
  71122b66 test(178-13): add ci.yml node --test require guard (red)
  ```
- **Run history:** read-only `gh run list --branch gsd/v2.10-ui-repairs-storybook --limit 20` found only runs through `40904249445`, all on the superseded SHA `2bdf18161182beeb286435b556f26e205976e658`; no newer run exists.
- **Remote actions taken by plan 178-15: none.** No push, pull request, workflow dispatch, rerun or merge. The record commit below comes after the candidate and is never pushed.

## Acceptance closure (D-15)

Every row without a status token is closed by the test or command it cites. A pending row closes only when its hosted verify passes on the re-frozen candidate; 178-17 or 178-18 then records it as closed with the run or record. A decline or a stop records it as open with the reason, which means unmet. Every row is `source: automated`, and the lane column names its required or advisory placement.

| Requirement | Acceptance item | Covering test or command | Lane | Source |
| --- | --- | --- | --- | --- |
| PRVUX-05 | The assigns form ends with one bordered, aligned Restore defaults action (full width below `sm`, end-aligned from `sm`, at least 44 px tall) | `preview_live_test.exs` "the assigns form ends with one Restore defaults action using the secondary classes"; `mix verify.support_contract.admin --seed 0` | `support_contract_admin` (required) | source: automated |
| PRVUX-05 | The `reset_assigns` event and its restore and error-clear behavior are unchanged | `phase178_prohibition_contract_test.exs` P5, mutation-proven (see "Prohibition contract (D-15)"); `git diff --quiet 61e90275 HEAD -- mailglass_admin/lib/mailglass_admin/preview_live.ex` | `support_contract_admin` (required) | source: automated |
| PRVUX-05 | Geometry, visible border and focus ring at 390, 639, 640 and 1280 px in light and dark, and under reduced motion | `structural.spec.js` "Preview: Phase 178 restore defaults geometry, border and focus" and "Preview: Phase 178 restore defaults under reduced motion" (`operator_browser_gate`, 310 passed) | `operator_browser_gate` (advisory) | source: automated |
| PRVUX-06 | No generic per-field type helper; one form-level read-only note; every `aria-describedby` and `aria-labelledby` id resolves | `preview_live_test.exs` "one form-level note describes read-only values and each display references it" and "every typed_values page state resolves its aria references"; contract P1 and P2 | `support_contract_admin` (required) | source: automated |
| PRVUX-06 | The Preview axe cell is unchanged for light, dark and system | `structural.spec.js` "Preview: Phase 178 axe cell matches the committed baseline" | `operator_browser_gate` (advisory) | source: automated |
| PRVUX-07 | Selector shows the humanized scenario first, the Mailable second and the exact `Module.scenario` identity as visible text; colliding labels fall back to raw atoms; URLs byte-identical | `preview/scenario_label_test.exs` (24 tests); `preview_live_test.exs` "compact picker exposes long non-ASCII scenario identity without truncation" and "option hrefs are the unchanged scenario_path/6 output, with and without return context"; contract P3 and P4 | `support_contract_admin` (required) | source: automated |
| PRVUX-07 | Duplicate long Unicode scenarios are distinguishable in light and dark and under reduced motion; the option link name pins match the new markup | `structural.spec.js` "Preview: Phase 178 selector distinguishes duplicate long Unicode ...", "selector identity reads in light and dark", "selector under reduced motion"; `flows.spec.js` "Preview edge: index redirects into the unified scenario layout at 320" | `operator_browser_gate` (advisory) | source: automated |
| STORY-07 | Every owner-feedback row is story-backed or carries a counted connected-only boundary; the accounting table in this file equals the computed table | `feedback_ledger_test.exs` "accounting" cases (`mix test test/mailglass_admin/feedback_ledger_test.exs --seed 0 --trace`) | `support_contract_admin` (required) | source: automated |
| STORY-07 | The three retained Preview authoring stories render the production components and agree with the live route's field set | `quick_view_projection_test.exs` (tag `phase178`) "Phase 178 Preview authoring typed values story render shows the live route's field set" and the no-editable and field-error cases | `support_contract_admin` (required) | source: automated |
| STORY-07 | Each retained Preview authoring story has exactly one frame and renders its production roots in light, dark and system | `phase178-stories.spec.js` "Phase 178 retained Preview authoring stories render through production components" (`demo_browser_evidence`, 111 cold and 111 warm) | `demo_browser_evidence` (advisory) | source: automated |
| UIQ-04 | No feedback row is `pending` or `partial`; every pointer resolves to a real file and heading; scenarios link both ways | `feedback_ledger_test.exs` "Phase 178 ledger: no feedback row is pending or partial" and the rule and link cases (13 mutations, plan 178-02); contract P6 | `support_contract_admin` (required) | source: automated |
| UIQ-06 | The StatCard story uses the production font roles (computed family and weight equal the Admin gallery's; no serif) | `phase178-stories.spec.js` "Phase 178 StatCard story uses the production font roles" (`demo_browser_evidence`) | `demo_browser_evidence` (advisory) | source: automated |
| UIQ-06 | The StatCard font-role and retained Preview stories receipts reproduce in the hosted Demo lane, cold and warm | 178-17 task 1 hosted receipt verify on `rerun_candidate_sha` | `demo_browser_evidence` (advisory) | source: automated; status: pending |
| UIQ-06 | Actual 200% Chromium tab zoom at 320 CSS px for the Delivery and Inbound quick views, Health, the Account control, the Filters and Preview | `phase178-real-zoom.spec.js` (5 cases) and `structural.spec.js` Phase 171 actual 200% zoom case (`operator_browser_gate`) | `operator_browser_gate` (advisory) | source: automated |
| UIQ-06 | No test labels CSS zoom as real zoom | `phase178_prohibition_contract_test.exs` P7, mutation-proven | `support_contract_admin` (required) | source: automated |
| UIQ-06 | The repaired surfaces add or change no hook | the Hook receipts commands above: `grep -n 'phx-hook' mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex mailglass_admin/lib/mailglass_admin/preview/sidebar.ex` exits 1, and `git diff --quiet 61e90275 HEAD -- mailglass_admin/lib/mailglass_admin/preview/tabs.ex mailglass_admin/priv/static/hooks.js` exits 0 | planning record | source: automated |
| UIQ-07 | Expected and executed test counts are recorded for both browser suites and every difference is explained by name | this file, `rerun_operator_list_count`, `rerun_operator_named_skips`, `rerun_demo_list_count`, `rerun_demo_receipt_expected_total`, and unit-declared `expected.json`, all measured at `rerun_gate_head_sha`; checked by the 178-15 task 1 counts verify | `operator_browser_gate`, `demo_browser_evidence` (advisory) | source: automated |
| UIQ-07 | The projected hosted Operator Browser Gate time is within 0.8 x the job timeout, or carries a remedy | this file, `rerun_operator_projected_hosted_s` and `rerun_operator_timeout_disposition`; checked by the 178-15 task 1 projection verify | `operator_browser_gate` (advisory) | source: automated |
| UIQ-07 | The hosted run executes the same counts, and the hosted cost is derived deterministically | 178-17 tasks 1 and 2 hosted evidence and cost-disposition verifies on `rerun_candidate_sha` | `operator_browser_gate`, `demo_browser_evidence` (advisory) | source: automated; status: pending |
| UIQ-08 | Every CI Green need passes locally on the candidate, or is shown not affected | the re-gate table and not-affected lanes in this section; logs are headed by `rerun_gate_head_sha`; checked by the 178-15 task 1 verifies | `ci_green` aggregate (required) | source: automated |
| UIQ-08 | A hosted-only missing-package red in any `ci.yml` `node --test` step is caught by a required lane | `test/scripts/ci_node_test_requires_contract_test.exs` | `mix_task_tests`, `core_deterministic_suite` (required) | source: automated |
| UIQ-08 | The phase diff has a standard-depth review with every finding dispositioned, and no gate was weakened | `178-REVIEW.md` for `61e90275..dd392b87`; `178-REVIEW-DISPOSITION.md` `Gap-closure review` for `dd392b87..<rerun_gate_head_sha>`; `rerun-gate/gate-integrity.log`; checked by the 178-15 task 1 verifies | planning record | source: automated |
| UIQ-08 | The frozen candidate has both remote refs as ancestors, so the push is a plain fast-forward, and no source changed after the freeze | 178-15 task 3 verify: `rerun_candidate_sha`, both `git merge-base --is-ancestor` checks, and no source diff after the gate head or candidate | planning record | source: automated |
| UIQ-08 | The hosted candidate has required CI green, and the preview runs the exact SHA | 178-17 task 1 required-CI/exact-SHA verify and 178-18 tasks 1 and 2 runbook URL verifies on `rerun_candidate_sha` | `ci_green` aggregate (required) | source: automated; status: pending |

The UIQ-08 ship/no-ship review (plan 178-10, the owner decision) is the only owner hand-off allowed by D-52. It is a judgment on shipping, not an acceptance row, and nothing in the table above waits on it.

## Hosted candidate evidence (UIQ-07, UIQ-08)

pre_approval_main_sha: 8328093e4a07d28251ec7f02dd0f37cda2fd6a7b
pre_approval_branch_sha: 25dc21cff0948eb75c0b00ec39cc06f4bb410e06

### Pre-approval state (plan 178-09 task 1, read-only, 2026-10-29)

- Candidate: `2bdf18161182beeb286435b556f26e205976e658` (`docs(178-08): phase diff review and dispositions`). `git diff --quiet <sha> HEAD -- . ':(exclude).planning'` exits 0.
- Remote refs (`git ls-remote origin`): `refs/heads/main` is `8328093e4a07d28251ec7f02dd0f37cda2fd6a7b`; `refs/heads/gsd/v2.10-ui-repairs-storybook` is `25dc21cff0948eb75c0b00ec39cc06f4bb410e06`. Both equal the 178-08 values; no remote write has happened.
- `gh pr list --head gsd/v2.10-ui-repairs-storybook --state all` returned `[]`. `gh run list --branch gsd/v2.10-ui-repairs-storybook` returned `[]`.
- Live scope after `git fetch origin main gsd/v2.10-ui-repairs-storybook`:
  - against `origin/main`: 351 commits ahead (`git rev-list --count origin/main..<sha>`); 656 files changed, 213365 insertions, 2163 deletions (`git diff --shortstat origin/main...<sha>`);
  - against `origin/gsd/v2.10-ui-repairs-storybook`: 52 commits ahead; 68 files changed, 13048 insertions, 233 deletions (`git diff --shortstat origin/gsd/v2.10-ui-repairs-storybook..<sha>`).
- Pipeline dry run on the baseline (run 40414024714, jobs saved as one 26-job page): the `disposition` subcommand with the baseline standing in for the PR and dispatch runs and the retained Phase 174 `phase174/cost.json` reports every job delta 0 and 0 runner-minute delta in both runs. It finds `Demo Browser Evidence (Docker Compose / Chromium)`, `Operator Browser Gate (Elixir 1.18 / OTP 27 / Node 22) (22)` and `Support Contract Admin (Elixir 1.18 / OTP 27)` by exact name, and `pilot_conditions` has cold and warm. Expected counts written: operator 311, demo 111 (the 178-08 `--list` totals).
- Approval text drafted from these numbers; the PR body is `reference/demo_app/tmp/phase178_candidate/pr-body.md` (git-ignored). The next step is the owner checkpoint 178-09-02.

### Owner decision (checkpoint 178-09-02)

owner_decision: approve-all

The owner answered the checkpoint directly (AskUserQuestion in the orchestrator session) with `approve-all`, recorded verbatim. It authorizes exactly: the fast-forward push of the candidate SHA to `gsd/v2.10-ui-repairs-storybook`, one draft PR to main, and one `workflow_dispatch` of `ci.yml` on that branch. No rerun, merge, further push or PR edit is authorized. Before pushing, the remote was re-verified: `gsd/v2.10-ui-repairs-storybook` is still `25dc21cff0948eb75c0b00ec39cc06f4bb410e06` (an ancestor of the candidate), `main` is still `8328093e4a07d28251ec7f02dd0f37cda2fd6a7b`, and no PR exists for the branch.

### Remote actions

Run exactly as authorized, once each, from `/Users/jon/projects/mailglass` (times UTC, 2026-10-29):

1. 15:41:51Z `git push origin 2bdf18161182beeb286435b556f26e205976e658:refs/heads/gsd/v2.10-ui-repairs-storybook` -> `25dc21cf..2bdf1816` (fast-forward, no force). `git ls-remote` afterwards: branch `2bdf18161182beeb286435b556f26e205976e658`, main `8328093e4a07d28251ec7f02dd0f37cda2fd6a7b` (unchanged).
2. 15:42:06Z `gh pr create --draft --base main --head gsd/v2.10-ui-repairs-storybook --title "chore(ui): v2.10 UI repairs review candidate (do not merge)" --body-file reference/demo_app/tmp/phase178_candidate/pr-body.md` -> https://github.com/szTheory/mailglass/pull/317 (no earlier PR existed for the branch; draft, open).
3. 15:42:15Z `gh workflow run ci.yml --ref gsd/v2.10-ui-repairs-storybook` -> https://github.com/szTheory/mailglass/actions/runs/40904249445 (workflow_dispatch, headSha = candidate, attempt 1).

The PR creation started the `pull_request` CI run https://github.com/szTheory/mailglass/actions/runs/40904235961 (attempt 1; headSha = candidate).

pr_number: 317
pr_run_id: 40904235961
dispatch_run_id: 40904249445

Both approved runs reached `completed` at attempt 1 (no rerun). The PR run concluded `failure` and the dispatch run concluded `failure`; classification is task 4.

remote_runs_status: completed

### Hosted classification (plan 178-09 task 4)

Both approved runs completed at attempt 1 and concluded `failure`. Logs were fetched read-only (`gh api --allow-escape-sequences .../jobs/<id>/logs`) and saved before classification. No rerun ran.

| Run | Event | Job | Conclusion | Saved log | SHA-256 |
|-----|-------|-----|------------|-----------|---------|
| 40904235961 | pull_request | Demo Browser Evidence (Docker Compose / Chromium) | failure | `reference/demo_app/tmp/demo_browser_evidence/ci/40904235961-attempt-1/demo-job.log` | `66c1f1ac333847ef8056ac33591e5da586555ebf73ab833fba313c7ef0bfb54f` |
| 40904235961 | pull_request | Operator Browser Gate (Elixir 1.18 / OTP 27 / Node 22) (22) | failure (1 failed, 1 skipped, 309 passed) | `reference/demo_app/tmp/demo_browser_evidence/ci/40904235961-attempt-1/operator-gate.log` | `f174338e8222ea127bc9ae7d93e698bb14e77fe55679dcf5859df547f47e9516` |
| 40904249445 | workflow_dispatch | Demo Browser Evidence (Docker Compose / Chromium) | failure | `reference/demo_app/tmp/demo_browser_evidence/ci/40904249445-attempt-1/demo-job.log` | `6703d781e8e3ee7c934d7c919a746e51bdeb2d1771207718be34762b6b45e646` |
| 40904249445 | workflow_dispatch | Operator Browser Gate | success | not needed | n/a |

Required contexts for the candidate SHA `2bdf18161182beeb286435b556f26e205976e658` (`gh api repos/szTheory/mailglass/commits/<sha>/check-runs`): `CI Green` = success, `Guard Release Trigger` = success. Preview Capture Advisory = success in the PR run.

Failure detail:

- Demo Browser Evidence (both runs, identical): the step `node --test scripts/check_phase174_evidence.test.cjs scripts/check_phase175_evidence.test.cjs scripts/phase174-review-claims.test.cjs mailglass_admin/e2e/support/storybook-axe.test.cjs` exits 1 in about 1 s. `mailglass_admin/e2e/support/storybook-axe-supplement.cjs:1` requires `@playwright/test`, which is not installed in that job (`Error: Cannot find module '@playwright/test'`, `MODULE_NOT_FOUND`), so `not ok 1 - mailglass_admin/e2e/support/storybook-axe.test.cjs` (18 of 19 pass). No evidence was captured, and the artifact upload found no files. This is a source or workflow defect in the candidate (the test passes locally because `mailglass_admin/e2e` dependencies are installed there). Its title matches no recorded advisory title; the Demo matched set is empty by construction.
- Operator Browser Gate, pull_request run only: `e2e/flows.spec.js:2453:3 > flows: a11y deltas - reveal disclosure + replay focus-trap + double-submit (D-11/D-14) > Phase174 scroll access: Inbound overflow is keyboard reachable and both navigation boundaries are disabled` failed (`expect(received).toBe(expected)`). Not in the recorded set (the 177 "scan deliveries" timeouts, the 178-08 list, which is empty, and the Pitfall 4 cold-start window). The same job passed in the dispatch run on the same SHA.

Per the plan's stop rule, a new advisory failure stops the plan and is never patched here; a source fix needs a new freeze and a new 178-09-02 approval.

hosted_status: stopped: new advisory failure (Demo Browser Evidence (Docker Compose / Chromium))
stop_job: Demo Browser Evidence (Docker Compose / Chromium)
stop_log: reference/demo_app/tmp/demo_browser_evidence/ci/40904249445-attempt-1/demo-job.log

UIQ-07's hosted measurement and UIQ-08's required CI are not met on this candidate; the plan stopped with the status above. (Note: the required check runs `CI Green` and `Guard Release Trigger` were success for the candidate SHA, but the Demo Browser Evidence pilot checkers did not run on hosted, so the identity-bound evidence and the hosted cost disposition do not exist. The status line above is authoritative.)

Run, job and PR URLs:

- PR: https://github.com/szTheory/mailglass/pull/317 (draft, open, not merged)
- pull_request run: https://github.com/szTheory/mailglass/actions/runs/40904235961 (Demo job https://github.com/szTheory/mailglass/actions/runs/40904235961/job/123554577451; Operator Browser Gate job https://github.com/szTheory/mailglass/actions/runs/40904235961/job/123554577630)
- workflow_dispatch run: https://github.com/szTheory/mailglass/actions/runs/40904249445 (Demo job https://github.com/szTheory/mailglass/actions/runs/40904249445/job/123554654315)

Post-action audit (2026-10-29): PR 317 `isDraft true`, `OPEN`, `mergedAt null`; `git ls-remote origin refs/heads/main` = `8328093e4a07d28251ec7f02dd0f37cda2fd6a7b` (equals `pre_approval_main_sha`); `.planning/release-target.json` unchanged; both runs at attempt 1.

## Placement, cost and limits (UIQ-07)

not measured: hosted run stopped (stopped: new advisory failure (Demo Browser Evidence (Docker Compose / Chromium))); see stop_log `reference/demo_app/tmp/demo_browser_evidence/ci/40904249445-attempt-1/demo-job.log`. No `178-COST-DISPOSITION.json` was created and no hosted cost, count or placement figure is claimed. The Demo Browser Evidence job failed before capture in both the pull_request and workflow_dispatch runs (a missing `@playwright/test` module in the pre-capture `node --test` step), so no hosted pilot receipt exists. The job wall and runner-minute figures in the saved raw run/jobs JSON were not dispositioned against the budgets.

## Not run: plan 178-10 (UIQ-08)

Plan 178-10 did not run (2026-10-29). Its precondition requires `owner_decision:` approve-all or approve-push-and-pr-only AND `hosted_status: completed`. This file records `owner_decision: approve-all` but `hosted_status: stopped: new advisory failure (Demo Browser Evidence (Docker Compose / Chromium))` (section "Hosted classification", plan 178-09 task 4). Not run: hosted candidate not approved or not completed.

No candidate preview was launched, no runbook (`178-DELIVERY.md`) was written, the ship/no-ship checkpoint was not presented, and no remote action was taken. `review_demo_count_before` was not recorded because no Docker work ran. UIQ-07 and UIQ-08 remain unmet for this phase.

Blocking defect: `.github/workflows/ci.yml` (root Demo Browser Evidence job) runs `node --test ... mailglass_admin/e2e/support/storybook-axe.test.cjs`, whose `storybook-axe-supplement.cjs:1` requires `@playwright/test`, which that job never installs (`MODULE_NOT_FOUND`). Introduced in Phase 175 and first hosted-run by 178-09. The PR-run Operator Browser Gate failure at `e2e/flows.spec.js:2453` is recorded, undiagnosed, and passed in the dispatch run on the same SHA. Moving on needs a fix to that job, a new candidate freeze and a new 178-09-02 approval.

## PR-run Operator Browser Gate failure (flows.spec.js:2453)

operator_pr_flake_evidence_dir: reference/demo_app/tmp/phase178_candidate/opgate-pr-40904235961
operator_pr_flake_outcome: classified-nondeterministic
operator_pr_flake_repeats: 50/50
recorded_advisory_title: Phase174 scroll access: Inbound overflow is keyboard reachable and both navigation boundaries are disabled | classification=nondeterministic-no-product-defect | log=reference/demo_app/tmp/phase178_candidate/opgate-pr-40904235961/classification-repeat.log | log_sha256=639827cec53c9a14d0cebb19dc51dad1e8175d01a7116605d7a11e1cd69e845e | repeats=50/50

The failure is the exact test title `Phase174 scroll access: Inbound overflow is keyboard reachable and both navigation boundaries are disabled` in pull request run 40904235961. The saved log is `reference/demo_app/tmp/demo_browser_evidence/ci/40904235961-attempt-1/operator-gate.log`, SHA-256 `f174338e8222ea127bc9ae7d93e698bb14e77fe55679dcf5859df547f47e9516`. It reports `expect(received).toBe(expected)`, Expected `true`, Received `false`, after the 5-second End poll. It failed on attempt 1 and retry 1.

Trace artifacts from `operator-browser-timeout-evidence-40904235961-node-22` are saved under the evidence directory:

| Attempt | Trace SHA-256 | Focus and scroll evidence |
|---|---|---|
| attempt 1 | `dde73155916d483700b69d38ba8b4409ea860de27c821684ea5e8a40d411b825` | focus call `call@5129`; active-element evaluation `call@5131` returned `inbound-quick-view`; PageDown `call@5133`; post-PageDown snapshot `call@5139` recorded scrollTop 625; End `call@5143`; post-End snapshot recorded scrollTop 630. |
| retry 1 | `475fb82752343c0fe8b7f08dd8448e4b99ced22858e4b8a501247396e3a1c0f0` | focus call `call@62`; active-element evaluation `call@64` returned `inbound-quick-view`; PageDown `call@66`; post-PageDown snapshot `call@72` recorded scrollTop 625; End `call@76`; post-End snapshot recorded scrollTop 630. |

The snapshots do not record `clientHeight` or `scrollHeight`, and the Playwright trace does not serialize the poll callback's numeric result. Both traces keep the same page, main frame, URL and `inbound-quick-view` element through the key presses and polls; no frame navigation or dialog replacement appears. The `0-trace.network` HAR contains resource snapshots and no WebSocket frame records, so it shows no LiveView patch during this interval. The End poll's false result is the recorded failure; the available trace cannot establish the expected bottom dimensions. The trace artifacts, both `error-context.md` files and server capture are retained in the evidence directory.

The PR merge tree equals the candidate: `git rev-list --count 2bdf18161182beeb286435b556f26e205976e658..8328093e4a07d28251ec7f02dd0f37cda2fd6a7b` returned `0`. On that same tree, the Dispatch run 40904249445 passed this target test.

Under `CI=1` and the pinned Elixir/OTP toolchain, the target passed `50/50` repeats in `classification-repeat.log` (SHA-256 recorded on the advisory line above). It also passed the final `30/30` check in `local-target-30.log`; the shared-helper Delivery sibling passed `10/10` in `local-delivery-10.log`. The first complete in-order `e2e/flows.spec.js` run reported 45 passed and 1 failed in `local-flows-full.log`; the unrelated Phase 168 Delivery Mailable wrapping case failed during account switching/quick-view setup. It passed in isolation (`local-mailable-isolated.log`, 1 passed), and a fresh full in-order run passed all 46 tests (`local-flows-full-rerun.log`, 0 failures). The target Inbound test passed in both full-file runs.

The temporary focus-loss mutation (`dialog.blur()` immediately before the End-side precondition) failed as intended: `precondition-red.log` reports `Expected: "inbound-quick-view"`, `Received: "BODY"`. The mutation was removed, leaving the two inline active-element polls around PageDown and End.

One separate local harness startup race was observed during an invalid repeat attempt: `/ops/browser-ready` returns `200` before the startup fixture seed completes, allowing Playwright's first `/ops/browser-reset` to compete with that seed on the shared SQL Sandbox connection. The server then exited before the test ran, so those failures do not count toward the 50-repeat result. For the valid run, the server was started and allowed to log `fixtures_seeded` and `ready` before Playwright connected; a temporary local config enabled reuse of that already-ready server. The tracked Playwright config and retry policy were unchanged. This local startup issue does not appear in the saved hosted traces and does not explain the hosted End-key result.

Outcome: `classified-nondeterministic`. The PR and dispatch runs used the same tree; both saved hosted traces show focus on `inbound-quick-view`, PageDown advancing `scrollTop`, and End advancing it further, with the dialog and frame remaining stable. The traces omit the dimensions and poll callback value needed to identify why the final bottom predicate was false. No product or test cause for the hosted result appears in the available trace evidence. The required `50/50` target repeats and full in-order suite pass establish the classification threshold; the advisory line above records the exact title for plan 178-17.

## Hosted candidate re-run (UIQ-06, UIQ-07, UIQ-08)

### Pre-approval state (read-only, 2026-11-01)

rerun_pre_approval_main_sha: 8328093e4a07d28251ec7f02dd0f37cda2fd6a7b
rerun_pre_approval_branch_sha: 2bdf18161182beeb286435b556f26e205976e658

- Candidate under review: 255422cbe6e16c570ccb465246c2394fa3190866 (docs(178-15): point acceptance closure at gap plans). The candidate has both recorded remote refs as ancestors and no source diff after the re-gate.
- Live scope from the fetched refs: against origin/main, 396 commits ahead, 675 files changed, 216803 insertions and 2166 deletions; against origin/gsd/v2.10-ui-repairs-storybook, 45 commits ahead, 32 files changed, 3480 insertions and 45 deletions.
- Existing PR: #317, https://github.com/szTheory/mailglass/pull/317, state OPEN, draft, not merged.
- Stopped dispatch run: 40904249445, completed with failure, https://github.com/szTheory/mailglass/actions/runs/40904249445.
- Stopped pull_request run: 40904235961, completed with failure, https://github.com/szTheory/mailglass/actions/runs/40904235961.
- Read-only branch run list returned runs 40904249445, 40904236058, 40904235995, 40904235953, 40904235938 and 40904235961; all have head SHA 2bdf18161182beeb286435b556f26e205976e658.
- The compare URL https://github.com/szTheory/mailglass/compare/main...gsd/v2.10-ui-repairs-storybook resolves to status ahead.
- A no-FETCH_HEAD fetch refreshed local refs; git ls-remote matched the recorded main and branch SHAs.

Pre-approval measurement pipeline:
- Copied baseline-run.raw.json and baseline-jobs.raw.json from disposition-inputs/; cmp confirms the copies match.
- Self-comparison output: reference/demo_app/tmp/phase178_candidate/rerun-disposition-inputs/self-check.json. It finds Demo Browser Evidence, Operator Browser Gate and Support Contract Admin by exact name for both workflow_dispatch and pull_request, with all job, CI-green wall-time and runner-minute deltas equal to zero. Cold and warm pilot conditions are present. The advisory-red input SHA-256 is e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855.
- Draft PR body: reference/demo_app/tmp/phase178_candidate/rerun-pr-body.md. Its final attribution names OpenAI Codex, matching the configured runtime.

Source-only commits the candidate would add to the branch:

```text
ea1e09b1 test(178-15): isolate workspace evidence sync markers
5d625006 test(178-15): reduce CI contract parser nesting
ad10d639 test(178-15): stabilize Demo theme screenshot captures
1cc410df test(178-15): allow time for loader contract checks
397c8391 test(178-15): wait for browser fixtures before readiness
f90c37e6 chore(deps): refresh reference/demo_app lock (phoenix_html 4.3.0 => 4.4.0)
5ee9a173 test(178-14): self-diagnosing scroll-access helper
befeb47e test(178-13): measure a recorded advisory Operator red in the cost disposition
33e485a5 test(178-13): reproduce disposition refusing a recorded advisory Operator red
a6a136e0 test(178-13): count each hosted Operator summary line once
b2102ced test(178-13): reproduce hosted Operator summary double count
534a6898 test(178-13): prove the require guard's teeth with hermetic fixtures
92704fc2 test(178-13): load Playwright lazily in the Storybook axe supplement
71122b66 test(178-13): add ci.yml node --test require guard (red)
```

### Approval checkpoint draft

Candidate: 255422cbe6e16c570ccb465246c2394fa3190866, docs(178-15): point acceptance closure at gap plans.

The previous hosted candidate stopped because Demo Browser Evidence failed before capture: @playwright/test was missing from that job's node test. Plan 178-13 fixed lazy loading and added a required missing-package guard. Plan 178-14 classified the pull_request-only flows.spec.js:2453 failure as nondeterministic after 50/50 local repeats and added focus diagnostics. Plan 178-15 passed the affected local gates and a new cold/warm Demo pilot on the candidate's source tree.

Live scope: against main SHA 8328093e4a07d28251ec7f02dd0f37cda2fd6a7b, 396 commits ahead with 675 files changed, 216803 insertions and 2166 deletions. Against branch SHA 2bdf18161182beeb286435b556f26e205976e658, 45 commits ahead with 32 files changed, 3480 insertions and 45 deletions. The source commits added by the push are listed above.

Review runbook, resolved immediately before this draft:
1. PR 317: https://github.com/szTheory/mailglass/pull/317 — open, draft and not merged.
2. Dispatch run 40904249445: https://github.com/szTheory/mailglass/actions/runs/40904249445 — completed; Demo Browser Evidence failed before capture.
3. Pull request run 40904235961: https://github.com/szTheory/mailglass/actions/runs/40904235961 — completed; Demo Browser Evidence failed before capture and Operator Browser Gate also failed on the recorded nondeterministic title.
4. Branch compare: https://github.com/szTheory/mailglass/compare/main...gsd/v2.10-ui-repairs-storybook — ahead.

Approve-all authorizes exactly these actions: fast-forward push candidate 255422cbe6e16c570ccb465246c2394fa3190866 to gsd/v2.10-ui-repairs-storybook; update the body of draft PR #317 from rerun-pr-body.md; and dispatch ci.yml once on that branch. The push starts the pull_request run automatically. Estimated hosted cost is about 100 runner-minutes per workflow run, for two runs. No rerun is included.

Approve-push-and-pr-only authorizes the push and PR body update without a dispatch. It does not provide the D-12 identity binding because the PR run builds the merge commit. The hosted Demo receipts and UIQ-07 cost disposition cannot be bound to the candidate; the UIQ-06 hosted receipt and UIQ-07 rows will remain open as unmet.

Decline performs no remote action. UIQ-06 hosted receipts, UIQ-07 hosted measurement and UIQ-08 required CI remain unmet, and plans 178-17 through 178-19 do not run.

Only recorded Operator Browser Gate or Preview Capture Advisory reds may continue: every failing title must already be recorded, and its title, saved log and hash are recorded. A failed Operator Browser Gate is measured with its duration, failure conclusion and matched titles. Any Demo Browser Evidence red, required-context red, or other failure stops the plan. Nothing is merged, released, published or deployed.

The new owner reply must be one of: approve-all, approve-push-and-pr-only, or decline. No remote write occurs before that user-originated choice.
