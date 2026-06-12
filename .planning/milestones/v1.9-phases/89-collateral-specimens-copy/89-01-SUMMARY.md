---
phase: 89-collateral-specimens-copy
plan: 01
subsystem: brand
tags: [brandbook, collateral, copy, svg, email-html, specimens]

# Dependency graph
requires:
  - phase: 85-research-and-differentiation-brief
    provides: manifest + budgets, compositional stance (left-aligned, documentation-like), banned motifs
  - phase: 87-logo-tournament
    provides: canonical lockup/wordmark/tagline path data, color program, usage rules (primary never on dark)
  - phase: 88-brand-book-assembly
    provides: index.html shell with slot-ready section 08 grid, theme-toggle pattern, masthead inline-mark pattern
provides:
  - brandbook-fable/examples/landing-page.html — self-contained, token-driven landing blueprint (hero, install, features, code, Swoosh comparison, footer)
  - brandbook-fable/examples/email-template.html — client-safe magic-link transactional specimen (tables, inline styles, both metas, VML, zero img/svg/tracking)
  - brandbook-fable/examples/readme-header.svg — dual-GitHub-theme banner, fills restricted to Glass + Slate
  - brandbook-fable/examples/docs-page.svg — hexdocs-style framing with greeked hierarchy
  - brandbook-fable/examples/og-card.svg — 1200x630 source template with PNG export policy in its desc
  - brandbook-fable/examples/diagram-language.svg — legend + worked Mailable→Message→Delivery→Event flow with stencil path labels
  - brandbook-fable/copy/copy-blocks.md — paste-ready per-surface copy, every fact repo-verified
  - brandbook-fable/copy/microcopy.md — 7 nouns x 4 states, taxonomy-consistent UX strings
  - index.html section 08 renders all six specimens (the 21-file manifest is complete)
affects: [90-quality-gate]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - file-based SVG specimens on fixed light chips inside the book (file SVGs cannot follow the page toggle; chips keep them deterministic)
    - README-facing SVG fills restricted to colors computed >= 3:1 on both #FFFFFF and #0d1117 (single-design dual-theme survival)
    - stencil letterform set for diagram labels — integer-grid mono-weight strokes as filled paths, label craft distinct from wordmark craft
    - copy single-source rule — landing hero/blurbs are the verbatim source for copy-blocks.md

key-files:
  created:
    - brandbook-fable/examples/landing-page.html
    - brandbook-fable/examples/email-template.html
    - brandbook-fable/examples/readme-header.svg
    - brandbook-fable/examples/docs-page.svg
    - brandbook-fable/examples/og-card.svg
    - brandbook-fable/examples/diagram-language.svg
    - brandbook-fable/copy/copy-blocks.md
    - brandbook-fable/copy/microcopy.md
    - .planning/phases/89-collateral-specimens-copy/89-visual-audit.md
  modified:
    - brandbook-fable/index.html

key-decisions:
  - "readme-header recolors the lockup to Glass (mark + wordmark) and keeps the tagline in Slate — the only token pair computed >= 3:1 on both GitHub grounds; Slate restricted to the display-size tagline because its dark-ground margin (3.46) is thin for small text"
  - "og-card and diagram-language reuse exact canonical path data and wrap it; no glyph was redrawn"
  - "diagram node labels use a purpose-built uppercase stencil set (14 glyphs, straight segments + integer diagonals) instead of reusing wordmark glyphs — label craft, per plan"
  - "email masthead is type-only in the web-safe stack; the production-logo note says PNG or JPG without naming the vector format (gate: zero svg substring)"
  - "Hex.pm description block ships the verbatim mix.exs string rather than a rewrite — the most honest paste-ready value"

patterns-established:
  - "Specimen chips: fixed Paper background + 1px border inline-styled on section 08 figures so light-expression artwork stays deterministic in both book themes"
  - "Copy honesty pass: every mix task named in shipped copy must have a matching lib/mix/tasks/{name}.ex (gate-enforced), task names always backtick-wrapped so trailing punctuation never enters the match"

requirements-completed: [COLL-01, COLL-02, COLL-03, COPY-01, COPY-02]

# Metrics
duration: 28min
completed: 2026-06-12
---

# Phase 89 Plan 01: Collateral, Specimens, and Copy Library Summary

**All eight remaining manifest files shipped — landing + email HTML specimens, four portable SVGs, two copy libraries — slotted into the book's section 08 grid and proven with a three-iteration visual audit ending zero-defect.**

## Performance

- **Duration:** 28 min
- **Started:** 2026-06-12T02:06:39Z
- **Completed:** 2026-06-12T02:34:30Z
- **Tasks:** 4/4
- **Files modified:** 10 (8 created in brandbook-fable/, 1 index.html edit, 1 audit record)

## Accomplishments

1. **landing-page.html (13,923 B / 50 KB budget)** — self-contained from file://, left-anchored documentation composition, token-driven with the index.html three-state toggle pattern, hero with the inline token-drawn mark, working install snippet (`{:mailglass, "~> 1.5"}` + `mix mailglass.install`), six-feature asymmetric grid, a code block whose every symbol exists in the repo, a calm "Why not just Swoosh?" comparison, and a fragment-href footer for find-and-replace deployment.
2. **email-template.html (5,834 B / 50 KB budget)** — magic-link sign-in specimen: nested presentation tables at 600px, all styles inline, both color-scheme metas + `:root{color-scheme:light dark}` + an Apple Mail dark block, mid-tone token hexes only (no #FFFFFF/#000000/shorthand), bulletproof CTA with `<!--[if mso]>` VML fallback, hidden preheader, zero `<img>`, zero svg substring, zero tracking of any kind.
3. **Four SVG specimens (all within budget)** — readme-header (9,564 B), docs-page (4,080 B), og-card (9,820 B), diagram-language (6,864 B). All: outlined paths only, viewBox, `role="img"` + prefixed-id `<title>`/`<desc>`, explicit six-digit token hexes, no gradients/filters/scripts/external refs/currentColor.
4. **copy-blocks.md (4,013 B)** — all 8 sections; GitHub About measured at 244 chars; hero/subhead/blurbs verbatim-identical to landing-page.html; release-note template with a real `mix mail.doctor --format json` example.
5. **microcopy.md (4,526 B)** — 28 strings across the seven nouns; Anymail taxonomy used correctly (rejected with reject_reason, deferred, complained, unknown); the Delivery success string carries the dispatch ≠ delivered distinction explicitly.
6. **index.html slot-in** — six section 08 figures now render real collateral (4 imgs on fixed light chips, 2 lazy iframes with open-the-file links); every Phase 88 gate re-passed including the CSS-URL check (0 hits) and the 8-asset-filename loop.

## Verified facts (honesty pass)

| Claim in copy/specimens | Verified against |
|---|---|
| `{:mailglass, "~> 1.5"}`, `{:mailglass_admin, "~> 1.5", only: [:dev]}` | README.md lines 61-62 |
| Elixir ~> 1.18, OTP 27+, Phoenix ~> 1.8, PostgreSQL 14+, Swoosh ~> 1.25 | README.md lines 28-34 |
| `use Mailglass.Mailable, stream: :transactional`, `new/to/from/subject/html_body/text_body`, `Mailglass.Message.put_function/2` | README quickstart + lib/mailglass/mailable.ex, lib/mailglass/message.ex:310 |
| `Mailglass.deliver/2`, `deliver_later/2`, `deliver_many/2` | lib/mailglass.ex defdelegates |
| mix tasks: mailglass.install, mail.doctor, mailglass.gen.mailable, mailglass.gen.mailbox, mailglass.suppressions.resync | lib/mix/tasks/*.ex (gate-enforced existence) |
| Hex.pm description string | mix.exs line 20 (verbatim) |
| preview dashboard tabs/toggles, RFC 8058 signed tokens, append-only trigger, webhook auto-suppression, mail.doctor cannot_verify + --format json schema_version: 1 | README.md + guides/jobs.md |

## Computed contrast (readme-header fills — actual figures)

| Fill | on #FFFFFF | on #0d1117 | Verdict |
|---|---|---|---|
| Glass #277B96 (mark + wordmark) | **4.817** | **3.929** | PASS both |
| Slate #5C6B7A (display-size tagline only) | **5.470** | **3.460** | PASS both; thin dark margin, so Slate is never used for small text in this file |

(The plan's interface block claimed 4.86/3.90/5.39/3.51; the recomputed values above are authoritative.)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed diagram-language flow arrows overrunning into nodes**
- **Found during:** Task 4 visual audit, iteration 1
- **Issue:** connector lines were drawn 88px into a 60px inter-node gap; arrowheads landed inside the next pane, touching the stencil labels
- **Fix:** recomputed geometry — lines x+176 → x+214, 12px heads ending 4px clear of the next node's stroke
- **Files modified:** brandbook-fable/examples/diagram-language.svg
- **Commit:** e2d47b57

**2. [Rule 1 - Bug] Unescaped `~&gt;` to `~>` in landing-page code blocks**
- **Found during:** Task 1 gate run
- **Issue:** HTML-escaping the version pin broke the literal `~> 1.5` gate (and raw `>` is valid in HTML text content anyway)
- **Fix:** replaced all `~&gt;` with `~>`
- **Files modified:** brandbook-fable/examples/landing-page.html
- **Commit:** 64f1d099

No other deviations — plan executed as written.

## Known Stubs

None functional. The `href="#"` links in both HTML specimens are the plan-specified find-and-replace deployment targets (documented in each file's header comment), not missing wiring.

## Task Commits

| Task | Commit | Type |
|---|---|---|
| 1 — HTML specimens | 64f1d099 | feat |
| 2 — SVG specimens | a2919b58 | feat |
| 3 — Copy library | 0708c696 | feat |
| 4 — Slot-in + audit fix | e2d47b57 | feat |
| 4 — Audit record | b2467edd | docs |

## Gate Results

- T1-GATES-PASS, T2-GATES-PASS, T3-GATES-PASS, T4-GATES-PASS (each consolidated command printed its token)
- Phase 88 re-runs: CSS-URL check 0 hits; all 8 asset filenames still referenced; index 79,789 B (≤ 153,600); 91 script lines (≤ 150); 9 headings present
- Whole-folder denylist: 0 hits; folder ≤ 500 KB; no file > 100 KB; all 21 manifest files present
- Working tree outside brandbook-fable/ and .planning/ identical to the pre-phase baseline (empty diff)

## Self-Check: PASSED

All 10 created files present on disk; all 5 task commits present in git history.
