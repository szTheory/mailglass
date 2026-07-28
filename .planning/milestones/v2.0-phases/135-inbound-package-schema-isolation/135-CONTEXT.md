# Phase 135: Inbound package schema isolation - Context

**Gathered:** 2026-07-03 (assumptions mode + research-driven refinement)
**Status:** Ready for planning

<domain>
## Phase Boundary

Design Phase D of the v2.0 Postgres Schema Isolation milestone: mirror the core
schema-isolation mechanism (Phases 132–134) onto the `mailglass_inbound` sibling
package. Two deliverables, both scoped to `mailglass_inbound/`:

1. **Facade threading** — wire the already-built `MailglassInbound.Config.schema/0`
   accessor through `MailglassInbound.Repo` so inbound's 3 tables resolve to the
   configured schema (INB-01).
2. **Migration conversion** — convert inbound's 7 loose `change/0` `.exs` files to
   the same prefix-aware version-dispatcher pattern core uses, issuing
   `CREATE SCHEMA IF NOT EXISTS` at the head (INB-02), proven green under both
   `schema: "public"` and `schema: "mailglass"` (INB-03).

**In scope:** `mailglass_inbound/` only. Inbound owns 3 tables
(`mailglass_inbound_records`, `_evidence`, `_replay_runs`) with **only internal
FKs** (records ← evidence ← replay_runs) and **no cross-package FK** to core → no
cross-schema FK hazard. Inbound's one cross-package touch is a *read* of core
suppression via `Mailglass.SuppressionStore.Ecto` → routes through `Mailglass.Repo`
(already core-prefixed). **Out of scope:** the upgrade codemod + docs (Phase 136),
the linked 2.0 release ceremony (Phase 137), any core/admin change.
</domain>

<decisions>
## Implementation Decisions

### Area 1 — Facade threading + the `prune.ex` bypass (INB-01)

- **D-01:** Thread a **private** `put_prefix/1` helper
  (`Keyword.put_new(opts, :prefix, MailglassInbound.Config.schema())`) through the
  facade's delegated reads/writes in `MailglassInbound.Repo`: `insert/2`, `one/2`,
  `all/2`, `get/3`. Use `Keyword.put_new` so an explicit caller-supplied `:prefix`
  (tests / advanced adopters) still wins. This mirrors the locked Phase 133 core
  facade shape (`lib/mailglass/repo.ex`). The accessor consumed is
  `MailglassInbound.Config.schema/0` (arity 0, `String.t()`, default `"mailglass"`,
  persistent_term-cached) — **already built in Phase 132 (D-12..D-15); Phase 135
  CONSUMES it, does not build it.**
  - `transact/2` is **not** prefixed at the executor (its inner `insert`/`one` carry
    their own prefix — matches core's `transact/2`). `multi/2` is not prefixed at
    the executor (that's what a `multi_opts/1` would be for — see D-03).

- **D-02 (load-bearing correctness fix — NOT in the roadmap success criteria):**
  Qualify the facade-bypass in `mailglass_inbound/lib/mailglass_inbound/internal/prune.ex`.
  Prune **deliberately** resolves the raw host repo (`host_repo/0`) — not the facade —
  because its batched-delete + session advisory-lock design needs `checkout/1` (to pin
  one connection across per-batch transactions), `delete_all/2`, and `query!/2`, none of
  which the thin facade exposes. **Fix:** add `prefix: MailglassInbound.Config.schema()`
  to the single `delete_all(from(...))` in `delete_batched/3` (~`prune.ex:196`). Leave
  the two advisory-lock `query!` calls (`pg_try_advisory_lock` / `pg_advisory_unlock`,
  ~`prune.ex:143,148`) and `checkout/1` **unprefixed** — they are session-scoped,
  schema-agnostic SQL touching no mailglass table (exactly mirrors core's
  `Mailglass.Repo.query!/2` "SET LOCAL exemption" precedent).
  - **Why inline-qualify, not widen the facade:** widening the facade to expose
    `delete_all`/`query!` would still NOT eliminate the bypass (prune must hold the raw
    repo for `checkout/1` regardless), so it adds two permanent public functions to serve
    one internal caller yet leaves the bypass in place — worst of both worlds. Inline
    qualification is a one-line change at the single site that emits a mailglass-table
    DELETE, and keeps the facade faithful to its "re-exports only what mailglass itself
    uses / narrow facade" moduledoc. (Research-confirmed; Ecto prefix precedence makes an
    inline `prefix:` identical in effect to `put_prefix`.)
  - **Consequence if missed:** under any non-`public` schema the retention sweep
    silently DELETEs 0 rows (or errors) → inbound tables grow unbounded. No facade-only
    test catches it. Add a schema-isolation assertion that the prune DELETE targets
    `<schema>.mailglass_inbound_*`, and a one-line `prune.ex` moduledoc note recording
    that any future raw mailglass-table SQL must carry `prefix: Config.schema()` inline.

- **D-03:** **Defer `multi_opts/1` — do NOT add it in this phase.** This **refines the
  original assumption and adjusts INB-01's wording.** Inbound has **zero `Ecto.Multi`
  builders today** (verified — the only `Ecto.Multi` reference in inbound lib is the
  facade's own `multi/2` passthrough). Core exposes `multi_opts/1` solely to serve real
  Multi builders in Events/Outbound/Suppression. Adding it to inbound now is YAGNI on a
  permanent public surface that the "narrow facade" principle explicitly argues against.
  Add `multi_opts/1` in the same commit as the first inbound Multi builder that needs it.
  - **INB-01 wording adjustment:** the requirement says "`multi_opts/1` through its Multi
    builders" — there are none, so that clause is satisfied vacuously / deferred. Update
    the REQUIREMENTS.md / ROADMAP.md INB-01 wording during planning to reflect this
    (parallels the Phase 133 D-06 roadmap-wording adjustment).

- **D-04:** **NO `@schema_prefix` on any inbound schema module** (locked milestone
  decision 6). The Phase 134 `NoSchemaPrefixAttribute` Credo guard already enforces this
  repo-wide; this phase must not introduce one.

- **D-05:** **Only thread what inbound uses.** The inbound facade lacks
  `update/delete/aggregate/delete_all` (core has them). Per Phase 133's "only thread
  what's used" principle, do NOT add them — inbound never `update`s/`delete`s through the
  facade (the only DELETEs live in prune's direct path, handled by D-02).

### Area 2 — Migration packaging + version-dispatcher conversion (INB-02)

- **D-06:** Adopt **Option A — a parallel, self-contained inbound migration stack**
  mirroring core's shape and Oban's canonical precedent:
  - `MailglassInbound.Migration.up/down` — public entrypoint, injects
    `prefix: MailglassInbound.Config.schema()` via `Keyword.put_new` (explicit caller
    `:prefix` wins), dispatches to the runner.
  - `MailglassInbound.Migrations.Postgres` — the runner, with its own
    `maybe_create_schema/1` + `maybe_drop_schema/1` (do **not** reuse core's — separate
    package, separate version anchor).
  - `MailglassInbound.Migrations.Postgres.V01` — a single fresh-install snapshot
    (see D-07).
  - `mix mailglass.inbound.gen.migration` — a parallel generator emitting the stable
    8-line delegating wrapper (`def up, do: MailglassInbound.Migration.up()` /
    `def down, do: MailglassInbound.Migration.down()`). The `mailglass.inbound.*`
    namespace already exists (`doctor`/`prune`/`replay`), so a 4th verb is least-surprising.
    Do **not** reuse/extend core's `mailglass.gen.migration` (that recouples the packages
    the milestone is deliberately decoupling).
  - **Precedent:** Oban ships NO loose files; adopters run a generated wrapper delegating
    to `Oban.Migration.up/down` → `Oban.Migrations.Postgres.VNN`, version tracked via a
    `pg_class` comment on its own anchor table `oban_jobs`. Structurally identical.
  - **Delete the 7 loose `.exs` files** from `mailglass_inbound/priv/repo/migrations/`
    as part of this conversion.

- **D-07:** **Version anchor = a `pg_class` comment on `mailglass_inbound_records`**
  (`COMMENT ON TABLE <prefix>.mailglass_inbound_records IS '<version>'`), queried via the
  same `pg_class`/`pg_namespace` join core uses. Because the anchor table differs from
  core's `mailglass_events`, the two version lines are fully independent even when both
  packages install into the same schema — no collision, no coordination.

- **D-08:** **V01 = final-state snapshot, greenfield-only** (LOCKED with user 2026-07-03).
  Collapse the 7 historical files into one clean V01 declaring each column at its **final**
  nullability/default and creating **all** indexes as they exist after migration 7:
  - `mailglass_inbound_replay_runs`: declare `source :text NOT NULL DEFAULT "replay"` and
    `replay_id`/`mailbox` nullable from the start. **Drop migration 3's
    `UPDATE … SET source='replay'` backfill + `DROP NOT NULL` `execute()` entirely** —
    forward-only reconciliation of existing rows, meaningless against an empty table.
  - `mailglass_inbound_evidence`: declare `raw_mime_fingerprint` as the
    `generated: "ALWAYS AS (…) STORED"` column inline in `create table`; create all three
    provider partial unique fingerprint indexes (sendgrid/mailgun/ses) + the postmark
    idempotency index.
  - `mailglass_inbound_records`: `suppression_flagged :boolean NOT NULL DEFAULT false`.
  - Thread `prefix:` on every `create table`/`create index`/`create unique_index` exactly
    as core's `v01.ex` does. Do **NOT** put `prefix:` on `references` (see D-09).
  - **Existing adopters upgrade via the Phase 136 `ALTER TABLE … SET SCHEMA` move-codemod,
    NOT by re-running V01.** Documented 2.0 breaking cut. No idempotent guard in V01.

- **D-09:** **`references` inherits the block prefix — do NOT set `prefix:` on any
  `references` call.** VERIFIED against Ecto source
  (`deps/ecto_sql/lib/ecto/adapters/postgres/connection.ex:1872`:
  `quote_name(Keyword.get(ref.options, :prefix, table.prefix), ref.table)`) — a
  `references(...)` with no `:prefix` inherits the enclosing `create table` block prefix.
  Inbound's 3 intra-package FKs (`evidence.inbound_record_id`,
  `replay_runs.inbound_record_id`, `replay_runs.inbound_evidence_id`) land in `<schema>`
  automatically. Setting `prefix:` explicitly is redundant and, if hardcoded wrong, is the
  silent-FK-dangle footgun. (Core's `v01.ex` does NOT prove this — core has no FKs; the
  Ecto source is the proof.)

- **D-10:** **Inbound has NO raw-DDL to hand-qualify.** Unlike core (plpgsql immutability
  trigger + function + citext + CHECK constraints), inbound is pure tables + indexes + FKs
  + one generated column. Its V01 needs **zero** `#{prefix}.`-interpolated raw DDL beyond
  the `CREATE SCHEMA` head — every statement is Ecto-native `create table`/`index` that
  Ecto prefixes automatically. The generated column expression (`md5(raw_mime)`) references
  only same-row columns → no qualification. Partial-index `where:` clauses reference
  unqualified column names in the table's own scope → safe.

### Area 3 — CREATE/DROP SCHEMA mechanics + dual-schema harness (INB-02, INB-03)

- **D-11:** **CREATE SCHEMA** = `CREATE SCHEMA IF NOT EXISTS <inspect(validated_prefix)>`
  as the first action of the runner's `up/1`, guarded by a `create_schema` opt whose
  **default is `prefix != "public"`** (so it is skipped for `public`, and skippable via
  `create_schema: false` for adopters who pre-create the schema with custom grants).
  **DROP SCHEMA** = `DROP SCHEMA IF EXISTS … RESTRICT` (never CASCADE — a non-empty schema
  must fail loud), fired only on full down-migration to version 0, after tables are
  dropped, and only when inbound created it. Mirror core's `maybe_create_schema/1` /
  `maybe_drop_schema/1` (`lib/mailglass/migrations/postgres.ex`). Use `inspect/1` on a
  **validated** identifier (via the shared `Mailglass.Identifier.validate!/2`) as the
  single unquoted-identifier interpolation chokepoint.

- **D-12:** **Dual-schema test harness.** In `mailglass_inbound/test/test_helper.exs`,
  replace the raw `Ecto.Migrator.run(repo, path, :up, all: true)` with
  `MailglassInbound.Migration.up(prefix: schema)` inside the existing `with_repo`
  pool-override block (keep the Sandbox→ConnectionPool dance — still needed so the
  migrator's checkout doesn't hang). Because `Migration.up/1` runs `CREATE SCHEMA` as its
  first statement **inside `with_repo`, before `Sandbox.mode(:manual)` and any test
  checkout**, the schema-must-exist-before-Sandbox-owner footgun is resolved for free.
  Read the target schema from `System.get_env("MAILGLASS_SCHEMA")` defaulting to
  `"public"` (mirrors core `config/runtime.exs:42`).

- **D-13:** **CI axis.** Add a `mailglass_inbound` job to `.github/workflows/advisory-matrix.yml`
  with the identical `schema: [public, mailglass]` matrix axis core's "Core Full Suite
  Advisory" uses, exporting `MAILGLASS_SCHEMA: ${{ matrix.schema }}`. **Advisory (non-blocking)**
  lane, push + cron + `workflow_dispatch` — matching core's posture (never a PR blocker per
  the fake-adapter-is-the-gate DNA). Pin `mix test --seed 0` to dodge the known phase-45
  1000-iter property-test pool flake (`tcp recv: closed`) so the dual-schema gate is
  deterministic.

### Claude's Discretion
- Exact private helper name (`put_prefix/1`) and sentinel/module naming — keep consistent
  with core's inbound-side naming.
- Whether V01's generated column is emitted via `add …, generated:` on `create table` vs a
  trailing `alter table` (planner's choice; inline is cleaner for a fresh snapshot).
- Exact new module file paths under `mailglass_inbound/lib/` — follow core's directory shape.
- Whether the `test_helper.exs` schema is read once at module load vs per-suite-setup —
  planner's choice; the schema must exist before the SQL Sandbox owner starts (footgun 13).

### Folded Todos
None. (The one weak todo match — cowlib advisory allowlist removal — is unrelated tooling;
see Deferred.)
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/research/milestone-schema-isolation/SCHEMA-ISOLATION-DESIGN.md` — §3.7
  (inbound package handling) + §Phase D (build order). The binding design contract.
- `.planning/phases/132-config-mailglass-identifier-foundation/132-CONTEXT.md` — D-12..D-15
  (the already-built inbound `:schema` config accessor this phase consumes).
- `.planning/phases/133-repo-facade-prefix-injection-multi-threading/133-CONTEXT.md` — the
  core facade `put_prefix`/`multi_opts` pattern to mirror (D-01..D-08).
- `.planning/phases/134-migration-entrypoint-raw-ddl-trigger-qualification/134-01-PLAN.md`
  + `134-VERIFICATION.md` — the core migration entrypoint + `maybe_create_schema`/
  `maybe_drop_schema` pattern to mirror.
- `.planning/REQUIREMENTS.md` — INB-01, INB-02, INB-03 (note D-03 adjusts INB-01 wording).

**Core reference implementations to mirror (read before implementing):**
- `lib/mailglass/repo.ex` — facade `put_prefix/1` + `multi_opts/1` + `query!` exemption.
- `lib/mailglass/migration.ex` — `up/down` prefix injection + `migrator/0` dispatch.
- `lib/mailglass/migrations/postgres.ex` — `maybe_create_schema/1` / `maybe_drop_schema/1`,
  version dispatch, `create_schema: false` escape hatch, RESTRICT drop.
- `lib/mailglass/migrations/postgres/v01.ex` — the snapshot-per-version threading shape.
- `lib/mix/tasks/mailglass.gen.migration.ex` — wrapper generator (⚠ has a stale
  `create table(:mailglass_events)` stub bug — do NOT copy it forward; see Deferred).
- `deps/oban/lib/oban/migrations/postgres.ex` — canonical Elixir-ecosystem precedent.
- `deps/ecto_sql/lib/ecto/adapters/postgres/connection.ex:1872` — proof that `references`
  inherits the block prefix.
- `.github/workflows/advisory-matrix.yml` — the dual-schema CI axis template (core lane).
- `config/runtime.exs:42` — `MAILGLASS_SCHEMA` env override template.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `MailglassInbound.Config.schema/0` — **already built** (Phase 132), persistent_term-cached,
  default `"mailglass"`, validated via shared `Mailglass.Identifier.validate!/2`, boot-warmed
  by `validate_at_boot!/0` wired into inbound's `application.ex` `start/2`.
- `Mailglass.Identifier.validate!/2` — shared unquoted-identifier validator (regex +
  63-byte NAMEDATALEN guard); inbound already hard-depends on core, so reuse it as the
  `CREATE SCHEMA` interpolation chokepoint.
- Core's entire Phase 133/134 implementation is the line-by-line template — inbound is a
  strictly simpler subset (no triggers/functions/citext/CHECK/cross-package FK).

### Established Patterns
- Thin-facade-over-host-repo (`MailglassInbound.Repo` currently: transact/insert/one/multi/all/get).
- Version-dispatcher migrations tracked by a `pg_class` comment anchor (core + Oban).
- `Keyword.put_new` prefix injection so explicit caller `:prefix` wins.
- Advisory-lock / `SET LOCAL` raw SQL stays schema-agnostic (unprefixed).
- Advisory (non-blocking) CI lanes for full-suite + dual-schema axes.

### Integration Points
- `mailglass_inbound/lib/mailglass_inbound/repo.ex` — facade to thread `put_prefix`.
- `mailglass_inbound/lib/mailglass_inbound/internal/prune.ex` — the raw-repo bypass to
  qualify (the one non-facade DELETE path — load-bearing, D-02).
- `mailglass_inbound/priv/repo/migrations/*.exs` — 7 loose files to collapse + delete.
- `mailglass_inbound/test/test_helper.exs` — migration path to rewire to `Migration.up/1`.
- `.github/workflows/advisory-matrix.yml` — add inbound dual-schema job.
- Cross-package read of core suppression via `Mailglass.SuppressionStore.Ecto` →
  `Mailglass.Repo` (already core-prefixed; no inbound change needed).
</code_context>

<specifics>
## Specific Ideas

- **Research-refined two analyzer assumptions:** (1) `multi_opts/1` → **defer** (not add),
  because inbound has zero Multi builders and the narrow-facade principle argues against a
  speculative public surface; (2) the facade-bypass → **inline-qualify prune**, not widen
  the facade (widening can't eliminate the `checkout/1` bypass anyway).
- **Oban is the canonical precedent** for the whole migration-packaging decision (no loose
  files; delegating wrapper; own `pg_class` anchor table). Follow it.
- **Ecto FK-prefix inheritance is proven from source** (connection.ex:1872), not assumed —
  no `prefix:` on `references`.
</specifics>

<deferred>
## Deferred Ideas

- **Core `mix mailglass.gen.migration` stale-stub bug** — it emits a `create table(:mailglass_events)`
  body (`lib/mix/tasks/mailglass.gen.migration.ex:55-70`) that contradicts its own moduledoc
  (should emit the 8-line delegating wrapper). Out of scope for Phase 135 (core file); file as
  a **core follow-up / backlog item** and do NOT copy the bug into the new inbound generator.
- **`multi_opts/1` on inbound** — add it in the same commit as the first inbound `Ecto.Multi`
  builder that needs it (D-03), not before.

### Reviewed Todos (not folded)
- `2026-06-30-remove-cowlib-advisory-allowlist-when-upstream-fixes.md` — weak keyword match
  (tooling / cowlib advisory allowlist); unrelated to inbound schema isolation. Not folded.
</deferred>
