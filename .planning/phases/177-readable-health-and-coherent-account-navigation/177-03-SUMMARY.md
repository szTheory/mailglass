---
phase: 177-readable-health-and-coherent-account-navigation
plan: "03"
subsystem: ui
tags: [phoenix-liveview, navigation, preview, return-context, copy]
status: complete

requires:
  - phase: 177-01
    provides: ReturnContext validator/minting, PreviewLive :return_context assign, SurfaceNav Back link
provides:
  - "Return context survives the width patch, sidebar/menu scenario links, broken-scenario link and nav items in Preview"
  - "Preview.Sidebar picker/menu/mailable entries take a return_query attr"
  - "TestOperatorAuth forbidden-account denial and navigation on the /alt/dev and /secure test mounts"
  - "Preview subtitle states what Preview reads (D-12)"
affects: [177-11]

plan_head_before: d8e3480698ecdf3ed6d60d0002fb437087b7841e
plan_head_after: 5c948a8859f397603cfaac5fce66246ff91294a5

actuals:
  tokens: 11000
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Every Preview-internal URL goes through ReturnContext.append_query/2; [] returns the string unchanged (byte identity)"
    - "Nav hrefs with a valid context: ReturnContext.surface_href/3 per surface, falling back to the static host path when the entry is not a local path"

key-files:
  created: []
  modified:
    - mailglass_admin/lib/mailglass_admin/preview_live.ex
    - mailglass_admin/lib/mailglass_admin/preview/sidebar.ex
    - mailglass_admin/test/support/endpoint_case.ex
    - mailglass_admin/test/mailglass_admin/phase177_return_navigation_test.exs
    - mailglass_admin/test/mailglass_admin/preview_live_test.exs
    - mailglass_admin/test/mailglass_admin/voice_test.exs

key-decisions:
  - "build_capture_url/3 lost its default arity: both callers pass the pairs explicitly"
  - "preview_theme_path/2 and ReturnContext were not edited; the theme round trip is proven by test only (Pitfall 5)"
  - "Per-surface nav href falls back to the configured static path when surface_href/3 returns nil (non-local configured entry), matching direct entry"
  - "Unauthorized arrival is proven only through the host redirect; no mailglass copy (D-05); the push_patch Account-switch gap stays deferred and is not claimed fixed"

patterns-established:
  - "Custom-mount tests assert decoded query pairs (sorted), not raw strings: put_tenant appends tenant_id after an existing query"

requirements-completed: ["UXF-10", "UXF-09"]

coverage:
  - id: D1
    description: "Return params survive width patch (once each), scenario/broken links and nav items; theme round trip keeps the Back link; no-context URLs are byte-identical"
    requirement: UXF-10
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/phase177_return_navigation_test.exs#Phase 177 context survives every Preview URL builder (8 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Custom mounts (/secure/console <-> /alt/dev/console), host-denied forbidden-account arrival, tampered-input parity with direct entry, frame HTML independence, Back link on not-found and raising scenarios"
    requirement: UXF-10
    verification:
      - kind: integration
        ref: "phase177_return_navigation_test.exs#Phase 177 custom mounts / host-denied Accounts / tampered input / Preview rendering (10 tests)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Preview subtitle equals the D-12 sentence with preview_props/0 in code.mono and none of the whole words sample, demo, fake, live"
    requirement: UXF-09
    verification:
      - kind: integration
        ref: "preview_live_test.exs (shell copy test) and voice_test.exs (canonical brand copy)"
        status: pass
    human_judgment: false
---

# Phase 177 Plan 03: Preview Return-Context Persistence Summary

**The validated return context now survives every Preview navigation (width patch, scenario and broken links, nav items, theme round trip), is proven against custom mounts, host-denied Accounts and tampered input, and Preview's subtitle states what it actually reads.**

## Accomplishments

- `build_capture_url/3` appends the context pairs; `sync_patch_capture_url_state/1` passes `ReturnContext.query_pairs/1`, so `set_device` patches keep both params exactly once (idempotency test counts keys in the decoded list).
- `Preview.Sidebar.picker/1`, `menu/1` and the two entry components take `return_query` (default `[]`) and thread it into `scenario_path/6` and `broken_path/3` via `ReturnContext.append_query/2`.
- `preview_surface_paths/1` has a context clause: Health, Deliveries and Inbound each resolve from their own configured entry with `tenant_id` replaced in place; the Preview item keeps both return params. Without a context the original clause is untouched.
- Test router: `/alt/dev` Preview mount got `navigation:` to the `/secure` operator mount (overview, deliveries, inbound), the `/secure` operator mount got `navigation: [preview_path: "/alt/dev/console"]`, and `TestOperatorAuth` denies `tenant_id=forbidden-account` with the host redirect to `/login`.
- Preview subtitle: "Renders the scenarios in each Mailable's `preview_props/0`. It doesn't read Deliveries or Inbound messages from any Account."

## Commands and results

- Task 1: `mix test phase177_return_navigation_test.exs preview_live_test.exs router_test.exs --seed 0` -> 83 tests, 0 failures (first red run: 4 failures in the new rows, then green). `--only phase177 --trace` lists "Phase 177 width patch twice keeps each return key once" (18 tests in the file at that point).
- Task 2: `phase177_return_navigation_test.exs admin_asset_url_test.exs assets_test.exs --seed 0` -> 48 tests, 0 failures. Red before the `endpoint_case.ex` edit: forbidden-account (3) and alt-mount (2) rows failed, as required.
- Task 3: `preview_live_test.exs voice_test.exs --seed 0` -> 61 tests, 0 failures, 1 excluded.
- Wave gate (preview_live, phase177, return_context, router, operator_live, inbound_live, voice, admin_asset_url, assets): 487 tests, 0 failures, 1 excluded (~21s).
- Full admin suite `mix test --seed 0`: 972 tests, 0 failures, 1 excluded.
- `bash mailglass_admin/scripts/check-conformance.sh`: "OK: design-system conformance clean." `mix format --check-formatted` on all six touched files: clean. `mix credo --strict`: 6 findings, all pre-existing in untouched files/lines (same set as 177-01). `git status --short mailglass_admin/priv/static` empty; no bundle change.
- Acceptance greps: `return_query` in sidebar.ex 15 (baseline 0, need 4); `forbidden-account` in endpoint_case.ex 1; old subtitle 0 in preview_live.ex; D-12 sentence 1.

## Deviations from Plan

**1. [Rule 1 - Own-test correction] Alt-mount Deliveries href key order**
- The configured alt entry `/secure/console?view=deliveries` carries no `tenant_id`, so `put_tenant` appends it after `view`. The test originally compared a raw string in the dev-mount order; it now compares sorted decoded pairs. No code change.

**2. [Process] Task 3 not run red-first**
- The subtitle assertions and the template change were authored together in one edit and then run green; the old string is gone from every file (grep 0), so the previous assertions cannot pass against the new template either way.

**3. [Design choice within Rule 2] Nav fallback to the static path**
- The plan said "nil when that entry is missing". Implemented as `surface_href/3 || navigation_path/2`: a configured path that is non-local yields the same static value direct entry shows, instead of silently dropping a nav item; a missing entry is still nil.

**Total deviations:** 1 own-test fix, 1 process note, 1 small robustness choice. **Impact:** none on scope.

## Known Stubs

None.

## Threat Flags

None. No package or lockfile changes; the only surface touched is the internal `return_surface`/`return_tenant_id` pair already in the plan's threat model (T-177-07..10 mitigated: host deny proven by test, all re-emission via `append_query/2`, no mailglass denial copy, no claim of patch-time re-authorization).

## Self-Check: PASSED

- Modified files exist; commits 36953f3d, 4cdcb184, 5c948a88 reachable from HEAD.
