---
phase: 121-inbound-surface-redesign
verified: 2026-06-28T13:35:00Z
status: passed
score: 6/6 must-haves verified
behavior_unverified: 0
overrides_applied: 0
deferred:
  - truth: "operator-inbound persona cells re-shot for only-forward D-THEME-PARITY visual proof (375/1440 × light/dark × 3 personas)"
    addressed_in: "Phase 123"
    evidence: "ROADMAP Phase 123 goal: 're-score the aesthetic ratchet only-forward and arm the new judgment gates'; Plan 121-04 deferred the re-shoot because the demo webServer auto-boot requires a baseline-drifting `mix deps.get` (frozen-baseline landmine). Demo baseline mix.lock verified byte-identical; persona spec unedited."
---

# Phase 121: Inbound surface redesign Verification Report

**Phase Goal:** Redesign the Inbound surface consistent with the cleaned-up Deliveries patterns (Phase 120 empty-pane-only IA), preserving PII/raw-payload boundaries, with the full viewport×theme×state matrix and paired structural tests — INB-01.
**Verified:** 2026-06-28T13:35:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

The phase goal is achieved in the codebase. The Phase 120 no-data/no-match/populated `cond` split is ported verbatim onto the Inbound LiveView (empty-pane-only orientation strip, withheld toolbar/health-strip/master-detail in genuine no-data); the reveal affordance is a true ARIA disclosure with re-redact + aria-live + PII-free telemetry; both replay modals carry an identical Tab focus-trap + double-submit lock; and the paired Playwright judgment gate + a11y e2e + D-07 copy migration are landed with the locked PII boundary preserved. The committed `app.css` is byte-unchanged across the whole phase.

### Observable Truths

| # | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| 1 | Genuine no-data Inbound renders a SINGLE calm pane only (empty-pane + orientation strip); filters toolbar, CTA, health strip, master-detail grid all withheld (D-02/D-05) | ✓ VERIFIED | inbound_live.ex:405-425 — `cond` branch guarded `@records == [] and not filters_active?(@filter_params) and @filter_errors == %{}` renders only `inbound-deliveries-empty-pane` (414) + `orientation_strip surface={:inbound}` (425); `true ->` branch (426+) holds filters/overview/master-detail. ExUnit "genuine no-data renders a single calm pane: truly-empty copy + orientation, toolbar withheld" passes. e2e judgment gate operator.spec.js:497-502 asserts inbound-empty-truly count 1, inbound-orientation count 1, inbound-filters count 0, inbound-master-detail count 0. |
| 2 | No-match / populated render the filters toolbar + health strip + master-detail; orientation strip NOT rendered there (D-03/D-04) | ✓ VERIFIED | `orientation_strip surface={:inbound}` count == 1 (only in no-data branch); removed from the `is_nil(@detail)` detail column (inbound_live.ex:527-535 has the helper, no strip). e2e gate asserts POPULATED inbound-orientation count 0 + filters visible; NO-MATCH filters visible + orientation count 0 (operator.spec.js:485-486, 508-509). |
| 3 | Populated-but-unselected detail column retains the "Select an InboundMessage…" helper (D-04, positive proof) | ✓ VERIFIED | inbound_live.ex:527-535 `is_nil(@detail) ->` renders `data-testid="inbound-empty-detail"` with "Select an InboundMessage to inspect its Mailbox routing, execution timeline, and raw evidence." `grep -c inbound-empty-detail` == 1. |
| 4 | D-07 noun fix + reachable data_state; no-match copy unchanged | ✓ VERIFIED | records_list.ex "No InboundMessages have been recorded yet." count 1; old "No records have been recorded yet." count 0; "No records match the current filters." preserved. `data_state=` wired in inbound_live.ex (count 1), gated on `records == []` so a loaded list is never hijacked (regression fix `9e6c822c`; tests "surfaces the detail-error band" pass). |
| 5 | Reveal is a true ARIA disclosure + re-redact + aria-live + PII-free telemetry; redacted-by-default un-weakened (D-10/D-11/D-12) | ✓ VERIFIED | evidence_card.ex: `aria-controls="inbound-evidence-raw"` (1), `aria-expanded` (1), `role="status"` (1), `aria-live="polite"` (1), `inbound-evidence-re-redact` (1), "Contains unredacted PII." (1); frozen denied/redacted copy present verbatim. inbound_live.ex: `handle_event("re_redact_raw"…)` assigns :redacted with no auth call; `[:mailglass_admin,:inbound,:reveal_raw,:stop]` emitted from the reveal_raw handler call-site; `authorize_reveal/1` (1015-1028) is pure; `emit_reveal_telemetry/2` (1041-1051) metadata is tenant_id/record_id/outcome ONLY — no PII key. Behavioral tests pass: re_redact collapse with no auth, outcome=:granted, outcome=:denied + no-PII assertion. |
| 6 | Both replay modals: identical Tab focus-trap + double-submit lock; all prior APG affordances preserved (D-14) | ✓ VERIFIED | inbound + operator replay_modal.ex each: 2 focus-sentinel spans (start→#…-replay-confirm, end→#…-replay-close), `phx-disable-with` (1), "Replaying…" (1), idle "Confirm replay" + `btn btn-error` preserved; role=dialog / aria-modal / phx-key="Escape" all present (1 each, none removed). e2e flows.spec.js asserts focus-trap + double-submit on both surfaces. |

**Score:** 6/6 truths verified (0 present, behavior-unverified)

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | operator-inbound persona cell re-shoot (only-forward D-THEME-PARITY visual delta, 375/1440 × light/dark × 3 personas) | Phase 123 | ROADMAP Phase 123 goal "re-score the aesthetic ratchet only-forward and arm the new judgment gates"; deferred in Plan 04 to avoid the frozen-baseline `mix deps.get` landmine; demo baseline mix.lock verified byte-identical; persona spec unedited. Documented, legitimate deferral. |

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `mailglass_admin/lib/mailglass_admin/inbound_live.ex` | else-branch cond split + data_state wiring + telemetry + re_redact handler | ✓ VERIFIED | Top-level cond at :405; data_state threaded; re_redact_raw + reveal telemetry wired; pure authorize_reveal preserved. |
| `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex` | D-07 noun fix | ✓ VERIFIED | empty_body(:truly_empty) uses InboundMessage noun; no-match copy unchanged. |
| `mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex` | ARIA disclosure + re-redact + aria-live + PII line | ✓ VERIFIED | All a11y affordances present; frozen denied/redacted copy. |
| `mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex` | Tab focus-trap + Replaying… lock | ✓ VERIFIED | 2 sentinels + phx-disable-with; APG attrs preserved. |
| `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex` | identical lockstep changes | ✓ VERIFIED | Byte-identical mechanism to inbound modal. |
| `mailglass_admin/e2e/operator.spec.js` | paired split + Inbound judgment gate | ✓ VERIFIED | Populated-inbound toBeVisible assertion removed (count 0); new judgment gate asserts full matrix incl. no-data filters count-0 boundary. |
| `mailglass_admin/e2e/flows.spec.js` | reveal + replay a11y e2e (both surfaces) | ✓ VERIFIED | aria-expanded (7), re-redact (1), phx-disable-with (4), aria-live/role=status (5). |
| `mailglass_admin/e2e/structural.spec.js` | D-07 copy migration; PII boundary preserved | ✓ VERIFIED | Old copy count 0, new copy count 2, inbound-evidence-redacted count 2 (boundary un-weakened). |
| `mailglass_admin/test/.../evidence_card_test.exs` (new) | component a11y tests | ✓ VERIFIED | File present; suite green. |
| `reference/demo_app/.../persona-screenshots.spec.js` | re-run only (no edit) | ✓ VERIFIED (deferred re-run) | Spec unedited (git clean); re-shoot deferred to Phase 123. |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| inbound_live.ex else-branch | empty_state_for/2 truth | top-level cond, no new flag | ✓ WIRED | Guard `@records == [] and not filters_active?(@filter_params) and @filter_errors == %{}` present verbatim. |
| inbound_live.ex | RecordsList.records_list | data_state={@data_state} | ✓ WIRED | data_state attr passed; gated on records == []. |
| reveal_raw handler | :telemetry.execute | emit_reveal_telemetry after authorize_reveal returns | ✓ WIRED | Call-site mapping :revealed→:granted; pure helper untouched. |
| replay modal sentinels | Close/Confirm ids | JS.focus(to:) | ✓ WIRED | start→confirm, end→close in both modals. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| IA state machine + detail-error + masking | `mix test inbound_live_test.exs voice_test.exs evidence_card_test.exs --seed 0` | 88 tests, 0 failures (1 excluded) | ✓ PASS |
| re_redact state transition + telemetry outcome mapping | named tests at inbound_live_test.exs:1469/1498/1518 | pass | ✓ PASS |
| operator + components regression | `mix test operator_live_test.exs components_test.exs --seed 0` | 159 tests, 0 failures | ✓ PASS |
| e2e specs parse | `npx playwright test operator/flows/structural.spec.js --list` | 146 tests enumerate, no syntax error | ✓ PASS |
| token-parity floor (D-18) | `mix test token_parity_test.exs --seed 0` | 2 tests, 0 failures | ✓ PASS |
| app.css byte-unchanged over whole phase | `git diff --stat df3f69fc~1 HEAD -- priv/static/app.css` | empty (no change) | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| INB-01 | 121-01/02/03/04 | Inbound surface redesigned consistent with cleaned-up Deliveries patterns, satisfying the cross-cutting matrix | ✓ SATISFIED | All 6 truths verified; REQUIREMENTS.md marks INB-01 Complete (Phase 121); no orphaned IDs for this phase. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| (none in phase-modified source) | — | TBD/FIXME/XXX scan returned no matches | — | No blocker debt markers in any of the 5 modified lib/ files. |

### Human Verification Required

None. All truths are behaviorally exercised by passing ExUnit/Playwright tests; no behavior-dependent truth was left present-but-unverified.

### Gaps Summary

No gaps. All 6 must-have truths are verified in the codebase with passing behavioral evidence; all 4 plans' artifacts exist, are substantive, and are wired; the locked PII redacted-by-default boundary and the no-data scope-widening security boundary are preserved and asserted; `app.css` is byte-unchanged (D-18 landmine avoided). The operator-inbound persona re-shoot is a documented, legitimately-scheduled deferral to Phase 123 (ratchet re-arm), not a gap — the demo baseline lock was verified byte-identical and the persona spec is unedited. The pre-existing `operator_live.ex:505` `--warnings-as-errors` warning is inherited Phase 120 code (not modified by this phase) and is out of scope per the verification ground rules.

---

_Verified: 2026-06-28T13:35:00Z_
_Verifier: Claude (gsd-verifier)_
