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

## Prohibition contract (plan 177-11)

`mailglass_admin/test/mailglass_admin/phase177_prohibition_contract_test.exs` (tag `phase177`, 60 tests, `--warnings-as-errors`) is the machine-checked form of every Phase 177 must-NOT. It runs inside `mix verify.support_contract.admin`, which executes the whole admin suite, so it is merge-blocking. Each rule is a detector that returns a violation list (`[]` is clean), with a teeth test (a violating fixture returns a non-empty list, a clean fixture returns `[]`) and a clean-state test against real rendered output (connected `live/2` for routes, `render_component/2` for components, file reads for docs).

| Rule | What it forbids | Clean-state evidence |
|---|---|---|
| P1 | An Account control, `<details>`, `<select>` or disabled Account control in Preview chrome | direct entry, valid return, tampered return |
| P2 | The return id anywhere but a href value (canary `zz-canary-7f3`) | three surfaces and a width patch; real-browser backstop below |
| P3 | `sample`, `demo`, `fake`, `live` (whole words) in Preview chrome; an Account word, `tenant_id` or configured Account label outside the three allow-listed static strings | direct entry, valid return, tampered return |
| P4 | A top-level `tenant_id` key on the operator to Preview href | Health, Deliveries, Inbound, no Account, alt mount |
| P5 | Preview inside `[data-account-scope]`; group links other than the rendered scoped items | operator, Preview, and the shared nav without Inbound |
| P6 | Any Preview subtitle other than the exact D-12 sentence | four Preview states |
| P7 | A `<details>`, chevron, option or switcher with fewer than two Account options | 0 and 1 option, Preview |
| P8 | A widened or `return_*`-bearing Preview or Operator session map; Account assigns on `PreviewLive` | both session maps, direct and returned Preview |
| P9 | Inbound named in the scope description when no Inbound link renders | shared shell with Inbound unavailable |
| Health order | Row order or row classes that depend on count | `seed_phase177_health_all!` ascending and reversed |
| Health severity | A severity word or severity colour on a row, derived from count | both seeds and a 9,999,999 count |
| Health deep link | An issue row without a non-empty link | all eight categories, default seed, both surfaces |
| Health reordering | `order-*` (any variant) or reversed flex inside the Health region | real region and every component state |
| Health live region | `role=status`, `role=alert` or `aria-live` on a persistent `operator-health-*` notice | stale and unavailable for all four panels, real stale route |
| Back link | A label outside the three closed labels, or any Account name or id in its text or attributes | three surfaces including a canary id |
| Docs | A sentence claiming the Account switch (a `push_patch`) re-runs host authorization | README, CHANGELOG, `docs/*.md`, `lib` moduledocs and docs, repository guides |

The P3 allow-list is exactly `It doesn't read Deliveries or Inbound messages from any Account.`, `Scoped to an Account` and `Not tied to an Account`, each removed only as a complete phrase; adding one is a deliberate edit of `@provenance_allow_list`.

### Mutation proofs (every rule proven red, then reverted)

Each mutation changed owning source, was run against the contract file at `--seed 0`, produced the red tests listed, and was reverted with a path-specific `git checkout`. `git status --porcelain -- mailglass_admin/lib mailglass_admin/docs mailglass_admin/CHANGELOG.md` was empty after every one.

| Rule | Temporary mutation | Red tests |
|---|---|---|
| P1 | `preview_live.ex`: sidebar `SurfaceNav` given `scope={:account}` and a `Shell.account_context` header | P1 direct entry, P1 valid return (`"Account control \"operator-account-context\" rendered on Preview" ... "<details> rendered in Preview chrome"`) |
| P2 | `preview_live.ex`: `@return_context.tenant_id` rendered as text in the page header | P2 canary test and width patch (`zz-canary-7f3 appears 1 time(s) outside href attribute values`), P3 |
| P3 | `preview_live.ex`: `Previews use sample data.` appended to the subtitle | P3 direct and tampered (`provenance claim "\b(sample|demo|fake)\b"`), P6 |
| P3 | `preview_live.ex`: `for this Account` appended to the subtitle | P3 direct and tampered (`Account wording ... outside the allow-list`), P6; proves the allow-list is exact |
| P4 | `return_context.ex`: `{"tenant_id", selected_tenant_id}` added to the minted Preview href | P4 (`/ops/mail?tenant_id=tenant-b`) |
| P5 | `surface_nav.ex`: Preview added to the scoped item list | P5 operator and Preview, P5 shared nav, P4, P9 |
| P6 | `preview_live.ex`: `Renders` changed to `Shows` | P6 (`/dev/mail/.../welcome_default?width=768`) |
| P7 | `shell.ex`: `length(options) >= 2` changed to `>= 1` | P7 fewer than two options (`<details> rendered without a real choice`) |
| P8 | `router.ex`: `"return_surface"` added to the Preview session map | P8 session maps (`session carries return_surface`) |
| P8 | `preview_live.ex`: `assign(:tenant_id, "acme")` in `mount/3` | P8 assigns (`PreviewLive assigns :tenant_id`) |
| P9 | `surface_nav.ex`: description hard-coded to name Inbound | P9 (`sidebar: description mentions Inbound but no Inbound link is rendered`) |
| Health order | `operator_live.ex`: `Enum.sort_by(& &1.count, :desc)` on `health_issues` | Health order (`issue order depends on count`) |
| Health severity | `health_overview.ex`: `" critical"` appended to the label when count > 5 | Health severity |
| Health deep link | `health_overview.ex`: the Inbound issue link set to `:if={false}` | Health deep link, both tests (`issue row operator-health-inbound-failed has no deep link`) |
| Health reordering | `health_overview.ex`: `order-2` added to the observation group | Health reordering (`visual reordering utility "order-2" in the Health region`) |
| Health live region | `health_overview.ex`: `role="status"` added to the notice | both persistent-notice tests |
| Back link | `preview_live.ex`: tenant id appended to `return_label` (both navs) | Back link, P2 (two), P3 |
| Docs | `docs/operator-trust.md`: a sentence claiming the switch re-runs host authorization | docs (`docs/operator-trust.md: ... re-runs host authorization on every patch.`) |

After the last revert the file ran green: 60 tests, 0 failures.

## Health composition result

[177-HEALTH-COMPARISON.md](177-HEALTH-COMPARISON.md) records 252 measurements (2 candidates, 9 scenarios, 7 viewports, 2 themes). Both candidates passed every gate, and the recorded outcome is `Winner: A`, which is what shipped (a single left-aligned 42rem reading column).

## Reduced motion

Plan 177-07 test "Phase 177 scope chrome honors reduced motion" in `mailglass_admin/e2e/phase177-account.spec.js` measures computed `transition-duration` and `animation-duration`. Elements measured: the Account switcher summary, the chevron closed and open, all 33 elements inside the visible scope group (closed and open), `#operator-health-refresh`, the Preview return link and the 11 elements of the Preview scope group. Under `reducedMotion: "reduce"` every measured element computes `1e-05s` for both properties (the global `@media (prefers-reduced-motion: reduce)` block in `assets/css/app.css` forces 0.01ms), all at most 0.001s. The no-preference teeth value is the Account chevron computing `transition-duration > 0`. The test passed in this gate's full coupled browser run. No `motion-safe:` gate had to be added, and no CSS was rebuilt.

## Health per-issue help tier

Owner todo `2026-10-25-health-overview-layout-owner-feedback.md` item 3. Decision (plan 177-04): each issue row keeps exactly one `field_help` with the default trigger, placed after the label link, so the help is the tertiary element of the row; `components.ex` is untouched. Test "Phase 177 Health per-issue help is visually subordinate" in `mailglass_admin/e2e/phase177-health.spec.js` (plan 177-08) asserts one trigger per row, a glyph at most 16px high and narrower than the label link, a help colour different from the link colour, no glyph underline while the link keeps its underline, and glyph contrast of at least 3:1 (WCAG 1.4.11). Measured in this gate on all eight rows at 1280px: glyph 16 by 16px; light help colour `rgb(92, 107, 122)` against link `rgb(13, 27, 42)`, contrast 5.26:1; dark help colour `rgb(184, 202, 212)` against link `rgb(234, 246, 251)`, contrast 10.30:1. The test passed in the full run.

## Lane placement

`operator_browser_gate` (`.github/workflows/ci.yml:954`) is not in the `ci_green` "CI Green" aggregate's `needs` (`ci.yml:1428`), so every browser-only property below is advisory: it runs on every code PR but cannot block a merge. These properties need real layout, focus or media emulation that ExUnit and Floki cannot observe, and the project keeps the browser lane advisory by convention. Each row names the browser proof and the merge-blocking ExUnit guard for the same behavior, or "none (browser-only)".

| Property | Browser proof (advisory) | Merge-blocking ExUnit guard |
|---|---|---|
| Health G1 overflow | `phase177-health.spec.js` "Phase 177 Health gates hold at every width" | none (browser-only) |
| Health G2 DOM and visual order | same test | `health_overview_test.exs` DOM order; `phase177_prohibition_contract_test.exs` "Health has no visual reordering" |
| Health G3 Refresh cohesion | same test; "Phase 177 Refresh keeps focus and width" | `health_overview_test.exs` shared `role=group` ancestor; the 16px and 8px gaps are browser-only |
| Health G4 target size | same test | `health_overview_test.exs` `min-h-11` class assertions |
| Health G6 text cues | same test | `health_overview_test.exs` copy states |
| Health G7 axe | "Phase 177 Health axe" | none in ExUnit (browser-only, including the incomplete-finding triage) |
| Account visibility at 320, 375, 768, 1280, 1440 | `phase177-account.spec.js` "Phase 177 Account control stays visible at every width" | `phase177_account_scope_test.exs` and `shell_test.exs` prove the group renders in both nav copies; in-viewport placement is browser-only |
| Keyboard order | "Phase 177 scope group keyboard order" | `phase177_account_scope_test.exs` nav order and `phase177_return_navigation_test.exs` Back link as the first nav child prove DOM order; focus traversal and the visible outline are browser-only |
| Reduced motion | "Phase 177 scope chrome honors reduced motion" | none (browser-only); the global reduce block in `assets/css/app.css` is guarded only by this test |
| Deep-link landing | "Phase 177 every Health issue link lands on its count" | `health_population_test.exs` pins every issue row's `{testid, count, href}`; that the destination shows the matching count is browser-only |

## Phase gate run (plan 177-11)

Run on 2026-10-28 at base commit `77cc7d71` (the contract test file already committed). Task 3 added only the Phase 177 return-navigation spec change below, the records and the todo, so no product source differs from the measured tree. No stale server was listening on port 4101 before either browser run.

| Gate | Command | Result |
|---|---|---|
| Admin suite | `cd mailglass_admin && mix verify.support_contract.admin --seed 0` | exit 0; 1082 tests, 0 failures, 1 excluded |
| Core suite | `mix test --seed 0` (repository root) | exit 2; 23 properties, 2239 tests, 3 failures, 27 excluded, 7 skipped. All 3 failures are pre-existing and unrelated; see Pre-existing below |
| Inbound suite | `cd mailglass_inbound && mix test --seed 0` | exit 0; 3 properties, 480 tests, 0 failures |
| Conformance | `bash scripts/check-conformance.sh` | `OK: design-system conformance clean.` |
| Bundle equals a fresh build | `mix mailglass_admin.assets.build && git diff --exit-code priv/static/` | exit 0 (no drift) |
| Format | `mix format --check-formatted` | fails on 10 files; see Pre-existing below. Every file this phase touched is clean |
| Credo | `mix credo --strict` | 1 warning, 3 refactoring opportunities, 2 readability; none in a file this plan authored; see Pre-existing below |
| Contract file alone | `mix test test/mailglass_admin/phase177_prohibition_contract_test.exs --trace --seed 0 --warnings-as-errors` | 60 tests, 0 failures; `credo --strict` on the file: no issues |
| Reference demo suite | `cd reference/demo_app && MIX_ENV=test mix test --seed 0` (lock clean before, restored after) | 37 tests, 0 failures; `phase177_navigation_test.exs` 9 tests, 0 failures |
| Operator browser, 13 specs in one wrapped run | `npm --prefix mailglass_admin run test:operator-browser -- phase177-return-navigation.spec.js phase177-account.spec.js phase177-health.spec.js phase169-journey.spec.js health-tooltips.spec.js operator.spec.js structural.spec.js flows.spec.js inbound-layout.spec.js phase170-journey.spec.js phase175-inbound.spec.js phase168-plan03-acceptance.spec.js axe-baseline.spec.js` | 242 passed, 3 failed (pre-existing, below), 1 skipped (guarded, below); `priv/static/app.css` unchanged |

The browser run was done twice. The first run (241 passed, same 3 failed, same 1 skipped) passed the Phase 177 specs, but running `phase177-return-navigation.spec.js` alone then failed intermittently (about 1 run in 3): "Phase 177 tracer: Preview returns to the originating Account" clicked the Preview link before the operator LiveView had connected. The synthetic test endpoint (`MailglassAdmin.TestAdopter.Endpoint`) has no `Plug.Parsers`, so the disconnected render sees no query params and mints a bare `/dev/mail` href (a debug render showed `selected_tenant_id` nil and `tenant_state` `:none` in the disconnected render, and the minted href after connect). The tracer now waits for `[data-phx-main].phx-connected` before reading the link (title unchanged), and 8 consecutive standalone runs passed. The second full run is the one in the table, after that fix and the new canary test.

### Pre-existing (confirmed outside this phase, not masking anything)

- **3 failed:** `axe-baseline.spec.js` "axe WCAG 2.2 AA baseline producer (RATCHET-03) > scan deliveries / light", "/ dark", "/ system" time out at `getByTestId("operator-replay-open").click()` while opening the Full detail overlay. Plan 177-07 reproduced them at the pre-phase commit `03e2cc35` in a scratch worktree; they are logged in `deferred-items.md`. Every Health, Account and Preview scan in the same spec passed.
- **1 skipped:** `structural.spec.js` "header-anchored overlay transform-origin is top-edge IF such an overlay exists (guarded, D-07)" calls `test.skip(true, ...)` by design when no header-anchored overlay exists (Phase 115).
- **Format:** the ten files `lib/mailglass_admin/auth.ex`, `lib/mailglass_admin/operator/replay_modal.ex`, `lib/mailglass_admin/operator/timeline.ex` and seven test files (`brand_test.exs`, `bucket_a_coverage_test.exs`, `inbound/replay_modal_test.exs`, `mix_config_test.exs`, `persona_drift_guard_test.exs`, `preview/chromium_test.exs`, `stability_contract_test.exs`) all show an empty `git diff 03e2cc35 HEAD`, so none changed in this phase.
- **Credo:** `test/support/fixtures/mailables.ex:84`, `test/support/admin_bootstrap.ex:31`, `test/mailglass_admin/token_parity_test.exs:252`, `lib/mailglass_admin/operator_live.ex:1666` (`assign_delivery_state`, outside every Phase 177 hunk), `test/support/endpoint_case.ex:147` (`reset/2`, complexity 20 against a maximum of 17; the one Phase 177 clause adds 1, so it was 19 before) and `test/mailglass_admin/operator_live_test.exs:1945` (outside every Phase 177 hunk).
- **Core suite, 3 failures:** `test/mailglass/state_md_contract_test.exs:38` ("positively points at live gh state for anything currently open") and `:52` ("the permanent, closed-forever facts are positively present") read the live `.planning/STATE.md`, which the GSD tooling rewrote for the v2.10 milestone; `git show 03e2cc35:.planning/STATE.md` already lacks both `gh issue list` and `f733fc22`, so they failed before this phase began. `test/scripts/phase_164_repository_truth_test.exs:261` ("git runtime rules do not conceal the retired finalize-phase extension paths") fails because the untracked local file `.gsd/.gitignore` (dated 2026-10-07, content `*`) makes git ignore `.gsd/extensions/finalize-phase/index.ts`; it is local GSD tooling state, not repository content. None involves a file this phase changed. They were not fixed here because the STATE.md contract and the GSD state format conflict is a milestone-lifecycle decision, and `STATE.md` is never hand-edited.
- `mix compile --no-optional-deps` was not run on the shared local `_build` (it pollutes the build); the CI lane owns it.

## Demo outcomes

- **Blocking demo ExUnit (D-07):** `reference/demo_app/test/mailglass_demo_web/phase177_navigation_test.exs`, 9 tests, 0 failures, including "Phase 177 logged-out Fjordline Deliveries return lands on Fjordline after login", "Phase 177 logged-out Inbound return lands on Fjordline Inbound", the hostile and oversized arrival fallbacks and the referrer policy test. The full demo suite is 37 tests, 0 failures.
- **Advisory demo browser:** `reference/demo_app/assets/e2e/phase177-return.spec.js` passed (2 tests) when plan 177-10 ran it (`demo-e2e-exit` 0). It was not re-run in this gate: it needs the demo server and the lane is advisory. The two `demo.spec.js` failures plan 177-10 observed need `DEMO_EVIDENCE_RESET_TOKEN` and are environmental.
- **P2 canary backstop:** plan 177-10 did not add a canary assertion to the demo spec, so the real-browser confirmation of P2 lives in the operator browser lane instead: `phase177-return-navigation.spec.js` "Phase 177 privacy canary: Preview shows the return id only inside hrefs" loads `/dev/mail?return_surface=overview&return_tenant_id=zz-canary-7f3` at 320 and 1280, asserts the Back link href carries the canary (non-vacuous), and asserts the canary is absent from the serialized DOM once href values are removed, from `body.innerText` and from the title. It passed in the gate run.
