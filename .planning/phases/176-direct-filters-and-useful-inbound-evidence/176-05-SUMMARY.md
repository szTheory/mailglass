---
phase: 176-direct-filters-and-useful-inbound-evidence
plan: "05"
subsystem: ui
tags: [phoenix-liveview, heex, inbound, evidence-card, admin, truthful-facts]

requires:
  - phase: 176-direct-filters-and-useful-inbound-evidence
    provides: "Plan 03 EvidenceCard disclosure and received_at attr"
provides:
  - Inbound.EvidenceCard one facts list of five truthful facts (Provider, Received, Payload size, Header count, Provider authentication)
  - nil-not-zero payload_byte_size/1 and header_count/1 with format_bytes/1 ("Unavailable" for unknown)
  - Truthful empty and missing evidence copy
  - Rebuilt admin app.css bundle (lg:grid-cols-4 for the facts grid)
affects: [176-08, 176-10]

plan_head_before: 2f5d535d8e400194488cd5f903a1ba68881a0261
plan_head_after: 018e1cb20b4c025c2f27c9ce5e53d4d787cee43b

actuals:
  tokens: 7500
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Unknown is nil, not zero: helpers return non_neg_integer() | nil and the renderer maps nil to Unavailable"

key-files:
  created: []
  modified:
    - mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex
    - mailglass_admin/lib/mailglass_admin/gallery_live.ex
    - mailglass_admin/test/mailglass_admin/inbound/evidence_card_test.exs
    - mailglass_admin/test/mailglass_admin/inbound/components_test.exs
    - mailglass_admin/test/mailglass_admin/inbound_live_test.exs
    - mailglass_admin/priv/static/app.css

key-decisions:
  - "Checksum stays out of the five facts as a scope choice: InboundEvidence does store raw_mime_sha256 and raw_mime_fingerprint, and the moduledoc says so"
  - "The gallery revealed specimen now carries its source in raw_mime with an empty raw_payload map, so its size and revealed text are truthful instead of Unavailable and an empty-payload line"
  - "Size precedence: non-empty raw_mime, then non-empty raw_payload map (JSON-encoded size), then known-empty 0 only for an empty map with nil/empty mime, else nil"

requirements-completed: ["INUX-06"]

coverage:
  - id: D1
    description: "One facts dl with five uniform non-mono facts in order; Provider authentication keeps the inbound-evidence-verification testid; Verification facts heading removed"
    requirement: INUX-06
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/inbound/evidence_card_test.exs#Phase 176 facts: one list with five facts in order and the shared grid classes"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#default-renders the redacted placeholder and never leaks raw bytes"
        status: pass
    human_judgment: false
  - id: D2
    description: "Size is raw_mime-backed (3 bytes), formats 0 bytes / 1 byte / 1,234 bytes, header count 0/1/N, and unknown size, count and received time render Unavailable, never 0"
    requirement: INUX-06
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/inbound/evidence_card_test.exs#Phase 176 facts: raw_mime backs the payload size (3 bytes, not 2)"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/inbound/evidence_card_test.exs#Phase 176 facts: unknown size, count and received time render Unavailable, never 0"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/inbound/evidence_card_test.exs#Phase 176 facts: sizes format as 0 bytes, 1 byte and thousands-separated bytes"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/inbound/evidence_card_test.exs#Phase 176 facts: header count renders 0, 1 and N as integers"
        status: pass
    human_judgment: false
  - id: D3
    description: "No-evidence and revealed-empty states say so; the connected Inbound route for a record with no evidence row shows the message, no reveal control, no facts and no 0 bytes"
    requirement: INUX-06
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/inbound/evidence_card_test.exs#Phase 176 facts: no stored evidence says so with no button and no facts"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/inbound/evidence_card_test.exs#Phase 176 facts: a revealed empty payload says the provider sent an empty payload"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/inbound_live_test.exs#Phase 176 Inbound detail without stored evidence says so and offers no reveal"
        status: pass
    human_judgment: false
  - id: D4
    description: "Dead can_reveal? attr removed from EvidenceCard and every gallery specimen with a clean warnings-as-errors compile; bundle committed with token parity"
    requirement: INUX-06
    verification:
      - kind: command
        ref: "mix compile --warnings-as-errors (mailglass_admin)"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/token_parity_test.exs"
        status: pass
    human_judgment: false

duration: 14min
completed: 2026-10-28
status: complete
---

# Phase 176 Plan 05: Truthful evidence facts Summary

**The Raw provider source card shows one list of five uniform facts where payload size follows the stored evidence (raw_mime first), unknown size, count and time read "Unavailable" instead of 0, and empty or missing evidence says so.**

## Performance

- **Duration:** about 14 min
- **Completed:** 2026-10-28
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- One `dl[data-testid="inbound-evidence-facts"]` (`grid gap-md sm:grid-cols-2 lg:grid-cols-4`) replaces the two mismatched lists. Cells in order: Provider, Received (`Components.timestamp`, "Unavailable" when nil), Payload size, Header count, Provider authentication. All `dt`/`dd` use the same non-mono styles. The Provider authentication cell keeps `data-testid="inbound-evidence-verification"`, so the live PII-withholding test is unchanged.
- `payload_byte_size/1` and `header_count/1` return `non_neg_integer() | nil`. A MIME-backed record that used to read "2 bytes" now reads its real size; an encode failure or missing field is nil. `format_bytes/1` renders "1 byte", "1,234 bytes", "0 bytes" for known-empty, and "Unavailable" for nil.
- No-evidence copy is "No raw provider source was stored for this message." (no button, no facts). Revealed-empty reads "Provider sent an empty payload." in place of "(empty)".
- `can_reveal?` is gone from the component and all five gallery sites. The gallery "revealed" specimen was moved to `raw_mime` so it shows a truthful size.
- Components test updated deliberately: the removed "Verification facts" heading is now a `refute`, plus an assert for the facts testid.

## Task Commits

1. **Task 1: One truthful facts list, nil-not-zero, can_reveal? removed (tracer)** - `3dde4525` (feat)
2. **Task 2: Size formatting, empty/missing copy, connected-route test, rebuilt bundle** - `018e1cb2` (feat)

## Verification

- Task 1 lane (evidence_card_test, inbound/components_test, inbound_live_test, group_nesting_test, persona_drift_guard_test `--seed 0`): 156 tests, 0 failures. `mix compile --warnings-as-errors`: exit 0.
- Task 2 lane (evidence_card_test, inbound_live_test, token_parity_test, assets_test, voice_test `--seed 0`): 136 tests, 0 failures. token_parity + assets + voice: 30 tests, 0 failures after the rebuild.
- Quick lane (operator_live_test, inbound_live_test, inbound/components_test, evidence_card_test, group_nesting_test, persona_drift_guard_test, bucket_a_coverage_test `--seed 0`): 332 tests, 0 failures.
- `check-conformance.sh`: clean. `mix format --check-formatted` and `mix credo --strict` clean on every file this plan touched. `git diff --exit-code -- mailglass_admin/priv/static/` clean after commit.
- Acceptance greps: `can_reveal` count 0 in evidence_card.ex and gallery_live.ex (baselines 1 and 6); non-refute "Verification facts" hits in components_test 0; `data-testid="inbound-evidence-verification"` count 1 in evidence_card.ex; "Provider sent an empty payload." count 1.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Gallery "revealed" specimen stored its source as a string in raw_payload**
- **Found during:** Task 1
- **Issue:** With truthful sizing, a string `raw_payload` is not a map, so the specimen would read "Unavailable" and, once the empty-payload copy landed, show "Provider sent an empty payload." beside a source it was meant to display.
- **Fix:** Moved the string to `raw_mime` with `raw_payload: %{}`. Specimen id unchanged.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/gallery_live.ex`
- **Commit:** `3dde4525`

**2. [Observation] Plan line numbers had drifted** (`components_test.exs:663` was at `:875`); edits were located by content. No behavior change.

**Total deviations:** 1 auto-fixed (1 Rule 1), 1 observation. **Impact:** none on scope.

## Issues Encountered

None. A `MailglassDemo.QuickViewScenarios is not included in any boundary` compiler note appears from `reference/persona_spec` when test support compiles; it is not caused by this plan and `mix compile --warnings-as-errors` exits 0.

## Known Stubs

None.

## Threat Flags

None. T-176-23 is mitigated by nil-returning helpers and the nil-field table tests; T-176-24 holds because the facts expose only sizes, counts, provider, time and authentication status, and the raw `<pre>` stays `:revealed`-only.

## Self-Check: PASSED

- Commits `3dde4525` and `018e1cb2` are ancestors of HEAD; `evidence_card.ex` and this SUMMARY exist.
