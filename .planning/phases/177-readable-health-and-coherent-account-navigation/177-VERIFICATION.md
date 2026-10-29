---
phase: 177-readable-health-and-coherent-account-navigation
verified: 2026-10-28T22:10:00Z
status: passed
score: 4/4 must-haves verified
covered_files:
  - .planning/phases/177-readable-health-and-coherent-account-navigation/177-01-PLAN.md
  - .planning/phases/177-readable-health-and-coherent-account-navigation/177-01-SUMMARY.md
  - .planning/phases/177-readable-health-and-coherent-account-navigation/177-02-PLAN.md
  - .planning/phases/177-readable-health-and-coherent-account-navigation/177-02-SUMMARY.md
  - .planning/phases/177-readable-health-and-coherent-account-navigation/177-03-PLAN.md
  - .planning/phases/177-readable-health-and-coherent-account-navigation/177-03-SUMMARY.md
  - .planning/phases/177-readable-health-and-coherent-account-navigation/177-04-PLAN.md
  - .planning/phases/177-readable-health-and-coherent-account-navigation/177-04-SUMMARY.md
  - .planning/phases/177-readable-health-and-coherent-account-navigation/177-05-PLAN.md
  - .planning/phases/177-readable-health-and-coherent-account-navigation/177-05-SUMMARY.md
  - .planning/phases/177-readable-health-and-coherent-account-navigation/177-06-PLAN.md
  - .planning/phases/177-readable-health-and-coherent-account-navigation/177-06-SUMMARY.md
  - .planning/phases/177-readable-health-and-coherent-account-navigation/177-07-PLAN.md
  - .planning/phases/177-readable-health-and-coherent-account-navigation/177-07-SUMMARY.md
  - .planning/phases/177-readable-health-and-coherent-account-navigation/177-08-PLAN.md
  - .planning/phases/177-readable-health-and-coherent-account-navigation/177-08-SUMMARY.md
  - .planning/phases/177-readable-health-and-coherent-account-navigation/177-09-PLAN.md
  - .planning/phases/177-readable-health-and-coherent-account-navigation/177-09-SUMMARY.md
  - .planning/phases/177-readable-health-and-coherent-account-navigation/177-10-PLAN.md
  - .planning/phases/177-readable-health-and-coherent-account-navigation/177-10-SUMMARY.md
  - .planning/phases/177-readable-health-and-coherent-account-navigation/177-11-PLAN.md
  - .planning/phases/177-readable-health-and-coherent-account-navigation/177-11-SUMMARY.md
  - mailglass_admin/lib/mailglass_admin/controllers/theme_controller.ex
  - mailglass_admin/lib/mailglass_admin/operator/health_overview.ex
  - mailglass_admin/lib/mailglass_admin/operator/shell.ex
  - mailglass_admin/lib/mailglass_admin/operator_live.ex
  - mailglass_admin/lib/mailglass_admin/preview/return_context.ex
  - mailglass_admin/lib/mailglass_admin/preview_live.ex
  - mailglass_admin/lib/mailglass_admin/surface_nav.ex
  - mailglass_admin/test/mailglass_admin/phase177_prohibition_contract_test.exs
  - reference/demo_app/lib/mailglass_demo_web/admin_auth.ex
covered_digest: "v4:sha256:cff6614bb57103b55bee34f1fb987b3b51f46c72bc0b3cb879a967ee106b683f"
behavior_unverified: 0
overrides_applied: 0
advisory:
  - finding: "WR-01: single-option Account control (shell.ex account_variant/3) ignores tenant_state and the selected id"
    category: other
    reason: "Edge case outside the literal D-10 must-have (one option renders static text). Renders the sole Account name as the scope when ?tenant_id= is blank (select_required) or when a deep-linked Account is not the sole listed option. Not a security issue, not a fake picker."
    evidence_status: "code-read of shell.ex:381-391 and operator_live.ex:1177-1180; no failing test"
---

# Phase 177: Readable Health and Coherent Account Navigation Verification Report

**Phase Goal:** Operators can scan actionable Health evidence, understand the scope of the compact Account control and return from Preview to the originating Account through a safe host-supported navigation seam.
**Verified:** 2026-10-28
**Status:** passed
**Re-verification:** No, initial verification

## Goal Achievement

### Observable Truths (ROADMAP success criteria, the contract)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Health is readable at narrow/wide/container widths: specific deep links kept, period/freshness/Refresh form one group, activity subordinate; bounded A vs B comparison supports the composition; population definitions unchanged; no severity inferred from count (OUTUX-06) | VERIFIED | `health_overview.ex` renders `operator-health-layout` > `operator-health-column` (42rem cap, `assets/css/app.css:679-687`, present in the committed `priv/static/app.css`), observation group (`operator-health-observation`), 44px rows, subordinate `operator-health-activity`. `health_population_test.exs` (five literal pre-refactor fingerprints) and `health_overview_test.exs` pass (256 admin tests, 0 failures, seed 0). `177-HEALTH-COMPARISON.md`: 252 measurements, both candidates pass every gate, `Winner: A` decided by a measured tie-breaker count, no owner tie. Contract tests "Health order", "Health severity", "Health deep link", "Health reordering", "Health live region" are mutation-proven. Browser: `phase177-health.spec.js` 8/8 pass on my re-run (geometry at every width, axe light/dark, link-landing, Refresh focus, help tier). |
| 2 | Compact Account control visibly scopes Health, Deliveries and Inbound; with Preview showing account-independent samples there is no fake picker or misleading sample claim (UXF-09) | VERIFIED | `shell.ex` `account_context/1` is the header of the `SurfaceNav` scope group (`data-account-scope`, `role=group`); picker `<details>` only at 2+ options (D-10); Preview sits outside the group with static "Scoped to an Account"/"Not tied to an Account" and no Account name/id. `phase177_account_scope_test.exs`, `shell_test.exs`, contract P1/P3/P5/P6/P7/P9 pass. Browser `phase177-account.spec.js` 8/8 pass on my re-run (visible at 320-1440, keyboard order, no Account identity on Preview, axe, reduced motion). See advisory WR-01 for a single-option edge case. |
| 3 | Operator entering Preview can return to the originating Account through a host-approved local destination; connected tests cover custom mounts, tampered/external destinations, unauthorized Accounts, direct-entry fallback; no authority granted, session/auth whitelists not widened (UXF-10) | VERIFIED | `preview/return_context.ex`: closed surface set compared as strings (no atoms from input), href rebuilt only from host `navigation` + percent-encoded `tenant_id` replaced in place, `local_path?/1` rejects scheme/host/`//`/backslash/control chars, `valid_tenant_id?/1` bounds id. `git diff 03e2cc35 HEAD -- router.ex` shows docs-only change (session maps untouched); contract P8 pins session maps and no Account assigns on `PreviewLive`. `phase177_return_navigation_test.exs` covers custom mounts, tampered params, host-denied Accounts on Health/Inbound/alt mount (arrival re-authorizes), width/scenario/theme persistence, direct entry; `return_context_test.exs` validator table. Demo `phase177_navigation_test.exs` re-run: 9 tests, 0 failures (incl. logged-out return). Browser tracer + privacy canary pass (2/2). |
| 4 | Retained Health/Account/navigation area scenarios use production presentation with normal/empty/stale/unavailable/long-content cases; real routes prove scope and return | VERIFIED | `quick_view_projection_test.exs` (tag `phase177`) renders 5 Health, 4 Account-scope and 2 Preview-chrome scenarios through production `HealthOverview.overview/1`, `Shell.account_context/1`, `SurfaceNav.nav/1`; Northstar story facts asserted equal to the real route's derivation; long Unicode label asserted escaped; `fb-health-crowding`/`fb-account-context` closed `automated` in `reference/persona_spec/quick_view_scenarios.json` with evidence pointers. Scope and return proven on real routes (truths 2-3). |

**Score:** 4/4 truths verified; 0 present-behavior-unverified.

### Required Artifacts / Key Links

| Artifact | Status | Details |
|----------|--------|---------|
| `preview/return_context.ex` | VERIFIED | Substantive (173 lines), wired in `preview_live.ex`, `sidebar.ex`, `shell.ex`, `surface_nav.ex`, `theme_controller.ex` |
| `operator/health_overview.ex` | VERIFIED | Recomposed; rendered by `OperatorLive`; population fingerprints unchanged |
| `operator/shell.ex`, `surface_nav.ex` | VERIFIED | Scope group header + Preview outside group; `tenant_state` threaded from Inbound (`inbound_live.ex`) |
| `controllers/theme_controller.ex` | VERIFIED | Segment-boundary redirect check; theme round trip test passes |
| `reference/demo_app/.../admin_auth.ex`, `router.ex` | VERIFIED | Host-owned `return_to` deny form; demo suite pass |
| `priv/static/app.css` | VERIFIED | Contains the 42rem rule; 177-11 recorded `git diff --exit-code priv/static/` clean after fresh build |
| Operator -> Preview mint -> Preview resolve -> Back link | WIRED | Traced in code and in `phase177_return_navigation_test.exs` round trip and browser tracer |

### Behavioral Spot-Checks (run by the verifier)

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Phase 177 admin ExUnit set (population, health_overview, stories, account_scope, return_navigation, return_context, shell, prohibition contract, router) | `cd mailglass_admin && mix test <9 files> --seed 0` | 256 tests, 0 failures | PASS |
| Demo return seam | `cd reference/demo_app && MIX_ENV=test mix test test/mailglass_demo_web/phase177_navigation_test.exs` | 9 tests, 0 failures; `mix.lock` and tree clean after | PASS |
| Operator browser, Phase 177 specs | `npm --prefix mailglass_admin run test:operator-browser -- phase177-{return-navigation,account,health}.spec.js` | 18 passed | PASS |
| Manifest validators | `node --test scripts/check_phase174_evidence.test.cjs scripts/check_phase175_evidence.test.cjs mailglass_admin/e2e/support/storybook-axe.test.cjs` | pass 40, fail 0 | PASS |
| Orchestrator regression gate (not re-run in full) | `bash scripts/gsd-regression-gate.sh` | admin 1082/0; inbound 480/0 on seeds 0,1,2 | accepted, consistent with 177-11 |

### Probe Execution

No phase-declared probes (`probe-*.sh`). Not applicable.

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|-------------|--------------|-------------|--------|----------|
| OUTUX-06 | 177-02, 04, 05, 08, 09, 11 | Readable Health, grouped period/freshness/Refresh, subordinate activity, specific deep links, truthful populations | SATISFIED | Truth 1; REQUIREMENTS.md marks Complete |
| UXF-09 | 177-03, 06, 07, 09, 11 | Compact Account control scoping Health/Deliveries/Inbound, no Account-scoped Preview suggestion | SATISFIED | Truth 2 (advisory WR-01 noted) |
| UXF-10 | 177-01, 03, 09, 10, 11 | Validated host-approved local return from Preview, direct-entry fallback | SATISFIED | Truth 3 |

All three phase IDs appear in plan frontmatter and in REQUIREMENTS.md; no orphaned requirement maps to Phase 177.

### Anti-Patterns Found

Debt-marker scan (`TBD|FIXME|XXX`) over the phase's changed product files (return_context.ex, shell.ex, health_overview.ex, surface_nav.ex, preview_live.ex, theme_controller.ex, admin_auth.ex): no unreferenced markers. No stubs; no hardcoded empty data flowing to render (Health issue rows are derived from real queries; stories assert equality with the real route).

Code review (177-REVIEW.md): 0 critical, 1 warning, 4 info. Assessment of each follows.

| ID | Assessment |
|----|-----------|
| WR-01 | Confirmed real by code-read: `account_variant([only], _state, selected)` returns `{:static, selected \|\| only.label, :named}` for every `tenant_state`. With exactly one option and `?tenant_id=` blank (`tenant_state` `:select_required`, selected nil) the header names the sole Account in bold while none is selected; with a deep link to an Account not in the activity-derived list it shows that Account with no switch path. It does NOT contradict a written must-have: D-10 and 177-06's truth say "exactly one option renders static text with no details", which is what ships, and the selected-id case is truthful about scope. It is not a fake picker (UXF-09 prohibition) and grants no authority (UXF-10). Classified WARNING (non-blocking advisory), recommended fix in the review (collapse to static only when the single option is the selection or auto-select is pending, else keep picker / prompt tone) plus a connected test for both shapes. Disposition still `open` in 177-REVIEW-DISPOSITION.md. |
| IN-01..IN-04 | Info only: `<p>` in `<span>`, accessible name includes sr-only id, empty `aria-describedby`, whitespace-only id not trimmed. None breaks a must-have; axe runs report 0 violations. |

### Pre-existing failures: attribution verified

- **Core `mix test`, 3 failures (re-run scoped by verifier: 52 tests, 3 failures):**
  - `state_md_contract_test.exs:38` and `:52`: need `gh issue list` / `f733fc22` in `.planning/STATE.md`. `grep -c` returns 0 for both at pre-phase `03e2cc35:.planning/STATE.md` and at HEAD, so they fail without any phase 177 change. Cause is the GSD v2.10 STATE.md format, not phase source.
  - `phase_164_repository_truth_test.exs:261`: `git check-ignore -v` shows `.gsd/.gitignore:1:*` (an untracked local file dated 2026-10-07, before the phase) ignoring `.gsd/extensions/finalize-phase/index.ts`. Local tooling state, not repository content.
  - `git diff --stat 03e2cc35 HEAD -- test/ lib/ scripts/` (core) is empty, so no core source or core test changed in this phase. Attribution confirmed. These are real red tests that stay red; they are recorded in `deferred-items.md` and need a milestone-lifecycle decision (STATE.md contract vs GSD state format; remove or test around the local `.gsd/.gitignore`). They are not Phase 177 gaps.
- **3 axe-baseline "scan deliveries" timeouts** at `operator-replay-open`: 177-04 and 177-07 report reproducing at pre-phase tree/commit; 177-11 re-confirms. Not independently re-run here (long browser run); every Health, Account and Preview axe scan passes, and Phase 177 axe specs pass on my re-run. Accepted as pre-existing, logged in `deferred-items.md`.
- Format drift (10 files) and credo items are documented as byte-identical at `03e2cc35`; none in files this phase authored.

### Human Verification Required

None. Per CLAUDE.md D-52, every machine-observable item is closed by a covering test (`source: automated`). The Health composition choice was settled by a measured tie-breaker, so the `owner-visual-tie` branch did not apply and no owner hand-off exists.

### Gaps Summary

No blocking gaps. All four roadmap success criteria are met by code that exists, is wired and is exercised by passing tests. Non-blocking follow-ups, none required to close the phase: fix WR-01 (and triage IN-01..IN-04); disposition the open rows in `177-REVIEW-DISPOSITION.md`; resolve the three pre-existing core failures and the axe-baseline deliveries timeouts under their own work.

---

_Verified: 2026-10-28_
_Verifier: Claude (gsd-verifier)_
