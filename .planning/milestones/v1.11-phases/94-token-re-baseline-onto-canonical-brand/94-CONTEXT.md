# Phase 94: Token Re-Baseline onto Canonical Brand - Context

**Gathered:** 2026-06-13 (assumptions mode + research-driven synthesis)
**Status:** Ready for planning

<domain>
## Phase Boundary

Make `mailglass_admin/assets/css/app.css` consume the canonical `brandbook/tokens.css`
`--mg-*` two-tier token system as the single source of truth; correct the surface/border
role mapping (accent confined to the 10%-accent allowlist, not borders/cards) and the
dark-mode token values (muted text, error, primary-content) to pass WCAG AA on their
actual surfaces — all behind conformance/motion gates landed FIRST so the re-baseline
cannot regress silently. Rebuild + commit the standalone-binary CSS bundle bit-for-bit.

**In scope:** the CSS token/role layer of `mailglass_admin` (`app.css`), the parity +
contrast ExUnit tests, the grep-gate scripts + their CI wiring, and the rebuilt
`priv/static/app.css` bundle.

**Out of scope (locked by SC-4):** admin HEEx/component markup changes; editing
`brandbook/` itself (this phase *consumes* the brand book); the fractal component/page
uplift (Phases 97–103); the quality-ratchet baseline + GAP register + Playwright +
LLM-scoring apparatus (Phase 95, RATCHET-01/02/04).

Requirements: TOKEN-01, TOKEN-02, TOKEN-03, TOKEN-04, TOKEN-05, RATCHET-03.
</domain>

<decisions>
## Implementation Decisions

These were derived codebase-first (assumptions mode), then hardened by four parallel
research streams (token mechanism, parity test, gates, role/contrast). One empirical
spike **reversed** the initial vendor-copy assumption. One genuinely strategic fork
(gate-vs-markup sequencing) was escalated and resolved by the owner.

### Token consumption mechanism (TOKEN-01)
- **D-01:** `app.css` consumes the canonical tokens via a **direct cross-package
  `@import "../../../brandbook/tokens.css";`** (three levels up from `assets/css/`), and its
  daisyUI theme `--color-*` declarations are rewritten to reference `var(--mg-*)` — **no
  duplicate hex literals**. This is the literal single-source-of-truth: one physical token
  file, no vendored copy and no codegen.
  - **Empirically proven** (research spike, standalone Tailwind v4.1.12 binary, build cwd
    `mailglass_admin/`): the binary resolves the above-package-root `@import` cleanly and
    inlines all `--mg-*` declarations; daisyUI forwards `var(--mg-*)` references through
    verbatim into the compiled `[data-theme=…]` selectors. The full zero-hex pipeline
    compiles end-to-end.
  - **Why not vendor-copy / codegen:** `brandbook/` lives in *this same git repo* (not an
    external supply-chain artifact like daisyUI, which is correctly vendored in
    `assets/vendor/`). A copy manufactures a drift surface for zero benefit; codegen
    re-implements a token resolver that `tokens.css` already is. The `@import` only needs to
    resolve at **maintainer build time** — `mailglass_admin/mix.exs` `:files` excludes both
    `assets/` and `brandbook/` from the Hex tarball, so adopters only ever consume the
    pre-resolved `priv/static/app.css`.
  - **Drift detection is free:** editing `brandbook/tokens.css` without rebuilding makes the
    committed bundle stale → the existing `verify.preview` `git diff --exit-code priv/static/`
    gate goes red. No new infra needed for drift.
  - **Reverses** the earlier assumptions-mode "Likely: vendor-copy" call — the spike settled
    the one open empirical question decisively.

### Token-parity test (TOKEN-04)
- **D-02:** Add `mailglass_admin/test/mailglass_admin/token_parity_test.exs` — a
  **fail-closed, always-run** test that reads the **compiled** `priv/static/app.css`, and for
  each daisyUI `--color-*` slot resolves its `var(--mg-*)` indirection against the inlined
  `--mg-*` block, then compares to the oracle value. Reading the compiled artifact (not
  source `app.css`) is what closes the stale-bundle footgun.
  - **Oracle:** `brandbook/tokens.json` (W3C design-token format; de-alias `{palette.x}`
    refs via the `palette` map; Jason is already an admin test dep). Equivalent: parse
    `brandbook/tokens.css`. Pick one oracle — do not hardcode a third copy of the values.
  - **Plus a structural assertion** (makes TOKEN-01 executable): **no `#hex` may appear on a
    `--color-*` line inside a daisyUI theme selector** in the compiled bundle — only
    `var(--mg-*)` references are allowed there.
  - **Contract surface:** a single hand-maintained `@mapping` of `{theme, daisyui_var} =>
    {tier, mg_role}` lives in the test — this IS the slot→role contract; a token rename forces
    a deliberate edit here. Collect ALL mismatches before asserting (one-pass fix).
  - **Failure message** must name the oracle file and give the exact self-serve fix, branching
    the two causes: stale bundle → `cd mailglass_admin && mix mailglass_admin.assets.build &&
    git add priv/static/`; intentional brand change → edit `brandbook/tokens.{json,css}` then
    re-sync `app.css`; never hand-edit `priv/static/app.css`. Note "`actual` is what currently
    SHIPS." Matches the existing `bundle_test.exs`/`brand_test.exs` message style.
  - **CI placement:** add to the `verify.support_contract.admin` alias (a **required**
    branch-protection check). Pure file I/O + Jason — no Postgres/Node/Playwright; never
    tag-excluded. Keep an `@tag :token_parity` as a *convenience selector* only.
  - **Existing `brand_test.exs`:** its literal-hex assertions will go red on the (correct)
    var-rewrite — update them to assert (a) `var(--mg-*)` wiring in the theme selector and
    (b) the resolved hex in the `--mg-*` block. Its visual-DON'T blocks (`backdrop-filter`,
    `--depth:0`) stay untouched. Don't duplicate the `@mapping` across two files.
  - **No byte-identity test** (that half only applied to the rejected vendor-copy design).

### Surface/border role remap + dark-mode AA fixes (TOKEN-02, TOKEN-03)
- **D-03:** Rewrite the daisyUI slot → `--mg-*` role map for both themes (all values via
  `var(--mg-*)`; resulting hex shown for verification). Headline corrections:
  - Light `--color-base-200`: Mist `#EAF6FB` → **`--mg-color-surface-raised` `#FFFFFF`** (cards).
  - Light `--color-base-300`: Ice `#A6EAF2` → **`--mg-color-border` `#C7DCE5`** (the
    accent-as-border bug — every real use is a hairline/divider, confirmed safe).
  - Light `--color-base-100`: → **`--mg-color-background` `#F8FBFD`** (Paper) — keep it as
    *background*, not white, to preserve the page-vs-card elevation step (cards = white
    surface-raised). Map by value, not name.
  - Light `--color-accent`: Ink `#0D1B2A` → **`--mg-color-accent` (Glass `#277B96`)** (the
    Ink-as-accent value was a v1.7 codex-era artifact; daisyUI `accent` is barely used).
  - Dark `--color-error`: **off-palette `#D47368` → `--mg-color-error-solid` `#E29089`**
    (crimson-bright; the current value exists nowhere in the canonical palette).
  - Dark `--color-secondary` (the de-facto muted-text role, `text-secondary` ~110×): Slate
    `#5C6B7A` → **`--mg-color-text-muted` `#B8CAD4`** (current fails AA at **3.18:1** on Ink;
    fix ≈ 10:1).
  - Dark `--color-base-300`: `#1F3049` → **`--mg-color-border` `#315069`** (border role).
  - Dark `--color-primary-content` stays Ink `#0D1B2A` on Ice (already passes, 12.98:1).
  - The full per-slot table (incl. neutral/info/success/warning + `-content` slots) is in the
    research dossier — the planner should reproduce it from `brandbook/tokens.css`.
- **D-04:** **Prove contrast in-repo by extending the existing
  `mailglass_admin/test/mailglass_admin/accessibility_test.exs`** (reuse its validated WCAG
  `contrast_ratio/2`/`luminance/1` — do NOT add a second WCAG implementation or a
  hand-maintained markdown table that rots). Assert every CHANGED dark value clears **AA 4.5:1**
  on its actual surface(s) (muted `#B8CAD4`, error `#E29089`, primary-content), and the
  remapped light surfaces. Read the hex from `brandbook/tokens.css` (same source as the parity
  test) so there's no duplicate token oracle: parity test = *value* oracle, contrast test =
  *math* oracle.
  - **Border role is intentionally < 3:1** (`#C7DCE5` on Paper ≈ 1.37; `#315069` on Ink ≈
    2.06): the brand classifies `border` as decorative hairlines/dividers only — exempt from
    WCAG 1.4.11 (only *control boundaries* need 3:1, and those use `border-input`
    `#74909F`/`#62809A` via daisyUI's input-border var, independent of base-300). **Pin this
    intent with an explicit `< 3.0` assertion + docstring** so a future contributor can't
    "helpfully" darken it. This is the single most likely well-intentioned mistake.

### Conformance + motion gates, tightened & wired (RATCHET-03)
- **D-05:** **Extend the two existing shell scripts in place** (do NOT port to Credo). Class-
  string substring matching is exactly what these greps are for; AST buys nothing for HEEx
  class attributes, and in-place editing preserves the WR-01..04 false-positive fixes and the
  `--ease-in-out` two-pass split. Matches the project's established shell-gate precedent and the
  JS ecosystem's class-matcher norm (eslint-plugin-tailwindcss, stylelint). The 18 core Credo
  checks stay scoped to core domain semantics.
- **D-06:** **Wire the dead `check-conformance.sh` into CI** — it is currently referenced
  *nowhere* (confirmed); only `scripts/check_motion_conformance.sh` runs (in the
  `credo_strict` job, `ci.yml:399-402`). Add a `bash mailglass_admin/scripts/check-conformance.sh`
  step to the `credo_strict` job right after the motion step. The script self-anchors to
  `BASH_SOURCE` (cwd-independent, fail-loud) — run from repo root, no `working-directory:`.
  **Wiring the dead gate is the load-bearing part of RATCHET-03.**
- **D-07:** Gate-pattern additions, all scoped to `mailglass_admin/lib/**/*.ex` only (kept OFF
  `app.css`, which legitimately holds `letter-spacing: -0.02em` and `--ease-in-out`):
  - TYPE-GATE (`check-conformance.sh`): add `text-(lg|xl|2xl|3xl|4xl|5xl)\b` to the existing
    `\b` arm (keep `text-base` on its own `($|[^-])` arm so the `text-base-content` exclusion
    holds).
  - New TRACK-GATE (`check-conformance.sh`): ban arbitrary `tracking-\[` only — named
    `tracking-tight`/`tracking-wide` must still pass.
  - Motion `ease-in`: already covered by `check_motion_conformance.sh` Pass B (`ease-in[^-]`,
    excludes `ease-in-out`/`--ease-in-out`) — verify only, no change.
  - THRASH_PATTERN (`check_motion_conformance.sh`): add layout-property transitions
    `transition-(width|spacing|margin|inset|top|right|bottom|left)\b` plus an arbitrary
    `transition-\[(…layout props…)` arm. Keep allowing `transition-colors|transform|opacity|shadow`.
- **D-08 (escalated fork — owner decision):** **Advisory-now, hard-fail-at-99 sequencing.**
  The `text-lg/xl` (5×) and `tracking-[0.08em]` (~45×) escapes ALREADY live in `lib` markup,
  and fixing them is HEEx markup change — forbidden by SC-4 and roadmapped to Phases 98/99. So
  in Phase 94: wire the dead script + arm all **token-layer** gates (HEX/BOLD/GAP/BADGE/TYPE-
  base) **fail-closed now**; the new **typography/tracking** gate patterns are authored and
  **run in CI but advisory** (`continue-on-error` / warn) until the phase that cleans their
  markup (98/99) flips them to hard-fail. This honors SC-4 strictly, keeps `main` green, and
  keeps the *token re-baseline itself* fully protected. Trade-off accepted: typography is not
  merge-blocking until 99. The planner must record which patterns are hard vs advisory and add
  a flip-to-hard task to the Phase 99 plan.
  - **TRACK-GATE prerequisite for the eventual hard flip:** `brandbook/tokens.css` defines NO
    tracking/letter-spacing token. Before TRACK-GATE can be armed hard, a named token (e.g.
    `--tracking-eyebrow: 0.08em`) must be defined and the ~45 sites migrated — that markup work
    belongs in 98/99, not 94.

### Bundle rebuild + commit (TOKEN-05)
- **D-09:** After all `app.css` edits, rebuild via `mix mailglass_admin.assets.build` (runs
  `tailwind default --minify`) and **commit `priv/static/app.css`**. The `verify.preview` alias
  already enforces `git diff --exit-code priv/static/` (CLAUDE.md rule 6) — never hand-edit the
  generated bundle.

### Commit ordering (gates-first, every commit green)
- **D-10:** Land the gate/test infra BEFORE the token re-baseline so the re-baseline can't
  regress silently, each commit green:
  1. `ci(admin): wire + tighten design-system conformance gates` — extend both scripts (D-07),
     wire `check-conformance.sh` into `ci.yml` (D-06), typography/tracking patterns advisory
     (D-08). Run both scripts locally → exit 0. (No CSS, no markup.)
  2. `test(admin): add fail-closed token-parity test` (D-02) — green against current tree
     (structural half tolerant of today's hardcoded hex, or land alongside step 3 if the
     no-raw-hex assertion needs the var rewrite first; planner decides exact split).
  3. `feat(admin): re-baseline app.css onto brandbook tokens` (D-01, D-03) — add the `@import`,
     rewrite daisyUI `--color-*` to `var(--mg-*)`, fix role map + dark values; update
     `brand_test.exs` assertions; extend `accessibility_test.exs` contrast proof (D-04);
     rebuild + commit bundle (D-09).

### Claude's Discretion
- Exact regex shapes for the gate additions (validate by running the scripts + `mix test`,
  not by grep proofs — per the "validate credo by running it" convention, here applied to
  shell gates).
- Whether the parity-test oracle parses `tokens.json` vs `tokens.css` (either is fine; one only).
- Exact split of test commits in D-10 step 2/3 (whichever keeps each commit green).

### Folded Todos
- None folded into Phase 94. See Deferred.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` — Phase 94 goal + 4 success criteria; Phase 95/98/99 dependencies.
- `.planning/REQUIREMENTS.md` — TOKEN-01..05, RATCHET-03 (and RATCHET-01/02/04 for Phase 95 context).
- `brandbook/tokens.css` — **the single source of truth** for all `--mg-*` token values
  (light `:root`/`[data-theme=light]`, `[data-theme=dark]`, `prefers-color-scheme` media block).
- `brandbook/tokens.json` — W3C design-token format (palette tier + light/dark semantic tier
  with `{palette.x}` aliases); the parity-test oracle.
- `brandbook/brand-book.md` — accent-restraint (10%) rule, border = decorative hairlines only,
  dark-mode intent; `.planning/PROJECT.md` brand constraints C-15/C-16.
- `mailglass_admin/assets/css/app.css` — the only CSS edit target (daisyUI theme blocks + `@theme`).
- `mailglass_admin/scripts/check-conformance.sh` — 5-gate design-system script (DEAD; wire + extend).
- `scripts/check_motion_conformance.sh` — motion gate (wired; extend THRASH_PATTERN).
- `.github/workflows/ci.yml` — `credo_strict` job (~399-404, wire conformance step);
  `support_contract_admin` job (~576+, required lane for parity test).
- `mailglass_admin/test/mailglass_admin/brand_test.exs` — existing compiled-bundle assertions
  to update; model for the parity test.
- `mailglass_admin/test/mailglass_admin/accessibility_test.exs` — existing WCAG calculator to
  extend for the contrast proof.
- `mailglass_admin/test/mailglass_admin/bundle_test.exs` — message-style precedent for fail-closed gates.
- `mailglass_admin/mix.exs` — `verify.preview` (git-diff gate) + `verify.support_contract.admin`
  aliases; `:files` tarball whitelist; `jason` test dep.
- `mailglass_admin/config/config.exs` — `tailwind` build config (cwd, input/output).
- `mailglass_admin/lib/mix/tasks/mailglass_admin.assets.build.ex` — the bundle build task.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **WCAG calculator** in `accessibility_test.exs` (`contrast_ratio/2`, `luminance/1`) — validated
  against brandbook anchors; reuse for the contrast proof.
- **Compiled-bundle test seam** in `brand_test.exs` (reads `priv/static/app.css` via
  `Application.app_dir`) — extend into the parity test.
- **Self-anchoring shell gate** `check-conformance.sh` (BASH_SOURCE-anchored, fail-loud, 5 gates
  with WR-01..04 false-positive fixes) and `check_motion_conformance.sh` (two-pass `ease-in`
  handling) — extend in place.
- **Bundle workflow** `mix mailglass_admin.assets.build` + `verify.preview` git-diff gate — the
  TOKEN-05 enforcement already exists.

### Established Patterns
- Zero-Node: standalone Tailwind v4.1.12 binary; daisyUI/daisyui-theme/heroicons vendored in
  `assets/vendor/` (external deps only — `brandbook/` is in-repo, so NOT vendored).
- daisyUI v5 themes (`mailglass-light`/`mailglass-dark`) own COLOR+radius; `@theme` owns
  size/type/elevation/easing. `base-300` is daisyUI's border/divider/hover slot (matches the
  border-role remap); inputs resolve through daisyUI's own input-border var, independent of base-300.
- Required CI lanes via `mix.exs` `verify.*` aliases mapped to branch-protection jobs in `ci.yml`.

### Integration Points
- `app.css` `@import` of `../../../brandbook/tokens.css` (cross-package, maintainer-build-time only).
- daisyUI `--color-*` → `var(--mg-*)` references in the compiled `[data-theme=…]` selectors.
- New parity test → `verify.support_contract.admin` (required). Contrast proof → `accessibility_test.exs`.
- `check-conformance.sh` → new `credo_strict` CI step.
</code_context>

<specifics>
## Specific Ideas

- Cross-package import path is **`../../../brandbook/tokens.css`** (three levels up from
  `assets/css/`) — empirically required; wrong depth yields "Can't resolve". Comment the import
  line with its resolved target.
- Dark muted-text bug is concretely **3.18:1 on Ink** (Slate `#5C6B7A`) — fails AA; the fix
  `#B8CAD4` lands ≈10:1. Dark error `#D47368` is **off-palette** entirely; canonical is `#E29089`.
- Border role is **deliberately sub-3:1** (decorative; WCAG 1.4.11-exempt) — pin with an
  assertion + docstring; do NOT raise it.
- Map daisyUI slots **by value, not name** (`base-100` → background `#F8FBFD`, not surface white,
  to keep the elevation step).
</specifics>

<deferred>
## Deferred Ideas

- **Hard-flip the typography/tracking gates** (TRACK-GATE + TYPE `text-lg/xl`) from advisory to
  fail-closed — Phases 98/99, alongside the markup migration (`text-xl`→`text-heading`,
  `tracking-[0.08em]`→a new named `--tracking-eyebrow` token defined first). Per D-08.
- **Stronger active-row / hover states** on dark (`--mg-color-surface-selected` `#1B3E55`) — needs
  markup, deferred to Phase 98/99 component work.
- **Quality-ratchet apparatus** (score baseline, GAP-NN register, Playwright structural
  assertions, LLM-scored 18-cell matrix) — Phase 95 (RATCHET-01/02/04).

### Reviewed Todos (not folded)
- `2026-06-13-refresh-outbound-admin-ui-look-and-feel.md` (score 0.9) — reviewed, **not folded**.
  This is the milestone-level seed (already captured in STATE/PROJECT, broadened to all three
  admin surfaces across Phases 94–103). Phase 94 is only the token-foundation slice; the visible
  "refresh" lands across the fractal uplift phases (97–103), not here.
</deferred>
</content>
</invoke>
