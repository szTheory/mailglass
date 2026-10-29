# Phase 177 automated proof and reproduction

This record closes the Phase 177 machine-observable requirements named below against retained tests and retained story scenarios. It does not claim provider delivery, hosted CI execution, or an owner aesthetic verdict. Deterministic acceptance is automated under METHODOLOGY.md D-52. Plan 177-11 appends the prohibition contract and the phase gate.

## Reproduce and check

Run from the repository root. Every `mix` command needs the toolchain pin `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27`; `.tool-versions` is the CI contract and is not edited.

```sh
# Health: population, markup, copy, retained stories (merge-blocking)
cd mailglass_admin && mix test test/mailglass_admin/health_population_test.exs test/mailglass_admin/operator/health_overview_test.exs test/mailglass_admin/quick_view_projection_test.exs --seed 0

# Account scope and Preview return (merge-blocking)
cd mailglass_admin && mix test test/mailglass_admin/phase177_account_scope_test.exs test/mailglass_admin/phase177_return_navigation_test.exs test/mailglass_admin/preview/return_context_test.exs test/mailglass_admin/operator/shell_test.exs --seed 0

# Reference demo return seam (merge-blocking in the demo project)
cd reference/demo_app && mix test test/mailglass_demo_web/phase177_navigation_test.exs

# Operator browser evidence (Chromium)
cd mailglass_admin && npx playwright test e2e/phase177-health.spec.js e2e/phase177-account.spec.js e2e/phase177-return-navigation.spec.js --grep "Phase 177"

# Retained story inventory (advisory; needs the demo Storybook on :4015)
npm --prefix reference/demo_app/assets run test:e2e -- phase177-stories.spec.js --grep "Phase 177 retained"

# Manifest validators
node --test scripts/check_phase174_evidence.test.cjs scripts/check_phase175_evidence.test.cjs mailglass_admin/e2e/support/storybook-axe.test.cjs
```

Demo runs bump `swoosh` in `reference/demo_app/mix.lock`; confirm `git diff --quiet -- reference/demo_app/mix.lock` before a run and `git checkout -- reference/demo_app/mix.lock` after it.

## Health composition (OUTUX-06)

Health is one left-aligned reading column (plan 177-04) speaking the reviewed copy in every state (plan 177-05). The composition was decided by a bounded A versus B comparison, recorded in [177-HEALTH-COMPARISON.md](177-HEALTH-COMPARISON.md) (252 measurements, both candidates passed every gate, `Winner: A`).

Merge-blocking evidence:

- **Population is frozen.** `mailglass_admin/test/mailglass_admin/health_population_test.exs` holds five literal fingerprints (default, all eight categories, reversed counts, partial refresh, quiet account) captured before the recomposition. Row order is the taxonomy order, never count order.
- **Markup and copy.** `mailglass_admin/test/mailglass_admin/operator/health_overview_test.exs` pins the verdict, stale tag, the closed set of eight notice sentences and the subordinate activity section.
- **Retained stories.** `mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs` (tag `phase177`) renders `health-overview-northstar-normal`, `-helios-empty`, `-stale`, `-unavailable` and `-fjordline-long-unicode` through the production `HealthOverview.overview/1` from manifest facts (stories at `/dev/storybook/health_overview`). The Northstar scenario's issue `{testid, count}` list and activity totals are asserted equal to what the real `/ops/mail?tenant_id=northstar` route derives after `OperatorFixtures.seed_persona_cohort!/0`. The Fjordline scenario carries a long Unicode, RTL, emoji and HTML-looking label and ten-digit counts; the test asserts it renders escaped.
- **Browser gates.** `mailglass_admin/e2e/phase177-health.spec.js` holds eight tests: tracer, "Phase 177 Health gates hold at every width" (320 to 1440, geometry G1 to G4 and G6), "Phase 177 Health axe" (light, dark, armed fault, with a computed-contrast resolution of the one incomplete finding), "Phase 177 every Health issue link lands on its count", "Phase 177 Refresh keeps focus and width", "Phase 177 Health real-width parity", "Phase 177 Health long counts widen only their own cell" and "Phase 177 Health per-issue help is visually subordinate". `mailglass_admin/e2e/phase169-journey.spec.js` keeps "Phase 177 Health column stays capped at landmark widths".

Limits: stories prove rendering only (`proof_boundary: story-render-only`); deep links, focus and population are proven on the real route. The Health scenarios are not in `axe_selection`, which stays at 20 entries; axe for Health runs on the connected route.

## Account scope and Preview return (UXF-09, UXF-10)

The Account control heads the Health, Deliveries and Inbound group it scopes and offers a picker only when there is a real choice (plan 177-06). Preview sits outside that group, names no Account, and returns to the originating Account through a validated closed-set return context (plans 177-01, 177-03, 177-10).

Merge-blocking evidence:

- **Return context and routes.** `mailglass_admin/test/mailglass_admin/preview/return_context_test.exs` (closed-set parsing, tampered and foreign input) and `mailglass_admin/test/mailglass_admin/phase177_return_navigation_test.exs` (Health to Preview to Back round trip, width patch, scenario and broken links, nav items, theme round trip, custom mounts, host-denied Accounts).
- **Scope group.** `mailglass_admin/test/mailglass_admin/phase177_account_scope_test.exs` pins the group order, the none, one and many variants, the long escaped label, the scope description and the Preview caption; `mailglass_admin/test/mailglass_admin/operator/shell_test.exs` keeps the switch-path contracts.
- **Reference demo.** `reference/demo_app/test/mailglass_demo_web/phase177_navigation_test.exs` proves the host-owned `return_to` deny form, logged in and logged out.
- **Retained stories.** `quick_view_projection_test.exs` (tag `phase177`) renders `account-scope-none`, `-one`, `-many` and `-long-label` (production `Shell.account_context/1` inside `SurfaceNav.nav/1`, scope `:account`; stories at `/dev/storybook/account_scope`) and `preview-chrome-valid-return` and `-direct-entry` (production `SurfaceNav.nav/1`, scope `:preview`; stories at `/dev/storybook/preview_chrome`). The Preview scenarios assert no Account name or `tenant_id` text outside href attributes; the long-label scenario asserts the HTML-looking label renders escaped.

Browser evidence (Chromium):

- `mailglass_admin/e2e/phase177-account.spec.js`: "Phase 177 tracer: Account header heads the scoped group", "Phase 177 Account control stays visible at every width", "Phase 177 Account menu fits the band below md", "Phase 177 scope group keyboard order", "Phase 177 Preview shows no Account identity", "Phase 177 Account switch shows a polite status", "Phase 177 scope group axe" and "Phase 177 scope chrome honors reduced motion".
- `mailglass_admin/e2e/phase177-return-navigation.spec.js`: "Phase 177 tracer: Preview returns to the originating Account".
- `reference/demo_app/assets/e2e/phase177-return.spec.js`: "Phase 177 demo returns Preview to the originating Account" and "Phase 177 demo logged-out Preview return lands on the originating Account after login".
- Account selectors in every operator spec resolve through `mailglass_admin/e2e/support/account.cjs`, because the control renders in the sidebar and the mobile band.

Limits: stories prove rendering only; scope and return are proven on the real routes and in the reference demo.

## Story inventory (plan 177-09)

`reference/demo_app/assets/e2e/phase177-stories.spec.js`, test "Phase 177 retained Health and Account stories inventory and composition", asserts the exact eleven scenario ids, story paths, theme owners, picker testids and `story-render-only` boundary, that `axe_selection` still has 20 entries with none of the new ids, and that every variation renders its production root. It is advisory by project convention (the demo Storybook is not a merge-blocking lane); the merge-blocking proof is the ExUnit render tables above. Recorded outcome of the last local run: passed (1 test, 11 variations, against the demo Storybook on `127.0.0.1:4015`, `reference/demo_app/mix.lock` unchanged before and after).

## Feedback and ownership

`fb-health-crowding` and `fb-account-context` are `automated` in `reference/persona_spec/quick_view_scenarios.json` with scenario ids and the anchors of this record (`#health-composition-outux-06` and `#account-scope-and-preview-return-uxf-09-uxf-10`). Other feedback rows were left unchanged.
