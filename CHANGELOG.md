# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Mailglass 1.0.0 bundles four shipped milestones (v0.5 + v0.6 + v1.0 + v1.1) into
the first stable release. If you ship on `~> 0.3`, read the
[bundle upgrade companion at `docs/upgrade-from-0.x.md`](docs/upgrade-from-0.x.md)
for the deep-dive walkthrough across all four milestones, then follow
[`guides/upgrading-to-v1_0.md`](guides/upgrading-to-v1_0.md) for the strict-CI
canonical migration steps. Sibling packages: `mailglass_admin` 1.0.0 (linked
release) and `mailglass_inbound` 0.1.0 (first Hex publish; separate 0.x
version line per [`guides/compatibility-and-deprecations.md`](guides/compatibility-and-deprecations.md)).

## [1.0.0](https://github.com/szTheory/mailglass/compare/mailglass-v0.3.2...mailglass-v1.0.0) (2026-05-07)


### Features

* **044.5-02:** add post-publish-smoke inbound parity (cron-guard version_inbound + 3 parallel jobs) ([2a36e93](https://github.com/szTheory/mailglass/commit/2a36e9326db4d5a51ce50a59e4d11dd0df6b682d))
* **044.5-02:** add publish-inbound job + all/mailglass_inbound enum to publish-hex.yml ([9083e16](https://github.com/szTheory/mailglass/commit/9083e1653ed73d6863a516b9c0eede9375efc956))
* **20-02:** add Mailglass.PublishError and register it in shared error contract ([79a9abd](https://github.com/szTheory/mailglass/commit/79a9abde8fbda9359ae43f08c73b22cb5deb3140))
* **22-01:** add operator delivery and timeline queries ([549cd2b](https://github.com/szTheory/mailglass/commit/549cd2b0985ebb2cc7c30e3621571087e09539b1))
* **22-01:** add operator suppression projection ([56b56b5](https://github.com/szTheory/mailglass/commit/56b56b5b0cc23b663862708a44dbf3e4c405f60f))
* **22-02:** add operator liveview shell ([f95cee5](https://github.com/szTheory/mailglass/commit/f95cee5401d58e7012de38f2fe2da008fa0613f8))
* **22-02:** build operator admin surface ([f8a120b](https://github.com/szTheory/mailglass/commit/f8a120b19c69feb5e11f6774ac70956fbe179ab8))
* **25-01:** add deliverability result contract ([85124e5](https://github.com/szTheory/mailglass/commit/85124e59f987f212836b552559d7bfbf753bdd14))
* **25-01:** add deliverability runtime and resolver seam ([e6eb695](https://github.com/szTheory/mailglass/commit/e6eb69590c9ff3c2437d5d3ca2082789aafab3f4))
* **25-02:** add DKIM and DMARC analyzers ([df2d6fd](https://github.com/szTheory/mailglass/commit/df2d6fd77077fb487b5601a2b6ac44c947abd17f))
* **25-02:** add SPF deliverability analyzer ([176adc6](https://github.com/szTheory/mailglass/commit/176adc613413deb661dbc73f7883d346cbebe548))
* **25-03:** add mx and bimi deliverability analyzers ([03dbee9](https://github.com/szTheory/mailglass/commit/03dbee9019965000a415eb63924bbb87144ceeb0))
* **25-03:** add shared deliverability formatter ([6f70fe9](https://github.com/szTheory/mailglass/commit/6f70fe9a2081f083897097b54ad2d071d5424f06))
* **25-04:** add mail doctor mix task ([719005b](https://github.com/szTheory/mailglass/commit/719005b2cd896279c889228ee938bfcfcc8b016f))
* **29-01:** add assigns to Message and Mailable API ([8bbbccf](https://github.com/szTheory/mailglass/commit/8bbbccf7e14aeaccd820dbaf5634039a21bb8e4a))
* **29-01:** extend TestAssertions with assigns and content matchers ([f61c7cb](https://github.com/szTheory/mailglass/commit/f61c7cbc9a5669a597b765b6259298e79b00eff0))
* **33-01:** align operator incident docs ([cd568d8](https://github.com/szTheory/mailglass/commit/cd568d871034905f00e85650ecf162e142869dfb))
* **33-02:** add tenant scoped support summary read model ([79f134f](https://github.com/szTheory/mailglass/commit/79f134fb0227b68141da68cdf5d0c22c9358c5fd))
* **33-03:** add operator support card surface ([1fd4bc3](https://github.com/szTheory/mailglass/commit/1fd4bc35e041225f041ac28bd3cf98223d4ae632))
* **33-03:** add support exemplar drilldowns ([8aa247c](https://github.com/szTheory/mailglass/commit/8aa247c1e3fdb7a4b7b8226ddff128dac3adb029))
* **37-01:** rewrite canonical testing guide ([ff60a04](https://github.com/szTheory/mailglass/commit/ff60a047cb7fa1d57f4bfc737af20be19903a2cd))
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
* add canonical webhook replay command ([6350cc8](https://github.com/szTheory/mailglass/commit/6350cc8f23e0ccc2ed9f79d94630b35745cdbdd3))
* add operator replay modal and liveview flow ([ba1ce0a](https://github.com/szTheory/mailglass/commit/ba1ce0af37e1ca625b511a87bb5a13088ebd6e00))
* add replay audit event contract and history read model ([2ca7cfb](https://github.com/szTheory/mailglass/commit/2ca7cfb5e5aa580f401a47960b29f32b0796d30c))
* add tenant-safe replay target resolver ([60840d5](https://github.com/szTheory/mailglass/commit/60840d575695ee4f244bc57dd8dae19618753505))
* **config:** add ses and resend configuration schemas ([efced13](https://github.com/szTheory/mailglass/commit/efced1321ae593d299fcdc97fb13fe1925b0e06f))
* persist replay linkage during webhook ingest ([653ca5d](https://github.com/szTheory/mailglass/commit/653ca5de9928afb63fdfb8bc873eae12b156f7ca))
* **phase-26:** add outbound adapter-ref contract ([445abfb](https://github.com/szTheory/mailglass/commit/445abfb74e6c242502c1f6455330d6312b9de2c6))
* **phase-26:** persist delivery adapter refs ([2c02d19](https://github.com/szTheory/mailglass/commit/2c02d19f3f7ef3b8ab7009091572ebde33169521))
* **phase-26:** route outbound delivery by adapter ref ([df827de](https://github.com/szTheory/mailglass/commit/df827dee4312e8294f46c9d7e06dc447c3b15603))


### Bug Fixes

* **044.5-01:** rewrite release-please.yml sync step to read core version directly ([eddebf7](https://github.com/szTheory/mailglass/commit/eddebf7f5c4c8e06bdc9cd010ff8e910f1d837cf))
* **044.5-04:** exclude glob entries from required-files missing report ([12002ea](https://github.com/szTheory/mailglass/commit/12002eacf41c66fc8fbb2a08676e048d2c406782))
* **19-01:** add :ses to ingest_multi/3 provider guard ([4152f47](https://github.com/szTheory/mailglass/commit/4152f47158d18fb43324329d485f6e191d1f1ddf))
* **19-01:** add derive_webhook_provider_event_id(:ses) clause ([76125c4](https://github.com/szTheory/mailglass/commit/76125c47db35011336dee9c2d021f2b403e0da9f))
* **22-03:** align admin liveview harness with root tests ([7089bc2](https://github.com/szTheory/mailglass/commit/7089bc2bb7cba0df70e9be83dac5a8a2d25d1807))
* **32-03:** align reconcile fallback docs and tests ([cabc145](https://github.com/szTheory/mailglass/commit/cabc14514f9486d6f115152e7430fae468fefedc))
* **32-03:** unify reconcile maintenance path ([f964dae](https://github.com/szTheory/mailglass/commit/f964dae5f079aab35f1faff6c3a7c9838dac3476))
* **33-02:** expose orphan backlog age ([1b57136](https://github.com/szTheory/mailglass/commit/1b57136181453035a59e2c341c1d713368ca3b75))
* **ci:** add workflow_dispatch trigger so PR head ref can run CI manually ([79c1c98](https://github.com/szTheory/mailglass/commit/79c1c98e9293870460272104f639957a4a195165))
* **ci:** apply Elixir 1.18 formatter rewrap across lib/ and test/ ([750e5ed](https://github.com/szTheory/mailglass/commit/750e5edad58ed69691ed5f8b4d66facf2075e7d4))
* **ci:** close 7 dialyzer warnings (5 fixed at source, 2 ignore-file added) ([e09c198](https://github.com/szTheory/mailglass/commit/e09c198034454f5b88f97c9b1c1b1c1938e65dfa))
* **ci:** create test DB for support_contract_admin lane ([27ce54e](https://github.com/szTheory/mailglass/commit/27ce54e672bddd37ad33d875c687d41727a361e4))
* **ci:** guard sibling MIX_PUBLISH steps in publish-hex.yml dry-run ([a0ba244](https://github.com/szTheory/mailglass/commit/a0ba244edd426d85c2525f2bd7c5dd7ff3215654))
* **ci:** make Operator Browser Gate advisory in publish-hex gate-ci-green ([5734c1b](https://github.com/szTheory/mailglass/commit/5734c1b172ddd1d95cda822330c42340ef12a371))
* **ci:** probe port binding + URL paths to diagnose operator_browser hang ([0a409c8](https://github.com/szTheory/mailglass/commit/0a409c8a04ee6123fa191e41dc990eade6a562bf))
* **ci:** satisfy Credo strict mode on publish.check + citext_probe ([1476305](https://github.com/szTheory/mailglass/commit/14763059072f1da6feef3b12d3f8f27090de7cac))
* **ci:** suppress 5 dialyzer warnings on result.ex + outbound_route test adapter ([fdcbb25](https://github.com/szTheory/mailglass/commit/fdcbb2521f9b153b68ee260bcc7048362f280d38))
* **ci:** surface operator_browser_gate stages + raise webServer timeout ([befbd02](https://github.com/szTheory/mailglass/commit/befbd0229ceb93c1ccb657681c11a10967f85166))
* **installer:** use false for swoosh api_client in generated config ([763be68](https://github.com/szTheory/mailglass/commit/763be685b982508d6daa021af6afd8a889b27924))
* **test:** force-load Reconciler before function_exported? probe ([9003cd5](https://github.com/szTheory/mailglass/commit/9003cd51f1460cbd017e7531e287f5fa86a05332))
* **test:** refresh stability + docs contract assertions for v1.0/1.1 ceremony ([f3a90b6](https://github.com/szTheory/mailglass/commit/f3a90b66d3053b6709eee51f920b0f837eaca17f))
* **test:** relax stability contract manifest assertion to SemVer pattern ([be8452a](https://github.com/szTheory/mailglass/commit/be8452a87b59edabfb1625a2fc3c9b90733022d9))


### Miscellaneous Chores

* **release:** force 0.1.0 first publish for mailglass_inbound ([dd61b5c](https://github.com/szTheory/mailglass/commit/dd61b5cb2e7237422af697f7c774c7dfefad0c35))
* **release:** force v1.0.0 cut for mailglass + mailglass_admin ([dfc457e](https://github.com/szTheory/mailglass/commit/dfc457ede56999a13c5caa47e0252b569e20fd6c))

## [0.3.2](https://github.com/szTheory/mailglass/compare/mailglass-v0.3.1...mailglass-v0.3.2) (2026-04-29)


### Bug Fixes

* **install:** normalize installer_version in golden snapshot ([#23](https://github.com/szTheory/mailglass/issues/23)) ([18fa5f6](https://github.com/szTheory/mailglass/commit/18fa5f62a2123029ba4ba277fe9f117492cbd5fd))

## [0.3.1](https://github.com/szTheory/mailglass/compare/mailglass-v0.3.0...mailglass-v0.3.1) (2026-04-29)


### Bug Fixes

* **dialyzer:** match SNS test-helper specs to success typing (CI test-env) ([#22](https://github.com/szTheory/mailglass/issues/22)) ([67f5961](https://github.com/szTheory/mailglass/commit/67f5961a5233649d2953594e33b4bf5738d3f5ab))
* **release:** unblock v0.3.1 CI for Hex publish ([#20](https://github.com/szTheory/mailglass/issues/20)) ([7269059](https://github.com/szTheory/mailglass/commit/726905976432b50d3349cd7b8a0d7941978a73f8))

## [0.3.0](https://github.com/szTheory/mailglass/compare/mailglass-v0.2.0...mailglass-v0.3.0) (2026-04-29)


### Features

* **14-01:** add resend webhook provider ([f97d2be](https://github.com/szTheory/mailglass/commit/f97d2be0479603f205a9a946ebd4751a82aea8ab))
* **15-01:** add mailgun replay cache supervision ([dfb0d16](https://github.com/szTheory/mailglass/commit/dfb0d165903b20eb28b8c4ec46c58b2ce6244442))
* **15-01:** allow replay-aware webhook verification ([395c9cb](https://github.com/szTheory/mailglass/commit/395c9cbb67b2b4ebbcc1e5a7eee88f978d0ea29f))
* **15-02:** finish mailgun provider test coverage ([1c6549d](https://github.com/szTheory/mailglass/commit/1c6549d02855d3281d15f0b5378042c0f3fe69a9))
* **15-02:** implement mailgun provider verification ([c52beac](https://github.com/szTheory/mailglass/commit/c52beacdf2a32b3dc81c899cf52cae1740368e59))
* **15-03:** add mailgun webhook test harness ([9639da0](https://github.com/szTheory/mailglass/commit/9639da06fff40d12e7b00f3686d8e74f5a475b4c))
* **15-03:** enable mailgun ingest runtime ([f7e8c18](https://github.com/szTheory/mailglass/commit/f7e8c18f8e7ae1d81f06ad5661e14f22e17b7953))
* **15-03:** wire mailgun into webhook runtime ([2cc9948](https://github.com/szTheory/mailglass/commit/2cc9948056328176e24d9704104e01c4993952d4))
* **16-02:** implement CertCache Supervisor and TableOwner ([11ba834](https://github.com/szTheory/mailglass/commit/11ba83469ccf19a5b92daf5b94b4b7cdd4c4854c))
* **16-02:** implement TrustPolicy and CertCache modules ([7bb099a](https://github.com/szTheory/mailglass/commit/7bb099a880744d3a7684eb06dce972356ea18b89))
* **16-03:** implement SES provider verify!/3 with SNS signature verification ([4093276](https://github.com/szTheory/mailglass/commit/4093276fec8784c700b2b8cbc84d93ec0e2dd6e8))
* **16-04:** implement normalize/2 in SES provider ([20df34f](https://github.com/szTheory/mailglass/commit/20df34f016896517c3d546bb6d0f08863c51773a))
* **16-04:** wire SES into plug, router, application, and webhooks guide ([3a3f3f9](https://github.com/szTheory/mailglass/commit/3a3f3f9917c6889d47653e10b59a914da2cf2018))
* **17-01:** add :resend lifecycle to WebhookCase ([396e940](https://github.com/szTheory/mailglass/commit/396e9406cedf01e1e140c2629338763074910eff))
* **17-01:** wire :resend into plug.ex and router.ex static dispatch ([eebf866](https://github.com/szTheory/mailglass/commit/eebf8661408d4259253050c1dcea88c6d6b2fab5))


### Bug Fixes

* **15-01:** keep mailgun test scaffolds warning-clean ([30ed9bd](https://github.com/szTheory/mailglass/commit/30ed9bd662d64104e3f8bf96f627432481e50775))
* **15:** enforce mailgun replay cache window ([31e5a85](https://github.com/szTheory/mailglass/commit/31e5a854250cf359ee0aea3933a66d77f999292e))
* **15:** harden mailgun replay claims ([043c293](https://github.com/szTheory/mailglass/commit/043c2939c31aec6415b39c5e194c0c2bbf6eee57))
* **16:** CR-01 add port guard to TrustPolicy to block SSRF via non-standard port ([87eed93](https://github.com/szTheory/mailglass/commit/87eed9329d8b0e233a7b93ddcc59cfaba385719a))
* **16:** CR-02 CR-03 safe base64 decode and explicit SignatureVersion case ([ecbc261](https://github.com/szTheory/mailglass/commit/ecbc2611fd61621dcfafa8f406e66d4707f855c6))
* **16:** WR-01 replace DateTime.utc_now() with Mailglass.Clock.utc_now() in tests ([079d312](https://github.com/szTheory/mailglass/commit/079d312dbe3b232f4ab6cb8deb00a3015de4ee23))
* **16:** WR-02 document intentional _email discard in build_event/8 ([d6b215d](https://github.com/szTheory/mailglass/commit/d6b215d17c97016c5e70099eb4b52ef6990e1e67))
* **16:** WR-03 document cache-miss stampede behavior in fetch_public_key!/2 ([813b7ce](https://github.com/szTheory/mailglass/commit/813b7ce8305557d5a9d472d769b6f874bf5f0122))
* **16:** WR-04 add :ses to provider type union in webhooks guide ([76d32ee](https://github.com/szTheory/mailglass/commit/76d32ee9e32c1ec0ff049a68622df447e61eb08e))
* **17-01:** fix async race and update plug_test :resend assertion ([f65a7ee](https://github.com/szTheory/mailglass/commit/f65a7ee98c99a5e76345b7b8dbcf9aacdaaf8d74))
* **ci:** add postgres service to prepublish-summary job ([33efe73](https://github.com/szTheory/mailglass/commit/33efe73e354f395e1a014a506f1f2a42e4c4780c))
* **ci:** satisfy release branch quality gates ([153c9f7](https://github.com/szTheory/mailglass/commit/153c9f7a2e1c668f9d6382737b2730955612ea84))
* **ci:** satisfy workflow shellcheck ([f5b66cd](https://github.com/szTheory/mailglass/commit/f5b66cd14661e32d35bc2b4966efa233885f9590))
* **release:** recover sibling publish validation ([db5f06f](https://github.com/szTheory/mailglass/commit/db5f06f838a9ac38636b3975fd509e9a1cae74d6))
* resolve add/add conflict in cert_cache_test.exs (use Clock.utc_now, keep multi-URL test) ([2d770a0](https://github.com/szTheory/mailglass/commit/2d770a05ffe55bbaafc62ea82396f589e18d9c0d))

## [0.2.0](https://github.com/szTheory/mailglass/compare/mailglass-v0.1.1...mailglass-v0.2.0) (2026-04-28)

Mailglass 0.2.0 is the release that turns the first adopter-facing mailable API,
deliverability floor, and migration path into a public contract. If you already
ship on `~> 0.1`, read this entry first, then use
[`guides/upgrading-from-v0_1.md`](guides/upgrading-from-v0_1.md) for the full
walkthrough and examples.

### Breaking Changes

- `use Mailglass.Mailable` now expects native `Mailglass.Message` setters in
  mailables. The supported builder surface is `to/2`, `from/2`, `subject/2`,
  `text_body/2`, `html_body/2`, `header/3`, `attach/2`, and `put_tag/2`.
- `Swoosh.Email.attachment/2` is renamed to `attach/2` on
  `Mailglass.Message`.
- Direct `Swoosh.Email.*` calls are no longer the default authoring API. Keep
  provider-specific or uncommon Swoosh mutations behind
  `Mailglass.Message.update_swoosh/2`.

### Exact Upgrade Path

1. Update your dependencies to `{:mailglass, "~> 0.2"}` and, if you will run
   the codemod, `{:igniter, "~> 0.7", only: [:dev, :test]}`.
2. Run `mix deps.get`.
3. Run `mix mailglass.upgrade.v0_2` first to inspect the dry-run diff. Re-run
   with `mix mailglass.upgrade.v0_2 --apply` once the changes look correct.
4. Recompile and run your normal test suite.
5. Use [`guides/upgrading-from-v0_1.md`](guides/upgrading-from-v0_1.md) for
   the full before/after examples and manual follow-up checklist.

### Dependency / Runtime Floor

- Elixir `~> 1.18`
- OTP 27+
- Phoenix `~> 1.8`
- Phoenix LiveView `~> 1.1`
- Phoenix HTML `~> 4.1`
- Igniter `~> 0.7` when running `mix mailglass.upgrade.v0_2`

### Ambiguous Swoosh Usage and Escape Hatch

- `mix mailglass.upgrade.v0_2` rewrites only the eight known
  `Swoosh.Email` setters listed above.
- Unknown `Swoosh.Email.*` calls are left in place and emit `IO.warn`; the
  task does not silently guess at a rewrite for ambiguous cases.
- Keep advanced provider-specific behavior by wrapping it in
  `Mailglass.Message.update_swoosh/2`. The upgrade guide includes the expected
  pattern for `put_provider_option/3` and similar calls.

### Rollback

- Treat the upgrade task as a git-clean operation. Run it from a disposable
  branch, worktree, or otherwise clean working tree so `git diff` tells you
  exactly what changed.
- If the codemod output is not what you want, discard the upgrade diff with
  `git restore .` (or `git checkout .` if that is still your local workflow)
  and review the guide before trying again.
- Mailglass does not promise cleanup of unrelated local edits in a dirty
  working tree.

### Immediate Behavior Changes

- The public mailable API now lives on `Mailglass.Message`, with
  `Mailglass.Message.update_swoosh/2` as the documented escape hatch instead
  of direct `Swoosh.Email` builder chains.
- Stream policy is now enforced across `:transactional`, `:operational`, and
  `:bulk`, so invalid or drifted stream usage fails early instead of silently
  shipping.
- RFC 8058 unsubscribe support is now first-class: config, routes, GET/POST
  behavior, DKIM rollout guidance, and replay-safe one-click semantics are part
  of the supported contract.
- Webhook-driven suppression is now load-bearing. Complaints remain durable
  compliance blocks, and bounce/complaint/unsubscribe events feed the
  suppression surface instead of staying advisory-only.

### Added

- `mix mailglass.upgrade.v0_2`, an Igniter-powered codemod for the standard
  `Swoosh.Email` setter migration path.
- RFC 8058 one-click unsubscribe support, including router mounts, a read-only
  generator, replay-safe POST handling, and DKIM verification guidance.
- Webhook-driven suppression automation, including complaint/unsubscribe
  projection and soft-bounce escalation into the same suppression surface.

### Changed

- `Mailglass.Mailable` now imports the native `Mailglass.Message` authoring
  surface instead of asking adopters to build mailables around raw
  `Swoosh.Email` calls.
- Stream policy enforcement now spans compile-time guidance, runtime checks,
  and the public docs contract for `:transactional`, `:operational`, and
  `:bulk` mail.
- The upgrade guide is now the deep dive for `~> 0.1` adopters, while this
  changelog entry acts as the release-day migration front door.

### Fixed

- Ambiguous `Swoosh.Email` migrations now fail safely by warning and preserving
  the original call site instead of implying automatic support that does not
  exist.
- Unsubscribe replay handling and suppression projection now converge on
  idempotent outcomes that are safer to operate at release time.

## [0.1.1](https://github.com/szTheory/mailglass/compare/mailglass-v0.1.0...mailglass-v0.1.1) (2026-04-26)


### Features

* **installer:** match real Phoenix router anchor + Swoosh Finch default ([cf287f9](https://github.com/szTheory/mailglass/commit/cf287f972cc70138205762a3a3528ba2f7bb4c3a))


### Bug Fixes

* **post-publish-smoke:** add hackney to sandbox deps for Swoosh ([9482a60](https://github.com/szTheory/mailglass/commit/9482a607a828fb5b5b8ed2b5e45c309ed837e12a))
* **post-publish-smoke:** drop --yes from mix mailglass.install ([17188b0](https://github.com/szTheory/mailglass/commit/17188b094656a192c48e6ad764e9293e08e97601))
* **post-publish-smoke:** list cron-guard as direct needs of all downstream jobs ([b636648](https://github.com/szTheory/mailglass/commit/b6366482837c94f62071aaab16265aa92f747cdb))
* **post-publish-smoke:** use --force on install (v0.1.0 anchor workaround) ([33f1212](https://github.com/szTheory/mailglass/commit/33f1212d09a89ee660c78d3903a6b5fb9f1b1933))
* **release-please:** bump mailglass_admin -&gt; mailglass dep pin on every release ([eb0370f](https://github.com/szTheory/mailglass/commit/eb0370ff464d2711275b3ad8386e2be81aed38a7))
* **release-please:** move x-release-please-version annotation onto its own line ([e0b1edb](https://github.com/szTheory/mailglass/commit/e0b1edbbdfd0b2458fad1bf09987b73d141d6a21))
* **release-please:** sync mailglass_admin -&gt; mailglass dep pin via workflow sed ([9fc4009](https://github.com/szTheory/mailglass/commit/9fc40093e8844ce59bb518e153b85382913dc17d))


### Miscellaneous Chores

* release 0.1.1 ([bfd001f](https://github.com/szTheory/mailglass/commit/bfd001fdf3a994de0da74b0091c1d60972c57605))

## 0.1.0 (2026-04-26)


### Features

* **01-01:** add Application, facade, and Wave 0 test stubs ([4d7f2e8](https://github.com/szTheory/mailglass/commit/4d7f2e83aeb7f8923ca1c7175a7f71f24eba8853))
* **01-02:** add Mailglass.Error namespace + six defexception modules ([0d0ca21](https://github.com/szTheory/mailglass/commit/0d0ca2121f2d8d0b236c4d94f74a714ddd703acc))
* **01-03:** add Mailglass.Config + Mailglass.Telemetry ([0f5d86d](https://github.com/szTheory/mailglass/commit/0f5d86d0ff5ad5b6b08408dc23ffead8b88e7d74))
* **01-03:** add Mailglass.Repo + Mailglass.IdempotencyKey ([4b40ea8](https://github.com/szTheory/mailglass/commit/4b40ea851a59d5dcac011fe8ba3a9b2c7f00008e))
* **01-04:** add Mailglass.Message struct wrapping Swoosh.Email ([68dba9a](https://github.com/szTheory/mailglass/commit/68dba9ab37510c5e28de1f1bcaf095d9c31e7924))
* **01-04:** add Mailglass.OptionalDeps namespace + five gateway modules ([0da97ed](https://github.com/szTheory/mailglass/commit/0da97ed850cfdcb7fa8b0fd8987ac4f5c3946d89))
* **01-05:** add Mailglass.Components HEEx library (11 components) + tests ([0a273c5](https://github.com/szTheory/mailglass/commit/0a273c5cb565d4d992ac1761f2358016adb9b336))
* **01-05:** add Mailglass.Components Theme/CSS/Layout helper modules ([9b91399](https://github.com/szTheory/mailglass/commit/9b91399b85d02fa6888a0297e9cc84303a290870))
* **01-06:** add Renderer pipeline + Compliance headers + de-skip 3 test files ([514617a](https://github.com/szTheory/mailglass/commit/514617a0c76ad29efaee06251787b427f78d0ced))
* **01-06:** add TemplateEngine behaviour + HEEx impl + Gettext backend ([79f6f27](https://github.com/szTheory/mailglass/commit/79f6f27a0a03dae1bbdd397c491911580c3d08be))
* **02-01:** activate SQLSTATE 45A01 translation and add persist telemetry spans ([c82fffa](https://github.com/szTheory/mailglass/commit/c82fffad4cee1b2ce1d6e41d1fa4199a98aa5b7c))
* **02-01:** add TestRepo, DataCase, Generators, config/test.exs DB wiring ([b058da7](https://github.com/szTheory/mailglass/commit/b058da75dc8565a44395485b86a882243a937648))
* **02-01:** scaffold Schema macro, EventLedger/Tenancy errors, :uuidv7 dep ([6859034](https://github.com/szTheory/mailglass/commit/68590343cb21e130d455d06e10fa17f9cb7b153b))
* **02-02:** add Migration public API + Postgres dispatcher + V01 DDL ([627b925](https://github.com/szTheory/mailglass/commit/627b925c3c343919fbc7f59f1d01192e4de72197))
* **02-02:** wire test_helper migration runner + integration tests ([0e7a6b8](https://github.com/szTheory/mailglass/commit/0e7a6b817a4a2ebd20eaa2f99dd62e882f8317c9))
* **02-03:** add Delivery + Event Ecto schemas with closed-atom-set reflectors ([96d6b6a](https://github.com/szTheory/mailglass/commit/96d6b6a8fee73437fd09b21c1962f4cc54707198))
* **02-03:** add Suppression.Entry schema with scope/stream coupling ([4c1eb05](https://github.com/szTheory/mailglass/commit/4c1eb0525e49c6ef70ec7ca0354da7ee50328578))
* **02-04:** add Mailglass.Oban.TenancyMiddleware (conditionally compiled) ([6588874](https://github.com/szTheory/mailglass/commit/6588874fa032e9ebb695d0d633d1506f93ddd9f2))
* **02-04:** add Mailglass.Tenancy behaviour + SingleTenant default + DataCase upgrade ([c26f3b2](https://github.com/szTheory/mailglass/commit/c26f3b274992d8635bcc2dacea9c67985df27512))
* **02-05:** add Mailglass.Events.Reconciler find_orphans + attempt_link ([960d0da](https://github.com/szTheory/mailglass/commit/960d0da8efb30e7955debcf68ad869fbe8d41731))
* **02-06:** add Mailglass.Outbound.Projector monotonic D-15 + optimistic_lock D-18 ([85e00cf](https://github.com/szTheory/mailglass/commit/85e00cfae414e07de42a51570d378a2b3d07fff6))
* **02-06:** add Mailglass.SuppressionStore behaviour + Ecto default impl ([795ffd7](https://github.com/szTheory/mailglass/commit/795ffd7c9d994c74e7ad92dbd9fc59e9b16572d9))
* **03-01:** Clock module + Frozen + System + Tenancy.assert_stamped! + api_stability extensions ([3b1a82a](https://github.com/szTheory/mailglass/commit/3b1a82a1cc6bf38e4cc9778864726f4457829d8f))
* **03-01:** PubSub.Topics + BatchFailed + ConfigError atoms + Message.mailable_function + put_metadata/3 ([13de495](https://github.com/szTheory/mailglass/commit/13de495a0f8906e3785aa4971c2e8efa0bafc9ef))
* **03-01:** Telemetry spans + Application supervision tree + Config schema + Repo.multi + Events.append_multi fn-form + mix alias + Wave 0 fixtures ([8a46cd7](https://github.com/szTheory/mailglass/commit/8a46cd746ab43f0146ca141d50ef0d509a10184f))
* **03-02:** Fake adapter + Storage GenServer + Supervisor + Projector broadcast ([e3a6288](https://github.com/szTheory/mailglass/commit/e3a6288858aaf112b712ba1755067672c39f8692))
* **03-02:** Mailglass.Adapter behaviour + Adapters.Swoosh wrapper ([e956fca](https://github.com/szTheory/mailglass/commit/e956fca7ae836701fe322fc9bdec1bdc0a25a068))
* **03-03:** Mailglass.Stream no-op policy_check seam (D-25) ([33e0fc9](https://github.com/szTheory/mailglass/commit/33e0fc9771f59c63d834263f5887a0b48c8c7839))
* **03-03:** RateLimiter + Supervisor + TableOwner — supervisor-owned ETS token bucket ([c04a7c8](https://github.com/szTheory/mailglass/commit/c04a7c8cb690c5150bcc819c9c15f78df9d96498))
* **03-03:** Suppression facade + SuppressionStore.ETS + Supervisor + TableOwner ([05d7b06](https://github.com/szTheory/mailglass/commit/05d7b0602c307b357e10f58299eead95837ce918))
* **03-04:** Mailglass.Mailable behaviour + __using__ macro + [@before](https://github.com/before)_compile ([074a28c](https://github.com/szTheory/mailglass/commit/074a28c5677d6dcf30326b9eae3da5d1d8fff7ea))
* **03-04:** Tracking facade + Guard auth-stream runtime enforcement (TRACK-01, D-38) ([dc932ea](https://github.com/szTheory/mailglass/commit/dc932ea605a540aa534783c63eb6d230d986ddd5))
* **03-05:** deliver_later/2 + Oban Worker + Task.Supervisor fallback ([1d0a407](https://github.com/szTheory/mailglass/commit/1d0a40709b4b4fe516484d35143a5555f3f13ca5))
* **03-05:** deliver_many/2 + deliver_many!/2 + batch idempotency-replay ([c06fc24](https://github.com/szTheory/mailglass/commit/c06fc24652aabaa49caa2c638a1981e6483f4772))
* **03-05:** Mailglass.Outbound facade — send/2, deliver/2, dispatch_by_id, top-level defdelegates ([6ecf721](https://github.com/szTheory/mailglass/commit/6ecf721d6327aeaf3a1787f3673b8f0f540b8ffc))
* **03-05:** migration + Delivery schema — idempotency_key, status, last_error ([b29df5c](https://github.com/szTheory/mailglass/commit/b29df5c685cffdc116f8ad4e4f3a6bd3d9620bc9))
* **03-06:** core_send_integration_test.exs — Phase 3 UAT gate (5 ROADMAP criteria) ([2ad4c78](https://github.com/szTheory/mailglass/commit/2ad4c78113dbc529648d21c5704b641dd0ebb6c1))
* **03-06:** MailerCase + WebhookCase + AdminCase test support (TEST-02) ([b1c1369](https://github.com/szTheory/mailglass/commit/b1c1369c9fcea866a36f15db7bd8c65b064ad223))
* **03-06:** Mailglass.TestAssertions — 4 matcher styles + PubSub-backed assertions ([329baf5](https://github.com/szTheory/mailglass/commit/329baf5cfc6108703d66ed2fd23f20e20313666c))
* **03-07:** Mailglass.Tracking.Plug + ConfigValidator + api_stability sections ([8c593a8](https://github.com/szTheory/mailglass/commit/8c593a851f7161b3992898b3f3d0b63f9d84abe0))
* **03-07:** Mailglass.Tracking.Rewriter + rewrite_if_enabled facade patch ([a5e016e](https://github.com/szTheory/mailglass/commit/a5e016ec5a0b129a2fc49146c0fc499ff6704bb5))
* **03-07:** Mailglass.Tracking.Token — sign/verify open+click with salts rotation ([828998c](https://github.com/szTheory/mailglass/commit/828998cdb6a0cc881fdd3cfe5690e37d54fcf202))
* **03-08:** wire Tracking.rewrite_if_enabled/1 into Outbound pipeline (TRACK-03) ([979f8e0](https://github.com/szTheory/mailglass/commit/979f8e05f56a97840232cef0f01e658529f9d300))
* **03-09:** add :adapter_endpoint end-to-end test in rewriter_test (HI-02 closed) ([28f6fb9](https://github.com/szTheory/mailglass/commit/28f6fb98a5484072e77533e033f1f84777b95f23))
* **03-09:** Tracking.endpoint/0 — single endpoint resolution (HI-02 fix) ([01b5279](https://github.com/szTheory/mailglass/commit/01b52798aa65a15a03dd90d80c6a8f45486d0480))
* **03-10:** add ObanHelpers and wire maybe_create_oban_jobs in test_helper ([7b482f9](https://github.com/szTheory/mailglass/commit/7b482f972fed8fcab3738aa5fc8d60ea638c0750))
* **04-01:** Wave 0 foundations — V02 migration, Repo.query!/2, :reconciled, verify.phase_04 ([54aced9](https://github.com/szTheory/mailglass/commit/54aced931b0eb69e10a368b8f3f177209e411b1f))
* **04-01:** WebhookFixtures + WebhookCase helpers + 7 fixture JSONs + api_stability §Webhook scaffolding ([6bcbcd5](https://github.com/szTheory/mailglass/commit/6bcbcd5992d7121586a3d20c179b78e0f48c6c0d))
* **04-02:** extend SignatureError + ConfigError atom sets for webhook ingest ([140a635](https://github.com/szTheory/mailglass/commit/140a635832a3b0d55d29f5624f57db8d20007e84))
* **04-02:** Postmark webhook provider + :postmark NimbleOptions sub-tree ([0aa3681](https://github.com/szTheory/mailglass/commit/0aa368164044d8388c54cf0bf896f5dd84bf8726))
* **04-02:** Webhook.Provider behaviour + CachingBodyReader with iodata accumulation ([e944967](https://github.com/szTheory/mailglass/commit/e94496718781836ddd08a25ce7a0e63e2e7898d1))
* **04-03:** SendGrid ECDSA verifier + Anymail normalizer + :sendgrid config ([f3c48e5](https://github.com/szTheory/mailglass/commit/f3c48e51b87d586ee4386b199e7d194358b0679d))
* **04-03:** SendGrid provider test suite — verify!/3 + normalize/2 ([996510a](https://github.com/szTheory/mailglass/commit/996510ab34e980a3c9aa1d00a181d49b8a558d60))
* **04-04:** Webhook.Plug single-ingress orchestrator + TenancyError atom ([de5ec28](https://github.com/szTheory/mailglass/commit/de5ec286450ef8280f8306010711e4c764fe8429))
* **04-05:** formalize Tenancy.resolve_webhook_tenant/1 + ResolveFromPath sugar ([5262142](https://github.com/szTheory/mailglass/commit/5262142c000d2e0c43f68a42b865f4b4b45a6475))
* **04-05:** Mailglass.Webhook.Router macro for provider-per-path POST routes ([ee33368](https://github.com/szTheory/mailglass/commit/ee33368321be4b29be8576164e03127460e232b7))
* **04-06:** Mailglass.Webhook.Ingest.ingest_multi/3 heart of HOOK-06 ([4daa121](https://github.com/szTheory/mailglass/commit/4daa12124ddc45d0826dbbaa25edf3c77481c531))
* **04-06:** WebhookEvent schema + IdempotencyKey arity-3 form ([c6b19d7](https://github.com/szTheory/mailglass/commit/c6b19d73b3d61f1b388d362579042db283bbce7b))
* **04-07:** Mailglass.Webhook.Pruner Oban worker + :webhook_retention config ([5f342e2](https://github.com/szTheory/mailglass/commit/5f342e24399b86de7aed67bea88cde32c9b3b768))
* **04-07:** Mailglass.Webhook.Reconciler Oban worker + mix task fallback ([1a6d9f9](https://github.com/szTheory/mailglass/commit/1a6d9f992edfdd01ff3b9247ae0824e089920730))
* **04-08:** Mailglass.Webhook.Telemetry — 6 named span helpers ([f35e898](https://github.com/szTheory/mailglass/commit/f35e89809cc4fa03186e614e2e7cfb208c252bf4))
* **04-09:** Phase 4 UAT integration test + guides/webhooks.md ([5a673d7](https://github.com/szTheory/mailglass/commit/5a673d77e5864771a47b8ef8ef86641dbbf4a45c))
* **05-02:** land mailglass_admin config + root module + package docs ([ce08709](https://github.com/szTheory/mailglass/commit/ce087099a8d7e0bc2f1206b5bb057ac304838512))
* **05-02:** scaffold mailglass_admin mix.exs + .formatter + .gitignore ([74e2021](https://github.com/szTheory/mailglass/commit/74e202175504a9da25671c062163a80af5c10b3c))
* **05-03:** add MailglassAdmin.PubSub.Topics + Layouts supporting deps ([134fe51](https://github.com/szTheory/mailglass/commit/134fe51617232bc81ebe2fb1f5cd9774104021cd))
* **05-03:** ship mailglass_admin_routes/2 macro + __session__/2 whitelist ([65be3a0](https://github.com/szTheory/mailglass/commit/65be3a08eed7241e099a431e09fce860ad94d4f6))
* **05-04:** add MailglassAdmin.Preview.Discovery with graceful failure ([f232393](https://github.com/szTheory/mailglass/commit/f232393c1e505011d04d47d99ec1028427ad6f71))
* **05-04:** add MailglassAdmin.Preview.Mount on_mount hook ([6a2c1ca](https://github.com/szTheory/mailglass/commit/6a2c1ca8ff3d78626c74abd02507be2e45b9c893))
* **05-05:** add three mailglass_admin mix tasks (assets.build/watch/daisyui.update) ([9eb7186](https://github.com/szTheory/mailglass/commit/9eb71864839cb1e931635e367aaa4289e961fdef))
* **05-05:** vendor daisyUI + subset fonts + place logo + author app.css ([2da151b](https://github.com/szTheory/mailglass/commit/2da151b4415835d2ac8dab0e6160d5047b241610))
* **05-06:** add four preview function components (sidebar/tabs/device_frame/assigns_form) ([94067e0](https://github.com/szTheory/mailglass/commit/94067e0d0b7ae793d82f097d2a05ba06f5e836dd))
* **05-06:** add PhoenixLiveReload gateway + shared UI atoms (Components) ([09bb359](https://github.com/szTheory/mailglass/commit/09bb35903a8a4fcb40382f0dfa480c2dc317415f))
* **05-06:** ship MailglassAdmin.PreviewLive + Rule 1-3 supporting fixes ([474e34e](https://github.com/szTheory/mailglass/commit/474e34e123070da2f54e07c4bbe828dca58ae4cf))
* **06-01:** add proven custom Credo checks ([c42cbd6](https://github.com/szTheory/mailglass/commit/c42cbd6a624b46eb00be811308f382fe307e120d))
* **06-02:** add remaining custom Credo boundary checks ([6bf8fc7](https://github.com/szTheory/mailglass/commit/6bf8fc7700fc21243e8fe4581278adb0d795cd5c))
* **06-03:** enforce tenant-scope and auth-tracking lint guards ([228b8b7](https://github.com/szTheory/mailglass/commit/228b8b7fad2093c0004e3f00afd6ed78c7c4ffda))
* **06-04:** enforce boundary DAG for core modules ([854faee](https://github.com/szTheory/mailglass/commit/854faee20cf8272dfff2a5037e63ede5535f91ad))
* **06-05:** wire custom Credo checks into config and CI ([230cf39](https://github.com/szTheory/mailglass/commit/230cf39b756a071da7d75ff887ae6757399b7d46))
* **07-01:** ship installer engine and mix mailglass.install ([24a0f2b](https://github.com/szTheory/mailglass/commit/24a0f2ba3a90ba2d16a23904cbfc8cb49f0f9400))
* **07-02:** add installer golden + idempotency + smoke tests ([ed37674](https://github.com/szTheory/mailglass/commit/ed37674f864333b64e1995d7f40beec349c74d40))
* **07-03:** land docs spine, guides, governance, and contract tests ([5f8d7f4](https://github.com/szTheory/mailglass/commit/5f8d7f4a8499815ffa7388519abaed4c16e0ba51))
* **07-04:** split CI workflows, advisory matrix, supply-chain checks ([c901c31](https://github.com/szTheory/mailglass/commit/c901c3179a506fa64c87c035ff6c72457d54c20f))
* **07-05:** release-please linked versions, protected hex publish ([0e767dd](https://github.com/szTheory/mailglass/commit/0e767ddda483928df842e76b9e94daccef52a82f))
* **phase-04:** add 9 webhook-ingest plans across 5 waves ([8e66ca2](https://github.com/szTheory/mailglass/commit/8e66ca24ed9002a755949b8b76de434984812f05))


### Bug Fixes

* **02:** IN-01 wrap Reconciler.attempt_link in persist_span and drop unused opts ([5bdd3c8](https://github.com/szTheory/mailglass/commit/5bdd3c8996c4d4a8a2bdf6458e92c883a316fb96))
* **02:** IN-02 disambiguate property-test idempotency_key by type ([dd833b6](https://github.com/szTheory/mailglass/commit/dd833b603b9b91dee216e4fab609c7b06e452009))
* **02:** IN-03 document EventLedgerImmutableError translator asymmetry ([a4a0707](https://github.com/szTheory/mailglass/commit/a4a07077f6ea99928bcbc0026f9ad65c354e5c4d))
* **02:** IN-04 add explicit ArgumentError guard for non-binary tenant_id ([c513e8f](https://github.com/szTheory/mailglass/commit/c513e8f70efab3109c81da2f6f43ef20bfcc4863))
* **02:** IN-05 update Mailglass.Error moduledoc to list all eight error types ([6abc242](https://github.com/szTheory/mailglass/commit/6abc24245162ca7a9e0ed8b6f85203431422d1e1))
* **02:** IN-06 replace D-09 cross-ref with inline retry-policy summary ([e0b0f54](https://github.com/szTheory/mailglass/commit/e0b0f54e9ced47a4b1779e2fae5ceeec9a6a337c))
* **02:** IN-07 document :rejected/:failed terminal-without-timestamp asymmetry ([af401de](https://github.com/szTheory/mailglass/commit/af401de778ece7aa6b531e1b15275b3117f382b5))
* **02:** IN-08 compose suppression scope/stream error messages per brand voice ([1bf2a6b](https://github.com/szTheory/mailglass/commit/1bf2a6bcf8257b66c9e1131d5609182122599f39))
* **02:** WR-01 close SQL injection vector in migrated_version/1 ([4947fe9](https://github.com/szTheory/mailglass/commit/4947fe9d55c3d68da9728562133d2073b864b69c))
* **02:** WR-02 advance last_event_at + last_event_type together ([41fd242](https://github.com/szTheory/mailglass/commit/41fd242c7f0cb426164255dd303da41f55878621))
* **02:** WR-03 return {:error, :invalid_key} on malformed check/2 input ([735065f](https://github.com/szTheory/mailglass/commit/735065f834b7f840c38006c95a31ca8e51ac7de9))
* **02:** WR-04 validate repo adapter at boot, not on first write ([452b0e2](https://github.com/szTheory/mailglass/commit/452b0e289b5359463192b92cef1ef971be9bebad))
* **03-05:** use {:shared, self()} sandbox mode in async delivery tests ([c8c2a7e](https://github.com/szTheory/mailglass/commit/c8c2a7e52f5085f775ce02776e32728806692df9))
* **03-10:** guard async_adapter mutation and fix on_exit restore in MailerCase (HI-01) ([6567d3e](https://github.com/szTheory/mailglass/commit/6567d3eea0ace2f9d55261a71c46040028ec7973))
* **03-11:** eliminate citext OID cache flake — zero cache lookup failed errors ([4fab4ba](https://github.com/szTheory/mailglass/commit/4fab4bad31ebf38f986cf7ff6da413c2a3fb3a2b))
* **03-12:** ME-01 use Clock.utc_now in Events.normalize and ME-02 simplify BatchFailed.format_message ([e9fb86f](https://github.com/szTheory/mailglass/commit/e9fb86f80ac961e310a46b612f3268becf7edf65))
* **03-12:** ME-03 rehydrate_message uses String.to_existing_atom on both resolution paths ([745cad4](https://github.com/szTheory/mailglass/commit/745cad4f21bb15da49f2ef70a9bee18a5b8884b0))
* **03-12:** ME-04 safe_broadcast catches :exit and ME-05 provider_tag safe pattern match ([1d7c9bb](https://github.com/szTheory/mailglass/commit/1d7c9bb327f6158f01aed60a2648b6b38ad60795))
* **04-01:** remove `:raw_payload` from ledger schema + callers after V02 drop ([2ea1e74](https://github.com/szTheory/mailglass/commit/2ea1e7443dc51f6690de6f2e9d9dd2c0b1910268))
* **04-03:** skip redundant EcpkParameters der_decode on OTP 27 ([9ab8bcc](https://github.com/szTheory/mailglass/commit/9ab8bcc386f3c7d87516fb27273e62935636fb8c))
* **04-04:** use :telemetry.span/3 directly in Plug.call/2 for per-request stop metadata ([4dcb29a](https://github.com/szTheory/mailglass/commit/4dcb29a43295777f809765ddc54ae33f0a49e6d0))
* **06-05:** close custom Credo bypass regressions ([e82325e](https://github.com/szTheory/mailglass/commit/e82325e9a20d251442ee8286442774867f706cff))
* **07.1-06:** drive installer fixtures through real Apply.run/2 ([b53a7b2](https://github.com/szTheory/mailglass/commit/b53a7b25a3bd0181be44d2da121b84364c82136f))
* **07.1-06:** emit the adopter admin router mount snippet ([70e69f0](https://github.com/szTheory/mailglass/commit/70e69f054f0e1741827d2744c284f1d3237e9a1f))
* **07.1-06:** wire webhook installer ops and migration generator ([b247187](https://github.com/szTheory/mailglass/commit/b24718758e9c2ab064dcfb6736bfa8e000bbe5c5))
* **07.1-07:** expand prepublish check ([ce2f3cf](https://github.com/szTheory/mailglass/commit/ce2f3cfb4f468a08c18a232c2929037ffa39f6a2))
* **07.1-08:** harden Hex publish workflow and package check support ([fa423da](https://github.com/szTheory/mailglass/commit/fa423daaece30d54b65c2ab53d6c41bf8ee37298))
* **07.1-10:** reset release-please bootstrap state for v0.1.0 PR ([3a19b43](https://github.com/szTheory/mailglass/commit/3a19b438f8075aa9bf3bbac78b9ee71c918b5709))
* **ci:** correct release-please pin and gate publish-hex jobs against bad triggers ([70d0306](https://github.com/szTheory/mailglass/commit/70d0306bfb45029bfacc37b209c9bbac437f34c8))
* **ci:** mark Tests gate advisory for v0.1.0 publish ([f4050a1](https://github.com/szTheory/mailglass/commit/f4050a13d72798b5bff01d09447f959512ec2a1e))
* **ci:** pin credo to --min-priority=high so v0.1.0 lower-priority noise doesn't gate publish ([8ab6c1f](https://github.com/szTheory/mailglass/commit/8ab6c1fe3cae2cb74e0b8316de877eaf18d359e4))
* **ci:** set credo strict: false in config to honor workflow change ([e3013d3](https://github.com/szTheory/mailglass/commit/e3013d36e553860e6d79a2b40228a586bae38550))
* **ci:** suppress transitive optional-dep warnings and ratchet credo ([f697d2d](https://github.com/szTheory/mailglass/commit/f697d2d34d23ba9eb07ef56ff23581cd9fa95618))
* **ci:** unblock docs and admin smoke gates ([e72c854](https://github.com/szTheory/mailglass/commit/e72c854f965b98fd87efb1a25a30f0311a703d3e))
* **ci:** unblock format, no-optional-deps, and credo gates ([fb4ee3c](https://github.com/szTheory/mailglass/commit/fb4ee3c86d562db6a3d0c936e0878f80bd46dfd0))
* **ci:** wait-for-postgres + create test DB + advisory credo ([544c566](https://github.com/szTheory/mailglass/commit/544c56609f456172d392dd1b92593df677c542ee))
* correct [@source](https://github.com/source)_url to szTheory/mailglass ([7553cfb](https://github.com/szTheory/mailglass/commit/7553cfb9f822f5ce1986c5959bb6d848630e6984))
* **installer:** detect host OTP app from mix.exs to substitute paths ([02df2f8](https://github.com/szTheory/mailglass/commit/02df2f8c46c48c90fdfc18378a61093250618089))
* move credo checks from lib/ to credo_checks/ to prevent path-dep compile failure ([7cdf7b1](https://github.com/szTheory/mailglass/commit/7cdf7b17f1fa8bd94ee65f477a6c12de8ea2c421))
* **phase-04:** apply checker revisions to plans 02-09 ([a77ef7f](https://github.com/szTheory/mailglass/commit/a77ef7f6498f7efcc12b6ee0e25861334d9bd207))
* **phase-04:** final revision — orphan flag + Tenancy.clear cleanup ([c29bb3e](https://github.com/szTheory/mailglass/commit/c29bb3ed021931e160e4ee4d5f8ce926fab67b05))
* **sendgrid:** handle public_key ≤1.16 ecc_params raw-DER shape ([edb2ab8](https://github.com/szTheory/mailglass/commit/edb2ab8d5a45dee5fd4b415c1d3f6ef1fa3b9731))
* suppress Oban.Migrations undefined warning in no-optional-deps lane ([eda647d](https://github.com/szTheory/mailglass/commit/eda647de4da4ee39337bbabf13667e1bd9d82bc4))
* **test:** align install test expectations + dialyzer advisory ([bb5c848](https://github.com/szTheory/mailglass/commit/bb5c8483c6496ac000a94843c858604968bdf320))
* **test:** broadcast DISCARD ALL to pool workers instead of pool restart ([42f3527](https://github.com/szTheory/mailglass/commit/42f352753f1201d281fb1d08b66d8e256d3db385))
* **test:** exclude migration roundtrip from cold-start lane ([7a15167](https://github.com/szTheory/mailglass/commit/7a15167a4bbd75e4811bf1d790073dc6cf498c9d))
* **test:** override pool for migration phase to unblock CI Tests gate ([3840b92](https://github.com/szTheory/mailglass/commit/3840b92d1c53f496413d6ad9738d2a5b524ec278))
* **test:** restart TestRepo pool after migration down/up round-trip ([ce2c03d](https://github.com/szTheory/mailglass/commit/ce2c03d3f10a53cc91ebaf472ca027f6f92f4c90))
* wrap Oban workers in top-level optional-dep guard ([19485d3](https://github.com/szTheory/mailglass/commit/19485d3c8e4ec88c17c16144780bf03b51fe3664))


### Miscellaneous Chores

* release 0.1.0 ([e26b691](https://github.com/szTheory/mailglass/commit/e26b6910f8859e3489937739da9a0db37e46ad90))

## [0.1.0] - 2026-04-25

Mailglass is the framework layer Swoosh deliberately leaves out of its
transport-only core: HEEx-native components, an append-only event ledger,
first-class multi-tenancy, and normalized webhook events across providers.
This is a validation release — the API surface is documented in
`docs/api_stability.md`, the test suite is green on Elixir 1.18+ / OTP 27+ /
Phoenix 1.8+, and we are inviting feedback from teams who want to see the
mail their app sends before it ships.

### Added

- HEEx-native component library (`<.container>`, `<.row>`, `<.column>`,
  `<.button>`, `<.img>`, `<.heading>`, `<.text>`, `<.divider>`, `<.spacer>`)
  with MSO Outlook VML fallbacks generated at render time. No Node toolchain
  required at any point in the pipeline.
- A pure-function render pipeline: `Mailglass.Renderer.render/1` runs HEEx →
  Premailex CSS inlining → Floki-derived plaintext, returning a fully formed
  `%Swoosh.Email{}` ready for any Swoosh adapter.
- An append-only `mailglass_events` ledger backed by a Postgres trigger that
  raises SQLSTATE `45A01` on UPDATE and DELETE attempts. Audit history is a
  database-level invariant, not a convention.
- Multi-tenancy via the `Mailglass.Tenancy` behaviour with `tenant_id` on
  every record from day one. The single-tenant default works out of the box;
  multi-tenant adopters swap in their own scope without retrofitting schemas.
- Webhook ingest for Postmark and SendGrid that normalizes provider payloads
  into the Anymail event taxonomy, deduplicates on
  `(provider, provider_event_id)`, and reconciles orphan events to deliveries
  via a 15-minute Oban cron when their delivery row arrives late.
- A send pipeline that flows `Mailable` → preflight (suppression list,
  rate-limit, stream policy) → render → atomic
  `Multi(Delivery + Event + Worker enqueue)` → adapter dispatch, with the
  adapter call held outside the transaction to keep the Postgres pool free.
- `Mailglass.Adapters.Fake` — a stateful, time-advanceable test adapter with
  the `assert_mail_sent/1` family of matchers for ExUnit, plus
  `Mailglass.Test.set_mailglass_global/1` for cross-process delivery capture.
- A dev-preview LiveView (`mailglass_admin`) with auto-discovered mailables,
  HTML / Text / Raw / Headers tabs, device-width and dark/light toggles, and
  the brand palette (Ink, Glass, Ice, Mist, Paper, Slate) wired through
  Tailwind v4 — also without Node, via static asset bundling.
- Twelve custom Credo checks that enforce domain rules at lint time —
  telemetry PII whitelist, tracking-off-by-default on auth-stream mailables,
  no-raw-Swoosh-deliver in lib code, prefixed PubSub topics, and append-only
  event writes among them.
- `mix mailglass.install` for Phoenix 1.8 hosts — an idempotent installer
  that writes config, migration, and module seams, leaving
  `.mailglass_conflict_*` sidecars when an existing file would be touched.
  A golden-diff CI snapshot test catches installer regressions.
- ExDoc with nine guides covering authoring, components, preview, webhooks,
  multi-tenancy, telemetry, testing, the Fake adapter, and migration from
  raw Swoosh + `Phoenix.Swoosh`.

### Security

- HMAC-verified webhook ingest. Postmark uses HTTP Basic Auth compared via
  `Plug.Crypto.secure_compare/2`; SendGrid uses ECDSA P-256 verification via
  OTP 27 `:public_key`. Forged signatures raise `Mailglass.SignatureError`
  with no recovery path and the plug returns `401`.
- A suppression-list check runs before every send. Recipients on the list
  cannot be re-sent to without an explicit unblock through the suppression
  store — bounce and complaint signals feed the list automatically.
- Open and click tracking are off by default. Per-mailable opt-in is
  required, and the `NoTrackingOnAuthStream` Credo check raises at compile
  time on auth-context heuristics (`magic_link`, `password_reset`,
  `verify_email`, `confirm_account`).
- Telemetry metadata is whitelisted to counts, statuses, IDs, and latencies.
  The PII keys (`:to`, `:from`, `:body`, `:html_body`, `:subject`,
  `:headers`, `:recipient`, `:email`) are forbidden by the
  `NoPiiInTelemetryMeta` Credo check, so adopters cannot accidentally leak
  recipient data through their handlers.
- Click-rewriting tokens are signed via `Phoenix.Token` with rotation
  support. Target URLs live inside the signed payload, never as a query
  parameter — the open-redirect CVE class is structurally unreachable.
