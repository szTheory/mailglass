# Changelog

All notable changes to `mailglass_inbound` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

`mailglass_inbound` 0.2.0 ships five phases of production-confidence work:
telemetry instrumentation, MIME parsing, the Mailgun provider, a full test
helper suite with generators, admin LiveView integration, and operator tooling.
`mailglass_inbound` remains on the **0.x version line** — the 1.x stability
promise applies to `mailglass` + `mailglass_admin` only. Conductor-style
synthetic inbound dev tool, Cloudflare Email Routing, and `gen_smtp` listener
are the pre-1.0 expansion targets. See
[`guides/compatibility-and-deprecations.md`](../guides/compatibility-and-deprecations.md).

### Phase 45 — Telemetry + MIME (TELE-01..08, MIME-01..02, MIME-04)

- `:telemetry` spans at `[:mailglass_inbound, :ingress, :request, :start/:stop/:exception]`,
  `[:route, :match, *]`, `[:execution, :run, *]`, `[:persist, :record, *]`
  with metadata whitelisted per core PII policy (no recipient/body/subject).
  `MailglassInbound.Telemetry` is the single attach-point module.
- `MailglassInbound.MIME` — RFC 5322 MIME parse seam via
  `Mailglass.OptionalDeps.GenSmtp.decode/2`; returns `{:ok, tuple}` or a
  `{:error, %MailglassInbound.MIMEError{}}`. Never raises. MIME-01, MIME-02,
  MIME-04.
- StreamData property test: 1000-replay convergence proof confirming telemetry
  handler failures do not propagate to business logic (TELE-08).

### Phase 46 — Mailgun + SES Providers (MGUN-01..04, SESI-01..05)

- `MailglassInbound.Ingress.Providers.Mailgun` — HMAC-SHA256 ingress provider
  with dual body-mime/parsed mode. Verifies `X-Mailgun-Signature-V1` header;
  raises `MailglassInbound.SignatureError` on failure per no-recovery contract.
  Supports both raw MIME and pre-parsed Mailgun multipart payloads (MGUN-01..04).
- `MailglassInbound.MIMEError` — a package-local structured error for raw MIME
  parse failures, mirroring the core `Mailglass.ConfigError` shape. Closed
  `:type` set `[:inbound_mime_invalid, :gen_smtp_unavailable]`, a
  `[:type, :message, :cause, :context]` `defexception`, and a `Jason.Encoder`
  derivation that excludes `:cause` so raw payload fragments do not leak into
  serialized output. Matched by struct, never by message string. `@since
  "0.2.0"` (minor bump). It does NOT implement the core `Mailglass.Error`
  behaviour.
- `MailglassInbound.SignatureError` — a package-local, **no-recovery** structured
  error for inbound provider signature failures (Mailgun HMAC, SES SNS X.509, SNS
  `SubscribeURL` trust-policy). Closed `:type` set
  `[:bad_signature, :missing_header, :malformed_header, :timestamp_skew, :subscribe_url_untrusted]`,
  a `[:type, :message, :cause, :context, :provider]` `defexception`, and a
  `Jason.Encoder` derivation that excludes `:cause` and `:provider` so signing
  secrets and raw payload fragments do not leak. Mirrors the no-recovery contract
  of core `Mailglass.SignatureError` while staying package-local (it does NOT
  implement the core `Mailglass.Error` behaviour). `@since "0.2.0"` (minor bump).
  (D-46-19)
- `MailglassInbound.S3FetchError` — a package-local structured error for AWS SES
  inbound S3-object fetch failures, mirroring the `MailglassInbound.MIMEError`
  shape. Closed `:type` set `[:s3_object_not_ready, :s3_fetch_failed]`, a
  `[:type, :message, :cause, :context]` `defexception`, and a `Jason.Encoder`
  derivation that excludes `:cause`. Matched by struct, never by message string.
  It does NOT implement the core `Mailglass.Error` behaviour. `@since "0.2.0"`
  (minor bump). (D-46-17)
- `MailglassInbound.OptionalDeps.ExAwsS3` — inbound-local optional-dep gateway
  for `ex_aws`/`ex_aws_s3`, mirroring the `Mailglass.OptionalDeps.GenSmtp` shape
  (`@compile {:no_warn_undefined, [ExAws, ExAws.S3]}` + `available?/0` +
  never-raise `get_object/2`). All `ExAws`/`ExAws.S3` access in inbound flows
  through this gateway; bare references are forbidden by `NoBareOptionalDepReference`.
  (D-46-14)
- `MailglassInbound.S3Fetcher.Fake` (fake-adapter-first test default, D-13) and
  `MailglassInbound.S3Fetcher.ExAwsS3` (real, optional-dep-gated) — implementations
  of the `MailglassInbound.S3Fetcher` behaviour. The fetcher module is resolved
  via a config-map-then-app-env seam defaulting to `Fake` in `:test` and
  `ExAwsS3` otherwise (D-46-13).
- `MailglassInbound.Ingress.Providers.SES` — SES inbound provider. Verifies the
  SNS X.509 signature by reusing core's `Mailglass.Webhook.Providers.SES.verify_envelope!/2`
  seam (CertCache + TrustPolicy), auto-confirms `SubscriptionConfirmation` /
  `UnsubscribeConfirmation` as a `{:control_plane, 200}` no-op (no record), and
  extracts the raw MIME body from the receipt-rule S3 action (primary) or the
  SNS-inline `content` field (secondary, ≤150 KB) into the canonical
  `%MailglassInbound.InboundMessage{}` + evidence. A small bounded GetObject
  retry maps exhaustion to `MailglassInbound.S3FetchError` `:s3_object_not_ready`
  so SNS redelivers. (SESI-01, SESI-02, SESI-04, SESI-05)

### Phase 47 — Test Helpers + Generators (ITEST-01..09, IGEN-01..04)

- `MailglassInbound.MailboxCase` — ExUnit test case module (`async: false`,
  ETS sandbox). Use `use MailglassInbound.MailboxCase` in inbound tests
  (ITEST-01).
- `MailglassInbound.TestAssertions` — four assertion styles: exact match,
  pattern match, outcome assertion, routing assertion. `assert_routed_to/2`,
  `assert_mailbox_received/2`, `refute_mailbox_received/1` (ITEST-02..06).
- `MailglassInbound.Test.Ingress` — test ingress dispatch helper for bypassing
  the HTTP layer in unit tests (ITEST-07).
- `MailglassInbound.Fixtures` — in-memory fixture builder. No `.eml` files on
  disk; fixtures are constructed programmatically for Postmark, SendGrid,
  Mailgun, and SES-SNS payloads (ITEST-08, ITEST-09).
- `mix mailglass.gen.mailbox` — generates a `MyApp.Mailboxes.MyMailbox` module
  with `@behaviour MailglassInbound.Mailbox` (IGEN-01, IGEN-02).
- `mix mailglass.gen.inbound_router` — generates the router module for inbound
  routing configuration (IGEN-03).
- `mix mailglass.gen.inbound_route` — generates an individual route entry
  (IGEN-04). All generators perform idempotent Sourceror-zipper edits and
  support `--dry-run`.

### Phase 48 — Admin LiveView Integration (IADM-01..07)

- InboundLive shipped via `mailglass_admin` 1.2.0. Requires
  `{:mailglass_admin, "~> 1.2"}` for the admin UI. The inbound package itself
  has no LiveView dependency — the UI is entirely in `mailglass_admin`.
  See `mailglass_admin` 1.2.0 CHANGELOG for the full admin surface narrative.

### Phase 49 — Runtime Operator Tooling (IOPS-01..05)

- `MailglassInbound.InboundMessage.Signals` — a framework-owned, read-only typed
  nested struct carrying framework-derived signals about an inbound message
  (today `suppression_flagged: false`), exposed on the new
  `%MailglassInbound.InboundMessage{}.signals` field (defaults to `%Signals{}`).
  Plus `MailglassInbound.InboundMessage.suppression_flagged?/1`. Every field is
  defaulted and non-nil, so safe dot-access never raises — including for records
  persisted before the signal column existed. A new
  `suppression_flagged :boolean, null: false, default: false` column on
  `mailglass_inbound_records` (generated migration adopters run) is the source of
  truth; a message from a suppressed sender persists normally with the flag set
  and still reaches the mailbox — there is no auto-bounce and no auto-suppression
  (IOPS-05). **Deviation D-49-21:** IOPS-05's literal wording places the flag at
  `.metadata.suppression_flagged`; it ships at `.signals.suppression_flagged`
  because `:metadata` is reserved framework-wide for adopter-owned data
  (SESI-04-erratum precedent). `@since "1.2.0"` (linked minor bump).
- `mix mailglass.inbound.doctor` — three-state exit (0 = healthy, 1 = warnings,
  2 = errors). DNS-free checks. `--strict` flag promotes warnings to errors.
  `--format json` for CI integrations (IOPS-01).
- `mix mailglass.inbound.replay` — tenant-scoped message replay. `--tenant` is
  REQUIRED. `--dry-run` for preview, `--yes` for cron/CI (IOPS-02).
- `mix mailglass.inbound.prune` — typed "yes" confirmation for destructive prune.
  `--dry-run`, `--yes` flags. Bounded retention window (IOPS-03).
- `MailglassInbound.RateLimiter` — three-bucket rate limiter (tenant /
  sender_domain / recipient) with ETS-backed sliding window (IOPS-04).

### Dependencies

- **Added `{:ex_aws, "~> 2.7", optional: true}` and `{:ex_aws_s3, "~> 2.5",
  optional: true}`** — the FIRST new optional runtime deps since the v1.0 STACK
  lock ("Optional deps: Add none"). Deliberate, scoped departure (D-46-20): they
  are exercised only by the SES inbound provider's real S3 fetcher and gated
  behind `MailglassInbound.OptionalDeps.ExAwsS3`, so a default install carries no
  AWS footprint and `mix compile --no-optional-deps --warnings-as-errors` stays
  green. Both verified on Hex (ex_aws 2.7.x, ex_aws_s3 2.5.x).

## 0.1.0 (2026-05-07)


### Features

* **39-01:** implement inbound message contract ([bb0173f](https://github.com/szTheory/mailglass/commit/bb0173f5a16c2356f1790f9d916ead3ea5510fbc))
* **39-01:** implement inbound routing and mailbox contracts ([47e6cf9](https://github.com/szTheory/mailglass/commit/47e6cf978cd1bf8c18b852fc166fc1a51061c6a4))
* **39-02:** implement inbound storage foundation ([2e6a6d1](https://github.com/szTheory/mailglass/commit/2e6a6d10d39605fd7df9cb1cd283e4ea1106e5dc))
* **39-02:** normalize replay outcomes for storage ([409d2a7](https://github.com/szTheory/mailglass/commit/409d2a7b6cad4b6974a96c3eb985cf9c0f18a5fe))
* **39-03:** publish inbound package contract docs ([9331e96](https://github.com/szTheory/mailglass/commit/9331e96db641d3d628c5efe08a251ba263f48d2a))
* **39-03:** scaffold inbound package contract shell ([768b53b](https://github.com/szTheory/mailglass/commit/768b53ba8eee5900948577636d836e38b7599254))
* **41-01:** extend ingress plug for sendgrid ([91c458d](https://github.com/szTheory/mailglass/commit/91c458d8887a76bb65895f650b6005045860f501))
* **41-01:** implement sendgrid ingress provider ([8b68f96](https://github.com/szTheory/mailglass/commit/8b68f96619c3d2b02af5a5948f841fa9e480d8f5))
* **41-02:** generalize replay lineage into execution runs ([7b5e53f](https://github.com/szTheory/mailglass/commit/7b5e53f89a193a1a0dce534c39b6f8c478a54f76))
* **41-02:** run mailbox execution after durable ingress persistence ([c1df869](https://github.com/szTheory/mailglass/commit/c1df86939b6c7e7e4850a187028de0f9946e4b30))
* **41-03:** implement truthful replay and sendgrid dedupe ([8d6f33b](https://github.com/szTheory/mailglass/commit/8d6f33b0c9fef62ec2fa431ffe5817d1da0c2656))
* **42-01:** add inbound async execution seam ([547529c](https://github.com/szTheory/mailglass/commit/547529c6285a8594c21b368e0c47a9662bd90276))
* **42-01:** rewire ingress and replay to shared execution seam ([1d88d13](https://github.com/szTheory/mailglass/commit/1d88d13cc1df812d44887d2d658f35aca770f0fb))
* **42-02:** publish canonical inbound setup docs ([570b8cb](https://github.com/szTheory/mailglass/commit/570b8cbeb7ae46a90932d66e04c810fe636006f4))
* **42-03:** align inbound release proof ([79524c0](https://github.com/szTheory/mailglass/commit/79524c0e0c456d913f7cd0603eec1dc5201efb70))
* **42-03:** extend root inbound proof lane ([8796091](https://github.com/szTheory/mailglass/commit/879609120066c6b106853539c0e2d692e2fd2a2a))


### Miscellaneous Chores

* release 0.1.0 ([e26b691](https://github.com/szTheory/mailglass/commit/e26b6910f8859e3489937739da9a0db37e46ad90))
* release 0.1.1 ([bfd001f](https://github.com/szTheory/mailglass/commit/bfd001fdf3a994de0da74b0091c1d60972c57605))
* **release:** force 0.1.0 first publish for mailglass_inbound ([dd61b5c](https://github.com/szTheory/mailglass/commit/dd61b5cb2e7237422af697f7c774c7dfefad0c35))

## [0.1.0] - 2026-05-XX

`mailglass_inbound` 0.1.0 is the first Hex appearance of the inbound sibling
package. It ships on a separate, unlinked 0.x version line per
[`guides/compatibility-and-deprecations.md`](../guides/compatibility-and-deprecations.md).
The 1.x compatibility promise applies to `mailglass` core and `mailglass_admin`
only; `mailglass_inbound` remains 0.x while the inbound API surface
stabilizes.

### Added

- Canonical manual setup documentation for the `mailglass_inbound` package.
- Postmark and SendGrid provider guides with contract-tested durability and replay wording.
- Oban-backed async execution with bounded Task.Supervisor fallback semantics.

### Changed

- Repo-root verification now treats inbound docs and sibling-package release proof as release-blocking truth.
