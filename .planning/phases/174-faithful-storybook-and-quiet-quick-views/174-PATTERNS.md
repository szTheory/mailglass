# Phase 174: Faithful Storybook and Quiet Quick Views - Pattern Map

**Mapped:** 2026-10-26  
**Files analyzed:** 14 candidate paths/seams (some new paths are intentionally unspecified)  
**Analogs found:** 12 / 14; two have no direct repository analog

## File Classification

| New/Modified File or Seam | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `mailglass_admin/lib/mailglass_admin/operator/quick_view.ex` | component | transform | `mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex` | exact sibling |
| `mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex` | component | transform | `mailglass_admin/lib/mailglass_admin/operator/quick_view.ex` | exact sibling |
| `reference/demo_app/lib/mailglass_demo_web/router.ex` | route | request-response | same router's Storybook macros | role-match; current mount placement is the defect |
| `reference/demo_app/dev/mailglass_demo_web/storybook.ex` | provider/config | transform | same module's sandbox configuration | exact |
| New Deliveries and Inbound quick-view stories under `reference/demo_app/storybook/` (exact filenames TBD) | provider/component story | transform | `reference/demo_app/storybook/primitives/stat_card.story.exs` | role-match |
| Shared production hook asset seam (exact file/route TBD), plus `mailglass_admin/lib/mailglass_admin/controllers/assets.ex` | utility/controller | event-driven; request-response for serving | `assets.ex` inline hooks and LiveSocket bootstrap; Storybook `js_path` config | partial; no isolated hook-only asset exists |
| Demo Storybook routing/font/theme receipt, likely extending `reference/demo_app/assets/e2e/persona-screenshots.spec.js` | test | request-response | same browser spec | exact |
| Admin quick-view geometry/focus checks, likely in `mailglass_admin/e2e/flows.spec.js` or `structural.spec.js` | test | request-response | `flows.spec.js` focus case and `structural.spec.js` target helper | exact behavior patterns; no quick-view geometry assertion yet |
| `mailglass_admin/e2e/axe-baseline.spec.js` | test/producer | batch | same producer | exact |
| `mailglass_admin/test/mailglass_admin/axe_baseline_test.exs` | test/comparator | batch | same comparator | exact |
| `mailglass_admin/docs/axe-baseline.json` or a small companion expected/executed manifest (path TBD) | config/evidence | batch | current `axe-baseline.json` | exact for rule-count baseline; no case manifest analog |
| `.github/workflows/ci.yml` and `scripts/run_demo_browser_evidence.sh` if evidence/cost reporting changes are needed | config/utility | batch | existing browser jobs and wrapper | exact command/evidence flow |
| Feedback-to-scenario disposition record, if this phase adds one | documentation | transform | `.planning/REQUIREMENTS.md` feedback coverage and owner review records | no executable ledger analog |

The new story filenames, hook-only asset path, and scenario-manifest path are not specified in research. Treat those as planning decisions; do not cite guessed paths as existing analogs. This phase owns UXF-11, STORY-03–06 and UIQ-05, with first retained-scenario and cost-pilot work carried forward for STORY-07/UIQ-07. The broader feedback ledger requirement UIQ-04 is assigned to Phase 178.

## Pattern Assignments

### Production quick views: `operator/quick_view.ex` and `inbound/quick_view.ex`

**Analogs:** Each component is the closest sibling for the other. Both are tracked production HEEx components, not Storybook previews.

**Assigns and rendering** (`operator/quick_view.ex:25-36`; Inbound equivalent at `inbound/quick_view.ex:19-30`):

```elixir
attr(:full_path, :string, required: true)
attr(:close_path, :string, required: true)
attr(:previous_path, :string, default: nil)
attr(:next_path, :string, default: nil)
attr(:position, :map, default: nil)

def quick_view(assigns) do
  ~H"""
```

**Shared control row** (`operator/quick_view.ex:65-91`; Inbound `:59-85`):

```heex
<.nav_button dir="prev" path={@previous_path} label="Previous delivery">
  <Components.icon name="hero-chevron-down" class="h-4 w-4 rotate-90" />
</.nav_button>
<span :if={@position} aria-live="polite" class="px-xs text-label tabular-nums text-secondary">
  {@position.index} of {@position.total}
</span>
<.nav_button dir="next" path={@next_path} label="Next delivery">
```

Active arrows currently use `mg-focus-ring btn btn-ghost min-h-11 min-w-11 border border-base-300` (`operator/quick_view.ex:201-211`; Inbound `:191-201`). Close is already unoutlined, named `Close quick view`, and `min-h-11 min-w-11` (`operator:83-91`; `inbound:77-85`). Keep the 44px floor, accessible names, focus treatment, position, and URL-patch navigation while adjusting idle visual weight.

**Boundary semantics to preserve:** Operator renders a labeled `aria-disabled="true"` span when a path is nil (`operator/quick_view.ex:188-199`). Inbound renders a disabled button, with a boundary `data-testid`, when a path is nil (`inbound/quick_view.ex:176-189`). These are intentionally different existing semantics; assert each surface's real boundary state rather than copying one into the other.

**Connected behavior analog:** `mailglass_admin/e2e/flows.spec.js:1409-1449` opens the operator quick view at 320px, checks dialog/position/content, keyboard traversal, Escape close, and focus return. It does not measure arrow target geometry. Reuse the DOM-driven approach for both surfaces and their boundaries.

**44px geometry analog** (`mailglass_admin/e2e/structural.spec.js:364-373`):

```js
async function assertTouchTarget(locator, label) {
  const target = locator.first();
  const box = await settledBoundingBox(target, label);
  expect(box, `${label} target-size box`).not.toBeNull();
  expect(Math.round(box.width), `${label} target-size width`).toBeGreaterThanOrEqual(44);
  expect(Math.round(box.height), `${label} target-size height`).toBeGreaterThanOrEqual(44);
}
```

`structural.spec.js:1258-1259` already applies this helper to the Inbound detail-back control. Use measured boxes for quick-view arrows and Close at an actual narrow viewport; CSS class presence alone is not the acceptance evidence.

### Prefixed Storybook routing: `reference/demo_app/lib/mailglass_demo_web/router.ex`

**Analog:** The current tracked router is the only local route-macro analog. Its asset macro is in a root scope, while the live Storybook macro is nested under `/dev` and receives only `/storybook` (`router.ex:4-32`):

```elixir
scope "/" do
  storybook_assets()
end

scope "/dev" do
  pipe_through(:browser)
  live_storybook("/storybook", backend_module: MailglassDemoWeb.Storybook)
end
```

The planned change must follow the pinned PhoenixStorybook 1.2.0 root-scope API and preserve the dev-only browser pipeline (`router.ex:44-51`):

```elixir
pipeline :browser do
  plug(:accepts, ["html"])
  plug(:fetch_session)
  plug(:fetch_live_flash)
  plug(:protect_from_forgery)
  plug(:put_secure_browser_headers)
end
```

Treat the present placement as the defect, not as a pattern to copy. `persona-screenshots.spec.js:191-234,276-288` is the browser analog for current direct `/dev/storybook/...` URLs and checking loaded story text/theme variations; it does not yet walk generated sidebar links or prove every prefix-preserving destination.

### Story provider, story metadata, CSS, and theme

**Backend analog:** `reference/demo_app/dev/mailglass_demo_web/storybook.ex:34-41` configures the Demo app's real Storybook content and Admin production stylesheet:

```elixir
use PhoenixStorybook,
  otp_app: :mailglass_demo,
  content_path: Path.expand("../../storybook", __DIR__),
  css_path: "/dev/mail/css-" <> MailglassAdmin.Controllers.Assets.css_hash(),
  sandbox_class: "mg-admin-root",
  title: "mailglass admin"
```

The module documents that stories stay in the Demo app and that `js_path` is currently omitted (`storybook.ex:25-40`). Extend this backend for the shared hook asset only after that asset's path/serving seam is decided; never point `css_path` at a new Storybook build.

**Story metadata analog:** `reference/demo_app/storybook/primitives/stat_card.story.exs:7-25,28-36` uses `PhoenixStorybook.Story, :component`, points `function/0` at the production component, wraps variations in production theme/root classes, and identifies cases with a stable variation ID plus attributes:

```elixir
use PhoenixStorybook.Story, :component
def function, do: &MailglassAdmin.Components.stat_card/1

def template do
  """
  <div data-theme="mailglass-light" class="mg-admin-root bg-base-100 text-base-content p-md">
    <.psb-variation/>
  </div>
  """
end

%Variation{id: :neutral_light, attributes: %{label: "Suppressions", value: 0, severity: :neutral}}
```

`reference/demo_app/storybook/_primitives.index.exs:1-8` shows sidebar metadata (`folder_name`, `folder_open?`, `folder_index`). Keep quick-view scenario IDs and labels specific to the two production components; existing stories demonstrate component rendering and variations, but none is a production quick-view story.

**Theme limitation:** `theme_picker.story.exs:10-43` sets fixed `data-theme="mailglass-light"` or `mailglass-dark` on each variation. Its `system_selected_light` and `system_selected_dark` IDs are visual picker states, not OS-following behavior. `axe-baseline.spec.js:51-76` already emulates `prefers-color-scheme` for its `system` cell, but currently exercises only the dark OS branch. There is no existing Storybook System-theme owner/resolution pattern or light-and-dark OS flip proof; record the chosen owner explicitly.

**Production type roles** (`mailglass_admin/assets/css/app.css:475-484`; six self-hosted faces/weights at `:152-186`):

```css
body { font-family: 'Inter', system-ui, -apple-system, sans-serif; }
h1, h2, h3 { font-family: 'Inter Tight', 'Inter', system-ui, -apple-system, sans-serif; }
code, pre, .mono { font-family: 'IBM Plex Mono', ui-monospace, monospace; }
```

Use these exact production roles as the browser receipt's expected values. `Assets.call(conn, :font)` serves only the allowlisted six WOFF2 assets (`mailglass_admin/lib/mailglass_admin/controllers/assets.ex:466-501`); receipt logic should verify responses and matching loaded faces/weights, not merely the CSS declaration.

### Shared production hook seam: Admin asset controller and Storybook backend

**Analogs:** `mailglass_admin/lib/mailglass_admin/controllers/assets.ex:64-100` defines `ModalFocusTrap` inline in `@live_socket_bootstrap`; it has `mounted()` and `destroyed()` callbacks. The same bootstrap creates/connects the Admin socket (`assets.ex:180-192`):

```js
const Hooks = {
  ModalFocusTrap: {
    mounted() { /* installs focusin handling */ },
    destroyed() { this.el.removeEventListener("focusin", this.handleFocusIn) }
  }
}

const liveSocket = new LiveView.LiveSocket("/live", Phoenix.Socket, { hooks: Hooks })
liveSocket.connect()
```

`storybook.ex:25-40` is the complementary integration seam: PhoenixStorybook currently has no `js_path`. The adapter must expose reusable hook definitions to Storybook's own client while leaving the Admin-only socket bootstrap out of the Storybook iframe. No tracked standalone hook asset or hook-only serving route exists, so the extraction filename and endpoint are unresolved; do not invent an existing path.

### Browser fidelity receipt and quick-view interaction evidence

**Demo receipt analog:** `reference/demo_app/assets/e2e/persona-screenshots.spec.js:237-315` checks the preview route, served CSS route/digest, committed bundle parity, Storybook rendering, and emits a JSON receipt keyed by candidate revision and URLs. Its digest core (`:255-264`) is:

```js
const sha256 = (bytes) => crypto.createHash("sha256").update(bytes).digest("hex");
const sourceCssSha256 = sha256(fs.readFileSync(sourceCssPath));
const builtCssSha256 = sha256(fs.readFileSync(builtCssPath));
const servedCssSha256 = sha256(servedCss);
expect(servedCssSha256).toBe(builtCssSha256);
```

It currently records source/built/served CSS digests and a narrow viewport, but not successful font responses, `FontFace` weight/status, computed type roles, theme owner, or both System OS outcomes. Extend this receipt shape with the scenario ID and browser-observed evidence; the separate direct-navigation test at `:191-234` is the closest prefix/story metadata test.

**Storybook browser command:** `scripts/run_demo_browser_evidence.sh:4-8,34-48,74-99` allocates isolated ports and a Compose project, exports the candidate revision, runs the Demo browser project, validates its evidence, and cleans up the services. `reference/demo_app/assets/package.json:4-10` keeps Demo dependencies to Playwright; `@axe-core/playwright` is already in Admin's lockfile/package (`mailglass_admin/package.json:4-10`). Research leaves the exact no-new-dependency Demo-hosted axe runner path unresolved.

### Accessibility producer, comparison, and negative tests

**Producer analog:** `mailglass_admin/e2e/axe-baseline.spec.js:206-227` currently summarizes node counts per rule and lets scan failures propagate:

```js
const { test, expect } = require("@playwright/test");
const { AxeBuilder } = require("@axe-core/playwright");

function summarizeViolations(violations) {
  const rules = {};
  let total = 0;
  for (const v of violations) {
    const n = v.nodes.length;
    rules[v.id] = (rules[v.id] || 0) + n;
    total += n;
  }
  const sortedRules = Object.fromEntries(Object.keys(rules).sort().map(k => [k, rules[k]]));
  return { total, rules: sortedRules };
}
```

Each producer test asserts overlay presence for the two modal-backed surfaces (`:222-263`). When persisting, `afterAll` fails on any missing surface/theme cell and writes only `{total, rules}` (`:267-319`). Keep the no-swallowed-failure and nonempty expected-case guards, but add rule/target/scenario-state fingerprints and an explicit expected/executed record. Existing JSON is rule-count-only and cannot supply those identities.

**Comparator analog:** `mailglass_admin/test/mailglass_admin/axe_baseline_test.exs:51-97,144-255,265-319` requires nine surface/theme cells, validates numeric totals/rule maps, prevents same-run self-comparison, and compares per-cell/per-rule counts. Its verify-by-construction tests already cover rising total, rule swap at a flat total, rising rule count, missing cells, malformed rules maps, and clean improvement (`:160-245`). Extend this fail-closed style to missing/duplicate/failed/zero/incomplete expected executions and separately represented `incomplete` axe results; do not replace its negative tests with only a happy-path receipt check.

`mailglass_admin/docs/axe-baseline.json:1-12,68-80` is the current artifact shape: `schema_version`, `prior`/`current` `run_id`, and per-surface/theme `{total, rules}`. It contains no target selector or scenario/state fields. A companion manifest can be small and phase-specific; research rejects a generic test engine.

### CI evidence and cost pilot

**Commands and scripts:**

```bash
cd mailglass_admin && npm run test:operator-browser
bash scripts/run_demo_browser_evidence.sh
cd mailglass_admin && mix test test/mailglass_admin/axe_baseline_test.exs
```

`mailglass_admin/package.json:4-6` shows the Admin command builds assets and runs one-worker Playwright. `.github/workflows/ci.yml:954-1040` runs that job with Postgres and uploads timeout evidence. The Demo evidence job runs the wrapper (`ci.yml:1042-1068`). The current `ci_green` policy's inputs at `ci.yml:1431-1483` omit both browser jobs; research also observed required main contexts `CI Green` and `Guard Release Trigger` on 2026-10-26. Treat any new check as advisory/required only after the cold/warm cost pilot and an explicit aggregate-policy change, and record setup time, wall time, runner-minutes, case coverage and artifact disposition.

## Shared Patterns

### Production presentation and interaction

**Sources:** `mailglass_admin/lib/mailglass_admin/operator/quick_view.ex:65-91,188-211`; `mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex:59-85,176-201`; `mailglass_admin/e2e/flows.spec.js:1409-1449`; `mailglass_admin/e2e/structural.spec.js:364-373`.

Keep production components as the source rendered in Storybook. Preserve position, Close, names, keyboard/focus behavior, and each component's boundary semantics while quieting the arrows. Assert actual target boxes using the existing settled-box helper and assert connected navigation/focus in browser tests.

### Feedback and scenario traceability

**Sources:** `.planning/todos/2026-10-26-owner-review-health-preview-controls.md:20,24-29`; `.planning/REQUIREMENTS.md:20,57-69,92-105`; `.planning/research/ui-quality-engine/SCOPING-EVIDENCE.md:42-56`.

The latest owner record says quick-view arrows look bulky and explicitly preserves generous targets, focus/hover, disabled boundaries, names and keyboard use. `REQUIREMENTS.md` maps “Quiet quick-view arrows on both surfaces” to UXF-11 and maps Storybook feedback to STORY-03–07. Reuse these planning records as the trace source and link retained scenario IDs to the owning requirement. There is no executable feedback ledger analog; do not infer a new findings database from the existing axe baseline.

### Evidence should fail closed and name what it measured

**Sources:** `mailglass_admin/e2e/axe-baseline.spec.js:222-319`; `mailglass_admin/test/mailglass_admin/axe_baseline_test.exs:51-97,144-255`; `reference/demo_app/assets/e2e/persona-screenshots.spec.js:255-315`.

Preserve direct producer failures, required-case completeness, unique run identity, deterministic output and comparator negative tests. The phase adds the missing identity layer (scenario/state, target, expected/executed status, incomplete triage) and font/theme/hook receipt fields; no old aggregate count alone can close those criteria.

## No Analog Found

| File or pattern | Role | Data Flow | Reason |
|---|---|---|---|
| Expected/executed scenario manifest with stable axe target/state fingerprints (path TBD) | config/evidence | batch | Existing axe artifact records only totals and rule counts; no case execution manifest or target/state fingerprint schema exists. |
| Executable feedback-to-scenario ledger | documentation/test support | transform | Current traceability lives in requirements and research/owner feedback docs; no code ledger exists. UIQ-04 is assigned to Phase 178. |

**Open seams to carry into planning:** exact shared hook asset/route; which iframe layer owns System resolution and both OS outcomes; how the Admin-installed axe adapter scans the Demo-hosted Storybook; which measured browser job is promoted into required CI; and the paths/names of the small retained stories/manifest. Research identifies these as unknowns rather than existing patterns.

## Metadata

**Analog search scope:** `mailglass_admin/lib/mailglass_admin/{operator,inbound,controllers}`, `mailglass_admin/assets/css`, `mailglass_admin/e2e`, `mailglass_admin/test/mailglass_admin`, `mailglass_admin/docs`, `reference/demo_app/lib`, `reference/demo_app/dev`, `reference/demo_app/storybook`, `reference/demo_app/assets/e2e`, `scripts`, `.github/workflows`, and planning feedback/research records.

**Tracked-source gate:** Every source-code analog named above was verified with `git ls-files -- <path>`; no ignored runtime mirror path is used.

**Pattern extraction date:** 2026-10-26. No test, browser suite, or cost measurement was run.
