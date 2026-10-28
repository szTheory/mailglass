---
phase: 176
review: 176-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: open
    title: "Payload size and revealed raw source describe different stored fields"
  - id: WR-02
    severity: warning
    disposition: open
    title: "Auto-applied time window can remove the Operator filter toolbar (focus lost, no way back)"
  - id: WR-03
    severity: warning
    disposition: open
    title: "Reveal denial is placed in a freshly inserted live region and likely not announced"
  - id: WR-04
    severity: warning
    disposition: open
    title: "Contact addresses are hidden from assistive technology by the copy button's `aria-label`"
  - id: WR-05
    severity: warning
    disposition: open
    title: "Invalid enum from the URL leaves its select contradicting its error (D-12)"
  - id: WR-06
    severity: warning
    disposition: open
    title: "URL-invalid results lose their \"filter excluded\" label after any edit or reconnect (D-13)"
  - id: WR-07
    severity: warning
    disposition: open
    title: "Operator status region announces on background PubSub refreshes (D-16)"
  - id: WR-08
    severity: warning
    disposition: open
    title: "Browser specs assert a 250 ms wall-clock bound (flaky)"
  - id: IN-01
    severity: info
    disposition: open
    title: "`commit_params/2` doc says the draft stays untrimmed, but the draft is built from the trimmed params"
  - id: IN-02
    severity: info
    disposition: open
    title: "Spoof cue fires on a local-part case difference only"
  - id: IN-03
    severity: info
    disposition: open
    title: "RFC 5322 quoted local parts are labeled \"Unparseable address\""
  - id: IN-04
    severity: info
    disposition: open
    title: "Reveal says \"Provider sent an empty payload.\" when the payload is unknown, not empty"
  - id: IN-05
    severity: info
    disposition: open
    title: "Inbound status region holds a no-data claim before any read"
  - id: IN-06
    severity: info
    disposition: open
    title: "`FilterSearchSync` loses the Back sync when a round trip exceeds 1.5 s"
  - id: IN-07
    severity: info
    disposition: open
    title: "Operator renders a \"Custom period ( hours)\" option for a blank URL window"
open: 15
total: 15
recorded: 2026-10-28T16:36:37.161Z
---

# Phase 176: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | open | - |
| WR-02 | warning | open | - |
| WR-03 | warning | open | - |
| WR-04 | warning | open | - |
| WR-05 | warning | open | - |
| WR-06 | warning | open | - |
| WR-07 | warning | open | - |
| WR-08 | warning | open | - |
| IN-01 | info | open | - |
| IN-02 | info | open | - |
| IN-03 | info | open | - |
| IN-04 | info | open | - |
| IN-05 | info | open | - |
| IN-06 | info | open | - |
| IN-07 | info | open | - |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
