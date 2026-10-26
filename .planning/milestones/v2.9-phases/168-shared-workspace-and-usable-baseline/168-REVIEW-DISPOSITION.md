---
phase: 168
review: 168-REVIEW.md
titles: json
findings:
  - id: CR-01
    severity: critical
    disposition: fixed
    title: "Delivery badges show the stored snapshot instead of the latest outcome"
  - id: CR-02
    severity: critical
    disposition: fixed
    title: "Transient reads can display cached support evidence from another Account"
  - id: WR-01
    severity: warning
    disposition: deferred
    title: "Malformed exact-support IDs crash the LiveView"
  - id: WR-02
    severity: warning
    disposition: fixed
    title: "Preview success flash cannot be dismissed"
  - id: WR-03
    severity: warning
    disposition: fixed
    title: "Replay confirmation does not handle transient failures in its fresh reads"
  - id: WR-04
    severity: warning
    disposition: fixed
    title: "Cached health counts can be shown for a different selected interval"
open: 0
total: 7
recorded: 2026-10-09T00:15:20Z
---

# Phase 168: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| CR-01 | critical | fixed | 168-06 rendered outcome regressions and passing ExUnit coverage (not in the current review) |
| CR-02 | critical | fixed | 168-07 account-scope fallback regression and passing ExUnit coverage (not in the current review) |
| WR-01 | warning | deferred | Introduced by Phase 169 Plan 02; retain as follow-up for exact-support UUID validation, outside Phase 168 scope (not in the current review) |
| WR-02 | warning | fixed | 168-08 actual LiveView dismissal regression and passing ExUnit coverage (not in the current review) |
| WR-03 | warning | fixed | 168-07 transient replay-read regressions and passing ExUnit coverage (not in the current review) |
| WR-04 | warning | fixed | 168-07 interval-scope regression and passing ExUnit coverage (not in the current review) |
| IN-01 | info | skipped | Gallery-only denied specimen: `can_reveal?` is unused and the reveal affordance remains visible, but the LiveView event enforces server-side authorization. This presentation mismatch is outside the 4px spacing correction and creates no data-access path; retain as a separate product follow-up only if gallery affordance semantics become in-scope. |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.

The Plan 10 spacing warnings WR-01, WR-02, and WR-03 were fixed by `5c6daebd`, `7633d7dc`, and `f92542e4`; the current review has no critical or warning findings. IN-01 is informational and explicitly skipped from this spacing follow-up. The deferred `WR-01` above is the distinct Phase 169 exact-support UUID issue.
