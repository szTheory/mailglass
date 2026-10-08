# Phase 170: Inbound Investigation and Recovery - Pattern Map

**Mapped:** 2026-10-08  
**Files analyzed:** 17 likely existing files to modify; exact scope should be selected by plan tasks  
**Analogs found:** 17 / 17

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `mailglass_admin/lib/mailglass_admin/inbound_live.ex` | controller (LiveView) | request-response, event-driven | same file; `mailglass_admin/lib/mailglass_admin/operator_live.ex` for established host Auth seam | exact |
| `mailglass_admin/lib/mailglass_admin/optional_deps/mailglass_inbound.ex` | service/gateway | request-response | same file | exact |
| `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex` | component | CRUD/read projection | same file | exact |
| `mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex` | component | request-response | same file | exact |
| `mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex` | component | transform/read projection | same file | exact |
| `mailglass_admin/lib/mailglass_admin/inbound/timeline.ex` | component | transform/read projection | same file | exact |
| `mailglass_admin/lib/mailglass_admin/inbound/routing_trace.ex` | component | transform | same file | exact |
| `mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex` | component | file-I/O presentation (stored evidence) | same file | exact |
| `mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex` | component | request-response | same file; outbound `Operator.ReplayModal` for modal conventions | exact |
| `mailglass_admin/lib/mailglass_admin/inbound/destructive_action.ex` | utility/auth boundary | request-response | same file | exact |
| `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex` | service/read model | CRUD/read projection | same file | exact |
| `mailglass_inbound/lib/mailglass_inbound/internal/operator/detail.ex` | service/read model | CRUD/read projection | same file | exact |
| `mailglass_inbound/lib/mailglass_inbound/internal/operator/timeline.ex` | service/read model | CRUD/read projection | same file | exact |
| `mailglass_inbound/lib/mailglass_inbound/internal/replay.ex` | service | request-response, event-driven execution | same file | exact |
| `mailglass_inbound/lib/mailglass_inbound/execution.ex` | service | transform, event-driven execution | same file | exact |
| `mailglass_admin/test/mailglass_admin/inbound_live_test.exs` | test | request-response, event-driven | same file | exact |
| `mailglass_inbound/test/mailglass_inbound/internal/operator/{records,detail,timeline}_test.exs` and `mailglass_inbound/test/mailglass_inbound/replay_test.exs` | test | CRUD/read projection, request-response | existing focused tests | exact |

The context/research name these as the primary seams; this list is a likely modify set, not a requirement to edit every file. The selected files should preserve Phase 168's inherited Admin shell, component, responsive, focus, and target-size contract. No new package or frontend framework is indicated.

## Pattern Assignments

### `mailglass_admin/lib/mailglass_admin/inbound_live.ex` (LiveView, request-response/event-driven)

**Analog:** same file, plus the host Auth adapter flow in `mailglass_admin/lib/mailglass_admin/operator_live.ex`.

**URL state and parameter handling** (`inbound_live.ex`, lines 154-205):

```elixir
def handle_params(params, uri, socket) do
  {filter_params, filter_errors} = normalize_filter_params_with_errors(params)
  tenant_options = TenantSelector.list_tenants(socket.assigns.operator_actor,
    account_labels: socket.assigns.account_labels
  )
  selected_tenant_id = blank_to_nil(filter_params["tenant_id"])
  # assign normalized filters, selected Account and derived state
  ...
  |> assign_inbound_state(
    filter_params,
    blank_to_nil(params["inbound_id"]),
    params["full"] == "1" and not is_nil(blank_to_nil(params["inbound_id"]))
  )
end
```

Continue using normalized URL params as the source of Account/filter/page/selection/detail mode. On selection or mode changes use the existing path builders and `push_patch`; retain the requested exact ID independently of list membership so a deep-linked record outside the visible page/filter remains resolvable. Current code at lines 745-752 loads detail then `filter_selected_detail/3` at lines 1116-1123 removes a record that misses active filters; that is the specific behavior to change. Reset transient raw-reveal and replay state on Account/record change.

**Replay ordering and host Auth** (`inbound_live.ex`, lines 399-416; `inbound/destructive_action.ex`, lines 22-39):

```elixir
with {:ok, record} <- selected_replayable_record(socket),
     :ok <- verify_tenant(record, socket.assigns.filter_params),
     {:ok, socket} <- DestructiveAction.authorize(
       socket, socket.assigns.operator_auth[:adapter], record
     ),
     {:ok, result} <- replay_record(record) do
  # preserve exact selection and refresh scoped detail/history
end
```

Re-resolve the exact Account-scoped record and eligibility at confirmation. Keep tenant verification before the host adapter, then call existing `:replay_inbound` authorization immediately before gateway replay. Do not add an Auth capability or use UI disabled state as the only guard. The helper supplies `%{actor: ..., inbound_record: record}`; the key is intentionally not `:delivery` for stable adopter semantics.

**Read failure boundary** (`inbound_live.ex`, lines 1032-1099):

```elixir
defp load_inbound_records_page(filter_params) do
  if gateway_available?() do
    apply(@gateway, :list_records_page, [filters, []])
  else
    empty_page_meta()
  end
end
```

The current absent-gateway branches collapse to empty/zero and detail/timeline failures have nil/empty fallbacks. Introduce narrow explicit Admin result states for successful empty, filtered empty, out-of-range, unavailable selection/package, and known unavailable reads. Keep unknown programming/configuration errors visible; do not broad-rescue them or mislabel failures as “No records.”

### `mailglass_admin/lib/mailglass_admin/optional_deps/mailglass_inbound.ex` (gateway, request-response)

**Analog:** same file. This file is conditionally compiled and uses runtime `apply/3`, preserving the optional inbound package boundary. Gateway additions should be narrowly scoped and internal where possible; don't make an unconditional compile-time reference from the Admin app to inbound modules. Existing wrappers are at lines 93-118 (`summary`, `timeline`, `detail`, `explain`) and replay at lines 161-171.

```elixir
def detail(filters, opts \\ []) do
  apply(MailglassInbound.Internal.Operator.Detail, :fetch, [filters, opts])
end

def explain(route, message) do
  apply(MailglassInbound.Router.Matcher, :explain, [route, message])
end
```

`explain_routes/2` (lines 121-159) invokes the package matcher over currently mounted routes. Keep it described/rendered as a *current routing simulation*, never historical routing evidence. Don't duplicate route matcher semantics in Admin.

### `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex` (tenant-scoped read model, CRUD/read projection)

**Analog:** same file; `internal/operator/detail.ex` for exact read.

**Query, projection, and pagination** (`records.ex`, lines 81-120):

```elixir
query = scoped_query(normalized, tenant_id)
total_count = count_records(query)
entries = query
  |> order_by([rec: record], desc: record.received_at,
    desc: record.inserted_at, desc: record.id)
  |> limit(^per_page)
  |> offset(^offset_for(page, per_page))
  |> record_projection(tenant_id)
  |> Repo.all()

from(record in InboundRecord, as: :rec)
|> where([rec: record], record.tenant_id == ^tenant_id)
|> maybe_filter_provider(normalized[:provider])
|> maybe_filter_outcome(tenant_id, normalized[:outcome])
|> Tenancy.scope(tenant_id)
```

Use `MailglassInbound.Repo`, an explicit `tenant_id` predicate and `Tenancy.scope/2` on every tenant-bound query. Preserve the stable public API; any new eligibility/projection seam belongs under `Internal`. `latest_fresh_run_field/2` (lines 157-170) orders fresh runs newest first. List and detail summary must use the same *latest fresh* disposition; do not let a previous matched run replace a later failed/no-match fresh run. Keep replay entries in timeline, not list disposition.

### `mailglass_inbound/lib/mailglass_inbound/internal/operator/detail.ex` (exact detail read, CRUD/read projection)

**Analog:** same file.

```elixir
with {:ok, tenant_id} <- fetch_tenant_id(normalized),
     {:ok, record_id} <- fetch_record_id(normalized),
     %InboundRecord{} = record <- load_record(tenant_id, record_id) do
  evidence = load_evidence(tenant_id, record_id)
  {mailbox, outcome, outcome_reason} = resolve_outcome(tenant_id, record_id)
  %{record: record, evidence: evidence, mailbox: mailbox,
    outcome: outcome, outcome_reason: outcome_reason}
else
  _ -> nil
end
```

The exact query is `where(record.id == ^record_id and record.tenant_id == ^tenant_id) |> Tenancy.scope(tenant_id) |> Repo.one()` (lines 76-95). Preserve non-disclosing nil for missing/foreign Account IDs. Detail is independent of list filters/page; don't drop a successfully scoped detail because it falls outside the current list. The current `resolve_outcome/2` first searches latest *matched* fresh at lines 100-114; align it with list's latest-fresh semantics to meet D-04.

### `mailglass_inbound/lib/mailglass_inbound/internal/operator/timeline.ex` (tenant-scoped lineage, read projection)

**Analog:** same file.

```elixir
ExecutionRun
|> where([run], run.tenant_id == ^tenant_id and
  run.inbound_record_id == ^record_id)
|> order_by([run], asc: run.executed_at, asc: run.inserted_at, asc: run.id)
|> select([run], %{id: run.id, source: run.source, mailbox: run.mailbox,
  outcome: run.outcome, outcome_reason: run.outcome_reason,
  executed_at: run.executed_at, inserted_at: run.inserted_at})
|> Tenancy.scope(tenant_id)
|> Repo.all()
```

This is append-only historical evidence: preserve all fresh/replay runs in chronological order and expose IDs/source/times. Avoid exposing raw exception details from outcome reasons; map known typed outcomes to safe copy. Keep read unavailable distinct from a successful empty timeline.

### `mailglass_admin/lib/mailglass_admin/inbound/records_list.ex` and `timeline.ex` (components, semantic projections)

**Analogs:** same components.

`RecordsList` already uses semantic table/list markup and a `data_state` branch (`records_list.ex`, lines 60-107). Its empty body distinguishes `:truly_empty` from `:filtered` (lines 379-387), but nil data currently falls through to “No records”; retain the component pattern while adding the explicit unavailable/out-of-range/unavailable-selection presentations required by D-02. `Timeline` uses an ordered list, source labels, exact run IDs and timestamps (`timeline.ex`, lines 30-65). Preserve semantic list/table structures and do not introduce a partial ARIA grid.

### `mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex` (component, stored evidence presentation)

**Analog:** same file; `inbound_live.ex` reveal handler (lines 1237-1277).

**Reveal state/disclosure** (`evidence_card.ex`, lines 45-63, 104-150):

```heex
<button type="button" phx-click="reveal_raw"
  aria-expanded={if @reveal_state == :revealed, do: "true", else: "false"}
  aria-controls="inbound-evidence-raw">
  {if @reveal_state == :revealed, do: "Raw source revealed", else: "Reveal raw source"}
</button>
<p role="status" aria-live="polite">{reveal_status_text(@reveal_state)}</p>
```

Keep raw payload/MIME redacted by default and gated by existing action-time `:reveal_raw`; reset it on record/Account change. The current loop over every `verification_facts` pair at lines 90-100 is not a safe display policy. Add a narrow explicit allowlist/projection and field-level masking before render. Apply equivalent policy to expected matchers and actual subject/header values in RoutingTrace. Do not render arbitrary facts, raw exception text, or stack traces; never put payloads in URL/log/telemetry.

### `mailglass_admin/lib/mailglass_admin/inbound/routing_trace.ex` (component, transform)

**Analog:** same file and gateway `explain_routes/2` above. `decorate/1` at lines 156-177 converts matcher verdict tuples to view fields; the matcher remains upstream. Recipient actuals are masked, but subject/header actuals and expected matcher values are currently emitted directly. Add field-level policy to those values and label the card as a current router simulation. Do not claim it records what ran on receipt.

### `mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex` and `detail_header.ex` (components, request-response/read projection)

**Analogs:** same files. Retain masked record identity, context-preserving native links, and readable summary hierarchy. Selection should reflect exact scoped detail even when the record is outside current results; explain that relation without disclosing whether an ID belongs to another Account. Header summary should state no match, failed, matched Mailbox, or missing history from persisted facts only. A Mailbox result does not establish provider delivery or recipient receipt.

### `mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex` and `destructive_action.ex` (component/helper, request-response)

**Analogs:** same files; outbound ReplayModal for established modal conventions. The inbound modal has a named dialog, `aria-modal`, focus-trap hook, Escape handling, and visible close/cancel (replay_modal.ex, lines 29-87). Keep those Phase 168 patterns, add truthful eligibility/reason and local pending/duplicate-submit state, and do not imply a global lock. Describe replay as current code running the recorded Mailbox identity against stored message data, separate from current-router simulation and provider redelivery. At confirmation re-resolve and authorize, then execute; show command/run-recording status separately from the Mailbox outcome. Report “no change” only if the Mailbox explicitly returns the additive `:no_change` outcome approved in CONTEXT D-16; current `Execution` result classification (lines 309-343) does not imply no-change from `:ignore`.

### `mailglass_inbound/lib/mailglass_inbound/internal/replay.ex` and `execution.ex` (services, request-response/transform)

**Analogs:** same files.

`Replay.replay/2` requires `tenant_id`, loads record/evidence with tenant predicates plus `Tenancy.scope/2`, resolves persisted route binding, then calls `Execution.execute(..., source: :replay)` (`replay.ex`, lines 27-43, 237-267). `resolve_mailbox/4` differentiates stored no-match and missing/unsafe legacy bindings (lines 269-299). Preserve that behavior: don't rematch old records against current router, atomize saved module strings, or add package-public APIs. Eligibility reads must use same tenant/schema boundary. Distinguish an error before run insertion from a persisted failed ExecutionRun. The source vocabulary currently lacks the approved additive `:no_change` outcome; plan to persist and project it explicitly. Keep `:ignore` distinct.

### Test analogs

**Files:** `mailglass_admin/test/mailglass_admin/inbound_live_test.exs`, `mailglass_admin/test/mailglass_admin/inbound/evidence_card_test.exs`, `mailglass_inbound/test/mailglass_inbound/internal/operator/records_test.exs`, `mailglass_inbound/test/mailglass_inbound/internal/operator/summary_test.exs`, `mailglass_inbound/test/mailglass_inbound/replay_test.exs`.

Follow the existing focused tests for LiveView URL/events and rendered states, sensitive evidence fixtures, tenant isolation, latest-fresh selection, and replay eligibility/error results. Add cases for selected ID outside page/filter, missing vs empty vs failed reads, latest fresh failed/no-match after an older match, safe verification/matcher fields, confirmation-time eligibility/auth, repeated confirm, and explicit callback-returned `:no_change` distinct from `:ignore`. No tests were run as instructed.

## Shared Patterns

### Tenant and schema boundary

**Sources:** `internal/operator/{records,detail,timeline}.ex`, `internal/replay.ex`. Apply explicit tenant predicate plus `Tenancy.scope/2` to every read/replay query; use `MailglassInbound.Repo` and preserve host schema-prefix handling.

### Optional package boundary and stable API

**Source:** `mailglass_admin/lib/mailglass_admin/optional_deps/mailglass_inbound.ex`. Admin should continue using conditional gateway/runtime `apply/3`. Keep new eligibility/projection operations internal and narrow; preserve adopter-facing API inventory.

### Authorization

**Sources:** `inbound/destructive_action.ex`, `inbound_live.ex`. Use host `MailglassAdmin.Auth` adapter and existing `:replay_inbound` / `:reveal_raw` actions at action time. Resolve exact selection and eligibility before authorizing immediately ahead of replay execution.

### Truthful state and privacy

**Sources:** `records_list.ex`, `evidence_card.ex`, `routing_trace.ex`, `timeline.ex`. Successful empty, filtered empty, out-of-range, missing selection, optional package unavailable, and failed read are distinct. Project safe values explicitly, mask sensitive actuals/expected values, and keep raw evidence action-gated. Persisted runs are historical facts; route trace is current simulation.

### UI interaction

**Sources:** Phase 168 `168-CONTEXT.md` / `168-UI-SPEC.md`, plus current inbound components. Keep native links/buttons, semantic list/table, accurate disclosure state, polite status messages, modal labeling/focus containment/return, narrow-screen layout, reduced motion, and existing 44px target baseline. No new frontend dependency.

## No Analog Found

No new feature file has a missing analog. A typed Admin read-state result or a narrow internal replay-eligibility projection may be introduced if necessary; keep it at the existing Admin/inbound boundary and borrow result-state patterns from `RecordsList.data_state` plus the scoped detail/read-model query above.

## Metadata

**Analog search scope:** `mailglass_admin/lib/mailglass_admin`, `mailglass_admin/test/mailglass_admin`, `mailglass_inbound/lib/mailglass_inbound/internal`, `mailglass_inbound/lib/mailglass_inbound/execution.ex`, and `mailglass_inbound/test/mailglass_inbound`. All named source/test analogs were verified as git-tracked with `git ls-files`; no `.gsd` capability mirrors are referenced.  
**Pattern extraction date:** 2026-10-08
