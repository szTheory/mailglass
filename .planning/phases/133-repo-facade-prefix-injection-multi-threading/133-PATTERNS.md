# Phase 133: Repo-facade prefix injection + Multi threading - Pattern Map

**Mapped:** 2026-07-02
**Files analyzed:** 7 (6 MODIFY + 1 CREATE)
**Analogs found:** 7 / 7

All files this phase touches already exist except the new schema-isolation
integration test. Every MODIFY target is edited in place; the "analog" for a
MODIFY file is its own current shape (the exact lines `put_prefix/1` /
`multi_opts/1` / `prefix:` slots into). The one CREATE file (the FACADE-04
integration test) has a strong, near-copy analog in
`test/mailglass/shipped_migration_divergence_test.exs`.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/mailglass/repo.ex` (MODIFY) | facade / repo-wrapper | request-response (CRUD delegation) | *self* — existing `insert/2`..`delete_all/2` wrappers + `multi/2` | exact (in-place) |
| `lib/mailglass/events.ex` (MODIFY) | service (ledger writer) | CRUD (insert + Multi step) | *self* — `insert_opts/1` chokepoint | exact (in-place) |
| `lib/mailglass/outbound.ex` (MODIFY) | service (send pipeline) | CRUD via `Ecto.Multi` (insert/insert_all/update) | *self* — the 3 Multi builders + inner `repo.insert_all` | exact (in-place) |
| `lib/mailglass/suppression/escalation.ex` (MODIFY) | service / Oban worker | CRUD (insert + Multi variant) | *self* — `insert_suppression/1` + `enqueue/2` | exact (in-place) |
| `lib/mailglass/operator/support_summary.ex` (MODIFY) | read-model | request-response (correlated `not exists` subquery) | *self* — `unresolved_orphans_query/2` (~l.190) | exact (in-place) |
| `lib/mailglass/operator/replay_targets.ex` (AUDIT only) | read-model | request-response (raw string-source queries) | *self* — `load_candidate/3` (l.99–141) | exact (audit) |
| NEW schema-isolation integration test (CREATE) | test (integration) | file-I/O + CRUD round-trip under a prefixed schema | `test/mailglass/shipped_migration_divergence_test.exs` | near-copy |
| `mailglass_admin/test/mailglass_admin/operator_live_test.exs` (MODIFY) | test (LiveView) | request-response (write→read→render) | *self* — existing render+fixture helpers | exact (in-place) |

---

## Pattern Assignments

### `lib/mailglass/repo.ex` (facade, CRUD delegation) — FACADE-01, FACADE-02

**Analog:** the file's own existing delegated wrappers. Every wrapper today has the
identical two-line shape (delegate + `rescue`). `put_prefix/1` slots into the
delegate call arg **without touching the rescue clause**.

**Current wrapper shape — where `put_prefix/1` slots in (exact current lines):**
- `insert/2` — l.61–66: change `repo().insert(struct_or_changeset, opts)` (l.62) → `... put_prefix(opts))`. Rescue at l.63–65 stays verbatim.
- `update/2` — l.72–77: change `repo().update(changeset, opts)` (l.73). Keep rescue l.74–76.
- `delete/2` — l.83–88: change `repo().delete(struct_or_changeset, opts)` (l.84). Keep rescue l.85–87.
- `one/2` — l.116: `def one(queryable, opts \\ []), do: repo().one(queryable, put_prefix(opts))` (no rescue — leave one-liner).
- `all/2` — l.121: `... repo().all(queryable, put_prefix(opts))`.
- `delete_all/2` — l.134: `... repo().delete_all(queryable, put_prefix(opts))`.
- `aggregate/3` — l.138–139: currently 3-arg with NO opts. Threading needs a 4th opt arg. See "Watch-out" below.
- `get/3` — l.144: `... repo().get(queryable, id, put_prefix(opts))`.

**DO NOT prefix (locked D-02):**
- `transact/2` — l.50–55 (opts don't reach inner steps; that's `multi_opts/1`'s job).
- `multi/2` — l.106–111 (same reason).
- `query!/2` — l.161–162 (raw SQL, facade can't rewrite; two callers run schema-agnostic `SET LOCAL`). Add the doc note from CONTEXT D-02 / dossier §3.2: a future raw caller touching a mailglass table must qualify inline.

**Locked helper shape to ADD (CONTEXT `<specifics>` + dossier §3.2/§3.3):**
```elixir
@spec put_prefix(keyword()) :: keyword()
defp put_prefix(opts), do: Keyword.put_new(opts, :prefix, Mailglass.Config.schema())

@spec multi_opts(keyword()) :: keyword()
def multi_opts(opts \\ []), do: Keyword.put_new(opts, :prefix, Mailglass.Config.schema())
```
`multi_opts/1` is **public** (lives beside the existing public `multi/2`, l.104–111);
`put_prefix/1` is **private** (lives beside `repo/0`, l.168–174). Use `Keyword.put_new`
so an explicit caller `:prefix` wins.

**The rescue clause the threading must NOT disturb (l.180–190):**
```elixir
defp translate_postgrex_error(%Postgrex.Error{postgres: %{pg_code: "45A01"}} = err, stacktrace) do
  type = infer_immutability_type(err)
  reraise Mailglass.EventLedgerImmutableError.new(type, cause: err, context: %{pg_code: "45A01"}), stacktrace
end
defp translate_postgrex_error(err, stacktrace), do: reraise(err, stacktrace)
```
`put_prefix/1` only rewrites the opts passed to `repo().<op>` — it is a pure keyword
transform with no failure mode, so the existing `rescue err in Postgrex.Error` blocks
are unchanged in every wrapper.

**Watch-out — `aggregate/3` has no opts arg today (l.138–139):**
```elixir
@spec aggregate(Ecto.Queryable.t(), atom(), atom()) :: term() | nil
def aggregate(queryable, aggregate, field), do: repo().aggregate(queryable, aggregate, field)
```
To thread a prefix it must gain a 4th opts param (`aggregate(queryable, agg, field, opts \\ [])`)
and pass `put_prefix(opts)`. Check callers (`grep -rn "Repo.aggregate"` — operator read-model + overview health counts) so the arity change is source-compatible (default arg keeps existing 3-arg calls working). This is the one signature change; all other wrappers already accept `opts`.

---

### `lib/mailglass/events.ex` (service, CRUD chokepoint) — FACADE-02

**Analog:** `insert_opts/1` (l.176–184) — the single opts builder consumed by BOTH
`append/1` (via `do_insert/1`, l.196 & l.206) and `append_multi/3` (l.135 map form,
l.153 function form).

**Current chokepoint (l.176–184):**
```elixir
defp insert_opts(%{idempotency_key: key}) when is_binary(key) do
  [
    on_conflict: :nothing,
    conflict_target: {:unsafe_fragment, "(idempotency_key) WHERE idempotency_key IS NOT NULL"},
    returning: true
  ]
end

defp insert_opts(_), do: [returning: true]
```

**Threading (dossier §3.3, CONTEXT D-04):** add `prefix: Mailglass.Config.schema()`
to BOTH clauses' keyword lists (or `Keyword.put_new` the result through
`Mailglass.Repo.multi_opts/0`). Threading here alone covers all four write sites:
- `append_multi/3` map form (l.135) `Ecto.Multi.insert(multi, name, changeset, insert_opts(normalized))`
- `append_multi/3` fn form (l.153) `repo.insert(changeset, opts)` where `opts = insert_opts(normalized)`
- `do_insert/1` idempotent (l.196) `Mailglass.Repo.insert(changeset, insert_opts(attrs))`
- `do_insert/1` plain (l.206) `Mailglass.Repo.insert(insert_opts(attrs))`

The `{:unsafe_fragment, …}` conflict target stays byte-for-byte (column-only →
schema-agnostic). **Claude's discretion note (CONTEXT):** `Keyword.put_new` vs
`Keyword.merge` — keep "explicit caller `:prefix` wins" precedence.

**Note — `fetch_by_idempotency_key/1` (l.209–215)** reads via `Mailglass.Repo.one`
(l.212), so it inherits the facade `put_prefix/1` automatically. No change needed here.

---

### `lib/mailglass/outbound.ex` (service, Multi CRUD) — FACADE-02

**Analog:** the file's own Multi builders. Every `Ecto.Multi.insert/insert_all/update`
step + the inner `repo.insert_all(Event, …)` must carry `:prefix`. Exact sites:

- **`enqueue_oban/3`** — `Ecto.Multi.insert(:delivery, …)` l.389 (currently no opts → add `multi_opts()`).
- **`enqueue_task_supervisor/3`** — `Ecto.Multi.insert(:delivery, …)` l.425 (add opts).
- **`insert_batch/1`** — `Ecto.Multi.insert_all(:deliveries, Delivery, rows, [on_conflict:, conflict_target:, returning: true])` l.557–561: append `prefix: Config.schema()` to that opts list.
- **`insert_batch/1` inner** — `repo.insert_all(Mailglass.Events.Event, event_rows, [on_conflict:, conflict_target:, returning: false])` l.580–585: append `prefix:` to that opts list too (inner-step opts do NOT inherit the transaction prefix — footgun 2).
- **`persist_queued/2`** — `Ecto.Multi.insert(:delivery, Delivery.changeset(...))` l.697–712 (add opts).
- **`persist_dispatched_multi/3`** — `Ecto.Multi.update(:delivery, …)` l.772–781 (add opts).
- **`persist_failed_by_id/2`** — `Ecto.Multi.update(:delivery, …)` l.802–809 (add opts).

**Existing `insert_all` opts shape to extend (l.557–561):**
```elixir
|> Ecto.Multi.insert_all(:deliveries, Delivery, rows,
  on_conflict: :nothing,
  conflict_target: {:unsafe_fragment, "(idempotency_key) WHERE idempotency_key IS NOT NULL"},
  returning: true
)
```
→ append `prefix: Mailglass.Config.schema()` (via `Repo.multi_opts/1` or inline).
`Config` is already aliased at l.83; `Repo` at l.84. `Events.append_multi` steps
(l.390, l.426, l.713, l.782) inherit prefix from the `Events.insert_opts/1` change
above — do NOT double-thread them.

**Reads that inherit the facade prefix automatically (no change):** `load_delivery/1`
(`Repo.one`, l.868), `insert_batch/1` re-fetch (`Repo.all(Tenancy.scope(query))`, l.603).

---

### `lib/mailglass/suppression/escalation.ex` (service / Oban worker, CRUD) — FACADE-02

**Analog:** `insert_suppression/1` (l.121–138) — the standalone insert. Its "Multi
variant" is `enqueue/2` (l.39–48), which enqueues via `OptionalDeps.Oban.insert`.

**Current insert (l.121–128):**
```elixir
defp insert_suppression(attrs) do
  changeset = Entry.changeset(attrs)
  case Repo.insert(changeset,
         on_conflict: :nothing,
         conflict_target: @conflict_target,
         returning: true
       ) do
```
→ add `prefix: Mailglass.Config.schema()` to the `Repo.insert/2` opts list. `@conflict_target`
(l.27, `{:unsafe_fragment, "(tenant_id, address, scope, COALESCE(stream, ''))"}`) is
column-only → unchanged. `Repo` is already aliased (l.18); add a `Config` alias or
call `Mailglass.Config.schema()` fully-qualified.

**Reads that inherit facade prefix (no change):** `deferred_count/3` (`Repo.one`, l.101),
`fetch_existing!/2` (`Repo.one`, l.151).

**Note:** whole module is wrapped in `if Code.ensure_loaded?(Oban.Worker)` (l.1) — the
prefix change lives inside that guard, no `--no-optional-deps` concern.

---

### `lib/mailglass/operator/support_summary.ex` (read-model, correlated subquery) — FACADE-01, FACADE-04

**Analog:** `unresolved_orphans_query/2` (l.190–210) — the ONE query with a nested
`from` inside `not exists(...)`. This is the sole defensive `put_query_prefix/2` site.

**Current subquery (l.190–210):**
```elixir
defp unresolved_orphans_query(tenant_id, window_started_at) do
  from(event in Event,
    as: :orphan,
    where: event.tenant_id == ^tenant_id,
    where: event.needs_reconciliation == true and is_nil(event.delivery_id),
    where: event.occurred_at >= ^window_started_at,
    where:
      not exists(
        from(reconciled in Event,
          where: reconciled.tenant_id == parent_as(:orphan).tenant_id,
          where: reconciled.type == ^:reconciled,
          where:
            fragment("?->>'reconciled_from_event_id' = CAST(? AS text)",
              reconciled.metadata, parent_as(:orphan).id)
        )
      )
  )
end
```

**Threading (CONTEXT D-05, dossier §3.4):** apply
`Ecto.Query.put_query_prefix(query, Mailglass.Config.schema())` to the returned outer
query (belt-and-suspenders — Ecto likely propagates the outer prefix into a same-`from`
correlated subquery, but the FACADE-04 integration test MUST assert the orphan-count
under `schema: "mailglass"` rather than assume). The outer execution still goes through
`Repo.all/one` which adds `prefix:`, so this is defensive only. The `not exists` inner
`from` uses the same `Event` schema and `parent_as(:orphan)` — the risk is the nested
`from` resolving under `public`; `put_query_prefix/2` bakes the prefix into the query
struct so it survives to the correlated subquery.

---

### `lib/mailglass/operator/replay_targets.ex` (read-model, raw string-source) — AUDIT (D-05)

**Analog:** `load_candidate/3` (l.99–116 and l.118–141) — two queries whose source is
the raw string `"mailglass_webhook_events"` (not an Ecto schema module):
```elixir
from(webhook_event in "mailglass_webhook_events",
  where: field(webhook_event, :id) == type(^webhook_event_id, Ecto.UUID),
  ...
)
```
Both execute via `Repo.one(Tenancy.scope(query, tenant_id))` (l.112, l.137) — **top-level
queryables**, so the facade's op-level `:prefix` covers them once `put_prefix/1` is wired
into `Repo.one/2`. **Audit conclusion for the planner:** verify these are NOT wrapped as
subqueries elsewhere (they are not — each is executed directly). No code change; document
in the plan that the audit confirmed top-level coverage. `fetch_delivery/2` (l.47) and
`fetch_delivery_events/2` (l.55) likewise run through `Repo.one`/`Repo.all` → covered.

---

### NEW schema-isolation integration test (test, integration round-trip) — FACADE-04

**Analog (near-copy):** `test/mailglass/shipped_migration_divergence_test.exs` — this is
the closest existing test that (a) creates a non-public schema with raw
`CREATE SCHEMA`, (b) runs a prefixed migration through `Ecto.Migrator`, (c) flips the
Sandbox to `:auto` for DDL, and (d) does write→read assertions scoped to `<prefix>.*`.
Copy its harness wholesale; change what it asserts.

**Harness pattern to copy (shipped_migration_divergence_test.exs l.44–85):**
```elixir
use ExUnit.Case, async: false           # DDL can't run in the Sandbox tx wrapper
@prefix "mailglass"                       # or a dedicated isolated schema name

setup do
  Ecto.Adapters.SQL.Sandbox.mode(TestRepo, :auto)          # DDL outside tx wrapper
  {:ok, _} = TestRepo.query("DROP SCHEMA IF EXISTS #{@prefix} CASCADE")
  {:ok, _} = TestRepo.query("CREATE SCHEMA #{@prefix}")     # footgun 13: schema BEFORE owner

  version = System.unique_integer([:positive, :monotonic]) + 90_000_000_000_000
  {:ok, _, _} =
    Ecto.Migrator.with_repo(TestRepo, fn repo ->
      Ecto.Migrator.up(repo, version, PrefixedWrapperMigration, log: false)
    end)

  on_exit(fn ->
    {:ok, _} = TestRepo.query("DROP SCHEMA IF EXISTS #{@prefix} CASCADE")
    {:ok, _} = TestRepo.query("DELETE FROM schema_migrations WHERE version = $1", [version])
    Ecto.Adapters.SQL.Sandbox.mode(TestRepo, :manual)       # restore for DataCase tests
  end)
  :ok
end
```

**Inline wrapper migration to copy (l.22–42):**
```elixir
defmodule PrefixedWrapperMigration do
  use Ecto.Migration
  @prefix "mailglass"
  def up do
    execute("SET LOCAL search_path TO #{@prefix}, public")   # binds v01's unqualified
    Mailglass.Migration.up(prefix: @prefix, repo: Mailglass.TestRepo)  # trigger to THIS schema
  end
  def down do
    execute("SET LOCAL search_path TO #{@prefix}, public")
    Mailglass.Migration.down(prefix: @prefix, repo: Mailglass.TestRepo)
  end
end
```

**Why the `SET LOCAL search_path` line is load-bearing (l.28–34 comment + dossier §3.6):**
v01's immutability trigger/function are created with a bare, non-prefix-qualified
`ON mailglass_events` (Phase 134/C fixes this — explicitly OUT OF SCOPE here). The
`search_path` pin makes that unqualified DDL bind to `<prefix>.mailglass_events`. This
is exactly why D-06 splits the full-suite-green-under-mailglass CI axis to Phase 134:
until C qualifies the raw DDL, only a search-path-pinned harness can stand the schema up.

**What the NEW test asserts (differs from the analog — CONTEXT `<specifics>`):**
1. Insert a Delivery + Events via the facade/Multi (`Mailglass.Events.append/1` and/or
   the `Outbound` Multi path) — round-trips into `<prefix>.mailglass_*`.
2. `SELECT count(*) FROM public.mailglass_events` (and deliveries/suppressions where
   present) == 0 — `public` holds none of the mailglass rows.
3. `SELECT count(*) FROM <prefix>.mailglass_events` > 0 — rows land under the prefix.
4. Operator reads (`Operator.SupportSummary.*` orphan-count, `Operator.*` list) resolve
   under the prefix — proves FACADE-01 reads + the `put_query_prefix/2` subquery.
5. `Tenancy.scope/2` still composes (WHERE + schema both apply) — dossier §3.9.

**Raw-count assertion idiom to copy (l.136–140, 147–160):**
```elixir
{:ok, %{rows: [[count]]}} =
  TestRepo.query("SELECT COUNT(*) FROM #{@prefix}.mailglass_events WHERE ...", [key])
assert count == 1
```

**Claude's discretion (CONTEXT):** schema creation in `test_helper.exs` suite setup vs.
the test module's own `setup` — footgun 13 only requires the schema exist BEFORE the
Sandbox owner starts for that test; the analog does it in the module's own `setup` with
Sandbox flipped to `:auto`, which is the recommended copy. Test file/module name is also
discretionary.

---

### `mailglass_admin/test/mailglass_admin/operator_live_test.exs` (test, write→read→render) — FACADE-03

**Analog:** the file's own existing render tests + fixture helpers. The zero-admin-change
proof adapts one dashboard-render test to boot against the schema-isolated DB and assert
the render succeeds unchanged.

**Existing write→read→render skeleton to reuse (l.214–288, helpers l.1056–1090):**
```elixir
test "selects a delivery and renders summary, timeline, ...", %{conn: conn} do
  conn = operator_conn(conn)
  delivery = insert_delivery!(recipient: "selected@example.com", ...)   # WRITE via TestRepo
  insert_event!(delivery, %{type: :delivered, ...})
  {:ok, view, _html} = live(conn, operator_path(%{"tenant_id" => @tenant_id, ...}))  # READ→RENDER
  html = render(view)
  assert html =~ delivery.recipient
end
```
Helpers `insert_delivery!/1` (l.1056), `insert_event!/2` (l.1076) write via
`TestRepo.insert!` / `Delivery.changeset`; the LiveView reads via the operator read-model
(facade). Making the WRITE and the subsequent RENDER round-trip through the prefixed
schema is the proof: a hidden facade-bypassing write (e.g. one landing in `public`) would
surface as an empty dashboard.

**Admin test harness (`mailglass_admin/test/support/live_view_case.ex`):** the Sandbox
owner starts in `setup` (l.34) via `MailglassAdmin.TestRepo` shared:true, and tenant is
stamped (l.38). To schema-isolate this test the planner mirrors the core integration
test's setup ordering — CREATE SCHEMA + prefixed migrate BEFORE the Sandbox owner starts
(footgun 13). **CONTEXT D-07:** exercise a write→read round-trip (not just a static
render); do NOT bump admin's `== <core>` pin (that's Phase 137).

---

## Shared Patterns

### The `:prefix` injection idiom (`Keyword.put_new`)
**Source:** dossier §3.2/§3.3 + CONTEXT `<specifics>`
**Apply to:** `repo.ex` (`put_prefix/1` + `multi_opts/1`), and every Multi builder in
`events.ex` / `outbound.ex` / `escalation.ex`.
```elixir
Keyword.put_new(opts, :prefix, Mailglass.Config.schema())
```
`put_new` (never `put`) so an explicit caller `:prefix` wins — matches Ecto's intentional
`:prefix` opt lever and the tests/advanced-adopter override path.

### `Config.schema/0` — the injected value
**Source:** `lib/mailglass/config.ex` l.666–679 (Phase 132)
**Apply to:** every threading site (facade + Multi builders + the two `put_query_prefix/2`
defensive spots).
```elixir
def schema do
  case :persistent_term.get(@schema_key, :__miss__) do
    :__miss__ -> warm_schema()   # self-heals: re-read + validate + cache
    schema -> schema
  end
end
```
O(1) persistent_term read on the hot path; boot-validated. NEVER use `@schema_prefix` on
a schema module (locked D-03; Phase 134 adds the guard).

### SQLSTATE-45A01 rescue — must stay untouched
**Source:** `lib/mailglass/repo.ex` l.180–190 (`translate_postgrex_error/2`)
**Apply to:** all `repo.ex` write wrappers being edited. `put_prefix/1` is a pure keyword
transform inside the delegate call — the `rescue err in Postgrex.Error` blocks in
`insert/2` (l.63), `update/2` (l.74), `delete/2` (l.85), `transact/2` (l.52), `multi/2`
(l.108) are unchanged.

### `{:unsafe_fragment, …}` conflict targets — schema-agnostic, leave verbatim
**Source:** `events.ex` l.179, `outbound.ex` l.559/l.582–583, `escalation.ex` l.27
**Apply to:** every builder that carries a conflict target. Column-only fragments are
schema-agnostic; the prefixed INSERT hits the right schema's index. Do NOT rewrite them.

### Schema-isolated integration harness (CREATE SCHEMA + prefixed migrate + Sandbox `:auto`)
**Source:** `test/mailglass/shipped_migration_divergence_test.exs` l.22–85
**Apply to:** the NEW FACADE-04 test and the adapted admin FACADE-03 test. Sandbox flips
to `:auto` for DDL, unique migration version per run + `on_exit` cleanup, `SET LOCAL
search_path` in the wrapper migration to bind v01's unqualified trigger to the prefix,
schema created BEFORE the Sandbox owner (footgun 13).

---

## No Analog Found

None. Every target file exists (MODIFY in place), and the one CREATE file has a
near-copy analog (`shipped_migration_divergence_test.exs`). No file requires falling
back to RESEARCH.md patterns (research was intentionally skipped; the LOCKED dossier
settles the design).

---

## Metadata

**Analog search scope:** `lib/mailglass/`, `lib/mailglass/operator/`,
`lib/mailglass/migrations/postgres/`, `test/mailglass/`, `test/support/`,
`mailglass_admin/test/`, `mailglass_admin/test/support/`.
**Files scanned:** repo.ex, events.ex, outbound.ex, suppression/escalation.ex,
support_summary.ex, replay_targets.ex, config.ex, data_case.ex, test_helper.exs,
persistence_integration_test.exs, repo_test.exs, repo_multi_test.exs,
shipped_migration_divergence_test.exs, operator_live_test.exs, live_view_case.ex,
SCHEMA-ISOLATION-DESIGN.md §3.2/§3.3/§3.4/§3.6/§5.
**Pattern extraction date:** 2026-07-02
