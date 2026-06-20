# Phase 115: Pages/Flows + Micro-Animation + Microcopy - Context

**Gathered:** 2026-06-20 (assumptions mode + 4-area parallel advisor research)
**Status:** Ready for planning

<domain>
## Phase Boundary

The **top of the v1.13 fractal stack**: whole-surface information architecture and lived
flows sitting on top of every already-fixed primitive (110), form (111), app-shell/tenant
seam (112), data-display (113), and component group (114). Four threads, all **delta passes**
over the v1.11 locked work (IA-LD-01..09, COPY-LD-01..16, MOTION-LD-01..14 shipped in phases
100–102) — NOT a redesign:

1. **FLOW-01** — GOV.UK-style IA per surface (top operator action obvious; novice→expert onboarding).
2. **FLOW-02** — every happy/error/boundary/edge/advanced path works in **light/dark/system** at
   **320→wide** (system is the new 3rd theme axis; 320 is the new floor — v1.11 stopped at 390).
3. **FLOW-03** — micro-animation pass (origin-aware overlays, theme-switch never animates,
   reduced-motion snaps, transform/opacity only) **WITHIN** the MOTION-LD locks.
4. **FLOW-04** — microcopy pass over the **new permission/stale/tenant** surfaces.

The three live surfaces are the entire scope: **Operator** (`/ops/mail`), **Inbound**
(`/ops/mail/inbound`), **Preview** (`/dev/mail`). No new routes, no new product capability.

**Hard out (Phase 116 owns):** the multi-tenant stress-fixture cohort, the full
component×state×theme×viewport gallery matrix, the axe-JSON baseline, the interaction-pillar
ratchet, and the `current → prior` re-score / baseline promotion. Phase 115 proves **flows**,
not the gallery, and must not pull these forward.
</domain>

<decisions>
## Implementation Decisions

### Area A — IA & Flow Proof (FLOW-01 / FLOW-02)

- **D-01:** GOV.UK-style IA is **~85% already built and locked** (IA-LD-01..09: master-detail split,
  orientation strips, `aria-current` nav, empty-state taxonomy, honest pagination, `<details>`
  preview hierarchy). Phase 115 is a **verification checklist + thin gap-fill, not a redesign.**
  Net-new is only: confirm the single obvious top action per surface survives 320px in all three
  themes, and that the orientation/empty/actionable states render the *recovery* path at 320. Do
  NOT re-architect IA or add user modes (the orientation-strip + empty-state-with-action pattern
  already threads novice↔expert — wizard-walls for experts and blank-canvas for novices are both
  footguns).

- **D-02:** Prove flows with **ONE new `e2e/flows.spec.js`** that walks the 5-path taxonomy
  (happy / error / boundary / edge / advanced) per surface **by seeded URL**, reusing the existing
  helpers (`openOperator`/`openInbound`/`openPreview*`, `assertNoElementHorizontalOverflow`,
  `assertPanelAboveScrim`, `assertTextContrastAA`). **Zero new fixtures** in 115 (the stress cohort
  is Phase 116's keystone) — flow-proof against what is already seeded. The 5 paths per surface are
  enumerated in `<specifics>` below.

- **D-03:** **Bounded matrix, deterministic, no pixel-diff ever.** 115 asserts: (a) **full walk** =
  3 surfaces × 5 paths × **{320px}** × **{system}** (≈15 flow tests), each asserting correct
  landmark/testid visible + no horizontal overflow on root & master-detail + the single-`h1`
  invariant; (b) **overlay interaction subset** = operator + inbound replay modal × {320} →
  panel-above-scrim + Escape-closes + background `scrollY` unchanged (scroll-chaining guard); (c)
  **theme-parity spot-check** = 1 happy + 1 overlay path × {light, dark, system} × {320} → contrast
  AA. Assertions only: `getComputedStyle`, `boundingBox`, `scrollWidth−clientWidth≤1`,
  `elementFromPoint` hit-test, `data-theme` attr, `getAnimations()`. **Never `toHaveScreenshot`.**

- **D-04:** **Phase 115/116 boundary (explicit):** 115 may **lower the 390→320 floor in the
  responsive tests it touches** and patch the overflow points that surfaces, but it must **NOT
  promote the 320 cell into the permanent ratchet baseline** — tighten-then-rebaseline and the
  `current → prior` re-score are Phase 116's job (re-baselining early erodes the floor — the
  v1.11 trap). The 320px fixes are mobile-first patches to the existing layout, **no new layout
  system**: header flex-wrap cluster (tenant-chip + theme-picker + nav-pills), `mono` ID cells
  (`min-w-0 truncate` + `title`), `overscroll-behavior: contain` on the modal scroll container,
  modal-above-scrim via the Phase-109 z-tokens, ≥44px targets re-asserted at 320.

### Area B — Permission / Stale / Tenant State Scope (FLOW-02 / FLOW-04)

- **D-05:** `:permission_denied` and `:stale` `data_state` kinds get a **design-system + microcopy
  pass ONLY — no live in-page triggers wired in Phase 115.** Rationale (research-converged): both
  require *product capability* this phase must not fabricate. **Permission-denied** is
  architecturally a **redirect-on-deny `on_mount` concern** (`operator/mount.ex` ~52-62 is the real
  permission path), not an in-page master-detail state — an in-page "you can't see *this tenant*"
  panel risks leaking forbidden-resource existence (403-vs-404 security lesson). **Stale** is
  meaningless without a live-data freshness signal (`as of HH:MM` + refresh) that does not exist
  yet; a stale banner *without* a real timestamp is worse than none (SRE footgun). Prove these two
  states **render** correctly via Floki/component tests + the existing dev-gallery entries + the
  URL state-probe mechanism (assert `data-state-*` testid, icon, color per kind). Hand the live
  triggers to Phase 116 / product.

- **D-06:** The **tenant surfaces ARE live** (Phase 112 shipped the selector) and get a full
  microcopy + voice-test pass against the running LiveView: no-tenants-exist, sole-tenant
  (auto-selected, **no picker rendered**), and the ≥2-tenant switcher. These close the v1.13
  "No tenant selected" dead-end and "pointless single-tenant picker" — keep the three failure modes
  (no tenant chosen ≠ no access ≠ no tenants exist) **lexically distinct**, each with its own
  template + testid.

### Area C — Micro-Animation within MOTION-LD locks (FLOW-03)

- **D-07:** **Origin-aware overlays** via CSS custom property: `.motion-overlay` gets
  `transform-origin: var(--mg-origin, center)`, and the **trigger declares the origin at author
  time** with an inline `style="--mg-origin: top right"` in HEEx. This is Radix's
  `--radix-*-transform-origin` pattern reduced to its zero-JS core — it only re-parameterizes the
  existing `scale(0.98→1)`, adding **no new animated property** (stays MOTION-LD-04/10 compliant).
  **No `getBoundingClientRect`, no `phx-hook`** (zero-hook lock). Origin is a **fixed intentional
  keyword by surface role, never computed**: header-anchored overlay = `top` (or `top right`);
  **centered confirm modals (`operator/replay_modal.ex`, `inbound/replay_modal.ex`, both
  `mx-auto max-w-2xl`) keep the default `center`** (omit the var); toast = `top right`.

- **D-08:** **Theme-switch-never-animates** via **inverted default**: bulk theme-driven color/border
  transitions are **OFF by default**, and only **state layers** (`:hover`/`:focus`) opt into a
  `transition-colors` at the fast token (≤100ms, MOTION-LD-06). Concretely, drop the always-on
  `transition-colors` from the theme-picker label (`components.ex` ~337) and never declare
  `transition-colors` on `data-theme`-driven chrome. Rationale: the LiveView theme swap re-renders
  the root subtree server-side, so the next-themes "inject `*{transition:none}` + force reflow"
  trick is **unavailable** (it needs JS `getComputedStyle`); inverting the default achieves the
  same flash-free result in pure CSS with no reflow dependency. (Reduced-motion already neutralizes
  everything via the existing `@media (prefers-reduced-motion: reduce)` block — no extra rule
  needed for the origin var.)

- **D-09:** **Conformance for both, deterministic, no pixel-diff.** Extend `check-conformance.sh`
  MOTION-GATE (~364-393): **positive** — `.motion-overlay` must declare `transform-origin: var(--mg-origin`;
  **negative** — no `transition-colors` on the theme-picker label / `data-theme` root chrome.
  Extend `structural.spec.js` motion block (~1208): assert `getComputedStyle(el).transformOrigin`
  resolves to center for centered modals and to the top edge for header-anchored overlays; assert
  the theme label's `transitionProperty` excludes `color`/`background-color`; toggle `data-theme`
  via `page.evaluate` and assert `getAnimations()` on the root subtree is empty immediately after
  the swap; assert a `:hover` state layer still reports `transitionDuration ≤ 0.1s` (state layers
  survive).

### Area D — Microcopy + Ban Coverage (FLOW-04)

- **D-10:** All new permission/stale/tenant copy **extends the locked COPY-LD-07 cause-naming
  pattern** (`[Noun] [past-tense verb]: [specific cause]` or names the recovery), the
  thoughtful-maintainer voice, and the seven domain nouns. The **verbatim strings are locked in
  `<specifics>` below** (ready to drop in). Permission-denied copy is **byte-identical regardless of
  whether the resource exists** and never names the missing permission or a specific tenant (no
  existence leak). The **stale copy *shape* is locked** (`Data may be out of date` / `Showing {Noun}s
  as of {HH:MM}. Refresh to load the latest.` + a Refresh affordance) but, per D-05, it is exercised
  only in the gallery/component test with an illustrative timestamp — the live trigger + real
  `{HH:MM}`/refresh wiring is deferred to Phase 116/product.

- **D-11:** Fix the one generic offender — the deliveries load-error body
  ("There was a problem loading deliveries", `deliveries_list.ex` ~53-54) — to the cause-naming
  recovery form: **"Delivery data could not be loaded. Refresh the page or adjust the filters, then
  try again."** (Avoids the GOV.UK-banned "something went wrong" register.)

- **D-12:** **Ban verification = rendered-HTML voice test + a narrowly-scoped source grep:**
  (a) extend `voice_test.exs` with `render_component`/LiveView-nav cases that force each new state
  (`data_state` `:permission_denied`/`:stale`; tenant 0/1/≥2 mounts) and assert both the
  `@banned_words` loop over `strip_scripts(html)` **and** the locked verbatim strings are present;
  the sole-tenant case asserts the picker testid is **absent** (proves auto-select). (b) Add a
  `check-conformance.sh` **VOICE-GATE** grep over **`*.ex` only** banning the "Oops"-class phrases
  (`Oops`/`Whoops`/`Uh oh`/`Something went wrong`) — scoping to `.ex` sidesteps the `phoenix.mjs`
  inlined-"noops" false-positive entirely (that token lives in a JS asset, never an `.ex` file).
  **Do NOT** grep standalone `Email`/`Status`/`Notification` — `Status` is a legitimate `<th>`
  column header (`deliveries_list.ex` ~106); enforce those domain-noun rules as **positive** render
  assertions, never a ban grep (a blanket ban goes permanently false-red).

### Scope

- **D-13:** Phase 115 touches exactly: `e2e/flows.spec.js` (new) + the responsive tests it lowers to
  320 in `structural.spec.js`; `assets/css/app.css` (`.motion-overlay` origin var, state-layer
  transition scoping, the committed CSS bundle if a utility is added); `components.ex` (theme-picker
  transition removal; data_state copy polish); the three surface live views + shell (320 overflow
  patches, inline `--mg-origin` on overlay triggers, microcopy); `operator/deliveries_list.ex` &
  `inbound/records_list.ex` (permission/stale/error copy); `operator/replay_modal.ex` &
  `inbound/replay_modal.ex` (origin keyword, overscroll-contain); `voice_test.exs` (new state
  cases); `check-conformance.sh` (VOICE-GATE + MOTION-GATE additions). It does **NOT** add routes,
  wire live `:permission_denied`/`:stale` triggers, add fixtures, touch the gallery matrix/axe
  baseline/re-score (Phase 116), or touch `brandbook/` tokens or recipient-facing email templates.

### Claude's Discretion

- Exact `flows.spec.js` test names/structure and whether login helpers are shared or duplicated
  (match the current per-file convention — no shared module exists today).
- Exact `--mg-origin` keyword chosen per overlay surface, provided centered modals stay `center` and
  the value is a fixed author-time keyword (never computed).
- Exact VOICE-GATE / MOTION-GATE regex and the state-layer transition utility name, provided the
  `.ex`-only scope and the no-standalone-noun-ban rule (D-12) hold.
- Exact illustrative `{HH:MM}` value used in the stale gallery/component specimen.

### Folded Todos

None — `todo.match-phase 115` returned one docs todo at score 0.2 (below the 0.4 fold threshold);
reviewed, not folded (see Deferred).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` — Phase 115 goal + success criteria; the 109→117 execution order; the
  Phase 116 ratchet/baseline boundary.
- `.planning/REQUIREMENTS.md` — FLOW-01..04 acceptance text and v1.13 scope locks.
- `.planning/PROJECT.md` — v1.13 intent, D-09 tenant isolation, D-13/D-23/D-28/D-29, scope locks.
- `.planning/STATE.md` — current milestone state; carried decisions from phases 109–114.
- `.planning/METHODOLOGY.md` — decisive-by-default, recommendation-first posture.
- `.planning/research/v1.11/MOTION.md` — **MOTION-LD-01..14** (binding motion locks: ease-out only,
  ≤300ms, transform/opacity only +color at fast token, phx-mounted entrances, exit ratio,
  reduced-motion, keyboard-repeatable exclusion).
- `.planning/research/v1.11/MICROCOPY.md` — **COPY-LD-01..16** (cause-naming pattern, seven nouns,
  "Oops"/"Email"/"Status"/"Notification" bans, thoughtful-maintainer voice).
- `.planning/research/v1.11/IA.md` — **IA-LD-01..09** (master-detail responsive split, orientation
  placement, honest pagination, empty-state taxonomy, preview `<details>` hierarchy).
- `.planning/research/v1.13/SUMMARY.md`, `FEATURES.md`, `PITFALLS.md`, `ARCHITECTURE.md` — the
  new permission/stale/tenant surfaces, the "lab-passes-but-ugly" gap, the 24 usability defects,
  the gallery/ratchet boundary.
- `.planning/phases/112-app-shell-navigation-tenant-seam/112-CONTEXT.md` — tenant selector/scope,
  theme picker, nav, pagination decisions (the live tenant surfaces this phase polishes).
- `.planning/phases/113-data-display/113-CONTEXT.md` — `data_state/1` four-state templates,
  long-value handling, the locked verification substrate (ExUnit + Playwright structural + grep +
  committed CSS, no-pixel-diff/zero-Node).
- `.planning/phases/114-component-groups/114-CONTEXT.md` — `<.card>` shell, SPACE-GATE, Floki depth
  proof, scoped Playwright geometry; the composed-group gallery specimens.
- `guides/jobs.md`, `.planning/research/JTBD-COVERAGE.md` — JTBD/personas (P1 Evaluator,
  P2 Integrator, P3 Maintainer, P4 Operator/SRE, P5 Security reviewer) and user flows.
- `brandbook/brand-book.md` — **CURRENT** brand SoT: thoughtful-maintainer voice + "say this not
  that", "clarity through panes" motion metaphor (arrive by becoming visible + settle a few px,
  never slide/bounce), no glassmorphism/bevels, mobile-first responsive admin.
- `prompts/mailer-domain-language-deep-research.md` — seven domain nouns; banned standalone words.
- `prompts/phoenix-live-view-best-practices-deep-research.md` — function-component / LiveView.JS
  idiom (note: if any `prompts/` file cites an OLD brand book, `brandbook/` overrides it).
- `mailglass_admin/lib/mailglass_admin/components.ex` — `data_state/1` (~410-464, kinds incl.
  orphaned `:permission_denied`/`:stale`); theme picker (~337, transition removal); no-tenant (~306).
- `mailglass_admin/lib/mailglass_admin/operator/mount.ex` — the **real** permission path
  (redirect-on-deny `on_mount`, ~52-62).
- `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex` — state branches (~49-99);
  generic error string to fix (~53-54); `Status` `<th>` (~106, the false-red risk).
- `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex` — inbound permission/stale copy
  (~59-71).
- `mailglass_admin/lib/mailglass_admin/operator/shell.ex` — IA/orientation strip (~309-420), header
  flex cluster (~243), `data-theme` swap (~210), tenant selector copy (~315-356).
- `mailglass_admin/lib/mailglass_admin/operator_live.ex`, `inbound_live.ex`, `preview_live.ex` —
  surface composition + modal opens (`inbound_live.ex` ~239).
- `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex`,
  `mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex` — centered confirm modals
  (default `center` origin; add `overscroll-behavior: contain`).
- `mailglass_admin/assets/css/app.css` — `.motion-overlay` keyframe (~312-335), reduced-motion
  block (~392-400), duration/ease tokens; focus-ring (~260).
- `mailglass_admin/scripts/check-conformance.sh` — MOTION-GATE (~364-393), PHASE112-SHELL-GATE
  (~302-329, where VOICE-GATE belongs).
- `mailglass_admin/test/mailglass_admin/voice_test.exs` — `@banned_words` (~25), `strip_scripts`
  (~183), surface coverage (~91-157), the `phoenix.mjs` "noops" false-positive note (~32-35).
- `mailglass_admin/e2e/structural.spec.js` — viewports (~19-23), responsive surface tests
  (~837-919, the 390 floor to lower), state-by-URL probes (~812-835), motion tests (~1208-1268),
  geometry/contrast helpers (~271-569).
- `mailglass_admin/e2e/operator.spec.js` — viewport calls (~74, 316).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- IA primitives already shipped and verified (v1.11): orientation strips, master-detail split,
  `aria-current` nav, honest pagination, `<details>` preview hierarchy, the four `data_state` kinds.
- Responsive substrate already present: `min-w-0`, `truncate`, `md:grid-cols-[40%_60%]`,
  row-to-card `max-md:hidden`, `mg-layer-overlay-scrim`, ≥44px target utilities.
- Verification substrate fully present: Playwright helpers (`assertNoElementHorizontalOverflow`,
  `assertPanelAboveScrim`, `assertTextContrastAA`, `openOperator/Inbound/Preview*`), `PRIMITIVE_VIEWPORTS`,
  the URL state-probe mechanism, the conformance grep-gate idiom, `voice_test.exs` rendered-HTML loop.
- `.motion-overlay` keyframe + reduced-motion neutralizer + duration/ease tokens already exist —
  origin-awareness is a one-line `transform-origin` parameterization, not new motion.

### Established Patterns

- All `mailglass_admin` UI is stateless `Phoenix.Component` function components (zero LiveComponents);
  the gallery can render any component from static assigns.
- Permission is gated at `on_mount` (redirect-on-deny), not as an in-page state.
- Verification is structural/deterministic: ExUnit (Floki/component/live) + Playwright
  structural/geometry/contrast + grep gates + committed CSS cleanliness — **no pixel-diff, zero-Node,
  zero client JS hooks.**
- Theme is `data-theme` on root + daisyUI `prefersdark` (system); theme swap is a server re-render.

### Integration Points

- The three live surfaces + shell compose the fixed primitives/groups; 115 patches their 320px
  overflow, inlines `--mg-origin` on overlay triggers, and polishes microcopy.
- `flows.spec.js` (new) drives the live surfaces by seeded URL — no new fixtures.
- VOICE-GATE/MOTION-GATE additions plug into the existing `check-conformance.sh` gate sequence.
</code_context>

<specifics>
## Specific Ideas

### Locked verbatim microcopy (extends COPY-LD-07; ready to drop in)

| Surface / state | Heading | Sub-copy | Recovery |
|---|---|---|---|
| permission_denied (deliveries) | `Access restricted` | `You do not have access to this tenant's mail operations. Ask an administrator to grant access.` | none (points to a human; no existence leak) |
| permission_denied (inbound) | `Access restricted` | `You do not have access to this tenant's inbound routing. Ask an administrator to grant access.` | none |
| stale (deliveries) | `Data may be out of date` | `Showing Deliveries as of {HH:MM}. Refresh to load the latest.` | `Refresh` (shape locked; live trigger deferred per D-05) |
| stale (inbound) | `Data may be out of date` | `Showing InboundMessages as of {HH:MM}. Refresh to load the latest.` | `Refresh` |
| no-tenant (none exist) | `No tenants available` | `This operator does not have a tenant with mail activity yet. Send a Message with a tenant_id, or check the host tenant scope.` | informational |
| sole-tenant (auto-selected) | *(no picker rendered)* | optional chip: `Scoped to {tenant}` | — |
| tenant-switcher (≥2) | `Select a tenant` | `Choose a tenant to inspect its Deliveries and inbound routing. Tenant scope stays in the URL so refreshes and shared links keep the same view.` | per-tenant `Select tenant` links (list, never free-text) |
| deliveries load error (fix) | `Delivery data unavailable` | `Delivery data could not be loaded. Refresh the page or adjust the filters, then try again.` | refresh / adjust filters |

### Flow-path taxonomy (per surface, for `flows.spec.js`)

| Surface | Happy | Error | Boundary | Edge | Advanced |
|---|---|---|---|---|---|
| Operator | select row → timeline | `delivery_id=does-not-exist` → detail error | no-results → empty + reset; no-tenant | long/non-ASCII tenant + ID truncate; high-count pagination | replay modal → above-scrim, Escape closes |
| Inbound | select no-match row → routing trace | failed-ingest record | empty window; no-match record | long mailbox/ID mono cells; evidence redacted→reveal | replay modal parity (role/aria/Escape) |
| Preview | select scenario → HTML tab renders | `BrokenMailer` → render error | no mailables → empty | many scenarios in `<details>`; frame theme ≠ admin theme | assigns-form override; device-frame width |

### Other locks

- Origin-aware overlay = `transform-origin: var(--mg-origin, center)`; trigger sets inline
  `style="--mg-origin: …"`; centered modals stay `center`; never computed (no hook).
- Theme-switch suppression = inverted default (theme color transitions OFF; state layers opt-in).
- Flow matrix bounded: full-walk at 320/system + overlay subset + light/dark/system spot-check;
  no pixel-diff; 320 floor lowered in touched tests but NOT promoted to baseline (Phase 116 owns that).
</specifics>

<deferred>
## Deferred Ideas

- **Live `:permission_denied` trigger** — the real recovery is the `on_mount` redirect; an in-page
  cross-tenant denial trigger is product capability + an existence-leak risk → Phase 116 / product.
- **Live `:stale` trigger + real `{HH:MM}` timestamp + working Refresh** — needs a data-freshness
  signal that doesn't exist yet → Phase 116 / product (copy *shape* is locked now).
- **Full component×state×theme×viewport gallery matrix, axe-JSON baseline, interaction-pillar
  ratchet, `current → prior` re-score, 320-cell baseline promotion** → Phase 116 (RATCHET-01..05).
- **Multi-tenant stress-fixture cohort** (long-ID/non-ASCII/high-count/null edge data) → Phase 116.

### Reviewed Todos (not folded)

- `doc-empty-parens-and-leftover-gsd-artifact-ids.md` (score 0.2, docs cleanup) — unrelated to
  FLOW-01..04; leave in the backlog.
</deferred>
</content>
</invoke>
