---
phase: 16-ses-webhook-provider-sns-cache
verified: 2026-04-29T23:30:00Z
status: passed
score: 10/10 must-haves verified
overrides_applied: 1
overrides:
  - must_have: "System automatically confirms SNS subscriptions by fetching the SubscribeURL (ROADMAP SC-2, SES-02)"
    reason: "D-07 security decision: ConfirmSubscription API URL is constructed from signed TopicArn+Token rather than following SubscribeURL directly. SubscribeURL is validated for trust but not followed as an authority (prevents open-redirect attacks). Functional outcome — automatic subscription confirmation — is achieved identically. RESEARCH.md line 56 documents this mapping explicitly."
    accepted_by: "jon"
    accepted_at: "2026-04-30T19:40:35Z"
---

# Phase 16: SES Webhook Provider & SNS Cache — Verification Report

**Phase Goal:** Implement the SES webhook provider — SNS signature verification with certificate caching via OTP supervisor
**Verified:** 2026-04-29T23:30:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | System successfully parses `text/plain` SES SNS payloads (ROADMAP SC-1, SES-01) | VERIFIED | `ses.ex` line 55: `verify!/3` accepts `raw_body :: binary()`; plug.ex `resolve_config!(:ses)` reads `Application.get_env(:mailglass, :ses)`; `provider_module(:ses)` dispatches to `Mailglass.Webhook.Providers.SES` |
| 2 | System automatically confirms SNS subscriptions by fetching the SubscribeURL (ROADMAP SC-2, SES-02) | PASSED (override) | Override accepted: Implementation makes HTTP GET to ConfirmSubscription URL constructed from TopicArn+Token per D-07 rather than following the raw SubscribeURL directly. SubscribeURL is validated for trust only. Functional outcome is identical automatic subscription confirmation. |
| 3 | Valid SES RSA signatures are accepted using X.509 certificates fetched from AWS (ROADMAP SC-3, SES-03) | VERIFIED | `ses.ex` lines 63-103: TrustPolicy.valid_cert_url? checked first; CertCache.fetch_public_key + :httpc fallback; `:public_key.verify/4` called; all 6 verify!/3 tests pass; 29/29 tests green |
| 4 | X.509 certificates are cached in `:ets` preventing repeated network calls per webhook (ROADMAP SC-4, SES-04) | VERIFIED | `cert_cache.ex`: ETS table `:mailglass_webhook_ses_cert_cache`; `fetch_public_key/1` returns `{:ok, key}` on hit; lazy TTL eviction on miss; `application.ex` lines 36-37: `SES.CertCache.Supervisor` in maybe_add chain; 7 CertCache tests pass |
| 5 | SES events wrapped inside the SNS Message are mapped to the normalized taxonomy (ROADMAP SC-5, SES-05) | VERIFIED | `ses.ex` lines 110-127: `normalize/2` double-decodes SNS envelope then inner Message; dispatches on `notificationType` vs `eventType`; 10 event type mappings verified; 16 normalize tests pass |
| 6 | TrustPolicy rejects non-SNS URLs including S3 namespace collision attacks | VERIFIED | `trust_policy.ex`: `@cert_host_pattern ~r/^sns\.[a-zA-Z0-9\-]{3,}\.amazonaws\.com(\.cn)?$/`; `valid_cert_url?` and `valid_subscribe_url?` present; pure predicate, no I/O |
| 7 | CertCache serves public key terms from ETS on hit, returns :miss on miss or expired | VERIFIED | `cert_cache.ex` lines 35-50: `fetch_public_key/1` with TTL comparison and lazy eviction; `CertCache.table/0` returns `:mailglass_webhook_ses_cert_cache` |
| 8 | SES provider implements @behaviour Mailglass.Webhook.Provider | VERIFIED | `ses.ex` line 34: `@behaviour Mailglass.Webhook.Provider`; both `verify!/3` and `normalize/2` are `@impl` annotated |
| 9 | Plug, Router, Application are wired for SES as opt-in provider | VERIFIED | `plug.ex` line 84: `:ses` in `@valid_providers`; `router.ex` line 71: `:ses` in `@valid_providers`, line 72: NOT in `@default_providers`; `application.ex` lines 36-37: `SES.CertCache.Supervisor` in maybe_add chain |
| 10 | guides/webhooks.md documents SES setup including config key | VERIFIED | `guides/webhooks.md` line 116: "### Amazon SES (via SNS)" section with setup steps, config example, event table, duplicate-source warning |

**Score:** 10/10 truths verified (includes 1 accepted override)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/mailglass/webhook/providers/ses.ex` | SES Provider behaviour implementation | VERIFIED | Full `verify!/3` + `normalize/2`; `@behaviour Mailglass.Webhook.Provider`; `@signable_keys_notification`, `@signable_keys_control` present |
| `lib/mailglass/webhook/providers/ses/trust_policy.ex` | SNS URL SSRF guard | VERIFIED | `valid_cert_url?/1` and `valid_subscribe_url?/1`; `@cert_host_pattern` with SNS host regex |
| `lib/mailglass/webhook/providers/ses/cert_cache.ex` | ETS-backed cert cache API | VERIFIED | `fetch_public_key/1`, `put/3`, `reset/0`, `table/0`; `@table :mailglass_webhook_ses_cert_cache` |
| `lib/mailglass/webhook/providers/ses/cert_cache/supervisor.ex` | Supervisor for TableOwner | VERIFIED | `use Supervisor`; one_for_one; starts `SES.CertCache.TableOwner` |
| `lib/mailglass/webhook/providers/ses/cert_cache/table_owner.ex` | GenServer owning ETS table | VERIFIED | `:ets.new(@table, [:set, :public, :named_table, ...])` in `init/1` |
| `test/support/fixtures/webhooks/ses/` (16 files) | 16 JSON SNS/SES fixture files | VERIFIED | 16 files confirmed; `notification_delivery.json` Message field is double-encoded; `subscription_confirmation.json` has correct Type |
| `test/support/webhook_fixtures.ex` | generate_sns_keypair/0, sign_sns_canonical_string/3, load_ses_fixture/1 | VERIFIED | All 3 functions present at lines 217-259 |
| `test/support/webhook_case.ex` | stub_ses_fixture/1, :ses conn builder | VERIFIED | `stub_ses_fixture: 1` in import (line 64); `stub_ses_fixture/1` at line 298; `:ses` clause in `mailglass_webhook_conn` |
| `test/mailglass/webhook/providers/ses_test.exs` | 22 tests across 5 describe blocks | VERIFIED | File exists; 22 tests; all pass (29 total with cert_cache_test.exs) |
| `test/mailglass/webhook/providers/ses/cert_cache_test.exs` | 7 CertCache unit tests | VERIFIED | File exists; 7 tests covering hit/miss/TTL/eviction/reset; all pass |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `plug.ex` | `Mailglass.Webhook.Providers.SES` | `provider_module(:ses)` | WIRED | Line 394: `defp provider_module(:ses), do: Mailglass.Webhook.Providers.SES` |
| `plug.ex` | control-plane branch | `{:ok, :control_plane, outcome}` case | WIRED | Lines 137-146: branch returns 200 without calling normalize or ingest |
| `ses.ex` | `SES.CertCache` | `alias + fetch_public_key/1 + put/3` | WIRED | Line 40: alias; lines 246-255: CertCache.fetch_public_key + CertCache.put |
| `ses.ex` | `SES.TrustPolicy` | `alias + valid_cert_url?/1 + valid_subscribe_url?/1` | WIRED | Line 40: alias; line 63: valid_cert_url? called BEFORE first :httpc; line 139: valid_subscribe_url? |
| `ses.ex` | `:public_key.verify/4` | RSA signature verification | WIRED | Line 101: `:public_key.verify(canonical, digest, decoded_sig, public_key)` |
| `application.ex` | `SES.CertCache.Supervisor` | `maybe_add/3` | WIRED | Lines 36-37: `maybe_add(Mailglass.Webhook.Providers.SES.CertCache.Supervisor, ...)` |
| `cert_cache.ex` | `:ets named table :mailglass_webhook_ses_cert_cache` | `@table atom` | WIRED | Line 25: `@table :mailglass_webhook_ses_cert_cache` |
| `cert_cache/table_owner.ex` | `:ets named table` | `:ets.new(@table, [:set, :public, :named_table, ...])` | WIRED | `init/1` creates named table; `@table` is same atom as in `cert_cache.ex` |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `ses.ex normalize/2` | `ses_payload` | `Jason.decode(message_str)` where `message_str = Map.get(sns_payload, "Message")` | Yes — double-decoded from SNS envelope body | FLOWING |
| `ses.ex verify!/3` | `public_key` | `CertCache.fetch_public_key` (ETS) or `:httpc.request` + `extract_public_key_from_pem!` | Yes — from ETS on hit; from real :httpc on miss | FLOWING |
| `cert_cache.ex fetch_public_key/1` | `public_key` | `:ets.lookup(@table, url)` | Yes — stored via `CertCache.put/3` which uses `:ets.insert` | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| 29 SES + CertCache tests pass | `mix test test/mailglass/webhook/providers/ses_test.exs test/mailglass/webhook/providers/ses/cert_cache_test.exs` | 29 tests, 0 failures | PASS |
| Full webhook suite no regressions | `mix test test/mailglass/webhook/` | 200 tests, 0 failures | PASS |
| Compile with no optional deps, warnings as errors | `mix compile --no-optional-deps --warnings-as-errors` | Generated mailglass app (clean) | PASS |
| No banned DateTime.utc_now in SES files | `grep "DateTime.utc_now" lib/mailglass/webhook/providers/ses.ex lib/.../cert_cache.ex` | Empty (no matches) | PASS |
| autoredirect: false in both :httpc call sites | `grep "autoredirect: false" ses.ex` | Lines 263 and 328 | PASS |
| TrustPolicy check before first :httpc call | `grep -n "TrustPolicy.valid_cert_url?"` | Line 63 before line 260 (fetch_cert_via_httpc!) | PASS |
| notificationType and eventType dispatch | `grep "notificationType\|eventType" ses.ex` | Both present in normalize_ses clauses | PASS |
| Fixture Message field is double-encoded | `python3 validation` | inner notificationType=Delivery confirmed | PASS |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| SES-01 | 16-01, 16-03, 16-04 | Webhook plug parses SNS payloads arriving with `text/plain` Content-Type | SATISFIED | `ses.ex verify!/3` accepts raw binary; `plug.ex` dispatches SES; `WebhookCase` :ses conn builder sets `content-type: text/plain` |
| SES-02 | 16-03, 16-04 | System automatically performs HTTP GET to `SubscribeURL` upon receiving `SubscriptionConfirmation` events | PASSED (override) | Override accepted: Implementation performs HTTP GET to the ConfirmSubscription API URL constructed from TopicArn+Token (D-07), not the raw SubscribeURL. Functional outcome (auto-confirmation) is achieved identically while avoiding trust in the raw URL. |
| SES-03 | 16-02, 16-03 | Webhook plug verifies RSA-SHA1/SHA256 signatures using X.509 certificates fetched from AWS | SATISFIED | `ses.ex` lines 63-103: TrustPolicy → CertCache/httpc → :public_key.verify; both SHA1 and SHA256 supported via SignatureVersion dispatch |
| SES-04 | 16-02 | X.509 certificates are fetched via `:httpc` and cached in `:ets` to avoid synchronous network I/O per webhook | SATISFIED | `cert_cache.ex` + `cert_cache/table_owner.ex` + `application.ex`: ETS table created by OTP supervisor; CertCache hit returns without network I/O; miss fetches via :httpc and stores with TTL |
| SES-05 | 16-04 | Webhook maps SES events inside the SNS `Message` envelope to `mailglass` normalized taxonomy | SATISFIED | `ses.ex normalize/2`: double-decode, dispatch on notificationType/eventType, all 10 event types mapped; fan-out per recipient; string-keyed metadata |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `ses.ex normalize/2` | 123-124 | `_other ->` catch-all returns `[]` with Logger.warning | Info | Correct defensive coding — non-Notification types (SubscriptionConfirmation, UnsubscribeConfirmation) should not be normalized |
| `ses.ex dispatch_message_type("UnsubscribeConfirmation")` | 170-174 | No network I/O for UnsubscribeConfirmation | Info | Correct per D-04 — no-op; returns `{:ok, :control_plane, :unsubscribe_confirmed}` |

No blockers found.

### Accepted Override

#### 1. SES-02 / ROADMAP SC-2: SubscribeURL vs Constructed ConfirmSubscription URL

The implementation satisfies the auto-confirmation requirement via the accepted D-07 security deviation: instead of following the raw `SubscribeURL` directly, it validates that URL for trust and constructs the `ConfirmSubscription` API request from signed `TopicArn` + `Token`. This preserves the required automatic HTTP GET confirmation behavior while preventing trust in attacker-influenceable redirect targets.

**Code path:** `ses.ex` lines 133-167: `dispatch_message_type("SubscriptionConfirmation")` → `fetch_required_field!(payload, "SubscribeURL")` (validation only) → `build_confirm_url(topic_arn, token)` → `confirm_subscription(confirm_url, config)` → `:httpc.request(:get, ...)`.

**Accepted by:** jon at 2026-04-30T19:40:35Z.

### Gaps Summary

No blocking gaps found. All implementation artifacts exist, are substantive, wired, and data flows correctly. All 200 webhook tests pass with 0 failures including 29 new SES-specific tests. The prior SES-02 paperwork gap is closed via the accepted D-07 override, so the verification record now fully reflects the shipped behavior.

---

_Verified: 2026-04-29T23:30:00Z_
_Verifier: Claude (gsd-verifier)_
