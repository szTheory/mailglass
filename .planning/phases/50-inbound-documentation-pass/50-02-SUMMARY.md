---
phase: 50-inbound-documentation-pass
plan: "02"
subsystem: mailglass_inbound/docs
tags: [documentation, mailgun, ses, inbound, setup-guide]
dependency_graph:
  requires: [50-01]
  provides: [inbound-mailgun-guide, inbound-ses-guide]
  affects: [mailglass_inbound/docs]
tech_stack:
  added: []
  patterns:
    - Provider-specific ingress guide (H2 section structure matching postmark_ingress.md)
    - Copy-pasteable config blocks with TODO comments for adopter secrets
    - IAM policy JSON templates with realistic placeholder names
key_files:
  created:
    - mailglass_inbound/docs/inbound-mailgun.md
    - mailglass_inbound/docs/inbound-ses.md
  modified: []
decisions:
  - "SES guide warns (blockquote) that default s3_fetcher is test-only Fake, must be set explicitly for production"
  - "SES IAM policy split into two templates: SES delivery role (PutObject) and application read role (GetObject)"
  - "SubscribeURL trust policy explains hardcoded SNS host pattern and why no adopter allowlist is needed (SSRF rationale)"
  - "Mailgun guide explicitly documents mg. subdomain requirement to prevent MX record confusion"
  - "KMS section frames client-side KMS as unsupported (not a crash, but a degraded record) and directs to SSE"
metrics:
  duration_minutes: 15
  completed_date: "2026-05-25"
  tasks_completed: 2
  files_created: 2
  files_modified: 0
requirements: [IDOC-04, MGUN-05, SESI-06]
---

# Phase 50 Plan 02: Mailgun and SES Inbound Setup Guides Summary

Provider-specific inbound setup guides for Mailgun (HMAC-SHA256 flat-field verification, two payload modes, replay protection) and SES (SNS X.509 + S3 fetch pipeline, IAM policy templates, SubscribeURL trust policy, KMS limitation, S3 consistency retry).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 0 | Read all source interfaces | (no commit — read-only) | mailgun.ex, ses.ex, plug.ex, trust_policy.ex, s3_fetcher.ex, ex_aws_s3.ex, postmark_ingress.md |
| 1 | Write inbound-mailgun.md (MGUN-05) | 3c73857 | mailglass_inbound/docs/inbound-mailgun.md |
| 2 | Write inbound-ses.md (SESI-06) | e2ad369 | mailglass_inbound/docs/inbound-ses.md |

## Verification Results

```
ls mailglass_inbound/docs/
  api_stability.md
  inbound-install.md
  inbound-mailgun.md   <- new
  inbound-operator.md
  inbound-ses.md       <- new
  inbound-testing.md
  postmark_ingress.md
  sendgrid_ingress.md

grep "signing_key" inbound-mailgun.md  → found in config block and key rotation
grep "HMAC-SHA256" inbound-mailgun.md  → found in verification section
grep "CachingBodyReader" inbound-mailgun.md  → found in Plug.Parsers wiring
grep "replay" inbound-mailgun.md  → Replay Protection section with 200 no-op explanation
grep "body-mime" inbound-mailgun.md  → Two Payload Modes section
grep "D-[0-9]|LINT-[0-9]|T-49-" inbound-mailgun.md  → 0 (no internal IDs)

grep "ex_aws_s3" inbound-ses.md  → deps block
grep "sweet_xml" inbound-ses.md  → deps block
grep "S3Fetcher.ExAwsS3" inbound-ses.md  → config section (production fetcher)
grep "Warning" inbound-ses.md  → prominent blockquote: default s3_fetcher is test-only
grep "s3:GetObject" inbound-ses.md  → IAM policy template
grep "SubscribeURL" inbound-ses.md  → auto-confirmation + trust policy section
grep "SubscriptionConfirmation" inbound-ses.md  → control-plane explanation
grep -i "client-side KMS" inbound-ses.md  → KMS limitation (not supported)
grep "D-[0-9]|LINT-[0-9]|T-49-" inbound-ses.md  → 0 (no internal IDs)
```

## Content Coverage

### inbound-mailgun.md

- Mount path with `provider: :mailgun` plug option
- Plug.Parsers CachingBodyReader wiring (reference to install guide)
- Mailgun Route Setup: dashboard navigation, filter expressions, forward action
- MX/subdomain section: `mg.` subdomain requirement, not main domain
- Configuration: `signing_key` config key with copy-pasteable `runtime.exs` block and TODO comment
- Where to find signing key: Mailgun Dashboard → Settings → API Security → HTTP Webhook Signing Key
- Optional tuning: `timestamp_tolerance_seconds`, `future_skew_seconds`, `replay_cache_ttl_seconds`
- Signing Key Rotation: no-downtime rotation, 5-minute Mailgun tolerance window
- Verification: HMAC-SHA256 over flat `timestamp <> token`, not nested JSON
- Replay Protection: 200 no-op (not 401), provider retry loop prevention rationale
- Two Payload Modes: `body-mime` field detection, raw MIME vs parsed fields, auto-detected
- Persistence Semantics: dual record write, duplicate collapse, execution dispatch

### inbound-ses.md

- Overview: SES receipt rules → S3 (raw MIME) + SNS notification → endpoint pipeline
- Distinction from SES sending-event webhooks
- Mount path with `provider: :ses` plug option
- Plug.Parsers CachingBodyReader wiring
- SNS Topic Setup: Standard type, HTTPS subscription, auto-confirmation explanation
- IAM Policy: two templates — SES delivery role (`s3:PutObject`) + application read role (`s3:GetObject`)
- SES Receipt Rule Setup: S3 action first, SNS action second, order note for consistency
- Optional Deps Install: `ex_aws ~> 2.7`, `ex_aws_s3 ~> 2.5`, `sweet_xml ~> 0.7`, HTTP client options
- AWS credentials: standard ex_aws chain, no mailglass-specific config
- Configuration: `s3_fetcher: MailglassInbound.S3Fetcher.ExAwsS3` with prominent warning about Fake default
- Optional tuning: `cert_cache_ttl_seconds`, `s3_retry_opts`
- SubscribeURL Trust Policy: hardcoded `sns.*.amazonaws.com` pattern, SSRF rationale, no adopter allowlist
- S3 Consistency: 3-attempt retry with 250ms/1000ms/2000ms backoff, configurable
- KMS Limitation: client-side KMS unsupported (degraded record), use SSE-S3 or SSE-KMS
- Testing in Development: Fake adapter default, `build_ses_sns_payload/1` fixture
- Persistence Semantics: dual record write, duplicate collapse, control-plane no-op for SNS control messages

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. Both guides are complete end-to-end walkthroughs with no placeholder sections.

## Threat Flags

None. Documentation files introduce no new network endpoints, auth paths, or trust boundaries.

## Self-Check: PASSED

- `mailglass_inbound/docs/inbound-mailgun.md` exists: FOUND
- `mailglass_inbound/docs/inbound-ses.md` exists: FOUND
- Task 1 commit 3c73857: FOUND
- Task 2 commit e2ad369: FOUND
- No internal GSD IDs in either file: CONFIRMED (grep returns 0)
- `signing_key` in Mailgun guide: CONFIRMED
- `S3Fetcher.ExAwsS3` in SES guide: CONFIRMED
- `sweet_xml` in SES deps: CONFIRMED
- `s3:GetObject` IAM policy in SES guide: CONFIRMED
- KMS limitation section present and client-side KMS framed as unsupported: CONFIRMED
