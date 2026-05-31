---
phase: 60-release-trust-gate-drift-prevention
plan: "01"
subsystem: reference-host
tags: [deps, hex, reference-host, trust-baseline]
dependency_graph:
  requires: []
  provides: [reference/host_app resolves siblings from Hex at 1.3.0/1.3.0/0.3.0]
  affects: [60-02-PLAN.md, 60-03-PLAN.md]
tech_stack:
  added: []
  patterns: [scoped mix deps.update, Hex-source guard script]
key_files:
  created: []
  modified:
    - reference/host_app/mix.exs
    - reference/host_app/mix.lock
decisions:
  - "D-02 applied: bump reference/host_app pins to ~> 1.3/~> 1.3/~> 0.3 so Hex-baseline lanes resolve live code"
  - "decimal 3.1.0→3.1.1 transitive bump accepted as benign patch noise; all other transitive deps unchanged"
metrics:
  duration: "~4 minutes"
  completed: "2026-05-29T12:31:09Z"
  tasks_completed: 1
  tasks_total: 1
  files_modified: 2
---

# Phase 60 Plan 01: Reference Host Sibling Pin Bump Summary

Bump the reference host's three sibling package pins from `~> 1.2`/`~> 1.2`/`~> 0.2` to `~> 1.3`/`~> 1.3`/`~> 0.3` and refresh its lock to Hex-sourced 1.3.0/1.3.0/0.3.0, enabling the Hex-baseline trust lanes in Plans 02 and 03.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Bump three sibling pins and scoped-refresh the lock | `707af25` | reference/host_app/mix.exs, reference/host_app/mix.lock |

## Verification Results

- `reference/host_app/mix.exs` contains `{:mailglass, "~> 1.3"}`, `{:mailglass_admin, "~> 1.3"}`, `{:mailglass_inbound, "~> 0.3"}` — confirmed via grep
- `reference/host_app/mix.lock` entries: `mailglass` at 1.3.0 (:hex), `mailglass_admin` at 1.3.0 (:hex, inner pin `{:mailglass, "1.3.0"}`), `mailglass_inbound` at 0.3.0 (:hex, inner pin `{:mailglass, "1.3.0"}`) — confirmed via diff review
- `bash scripts/check_clean_baseline_hex_only.sh` run from `reference/host_app/` exits 0 — all three siblings positively `:hex`-sourced at correct versions
- Lock diff is confined to 4 entries: `mailglass`, `mailglass_admin`, `mailglass_inbound` (3 sibling targets), plus one transitive `decimal` bump (flagged below)

## Deviations from Plan

**Transitive dep churn — `decimal` 3.1.0 → 3.1.1**

- **Found during:** Task 1, when reviewing `git diff reference/host_app/mix.lock`
- **Issue:** `mix deps.update mailglass mailglass_admin mailglass_inbound` also bumped `decimal` from 3.1.0 to 3.1.1. Elixir's resolver accepted 3.1.1 as a better patch within the existing `~> 3.0` constraint. This is cosmetic patch noise (no API or behavior changes); `decimal` is not a sibling package.
- **Fix:** No action taken — the bump is benign and correct; reverting would require pinning `decimal` explicitly which would be counter-productive.
- **Flagged per:** Plan Task 1 acceptance criteria ("any churn is flagged in the SUMMARY")

No other deviations.

## Known Stubs

None. The reference host mix.exs and mix.lock are data files, not application stubs.

## Threat Flags

None. The lock diff was reviewed: only three first-party sibling entries and one benign transitive patch (decimal) moved. No new network endpoints, auth paths, file access patterns, or schema changes.

## Self-Check: PASSED

- [x] `reference/host_app/mix.exs` modified with correct pins — file exists and was edited
- [x] `reference/host_app/mix.lock` refreshed — file exists and was updated by `mix deps.update`
- [x] Commit `707af25` exists: `git log --oneline | grep 707af25`
- [x] Hex-source guard passes from `reference/host_app/` — confirmed above
