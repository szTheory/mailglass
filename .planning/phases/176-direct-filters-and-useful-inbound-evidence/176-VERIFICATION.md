---
phase: 176-direct-filters-and-useful-inbound-evidence
verified: 2026-10-28T18:00:00Z
status: passed
score: 5/5 must-haves verified
covered_files:
  - .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-01-PLAN.md
  - .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-01-SUMMARY.md
  - .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-02-PLAN.md
  - .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-02-SUMMARY.md
  - .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-03-PLAN.md
  - .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-03-SUMMARY.md
  - .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-04-PLAN.md
  - .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-04-SUMMARY.md
  - .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-05-PLAN.md
  - .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-05-SUMMARY.md
  - .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-06-PLAN.md
  - .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-06-SUMMARY.md
  - .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-07-PLAN.md
  - .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-07-SUMMARY.md
  - .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-08-PLAN.md
  - .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-08-SUMMARY.md
  - .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-09-PLAN.md
  - .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-09-SUMMARY.md
  - .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-10-PLAN.md
  - .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-10-SUMMARY.md
  - .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-11-PLAN.md
  - .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-11-SUMMARY.md
  - .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-12-PLAN.md
  - .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-12-SUMMARY.md
  - .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-13-PLAN.md
  - .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-13-SUMMARY.md
  - .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-14-PLAN.md
  - .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-14-SUMMARY.md
  - .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-15-PLAN.md
  - .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-15-SUMMARY.md
  - mailglass_admin/lib/mailglass_admin/components.ex
  - mailglass_admin/lib/mailglass_admin/inbound/address_list.ex
  - mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex
  - mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex
  - mailglass_admin/lib/mailglass_admin/inbound/filters_form.ex
  - mailglass_admin/lib/mailglass_admin/inbound/records_list.ex
  - mailglass_admin/lib/mailglass_admin/inbound_live.ex
  - mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex
  - mailglass_admin/lib/mailglass_admin/operator/filter_commit.ex
  - mailglass_admin/lib/mailglass_admin/operator/filters_form.ex
  - mailglass_admin/lib/mailglass_admin/operator/results_status.ex
  - mailglass_admin/lib/mailglass_admin/operator_live.ex
  - mailglass_admin/priv/static/hooks.js
  - mailglass_admin/test/mailglass_admin/phase176_prohibition_contract_test.exs
covered_digest: "v4:sha256:0b8bf3a7df87702b51c9510d74c904c68bf8abc98cb4d5a292626c3b2bfbdc12"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 3/5
  gaps_closed:
    - "SC5 / INUX-06: Payload size and revealed raw source describe the same stored field"
    - "SC4 / INUX-05: Contact addresses are part of the copy control's accessible name"
    - "SC1 / FILTER-01: A non-default time window keeps the Deliveries toolbar"
    - "SC1 / FILTER-01 (mobile): Deliveries filter panel survives a mobile close at desktop width"
  gaps_remaining: []
  regressions: []
advisory:
  - finding: "GR-WR-01: the sr-only Deliveries status region is frozen on a PubSub refresh even when the read state changes (ready to stale/error, error/stale to ready, empty to non-empty)"
    category: other
    reason: "Visible results and visible stale/error/empty panels are driven by read state and stay truthful; only the assistive-technology-only announcement text lags. No stated success criterion requires announcing another actor's activity (D-16 forbids it). Follow-up: freeze the text only when the settled state class is unchanged."
    evidence_status: "code-read of operator_live.ex refresh_visible_state/1 and assign_delivery_state/5; no failing criterion"
---

# Phase 176: Direct Filters and Useful Inbound Evidence Verification Report

**Phase Goal:** Operators can find records directly in either collection and inspect useful ordinary Inbound contact/raw-source evidence while URL, Account and private-disclosure contracts remain truthful.
**Verified:** 2026-10-28
**Status:** passed
**Re-verification:** Yes, after gap-closure plans 176-11..15. Previous status `gaps_found` (3/5).

## Goal Achievement

All four gaps recorded by the initial verification are closed in source, each with a regression test and a mutation-proven contract describe (P9..P13). SC2 and SC3 were re-checked for regressions and still hold. The one new review finding (GR-WR-01) is judged advisory and does not break any stated criterion (see below).

### Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Select filters commit immediately, search debounced, no Apply, Enter commits, results follow canonical URL (FILTER-01, FILTER-02) | VERIFIED | `phx-debounce="300"` on search only; no Apply/submit control (P1 contract). Previously failing paths now closed: `filters_active?/1` (`operator_live.ex:1328-1332`) ORs in `non_default_window?/1` (`:1299`), so an empty narrower window keeps the toolbar and renders the filtered-empty pane (P11, both commit and URL paths); toggle is `JS.toggle_class("mg-inbound-filters-open", to: "#operator-filter-panel")` (`operator_live.ex:951`), no inline display written (P12, asserts a `toggle_class` op and no style); the class is defined in source `assets/css/app.css:375` and the committed `priv/static/app.css`. Browser spec "filter panel is visible at desktop width after a mobile close" exists for both collections and passed in the orchestrator gate (Playwright 31 passed). |
| 2 | Back/Forward, Clear during debounce, rapid edits, reconnect, page reset, pagination preserve filters; history not flooded; Account/selection isolation (FILTER-03) | VERIFIED (no regression) | `FilterCommit`, `replace: true` canonicalization and `FilterSearchSync` unchanged by the gap round except for the additive `non_default_window?` and class toggle; full LiveView suites pass (below); connected browser specs pass in the orchestrator gate. |
| 3 | Invalid input keeps visible draft/error and identifiable committed results; failed reads show error/stale/unavailable with no silent fallback or misleading empty population (FILTER-04) | VERIFIED (strengthened) | P7 (failed new-query read: no count, no empty copy) and P8 (URL-invalid filter labelled) still pass; 176-15 adds P13 (URL-invalid note survives a later Search edit and a reconnect, on both collections) and the "Not applied" option so a rejected enum value is still shown beside its error. Read states `:stale`/`:error` come from `assign_delivery_state/5` (`operator_live.ex:1705-1716`): same-query failure keeps prior rows under the stale panel, a first-query failure shows the error panel with no rows. GR-WR-01 does not weaken this (see judgment). |
| 4 | Ordinary authorized Inbound contacts show complete addresses (long/Unicode/missing/multiple); envelope vs header distinct; diagnostics/raw/telemetry protections intact (INUX-05) | VERIFIED | `Components.copy_value/1` now `aria-label={"Copy #{@label}: #{@value}"}` (`components.ex:1609-1625`), so the visible address is in the accessible name (WCAG 2.5.3). `inbound/components_test.exs:661-668` asserts every contact button's name is `"Copy " <> label <> ": " <> value`, including the Unicode address `用户@例子.广告`; `components_test.exs:605,615` pin the Delivery ID and To-address names. P10 live tests seed From/To/Cc/envelope and assert all four values are present and `copy_name_violations/1 == []`. P2/P3/P4/P5 (masked routing trace, envelope vs header, no raw bytes in redacted/denied HTML, PII-free telemetry) still pass. |
| 5 | Raw provider source groups heading/reveal/privacy and compact facts; permitted/denied reveal and unavailable evidence truthful; retained scenarios reproduce layouts (INUX-06) | VERIFIED | One selector `raw_source/1` (`evidence_card.ex:177-189`) drives both `payload_byte_size/1` and `raw_payload_text/1`; precedence payload map then raw_mime, matching the pre-phase reveal order so revealed bytes are unchanged (D-27). `evidence_card_test.exs:241-262` stores BOTH fields (the exact case the first verification found untested) and asserts the size equals `byte_size` of the revealed text and that the raw_mime marker is not shown. P9 repeats this at component level (including a >1.7 KB payload) and on a live authorized reveal of a record seeded with both fields. Denial is announced from the persistent `role="status"` region (`evidence_card.ex:133-146`), and a record with nothing stored shows only the static "was not stored" sentence with no reveal control (IN-04). Unknown size/headers render "Unavailable", never 0 (P6). |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

### Judgment: GR-WR-01 (frozen Operator status region after a background refresh)

Mechanism confirmed in source: `refresh_visible_state/1` (`operator_live.ex:1230-1244`) re-runs `assign_delivery_state/5` and then restores the previous `results_status_text` unconditionally. The review's three scenarios are real: ready to stale/error, error/stale to ready, and empty to non-empty on a PubSub `:delivery_updated`.

Why it does not break a success criterion:

- The status region is `class="sr-only"` (`operator_live.ex:809-821`). It is a supplementary announcement channel; the authoritative UI is the visible list and the stale/error/empty panels, which render from `deliveries_read_state` and the row data, not from `results_status_text`. After a background refresh, rows, stale panel (with "Results loaded ..." time and Retry), error panel and empty pane are all current and truthful. SC3 / FILTER-04 require "truthful error/stale/unavailable feedback" and "no silent fallback queries or misleading empty populations": a failed refresh keeps the prior rows under the stale panel (`operator_live.ex:1710-1712`), no fallback query runs, and the visible empty state is not misrepresented.
- The freeze is the intended D-16 behavior: the polite region speaks after a commit or Retry, never on another actor's background activity. The ready-to-ready case (the common one) is correct and tested. The ready-to-stale case is also self-consistent for AT: the retained text describes the stale rows still on screen.
- The incongruent cases (error to ready, empty to non-empty) require a PubSub-driven state recovery with an AT user reading the region by navigation rather than the page. That is a real polish defect but a narrow one, and no truth in the ROADMAP contract mentions announcing background refreshes.

Verdict: advisory (recorded in `advisory:` frontmatter), not a gap and not a human-verification item. Suggested follow-up: freeze the text only when the settled state class (ready/stale/error, empty vs non-empty) is unchanged, with tests for ready-to-stale and error-to-ready. Other open info items (GR-IN-01..04, IN-01/02/03/05/06, deferred WR-08) are quality notes with no criterion impact; GR-IN-02 ("Payload size" measures the pretty-printed text) is consistent with the revealed bytes and is documented in the function comment.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `operator/filter_commit.ex`, `operator/results_status.ex` | Commit/history policy; persistent status text | VERIFIED | Wired in both LiveViews. |
| `inbound/address_list.ex`, `inbound/detail_header.ex` | Dedupe, split, spoof cue, complete addresses | VERIFIED | Wired; contact buttons carry value-bearing names. |
| `inbound/evidence_card.ex` | Single-disclosure card, five facts, one source selector | VERIFIED | `raw_source/1` shared by size and reveal. |
| `components.ex` `copy_value/1` | Copy control with value in accessible name | VERIFIED | `components.ex:1620`. |
| `operator_live.ex` | Window-aware `filters_active?`, class toggle | VERIFIED | `:1328`, `:951`. |
| `priv/static/hooks.js`, `priv/static/app.css` | Committed bundles | VERIFIED | hooks.js present; `.mg-inbound-filters-open` in committed app.css; no uncommitted changes under `mailglass_admin`. |
| `phase176_prohibition_contract_test.exs` | Mutation-proven must-NOT contracts | VERIFIED | P1..P13 plus a "detectors have teeth" describe; passes. |

### Key Link Verification

| From | To | Via | Status |
|------|----|-----|--------|
| Filter form `phx-change` | `FilterCommit.commit_params/2` then `push_patch` | `commit_filters/3` | WIRED |
| `handle_params` | Read + `ResultsStatus.text/1` | `assign_delivery_state/5` | WIRED |
| Mobile toggle | `#operator-filter-panel` class `mg-inbound-filters-open` | `JS.toggle_class` | WIRED |
| Contact entries | `copy_value/1` accessible name | `aria-label` includes `@value` | WIRED |
| `payload_byte_size/1` and `raw_payload_text/1` | `raw_source/1` | shared selector | WIRED |
| Reveal button | `reveal_raw` auth at action time | `inbound_live.ex` | WIRED, unchanged |

### Data-Flow Trace (Level 4)

| Artifact | Variable | Source | Real data | Status |
|----------|----------|--------|-----------|--------|
| Contact rows | `from/to/cc/reply_to` | `InboundRecord` via read model | Yes | FLOWING |
| Evidence facts | `raw_payload`/`raw_mime`/`raw_headers` | `InboundEvidence` | Yes, P9 live reveal seeds both fields | FLOWING |
| Deliveries/Inbound lists | rows, `total_count` | Tenant-scoped reads | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Contract, evidence card, components (both), Operator and Inbound LiveViews | `cd mailglass_admin && mix test --seed 0 test/mailglass_admin/phase176_prohibition_contract_test.exs test/mailglass_admin/inbound/evidence_card_test.exs test/mailglass_admin/inbound/components_test.exs test/mailglass_admin/components_test.exs test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs` | 526 tests, 0 failures (logged error is an injected read-fault test) | PASS |
| Orchestrator post-merge gate at HEAD (not re-run by verifier) | `scripts/gsd-regression-gate.sh` | exit 0: core 81/0, admin 878/0, inbound 480/0, Playwright 31 passed, node storybook tests pass | reported |

### Probe Execution

SKIPPED: the phase declares no probe scripts.

### Requirements Coverage

| Requirement | Source Plans | Status | Evidence |
|-------------|--------------|--------|----------|
| FILTER-01 | 01, 07, 10, 13 | SATISFIED | Auto-apply on both; window toolbar trap and mobile strand closed (P11, P12). |
| FILTER-02 | 01, 06, 07, 10 | SATISFIED | Debounce 300 ms on search only; Enter commits; Back focus hook. |
| FILTER-03 | 01, 06, 07, 10 | SATISFIED | History policy, `replace: true`, page/selection drop, server-held tenant. |
| FILTER-04 | 04, 07, 09, 10, 13, 15 | SATISFIED | P7, P8, P13, "Not applied" option; read-state-driven visible feedback. GR-WR-01 advisory only. |
| INUX-05 | 02, 08, 10, 12 | SATISFIED | Complete addresses visually, by data and in the accessible name (P10). |
| INUX-06 | 03, 05, 08, 10, 11 | SATISFIED | One source selector (P9); denial announced from persistent region; unavailable never zero. |

All six IDs appear in plan frontmatter and in REQUIREMENTS.md; none orphaned. Note for the orchestrator: REQUIREMENTS.md still shows the six checkboxes unticked and the traceability table "Gaps Found" for FILTER-01..04, INUX-05, INUX-06. Per instructions the verifier did not edit it; it should move to Complete now that status is `passed`.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `operator_live.ex` | 1230-1244 | Unconditional status-text freeze on PubSub refresh | Advisory (GR-WR-01) | AT-only text can lag a background state change |
| `operator_live.ex`, `inbound_live.ex` | 192, 225 | `filter_error_source` can no longer be `:url` | Info (GR-IN-01) | Dead state |
| Debt markers | n/a | No TBD/FIXME/XXX in changed implementation files | None | n/a |

### Human Verification Required

None. Per D-52 every item above is machine-observable and was either verified by automated test or recorded as an advisory. Brand/visual identity, secrets and physical devices are not involved in this phase's criteria.

### Gaps Summary

No gaps. Previous gaps (SC5 size/reveal source, SC4 accessible name, SC1 window toolbar trap, SC1 mobile toggle) are closed with tests and mutation-proven contracts. Recommended non-blocking follow-ups: GR-WR-01 (conditional status-text freeze), then the remaining open info items.

---

_Verified: 2026-10-28_
_Verifier: Claude (gsd-verifier)_
