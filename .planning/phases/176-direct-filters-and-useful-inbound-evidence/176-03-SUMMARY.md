---
phase: 176-direct-filters-and-useful-inbound-evidence
plan: "03"
subsystem: ui
tags: [phoenix-liveview, heex, inbound, evidence-card, aria-disclosure, admin]

requires:
  - phase: 176-direct-filters-and-useful-inbound-evidence
    provides: "Plan 02 Inbound detail header (independent file set; wave ordering only)"
provides:
  - Inbound.EvidenceCard single persistent Reveal/Hide disclosure with always-visible caption
  - EvidenceCard received_at attr wired from the selected record (consumed by plan 176-05)
  - Rebuilt admin app.css bundle (adds sm:w-auto for the header toggle)
affects: [176-05, 176-10]

plan_head_before: 889fa1435ab4c491e314a1a177f312b2d2256f72
plan_head_after: 737bf5b6c46312eb4215bf8f0c1a4d482a735e9d

actuals:
  tokens: 8500
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "One persistent disclosure element: same id across states, phx-click, label and aria-expanded switch with state, handlers unchanged"

key-files:
  created: []
  modified:
    - mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex
    - mailglass_admin/lib/mailglass_admin/inbound_live.ex
    - mailglass_admin/test/mailglass_admin/inbound_live_test.exs
    - mailglass_admin/test/mailglass_admin/inbound/evidence_card_test.exs
    - mailglass_admin/test/mailglass_admin/inbound/components_test.exs
    - mailglass_admin/e2e/flows.spec.js
    - mailglass_admin/e2e/operator.spec.js
    - mailglass_admin/e2e/phase170-journey.spec.js
    - mailglass_admin/e2e/structural.spec.js
    - mailglass_admin/priv/static/app.css

key-decisions:
  - "Caption and button render only when evidence is present; the no-evidence card keeps just the heading and its existing copy"
  - "The empty :redacted case branch renders nothing: the caption and toggle carry the collapsed state, so no replacement paragraph"
  - "The focus_reveal_after_redact sentinel is left unchanged; it targets the now-persistent button id and is harmless when focus never left it"

requirements-completed: ["INUX-06"]

coverage:
  - id: D1
    description: "One persistent Reveal/Hide toggle (same id, label and aria-expanded flip, reveal_raw then re_redact_raw) through the live Inbound detail; locked badge, inner hide button and hidden-by-default paragraph removed"
    requirement: INUX-06
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#one persistent toggle keeps its id across collapse -> reveal -> collapse"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/inbound/evidence_card_test.exs#the :revealed state reflects aria-expanded=true on the single toggle that collapses it"
        status: pass
      - kind: e2e
        ref: "mailglass_admin/e2e/flows.spec.js#Inbound reveal is a true ARIA disclosure"
        status: pass
    human_judgment: false
  - id: D2
    description: "Denied reveal renders role=status copy and no raw sentinel bytes; redacted/denied component renders contain no raw payload; revealed pre is focusable and labelled"
    requirement: INUX-06
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#denied reveal on the live route renders status copy and no raw sentinel bytes"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/inbound/components_test.exs#redacted and denied states keep raw payload absent while revealed shows it"
        status: pass
    human_judgment: false
  - id: D3
    description: "Reveal telemetry metadata keys remain exactly outcome, record_id, tenant_id"
    requirement: INUX-06
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#reveal telemetry metadata keys are exactly outcome, record_id, tenant_id"
        status: pass
    human_judgment: false
  - id: D4
    description: "No ExUnit or browser spec references the removed card elements/copy except in a refute; moved contrast check passes; bundle committed with token parity"
    requirement: INUX-06
    verification:
      - kind: e2e
        ref: "mailglass_admin/e2e/structural.spec.js#Inbound: WCAG AA contrast matrix covers light/dark themes at 390/768/1440"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/token_parity_test.exs"
        status: pass
    human_judgment: false

duration: 14min
completed: 2026-10-28
status: complete
---

# Phase 176 Plan 03: Raw provider source disclosure Summary

**The Raw provider source card now has one header group (heading, caption, one persistent "Reveal raw source" / "Hide raw source" toggle) with unchanged reveal authorization, telemetry and state atoms.**

## Performance

- **Duration:** about 14 min
- **Completed:** 2026-10-28
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- `EvidenceCard` header is one `flex flex-wrap` group. The button keeps `id="inbound-evidence-reveal-btn"`, flips `phx-click` (`reveal_raw` / `re_redact_raw`), label and `aria-expanded`, and carries `aria-controls="inbound-evidence-raw"` and `aria-describedby="inbound-evidence-caption"`. The caption "May contain personal information." is visible in every evidence-present state.
- Removed: "Raw source locked" badge, the inner second hide button, and the "hidden by default" paragraph. Revealed `<pre>` has `id="inbound-evidence-raw"`, `tabindex="0"`, `aria-label="Raw provider source, read-only"`. Denied copy is now "You don't have permission to reveal raw source." in `role="status"`.
- `received_at` attr added and passed from the selected record via `Map.get/2` (struct-safe); plan 176-05 renders it.
- `reveal_raw`, `re_redact_raw`, `authorize_reveal/1`, telemetry emission and the focus sentinel are untouched.
- Coupled ExUnit and the four browser specs were updated without renaming any title; the contrast AA check moved to the caption.

## Task Commits

1. **Task 1: One persistent Reveal/Hide disclosure through the live Inbound detail (tracer)** - `6d66fd18` (feat)
2. **Task 2: Coupled browser specs and rebuilt bundle** - `737bf5b6` (test)

## Verification

- `mix test` inbound_live_test + inbound/evidence_card_test + inbound/components_test `--seed 0`: 141 tests, 0 failures.
- Quick lane (operator_live_test, inbound_live_test, inbound/components_test, evidence_card_test, bucket_a_coverage_test `--seed 0`): 304 tests, 0 failures.
- token_parity_test + assets_test: 12 tests, 0 failures. `git diff --exit-code -- mailglass_admin/priv/static/` clean after commit.
- Playwright: flows "Inbound reveal is a true ARIA disclosure" 1 passed; operator/phase170/structural named tests 5 passed.
- `check-conformance.sh`: clean. Acceptance greps: `tabindex="0"` count 1 in evidence_card.ex; removed-testid counts 0 in all three specs and flows.spec.js; 0 non-refute hits in components_test and evidence_card_test.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Line numbers in the plan had drifted**
- **Found during:** Task 1
- **Issue:** Plan 02 added tests above the cited ranges in `inbound_live_test.exs` and `components_test.exs`; the plan's line refs were stale. Edits were located by content instead.
- **Fix:** Matched on the assertion text; no behavior change.

**2. [Observation] `npm run test:operator-browser` runs `mix mailglass_admin.assets.build` itself**
- The first Task 1 browser run therefore rebuilt `app.css` in the working tree before Task 2. The rebuilt bundle was left out of the Task 1 commit and committed with Task 2 as planned. Token parity held.

## Issues Encountered

- `mix format --check-formatted` and `mix credo --strict` report findings only in files this plan did not touch (persona_drift_guard_test, bucket_a_coverage_test, preview/chromium_test, inbound/replay_modal_test, operator/deliveries_list.ex, a design-token warning). Files touched here are formatted and have no credo findings. Not fixed (out of scope).

## Known Stubs

None.

## Threat Flags

None. T-176-08/09/10 mitigations are covered by the sentinel-byte tests, the unchanged action-time authorization and the exact-keys telemetry test.

## Self-Check: PASSED

- Commits `6d66fd18` and `737bf5b6` are ancestors of HEAD; `evidence_card.ex` and this SUMMARY exist.
