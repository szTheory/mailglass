---
phase: 87-logo-tournament
plan: 02
status: awaiting-final-winner
created: 2026-06-11
gallery: .planning/phases/87-logo-tournament/tournament/round-3.html
parent_pick: variant-8F
round: 3
rejection_count: 0
blocks: [task-3-promotion]
---

# Phase 87 Plan 02 Checkpoint — FINAL Winner Decision (pick or stop)

**Status: awaiting-final-winner.** Round 3 — the protocol's hard cap — is
built, pre-screened (60/60 PASS, see 87-pre-flight.md Round 3), and
browser-audited. Task 3 (promotion to the canonical 8-asset system) must NOT
start until the final winner is recorded below. No default may be inferred,
and **no round 4 exists under any circumstances**.

## Round 2 — what was reviewed (HISTORICAL)

The round-2 rendered-evidence gallery (still on disk for reference):

```
.planning/phases/87-logo-tournament/tournament/round-2.html
```

The round-1 baseline (option 8, "the shared light") is shown first; the six
variants follow. Each entry shows the same six cells as round 1: large light,
large dark, actual-size 16/32 px in a browser-tab mock, single-color
(currentColor), repository-header context, and a one-line rationale. A
whole-page dark section closes the gallery.

## Design examination (multimodal, pre-variant)

Option 8 was rendered large via Playwright and read with a graphic-design eye
before anything was drawn (screenshots: `tmp/87-logo-tournament/round-2/exam-*`).
Findings, which drove the variant field:

At display sizes the baseline's gestalt is exactly right — square and circle
read instantly as pane and lens, and the voided overlap reads as light, not
damage, because the solid outer half completes the circle. The mass balance is
off, though: a 96-unit solid square against 22-unit type stems makes the mark a
heavy block beside an airy word. The equal-sided sharp square drifts toward
folder and sticky-note vocabulary at 32 px and below, where the lens shrinks to
a bump on the edge. At 16 px the motif nearly disappears — the void subtends
about three pixels and the 14-unit overshoot below the pane reads as noise
rather than a boundary break. The 52-unit gap sits exactly at the
0.4 × mark-width bound and leaves mark and word reading as neighbors rather
than one unit. Each variant attacks one finding; the spinoff resolves them
together.

Two directions were explored and rejected before drawing: pane-as-outline-frame
with a solid lens (under even-odd geometry the lens always splits into
disconnected solid fragments where it crosses a frame bar — a guaranteed
severed read, violating the standing constraint) and rounded pane corners (a
solid rounded square enters badge/plate vocabulary).

## The field (unranked, after the baseline)

| ID | Family changed | Variant | One line |
|----|----------------|---------|----------|
| 8A | motif-intensity | the larger lens (r 34 → 40) | Only the lens grows; the shared light carries more of the mark and survives 16 px. |
| 8B | baseline | the corner light (lens straddles the bottom-right corner) | Breaks two edges at once; three quarters of the lens stay solid, so the circle never reads cut. |
| 8C | proportion | the portrait pane (96×96 → 84×100, flush to the type band) | A taller pane reads window, not folder, and locks exactly to x-height line and baseline. |
| 8D | gap | the tighter lockup (52 → 40 units) | Same mark, pulled 12 units closer — mark and word read as one unit, not neighbors. |
| 8E | weight | the lighter pane (pane 96 → 80 square, lens unchanged) | Less ink in the pane rebalances the mark toward the weight of the type; the lens gains rank. |
| 8F | SPINOFF (proportion + baseline + gap, lens r36) | the synthesis | The single-parameter wins combined: window proportion, two-edge break beside the g descender, one-unit lockup. |

Standing constraint honored throughout (from the option-2 rejection): nothing
reads as broken, severed, fractured, or bitten; every void reads as light
passing through. The corner-straddle variants (8B, 8F) were specifically
judged for the pac-man failure mode at 280 px
(`tmp/87-logo-tournament/round-2/marks-closeup.png`) and pass: the lit corner
is bounded by both shapes' edges and the solid circle mass wraps it from
outside.

All wordmark glyph paths are the round-1 originals, verbatim; the i dot is
untouched.

## Round-2 resume signals (HISTORICAL — superseded by the Round 3 protocol below)

1. **`winner 8X`** — one variant ID (8A–8F), with optional notes. Recorded
   verbatim in 87-decision-record.md under `## Round 2 Decision`; unblocks
   Task 3 (promotion to the canonical asset system in `brandbook-fable/assets/`).
   `winner baseline` is also valid if the round-1 original beats every variant.
2. **`round 3`** naming **at most 4** candidates plus what to adjust — one
   final single-parameter pass in the same evidence-strip format. **Round 3 is
   the hard cap:** the next pause after it is pick-or-stop. No round 4 exists
   under any circumstances.
3. **A full-field rejection — CIRCUIT BREAKER: STOP.** No further generation
   in this plan. The phase escalates to a re-brief discussion with the
   maintainer before any new drawing happens.

## Selection

- **Round-2 outcome:** `round 3` requested (the protocol's final round, ≤4
  candidates, hard cap). Direction locked: **8F — the synthesis** (portrait
  pane 84×100 + corner lens r36 + gap 40) is the maintainer's favorite.
- **Round-3 directive:** variations on the actual IMAGE in the mark
  (pictorial content, not just parameters), plus COLOR versions — the
  maintainer asked whether the identity is pure monochrome; answer recorded:
  mono was a constraint test, round 3 introduces the token-only color
  program (Ink / Glass / glass-deep / Ice / Mist, no gradients).
- **Standing constraints carry:** C-01..C-15 including no-broken-reads; mono
  single-path even-odd master remains a required deliverable per candidate.
- **Date:** 2026-06-11

Round-3 candidates (per the approved plan): 8F-1 as-is-in-color (control),
8F-2 the lit lens (Ice-filled void), 8F-3 imagery variation A (message made
visible in the light), 8F-4 imagery variation B (executor's design-exam
pick, same shared-light language). Final pause after round 3 is
**pick-or-stop** — no round 4.

## Round 3 — what to review (FINAL)

Open the rendered-evidence gallery from disk (no network needed):

```
.planning/phases/87-logo-tournament/tournament/round-3.html
```

The locked 8F mono baseline is shown first; the four candidates follow. Each
candidate keeps the standard six evidence cells (large light, large dark,
actual-size 16/32 px favicon row — active tab and header in COLOR, idle tab
mono — single-color, repository context, one-line rationale) plus a color row:
the large color expression on light and on dark. A whole-page dark section
closes the gallery. Candidate files (mono master + color-light + color-dark
each) live in `tournament/round-3/`.

### The field (unranked, after the baseline)

| ID | Imagery | Color program (light / dark) | One line |
|----|---------|------------------------------|----------|
| 8F-1 | 8F unchanged (control) | pane Ink + lens Glass / pane Mist + lens Ice | Answers "is this mono-only?" — the lit corner stays transparent. |
| 8F-2 | the lit lens — the shared light made VISIBLE | + lit quarter Ice / pane Mist + lens Glass + light Ice | The only candidate that changes how the light itself behaves; mono collapses back to the 8F void. |
| 8F-3 | the message line — one left-aligned line of mail through the pane | bar Ice / bar Glass on Mist | Message made visible in the light; simplifies away by design at favicon size. |
| 8F-4 | the through-light — a small echo light exits the opposite corner | entry Glass + exit Ice / entry Ice + exit Glass | In one side, out the other: see-through as a picture, not a parameter. |

Design-exam findings are in the gallery masthead. Standing constraints
C-01..C-15 all hold (60/60 PASS); every candidate's mono master is a single
even-odd path and reads correctly on its own; color fills are Phase 86 tokens
only — no gradients, no new hexes, no opacity; the wordmark paths and i dot
are the round-1 originals verbatim.

## Valid resume signals (verbatim protocol — PICK OR STOP)

1. **`winner {id}`** — any candidate ON THE TABLE: a round-3 id (8F-1..8F-4),
   any round-2 variant (8A–8F), or the round-1 baseline (option 8). Optional
   notes welcome. Recorded verbatim in 87-decision-record.md under
   `## Round 3 Decision`; unblocks Task 3 (promotion to the canonical asset
   system in `brandbook-fable/assets/`). All candidates passed every hard
   constraint, so best-available is a safe pick.
2. **`stop`** — ends the tournament with NO promotion. The phase escalates to
   a re-brief discussion with the maintainer before any new drawing happens.

There is no third signal. Requests for further variants cannot be honored in
this plan — round 3 is the protocol's hard cap.

## Final Selection

- *(awaiting maintainer — record the response verbatim here and in
  87-decision-record.md before Task 3 starts)*
