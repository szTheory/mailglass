---
phase: 11-rfc-8058-list-unsubscribe
plan: 07
subsystem: docs
tags: [rfc-8058, unsubscribe, dkim, exdoc, docs-smoke]
requires:
  - phase: 11-04
    provides: router mount contract and generator behavior
  - phase: 11-05
    provides: controller GET behavior and redirect escape hatch
  - phase: 11-06
    provides: replay-safe POST contract and property-backed durability
provides:
  - unsubscribe adopter walkthrough aligned with the shipped config, router, controller, and generator behavior
  - DKIM verification guide requiring both unsubscribe headers in the signed `h=` list
  - docs smoke coverage for the published unsubscribe and ExDoc navigation contract
affects: [phase-11, docs, exdoc, adopter-guides]
tech-stack:
  added: []
  patterns: [guide contracts enforced by ExUnit smoke tests, ExDoc extras used as a published operational contract]
key-files:
  created:
    - guides/unsubscribe.md
    - guides/dkim-setup.md
    - test/mailglass/docs/unsubscribe_guide_test.exs
  modified:
    - mix.exs
key-decisions:
  - "Published unsubscribe setup as a dedicated adopter walkthrough instead of folding it into a broader guide so the route, rotation, and replay contract stay explicit."
  - "Kept the docs smoke test string-based and ExDoc-wiring based so route shape, zero-copy generator behavior, and guide publication fail loudly on drift."
patterns-established:
  - "Operational guides should assert exact route and task strings in ExUnit so docs stay load-bearing."
  - "RFC 8058 rollout docs must pair product guidance with DKIM `h=` verification guidance, not treat them as separate concerns."
requirements-completed: [UNSUB-06]
duration: 4 min
completed: 2026-04-28
---

# Phase 11 Plan 07: RFC 8058 docs contract summary

**Adopter-facing RFC 8058 setup, replay, rotation, and DKIM verification guidance with load-bearing docs smoke coverage**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-28T09:58:00Z
- **Completed:** 2026-04-28T10:01:48Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added `guides/unsubscribe.md` as the canonical adopter walkthrough for compliance config, router mount, generator usage, built-in GET behavior, lifecycle hooks, POST replay, and `previous_secrets` rotation.
- Added `guides/dkim-setup.md` with explicit RFC 8058 `h=` guidance for both unsubscribe headers plus Postmark and SendGrid verification notes.
- Added `test/mailglass/docs/unsubscribe_guide_test.exs` and wired both guides into ExDoc so the published docs contract is enforced by tests instead of prose drift.

## Task Commits

Each task was committed atomically:

1. **Task 1: Write the unsubscribe adopter guide and docs smoke test** - `96bfc40` (feat)
2. **Task 2: Update DKIM guidance and docs navigation for RFC 8058** - `4d399f9` (docs)

## Files Created/Modified

- `guides/unsubscribe.md` - Canonical RFC 8058 setup, UAT, troubleshooting, and rotation walkthrough.
- `guides/dkim-setup.md` - DKIM `h=` verification guidance for `List-Unsubscribe` and `List-Unsubscribe-Post`.
- `test/mailglass/docs/unsubscribe_guide_test.exs` - Smoke tests for route shape, zero-copy generator contract, UAT steps, rotation language, and ExDoc wiring.
- `mix.exs` - ExDoc extras and guide navigation entries for the new unsubscribe and DKIM docs.

## Decisions Made

- Split unsubscribe setup and DKIM verification into two guides so adopters get one primary wiring walkthrough plus one focused deliverability-verification reference.
- Treated ExDoc navigation as part of the contract by asserting both guides are present in `docs[:extras]` and the `Guides` group.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- `mix docs` emits pre-existing ExDoc warnings about `Swoosh.Email.recipient()` and hidden `Mailglass.Lifecycle.Noop` references. The docs build still passed, and those warnings were out of scope for this plan.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 11 is complete. Adopters now have published setup and verification guidance that matches the shipped unsubscribe implementation.
- Ready for the next roadmap step without additional Phase 11 documentation work.

## Verification

- `mix test test/mailglass/docs/unsubscribe_guide_test.exs && mix docs`

## Self-Check: PASSED

---
*Phase: 11-rfc-8058-list-unsubscribe*
*Completed: 2026-04-28*
