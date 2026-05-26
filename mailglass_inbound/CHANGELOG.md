# Changelog

All notable changes to `mailglass_inbound` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0](https://github.com/szTheory/mailglass/compare/mailglass_inbound-v0.1.0...mailglass_inbound-v0.2.0) (2026-05-25)


### Features

* **45-01:** inbound config tree + Postgres TestRepo + gen_smtp optional dep ([6809164](https://github.com/szTheory/mailglass/commit/6809164dc8439ef35bd0f043dbbb0dc2c8631e36))
* **45-01:** migration-running inbound test_helper + Postgres CI job ([64d1796](https://github.com/szTheory/mailglass/commit/64d17968082c53259ff3ad83a55e75f3c8b7a28b))
* **45-01:** widen Credo to inbound + telemetry/optional-dep checks + api_stability ([e6b808a](https://github.com/szTheory/mailglass/commit/e6b808ae6f20dc1069e928db47979f57d3e35307))
* **45-02:** add MailglassInbound.Telemetry span surface + PubSub.Topics builder ([3c78da7](https://github.com/szTheory/mailglass/commit/3c78da748e6ef0377a47aaa24b6596ed00691b94))
* **45-02:** post-commit inbound broadcast (TELE-07) + telemetry coverage tests (TELE-05) ([3114ac1](https://github.com/szTheory/mailglass/commit/3114ac1b648114551ae6a9f5d31b033100d8b0de))
* **45-02:** wrap the four inbound span sites (route/persist/execution/ingress) ([2661610](https://github.com/szTheory/mailglass/commit/266161097072b8147e3a19eeeff703d29912ada6))
* **45-03:** add never-raising MailglassInbound.MIME parser ([c2d52f4](https://github.com/szTheory/mailglass/commit/c2d52f4229032063323649340a2a4313f477551a))
* **45-03:** add package-local MailglassInbound.MIMEError defexception ([f767771](https://github.com/szTheory/mailglass/commit/f7677711ce7f416cccc03b640b716629fc1fb117))
* **45-04:** wire stream_data + CI gate to green the convergence proof (TELE-08) ([75df25b](https://github.com/szTheory/mailglass/commit/75df25b449664840c579fe4d0125f0cd4b4f0bed))
* **46-01:** add net-new closed-type inbound errors SignatureError + S3FetchError ([97f7202](https://github.com/szTheory/mailglass/commit/97f7202620c520615c51d2cb457757930eab26db))
* **46-01:** add S3Fetcher behaviour + widen Ingress.Provider verify! callback ([d3ab5fe](https://github.com/szTheory/mailglass/commit/d3ab5fedcf13e7aa66ebbe916f40802bcfb081b9))
* **46-01:** widen ingress plug to 4 providers + extract SES verify_envelope!/2 ([6b3c6ed](https://github.com/szTheory/mailglass/commit/6b3c6eddea2933d1f73712dc31027edbb9c7f619))
* **46-02:** Mailgun inbound provider — flat-field HMAC verify + replay no-op + Message-Id ([85749d8](https://github.com/szTheory/mailglass/commit/85749d8bdf671bbec3eee7e5d0da2c2fb19845e1))
* **46-02:** Mailgun normalize (parsed + raw-MIME) + evidence; fingerprint index + persist dedupe ([7b1830b](https://github.com/szTheory/mailglass/commit/7b1830be8fb1e8bcd7fd89e022d16c7a7b1418b3))
* **46-03:** add inbound-local ExAwsS3 optional-dep gateway ([2e82eb0](https://github.com/szTheory/mailglass/commit/2e82eb078047dd54a96980db58458e9f9f213b17))
* **46-03:** add S3Fetcher Fake/ExAwsS3 adapters + bounded retry ([3dacc30](https://github.com/szTheory/mailglass/commit/3dacc306f47f1249fe660cad4be2274e7195fb4f))
* **46-03:** add SES inbound provider with SNS verify + S3/inline MIME ([69b1e3b](https://github.com/szTheory/mailglass/commit/69b1e3b3bd569016cdc11a06616b3d7b1b0646f0))
* **47-01:** add build_ses_sns_payload/1 with real CertCache priming ([bcea3f7](https://github.com/szTheory/mailglass/commit/bcea3f7767ccb895cda0bf5beceedb042350ad50))
* **47-01:** implement Fixtures canonical message + Postmark/SendGrid/Mailgun builders ([a394c00](https://github.com/szTheory/mailglass/commit/a394c002e00083fdc104f9f03a97ac4f4c75b515))
* **47-03:** implement MailglassInbound.TestAssertions (ITEST-01..04) ([eb42b8e](https://github.com/szTheory/mailglass/commit/eb42b8e846226df0d242ff3f2f3689d85a04ea06))
* **47-03:** implement Test.Ingress real persist+execute driver (ITEST-06) ([f199239](https://github.com/szTheory/mailglass/commit/f1992398cc68000785006666180ce8055300d589))
* **47-04:** build MailglassInbound.MailboxCase ExUnit case template (ITEST-05) ([547ebbb](https://github.com/szTheory/mailglass/commit/547ebbb6ad16070f975f7a53ab7a2f8f54ff9af7))
* **47-04:** package the four inbound Testing helpers under an ExDoc Testing group ([dff2870](https://github.com/szTheory/mailglass/commit/dff28706fe407f1b7bd219f9c66e50cc3624dec4))
* **48-01:** add Router.Matcher.explain/2 reflection (IADM-04) ([9f6ef94](https://github.com/szTheory/mailglass/commit/9f6ef9401f37c856e42a16c59799c112f834848d))
* **48-01:** inbound read-model Internal.Operator.{Records,Timeline,Detail} (IADM-01) ([fb94791](https://github.com/szTheory/mailglass/commit/fb94791b366d5cbe10fa432151907098046ccc34))
* **49-01:** MailglassInbound.Config + RateLimiter + TableOwner + supervised child ([28d2f2f](https://github.com/szTheory/mailglass/commit/28d2f2ff4f6e0cc3371ea1754caf103641d43775))
* **49-01:** post-verify rate-limit 429 in Ingress.Plug + 3 telemetry span helpers ([267b600](https://github.com/szTheory/mailglass/commit/267b600a67e1ec850656d70934558e16ae963fd9))
* **49-02:** add suppression_flagged column + Signals struct + :signals field (IOPS-05) ([3f017e0](https://github.com/szTheory/mailglass/commit/3f017e0cb8842e0e4ff2884556463c82f7f52f43))
* **49-02:** wire degrade-OPEN suppression flag compute + projection + IADM-02 select (IOPS-05) ([83b6410](https://github.com/szTheory/mailglass/commit/83b641087e81de73927b7610bb0b4719ed042708))
* **49-03:** batched advisory-locked prune + replay/prune CLI tasks (IOPS-02, IOPS-03) ([30c8e3f](https://github.com/szTheory/mailglass/commit/30c8e3fbd8912c17b48cfd62348a9b1d50eeaa23))
* **49-03:** DNS-free inbound doctor with three-state exit (IOPS-01, MIME-03) ([93a815e](https://github.com/szTheory/mailglass/commit/93a815e9759461fdda91580dee31d95dd7e0e21f))
* **50-03:** add inbound docs to mix.exs extras and extend docs_contract_test ([d0fc831](https://github.com/szTheory/mailglass/commit/d0fc831755aa37f40d696564b8521f81c6969da1))


### Bug Fixes

* **45-06:** suppress cross-package Oban middleware xref in inbound no-optional-deps compile ([d9308d7](https://github.com/szTheory/mailglass/commit/d9308d75a3a2477691d409b500f00b1bc55037e3))
* **45-07:** make persist-failure egress PII-safe (static body + error_kind in stop-meta) ([2bf1571](https://github.com/szTheory/mailglass/commit/2bf157194b4c0c7a5df4b3e429cdbca205d91117))
* **46:** add SES MD5(raw_mime) dedupe fallback for missing messageId (WR-02) ([d4364c9](https://github.com/szTheory/mailglass/commit/d4364c95030267000df2c9c9f7ef959844cd8b3c))
* **46:** add unique_constraint for Mailgun fingerprint dedupe race (CR-01) ([e177ff2](https://github.com/szTheory/mailglass/commit/e177ff22ee58bbd91311edfbdb68b4aeb151ee59))
* **46:** gate ExAwsS3 gateway on available?/0 and tag absent dep (WR-06) ([f58f5b2](https://github.com/szTheory/mailglass/commit/f58f5b22b40edd2bde15519bf72bf354fc47d111))
* **46:** harden SES verify-&gt;normalize handoff fallback (WR-01) ([4bf659c](https://github.com/szTheory/mailglass/commit/4bf659cfc91688986cc40de9267a6947df067052))
* **46:** rescue S3FetchError in ingress plug with transient/permanent mapping (CR-02) ([4df1903](https://github.com/szTheory/mailglass/commit/4df1903a84fbfc5e604134f29247be0fbaf8fe6f))
* **46:** thread :s3_retry_opts through SES resolve_config! (WR-04) ([f90e21b](https://github.com/szTheory/mailglass/commit/f90e21b9e41636b0e580eac56fe64159d48c8881))
* **46:** tighten SES inline base64 heuristic and record parse_warning (WR-05) ([dbe9846](https://github.com/szTheory/mailglass/commit/dbe984689400915c0c7afa281386c96139cdfe8d))
* **47:** CR-01 fix broken README/MailboxCase usage example ([3715296](https://github.com/szTheory/mailglass/commit/3715296566a329933df7a154eea38ad5097d13a0))
* **47:** CR-01 make SendGrid/Mailgun receive_provider_payload compose out of the box ([7f7d930](https://github.com/szTheory/mailglass/commit/7f7d93010e27f223d3c2b8b81e41c3b221579867))
* **47:** IN-03 handle captured-function syntax in assert_inbound_received ([126a5b9](https://github.com/szTheory/mailglass/commit/126a5b99b7ef2fee4c3535608970213e73ef91c0))
* **47:** IN-04 clarify Test.Ingress PII-posture moduledoc ([e0d6472](https://github.com/szTheory/mailglass/commit/e0d6472689c65d934baaefc9948815ba1deb3913))
* **47:** WR-01 resolve version metadata drift to 0.1.0 ([b6b4e89](https://github.com/szTheory/mailglass/commit/b6b4e89826adcd7fd7d7c31e3901d69a3c394c67))
* **47:** WR-02 correct FIFO semantics in outcome/routing assertion docs ([3b410ec](https://github.com/szTheory/mailglass/commit/3b410ecf36c0b16e46028a178115bf6818a504ee))
* **47:** WR-04 reject non-binary :from/:to with an accurate matcher message ([d4ba54c](https://github.com/szTheory/mailglass/commit/d4ba54cbcdacc85c308af69c960b9d19347984ca))
* **47:** WR-05 document SES CertCache cross-test hygiene ([31559c0](https://github.com/szTheory/mailglass/commit/31559c0fb167aa48f4a48aaaee35aaa26182c7cc))
* **47:** WR-06 cover receive_inbound/2 raw_mime-dedupe contract for SendGrid ([c9a93f5](https://github.com/szTheory/mailglass/commit/c9a93f5043614f59cdad102e0f8b64b85226ec1c))
* **47:** WR-07 stop steering adopters to the internal Route struct ([8b4e4fa](https://github.com/szTheory/mailglass/commit/8b4e4fa3e12288bf4c50c88ad8d5594cc34b07a4))
* **47:** WR-08 add receive_provider_payload/3 driver tests for sendgrid and mailgun ([42be994](https://github.com/szTheory/mailglass/commit/42be9940af7c2bc40e30e91ec3cec566c9952e90))
* **48:** inbound list read-model — real disposition + search clause (WR-01, WR-03) ([6bfe32b](https://github.com/szTheory/mailglass/commit/6bfe32b0dacd9489f1ac6cf0e2863bf9674593df))
* **48:** thread inbound search end-to-end + assert list disposition (WR-03, WR-01) ([ddb6f31](https://github.com/szTheory/mailglass/commit/ddb6f31ef5f92419788d524de4b47707c2d62dbc))
* **49:** CR-01 pin advisory lock to one connection via Repo.checkout ([ae2e755](https://github.com/szTheory/mailglass/commit/ae2e75573044c4989cc2c75eb240e39e3865c939))
* **49:** CR-02 clamp retention windows to FK lineage so prune never trips on_delete: :nothing ([0911211](https://github.com/szTheory/mailglass/commit/0911211ee75f46fe57e644a0fe13e0c569aa9224))
* **49:** neutralize inbound ingress rate limiter in test env ([79272e4](https://github.com/szTheory/mailglass/commit/79272e4cbd0d5767abc1aca42abb45373afff9cc))
* **49:** T-49-17 tenant-scope inbound replay to prevent cross-tenant replay ([3f92c1d](https://github.com/szTheory/mailglass/commit/3f92c1d391fa1e40391db777819f5045aef6fb9b))
* **49:** WR-01 set rate-limit per_minute == capacity so advertised N/min is the sustained rate ([9dbcad3](https://github.com/szTheory/mailglass/commit/9dbcad393936253a363a5607cc0ce8d46e69d49b))
* **49:** WR-02 declare --no-start in doctor task strict option spec ([7d676ac](https://github.com/szTheory/mailglass/commit/7d676ac891dcd0ad75206d351db3e5183f140173))
* **49:** WR-03 compute suppression flag before the inbound write transaction ([4cde2ed](https://github.com/szTheory/mailglass/commit/4cde2ed8ab4922f38f141340009258e2d98b3de0))
* **49:** WR-04 count cannot-diagnose findings separately from fail in doctor summary ([e38f602](https://github.com/szTheory/mailglass/commit/e38f602710d141caee9bdfc7530e82a7f2798526))
* **docs:** CR-01 use signals.suppression_flagged instead of metadata[:suppression_flagged] ([f53e486](https://github.com/szTheory/mailglass/commit/f53e48698e4e5478423fb011b772602d080c586c))
* **docs:** CR-02 CR-03 fix SES subscription confirmation and fixture API docs ([1043d54](https://github.com/szTheory/mailglass/commit/1043d5466e810a11284a690e4181198615992e55))
* **docs:** WR-01 correct mailglass_inbound version pin from ~&gt; 0.2 to ~&gt; 0.1 ([5467669](https://github.com/szTheory/mailglass/commit/546766914179602b43b3231c63304c3ffa565ef8))
* **docs:** WR-03 clarify test.exs repo config is optional override, not a duplicate ([dab4f72](https://github.com/szTheory/mailglass/commit/dab4f72c0016c249413270a9ec92e651fa05afd9))
* **docs:** WR-04 remove TODO comment from inbound-mailgun.md configuration block ([6c39049](https://github.com/szTheory/mailglass/commit/6c390495644d496f927aee64296570e5944ea01b))

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
