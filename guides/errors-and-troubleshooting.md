# Errors and Troubleshooting

This guide covers all ten mailglass error structs — their causes, fix actions, and remediation pointers. Every struct has a closed `:type` atom set. Always match on the struct module and `:type` field, never on `:message`:

```elixir
case result do
  {:error, %Mailglass.SuppressedError{type: :address}} -> ...
  {:error, %Mailglass.RateLimitError{retry_after_ms: ms}} -> ...
  {:error, %Mailglass.SendError{}} -> ...
end
```

Message strings are a presentation concern. The closed `:type` atom set is the stable contract. Canonical closed atom sets and Retryable values for each struct are documented in [docs/api_stability.md](../docs/api_stability.md).

For symptom-first incident runbooks — where you start from what went wrong in production rather than which struct appeared — use [operator-incident-support.md](./operator-incident-support.md). For webhook-specific incidents, see [webhook-troubleshooting.md](./webhook-troubleshooting.md).

## SendError

Raised when email delivery fails.

The four type atoms are `:adapter_failure`, `:rendering_failed`, `:preflight_rejected`, and `:serialization_failed`. `:adapter_failure` means the Swoosh adapter returned an error — this is the only retryable type. `:rendering_failed` means the HEEx or CSS-inlining pipeline could not produce a valid message. `:preflight_rejected` means a suppression or rate-limit check blocked the send before reaching the adapter. `:serialization_failed` means the rendered message could not be serialized into the form the adapter requires.

To fix an `:adapter_failure`, check your ESP credentials, the provider's status page, and the `:cause` field for the raw adapter error. To fix `:rendering_failed`, inspect the `:cause` for the underlying `Mailglass.TemplateError`. To fix `:preflight_rejected`, the upstream suppression or rate-limit check is the authoritative signal — inspect the wrapped error in `:cause`. For `:serialization_failed`, verify the message assigns produce valid content and that attachments are well-formed.

The `:delivery_id` field is populated when the delivery row was persisted before the failure; use it to correlate with the `mailglass_events` ledger.

For the canonical closed `:type` atom set and Retryable policy, see [docs/api_stability.md](../docs/api_stability.md).

## TemplateError

Raised when a template cannot be compiled or rendered.

The four type atoms are `:heex_compile`, `:missing_assign`, `:helper_undefined`, and `:inliner_failed`. `:heex_compile` means HEEx compilation failed — a syntax error, unclosed tag, or invalid expression in the template source. `:missing_assign` means a required assign was not passed to `render/3`; the `:context` map carries `:assign` with the name of the missing key. `:helper_undefined` means the template references a helper function that is not defined. `:inliner_failed` means Premailex or the configured CSS inliner raised an error during the CSS-inlining pass.

To fix a `:heex_compile` error, correct the template syntax and recompile. For `:missing_assign`, add the assign to the `deliver/2` call or set a default in the mailable's `build/2`. For `:helper_undefined`, define the helper or import the module that contains it. For `:inliner_failed`, check that the CSS is valid and that the inliner dependency is available.

TemplateError is never retryable — the template must be fixed before re-sending.

For the canonical closed `:type` atom set and Retryable policy, see [docs/api_stability.md](../docs/api_stability.md).

## SignatureError

Raised when webhook signature verification fails.

SignatureError is never retryable. A signature failure means the request is either misconfigured (wrong secret, rotated key not yet deployed) or is a forgery. Let the process crash under supervision and surface a 4xx to the provider — do not suppress or catch this error silently.

The current type atoms are `:missing_header`, `:malformed_header`, `:bad_credentials`, `:ip_disallowed`, `:bad_signature`, `:timestamp_skew`, and `:malformed_key`. Three legacy atoms remain in the closed set for backward compatibility: `:missing` (alias of `:missing_header`), `:malformed` (alias of `:malformed_header`), and `:mismatch` (alias of `:bad_signature`). Match the current atoms in new code; the legacy atoms will not be removed in a minor release.

`:missing_header` — the provider's signature header is absent from the request. `:malformed_header` — the header is present but cannot be parsed (bad Base64, missing prefix); the `:context` map may carry a `:detail` string. `:bad_credentials` — Postmark Basic Auth user/pass mismatch. `:ip_disallowed` — the source IP is not in the configured Postmark allowlist (opt-in check). `:bad_signature` — HMAC or ECDSA verification returned false. `:timestamp_skew` — the signed timestamp is outside the acceptable tolerance window. `:malformed_key` — the PEM or DER decode failed at config validate-at-boot time; fix your provider config and restart.

To fix most signature errors: verify the secret in your deployment environment matches the credential in the provider dashboard, run `mix mailglass.doctor` to confirm `CachingBodyReader` is wired, and redeploy. For `:malformed_key`, check the PEM/DER format of the key you have configured.

For webhook-specific incident recovery, see [webhook-troubleshooting.md](./webhook-troubleshooting.md).

For the canonical closed `:type` atom set and Retryable policy, see [docs/api_stability.md](../docs/api_stability.md).

## SuppressedError

Raised when delivery is blocked by the suppression list.

SuppressedError is a permanent policy block — never retryable. A suppressed recipient opted out, hard-bounced, or was explicitly excluded by the tenant. Treat this as expected behavior, not a delivery failure.

The three type atoms are `:address`, `:domain`, and `:address_stream`. `:address` means the recipient address is globally suppressed. `:domain` means the recipient domain is globally suppressed. `:address_stream` means the recipient is suppressed for a specific stream (for example, `:bulk`); the `:context` map carries `:stream` with the stream atom.

The `:context` map is PII-safe and carries `:tenant_id`, `:stream`, `:reason`, `:source`, and `:expires_at` for diagnostic correlation.

To fix: if the suppression was created in error, remove the record via `Mailglass.Suppression` and re-send. If the suppression is legitimate, your application should not retry delivery to this recipient.

For RFC 8058 List-Unsubscribe wiring and suppression record management, see [Unsubscribe](./unsubscribe.md).

For the canonical closed `:type` atom set and Retryable policy, see [docs/api_stability.md](../docs/api_stability.md).

## RateLimitError

Raised when a rate limit is exceeded.

RateLimitError is always retryable. The `:retry_after_ms` field carries the number of milliseconds to wait before retrying. When Oban is in use, the worker handles backoff automatically.

The three type atoms are `:per_domain`, `:per_tenant`, and `:per_stream`. `:per_domain` means the recipient domain is over its configured rate limit. `:per_tenant` means the sending tenant is over its configured rate limit. `:per_stream` means the delivery stream (`:transactional`, `:operational`, or `:bulk`) is over its limit.

To fix: honor the `:retry_after_ms` value. For persistent rate-limit failures, review your mailglass rate-limit config and your ESP's sending quotas, and consider reducing the Oban queue concurrency for the `:mailglass` queue.

For the canonical closed `:type` atom set and Retryable policy, see [docs/api_stability.md](../docs/api_stability.md).

## ConfigError

Raised when mailglass is misconfigured.

ConfigError is never retryable. The host application must fix the configuration and restart. `Mailglass.Config.validate_at_boot!/0` raises this at application startup for the most critical config problems.

The type atoms are: `:missing` (a required config key is not set), `:invalid` (a key is present but its value is not valid), `:conflicting` (two or more keys contradict each other), `:optional_dep_missing` (an optional dependency required for the selected config is not loaded), `:tracking_on_auth_stream` (open/click tracking is enabled on a mailable whose function name matches an auth-stream heuristic — forbidden), `:tracking_host_missing` (tracking is enabled but no tracking host is configured), `:tracking_endpoint_missing` (tracking is enabled but no Phoenix endpoint is configured for token signing), `:webhook_verification_key_missing` (a webhook provider is configured but its verification credentials are not set), and `:webhook_caching_body_reader_missing` (a webhook request arrived but `conn.private[:raw_body]` is missing, meaning `CachingBodyReader` is not wired).

The `:context` map carries `:key` for `:missing` and `:invalid`, `:dep` for `:optional_dep_missing`, and `:hint` for webhook config errors.

To fix: read the message string for the specific remediation instruction, correct the config in your application's `config/` files, and restart. For `:webhook_caching_body_reader_missing`, run `mix mailglass.install` and verify with `mix mailglass.doctor`.

For the canonical closed `:type` atom set and Retryable policy, see [docs/api_stability.md](../docs/api_stability.md).

## EventLedgerImmutableError

Raised when the `mailglass_events` append-only immutability trigger fires.

The event ledger is append-only by design. A Postgres `BEFORE UPDATE OR DELETE` trigger on `mailglass_events` raises `SQLSTATE 45A01` for every mutation attempt. `Mailglass.Repo.transact/1` translates the resulting `%Postgrex.Error{}` into this struct so callers pattern-match a mailglass-owned error rather than the raw Postgrex one.

The two type atoms are `:update_attempt` and `:delete_attempt`. EventLedgerImmutableError is never retryable — an immutability violation is a bug in the calling code.

To fix: locate the code path that attempted to UPDATE or DELETE a row in `mailglass_events` and remove it. Events must only be inserted; they can never be modified or deleted. The `:pg_code` field carries `"45A01"` for log correlation.

For the canonical closed `:type` atom set and Retryable policy, see [docs/api_stability.md](../docs/api_stability.md).

## TenancyError

Raised when tenant context is required but not stamped on the process.

`Mailglass.Tenancy.tenant_id!/0` raises this when the calling process has not been stamped via `Mailglass.Tenancy.put_current/1`. TenancyError is never retryable — the caller failed to establish tenant context before invoking mailglass.

The two type atoms are `:unstamped` and `:webhook_tenant_unresolved`. `:unstamped` means no `tenant_id` is present in the process dictionary. `:webhook_tenant_unresolved` means `Mailglass.Tenancy.resolve_webhook_tenant/1` returned `{:error, _}` for a cryptographically verified webhook request — the request is authentic but your tenancy module could not map it to a known tenant.

To fix `:unstamped`: call `Mailglass.Tenancy.put_current/1` in your `on_mount/4` LiveView callback, your Plug pipeline, or your test setup before any mailglass call. To fix `:webhook_tenant_unresolved`: inspect `:context` for `:provider` and `:reason`, then update your tenancy resolver to handle the provider or tenant mapping that is failing.

For the canonical closed `:type` atom set and Retryable policy, see [docs/api_stability.md](../docs/api_stability.md).

## StreamPolicyError

Raised when a message violates stream policy.

The single type atom is `:stream_policy_violated` — the message violates rules for its assigned stream. StreamPolicyError is never retryable — the message must be corrected before re-sending.

The `:detail` field, when present, carries a map with `:rule` (the rule atom that triggered) and `:suggestion` (a human-readable remediation hint). Inspect `:detail` to understand which rule fired and how to resolve it.

To fix: review the stream policy configured for the message's stream and correct the mailable so it satisfies the rule. The `:detail` map's `:suggestion` field provides a starting point.

Note: StreamPolicyError's type set is sourced from its module (`lib/mailglass/errors/stream_policy_error.ex`); it does not currently have a dedicated section in [docs/api_stability.md](../docs/api_stability.md). For general error contract context, see [docs/api_stability.md](../docs/api_stability.md).

## PublishError

Raised when installer golden drift is detected during the `mix mailglass.publish.check` task.

The single type atom is `:publish_blocked_golden_drift` — the generated installer snippets do not match the expected golden files. PublishError is never retryable as a runtime error; it requires regenerating the goldens.

To fix: run the golden regeneration command:

```bash
MIX_INSTALLER_ACCEPT_GOLDEN=1 mix test test/mailglass/install/install_golden_test.exs --warnings-as-errors
```

This regenerates the golden files to match the current installer output. Review the diff, commit the updated goldens, and re-run `mix mailglass.publish.check`.

The `:context` map may carry `:output` with the subprocess output for diagnosis.

For the canonical closed `:type` atom set and Retryable policy, see [docs/api_stability.md](../docs/api_stability.md).
