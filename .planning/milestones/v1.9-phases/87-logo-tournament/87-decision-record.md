# Phase 87 Decision Record — The Mailglass Fable Logo

**Decided:** 2026-06-11
**Winner:** 4D — "the sealed flap"
**Canonical assets:** `brandbook-fable/assets/` (8 files, see mapping below)

## The selected identity

A landscape envelope pane whose fold and seal are drawn entirely in light:
the flap is a triangle of light descending from the top edge, and a circular
seal straddles the bottom edge — lit inside the pane, solid outside it. The
envelope is never outlined; light does all the drawing. One even-odd path in
mono; two layered fills in color.

**Geometry (canonical):** landscape pane ~140×96 on the LOGO-CRAFT grid,
flap-of-light triangle from the top corners to center, seal circle centered
on the bottom edge. Wordmark: the round-1 hand-drawn "mailglass" paths
(x-height 100, stem 22, optical corrections), verbatim, untouched i dot.

**Color program (tokens only, no gradients):**

| Context | Pane | Seal (outer half) | Light regions |
|---|---|---|---|
| Light surfaces | Ink `#0D1B2A` | Glass `#277B96` | background shows through |
| Dark surfaces | Mist `#EAF6FB` | Ice `#A6EAF2` | background shows through |
| Mono / hostile contexts | currentColor single even-odd path | — | voids |

**Usage rules:**
- `logo-primary.svg` is the light-surface flagship. On dark surfaces use
  `logo-monochrome.svg` (currentColor inherits the page's light text color)
  or the dark expressions (`social-avatar-dark.svg` pattern: Mist pane + Ice
  seal). Never place the light-expression primary on a dark surface — the
  Ink pane vanishes.
- `favicon.svg` self-adapts: the pane flips Ink→Mist under
  `prefers-color-scheme: dark`; the Glass seal holds in both themes.
- `logo-with-tagline.svg` is the ONLY asset carrying the subtitle
  ("Email, made visible." in Slate, outlined paths).

## Asset mapping (for downstream consumers)

| File | What it is |
|---|---|
| `logo-primary.svg` | Mark + wordmark tight lockup, light color expression — the flagship |
| `logo-typemark.svg` | Standalone hand-drawn wordmark, currentColor-friendly |
| `logo-mark.svg` | Mark alone, light color expression |
| `logo-monochrome.svg` | Lockup as pure currentColor (single even-odd mark path) — dark/hostile contexts |
| `logo-with-tagline.svg` | Primary + outlined tagline (only subtitle-bearing asset) |
| `favicon.svg` | 16-grid redraw, 2 shape elements, OS-dark adaptive |
| `social-avatar.svg` | Square canvas (documented plate exception), light expression |
| `social-avatar-dark.svg` | Square canvas, dark expression (Mist pane + Ice seal on Ink) |

The Phase 85 brief manifest names `logo-mark-mono.svg` / `social-avatar-light.svg`;
the shipped names above are canonical (locked by 87-CONTEXT). Phases 88-90
reference the shipped names.

## Tournament history (4 rounds, rejection_count 0 throughout)

| Round | Field | Maintainer outcome |
|---|---|---|
| 1 | 8 options, 2 per axis (typemark / lockup / monogram / negative space), 112/112 pre-flight | Picked **option 8 "the shared light"** (pane + edge lens, even-odd void-as-light). Option 2 rejected with the note that its sheared `l` "reads broken" → standing constraint C-15. |
| 2 | 6 variants of option 8 (5 single-parameter + 1 spinoff), 90/90 pre-flight | Liked **8F "the synthesis"** (portrait pane 84×100 + corner lens r36 + gap 40); requested round 3: imagery variations + color. |
| 3 | 4 candidates, each in mono + color program, 60/60 pre-flight | Liked **8F-1 in color** (Ink pane + Glass lens / Mist + Ice on dark); directed a 4th round exploring envelope reading. |
| 4 | 4 envelope-in-light candidates (maintainer-directed extension; fallback winner 8F-1), 64/64 pre-flight incl. no-codex-convergence | **Picked 4D "the sealed flap"** — the only candidate whose flap and seal both survive at 16px. |

## Standing constraints that emerged (binding on all future brand work)

1. **No broken reads (C-15):** nothing may read as broken, severed,
   fractured, or bitten. Voids always read as light passing through.
2. **Envelope by light only (C-16):** the envelope is suggested through
   composition and light — never a drawn outline, zigzag flap line, or any
   construction shared with the codex baseline's literal envelope mark.
3. All original hard constraints hold: no background plates (square social
   avatars are the sole documented exception), boundary-breaking marks,
   tight lockups, no subtitle in the main lockup, untouched i dot, no
   glassmorphism/paper-planes/mailboxes/send-arrows/mascots.

## Rejected-evidence index (do not revive)

- Round 1 options 1-7 and round 2/3/4 non-winners:
  `.planning/phases/87-logo-tournament/tournament/{options,round-2,round-3,round-4}/`
- Galleries: `tournament/round-{1,2,3,4}.html`
- Pre-flight evidence: `87-pre-flight.md` (326 rows total, all PASS)
