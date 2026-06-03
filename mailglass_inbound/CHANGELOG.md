# Changelog

All notable changes to `mailglass_inbound` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.3](https://github.com/szTheory/mailglass/compare/mailglass_inbound-v1.1.2...mailglass_inbound-v1.1.3) (2026-06-03)


### Bug Fixes

* **inbound:** track mailglass core pin to == 1.4.3 for the 1.4.3 linked release ([1bd1291](https://github.com/szTheory/mailglass/commit/1bd12915e3d97ecd976ea97ed6c91654edabb03e))

## [1.1.2](https://github.com/szTheory/mailglass/compare/mailglass_inbound-v1.1.1...mailglass_inbound-v1.1.2) (2026-06-03)


### Bug Fixes

* **inbound:** track mailglass core pin to == 1.4.2 for the 1.4.2 linked release ([fae6dd1](https://github.com/szTheory/mailglass/commit/fae6dd1673ad589b390b34396eb9bb64516fbecd))

## [1.1.1](https://github.com/szTheory/mailglass/compare/mailglass_inbound-v1.1.0...mailglass_inbound-v1.1.1) (2026-06-02)


### Bug Fixes

* **inbound:** bump README/install dep pins to mailglass ~&gt; 1.4, inbound ~&gt; 1.1 ([bd64c9c](https://github.com/szTheory/mailglass/commit/bd64c9c790bfe1b1917f0683c1953a7f88cb56a3))

## [1.1.0](https://github.com/szTheory/mailglass/compare/mailglass_inbound-v1.0.0...mailglass_inbound-v1.1.0) (2026-06-02)


### Features

* **64-05:** delegate root stability lane to inbound support contract alias ([37388f4](https://github.com/szTheory/mailglass/commit/37388f44f5197e655bf6a285f008f9a5ef608fbc))
* **66-02:** apply inbound 1.0.0 candidate and release notes ([7c5d77e](https://github.com/szTheory/mailglass/commit/7c5d77ef06f1baa052408d51b0607fbb8dac9369))


### Bug Fixes

* **63-01:** restore inbound docs check tokens ([650b379](https://github.com/szTheory/mailglass/commit/650b3799030072c0c026930d030d5613f245d745))
* **64-01:** annotate direct runtime seams with 0.1.0 since metadata ([f2edf58](https://github.com/szTheory/mailglass/commit/f2edf5800da4e36aa88c0f0f36b0b6d0e5f38b5c))
* **64-01:** normalize inbound package-line since metadata ([445f23a](https://github.com/szTheory/mailglass/commit/445f23a41e3576f62bfcca17ec6e0ef9671b73be))
* **64-03:** align test assertion and case metadata to 0.2.0 ([cf54dd7](https://github.com/szTheory/mailglass/commit/cf54dd79ab9afa486e233282d5cf24687021bb94))
* **64-03:** tag fixtures and ingress testing helpers as 0.2.0 ([891e269](https://github.com/szTheory/mailglass/commit/891e2692475db16b021a5dd6ac8bde8ac4e8381a))
* **64-review:** close contract review findings ([b1abd77](https://github.com/szTheory/mailglass/commit/b1abd77290798139eeb6068dcf1c54ee566d61ec))
* **65:** resolve provider contract review findings ([42ceef2](https://github.com/szTheory/mailglass/commit/42ceef254ea45aa3214febfc1a3aa4dcf725ed6f))
* **66-02:** refresh publish proof and lock phase 66 governance state ([ce26a56](https://github.com/szTheory/mailglass/commit/ce26a566331293b97cf8fd77e8ffb237447dbb26))
* **66:** clean inbound changelog release truth ([eab4312](https://github.com/szTheory/mailglass/commit/eab431260f85f11f39399cd885e5789df002c575))
* **72-03:** correct source_ref_pattern to mailglass_inbound-v%{version} ([0e1f65b](https://github.com/szTheory/mailglass/commit/0e1f65b9a818ddd033577a634adc0d61df44c107))
* **72:** WR-01 make inbound changelog over-claim guard meaningful ([ab116f4](https://github.com/szTheory/mailglass/commit/ab116f4fece2519961f2bdee9dd29ba15da67e02))
* **73:** WR-01 gate pending-marker asserts behind staged-posture check ([cfcf055](https://github.com/szTheory/mailglass/commit/cfcf055c11939cbcba642afb1602e2a1b78ba4bd))
* **73:** WR-02 bind REL-03 field asserts to exact labels (folds IN-02) ([cfaae1d](https://github.com/szTheory/mailglass/commit/cfaae1dad38fe01765764c8e04aefad0665f5a9e))
* **73:** WR-03 guard inbound release-record path against archival with readable flunk ([adaa0d7](https://github.com/szTheory/mailglass/commit/adaa0d7780e231e1aff2f34ed97c1371f7fc64a7))

## [Unreleased]

No unreleased changes yet.

## [1.0.0](https://github.com/szTheory/mailglass/compare/mailglass_inbound-v0.3.0...mailglass_inbound-v1.0.0) (2026-06-01)

### Adopter action required

- Upgrade to `{:mailglass_inbound, "~> 1.0"}` and keep sibling dependency posture unchanged (`{:mailglass, "== 1.3.0"}` for publish).
- Re-run release and contract checks in your release lane:
  - `mix verify.stability_contract`
  - `mix mailglass.publish.check --package mailglass_inbound`

### Behavior changes since 0.3.0

- `mailglass_inbound` moves from `0.3.0` to `1.0.0` after the inbound stability-lock proof lane was completed and verified.
- The release-position decision now records inbound as release-ready without widening feature scope or introducing new runtime APIs.

### Operator-impacting changes

- No new operator commands were introduced in this release.
- Existing `mailglass.inbound.doctor`, `mailglass.inbound.replay`, and `mailglass.inbound.prune` command semantics are unchanged.

### Compatibility posture and boundaries

- Stable runtime/testing/operator seams remain the same; this release is a version-line promotion backed by proof, not a feature expansion.
- Stable vs internal vs deferred contract truth is canonical in [`docs/api_stability.md`](docs/api_stability.md).
- Compatibility/deprecation lifecycle policy is canonical in [`../guides/compatibility-and-deprecations.md`](../guides/compatibility-and-deprecations.md).
- Stable boundaries: `MailglassInbound`, `InboundMessage`, ingress plug + body reader, router, mailbox contract, documented operator command semantics, telemetry families, and closed inbound error type sets.
- Internal boundaries: provider modules, replay/doctor/prune internals, worker/queue details, and UI implementation details remain non-contract.
- Deferred boundaries: no matcher expansion, lifecycle callbacks, public replay/provider APIs, worker/queue public contracts, synthetic UI, `gen_smtp` listener, or ecosystem integrations are promised by this release.

## [0.3.0](https://github.com/szTheory/mailglass/compare/mailglass_inbound-v0.2.0...mailglass_inbound-v0.3.0) (2026-05-28)


### Features

* **58-01:** implement webhook route proof helper ([67b0706](https://github.com/szTheory/mailglass/commit/67b0706efb8cc767ef0f2311208b2c8845d0c571))

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

## [0.1.1](https://github.com/szTheory/mailglass/compare/mailglass_inbound-v0.1.0...mailglass_inbound-v0.1.1) (2026-05-07)

### Miscellaneous Chores

* release 0.1.1 ([bfd001f](https://github.com/szTheory/mailglass/commit/bfd001fdf3a994de0da74b0091c1d60972c57605))

## [0.1.0](https://github.com/szTheory/mailglass/releases/tag/mailglass_inbound-v0.1.0) (2026-05-07)


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
* **release:** force 0.1.0 first publish for mailglass_inbound ([dd61b5c](https://github.com/szTheory/mailglass/commit/dd61b5cb2e7237422af697f7c774c7dfefad0c35))
