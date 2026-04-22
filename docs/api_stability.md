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
- `:tenant_address`

Per-kind fields: none.

Retryable: `false` (permanent policy block).

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

## Shared Error Serialization

Every error struct derives:

    @derive {Jason.Encoder, only: [:type, :message, :context]}

The `:cause` field is deliberately excluded to prevent recursive emission of
adapter structs that may carry provider payloads with recipient PII (T-PII-002).
Adopters that need the full cause chain walk it explicitly via
`Mailglass.Error.root_cause/1`.

## Adapter Return Shape

`Mailglass.Adapter.deliver/2` returns:

- `{:ok, %{message_id: String.t(), provider_response: term()}}` on success
- `{:error, Mailglass.Error.t()}` on failure (any of the six structs above)

Since: 0.1.0 (stub — adapter behaviour implementation lands Phase 3).
