---
phase: 176-direct-filters-and-useful-inbound-evidence
plan: "11"
subsystem: ui
tags: [liveview, evidence-card, d-26, payload-size, status-region, a11y, tdd]
status: complete
gap_closure: true

requires:
  - phase: 176-direct-filters-and-useful-inbound-evidence
    provides: "Plan 05 evidence card with five-fact list and reveal disclosure"
provides:
  - "EvidenceCard.raw_source/1: one selector driving both the Payload size fact and the revealed <pre>"
  - "Nothing-stored card: no reveal control, static D-26 sentence, size Unavailable"
  - "Denied reveal announced from the persistent role=status region (D-26 / WR-03)"
  - "InboundFixtures.insert_evidence!/3 :raw_mime option"
affects: [176-12, 176-13, 176-14, 176-15, phase-176-verification]

plan_head_before: b69da7b3620ab25c32edb5eace23c66187763f35
plan_head_after: 93ff966ce14baddf27132e888958f7b1c28a8bd1
actuals:
  tokens: 7200
  tasks: 2
  commits: 4

tech-stack:
  added: []
  patterns:
    - "One private selector (tagged tuple) feeds every derived fact and the rendered body so two orders cannot diverge"
    - "One complete class list per state (status_region_class/1) instead of a base list plus conditional modifiers"

key-files:
  created: []
  modified:
    - mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex
    - mailglass_admin/lib/mailglass_admin/gallery_live.ex
    - mailglass_admin/test/mailglass_admin/inbound/evidence_card_test.exs
    - mailglass_admin/test/mailglass_admin/inbound_live_test.exs
    - mailglass_admin/test/support/inbound_fixtures.ex
    - .planning/phases/176-direct-filters-and-useful-inbound-evidence/176-UI-SPEC.md

key-decisions:
  - "Precedence is raw_payload first, then raw_mime: restores the pre-phase order (c96c8a4f) for both functions, so the revealed bytes are unchanged and the disclosure surface does not move (D-27)"
  - "Payload size is the UTF-8 byte size of the exact text the reveal renders (pretty JSON for a map, the binary for raw_mime)"
  - "An unencodable non-empty payload stays the selected source even beside a raw_mime: size Unavailable, reveal shows the inspect/2 fallback, the MIME is never consulted"
  - "Nothing stored (raw_source/1 == :unknown) renders no caption, button, <pre> or status region, only the existing D-26 sentence as static text"
  - "UI-SPEC rows for Denied and Status region are superseded: the denial is the text of the persistent region (D-26 wins over the UI-SPEC wording)"

patterns-established:
  - "Regression invariant: a both-fields-stored test asserts size == byte_size of the revealed text, on the component and on the live reveal route"

requirements-completed: ["INUX-06"]

coverage:
  - id: D1
    description: "With raw_mime and raw_payload both stored, Payload size equals the byte size of the revealed text (component and live authorized reveal route)"
    requirement: "INUX-06"
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/inbound/evidence_card_test.exs#Phase 176 facts: both stored, the size is the byte size of the revealed text"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#Phase 176 Inbound reveal: with both fields stored, Payload size is the byte size of the revealed text"
        status: pass
    human_judgment: false
  - id: D2
    description: "A record with nothing stored shows no reveal control and the static not-stored sentence; known-empty keeps its control"
    requirement: "INUX-06"
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/inbound/evidence_card_test.exs#Phase 176 facts: nothing stored, no reveal control and the size is Unavailable"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/inbound/evidence_card_test.exs#Phase 176 facts: a known-empty payload keeps its reveal control"
        status: pass
    human_judgment: false
  - id: D3
    description: "A denied reveal is announced from the persistent role=status region; no second live region; raw bytes absent"
    requirement: "INUX-06"
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/inbound/evidence_card_test.exs#Phase 176 denial is announced from the persistent status region"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#evidence redacted-default + reveal-denied carry verbatim copy (V10)"
        status: pass
      - kind: e2e
        ref: "playwright: phase176-filters.spec.js revealed and denied raw source pass axe (light, dark); structural.spec.js Inbound WCAG AA contrast matrix; flows.spec.js Inbound reveal is a true ARIA disclosure (4 passed)"
        status: pass
    human_judgment: false
---

# Phase 176 Plan 11: One raw-source selector, nothing-stored card, persistent denial region Summary

**The evidence card's Payload size and its revealed raw source now come from one `raw_source/1` selector (raw_payload first, then raw_mime), a record with nothing stored shows no reveal control, and a denied reveal is announced from the persistent status region.**

Duration: about 6 minutes. Start 2026-10-28T15:08Z, end 2026-10-28T15:14Z. Tasks: 2. Files: 6.

## Accomplishments

- Closed gap SC5 / INUX-06 (WR-01). Phase 176 made the size raw_mime-first while the reveal stayed raw_payload-first, so SES records (which store both) stated the size of one field and revealed another. Both now read the same selector result.
- Bundled IN-04 (D-26 "hide the button"): evidence with nothing stored renders no caption, button, `<pre>` or status region, only `<p data-testid="inbound-evidence-not-stored">No raw provider source was stored for this message.</p>`. It no longer offers a reveal that would claim "Provider sent an empty payload." beside a size of "Unavailable".
- Bundled WR-03 (D-26): the denial copy is now the text of the always-present `inbound-evidence-status` region (wrapped in an inline `data-testid="inbound-evidence-denied"` span with no role). No freshly inserted second live region exists. `status_region_class/1` returns one full class list per state; `:denied` carries `border` plus `border-warning` (the box) and `text-base-content`, with neither `text-secondary` nor `sr-only`.
- UI-SPEC: added the "Nothing stored (no reveal control)" state-body row; rows 171 (Denied) and 173 (Status region) marked "Superseded by 176-11 per D-26 / WR-03" and rewritten to the persistent-region contract. CONTEXT.md untouched.
- Gallery specimens `evidence_card` "redacted" and "denied" now carry `%{"body" => "Gallery specimen payload"}` so they keep showing the reveal button and the denial they are named for. No story added.

## Task Commits

1. Task 1 RED: `41401f07` test(176-11): add failing tests for one raw-source selector and nothing-stored card
2. Task 1 GREEN: `829977f9` feat(176-11): one raw-source selector for payload size and reveal
3. Task 2 RED: `4b9156f4` test(176-11): add failing tests for denial announced from the persistent status region
4. Task 2 GREEN: `93ff966c` feat(176-11): announce a denied reveal from the persistent status region

## TDD Evidence (red then green)

Task 1 RED (evidence_card_test.exs, `--seed 0`: 22 tests, 5 failures; each on the planned assertion):
- `sizes format as 0 bytes, 1 byte and thousands-separated bytes`: right `{"Payload size", "7 bytes"}`, expected pretty-JSON `"12 bytes"`.
- `both stored, the size is the byte size of the revealed text`: right `"39 bytes"` (the MIME's size), expected `"58 bytes"`.
- `sizes count UTF-8 bytes, not characters`: right `"22 bytes"` (compact), expected `"27 bytes"`.
- `an unencodable payload stays the source, size Unavailable, never the MIME`: right `"17 bytes"` (the MIME's size), expected `"Unavailable"`.
- `nothing stored, no reveal control and the size is Unavailable`: `Floki.find(doc, "[data-testid='inbound-evidence-reveal']") == []` failed, the button rendered.
- Live route (`inbound_live_test.exs --only phase176`): 124 tests, 1 failure, `size_dd == "37 bytes"` but left `"16 bytes"` (the MIME's size).

Task 2 RED (3 failures): the persistent region read "Raw source hidden." in `:denied` in both the new region test and the live-route test; the updated component test found two `role="status"` elements (the freshly inserted denied paragraph plus the persistent region).

GREEN: evidence_card_test + quick_view_projection_test 28 tests, 0 failures; `inbound_live_test.exs --only phase176` 124 tests, 0 failures; evidence_card + components + phase176_prohibition_contract + quick_view_projection 96 tests, 0 failures; full `inbound_live_test.exs` 124 tests, 0 failures; full admin suite `mix test --seed 0` 850 tests, 0 failures, 1 excluded.

## Precedence and Measurement Decisions

- Precedence: non-empty raw_payload map wins, then non-empty raw_mime binary. This is the pre-phase order (c96c8a4f) for both functions, so what an authorized operator sees is identical before and after this fix (D-27). The existing `raw_payload: %{}` plus MIME tests keep their meaning because an empty map falls through to the MIME. Review WR-01 sketched mime-first; that would have changed the revealed bytes for every SES and Mailgun record.
- Measurement: byte size of the exact revealed text. For a map that is `Jason.encode(payload, pretty: true)`; for raw_mime it is the binary.
- Unencodable carve-out: a non-empty map that Jason cannot encode stays the source even with a non-empty raw_mime. Size is "Unavailable" (never the MIME's size, never the byte size of the inspect/2 debugging text); the reveal shows the inspect/2 fallback of the payload, never the MIME.
- D-26 truth rules unchanged: known-empty (`%{}` and no MIME) reads "0 bytes"; unknown storage or an unencodable payload reads "Unavailable", never 0.

## Operator-visible value change

Two baselines are relevant. At c96c8a4f (pre-phase) a map payload was measured with compact `Jason.encode!/1`. At Phase 176 HEAD before this plan (5c65e9bb) a non-empty raw_mime was measured first and otherwise compact `Jason.encode/1`.

After this plan, Payload size for every non-empty, encodable map-payload record measures the pretty JSON the reveal shows. Example: `%{"a" => 1}` was "7 bytes" at both baselines and is now "12 bytes". Records that store both fields (SES, Mailgun) showed the compact payload size at c96c8a4f and the MIME size at 5c65e9bb; they now show the pretty payload size. raw_mime-only records are unchanged against both baselines. A nothing-stored record now shows no reveal control and the static sentence "No raw provider source was stored for this message." (IN-04 / D-26) where it previously offered a reveal that said "Provider sent an empty payload.". This is an intended value change, not a regression.

Scope facts so verify-work does not overread the change:

1. The nothing-stored branch (`raw_source/1` returns `:unknown`) is reachable only for legacy or fixture rows with nil storage. In production, `raw_payload` is `NOT NULL DEFAULT %{}` (`mailglass_inbound/lib/mailglass_inbound/migrations/postgres/v01.ex:81`) and ingest writes `Map.get(evidence, :raw_payload, %{})` (`mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex:460`), so a production row without a MIME is `%{}`. It stays known-empty, reads "0 bytes" and keeps its reveal control ("Provider sent an empty payload.").
2. Payload size measures the UTF-8 byte size of the pretty-printed JSON re-encoding that the reveal renders (`Jason.encode(payload, pretty: true)`). It does not measure the bytes the provider originally sent; for a map payload those bytes are not stored. For raw_mime it is the stored binary itself.

## UI-SPEC Supersession

Rows 171 (Denied) and 173 (Status region) of `176-UI-SPEC.md` previously prescribed a separately inserted denied paragraph with its own `role="status"`. CONTEXT D-26 says the denial is announced "via the existing `role="status"` region", and review WR-03 found a freshly inserted live region may not be announced. D-26 wins. Both rows are rewritten to the persistent-region form and carry "(Superseded by 176-11 per D-26 / WR-03.)". The row-4 grep for the old markup (`data-testid="inbound-evidence-denied" role="status"`) now returns 0.

## Advisory Browser Lane (D-29)

`npm --prefix mailglass_admin run test:operator-browser -- phase176-filters.spec.js structural.spec.js flows.spec.js --grep "revealed and denied raw source|Inbound: WCAG AA contrast matrix covers light/dark themes|Inbound reveal is a true ARIA disclosure"`: 4 passed, 0 failed (flows ARIA disclosure; phase176 revealed/denied axe in light and dark; structural Inbound contrast matrix). The wrapper restored `priv/static/app.css` and the tracked Phase 168/169 artifact directories; both are clean at HEAD. The committed bundle was not rebuilt or committed; no new CSS class or icon was introduced.

## Deviations from Plan

None - plan executed exactly as written. One ordering note: while drafting Task 1 tests I briefly edited the denied live-route selector (a Task 2 item), reverted it before the Task 1 RED commit, and applied it in Task 2.

## Issues Encountered

- `mix format --check-formatted` in `mailglass_admin` reports 10 pre-existing unformatted files (for example `persona_drift_guard_test.exs`, `bucket_a_coverage_test.exs`, `operator/timeline.ex`, `auth.ex`). None is touched by this plan; every file this plan changed is formatted. Out of scope, not fixed.

## Known Stubs

None.

## Threat Flags

None. No new endpoint, auth path or storage surface. T-176-27 held: the selector feeds the `<pre>` only in the `:revealed` branch, raw_payload stays first so revealed bytes are unchanged, and the denied and redacted paths carry no payload bytes (phase176_prohibition_contract P4 and P5 green). T-176-28: the both-fields tests assert size == byte_size of the revealed text; plan 176-14 adds the mutation-proven contract P9.

## Next Phase Readiness

Ready for 176-12 (wave 2). It edits `components_test.exs` and `flows.spec.js`, which this plan ran but did not modify. No blockers.

## Self-Check: PASSED

- `defp raw_source(` in evidence_card.ex: 1. `raw_mime: Keyword.get(opts, :raw_mime)` in inbound_fixtures.ex: 1. `data-testid="inbound-evidence-not-stored"` in evidence_card.ex: 1. `Gallery specimen payload` in gallery_live.ex: 2. `defp status_region_class(`: 1.
- UI-SPEC: "Added by 176-11 per IN-04" 1; "Superseded by 176-11" 2; old denied-role markup 0.
- Commits 41401f07, 829977f9, 4b9156f4, 93ff966c are ancestors of HEAD; `git rev-list --count` from the ledger base is 4.
