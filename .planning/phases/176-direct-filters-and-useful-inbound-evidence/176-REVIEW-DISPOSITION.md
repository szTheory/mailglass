---
phase: 176
review: 176-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: fixed
    title: "Payload size and revealed raw source describe different stored fields"
  - id: WR-02
    severity: warning
    disposition: fixed
    title: "Auto-applied time window can remove the Operator filter toolbar (focus lost, no way back)"
  - id: WR-03
    severity: warning
    disposition: fixed
    title: "Reveal denial is placed in a freshly inserted live region and likely not announced"
  - id: WR-04
    severity: warning
    disposition: fixed
    title: "Contact addresses are hidden from assistive technology by the copy button's `aria-label`"
  - id: WR-05
    severity: warning
    disposition: fixed
    title: "Invalid enum from the URL leaves its select contradicting its error (D-12)"
  - id: WR-06
    severity: warning
    disposition: fixed
    title: "URL-invalid results lose their \"filter excluded\" label after any edit or reconnect (D-13)"
  - id: WR-07
    severity: warning
    disposition: fixed
    title: "Operator status region announces on background PubSub refreshes (D-16)"
  - id: WR-08
    severity: warning
    disposition: deferred
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
    disposition: fixed
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
    disposition: fixed
    title: "Operator renders a \"Custom period ( hours)\" option for a blank URL window"
  - id: GR-WR-01
    severity: warning
    disposition: open
    title: "Frozen Operator status region contradicts the list after a background refresh that changes the read state (176-13 WR-07 fix)"
  - id: GR-IN-01
    severity: info
    disposition: open
    title: "`filter_error_source` can no longer be `:url`, so the assignment is dead state"
  - id: GR-IN-02
    severity: info
    disposition: open
    title: "\"Payload size\" now reports the pretty-printed re-encoding, not the stored payload"
  - id: GR-IN-03
    severity: info
    disposition: open
    title: "`nothing_stored?/1` reports \"was not stored\" for a stored value of an unexpected shape"
  - id: GR-IN-04
    severity: info
    disposition: open
    title: "New browser specs add fixed sleeps and a race-prone connectivity check"
open: 10
total: 20
recorded: 2026-10-28T16:36:37.161Z
---

# Phase 176: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | fixed | 176-11 (raw_source/1 selector) |
| WR-02 | warning | fixed | 176-13 (non_default_window?/1 in filters_active?/1) |
| WR-03 | warning | fixed | 176-11 (denial in persistent status region) |
| WR-04 | warning | fixed | 176-12 (copy_value aria-label names the value) |
| WR-05 | warning | fixed | 176-15 (Not applied option keeps the rejected value) |
| WR-06 | warning | fixed | 176-15 (filter_url_invalid keeps the URL note) |
| WR-07 | warning | fixed | 176-13 (PubSub refresh keeps status text) |
| WR-08 | warning | deferred | advisory browser lane under D-29, not merge-blocking |
| IN-01 | info | open | - |
| IN-02 | info | open | - |
| IN-03 | info | open | - |
| IN-04 | info | fixed | 176-11 (no reveal control when nothing is stored) |
| IN-05 | info | open | - |
| IN-06 | info | open | - |
| IN-07 | info | fixed | 176-13 (blank window normalizes quietly) |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.

## Gap-round re-review (176-REVIEW.md, base d9418fca)

The gap-round review reused finding IDs WR-01 and IN-01..04 for different findings. They are recorded here with a `GR-` prefix so the decisions above (several marked `fixed`) are not overwritten. The original findings are in git history at d9418fca.

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| GR-WR-01 | warning | open | - |
| GR-IN-01 | info | open | - |
| GR-IN-02 | info | open | - |
| GR-IN-03 | info | open | - |
| GR-IN-04 | info | open | - |

## UI review warnings (176-UI-REVIEW.md)

These rows disposition WARNING-level items from 176-UI-REVIEW.md. They are not REVIEW.md findings, so they stay out of the frontmatter `findings` list and the `open:` and `total:` counts.

WARNING-level items this gap round fixes in code are not repeated here: Top Fix 1 (the BLOCKER, 176-13-02 class toggle) and Top Fix 3 (blank window, 176-13-03 / IN-07). INFO-level items are not dispositioned.

| Warning | Disposition | Reason |
|---------|-------------|--------|
| UI-TF2 Retry and empty-state focus rings clipped; Clear, toggles and Retry lack mg-focus-ring (Top Fix 2; Pillar 3) | deferred | Focus-ring polish outside this gap round's verification gaps (SC1, SC4, SC5). No locked decision requires it. The controls stay keyboard-reachable with the daisyUI default ring, and the UI-SPEC's own Clear and Retry class lists omit mg-focus-ring. |
| UI-TF4 Subject-less Quick view shows the envelope recipient only as an unlabelled heading (Top Fix 4) | deferred | With no subject, message_identity uses the envelope recipient as the heading text (components.ex:572) and skips the labelled recipient line, which is gated on a subject (components.ex:576). The Quick view therefore shows the value unlabelled and without a copy control. Identity-line layout is outside this gap round's verification gaps (SC1, SC4, SC5). The full-detail header still shows the recipient labelled and copyable in the Delivered to row (INUX-05, 176-12), so its duplicate identity line is cosmetic. |
| UI-TF5 Critical axe aria-allowed-attr finding: aria-selected on row buttons (Top Fix 5; deliveries_list.ex:199,263) | deferred | Pre-existing since Phase 113, not introduced by Phase 176. 176-10 compared axe results against a baseline that already contains it (no new violations), and deferred-items.md records it. Removing it changes coupled specs outside this gap round. |
| UI-HELP-TARGET Field-help triggers are 24px (h-6 w-6, components.ex:1123) against the UI-SPEC 44px rule (Pillar 6) | deferred | The triggers meet WCAG 2.2 AA 2.5.8 (24px minimum). The deviation is only from the phase contract's stricter 44px rule, and it is outside the verification gaps. |
| UI-TOGGLE-HEIGHT Mobile Filters toggles fixed at !h-11 (operator_live.ex:951, inbound_live.ex:731) may clip a wrapped label at 200% zoom (Pillar 6) | deferred | Static inference, unverified in a browser. The advisory case "the mobile Filters toggle reaches 44px and does not clip at 200% zoom" (phase176-filters.spec.js) re-runs in gate 7 with its result recorded. Not part of the verification gaps. |
| UI-STALE-TITLE Stale title appends UTC and an invented "Showing earlier results; refresh failed" fallback (results_status.ex:38,40; Pillar 1) | deferred | Recorded as an execution-time orchestrator decision (UI-REVIEW cites decision 3); the UI-SPEC stale-title row is not amended in this gap round. Outside the verification gaps. |
| UI-STALE-REPEAT Stale panel states the load time twice (deliveries_list.ex:66-72, records_list.ex:76-82; Pillar 1) | deferred | Copy redundancy, not a truth defect; outside the verification gaps. |
| UI-SPACING-GAP2 Deliveries Clear wrapper uses raw gap-2 where Inbound uses gap-sm (operator_live.ex:978; Pillar 5) | deferred | Pre-existing markup, not touched by the 176-13 edits to operator_live.ex. Spacing polish outside the verification gaps. |
| UI-WINDOW-NOTE Window invalid note reads "Showing results for the default time window instead." where the approved row 112 text is "Showing results without the {Field} filter." (Pillar 1) | reconciled | 176-15-02 amends UI-SPEC row 112 to the shipped window copy: an invalid window falls back to the default rather than being dropped, and the note says so. No code change. |
