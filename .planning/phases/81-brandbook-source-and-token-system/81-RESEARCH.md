# Phase 81: Brandbook Source and Token System - Research

**Phase:** 81 - Brandbook Source and Token System
**Researched:** 2026-06-06
**Mode:** repo-grounded research
**Question:** What do we need to know to plan this phase well?

## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Phase Boundary

- Phase 81 modifies exactly four source artifacts:
  - `brandbook/index.html`
  - `brandbook/brand-book.md`
  - `brandbook/tokens.json`
  - `brandbook/tokens.css`
- Do not change logo assets, SVG specimens, README/package/docs copy, repo-hygiene scripts, package allowlists, product UI code, public APIs, or release workflow in this phase.
- Phase 81 must cite Phase 80's audit/register rows: `BRAND-GAP-01`, `BRAND-GAP-08`, and `BRAND-GAP-12`.

#### Draft Artifact Treatment

- Existing `brandbook/` files are useful draft inputs from commit `572f3eb2`, not approved final v1.8 outputs.
- Phase 81 should harden and tighten the current source artifacts rather than replacing them wholesale.
- Wording in the source brandbook, token files, and static HTML must not imply Phases 82-84 are complete.

#### Brand Center

- Preserve the conceptual center:
  - "Mailglass makes email visible"
  - "Mail you can see through"
  - "glass is a metaphor, not a visual excuse"
- Keep Mailglass positioned as Phoenix-native transactional and operational email infrastructure built on Swoosh and shipped as `mailglass`, `mailglass_admin`, and `mailglass_inbound`.
- Keep out marketing email, campaigns, newsletters, drip automation, outbound-sales language, growth/outreach framing, "AI magic", and "Swoosh replacement" language.
- Preserve the thoughtful-maintainer voice: exact, calm, technical, direct, helpful under failure, and warm without cuteness.

#### Token System

- Required token groups: raw palette, light/dark semantic color roles, state roles, callout roles, code roles, typography, spacing, radius, border, shadow, focus, and motion.
- Token guidance should prefer semantic roles over raw hex usage.
- Raw palette tokens are source values; examples should route through roles such as background, surface, border, text, link, focus, state, callout, and code.
- Add explicit text versus non-text guidance for state and callout colors. `BRAND-GAP-08` requires documenting the current info callout/background relationship as appropriate for border/non-text use unless later Phase 84 contrast validation proves a safe text pair.
- Preserve Ink, Glass, Ice, Mist, Paper, Slate, plus semantic Pine/Amber/Crimson.
- Glass remains a restrained accent, not the default background or border flood.
- Preserve Inter Tight, Inter, IBM Plex Mono; weights 400 and 700; letter spacing `0`; 4px spacing grid; modest radius; border-first surfaces; overlay-only shadows; transform/opacity-friendly motion at or below 300ms.

#### Admin Design-System Boundary

- `mailglass_admin/docs/design-system.md` remains the implemented product UI constraint source.
- The brandbook may guide docs, marketing, examples, lightweight prototypes, and future collateral.
- The brandbook must not become a second admin UI framework and must not imply that product admin UI should directly consume `brandbook/tokens.css`.
- Align language with the admin discipline: semantic roles over raw hex, restrained Glass accent, flat panes, visible focus, non-color state cues, reduced-motion posture, no glassmorphism, no bevels, no glossy depth, no heavy shadows, and no decorative gradients or blobs.

#### Static HTML

- `brandbook/index.html` must open directly from disk.
- No build step, Node toolchain, external asset service, PDF export, font binary, or vendor design tool should be introduced.
- The HTML may use committed token CSS and local SVG assets as draft display evidence, but it must not present the Phase 82 logo system or Phase 83 specimens/copy as approved.

### the agent's Discretion

- The planner can choose the exact split across plans, but every plan must stay within the four-file boundary.
- It can add a status note, dedicated "Phase status" section, or inline wording to remove overclaims.
- It can improve small source-only consistency issues in the four Phase 81 files.

### Deferred Ideas (OUT OF SCOPE)

- Final logo option review, favicon/small-mark ambiguity, SVG accessibility ID/distribution strategy, monochrome/reversed variants: Phase 82.
- Visual specimens, README/Hex.pm/HexDocs/landing/social/launch copy blocks, real Mailglass snippet replacement, non-color UI-state specimen cues: Phase 83.
- JSON/CSS/SVG/HTML/file-size/contrast/package/git-cleanliness validation scripts: Phase 84.
- PNG social cards, conference-slide template, reusable diagram component set, automated contrast-report script, and trademark/name strategy: future-only unless justified by concrete launch or legal needs.

## Phase Requirements

| Requirement | Meaning for Phase 81 |
|---|---|
| BOOK-01 | `brandbook/index.html` remains direct-open from disk and honestly reflects draft/final status. |
| BOOK-02 | `brandbook/brand-book.md` becomes the concise source brand book, preserving concept while removing prompt-era friction and overclaims. |
| BOOK-03 | Source brandbook explicitly preserves "Mailglass makes email visible" and "glass is a metaphor, not a visual excuse." |
| TOKEN-01 | `tokens.json` and `tokens.css` expose raw palette and semantic roles for light, dark, state, callout, and code contexts. |
| TOKEN-02 | Token artifacts include typography, spacing, radius, border, shadow, focus, and motion primitives without becoming a giant framework. |
| TOKEN-03 | Token guidance aligns with admin UI discipline: semantic roles over raw hex, restrained Glass accent, flat panes, visible focus, and no glassmorphism. |

## Summary

Phase 81 is not a visual redesign. It is a source-hardening and token-language pass over four existing draft files. The files already contain most required structure: the Markdown brandbook has the conceptual center and voice; JSON and CSS tokens include the requested token families; HTML is already static and direct-open. The plan should focus on precision:

- Add Phase 80 status and downstream handoff language so the artifacts do not overclaim final logo/specimen/copy/validation completion.
- Tighten `brandbook/brand-book.md` into the source-of-truth brand guidance for concept, positioning, visual principles, tokens, admin boundary, voice, and artifact rules.
- Tighten `brandbook/tokens.json` descriptions and metadata so semantic roles are preferred and callout/state text-vs-non-text usage is explicit.
- Keep `brandbook/tokens.css` aligned with the JSON source and direct-open HTML use, including dark mode, focus, and reduced motion.
- Update `brandbook/index.html` copy to display the approved brand center and draft status without implying Phase 82-84 artifacts are done.

## Architectural Responsibility Map

| Artifact | Role | Current state | Phase 81 responsibility |
|---|---|---|---|
| `brandbook/brand-book.md` | Source brand guidance | Good conceptual center; light on Phase 80 status and admin boundary | Tighten source-of-truth language, cite `BRAND-GAP-01`, `BRAND-GAP-08`, `BRAND-GAP-12`, preserve positioning and voice. |
| `brandbook/tokens.json` | Structured token source | Required groups already present | Clarify metadata/descriptions, semantic role usage, text-vs-non-text state/callout policy, admin boundary. |
| `brandbook/tokens.css` | Direct-open CSS custom properties | Mirrors major token roles, has dark theme/focus/reduced motion | Keep role names aligned with JSON, add missing practical token exports only when needed by Phase 81 language, preserve direct-open simplicity. |
| `brandbook/index.html` | Static preview/source brandbook surface | Direct-open, local CSS/assets, but presents logos/specimens as polished system | Add honest status/handoff copy and token/admin-boundary language; keep local references only. |

## Project Constraints

- No new dependencies.
- No generated binaries, PDFs, font files, screenshots, PNG batches, contrast reports, vendor design files, or asset pipelines.
- No product UI code changes.
- No package metadata or Hex allowlist changes.
- No release workflow or public API changes.
- All edits remain source-native and directly inspectable in git.

## Standard Stack

### Core

- Markdown source documentation (`brandbook/brand-book.md`).
- Static HTML (`brandbook/index.html`) with local CSS and local SVG references.
- JSON design token source (`brandbook/tokens.json`) parseable by `jq`.
- CSS custom properties (`brandbook/tokens.css`) parseable enough for grep and browser use.

### Supporting

- `git diff --check` for whitespace and patch sanity.
- `jq -e . brandbook/tokens.json` for JSON parse.
- `xmllint --html --noout brandbook/index.html` as a tolerant HTML parse/smoke check. Existing HTML5 parser diagnostics are acceptable if the command exits 0.
- `rg` for required wording, forbidden overclaim checks, token group coverage, and boundary checks.

## Architecture Patterns

### Pattern 1: Frozen Audit Rows As Planning Anchors

Phase 80 established stable `BRAND-GAP-*` rows. Phase 81 should not rewrite the audit or renumber rows. It should cite the assigned rows directly in the source files or plan `must_haves`:

- `BRAND-GAP-01`: current `brandbook/` files are draft inputs, not approved final outputs.
- `BRAND-GAP-08`: token/callout guidance must distinguish text use from border/non-text use.
- `BRAND-GAP-12`: preserve the brand center.

Recommended plan implication: every implementation task should include one or more of these row IDs in `must_haves.truths`, task acceptance criteria, or source text checks.

### Pattern 2: Semantic Roles Over Raw Values

The admin design-system pattern is role-first:

- Product UI uses semantic daisyUI roles and theme tokens, not raw hex in components.
- Brandbook examples should mirror this discipline by explaining raw palette tokens as source values and semantic tokens as usage values.
- Glass is an accent and focus/link/selected-state color, not the default border or surface flood.

Recommended plan implication: token edits should preserve raw palette values but strengthen descriptions and usage examples around semantic roles.

### Pattern 3: One Source Of Truth Per Layer

`mailglass_admin/docs/design-system.md` governs implemented admin UI. The brandbook governs source brand guidance, docs, marketing, examples, lightweight prototypes, and future collateral. Phase 81 should avoid language such as:

- "Admin UI consumes these tokens directly"
- "Replace product design tokens with brandbook tokens"
- "The brandbook is the admin UI design system"

Recommended replacement language: product UI may map brand tokens deliberately in a future phase, but the current admin mechanics remain Tailwind/daisyUI and the admin design-system doc.

### Pattern 4: Static HTML As Honest Preview, Not Approval Proof

`brandbook/index.html` already opens from disk via:

- `href="tokens.css"`
- `href="assets/favicon.svg"`
- local `assets/*.svg`
- local `examples/*.svg`

The HTML can remain a helpful browser-readable preview, but Phase 81 should add status language that says logo and specimen sections are draft evidence until Phases 82 and 83.

### Pattern 5: Validation Named Now, Heavier Gates Later

Phase 84 owns executable validation scripts and proof for contrast, SVG safety, package allowlists, file-size caps, and git cleanliness. Phase 81 should not implement those scripts, but it should make later validation possible by documenting token role intent and allowed uses.

## Don't Hand-Roll

- Do not invent a new token schema beyond the existing `tokens.json` shape unless the current shape cannot represent required groups.
- Do not add a build system, CSS preprocessor, design-token transformer, package manager, or browser automation dependency.
- Do not create contrast automation in Phase 81; document usage policy and defer executable contrast checks to Phase 84.
- Do not convert the static HTML into a frontend app.
- Do not redesign logo assets, specimens, README copy, Hex copy, or public docs copy.

## Common Pitfalls

### Pitfall 1: Treating Draft Display Assets As Approved

`brandbook/index.html` shows logos and specimens, but Phase 80 says these are draft evidence. The plan should make the HTML copy honest without deleting useful local previews.

### Pitfall 2: Token Guidance That Still Encourages Raw Hex Use

Raw palette tokens are useful source values, but implementation language should route usage through semantic roles. Acceptance checks should look for phrases such as "semantic roles" and "raw palette tokens are source values".

### Pitfall 3: `BRAND-GAP-08` Gets Reduced To A Contrast Number

The important planning action is usage policy: identify which state/callout pairs are safe for text, which are border/non-text/background only, and which await Phase 84 validation. The plan should not ask the executor to overstate unvalidated text contrast.

### Pitfall 4: Brandbook Becomes Product UI Framework

The brandbook is allowed to influence future docs and collateral, but product admin UI constraints live elsewhere. The plan should require explicit boundary language in Markdown and tokens.

### Pitfall 5: Scope Creep Into Phase 82-84 Work

Logo option review, visual specimens, public copy blocks, validation scripts, package proof, and SVG safety checks are not Phase 81 source edits. Plans should name these as deferred or downstream where the current four files refer to them.

### Pitfall 6: CSS And JSON Drift

`tokens.json` and `tokens.css` should stay conceptually aligned. If JSON descriptions add a token role that CSS needs to display or the HTML uses, the plan should require the matching CSS custom property. If a token exists only as source metadata and is not needed in CSS, the plan should say so.

## Code Examples

### Good Token Guidance Shape

```markdown
Raw palette tokens define source values. Use semantic roles for implementation:
`color.light.text`, `color.light.background`, `color.light.border`,
`color.state.success`, `color.callout.infoBorder`, and code roles.
Do not use `palette.glass` as the default border or background flood.
```

### Good Callout Guidance Shape

```markdown
Info callout background and border tokens are safe as non-text structure.
Do not use the info border token as normal body text on info background until
Phase 84 contrast validation proves an approved text pair.
```

### Fast Local Validation Commands

```bash
git diff --check -- brandbook/brand-book.md brandbook/index.html brandbook/tokens.json brandbook/tokens.css
jq -e . brandbook/tokens.json
xmllint --html --noout brandbook/index.html
rg -n 'BRAND-GAP-01|BRAND-GAP-08|BRAND-GAP-12|draft input|not approved|semantic roles|admin design-system|glass is a metaphor' brandbook/brand-book.md brandbook/index.html brandbook/tokens.json brandbook/tokens.css
```

## Environment Availability

| Tool | Availability | Use |
|---|---|---|
| `rg` | available | Text and boundary checks. |
| `jq` | available by project precedent | JSON parse for `tokens.json`. |
| `xmllint` | available by Phase 80 precedent | Tolerant static HTML parse. |
| Browser/dev server | not required | `index.html` must open directly from disk; no server should be required for Phase 81 acceptance. |

## Validation Architecture

### Test Framework

Phase 81 uses existing CLI checks and source assertions. No test framework install is required.

| Property | Value |
|---|---|
| Framework | Existing CLI checks: `git diff --check`, `jq`, `xmllint`, `rg` |
| Config file | None |
| Quick run command | `git diff --check -- brandbook/brand-book.md brandbook/index.html brandbook/tokens.json brandbook/tokens.css && jq -e . brandbook/tokens.json && xmllint --html --noout brandbook/index.html` |
| Full suite command | Quick run command plus source assertion greps listed below |
| Estimated runtime | Less than 30 seconds for phase-specific checks |

### Phase Requirements -> Test Map

| Requirement | Verification approach |
|---|---|
| BOOK-01 | `brandbook/index.html` exists; references only local `tokens.css`, `assets/...`, and `examples/...`; no `http://`, `https://`, CDN, script tag, or build dependency. |
| BOOK-02 | `brandbook/brand-book.md` contains source-of-truth sections for concept, positioning, visual principles, token usage, admin boundary, voice, and artifact rules. |
| BOOK-03 | `brandbook/brand-book.md` contains "Mailglass makes email visible" and "glass is a metaphor, not a visual excuse". |
| TOKEN-01 | `tokens.json` and `tokens.css` expose palette, light/dark roles, state roles, callout roles, and code roles. |
| TOKEN-02 | `tokens.json` and `tokens.css` expose type, spacing, radius, border, shadow, focus, and motion primitives. |
| TOKEN-03 | Source files contain semantic-role, restrained Glass, flat-pane, visible-focus, no-glassmorphism, and admin-boundary language. |

### Sampling Rate

- After every task commit: run the quick command and task-specific `rg` checks.
- After the plan wave: run the full source assertion set.
- Before `$gsd-verify-work`: run phase-specific checks and confirm no out-of-scope files changed.
- Max feedback latency: 30 seconds for Phase 81-specific checks.

### Wave 0 Gaps

No test infrastructure is missing. Phase 84 owns committed validation scripts and contrast/package/file-size proof.

## Security Domain

Security enforcement is effectively enabled by default for this workflow. Phase 81 is low-risk documentation/static-asset work, but plans should still include a threat model because static HTML and SVG/CSS/JSON artifacts can accidentally introduce unsafe references or publication scope drift.

### Applicable Threat Patterns

| Threat | STRIDE | Planning control |
|---|---|---|
| External asset/script reference in direct-open HTML | Information disclosure / tampering | Require local-only references and no scripts in `brandbook/index.html`. |
| Overclaiming draft assets as approved outputs | Tampering / repudiation | Require Phase 80 status language and `BRAND-GAP-01` citation. |
| Product UI boundary confusion | Tampering / maintainability risk | Require explicit language that admin UI remains governed by `mailglass_admin/docs/design-system.md`. |
| Color-only or unsafe token guidance | Accessibility / denial of use | Require text-vs-non-text guidance for state and callout roles, especially `BRAND-GAP-08`. |
| Scope creep into package/public artifacts | Information disclosure / repo hygiene risk | Require out-of-scope file boundary checks and leave package proof to Phase 84. |

### Threat Model Template For Plans

Each plan should include a `<threat_model>` block with at least:

- `T-81-01`: Local-reference safety for static HTML.
- `T-81-02`: Draft-vs-approved artifact status integrity.
- `T-81-03`: Admin design-system boundary integrity.
- `T-81-04`: Token accessibility guidance for text/non-text state use.

## Assumptions Log

| ID | Assumption | Confidence | Impact |
|---|---|---|---|
| A1 | Phase 81 can be completed as one or two plans because it touches four closely related source files. | High | Planner can choose a compact plan set. |
| A2 | The current JSON token schema is adequate; this phase needs descriptions and role clarity more than schema redesign. | High | Avoids unnecessary abstraction. |
| A3 | Static HTML does not need browser automation for plan acceptance because Phase 84 owns deeper validation. | Medium | Phase 81 should still parse HTML and check local references. |
| A4 | `xmllint --html --noout` may emit HTML5 parser diagnostics but is acceptable if exit code is 0, matching Phase 80 precedent. | High | Plan verification should focus on command exit status. |

## Open Questions (Resolved)

No unresolved planning questions. The user selected research first and Phase 81 context was already gathered in assumptions mode.

## Sources

### Primary - Repo (HIGH confidence)

- `.planning/phases/81-brandbook-source-and-token-system/81-CONTEXT.md` - locked decisions, phase boundary, canonical references, deferred items. [VERIFIED: repo file read]
- `.planning/REQUIREMENTS.md` - BOOK-01, BOOK-02, BOOK-03, TOKEN-01, TOKEN-02, TOKEN-03. [VERIFIED: repo file read]
- `.planning/ROADMAP.md` - Phase 81 goal and success criteria. [VERIFIED: repo file read]
- `.planning/STATE.md` - v1.8 correction, scope locks, and current phase position. [VERIFIED: repo file read]
- `.planning/phases/80-brand-audit-and-gap-register/80-CONTEXT.md`, `80-PATTERNS.md`, `80-01-PLAN.md`, `80-01-SUMMARY.md`, `80-VERIFICATION.md` - frozen audit/register precedent and downstream handoff. [VERIFIED: repo file read]
- `brandbook/brand-audit.md` - `BRAND-GAP-*` register and Phase 81 handoff rows. [VERIFIED: repo file read]
- `brandbook/brand-book.md`, `brandbook/index.html`, `brandbook/tokens.json`, `brandbook/tokens.css` - Phase 81 implementation targets. [VERIFIED: repo file read]
- `mailglass_admin/docs/design-system.md` - implemented product UI constraint source. [VERIFIED: repo file read]

## Metadata

**Confidence breakdown:**

- Scope: HIGH - locked by 81-CONTEXT and Phase 80 audit/register.
- Architecture: HIGH - four source files, no dependency or product-code work.
- Validation: MEDIUM-HIGH - direct parse/grep checks cover Phase 81; heavier validation deliberately deferred to Phase 84.
- Security: MEDIUM - low-risk static artifacts, but local-reference and boundary checks are still necessary.

**Research date:** 2026-06-06
**Valid until:** 2026-07-06 for repo-scoped planning; re-read Phase 80 and admin design-system artifacts if either changes before execution.
