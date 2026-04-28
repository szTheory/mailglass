# Phase 12: auto-suppression-soft-bounce-escalation - Pattern Map

**Mapped:** 2026-04-28
**Files analyzed:** 16
**Analogs found:** 16 / 16

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mailglass/webhook/ingest.ex` | service | event-driven | `lib/mailglass/webhook/ingest.ex` | exact |
| `lib/mailglass/suppression/auto_suppress.ex` | service | event-driven | `lib/mailglass/webhook/ingest.ex` | flow-match |
| `lib/mailglass/suppression/escalation.ex` | service | event-driven | `lib/mailglass/outbound/worker.ex` | role-match |
| `lib/mailglass/suppression/resync.ex` | service | batch | `lib/mailglass/events/reconciler.ex` | role-match |
| `lib/mix/tasks/mailglass.suppressions.resync.ex` | utility | batch | `lib/mix/tasks/mailglass.reconcile.ex` | role-match |
| `lib/mailglass/suppression.ex` | service | request-response | `lib/mailglass/suppression.ex` | exact |
| `lib/mailglass/suppression/entry.ex` | model | CRUD | `lib/mailglass/suppression/entry.ex` | exact |
| `lib/mailglass/suppression_store/ecto.ex` | service | CRUD | `lib/mailglass/suppression_store/ecto.ex` | exact |
| `lib/mailglass/migrations/postgres.ex` | migration | CRUD | `lib/mailglass/migrations/postgres.ex` | exact |
| `lib/mailglass/migrations/postgres/v03.ex` | migration | CRUD | `lib/mailglass/migrations/postgres/v02.ex` | exact |
| `credo_checks/multi_event_first_in_webhook_ingest.ex` | utility | transform | `credo_checks/no_bare_optional_dep_reference.ex` | exact |
| `test/mailglass/webhook/ingest_auto_suppress_test.exs` | test | event-driven | `test/mailglass/webhook/ingest_test.exs` | exact |
| `test/mailglass/suppression/escalation_test.exs` | test | event-driven | `test/mailglass/outbound/worker_test.exs` | role-match |
| `test/mailglass/properties/webhook_suppression_convergence_test.exs` | test | event-driven | `test/mailglass/properties/webhook_idempotency_convergence_test.exs` | exact |
| `test/mix/tasks/mailglass.suppressions.resync_test.exs` | test | batch | `test/mix/tasks/mailglass.gen.unsubscribe_test.exs` | role-match |
| `test/mailglass/credo/multi_event_first_in_webhook_ingest_test.exs` | test | transform | `test/mailglass/credo/no_bare_optional_dep_reference_test.exs` | exact |

## Pattern Assignments

### `lib/mailglass/webhook/ingest.ex` (service, event-driven)

**Analog:** `lib/mailglass/webhook/ingest.ex`

Use the existing flat `Ecto.Multi` composition. Phase 12 should extend it; do not introduce a nested `Repo.multi/1` or a second write path.

**Imports + aliases** (`lib/mailglass/webhook/ingest.ex:89-97`)
```elixir
import Ecto.Query

alias Ecto.Multi
alias Mailglass.{Clock, Config, Events, IdempotencyKey, Repo}
alias Mailglass.Events.Event
alias Mailglass.Outbound.{Delivery, Projector}
alias Mailglass.Tenancy
```

**Transaction shell + fail-loud tenant stamp** (`lib/mailglass/webhook/ingest.ex:121-149`)
```elixir
tenant_id = Tenancy.tenant_id!()

result =
  Repo.transact(fn ->
    _ = Repo.query!("SET LOCAL statement_timeout = '2s'", [])
    _ = Repo.query!("SET LOCAL lock_timeout = '500ms'", [])

    multi = build_multi(provider, raw_body, events, tenant_id)
```

**Current event-first step ordering** (`lib/mailglass/webhook/ingest.ex:212-226`)
```elixir
duplicate_check_step
|> Multi.insert(:webhook_event, WebhookEvent.changeset(webhook_event_attrs),
  on_conflict: :nothing,
  conflict_target: [:provider, :provider_event_id],
  returning: true
)
|> append_events_for_each(events, provider, tenant_id)
|> update_projections_for_each(events)
|> Multi.update_all(:flip_status, &flip_status_query(&1, provider_str),
  set: [status: :succeeded, processed_at: Clock.utc_now()]
)
```

**Per-event flat step pattern** (`lib/mailglass/webhook/ingest.ex:269-313`)
```elixir
Multi.run(acc, {:projector_categorize, idx}, fn _repo, changes ->
  inserted_event = Map.get(changes, event_step_name(idx))
  ...
end)

Multi.run(acc, {:projector_apply, idx}, fn repo, changes ->
  case Map.get(changes, {:projector_categorize, idx}) do
    {:matched, delivery, inserted_event} ->
      changeset = Projector.update_projections(delivery, inserted_event)
      repo.update(changeset)
```

**Apply to Phase 12:** add `{:auto_suppress, idx}` after `{:projector_apply, idx}` and keep `Events.append_multi/3` first.

---

### `lib/mailglass/suppression/auto_suppress.ex` (service, event-driven)

**Analog:** `lib/mailglass/webhook/ingest.ex`

This module should be a helper invoked from the ingest Multi, not a second pipeline.

**Matched/orphan branching pattern** (`lib/mailglass/webhook/ingest.ex:274-305`)
```elixir
cond do
  is_nil(inserted_event) ->
    {:ok, :no_event_row}

  is_nil(inserted_event.delivery_id) ->
    {:ok, :orphan_skipped}

  true ->
    ...
    %Delivery{} = delivery -> {:ok, {:matched, delivery, inserted_event}}
```

**Result pass-through pattern for skipped paths** (`lib/mailglass/webhook/ingest.ex:298-310`)
```elixir
case Map.get(changes, {:projector_categorize, idx}) do
  {:matched, delivery, inserted_event} ->
    ...

  other ->
    {:ok, other}
end
```

**Provider normalization already produces the event types you need**

Postmark (`lib/mailglass/webhook/providers/postmark.ex:206-234`)
```elixir
defp map_record_type(%{"RecordType" => "Bounce", "TypeCode" => 1}), do: {:bounced, :bounced}
defp map_record_type(%{"RecordType" => "Bounce", "TypeCode" => 2}), do: {:deferred, nil}
defp map_record_type(%{"RecordType" => "SpamComplaint"}), do: {:complained, nil}
defp map_record_type(%{"RecordType" => "SubscriptionChange", "SuppressSending" => true}),
  do: {:unsubscribed, nil}
```

SendGrid (`lib/mailglass/webhook/providers/sendgrid.ex:266-301`)
```elixir
defp map_event(%{"event" => "deferred"}), do: {:deferred, nil}
defp map_event(%{"event" => "bounce", "type" => "bounce"}), do: {:bounced, :bounced}
defp map_event(%{"event" => "spamreport"}), do: {:complained, nil}
defp map_event(%{"event" => "unsubscribe"}), do: {:unsubscribed, nil}
defp map_event(%{"event" => "group_unsubscribe"}), do: {:unsubscribed, nil}
```

**Apply to Phase 12:** centralize event-type -> suppression-reason translation here, derive address/stream from `%Delivery{}` only, and return `{:ok, :skipped}` for orphan/no-op paths.

---

### `lib/mailglass/suppression/escalation.ex` (service, event-driven)

**Analog:** `lib/mailglass/outbound/worker.ex`

Use the existing conditional Oban worker shape. Keep compilation gated on `Code.ensure_loaded?(Oban.Worker)`.

**Conditional worker module** (`lib/mailglass/outbound/worker.ex:1-8`)
```elixir
if Code.ensure_loaded?(Oban.Worker) do
  defmodule Mailglass.Outbound.Worker do
    @moduledoc """
    Oban worker that dispatches a queued Delivery (SEND-03). Conditionally
    compiled — entire module elided when `:oban` is not loaded.
```

**Worker options** (`lib/mailglass/outbound/worker.ex:33-37`)
```elixir
use Oban.Worker,
  queue: :mailglass_outbound,
  max_attempts: 20,
  unique: [period: 3600, fields: [:args], keys: [:delivery_id]]
```

**Tenant restoration inside `perform/1`** (`lib/mailglass/outbound/worker.ex:38-55`)
```elixir
def perform(%Oban.Job{args: %{"delivery_id" => id}} = job) when is_binary(id) do
  Mailglass.Oban.TenancyMiddleware.wrap_perform(job, fn ->
    case Mailglass.Outbound.dispatch_by_id(id) do
      {:ok, %Mailglass.Outbound.Delivery{status: :sent}} -> :ok
      {:ok, %Mailglass.Outbound.Delivery{status: :failed, last_error: err}} -> {:error, err}
      {:error, %{__exception__: true} = err} -> {:error, err}
      {:error, other} -> {:error, inspect(other)}
    end
  end)
end
```

**Gateway pattern for enqueueing** (`lib/mailglass/optional_deps/oban.ex:48-61`)
```elixir
@spec insert(Ecto.Multi.t(), atom(), (map() -> term())) :: Ecto.Multi.t()
def insert(multi, name, job_builder) when is_atom(name) and is_function(job_builder, 1) do
  if available?() do
    Oban.insert(multi, name, job_builder)
  else
    multi
  end
end
```

**Apply to Phase 12:** compile the worker only when Oban exists, wrap `perform/1` with tenancy middleware, and route enqueue operations through `Mailglass.OptionalDeps.Oban`.

---

### `lib/mailglass/suppression/resync.ex` (service, batch)

**Analog:** `lib/mailglass/events/reconciler.ex`

This is the closest batch query module in the repo: pure query logic, explicit tenant handling, and typed skip/error return values.

**Tenant-scoped option parsing pattern** (`lib/mailglass/events/reconciler.ex:57-88`)
```elixir
@spec find_orphans(keyword()) :: [Event.t()]
def find_orphans(opts \\ []) when is_list(opts) do
  tenant_id = Keyword.get(opts, :tenant_id)
  ...
  case tenant_id do
    nil ->
      Tenancy.audit_unscoped_bypass(%{reason: :system_reconciliation, resource: :event})
      Mailglass.Repo.all(query, scope: :unscoped)

    tid when is_binary(tid) ->
      Mailglass.Repo.all(Tenancy.scope(query, tid))
  end
end
```

**Pure query + structured error return** (`lib/mailglass/events/reconciler.ex:111-145`)
```elixir
@spec attempt_link(Event.t()) ::
        {:ok, {Delivery.t(), Event.t()}}
        | {:error, :delivery_not_found | :malformed_payload}
def attempt_link(%Event{} = event) do
  Mailglass.Telemetry.persist_span(
    [:reconcile, :link],
    %{tenant_id: event.tenant_id},
    fn ->
      ...
      case Mailglass.Repo.one(query, scope: :unscoped) do
        nil -> {:error, :delivery_not_found}
        %Delivery{} = delivery -> {:ok, {delivery, event}}
      end
```

**Apply to Phase 12:** keep `resync.ex` as the reusable candidate-selection and insert-planning module. The Mix task should call this module in both dry-run and apply modes.

---

### `lib/mix/tasks/mailglass.suppressions.resync.ex` (utility, batch)

**Analog:** `lib/mix/tasks/mailglass.reconcile.ex`

Use `mailglass.reconcile` for the task shell and output tone, but borrow strict CLI rejection from the stricter tasks below.

**Task shell + app boot + concise output** (`lib/mix/tasks/mailglass.reconcile.ex:43-70`)
```elixir
def run(argv) do
  {opts, _rest, _invalid} =
    OptionParser.parse(argv, strict: [tenant_id: :string, batch_size: :integer])

  Mix.Task.run("app.start")
  tenant_id = opts[:tenant_id]
  batch_size = opts[:batch_size] || 1000

  if Mailglass.Webhook.Reconciler.available?() do
    {:ok, %{scanned: scanned, linked: linked}} =
      Mailglass.Webhook.Reconciler.reconcile(tenant_id, batch_size)

    Mix.shell().info("Reconcile complete: scanned=#{scanned} linked=#{linked}" <> ...)
```

**Strict unknown-option and positional-arg rejection** (`lib/mix/tasks/mailglass.gen.unsubscribe.ex:199-219`)
```elixir
defp validate_cli!(opts, rest, invalid) do
  if opts != [] do
    Mix.raise("Unsubscribe checklist blocked: unexpected parsed options #{inspect(opts)}")
  end

  if rest != [] do
    Mix.raise("Unsubscribe checklist blocked: unexpected positional arguments #{Enum.join(rest, " ")}")
  end

  if invalid != [] do
    ...
    Mix.raise("Unsubscribe checklist blocked: unknown option(s) #{invalid_flags}")
  end
end
```

**Dry-run totals pattern** (`lib/mix/tasks/mailglass.install.ex:80-92`)
```elixir
defp print_totals(counts, dry_run?) do
  suffix =
    if dry_run? do
      " (dry run)"
    else
      ""
    end

  Mix.shell().info(
    "Install result#{suffix}: create=#{counts.create} update=#{counts.update} " <>
      "unchanged=#{counts.unchanged} conflict=#{counts.conflict}"
  )
end
```

**Apply to Phase 12:** require `--tenant-id`, reject unknown args loudly, and print terse operator output like `scanned=... would_insert=... existing=...`.

---

### `lib/mailglass/suppression.ex` (service, request-response)

**Analog:** `lib/mailglass/suppression.ex`

This is the pre-send facade that Phase 12 tightens. Keep it thin over the store and preserve the PII-safe telemetry contract.

**Facade shape** (`lib/mailglass/suppression.ex:35-64`)
```elixir
@spec check_before_send(Message.t()) :: :ok | {:error, SuppressedError.t()}
def check_before_send(%Message{} = msg) do
  address = primary_recipient(msg)
  key = %{tenant_id: msg.tenant_id, address: address, stream: msg.stream}

  result = store().check(key, [])
  ...
  case result do
    :not_suppressed -> :ok
    {:suppressed, %{scope: scope}} -> {:error, SuppressedError.new(scope, context: %{...})}
    {:error, err} -> {:error, err}
  end
end
```

**Telemetry shape** (`lib/mailglass/suppression.ex:80-85`)
```elixir
:telemetry.execute(
  [:mailglass, :outbound, :suppression, :stop],
  %{duration_us: duration_us},
  %{hit: hit, tenant_id: tenant_id}
)
```

**Apply to Phase 12:** if you add richer suppression reasons or metadata, keep the public result contract and telemetry metadata stable.

---

### `lib/mailglass/suppression/entry.ex` (model, CRUD)

**Analog:** `lib/mailglass/suppression/entry.ex`

Use this file as the source of truth for closed scope/reason sets and schema-level invariants.

**Closed atom sets** (`lib/mailglass/suppression/entry.ex:35-38`)
```elixir
@scopes [:address, :domain, :address_stream]
@streams [:transactional, :operational, :bulk]
@reasons [:hard_bounce, :complaint, :unsubscribe, :manual, :policy, :invalid_recipient]
```

**Schema fields for suppression semantics** (`lib/mailglass/suppression/entry.ex:52-65`)
```elixir
schema "mailglass_suppressions" do
  field(:tenant_id, :string)
  field(:address, :string)
  field(:scope, Ecto.Enum, values: @scopes)
  field(:stream, Ecto.Enum, values: @streams)
  field(:reason, Ecto.Enum, values: @reasons)
  field(:source, :string)
  field(:expires_at, :utc_datetime_usec)
  field(:metadata, :map, default: %{})
```

**Coupling validation** (`lib/mailglass/suppression/entry.ex:82-108`)
```elixir
%__MODULE__{}
|> cast(attrs, @cast)
|> validate_required(@required)
|> validate_scope_stream_coupling()
|> downcase_address()
```

**Apply to Phase 12:** keep new escalation provenance in `:source` and/or `:metadata`; do not widen `:reason` unless requirements force it.

---

### `lib/mailglass/suppression_store/ecto.ex` (service, CRUD)

**Analog:** `lib/mailglass/suppression_store/ecto.ex`

This is the storage seam for all suppression writes and reads. New auto-suppression and resync code should reuse `record/2`, not bypass it.

**Lookup union semantics** (`lib/mailglass/suppression_store/ecto.ex:48-60`)
```elixir
base =
  from(e in Entry,
    where: e.tenant_id == ^tenant_id,
    where: is_nil(e.expires_at) or e.expires_at > ^now,
    limit: 1
  )

query = union_predicates(base, address, recipient_domain, stream)

case Mailglass.Repo.one(Tenancy.scope(query, tenant_id)) do
  nil -> :not_suppressed
  %Entry{} = entry -> {:suppressed, entry}
end
```

**Address/domain/address_stream branching** (`lib/mailglass/suppression_store/ecto.ex:76-91`)
```elixir
defp union_predicates(base, address, recipient_domain, nil) do
  from(e in base,
    where:
      (e.scope == :address and e.address == ^address) or
        (e.scope == :domain and e.address == ^recipient_domain)
  )
end

defp union_predicates(base, address, recipient_domain, stream) when is_atom(stream) do
```

**Idempotent store write** (`lib/mailglass/suppression_store/ecto.ex:97-123`)
```elixir
attrs
|> Entry.changeset()
|> Mailglass.Repo.insert(insert_opts())

[
  on_conflict: {:replace, [:reason, :source, :expires_at, :metadata]},
  conflict_target: {:unsafe_fragment, "(tenant_id, address, scope, COALESCE(stream, ''))"},
  returning: true
]
```

**Apply to Phase 12:** auto-suppression, escalation, and resync should all converge on this upsert path for replay-safe behavior.

---

### `lib/mailglass/migrations/postgres.ex` and `lib/mailglass/migrations/postgres/v03.ex` (migration, CRUD)

**Analog:** `lib/mailglass/migrations/postgres.ex`, `lib/mailglass/migrations/postgres/v02.ex`, `lib/mailglass/migrations/postgres/v01.ex`

Use `postgres.ex` for version bumping and the existing V01/V02 modules for DDL style.

**Migration runner version constants** (`lib/mailglass/migrations/postgres.ex:6-14`)
```elixir
@initial_version 1
@current_version 2

def initial_version, do: @initial_version
def current_version, do: @current_version
```

**Per-version dispatch** (`lib/mailglass/migrations/postgres.ex:73-80`)
```elixir
for index <- range do
  pad_idx = String.pad_leading(to_string(index), 2, "0")

  [__MODULE__, "V#{pad_idx}"]
  |> Module.concat()
  |> apply(direction, [opts])
end
```

**V02 migration module structure** (`lib/mailglass/migrations/postgres/v02.ex:25-45`)
```elixir
def up(opts \\ []) do
  prefix = opts[:prefix]

  create table(:mailglass_webhook_events, primary_key: false, prefix: prefix) do
    add(:id, :uuid, primary_key: true)
    add(:tenant_id, :text, null: false)
    ...
  end
```

**Existing suppression constraint style** (`lib/mailglass/migrations/postgres/v01.ex:166-176`)
```elixir
execute(
  """
  ALTER TABLE mailglass_suppressions
    ADD CONSTRAINT mailglass_suppressions_stream_scope_check
    CHECK (
      (scope = 'address_stream' AND stream IS NOT NULL) OR
      (scope IN ('address', 'domain') AND stream IS NULL)
    )
  """,
  "ALTER TABLE mailglass_suppressions DROP CONSTRAINT IF EXISTS mailglass_suppressions_stream_scope_check"
)
```

**Apply to Phase 12:** add `V03`, bump `@current_version`, and express the complaint-permanence invariant as explicit DDL in the same `execute/2` style.

---

### `credo_checks/multi_event_first_in_webhook_ingest.ex` (utility, transform)

**Analog:** `credo_checks/no_bare_optional_dep_reference.ex`

Use the repo’s standard custom Credo check structure: `use Credo.Check`, `SourceFile.ast/1`, `Macro.traverse/4`, and `format_issue/2`.

**Check declaration + param defaults** (`credo_checks/no_bare_optional_dep_reference.ex:1-24`)
```elixir
defmodule Mailglass.Credo.NoBareOptionalDepReference do
  use Credo.Check,
    category: :warning,
    base_priority: :high,
    param_defaults: [...],
    explanations: [...]
```

**AST traversal skeleton** (`credo_checks/no_bare_optional_dep_reference.ex:26-44`)
```elixir
def run(%SourceFile{} = source_file, params \\ []) do
  ...
  ast = SourceFile.ast(source_file)

  {_ast, state} =
    Macro.traverse(
      ast,
      %{issues: [], module_stack: []},
      &prewalk(&1, &2, issue_meta, gated_modules),
      &postwalk/2
    )
```

**Issue formatting** (`credo_checks/no_bare_optional_dep_reference.ex:113-121`)
```elixir
format_issue(
  issue_meta,
  message: "Optional dependency call `#{dependency_root}.#{function_name}` must go through `#{gateway_module}`.",
  trigger: "#{dependency_root}.#{function_name}",
  line_no: line_no,
  column: column
)
```

**Apply to Phase 12:** scan only `lib/mailglass/webhook/ingest.ex`, enforce the `webhook_event -> event -> projector -> auto_suppress` ordering structurally, and keep the failure message concrete.

---

### `test/mailglass/webhook/ingest_auto_suppress_test.exs` (test, event-driven)

**Analog:** `test/mailglass/webhook/ingest_test.exs`

Follow the current ingest integration test layout: `WebhookCase`, tenant cleanup in `setup`, fixture helpers at the bottom, and concrete assertions against `Repo` rows.

**Test module shell** (`test/mailglass/webhook/ingest_test.exs:23-37`)
```elixir
use Mailglass.WebhookCase, async: false

alias Mailglass.{Repo, Tenancy, TestRepo}
alias Mailglass.Events.Event
alias Mailglass.Outbound.Delivery
alias Mailglass.Webhook.{Ingest, WebhookEvent}

setup do
  on_exit(fn -> Tenancy.clear() end)
  :ok
end
```

**Happy-path assertion style** (`test/mailglass/webhook/ingest_test.exs:58-85`)
```elixir
assert {:ok, result} = Ingest.ingest_multi(:postmark, ..., events)
assert result.duplicate == false
assert length(result.events_with_deliveries) == 1

[webhook_event] = Repo.all(WebhookEvent)
assert webhook_event.status == :succeeded

[event_row] = Repo.all(Event)
assert event_row.delivery_id == delivery.id
```

**Apply to Phase 12:** write separate tests for hard bounce, complaint, unsubscribe, deferred enqueue, and orphan skip behavior.

---

### `test/mailglass/suppression/escalation_test.exs` (test, event-driven)

**Analog:** `test/mailglass/outbound/worker_test.exs`

Use the repo’s Oban-optional test discipline: `@moduletag :oban`, runtime `Code.ensure_loaded?` guard, and assertions against worker opts / perform behavior.

**Optional-dep guard pattern** (`test/mailglass/outbound/worker_test.exs:4-18`)
```elixir
@moduletag :oban

setup do
  if Code.ensure_loaded?(Oban.Testing) do
    Oban.Testing.with_testing_mode(:manual, fn -> :ok end)
  end

  :ok
end
```

**Worker option assertions** (`test/mailglass/outbound/worker_test.exs:21-50`)
```elixir
if Code.ensure_loaded?(Mailglass.Outbound.Worker) do
  opts = Mailglass.Outbound.Worker.__opts__()
  assert Keyword.get(opts, :queue) == :mailglass_outbound
  assert Keyword.get(opts, :max_attempts) == 20
```

**Perform-path structure** (`test/mailglass/outbound/worker_test.exs:53-80`)
```elixir
job = %Oban.Job{
  args: %{"delivery_id" => delivery.id, "mailglass_tenant_id" => "test-tenant"}
}

result =
  Mailglass.Oban.TenancyMiddleware.wrap_perform(job, fn ->
    Outbound.dispatch_by_id(delivery.id)
  end)
```

**Apply to Phase 12:** assert queue name, uniqueness keys, tenant restoration, threshold counting from `:deferred`, and idempotent suppression insert behavior.

---

### `test/mailglass/properties/webhook_suppression_convergence_test.exs` (test, event-driven)

**Analog:** `test/mailglass/properties/webhook_idempotency_convergence_test.exs`

Follow the existing property-test sandbox discipline exactly.

**Property test shell** (`test/mailglass/properties/webhook_idempotency_convergence_test.exs:37-63`)
```elixir
use ExUnit.Case, async: false
use ExUnitProperties

setup do
  Sandbox.mode(TestRepo, :auto)
  :ok = Tenancy.put_current("prop-test-tenant")

  TestRepo.query!("TRUNCATE TABLE mailglass_webhook_events CASCADE", [])
  TestRepo.query!("TRUNCATE TABLE mailglass_events CASCADE", [])
```

**Generator shape** (`test/mailglass/properties/webhook_idempotency_convergence_test.exs:67-91`)
```elixir
gen all(
      record_type <- member_of(["Delivery", "Open", "Click", "SpamComplaint"]),
      msg_id <- string(:alphanumeric, min_length: 8, max_length: 24),
      event_id <- string(:alphanumeric, min_length: 8, max_length: 24)
    ) do
  %Event{type: type, metadata: %{...}}
end
```

**Convergence assertion style** (`test/mailglass/properties/webhook_idempotency_convergence_test.exs:94-147`)
```elixir
for event <- events, _ <- 1..replay_count do
  {:ok, _result} = Ingest.ingest_multi(:postmark, raw_body, [event])
end

webhook_event_count = TestRepo.aggregate(WebhookEvent, :count)
assert webhook_event_count == unique_provider_event_ids
```

**Apply to Phase 12:** extend the invariant from event-row convergence to suppression-row convergence for hard bounce / complaint / unsubscribe replay scenarios.

---

### `test/mix/tasks/mailglass.suppressions.resync_test.exs` (test, batch)

**Analog:** `test/mix/tasks/mailglass.gen.unsubscribe_test.exs`

Use `CaptureIO`, env setup/restore, and explicit failure assertions for CLI UX.

**Setup + env restore** (`test/mix/tasks/mailglass.gen.unsubscribe_test.exs:6-25`)
```elixir
setup do
  prior_mailglass = Application.get_all_env(:mailglass)
  ...
  on_exit(fn ->
    Application.put_all_env(mailglass: prior_mailglass)
  end)
  :ok
end
```

**Output contract assertions** (`test/mix/tasks/mailglass.gen.unsubscribe_test.exs:28-59`)
```elixir
output = capture_io(fn -> Mix.Tasks.Mailglass.Gen.Unsubscribe.run([]) end)
assert output =~ "mix mailglass.gen.unsubscribe"

assert_raise Mix.Error, ~r/unknown option/, fn ->
  Mix.Tasks.Mailglass.Gen.Unsubscribe.run(["--wat"])
end
```

**Behavioral test style** (`test/mix/tasks/mailglass.gen.unsubscribe_test.exs:61-117`)
```elixir
output =
  File.cd!(tmp_dir, fn ->
    capture_io(fn -> Mix.Tasks.Mailglass.Gen.Unsubscribe.run([]) end)
  end)

assert File.ls!(tmp_dir) == []
assert output =~ "This task intentionally copies zero files."
```

**Apply to Phase 12:** assert `--tenant-id` is mandatory, `--dry-run` and apply share candidate counts, `--verbose` changes output detail only, and unknown args fail loudly.

---

### `test/mailglass/credo/multi_event_first_in_webhook_ingest_test.exs` (test, transform)

**Analog:** `test/mailglass/credo/no_bare_optional_dep_reference_test.exs`

Use the current direct-string AST fixture style.

**Test structure** (`test/mailglass/credo/no_bare_optional_dep_reference_test.exs:1-10`)
```elixir
defmodule Mailglass.Credo.NoBareOptionalDepReferenceTest do
  use ExUnit.Case, async: true

  alias Credo.SourceFile
  alias Mailglass.Credo.NoBareOptionalDepReference
```

**Inline source fixture pattern** (`test/mailglass/credo/no_bare_optional_dep_reference_test.exs:12-25`)
```elixir
source = """
defmodule Mailglass.Outbound.BadCall do
  def run(job) do
    Oban.insert(job)
  end
end
"""

issues = run_check(source, "lib/mailglass/outbound/no_bare_optional_dep_reference_bad.ex")
assert length(issues) == 1
```

**Helper** (`test/mailglass/credo/no_bare_optional_dep_reference_test.exs:63-67`)
```elixir
defp run_check(source, filename) do
  source
  |> SourceFile.parse(filename)
  |> NoBareOptionalDepReference.run([])
end
```

**Apply to Phase 12:** write one failing fixture with `:auto_suppress` before event append / projector ordering, and one passing fixture with the correct order.

## Shared Patterns

### Tenant Scoping
**Sources:** `lib/mailglass/webhook/ingest.ex`, `lib/mailglass/suppression_store/ecto.ex`, `lib/mailglass/tenancy.ex`
**Apply to:** all new suppression, escalation, and resync modules

`lib/mailglass/webhook/ingest.ex:121-126`
```elixir
tenant_id = Tenancy.tenant_id!()
```

`lib/mailglass/suppression_store/ecto.ex:57-60`
```elixir
case Mailglass.Repo.one(Tenancy.scope(query, tenant_id)) do
  nil -> :not_suppressed
  %Entry{} = entry -> {:suppressed, entry}
end
```

`lib/mailglass/tenancy.ex:170-183`
```elixir
def with_tenant(tenant_id, fun) when is_binary(tenant_id) and is_function(fun, 0) do
  prior = Process.get(@process_dict_key)
  put_current(tenant_id)
  try do
    fun.()
  after
    ...
  end
end
```

### Suppression Write Semantics
**Sources:** `lib/mailglass/suppression/entry.ex`, `lib/mailglass/suppression_store/ecto.ex`
**Apply to:** auto-suppression, escalation, resync, pre-send enforcement

`lib/mailglass/suppression/entry.ex:67-88`
```elixir
@required ~w[tenant_id address scope reason source]a
@cast @required ++ ~w[stream expires_at metadata]a

%__MODULE__{}
|> cast(attrs, @cast)
|> validate_required(@required)
|> validate_scope_stream_coupling()
|> downcase_address()
```

`lib/mailglass/suppression_store/ecto.ex:118-123`
```elixir
[
  on_conflict: {:replace, [:reason, :source, :expires_at, :metadata]},
  conflict_target: {:unsafe_fragment, "(tenant_id, address, scope, COALESCE(stream, ''))"},
  returning: true
]
```

### Optional Oban Dependency
**Sources:** `lib/mailglass/optional_deps/oban.ex`, `lib/mailglass/outbound/worker.ex`
**Apply to:** soft-bounce enqueue + worker modules

`lib/mailglass/optional_deps/oban.ex:45-57`
```elixir
@spec available?() :: boolean()
def available?, do: Code.ensure_loaded?(Oban)

def insert(multi, name, job_builder) when is_atom(name) and is_function(job_builder, 1) do
  if available?() do
    Oban.insert(multi, name, job_builder)
```

`lib/mailglass/outbound/worker.ex:33-40`
```elixir
use Oban.Worker,
  queue: :mailglass_outbound,
  max_attempts: 20,
  unique: [period: 3600, fields: [:args], keys: [:delivery_id]]
```

### Strict Mix Task UX
**Sources:** `lib/mix/tasks/mailglass.reconcile.ex`, `lib/mix/tasks/mailglass.gen.unsubscribe.ex`, `lib/mix/tasks/mailglass.install.ex`
**Apply to:** `mix mailglass.suppressions.resync`

`lib/mix/tasks/mailglass.reconcile.ex:55-62`
```elixir
{:ok, %{scanned: scanned, linked: linked}} =
  Mailglass.Webhook.Reconciler.reconcile(tenant_id, batch_size)

Mix.shell().info(
  "Reconcile complete: scanned=#{scanned} linked=#{linked}" <>
    if(tenant_id, do: " tenant=#{tenant_id}", else: "")
)
```

`lib/mix/tasks/mailglass.install.ex:53-69`
```elixir
defp validate_cli!(rest, invalid) do
  if rest != [] do
    Mix.raise("Installation blocked: unexpected positional arguments #{Enum.join(rest, " ")}")
  end

  if invalid != [] do
    ...
    Mix.raise("Installation blocked: unknown option(s) #{invalid_flags}")
  end
end
```

### Custom Credo Check Structure
**Sources:** `credo_checks/no_bare_optional_dep_reference.ex`, `test/mailglass/credo/no_bare_optional_dep_reference_test.exs`
**Apply to:** new ingest-order check + its tests

`credo_checks/no_bare_optional_dep_reference.ex:35-44`
```elixir
{_ast, state} =
  Macro.traverse(
    ast,
    %{issues: [], module_stack: []},
    &prewalk(&1, &2, issue_meta, gated_modules),
    &postwalk/2
  )
```

`test/mailglass/credo/no_bare_optional_dep_reference_test.exs:63-67`
```elixir
defp run_check(source, filename) do
  source
  |> SourceFile.parse(filename)
  |> NoBareOptionalDepReference.run([])
end
```

## No Analog Found

None. Every planned file has at least a strong role-match analog in the current codebase.

## Metadata

**Analog search scope:** `lib/mailglass/`, `lib/mix/tasks/`, `lib/mailglass/migrations/`, `credo_checks/`, `test/mailglass/`, `test/mix/tasks/`
**Files scanned:** 21
**Pattern extraction date:** 2026-04-28
