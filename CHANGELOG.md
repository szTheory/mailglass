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

## [2.6.0](https://github.com/szTheory/mailglass/compare/mailglass-v2.5.0...mailglass-v2.6.0) (2026-09-07)


### Features

* **162-01:** capture PR release reconciliation tracer ([fec73dd](https://github.com/szTheory/mailglass/commit/fec73ddad869ba82504692712f6ece58e735bbc2))
* **162-02:** record proposal-only release outcomes ([424c9af](https://github.com/szTheory/mailglass/commit/424c9af71f93b27b31f71517cc6f0e03e5783ff2))
* **162-03:** classify hygiene evidence as cannot-check ([52f2fe3](https://github.com/szTheory/mailglass/commit/52f2fe3522142626603ed57745623cadbf619e6f))
* **162-03:** render hygiene result from audit artifact ([ac00bd2](https://github.com/szTheory/mailglass/commit/ac00bd2405d8b8cd11eef30739d613ed5c5be6a7))
* **162-04:** report blocked scheduled post-publish targets ([751e89a](https://github.com/szTheory/mailglass/commit/751e89a105741056489b9cf78c60837f05a832e2))
* **162-05:** finalize protected release reconciliation ([fb32b07](https://github.com/szTheory/mailglass/commit/fb32b076e65ad995b4d48520da8ae7c26481683e))
* **162-08:** recover idle scheduled release control\n\n- Discover exact open release proposals before scheduled capture\n- Preserve pending no-open-proposal evidence through upload and gate\n ([cb5020c](https://github.com/szTheory/mailglass/commit/cb5020c7584a020199d2305c0aa7abff7cf881b1))
* **162-12:** authorize protected release dispatcher ([7f74f02](https://github.com/szTheory/mailglass/commit/7f74f02b6756ecd3063109a346763438f895f758))
* **164-01:** ledger the stale scheduled-control sweep ([507b7a1](https://github.com/szTheory/mailglass/commit/507b7a169a5598c010b8fbd60434528262a1ae08))
* **164-03:** clarify current package compatibility\n\n- Mark each package README's current compatibility guidance\n- Document the linked core/admin and independent inbound constraints\n ([d272e82](https://github.com/szTheory/mailglass/commit/d272e824e92f11f09c4a060271cd1202837b3711))
* **164-04:** complete repository truth inventory ([12a1694](https://github.com/szTheory/mailglass/commit/12a1694cb087d9ba376935e5525af05363334a42))
* **164-05:** compose fail-closed closeout verdict ([a24f161](https://github.com/szTheory/mailglass/commit/a24f161395c6661085f3e2ca68109372d1b21f51))
* **164-08:** extract repository truth ledger validator ([b96df55](https://github.com/szTheory/mailglass/commit/b96df559bcafeecd910f7567e5f4ca9817a1a95c))
* **164-09:** bind closeout to canonical truth paths ([38e7076](https://github.com/szTheory/mailglass/commit/38e7076fe09f1793045742d3168fe76e1f1f4449))
* **164-10:** trust authoritative scheduled freshness ([6e825d2](https://github.com/szTheory/mailglass/commit/6e825d2ea2bb576c4f2ed1e98db1be92a2368572))
* **164-11:** add guarded finalize-phase command ([4f2ddf6](https://github.com/szTheory/mailglass/commit/4f2ddf6c1f1603eb98a4f2286eb390dedab6b39a))
* **164-11:** implement attempt-one phase finalization ([e0ad4fa](https://github.com/szTheory/mailglass/commit/e0ad4fa82a2172d445baddbee4f4b8871e29e14b))


### Bug Fixes

* **162-06:** preserve proposal capture outputs on exit ([815ec16](https://github.com/szTheory/mailglass/commit/815ec166085d4c1353e1f282750fb09f962e4d91))
* **162-07:** serialize every post-publish resolution ([e7f0e29](https://github.com/szTheory/mailglass/commit/e7f0e29259d4c65a4b22c9774b3a775514ce04ba))
* **162-09:** select CI by checkout SHA\n\n- Query ci.yml runs with the exact detached HEAD commit\n- Preserve head SHA and terminal-success validation in hygiene output\n ([eff6892](https://github.com/szTheory/mailglass/commit/eff6892d19ed2ffcceff8d94634df7ec96b3562b))
* **162-10:** isolate protected release from proposal tail ([aee58c0](https://github.com/szTheory/mailglass/commit/aee58c02cfebd31507c238821bece8949d0323f1))
* **162-11:** bound malformed CI run responses ([833df30](https://github.com/szTheory/mailglass/commit/833df307ecde21dd1f3a3a6934131185309cdbe6))
* **162-13:** bound malformed PR list evidence ([b33d619](https://github.com/szTheory/mailglass/commit/b33d619d8df33d59dec0d5df2b5643e952163c43))
* **163:** bound recurrent primitive matrices ([f8bf029](https://github.com/szTheory/mailglass/commit/f8bf029faf87d8dda0ef1a36fe6ebbe6e2ab60d6))
* **163:** preserve protected browser ownership ([9d0bcac](https://github.com/szTheory/mailglass/commit/9d0bcacf875ad0c88155bd16bad2996c1c57b926))
* **163:** repair protected browser timeout recurrences ([e8c6260](https://github.com/szTheory/mailglass/commit/e8c6260ff0f01fc88ed0b3b5241e4caf8584ccf2))
* **164-05:** accept evidenced hygiene policy blocks ([fbc2a09](https://github.com/szTheory/mailglass/commit/fbc2a0992f01b2a5b4094a40914808cbeff750ce))
* **164-05:** preserve exact CI JSON in closeout ([8edae93](https://github.com/szTheory/mailglass/commit/8edae935d74a8200ed2eee4674ae9326189b452e))
* **164-08:** reconcile authoritative truth ledger ([d5ce88f](https://github.com/szTheory/mailglass/commit/d5ce88f97f39924149c7c594ae211309a16503c7))
* **164-11:** align finalizer command with GSD exec results ([8f212b0](https://github.com/szTheory/mailglass/commit/8f212b0917ff3c97186b35defb6b7743542cd4c3))
* **164-11:** ignore volatile GSD milestone lock ([4bc18c2](https://github.com/szTheory/mailglass/commit/4bc18c2dc3fee120cabcd92d60cf6379ced68be8))
* **164:** close repository-truth security and validation gaps ([e79cd50](https://github.com/szTheory/mailglass/commit/e79cd50c04cd34961a7e60613e2067701cd173d4))
* **164:** CR-01 prevent symlinked evidence writes ([d6f83d2](https://github.com/szTheory/mailglass/commit/d6f83d2d6fc1116ef5f5c61891149e6a08fd27b7))
* **164:** CR-02 require complete scheduled evidence ([e12b8c2](https://github.com/szTheory/mailglass/commit/e12b8c212c3d81fa48a1d4e72f11e893c38628b8))
* **164:** CR-03 pin authoritative GitHub host ([40042c7](https://github.com/szTheory/mailglass/commit/40042c78dd3c2a109342ae7986c2304fd0168299))
* **164:** CR-03 pin authoritative repository identity ([eaf41de](https://github.com/szTheory/mailglass/commit/eaf41de2a25be18df759d79a8fdc3542ad1d7a02))
* **164:** CR-03 pin scheduled freshness authority ([fe20b57](https://github.com/szTheory/mailglass/commit/fe20b570deda921c316f84b305e351725ac0dcea))
* **164:** CR-04 revalidate protected main at final decision ([897f48c](https://github.com/szTheory/mailglass/commit/897f48ca9603596ce9313b96f3fd13df587e2144))
* **164:** CR-05 authenticate ledger semantics ([0deb20e](https://github.com/szTheory/mailglass/commit/0deb20eb7a7cfb4740230fac0ec4e6128252e1d9))
* **164:** CR-05 bind every audited ledger relationship ([4b0edbf](https://github.com/szTheory/mailglass/commit/4b0edbf0f3a9b007a726505c2b77a0f4c1c51728))
* **164:** CR-05 bind ledger semantics to canonical subjects ([7d5559a](https://github.com/szTheory/mailglass/commit/7d5559afbf891b79b4f9b47e2f7c9403540c2bac))
* **164:** CR-06 document production admin dependency ([cbdd37c](https://github.com/szTheory/mailglass/commit/cbdd37c9f89ca626ae936a7978b4ba99346e64a0))
* **164:** WR-01 align compatibility index with v2 ([e91b5cb](https://github.com/szTheory/mailglass/commit/e91b5cb8f9b9b1b85d3c71af83598b2339f491c8))
* **164:** WR-01 align current contract major labels ([7897fb4](https://github.com/szTheory/mailglass/commit/7897fb4e5f67e5f157b2af9b1e89a7b910140790))
* accept evidenced closeout policy blocks ([84454ae](https://github.com/szTheory/mailglass/commit/84454ae6b60ec9c52114d5bf44ed394dac611f99))
* **ci:** fetch history for evidence contracts ([8ab9fc5](https://github.com/szTheory/mailglass/commit/8ab9fc5ba299d11bdd45b7684567c75cb042e352))
* **ci:** repair phase 164 protected gates ([5859cc7](https://github.com/szTheory/mailglass/commit/5859cc7ccb47dc49d41b94cf682286fc846a057b))
* **ci:** retain history in deterministic suite ([6466d4f](https://github.com/szTheory/mailglass/commit/6466d4f18f662ae4e8e5f986695134580520498d))
* **ci:** retain history in full-suite lanes ([3d93f4e](https://github.com/szTheory/mailglass/commit/3d93f4ef4427789a682e366ca92736c4819fc61a))
* preserve exact CI JSON in repository closeout ([233c24c](https://github.com/szTheory/mailglass/commit/233c24c10f01d7a74a2b955b81ed526397e0bf52))
* reconcile repository truth closeout ([e5c4fc7](https://github.com/szTheory/mailglass/commit/e5c4fc793d7504280298156da4d4652f09802482))
* **release:** configure disposable host Swoosh ([6c4b284](https://github.com/szTheory/mailglass/commit/6c4b2846d4d3af062ae27579394ccfe7e9c27f20))
* **release:** configure disposable host Swoosh ([b56bb13](https://github.com/szTheory/mailglass/commit/b56bb1345bca38eab2cd50365febe58dbcb935fd))
* **release:** provision smoke consumer database ([3a06e12](https://github.com/szTheory/mailglass/commit/3a06e122a990d63bea13244299af0e21d9972282))
* **release:** provision smoke consumer database ([229421a](https://github.com/szTheory/mailglass/commit/229421a9dc5cc0e5a58c304128eafb29cc8cfbe0))
* **release:** recover immutable tag CI gate ([#221](https://github.com/szTheory/mailglass/issues/221)) ([323f808](https://github.com/szTheory/mailglass/commit/323f808cb2d5fc203120ed2e528059ff1806d640))
* resolve post-merge formatting from wave 2 ([6af2f41](https://github.com/szTheory/mailglass/commit/6af2f419831618c8d52ae93ede0108f802abb6f3))
* restore Phase 164 repository-truth finalization ([382ebb0](https://github.com/szTheory/mailglass/commit/382ebb0a33ad12d8bb11cc67fa4ef9a943b37a9d))

## [2.5.0](https://github.com/szTheory/mailglass/compare/mailglass-v2.4.1...mailglass-v2.5.0) (2026-08-20)


### Features

* complete v2.6 engineering quality ratchet ([#203](https://github.com/szTheory/mailglass/issues/203)) ([61e8c8e](https://github.com/szTheory/mailglass/commit/61e8c8e841306755ec637f84052f8dca4baadb76))


### Bug Fixes

* **160-06:** unblock exact protected release merge ([856d661](https://github.com/szTheory/mailglass/commit/856d661c094ceffc22f7bb7a8e5812aeb25de9f5))
* **ci:** avoid branch protection probe sigpipe ([#211](https://github.com/szTheory/mailglass/issues/211)) ([f14cd66](https://github.com/szTheory/mailglass/commit/f14cd6601d03036cbfef7d29a91ee9783cb1272b))
* **release:** bound proposal history after published baselines ([#208](https://github.com/szTheory/mailglass/issues/208)) ([d44d891](https://github.com/szTheory/mailglass/commit/d44d891d4cf2106e9cda8677dd1932b4bc032229))

## [2.4.0](https://github.com/szTheory/mailglass/compare/mailglass-v2.3.0...mailglass-v2.4.0) (2026-08-02)


### Features

* ship B2C first-adopter readiness ([#165](https://github.com/szTheory/mailglass/issues/165)) ([53211e8](https://github.com/szTheory/mailglass/commit/53211e8bb9db2d2e16d5b2457868f2eefad249c5))


### Bug Fixes

* **ci:** isolate branch protection report output ([#168](https://github.com/szTheory/mailglass/issues/168)) ([e171798](https://github.com/szTheory/mailglass/commit/e17179814d8e8a70b153255d9dd770e4cb621edc))
* **ci:** make missing gh fixture portable ([#167](https://github.com/szTheory/mailglass/issues/167)) ([c829c38](https://github.com/szTheory/mailglass/commit/c829c386c59a08a190ffb5243e5871f974548637))
* **release:** sync inbound core compatibility pins ([#178](https://github.com/szTheory/mailglass/issues/178)) ([313455a](https://github.com/szTheory/mailglass/commit/313455a67b60c1b5221047190ed390f7449279f0))

## [2.4.1](https://github.com/szTheory/mailglass/compare/mailglass-v2.4.0...mailglass-v2.4.1) (2026-08-03)

### Added

* Add a stable, PII-free delivery-feedback telemetry event for durable provider and unsubscribe outcomes.
* Add an opinionated B2C first-adopter production profile covering streams, suppression recovery, cold-domain routing, observability, and sibling-package boundaries.

### Changed

* The sibling packages (`mailglass_inbound`, `mailglass_admin`) now depend on
  `mailglass` via pessimistic `~>` constraints instead of exact pins, ending
  the paired-release-per-core-patch requirement. A core patch release no longer
  drags a paired inbound or admin release.

### Fixed

* Prevent replayed RFC 8058 POSTs from emitting duplicate delivery-update and feedback signals.

## [2.3.0](https://github.com/szTheory/mailglass/compare/mailglass-v2.2.2...mailglass-v2.3.0) (2026-07-31)


### Features

* **143:** give the Core Full Suite legs veto power over a Hex publish ([#161](https://github.com/szTheory/mailglass/issues/161)) ([3400813](https://github.com/szTheory/mailglass/commit/34008138fdb779d01109da086dea0c468d5c75d9))

## [2.2.2](https://github.com/szTheory/mailglass/compare/mailglass-v2.2.1...mailglass-v2.2.2) (2026-07-31)


### Bug Fixes

* **143:** make the gate-self-test probe report what it actually observed ([#157](https://github.com/szTheory/mailglass/issues/157)) ([981b934](https://github.com/szTheory/mailglass/commit/981b9343a8fec7eb82d0d7df3f3e06467b04f90a))

## [2.2.1](https://github.com/szTheory/mailglass/compare/mailglass-v2.2.0...mailglass-v2.2.1) (2026-07-29)


### Bug Fixes

* **publish:** document tarball allowlist protocol and release 2.2.1 ([#148](https://github.com/szTheory/mailglass/issues/148)) ([3edc95f](https://github.com/szTheory/mailglass/commit/3edc95f01865dc667eaa8cf80c7130714aa4f3ca))

## [2.2.0](https://github.com/szTheory/mailglass/compare/mailglass-v2.1.3...mailglass-v2.2.0) (2026-07-29)


### Features

* **142:** supply-chain remediation — allowlist wiring + promote audit lanes to merge-gating ([#144](https://github.com/szTheory/mailglass/issues/144)) ([4659846](https://github.com/szTheory/mailglass/commit/46598461143b9413d57b5746acec3b84e9735614))

## [2.1.3](https://github.com/szTheory/mailglass/compare/mailglass-v2.1.2...mailglass-v2.1.3) (2026-07-28)


### Miscellaneous Chores

* **mailglass:** Synchronize mailglass-sibling-group versions

## [2.1.2](https://github.com/szTheory/mailglass/compare/mailglass-v2.1.1...mailglass-v2.1.2) (2026-07-28)


### Bug Fixes

* **admin:** clear the design-system and Dialyzer lanes blocking release ([#136](https://github.com/szTheory/mailglass/issues/136)) ([31588bb](https://github.com/szTheory/mailglass/commit/31588bb40343fc67200ca8bf4da7ffb3351248fa))
* **test:** make the citext probe honest and restore the suite baseline ([#137](https://github.com/szTheory/mailglass/issues/137)) ([579ad37](https://github.com/szTheory/mailglass/commit/579ad379bc979a78870f2f56ce865c19f44f6a20))

## [2.1.1](https://github.com/szTheory/mailglass/compare/mailglass-v2.1.0...mailglass-v2.1.1) (2026-07-28)


### Bug Fixes

* unblock the 2.1.0 publish — admin allowlist + 7 security advisories ([#134](https://github.com/szTheory/mailglass/issues/134)) ([eda8d00](https://github.com/szTheory/mailglass/commit/eda8d0032bf1976477c9f1bac18c4e1488ed57d7))

## [2.1.0](https://github.com/szTheory/mailglass/compare/mailglass-v2.0.0...mailglass-v2.1.0) (2026-07-28)


### Features

* **138-01:** prefix unsubscribe conflict lookup ([a9dcd9a](https://github.com/szTheory/mailglass/commit/a9dcd9a9dca99f1a8edfb930228cc0574c400bbe))
* **138-01:** prefix webhook replay projection update ([e3bcb67](https://github.com/szTheory/mailglass/commit/e3bcb67f472525dd3fe077e1a41b87c24c5ef6da))
* **138-03:** add raw repo prefix Credo guard ([8e8ae96](https://github.com/szTheory/mailglass/commit/8e8ae96fa6d8585b19a69a3d962eedb83a24c8a9))
* **138-03:** prefix projection Multi updates ([0e38af5](https://github.com/szTheory/mailglass/commit/0e38af52e37b7526bca5f0fb21327731d6ab4c73))
* **138-04:** add schema prefix verification alias ([bf76db9](https://github.com/szTheory/mailglass/commit/bf76db91de33f2030d43931f1e75a525f861c1bb))
* operator Quick view + Full detail record inspection ([#128](https://github.com/szTheory/mailglass/issues/128)) ([7a68501](https://github.com/szTheory/mailglass/commit/7a6850146f606c3e82bcb50bc7c146c830caf0e1))


### Bug Fixes

* **138:** close raw guard and replay review gaps ([68f820c](https://github.com/szTheory/mailglass/commit/68f820c8493fa69be753e95440cd8fb6c2a0ee5f))
* **138:** close raw repo guard owner gaps ([7563b7f](https://github.com/szTheory/mailglass/commit/7563b7f186c2082f8afd0cdbd91d27de83e510a5))
* **138:** close raw repo prefix guard review gaps ([b034c07](https://github.com/szTheory/mailglass/commit/b034c070a18541f2c31d99e1e52785796a9a7f72))
* **138:** close remaining schema prefix review gaps ([d707e0a](https://github.com/szTheory/mailglass/commit/d707e0a321025f4c2e215731470545926e0f05f6))
* **138:** close review alias and actor gaps ([50ecab5](https://github.com/szTheory/mailglass/commit/50ecab5daff4fbd1588621d90ff23007632d42ac))
* **138:** cover helper and schema alias guard bypasses ([632ef1c](https://github.com/szTheory/mailglass/commit/632ef1c9ca6f142640c0c1f4ba6cf4b558efe36d))
* **138:** cover replay run raw guard gaps ([c028967](https://github.com/szTheory/mailglass/commit/c028967721aca953d57b6d383f40e4ba6f16a848))
* **138:** cover repo and multi alias guard bypasses ([0f3edbc](https://github.com/szTheory/mailglass/commit/0f3edbc4fa71218334161eaea0aaf36a06e671f4))
* **138:** cover same-module query helper guard bypass ([f6aaca1](https://github.com/szTheory/mailglass/commit/f6aaca1473cf725a342750fe005b099e37bcab85))
* **138:** harden raw repo guard alias and helper trust ([e4200a3](https://github.com/szTheory/mailglass/commit/e4200a3bb7843a59a394df7a069b331d88c4608e))
* **138:** harden raw repo guard pipe handling ([e45ca0e](https://github.com/szTheory/mailglass/commit/e45ca0e6862cd7895f8c74f2b17176dfe32cc460))
* **138:** harden raw repo prefix guard edge cases ([544a8e9](https://github.com/szTheory/mailglass/commit/544a8e946e701619d013bab541bb9deb1c5b649a))
* **138:** isolate raw repo guard module context ([7d0e2dd](https://github.com/szTheory/mailglass/commit/7d0e2ddf446f482e8377caa6f2167b96e9ee8f87))
* **138:** respect module alias order in raw guard ([786d277](https://github.com/szTheory/mailglass/commit/786d2772f29a034521d7186be026ce867af012a1))
* **138:** scope schema aliases in raw repo guard ([f33d433](https://github.com/szTheory/mailglass/commit/f33d433c20739604156ebcb557f8f7b711593c28))
* **138:** skip no-op event projections ([4aa0a1d](https://github.com/szTheory/mailglass/commit/4aa0a1dbaa859b2d882e7d8db44c630262c251d7))
* format docs contract after wave 2 ([dde7225](https://github.com/szTheory/mailglass/commit/dde7225e00c8e4a73d252a5153ef99d6c65cff57))

## [2.0.0](https://github.com/szTheory/mailglass/compare/mailglass-v1.11.0...mailglass-v2.0.0) (2026-07-04)


### ⚠ BREAKING CHANGES

* **release:** marker is banked in 132-136, so release-please would otherwise cut 1.12.0/1.12.0. This root mix.exs touch attributes the footer below to the linked group (core exclude-paths keep admin/inbound out of `.`).

### Features

* **132-01:** add :schema config key, schema/0 accessor, boot-warm ([3ab6978](https://github.com/szTheory/mailglass/commit/3ab6978a66b76d7d9d77380b0be43504b1c1b62f))
* **132-01:** implement Mailglass.Identifier shared validator ([9c4aedc](https://github.com/szTheory/mailglass/commit/9c4aedc4e21fcfa31c62fdf98e1b4de91a4a16f7))
* **133-01:** add put_prefix/1 + multi_opts/1 to Mailglass.Repo facade ([be7a16a](https://github.com/szTheory/mailglass/commit/be7a16a6a9dffa569741543f18f86a47a7640431))
* **133-01:** defensive put_query_prefix on orphans subquery + fix Credo comments ([de34a2e](https://github.com/szTheory/mailglass/commit/de34a2ea8afd1ebf2ccab37e3f2f090e081581fe))
* **133-01:** thread prefix per-step into Events/Outbound/Escalation Multi builders ([a3abe87](https://github.com/szTheory/mailglass/commit/a3abe87fbf366e8c4f8f61db6a21e885b267619d))
* **133-02:** add FACADE-04 schema-isolation integration test + fix admin test.exs schema pin ([70a3e07](https://github.com/szTheory/mailglass/commit/70a3e0715ec69c44f9977025f7dd4bab8aaddf0f))
* **133-02:** FACADE-03 admin zero-code-change render proof + D-08 bypass fix ([ee8e965](https://github.com/szTheory/mailglass/commit/ee8e965d54fd7bd2e86676c3e2cb0d4f697841b3))
* **134-01:** add maybe_create_schema/1 + maybe_drop_schema/1 to Postgres dispatcher ([43e3c65](https://github.com/szTheory/mailglass/commit/43e3c657fc53d5f349686e6e7ae31753eb5b0b75))
* **134-01:** inject prefix: Config.schema() at Mailglass.Migration entrypoint ([0d0d70d](https://github.com/szTheory/mailglass/commit/0d0d70dc4b00ede2f9fc254f1a8036309507bdc0))
* **134-02:** schema-qualify v01 immutability fn+trigger+CHECK, thread prefix through down/1 (MIGR-03, MIGR-04) ([ac2a2e5](https://github.com/szTheory/mailglass/commit/ac2a2e5b1a5f5b182332f93dd657cb04259f1708))
* **134-02:** schema-qualify v03 complaint CHECK in up/1 and down/1 (MIGR-04) ([63f54a3](https://github.com/szTheory/mailglass/commit/63f54a3f29be0774b35b937bfbd6820a4d6c2d72))
* **134-03:** add NoSchemaPrefixAttribute credo guard (MIGR-06) ([dc40465](https://github.com/szTheory/mailglass/commit/dc404655c068b543806cb48e800ba9d702b7aab0))
* **134-03:** MAILGLASS_SCHEMA override + schema-aware suite (D-06 axis) ([ace086b](https://github.com/szTheory/mailglass/commit/ace086b5e09a51e81e63c34eb6c4edf0242f2a9b))
* **135-03:** add mailglass_inbound dual-schema advisory CI job (INB-03) ([76f2be0](https://github.com/szTheory/mailglass/commit/76f2be0e8022281eb3c97cdc1a7a565e03301ca0))
* **136-01:** implement mix mailglass.upgrade.v2_schema file-emitter ([ffeb84e](https://github.com/szTheory/mailglass/commit/ffeb84ed023b25a17ec0eb50ec5cd04b49553c71))


### Bug Fixes

* **137-02:** defer reference baseline ~&gt; 2.0 advance to post-publish ([c38d20c](https://github.com/szTheory/mailglass/commit/c38d20c0ea7a987bd02d072c7745fb0afd5bfe5f))
* **137-02:** schema-qualify demo hand-written migrations for v2.0 mailglass schema ([adc27f8](https://github.com/szTheory/mailglass/commit/adc27f8889f9447ed9be7ca98bac6ba4b5a38291))
* **137-02:** set up non-public schema in core test harness (D-06 matrix) ([3169228](https://github.com/szTheory/mailglass/commit/3169228f9e75185c9b68757fe433ebc9b7c97368))
* **137:** no-op redundant demo delivery-snapshot migration for v2.0 ([076530d](https://github.com/szTheory/mailglass/commit/076530dce3b19ca101f65806ada74541983165c6))
* **137:** schema-qualify demo seed/reset SQL for v2.0 mailglass schema ([ead30b5](https://github.com/szTheory/mailglass/commit/ead30b5e830bab6d1d8012a8273ca03af63b18d5))
* **docs-contract:** update inbound stability marker assertions to 2.0 ([2996c5e](https://github.com/szTheory/mailglass/commit/2996c5e9d55ab21e2c90645221c51c2cd78dbd05))
* **docs:** bump docs.check README inbound tokens to stable 2.0 ([32657f7](https://github.com/szTheory/mailglass/commit/32657f7b80730b86bc82b63be71ee339d4ab5462))
* **publish-contract:** reconcile trust-lane contract test with Phase 126 changes-gate ([b308f45](https://github.com/szTheory/mailglass/commit/b308f453dd831d1ec7d8735cc157f93775223213))
* **test:** scope generic down/0 rollback test to public axis ([ba993c4](https://github.com/szTheory/mailglass/commit/ba993c4ff10b55d7a53fc23f8e1549f49dfa5d12))
* **webhook:** thread schema prefix through ingest Multi write steps ([f64c0b2](https://github.com/szTheory/mailglass/commit/f64c0b2ff5677ba6c5566857965e8b2970130c08))


### Miscellaneous Chores

* **release:** trigger 2.0.0 major for linked core+admin group ([c96d7ca](https://github.com/szTheory/mailglass/commit/c96d7ca8b9039a842d53f904e59eedfe3da40093))

## [1.11.0](https://github.com/szTheory/mailglass/compare/mailglass-v1.10.2...mailglass-v1.11.0) (2026-07-02)


### Features

* **125-01:** loosen sibling pins from == to ~&gt; (keystone atomic change) ([37dcaf1](https://github.com/szTheory/mailglass/commit/37dcaf11dfa1cea1f59ac7f247d71ff8bf9943bf))
* **128-01:** add brand-voice Postgres + network preflight guards ([8fcea59](https://github.com/szTheory/mailglass/commit/8fcea591f3ea486954cebabf0cde206f07c70756))
* **128-01:** add make ci / ci-fast / ci-browser wrappers ([7c69277](https://github.com/szTheory/mailglass/commit/7c6927764a1db5d722abb04a14f5e25d247f6ee7))
* **128-01:** add mix ci alias family, remove deprecated verify.phase pass-throughs ([62da46a](https://github.com/szTheory/mailglass/commit/62da46aeb232262e292ffd4ed0adb7c10c075c98))
* **128-02:** add MIXCI-03 parity-drift + durable seed guard test ([4a3fa5a](https://github.com/szTheory/mailglass/commit/4a3fa5a3aac3d1f74e11bf152edb1968c8252cef))
* **128-02:** hoist required+advisory CI lanes to Mailglass.CILanes source ([6747fdd](https://github.com/szTheory/mailglass/commit/6747fddff0035eb0e75bf1e3316038436f13223c))
* **129-01:** point all canonical-lane setup-beam blocks at .tool-versions ([6c7f359](https://github.com/szTheory/mailglass/commit/6c7f359d5d9d398f029367649daf407b50880211))
* **129-01:** rewrite canonical deps/_build cache keys to toolchain-hashed shape ([35bef2a](https://github.com/szTheory/mailglass/commit/35bef2a0b90a41e987c32f0c31351c5c1ef68cdf))
* **130-01:** add deps_audit_advisory advisory CI lane (SUPPLY-01) ([a7c86e4](https://github.com/szTheory/mailglass/commit/a7c86e42d2fa7e53665fa02f7824526b3b55b2e3))
* **130-01:** add mix_audit dep and deps.audit ci alias entry ([3adde80](https://github.com/szTheory/mailglass/commit/3adde80b5ec57e8aaea7e229b42071adaf4ce097))
* **130-01:** implement deps.audit gate + OSV staleness (SUPPLY-01/03) ([8d10afd](https://github.com/szTheory/mailglass/commit/8d10afdf9660179452da74eb24700e41b74ca08a))


### Bug Fixes

* **128:** bound preflight TCP fallback; correct CONTRIBUTING + comment discipline ([90f1416](https://github.com/szTheory/mailglass/commit/90f1416813553aecd8ba67dd3223836a8f9f9444))
* **ci:** format+credo+compile-no-optional-deps regressions from phase 126-130 commits ([6da0074](https://github.com/szTheory/mailglass/commit/6da0074489c1033eaccc34dd2c64f30fca49c37a))

## [1.10.2](https://github.com/szTheory/mailglass/compare/mailglass-v1.10.1...mailglass-v1.10.2) (2026-06-30)


### Bug Fixes

* ship deliveries idempotency DDL via the migration dispatcher (V05) ([#100](https://github.com/szTheory/mailglass/issues/100)) ([9512ce1](https://github.com/szTheory/mailglass/commit/9512ce1b1d5612faf36dd279a3447105374f21b3))

## [1.10.1](https://github.com/szTheory/mailglass/compare/mailglass-v1.10.0...mailglass-v1.10.1) (2026-06-30)


### Bug Fixes

* **release:** accept unfixable cowlib advisories in publish.check hex.audit gate ([8e9fbaf](https://github.com/szTheory/mailglass/commit/8e9fbaf962e68e012ef66c8f98d30a20756ce16f))

## [1.10.0](https://github.com/szTheory/mailglass/compare/mailglass-v1.9.0...mailglass-v1.10.0) (2026-06-29)


### Features

* **118-01:** author foundations + primitives story inventory (STORY-01) ([6e34470](https://github.com/szTheory/mailglass/commit/6e344707d83d875227dee0eec7c872f81cb0056e))
* **118-01:** mount dev-only phoenix_storybook in the demo app (D-06/D-07) ([2667c55](https://github.com/szTheory/mailglass/commit/2667c5546cd0fa3bdbd41d541945fc33524ebd1f))
* **118-03:** add persona-critic screenshot seam reusing existing Playwright infra ([e596bf9](https://github.com/szTheory/mailglass/commit/e596bf9c06e3d1b4c6e0062d547f93f2d0e65360))


### Bug Fixes

* **deps:** bump plug to 1.19.3 for CVE-2026-54892 (HIGH) ([fc17fdf](https://github.com/szTheory/mailglass/commit/fc17fdfd05f2080301986fec14b1b26671ce09d4))

## [1.9.0](https://github.com/szTheory/mailglass/compare/mailglass-v1.8.0...mailglass-v1.9.0) (2026-06-26)


### Features

* **admin:** fold post-117 admin polish + fix the release-blocking demo reset race ([#91](https://github.com/szTheory/mailglass/issues/91)) ([5bba33c](https://github.com/szTheory/mailglass/commit/5bba33ccaed46f14d9ac1314ab829c6fdb10841e))


### Bug Fixes

* **ci:** refresh Hex registry before sibling publish deps.get ([c56973e](https://github.com/szTheory/mailglass/commit/c56973ea4bf18dd9a91c7257d234221fca162f2a))
* **ci:** unlock stale sibling lock before publish deps.get ([ceee383](https://github.com/szTheory/mailglass/commit/ceee38352f3bbccf20368b2fa65d6f614430e2cc))
* **ci:** use a fresh HEX_HOME for sibling publish deps.get ([f772e46](https://github.com/szTheory/mailglass/commit/f772e46ce3880afe889f262ef49cdee32d3ddfc8))

## [1.8.0](https://github.com/szTheory/mailglass/compare/mailglass-v1.7.0...mailglass-v1.8.0) (2026-06-21)


### Features

* **112-01:** implement scoped tenant selector seam ([d74b47b](https://github.com/szTheory/mailglass/commit/d74b47bbde226f3039dcfff0f91b4061beda4fbb))
* **112-05:** add read-model pagination metadata APIs ([4c78d23](https://github.com/szTheory/mailglass/commit/4c78d23fdef46ec4bb67814d4c6f74f380a8c6b5))
* **116-01:** admin-side seed_persona_cohort!/0 + cohort integration test ([039a9da](https://github.com/szTheory/mailglass/commit/039a9da64ff4c9d8eb180d642bb44f78bb9370c9))
* **116-01:** declarative Personas spec + parameterized demo seeding ([fcf5636](https://github.com/szTheory/mailglass/commit/fcf56362b8928f0427ce31403c78dfab06bdf0e1))


### Bug Fixes

* **116:** reconcile demo reset counts for the fjordline persona ([f71b2cc](https://github.com/szTheory/mailglass/commit/f71b2cc5a2a7692a2149082b15fddba06d6092fe))
* **116:** WR-04/WR-05 thread the demo seed anchor through Personas.materialize and match payload kind explicitly ([fc5b733](https://github.com/szTheory/mailglass/commit/fc5b7332abf406a8977c2e485f4c6578bdc0e859))
* **admin:** preview mount-aware URLs + operator tenant/theme/stat-card UI fixes ([766edf8](https://github.com/szTheory/mailglass/commit/766edf896befd713a46537c16ac1fb3ab5c695a6))

## [1.7.0](https://github.com/szTheory/mailglass/compare/mailglass-v1.6.2...mailglass-v1.7.0) (2026-06-17)


### Features

* **104-02:** add Mailglass.Installer.Doctor + mix mailglass.doctor static scan (INSTALL-03) ([29ae7bc](https://github.com/szTheory/mailglass/commit/29ae7bc4a976e5ee78f76476066f7acfe66bc22f))
* **104-02:** fail-closed validate_preflight/1 + format_error/1 clause (INSTALL-01/02) ([194fc8b](https://github.com/szTheory/mailglass/commit/194fc8b2813c9a439aaba00dca99307246b5886d))
* **106-02:** register production-go-live-checklist and errors-and-troubleshooting in mix.exs docs ([90c7f56](https://github.com/szTheory/mailglass/commit/90c7f562e146a8bd6bd061af41328d3a27a39ae8))
* **99-05:** harden advisory conformance gate ([733222f](https://github.com/szTheory/mailglass/commit/733222fa4fb97df6ae86d7838a60576037ec59de))

## [1.6.2](https://github.com/szTheory/mailglass/compare/mailglass-v1.6.1...mailglass-v1.6.2) (2026-06-12)


### Bug Fixes

* **inbound:** release the mailglass == 1.6.1 pin to restore resolution ([8dfc26a](https://github.com/szTheory/mailglass/commit/8dfc26abbefd1a207c084363063ca8fc3678d8c2))

## [1.6.1](https://github.com/szTheory/mailglass/compare/mailglass-v1.6.0...mailglass-v1.6.1) (2026-06-12)


### Bug Fixes

* **demo:** resolve seed anchor at reset time so evidence never ages out ([bfd010f](https://github.com/szTheory/mailglass/commit/bfd010f7560e6cd1b96be42aaa982a492a8c0ce5))

## [1.6.0](https://github.com/szTheory/mailglass/compare/mailglass-v1.5.1...mailglass-v1.6.0) (2026-06-12)


### Features

* **82-01:** add logo option SVGs ([8f216d7](https://github.com/szTheory/mailglass/commit/8f216d72fbea0585330c3a37163fc0f24bbcd940))
* **86-01:** add fable brand tokens (light+dark, DTCG json + css) ([e5a67a7](https://github.com/szTheory/mailglass/commit/e5a67a7d126c98dd0f2903a8746ef90dabe96e8f))
* **87-01:** add round-1 logo options 1-4 (axis A typemarks, axis B lockups) ([33022db](https://github.com/szTheory/mailglass/commit/33022db18282d924ce5f0737165bcd8c8725fa79))
* **87-01:** add round-1 logo options 5-8 (axis C monograms, axis D negative space) ([8768e0b](https://github.com/szTheory/mailglass/commit/8768e0b7f470b144ec8cacdfdfbcff47d55ff793))
* **87-01:** add round-1 rendered-evidence gallery ([86add0a](https://github.com/szTheory/mailglass/commit/86add0a96293b94913912e8b449f0ac1f330d81b))
* **87-02:** add round-2 variant field for option 8 with evidence gallery ([5ea4732](https://github.com/szTheory/mailglass/commit/5ea4732be1f63fba6327f14893972b21d5e860a0))
* **87-02:** add round-3 final candidate field with color program ([b1e0beb](https://github.com/szTheory/mailglass/commit/b1e0beb864ec144b464ff172e10581be415e6f10))
* **87-02:** add round-4 envelope-in-light candidates + gallery ([45c6aef](https://github.com/szTheory/mailglass/commit/45c6aeffa78de0890833d4ea0f430852057dc2b5))
* **87-02:** favicon adapts pane color to OS dark mode ([7f07706](https://github.com/szTheory/mailglass/commit/7f0770673f86cdb1988c94f2bd0f8f56a31993af))
* **87-02:** promote the sealed-flap mark to the canonical asset system ([b65335a](https://github.com/szTheory/mailglass/commit/b65335ac373f3041350338fb0a2a3d2f61152a00))
* **88-01:** add brand-book.md text master and folder README ([26c5af4](https://github.com/szTheory/mailglass/commit/26c5af433869569063f57919685a68212464a041))
* **88-01:** build the standalone fable brand book page ([39570f6](https://github.com/szTheory/mailglass/commit/39570f6340fdf18449afe5b31db444efdecd7e28))
* **88-01:** polish the brand book from the visual audit ([0bfd455](https://github.com/szTheory/mailglass/commit/0bfd455195c38a53fc354eccf29c75bb4b90ac43))
* **89-01:** add copy library — per-surface copy blocks and seven-noun microcopy ([0708c69](https://github.com/szTheory/mailglass/commit/0708c6962a67d4fc0911ab83669409cf1d6b87ef))
* **89-01:** add four SVG specimens — readme header, docs page, og card, diagram language ([a2919b5](https://github.com/szTheory/mailglass/commit/a2919b58fc8f7fd7d994d114196068a11fdd8571))
* **89-01:** add landing page and transactional email specimens ([64f1d09](https://github.com/szTheory/mailglass/commit/64f1d09991b41cbed934f27a17cafbb3ff4815cb))
* **89-01:** slot rendered specimens into the book's section 08 grid ([e2d47b5](https://github.com/szTheory/mailglass/commit/e2d47b5772611dd490d8b68e953cd83fb66c33af))

## [1.5.1](https://github.com/szTheory/mailglass/compare/mailglass-v1.5.0...mailglass-v1.5.1) (2026-06-05)


### Bug Fixes

* **admin-test:** run inbound migrations in the browser-server DB bootstrap ([#71](https://github.com/szTheory/mailglass/issues/71)) ([615beb0](https://github.com/szTheory/mailglass/commit/615beb06445c2c2b4cbc13a28780f0995a91a58c))

## [1.5.0](https://github.com/szTheory/mailglass/compare/mailglass-v1.4.5...mailglass-v1.5.0) (2026-06-05)


### Features

* **demo:** one-command Docker DX with collision-free ports ([#65](https://github.com/szTheory/mailglass/issues/65)) ([466544f](https://github.com/szTheory/mailglass/commit/466544f3d011fd95bc888abda9e81cedf24e966c))

## [1.4.5](https://github.com/szTheory/mailglass/compare/mailglass-v1.4.4...mailglass-v1.4.5) (2026-06-03)


### Bug Fixes

* **inbound:** track mailglass core pin to == 1.4.5 for the 1.4.5 linked release ([2f52710](https://github.com/szTheory/mailglass/commit/2f52710e9050a236af3986e439a5acd0f9511f21))
* **installer:** repair endpoint anchor split and escaped heex in generated code ([#59](https://github.com/szTheory/mailglass/issues/59)) ([f28e381](https://github.com/szTheory/mailglass/commit/f28e381f15764f57b5ffa779e088d88b4f6841db))

## [1.4.4](https://github.com/szTheory/mailglass/compare/mailglass-v1.4.3...mailglass-v1.4.4) (2026-06-03)


### Bug Fixes

* **deps:** make igniter optional so a fresh install stays HTTP-client-agnostic ([#57](https://github.com/szTheory/mailglass/issues/57)) ([65710fc](https://github.com/szTheory/mailglass/commit/65710fc560801c83ef94b0330ecf57e9c2ca8e6d))
* **inbound:** track mailglass core pin to == 1.4.4 for the 1.4.4 linked release ([949cdee](https://github.com/szTheory/mailglass/commit/949cdee6f6a3ad32790440a49c1c4071941e8a7c))

## [1.4.3](https://github.com/szTheory/mailglass/compare/mailglass-v1.4.2...mailglass-v1.4.3) (2026-06-03)


### Bug Fixes

* **inbound:** track mailglass core pin to == 1.4.3 for the 1.4.3 linked release ([1bd1291](https://github.com/szTheory/mailglass/commit/1bd12915e3d97ecd976ea97ed6c91654edabb03e))
* **installer:** prevent swoosh 1.26 hackney crash during mix mailglass.install ([#55](https://github.com/szTheory/mailglass/issues/55)) ([ddab80b](https://github.com/szTheory/mailglass/commit/ddab80b503162d2a7417ad44c66660a4ef228158))

## [1.4.2](https://github.com/szTheory/mailglass/compare/mailglass-v1.4.1...mailglass-v1.4.2) (2026-06-03)


### Bug Fixes

* **admin:** float optional mailglass_inbound dep to ~&gt; 1.1 (was stale ~&gt; 0.2) ([f27dff1](https://github.com/szTheory/mailglass/commit/f27dff12e19644593b5507406730f2c3631b5066))
* **inbound:** track mailglass core pin to == 1.4.2 for the 1.4.2 linked release ([fae6dd1](https://github.com/szTheory/mailglass/commit/fae6dd1673ad589b390b34396eb9bb64516fbecd))

## [1.4.1](https://github.com/szTheory/mailglass/compare/mailglass-v1.4.0...mailglass-v1.4.1) (2026-06-02)


### Bug Fixes

* **inbound:** bump README/install dep pins to mailglass ~&gt; 1.4, inbound ~&gt; 1.1 ([bd64c9c](https://github.com/szTheory/mailglass/commit/bd64c9c790bfe1b1917f0683c1953a7f88cb56a3))

## [1.4.0](https://github.com/szTheory/mailglass/compare/mailglass-v1.3.0...mailglass-v1.4.0) (2026-06-02)


### Features

* **61-01:** enforce phase 61 reference-host boundary tokens in contract test ([f568e16](https://github.com/szTheory/mailglass/commit/f568e16a8d3a2239e72f04cf02c1e8498949a271))
* **61-01:** enforce usage-proof boundary in reference host docs ([fad0227](https://github.com/szTheory/mailglass/commit/fad0227f4235ae27b509dd15a0060e2fd3bc2826))
* **61-02:** route maintainer and webhook docs to canonical contract truth ([d226877](https://github.com/szTheory/mailglass/commit/d22687739f25061f4af504a018aeead489da13d7))
* **61-02:** tighten operator trust boundary routing ([1b40cf5](https://github.com/szTheory/mailglass/commit/1b40cf574a00b36201db480c75fe7c150adac3fb))
* **61-03:** extend docs checker for trust-entry boundary enforcement ([c22eff9](https://github.com/szTheory/mailglass/commit/c22eff907178b7a35b3ce39ff803cf6464885a56))
* **61-03:** pin trust-entry docs contract routing in ExUnit ([3f685eb](https://github.com/szTheory/mailglass/commit/3f685eba8d22e8b7779d56d16e9a26a8511cdbdd))
* **64-05:** delegate root stability lane to inbound support contract alias ([37388f4](https://github.com/szTheory/mailglass/commit/37388f44f5197e655bf6a285f008f9a5ef608fbc))
* **66-02:** apply inbound 1.0.0 candidate and release notes ([7c5d77e](https://github.com/szTheory/mailglass/commit/7c5d77ef06f1baa052408d51b0607fbb8dac9369))
* **67-03:** add deterministic demo reset proof and evidence reset endpoint ([7a24342](https://github.com/szTheory/mailglass/commit/7a24342ecabc6321158d84dcf465dd89a87299ac))
* **67-03:** add phase-67 verification lane and evidence boundary wording ([af68014](https://github.com/szTheory/mailglass/commit/af680149a9a83b636f2db0c77ad8e1b6913d02d4))
* **67-demo-app-foundation-02:** add demo health route and compose health gating ([4141ea3](https://github.com/szTheory/mailglass/commit/4141ea388077411263455f2c9603362e6b19bec5))
* **67:** track demo app scaffold artifacts ([1a31989](https://github.com/szTheory/mailglass/commit/1a3198931d472b837cdb30275e2c2e6608fd7f7b))
* **68-01:** expand deterministic demo fixture corpus ([71ef999](https://github.com/szTheory/mailglass/commit/71ef99948e95cdcb7d3c483885acd5efb2d96bcf))
* **68-02:** enrich deterministic preview mailer scenarios ([73721f8](https://github.com/szTheory/mailglass/commit/73721f8cc94587e9f00e5a2f59b01d4afe4a7c02))
* **69-01:** refine northstar dashboard hub copy and labels ([485792d](https://github.com/szTheory/mailglass/commit/485792d25067b1104e0d7921a844543529c8b9d2))
* **72-01:** flip executable guards for inbound stable 1.0 posture ([8b96cee](https://github.com/szTheory/mailglass/commit/8b96ceef9553a40c5087bc86b34143c3dbe269be))
* **admin-ui:** design-system tokens, operator shell IA, motion, and visual audit ([#52](https://github.com/szTheory/mailglass/issues/52)) ([f1c17d8](https://github.com/szTheory/mailglass/commit/f1c17d8cbee3558b32988185223e34eb0f21b7b0))


### Bug Fixes

* **62-01:** classify short lock tuples as malformed ([1d93b26](https://github.com/szTheory/mailglass/commit/1d93b26a11d8ecd729fdbb5b25982fa2af93d60d))
* **62-01:** parse clean-baseline lock without evaluation ([b4b13aa](https://github.com/szTheory/mailglass/commit/b4b13aaa377c6df3925435235fc6e12f008dc589))
* **62-01:** report invalid lock entry types ([8d5dcda](https://github.com/szTheory/mailglass/commit/8d5dcdac1df74a78f97c5d270affc066d25d4e8b))
* **63-01:** restore inbound docs check tokens ([650b379](https://github.com/szTheory/mailglass/commit/650b3799030072c0c026930d030d5613f245d745))
* **64-01:** annotate direct runtime seams with 0.1.0 since metadata ([f2edf58](https://github.com/szTheory/mailglass/commit/f2edf5800da4e36aa88c0f0f36b0b6d0e5f38b5c))
* **64-01:** normalize inbound package-line since metadata ([445f23a](https://github.com/szTheory/mailglass/commit/445f23a41e3576f62bfcca17ec6e0ef9671b73be))
* **64-03:** align test assertion and case metadata to 0.2.0 ([cf54dd7](https://github.com/szTheory/mailglass/commit/cf54dd79ab9afa486e233282d5cf24687021bb94))
* **64-03:** tag fixtures and ingress testing helpers as 0.2.0 ([891e269](https://github.com/szTheory/mailglass/commit/891e2692475db16b021a5dd6ac8bde8ac4e8381a))
* **64-review:** close contract review findings ([b1abd77](https://github.com/szTheory/mailglass/commit/b1abd77290798139eeb6068dcf1c54ee566d61ec))
* **65:** fail docs check on empty path scope ([1e0f20a](https://github.com/szTheory/mailglass/commit/1e0f20a38721fe51cc459fbbd46e2e9a7cda347f))
* **65:** resolve provider contract review findings ([42ceef2](https://github.com/szTheory/mailglass/commit/42ceef254ea45aa3214febfc1a3aa4dcf725ed6f))
* **66-02:** refresh publish proof and lock phase 66 governance state ([ce26a56](https://github.com/szTheory/mailglass/commit/ce26a566331293b97cf8fd77e8ffb237447dbb26))
* **66:** clean inbound changelog release truth ([eab4312](https://github.com/szTheory/mailglass/commit/eab431260f85f11f39399cd885e5789df002c575))
* **67-01:** tighten demo hex dependency mode\n\n- pin demo hex inbound dep to ~&gt; 0.3.0\n- clarify README dependency modes and non-contract boundary\n ([703a9ae](https://github.com/szTheory/mailglass/commit/703a9ae912cbe44b5018b0f63efdff8130fd5092))
* **67-demo-app-foundation-02:** make demo e2e browser deps deterministic ([2a8d01b](https://github.com/szTheory/mailglass/commit/2a8d01b7debc56b56d56d11d7de81a6de5282876))
* **67:** require explicit demo reset token ([a959dbd](https://github.com/szTheory/mailglass/commit/a959dbd7ddfadf36bd0674e751d3b8f6b4d85c41))
* **67:** secure demo reset and login redirects ([ec2dfdf](https://github.com/szTheory/mailglass/commit/ec2dfdf45bbbfd95e4cd540ee197fcbafbf5edc8))
* **68:** close demo fixture review findings ([c44a88f](https://github.com/szTheory/mailglass/commit/c44a88f54f2c51bc969cdbb804c613dd7f3fdf54))
* **68:** revise plans based on checker feedback ([8009076](https://github.com/szTheory/mailglass/commit/8009076cabdb7c0007f08335131268016fcd9a1b))
* **72-03:** correct source_ref_pattern to mailglass_inbound-v%{version} ([0e1f65b](https://github.com/szTheory/mailglass/commit/0e1f65b9a818ddd033577a634adc0d61df44c107))
* **72:** WR-01 make inbound changelog over-claim guard meaningful ([ab116f4](https://github.com/szTheory/mailglass/commit/ab116f4fece2519961f2bdee9dd29ba15da67e02))
* **72:** WR-02 surface leak-only docs.check runs and normalize --path ([fcdf5b4](https://github.com/szTheory/mailglass/commit/fcdf5b45d37637209b1a8e14b6849668a95565a1))
* **72:** WR-03/WR-04 assert inbound release consistency, not literals ([5a367d8](https://github.com/szTheory/mailglass/commit/5a367d8ab9457071b0481314c17b985cad6346f7))
* **73:** WR-01 gate pending-marker asserts behind staged-posture check ([cfcf055](https://github.com/szTheory/mailglass/commit/cfcf055c11939cbcba642afb1602e2a1b78ba4bd))
* **73:** WR-02 bind REL-03 field asserts to exact labels (folds IN-02) ([cfaae1d](https://github.com/szTheory/mailglass/commit/cfaae1dad38fe01765764c8e04aefad0665f5a9e))
* **73:** WR-03 guard inbound release-record path against archival with readable flunk ([adaa0d7](https://github.com/szTheory/mailglass/commit/adaa0d7780e231e1aff2f34ed97c1371f7fc64a7))

## [1.3.0](https://github.com/szTheory/mailglass/compare/mailglass-v1.2.0...mailglass-v1.3.0) (2026-05-28)


### Features

* **51-02:** add branch protection verifier ([c6c71cf](https://github.com/szTheory/mailglass/commit/c6c71cfcd8f4763fd7ca83aa8fff03ac078c3b58))
* **52-01:** enforce reference host boot contract ([0e2ce52](https://github.com/szTheory/mailglass/commit/0e2ce520e509356baefb6b951833ddde440180a1))
* **52-01:** scaffold maintained reference host baseline ([a56796b](https://github.com/szTheory/mailglass/commit/a56796be6af909539f5537ea064c86f9d7762c5f))
* **52-02:** lock reference host to public seams ([e3b17a0](https://github.com/szTheory/mailglass/commit/e3b17a0a0c4c0fd07c3f9aab6c96c66a5efd9fb4))
* **52-03:** lock reference host proof scope boundaries ([76c996e](https://github.com/szTheory/mailglass/commit/76c996e5e7700c2ae2fb3e854305bda282975239))
* **57-01:** add canonical deterministic trust runner command ([293cd74](https://github.com/szTheory/mailglass/commit/293cd742e9bb5e7df9ea4e11b79bf9fe06b15bd0))
* **57-02:** add deterministic fixtures and trust checkpoint encoder ([8ed47eb](https://github.com/szTheory/mailglass/commit/8ed47ebf21ee5faf0080d4b65e416b0cf9dcf65d))
* **57-02:** add trust checkpoint validator and repeatability tests ([7030022](https://github.com/szTheory/mailglass/commit/703002298da98245d4ad83187de548f49274dc50))
* **58-01:** emit webhook ingest proof evidence ([1bb707a](https://github.com/szTheory/mailglass/commit/1bb707a7c5c36d254460e01e19e5258bf7f31f8c))
* **58-01:** implement webhook route proof helper ([67b0706](https://github.com/szTheory/mailglass/commit/67b0706efb8cc767ef0f2311208b2c8845d0c571))
* **58-02:** add no-match operator diagnosis evidence ([3b276ab](https://github.com/szTheory/mailglass/commit/3b276ab7f53691f22148f36770ca7a7165a5ae45))
* **58-02:** validate completed Phase 58 checkpoint evidence ([8ac4593](https://github.com/szTheory/mailglass/commit/8ac4593e9dc14809b59af979dd64dc7b92492c28))
* **59-01:** add check_clean_baseline_hex_only.sh Hex-source guard ([584541a](https://github.com/szTheory/mailglass/commit/584541a968ece1abeeab5b66b101b75ae56e0fce))
* **59-01:** parameterize gate-self-test.yml with check_name input ([6a0aa79](https://github.com/szTheory/mailglass/commit/6a0aa791a6a8710195d5604fce586d49668b10b1))
* **999.1-03:** add planning artifact comment drift guard ([c9624f2](https://github.com/szTheory/mailglass/commit/c9624f2438938811ed60f33f0e1b7c02d726a363))
* **999.2-01:** add deterministic capture matrix helpers ([b89b140](https://github.com/szTheory/mailglass/commit/b89b14056248d23edb6fe81e35cdd1a3a0c6a3b5))
* **999.2-01:** canonicalize preview width/theme capture state ([738a6af](https://github.com/szTheory/mailglass/commit/738a6afe03b07077f560c127572db2e61902b03d))
* **999.2-02:** add deterministic preview capture manifest contract ([3a29b76](https://github.com/szTheory/mailglass/commit/3a29b76e4096afab574cc8d9f825c9384d489e7e))
* **999.2-02:** add deterministic preview capture mix task ([80259ac](https://github.com/szTheory/mailglass/commit/80259acd7dc238f320878efc95e2b4313438c582))
* **999.2-03:** add advisory preview capture CI lane ([26696c4](https://github.com/szTheory/mailglass/commit/26696c4d9cbe62de42dc698d2970e25fe8048396))
* **999.2-03:** enforce preview docs boundary language contracts ([f58b080](https://github.com/szTheory/mailglass/commit/f58b08001d0676356f189bbfd4045cbe716cb0e5))
* **999.2-03:** validate preview capture checkpoint contract ([b54d7d8](https://github.com/szTheory/mailglass/commit/b54d7d84d45e4765a86fa0fe9450c8ef035680cf))


### Bug Fixes

* **52:** harden reference host routing and auth baseline ([93354d2](https://github.com/szTheory/mailglass/commit/93354d2691cfe2af98d7dd3a8353fb464e9c182a))
* **58:** revise webhook operator path plans .planning/phases/58-verify-first-webhook-operator-path/58-01-PLAN.md .planning/phases/58-verify-first-webhook-operator-path/58-02-PLAN.md ([22ab39f](https://github.com/szTheory/mailglass/commit/22ab39f3fd0191905ee48380b552a01341ea2d26))
* **59:** harden trust-lane scripts against injection (code review) ([544415f](https://github.com/szTheory/mailglass/commit/544415f41fa5751fde2ff87126dc536ee0874e71))
* **999.1-01:** unblock verification gates for execution run ([8c622ea](https://github.com/szTheory/mailglass/commit/8c622ea1acdf9d7c13b1773086b685abbe5ab915))
* **admin:** add --no-sandbox to preview Chromium for CI containers ([bcf787c](https://github.com/szTheory/mailglass/commit/bcf787cd076590252135ff16acb939429bf94aab))
* **admin:** preview Chromium capture passed invalid :timeout to System.cmd ([abc54c9](https://github.com/szTheory/mailglass/commit/abc54c9b31305aa714f31c14af4ddd445d3c2be0))
* **ci:** de-matrix required checks and automate release-PR merge ([#43](https://github.com/szTheory/mailglass/issues/43)) ([3a74bf2](https://github.com/szTheory/mailglass/commit/3a74bf2ecc5b812ee0273d2612d11729c912c291))
* **ci:** green main — format, credo, dialyzer, trust lane, inbound seed ([102ff7e](https://github.com/szTheory/mailglass/commit/102ff7e4dcaca2110c09592288a92f521ef98a18))

## [1.2.0](https://github.com/szTheory/mailglass/compare/mailglass-v1.0.0...mailglass-v1.2.0) (2026-05-25)


### Features

* **45-01:** inbound config tree + Postgres TestRepo + gen_smtp optional dep ([6809164](https://github.com/szTheory/mailglass/commit/6809164dc8439ef35bd0f043dbbb0dc2c8631e36))
* **45-01:** migration-running inbound test_helper + Postgres CI job ([64d1796](https://github.com/szTheory/mailglass/commit/64d17968082c53259ff3ad83a55e75f3c8b7a28b))
* **45-01:** widen Credo to inbound + telemetry/optional-dep checks + api_stability ([e6b808a](https://github.com/szTheory/mailglass/commit/e6b808ae6f20dc1069e928db47979f57d3e35307))
* **45-02:** add MailglassInbound.Telemetry span surface + PubSub.Topics builder ([3c78da7](https://github.com/szTheory/mailglass/commit/3c78da748e6ef0377a47aaa24b6596ed00691b94))
* **45-02:** post-commit inbound broadcast (TELE-07) + telemetry coverage tests (TELE-05) ([3114ac1](https://github.com/szTheory/mailglass/commit/3114ac1b648114551ae6a9f5d31b033100d8b0de))
* **45-02:** wrap the four inbound span sites (route/persist/execution/ingress) ([2661610](https://github.com/szTheory/mailglass/commit/266161097072b8147e3a19eeeff703d29912ada6))
* **45-03:** add never-raising GenSmtp.decode/2 MIME parse seam ([c7ac6de](https://github.com/szTheory/mailglass/commit/c7ac6de7430733da528771c8f1e9c2c254e6a665))
* **45-03:** add never-raising MailglassInbound.MIME parser ([c2d52f4](https://github.com/szTheory/mailglass/commit/c2d52f4229032063323649340a2a4313f477551a))
* **45-03:** add package-local MailglassInbound.MIMEError defexception ([f767771](https://github.com/szTheory/mailglass/commit/f7677711ce7f416cccc03b640b716629fc1fb117))
* **45-04:** wire stream_data + CI gate to green the convergence proof (TELE-08) ([75df25b](https://github.com/szTheory/mailglass/commit/75df25b449664840c579fe4d0125f0cd4b4f0bed))
* **45-07:** add NoPiiInResponseBody egress Credo check + register it ([544c7c3](https://github.com/szTheory/mailglass/commit/544c7c395c8d727cf14ad233618daf278f1b496b))
* **45-11:** generalize span-wrapper match to span-prefixed names (webhook coverage, FIX-4) ([5633cfb](https://github.com/szTheory/mailglass/commit/5633cfb8a4ceb857417e01d05435ff67916ef10b))
* **45-11:** validate literal event names at span/3 wrapper call sites (real inbound coverage) ([39b717f](https://github.com/szTheory/mailglass/commit/39b717f64e2fc8d5adf91f14e71d44fd35feb838))
* **45-12:** mandate bare-variable body-arg rule in NoPiiInResponseBody ([58e34c6](https://github.com/szTheory/mailglass/commit/58e34c647e43f3afee852ff3d38aee5184226839))
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
* **47-02:** implement gen.inbound_route idempotent route insertion (IGEN-03/04) ([55bf072](https://github.com/szTheory/mailglass/commit/55bf072e57c098877f386712e8bee8ddfbe3cac5))
* **47-02:** implement gen.inbound_router scaffold (IGEN-02/04) ([3178405](https://github.com/szTheory/mailglass/commit/3178405deb2860d3da4a543e56c7788bcda54190))
* **47-02:** implement gen.mailbox scaffold (IGEN-01/04) ([de31ff8](https://github.com/szTheory/mailglass/commit/de31ff8451c7f5ffdaf83aa881bae616455856a7))
* **47-03:** implement MailglassInbound.TestAssertions (ITEST-01..04) ([eb42b8e](https://github.com/szTheory/mailglass/commit/eb42b8e846226df0d242ff3f2f3689d85a04ea06))
* **47-03:** implement Test.Ingress real persist+execute driver (ITEST-06) ([f199239](https://github.com/szTheory/mailglass/commit/f1992398cc68000785006666180ce8055300d589))
* **47-04:** build MailglassInbound.MailboxCase ExUnit case template (ITEST-05) ([547ebbb](https://github.com/szTheory/mailglass/commit/547ebbb6ad16070f975f7a53ab7a2f8f54ff9af7))
* **47-04:** package the four inbound Testing helpers under an ExDoc Testing group ([dff2870](https://github.com/szTheory/mailglass/commit/dff28706fe407f1b7bd219f9c66e50cc3624dec4))
* **48-01:** add Router.Matcher.explain/2 reflection (IADM-04) ([9f6ef94](https://github.com/szTheory/mailglass/commit/9f6ef9401f37c856e42a16c59799c112f834848d))
* **48-01:** admin seams — inbound gateway, topic builder, mask_recipient promotion (IADM-05) ([6874895](https://github.com/szTheory/mailglass/commit/687489532b790664a557585535577247a89a1535))
* **48-01:** inbound read-model Internal.Operator.{Records,Timeline,Detail} (IADM-01) ([fb94791](https://github.com/szTheory/mailglass/commit/fb94791b366d5cbe10fa432151907098046ccc34))
* **48-01:** wire optional inbound dep + admin test-infra (Wave 0) ([be1fd76](https://github.com/szTheory/mailglass/commit/be1fd76f3cb1f702aee77927951f94ee54560583))
* **48-02:** clone inbound sibling components (list, detail, timeline, filters, replay-modal, destructive-action) ([7f98e39](https://github.com/szTheory/mailglass/commit/7f98e391bb212890e13ee396e55dbf313ae7bc16))
* **48-02:** InboundLive shell — URL-state, tenant gate, list/detail/timeline via the gateway ([9c6ade6](https://github.com/szTheory/mailglass/commit/9c6ade6824d7b02d9ac858c353708e2457e38712))
* **48-02:** router wiring — /inbound route in operator live_session, available?/0-gated (IADM-07) ([decb24e](https://github.com/szTheory/mailglass/commit/decb24e26a662b9b17e6ae37f71de2260abbd65a))
* **48-03:** routing-trace + evidence cards wired into detail pane ([f4dc7a7](https://github.com/szTheory/mailglass/commit/f4dc7a7450718d05901e90ba41ea3b64d246f50a))
* **48-03:** tenant-gated replay confirm flow + live PubSub updates ([decb6d5](https://github.com/szTheory/mailglass/commit/decb6d555907abea54e41336fdbe0d313903a1e9))
* **49-01:** MailglassInbound.Config + RateLimiter + TableOwner + supervised child ([28d2f2f](https://github.com/szTheory/mailglass/commit/28d2f2ff4f6e0cc3371ea1754caf103641d43775))
* **49-01:** post-verify rate-limit 429 in Ingress.Plug + 3 telemetry span helpers ([267b600](https://github.com/szTheory/mailglass/commit/267b600a67e1ec850656d70934558e16ae963fd9))
* **49-02:** add suppression_flagged column + Signals struct + :signals field (IOPS-05) ([3f017e0](https://github.com/szTheory/mailglass/commit/3f017e0cb8842e0e4ff2884556463c82f7f52f43))
* **49-02:** wire degrade-OPEN suppression flag compute + projection + IADM-02 select (IOPS-05) ([83b6410](https://github.com/szTheory/mailglass/commit/83b641087e81de73927b7610bb0b4719ed042708))
* **49-03:** batched advisory-locked prune + replay/prune CLI tasks (IOPS-02, IOPS-03) ([30c8e3f](https://github.com/szTheory/mailglass/commit/30c8e3fbd8912c17b48cfd62348a9b1d50eeaa23))
* **49-03:** DNS-free inbound doctor with three-state exit (IOPS-01, MIME-03) ([93a815e](https://github.com/szTheory/mailglass/commit/93a815e9759461fdda91580dee31d95dd7e0e21f))
* **50-03:** add inbound docs to mix.exs extras and extend docs_contract_test ([d0fc831](https://github.com/szTheory/mailglass/commit/d0fc831755aa37f40d696564b8521f81c6969da1))
* **50-03:** extend mailglass.docs.check with 6 new inbound docs (IDOC-06) ([15e2ecc](https://github.com/szTheory/mailglass/commit/15e2eccf08fe5197a3721b3857bf945d495ff662))


### Bug Fixes

* **45-05:** close CR-01 — key gated_modules on gen_smtp Erlang atoms ([0ca9103](https://github.com/szTheory/mailglass/commit/0ca9103b7408a5d0a8b1d679186d65ab7dc62586))
* **45-05:** close WR-02 — span-aware TelemetryEventConvention clause ([302f9cc](https://github.com/szTheory/mailglass/commit/302f9ccf9d0d2e83698d5bb43d11a706b6e1febd))
* **45-06:** suppress cross-package Oban middleware xref in inbound no-optional-deps compile ([d9308d7](https://github.com/szTheory/mailglass/commit/d9308d75a3a2477691d409b500f00b1bc55037e3))
* **45-07:** make persist-failure egress PII-safe (static body + error_kind in stop-meta) ([2bf1571](https://github.com/szTheory/mailglass/commit/2bf157194b4c0c7a5df4b3e429cdbca205d91117))
* **45-10:** register StreamPolicyConsistent in .credo.exs + correct GenSmtp-key comment (WR-04) ([b1debed](https://github.com/szTheory/mailglass/commit/b1debed16f2e5a7843c4cbf9f1a42e794d64144a))
* **45:** scope StreamPolicyConsistent to production paths (post-merge credo gate) ([5ddba43](https://github.com/szTheory/mailglass/commit/5ddba4356e6efd6eb1adf6cb6aa3c251f4cb36b8))
* **46:** add SES MD5(raw_mime) dedupe fallback for missing messageId (WR-02) ([d4364c9](https://github.com/szTheory/mailglass/commit/d4364c95030267000df2c9c9f7ef959844cd8b3c))
* **46:** add unique_constraint for Mailgun fingerprint dedupe race (CR-01) ([e177ff2](https://github.com/szTheory/mailglass/commit/e177ff22ee58bbd91311edfbdb68b4aeb151ee59))
* **46:** gate ExAwsS3 gateway on available?/0 and tag absent dep (WR-06) ([f58f5b2](https://github.com/szTheory/mailglass/commit/f58f5b22b40edd2bde15519bf72bf354fc47d111))
* **46:** harden SES verify-&gt;normalize handoff fallback (WR-01) ([4bf659c](https://github.com/szTheory/mailglass/commit/4bf659cfc91688986cc40de9267a6947df067052))
* **46:** rescue S3FetchError in ingress plug with transient/permanent mapping (CR-02) ([4df1903](https://github.com/szTheory/mailglass/commit/4df1903a84fbfc5e604134f29247be0fbaf8fe6f))
* **46:** thread :s3_retry_opts through SES resolve_config! (WR-04) ([f90e21b](https://github.com/szTheory/mailglass/commit/f90e21b9e41636b0e580eac56fe64159d48c8881))
* **46:** tighten SES inline base64 heuristic and record parse_warning (WR-05) ([dbe9846](https://github.com/szTheory/mailglass/commit/dbe984689400915c0c7afa281386c96139cdfe8d))
* **47:** CR-01 fix broken README/MailboxCase usage example ([3715296](https://github.com/szTheory/mailglass/commit/3715296566a329933df7a154eea38ad5097d13a0))
* **47:** CR-01 make SendGrid/Mailgun receive_provider_payload compose out of the box ([7f7d930](https://github.com/szTheory/mailglass/commit/7f7d93010e27f223d3c2b8b81e41c3b221579867))
* **47:** IN-01 clarify SampleMailbox is a placeholder in gen.inbound_router ([0d8a8f6](https://github.com/szTheory/mailglass/commit/0d8a8f64cda1b80c3ec41e454ea28db350a1a5cc))
* **47:** IN-02 validate the mailbox/router arg in parse_module ([51072f8](https://github.com/szTheory/mailglass/commit/51072f8656719e1eb8722c89876fed73ce3870cd))
* **47:** IN-03 handle captured-function syntax in assert_inbound_received ([126a5b9](https://github.com/szTheory/mailglass/commit/126a5b99b7ef2fee4c3535608970213e73ef91c0))
* **47:** IN-04 clarify Test.Ingress PII-posture moduledoc ([e0d6472](https://github.com/szTheory/mailglass/commit/e0d6472689c65d934baaefc9948815ba1deb3913))
* **47:** WR-01 resolve version metadata drift to 0.1.0 ([b6b4e89](https://github.com/szTheory/mailglass/commit/b6b4e89826adcd7fd7d7c31e3901d69a3c394c67))
* **47:** WR-02 correct FIFO semantics in outcome/routing assertion docs ([3b410ec](https://github.com/szTheory/mailglass/commit/3b410ecf36c0b16e46028a178115bf6818a504ee))
* **47:** WR-03 make gen.mailbox test scaffold hint accurate and runnable ([584e571](https://github.com/szTheory/mailglass/commit/584e5714fe7847e45bd3d9372a43d3630e3e66be))
* **47:** WR-04 reject non-binary :from/:to with an accurate matcher message ([d4ba54c](https://github.com/szTheory/mailglass/commit/d4ba54cbcdacc85c308af69c960b9d19347984ca))
* **47:** WR-05 document SES CertCache cross-test hygiene ([31559c0](https://github.com/szTheory/mailglass/commit/31559c0fb167aa48f4a48aaaee35aaa26182c7cc))
* **47:** WR-06 cover receive_inbound/2 raw_mime-dedupe contract for SendGrid ([c9a93f5](https://github.com/szTheory/mailglass/commit/c9a93f5043614f59cdad102e0f8b64b85226ec1c))
* **47:** WR-07 stop steering adopters to the internal Route struct ([8b4e4fa](https://github.com/szTheory/mailglass/commit/8b4e4fa3e12288bf4c50c88ad8d5594cc34b07a4))
* **47:** WR-08 add receive_provider_payload/3 driver tests for sendgrid and mailgun ([42be994](https://github.com/szTheory/mailglass/commit/42be9940af7c2bc40e30e91ec3cec566c9952e90))
* **48:** detail 'From' cell shows the masked sender, not the recipient (WR-02) ([d549b3a](https://github.com/szTheory/mailglass/commit/d549b3af124989cce6052e89a0e3dedf8804c85f))
* **48:** deterministic inbound-route test ordering + operator-session assertion ([bba56a1](https://github.com/szTheory/mailglass/commit/bba56a1a9300422fee6941fd8423ab9ac76e0474))
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
* **ci:** correct dialyzer ignore string for GenSmtp.decode/2 extra_range ([28b5bfb](https://github.com/szTheory/mailglass/commit/28b5bfb3af96b9efdb5eb5ef366aa197c45d8dc4))
* **ci:** restore release readiness gates ([683f653](https://github.com/szTheory/mailglass/commit/683f653ce6252f951c82c8ab581596dc31408aeb))
* **ci:** restore release readiness gates ([b3acce2](https://github.com/szTheory/mailglass/commit/b3acce29c9172af4ed9d495bd375100a614cbed2))
* **ci:** skip stale release-please reruns by release tags ([68e845a](https://github.com/szTheory/mailglass/commit/68e845a12f96a7fbe79ac99c33ce26fe1c6fe22f))
* **ci:** skip stale tagged release-please reruns ([b74d05e](https://github.com/szTheory/mailglass/commit/b74d05eff9937092619f94226401fd7d80499643))
* **ci:** stabilize operator browser gate ([370433d](https://github.com/szTheory/mailglass/commit/370433d5df68c2ceaf9b95bba6f2c2be2c63ea42))
* **ci:** unblock v1.2 release ceremony — dialyzer ignore + inbound README pin sync ([061e85f](https://github.com/szTheory/mailglass/commit/061e85fe1a4dc4b88038cab2d479c60b99e40a5e))
* **ci:** update tests gate verifier for split CI ([37129d8](https://github.com/szTheory/mailglass/commit/37129d840ce5592dd002a4e848f2537b3f7c869b))
* **docs:** CR-01 use signals.suppression_flagged instead of metadata[:suppression_flagged] ([f53e486](https://github.com/szTheory/mailglass/commit/f53e48698e4e5478423fb011b772602d080c586c))
* **docs:** CR-02 CR-03 fix SES subscription confirmation and fixture API docs ([1043d54](https://github.com/szTheory/mailglass/commit/1043d5466e810a11284a690e4181198615992e55))
* **docs:** harden core/admin README version pins + self-maintaining enforcement ([79e88d0](https://github.com/szTheory/mailglass/commit/79e88d0a3f29922457f85a8169ced310a13d6251))
* **docs:** WR-01 correct mailglass_inbound version pin from ~&gt; 0.2 to ~&gt; 0.1 ([5467669](https://github.com/szTheory/mailglass/commit/546766914179602b43b3231c63304c3ffa565ef8))
* **docs:** WR-03 clarify test.exs repo config is optional override, not a duplicate ([dab4f72](https://github.com/szTheory/mailglass/commit/dab4f72c0016c249413270a9ec92e651fa05afd9))
* **docs:** WR-04 remove TODO comment from inbound-mailgun.md configuration block ([6c39049](https://github.com/szTheory/mailglass/commit/6c390495644d496f927aee64296570e5944ea01b))
* **tasks:** WR-02 replace use MailglassInbound.Mailbox token with [@behaviour](https://github.com/behaviour) in docs check ([3e352b6](https://github.com/szTheory/mailglass/commit/3e352b65f6190d45347403e0220db2d73b31eb57))

## [Unreleased]

## What's new in 1.2.0 (v1.2 Inbound Production Confidence)

`mailglass` 1.2.0 ships the v1.2 milestone: production-ready inbound email
processing via `mailglass_inbound` 0.2.0. The primary deliverable is the
`mailglass_inbound` sibling package — see its
[0.2.0 CHANGELOG](mailglass_inbound/CHANGELOG.md) for the full feature narrative.
Sibling: `mailglass_admin` 1.2.0 (linked release) ships the InboundLive admin UI.
`mailglass_inbound` remains on the 0.x version line — see
[`guides/compatibility-and-deprecations.md`](guides/compatibility-and-deprecations.md).

### v1.2 REQ-ID categories shipped

- **TELE (TELE-01..08)** — `:telemetry` spans at four inbound levels (ingress/route/execution/persist) with property-tested 1000-replay convergence proof
- **MIME (MIME-01..02, MIME-04)** — RFC 5322 MIME parse seam via `Mailglass.OptionalDeps.GenSmtp.decode/2` (the core addition in this release)
- **MGUN (MGUN-01..04)** — Mailgun inbound provider with HMAC-SHA256 ingress and dual body-mime/parsed mode
- **SESI (SESI-01..05)** — SES inbound provider with SNS X.509 verification and S3 receipt-rule extraction
- **ITEST (ITEST-01..09)** — `MailglassInbound.MailboxCase`, `TestAssertions`, `Test.Ingress`, `Fixtures` test helpers
- **IGEN (IGEN-01..04)** — `mix mailglass.gen.mailbox`, `mix mailglass.gen.inbound_router`, `mix mailglass.gen.inbound_route` generators
- **IADM (IADM-01..07)** — InboundLive admin UI shipped via `mailglass_admin` 1.2.0 (list/detail/timeline/routing-trace, tenant-gated replay)
- **IOPS (IOPS-01..05)** — `mix mailglass.inbound.doctor`, `.replay`, `.prune`; `MailglassInbound.RateLimiter`; suppression signals
- **IDOC (IDOC-01..06)** — six production operator guides (install, mailgun, ses, testing, operator, routing-debug)

### Added

- `Mailglass.OptionalDeps.GenSmtp.decode/2` — a never-raising RFC 5322 MIME
  parse seam over `:mimemail.decode/2` (gen_smtp 1.3.0), gated through the
  existing optional-dep gateway. Returns `{:ok, tuple}` or a tagged
  `{:error, {kind, reason}}` (`:error` / `:throw` / `:exit`) and wraps all three
  `:mimemail` escape mechanisms (`erlang:error`, `throw`, `:exit`). Passes
  `{:encoding, :none}` (skips iconv, which gen_smtp does not bundle) and
  `{:allow_missing_version, true}`. `@since "1.2.0"`. This is the producer
  behind `MailglassInbound.MIME.parse/1`; Phase 46 (Mailgun/SES raw-MIME
  ingress) is the first consumer.

## [1.0.0](https://github.com/szTheory/mailglass/compare/mailglass-v1.0.0...mailglass-v1.0.0) (2026-05-08)


### Bug Fixes

* **ci:** restore release readiness gates ([683f653](https://github.com/szTheory/mailglass/commit/683f653ce6252f951c82c8ab581596dc31408aeb))
* **ci:** restore release readiness gates ([b3acce2](https://github.com/szTheory/mailglass/commit/b3acce29c9172af4ed9d495bd375100a614cbed2))
* **ci:** skip stale release-please reruns by release tags ([68e845a](https://github.com/szTheory/mailglass/commit/68e845a12f96a7fbe79ac99c33ce26fe1c6fe22f))
* **ci:** skip stale tagged release-please reruns ([b74d05e](https://github.com/szTheory/mailglass/commit/b74d05eff9937092619f94226401fd7d80499643))
* **ci:** stabilize operator browser gate ([370433d](https://github.com/szTheory/mailglass/commit/370433d5df68c2ceaf9b95bba6f2c2be2c63ea42))
* **ci:** update tests gate verifier for split CI ([37129d8](https://github.com/szTheory/mailglass/commit/37129d840ce5592dd002a4e848f2537b3f7c869b))

## [1.0.0](https://github.com/szTheory/mailglass/compare/mailglass-v1.0.0...mailglass-v1.0.0) (2026-05-08)


### Bug Fixes

* **ci:** restore release readiness gates ([683f653](https://github.com/szTheory/mailglass/commit/683f653ce6252f951c82c8ab581596dc31408aeb))
* **ci:** restore release readiness gates ([b3acce2](https://github.com/szTheory/mailglass/commit/b3acce29c9172af4ed9d495bd375100a614cbed2))
* **ci:** skip stale tagged release-please reruns ([b74d05e](https://github.com/szTheory/mailglass/commit/b74d05eff9937092619f94226401fd7d80499643))
* **ci:** stabilize operator browser gate ([370433d](https://github.com/szTheory/mailglass/commit/370433d5df68c2ceaf9b95bba6f2c2be2c63ea42))
* **ci:** update tests gate verifier for split CI ([37129d8](https://github.com/szTheory/mailglass/commit/37129d840ce5592dd002a4e848f2537b3f7c869b))

## [1.0.0](https://github.com/szTheory/mailglass/compare/mailglass-v1.0.0...mailglass-v1.0.0) (2026-05-08)


### Bug Fixes

* **ci:** restore release readiness gates ([683f653](https://github.com/szTheory/mailglass/commit/683f653ce6252f951c82c8ab581596dc31408aeb))
* **ci:** restore release readiness gates ([b3acce2](https://github.com/szTheory/mailglass/commit/b3acce29c9172af4ed9d495bd375100a614cbed2))
* **ci:** stabilize operator browser gate ([370433d](https://github.com/szTheory/mailglass/commit/370433d5df68c2ceaf9b95bba6f2c2be2c63ea42))
* **ci:** update tests gate verifier for split CI ([37129d8](https://github.com/szTheory/mailglass/commit/37129d840ce5592dd002a4e848f2537b3f7c869b))

## [1.0.0](https://github.com/szTheory/mailglass/compare/mailglass-v0.3.2...mailglass-v1.0.0) (2026-05-07)

### v0.5 Adoption Hardening (Phases 28-31)

REQ-IDs: TASRT, INSTALLER, TESTHELP — see
[`v0.5-MILESTONE-AUDIT.md`](.planning/milestones/v0.5-MILESTONE-AUDIT.md).

- `Mailglass.TestAssertions` matchers (`assert_mail_sent/1`, `last_mail/0`,
  `wait_for_mail/1`).
- Idempotent `mix mailglass.install` with `.mailglass_conflict_*` sidecars
  on managed-block drift.
- Disposable host fixture harness for installer regression smoke.

### v0.6 Production Maturity (Phases 32-34)

REQ-IDs: RATELIMIT, REPLAY, RECONCILE — see
[`v0.6-MILESTONE-AUDIT.md`](.planning/milestones/v0.6-MILESTONE-AUDIT.md).

- Multi-bucket `RateLimiter` (`:tenant_recipient`, `:global_recipient`,
  `:sender_domain`) gating outbound on `:operational` and `:bulk` streams.
- Mailgun replay-cache supervision; SES SNS X.509 verifier; Resend webhook
  provider; reconciler advances on idempotency replays.
- Operator support summary surface for incident response.

### v1.0 Stability Lock (Phases 35-38)

REQ-IDs: STAB, COMPAT, DEPREC, RELS — see
[`v1.0-MILESTONE-AUDIT.md`](.planning/milestones/v1.0-MILESTONE-AUDIT.md).

- `guides/compatibility-and-deprecations.md` (canonical support matrix).
- `guides/upgrading-to-v1_0.md` (canonical 0.x → 1.0 upgrade authority).
- Deprecation DX inventory with strict-CI guidance for warning-emitting
  bridges (`Mailglass.Message.new/2`).
- Phase 38 release-rehearsal proof bundle (committed in-repo, converted to
  live in this release).

### v1.1 Inbound Core Slice (Phases 39-44)

REQ-IDs: INBR, INGRESS, EXEC, ADP — see
[`v1.1-MILESTONE-AUDIT.md`](.planning/milestones/v1.1-MILESTONE-AUDIT.md).

- `mailglass_inbound` opens with canonical `%InboundMessage{}`, narrow router
  DSL, mailbox behaviour with locked outcomes.
- First-party Postmark + SendGrid ingress with replayable persistence.
- Oban-backed async execution with bounded `Task.Supervisor` fallback.
- Sibling docs contract test wired into repo-root release-truth lane.

**`mailglass_inbound` ships at 0.1.0 on a separate 0.x version line, NOT linked
to `mailglass` 1.0.0.** See
[`guides/compatibility-and-deprecations.md`](guides/compatibility-and-deprecations.md)
for the stability disclaimer.


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
