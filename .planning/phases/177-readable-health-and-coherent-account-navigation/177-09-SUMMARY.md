---
phase: 177-readable-health-and-coherent-account-navigation
plan: "09"
subsystem: testing
tags: [storybook, manifest, health, account-scope, preview-chrome, ExUnit]
status: complete

requires:
  - phase: 177-03
    provides: "Preview return context and the Back link the preview-chrome stories render"
  - phase: 177-06
    provides: "Account control heading the scope group (Shell.account_context/1 inside SurfaceNav.nav/1)"
  - phase: 177-08
    provides: "Winner A Health composition the retained Health stories render"
provides:
  - "QuickViewScenarios.health_overview/1, account_scope/1, preview_chrome/1 builders"
  - "Eleven retained story-render-only manifest scenarios (5 Health, 4 Account scope, 2 Preview chrome)"
  - "Storybook.HealthOverview, Storybook.AccountScope, Storybook.PreviewChrome flat story files"
  - "fb-health-crowding and fb-account-context closed as automated with 177-AUTOMATION.md anchors"
  - "177-AUTOMATION.md first two sections plus reproduce commands"
affects: [177-11]

plan_head_before: cce2a6c29907c23b97c72b334fa087c6e0867767
plan_head_after: d6680f50d4624026d7c1720e59589001e30b5de2

actuals:
  tokens: 52000
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Manifest -> closed-map builder (no String.to_atom) -> production component -> flat story file"
    - "Population parity test: the manifest's issue {testid, count} list and activity totals compared with the real LiveView for the same seed"

key-files:
  created:
    - reference/demo_app/storybook/health_overview.story.exs
    - reference/demo_app/storybook/account_scope.story.exs
    - reference/demo_app/storybook/preview_chrome.story.exs
    - reference/demo_app/assets/e2e/phase177-stories.spec.js
    - .planning/phases/177-readable-health-and-coherent-account-navigation/177-AUTOMATION.md
  modified:
    - reference/persona_spec/quick_view_scenarios.json
    - reference/persona_spec/quick_view_scenarios.ex
    - mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs

key-decisions:
  - "northstar_normal mirrors exactly what the real route derives after seed_persona_cohort!/0: no issue rows, outbound 1, inbound 0, state normal-no-issues. The parity test also compares activity totals so an empty issue list cannot make it vacuous."
  - "Story iframes are resolved by the stable prefix iframe-storybook_<story>-variation-<id> at use time, because Storybook appends a theme suffix to iframe ids after hydration and variation id one is a substring of none."
  - "Stories stay out of axe_selection (20 entries); Health and Account axe runs on the connected routes."

requirements-completed: ["OUTUX-06", "UXF-09", "UXF-10"]

coverage:
  - id: D1
    description: "Health, Account scope and Preview chrome states render through the production components from manifest facts, with long Unicode and HTML-looking text escaped"
    requirement: OUTUX-06
    verification:
      - kind: test
        ref: "mailglass_admin/test/mailglass_admin/quick_view_projection_test.exs (tag phase177, 7 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "northstar_normal issue list and activity totals equal the population the real /ops/mail route derives for the same seed (G5)"
    requirement: OUTUX-06
    verification:
      - kind: test
        ref: "quick_view_projection_test.exs: Phase 177 northstar_normal Health scenario matches the population the real route derives"
        status: pass
    human_judgment: false
  - id: D3
    description: "Preview chrome never renders an Account name or tenant_id outside href attributes; valid_return shows Back to Deliveries, direct_entry shows no Back link"
    requirement: UXF-10
    verification:
      - kind: test
        ref: "quick_view_projection_test.exs: Phase 177 retained Preview chrome scenarios show a plain return and never an Account"
        status: pass
    human_judgment: false
  - id: D4
    description: "fb-health-crowding and fb-account-context closed as automated with scenario ids and existing 177-AUTOMATION.md anchors; axe_selection stays 20"
    requirement: UXF-09
    verification:
      - kind: command
        ref: "python3 manifest check + grep of both anchor headings + node --test over the three manifest validators (40 pass, 0 fail)"
        status: pass
    human_judgment: false

duration: 40min
completed: 2026-10-28
---

# Phase 177 Plan 09: Retained Health, Account Scope and Preview Chrome Stories Summary

**Eleven manifest-driven stories now render the production Health, Account-control and Preview-chrome components, the Northstar Health scenario is proven equal to what the real route derives, and both Phase 177 feedback entries are closed with machine evidence.**

## What was built

- Task 1 (tracer, `c695a417`): `health-overview-northstar-normal` scenario, `QuickViewScenarios.health_overview/1` (closed maps for panel keys, statuses and surfaces; ISO8601 `observed_at`/`checked_at`), `Storybook.HealthOverview`, and three `@tag :phase177` tests (render, real-route parity after `seed_persona_cohort!/0`, story parse).
- Task 2 (`04a331d2`): the other ten scenarios, `account_scope/1` and `preview_chrome/1` builders, `Storybook.AccountScope` (production `Shell.account_context/1` inside `SurfaceNav.nav/1`, scope `:account`) and `Storybook.PreviewChrome` (`SurfaceNav.nav/1`, scope `:preview`), and render tables for all three builders plus a manifest-shape test.
- Task 3 (`d6680f50`): both feedback entries set to `automated` with scenario ids, a rewritten disposition and evidence pointers; `177-AUTOMATION.md` with the two anchored sections and reproduce commands; advisory inventory spec `phase177-stories.spec.js`.

## Verification evidence

- `mix test quick_view_projection_test.exs --only phase177`: 7 phase177 tests pass; whole file `--seed 0`: 20 tests, 0 failures; with `operator/scenario_contract_test.exs`: 24 tests, 0 failures.
- Health gate suites (`health_population + health_overview + quick_view_projection`): 44 tests, 0 failures. Account/return suites (`phase177_account_scope + phase177_return_navigation + return_context + shell`): 130 tests, 0 failures.
- Manifest: 11 Phase 177 scenarios, `axe_selection` length 20, both feedback entries `automated` with non-empty `scenario_ids`, both anchor headings present.
- `node --test` over `check_phase174_evidence`, `check_phase175_evidence` and `storybook-axe` validators: 40 tests, 40 pass, 0 fail (the manifest hash change did not break them).
- `grep -c 'defp health_issues' operator_live.ex` prints 1; `git status -- mailglass_admin/lib` empty, so no production code path was added for stories.
- `reference/demo_app/mix.lock` was clean before and after every demo run (verified, then `git checkout --` as a guard).

## Advisory demo outcome

`npm --prefix reference/demo_app/assets run test:e2e -- phase177-stories.spec.js --grep "Phase 177 retained"`: **passed** (`demo-e2e-exit=0`, 1 test, 645 ms) against the already-running review demo Storybook on `127.0.0.1:4015`, which mounts this working tree and hot-reloads it. It asserts the 11 ids, story paths, theme owners, picker testids, `story-render-only`, `axe_selection` 20 with none of the new ids, and that every variation shows its `data-scenario-id`, `data-state`, theme picker and production root. Two earlier runs failed on my own spec (iframe ids read before hydration, then ids re-rendered with a `-light` suffix); both were fixed in the spec, not the stories.

## Deviations from Plan

None - plan executed as written. Judgment calls inside its latitude:
- The persona cohort derives no Northstar issues, so per the plan the scenario mirrors that (`normal-no-issues`). To keep the parity check meaningful I also compare the outbound and inbound activity totals (1 and 0).
- The Preview chrome scenarios use `cohort: "none"` (the facts carry no Account) and the `direct_entry` paths carry no `tenant_id` at all; `valid_return` carries it only inside link targets.
- `177-AUTOMATION.md` lists commands and test files from plans 177-01..10 and the 177-07 reduced-motion test; plan 177-11 appends the prohibition contract and phase gate.

## Known Stubs

None.

## Threat Flags

None. Dev/test-only story data; no new endpoint, auth path or schema; no package installs or lockfile changes. T-177-19 (escaping) is held by the Fjordline Health and long-label Account render assertions; T-177-20 by closed-map conversions with no `String.to_atom`.

## Self-Check: PASSED

- FOUND: reference/demo_app/storybook/{health_overview,account_scope,preview_chrome}.story.exs
- FOUND: reference/demo_app/assets/e2e/phase177-stories.spec.js
- FOUND: .planning/phases/177-readable-health-and-coherent-account-navigation/177-AUTOMATION.md
- FOUND commits: c695a417 (Task 1), 04a331d2 (Task 2), d6680f50 (Task 3)
