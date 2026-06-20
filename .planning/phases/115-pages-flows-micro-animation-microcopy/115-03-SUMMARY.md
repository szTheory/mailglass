---
phase: 115-pages-flows-micro-animation-microcopy
plan: 03
subsystem: testing
tags: [conformance, grep-gate, shell, ci, voice, motion, brand]

# Dependency graph
requires:
  - phase: 115-01
    provides: locked tenant-selector copy + theme-picker transition-colors removal + cause-naming data_state copy
  - phase: 115-02
    provides: .motion-overlay transform-origin var, mg-overscroll-contain utility, replay-modal scroll-chaining guard
provides:
  - VOICE-GATE — .ex-only ban of the Oops-class phrases (Oops/Whoops/Uh oh/Something went wrong) in check-conformance.sh
  - MOTION-GATE positive check — app.css .motion-overlay must declare transform-origin: var(--mg-origin
  - MOTION-GATE negative check — no transition-colors inside the theme_picker/1 function body
  - SIZE-GATE viewport-relative carve-out — max-h/min-h bare viewport units (vh/dvh/...) excepted
affects: [116, conformance-gates, ci-lint-lane]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Two-pass grep gate (strip-then-rematch) to allow a narrow token while keeping the broad ban — BSD/GNU portable"
    - "awk doc-heredoc strip before grepping so @doc/@moduledoc prose describing a ban does not self-trip the gate"
    - "awk function-body extraction (def NAME( .. end) to scope a negative grep to one component only"

key-files:
  created: []
  modified:
    - mailglass_admin/scripts/check-conformance.sh

key-decisions:
  - "VOICE-GATE scoped to *.ex only (sidesteps phoenix.mjs inlined 'noops' false-positive)"
  - "VOICE-GATE strips @doc/@moduledoc heredoc bodies so the ban-describing moduledoc is not flagged"
  - "No standalone Email/Status/Notification ban (Status is a legit <th> header; positive render assertions own those nouns)"
  - "MOTION-GATE negative scoped to theme_picker/1 body only so nav state-layer transition-colors elsewhere survive"
  - "SIZE-GATE carve-out for viewport-relative max-h/min-h (no 4px-grid token expresses 90vh)"

patterns-established:
  - "Strip-then-rematch two-pass gate: collect broad matches, sed out the one allowed token, re-grep the residual"
  - "BSD-sed safety: replace unsupported \\b with (^|[^a-z-]) capture-and-restore boundary"

requirements-completed: [FLOW-03, FLOW-04]

# Metrics
duration: 7min
completed: 2026-06-20
status: complete
---

# Phase 115 Plan 03: Conformance Gates (VOICE-GATE + MOTION-GATE) Summary

**Deterministic grep-only VOICE-GATE (.ex-scoped Oops-class ban) and MOTION-GATE origin/theme additions in check-conformance.sh, with a BSD-portable SIZE-GATE viewport carve-out that unblocks the Wave-1 modal scroll cap; the full gate suite is green (exit 0).**

## Performance

- **Duration:** 7 min
- **Started:** 2026-06-20T18:17:47Z
- **Completed:** 2026-06-20T18:24:47Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- **VOICE-GATE (FLOW-04, Task 1):** new gate adjacent to PHASE112-SHELL-GATE that bans the Oops-class phrases (`Oops`/`Whoops`/`Uh oh`/`Something went wrong`) case-insensitively over `*.ex` files only. `.ex`-only scope sidesteps the `phoenix.mjs` inlined "noops" false-positive entirely (it lives in a JS asset). "Oops" is anchored on a non-word boundary so it can never match the "noops" substring. An awk pass strips `@doc`/`@moduledoc` heredoc bodies first, so the `components.ex` moduledoc that *names* the banned phrases to document the ban is not itself flagged. No standalone Email/Status/Notification ban (those are positive render assertions in voice_test, per D-12).
- **MOTION-GATE positive (FLOW-03, Task 2):** asserts `assets/css/app.css` declares `transform-origin: var(--mg-origin` (origin-aware overlays, D-07); CSS comment bodies are filtered so the explanatory prose above the rule cannot self-satisfy or self-invalidate the gate.
- **MOTION-GATE negative (FLOW-03, Task 2):** forbids `transition-colors` scoped to the `theme_picker/1` function body only (awk-extracted from `def theme_picker(` to its `end`), so legitimate state-layer `transition-colors` on `nav_link`/`nav_pill` hover/focus layers elsewhere are NOT flagged (D-08 inverted default).
- Both new MOTION checks were validated to fire on injected violations and to pass on the landed Plan 01+02 tree.

## Task Commits

Both tasks edit the single plan file (`check-conformance.sh`) and are tightly coupled (the SIZE-GATE carve-out is a blocking-issue deviation discovered while running Task 1's verification), so they were committed together:

1. **Task 1 (VOICE-GATE) + Task 2 (MOTION-GATE positive/negative) + SIZE-GATE deviation** - `1d1e8c33` (feat)

## Files Created/Modified
- `mailglass_admin/scripts/check-conformance.sh` - Added VOICE-GATE block, MOTION-GATE Part 3 (positive origin var) + Part 4 (negative theme transition-colors), an `APP_CSS` var, and a viewport-relative carve-out for the SIZE-GATE.

## Decisions Made
- **VOICE-GATE `.ex`-only + doc-heredoc strip:** the only Oops-class occurrences in `lib/**/*.ex` today are in the `components.ex` `@moduledoc`/`@doc` prose that documents the ban. A naive grep would false-red on the very comment describing the rule. An awk pass drops `@doc`/`@moduledoc` heredoc bodies before grepping, so the gate enforces against rendered copy, not documentation. `@doc since:` one-liners are preserved (they don't open a heredoc).
- **MOTION-GATE negative scoped to `theme_picker/1` body via awk:** a blanket `transition-colors` ban would false-red on the legitimate nav state layers (`components.ex` lines 232/277). Extracting just the `theme_picker/1` function body keeps the negative check precise.
- **Portability:** the test harness `grep` is `ugrep` (shell-function shim) but `bash scripts/check-conformance.sh` runs under non-interactive bash using `/usr/bin/grep` + `/usr/bin/sed` (BSD). All new regex was validated against the BSD toolchain the script actually uses. BSD sed does not support `\b`, so the SIZE-GATE strip uses an `(^|[^a-z-])` capture-and-restore boundary.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1/Rule 3 - Bug/Blocking] SIZE-GATE viewport-relative carve-out (pre-existing Wave-1 regression)**
- **Found during:** Task 1 (running the verification `bash scripts/check-conformance.sh`)
- **Issue:** The committed (Wave-1) conformance script already failed against the current tree with exit 1: SIZE-GATE flagged `max-h-[90vh]` in `lib/mailglass_admin/inbound/replay_modal.ex:37`. Wave-1's `feat(115-02)` commit `a6e7d48c` added `max-h-[90vh]` + `overflow-y-auto` alongside `mg-overscroll-contain` for the modal scroll-chaining guard (D-04, FLOW-03) but never updated SIZE-GATE, leaving the committed gate red. The plan requires the script to pass deterministically against the landed Wave-1 tree.
- **Fix:** Added a strip-then-rematch second pass to SIZE-GATE that drops ONLY arbitrary `max-h`/`min-h` tokens whose value is a bare viewport unit (`vh`/`svh`/`lvh`/`dvh`/`vw`/`svw`/`lvw`/`dvw`/`vmin`/`vmax`); every other arbitrary size/spacing bracket (incl. non-viewport `max-h-[400px]`) still trips the gate, and any other arbitrary token on the same line still fires because the residual re-matches. There is no 4px-grid token for "90% of viewport height", and the cap is what gives the Wave-1 `overflow-y-auto` + `mg-overscroll-contain` something to scroll, so this preserves the intended FLOW-03 functionality rather than deleting it.
- **Files modified:** `mailglass_admin/scripts/check-conformance.sh`
- **Verification:** Validated against `/usr/bin/grep` + `/usr/bin/sed` (the BSD toolchain the script runs under): the modal line passes, non-viewport `max-h-[400px]` and `w-[300px]` still fail, and a line carrying both a viewport `max-h` and a real `w-[300px]` still fails. Full suite exits 0.
- **Committed in:** `1d1e8c33`

---

**Total deviations:** 1 auto-fixed (1 bug/blocking — pre-existing Wave-1 SIZE-GATE regression).
**Impact on plan:** The deviation was required to satisfy the plan's hard constraint that the gate pass deterministically against the landed Wave-1 tree. The carve-out is narrow (viewport-relative max-h/min-h only), reversible, and directly tied to the FLOW-03 D-04 modal scroll work. No scope creep — no source/fixture/route/brandbook changes; only the conformance script was touched.

## Issues Encountered
- **Test-harness grep vs runtime grep mismatch:** the interactive shell aliases `grep` to `ugrep` (which rejects PCRE lookahead and behaves differently on some alternations), while the script runs under non-interactive bash using `/usr/bin/grep`/`/usr/bin/sed` (BSD). Early validation against ugrep gave misleading results. Resolved by validating all new regex against `/usr/bin/grep` and `/usr/bin/sed` directly, and by avoiding PCRE-only constructs (lookahead) and BSD-unsupported `\b` in sed.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- FLOW-03 MOTION-GATE (origin var positive + theme transition-colors negative) and FLOW-04 VOICE-GATE are enforced at lint time, deterministic and grep-only (no pixel-diff, no Node).
- The conformance suite is green against landed Plans 01+02; ready for Wave-2 sibling plans / phase verification.
- Note for the orchestrator: STATE.md/ROADMAP.md/REQUIREMENTS.md mutations were intentionally NOT run for this plan (per execution constraints — main-tree sequential run with a dirty .planning/ tree). Mark FLOW-03/FLOW-04 complete centrally if desired.

## Self-Check: PASSED
- `mailglass_admin/scripts/check-conformance.sh` exists and is committed in `1d1e8c33` (verified via `git show --stat`).
- `git log` contains commit `1d1e8c33` for `feat(115-03)`.
- `bash scripts/check-conformance.sh` exits 0 ("OK: design-system conformance clean.") against the landed Plan 01+02 tree.
- VOICE-GATE acceptance: grep enumerates `--include="*.ex"` only (no .js/.mjs scan); no standalone Email/Status/Notification ban; phoenix.mjs "noops" does not trip it.
- MOTION-GATE acceptance: positive grep for `transform-origin: var(--mg-origin` (comment-filtered) FAILs when absent; negative grep for `transition-colors` scoped to `theme_picker/1` only — both verified to fire on injected violations and pass clean.

---
*Phase: 115-pages-flows-micro-animation-microcopy*
*Completed: 2026-06-20*
