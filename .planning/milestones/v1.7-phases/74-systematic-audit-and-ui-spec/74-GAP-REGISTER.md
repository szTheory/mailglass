---
phase: 74
slug: systematic-audit-and-ui-spec
artifact: gap-register
stable_ids: true
created: 2026-06-04
---

# Phase 74 — Gap Register (AUDIT-01)

> Scored gap register covering surface × theme (light/dark) × viewport (390/768/1440) × state.
> Stable `GAP-NN` row IDs are the anti-churn citation gate for Phases 75-78.
> **Zero production code was changed to produce this register. All cited files are read-only.**

---

## Anti-Churn Contract

Every build task in Phases 75-78 MUST cite a row from this register at **severity ≥ 3**. No
citation → no merge. This is the mechanical enforcement of the D-02 stable-ID rule: rows are
never renumbered once written.

---

## Row Schema

| Column | Description |
|--------|-------------|
| `GAP-NN` | Stable ID — never renumber once assigned |
| `surface` | Deliveries / Inbound / Preview / Operator Overview / All |
| `component:line` | Path relative to `mailglass_admin/lib/` (or `docs/`) and line number |
| `pillar` | One of the six conformance pillars below |
| `sev` | 1-5 per severity rubric below |
| `evidence PNG` | `tmp/ui-audit/{surface}-{viewport}-{theme}.png` (gitignored, never committed — D-06) |
| `fix sketch` | Concise implementation direction referencing the frozen UI-SPEC taxonomy |

---

## Six Conformance Pillars (design-system.md:104-121)

| # | Pillar | What it covers |
|---|--------|---------------|
| 1 | **Spacing/size** | Token utilities on the 4px grid; touch targets ≥ `min-h-11` (44px) |
| 2 | **Radius** | `rounded-box` / `rounded-field` only (theme-driven) |
| 3 | **Color** | Semantic tokens + opacity tints; no hex, no raw palette; accent ≤ 10% rule |
| 4 | **Type** | `text-label/body/heading/display`; weight `font-bold` or default only (no faux-bold) |
| 5 | **Elevation/stacking** | `border border-base-300`; `shadow-overlay` for modals only; z-index from named tiers |
| 6 | **Motion + A11y** | Named motion vocabulary; `prefers-reduced-motion` inherited; semantic roles; visible focus rings |

---

## Severity Rubric (anchored to Phase 79 closeout)

| Sev | Meaning | Phase 79 effect |
|-----|---------|----------------|
| 5 | Blocks correct usage or accessibility | **Blocks Phase 79 closeout** |
| 4 | Visible quality regression | **Blocks Phase 79 closeout** |
| 3 | Meaningful inconsistency — minimum severity required to cite in a build-phase task | Does not block closeout on its own |
| 2 | Minor drift — tracked but does not block closeout | Informational |
| 1 | Cosmetic — noted only | Informational |

Phase 79 success criterion: **zero open severity-4/5 rows**. Every sev-4/5 row must be either
fixed or explicitly downgraded with rationale before closeout.

---

## Evidence PNG Path Convention

PNG paths use the deterministic filename set produced by `mailglass_admin/scripts/ui-audit.sh`:

```
tmp/ui-audit/{surface}-{viewport}-{theme}.png
```

Where `{surface}` ∈ `deliveries | inbound | preview`, `{viewport}` ∈ `390 | 768 | 1440`,
`{theme}` ∈ `light | dark`.

Full 18-cell matrix:
- `deliveries-390-light.png` / `deliveries-390-dark.png`
- `deliveries-768-light.png` / `deliveries-768-dark.png`
- `deliveries-1440-light.png` / `deliveries-1440-dark.png`
- `inbound-390-light.png` / `inbound-390-dark.png`
- `inbound-768-light.png` / `inbound-768-dark.png`
- `inbound-1440-light.png` / `inbound-1440-dark.png`
- `preview-390-light.png` / `preview-390-dark.png`
- `preview-768-light.png` / `preview-768-dark.png`
- `preview-1440-light.png` / `preview-1440-dark.png`

Binaries are **never committed** (D-06). Path references are the durable artifact.

---

## IMPORTANT: Five badge_class/1 Call Sites

`grep -rln badge_class mailglass_admin/lib` returns **FIVE** files — not the three named in
CONTEXT D-12. The two `detail_header.ex` copies are LATENT: they replicate divergent behavior
that must be deleted in Phase 76 alongside the three named copies. Silently missing either
latent copy during consolidation would leave a divergent `badge_class/1` live in production
(Pitfall 5 silent-color-change failure mode).

| # | File | Lines | Named in D-12? |
|---|------|-------|----------------|
| 1 | `operator/deliveries_list.ex` | 80-84 | Yes |
| 2 | `operator/timeline.ex` | 130-135 | Yes |
| 3 | `inbound/records_list.ex` | 97-101 | Yes |
| 4 | `operator/detail_header.ex` | 81-85 | **No — LATENT** |
| 5 | `inbound/detail_header.ex` | 142-146 | **No — LATENT** |

---

## Gap Register

### BADGE-CONSOLIDATION Rows (Pillar 3 — Color; Phase 76 DS-01 targets)

| GAP-NN | surface | component:line | pillar | sev | evidence PNG | fix sketch |
|--------|---------|---------------|--------|-----|-------------|-----------|
| GAP-01 | Deliveries | `operator/deliveries_list.ex:83` | Color (3) | 4 | `tmp/ui-audit/deliveries-1440-light.png` | Phantom `:suppressed` → `badge-warning` has no canonical row in the Anymail taxonomy. Route through `Components.status_badge/1`; eliminate atom per UI-SPEC Conflict 1. Canonical replacement: `:unsubscribed` → `badge-warning`. Delete this `badge_class/1` private function entirely in Phase 76. |
| GAP-02 | Deliveries | `operator/deliveries_list.ex:80` | Color (3) | 3 | `tmp/ui-audit/deliveries-1440-light.png` | `:dispatched` grouped with `:delivered`/`:sent` under `badge-success` — semantically wrong (dispatched = in-flight, not terminal success). UI-SPEC Conflict 5 resolution: `:dispatched` → `"badge-primary"`. Route through unified `status_badge/1`. |
| GAP-03 | Deliveries | `operator/timeline.ex:130-135` | Color (3) | 4 | `tmp/ui-audit/deliveries-1440-light.png` | Full `"badge badge-outline badge-error"` string returned including base `badge` class (structural divergence from other two copies). All three replay event types (requested/succeeded/failed) collapse to `badge-error` — semantically incorrect; `:webhook_replay_succeeded` should be success. UI-SPEC Conflicts 3+4. Route through unified `status_badge/1`; delete this `badge_class/1`. |
| GAP-04 | Inbound | `inbound/records_list.ex:97-99` | Color (3) | 3 | `tmp/ui-audit/inbound-1440-light.png` | Singular inbound atoms `:accept`/`:reject`/`:bounce` (present tense) vs. canonical Anymail past-tense `:accepted`/`:rejected`/`:bounced`. UI-SPEC Conflict 2 resolution: normalize via `record_outcome/1` adapter before calling `status_badge/1`. Delete this `badge_class/1`. |
| GAP-05 | Deliveries | `operator/detail_header.ex:81-85` | Color (3) | 4 | `tmp/ui-audit/deliveries-1440-light.png` | **LATENT duplicate** — replicates `deliveries_list.ex:80-84` verbatim, including the phantom `:suppressed` at line 84. NOT enumerated in CONTEXT D-12. If Phase 76 deletes only the three named copies and misses this file, suppression status rendering silently diverges in the delivery detail header while the list view is fixed. This is the Pitfall-5 latent failure mode. Must be deleted in Phase 76 alongside GAP-01/GAP-02. |
| GAP-06 | Inbound | `inbound/detail_header.ex:142-146` | Color (3) | 4 | `tmp/ui-audit/inbound-1440-light.png` | **LATENT duplicate** — replicates `inbound/records_list.ex:97-101` verbatim, including singular `:accept`/`:reject`/`:bounce` atoms (lines 142-144). NOT enumerated in CONTEXT D-12. Phase 76 consolidation must delete this copy; the inbound detail header must call `status_badge/1` with normalized past-tense atoms identical to the list view. Same Pitfall-5 latent failure mode as GAP-05. |

---

### 390px MOBILE Rows (Pitfall 15 — explicit 390px pass, AUDIT-01 mandatory)

#### Deliveries Surface — 390px

| GAP-NN | surface | component:line | pillar | sev | evidence PNG | fix sketch |
|--------|---------|---------------|--------|-----|-------------|-----------|
| GAP-07 | Deliveries | `operator/operator_live.ex` (master-detail grid) | Spacing/size (1) | 3 | `tmp/ui-audit/deliveries-390-light.png` | At 390px, the `lg:grid-cols-[minmax(22rem,28rem)_1fr]` master-detail collapses to single column. Verify: list-only visible, no detail pane overlap. Orientation strip must remain readable at 390px. Touch targets on list rows must be `min-h-11` (44px). Phase 75 acceptance criterion: 390px screenshot review required before IA merge. |
| GAP-08 | Deliveries | `operator/operator_live.ex` (filter bar) | Spacing/size (1) | 3 | `tmp/ui-audit/deliveries-390-dark.png` | Filter bar at 390px: inputs and controls must stack or scroll without horizontal overflow. Raw `gap-3`/`gap-4`/`gap-6` utilities produce off-grid spacing; migrate to `gap-sm`/`gap-md`/`gap-lg` tokens. Phase 76 token migration target. |

#### Inbound Surface — 390px

| GAP-NN | surface | component:line | pillar | sev | evidence PNG | fix sketch |
|--------|---------|---------------|--------|-----|-------------|-----------|
| GAP-09 | Inbound | `inbound/inbound_live.ex` (master-detail grid) | Spacing/size (1) | 3 | `tmp/ui-audit/inbound-390-light.png` | Inbound master-detail collapses to single-column list at 390px — same breakpoint pattern as Deliveries. Orientation strip in empty-detail position must be readable. No horizontal overflow. Touch targets `min-h-11`. Phase 75 acceptance criterion: explicit 390px screenshot before IA merge. |
| GAP-10 | Inbound | `inbound/records_list.ex` (outcome badge in list row) | Spacing/size (1) | 3 | `tmp/ui-audit/inbound-390-dark.png` | Outcome badge inside a compressed 390px row: badge must not overflow or be clipped. After Phase 76 consolidation to `status_badge/1`, confirm badge renders correctly at 390px and legible in both light and dark theme. |

#### Preview Surface — 390px

| GAP-NN | surface | component:line | pillar | sev | evidence PNG | fix sketch |
|--------|---------|---------------|--------|-----|-------------|-----------|
| GAP-11 | Preview | `preview/preview_live.ex` (tab navigation) | Spacing/size (1) | 3 | `tmp/ui-audit/preview-390-light.png` | At 390px, the preview tab strip (`motion-tab-swap` keyed container) must be horizontally scrollable or stack. Tab touch targets `min-h-11`. Mailable selector sidebar at narrow width: verify no overflow. Phase 75 acceptance criterion: 390px review required. |
| GAP-12 | Preview | `preview/preview_live.ex` (zero-mailables empty state) | Spacing/size (1) | 2 | `tmp/ui-audit/preview-390-dark.png` | The zero-mailables empty state at `preview_live.ex:291` (testid `preview-empty-mailables`) must be centered and legible at 390px. Minor drift item — CTA button touch target should be `min-h-11`. Confirm during Phase 75 orientation-strip work. |

---

### SUPPORT-CARD / HIERARCHY Rows (Pillar 1 + 5; Phase 76 DS-03 target)

| GAP-NN | surface | component:line | pillar | sev | evidence PNG | fix sketch |
|--------|---------|---------------|--------|-----|-------------|-----------|
| GAP-13 | Operator Overview | `operator/support_cards.ex` (2×2 flat grid) | Elevation/stacking (5) | 4 | `tmp/ui-audit/deliveries-1440-light.png` | Flat `xl:grid-cols-2` 2×2 grid; all four cards have identical visual weight regardless of count. Zero triage signal. Target structure per UI-SPEC: Tier 1 (non-zero/actionable counts) as full `card bg-base-200` containers; Tier 2 (zero-state) as a compact `border-t border-base-300` horizontal row with `text-secondary text-label`. Restructure layout FIRST, then token-migrate (Pitfall 4 — never reverse the order). |
| GAP-14 | Operator Overview | `operator/support_cards.ex` (count number styling) | Type (4) | 3 | `tmp/ui-audit/deliveries-1440-light.png` | Count numbers rendered with raw Tailwind scale utilities instead of `text-display font-bold`. Semantic color missing: failure count should be `text-error`, orphan count `text-warning`, all-clear `text-success`. Fix: after hierarchy restructure, apply `text-display font-bold` with correct semantic color per UI-SPEC Health Count Colors table. |
| GAP-15 | Operator Overview | `operator/support_cards.ex` (zero-state row) | Spacing/size (1) | 2 | `tmp/ui-audit/deliveries-768-light.png` | At 768px (below `xl:` breakpoint), the 2×2 grid stacks to single column — no triage signal at mid-viewport. After hierarchy redesign, Tier 2 compact row must remain a single horizontal strip at all viewports. Minor drift until structure is addressed in Phase 76. |

---

### TYPE / TOKEN DRIFT Rows (Pillar 4 + 1; Phase 76 DS-02 targets)

| GAP-NN | surface | component:line | pillar | sev | evidence PNG | fix sketch |
|--------|---------|---------------|--------|-----|-------------|-----------|
| GAP-16 | All | `operator/operator_live.ex`, `inbound/inbound_live.ex`, `preview/preview_live.ex` (raw type utilities) | Type (4) | 3 | `tmp/ui-audit/deliveries-1440-light.png` | Raw Tailwind type utilities `text-sm`, `text-base`, `text-xs` present across HEEx. Must be migrated: `text-sm` → `text-body`, `text-base` → `text-body`, `text-xs` → `text-label`. Also: `font-medium` and `font-semibold` are faux-bold (500/600 not loaded); replace with `font-bold` or default. Phase 76 token-migration target. |
| GAP-17 | All | `operator/operator_live.ex`, `inbound/inbound_live.ex` (raw spacing utilities) | Spacing/size (1) | 3 | `tmp/ui-audit/deliveries-768-light.png` | Off-grid raw spacing utilities `gap-3` (12px), `gap-4` (16px raw), `gap-6` (24px raw) present. Must be replaced with tokens: `gap-sm`, `gap-md`, `gap-lg`. `gap-4` and `gap-md` are equivalent in value but raw utilities do not respond to theme-level token overrides. Phase 76 migration target per UI-SPEC Spacing Scale. |
| GAP-18 | Deliveries | `operator/deliveries_list.ex` (delivery ID / timestamp rendering) | Type (4) | 2 | `tmp/ui-audit/deliveries-1440-light.png` | Delivery IDs, event IDs, and timestamps should use `mono` class (IBM Plex Mono) per brand. Verify `mono` class applied to ledger-context values. Minor drift — does not block closeout but tracked for Phase 76 token pass. |

---

### MOTION + A11Y Rows (Pillar 6; Phase 77 MOTION-01 target)

| GAP-NN | surface | component:line | pillar | sev | evidence PNG | fix sketch |
|--------|---------|---------------|--------|-----|-------------|-----------|
| GAP-19 | Deliveries | `operator/operator_live.ex:332` (motion-reveal detail pane) | Motion + A11y (6) | 3 | `tmp/ui-audit/deliveries-1440-light.png` | `motion-reveal` div at `operator_live.ex:332` has no `id`. LiveView patches it in place on delivery selection change — animation does not re-fire (no insertion event). Bug: selecting a new delivery does not trigger the entrance reveal. Fix per UI-SPEC Motion section: add `id={"delivery-detail-#{@selected_delivery.id}"}`. LiveView replaces the element on record change, causing re-insertion and animation re-fire. Pattern reference: `preview/tabs.ex` id-keyed `motion-tab-swap`. This fix is Phase 77, not Phase 76. |
| GAP-20 | Deliveries | `operator/timeline.ex` (replay events motion) | Motion + A11y (6) | 2 | `tmp/ui-audit/deliveries-1440-dark.png` | `motion-timeline > *` stagger applied to timeline items. Verify stagger cap at 8 items respected (does not delay 50th event by 2 seconds). Also verify: animation does not re-fire on LiveView patches to the timeline after initial mount. Minor drift — reviewed in Phase 77. |
| GAP-21 | All | `operator/shell.ex`, `inbound/inbound_live.ex`, `preview/preview_live.ex` (a11y: aria-current) | Motion + A11y (6) | 3 | `tmp/ui-audit/deliveries-1440-light.png` | Active nav item must carry `aria-current="page"` (not color alone). Selected list row must carry `aria-selected="true"`. Modals must have `role="dialog"` and `aria-modal="true"`. Verify semantic heading hierarchy (h1 per page; h2 for sections). Missing attributes make keyboard and screen-reader navigation non-conformant. Phase 75/76 must add attributes when building the Operator Overview route and new component structure. |

---

### DEEP-LINK Deferral Row (D-11, Mandatory)

| GAP-NN | surface | component:line | pillar | sev | evidence PNG | fix sketch |
|--------|---------|---------------|--------|-----|-------------|-----------|
| GAP-22 | All | `docs/design-system.md:141-150` (asset-serving seam) | Elevation/stacking (5) | 3 | `tmp/ui-audit/deliveries-1440-light.png` (on hard refresh via direct deep URL, page loads unstyled — not capturable by normal audit flow) | The CSS/font URLs are relative; a hard refresh on a deep URL (e.g., `/ops/mail?tenant_id=foo&delivery_id=bar`) loads the page unstyled because the relative `css-<md5>` resolves against the deep path rather than the mount root. Stable in normal in-app navigation (live navigation keeps the stylesheet loaded). This is the asset-serving strategy, an explicitly stable seam. **Recommended disposition: Defer to Phase 79 (VERIF-04); formal in-scope/deferred decision owned by Phase 75 (IA-04).** Severity set to 3 (not 4/5) so it does not falsely block Phase 79 closeout before the Phase 75 decision is made. If Phase 75 decides to fix it, severity is upgraded; if deferred again, it must be explicitly documented with rationale before Phase 79 closeout (per Pitfall 16). |

---

## Summary by Phase Target

| Phase | Build Requirement | Citing Rows | Min Sev |
|-------|------------------|-------------|---------|
| 75 (IA + Navigation) | IA-01: Operator Overview route | GAP-13, GAP-19 | 3 |
| 75 (IA + Navigation) | IA-02: Orientation strip generalization | GAP-07, GAP-09, GAP-11 | 3 |
| 75 (IA + Navigation) | IA-03: 390px acceptance on all surfaces | GAP-07, GAP-09, GAP-11 | 3 |
| 75 (IA + Navigation) | IA-04: Deep-link decision (in/out scope) | GAP-22 | 3 |
| 76 (Component Hardening) | DS-01: Unified `status_badge/1` | GAP-01, GAP-02, GAP-03, GAP-04, GAP-05, GAP-06 | 3 |
| 76 (Component Hardening) | DS-02: Token migration (type + spacing) | GAP-16, GAP-17 | 3 |
| 76 (Component Hardening) | DS-03: Support-card hierarchy redesign | GAP-13, GAP-14 | 3 |
| 77 (Motion) | MOTION-01: Motion-reveal re-fire fix | GAP-19 | 3 |
| 77 (Motion) | MOTION-02: Motion vocabulary conformance | GAP-20, GAP-21 | 2 |
| 78 (Seed Data) | SEED-01: Every screen state reachable | GAP-13 (zero-state), GAP-16 (empty states) | 3 |
| 79 (Verification) | VERIF-04: Deep-link disposition | GAP-22 | 3 |

---

## Deferred Items (out of v1.7 scope)

Items discovered during audit that are out of milestone scope per D-23/D-24 (no new features,
quality investment only):

| Item | Reason deferred |
|------|----------------|
| CI-promoted visual regression / LLM-critique loop | VR-NEXT-01 — explicitly out of v1.7 scope; screenshot→LLM loop stays local/ad-hoc |
| `count_active_suppressions/1` core function | Code change → D-10; recorded absent; Phase 75 additive implementation target |

---

## Self-Verification

- All 5 `badge_class/1` call sites enumerated: GAP-01/GAP-02 (deliveries_list.ex), GAP-03 (timeline.ex), GAP-04 (records_list.ex), GAP-05 (operator/detail_header.ex — LATENT), GAP-06 (inbound/detail_header.ex — LATENT)
- Explicit 390px mobile rows per surface: Deliveries (GAP-07, GAP-08), Inbound (GAP-09, GAP-10), Preview (GAP-11, GAP-12)
- Deep-link row present with "Phase 79" deferral: GAP-22
- Every badge consolidation, 390px, support-card, token, and motion row is severity ≥ 3
- Every pillar is one of the six from design-system.md:104-121
- Zero production code changed in this plan
