# Populated-Table Migration Policy

Mailglass migrations are package-owned DDL executed by an adopter's Ecto Repo. Treat every existing
table as populated and serving live traffic. Append a new `VNN` module; never edit a shipped migration.
Core V01–V05 and inbound V01 are byte-frozen by
`test/mailglass/shipped_migration_divergence_test.exs`.

## Required sequence

1. **Expand.** Add nullable columns, compatible defaults, and other additive structures. Set a finite
   `lock_timeout` and `statement_timeout` for short catalog changes. Fresh installs retain the stable
   transactional install wrapper and use ordinary indexes against empty tables. Do not combine an expansion with a
   destructive rename, type rewrite, or constraint validation that scans the whole table.
2. **Build indexes without blocking writers.** Populated-table indexes use
   `CREATE INDEX CONCURRENTLY` from a generated wrapper containing both
   `@disable_ddl_transaction true` and `@disable_migration_lock true`. The wrapper also passes
   `non_transactional_wrapper: true` to the package migration facade. Do not paste package DDL into a
   host migration or add these attributes to an old wrapper by hand; generate a new upgrade wrapper.
3. **Backfill.** Run a bounded, resumable backfill in small committed batches. Record or derive a stable
   cursor, make each batch safe to repeat, and stop on error. Reads must support old and new rows for the
   entire transition; new writes populate both representations when compatibility requires it.
4. **Observe and verify.** Confirm package version anchors, new columns, index validity, query shape,
   mixed-row behavior, and application error rates before deploying code that requires the expansion.
5. **Contract later.** Remove legacy reads, columns, constraints, or indexes only in a later release
   after the compatibility window and an independently reversible rollout.

## Generate the upgrade wrappers

From a host already anchored at core V05 and inbound V01:

```sh
mix mailglass.gen.migration --upgrade --from 5 --repo MyApp.Repo
mix mailglass.inbound.gen.migration --upgrade --from 1 --repo MyApp.Repo
mix ecto.migrate -r MyApp.Repo
```

Omit `--from` to let the generator inspect the selected live Repo. An explicit `--from` is useful in a
build artifact that cannot connect to production, but it is an operator assertion: verify the live
package anchor before deploying it. A timestamp collision or unknown anchor fails without replacing an
existing file.

The generated source is intentionally non-transactional because PostgreSQL forbids concurrent index
creation inside a transaction. Each package facade selects concurrent DDL only when the generated
wrapper supplies `non_transactional_wrapper: true`; direct or historical wrappers keep the
transactional compatibility path.

## Retry and invalid-index recovery

A failed concurrent build can leave an index present but invalid. Do not mark the package version
forward and do not delete package tables. Inspect the fixed package-owned index names:

```sql
SELECT n.nspname, c.relname, i.indisvalid, i.indisready
FROM pg_index AS i
JOIN pg_class AS c ON c.oid = i.indexrelid
JOIN pg_namespace AS n ON n.oid = c.relnamespace
WHERE n.nspname = 'mailglass' AND c.relname LIKE 'mailglass_%_idx';
```

The new version's concurrent path removes its own fixed index names with
`DROP INDEX CONCURRENTLY IF EXISTS` before rebuilding them. Re-run the same generated upgrade after the
failed migration has released its connection. This recovers invalid indexes and is idempotent for the
version-owned expansion; never drop an adopter-owned or unknown index.

For the inbound SHA-256 transition, resume bounded batches until a batch reports zero updated rows. Old
rows remain readable through the MD5 fallback while new and backfilled rows prefer SHA-256. Keep the
legacy representation and its indexes until a later contract release.

## Rollback boundary

The generated upgrade wrapper's `down/0` returns only to the declared prior package version: core V06
to V05 and inbound V02 to V01. It removes the additive version's columns, triggers, and indexes, but it
does not tear down the prior installation. Roll back application code before rolling back an expansion,
and do not roll back after code or data has begun depending exclusively on the new representation.

Run the repository's real Postgres certification journey before release:

```sh
MAILGLASS_PATH="$PWD" bash scripts/generated_ecto_host_proof.sh
```

`scripts/generated_ecto_host_proof.sh` generates an isolated Phoenix/Ecto host, populates prior-version
schemas, applies both public upgrade generators, exercises backfill and evidence behavior, validates
indexes, and returns only the additive versions to their prior anchors.

## Package and product boundaries

The core and inbound migrations are independent. Either package may be installed, upgraded, or rolled
back without assuming the other package owns its relations; sharing a schema does not merge their
version anchors. This policy does not add or modify any admin/operator schema or UI. Operator tooling
may observe migration state later, but it is not part of migration correctness or recovery.
