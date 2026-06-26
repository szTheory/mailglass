# Phase 119: App-shell + Nav + Overview redesign - Research

**Researched:** 2026-06-26
**Domain:** Phoenix LiveView admin/operator IA — app-shell nav active-state, overview-as-triage landing, HEEx component reuse, zero-Node asset pipeline
**Confidence:** HIGH (every claim grounded in real file/line references; the two flagged IA topics cross-checked against GOV.UK Design System)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions (D-01..D-12 — authoritative; do NOT relitigate)
- **D-01:** Add `:overview` to the shell `active` attr enum (`shell.ex:201`, currently `values: [:deliveries, :inbound]`) + a third **"Overview"** sidebar nav link → bare operator root (no `&view=`). Always shown (not gated by `inbound_available?`).
- **D-02:** Replace the hardcoded `active={:deliveries}` at `operator_live.ex:349` with `active={@view}`. Do NOT rewrite the shell — `shell.ex:235` (`@active == :deliveries`) + `components.ex:230` (`aria-current`) are correct.
- **D-03:** Overview link must take the **enabled `nav_link` branch** (not the disabled `<span>`) so `aria-current="page"` renders. Thread `active={@view}` for inbound too. Active conveyed non-color-alone (accent left-border + weight); holds light/dark/system.
- **D-04:** **Delete** the `operator-overview-nav` block (`operator_live.ex:416-448`). Drop the signpost subtitle.
- **D-05:** Health counts become click-throughs: Recent failures → `?view=deliveries&status=failed`; Active suppressions → `?view=deliveries&status=suppressed`; Orphan backlog → keep existing `support_cards.ex` focus drilldown (`phx-value-focus="orphan_backlog"`). `:failed`/`:suppressed` already in `@status_values` (`operator_live.ex:34`).
- **D-06:** Drill-through = **wrap** `stat_card` in `<.link patch={...}>`, NOT embed `<a>` inside the primitive. `stat_card` stays a presentational `<article>`.
- **D-07:** `orientation_strip` becomes **empty-pane-only** (render only on all-clear/empty). Collapse the all-clear Overview to a calm, short summary.
- **D-08:** Overview gets its own nav identity (`:overview`).
- **D-09:** **Paired test update (mandatory, same phase):** rewrite `operator.spec.js:352-368` (VERIF-02) to stop asserting `operator-overview-nav` is visible; flip BOTH `judgment.spec.js` gates `test.fixme`→`test`.
- **D-10:** Rewrite the Overview subtitle (triage framing; "Oops" banned; no sidebar-duplicating copy). Keep `orientation_strip` copy (`shell.ex:392-423`) **byte-frozen** — only its render condition changes.
- **D-11:** **Motion:** reuse existing token classes (`motion-reveal`, `transition-colors ease-out duration-(--duration-fast)`). Transform/opacity only. **No new keyframes / bespoke motion CSS.**
- **D-12:** **Asset landmine:** any Tailwind class change requires `mix mailglass_admin.assets.build` + committed `priv/static/app.css`. Watch the TokenParityTest landmine — the committed bundle is canonical.

### Claude's Discretion (resolved below — see flagged topics 1 & 2)
- All-clear vs attention-state IA layout — **resolved:** confirm the UI-SPEC's "calm single-line `<p>` + orientation strip (all-clear)" / "health stat_card row, no orientation strip (attention)". Severity-ordered; lead with the single most-urgent line. See Topic 1.
- Health-row vs `support_cards` dedup — **resolved:** they do NOT overlap on the Overview (support_cards renders only in the Deliveries detail context, `operator_live.ex:598`). Keep both; no merge. See Topic 2.
- Overview nav icon — **resolved:** `hero-squares-2x2` is **NOT embedded** in `heroicons-inline.js` (see Implementation Seams). Either embed + rebuild, or use an already-embedded glyph. Recommendation below.

### Deferred Ideas (OUT OF SCOPE)
- Deliveries filters-on-empty / label-tripling (Phase 120). Inbound (121). Preview (122). Arming new judgment gates into the ratchet floor + pillar re-score (Phase 123). Storybook chrome on-brand (123, optional).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SHELL-01 | Nav active-state correctness + Overview nav identity | `active` enum at `shell.ex:201` extends to `[:overview, :deliveries, :inbound]`; `@view` already resolves to all three (`operator_live.ex:55` mount default `:overview`, `:836-838` overview path, `:141` deliveries path); caller literal at `:349`. nav_link emits `aria-current` correctly (`components.ex:230`). |
| SHELL-02 | Overview → triage destination (drill-through health, empty-pane orientation) | `build_path/4..5` confirmed (`operator_live.ex:898`); `@base_path`/`@filter_params`/`@dark_chrome` assigns confirmed; `all_clear?/1` predicate at `:1150`; `support_cards` orphan drilldown at `support_cards.ex:102-104`. |
| SHELL-03 | Microcopy + motion + paired-test mechanics | Subtitle at `operator_live.ex:356-363`; orientation copy frozen at `shell.ex:392-423`; motion tokens confirmed in `app.css:327`; test seams at `operator.spec.js:352-368` + `judgment.spec.js:77,102`. |
</phase_requirements>

## Summary

Phase 119 is a **surgical IA correction**, not a rebuild — and the codebase confirms the UI-SPEC's central premise: the shell's active logic is already correct, and the only false-active source is one hardcoded literal (`operator_live.ex:349`). I verified every cited line; the CONTEXT/UI-SPEC line numbers are **accurate** with two exceptions noted in Implementation Seams (TokenParityTest path; the `aria-current="false"` assertion in the drafted gate).

The two flagged research topics resolve cleanly against the real code and IA best practice:

1. **Overview-as-triage IA** — The UI-SPEC's resolution (calm single-line all-clear + orientation strip; health stat_card row + no strip for attention) is **confirmed sound** and aligns with the GOV.UK task-list principle: *de-emphasize the cleared state so attention flows to what needs action.* Concrete refinement below: severity-order the attention row (failures → orphans → suppressions → overall), and guard the all-clear predicate against a nil `@support_summary` (the existing `all_clear?/1` raises on nil).

2. **Health-row vs support_cards dedup** — **No same-page overlap exists.** `support_cards` renders only inside the Deliveries *selected-delivery detail* context (`operator_live.ex:598`), driven by `@support_state`/`event_id`. The Overview health is the 4-`stat_card` row. They share the `@support_summary` data source but are distinct surfaces. Recommendation: keep both, do not merge — merging would couple a per-delivery support window to the tenant-level overview.

**Primary recommendation:** Execute exactly the 12 locked decisions. Spend implementation care on three real landmines: (a) `hero-squares-2x2` is not embedded (icon choice forces an embed+rebuild or a substitute glyph); (b) the drafted `judgment.spec.js:87` asserts `aria-current="false"` but the real `nav_link` *omits* the attribute when inactive — fix the assertion; (c) the all-clear render gate must null-guard `@support_summary` or `all_clear?/1` raises.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Nav active-state resolution | Frontend Server (LiveView caller) | — | `@view` is computed server-side in `operator_live.ex`; the shell is a pure presentational component. The bug is a caller-side literal, not a shell or client concern. |
| Drill-through link construction | Frontend Server (LiveView) | — | `build_path/4` runs in the render; links are stable URLs (`patch=`), no client routing. |
| Orphan drilldown | Frontend Server (LiveView `phx-click`) | — | Server event `open_support_exemplar` already exists in `support_cards.ex`; reused as-is. |
| Health data | API/Backend (`Mailglass.Operator.SupportSummary` / `Suppressions`) | Frontend Server | `summarize_tenant` + `count_active_suppressions` are core read-model calls (`operator_live.ex:802,819`); admin only renders. |
| Theme / active visual treatment | CDN/Static (committed `app.css`) | Browser | daisyUI semantic tokens compiled into the canonical bundle; no runtime CSS. |

## Standard Stack

No new packages. This phase uses only in-repo components and the existing zero-Node pipeline. [VERIFIED: codebase]

| Library / asset | Version | Purpose | Why Standard |
|-----------------|---------|---------|--------------|
| Phoenix LiveView | (project pin) | Server-rendered operator surface | Already the operator stack |
| Tailwind v4 + daisyUI 5 (standalone Hex binary) | (project pin) | Semantic-token styling, no npm | Zero-Node *shipped* pipeline (CLAUDE.md, D-12) |
| `heroicons-inline.js` (vendor plugin) | in-repo | Embedded SVG icons, no heroicons dep | Project landmine documented in MEMORY |

**Installation:** none.

## Package Legitimacy Audit

Not applicable — this phase installs **zero** external packages. All components are in-repo (`MailglassAdmin.Components.*`, `MailglassAdmin.Operator.*`). [VERIFIED: codebase]

## Architecture Patterns

### System Architecture Diagram

```
URL (?tenant_id=&view=)  ──►  OperatorLive (mount/handle_params)
                                   │  computes @view ∈ {:overview,:deliveries,:inbound}
                                   │  assign_overview_state/2 → @support_summary, @suppression_count
                                   ▼
                    render/1 (operator_live.ex:347)
                                   │ active={@view}  ◄── FIX (was literal :deliveries)
                                   ▼
                       Shell.shell (shell.ex:216)
                          ├─ <aside> sidebar nav  ──►  nav_link(active={@active==:overview|…})
                          │                              └─ aria-current={@active && "page"}  (components.ex:230)
                          ├─ <header> mobile nav  ──►  nav_pill (same active resolution)
                          └─ <main> render_slot ──►  Overview branch (operator_live.ex:373-466)
                                   │
                       ┌───────────┴───────────────┐
              all-clear state               attention state
              (support_summary clear         (failures/orphans/suppressions > 0)
               AND suppression_count==0)            │
                     │                              ▼
            calm <p> + orientation_strip     Health row: 4 stat_cards
            (empty-pane-only, D-07)          ├─ failures  ─► <.link patch=?status=failed>
                                             ├─ orphans   ─► phx-click focus (support_cards event)
                                             ├─ suppress. ─► <.link patch=?status=suppressed>
                                             └─ overall   ─► (no link)
                                             (NO orientation strip)
```

### Recommended structure (no new files — edits only)
```
mailglass_admin/lib/mailglass_admin/
├── operator/shell.ex          # +:overview enum, +Overview nav_link, +Overview nav_pill
├── operator_live.ex           # :349 literal→@view; :356-363 subtitle; :373-466 overview branch
└── components.ex              # untouched (stat_card/nav_link already correct)
mailglass_admin/assets/vendor/heroicons-inline.js  # +hero-squares-2x2 IF chosen (else no change)
mailglass_admin/priv/static/app.css                # rebuild IF any new class added
mailglass_admin/e2e/operator.spec.js               # :352-368 rewrite
mailglass_admin/e2e/judgment.spec.js               # :77,:102 fixme→test (+ :87 assertion fix)
```

### Pattern 1: Overview-as-triage (all-clear vs attention) — Topic 1 resolution
**What:** A dashboard landing that answers "what needs me now?" in one glance, with the cleared state visually *receding* rather than matching the attention state's height.
**When to use:** The Overview branch (`operator_live.ex:373`).
**Confirmed against GOV.UK task-list IA** [CITED: design-system.service.gov.uk/components/task-list/]: *completed items use plain text with no badge so attention flows to items needing action.* This is exactly the empty-pane-only / calm-all-clear resolution (D-07). The on-call/SRE convention is the same: surface actionable signals, suppress noise.

Refinements (concrete, codebase-grounded):
- **Attention state ordering = severity-first:** failures (`:error`) → orphans (`:warning`) → suppressions (`:info`) → overall (summary). The existing `support_metric_severity/3` already encodes `:error`/`:warning`/`:info`; keep the existing card order at `operator_live.ex:381-412` (it already matches this severity descent). No reorder needed — **confirm and move on.**
- **Lead-with-most-urgent vs 4-card grid:** Keep the 4-card grid (`sm:grid-cols-2 lg:grid-cols-4`, `operator_live.ex:380`). A single-most-urgent banner would *hide* the other three signals an SRE needs at a glance and would diverge from the existing scannable KPI-tile convention. The grid + severity color + drill-through link is the least-surprise triage shape. The "lead with most urgent" intent is satisfied by severity *coloring/ordering within the grid*, not by collapsing to one card.
- **All-clear copy + shape:** single `<p>` ("Your delivery system is healthy — nothing needs your attention right now.") + orientation strip. Confirmed compact for 320/375 (D-MOBILE-INFODUMP) — it replaces a 4-card grid + deleted nav block with one line + one strip.

### Pattern 2: Drill-through by wrapping (a11y) — D-06
**What:** Wrap the presentational `stat_card` `<article>` in `<.link patch={...}>` at the call site.
**Verified:** `stat_card` (`components.ex:380-412`) is a pure `<article>` with `{@rest}` passthrough and **no inner `<a>`/`<button>`** — so a wrapping `<.link>` is nested-interactive-clean. [VERIFIED: codebase]
**Example (the failures card — grounded in the real `build_path/4` arity):**
```elixir
# Source: operator_live.ex build_path/4 (line 898) + stat_card (components.ex:380)
<.link
  patch={build_path(@base_path, Map.put(@filter_params, "view", "deliveries") |> Map.put("status", "failed"), nil, @dark_chrome)}
  class="block mg-focus-ring rounded-box hover:border-primary transition-colors ease-out duration-(--duration-fast)"
  aria-label="View recent failures in Deliveries"
>
  <Components.stat_card label="Recent failures" value={...} ... />
</.link>
```
Note: `build_path/5` has a defaulted 5th arg (`support_state \\ default_support_state()`); the **4-arg call is correct** and is the form already used throughout (`operator_live.ex:427,587`). The UI-SPEC's proposed call compiles. The `hover:border-primary` belongs on the **wrapper**, not the card (do not mutate the primitive) — but note `border-primary` is already in the bundle (active nav uses it), so likely no rebuild for that class alone; verify (`hover:border-primary` variant may be new — see Implementation Seams).

### Pattern 3: Empty-pane-only orientation gate — D-07
**What:** Render `orientation_strip` only when all-clear/empty; suppress otherwise.
**Render gate (null-safe — critical):**
```elixir
# all_clear?/1 (operator_live.ex:1150) RAISES on nil — must guard:
<%= if @support_summary && all_clear?(@support_summary) && (@suppression_count in [0, nil]) do %>
  <MailglassAdmin.Operator.Shell.orientation_strip surface={:deliveries} />
<% end %>
```
The orientation strip's `<h2>` (`shell.ex:382`) shares heading level with the deleted Health `<h2>` — in the all-clear path the Health row is absent, so no `<h2>` collision. Keep the page `<h1>` (shell title) → strip `<h2>` hierarchy intact (no skipped levels). **Confirmed against A11y contract.**

### Anti-Patterns to Avoid
- **Rewriting the shell active logic** — it is correct (`shell.ex:235`, `components.ex:230`). The bug is the caller literal only. (D-02)
- **Embedding `<a>` inside `stat_card`** — nested-interactive violation; wrap instead. (D-06)
- **Inventing a Deliveries `status=` filter for orphans** — none maps; use the existing `support_cards` focus drilldown. (D-05)
- **Calling `all_clear?/1` on a nil summary** — it raises; guard with `@support_summary && …`.
- **Asserting `aria-current="false"`** in the gate — the real component omits the attribute when inactive (see Seams).
- **Blind `mix assets.build` + commit** — TokenParityTest landmine; run the gate first. (D-12)

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Active-nav resolution | A new active-state map in the caller | `active={@view}` — `@view` already resolves all three values | Shell + nav_link already correct; one literal swap |
| Filtered Deliveries URL | String concatenation of query params | `build_path/4` (`operator_live.ex:898`) | Handles theme, page-1 stripping, blank rejection, encoding |
| Orphan drilldown | A new orphan view | `support_cards.ex` `phx-value-focus="orphan_backlog"` (`:103`) | Ships today; expands oldest unmatched reconcile fact |
| aria-current emission | Manual `aria-current` in template | `nav_link`/`nav_pill` enabled branch | `components.ex:230,275` emit it from `@active` |
| Reveal motion | New `@keyframes` | `.motion-reveal` (`app.css:327`) + `transition-colors duration-(--duration-fast)` | Reduced-motion already neutralizes `.motion-*` |

**Key insight:** Nearly the entire phase is *deletion + one literal swap + wrapping existing primitives in links*. The only genuinely new artifact is one nav link/pill instance (+ possibly one embedded icon SVG).

## Runtime State Inventory

Not a rename/refactor/migration phase — this is a UI/IA correction with no stored-state, service-config, OS-registration, secret, or build-artifact rename. **None found in any category — verified by scope (no string-rename, no datastore key change, no env/secret touch).** The only build artifact affected is the committed `priv/static/app.css` bundle, which is a normal asset rebuild (D-12), not stale runtime state.

## Common Pitfalls

### Pitfall 1: `hero-squares-2x2` is not embedded
**What goes wrong:** Using `<.icon name="hero-squares-2x2">` renders an invisible/blank icon — no compile or test error catches it (the heroicons-inline landmine, MEMORY).
**Why:** `heroicons-inline.js` embeds a fixed SVG set. Verified embedded keys: `arrow-path, arrow-uturn-left, bell-slash, building-office-2, chart-bar, check-circle, clock, device-phone-mobile, display, envelope, envelope-open, exclamation-circle, exclamation-triangle, eye, hand-thumb-up, inbox, inbox-arrow-down, inbox-stack, lifebuoy, lock-closed, magnifying-glass, minus-circle, moon, paper-airplane, pencil-square, question-mark-circle, sun, vertical-align, window, x-circle`. **`squares-2x2` and `home` are both absent.** [VERIFIED: codebase]
**How to avoid:** Either (a) embed the `hero-squares-2x2` outline SVG into `heroicons-inline.js` and rebuild the bundle, OR (b) pick an already-embedded semantically-correct glyph. **Recommendation:** `hero-chart-bar` (already embedded; reads as "at-a-glance metrics/health" — semantically apt for a triage overview) or `hero-window` (already embedded; "the landing pane"). If the maintainer insists on `squares-2x2`, embed it. The UI-SPEC argued against `hero-home`; `hero-chart-bar` satisfies that argument and avoids the embed+rebuild.
**Warning signs:** Blank space where the Overview nav icon should be; no test failure.

### Pitfall 2: VERIF-02 contradiction (paired test, D-09)
**What goes wrong:** Deleting `operator-overview-nav` turns `operator.spec.js:352-368` red (it asserts that testid IS visible at line 367), while `judgment.spec.js:111` asserts it has count 0 — directly opposed.
**Why:** VERIF-02 was written for the old homepage shape.
**How to avoid:** In the SAME phase, rewrite `operator.spec.js:367` to drop the `operator-overview-nav` assertion (keep `operator-overview` + `operator-overview-health`), and flip both `judgment.spec.js` gates `test.fixme`→`test`. The operator browser gate is green-only-forward. [VERIFIED: codebase — exact lines confirmed]

### Pitfall 3: drafted gate asserts the wrong inactive value
**What goes wrong:** `judgment.spec.js:87` asserts `await expect(deliveriesLink).toHaveAttribute("aria-current", "false")`. The real `nav_link` emits `aria-current={@active && "page"}` — when inactive this is boolean `false`, which **Phoenix omits entirely** (no attribute rendered). The existing unit test confirms this: `components_test.exs:260` `refute html =~ ~s(aria-current="page")` (omitted, not `="false"`). So flipping the gate to `test` as-written makes it **fail**.
**Why:** The gate was drafted in Phase 118 ahead of the implementation; the assertion guessed the inactive representation.
**How to avoid:** When flipping the gate, change line 87 to `await expect(deliveriesLink).not.toHaveAttribute("aria-current", "page")` (or use `getByRole("link", { name: "Deliveries", current: false })`). This is a **required edit to the gate**, not just a `fixme`→`test` flip. Flag explicitly in the plan.
**Warning signs:** `nav-active-correctness` gate red immediately after flipping, on the Deliveries assertion line.

### Pitfall 4: `all_clear?/1` raises on nil
**What goes wrong:** The render gate `all_clear?(@support_summary)` raises `KeyError`/`BadMapError` when `@support_summary` is nil (summarize raised or tenant unscoped) — `all_clear?/1` (`:1150`) pattern-accesses `summary.failed_ingest.count`.
**Why:** `assign_overview_state/2` sets `support_summary` to `nil` on rescue (`operator_live.ex:810`) or when no tenant.
**How to avoid:** Guard: `@support_summary && all_clear?(@support_summary)`. Treat nil summary as **attention/unavailable** (not all-clear) so the orientation strip is suppressed and the existing `:unavailable` stat_card states render. The subtitle predicate (D-10) must use the same guarded condition.

### Pitfall 5: TokenParityTest asset landmine (D-12)
**What goes wrong:** A fresh `mix mailglass_admin.assets.build` emits raw-inline daisyUI theme blocks that break `token_parity_test.exs` if committed naively (MEMORY: token-parity bundle landmine).
**Why:** The committed bundle is canonical/curated; daisyUI 5.5.x re-emits theme blocks on rebuild.
**How to avoid:** Only rebuild if a genuinely new utility class is introduced. Run `mix test mailglass_admin/test/mailglass_admin/token_parity_test.exs` (NOTE: path is `test/mailglass_admin/token_parity_test.exs`, **not** the UI-SPEC's `test/mailglass_admin/components/token_parity_test.exs`) before committing the bundle. If no new class, skip the rebuild entirely.

## Code Examples

### Subtitle predicate (D-10, null-safe)
```elixir
# operator_live.ex:356-363 region — thread @view AND a guarded health predicate
subtitle={
  cond do
    @view != :overview ->
      "Prove what happened to a message — inspect its event timeline, suppression state, and replay history."
    @support_summary && all_clear?(@support_summary) && @suppression_count in [0, nil] ->
      "Your delivery system is healthy."
    true ->
      "Your delivery system needs attention."
  end
}
```

### New Overview nav link (shell.ex sidebar, above Deliveries)
```elixir
# Source: shell.ex:230-244 nav block; nav_link enabled branch (components.ex:226)
<Components.nav_link
  label="Overview"
  icon="hero-chart-bar"            # already embedded; OR embed hero-squares-2x2 first
  href={@overview_path}            # bare operator root, no ?view= ; see note
  active={@active == :overview}
/>
```
Note on href: the shell currently receives `@deliveries_path` and `@inbound_path`. The Overview link needs the **bare operator root**. Either pass a new `@overview_path` assign (the `@base_path` / root with theme but no `view`), or strip `view` from `@deliveries_path`. The `surface_paths/4` helper (`shell.ex`, called at `operator_live.ex:828`) already builds surface paths — the planner should add an `:overview` surface path (root, no `view`) rather than hand-stripping. Verify `surface_paths/4` shape during planning.

### Extend the active enum (shell.ex:201)
```elixir
attr(:active, :atom, values: [:overview, :deliveries, :inbound], required: true)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Overview = homepage that signposts elsewhere | Overview = triage destination with drill-through health | Phase 119 | The #1-pain surface becomes actionable |
| Hardcoded `active={:deliveries}` | `active={@view}` | Phase 119 | Nav stops lying about location |
| Orientation strip on every surface/state | Empty-pane-only | Phase 119 (pattern); 120 applies to Deliveries | Removes triplicate redundancy |

**Deprecated/outdated:** the `operator-overview-nav` "Navigate" cards (`operator_live.ex:416-448`) — duplicate the always-visible sidebar; deleted.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `surface_paths/4` can be extended to yield an `:overview` (root, no `view`) path cleanly | Code Examples | LOW — if not, strip `view` from `@deliveries_path` at the caller; either is a small caller edit |
| A2 | `hover:border-primary` is the only potentially-new Tailwind variant; `border-primary`/`block`/`rounded-box`/`mg-focus-ring` are already in the bundle | Pitfall 5 / Pattern 2 | LOW — if new, the rebuild+TokenParity gate (already mandated by D-12) catches it; verify with a `grep` of `priv/static/app.css` during planning |
| A3 | `hero-chart-bar` is the best already-embedded substitute for the Overview glyph | Pitfall 1 | LOW — maintainer may prefer embedding `squares-2x2`; both are viable, reversible |

**Note:** All three are LOW-risk and reversible; none blocks planning. No compliance/security/retention assumptions in this phase.

## Open Questions

1. **Overview glyph: embed `hero-squares-2x2` or use embedded `hero-chart-bar`?**
   - What we know: `squares-2x2` is not embedded; `chart-bar`/`window` are.
   - What's unclear: maintainer aesthetic preference.
   - Recommendation: default to `hero-chart-bar` (no embed, no rebuild risk); embed `squares-2x2` only if the maintainer asks. Reversible either way.

2. **`@overview_path` vs `view`-stripping for the Overview href.**
   - What we know: shell receives `@deliveries_path`/`@inbound_path`; `surface_paths/4` builds these.
   - Recommendation: add `:overview` to `surface_paths/4` (cleanest); fall back to caller-side strip if the helper resists.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix mailglass_admin.assets.build` (alias) | Asset rebuild on new class (D-12) | ✓ | `mailglass_admin/mix.exs:200` | none needed |
| Playwright (operator + judgment e2e) | D-09 paired gates | ✓ (e2e suite present) | `mailglass_admin/e2e/*` | run against `make demo` |
| `mix test` (TokenParity, components, shell) | Validation gates | ✓ | — | — |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** none.

## Validation Architecture

> nyquist_validation treated as enabled (no explicit `false` found).

### Test Framework
| Property | Value |
|----------|-------|
| Frameworks | ExUnit (unit/LiveView) + Playwright (operator/judgment/structural e2e) |
| Config files | `mailglass_admin/test/` (ExUnit) ; `mailglass_admin/e2e/` (Playwright) |
| Quick run command | `mix test mailglass_admin/test/mailglass_admin/operator/shell_test.exs mailglass_admin/test/mailglass_admin/components_test.exs` |
| Full suite command | `mix test` (admin scope) + `npx playwright test e2e/operator.spec.js e2e/judgment.spec.js e2e/structural.spec.js` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SHELL-01 | Overview route → Overview nav `aria-current=page`, Deliveries inactive | e2e | `npx playwright test e2e/judgment.spec.js -g "nav-active-correctness"` | ✅ (drafted; flip+fix :87) |
| SHELL-01 | nav_link enabled branch emits aria-current; inactive omits | unit | `mix test mailglass_admin/test/mailglass_admin/components_test.exs -o "nav_link"` | ✅ |
| SHELL-01 | shell active resolution across :overview/:deliveries/:inbound | unit | `mix test mailglass_admin/test/mailglass_admin/operator/shell_test.exs` | ✅ (extend for :overview) |
| SHELL-02 | populated Overview renders no `operator-overview-nav` | e2e | `npx playwright test e2e/judgment.spec.js -g "no-nav-duplication"` | ✅ (flip fixme→test) |
| SHELL-02 | Overview health cards visible; nav block gone | e2e | `npx playwright test e2e/operator.spec.js -g "operator overview landing"` | ✅ (rewrite :367) |
| SHELL-02 | failures/suppressions stat cards are drill-through links to filtered Deliveries | e2e | new assertion in `operator.spec.js` (link href contains `status=failed`/`status=suppressed`) | ❌ Wave 0 |
| SHELL-02 | orientation strip suppressed in attention state, present in all-clear | e2e | new assertion (helios-void all-clear vs northstar attention) | ❌ Wave 0 |
| SHELL-03 | subtitle = triage line, never "Oops"/"Navigate to" | unit/e2e | `mix test mailglass_admin/test/mailglass_admin/operator/shell_test.exs` (subtitle render) | ✅ (extend) |
| SHELL-03 | motion = existing tokens only; no new keyframes | static | `grep` diff of `app.css` shows no new `@keyframes` | ✅ (manual diff) |
| matrix | TokenParity holds after any rebuild | unit | `mix test mailglass_admin/test/mailglass_admin/token_parity_test.exs` | ✅ |
| matrix | 320/375/768/1024/1440 × light/dark/system, no h-overflow, all-clear ≤1 screen at 375 | e2e | re-shoot persona cells: `npx playwright test e2e/persona-screenshots.spec.js` (DEFECT-REGISTER seam) | ✅ (rerunnable) |

### Sampling Rate
- **Per task commit:** quick ExUnit (`shell_test.exs` + `components_test.exs`).
- **Per wave merge:** `operator.spec.js` + `judgment.spec.js` + `token_parity_test.exs`.
- **Phase gate:** full admin `mix test` + the three Playwright specs green + re-shot persona cells show only-forward improvement, before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `e2e/operator.spec.js` — add drill-through link assertions (failures→`status=failed`, suppressions→`status=suppressed`).
- [ ] `e2e/operator.spec.js` — add orientation-strip presence assertions keyed to all-clear vs attention persona.
- [ ] `e2e/judgment.spec.js:87` — fix the `aria-current="false"`→`not.toHaveAttribute("aria-current","page")` assertion (REQUIRED, not optional).
- [ ] `shell_test.exs` — extend `aria-current nav resolution` describe block to cover `:overview`.

## Security Domain

> `security_enforcement` not explicitly `false`; included for completeness.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Inherited host-app auth; no change |
| V3 Session Management | no | No change |
| V4 Access Control | yes (tenant scope) | Drill-through links carry `tenant_id` via `@filter_params`; `build_path/4` preserves tenant scope — verify the failures/suppressions links do not widen tenant scope. `count_active_suppressions/1` is tenant-scoped (`suppressions.ex:56`). |
| V5 Input Validation | yes | `:failed`/`:suppressed` are closed-set `@status_values` (`operator_live.ex:34`); no free-text param introduced |
| V6 Cryptography | no | None |

### Known Threat Patterns
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Tenant-scope widening via crafted drill-through URL | Elevation/Info disclosure | `build_path/4` merges existing `@filter_params` (which includes `tenant_id`); the read model re-scopes server-side. Confirm no link drops `tenant_id`. |
| Nested-interactive a11y (link-in-link) | (a11y, not security) | Wrap-don't-embed pattern (D-06); `stat_card` has no inner interactive element [VERIFIED] |

## Sources

### Primary (HIGH confidence)
- Codebase (verified line-by-line): `operator_live.ex` (`:34,:55,:349,:356-363,:373-466,:598,:798-840,:898,:1150`), `shell.ex` (`:201,:230-265,:361-423`), `components.ex` (`:208-285,:380-412`), `support_cards.ex` (`:20-240`), `heroicons-inline.js` (icon key set), `app.css:327`, `mix.exs:200`, `e2e/operator.spec.js:352-368`, `e2e/judgment.spec.js:65-113`, `components_test.exs:252-260`, `suppressions.ex:56`.
- `.planning/phases/119-.../119-CONTEXT.md`, `119-UI-SPEC.md` — locked decisions.
- `.planning/research/v1.14/DEFECT-REGISTER.md`, `STRESS-TEST-PROMPT.md` — binding rubric.

### Secondary (MEDIUM confidence)
- GOV.UK Design System — Task list pattern (status-label de-emphasis principle) [CITED: design-system.service.gov.uk/components/task-list/].

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new deps; all in-repo, verified.
- Architecture / IA: HIGH — UI-SPEC resolution confirmed against real code + GOV.UK IA.
- Pitfalls: HIGH — all five verified against actual lines (icon set, test contradiction, gate assertion drift, nil-raise, asset path).

**Research date:** 2026-06-26
**Valid until:** 2026-07-26 (stable internal codebase; re-verify line numbers if `operator_live.ex` is edited before planning)

## RESEARCH COMPLETE

**Phase:** 119 - App-shell + Nav + Overview redesign
**Confidence:** HIGH

### Key Findings
- Topic 1 (Overview-as-triage IA): UI-SPEC resolution **confirmed** — keep the 4-card severity-ordered grid (no collapse-to-one-card), all-clear = calm `<p>` + orientation strip. GOV.UK task-list IA backs de-emphasizing the cleared state. Severity order already matches the existing card order.
- Topic 2 (health-row vs support_cards dedup): **no same-page overlap** — `support_cards` renders only in the Deliveries selected-delivery detail (`operator_live.ex:598`), not on the Overview. Keep both, do not merge.
- Three concrete landmines flagged: (1) `hero-squares-2x2` is NOT embedded in `heroicons-inline.js` — embed+rebuild or use `hero-chart-bar`; (2) drafted `judgment.spec.js:87` asserts `aria-current="false"` but the real component omits the attribute — assertion MUST be fixed when flipping, not just `fixme→test`; (3) `all_clear?/1` raises on nil `@support_summary` — render gate must null-guard.
- All CONTEXT/UI-SPEC line numbers verified accurate, except: TokenParityTest is at `test/mailglass_admin/token_parity_test.exs` (not `.../components/...`); `build_path/4` arity confirmed (UI-SPEC's proposed call compiles).
- `@view` already resolves to `:overview`/`:deliveries`/`:inbound`; the entire SHELL-01 fix is the enum extension + one new nav link/pill + the `active={@view}` literal swap. Surgical.

### File Created
`.planning/phases/119-app-shell-nav-overview-redesign/119-RESEARCH.md`

### Confidence Assessment
| Area | Level | Reason |
|------|-------|--------|
| Standard Stack | HIGH | No new deps; in-repo, verified |
| Architecture | HIGH | UI-SPEC confirmed against real code + GOV.UK IA |
| Pitfalls | HIGH | All five verified against actual lines |

### Open Questions
- Overview glyph (embed `squares-2x2` vs use `chart-bar`) — recommended `chart-bar`; reversible.
- Overview href construction (`surface_paths/4` `:overview` vs strip `view`) — recommended extend the helper.

### Ready for Planning
Research complete. Planner can now create PLAN.md files.
