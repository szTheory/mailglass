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

## §RateLimiter (Phase 3 Plan 03)

### `Mailglass.RateLimiter.check/3`

Locked signature: `@spec check(String.t(), String.t(), atom()) :: :ok | {:error, Mailglass.RateLimitError.t()}`

**`:transactional` bypass invariant (D-24):** When `stream == :transactional`, `check/3` returns `:ok`
immediately WITHOUT reading ETS. This is a reserved invariant — NOT a tunable. Password-reset,
magic-link, and verify-email flows MUST NOT be throttled by bulk campaign saturation.

**Token bucket math (D-23):** Continuous leaky-bucket refill at `per_minute / 60_000` tokens/ms.
Default: 100 capacity @ 100/min. After an over-limit event (counter at -1), refill restores the
bucket on the next call using `restore + elapsed_refill` delta, capped at `capacity`.

**Configuration shape:**

```elixir
config :mailglass, :rate_limit,
  default: [capacity: 100, per_minute: 100],
  overrides: [
    {{"tenant-id", "domain.com"}, [capacity: 500, per_minute: 500]}
  ]
```

Missing `:rate_limit` key uses built-in defaults (`capacity: 100, per_minute: 100`).

**Telemetry:** Single-emit `[:mailglass, :outbound, :rate_limit, :stop]`
- Measurements: `%{duration_us: integer()}`
- Metadata: `%{allowed: boolean(), tenant_id: String.t()}` — no recipient domain (D-31 PII whitelist)

Since: 0.1.0.

### `Mailglass.RateLimiter.Supervisor` (library-reserved singleton)

Registered under `name: __MODULE__` (`Mailglass.RateLimiter.Supervisor`). Library-internal machinery.
Started unconditionally by `Mailglass.Application` via `Code.ensure_loaded?/1` gate (I-08).

Phase 6 `LINT-07 NoDefaultModuleNameSingleton` has an allowlist entry for this module.

Since: 0.1.0.

### `:mailglass_rate_limit` ETS table (library-reserved)

Named ETS table owned by `Mailglass.RateLimiter.TableOwner`. Key shape: `{tenant_id, domain}`.
Value shape: `{key, tokens :: integer(), last_refill_ms :: integer()}`.

OTP 27 opts: `:set, :public, :named_table, read_concurrency: true, write_concurrency: :auto, decentralized_counters: true`.

Adopters MUST NOT register a process or table under this name. Crash semantics (D-22): if
`TableOwner` crashes, BEAM deletes the table; supervisor restarts and recreates it empty.
Counter reset is acceptable — worst case is 1 minute of burst allowance.

### `Mailglass.RateLimiter.TableOwner` (library-reserved singleton)

Registered under `name: __MODULE__` (`Mailglass.RateLimiter.TableOwner`). Init-and-idle GenServer —
no `handle_call/3`, `handle_cast/2`, or `handle_info/2`. All hot-path reads/writes happen directly
from caller processes via `:ets.update_counter/4`.

Phase 6 `LINT-07 NoDefaultModuleNameSingleton` has an allowlist entry for this module.

Since: 0.1.0.

## §SuppressionStore.ETS (Phase 3 Plan 03)

### `Mailglass.SuppressionStore.ETS`

ETS-backed implementation of `Mailglass.SuppressionStore` (D-28). Behaviour parity with
`Mailglass.SuppressionStore.Ecto` — same `check/2` and `record/2` contract.

**Locked behaviour callbacks:**

```elixir
@callback check(lookup_key(), keyword()) ::
            {:suppressed, Entry.t()} | :not_suppressed | {:error, term()}
@callback record(record_attrs(), keyword()) ::
            {:ok, Entry.t()} | {:error, term()}
```

**Lookup algorithm (3-branch OR-union, matching Ecto):**
1. `{tenant_id, address, :address, nil}` — address scope
2. `{tenant_id, domain, :domain, nil}` — domain scope
3. `{tenant_id, address, :address_stream, stream}` — only when stream is provided

**UPSERT behaviour:** `record/2` with same key `{tenant_id, address, scope, stream}` overwrites
the existing entry (equivalent to Ecto's `on_conflict: {:replace, [...]}`).

**Expiry filter:** expired entries (where `expires_at < Clock.utc_now()`) are silently skipped
at read time — they are NOT returned by `check/2`.

**Test override pattern:** configure via `Application.put_env/3` in test `setup`, restore in
`on_exit`. Scope tests by unique `tenant_id` to avoid cross-test leakage. Call `reset/0` in
`setup` for a guaranteed clean slate.

**`reset/0` (test-only helper):** `@spec reset() :: :ok` — clears all entries from the ETS
suppression table. MUST NOT be called from production code.

Since: 0.1.0.

### `:mailglass_suppression_store` ETS table (library-reserved)

Named ETS table owned by `Mailglass.SuppressionStore.ETS.TableOwner`. Key shape:
`{tenant_id, address, scope, stream_or_nil}`. Value shape: `{key, %Mailglass.Suppression.Entry{}}`.

OTP 27 opts: `:set, :public, :named_table, read_concurrency: true, write_concurrency: :auto`.

Adopters MUST NOT register a process or table under this name. Crash semantics (D-22): if
`TableOwner` crashes, BEAM deletes the table; supervisor restarts and recreates it empty.

### `Mailglass.SuppressionStore.ETS.Supervisor` (library-reserved singleton)

Registered under `name: __MODULE__`. Library-internal machinery. Started unconditionally by
`Mailglass.Application` via `Code.ensure_loaded?/1` gate (I-08).

Phase 6 `LINT-07 NoDefaultModuleNameSingleton` has an allowlist entry for this module.

Since: 0.1.0.

### `Mailglass.SuppressionStore.ETS.TableOwner` (library-reserved singleton)

Registered under `name: __MODULE__`. Init-and-idle GenServer — no `handle_call/3`,
`handle_cast/2`, or `handle_info/2`.

Phase 6 `LINT-07 NoDefaultModuleNameSingleton` has an allowlist entry for this module.

Since: 0.1.0.

## §Suppression (Phase 3 Plan 03)

### `Mailglass.Suppression.check_before_send/1`

Locked signature: `@spec check_before_send(Mailglass.Message.t()) :: :ok | {:error, Mailglass.SuppressedError.t()}`

**Store-indirection pattern:** Delegates to the module configured at runtime via:

```elixir
Application.get_env(:mailglass, :suppression_store, Mailglass.SuppressionStore.Ecto)
```

Default is `Mailglass.SuppressionStore.Ecto`. Tests override to `Mailglass.SuppressionStore.ETS`
for in-memory speed.

**Recipient extraction:** Reads `msg.swoosh_email.to` — first element (primary recipient).
Returns `""` when the `to` list is empty (store will return `:not_suppressed`).

**Return shape:**
- `:ok` — recipient is not suppressed
- `{:error, %SuppressedError{type: scope}}` — recipient is suppressed; `scope` is `:address | :domain | :address_stream`
- `{:error, term()}` — store infrastructure failure (passed through)

**Telemetry:** Single-emit `[:mailglass, :outbound, :suppression, :stop]`
- Measurements: `%{duration_us: integer()}`
- Metadata: `%{hit: boolean(), tenant_id: String.t()}` — no PII (D-31 whitelist)

**`SuppressedError` context keys:** `%{tenant_id: String.t(), stream: atom()}` — no recipient
address, no email headers. (T-3-03-02 mitigation.)

Since: 0.1.0.

## §Stream (Phase 3 Plan 03)

### `Mailglass.Stream.policy_check/1`

Locked signature: `@spec policy_check(Mailglass.Message.t()) :: :ok`

**No-op at v0.1.** Returns `:ok` for all valid streams (`:transactional | :operational | :bulk`).
Pattern-matches on `%Mailglass.Message{}` only — passing a raw map raises `FunctionClauseError`.

**v0.5 DELIV-02 contract stability:** The v0.5 implementation swaps this no-op in place.
The function signature, telemetry event name, and return type are stable across the swap.
Callers in `Mailglass.Outbound.send/2` do not change. Do not extend this module from adopter
code — the implementation contract is internal.

**Telemetry:** Single-emit `[:mailglass, :outbound, :stream_policy, :stop]`
- Measurements: `%{duration_us: integer()}`
- Metadata: `%{tenant_id: String.t(), stream: atom()}` — no PII (D-31 whitelist)

Stream atom is enum-narrow (one of three known values) — not recipient-identifying.

Since: 0.1.0.

## §Mailable (Phase 3 Plan 04)

### `Mailglass.Mailable` behaviour

Shipped in Phase 3 Plan 04 (AUTHOR-01). The adopter entry point — `use Mailglass.Mailable, stream: …`
injects the mailable boilerplate in ≤20 top-level AST forms.

**Locked behaviour callbacks:**

```elixir
@callback new() :: Mailglass.Message.t()
@callback render(Mailglass.Message.t(), atom(), map()) ::
            {:ok, Mailglass.Message.t()} | {:error, Mailglass.TemplateError.t()}
@callback deliver(Mailglass.Message.t(), keyword()) ::
            {:ok, term()} | {:error, Mailglass.Error.t()}
@callback deliver_later(Mailglass.Message.t(), keyword()) ::
            {:ok, term()} | {:error, Mailglass.Error.t()}
@optional_callbacks preview_props: 0
@callback preview_props() :: [{atom(), map()}]
```

**`preview_props/0` is optional.** Adopters who want Phase 5 admin preview discovery implement it;
omitting it produces no compiler warning.

**`defoverridable` surface (stable):** `new/0`, `render/3`, `deliver/2`, `deliver_later/2` — all
four injected functions are overridable via `defoverridable`. Adopters who override `deliver/2` to
bypass `Mailglass.Outbound` lose telemetry + projection writes (T-3-04-04 accepted risk; documented).

### `use` opts vocabulary (compile-time tier, D-11)

The locked `use` opts passed to `use Mailglass.Mailable`:

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `:stream` | `:transactional \| :operational \| :bulk` | `:transactional` | Compile-time stream classification. Required for Phase 6 LINT AST check. |
| `:tracking` | `[opens: boolean, clicks: boolean]` | `[]` (all false) | Open/click tracking opt-in (TRACK-01, D-08). Off by default. Phase 6 TRACK-02 + Phase 3 Guard enforce. |
| `:from_default` | `{name :: String.t(), address :: String.t()} \| nil` | `nil` | Default `from` header applied at `new/0` time. Per-call `Swoosh.Email.from/2` overrides. |
| `:reply_to_default` | `{name :: String.t(), address :: String.t()} \| nil` | `nil` | Default Reply-To header applied at `new/0` time. |

Adding new `use` opts is semver-minor. Removing or changing the type of an existing opt is
semver-major.

### Injection budget (LINT-05, D-09)

`__using__/1` injects exactly 12 top-level AST forms (budget: ≤20 per LINT-05; target: 15 per D-09).
Phase 6 `NoOversizedUseInjection` Credo check enforces this at lint time. A runtime AST-counting
test in `test/mailglass/mailable_test.exs` asserts the budget on every CI run.

**What is injected:**
1. `@behaviour Mailglass.Mailable`
2. `@before_compile Mailglass.Mailable`
3. `@mailglass_opts opts`
4. `@compile {:no_warn_undefined, Mailglass.Outbound}` (forward-ref guard until Plan 05)
5. `import Swoosh.Email, except: [new: 0]`
6. `import Mailglass.Components`
7. `def __mailglass_opts__/0`
8. `def new/0`
9. `def render/3`
10. `def deliver/2`
11. `def deliver_later/2`
12. `defoverridable new: 0, render: 3, deliver: 2, deliver_later: 2`

**What is NOT injected:** `import Phoenix.Component` (adopters opt in per-mailable to avoid HEEx
collision), `preview_props/0` default, module attributes `@subject` / `@from` (D-11 rationale).

### `__mailglass_opts__/0` reflection contract

Every module compiled with `use Mailglass.Mailable` exposes:

```elixir
@spec __mailglass_opts__() :: keyword()
```

Returns the keyword list passed to `use`. Phase 6 Credo reads this via AST introspection of the
`@mailglass_opts` attribute. Phase 3 `Mailglass.Tracking.Guard.assert_safe!/1` reads it at runtime
via `module.__mailglass_opts__()`.

**Stability:** This function is library-internal machinery. Adopters MUST NOT define
`def __mailglass_opts__` manually outside `use Mailglass.Mailable` — Phase 6 LINT will catch this.

### `__mailglass_mailable__/0` discovery marker

Every module compiled with `use Mailglass.Mailable` exposes:

```elixir
@spec __mailglass_mailable__() :: true
```

Always returns `true`. Phase 5 admin dashboard discovers mailable modules by probing
`function_exported?(mod, :__mailglass_mailable__, 0)` across loaded modules.

**Stability:** Locked. Must return `true` — Phase 5 admin uses this as a boolean gate.

Since: 0.1.0.

## §Message Helpers (Phase 3 Plan 04)

Three new helpers added to `Mailglass.Message`:

### `Mailglass.Message.new_from_use/2`

```elixir
@spec new_from_use(module(), keyword()) :: Mailglass.Message.t()
```

Creates a `%Mailglass.Message{}` from a mailable module and its `use` opts. Called by the
injected `new/0` function. Seeds `:stream`, `:mailable`, `:tenant_id` from opts; applies
`:from_default` to the inner `%Swoosh.Email{}` when present.

Since: 0.1.0.

### `Mailglass.Message.update_swoosh/2`

```elixir
@spec update_swoosh(Message.t(), (Swoosh.Email.t() -> Swoosh.Email.t())) :: Message.t()
```

Applies a transformation function to the inner `%Swoosh.Email{}`. Adopters use this to pipe
through Swoosh builder functions while keeping the `%Message{}` wrapper intact. The canonical
pattern for building mailable functions:

```elixir
def welcome(user) do
  new()
  |> Mailglass.Message.update_swoosh(fn e ->
       e
       |> Swoosh.Email.to(user.email)
       |> Swoosh.Email.subject("Welcome!")
     end)
  |> Mailglass.Message.put_function(:welcome)
end
```

Since: 0.1.0.

### `Mailglass.Message.put_function/2`

```elixir
@spec put_function(Message.t(), atom()) :: Message.t()
```

Stamps the `:mailable_function` field. Required for the D-38 runtime tracking guard
(`Mailglass.Tracking.Guard.assert_safe!/1`) to perform its auth-stream heuristic check.
Adopters who omit `put_function/2` get `mailable_function: nil` — the Guard returns `:ok`
(can't check without the function name); Phase 6 Credo TRACK-02 catches this statically.

Since: 0.1.0.

## §Tracking (Phase 3 Plan 04)

### `Mailglass.Tracking.enabled?/1`

```elixir
@spec enabled?(mailable: module()) :: %{opens: boolean(), clicks: boolean()}
```

Returns the compile-time tracking flags for a mailable module. Reads
`module.__mailglass_opts__/0` to inspect the `tracking:` keyword list from `use` opts.

**Off-by-default semantics (TRACK-01):** Returns `%{opens: false, clicks: false}` for:
- Modules without `use Mailglass.Mailable` (no `__mailglass_opts__/0` exported)
- Modules with `use Mailglass.Mailable` but no `tracking:` opt (default is all false)

**Locked return shape:** Always a two-key map with `:opens` and `:clicks` boolean values.
Used by Plan 06's `Mailglass.Tracking.Rewriter` (pixel injection + link rewriting) and by
`Mailglass.Tracking.Guard.assert_safe!/1` (D-38 runtime enforcement).

Since: 0.1.0.

### `Mailglass.Tracking.Guard.assert_safe!/1`

```elixir
@spec assert_safe!(Mailglass.Message.t()) :: :ok
```

Raises `%Mailglass.ConfigError{type: :tracking_on_auth_stream}` when the mailable's
compile-time tracking opts enable opens or clicks AND the `mailable_function` field
matches the auth-stream regex. Returns `:ok` otherwise.

**Locked contract:** Returns `:ok` or raises — no `{:error, _}` return path. This is a
fail-loud guard, not a preflight stage.

**Auth-stream regex (locked):** `^(magic_link|password_reset|verify_email|confirm_account)`

Matches the four canonical auth-carrying function-name prefixes. Variant names starting
with these prefixes (e.g. `magic_link_verify_otp`, `password_reset_confirm`) ALSO match —
prefix matching prevents Outlook SafeLinks pre-fetch from triggering auth-stream tracking.

Adding new prefix patterns to the regex is **semver-minor** (new mailables are newly
prevented from enabling tracking). Removing patterns is **semver-major**.

**`nil` mailable_function (T-3-04-01):** When `mailable_function` is `nil`, the guard
returns `:ok` — it cannot perform the heuristic without a function name. Phase 6 Credo
`TRACK-02 NoTrackingOnAuthStream` is the primary enforcement for this case via AST
inspection of the mailable module's function heads.

**Error context (PII-free, T-3-04-03):**
```elixir
%Mailglass.ConfigError{
  type: :tracking_on_auth_stream,
  context: %{
    mailable: MyApp.UserMailer,   # module atom — not PII
    function: :magic_link         # function atom — not PII
  }
}
```

**Dual enforcement layers:**
1. Phase 6 `TRACK-02 NoTrackingOnAuthStream` Credo check — compile-time, catches static patterns.
2. `Mailglass.Tracking.Guard.assert_safe!/1` — runtime, catches dynamically-named mailables.

**Callers:** `Mailglass.Outbound.send/2` (Plan 05) — called as a precondition before
the Delivery row is inserted.

Since: 0.1.0.

## §Delivery — idempotency_key + status + last_error (Phase 3 Plan 05)

### New fields on `Mailglass.Outbound.Delivery` (I-01, Task 1)

**`:idempotency_key`** — nullable text field added in Phase 3 Plan 05.

- Shape: any binary. `Mailglass.Outbound.send/2` computes
  `sha256(tenant_id | mailable | recipient | content_hash)` (D-15). Adopters may
  supply any string; the partial UNIQUE index enforces uniqueness only when non-nil.
- Partial UNIQUE index: `mailglass_deliveries_idempotency_key_unique_idx`
  ON `(idempotency_key) WHERE idempotency_key IS NOT NULL`.
  The WHERE predicate matches the `conflict_target` fragment
  `"(idempotency_key) WHERE idempotency_key IS NOT NULL"` used by
  `deliver_many/2` — character-for-character (Pitfall 1).

**`:status`** — `Ecto.Enum` field with values `:queued | :sent | :dispatched | :failed | :suppressed`.
Default: `:queued` (NOT NULL at the DB layer). This is the stable public snapshot adopters
pattern-match on (ROADMAP success criterion 1: `{:ok, %Delivery{status: :sent}}`). It is
distinct from `:last_event_type` (the most-recent ledger projection). They diverge at dispatch:
Multi#2 sets `status: :sent` AND `last_event_type: :dispatched`.

**`:last_error`** — `:map` column. Populated when `status: :failed` via `serialize_error/1`
in `Mailglass.Outbound`. Shape at read time: `%{type: atom, message: binary, module: binary}`.
Never a raw exception message string — adopters pattern-match on `:type`, never on `:message`.

### Idempotency key computation (D-15)

```
sha256(tenant_id <> "|" <> inspect(mailable) <> "|" <> recipient <> "|" <> content_hash)
```

where `content_hash = sha256(html_body <> text_body)`. The SHA-256 output is hex-encoded
(lowercase). Cross-tenant collision probability is ~2^-256 per batch (cryptographic-strength).

Adopters using `deliver_many/2` who want deterministic replay safety should ensure the
message content is stable across retries (no timestamp interpolation in the body).

Since: 0.1.0.

## §Outbound (Phase 3 Plan 05)

### `Mailglass.Outbound` — public surface

**Locked functions:**

| Function | Return shape | Notes |
|----------|-------------|-------|
| `send/2` | `{:ok, %Delivery{status: :sent}}` or `{:error, %Error{}}` | Canonical internal verb |
| `deliver/2` | same as `send/2` | `defdelegate` alias (D-13) |
| `deliver!/2` | `%Delivery{}` or raises | Bang variant; raises the error struct directly |
| `deliver_later/2` | `{:ok, %Delivery{status: :queued}}` or `{:error, %Error{}}` | Always returns Delivery, never `%Oban.Job{}` (D-14) |
| `deliver_many/2` | `{:ok, [%Delivery{}]}` or `{:error, %Error{}}` | v0.1 async-only |
| `deliver_many!/2` | `[%Delivery{}]` or raises `%BatchFailed{}` | Bang batch variant |
| `dispatch_by_id/1` | `{:ok, %Delivery{}}` or `{:error, %Error{}}` | Called by Outbound.Worker |

Top-level `Mailglass` module re-exports all five public verbs as `defdelegate`.

**Preflight pipeline order (D-18, SEND-01) — locked:**

0. `Mailglass.Tenancy.assert_stamped!/0` — raises `%TenancyError{:unstamped}`
1. `Mailglass.Tracking.Guard.assert_safe!/1` — raises `%ConfigError{:tracking_on_auth_stream}`
2. `Mailglass.Suppression.check_before_send/1` — returns `{:error, %SuppressedError{}}`
3. `Mailglass.RateLimiter.check/3` — `:transactional` bypasses; returns `{:error, %RateLimitError{}}`
4. `Mailglass.Stream.policy_check/1` — no-op seam (v0.1)
5. `Mailglass.Renderer.render/1` — returns `{:error, %TemplateError{}}`

**Two-Multi sync pattern invariant (D-20 — critical, T-3-05-03):**

Adapter call is OUTSIDE any `Repo.transact/1` transaction. Adapter-in-transaction
causes Postgres connection-pool starvation under provider latency. Any PR inlining
the adapter call inside `Repo.transact` is a blocking defect.

**Telemetry events (Phase 1 D-31 whitelist — no PII):**

| Event | Metadata keys |
|-------|--------------|
| `[:mailglass, :outbound, :send, :start\|:stop]` | `tenant_id, mailable, stream` |
| `[:mailglass, :outbound, :dispatch, :start\|:stop]` | `tenant_id, mailable, provider` |
| `[:mailglass, :persist, :outbound, :multi, :start\|:stop]` | `step_name, tenant_id` |

**PII exclusion list** (verified by property test across 100 generated sends):
`:to, :from, :body, :html_body, :subject, :headers, :recipient, :email`

**`deliver_later/2` return shape invariant (D-14):** ALWAYS `{:ok, %Delivery{status: :queued}}`
or `{:error, %Error{}}`. Never `%Oban.Job{}`. Oban types never leak into the public API.

**`deliver_many/2` v0.1 scope:** Async-only. Each message produces one Oban job (or one
`Task.Supervisor` spawn when Oban absent). Sync-batch fan-out deferred to v0.5.
`[ASSUMED — Plan 05 Task 4 decision]`

Since: 0.1.0.

## §Tracking.Token (Phase 3 Plan 07)

### `Mailglass.Tracking.Token`

Shipped in Phase 3 Plan 07 (TRACK-03, D-33..D-35). Phoenix.Token-signed tokens for
open-pixel and click-redirect URLs.

**Token shapes:**

- Open pixel: `{:open, delivery_id, tenant_id}`
- Click redirect: `{:click, delivery_id, tenant_id, target_url}`

**Locked function signatures:**

```elixir
@spec sign_open(endpoint :: atom() | binary(), delivery_id :: String.t(), tenant_id :: String.t()) :: binary()
@spec verify_open(endpoint :: atom() | binary(), binary()) ::
        {:ok, %{delivery_id: String.t(), tenant_id: String.t()}} | :error
@spec sign_click(endpoint :: atom() | binary(), String.t(), String.t(), String.t()) :: binary()
@spec verify_click(endpoint :: atom() | binary(), binary()) ::
        {:ok, %{delivery_id: String.t(), tenant_id: String.t(), target_url: String.t()}} | :error
```

**Open-redirect prevention (D-35 pattern a):** `target_url` lives INSIDE the signed token
payload, never as a query parameter. The CVE class is structurally unreachable — there is
no parameter to tamper with. A tampered token fails Phoenix.Token HMAC → `:error`.

**Scheme validation at sign time:** `sign_click/4` raises `%ConfigError{type: :invalid,
context: %{rejected_url: url, reason: :scheme}}` when `target_url` scheme is not
`http` or `https`. Defense-in-depth re-check at `verify_click/2` time (T-3-07-10).

**Salts rotation (D-33):** `config :mailglass, :tracking, salts: ["q2-2026", "q1-2026"]`.
HEAD of list signs; ALL salts in list are tried at verify (early-return iteration).
Rotating = prepend new salt; remove old salt to invalidate tokens signed with it.

**`tenant_id` in payload only (D-39):** Never exposed in URL path or query string.
Corporate proxy logs, referrer headers, and shared-link screenshots cannot leak it.

**Token max_age:** Default 2 years (`2 * 365 * 86_400` seconds). Configurable via
`config :mailglass, :tracking, max_age: seconds`.

**Sign opts:** `[key_iterations: 1000, key_length: 32, digest: :sha256]` — matches
Phoenix.Token security recommendations.

Since: 0.1.0.

## §Tracking.Rewriter (Phase 3 Plan 07)

### `Mailglass.Tracking.Rewriter`

Shipped in Phase 3 Plan 07 (TRACK-03, D-36..D-37). Pure Floki-based HTML transform
for open-pixel injection and click link rewriting.

**Locked function signature:**

```elixir
@spec rewrite(html_body :: String.t(), opts :: keyword()) :: String.t()
```

**Options:**
- `:flags` — `%{opens: boolean, clicks: boolean}` (required)
- `:delivery_id` — delivery UUID for token encoding (required)
- `:tenant_id` — tenant scope for token encoding (required)
- `:endpoint` — Phoenix.Token endpoint or secret binary (optional, falls back to config)

**Skip list (D-36):** The following hrefs are NEVER rewritten:
- `mailto:`, `tel:`, `sms:`, `data:`, `javascript:` schemes
- `#fragment` hrefs (same-page anchors)
- Scheme-less relative URLs (e.g. `/signup`, `../path`)
- `<a data-mg-notrack>` — attribute stripped from final HTML, href preserved
- `<a>` tags inside `<head>` (prefetch, canonical)
- List-Unsubscribe URL (v0.5 hook reserved — not yet implemented)

**Pixel markup (D-37):**
```html
<img src="https://track.host/o/<token>.gif" width="1" height="1" alt=""
     style="display:block;width:1px;height:1px;border:0;" />
```
Position: LAST child of `<body>`. Missing `<body>` → appended at document root.
`alt=""` prevents screen-reader announcement.

**Plaintext body invariant:** NEVER modified. The rewriter only operates on
`html_body`. `text_body` is passed through untouched (D-36).

**Floki parse failure:** When `Floki.parse_document/1` returns `{:error, _}`, the
original HTML string is returned unchanged and a `Logger.debug` crumb is emitted.

Since: 0.1.0.

### `Mailglass.Tracking.rewrite_if_enabled/1`

```elixir
@spec rewrite_if_enabled(Mailglass.Message.t()) :: Mailglass.Message.t()
```

Facade function that dispatches on `Mailglass.Tracking.enabled?/1` flags and calls
`Mailglass.Tracking.Rewriter.rewrite/2` when any flag is true. Returns the message
unchanged when tracking is disabled (D-10). Never touches `text_body` (D-36).

`delivery_id` is read from `message.metadata[:delivery_id]`; falls back to
`"pre-delivery"` when not yet stamped (render-preview mode).

**Gap-closure note:** `Mailglass.Outbound.send/2` (Plan 05) does not yet call
`rewrite_if_enabled/1`. Adopters can invoke it manually between `Renderer.render/1`
and `deliver/2`. Wiring into the Outbound pipeline is a gap-closure item for Phase 3.1.

Since: 0.1.0.

## §Tracking.Plug (Phase 3 Plan 07)

### `Mailglass.Tracking.Plug`

Shipped in Phase 3 Plan 07 (TRACK-03, D-34..D-35..D-39). Mountable `Plug.Router`
for open-pixel and click-redirect endpoints.

**Mount pattern:**

```elixir
# In adopter's Endpoint or router:
forward "/track", Mailglass.Tracking.Plug
```

**Locked routes:**

| Route | Success | Failure |
|-------|---------|---------|
| `GET /o/:token.gif` | `200 image/gif` — 43-byte GIF89a body | `204` (D-39: no enumeration) |
| `GET /c/:token` | `302 Location: <target_url>` | `404` |
| Any other | `404` | — |

**Pixel response headers (D-34):**
- `Content-Type: image/gif`
- `Cache-Control: no-store, private, max-age=0`
- `Pragma: no-cache`
- `X-Robots-Tag: noindex`

**GIF89a body:** Exactly 43 bytes. First 6 bytes: `<<71, 73, 70, 56, 57, 97>>` (GIF89a magic).

**No-enumeration contract (D-39):** Failed `verify_open/2` returns HTTP 204 (empty body),
NOT 404. An attacker scanning URLs cannot distinguish a valid-but-expired token from an
invalid one — both return 204. Failed `verify_click/2` returns 404 (users expect a redirect
or error page for click links, so 404 is the appropriate non-redirecting response).

**`target_url` never appears in URL path/query (D-39):** The redirect target lives in the
signed token payload. There is no surface for open-redirect attacks.

**Event recording:** On successful verify, calls `Mailglass.Events.append/1` with
`type: :opened` / `type: :clicked`. DB write failures are swallowed — the pixel and
redirect responses ALWAYS succeed. Click events store `target_url_hash` (SHA-256 hex)
in `normalized_payload`, never the raw URL (D-31 PII whitelist).

**Telemetry:**
- `[:mailglass, :tracking, :open, :recorded]` — measurements: `%{count: 1}`, metadata: `%{delivery_id, tenant_id}`
- `[:mailglass, :tracking, :click, :recorded]` — same shape

Since: 0.1.0.

## §Tracking.ConfigValidator (Phase 3 Plan 07)

### `Mailglass.Tracking.ConfigValidator`

Shipped in Phase 3 Plan 07 (TRACK-03, D-32). Boot-time validator for tracking host
configuration.

**Locked function:**

```elixir
@spec validate_at_boot!() :: :ok
```

Raises `%Mailglass.ConfigError{type: :tracking_host_missing}` when:
1. Any loaded `Mailglass.Mailable` module has `tracking: [opens: true]` OR `tracking: [clicks: true]` in its `__mailglass_opts__/0`, AND
2. `config :mailglass, :tracking, host:` is `nil` or `""`.

Returns `:ok` otherwise.

**Detection algorithm:** Iterates `:code.all_loaded()`, checks `__mailglass_mailable__/0`
(discovery marker) + `__mailglass_opts__/0` (compile-time opts) presence, reads `:tracking`
opts. Modules without `use Mailglass.Mailable` are skipped.

**Adopter usage (v0.1):** Call explicitly from `Application.start/2` after
`Mailglass.Config.validate_at_boot!/0`. Auto-wiring into `Mailglass.Config.validate_at_boot!/0`
is a v0.5 gap-closure item.

Since: 0.1.0.

## §TestAssertions (Phase 3 Plan 06)

### `Mailglass.TestAssertions`

Shipped in Phase 3 Plan 06 (TEST-01, D-05). Adopter-facing test assertion helpers.
Lives in `lib/` (not `test/support/`) so adopters can `import Mailglass.TestAssertions`
in their own test helpers.

**Locked function surface:**

| Function / Macro | Signature | Description |
|-----------------|-----------|-------------|
| `assert_mail_sent/0` | macro | Asserts any `{:mail, _}` in process mailbox |
| `assert_mail_sent/1` | macro (4 dispatch forms) | See matcher styles below |
| `assert_no_mail_sent/0` | macro | `refute_received {:mail, _}` |
| `last_mail/0` | `() :: Message.t() \| nil` | Most recent msg from Fake ETS bucket |
| `wait_for_mail/1` | `(timeout()) :: Message.t()` | Blocks until mail or timeout |
| `assert_mail_delivered/2` | `(Delivery.t() \| binary(), timeout()) :: :ok` | Consumes PubSub `:delivered` broadcast |
| `assert_mail_bounced/2` | `(Delivery.t() \| binary(), timeout()) :: :ok` | Consumes PubSub `:bounced` broadcast |

**Macro vs function dispatch rule:**
- `assert_mail_sent/0,1` and `assert_no_mail_sent/0` are **macros** — required to
  support struct-pattern syntax (`%{mailable: X}`) and `assert_received`/`refute_received`
  which must be called in caller context.
- `last_mail/0`, `wait_for_mail/1`, `assert_mail_delivered/2`, `assert_mail_bounced/2`
  are **regular functions** — they do not require compile-time AST manipulation.

**Four `assert_mail_sent/1` matcher styles:**

```elixir
# Style 1: presence (bare call)
assert_mail_sent()

# Style 2: keyword list (Swoosh familiarity)
assert_mail_sent(subject: "Welcome", to: "user@example.com")
assert_mail_sent(mailable: MyApp.UserMailer, stream: :transactional)

# Style 3: struct pattern (macro — no explicit quoting)
assert_mail_sent(%{mailable: MyApp.UserMailer})

# Style 4: predicate fn
assert_mail_sent(fn msg -> msg.stream == :transactional end)
```

**Supported keyword matcher keys (Style 2):**

| Key | Matches against |
|-----|----------------|
| `:subject` | `msg.swoosh_email.subject` |
| `:to` | any address in `msg.swoosh_email.to` |
| `:mailable` | `msg.mailable` |
| `:stream` | `msg.stream` |
| `:tenant` | `msg.tenant_id` |

Any unsupported key raises `ExUnit.AssertionError` with descriptive message.
Extensible in future versions (new keys are semver-minor).

**PubSub-backed assertions (assert_mail_delivered/2, assert_mail_bounced/2):**
- Consume `{:delivery_updated, delivery_id, :delivered | :bounced, meta}` from PubSub.
- Require the test process to be subscribed to `Mailglass.PubSub.Topics.events(tenant_id)`
  or `Mailglass.PubSub.Topics.events(tenant_id, delivery_id)` before the assertion.
- `Mailglass.MailerCase` handles the tenant-wide subscription in setup automatically.
- Both functions accept either `delivery_id :: binary()` OR `%Delivery{}` struct
  (`.id` is extracted automatically).
- Default timeout: `100` milliseconds.

**Async-safe guarantees (T-3-06-01):**
- Process mailbox (`{:mail, msg}`) is per-process — no cross-test leakage.
- `last_mail/0` reads the Fake ETS bucket keyed by owner pid — per-process isolation.
- PubSub subscription is per-process and cleaned up on process exit.
- All helpers are safe for `async: true` tests via `Mailglass.MailerCase`.

**PII policy (T-3-06-01):** Failure messages embed caller-supplied values (e.g. `subject`,
`to` address) because adopter test failures need that context. These values appear only in
the adopter's own test output — never in telemetry, log streams, or cross-tenant surfaces.

Since: 0.1.0.
