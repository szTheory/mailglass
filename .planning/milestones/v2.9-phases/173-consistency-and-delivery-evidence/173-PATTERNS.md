# Phase 173: Consistency and Delivery Evidence - Pattern Map

**Mapped:** 2026-10-09  
**Files analyzed:** 11 likely touched files/surfaces  
**Analogs found:** 11 / 11

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `mailglass_admin/docs/design-system.md` | documentation | reference/transform | `mailglass_admin/assets/css/app.css` + `brandbook/tokens.css` | exact ownership relationship |
| `mailglass_admin/test/mailglass_admin/token_parity_test.exs` | test | file-I/O / transform | same file; `mailglass_admin/test/mailglass_admin/preview/capture_manifest_test.exs` | exact |
| `mailglass_admin/dev/mailglass_admin/preview/capture_manifest.ex` | utility | transform / file-I/O | same module | exact |
| `mailglass_admin/test/mailglass_admin/preview/capture_manifest_test.exs` | test | file-I/O / transform | same file | exact |
| `reference/demo_app/assets/e2e/demo.spec.js` (or focused existing Playwright spec) | test | request-response / browser capture | same file; `reference/demo_app/assets/e2e/persona-screenshots.spec.js` | exact |
| `reference/demo_app/assets/scripts/check-demo-browser-evidence.cjs` | utility | file-I/O / transform | same file | exact |
| `scripts/run_demo_browser_evidence.sh` | utility | process lifecycle / file-I/O | same script | exact |
| `mailglass_admin/dev/mix/tasks/mailglass_admin.preview.capture.ex` | utility/task | request-response / file-I/O | same Mix task | exact |
| `README.md` and/or `reference/demo_app/README.md` | documentation | reference | `reference/demo_app/README.md` | role-match |
| `mailglass_admin/lib/mailglass_admin/gallery_live.ex` and `reference/demo_app/dev/mailglass_demo_web/storybook.ex` | component/config | render | same files | exact |
| `.github/workflows/ci.yml` | config | event-driven | same workflow | exact; preserve current topology |

The last three rows are existing review/delivery surfaces whose inventory, route, or status may be documented or checked. Phase decisions do not call for restructuring them. Avoid editing them unless planning identifies a specific, verifiable gap.

## Pattern Assignments

### `mailglass_admin/docs/design-system.md` (documentation, reference/transform)

**Sources:** `brandbook/brand-book.md`, `brandbook/tokens.css`, and `mailglass_admin/assets/css/app.css` are the ownership chain; the current guide itself is the closest format/style analog.

The guide already states the intended separation: brandbook owns voice/palette; this document describes implementation mechanics (lines 3-6). Its CSS architecture section identifies the source and generated bundle/build task and says the committed bundle must be rebuilt with source changes (lines 15-29). The token tables at lines 41-68 and visual audit loop at lines 123-155 contain the stale claims to reconcile. Source CSS shows the actual semantic mapping in `mailglass_admin/assets/css/app.css:28-95` and current typography/spacing scale at `:97-126`.

**Copy/keep:** preserve the current ownership framing and mechanics-oriented headings. Take values from shipped source CSS and token owners; do not create a second token inventory or treat historical visual scores as acceptance. The current token parity test is a model for a focused contract check: read canonical files, compare explicit mappings, and fail with an actionable message (`mailglass_admin/test/mailglass_admin/token_parity_test.exs:22-50,185-232`).

### `mailglass_admin/test/mailglass_admin/token_parity_test.exs` (test, file-I/O/transform)

**Analog:** same file, particularly lines 22-50, 97-107, 109-163, and 185-240.

**Imports/setup pattern** (lines 20-50, abbreviated):

```elixir
use ExUnit.Case, async: true

@css_path Path.join([Application.app_dir(:mailglass_admin, "priv"), "static", "app.css"])
@css_source_path Path.expand("../../assets/css/app.css", __DIR__)
@tokens_path Path.expand(Path.join([__DIR__, "..", "..", "..", "brandbook", "tokens.json"]))

setup_all do
  assert File.exists?(@tokens_path), "tokens.json not found at #{@tokens_path} — run from mailglass_admin/"
  {:ok, tokens: Jason.decode!(File.read!(@tokens_path))}
end
```

The test uses a deliberate explicit mapping as the contract and compares source, built CSS, and token oracle. For any new guide/surface parity assertion, follow this focused source-read plus precise mismatch style; avoid a generic documentation parser or a new dependency. Keep assertions robust to harmless prose changes and test the actual mismatch that should block.

### `mailglass_admin/dev/mailglass_admin/preview/capture_manifest.ex` (utility, transform/file-I/O)

**Analog:** same module, lines 8-17, 33-79, 81-118, and 136-166.

**Core pattern** (lines 40-78):

```elixir
def write_from_states!(states, skipped, opts) when is_list(states) and is_list(skipped) do
  output_dir = Keyword.fetch!(opts, :output_dir)
  sha_mode = Keyword.get(opts, :sha_mode, :identity)
  manifest_path = Keyword.fetch!(opts, :manifest_path)
  checkpoint_path = Keyword.fetch!(opts, :checkpoint_path)

  entries = build_entries(states, output_dir, sha_mode)
  write!(entries, skipped, manifest_path: manifest_path, checkpoint_path: checkpoint_path)
end
```

The module normalizes and sorts entries before serialization, writes manifest and checkpoint from one normalized data set, and makes the claim boundary explicit. Existing `:files` mode hashes screenshot bytes, whereas `:identity` hashes scenario fields (`:95-118`); keep these meanings separate. Extend the existing per-capture/candidate records rather than adding a parallel evidence catalog. Reject missing or unsafe required provenance at the narrowest existing contract boundary; never silently substitute identity hash for required file-byte proof.

### `mailglass_admin/test/mailglass_admin/preview/capture_manifest_test.exs` (test, file-I/O/transform)

**Analog:** same file, lines 7-100.

**Test pattern:** create unique temporary output directories (`:105-115`), invoke the public manifest writer with explicit paths (`:20-26`), decode the emitted JSON, then assert schema, claim boundary, counts, sort order, and byte-for-byte repeatability (`:28-100`). This is the appropriate home and style for valid and fail-closed incomplete/empty-record cases. Keep fixtures synthetic (`HappyMailer`); do not include real message data in retained artifacts.

### `reference/demo_app/assets/e2e/demo.spec.js` (test, request-response/browser capture)

**Analog:** same file (`:1-27`, `:29-37`, `:103-128`, `:290-326`). `reference/demo_app/assets/e2e/persona-screenshots.spec.js:49-93,139-150` is a secondary analog for bounded theme/viewport sampling and seeded reset reuse.

**Imports/reset pattern** (`demo.spec.js:1-3,29-37`):

```javascript
const { test, expect } = require("@playwright/test");
const fs = require("node:fs");
const path = require("node:path");

test.beforeEach(async ({ request }) => {
  const response = await request.post("/demo/evidence/reset", {
    headers: { "x-mailglass-demo-reset-token": process.env.DEMO_EVIDENCE_RESET_TOKEN || "" },
  });
  expect(response.ok()).toBeTruthy();
});
```

Use seeded/synthetic state, existing configured base URL and reset seam, and accessible role/text assertions. For selected captures pair `expect` assertions with bounding-box or `page.evaluate` geometry checks, then save a small representative screenshot set. `demo.spec.js:14-27,59-99,103-128` demonstrates that pairing. Avoid treating screenshots as the interaction or accessibility assertion, avoid a Cartesian viewport/theme sweep, and don't label browser email rendering as delivered-client compatibility.

### `reference/demo_app/assets/scripts/check-demo-browser-evidence.cjs` (utility, file-I/O/transform)

**Analog:** same file, lines 1-75.

**Core contract:** existing script resolves fixed report/checkpoint paths (`:1-6`), enumerates required tests/routes (`:8-19`), recursively extracts outcomes (`:21-38`), fails if the report or required test is absent/failed (`:40-52`), writes a versioned checkpoint with explicit status and failure details (`:53-75`). Extend this checkpoint/schema in place with truthful candidate and served-asset provenance. Fail closed for missing required inputs and an empty capture set; use deterministic explicit fields and keep artifact paths within the evidence output directory. Do not derive source identity from a URL or call a passing advisory test the required CI result.

### `scripts/run_demo_browser_evidence.sh` (utility, process lifecycle/file-I/O)

**Analog:** same script, lines 1-25.

**Current pattern to repair:** strict shell mode and root-relative paths (`:1-5`), environment defaults (`:7-8`), one EXIT cleanup function (`:10-17`), stale-output removal before run (`:19-20`), then Compose `up` (`:22-23`). The current `down`/`logs` calls omit a run-scoped project identity (`:13-15,22`), so they target the retained default demo. Keep the single trap/error-log structure but generate/select one unique explicit Compose project and pass it consistently to `up`, logs, and cleanup. Cleanup only the project created by this run; never use broad prune, volume removal, or default-project `down`. Add a script-level contract test using the repository's existing test stack if needed.

### `mailglass_admin/dev/mix/tasks/mailglass_admin.preview.capture.ex` (utility/task, request-response/file-I/O)

**Analog:** same task, lines 1-33, 39-75, 78-115, and 118-153.

The Mix task convention is `use Boundary` + `use Mix.Task`, documented CLI options/defaults, strict `OptionParser.parse` validation, explicit config construction, dry-run contract output, actionable `Mix.raise` failures, and a deterministic artifact writer. Preserve these conventions if provenance needs to be supplied at capture time. Keep dry-run identity records and actual screenshot-byte hashes clearly distinguished.

### `README.md` / `reference/demo_app/README.md` (documentation, reference)

**Analog:** `reference/demo_app/README.md:5-28,67-95`; root quickstart at `README.md:40-55`.

Prefer the demo guide's short commands, explicit URLs, config path, and warning about destructive reset. A Phase 173 walkthrough should state how to open the existing working preview, which checkout/revision it serves, which generated/served CSS it uses, and where evidence is retained or cleaned. Keep CI evidence tied to the same committed candidate and label advisory jobs separately. Do not represent local documentation as proof that CI or the retained preview is actually running.

### Existing Gallery, Storybook, and CI surfaces

**Gallery:** `mailglass_admin/lib/mailglass_admin/gallery_live.ex:1-15,89-110` is the authoritative broad shared-component/state inventory: dev-only route, no database/mailable discovery, stable `data-testid`, explicit theme wrappers, and a static specimen list. Extend its existing specimens/tests only for a specifically missing state; do not duplicate the entire catalog elsewhere.

**Storybook:** `reference/demo_app/dev/mailglass_demo_web/storybook.ex:1-41` is a dev-only curated demo explorer. It uses the versioned served Admin CSS (`css_path` via `Assets.css_hash/0`), no JS asset build, and resides in the demo app because PhoenixStorybook is dev-only. Preserve that setup and make overlapping examples/theme behavior consistent; do not mirror styles or move files into the package.

**CI:** `.github/workflows/ci.yml` and `scripts/setup_branch_protection.sh` define existing required `CI Green` versus advisory browser/capture jobs. Phase acceptance uses the already-required aggregation on the exact candidate. No new lane, branch-protection edit, or workflow topology change is indicated. Evidence must report actual job class/status and exact SHA.

## Shared Patterns

### Source and generated-asset parity

Use `mailglass_admin/test/mailglass_admin/token_parity_test.exs:22-50,149-183` and `mailglass_admin/mix.exs`'s `verify.preview` task as the current model: source CSS is authoritative for implementation mechanics, generated `priv/static/` is committed and checked for drift, and a test failure should identify the rebuild command. `brandbook/tokens.css` owns brand values; `app.css` maps values to application roles. Don't turn the docs into another source of token values that contradict the CSS.

### Evidence identity and truthful claims

Keep a single versioned manifest/checkpoint path, deterministic normalization/order, SHA-256 from the bytes being identified, synthetic fixtures, and an explicit browser-only claim boundary. Candidate/revision, dirty state, route, fixture, theme, viewport, interaction state, browser, before/after relationship, image path/hash, and source/build/served asset identity must describe the same run. A hash proves identity/integrity only for the hashed bytes; it doesn't prove render correctness or email-client behavior.

### Browser assertions and capture

Use the existing Playwright Test dependency/config. Assert semantic and interactive behavior with role/text/URL assertions, geometry for bounded layout constraints, and screenshots as review artifacts. Reuse the configured base URL and seeded fixture reset. Keep screenshots synthetic and sampled to changed primary/adverse states.

### Resource ownership and cleanup

Use explicit run ownership for temporary Docker Compose resources. One generated evidence project identity must flow through every Compose operation; cleanup must be scoped to that identity, including failure paths. Preserve the long-lived preview and unrelated containers. Treat phase-local artifacts and temporary service state as owned resources and state their disposition explicitly.

## No Analog Found

None. The exact evidence and test surfaces already exist. If a requested provenance field has no compatible existing record shape, extend the current shape and its version deliberately rather than introducing a separate framework or dependency.

## Metadata

**Analog search scope:** tracked Mailglass Admin CSS/docs/ExUnit/Mix tasks, demo LiveView/Storybook/Playwright/checkpoint files, root evidence script, and CI workflow.  
**Files scanned:** 11 primary analog/surface files plus related source/config references.  
**Pattern extraction date:** 2026-10-09
