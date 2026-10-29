---
phase: 177-readable-health-and-coherent-account-navigation
plan: "06"
subsystem: ui
tags: [phoenix-liveview, navigation, account-scope, heex, css-bundle, playwright]
status: complete

requires:
  - phase: 177-01
    provides: SurfaceNav Back link (preview-return-link) and Shell-minted Preview href
  - phase: 177-03
    provides: PreviewLive threaded nav (preview_surface_paths/1, return_context)
  - phase: 177-05
    provides: Health copy (no overlap; ordering only)
provides:
  - "SurfaceNav scope group: Account header slot over Health/Deliveries/Inbound, Preview outside below a divider with a caption"
  - "Shell.account_context/1 variants (0/1 static, 2+ switcher), layout-suffixed ids, tenant_state threading"
  - "Preview static 'Scoped to an Account' header (no Account identity)"
  - "One-row topbar CSS and rebuilt priv/static/app.css"
  - "e2e/support/account.cjs visible-only locator helper and phase177-account.spec.js"
affects: [177-07, 177-09, 177-11]

plan_head_before: 250201474753b07366547ec4bcc0a5872042b572
plan_head_after: 45243ac61b77cf5a160ee17c86aa51a02709a6ac

actuals:
  tokens: 11900
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Scope group = role=group labelled by its header; description span derived from rendered items"
    - "Duplicate sidebar+mobile renders: layout-suffixed ids, base data-testids kept with data-layout, e2e filters to the visible copy"
    - "Menu anchor switches by breakpoint: header 'relative md:static' + details 'md:relative'"

key-files:
  created:
    - mailglass_admin/test/mailglass_admin/phase177_account_scope_test.exs
    - mailglass_admin/e2e/support/account.cjs
    - mailglass_admin/e2e/phase177-account.spec.js
  modified:
    - mailglass_admin/lib/mailglass_admin/surface_nav.ex
    - mailglass_admin/lib/mailglass_admin/operator/shell.ex
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/lib/mailglass_admin/inbound_live.ex
    - mailglass_admin/assets/css/app.css
    - mailglass_admin/priv/static/app.css
    - mailglass_admin/test/mailglass_admin/operator/shell_test.exs

key-decisions:
  - "SurfaceNav scope attr defaults to :preview, so a call site that forgets the header shows no Account identity"
  - "Added data-testid surface-nav-scope-items to the scoped-links region so tests (and 177-11 P5) can select exactly the group's links without matching the menu's option anchors"
  - "Account menu is anchored to the group header below md (spans the group) and to the details at md+ (aligns with the summary); the plan's 'band width' is read as the group width"
  - "Single-option header shows the selected label, else that option's label, as static text"

requirements-completed: ["UXF-09"]

coverage:
  - id: D1
    description: "Account control heads a role=group of Health, Deliveries, Inbound; Preview sits outside it with 'Not tied to an Account'; topbar holds only the theme picker"
    requirement: UXF-09
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/phase177_account_scope_test.exs#Phase 177 Account scope group on operator pages (5 tests)"
        status: pass
      - kind: e2e
        ref: "playwright: e2e/phase177-account.spec.js#Phase 177 tracer: Account header heads the scoped group"
        status: pass
    human_judgment: false
  - id: D2
    description: "Header variants: 0/1 options static, 2+ switcher (incl. none selected -> Choose an Account), Inbound :unavailable never 'No Accounts yet', long/Unicode/HTML label escaped and wrapped, no duplicate ids, derived description omits absent Inbound, neutral and never disabled"
    requirement: UXF-09
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/phase177_account_scope_test.exs#Phase 177 Account header variants (11 tests)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Preview shows only the static 'Scoped to an Account' label with no operator-account* element, no picker, no Account text; Back link stays first above the group"
    requirement: UXF-09
    verification:
      - kind: integration
        ref: "phase177_account_scope_test.exs#Phase 177 Preview scope chrome (2 tests)"
        status: pass
      - kind: e2e
        ref: "phase177-account.spec.js#Phase 177 Account control stays visible at every width (Preview at 320 assertions)"
        status: pass
    human_judgment: false
  - id: D4
    description: "At 320/375/768/1280/1440 the Account header is above the fold, logo and Appearance picker share one row, all scoped and Preview links are >=44px, the menu fits (spans the group below md, aligns with the summary at md+, options uncovered)"
    requirement: UXF-09
    verification:
      - kind: e2e
        ref: "phase177-account.spec.js#Phase 177 Account control stays visible at every width; #Phase 177 Account menu fits the band below md"
        status: pass
    human_judgment: false
---

# Phase 177 Plan 06: Account Scope Group Summary

**The Account control now heads the Health/Deliveries/Inbound group it scopes (Preview sits outside it with a caption), offers a picker only when there is a real choice, and the topbar is one row at every width.**

## Accomplishments

- `SurfaceNav.nav/1` keeps one `nav` landmark: optional Back link, then `[data-account-scope][role=group]` (header slot, scoped items, derived sr-only description), then a divider block with Preview and "Not tied to an Account". New `scope` attr (`:account | :preview`, default `:preview`) and `scope_header` slot.
- `Shell.shell/1` moves `account_context/1` out of the topbar `:actions` slot into the header slot of both nav copies and gains a `tenant_state` attr; `operator_live.ex` and `inbound_live.ex` pass `@tenant_state`.
- `account_context/1` variants (D-10): 2+ options render the existing `<details>` switcher (summary label "Change Account: <name>" or "Choose an Account"), exactly 1 option or Inbound `:unavailable` render static text, 0 render "No Accounts yet". All ids are layout-suffixed, the menu no longer right-anchors, `mg-scope-identity` is gone so names wrap.
- Preview renders the static "Scoped to an Account" header and no Account element (D-11).
- CSS: the second-topbar-row rules for the Account control and `.mg-scope-identity` are deleted; topbar grid and the three Appearance-fieldset rules stay. Bundle rebuilt and committed.

## Commands and results

- Task 1 verify: `phase177_account_scope_test + shell_test + phase177_return_navigation_test + preview_live_test + bucket_a_coverage_test --seed 0` -> 114 tests, 0 failures. Browser tracer pair (`phase177-account.spec.js`, `phase177-return-navigation.spec.js`, `--grep "Phase 177 tracer"`) -> 2 passed; bundle unchanged.
- Task 2 verify: `phase177_account_scope_test + shell_test + voice_test` -> 64 tests, 0 failures (1 excluded); `--only phase177 --trace` -> 17 "Phase 177 Account" lines (>= 10). Mutation check (picker threshold `>= 1`, un-suffixed switch-status id) failed 4 variant tests; restored.
- Task 3 verify: TokenParity + Assets + account-scope tests -> 31 tests, 0 failures. Browser: `phase177-account.spec.js` tracer + 2 new tests -> 3 passed (3.3s); bundle committed equals a fresh build (two consecutive builds are byte-identical).
- Plan gate: shell + account_scope + preview_live + voice + operator_live + inbound_live + token_parity + assets + return_navigation, `--seed 0` -> **447 tests, 0 failures, 1 excluded**. `mix format --check-formatted` on every touched file clean (no bare `mix format`); `bash scripts/check-conformance.sh` -> "OK: design-system conformance clean."; `mix credo --strict` -> 6 findings, all pre-existing in files/lines this plan did not author (mailables.ex, admin_bootstrap.ex, token_parity_test.exs:252, operator_live.ex:1666, endpoint_case.ex, operator_live_test.exs:1945).
- Acceptance greps: `data-account-scope` 1, `Not tied to an Account` 1, `Scoped to an Account` 1, `Choose Account` in shell.ex 1 (body tenant_selector label), `sm:right-0` 0, `operator-account` in app.css 0 (was 6), `mg-scope-identity` 0 (was 1), `fieldset[aria-label="Appearance"]` 3 (unchanged).

### Bundle-rebuild outcome

Fresh build on the edited tree differed from the committed bundle only by the intended rule changes: removed the five Account-in-topbar rules, `.mg-scope-identity`, `.sm:left-auto`, `.sm:right-0`; added `[data-account-scope] .mg-scope-menu{width:100%}` and `md:relative`/`md:static`. No daisyUI theme block moved; TokenParity and Assets pass. The committed `app.css` equals a fresh build (`git diff --exit-code priv/static/` clean after the Task 3 commit).

## Deviations from Plan

**1. [Rule 1 - Bug in plan's measure] Topbar row check compares vertical centers, not tops**
- **Found during:** Task 3 browser run (received 16px at 320).
- **Issue:** the plan's "bounding-box tops differ by less than 8px" cannot hold: the 24px logo and 46px Appearance picker are center-aligned, so tops differ by half the height gap by design while sharing one row.
- **Fix:** the spec compares vertical centers (< 8px). Same intent (one row), correct measure.
- **Files modified:** mailglass_admin/e2e/phase177-account.spec.js. **Commit:** 45243ac6.

**2. [Rule 1 - Bug] Menu left edge did not align with the summary at md+**
- **Found during:** Task 3 browser run (8px off at 768).
- **Issue:** anchoring the menu to the header (needed so it spans the group below md) put its left edge at the group border, 8px left of the summary.
- **Fix:** header is `relative md:static`, details gets `md:relative`, so below md the menu spans the group and at md+ it lines up with the summary. "Full band width" in the plan is read as the group width (the band content width); the menu equals the group within 2px and stays inside the viewport at 320 and 375.
- **Files modified:** surface_nav.ex, operator/shell.ex. **Commit:** 45243ac6.

**3. [Rule 3 - Blocking] Duplicate `import` of LiveViewTest in the new test**
- A narrowed `import Phoenix.LiveViewTest, only: [...]` replaced the `LiveViewCase` import and hid `live/2`; removed. No effect on the product.

**4. [Process] Task 2 variants were implemented before the new tests ran**
- Task 2's tests were written after the implementation in the same sitting, so there was no red run. Teeth were proven by mutation instead (above): 4 of the variant tests failed under the two mutations.

**5. [Additive] `data-testid="surface-nav-scope-items"` on the scoped-links region**
- Not in the plan. Needed so tests select the group's links without matching the menu's `operator-account-option` anchors. Available to plan 177-11 (P5).

**Total deviations:** 2 auto-fixed bugs, 1 blocker in own test, 2 notes. **Impact:** none on scope.

## Specs left for plan 177-07 (knowingly ambiguous or stale)

Not run in this plan. These locate `operator-account-*` by bare testid and will hit strict-mode duplicates (sidebar + mobile copies) or the removed topbar placement; plan 177-07 migrates them to `e2e/support/account.cjs`:

- `mailglass_admin/e2e/flows.spec.js` (switcher/option clicks at ~845, ~926, ~1483-1519, ~1949; `operator-account-context` at ~957 inside a topbar-controls zoom list, ~2010, ~2080; switch-status id regex `^operator-account-switch-status-\d+$` at ~1498 must accept the layout segment)
- `mailglass_admin/e2e/structural.spec.js` (~2546-2573)
- `mailglass_admin/e2e/inbound-layout.spec.js` (~195)
- `mailglass_admin/e2e/phase170-journey.spec.js` (~391)
- `mailglass_admin/e2e/phase175-inbound.spec.js` (~297)

## Known Stubs

None.

## Threat Flags

None. T-177-13 (Preview Account spoofing) and T-177-14 (escaped labels) are mitigated and tested here; T-177-15 is accepted as planned (switch path unchanged).

## Notes for later plans

- `tenant_switch_path/2`, `@switch_query_keys`, `surface_paths/4` and `tenant_selector/1` are unchanged; the body "Choose Account" option label is intact (voice_test, operator_live_test, inbound_live_test all green).
- The Account control is a neutral element; no accent class was added and none is disabled.

## Self-Check: PASSED

- Created files exist: phase177_account_scope_test.exs, account.cjs, phase177-account.spec.js (FOUND).
- Commits reachable from HEAD: 489c1365, 0444279e, 45243ac6 (FOUND).
- `git rev-list --count 25020147..HEAD` = 3 before this SUMMARY commit.
