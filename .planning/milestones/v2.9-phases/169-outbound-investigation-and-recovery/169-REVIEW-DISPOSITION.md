---
phase: 169
review: 169-REVIEW.md
titles: json
findings:
  - id: CR-01
    severity: critical
    disposition: fixed
    title: "Exact support IDs can be presented as the wrong evidence population"
  - id: WR-01
    severity: warning
    disposition: fixed
    title: "A changed replay target cannot be refreshed from the rejection flow"
open: 0
total: 2
recorded: 2026-10-08T03:38:46.839Z
---

# Phase 169: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| CR-01 | critical | fixed | 169-REVIEW-FIX.md (not in the current review) |
| WR-01 | warning | fixed | 169-REVIEW-FIX.md (not in the current review) |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
