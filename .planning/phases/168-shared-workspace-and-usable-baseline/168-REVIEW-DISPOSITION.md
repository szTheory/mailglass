---
phase: "168"
review: 168-REVIEW.md
titles: json
findings:
  - id: CR-01
    severity: critical
    disposition: skipped
    title: "URL Account selection bypasses the server-side permitted-account set"
    source: "Owner confirmed global operator access on 2026-10-08; stable trust contract and Phase 168 threat register now state the policy."
  - id: WR-01
    severity: warning
    disposition: open
    title: "Malformed support evidence IDs crash the operator page"
  - id: WR-02
    severity: warning
    disposition: open
    title: "Resend replay evidence omits its provider label"
open: 2
total: 3
recorded: "2026-10-08"
---

# Phase 168: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| CR-01 | critical | skipped | Owner confirmed global operator access on 2026-10-08; see operator-trust.md and 168-SECURITY.md |
| WR-01 | warning | open | Untriaged; see 168-REVIEW.md |
| WR-02 | warning | open | Untriaged; see 168-REVIEW.md |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
