---
phase: 177
review: 177-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: fixed
    title: "Single-option Account control renders a fake \"selected\" identity and removes the only way to switch"
  - id: IN-01
    severity: info
    disposition: fixed
    title: "Invalid HTML content model in the observation group"
  - id: IN-02
    severity: info
    disposition: fixed
    title: "Scope group accessible name absorbs the sr-only Account id"
  - id: IN-03
    severity: info
    disposition: fixed
    title: "Header `aria-describedby` can reference an empty description"
  - id: IN-04
    severity: info
    disposition: fixed
    title: "Operator Account control does not trim whitespace-only Account ids"
open: 0
total: 5
recorded: 2026-10-29T02:26:51.987Z
---

# Phase 177: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | fixed | 177-REVIEW-FIX.md |
| IN-01 | info | fixed | 177-REVIEW-FIX.md |
| IN-02 | info | fixed | 177-REVIEW-FIX.md |
| IN-03 | info | fixed | 177-REVIEW-FIX.md |
| IN-04 | info | fixed | 177-REVIEW-FIX.md |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
