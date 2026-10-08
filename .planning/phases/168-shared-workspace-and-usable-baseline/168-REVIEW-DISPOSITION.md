---
phase: 168
review: 168-REVIEW.md
titles: json
findings:
  - id: CR-01
    severity: critical
    disposition: open
    title: "Delivery badges show the stored snapshot instead of the latest outcome"
  - id: CR-02
    severity: critical
    disposition: open
    title: "Transient reads can display cached support evidence from another Account"
  - id: WR-01
    severity: warning
    disposition: open
    title: "Malformed exact-support IDs crash the LiveView"
  - id: WR-02
    severity: warning
    disposition: open
    title: "Preview success flash cannot be dismissed"
  - id: WR-03
    severity: warning
    disposition: open
    title: "Replay confirmation does not handle transient failures in its fresh reads"
  - id: WR-04
    severity: warning
    disposition: open
    title: "Cached health counts can be shown for a different selected interval"
open: 6
total: 6
recorded: 2026-10-08T17:15:36.098Z
---

# Phase 168: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| CR-01 | critical | open | - |
| CR-02 | critical | open | - |
| WR-01 | warning | open | - |
| WR-02 | warning | open | - |
| WR-03 | warning | open | - |
| WR-04 | warning | open | - |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
