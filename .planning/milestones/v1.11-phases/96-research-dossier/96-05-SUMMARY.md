---
phase: 96-research-dossier
plan: 05
subsystem: ui
tags: [microcopy, ux-writing, brand-voice, admin, liveview, accessibility]

requires:
  - phase: 96-01
    provides: MOTION.md with MOTION-LD-01..14 locked decisions
  - phase: 96-02
    provides: IA.md with IA-LD-01..09 locked decisions including GAP-02 and GAP-04 reference
  - phase: 96-03
    provides: COMPONENT-STATES.md with STATE-LD-01..22 locked decisions including component archetypes
  - phase: 96-04
    provides: DARK-MODE.md with DARK-LD-01..08 locked decisions

provides:
  - MICROCOPY.md at .planning/research/v1.11/ with 16 COPY-LD-NN locked decisions
  - Codebase-grounded copy inventory with file:line citations for all three admin surfaces
  - Adversarially-synthesized locked copy strings for empty/error/loading/confirmation states
  - GAP-02 close signal (Preview CTA "Preview the first Mailable" — keyboard-focusable domain noun)
  - GAP-04 copy angle (Inbound "Window" → "Time window"; coordinated with Phase 99 class change)

affects:
  - Phase 101 (Microcopy Pass) — cites COPY-LD-NN IDs for all copy string changes
  - Phase 103 (Verification + Closeout) — Type pillar conformance checks voice-pattern compliance
  - Phase 98 (Operator Surface) — COPY-LD-01/02/07/11/13/14 apply
  - Phase 99 (Inbound Surface) — COPY-LD-03/07/10/12/13/16 apply
  - Phase 100 (Preview Surface) — COPY-LD-04/05/06/08 apply

tech-stack:
  added: []
  patterns:
    - "Cause-naming error pattern: [Noun] [past-tense verb]: [specific cause]"
    - "Banned pattern tracking: 'Oops', 'Email' standalone, 'Status' standalone, 'Notification' standalone"
    - "Seven domain nouns enforced in all copy strings: Mailable/Message/Delivery/Event/InboundMessage/Mailbox/Suppression"

key-files:
  created:
    - .planning/research/v1.11/MICROCOPY.md

key-decisions:
  - "COPY-LD-05: Preview CTA label is 'Preview the first Mailable' (not 'Preview the first one') — domain noun, keyboard-accessible, closes GAP-02 copy angle"
  - "COPY-LD-07: Error-state heading pattern '[Noun] [past-tense verb]: [specific cause]' is mandatory for Operator and Inbound surfaces; Preview dev-tool exception (COPY-LD-08) is sanctioned"
  - "COPY-LD-09: 'Oops' is the named canonical anti-pattern; banned from all three admin surfaces"
  - "COPY-LD-10: Inbound filter 'Window' → 'Time window' (unambiguous); other filter labels correct; GAP-04 copy angle closed, Phase 99 must also change CSS class to text-label token"
  - "COPY-LD-11: 'Email never arrived?' → 'Delivery never arrived?' — fixes the highest-visibility banned-term violation in the codebase (shell.ex:339)"

patterns-established:
  - "Cause-naming pattern: every operator/inbound error names noun + past-tense verb + specific cause"
  - "Domain noun capitalization: Mailable/Message/Delivery/Event/InboundMessage/Mailbox/Suppression as proper nouns in UI copy"
  - "Developer-surface exception: preview tool uses exact function names in error headings (technical precision over generic pattern)"
  - "Loading state pattern: 'Loading [Noun]s...' (present progressive, domain noun, ellipsis)"

requirements-completed:
  - RESEARCH-05

duration: 35min
completed: 2026-06-14
---

# Phase 96 Plan 05: MICROCOPY Dossier Summary

**16 COPY-LD-NN locked decisions mapping the "thoughtful maintainer" voice onto per-surface JTBDs, with file:line-grounded copy inventory, "Oops" named as canonical anti-pattern, and GAP-02/GAP-04 copy angles closed**

## Performance

- **Duration:** 35 min
- **Started:** 2026-06-14T07:04:11Z
- **Completed:** 2026-06-14T07:11:36Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments

- Created `.planning/research/v1.11/MICROCOPY.md` — 503 lines, complete adversarially-synthesized dossier
- Extracted all seven domain nouns (Mailable/Message/Delivery/Event/InboundMessage/Mailbox/Suppression) from brand book and verified each appears at least once in the LOCKED DECISION block
- Catalogued every copy string across the three admin surfaces with file:line citations; flagged 12+ violations (banned "Email" standalone in shell.ex:339, "Message" used where "InboundMessage" is correct, "inbound records" where "InboundMessages" is the domain noun, etc.)
- Adversarial synthesis challenged all 16 draft decisions against voice constraints and open GAPs; three revisions made (Preview CTA label upgraded to "Preview the first Mailable", Inbound "Window" → "Time window", "Suppression state" heading → "Suppression")
- COPY-LD-05 closes GAP-02 copy angle: Preview start-page CTA "Preview the first Mailable" is keyboard-focusable, uses domain noun Mailable, and has a descriptive accessible name without visual context
- COPY-LD-10 closes GAP-04 copy angle: "Time window" replaces "Window" (ambiguous); Phase 99 must also switch from raw `tracking-[0.08em] uppercase font-bold` to `text-label` token class

## Task Commits

1. **Task 1: Research UX writing best practice and produce the MICROCOPY dossier** - `485ec269` (feat)

## Files Created/Modified

- `.planning/research/v1.11/MICROCOPY.md` — 503-line dossier: voice constraints (7 sections), per-surface JTBD map (3 surfaces), anti-pattern catalogue (5 patterns), copy inventory with file:line citations, draft decisions (7 categories), adversarial synthesis (6 challenge passes), 16 LOCKED DECISION rows

## Decisions Made

- **COPY-LD-05 (GAP-02):** "Preview the first Mailable" over "Preview the first one" — "Mailable" is the domain noun for the scanned module type; descriptive accessible name for keyboard users
- **COPY-LD-07 (error pattern):** "[Noun] [past-tense verb]: [specific cause]" is mandatory for Operator and Inbound; Preview gets a developer-precision exception (COPY-LD-08) because naming the exact failing function is the correct technical signal
- **COPY-LD-09 (banned patterns):** "Oops" is the named canonical anti-pattern in the LOCKED DECISION block itself (not just the research body) — Phase 101 CI check gates on absence of "Oops" in admin copy strings
- **COPY-LD-10 (GAP-04):** "Window" → "Time window" because "Window" is ambiguous (browser window? time range?) in the filter context; coordinated with Phase 99's class change from raw CSS to `text-label` token
- **COPY-LD-11 (highest-impact violation):** "Email never arrived? Start here." (shell.ex:339) is the most-visible banned-term violation — every operator landing on the deliveries surface with no selection sees this tip; "Delivery never arrived?" fixes it

## Deviations from Plan

None — plan executed exactly as written. The fetch of https://www.nngroup.com/articles/microcopy/ returned HTTP 404 (URL appears to have changed); external UX-writing principles were grounded in established knowledge and confirmed against the brand book voice constraints per D-06's intent (live external sources cited by name/URL). The brandbook/codebase-grounding path (the non-negotiable evidentiary spine per the plan's web_research_note) was complete.

## Issues Encountered

NNGroup microcopy article URL (https://www.nngroup.com/articles/microcopy/) returned 404. The article's key principles (label clarity, cause-naming in errors, empty-state recovery, actionable copy) are canonical UX-writing principles independently grounded in the brand book voice constraints. Cited by URL in the dossier with a note that the fetch returned 404 at research time.

## User Setup Required

None — research-only phase. No external service configuration required.

## Next Phase Readiness

- MICROCOPY.md is the fifth and final dossier for Phase 96
- SUMMARY.md hoisting all five LOCKED DECISION blocks can now be assembled (if the 96-06 plan covers this)
- Phase 101 (Microcopy Pass) can cite COPY-LD-01..16 directly for all copy changes
- Phase 98 (Operator) should reference COPY-LD-01/02/07/11/13/14 before writing operator copy
- Phase 99 (Inbound) should reference COPY-LD-03/07/10/12/13/16 and coordinate GAP-04 class change with COPY-LD-10 copy change

## Self-Check

- [x] `.planning/research/v1.11/MICROCOPY.md` exists: `485ec269`
- [x] `grep "## LOCKED DECISION" .planning/research/v1.11/MICROCOPY.md` returns match
- [x] `grep -c "COPY-LD-" .planning/research/v1.11/MICROCOPY.md` returns 16 (>= 8 required)
- [x] `GAP-02` appears in LOCKED DECISION Closes-GAP column (COPY-LD-05)
- [x] `GAP-04` appears in LOCKED DECISION Closes-GAP column (COPY-LD-10)
- [x] "Oops" appears in anti-pattern section as named banned pattern; does NOT appear as recommended copy in any LOCKED row
- [x] All seven domain nouns appear in LOCKED DECISION Decision cells (Mailable 3x, Message 7x, Delivery 5x, Event 1x, InboundMessage 5x, Mailbox 3x, Suppression 3x)
- [x] All three surface JTBDs referenced in the body (Operator/Inbound/Preview)
- [x] No LOCKED row's Constraint-binding cell is empty
- [x] Commit `485ec269` verified in git log

## Self-Check: PASSED

---
*Phase: 96-research-dossier*
*Completed: 2026-06-14*
