---
phase: 16-ses-webhook-provider-sns-cache
reviewed: 2026-04-28T00:00:00Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - guides/webhooks.md
  - lib/mailglass/application.ex
  - lib/mailglass/webhook/plug.ex
  - lib/mailglass/webhook/providers/ses.ex
  - lib/mailglass/webhook/providers/ses/cert_cache.ex
  - lib/mailglass/webhook/providers/ses/cert_cache/supervisor.ex
  - lib/mailglass/webhook/providers/ses/cert_cache/table_owner.ex
  - lib/mailglass/webhook/providers/ses/trust_policy.ex
  - lib/mailglass/webhook/router.ex
  - test/mailglass/webhook/plug_test.exs
  - test/mailglass/webhook/providers/ses/cert_cache_test.exs
  - test/mailglass/webhook/providers/ses_test.exs
  - test/support/webhook_case.ex
  - test/support/webhook_fixtures.ex
findings:
  critical: 3
  warning: 4
  info: 2
  total: 9
status: issues_found
---

# Phase 16: Code Review Report

**Reviewed:** 2026-04-28
**Depth:** standard
**Files Reviewed:** 14
**Status:** issues_found

## Summary

Phase 16 implements the SES webhook provider backed by SNS signature verification and an ETS certificate cache. The overall structure is sound: TrustPolicy is a pure predicate, CertCache is a well-structured ETS owner pattern, and the verify!/3 flow follows the correct order (URL validation → cache/fetch → verify → dispatch). Normalization covers both classic feedback and event-publishing formats with appropriate fan-out.

However, three security-relevant defects need fixing before this ships. The most critical is that `TrustPolicy.valid_cert_url?/1` does not check the port, allowing a URL like `https://sns.us-east-1.amazonaws.com:9000/cert.pem` to pass validation while connecting to a non-standard port — this is an SSRF bypass vector. Second, `Base.decode64!/1` on the untrusted `Signature` field raises a bare `ArgumentError` that escapes the `SignatureError` rescue boundary in `Plug` and will produce a 500 instead of a 401. Third, an unknown `SignatureVersion` value (e.g. `"3"`) is silently downgraded to SHA-1 instead of being rejected, creating a protocol-downgrade vector.

---

## Critical Issues

### CR-01: TrustPolicy does not validate port — SSRF bypass via non-standard port

**File:** `lib/mailglass/webhook/providers/ses/trust_policy.ex:39`

**Issue:** `URI.parse/1` populates `%URI{host: ..., port: N}` separately. The pattern match in `valid_cert_url?/1` (and `valid_subscribe_url?/1`) binds `host` and checks the host regex, but never matches or guards on `port`. A crafted URL like `https://sns.us-east-1.amazonaws.com:9000/cert.pem` passes all current checks — the host matches the regex, the path ends with `.pem`, scheme is `https`, and neither `userinfo` nor `fragment` nor `query` are present. This allows an attacker who can control the `SigningCertURL` field to redirect cert fetches to a non-standard port on an otherwise-legitimate AWS SNS hostname. The comment in the module doc says "No additional subdomains between sns. and amazonaws.com" but says nothing about port. Confirmed with `URI.parse("https://sns.us-east-1.amazonaws.com:9000/cert.pem")` — `port: 9000`, `host: "sns.us-east-1.amazonaws.com"`.

**Fix:**
```elixir
# valid_cert_url?/1 — add port guard
%URI{scheme: "https", host: host, port: port, userinfo: nil,
     fragment: nil, path: path, query: nil}
when is_binary(host) and is_binary(path) and port in [nil, 443] ->
  Regex.match?(@cert_host_pattern, host) and String.ends_with?(path, ".pem")

# valid_subscribe_url?/1 — same guard
%URI{scheme: "https", host: host, port: port, userinfo: nil, fragment: nil}
when is_binary(host) and port in [nil, 443] ->
  Regex.match?(@cert_host_pattern, host)
```

`URI.parse` sets `port` to `nil` when no port is present in the URL (HTTPS implies 443 but `URI` leaves the field nil when not explicit). Guarding `port in [nil, 443]` rejects any explicit non-443 port while accepting the normal case.

---

### CR-02: `Base.decode64!` on untrusted `Signature` field raises `ArgumentError` outside the `SignatureError` rescue boundary

**File:** `lib/mailglass/webhook/providers/ses.ex:78`

**Issue:** `decoded_sig = Base.decode64!(signature_b64)` raises `ArgumentError` when the `Signature` field contains invalid base64 (e.g. non-ASCII bytes, incorrect padding, or a forged payload). The rescue clause in `Mailglass.Webhook.Plug.do_call/3` catches only `SignatureError`, `TenancyError`, and `ConfigError`. An `ArgumentError` is not in that list, so it propagates up through `:telemetry.span/3` and will eventually become an unhandled exception — producing a 500 response with a raw Elixir stacktrace in the Logger, leaking internal structure and failing to properly identify this as a signature failure.

**Fix:**
```elixir
# Replace line 78 with a safe decode:
decoded_sig =
  case Base.decode64(signature_b64) do
    {:ok, bytes} ->
      bytes

    :error ->
      raise SignatureError.new(:malformed_header,
              provider: :ses,
              context: %{detail: "Signature field is not valid base64"}
            )
  end
```

---

### CR-03: Unknown `SignatureVersion` silently downgrades to SHA-1 — protocol-downgrade vector

**File:** `lib/mailglass/webhook/providers/ses.ex:77`

**Issue:** `digest = if sig_version == "2", do: :sha256, else: :sha` silently maps any version other than `"2"` (including `"3"`, `"0"`, `""`, or attacker-injected values) to `:sha` (SHA-1). An attacker who can forge a `SignatureVersion: "99"` field could force verification to run against SHA-1 regardless of whether the server should enforce SHA-256. While AWS currently only defines versions `"1"` and `"2"`, accepting unknown future versions silently — particularly downgrading to the weaker algorithm — violates the fail-closed principle (D-09).

**Fix:**
```elixir
digest =
  case sig_version do
    "1" -> :sha
    "2" -> :sha256
    other ->
      raise SignatureError.new(:malformed_header,
              provider: :ses,
              context: %{detail: "Unknown SignatureVersion: #{inspect(other)}"}
            )
  end
```

---

## Warnings

### WR-01: `DateTime.utc_now()` used directly in tests — bypasses the `Mailglass.Clock` abstraction

**File:** `test/mailglass/webhook/providers/ses_test.exs:72,81,112,124` and `test/support/webhook_fixtures.ex:212`

**Issue:** Five occurrences of `DateTime.add(DateTime.utc_now(), 86_400, :second)` appear in test code, directly calling `DateTime.utc_now()`. CLAUDE.md mandates `Mailglass.Clock.utc_now()` throughout (no `DateTime.utc_now()`). The production code and `cert_cache_test.exs` both correctly use `Mailglass.Clock.utc_now()`. This inconsistency means freeze-time tests (`Mailglass.Clock.Frozen.freeze/1`) won't affect the expiry timestamps computed in `ses_test.exs`, making those test setups brittle if freeze is ever combined with cert-expiry assertions.

**Fix:** Replace every `DateTime.utc_now()` in test files with `Mailglass.Clock.utc_now()`:
```elixir
# Before:
future = DateTime.add(DateTime.utc_now(), 86_400, :second)
# After:
future = DateTime.add(Mailglass.Clock.utc_now(), 86_400, :second)
```

---

### WR-02: `build_event/8` discards `_email` parameter — recipient address is not in metadata

**File:** `lib/mailglass/webhook/providers/ses.ex:534`

**Issue:** `build_event/8` receives the `_email` argument (prefixed with `_`) and ignores it entirely. The `metadata` map in the returned `%Event{}` contains `"provider_event_id"` (which includes the email in its key string) but no `"recipient"` field or similar. The email address is available at each call site and is meaningful for debugging, orphan reconciliation, and suppression matching — the Ingest layer uses `provider_event_id` to deduplicate, but downstream code matching deliveries typically needs the recipient address separately. By discarding it here, the information is only partially recoverable from the string `provider_event_id` value.

Note: This is a design trade-off (no PII in telemetry is the policy), and the `provider_event_id` does embed the email. The defect is that the email is available but explicitly discarded with `_email` rather than stored in a non-telemetry path like `metadata`. At minimum, document this as an intentional choice in the function comment.

**Fix:** Either document the intentional omission with a comment explaining that recipients are recoverable from `provider_event_id`, or — if downstream code needs direct recipient lookup — add a `"recipient_email"` metadata key and ensure it is excluded from any telemetry emission path (it is safe in `metadata` which goes to the DB, not to telemetry).

---

### WR-03: Concurrent cache-miss stampede — multiple `:httpc` fetches for the same cert URL

**File:** `lib/mailglass/webhook/providers/ses.ex:215-226`

**Issue:** `fetch_public_key!/2` follows a check-then-act pattern against the ETS table: it reads from the cache, and if `:miss`, it fetches via `:httpc` and then writes. If multiple webhook requests arrive concurrently for the first time (before any cert is cached), each will independently see `:miss`, make its own `:httpc` request, and write the result. This is a thundering-herd on the SNS certificate endpoint at cold-start. While harmless in terms of correctness (all writers write the same public key, ETS `:insert` is atomic and overwrites), it creates N concurrent HTTP calls to AWS per cert URL on the first burst of SES traffic.

**Fix:** The simplest mitigation is a process-level serialization via the `TableOwner` GenServer: a `call` to fetch-or-populate atomically. A lighter alternative is to use `:ets.insert_new/2` to detect the race and let the loser wait for a configurable brief period before re-reading. At minimum, document this behavior in `CertCache` module docs so operators are not surprised by multiple simultaneous cert fetches on cold start.

---

### WR-04: Guide `context map` shows incomplete `provider:` type union — `:ses` omitted

**File:** `guides/webhooks.md:258`

**Issue:** The "Context map the callback receives" section documents the `provider:` field type as `:postmark | :sendgrid | :mailgun` — `:ses` is missing from the union. After Phase 16, `:ses` is a valid provider and adopters implementing custom `Mailglass.Tenancy` callbacks need to know all valid atoms to match against. An adopter writing `case context.provider do :postmark -> ... :sendgrid -> ... end` without a `:ses` clause will silently miss SES webhook tenant resolution.

**Fix:**
```markdown
  provider: :postmark | :sendgrid | :mailgun | :ses,
```

---

## Info

### IN-01: `build_event/8` has redundant `"ses_message_id"` and `"message_id"` keys with identical values

**File:** `lib/mailglass/webhook/providers/ses.ex:546-548`

**Issue:** The base metadata map in `build_event/8` sets both `"message_id"` and `"ses_message_id"` to the same `ses_message_id` value. For event-publishing events, the `extra_metadata` passed in also contains `"ses_message_id"`. This means `Map.merge(base, extra_metadata)` will overwrite `"ses_message_id"` with the same value from `extra_metadata` (a no-op for event publishing), but for classic feedback events, only the base map has `"ses_message_id"` — so `"message_id"` and `"ses_message_id"` are both set and both identical. The duplication wastes storage and may confuse downstream consumers trying to understand the schema.

**Fix:** Remove the duplicate `"ses_message_id"` from the base metadata map and keep only `"message_id"`. The `extra_metadata` from event-publishing normalizers can continue to pass `"ses_message_id"` when the SES event format provides it:

```elixir
%{
  "provider" => "ses",
  "provider_event_id" => provider_event_id,
  "record_type" => record_type,
  "message_id" => ses_message_id,
  "sns_message_id" => sns_message_id
  # remove: "ses_message_id" => ses_message_id (redundant with "message_id")
}
```

---

### IN-02: No test coverage for `Permanent/Suppressed` and `Permanent/UnsubscribedRecipient` bounce subtypes mapping to `:rejected`

**File:** `test/mailglass/webhook/providers/ses_test.exs`

**Issue:** `map_bounce/1` has a specific clause for `bounceSubType in ["Suppressed", "OnAccountSuppressionList", "UnsubscribedRecipient"]` mapping to `{:rejected, :blocked}` — the path that triggers address-wide suppression. The test suite only covers `Permanent/General -> :bounced` and `Transient -> :deferred`. The `Permanent/Suppressed -> :rejected` path is the auto-suppression gate and is entirely untested. If this clause is broken (e.g. a typo in the subtype string), suppression list handling silently degrades without a failing test.

**Fix:** Add normalize tests covering the suppressed-bounce path:
```elixir
test "Bounce Permanent/Suppressed -> :rejected/:blocked" do
  payload = %{
    "notificationType" => "Bounce",
    "mail" => %{"messageId" => "msg-001"},
    "bounce" => %{
      "bounceType" => "Permanent",
      "bounceSubType" => "Suppressed",
      "bouncedRecipients" => [%{"emailAddress" => "suppressed@example.com"}]
    }
  }
  sns_wrapped = Jason.encode!(%{
    "Type" => "Notification",
    "MessageId" => "sns-001",
    "Message" => Jason.encode!(payload)
  })
  [event] = SES.normalize(sns_wrapped, [])
  assert event.type == :rejected
  assert event.reject_reason == :blocked
end
```

---

_Reviewed: 2026-04-28_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
