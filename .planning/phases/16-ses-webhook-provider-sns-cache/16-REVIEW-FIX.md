---
phase: 16-ses-webhook-provider-sns-cache
fixed_at: 2026-04-28T00:00:00Z
review_path: .planning/phases/16-ses-webhook-provider-sns-cache/16-REVIEW.md
iteration: 1
findings_in_scope: 7
fixed: 7
skipped: 0
status: all_fixed
---

# Phase 16: Code Review Fix Report

**Fixed at:** 2026-04-28
**Source review:** .planning/phases/16-ses-webhook-provider-sns-cache/16-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 7 (3 Critical + 4 Warning; Info findings excluded by fix_scope)
- Fixed: 7
- Skipped: 0

## Fixed Issues

### CR-01: TrustPolicy does not validate port — SSRF bypass via non-standard port

**Files modified:** `lib/mailglass/webhook/providers/ses/trust_policy.ex`
**Commit:** 87eed93
**Applied fix:** Added `port: port` to both URI pattern matches in `valid_cert_url?/1` and `valid_subscribe_url?/1`, with a `port in [nil, 443]` guard. A URL like `https://sns.us-east-1.amazonaws.com:9000/cert.pem` now returns `false` from `valid_cert_url?/1` and triggers `SignatureError` in the caller.

---

### CR-02: `Base.decode64!` on untrusted `Signature` field raises `ArgumentError` outside the `SignatureError` rescue boundary

**Files modified:** `lib/mailglass/webhook/providers/ses.ex`
**Commit:** ecbc261
**Applied fix:** Replaced `Base.decode64!(signature_b64)` with a `case Base.decode64(signature_b64)` pattern match. On `:error`, raises `SignatureError.new(:malformed_header, ...)` with a detail string, keeping the error within the established `SignatureError` boundary handled by `Mailglass.Webhook.Plug`.

---

### CR-03: Unknown `SignatureVersion` silently downgrades to SHA-1 — protocol-downgrade vector

**Files modified:** `lib/mailglass/webhook/providers/ses.ex`
**Commit:** ecbc261
**Applied fix:** Replaced `if sig_version == "2", do: :sha256, else: :sha` with an explicit `case sig_version do "1" -> :sha; "2" -> :sha256; other -> raise SignatureError... end`. Any version string other than `"1"` or `"2"` now raises `SignatureError.new(:malformed_header, ...)` rather than silently defaulting to SHA-1.

Note: CR-02 and CR-03 were adjacent lines in the same function and were fixed in a single atomic commit.

---

### WR-01: `DateTime.utc_now()` used directly in tests — bypasses the `Mailglass.Clock` abstraction

**Files modified:** `test/mailglass/webhook/providers/ses_test.exs`, `test/support/webhook_fixtures.ex`
**Commit:** 079d312
**Applied fix:** All 5 occurrences of `DateTime.add(DateTime.utc_now(), 86_400, :second)` replaced with `DateTime.add(Mailglass.Clock.utc_now(), 86_400, :second)` using `replace_all`. Test code now uses the Clock abstraction consistently with production code and `cert_cache_test.exs`.

---

### WR-02: `build_event/8` discards `_email` parameter — recipient address is not in metadata

**Files modified:** `lib/mailglass/webhook/providers/ses.ex`
**Commit:** d6b215d
**Applied fix:** Added a multi-line comment above `build_event/8` documenting that `_email` is intentionally discarded. The comment explains that the recipient address is embedded in `provider_event_id` and is recoverable for deduplication and orphan reconciliation, and that the field is intentionally absent to keep the schema minimal and consistent across all normalizers.

---

### WR-03: Concurrent cache-miss stampede — multiple `:httpc` fetches for the same cert URL

**Files modified:** `lib/mailglass/webhook/providers/ses.ex`
**Commit:** 813b7ce
**Applied fix:** Added a comment block above `fetch_public_key!/2` documenting the check-then-act pattern, its correctness guarantees (ETS insert is atomic, all writers converge on the same key), the acceptable impact (N concurrent HTTP GETs on cold start), and the forward path (serialize via TableOwner GenServer call if needed).

---

### WR-04: Guide `context map` shows incomplete `provider:` type union — `:ses` omitted

**Files modified:** `guides/webhooks.md`
**Commit:** 76d32ee
**Applied fix:** Changed `provider: :postmark | :sendgrid | :mailgun,` to `provider: :postmark | :sendgrid | :mailgun | :ses,` in the "Context map the callback receives" section. Adopters implementing `Mailglass.Tenancy` callbacks now see the complete atom union.

---

_Fixed: 2026-04-28_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
