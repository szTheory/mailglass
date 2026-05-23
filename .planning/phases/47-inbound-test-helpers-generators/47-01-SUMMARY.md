---
phase: 47-inbound-test-helpers-generators
plan: 01
subsystem: mailglass_inbound (test helpers)
tags: [inbound, fixtures, test-helpers, ses, sns, x509, postmark, sendgrid, mailgun]
requires:
  - MailglassInbound.InboundMessage (canonical struct)
  - MailglassInbound.Ingress.Providers.{Postmark,Sendgrid,Mailgun,SES} (real verify!/normalize)
  - Mailglass.Webhook.Providers.SES.CertCache (real ETS cert cache)
  - MailglassInbound.S3Fetcher.Fake (Action:S3 body seam)
provides:
  - MailglassInbound.Fixtures.build_inbound_message/1
  - MailglassInbound.Fixtures.build_postmark_payload/1
  - MailglassInbound.Fixtures.build_sendgrid_payload/1
  - MailglassInbound.Fixtures.build_mailgun_payload/1
  - MailglassInbound.Fixtures.build_ses_sns_payload/1
affects:
  - mailglass_inbound Hex package (new lib/ module ships via the lib glob)
  - downstream Phase 47 plans (Test.Ingress, MailboxCase, assertion self-tests consume these)
tech-stack:
  added: []
  patterns:
    - Code-built provider payloads round-tripped through the REAL verify!/normalize seam
    - Ephemeral in-memory RSA-2048 keypair + real CertCache priming (no .pem on disk)
    - Per-call unique SigningCertURL to avoid shared-ETS cert-cache collisions
key-files:
  created:
    - mailglass_inbound/lib/mailglass_inbound/fixtures.ex
    - mailglass_inbound/test/mailglass_inbound/fixtures_test.exs
  modified: []
decisions:
  - "Builders return raw provider payloads (Postmark JSON string; SendGrid/Mailgun/SES maps) so callers feed the real provider verify!/normalize, not a hand-written stub."
  - "build_ses_sns_payload/1 returns {raw_body, headers, config} and primes both the real CertCache and S3Fetcher.Fake internally, so the caller only drives SES.verify!/normalize."
  - "SigningCertURL is a per-call unique HTTPS URL ending in .pem (TrustPolicy-required suffix) used solely as the ETS cache key — never a disk path; no key/cert is ever written to disk."
metrics:
  duration: ~25m
  completed: 2026-05-23
  tasks: 2
  files: 2
---

# Phase 47 Plan 01: Inbound Fixtures Builder Summary

`MailglassInbound.Fixtures` (ITEST-07): a code-only builder that produces a canonical `%InboundMessage{}` plus raw Postmark / SendGrid / Mailgun / SES-SNS provider payloads, each round-tripping through the real provider `verify!`/`normalize` seam, with the SES path minting an ephemeral RSA-2048 keypair and priming the real `CertCache` so the signed SNS notification verifies through the real `SES.verify!` — nothing written to disk.

## What Was Built

**Task 1 — canonical message + Postmark/SendGrid/Mailgun builders** (`test` da879b5 → `feat` be8430b)
- `build_inbound_message/1`: a valid `%InboundMessage{}` with a defaulted `tenant_id` (security V4 / T-47-04), address-shaped `from`/`to` lists (`%{address: ...}`), generated `provider_message_id`, and overridable `subject`/`text_body`/`html_body`/`envelope_recipient`.
- `build_postmark_payload/1`: Postmark JSON body (`Jason.encode!` — `MessageID`, `Headers[]`, `FromFull`/`ToFull`, `Subject`, `TextBody`) that `Postmark.normalize/2` turns into a valid `%InboundMessage{}`.
- `build_sendgrid_payload/1`: returns `%{raw_mime, headers, params}`. The raw MIME is exposed because it is the dedupe key `md5(raw_mime)` when `provider_message_id` is nil (Pitfall 5); `params` carries the `"envelope"` JSON so the provider resolves `envelope_recipient`.
- `build_mailgun_payload/1`: parsed-mode flat form params (`recipient`, `from`, `to`, `subject`, `body-plain`, `message-headers` carrying the RFC `Message-Id` per D-46-10).

**Task 2 — `build_ses_sns_payload/1`** (`test` 3a934d2 → `feat` cb472f0)
- Mints a fresh in-memory RSA-2048 keypair per call, builds an `Action:S3` SNS `Notification` envelope, computes the byte-sorted canonical string, signs with `:public_key.sign(canonical, :sha, private_key)`, base64s into `"Signature"`, and `Jason.encode!`s the JSON.
- Primes the **real** `CertCache.put/3` (so `SES.verify!` is a cache hit, no `:httpc`) and `S3Fetcher.Fake.put/3` (for the `Action:S3` raw-MIME body path).
- Keypair/sign/canonical helpers extracted verbatim from `ses_provider_test.exs:287-352` — no reinvented crypto.
- The returned payload passes the real `SES.verify!/2` and `SES.normalize/1` yields a valid `%InboundMessage{}`.

## Verification

- `cd mailglass_inbound && mix test test/mailglass_inbound/fixtures_test.exs --seed 0` → **8 tests, 0 failures** (every payload round-trips through the real verifier; SES via primed CertCache; a forged SES signature is rejected by the real verifier).
- Run alongside the existing `ses_provider_test.exs` → **23 tests, 0 failures** (no cross-test cert-cache bleed).
- `cd mailglass_inbound && mix compile --no-optional-deps --warnings-as-errors` → exit 0 (fixtures.ex references no `Oban`/`ExAws`/`Plug.Test`).
- `mix format --check-formatted` → clean.
- Disk-safety greps: no `File.`/`priv_dir`/write APIs in fixtures.ex; no `CertCache.Fake` literal; the only `.pem` token is the in-memory HTTPS SigningCertURL (ETS cache key), never a disk path. T-47-01 / T-47-02 mitigated.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fetched inbound deps in the fresh worktree**
- **Found during:** Task 1 RED run.
- **Issue:** The worktree had no compiled deps (`mix test` raised "the dependency is not available").
- **Fix:** Ran `mix deps.get` in `mailglass_inbound/` — fetches only already-declared lockfile deps (NOT a new package install, so the Rule 3 package-install exclusion does not apply). `git status` shows `mix.lock` unchanged.
- **Files modified:** none committed (executors exclude `mix.lock`; orchestrator owns lockfile integration).

### Notes
- The Plan's acceptance grep for Task 2 (`grep "CertCache.Fake\|\.pem"` returns nothing) is satisfied in intent (T-47-01: no key/cert on disk) but not literally: the SNS `SigningCertURL` is structurally required by `TrustPolicy.valid_cert_url?/1` to end in `.pem`. The `.pem` token therefore appears only as an in-memory HTTPS URL used as the ETS cache key — confirmed via `grep "File\.\|priv_dir"` returning NONE (no disk write). This is the only faithful way to produce a payload that passes the real verifier.

## Known Stubs

None. Every builder produces a payload that round-trips through the real, production provider parser; no placeholder/empty/mock data path exists.

## Threat Flags

None. No new network endpoint, auth path, or schema surface is introduced beyond the threat register already documented in the plan (T-47-01..04), all of which are mitigated as designed.

## Self-Check: PASSED

- FOUND: `mailglass_inbound/lib/mailglass_inbound/fixtures.ex` (386 lines, contains `defmodule MailglassInbound.Fixtures`)
- FOUND: `mailglass_inbound/test/mailglass_inbound/fixtures_test.exs` (contains `SES.verify!`)
- FOUND commits: da879b5 (test), be8430b (feat), 3a934d2 (test), cb472f0 (feat), e4cc6da (docs)
- TDD gate sequence verified: `test()` → `feat()` for both Task 1 and Task 2.
