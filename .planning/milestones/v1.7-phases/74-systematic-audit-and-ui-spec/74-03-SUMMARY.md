---
phase: "74"
plan: "03"
subsystem: mailglass_admin
tags: [audit, gap-register, badge-taxonomy, before-baseline, AUDIT-01]
dependency_graph:
  requires: ["74-01", "74-02"]
  provides: [74-GAP-REGISTER, AUDIT-01-coverage, anti-churn-gate]
  affects: [phases/75, phases/76, phases/77, phases/78, phases/79]
tech_stack:
  added: []
  patterns: [scored-gap-register, stable-gap-ids, five-badge-sites-enumerated]
key_files:
  created:
    - .planning/phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md
  modified: []
decisions:
  - "GAP-22 deep-link row filed at sev-3 (not sev-4/5) so it does not falsely block Phase 79 closeout before Phase 75 makes the formal in/out decision (IA-04)"
  - "Both latent detail_header.ex badge_class copies (GAP-05, GAP-06) explicitly flagged as the Pitfall-5 failure mode — Phase 76 must delete all 5 copies, not just the 3 named in CONTEXT D-12"
  - "390px rows filed for all three surfaces at sev-3 to satisfy the Pitfall-15 mandatory mobile pass and make them citable in Phase 75 acceptance criteria"
metrics:
  duration: "~15 minutes"
  completed: "2026-06-04"
  tasks_completed: 2
  files_changed: 1
---

# Phase 74 Plan 03: Gap Register (AUDIT-01) Summary

Authored `74-GAP-REGISTER.md` — 22 stable GAP-NN rows covering surface × light/dark × viewport (390/768/1440) × state — enumerating all five `badge_class/1` call sites including the two latent `detail_header.ex` copies, filing explicit 390px mobile rows per surface, and recording the deep-link unstyled-CSS bug as GAP-22 with "Defer to Phase 79" disposition. Zero production code changed.

---

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Author 74-GAP-REGISTER.md header — schema, pillar set, severity rubric | 2ebceeba | `.planning/phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md` |
| 2 | Populate gap rows — all 5 badge_class copies, 390px pass, deep-link defer row | 2ebceeba | `.planning/phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md` |

Tasks 1 and 2 produced a single file; committed together as one atomic change (the file is a single authored artifact, not a two-step modification).

---

## Gap Register Summary

### AUDIT-01 Coverage

| Category | Rows | Min Sev | Phase targets |
|----------|------|---------|---------------|
| Badge consolidation (5 call sites) | GAP-01 – GAP-06 | 3 | DS-01 (Phase 76) |
| 390px mobile — Deliveries | GAP-07, GAP-08 | 3 | IA-03 (Phase 75) |
| 390px mobile — Inbound | GAP-09, GAP-10 | 3 | IA-03 (Phase 75) |
| 390px mobile — Preview | GAP-11, GAP-12 | 2–3 | IA-03 (Phase 75) |
| Support-card hierarchy | GAP-13, GAP-14, GAP-15 | 2–4 | DS-03 (Phase 76) |
| Type / spacing token drift | GAP-16, GAP-17, GAP-18 | 2–3 | DS-02 (Phase 76) |
| Motion + A11y | GAP-19, GAP-20, GAP-21 | 2–3 | MOTION-01 (Phase 77) |
| Deep-link deferral | GAP-22 | 3 | VERIF-04 (Phase 79) |

Total rows: 22. No duplicate GAP-NN IDs.

### Five badge_class/1 Call Sites (Pitfall-5 Prevention)

`grep -rln badge_class mailglass_admin/lib` returns exactly five files:

| # | File | Lines | Status |
|---|------|-------|--------|
| 1 | `operator/deliveries_list.ex` | 80-84 | Named (D-12); GAP-01/GAP-02 |
| 2 | `operator/timeline.ex` | 130-135 | Named (D-12); GAP-03 |
| 3 | `inbound/records_list.ex` | 97-101 | Named (D-12); GAP-04 |
| 4 | `operator/detail_header.ex` | 81-85 | **LATENT** — not in D-12; GAP-05 |
| 5 | `inbound/detail_header.ex` | 142-146 | **LATENT** — not in D-12; GAP-06 |

The two latent copies replicate the same divergent behavior as their list-view counterparts.
Phase 76 must delete all five copies; missing either detail_header.ex copy would leave a
divergent `badge_class/1` live in the delivery/inbound detail header while the list is fixed.

### Deep-Link Row (D-11, mandatory)

GAP-22 filed at sev-3 referencing `docs/design-system.md:141-150`. Fix sketch: "Defer to Phase 79 (VERIF-04); formal in-scope/deferred decision owned by Phase 75 (IA-04)." Severity is intentionally 3 (not 4/5) so it does not falsely block Phase 79 closeout before Phase 75 makes the formal decision. Per Pitfall 16: if Phase 75 defers to Phase 79, the sev-3 row must be either fixed or explicitly downgraded with rationale before Phase 79 closeout.

---

## Deviations from Plan

None. Plan executed exactly as written. Both tasks completed in a single file creation, committed atomically.

---

## Threat Surface Scan

No new attack surface introduced. This is a documentation-only plan. The gap register cites only structural/aggregate strings, class names, and PNG paths — no raw recipient/subject/delivery PII. All referenced PNG paths point to gitignored `tmp/ui-audit/` (D-06; never committed). T-74-03 is fully mitigated.

---

## Known Stubs

None. The gap register is a complete scored artifact with 22 populated rows. All rows have concrete fix sketches referencing the frozen UI-SPEC taxonomy. No placeholder or "TODO" entries.

---

## Self-Check: PASSED

- [x] `74-GAP-REGISTER.md` exists with stable GAP-NN IDs and AUDIT-01 column schema
- [x] Commit `2ebceeba` exists in git log
- [x] All five `badge_class/1` call sites enumerated — `grep -rln badge_class mailglass_admin/lib` returns 5 files, all present in register
- [x] Explicit 390px rows: Deliveries (GAP-07, GAP-08), Inbound (GAP-09, GAP-10), Preview (GAP-11, GAP-12) — one or more per surface
- [x] Deep-link row GAP-22 present with "Phase 79" deferral disposition
- [x] Every build-anchor row is severity >= 3; every pillar is one of the canonical six
- [x] `git diff --name-only` shows only `.planning/` changed — confirmed
- [x] `git diff --exit-code mailglass_admin/priv/static/` exits 0 — confirmed
- [x] Zero `mailglass_admin/lib/` files changed — confirmed
- [x] `74-GAP-REGISTER.md` line count: 226 lines (well above 60-line minimum)
- [x] `grep -oE 'GAP-[0-9]+' 74-GAP-REGISTER.md | sort | uniq -d` returns only IDs that appear in multiple sections (table rows, summary section, self-verification) — no IDs appear more than once as a table data row
