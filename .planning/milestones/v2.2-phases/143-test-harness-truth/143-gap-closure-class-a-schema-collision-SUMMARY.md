---
phase: 143
plan: gap-closure-class-a-schema-collision
subsystem: test-harness
tags: [harness-01, d-31, class-a, schema-isolation, sandbox, flake]
status: complete
requires:
  - "Mailglass.TestSupport.SandboxOwnership — checkout!/1, unsandboxed_module/1, with_schema!/2, probe/1, baseline_tables_present?/1 (plans 143-01/04/07)"
  - "Mailglass.TestSupport.SuiteTruthFormatter + SuiteFloor (plans 143-01/09)"
provides:
  - "SandboxOwnership.scratch_schema!/2 + ScratchSchemaError — a throwaway-schema declaration seam that refuses the live schema and `public`, attributed to the declaring module"
  - "SandboxOwnership.assert_baseline_intact!/3 + BaselineError — one raising, caller-named baseline verification replacing four hand-rolled copies"
  - "@baseline_relations widened to all four relations the shipped install migration creates"
affects:
  - "test/support/sandbox_ownership.ex, test/test_helper.exs, and six test modules"
key-files:
  created: []
  modified:
    - test/support/sandbox_ownership.ex
    - test/test_helper.exs
    - test/mailglass/schema_prefix_hardening_test.exs
    - test/mailglass/schema_isolation_immutability_test.exs
    - test/mailglass/schema_isolation_integration_test.exs
    - test/mailglass/upgrade_v2_schema_migration_test.exs
    - test/mailglass/migration_test.exs
    - test/mailglass/shipped_migration_divergence_test.exs
    - test/mailglass/operator/support_summary_test.exs
    - test/mailglass/test_support/sandbox_ownership_test.exs
metrics:
  axes-verified: 2
  seeds-per-axis: 3
  mutation-checks: 6
---

# Phase 143 Gap Closure: Class A schema collision, baseline instrument gap, and the Map.keys order flake

Closed the orchestrator-directed gap on the `MAILGLASS_SCHEMA=mailglass` axis. Both axes are now
clean at the CI seeds plus two further seeds each, with `--warnings-as-errors`.

**Headline correction, stated up front:** the directed root cause — five modules CASCADE-dropping
the live baseline schema — is **real, was fixed, and is now structurally impossible**, but it was
**not** the cause of the observed `42P01` cascade. The actual cause was a different defect in the
same file: an unscoped, session-level `SET search_path TO public` that poisoned a pooled Postgres
connection for the rest of the run. Section 3 gives the evidence for both claims.

---

## 1. CI evidence and the local repro

Advisory Matrix run `30516126767` on `gsd/phase-143-test-harness-truth` failed both Core Full Suite
legs. Reproduced locally, deterministically, from a reset DB:

```
MIX_ENV=test mix ecto.drop -r Mailglass.TestRepo --quiet && MIX_ENV=test mix ecto.create -r Mailglass.TestRepo --quiet
MAILGLASS_SCHEMA=mailglass mix test --seed 374117 --exclude requires_workspace
```

→ `23 properties, 1513 tests, 7 failures`, `signature tally: already_shared=1, formatter_violations=0`.

All seven were `(Postgrex.Error) ERROR 42P01 (undefined_table)` on **unqualified** relation names —
`mailglass_events`, `mailglass_suppressions`, `mailglass_webhook_events`, `mailglass_deliveries` —
in unrelated victim modules (`IngestTest`, `TenantsTest`, `DeliveryIdempotencyKeyTest`,
`ReconcilerTest`, `IngestAutoSuppressTest`, and others). `already_shared=0` on the pool axis
confirms this is D-31 **Class A**, not the pool-mode class.

Separately on the public axis at seed `783091`:
`test/mailglass/operator/support_summary_test.exs:11` — `Map.keys(summary)` returned
`[:orphan_backlog, :failed_ingest, …]` against a hardcoded `[:failed_ingest, :orphan_backlog, …]`.

---

## 2. What I verified before fixing

Read confirmed the directed finding: five `async: false` modules hardcoded a *scratch* prefix
`@prefix "mailglass"` and ran `DROP SCHEMA IF EXISTS mailglass CASCADE` in `setup` and again in
`on_exit`. On the `public` axis that scratch schema is disjoint from the baseline; under
`MAILGLASS_SCHEMA=mailglass` it **is** the live baseline schema.

- `test/mailglass/schema_prefix_hardening_test.exs` (module attr + nested migration)
- `test/mailglass/schema_isolation_immutability_test.exs` (module attr + nested migration)
- `test/mailglass/schema_isolation_integration_test.exs` (module attr + nested migration)
- `test/mailglass/upgrade_v2_schema_migration_test.exs` (module attr; emitted body's own `@schema`)
- `test/mailglass/migration_test.exs` (describe-block attr + two nested migrations)

`test/mailglass/shipped_migration_divergence_test.exs`'s `@prefix "mailglass_shipped_path_test"` is
the model, and is the naming precedent every rename follows.

---

## 3. Root cause — corrected, with evidence

### 3a. The DROP SCHEMA collision was real but is NOT what failed the suite

Two independent pieces of evidence refute it as the cause:

1. **The baseline was intact at the end of the failing run.** Immediately after the 7-failure repro
   I queried the database directly:
   `mailglass.{mailglass_deliveries, mailglass_events, mailglass_suppressions, mailglass_webhook_events}`
   were all present. Nothing was missing that a restore had failed to bring back.
2. **There is no cross-module window for it to fail in.** `ExUnit.Runner` runs every `async: true`
   module strictly before every `async: false` module, and runs `async: false` modules one at a
   time. Each dropping module's `on_exit` restore therefore completes before the next module starts.
   A drop-then-restore inside one module's own lifecycle cannot be observed by another module.

Confirmed constructively as well: after renaming all five scratch prefixes and **deleting** the
baseline-restoration code from four of them, the same seed still produced the same 42P01 failures
(8, at that point) — so removing the drops entirely did not remove the failures.

### 3b. The actual cause — session-level `search_path` poisoning

`test/mailglass/schema_prefix_hardening_test.exs` had:

```elixir
defp force_public_search_path! do
  _ = TestRepo.query!("SET search_path TO public", [])
  :ok
end
```

Three facts combine into the cascade:

1. `SET` without `LOCAL` is a **session-level** write — it persists on the physical Postgres
   connection for that connection's entire lifetime.
2. That module runs in Sandbox `:auto` mode, where every `TestRepo.query` checks a connection out of
   the 10-slot pool and returns it. The poisoned connection goes straight back into the pool. The
   `RESET search_path` the module issued from `on_exit` was a **separate checkout** that could — and
   under concurrency did — land on a different connection than the one that had been poisoned.
3. `config/test.exs` + `test_helper.exs` give pool connections a startup `search_path` of
   `"<schema>, public"`, and the rest of the suite relies on it to resolve unqualified relation
   names. A connection stuck at `search_path = public` raises
   `42P01 … relation "mailglass_deliveries" does not exist` for whatever unrelated test later drew
   it from the pool.

Confirmed live with a throwaway probe (`mix run` against a started `Mailglass.TestRepo`):

```
baseline search_path: "\"$user\", public"
distinct values across 40 checkouts after ONE `SET search_path TO public`: %{"public" => 40}
same-connection: before="public" poisoned="public" after_RESET="\"$user\", public"
```

One session-level `SET` poisoned the hot pooled connection for all 40 subsequent checkouts.
(`RESET` does correctly restore the startup-packet value — but only on the connection it lands on.)

This also explains why `assert_baseline_intact!/3` never fired: it queries
`information_schema.tables` with an explicit `table_schema = $1` parameter, so it is immune to
`search_path` and correctly reported the baseline present. It did not report a false success; the
defect was simply not a missing baseline.

### 3c. Two further latent bugs the scratch rename exposed

Both were pre-existing and order-dependent, invisible only because every prefixed-schema test
happened to use the literal `"mailglass"`:

- **citext landed in the wrong schema.** `v01` issues a deliberately unqualified
  `CREATE EXTENSION IF NOT EXISTS citext`, and `CREATE EXTENSION` with no `SCHEMA` clause installs
  into the *first* schema of `search_path`. On a fresh DB on the mailglass axis that is `mailglass`,
  not `public` — directly contradicting `test_helper.exs`'s own comment ("the citext extension type
  (installed in public) stays resolvable"). Once tests moved to their own scratch prefixes,
  `add(:address, :citext)` under `search_path = "<scratch>, public"` raised
  `42704 (undefined_object) type "citext" does not exist`.
- **`SET LOCAL search_path` inside wrapper migrations broke Ecto's own bookkeeping.** `SET LOCAL`
  persists for the remainder of the transaction, and `Ecto.Migrator` inserts its `schema_migrations`
  version row **inside that same transaction, after the migration body**. The pin therefore
  redirected Ecto's bookkeeping INSERT to a `search_path` holding no `schema_migrations` table.
  Under `MAILGLASS_SCHEMA=mailglass`, `test/mailglass/shipped_migration_divergence_test.exs` failed
  **4 tests / 4 failures when run alone** on that axis (all
  `42P01 … relation "schema_migrations" does not exist`) and passed in a full suite only because
  some earlier module happened to create `public.schema_migrations` first. The pins were documented
  crutches for v01's then-unqualified trigger DDL; Phase 134-02 schema-qualified that DDL
  (`v01.ex:138,154`), so they were already obsolete.

---

## 4. The fixes

### Fix 1 — the collision made structurally impossible, and loud

`Mailglass.TestSupport.SandboxOwnership.scratch_schema!/2` returns a scratch schema name unchanged,
and raises `ScratchSchemaError` when the name is either the live schema `Mailglass.Config.schema/0`
currently resolves to, or `"public"` (never scratch even on an axis where it is not live — it owns
the citext extension). The raise names **the declaring module** and **the live schema**, before a
single DDL statement runs, so the failure lands at the module that would corrupt the baseline rather
than as a 42P01 in an innocent module hundreds of tests later.

It raises rather than silently substituting a safe name: a rename-and-continue would make the guard
invisible, and the next person to hardcode `"mailglass"` would get a passing suite with no signal.

**Ordering is load-bearing and documented:** `scratch_schema!/2` must be called *before*
`with_schema!/2`, because `with_schema!/2` makes `Config.schema/0` return the scratch name, after
which the guard can no longer observe the schema the rest of the suite needs. Calling it after
raises — deliberate fail-closed behavior, not a false positive to work around.

All five modules now route their prefixes through it and use names disjoint from `"public"` and
`"mailglass"`, following the `mailglass_shipped_path_test` precedent:

| Module | Scratch prefix |
|---|---|
| `schema_prefix_hardening_test.exs` | `mailglass_prefix_hardening_test` |
| `schema_isolation_immutability_test.exs` | `mailglass_isolation_immutability_test` |
| `schema_isolation_integration_test.exs` | `mailglass_isolation_integration_test` |
| `upgrade_v2_schema_migration_test.exs` | `mailglass_upgrade_v2_move_test` |
| `migration_test.exs` (describe block) | `mailglass_migration_prefix_test` |

**Per-file care, as directed:**

- `upgrade_v2_schema_migration_test.exs` exercises an emitted migration whose `@schema` is baked into
  the generated bytes. `Mix.Tasks.Mailglass.Upgrade.V2Schema.migration_body/2` accepts a `:schema`
  option (default `"mailglass"`), so the scratch name is threaded through it rather than weakening
  the guard. Because the guard only sees the outer module's `@prefix`, `setup` adds a **non-vacuity
  assertion** that the emitted source really contains `@schema "<scratch>"` — a drift between the
  outer literal and the nested one, or a future change dropping the `schema:` pass-through, fails
  there instead of silently CASCADE-dropping the live baseline again.
- The same file **must** operate on `public`: the emitted migration's source side is hardcoded
  (`ALTER TABLE public.mailglass_events SET SCHEMA …`), and UPG-01/04 exists to prove a 1.x install
  sitting in `public` can be relocated. That is documented in a comment naming it as the one
  deliberate live-schema operation in the file, and it is why this module — uniquely among the five
  — keeps an unconditional `restore_suite_baseline_schema/0` **plus** a verification of it. The
  guard is not weakened for it; the module's own live-schema safety is made explicit and verified.
- `migration_test.exs`'s file-level restore is kept, because its `:public_only` `down/0` describe
  genuinely tears the configured schema down. Its `:schema_isolation` describe now only *verifies*.
- The other three modules no longer touch the baseline at all, so their restores were deleted
  (removing, among other things, a `DELETE FROM public.schema_migrations WHERE version < 100` that
  every test in those files used to run). Each registers `assert_baseline_intact!/3` as its **first**
  `on_exit` — so it runs **last**, after `with_schema!/2`'s restore, and therefore checks the boot
  schema rather than the module's own override.

### Fix 2 — the instrument gap closed

`@baseline_relations` omitted `mailglass_events` — the append-only ledger, and the first relation CI
named as missing — so `baseline_tables_present?/1` could not observe the very table that vanished,
and every call site reported a restore it had not verified.

The list is now **enumerated from the shipped install migration**, not guessed, with the derivation
recorded in a comment and a re-derivation command:

```
v01.ex:21  create table(:mailglass_deliveries)
v01.ex:77  create table(:mailglass_events)
v01.ex:163 create table(:mailglass_suppressions)
v02.ex:28  create table(:mailglass_webhook_events)
```

`v03`/`v04`/`v05` add columns, indexes and constraints only — no further tables. Moduledoc and `@doc`
text updated from "three" to all four, everywhere they enumerated the names.

Also added `assert_baseline_intact!/3` + `BaselineError`, collapsing four hand-rolled three-clause
`case` blocks (each with its own wording, one of them wrapped in an axis guard) onto a single raising
helper that names the caller and treats `:cannot_verify` as a failure. It is **read-only** — it
observes and reports, never restores. `probe/1` and `baseline_tables_present?/1` remain read-only and
otherwise unchanged.

### Fix 3 — the `Map.keys/1` order flake

**Decision: fix the test, not the production code.** `SupportSummary.summarize_tenant/1` returns a
plain map, and a map has no public order. `Map.keys/1` on a ≤32-key flatmap returns keys in ERTS'
internal map-key order, which for atoms follows the atom **table index** (creation order), not the
atoms' names — so it varies with which modules the run has loaded and in which sequence, i.e. with
the seed. Asserting on it asserts something the callee does not and cannot promise.

The assertion now tests the intended property — the exact key **set**, no extras, no missing — via
`Enum.sort(Map.keys(summary)) == Enum.sort([...])`. The comment records what would have to change if
the four-bucket *order* ever became part of the contract: the production code would have to return
something order-bearing (a keyword list, or an explicit `@bucket_order`) and the test would target
that.

### Fix 4 — the actual 42P01 cause: scoped, verified `search_path`

`force_public_search_path!/0` is replaced by `with_public_search_path!/1`, which runs the code under
test inside `TestRepo.checkout/1` — pinning **one** connection for the whole block — captures the
prior `search_path`, forces `public`, and restores the captured value in an `after` block **on that
same connection**, then **re-reads it to verify the restore landed**, raising a message that names
this module if it did not. The `RESET search_path` in `on_exit` is kept only as belt-and-braces, now
commented honestly as something that may land on a different pooled connection and therefore can
neither be relied on nor read as evidence.

### Fix 5 — citext pinned to `public`

`test_helper.exs` now issues `CREATE EXTENSION IF NOT EXISTS citext SCHEMA public` before running the
boot migrations, making the harness match its own documented invariant on both axes. The four
test-side `CREATE EXTENSION IF NOT EXISTS citext` recreations are likewise pinned `SCHEMA public`.
Idempotent: `IF NOT EXISTS` is a no-op when citext already exists, so this only decides the location
on a fresh database.

### Fix 6 — obsolete `SET LOCAL search_path` pins removed

Removed from all four wrapper migrations (`migration_test.exs` ×2,
`schema_isolation_integration_test.exs`, `shipped_migration_divergence_test.exs`), with the mechanism
recorded at each site. `schema_isolation_immutability_test.exs` already carries an in-module
self-check that refuses any pin in its own source, and it passes — which is the standing proof the
crutch is no longer needed.

---

## 5. Mutation checks (non-vacuity)

Each fix was shown to fail when its underlying defect is reintroduced, with everything else in place.

| # | Defect reintroduced | Result |
|---|---|---|
| M1 | `mailglass_events` deleted from `@baseline_relations` | **2 failures** in `sandbox_ownership_test.exs` — the dedicated "names mailglass_events when it is the ONLY absent relation" test and the four-relation missing-set test |
| M2 | `@prefix "mailglass"` re-typed into `schema_isolation_immutability_test.exs` | **7 failures**, every one a `ScratchSchemaError` naming `Mailglass.SchemaIsolationImmutabilityTest` and the live schema — including the cross-file non-vacuity test, which fires on **both** axes, i.e. even where the collision would have been silently harmless |
| M3 | ordered `Map.keys(summary) == [...]` restored | **1 failure**, public axis seed `783091`, `left: [:orphan_backlog, :failed_ingest, …]` — the reported flake reproduced verbatim |
| M4 | unscoped session-level `SET search_path TO public` restored | **6 failures**, mailglass axis seed `374117` — the CI victim set exactly: `DeliverManyTest`, `IngestTest`, `TenantsTest`, `PlugSESTest`, `ProjectorBroadcastTest`, `WebhookCaseTest`, all `42P01` |
| M5 | (observed pre-fix) `SET LOCAL search_path` pin present | `MAILGLASS_SCHEMA=mailglass mix test test/mailglass/shipped_migration_divergence_test.exs` → **4 tests, 4 failures**, all `42P01 … relation "schema_migrations" does not exist` |
| M6 | (observed pre-fix) citext not pinned to `public` | `42704 (undefined_object) type "citext" does not exist` in `migration_test.exs` once scratch prefixes were introduced |

M4 is the decisive one: with the scratch renames, the widened baseline list and every other fix still
applied, reverting **only** the `search_path` scoping reproduces the CI failure set.

The tree was restored from byte-identical backups after each mutation and re-verified (§6).

---

## 6. Acceptance

Every run from a freshly reset DB
(`MIX_ENV=test mix ecto.drop -r Mailglass.TestRepo --quiet && MIX_ENV=test mix ecto.create -r Mailglass.TestRepo --quiet`),
with `--warnings-as-errors`, read from raw `mix test` output — never from the SuiteFloor ledger or
the formatter.

| Axis | Seed | Result | Exit |
|---|---|---|---|
| `MAILGLASS_SCHEMA=mailglass` | 374117 (CI) | 23 properties, 1521 tests, **0 failures**, 7 skipped (14 excluded) | 0 |
| `MAILGLASS_SCHEMA=mailglass` | 20260730 | 23 properties, 1521 tests, **0 failures**, 7 skipped (14 excluded) | 0 |
| `MAILGLASS_SCHEMA=mailglass` | 601979 | 23 properties, 1521 tests, **0 failures**, 7 skipped (14 excluded) | 0 |
| public (default) | 783091 (CI) | 23 properties, 1522 tests, **0 failures**, 7 skipped (13 excluded) | 0 |
| public (default) | 20260730 | 23 properties, 1522 tests, **0 failures**, 7 skipped (13 excluded) | 0 |
| public (default) | 601979 | 23 properties, 1522 tests, **0 failures**, 7 skipped (13 excluded) | 0 |

Both CI seeds re-run once more **after** all mutations were reverted: mailglass/374117 exit 0,
public/783091 exit 0, `signature tally: already_shared=0, formatter_violations=0` on both.

`mix format --check-formatted` → clean. `mix credo --strict` → `3896 mods/funs, found no issues.`

Test-count delta: mailglass axis 1513 → 1521, public axis → 1522 (8 new regression tests in
`sandbox_ownership_test.exs`). The pre-fix `already_shared=1` on the mailglass axis is now 0.

---

## 7. Deviations from the directed scope

1. **Root cause corrected.** The directed root cause (scratch-prefix collision CASCADE-dropping the
   baseline) is refuted as the cause of the observed failures, with evidence (§3a). It was
   nonetheless a real hazard and is fixed and now structurally prevented, exactly as directed. The
   observed failures came from a different defect in the same file (§3b), found by re-verifying
   rather than assuming.
2. **Three fixes beyond the directed three**, all forced by the rename and all pre-existing latent
   bugs rather than optional cleanups: the `search_path` scoping (Fix 4), citext's schema (Fix 5),
   and the obsolete `SET LOCAL` pins (Fix 6). Without Fix 5 and Fix 6 the renamed modules cannot
   migrate at all; without Fix 4 the suite is still red.
3. **`shipped_migration_divergence_test.exs` was touched** although it was not in the directed list
   of five — it carried the same `SET LOCAL search_path` bug and failed 4/4 in isolation on the
   mailglass axis.
4. **`assert_baseline_intact!/3` added and four call sites collapsed onto it.** Not strictly
   required, but four hand-rolled copies of the same `:cannot_verify` branch is exactly the shape
   where one copy quietly grows a guard — one of them already had.
5. **Commit granularity slipped once.** Fix 4 (the `search_path` scoping) lives in
   `test/mailglass/schema_prefix_hardening_test.exs`, which was staged whole as part of the
   scratch-prefix rename commit (`053b2fd1`), so it did not get the standalone commit its message
   was written for. The change is present and correct; only its separation is imperfect. Not
   rewritten, since the branch history is already published.

## 8. Not closed

- **The formatter's boundary blind spot is unchanged.** `SuiteTruthFormatter` still probes only at
  `:module_finished` of `async: false` modules, so a corruption that occurs and self-heals inside one
  module's own lifecycle stays invisible to it (143-MECHANISM.md §7). Nothing here narrows that; the
  per-module `assert_baseline_intact!/3` and `scratch_schema!/2` calls are the compensating controls.
- **No instrument observes pooled-connection `search_path` globally.** Fix 4 guarantees the one call
  site restores correctly and verifies it, but there is no suite-wide probe that would catch a *new*
  session-level `SET` in some future test. A Credo check forbidding unscoped `SET search_path` in
  `test/` would be the fail-closed layer, mirroring `NoRawSandboxOwnership`; not built here.
- **Test names in `upgrade_v2_schema_migration_test.exs` still say "mailglass.\*"** where they now
  mean the scratch schema. Left as-is deliberately: those names are referenced by ref in earlier 143
  SUMMARY traceability entries.
