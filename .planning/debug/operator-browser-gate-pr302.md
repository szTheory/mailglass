---
status: awaiting_human_verify
trigger: "Operator Browser Gate failing on PR #302 (17 Playwright tests) after 21 admin UI polish commits a17f0ee5..1c547f6c; scope extended to 5 Demo Browser Evidence failures"
created: 2026-10-24T00:00:00Z
updated: 2026-10-24T00:00:00Z
---

## Current Focus

reasoning_checkpoint:
  hypothesis: "The 17+5 failures have six product regressions introduced by the polish commits (touch targets on copy controls, truncated preview identity, replay CTA under its dialog, translucent failing-clause surface, nav_link title removal) and otherwise stale assertions against intentional owner-directed copy/structure changes."
  confirming_evidence:
    - "Each regression reproduced locally with the CI message; each fix verified by the original test going green (copy target: phase170:278; identity: structural 200% zoom; CTA: forced-wrap probe reproduced CI geometry x=289,y=542 without fix and clears with fix)."
    - "Stale items trace to explicit owner intent: design-system.md Health rewrite (20ed2d61), inspection-polish note (subject-first identity, ID-as-copy-button, latest event only when distinct, account diagnostics folded, routing caveat), inbound Phase 170-08 selection contract."
  falsification_test: "Reverting any product fix makes its test fail again (verified for CTA via stash)."
  fix_rationale: "Product fixes restore a11y/geometry floors without undoing owner layout; spec edits assert the replacement facts with equal rigor."
  blind_spots: "Linux font metrics only covered via forced-wrap probe; demo evidence verified via Docker script."
  candidate_causes:
    - "code: polish commits changed markup/CSS"
    - "data/environment: CI fonts wrap the replay CTA; test-order fixture state; LiveView settle race in inbound helpers"
  and_gate: "yes for A4/A23 — needs the wrapped CTA (font metrics) AND the folded Account diagnostics row preventing scroll-centering"
next_action: "run full operator gate and demo evidence script; commit by root cause"

## Symptoms

expected: Operator Browser Gate green
actual: CI run 40140010738 — 17 failed / 212 passed / 1 skipped
errors: see CI log job-121009602147.log
reproduction: cd mailglass_admin && npx playwright test --config=playwright.config.cjs --workers=1 <spec:line>
started: after a17f0ee5..1c547f6c (never ran through this gate)

## Eliminated

- hypothesis: "composed-group overflow is real visual overflow"
  evidence: "offenders are sr-only field-help descriptions (1x1 clipped boxes); scrollWidth is clipped nowrap text"
  timestamp: 2026-10-24
- hypothesis: "inbound replayable-row lookup failures in full local run were caused by these changes"
  evidence: "same failure 1/6 at HEAD with all admin changes stashed; probe shows rows absent right after heading paints (LiveView settle)"
  timestamp: 2026-10-24

## Evidence

- timestamp: 2026-10-24
  checked: local run of the 17 failing tests
  found: 15 fail locally with same messages; structural.spec.js:3533 passes locally
  implication: deterministic except 3533 (font-metric dependent)
- timestamp: 2026-10-24
  checked: CI trace frame for A4/A23
  found: replay CTA wrapped to left under centered dialog; overlaps by ~18px vertically
  implication: needs product fix; ml-auto keeps CTA right-aligned outside dialog footprint
- timestamp: 2026-10-24
  checked: inbound contrast matrix after row-lookup fix
  found: trace clause 2.63:1 because bg-error/10 is translucent and helper ignores alpha
  implication: opaque color-mix surface (same appearance) gives a definite background

## Resolution

root_cause: "see Current Focus hypothesis"
fix: "commits 31e9746b 1cac2182 4e7d2e24 941cac11 6af0e4f1 454fc37f"
verification: "local Operator Browser Gate 229 passed/0 failed/1 skipped (retries 0); admin mix test 634/0; demo evidence 82/0/0 flaky"
files_changed: []
