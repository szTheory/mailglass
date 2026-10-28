---
phase: 176-direct-filters-and-useful-inbound-evidence
verified: 2026-10-28T17:00:00Z
status: gaps_found
score: 3/5 must-haves verified
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
  - mailglass_admin/lib/mailglass_admin/components.ex
  - mailglass_admin/lib/mailglass_admin/gallery_live.ex
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
covered_digest: "v4:sha256:80a8f553f79a6ea5f105fa6c6e249c53ab3e9aa16cb790363371c66f936478ec"
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "SC5 / INUX-06: Raw provider source facts are truthful and consistent with what the reveal shows (D-26 truth fixes)"
    status: partial
    reason: "Payload size reads raw_mime first, but the revealed <pre> renders raw_payload first. SES persists both (mailglass_inbound ses.ex:118-120), so the card states the byte size of one stored field and then reveals a different one. Phase regression: before 176 both used raw_payload first. The only new test feeds raw_mime with raw_payload %{}, so the suite never sees both set."
    artifacts:
      - path: "mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex"
        issue: "payload_byte_size/1 (lines 166-183) is raw_mime-first; raw_payload_text/1 (lines 205-212) is raw_payload-first"
    missing:
      - "One shared source selector used by both payload_byte_size/1 and raw_payload_text/1"
      - "Test with raw_mime AND raw_payload both non-empty asserting the size equals the byte size of the text actually revealed (or an explicit documented label for which field is measured)"
  - truth: "SC4 / INUX-05: An authorized operator can read complete ordinary Inbound sender/recipient addresses"
    status: partial
    reason: "Every From/Reply-To/To/Cc/Delivered-to address and unparseable original is rendered only through Components.copy_value, whose aria-label (\"Copy <label>\") replaces the visible address as the accessible name. Screen-reader users hear \"Copy To address, button\" per recipient and never the address (WCAG 2.5.3 Label in Name, level A). The display name is a plain span, so only the address itself is hidden."
    artifacts:
      - path: "mailglass_admin/lib/mailglass_admin/components.ex"
        issue: "copy_value/1 line 1605: aria-label={\"Copy \" <> @label} drops @value from the accessible name"
      - path: "mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex"
        issue: "lines 96-100, 223, 232 use copy_value as the sole address presentation"
    missing:
      - "Accessible name that contains the address, e.g. aria-label={\"Copy #{@label}: #{@value}\"} (or sr-only prefix text)"
      - "Test asserting the address text is part of the accessible name of each contact button"
  - truth: "SC1 / FILTER-01: Select filters commit immediately on Deliveries and the operator keeps a way to change them"
    status: partial
    reason: "Operator filters_active?/1 ignores window_hours, so choosing a narrower time window that has no deliveries commits immediately and renders the genuine no-data pane, which withholds the whole filter toolbar. Focus falls to <body> and the only recovery is browser Back. Inbound counts a non-default window (inbound_live.ex:1495-1501) and does not trap. The condition predates the phase, but auto-apply turns it into a one-change trap and the phase owns the select-commit path; the empty pane also claims no data when data exists outside the window."
    artifacts:
      - path: "mailglass_admin/lib/mailglass_admin/operator_live.ex"
        issue: "lines 821-823 branch on not filters_active?(@filter_params); lines 1308-1311 filters_active?/1 drops window_hours"
    missing:
      - "Count a non-default window_hours as an active filter (match Inbound)"
      - "LiveView test: select window_hours=24 where deliveries exist only outside it, assert #operator-filters still renders"
  - truth: "SC1 / FILTER-01 (mobile): Deliveries filter panel remains usable across viewport widths"
    status: partial
    reason: "Deliveries mobile toggle uses JS.toggle (inline display:none) on a panel classed hidden md:block. Closing the panel on a narrow viewport leaves inline display:none that md:block cannot override, and the toggle is md:hidden, so at >=768px the filters are gone with no control until reload. Inbound already uses JS.toggle_class(\"mg-inbound-filters-open\") with a CSS comment documenting exactly this failure. Origin is Phase 98 (not introduced by 176), but plan 176-01 task 3 rewired this toggle (added aria-controls/aria-expanded via toggle_attribute) and kept JS.toggle. Verified in source."
    artifacts:
      - path: "mailglass_admin/lib/mailglass_admin/operator_live.ex"
        issue: "lines 944-947 JS.toggle(to: \"#operator-filter-panel\"); line 960 class=\"hidden md:block\""
    missing:
      - "Use JS.toggle_class(\"mg-inbound-filters-open\", to: \"#operator-filter-panel\") (class already ships in the committed bundle; no CSS change)"
      - "Browser or LiveView-level assertion that the panel is visible at desktop width after a toggle-close on mobile"
---

# Phase 176: Direct Filters and Useful Inbound Evidence Verification Report

**Phase Goal:** Operators can find records directly in either collection and inspect useful ordinary Inbound contact/raw-source evidence while URL, Account and private-disclosure contracts remain truthful.
**Verified:** 2026-10-28
**Status:** gaps_found
**Re-verification:** No, initial verification

## Goal Achievement

The core mechanism is real and wired: both collections auto-apply selects, debounce search (300 ms, search input only), have no Apply control, commit through `FilterCommit` (server-held Account, page/selection dropped, canonical sorted query), and patch Account canonicalization with `replace: true`. The contract tests have teeth. Five defects remain that make a success criterion untrue in a specific, source-verified state. Each fix is small and local.

### Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Select filters commit immediately, search is debounced, no Apply, Enter commits, results follow canonical URL (FILTER-01, FILTER-02) | PARTIAL (gaps below) | `phx-debounce="300"` on search only (`operator/filters_form.ex:33`, `inbound/filters_form.ex:38`); no Apply/submit/disable-with in either form (P1 contract tests pass); `FilterCommit` in `operator/filter_commit.ex`; `FilterSearchSync` hook in committed `priv/static/hooks.js`. Defects: Deliveries window select can remove the toolbar (WR-02); Deliveries mobile toggle can strand filters at desktop width. |
| 2 | Back/Forward, Clear during debounce, rapid edits, reconnect, page reset, pagination preserve filters; history not flooded; Account/selection isolation (FILTER-03) | VERIFIED | `history_kind/2` pure policy (unit-tested); `replace: true` at `operator_live.ex:237`, `inbound_live.ex:531`; `commit_params/2` drops `page`, `delivery_id`, `inbound_id`, `full` and takes `tenant_id` only from the server; `filters_tenant_id` absent; 73 targeted + 331 LiveView tests pass at `--seed 0`. |
| 3 | Invalid input keeps visible draft/error and identifiable committed results; failed reads show error/stale/unavailable, no silent fallback, no misleading empty population (FILTER-04) | VERIFIED | Draft vs committed split with `filter_error_source`; P7 (failed new-query read: no count, no empty copy) and P8 (URL-invalid filter labelled as excluded) contract tests pass on both collections; Retry is patch-free. Residual rough edges are advisory (WR-05, WR-06, IN-07). |
| 4 | Ordinary authorized Inbound contacts show complete addresses (long/Unicode/missing/multiple), envelope vs header distinct, diagnostics/raw/telemetry protections intact (INUX-05) | PARTIAL (gap) | `detail_header.ex` `<dl>` order From, Reply-To, To, Cc, Delivered to; P3 binds "Delivered to" to `envelope_recipient` and "To" to header `to`; `mask_recipient/1`/`mask_value/1` kept and routing trace still masked (P2). Defect: addresses are not exposed to assistive technology (WR-04). |
| 5 | Raw provider source groups heading/reveal/privacy and compact facts; permitted/denied reveal and unavailable evidence truthful; retained scenarios reproduce layouts (INUX-06) | PARTIAL (gap) | One header group, one persistent disclosure (`aria-expanded`/`aria-controls`), five-fact `<dl>`, nil-not-zero (P6), denied path leaks no sentinel bytes (P4), telemetry PII-free (P5). Defect: size and revealed bytes can describe different stored fields (WR-01). |

**Score:** 3/5 truths verified (SC2, SC3 fully; SC1, SC4, SC5 partial)

### Adjudication of review findings

| Finding | Verdict | Source evidence |
|---------|---------|-----------------|
| REVIEW WR-01 | GAP (phase regression) | `evidence_card.ex:166-183` size is raw_mime-first; `:205-212` reveal is raw_payload-first; pre-phase (`c96c8a4f`) both were raw_payload-first. SES stores both (`mailglass_inbound/.../ses.ex:118-120`). |
| REVIEW WR-02 | GAP | `operator_live.ex:821-823`, `:1308-1311`; Inbound counts window (`inbound_live.ex:1495-1501`). Default window is 168 h, so any narrower option with no recent traffic triggers it. |
| REVIEW WR-03 | Advisory (D-26 wording deviation) | Pre-phase denial was a plain `<p>` (never announced). Phase added `role="status"` to the inserted denial paragraph (`evidence_card.ex:133-140`); the persistent region still reads "Raw source hidden." for `:denied` (`:249-250`). Visible text is truthful; announcement reliability is imperfect. Recommend using the persistent region as D-26 states. |
| REVIEW WR-04 | GAP | `components.ex:1605` aria-label replaces the address; sole address presentation in `detail_header.ex`. |
| REVIEW WR-05 | Advisory | Enum select shows the prompt ("Any outcome"/"Any status") beside "was not applied". That agrees with the effective filter (none applied); the next edit posting `""` clears an already-ignored value, so results do not change. Cosmetic against D-12's wording. |
| REVIEW WR-06 | Advisory | Confirmed mechanism (`inbound_live.ex:2080-2110`): a re-posted invalid window keeps committing blocked and swaps the URL note for the draft note. D-12 explicitly says an invalid draft never commits, the highlighted field is the invalid window, and results still reflect the committed URL. The loss of the "excluded" label is a polish miss, not a silent fallback. |
| REVIEW WR-07 | Advisory (D-16 deviation) | `refresh_visible_state/1` (`operator_live.ex:1221-1229`) reruns `assign_delivery_state/5`, which rewrites `results_status_text` (`:1791-1801`) on PubSub refresh; Inbound does not. Unsolicited polite announcements on busy Accounts. Recommend confining the assign to commit-driven reads. |
| REVIEW WR-08 | Advisory | Wall-clock 250 ms assertions are in the advisory browser lane (D-29), not merge-blocking. |
| UI-REVIEW BLOCKER (mobile toggle) | GAP, pre-existing origin | Verified at `operator_live.ex:944-960`; fix pattern already shipped for Inbound. Counted because 176-01 rewired this exact control. |
| Blank `window_hours` / IN-07 | Advisory | `normalize_window_filter` treats a present-blank key as an error (`operator_live.ex:2609-2613`) and `window_options/2` emits "Custom period ( hours)". Reachable only by hand-editing the URL; error copy is still specific. Fix with the WR-02 round. |
| Envelope recipient duplicated / subject-less Quick view | Advisory | Subject-less messages use the recipient as the heading (`components.ex:564`), so it is not dropped. The full detail repeating "Delivered to" in the identity line and the contact row is redundancy, not a false statement. |
| Pre-existing, not counted | Noted | `aria-selected` on `<button>` rows (Phase 113, axe critical, baseline-compared in 176-10); 10 unformatted files untouched by 176; `assign_delivery_state/5` complexity 24. |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `operator/filter_commit.ex` | Pure commit/history/canonical-query helpers | VERIFIED | Substantive and wired from both LiveViews; unit tests pass. |
| `operator/results_status.ex` | Persistent status text per collection | VERIFIED | Wired in both LiveViews, rendered in `role="status"` from first paint. |
| `inbound/address_list.ex` | Dedupe, split >5, spoof cue, unparseable | VERIFIED | Wired in `detail_header.ex`; tests pass. |
| `inbound/evidence_card.ex` | Single-disclosure card + five facts | PARTIAL | Wired; size/reveal source mismatch (WR-01). |
| `priv/static/hooks.js` (`FilterSearchSync`) | Back/Forward sync hook, committed bundle | VERIFIED | Referenced by `phx-hook` on both search inputs; working tree clean. |
| `phase176_prohibition_contract_test.exs` | Mutation-proven must-NOT contracts (D-30) | VERIFIED | 8 prohibitions with fail-first detector tests; passes. |

### Key Link Verification

| From | To | Via | Status |
|------|----|-----|--------|
| Filter form `phx-change` | `FilterCommit.commit_params/2` then `push_patch` | `commit_filters/3` | WIRED |
| `handle_params` | Read + `ResultsStatus.text/1` | `assign_delivery_state/5`, inbound equivalent | WIRED (see WR-07 for PubSub path) |
| Search input | `FilterSearchSync` hook | `phx-hook` + `data-committed` | WIRED |
| Detail header contacts | `AddressList` | `contact_entries/2` | WIRED |
| Reveal button | `reveal_raw`/`re_redact_raw` auth at action time | `inbound_live.ex` | WIRED, unchanged |

### Data-Flow Trace (Level 4)

| Artifact | Variable | Source | Real data | Status |
|----------|----------|--------|-----------|--------|
| `detail_header.ex` contacts | `from/to/cc/reply_to` arrays | `InboundRecord` schema via operator read model | Yes | FLOWING |
| `evidence_card.ex` facts | `raw_mime`/`raw_payload`/`raw_headers` | `InboundEvidence` | Yes | FLOWING (size/source mismatch noted) |
| Deliveries/Inbound lists | rows, `total_count` | Tenant-scoped read models | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Prohibition contracts + commit/status/address/evidence units | `mix test` on 5 phase files, `--seed 0` | 73 tests, 0 failures | PASS |
| Connected LiveView behavior | `mix test operator_live_test inbound_live_test inbound/components_test`, `--seed 0` | 331 tests, 0 failures | PASS |
| Orchestrator gate (not re-run by verifier) | `scripts/gsd-regression-gate.sh` | core 81/0, admin 842/0, inbound 480/0, browser 31, node 42/0 | reported by orchestrator |

### Probe Execution

SKIPPED: the phase declares no probe scripts.

### Requirements Coverage

| Requirement | Source Plans | Status | Evidence |
|-------------|--------------|--------|----------|
| FILTER-01 | 01, 07, 10 | PARTIAL | Auto-apply works on both; Deliveries window-select toolbar trap and mobile-toggle strand (gaps). |
| FILTER-02 | 01, 06, 07, 10 | SATISFIED | Debounce 300 on search only, Enter via implicit submission, hook for Back focus. |
| FILTER-03 | 01, 06, 07, 10 | SATISFIED | History policy, `replace: true` canonicalization, page/selection drop, server-held tenant. |
| FILTER-04 | 04, 07, 09, 10 | SATISFIED | P7/P8 contracts; stale vs error separation; residual polish advisory. |
| INUX-05 | 02, 08, 10 | PARTIAL | Complete addresses visually and by data; not exposed to AT (WR-04). |
| INUX-06 | 03, 05, 08, 10 | PARTIAL | Card hierarchy done; size/reveal mismatch (WR-01). |

All six phase requirement IDs appear in plan frontmatter and in REQUIREMENTS.md (checked complete there). No orphaned requirements. REQUIREMENTS.md currently marks FILTER-01, INUX-05, INUX-06 as complete; that should be treated as provisional until the gaps close.

### Locked-decision spot audit

D-01/D-02 (change commits, 300 ms search only), D-03/D-04 (no Apply, no hidden submit), D-07 (`replace: true`), D-08/D-09 (page and selection dropped, server tenant), D-10 (hook in committed bundle, no `phx-patch-focused`), D-17 to D-22 (contact `<dl>`, `AddressList`), D-23 (`mask_recipient/1`, `mask_value/1` retained, trace masked), D-24 to D-27 (single disclosure, `<pre tabindex>`, `can_reveal?` removed), D-28 to D-31 (tests present and passing; coupled specs updated per 176-10) are honored. Deviations: D-16 (WR-07), D-26 denial wiring (WR-03), D-06 Enter replaces when finalizing an in-flight search edit (a deliberate refinement consistent with one entry per intent; accepted).

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `operator_live.ex` | 944-947 | `JS.toggle` on a `md:block` panel | Blocker (gap) | Filters unreachable at desktop width |
| `evidence_card.ex` | 166 vs 205 | Divergent field precedence | Warning (gap) | Size and revealed bytes disagree |
| `components.ex` | 1605 | `aria-label` hides visible text | Warning (gap) | Addresses unreadable to AT |
| `deliveries_list.ex`, `records_list.ex` | 116-121, 137-167 | Test ids carried by hidden `display:none` divs | Info | Not production markup; no user impact |
| Debt markers | n/a | No unreferenced TBD/FIXME/XXX found in changed implementation files | None | n/a |

### Human Verification Required

None. Per D-52 every item above is machine-observable and is routed to a gap or advisory.

### Gaps Summary

Close in one small gap round (all single-file edits):

1. `evidence_card.ex`: unify the source selector for size and reveal; add a both-fields test.
2. `components.ex:1605`: include the value in the `copy_value` accessible name; add an accessible-name test.
3. `operator_live.ex:1308`: count a non-default window as active; add the toolbar-persists test.
4. `operator_live.ex:944`: switch the Deliveries toggle to `JS.toggle_class("mg-inbound-filters-open", ...)`; add a desktop-width assertion.

Recommended to bundle (advisory, cheap): WR-07 confine `results_status_text` to commit-driven reads; WR-03 announce denial from the persistent region; IN-07 skip the custom option for a blank window value.

---

_Verified: 2026-10-28_
_Verifier: Claude (gsd-verifier)_
