# Phase 82: Logo and SVG Asset System - Research

**Phase:** 82 - Logo and SVG Asset System
**Researched:** 2026-06-06
**Mode:** repo-grounded research
**Question:** What do we need to know to plan this phase well?

## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Phase Boundary

- Phase 82 updates the logo/SVG brandbook surface, not package code,
  product/admin implementation code, public APIs, release workflow, README,
  Hex.pm, HexDocs, launch copy, social copy blocks, visual specimens,
  validation scripts, PDFs, raster exports, font binaries, or vendor design
  files.
- The phase may add a durable logo-option review artifact under `brandbook/`
  and may update logo-specific wording in `brandbook/index.html`,
  `brandbook/brand-book.md`, `brandbook/README.md`, and final logo SVG files.
- Phase 82 must consume `BRAND-GAP-04`, `BRAND-GAP-05`, and `BRAND-GAP-06`.

#### Logo Direction

- Treat the current pane/message-fold SVG set as one credible draft direction,
  not final approval.
- Compare at least three compact, credible logo directions before selecting or
  refining the final system:
  - the current folded pane direction
  - a simplified pane/message-lines mark with no triangular fold
  - a more inspection/pane-forward mark
- Default final posture should stay wordmark-first and refine toward the
  simplest small-size-safe pane mark that supports "Mailglass makes email
  visible."
- The mark may suggest a pane, message fold, inspection surface, or visible
  email structure, but must avoid paper planes, mailbox-on-post imagery, chat
  bubbles, send arrows, glossy app-icon treatment, mascot logic, and
  unnecessary path complexity.

#### SVG Accessibility And Distribution

- Final SVGs must keep `role="img"`, `title`, `desc`, `viewBox`, and accessible
  labeling.
- Final SVGs must avoid raster images, embedded fonts, scripts,
  `foreignObject`, data/base64 payloads, and external references.
- Repeated `id="title"` and `id="desc"` should be replaced with unique IDs per
  asset unless the phase explicitly documents a non-inline distribution rule.
  The recommended default is unique IDs.
- Keep the primary lockup editable with live SVG text for source use. Keep
  favicon, icon mark, monochrome mark, and avatar path-only or shape-only where
  practical.
- Defer outlined wordmark exports unless a real launch/package/docs
  distribution surface needs pixel-exact typography. Do not introduce font
  binaries.

#### Small-Size, Monochrome, And Dark Use

- Review favicon and mark behavior at 16px and 32px.
- If the triangular fold reads like a document corner, envelope, or send arrow,
  simplify the mark rather than adding detail.
- Record final disposition for monochrome use, reversed/dark-background use,
  favicon use, and social avatar use.
- Monochrome assets should use simple `currentColor` construction where
  possible.

#### Brand And Token Alignment

- Preserve: "Mailglass makes email visible", "Mail you can see through", and
  "glass is a metaphor, not a visual excuse."
- Preserve Phase 81 visual discipline: restrained Glass accent, flat panes,
  modest radius, border-first construction, visible focus posture, no
  glassmorphism, no bevels, no glossy depth, no heavy shadows, and no decorative
  gradient or blob language.
- Use `brandbook/tokens.json` and `brandbook/tokens.css` as source color/type
  guidance for brandbook assets without implying product admin UI consumes them.

## Phase Requirements

| Requirement | Meaning for Phase 82 |
|---|---|
| LOGO-01 | Repo contains editable SVG assets for primary lockup, icon-only mark, monochrome mark, favicon, and social avatar. |
| LOGO-02 | Maintainer can compare multiple credible logo directions before final selection/refinement. |
| LOGO-03 | Mark works as a pane/message-fold or visible-email metaphor and avoids banned generic email/app-icon tropes. |
| LOGO-04 | Assets include accessible SVG metadata, transparent-background-friendly construction where appropriate, and no embedded raster/font files. |

## Summary

Phase 82 is a source-native logo review and final SVG pass. The current assets
already prove that the repo can carry compact editable SVGs, but they are one
draft direction only. The plan should create an auditable comparison artifact,
record the selected/refined direction, then update the final asset set and
logo-specific brandbook wording.

The strongest default direction is a simplified pane/message-lines mark without
the triangular fold. It keeps the pane and visible-email idea, reduces
small-size ambiguity, avoids paper-plane/send-arrow readings, and works well
for monochrome/currentColor variants. The current folded pane should remain in
the comparison as option A because it is credible and already implemented. The
inspection/pane-forward direction should be compared as option C because it
may better express "visible email", but it risks becoming abstract if it loses
message affordance.

## Architectural Responsibility Map

| Artifact | Role | Current state | Phase 82 responsibility |
|---|---|---|---|
| `brandbook/logo-options.md` | Durable logo-direction review | Missing | Add comparison of at least three credible directions, criteria, small-size notes, and final selected/refined direction. |
| `brandbook/assets/options/*.svg` | Source-native option sketches | Missing | Add lightweight editable option SVGs if visual comparison needs separate files. |
| `brandbook/assets/logo-primary.svg` | Primary lockup | Existing folded-pane draft with live text and repeated title/desc IDs | Update to selected/refined direction, keep live text editable, use unique accessible IDs. |
| `brandbook/assets/logo-mark.svg` | Icon-only mark | Existing folded-pane draft and repeated title/desc IDs | Update to selected/refined mark, keep simple path geometry, unique IDs. |
| `brandbook/assets/logo-monochrome.svg` | Single-color mark | Existing currentColor folded-pane draft and repeated title/desc IDs | Preserve currentColor construction, update shape/IDs/disposition. |
| `brandbook/assets/favicon.svg` | 32px favicon | Existing triangular fold may be ambiguous | Use the small-size-safe final mark, test/review 16px and 32px, unique IDs. |
| `brandbook/assets/social-avatar.svg` | Social avatar | Existing dark square with folded-pane mark and repeated title/desc IDs | Update to final mark, preserve dark/reversed disposition, unique IDs. |
| `brandbook/brand-book.md` | Source logo guidance | Wordmark-first guidance exists | Record Phase 82 final disposition and link/refer to option review. |
| `brandbook/index.html` | Direct-open brandbook preview | Displays draft logo assets | Update logo copy from "draft until Phase 82" to approved Phase 82 logo-system language after final assets land. |
| `brandbook/README.md` | Brandbook artifact guide | Lists assets generally | Add option-review artifact and final logo asset policy if needed. |

## Project Constraints

- No new dependencies or build pipeline.
- No product admin code changes.
- No root README/Hex.pm/HexDocs/landing/launch/social copy changes.
- No broad package allowlist or release workflow changes.
- No PNG/raster exports, PDFs, font binaries, Figma/vendor files, screenshots,
  generated contrast reports, or large asset packs.
- Use SVG, Markdown, CSS/JSON token references, and grep/xmllint validation.

## Standard Stack

### Core

- Editable SVG files under `brandbook/assets/`.
- Markdown review artifact under `brandbook/`.
- Existing token guidance from `brandbook/tokens.json` and `brandbook/tokens.css`.
- Static HTML preview in `brandbook/index.html`.

### Supporting

- `xmllint --noout` for SVG parse checks.
- `rg` for source assertions and banned SVG constructs.
- `git diff --check` for whitespace and patch sanity.
- `git diff --exit-code -- <out-of-scope paths>` for phase-boundary checks.

## Architecture Patterns

### Pattern 1: Review Artifact Before Final Asset Approval

`BRAND-GAP-04` exists because one draft direction was not enough. The executor
should create a durable `brandbook/logo-options.md` artifact before finalizing
assets. The artifact should compare at least three directions against concrete
criteria:

- small-size clarity at 16px and 32px
- wordmark-first fit
- brand center alignment
- forbidden trope avoidance
- monochrome/currentColor viability
- reversed/dark-background viability
- path complexity and editability
- accessible metadata and ID strategy

Recommended plan implication: include a human-readable selection section such
as "Selected direction" or "Final refinement" so future maintainers can audit
why the final SVGs changed.

### Pattern 2: Unique Accessible IDs Per SVG Asset

Current SVGs are valid standalone assets, but repeated `id="title"` and
`id="desc"` collide when more than one SVG is inlined in one document. The
preferred Phase 82 strategy is:

- `logo-primary.svg`: `mg-logo-primary-title`, `mg-logo-primary-desc`
- `logo-mark.svg`: `mg-logo-mark-title`, `mg-logo-mark-desc`
- `logo-monochrome.svg`: `mg-logo-monochrome-title`, `mg-logo-monochrome-desc`
- `favicon.svg`: `mg-favicon-title`, `mg-favicon-desc`
- `social-avatar.svg`: `mg-social-avatar-title`, `mg-social-avatar-desc`

Each `aria-labelledby` should reference the matching IDs in order.

### Pattern 3: Live Text For Source Lockup, Shape-Only For Compact Assets

The primary lockup can keep live SVG `<text>` so the source remains editable.
Compact assets should avoid font dependency:

- `logo-mark.svg`, `favicon.svg`, and `social-avatar.svg`: no wordmark text.
- `logo-monochrome.svg`: currentColor mark only.
- outlined wordmark export: deferred until a real distribution surface needs it.

### Pattern 4: Small-Size Simplicity Beats More Detail

The current lower triangular fold is the main ambiguity. At small sizes it can
read as a document corner, envelope, or send arrow. The best correction is
simplification: fewer strokes, no folded-corner triangle if ambiguity persists,
and a strong pane/message-line silhouette.

### Pattern 5: Brandbook Copy Status Must Change With The Asset Status

Phase 81 intentionally labels current logos as draft evidence until Phase 82.
When Phase 82 finalizes the logo system, `brandbook/index.html` and
`brandbook/brand-book.md` should stop saying "draft until Phase 82" for the
final logo assets. They should still leave Phase 83 copy/specimens and Phase 84
validation proof in their own phases.

## Don't Hand-Roll

- Do not introduce a design tool export pipeline.
- Do not add JS, CSS preprocessors, image optimizers, or font packages.
- Do not create raster social-card exports.
- Do not add product UI components or replace `mailglass_admin` static assets.
- Do not solve Phase 84 validation by adding committed validation scripts in
  this phase.

## Common Pitfalls

### Pitfall 1: Text-Only Option Review

A prose-only comparison is weak for LOGO-02. The option review should include
visual SVG evidence, either as separate option SVG files or compact inline SVG
source snippets that are easy to render and inspect.

### Pitfall 2: More Detail To Fix Small-Size Ambiguity

Adding detail usually makes a favicon worse. If the fold is ambiguous, remove
or simplify it. Prefer a simpler pane/message-lines mark.

### Pitfall 3: Solving Distribution With Font Binaries

The primary lockup can remain live text in source. Do not commit font binaries
or outlined text exports unless a real distribution surface requires them.

### Pitfall 4: Treating CurrentColor As Optional For Monochrome

The monochrome mark is useful because it can inherit color in stamps, compact
docs, print, and single-color contexts. Preserve simple currentColor use where
possible.

### Pitfall 5: Product UI Scope Creep

`mailglass_admin/priv/static/mailglass-logo.svg` is an older placeholder, but
Phase 82 context says not to touch product/admin implementation code. Leave it
for a future product integration phase.

## Code Examples

### Good Accessible SVG ID Shape

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 96 96" role="img" aria-labelledby="mg-logo-mark-title mg-logo-mark-desc">
  <title id="mg-logo-mark-title">Mailglass mark</title>
  <desc id="mg-logo-mark-desc">A simple pane mark representing visible email.</desc>
</svg>
```

### Banned SVG Constructs Check

```bash
! rg -n '<script|<image|foreignObject|data:|base64|https?://|@font-face|font-face' brandbook/assets/*.svg brandbook/assets/options/*.svg
```

### Fast Local Validation Commands

```bash
git diff --check -- brandbook/logo-options.md brandbook/brand-book.md brandbook/index.html brandbook/README.md brandbook/assets
xmllint --noout brandbook/assets/*.svg brandbook/assets/options/*.svg
rg -n 'BRAND-GAP-04|BRAND-GAP-05|BRAND-GAP-06|Selected direction|16px|32px|currentColor|reversed|unique ID' brandbook/logo-options.md brandbook/brand-book.md brandbook/index.html brandbook/README.md
! rg -n '<script|<image|foreignObject|data:|base64|https?://|@font-face|font-face|paper plane|chat bubble|mailbox-on-post|send arrow|mascot|glossy' brandbook/logo-options.md brandbook/assets/*.svg brandbook/assets/options/*.svg
```

## Environment Availability

| Tool | Availability | Use |
|---|---|---|
| `rg` | available | Text assertions, boundary checks, banned-construct checks. |
| `xmllint` | used by prior phases | SVG and HTML parse checks. |
| `git diff --check` | available | Whitespace and patch sanity. |
| Browser/dev server | not required | SVGs and static brandbook should be inspectable from disk. |

## Validation Architecture

### Test Framework

Phase 82 uses source assertions, XML parse checks, and manual visual review. No
test framework install is required.

| Property | Value |
|---|---|
| Framework | Existing CLI checks: `git diff --check`, `xmllint`, `rg` |
| Config file | None |
| Quick run command | `git diff --check -- brandbook/logo-options.md brandbook/brand-book.md brandbook/index.html brandbook/README.md brandbook/assets && xmllint --noout brandbook/assets/*.svg brandbook/assets/options/*.svg` |
| Full suite command | Quick run command plus source assertion greps, banned SVG construct checks, and out-of-scope diff checks |
| Estimated runtime | Less than 30 seconds for phase-specific checks |

### Phase Requirements -> Test Map

| Requirement | Verification approach |
|---|---|
| LOGO-01 | Final five SVG files exist and parse with `xmllint`; primary lockup, mark, monochrome mark, favicon, and social avatar are all editable SVG. |
| LOGO-02 | `brandbook/logo-options.md` compares at least three directions and records selected/refined direction. |
| LOGO-03 | Review artifact and final SVG descriptions avoid paper planes, mailbox-on-post imagery, chat bubbles, send arrows, glossy app icons, mascots, and unnecessary path complexity; manual review checks visual metaphor. |
| LOGO-04 | SVGs include `role="img"`, title/desc metadata, viewBox, unique accessible IDs, no raster/font/script/foreignObject/data/external references. |

### Sampling Rate

- After every task commit: run the quick command and task-specific `rg` checks.
- After the plan wave: run the full source assertion set and manual visual
  review steps.
- Before `$gsd-verify-work`: parse all SVGs, check banned constructs, confirm
  final logo docs reflect Phase 82 completion, and confirm out-of-scope paths
  are unchanged.
- Max feedback latency: 30 seconds for Phase 82-specific automated checks.

### Wave 0 Gaps

No test infrastructure is missing. Option SVG files do not exist before Task 1,
so checks that include `brandbook/assets/options/*.svg` become active after the
option-review task creates them.

## Security Domain

Security enforcement is effectively enabled by default for this workflow.
Phase 82 is low-risk static asset work, but SVGs can still introduce active
content, external references, misleading accessible names, or publication scope
drift.

### Applicable Threat Patterns

| Threat | STRIDE | Planning control |
|---|---|---|
| SVG active content or external reference | Tampering / information disclosure | Reject script, image, foreignObject, data/base64, http(s), font-face, and external href references. |
| Accessible names collide when SVGs are inlined | Spoofing / repudiation | Use unique title/desc IDs per asset and matching aria-labelledby values. |
| Draft option confused with final asset | Repudiation | Keep option files/review artifact clearly labeled and record selected/refined final direction. |
| Generic email trope weakens brand distinctiveness | Spoofing / brand confusion | Require banned trope review in option artifact and manual visual review. |
| Product/admin code scope creep | Tampering / maintainability risk | Keep product UI, package files, release workflow, and public copy out of scope. |

## Assumptions Log

| ID | Assumption | Confidence | Impact |
|---|---|---|---|
| A1 | A single non-autonomous plan can cover review, selection checkpoint, final assets, and docs because all writes are in `brandbook/`. | Medium | Planner can keep one plan if it includes a human selection gate. |
| A2 | The simplified pane/message-lines direction is the strongest default if maintainer does not request a different final direction. | Medium | Reduces small-size ambiguity while preserving the brand center. |
| A3 | Separate option SVGs under `brandbook/assets/options/` are acceptable because they are source-control-friendly and support LOGO-02. | Medium | Provides visual comparison without raster/vendor artifacts. |
| A4 | Product admin placeholder logo replacement is intentionally out of scope for Phase 82. | High | Prevents product UI scope creep. |

## Open Questions (Resolved)

No unresolved planning questions. The user selected research first. The only
expected execution-time decision is maintainer review/selection of the final
logo direction if the executor cannot confidently apply the default simplified
pane/message-lines refinement.

## Sources

### Primary - Repo (HIGH confidence)

- `.planning/phases/82-logo-and-svg-asset-system/82-CONTEXT.md` - locked decisions, phase boundary, canonical references, deferred items. [VERIFIED: repo file read]
- `.planning/REQUIREMENTS.md` - LOGO-01, LOGO-02, LOGO-03, LOGO-04. [VERIFIED: repo file read]
- `.planning/ROADMAP.md` - Phase 82 goal and success criteria. [VERIFIED: repo file read]
- `.planning/STATE.md` - v1.8 correction, scope locks, and current phase position. [VERIFIED: repo file read]
- `.planning/phases/80-brand-audit-and-gap-register/80-CONTEXT.md`, `80-RESEARCH.md`, `80-PATTERNS.md`, `80-01-PLAN.md`, `80-01-SUMMARY.md`, `80-VERIFICATION.md` - logo handoff rows and audit/register precedent. [VERIFIED: repo file read]
- `.planning/phases/81-brandbook-source-and-token-system/81-CONTEXT.md`, `81-RESEARCH.md`, `81-PATTERNS.md`, `81-01-PLAN.md`, `81-01-SUMMARY.md`, `81-VERIFICATION.md` - Phase 81 draft-status language and brandbook source posture. [VERIFIED: repo file read]
- `brandbook/brand-audit.md` - `BRAND-GAP-04`, `BRAND-GAP-05`, `BRAND-GAP-06` rows and Phase 82 handoff. [VERIFIED: repo file read]
- `brandbook/brand-book.md`, `brandbook/index.html`, `brandbook/README.md`, `brandbook/tokens.json`, `brandbook/tokens.css`, `brandbook/assets/*.svg` - Phase 82 implementation inputs. [VERIFIED: repo file read]
- `mailglass_admin/docs/design-system.md` and `mailglass_admin/priv/static/mailglass-logo.svg` - read-only product UI boundary evidence. [VERIFIED: repo file read]

## Metadata

**Confidence breakdown:**

- Scope: HIGH - locked by Phase 82 context and Phase 80 audit rows.
- Architecture: MEDIUM-HIGH - static SVG/Markdown/HTML work is straightforward, but final logo selection includes visual judgment.
- Validation: MEDIUM-HIGH - parse/grep checks cover safety and metadata; manual review is still required for visual metaphor quality.
- Security: MEDIUM - low-risk static assets, but SVG active-content and accessible-name risks are real enough to plan explicitly.

**Research date:** 2026-06-06
**Valid until:** 2026-07-06 for repo-scoped planning; re-read Phase 80-82 artifacts if brandbook assets change before execution.

## RESEARCH COMPLETE

