---
phase: 177-readable-health-and-coherent-account-navigation
plan: "01"
subsystem: ui
tags: [phoenix-liveview, navigation, open-redirect, closed-set-validation, playwright]
status: complete

requires:
  - phase: 176
    provides: operator Shell/SurfaceNav chrome and the phase176 prohibition-contract test conventions
provides:
  - "MailglassAdmin.Preview.ReturnContext: closed-set return-context validator, minting and href builder"
  - "Operator.Shell mints return_surface/return_tenant_id on the Preview link when an Account is selected"
  - "SurfaceNav Back link (preview-return-link) first in the nav landmark"
  - "PreviewLive :return_context assign; index redirect keeps the context"
  - "ThemeController segment-boundary return_to sanitizer"
affects: [177-03, 177-06, 177-11]

plan_head_before: 03e2cc3561818ec3bc6a0cf6a4798ac03a603249
plan_head_after: 9769e8f021df938fd77f0b0b9fca632f139347d3

actuals:
  tokens: 8845
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Back destination rebuilt from host navigation plus an opaque id; never parsed from a request URL"
    - "Direct-entry byte identity: empty query_pairs returns the original string unchanged"

key-files:
  created:
    - mailglass_admin/lib/mailglass_admin/preview/return_context.ex
    - mailglass_admin/test/mailglass_admin/preview/return_context_test.exs
    - mailglass_admin/test/mailglass_admin/phase177_return_navigation_test.exs
    - mailglass_admin/e2e/phase177-return-navigation.spec.js
  modified:
    - mailglass_admin/lib/mailglass_admin/operator/shell.ex
    - mailglass_admin/lib/mailglass_admin/surface_nav.ex
    - mailglass_admin/lib/mailglass_admin/preview_live.ex
    - mailglass_admin/lib/mailglass_admin/controllers/theme_controller.ex
    - mailglass_admin/test/mailglass_admin/router_test.exs
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs

key-decisions:
  - "Param names stay return_surface / return_tenant_id (no clash with any existing Preview/Operator param)"
  - "A3: Shell mints only when preview_path is a local absolute path and the id is valid; a cross-origin preview_path is rendered unchanged"
  - "A2: the theme sanitizer also rejects ., .. and %2e segments, backslashes and // in the path"
  - "Back label comes from ReturnContext.back_label/1 (closed map), so request text can never reach it"
  - "Invalid ids are not minted at all on the operator side (stronger than the plan minimum; Preview would drop them anyway)"

patterns-established:
  - "ReturnContext is total: binary-guarded clauses plus fallbacks; surface compared as a string"
  - "Phase 177 tests use @moduletag :phase177 and decoded-query Floki assertions (HEEx renders &amp;)"

requirements-completed: ["UXF-10"]

coverage:
  - id: D1
    description: "Health/Deliveries/Inbound with a selected Account link to Preview carrying only return_surface and return_tenant_id"
    requirement: UXF-10
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/phase177_return_navigation_test.exs#Phase 177 Health/Deliveries/Inbound mints"
        status: pass
    human_judgment: false
  - id: D2
    description: "Preview resolves the context only from host navigation; tampered params fall back to direct entry with no Back link or echo"
    requirement: UXF-10
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/preview/return_context_test.exs (56 tests)"
        status: pass
      - kind: integration
        ref: "phase177_return_navigation_test.exs#Phase 177 tampered params render direct entry without a Back link"
        status: pass
    human_judgment: false
  - id: D3
    description: "Back to Health/Deliveries/Inbound link is first in nav, names no Account, and returns to the originating Account (browser)"
    requirement: UXF-10
    verification:
      - kind: e2e
        ref: "playwright: e2e/phase177-return-navigation.spec.js#Phase 177 tracer: Preview returns to the originating Account"
        status: pass
    human_judgment: false
  - id: D4
    description: "ThemeController return_to enforces a mount segment boundary; session maps unchanged"
    requirement: UXF-10
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/router_test.exs#Phase 177 (3 tests)"
        status: pass
    human_judgment: false
---

# Phase 177 Plan 01: Return-Navigation Tracer Summary

**Closed-set Health -> Preview -> Back round trip for a real Account: Shell mints `return_surface`/`return_tenant_id`, `ReturnContext` rebuilds the Back href from host navigation only, and the theme sanitizer now respects the mount segment boundary.**

## Accomplishments

- `MailglassAdmin.Preview.ReturnContext` (`@moduledoc false`, total functions) validates the surface against `~w(overview deliveries inbound)` as strings, takes the destination only from the host-configured navigation entry, and replaces `tenant_id` in place (a configured `?tenant_id=browser-tenant` becomes the selected id, never a second key).
- `Operator.Shell` mints the Preview href once and feeds it to both nav layouts; no Account selected, an invalid id, or a non-local `preview_path` leaves the configured path byte-identical.
- `SurfaceNav` renders a plain-href Back link (`preview-return-link`, `hero-arrow-uturn-left`, label "Back to Health | Deliveries | Inbound") as the first child of the nav landmark.
- `PreviewLive` assigns `:return_context` in every `handle_params` clause; the index redirect keeps both params (`first_scenario_path/4`, `build_capture_url/3`).
- `ThemeController.sanitized_return_to/2` accepts only the mount path or a path under it at a `/`; sibling mounts, backslashes, `//`, and dot/`%2e` segments redirect to the mount path.

## Commands and results

- Pre-change count (before any edit): `mix test test/mailglass_admin/operator/shell_test.exs test/mailglass_admin/preview_live_test.exs --seed 0` -> **70 tests, 0 failures**. Post-change the same two files plus `phase177_return_navigation_test.exs` -> 80 tests (70 + 10 new), 0 failures.
- Task 1 verifies: connected trio 80/0; `operator_live_test.exs --only phase177` 1 test run (174 total, 173 excluded), 0 failures; `--only phase177 --trace` shows "Phase 177 ..." names.
- Task 2: `return_context_test.exs` 56 tests; with `phase177_return_navigation_test.exs` 66 tests, 0 failures.
- Task 3: `router_test.exs` + `preview_live_test.exs` 65 tests, 0 failures; `git diff --quiet -- router.ex` holds.
- Wave gate: shell + return_context + phase177 + router + operator_live + inbound_live tests -> **415 tests, 0 failures** (16s wall clock).
- `bash mailglass_admin/scripts/check-conformance.sh` -> "OK: design-system conformance clean."
- `mix format --check-formatted` on every touched file: clean. `mix credo --strict`: 6 findings, all pre-existing in untouched files/lines (mailables.ex, admin_bootstrap.ex, token_parity_test.exs, operator_live.ex:1689, endpoint_case.ex, operator_live_test.exs:1945); none in files this plan changed.
- `git status --short mailglass_admin/priv/static` empty; `app.css` never staged.

### Red/green evidence

- Task 3 (true red-first): the new sanitizer rows failed on the unmodified controller (`return_to "/ops/mailx"` redirected to itself, 22 tests / 1 failure), then 0 failures after the fix. The session-map test passed on both sides, as intended (router.ex untouched).
- Task 2 (deviation, see below): the implementation landed in Task 1, so the table could not be run red against a missing module. Teeth were proven by a temporary source mutation instead (removed the control-character check, the 255-byte limit, the closed-set guard and the `//` check): **6 failures / 56 tests**; the restored module gives 56 passing tests.

### Playwright tracer

`npm --prefix mailglass_admin run test:operator-browser -- phase177-return-navigation.spec.js --grep "Phase 177 tracer"` -> **1 passed (3.1s)**, Chromium, LV 1.2.13. Measured wall clock for the whole command (Tailwind build + webServer boot + test) was **4s**, but this was a warm run (compiled `_build`, cached Tailwind binary); a cold CI figure is not measured here, so the ~180s advisory budget in 177-VALIDATION.md is neither confirmed nor refuted. `app.css` was clean before the run and restored/clean after (the guard `git checkout -- priv/static/app.css` ran).

### ExUnit per-task timing (budget < 60s)

| Task | Command | Wall clock |
|------|---------|------------|
| 1 | phase177 + shell_test + preview_live_test | ~3.4s |
| 1 | operator_live_test `--only phase177` | ~2.0s |
| 2 | return_context_test + phase177 test | ~1s |
| 3 | router_test + preview_live_test | ~5s |
| gate | 6-file wave gate | 16s |

All under budget.

## Deviations from Plan

### Auto-fixed / Notes

**1. [Rule 3 - Blocking] Icon component takes no `aria-hidden` attr**
- **Found during:** Task 1
- **Issue:** the plan's Back link markup passes `aria-hidden="true"` to `Components.icon`, which declares no `:global` attrs (would be an undefined-attribute warning). `icon/1` already renders `aria-hidden="true"` itself.
- **Fix:** omitted the redundant attribute; the rendered icon is still decorative.
- **Files modified:** mailglass_admin/lib/mailglass_admin/surface_nav.ex
- **Commit:** 529c00cb

**2. [Process] Task 2 red run proven by mutation, not pre-implementation**
- The plan puts the full `ReturnContext` in Task 1 and the table test in Task 2, so a pre-implementation red was impossible. See "Red/green evidence".

**3. [Rule 1 - Bug in own test] Removed a wrong assertion**
- `surface_href(%{overview_path: "/a?b=%zz"}, ...) == nil` assumed `URI.query_decoder/1` raises on `%zz`; it decodes leniently and re-encodes (`%25zz`). The assertion was dropped; the defensive `rescue ArgumentError` in the module stays.

**4. [Process] `mix format` over the whole app touched 10 unrelated files**
- A bare `mix format` reformatted pre-existing drift in files this plan does not own. They were restored with `git checkout -- <file>` before any commit; only plan files were staged. Later formatting used explicit file paths.

**Total deviations:** 1 auto-fixed blocker, 3 process/own-test notes. **Impact:** none on scope or behavior.

## Known Stubs

None. (`ReturnContext` has no stub data; `rg` over the changed files for TODO/FIXME/placeholder found nothing.)

## Threat Flags

None. The only new surface is the internal `return_surface`/`return_tenant_id` query pair on Preview, which is the plan's own threat model (T-177-01..05, all mitigated and tested).

## Notes for later plans

- The remaining Preview builders (sidebar scenario patch, `set_device` width patch via `sync_patch_capture_url_state/1`, nav items, theme round-trip proof) are intentionally not threaded here; until 177-03 a width change on Preview re-resolves the context from a URL that no longer carries it, so the Back link disappears after a device switch. This is the plan's stated tracer boundary (D-04).
- `PreviewLive` gained no Account assigns (`:selected_tenant_id`, `:tenant_id`, `:account_labels`): invariant P8 for 177-11 holds.

## Self-Check: PASSED

- Created files exist: return_context.ex, return_context_test.exs, phase177_return_navigation_test.exs, phase177-return-navigation.spec.js (FOUND).
- Commits reachable from HEAD: 529c00cb, 23d45051, 9769e8f0 (FOUND).
- Acceptance greps: `String.to_atom` 0, `Logger|:telemetry` 0, `preview-return-link` in surface_nav.ex 1, old starts_with clause 0, router.ex unchanged, `priv/static` clean.
