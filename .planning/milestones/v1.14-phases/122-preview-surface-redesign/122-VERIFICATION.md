---
phase: 122-preview-surface-redesign
verified: 2026-06-28T15:40:00Z
status: passed
score: 12/12 must-haves verified
behavior_unverified: 0
overrides_applied: 0
deferred:
  - truth: "The single `preview` persona cell is re-shot across {northstar,fjordline-aps,helios-void} × {375,1440} × {light,dark}"
    addressed_in: "Phase 123"
    evidence: "Authorized D-17 fallback (written into 122-03 PLAN must_haves) — demo webServer boot requires a baseline-drifting `mix deps.get` (plug/plug_cowboy/premailex-MAJOR/swoosh `=>` bumps confirmed via --check-locked). Captured in deferred-items.md Plan 122-03; Phase 123 re-runs the shoot under a coordinated baseline bump. Persona spec verified intact (exactly 1 `preview` cell, unedited, parses)."
---

# Phase 122: Preview Surface Redesign Verification Report

**Phase Goal:** Redesign the Preview surface consistent with the established patterns, keeping the previewed email's independent theme toggle intact.
**Verified:** 2026-06-28T15:40:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

The Preview surface goal is achieved in the codebase. The bespoke binary admin-theme button was replaced with the canonical tri-state `Components.theme_picker`, routed through Preview's OWN frame-aware `preview_theme_path/2` (never the operator shell's frame-blind builder), so the previewed email's independent backdrop toggle stays distinct and survives chrome remounts. Brandbook microcopy, recovery-oriented error card, a11y hardening, and dead-code removal are all present and wired. The load-bearing D-05 invariant is proven by a passing behavioral test, not just symbol presence.

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Preview header renders canonical tri-state `theme_picker` (light/dark/system), not the bespoke binary button | ✓ VERIFIED | `preview_live.ex:319-322` renders `<Components.theme_picker selected={admin_chrome_selected(@admin_chrome_theme)} event="set_theme" />`; bespoke `preview-admin-theme-toggle` testid absent (grep: 0 matches); e2e `flows.spec.js:467-478` asserts 3 theme radios + system reachable + bespoke gone |
| 2 | Flipping admin chrome theme preserves the independent email-backdrop state (frame=dark carry-through; backdrop does NOT reset) | ✓ VERIFIED (behavioral) | `preview_theme_path/2` (`:622-637`) keeps `put_frame_query(socket.assigns.preview_frame_dark_chrome)` verbatim; behavioral test `preview_live_test.exs:320-332` toggles backdrop dark → fires `set_theme` → asserts redirect `return_to` carries `frame=dark`. Test PASSED. |
| 3 | Email-backdrop button is a correct toggle: aria-pressed reflects state, always-visible "Email backdrop" label, aria-live announce | ✓ VERIFIED | `:324-352` — `aria-pressed={@preview_frame_dark_chrome}`, label "Email backdrop", `role="status" aria-live="polite" sr-only` region with `backdrop_status_text/1`; e2e `flows.spec.js:481-495` asserts the flip + announce |
| 4 | flows.spec.js two-theme independence lock stays green against the theme_picker swap | ✓ VERIFIED | `flows.spec.js:455-465` asserts `preview-pane[data-preview-frame-theme]=dark` while `preview-shell[data-theme]=mailglass-light` — preserved, unweakened |
| 5 | set_theme routes through frame-aware `preview_theme_path/2`, NEVER `Shell.set_theme_path/2` (D-05) | ✓ VERIFIED (behavioral) | `:191-193` handler calls `preview_theme_path`; `set_theme_path`/`Shell.set_theme_path` grep: 0 matches in preview_live.ex; closed-set `theme_segment/1` guard (`:641-643`) |
| 6 | Empty-mailables onboarding leads with brandbook Empty string verbatim; `mix mailglass.gen.mailable` PRIMARY; checks demoted to secondary | ✓ VERIFIED | `:382` brandbook string verbatim; generator chip primary; voice_test `:81` greps the string byte-for-byte (PASSED) |
| 7 | Render-error card headline "This Mailable raised while rendering", names Mailable + scenario, keeps inline `<pre>`, no log redirect | ✓ VERIFIED | `:296` headline; `:300-305` names `inspect(@current_mailable)` + `@current_scenario`; `:307` inline `<pre max-h-80 overflow-auto>`; old "preview_props/0 raised an error" absent |
| 8 | On render-error transition, focus moves OR announced via role=status/aria-live | ✓ VERIFIED | `:287-291` error card carries `role="status" aria-live="polite"` + `motion-reveal` |
| 9 | Dead `dark_chrome` attr removed from preview/sidebar.ex (and gallery pass-through) | ✓ VERIFIED | grep `dark_chrome`: 0 matches in sidebar.ex AND gallery_live.ex |
| 10 | voice_test + preview e2e specs updated same-phase (green-only-forward); start branch has assertSingleH1 | ✓ VERIFIED | voice_test `:67,:81` updated; `flows.spec.js:446-447` asserts `preview-start` visible + single h1 |
| 11 | Committed `priv/static/app.css` bundle untouched (D-13 / TokenParity) | ✓ VERIFIED | `git status` clean for app.css; no 122 commit touched it (last touch commit 5bba33cc, pre-phase); TokenParityTest 4 tests PASSED |
| 12 | Orientation strip stays in `@mailables == []` branch (D-11a, not moved) | ✓ VERIFIED | `:369` `orientation_strip surface={:preview}` immediately inside the `<% @mailables == [] -> %>` clause at `:368` |

**Score:** 12/12 truths verified (0 present, behavior-unverified)

### Deferred Items

| # | Item | Addressed In | Evidence |
| --- | --- | --- | --- |
| 1 | `preview` persona cell re-shoot (4 anchor cells {375,1440}×{light,dark}) | Phase 123 | Authorized D-17 fallback baked into 122-03 PLAN must_haves; demo boot needs baseline-drifting `mix deps.get` (plug/plug_cowboy/premailex-MAJOR/swoosh confirmed via `--check-locked`). Captured in deferred-items.md. Spec intact (1 cell, unedited, parses). NOT a gap. |

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `mailglass_admin/lib/mailglass_admin/preview_live.ex` | theme_picker + set_theme handler + hardened backdrop + aria-live + error/onboarding re-voice | ✓ VERIFIED | All symbols present + wired; compiles warning-clean (only pre-existing out-of-scope operator_live.ex:505 warning trips repo-wide lane) |
| `mailglass_admin/lib/mailglass_admin/preview/sidebar.ex` | dead dark_chrome attr removed | ✓ VERIFIED | grep clean |
| `mailglass_admin/lib/mailglass_admin/gallery_live.ex` | dark_chrome pass-through removed (Rule 3 blocking fix) | ✓ VERIFIED | grep clean |
| `mailglass_admin/test/mailglass_admin/voice_test.exs` | error headline grep updated + brandbook Empty grep added | ✓ VERIFIED | `:67,:81`; tests PASSED |
| `mailglass_admin/test/mailglass_admin/preview_live_test.exs` | migrated assertions incl. frame=dark carry-through | ✓ VERIFIED | 23 tests including D-05 `:320-332`; PASSED |
| `mailglass_admin/e2e/flows.spec.js` | toggle-a11y assertions + two-theme lock + start-branch h1 | ✓ VERIFIED | `:446-447,:455-495`; parses |
| `mailglass_admin/e2e/structural.spec.js` | copy assertions + retargeted theme_picker spots | ✓ VERIFIED | parses (node --check) |
| `reference/demo_app/assets/e2e/persona-screenshots.spec.js` | single `preview` cell intact (re-shoot deferred per D-17) | ✓ VERIFIED | exactly 1 cell, unedited, parses; re-shoot deferred (authorized) |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| theme_picker set_theme event | `preview_theme_path/2` (frame-aware) | `handle_event("set_theme")` → `preview_theme_path` | ✓ WIRED | `:191-193`; never calls `Shell.set_theme_path` (grep 0) |
| set_theme redirect return_to | `put_frame_query(@preview_frame_dark_chrome)` | return_to construction | ✓ WIRED | `:630`; proven by behavioral test `:320-332` |
| voice_test error/Empty greps | preview_live.ex rendered copy | byte-for-byte grep | ✓ WIRED | voice_test PASSED (greps match new copy) |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Preview/voice/token-parity tests | `mix test preview_live_test.exs voice_test.exs token_parity_test.exs --seed 0` | 42 tests, 0 failures (1 excluded) | ✓ PASS |
| D-05 frame=dark carry-through | included above (`preview_live_test.exs:320-332`) | redirect asserts `frame=dark` in return_to | ✓ PASS |
| TokenParity bundle gate | `mix test token_parity_test.exs` | 4 tests, 0 failures | ✓ PASS |
| Persona spec parses + 1 cell | `node --check` + `grep -c` | PARSE-OK, count=1 | ✓ PASS |
| e2e specs parse | `node --check flows.spec.js structural.spec.js` | parse OK | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PREV-01 | 122-01, 122-02, 122-03 | The Preview surface is redesigned consistent with the established patterns, satisfying the cross-cutting matrix | ✓ SATISFIED | All 12 truths verified; REQUIREMENTS.md:82,134 marked Complete; no orphaned reqs (PREV-01 is the only Phase 122 req) |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| (none) | — | No TBD/FIXME/XXX, no placeholder stubs, no unwired empty returns in modified source | — | The two "placeholder" comment hits (`:757,:794`) reference PREV-03 "no placeholder shape divergence" — descriptive, not stubs |

### Human Verification Required

None. All truths verified programmatically including the behavior-dependent D-05 carry-through (proven by a passing behavioral test) and the two-theme independence lock. The persona re-shoot is an authorized deferral to Phase 123 (D-17 fallback), not a verification gap.

### Gaps Summary

No gaps. All 12 must-haves are verified against the codebase:
- theme_picker adoption + frame-aware D-05 routing (proven behaviorally, backdrop survives remount)
- backdrop toggle a11y (aria-pressed + visible label + aria-live announce)
- brandbook onboarding + recovery-oriented error card with inline `<pre>`
- dead `dark_chrome` removal, orientation strip unmoved, paired tests green-only-forward
- app.css bundle byte-untouched (D-13), TokenParity green

The pre-existing `operator_live.ex:505` warning is confirmed out-of-scope (phase 120 origin; preview_live.ex itself compiles clean). The persona re-shoot deferral is authorized and captured for Phase 123 — it does not block the phase goal.

---

_Verified: 2026-06-28T15:40:00Z_
_Verifier: Claude (gsd-verifier)_
