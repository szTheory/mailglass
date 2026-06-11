---
phase: 79-verification-and-visual-regression-hardening
plan: "01"
subsystem: mailglass_admin
tags:
  - conformance
  - design-system
  - shell-script
  - documentation
  - verif-03
dependency_graph:
  requires:
    - phase: 76-06
      provides: five conformance grep gates (zero violations confirmed on current codebase)
    - phase: 74
      provides: Phase 74 baseline PNGs + 6-pillar rubric + GAP register rows
  provides:
    - mailglass_admin/scripts/check-conformance.sh — CI-safe five-gate conformance script
    - mailglass_admin/docs/design-system.md — explicit before/after LLM-critique ritual
  affects:
    - mailglass_admin/scripts/check-conformance.sh
    - mailglass_admin/docs/design-system.md
tech_stack:
  added: []
  patterns:
    - "Bash grep-and-exit conformance script mirroring check_motion_conformance.sh structure"
    - "Footgun-6 exclusion: grep -v text-base-content on TYPE-GATE to eliminate DaisyUI false positives"
key_files:
  created:
    - mailglass_admin/scripts/check-conformance.sh
  modified:
    - mailglass_admin/docs/design-system.md
decisions:
  - "Footgun-6 exclusion is mandatory in TYPE-GATE — text-base-content is a DaisyUI semantic color token, not a raw type-scale violation; without grep -v, every file using it produces a false failure"
  - "Script scopes exclusively to mailglass_admin/lib/ with --include='*.ex' — no CSS file scan (CSS definitions are not violations; false-positive risk mirrors check_motion_conformance.sh's Pass B / app.css exclusion)"
  - "doc expansion is prose-only — no new tooling references, no script additions; bullet-point format matches existing audit-loop voice"
metrics:
  duration: ~8 minutes
  completed: "2026-06-04"
  tasks_completed: 2
  files_modified: 2
---

# Phase 79 Plan 01: Conformance Script and Design-System Audit-Loop Expansion Summary

Committed the five design-system conformance gates as a runnable CI-safe shell script, and expanded the design-system.md audit-loop section to make the before/after LLM-critique comparison an explicit, repeatable procedure. Both deliverables satisfy VERIF-03.

## Performance

- **Duration:** ~8 minutes
- **Tasks:** 2
- **Files created/modified:** 2

## Accomplishments

### Task 1: check-conformance.sh

Created `mailglass_admin/scripts/check-conformance.sh` mirroring the structure of `scripts/check_motion_conformance.sh` exactly. The script:

- Uses `set -euo pipefail`, `LIB="mailglass_admin/lib"`, `errors=0` counter, and `exit 1` on any failure — matching the analog structure invariant-for-invariant.
- Implements the five gates in order:
  - **BADGE-GATE:** `grep -rE 'defp badge_class' "$LIB" --include="*.ex"` — zero results required.
  - **TYPE-GATE:** `grep -rE 'text-(sm|base|xs)' "$LIB" --include="*.ex" | grep -v 'text-base-content'` — Footgun-6 exclusion mandatory.
  - **BOLD-GATE:** `grep -rE 'font-(medium|semibold)' "$LIB" --include="*.ex"` — zero results required.
  - **GAP-GATE:** `grep -rE 'gap-(3|4|6)' "$LIB" --include="*.ex"` — zero results required.
  - **HEX-GATE:** `grep -rE '#[0-9a-fA-F]{3,6}' "$LIB" --include="*.ex"` — zero results required.
- `bash mailglass_admin/scripts/check-conformance.sh` exits 0 and prints "OK: design-system conformance clean."
- `git diff --exit-code mailglass_admin/priv/static/` exits 0 (bundle not dirtied).

### Task 2: design-system.md audit-loop expansion

Expanded the "Ad-hoc (agent-browser)" bullet in the Visual audit loop section with a new **Before/after LLM-critique ritual** bullet. The expansion:

- References the Phase 74 baseline as the comparison baseline (maintainer's local `tmp/ui-audit/`, not committed PNGs).
- References the 6-pillar rubric already present in the doc as the scoring framework.
- Names the four GAP rows that should show visible improvement: GAP-01/03/05/06 (badge colors), GAP-13 (support-card hierarchy), GAP-07 (390px orientation strip), GAP-21 (single h1 on landing).
- Notes the `/ops/mail/` IA change (now Operator Overview landing, not Deliveries list) so reviewers don't flag it as a regression.
- Prose only — no new tooling, no fenced code blocks, no structural changes outside the audit-loop section.
- Known Limitations / GAP-22 block untouched.

## Task Commits

1. **Task 1: check-conformance.sh** — `8c28352a`
2. **Task 2: design-system.md expansion** — `ef660f27`

## Verification Results

```
bash mailglass_admin/scripts/check-conformance.sh
# → OK: design-system conformance clean.

git diff --exit-code mailglass_admin/priv/static/
# → (exit 0) BUNDLE-CLEAN

grep -c "Phase 74 baseline" mailglass_admin/docs/design-system.md
# → 2

cd mailglass_admin && mix test --seed 0 --warnings-as-errors
# → 189 tests, 0 failures (2 excluded)
```

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. Both deliverables are complete and functional.

## Threat Flags

None. This plan creates a read-only shell script (grep + exit) and edits documentation prose. No new auth surfaces, network endpoints, data surfaces, or PII paths introduced.

## Self-Check

Files created/modified:
- [x] `mailglass_admin/scripts/check-conformance.sh` — FOUND
- [x] `mailglass_admin/docs/design-system.md` — FOUND

Commits:
- [x] `8c28352a` — FOUND
- [x] `ef660f27` — FOUND

## Self-Check: PASSED
