# Phase 17: Unblock & Verify Resend - Research

**Researched:** 2026-04-29
**Domain:** Elixir/Phoenix webhook provider wiring, test infrastructure completion
**Confidence:** HIGH

## Summary

Phase 17 is a code-completion sprint, not an architectural design phase. Phase 14 shipped a complete `Mailglass.Webhook.Providers.Resend` implementation but stopped short of wiring `:resend` into the `Plug` and `Router` modules, and stopped short of adding plug-level integration tests. The full test suite currently passes clean (891 tests, 0 failures) when run with a working database. The only remaining work is mechanical:

1. Add `:resend` to four locations in `plug.ex` and `router.ex` — each is a one-liner or two-liner following the exhaustive static dispatch pattern already established for `:mailgun` and `:ses`.
2. Update one existing test assertion in `plug_test.exs` that guards against `:resend` raising at `init/1` — after wiring, it must assert success instead.
3. Add Resend config wiring to `WebhookCase` setup block and add a `:resend` arm to `mailglass_webhook_conn/3`.
4. Create `resend_webhook_plug_test.exs` mirroring `plug_mailgun_test.exs` structure.
5. Create the `delivered.json` fixture file under `test/support/fixtures/webhooks/resend/`.

The `endpoint_resolution_test.exs` `async: true` issue from CONTEXT.md is a latent race. The full suite runs clean today, but the D-01 fix (change to `async: false`) remains correct hygiene and should be applied.

**Primary recommendation:** Execute all 11 decisions from CONTEXT.md exactly as specified. No architectural research needed — all patterns are verified in the codebase.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Change `async: true` → `async: false` in `test/mailglass/tracking/endpoint_resolution_test.exs`. One-line fix.
- **D-02:** Add `:resend` to `@valid_providers` in both `lib/mailglass/webhook/plug.ex` and `lib/mailglass/webhook/router.ex`.
- **D-03:** Add `resolve_config!(:resend, _conn)` clause to `plug.ex` reading `Application.get_env(:mailglass, :resend, [])`, returning `%{secret: env[:secret], timestamp_tolerance_seconds: env[:timestamp_tolerance_seconds] || 300}`.
- **D-04:** Add `provider_module(:resend)` → `Mailglass.Webhook.Providers.Resend` clause to `plug.ex`.
- **D-05:** Remove the `assert_raise ArgumentError, ~r/unknown :provider/` test for `:resend` from `plug_test.exs`. Replace with a test asserting `:resend` initializes successfully.
- **D-06:** Add `:resend` arm to `mailglass_webhook_conn/3` in `test/support/webhook_case.ex`. Build conn for `/webhooks/resend`, set `content-type: application/json`, populate `conn.private[:raw_body]`, attach `svix-id`, `svix-timestamp`, `svix-signature: v1,<sig>` headers using `sign_resend_payload/4`.
- **D-07:** Add Resend config installation to `WebhookCase` setup block: `Application.put_env(:mailglass, :resend, enabled: true, secret: <test_whsec>, timestamp_tolerance_seconds: 300)` with `prior_resend` capture + `on_exit` restore. Module-level `@resend_secret_bytes` constant + derived `@resend_secret`.
- **D-08:** Add `stub_resend_fixture/1` to `WebhookCase` and import it via the `using` macro.
- **D-09:** Create `test/mailglass/webhook/providers/resend_webhook_plug_test.exs` mirroring `plug_mailgun_test.exs`. Covers: valid signature → 200; invalid/tampered signature → 401 with `SignatureError`; stale timestamp → 401; missing `svix-id` header → 401. Uses `WebhookCase, async: false`.
- **D-10:** Create `test/support/fixtures/webhooks/resend/delivered.json` fixture file.
- **D-11:** Mark Phase 14 complete in `.planning/ROADMAP.md`.

### Claude's Discretion

None listed in CONTEXT.md.

### Deferred Ideas (OUT OF SCOPE)

- Resend doc/guide update (webhooks.md Resend configuration section) — deferred to Phase 18.
- Additional Resend fixture files beyond `delivered.json`.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| RESEND-01 | Webhook plug verifies Svix HMAC-SHA256 signature using `svix-id`, `svix-timestamp`, and raw request body | Verification implementation confirmed complete in `resend.ex`. Plug wiring (D-02..D-04) enables it to reach `verify!/3`. Plug tests (D-09) assert the 200/401 boundary. |
| RESEND-02 | Webhook maps Resend events (delivered, bounced, complained) to `mailglass` normalized taxonomy | `normalize/2` implementation confirmed: `email.delivered` → `:delivered`, `email.bounced` → `:bounced/:bounced`, `email.complained` → `:complained`. Unit tests pass. Plug integration tests (D-09) exercise the full path through the plug. |
</phase_requirements>

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Svix HMAC-SHA256 verification | API / Backend (`Resend.verify!/3`) | — | Signature verification is pure computation over raw bytes + headers; no I/O, no state |
| Provider routing/dispatch | API / Backend (`Webhook.Plug`) | — | Plug owns the request lifecycle and dispatches to provider modules |
| Config resolution | API / Backend (`resolve_config!/2`) | — | Reads Application env at request time; static dispatch per provider |
| Test helper wiring | Test support (`WebhookCase`) | `WebhookFixtures` | Setup/teardown of global Application env for provider credentials |
| Integration test assertions | Test support (`resend_webhook_plug_test.exs`) | — | End-to-end from `WebhookPlug.call/2` through `verify!/3` |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:crypto` (OTP) | OTP 27 | HMAC-SHA256 via `:crypto.mac(:hmac, :sha256, ...)` | Already used in `Resend.verify!/3` and `WebhookFixtures.sign_resend_payload/4` |
| `Plug.Crypto` | Plug ~> 1.18 | `secure_compare/2` for timing-safe signature comparison | Already used inside `valid_signature?/2` in `resend.ex` |
| `ExUnit` | Elixir stdlib | Test assertions | Project-standard |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Jason` | ~> 1.4 | JSON decode in `normalize/2` | Already used in `resend.ex` normalize path |
| `Plug.Test` | Plug ~> 1.18 | `conn/3` for building test conns | Already used in all `WebhookCase` arms |

**No new dependencies required for this phase.**

## Architecture Patterns

### System Architecture Diagram

```
Test: resend_webhook_plug_test.exs
        |
        | mailglass_webhook_conn(:resend, raw_body)
        v
WebhookCase.mailglass_webhook_conn/3  ← signs with sign_resend_payload/4
        |  (builds %Plug.Conn{} with svix-id, svix-timestamp, svix-signature: v1,<sig>)
        |
        v
Mailglass.Webhook.Plug.call/2
        |
        +-- resolve_config!(:resend, conn)  [reads Application.get_env(:mailglass, :resend)]
        |   returns %{secret: "whsec_...", timestamp_tolerance_seconds: 300}
        |
        +-- verify_with_telemetry!(:resend, raw_body, headers, config)
        |       |
        |       v
        |   Resend.verify!/3
        |       |-- fetch_header(headers, "svix-id")
        |       |-- fetch_header(headers, "svix-timestamp")
        |       |-- fetch_header(headers, "svix-signature")
        |       |-- verify_timestamp(svix_timestamp, 300)
        |       |-- fetch_secret!(config)  →  Base64.decode "whsec_" prefix
        |       |-- :crypto.mac(:hmac, :sha256, secret, "id.ts.body")
        |       |-- valid_signature?(header, expected)  →  Plug.Crypto.secure_compare
        |       returns :ok  OR  raises %SignatureError{}
        |
        +-- [on :ok] resolve_tenant! → Tenancy.with_tenant → normalize → ingest
        +-- [on SignatureError] 401
```

### Recommended Project Structure

No new directories. All changes are in existing files plus one new test file and one new fixture file:

```
lib/mailglass/webhook/
├── plug.ex                          # add :resend to @valid_providers, resolve_config!, provider_module
├── router.ex                        # add :resend to @valid_providers
└── providers/
    └── resend.ex                    # NO CHANGES — implementation complete

test/
├── support/
│   ├── webhook_case.ex              # add :resend arm, setup config, stub_resend_fixture/1
│   ├── webhook_fixtures.ex          # NO CHANGES — sign_resend_payload/4 + load_resend_fixture/1 exist
│   └── fixtures/webhooks/
│       └── resend/
│           └── delivered.json       # NEW: minimal Resend delivered event payload
├── mailglass/
│   ├── tracking/
│   │   └── endpoint_resolution_test.exs   # change async: true → async: false
│   └── webhook/
│       ├── plug_test.exs            # update :resend init test
│       └── providers/
│           └── resend_webhook_plug_test.exs  # NEW: plug-level integration tests
```

### Pattern 1: `@valid_providers` and `provider_module/1` Static Dispatch

**What:** `plug.ex` has a module attribute `@valid_providers` list and a series of exhaustive `defp provider_module/1` clauses. Adding `:resend` means adding to both.

**Current state (verified):**
```elixir
# Source: lib/mailglass/webhook/plug.ex line 84
@valid_providers [:postmark, :sendgrid, :mailgun, :ses]

# Source: lib/mailglass/webhook/plug.ex lines 391-394
defp provider_module(:postmark), do: Mailglass.Webhook.Providers.Postmark
defp provider_module(:sendgrid), do: Mailglass.Webhook.Providers.SendGrid
defp provider_module(:mailgun), do: Mailglass.Webhook.Providers.Mailgun
defp provider_module(:ses), do: Mailglass.Webhook.Providers.SES
```

**After change:**
```elixir
@valid_providers [:postmark, :sendgrid, :mailgun, :ses, :resend]

defp provider_module(:postmark), do: Mailglass.Webhook.Providers.Postmark
defp provider_module(:sendgrid), do: Mailglass.Webhook.Providers.SendGrid
defp provider_module(:mailgun), do: Mailglass.Webhook.Providers.Mailgun
defp provider_module(:ses), do: Mailglass.Webhook.Providers.SES
defp provider_module(:resend), do: Mailglass.Webhook.Providers.Resend
```

[VERIFIED: read lib/mailglass/webhook/plug.ex]

### Pattern 2: `resolve_config!` Per-Provider Clause

**What:** Each provider has a `defp resolve_config!(:provider, conn)` clause reading `Application.get_env`. The shape of the returned map is dictated by what `verify!/3` calls via `Map.get(config, :key)`.

**Verified from `resend.ex`:**
```elixir
# Source: lib/mailglass/webhook/providers/resend.ex
# verify!/3 reads:
tolerance = Map.get(config, :timestamp_tolerance_seconds, @default_tolerance_seconds)
secret = fetch_secret!(config)  # calls Map.get(config, :secret)
```

**New clause to add:**
```elixir
defp resolve_config!(:resend, _conn) do
  env = Application.get_env(:mailglass, :resend, [])
  %{
    secret: env[:secret],
    timestamp_tolerance_seconds: env[:timestamp_tolerance_seconds] || 300
  }
end
```

[VERIFIED: read lib/mailglass/webhook/providers/resend.ex — config key names confirmed]

### Pattern 3: WebhookCase `:resend` Arm

**What:** `mailglass_webhook_conn(:resend, raw_body, opts)` must attach three headers. The `sign_resend_payload/4` helper already exists in `WebhookFixtures`.

**Verified signature of `sign_resend_payload/4`:**
```elixir
# Source: test/support/webhook_fixtures.ex
@spec sign_resend_payload(String.t(), String.t(), binary(), binary()) :: String.t()
def sign_resend_payload(svix_id, svix_timestamp, raw_body, secret)
# Args: svix_id, svix_timestamp, raw_body, secret_bytes (raw bytes, NOT "whsec_" prefixed)
# Returns: Base64-encoded HMAC-SHA256 signature (no "v1," prefix — caller adds it)
```

**New WebhookCase arm:**
```elixir
def mailglass_webhook_conn(:resend, raw_body, _opts) when is_binary(raw_body) do
  svix_id = "msg_test_#{System.unique_integer([:positive])}"
  svix_timestamp = Integer.to_string(System.system_time(:second))

  secret_bytes =
    case Application.fetch_env(:mailglass, :resend) do
      {:ok, cfg} ->
        "whsec_" <> encoded = Keyword.fetch!(cfg, :secret)
        Base.decode64!(encoded)
      :error ->
        :crypto.strong_rand_bytes(32)
    end

  sig = Mailglass.WebhookFixtures.sign_resend_payload(svix_id, svix_timestamp, raw_body, secret_bytes)

  base_conn(:resend, raw_body)
  |> Plug.Conn.put_req_header("svix-id", svix_id)
  |> Plug.Conn.put_req_header("svix-timestamp", svix_timestamp)
  |> Plug.Conn.put_req_header("svix-signature", "v1," <> sig)
end
```

[VERIFIED: read test/support/webhook_fixtures.ex and test/support/webhook_case.ex]

### Pattern 4: `resend_webhook_plug_test.exs` Structure

**Template:** `test/mailglass/webhook/plug_mailgun_test.exs` (verified — file exists and was read).

**Key differences from Mailgun template:**
- No `MailgunReplayCache.reset()` in setup — Resend has no replay cache
- No `TRUNCATE` calls in setup — the plug-level Resend tests don't need ingest to succeed (they only test the signature verification layer, same as the approach in `plug_test.exs`)
- Stale timestamp test: pass `opts[:timestamp]` as a stale value OR build the conn manually with an old `svix-timestamp`
- Missing header test: build conn manually without `svix-id`

**Minimum test coverage per D-09:**
1. Valid signature → 200
2. Invalid/tampered body → 401 with `SignatureError`
3. Stale timestamp → 401
4. Missing `svix-id` header → 401

**Note on ingest layer:** The Mailgun plug test calls `WebhookPlug.call/2` through to ingest (200 means a `WebhookEvent` row exists). For Resend, the same pattern applies — `ingest_multi/3` will run on the happy path. If the test DB is available and `WebhookEvent` rows are inspected, `TestRepo` and truncation are needed. If the test only asserts status codes and log output (like `plug_test.exs`), no DB setup is needed. The CONTEXT.md says "valid signature → 200" which implies end-to-end. Follow `plug_mailgun_test.exs` structure (with DB truncation in setup) for consistency.

[VERIFIED: read test/mailglass/webhook/plug_mailgun_test.exs]

### Pattern 5: `delivered.json` Fixture

**What:** Minimal Resend delivered event JSON. The fixture is loaded by `load_resend_fixture("delivered")` and passed to `mailglass_webhook_conn/3` as raw bytes. The JSON must be stable (no re-encoding) because the signature is computed over the exact bytes.

**Structure (based on `resend_test.exs` inline payloads — verified):**
```json
{
  "id": "evt_delivered_001",
  "type": "email.delivered",
  "created_at": "2026-04-29T12:00:00Z",
  "data": {
    "email_id": "email_delivered_001",
    "to": ["test@example.com"]
  }
}
```

[VERIFIED: read test/mailglass/webhook/providers/resend_test.exs — `resend_payload/1` helper used there as template]

### Anti-Patterns to Avoid

- **Do not** re-generate `@resend_secret_bytes` per test at runtime in `WebhookCase`. Generate once as a module attribute (same pattern as `resend_test.exs` uses `@secret_bytes :crypto.strong_rand_bytes(32)`).
- **Do not** use a stale hardcoded timestamp in the fixture file — fixtures are payload-only, signatures are applied at test time.
- **Do not** change `router.ex` default providers (`@default_providers [:postmark, :sendgrid]`). Only `@valid_providers` gets `:resend` added.
- **Do not** skip the `prior_resend` capture + `on_exit` restore in `WebhookCase` setup — consistent with all other providers.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| HMAC-SHA256 signing in tests | Custom crypto in test | `WebhookFixtures.sign_resend_payload/4` | Already exists, tested |
| Resend fixture loading | `File.read!` inline | `WebhookFixtures.load_resend_fixture/1` | Already exists, consistent path |
| Timing-safe comparison | `==` operator | `Plug.Crypto.secure_compare/2` | Already used in `valid_signature?/2` — don't change |

**Key insight:** All crypto primitives, signing helpers, and fixture loaders are already written. Phase 17 is pure wiring.

## Common Pitfalls

### Pitfall 1: `sign_resend_payload/4` takes raw secret bytes, not the `whsec_` string

**What goes wrong:** The WebhookCase arm calls `sign_resend_payload` with the `whsec_<base64>` string instead of the decoded raw bytes. The signature won't match what `verify!/3` computes (it decodes the prefix first).

**Why it happens:** `resend.ex` stores and exposes the `whsec_` prefixed string in Application config, but `sign_resend_payload/4` takes raw bytes (the decoded half).

**How to avoid:** In the WebhookCase arm, decode the secret before passing it: `"whsec_" <> encoded = cfg[:secret]; Base.decode64!(encoded)`.

**Warning signs:** Tests get 401 even when the body hasn't been tampered.

[VERIFIED: read test/support/webhook_fixtures.ex — sign_resend_payload takes `secret` as binary (raw bytes); read resend.ex — fetch_secret!/1 does the whsec_ decode internally]

### Pitfall 2: `svix-timestamp` must be fresh per test, not a module-level constant

**What goes wrong:** A module-level `@svix_timestamp` constant is computed at compile time. By test execution time it is stale beyond the 300-second tolerance window and every test gets 401.

**Why it happens:** Module attributes in ExUnit are evaluated at compile time.

**How to avoid:** Generate `svix_timestamp = Integer.to_string(System.system_time(:second))` inside the function body of the WebhookCase arm, per call.

**Warning signs:** Tests fail with `reason=timestamp_skew` in logs despite valid signatures.

[VERIFIED: CONTEXT.md specifics section explicitly calls this out; confirmed by reading verify_timestamp/2 in resend.ex]

### Pitfall 3: The `assert_raise` test in `plug_test.exs` becomes a false-pass after wiring

**What goes wrong:** After `:resend` is added to `@valid_providers`, the existing `assert_raise ArgumentError, ~r/unknown :provider/` test for `:resend` in `plug_test.exs` will fail — the error is no longer raised. If not updated, the test gives a misleading "ArgumentError was not raised" failure.

**Why it happens:** The test was written correctly as a guard against accepting `:resend` before it was wired. After wiring, the guard inverts.

**How to avoid:** Update the test (per D-05) to assert `Keyword.get(WebhookPlug.init(provider: :resend), :provider) == :resend`.

[VERIFIED: read test/mailglass/webhook/plug_test.exs — test at line 38-41 confirmed]

### Pitfall 4: `router.ex` has TWO provider lists — only `@valid_providers` gets `:resend`

**What goes wrong:** `@default_providers` in `router.ex` also gets `:resend` added. This would make Resend routes mount by default for all adopters who call `mailglass_webhook_routes/2` without specifying `:providers`. Only `:postmark` and `:sendgrid` are in the default set by design (per router.ex docstring: "Mailgun and SES require explicit opt-in").

**Why it happens:** Both `@valid_providers` and `@default_providers` are on adjacent lines and look similar.

**How to avoid:** Only modify line 71 (`@valid_providers`) in `router.ex`. Leave `@default_providers [:postmark, :sendgrid]` unchanged.

[VERIFIED: read lib/mailglass/webhook/router.ex]

### Pitfall 5: WebhookCase `using` macro must be updated to export `stub_resend_fixture/1`

**What goes wrong:** `stub_resend_fixture/1` is added as a function but not added to the `import Mailglass.WebhookCase, only: [...]` list in the `using` macro. Tests that call it get `undefined function` errors.

**How to avoid:** Add `stub_resend_fixture: 1` to the `only:` list in the `using` block alongside `stub_mailgun_fixture: 1` and `stub_ses_fixture: 1`.

[VERIFIED: read test/support/webhook_case.ex — using macro at lines 58-71 shows current exports]

## Code Examples

### WebhookCase Setup Block Addition

```elixir
# Source: test/support/webhook_case.ex pattern — verified by reading existing setup block

# Module-level constants (outside setup, at module top)
@resend_secret_bytes :crypto.strong_rand_bytes(32)
@resend_secret "whsec_" <> Base.encode64(@resend_secret_bytes)

# Inside setup:
prior_resend = Application.get_env(:mailglass, :resend)

if install_config? do
  # ...existing providers...
  Application.put_env(:mailglass, :resend,
    enabled: true,
    secret: @resend_secret,
    timestamp_tolerance_seconds: 300
  )
end

on_exit(fn ->
  # ...existing restores...
  restore_env(:resend, prior_resend)
end)
```

### Stale Timestamp Test Pattern

```elixir
# For the "stale timestamp → 401" test in resend_webhook_plug_test.exs:
# Build conn manually bypassing the WebhookCase arm (which always uses current time)

stale_ts = Integer.to_string(System.system_time(:second) - 400)
sig = Mailglass.WebhookFixtures.sign_resend_payload("msg_stale", stale_ts, raw_body, @resend_secret_bytes)

conn =
  :post
  |> Plug.Test.conn("/webhooks/resend", raw_body)
  |> Plug.Conn.put_req_header("content-type", "application/json")
  |> Plug.Conn.put_private(:raw_body, raw_body)
  |> Plug.Conn.put_req_header("svix-id", "msg_stale")
  |> Plug.Conn.put_req_header("svix-timestamp", stale_ts)
  |> Plug.Conn.put_req_header("svix-signature", "v1," <> sig)

{result, _log} = with_log(fn -> WebhookPlug.call(conn, WebhookPlug.init(provider: :resend)) end)
assert result.status == 401
```

### Missing Header Test Pattern

```elixir
# For the "missing svix-id → 401" test:
# Build the conn with svix-timestamp and svix-signature but omit svix-id

conn =
  base_conn_without_svix_id(raw_body)

{result, _log} = with_log(fn -> WebhookPlug.call(conn, WebhookPlug.init(provider: :resend)) end)
assert result.status == 401
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `:resend` raises `ArgumentError` at `plug.ex init/1` | `:resend` accepted — routes mount, `verify!/3` runs | Phase 17 | RESEND-01 completion |
| No Resend fixture directory | `test/support/fixtures/webhooks/resend/delivered.json` | Phase 17 | Enables fixture-based plug tests |
| `endpoint_resolution_test.exs async: true` | `async: false` | Phase 17 | Prevents intermittent race with other `Application.put_env` tests |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | — | — | — |

**This table is empty.** All claims in this research were verified by reading the actual source files. No assumed knowledge was used for any factual assertion.

## Open Questions

None. All implementation details are fully specified by CONTEXT.md decisions and verified against the current codebase.

## Environment Availability

Step 2.6: SKIPPED (no new external dependencies — this phase adds no new libraries, runtimes, or services).

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir stdlib) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/mailglass/webhook/providers/resend_test.exs test/mailglass/webhook/plug_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RESEND-01 | Valid Svix signature accepted by plug → 200 | integration | `mix test test/mailglass/webhook/providers/resend_webhook_plug_test.exs` | ❌ Wave 0 |
| RESEND-01 | Invalid Svix signature rejected → 401 + SignatureError | integration | `mix test test/mailglass/webhook/providers/resend_webhook_plug_test.exs` | ❌ Wave 0 |
| RESEND-01 | Stale timestamp rejected → 401 | integration | `mix test test/mailglass/webhook/providers/resend_webhook_plug_test.exs` | ❌ Wave 0 |
| RESEND-01 | Missing `svix-id` header → 401 | integration | `mix test test/mailglass/webhook/providers/resend_webhook_plug_test.exs` | ❌ Wave 0 |
| RESEND-02 | Resend events map to correct Anymail atoms | unit | `mix test test/mailglass/webhook/providers/resend_test.exs` | ✅ exists |

### Sampling Rate

- **Per task commit:** `mix test test/mailglass/webhook/ test/mailglass/tracking/endpoint_resolution_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/mailglass/webhook/providers/resend_webhook_plug_test.exs` — covers RESEND-01 (plug-level integration)
- [ ] `test/support/fixtures/webhooks/resend/delivered.json` — fixture file needed by plug tests

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | N/A (webhook ingest, not user auth) |
| V3 Session Management | no | N/A |
| V4 Access Control | no | N/A |
| V5 Input Validation | yes | `Integer.parse/1` for timestamp, `Jason.decode/1` for body |
| V6 Cryptography | yes | `:crypto.mac(:hmac, :sha256, ...)` + `Plug.Crypto.secure_compare/2` |

### Known Threat Patterns for Webhook Ingest

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Forged webhook (signature bypass) | Spoofing | HMAC-SHA256 via `:crypto.mac` — already implemented in `verify!/3` |
| Replay attack | Repudiation | 300-second timestamp tolerance window — already implemented in `verify_timestamp/2` |
| Timing oracle (signature comparison) | Information disclosure | `Plug.Crypto.secure_compare/2` — already used in `valid_signature?/2` |
| PII in logs | Information disclosure | `Logger.warning` includes only `provider` + `e.type` atom — enforced by `do_call/3` rescue clause |

All security controls are already implemented in Phase 14. Phase 17 only wires the provider into the dispatch chain.

[VERIFIED: read lib/mailglass/webhook/plug.ex, lib/mailglass/webhook/providers/resend.ex]

## Sources

### Primary (HIGH confidence)
- `lib/mailglass/webhook/plug.ex` — `@valid_providers`, `resolve_config!/2`, `provider_module/1` exact state verified
- `lib/mailglass/webhook/router.ex` — `@valid_providers`, `@default_providers` exact state verified
- `lib/mailglass/webhook/providers/resend.ex` — `verify!/3` config key names (`secret`, `timestamp_tolerance_seconds`) verified
- `test/support/webhook_case.ex` — full setup block, `using` macro exports, `mailglass_webhook_conn/3` arms all verified
- `test/support/webhook_fixtures.ex` — `sign_resend_payload/4` signature `(svix_id, svix_timestamp, raw_body, secret_bytes)` verified
- `test/mailglass/webhook/plug_test.exs` — the `assert_raise` test for `:resend` at line 38-41 verified
- `test/mailglass/webhook/plug_mailgun_test.exs` — structural template for `resend_webhook_plug_test.exs` verified
- `test/mailglass/webhook/providers/resend_test.exs` — inline payload structure for `delivered.json` fixture shape verified
- `mix test` output — full suite 0 failures confirmed; tracking tests pass clean

### Secondary (MEDIUM confidence)

None — all research was done against the project's own source files.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — verified against live source files
- Architecture: HIGH — all patterns read from existing provider implementations
- Pitfalls: HIGH — derived from code structure and CONTEXT.md specifics

**Research date:** 2026-04-29
**Valid until:** Phase 17 is short-lived; research is valid until execution completes (days, not weeks).
