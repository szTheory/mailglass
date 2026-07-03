# Upgrading to v2.0

This is the canonical `1.x` to `2.0` upgrade guide for Mailglass.

The one change that matters in `2.0` is where mailglass keeps its tables. In
`1.x`, mailglass installed its four domain tables into your `public` Postgres
schema alongside your own. In `2.0`, they default to a dedicated `mailglass`
Postgres schema instead. This isolates mailglass from your `public` namespace so
its tables, trigger, and function no longer share a schema with your application.

The four tables are `mailglass_events`, `mailglass_deliveries`,
`mailglass_suppressions`, and `mailglass_webhook_events`.

There are two supported upgrade routes. Read both, pick one, and execute it. Most
existing installs should reach for Route A first; new-schema adoption (Route B) is
the recommended long-term shape but it is a real migration, so choose it
deliberately.

## Who this guide is for

Use this guide if you run an existing `1.x` mailglass deployment — your four
mailglass tables already live in `public` — and you are moving onto the `2.0`
contract. If you are installing mailglass fresh on `2.0`, you do not need this
guide: the default `mailglass` schema is created for you and you never touch
`public`.

## Route A — keep `public` (zero data movement)

If you do not want to move data, opt out of the new default with one line:

```elixir
config :mailglass, :schema, "public"
```

That is the whole upgrade. Everything keeps working exactly as it did on `1.x`
because your tables never move. This is the **explicit `public` opt-out** — it is
the safest path and the recommended advice for large existing installs where a
schema move is not worth the coordination.

Choose Route A when:

- you want the smallest possible `2.0` diff
- you cannot schedule even a brief migration window
- other systems read `mailglass_*` tables by their `public`-qualified names and
  you are not ready to requalify them (see the grep checklist below)

Route A is a conscious, permanent choice, not a temporary bridge. You can adopt
the `mailglass` schema later via Route B whenever it suits you.

## Route B — adopt the `mailglass` schema (recommended long-term)

Route B moves your four existing tables from `public` into the `mailglass`
schema. Mailglass ships a first-class Mix task that writes the migration for you —
you review it, then run it like any other migration.

```bash
mix mailglass.upgrade.v2_schema
mix ecto.migrate
```

`mix mailglass.upgrade.v2_schema` generates a `MoveMailglassToSchema` migration in
your `priv/repo/migrations/`. Read the generated file before you migrate. It:

- opens with `SET LOCAL lock_timeout = '5s'` so the moves fail fast instead of
  queue-blocking (see the locking posture below)
- runs `CREATE SCHEMA IF NOT EXISTS "mailglass"`
- runs `ALTER TABLE public.<table> SET SCHEMA "mailglass"` for all four tables
- recreates the append-only immutability function and trigger, schema-qualified
  under `mailglass`, byte-identical to a fresh `2.0` install
- ships a real `down/0` that reverses the move back into `public`

### Why the move is safe

- `ALTER TABLE … SET SCHEMA` is **metadata-only** — it swaps the table's schema
  reference and is instant regardless of table size. There is no table rewrite.
- **Indexes, constraints, and column-owned sequences move with the table.**
  mailglass primary keys are UUIDs, so there are no standalone sequences to worry
  about.
- **Foreign keys, views, and functions that reference the tables resolve by
  internal identity**, so they keep working across the move. The one thing that
  does not follow automatically is any **literal `public.mailglass_*` string** in
  your own SQL — see the grep checklist.
- **The `citext` extension stays in `public`.** The migration never touches it;
  only the tables move. Case-insensitive address matching keeps working.
- **The version-marker comment survives the move**, so mailglass still reports the
  correct installed schema version after the migration and will not try to
  re-run earlier migrations.
- **The immutability function is recreated, not moved.** In `1.x` the trigger's
  function was created unqualified in `public`; the generated migration drops it
  and recreates it qualified under `mailglass`. This is the single manual step,
  and the task does it for you.

### The `public.mailglass_*` grep checklist

Schema qualification cannot rescue hard-coded strings. If any of your own SQL,
views, functions, or dashboards reference a mailglass table by its
`public`-qualified name — for example `public.mailglass_events` — that reference
will break after the move because the table is no longer in `public`.

Before you migrate, grep your codebase:

```bash
grep -rn "public.mailglass_" .
```

For each hit, either requalify it to `mailglass.<table>` or drop the schema
prefix entirely and let `search_path` resolve it. This is the only application-
side breakage the move can cause, and it is entirely mechanical to fix.

### Locking posture and retry

`ALTER TABLE … SET SCHEMA` takes an `ACCESS EXCLUSIVE` lock. The lock is cheap to
hold — the move is metadata-only and instant once granted — but it queues behind
long-running readers and blocks new queries once it is waiting. The generated
migration guards against this with `SET LOCAL lock_timeout = '5s'`: the schema
moves fail fast with SQLSTATE `55P03` (`lock_not_available`) instead of stalling
your traffic behind a long reader.

The whole migration runs in a single transaction, so a lock timeout rolls the
entire move back cleanly — you never end up with tables split across two schemas.
If the migration aborts with `55P03`, it means a long-running query held one of
the tables. Retry `mix ecto.migrate` off-peak; the move is metadata-only and
completes instantly once the lock is granted.

Do not add `@disable_ddl_transaction` to the generated migration. `SET LOCAL`
only takes effect inside a transaction, and the transactional wrapper is what
makes a lock abort roll back safely.

### Locked-down production roles (`create_schema: false`)

If your application's database role lacks `CREATE` privilege on the database — a
common hardened-production posture — a DBA must pre-create the schema and grant
access, then you run the migration with schema creation skipped:

```sql
CREATE SCHEMA mailglass AUTHORIZATION app_role;
GRANT USAGE ON SCHEMA mailglass TO app_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA mailglass GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_role;
```

Then invoke the migration path with `create_schema: false` so mailglass skips the
`CREATE SCHEMA` statement (the DBA already made it):

```elixir
Mailglass.Migration.up(create_schema: false)
```

This mirrors the same `create_schema: false` posture Oban and other Ecto-based
libraries use for roles that cannot create schemas themselves.

## Rollback

- **Route A:** revert the one `config :mailglass, :schema, "public"` line.
- **Route B:** the generated migration ships a real `down/0` that moves the four
  tables back into `public` and restores the `public`-qualified immutability
  trigger and function. Because the moves are metadata-only, rollback is fast. You
  can also stop after a partial rollback and stay on `config :mailglass, :schema,
  "public"` (Route A) indefinitely.

## Verification before shipping

After you migrate, confirm the tables landed where you expect:

```sql
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_name LIKE 'mailglass_%';
```

All four tables should report `mailglass` as their `table_schema` (Route B) or
`public` (Route A). Then run your normal test and compile checks before you ship.

## Upgrade outcome

You are `2.0`-ready when:

- you have chosen Route A or Route B deliberately, not by default
- if you took Route B, all four tables report the `mailglass` schema and your
  `public.mailglass_*` grep is clean
- if you took Route A, the explicit `config :mailglass, :schema, "public"` opt-out
  is in place and your tables are untouched
