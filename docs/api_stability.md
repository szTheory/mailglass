# API Stability — mailglass

> This file documents the closed sets of values that form part of the public
> API contract. Adding a value requires a CHANGELOG entry plus an `@since`
> annotation on the new atom (minor version bump). Removing a value requires
> a major version bump.
>
> Automated tests in `test/mailglass/` assert that each error module's
> `__types__/0` function returns exactly the set documented here.

## Error Hierarchy

### `Mailglass.Error`

Namespace + behaviour module. Not a struct.

- `@type t` — union of the six error structs
- `@callback type(t()) :: atom()`
- `@callback retryable?(t()) :: boolean()`
- Helpers: `is_error?/1`, `kind/1`, `retryable?/1`, `root_cause/1`

Since: 0.1.0.

### `Mailglass.SendError`

Raised when email delivery fails.

Type atom set (per `Mailglass.SendError.__types__/0`):

- `:adapter_failure`
- `:rendering_failed`
- `:preflight_rejected`
- `:serialization_failed`

Per-kind fields: `delivery_id :: binary() | nil`.

Retryable: `true` for `:adapter_failure`, `false` otherwise.

Since: 0.1.0.

### `Mailglass.TemplateError`

Raised when a template cannot be compiled or rendered.

Type atom set:

- `:heex_compile`
- `:missing_assign`
- `:helper_undefined`
- `:inliner_failed`

Per-kind fields: none.

Retryable: `false`.

Since: 0.1.0.

### `Mailglass.SignatureError`

Raised when webhook signature verification fails.

Type atom set:

- `:missing`
- `:malformed`
- `:mismatch`
- `:timestamp_skew`

Per-kind fields: `provider :: atom() | nil`.

Retryable: `false` (the caller is misconfigured or the request is a forgery).

Since: 0.1.0.

### `Mailglass.SuppressedError`

Raised when delivery is blocked by the suppression list. Atom set mirrors
`Mailglass.Suppression.scope` (lands Phase 2) for a 1:1 pattern match.

Type atom set:

- `:address`
- `:domain`
- `:address_stream`

Per-kind fields: none.

Retryable: `false` (permanent policy block).

**Pre-0.1.0 refinement (D-09):** the atom set was refined from
`:tenant_address` → `:address_stream` before 0.1.0 shipped to match the
`mailglass_suppressions.scope` column. No deprecation cycle owed because
0.1.0 has not shipped.

Since: 0.1.0.

### `Mailglass.RateLimitError`

Raised when a rate limit is exceeded.

Type atom set:

- `:per_domain`
- `:per_tenant`
- `:per_stream`

Per-kind fields: `retry_after_ms :: non_neg_integer()` (default `0`).

Retryable: `true` — caller waits `retry_after_ms` and retries.

Since: 0.1.0.

### `Mailglass.ConfigError`

Raised when mailglass is misconfigured. `Mailglass.Config.validate_at_boot!/0`
(Plan 03) raises this at application startup.

Type atom set:

- `:missing`
- `:invalid`
- `:conflicting`
- `:optional_dep_missing`

Per-kind fields: none.

Retryable: `false` — fix config and restart.

Since: 0.1.0.

### `Mailglass.EventLedgerImmutableError`

Raised when the `mailglass_events` immutability trigger fires
(SQLSTATE 45A01). Translation happens inside `Mailglass.Repo.transact/1`
— callers never see the raw `%Postgrex.Error{}`.

Type atom set:

- `:update_attempt`
- `:delete_attempt`

Per-kind fields: `pg_code :: String.t()` (always `"45A01"`).

Retryable: `false` (append-only invariant; the calling code has a bug).

**Translator asymmetry (Phase 2, IN-03):** both atoms are part of the
closed type set and stable, but the v0.1 translator in
`Mailglass.Repo.infer_immutability_type/1` always emits
`:update_attempt`. The Postgrex error message is not a stable public
API, and the v0.1 trigger function is shared between UPDATE and DELETE
rule violations. `:delete_attempt` is reserved for a future Phase 4+
refinement that distinguishes the two actions (either via dedicated
trigger functions per action, or by pattern-matching the constraint
name) when webhook-path DELETE-attempt telemetry becomes valuable.
Callers pattern-matching today should match either atom
(`err.type in [:update_attempt, :delete_attempt]`) to stay forward-
compatible.

Since: 0.1.0.

### `Mailglass.TenancyError`

Raised by `Mailglass.Tenancy.tenant_id!/0` when no tenant has been
stamped on the current process via `Mailglass.Tenancy.put_current/1`.

Type atom set:

- `:unstamped`

Per-kind fields: none.

Retryable: `false` (the caller failed to establish tenant context).

Since: 0.1.0.

## Shared Error Serialization

Every error struct derives:

    @derive {Jason.Encoder, only: [:type, :message, :context]}

The `:cause` field is deliberately excluded to prevent recursive emission of
adapter structs that may carry provider payloads with recipient PII (T-PII-002).
Adopters that need the full cause chain walk it explicitly via
`Mailglass.Error.root_cause/1`.

## §Telemetry Extensions (Phase 3)

### New named span helpers

Added in Phase 3 (D-26). All delegate to `Mailglass.Telemetry.span/3`.

- `send_span(map(), (-> any())) :: any()` — emits `[:mailglass, :outbound, :send, :start | :stop | :exception]`.
- `dispatch_span(map(), (-> any())) :: any()` — emits `[:mailglass, :outbound, :dispatch, :start | :stop | :exception]`.
- `persist_outbound_multi_span(map(), (-> any())) :: any()` — emits `[:mailglass, :persist, :outbound, :multi, :start | :stop | :exception]`.

### New logged events (Phase 3)

Added to `@logged_events` for the default logger handler:

```
[:mailglass, :outbound, :send, :stop | :exception]
[:mailglass, :outbound, :dispatch, :stop | :exception]
[:mailglass, :outbound, :suppression, :stop]
[:mailglass, :outbound, :rate_limit, :stop]
[:mailglass, :outbound, :stream_policy, :stop]
[:mailglass, :persist, :outbound, :multi, :stop | :exception]
```

Metadata whitelist per D-31: `:tenant_id, :mailable, :stream, :delivery_id, :status, :provider, :latency_ms, :step_name, :allowed, :hit, :duration_us`.

Since: 0.1.0.

## §Repo.multi (Phase 3)

### `Mailglass.Repo.multi/1,2`

Added in Phase 3 (I-02). Executes an `Ecto.Multi` against the host-configured repo.

Locked signature: `@spec multi(Ecto.Multi.t(), keyword()) :: {:ok, map()} | {:error, atom(), any(), map()}`

Raises `%ConfigError{type: :missing}` when `:repo` is not configured. SQLSTATE 45A01 is translated via the same path as other write helpers.

Since: 0.1.0.

## §Events.append_multi function-form (Phase 3)

### Function-form attrs (I-03)

`Mailglass.Events.append_multi/3` now accepts `attrs :: map() | (map() -> map())`. When `attrs` is a 1-arity function, it is called inside a `Multi.run` step with the prior `changes` map. The intermediate step is named `:"<name>_attrs"`.

Since: 0.1.0.

## §PubSub (Phase 3)

### `Mailglass.PubSub`

Reserved name atom for the mailglass-owned `Phoenix.PubSub` child. The supervision tree starts `{Phoenix.PubSub, name: Mailglass.PubSub}`. This is the only valid name for mailglass-internal broadcasts.

Since: 0.1.0.

### `Mailglass.PubSub.Topics`

The only public topic builders. All outputs are prefixed `mailglass:` — Phase 6 `LINT-06 PrefixedPubSubTopics` enforces this at lint time.

- `events/1 :: String.t()` — `"mailglass:events:#{tenant_id}"` — tenant-wide event stream.
- `events/2 :: String.t()` — `"mailglass:events:#{tenant_id}:#{delivery_id}"` — per-delivery stream.
- `deliveries/1 :: String.t()` — `"mailglass:deliveries:#{tenant_id}"` — delivery-list stream.

Since: 0.1.0.

## §BatchFailed (Phase 3)

### `Mailglass.Error.BatchFailed`

Raised by `Mailglass.Outbound.deliver_many!/2` when one or more deliveries fail. Never raised by `deliver_many/2`.

Type atom set (per `Mailglass.Error.BatchFailed.__types__/0`):

- `:partial_failure` — at least one Delivery succeeded AND at least one failed
- `:all_failed` — every Delivery failed

Per-kind fields: `failures :: [Mailglass.Outbound.Delivery.t()]` — failed deliveries only. Excluded from JSON output (`@derive {Jason.Encoder, only: [:type, :message, :context]}`).

Retryable: `true` — individual deliveries may retry.

Since: 0.1.0.

## §ConfigError Extensions (Phase 3)

Two new atoms added to `Mailglass.ConfigError.__types__/0`:

- `:tracking_on_auth_stream` — (D-38, Phase 3) tracking enabled on a mailable whose function name matches an auth-stream heuristic. Forbidden at compile time via `NoTrackingOnAuthStream` Credo check (Phase 6).
- `:tracking_host_missing` — (D-32, Phase 3) a mailable enables opens or clicks but no tracking host is configured. Required for link rewriting.

Full type atom set is now: `[:missing, :invalid, :conflicting, :optional_dep_missing, :tracking_on_auth_stream, :tracking_host_missing]`.

Since: 0.1.0 (atoms added in Phase 3).

## §Message Extensions (Phase 3)

### `:mailable_function` field

Added in Phase 3. `atom() | nil`, default `nil`. Populated by the `use Mailglass.Mailable` macro's injected builder (D-38). Used by the runtime auth-stream tracking guard.

### `Mailglass.Message.put_metadata/3`

Locked signature: `@spec put_metadata(Message.t(), atom(), any()) :: Message.t()`

Returns a new `%Message{}` with `metadata[key] = value`. Used by the send pipeline (Plan 05) to stamp `delivery_id` after the Delivery row is inserted but before the adapter is called.

Since: 0.1.0.

## §Clock

### `Mailglass.Clock`

The single legitimate source of wall-clock time in mailglass (TEST-05).

- `Mailglass.Clock.utc_now/0 :: DateTime.t()` — three-tier resolution: process-frozen → configured impl → `Mailglass.Clock.System`.

Since: 0.1.0.

### `Mailglass.Clock.System`

Production impl. `utc_now/0` delegates to `DateTime.utc_now/0`.

Since: 0.1.0.

### `Mailglass.Clock.Frozen` (test-only)

Per-process clock freeze helper. Safe for `async: true` tests — frozen state is process-local.

- `freeze(DateTime.t()) :: DateTime.t()` — stamps the process dict and returns the frozen value.
- `advance(integer()) :: DateTime.t()` — advances the frozen time by `ms` milliseconds. Seeds from wall clock if no freeze is active.
- `unfreeze() :: :ok` — clears the process-dict freeze key.

**Convention:** `Mailglass.Clock.Frozen` is test-only. Calling `freeze/1` from production code paths is a bug. Phase 6 LINT-12 (`NoDirectDateTimeNow`) enforces this at lint time.

Since: 0.1.0.

## §Tenancy Extensions (Phase 3)

### `Mailglass.Tenancy.assert_stamped!/0`

- `assert_stamped!() :: :ok` — raises `%TenancyError{type: :unstamped}` when no tenant is stamped on the current process. Returns `:ok` otherwise. Does NOT fall back to the `SingleTenant` default (unlike `current/0`). SEND-01 precondition (D-18).

Since: 0.1.0.

### `Mailglass.Tenancy` optional callback: `c:tracking_host/1`

- `@callback tracking_host(context :: term()) :: {:ok, String.t()} | :default` — optional per-tenant tracking host override (D-32). Default resolution: `:default` (use global `config :mailglass, :tracking, host:`). Adopters returning `{:ok, host}` get per-tenant subdomains for strict cookie/origin isolation.

Since: 0.1.0.

## §Adapter (Phase 3)

### `Mailglass.Adapter` behaviour

Shipped in Phase 3 Plan 02 (TRANS-01). Single-callback behaviour every mailglass adapter implements.

**Locked callback signature:**

```elixir
@callback deliver(Mailglass.Message.t(), keyword()) ::
            {:ok, %{message_id: String.t(), provider_response: term()}} | {:error, Mailglass.Error.t()}
```

**Return shape contract:**

- `{:ok, %{message_id: String.t(), provider_response: term()}}` on success.
  `:message_id` is the adapter's canonical identifier — Phase 4 webhook ingest uses it to join
  incoming events to the `%Delivery{}` row via `provider_message_id`.
- `{:error, Mailglass.Error.t()}` on failure. Return struct must be a subtype of `%Mailglass.Error{}`
  — callers pattern-match by struct, never by message string. `%Mailglass.SendError{type: :adapter_failure}`
  is the canonical wrap for downstream provider errors.

Changes to the callback signature are semver-breaking. Adopters implement custom adapters by
conforming to this behaviour.

**In-repo implementations:**

- `Mailglass.Adapters.Fake` (TRANS-02) — in-memory, merge-blocking release gate (D-13).
- `Mailglass.Adapters.Swoosh` (TRANS-03) — wraps any `Swoosh.Adapter`, normalizes errors.

Since: 0.1.0.

### `Mailglass.Adapters.Swoosh`

Bridges to any `Swoosh.Adapter` (Postmark, SendGrid, Mailgun, SES, Resend, SMTP).

**Error mapping table:**

| Swoosh error shape | Mapped `SendError` `:type` | Context keys |
|--------------------|---------------------------|--------------|
| `{:api_error, status, body}` | `:adapter_failure` | `provider_status`, `body_preview` (200 bytes), `provider_module`, `reason_class` |
| `{:error, :timeout}` | `:adapter_failure` | `provider_module`, `reason_class: :transport` |
| `{:error, {:tls_alert, _}}` | `:adapter_failure` | `provider_module`, `reason_class: :transport` |
| `{:error, other}` | `:adapter_failure` | `provider_module`, `reason_class: :other` |

**`reason_class` atoms:** `:server_error` (5xx), `:client_error` (4xx), `:unknown` (other status),
`:transport` (timeout/TLS), `:other` (unclassified).

**PII policy:** The 8 forbidden keys (`:to, :from, :body, :html_body, :subject, :headers, :recipient, :email`)
NEVER appear in error context. `body_preview` is a 200-byte head of the provider response body —
provider-emitted strings only, never user-supplied content. Phase 6 LINT-02 enforces.

Does NOT call `Swoosh.Mailer.deliver/1` — LINT-01 forbidden. Calls `Swoosh.Adapter.deliver/2`
(the behaviour callback) directly. Pure: no DB, no PubSub, no GenServer.

Since: 0.1.0.

## §Fake (Phase 3)

### `Mailglass.Adapters.Fake`

In-memory, time-advanceable test adapter (TRANS-02, D-01..D-03). The merge-blocking release gate (D-13).

**Stored record shape** (JSON-compatible per TRANS-02):

```elixir
%{
  message: %Mailglass.Message{},
  delivery_id: Ecto.UUID.t(),
  provider_message_id: String.t(),
  recorded_at: DateTime.t()
}
```

**Locked public API:**

| Function | Signature | Description |
|----------|-----------|-------------|
| `deliveries/0,1` | `(keyword()) :: [map()]` | List recorded deliveries; opts: `:owner`, `:tenant`, `:mailable`, `:recipient` |
| `last_delivery/0,1` | `(keyword()) :: map() \| nil` | Most recently inserted delivery |
| `clear/0,1` | `(keyword() \| :all) :: :ok` | Wipe owner bucket; `:all` flushes entire ETS table |
| `trigger_event/3` | `(String.t(), atom(), keyword()) :: {:ok, Event.t()} \| {:error, term()}` | Simulate webhook event via real write path |
| `advance_time/1` | `(integer()) :: DateTime.t()` | Advances process-local frozen clock (delegates to `Clock.Frozen.advance/1`) |
| `checkout/0` | `() :: :ok` | Register current process as owner |
| `checkin/0` | `() :: :ok` | Unregister current process as owner |
| `allow/2` | `(pid(), pid()) :: :ok` | Allow `allowed_pid` to deliver into `owner_pid`'s bucket |
| `set_shared/1` | `(pid() \| nil) :: :ok` | Set global shared owner (for non-async E2E tests) |
| `get_shared/0` | `() :: pid() \| nil` | Returns current shared owner |

**ETS table name:** `:mailglass_fake_mailbox` — library-reserved. Adopters must not register a
process or table under this name.

**GenServer name:** `Mailglass.Adapters.Fake.Storage` — library-reserved singleton (LINT-07
exception: library-internal per D-02). Unconditionally started by `Mailglass.Application`.

**`trigger_event/3` write-path guarantee (D-03):** Looks up the `%Delivery{}` by
`provider_message_id`, then runs `Events.append_multi/3 + Projector.update_projections/2` inside
`Repo.multi/1` — the SAME write path Phase 4 webhook ingest uses. The Fake proves the production
write path in every CI run.

**Ownership model:** Mirrors `Swoosh.Adapters.Sandbox`. Each test process is its own owner via
`checkout/0`. `$callers` inheritance (Task.async) works automatically. Cross-process delegation
(LiveView, Oban workers, Playwright) uses `allow/2`. Global mode uses `set_shared/1`.

Since: 0.1.0.

## §Projector.broadcast_delivery_updated (Phase 3)

### `Mailglass.Outbound.Projector.broadcast_delivery_updated/3`

Locked signature: `@spec broadcast_delivery_updated(Delivery.t(), atom(), map()) :: :ok`

**Payload shape:** `{:delivery_updated, delivery_id :: binary, event_type :: atom, meta :: map}`

**Broadcast topics (SEND-05, D-27):**
- `Mailglass.PubSub.Topics.events(tenant_id)` — tenant-wide stream
- `Mailglass.PubSub.Topics.events(tenant_id, delivery_id)` — per-delivery stream

**Semantics:** Best-effort, fire-and-forget. Broadcast failure NEVER rolls back (broadcast runs
AFTER `Repo.transact/1` commits). If Phoenix.PubSub is unreachable, logs a debug message and
returns `:ok`. The event ledger is the durable source of truth; PubSub is the realtime fan-out.

**Callers:**
- `Mailglass.Outbound.send/2` (Plan 05 Multi#2 success path)
- `Mailglass.Outbound.Worker.perform/1` (Plan 05 async Multi#2 success)
- `Mailglass.Adapters.Fake.trigger_event/3` (after its own `Repo.multi/1` commits)
- `Mailglass.Webhook.Plug` (Phase 4 — after webhook Multi commits)

Since: 0.1.0.
