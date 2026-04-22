---
phase: 01-foundation
plan: 01
subsystem: infra
tags: [mix, hex, elixir, otp-application, boundary, ex_unit, wave-0, optional-deps, swoosh]

requires: []
provides:
  - "mix.exs with locked 2026 dep versions (required: phoenix 1.8, phoenix_live_view 1.1, phoenix_html 4.1, plug 1.18, swoosh 1.25, nimble_options 1.1, telemetry 1.4, gettext 1.0, premailex 0.3, floki 0.38, boundary 0.10, jason 1.4; optional: oban 2.21, opentelemetry 1.7, mjml 5.3, gen_smtp 1.3, sigra 0.2)"
  - "elixirc_options no_warn_undefined covering all optional deps + the Phase-1-only Mailglass.Config.validate_at_boot!/0 forward reference"
  - "compilers: [:boundary | Mix.compilers()] — CORE-07 wiring for later-plan `use Boundary` enforcement"
  - "Application module with Code.ensure_loaded? guard on Mailglass.Config.validate_at_boot!/0 and maybe_warn_missing_oban/0 boot-time warning"
  - "Flat root Boundary on Mailglass — classifies every Mailglass.* module with no internal dep constraints (internal boundaries land in later plans)"
  - "ExUnit + Mox harness with guarded Mox.defmock for the Mailglass.TemplateEngine behaviour (behaviour lands Plan 06)"
  - "12 Wave 0 test stubs under test/mailglass/ — all @moduletag :skip — including the mandatory D-14 vml_preservation_test.exs golden-fixture stub and AUTHOR-02 img_no_alt_test.exs compile-fixture stub"
  - "INST-04 verify.phase01 mix alias + CI-05 files whitelist in package/0"
  - "Swoosh :api_client set to false — adopters override when they select an HTTP client"
affects: [phase-01-plan-02-error-hierarchy, phase-01-plan-03-config-telemetry-repo-idempotency, phase-01-plan-04-optional-deps, phase-01-plan-05-components, phase-01-plan-06-renderer, phase-2-persistence-tenancy, phase-3-outbound, phase-4-webhooks, phase-5-admin, phase-6-credo, phase-7-installer]

tech-stack:
  added:
    - "Elixir 1.18+ / OTP 27+ project scaffold"
    - "Phoenix 1.8 + Phoenix.LiveView 1.1 + Phoenix.Component"
    - "Swoosh 1.25 (with :api_client deferred to adopter)"
    - "Boundary 0.10 compiler (flat root; internal boundaries TBD)"
    - "ExUnit + Mox 1.2 + StreamData 1.3 test harness"
    - "NimbleOptions 1.1, Telemetry 1.4, Premailex 0.3, Floki 0.38"
    - "Optional: Oban 2.21, OpenTelemetry 1.7, MJML 5.3, gen_smtp 1.3, Sigra 0.2"
  patterns:
    - "elixirc_options no_warn_undefined list covers every optional-dep module + forward-referenced in-repo modules — lets --warnings-as-errors pass across the full phase-1 execution window before every module exists"
    - "Application.start/2 uses Code.ensure_loaded? + function_exported? guard so OTP app boots cleanly even when referenced Phase-1 modules haven't been created yet"
    - "config/*.exs uses Application.get_env at runtime (never compile_env) — LINT-08 enforced from day one"
    - "@moduletag :skip on every Wave 0 stub lets mix test exit 0 immediately; each stub de-skips as its implementing plan lands"
    - "config :swoosh, :api_client, false at project level — defers HTTP client selection to adopters, keeps the library decoupled from hackney/finch/req"
    - "Flat root Boundary pattern (use Boundary, deps: [], exports: []) satisfies the compiler without imposing cross-module constraints; fine-grained boundaries emerge in the plans that own them"

key-files:
  created:
    - "mix.exs — project manifest, deps, elixirc_options, verify.phase01 alias"
    - "mix.lock — Hex dep resolution snapshot"
    - ".formatter.exs — 100-column line_length"
    - ".credo.exs — strict mode stub (custom LINT-01..LINT-12 land Phase 6)"
    - "config/config.exs — runtime config base + Swoosh api_client deferral"
    - "config/{dev,test,prod,runtime}.exs — per-env stubs"
    - "lib/mailglass.ex — top-level facade + root Boundary declaration"
    - "lib/mailglass/application.ex — OTP app with guarded Config validation + Oban warning"
    - "test/test_helper.exs — ExUnit.start + guarded Mox.defmock"
    - "test/support/fixtures.ex — shared test helpers"
    - "test/support/mocks.ex — mock declaration namespace"
    - "test/fixtures/.gitkeep — placeholder for golden VML fixture"
    - "test/mailglass/{error,config,telemetry,repo,idempotency_key,renderer,compliance}_test.exs — 7 stubs"
    - "test/mailglass/components/{vml_preservation,button,row,img_no_alt}_test.exs — 4 stubs"
    - "test/mailglass/template_engine/heex_test.exs — 1 stub"
  modified: []

key-decisions:
  - "Swoosh :api_client is set to false at the project level (not in test.exs alone); adopters opt into Hackney/Finch/Req when they configure a real transport. Keeps mailglass decoupled from any specific HTTP client."
  - "Mailglass.Config.validate_at_boot!/0 is added to no_warn_undefined as a forward reference — lets --warnings-as-errors pass across Plans 01..02 before the Config module lands in Plan 03. The Code.ensure_loaded? guard in Application.start/2 makes the reference safe at runtime."
  - "A flat root Boundary declaration lives on Mailglass for Phase 1 only (deps: [], exports: []). CORE-07 requires the compiler wired + --warnings-as-errors must pass; the plan forbids internal dep constraints here. The flat root satisfies both: classifier sees all Mailglass.* modules, no cross-module restrictions applied. Internal boundaries land with the plans that introduce them (Renderer, Components, Outbound, Events, ...)."
  - "Wave 0 stubs use @moduletag :skip rather than pending-test markers so mix test exits 0 even with 24 unimplemented tests — keeps CI green across the Phase 1 execution window."

patterns-established:
  - "Phase-N-safe forward references: any module reference that lands in a later Phase-1 plan is guarded by Code.ensure_loaded? at runtime AND added to elixirc_options no_warn_undefined at compile time. Once the referenced module ships the guard becomes trivially satisfied but stays in place."
  - "Per-env config layering: config/config.exs sets the shared baseline then `import_config '#{config_env()}.exs'` pulls the env-specific file. Runtime-only configuration uses config/runtime.exs (loaded after compile)."
  - "Wave 0 test stub shape: `use ExUnit.Case, async: true; @moduletag :skip`; body uses `flunk \"not yet implemented\"` with a comment pointing to the plan that will de-skip it. Golden-fixture stubs (vml_preservation_test, img_no_alt_test) carry extra @moduledoc explaining the D-14 / AUTHOR-02 contract they enforce."

requirements-completed: [CORE-06, CORE-07]

duration: 8min
completed: 2026-04-22
---

# Phase 1 Plan 1: Project Scaffold + Wave 0 Test Stubs Summary

**Greenfield Elixir 1.18 / Phoenix 1.8 / OTP 27 project skeleton with locked 2026 deps, Boundary compiler wired (flat root), OTP application with forward-safe Config guard, and 12 Wave 0 test stubs under @moduletag :skip ready to de-skip as later Phase 1 plans land.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-04-22T14:24:44Z
- **Completed:** 2026-04-22T14:32:30Z
- **Tasks:** 2 / 2
- **Files created:** 20
- **Files modified:** 0 (greenfield)

## Accomplishments

- `mix.exs` with all 23 deps from RESEARCH.md Standard Stack table, pinned to verified 2026 versions
- `mix deps.get` resolves cleanly; `mix compile --no-optional-deps --warnings-as-errors` and `mix compile --warnings-as-errors` both exit 0
- `compilers: [:boundary | Mix.compilers()]` wires CORE-07 so later plans can drop `use Boundary` blocks as they introduce new subsystems
- `lib/mailglass/application.ex` boots through `mix test` without crashing despite `Mailglass.Config` not existing yet (Plan 03 owns it) — the `Code.ensure_loaded?/function_exported?` guard makes the forward reference runtime-safe
- 12 Wave 0 test stubs (7 at `test/mailglass/`, 4 under `components/`, 1 under `template_engine/`) — `mix test` reports 24 tests, 0 failures, 24 skipped
- Mandatory artifacts present: D-14 `vml_preservation_test.exs` golden-fixture stub + AUTHOR-02 `img_no_alt_test.exs` compile-fixture stub
- `verify.phase01` mix alias ready for CI (compile --no-optional-deps + test --warnings-as-errors + credo --strict)

## Task Commits

Each task was committed atomically:

1. **Task 1: mix.exs, config, formatter, credo stubs** — `c7a064b` (chore)
2. **Task 2: Application, facade, Wave 0 test stubs** — `4d7f2e8` (feat)

## Files Created/Modified

| File | Purpose |
|------|---------|
| `mix.exs` | Project manifest — deps, elixirc_options, verify.phase01 alias, boundary compiler wiring, CI-05 files whitelist |
| `mix.lock` | Hex dependency resolution snapshot |
| `.formatter.exs` | 100-column `line_length` |
| `.credo.exs` | Strict-mode stub (custom LINT checks land Phase 6) |
| `config/config.exs` | Base runtime config + Swoosh `:api_client` deferral + `import_config` chain |
| `config/dev.exs` | Dev default_logger enabled |
| `config/test.exs` | Fake adapter + logger level warning |
| `config/prod.exs` | Empty — adopter provides |
| `config/runtime.exs` | Commented example for adopter |
| `lib/mailglass.ex` | Top-level facade `@moduledoc` + flat root `use Boundary, deps: [], exports: []` |
| `lib/mailglass/application.ex` | OTP app with guarded Config.validate_at_boot!/0 + maybe_warn_missing_oban/0 |
| `test/test_helper.exs` | ExUnit.start + guarded Mox.defmock for Mailglass.TemplateEngine |
| `test/support/fixtures.ex` | Shared fixtures + VML golden fixture path |
| `test/support/mocks.ex` | Mox namespace placeholder |
| `test/fixtures/.gitkeep` | Directory placeholder for golden fixtures |
| `test/mailglass/error_test.exs` | CORE-01 stub (3 tests) |
| `test/mailglass/config_test.exs` | CORE-02 stub (2 tests) |
| `test/mailglass/telemetry_test.exs` | CORE-03 stub (2 tests, includes property test placeholder) |
| `test/mailglass/repo_test.exs` | CORE-04 stub (1 test) |
| `test/mailglass/idempotency_key_test.exs` | CORE-05 stub (2 tests) |
| `test/mailglass/renderer_test.exs` | AUTHOR-03 stub (5 tests) |
| `test/mailglass/compliance_test.exs` | COMP-01/02 stub (3 tests) |
| `test/mailglass/components/vml_preservation_test.exs` | **MANDATORY** D-14 golden-fixture stub (2 tests) |
| `test/mailglass/components/button_test.exs` | AUTHOR-02 VML wrapper stub (1 test) |
| `test/mailglass/components/row_test.exs` | AUTHOR-02 non-column warning stub (1 test) |
| `test/mailglass/components/img_no_alt_test.exs` | AUTHOR-02 compile-time fixture stub (1 test) |
| `test/mailglass/template_engine/heex_test.exs` | AUTHOR-05 stub (1 test) |

## Decisions Made

- **Swoosh `:api_client` deferral at project level.** Swoosh 1.25 requires the key at application boot via `Application.fetch_env!`. Mailglass does not pin an HTTP transport (adopters choose Finch/Hackney/Req, or use `Mailglass.Adapters.Fake` for dev/test). Setting `config :swoosh, :api_client, false` in `config/config.exs` makes `Swoosh.ApiClient.init/0` skip initialization because `Code.ensure_loaded?(false)` returns false. Adopters override this key when they configure a real transport.
- **Forward reference via `no_warn_undefined` MFA tuple.** `Mailglass.Application.start/2` must call `Mailglass.Config.validate_at_boot!/0` behind a `Code.ensure_loaded?` guard per the plan. Under `--warnings-as-errors`, the compiler emits a warning for the unresolved reference because the guard is dynamic. Adding `{Mailglass.Config, :validate_at_boot!, 0}` to `elixirc_options[:no_warn_undefined]` suppresses the warning without disabling guards elsewhere. Removes naturally when Plan 03 lands Config.
- **Flat root Boundary as Phase-1-only measure.** CORE-07 mandates `compilers: [:boundary | Mix.compilers()]` wiring in Plan 01; the plan notes simultaneously forbid `use Boundary` annotations on `Mailglass` / `Mailglass.Application`. Boundary emits a compiler warning for every unclassified module in the main app, which under `--warnings-as-errors` fails the verification gate. A flat root `use Boundary, deps: [], exports: []` on `Mailglass` resolves this: it classifies every `Mailglass.*` module (including `Mailglass.Application` and the two `test/support` modules) into one undifferentiated boundary with no cross-module constraints. Later plans add sub-boundaries (`Mailglass.Renderer`, `Mailglass.Components`, `Mailglass.Outbound`, …) — the root stays in place as the catch-all.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Swoosh :api_client required at application boot**

- **Found during:** Task 2 verification (`mix test`)
- **Issue:** Swoosh 1.25 `Swoosh.Application.start/2` calls `Swoosh.ApiClient.init/0`, which invokes `Application.fetch_env!(:swoosh, :api_client)`. Without the key set, the OTP app fails to start and `mix test` exits with `(Mix) Could not start application swoosh`.
- **Fix:** Added `config :swoosh, :api_client, false` to `config/config.exs`. `Code.ensure_loaded?(false)` returns false, so Swoosh's init no-ops. Adopters override when selecting a real HTTP client.
- **Files modified:** `config/config.exs`
- **Verification:** `mix test` now exits 0 with 24 tests / 24 skipped
- **Committed in:** `4d7f2e8` (Task 2 commit)

**2. [Rule 3 - Blocking] `Mailglass.Config.validate_at_boot!/0` forward reference fails --warnings-as-errors**

- **Found during:** Task 2 verification (`mix compile --warnings-as-errors`)
- **Issue:** `Mailglass.Application.start/2` references `Mailglass.Config.validate_at_boot!/0` behind a `Code.ensure_loaded?` guard. Elixir's compiler cannot prove the guard prevents the call, so it emits `Mailglass.Config.validate_at_boot!/0 is undefined`. Under `--warnings-as-errors` this fails compilation.
- **Fix:** Added the MFA tuple `{Mailglass.Config, :validate_at_boot!, 0}` to `elixirc_options[:no_warn_undefined]` in `mix.exs`. Once Plan 03 lands the module, the guard is always satisfied and the warning never fires anyway; the MFA entry becomes a no-op.
- **Files modified:** `mix.exs`
- **Verification:** `mix compile --warnings-as-errors` and `mix compile --no-optional-deps --warnings-as-errors` both exit 0
- **Committed in:** `4d7f2e8` (Task 2 commit)

**3. [Rule 3 - Blocking] Boundary compiler + --warnings-as-errors require at least one boundary declaration**

- **Found during:** Task 2 verification (`mix compile --warnings-as-errors`)
- **Issue:** With `compilers: [:boundary | Mix.compilers()]` enabled and zero `use Boundary` declarations, the Boundary compiler emits `Mailglass is not included in any boundary` / `Mailglass.Application is not included in any boundary` for every main-app module. Under `--warnings-as-errors` this fails both compile lanes. The plan simultaneously requires (a) CORE-07 compiler wiring, (b) `--warnings-as-errors` exit 0, and (c) no `use Boundary` annotations in Plan 01 — all three cannot simultaneously hold.
- **Fix:** Added a single minimal `use Boundary, deps: [], exports: []` declaration on the `Mailglass` facade module. Boundary contains any module whose name starts with `Mailglass.` in this root boundary, classifying every Phase 1 module (including `Mailglass.Application`, `Mailglass.Test.Fixtures`, `Mailglass.Test.Mocks`) under one catch-all. With `deps: []` and `exports: []` there are no cross-module constraints — the INTENT of the plan's no-annotation note is preserved. Later plans add sub-boundaries (`Mailglass.Renderer`, `Mailglass.Components`, …) as they introduce subsystems.
- **Files modified:** `lib/mailglass.ex`
- **Verification:** `mix compile --warnings-as-errors` and `mix compile --no-optional-deps --warnings-as-errors` both exit 0; `mix test` still exits 0 with 24 skipped tests
- **Committed in:** `4d7f2e8` (Task 2 commit)

---

**Total deviations:** 3 auto-fixed (3 Rule 3 - blocking issues)
**Impact on plan:** All three fixes were blocking the verification gates explicitly listed in the plan's success criteria. None changed plan scope; each is minimal and reversible (the Config forward-reference MFA becomes a no-op once Plan 03 lands, the flat root Boundary will host real sub-boundaries from later plans, and the Swoosh `:api_client, false` default is documented for adopter override).

## Issues Encountered

- **Elixir toolchain newer than locked floor.** Local toolchain is Elixir 1.19.5 / OTP 28; plan locks floor at Elixir 1.18 / OTP 27. The `~> 1.18` constraint in `mix.exs` allows 1.19 — no action needed. The toolchain difference is documented here only so downstream reviewers know the lock file reflects actual resolution against 1.19.5.
- **Dep resolution produced current 2026-04 patch versions** that match or minor-bump the RESEARCH.md Standard Stack (e.g., `premailex 0.3.20`, `phoenix 1.8.5`, `phoenix_live_view 1.1.28`, `oban 2.21.1`). All within the specified `~>` constraints. No functional impact.
- **OTLP exporter warning at test boot.** OpenTelemetry (optional dep) is loaded because `mix deps.get` pulls all optional deps, and it emits `OTLP exporter module opentelemetry_exporter not found` as a Logger.warning during app start. Not a compile warning — does not affect `--warnings-as-errors`. Adopters who want OTLP export add `{:opentelemetry_exporter, "~> 1.7"}` in their own deps.

## Self-Check

- File verification:
  - ✓ `mix.exs` exists
  - ✓ `mix.lock` exists
  - ✓ `.formatter.exs` exists
  - ✓ `.credo.exs` exists
  - ✓ `config/config.exs` exists
  - ✓ `config/dev.exs` exists
  - ✓ `config/test.exs` exists
  - ✓ `config/prod.exs` exists
  - ✓ `config/runtime.exs` exists
  - ✓ `lib/mailglass.ex` exists
  - ✓ `lib/mailglass/application.ex` exists
  - ✓ `test/test_helper.exs` exists
  - ✓ `test/support/fixtures.ex` exists
  - ✓ `test/support/mocks.ex` exists
  - ✓ all 12 Wave 0 test stubs exist
- Commit verification:
  - ✓ `c7a064b` (Task 1) in git log
  - ✓ `4d7f2e8` (Task 2) in git log
- Gate verification:
  - ✓ `mix deps.get` exits 0
  - ✓ `mix compile --no-optional-deps --warnings-as-errors` exits 0
  - ✓ `mix compile --warnings-as-errors` exits 0
  - ✓ `mix test` exits 0 (24 tests, 0 failures, 24 skipped)

## Self-Check: PASSED

## Next Phase Readiness

- Project compiles cleanly in both lanes (with/without optional deps) — Plans 02..06 can execute without scaffold rework
- Wave 0 stubs in place — each later plan de-skips its stubs and implements them in-file
- `Mailglass.Config` forward reference is the only compile-warning suppressant in `no_warn_undefined` targeting an in-repo module; Plan 03 lands Config and the entry becomes a no-op
- Root Boundary is ready to host sub-boundaries; Plan 02 (errors) can add `use Boundary, deps: [], exports: [Mailglass.SendError, Mailglass.TemplateError, ...]` per its own scope
- Swoosh transport selection remains adopter-owned as intended by PROJECT.md composition philosophy

---

*Phase: 01-foundation*
*Completed: 2026-04-22*
