---
type: bug
created: 2026-06-04
surfaced_in: 77 (motion-and-microinteraction-polish)
resolves_phase: 79
severity: medium
area: mailglass_admin e2e (operator browser gate)
---

# Pre-existing e2e failure: "exact replay flow" timeline assertion

`mailglass_admin/e2e/operator.spec.js:104` — *"exact replay flow shows ready copy
and records a new-work outcome"* fails at line 128: after a replay confirm, the
`operator-timeline` does not contain the expected "Replay audit" entry (the
preceding header assertion at line 125, "Last replay: completed · new work",
passes).

## Confirmed pre-existing (not a Phase 77 regression)

- Fails consistently in isolation and in the full suite.
- Fails **identically** when `operator_live.ex` / `inbound_live.ex` are reverted
  to the pre-77 baseline (commit `868eb92b`, no record-keyed `id`) — so the
  failure predates Phase 77 and is independent of the motion-reveal id change.
- Phase 77 never modified the replay/timeline code path (77-01 added only `id`
  attributes to the two detail-pane divs).

## Why it matters

Surfaced during Phase 77 shift-left e2e execution. It is genuine prior-phase
debt in the operator browser gate. Natural fit for the Phase 79
"Verification and Visual-Regression Hardening" wave (extended e2e + audit-matrix
re-run). Triage there: determine whether the replay outcome event is not being
recorded, or the timeline is not re-rendering the new audit entry under the
browser-scenario seed.

## Repro

```
cd mailglass_admin
npx playwright test --config=playwright.config.cjs operator.spec.js \
  -g "exact replay flow shows ready copy"
```
