# Phase 109: Foundations + Gate-Tightening - Context

**Gathered:** 2026-06-18 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

First phase of milestone v1.13 (Admin Design-System Stress Test & UX Uplift). Scope:
the **token substrate** the whole milestone inherits is complete in light/dark/system with
zero one-off values; **system-theme plumbing exists at the CSS layer**; and the
**conformance/structural gates are tightened FIRST and proven green on current code** — all
on top of a **merged PR #86 baseline**.

**Hard scope line — NO pillar re-score this phase.** Tighten gates → prove green on current
code → re-baseline only the *token* layer. The full pillar re-score happens only in the final
ratchet-arm phase (116). This is the binding v1.11 anti-trap (PITFALLS B-C6: re-scoring before
tightening makes the higher score the floor and the looser gate can never be re-armed).

**Out of this phase (deferred to later v1.13 phases):** the 3-way system/light/dark *picker UI*
(Phase 110 primitive + Phase 112 shell wiring); the `@axe-core/playwright` JSON baseline and the
new npm devDependency (Phase 116); the multi-tenant stress-fixture cohort (Phase 116); any pillar
re-baseline; canonical `stat_card`, responsive tables, honest pagination, tenant seam.

Requirements: REL-01 (precondition), FND-01, FND-02, FND-03, FND-04, FND-05.
</domain>

<decisions>
## Implementation Decisions

### Token-Layer Structure (FND-01, FND-02, FND-03)

- **D-01:** Tokens are **mostly already present** — this is a *tokenize-the-stragglers-and-tighten*
  job, not build-from-scratch. The type scale (`--text-label/body/heading/display`), spacing
  (`--spacing-xs..3xl`), elevation (`--shadow-flat/raised/overlay`), and easing tokens live in the
  `@theme` block (`mailglass_admin/assets/css/app.css:107-144`); durations
  (`--duration-instant/fast/reveal/flash`), control sizes, and a z-index tier set live in `:root`
  (`app.css:192-223`). **Net-new semantic tokens go into these existing blocks — do not create a
  parallel token source** (that triggers an override war, e.g. two definitions of `--text-heading`).

- **D-02:** **Color stays only in the daisyUI theme blocks** (`mailglass-light` default /
  `mailglass-dark` `prefersdark`) per the existing TOKEN-01 rule documented at `app.css:99-106`.
  No new color literals anywhere outside those blocks.

- **D-03 (FND-01, stale-research correction):** **Z-index tokens already exist** at
  `app.css:216-223` (`--z-sticky:10 / --z-dropdown:20 / --z-overlay:30 / --z-modal:40 /
  --z-toast:50`) — the v1.13 research's "no z-index tokens in app.css" claim is **stale/wrong**.
  The real FND-01 defect is they are **unconsumed**: HEEx uses literal Tailwind `z-*` utilities.
  Fix = (a) introduce the formal named layer system **including a `--z-overlay-scrim` vs
  `--z-overlay-panel` split and a `--z-base`** (today scrim+panel share one `z-40` band); (b)
  replace the three literal `z-*` usages in HEEx — `operator/replay_modal.ex:20` (scrim `z-40`),
  `inbound/replay_modal.ex:24` (scrim `z-40`), `components.ex:104` (toast `z-50`) — with
  token-driven classes; (c) the modal **panel** (currently no explicit z, stacks by source order
  only — the literal modal-behind-scrim fragility) gets the explicit panel layer; (d) add
  `isolation: isolate` on the mount root for host-safe stacking.

- **D-04 (FND-02, focus-ring):** The focus ring is currently an **un-tokenized string copy-pasted
  ~14×** (`focus-visible:ring-2 focus-visible:ring-primary` across `shell.ex`, `tabs.ex`,
  `sidebar.ex`, `deliveries_list.ex`, `gallery_live.ex`, `preview_live.ex`) plus a **divergent**
  idiom (`focus:outline focus:outline-2 focus:outline-offset-2` at `preview_live.ex:385`).
  Consolidate to a **single focus-ring token/utility** and converge both idioms — and do this
  **before** the FOCUS-RING-GATE is added so the gate proves green on current code (FND-05).

- **D-05 (FND-02):** Motion, elevation, and overlay values are likewise defined as semantic tokens
  resolving correctly in light/dark/system. Reuse/extend existing `--duration-*`/easing/`--shadow-*`
  tokens; only add what's genuinely missing (e.g. overlay-scrim color/opacity token if inlined).

### Gate-Tightening Mechanics (FND-05)

- **D-06:** New gates are **additional grep blocks in the existing
  `mailglass_admin/scripts/check-conformance.sh`**, following the established 6-gate pattern
  (BADGE/TYPE/BOLD/GAP/HEX/MOTION): shared `errors` counter, `--include="*.ex"`, scoped to
  `${SCRIPT_DIR}/../lib` via the `BASH_SOURCE` anchoring (cwd-independent — preserves the WR-02
  footgun guard). Add: **Z-INDEX gate** (no literal `z-*` in admin `lib/`), **FOCUS-RING gate**
  (no raw inline focus-ring string), **SCOPE/isolation gate**. **TYPE-GATE is *extended*** (not
  replaced) to also match `text-xl|2xl|3xl`. Do NOT add gates to a new script or with different
  scoping — CI invokes the existing script.

- **D-07 (ratchet schema → v3):** In `mailglass_admin/test/mailglass_admin/ratchet_baseline_test.exs`:
  add `"system"` to the `@themes` attr (currently `["light","dark"]`, line ~28), bump the schema
  assertion `== 2` → `== 3` (line ~41), and update the derived cell-count math (3 surfaces × 6
  pillars × 3 themes). **Seed the new `system` cells in BOTH `prior` and `current` blocks** of
  `docs/ui-baseline-scores.json` (the comparator fails closed on `nil` cells), by **copying each
  surface's existing light-or-dark scores into the `system` slot** — system resolves to one of
  them — so **no cell regresses and no new pillar judgment is introduced this phase.** The real
  `system` re-score is deferred to Phase 116. (FND-05 says "ratchet schema bumped to include
  `system`" — the decisive reading is `system` as a 3rd theme axis, not viewport-structural-only.)

- **D-08 (WCAG 2.2 SC):** Add WCAG 2.2 success criteria as **additions to the existing structural
  matrix** in `mailglass_admin/e2e/structural.spec.js`, not a rewrite: an `elementFromPoint`
  **hit-test for opened overlays** (SC 2.4.11 / modal-above-scrim) is **net-new** (no
  `elementFromPoint`/`isolation`/`focus-not-obscured` assertion exists today); **target-size**
  (2.5.8, extend the existing `touch targets >= 44px` block ~`:286`) and **contrast** (1.4.11,
  extend `assertTextContrastAA`/`assertNonTextContrastAA` ~`:222/:232`) extend existing assertions.
  Add `emulateMedia({colorScheme})` for the system case (same shape as the existing
  `emulateMedia({reducedMotion})` at ~`:780`).

- **D-09 (FND-05 ordering — binding):** Every gate is tightened → **proven green on CURRENT code**
  → only then is the token layer re-baselined. No pillar re-score. If a gate would fail on current
  code, the underlying code is consolidated first (e.g. D-04 focus-ring before FOCUS-RING-GATE).

### System-Theme Plumbing (FND-04)

- **D-10:** The CSS-layer system-theme plumbing FND-04 requires is **already correct and in place**
  — `layouts/root.html.heex:2` emits `<html data-theme={root_theme(assigns)}>`; `layouts.ex:82-97`
  returns `mailglass-dark`/`mailglass-light` only for explicit `theme=dark|light` and `nil`
  otherwise, so `data-theme={nil}` emits **no attribute**, and daisyUI's `prefersdark: true` on the
  `mailglass-dark` block (`app.css:60-64`) resolves system via `prefers-color-scheme` — **no JS
  hook, no host-global CSS.** Phase 109 **proves and locks** this (a structural assertion + the
  SCOPE gate), it does **not** rebuild it. Do NOT add a `phx-hook` or a head script that
  force-sets `data-theme` for the system case (re-creates the DARK-LD-08 split-brain where OS
  changes stop tracking).

- **D-11 (scope hold):** The operator surface still carries a **2-state `dark_chrome?` boolean**
  (`?theme=dark` only, `operator/shell.ex`, `operator_live.ex`) that doesn't model `system`. Phase
  109 owns **only the token/CSS-layer system plumbing + the gate/structural proof** — it does NOT
  rebuild the toggle into a 3-way picker. The 3-way picker primitive is Phase 110; shell wiring is
  Phase 112. Hold this line to avoid pulling forward Phase 112's `surface_paths`/`build_path`
  plumbing that PR #86 just stabilized.

### REL-01 / PR #86 (precondition)

- **D-12:** REL-01 is satisfied by a **one-time admin-override merge of PR #86 into `main` BEFORE
  any Phase 109 code lands** — captured as the **first step of phase execution**, NOT done during
  discussion (user decision 2026-06-18). PR #86 (`fix/admin-preview-mount-aware-urls`) is verified
  OPEN, all 24 CI checks SUCCESS, `mergeable: MERGEABLE`, blocked **only** by review-required
  branch protection (`reviewDecision: ""`) — resolve with `gh pr merge 86 --admin` (the documented
  `enforce_admins:false` / `--admin` override). Foundation edits touch the same
  `shell.ex`/`layouts.ex`/`app.css`/`root.html.heex` regions #86 carries held fixes for, so merging
  first is mandatory to avoid conflicts and to honor the "build on the merged #86 baseline"
  precondition. Confirm main CI is green post-merge before the first uplift commit.

### Claude's Discretion
- Exact token names for the scrim/panel split and focus-ring (follow existing `--z-*`/`--text-*`
  naming convention in `app.css`).
- Whether the focus-ring becomes a CSS custom property + utility class or a Tailwind `@utility` —
  pick whichever the existing `app.css` structure makes cleanest.
- Exact placement of the new grep gates within `check-conformance.sh` (preserve the shared counter).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/research/v1.13/SUMMARY.md` — convergent HIGH-confidence synthesis; Phase A (=109)
  flagged "plan directly."
- `.planning/research/v1.13/ARCHITECTURE.md` — §1 token/CSS layer, §2 the 4-mechanism ratchet, §3
  gallery/ratchet extension (incl. §3a the `system`-as-theme vs viewport-structural cell-count note).
- `.planning/research/v1.13/PITFALLS.md` — Bucket C "lab-passes-but-ugly"; B-C6 re-score-before-
  tighten; the literal `z-40` / modal-behind-scrim / theme-FOUC entries.
- `.planning/research/v1.13/STACK.md` — zero-Node-asset vs Node-test distinction; the one test-only
  dep is **Phase 116, not 109**.
- `.planning/PROJECT.md` — v1.13 scope locks, D-23/D-28/D-29, the named bug list, merge-#86-then-ship.
- `.planning/REQUIREMENTS.md` — REL-01, FND-01..05 acceptance text.
- `.planning/ROADMAP.md` — Phase 109 goal + success criteria.
- Codebase grounding (read before editing): `mailglass_admin/assets/css/app.css`,
  `mailglass_admin/scripts/check-conformance.sh`,
  `mailglass_admin/test/mailglass_admin/ratchet_baseline_test.exs`,
  `mailglass_admin/docs/ui-baseline-scores.json`, `mailglass_admin/e2e/structural.spec.js`,
  `mailglass_admin/lib/.../operator/replay_modal.ex`, `.../inbound/replay_modal.ex`,
  `.../components.ex`, `.../operator/shell.ex`, `.../layouts.ex`, `.../layouts/root.html.heex`.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`app.css` token blocks** — `@theme` (`:107-144`: type/spacing/elevation/easing) and `:root`
  (`:192-223`: durations, control sizes, z-tiers `--z-sticky/dropdown/overlay/modal/toast`). The
  daisyUI theme blocks `mailglass-light` (default) and `mailglass-dark` (`prefersdark: true`,
  `:60-64`). Extend these — don't fork.
- **`scripts/check-conformance.sh`** — 6 working grep gates (BADGE/TYPE/BOLD/GAP/HEX/MOTION),
  shared `errors` counter, `BASH_SOURCE`-anchored `LIB` (cwd-independent), final `exit 1`. A
  `check-conformance-advisory.sh` twin exists for non-blocking probes.
- **`ratchet_baseline_test.exs`** — surfaces/pillars/themes as module attrs; 3×6×2=36 cells;
  `compare_baselines/2` fails closed on `nil`; anti-vacuity guard asserts `prior.run_id !=
  current.run_id`. `docs/ui-baseline-scores.json` has the two-block `prior`/`current` structure.
- **`structural.spec.js`** — existing `assertTextContrastAA`/`assertNonTextContrastAA` theme×viewport
  contrast matrix; `touch targets >= 44px` describe block; `emulateMedia({reducedMotion})` already
  in use. The seams to *extend* for WCAG 2.2.
- **Root layout theme plumbing** — `root.html.heex:2` + `layouts.ex:82-97` already implement the
  correct tri-state (`nil` data-theme = system via `prefersdark`). No JS theme hook anywhere.

### Established Patterns
- **TOKEN-01:** color lives once, only in the daisyUI theme blocks (`app.css:99-106`).
- **Tighten-then-rebaseline** (v1.11): gate first, prove green on current code, re-score last.
- **Zero-Node asset pipeline** for shipped CSS (committed `priv/static/app.css`); the **test**
  harness already uses Node/Playwright and never ships — but the axe dep is still Phase 116.
- **Host-safety seams:** no host-global CSS, no `phx-hook` for theme, `data-theme="mailglass-*"` +
  `isolation: isolate` for stacking isolation.

### Integration Points
- New gates plug into the CI lane that already calls `check-conformance.sh`.
- Ratchet schema v3 + new `system` JSON cells flow through `ratchet_baseline_test.exs`.
- Structural WCAG additions run in the existing Playwright `structural.spec.js` suite.
- Token edits land in `app.css` → recompiled committed `priv/static/app.css` (`git diff --exit-code`
  gate — rebuild + commit the bundle on any class change).
- PR #86 merge must precede all of the above on `main`.
</code_context>

<specifics>
## Specific Ideas

- **Stale-research correction worth carrying forward:** treat FND-01 as *consume existing z-tokens +
  split scrim/panel + add isolation*, not *create from scratch*. The `--z-*` tokens already exist;
  the bug is that HEEx ignores them.
- **Focus-ring must be consolidated before its gate** — otherwise FND-05's "green on current code"
  fails on the project's own ~14 inline copies.
- **`system` ratchet cells are seeded by copy, not scored** this phase — preserves "no pillar
  re-baseline."
</specifics>

<deferred>
## Deferred Ideas

- **3-way system/light/dark picker UI** — Phase 110 (primitive) + Phase 112 (shell wiring). Phase
  109 is CSS-layer plumbing + proof only.
- **`@axe-core/playwright` JSON baseline + the one test-only npm devDep** — Phase 116 (ratchet-arm).
- **Multi-tenant stress-fixture cohort** — Phase 116 (the keystone proving substrate).
- **Full pillar re-score** — Phase 116 only.
- **Operator `dark_chrome?` → tri-state reconciliation in the UI** — Phase 112.

### Reviewed Todos (not folded)
None — `todo.match-phase 109` returned 0 matches.
</deferred>
