# Requirements: mailglass — v2.0 Postgres Schema Isolation

> **Milestone v2.0 (breaking).** Default all mailglass domain tables into a dedicated `"mailglass"`
> Postgres SCHEMA (explicit `"public"` opt-out) with a first-class codemod upgrade path.
> Derived directly from the LOCKED design dossier
> `.planning/research/milestone-schema-isolation/SCHEMA-ISOLATION-DESIGN.md` (§0–§7).
> Traceability (REQ → phase) is filled by the roadmap.

---

## Milestone v2.0 Requirements

### SCHEMA — Config + identifier foundation (Phase A)

- [x] **SCHEMA-01**: An adopter can set `config :mailglass, :schema, "<name>"`; unset defaults to
  `"mailglass"`, and `"public"` is the explicit pre-2.0 opt-out (documented in the config key `:doc`).
- [x] **SCHEMA-02**: `Mailglass.Config.schema/0` returns the validated schema name, is validated at boot
  (`validate_at_boot!/0` fails fast on a malformed identifier), and is cached in `:persistent_term` so
  the hot path never calls `Application.get_env` per operation.
- [x] **SCHEMA-03**: A shared `Mailglass.Identifier.validate!/2` (promoted from
  `Migrations.Postgres.validate_identifier!/2`) rejects any value that is not a valid unquoted Postgres
  identifier (`[a-zA-Z_][a-zA-Z0-9_]*`), and both config-boot and migration validation use it.
- [ ] **SCHEMA-04**: `mailglass_inbound` mirrors the same contract on its own line —
  `config :mailglass_inbound, :schema` (default `"mailglass"`), a validated accessor, boot validation,
  and a `:persistent_term` cache — reusing `Mailglass.Identifier`.

### FACADE — Repo prefix injection (Phase B)

- [ ] **FACADE-01**: Every `Mailglass.Repo` delegated call (`insert/update/delete/one/all/get/aggregate/
  delete_all`) injects `prefix: Config.schema()` via `put_prefix/1` (using `Keyword.put_new` so an
  explicit caller-supplied `:prefix` still wins). NO `@schema_prefix` is declared on any schema.
- [ ] **FACADE-02**: Every `Ecto.Multi` builder that writes a mailglass table
  (`Events.append_multi`/`insert_opts`, `Outbound` insert/insert_all/update, `Suppression.Escalation`)
  threads `prefix:` per-step via a shared `multi_opts/1`, so no step falls back to the connection schema.
- [ ] **FACADE-03**: `mailglass_admin` requires zero code changes — its `Operator.*` reads land in the
  configured schema through the facade — proven by an admin integration test booting against a
  schema-isolated DB and asserting the dashboard renders.
- [ ] **FACADE-04**: A dedicated schema-isolation integration test creates the schema, migrates,
  round-trips insert/read, and asserts mailglass tables exist under `mailglass.*` while `public` holds
  none of them; the full core suite runs green under BOTH `schema: "public"` and `schema: "mailglass"`
  (new CI matrix axis).

### MIGR — Migration entrypoint + raw-DDL qualification (Phase C)

- [ ] **MIGR-01**: `Mailglass.Migration.up/down` inject `prefix: Config.schema()` so the version
  dispatcher (v01–v05) threads the configured schema into every structural DDL statement.
- [ ] **MIGR-02**: `Migrations.Postgres.up/1` issues `CREATE SCHEMA IF NOT EXISTS` for a non-public
  prefix, honoring an explicit `create_schema: false` escape hatch (locked-down prod role); `down/1`
  drops the schema with `RESTRICT` only if it was created and only after all tables are gone.
- [ ] **MIGR-03**: The events immutability trigger + function are schema-qualified and created IN the
  configured schema (`<schema>.mailglass_raise_immutability`), with `SET search_path = ''` on the
  function, so two installs in different schemas of one database never collide on a global function name.
- [ ] **MIGR-04**: The v01/v03 CHECK constraints and every `down/0` raw `execute()` drop
  (trigger/function/table) are hand-qualified to the runtime prefix (Ecto does not prefix raw SQL).
- [ ] **MIGR-05**: `citext` is created UNqualified (stays in `public`); migrating up/down against a
  non-public prefix succeeds, and a regression test proves the immutability trigger raises SQLSTATE
  45A01 under the `mailglass` schema WITHOUT any `search_path` pin.
- [ ] **MIGR-06**: A grep/Credo guard fails the build if any mailglass schema module declares
  `@schema_prefix` (enforces the pure-runtime-prefix decision and blocks the read-vs-write precedence
  inversion).

### INB — Inbound package (Phase D)

- [ ] **INB-01**: `MailglassInbound.Repo` threads `put_prefix/1` through its delegated reads/writes and
  `multi_opts/1` through its Multi builders, resolving inbound tables to the configured schema.
- [ ] **INB-02**: Inbound's loose `change/0` migration files are converted to the same prefix-aware
  version-dispatcher pattern core uses (`MailglassInbound.Migration.up/down` + `Migrations.Postgres.VNN`),
  issuing `CREATE SCHEMA IF NOT EXISTS` at the head and threading `prefix:` into every
  `create table`/`index`/`references`.
- [ ] **INB-03**: The inbound suite runs green under both `schema: "public"` and `schema: "mailglass"`.

### UPG — Upgrade tooling + docs (Phase E)

- [ ] **UPG-01**: `mix mailglass.upgrade.v2_schema` generates a Route B move migration that
  `CREATE SCHEMA`s, `ALTER TABLE … SET SCHEMA`s all four core tables under `SET LOCAL lock_timeout`,
  and recreates the immutability trigger+function schema-qualified — with a working `down/0`.
- [ ] **UPG-02**: `guides/upgrading-to-v2_0.md` documents both routes (Route A one-line `"public"`
  opt-out; Route B move), the `create_schema: false` grants, the `public.mailglass_*` literal-SQL grep
  checklist, and the `lock_timeout`+retry locking posture.
- [ ] **UPG-03**: `api_stability.md` (core + inbound) documents the `:schema` config contract as a
  stable 2.0 surface, and the tenancy-vs-schema orthogonality is stated so no one conflates `:schema`
  with per-tenant prefixes.
- [ ] **UPG-04**: The `mix mailglass.upgrade.v2_schema` codemod is run end-to-end against
  `reference/host_app` (frozen baseline) and asserted green.

### REL — Release cut + milestone closeout (Phase F)

- [ ] **REL-01**: A linked-version 2.0 release is cut — core + admin `2.0.0`, paired inbound bump
  (sibling-pin drag) — with the coordinated 5-file reference-baseline update applied.
- [ ] **REL-02**: Hex resolution, the consumer smoke, and post-publish smoke are confirmed green for
  all three published packages.
- [ ] **REL-03**: The milestone audit runs `status: passed` and the milestone is archived.

---

## Out of Scope (explicit exclusions — v2.0)

- **Per-tenant schemas.** `:schema` is one fixed library schema, not a Triplex-style per-tenant prefix.
  Multi-tenant *data* isolation remains `tenant_id` scoping (orthogonal; composes with the prefix).
- **Mutating the connection `search_path`.** Rejected on principle (PgBouncer transaction-mode leak,
  CVE-2018-1058, plan-cache invalidation). Explicit per-query/per-DDL qualification only.
- **Moving `citext` out of `public`.** Kept in `public` deliberately (case-insensitive operator
  resolution depends on `public` staying on the path).
- **MySQL/SQLite.** Still Postgres-only.
- **Changing the `tenant_id`-on-every-row model.** Unaffected.
- **Runtime schema switching per request.** The schema is a boot-time constant.
- **New product capability / providers / transports / routes.** D-23 convergence holds.

## Future Requirements (deferred, not this milestone)

- Optional `mix mail.doctor` check that verifies citext operators resolve on the configured path
  (design §6 footgun 1 mitigation; nice-to-have, can follow the 2.0 release).
- Making the `DROP EXTENSION citext` on full teardown opt-in (design §3.6 note).

---

## Traceability

| REQ-ID | Phase | Status |
|--------|-------|--------|
| SCHEMA-01 | Phase 132 | Complete |
| SCHEMA-02 | Phase 132 | Complete |
| SCHEMA-03 | Phase 132 | Complete |
| SCHEMA-04 | Phase 132 | Pending |
| FACADE-01 | Phase 133 | Pending |
| FACADE-02 | Phase 133 | Pending |
| FACADE-03 | Phase 133 | Pending |
| FACADE-04 | Phase 133 | Pending |
| MIGR-01 | Phase 134 | Pending |
| MIGR-02 | Phase 134 | Pending |
| MIGR-03 | Phase 134 | Pending |
| MIGR-04 | Phase 134 | Pending |
| MIGR-05 | Phase 134 | Pending |
| MIGR-06 | Phase 134 | Pending |
| INB-01 | Phase 135 | Pending |
| INB-02 | Phase 135 | Pending |
| INB-03 | Phase 135 | Pending |
| UPG-01 | Phase 136 | Pending |
| UPG-02 | Phase 136 | Pending |
| UPG-03 | Phase 136 | Pending |
| UPG-04 | Phase 136 | Pending |
| REL-01 | Phase 137 | Pending |
| REL-02 | Phase 137 | Pending |
| REL-03 | Phase 137 | Pending |
