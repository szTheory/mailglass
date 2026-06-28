---
phase: 121-inbound-surface-redesign
plan: 02
subsystem: ui
tags: [phoenix-liveview, heex, inbound, a11y, aria-disclosure, telemetry, pii-boundary, exunit, wcag]

# Dependency graph
requires:
  - phase: 121-inbound-surface-redesign
    plan: 01
    provides: the no-data/no-match/populated cond split + data_state gating; the EvidenceCard render kept inside the per-selection reveal_state reset (D-10 render shape this plan composes with)
provides:
  - The Inbound evidence-card reveal affordance is a true ARIA disclosure (aria-expanded false→true, aria-controls="inbound-evidence-raw", mg-focus-ring) with a secondary "Contains unredacted PII." line
  - A "Re-redact raw source" collapse control in the :revealed branch routing back to :redacted via ONE new handle_event("re_redact_raw") — no fourth state atom — returning focus to the reveal button
  - An aria-live="polite" role="status" region announcing the reveal/re-redact state change in TEXT (WCAG 1.4.1), never the warning border color alone
  - A PII-free reveal-audit telemetry count [:mailglass_admin, :inbound, :reveal_raw, :stop] with metadata tenant_id / record_id / outcome only — the first telemetry emit in mailglass_admin
affects: [121-04, 122-preview-surface-redesign, 123-cross-surface-coherence-ratchet]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "ARIA disclosure on a capability-gated reveal: aria-expanded={@reveal_state == :revealed} + aria-controls on the trigger; a collapse button in the expanded branch routes back via ONE handler (no extra state atom); a one-shot phx-mounted focus sentinel returns focus to the trigger"
    - "aria-live status region announces a security-relevant state change in TEXT (sr-only when redacted, visible when revealed) — color is never the sole signal (WCAG 1.4.1)"
    - "First mailglass_admin telemetry: a single fire-and-forget :telemetry.execute/3 (not a span); outcome mapping (:revealed→:granted) lives at the handler call-site so the pure authorize helper stays pure; metadata whitelisted to tenant_id/record_id/outcome (CLAUDE.md PII rule)"

key-files:
  created:
    - mailglass_admin/test/mailglass_admin/inbound/evidence_card_test.exs
  modified:
    - mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex
    - mailglass_admin/lib/mailglass_admin/inbound_live.ex
    - mailglass_admin/test/mailglass_admin/inbound_live_test.exs

key-decisions:
  - "Telemetry emit + outcome mapping live at the reveal_raw handler call-site, AFTER authorize_reveal/1 returns its reveal_state atom; authorize_reveal/1 stays a pure auth helper (0 telemetry references inside it) per the plan's explicit boundary"
  - "tenant_id sourced from socket.assigns.filter_params[\"tenant_id\"] (blank_to_nil), record_id from socket.assigns.detail.record.id — NEVER from payload/body/headers/recipient; metadata map literal contains exactly tenant_id/record_id/outcome"
  - "Re-redact focus return implemented as a one-shot phx-mounted JS.focus sentinel keyed on a transient :focus_reveal_after_redact assign (mirrors the existing replay focus-sentinel pattern), reset to false on every selection/clear so it never steals focus on mount"
  - "The aria-live region is always in the DOM (sr-only in non-revealed states, visible in :revealed) so the :revealed→:redacted collapse is also perceivable; redacted/initial state carries 'Raw source re-redacted.' which (correctly) does NOT contain the revealed announcement string"
  - "New co-located evidence_card_test.exs created as the plan named it; the pre-existing EvidenceCard test in components_test.exs is left intact (still green, 20 tests)"

requirements-completed: [INB-01]

coverage:
  - id: D1
    description: "Reveal button is a true ARIA disclosure (aria-expanded/aria-controls/mg-focus-ring) with the secondary 'Contains unredacted PII.' line"
    requirement: "INB-01"
    verification:
      - kind: unit
        ref: "test/mailglass_admin/inbound/evidence_card_test.exs#the :redacted reveal button is a true ARIA disclosure with the secondary PII line"
        status: pass
      - kind: other
        ref: "grep -c 'aria-controls=\"inbound-evidence-raw\"' lib/mailglass_admin/inbound/evidence_card.ex == 1"
        status: pass
    human_judgment: false
  - id: D2
    description: "Re-redact collapse button in :revealed routes to :redacted via one new handle_event('re_redact_raw') with focus return; no fourth state atom"
    requirement: "INB-01"
    verification:
      - kind: unit
        ref: "test/mailglass_admin/inbound/evidence_card_test.exs#the :revealed state reflects aria-expanded=true and renders the re-redact collapse"
        status: pass
      - kind: unit
        ref: "test/mailglass_admin/inbound_live_test.exs#re_redact_raw collapses :revealed back to :redacted with no auth call (D-11)"
        status: pass
    human_judgment: false
  - id: D3
    description: "aria-live='polite' role='status' region announces the reveal state change in TEXT (WCAG 1.4.1), never border color alone"
    requirement: "INB-01"
    verification:
      - kind: unit
        ref: "test/mailglass_admin/inbound/evidence_card_test.exs#a role=status aria-live=polite region announces the reveal grant in text"
        status: pass
      - kind: other
        ref: "grep -c 'role=\"status\"' lib/mailglass_admin/inbound/evidence_card.ex >= 1"
        status: pass
    human_judgment: false
  - id: D4
    description: "PII-free [:mailglass_admin, :inbound, :reveal_raw, :stop] emit with tenant_id/record_id/outcome only; :revealed→:granted / :denied→:denied at the call-site, authorize_reveal/1 pure"
    requirement: "INB-01"
    verification:
      - kind: unit
        ref: "test/mailglass_admin/inbound_live_test.exs#reveal emits a PII-free [:reveal_raw, :stop] with outcome=:granted (D-12)"
        status: pass
      - kind: unit
        ref: "test/mailglass_admin/inbound_live_test.exs#reveal emits outcome=:denied for a denying operator (D-12)"
        status: pass
      - kind: other
        ref: "grep -c ':mailglass_admin, :inbound, :reveal_raw, :stop' lib/mailglass_admin/inbound_live.ex == 1; emit metadata has no PII key; authorize_reveal/1 has 0 telemetry refs"
        status: pass
    human_judgment: false
  - id: D5
    description: "Frozen denied/redacted copy + redacted-by-default invariant (D-10) un-weakened; raw bytes absent in every non-revealed state; app.css byte-unchanged (D-18)"
    requirement: "INB-01"
    verification:
      - kind: unit
        ref: "test/mailglass_admin/inbound/evidence_card_test.exs#the :denied body is byte-frozen and the raw payload is absent / #the :redacted body is byte-frozen and renders NO inbound-evidence-raw"
        status: pass
      - kind: other
        ref: "git diff --stat mailglass_admin/priv/static/app.css (no change)"
        status: pass
    human_judgment: false

# Metrics
duration: 4min
completed: 2026-06-28
status: complete
---

# Phase 121 Plan 02: Inbound evidence-reveal a11y + reveal telemetry Summary

**Hardened the Inbound evidence-card raw-payload reveal into a true ARIA disclosure (aria-expanded/aria-controls + secondary "Contains unredacted PII." line), added a "Re-redact raw source" collapse routing back to :redacted via one new handle_event with focus return, added an aria-live status region announcing the state change in TEXT (WCAG 1.4.1), and wired the first mailglass_admin telemetry — a PII-free [:mailglass_admin, :inbound, :reveal_raw, :stop] count with tenant_id/record_id/outcome only — all without weakening the redacted-by-default invariant, the capability gate, or the storage contract (D-10/D-11/D-12).**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-28T17:09:13Z
- **Completed:** 2026-06-28T17:13:47Z
- **Tasks:** 2 (both TDD: RED → GREEN)
- **Files modified:** 3 (+1 created test)

## Accomplishments
- **Task 1 (evidence_card.ex):** Turned the reveal button into a true ARIA disclosure — `aria-expanded={@reveal_state == :revealed}`, `aria-controls="inbound-evidence-raw"`, `mg-focus-ring`, kept `type="button"` + `min-h-11` — and added the secondary "Contains unredacted PII." line. Added a "Re-redact raw source" collapse button (`phx-click="re_redact_raw"`, `data-testid="inbound-evidence-re-redact"`) in the `:revealed` branch, an `id` on the reveal button for focus return, and an always-present `role="status" aria-live="polite"` region (sr-only when not revealed) that announces "Raw source revealed. This payload contains unredacted PII." on grant / "Raw source re-redacted." on collapse — TEXT, never border color (WCAG 1.4.1). Denied/redacted body copy byte-frozen.
- **Task 2 (inbound_live.ex):** Added `handle_event("re_redact_raw", …)` assigning `:reveal_state, :redacted` with NO auth call and a one-shot focus sentinel back to the reveal button. Wired a PII-free `[:mailglass_admin, :inbound, :reveal_raw, :stop]` emit at the `reveal_raw` handler call-site AFTER `authorize_reveal/1` returns — mapping `:revealed→:granted` / `:denied→:denied` via a `reveal_outcome/1` call-site helper — with metadata `tenant_id`/`record_id`/`outcome` only. `authorize_reveal/1` stays a pure auth helper; the redacted-default resets at `assign_inbound_state/3` and `clear_surface_state/1` are untouched (D-10).

## Task Commits

1. **Task 1: Reveal disclosure ARIA + re-redact button + aria-live region (D-11)** - `cfc2d24f` (feat)
2. **Task 2: re_redact_raw handler + PII-free reveal telemetry (D-11/D-12)** - `72b15f40` (feat)

## Files Created/Modified
- `mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex` - reveal button → ARIA disclosure (aria-expanded/aria-controls/mg-focus-ring) + id; secondary "Contains unredacted PII." line; NEW re-redact button in `:revealed`; NEW always-present `role="status" aria-live="polite"` region + `reveal_status_text/1` helper.
- `mailglass_admin/lib/mailglass_admin/inbound_live.ex` - NEW `handle_event("re_redact_raw", …)` (assigns `:redacted` + `:focus_reveal_after_redact`); telemetry wired in the `reveal_raw` handler via `emit_reveal_telemetry/2` + `reveal_outcome/1` + `reveal_record_id/1`; `:focus_reveal_after_redact` assign added to mount and reset in `assign_inbound_state/3` + `clear_surface_state/1`; one-shot focus sentinel rendered beside the replay sentinel.
- `mailglass_admin/test/mailglass_admin/inbound/evidence_card_test.exs` - NEW co-located component test (6 tests): disclosure ARIA + secondary line, revealed/re-redact, aria-live region present+announcing, frozen denied/redacted copy, redacted-by-default raw absence.
- `mailglass_admin/test/mailglass_admin/inbound_live_test.exs` - NEW describe block (3 tests + helpers): re_redact collapse with no auth call, telemetry grant (outcome=:granted, no PII key), telemetry deny (outcome=:denied); `attach_and_reveal/1` + `assert_no_pii/1` helpers asserting the `@pii_keys` whitelist is absent.

## Decisions Made
- **Telemetry mapping at the call-site, not in the auth helper.** `authorize_reveal/1` returns the `reveal_state` atom and stays pure (verified: 0 telemetry references inside it). The `:revealed→:granted` mapping and the `:telemetry.execute/3` emit live in the `reveal_raw` handler, exactly where the plan placed them.
- **Metadata whitelist enforced by test, not just by inspection.** `assert_no_pii/1` checks the metadata map has none of `:to/:from/:body/:html_body/:subject/:headers/:recipient/:email/:payload`, and asserts the presence of `tenant_id`/`record_id`/`outcome`.
- **One-shot focus sentinel for re-redact focus return**, mirroring the existing replay focus sentinel; the `:focus_reveal_after_redact` flag resets to `false` on every selection/clear so it never steals focus on mount or re-selection.
- **aria-live region always in the DOM** (`sr-only` when not revealed) so the `:revealed→:redacted` collapse is announced too; the redacted/initial state carries "Raw source re-redacted." which does not contain the revealed announcement string (asserted).
- **New `evidence_card_test.exs` created** as the plan named it; the older EvidenceCard test in `components_test.exs` is left intact and still green (20 tests).

## Deviations from Plan

None - plan executed exactly as written. Both tasks ran RED → GREEN; no Rule 1–4 deviations were needed. The new co-located test file path was specified by the plan's `files_modified` frontmatter.

## Issues Encountered
- **Pre-existing out-of-scope warning (deferred, unchanged):** `mix compile --warnings-as-errors` still fails only on the shipped Phase 120 warning — `attribute "selected_delivery" … must be a :map, got: nil` at `operator_live.ex:505`, which this plan does not touch (already logged in 121-01's deferred-items). This plan's touched files (`inbound_live.ex`, `evidence_card.ex`) compile clean with zero warnings. Gated on the touched-file compile per the orchestrator's guidance.

## User Setup Required
None - no external service configuration required. The new telemetry event is fire-and-forget; adopters may optionally attach a handler to `[:mailglass_admin, :inbound, :reveal_raw, :stop]`.

## Next Phase Readiness
- The evidence reveal affordance now exposes WCAG 2.2 AA + APG disclosure semantics, a text-announced state change, a re-redact path, and a PII-free reveal-audit count. Plan 121-04 owns the e2e (structural.spec.js) only-forward assertions for the disclosure/re-redact/aria-live behaviors and the locked redacted-by-default boundary (structural.spec.js:1176-1177) — the render shape here is compatible with that un-weakened boundary.
- Raw payload bytes remain absent in `:redacted` and `:denied`; `:revealed` is the only raw-rendering state, and re-redact returns to a state with no raw bytes in the DOM (Phase 99 PII boundary upheld).

## Self-Check: PASSED

All modified/created files exist; both task commits (`cfc2d24f`, `72b15f40`) are present in git history. Targeted verification green: `mix test test/mailglass_admin/inbound/evidence_card_test.exs test/mailglass_admin/inbound_live_test.exs --seed 0` → 72 tests, 0 failures. `grep -c ':mailglass_admin, :inbound, :reveal_raw, :stop' inbound_live.ex == 1`; `grep -c 'aria-controls="inbound-evidence-raw"' evidence_card.ex == 1`; emit metadata has no PII key; `authorize_reveal/1` has 0 telemetry refs; `app.css` byte-unchanged.

---
*Phase: 121-inbound-surface-redesign*
*Completed: 2026-06-28*
