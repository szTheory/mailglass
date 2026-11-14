# Phase 176: Direct Filters and Useful Inbound Evidence - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-10-27
**Phase:** 176-direct-filters-and-useful-inbound-evidence
**Mode:** assumptions (research-first fan-out per CLAUDE.md Decision Policy; owner asked for one-shot coherent recommendations)
**Areas analyzed:** Commit path/history/Account; Invalid input and read failures; Inbound contact display; Raw provider source card; Verification placement

## Research fan-out
1. Codebase assumptions analyzer — current filter wiring, normalization, read-failure handling, address masking, evidence card, coupled tests, CI lanes.
2. LiveView auto-apply research — verified against pinned client source (`phoenix_live_view.js`, LV 1.2.13) and CHANGELOG: debounce flush on submit/blur, focused-input merge, `phx-patch-focused` (≥1.2.8 only), form recovery, LiveViewTest limits (no push/replace distinction).
3. Inbound address/raw-source research — RFC 5321/5322/6531/6532, UTS #46/#39, Postmark/Mailgun/SendGrid prior art, `<dl>`/overflow-wrap guidance.

## Assumptions Presented

| Area | Assumption | Confidence | Evidence |
|---|---|---|---|
| Commit path | Reuse form→push_patch→handle_params; phx-change commits; debounce search; Enter via phx-submit | Confident | operator_live.ex:249-291, inbound_live.ex:249-285 |
| History | One entry per settled intent; search edit = 1 push then replaces | Likely | no `replace:` anywhere; ROADMAP "no query-fragment flooding" |
| Account | Commits use server-held tenant | Likely | hidden tenant input operator_live.ex:948-953 |
| Invalid/failed | Invalid draft never commits; new-query failure = error w/o counts; same-query = stale | Likely | operator_live.ex:1554-1565; deliveries_list.ex:50-55 shows "0 deliveries" on error |
| INUX-05 | Unmask From only; "Delivered to" for envelope; keep mask helpers + trace masking | Likely | detail_header.ex:125-146; components.ex:576-578; routing_trace.ex:171-249 |
| INUX-06 | Recompose card; one header group, one dl; nil not 0 | Likely | evidence_card.ex:38-165 |
| Verification | ExUnit merge-blocking + advisory Playwright + mutation-proven prohibition test | Confident | mix.exs:213-215; ci.yml:1428-1453 |

## Conflicts resolved in synthesis
- D-30 citation: research found PROJECT.md D-30 is the B2C safety profile, not "unmask"; authority set to UPSTREAM-SCOPE §76.
- "Reveal is logged" copy dropped: telemetry is not an audit log.
- Hidden submit button vs implicit submission: chose implicit submission + pinning browser test.
- "Showing results for…" line: limited to a note shown only while an invalid draft is pending (less noise).
- IDNA conversion: deferred (no stdlib IDNA, no-new-dep preference); Unicode shown as received.
- `phx-patch-focused` rejected (version floor + clobbers typing); copy-paste hook chosen.
- New finding: tenant canonicalization pushes history → Back trap; fixed with `replace: true` (D-07).

## Corrections Made
No corrections — owner pre-authorized one-shot research-driven recommendations.
