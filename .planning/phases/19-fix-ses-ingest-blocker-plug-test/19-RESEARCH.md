# Phase 19: Fix SES Ingest BLOCKER + Plug-level Integration Test — Research

**Researched:** 2026-04-30
**Domain:** Webhook ingest seam (provider guard + provider_event_id derivation) + Plug-level integration test infrastructure for SES (SNS-wrapped RSA-signed Notifications)
**Confidence:** HIGH

## Summary

Phase 19 closes the v0.3.0 milestone audit BLOCKER: `Mailglass.Webhook.Ingest.ingest_multi/3` rejects `:ses` at its provider guard (line 122), so any real SES Notification crashes with `%FunctionClauseError{}` after passing signature verification and normalization. The integration gap is invisible because no Plug-level SES test exists — only unit-level `verify!/3` and `normalize/2` tests in `ses_test.exs`.

The fix is exceptionally surgical: **two single-line edits to `lib/mailglass/webhook/ingest.ex`** (add `:ses` to the guard list at line 122; add a `derive_webhook_provider_event_id(:ses, ...)` clause mirroring Mailgun/Resend at line ~376) **plus one new test file** (`test/mailglass/webhook/plug_ses_test.exs`) modeled byte-for-byte after `test/mailglass/webhook/plug_mailgun_test.exs` and `test/mailglass/webhook/providers/resend_webhook_plug_test.exs`. The release ceremony is identical to v0.3.2 — a Conventional Commits `fix:` PR triggers Release Please to cut v0.3.3.

All required test infrastructure already exists: `WebhookCase.mailglass_webhook_conn(:ses, raw_body)` builds the conn (lines 222-228), `WebhookFixtures.generate_sns_keypair/0` + `sign_sns_canonical_string/3` mint signing material at runtime (lines 217-259), `CertCache.put/3` pre-stuffs the cache to bypass network I/O, and 16 SES fixtures live at `test/support/fixtures/webhooks/ses/`. **No new fixtures, no new helpers, no schema changes.**

**Primary recommendation:** Single plan, two ordered tasks: (1) edit `ingest.ex` lines 122 and ~376 with the minimal-diff changes spelled out below, (2) add `test/mailglass/webhook/plug_ses_test.exs` mirroring `plug_mailgun_test.exs` structure with SNS-specific signing (RSA via `sign_sns_canonical_string/3` injected into a fixture, not HMAC). Commit as `fix(ingest): accept :ses provider in webhook ingest seam` to trigger Release Please patch bump to v0.3.3.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Provider guard (atom whitelist) | Backend / Ingest core | — | `Mailglass.Webhook.Ingest` owns the cross-provider compositional seam; per-provider modules don't gate ingest |
| `provider_event_id` derivation per provider | Backend / Ingest core | Provider module (supplies `Event.metadata["provider_event_id"]`) | Ingest reads canonical key from normalized Event metadata; SES `build_event/8` already populates it as `"#{sns_message_id}:#{email}"` |
| Plug-level integration test (signed request → 200 → DB row) | Test (DataCase + WebhookCase + TestRepo) | — | Mirrors existing `plug_mailgun_test.exs` and `resend_webhook_plug_test.exs` pattern verbatim |
| RSA signing of SNS canonical string in test | Test fixture (`WebhookFixtures.sign_sns_canonical_string/3`) | — | Already implemented in Phase 16 Wave 0; reused as-is |
| CertCache pre-population (bypass `:httpc` in tests) | Test setup (`CertCache.put/3`) | — | Pattern established in `ses_test.exs` lines 71-73 |
| Release ceremony (v0.3.3 patch) | CI / Release Please | Hex.pm publish workflow | Conventional Commits `fix:` triggers RP — same path used 3 times in Phase 18 |

## Standard Stack

### Core (already installed — no new dependencies)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:plug` | ~> 1.18 | `Plug.Test.conn/3` for synthesizing requests | Standard Phoenix testing surface |
| `:public_key` | OTP 27 stdlib | RSA sign + verify (`:public_key.sign/3`, `:public_key.verify/4`) | Already used by `WebhookFixtures.sign_sns_canonical_string/3` and `SES.verify!/3` |
| `:crypto` | OTP 27 stdlib | RSA keypair generation (`:public_key.generate_key({:rsa, 2048, 65537})`) | Already used by `WebhookFixtures.generate_sns_keypair/0` |
| `Jason` | (project default) | JSON encode/decode for fixture mutation | Already used to inject `Signature` into payload-only fixtures |
| `Mailglass.WebhookCase` | test/support | Setup template — installs SES config, mints keypair, provides `mailglass_webhook_conn(:ses, ...)` | Already SES-aware (line 222-228) |
| `Mailglass.WebhookFixtures` | test/support | RSA helpers + fixture loader | Already SES-aware (lines 217-267) |
| `Mailglass.TestRepo` | test/support | Sandboxed Ecto repo for `aggregate(WebhookEvent, :count)` | Pattern in `plug_mailgun_test.exs:40` |

### Supporting (no changes needed)
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `release-please` | (CI workflow) | Conventional Commits → semver bump → PR | Triggered by `fix:` commit after merge |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `CertCache.put/3` to pre-stuff cert | Mock `:httpc` via `httpc_client: Mailglass.HTTPCStub` Application env | Pre-stuff is simpler — `Notification` flow doesn't call `:httpc` once cert is cached; HTTPCStub only matters for SubscriptionConfirmation flow (already covered in `ses_test.exs:121`) |
| New SES Plug test in `test/mailglass/webhook/providers/ses_plug_test.exs` (per audit narrative) | Place at `test/mailglass/webhook/plug_ses_test.exs` (mirroring `plug_mailgun_test.exs` location) | Audit says `providers/ses_plug_test.exs`; existing repo convention puts plug tests at `test/mailglass/webhook/plug_<provider>_test.exs`. **Recommendation: follow existing repo convention** — `test/mailglass/webhook/plug_ses_test.exs`. Resend is the lone outlier (`providers/resend_webhook_plug_test.exs`); Mailgun (`plug_mailgun_test.exs`) is the dominant pattern. Roadmap success criterion #3 names `test/mailglass/webhook/providers/ses_plug_test.exs` — flag for planner to confirm with user, but recommend the `plug_ses_test.exs` path for consistency with Mailgun. Either path works functionally; this is purely a naming/co-location choice. |

**Installation:** None required.

**Version verification:** All deps already pinned in `mix.lock` for v0.3.2 release. No new packages to add.

## Architecture Patterns

### System Architecture Diagram

```
        SES → SNS → POST /webhooks/ses
                          │
                          ▼
        Mailglass.Webhook.CachingBodyReader (preserves raw bytes)
                          │
                          ▼
                Mailglass.Webhook.Plug.call/2
                          │
                          ├─► extract_headers_and_raw_body!/1
                          ├─► resolve_config!(:ses, _)        ← reads :mailglass, :ses env
                          │
                          ▼
                  verify!/3 (Providers.SES)
                          │
                ┌─────────┴─────────┐
                │                   │
        Notification:        SubscriptionConfirmation:
        :ok                  {:ok, :control_plane,
                              :subscription_confirmed}
                │                   │
                ▼                   └─► send_resp(200) [PASSING]
        resolve_tenant!  ──► Tenancy.with_tenant/2 (block form)
                │
                ▼
        SES.normalize/2 ──► [%Event{provider_event_id, ...}, ...]
                │
                ▼
        ★ Mailglass.Webhook.Ingest.ingest_multi(:ses, raw_body, events) ★
                │                                     │
                │                                     │ ← BLOCKER HERE
                ▼                                     ▼
        guard at line 122:                  derive_webhook_provider_event_id(:ses, ...)
        when provider in                    NO :ses CLAUSE
        [:postmark, :sendgrid,              (line ~376 default catch-all
        :mailgun, :resend]                   returns "" — wrong)
                │
                │ FunctionClauseError → HTTP 500
                ▼
                X
```

After Phase 19 fix, the ingest path completes:
- guard accepts `:ses` → `Repo.transact/1` runs the Multi
- `derive_webhook_provider_event_id(:ses, _, [first | _])` returns `extract_event_provider_id(first)` which reads `Event.metadata["provider_event_id"]` (`"#{sns_message_id}:#{email}"` per `SES.build_provider_event_id/3` line 641-647)
- `WebhookEvent` row inserts with `(:ses, "<sns_msg_id>:<email>")` as the UNIQUE key
- post-commit broadcast fires; `send_resp(200)`

### Recommended Project Structure (no new directories)

```
lib/mailglass/webhook/
├── ingest.ex                         # EDIT line 122 (guard) + add :ses clause ~line 376
├── plug.ex                           # NO CHANGE — already SES-aware (line 84, 260, 403)
└── providers/
    ├── ses.ex                        # NO CHANGE — populates Event.metadata["provider_event_id"]
    └── ses/
        ├── cert_cache.ex             # NO CHANGE
        └── trust_policy.ex           # NO CHANGE

test/mailglass/webhook/
├── plug_mailgun_test.exs             # CANONICAL ANALOG — mirror this structure
├── plug_test.exs                     # generic plug behaviour tests
└── plug_ses_test.exs                 # NEW (recommended path; see Alternatives table)

test/mailglass/webhook/providers/
├── resend_webhook_plug_test.exs      # second analog (different naming convention)
└── ses_test.exs                      # unit-level (verify!/3 + normalize/2)
```

### Pattern 1: Provider guard expansion (minimal diff)

**What:** Add a single atom to a runtime guard list.
**When to use:** Closing a "provider-supported-everywhere-except-ingest" gap that occurs when a provider's `verify!`/`normalize` ships before the central seam is updated.
**Example (verbatim minimal diff):**

```elixir
# CURRENT (lib/mailglass/webhook/ingest.ex line 121-123) — Source: file:read
def ingest_multi(provider, raw_body, events)
    when provider in [:postmark, :sendgrid, :mailgun, :resend] and is_binary(raw_body) and
           is_list(events) do

# AFTER FIX
def ingest_multi(provider, raw_body, events)
    when provider in [:postmark, :sendgrid, :mailgun, :ses, :resend] and is_binary(raw_body) and
           is_list(events) do
```

`:ses` is inserted between `:mailgun` and `:resend` to preserve the same atom ordering used by `Mailglass.Webhook.Plug.@valid_providers` at line 84 (`[:postmark, :sendgrid, :mailgun, :ses, :resend]`). This keeps the two lists symmetric — every reviewer scanning the seam sees the same atom order both places.

### Pattern 2: `provider_event_id` derivation clause (mirror Mailgun/Resend)

**What:** Add a function clause to a tagged dispatch table.
**When to use:** New provider whose normalize/2 already populates `Event.metadata["provider_event_id"]` (most do — Postmark, Mailgun, Resend, SES all do; only SendGrid is special because of batch idempotency).
**Example (exact verbatim insertion site):**

```elixir
# CURRENT (lib/mailglass/webhook/ingest.ex lines 364-377) — Source: file:read
# Mailgun replay and ingest both key off the webhook token surfaced in
# Event.metadata["provider_event_id"].
defp derive_webhook_provider_event_id(:mailgun, _raw_body, [first | _]) do
  extract_event_provider_id(first) || ""
end

# Resend (Svix) sends one event per webhook with a stable `id` like
# "evt_..."; Phase 14 normalize/2 plumbs that into
# Event.metadata["provider_event_id"], same convention as Postmark.
defp derive_webhook_provider_event_id(:resend, _raw_body, [first | _]) do
  extract_event_provider_id(first) || ""
end

defp derive_webhook_provider_event_id(_provider, _raw_body, []), do: ""

# AFTER FIX — insert new clause between :resend and the empty-list catch-all
# (preserves the @valid_providers atom ordering [:postmark, :sendgrid, :mailgun, :ses, :resend]
# would put :ses before :resend; pick whichever the planner prefers — both are valid).
#
# RECOMMENDED INSERTION between :mailgun and :resend (matches Plug @valid_providers ordering):
# Mailgun replay and ingest both key off the webhook token...
defp derive_webhook_provider_event_id(:mailgun, _raw_body, [first | _]) do
  extract_event_provider_id(first) || ""
end

# SES (SNS) populates `provider_event_id` as "#{sns_message_id}:#{email}" via
# `Mailglass.Webhook.Providers.SES.build_provider_event_id/3` — stable across SNS
# retries because both fields come from the signed payload. Same dispatch as
# Mailgun/Resend.
defp derive_webhook_provider_event_id(:ses, _raw_body, [first | _]) do
  extract_event_provider_id(first) || ""
end

# Resend (Svix) sends one event per webhook...
defp derive_webhook_provider_event_id(:resend, _raw_body, [first | _]) do
  extract_event_provider_id(first) || ""
end

defp derive_webhook_provider_event_id(_provider, _raw_body, []), do: ""
```

The new clause is byte-identical to `:mailgun` and `:resend` clauses except for the atom and the comment. `extract_event_provider_id/1` (lines 382-386) already handles the `%Event{metadata: %{"provider_event_id" => _}}` shape SES emits — no helper changes needed.

### Pattern 3: Plug-level integration test mirroring `plug_mailgun_test.exs`

**What:** End-to-end test that builds a signed conn, calls `WebhookPlug.call/2`, and asserts both HTTP 200 and `WebhookEvent` row count.
**When to use:** Closing an "uncovered seam" gap (the test suite has unit coverage and downstream coverage but nothing exercises the full `Plug.call/2` happy path).
**Example (full file scaffold — see Code Examples section for complete code):**

The template structure is:

```elixir
defmodule Mailglass.Webhook.PlugSESTest do
  use Mailglass.WebhookCase, async: false

  import ExUnit.CaptureLog

  alias Mailglass.TestRepo
  alias Mailglass.Webhook.Plug, as: WebhookPlug
  alias Mailglass.Webhook.Providers.SES.CertCache
  alias Mailglass.Webhook.WebhookEvent

  @cert_url "https://sns.us-east-1.amazonaws.com/SimpleNotificationService-test.pem"

  setup do
    CertCache.reset()
    TestRepo.query!("TRUNCATE TABLE mailglass_webhook_events CASCADE", [])
    TestRepo.query!("TRUNCATE TABLE mailglass_events CASCADE", [])

    # Mint a fresh RSA keypair, pre-stuff the CertCache so verify!/3 finds the
    # public key WITHOUT calling :httpc. This mirrors ses_test.exs:71-73.
    {public_key, private_key} = generate_sns_keypair()
    future = DateTime.add(Mailglass.Clock.utc_now(), 86_400, :second)
    CertCache.put(@cert_url, public_key, future)

    {:ok, private_key: private_key}
  end

  defp sign_ses_fixture(name, private_key) do
    raw = stub_ses_fixture(name)
    payload = Jason.decode!(raw)
    canonical = build_canonical_string(payload, payload["Type"])
    sig = sign_sns_canonical_string(canonical, private_key)
    payload |> Map.put("Signature", sig) |> Jason.encode!()
  end

  defp build_canonical_string(payload, "Notification") do
    ~w(Message MessageId Subject Timestamp TopicArn Type)
    |> Enum.filter(&Map.has_key?(payload, &1))
    |> Enum.map_join(fn k -> "#{k}\n#{payload[k]}\n" end)
  end

  describe "call/2 SES Notification end-to-end" do
    test "200 + persists WebhookEvent on a valid signed Notification", %{private_key: pk} do
      raw = sign_ses_fixture("notification_delivery", pk)
      conn = mailglass_webhook_conn(:ses, raw)

      result = WebhookPlug.call(conn, WebhookPlug.init(provider: :ses))

      assert result.status == 200
      assert TestRepo.aggregate(WebhookEvent, :count) == 1
    end
  end

  describe "call/2 SES bad signature response" do
    test "401 when the SES Message field is tampered", %{private_key: pk} do
      raw = sign_ses_fixture("notification_delivery", pk)
      tampered = String.replace(raw, "\"Message\":", "\"Message\":\"X\", \"X\":", global: false)
      conn = mailglass_webhook_conn(:ses, tampered)

      {result, log} =
        with_log(fn -> WebhookPlug.call(conn, WebhookPlug.init(provider: :ses)) end)

      assert result.status == 401
      assert log =~ "provider=ses"
    end
  end

  describe "call/2 SES SubscriptionConfirmation control-plane" do
    test "200 + does NOT persist WebhookEvent (control-plane no-op)", %{private_key: pk} do
      # IMPORTANT: SubscriptionConfirmation triggers an :httpc GET to the
      # constructed ConfirmSubscription URL (D-07). Inject HTTPCStub via
      # Application env so the test does not hit the network.
      Application.put_env(:mailglass, :ses,
        enabled: true,
        cert_cache_ttl_seconds: 86_400,
        httpc_client: Mailglass.HTTPCStub  # defined in test/.../ses_test.exs
      )

      raw =
        "subscription_confirmation"
        |> stub_ses_fixture()
        |> sign_subscription_confirmation_fixture(pk)  # signs the control-plane keys

      conn = mailglass_webhook_conn(:ses, raw)
      result = WebhookPlug.call(conn, WebhookPlug.init(provider: :ses))

      assert result.status == 200
      # Control-plane: NO WebhookEvent row inserted (verify!/3 returns
      # {:ok, :control_plane, :subscription_confirmed} which short-circuits
      # before ingest_multi/3 — see plug.ex line 137-146).
      assert TestRepo.aggregate(WebhookEvent, :count) == 0
    end
  end
end
```

### Anti-Patterns to Avoid

- **Don't add a per-event helper to `WebhookFixtures` for the SES plug test.** All RSA primitives already exist (`generate_sns_keypair/0`, `sign_sns_canonical_string/3`); the canonical-string builder belongs inside the test module (it's already inlined in `ses_test.exs:42-57`).
- **Don't query for the persisted `WebhookEvent` by content.** Use `TestRepo.aggregate(WebhookEvent, :count) == 1` — same pattern as `plug_mailgun_test.exs:40` and `resend_webhook_plug_test.exs:35`. Tests that introspect row content tend to drift from production reality (audit-table-style assertions belong in `ses_test.exs` unit tests).
- **Don't use `Mailglass.HTTPCStub` for the Notification test.** Once `CertCache.put/3` runs in `setup`, the `verify!/3` cert path skips `:httpc` entirely. Adding stub config there is dead code and signals confusion about the verification flow.
- **Don't pattern-match `SignatureError` by message string.** Already a CLAUDE.md rule (errors as struct contracts) — but a temptation surfaces in tampered-fixture tests. Match `%SignatureError{type: :bad_signature, provider: :ses}` if you need to inspect the exception (the existing tests just assert `result.status == 401` and `log =~ "provider=ses"`).
- **Don't add a fixture file with a baked-in signature.** Fixtures stay payload-only with `"Signature": "PLACEHOLDER_REPLACED_AT_TEST_RUNTIME"`. The `sign_ses_fixture/2` helper inside the test module mutates the JSON at runtime — same pattern as `ses_test.exs:59-65`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| RSA keypair for tests | `:crypto.generate_key/2` direct | `WebhookFixtures.generate_sns_keypair/0` | Returns `{:RSAPublicKey, n, e}` shape that `CertCache` expects |
| RSA signing of canonical string | `:public_key.sign/3` direct | `WebhookFixtures.sign_sns_canonical_string/3` | Already `:sha` digest default + Base64 encode |
| Building the canonical string | New module | Inline `defp build_canonical_string/2` in the test | 8 lines; pattern is already inlined in `ses_test.exs:42-57` |
| Signed conn skeleton | New helper | `WebhookCase.mailglass_webhook_conn(:ses, raw_body)` | Lines 222-228 already wire `content-type: text/plain` + `x-amz-sns-message-type: Notification` + `conn.private[:raw_body]` |
| SES fixture loading | `File.read!` direct | `stub_ses_fixture/1` (re-exported via WebhookCase) | Resolves path via `@fixture_root` |
| TestRepo sandbox setup | New `Sandbox.checkout` boilerplate | `use Mailglass.WebhookCase, async: false` | Inherits MailerCase setup (sandbox, tenancy stamping, PubSub subscribe) |
| Truncate before each test | New helper | `TestRepo.query!("TRUNCATE TABLE mailglass_webhook_events CASCADE", [])` in `setup` | Verbatim from `plug_mailgun_test.exs:13-14` |

**Key insight:** Phase 16 Wave 0 already shipped every test primitive Phase 19 needs. The work is composition, not creation.

## Common Pitfalls

### Pitfall 1: Signing the wrong canonical key set for control-plane vs. Notification
**What goes wrong:** SubscriptionConfirmation/UnsubscribeConfirmation use a DIFFERENT signable-keys list than Notification (the control-plane variants include `SubscribeURL` and `Token` but omit `Subject`). Signing with the wrong list produces a signature that fails `:public_key.verify/4`.
**Why it happens:** `ses_test.exs:42-57` defines two `build_canonical_string/2` clauses — one for `"Notification"`, one for `"SubscriptionConfirmation" | "UnsubscribeConfirmation"`. Easy to miss the second clause when copy-pasting.
**How to avoid:** Copy BOTH clauses verbatim into the new plug test. Use `payload["Type"]` to dispatch — exactly what `sign_fixture/2` in `ses_test.exs:59-65` does.
**Warning signs:** Test fails with HTTP 401 on a "valid" SubscriptionConfirmation fixture; logs show `provider=ses reason=bad_signature`.

### Pitfall 2: Forgetting to `CertCache.reset/0` in `setup`
**What goes wrong:** Previous test's stale public key is still in ETS; new test's keypair signs fixtures that the previous public key cannot verify.
**Why it happens:** `Mailglass.Webhook.Providers.SES.CertCache` is a module-level singleton ETS table — it persists across tests within a file unless explicitly reset. `WebhookCase.setup` mints a fresh keypair per test (line 82) but does NOT touch `CertCache` (it doesn't know about SES specifics).
**How to avoid:** Call `CertCache.reset()` in the test module's `setup` block. Pattern verbatim from `ses_test.exs:27-29`.
**Warning signs:** First test in the file passes, subsequent tests fail with `bad_signature` even though signing logic looks correct.

### Pitfall 3: Sandbox connection ownership for `with_tenant/2` block
**What goes wrong:** `Mailglass.Webhook.Plug` calls `Tenancy.with_tenant(tenant_id, fn -> ... end)` (plug.ex:153). The block runs in the calling process. If the calling process is the test process, sandbox connection is owned correctly. If the test runs `async: true`, sandbox mode is `:manual` and connection ownership is per-process — the block runs fine because it's the same process.
**Why it happens:** This is actually NOT a problem here — `Plug.call/2` runs synchronously in the test process, so all DB work happens under the test's checked-out connection. But the temptation to use `async: true` may surface; resist.
**How to avoid:** Always `use Mailglass.WebhookCase, async: false` for plug-level webhook tests. The `setup` block in `WebhookCase` mutates `Application.put_env(:mailglass, :ses, ...)` (line 117-120) — concurrent async tests would clobber each other.
**Warning signs:** Sporadic test failures on CI, especially when test ordering changes.

### Pitfall 4: Reading the wrong `:mailglass, :ses` env after WebhookCase install
**What goes wrong:** `WebhookCase.setup` (lines 117-120) installs `Application.put_env(:mailglass, :ses, enabled: true, cert_cache_ttl_seconds: 86_400)`. Tests that need `httpc_client: HTTPCStub` (SubscriptionConfirmation flow) must `Application.put_env/3` to MERGE not REPLACE this — or remember to re-include `cert_cache_ttl_seconds`.
**Why it happens:** The default install does NOT include `httpc_client`, so `httpc_client/1` (ses.ex:351-362) falls through to `:httpc` (real network). For `Notification` flow this is fine because cert is pre-stuffed. For `SubscriptionConfirmation` it would hit AWS for real.
**How to avoid:** For SubscriptionConfirmation tests, write a complete put_env: `enabled: true, cert_cache_ttl_seconds: 86_400, httpc_client: Mailglass.HTTPCStub`. For Notification tests (the primary success-criterion #3 test), no env mutation is needed.
**Warning signs:** Test hangs (network call to `sns.us-east-1.amazonaws.com`) or fails with `:httpc` error on CI runners without internet.

### Pitfall 5: `Mailglass.HTTPCStub` is defined in `ses_test.exs` (test file, not test/support)
**What goes wrong:** Plug test references `Mailglass.HTTPCStub` but the module is only defined inside `ses_test.exs` (the file's prelude lines 1-7), not in `test/support/`. ExUnit may compile test files in any order.
**Why it happens:** `ses_test.exs:1-7` defines `Mailglass.HTTPCStub` as a top-level module inside the test file. Other test files referencing it depend on `ses_test.exs` having been compiled first.
**How to avoid:** Either (a) use `Mailglass.HTTPCStub` only in tests that are in the same file (the plug test for SubscriptionConfirmation can be a separate test module in the same file as the Notification plug test, OR — recommended — (b) don't write a SubscriptionConfirmation case at the plug level (it's already covered in `ses_test.exs:121-123` and is a control-plane no-op that doesn't exercise the broken seam). Phase 19 success criteria call out `Notification` only.
**Warning signs:** `(CompileError) undefined module Mailglass.HTTPCStub` when running the new test in isolation via `mix test test/mailglass/webhook/plug_ses_test.exs`.

### Pitfall 6: `derive_webhook_provider_event_id/3` empty-list fallback returns `""`
**What goes wrong:** A `Notification` whose `Message` field doesn't decode as JSON (or has neither `notificationType` nor `eventType`) produces `[]` from `SES.normalize/2` (lines 121-131, 374-377). The empty-list catch-all clause (`derive_webhook_provider_event_id(_provider, _raw_body, []), do: ""`) returns `""`. The `WebhookEvent` row inserts with `provider_event_id: ""`. Subsequent identical-degenerate webhooks all collide on `(:ses, "")` — silent dedup.
**Why it happens:** Existing behavior mirrors Mailgun/Resend; not new to Phase 19. But it's worth documenting in the test plan that the new SES test should use a fixture (`notification_delivery`) that produces a non-empty event list.
**How to avoid:** Use the canonical happy-path fixture `notification_delivery` (already exists; produces 1 event). Don't write tests against `notification_empty` or malformed payloads — those belong in `ses_test.exs` unit tests.
**Warning signs:** Test passes but `WebhookEvent.provider_event_id` is empty string; `aggregate(WebhookEvent, :count)` returns 1 after the first call but stays at 1 after subsequent identical calls (UNIQUE collision).

### Pitfall 7: Roadmap success-criterion path mismatch
**What goes wrong:** Roadmap success criterion #3 names the new file `test/mailglass/webhook/providers/ses_plug_test.exs`. But existing convention (`plug_mailgun_test.exs`, `plug_test.exs`) places plug-level tests at `test/mailglass/webhook/plug_<provider>_test.exs`. The Resend plug test is the lone outlier (`providers/resend_webhook_plug_test.exs`).
**Why it happens:** Likely a copy-paste from the audit narrative which referenced the Resend file.
**How to avoid:** Plan should explicitly choose ONE path. **Recommendation: `test/mailglass/webhook/plug_ses_test.exs`** (Mailgun pattern; cleaner separation between unit tests in `providers/` and plug tests in `webhook/`). If user prefers the audit-stated path, both work — flag this as a discretion area in the plan.
**Warning signs:** None at runtime; this is a code-organization preference. Pick one and document the choice.

## Code Examples

### Complete `plug_ses_test.exs` template (recommended path)

```elixir
# test/mailglass/webhook/plug_ses_test.exs
defmodule Mailglass.Webhook.PlugSESTest do
  use Mailglass.WebhookCase, async: false

  import ExUnit.CaptureLog

  alias Mailglass.TestRepo
  alias Mailglass.Webhook.Plug, as: WebhookPlug
  alias Mailglass.Webhook.Providers.SES.CertCache
  alias Mailglass.Webhook.WebhookEvent

  @cert_url "https://sns.us-east-1.amazonaws.com/SimpleNotificationService-test.pem"

  setup do
    CertCache.reset()
    TestRepo.query!("TRUNCATE TABLE mailglass_webhook_events CASCADE", [])
    TestRepo.query!("TRUNCATE TABLE mailglass_events CASCADE", [])

    {public_key, private_key} = generate_sns_keypair()
    future = DateTime.add(Mailglass.Clock.utc_now(), 86_400, :second)
    CertCache.put(@cert_url, public_key, future)

    {:ok, private_key: private_key}
  end

  # ---- helpers (mirrors ses_test.exs:42-65) ----

  defp build_canonical_string(payload, "Notification") do
    ~w(Message MessageId Subject Timestamp TopicArn Type)
    |> Enum.filter(&Map.has_key?(payload, &1))
    |> Enum.map_join(fn k -> "#{k}\n#{payload[k]}\n" end)
  end

  defp sign_ses_fixture(name, private_key) do
    raw = stub_ses_fixture(name)
    payload = Jason.decode!(raw)
    canonical = build_canonical_string(payload, payload["Type"])
    sig = sign_sns_canonical_string(canonical, private_key)
    payload |> Map.put("Signature", sig) |> Jason.encode!()
  end

  # ---- success path (closes BLOCKER) ----

  describe "call/2 SES Notification end-to-end" do
    test "returns 200 and persists WebhookEvent on a valid signed Notification",
         %{private_key: private_key} do
      raw = sign_ses_fixture("notification_delivery", private_key)
      conn = mailglass_webhook_conn(:ses, raw)

      result = WebhookPlug.call(conn, WebhookPlug.init(provider: :ses))

      assert result.status == 200
      assert TestRepo.aggregate(WebhookEvent, :count) == 1
    end

    test "returns 200 and persists once on a replayed Notification",
         %{private_key: private_key} do
      raw = sign_ses_fixture("notification_delivery", private_key)
      conn = mailglass_webhook_conn(:ses, raw)

      first = WebhookPlug.call(conn, WebhookPlug.init(provider: :ses))
      second = WebhookPlug.call(conn, WebhookPlug.init(provider: :ses))

      assert first.status == 200
      assert second.status == 200
      assert TestRepo.aggregate(WebhookEvent, :count) == 1
    end
  end

  # ---- bad signature path (defense-in-depth) ----

  describe "call/2 SES bad signature response" do
    test "returns 401 when the Message field is tampered",
         %{private_key: private_key} do
      raw = sign_ses_fixture("notification_delivery", private_key)
      tampered =
        String.replace(raw, "\"Message\":", "\"Message\":\"TAMPERED\", \"X\":", global: false)
      conn = mailglass_webhook_conn(:ses, tampered)

      {result, log} =
        with_log(fn ->
          WebhookPlug.call(conn, WebhookPlug.init(provider: :ses))
        end)

      assert result.status == 401
      assert log =~ "provider=ses"
      refute log =~ raw
    end
  end

  # ---- explicit route execution (matches plug_mailgun_test.exs:130-133) ----

  describe "call/2 SES explicit route execution" do
    test "init/1 accepts :ses as an explicit provider" do
      assert Keyword.get(WebhookPlug.init(provider: :ses), :provider) == :ses
    end
  end
end
```

### Verbatim ingest.ex diff (the entire BLOCKER closure)

```diff
--- a/lib/mailglass/webhook/ingest.ex
+++ b/lib/mailglass/webhook/ingest.ex
@@ -119,7 +119,7 @@ defmodule Mailglass.Webhook.Ingest do
   @spec ingest_multi(atom(), binary(), [Event.t()]) ::
           {:ok, map()} | {:error, term()}
   def ingest_multi(provider, raw_body, events)
-      when provider in [:postmark, :sendgrid, :mailgun, :resend] and is_binary(raw_body) and
+      when provider in [:postmark, :sendgrid, :mailgun, :ses, :resend] and is_binary(raw_body) and
              is_list(events) do
     # Tenancy.tenant_id!/0 is the fail-loud accessor — raises %TenancyError{:unstamped}
     # when the process-dict key is absent. Unlike Tenancy.current/0 (which falls back
@@ -366,6 +366,13 @@ defmodule Mailglass.Webhook.Ingest do
   defp derive_webhook_provider_event_id(:mailgun, _raw_body, [first | _]) do
     extract_event_provider_id(first) || ""
   end

+  # SES (SNS) populates `provider_event_id` as "#{sns_message_id}:#{email}" via
+  # `Mailglass.Webhook.Providers.SES.build_provider_event_id/3`. Stable across SNS
+  # retries because both fields come from the signed payload. Same dispatch as
+  # Mailgun/Resend.
+  defp derive_webhook_provider_event_id(:ses, _raw_body, [first | _]) do
+    extract_event_provider_id(first) || ""
+  end
+
   # Resend (Svix) sends one event per webhook with a stable `id` like
   # "evt_..."; Phase 14 normalize/2 plumbs that into
   # Event.metadata["provider_event_id"], same convention as Postmark.
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Plug seam + Provider hardcoded ingest dispatch (Phase 1-3 prototype) | Provider atom guard + per-provider `derive_webhook_provider_event_id/3` clauses | Phase 4 (HOOK-06 → CONTEXT D-15 amendment) | Adding a new provider = 2 line edits in `ingest.ex` + populate `Event.metadata["provider_event_id"]` in normalize |
| Hand-rolled ECDSA/RSA signing in tests | `WebhookFixtures` shared signing helpers per provider | Phase 4 (TEST-03 / Wave 0) | Test files stay focused on ingest semantics, not crypto plumbing |
| Network-dependent SES tests | `CertCache.put/3` pre-stuffing + `httpc_client` config injection | Phase 16 Wave 1-2 | All SES tests run with no internet — CI deterministic |
| Plug-level webhook tests via `Plug.Test.conn/3` boilerplate | `WebhookCase.mailglass_webhook_conn(:provider, raw_body)` helper | Phase 4 + extended Phase 14, 15, 16 | One-liner conn construction; signature attached automatically |

**Deprecated/outdated:**
- Pre-Phase-15 `derive_webhook_provider_event_id/3` only had Postmark and SendGrid clauses; the empty-list catch-all was the only fallback. Mailgun (Phase 15) and Resend (Phase 14) added provider-specific clauses. SES is the missing one.

## Project Constraints (from CLAUDE.md)

| Rule | How Phase 19 complies |
|------|-----------------------|
| Errors as a public API contract | New code adds no new error types; existing `%SignatureError{type: :bad_signature, provider: :ses}` already covers the bad-signature path |
| Telemetry on `[:mailglass, :webhook, :*]` with no PII | No telemetry changes; the existing `WebhookTelemetry.ingest_span/2` (plug.ex:107) auto-covers the `:ses` path once the guard accepts it |
| Append-only `mailglass_events` | No schema changes; `ingest_multi/3` already enforces SQLSTATE 45A01 trigger semantics for `:ses` (the same code path as `:postmark`/`:mailgun`/`:resend`) |
| Multi-tenancy first-class | `Mailglass.Tenancy.with_tenant/2` block form in `plug.ex:153` is provider-agnostic; SES inherits the SingleTenant default `"default"` resolver via `Tenancy.resolve_webhook_tenant/1` |
| Sibling packages with linked-version releases | v0.3.3 patch via Release Please `separate-pull-requests: false` + linked-versions plugin (verified working in Phase 18 — see PRs #21 and #24) |
| Custom Credo checks at lint time | New code adds no new Credo checks; existing checks (no `Application.compile_env*` outside `Mailglass.Config`, no PII in telemetry, etc.) all pass |
| Optional deps gated through `Mailglass.OptionalDeps.*` | No optional-dep boundaries crossed |
| Open/click tracking off by default | No tracking changes |
| Don't UPDATE/DELETE `mailglass_events` | Phase 19 only adds INSERT paths via existing append flow |
| Don't put PII in telemetry metadata | Confirmed — existing `WebhookTelemetry.normalize_emit/1` (ingest.ex:510-514) emits only `provider, event_type, mapped`. SES inherits this. |
| Don't recover from webhook signature failures | Compliant — `SignatureError` raises and the existing rescue in `plug.ex:163` returns 401. New SES test exercises this exact rescue path. |
| Don't pattern-match errors by message string | Compliant — test asserts `result.status == 401` and `log =~ "provider=ses"` (log content, not exception message) |
| Don't ship marketing-email features | Phase 19 is webhook ingest only — no marketing features |

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SES-01 | text/plain SNS parsing | `Mailglass.Webhook.CachingBodyReader` already handles `text/plain`; `WebhookCase.mailglass_webhook_conn(:ses, ...)` lines 222-228 set `content-type: text/plain`; new plug test asserts the full pipe runs end-to-end |
| SES-03 | RSA sig verification | `WebhookFixtures.sign_sns_canonical_string/3` already implemented; `CertCache.put/3` pre-stuffing already covered; new plug test exercises the full verify → ingest flow |
| SES-04 | X.509 cert ETS cache | `CertCache.put/3` (lines 60-63) is the API surface for test setup; same line is exercised by the new plug test (closes the "uncovered seam" gap) |
| SES-05 | SES events → taxonomy | `SES.normalize/2` already produces `[%Event{type: :delivered, ...}]` for the `notification_delivery` fixture (verified in `ses_test.exs:166-171`); new plug test confirms these events flow through `ingest_multi/3` |

All four requirements are unsatisfied **end-to-end** because of the BLOCKER (audit lines 17-46). Closing the BLOCKER and adding the integration test satisfies all four simultaneously — they are not independent work items.

## Runtime State Inventory

> Phase 19 is a code-edit phase, not a rename/refactor/migration. The 5-category audit below is included for completeness but every category resolves to "nothing to do."

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — verified by inspection. `mailglass_events` and `mailglass_webhook_events` tables already accept `provider = 'ses'` strings (the schema column is `:string`, no enum constraint at DB level). Existing rows from prior unit-test runs are unaffected. | none |
| Live service config | None — no n8n / Datadog / Tailscale / Cloudflare config references SES ingest. SES Application env (`config :mailglass, :ses, ...`) is read at runtime from app config files; no service-side state. | none |
| OS-registered state | None — no Task Scheduler / pm2 / systemd / launchd registration touches SES. | none |
| Secrets and env vars | None — SES requires no shared secret (RSA verification uses fetched X.509 certs). `HEX_API_KEY` for the v0.3.3 publish is already configured (per memory file: "HEX_API_KEY configured"). | none |
| Build artifacts / installed packages | None — no compiled artifacts depend on the SES dispatch path. `mix deps.compile` is incremental; touching `ingest.ex` recompiles only modules that depend on it. | none |

**The canonical question** — *After every file in the repo is updated, what runtime systems still have the old behavior cached, stored, or registered?* — resolves to **nothing**. Phase 19 is a pure source-code change with no runtime-state migration component.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Erlang/OTP | All | ✓ | OTP 27 (per Phase 16 research) | — |
| Elixir | All | ✓ | per `.tool-versions` | — |
| PostgreSQL | TestRepo sandbox | ✓ (assumed; required for `mix test`) | per dev environment | — |
| `:public_key` (OTP stdlib) | RSA sign/verify | ✓ | OTP 27 stdlib | — |
| `:crypto` (OTP stdlib) | RSA keypair gen | ✓ | OTP 27 stdlib | — |
| `git` + `gh` CLI | Release Please trigger | ✓ (used in Phase 18) | — | — |
| Hex.pm `HEX_API_KEY` | v0.3.3 publish | ✓ (configured per user memory) | — | — |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir stdlib) |
| Config file | `test/test_helper.exs` (assumed standard); `Mailglass.WebhookCase` + `Mailglass.MailerCase` + `Mailglass.DataCase` test templates |
| Quick run command | `mix test test/mailglass/webhook/plug_ses_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SES-01 | text/plain SNS Notification flows through Plug end-to-end and persists | integration (plug-level) | `mix test test/mailglass/webhook/plug_ses_test.exs:<line of "200 and persists" test>` | ❌ Wave 0 — to create in Phase 19 plan |
| SES-03 | Valid RSA signature on SNS Notification accepted (full pipe) | integration (plug-level) | (same test as SES-01 — these requirements collapse at the seam) | ❌ Wave 0 |
| SES-03 (negative) | Tampered Message field rejected with 401 | integration (plug-level) | `mix test test/mailglass/webhook/plug_ses_test.exs:<line of "401 when tampered" test>` | ❌ Wave 0 |
| SES-04 | CertCache reachable from Plug-level flow (cache hit returns public key) | integration (plug-level) | (covered implicitly by success test — `CertCache.put/3` in setup is the cache hit path) | ❌ Wave 0 |
| SES-05 | Normalized SES events persist to `mailglass_events` | integration (plug-level) | `assert TestRepo.aggregate(WebhookEvent, :count) == 1` (success test) | ❌ Wave 0 |
| SES-01..05 | `mix test` passes clean (no `--only`, no exclusions) | smoke (full suite) | `mix test` | ✅ exists, must stay green |

### Sampling Rate
- **Per task commit:** `mix test test/mailglass/webhook/plug_ses_test.exs && mix test test/mailglass/webhook/providers/ses_test.exs`
- **Per wave merge:** `mix test test/mailglass/webhook/`
- **Phase gate:** `mix test` (full suite green) before `/gsd-verify-work`; CI green before Release Please tags v0.3.3.

### Wave 0 Gaps
- [ ] `test/mailglass/webhook/plug_ses_test.exs` — covers SES-01, SES-03, SES-04, SES-05 (single file)
- [ ] No new fixtures needed (16 SES fixtures already at `test/support/fixtures/webhooks/ses/`)
- [ ] No new helpers needed (`generate_sns_keypair/0` + `sign_sns_canonical_string/3` + `mailglass_webhook_conn(:ses, ...)` + `CertCache.put/3` all already exist)
- [ ] No framework install / config changes needed

## Security Domain

> `security_enforcement` is enabled by default (config.json does not explicitly disable). This phase touches the webhook signature-verification seam, so security review is appropriate.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no (webhook caller is a system, not a user) | — |
| V3 Session Management | no | — |
| V4 Access Control | no (tenant resolution happens AFTER signature verify per D-13; not changed here) |  — |
| V5 Input Validation | yes (raw_body parsing, SNS field extraction) | Existing `decode_payload!/1` + `fetch_required_field!/2` (ses.ex:192-216) — no changes |
| V6 Cryptography | yes (RSA signature verification with cached X.509 certs) | `:public_key.verify/4` with `:public_key.cacerts_get/0` for TLS — already in place. **Phase 19 adds no new crypto.** |
| V14 Configuration | yes (Application env for SES) | No new env keys; no new boot validation needed (Mailglass.Config @schema gap is a Phase 20 concern, not Phase 19) |

### Known Threat Patterns for SES SNS webhook stack

| Pattern | STRIDE | Standard Mitigation | Already in Place? |
|---------|--------|---------------------|-------------------|
| Replay attack (resending captured signed payload) | Repudiation | UNIQUE constraint on `(provider, provider_event_id)` + `on_conflict: :nothing` returns 200 (idempotent no-op) | ✓ — `WebhookEvent` schema (line 9-12); ingest.ex:215-222 |
| Forged SNS payload | Spoofing | RSA-SHA1/SHA256 verification against AWS-published X.509 cert (D-05) | ✓ — `SES.verify!/3` (line 76-106) |
| SSRF via crafted `SigningCertURL` | Tampering | `TrustPolicy.valid_cert_url?/1` validates URL host + scheme BEFORE network I/O (D-06) | ✓ — `SES.verify!/3` (line 63-68) |
| SubscriptionConfirmation hijack (attacker tricks system into following a forged URL) | Spoofing | D-07 — auto-confirm via constructed URL from signed `TopicArn` + `Token`, NEVER follow raw `SubscribeURL` | ✓ — `SES.dispatch_message_type/3` (line 139-173) |
| `ingest_multi/3` rejects valid SES → DoS | Denial of Service | **THIS IS THE BUG** — Phase 19 closes it by adding `:ses` to the guard | ❌ → ✓ after Phase 19 |
| PII leakage via Logger | Information Disclosure | `Logger.warning("[mailglass] Webhook signature failed: provider=ses reason=#{e.type}")` includes only provider + atom — no body, no headers | ✓ — `plug.ex:163-173`; new test asserts `refute log =~ raw_body` |

**Phase 19 introduces no new attack surface.** The fix re-enables a code path that was already designed and crypto-verified in Phase 16. The new test file extends test surface coverage but adds no production code beyond the 8-line ingest.ex diff.

## Files to Touch (definitive list)

| File | Change | Lines | Risk |
|------|--------|-------|------|
| `lib/mailglass/webhook/ingest.ex` | Edit guard list at line 122; add `derive_webhook_provider_event_id(:ses, ...)` clause | +6 / -1 | LOW — pattern is identical to existing `:mailgun` and `:resend` clauses; no behavioral surprises |
| `test/mailglass/webhook/plug_ses_test.exs` | NEW file | ~120 lines | LOW — composes existing test primitives; no new helpers |
| `mix.exs` (`@version`) | NO CHANGE — Release Please bumps automatically | — | — |
| `mailglass_admin/mix.exs` (`@version` + `:mailglass` pin) | NO CHANGE — Release Please linked-versions plugin handles this | — | — |
| `CHANGELOG.md` | NO MANUAL EDIT — Release Please auto-generates entry from `fix:` commit | — | — |
| `.planning/STATE.md`, `.planning/ROADMAP.md` | Updated by `/gsd-execute-phase` and `/gsd-verify-work` | — | — |

**Total production code change: ~7 lines (1 line in guard + 6-line clause + comment).**
**Total test code addition: 1 file, ~120 lines.**

## Open Questions (RESOLVED)

1. **New test file location: `test/mailglass/webhook/plug_ses_test.exs` (Mailgun pattern) vs. `test/mailglass/webhook/providers/ses_plug_test.exs` (Resend pattern + roadmap success criterion)?**
   - What we know: Both paths work; the codebase has both conventions in active use.
   - What's unclear: User intent. Roadmap line 105 says `test/mailglass/webhook/providers/ses_plug_test.exs` (matches Resend); existing convention favors `test/mailglass/webhook/plug_ses_test.exs` (matches Mailgun).
   - **RESOLVED:** Use the Mailgun convention `test/mailglass/webhook/plug_ses_test.exs` (planner choice; honored by Plan 19-02 `files_modified`). Rationale: cleaner separation between unit tests in `providers/` and Plug-level integration tests in `webhook/`. Roadmap text was a copy-paste from the Resend analog; both paths function identically.
   - Recommendation: Plan should explicitly choose one. Default to the **Mailgun convention (`plug_ses_test.exs`)** for cleaner separation between unit tests (`providers/`) and plug-level tests (`webhook/`). If the planner / discuss-phase prefers honoring the roadmap text verbatim, the alternate path also works — flag for user confirmation.

2. **Should the new test cover SubscriptionConfirmation flow at the plug level, or rely on the existing unit test at `ses_test.exs:121`?**
   - What we know: Roadmap success criterion #3 explicitly says "real signed SES Notification" — singular, Notification-only. The audit BLOCKER is also Notification-only (control plane never reaches `ingest_multi/3`).
   - What's unclear: Whether a defense-in-depth SubscriptionConfirmation plug test adds enough value to justify the `Mailglass.HTTPCStub` cross-file dependency (Pitfall 5).
   - **RESOLVED:** Skip SubscriptionConfirmation at the plug level — already covered by existing unit test `ses_test.exs:121`. Phase 19 plug test stays Notification-only, matching Roadmap Phase 19 success criterion #3 verbatim. Plan 19-02 explicitly excludes SubscriptionConfirmation tests (enforced by `<success_criteria>` block).
   - Recommendation: Skip SubscriptionConfirmation at the plug level (covered by existing unit test). Phase 19 plug test stays Notification-focused, matching success criterion #3 verbatim.

3. **Should the new clause in `derive_webhook_provider_event_id/3` be inserted before or after the `:resend` clause?**
   - What we know: Both are equivalent functionally; `extract_event_provider_id/1` is content-agnostic.
   - What's unclear: Stylistic ordering preference.
   - **RESOLVED:** Insert the new `:ses` clause between the existing `:mailgun` and `:resend` clauses in `derive_webhook_provider_event_id/3` to match `@valid_providers` ordering (`[:postmark, :sendgrid, :mailgun, :ses, :resend]`) at `plug.ex:84`. Plan 19-01 Task 19-01-02 specifies this insertion point explicitly.
   - Recommendation: Insert between `:mailgun` (line 366) and `:resend` (line 373) to match `Mailglass.Webhook.Plug.@valid_providers` ordering at plug.ex:84 (`[:postmark, :sendgrid, :mailgun, :ses, :resend]`). This keeps reviewers seeing the same atom order in both places.

4. **Conventional Commits message format for the fix.**
   - What we know: Phase 18 used `fix(release):`, `fix(install):`, `fix(dialyzer):`, `fix(ci):` — all triggered patch bumps. Roadmap success criterion #5 says "Conventional Commits `fix:`".
   - What's unclear: Specific scope qualifier.
   - **RESOLVED:** Use `fix(ingest): accept :ses provider in webhook ingest seam` as the Conventional Commits subject. Plan 19-03 SUMMARY frontmatter and Task 19-03-02 acceptance criteria reference this exact string. Release Please will consume the `fix:` type and cut v0.3.3 on merge to main.
   - Recommendation: `fix(ingest): accept :ses provider in webhook ingest seam` (or `fix(webhook):`) — captures the seam being fixed. Single PR with the ingest.ex edit + new test file. Release Please will produce v0.3.3 from this on merge to main.

## Assumptions Log

> All factual claims tagged `[ASSUMED]` here. Source-code claims `[VERIFIED: file:read]`, citations `[CITED]`, and inferences `[ASSUMED]`.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| (none) | All technical claims in this research were verified by direct read of `lib/mailglass/webhook/ingest.ex`, `lib/mailglass/webhook/plug.ex`, `lib/mailglass/webhook/providers/ses.ex`, `lib/mailglass/webhook/providers/ses/cert_cache.ex`, `lib/mailglass/webhook/webhook_event.ex`, `test/support/webhook_case.ex`, `test/support/webhook_fixtures.ex`, `test/support/mailer_case.ex`, `test/mailglass/webhook/providers/ses_test.exs`, `test/mailglass/webhook/providers/resend_webhook_plug_test.exs`, `test/mailglass/webhook/plug_mailgun_test.exs`, `.planning/STATE.md`, `.planning/ROADMAP.md`, `.planning/v0.3.0-MILESTONE-AUDIT.md`, `.release-please-manifest.json`, and `git log` output. | — | — |
| A1 | Hex.pm `HEX_API_KEY` is currently valid and write-rights working | Environment Availability | LOW — confirmed via user memory; verified empirically by Phase 18 publishing v0.3.2 |
| A2 | The roadmap success-criterion file path `test/mailglass/webhook/providers/ses_plug_test.exs` was a copy-paste from the audit (which referenced the Resend file by analogy) and the Mailgun-convention path is preferable | Open Questions #1, Alternatives Considered | LOW — purely stylistic; both paths function identically. Flagged for user confirmation. |
| A3 | Release Please will cut v0.3.3 from a `fix:` commit without manual intervention | Files to Touch, Open Questions #4 | LOW — Phase 18 demonstrated this 3 times (PRs #20, #22, #23); pattern is well-validated |
| A4 | `mix test` already passes clean today (Phase 18 closed with full suite green) | Validation Architecture | LOW — required by Phase 18 success criterion #4 ("`mix test` passes clean"); state is "Milestone v0.3 complete" |

## Sources

### Primary (HIGH confidence)
- `lib/mailglass/webhook/ingest.ex` — full file read, 540 lines. Confirmed exact location of guard (line 122) and `derive_webhook_provider_event_id/3` clauses (lines 352-377).
- `lib/mailglass/webhook/plug.ex` — full file read. Confirmed `@valid_providers` includes `:ses` (line 84), `resolve_config!(:ses, _)` exists (line 260), `provider_module(:ses)` exists (line 403). The plug is fully SES-aware; only `ingest_multi/3` rejects.
- `lib/mailglass/webhook/providers/ses.ex` — full file read. Confirmed `build_event/8` populates `Event.metadata["provider_event_id"]` as `"#{sns_message_id}:#{email}"` (lines 597, 641-647). `extract_event_provider_id/1` (ingest.ex:382-386) reads exactly this key.
- `lib/mailglass/webhook/webhook_event.ex` — full file read. Schema confirmed; `provider :string` field accepts `"ses"` with no enum constraint.
- `test/support/webhook_case.ex` — full file read. `mailglass_webhook_conn(:ses, raw_body)` defined at lines 222-228; SES Application env install at lines 117-120; `stub_ses_fixture/1` re-exported at lines 337-338.
- `test/support/webhook_fixtures.ex` — full file read. `generate_sns_keypair/0` (lines 217-228), `sign_sns_canonical_string/3` (lines 248-259), `load_ses_fixture/1` (lines 264-267).
- `test/mailglass/webhook/plug_mailgun_test.exs` — full file read. The canonical analog. Used as template structure.
- `test/mailglass/webhook/providers/resend_webhook_plug_test.exs` — full file read. Second analog showing simpler structure for HMAC-signed providers.
- `test/mailglass/webhook/providers/ses_test.exs` — full file read. Confirmed signing helper pattern (`sign_fixture/2` lines 59-65, `build_canonical_string/2` lines 42-57), CertCache pattern (`CertCache.put/3` line 73, `CertCache.reset/0` line 27).
- `.planning/v0.3.0-MILESTONE-AUDIT.md` — full file read. Confirmed BLOCKER scope (lines 47-51) and remediation plan (lines 227-231).
- `.planning/ROADMAP.md` — full file read. Phase 19 spec at lines 97-108.
- `.planning/STATE.md` — full file read. Confirms Phase 18 closed cleanly; v0.3.2 live.
- `git log --oneline -20 --all` — confirms Release Please pipeline operational; `fix:` commits trigger patch bumps.

### Secondary (MEDIUM confidence)
- (none — all claims verified primary)

### Tertiary (LOW confidence)
- (none — all claims verified primary)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every helper exists in tree; no new dependencies
- Architecture: HIGH — pattern mirrors Mailgun and Resend exactly; provider_module dispatch unchanged
- Pitfalls: HIGH — pitfalls extracted from existing analog tests (`ses_test.exs`, `plug_mailgun_test.exs`) and the audit-evidence trail
- Test strategy: HIGH — full template provided; identical shape to two existing passing files
- Release pipeline: HIGH — Phase 18 demonstrated the path 3 times in 24 hours

**Research date:** 2026-04-30
**Valid until:** 2026-05-30 (or until any of the following change: `lib/mailglass/webhook/ingest.ex`, `lib/mailglass/webhook/plug.ex`, `lib/mailglass/webhook/providers/ses.ex`, `test/support/webhook_case.ex`, `test/support/webhook_fixtures.ex`)

## RESEARCH COMPLETE

**Phase:** 19 — Fix SES Ingest BLOCKER + Plug-level Integration Test
**Confidence:** HIGH

### Key Findings

1. **The BLOCKER is two surgical edits in `lib/mailglass/webhook/ingest.ex`**: add `:ses` to the guard list at line 122 (one atom), and add a single 3-line `derive_webhook_provider_event_id(:ses, _, [first | _])` clause around line 376 that delegates to `extract_event_provider_id(first)` — byte-identical to the `:mailgun` and `:resend` clauses already in the file.
2. **All required test infrastructure already exists.** `WebhookCase.mailglass_webhook_conn(:ses, raw_body)` (lines 222-228), `WebhookFixtures.generate_sns_keypair/0` + `sign_sns_canonical_string/3` (lines 217-259), and 16 SES fixtures at `test/support/fixtures/webhooks/ses/` — all shipped in Phase 16 Wave 0. The new plug test composes them; it doesn't extend them.
3. **The new test mirrors `plug_mailgun_test.exs` structurally**, with one SES-specific addition: a `setup` block that calls `CertCache.reset()` then `CertCache.put(@cert_url, public_key, future)` to bypass `:httpc` (the same pattern `ses_test.exs:71-73` uses). For the Notification flow, no `Mailglass.HTTPCStub` injection is needed — the cert path is short-circuited by the cache hit, and the Notification flow itself never calls `:httpc`.
4. **`Mailglass.Webhook.Plug` is already fully SES-aware** — `@valid_providers` includes `:ses` (line 84), `resolve_config!(:ses, _)` exists (line 260), `provider_module(:ses)` returns `Mailglass.Webhook.Providers.SES` (line 403). The plug surface needs zero changes; only the ingest seam was missed in Phase 16.
5. **`Mailglass.Webhook.Providers.SES.build_event/8` already populates `Event.metadata["provider_event_id"]`** as `"#{sns_message_id}:#{email}"` (line 597, 641-647). `extract_event_provider_id/1` (ingest.ex:382-386) reads this key by string. Zero changes to provider code or schema; the wiring is purely a missing dispatch clause.
6. **Release pipeline is hot.** Phase 18 cycled `fix:` commits through Release Please three times in one day (PRs #20, #22, #23 / orphan v0.3.0 and v0.3.1 → shipped v0.3.2). v0.3.3 from a `fix(ingest):` commit is the natural path.

### File Created
`/Users/jon/projects/mailglass/.planning/phases/19-fix-ses-ingest-blocker-plug-test/19-RESEARCH.md`

### Confidence Assessment

| Area | Level | Reason |
|------|-------|--------|
| Standard Stack | HIGH | Every helper exists; no new dependencies; `mix.lock` unchanged |
| Architecture | HIGH | Pattern mirrors `:mailgun` and `:resend` clauses byte-for-byte; provider_module dispatch already in place |
| Pitfalls | HIGH | Extracted from existing analog tests + audit evidence; all surface-level (no deep gotchas) |
| Test strategy | HIGH | Full template provided in Code Examples section; structurally identical to `plug_mailgun_test.exs` (passing) |
| Release ceremony | HIGH | Pipeline used 3× in Phase 18 (24h ago); same `fix:` Conventional Commits format |
| Security | HIGH | No new attack surface; closes a code path already crypto-verified in Phase 16 |

### Open Questions
1. **Test file location** — `test/mailglass/webhook/plug_ses_test.exs` (Mailgun convention, recommended) vs. `test/mailglass/webhook/providers/ses_plug_test.exs` (Resend convention + roadmap success criterion text). Both function identically; flag for planner discretion.
2. **SubscriptionConfirmation plug-level test** — recommend skipping (already covered by `ses_test.exs:121`); Phase 19 success criterion is Notification-only.
3. **Conventional Commits scope** — `fix(ingest):` vs. `fix(webhook):` vs. `fix(ses):`. Stylistic only; Release Please cuts v0.3.3 either way.

### Ready for Planning
Research is complete. Planner can now create a single PLAN.md with two ordered tasks: (1) edit `lib/mailglass/webhook/ingest.ex` lines 122 and ~376; (2) add `test/mailglass/webhook/plug_ses_test.exs` mirroring `plug_mailgun_test.exs`. A Conventional Commits `fix(ingest):` commit will trigger Release Please to cut v0.3.3. Total production code delta: ~7 lines. Total test delta: ~120 lines (one file). Phase fits naturally into a single-plan, single-PR shape — no waves required.
