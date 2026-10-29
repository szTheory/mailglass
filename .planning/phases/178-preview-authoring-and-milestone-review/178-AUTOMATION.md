# Phase 178 automated proof and reproduction

This record closes the Phase 178 machine-observable requirements named below against retained tests and retained story scenarios. It does not claim provider delivery, hosted CI execution, or an owner aesthetic verdict. Deterministic acceptance is automated under METHODOLOGY.md D-52. Later plans append the fidelity and ledger sections (178-07) and the prohibition contract (178-11); hosted sections come after the candidate.

## Reproduce and check

Run from the repository root. Every `mix` command needs the toolchain pin `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27`; `.tool-versions` is the CI contract and is not edited.

```sh
# Preview authoring form and selector (merge-blocking)
cd mailglass_admin && mix test test/mailglass_admin/preview_live_test.exs test/mailglass_admin/voice_test.exs test/mailglass_admin/preview/scenario_label_test.exs test/mailglass_admin/discovery_test.exs test/mix/tasks/mailglass_admin.preview.capture_test.exs --seed 0

# Retained Preview authoring stories and the feedback ledger (merge-blocking)
cd mailglass_admin && mix test test/mailglass_admin/quick_view_projection_test.exs test/mailglass_admin/feedback_ledger_test.exs --seed 0

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
