# Phase 121: Inbound surface redesign - Context

**Gathered:** 2026-06-28 (assumptions mode + 4-area research synthesis)
**Status:** Ready for planning

<domain>
## Phase Boundary

Redesign the **Inbound** admin surface to be consistent with the cleaned-up **Deliveries**
surface (Phase 120) — streamlined, non-info-dump, least-surprise — **while preserving the
PII/raw-payload-default-hidden boundary and the replay safety contract**. Inbound is surface #3
of 4 in the v1.14 biggest-impact-first order (119 → 120 → **121** → 122). The DEFECT-REGISTER
records "no net-new headline defect — 121 applies 120's cleanup" (line 288): **Inbound is the
as-built "before" picture of Deliveries** — it still renders the orientation strip always-visible
below a populated table and never applies the single-calm-pane no-data gate. The core job is to
**port Deliveries' D-01..D-13 verbatim onto the Inbound render branch**, fix the accidental drifts
the mechanical mirror does not name, and bring the surface to the roadmap's success-criterion-3
bar (WCAG 2.2 AA + APG, predictable dialogs incl. the replay modal).

**Scope decision (this phase): "Mirror + in-scope a11y/correctness fixes."** Beyond the
empty-state IA port + paired-test updates, this phase also: (a) **wires the dormant `data_state`**
error/permission-denied/stale states (built into `RecordsList` but never passed from
`inbound_live.ex` — currently dead code); (b) hardens the **PII raw-payload reveal** affordance to
a true ARIA disclosure + adds a "Re-redact" collapse + a PII-free reveal telemetry count; (c)
closes the two **replay-modal APG gaps** (Tab focus-trap + double-submit pending-lock) on **both**
the Inbound and Deliveries replay modals (cross-surface coherence). All three are justified by
roadmap success-criterion 3, not scope creep.

**In scope (INB-01 + cross-cutting matrix):** the inbound render `else` branch of
`inbound_live.ex` (~382-533), the filters card + "Open record" CTA + health-strip gating, the
`orientation_strip surface={:inbound}` placement, the master-detail empty/populated states, the
`records_list` `data_state`/`empty_state` wiring, the `evidence_card` reveal affordance, the
`replay_modal` (both surfaces) a11y, and the paired Playwright/ExUnit gate updates + persona
re-shoot. Full matrix applies: 320→wide responsive (table≥768 / cards<768, graceful long
IDs/UUIDs/module-names/non-ASCII/high-counts/nulls), light/dark/system,
happy/empty/loading/error/permission-denied/boundary/disconnected-reconnect, WCAG 2.2 AA + APG,
Emil-Kowalski-grade transform/opacity motion within the v1.13 MOTION locks, on-brand
recovery-oriented microcopy.

**Out of scope (later phases / locked):** Preview surface (Phase 122). Cross-surface coherence +
arming the new Inbound judgment gate into the permanent ratchet floor + the pillar re-score
(Phase 123 — this phase ADDS the gate and HOLDS the floor green only-forward; it does not
re-score). No new product capability, providers, transports, or routes (D-23). No new reveal
*trigger*, no "copy raw" action, no per-field reveal (whole-payload only — storage shape is a
`redact: true` blob). **Durable persisted reveal-audit is OUT** (a telemetry count ships; a
persisted audit row touching the storage/retention contract is deferred). Background-content
`inert`/`aria-hidden` full-APG modality and the replay `btn-error`-vs-consequential-color question
are deferred design-system items (Phase 123 or later). Recipient-facing email HEEx + `brandbook/`
tokens are OUT. Zero-Node *shipped* asset pipeline preserved. No new orientation/motion copy or
keyframes (119 D-10/D-11 / v1.13 MOTION locks).
</domain>

<decisions>
## Implementation Decisions

### Empty-state IA — mirror 120's no-data / no-match / populated split onto Inbound (port of 120 D-01..D-08)
- **D-01:** Wrap the inbound render `else` branch (`inbound_live.ex:382-533`, inside the
  `@tenant_state in [:select_required, :none]` else) in a top-level `cond`, mirroring the shipped
  Deliveries shape (`operator_live.ex:489-522`). Drive it off the **existing** discriminator — do
  NOT invent a flag. Genuine **no-data** = `@records == [] and not filters_active?(@filter_params)
  and @filter_errors == %{}` (the `empty_state_for/2` `:truly_empty` case, `inbound_live.ex:659-670`);
  **no-match** = `filters_active?` true OR `tenant_has_inbound_history?` (`:filtered`); otherwise
  **populated**. Keep the `@filter_errors == %{}` guard so an in-flight invalid filter is not
  misclassified as no-data (the 120 trap at `operator_live.ex:490`).
- **D-02:** In genuine **no-data**, render a **single calm pane** (`RecordsList.records_list
  records={[]} empty_state={:truly_empty}`) **+ the empty-pane-only `orientation_strip
  surface={:inbound}`**, and **withhold** the filters card ("Open record" submit `:412`), the
  **health strip** (`Overview.overview`, `:421-426`), and the entire master-detail grid (incl. the
  "Select an InboundMessage…" helper and the replay-modal seam). Filters/CTA can only act on an
  empty set; a wall of zero stat-cards over an empty surface is the canonical info-dump the
  STRESS-TEST-PROMPT bans.
- **D-03:** In **no-match** and **populated**, keep the filters toolbar (so the **"Clear filters"**
  escape `:413` / `inbound-empty-reset` survives), the health strip, and the master-detail grid.
- **D-04:** Apply 120 **D-05** to Inbound: **remove `orientation_strip surface={:inbound}` from the
  detail-column `is_nil(@detail)` branch** (`inbound_live.ex:483`), where it currently fires on
  every populated-but-unselected view below a populated table — the same redundant-orientation /
  label-tripling defect 120 fixed. **Keep the "Select an InboundMessage to inspect its Mailbox
  routing…" master-detail helper** (`:484-491`) — it is the correct column-fill affordance, not
  orientation. Strip becomes empty-pane-only, identical to Deliveries.
- **D-05:** **Preserve the tenant-scope boundary** (mirror of 120 D-04): withholding the filters
  card in genuine no-data removes the only scope-widening vector; `FiltersForm.fields` exposes only
  outcome/window, never a tenant-widening control; `:no_tenant` is handled entirely upstream by the
  `tenant_selector` (`:376-381`). Any fix that lets the empty/no-data state widen tenant scope is a
  regression.
- **D-06:** **Detail-column forensic density is legitimate, not info-dump.** Once a record is
  selected, DetailHeader → Timeline → RoutingTrace (`:no_match` only) → EvidenceCard → replay render
  at full density — this is selection-gated, progressively-disclosed forensic detail (the inbound
  JTBD: "why did this InboundMessage route the way it did?"), and the streamlined gate governs only
  the empty/no-data state. Keep RoutingTrace gated to `:no_match` so it is signal, not noise.

### Microcopy — one drift fix; everything else byte-frozen
- **D-07:** Fix the one noun drift: `records_list.ex:365` `"No records have been recorded yet."` →
  **"No InboundMessages have been recorded yet."** (brandbook noun discipline — `brandbook/copy/
  microcopy.md:48`, `brand-book.md:71` lock **InboundMessage**; the card header already says "Recent
  InboundMessages"). No-match copy `"No records match the current filters."` + the reset link stay.
- **D-08:** **Orientation strip copy stays byte-frozen** (`shell.ex:416-425`, 119 D-10 / 120 D-07) —
  only its render *condition* changes. "Oops" stays banned (none present).

### Cross-cutting matrix via existing capabilities + wire the dormant data_state (port of 120 D-09)
- **D-09:** **Wire the dormant `data_state` (latent bug-fix).** `RecordsList` supports
  `data_state` (`records_list.ex:43-73`: error/permission_denied/stale/empty) but `inbound_live.ex`
  **never passes it** — the four states are dead code on this surface. Pass it (mirror 120 D-09) so
  error / permission-denied / stale / disconnected route through the existing primitive + the
  existing `inbound-detail-error` branch (`:470-481`). Responsive table+card duality, `mask_recipient`,
  `format_datetime(nil) → "Pending"`, truncate+title are already in `records_list.ex` — **verify
  against the matrix, do not rebuild.** Note: `tenant_has_inbound_history?` (`:687-702`) runs an
  extra full-window list query only when `@records == []` — acceptable; ensure the no-data port does
  not trigger it on populated views.

### PII / raw-payload reveal — preserve invariants + bounded a11y polish + PII-free audit
- **D-10:** **Preserve every reveal invariant (hard guardrail):** `reveal_state` defaults
  `:redacted` and re-sets to `:redacted` on every selection and clear (`inbound_live.ex:100/565/584`)
  — non-sticky across views; whole-payload only; capability-gated via the existing
  `authorize_reveal/1` over `Auth.authorize(adapter, :reveal_raw, …)` (`:944-951`), fail-closed on
  nil/non-atom adapter; no new auth surface, no new reveal trigger, no default-on. The IA refactor
  must not hoist evidence rendering outside the per-selection reset. The locked boundary test
  (`structural.spec.js:1176-1177`: `inbound-evidence-redacted` visible + `inbound-evidence-raw`
  count 0 on first selection) must **not** be weakened.
- **D-11:** **Bounded reveal-UX a11y polish (within the locked `:reveal_raw` contract):** make the
  reveal control a true ARIA **disclosure button** — `aria-expanded` false→true on grant,
  `aria-controls="inbound-evidence-raw"`, `mg-focus-ring`, `min-h-11` (44px); announce the state
  change via an `aria-live="polite"` `role="status"` region (never the warning border color alone —
  WCAG 1.4.1). Add a **"Re-redact raw source"** collapse control in the `:revealed` state routing
  back to `:redacted` (one new `handle_event`, **no fourth state atom**), returning focus to the
  reveal button. Reveal button copy: **"Reveal raw source"** + secondary **"Contains unredacted
  PII."** Keep the exemplary denied copy verbatim.
- **D-12:** **PII-free reveal audit (telemetry, not storage).** Emit `[:mailglass_admin, :inbound,
  :reveal_raw, :stop]` with metadata `tenant_id` / `record_id` / `:outcome ∈ :granted | :denied`
  ONLY — never payload/body/headers/recipient (CLAUDE.md telemetry PII rule). Makes reveals
  observable via telemetry handlers without touching the storage/retention contract. **Durable
  persisted reveal-audit is deferred** (would add a new persisted record touching
  `api_stability.md` — its own trust-posture decision).

### Replay (consequential action) — keep modal weight + close two APG gaps on BOTH surfaces
- **D-13:** **Keep the full-modal confirmation weight — do NOT downgrade** to inline-confirm,
  single-click+undo, or type-to-confirm. Replay is consequential-but-non-destructive (it appends an
  immutable replay run to the append-only ledger; "Undo" would be a lie). The modal that names the
  recipient + states the ledger consequence delivers the "boring instead of terrifying" calm
  (`guides/jobs.md:190`). Preserve the gate order **TENANT → CAPABILITY (`:replay_inbound`) →
  REPLAY** (`inbound_live.ex:274-322`), the `:no_match`-can-never-replay rule, and the struct-matched
  error copy (CLAUDE.md rule 7) — all unchanged.
- **D-14:** **Close two genuine APG gaps, applied identically to BOTH replay modals** (Inbound
  `inbound/replay_modal.ex` + Deliveries `operator/replay_modal.ex`) for cross-surface coherence:
  (1) **Tab/Shift+Tab focus-trap** (wrap last→first / first→last) via LiveView.JS focus sentinels or
  a scoped Tab keydown handler — the one APG line item currently unmet (`JS.focus_first` sets initial
  focus but does not contain Tab); (2) **double-submit pending-lock** on Confirm (`phx-disable-with`
  / `JS.set_attribute(disabled)` + a calm pending label **"Replaying…"**) — prevents the render→click
  double-fire the code already worries about. Everything else the modal already does right
  (`role="dialog"`, `aria-modal`, `aria-labelledby`, Escape via `phx-key`, initial focus,
  focus-restore to trigger, scrim/overscroll, reduced-motion neutralizer) is **already APG-conformant
  and e2e-asserted — do not regress.** Background-content `inert` and the `btn-error`-color question
  are **deferred** (Phase 123+).

### Paired-test updates + new judgment gate + persona re-shoot (port of 120 D-10) + asset landmine (120 D-13)
- **D-15:** **Mandatory same-phase paired-test updates (the green-only-forward / Pitfall-2 trap):**
  `operator.spec.js:462-476` ("inbound and preview surfaces render their orientation strips") asserts
  `inbound-orientation` **visible on a populated** `/ops/mail/inbound?tenant_id=…` view (`:468`) — it
  goes RED the instant the strip is empty-pane-only. **Split it** (keep the preview assertion; replace
  the inbound assertion). Scan `structural.spec.js` inbound block (~1103-1264) + any inbound ExUnit
  for `inbound-orientation`-on-populated or health-strip-over-empty assumptions and update them.
- **D-16:** **Add an Inbound empty-pane-only judgment gate** (in the `operator.spec.js` judgment
  describe block, mirroring the Deliveries gate `operator.spec.js:402-456`), asserting by
  `data-testid` count/presence (never pixel/CSS-visibility): POPULATED → `inbound-orientation` count
  0, `inbound-filters` visible; NO-DATA → `inbound-empty-truly` count 1, `inbound-orientation` count
  1, `inbound-filters` count 0 (the security-boundary assertion), `inbound-master-detail` count 0;
  NO-MATCH → `inbound-filters` visible, `inbound-orientation` count 0. Add e2e assertions for the two
  new replay-modal behaviors (Tab wraps last→first; Confirm disabled after first click) on both
  surfaces, and for the reveal disclosure `aria-expanded` + re-redact collapse.
- **D-17:** **Persona re-shoot — no new cells.** `persona-screenshots.spec.js` already enumerates
  `operator-inbound` cells (`:69`, `:120-122`) × {northstar, fjordline-aps, helios-void} ×
  {375,1440} × {light,dark}. Re-run the producer in one pass: `helios-void` (zero-data) now proves
  the calm no-data pane, `northstar` proves error/high-count, `fjordline-aps` proves
  long-ID/non-ASCII/null. That delta IS the only-forward evidence.
- **D-18:** **Asset / TokenParity landmine (120 D-13):** the port is mostly **render-condition**
  changes (which `cond` branch fires) reusing classes already in the committed bundle (Deliveries
  uses them) — those need NO `mix assets.build`. Only if a genuinely new utility appears: rebuild,
  but **commit only a bundle that survives TokenParityTest** (a fresh build emits raw-inline daisyUI
  5.5.19 theme blocks that BREAK the gate; the committed bundle is canonical). Motion stays on
  existing tokens (`motion-reveal`, no new keyframes — 120 D-11). Hold the v1.13 ratchet floor +
  D-THEME-PARITY (light/dark/system) green **only-forward** — no pillar re-score (Phase 123).

### Claude's Discretion
- Exact focus-trap implementation (LiveView.JS focus-sentinel spans vs. a scoped Tab keydown
  handler) — pick the least-surprise, smallest-correct-JS option; both are pure Phoenix/LiveView.JS,
  no new npm deps. Keep both surfaces' modals in lockstep.
- Exact onboarding-pane layout/spacing in genuine no-data (single calm pane vs. a brief
  "point your inbound webhook here" next-step hint delivered via the existing brandbook empty-state
  microcopy, not new structure) — default to least-surprise / structural parity with Deliveries.
- Precise placement of the `aria-live` status region + re-redact button within `evidence_card.ex` —
  planner's call; reuse existing primitives.

### Folded Todos
None — no pending todos matched Phase 121.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/phases/120-deliveries-surface-redesign/120-CONTEXT.md` — the locked pattern being
  ported (D-01..D-13: no-data/no-match split, empty-pane-only orientation, data_state routing,
  paired-test trap, motion locks, asset/TokenParity landmine). Do not re-decide these.
- `mailglass_admin/lib/mailglass_admin/operator_live.ex:489-579` — **the shipped Phase 120
  Deliveries shape to mirror** (the no-data calm pane `490-509`, populated branch `510-579`); also
  the Deliveries replay/confirm analogue for cross-surface modal parity.
- `mailglass_admin/lib/mailglass_admin/inbound_live.ex` — the surface. `render/1` `345-536`; the
  `else` branch `382-533` to wrap in a `cond`; FILTERS card `383-419` ("Open record" submit `:412`,
  "Clear filters" `:413`); health strip `421-426`; master-detail `428-524`; orientation strip at the
  **redundant** `is_nil(@detail)` placement `483` (the relocate/remove target) + "Select an
  InboundMessage…" helper `484-491`; reveal handler `258-260` + reset `100`/`565`/`584` +
  `authorize_reveal/1` `944-951`; replay open/close `246-251`, confirm gate `274-322`, focus-mgmt
  span + modal `527-532`, `replay_error_copy` `645+`; `empty_state_for/2` `659-670`; `filters_active?/1`
  `672-685`; `tenant_has_inbound_history?` `687-702`.
- `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex` — already distinguishes
  no-data/no-match (`74-102`: `inbound-empty-truly` / `inbound-empty-filtered` + reset), **supports
  `data_state` (`43-73`) that is currently UNWIRED**, table+card duality, null/long-value/mask
  handling; copy fix at `:365` (D-07).
- `mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex` — the redacted/revealed/denied
  reveal UI to harden (D-11); read before touching the detail subtree.
- `mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex` +
  `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex` — keep the two modals in lockstep
  (D-14 focus-trap + double-submit on both).
- `mailglass_admin/lib/mailglass_admin/inbound/overview.ex` — the health strip to withhold in
  no-data (D-02).
- `mailglass_admin/lib/mailglass_admin/operator/shell.ex:374-425` — `orientation_strip/1`
  (byte-frozen `:inbound` copy `416-425`); only the render condition changes (D-08).
- `mailglass_admin/e2e/operator.spec.js:462-476` — **the mandatory paired-test update** (asserts
  `inbound-orientation` visible on populated); model the new judgment gate on the Deliveries gate
  `402-456`.
- `mailglass_admin/e2e/structural.spec.js` — `~1103-1264` inbound block (verify still green;
  `1176-1177` is the locked redacted-by-default boundary — do not weaken); `flows.spec.js` inbound
  replay-modal parity (~396).
- `reference/demo_app/assets/e2e/persona-screenshots.spec.js:69,120-122` — re-run the
  `operator-inbound` cells for only-forward proof (no new cells, D-17).
- `.planning/research/v1.14/DEFECT-REGISTER.md` (Inbound row `288`: "no net-new headline defect —
  121 applies 120's cleanup"; consumption guide `305`) + `.planning/research/v1.14/
  STRESS-TEST-PROMPT.md` (the binding Apple-deliberate-IA judgment rubric — do not dilute).
- `brandbook/brand-book.md` + `brandbook/copy/microcopy.md` (CURRENT brandbook; noun discipline,
  thoughtful-maintainer voice, "Oops" banned) + `mailglass_inbound/docs/api_stability.md` (telemetry
  PII rule, storage boundary — for D-12).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Inbound is a deliberate clone of Deliveries** (`InboundLive` docstring calls itself a "clone,
  not a refactor" of `OperatorLive`) — structural parity is a maintained contract. The
  no-data/no-match distinction (`empty_state_for/2` → `:no_tenant`/`:truly_empty`/`:filtered`,
  `inbound_live.ex:659-670`) and `filters_active?/1` (`:672`) already exist; Phase 121 *gates on*
  this truth rather than inventing a flag.
- **`data_state` is built but UNWIRED** (`records_list.ex:43-73`) — error/permission_denied/stale
  are dead code until `inbound_live.ex` passes the attr. Biggest latent gap; D-09 fixes it.
- **Responsive / long-value / null / mask / pagination** already in `records_list.ex` — verify,
  don't rebuild.
- **Replay modal is already APG-strong** (`role="dialog"`, `aria-modal`, `aria-labelledby`, Escape,
  initial focus, focus-restore, scrim, reduced-motion) and e2e-asserted — only the Tab focus-trap +
  double-submit guard are missing (D-14).
- **Reveal three-state machine** (`:redacted`/`:revealed`/`:denied`, non-sticky reset) is correct;
  it just lacks disclosure a11y semantics + a re-redact path (D-11).

### Established Patterns
- The byte-frozen `orientation_strip` changes render *condition*, never copy (119 D-10 / 120 D-07).
- Empty states withhold controls that can't act on an empty set (filters/CTA/health in no-data) —
  GOV.UK / Polaris / Stripe / Sentry pattern; a zero-stat-card wall is the info-dump to avoid.
- `RecordsList` ≡ `DeliveriesList`: coherence = wire the same tested primitive identically, not
  re-author per surface ("one component, many surfaces").
- Committed `priv/static/app.css` is canonical; a fresh `mix assets.build` regenerates raw-inline
  daisyUI theme blocks that trip TokenParityTest — only commit a rebuild that survives the gate.
- Paired-test trap (Pitfall-2 / 120 D-10): relocating an always-visible block on a green-only-forward
  floor REQUIRES updating the specs that assert it, in the same phase.

### Integration Points
- `inbound_live.ex` render branch → `records_list.ex` (`data_state` + `empty_state` +
  `filters_active?`) — the empty-state gating + dead-code-wiring seam.
- `inbound_live.ex` → `shell.ex` (`orientation_strip`) — the empty-pane-only relocation seam.
- `inbound_live.ex` / `evidence_card.ex` — reveal disclosure a11y + re-redact + PII-free telemetry.
- `inbound/replay_modal.ex` + `operator/replay_modal.ex` — paired focus-trap + double-submit (both
  surfaces).
- redesign → `operator.spec.js` / `structural.spec.js` / `flows.spec.js` (paired updates + new
  judgment gate) + `persona-screenshots.spec.js` (re-shoot inbound cells for only-forward proof).
</code_context>

<specifics>
## Specific Ideas

- Microcopy: reveal button **"Reveal raw source"** + **"Contains unredacted PII."**; re-redact
  **"Re-redact raw source"**; live-region **"Raw source revealed. This payload contains unredacted
  PII."** / **"Raw source re-redacted."**; replay Confirm pending **"Replaying…"**. All grounded in
  the current brandbook voice; existing denied/error/success copy kept verbatim.
- No-data body may adopt the brandbook InboundMessage empty-state next-step line ("point your
  provider's inbound webhook here") via existing microcopy, delivered as copy not new structure.
</specifics>

<deferred>
## Deferred Ideas

- **Durable persisted reveal-audit** (queryable access-log row per reveal) — touches the inbound
  storage/retention + `api_stability.md` trust contract; its own decision/phase. Telemetry count
  ships now (D-12).
- **Background-content `inert` / `aria-hidden`** for full-APG-strict modality — larger cross-shell
  change; Phase 123+ follow-up (scrim + overscroll passes today's invariants).
- **Replay Confirm `btn-error` red vs. a "consequential" (non-destructive) treatment** across both
  surfaces — a cross-surface design-system question, not Inbound-specific; Phase 123.
- **Per-field reveal** / **"copy raw" action** — out of scope (storage is a whole-payload blob; copy
  would be a new capability decision).
- Arming the new Inbound empty-pane judgment gate into the permanent ratchet floor + the
  cross-surface pillar re-score — Phase 123.
- Preview surface (Phase 122) inherits 121's cleaned-up patterns — out of scope here.

### Reviewed Todos (not folded)
None — no pending todos matched Phase 121.
</deferred>
