# Phase 138: Schema-prefix no-search-path hardening - Research

**Researched:** 2026-07-07  
**Domain:** Elixir/Ecto/Postgres schema-prefix hardening and static regression guards  
**Confidence:** HIGH for codebase inventory; MEDIUM for external documentation fetched through WebSearch instead of Context7

## User Constraints

No `CONTEXT.md` exists for this phase; there are no phase-specific locked user decisions to copy verbatim. [VERIFIED: init.phase-op + codebase grep]

Binding phase constraints come from `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, and `.planning/STATE.md`: Phase 138 must ensure runtime reads/writes that touch mailglass tables still target the configured schema when the DB connection `search_path` does not include that schema. [VERIFIED: .planning/ROADMAP.md]

Locked milestone decision: explicit Ecto `prefix:` remains the correctness mechanism, and `search_path` may be test/host convenience only. [VERIFIED: .planning/STATE.md]

Locked milestone decision: use surgical fixes, hostile runtime tests, and a static guard instead of hand-editing every fixture or migrating the whole suite to no-search-path first. [VERIFIED: .planning/STATE.md]

Out of scope for v2.1: product expansion, new providers/transports/routes, release ceremony, full no-search-path suite migration as a first step, and broader UI verification work. [VERIFIED: .planning/REQUIREMENTS.md]

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SCHEMA-01 | Prove `Mailglass.Webhook.Replay` updates projections in the configured schema under hostile `search_path`. | `Webhook.Replay` has a raw `repo.update/1` inside `Ecto.Multi.run` at `lib/mailglass/webhook/replay.ex:305`; Ecto docs show Multi callbacks receive a raw repo handle, so pass explicit `Repo.multi_opts()` and add a hostile runtime proof. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| SCHEMA-02 | Prove unsubscribe replay/idempotency conflict lookups read from the configured schema under hostile `search_path`. | `UnsubscribeController.canonical_event/3` calls raw `repo.one!/1` at `lib/mailglass/compliance/unsubscribe_controller.ex:120`; query operations need explicit `prefix:` when not routed through the facade. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] |
| SCHEMA-03 | Ensure raw repo calls and transaction callbacks touching mailglass tables are prefixed, facade-routed, or allowlisted; block recurrence with a static guard. | Production Multi update audit found already-safe Outbound steps and missing explicit opts in fake adapter and webhook reconciler projection steps. [VERIFIED: codebase grep] |
| SCHEMA-04 | Inbound repo-option extension points keep the facade by default or document/prove raw-repo prefix contract. | `Ingress.Persist` already passes `schema_opts()` to raw repo calls, while `Internal.Replay`, `Execution.load`, and inbound replay mix-task selector resolution call a supplied raw repo without opts. [VERIFIED: codebase grep] |
| GATE-01 | Expose a focused schema-prefix verification lane. | Add `mix verify.schema_prefix` with focused hostile runtime proofs plus the static guard test/credo lane. [VERIFIED: mix.exs grep] |
| GATE-02 | Keep the dual-schema advisory matrix as a canary, not the only proof. | Existing advisory matrix sets `MAILGLASS_SCHEMA` and patches `search_path`, so it can mask missing-prefix bugs by design. [VERIFIED: .github/workflows/advisory-matrix.yml] |

## Project Constraints (from CLAUDE.md)

- mailglass is an Elixir/Phoenix/Ecto/Postgres library with three sibling packages and no Node toolchain in core work. [VERIFIED: CLAUDE.md]
- Runtime code must route database access through project facades where possible; host apps own the actual repo. [VERIFIED: lib/mailglass/repo.ex] [VERIFIED: mailglass_inbound/lib/mailglass_inbound/repo.ex]
- Telemetry metadata must not include PII such as recipients, subjects, headers, or body content. [VERIFIED: CLAUDE.md]
- `mailglass_events` is append-only; UPDATE/DELETE is intentionally rejected by SQLSTATE 45A01. [VERIFIED: CLAUDE.md] [VERIFIED: lib/mailglass/events/event.ex]
- Multi-tenancy remains `tenant_id` scoping; schema prefix is orthogonal database namespace selection. [VERIFIED: .planning/research/milestone-schema-isolation/SCHEMA-ISOLATION-DESIGN.md]
- Optional dependencies stay gated through `OptionalDeps` modules, but this phase does not add optional dependency work. [VERIFIED: CLAUDE.md] [VERIFIED: mix.exs]
- Existing custom Credo checks are first-class enforcement; new static guards should follow the `credo_checks/*.ex` plus `test/mailglass/credo/*_test.exs` pattern. [VERIFIED: .credo.exs] [CITED: https://credo.hexdocs.pm/adding_checks.html]

## Summary

Phase 138 should be planned as a narrow runtime-hardening and guard phase, not a schema-isolation redesign. The repo already has the v2.0 foundation: `Mailglass.Repo` and `MailglassInbound.Repo` inject `prefix: Config.schema()` on delegated reads/writes, and `Repo.multi_opts/1` exists for raw repo use inside Multi steps. [VERIFIED: lib/mailglass/repo.ex] [VERIFIED: mailglass_inbound/lib/mailglass_inbound/repo.ex]

The risk surface is the gap between facade-routed calls and raw repo handles supplied by `Ecto.Multi.run` callbacks or inbound extension options. Ecto docs state `Multi.run` callbacks receive the repo as the first callback argument, while operation-level opts such as `prefix:` are supplied per operation. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html]

**Primary recommendation:** Fix/prove all production raw-repo mailglass-table operations with explicit `prefix:` opts, then add `mix verify.schema_prefix` that runs hostile no-search-path runtime tests plus a focused AST/static guard; keep the existing dual-schema advisory matrix as a broad canary only. [VERIFIED: .planning/REQUIREMENTS.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Runtime schema targeting | API / Backend | Database / Storage | Ecto call sites decide whether SQL is schema-qualified; Postgres only executes the resulting target. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] |
| Hostile no-search-path proofs | Test / CI | Database / Storage | The proof must run real Postgres operations with a connection path that excludes the configured schema. [VERIFIED: test/mailglass/schema_isolation_immutability_test.exs] |
| Raw-repo recurrence guard | Build / CI | API / Backend | Existing project enforcement lives in custom Credo checks loaded by `.credo.exs`. [VERIFIED: .credo.exs] |
| Inbound repo-option contract | API / Backend | Database / Storage | Inbound extension points accept a repo option; default facade is safe, raw repo options need explicit prefix opts. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex] |
| Dual-schema advisory matrix | CI | Database / Storage | Existing matrix varies `MAILGLASS_SCHEMA` but also patches connection `search_path`, so it is canary coverage rather than fail-closed proof. [VERIFIED: .github/workflows/advisory-matrix.yml] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Elixir / Mix | 1.19.5 local; project floor `~> 1.18` | Test and build runtime | Existing project toolchain; no new language/runtime decision. [VERIFIED: local command] [VERIFIED: mix.exs] |
| Ecto | 3.14.0 locked | Repo API, query prefixes, Multi operations | Official prefix semantics are the core mechanism for schema targeting. [VERIFIED: mix deps + Hex.pm] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] |
| Ecto SQL | 3.14.0 locked | SQL adapter/migration integration | Existing Postgres-backed test/migration stack. [VERIFIED: mix deps + Hex.pm] |
| Postgrex | 0.22.2 locked | PostgreSQL driver | Existing adapter used by Ecto SQL for Postgres. [VERIFIED: mix deps + Hex.pm] |
| Credo | 1.7.19 locked in root | Custom static checks | Project already enforces domain rules with custom Credo checks. [VERIFIED: mix deps + Hex.pm] [VERIFIED: .credo.exs] |
| PostgreSQL | psql 14.17 local; CI service uses `postgres:16-alpine` | Runtime DB proof | Local and CI Postgres are available for schema-prefix proofs. [VERIFIED: local command] [VERIFIED: .github/workflows/advisory-matrix.yml] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| ExUnit | Bundled with Elixir | Focused hostile runtime tests and Credo-check tests | Use for `schema_prefix_hardening` runtime proofs and static guard unit tests. [VERIFIED: test tree] |
| Ecto SQL Sandbox | Existing test harness | Per-test DB ownership | Use for normal runtime proofs; switch to `Sandbox.mode(TestRepo, :auto)` only for DDL/setup that cannot run inside a transactional test. [VERIFIED: test/support/data_case.ex] [VERIFIED: test/mailglass/schema_isolation_immutability_test.exs] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Explicit `prefix:` opts | Mutate connection `search_path` | Rejected by milestone decision and weaker under pooled connections; Postgres docs also make unqualified object resolution path-dependent. [VERIFIED: .planning/STATE.md] [CITED: https://www.postgresql.org/docs/current/ddl-schemas.html] |
| Custom Credo AST check | Shell grep only | Grep is cheap but brittle around comments/tests; project already has AST-based Credo checks and tests. [VERIFIED: credo_checks/no_schema_prefix_attribute.ex] [CITED: https://credo.hexdocs.pm/adding_checks.html] |
| Whole-suite no-search-path migration | Focused hostile lane first | Whole-suite migration is explicitly out of v2.1 first-step scope. [VERIFIED: .planning/REQUIREMENTS.md] |

**Installation:**

```bash
# No new external package installation for Phase 138.
mix deps.get
```

**Version verification:** Root `mix deps` reports `ecto 3.14.0`, `ecto_sql 3.14.0`, `postgrex 0.22.2`, and `credo 1.7.19`; `mix hex.info` confirms public Hex metadata and recent release dates. [VERIFIED: mix deps + Hex.pm]

## Package Legitimacy Audit

Phase 138 should install no new external packages. [VERIFIED: phase scope + mix.exs]

The GSD package-legitimacy seam supports npm/PyPI/crates only and returned a usage error for Hex packages, so no Hex legitimacy verdict is available from that seam. [VERIFIED: gsd-tools package-legitimacy output]

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| ecto | Hex.pm | Existing locked dependency; 3.14.0 released 2026-05-19 | 289,634 last 7 days at check time | github.com/elixir-ecto/ecto | Existing verified dependency | Approved; no install task |
| ecto_sql | Hex.pm | Existing locked dependency; 3.14.0 released 2026-05-19 | 268,515 last 7 days at check time | github.com/elixir-ecto/ecto_sql | Existing verified dependency | Approved; no install task |
| postgrex | Hex.pm | Existing locked dependency; 0.22.2 released 2026-05-12 | 253,317 last 7 days at check time | github.com/elixir-ecto/postgrex | Existing verified dependency | Approved; no install task |
| credo | Hex.pm | Existing locked dependency; 1.7.19 released 2026-06-05 | 234,622 last 7 days at check time | github.com/rrrene/credo | Existing verified dependency | Approved; no install task |

**Packages removed due to [SLOP] verdict:** none.  
**Packages flagged as suspicious [SUS]:** none.  

## Architecture Patterns

### System Architecture Diagram

```text
Webhook replay / unsubscribe / inbound replay input
  -> tenant-scoped query construction
  -> Mailglass.Config.schema() / MailglassInbound.Config.schema()
  -> one of:
       A. facade call: Mailglass.Repo.* / MailglassInbound.Repo.*
       B. raw repo call with explicit prefix opts
       C. allowlisted schema-agnostic raw SQL
  -> Ecto/Postgrex SQL targets configured schema
  -> hostile DB connection search_path excludes configured schema
  -> runtime assertion checks configured-schema rows changed/read
  -> mix verify.schema_prefix runs proofs + static guard
```

This data flow is the planning target: every mailglass-table access must pass through A or B; C is only for statements that cannot touch mailglass tables, such as `SET LOCAL statement_timeout` or advisory-lock SQL. [VERIFIED: codebase grep]

### Recommended Project Structure

```text
lib/
├── mailglass/
│   ├── webhook/replay.ex                 # add explicit raw-repo projection opts
│   ├── compliance/unsubscribe_controller.ex
│   ├── adapters/fake.ex                  # audit/fix Multi.update projection opts
│   └── webhook/reconciler.ex             # audit/fix Multi.update projection opts
├── mailglass_inbound/
│   ├── internal/replay.ex                # make raw-repo prefix contract explicit
│   ├── execution.ex                      # make raw-repo prefix contract explicit
│   └── mix/tasks/mailglass.inbound.replay.ex
credo_checks/
└── raw_repo_prefix_contract.ex           # recommended static guard
test/
├── mailglass/schema_prefix_hardening_test.exs
├── mailglass/credo/raw_repo_prefix_contract_test.exs
└── mailglass_inbound/schema_prefix_contract_test.exs
```

The exact guard filename is a recommendation, but the custom-check location and test pairing follow existing project convention. [VERIFIED: test/mailglass/credo/checks_have_tests_test.exs] [ASSUMED]

### Pattern 1: Raw Multi Callback Writes Must Carry Prefix

**What:** When an `Ecto.Multi.run` callback receives `repo`, use explicit `Mailglass.Repo.multi_opts()` for any raw write against mailglass tables. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] [VERIFIED: lib/mailglass/webhook/ingest.ex]

**When to use:** Use inside `Multi.run` callbacks and callback modules that receive the host repo rather than `Mailglass.Repo`. [VERIFIED: codebase grep]

**Example:**

```elixir
# Source: existing safe pattern in lib/mailglass/webhook/ingest.ex
case repo.update(changeset, Repo.multi_opts()) do
  {:ok, _projected} -> {:ok, {:matched, delivery, inserted_event}}
  {:error, reason} -> {:error, reason}
end
```

### Pattern 2: Raw Multi Callback Reads Must Carry Prefix

**What:** For conflict/idempotency lookups inside a Multi callback, pass prefix opts directly to the raw repo call. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html]

**When to use:** Use when the facade lacks a helper such as `one!/2`, or when the callback repo is required to stay inside the transaction. [VERIFIED: lib/mailglass/compliance/unsubscribe_controller.ex]

**Example:**

```elixir
# Source: recommended Phase 138 pattern
repo.one!(
  from(event in Event,
    where: event.delivery_id == ^delivery.id,
    limit: 1
  ),
  Repo.multi_opts()
)
```

### Pattern 3: Inbound Raw Repo Extension Points Need Local Schema Opts

**What:** Inbound code that accepts `repo:` should keep `MailglassInbound.Repo` as the default and pass `prefix: MailglassInbound.Config.schema()` when the supplied repo may be raw. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex]

**When to use:** Use in `Internal.Replay`, `Execution.load`, and mix-task selector resolution if they keep accepting raw repos. [VERIFIED: codebase grep]

**Example:**

```elixir
# Source: existing safe pattern in mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex
defp schema_opts, do: [prefix: MailglassInbound.Config.schema()]

query
|> repo.one(schema_opts())
```

### Pattern 4: Hostile No-search-path Runtime Proof

**What:** Build test data in the configured schema, then force the test connection path to exclude that schema and assert the runtime path still succeeds. [VERIFIED: test/mailglass/schema_isolation_immutability_test.exs]

**When to use:** Use for SCHEMA-01 and SCHEMA-02 proofs and for the inbound raw-repo contract test. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**

```elixir
# Source: recommended Phase 138 test shape
Application.put_env(:mailglass, :schema, "mailglass")
:persistent_term.erase({Mailglass.Config, :schema})
TestRepo.query!("SET search_path TO public")

assert {:ok, result} = Mailglass.Webhook.Replay.execute(attrs)
assert result.status in [:replayed, :noop]
assert prefixed_row_changed?("mailglass", delivery.id)
```

### Anti-Patterns to Avoid

- **Relying on the dual-schema advisory matrix as the only proof:** That matrix patches `search_path`, so it can hide unqualified runtime calls. [VERIFIED: .github/workflows/advisory-matrix.yml]
- **Adding `@schema_prefix`:** v2.0 explicitly chose runtime prefixing and already has a Credo guard against schema-prefix attributes. [VERIFIED: credo_checks/no_schema_prefix_attribute.ex]
- **Assuming a struct-loaded prefix is enough:** Ecto schema operations may use struct/changeset prefix metadata, but explicit operation opts are clearer and override metadata. [CITED: https://hexdocs.pm/ecto/multi-tenancy-with-query-prefixes.html]
- **String-grepping arbitrary SQL as the whole guard:** Ecto AST-based Credo checks are already available and less noisy for production Elixir call sites. [CITED: https://credo.hexdocs.pm/adding_checks.html] [VERIFIED: credo_checks/no_schema_prefix_attribute.ex]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Schema targeting | Connection-level `search_path` manager | Ecto `prefix:` opts via facade or raw call opts | Postgres resolves unqualified names from `search_path`; project decision rejects this as correctness mechanism. [CITED: https://www.postgresql.org/docs/current/ddl-schemas.html] [VERIFIED: .planning/STATE.md] |
| Multi transaction prefixing | A wrapper assuming transaction opts affect inner steps | Per-operation opts such as `Repo.multi_opts()` | Ecto.Multi operations carry their own opts; callbacks receive a repo handle. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| Static guard | Ad hoc grep over all files | Custom Credo check with path and call-shape allowlists | Project already loads and tests domain-specific Credo checks. [VERIFIED: .credo.exs] |
| Inbound raw repo support | Duplicated raw query helpers per call site | One `schema_opts()` helper per module or route through `MailglassInbound.Repo` | Existing `Ingress.Persist` pattern is already safe and local. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex] |

**Key insight:** The hard problem is not adding `prefix:` once; it is preventing facade bypasses introduced through transaction callback repos and extension-point repos. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Multi Callback Repo Bypasses the Facade

**What goes wrong:** A callback uses `repo.update/1`, `repo.one!/1`, or `repo.get/2` without opts, so the operation resolves through struct metadata or connection `search_path` rather than the configured schema contract. [VERIFIED: codebase grep]  
**Why it happens:** Ecto.Multi passes the raw repo into `run` callbacks. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]  
**How to avoid:** Pass `Repo.multi_opts()` or a package-local `schema_opts()` to every raw repo call that touches mailglass tables. [VERIFIED: lib/mailglass/webhook/ingest.ex]  
**Warning signs:** `fn repo, changes ->` followed by `repo.one`, `repo.update`, `repo.insert`, `repo.get`, or `repo.delete_all` without a final opts argument. [VERIFIED: codebase grep]

### Pitfall 2: Existing Advisory Matrix Masks Missing Prefixes

**What goes wrong:** A runtime path passes in the `schema: mailglass` advisory row because the test harness also puts the schema in `search_path`. [VERIFIED: .github/workflows/advisory-matrix.yml]  
**Why it happens:** The matrix was designed as broad full-suite canary coverage after v2.0, not as a hostile no-search-path proof. [VERIFIED: .planning/STATE.md]  
**How to avoid:** Add focused tests that set `Config.schema()` to the isolated schema and force the connection `search_path` to exclude it. [VERIFIED: .planning/REQUIREMENTS.md]  
**Warning signs:** A test proves `MAILGLASS_SCHEMA=mailglass` but does not assert the connection path excludes `mailglass`. [VERIFIED: test/test_helper.exs]

### Pitfall 3: Inbound Raw Repo Options Look Safe Because the Default Is Safe

**What goes wrong:** `repo = Keyword.get(opts, :repo, MailglassInbound.Repo)` is safe by default, but caller-supplied raw repos do not inject prefix unless each call passes opts. [VERIFIED: codebase grep]  
**Why it happens:** The default facade and raw repo share the same function names, but only the facade's functions call `put_prefix/1`. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/repo.ex]  
**How to avoid:** Either do not expose raw repo options for schema-touching paths, or document/test that raw repos must accept explicit `prefix:` opts passed by mailglass_inbound. [VERIFIED: .planning/REQUIREMENTS.md]  
**Warning signs:** `repo.one()` or `repo.get()` in inbound code that accepts a `:repo` option. [VERIFIED: codebase grep]

### Pitfall 4: Overbroad Static Guard Creates Noise

**What goes wrong:** A guard flags tests, migrations, schema-agnostic advisory locks, and `SET LOCAL` timeout statements, causing maintainers to disable or weaken it. [VERIFIED: codebase grep]  
**Why it happens:** Raw repo calls are legitimate in migrations, setup helpers, and schema-agnostic SQL. [VERIFIED: test/support/citext_probe.ex] [VERIFIED: mailglass_inbound/lib/mailglass_inbound/internal/prune.ex]  
**How to avoid:** Scope the guard to production paths and require an explicit allowlist with comments for schema-agnostic calls. [VERIFIED: .credo.exs]  
**Warning signs:** Guard failures in `test/`, `priv/repo/migrations`, or SQL that does not name mailglass tables. [VERIFIED: codebase grep]

## Code Examples

### Safe Core Projection Update

```elixir
# Source: lib/mailglass/webhook/ingest.ex
case repo.update(changeset, Repo.multi_opts()) do
  {:ok, _projected} -> {:ok, {:matched, delivery, inserted_event}}
  {:error, reason} -> {:error, reason}
end
```

### Safe Inbound Raw Repo Query

```elixir
# Source: mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex
defp schema_opts, do: [prefix: MailglassInbound.Config.schema()]

repo.one(query, schema_opts())
```

### Static Guard Test Pattern

```elixir
# Source: existing project pattern in test/mailglass/credo/no_schema_prefix_attribute_test.exs
source
|> Credo.SourceFile.parse("lib/mailglass/example.ex")
|> Mailglass.Credo.RawRepoPrefixContract.run([])
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Runtime correctness was partly inferred from `MAILGLASS_SCHEMA=mailglass` full-suite advisory rows. | Focused hostile no-search-path runtime proofs plus static guard. | v2.1 Phase 138 requirement, 2026-07-07. | The proof fails closed on missing `prefix:` instead of relying on a helper path. [VERIFIED: .planning/REQUIREMENTS.md] |
| Schema isolation depended on facade prefixing for normal reads/writes. | Facade stays primary, raw callback repos must carry per-operation prefix opts. | v2.0 foundation plus v2.1 hardening. | Multi callbacks and repo-option extensions become explicit contracts. [VERIFIED: lib/mailglass/repo.ex] |
| Raw DDL trigger/function qualification was the main no-search-path proof. | Runtime read/write paths now get equivalent hostile proof. | v2.0 MIGR-05 to v2.1 SCHEMA-01/02. | DDL and runtime paths are verified separately. [VERIFIED: test/mailglass/schema_isolation_immutability_test.exs] |

**Deprecated/outdated:**

- Treating `search_path` mutation as the correctness mechanism is outdated for this project; v2.0 and v2.1 decisions require explicit qualification. [VERIFIED: .planning/STATE.md]
- Treating the dual-schema advisory matrix as sufficient proof is outdated for this milestone. [VERIFIED: .planning/REQUIREMENTS.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The static guard can be implemented as a new custom Credo check rather than a shell script. [ASSUMED] | Recommended Project Structure | If the AST shape is more complex than expected, the planner should fall back to a narrower ExUnit source-scanner guard for Phase 138. |

## Open Questions (RESOLVED)

1. **RESOLVED: Should fake adapter and webhook reconciler projection updates be included in Phase 138?**
   - What we know: They are production Multi update steps touching `mailglass_deliveries` without explicit opts, found at `lib/mailglass/adapters/fake.ex:177` and `lib/mailglass/webhook/reconciler.ex:177/349`. [VERIFIED: codebase grep]
   - What's unclear: The named success criteria call out `Webhook.Replay` and unsubscribe, but SCHEMA-03 covers raw callbacks touching mailglass tables generally. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/REQUIREMENTS.md]
   - Recommendation: Include them in the SCHEMA-03 audit/fix unless a planner-level task explicitly proves they are safe under hostile `search_path` and documents the allowlist. [ASSUMED]
   - Resolution: Plan `138-03` includes `lib/mailglass/adapters/fake.ex` and `lib/mailglass/webhook/reconciler.ex` projection updates under SCHEMA-03, plus a static guard so future raw callback table operations are prefixed, facade-routed, or explicitly allowlisted.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | ExUnit, Mix aliases, Credo | yes | 1.19.5 local | CI uses configured setup-beam rows. [VERIFIED: local command] |
| Erlang/OTP | Elixir runtime | yes | OTP 28 local | CI required row uses OTP 27; advisory row uses OTP 28. [VERIFIED: local command] [VERIFIED: .github/workflows/advisory-matrix.yml] |
| Mix | build/test aliases | yes | 1.19.5 local | none needed. [VERIFIED: local command] |
| PostgreSQL server | hostile runtime proof | yes | local `/tmp:5432` accepting connections | CI service `postgres:16-alpine`. [VERIFIED: pg_isready] [VERIFIED: .github/workflows/advisory-matrix.yml] |
| psql | manual DB inspection | yes | 14.17 local | Ecto/Postgrex queries from tests. [VERIFIED: local command] |
| Hex public registry | version metadata | yes with expired auth warning for private resources | public `mix hex.info` succeeded | No private Hex access required. [VERIFIED: mix hex.info output] |

**Missing dependencies with no fallback:** none found for planning. [VERIFIED: local command]  
**Missing dependencies with fallback:** Context7/ctx7 unavailable; official docs were fetched through WebSearch and tagged as cited official docs. [VERIFIED: ctx7 command] [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with Ecto SQL Sandbox. [VERIFIED: test/support/data_case.ex] |
| Config file | `config/test.exs` plus `test/test_helper.exs` and `mailglass_inbound/test/test_helper.exs`. [VERIFIED: codebase grep] |
| Quick run command | `mix verify.schema_prefix` after alias is added. [VERIFIED: .planning/REQUIREMENTS.md] |
| Full suite command | `mix ci` for local full parity; advisory dual-schema matrix remains separate. [VERIFIED: mix.exs] |

### Phase Requirements to Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| SCHEMA-01 | Webhook replay projection update succeeds and mutates configured-schema delivery under hostile `search_path`. | integration | `mix test test/mailglass/schema_prefix_hardening_test.exs --only schema_prefix` | No; Wave 0 create. |
| SCHEMA-02 | Unsubscribe idempotency conflict lookup reads existing configured-schema event under hostile `search_path`. | integration | `mix test test/mailglass/schema_prefix_hardening_test.exs --only schema_prefix` | No; Wave 0 create. |
| SCHEMA-03 | Production raw repo/Multi callbacks touching mailglass tables are prefixed/facade-routed/allowlisted. | static + unit | `mix test test/mailglass/credo/raw_repo_prefix_contract_test.exs` and `mix credo --strict` | No; Wave 0 create. |
| SCHEMA-04 | Inbound repo-option extension points default to facade and raw-repo calls carry explicit prefix opts or have tested contract. | integration + unit | `cd mailglass_inbound && mix test test/mailglass_inbound/schema_prefix_contract_test.exs` | No; Wave 0 create. |
| GATE-01 | Focused lane runs runtime proofs and static guard. | alias smoke | `mix verify.schema_prefix` | No; Wave 0 alias. |
| GATE-02 | Advisory matrix remains documented as canary only. | source assertion or review | `rg -n "canary|focused no-search-path|verify.schema_prefix" .github .planning mix.exs` | No; Wave 0/closeout update. |

### Sampling Rate

- **Per task commit:** `mix verify.schema_prefix` once added. [VERIFIED: .planning/REQUIREMENTS.md]
- **Per wave merge:** `mix verify.schema_prefix` plus affected package focused tests. [VERIFIED: phase scope]
- **Phase gate:** `mix verify.schema_prefix`; `mix credo --strict`; affected inbound focused test command; broad advisory remains canary. [VERIFIED: .planning/REQUIREMENTS.md]

### Wave 0 Gaps

- [ ] `test/mailglass/schema_prefix_hardening_test.exs` covering SCHEMA-01 and SCHEMA-02. [VERIFIED: test tree]
- [ ] `credo_checks/raw_repo_prefix_contract.ex` plus `test/mailglass/credo/raw_repo_prefix_contract_test.exs` or a narrower source-scanner equivalent. [VERIFIED: credo_checks tree] [ASSUMED]
- [ ] `mailglass_inbound/test/mailglass_inbound/schema_prefix_contract_test.exs` covering SCHEMA-04 raw-repo extension points. [VERIFIED: mailglass_inbound/test tree]
- [ ] `mix.exs` alias and `cli.preferred_envs` entry for `verify.schema_prefix`. [VERIFIED: mix.exs]

## Security Domain

Security enforcement is enabled by default because `.planning/config.json` does not set `security_enforcement: false`. [VERIFIED: .planning/config.json]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | no | No authentication flow changes in this phase. [VERIFIED: phase scope] |
| V3 Session Management | no | No session/cookie lifecycle changes in this phase. [VERIFIED: phase scope] |
| V4 Access Control | yes | Tenant scope plus configured schema prefix must compose; hostile tests verify schema boundary. [VERIFIED: Mailglass.Tenancy usage grep] |
| V5 Input Validation | yes | Schema names must continue through existing identifier validation; raw SQL should not interpolate unvalidated schema names. [VERIFIED: .planning/STATE.md] |
| V6 Cryptography | no | No new cryptographic operations or token format changes. [VERIFIED: phase scope] |

OWASP ASVS is a web application security verification standard and latest stable version is listed as 5.0.0 on the OWASP project page. [CITED: https://owasp.org/www-project-application-security-verification-standard/]

### Known Threat Patterns for Elixir/Ecto/Postgres Schema Hardening

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-schema data confusion when unqualified queries hit `public` instead of configured schema | Information Disclosure / Tampering | Explicit Ecto `prefix:` opts or facade-routed calls. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html] |
| `search_path` shadowing or path-dependent object resolution | Tampering / Elevation of Privilege | Do not rely on mutable `search_path`; qualify table targets via Ecto prefix. [CITED: https://www.postgresql.org/docs/current/ddl-schemas.html] |
| Raw SQL/schema-name injection | Tampering | Continue using validated identifiers and avoid string interpolation for untrusted values. [VERIFIED: .planning/STATE.md] |
| PII leakage in new test/log diagnostics | Information Disclosure | Keep telemetry/log metadata to IDs, counts, schema names, and status; never include addresses, subjects, headers, or bodies. [VERIFIED: CLAUDE.md] |

## Sources

### Primary (HIGH confidence)

- `CLAUDE.md` - project constraints, no Node core toolchain, telemetry/PII rules, append-only event ledger, custom Credo policy. [VERIFIED: local file]
- `.planning/REQUIREMENTS.md` - SCHEMA-01..04 and GATE-01..02 phase requirements. [VERIFIED: local file]
- `.planning/ROADMAP.md` - Phase 138 goal and success criteria. [VERIFIED: local file]
- `.planning/STATE.md` - v2.1 locked decisions and v2.0 follow-up context. [VERIFIED: local file]
- `lib/mailglass/repo.ex` and `mailglass_inbound/lib/mailglass_inbound/repo.ex` - facade prefix behavior. [VERIFIED: local file]
- Codebase grep over `lib`, `mailglass_inbound/lib`, `test`, `.github`, and `mix.exs` - raw repo/Multi call inventory and verification lanes. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)

- Ecto.Repo official docs - Repo `:prefix` option, transactions, Multi execution. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html]
- Ecto.Multi official docs - Multi operation opts and run callback semantics. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]
- Ecto query-prefix guide - prefix precedence and schema operation override behavior. [CITED: https://hexdocs.pm/ecto/multi-tenancy-with-query-prefixes.html]
- Credo official docs - custom checks, `:requires`, and AST traversal. [CITED: https://credo.hexdocs.pm/adding_checks.html]
- PostgreSQL official docs - schemas, default `search_path`, and secure schema usage. [CITED: https://www.postgresql.org/docs/current/ddl-schemas.html]
- PostgreSQL `CREATE FUNCTION` docs - secure function `search_path` examples. [CITED: https://www.postgresql.org/docs/current/sql-createfunction.html]
- OWASP ASVS project page - ASVS purpose and latest stable version. [CITED: https://owasp.org/www-project-application-security-verification-standard/]

### Tertiary (LOW confidence)

- A1 static guard exact implementation shape; planner should validate the AST matcher design while implementing. [ASSUMED]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - verified from `mix deps`, `mix.lock`, and public Hex metadata. [VERIFIED: mix deps + Hex.pm]
- Architecture: HIGH - based on local source inventory and existing v2.0 research/implementation. [VERIFIED: codebase grep]
- Ecto/Postgres semantics: MEDIUM - official docs were fetched through WebSearch because Context7/ctx7 was unavailable. [CITED: https://hexdocs.pm/ecto/Ecto.Repo.html]
- Pitfalls: HIGH for local call-site risks; MEDIUM for external mechanics. [VERIFIED: codebase grep] [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]

**Research date:** 2026-07-07  
**Valid until:** 2026-08-06 for Ecto/Postgres/Credo mechanics; revisit sooner if the project changes repo facade or Ecto major version. [ASSUMED]
