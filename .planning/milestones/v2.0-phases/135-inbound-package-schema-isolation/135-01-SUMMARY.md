---
phase: 135-inbound-package-schema-isolation
plan: "01"
subsystem: mailglass_inbound
tags: [schema-isolation, inbound, repo-facade, prune, prefix-injection]
dependency_graph:
  requires: [132-02, 133-01]
  provides: [INB-01]
  affects: [mailglass_inbound/lib/mailglass_inbound/repo.ex, mailglass_inbound/lib/mailglass_inbound/internal/prune.ex]
tech_stack:
  added: []
  patterns:
    - "Keyword.put_new/3 for schema prefix injection (explicit caller :prefix wins)"
    - "Inline prefix: on facade-bypassing DELETE in prune (checkout/1 bypass)"
key_files:
  created:
    - mailglass_inbound/test/mailglass_inbound/repo_prefix_test.exs
  modified:
    - mailglass_inbound/lib/mailglass_inbound/repo.ex
    - mailglass_inbound/lib/mailglass_inbound/internal/prune.ex
    - mailglass_inbound/config/test.exs
decisions:
  - "D-03 deferred: multi_opts/1 not added to inbound facade (zero Multi builders today)"
  - "D-02 inline prefix on delete_batched/3: facade cannot rewrite prune's raw-repo path (checkout/1 bypass)"
  - "D-04: no @schema_prefix on any inbound schema module"
  - "Rule 2: test config pinned to schema:'public' to match core Phase 133 pattern"
metrics:
  duration: "~15 minutes"
  completed: "2026-07-03"
  tasks: 3
  files: 4
status: complete
---

# Phase 135 Plan 01: Inbound Facade Prefix Injection Summary

Thread the already-built `MailglassInbound.Config.schema/0` accessor through the `MailglassInbound.Repo` facade (`put_prefix/1` via `Keyword.put_new`) and inline-qualify the single facade-bypassing DELETE in `internal/prune.ex`, with a deterministic schema-isolation test that fails RED if either fix is reverted.

## What Was Built

### Task 1: `put_prefix/1` threaded through inbound facade reads/writes

Added a private `put_prefix/1` helper to `MailglassInbound.Repo` mirroring core's `Mailglass.Repo.put_prefix/1`:

```elixir
defp put_prefix(opts), do: Keyword.put_new(opts, :prefix, MailglassInbound.Config.schema())
```

Threaded through the four delegated read/write functions inbound exposes:
- `insert/2`, `one/2`, `all/2`, `get/3` — each passes opts through `put_prefix/1`
- `transact/2` and `multi/2` — intentionally NOT prefixed (D-03 defers `multi_opts/1`; no Multi builders in inbound today)

Added a `## Schema prefix injection (v2.0)` moduledoc note documenting the `Keyword.put_new` precedence and which functions are exempt. No `@schema_prefix` introduced (D-04).

### Task 2: Inline schema qualification on prune batched DELETE (D-02 load-bearing fix)

In `MailglassInbound.Internal.Prune.delete_batched/3`, the single `repo.delete_all(...)` call now carries `prefix: MailglassInbound.Config.schema()`:

```elixir
repo.delete_all(from(r in schema, where: r.id in subquery(inner)),
  prefix: MailglassInbound.Config.schema()
)
```

The two advisory-lock `query!` calls (`pg_try_advisory_lock`/`pg_advisory_unlock`) and `repo.checkout/1` remain UNprefixed — they are session-scoped, schema-agnostic SQL touching no mailglass table (mirrors core's `query!/2` SET LOCAL exemption).

Added a `## Schema qualification` moduledoc note recording that any future raw mailglass-table SQL added to this module's direct-repo path MUST carry `prefix: MailglassInbound.Config.schema()` inline.

### Task 3: Schema-isolation test (repo_prefix_test.exs)

Created 8 deterministic tests in `test/mailglass_inbound/repo_prefix_test.exs`:

**(A) Facade prefix injection** (via inline `CaptureRepo` fake — no real DB needed):
- `insert/2`, `one/2`, `all/2`, `get/3` with no opts inject `prefix: Config.schema()`
- Explicit caller `prefix: "override"` wins (`Keyword.put_new` precedence)
- `transact/2` and `multi/2` do NOT inject a prefix

**(B) Prune DELETE schema target** (real non-sandboxed connection):
- Override `Config.schema()` to `"mg_iso_test"` (nonexistent schema)
- Insert aged row directly into `"public"` via TestRepo (bypassing facade)
- Run prune — DELETE targets `"mg_iso_test"`, NOT `"public"`
- Assert the `"public"` row SURVIVES (confirmed by debug output: `DELETE FROM "mg_iso_test"."mailglass_inbound_replay_runs"`)
- **RED condition**: remove `prefix:` from `delete_batched/3` → DELETE falls back to `"public"` → aged row deleted → final `TestRepo.get` returns nil → test fails

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical config] Pin :schema to "public" in inbound test env**
- **Found during:** Task 1 verification — ran existing records_test.exs to check for regressions
- **Issue:** `Config.schema()` defaults to `"mailglass"` at boot (application starts in tests), but migrations ran in `"public"`. After adding `put_prefix/1`, all 26 out of 31 DB-backed tests failed with `ERROR 42P01 relation "mailglass.mailglass_inbound_*" does not exist`
- **Fix:** Added `config :mailglass_inbound, :schema, "public"` to `config/test.exs`, exactly mirroring core's `config/test.exs` from Phase 133 (`config :mailglass, :schema, "public"`)
- **Files modified:** `mailglass_inbound/config/test.exs`
- **Commit:** `c35dd10d`

## Verification Results

```
cd mailglass_inbound && mix compile --warnings-as-errors  → PASS (0 warnings)
cd mailglass_inbound && mix format --check-formatted lib/ → PASS
cd mailglass_inbound && mix test test/mailglass_inbound/repo_prefix_test.exs --seed 0 → 8 tests, 0 failures
grep -rn "@schema_prefix" mailglass_inbound/lib/        → no matches (D-04 ✓)
```

## Commits

| Hash | Message |
|------|---------|
| `fac03d23` | feat(135-01): thread put_prefix/1 through MailglassInbound.Repo facade |
| `a91c267c` | fix(135-01): inline-qualify prune batched DELETE with schema prefix (D-02) |
| `c35dd10d` | fix(135-01): pin schema to public in inbound test env (Rule 2 - missing critical config) |
| `de5c1eef` | test(135-01): schema-isolation assertions for facade + prune DELETE target |

## Known Stubs

None — all functionality is fully wired. `put_prefix/1` reads from `MailglassInbound.Config.schema/0` (Phase 132, persistent_term-cached, boot-validated).

## Threat Surface Scan

No new network endpoints, auth paths, or file access patterns introduced. The `prefix:` value flows from `Config.schema()` (operator app-env config, validated by `Mailglass.Identifier.validate!/2` at boot). Ecto quotes the prefix as a Postgres identifier — no raw string interpolation. T-135-01 and T-135-02 from the plan's threat model are both mitigated by this plan.

## Self-Check: PASSED

| Item | Status |
|------|--------|
| `mailglass_inbound/lib/mailglass_inbound/repo.ex` | FOUND |
| `mailglass_inbound/lib/mailglass_inbound/internal/prune.ex` | FOUND |
| `mailglass_inbound/test/mailglass_inbound/repo_prefix_test.exs` | FOUND |
| `.planning/phases/135-inbound-package-schema-isolation/135-01-SUMMARY.md` | FOUND |
| Commit `fac03d23` | FOUND |
| Commit `a91c267c` | FOUND |
| Commit `c35dd10d` | FOUND |
| Commit `de5c1eef` | FOUND |
