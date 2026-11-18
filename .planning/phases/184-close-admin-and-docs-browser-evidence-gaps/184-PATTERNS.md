# Phase 184: Close Admin and docs browser evidence gaps - Pattern Map

**Mapped:** 2026-11-18  
**Candidate base:** `a295e9a950e14d7ce3ec9456f31fbda864933580`  
**Files/seams analyzed:** 12 likely source seams  
**Analogs found:** 12 / 12 (two checks have only a partial analog)

The Phase 184 context names the work areas but does not give a definitive edit list, and there is no `184-RESEARCH.md` yet. Rows below map the likely implementation seams from the context; they do not imply every listed analog needs modification. Every analog was verified with `git ls-files` in the specified candidate checkout.

## File Classification

| New/Modified File or Seam | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.formatter.exs` / formatter preflight | config | transform | `.github/workflows/ci.yml` | role-match |
| `.credo.exs` literal-root correction | config | transform | `.credo.exs` | exact |
| `reference/demo_app/assets/scripts/check-demo-browser-deps.cjs` | utility | transform/validation | `scripts/assert_gating_toolchain.sh` | partial |
| `scripts/run_demo_browser_evidence.sh` | utility | batch, file I/O | `scripts/gsd-regression-gate.sh` | role-match |
| `mailglass_admin/e2e/docs-theme-contract.test.cjs` | test | file I/O, request-response | `mailglass_admin/e2e/docs-theme-contract.cjs` | exact |
| `mailglass_admin/e2e/operator.spec.js` | test | request-response | `mailglass_admin/e2e/structural.spec.js` | role-match |
| `mailglass_admin/test/mailglass_admin/browser_server_readiness_test.exs` | test | request-response | `mailglass_admin/test/support/operator_browser_server.ex` | role-match |
| `mailglass_admin/test/support/operator_browser_server.ex` | utility | event-driven, request-response | `scripts/gsd-regression-gate.sh` | role-match |
| `scripts/gsd-regression-gate.sh` | utility | batch, request-response | `scripts/run_demo_browser_evidence.sh` | role-match |
| `mailglass_admin/e2e/structural.spec.js` preview Axe cell | test | request-response | `mailglass_admin/e2e/axe-baseline.spec.js` | exact |
| `scripts/verify_brand_docs.sh` | utility | batch, file I/O | `scripts/gsd-regression-gate.sh` | role-match |
| `mailglass_admin/e2e/docs-theme-contract.cjs` | utility | file I/O, browser request-response | `scripts/verify_brand_docs.sh` | role-match |

## Pattern Assignments

### Formatter gate (`.formatter.exs`, `.github/workflows/ci.yml`)

**Analog:** `.formatter.exs` and the tracked CI formatter step.

`.formatter.exs` lines 1-8 defines the formatted Elixir/ExUnit inputs and a 100-character line length. `.github/workflows/ci.yml` lines 115-116 uses `mix format --check-formatted`. Keep a cheap format check scoped to the changed Elixir inputs; do not invent a new formatter configuration for the phase.

```elixir
# .formatter.exs:1-8
[
  inputs: [
    "{mix,.formatter}.exs",
    "{config,lib,test}/**/*.{ex,exs}",
    "mailglass_inbound/{config,lib,test}/**/*.{ex,exs}"
  ],
  line_length: 100
]
```

```yaml
# .github/workflows/ci.yml:115-116
- name: Run formatter check
  run: mix format --check-formatted
```

### Credo literal root (`.credo.exs`)

**Analog:** `.credo.exs` lines 30-54.

The existing custom-check configuration documents that Credo sees the literal call root (`OptionalGenSmtp`) and does not resolve aliases to the underlying module. When correcting a literal-root mismatch, key the rule to the call root Credo actually parses and keep the allowed gateway path narrow; do not infer alias expansion.

```elixir
# .credo.exs:38-54
# WR-04 correction: Credo does NOT resolve aliases. Inbound `mime.ex` uses
# `alias Mailglass.OptionalDeps.GenSmtp, as: OptionalGenSmtp` and calls
# `OptionalGenSmtp.decode/2`; Credo sees the literal call root
# `OptionalGenSmtp`, NOT the underlying `GenSmtp` alias target.
gated_modules: %{
  Oban => [Mailglass.OptionalDeps.Oban, MailglassInbound.OptionalDeps.Oban],
  OpenTelemetry => Mailglass.OptionalDeps.OpenTelemetry,
  Mjml => Mailglass.OptionalDeps.Mjml,
  GenSmtp => [Mailglass.OptionalDeps.GenSmtp, MailglassInbound.OptionalDeps.GenSmtp],
  :mimemail => Mailglass.OptionalDeps.GenSmtp,
  :gen_smtp_client => Mailglass.OptionalDeps.GenSmtp,
```

### Demo Node runtime and dependency preflight

**Analog:** `scripts/assert_gating_toolchain.sh` lines 27-51; dependency-contract check in `reference/demo_app/assets/scripts/check-demo-browser-deps.cjs` lines 8-37 and 85-102.

The Demo dependency checker verifies exact package/lock metadata and records the package `engines.node` floor (`>=18`), but it does **not** compare that floor to the active `process.version`. There is no current tracked Node runtime-version preflight. `assert_gating_toolchain.sh` is the nearest pattern for comparing declared and actual versions and failing before expensive work. Keep this check inexpensive and preserve the Demo Playwright 1.60 / Node 18 contract; do not alter it while adjusting Admin's runtime.

```sh
# scripts/assert_gating_toolchain.sh:27-38
expected_elixir="$(awk '$1 == "elixir" { print $2 }' "$tool_versions")"
expected_otp="$(awk '$1 == "erlang" { print $2 }' "$tool_versions")"
actual_elixir="$(elixir -e 'IO.write(System.version())')"
actual_otp="$(erl -noshell -eval '...')"

if [ "$actual_elixir" != "$expected_elixir" ] || [ "$actual_otp" != "$expected_otp" ]; then
  ...
  exit 1
fi
```

### Demo evidence wrapper (`scripts/run_demo_browser_evidence.sh`)

**Analog:** `scripts/gsd-regression-gate.sh` for staged preflight, owned browser execution, bounded resources, and cleanup.

The Demo wrapper records phase/run identity and timings in its evidence output. Its browser setup at `scripts/run_demo_browser_evidence.sh:289-305` checks the pinned lock, installs dependencies/browser, and records versions before the scan. Add any runtime preflight before dependency installation or browser work so an unsupported runtime fails cheaply; do not change evidence identity fields or the separate Phase 174 browser contract.

### Generated-doc fixture (`mailglass_admin/e2e/docs-theme-contract.test.cjs`)

**Analog:** `mailglass_admin/e2e/docs-theme-contract.cjs` lines 158-224.

The fixture tests establish the output-root contract with pure helpers and temporary directories. `docs-theme-contract.test.cjs:12-23` asserts all three package paths; lines 25-35 creates a temporary generated-output fixture and removes it with `t.after`; lines 37-49 launches the real CLI and proves missing output is rejected before Chromium starts. Reuse that fixture pattern for same-output checks: use a temp root, assert explicit package paths, clean up in `t.after`, and assert browser launch is not reached after invalid output.

```js
// docs-theme-contract.test.cjs:25-35
test("missing package output is rejected with its name and README path", (t) => {
  const outputRoot = fs.mkdtempSync(path.join(os.tmpdir(), "mailglass-docs-contract-"));
  t.after(() => fs.rmSync(outputRoot, { recursive: true, force: true }));
  fs.mkdirSync(path.join(outputRoot, "core"), { recursive: true });
  fs.writeFileSync(path.join(outputRoot, "core", "README.html"), "<html></html>");
  ...
  assert.throws(() => validateOutputPaths(outputs), /admin docs output is missing README\\.html/);
});
```

### Operator selector and LiveView readiness

**Selector analog:** `mailglass_admin/e2e/operator.spec.js` lines 9-15 and 40-66. Use stable `data-testid` or accessible role/name selectors; for the responsive list, filter visible duplicated presentations before selecting an index. The `openOperator` helper resets the fixture, logs in, asserts the `Email health` heading, then navigates to Activity and asserts the level-one `Activity` heading plus the viewport-independent list-card test id.

```js
// operator.spec.js:9-15, 40-46, 55-66
function deliveryRow(page, index) {
  return page.getByTestId("operator-delivery-row").filter({ visible: true }).nth(index);
}

async function openOperator(page) {
  const resetResponse = await page.request.get("/ops/browser-reset");
  expect(resetResponse.ok()).toBeTruthy();
  ...
  await expect(page.getByRole("heading", { name: "Email health", exact: true })).toBeVisible();
  await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries`);
  await expect(page.getByRole("heading", { name: "Activity", exact: true, level: 1 })).toBeVisible();
  await expect(page.getByTestId("operator-deliveries-list-card")).toBeVisible();
}
```

**Readiness analog:** `mailglass_admin/test/mailglass_admin/browser_server_readiness_test.exs:6-30` checks the endpoint returns `503/starting` before fixtures and `200/ok` only after readiness is enabled. `mailglass_admin/test/support/operator_browser_server.ex:27-44` keeps readiness closed through bootstrap and fixture seeding, then opens it. `scripts/gsd-regression-gate.sh:114-159` polls host loopback and separately verifies container-to-host reachability before launching Playwright. Treat readiness as a server/setup contract; a ready endpoint does not prove a page selector or LiveView render has settled, so browser tests should still assert the visible page heading/control.

```elixir
# browser_server_readiness_test.exs:19-29
Application.put_env(:mailglass_admin, :operator_browser_server_ready?, false)
starting = BrowserSessionController.ready(Plug.Test.conn(:get, "/ops/browser-ready"), %{})
assert starting.status == 503
assert starting.resp_body == "starting"

Application.put_env(:mailglass_admin, :operator_browser_server_ready?, true)
ready = BrowserSessionController.ready(Plug.Test.conn(:get, "/ops/browser-ready"), %{})
assert ready.status == 200
assert ready.resp_body == "ok"
```

### Preview Axe target-creation diagnosis

**Analog:** `mailglass_admin/e2e/structural.spec.js` lines 2658-2695; supporting producer pattern in `mailglass_admin/e2e/axe-baseline.spec.js` lines 227-231 and 242-269.

The current structural preview cell reuses the test's existing page, scans the active document with legacy Axe mode, retains the full WCAG 2.2 AA tags, and logs each target selector as an annotation and line. The sandboxed `srcdoc` explanation is specific to the preview; do not create a second page to inspect the same cell. Use this as the diagnosis surface and retain the committed per-theme baseline equality. The baseline producer's `test.slow()` is the existing suite accommodation; it is not a remedy for the reported `Target.createTarget` timeouts. Diagnose one bounded cell with zero retries and do not weaken assertions or extend timeouts.

```js
// structural.spec.js:2671-2694
await page.goto(`/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default${themed}`);
await expect(page.getByTestId("preview-shell")).toBeVisible();
const results = await new AxeBuilder({ page })
  .setLegacyMode()
  .withTags(WCAG_22_AA_TAGS)
  .analyze();
...
test.info().annotations.push({ type: "axe-target", description });
console.log(`axe-target ${description}`);
expect(measured, `Preview axe cell (${theme}) must equal the committed baseline`).toEqual(
  baseline.current.violations.preview[theme].rules
);
```

### Docs browser on the same generated output in the pinned container

**Output analog:** `scripts/verify_brand_docs.sh` lines 29-64 and `mailglass_admin/e2e/docs-theme-contract.cjs` lines 193-224. The script builds core, admin, and inbound docs under one owned temporary `output_root`, validates the generated output, and passes that same root explicitly to the browser contract. `outputPathsFor` maps each package under the explicit root; `validateOutputPaths` fails before launching Chromium.

**Container analog:** `scripts/gsd-regression-gate.sh` lines 52-57 and 161-184. It derives the Playwright image tag from the installed package version, fails when that exact image is absent (no implicit pull), uses a read-only browser container with bounded memory/CPU/tmp, and surfaces the runner log. Adapt the runner to mount the docs output root read-only and pass its container-visible path to `--output-root`; keep the single generated output tree alive until the browser process exits, then let the owning trap remove it. The current `verify_brand_docs.sh --browser` runs Chromium locally, so same-output browser-in-container is a new composition of these two existing patterns.

```sh
# verify_brand_docs.sh:40-59
MIX_ENV=dev mix docs --warnings-as-errors --output "$output_root/core"
(cd mailglass_admin && MIX_ENV=dev mix docs --output "$output_root/admin")
(cd mailglass_inbound && MIX_ENV=dev mix docs --output "$output_root/inbound")
MAILGLASS_DOCS_OUTPUT_ROOT="$output_root" MIX_ENV=dev mix run --no-start ci/contracts/brand_docs_output_test.exs
node mailglass_admin/e2e/docs-theme-contract.cjs --all --output-root "$output_root"
```

```sh
# gsd-regression-gate.sh:52-57, 161-171
playwright_version="$(node -e 'process.stdout.write(require("./mailglass_admin/node_modules/playwright/package.json").version)')"
image="mcr.microsoft.com/playwright:v${playwright_version}-noble"
if ! docker image inspect "$image" >/dev/null 2>&1; then
  echo "Matching Playwright Docker image is not present locally: ${image}."
  return 1
fi

docker run --rm --init --read-only --network=bridge \
  --tmpfs /tmp:rw,nosuid,size=1g --shm-size=512m --memory=2g --cpus=2 --pids-limit=512 \
  --volume "$ROOT_DIR:/workspace/mailglass:rw" \
  --volume "$runner_file:/runner.cjs:ro" ...
```

## Shared Patterns

### Cheap preflights

Use the established formatter command from `.github/workflows/ci.yml:115-116`; run focused Node checks with the repository's `node --check` / `node:test` style. For runtime validation, compare actual to an explicit supported floor/version before `npm ci` or browser setup. The existing Demo lock checker only verifies a declared engine range; it is not a runtime check.

### Browser readiness and cleanup

The browser-server process logs staged setup, leaves readiness false while bootstrap and seed fixtures run, and sets it true only after seeding. The shell gate polls readiness, checks the server process is alive, logs the server on failure, and stops only the PID it started. Keep those ownership and readiness boundaries when changing selector or container startup behavior.

### Browser container and evidence

Pin the Playwright image to the installed package version, inspect for local availability before running, use finite resource limits and zero Playwright retries for the Docker route, and keep evidence attached to exact source identity. For docs, pass the same generated output path from build through contract check and container mount; never fall back to checkout `doc/` when an explicit output root was requested.

## No Direct Analog Found

| Seam | Closest Pattern | Gap |
|---|---|---|
| Active Demo Node runtime-version check | `scripts/assert_gating_toolchain.sh:27-51`; `reference/demo_app/assets/scripts/check-demo-browser-deps.cjs:8-37` | No tracked file compares the actual Node process version to the supported Demo runtime. The dependency checker only verifies `engines.node` metadata. |
| Docs same-output container execution | `scripts/verify_brand_docs.sh` + `scripts/gsd-regression-gate.sh` | Each half exists, but the current docs script runs the browser locally and the current container runner does not mount a generated docs output root. Preserve one output root while composing them. |

## Metadata

**Analog search scope:** tracked formatter/CI/Credo config, browser evidence scripts, Demo browser dependency checks, Admin Playwright specs and readiness support.  
**Files scanned:** 16 tracked analog/config files.  
**Pattern extraction date:** 2026-11-18.  
**Execution:** no tests, browsers, Docker, install/pull, or CI were run.
