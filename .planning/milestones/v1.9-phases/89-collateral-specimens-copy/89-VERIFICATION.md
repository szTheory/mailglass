---
phase: 89-collateral-specimens-copy
verified: 2026-06-11T00:00:00Z
status: passed
score: 6/6 must-haves verified
overrides_applied: 0
---

# Phase 89: Collateral, Specimens, and Copy Library — Verification Report

**Phase Goal:** Every real launch surface — landing page, transactional email, README, docs, social card, diagrams, and per-surface copy — has a deployable, brand-true specimen in the fable system
**Verified:** 2026-06-11
**Status:** passed
**Re-verification:** No — initial verification

All evidence below is from independent re-execution: fresh greps, xmllint, a self-computed WCAG contrast script, repo-fact greps against `lib/` + `mix.exs` + `README.md`, and a fresh Playwright render run to `/tmp/fable-89-verify/` (11 screenshots, all read). SUMMARY.md and 89-visual-audit.md claims were not taken as evidence.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | landing-page.html is a full self-contained, find-and-replace-deployable blueprint (hero, install snippet, feature grid, code block, comparison row, footer) [COLL-01 / SC1] | VERIFIED | Zero `https?://` strings anywhere in the file; zero fetch/XHR/script-src; all nav/CTA/footer links are `href="#"` fragments; only subresources are `../tokens.css` + `../assets/favicon.svg` (both resolve). All six sections present (lines 150-251). Playwright renders at 1440px and 390px, light AND dark, read from screenshots: left-anchored composition, hero mark redrawn from live tokens in both themes, code blocks legible, no overflow at 390 |
| 2 | email-template.html is email-client-safe: table-based, inline styles, both color-scheme metas [COLL-02 / SC2] | VERIFIED | 5 `<table role="presentation">`, all styles inline, `name="color-scheme"` + `supported-color-schemes` metas both present, `:root { color-scheme: light dark }` + `@media (prefers-color-scheme: dark)` block, `width="600"`/`max-width:600px`, `<!--[if mso]>` VML roundrect fallback. Zero `svg` substring (case-insensitive), zero `<img>`, zero `track`/1x1 patterns, zero flex/grid, zero rem, zero #FFFFFF/#000000/3-digit hex. Rendered at 620px light + dark — card, CTA, footer all intact; dark scheme flips correctly |
| 3 | SVG specimens cover README header, docs framing, 1200×630 og-card with PNG export policy, diagram-language spec [COLL-03 / SC3] | VERIFIED | All four xmllint-parse clean; each carries viewBox + role="img" + `<title>`; zero `<text>`, zero `font-family`, zero `currentColor`, zero gradients/filters/scripts/external refs. readme-header fills are exactly #277B96 (×11) and #5C6B7A (×18); contrast recomputed from the WCAG formula: Glass 4.82:1 on #FFFFFF / 3.93:1 on #0d1117, Slate 5.47:1 / 3.46:1 — all ≥3:1. og-card `viewBox="0 0 1200 630"` with PNG export policy in its `<desc>` ("export a 1200 by 630 PNG locally... crawlers do not render vector images"). diagram-language `<title>`/`<desc>` name Mailable → Message → Delivery → Event verbatim and state "Dispatch is not delivery". Rendered on #FFFFFF AND #0d1117 grounds and read: readme-header fully legible on both; the other three carry their own light grounds and read on both |
| 4 | copy-blocks.md is paste-ready: 8 surfaces, GitHub About ≤350 chars, no placeholders/lorem, facts repo-true [COPY-01 / SC4] | VERIFIED | All 8 `##` sections present. About blockquote = 244 chars (≤350). Hype denylist (lorem/ipsum/blazing/supercharge/10x/oops) = 0 hits. Hex.pm description matches `mix.exs` `description:` verbatim. Hero headline + subhead + all 6 feature blurbs verbatim-identical between copy-blocks.md and landing-page.html (grep -cF = 1 in each). Every named mix task has a real file: lib/mix/tasks/{mail.doctor, mailglass.install, mailglass.gen.mailable, mailglass.gen.mailbox, mailglass.suppressions.resync}.ex. Release-note example facts verified: `mail.doctor --format json` (mail.doctor.ex:19,76) and `schema_version: 1` (deliverability/result.ex:22) |
| 5 | microcopy.md keys all 7 nouns × 4 states (≥28 entries), taxonomy-consistent [COPY-02 / SC5] | VERIFIED | `## {Noun}` header for each of Mailable, Message, Delivery, Event, InboundMessage, Mailbox, Suppression in canonical order; `^| Error`/`^| Empty`/`^| Success`/`^| Warning` each count 7 → 28 entries. Preamble cites the full 14-term Anymail taxonomy. Delivery Success row explicitly distinguishes "Dispatched is not delivered". `reject_reason: invalid` used correctly. Error style specific-and-composed (the canonical "Delivery blocked: recipient is on the suppression list" string ships verbatim); zero "Oops" |
| 6 | index.html section 08 renders the specimens and still passes its Phase 88 gates (plan must-have) | VERIFIED | 12 `examples/` refs (6 src + 6 "Open the file" hrefs) covering all 6 specimens; four SVGs on fixed Paper #F8FBFD light chips, two iframes for the HTML files. All Phase 88 gates re-run and pass: 0 external URLs/fetch/script-src/XHR, 79,789 bytes ≤150KB, noscript ≥1, getComputedStyle ≥1, data-theme ≥2, "16.74" and "4.82" present, all 9 section headings, all 8 canonical asset filenames referenced, script-line count 91 ≤150. Section 08 rendered at 1440 light + dark and 390 light: all six figures render, light chips hold in dark mode, iframes load their light specimens |

**Score:** 6/6 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `brandbook-fable/examples/landing-page.html` | Self-contained landing blueprint, min 200 lines | VERIFIED | 279 lines / 13,923 B (≤51,200); substantive, wired into index iframe |
| `brandbook-fable/examples/email-template.html` | Client-safe transactional specimen, min 100 lines | VERIFIED | 122 lines / 5,834 B; substantive, wired into index iframe |
| `brandbook-fable/examples/readme-header.svg` | Dual-theme GitHub banner | VERIFIED | 9,564 B (≤20,480); Glass/Slate fills only, no background rect |
| `brandbook-fable/examples/docs-page.svg` | HexDocs framing specimen | VERIFIED | 4,080 B (≤24,576); greeked bars, no text elements |
| `brandbook-fable/examples/og-card.svg` | 1200×630 social template + PNG policy | VERIFIED | 9,820 B (≤20,480); policy in desc |
| `brandbook-fable/examples/diagram-language.svg` | Diagram spec with noun flow | VERIFIED | 6,864 B (≤24,576); legend + Mailable→Message→Delivery→Event flow with stencil-path labels |
| `brandbook-fable/copy/copy-blocks.md` | Per-surface copy library | VERIFIED | 4,013 B (≤10,240); 8 sections |
| `brandbook-fable/copy/microcopy.md` | 7-noun × 4-state strings | VERIFIED | 4,526 B (≤10,240); 28 table rows |
| `.planning/phases/89-collateral-specimens-copy/89-visual-audit.md` | Playwright audit record | VERIFIED | 37 lines; 3 iterations logged, dark + 390 + #0d1117 grounds covered, real defect found/fixed in iteration 1 (diagram arrow overrun), final zero-defect pass with pixel assertions |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| index.html | examples/* | section 08 figures | WIRED | 6 img/iframe src + 6 figcaption hrefs, all resolve on disk |
| landing-page.html | tokens.css | relative stylesheet | WIRED | `<link rel="stylesheet" href="../tokens.css">` line 9; every color routes through `var(--mg-*)` |
| copy-blocks.md | landing-page.html | hero + blurbs verbatim | WIRED | Headline, subhead, and all 6 blurbs grep -F identical in both files |
| microcopy.md | Anymail taxonomy | event vocabulary | WIRED | Full 14-term taxonomy in preamble; bounced/deferred/complained/rejected/unsubscribed used correctly in rows |

### Data-Flow / Behavioral Evidence (independent render run)

| Surface | Command/Check | Result | Status |
|---------|---------------|--------|--------|
| landing 1440/390 × light/dark | Playwright file:// screenshots, read | All sections render, toggle/theme re-skins, mark visible both themes, no 390 overflow | PASS |
| email 620 × light/dark | Playwright screenshots, read | Table card + bulletproof CTA intact; dark `prefers-color-scheme` block applies | PASS |
| 4 SVGs on #FFFFFF + #0d1117 | img harness, screenshots read | readme-header legible on both grounds; others carry own light grounds | PASS |
| index section 08, 1440 light/dark + 390 | screenshots read | Six figures render; Paper chips hold in dark; iframes load | PASS |
| WCAG ratios | python3 relative-luminance recompute | Glass 4.82/3.93, Slate 5.47/3.46 — all ≥3:1 | PASS |
| Repo facts | grep lib/, mix.exs, README | put_function (message.ex:310), deliver/deliver_later/deliver_many (mailglass.ex:120-128), `stream: :transactional` (mailable.ex:8), cannot_verify (dkim.ex), env reqs match README Requirements block | PASS |

### Requirements Coverage

| Requirement | Source Plan | Status | Evidence |
|-------------|-------------|--------|----------|
| COLL-01 | 89-01 | SATISFIED | Truth 1 |
| COLL-02 | 89-01 | SATISFIED | Truth 2 |
| COLL-03 | 89-01 | SATISFIED | Truth 3 |
| COPY-01 | 89-01 | SATISFIED | Truth 4 |
| COPY-02 | 89-01 | SATISFIED | Truth 5 |

No orphaned requirements: REQUIREMENTS.md maps exactly these five IDs to Phase 89.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | — | — | None. Whole-folder process-vocabulary denylist = 0 hits; TBD/FIXME/XXX/HACK = 0; zero "Oops"; zero hype words; zero placeholders/lorem |

Note (info-level, not a gap): the Launch post block contains a `[link]` slot and the footers use `href="#"` — both are the plan's explicit find-and-replace deployment pattern, not placeholders in the stub sense.

### Scope / Hygiene

- Folder total: 256 KB ≤ 500 KB; largest file index.html at 79.8 KB ≤ 100 KB.
- Frozen `brandbook/`: `git diff 03e54c43..HEAD -- brandbook/` is empty.
- No stray changes: `git diff --name-only 03e54c43..HEAD` touches only `brandbook-fable/` and `.planning/`; working tree clean.

### Human Verification Required

None at this phase. Aesthetic/A-B sign-off is explicitly Phase 90's success criterion 3 (maintainer A/B walkthrough against the codex baseline) — routing it there per the roadmap, and all renderable behavior was self-verified by screenshot reads above.

### Gaps Summary

No gaps. All five ROADMAP success criteria plus the plan's index-integration must-have are observably true in the codebase, proven by independent re-execution of every gate.

---

_Verified: 2026-06-11_
_Verifier: Claude (gsd-verifier)_
