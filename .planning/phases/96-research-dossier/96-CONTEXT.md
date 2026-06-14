# Phase 96: Research Dossier - Context

**Gathered:** 2026-06-14 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Produce **parallel-subagent research dossiers** under `.planning/research/v1.11/`, each
ending in an **adversarially-synthesized LOCKED DECISION block** the main thread (and the
downstream build phases 97–102) consume — covering five areas:

1. **Motion** (Emil Kowalski `emilkowal.ski` + platform HIG) — RESEARCH-01
2. **IA** (gov.uk Design System / Nielsen) — RESEARCH-02
3. **Component-state matrices** per archetype — RESEARCH-03
4. **Dark-mode pitfalls** (elevation, desaturation, focus-ring contrast) — RESEARCH-04
5. **"Thoughtful maintainer" microcopy** mapped to each surface's JTBD — RESEARCH-05

This is a **research-PRODUCING** phase: the deliverable is the dossiers + their LOCKED
DECISION blocks. No admin markup/CSS changes here — the visible uplift lands in Phases
97–103, which *cite* these locked decisions.

**In scope:** the five dossier files, their per-dossier adversarial synthesis, the LOCKED
DECISION block schema, and a `SUMMARY.md` hoisting all five blocks. Every locked decision
must (a) stay within the hard design constraints and (b) map to the open
`RATCHET-GAP-REGISTER.md` rows it lets a downstream phase close.

**Out of scope:**
- Any admin UI/markup/CSS change (Phases 97–103 consume the decisions; they don't land here).
- Editing `brandbook/` (this milestone *consumes* the brand book; `tokens.css` is the SoT).
- Any core/inbound functional code.
- Building the dev gallery (`/dev/mail/gallery`) — Phase 97.
- Re-running the audit matrix / closing GAP rows — Phase 103.

**Bounding constraints (from STATE.md hard-design-constraints):** zero Node in shipped lib;
motion ≤300ms, ease-out, transform/opacity-only, no springs/overshoot, `prefers-reduced-motion`
respected, CSS+LiveView.JS only (no client JS hook); type weights only 400/700; flat
elevation (border-first, no glassmorphism/bevels); 10%-accent rule; semantic tokens only;
brand constraints C-15/C-16; PII minimization preserved. **A dossier may not lock a decision
the build phases cannot legally implement under these constraints.**

Requirements: RESEARCH-01, RESEARCH-02, RESEARCH-03, RESEARCH-04, RESEARCH-05.
</domain>

<decisions>
## Implementation Decisions

Derived codebase-first (assumptions mode), grounded in prior research-dir conventions
(`v1.9-brandbook-fable/`, `v1.7-admin-ui-polish/`), the Phase 95 ratchet apparatus + GAP
register, the canonical `design-system.md` pillars, and the locked brand voice + domain
nouns. Calibration: minimal_decisive (`vendor_philosophy: opinionated`) under the
project METHODOLOGY (decisive-by-default research posture). All assumptions confirmed by the
owner; no corrections.

### Dossier inventory & file layout (RESEARCH-01..05)
- **D-01:** Produce **exactly five dossier files**, one per RESEARCH-NN, under
  `.planning/research/v1.11/`, ALLCAPS topic-named per repo convention:
  - `MOTION.md` (RESEARCH-01)
  - `IA.md` (RESEARCH-02)
  - `COMPONENT-STATES.md` (RESEARCH-03)
  - `DARK-MODE.md` (RESEARCH-04)
  - `MICROCOPY.md` (RESEARCH-05)

  Plus a thin **`SUMMARY.md`** that hoists **only the five LOCKED DECISION blocks verbatim**
  for one-stop downstream citation.
  - **Why:** every prior milestone research dir uses ALLCAPS topic files + a `SUMMARY.md`
    (`v1.9-brandbook-fable/`, `v1.7-admin-ui-polish/`); ROADMAP names exactly 5 areas;
    one-per-RESEARCH-NN preserves the 1:1 requirement→file trace the Phase 103 audit needs.
- **D-02:** The **LOCKED DECISION block lives at the END** of each dossier (after research
  body + adversarial synthesis). `SUMMARY.md` is the canonical downstream read — Phases
  97–102 and the main thread read `SUMMARY.md`, never the dossier bodies.
  - **Why:** success criterion 4 — "downstream phases can cite a locked decision without
    re-reading the research body"; matches the repo's "pre-settled decisions" pattern
    (`v1.10-brand-adoption/ADOPTION-MECHANICS.md` cited directly by STATE.md).

### LOCKED DECISION block schema (highest-value output)
- **D-03:** Each LOCKED DECISION block is an **ID-stamped decision table** with a per-dossier
  ID prefix and stable IDs:
  - `MOTION-LD-NN`, `IA-LD-NN`, `STATE-LD-NN` (component-states), `DARK-LD-NN`, `COPY-LD-NN`.
  - **Columns:** `LD-ID | Decision | Applies-to (surface/archetype) | Constraint-binding | Closes-GAP`.
  - "**Self-contained**" means each Decision cell states the **literal token / class / value**
    to use (exact easing token, exact `text-*` class, exact state list, exact copy string),
    so a build phase implements without re-reading the body.
  - **Why:** mirrors the proven stable-`GAP-NN` citation machinery (`RATCHET-GAP-REGISTER.md`)
    and the STATE.md bracketed-decision-ID idiom; the anti-churn contract needs a
    motion/IA/microcopy-flavored ID to cite; Phases 101/102 success criteria require
    decisions to *trace* to a Phase 96 LOCKED block.
- **D-04:** Every LOCKED DECISION row **must carry a `Constraint-binding` cell** naming the
  hard design constraint(s) it operates within (e.g. "≤300ms ease-out, transform/opacity-only",
  "weights 400/700 only", "10%-accent rule", "semantic tokens only"). A decision that the
  conformance / motion-grep / token-parity CI gates would reject is invalid and must not be
  locked.
  - **Why:** the front-loaded-decision premise fails if a build phase inherits a decision the
    gate rejects (e.g. a spring easing, a `font-medium` weight) and has to re-research
    mid-build. The constraint cell makes legality auditable on the block's face.

### Research execution model
- **D-05:** **Fan out five research subagents in parallel** (one per dossier), then run a
  **per-dossier adversarial-synthesis pass**: a critic challenges each draft decision against
  (a) the hard design constraints and (b) the open GAP rows, before any decision is marked
  LOCKED. "Adversarially-synthesized" = **critic-then-lock**, not a separate sixth dossier.
  - **Why:** `config.json` `parallelization: true`; ROADMAP says "parallel-subagent"; CLAUDE.md
    decision policy ("spawn research subagent(s), parallel, one per area … synthesize + decide")
    is the established house pattern.
- **D-06:** **Web research is enabled** for the externally-sourced dossiers. The
  `gsd-phase-researcher` agent type carries WebSearch / WebFetch / firecrawl / exa regardless
  of the `config.json` MCP-search flags (`brave_search/firecrawl/exa_search: false` gate only
  certain MCP servers). Motion / IA / microcopy dossiers use **live external sources**
  (emilkowal.ski, gov.uk Design System, Nielsen, platform HIG) cited by name/URL, grounded
  with codebase `file:line` citations.
- **D-07:** **Sourcing split by dossier:**
  - **External-led + codebase-grounded:** MOTION (Emil Kowalski/HIG), IA (gov.uk/Nielsen),
    MICROCOPY (UX-writing best practice mapped onto the locked brand voice).
  - **Codebase-led + external-secondary:** COMPONENT-STATES (over *this* project's real
    archetypes) and DARK-MODE (over the existing dark tokens + Phase 86 dark-feedback
    decisions).
  - **Why:** RESEARCH-01/02 name external sources explicitly; RESEARCH-03/04 are matrices over
    this project's own archetypes/tokens already defined in `design-system.md` and STATE.md.

### Per-dossier scope boundaries (overlap resolution)
- **D-08:** Overlap between motion / component-state / dark-mode is resolved by
  **axis-ownership**, and dossiers cross-reference by LD-ID instead of re-deciding:
  - **COMPONENT-STATES** owns *which states exist per archetype*
    (rest/hover/focus/active/disabled/loading/empty/error).
  - **MOTION** owns *how transitions between states animate*.
  - **DARK-MODE** owns *how each state / elevation / focus-ring renders in the dark theme*.
  - **Why:** the three axes are orthogonal in `design-system.md`; without axis-ownership two
    dossiers could lock conflicting decisions for the same cell, handing the build phases an
    unresolvable contradiction.
- **D-09:** The **COMPONENT-STATES matrix must cover the real archetype inventory** drawn from
  the code (not a generic list): `icon`, `logo`, `flash`, `badge`, `status_badge` (incl. its
  full status-atom set), `nav_link`, `theme_toggle`, `tenant_chip`, `orientation_strip`,
  `shell`; master-detail list+detail, `filters_form`, support-card triage grid,
  suppression card, timeline, replay modal, device frame, preview tabs/sidebar; and inbound
  `routing_trace` + `evidence_card` (locked/info reveal, mono chips on `surface-sunken`).
  - **Why:** enumerated from `components.ex`, `operator/shell.ex`, the `operator/`/`preview/`
    modules, and `inbound/routing_trace.ex` + `inbound/evidence_card.ex`; COMP-01/Phase 99
    name these explicitly. A matrix that omits real archetypes leaves Phases 97/99 without a
    locked spec.

### Grounding in real surfaces & GAPs
- **D-10:** Each dossier **maps its locked decisions to the open `RATCHET-GAP-REGISTER.md`
  rows** it lets a downstream phase close — at minimum: DARK-MODE → GAP-03 (preview ignores
  dark theme), MOTION/A11y → GAP-02 (preview empty-state focusable CTA), COMPONENT-STATES/Type
  → GAP-04 (inbound filter labels off-token), with the gallery gap GAP-05 noted as the
  structural surface that will verify the matrix.
  - **Why:** the seed-run register has exactly five open rows; the anti-churn contract requires
    build tasks to cite sev≥3 GAP rows; tying each dossier to its target GAPs closes the
    research-grounded-ratchet loop (STATE.md intent).
- **D-11:** The **MICROCOPY dossier maps voice patterns to each surface's specific JTBD** using
  the project's locked domain nouns + brand voice — NOT generic UX-writing rules:
  - Operator = "audit why a delivery failed"; Inbound = "why did inbound not route";
    Preview = "preview a message before send".
  - Canonical anti-pattern = "Oops"; canonical positive = cause-naming
    ("Delivery blocked: recipient is on the suppression list").
  - Must use the seven domain nouns (Mailable/Message/Delivery/Event/InboundMessage/Mailbox/
    Suppression); must not reintroduce banned terms (Email/Status/Notification alone).
  - **Why:** RESEARCH-05 "mapped to each surface's JTBD"; CLAUDE.md Brand & Voice + Domain
    Language; Phase 101's voice-conformance check gates on "no Oops, name the cause".

### Claude's Discretion
- Exact markdown layout of each dossier body (headings, evidence-table style) as long as the
  LOCKED DECISION block follows the D-03 schema and lands at the end (D-02).
- Exact LD-NN numbering granularity per dossier (how finely decisions are split into rows).
- Whether the adversarial-synthesis critic (D-05) is a distinct subagent invocation or a
  second pass by the same dossier agent — as long as each LOCKED decision is stress-tested
  against constraints + GAPs before locking.
- Which specific secondary external sources each codebase-led dossier (D-07) cites.

### Folded Todos
- None folded. See Reviewed Todos below.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` — Phase 96 goal + 4 success criteria; the consuming phases 97
  (components), 98/99/100 (surfaces), 101 (microcopy), 102 (motion); critical path.
- `.planning/REQUIREMENTS.md` — RESEARCH-01..05 (lines ~67-78), incl. the "each dossier ends
  in an adversarially-synthesized LOCKED DECISION block" note.
- `.planning/STATE.md` — v1.11 milestone intent + **scope locks** + the **hard design
  constraints** block that BOUNDS every locked decision; Phase 86 dark-feedback decisions
  (success-bg/warning-bg/error-bg/info-bg contrast figures) the DARK-MODE dossier extends.
- `.planning/METHODOLOGY.md` — decisive-by-default research posture; recommendation-first
  synthesis (shapes how the dossiers reach LOCKED decisions).
- `.planning/RATCHET-GAP-REGISTER.md` — the five open GAP rows each dossier must map to
  (D-10); the stable-`GAP-NN` ID + anti-churn sev≥3 citation machinery the LD-ID scheme
  mirrors.
- `.planning/phases/95-audit-apparatus-quality-ratchet-v2/95-CONTEXT.md` — predecessor; the
  6-pillar rubric (Spacing/Radius/Color/Type/Elevation/Motion+A11y), the ratchet apparatus the
  dossiers feed.
- `mailglass_admin/docs/design-system.md` — canonical pillars (≈104-121), motion vocabulary +
  rules (≈80-102), token/color tables (≈35-68) — the lockable values the dossiers crystallize.
- `brandbook/brand-book.md` — active brand voice + visual identity SoT (MICROCOPY dossier
  voice source); `brandbook/tokens.css` is the token SoT the DARK-MODE dossier reasons over.
- `CLAUDE.md` — "Brand & Voice" (thoughtful-maintainer register, error exemplar) and "Domain
  Language" (seven nouns; banned Email/Status/Notification) for the MICROCOPY dossier.
- `mailglass_admin/lib/mailglass_admin/components.ex`, `operator/shell.ex`, the `operator/` +
  `preview/` modules, `inbound/routing_trace.ex`, `inbound/evidence_card.ex` — the real
  archetype inventory the COMPONENT-STATES matrix must cover (D-09).
- Prior research-dir conventions for layout (D-01): `.planning/research/v1.9-brandbook-fable/`
  and `.planning/research/v1.7-admin-ui-polish/` (ALLCAPS topic files + `SUMMARY.md`);
  `.planning/research/v1.10-brand-adoption/ADOPTION-MECHANICS.md` (pre-settled-decision style).
- `.planning/config.json` — parallelization/research toggles (D-05); MCP-search flags note
  (D-06: web research still available via `gsd-phase-researcher` tools).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Prior research-dir conventions** (`v1.9-brandbook-fable/`, `v1.7-admin-ui-polish/`):
  ALLCAPS topic files + `SUMMARY.md` — directly reused for D-01 layout.
- **`RATCHET-GAP-REGISTER.md`** — the stable-ID citation machinery the LD-ID scheme mirrors
  (D-03) and the five open rows each dossier maps to (D-10).
- **`design-system.md`** — already enumerates lockable motion/type/color/elevation values the
  dossiers crystallize into LOCKED decisions.
- **`components.ex` / `shell.ex` / inbound modules** — the real archetype list (D-09).
- **CLAUDE.md Brand & Voice + Domain Language** — the locked voice + nouns for MICROCOPY (D-11).

### Established Patterns
- Research is parallel-subagent fan-out, one per area, then synthesize-and-decide (CLAUDE.md
  decision policy; METHODOLOGY recommendation-first synthesis) → D-05.
- The milestone runs on stable-ID citation gates (`GAP-NN`, bracketed STATE decision IDs);
  LOCKED decisions adopt the same idiom (`*-LD-NN`) → D-03.
- Every phase is bounded by the hard design constraints; artifacts prove legality on their face
  → D-04 constraint-binding cell.

### Integration Points
- `SUMMARY.md` LOCKED blocks → cited by Phases 97 (COMP), 98/99/100 (surfaces), 101 (COPY),
  102 (MOTION) alongside the GAP rows they close.
- Each dossier's `Closes-GAP` column → `RATCHET-GAP-REGISTER.md` rows (the anti-churn gate
  join).
- DARK-MODE decisions → extend Phase 86 dark-feedback contrast figures (STATE.md).
- COMPONENT-STATES matrix → the spec Phase 97 gallery (`/dev/mail/gallery`) renders + the
  structural assertion layer (Phase 95) verifies.
</code_context>

<specifics>
## Specific Ideas

- Five dossiers + `SUMMARY.md`; `SUMMARY.md` is the only file downstream phases read.
- LOCKED DECISION block schema: `LD-ID | Decision | Applies-to | Constraint-binding | Closes-GAP`,
  stable per-dossier ID prefixes, literal values in the Decision cell.
- "Adversarially-synthesized" = a critic-then-lock pass against constraints + GAPs (D-05).
- Axis-ownership prevents motion/component-state/dark-mode from re-deciding the same cell (D-08).
- Microcopy uses the seven domain nouns, the thoughtful-maintainer voice, names the cause,
  never "Oops" (D-11).
</specifics>

<deferred>
## Deferred Ideas

- **Building the gallery, surfaces, motion CSS, microcopy strings** — all downstream
  (Phases 97–103). Phase 96 only *locks decisions*; it changes no admin code.
- **Editing `brandbook/`** — out of milestone scope; this milestone consumes the brand book.

### Reviewed Todos (not folded)
- `2026-06-13-refresh-outbound-admin-ui-look-and-feel.md` (score 0.5) — reviewed, **not
  folded**. It is the milestone-level seed (already captured in STATE/PROJECT, broadened to
  all three admin surfaces across Phases 94–103). Phase 96 only produces the research the
  visible refresh consumes; the refresh lands in Phases 97–103, not here.
</deferred>
</content>
