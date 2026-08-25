# Phase 155: Restore Adopter and CI Truth - Research

**Researched:** 2026-08-16  
**Domain:** Ecto/Postgres package-migration generation and GitHub Actions aggregate-gate integrity  
**Confidence:** HIGH for repository integration points; MEDIUM for external workflow and Ecto semantics

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

Initial generators emit the documented `Migration.up/0` and `down/0` wrappers.
Additive flags are `--repo`, `--upgrade`, `--from`, and `--repair-legacy`.
Repo inference is allowed only for exactly one configured `:ecto_repos` entry.
Upgrade wrappers are new timestamped files and bake the previous schema version into rollback.
Already-applied migrations are immutable.

Repair only the exact known toy shape; ambiguous or populated data fails with actionable guidance.
Version zero means the anchor is genuinely absent. Query errors, missing/malformed comments, and
impossible ranges fail closed.

Preserve the public protected check name `CI Green`.
Add change detection to its dependency graph and require exact success for every required code lane
when `code=true`; only successful docs-only classification may permit skips.
Add regression meta-tests for failed change detection, skipped code lanes, and docs-only behavior.

### the agent's Discretion

Internal module factoring, helper names, and test fixture structure may follow existing conventions.
Prefer the smallest additive surface that gives deterministic generated-host proof.

### Deferred Ideas (OUT OF SCOPE)

Runtime delivery, inbound/data hardening, architecture refactors, broader quality-gate expansion, and
release certification belong to Phases 156-160 respectively.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADOPT-01 | Generated Ecto host receives real core and inbound wrappers. | Preserve the existing `Installer Host Smoke` required lane, but add a stock Ecto-host journey that invokes both Mix tasks, runs `ecto.migrate`/rollback, and persists a delivery. |
| ADOPT-02 | Explicit `--repo`; inference only for exactly one repo. | Centralize task option parsing and configured-repo resolution for both package generators. |
| ADOPT-03 | Upgrade is a fresh timestamped migration with prior-version rollback. | Generate a new wrapper only for `--upgrade`; never edit/install-path match an existing file. |
| ADOPT-04 | Offline `--from` only accepts valid older version. | Validate against each package runner's `current_version/0`, and reject conflicting/invalid live-or-offline state. |
| ADOPT-05 | Known toy migration has non-destructive, fail-closed repair. | Recognize the exact historical core toy source; generate an additive repair migration only after source and live-catalog/empty-table checks. |
| ADOPT-06 | Missing anchor differs from query/malformed metadata failure. | Replace runner's catch-all `0` path with explicit absent / valid / invalid outcomes. |
| QUAL-02 | `CI Green` fails closed for detector failure or skipped code lanes. | Add `changes` to the aggregate graph and branch its explicit result policy on successful `code=true`/`code=false`. |
</phase_requirements>

## Summary

The core generator is presently false: it accepts `--upgrade` but ignores it, has no repo selection, and emits the historical toy `change/0` DDL instead of the documented public `Mailglass.Migration.up/0`/`down/0` wrapper. The inbound generator emits correct initial wrappers but likewise has no repo, upgrade, prior-version, or repair semantics. Both resolve the migration module from a regex against `mix.exs`, which cannot select the owning repository in a multi-repo host. [VERIFIED: codebase — `lib/mix/tasks/mailglass.gen.migration.ex`, `mailglass_inbound/lib/mix/tasks/mailglass.inbound.gen.migration.ex`]

The package runners have the version-dispatch machinery required for generated wrappers, but their `migrated_version/1` implementations collapse every non-successful query outcome into `0` and core applies `String.to_integer/1` without validating the comment. That contradicts the locked distinction between absent anchor and malformed/query failure. The current repository has realistic wrapper-through-`Ecto.Migrator` tests, but its required host smoke intentionally uses `phx.new --no-ecto`; it cannot prove migration generation, migration rollback, or persistence in a real Ecto host. [VERIFIED: codebase — `lib/mailglass/migrations/postgres.ex`, `mailglass_inbound/lib/mailglass_inbound/migrations/postgres.ex`, `scripts/consumer_install_smoke.sh`]

`CI Green` presently has `if: always()` and eight required leaf jobs, but not `changes`; its shell loop fails only `failure`/`cancelled` and prints that skipped leaves passed. GitHub documents `needs.<job_id>.result` values including `skipped`, and a skipped job itself reports Success, so this is a real false-green path. [CITED: https://docs.github.com/en/enterprise-cloud%40latest/actions/reference/workflows-and-actions/contexts] [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-jobs-with-conditions?apiVersion=2022-11-28] [VERIFIED: codebase — `.github/workflows/ci.yml`]

**Primary recommendation:** Create one shared internal migration-generation/validation seam used by core and inbound tasks; add an Ecto-host proof as a step of the existing required installer lane; and make `CI Green` explicitly accept skipped leaves only after a successful `code=false` detector result.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Generate host migration source | CLI / Mix task | Filesystem | The task owns option validation, repo selection, timestamped filenames, and writing the host-owned migration. |
| Apply and roll back package schema | Database / Storage | Host Ecto migration runner | The generated wrapper is executed inside Ecto's migration runner; package dispatchers own ordered versioned DDL. [CITED: https://ecto-sql.hexdocs.pm/3.8.2/Ecto.Migrator.html] |
| Detect version / legacy shape | Database / Storage | Package migration runner | PostgreSQL catalog metadata and table contents are the source of truth; query failure must not be reclassified as absence. |
| Protect existing host history | Host migration directory | Ecto `schema_migrations` | New upgrades/repairs must add migrations, never rewrite an existing file or applied record. |
| Aggregate merge truth | GitHub Actions workflow | CI meta-tests | `CI Green` consumes direct dependency results and supplies the stable protected context. |

## Standard Stack

### Core

| Library / tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Existing `ecto_sql` | `~> 3.13` | Generated `up/0`/`down/0` execution through Ecto. | The repo already uses `Ecto.Migrator` wrappers and package DDL is written as `Ecto.Migration` instructions. [VERIFIED: codebase — `mix.exs`, `mailglass_inbound/mix.exs`] |
| Existing GitHub Actions | repository workflow | Required-check aggregation. | Keeps the public protected context and current lane topology intact. [VERIFIED: codebase — `.github/workflows/ci.yml`] |

### Supporting

| Library / tool | Purpose | When to Use |
|----------------|---------|-------------|
| Existing `OptionParser` | Strict Mix-task flags. | Parse `--repo`, `--upgrade`, `--from`, and `--repair-legacy`; reject positional/unknown options. [VERIFIED: codebase — both generator tasks] |
| Existing `Ecto.Migrator.with_repo/3` | Start/use the selected host repo for live version inspection. | Live upgrade or legacy safety checks when the task must query the actual host database. [CITED: https://ecto-sql.hexdocs.pm/3.8.2/Ecto.Migrator.html] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Shared internal task helper | Duplicate core/inbound flag logic | Duplication would make different repo inference, timestamp, and fail-closed behavior likely; use one small helper with package-provided callbacks. [VERIFIED: codebase — analogous task patterns are package-local, current generators duplicate timestamp/app parsing] |
| Existing `Installer Host Smoke` lane | New required workflow job | A new job changes lane topology and registries. Add the Ecto proof as a step in the existing required lane. [VERIFIED: codebase — `CILanes` and lane drift tests pin current identities] |

**Installation:** No new package is required. [VERIFIED: codebase]

## Architecture Patterns

### System Architecture Diagram

```text
mix mailglass[.inbound].gen.migration FLAGS
  -> strict flag parser
  -> resolve configured host app + selected Ecto repo
       -> exactly one repo: infer
       -> many/none: require --repo
  -> choose operation
       -> initial: write stable up/down wrapper when absent
       -> upgrade: inspect live anchor OR validate --from; write NEW timestamped wrapper
       -> repair: verify exact toy source + safe catalog state; write NEW repair wrapper
  -> host priv/repo/migrations/<timestamp>_*.exs
  -> mix ecto.migrate / rollback
  -> Mailglass(.Inbound).Migration -> Postgres runner -> versioned DDL + anchor comment

ci.yml changes
  -> code=true or code=false output
  -> all required code leaves
  -> CI Green (always): detector success? -> code policy -> exact leaf results -> protected status
```

### Exact Integration Points

| Concern | Files to change | Required behavior |
|---------|-----------------|-------------------|
| Core generator | `lib/mix/tasks/mailglass.gen.migration.ex` | Replace toy body; parse all four flags; select repo; generate initial/upgrade/repair source through shared helper. |
| Inbound generator | `mailglass_inbound/lib/mix/tasks/mailglass.inbound.gen.migration.ex` | Adopt the identical flag and repo contract while emitting `MailglassInbound.Migration` wrappers. |
| Shared task semantics | New small internal module under `lib/mailglass/` (or a core-owned helper callable by inbound without reverse dependency) | Keep only host-source generation, option/repo/version validation, and file collision logic here; parameterize package module, anchor, version callbacks, and names. Core must not depend on inbound. [VERIFIED: codebase — inbound depends on core, never reverse] |
| Core runner truth | `lib/mailglass/migrations/postgres.ex` and public façade only if needed | Return/raise a typed fail-closed error for query failure, absent/malformed comment, and out-of-range version; return `0` only for no anchor row. |
| Inbound runner truth | `mailglass_inbound/lib/mailglass_inbound/migrations/postgres.ex` and façade only if needed | Mirror core's classification while retaining the independent `mailglass_inbound_records` anchor. |
| Deterministic Ecto-host proof | Extend `scripts/consumer_install_smoke.sh` only if its no-Ecto contract remains intact; otherwise add a sibling `scripts/generated_ecto_host_proof.sh`, invoked by `.github/workflows/ci.yml`'s `installer_host_smoke` job | Provision a stock Phoenix/Ecto/Postgres host, add path deps, run both generators, migrate, persist a delivery, then drive generated-wrapper rollback. Do not hand-write Mailglass DDL. |
| CI aggregate | `.github/workflows/ci.yml` | Make `ci_green.needs` include `changes`; require `changes.result == success`; reject non-boolean/missing `code`; for `code=true`, require every declared required leaf `success`; for `code=false`, permit those leaves to be `skipped` only. |
| CI contracts | `test/scripts/required_checks_test.exs`, `test/scripts/lane_classification_drift_test.exs`, `test/support/ci_yaml.ex`, and/or a focused new aggregate-policy test | Preserve required leaf identity while adding a structural dependency. Parser assertions must compare required leaves separately from `changes`, rather than silently dropping it. |

### Pattern 1: Generated wrapper is host-owned and stable

**What:** Initial wrappers contain only `use Ecto.Migration`, `up`, and `down`, delegated to the package façade; no package DDL is copied into the host file. [VERIFIED: codebase — `Mailglass.Migration`/`MailglassInbound.Migration` module docs]

**When to use:** Fresh installation. The core task must now match the inbound task's existing wrapper shape.

```elixir
# Generated source; package facade owns version dispatch.
defmodule MyApp.Repo.Migrations.MailglassInstall do
  use Ecto.Migration

  def up, do: Mailglass.Migration.up()
  def down, do: Mailglass.Migration.down()
end
```

**Source:** [CITED: https://ecto-sql.hexdocs.pm/3.8.2/Ecto.Migrator.html] [VERIFIED: codebase — `mailglass_inbound/lib/mix/tasks/mailglass.inbound.gen.migration.ex`]

### Pattern 2: Upgrade/repair are additive host migrations

**What:** `--upgrade` and `--repair-legacy` always create distinct timestamped migration files; they never modify the matching install wrapper. An upgrade’s `down/0` passes the validated previous package schema version. [VERIFIED: CONTEXT.md]

**When to use:** Existing host migration directory, whether live version is inspected or `--from` provides offline evidence.

```elixir
# Conceptual generated upgrade source; `prior_version` is a validated literal.
def up, do: Mailglass.Migration.up()
def down, do: Mailglass.Migration.down(version: prior_version)
```

**Source:** [CITED: https://ecto-sql.hexdocs.pm/3.8.2/Ecto.Migrator.html] [VERIFIED: codebase — `lib/mailglass/migrations/postgres.ex`]

### Pattern 3: Three-way version-anchor classification

**What:** Catalog lookup must produce one of: `:absent` (no anchor relation), `{:ok, version}` (single numeric comment in `1..current_version`), or `{:error, reason}`. Only `:absent` maps to public version `0`. [VERIFIED: CONTEXT.md]

**When to use:** Live upgrade generation, repair preflight, and any direct `migrated_version` API path.

**Anti-Patterns to Avoid**

- **Catch-all query fallback:** `{:error, _}` and malformed rows must not become `0`; this makes outage/corruption look like a fresh install. [VERIFIED: codebase — both Postgres runners]
- **Regex-only app-module inference:** `mix.exs` app name cannot decide the migration namespace when the host has multiple repos. Resolve a chosen configured repo first. [VERIFIED: codebase — current generators]
- **Editing an existing wrapper:** It changes source that Ecto may already have applied and cannot repair live schema history. Generate an additive migration instead. [VERIFIED: CONTEXT.md]
- **Repair by table name alone:** Same table name is not proof of the known toy migration; require exact source plus catalog shape and emptiness before any destructive action. [VERIFIED: CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Migration execution | A custom SQL migration runner | Generated `Ecto.Migration` wrappers plus existing package dispatchers | Ecto owns migration locks, transaction/running context, and host `schema_migrations`. [CITED: https://ecto-sql.hexdocs.pm/3.8.2/Ecto.Migrator.html] |
| Repo selection | Filename or module-name guesses | `Application.get_env(host_app, :ecto_repos)` and explicit `--repo` validation | `:ecto_repos` is the host’s declared repository list; a guessed repo is unsafe in multi-repo apps. [VERIFIED: codebase — `reference/host_app/config/config.exs`] |
| CI result policy | Implicit GitHub required-check behavior | Explicit aggregate branch over `needs.changes.result`, output, and every leaf result | GitHub can show a skipped job as success, so the protected aggregate must interpret skips. [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-jobs-with-conditions?apiVersion=2022-11-28] |
| YAML verification | A broad substring assertion | Existing identity-oriented parsers plus targeted negative controls | Repository meta-tests deliberately use non-vacuous parsers and set equality. [VERIFIED: codebase — `test/support/ci_yaml.ex`, `test/scripts/required_checks_test.exs`] |

**Key insight:** The correct small surface is not new migration infrastructure; it is honest generation around the existing Ecto and package-runner infrastructure.

## Common Pitfalls

### Pitfall 1: Upgrade file collides with or rewrites initial install

**What goes wrong:** Re-running an upgrade overwrites an install wrapper or silently returns unchanged.  
**Why it happens:** The core generator currently finds the first `*_mailglass_install.exs` and ignores `--upgrade`. [VERIFIED: codebase — core generator]  
**How to avoid:** Initial mode is idempotent by exact wrapper detection; upgrade/repair modes use a separate timestamped suffix and fail on an intended-file collision, never edit any existing file.  
**Warning signs:** `git diff` changes an existing migration or a second upgrade does not create a new file.

### Pitfall 2: Legacy repair destroys valid data

**What goes wrong:** A broad `DROP TABLE` treats a similarly named or populated table as the known toy output.  
**Why it happens:** The toy generator produced a `mailglass_events` table, but table name alone has no provenance. [VERIFIED: codebase — current core generator]  
**How to avoid:** Make `--repair-legacy` opt-in; require the exact known generated source and a live catalog comparison of columns/types/nullability/defaults/indexes plus a zero-row proof. On ambiguity, populated data, unavailable repo, or query error, raise an actionable `Mix.raise/1` and write nothing. The generated repair migration should preserve the legacy source file and reconstruct the pre-repair toy shape on its own `down/0` only after a successful package rollback.  
**Warning signs:** Any repair path can run from only a filename match, has `CASCADE`, or accepts an error result as empty.

### Pitfall 3: Version zero hides corruption

**What goes wrong:** A missing comment, an invalid value, or database connectivity problem invokes initial migration logic.  
**Why it happens:** Both runner implementations currently use `_ -> 0`; core additionally calls `String.to_integer/1` on an unchecked comment. [VERIFIED: codebase — both Postgres runners]  
**How to avoid:** Require the catalog query to distinguish no row from `[[nil]]`, malformed/non-numeric comments, result shape changes, and query errors; validate the parsed integer against package `initial_version..current_version`.  
**Warning signs:** Tests assert only `0`/current happy paths, or a mocked query error returns `0`.

### Pitfall 4: Aggregate remains green on skipped code work

**What goes wrong:** A detector error causes code lanes to skip, then the aggregate prints success.  
**Why it happens:** The aggregate runs unconditionally but does not depend on `changes`, and its loop excludes `skipped`. [VERIFIED: codebase — `.github/workflows/ci.yml`]  
**How to avoid:** Add `changes` as a direct need; first require `needs.changes.result == 'success'`; then accept exactly `code=true` or `code=false`. In `true`, every declared required leaf must be exactly `success`; in `false`, require leaves to be exactly `skipped` (or use the explicitly documented safe result set if GitHub changes it). Any other result is failure.  
**Warning signs:** Success message contains “passed or were skipped” during a code change.

### Pitfall 5: Existing lane registry test becomes blind

**What goes wrong:** Adding structural `changes` to `ci_green.needs` breaks the old leaf-set equivalence, and a quick test weakening hides a missing required leaf.  
**Why it happens:** `required_checks_test.exs` currently treats all `ci_green.needs` entries as required leaves. [VERIFIED: codebase — `test/scripts/required_checks_test.exs`]  
**How to avoid:** Teach the parser/contract to assert `(needs - {changes}) == required_lanes`, assert `changes` occurs exactly once as a structural dependency, and retain anti-vacuity and deletion negative controls.  
**Warning signs:** A set-difference test filters unknown keys, or no regression test represents failed detector/skipped leaf/docs-only scenarios.

## Code Examples

### CI Green fail-closed decision table

```text
changes.result != success                 -> fail
changes.result == success, code == true   -> every required leaf must be success
changes.result == success, code == false  -> skipped leaves permitted (docs-only)
missing/other code output                 -> fail
```

**Source:** [CITED: https://docs.github.com/en/enterprise-cloud%40latest/actions/reference/workflows-and-actions/contexts] [VERIFIED: CONTEXT.md]

### Generated-host proof minimum

```text
stock Phoenix/Ecto host + Postgres
  -> add local core and inbound deps
  -> configure one host Repo for both packages
  -> mix mailglass.gen.migration --repo Host.Repo
  -> mix mailglass.inbound.gen.migration --repo Host.Repo
  -> mix ecto.migrate
  -> insert/persist a delivery through the real host repo
  -> rollback generated wrappers and assert package relations are removed
```

This must be a real Ecto host rather than the existing `--no-ecto` installer smoke. [VERIFIED: CONTEXT.md] [VERIFIED: codebase — `scripts/consumer_install_smoke.sh`]

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| Core generator writes toy `change/0` table DDL. | Stable wrapper delegates to a package version dispatcher. | Package schemas can evolve without copying DDL into new hosts. [VERIFIED: codebase — current core/inbound generator contrast] |
| Treat skipped aggregate dependencies as harmless. | Interpret `needs.*.result` explicitly based on successful change classification. | Required protected status cannot bless unexecuted code proof. [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-jobs-with-conditions?apiVersion=2022-11-28] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `--from 0` should be rejected for `--upgrade` because zero is the fresh/absent-anchor state, not a prior applied package version. | Architecture Patterns | The exact CLI acceptance matrix may need a small adjustment; it does not alter the fail-closed rule. |
| A2 | A reusable helper can reside in core without creating an inbound-to-core ownership violation. | Exact Integration Points | If packaging/compiler boundaries prohibit it, duplicate only the thin source-rendering adapter while keeping test vectors identical. |

## Open Questions (RESOLVED)

1. **RESOLVED — Exact legacy toy catalog signature**
   - Repair accepts only the byte-for-byte core migration body emitted before Phase 155, whose sole table is `mailglass_events(tenant_id, timestamps)`, together with its exact expected empty catalog shape.
   - Any source or catalog variation, and any populated legacy table, fails closed with manual-remediation guidance.

2. **RESOLVED — Offline `--from 0` policy**
   - `--upgrade --from 0` is invalid and fails with guidance to run initial generation without `--upgrade`.
   - Upgrade mode requires a valid positive version older than the package's current migration version.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir / Mix | generators and tests | ✓ | OTP 28 locally; repository pins Elixir 1.18 / OTP 27 | CI uses `.tool-versions` |
| PostgreSQL client | real generated Ecto-host proof | ✓ | 14.17 client | CI service uses `postgres:16-alpine` |
| Docker | optional local Postgres host proof | ✓ | 29.5.2 | local Postgres service / CI service |
| Node / npm | existing host provisioning dependencies | ✓ | Node 22.14.0 / npm 11.1.0 | not required by migration runner itself |

**Missing dependencies with no fallback:** None identified. [VERIFIED: local environment]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (repository standard) [VERIFIED: codebase] |
| Config file | `test/test_helper.exs`; inbound has `mailglass_inbound/test/test_helper.exs` [VERIFIED: codebase] |
| Quick run command | `mix test test/mix/tasks/mailglass_gen_migration_test.exs test/mailglass/migration_test.exs test/scripts/required_checks_test.exs --warnings-as-errors` (new task test path) |
| Full suite command | `mix test --warnings-as-errors` and `cd mailglass_inbound && mix test --warnings-as-errors` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ADOPT-01 | Generated core/inbound wrappers migrate, persist delivery, and roll back in an Ecto host. | integration / shell | required `Installer Host Smoke` job invokes Ecto-host proof | ❌ Wave 0 |
| ADOPT-02 | Explicit repo, one-repo inference, zero/many rejection. | unit | focused core + inbound Mix task tests | ❌ Wave 0 |
| ADOPT-03 | Upgrade creates new file and generated rollback targets validated prior version. | unit + integration | focused task tests plus wrapper-through-`Ecto.Migrator` test | ❌ Wave 0 |
| ADOPT-04 | `--from` accepts only supported older version; invalid/conflicting flags fail. | unit | focused task tests | ❌ Wave 0 |
| ADOPT-05 | Exact empty toy only repairs; populated/ambiguous state changes nothing. | integration | task/runner tests against scratch Postgres schema | ❌ Wave 0 |
| ADOPT-06 | absent, query error, nil/malformed/out-of-range comment produce distinct outcomes. | unit + integration | core and inbound runner tests | ❌ Wave 0 |
| QUAL-02 | detector failure, skipped code leaf, docs-only skip behavior fail/pass as specified. | meta-test | `mix test test/scripts/required_checks_test.exs test/scripts/lane_classification_drift_test.exs --warnings-as-errors` | partial |

### Sampling Rate

- **Per task commit:** relevant focused ExUnit test files plus `mix format --check-formatted`.
- **Per wave merge:** root and inbound focused migration suites; CI meta-contract suite.
- **Phase gate:** both package suites green, then a CI execution where the preserved `Installer Host Smoke` proves the real Ecto path.

### Wave 0 Gaps

- [ ] Root Mix-task tests for `mailglass.gen.migration` (there is currently no matching task test file). [VERIFIED: codebase]
- [ ] Inbound Mix-task tests for `mailglass.inbound.gen.migration`.
- [ ] Mockable/catalog fixture seam for runner query-result classification; do not depend only on a live happy-path database.
- [ ] Generated Ecto-host proof script/fixture and a contract test that prevents replacing it with `--no-ecto` smoke.
- [ ] Aggregate-policy negative controls that mutate/represent `changes` failure, skipped code leaf, and docs-only classification.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No authentication surface changes. |
| V3 Session Management | no | No session surface changes. |
| V4 Access Control | yes | Explicit repo must be configured and repair must refuse unsafe state; task does not guess target database. |
| V5 Input Validation | yes | Strict options, valid configured module selection, bounded numeric `--from`, validated catalog identifier paths. [VERIFIED: codebase — existing identifier validation / `OptionParser` usage] |
| V6 Cryptography | no | No cryptographic operation is introduced. |

### Known Threat Patterns for Phase 155

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Destructive legacy repair on unrelated/present data | Tampering | Exact source + catalog signature + zero-row precondition; no `CASCADE`; fail before write/DDL. |
| Untrusted CLI module/value creates unsafe selection | Tampering | Parse only expected flags; resolve against declared `:ecto_repos`; do not turn arbitrary strings into atoms. |
| Database/catalog fault masquerades as fresh install | Tampering / Repudiation | Tagged version outcome and explicit error propagation; `0` only for verified absent anchor. |
| Required status approves skipped proof | Repudiation | Explicit `needs` result decision table and regression negative controls. |

## Recommended Plan Decomposition

1. **Migration truth core:** Add the shared generator contract and core/inbound task coverage: repo resolution, stable initial wrappers, timestamped upgrade source, offline validation, and no-rewrite guarantees. This is the smallest tracer and should land before live repair behavior.
2. **Runner and legacy safety:** Make both catalog readers fail closed, then implement the exact toy repair route with database-state negative controls. Keep all shipping migrations untouched.
3. **Real adopter proof:** Add the stock Ecto/Postgres host journey and wire it into the existing `Installer Host Smoke` required lane; prove core + inbound generated wrappers, migration/rollback, and delivery persistence.
4. **CI aggregate truth:** Add `changes` to `CI Green`, implement explicit code/docs result handling, and evolve the lane parser/meta-tests without changing the required check name or lane topology.

The ordering is deliberate: generated-host proof should consume the final task/runner semantics, while CI truth must protect the lane that proves them. [VERIFIED: CONTEXT.md]

## Sources

### Primary (HIGH confidence)

- [Repository core generator](../../../../lib/mix/tasks/mailglass.gen.migration.ex) and [inbound generator](../../../../mailglass_inbound/lib/mix/tasks/mailglass.inbound.gen.migration.ex) — current task options and generated source.
- [Core Postgres runner](../../../../lib/mailglass/migrations/postgres.ex) and [inbound Postgres runner](../../../../mailglass_inbound/lib/mailglass_inbound/migrations/postgres.ex) — current version classification behavior.
- [CI workflow](../../../../.github/workflows/ci.yml), [lane registry](../../../../test/support/ci_lanes.ex), and [lane contracts](../../../../test/scripts/required_checks_test.exs) — protected aggregate and parser seams.
- [Phase context](155-CONTEXT.md) — locked scope and safety decisions.

### Secondary (MEDIUM confidence)

- [Ecto.Migrator API](https://ecto-sql.hexdocs.pm/3.8.2/Ecto.Migrator.html) — wrapper/module migration execution and `with_repo` semantics.
- [GitHub Actions contexts](https://docs.github.com/en/enterprise-cloud%40latest/actions/reference/workflows-and-actions/contexts) — `needs.<job_id>.result` result set.
- [GitHub job conditions](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-jobs-with-conditions?apiVersion=2022-11-28) — skipped-job required-check behavior.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — no new package; existing Ecto, Mix, and Actions seams are directly inspected.
- Architecture: HIGH — exact generators, runners, host smoke, lane registry, and aggregate job inspected.
- Pitfalls: HIGH — each is a current source behavior or locked decision; external result semantics are MEDIUM and cited.

**Research date:** 2026-08-16  
**Valid until:** 2026-09-15 for repository seams; re-check GitHub Actions/Ecto documentation before a delayed implementation.
