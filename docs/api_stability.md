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

## Adapter Return Shape

`Mailglass.Adapter.deliver/2` returns:

- `{:ok, %{message_id: String.t(), provider_response: term()}}` on success
- `{:error, Mailglass.Error.t()}` on failure (any of the six structs above)

Since: 0.1.0 (stub — adapter behaviour implementation lands Phase 3).
