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
