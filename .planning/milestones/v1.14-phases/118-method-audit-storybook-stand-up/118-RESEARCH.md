# Phase 118: Method, Audit & Storybook stand-up - Research

**Researched:** 2026-06-26
**Domain:** Dev-tooling / review-method stand-up (phoenix_storybook + Playwright persona-critic harness + ratchet-floor verification)
**Confidence:** HIGH (codebase-grounded; external mechanics cited from hexdocs + verified on hex)

## Summary

This is a **pure tooling/method phase** — it redesigns no surface and fixes no bug. The CONTEXT.md
assumptions pass (D-01..D-14) already resolved the integration mechanics; this research **validates
them against the actual codebase and external docs** and surfaces the few places where a locked
decision needs a small adaptation. All five named bug sites, all five floor artifacts, the existing
Playwright accent-allowlist seam, the committed-CSS asset route, and the `data-theme` shell contract
were confirmed by direct file read.

Three findings change nothing strategic but **must** reach the planner: (1) the screenshot cache dir
`.planning/research/v1.14/.cache/screenshots/` is **NOT currently gitignored** (git treats it as
untracked, not ignored) — D-02 assumes it is, so the plan must add a `.gitignore` entry as an explicit
task. (2) An **existing structural test** (`mailglass_admin/e2e/operator.spec.js:352-368`, VERIF-02)
asserts `data-testid="operator-overview-nav"` IS visible — the new `no-nav-duplication` gate (D-11)
asserts its *absence*. These don't run in the same suite today (the new gate is drafted pending/xfail
per D-12), but the planner must note the existing test will need updating in Phase 119 when the card is
removed, or the two will contradict. (3) `color_mode: true` in phoenix_storybook applies a `dark` CSS
**class**, never `data-theme` — confirming D-08's bridge is mandatory; the cleanest form is
**template-level `data-theme` per variation**, not the storybook color-mode picker.

**Primary recommendation:** Plan four work areas as mostly-independent tasks — (A) phoenix_storybook
dev-only wiring in the demo app with hand-written backend + template-level `data-theme` bridge; (B) a
small persona-critic screenshot seam reusing the demo's Playwright infra, driving a prioritized cell
sample (NOT full Cartesian) to author `DEFECT-REGISTER.md`; (C) two new Playwright rendered-DOM gates
drafted as `test.fixme` pending; (D) a verify-green run of the five inherited floor artifacts with no
re-score and no arming. Add the `.gitignore` fix as a Wave-0 prerequisite.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| phoenix_storybook explorer + stories | Frontend Server (demo app, `:dev`) | — | Dev-only LiveView host; never ships to adopters (D-06) |
| Sandbox stylesheet (component CSS) | CDN/Static (committed `app.css`) | API/Backend (asset route) | Reuse the already-served `/mail/css-<md5>` bundle (D-07) |
| `data-theme` theme bridge | Frontend Server (story templates) | — | Templates set the attribute the components read; never touch `app.css` (D-08) |
| Persona-critic screenshots | Browser (Playwright) | Frontend Server (`make demo`) | Drive the running demo, capture `page.screenshot()` (D-01) |
| Defect register (hit-list) | Research artifact (`.planning/research/v1.14/`) | — | Milestone scope so 119-123 consume it without reaching an archived phase dir (D-05) |
| New judgment gates | Browser (Playwright rendered-DOM) | — | Active-state is a *rendered* property a grep can't see (D-11) |
| Inherited ratchet floor | API/Backend (ExUnit) + Browser (Playwright) + shell scripts | — | Verify-green only, no re-score (D-13/D-14) |

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Harness = agent-orchestrated Playwright walkthroughs against the running `make demo`,
  reusing existing Playwright infra. No new screenshot harness is built.
- **D-02:** Screenshots → gitignored `.planning/research/v1.14/.cache/screenshots/` as evidence
  attachments only; NOT a pixel-diff baseline. *(See Pitfall 1 — dir is not actually ignored yet.)*
- **D-03:** Three personas already seeded by `make demo` (`DemoData.reset!/0` → `Personas.seed!`);
  reached via `/ops/mail?tenant_id=<persona>` (northstar / fjordline-aps / helios-void). No new seed.
- **D-04:** Five adversarial hats: dev-evaluator, library-integrator, maintainer-debugging,
  operator/on-call-SRE-under-stress, security-reviewer. Walk every surface across
  320/375/768/1024/1440/wide × light/dark/system × happy/empty/loading/error/permission-denied/boundary.
  Rubric = STRESS-TEST-PROMPT.md (must not be diluted).
- **D-05:** Hit-list lives at `.planning/research/v1.14/DEFECT-REGISTER.md`, prioritized +
  severity-ranked, each finding citing surface/persona/viewport/theme/state + screenshot path.
- **D-06:** `{:phoenix_storybook, "~> 1.2", only: :dev}` in `reference/demo_app/mix.exs`, mounted
  dev-only in the demo router. Backend module + `*.story.exs` live IN the demo app, NOT in
  `mailglass_admin/lib/` (the `:files` glob would tarball them to adopters and break their compile).
- **D-07:** Sandbox stylesheet wired via `css_path` pointing at the served committed bundle
  (`/mail/css-<md5>` from `MailglassAdmin.Controllers.Assets :css`). No new Tailwind/esbuild build of
  our CSS; `app.css` unchanged. Omit `js_path` (static stories) ⇒ no esbuild watcher in `dev.exs`.
  Do NOT run `mix phx.gen.storybook` unmodified — hand-write the config module.
- **D-08:** Theme bridge — storybook applies CSS *classes* (`dark`/`light` via `color_mode`, or named
  `themes:`), but components key off `data-theme="mailglass-light|mailglass-dark"` on `mg-admin-root`.
  Bridge by setting `data-theme` on each story's rendered root from the theme assign (or a
  storybook-only alias shim). NEVER edit committed `app.css` (trips TokenParityTest + drift gate).
- **D-09:** phoenix_storybook v1.2 supports Phoenix 1.8 / LiveView 1.1. v1.0 rename: "Story" →
  "Variation", "StoryGroup" → "VariationGroup", files are `*.story.exs`. Ignore pre-1.0 tutorials.
- **D-10:** STORY-02: existing `/dev/mail/gallery` (`gallery_live.ex`) retained UNCHANGED as the
  structural-contract/ratchet surface. Storybook added alongside as the interactive review surface.
- **D-11:** Two new gates as Playwright rendered-DOM assertions (sibling of `structural.spec.js`):
  nav-active-correctness (`aria-current="page"` on `:overview`, Deliveries inactive) and
  no-nav-duplication (no `data-testid="operator-overview-nav"`). NOT greps, NOT pure Floki ExUnit.
- **D-12:** Gates are DRAFTED as pending/xfail in Phase 118 (documented end-state), NOT armed green.
  They turn green in Phase 119 (bug fixed) and are armed into the floor in Phase 123. Do NOT pull the
  119 nav fix into 118.
- **D-13:** "Inherit green" in 118 = verification run only. NO pillar re-score (Phase 123), NO arming
  new gates, storybook is never a ratchet gate.
- **D-14:** Inherited floor to verify-green: (1) ~26 conformance gates (`check-conformance.sh`);
  (2) 54-cell aesthetic baseline (`ratchet_baseline_test.exs`); (3) 9-cell axe baseline
  (`axe_baseline_test.exs` + `e2e/axe-baseline.spec.js`); (4) 24-item Bucket-A
  (`bucket_a_coverage_test.exs`); (5) persona drift-guard (`persona_drift_guard_test.exs` +
  `persona_cohort_test.exs`).

### Claude's Discretion
- Exact story-file inventory (which primitives/groups/pages first) — guided by STRESS-TEST-PROMPT
  fractal scope (foundations → primitives → groups → pages).
- `color_mode: true` vs `themes:` — pick whichever cleanly drives `data-theme` per D-08.
- Screenshot-cell sampling strategy (full Cartesian vs prioritized representative cells).

### Deferred Ideas (OUT OF SCOPE)
- Consolidating `/dev/mail/gallery` into phoenix_storybook (migrate ratchet testids) — future req only
  if the two prove redundant.
- Arming new judgment gates into the floor + pillar re-score — Phase 123, not 118.
- Fixing the false-active-nav bug + removing redundant nav cards — Phase 119, not 118.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| METHOD-01 | Persona-critic harness + prioritized screenshot-backed defect register | D-01..D-05 validated: Playwright infra exists (`reference/demo_app/assets/`), personas seeded by `make demo`, register path is a research artifact. Concrete screenshot seam + sampling strategy below. |
| METHOD-02 | Two new judgment gates (nav-active-correctness, no-nav-duplication) drafted; inherit v1.13 floor green | D-11/D-12 validated: bug sites confirmed at exact lines; accent-allowlist Playwright seam keys off `[aria-current='page']`; `test.fixme` pattern for drafted gates. Floor inventory (D-14) all five artifacts confirmed present. |
| STORY-01 | phoenix_storybook dev-only with committed `app.css` as sandbox stylesheet | D-06/D-07 validated: dep is `only: :dev` in demo `mix.exs`; `css_path` is a remote URL string (hexdocs); served bundle route `/mail/css-<md5>` confirmed; no `app.css` mutation. |
| STORY-02 | Keep `/dev/mail/gallery`; add storybook alongside | D-10 validated: `gallery_live.ex` is the ratchet surface; storybook is additive in the demo router. |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix_storybook` | `~> 1.2` (1.2.0, published 2026-06-11) | Dev-only interactive component review surface | The canonical Phoenix component storybook; v1.2 aligns with Phoenix 1.8 / Tailwind v4 / LiveView 1.1 [VERIFIED: hex `mix hex.info`, 1.59M all-time downloads] |
| `@playwright/test` | `^1.59.1` (already installed) | Browser walkthroughs + `page.screenshot()` + rendered-DOM gates | Existing infra (`reference/demo_app/assets/`, `mailglass_admin/e2e/`); no new dep [VERIFIED: codebase] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| (none new) | — | — | Phase reuses all existing test/build infra; the only new dep is `phoenix_storybook` |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `phoenix_storybook` | A hand-rolled gallery (already have `/dev/mail/gallery`) | Locked by MILESTONE-SEED decision 4; gallery is retained as the ratchet surface, storybook is the interactive review surface (D-10) |
| `color_mode: true` (class-based) | `themes:` named-theme keys | Both apply *classes*, not `data-theme`; per-variation template `data-theme` is cleaner than either picker (see D-08 finding) |

**Installation (D-06):**
```elixir
# reference/demo_app/mix.exs deps/0
{:phoenix_storybook, "~> 1.2", only: :dev}
```

**Version verification:** `mix hex.info phoenix_storybook` → `1.2.0 (2026-06-11)`, all-time downloads
1,592,791, last-7-days 7,677. Mature, actively maintained. [VERIFIED: hex registry]

## Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `phoenix_storybook` | hex.pm | 1.2.0 published 2026-06-11; line since 0.8.x (2025) | 1.59M all-time / ~7.7k/wk | github.com/phenixdigital/phoenix_storybook | OK | Approved — maintained, high-trust, ecosystem-standard |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

*Note: `mix hex.audit` / `package-legitimacy check` seam not run in this sandboxed session; verification
done via `mix hex.info` (registry presence, download volume, version cadence) + known-good upstream
(`phenixdigital`, the maintainer org behind phoenix_storybook). The planner may add a
`checkpoint:human-verify` before `mix deps.get` if policy requires the seam, but this is the canonical
Phoenix storybook package — not a hallucination risk.*

## Architecture Patterns

### System Architecture Diagram

```
                          ┌─────────────────────────────────────────────┐
   make demo (Docker)     │  demo app  (MailglassDemoWeb.Endpoint :4015) │
   container port 4015    │                                             │
   host ${HTTP_PORT:-4015}│  /ops/mail?tenant_id=<persona>  ──► OperatorLive (admin surfaces)
                          │  /dev/mail/gallery              ──► GalleryLive (ratchet surface, KEEP)
                          │  /dev/storybook  (NEW, :dev)    ──► live_storybook → backend module
                          │       │                              │
                          │       │ css_path "/mail/css-<md5>" ──┘ (committed app.css, served)
                          │       │ stories: *.story.exs (in demo app content_path)
                          └───────┼─────────────────────────────────────┘
                                  │
   Playwright (D-01)  ────────────┘
   page.goto(DEMO_BASE_URL + route)
   page.screenshot() per cell
        │
        ▼
   .planning/research/v1.14/.cache/screenshots/<surface>-<persona>-<vw>-<theme>-<state>.png
        │  (read back by critic agents)
        ▼
   .planning/research/v1.14/DEFECT-REGISTER.md  (prioritized, severity-ranked hit-list)
        │
        ▼
   Phases 119-123 consume the register (Phase 119 = keystone shell redesign)

   Parallel, independent:
   - e2e/judgment.spec.js (NEW): nav-active-correctness + no-nav-duplication, test.fixme (drafted)
   - verify-green: check-conformance.sh + 4 ExUnit baseline tests + axe spec (D-14)
```

### Recommended Project Structure
```
reference/demo_app/
├── mix.exs                                  # + {:phoenix_storybook, "~> 1.2", only: :dev}
├── lib/mailglass_demo_web/
│   ├── router.ex                            # + storybook_assets() + live_storybook (dev-only scope)
│   └── storybook.ex                         # NEW backend module (use PhoenixStorybook, ...)
├── storybook/                               # NEW content_path — *.story.exs live here
│   ├── primitives/
│   │   ├── nav_link.story.exs
│   │   ├── stat_card.story.exs
│   │   └── ... (foundations → primitives → groups → pages, planner's inventory call)
│   └── ...
└── assets/e2e/
    └── (existing cohort.spec.js, demo.spec.js — screenshot seam reuses this harness)

mailglass_admin/e2e/
└── judgment.spec.js                         # NEW: drafted (test.fixme) nav gates (D-11/D-12)

.planning/research/v1.14/
├── DEFECT-REGISTER.md                       # NEW deliverable (D-05)
└── .cache/screenshots/                      # gitignored evidence (D-02 — MUST add .gitignore)
```

### Pattern 1: phoenix_storybook minimal hand-written setup (avoids the watcher)
**What:** Wire storybook without `mix phx.gen.storybook` so no `storybook.css`/`storybook.js` build
path or watcher is introduced (D-07).
**When to use:** STORY-01 task.
**Example:**
```elixir
# reference/demo_app/lib/mailglass_demo_web/router.ex — add to the existing dev-only "/dev" scope
# Source: https://phoenix-storybook.hexdocs.pm/setup.html
import PhoenixStorybook.Router   # alongside existing `import MailglassAdmin.Router`

scope "/" do
  storybook_assets()             # serves storybook's OWN prebuilt explorer assets (shipped in the hex pkg)
end

scope "/dev" do
  pipe_through(:browser)
  live_storybook "/storybook", backend_module: MailglassDemoWeb.Storybook
  # ... existing mailglass_admin_routes("/mail", ...) stays
end
```
```elixir
# reference/demo_app/lib/mailglass_demo_web/storybook.ex — NEW
# Source: https://phoenix-storybook.hexdocs.pm/setup.html + sandboxing.html
defmodule MailglassDemoWeb.Storybook do
  use PhoenixStorybook,
    otp_app: :mailglass_demo,
    content_path: Path.expand("../../storybook", __DIR__),
    # css_path is a REMOTE URL string served by our own endpoint — points at the
    # committed admin bundle route. NOT a filesystem path, NOT a new build. (D-07)
    # Source: sandboxing.html — "remote path ... served by your own application endpoint"
    css_path: "/dev/mail/" <> "css-" <> MailglassAdmin.Controllers.Assets.css_hash(),
    # js_path OMITTED (D-07): stories are static markup ⇒ no esbuild watcher in dev.exs
    sandbox_class: "mg-admin-root"
end
```
> **css_path note:** the live admin layout builds the URL via
> `MailglassAdmin.Layouts.css_url/1` → `mounted_asset_url(assigns, "css-" <> css_hash())` against
> the mount point. The storybook is mounted under a *different* path than `/mail`, so the URL must be
> an absolute path to the served route. The exact prefix is the admin mount (`/dev/mail`) where
> `__asset_routes__` emits `get "/css-:md5", ...`. The planner should resolve the literal at compile
> time from `MailglassAdmin.Controllers.Assets.css_hash/0` (the layout already does this) and confirm
> the served path by curling `/dev/mail/css-<hash>` against a running demo during the verify step.
> [VERIFIED: codebase — `controllers/assets.ex:114`, `layouts.ex:28`, `router.ex:288`]

### Pattern 2: data-theme bridge via per-variation template (D-08)
**What:** Components read `data-theme="mailglass-light|mailglass-dark"` on `mg-admin-root`
(`operator/shell.ex:219`). phoenix_storybook's `color_mode: true` applies a `dark` *class*, never
`data-theme`. Bridge at the **story template level**: render each variation's root wrapper with the
explicit `data-theme` attribute.
**When to use:** every `*.story.exs` whose component is theme-sensitive.
**Recommendation:** Prefer **template-level `data-theme` per variation** over the storybook color-mode
picker. Define paired light/dark variations (mirrors the existing gallery's
`gallery-<component>-<state>` + `[data-theme="mailglass-<theme>"]` wrapper convention in
`structural.spec.js:403-407`). This needs **no** `app.css` edit and **no** alias shim, so it cannot
trip TokenParityTest or the `priv/static` drift gate.
**Example (shape — exact `.story.exs` API per hexdocs v1.2):**
```elixir
# storybook/primitives/stat_card.story.exs
defmodule Storybook.Primitives.StatCard do
  use PhoenixStorybook.Story, :component
  def function, do: &MailglassAdmin.Components.stat_card/1

  def variations do
    [
      %Variation{
        id: :light,
        # wrap the rendered component root with data-theme="mailglass-light"
        # (template slot / container), so the component resolves light tokens
        attributes: %{...},
        slots: [...]
      },
      %Variation{id: :dark, attributes: %{...}, slots: [...]}  # data-theme="mailglass-dark"
    ]
  end
end
```
> The exact mechanism for setting a wrapper attribute per-variation in v1.2 (template option vs a
> container element in the rendered slot) is an implementation detail the planner should pin from the
> v1.2 `PhoenixStorybook.Story` docs during the storybook task. If color_mode is used INSTEAD, set
> `color_mode_sandbox_dark_class` / `color_mode_sandbox_light_class` — but that still yields a *class*,
> not `data-theme`, so the components would not switch unless a class→`data-theme` rule existed in CSS
> (which we cannot add). **Therefore template-level `data-theme` is the recommended bridge.**
> [CITED: https://phoenix-storybook.hexdocs.pm/color_modes.html — `dark` class, not data-theme]

### Pattern 3: persona-critic screenshot seam (D-01/D-03)
**What:** A small Playwright screenshot script (NOT a new harness) driving the running `make demo`,
iterating cells, saving PNGs the critic agents read back.
**Concrete seam:** add a screenshot spec under `reference/demo_app/assets/e2e/` (e.g.
`persona-screenshots.spec.js`) OR a standalone `page.screenshot()` script run via the existing
`@playwright/test` runner. Drive against `DEMO_BASE_URL` (the demo compose sets
`DEMO_BASE_URL: http://demo:4015`; the host runner uses `http://127.0.0.1:${PORT:-4015}` per
`playwright.config.cjs:4-5`).
**Persona→route routing (D-03):** `/ops/mail?tenant_id=<persona>` where persona ∈
`northstar` (many/high-count/error), `fjordline-aps` (one/long-ID/non-ASCII/null),
`helios-void` (zero-data, intentionally absent from the tenant switcher). Theme via `?theme=light|dark`
or absence-of-param + `emulateMedia({colorScheme:'dark'})` for system (the `themeQuery` /
`applyThemeEmulation` pattern already in `structural.spec.js:688-704`). Viewport via
`page.setViewportSize({width, height})`.
**Example:**
```js
// reference/demo_app/assets/e2e/persona-screenshots.spec.js (illustrative)
const { test } = require("@playwright/test");
const path = require("path");
const OUT = path.join(__dirname, "../../../../.planning/research/v1.14/.cache/screenshots");

const personas = ["northstar", "fjordline-aps", "helios-void"];
const viewports = [320, 375, 768, 1024, 1440];
const themes = ["light", "dark"];                 // + system via emulateMedia
const surfaces = ["", "/inbound"];                // overview/deliveries + inbound; add preview/gallery/storybook

for (const persona of personas)
  for (const vw of viewports)
    for (const theme of themes)
      for (const surface of surfaces)
        test(`shot ${persona} ${vw} ${theme} ${surface || "overview"}`, async ({ page }) => {
          await page.setViewportSize({ width: vw, height: 900 });
          // (auth/login as the existing operator.spec.js openOperator does, if surface needs a session)
          await page.goto(`/ops/mail${surface}?tenant_id=${persona}&theme=${theme}`);
          await page.screenshot({ path: `${OUT}/${surface.replace("/","") || "overview"}-${persona}-${vw}-${theme}.png`, fullPage: true });
        });
```
> **Auth note:** the live operator surfaces require an authenticated session. The CI Playwright specs
> use demo-only `/ops/browser-reset` + `/ops/browser-login` helper routes (`operator.spec.js:17-40`).
> Against `make demo` the human-facing entry is `/demo/login?return_to=/ops/mail?tenant_id=northstar`
> (Makefile:43). The planner should confirm which login path the screenshot seam uses against the
> Docker demo (the browser-* test routes exist in the demo's `/ops` scope via
> `mailglass_operator_routes` test affordances — verify availability in dev env, not just :test).

**Sampling strategy recommendation (Claude's discretion, D-04 matrix):** the full Cartesian product is
3 personas × 6 viewports × 3 themes × 6 states × ~5 surfaces = **~1,620 cells** — too many to author
findings against. Recommend a **prioritized representative sample**, weighted by the
biggest-impact-first surface order (App-shell+Overview #1, Deliveries #2):
- **Anchor cells (always shoot):** each surface × {northstar, fjordline-aps, helios-void} × {375, 1440}
  × {light, dark} = the 4-corner viewport/theme square that catches most layout/contrast defects.
- **Targeted state cells:** error/empty/permission-denied only where a persona naturally produces them
  (helios-void = empty/zero; northstar = error/high-count; fjordline-aps = long-ID/non-ASCII/null).
- **System theme + 320 + 768/1024:** spot-check on the #1/#2 surfaces only.
This keeps the register-authoring tractable (~80-120 evidence shots) while honoring the binding matrix
intent. The register cites the exact cell per finding (D-05), so coverage is auditable.

### Pattern 4: drafted judgment gates (D-11/D-12)
**What:** Two rendered-DOM assertions as a sibling of `mailglass_admin/e2e/structural.spec.js`, drafted
pending so they do NOT run green against the live bug.
**When to use:** METHOD-02 task.
**Example:**
```js
// mailglass_admin/e2e/judgment.spec.js (NEW) — DRAFTED per D-12
const { test, expect } = require("@playwright/test");

// nav-active-correctness — DRAFTED: turns green in Phase 119 when active={:overview} is wired.
// Today operator_live.ex:349 hardcodes active={:deliveries}; arming green now would force
// weakening the assertion to pass on the bug. test.fixme marks the documented end-state.
test.fixme("Overview nav item renders active (aria-current=page); Deliveries inactive", async ({ page }) => {
  await openOverview(page);  // /ops/mail?tenant_id=... (overview view, no &view=deliveries)
  await expect(page.getByRole("navigation").getByRole("link", { name: "Deliveries" }))
    .not.toHaveAttribute("aria-current", "page");
  // end-state: an Overview nav item exists and carries aria-current="page"
  await expect(page.getByRole("navigation").getByRole("link", { current: "page" })).toBeVisible();
});

// no-nav-duplication — DRAFTED: turns green in Phase 119 when the redundant card block is deleted.
test.fixme("populated Overview does not render the redundant Navigate card block", async ({ page }) => {
  await openOverview(page);
  await expect(page.getByTestId("operator-overview-nav")).toHaveCount(0);
});
```
> **Pending mechanism:** Playwright `test.fixme(...)` marks a test as expected-to-fail/skip with the
> body NOT executed (it is reported as skipped, never red/green) — the idiomatic "documented but not
> armed" form. `test.skip(...)` is an alternative but `fixme` reads as "known-broken end-state pending
> a fix," matching D-12's intent precisely. The drafted spec is NOT added to any CI required lane in
> 118 (D-13). Phase 119 flips `test.fixme` → `test` when the bug is fixed; Phase 123 arms it into the
> ratchet floor. [VERIFIED: codebase accent-allowlist seam `structural.spec.js:11-17` keys off
> `[aria-current='page']`; ARIA-current pattern already used at `structural.spec.js:807-819`]

### Anti-Patterns to Avoid
- **Running `mix phx.gen.storybook` unmodified** — scaffolds a `storybook.css`/`storybook.js` build +
  watcher we deliberately avoid (D-07). Hand-write the backend module.
- **Editing `mailglass_admin/assets/css/app.css` (or the committed `priv/static/app.css`) to add a
  class→data-theme alias** — trips `TokenParityTest` and the `priv/static` drift gate
  (`mix verify.preview` runs `git diff --exit-code priv/static/`). Bridge in story templates instead.
- **Putting the backend module or stories under `mailglass_admin/lib/`** — the `:files` glob ships
  `lib` to adopters; a dev-only-dep module would tarball and fail their compile (D-06).
- **Arming the new gates green in 118** — would force weakening assertions to pass on buggy UI (D-12).
- **Full Cartesian screenshot sweep** — ~1,620 cells; author findings off a prioritized sample.
- **Pulling the Phase 119 nav fix into 118** — user-confirmed not to front-load the redesign.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Component preview surface | A custom LiveView gallery v2 | `phoenix_storybook` (D-06) + keep existing `gallery_live.ex` | Locked decision; storybook ships the explorer prebuilt |
| Screenshot capture | A new screenshot harness | Existing `@playwright/test` + `page.screenshot()` (D-01) | Infra already exists in `reference/demo_app/assets/` and `mailglass_admin/e2e/` |
| Persona/seed data | A new seed path | `make demo` → `DemoData.reset!/0` → `Personas.seed!` (D-03) | Duplicating `Personas.seed!` risks the persona drift-guard (`persona_drift_guard_test.exs`) |
| Sandbox stylesheet | A new Tailwind/esbuild build of component CSS | `css_path` → served committed bundle `/mail/css-<md5>` (D-07) | Zero-Node adopter guarantee; `app.css` stays untouched |
| Active-nav correctness check | A grep/conformance gate | Playwright rendered-DOM `aria-current` assertion (D-11) | Active state is a *rendered* property; a hardcoded literal grep can't evaluate it |

**Key insight:** Nearly every capability this phase needs already exists in the repo. The phase is
*assembly + authoring*, not construction. The single genuinely new dependency is `phoenix_storybook`,
and its integration is config-only (no new asset build).

## Runtime State Inventory

> This is a tooling/method phase (adds a dev-only dep + test artifacts), not a rename/refactor. The
> categories below are checked for completeness; nothing requires data migration.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — no DB schema, key, or collection touched. Personas reuse existing seed (D-03). | None |
| Live service config | None — storybook is a dev-only route in the demo app; no external service config. | None |
| OS-registered state | None. | None |
| Secrets/env vars | None new. Screenshot seam reads `DEMO_BASE_URL`/`PORT` (already used by `playwright.config.cjs`). | None |
| Build artifacts | `reference/demo_app/mix.lock` gains the `phoenix_storybook` entry + transitive deps on `mix deps.get`. The committed `mailglass_admin/priv/static/app.css` is NOT rebuilt (D-07). | Commit only the intentional new-dep lock entries per the project's mix.lock policy; do NOT rebuild/commit `app.css`. |

## Common Pitfalls

### Pitfall 1: The screenshot cache dir is NOT actually gitignored (contradicts D-02)
**What goes wrong:** D-02 states `.planning/research/v1.14/.cache/screenshots/` is gitignored because
"`.planning/research/.cache/` is already gitignored." It is NOT. `git check-ignore -v` on a file in
that path returns nothing (NOT IGNORED); there is no `.gitignore` anywhere under `.planning/`; the
existing `.planning/research/.cache/` shows up as `?? .planning/research/.cache/` in `git status`
(untracked, not ignored). Without a fix, ~80-120 evidence PNGs would be staged/committed.
**Why it happens:** the assumption pass inferred ignore status from the untracked state, which looks the
same in `git status` but behaves differently — untracked files CAN be `git add`-ed accidentally
(e.g. `git add .` or the gsd commit seam that sweeps `.planning/`).
**How to avoid:** Wave-0 task — add a `.gitignore` (e.g. `.planning/research/.gitignore` with
`.cache/`, or a root-level entry `\.planning/research/**/.cache/`). Verify with
`git check-ignore -v .planning/research/v1.14/.cache/screenshots/x.png`. [VERIFIED: codebase —
`git check-ignore` returned NOT IGNORED; no `.gitignore` under `.planning`]
**Warning signs:** `git status` shows screenshot PNGs as untracked; the gsd commit seam (known to sweep
all dirty `.planning/` paths per project memory) would stage them.

### Pitfall 2: The new no-nav-duplication gate contradicts an existing live test
**What goes wrong:** `mailglass_admin/e2e/operator.spec.js:352-368` (VERIF-02) currently asserts
`page.getByTestId("operator-overview-nav")` IS visible. The new `no-nav-duplication` gate (D-11)
asserts its **absence**. They don't clash in Phase 118 (the new gate is `test.fixme`/drafted, not run),
but in Phase 119 — when the card is removed — the existing VERIF-02 test will START FAILING unless it
is updated in the same phase.
**Why it happens:** the redundant "Navigate" card was a deliberate VERIF-02 deliverable in a prior
milestone; this milestone reverses that decision.
**How to avoid:** the Phase 118 register entry for the redundant-nav defect MUST flag
`operator.spec.js:352-368` as a test that Phase 119 must update/remove when deleting the card. Document
this cross-reference in `DEFECT-REGISTER.md` so 119 doesn't get blindsided. [VERIFIED: codebase]
**Warning signs:** Phase 119 deletes `operator-overview-nav` and the operator browser gate goes red.

### Pitfall 3: The shell is correct; only the caller literal is the bug
**What goes wrong:** A planner might over-scope the Phase-119 fix into the shell. `operator/shell.ex`
already does `active={@active == :deliveries}` and `data-theme={if @dark_chrome, ...}` correctly. The
bug is solely `operator_live.ex:349` passing the literal `active={:deliveries}` regardless of `@view`,
and there's no `:overview` nav item to highlight. The register should name the precise site so 119's
fix is surgical (introduce an Overview nav item + pass `active={@view}`-equivalent), not a shell
rewrite. [VERIFIED: codebase — `shell.ex:235`, `operator_live.ex:349`]
**How to avoid:** register the finding at `operator_live.ex:349` (caller), note shell is correct.

### Pitfall 4: Demo runs in Docker — screenshot seam must target the right base URL
**What goes wrong:** `make demo` is a Docker compose stack; the app listens on container port 4015,
host-mapped to `${MAILGLASS_DEMO_HTTP_PORT:-4015}`. The `demo_e2e` compose service sets
`DEMO_BASE_URL: http://demo:4015` (in-network). A host-run Playwright must use
`http://127.0.0.1:${PORT:-4015}`. Mismatched base URL = connection refused or wrong instance.
**How to avoid:** drive the screenshot seam via `make demo-e2e` (in-network `demo_e2e` service) OR set
`DEMO_BASE_URL`/`PORT` explicitly for a host run. The existing `playwright.config.cjs:4-5` already
honors `DEMO_BASE_URL`/`PORT`. [VERIFIED: codebase — `compose.demo.yml:37,50,81`, `playwright.config.cjs`]

### Pitfall 5: Persona auth + browser-* test routes may be :test-only
**What goes wrong:** the operator surfaces need a session. CI specs use `/ops/browser-reset` +
`/ops/browser-login` (demo affordances). If those routes are gated to `MIX_ENV=test`, they won't exist
in the `make demo` (`MIX_ENV=dev`) instance, and the screenshot seam can't authenticate.
**How to avoid:** confirm in the storybook/screenshot task whether the browser-* helper routes are
available in `:dev`, or use `/demo/login?return_to=/ops/mail?tenant_id=<persona>` (the human path,
Makefile:43). Resolve this before authoring the screenshot seam. [CITED: `operator.spec.js:17-40`,
`Makefile:43`]

## Code Examples

(See Patterns 1-4 above — all examples are codebase-grounded or hexdocs-cited.)

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| phoenix_storybook "Story"/"StoryGroup" modules | "Variation"/"VariationGroup", `*.story.exs` files | v1.0 (2026-03-03) | Ignore pre-1.0 tutorials (D-09) — the rename breaks old examples |
| `mix phx.gen.storybook` default scaffold (watcher + storybook.css/js) | Hand-written backend, `css_path` → existing served bundle | This phase (D-07) | No new asset build; zero-Node adopter guarantee preserved |
| Bottom-up structural-gate-verified review | Top-down JTBD/IA-led persona-critic loop | v1.14 milestone | Gates can't ask "is this redundant/coherent" — persona critics + register fill the gap |

**Deprecated/outdated:**
- Pre-1.0 phoenix_storybook "Story" API — renamed to "Variation" in v1.0 (D-09).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The exact `css_path` literal resolves to `/dev/mail/css-<hash>` (admin mount + asset route). | Pattern 1 | Storybook sandbox renders unstyled; fixable by curling the served route during verify — low risk, self-evident in the explorer. |
| A2 | The v1.2 `*.story.exs` per-variation API can set a wrapper `data-theme` (template/container). | Pattern 2 | If not, fall back to a storybook-only container element in the variation slot that carries `data-theme`; still no `app.css` edit. Medium risk — pin from v1.2 Story docs during the task. |
| A3 | `/ops/browser-login` (or `/demo/login`) is usable to authenticate the screenshot seam in `:dev`. | Pattern 3 / Pitfall 5 | If browser-* routes are :test-only, use `/demo/login`; resolve before authoring the seam. Low-medium risk. |
| A4 | `test.fixme` is the right "drafted/pending" primitive (skipped, never red/green). | Pattern 4 | If the project prefers `test.skip` with an annotation, swap — both satisfy D-12; cosmetic. Low risk. |

**These four are the only unverified items; all are low/medium risk with documented fallbacks.**

## Open Questions (RESOLVED)

Both items are functionally resolved with recommendations the plans implement; neither leaves an
execution-blocking fork. Carried into the plan as concrete tasks/discretion, not open decisions.

1. **Exact `css_path` literal for the storybook mount** — **RESOLVED:** hardcode
   `"/dev/mail/css-" <> MailglassAdmin.Controllers.Assets.css_hash()` (Plan 01 Task 2 implements this
   verbatim with a load-`/dev/storybook` verify step).
   - What we know: `__asset_routes__` emits `get "/css-:md5"`; layout builds it via
     `mounted_asset_url(assigns, "css-" <> css_hash())` relative to the admin mount (`/dev/mail`).
   - What was unclear: whether the storybook (mounted at `/dev/storybook`) can reference the
     `/dev/mail/css-<hash>` route directly as an absolute path — it can; it's a plain `<link>` URL.
   - Verify by loading `/dev/storybook` against a running demo; the explorer renders styled or not.

2. **Story-file inventory order (Claude's discretion)** — **RESOLVED:** foundations → primitives
   (nav_link, stat_card, theme_picker, badge — the gallery already enumerates these in
   `structural.spec.js:25-42`) → groups → pages, biggest-impact surface first (App-shell/Overview);
   implemented in Plan 01 Task 3. Stories are review aids, not gates — start small, expand as 119+ need.
   A discretion item per D-09, not a blocking unknown.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `phoenix_storybook` | STORY-01/02 | ✓ (hex) | 1.2.0 | none needed |
| `@playwright/test` | METHOD-01/02 | ✓ (installed) | ^1.59.1 | none |
| Docker + compose | `make demo` | (assumed on dev host) | — | run demo natively via `mix phx.server` in `reference/demo_app` |
| Node (dev-only) | Playwright + storybook explorer assets | (accepted per MILESTONE-SEED dec 4) | — | none — zero-Node is adopter-facing only |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** Docker (demo can run natively if compose is unavailable).

## Validation Architecture

> Nyquist validation applies — METHOD-02 and the floor inheritance are testable gates.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir) + `@playwright/test` ^1.59.1 (JS) |
| Config file | `reference/demo_app/assets/playwright.config.cjs`; `mailglass_admin/e2e/` (admin Playwright) |
| Quick run command | Floor scripts: `mailglass_admin/scripts/check-conformance.sh` |
| Full suite command | Per-artifact ExUnit + Playwright (see map below) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| STORY-01 | storybook mounts dev-only, sandbox styled by committed bundle | smoke | load `/dev/storybook` against `make demo`; assert styled render | ❌ Wave-0 (manual verify; optional `e2e/storybook-smoke.spec.js`) |
| STORY-01 | `app.css` unchanged (no drift) | gate | `cd mailglass_admin && mix verify.preview` (`git diff --exit-code priv/static/`) | ✅ exists |
| STORY-02 | `/dev/mail/gallery` retained unchanged | gate | `mailglass_admin/scripts/check-conformance.sh` + gallery ratchet tests | ✅ exists |
| METHOD-01 | defect register authored, screenshot-backed | artifact review | manual (register file populated + screenshots in cache) | ❌ Wave-0 (deliverable) |
| METHOD-02 | nav gates drafted, NOT armed green | gate | `judgment.spec.js` present with `test.fixme`; not in any required lane | ❌ Wave-0 (new file) |
| METHOD-02 | floor 1 — ~26 conformance gates | gate | `mailglass_admin/scripts/check-conformance.sh` | ✅ exists |
| METHOD-02 | floor 2 — 54-cell aesthetic baseline | gate | `cd mailglass_admin && mix test test/mailglass_admin/ratchet_baseline_test.exs` | ✅ exists |
| METHOD-02 | floor 3 — 9-cell axe baseline | gate | `mix test test/mailglass_admin/axe_baseline_test.exs` + `e2e/axe-baseline.spec.js` (Playwright) | ✅ exists |
| METHOD-02 | floor 4 — 24-item Bucket-A manifest | gate | `mix test test/mailglass_admin/bucket_a_coverage_test.exs` | ✅ exists |
| METHOD-02 | floor 5 — persona drift-guard | gate | `mix test test/mailglass_admin/persona_drift_guard_test.exs test/mailglass_admin/persona_cohort_test.exs` | ✅ exists |

### Sampling Rate
- **Per task commit:** `mailglass_admin/scripts/check-conformance.sh` (fast; the touched-area gate).
- **Per wave merge:** the four ExUnit baseline tests + the axe Playwright spec.
- **Phase gate:** all five floor artifacts green (verify-run only, no re-score) + new `judgment.spec.js`
  present-and-drafted + register populated + `app.css` drift-clean.

### Wave 0 Gaps
- [ ] `.planning/research/.gitignore` (or root entry) — ignore `.cache/` (Pitfall 1) — PREREQUISITE.
- [ ] `reference/demo_app/lib/mailglass_demo_web/storybook.ex` — backend module (STORY-01).
- [ ] `reference/demo_app/storybook/**/*.story.exs` — initial story inventory (STORY-01).
- [ ] `mailglass_admin/e2e/judgment.spec.js` — drafted nav gates `test.fixme` (METHOD-02).
- [ ] `reference/demo_app/assets/e2e/persona-screenshots.spec.js` (or a script) — screenshot seam (METHOD-01).
- [ ] `.planning/research/v1.14/DEFECT-REGISTER.md` — the deliverable (METHOD-01).
- [ ] Framework install: `cd reference/demo_app && mix deps.get` (pulls phoenix_storybook).

## Security Domain

> `security_enforcement` default-enabled. This phase adds a **dev-only** review surface and test
> artifacts; it ships nothing to adopters and touches no auth/crypto/data path.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Storybook + screenshots are dev-only; demo login is a demo affordance |
| V3 Session Management | no | — |
| V4 Access Control | yes (narrow) | Storybook MUST be mounted in the **dev-only `/dev` scope** (D-06), never in a prod-reachable pipeline — it exposes component internals. The demo router already isolates `/dev` (it's a demo app). |
| V5 Input Validation | no | Static stories; no user input |
| V6 Cryptography | no | — |
| V7 Errors/Logging — PII | yes (advisory) | Screenshots of `make demo` capture only seeded persona data (no real PII); cache is gitignored evidence (D-02). Do not screenshot any real-tenant instance. |

### Known Threat Patterns for {Phoenix dev-tooling}

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Storybook reachable in prod (info disclosure) | Information disclosure | `only: :dev` dep + dev-only router scope (D-06); the dep isn't even compiled in prod |
| Committed screenshots leaking data | Information disclosure | Gitignore the cache (Pitfall 1 fix); seeded-persona data only |

## Sources

### Primary (HIGH confidence)
- Codebase (direct read): `reference/demo_app/lib/mailglass_demo_web/router.ex`,
  `reference/demo_app/mix.exs`, `reference/demo_app/config/dev.exs`,
  `reference/demo_app/compose.demo.yml`, `reference/demo_app/assets/playwright.config.cjs`,
  `mailglass_admin/lib/mailglass_admin/operator_live.ex` (lines 349, 416-448),
  `mailglass_admin/lib/mailglass_admin/operator/shell.ex` (lines 219, 235),
  `mailglass_admin/lib/mailglass_admin/controllers/assets.ex` (lines 49-119),
  `mailglass_admin/lib/mailglass_admin/layouts.ex` (line 28),
  `mailglass_admin/lib/mailglass_admin/router.ex` (line 288),
  `mailglass_admin/e2e/structural.spec.js`, `mailglass_admin/e2e/operator.spec.js`,
  `mailglass_admin/scripts/check-conformance.sh`,
  `mailglass_admin/test/mailglass_admin/{ratchet_baseline,axe_baseline,bucket_a_coverage,persona_drift_guard,persona_cohort}_test.exs`,
  `reference/persona_spec/personas.ex`, `Makefile`.
- `mix hex.info phoenix_storybook` — v1.2.0 (2026-06-11), 1.59M all-time downloads [registry-verified].

### Secondary (MEDIUM confidence)
- https://phoenix-storybook.hexdocs.pm/setup.html — router macros, backend module, story location.
- https://phoenix-storybook.hexdocs.pm/sandboxing.html — `css_path` is a remote URL served by the app;
  `sandbox_class` scoping.
- https://phoenix-storybook.hexdocs.pm/color_modes.html — `color_mode: true` applies a `dark` *class*
  (not `data-theme`); `color_mode_sandbox_dark_class`/`light_class` overrides.

### Tertiary (LOW confidence)
- Exact v1.2 `PhoenixStorybook.Story` per-variation wrapper-attribute API (A2) — not fully pinned in
  this session; confirm from v1.2 Story docs during the storybook task.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — phoenix_storybook verified on hex; Playwright infra read in codebase.
- Architecture: HIGH — all integration points (router, asset route, shell theme contract, bug sites,
  floor artifacts) confirmed by direct file read.
- Pitfalls: HIGH — gitignore gap, test contradiction, Docker base-URL, shell-vs-caller all
  codebase-verified.
- Theme bridge / storybook variation API: MEDIUM — class-vs-data-theme confirmed (hexdocs); exact
  per-variation attribute mechanism (A2) pending the v1.2 Story docs.

**Research date:** 2026-06-26
**Valid until:** 2026-07-26 (stable; phoenix_storybook 1.2 is current, codebase is the live main)
