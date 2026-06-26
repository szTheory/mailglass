# Phase 116: Fixtures + Idempotent Ratchet-Arm - Research

**Researched:** 2026-06-20
**Domain:** Playwright e2e + axe-core WCAG 2.2 AA accessibility baseline; multi-tenant Elixir/Phoenix stress fixtures; fail-closed JSON ratchet comparators
**Confidence:** HIGH (axe wire shape, version, and harness composition all verified/cited; one MEDIUM item — test-only path-dep compilability — flagged for plan-phase)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Interaction pillar is a separate BINARY pass/fail Playwright gate set (NOT a 7th LLM-scored pillar), extending `assertPanelAboveScrim` in `e2e/structural.spec.js`. Four invariants: panel-above-scrim hit-test, scroll-chaining/overscroll-contain, focus-restore-to-trigger, layout-jump/CLS — each parameterized across deliveries/inbound/preview × light/dark/system.
- **D-02:** Scored matrix STAYS at 54 cells (3 surfaces × 6 pillars × 3 themes), schema_version 3, untouched. Phase 116 performs the milestone's ONLY full pillar re-score (regenerate current, promote, meet-or-beat, zero regression). NO new pillar, NO schema bump.
- **D-03:** Axe baseline = NEW separate file `mailglass_admin/docs/axe-baseline.json`, `schema_version: 1`. Hybrid format: per-surface×theme violation COUNTS (meet-or-beat / zero-new floor) + rule-id → count breakdown. `surface → theme → { total, rules }`. `[role=dialog]` overlay violations fold into the opening surface (3×3 = 9 cells). REJECTED: node-fingerprint snapshots, bare rule-id allowlists.
- **D-04:** Axe comparator = `mailglass_admin/test/mailglass_admin/axe_baseline_test.exs`, near-clone of `ratchet_baseline_test.exs`. Assert schema_version==1; all 9 cells in BOTH blocks (fail closed); `prior.run_id != current.run_id`; meet-or-beat per cell + rule-id diff fail-closed on rising count OR new rule-id even if total flat.
- **D-05:** `@axe-core/playwright ^4.11.2` (test-only npm devDep, only net-new dep). `.withTags(['wcag2a','wcag2aa','wcag21a','wcag21aa','wcag22aa'])`, scan deliveries/inbound/preview + opened `[role=dialog]` in light/dark/system (`emulateMedia` for system). Producer spec `e2e/axe-baseline.spec.js`. Screenshot-free, no pixel-diff.
- **D-06:** Cohort defined ONCE as declarative spec in `reference/demo_app/lib/mailglass_demo/personas.ex`, materialized by 3 thin builders: demo seed (`DemoData.reset!` → `Personas.seed!(Repo)`), admin e2e (`operator_fixtures.ex` `seed_persona_cohort!/0` via test-only path dep `only: [:test]`), gallery static specimens (library-pure). Library lib code stays demo-free; only test support crosses the boundary.
- **D-07:** Drift-guard test asserts admin-side cohort matches `Personas` name + edge-case set (defeats triplication drift).
- **D-08:** Three personas: `northstar` (keep, many/high-count/error), `fjordline-aps` (NEW single delivery, one/long-ID/non-ASCII/null, `"Bjørn Hansen"`/`"山田太郎"`), `helios-void` (NEW zero deliveries, no-data edge — absent from switcher, direct-URL empty state). ≥2 selectable tenants → Phase-112 picker renders.
- **D-09:** Gallery widening keeps hand-enumerated specimen list as source of truth (stable `data-testid="gallery-{component}-{state}"`). Theme = existing inline 3-wrapper. Viewport = Playwright resize loop over SAME testids at 320/390/768/wide. REJECTED: programmatic cartesian generation (324-cell explosion).
- **D-10:** RATCHET-04 extends existing `reference/demo_app/assets/e2e` Playwright suite (config + `/demo/evidence/reset` token already shipped). No new harness; do NOT bend `OperatorBrowserServer`.
- **D-11:** RATCHET-05 = audit (verify-and-lock), not author-all-24. ~18 already have green guards (cite + prove green). Author net-new guards only for ~6 cohort/interaction residue: A3, A4/A23, A16-system, A21, A22, A11.
- **D-12:** Durable closure artifact = executable manifest `bucket_a_coverage_test.exs` mapping A-NN → {guard_kind, locator, status}; asserts cited guard physically exists (fail-closed on stale citation). Stable-ID / never-delete / downgraded-not-deleted contract like `RATCHET-GAP-REGISTER.md`. Human mirror `.planning/research/v1.13/BUCKET-A-LEDGER.md`.

### Claude's Discretion
- Exact file names/locations for new producer specs + bucket-A coverage test may be refined at plan time, honoring D-03/D-04/D-12.
- Precise CLS delta threshold (D-11, A21) and exact long-ID/non-ASCII literal values (D-08) are implementation details, provided they are domain-true.

### Deferred Ideas (OUT OF SCOPE)
- Marketing email / multi-channel — permanently out of scope (project-wide).
- No new product capability / providers / transports / routes (v1.13 scope lock — admin + demo only).
- Brandbook tokens are OUT (brand book is source of truth).
- The ONE deferred item this research settles: exact `@axe-core/playwright` 4.11.x wire shape + Playwright 1.59.1 + emulateMedia composition (resolved below — directional format already LOCKED).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RATCHET-01 | 2–3-tenant persona stress-fixture cohort (8 edge cases) in `reference/demo_app` seeds + gallery specimens | Persona Cohort section: `DemoData` single-tenant refactor surface, `list_tenants/2` distinct-tenant constraint, D-08 persona map, test-only path dep mechanism |
| RATCHET-02 | Widen gallery to component × state × {light,dark,system} × {320…wide} matrix | D-09 Playwright resize-loop over stable testids; SUMMARY §3a 324-cell explosion avoided |
| RATCHET-03 | Interaction pillar (binary Playwright gates) + WCAG 2.2 AA axe-JSON baseline, both screenshot-free | PRIMARY axe wire shape; `assertPanelAboveScrim` extension pattern; emulateMedia for theme axis |
| RATCHET-04 | Full matrix incl. ≥1 run vs rich demo_app data; promote current→prior, re-score, all gates green | Demo Harness section; ratchet comparator clone; meet-or-beat promotion |
| RATCHET-05 | Close all 24 Bucket-A defects, each w/ regression guard | D-11 audit approach (18 cite-existing + 6 net-new); D-12 executable manifest; Bucket-A guard kinds |
</phase_requirements>

## Summary

Phase 116 is the keystone ratchet-arm of v1.13. The directional architecture is fully locked in CONTEXT.md (D-01..D-12); this research settles the ONE deferred wire-level unknown (the `@axe-core/playwright` 4.11.x API + violation JSON shape and its composition with the pinned `@playwright/test ^1.59.1` harness) plus four thin implementation-blocking landmines the planner must route around.

**Primary finding:** `@axe-core/playwright ^4.11.2` resolves to `4.11.3` (current stable), declares `peerDependencies: { "playwright-core": ">= 1.0.0" }` (satisfied by `@playwright/test ^1.59.1`), and bundles `axe-core ~4.11.4` (ships the `wcag22aa` rule pack). The API is `new AxeBuilder({ page }).withTags([...]).analyze()` returning `AxeResults` whose `violations[]` entries carry `id` (the rule-id key), `nodes[]` (each node = one failing element → the count), plus `impact/tags/description/help/helpUrl` and per-node `html/target/failureSummary`. The locked D-03 hybrid output `surface → theme → { total, rules }` is derived by summing `v.nodes.length` per rule-id. `page.emulateMedia({ colorScheme })` (stable Playwright API) drives the light/dark/system axis and composes with the existing single-worker harness — no version conflict, no worker-model change.

**Four landmines for the planner:** (1) `DemoData` hardcodes `@tenant "northstar"` into every helper — the persona refactor must parameterize tenant or add a per-persona inserter; (2) `@empty_tenant "empty-tenant"` is declared but never seeded — `helios-void` is realized via ABSENCE (no Delivery → absent from `list_tenants/2`); (3) the test-only path dep `{:mailglass_demo, path: "../reference/demo_app", only: [:test], runtime: false}` is the only allowed boundary crossing — verify it compiles in admin's test env; (4) the `system` axe cell is only distinct from `light`/`dark` if both app-theme=system AND `emulateMedia colorScheme:dark` are set.

**Primary recommendation:** Add `@axe-core/playwright@^4.11.2` as a test-only devDep in `mailglass_admin/` only (NOT demo). Clone `ratchet_baseline_test.exs` verbatim for the axe comparator (`__DIR__` docs-path trick, `is_nil` fail-closed, `run_id` anti-vacuity, extend `compare_baselines/2` with a per-rule diff). Keep axe admin-only; RATCHET-04's demo run is structural-coverage, not an axe baseline source.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Persona stress cohort (data) | Database/Storage (demo Repo + admin TestRepo) | — | Fixtures are seed-time DB state; library lib code stays demo-free |
| Persona SPEC (declarative) | Backend/Elixir module (`personas.ex`) | Test support | Single source of truth consumed by 3 materializers |
| Tenant switcher visibility | API/Backend (`Mailglass.Operator.Tenants.list_tenants/2`) | Frontend (Phase-112 picker LiveView) | Distinct-`Delivery.tenant_id` read model is the constraint; picker is a pure consumer |
| Interaction invariants (panel/scroll/focus/CLS) | Browser/Client (Playwright e2e) | — | True/false runtime DOM properties only observable in a live browser |
| Axe WCAG baseline | Browser/Client (Playwright producer) + Backend (ExUnit comparator) | — | Scan is in-browser; meet-or-beat gate is fail-closed ExUnit |
| Gallery matrix | Frontend (`gallery_live.ex` static specimens) | Browser (Playwright resize loop) | Library-pure specimens; viewport axis is a browser concern |
| Bucket-A closure ledger | Backend (executable ExUnit manifest) | grep gates / Playwright | Fail-closed citation-existence checks keep the ledger honest in CI |

## PRIMARY: @axe-core/playwright Wire Shape (D-03/D-05)

### Version + dependency resolution (all VERIFIED via npm registry this session)

- **`@axe-core/playwright` latest stable = `4.11.3`** `[VERIFIED: npm view @axe-core/playwright version → 4.11.3]`. The locked constraint `^4.11.2` (D-05) resolves to `4.11.3` today. `4.11.4` exists only as prerelease (`4.11.4-*`); `4.12.x` is `rc` only. So `^4.11.2` is correct and current.
- **Peer dependency:** `playwright-core >= 1.0.0` `[VERIFIED: npm view ... peerDependencies]`. This is satisfied transitively by `@playwright/test ^1.59.1` (the EXACT pin in BOTH `mailglass_admin/package.json` and `reference/demo_app/assets/package.json` `[VERIFIED: read both package.json files]`). `@playwright/test` depends on `playwright` which depends on `playwright-core` at the same version — `1.59.1` >> `1.0.0`, so the peer is met with no conflict. **No peer-dep warning expected.**
- **Bundled axe-core:** `@axe-core/playwright@4.11.3` declares `dependencies: { "axe-core": "~4.11.4" }` `[VERIFIED: npm view ... dependencies]`. axe-core 4.11.x ships the WCAG 2.2 AA rule pack including `wcag22aa` tag — the D-05 tag list `['wcag2a','wcag2aa','wcag21a','wcag21aa','wcag22aa']` is valid against this version. `[CITED: github.com/dequelabs/axe-core API.md]`

### The exact API surface (CommonJS — matches the `.cjs` harness)

```javascript
// e2e/axe-baseline.spec.js — CommonJS to match playwright.config.cjs convention
const { test, expect } = require("@playwright/test");
const { AxeBuilder } = require("@axe-core/playwright");

const results = await new AxeBuilder({ page })
  .withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"])
  .analyze();
// results.violations is the array of interest
```

- Import: `const { AxeBuilder } = require("@axe-core/playwright");` (named export). `[CITED: axe-core-npm playwright README]`
- Construct: `new AxeBuilder({ page })` — takes the Playwright `page`. `[CITED: README]`
- `.withTags(String|Array)` — restricts to rules carrying any listed tag. Accepts a single string or array. `[CITED: README]`
- `.analyze()` returns `Promise<axe.Results>`. `[CITED: README]`

### `AxeResults.violations[]` wire shape (the load-bearing structure)

`results` has four arrays: `violations`, `passes`, `incomplete`, `inapplicable`. Only `violations` matters here. `[CITED: axe-core API.md]`

Each **violation object**:

| Field | Type | Use for D-03/D-04 |
|-------|------|-------------------|
| `id` | string | **THE rule-id key** for the `rules` breakdown (e.g. `"color-contrast"`) |
| `impact` | `"minor"\|"moderate"\|"serious"\|"critical"` | informational; not part of baseline math |
| `tags` | string[] | e.g. `["cat.color","wcag2aa","wcag143"]` — used only to confirm the rule was in scope |
| `description` | string | human context (not stored in baseline) |
| `help` | string | human context |
| `helpUrl` | string | Deque University link (not stored) |
| `nodes` | object[] | **`nodes.length` = the per-rule violation count** (each node = one failing element) |

Each **node object** (within `violations[].nodes`):

| Field | Type | Notes |
|-------|------|-------|
| `html` | string | HTML snippet of failing element |
| `target` | string[] (or nested array for shadow/iframe) | CSS selector path |
| `failureSummary` | string | human-readable "why" (e.g. `"Element has insufficient color contrast of 3.21 (foreground #9ca3af, background #ffffff...). Expected contrast ratio of 4.5:1"`) `[CITED: deque docs + axe-core/react dedup behavior]` |
| `impact` | string | per-node severity |
| `any` / `all` / `none` | check[] | check results; not needed for count baseline |

`[CITED: github.com/dequelabs/axe-core/blob/develop/doc/API.md]`

### Deriving the locked D-03 hybrid output `surface → theme → { total, rules }`

`total` = sum of node counts across all violations; `rules` = map of `violation.id → node count`. Per-surface×theme producer logic:

```javascript
function summarizeViolations(violations) {
  // violations: AxeResults.violations[]
  const rules = {};
  let total = 0;
  for (const v of violations) {
    const n = v.nodes.length;           // each failing node counts once
    rules[v.id] = (rules[v.id] || 0) + n;
    total += n;
  }
  // deterministic key order so the committed JSON diff is stable / minimal
  const sortedRules = Object.fromEntries(
    Object.keys(rules).sort().map((k) => [k, rules[k]])
  );
  return { total, rules: sortedRules };
}
```

Produces e.g. `{ "total": 2, "rules": { "color-contrast": 2 } }`. The D-03 failure message shape `"inbound.dark: color-contrast 0 → 2 (REGRESSION)"` is derived entirely on the ExUnit comparator side (D-04) from this `rules` map.

> **Counting decision the planner should lock:** `total` counts *failing nodes* (`v.nodes.length`), NOT `violations.length` (distinct rules). Counting nodes is the stricter, more diagnosable floor — adding one new bad element under an already-failing rule still trips the gate. This matches D-03's stated intent ("false-green on new nodes under an allowlisted rule" is the explicitly-rejected failure mode). The `rules` breakdown additionally keys by rule-id so a rule appearing/disappearing is also caught (D-04).

### Light / dark / system axis — `emulateMedia`

axe scans the rendered DOM, so theme must be applied to the page *before* `.analyze()`. Three mechanisms, matching the app's existing 3-theme model:

```javascript
// light (default — explicit for determinism)
await page.emulateMedia({ colorScheme: "light" });

// dark
await page.emulateMedia({ colorScheme: "dark" });

// system — the app reads prefers-color-scheme; emulate the OS preference.
// "system" theme in this app == honoring prefers-color-scheme, so to exercise
// the system-dark branch set colorScheme dark while the app is in system mode.
await page.emulateMedia({ colorScheme: "dark" });   // + ensure app theme = system
```

`page.emulateMedia({ colorScheme })` is a first-class Playwright API on `@playwright/test ^1.59.1` `[VERIFIED: stable since Playwright 1.9; present in 1.59.x]`. It sets the `prefers-color-scheme` media feature for the page. The existing `structural.spec.js` already drives theme via the app's inline 3-wrapper (light/dark/system) and reduced-motion via `emulateMedia` — so this composes with the established harness with no new infra.

> **Planner note on the `system` cell:** the app's `system` theme = "follow `prefers-color-scheme`". The axe baseline's `system` cell is only meaningfully distinct from `light`/`dark` if the OS preference is emulated AND the app is in system mode. The plan should set BOTH (app theme switch to system + `emulateMedia colorScheme:dark`) so the `system` cell genuinely exercises the media-query branch — otherwise `system` is a duplicate of `light` and the 9-cell block degenerates to 6 distinct cells. This is the same subtlety Phase 109 handled when seeding `system` into `ui-baseline-scores.json`.

### Compatibility verdict

- `@axe-core/playwright@4.11.3` + `@playwright/test@^1.59.1`: **compatible**, peer satisfied, no conflict. `[VERIFIED]`
- Single-worker `OperatorBrowserServer` harness (`--workers=1` in the npm script): axe adds no worker requirement — it runs inside the existing page context. **No worker-model change needed.**
- Install: `npm install --save-dev @axe-core/playwright@^4.11.2` run in `mailglass_admin/` (and, IF axe is also added to demo per D-10 discussion below, in `reference/demo_app/assets/`). Test-only devDep; zero Hex deps; zero runtime/app-bundle impact (never imported by `priv/static` assets).

## Axe Comparator Clone Pattern (D-04)

The axe comparator (`mailglass_admin/test/mailglass_admin/axe_baseline_test.exs`) is a near-clone of `ratchet_baseline_test.exs`. The four reusable mechanics, lifted verbatim from the template `[VERIFIED: read ratchet_baseline_test.exs]`:

### 1. The `__DIR__`-relative `docs/` path trick (D-03 placement)
```elixir
# Two levels up from test/mailglass_admin/ → test/ → mailglass_admin/ → docs/
# docs/ is outside priv/, so use __DIR__ relative path (not Application.app_dir).
@axe_path Path.join([__DIR__, "..", "..", "docs", "axe-baseline.json"])
```
This is exactly how `ratchet_baseline_test.exs` reaches `ui-baseline-scores.json`. The new `axe-baseline.json` is a sibling in the same `docs/` dir, so the identical path works.

### 2. Fail-closed `is_nil` missing-cell guard
The template fails closed on a missing cell rather than coercing to 0 (lines 107-109). For axe this means: assert all 9 `surface × theme` cells exist in BOTH `prior` and `current`; a missing cell is an error, never silently 0.

### 3. Anti-vacuity `run_id` check
```elixir
assert b["prior"]["run_id"] != b["current"]["run_id"],
  "prior and current share run_id ... — the re-score was not promoted; vacuous self-comparison."
```
A forgotten `current → prior` promotion fails loudly (template lines 87-89). axe baseline reuses this exactly.

### 4. `compare_baselines/2` shape — adapted for the hybrid count+rules structure
The template iterates a fixed cell list and flags `current < prior`. The axe variant must additionally diff the `rules` map per D-04. Recommended structure:

```elixir
@surfaces ["deliveries", "inbound", "preview"]
@themes ["light", "dark", "system"]

defp compare_axe(prior, current) do
  regressions =
    for surface <- @surfaces, theme <- @themes do
      pc = get_in(prior,   ["violations", surface, theme])
      cc = get_in(current, ["violations", surface, theme])

      cond do
        # fail closed — missing cell never coerces to {total: 0}
        is_nil(pc) or is_nil(cc) ->
          "#{surface}.#{theme}: missing cell (prior=#{inspect(pc)}, current=#{inspect(cc)})"

        # total meet-or-beat (zero-new floor)
        cc["total"] > pc["total"] ->
          "#{surface}.#{theme}: total #{pc["total"]} → #{cc["total"]} (REGRESSION)"

        true ->
          # per-rule diff: fail closed when ANY rule's count rises OR a rule-id
          # present in current is absent in prior (even if total held flat — a
          # rule swap masks under a flat total otherwise).
          rule_regressions =
            for {rid, ccount} <- (cc["rules"] || %{}) do
              pcount = get_in(pc, ["rules", rid]) || 0
              if ccount > pcount,
                do: "#{surface}.#{theme}: #{rid} #{pcount} → #{ccount} (REGRESSION)",
                else: nil
            end
            |> Enum.reject(&is_nil/1)

          if rule_regressions == [], do: nil, else: Enum.join(rule_regressions, "\n")
      end
    end
    |> List.flatten()
    |> Enum.reject(&is_nil/1)

  assert regressions == [],
    "Axe violation regressions — only-forward ratchet violated:\n" <> Enum.join(regressions, "\n")
end
```

This yields exactly the D-03 message shape `"inbound.dark: color-contrast 0 → 2 (REGRESSION)"`. Note the rule-id diff catches the "rule swap under flat total" case D-04 calls out: a new rule-id in current (pcount defaults to 0) with `ccount > 0` regresses even if `total` is unchanged.

### Schema + coverage assertions (mirror template tests 40-83)
- `assert b["schema_version"] == 1` (D-03 locks axe schema at 1, distinct from score schema 3).
- All 9 `surface × theme` cells present in both blocks (the missing-cell coverage test).
- The producer spec (`e2e/axe-baseline.spec.js`) writes `current.violations` + a fresh `run_id`; the promotion step copies `current → prior` before the re-scan.

### `[role=dialog]` overlay folding (D-03)
Overlay violations fold into the surface that opened them — so when the producer opens a dialog on `deliveries`, it scans the dialog and merges those violations into the `deliveries.{theme}` cell (it does NOT create a 4th surface). 3 surfaces × 3 themes = **9 cells**, as locked.

## Demo Harness Extension (RATCHET-04 / D-10)

The demo Playwright harness RATCHET-04 extends is `reference/demo_app/assets/` `[VERIFIED: read playwright.config.cjs + demo.spec.js]`. Confirmed facts:

- **Config:** `reference/demo_app/assets/playwright.config.cjs` — `testDir: "./e2e"`, `@playwright/test ^1.59.1` (same pin as admin), webServer runs `mix ecto.setup && mix phx.server` in MIX_ENV=dev unless `DEMO_BASE_URL` is set (external-server mode). 300s startup timeout. NO `--workers=1` override (the admin harness forces single-worker; demo does not — see worker note below).
- **Reset token flow:** `demo.spec.js` `beforeEach` POSTs `/demo/evidence/reset` with header `x-mailglass-demo-reset-token: $DEMO_EVIDENCE_RESET_TOKEN`. This is the seed-reset seam. The RATCHET-04 cohort spec extends this — after reset, the demo seed must already contain the persona cohort (so `DemoData.reset!` → `Personas.seed!` must run as part of reset).
- **JSON reporter:** demo config already emits `playwright-report.json` into `tmp/demo_browser_evidence` under CI — useful if axe results are captured as demo evidence.

### Does axe live in the demo harness too?

**Recommendation: axe lives ONLY in `mailglass_admin/e2e`, NOT in the demo harness.** Rationale:
- D-03/D-04 lock the axe baseline at `mailglass_admin/docs/axe-baseline.json` and the comparator at `mailglass_admin/test/...` — the baseline is an admin artifact. The admin `OperatorBrowserServer` harness drives the same three surfaces (deliveries/inbound/preview) the baseline scores, with deterministic `TestRepo` seeding.
- RATCHET-04's "≥1 run against rich demo_app data" is a *coverage* requirement (prove the UI survives realistic multi-tenant data) — it does NOT require the axe baseline to be produced from demo data. The demo cohort spec asserts the surfaces render correctly with the cohort present (structural assertions + tenant-picker visibility), not axe counts.
- Adding axe to demo would mean a SECOND `@axe-core/playwright` devDep install (in `reference/demo_app/assets/package.json`) and a second baseline source — splitting the single source of truth. Avoid.

> **If the planner nonetheless wants an axe smoke-run on demo data:** it would be advisory-only (no baseline comparison), and would require `npm install --save-dev @axe-core/playwright@^4.11.2` in `reference/demo_app/assets/` too. The `^1.59.1` pin matches, peer dep satisfied — no version incompatibility. But this duplicates the dep for marginal value; prefer keeping axe admin-only.

### Worker-model note
- Admin harness: `--workers=1` (forced in the npm script) because `OperatorBrowserServer` is a single shared server seam. axe runs in-page, adds no worker pressure — compatible.
- Demo harness: no `--workers=1`. The `beforeEach` reset is destructive (TRUNCATE + reseed), so **parallel demo workers would race the shared DB**. The existing demo suite is already serial-by-necessity for this reason; the RATCHET-04 cohort spec inherits that constraint. If adding cohort specs, keep them in the same serial flow (do NOT introduce `fullyParallel: true`).

> **Do NOT bend `OperatorBrowserServer` (D-10):** it seeds `browser-tenant` against `TestRepo`, a different seam from the demo `northstar` seed. The cohort RATCHET-04 run uses the demo harness + demo seed, not the admin browser server.

## Persona Cohort Triplication + Drift-Guard (D-06/D-07/D-08)

### Landmine 1 — `DemoData` is hardcoded single-tenant (the biggest refactor surface)
`reference/demo_app/lib/mailglass_demo/demo_data.ex` `[VERIFIED: read in full]` bakes `@tenant "northstar"` into EVERY private helper (`delivery!/1`, `event!/4`, `webhook!`, `suppression!/4`, `inbound_record!/1`, `inbound_evidence!/2`, `inbound_run!`, and the orphan/reconcile/failed-ingest inserts all set `tenant_id: @tenant`). `truncate!/0` wipes all tables RESTART IDENTITY CASCADE.

Implication for D-06: the `Personas.seed!(Repo)` builder cannot just call the existing helpers — those helpers must either (a) be parameterized to accept a `tenant_id`, or (b) `Personas` provides its own thin inserter that sets `tenant_id` per-persona. The existing `northstar` body (lines 42-491) is the `northstar` persona's payload — D-08 says "keep northstar as-is", so the cleanest path is: keep the existing `seed_outbound!/seed_inbound!` for northstar, and add `Personas.seed!` that ALSO seeds `fjordline-aps` (one delivery) + `helios-void` (zero deliveries). The drift-guard then asserts all three persona NAMES + their edge-case assignments are present.

### Landmine 2 — `@empty_tenant "empty-tenant"` is declared but never seeded
`DemoData` exposes `empty_tenant_id/0` returning `"empty-tenant"` but **no code ever inserts rows for it** `[VERIFIED]`. D-08's `helios-void` (zero-delivery edge) augments/replaces this. Because `list_tenants/2` keys off distinct non-null `Delivery.tenant_id` `[VERIFIED: read tenants.ex]`, a zero-delivery tenant is correctly ABSENT from the switcher — `helios-void` is "seeded" by intentionally having NO deliveries (it may have zero rows entirely, OR an Event/InboundMessage but no Delivery). The planner must decide: does `helios-void` exist as any row at all, or is it purely a negative assertion (absent from switcher + direct-URL renders empty state)? Per D-08 it is "the load-bearing edge" tested via absence + direct-URL empty-state — so it likely needs at least a reachable surface (e.g. a tenant_id string the test navigates to) without a Delivery.

### Landmine 3 — the test-only path dep boundary crossing (D-06 mechanism 2)
The admin e2e materialization (`mailglass_admin/test/support/operator_fixtures.ex` gains `seed_persona_cohort!/0`) reaches the demo `Personas` spec via a **test-only path dep** (`only: [:test]`). This is the ONLY allowed boundary crossing (CLAUDE.md: "library lib code never depends on demo; only test support may cross the boundary").

Planner verification items:
- Add to `mailglass_admin/mix.exs` deps: `{:mailglass_demo, path: "../reference/demo_app", only: [:test], runtime: false}` (or similar) — **confirm the path is correct relative to `mailglass_admin/`** (`../reference/demo_app`). `runtime: false` keeps it out of prod.
- The demo app must be compilable as a dep in admin's test env. The demo app pulls `mailglass` + `mailglass_inbound` + Phoenix — confirm no dep-version conflict with admin's own `mix.lock`. **This is a light plan-phase verification item** (compile `MIX_ENV=test mix deps.get && mix compile` in `mailglass_admin/`).
- `Personas` must be a pure data/spec module (no demo-web, no Repo hardcoding) so admin test-support can call `Personas.spec()` to drive `TestRepo` materialization. Keep the persona SPEC (names + 8 edge-case assignments + payload shapes) separate from the demo-Repo seeding side-effect, so both demo seed and admin TestRepo can consume the same spec.

### Landmine 4 — gallery mirror is library-pure (D-06 mechanism 3 / D-09)
The gallery (`mailglass_admin/lib/mailglass_admin/gallery_live.ex`) mirrors only the long-ID / non-ASCII / null VALUES as named static specimen states — it must NOT depend on demo or seed any DB. D-09 keeps the hand-enumerated specimen list as source of truth (stable `data-testid="gallery-{component}-{state}"`). Existing specimens already include `non-ascii-tenant` / `long-value-stress` per the CONTEXT code-context — additive only. The non-ASCII literals `"Bjørn Hansen"` / `"山田太郎"` should match between gallery specimens and the `fjordline-aps` persona so the drift-guard can assert consistency.

### The drift-guard (D-07)
A test asserts the admin-side cohort materialization matches the `Personas` persona-name + edge-case set, so the three materializations cannot diverge. Concretely: `Personas.spec()` returns the canonical list; the drift-guard asserts (a) the demo seed produced exactly those tenant_ids, (b) the admin `seed_persona_cohort!/0` produced the same, (c) the gallery specimen set covers the same edge-case value classes. Fail-closed: a persona added to the spec but not to a materializer fails the guard.

### D-08 persona → edge-case map (locked, for the planner's reference)
| Persona | Deliveries | Edge cases | Domain-true payload |
|---------|-----------|-----------|---------------------|
| `northstar` (keep) | many / high-count | many / high-count / error | full 14-event lifecycle, replay/orphan/reconcile, failed_ingest, `:bounced` w/ reject_reason — ALREADY in DemoData |
| `fjordline-aps` (new) | 1 | one / long-ID / non-ASCII / null | recipient names `"Bjørn Hansen"` / `"山田太郎"`, `del_01JXW…` long-ID, one event `reject_reason: nil` on a `:delivered`, long Mailable module name |
| `helios-void` (new) | 0 | no-data | absent from switcher (list_tenants); direct-URL renders empty/permission state, no crash |

With northstar + fjordline-aps selectable (≥2 deliveries-bearing tenants), the Phase-112 tenant picker has a real reason to render (it only appears at ≥2 tenants).

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `@axe-core/playwright` | `^4.11.2` → resolves `4.11.3` | WCAG 2.2 AA scan inside Playwright pages | Deque's official Playwright integration; the only maintained axe×Playwright binding `[VERIFIED: npm registry]` |
| `@playwright/test` | `^1.59.1` (EXISTING pin) | e2e browser harness | Already pinned in both admin + demo `package.json`; no change `[VERIFIED: read package.json]` |
| `axe-core` | `~4.11.4` (transitive) | accessibility rule engine | Bundled by `@axe-core/playwright`; ships `wcag22aa` tag `[VERIFIED: npm view dependencies]` |
| ExUnit + Jason | (existing) | fail-closed JSON baseline comparators | `ratchet_baseline_test.exs` template already uses `Jason.decode!` |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| (none new) | — | — | Zero new Hex deps; `@axe-core/playwright` is the only net-new dependency in the whole phase |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `@axe-core/playwright` | `axe-playwright` (community wrapper) | Older API, less maintained, no first-party Deque support — REJECT |
| node-count `total` | `violations.length` (distinct rules) | rule-count misses new bad nodes under an existing rule (the explicitly-rejected D-03 false-green) — use node count |
| Adding axe to demo harness | axe admin-only | Splitting baseline source of truth + 2nd dep install for marginal value — keep admin-only |

**Installation:**
```bash
# In mailglass_admin/ only (NOT reference/demo_app/assets unless an advisory demo smoke-run is later wanted)
cd mailglass_admin && npm install --save-dev @axe-core/playwright@^4.11.2
```

**Version verification (run this session):**
```
npm view @axe-core/playwright version           → 4.11.3        [VERIFIED]
npm view @axe-core/playwright peerDependencies   → { playwright-core: '>= 1.0.0' }  [VERIFIED]
npm view @axe-core/playwright dependencies        → { axe-core: '~4.11.4' }  [VERIFIED]
```

## Package Legitimacy Audit

> Legitimacy seam (`gsd-tools query package-legitimacy`) was UNAVAILABLE in this session (returned SEAM_UNAVAILABLE). Verdict below is from manual registry verification + official-source provenance.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `@axe-core/playwright` | npm | mature (4.x line, years) | very high (Deque official, millions/wk) | github.com/dequelabs/axe-core-npm | OK | Approved (cited from official Deque repo README + axe-core API docs) |

- This package is discovered from an AUTHORITATIVE source (Deque's official `dequelabs/axe-core-npm` repo + axe-core API.md), not from a bare WebSearch guess — so it qualifies beyond `[ASSUMED]`. Registry metadata (peer/deps/version) confirmed via `npm view`.
- No suspicious postinstall: `@axe-core/playwright` is a pure JS lib; no native build step required.

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### Three coexisting fail-closed primitives (the v1.13 ratchet model)
```
                       ┌─────────────────────────────────────────────┐
   Playwright e2e ───► │ (1) 54-cell AESTHETIC matrix                 │
   producer + LLM      │     ui-baseline-scores.json (schema 3)       │ ─► ratchet_baseline_test.exs
                       │     3 surfaces × 6 pillars × 3 themes        │    (meet-or-beat, run_id anti-vacuity)
                       └─────────────────────────────────────────────┘
   Playwright e2e ───► ┌─────────────────────────────────────────────┐
   structural.spec.js  │ (2) BINARY interaction gates (D-01)          │ ─► test names ARE the diagnosis
                       │     panel/scroll/focus/CLS × surface × theme │    (no JSON baseline — pass/fail)
                       └─────────────────────────────────────────────┘
   AxeBuilder.analyze  ┌─────────────────────────────────────────────┐
   e2e/axe-baseline    │ (3) 9-cell AXE baseline (D-03, schema 1)     │ ─► axe_baseline_test.exs
   .spec.js producer   │     axe-baseline.json: surface→theme→        │    (meet-or-beat counts + per-rule diff,
                       │     {total, rules{rule-id→count}}            │     fail-closed missing cell + run_id)
                       └─────────────────────────────────────────────┘
```

### Pattern 1: Producer/comparator split (axe + scores both follow this)
**What:** A Playwright "producer" spec regenerates the `current` block of a committed JSON baseline on demand; a separate ExUnit "comparator" test fails-closed on regression. The JSON file is the durable artifact; ExUnit is the CI gate.
**When to use:** any meet-or-beat ratchet that needs a human-reviewable committed diff.
**Example:** see Code Examples below (producer writes JSON; `axe_baseline_test.exs` reads + compares).

### Pattern 2: Single declarative spec, N thin materializers (D-06)
**What:** Define the persona cohort once as pure data (`Personas.spec()`); materialize via thin mechanical builders into each consumer (demo Repo, admin TestRepo, gallery specimens). A drift-guard asserts the materializers agree.
**When to use:** the same fixtures must appear in ≥2 environments that cannot share a DB.

### Anti-Patterns to Avoid
- **Programmatic cartesian gallery generation:** breaks the `data-testid="gallery-{component}-{state}"` contract the conformance awk-assertions depend on; explodes to 324 cells (SUMMARY §3a). Use a resize loop over the SAME stable testids.
- **Counting `violations.length` instead of node count:** false-green when a new bad element appears under an already-failing rule.
- **Coercing a missing baseline cell to 0:** vacuous comparison. Fail closed.
- **Library lib code importing demo:** only test support may cross the boundary (test-only path dep).
- **`fullyParallel` on the demo harness:** the destructive `/demo/evidence/reset` beforeEach races a shared DB across workers.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| WCAG 2.2 AA rule evaluation | a custom contrast/aria checker | `@axe-core/playwright` `.withTags(['...wcag22aa'])` | axe encodes hundreds of rules + edge cases; hand-rolling is incomplete + drifts from the spec |
| theme media emulation | manual `document.documentElement.classList` hacks | `page.emulateMedia({ colorScheme })` | first-class Playwright API; matches existing `structural.spec.js` reduced-motion pattern |
| panel-above-scrim hit-test | screenshot/pixel diff | `document.elementFromPoint` centroid hit-test (existing `assertPanelAboveScrim`) | deterministic, no-pixel-diff, already in the codebase |
| meet-or-beat comparator | bespoke diff logic | clone `ratchet_baseline_test.exs` | the fail-closed/anti-vacuity mechanics are already proven across phases 95/103 |

**Key insight:** every primitive this phase needs already exists in-repo (`ratchet_baseline_test.exs` comparator, `assertPanelAboveScrim` hit-test, `emulateMedia` theme drive, the demo reset token flow). The ONLY net-new capability is axe's rule engine — and that is precisely what should be a library, not hand-rolled.

## Common Pitfalls

### Pitfall 1: `system` axe cell silently duplicates `light`
**What goes wrong:** the `system` theme cell scans identical DOM to `light`, so the 9-cell block degenerates to 6 distinct cells and a system-only regression is invisible.
**Why it happens:** `system` theme = "follow prefers-color-scheme"; if the OS preference isn't emulated AND the app isn't in system mode, the page renders light.
**How to avoid:** for the `system` cell, set BOTH app theme = system AND `page.emulateMedia({ colorScheme: 'dark' })` so the media-query branch is genuinely exercised (mirrors how Phase 109 seeded `system` into the score baseline; mirrors `structural.spec.js` L1110-1120 explicit-system pattern).
**Warning signs:** `system` and `light` cells have byte-identical `{total, rules}` for all surfaces.

### Pitfall 2: `DemoData` tenant hardcoding blocks multi-tenant seeding
**What goes wrong:** calling existing `delivery!/event!` helpers for `fjordline-aps` silently writes `tenant_id: "northstar"`.
**Why it happens:** every private helper closes over `@tenant "northstar"`.
**How to avoid:** parameterize the helpers with a `tenant_id` arg, or give `Personas` its own thin inserter. Verify seeded `Delivery.tenant_id` values per persona after `reset!`.
**Warning signs:** `list_tenants/2` returns only `northstar` after the cohort lands.

### Pitfall 3: test-only path dep fails to compile in admin test env
**What goes wrong:** `{:mailglass_demo, path: "../reference/demo_app", only: [:test]}` introduces a dep-version conflict (demo pulls its own mailglass/phoenix versions) or the demo app isn't structured as a consumable dep.
**Why it happens:** the demo app was built as a standalone Phoenix app, not a library dep.
**How to avoid:** a light plan-phase verification — `cd mailglass_admin && MIX_ENV=test mix deps.get && mix compile`. If conflict, scope the path dep to only compile `Personas` (extract `personas.ex` as a minimal pure module), or vendor the spec.
**Warning signs:** `mix deps.get` reports a version conflict on `mailglass`/`phoenix`.

### Pitfall 4: stale Bucket-A citation passes vacuously
**What goes wrong:** `bucket_a_coverage_test.exs` cites a gate/testid that was renamed or deleted, so the ledger claims green while the guard is gone.
**Why it happens:** D-12's whole point — citations drift.
**How to avoid:** the manifest must ASSERT the cited string literal physically exists (gate name in `check-conformance.sh`; `data-testid`/title literal in `e2e/*.spec.js`; fixture testid present). Fail closed on absence.
**Warning signs:** a guard file renamed without updating the manifest.

## Code Examples

### Producer spec — regenerate `current.violations` (e2e/axe-baseline.spec.js)
```javascript
// Source: dequelabs/axe-core-npm README + axe-core API.md (verified this session)
const { test } = require("@playwright/test");
const { AxeBuilder } = require("@axe-core/playwright");
const fs = require("fs");
const path = require("path");

const WCAG = ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"];
const SURFACES = { deliveries: "/ops/mail?...&view=deliveries",
                   inbound: "/ops/mail/inbound?...",
                   preview: "/dev/mail" };
const THEMES = ["light", "dark", "system"];

function summarize(violations) {
  const rules = {};
  let total = 0;
  for (const v of violations) {
    const n = v.nodes.length;
    rules[v.id] = (rules[v.id] || 0) + n;
    total += n;
  }
  const sorted = Object.fromEntries(Object.keys(rules).sort().map((k) => [k, rules[k]]));
  return { total, rules: sorted };
}

test("regenerate axe baseline current block", async ({ page }) => {
  const out = { schema_version: 1,
                current: { run_id: `axe-${new Date().toISOString().slice(0,10)}`, violations: {} } };
  for (const [surface, url] of Object.entries(SURFACES)) {
    out.current.violations[surface] = {};
    for (const theme of THEMES) {
      if (theme === "dark" || theme === "system") await page.emulateMedia({ colorScheme: "dark" });
      else await page.emulateMedia({ colorScheme: "light" });
      // (set app theme = system for the system cell so the media branch is live)
      await page.goto(url);
      // open [role=dialog] overlay here if folding overlay violations into this surface
      const results = await new AxeBuilder({ page }).withTags(WCAG).analyze();
      out.current.violations[surface][theme] = summarize(results.violations);
    }
  }
  const file = path.join(__dirname, "..", "docs", "axe-baseline.json");
  // merge into existing file's prior block on promotion; shown standalone here
  fs.writeFileSync(file, JSON.stringify(out, null, 2) + "\n");
});
```

### Example `axe-baseline.json` shape (D-03 hybrid)
```json
{
  "schema_version": 1,
  "prior":   { "run_id": "axe-2026-06-13-phase-103",
               "violations": { "deliveries": { "light": { "total": 0, "rules": {} },
                                                "dark":  { "total": 0, "rules": {} },
                                                "system":{ "total": 0, "rules": {} } },
                               "inbound":  { "light": { "total": 0, "rules": {} }, "dark": {"total":0,"rules":{}}, "system": {"total":0,"rules":{}} },
                               "preview":  { "light": { "total": 0, "rules": {} }, "dark": {"total":0,"rules":{}}, "system": {"total":0,"rules":{}} } } },
  "current": { "run_id": "axe-2026-06-20-phase-116",
               "violations": { "deliveries": { "light": { "total": 0, "rules": {} }, "dark": {"total":0,"rules":{}}, "system": {"total":0,"rules":{}} },
                               "inbound":  { "light": { "total": 0, "rules": {} }, "dark": {"total":0,"rules":{}}, "system": {"total":0,"rules":{}} },
                               "preview":  { "light": { "total": 0, "rules": {} }, "dark": {"total":0,"rules":{}}, "system": {"total":0,"rules":{}} } } }
}
```

### Interaction pillar extension (clone `assertPanelAboveScrim`, structural.spec.js L528)
```javascript
// Existing in-repo pattern — the D-01 interaction pillar extends this seam.
async function assertPanelAboveScrim(modal, label) {
  await expect(modal, label).toBeVisible();
  const hitTest = await modal.evaluate(el => {
    const rect = el.getBoundingClientRect();
    const hit = document.elementFromPoint(rect.left + rect.width/2, rect.top + rect.height/2);
    return { ok: hit === el || el.contains(hit) };
  });
  expect(hitTest.ok, `${label} panel above scrim at centroid`).toBeTruthy();
}
// New invariants follow the same evaluate-in-page + assert shape:
//  - scroll-chaining: scroll modal to end; assert window.scrollY of background unchanged
//  - focus-restore: close overlay; assert document.activeElement === trigger
//  - layout-jump/CLS: capture getBoundingClientRect().height loading vs loaded; assert delta <= threshold
```

## Validation Architecture

> nyquist_validation is `true` in `.planning/config.json` `[VERIFIED]` — section included.

### Test Framework
| Property | Value |
|----------|-------|
| Framework (Elixir) | ExUnit (admin app), Elixir ~1.18 / OTP 27 |
| Framework (browser) | `@playwright/test ^1.59.1` (admin `e2e/` + demo `assets/e2e/`) |
| Config file | `mailglass_admin/playwright.config.cjs`, `reference/demo_app/assets/playwright.config.cjs` |
| Quick run command | `cd mailglass_admin && mix test test/mailglass_admin/axe_baseline_test.exs test/mailglass_admin/ratchet_baseline_test.exs` |
| Full suite command | `cd mailglass_admin && mix mailglass_admin.assets.build && npm run test:operator-browser` (Playwright) + `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RATCHET-01 | cohort seeds 3 personas; `list_tenants/2` shows ≥2; helios-void absent | integration (ExUnit) + drift-guard | `mix test test/.../persona_cohort_test.exs` | ❌ Wave 0 |
| RATCHET-01 | drift-guard: 3 materializers agree on names + edge cases | unit (ExUnit) | `mix test test/.../persona_drift_guard_test.exs` | ❌ Wave 0 |
| RATCHET-02 | gallery specimens render at 320/390/768/wide × 3 themes, no overflow | structural (Playwright resize loop) | `npm run test:operator-browser` (gallery spec) | ⚠️ extend `structural.spec.js` |
| RATCHET-03 | interaction pillar: panel/scroll/focus/CLS binary gates | structural (Playwright) | `npm run test:operator-browser` | ⚠️ extend `structural.spec.js` |
| RATCHET-03 | axe baseline meet-or-beat (9 cells, schema 1, fail-closed) | ExUnit comparator | `mix test test/mailglass_admin/axe_baseline_test.exs` | ❌ Wave 0 (clone) |
| RATCHET-04 | ≥1 run vs demo data; current→prior promoted; 54-cell re-score green | Playwright (demo) + ExUnit ratchet | `cd reference/demo_app/assets && npm run test:e2e` + admin ratchet test | ⚠️ extend `demo.spec.js` |
| RATCHET-05 | 24 Bucket-A defects each have a live guard; manifest fail-closed | ExUnit manifest + grep gates + Playwright | `mix test test/.../bucket_a_coverage_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** the targeted ExUnit file(s) touched (`axe_baseline_test.exs`, `persona_*_test.exs`, `bucket_a_coverage_test.exs`) + `check-conformance.sh`.
- **Per wave merge:** full admin `mix test` (scope to avoid the ~57 unrelated Oban worktree failures per MEMORY) + `npm run test:operator-browser`.
- **Phase gate:** full Playwright matrix (admin + ≥1 demo run) green + all three baseline comparators green before `/gsd-verify-work`. Run on main, not a worktree (execute-phase worktrees impractical per MEMORY — deps/_build gitignored).

### Wave 0 Gaps
- [ ] `mailglass_admin/test/mailglass_admin/axe_baseline_test.exs` — clone of ratchet comparator (RATCHET-03)
- [ ] `mailglass_admin/docs/axe-baseline.json` — 9-cell schema-1 baseline (seeded by producer spec)
- [ ] `mailglass_admin/e2e/axe-baseline.spec.js` — producer (RATCHET-03)
- [ ] `reference/demo_app/lib/mailglass_demo/personas.ex` — declarative spec (RATCHET-01)
- [ ] `mailglass_admin/test/support/operator_fixtures.ex` — `seed_persona_cohort!/0` (RATCHET-01)
- [ ] test-only path dep entry in `mailglass_admin/mix.exs` (RATCHET-01)
- [ ] persona drift-guard test (RATCHET-01 / D-07)
- [ ] `bucket_a_coverage_test.exs` executable manifest + `.planning/research/v1.13/BUCKET-A-LEDGER.md` mirror (RATCHET-05)
- [ ] `@axe-core/playwright@^4.11.2` devDep install + committed `package-lock` (if lockfile tracked)
- [ ] 6 net-new Bucket-A guards (A3, A4/A23, A16-system, A21, A22, A11)
- Framework install: `cd mailglass_admin && npm install --save-dev @axe-core/playwright@^4.11.2`

## Project Constraints (from CLAUDE.md)

- **Zero-Node asset pipeline:** `@axe-core/playwright` is a test-only devDep, NEVER imported into `priv/static` bundles. Committed `priv/static/app.css` rule still applies — no asset rebuild needed for axe.
- **Library lib code never depends on demo:** only test support may cross the boundary (test-only path dep, `only: [:test]`). `personas.ex` lives in the DEMO app; admin reaches it only via the test-scoped path dep.
- **NO pixel-diff regression ever:** axe-JSON + structural + score-baseline only. (D-03/D-05 already honor this.)
- **Tenant listing from core read model scoped via `Mailglass.Tenancy.scope/2`:** never raw admin Repo. `PHASE112-SHELL-GATE` enforces. The cohort surfaces through `list_tenants/2`, not a direct query.
- **No new product capability / providers / transports / routes:** admin + demo only.
- **Domain language:** persona/recipient/event naming follows `prompts/mailer-domain-language-deep-research.md` + the seven nouns + Anymail taxonomy (D-08 names already domain-true).
- **Conventional Commits enforced;** `docs(state):` for STATE.md; squash-merge. Commit `mix.lock` only for clean intentional new-dep entries (MEMORY).
- **bare `mix test` has ~57 unrelated Oban failures in worktrees** (MEMORY) — scope test runs; verify on main.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The test-only path dep `{:mailglass_demo, path: "../reference/demo_app", only: [:test]}` compiles cleanly in admin's test env without a mailglass/phoenix version conflict | Persona Cohort / Pitfall 3 | If it conflicts, must extract `personas.ex` as a minimal standalone module or vendor the spec — plan-phase must verify with `mix deps.get && mix compile` |
| A2 | The `system` app theme genuinely renders distinct DOM from `light` when `emulateMedia colorScheme:dark` + app-theme=system are both set | PRIMARY axe / Pitfall 1 | If `system` can't be made distinct, the 9-cell block effectively has 6 distinct cells; baseline still valid but `system` rows are redundant |
| A3 | `failureSummary` is reliably populated on every violation node in axe-core 4.11.x (it is human-display only; not used in the count math) | PRIMARY axe wire shape | Low — not load-bearing for the baseline; only `id` + `nodes.length` matter |
| A4 | helios-void needs at least a reachable tenant_id string for the direct-URL empty-state test, even with zero Deliveries | Persona Cohort / D-08 | If a fully-rowless tenant can't be navigated to, the empty-state assertion needs a different reachability mechanism — implementation detail for planner |
| A5 | The demo app's `mix ecto.setup` (config webServer) already runs `seeds.exs` → `DemoData.reset!`, so `Personas.seed!` runs as part of the demo harness startup | Demo Harness | If seeds aren't run on harness boot, RATCHET-04 cohort won't be present — verify the demo webServer command seeds |

**Note:** the directional axe format (hybrid counts + rule breakdown, separate docs/ file, 9 cells) is LOCKED in CONTEXT.md, not assumed. The wire-shape claims (violation fields, API methods, version resolution) are `[VERIFIED]`/`[CITED]`, not assumed.

## Open Questions (RESOLVED)

> All three questions are resolved and threaded into the plan set. Each carries an inline resolution
> pointer naming the consuming plan/task. The questions are retained (not deleted) for traceability.

1. **Does the demo webServer boot seed the cohort?**
   - What we know: demo config runs `mix ecto.setup && mix phx.server`; `seeds.exs` calls `DemoData.reset!`.
   - What's unclear: whether `ecto.setup` runs `seeds.exs` (alias-dependent), and whether the `/demo/evidence/reset` beforeEach re-runs `Personas.seed!`.
   - Recommendation: plan a task to confirm `DemoData.reset!` (incl. `Personas.seed!`) runs both at boot AND on the reset-token POST.
   - **RESOLVED →** Plan **116-06 Task 1** (demo cohort run) opens by confirming `Personas.seed!` runs on the `/demo/evidence/reset` token POST and wires `reset!` to seed the cohort if not; plan **116-01 Task 1** wires `DemoData.reset!` to call `Personas.seed!(Repo)` (boot seeding) and its 116-01 SUMMARY records whether boot seeding holds. (maps to Assumption A5)

2. **Path-dep granularity for `personas.ex`.**
   - What we know: only test support may cross the demo boundary.
   - What's unclear: whether the whole demo app compiles cleanly as an admin test dep, or whether `Personas` must be a minimal extractable module.
   - Recommendation: try the full path dep first; fall back to a pure spec module if `mix compile` conflicts.
   - **RESOLVED →** Plan **116-01 Task 2** adds the `{:mailglass_demo, path: "../reference/demo_app", only: [:test], runtime: false}` path dep and discharges it with `MIX_ENV=test mix deps.get && mix compile`, with the documented fallback to extract a minimal standalone `Personas` module if a mailglass/phoenix version conflict surfaces. (maps to Assumption A1 / Pitfall 3)

3. **Is `helios-void` a zero-row tenant or a rows-but-no-Delivery tenant?**
   - What we know: `list_tenants/2` keys off distinct non-null `Delivery.tenant_id`; absence is the asserted edge.
   - What's unclear: D-08 says "direct-URL renders empty state" — that needs a reachable surface.
   - Recommendation: planner decides; likely a tenant_id the test navigates to with zero Deliveries (may have an Event/InboundMessage to make the surface non-404 but Delivery-empty).
   - **RESOLVED →** Plan **116-01 Task 2** resolves helios-void as a reachable zero-Delivery tenant: it is absent from `list_tenants/2` (no Delivery rows) yet navigable by direct URL to render the empty state without a crash (asserted in `persona_cohort_test.exs`). (maps to Assumption A4)

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `@playwright/test` | all e2e | ✓ (pinned) | `^1.59.1` | — |
| `@axe-core/playwright` | axe baseline | ✗ (to install) | `^4.11.2`→4.11.3 | none — required net-new devDep |
| npm registry access | install axe dep | ✓ | — | — |
| Playwright browsers | e2e run | assume installed (existing harness runs) | bundled w/ 1.59.1 | `npx playwright install` if missing |
| PostgreSQL | demo seed + admin TestRepo | ✓ (existing harness) | — | — |
| Elixir/OTP | ExUnit comparators | ✓ | ~1.18 / OTP 27 | — |

**Missing dependencies with no fallback:** `@axe-core/playwright` — must be installed (`npm install --save-dev @axe-core/playwright@^4.11.2` in `mailglass_admin/`). This is the only net-new dependency in the phase and is the single install task.
**Missing dependencies with fallback:** none.

## Sources

### Primary (HIGH confidence)
- `npm view @axe-core/playwright {version,peerDependencies,dependencies,versions}` — version resolution, peer/dep constraints (run this session)
- github.com/dequelabs/axe-core-npm `packages/playwright/README.md` — AxeBuilder API (`new AxeBuilder({page})`, `.withTags`, `.analyze`)
- github.com/dequelabs/axe-core `doc/API.md` — `violations[]` + node object wire shape
- In-repo (read this session): `ratchet_baseline_test.exs`, `ui-baseline-scores.json`, `playwright.config.cjs` (admin + demo), `package.json` (admin + demo), `demo_data.ex`, `seeds.exs`, `tenants.ex`, `structural.spec.js` (assertPanelAboveScrim + emulateMedia patterns), `demo.spec.js`, CONTEXT.md, REQUIREMENTS.md, PITFALLS.md Bucket A

### Secondary (MEDIUM confidence)
- deque.com axe API documentation + axe-core/react dedup behavior (WebSearch) — `failureSummary` content/usage confirmation

### Tertiary (LOW confidence)
- none load-bearing

## Metadata

**Confidence breakdown:**
- Standard stack (axe version/peer/deps): HIGH — verified via npm registry + official Deque repo this session
- Axe wire shape (violations/nodes fields): HIGH — cited from axe-core official API.md + README
- emulateMedia composition + worker model: HIGH — verified against existing in-repo `structural.spec.js` usage + pinned 1.59.1
- Comparator clone pattern: HIGH — read the exact template in full
- Persona cohort landmines: HIGH — read `demo_data.ex` + `tenants.ex` in full (single-tenant hardcoding + distinct-tenant constraint confirmed)
- Test-only path-dep compilability (A1): MEDIUM — not compiled this session; flagged as plan-phase verification item

**Research date:** 2026-06-20
**Valid until:** 2026-07-20 (axe-core 4.11.x line stable; re-verify version if `^4.11.2` drift matters — `4.12.x` is rc-only as of this date)
