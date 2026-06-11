# Phase 75: Information Architecture, Navigation and Orientation - Context

**Gathered:** 2026-06-04 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 75 is the first **build phase** of milestone v1.7 (Admin UI — IA & Design-System Polish v2). It delivers information architecture, navigation, and orientation across the three `mailglass_admin` operator surfaces — touching **only `mailglass_admin` source** plus **one additive core `mailglass` read-model function**. Four requirements:

1. **IA-01** — Generalize the Deliveries-only private orientation strip into a shared `Shell.orientation_strip/1` public function component rendered on all three surfaces (Deliveries, Inbound, Preview) with per-surface symptom-first copy and testids.
2. **IA-02** — A task-oriented **Operator Overview** as a `:overview`-style state on the existing `OperatorLive` (handled in `handle_params/3`, **zero router-macro change**), surfacing at-a-glance health (orphan backlog, recent failures, suppression count) and routing to Deliveries/Inbound.
3. **IA-03** — One deliberate IA vocabulary (page titles, subtitles, headings) across surfaces, with `operator.spec.js` + `demo.spec.js` heading assertions updated **in the same commit** (no Playwright failures after).
4. **IA-04** — An explicit, recorded **in-scope / deferred decision** for the deep-link-unstyled-CSS bug (GAP-22) — it touches the stable asset-serving seam.

**In scope:** orientation-strip generalization; Operator Overview landing; IA vocabulary normalization + same-commit e2e updates; one additive core `count_active_suppressions/1`; the deep-link disposition decision; the a11y attributes the *new* Overview/nav surface requires.

**Out of scope (later phases / locked exclusions):** the unified `status_badge/1` atom and support-card hierarchy restructure (Phase 76 — GAP-13/14); motion-reveal re-fire fix (Phase 77 — GAP-19); seed expansion (Phase 78); router macro changes; `MailglassAdmin.Auth` behaviour; replay semantics; operator session contract; bumping `reference/host_app`/`demo_app` version pins; any new product/observability feature.

**Anti-churn gate:** every build task must cite a Phase 74 gap-register row at severity ≥ 3. Phase 75 owns: **GAP-07, GAP-09, GAP-11** (390px orientation readability), **GAP-21** (a11y — Overview subset), **GAP-22** (deep-link disposition, IA-04).
</domain>

<decisions>
## Implementation Decisions

All decisions below are grounded in codebase analysis (verified file:line) and the frozen `74-UI-SPEC.md`. Where the UI-SPEC already locks a decision it is marked "(locked by UI-SPEC)".

### Orientation Strip (IA-01)
- **D-01:** Extract the existing `orientation_strip/0` private defp (`operator_live.ex:362`) into a **public** `MailglassAdmin.Operator.Shell.orientation_strip/1`, placed after `flash_region/1` in `shell.ex` (locked by UI-SPEC §Orientation Strip Contract).
- **D-02:** The component takes a single discriminated `attr :surface, :atom, values: [:deliveries, :inbound, :preview]` with the **frozen per-surface copy table baked in** (heading + symptom-first bullets from UI-SPEC:302-308). Callers vary only which surface they are. Rationale: the copy is frozen, so a `surface` discriminator matches the spec table shape exactly and prevents the three-way copy divergence this milestone exists to eliminate. Precedent: shell's existing `attr :active` discriminator (`shell.ex:102`).
- **D-03:** Per-surface root testids `{surface}-orientation` (`deliveries-orientation`, `inbound-orientation`, `preview-orientation`). The Deliveries strip's extraction must not break any e2e assertion (operator.spec.js does not currently assert the orientation testid — confirmed safe).
- **D-04:** Render triggers (all already present in code): Deliveries `is_nil(@selected_delivery)` (`operator_live.ex:254`); Inbound `is_nil(@detail)` (`inbound_live.ex:330`); Preview `@mailables == []` (`preview_live.ex:291`).
- **D-05:** No motion on the orientation strip (always-visible, not action-triggered) — locked by UI-SPEC §Motion Rules.

### Preview Empty-State Co-existence (IA-01, D-09 from Phase 74)
- **D-06:** The orientation strip **supplements** (does not replace) the existing zero-mailables empty state at `preview_live.ex:291-323`. Preserve the existing `preview-empty-mailables` testid and the existing router-config adopter hint (`mailglass_admin_routes "/mail", mailables: [...]`), which carries value beyond the spec's three bullets. (UI-SPEC:308 explicitly defers this co-existence call to Phase 75.)

### Operator Overview Routing (IA-02) — the one genuine design fork
- **D-07:** **No router change** (confirmed: `router.ex:261` is `live "/", OperatorLive, :index` — the only operator route besides `live "/inbound", InboundLive, :index` at line 270; there is no `:overview` action and no `/deliveries` route). The Overview is therefore a **params-based branch inside `OperatorLive.handle_params/3`** (`operator_live.ex:71`), not a real Phoenix `live_action`. `live_action` stays `:index`; shell still receives `active={:deliveries}` (locked by UI-SPEC §Route Mechanics). The UI-SPEC's "`:overview` action" language is interpreted as this params-based state.
- **D-08:** **Landing model:** bare `/ops/mail/` (no list-intent params) → **Operator Overview**. An explicit `?view=deliveries` query param (set by the Overview's "View Deliveries" card via `push_patch`) → the existing Deliveries master-detail list. `view` is the discriminator; `tenant_id` stays orthogonal so it can be set on either view. Rationale: tenant_id cannot be the discriminator — Overview-with-health requires a tenant, so a tenant-keyed discriminator would make Overview-with-health and the deliveries list mutually unreachable. The `?view=deliveries` param is an internal URL convention (not a stable seam), reversible if a different shape is preferred during planning.
- **D-09:** **Tenant-context branch** (locked by UI-SPEC:292): Overview with no `tenant_id` → orientation strip + "Select a tenant to see health at a glance." nudge; with `tenant_id` set → render the health-count row.
- **D-10:** **Overview layout** (locked by UI-SPEC §Operator Overview Layout): orientation strip → horizontal row of 4 compact health-count cards (Recent failures / Orphan backlog / Active suppressions / All-clear) → two full-width navigation cards ("View Deliveries", "View Inbound"). Health counts use the UI-SPEC Health Count Colors rules. CTA copy frozen ("View Deliveries", "View Inbound") per UI-SPEC §Copywriting Contract.

### Suppression Count Core Function (IA-02)
- **D-11:** Add `count_active_suppressions/1` to **core `mailglass`** at `lib/mailglass/operator/suppressions.ex` — a purely additive, tenant-scoped count mirroring the active-entry filter already in `get_delivery_suppression_state/2` (`tenant_id ==` + `is_nil(expires_at) or expires_at > now` + `Tenancy.scope/2`). Confirmed absent today (only `get_delivery_suppression_state/2` exists at `suppressions.ex:18`). It belongs in core, not admin, per the read-model boundary rule (`operator_live.ex` moduledoc: all data access stays behind core operator read-model modules).
- **D-12:** The Overview reads the count through the existing runtime-module-indirection seam (mirroring `support_summary_module/0` at `operator_live.ex:670`) so a missing/erroring count **degrades to a neutral "—"** rather than crashing the Overview. (Suppression health color is `text-secondary`/informational per UI-SPEC:218, so neutral degradation is visually consistent.)
- **D-13:** **Cross-package acknowledgment:** this is the milestone's single core touch. It is benign and additive, but it means Phase 79's linked-version release produces matched bumps across all three packages — already expected/acknowledged (UI-SPEC:441-443). Other two health counts (failed_ingest, orphan_backlog) already exist on `SupportSummary.summarize_tenant/1` (`support_summary.ex:29-34`); no change there.

### IA Vocabulary + Same-Commit e2e (IA-03)
- **D-14:** Existing surface titles are already conformant ("Deliveries" `operator_live.ex:250`, "Inbound records" `inbound_live.ex:271`); the principal new heading is the Overview **h1 "Operator overview"** (single h1 per page; h2 for the health and navigation sections).
- **D-15:** Changing the bare-root render from the Deliveries list to the Overview **will** change/break heading assertions in `operator.spec.js` (`:19`, `name: "Deliveries"`) and `reference/demo_app/assets/e2e/demo.spec.js` (`:27`, `:41`). These assertion edits ship in the **same commit** as the IA change (IA-03 mandate — no red Playwright across the commit boundary). `demo.spec.js:15` "Northstar Ops" is the host app's own heading, out of scope. Consult `74-ASSERTION-INVENTORY.md` for the full rippled-assertion list.

### Accessibility (IA-02, GAP-21)
- **D-16:** Phase 75 a11y scope is confined to the **new** Overview/nav surface: `aria-current="page"` on the active nav state and a semantic h1/h2 hierarchy on the Overview. `aria-selected` on list rows already exists (operator.spec.js:47), `aria-current` already exists in shell nav (`shell.ex`); `role="dialog"`/`aria-modal` on modals and broader component a11y are Phase 76. Do not front-run them.

### Deep-Link Disposition (IA-04)
- **D-17:** **Decision: DEFER the deep-link-unstyled-CSS bug (GAP-22) to Phase 79** (VERIF-04), with this recorded rationale: a robust fix touches the **stable asset-serving seam** (`docs/design-system.md:141-150` — relative `css-<md5>` URL resolves against the deep path on hard refresh), which is explicitly out of churn scope for v1.7. The bug is stable under normal in-app live navigation; only a hard refresh on a deep URL loads unstyled. GAP-22 is held at severity 3 so it does not false-block Phase 79 closeout before the decision is reconfirmed there. This is a **documentation/decision deliverable, not a code fix**, and satisfies IA-04.

### 390px Acceptance (IA-03, GAP-07/09/11)
- **D-18:** 390px acceptance is verified via the established **local screenshot→LLM-critique ritual** (`tmp/ui-audit/{surface}-390-{light,dark}.png` per the audit manifest) **plus** the existing Playwright 390px structural test (`operator.spec.js:64-89`, viewport 390, list-before-detail stacking), extended to assert the orientation strip remains visible/readable at 390px. No CI-promoted visual regression (out of scope, VR-NEXT-01). A 390px screenshot review is required before IA merge (GAP-07/09/11 acceptance note).

### Claude's Discretion
- Exact internal structure of the per-surface copy table inside `orientation_strip/1` (case/map/function-clause) — any clean form is fine.
- Precise HEEx markup of the Overview health-count cards and navigation cards within the locked layout and token rules (Phase 76 will tokenize; Phase 75 should already prefer token utilities for new markup to avoid re-touch).
- Whether the `?view=deliveries` discriminator is a query param vs. a sentinel filter value — query param recommended; planner may refine.
- Exact wording of any new Overview subtitle (within the IA vocabulary + copywriting voice).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/phases/74-systematic-audit-and-ui-spec/74-UI-SPEC.md` — **frozen (`status: approved`) design contract.** MUST read. Authoritative for: Operator Overview Layout Spec (§ ~269), Orientation Strip Contract + per-surface copy table (§ ~296), Copywriting Contract (§ ~447), Motion Rules, per-surface acceptance checklists (§ ~377), Health Count Colors.
- `.planning/phases/74-systematic-audit-and-ui-spec/74-GAP-REGISTER.md` — anti-churn citation gate. Phase 75 rows: GAP-07, GAP-09, GAP-11 (390px), GAP-21 (a11y), GAP-22 (deep-link). **Note the line-193 mis-tag**: it lists GAP-13/GAP-19 under IA-01, but GAP-13 is Phase 76 (support cards) and GAP-19 is Phase 77 (motion) — do not pull them in.
- `.planning/phases/74-systematic-audit-and-ui-spec/74-ASSERTION-INVENTORY.md` — every e2e/demo heading + seed-count assertion that Phase 75 will ripple (IA-03 same-commit source of truth).
- `.planning/research/v1.7-admin-ui-polish/FEATURES.md` — Operator Overview §1, orientation §1, empty-state copy rules.
- `.planning/research/v1.7-admin-ui-polish/ARCHITECTURE.md` — concrete file:line references for the structural changes.
- `.planning/research/v1.7-admin-ui-polish/PITFALLS.md` — esp. Pitfall 15 (390px audit gap), Pitfall 16 (deep-link), Pitfall 4 (restructure-before-tokenize — Phase 76, but informs ordering).
- `.planning/research/v1.7-admin-ui-polish/STACK.md` — Tailwind v4 / daisyUI 5 / LiveView mechanics; daisyUI class names must be verified against the installed plugin, not web search.
- `.planning/ROADMAP.md` — Phase 75 success criteria + cross-cutting anti-churn contract.
- `.planning/REQUIREMENTS.md` — IA-01..IA-04 acceptance criteria.
- `mailglass_admin/docs/design-system.md` — 6 conformance pillars, audit ritual, `tmp/ui-audit/` gitignore contract, deep-link Known Limitations note (lines 141-150, the IA-04 subject).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`operator_live.ex:362` `orientation_strip/0`** — the existing private defp to extract and generalize (D-01).
- **`shell.ex:102` `attr :active`** — the surface-discriminator precedent for the new `attr :surface` (D-02); `flash_region/1` is the placement anchor for the new public component.
- **`operator_live.ex:670` `support_summary_module/0`** — the runtime-module-indirection seam to mirror for the suppression-count read (D-12, graceful degradation).
- **`support_summary.ex:29-34` `summarize_tenant/1`** — already returns `failed_ingest.count` and `orphan_backlog.count` (two of the three Overview health counts; no change needed).
- **`suppressions.ex:26-28`** — the active-entry filter (`tenant_id ==`, `is_nil(expires_at) or expires_at > now`, `Tenancy.scope/2`) to mirror in the new `count_active_suppressions/1` (D-11).
- **`preview_live.ex:291-323`** — existing `preview-empty-mailables` empty state to supplement, not replace (D-06).
- **`operator.spec.js:64-89`** — existing 390px viewport structural test to extend (D-18).

### Established Patterns
- **Single `:index` operator route** — `router.ex:261`/`:270`; the Overview/Deliveries split is params-based, not action-based (D-07). Router macro is a stable seam — untouchable.
- **Core read-model boundary** — all admin data access goes through core `Mailglass.Operator.*` read-model modules; the suppression count therefore lands in core, not admin (D-11).
- **`load_deliveries(%{"tenant_id" => ""}) -> []`** (`operator_live.ex:417`) — bare root with no tenant currently yields an empty deliveries list; the Overview replaces this default landing.
- **Bundle gate** — `git diff --exit-code priv/static/`; rebuilt admin bundle must be committed in the same PR as any HEEx change (Phase 76 emphasis, but applies whenever assets change).

### Integration Points
- `OperatorLive.handle_params/3` (`operator_live.ex:71`) — where the Overview-vs-Deliveries branch lives (D-07/D-08).
- `Shell` (`shell.ex`) — new public `orientation_strip/1` rendered by all three LiveViews.
- Core `mailglass` `lib/mailglass/operator/suppressions.ex` — the one cross-package additive change (D-11/D-13).
- e2e: `mailglass_admin/e2e/operator.spec.js` + `reference/demo_app/assets/e2e/demo.spec.js` — same-commit heading-assertion updates (D-15).
</code_context>

<specifics>
## Specific Ideas

- The Operator Overview **at the bare root** is the headline deliverable: a cold operator at `/ops/mail/` must know within one screen what to do and where to go (ROADMAP Phase 75 goal). The `?view=deliveries` param is the deliberate mechanism that keeps the list reachable without a router change.
- The orientation copy is **symptom-first** ("Email never arrived? Start here.") — verbatim from the frozen UI-SPEC table; do not paraphrase.
- IA-04 is a **decision artifact**, not code: defer GAP-22 to Phase 79 with the recorded asset-seam rationale. Leaving it ambiguous is the Pitfall-16 failure mode.
- Prefer token utilities for all new Overview markup now, even though Phase 76 owns the global token migration — new code should not add to the GAP-16/17 debt.
</specifics>

<deferred>
## Deferred Ideas

- **Unified `status_badge/1` atom + delete 5 `badge_class/1` copies** — Phase 76 (DS-01, GAP-01..06). Not Phase 75.
- **Support-card primary/secondary hierarchy restructure** — Phase 76 (DS-03, GAP-13/14); restructure-before-tokenize ordering (Pitfall 4). Phase 75 must not front-run it.
- **Motion-reveal re-fire fix (delivery-keyed id)** — Phase 77 (MOTION-01, GAP-19).
- **Global token migration (type + spacing) + committed bundle** — Phase 76 (DS-02/DS-04, GAP-16/17).
- **Robust deep-link asset fix** — deferred to Phase 79 per D-17 (touches stable asset-serving seam).
- **CI-promoted visual regression / LLM-critique automation** — VR-NEXT-01, explicitly out of v1.7 scope.

### Reviewed Todos (not folded)
None — no pending todos matched Phase 75 scope.
</deferred>
