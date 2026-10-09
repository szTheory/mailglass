---
phase: 170-inbound-investigation-and-recovery
plan: "03"
subsystem: inbound-operator-ui
tags: [elixir, phoenix_live_view, inbound, privacy, accessibility]

# Dependency graph
requires: []
provides:
  - Safe provider-aware verification projection for ordinary inbound evidence
  - Masked current-router simulation with matcher verdicts preserved
  - Native progressive disclosure for the current routing explanation
affects: [inbound-evidence, routing-trace, INUX-02, INUX-03]

# Actuals (#2632)
actuals:
  tokens: 5293
  tasks: 2
  commits: 4

# Tech tracking
tech-stack:
  added: []
  patterns:
    - 'Render provider verification only through an explicit allowlist and fixed copy.'
    - 'Sanitize routing fields before HEEx while preserving matcher verdicts.'
    - 'Use native details and summary elements to keep disclosure state browser-owned.'

key-files:
  created: []
  modified:
    - mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex
    - mailglass_admin/lib/mailglass_admin/inbound/routing_trace.ex
    - mailglass_admin/test/mailglass_admin/inbound/evidence_card_test.exs
    - mailglass_admin/test/mailglass_admin/inbound/components_test.exs

key-decisions:
  - 'Only SES auth equal to sns_x509 renders a fixed authentication status; all other verification input is unavailable.'
  - 'Keep current matcher pass and fail results, but mask or withhold message fields, header names, and matcher source text.'
  - 'Use native details and summary disclosure semantics so the browser exposes the true expanded state and keyboard behavior without JavaScript or duplicated LiveView state.'

patterns-established:
  - 'Verification facts are projected through an exact provider-specific safe mapping; raw map enumeration is prohibited.'
  - 'Routing explanations state that they simulate the current router and do not establish historical routing.'

requirements-completed: [INUX-02, INUX-03]

# Coverage metadata
coverage:
  - id: D1
    description: 'Ordinary inbound evidence exposes only the fixed SES verification fact or Unavailable and keeps raw evidence redacted.'
    requirement: INUX-03
    verification:
      - kind: unit
        ref: 'mailglass_admin/test/mailglass_admin/inbound/evidence_card_test.exs#test safe verification projection (D-05/D-06) ordinary evidence shows only the fixed SES authentication fact and withholds untrusted data'
        status: pass
      - kind: unit
        ref: 'mailglass_admin/test/mailglass_admin/inbound/evidence_card_test.exs#test safe verification projection (D-05/D-06) absent or unrecognized SES authentication renders unavailable without raw values'
        status: pass
      - kind: unit
        ref: 'mailglass_admin/test/mailglass_admin/inbound/evidence_card_test.exs#test reveal disclosure ARIA (D-11) the :revealed state reflects aria-expanded=true and renders the re-redact collapse'
        status: pass
    human_judgment: false
  - id: D2
    description: 'Routing clauses retain matcher verdicts while masking or withholding message and matcher values and identifying the output as a current-router simulation.'
    requirement: INUX-02
    verification:
      - kind: unit
        ref: 'mailglass_admin/test/mailglass_admin/inbound/components_test.exs#test RoutingTrace.routing_trace renders a responsive clause grid with masked recipient actuals'
        status: pass
      - kind: unit
        ref: 'mailglass_admin/test/mailglass_admin/inbound/components_test.exs#test RoutingTrace.routing_trace masks long non-ASCII values and safely labels unsupported route clauses'
        status: pass
    human_judgment: false
  - id: D3
    description: 'The routing explanation uses a native keyboard-operable disclosure with a focus target and a content control relationship.'
    requirement: INUX-03
    verification:
      - kind: unit
        ref: 'mailglass_admin/test/mailglass_admin/inbound/components_test.exs#test RoutingTrace.routing_trace renders a responsive clause grid with masked recipient actuals'
        status: pass
    human_judgment: false

# Metrics
duration: 8min
completed: 2026-10-08
status: complete
---

# Phase 170 Plan 03: Privacy-safe evidence and current-router simulation

**Inbound evidence now shows only approved verification facts, and route explanations preserve verdicts without exposing message contents or implying historical certainty.**

## Performance

- **Duration:** 8 min from the first recorded RED run through task verification.
- **Started:** 2026-10-08T22:17:26-04:00 (first task RED evidence).
- **Completed:** 2026-10-08T22:25:16-04:00.
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Replaced generic verification-fact rendering with a fixed SES SNS X.509 authentication label and an unavailable fallback; unknown provider identities render as UNKNOWN.
- Kept raw provider payload and MIME in the existing reveal-state branch, with no new authorization surface.
- Labeled routing output as a simulation of the currently configured router, kept matcher verdicts, masked recipient and subject values, and withheld header and unsupported matcher details.
- Added a native details/summary disclosure with a focus target and control relationship; its browser-owned state stays truthful as content opens and closes.

## Task Commits

1. **Task 1: Project safe stored verification facts and retain gated raw disclosure** — RED 3daabf8a; GREEN 16a0c4a9.
2. **Task 2: Mask route matcher values and label current simulation explicitly** — RED 7afb58ae; GREEN 557573a5.

Both RED runs have committed JUnit reports and JSON records under artifacts/tdd-red; GSD classified each as RED_EVIDENCE_OK.

## Files Created/Modified

- mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex — fixed provider-aware verification projection and allowlisted provider identity.
- mailglass_admin/lib/mailglass_admin/inbound/routing_trace.ex — safe field projection, current-router copy, unknown-clause fallback, and native disclosure.
- mailglass_admin/test/mailglass_admin/inbound/evidence_card_test.exs — adversarial provider facts and redaction assertions.
- mailglass_admin/test/mailglass_admin/inbound/components_test.exs — route masking, historical-boundary copy, Unicode, long-value, and disclosure assertions.

## Decisions Made

- A literal SES auth fact of sns_x509 is the only displayed verification detail. All other keys and values remain unavailable in ordinary HTML.
- Exact recipient and subject matchers are masked; regex sources and header matcher values are withheld; actual header content and header names are not rendered.
- The current router is explanatory simulation only. Persisted execution and route-binding records remain the historical evidence.
- Native details/summary semantics expose browser-managed expanded state and keyboard behavior, avoiding a static aria-expanded value or a second LiveView state machine.

## Deviations from Plan

None - the plan's privacy, source-label, and disclosure behavior is implemented with native browser disclosure semantics.

## Issues Encountered

- Focused tests used the pinned Erlang/Elixir toolchain with --no-deps-check because the previously recorded local Dialyxir checkout differs from the lockfile. No dependency or lockfile changes were made.
- The focused Admin test run emits existing Boundary and Oban-not-loaded warnings; both component modules still pass.

## User Setup Required

None - no external service or schema setup is required.

## Next Phase Readiness

- Plan 170-04 is the next Wave 2 plan and its prerequisites 170-01 and 170-02 are complete.
- INUX-02 and INUX-03 remain pending at phase level because sibling plans also declare them; GSD reports 0/2 requirement IDs ready to mark.
- Rendered keyboard, zoom, and theme acceptance remains assigned to Plan 170-08.

## Self-Check: PASSED

- Plan files and both component test modules exist; all task tests and the combined plan verification pass.
- Combined focused verification: 29 tests passed; formatter check passed.
- Evaluation-scope found all four Plan 170-03 task commits on the current branch.

---
*Phase: 170-inbound-investigation-and-recovery*
*Completed: 2026-10-08*

