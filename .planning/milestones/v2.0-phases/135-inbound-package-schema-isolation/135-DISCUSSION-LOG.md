# Phase 135: Inbound package schema isolation - Discussion Log (Assumptions Mode + Research)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-07-03
**Phase:** 135-inbound-package-schema-isolation
**Mode:** assumptions (with research-driven refinement per project Decision Policy)
**Areas analyzed:** Facade threading + prune bypass; Migration packaging + conversion;
CREATE/DROP SCHEMA mechanics + dual-schema harness

## Assumptions Presented (from gsd-assumptions-analyzer)

### Migration Conversion Strategy
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Collapse 7 loose `change/0` files into a single fresh-install `V01` snapshot dispatched by a new `MailglassInbound.Migrations.Postgres` runner; do NOT reproduce V01..V07 | Likely | design doc §3.7 (`SCHEMA-ISOLATION-DESIGN.md:378-387`); core VNN is snapshot-per-version |

### Facade Threading + Bypass
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Thread private `put_prefix/1` through `Repo.{insert,one,all,get}`; add public `multi_opts/1`; qualify the `prune.ex` raw-repo bypass (`delete_all` gets `prefix:`, advisory-lock `query!` stays unprefixed); no `@schema_prefix` | Confident | `repo.ex:17,22,31,34`; `internal/prune.ex:69,142-148,196`; core `lib/mailglass/repo.ex:187-208` |

### CREATE SCHEMA / references / no trigger
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Own `maybe_create_schema`/`maybe_drop_schema`; own version anchor on `mailglass_inbound_records`; `prefix:` on `create table` auto-covers `references`; zero triggers/functions/citext to hand-qualify; ship own 8-line wrapper + gen task | Confident | core `migrations/postgres.ex:103-118`, `postgres/v01.ex`; inbound migrations have no trigger/function/citext |

## User Decision Gate (2026-07-03)

- **Q1 — V01 upgrade path:** User selected **"Yes — greenfield V01, 136 moves"**: V01 is a
  fresh from-scratch snapshot; existing adopters migrate via Phase 136's `ALTER TABLE … SET
  SCHEMA` move-codemod, not by re-running V01. Documented 2.0 breaking cut. → Locked as D-08.
- **Q2 — confirm Areas 1 & 2:** User declined a simple "proceed" and instead directed a
  research-first pass (per CLAUDE.md Decision Policy): spawn per-area research subagents on
  pros/cons/tradeoffs, Elixir/Ecto/Phoenix idioms, lessons from comparable libs, adopter DX,
  and the `prompts/` research, then one-shot a coherent recommendation set.

## Research Performed (3 parallel gsd-advisor-researchers)

### Area 1 — Facade surface + prune bypass
- **Recommendation:** inline-qualify the `delete_all` in `prune.ex`; leave advisory-lock
  `query!` + `checkout/1` unprefixed. Do **NOT** widen the facade — it can't eliminate the
  bypass (prune structurally needs raw `checkout/1`), so widening adds 2 permanent public
  fns for one caller yet leaves the bypass in place.
- **Refinement:** **DEFER `multi_opts/1`** — inbound has zero `Ecto.Multi` builders; adding
  it now is YAGNI on a public surface the narrow-facade principle argues against. (Overrides
  the analyzer's "add multi_opts/1" assumption.)
- Source: [Ecto multi-tenancy-with-query-prefixes](https://hexdocs.pm/ecto/multi-tenancy-with-query-prefixes.html)

### Area 2 — Migration packaging + conversion
- **Recommendation:** Option A — parallel `mix mailglass.inbound.gen.migration` + own
  `MailglassInbound.Migration` runner + `V01` snapshot + version anchor on
  `mailglass_inbound_records`.
- **Precedent:** Oban ships NO loose files; delegating wrapper → `Oban.Migration.up/down` →
  `Oban.Migrations.Postgres.VNN`; version tracked via `pg_class` comment on `oban_jobs`.
  Structurally identical to core.
- **Snapshot fidelity:** collapse to final column state; drop migration 3's `UPDATE`
  backfill + `DROP NOT NULL` (moot on empty tables).
- **Footgun flagged:** core's `mailglass.gen.migration` emits a stale `create table(:mailglass_events)`
  stub (`lines 55-70`) contradicting its moduledoc — do NOT copy it forward; file as a core
  follow-up. → captured in Deferred.

### Area 3 — CREATE SCHEMA / prefix DDL mechanics + harness
- **VERIFIED (source-level):** `references` inherits the `create table` block prefix —
  `deps/ecto_sql/lib/ecto/adapters/postgres/connection.ex:1872`
  (`quote_name(Keyword.get(ref.options, :prefix, table.prefix), ref.table)`). No `prefix:`
  on `references`.
- CREATE SCHEMA skipped for `public`; `create_schema: false` escape hatch; DROP RESTRICT
  (never CASCADE) on teardown to v0 only.
- Generated column + partial unique indexes need no special prefix handling beyond the
  block prefix.
- Harness: switch `test_helper.exs` to `MailglassInbound.Migration.up(prefix:)` inside the
  existing `with_repo` block so CREATE SCHEMA runs before the Sandbox owner; read
  `MAILGLASS_SCHEMA` env (default `public`); add inbound `schema:[public,mailglass]` axis to
  `advisory-matrix.yml`; pin `--seed 0` for the known phase-45 property-test pool flake.

## Corrections Made

Two analyzer assumptions were refined by research (not user-corrected):
1. **`multi_opts/1`:** analyzer said "add it"; research → **defer** (no Multi builders). D-03.
2. **Facade bypass:** analyzer offered widen-vs-inline as open; research → **inline-qualify
   prune, decisively do NOT widen** (checkout bypass is structural). D-02.

## External Research
- Ecto multi-tenancy query prefixes (facade prefix precedence).
- Oban migration distribution pattern (canonical Elixir-ecosystem precedent).
- Ecto Postgres adapter FK-prefix inheritance (source-level verification).
