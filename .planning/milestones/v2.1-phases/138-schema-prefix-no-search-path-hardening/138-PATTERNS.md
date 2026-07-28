# Phase 138: Schema-prefix no-search-path hardening - Pattern Map

**Mapped:** 2026-07-07
**Files analyzed:** 14 new/modified files
**Analogs found:** 14 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/mailglass/webhook/replay.ex` | service | event-driven CRUD | `lib/mailglass/webhook/ingest.ex` | exact for raw Multi callback projection update |
| `lib/mailglass/compliance/unsubscribe_controller.ex` | controller | request-response CRUD | `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex` + `lib/mailglass/repo.ex` | partial; no exact core `repo.one!/2` callback analog |
| `lib/mailglass/adapters/fake.ex` | adapter/service | event-driven CRUD | `lib/mailglass/outbound.ex` | exact for `Ecto.Multi.update/4` opts |
| `lib/mailglass/webhook/reconciler.ex` | service/worker | batch event-driven CRUD | `lib/mailglass/outbound.ex` | exact for `Ecto.Multi.update/4` opts |
| `mailglass_inbound/lib/mailglass_inbound/internal/replay.ex` | service | CRUD request-response | `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex` | exact for raw `repo.one(query, schema_opts())` |
| `mailglass_inbound/lib/mailglass_inbound/execution.ex` | service | event-driven CRUD | `mailglass_inbound/lib/mailglass_inbound/repo.ex` + `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex` | role-match |
| `mailglass_inbound/lib/mix/tasks/mailglass.inbound.replay.ex` | utility/CLI task | batch CRUD | `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex` | role-match for supplied raw repo opts |
| `credo_checks/raw_repo_prefix_contract.ex` | utility/static guard | transform | `credo_checks/no_unscoped_tenant_query_in_lib.ex` | role-match AST guard |
| `test/mailglass/schema_prefix_hardening_test.exs` | test | event-driven CRUD | `test/mailglass/schema_isolation_immutability_test.exs` + existing replay/unsubscribe tests | role-match; no exact replay hostile-path test |
| `test/mailglass/credo/raw_repo_prefix_contract_test.exs` | test | transform | `test/mailglass/credo/no_schema_prefix_attribute_test.exs` | exact custom Credo test style |
| `mailglass_inbound/test/mailglass_inbound/schema_prefix_contract_test.exs` | test | CRUD request-response | `mailglass_inbound/test/mailglass_inbound/repo_prefix_test.exs` | exact prefix-contract test style |
| `mix.exs` | config | batch | existing `verify.*` aliases in `mix.exs` | exact |
| `.credo.exs` | config | transform | existing `extra_checks` registration in `.credo.exs` | exact |
| `.github/workflows/advisory-matrix.yml` | config | batch | existing advisory schema comments in `.github/workflows/advisory-matrix.yml` | role-match |

## Pattern Assignments

### `lib/mailglass/webhook/replay.ex` (service, event-driven CRUD)

**Analog:** `lib/mailglass/webhook/ingest.ex`

**Imports/current target pattern** (`lib/mailglass/webhook/replay.ex` lines 6-12):

```elixir
import Ecto.Query

alias Ecto.Multi
alias Mailglass.{Clock, Events, IdempotencyKey, Repo, Tenancy}
alias Mailglass.Events.Event
alias Mailglass.Outbound.{Delivery, Projector}
alias Mailglass.Webhook.WebhookEvent
```

**Target gap** (`lib/mailglass/webhook/replay.ex` lines 305-309):

```elixir
|> Multi.run({:projector_apply, idx}, fn repo, changes ->
  case Map.get(changes, {:projector_categorize, idx}) do
    {:matched, delivery, inserted_event} ->
      case repo.update(Projector.update_projections(delivery, inserted_event)) do
        {:ok, _delivery} -> {:ok, {:matched, delivery, inserted_event}}
```

**Copy this raw callback update pattern** (`lib/mailglass/webhook/ingest.ex` lines 314-325):

```elixir
Multi.run(acc, {:projector_apply, idx}, fn repo, changes ->
  case Map.get(changes, {:projector_categorize, idx}) do
    {:matched, delivery, inserted_event} ->
      changeset = Projector.update_projections(delivery, inserted_event)

      # v2.0 FACADE-01: `repo` is the raw Ecto.Multi callback repo (the
      # host Repo), NOT the Mailglass.Repo facade -- it does NOT inject
      # prefix. Thread prefix: Config.schema() via Repo.multi_opts/0 so
      # the projection UPDATE routes to the isolated schema's
      # mailglass_deliveries row.
      case repo.update(changeset, Repo.multi_opts()) do
```

**Prefix helper source** (`lib/mailglass/repo.ex` lines 130-151):

```elixir
@doc """
Returns opts with `prefix: Mailglass.Config.schema()` injected via
`Keyword.put_new`, for use as the step-level opts in `Ecto.Multi` builders
in domain modules (Events, Outbound, Suppression.Escalation).

`Ecto.Multi` does NOT propagate the transaction/executor opts into inner
step SQL. Every builder step that writes a mailglass table must carry its
own `:prefix`; call `multi_opts/1` (or `multi_opts()`) to build that opts
list rather than constructing it by hand.
"""
@doc since: "2.0.0"
@spec multi_opts(keyword()) :: keyword()
def multi_opts(opts \\ []), do: Keyword.put_new(opts, :prefix, Mailglass.Config.schema())
```

**Planner action:** Change replay projection `repo.update(...)` to `repo.update(changeset, Repo.multi_opts())`, keeping the existing `Repo.one(Tenancy.scope(...))` facade read at lines 293-300.

---

### `lib/mailglass/compliance/unsubscribe_controller.ex` (controller, request-response CRUD)

**Analog:** `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex` plus `lib/mailglass/repo.ex`

**Imports/current target pattern** (`lib/mailglass/compliance/unsubscribe_controller.ex` lines 9-22):

```elixir
use Phoenix.Controller, formats: [:html]

import Ecto.Query
import Plug.Conn

alias Mailglass.Compliance
alias Mailglass.Compliance.Unsubscribe
alias Mailglass.Compliance.UnsubscribeHTML
alias Mailglass.Events
alias Mailglass.Events.Event
alias Mailglass.Outbound.Delivery
alias Mailglass.Outbound.Projector
alias Mailglass.Repo
alias Mailglass.Tenancy
```

**Target gap** (`lib/mailglass/compliance/unsubscribe_controller.ex` lines 120-129):

```elixir
defp canonical_event(repo, %Event{inserted_at: nil}, %Delivery{} = delivery) do
  repo.one!(
    from(event in Event,
      where:
        event.delivery_id == ^delivery.id and
          event.type == :unsubscribed and
          event.idempotency_key == ^unsubscribe_idempotency_key(delivery),
      limit: 1
    )
  )
end
```

**Raw repo read-with-opts analog** (`mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex` lines 12-17, 271-281):

```elixir
# Returns the schema-prefix option that must be passed to all direct repo
# calls (insert, one, all) so they route to the configured Postgres schema
# This mirrors what `MailglassInbound.Repo.put_prefix/1`
# does for facade calls -- callers that pass an explicit `:prefix` override
# this via Ecto's `Keyword.put_new` / option-merge semantics (caller wins).
defp schema_opts, do: [prefix: MailglassInbound.Config.schema()]

defp load_by_provider_message_id(repo, tenant_id, provider, provider_message_id) do
  query =
    from(record in InboundRecord,
      where:
        record.tenant_id == ^tenant_id and
          record.provider == ^provider and
          record.provider_message_id == ^provider_message_id,
      limit: 1
    )

  repo.one(query, schema_opts())
end
```

**Core opts helper to use instead of inbound `schema_opts/0`** (`lib/mailglass/repo.ex` line 151):

```elixir
def multi_opts(opts \\ []), do: Keyword.put_new(opts, :prefix, Mailglass.Config.schema())
```

**Existing behavior test to preserve** (`test/mailglass/compliance/unsubscribe_controller_test.exs` lines 228-246):

```elixir
test "replayed POST returns 200 without duplicating durable state", %{conn: conn} do
  delivery = Generators.delivery_fixture()
  token = Unsubscribe.sign_token(delivery.id)

  first = post(conn, "/mailglass/unsubscribe/#{token}", %{})
  second = post(build_conn(), "/mailglass/unsubscribe/#{token}", %{})

  assert response(first, 200) == ""
  assert response(second, 200) == ""

  count =
    TestRepo.aggregate(
      from(event in Event,
        where: event.delivery_id == ^delivery.id and event.type == :unsubscribed
      ),
      :count
    )

  assert count == 1
end
```

**Planner action:** Keep `repo` inside the transaction callback, but pass explicit opts: `repo.one!(query, Repo.multi_opts())`. No exact existing core `repo.one!/2` callback analog exists; copy the inbound raw read-with-opts shape and the core `Repo.multi_opts/1` helper.

---

### `lib/mailglass/adapters/fake.ex` (adapter/service, event-driven CRUD)

**Analog:** `lib/mailglass/outbound.ex`

**Target gap** (`lib/mailglass/adapters/fake.ex` lines 174-180):

```elixir
result =
  Ecto.Multi.new()
  |> Mailglass.Events.append_multi(:event, attrs)
  |> Ecto.Multi.update(:delivery, fn %{event: event} ->
    Projector.update_projections(delivery, event)
  end)
  |> Mailglass.Repo.multi()
```

**Copy this `Ecto.Multi.update/4` opts pattern** (`lib/mailglass/outbound.ex` lines 781-793):

```elixir
Repo.multi(
  Ecto.Multi.new()
  |> Ecto.Multi.update(
    :delivery,
    Projector.update_projections(delivery, event_for_projection)
    |> Ecto.Changeset.change(%{
      status: :sent,
      last_event_type: :dispatched,
      provider_message_id: pmid,
      dispatched_at: event_occurred_at
    }),
    Repo.multi_opts()
  )
```

**Planner action:** Convert the fake adapter update to 4-arity `Ecto.Multi.update(:delivery, fn ... end, Mailglass.Repo.multi_opts())`.

---

### `lib/mailglass/webhook/reconciler.ex` (service/worker, batch event-driven CRUD)

**Analog:** `lib/mailglass/outbound.ex`

**Target gaps** (`lib/mailglass/webhook/reconciler.ex` lines 174-181 and 346-353):

```elixir
multi =
  Multi.new()
  |> Events.append_multi(:reconciled_event, reconciled_attrs)
  |> Multi.update(:projection, fn _changes ->
    Projector.update_projections(delivery, orphan)
  end)

case Repo.transact(fn -> Repo.multi(multi) end) do
```

**Copy this operation opts pattern** (`lib/mailglass/outbound.ex` lines 812-822):

```elixir
Repo.multi(
  Ecto.Multi.new()
  |> Ecto.Multi.update(
    :delivery,
    Projector.update_projections(delivery, event)
    |> Ecto.Changeset.change(%{
      status: :failed,
      last_error: serialize_error(err)
    }),
    Repo.multi_opts()
  )
```

**Planner action:** Add `Repo.multi_opts()` as the fourth argument for both reconciler projection updates. Preserve append-only event semantics; do not update the orphan event.

---

### `mailglass_inbound/lib/mailglass_inbound/internal/replay.ex` (service, CRUD request-response)

**Analog:** `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex`

**Current target pattern** (`mailglass_inbound/lib/mailglass_inbound/internal/replay.ex` lines 23-31):

```elixir
def replay(inbound_record_id, opts \\ []) when is_binary(inbound_record_id) and is_list(opts) do
  repo = Keyword.get(opts, :repo, MailglassInbound.Repo)
  execution = Keyword.get(opts, :execution, Execution)
  tenant_id = require_tenant!(opts)

  with %InboundRecord{} = record <- load_record(repo, inbound_record_id, tenant_id),
       %InboundEvidence{} = evidence <- load_evidence(repo, inbound_record_id, tenant_id),
       {:ok, mailbox} <- resolve_mailbox(repo, inbound_record_id, tenant_id),
       payload = replay_payload(record, evidence, mailbox),
```

**Target gaps** (`mailglass_inbound/lib/mailglass_inbound/internal/replay.ex` lines 52-69, 91-116):

```elixir
|> Tenancy.scope(tenant_id)
|> repo.one()
```

**Copy this local opts helper and raw repo call shape** (`mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex` lines 12-17, 163):

```elixir
defp schema_opts, do: [prefix: MailglassInbound.Config.schema()]

repo.one(query, schema_opts())
```

**Default facade contract** (`mailglass_inbound/lib/mailglass_inbound/repo.ex` lines 8-18):

```elixir
Every delegated read/write injects `prefix: MailglassInbound.Config.schema()` via
`Keyword.put_new`, routing all operations to the configured Postgres schema
(`"mailglass"` by default, `"public"` for pre-2.0 opt-out). An explicit
caller-supplied `:prefix` wins over the injected default (INB-01).

`transact/2` and `multi/2` do NOT inject prefix. The inner `insert/2`, `one/2`,
`all/2`, and `get/3` calls inside a transaction carry their own prefix via the
facade.
```

**Planner action:** Add local `schema_opts/0` and pass it to every `repo.one` in `Internal.Replay`, or route only through the facade and remove raw repo extension if acceptable. Since the public extension point already accepts `repo:`, explicit opts are the lower-risk phase change.

---

### `mailglass_inbound/lib/mailglass_inbound/execution.ex` (service, event-driven CRUD)

**Analog:** `mailglass_inbound/lib/mailglass_inbound/repo.ex` plus `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex`

**Target gap** (`mailglass_inbound/lib/mailglass_inbound/execution.ex` lines 77-81):

```elixir
repo = Keyword.get(opts, :repo, Repo)

with %InboundRecord{} = record <- repo.get(InboundRecord, inbound_record_id),
     %InboundEvidence{} = evidence <- repo.get(InboundEvidence, inbound_evidence_id),
     {:ok, route} <- decode_route(route_status, Map.get(job_args, "mailbox")) do
```

**Facade get pattern** (`mailglass_inbound/lib/mailglass_inbound/repo.ex` lines 45-46):

```elixir
@spec get(Ecto.Queryable.t(), term(), keyword()) :: struct() | nil
def get(queryable, id, opts \\ []), do: repo().get(queryable, id, put_prefix(opts))
```

**Raw repo option pattern to copy** (`mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex` lines 12-17):

```elixir
defp schema_opts, do: [prefix: MailglassInbound.Config.schema()]
```

**Planner action:** For a supplied raw `repo:`, call `repo.get(Schema, id, schema_opts())`. This keeps default facade behavior safe while making the raw-repo contract explicit.

---

### `mailglass_inbound/lib/mix/tasks/mailglass.inbound.replay.ex` (utility/CLI task, batch CRUD)

**Analog:** `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex`

**Target gap** (`mailglass_inbound/lib/mix/tasks/mailglass.inbound.replay.ex` lines 63-68, 136-145):

```elixir
repo = Keyword.get(runtime_opts, :repo, MailglassInbound.Repo)
replay = Keyword.get(runtime_opts, :replay, Replay)

selectors = parse_selectors!(opts)
ids = resolve_ids(repo, selectors)
```

```elixir
defp resolve_ids(repo, selectors) do
  InboundRecord
  |> filter_record_id(selectors.record_id)
  |> filter_tenant(selectors.tenant)
  |> filter_since(selectors.since)
  |> select([r], r.id)
  |> repo.all()
end
```

**Copy this inbound raw repo opts pattern** (`mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex` lines 12-17):

```elixir
defp schema_opts, do: [prefix: MailglassInbound.Config.schema()]
```

**Existing selector test pattern** (`mailglass_inbound/test/mix/tasks/mailglass_inbound_replay_test.exs` lines 48-78):

```elixir
describe "selector resolution" do
  test "--tenant scopes the id set; --yes skips the prompt" do
    {:ok, a1} = insert_record("tenant-a")
    {:ok, _a2} = insert_record("tenant-a")
    {:ok, _b1} = insert_record("tenant-b")

    run(["--tenant", "tenant-a", "--yes"])

    replayed = Process.get(:stub_replay_ids, [])
    assert length(replayed) == 2
    assert a1.id in replayed
  end
```

**Planner action:** Add local `schema_opts/0` and call `repo.all(schema_opts())` in `resolve_ids/2`; extend mix-task tests or the new inbound contract test with a capture repo that asserts `opts[:prefix]`.

---

### `credo_checks/raw_repo_prefix_contract.ex` (utility/static guard, transform)

**Analog:** `credo_checks/no_unscoped_tenant_query_in_lib.ex`

**Copy this custom check skeleton** (`credo_checks/no_schema_prefix_attribute.ex` lines 1-7, 27-44):

```elixir
defmodule Mailglass.Credo.NoSchemaPrefixAttribute do
  use Credo.Check,
    category: :warning,
    base_priority: :high,
    param_defaults: [
      included_path_prefixes: ["lib/mailglass/"]
    ],

  @impl true
  def run(%SourceFile{} = source_file, params \\ []) do
    included_path_prefixes = Params.get(params, :included_path_prefixes, __MODULE__)

    if included_path?(source_file, included_path_prefixes) do
      issue_meta = IssueMeta.for(source_file, params)
      ast = SourceFile.ast(source_file)
```

**Copy this repo-call AST matching pattern** (`credo_checks/no_unscoped_tenant_query_in_lib.ex` lines 125-176):

```elixir
defp collect_repo_calls(body, schema_tail_names, repo_functions, scope_module_tail) do
  {_ast, calls} =
    Macro.prewalk(body, [], fn
      {:|>, meta, [lhs, {{:., _, [repo_module_ast, function_name]}, _, rhs_args}]} = node,
      calls ->
        args = [lhs | List.wrap(rhs_args)]

        {node,
         maybe_collect_call(
           calls,
           meta,
           repo_module_ast,
           function_name,
           args,
           schema_tail_names,
           repo_functions,
           scope_module_tail
         )}

      {{:., _, [repo_module_ast, function_name]}, meta, args} = node, calls ->
        {node,
         maybe_collect_call(
           calls,
           meta,
           repo_module_ast,
           function_name,
           args,
           schema_tail_names,
           repo_functions,
           scope_module_tail
         )}
```

**Copy issue formatting style** (`credo_checks/no_unscoped_tenant_query_in_lib.ex` lines 316-324):

```elixir
defp issue_for(issue_meta, line_no, column, function_name) do
  format_issue(
    issue_meta,
    message:
      "Repo.#{function_name} on a tenanted schema must pass through `Mailglass.Tenancy.scope/2` or use `scope: :unscoped` with a companion tenant-bypass audit telemetry helper call.",
    trigger: "Repo.#{function_name}",
    line_no: line_no,
    column: column
  )
end
```

**Planner action:** Build a path-scoped AST guard for production paths that flags raw `repo.one`, `repo.one!`, `repo.get`, `repo.get!`, `repo.all`, `repo.update`, `repo.insert`, `repo.delete_all`, and `Ecto.Multi.update`/`update_all` calls touching mailglass tables unless they pass `Repo.multi_opts()`, an inbound `schema_opts()`, explicit `prefix:`, or a documented allowlist. Scope carefully to avoid migrations, tests, and schema-agnostic SQL.

---

### `test/mailglass/schema_prefix_hardening_test.exs` (test, event-driven CRUD)

**Analogs:** `test/mailglass/schema_isolation_immutability_test.exs`, `test/mailglass/webhook/replay_test.exs`, `test/mailglass/compliance/unsubscribe_controller_test.exs`

**Schema setup/reset pattern** (`test/mailglass/schema_isolation_immutability_test.exs` lines 40-63):

```elixir
setup do
  original_schema = Application.get_env(:mailglass, :schema)
  Application.put_env(:mailglass, :schema, @prefix)
  :persistent_term.erase({Mailglass.Config, :schema})

  Ecto.Adapters.SQL.Sandbox.mode(TestRepo, :auto)

  {:ok, _} = TestRepo.query("DROP SCHEMA IF EXISTS #{@prefix} CASCADE")

  version = System.unique_integer([:positive, :monotonic]) + 90_000_000_000_000

  {:ok, _, _} =
    Ecto.Migrator.with_repo(TestRepo, fn repo ->
      Ecto.Migrator.up(repo, version, PrefixedWrapperMigration, log: false)
    end)
```

**Teardown pattern** (`test/mailglass/schema_isolation_immutability_test.exs` lines 65-90):

```elixir
on_exit(fn ->
  {:ok, _} = TestRepo.query("DROP SCHEMA IF EXISTS #{@prefix} CASCADE")

  {:ok, _} =
    TestRepo.query("DELETE FROM schema_migrations WHERE version = $1", [version])

  if original_schema do
    Application.put_env(:mailglass, :schema, original_schema)
  else
    Application.delete_env(:mailglass, :schema)
  end

  :persistent_term.erase({Mailglass.Config, :schema})
  restore_suite_baseline_schema()
  Ecto.Adapters.SQL.Sandbox.mode(TestRepo, :manual)
end)
```

**Replay behavior fixture shape** (`test/mailglass/webhook/replay_test.exs` lines 25-39):

```elixir
assert {:ok, result} =
         Replay.execute(%{
           tenant_id: "test-tenant",
           webhook_event_id: webhook_event.id,
           delivery_id: delivery.id,
           actor: %{subject_id: "operator-1"}
         })

assert result.status == :replayed
assert result.delivery_id == delivery.id
assert result.replayed_event_count == 1
assert result.new_event_count == 1
assert result.orphan_event_count == 0
```

**Unsubscribe idempotency behavior shape** (`test/mailglass/compliance/unsubscribe_controller_test.exs` lines 232-246):

```elixir
first = post(conn, "/mailglass/unsubscribe/#{token}", %{})
second = post(build_conn(), "/mailglass/unsubscribe/#{token}", %{})

assert response(first, 200) == ""
assert response(second, 200) == ""

count =
  TestRepo.aggregate(
    from(event in Event,
      where: event.delivery_id == ^delivery.id and event.type == :unsubscribed
    ),
    :count
  )

assert count == 1
```

**Do not copy this canary crutch as proof** (`test/test_helper.exs` lines 57-65):

```elixir
# search_path is "<schema>, public": unqualified DDL/queries resolve to the
# isolated schema first, but the `citext` extension type (installed in public)
# stays resolvable.
migration_parameters =
  if schema != "public" do
    test_repo_config
    |> Keyword.get(:parameters, [])
    |> Keyword.put(:search_path, "#{schema}, public")
```

**Planner action:** New tests must explicitly exclude the configured schema from the active connection path before executing `Webhook.Replay` and unsubscribe replay. No existing test proves these runtime paths under hostile `search_path`; combine the schema setup/teardown above with new `SET search_path TO public` style setup and prefixed row assertions.

---

### `test/mailglass/credo/raw_repo_prefix_contract_test.exs` (test, transform)

**Analog:** `test/mailglass/credo/no_schema_prefix_attribute_test.exs`

**Copy this Credo test skeleton** (`test/mailglass/credo/no_schema_prefix_attribute_test.exs` lines 1-10, 52-56):

```elixir
defmodule Mailglass.Credo.NoSchemaPrefixAttributeTest do
  use ExUnit.Case, async: true

  alias Credo.SourceFile
  alias Mailglass.Credo.NoSchemaPrefixAttribute

  setup_all do
    {:ok, _apps} = Application.ensure_all_started(:credo)
    :ok
  end

  defp run_check(source, filename) do
    source
    |> SourceFile.parse(filename)
    |> NoSchemaPrefixAttribute.run([])
  end
end
```

**Copy path-scope assertion style** (`test/mailglass/credo/no_unscoped_tenant_query_in_lib_test.exs` lines 143-156):

```elixir
test "ignores files outside lib/mailglass path scope" do
  source = """
  defmodule Mailglass.Fixture.BadTenantScope do
    import Ecto.Query
    alias Mailglass.Outbound.Delivery
    alias Mailglass.Repo

    def list do
      Repo.all(from(d in Delivery))
    end
  end
  """

  assert run_check(source, "test/support/no_unscoped_tenant_query_fixture.exs") == []
end
```

**Meta-guard that will require this test and `.credo.exs` registration** (`test/mailglass/credo/checks_have_tests_test.exs` lines 17-31, 34-48):

```elixir
test "every custom Credo check has a matching regression test" do
  missing =
    "credo_checks/*.ex"
    |> Path.wildcard()
    |> Enum.map(fn check_path ->
      base = Path.basename(check_path, ".ex")
      {check_path, "test/mailglass/credo/#{base}_test.exs"}
    end)
    |> Enum.reject(fn {_check_path, test_path} -> File.exists?(test_path) end)

  assert missing == [],
         "Custom Credo checks missing a regression test:\n" <>
           Enum.map_join(missing, "\n", fn {check_path, test_path} ->
             "  #{check_path} -> expected #{test_path}"
           end)
end
```

**Planner action:** Test at least: bad raw callback repo call is flagged; `repo.update(changeset, Repo.multi_opts())` is allowed; inbound `repo.one(query, schema_opts())` is allowed; facade calls are allowed; tests/migrations/known schema-agnostic SQL are ignored.

---

### `mailglass_inbound/test/mailglass_inbound/schema_prefix_contract_test.exs` (test, CRUD request-response)

**Analog:** `mailglass_inbound/test/mailglass_inbound/repo_prefix_test.exs`

**Copy env/cache reset pattern** (`mailglass_inbound/test/mailglass_inbound/repo_prefix_test.exs` lines 36-48):

```elixir
setup do
  prior_schema = Application.fetch_env(:mailglass_inbound, :schema)

  on_exit(fn ->
    :persistent_term.erase(@schema_key)

    case prior_schema do
      {:ok, value} -> Application.put_env(:mailglass_inbound, :schema, value)
      :error -> Application.delete_env(:mailglass_inbound, :schema)
    end
  end)

  :ok
end
```

**Copy capture repo pattern** (`mailglass_inbound/test/mailglass_inbound/repo_prefix_test.exs` lines 59-90):

```elixir
defmodule CaptureRepo do
  @moduledoc false
  def insert(_changeset_or_struct, opts) do
    Process.put(:captured_opts, opts)
    {:ok, %{}}
  end

  def one(_queryable, opts) do
    Process.put(:captured_opts, opts)
    nil
  end

  def all(_queryable, opts) do
    Process.put(:captured_opts, opts)
    []
  end

  def get(_queryable, _id, opts) do
    Process.put(:captured_opts, opts)
    nil
  end
end
```

**Copy option assertion pattern** (`mailglass_inbound/test/mailglass_inbound/repo_prefix_test.exs` lines 120-140):

```elixir
test "one/2 with no opts injects prefix: Config.schema()" do
  with_capture_repo("mg_test", fn ->
    MailglassInbound.Repo.one(nil, [])
    opts = Process.get(:captured_opts)
    assert Keyword.get(opts, :prefix) == Config.schema()
  end)
end

test "get/3 with no opts injects prefix: Config.schema()" do
  with_capture_repo("mg_test", fn ->
    MailglassInbound.Repo.get(nil, "some-id", [])
    opts = Process.get(:captured_opts)
    assert Keyword.get(opts, :prefix) == Config.schema()
  end)
end
```

**Planner action:** Use capture repos to assert `Internal.Replay`, `Execution.load`, and mix-task selector resolution pass `prefix: MailglassInbound.Config.schema()` when a raw repo is supplied. Add real DB hostile-path coverage only if needed for confidence; the capture test is the closest exact local pattern.

---

### `mix.exs` (config, batch)

**Analog:** existing semantic verify aliases in `mix.exs`

**Preferred env pattern** (`mix.exs` lines 54-83):

```elixir
def cli do
  [
    preferred_envs: [
      # Local<->CI parity aliases (CICD milestone)
      ci: :test,
      "ci.fast": :test,
      "ci.setup": :test,
      "ci.browser": :test,
      # Semantic verify aliases (REL-03)
      "verify.foundation": :test,
      "verify.persistence": :test,
      "verify.send_pipeline": :test,
      "verify.webhooks": :test,
      "verify.installer": :test,
      "verify.mix_tasks": :test,
      "verify.reference_host.journey": :test,
      "verify.demo_browser_evidence": :test,
      "verify.phase69": :test,
      "verify.phase67": :test,
      "verify.cold_start": :test,
      "verify.installer.golden": :test,
      "verify.installer.idempotency": :test,
      "verify.installer.smoke": :test,
      "verify.support_contract.core": :test,
      "verify.stability_contract": :test,
      "verify.provider_compatibility": :test,
      "verify.docs.contract": :test,
      "verify.docs.contract.inbound": :test,
      "verify.docs.migration": :test
    ]
  ]
end
```

**Alias list pattern** (`mix.exs` lines 199-208, 288-297):

```elixir
defp aliases do
  [
    # --- Semantic verify aliases (REL-03) ---

    # Phase 1: foundation -- no-optional-deps compile + full test suite + Credo strict.
    "verify.foundation": [
      "compile --no-optional-deps --warnings-as-errors",
      "test --warnings-as-errors",
      "credo --strict"
    ],

    "verify.support_contract.core": [
      "test test/mailglass/docs_contract_test.exs test/mailglass/docs/testing_guide_test.exs test/mailglass/stability_contract_test.exs test/mailglass/compatibility_contract_test.exs test/mailglass/docs_migration_smoke_test.exs test/mailglass/docs/operator_incident_support_guide_test.exs test/mailglass/operator/support_summary_test.exs test/mailglass/webhook/telemetry_test.exs test/mailglass/telemetry_test.exs test/mailglass/webhook/replay_test.exs test/mailglass/webhook/reconciler_test.exs --warnings-as-errors"
    ],
```

**Planner action:** Add `"verify.schema_prefix": :test` under `preferred_envs` and a semantic alias near the other `verify.*` entries. Expected commands: focused core hostile test, custom Credo guard test, `credo --strict`, and inbound focused contract test via `cmd --cd mailglass_inbound mix test test/mailglass_inbound/schema_prefix_contract_test.exs --warnings-as-errors`.

---

### `.credo.exs` (config, transform)

**Analog:** existing `extra_checks` registration and glob loading

**Registration pattern** (`.credo.exs` lines 1-20):

```elixir
extra_checks = [
  {Mailglass.Credo.NoRawSwooshSendInLib,
   [
     allowed_modules: [Mailglass.Adapters.Swoosh]
   ]},
  {Mailglass.Credo.NoPiiInTelemetryMeta,
   [
     blocked_keys: ~w(to from cc bcc body html_body text_body subject headers recipient email)a
   ]},
  {Mailglass.Credo.NoUnscopedTenantQueryInLib,
   [
     tenanted_schemas: [
       Mailglass.Outbound.Delivery,
       Mailglass.Events.Event,
       Mailglass.Suppression.Entry,
       Mailglass.Webhook.WebhookEvent
     ],
```

**Requires/checks pattern** (`.credo.exs` lines 155-168):

```elixir
name: "default",
strict: true,
files: %{
  included: ["lib/", "test/", "mailglass_inbound/lib/", "mailglass_inbound/test/"],
  excluded: []
},
requires: ["./credo_checks/*.ex"],
checks:
  extra_checks ++
    [
```

**Planner action:** Add `{Mailglass.Credo.RawRepoPrefixContract, [...]}` to `extra_checks`. The meta-test will fail if the module exists but is not registered.

---

### `.github/workflows/advisory-matrix.yml` (config, batch)

**Analog:** existing advisory schema comments

**Core canary wording to preserve/extend** (`.github/workflows/advisory-matrix.yml` lines 87-106):

```yaml
- name: Run advisory full suite
  # Runs the complete core `lib/` test suite (the ~120 core test files no
  # required lane covers -- only the narrow verify.support_contract.core /
  # provider-compat file lists run as required checks).
  #
  # MAILGLASS_SCHEMA (D-06): config/runtime.exs reads this in the :test env
  # to override `config :mailglass, :schema`, so the whole suite runs under
  # the matrix schema (public or mailglass). The `--exclude requires_workspace`
  # flag is preserved unchanged.
  env:
    MAILGLASS_SCHEMA: ${{ matrix.schema }}
  run: mix test --warnings-as-errors --exclude requires_workspace
```

**Inbound canary caveat** (`.github/workflows/advisory-matrix.yml` lines 314-318):

```yaml
- name: Run inbound dual-schema advisory full suite
  # MAILGLASS_SCHEMA (D-12 / INB-03): test_helper.exs reads this env var
  # to align BOTH Migration.up(prefix:) AND Config.schema/0 to the matrix
  # schema, then sets search_path on the TestRepo connections so unqualified
  # raw SQL in tests also targets the configured schema.
```

**Planner action:** If touching this workflow for GATE-02, only clarify that the dual-schema matrix is a broad canary because it patches `search_path`; do not make it the fail-closed proof. The focused proof is `mix verify.schema_prefix`.

## Shared Patterns

### Core raw Multi prefixing

**Source:** `lib/mailglass/repo.ex` lines 116-118 and 130-151
**Apply to:** `Webhook.Replay`, fake adapter, webhook reconciler, unsubscribe callback lookup

```elixir
NOTE: `multi/2` does NOT inject prefix at the executor level -- Ecto.Multi
does not propagate executor opts into inner step SQL. Use `multi_opts/1`
to thread prefix per-step in Multi builder chains.

def multi_opts(opts \\ []), do: Keyword.put_new(opts, :prefix, Mailglass.Config.schema())
```

### Inbound raw repo extension points

**Source:** `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex` lines 12-17
**Apply to:** `Internal.Replay`, `Execution.load`, inbound replay mix task selector resolution

```elixir
defp schema_opts, do: [prefix: MailglassInbound.Config.schema()]
```

### Hostile no-search-path runtime proof

**Source:** `test/mailglass/schema_isolation_immutability_test.exs` lines 40-90 and `test/test_helper.exs` lines 57-65
**Apply to:** `test/mailglass/schema_prefix_hardening_test.exs`

Use the schema setup/teardown pattern from `schema_isolation_immutability_test.exs`, but do not copy the suite-level `search_path = "<schema>, public"` crutch from `test/test_helper.exs`. The new proof must force the active connection path to exclude the configured schema before running the behavior under test.

### Custom Credo checks

**Source:** `credo_checks/no_unscoped_tenant_query_in_lib.ex` and `test/mailglass/credo/checks_have_tests_test.exs`
**Apply to:** `credo_checks/raw_repo_prefix_contract.ex`, `.credo.exs`, and the guard test

```elixir
requires: ["./credo_checks/*.ex"],
checks:
  extra_checks ++
```

Every new `credo_checks/*.ex` file must have `test/mailglass/credo/*_test.exs` and `.credo.exs` registration.

### Verify aliases

**Source:** `mix.exs` lines 54-83 and 199-208
**Apply to:** `mix verify.schema_prefix`

Add preferred env first, then add the alias in `aliases/0`. Keep the alias focused: hostile runtime test, static guard test, strict Credo, and inbound contract test.

## No Exact Analog Found

| Target | Missing Exact Analog | Use Instead |
|--------|----------------------|-------------|
| `lib/mailglass/compliance/unsubscribe_controller.ex` raw `repo.one!/2` in `Ecto.Multi.run` | No existing core callback uses raw `repo.one!` with `Repo.multi_opts()` | Combine `Repo.multi_opts/1` from `lib/mailglass/repo.ex` with inbound `repo.one(query, schema_opts())` from `Ingress.Persist` |
| `test/mailglass/schema_prefix_hardening_test.exs` hostile replay/unsubscribe runtime proof | No existing test runs these runtime paths while `search_path` excludes the configured schema | Combine schema setup from `schema_isolation_immutability_test.exs` with replay/unsubscribe behavior tests and add explicit hostile path setup |
| `credo_checks/raw_repo_prefix_contract.ex` exact semantic guard | No existing guard checks raw repo prefix contracts specifically | Use `NoUnscopedTenantQueryInLib` AST call-shape matching and path-scoping as the closest good analog |

## Metadata

**Analog search scope:** `lib/`, `mailglass_inbound/lib/`, `credo_checks/`, `test/`, `mailglass_inbound/test/`, `mix.exs`, `.credo.exs`, `.github/workflows/advisory-matrix.yml`
**Files scanned:** 538 source/test/config files
**Pattern extraction date:** 2026-07-07
