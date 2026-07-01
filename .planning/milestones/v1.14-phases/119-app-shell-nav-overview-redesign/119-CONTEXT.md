# Phase 119: App-shell + Nav + Overview redesign - Context

**Gathered:** 2026-06-26 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Redesign the #1-pain admin operator surface — the **app shell, sidebar navigation, and Operator
Overview landing** — into a real triage destination with correct location awareness and zero
redundant chrome. This is the **keystone** phase of v1.14: it establishes the cleaned-up
IA / component / microcopy / motion patterns that every later surface (Deliveries 120 → Inbound 121
→ Preview 122) inherits.

**In scope (SHELL-01/02/03 + cross-cutting matrix):** the operator shell nav (`shell.ex`), the
Overview branch of `operator_live.ex`, the orientation strip, the Overview health row, and the
paired Playwright gate updates. Full matrix applies: 320→wide responsive, light/dark/system,
happy/empty/error/boundary, WCAG 2.2 AA, Emil-Kowalski-grade transform/opacity motion.

**Out of scope (later phases / locked):** Deliveries surface internals incl. filters-on-empty and
label-tripling (Phase 120); Inbound (121); Preview (122); arming the new judgment gates into the
ratchet floor + pillar re-score (Phase 123). No new product capability, providers, transports, or
routes (D-23). Recipient-facing email HEEx + `brandbook/` tokens are OUT (brand book is source of
truth). Zero-Node *shipped* asset pipeline preserved.
</domain>

<decisions>
## Implementation Decisions

### Nav active-state + Overview nav identity (SHELL-01)
- **D-01:** Add `:overview` to the shell's `active` attr enum (`shell.ex:201`, currently
  `values: [:deliveries, :inbound]`) and add a third sidebar nav link **"Overview"** that points at
  the bare operator root (no `&view=`). The Overview link is **always shown** (unlike Inbound, which
  is gated by `inbound_available?`).
- **D-02:** Fix the false-active-nav bug by replacing the hardcoded literal `active={:deliveries}`
  at `operator_live.ex:349` with `active={@view}` — `@view` already resolves to
  `:overview` / `:deliveries` / `:inbound` and already drives the title/subtitle
  (`operator_live.ex:356-363`). **Do NOT rewrite the shell** — it is already correct
  (`shell.ex:235` does `@active == :deliveries`; `components.ex:230` emits `aria-current`).
- **D-03:** The Overview link must be a real `nav_link` (not the disabled-`<span>` branch, which
  omits `aria-current`) so `aria-current="page"` renders on the active surface. This is the exact
  end-state the drafted `nav-active-correctness` gate (`mailglass_admin/e2e/judgment.spec.js`)
  asserts. Thread `active={@view}` for the inbound surface too, or inbound regresses to a false
  Overview highlight. Active state is conveyed non-color-alone (existing accent left-border + weight)
  and holds in light/dark/system.

### Overview → real triage destination (SHELL-02)
- **D-04:** **Delete** the `operator-overview-nav` block (`operator_live.ex:416-448`) — the two
  "Navigate" cards (View Deliveries / View Inbound) duplicate the always-visible sidebar (D-NAV-DUP).
  Also drop the signpost subtitle ("Navigate to Deliveries to inspect individual sends").
- **D-05:** Make health counts **click-throughs** (drill-into-the-failing-sends), not dead numbers:
  - **Recent failures** → deep-link `?view=deliveries&status=failed`
  - **Active suppressions** → deep-link `?view=deliveries&status=suppressed`
  - (`:failed` / `:suppressed` are already valid filter values — `operator_live.ex:34`
    `@status_values`. Build links via the existing `build_path` helper.)
  - **Orphan backlog** → keep the **existing `support_cards.ex` focus drilldown**
    (`phx-value-focus="orphan_backlog"`, expands the oldest unmatched reconcile fact). No Deliveries
    `status=` filter maps to orphans and one already ships — do NOT invent a 404-ing filter link.
- **D-06:** Drill-through is implemented by **wrapping** the `stat_card` primitive in an
  `<.link patch={...}>` (or equivalent), NOT by embedding an `<a>` inside the shared
  `stat_card`/`components.ex:380` primitive — `stat_card` stays a presentational `<article>`;
  wrapping avoids nested-interactive a11y violations and keeps the primitive reusable.
- **D-07:** Make the `orientation_strip` **empty-pane-only**: render the teach-the-next-step strip
  only when there is no actionable data (all-clear / empty), and suppress it otherwise. This is the
  pattern Phase 120 then applies to Deliveries (D-ORIENT-REDUNDANT). Collapse the all-clear Overview
  to a **calm, short summary** rather than a full-height info-dump (D-MOBILE-INFODUMP shortens the
  375/320 scroll as a side-effect).
- **D-08:** Overview gets its **own nav identity** (the `:overview` item from D-01) so the landing is
  a destination in its own right, not an unnamed homepage that highlights Deliveries.

### Microcopy, motion & paired-test mechanics (SHELL-03 + matrix)
- **D-09:** **Paired test update (mandatory, same phase):** rewrite `operator.spec.js:352-368`
  (VERIF-02 currently asserts `operator-overview-nav` IS visible) so it stops asserting the deleted
  block — keep only the `operator-overview` + `operator-overview-health` assertions. Flip BOTH
  `judgment.spec.js` gates (`nav-active-correctness`, `no-nav-duplication`) from `test.fixme`→`test`.
  Skipping the VERIF-02 edit turns the operator browser gate red on a green-only-forward floor.
- **D-10:** **Microcopy:** rewrite the Overview subtitle from the signpost line to a
  thoughtful-maintainer triage framing ("Oops" banned; no boilerplate; nothing duplicating the
  always-visible sidebar). Keep the `orientation_strip` copy (`shell.ex:392-423`) **byte-frozen** —
  only its render condition changes (D-07).
- **D-11:** **Motion:** reuse the existing token classes already on `nav_link` / `flash_region`
  (`motion-reveal`, `transition-colors ease-out duration-(--duration-fast)`) — transform/opacity
  only, instant under reduced-motion. **No new keyframes / bespoke motion CSS** (would risk the v1.13
  MOTION locks that 120-122 inherit).
- **D-12:** **Asset landmine:** any Tailwind class change to these templates requires
  `mix assets.build` + a committed `mailglass_admin/priv/static/app.css`. Watch the **TokenParityTest
  landmine** — a fresh `mix assets.build` emits raw-inline daisyUI theme blocks that BREAK
  TokenParityTest; the committed bundle is canonical. Hold the v1.13 ratchet floor green
  only-forward (no pillar re-score here — that is Phase 123).

### Claude's Discretion
- Exact triage layout for the all-clear vs attention state (single calm summary line vs.
  conditionally-expanded cards) — guided by the plan-phase IA research below; pick the
  least-surprise, Apple-deliberate option.
- Whether the `operator-overview-health` stat_card row and the richer `support_cards` component
  should be reconciled/deduped (they may overlap) — planner's call; resolve toward one canonical
  health presentation.
- Precise nav icon for the Overview item (`hero-home` / `hero-squares-2x2`) — pick the on-brand,
  semantically-correct glyph; verify the SVG is embedded in `heroicons-inline.js` + rebuilt if new.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/research/v1.14/DEFECT-REGISTER.md` — the prioritized, screenshot-backed hit-list;
  Phase 119 owns D-NAV-ACTIVE, D-NAV-DUP, D-OVERVIEW-SIGNPOST, D-MOBILE-INFODUMP and SETS the
  empty-pane-only orientation pattern (D-ORIENT-REDUNDANT). Includes the Pitfall-2 VERIF-02
  cross-reference.
- `.planning/research/v1.14/STRESS-TEST-PROMPT.md` — the binding judgment rubric (the Apple-like
  deliberate-IA bar; redundancy / earns-its-place / least-surprise / info-dump-vs-streamlined /
  hierarchy / microcopy / semantic-icons / cross-surface-consistency). Do not dilute.
- `.planning/phases/118-method-audit-storybook-stand-up/118-CONTEXT.md` — locked Phase 118 decisions
  (persona harness, personas, storybook, the two drafted judgment gates D-11/D-12).
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` — caller literal (`:349`), overview branch +
  health row (`~375-415`), `operator-overview-nav` block to delete (`416-448`), `@status_values`
  (`:34`), `build_path` helper, orphan focus normalization (`:1044`), all-clear predicate (`:1151`).
- `mailglass_admin/lib/mailglass_admin/operator/shell.ex` — nav block (`~216-244`), `active` attr
  enum (`:201`), `@active == :deliveries` handling (`:235`), `orientation_strip` (`361-424`, copy
  `392-423`).
- `mailglass_admin/lib/mailglass_admin/operator/support_cards.ex` — existing orphan-backlog tiered
  cards + focus drilldown (the orphan drill-through target; D-05).
- `mailglass_admin/lib/mailglass_admin/components.ex` — `stat_card` primitive (`:380`), `aria-current`
  emission (`:230`).
- `mailglass_admin/e2e/judgment.spec.js` — drafted `nav-active-correctness` + `no-nav-duplication`
  gates to flip `test.fixme`→`test` (D-09).
- `mailglass_admin/e2e/operator.spec.js:352-368` — VERIF-02; MUST be updated when the Navigate block
  is deleted (D-09).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The **shell is already correct** — `shell.ex:235` keys active off `@active == :deliveries` and
  `components.ex:230` already emits `aria-current`. The whole SHELL-01 fix is a caller-literal change
  + one new nav link; do not touch the shell's active logic.
- `@view` socket assign already resolves to `:overview`/`:deliveries`/`:inbound` and drives
  title/subtitle (`operator_live.ex:356-363`) — the right source to thread into `active={...}`.
- `@status_values` (`operator_live.ex:34`) already includes `:failed` and `:suppressed`, and
  `build_path` already constructs filtered Deliveries URLs — the failures/suppressions drill-through
  links need no new filter plumbing.
- `support_cards.ex` already implements the orphan-backlog drilldown (focus-expand on the oldest
  unmatched reconcile fact) — reuse it; do not build a new orphan view.
- Motion tokens (`motion-reveal`, `transition-colors duration-(--duration-fast)`) are already on
  `nav_link`/`flash_region` — Emil-Kowalski-grade motion needs no new CSS.

### Established Patterns
- Disabled nav items render as a `<span>` (no `aria-current`); active/enabled items must be a real
  `nav_link` to emit `aria-current="page"` — the Overview link must take the enabled branch.
- `stat_card` is a presentational `<article>` primitive with a `@rest` passthrough — drill-through is
  achieved by wrapping in a link, not mutating the primitive (avoids nested-interactive a11y issues).
- Committed `priv/static/app.css` is canonical; a fresh `mix assets.build` regenerates raw-inline
  daisyUI theme blocks that trip TokenParityTest — only commit a rebuild that survives the gate.

### Integration Points
- `operator_live.ex` → `shell.ex` (`active` attr) — the SHELL-01 seam.
- Overview health stats → Deliveries filtered view (`?view=deliveries&status=...`) — the SHELL-02
  drill-through seam; and → `support_cards` focus for orphans.
- `judgment.spec.js` + `operator.spec.js` — the gate seam that must move with the deletion (D-09).
</code_context>

<specifics>
## Specific Ideas

- Health counts become **triage entry points**, not dead numbers: the failing/suppressed counts link
  straight into the already-filtered Deliveries table the operator needs under stress.
- The all-clear Overview should read **calm and short** ("nothing needs you now"), not the same height
  as the attention state — directly answers the on-call "what needs me now?" in one glance.
</specifics>

<deferred>
## Deferred Ideas

- **All-clear vs attention-state IA layout** (single calm summary line vs. conditionally-expanded
  cards) — slated for `/gsd-plan-phase` research per the ROADMAP research flag (GOV.UK overview-as-
  triage IA patterns + the Apple-deliberate bar). Captured here as the primary plan-phase research
  topic, not decided in discuss.
- **Health row vs `support_cards` dedup** — the `operator-overview-health` stat_card row and the
  richer `support_cards` component may overlap; reconcile toward one canonical health presentation in
  planning (a refinement, not a new capability).
- **Deliveries filters-on-empty / label-tripling** (D-FILTERS-ON-EMPTY, D-LABEL-TRIPLING) — Phase 120,
  inheriting the empty-pane pattern set here.
- **Arming the new judgment gates into the ratchet floor + pillar re-score** — Phase 123 (the gates
  turn green here; they are armed there).
- **Storybook chrome on-brand** (D-STORYBOOK-BRAND) — Low, optional Phase 123 finalize.

### Reviewed Todos (not folded)
None — `todo.match-phase 119` returned 0 matches.
</deferred>
