# Phase 17: Unblock & Verify Resend - Context

**Gathered:** 2026-04-29
**Status:** Ready for planning

<domain>
## Phase Boundary

Complete the interrupted Phase 14 wire-up and make `mix test` pass clean. This means: (1) fix the one broken pre-existing test that blocks the full suite, (2) finish the four missing Resend entries in `plug.ex` and `router.ex` so the provider is actually mountable, and (3) add plug-level integration tests that satisfy ROADMAP success criteria 2 + 3 ("accepted/rejected by the webhook plug"). Mark Phase 14 complete.

</domain>

<decisions>
## Implementation Decisions

### Tracking test fix (endpoint_resolution_test.exs:32)

- **D-01:** Change `async: true` → `async: false` in `test/mailglass/tracking/endpoint_resolution_test.exs`. This is a one-line fix. Every other tracking test that calls `Application.put_env` (config_validator_test, plug_test, rewriter_test, token_test, token_rotation_test, open_redirect_test) is already `async: false`. This file is the only outlier. The `Tracking.endpoint/0` implementation is correct; the failure is purely a concurrency race from async tests sharing global Application env.

### Router + plug wiring for Resend

- **D-02:** Add `:resend` to `@valid_providers` in both `lib/mailglass/webhook/plug.ex` and `lib/mailglass/webhook/router.ex`. This is mechanical completion of Phase 14's interrupted wire-up — every prior provider (Mailgun in Phase 15, SES in Phase 16) had router/plug wiring land in the same phase as implementation.
- **D-03:** Add `resolve_config!(:resend, _conn)` clause to `plug.ex` that reads `Application.get_env(:mailglass, :resend, [])` and returns `%{secret: env[:secret], timestamp_tolerance_seconds: env[:timestamp_tolerance_seconds] || 300}`. This matches the shape `Mailglass.Webhook.Providers.Resend.verify!/3` already expects.
- **D-04:** Add `provider_module(:resend)` → `Mailglass.Webhook.Providers.Resend` clause to `plug.ex`. The static dispatch pattern is exhaustive per the existing comment; this is the missing entry.
- **D-05:** Update `plug_test.exs` to remove the existing `assert_raise ArgumentError, ~r/unknown :provider/ fn -> WebhookPlug.init(provider: :resend) end` test. That assertion was correct before wiring — after wiring `:resend` becomes valid and the test will fail. Replace with a test asserting `:resend` initializes successfully.

### Plug-level integration tests

- **D-06:** Add a `:resend` arm to `mailglass_webhook_conn/3` in `test/support/webhook_case.ex`. The arm should build a `%Plug.Conn{}` for `/webhooks/resend`, set `content-type: application/json`, populate `conn.private[:raw_body]`, and attach the three Svix headers (`svix-id`, `svix-timestamp`, `svix-signature: v1,<sig>`) signed with `Mailglass.WebhookFixtures.sign_resend_payload/4`. Follow the exact Mailgun arm pattern.
- **D-07:** Add Resend config installation to the `WebhookCase` setup block: `Application.put_env(:mailglass, :resend, enabled: true, secret: <test_whsec>, timestamp_tolerance_seconds: 300)` with proper `prior_resend` capture + `on_exit` restore. Use a module-level `@resend_secret_bytes` constant (`:crypto.strong_rand_bytes(32)`) and derive `@resend_secret "whsec_" <> Base.encode64(@resend_secret_bytes)` to avoid re-generating per test.
- **D-08:** Add `stub_resend_fixture/1` to `WebhookCase` and import it via the `using` macro. Implement as `Mailglass.WebhookFixtures.load_resend_fixture(name)`.
- **D-09:** Create a new `test/mailglass/webhook/providers/resend_webhook_plug_test.exs` file (mirroring `plug_mailgun_test.exs`). Cover: valid signature → 200; invalid/tampered signature → 401 with `SignatureError`; stale timestamp → 401; missing `svix-id` header → 401. Use `WebhookCase, async: false`.
- **D-10:** Create at least one resend fixture JSON file at `test/support/fixtures/webhooks/resend/delivered.json` for normalize integration. The other event types (sent, bounced, complained, delivery_delayed) are already covered by inline payloads in the existing unit test — no need to duplicate as fixture files unless the plug test needs them.

### Phase completion

- **D-11:** Mark Phase 14 as complete in `.planning/ROADMAP.md` once all success criteria pass. Update progress table to reflect Phase 14 `Status: Complete` and set `Completed: 2026-04-29` (or the actual completion date).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 14 decisions (Resend provider — these are locked)
- `.planning/phases/14-resend-webhook-provider-core-ingest/14-CONTEXT.md` — D-01 (native HMAC-SHA256, no third-party dep), D-02 (300s tolerance, configurable), D-03 (unmapped → :unknown)

### Core files to modify
- `lib/mailglass/webhook/plug.ex` — `@valid_providers`, `resolve_config!/2`, `provider_module/1` all need `:resend` entries. Line 84 for `@valid_providers`, lines 230–266 for `resolve_config!` clauses, lines 391–394 for `provider_module/1` clauses.
- `lib/mailglass/webhook/router.ex` — `@valid_providers` line 71. One-atom addition.
- `lib/mailglass/webhook/providers/resend.ex` — Complete implementation. No changes needed. Read to confirm `verify!/3` config key names before writing `resolve_config!(:resend, ...)`.

### Test infrastructure to update
- `test/support/webhook_case.ex` — Add `:resend` arm to `mailglass_webhook_conn/3` (lines 153–222), Resend config to setup block (lines 86–116), `stub_resend_fixture/1` to exports and helpers.
- `test/mailglass/tracking/endpoint_resolution_test.exs` — Line 1: change `async: true` to `async: false`. One-line fix.
- `test/mailglass/webhook/plug_test.exs` — Remove/update the `assert_raise ArgumentError` test for `:resend` (currently expects `:resend` to raise — must become a success assertion once `:resend` is wired in).

### Template patterns (read these for structural guidance)
- `test/mailglass/webhook/providers/plug_mailgun_test.exs` — Direct template for `resend_webhook_plug_test.exs`. Same structure: `WebhookCase, async: false`, valid → 200, invalid → 401.
- `lib/mailglass/webhook/providers/mailgun.ex` — Nearest prior provider implementation for style reference.

### Phase goals and requirements
- `.planning/ROADMAP.md` — Phase 17 success criteria (5 items). Phase 14 progress row to update.
- `.planning/REQUIREMENTS.md` — RESEND-01, RESEND-02 requirement IDs.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Mailglass.WebhookFixtures.sign_resend_payload/4` — already exists; takes `(svix_id, svix_timestamp, body, secret_bytes)` and returns a Base64-encoded HMAC-SHA256 sig. The `:resend` WebhookCase arm just calls this.
- `Mailglass.WebhookFixtures.load_resend_fixture/1` — already exists; reads from `test/support/fixtures/webhooks/resend/{name}.json`. Only the JSON fixture files are missing.
- `Plug.Crypto.secure_compare/2` — already used inside `Resend.verify!/3` for timing-safe comparison.

### Established Patterns
- `resolve_config!` follows a per-provider `defp` clause pattern. The `:resend` clause must read `Application.get_env(:mailglass, :resend, [])` and return a plain map with `:secret` and `:timestamp_tolerance_seconds`.
- `provider_module/1` is a single-line static dispatch: `defp provider_module(:resend), do: Mailglass.Webhook.Providers.Resend`.
- WebhookCase setup captures `prior_X = Application.get_env(:mailglass, :X)` and restores on exit. The `:resend` entry follows the identical pattern already done for `:mailgun` and `:ses`.

### Integration Points
- `Mailglass.Webhook.Plug.init/1` validates `provider in @valid_providers` at compile/mount time. Adding `:resend` to that list makes it mountable; the existing `do_call/3` → `resolve_config!` → `verify_with_telemetry!` → `provider_module` chain handles the rest automatically.
- The existing `assert_raise ArgumentError` test in `plug_test.exs` for `:resend` is a correctness guard that will invert after wiring — it must be updated, not left to fail.

</code_context>

<specifics>
## Specific Ideas

- The `resolve_config!(:resend, _conn)` clause shape is dictated by `Resend.verify!/3` which calls `Map.get(config, :secret)` and `Map.get(config, :timestamp_tolerance_seconds, 300)`. No deviations needed.
- For the WebhookCase `:resend` arm, derive a fresh `svix_timestamp` from `System.system_time(:second)` per test (as the unit tests do), not a module-level constant, to avoid timestamp-skew failures.
- `plug_mailgun_test.exs` is the direct structural template — its test names and assertions are close to what `resend_webhook_plug_test.exs` should look like: valid body → 200, tampered body → 401, missing header → 401, stale timestamp → 401.

</specifics>

<deferred>
## Deferred Ideas

- Resend doc/guide update (webhooks.md Resend configuration section) — deferred to Phase 18, which already scopes "webhooks.md documents Resend configuration including CachingBodyReader setup".
- Additional Resend fixture files beyond `delivered.json` — not needed until Phase 17 integration tests require them; the unit tests cover all event types inline.

</deferred>

---

*Phase: 17-unblock-verify-resend*
*Context gathered: 2026-04-29*
