# Phase 152: Atomic One-Click Suppression Convergence - Pattern Map

**Mapped:** 2026-08-03  
**Files analyzed:** 8 likely changed/new files  
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mailglass/compliance/unsubscribe_controller.ex` | controller | request-response | same file | exact |
| `lib/mailglass/compliance/unsubscribe_convergence.ex` (new, name discretionary) | service | CRUD / request-response | `lib/mailglass/webhook/ingest.ex` + `lib/mailglass/suppression/auto_suppress.ex` | flow-match |
| `lib/mailglass/lifecycle.ex` | behaviour / service | event-driven | same file + `lib/mailglass/outbound/projector.ex` | role-match |
| `lib/mailglass/suppression/auto_suppress.ex` (only if its helper API is generalized) | service | CRUD | same file | exact |
| `test/mailglass/compliance/unsubscribe_controller_test.exs` | integration test | request-response | same file | exact |
| `test/mailglass/properties/unsubscribe_post_idempotency_property_test.exs` | property test | concurrent / CRUD | `test/mailglass/properties/webhook_idempotency_convergence_test.exs` | flow-match |
| `test/mailglass/outbound/preflight_test.exs` | integration test | request-response | same file | exact |
| `test/mailglass/schema_prefix_hardening_test.exs` | integration test | file-I/O / CRUD | same file | exact |

No migration is indicated: the event idempotency partial unique index and the suppression `(tenant_id, address, scope, COALESCE(stream, ''))` uniqueness contract already provide the two convergence authorities.

## Pattern Assignments

### `lib/mailglass/compliance/unsubscribe_controller.ex` (controller, request-response)

**Analog:** `lib/mailglass/compliance/unsubscribe_controller.ex`

Keep token authority delivery-only and the deliberately audited unscoped initial lookup. The controller is the public privacy boundary; all valid, missing, expired, and tampered cases retain a byte-empty 200 except a real convergence failure.

**Token resolution and privacy no-op** (`lib/mailglass/compliance/unsubscribe_controller.ex:37-48,70-76`):
```elixir
def unsubscribe(conn, %{"token" => token}) do
  case resolve_delivery(token) do
    {:ok, delivery} ->
      delivery
      |> append_unsubscribe_event()
      |> respond_to_unsubscribe(conn, delivery)

    {:error, :expired} -> send_resp(conn, 200, "")
    {:error, :invalid} -> send_resp(conn, 200, "")
  end
end
```

**Narrow audited lookup, then tenant restoration** (`lib/mailglass/compliance/unsubscribe_controller.ex:80-95`):
```elixir
defp append_unsubscribe_event(%Delivery{} = delivery) do
  Tenancy.with_tenant(delivery.tenant_id, fn ->
    delivery |> unsubscribe_multi() |> Repo.multi()
  end)
end

defp fetch_delivery(delivery_id) do
  Tenancy.audit_unscoped_bypass(%{
    reason: :unsubscribe_token_delivery_lookup, resource: :delivery
  })
  Repo.get(Delivery, delivery_id, scope: :unscoped)
end
```

**Pitfall:** do not convert `fetch_delivery/1` to a tenant-scoped query before the tenant is derived, and do not accept recipient/stream from the token or request. Derive `tenant_id`, normalized recipient, and stream only from `%Delivery{}`.

### `lib/mailglass/compliance/unsubscribe_convergence.ex` (new service, CRUD/request-response)

**Analog:** `lib/mailglass/compliance/unsubscribe_controller.ex:97-131`, `lib/mailglass/suppression/auto_suppress.ex:48-77`

Create a small internal builder/service if that makes the post-commit result explicit; otherwise keep this shape private in the controller. It must build one flat `Ecto.Multi`, append/re-fetch the canonical event, insert-or-refetch the suppression with the existing uniqueness target, and report whether this request created the pair.

**Event insertion/replay sentinel** (`lib/mailglass/events.ex:131-153,179-188`):
```elixir
Ecto.Multi.new()
|> Events.append_multi(:unsubscribe_event, attrs)
|> Ecto.Multi.run(:unsubscribe_event_record, fn repo, changes ->
  {:ok, canonical_event(repo, changes.unsubscribe_event, delivery)}
end)

# `inserted_at == nil` means ON CONFLICT DO NOTHING for UUID events.
```

**The required prefix rule for every raw Multi callback operation** (`lib/mailglass/repo.ex:116-151`):
```elixir
# Repo.multi/1 does NOT inject prefix into inner Ecto.Multi SQL.
Ecto.Multi.insert(multi, :suppression, changeset,
  Repo.multi_opts(
    on_conflict: :nothing,
    conflict_target: {:unsafe_fragment, "(tenant_id, address, scope, COALESCE(stream, ''))"},
    returning: true
  )
)
# Every refetch inside Multi also needs Repo.multi_opts().
```

**Existing suppression shape** (`lib/mailglass/suppression/auto_suppress.ex:48-77`):
```elixir
%{scope: :address_stream, stream: stream, reason: :unsubscribe}

attrs
|> Entry.changeset()
|> repo.insert(Repo.multi_opts(
  on_conflict: :nothing,
  conflict_target: @conflict_target,
  returning: true
))
```

**Pitfalls:** `AutoSuppress` currently labels its row `"webhook:auto_suppress"`; one-click needs an honest bounded source/metadata without mutating replayed rows. Never use `SuppressionStore.Ecto.record/2` for the atomic path: its conflict action replaces mutable columns, while this phase needs conflict-safe immutable convergence plus canonical refetch. Do not rely on `Repo.multi/1` alone for prefix safety.

### `lib/mailglass/lifecycle.ex` (behaviour, event-driven)

**Analog:** `lib/mailglass/lifecycle.ex:1-35` and `lib/mailglass/outbound/projector.ex:132-175`

The old callback composes adopter work into the transaction:
```elixir
@callback handle_event(Ecto.Multi.t(), map()) :: Ecto.Multi.t()
```

The post-commit compatibility seam should be designed deliberately: transaction-side callback invocation cannot remain on this one-click path under D-11. Preserve unrelated callback compatibility where possible, but add/adapt a bounded post-commit callback result that cannot change the committed pair or the response.

**Post-commit broadcast precedent** (`lib/mailglass/outbound/projector.ex:132-175`):
```elixir
# Called AFTER Repo.transact/1 / Repo.multi/1 returns {:ok, _}.
_ = safe_broadcast(Mailglass.PubSub.Topics.events(tenant_id), payload)
_ = safe_broadcast(Mailglass.PubSub.Topics.events(tenant_id, delivery_id), payload)
:ok
```

`safe_broadcast/2` rescues `ArgumentError`/`RuntimeError` and catches exits (`lib/mailglass/outbound/projector.ex:192-224`), which is the required best-effort convention.

**Pitfall:** invoke lifecycle then projector only after a `{:ok, changes}` result, only when both facts were newly created by this request. Callback/broadcast failure must neither roll back, become HTTP 500, nor duplicate on replays or race losers. Payloads must contain bounded domain facts only—never the token or message content.

### `lib/mailglass/suppression/auto_suppress.ex` (service, CRUD; optional modification)

**Analog:** same file

If generalized rather than copied privately, preserve its Ecto.Multi callback-repo contract and expose only a narrow attributes/insert helper. `build_attrs/2` derives address/stream from trusted `%Delivery{}` and `Entry.changeset/1` normalizes address / enforces stream coupling (`lib/mailglass/suppression/entry.ex:81-115`).

Do not call `apply/2` blindly: it returns `:inserted` even for `on_conflict: :nothing`, so it is insufficient to decide whether this request may emit post-commit effects.

### `test/mailglass/compliance/unsubscribe_controller_test.exs` (integration, request-response)

**Analog:** `test/mailglass/properties/unsubscribe_post_idempotency_property_test.exs:132-161`

Retain the current router/endpoint setup and assert the public wire contract first:
```elixir
baseline_conn = Phoenix.ConnTest.post(Phoenix.ConnTest.build_conn(), path, %{})
assert Phoenix.ConnTest.response(baseline_conn, 200) == ""
```

Extend with focused examples for first POST, serial replay, invalid/expired/missing target privacy no-ops, real transaction failure returning a stable non-success, and lifecycle/broadcast failure after commit. Snapshot both `Event` and `Suppression.Entry`; assert exactly one each and no post-commit effect on rollback/replay.

### `test/mailglass/properties/unsubscribe_post_idempotency_property_test.exs` (property/concurrency test)

**Analog:** `test/mailglass/properties/webhook_idempotency_convergence_test.exs:35-79`; `test/mailglass/properties/idempotency_convergence_test.exs:124-177`

True concurrent POSTs require `use ExUnit.Case, async: false`, the sanctioned shared checkout, and committed behavior where needed. Copy the checkout discipline—not an ad-hoc Sandbox call:
```elixir
_owner = SandboxOwnership.checkout!(
  repo: TestRepo, shared: true, context: context,
  ownership_timeout: 10 * 60_000
)
```

Use parallel request tasks only after the shared checkout. Assert every response is exactly `200, ""`, the durable snapshot converges to one unsubscribe event + one `:address_stream` row, and callback/broadcast counters are one (or zero for races/replays). Keep `TRUNCATE ... CASCADE` cleanup for committed property rows; event UPDATE/DELETE is trigger-forbidden.

### `test/mailglass/outbound/preflight_test.exs` (integration, request-response)

**Analog:** `test/mailglass/outbound/preflight_test.exs:378-432,463-485`; `lib/mailglass/suppression.ex:30-64`

Prove enforcement by calling the real `Outbound.send/1` boundary after the POST, not by querying the suppression row alone. `Suppression.check_before_send/1` derives the key from the message’s sole recipient and stream:
```elixir
key = %{tenant_id: msg.tenant_id, address: address, stream: msg.stream}
result = store().check(key, [])
```

Required matrix: same tenant/address/origin stream is `%SuppressedError{}`; the same address on an unrelated stream and `:transactional` remain sendable. Include address case normalization.

### `test/mailglass/schema_prefix_hardening_test.exs` (integration, CRUD)

**Analog:** `test/mailglass/schema_prefix_hardening_test.exs:299-308`

Use the only sanctioned hostile-search-path seam:
```elixir
SandboxOwnership.with_search_path!("public", fun,
  repo: TestRepo, caller: __MODULE__)
```

Arrange decoy or absent `public` rows, run a valid one-click POST under hostile `search_path`, and assert both event and suppression live only in `Mailglass.Config.schema()`. Cover the conflict/refetch branch, because raw `repo.one!/2` inside `Ecto.Multi.run` is the easiest place to accidentally omit `Repo.multi_opts()`.

## Shared Patterns

### Tenant restoration and prefix safety

**Sources:** `lib/mailglass/compliance/unsubscribe_controller.ex:80-95`, `lib/mailglass/repo.ex:116-151`

Apply to the initial Delivery lookup versus all subsequent persistence: only the opaque-ID Delivery lookup is audited unscoped; tenant context begins immediately after resolution. In a Multi, prefix every insert, update, conflict resolution, and refetch with `Repo.multi_opts/1`.

### Durable idempotency

**Source:** `lib/mailglass/events.ex:131-153,174-213`

Event replay is `inserted_at == nil`, not `id == nil` (UUIDv7 is client-generated). The partial-index conflict fragment must remain character-for-character compatible. Suppression conflict also requires a refetch/canonical result and a separate created/replayed marker.

### Post-commit best-effort effects

**Source:** `lib/mailglass/outbound/projector.ex:132-224`

Run host lifecycle and PubSub only after a committed success, swallow/log only their expected failure modes, and use the durable ledger/suppression as truth. The transaction result must explicitly distinguish `created` from `already_converged`.

### Real send enforcement

**Sources:** `lib/mailglass/suppression.ex:30-64`, `lib/mailglass/suppression_store/ecto.ex:47-119`

Preflight matching includes stream only for `:address_stream`; it normalizes the lookup address and scopes the query with `Tenancy.scope(query, tenant_id)`. Tests must prove scope isolation through sends.

### Concurrency and hostile schema tests

**Sources:** `test/mailglass/properties/webhook_idempotency_convergence_test.exs:35-79`, `test/mailglass/schema_prefix_hardening_test.exs:299-308`, `test/support/data_case.ex:34-76`

Concurrent DB tests must be `async: false` with the sanctioned shared owner. Hostile `search_path` writes must go through `SandboxOwnership.with_search_path!/3`, which pins and restores the same pooled connection. Never change global application config from async cases.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/mailglass/compliance/unsubscribe_convergence.ex` | service | atomic convergence | No dedicated one-click convergence service exists; compose the existing controller/Event/AutoSuppress patterns. |

## Metadata

**Analog search scope:** `lib/mailglass/{compliance,events,repo,suppression,outbound}`, `test/mailglass/{compliance,properties,outbound}`, `test/support`  
**Files scanned:** 30+  
**Pattern extraction date:** 2026-08-03
