---
phase: 16-ses-webhook-provider-sns-cache
plan: "03"
subsystem: webhook
tags: [ses, sns, rsa, signature-verification, cert-cache, trust-policy, ssrf-guard, control-plane, otp28]
dependency_graph:
  requires:
    - phase: "16-02"
      provides: "TrustPolicy SSRF guard + CertCache ETS + Supervisor/TableOwner OTP structure"
    - phase: "16-01"
      provides: "RSA test keypair helpers, 16 SNS fixture files, RED-state ses_test.exs"
  provides:
    - "lib/mailglass/webhook/providers/ses.ex — full verify!/3 implementation"
    - "Mailglass.Webhook.Providers.SES @behaviour Mailglass.Webhook.Provider"
    - "SNS Notification, SubscriptionConfirmation, UnsubscribeConfirmation dispatch"
    - "normalize/2 stub returning [] (Plan 04 replaces)"
  affects:
    - "16-04-PLAN.md (normalize/2 implementation — replaces stub)"
tech-stack:
  added: []
  patterns:
    - "TrustPolicy checked before any network I/O (D-06 SSRF guard pattern)"
    - "CertCache ETS hit returns public key directly; miss fetches via :httpc and stores with TTL"
    - "ConfirmSubscription URL constructed from TopicArn+Token (D-07) — SubscribeURL not followed"
    - "autoredirect: false on all :httpc calls to prevent open-redirect to internal services"
    - "Application.get_env-based :httpc_client injection for test isolation (no Mox needed)"
    - "pkix_decode_cert(der, :otp) for OTP 28-compatible public key extraction (pkix_extract_public_key not available)"
    - "RSA-SHA1 (SignatureVersion 1) and RSA-SHA256 (SignatureVersion 2) dispatch via sig_version field"
    - "Separate HTTPCStub module inline in test file for SubscriptionConfirmation"

key-files:
  created:
    - lib/mailglass/webhook/providers/ses.ex
  modified:
    - test/mailglass/webhook/providers/ses_test.exs

key-decisions:
  - "Use pkix_decode_cert(der, :otp) + tuple indexing for public key extraction — pkix_extract_public_key/1 is not available in OTP 28"
  - "Inject :httpc via Application.get_env(:mailglass, :ses, httpc_client:) with map-level override — avoids Mox, matches plan spec exactly"
  - "normalize/2 stubbed as [] with intentional Plan-04 comment — 16 type warnings in test scaffold are expected RED state"
  - "dispatch_message_type/3 takes config as third param so httpc_client flows through without Application.get_env in all call sites"

patterns-established:
  - "SES: verify!/3 always validates TrustPolicy before any network I/O — this is the SSRF fence"
  - "SES: ConfirmSubscription uses D-07 constructed URL from signed fields; SubscribeURL is consistency-checked only"
  - "SES: Both cert fetch and confirm subscription share @confirm_timeout_ms and httpc_client/1 helper"

requirements-completed:
  - SES-01
  - SES-02
  - SES-03

duration: ~15 minutes
completed: "2026-04-28"
---

# Phase 16 Plan 03: SES Provider verify!/3 Implementation Summary

**SNS RSA signature verifier with trust-policy SSRF guard, ETS cert cache integration, and control-plane auto-confirmation — all three SNS message types handled before any side-effect**

## Performance

- **Duration:** ~15 minutes
- **Started:** 2026-04-28T22:40:00Z
- **Completed:** 2026-04-28T22:55:00Z
- **Tasks:** 1 (TDD GREEN + test scaffold update)
- **Files created:** 1
- **Files modified:** 1

## Accomplishments

- `lib/mailglass/webhook/providers/ses.ex` implements `@behaviour Mailglass.Webhook.Provider` with full `verify!/3`
- RSA signature verification covers both SignatureVersion 1 (SHA1) and SignatureVersion 2 (SHA256)
- TrustPolicy SSRF guard checked at line 63 — before first network I/O (line 208) — satisfying D-06
- SubscriptionConfirmation constructs ConfirmSubscription URL from TopicArn+Token per D-07; SubscribeURL is validated for consistency only, not followed
- All `:httpc` calls use `autoredirect: false` preventing open-redirect to internal services (T-16-03-04)
- `Mailglass.HTTPCStub` added to test file; SubscriptionConfirmation test uses `@config_with_httpc_stub` to avoid real AWS network I/O
- `normalize/2` stubbed to `[]` with Plan 04 comment
- `mix compile --warnings-as-errors` exits 0 — no production code warnings

## Task Commits

1. **Task 1 (GREEN): Implement SES provider verify!/3** — `4093276` (feat)

## Files Created/Modified

- `lib/mailglass/webhook/providers/ses.ex` — Full `verify!/3` implementation: JSON decode, TrustPolicy check, CertCache lookup, RSA verify, MessageType dispatch (Notification/SubscriptionConfirmation/UnsubscribeConfirmation); `normalize/2` stub
- `test/mailglass/webhook/providers/ses_test.exs` — Added `Mailglass.HTTPCStub` module, `@config_with_httpc_stub`, removed unused `@topic_arn` and `import ExUnit.CaptureLog`

## Decisions Made

**pkix_extract_public_key not available in OTP 28:**
The plan referenced `:public_key.pkix_extract_public_key/1` but this function does not exist in OTP 28. Used `pkix_decode_cert(der, :otp)` instead, then extracted the public key term by accessing the OTPCertificate tuple structure: `tbs = elem(otp_cert, 1); spki = elem(tbs, 7); elem(spki, 2)`. This is the correct OTP 28 approach and avoids the compilation warning.

**dispatch_message_type/3 takes config:**
The original plan's action code used `dispatch_message_type(msg_type, payload)` with 2 args. The implementation uses 3 args to thread `config` through so the `:httpc_client` setting reaches `confirm_subscription/2` without a second `Application.get_env` call. Cleaner than reading Application env in both `fetch_cert_via_httpc!` and `confirm_subscription`.

**httpc_client/1 helper reads config map first, Application env second:**
The `httpc_client/1` private function first checks `Map.get(config, :httpc_client)` (set in tests via `@config_with_httpc_stub`), then falls back to `Application.get_env(:mailglass, :ses, []) |> Keyword.get(:httpc_client, :httpc)`. This gives tests two injection paths without requiring global Application state mutation.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Replaced non-existent :public_key.pkix_extract_public_key/1 with OTP 28 compatible approach**
- **Found during:** Task 1 (compile step — "undefined or private" warning treated as error)
- **Issue:** Plan specified `{:ok, public_key} = :public_key.pkix_extract_public_key(cert)` but this function does not exist in OTP 28
- **Fix:** Used `pkix_decode_cert(der, :otp)` and extracted the RSAPublicKey term by positional tuple access (`elem(otp_cert, 1)` → `elem(tbs, 7)` → `elem(spki, 2)`)
- **Files modified:** `lib/mailglass/webhook/providers/ses.ex`
- **Verification:** `mix compile --warnings-as-errors` exits 0; no undefined function warning
- **Committed in:** `4093276`

---

**Total deviations:** 1 auto-fixed (1 bug — OTP 28 API mismatch)
**Impact on plan:** Required fix — plan referenced an unavailable OTP function. Replacement is functionally equivalent and OTP 28-correct.

## Known Stubs

| Stub | File | Line | Reason |
|------|------|------|--------|
| `normalize/2` returns `[]` | `lib/mailglass/webhook/providers/ses.ex` | ~58 | Intentional — Plan 04 implements full normalize logic for SNS classic feedback + SES event publishing |

The stub causes 16 type-inference warnings in the test scaffold (Elixir 1.19 sees `normalize/2` always returns `empty_list()` and warns that fan-out pattern matches can never succeed). These warnings are expected RED state for Plan 04 — they confirm the normalize tests are correctly failing without implementation. `mix compile --warnings-as-errors` passes because these are test-file compile warnings during `mix test`, not production module warnings.

## Threat Flags

No new network endpoints introduced. The SES provider is an implementation of the existing `Webhook.Provider` behavior — the HTTP ingestion endpoint was established in prior phases. All outbound calls (`httpc`) go to AWS SNS APIs. All threats from the plan's threat register are implemented:

| Threat | Mitigation | Status |
|--------|------------|--------|
| T-16-03-01: SSRF via SigningCertURL | `TrustPolicy.valid_cert_url?/1` first in `verify!/3` | Implemented |
| T-16-03-02: Forged SNS with attacker cert | Trust policy + RSA verify over canonical string | Implemented |
| T-16-03-03: Tampered canonical string fields | `:public_key.verify/4` RSA-SHA1/SHA256 | Implemented |
| T-16-03-04: SubscriptionConfirmation open-redirect | D-07 constructed URL; `autoredirect: false` | Implemented |
| T-16-03-06: PII in Logger | Logger emits only topic_arn, outcome atoms | Implemented |
| T-16-03-07: DoS via repeated cert fetch | CertCache ETS hit bypasses `:httpc` | Implemented |

## Test Results

```
mix test test/mailglass/webhook/providers/ses_test.exs
22 tests, 16 failures

Passing (6):
  - verify!/3 SES SNS signature verification — returns :ok for valid Notification
  - verify!/3 SES SNS signature verification — raises :bad_signature for tampered payload
  - verify!/3 SES SNS signature verification — raises :bad_signature for invalid SigningCertURL
  - verify!/3 SES SNS signature verification — raises :malformed_header for non-JSON body
  - verify!/3 SES SNS control-plane — returns {:ok, :control_plane, :subscription_confirmed}
  - verify!/3 SES SNS control-plane — returns {:ok, :control_plane, :unsubscribe_confirmed}

Failing (16): All normalize/2 tests — expected RED state for Plan 04
```

## Issues Encountered

None beyond the OTP 28 API mismatch documented as a deviation above.

## Next Phase Readiness

- `Mailglass.Webhook.Providers.SES.verify!/3` is fully implemented and security-hardened
- Plan 04 can implement `normalize/2` by replacing the stub; all 16 RED normalize tests serve as the ready-made spec
- CertCache integration is fully wired: tests pre-populate via `CertCache.put/3`, production path uses `fetch_cert_via_httpc!` + `extract_public_key_from_pem!`

---
*Phase: 16-ses-webhook-provider-sns-cache*
*Completed: 2026-04-28*

## Self-Check: PASSED

| Item | Status |
|------|--------|
| `lib/mailglass/webhook/providers/ses.ex` | FOUND |
| `test/mailglass/webhook/providers/ses_test.exs` | FOUND (modified) |
| Commit `4093276` | FOUND |
| `mix compile --warnings-as-errors` exits 0 | PASSED |
| 6 verify!/3 tests pass | PASSED |
| 16 normalize tests fail (expected RED) | CONFIRMED |
| `autoredirect: false` in two :httpc call sites | CONFIRMED |
| `TrustPolicy.valid_cert_url?` before first `:httpc` call | CONFIRMED |
| `DateTime.utc_now` absent from ses.ex | CONFIRMED |
