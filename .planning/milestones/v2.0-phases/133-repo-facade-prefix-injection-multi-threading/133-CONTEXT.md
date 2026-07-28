# Phase 133: Repo-facade prefix injection + Multi threading - Context

**Gathered:** 2026-07-02 (assumptions mode + code analysis)
**Status:** Ready for planning

<domain>
## Phase Boundary

**Design Phase B of v2.0 (Postgres Schema Isolation).** Wire the *core prefix-threading
mechanism* — the runtime `prefix:` injection at the `Mailglass.Repo` facade (the universal
choke point) and per-step into the `Ecto.Multi` builders — so that every mailglass read/write
(including admin's, which route through the facade) resolves to the `Config.schema/0` schema
with **zero admin code changes**.

- `put_prefix/1` (private) threaded through every delegated `Mailglass.Repo` read/write via
  `Keyword.put_new` (explicit caller `:prefix` wins).
- `multi_opts/1` (public, exported from `Mailglass.Repo`) threaded per-step into the three
  Multi builders: Events, Outbound, Suppression.Escalation.
- NO `@schema_prefix` anywhere; the value injected is `Mailglass.Config.schema/0` (shipped
  Phase 132, persistent_term-cached, boot-validated).

**Scope is fixed by ROADMAP §Phase 133 + the LOCKED dossier §5 Phase B.** Discussion here
clarifies HOW to build the four requirements, never WHETHER to add new capability.

**Requirements:** FACADE-01, FACADE-02, FACADE-03, FACADE-04.

**Depends on:** Phase 132 (the facade reads `Config.schema/0` + its `:persistent_term` cache).
**Out of scope (Phase 134/C):** `CREATE SCHEMA`, migration-entrypoint prefix injection, and
raw-DDL (trigger/function/CHECK) schema qualification. This boundary is load-bearing for the
FACADE-04 decision below (D-06).
</domain>

<decisions>
## Implementation Decisions

### Area 1 — `multi_opts/1` location + facade export surface (FACADE-01, FACADE-02)

- **D-01:** `multi_opts/1` becomes a **public** function in `Mailglass.Repo`
  (`def multi_opts(opts \\ []), do: Keyword.put_new(opts, :prefix, Mailglass.Config.schema())`),
  living alongside the existing public `multi/2`. **Do NOT create a new
  `Mailglass.Persistence` module.** `put_prefix/1` stays a **private** helper in
  `Mailglass.Repo`. Rationale: `repo.ex` is already the sole facade; `multi/2` is already
  exported precisely so `Outbound` can compose Multis, and its moduledoc states the facade
  "re-exports only what mailglass itself uses" / "`repo/0` is deliberately private to keep the
  facade narrow." Dossier §3.3 + §7 name `repo.ex` as the home. A separate module would
  fragment the facade and force a second alias/Boundary export on every Multi builder.

- **D-02:** Thread `put_prefix/1` through **every** delegated read/write:
  `insert/2`, `update/2`, `delete/2`, `one/2`, `all/2`, `get/3`, `aggregate/3`,
  `delete_all/2`. Use `Keyword.put_new` so an explicit caller-supplied `:prefix` (tests /
  advanced adopters) still wins. `query!/2` is **NOT** prefixed (facade can't rewrite arbitrary
  SQL; its two current callers run schema-agnostic `SET LOCAL` statements) — add a doc note that
  a future raw caller touching a mailglass table must qualify inline. `transact/2` and `multi/2`
  do not prefix at the executor (opts don't reach inner steps — that's what `multi_opts/1` is for).

- **D-03:** **NO `@schema_prefix` on any schema module** (locked dossier decision 6; the Phase
  134 grep/Credo guard enforces it, but this phase must not introduce one).

### Area 2 — Exact Multi-builder threading points (FACADE-02)

- **D-04:** Thread `multi_opts()` (or an equivalent `Keyword.put_new(:prefix, Config.schema())`)
  into exactly these builders — the single chokepoints, so both the standalone and Multi paths
  inherit it:
  - **Events:** merge into `Mailglass.Events.insert_opts/1` — the one place that builds the
    `on_conflict`/`conflict_target`/`returning` opts used by BOTH `append/1` and `append_multi/3`.
    Threading here covers the map-form insert and the function-form `repo.insert(cs, opts)` step.
  - **Outbound:** every `Ecto.Multi.insert(:delivery, …)`, `Ecto.Multi.insert_all(:deliveries,
    Delivery, rows, …)`, the inner `repo.insert_all(Event, …)`, and every `Ecto.Multi.update(
    :delivery, …)` step. `insert_all` takes the schema module, so the op-level `:prefix` routes it.
  - **Suppression.Escalation:** the `Repo.insert(cs, on_conflict:, conflict_target:, …)` and its
    Multi variant.
  - `{:unsafe_fragment, …}` conflict targets are **unchanged** (column-only → schema-agnostic; the
    prefixed INSERT hits the right schema's index).
  - **Why per-builder, not executor:** `Ecto.Multi` does NOT propagate the transaction/executor
    `opts` into inner step SQL (locked decision + dossier footgun 2). A missed step → half-isolated
    ledger inside one transaction that passes public-schema tests silently.

### Area 3 — Read-model (Operator.*) + subquery audit (FACADE-01, FACADE-04)

- **D-05:** **No operator code changes** for reads that execute a top-level queryable through the
  facade (`Repo.all/one/aggregate`) — the prefix is applied at execution and `Tenancy.scope/2`
  still composes (it transforms the `WHERE`; the facade adds the schema). **One defensive
  exception:** apply `Ecto.Query.put_query_prefix(query, Config.schema())` to the correlated
  `not exists(from(reconciled in Event, …))` subquery in
  `lib/mailglass/operator/support_summary.ex:~197` (belt-and-suspenders — Ecto likely propagates
  the outer prefix into a same-`from` correlated subquery, but the FACADE-04 integration test must
  ASSERT the orphan-count under `schema:"mailglass"` rather than assume it). Audit the remaining
  operators during planning; the two raw string-source queries in `replay_targets.ex` are
  top-level queryables → covered by the op-level `:prefix` (verify they aren't wrapped as subqueries).

### Area 4 — FACADE-04 verification vs. the A→B→C build order (FACADE-04) — **strategic decision**

- **D-06:** **Ship a dedicated schema-isolation integration test in Phase 133; defer the full
  CI matrix axis to Phase 134.** (User-selected fork — see DISCUSSION-LOG.)
  - The new integration test's OWN setup does `CREATE SCHEMA mailglass` + migrates the structural
    tables with `prefix: "mailglass"` (a **test-harness** concern, independent of the production
    migration path), then asserts an insert/read round-trip + operator/admin render land under
    `mailglass.*` while `public` holds none of the mailglass tables.
  - **The "full core suite green under BOTH `schema:"public"` and `schema:"mailglass"`" CI matrix
    axis is Phase 134's deliverable**, NOT 133's. Reason: `CREATE SCHEMA` and raw-DDL
    trigger/function/CHECK qualification are Phase 134 (C) — under `schema:"mailglass"` today Ecto
    auto-prefixes `create table`, but the immutability trigger/function are created unqualified, so
    the ledger-immutability tests would red-fail under mailglass until Phase C lands. Turning the
    whole suite green under mailglass would require pulling Phase C forward and breaking the locked
    A→B→C boundary.
  - **This adjusts roadmap §Phase 133 success criterion (4):** the "full core suite … under BOTH"
    clause moves to Phase 134; Phase 133's FACADE-04 is satisfied by the dedicated integration test
    (schema created + migrated + round-trip + `mailglass.*` present / `public` clean) plus the
    admin-render regression test (FACADE-03). Update the ROADMAP/REQUIREMENTS wording during
    planning to reflect this split.

### Area 5 — Admin zero-change proof + facade-bypass audit (FACADE-03)

- **D-07:** Prove FACADE-03 by adapting the existing admin dashboard-render test
  (`mailglass_admin/test/.../operator_live_test.exs`) to boot against the schema-isolated DB and
  assert the render succeeds **with zero admin code changes**. Make the test exercise a
  write→read round-trip (not just a static render) so a hidden facade-bypassing write would surface
  as an empty dashboard. Bump admin's `== <core>` pin to 2.0 is a Phase 137 release concern, not here.

- **D-08:** **No facade-bypassing runtime call-sites need threading.** Every runtime read/write in
  `lib/` routes through `Mailglass.Repo.*` (verified: Events, Outbound, Escalation,
  `SuppressionStore.Ecto`, all `operator/*`). The only direct-host-repo hits are in `migration.ex`
  (`resolve_repo().__adapter__()` / `Application.get_env(:mailglass, :repo)`) — correctly out of
  scope (Phase C). `SuppressionStore.Ecto` is verify-only (uses `Mailglass.Repo.one`/`insert`).

### Claude's Discretion
- Exact merge idiom inside `Events.insert_opts/1` (`Keyword.put_new` vs `Keyword.merge` with
  `multi_opts/0`) — planner's choice, keep the "explicit caller `:prefix` wins" precedence.
- Whether the dedicated FACADE-04 integration test creates the schema in `test_helper.exs` suite
  setup vs. in the test module's own `setup` — planner's choice; footgun 13 requires the schema to
  exist before the SQL Sandbox owner starts for that test.
- Exact file/module name for the new integration test.

### Folded Todos
None.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/research/milestone-schema-isolation/SCHEMA-ISOLATION-DESIGN.md` — the LOCKED design
  dossier. For this phase: §3.2 (`put_prefix/1` facade threading), §3.3 (`multi_opts/1` + the three
  Multi builders), §3.4 (Operator read-model + `put_query_prefix/2` for nested `from`), §3.8 (admin
  no-change + render regression test), §3.9 (tenancy orthogonality), §5 Phase B, §6 (footguns 2, 6,
  10, 13), §7 (diff surface — the exact files touched).
- `.planning/REQUIREMENTS.md` — FACADE-01..04 acceptance criteria (note D-06 splits criterion 4's
  full-matrix clause to Phase 134).
- `.planning/phases/132-config-mailglass-identifier-foundation/132-CONTEXT.md` — the `Config.schema/0`
  accessor contract this phase consumes.
- `lib/mailglass/repo.ex` — the facade to thread `put_prefix/1` through + export `multi_opts/1`.
- `lib/mailglass/config.ex` — `Mailglass.Config.schema/0` (persistent_term-cached, ~l.666).
- `lib/mailglass/events.ex` — `append_multi/3`, `insert_opts/1` (the events threading chokepoint).
- `lib/mailglass/outbound.ex` — `Ecto.Multi.insert`/`insert_all`/`update` + inner `repo.insert_all(Event,…)`.
- `lib/mailglass/suppression/escalation.ex` — `insert_suppression` insert + Multi variant.
- `lib/mailglass/operator/support_summary.ex` — the correlated `not exists` subquery (~l.197) needing
  defensive `put_query_prefix/2`; `lib/mailglass/operator/replay_targets.ex` (raw string sources — verify).
- `mailglass_admin/test/.../operator_live_test.exs` — the dashboard-render test to adapt for FACADE-03.
- `.github/workflows/advisory-matrix.yml` — "Core Full Suite Advisory" (the only full-core `mix test`
  lane); the schema matrix axis lands HERE in Phase 134, not 133.
- `test/support/data_case.ex` + `test/test_helper.exs` — Sandbox + `Ecto.Migrator.run` setup; the
  FACADE-04 integration test must create the `mailglass` schema before the Sandbox owner starts (footgun 13).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`Mailglass.Repo` facade** (`lib/mailglass/repo.ex`) — already the sole choke point with a private
  `repo/0` and a public `multi/2`; add `put_prefix/1` (private) + `multi_opts/1` (public) here.
- **`Mailglass.Config.schema/0`** (`config.ex:~666`) — Phase-132 persistent_term-cached, boot-validated
  accessor; the O(1) value injected on every delegated op.
- **`Events.insert_opts/1`** (`events.ex:~176`) — single opts chokepoint for both `append/1` and
  `append_multi/3`; thread prefix here once.
- **`operator_live_test.exs`** — existing admin dashboard-render test to adapt for FACADE-03.
- **SQL Sandbox harness** (`data_case.ex`, `test_helper.exs`) — reused; the FACADE-04 test extends it
  with a `CREATE SCHEMA` + prefixed migration in setup.

### Established Patterns
- `Keyword.put_new` for "explicit caller wins, else inject default" (matches Ecto's `:prefix` lever).
- The facade rescues `%Postgrex.Error{}` and translates SQLSTATE 45A01 — threading prefix must NOT
  disturb the existing `rescue`/`translate_postgrex_error` clauses.
- Multi builders live in domain modules (Events/Outbound/Escalation), so `multi_opts/1` must be public.

### Integration Points
- Facade prefix is consumed by ALL of: Events append, Outbound delivery/event writes, Escalation,
  `SuppressionStore.Ecto`, and every `Operator.*` read — one facade change covers them.
- `Tenancy.scope/2` composes orthogonally (WHERE vs schema) — the integration test must prove both apply.
- Phase 134 (migration entrypoint + raw-DDL qualification) DEPENDS on this facade being correct; the
  production `CREATE SCHEMA`/migration path is explicitly NOT built here (D-06 boundary).
</code_context>

<specifics>
## Specific Ideas

- Facade helpers (locked shape, dossier §3.2/§3.3):
  ```elixir
  # lib/mailglass/repo.ex
  @spec put_prefix(keyword()) :: keyword()
  defp put_prefix(opts), do: Keyword.put_new(opts, :prefix, Mailglass.Config.schema())

  @spec multi_opts(keyword()) :: keyword()
  def multi_opts(opts \\ []), do: Keyword.put_new(opts, :prefix, Mailglass.Config.schema())
  ```
- FACADE-04 integration test skeleton: `setup` → `CREATE SCHEMA mailglass` (raw) + `Ecto.Migrator.run(
  repo, path, :up, all: true, prefix: "mailglass")` before Sandbox owner → insert Delivery+Events Multi
  → assert rows in `mailglass.*` and `SELECT count(*) FROM public.mailglass_*` (where present) is 0 →
  assert `Operator.*` reads + `support_summary` orphan-count resolve under the prefix.
- Verification for this phase = facade unit tests (explicit-`:prefix`-wins + default injection) +
  the dedicated schema-isolation integration test + the admin-render regression test + `mix credo`.
</specifics>

<deferred>
## Deferred Ideas

- **Full CI matrix axis** (`schema: [public, mailglass]` on "Core Full Suite Advisory") + the whole
  core suite green under BOTH schemas → **Phase 134** (blocked on raw-DDL trigger/function/CHECK
  qualification + `CREATE SCHEMA` in the production migration path). D-06.
- `CREATE SCHEMA`/`DROP SCHEMA` in the production migration entrypoint + `create_schema: false` escape
  hatch → Phase 134 (MIGR-*).
- Grep/Credo guard that no schema declares `@schema_prefix` → Phase 134 (MIGR-06).
- Inbound facade threading + migration-dispatcher conversion → Phase 135 (INB-*).

### Reviewed Todos (not folded)
None matched this phase's scope.
</deferred>
