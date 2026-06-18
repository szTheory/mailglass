# Architecture Research — v1.13 Admin Design-System Stress Test

**Domain:** Mountable Phoenix LiveView admin dashboard — fractal design-system uplift + idempotent quality ratchet (extends v1.11)
**Researched:** 2026-06-18
**Confidence:** HIGH (every claim cites a real file path read in `mailglass_admin/`; ratchet/gate machinery, gallery, router/mount, and tenant seam all inspected directly)

> Scope: this file answers "how does the fractal stress-test integrate with the EXISTING
> architecture, and what is the build order?" It is an **integration + build-order** map, not a
> from-scratch architecture. It does NOT modify `.planning/research/ARCHITECTURE.md` (the
> foundational project file). Downstream: roadmap creation.

---

## 1. INVENTORY — the admin UI architecture as built

### 1a. Component layer (all are **function components**, not LiveComponents)

There are **zero `Phoenix.LiveComponent`s** in `mailglass_admin`. Every UI unit is a stateless
`Phoenix.Component` function component with a co-located `~H` sigil; state lives in the three
parent LiveViews. This is a deliberate, clean architecture — the gallery can render any
component from static assigns with no live process.

**Shared atoms** — `lib/mailglass_admin/components.ex`:

| Component | Def | Notes |
|-----------|-----|-------|
| `icon/1` | `components.ex:45` | heroicons via `vendor/heroicons-inline.js` plugin; `aria-hidden` |
| `logo/1` | `components.ex:62` | `currentColor` sealed-flap SVG |
| `flash/1` | `components.ex:102` | daisyUI `alert-{kind}` |
| `badge/1` | `components.ex:129/137` | `:warning` / `:stub` variants |
| `status_badge/1` | `components.ex:197` | **the** canonical status→color atom; 22 atoms + `nil` fallback (STATE-LD-05). Single source after v1.7 collapsed five `badge_class/1` copies (BADGE-GATE enforces it) |
| `mask_recipient` / `mask_email` / `mask_value` | `components.ex:296-324` | PII masking helpers |

**Surface-scoped function components** (3 surfaces, parallel folder structure):

- **Operator** (`operator/`): `shell.ex` (app-shell: nav, tenant_chip, theme_toggle, orientation_strip), `deliveries_list.ex`, `detail_header.ex`, `filters_form.ex`, `support_cards.ex`, `suppression_card.ex`, `timeline.ex`, `replay_modal.ex`, `destructive_action.ex`, `repair_state.ex`, `mount.ex` (auth hook).
- **Inbound** (`inbound/`): `records_list.ex`, `detail_header.ex`, `filters_form.ex`, `routing_trace.ex`, `evidence_card.ex`, `timeline.ex`, `replay_modal.ex`, `overview.ex`, `destructive_action.ex`, `filters_form.ex`.
- **Preview** (`preview/`): `sidebar.ex`, `tabs.ex`, `device_frame.ex`, `assigns_form.ex`, `discovery.ex`, `mount.ex`.

**LiveViews (the only stateful units):** `operator_live.ex`, `inbound_live.ex`, `preview_live.ex`, `gallery_live.ex`. `layouts.ex` is the root layout.

### 1b. Token / CSS layer

`assets/css/app.css` (~single bundle, zero Node):
- `@import "../../../brandbook/tokens.css"` (line 9) — consumes the canonical two-tier `--mg-*` tokens. This is the v1.11 re-baseline; `brandbook/` is the SoT and is **out of v1.13 scope** (scope lock).
- Two `@plugin "daisyui-theme"` blocks: `mailglass-light` (`default: true`, `prefersdark: false`) and `mailglass-dark` (`prefersdark: true`). Each maps daisyUI `--color-*` → `--mg-*` tokens. No raw hex (TOKEN-01).
- A `@theme` block defines the semantic type scale (`text-label/body/heading/display`), spacing tokens (`gap-sm/md/lg`, `px-sm/md/lg`), `--duration-fast/instant`, easing tokens (`--ease-out`, `--ease-symmetric`), and the `prefers-reduced-motion` global block (`app.css:292-300`, `0.01ms !important`).
- Built by `mix mailglass_admin.assets.build` (standalone Tailwind binary). The compiled bundle lives in `priv/static/` and is **committed** behind a `git diff --exit-code priv/static/` CI gate (per CLAUDE.md rule 6).

**Duplication / one-off styling that should become design-system primitives (the v1.13 target list):**

| Smell | Where | Promote to |
|-------|-------|------------|
| `nav_link` / `nav_pill` / `tenant_chip` / `theme_toggle` are **`defp` inside `shell.ex`** AND **re-inlined verbatim in `gallery_live.ex:162-243`** | `operator/shell.ex` + `gallery_live.ex` | extract to public `components.ex` function components so gallery imports them, not copies them (the gallery copy already drifts: see §2) |
| Two near-identical `filters_form.ex` (operator + inbound) | `operator/filters_form.ex`, `inbound/filters_form.ex` | a shared `filter_field` / `filter_section` primitive (IA-LD-04 already forces label parity) |
| Two near-identical `detail_header.ex`, two `timeline.ex`, two `replay_modal.ex` | operator + inbound | shared primitives parameterized by surface |
| Stat/summary cards diverge: operator `support_cards.ex` vs inbound `overview.ex` ("inconsistent stat cards", clipped labels — fixed ad-hoc in 92866236) | both | one canonical `stat_card` primitive |
| `text-xl` raw utility (not `text-heading` token) flagged STATE-LD-12 | `operator/detail_header.ex`, `inbound/detail_header.ex` | already a known GAP; TYPE-GATE catches `text-sm/xs/base` but **not** `text-xl/2xl` — see §3 gate-tightening |
| `border-l-[3px]`, `max-h-80`, `px-5` arbitrary values | `preview/sidebar.ex`, `inbound/evidence_card.ex`, `operator/detail_header.ex` | token rounding (STATE-LD-22/19/12) |
| `btn-sm` + `min-h-11` tension (touch-target) | `theme_toggle`, `device_frame`, `evidence_card`, `support_cards` | a sized icon-button primitive |

### 1c. The ratchet machinery (extend, do not redo)

Four independent enforcement mechanisms, all currently green:

1. **Score baseline (meet-or-beat)** — `docs/ui-baseline-scores.json` (`schema_version: 2`) + `test/mailglass_admin/ratchet_baseline_test.exs`. A `prior` block and a `current` block, each **3 surfaces × 6 pillars × 2 themes = 36 cells**, scores 1–4. `compare_baselines/2` (test line 90) fails closed on **any** `current < prior` regression and on missing cells; the anti-vacuity guard asserts `prior.run_id != current.run_id`. Pillars: `Spacing, Radius, Color, Type, Elevation, Motion+A11y`.
2. **Conformance grep gate** — `scripts/check-conformance.sh`: seven greps over `lib/**/*.ex` (BADGE / TYPE / BOLD / GAP / HEX / MOTION ×2). cwd-independent (anchored to `BASH_SOURCE`), fail-loud. An advisory twin exists (`check-conformance-advisory.sh`).
3. **Motion gate** — `scripts/check_motion_conformance.sh` (repo root) + MOTION greps inside `check-conformance.sh` (MOTION-LD-01/10: bans layout-property transitions and stray `ease-in`).
4. **Playwright structural assertions** — `e2e/structural.spec.js` (1042 lines) + `e2e/operator.spec.js`. Seven "D-01 pillar FACTs" (ARIA, ≥44px touch targets, font-weight∈{400,700}, reduced-motion collapse, visible focus rings, accent-only-on-allowlist, enter/exit asymmetry) PLUS per-surface state-coverage, responsive-grid (390/768/1440), and a **runtime WCAG contrast matrix** (`assertTextContrastAA` ≥4.5:1, `assertNonTextContrastAA` ≥3:1 computed from `getComputedStyle` — **no pixel diff**). Gallery has its own `describe` block asserting `data-testid="gallery-{component}-{state}"` cells + twin-theme wrappers.

There is also `docs/ui-baseline-scores.json` LLM-scored PNG matrix (PNGs gitignored); the JSON is the committed artifact. Token-parity (`token_parity_test.exs`) and bundle-clean (`bundle_test.exs`) gates round out the lane.

### 1d. The gallery LiveView (the v1.11 component-lab seed)

`lib/mailglass_admin/gallery_live.ex` (785 lines), routed at `/dev/mail/gallery` **inside the
preview `live_session`** (`router.ex:226`). No DB, no auth, no mailable scan. Renders a flat
`@specimens` list — one `{component, state, assigns_map}` tuple per STATE-LD row × state atom
(currently ~55 specimens across 22 component types). Each cell wraps **twin
`data-theme="mailglass-light"` + `data-theme="mailglass-dark"`** wrappers so one structural
assertion covers both themes. This is the surface v1.13 extends into the full matrix (§2).

---

## 2. COMPONENT-LAB SURFACE design — extend `/dev/mail/gallery`

**Decision: extend the in-house gallery; do NOT adopt PhoenixStorybook** (zero-Node rule, no
new dep payoff, the twin-theme + `data-testid` pattern already doubles as the structural-assert
surface — confirmed in `structural.spec.js:999-1040`). PROJECT.md target features call for a
decision brief leaning in-house; the existing surface already proves the pattern.

### Current matrix vs target matrix

Today the gallery is **component × state × theme** (theme via twin wrappers). v1.13 widens it to
**component × state × theme × viewport**, where theme grows from {light, dark} to {light, dark,
**system**} and viewport becomes an explicit axis {320, 375, 768, 1024, 1440, wide}.

### Concrete extension design

1. **Promote the inlined components first.** `gallery_live.ex:162-243` re-implements `nav_link`,
   `nav_pill`, `tenant_chip`, `theme_toggle` by **copying** the `shell.ex` `defp` HEEx. This is a
   latent drift bug (the gallery `theme_toggle` already omits `phx-click`). Extract these to public
   `components.ex` (or a `Shell` public API) so the gallery and the shell render the *same* code.
   This is a prerequisite, not optional — a component lab that renders a *copy* cannot certify the
   real component.
2. **Viewport axis without N×6 route explosion.** Keep one route. Render each specimen cell at its
   natural width but add a **viewport harness**: a `?w=320|375|768|1024|1440|wide` URL param that
   sets a max-width container around the specimen grid (CSS-only, LiveView reads the param in
   `handle_params`). Playwright drives the real device width via `page.setViewportSize` (already
   the pattern in `structural.spec.js`), so the structural matrix iterates viewports while the
   route stays singular. This mirrors the existing `inbound`/`preview` contrast-matrix loops
   (`structural.spec.js:566`, `:733`) that loop `themes × viewports` against one URL.
3. **System-theme axis.** Add a third wrapper variant. Today each cell has light + dark wrappers;
   add the ability to render under the **system** resolution (`@media (prefers-color-scheme)`),
   driven by Playwright `page.emulateMedia({ colorScheme })`. The gallery cell stays declarative;
   the test toggles the OS preference. (See §3 + §5 for the system-theme plumbing this depends on.)
4. **State completeness pass.** The gallery already enumerates STATE-LD rows but several are
   `:closed`/`:rest`-only (replay_modal open states "require a live event"; device_frame only
   `inactive-btn`; tabs only `inactive-tab`). v1.13's "every component in every state"
   (hover/focus/active/pressed/disabled/loading/selected/error/empty/long-content) needs: (a) the
   open/loading/long-content specimens added as static assigns where possible, and (b) interactive
   states (hover/focus/active) certified by Playwright `:hover`/`.focus()` against gallery cells
   rather than only static render.
5. **Long-content / overflow specimens.** Add deliberate stress fixtures: long tenant IDs,
   non-ASCII recipients, high event counts, null fields — these double as the multi-tenant stress
   cohort's component-level proof (the "squished table columns / clipped labels" class of bug from
   92866236).

The gallery remains **dev-only** (lives in the preview `live_session`, gated by the adopter's
`if dev_routes` wrapper — `router.ex:14-21`), so none of this ships to production admins.

---

## 3. RATCHET EXTENSION — cover the new axes without regressions, without pixel-diff

The v1.11 lesson is explicit and binding: **tighten the gates BEFORE re-baselining.** If you
re-score first, the new (higher) numbers become the floor and the looser gates can never be
re-armed against them. Order every phase: tighten gate → prove green on current code → only then
re-score/re-baseline.

### 3a. Score baseline (`ui-baseline-scores.json`)

The schema is hardcoded to 2 themes in `ratchet_baseline_test.exs:28` (`@themes ["light","dark"]`).
To add **system** and keep no-regression:

- Bump `schema_version` → 3 (the test asserts `== 2`; update in lockstep — `:40`).
- Either add `"system"` to `@themes` (→ 54 cells) **or** keep theme at 2 and add a separate
  `viewport` dimension. **Recommendation:** add `system` as a theme value (54 cells) AND keep
  viewport as structural-only (Playwright), because the LLM PNG scoring is theme-sensitive but the
  viewport facts (grid ratios, touch targets, no-overflow) are objective and belong in the
  structural layer, not the 1–4 subjective scores. This keeps the JSON from exploding to 324 cells.
- `compare_baselines/2` already fails closed on missing cells, so adding cells to `current`
  without adding them to `prior` would regress-fail — the v1.11 promotion procedure (copy current
  → prior, then re-score current) handles this; do it **after** gates are tightened.

### 3b. Conformance grep gate (`check-conformance.sh`)

Add gates for the new design-system rules **before** any uplift:
- Extend TYPE-GATE to catch `text-xl`/`text-2xl`/`text-3xl` (currently only `text-sm/xs/base`),
  which closes the known STATE-LD-12 `text-xl` smell at lint time.
- Add a **Z-INDEX-GATE**: ban raw `z-10/20/.../[999]` arbitrary z utilities once a formal z-index
  layer token system exists (PROJECT.md foundations target). Tokenize overlay/scrim/modal/popover
  layers; gate raw values.
- Add a **FOCUS-RING-GATE** / **OVERLAY-GATE** as needed for the new foundation tokens.
- All gates scope to `lib/**/*.ex` and are pure grep — no pixel diff, idempotent.

### 3c. WCAG 2.2 AA — extend the existing runtime contrast matrix

The structural spec **already** computes WCAG contrast at runtime (`contrastRatio`,
`assertTextContrastAA` ≥4.5, `assertNonTextContrastAA` ≥3 — `structural.spec.js:178-239`) — this
is the no-pixel-diff a11y mechanism and it generalizes cleanly:
- Add **2.2-specific** success criteria as structural assertions: 2.4.11 focus-not-obscured
  (assert focused element is in viewport / not behind a scrim), 2.5.8 target-size (the existing
  ≥44px check, extend to all interactive states), 3.2.6 consistent help, 1.4.11 non-text contrast
  (already present for borders/focus rings).
- Run the contrast matrix loop over **{light, dark, system} × {320,375,768,1024,1440,wide}** by
  extending the existing `themes × viewports` loops (`structural.spec.js:566/733`) — same code
  shape, more iterations. Computed-style based, never pixel.

### 3d. Motion gate

No change needed structurally; re-run the existing MOTION greps + the reduced-motion computed-
duration assertion (`structural.spec.js:804`) across the new viewport axis. The motion token
system already exists (`--ease-out`, `--duration-fast`); v1.13 only adds origin-aware overlay
motion tokens, which the existing MOTION-GATE covers.

### 3e. No-regression guarantee

The four mechanisms together give no-regression without pixel-diff:
- **grep gates** = "no off-token values ever re-enter" (idempotent, fail-closed).
- **score baseline** = "no pillar score drops" (meet-or-beat, fail-closed).
- **Playwright structural + runtime-WCAG** = "objective facts (ARIA, contrast ratios, grid
  ratios, touch targets, focus visibility) hold at every theme × viewport."
- **token-parity + bundle-clean** = "CSS stays sourced from `brandbook/tokens.css` and the
  committed bundle matches source."

---

## 4. MULTI-TENANT seam — fixture cohort + tenant listing / auto-select

### 4a. Where the fixture cohort lives

`reference/demo_app/priv/repo/seeds.exs` → `MailglassDemo.DemoData`
(`reference/demo_app/lib/mailglass_demo/demo_data.ex`). Today there is **one tenant: `northstar`**
("Tenant **northstar** contains deterministic..." — `page_controller.ex:80`). v1.13 adds the
**2–3 persona cohort** here (e.g. a high-volume tenant, a quiet/near-empty tenant, a tenant with
long/non-ASCII IDs and error/boundary records). All records carry `tenant_id` (D-09) and must be
seeded through the same public seam — the seeds are the realistic-cohort home, the gallery
(§2.5) is the component-level stress home.

### 4b. The tenant-scoping seam (the "No tenant selected" dead-end)

This is real code and was **partially** fixed in commit `92866236` (read in full):

- **The dead-end:** `/ops/mail` and `/ops/mail/inbound` are tenant-scoped. Tenant flows in via
  the `?tenant_id=` URL param → `OperatorLive.handle_params/3` normalizes it
  (`operator_live.ex:74`, `normalize_filter_params`); when blank, `load_deliveries(%{"tenant_id"
  => ""})` returns `[]` (`operator_live.ex:543`) and the surface renders "No tenant selected"
  (`shell.ex:253` `tenant_chip`, plus the overview/records-list copy). It is NOT a 302 redirect
  in the current code — it is an empty-state render (IA-LD-07a). The "302 dead-end" in the prompt
  is the *experienced* symptom: a cross-surface click that dropped `tenant_id`.
- **Already fixed (92866236):** `Shell.surface_paths/3` (`shell.ex:50`) previously carried only
  `?theme=` across Deliveries↔Inbound, dropping `tenant_id` — so every cross-surface click landed
  bare → "No tenant selected." Now `surface_paths` carries `tenant_id` too. Theme toggle was also
  repaired (root `<html data-theme>` now wired through the mount hook). This fix is **on the held
  PR #86 branch** (`fix/admin-preview-mount-aware-urls`, the current branch) — v1.13 must merge it
  first (PROJECT.md release lock).
- **What v1.13 still owes (the seam to build):** there is **no tenant LISTING and no
  auto-select-sole-tenant**. The tenant is a free-text URL param / session value; there is no
  picker that enumerates available tenants, and a single-tenant install still shows a pointless
  "No tenant selected" gate (the "pointless single-tenant picker" complaint).

### 4c. Where tenant listing / auto-select belongs

- **Listing source:** tenant enumeration must come from the **core read model**, tenant-scoped,
  respecting `Mailglass.Tenancy.scope/2` — NOT a new admin-side query that bypasses tenancy. The
  operator LiveView already calls `Mailglass.Operator.{Deliveries, Suppressions, ...}`
  (`operator_live.ex:14`); a `list_tenants/0` (or equivalent distinct-tenant projection) belongs
  in that core operator read-model namespace, surfaced to the admin the same way deliveries are.
  Admin code stays a thin consumer; it must not issue raw Repo queries (host-app-friendliness, §5).
- **Auto-select-sole-tenant:** belongs in `OperatorLive.handle_params/3` (and `InboundLive`) at
  the no-tenant branch: when the listing returns exactly one tenant and no `tenant_id` param is
  present, `push_patch` to that tenant instead of rendering the dead-end. This kills both the
  dead-end AND the pointless picker in the common single-tenant case.
- **The picker UI** is a new app-shell primitive (a tenant select in the shell header, next to
  `tenant_chip`), rendered only when listing returns ≥2 tenants. It writes `?tenant_id=` (the
  existing param contract) so all downstream scoping is unchanged.
- **Tenancy boundary:** the listing/auto-select must never let an operator see a tenant they're
  not authorized for. The `Operator.Mount` auth hook (`operator/mount.ex`) already establishes
  `operator_actor`; tenant listing must be scoped through the same actor/auth context, not global.

---

## 5. HOST-APP-FRIENDLINESS — theme system + component-lab without hijacking the host

`mailglass_admin` is a **mountable library**, so every new system must respect these existing
isolation seams (all verified in `router.ex`):

| Host resource | Existing isolation | v1.13 must preserve |
|---------------|--------------------|--------------------|
| **Auth** | Adopter-owned `MailglassAdmin.Auth` impl via `:auth` opt; `Operator.Mount` calls it; never library-owned | tenant listing/auto-select scoped through the adopter actor, not a global query |
| **Session/cookies** | `__operator_session__/2` / `__preview_session__/2` whitelist explicit keys; `_conn` underscore-bound to fail-compile on pass-through | theme + tenant state stays in URL params (existing pattern), not new cookie reads |
| **Assets** | Self-served via `Controllers.Assets` at `/css-:md5`, `/js-:md5`; one committed bundle; no host asset pipeline touched; zero Node | new tokens compile into the same bundle; rebuild + commit; do not emit a global `<style>` |
| **Repo** | Admin calls **core read-model modules** (`Mailglass.Operator.*`), never the host Repo directly | tenant `list_tenants` lives in core, scoped via `Mailglass.Tenancy.scope/2` |
| **CSS/JS collisions** | daisyUI themes scoped to `data-theme="mailglass-*"`; component classes are daisyUI/Tailwind utilities inlined into the md5 bundle, not global resets | system-theme must not add an un-scoped global `@media` that restyles host pages |
| **LiveView session names** | `:live_session_name` opt lets adopters rename to avoid collisions | unchanged |

### System-theme without global hijack

Today the theme is a **binary** `dark_chrome?` boolean keyed on `?theme=dark`
(`shell.ex:60`, `operator_live.ex:84`), with daisyUI `prefersdark: true` on the dark block giving
OS-default behavior at the **CSS** level (DARK-LD-08). There is **no explicit "system" option** —
PROJECT.md wants full {system, light, dark} with **system as default**.

Design (host-safe):
- Theme state becomes a tri-value (`:system | :light | :dark`) carried in `?theme=` (default
  `:system` = omit the param). At `:system`, **do not** set an explicit `data-theme` on the root
  `<html>` — let daisyUI's `prefersdark: true` resolve via `prefers-color-scheme` at the CSS
  layer (exactly DARK-LD-08's locked rule: "do not unconditionally assign at mount; defer to the
  daisyUI `prefersdark` CSS behavior"). Only `:light`/`:dark` set `data-theme` explicitly.
- This requires **no client JS hook** (CSS+LiveView.JS only — the hard constraint) and **no global
  CSS** outside the `data-theme="mailglass-*"` scope, so the host page is never restyled.
- The picker becomes a 3-way control (replaces the 2-way `theme_toggle`, `shell.ex:258`).

The component-lab is already host-safe: it's dev-only inside the preview `live_session`, no DB,
no auth, gated by the adopter's `if dev_routes`.

---

## 6. FRACTAL BUILD ORDER → phases

Dependency-ordered. The hard rule (v1.11 lesson) threads through: **tighten the relevant gate
inside each phase BEFORE its re-baseline/re-score**, and re-score the whole matrix only at the end.

```
Foundations/tokens   → Primitives → Forms → App-shell → Data-display
        │                                        │            │
        └─ ratchet-tighten (gates first) ────────┴────────────┴── Component-groups
                                                                        │
                                                          Pages/flows → Fixtures + ratchet-arm
```

**Phase A — Foundations + gate-tightening (do FIRST, no uplift yet).**
Semantic-token completeness: color/surface/elevation, formal **z-index layer system**, focus
rings, overlays, type scale, spacing, radius, shadows, borders, icons, **motion tokens** — in
light/dark/system, zero one-off values. Simultaneously **tighten the gates** (TYPE-GATE→text-xl,
new Z-INDEX/FOCUS-RING gates, system theme added to `ratchet_baseline_test.exs` schema v3, WCAG
2.2 SC added to structural spec) and prove them green on *current* code. Re-baseline tokens but do
NOT re-score pillars yet. **Depends on:** merge PR #86 first (held tenant/theme fixes).

**Phase B — Primitives (shared atoms).**
Promote the gallery-inlined `nav_link/nav_pill/tenant_chip/theme_toggle` to public components
(kills the copy-drift). Audit every primitive in every state (hover/focus/active/pressed/disabled/
loading/selected/error/empty/long-content) per WCAG 2.2 AA + WAI-ARIA APG, 320→wide. Build the
3-way system/light/dark picker primitive. **Depends on:** A (tokens + gates).

**Phase C — Forms (form-control audit).**
Unify the two `filters_form.ex` into shared `filter_field`/`filter_section` primitives; every
input state; error/disabled coverage. **Depends on:** B.

**Phase D — App-shell, navigation, tenant seam.**
Shell consistency; nav L1/L2 discipline; **tenant listing + auto-select-sole-tenant** (the §4
seam — core `list_tenants` scoped via `Mailglass.Tenancy.scope/2`, picker in shell, auto-select
in `handle_params`); honest pagination affordances; theme picker wired through the mount hook.
**Depends on:** B (picker primitive), C, and the core read-model listing.

**Phase E — Data-display.**
Tables-vs-cards discipline; one canonical `stat_card` (kills the operator/inbound divergence);
timelines; empty/error/permission/stale states; squished-column / clipped-label fixes.
**Depends on:** B.

**Phase F — Component groups (meta-components).**
Coherent spacing/hierarchy across composed groups (support-cards triage, routing-trace +
evidence, detail+timeline). **Depends on:** B–E.

**Phase G — Pages/flows.**
GOV.UK-style IA, principle of least surprise, per-persona/JTBD happy/error/boundary/edge/advanced
paths across all 3 surfaces in light/dark/system at every width; micro-animation + microcopy
passes. **Depends on:** A–F.

**Phase H — Fixtures + ratchet-arm (LAST).**
Land the 2–3-persona stress cohort in `reference/demo_app` seeds + gallery stress specimens; run
the **full** widened matrix (component × state × {light,dark,system} × {320..wide}); **then**
promote `current` → `prior` and re-score (the tighten-then-rebaseline ordering means gates are
already armed against the new floor). Verify all gates green; stage the release (PROJECT.md:
actually cut at close — admin-minor drags core+inbound, D-13 inbound exact-pin re-pin).

---

## 7. Integration Points (summary table for the roadmap)

| Surface to touch | File(s) | New vs Modified |
|------------------|---------|-----------------|
| Token foundations + z-index/motion tokens | `assets/css/app.css`, `brandbook/tokens.css` (read-only SoT — admin maps only) | Modified (admin `@theme` only) |
| Gate: schema v3 + system theme | `test/mailglass_admin/ratchet_baseline_test.exs`, `docs/ui-baseline-scores.json` | Modified |
| Gate: TYPE/Z-INDEX/FOCUS | `scripts/check-conformance.sh` | Modified |
| Gate: WCAG 2.2 + system + viewports | `e2e/structural.spec.js` | Modified |
| Promote inlined atoms | `components.ex` (new public fns), `operator/shell.ex`, `gallery_live.ex` | New + Modified |
| 3-way theme picker | new `theme_picker` primitive; `operator/shell.ex:258`; mount hook | New + Modified |
| Tenant listing | core `Mailglass.Operator.*` (`list_tenants` scoped via `Tenancy.scope/2`) | New (core read-model) |
| Tenant auto-select | `operator_live.ex:74` / `inbound_live.ex` `handle_params` | Modified |
| Component lab widening | `gallery_live.ex` (viewport param, system wrapper, state/long-content specimens) | Modified |
| Persona cohort | `reference/demo_app/priv/repo/seeds.exs`, `demo_data.ex` | Modified |
| Shared forms/cards/headers/timelines | `operator/*` + `inbound/*` pairs → shared primitives | New + Modified |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| admin LiveView ↔ core | direct module calls to `Mailglass.Operator.*` read model | tenant listing must join here, not a new Repo path |
| admin ↔ inbound | compile-gated route + `OptionalDeps.MailglassInbound.available?/0` | order-sensitive (router.ex:270); preserve |
| gallery ↔ components | render the **same** public fns (not copies) | the key fix B delivers |
| shell ↔ surfaces | `surface_paths/3` carries `tenant_id` + `theme` | already fixed in PR #86 — merge first |

## 8. Anti-Patterns (v1.13-specific)

- **Re-scoring before tightening gates.** The v1.11 trap: the higher score becomes the floor and
  the looser gate can never be re-armed. Always tighten → prove green → re-baseline.
- **Pixel-diff regression.** Banned. Use the runtime `getComputedStyle` contrast/grid/touch
  assertions that already exist — they are robust to font rendering and theme.
- **Gallery rendering copies.** A component lab that re-inlines `shell.ex` HEEx certifies the
  copy, not the shipped component. Promote to public fns first.
- **Tenant listing via raw Repo.** Hijacks the host Repo and bypasses `Tenancy.scope/2`. Route
  through the core operator read model with the authenticated actor.
- **Global `@media`/`<style>` for system theme.** Restyles host pages. Scope everything to
  `data-theme="mailglass-*"` and defer system to daisyUI `prefersdark` (DARK-LD-08).
- **A standalone "No tenant selected" gate on single-tenant installs.** Auto-select the sole
  tenant instead.

## Sources

- `mailglass_admin/lib/**` (read: `components.ex`, `gallery_live.ex`, `router.ex`,
  `operator/mount.ex`, `operator_live.ex`, `operator/shell.ex`, `layouts.ex` greps)
- `mailglass_admin/assets/css/app.css` (token layer, themes, `@theme`)
- `mailglass_admin/docs/ui-baseline-scores.json` + `test/mailglass_admin/ratchet_baseline_test.exs`
- `mailglass_admin/scripts/check-conformance.sh`, `scripts/check_motion_conformance.sh`
- `mailglass_admin/e2e/structural.spec.js`, `e2e/operator.spec.js`
- `reference/demo_app/priv/repo/seeds.exs`, `lib/mailglass_demo/demo_data.ex`, mailers, `page_controller.ex`
- commit `92866236` (tenant-scope/theme/stat-card fix), branch `fix/admin-preview-mount-aware-urls`/PR #86
- `.planning/PROJECT.md` (v1.13 scope), `.planning/research/v1.11/SUMMARY.md` (LOCKED DECISIONS, axis ownership, ratchet design)

---
*Architecture research for: mailglass_admin v1.13 design-system stress-test (integration + build order)*
*Researched: 2026-06-18*
