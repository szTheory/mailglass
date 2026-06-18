---
phase: 106-day-2-guides-go-live-checklist-error-troubleshooting-map
plan: "01"
subsystem: docs
tags: [guides, operator, checklist, errors, troubleshooting]
dependency_graph:
  requires: []
  provides:
    - guides/production-go-live-checklist.md
    - guides/errors-and-troubleshooting.md
  affects:
    - docs/api_stability.md (cross-linked, not modified)
    - guides/operator-incident-support.md (cross-linked, not modified)
    - guides/webhook-troubleshooting.md (cross-linked, not modified)
tech_stack:
  added: []
  patterns:
    - Cross-link-not-duplicate orchestrating guide pattern
    - Closed-atom-set routing to api_stability.md (source-of-truth delegation)
key_files:
  created:
    - guides/production-go-live-checklist.md
    - guides/errors-and-troubleshooting.md
  modified: []
decisions:
  - "Checklist sections use ## (two-hash) headings throughout for docs_helper extract_block_after_heading/2 compatibility"
  - "StreamPolicyError section sourced entirely from stream_policy_error.ex (absent from api_stability.md); remediation note added"
  - "Oban queue sizing uses generic :mailglass queue name per Honest-Surface lens — no invented config key"
metrics:
  duration_seconds: 144
  completed_date: "2026-06-17"
  tasks_completed: 2
  files_created: 2
  files_modified: 0
---

# Phase 106 Plan 01: Day-2 Guides — Go-Live Checklist + Errors/Troubleshooting Summary

Two new operator guides written as pure markdown: a 7-section production go-live checklist surfacing both doctor commands with distinct descriptions, and a 10-section unified error struct map routing canonical type/retryable truth to api_stability.md.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Write guides/production-go-live-checklist.md | fdace05a | guides/production-go-live-checklist.md |
| 2 | Write guides/errors-and-troubleshooting.md | 146bec54 | guides/errors-and-troubleshooting.md |

## Verification Results

All plan verification checks passed:

1. Both files exist.
2. Checklist has exactly 7 `##` sections (grep count = 7).
3. Both doctor commands present: `mix mail.doctor` and `mix mailglass.doctor` appear with distinct descriptions (DNS checks requiring app.start vs OFFLINE static wiring check).
4. Errors guide has exactly 10 `##` sections (grep count = 10).
5. All ten struct names present in errors guide.
6. `## StreamPolicyError` is a two-hash heading (not `###`).
7. `api_stability` appears 11 times in the errors guide (once in intro, once per struct section).

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. Both guides are complete and cross-link live files. No placeholder text or TODO markers.

## Threat Flags

None. Both guides are public markdown documentation with no runtime attack surface, no secrets, no PII, and no code paths.

## Self-Check: PASSED

Files confirmed present:
- /Users/jon/projects/mailglass/guides/production-go-live-checklist.md
- /Users/jon/projects/mailglass/guides/errors-and-troubleshooting.md

Commits confirmed:
- fdace05a: docs(106-01): add production-go-live-checklist.md
- 146bec54: docs(106-01): add errors-and-troubleshooting.md
