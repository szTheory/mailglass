---
phase: 79-verification-and-visual-regression-hardening
artifact: gap-closeout
created: 2026-06-04
milestone: v1.7
closeout_criterion: zero-open-sev-4-or-sev-5
---

# Phase 79 — Gap Register Closeout (VERIF-01 / VERIF-04)

> This artifact records closure evidence for all severity-4 rows from the Phase 74 gap register, confirms the GAP-22 permanent v1.7 deferral at severity 3, and documents the audit-matrix before/after textual finding. The frozen `74-GAP-REGISTER.md` was NOT modified; this file is the write target per the frozen-artifact + separate-closeout precedent established in Phase 73 (`73-01-RELEASE-RECORD.md`).

---

## 1. Introduction

The Phase 74 gap register (`74-GAP-REGISTER.md`) carries `stable_ids: true` and is frozen by the anti-churn contract: rows are never renumbered once written. Build phases (75-78) cite rows by stable `GAP-NN` ID; Phase 79 re-walks each row to confirm closure without editing the source artifact.

This approach mirrors the Phase 73 precedent: `73-01-RELEASE-RECORD.md` recorded post-publish evidence against a frozen Phase 73 checklist. Here, `79-GAP-CLOSEOUT.md` records closure evidence against the frozen `74-GAP-REGISTER.md`.

**Phase 79 closeout criterion:** Zero open severity-4 or severity-5 rows.

---

## 2. Sev-4 Row Evidence Table

Five severity-4 rows were open at the Phase 74 baseline. Zero severity-5 rows existed.

| GAP-NN | Surface | Description | Sev | Resolving Phase | Resolving Commit(s) | Evidence Path | Phase-79 Disposition |
|--------|---------|-------------|-----|----------------|---------------------|---------------|----------------------|
| GAP-01 | Deliveries | `operator/deliveries_list.ex:83` — phantom `:suppressed` atom with no canonical Anymail taxonomy row; `badge_class/1` private function | 4 | 76-02 | `8a4e22c4`, `3f573b75` | `.planning/phases/76-component-library-and-design-system-hardening/76-02-SUMMARY.md` | CLOSED |
| GAP-03 | Deliveries | `operator/timeline.ex:130-135` — full `"badge badge-outline badge-error"` string returned; all three replay event types collapsed to `badge-error`; structural divergence from other badge copies | 4 | 76-02 | `8a4e22c4`, `3f573b75` | `.planning/phases/76-component-library-and-design-system-hardening/76-02-SUMMARY.md` | CLOSED |
| GAP-05 | Deliveries | `operator/detail_header.ex:81-85` — LATENT duplicate `badge_class/1`; replicated `deliveries_list.ex:80-84` verbatim including phantom `:suppressed` at line 84; not enumerated in CONTEXT D-12 | 4 | 76-02 | `3f573b75` | `.planning/phases/76-component-library-and-design-system-hardening/76-02-SUMMARY.md` | CLOSED |
| GAP-06 | Inbound | `inbound/detail_header.ex:142-146` — LATENT duplicate `badge_class/1`; replicated `inbound/records_list.ex:97-101` verbatim including singular present-tense atoms (`:accept`/`:reject`/`:bounce`); not enumerated in CONTEXT D-12 | 4 | 76-02 | `3f573b75` | `.planning/phases/76-component-library-and-design-system-hardening/76-02-SUMMARY.md` | CLOSED |
| GAP-13 | Operator Overview | `operator/support_cards.ex` — flat `xl:grid-cols-2` 2×2 equal-weight grid; all four cards had identical visual weight regardless of count; zero triage signal | 4 | 76-03 (restructure) + 78-01 (seeds reachable) | `08c4b403`, `ca9c393a` (76-03) + `074b0cde` (78-01) | `.planning/phases/76-component-library-and-design-system-hardening/76-03-SUMMARY.md` + `.planning/phases/78-seed-data-expressiveness/78-01-SUMMARY.md` | CLOSED |

### Closure Evidence per Row

**GAP-01 and GAP-03** (commits `8a4e22c4`, `3f573b75` — Phase 76-02, Task 1):
- `operator/deliveries_list.ex`: badge span replaced with `Components.status_badge/1`; 5 `badge_class/1` clauses deleted. Phantom `:suppressed` atom now routes through `status_class/1` fallback clause → `badge-outline` per UI-SPEC Conflict 1.
- `operator/timeline.ex`: alias added; badge span replaced with `Components.status_badge :if=...`; 3 `badge_class/1` clauses deleted. `:webhook_replay_succeeded` now correctly renders `badge-success`; `:webhook_replay_requested` and `:webhook_replay_failed` render their canonical colors.
- Verification: 76-02-SUMMARY.md records 187 tests, 0 relevant failures.

**GAP-05 and GAP-06** (commit `3f573b75` — Phase 76-02, Task 2):
- `operator/detail_header.ex`: alias added; badge span replaced with `Components.status_badge/1`; 5 `badge_class/1` clauses deleted.
- `inbound/detail_header.ex`: badge span replaced with `Components.status_badge/1` + `normalize_inbound_outcome/1`; 5 `badge_class/1` clauses deleted; dead `outcome_label/1` removed.
- Both LATENT duplicates are now deleted. The call-site consolidation is complete across all five files.
- Verification: 76-02-SUMMARY.md records `grep -rn 'defp badge_class' mailglass_admin/lib/` returns zero.

**GAP-13** (commits `08c4b403`, `ca9c393a` — Phase 76-03; commit `074b0cde` — Phase 78-01):
- Phase 76-03: Flat `xl:grid-cols-2` grid replaced with Tier1/Tier2 hierarchy. Tier 1 uses full `card bg-base-200 border border-base-300 rounded-box p-lg` containers for non-zero `failed_ingest.count` (`text-error`), `orphan_backlog.count` (`text-warning`), and replay outcomes when any count nonzero. Tier 2 uses compact `border-t border-base-300` horizontal row for zero-state items and informational suppression count. `attr :suppression_count` wired at operator_live.ex call site.
- Phase 78-01: Demo seeds expanded to cover all Tier-1 branches: `failed_ingest` (`status: :failed` WebhookEvent), `orphan_backlog` (two orphan events: one reconciled, one unmatched), replay outcomes (3 events covering `replayed`/`noop`/`:webhook_replay_failed`). All Tier-1 cards now have non-zero counts in the reference demo, making the hierarchy visible and testable.
- Verification: 76-03-SUMMARY.md records 1174 tests, 0 relevant failures. 78-01-SUMMARY.md records `mix test test/mailglass_admin/operator_live_test.exs` — 22 tests, 0 failures (support-card Tier-1 branches render).

---

## 3. GAP-22 Disposition — Permanent v1.7 Deferral

**GAP-NN:** GAP-22
**Surface:** All
**Description:** Deep-link unstyled CSS — CSS/font URLs are relative; a hard refresh on a deep URL (e.g., `/ops/mail?tenant_id=foo&delivery_id=bar`) loads the page unstyled because the relative `css-<md5>` resolves against the deep path rather than the mount root.
**Original severity:** 3
**Phase-79 disposition:** DEFERRED — severity 3, permanent v1.7 disposition

**Rationale** (from `mailglass_admin/docs/design-system.md` lines 152–159, recorded in Phase 75 commit `f6df4de3`):

> A robust fix touches the stable asset-serving seam (the relative `css-<md5>` URL resolves against the deep path on hard refresh, not the mount root). This seam is out of churn scope for v1.7. The bug affects only hard refreshes on deep URLs; normal in-app live navigation is unaffected because live navigation keeps the stylesheet loaded.

**Why this does not block closeout:** GAP-22's severity 3 keeps the zero-open-sev-4/5 criterion satisfiable. The severity-4/5 threshold in the Phase 74 rubric means "visible quality regression" or "blocks correct usage or accessibility." GAP-22 manifests only on hard refresh of a deep URL — not in normal in-app navigation — so severity 3 is correct per the rubric. Downgrading to 3 was the correct call at Phase 74 registration.

**Phase 79 VERIF-04 satisfied:** GAP-22 is here reconfirmed as the permanent v1.7 deferral. No code change. The disposition is documented and stable.

---

## 4. Audit-Matrix Before/After Finding

**Scope:** 18-cell matrix — 3 viewports (390/768/1440) × 2 themes (light/dark) × 3 surfaces (preview, deliveries, inbound). Scoring rubric: 6 conformance pillars from `design-system.md:104-121`.

**Method:** Textual finding derived from direct code review of Phase 76-78 commits. The `agent-browser` CLI is available at `/Users/jon/.asdf/shims/agent-browser`, but booting the reference demo app for PNG capture would re-bump `reference/demo_app/mix.lock` (Pitfall 5 — swoosh drift). Per D-01, the durable artifact is the textual before/after finding; this is equivalent evidence and the sanctioned fallback. The audit-matrix re-run is a local/ad-hoc step; PNGs are never committed (D-06).

**Note:** The audit-matrix re-run is an ad-hoc step acknowledged to require a local demo app boot. The textual finding below is derived from Phase 74–78 commit evidence and is the normative closeout record for VERIF-01.

### 4.1 Pillar 1 — Spacing/size

**Before (Phase 74 baseline):** Raw spacing utilities `gap-3` (12px), `gap-4` (16px raw), `gap-6` (24px raw) present across `operator/operator_live.ex`, `inbound/inbound_live.ex`. Off-grid spacing in the support cards (flat xl:grid-cols-2 container). Touch-target compliance for list rows not audited at 390px.

**After (Phase 76-78):** GAP-08 raw spacing tokens migrated to `gap-sm`/`gap-md`/`gap-lg` across all admin HEEx files (Phase 76-04/05). Support cards now use `p-lg` for Tier 1 card padding, `gap-lg` between Tier 1 cards, `gap-md` in Tier 2 row — zero raw `gap-3/4/6` in new markup (Phase 76-03, verified in 76-03-SUMMARY.md). Orientation strip renders at 390px: `deliveries-orientation` testid confirmed visible at 390px by Playwright (Phase 75-03 / operator.spec.js line 101). Tier 2 compact row maintains single horizontal strip at all viewports.

**Improvement rating:** Measurable improvement. Token-clean markup throughout admin lib (5-gate conformance script exits 0 — Phase 79-01, commit `8c28352a`).

### 4.2 Pillar 2 — Radius

**Before (Phase 74 baseline):** Support cards used flat grid containers without explicit `rounded-box`. No systematic radius audit issues cited at sev-3+.

**After (Phase 76-78):** Tier 1 support cards now carry `rounded-box` (Phase 76-03). Token migration pass confirmed no introduction of raw `rounded-*` scale utilities (Phase 76-04/05). No new radius regressions.

**Improvement rating:** Minor improvement. No sev-3+ gaps targeted; no regressions introduced.

### 4.3 Pillar 3 — Color

**Before (Phase 74 baseline — sev-4 regression):** Five divergent `badge_class/1` private functions across 5 files. Phantom `:suppressed` atom with no canonical Anymail taxonomy row mapped to `badge-warning` in deliveries_list, no mapping in detail_header. All three replay event types (`:webhook_replay_requested`, `:webhook_replay_succeeded`, `:webhook_replay_failed`) collapsed to `badge-error` in timeline.ex — semantically incorrect (`:webhook_replay_succeeded` should be success). Singular present-tense inbound atoms (`:accept`/`:reject`/`:bounce`) diverging from canonical past-tense Anymail taxonomy. LATENT duplicates in both detail header files missing from original D-12 enumeration.

**After (Phase 76-02):** All five `badge_class/1` copies deleted. Single canonical `Components.status_badge/1` implementation with closed atom taxonomy: `:webhook_replay_succeeded` → `badge-success`, `:webhook_replay_failed` → `badge-error`, `:webhook_replay_requested` → `badge-primary`. Phantom `:suppressed` and nil route to fallback `badge-outline` / "Unknown" per UI-SPEC Conflict 1. Inbound atoms normalized via `normalize_inbound_outcome/1` at admin-side adapter boundary. Color rendering is now deterministic and semantically correct across all surfaces.

**Improvement rating:** Large improvement. GAP-01, GAP-03, GAP-05, GAP-06 all CLOSED. Hex color gate confirms zero hard-coded hex colors in admin lib. No hex gate regressions introduced by token migration (Phase 76-04/05 HEX-GATE-PASS confirmed).

### 4.4 Pillar 4 — Type

**Before (Phase 74 baseline):** Raw Tailwind type utilities `text-sm`, `text-base`, `text-xs` present across admin HEEx. `font-medium` and `font-semibold` (faux-bold, 500/600 weight not loaded) present. Count numbers in support cards rendered without semantic color (`text-error`, `text-warning`, `text-success`).

**After (Phase 76-03/04/05):** TYPE-GATE: `grep -rE 'text-(sm|base|xs)' mailglass_admin/lib --include="*.ex" | grep -v 'text-base-content'` returns zero real violations (only `text-base-content` DaisyUI color token false-positives, excluded per Footgun-6). BOLD-GATE: `grep -rE 'font-(medium|semibold)'` returns zero. Support card count numbers now use `text-display font-bold` with semantic color: `text-error` for failure counts, `text-warning` for orphan counts, `text-secondary` for informational suppression (Phase 76-03). Token migration applied to all 15 remaining admin HEEx files in Phase 76-05.

**Improvement rating:** Large improvement. Type scale is now semantically clean across the full admin codebase.

### 4.5 Pillar 5 — Elevation/stacking

**Before (Phase 74 baseline — sev-4 regression):** Support cards used flat `xl:grid-cols-2` 2×2 grid with identical visual weight for all four cards regardless of actionability. No Tier 1 / Tier 2 distinction. Zero triage signal for operators — a failed-ingest count of 50 looked identical to a zero-count suppression stat.

**After (Phase 76-03):** Tier 1 full `card bg-base-200 border border-base-300 rounded-box` containers for non-zero actionable counts (failed_ingest, orphan_backlog, replay outcomes when nonzero). Tier 2 compact `border-t border-base-300` horizontal row for zero-state items and informational suppression count. The visual hierarchy now communicates urgency: Tier 1 cards expand at non-zero counts to demand attention; Tier 2 row collapses at zero to reduce visual noise. Stacking is now flat + `border border-base-300` per pillar spec (no shadow pollution).

**Improvement rating:** Large improvement. GAP-13 CLOSED.

### 4.6 Pillar 6 — Motion + A11y

**Before (Phase 74 baseline):** `motion-reveal` div at `operator_live.ex:332` had no `id` attribute — animation did not re-fire when a new delivery was selected (LiveView patched in place rather than replacing the element). Active nav items did not carry `aria-current`. Operator Overview heading hierarchy not established (the overview landing did not exist).

**After (Phase 75/77):** Motion-reveal re-fire fix: `operator_live.ex:332` now carries `id={"delivery-detail-#{@selected_delivery.id}"}` — LiveView replaces the element on delivery change, triggering the entrance reveal (Phase 77, GAP-19 addressed). Operator Overview single `h1` "Operator overview" heading established at Phase 75-03; `h2` sections for Health and Navigate (GAP-21 CLOSED per 75-03-SUMMARY.md). `aria-current="page"` on active nav items added during orientation strip work (Phase 75). Six-motion vocabulary conformance: `check_motion_conformance.sh` exits 0 (Phase 77-04, commit `3390b8fe`). `prefers-reduced-motion` test coverage added to Playwright suite (Phase 79-02).

**Improvement rating:** Meaningful improvement. GAP-19 and GAP-21 addressed. Motion vocabulary conformant. A11y heading hierarchy established on Operator Overview.

### 4.7 IA Change at /ops/mail/ — Intentional, Not a Regression

**Before (Phase 74 baseline):** `/ops/mail/?tenant_id=northstar` landed directly on the Deliveries list.

**After (Phase 75 / Fork A):** `/ops/mail/?tenant_id=northstar` now lands on the Operator Overview (`:overview` action on `OperatorLive`). The Deliveries list is reached at `/ops/mail/?tenant_id=northstar&view=deliveries`. This is the intentional IA change per D-24 (Fork A locked: Operator Overview as a `:overview` action on existing `OperatorLive`, zero router-macro change). A reviewer comparing deliveries-at-landing screenshots from the Phase 74 baseline against the v1.7 state will see a different page at the same URL — this is correct and expected.

**Note for future audit-matrix runs:** The script at `mailglass_admin/scripts/ui-audit.sh` captures the `deliveries` surface at `/ops/mail/?tenant_id=northstar`, which now shows the Operator Overview. To capture the Deliveries list separately, navigate to `/ops/mail/?tenant_id=northstar&view=deliveries`. No script change is required — the durable audit artifact is textual.

---

## 5. Closeout Declaration

**Zero open severity-4 or severity-5 rows. Phase 79 closeout criterion met.**

| Severity | Open Rows | Status |
|----------|-----------|--------|
| 5 | 0 | No sev-5 rows existed at Phase 74 baseline |
| 4 | 0 | All five sev-4 rows (GAP-01/03/05/06/13) are CLOSED |
| 3 | 1 (GAP-22) | DEFERRED — does not block closeout per severity rubric |
| 2 | 0 open (GAP-18, GAP-12, GAP-15, GAP-20) | Informational; not targeted in v1.7 scope |
| 1 | 0 open | Informational |

---

## 6. Frozen Register Acknowledgment

`74-GAP-REGISTER.md` is frozen read-only and was NOT modified by Phase 79. All closure evidence is recorded exclusively in this file (`79-GAP-CLOSEOUT.md`). The stable `GAP-NN` IDs from `74-GAP-REGISTER.md` are cited by reference only.

---

## 7. Per-Phase SUMMARY Source Map

The evidence table in Section 2 aggregates from the following per-phase SUMMARY files:

| Source SUMMARY | GAP Rows Covered | Commits Referenced |
|----------------|-----------------|-------------------|
| `.planning/phases/76-component-library-and-design-system-hardening/76-02-SUMMARY.md` | GAP-01, GAP-03, GAP-05, GAP-06 | `8a4e22c4`, `3f573b75` |
| `.planning/phases/76-component-library-and-design-system-hardening/76-03-SUMMARY.md` | GAP-13 (restructure) | `08c4b403`, `ca9c393a` |
| `.planning/phases/78-seed-data-expressiveness/78-01-SUMMARY.md` | GAP-13 (seeds reachable) | `074b0cde` |
| `.planning/phases/75-information-architecture-navigation-and-orientation/75-03-SUMMARY.md` | GAP-07, GAP-21, GAP-22 (recorded) | (per 75-03 commits) |
