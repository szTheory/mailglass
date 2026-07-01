# Schema Isolation Design — mailglass 2.0 (breaking)

> **Milestone 2 — Postgres Schema Isolation.** Locked, decision-ready design.
> Default mailglass domain tables into a dedicated `mailglass` Postgres SCHEMA
> instead of the host app's `public`. Opting back to `public` (or any schema)
> must be **explicit**. Breaking → `mailglass` 2.0 with a documented upgrade path.
>
> Status: **LOCKED** (research-first, decide, escalate rarely). Author: principal
> Elixir/Ecto/Postgres architect. Date: 2026-06-30.

---

## 0. Executive summary (the locked shape)

- **Default schema** = `"mailglass"`. Config key `config :mailglass, :schema, "mailglass"`.
  Opting back to `public` is the explicit `config :mailglass, :schema, "public"`.
- **Runtime prefix, NOT compile-time `@schema_prefix`.** The prefix is adopter-
  configurable at runtime, so it cannot be frozen into a module attribute. It is
  injected at the **`Mailglass.Repo` facade** (already the universal choke point:
  every core read/write routes through it, and inbound's one cross-package read
  goes through `Mailglass.SuppressionStore.Ecto` → `Mailglass.Repo`).
- **Threading mechanism:** the facade merges `prefix: Mailglass.Config.schema()`
  into the opts of every delegated call (`insert/update/delete/one/all/get/aggregate/
  delete_all/query!`), and wraps `Ecto.Multi` execution so **every step** inherits
  the prefix. `Ecto.Query.put_query_prefix/2` is used for read queryables that are
  built and executed in one place; the facade-level opt covers the rest.
- **Migrations** already thread `prefix:` through the structural DSL (v01–v05).
  The three gaps to close: (1) the `migration.ex` entrypoint must inject
  `prefix: Config.schema()` and issue `CREATE SCHEMA` (Ecto's migrator does NOT
  auto-create it); (2) the events immutability **trigger + function** and the
  **CHECK constraints** and **`down/0` drops** are raw `execute()` SQL and must be
  schema-qualified by hand (Ecto does not prefix raw SQL); (3) `citext` stays in
  `public` and the design guarantees `public` is resolvable for type/operator lookup.
- **Inbound** (`mailglass_inbound`) has **no cross-package FKs** (all its FKs are
  internal inbound→inbound). It gets the identical treatment on its own line:
  `config :mailglass_inbound, :schema` (default `"mailglass"`), facade + migration
  prefix threading. Its migrations are NOT yet prefix-aware — that is net-new work.
- **Admin** (`mailglass_admin`) owns NO tables and reads only through
  `Mailglass.Operator.*` → `Mailglass.Repo`. **Zero admin changes required** once the
  facade threads prefix. This is the single biggest simplifier.
- **Tenancy** (`Mailglass.Tenancy.scope/2`) operates on the *queryable* (adds a
  `WHERE tenant_id = ?`); prefix selects the *schema*. They are orthogonal and
  compose — a scoped query still resolves against the configured schema because the
  facade applies the prefix at execution time.

**Top 3 risks:** (1) `citext` silent case-sensitivity if `public` leaves the
resolution path; (2) `Ecto.Multi` steps that bypass the facade's per-op prefix
(must be threaded per-step or via `default_options`); (3) the existing-adopter
`ALTER TABLE … SET SCHEMA` move takes an `ACCESS EXCLUSIVE` lock — cheap to hold,
dangerous to acquire behind a long query.

---

## 1. Ecto/Postgres mechanics — decision table (with LOCKED choices)

Citations: Ecto multi-tenancy-with-query-prefixes guide, `Ecto.Schema`, `Ecto.Query`,
`Ecto.Repo`, `Ecto.Migration` hexdocs; PostgreSQL `citext`, `CREATE EXTENSION`,
`ALTER TABLE`, `ddl-schemas` docs; Oban `Oban.Migration` + module docs.

| Fork | Option A | Option B | LOCKED | Why |
|---|---|---|---|---|
| **Where does prefix live?** | Compile-time `@schema_prefix "mailglass"` on each schema | Runtime `prefix:` injected at facade / `default_options` | **B (runtime, facade-injected)** | `@schema_prefix` is a compile-time attribute; `Application.compile_env` freezes it — an adopter's `config :mailglass, :schema` in `runtime.exs` would be ignored. Oban's decisive precedent: it threads a runtime `:prefix`, never `@schema_prefix`, for exactly this reason. |
| **Facade opt vs `Repo.default_options/1`** | Merge `prefix:` into opts inside `Mailglass.Repo.*` | Adopter sets `def default_options(_), do: [prefix: "mailglass"]` on their repo | **A primary, B optional escape hatch** | mailglass does NOT own the repo (host does) — we cannot define `default_options/1` on the adopter's repo. Facade injection is self-contained and needs no adopter cooperation. Document `default_options/1` as an optional adopter-side convenience only. |
| **Reads: opt vs `put_query_prefix/2`** | Pass `prefix:` opt to `Repo.all/one/aggregate` | `Ecto.Query.put_query_prefix(query, schema)` before execution | **Both, facade-mediated** | The facade adds the `prefix:` opt to every `all/one/aggregate/get`. For queryables the facade can see, this is sufficient. `put_query_prefix/2` is used only where a query is threaded through joins/subqueries and we want the prefix baked into the query struct itself. |
| **Precedence hazard** | — | — | **Never set `@schema_prefix` AND a per-op prefix together** | Ecto inverts precedence: for **queries** `@schema_prefix` beats the `:prefix` opt; for **writes** the `:prefix` opt beats `@schema_prefix`. Mixing them is a silent footgun. Since we choose pure-runtime, we set NO `@schema_prefix` anywhere and rely solely on the runtime opt → one precedence level, no inversion surprises. |
| **`Ecto.Multi` steps** | Rely on connection/default prefix | Thread `prefix:` onto each `Multi.insert/insert_all/update/run` | **B (per-step) + facade multi-wrap** | Multi has no prefix of its own; each op resolves independently. `Repo.multi/2` runs `repo().transaction(multi, opts)` but `opts` does NOT propagate into inner step SQL. We thread prefix at each Multi builder (Events, Outbound, Escalation) via a shared helper. |
| **`on_conflict`/`conflict_target`** | — | — | **No change to fragments** | Conflict-target column fragments (`{:unsafe_fragment, "(idempotency_key) WHERE …"}`) are column-only and schema-agnostic. The **INSERT** carries the prefix (from the step opt), so it hits the right schema's partial index automatically. |
| **Raw DDL (`execute/1,2`)** | Assume prefixing | Hand-qualify every object | **B (hand-qualify)** | `Ecto.Migration.execute/1,2` passes SQL verbatim — NO auto-prefix. The events trigger, its function, both CHECK constraints, and the `down/0` drops must be schema-qualified from the runtime prefix. |
| **Schema creation** | Assume Ecto creates it | `execute("CREATE SCHEMA IF NOT EXISTS …")` at entrypoint | **B** | Ecto's migrator does NOT `CREATE SCHEMA` for a non-public prefix — `create table(prefix:)` FAILS if the schema is absent. `postgres.ex` already computes `create_schema: prefix != "public"`; the entrypoint must actually issue the DDL. |
| **`citext` location** | Move citext into `mailglass` | Keep in `public`, ensure `public` resolvable | **B (keep in public)** | `citext`'s case-insensitivity comes from operators resolved by name via `search_path`. If tables live in `mailglass` but `public` leaves the resolution path, comparisons **silently degrade to case-sensitive** (no error). Keep the extension in `public` and guarantee `public` stays resolvable. |
| **`search_path` vs explicit qualification** | `SET search_path` on connection | Explicit per-query/per-DDL qualification | **B (explicit)** | Unanimous cross-ecosystem verdict. `search_path` mutation leaks/evaporates under PgBouncer transaction mode (Ecto's required mode), is defeated by hardened/empty paths (CVE-2018-1058; PG15 revokes CREATE on public), invalidates plan caches, and makes cross-schema JOINs ambiguous. Explicit `prefix:` is pool-transparent and plan-stable. |

### The one nuance that makes citext safe under explicit qualification

Because we do NOT mutate the connection `search_path`, the default `search_path`
(`"$user", public`) remains in effect for the pooled connections. `citext`'s
operators live in `public`, which is on that default path → case-insensitive
comparison keeps working even though the *tables* are addressed as
`mailglass.mailglass_suppressions`. The **only** way this breaks is if the adopter
has independently hardened their role's `search_path` to exclude `public`; we
document that as a hard requirement ("keep `public` on the path, or install citext
into `mailglass`"). We do NOT `SET search_path` ourselves — that would reintroduce
the pooling footgun.

---

## 2. Oban + cross-ecosystem lessons (adopt / avoid)

### Adopt (from Oban — the gold-standard precedent)
1. **Runtime `:prefix`, default `"public"`; we default *stronger* to `"mailglass"`.**
   Oban proves a library can namespace into a schema with a single runtime lever.
2. **The migration creates the schema for you** (`Oban.Migration.up(prefix:)` runs
   `CREATE SCHEMA`), with a **`create_schema: false` escape hatch** for prod roles
   lacking `CREATE`. We copy this verbatim → `Mailglass.Migration.up(create_schema: false)`.
3. **Schema-qualify ALL raw trigger/function/notify DDL** from the runtime prefix.
   Oban qualifies its `oban_jobs_notify` trigger to the configured prefix; our
   events immutability trigger + function must do the same.
4. **Two-step ceremony is normal and documentable:** migrate with `prefix:` first,
   then set `:prefix`/`:schema` in config. Adopters accept this from Oban.
5. **Isolation is a feature:** running mailglass tables in their own schema keeps
   `public` clean and makes `pg_dump --schema=mailglass` / GDPR erasure targeted.

### Adopt (from the wider Ecto ecosystem)
- **Triplex, paper_trail, the Ecto multi-tenancy guides** all use explicit
  `prefix:` qualification, never per-request `search_path` mutation. This validates
  our facade-injection choice.
- **`Repo.default_options/1` + `prepare_query/3`** is the idiomatic "global default
  prefix" pattern (Ecto FK-tenancy guide). We can't define it on the host repo, but
  we document it as an optional adopter convenience and we mirror its *shape* inside
  the facade.

### Avoid (cross-language cautionary tales)
- **Rails `schema.rb` is namespace-blind** — putting tables in a non-public schema
  forces `structure.sql`. Ecto has no equivalent dump (migrations are the source of
  truth), so we dodge this entirely. Nothing to do; call it out as a non-issue.
- **Django's native multi-schema support is weak** — libs resort to
  `SET search_path` in connection OPTIONS and inherit heavy pooling caveats. This is
  the anti-pattern we explicitly reject.
- **`search_path` mutation footguns** (all cited): PgBouncer transaction-mode leak,
  CVE-2018-1058 shadowing, plan-cache invalidation, ambiguous cross-schema JOINs.

---

## 3. The LOCKED end-to-end design

### 3.1 Config API

```elixir
# lib/mailglass/config.ex — add to @schema
schema: [
  type: :string,
  default: "mailglass",
  doc: """
  Postgres SCHEMA that holds all mailglass domain tables
  (mailglass_events, mailglass_deliveries, mailglass_suppressions,
  mailglass_webhook_events). Defaults to a dedicated `"mailglass"` schema.
  Set to `"public"` to place tables in the host app's public schema
  (the pre-2.0 behavior — now an explicit opt-out). Must be a valid
  unquoted Postgres identifier (`[a-zA-Z_][a-zA-Z0-9_]*`).
  """
]
```

Add a validated accessor + identifier guard (reuse the existing regex from
`Migrations.Postgres.validate_identifier!/2` — promote it to a shared
`Mailglass.Identifier` helper so both config-boot and migration validate identically):

```elixir
@doc since: "2.0.0"
@spec schema() :: String.t()
def schema do
  schema = Application.get_env(:mailglass, :schema, "mailglass")
  Mailglass.Identifier.validate!(schema, :schema)
  schema
end
```

Validate at boot in `validate_at_boot!/0` (fail fast on a bad identifier, same
posture as the repo-adapter check). `:schema` is read on the hot path, so cache it
in `:persistent_term` alongside `:theme` during boot and read from there in
`Mailglass.Repo` to avoid per-call `Application.get_env`.

Inbound mirrors this on its own line: `config :mailglass_inbound, :schema` (default
`"mailglass"`) with its own accessor + `:persistent_term` cache.

### 3.2 Prefix threading through the `Mailglass.Repo` facade (the core mechanism)

Add a single private helper and thread it through every delegated call:

```elixir
# lib/mailglass/repo.ex
@spec put_prefix(keyword()) :: keyword()
defp put_prefix(opts) do
  # Adopter-supplied :prefix wins (explicit override / test isolation);
  # otherwise inject the configured schema. Read from persistent_term
  # (populated at boot) to keep the hot path O(1).
  Keyword.put_new(opts, :prefix, Mailglass.Config.schema())
end

def insert(struct_or_changeset, opts \\ []) do
  repo().insert(struct_or_changeset, put_prefix(opts))
rescue
  err in Postgrex.Error -> translate_postgrex_error(err, __STACKTRACE__)
end
# …identically for update/2, delete/2, one/2, all/2, get/3,
#   aggregate/3, delete_all/2.
```

`Keyword.put_new/3` (not `put/3`) preserves the precedent that a caller passing an
explicit `prefix:` (e.g. a test, or an adopter doing something advanced) overrides
the default — matching Ecto's "explicit `:prefix` opt" being an intentional lever.

**`query!/2` (raw SQL):** the facade cannot prefix arbitrary SQL. Its two current
callers run `SET LOCAL statement_timeout`/`lock_timeout` (schema-agnostic), so no
change is needed. If a future raw caller touches a mailglass table, it must
qualify inline (`#{Config.schema()}.mailglass_events`). Add a doc note.

**`Ecto.Multi` execution (`multi/2`, `transact/2`):** the outer `opts` does not
propagate into inner steps, so we thread prefix at each Multi *builder*, not the
executor. See 3.3.

### 3.3 Multi step prefix threading

Every place that builds a Multi against a mailglass table threads `prefix:`:

```elixir
# Shared helper (new): lib/mailglass/repo.ex or a Mailglass.Persistence module
@spec multi_opts(keyword()) :: keyword()
def multi_opts(opts \\ []), do: Keyword.put_new(opts, :prefix, Mailglass.Config.schema())
```

Wire it into the three known Multi builders:

- **`Mailglass.Events.append_multi/3` / `insert_opts/1`** — already builds
  `[on_conflict:, conflict_target:, returning:]`; add `prefix: Config.schema()`.
- **`Mailglass.Outbound`** — `Ecto.Multi.insert(:delivery, cs, multi_opts())`,
  `Ecto.Multi.insert_all(:deliveries, Delivery, rows, [on_conflict:, conflict_target:,
  returning: true] ++ [prefix: Config.schema()])`, and the `Multi.update` step.
- **`Mailglass.Suppression.Escalation`** — `Repo.insert(cs, on_conflict:,
  conflict_target:, prefix: Config.schema())` and its Multi variant.

`insert_all(Delivery, rows, …)` takes the schema module, so the prefix flows via the
op-level `:prefix`. The `{:unsafe_fragment, …}` conflict targets are unchanged
(column-only → schema-agnostic; the prefixed INSERT hits the right schema's index).

### 3.4 Read-model (Operator.*) handling

`Mailglass.Operator.*` build queryables and execute via `Repo.all/aggregate/one`.
Once the facade injects `prefix:`, **no operator code changes** — the prefix is
applied at execution. `Tenancy.scope/2` still composes: it adds a `WHERE` to the
queryable; the facade adds the schema at execution; both apply. Verify with a
schema-isolated integration test (see Phase order).

For queries that use subqueries/CTEs where the op-level prefix might not reach a
nested `from`, use `Ecto.Query.put_query_prefix(query, Config.schema())` on the
outer query before handing to the facade (belt-and-suspenders; audit each operator
read during the phase).

### 3.5 Migration entrypoint — the missing layer

```elixir
# lib/mailglass/migration.ex
def up(opts \\ []) when is_list(opts) do
  opts = Keyword.put_new(opts, :prefix, Mailglass.Config.schema())
  migrator().up(opts)   # dispatcher already threads prefix into v01..v05
end

def down(opts \\ []) when is_list(opts) do
  opts = Keyword.put_new(opts, :prefix, Mailglass.Config.schema())
  migrator().down(opts)
end
```

**`CREATE SCHEMA` at the entrypoint.** The dispatcher's `with_defaults/2` already
computes `create_schema: prefix != "public"`, but nothing issues the DDL. Add it as
the first action of `Migrations.Postgres.up/1` (inside the runner, where an active
`Ecto.Migration` context exists), honoring an explicit `create_schema: false`:

```elixir
# lib/mailglass/migrations/postgres.ex — in up/1, before change(...)
def up(opts) do
  opts = with_defaults(opts, @current_version)
  maybe_create_schema(opts)   # NEW
  initial = migrated_version(opts)
  # …existing cond…
end

defp maybe_create_schema(%{prefix: prefix, create_schema: true}) do
  validate_identifier!(prefix, :prefix)
  execute(~s(CREATE SCHEMA IF NOT EXISTS #{inspect(prefix)}))
end
defp maybe_create_schema(_), do: :ok
```

`inspect(prefix)` double-quotes the (already identifier-validated) schema name —
matches the existing `quoted_prefix` convention. In `down/1`, drop the schema **only
if we created it** and only after the tables are gone:

```elixir
# after change(range, :down, opts) fully drops v01 tables (version reaches 0)
defp maybe_drop_schema(%{prefix: prefix, create_schema: true}) do
  execute(~s(DROP SCHEMA IF EXISTS #{inspect(prefix)} RESTRICT))
end
```
Use `RESTRICT` (not `CASCADE`) so a non-empty schema — e.g. the adopter parked other
objects there — fails loudly instead of nuking data.

### 3.6 Raw-DDL schema qualification (v01) — the genuine collision fix

The trigger, function, CHECK constraints, and `down/0` drops in v01 (and the CHECK
in v03) are `execute()` SQL and are NOT prefixed. Rewrite them to schema-qualify
from the runtime prefix. **The function MUST be schema-qualified and namespaced by
prefix** so two mailglass installs in different schemas of the same database don't
collide on the unqualified global function name.

```elixir
# lib/mailglass/migrations/postgres/v01.ex — up/1
prefix = opts[:prefix]
q = inspect(prefix)   # "mailglass"

# Function lives IN the schema, and its name is stable within that schema.
execute(
  """
  CREATE OR REPLACE FUNCTION #{q}.mailglass_raise_immutability()
  RETURNS trigger
  LANGUAGE plpgsql
  SET search_path = ''
  AS $$
  BEGIN
    RAISE SQLSTATE '45A01'
      USING MESSAGE = 'mailglass_events is append-only; UPDATE and DELETE are forbidden';
  END;
  $$;
  """,
  "DROP FUNCTION IF EXISTS #{q}.mailglass_raise_immutability()"
)

execute(
  """
  CREATE TRIGGER mailglass_events_immutable_trigger
    BEFORE UPDATE OR DELETE ON #{q}.mailglass_events
    FOR EACH ROW EXECUTE FUNCTION #{q}.mailglass_raise_immutability();
  """,
  "DROP TRIGGER IF EXISTS mailglass_events_immutable_trigger ON #{q}.mailglass_events"
)

# CHECK constraints (v01:166 + v03:16) — qualify the table:
execute(
  """
  ALTER TABLE #{q}.mailglass_suppressions
    ADD CONSTRAINT mailglass_suppressions_stream_scope_check
    CHECK ( (scope = 'address_stream' AND stream IS NOT NULL)
            OR (scope IN ('address','domain') AND stream IS NULL) )
  """,
  "ALTER TABLE #{q}.mailglass_suppressions DROP CONSTRAINT IF EXISTS mailglass_suppressions_stream_scope_check"
)
```

Notes:
- **`SET search_path = ''` on the function** is defense-in-depth (Postgres best
  practice): the function body references nothing unqualified, so an empty search
  path is safe and immunizes it against a caller's ambient path / CVE-2018-1058.
- **Function name stays `mailglass_raise_immutability` but is schema-scoped** — two
  installs (`mailglass.mailglass_raise_immutability` vs
  `public.mailglass_raise_immutability`) are distinct objects. This is the exact
  collision the given footgun (2) describes; qualifying the function name and target
  table resolves it without a `search_path` pin.
- **`v01.down/0`** — apply `#{q}.` to every drop (`DROP TRIGGER … ON #{q}.mailglass_events`,
  `DROP FUNCTION IF EXISTS #{q}.mailglass_raise_immutability()`, and pass `prefix:`
  to `drop(table(...))`). The structural `drop(table(:x, prefix: prefix))` is already
  prefix-aware; the raw executes are not and must be fixed.
- **`CREATE EXTENSION IF NOT EXISTS citext`** stays **unqualified** → installs into
  `public` (default creation schema), which is what we want (§1 nuance). Do NOT
  qualify it into `mailglass`; that would break case-insensitive resolution for any
  adopter whose path doesn't include `mailglass`.
- **`down/0` `DROP EXTENSION citext`** — keep dropping only on full teardown; note
  the extension is shared and its drop is best-effort (`IF EXISTS`). Consider NOT
  dropping citext on `down` at all (an adopter may use it elsewhere) — recommend
  making the citext drop opt-in, but out of scope for this milestone unless trivial.

### 3.7 Inbound package handling (`mailglass_inbound`)

Inbound owns 3 tables (`mailglass_inbound_records`, `_evidence`, `_replay_runs`)
with **only internal FKs** (records ← evidence ← replay_runs) — **no cross-package
FK to `mailglass_events`/`mailglass_deliveries`**. So there is no cross-schema FK
hazard. Its one cross-package touch is a *read* of core suppression via
`Mailglass.SuppressionStore.Ecto`, which routes through `Mailglass.Repo` → already
prefixed by the core facade. Inbound work is therefore self-contained:

1. **Config:** `config :mailglass_inbound, :schema` (default `"mailglass"`), accessor
   + `:persistent_term` cache, identifier validation (share the `Mailglass.Identifier`
   helper — inbound already depends on core via the `== <core>` pin).
2. **Facade:** thread `put_prefix/1` into `MailglassInbound.Repo.{insert,one,all,get}`
   and `multi_opts/1` into its Multi builders.
3. **Migrations:** inbound migrations use the plain `change/0` Ecto convention and
   are **NOT prefix-aware** — this is net-new work. Convert them to `up/0`+`down/0`
   (or thread `prefix:` into every `create table`/`index`/`references`) and issue
   `CREATE SCHEMA IF NOT EXISTS` at the head. Because inbound ships raw `.exs` files
   the adopter copies (unlike core's version-dispatcher), the cleanest path is to
   move inbound to the **same version-dispatcher + wrapper pattern core uses**
   (`MailglassInbound.Migration.up/down` + `Migrations.Postgres.VNN`), which also
   fixes the "7 loose migration files" adopter-copy DX. **Decision:** adopt the
   dispatcher pattern for inbound in this milestone (it's the same 2.0 breaking
   window; do it once).
4. **`references(:mailglass_inbound_records, …)`** inside the same schema needs the
   `prefix:` on the `references` (it defaults to the table's block prefix, so
   threading `prefix:` on the `create table` covers it — verify).

Inbound stays on its own version line (`1.5.x` today); its schema-isolation release
is a **paired 2.0-era bump** driven by the `== <core>` pin drag.

### 3.8 Admin package handling (`mailglass_admin`)

**No changes.** Admin owns no tables and reads exclusively through
`Mailglass.Operator.*` → `Mailglass.Repo`. Once the core facade threads prefix, admin
reads land in the right schema transparently. The only admin task: an integration
test that boots admin against a schema-isolated DB and asserts the dashboard renders
(regression guard). Bump admin's `== <core>` pin to 2.0 as part of the linked release.

### 3.9 Tenancy interaction

Orthogonal and composing, confirmed by reading `Operator.Deliveries.scoped_query/2`:
`Tenancy.scope/2` transforms the *queryable* (`WHERE tenant_id = ?`); the facade
applies the *schema* at execution. A multi-tenant adopter with a schema-per-tenant
resolver would NOT use this mechanism to switch tenant schemas — mailglass's
`:schema` is a single fixed library schema, not a per-tenant one. If an adopter wants
per-tenant *data* isolation they use `tenant_id` scoping (the shipped model); the
`:schema` key isolates mailglass's tables from the host's `public`, a different axis.
Document this explicitly so no one conflates `:schema` with multi-tenant prefixes.

---

## 4. Adopter upgrade path to 2.0

### 4.1 Fresh install (2.0 greenfield)
1. `config :mailglass, repo: MyApp.Repo` (unchanged). `:schema` defaults to
   `"mailglass"` — nothing to set.
2. `mix mailglass.install` / `mix mailglass.gen.migration` emits the 8-line wrapper
   (unchanged shape). `Mailglass.Migration.up/0` now:
   `CREATE SCHEMA IF NOT EXISTS "mailglass"` → creates all tables + qualified trigger
   in `mailglass`.
3. Runtime reads/writes hit `mailglass.*` via the facade. Done. The adopter never
   sees the schema name unless they look.

### 4.2 Existing adopter (tables in `public`) → 2.0
Two supported routes, documented in `guides/upgrading-to-v2_0.md`:

**Route A — keep `public` (zero data movement, minimal risk).** For adopters who
don't want to move data:
```elixir
config :mailglass, :schema, "public"   # explicit opt-out
```
Everything keeps working exactly as 1.x. This is the **explicit `public` opt-out**
and the safest upgrade — a one-line config change, no migration. Recommended default
advice for large existing installs.

**Route B — adopt the `mailglass` schema (recommended long-term).** Ship a
first-class codemod-style Mix task `mix mailglass.upgrade.v2_schema` (mirrors the
existing `mailglass.upgrade.v0_2` Igniter precedent) that generates a move migration:

```elixir
defmodule MyApp.Repo.Migrations.MoveMailglassToSchema do
  use Ecto.Migration
  @schema "mailglass"
  @tables ~w(mailglass_events mailglass_deliveries
             mailglass_suppressions mailglass_webhook_events)

  def up do
    execute "SET LOCAL lock_timeout = '5s'"          # fail fast, don't queue-block
    execute ~s(CREATE SCHEMA IF NOT EXISTS "#{@schema}")
    for t <- @tables, do: execute(~s(ALTER TABLE public.#{t} SET SCHEMA "#{@schema}"))

    # The immutability trigger + function move with the table? NO — the FUNCTION
    # is a separate object created unqualified in public. Recreate it qualified:
    execute ~s(DROP TRIGGER IF EXISTS mailglass_events_immutable_trigger ON "#{@schema}".mailglass_events)
    execute ~s(DROP FUNCTION IF EXISTS public.mailglass_raise_immutability())
    execute """
      CREATE OR REPLACE FUNCTION "#{@schema}".mailglass_raise_immutability()
      RETURNS trigger LANGUAGE plpgsql SET search_path = '' AS $$
      BEGIN RAISE SQLSTATE '45A01' USING MESSAGE =
        'mailglass_events is append-only; UPDATE and DELETE are forbidden'; END; $$;
    """
    execute """
      CREATE TRIGGER mailglass_events_immutable_trigger
        BEFORE UPDATE OR DELETE ON "#{@schema}".mailglass_events
        FOR EACH ROW EXECUTE FUNCTION "#{@schema}".mailglass_raise_immutability();
    """
    # COMMENT-based version marker: ALTER TABLE SET SCHEMA preserves the comment,
    # so per-prefix version tracking (obj_description on mailglass_events) stays intact.
  end

  def down do
    for t <- @tables, do: execute(~s(ALTER TABLE "#{@schema}".#{t} SET SCHEMA public))
    execute ~s(DROP TRIGGER IF EXISTS mailglass_events_immutable_trigger ON public.mailglass_events)
    execute ~s(DROP FUNCTION IF EXISTS "#{@schema}".mailglass_raise_immutability())
    # recreate the public-qualified trigger/function (mirror of up) …
  end
end
```

Facts that make Route B safe (all cited in the research):
- `ALTER TABLE … SET SCHEMA` is **metadata-only** (OID relnamespace swap) — instant
  regardless of table size, no rewrite.
- **Indexes, constraints, and column-owned sequences move with the table** — no
  separate moves. mailglass PKs are UUIDv7 (no sequences), so even the standalone-
  sequence caveat doesn't apply.
- **FKs, views, functions resolve by OID** — inbound's internal FKs and any host
  views over mailglass tables keep working. The **only** breakage is literal
  `public.mailglass_*` strings in host SQL — grep for those (the migration guide's
  checklist item).
- **`citext` column type is unaffected** (stored by type OID); the trap is only the
  operator resolution — keep `public` on the path (which the default path does).
- **The trigger's FUNCTION does NOT auto-move** — it was created unqualified in
  `public` in 1.x. The move migration explicitly recreates it in `mailglass`. This is
  the single manual step the codemod handles.

**Locking / downtime:** `SET SCHEMA` takes `ACCESS EXCLUSIVE`, cheap to hold but it
queues behind long readers and blocks new ones once waiting. The `SET LOCAL
lock_timeout = '5s'` makes the DDL fail fast and retry instead of stalling traffic.
For mailglass's 4 small metadata-move statements this is effectively zero-downtime;
document the `lock_timeout` + retry posture.

### 4.3 Rollback
- **Route A** (config `"public"`): revert the one config line.
- **Route B**: the generated migration ships a real `down/0` that moves tables back
  to `public` and restores the public-qualified trigger/function. Because moves are
  metadata-only and reversible, rollback is fast. Adopters can also stay on
  `config :schema, "public"` after a partial rollback.

### 4.4 `create_schema: false` (locked-down prod)
For roles lacking `CREATE` on the database, `Mailglass.Migration.up(create_schema:
false)` skips `CREATE SCHEMA` (a DBA pre-creates `mailglass` + grants `USAGE`). Direct
Oban parallel. Document the required grants:
```sql
CREATE SCHEMA mailglass AUTHORIZATION app_role;   -- or GRANT USAGE …
GRANT USAGE ON SCHEMA mailglass TO app_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA mailglass GRANT SELECT,INSERT,UPDATE,DELETE ON TABLES TO app_role;
```

---

## 5. Phased build order (maps to GSD phases) + non-goals

**Phase A — Config + identifier foundation.** Add `:schema` to `Mailglass.Config`
(default `"mailglass"`), promote the identifier regex to `Mailglass.Identifier`,
validate at boot, cache in `:persistent_term`. Same for `mailglass_inbound`. *No
behavior change yet* (facade not wired) — pure additive. Verify: config tests +
`mix credo`.

**Phase B — Repo facade prefix injection (core).** Thread `put_prefix/1` through
every `Mailglass.Repo` read/write + `multi_opts/1` into Events/Outbound/Escalation
Multi builders. Verify: full core suite under BOTH `schema: "public"` and
`schema: "mailglass"` (new CI matrix axis), plus a dedicated schema-isolation
integration test (create schema, migrate, round-trip insert/read, assert
`mailglass.*` tables exist and `public` is empty of mailglass tables).

**Phase C — Migration entrypoint + raw-DDL qualification.** Inject prefix at
`Mailglass.Migration.up/down`; add `maybe_create_schema/1` + `maybe_drop_schema/1`;
schema-qualify the v01 trigger/function/CHECKs + v03 CHECK + all `down/0` raw drops;
keep `citext` in `public`. Verify: migrate up/down against a non-public prefix; assert
the immutability trigger fires (SQLSTATE 45A01) under the `mailglass` schema WITHOUT a
`search_path` pin (this is the regression the given footgun (2) demands).

**Phase D — Inbound package.** Config key, facade threading, and convert inbound
migrations to the prefix-aware version-dispatcher pattern with `CREATE SCHEMA`.
Verify: inbound suite under both prefixes (use `--seed 0` per the known flake memory).

**Phase E — Upgrade tooling + docs.** `mix mailglass.upgrade.v2_schema` codemod
generating the Route B move migration; `guides/upgrading-to-v2_0.md` (Route A/B,
grants, `create_schema: false`, `public.` grep checklist, lock_timeout posture);
update `api_stability.md` with the `:schema` config contract. Verify: run the codemod
against `reference/host_app` (frozen baseline) end-to-end; assert green.

**Phase F — Release ceremony (2.0/2.0/2.x).** Linked core+admin 2.0; paired inbound
bump (== pin drag). Update reference baseline (the 5-file coordinated change per the
baseline-coupling memory). Follow the documented release lessons (push-before-merge,
whole-lane validation, racing fan-outs).

### Non-goals (explicitly out of scope)
- **Per-tenant schemas.** `:schema` is one fixed library schema, not a Triplex-style
  per-tenant prefix. Multi-tenant *data* isolation remains `tenant_id` scoping.
- **Mutating the connection `search_path`.** Rejected on principle (§1).
- **Moving `citext` out of `public`.** Kept in `public` deliberately.
- **MySQL/SQLite.** Still Postgres-only.
- **Changing the `tenant_id`-on-every-row model.** Unaffected.
- **Runtime schema switching per request.** The schema is a boot-time constant.

---

## 6. Footguns / pitfalls checklist (with mitigations)

1. **citext silent case-sensitivity.** If tables move to `mailglass` and `public`
   leaves the resolution path, `WHERE address = ?` on `mailglass_suppressions` goes
   case-sensitive with NO error. → Keep citext in `public`; never `SET search_path`
   to exclude it; document "keep `public` on the path." Add a `mix mail.doctor` check
   that verifies citext operators resolve.
2. **`Ecto.Multi` steps miss the prefix.** The executor `opts` don't reach inner
   step SQL. → Thread `prefix:` at each Multi *builder* (Phase B); add a test that a
   Delivery+Events Multi lands in `mailglass`, not `public`.
3. **`ALTER TABLE SET SCHEMA` lock stall.** `ACCESS EXCLUSIVE` queues behind long
   readers and blocks new ones once waiting. → `SET LOCAL lock_timeout` + retry in
   the generated move migration; document.
4. **The immutability FUNCTION doesn't move with the table.** It's a separate,
   unqualified-in-`public` object. → The Route B codemod explicitly recreates it
   schema-qualified; Phase C creates it qualified for fresh installs. This is the
   real collision the footgun (2) flagged.
5. **Two installs colliding on the global function name.** Unqualified
   `mailglass_raise_immutability()` in the same DB across two schemas would collide.
   → Function is created IN the schema (`mailglass.mailglass_raise_immutability`);
   qualified name is unique per schema.
6. **`@schema_prefix` + runtime prefix precedence inversion.** Setting both silently
   flips which wins for reads vs writes. → We set NO `@schema_prefix` anywhere; pure
   runtime. Add a Credo/grep guard that no mailglass schema declares `@schema_prefix`.
7. **`create table(prefix:)` fails if schema absent.** Ecto won't auto-create. →
   `maybe_create_schema/1` runs first (Phase C); `create_schema: false` escape hatch.
8. **`DROP SCHEMA CASCADE` data loss.** → Use `RESTRICT`; only drop if we created it.
9. **Host SQL with literal `public.mailglass_*`.** Breaks after the move (OID
   resolution can't save literal-string schema refs). → Upgrade guide grep checklist.
10. **`query!/2` raw callers.** Not auto-prefixed. → Current callers are
    schema-agnostic (`SET LOCAL`); document the requirement; add a lint note.
11. **PgBouncer transaction mode + `search_path`.** Would leak/evaporate if we used
    `search_path`. → We don't; explicit qualification is pool-transparent.
12. **Version-comment marker survival.** Per-prefix version tracking uses
    `obj_description` on `mailglass_events`; `ALTER TABLE SET SCHEMA` preserves the
    comment, so Route B keeps the marker intact. Verify in the move-migration test.
13. **Test isolation.** The test repo config must set `:schema` (or default to
    `mailglass`) consistently; SQL Sandbox works fine with a non-public prefix but
    the schema must exist before the sandbox starts — create it in `test_helper.exs`
    / a migration run at suite setup.

---

## 7. Concrete diff surface (files touched)

- `lib/mailglass/config.ex` — add `:schema` key, `schema/0` accessor, boot validation,
  persistent_term cache.
- `lib/mailglass/identifier.ex` — NEW shared identifier validator (extracted from
  `Migrations.Postgres`).
- `lib/mailglass/repo.ex` — `put_prefix/1` + thread through all delegated calls;
  export `multi_opts/1`.
- `lib/mailglass/events.ex` — `insert_opts/1` add `prefix:`.
- `lib/mailglass/outbound.ex` — thread `prefix:` into Multi insert/insert_all/update.
- `lib/mailglass/suppression/escalation.ex` — add `prefix:` to insert + Multi.
- `lib/mailglass/suppression_store/ecto.ex` — inherits facade prefix (verify only).
- `lib/mailglass/migration.ex` — inject `prefix:` at `up/down`.
- `lib/mailglass/migrations/postgres.ex` — `maybe_create_schema/1` + `maybe_drop_schema/1`.
- `lib/mailglass/migrations/postgres/v01.ex` — qualify trigger/function/CHECK + down/0.
- `lib/mailglass/migrations/postgres/v03.ex` — qualify CHECK + down/0.
- `lib/mailglass/operator/*.ex` — audit for subquery `put_query_prefix/2` (likely none).
- `lib/mix/tasks/mailglass.upgrade.v2_schema.ex` — NEW Route B codemod.
- `guides/upgrading-to-v2_0.md` — NEW.
- `mailglass_inbound/…` — config key, facade, migration dispatcher conversion.
- `mailglass_admin/…` — no code change; pin bump + integration test.
- `reference/…` — baseline update (coordinated 5-file change).
```
