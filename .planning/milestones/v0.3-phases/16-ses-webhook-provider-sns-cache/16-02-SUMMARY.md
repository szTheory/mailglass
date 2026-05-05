---
phase: 16-ses-webhook-provider-sns-cache
plan: "02"
subsystem: webhook
requirements-completed: [SES-04]
tags: [ses, sns, cert-cache, trust-policy, ets, otp, ssrf-guard, tdd]
dependency_graph:
  requires: ["16-01"]
  provides: ["ses/trust_policy", "ses/cert_cache", "ses/cert_cache/supervisor", "ses/cert_cache/table_owner"]
  affects: ["16-03"]
tech_stack:
  added: []
  patterns: ["ETS named-table with GenServer ownership", "lazy TTL expiry on ETS read", "pure predicate SSRF guard", "MailgunReplayCache OTP structure mirrored for SES"]
key_files:
  created:
    - lib/mailglass/webhook/providers/ses/trust_policy.ex
    - lib/mailglass/webhook/providers/ses/cert_cache.ex
    - lib/mailglass/webhook/providers/ses/cert_cache/supervisor.ex
    - lib/mailglass/webhook/providers/ses/cert_cache/table_owner.ex
    - test/mailglass/webhook/providers/ses/cert_cache_test.exs
  modified: []
decisions:
  - "TrustPolicy uses URI.parse/1 for structured URL decomposition rather than raw regex on full URL string"
  - "CertCache evicts expired entries lazily during fetch_public_key/1 — no background sweep timer"
  - "@cert_host_pattern requires exactly 3+ alphanumeric chars for region segment, blocking S3 namespace collision"
  - "TableOwner uses :public ETS visibility so CertCache API can read/write without GenServer message-passing"
metrics:
  duration: "~8 minutes"
  completed: "2026-04-29T02:34:10Z"
  tasks_completed: 2
  files_created: 5
  files_modified: 0
---

# Phase 16 Plan 02: TrustPolicy + CertCache Foundation Summary

SNS URL SSRF guard (TrustPolicy) and ETS-backed X.509 certificate cache (CertCache + Supervisor + TableOwner) using the exact MailgunReplayCache OTP pattern, with full TDD coverage.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| RED | Add failing CertCache tests | c1fdfc1 | test/mailglass/webhook/providers/ses/cert_cache_test.exs |
| 1 (GREEN) | Implement TrustPolicy and CertCache modules | 7bb099a | lib/.../ses/trust_policy.ex, lib/.../ses/cert_cache.ex |
| 2 | Implement CertCache Supervisor and TableOwner | 11ba834 | lib/.../ses/cert_cache/supervisor.ex, lib/.../ses/cert_cache/table_owner.ex |

## What Was Built

### TrustPolicy (`lib/mailglass/webhook/providers/ses/trust_policy.ex`)

Pure predicate SSRF guard for SNS cert and subscribe URLs. Two public functions:

- `valid_cert_url?/1` — validates `SigningCertURL` before any network I/O: requires `https` scheme, SNS host pattern, no userinfo/fragment, no query string, `.pem` path suffix
- `valid_subscribe_url?/1` — validates `SubscribeURL` for consistency check: requires `https` scheme, SNS host pattern, no userinfo/fragment

The `@cert_host_pattern` (`^sns\.[a-zA-Z0-9\-]{3,}\.amazonaws\.com(\.cn)?$`) is derived directly from the AWS PHP SDK canonical reference implementation. Uses `URI.parse/1` for structured decomposition — never raw regex on the full URL string.

Key blocks:
- HTTP scheme downgrade attack (T-16-02-02): scheme guard `"https"` only
- Userinfo credential injection (T-16-02-03): `userinfo: nil` match
- Non-PEM certificate path (T-16-02-04): `String.ends_with?(path, ".pem")`
- S3 namespace collision SSRF (T-16-02-01): exact SNS host pattern with minimum 3-char region segment

### CertCache (`lib/mailglass/webhook/providers/ses/cert_cache.ex`)

ETS-backed cache for RSA public key terms extracted from X.509 PEM certificates. Table name: `:mailglass_webhook_ses_cert_cache`. Entry shape: `{url_binary, public_key_term, expires_at_datetime}`.

- `fetch_public_key/1` — returns `{:ok, key}` on hit within TTL; `:miss` on miss or expiry; evicts expired entries from ETS before returning `:miss`
- `put/3` — inserts 3-tuple into ETS, overwrites existing entry for same URL
- `reset/0` — deletes all objects (for test isolation)
- `table/0` — returns `:mailglass_webhook_ses_cert_cache`

Uses `Mailglass.Clock.utc_now()` for all TTL comparisons — `DateTime.utc_now()` is banned for testability.

### CertCache.Supervisor + TableOwner

Exact structural copy of `MailgunReplayCache.Supervisor` + `MailgunReplayCache.TableOwner` with SES-specific module names and table atom.

- Supervisor: `:one_for_one`, starts TableOwner with `[name: TableOwner]`
- TableOwner: GenServer creating `:mailglass_webhook_ses_cert_cache` with `:set, :public, :named_table, read_concurrency: true, write_concurrency: :auto`
- `:public` visibility allows CertCache API to read/write directly without message-passing overhead

## TDD Gate Compliance

| Gate | Commit | Status |
|------|--------|--------|
| RED: failing tests | c1fdfc1 | PASSED — 6 tests, 6 failures |
| GREEN: implementation | 7bb099a + 11ba834 | PASSED — 6 tests, 0 failures |
| REFACTOR | n/a | Not needed — implementation was clean |

## Verification Results

```
mix test test/mailglass/webhook/providers/ses/cert_cache_test.exs --warnings-as-errors
6 tests, 0 failures

mix compile --no-optional-deps --warnings-as-errors
Generated mailglass app (clean)

grep "DateTime.utc_now" lib/mailglass/webhook/providers/ses/cert_cache.ex
# Empty — no banned DateTime.utc_now usage
```

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — all four modules are fully implemented with real logic.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced in this plan. TrustPolicy is a pure predicate with no I/O. CertCache is an ETS API module with no network I/O of its own. All threat mitigations from the plan's threat register are implemented:

| Threat | Mitigation | Status |
|--------|------------|--------|
| T-16-02-01: S3 SSRF via namespace collision | `@cert_host_pattern` exact SNS host regex | Implemented |
| T-16-02-02: HTTP scheme downgrade | `scheme: "https"` guard in URI.parse | Implemented |
| T-16-02-03: Userinfo credential injection | `userinfo: nil` guard | Implemented |
| T-16-02-04: Non-.pem certificate path | `String.ends_with?(path, ".pem")` | Implemented |
| T-16-02-05: Stale cached cert after rotation | TTL-aware expiry with eviction on miss | Implemented |
| T-16-02-06: ETS table not found DoS | Supervisor :one_for_one restart recreates table | Implemented (by OTP structure) |

## Self-Check: PASSED

| Item | Status |
|------|--------|
| lib/.../ses/trust_policy.ex | FOUND |
| lib/.../ses/cert_cache.ex | FOUND |
| lib/.../ses/cert_cache/supervisor.ex | FOUND |
| lib/.../ses/cert_cache/table_owner.ex | FOUND |
| test/.../ses/cert_cache_test.exs | FOUND |
| commit c1fdfc1 (RED tests) | FOUND |
| commit 7bb099a (Task 1 GREEN) | FOUND |
| commit 11ba834 (Task 2) | FOUND |
