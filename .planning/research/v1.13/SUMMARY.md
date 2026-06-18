# v1.13 Research Summary — Admin Design-System Stress Test & UX Uplift (v3)

**Project:** mailglass / `mailglass_admin`
**Domain:** Mountable Phoenix LiveView operator/admin dashboard — design-system uplift + idempotent quality ratchet
**Researched:** 2026-06-18
**Confidence:** HIGH
**Relationship to prior research:** This is a SUBSEQUENT-MILESTONE synthesis. It EXTENDS the v1.11 LOCKED-DECISION dossiers (`MOTION.md` MOTION-LD-01..14, `DARK-MODE.md` DARK-LD-01..08, `COMPONENT-STATES.md` STATE-LD-01..22, `IA.md` IA-LD-01..09, `MICROCOPY.md` COPY-LD-01..16) and the armed v1.11 ratchet. It does NOT re-derive or overwrite the foundational root `.planning/research/{STACK,FEATURES,ARCHITECTURE,PITFALLS}.md`. Downstream consumer: the requirements + roadmap steps of `/gsd-new-milestone`.

---

## Executive Summary

v1.13 is a **lived-experience / real-demo-driven** design-system uplift of `mailglass_admin` (D-29) — the third adopter-visible-quality admin pass after v1.7 and v1.11, distinguished by being driven by *clicking the real `make demo` app* rather than passing in the lab. The v1.11 ratchet was strong (LLM-scored PNG matrix, structural Playwright assertions, grep gates, meet-or-beat baseline) yet the maintainer still hit usability traps — a tenant-scoping dead-end, a pointless single-tenant picker, clipped stat-card labels, modal-behind-scrim, "kind of ugly" rough edges. The core insight across all four research files: **the v1.11 ratchet measured structure and tokens, not lived interaction quality on realistic data** (PITFALLS Bucket C, "lab-passes-but-ugly"). v1.13 closes that gap, then SHIPS (D-28: merge PR #86 first, then one linked-version Hex release, admin-minor dragging core+inbound via the D-13 exact-pin).

The research is strongly **convergent and opinionated**. All four dimensions independently land on the same answers: **extend the in-house `/dev/mail/gallery` LiveView** (do NOT add PhoenixStorybook — it imports a JS/esbuild build surface this zero-Node project deliberately lacks); build **system/light/dark with system as default** in-house via daisyUI `prefersdark` + a namespaced cookie + a no-FOUC inline script (no `phx-hook`, no theme library); add **exactly one** test-only npm devDependency (`@axe-core/playwright` for WCAG 2.2 AA) and zero new Hex deps; keep regression **screenshot-free** by extending the meet-or-beat score baseline + structural/computed-style assertions, adding an **axe-violation JSON baseline** as the new ratchet primitive (no pixel-diff, ever); and put **tenant listing / auto-select in the core read model** (`Mailglass.Operator.*` scoped via `Mailglass.Tenancy.scope/2`), never raw admin Repo queries.

The work is fractal and **dependency-ordered**: foundations/z-index/system-theme/gate-tightening FIRST → primitives → forms → app-shell + tenant seam → data-display → component-groups → pages/flows + micro-animation/microcopy → fixtures (the multi-tenant persona cohort) + ratchet-arm LAST. Two binding sequencing constraints thread through everything: **(1) merge PR #86 first** (it carries the already-landed tenant-scope/theme fixes the rest builds on), and **(2) tighten gates BEFORE re-baselining** (the v1.11 trap: if you re-score first the higher numbers become the floor and the looser gate can never be re-armed against them). The **keystone dependency** is the multi-tenant stress-fixture cohort — most data-display and state features are only *provable* against it, which is why it lands late but gates the final ratchet-arm.

---

## Key Findings

### Recommended Stack

Net-new dependencies for the entire milestone: **exactly one test-only npm devDependency (`@axe-core/playwright`). Zero new Hex deps. Zero new asset-pipeline tooling. Zero Node added to the build.** The load-bearing distinction (STACK): the "zero Node toolchain" lock is about the **CSS/asset build pipeline** (committed `priv/static/app.css` via the standalone `tailwind` binary). The **dev/CI test harness already uses Node** (`@playwright/test`, `npm ci`, `npx playwright install`) and never ships in the Hex tarball — so adding a test-only axe devDependency extends an already-sanctioned surface and does NOT violate the lock.

**Core technologies (confirm, do not touch):**
- **standalone `tailwind` binary (`{:tailwind, "~> 0.4"}`, Tailwind v4.1.x)** — compiles tokens + daisyUI into the committed bundle. Zero-Node asset pipeline. No change.
- **daisyUI 5 (`prefersdark`)** — already supplies "system mode" for free at the CSS layer; `system` = emit NO `data-theme` and let `prefersdark` resolve via `prefers-color-scheme`. No change.
- **`phoenix_live_view ~> 1.1`** — motion + theme are LiveView/CSS-native. No client JS hook anywhere.
- **`@playwright/test ^1.59.1`** — existing structural/contrast gate harness; the host for the a11y additions.

**The ONE addition:**
- **`@axe-core/playwright ^4.11.2`** (bundles axe-core ≥4.10, `wcag22aa` rules incl. 2.5.8 target-size) — test-only devDependency in `mailglass_admin/package.json`. Scan with `.withTags(['wcag2a','wcag2aa','wcag21a','wcag21aa','wcag22aa'])`; scan opened dialogs/popovers via `.include('[role=dialog]')`. Catches ~⅓ of WCAG (contrast, ARIA, names, target-size) — keep manual review for focus-order, keyboard traps, reading order, copy quality.

**Explicitly rejected:** PhoenixStorybook (JS/esbuild surface + second mountable surface a library shouldn't impose); Pa11y (duplicate headless-Chrome harness, re-solves auth); any pixel-diff tool (Percy/Chromatic/`toHaveScreenshot`/BackstopJS — violates the gitignored-PNG precedent); JS animation libs; `phx-hook` for theme; host-global theme storage.

### Expected Features

Organized by fractal level × 5 personas (P1 Evaluator, P2 Integrator, P3 Maintainer, P4 Operator/SRE, P5 Security reviewer). The v1.11 locks settle per-state, IA, microcopy, motion, dark-mode; v1.13 builds the *next* layer.

**Must have (table stakes — the MVP):**
- **Theme picker: system / light / dark, system default** — THE headline fix; host-scoped persistence, also drives Preview chrome (closes v1.11 GAP-03).
- **Multi-tenant selector** — auto-select sole tenant (kills the "pointless single-tenant picker") + switcher list when >1 (kills the "No tenant selected" dead-end); list, never free-text.
- **Permission-denied state** — distinct from no-tenant-chosen and from crash (NEW template).
- **Canonical `stat_card` primitive** — label truncate+tooltip, value `tabular-nums` never-wraps, severity-first (icon+label+color, never color-alone). Fixes "clipped stat-card labels."
- **Row-to-card responsive transform** for Deliveries + Inbound lists <768px — kills squished tables.
- **Honest pagination** — result count always; chrome only when >1 page (GOV.UK rule); boundary-disabled (not hidden) prev/next.
- **z-index layer system + token coverage in light/dark/system** — fixes modal-behind-scrim.
- **44×44 touch-target resolution** (the `btn-sm`/`min-h-11` tension) — verified in the compiled bundle.
- **Usability-bug sweep** (24 enumerated defects, PITFALLS Bucket A).
- **Stress-fixture cohort (2–3 tenant personas + edge data)** — the proving substrate.
- **Extended idempotent ratchet** (system theme + WCAG 2.2 AA + 320/wide + axe-JSON baseline + interaction pillar).

**Should have (differentiators, add after if capacity):**
- Stale-data indicator ("as of HH:MM" + refresh) on live surfaces (P4 SRE).
- Skeleton loaders (not spinners) for master/detail.
- LiveView `streams` for live-append lists.
- Component-lab matrix widened to full component×state×theme×viewport.

**Anti-features (defer/never):** PhoenixStorybook; squished responsive tables; sortable/filterable mega-table-of-everything (Kaffy/AshAdmin auto-admin); always-on pagination bar; server-persisted per-user/per-tenant theme; cross-tenant "all tenants" view (data-leak, violates D-09 isolation); tenant CRUD in the picker (host-app concern); infinite scroll; color-only severity; illustration-heavy empty states (zero-asset constraint); pin/favorite tenants (over-engineered for a bounded set).

### Architecture Approach

`mailglass_admin` is **all stateless `Phoenix.Component` function components** (zero LiveComponents) across 3 parallel surfaces (Operator / Inbound / Preview) + 4 LiveViews + the dev-only gallery. This clean architecture means the gallery can render any component from static assigns — the foundation for the component-lab extension. The work is an **integration + build-order map onto existing machinery**, not from-scratch.

**Major components / seams:**
1. **Token/CSS layer** (`app.css`) — consumes `brandbook/tokens.css` (SoT, out of scope) + two daisyUI theme blocks (`mailglass-light{default}`, `mailglass-dark{prefersdark}`); compiled to a committed bundle behind a `git diff --exit-code` gate. v1.13 adds z-index/motion/elevation tokens + system-theme plumbing here.
2. **The 4-mechanism ratchet** — (a) score baseline `docs/ui-baseline-scores.json` (`schema_version:2`, 36 cells = 3 surfaces × 6 pillars × 2 themes, meet-or-beat fail-closed); (b) conformance grep gate `check-conformance.sh` (7 greps over `lib/`); (c) motion gate; (d) Playwright structural + **runtime WCAG contrast matrix** (`getComputedStyle`, no pixel-diff). EXTEND all four, don't redo.
3. **The gallery LiveView** (`gallery_live.ex`, dev-only in the preview `live_session`) — current matrix is component × state × theme (twin-theme wrappers + stable `data-testid`); widen to **+ viewport + system**. Prerequisite: **promote the gallery-inlined `nav_link/nav_pill/tenant_chip/theme_toggle` copies to public components** — a lab that renders a copy can't certify the real component (the gallery copy already drifted, omitting `phx-click`).
4. **The multi-tenant seam** — `?tenant_id=` URL param drives scoping; PR #86 already fixed `surface_paths` to carry `tenant_id` across surfaces. v1.13 owes `list_tenants` in the **core read model** (scoped via `Mailglass.Tenancy.scope/2`, through the authenticated `operator_actor`, never raw Repo) + auto-select-sole-tenant in `handle_params` + the shell picker UI (renders only when ≥2 tenants). Fixture cohort lands in `reference/demo_app` seeds.
5. **Host-app-friendliness seams** — auth (adopter-owned), session/cookie (whitelisted), assets (self-served md5 bundle, no host pipeline), Repo (core read-model only), CSS scoping (`data-theme="mailglass-*"` + `isolation: isolate`, no global `@media`/`<style>`). Every new system must preserve these.

### Critical Pitfalls

The unifying lesson is **PITFALLS Bucket C — "passes the lab but ugly in the real demo"** (the literal v1.13 trigger). The other buckets are 24 concrete usability bugs (A) and discipline footguns (B). Top items:

1. **"Lab-passes-but-ugly" process gap** — the ratchet measured structure, not interaction on realistic data. *Avoid:* add an **interaction pillar** (hit-testing modal-above-scrim, scroll-chaining, focus-restore, layout-jump) to the ratchet AND run at least one matrix run against the rich `reference/demo_app` data, not just structural assertions on seeded `host_app`. Stress fixtures (no-data/one/many/long-ID/non-ASCII/null/high-count/error) parameterize every assertion.
2. **Re-scoring before tightening gates** — the v1.11 trap; the higher score becomes the floor and the looser gate can never be re-armed. *Avoid:* every phase ordered tighten-gate → prove-green-on-current-code → only then re-baseline; re-score the whole matrix only at the very end.
3. **Modal-behind-scrim / z-index chaos** (no z-tokens in `app.css`; `replay_modal.ex` uses literal `z-40`, panel has no explicit z). *Avoid:* L0 formal z-index layer system (`--z-base/dropdown/overlay-scrim/overlay-panel/toast`) + Z-GATE grep + Playwright `elementFromPoint` hit-test on opened overlays + `isolation: isolate` on the mount root (host-safe stacking).
4. **Theme FOUC + system/explicit conflation** — `system` must be the absence of an explicit choice (clear the cookie), not a stored resolved value, or OS changes stop tracking; no-FOUC requires server-side `data-theme` from cookie for explicit choices and `prefersdark` (CSS, no flash) for system. *Avoid:* tri-state `:system|:light|:dark`; `:system` emits NO `data-theme`; namespaced cookie + inline early-set script (not a hook); never force-set `data-theme` for system (re-creates DARK-LD-08 split-brain).
5. **Tenant listing via raw Repo / single-tenant dead-end** — hijacks the host Repo, bypasses tenancy. *Avoid:* listing in the core operator read model scoped via `Tenancy.scope/2` through the authenticated actor; auto-select the sole tenant instead of gating it.

---

## Implications for Roadmap

The architecture + pitfalls researchers **converged on the same dependency-ordered fractal build order**. Phases continue from 108 → 109+. Suggested structure (the roadmapper assigns final numbers):

### Phase A: Foundations + Gate-Tightening (do FIRST, no uplift yet)
**Rationale:** Tokens and gates are the substrate everything else inherits; the v1.11 rule is tighten-before-rebaseline. **Binding precondition: merge PR #86 first** (held tenant-scope/theme fixes).
**Delivers:** Semantic-token completeness (color/surface/elevation, formal **z-index layer system**, focus rings, overlays, type scale, spacing, radius, shadows, borders, **motion tokens**) in light/dark/system, zero one-off values. Simultaneously: TYPE-GATE→`text-xl`, new Z-INDEX/FOCUS-RING/SCOPE gates, `system` added to `ratchet_baseline_test.exs` (schema v3), WCAG 2.2 SC added to the structural spec. Re-baseline tokens; do NOT re-score pillars yet.
**Avoids:** modal-behind-scrim (A1), host CSS leak / z-wars (B-H1/H2), re-scoring-before-tightening (B-C6).

### Phase B: Primitives (shared atoms)
**Rationale:** Fixing the primitive once (bottom-up) means every page inherits it (avoids B-C3 "fix one page, leave component-level inconsistency").
**Delivers:** Promote the gallery-inlined `nav_link/nav_pill/tenant_chip/theme_toggle` to public components (kills copy-drift). Audit every primitive in every state per WCAG 2.2 AA + WAI-ARIA APG, 320→wide. Define the canonical `stat_card` and the 3-way system/light/dark **picker primitive**. Icon-SVG-exists grep, disabled≠enabled structural test, STATCARD-GATE.
**Depends on:** A. **Avoids:** disabled-looking-enabled (A13), inconsistent stat cards (A12), invisible-icon footgun (A20), APG misuse (B-A4).

### Phase C: Forms (form-control audit)
**Rationale:** Forms sit on primitives; the two `filters_form.ex` should unify before app-shell consumes them.
**Delivers:** Shared `filter_field`/`filter_section` primitives; every input/error/disabled state.
**Depends on:** B.

### Phase D: App-Shell, Navigation & Tenant Seam
**Rationale:** The shell consumes the picker primitive (B) and the core listing; the tenant seam is the headline multi-tenant fix.
**Delivers:** Shell + nav L1/L2 discipline; **tenant listing (`list_tenants` in core, scoped via `Tenancy.scope/2`) + auto-select-sole-tenant in `handle_params` + shell picker (renders only ≥2 tenants)**; theme picker wired through the mount hook; honest pagination affordances; tab active-state (non-color cue).
**Depends on:** B (picker primitive), C, and the core read-model listing. **Avoids:** "No tenant selected" dead-end + pointless single-tenant picker (B-C5), no-system-picker (A17), FOUC (B-T1), theme persistence conflation (B-T2/T3), host theme hijack (B-H3).

### Phase E: Data-Display
**Rationale:** The densest, most-differentiating level; depends only on primitives.
**Delivers:** Tables-vs-cards discipline (table ≥768, **row-to-card <768**); migrate all stat cards to the canonical `stat_card`; timelines; empty/error/**permission**/**stale** states; squished-column / clipped-label fixes; severity-first encoding.
**Depends on:** B. **Avoids:** squished/overused tables (A10/A11), chopped padding/overflow (A6), bare-`—` placeholders (A24), weird pagination (A19).

### Phase F: Component Groups (meta-components)
**Rationale:** Coherence across composed groups is a group-level concern (box-in-box, alignment).
**Delivers:** Coherent spacing/hierarchy across support-cards triage, routing-trace + evidence, detail + timeline; box-in-box depth ≤2; alignment x/y discipline.
**Depends on:** B–E. **Avoids:** "box prison" nesting (A9), misalignment (A5), flush content (A8).

### Phase G: Pages/Flows + Micro-Animation + Microcopy
**Rationale:** Whole-surface IA and lived flows sit on top of every primitive/group.
**Delivers:** GOV.UK-style IA, principle of least surprise, per-persona/JTBD happy/error/boundary/edge paths across all 3 surfaces in light/dark/system at every width; **micro-animation pass** (Emil Kowalski origin-aware overlays, reduced-motion, transform/opacity only — only deltas beyond MOTION-LD-*: theme-switch-must-not-animate, target-size, gallery-viewport-no-multiply-motion); **microcopy pass** (permission/stale copy, "Oops" banned).
**Depends on:** A–F. **Avoids:** post-patch focus loss (B-A9/A14), motion blocking feedback (B-M4).

### Phase H: Fixtures + Ratchet-Arm (LAST — the keystone closes here)
**Rationale:** The multi-tenant stress cohort is the **keystone dependency** — most data-display/state features are only *provable* against it, so it lands late but gates the final score. Tighten-then-rebaseline means gates are already armed against the new floor.
**Delivers:** Land the 2–3-persona stress cohort in `reference/demo_app` seeds + gallery stress specimens; **widen the gallery to component × state × {light,dark,system} × {320..wide}**; run the FULL matrix INCLUDING the interaction pillar AND at least one run against the rich `demo_app` data (closes B-C4); add the **axe-violation JSON baseline**; promote `current → prior` and re-score; verify all gates green; **stage + actually cut the linked-version release** (D-28: admin-minor drags core+inbound, D-13 exact-pin re-pin).
**Depends on:** A–G. **Avoids:** lab-passes-but-ugly (B-C4), perfect-seed-data-only states (B-C5), baseline erosion (B-C6).

### Phase Ordering Rationale
- **Bottom-up fractal order** (foundations → primitives → ... → pages) so each level inherits a fixed lower level — directly prevents B-C3 (fix-one-page-leave-component-inconsistency).
- **Gates tightened inside each phase, re-score only at the end** — the binding v1.11 anti-trap (B-C6 / Architecture §3).
- **Fixtures + ratchet-arm last** because the cohort is the proving substrate the whole matrix runs against; arming earlier would re-baseline against incomplete data.
- **Two hard gates threaded through:** merge PR #86 before Phase A; the interaction pillar + demo_app run must exist before the final ratchet-arm.

### Research Flags

**Phases with standard patterns (plan directly — research already convergent and adversarially judged in the 4 dossiers + v1.11 locks):** A, B, C, E, F, G. The patterns are settled (extend the gallery, extend the gates, the 24-bug catalog with concrete Playwright/grep guards, the 4-template empty-state taxonomy, tables-vs-cards heuristic, severity encoding). No deeper research needed.

**Phases likely needing light `/gsd-plan-phase` research during planning:**
- **Phase D (tenant seam):** the exact shape of the core `list_tenants` projection — distinct-tenant query vs a dedicated read model — and how it composes with `Tenancy.scope/2` and the `operator_actor` auth context. Confirm the seam in core, not admin. (Open question flagged by Architecture §4c.)
- **Phase H (ratchet-arm):** decide the **axe-JSON baseline format** (per-surface counts vs rule-id allowlist) — it's the new ratchet primitive and should match the existing score-baseline ergonomics (STACK open question). Plus the `ratchet_baseline_test.exs` schema-v3 cell-count decision (add `system` as a 3rd theme → 54 cells vs keeping viewport structural-only — Architecture §3a recommends the latter to avoid a 324-cell explosion).

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Every rec grounded in shipped code (`package.json`, `app.css`, `mix.exs :files`, gallery, shell) + verified current versions (`@axe-core/playwright` 4.11.2, `phoenix_storybook` 1.2.0, daisyUI 5 `prefersdark`). The one new dep is well-understood and test-only. |
| Features | HIGH | Mature DS (Carbon/Polaris/GOV.UK/Atlassian) + Elixir peers (LiveDashboard/Oban Web/Backpex) are convergent; project-specifics grounded in v1.11 locks + the named bug list + `guides/jobs.md`. |
| Architecture | HIGH | Every claim cites a real file path read in `mailglass_admin/`; ratchet machinery, gallery, router/mount, tenant seam, and host-safety seams all inspected directly; PR #86 fix read in full. |
| Pitfalls | HIGH | 24 concrete bugs + discipline footguns grounded in codebase grep (literal `z-40`, binary `theme_toggle`, URL-param theme) + WCAG 2.2 / WAI-ARIA APG / Emil Kowalski / GOV.UK convergence; every row proposes a concrete guard. |

**Overall confidence:** HIGH

### Gaps to Address
- **Core `list_tenants` projection shape** — resolve during Phase D planning (distinct-tenant vs read model; composition with `Tenancy.scope/2` + actor). Must live in core, scoped, not raw admin Repo.
- **axe-JSON baseline format + schema-v3 cell count** — resolve during Phase H planning (per-surface counts vs rule-id allowlist; `system`-as-theme vs viewport-structural-only). Match the existing score-baseline ergonomics.
- **No-FOUC for explicit-dark first paint inside a mountable lib** — confirm the namespaced cookie is readable in `mount/3` for the adopter's chosen mount path so the first server render is already correct (the only fully flash-free path).
- **Dense-control 24px audit** — the axe `target-size` rule will surface dense replay/sort buttons currently advisory-only; requirements should decide gate-now vs GAP-record per the v1.11 split.
- **Tooltip delay-then-instant grouping** under the zero-JS constraint (B-M3) — may not be achievable without a hook; document the decision in the MOTION delta rather than forcing it.

## Sources

### Primary (HIGH confidence) — project-internal, grounded in code
- `.planning/research/v1.13/STACK.md` — the one-dep decision, the zero-Node-asset vs Node-test distinction, theme/gallery/a11y/regression/motion recommendations.
- `.planning/research/v1.13/FEATURES.md` — fractal × persona feature landscape, MVP, anti-features, competitor matrix.
- `.planning/research/v1.13/ARCHITECTURE.md` — inventory, gallery extension, ratchet extension, tenant seam, host-safety, the dependency-ordered Phase A–H build order.
- `.planning/research/v1.13/PITFALLS.md` — 24 usability bugs (Bucket A), discipline footguns (Bucket B), the "lab-passes-but-ugly" process gap (Bucket C), pitfall→fractal-level map.
- `.planning/PROJECT.md` — v1.13 scope locks, D-23/D-28/D-29, the named bug list, the merge-PR-#86-then-ship release posture.
- `.planning/research/v1.11/{MOTION,DARK-MODE,COMPONENT-STATES,IA,MICROCOPY}.md` + the armed v1.11 ratchet — EXTENDED, not redone.
- `mailglass_admin/` codebase reads — `gallery_live.ex`, `operator/shell.ex`, `operator_live.ex`, `replay_modal.ex`, `components.ex`, `app.css`, `mix.exs`, `package.json`, `docs/ui-baseline-scores.json`, `ratchet_baseline_test.exs`, `e2e/structural.spec.js`, `scripts/check-conformance.sh`; commit `92866236` / PR #86.

### Secondary (HIGH/MEDIUM) — external standards & exemplars
- WCAG 2.2 (W3C / Deque) — 2.5.8 Target Size, 2.4.11 Focus Not Obscured, 2.4.13 Focus Appearance; WAI-ARIA APG Dialog pattern.
- `@axe-core/playwright` (npm 4.11.2), axe-core `wcag22aa` tags (Deque); Playwright accessibility-testing docs.
- daisyUI 5 `prefersdark`; `phoenix_storybook` 1.2.0 setup docs (esbuild/JS-entrypoint requirement — MEDIUM on detail).
- Carbon, Shopify Polaris, GOV.UK Design System + Service Manual, Atlassian ADS; Phoenix LiveDashboard, Oban Web, Backpex, Kaffy, AshAdmin.
- Emil Kowalski (origin-aware overlays, `scale(0)` anti-pattern, tooltip delay-then-instant); Aleksandr Hovhannisyan / CSS-Tricks (FOUC, system-vs-explicit persistence); M365 / Clerk tenant switchers.

---
*Research completed: 2026-06-18*
*Ready for requirements + roadmap: yes*
