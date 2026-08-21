# Phase 159: Engineering-Gate Pattern Map

**Scope:** QUAL-01 and QUAL-03 through QUAL-11. This phase tightens proof and
maintainer tooling without changing product behavior, public APIs, release
publication, or any admin/operator UI behavior.

## Guiding shape

Keep named GitHub jobs as the external check identities, but move policy and
repeated setup into small, versioned repository seams that have mutation tests.
Core, admin, and inbound remain independently released projects: a shared
workflow helper must take package, lockfile, environment, and build inputs
explicitly rather than inferring a monorepo-wide dependency graph.

```text
Mix aliases / package tests --> named CI jobs --> CI Green policy --> merge verdict
                                |                    ^
                                +--> advisory inventory (never an input to merge verdict)
```

## Existing patterns to reuse

| Planned concern | Closest existing analogs | Reuse pattern | Do not copy |
|---|---|---|---|
| Required/advisory CI policy | `scripts/ci_green_policy.sh`, `test/scripts/ci_green_policy_test.exs`, `test/scripts/required_checks_test.exs`, `test/scripts/lane_classification_drift_test.exs` | Keep the shell evaluator fail-closed; pass explicit named results; use fixture and injected-breakage tests for omitted, duplicate, failing, and renamed lanes. | A second YAML-only aggregate list or a permissive missing-result default. |
| Local/CI parity | `mix.exs` `ci`, `ci.fast`, `ci.full`, `ci.setup`; `test/scripts/ci_parity_drift_test.exs` | Preserve declarative aliases and prove their union covers named jobs. A helper only removes duplicated setup, not command ownership. | One generic command that hides whether root, inbound, or admin was tested. |
| Formatting | `.formatter.exs`, `mailglass_inbound/.formatter.exs`, `.github/workflows/ci.yml` `format_check` | One root command/check-formatted baseline plus a static scope contract; run formatting only after the scope is agreed. | Letting sibling formatting depend on a job-local `cd` convention or treating a dirty worktree as a baseline. |
| Full-suite count floor | `test/support/suite_floor.ex`, `test/scripts/suite_floor_contract_test.exs`, `.github/workflows/advisory-matrix.yml` | Measure on the pinned toolchain, commit literal human-reviewed thresholds, and use direct negative controls over the same pure function. | Rewriting a threshold from the current run, parsing CLI summaries, or calling test count a coverage floor. |
| Coverage floor | Core `mix.exs` `test_coverage: [tool: ExCoveralls]`; `SuiteFloor` measurement comments | Introduce package-local coverage results and a checked-in measured baseline only after the canonical pinned CI run. Mirror the SuiteFloor "measure then literal ratchet" posture. | Inventing a percentage or sharing core coverage config with inbound. |
| Critical-path contracts | `test/scripts/architecture_boundary_test.exs`, `test/reference_host/public_seams_contract_test.exs`, `verify.support_contract.*` aliases | Test exact stable seams and ensure the required lane invokes them by identity. | Source grep as the only proof when a fake/spy can exercise ordering or outcomes. |
| Dialyzer ignore hygiene | `mix.exs` `dialyzer/0`, `.dialyzer_ignore.exs`, `scripts/check_dialyzer_ignore.sh`, CI stale-PLT rebuild | Use `ignore_file_strict` plus `list_unused_filters`; keep an explicit package-local ignore file and rebuild stale PLTs once. | Root-only analysis of inbound, comments as the sole no-growth mechanism, or shared PLTs across packages. |
| Credo exception policy | `.credo.exs`, `scripts/check_credo_suppressions.sh`, custom checks under `credo_checks/` and their tests | Retain custom rule registration and test its enforcement; replace blanket disabled complexity checks with data whose validator has mutation tests. | Permanent global `Nesting`/`CyclomaticComplexity` disables or raw `# credo:disable` scatter. |
| Skip/flaky/sleep governance | `test/support/suite_floor.ex`, `test/scripts/suite_floor_contract_test.exs`, mailbox/telemetry `assert_receive` patterns | Define a bidirectional registry and validate both source declarations and registry entries. Prefer monitors, task replies, telemetry, and mailbox acknowledgements. | Treating every sleep equally: TTL/clock and liveness fixtures need distinct, reviewed categories. |
| Toolchain/Docker contracts | `scripts/assert_gating_toolchain.sh`, `dev/toolchain/Dockerfile`, `test/scripts/*toolchain*`/CI contract tests | Make one script own exact toolchain comparison and test changed pins as a failure. | Assuming a Docker image tag or `.tool-versions` stays aligned without an executable comparison. |
| Release-policy extraction | `.github/workflows/publish-hex.yml`, `.github/workflows/release-please.yml`, `test/scripts/linked_release_concurrency_test.exs`, `test/scripts/release_trigger_recovery_test.exs` | Extract deterministic selection/validation into scripts with fixture tests while retaining protected workflow job names and release triggers. | Rewriting release topology, exposing secrets to scripts, or changing publish semantics in Phase 159. |

## Likely file map and ownership

| Likely file | Closest analog / intended responsibility | Safe owner and conflict notes |
|---|---|---|
| `.github/actions/setup-beam-mix/action.yml` (new) | Existing repeated `erlef/setup-beam`, `actions/cache`, and `mix deps.get` blocks in `ci.yml` | CI/setup slice owns it. Inputs must include package path, lockfile, Mix env, build path, and cache namespace. Do not absorb job-specific Postgres, browser, or publish credentials. |
| `scripts/ci_green_policy.sh` | Existing evaluator | Policy slice only. Preserve its argument protocol until all callers/tests change atomically. |
| `scripts/ci_policy_manifest.*` (new data/parser) | `test/support/ci_lanes.ex`, lane-classification tests | Policy slice owns the single inventory. The manifest distinguishes required, publish-gating, and advisory rather than changing existing job display names. |
| `test/scripts/ci_green_policy_test.exs`, `required_checks_test.exs`, `lane_classification_drift_test.exs`, `ci_parity_drift_test.exs` | Existing mutation-test suite | Policy slice updates them together; do not independently edit YAML names in another wave. |
| `.formatter.exs`, `mailglass_inbound/.formatter.exs`, formatter-scope contract test (new) | Existing format job | Formatting slice owns scope + mechanical reformat. Avoid overlapping source formatting with implementation waves; stage the baseline alone. |
| `mix.exs`, `mailglass_inbound/mix.exs`, coverage config/baseline files (new), coverage contract tests (new) | Core ExCoveralls setup and `SuiteFloor` | Coverage slice owns both package manifests. CI first records a pinned-toolchain measurement; only then add non-decreasing assertions. |
| `test/support/suite_floor.ex`, inbound equivalent (new only if needed) | Core count-floor pure function | Keep count and coverage vocabularies separate. Inbound should not copy core's schema assumptions blindly. |
| `mailglass_inbound/mix.exs`, `mailglass_inbound/.dialyzer_ignore.exs` (new), `.dialyzer_ignore.exs`, `scripts/check_dialyzer_ignore.sh`, Dialyzer policy tests (new) | Root Dialyxir/strict-ignore setup | Static-analysis slice owns all of these. Inbound gets its own PLT/cache key and no reference to root's ignore path. |
| `.credo.exs`, complexity ledger (new), ledger validator/test (new) | Credo custom check registration and suppression checker | Static-analysis slice only. Re-enable nesting/complexity after ledger baseline exists; retain unrelated custom checks. |
| Skip/flaky/sleep registry (new), validator script/test (new), affected focused tests | `SuiteFloor` bidirectional exclusion allowlist and async message assertions | Determinism slice owns registry mechanics; subsystem owners replace only their own readiness sleeps. Avoid a wide mechanical edit in one commit. |
| `.github/dependabot.yml`, `dev/toolchain/Dockerfile`, `reference/demo_app/Dockerfile`, workflow-policy contract test (new) | `assert_gating_toolchain.sh` | Workflow-hardening slice owns policy checks. This is build/release hygiene only, not a demo/admin UI change. |
| `.github/workflows/{ci,advisory-matrix,publish-hex,release-please}.yml`, release-policy scripts/tests (new) | Existing release trigger/concurrency tests | Promotion/extraction slice owns workflow edits. Preserve advisory identities and release-event protection; publication is Phase 160. |

## Baselines and ratchets

1. **Format first:** establish a clean one-format baseline before making format
   scope a release blocker.
2. **Measure before thresholds:** the only current measured numbers are core
   executed-test floors (`public: 1576`, `mailglass: 1575`) and skipped ceiling
   (`7`) in `SuiteFloor`; they are not coverage. Coverage and inbound floors
   need fresh pinned-toolchain evidence.
3. **Inventory before enforcement:** record every Dialyzer ignore, complexity
   exception, skip/flaky declaration, and sleep category before a validator
   denies new entries.
4. **Promote last:** only completed, deterministic commands enter required CI
   Green. Browser/demo/preview/provider-live/next-toolchain evidence stays in
   the advisory inventory and is negatively asserted absent from merge inputs.

## Anti-patterns to retire

- `hashFiles('**/mix.lock')` cache keys for package-local jobs; they blur
  independent dependency graphs.
- Global Credo complexity/nesting `false` entries and comments that say
  "permanent" instead of an executable expiry.
- Root-only Dialyzer as evidence for inbound shipped library code.
- A test-count floor presented as branch/line coverage.
- Wall-clock readiness sleeps where an observable completion event exists.
- Broad workflow permissions or mutable service-image tags without a contract
  test.
- Moving browser/admin-visual evidence into CI Green, or touching
  `mailglass_admin/lib`, assets, router, LiveViews, and operator behavior.

## Same-wave coordination

| Concurrent work | Coordination rule |
|---|---|
| Policy manifest and CI Green promotion | Do not promote a lane until its owner has supplied a deterministic command and mutation proof. Keep these in adjacent, ordered commits. |
| Formatter baseline and source changes | Reformat only the agreed Phase 159 scope; other waves rebase/format their own touched files after the baseline commit. |
| Coverage measurement and test cleanup | The measurement commit is evidence, not a target reset. Test replacements must not lower the newly recorded floor. |
| Dialyzer/Credo and package setup | Add inbound tooling before making inbound analysis required; package setup action must not change semantic aliases. |
| Release workflow extraction | Coordinate with Phase 160 planning; extract/test policy only, leave tags, publishing, credentials, and release-target values unchanged. |

## Validation order

1. Pure policy/registry/ledger mutation tests.
2. Package-local formatter, locked dependency, no-optional, Credo, and
   Dialyzer commands.
3. Pinned-toolchain coverage measurement and floor validation.
4. Existing CI YAML/parity/required-check contract tests.
5. Required CI Green promotion only after every candidate command is green.

This keeps failure signals attributable and prevents Phase 159 from becoming a
CI topology rewrite.
