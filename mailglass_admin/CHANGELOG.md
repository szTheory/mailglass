# Changelog

All notable changes to `mailglass_admin` will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning coordinated with `mailglass` core via Release Please linked-versions.

## [2.6.0](https://github.com/szTheory/mailglass/compare/mailglass_admin-v2.5.0...mailglass_admin-v2.6.0) (2026-09-07)


### Features

* **163-02:** add gallery timeout attribution probes ([673b2d2](https://github.com/szTheory/mailglass/commit/673b2d20e4bf624cd9475c0b55c0c12e3d67914b))
* **164-03:** clarify current package compatibility\n\n- Mark each package README's current compatibility guidance\n- Document the linked core/admin and independent inbound constraints\n ([d272e82](https://github.com/szTheory/mailglass/commit/d272e824e92f11f09c4a060271cd1202837b3711))


### Bug Fixes

* **163:** bound recurrent primitive matrices ([f8bf029](https://github.com/szTheory/mailglass/commit/f8bf029faf87d8dda0ef1a36fe6ebbe6e2ab60d6))
* **163:** preserve protected browser ownership ([9d0bcac](https://github.com/szTheory/mailglass/commit/9d0bcacf875ad0c88155bd16bad2996c1c57b926))
* **163:** repair and capture gallery timeout ([7b9da5b](https://github.com/szTheory/mailglass/commit/7b9da5b7fa736542662fe8ea7ad76c8f9ea29cb0))
* **163:** repair protected browser timeout recurrences ([e8c6260](https://github.com/szTheory/mailglass/commit/e8c6260ff0f01fc88ed0b3b5241e4caf8584ccf2))
* **164:** close repository-truth security and validation gaps ([e79cd50](https://github.com/szTheory/mailglass/commit/e79cd50c04cd34961a7e60613e2067701cd173d4))
* **164:** CR-06 document production admin dependency ([cbdd37c](https://github.com/szTheory/mailglass/commit/cbdd37c9f89ca626ae936a7978b4ba99346e64a0))
* **164:** WR-01 align current contract major labels ([7897fb4](https://github.com/szTheory/mailglass/commit/7897fb4e5f67e5f157b2af9b1e89a7b910140790))
* **ci:** repair phase 164 protected gates ([5859cc7](https://github.com/szTheory/mailglass/commit/5859cc7ccb47dc49d41b94cf682286fc846a057b))

## [2.5.0](https://github.com/szTheory/mailglass/compare/mailglass_admin-v2.4.1...mailglass_admin-v2.5.0) (2026-08-20)


### Features

* complete v2.6 engineering quality ratchet ([#203](https://github.com/szTheory/mailglass/issues/203)) ([61e8c8e](https://github.com/szTheory/mailglass/commit/61e8c8e841306755ec637f84052f8dca4baadb76))

## [2.4.0](https://github.com/szTheory/mailglass/compare/mailglass_admin-v2.3.0...mailglass_admin-v2.4.0) (2026-08-02)


### Features

* ship B2C first-adopter readiness ([#165](https://github.com/szTheory/mailglass/issues/165)) ([53211e8](https://github.com/szTheory/mailglass/commit/53211e8bb9db2d2e16d5b2457868f2eefad249c5))

## [2.4.1](https://github.com/szTheory/mailglass/compare/mailglass_admin-v2.4.0...mailglass_admin-v2.4.1) (2026-08-03)

### Added

* Refresh outbound delivery lists, selected evidence, suppression state, and overview counters from tenant-scoped Mailglass events without a browser reload.

### Changed

* `mailglass_admin` now depends on `mailglass ~> 1.10` instead of an exact pin.
  Because admin is in the linked-versions release group with core, `~> 1.10` is
  safe — admin never resolves against a core minor it was not shipped with.

## [2.3.0](https://github.com/szTheory/mailglass/compare/mailglass_admin-v2.2.2...mailglass_admin-v2.3.0) (2026-07-31)


### Miscellaneous Chores

* **mailglass_admin:** Synchronize mailglass-sibling-group versions

## [2.2.2](https://github.com/szTheory/mailglass/compare/mailglass_admin-v2.2.1...mailglass_admin-v2.2.2) (2026-07-31)


### Miscellaneous Chores

* **mailglass_admin:** Synchronize mailglass-sibling-group versions

## [2.2.1](https://github.com/szTheory/mailglass/compare/mailglass_admin-v2.2.0...mailglass_admin-v2.2.1) (2026-07-29)


### Miscellaneous Chores

* **mailglass_admin:** Synchronize mailglass-sibling-group versions

## [2.2.0](https://github.com/szTheory/mailglass/compare/mailglass_admin-v2.1.3...mailglass_admin-v2.2.0) (2026-07-29)


### Miscellaneous Chores

* **mailglass_admin:** Synchronize mailglass-sibling-group versions

## [2.1.3](https://github.com/szTheory/mailglass/compare/mailglass_admin-v2.1.2...mailglass_admin-v2.1.3) (2026-07-28)


### Bug Fixes

* **deps:** patch new cowboy/cowlib advisories blocking the 2.1.2 publish ([#139](https://github.com/szTheory/mailglass/issues/139)) ([3c80ca8](https://github.com/szTheory/mailglass/commit/3c80ca805e6eedf8232817d3aa6e5786e364a669))

## [2.1.2](https://github.com/szTheory/mailglass/compare/mailglass_admin-v2.1.1...mailglass_admin-v2.1.2) (2026-07-28)


### Bug Fixes

* **admin:** clear the design-system and Dialyzer lanes blocking release ([#136](https://github.com/szTheory/mailglass/issues/136)) ([31588bb](https://github.com/szTheory/mailglass/commit/31588bb40343fc67200ca8bf4da7ffb3351248fa))
* **test:** make the citext probe honest and restore the suite baseline ([#137](https://github.com/szTheory/mailglass/issues/137)) ([579ad37](https://github.com/szTheory/mailglass/commit/579ad379bc979a78870f2f56ce865c19f44f6a20))

## [2.1.1](https://github.com/szTheory/mailglass/compare/mailglass_admin-v2.1.0...mailglass_admin-v2.1.1) (2026-07-28)


### Bug Fixes

* unblock the 2.1.0 publish — admin allowlist + 7 security advisories ([#134](https://github.com/szTheory/mailglass/issues/134)) ([eda8d00](https://github.com/szTheory/mailglass/commit/eda8d0032bf1976477c9f1bac18c4e1488ed57d7))

## [2.1.0](https://github.com/szTheory/mailglass/compare/mailglass_admin-v2.0.0...mailglass_admin-v2.1.0) (2026-07-28)


### Features

* operator Quick view + Full detail record inspection ([#128](https://github.com/szTheory/mailglass/issues/128)) ([7a68501](https://github.com/szTheory/mailglass/commit/7a6850146f606c3e82bcb50bc7c146c830caf0e1))

## [2.0.0](https://github.com/szTheory/mailglass/compare/mailglass_admin-v1.11.0...mailglass_admin-v2.0.0) (2026-07-04)


### Features

* **133-02:** add FACADE-04 schema-isolation integration test + fix admin test.exs schema pin ([70a3e07](https://github.com/szTheory/mailglass/commit/70a3e0715ec69c44f9977025f7dd4bab8aaddf0f))
* **133-02:** FACADE-03 admin zero-code-change render proof + D-08 bypass fix ([ee8e965](https://github.com/szTheory/mailglass/commit/ee8e965d54fd7bd2e86676c3e2cb0d4f697841b3))


### Bug Fixes

* **137:** migrate inbound tables via programmatic installer in browser harness ([5267fe4](https://github.com/szTheory/mailglass/commit/5267fe47c8a4e663dfea07c5520bd38e776c2df2))
* **admin-test:** migrate inbound tables into admin test DB + pin inbound schema ([57237e6](https://github.com/szTheory/mailglass/commit/57237e618c5728c75985ac119edd13f2c79efafc))

## [1.11.0](https://github.com/szTheory/mailglass/compare/mailglass_admin-v1.10.2...mailglass_admin-v1.11.0) (2026-07-02)


### Features

* **125-01:** loosen sibling pins from == to ~&gt; (keystone atomic change) ([37dcaf1](https://github.com/szTheory/mailglass/commit/37dcaf11dfa1cea1f59ac7f247d71ff8bf9943bf))
* **128-01:** add sibling-local ci/ci.fast aliases in admin + inbound ([dae016d](https://github.com/szTheory/mailglass/commit/dae016d9863db2d6aa3baa84fd073b3849286b5e))

## [1.10.2](https://github.com/szTheory/mailglass/compare/mailglass_admin-v1.10.1...mailglass_admin-v1.10.2) (2026-06-30)


### Miscellaneous Chores

* **mailglass_admin:** Synchronize mailglass-sibling-group versions

## [1.10.1](https://github.com/szTheory/mailglass/compare/mailglass_admin-v1.10.0...mailglass_admin-v1.10.1) (2026-06-30)


### Bug Fixes

* **deps:** bump admin + inbound deps to clear the EEF security advisory wave ([29a6155](https://github.com/szTheory/mailglass/commit/29a6155d854f9fcf3225e2f6afc68bdc67f4c161))

## [1.10.0](https://github.com/szTheory/mailglass/compare/mailglass_admin-v1.9.0...mailglass_admin-v1.10.0) (2026-06-29)


### Features

* **119-01:** scaffold Wave-0 e2e assertions for drill-through + orientation strip ([f42d225](https://github.com/szTheory/mailglass/commit/f42d2255d682ee35fbe9a89e087015053db6d93d))
* **119-01:** SHELL-01 Overview nav identity + active-state fix (TDD GREEN) ([b4fc5a0](https://github.com/szTheory/mailglass/commit/b4fc5a0cf9a08d7f3f916b54140f56db3babdd6b))
* **119-01:** SHELL-02 delete Navigate block + drill-through health + orientation gate (TDD GREEN) ([3d7899a](https://github.com/szTheory/mailglass/commit/3d7899a8c5823e77cc2ed903efb2549f1a76c7ec))
* **119-01:** SHELL-03 triage subtitle + calm copy + inbound_live overview_path fix (TDD GREEN) ([3c2feb0](https://github.com/szTheory/mailglass/commit/3c2feb0d7954ea53889cb50b3cb1d5227f8254e7))
* **119-02:** arm both judgment gates — flip test.fixme→test + fix aria-current assertion (D-09) ([1d12b67](https://github.com/szTheory/mailglass/commit/1d12b673ff49a3744c89472d7eaaf5a285426861))
* **120-01:** gate Deliveries to single-calm-pane on genuine no-data ([b8ab569](https://github.com/szTheory/mailglass/commit/b8ab569802e37a0347cabbc83cc740a470007ddc))
* **121-01:** gate inbound else-branch into no-data/no-match/populated cond ([dd8e4c1](https://github.com/szTheory/mailglass/commit/dd8e4c1f14b642784e5db177576be63195ebcfb4))
* **121-02:** re_redact_raw handler + PII-free reveal telemetry (D-11/D-12) ([082e1a9](https://github.com/szTheory/mailglass/commit/082e1a9727e96789de355bd72d3522ff18a62897))
* **121-02:** reveal disclosure ARIA + re-redact button + aria-live region (D-11) ([10a5281](https://github.com/szTheory/mailglass/commit/10a5281556be4234a7824212ca89004247fe7c05))
* **121-03:** add Tab/Shift+Tab focus-trap to both replay modals (D-14, lockstep) ([9aee4cf](https://github.com/szTheory/mailglass/commit/9aee4cfcaed6fd8911e2b92984861a5c1db55282))
* **121-03:** double-submit pending-lock on both replay Confirm buttons (D-14) ([8cc386b](https://github.com/szTheory/mailglass/commit/8cc386b8181a25ed59ddab81f717fe7355baf700))
* **122-01:** adopt theme_picker for Preview admin chrome via frame-aware path ([fc59dfb](https://github.com/szTheory/mailglass/commit/fc59dfb1bef4e3ab08483ff5c56f2319ae55b3fb))
* **122-01:** harden email-backdrop toggle a11y (aria-pressed + label + aria-live) ([4f188aa](https://github.com/szTheory/mailglass/commit/4f188aa12c96b76bfb38b1b340fc06eb7b4c5600))
* **122-02:** generalize render-error card copy + error-transition a11y ([ca376fb](https://github.com/szTheory/mailglass/commit/ca376fb306e3ef88dc286a19cc646fba31bd17cf))
* **122-02:** re-voice empty-mailables onboarding + remove dead dark_chrome attr ([a7edcbf](https://github.com/szTheory/mailglass/commit/a7edcbfddfc5be3374985cc7289dc75bfbd4a53b))
* **123-01:** promote + re-score 54-cell aesthetic ratchet baseline ([fcd5738](https://github.com/szTheory/mailglass/commit/fcd57384d6d50aad875ae2f1d75e2fc2c937c951))


### Bug Fixes

* **119-02:** rewrite VERIF-02 — drop deleted operator-overview-nav assertion (D-09) ([b3e98af](https://github.com/szTheory/mailglass/commit/b3e98af37a6b7c6f1f72a3e7cc6fa8ff71da999c))
* **121-01:** data_state must not hijack a loaded records list (D-09) ([a55eb5f](https://github.com/szTheory/mailglass/commit/a55eb5f1ea51578cdbf0a64e9dbc88943b2df945))
* **121-01:** inbound truly-empty body uses the InboundMessage noun (D-07) ([bf91f8e](https://github.com/szTheory/mailglass/commit/bf91f8e81b6615ba80da67286f6c46577fd243fe))
* **122:** IN-01 standardize onboarding code chips on font-mono ([94a6d5a](https://github.com/szTheory/mailglass/commit/94a6d5a1b76fd563ea6e599d14cc1f147b39e676))
* **122:** IN-02 re-voice start-page legend to the control's own noun ([78979bb](https://github.com/szTheory/mailglass/commit/78979bb96324645ec8e42b48662fe9902cf327fc))
* **122:** IN-03 document :admin_chrome_theme precedence contract ([d825d10](https://github.com/szTheory/mailglass/commit/d825d108cb8d2f2b140c47debc0e373f5846a102))
* **122:** IN-04 give preview theme_picker an explicit stable name ([4509c87](https://github.com/szTheory/mailglass/commit/4509c870b8606c77a13a2a634f685ee1112d2e6a))
* **122:** WR-01 scope render-error aria-live to sr-only announce span ([f9015d1](https://github.com/szTheory/mailglass/commit/f9015d18ae807d437885d3761c39788e60425e0b))
* **122:** WR-02 derive preview theme mount base instead of /dev/mail literal ([6a31e99](https://github.com/szTheory/mailglass/commit/6a31e990cdb3896fcdbf1a6c325820ecf9ba3d43))
* **122:** WR-03 add merge_assigns catch-all clause for non-map params ([2ecaf1e](https://github.com/szTheory/mailglass/commit/2ecaf1eeff794c9a83fcc75779d960c5582294a0))
* **admin:** align operator browser gate specs to the v1.14 redesign contract ([8a10e58](https://github.com/szTheory/mailglass/commit/8a10e5842ae502ec1b51f57933643d7af56cc3aa))
* **admin:** expose true ARIA state on preview backdrop toggle + inbound reveal disclosure ([c8b1996](https://github.com/szTheory/mailglass/commit/c8b1996047a47cee52b15025a8075ed3c786b201))
* **admin:** narrow re-redact button to px-sm to fix CI gallery overflow ([8bfb7ac](https://github.com/szTheory/mailglass/commit/8bfb7ac50e0c2b697e559a101f65089eb23297f5))
* **admin:** wrap revealed raw-payload pre to prevent CI horizontal overflow ([fb36456](https://github.com/szTheory/mailglass/commit/fb364564cf9696a6bc29c88d0ea7e336cc87539e))
* **deps:** bump plug to 1.19.3 for CVE-2026-54892 (HIGH) ([fc17fdf](https://github.com/szTheory/mailglass/commit/fc17fdfd05f2080301986fec14b1b26671ce09d4))

## [1.9.0](https://github.com/szTheory/mailglass/compare/mailglass_admin-v1.8.0...mailglass_admin-v1.9.0) (2026-06-26)


### Features

* **admin:** fold post-117 admin polish + fix the release-blocking demo reset race ([#91](https://github.com/szTheory/mailglass/issues/91)) ([5bba33c](https://github.com/szTheory/mailglass/commit/5bba33ccaed46f14d9ac1314ab829c6fdb10841e))

## [1.8.0](https://github.com/szTheory/mailglass/compare/mailglass_admin-v1.7.0...mailglass_admin-v1.8.0) (2026-06-21)


### Features

* **109-02:** add semantic admin layer utilities ([2340690](https://github.com/szTheory/mailglass/commit/2340690826b2465277193d3c771a1ff112a71b16))
* **110-01:** add public primitive components ([0a6a51f](https://github.com/szTheory/mailglass/commit/0a6a51fe7915137a676faf169d3b57ce0946cb6a))
* **110-02:** migrate overview stats to stat_card ([f452633](https://github.com/szTheory/mailglass/commit/f4526333679d155f8d3bcac4e4163dd069524784))
* **110-02:** migrate shell to public primitives ([5c2d688](https://github.com/szTheory/mailglass/commit/5c2d68883f61ff4eb24f995bbe744be352d5a25a))
* **110-02:** route shell theme picker events ([d71bfa9](https://github.com/szTheory/mailglass/commit/d71bfa9108a063cda7661f86ad1261b2f30e48cc))
* **110-03:** expand primitive gallery states ([8f2a2a0](https://github.com/szTheory/mailglass/commit/8f2a2a00409c2ffada96e9ea92a448c3bb581080))
* **110-03:** render public primitives in gallery ([5587de1](https://github.com/szTheory/mailglass/commit/5587de1961831d9da89bd0fde2e2228b37fb3ba0))
* **111-01:** complete filter primitive state rendering ([e00b624](https://github.com/szTheory/mailglass/commit/e00b62454822296ccdf0903a5b4e0036a5eee46e))
* **111-01:** implement public filter primitives ([b7db845](https://github.com/szTheory/mailglass/commit/b7db84502039024b25a323a06cc984994fd000ac))
* **111-02:** add filter recovery errors ([a2f1cad](https://github.com/szTheory/mailglass/commit/a2f1cadca82c0f45d27cd5daab0c0990a77cdfbc))
* **111-02:** migrate filter wrappers to shared primitives ([84f7316](https://github.com/szTheory/mailglass/commit/84f731646467b54c0019ff22c0195f73cf9db116))
* **111-03:** label preview assigns controls ([50f6d28](https://github.com/szTheory/mailglass/commit/50f6d28ec64c79714122f7237a0c1e6c9aa75d51))
* **111-03:** label replay target controls ([4102d1c](https://github.com/szTheory/mailglass/commit/4102d1c6e8c262d5f20323892aaca11249a32a1b))
* **111:** certify filter_field/filter_section gallery specimens + e2e form-layer proof ([b07036f](https://github.com/szTheory/mailglass/commit/b07036f808d9495b1c069890bb86e77239840f05))
* **112-01:** implement scoped tenant selector seam ([d74b47b](https://github.com/szTheory/mailglass/commit/d74b47bbde226f3039dcfff0f91b4061beda4fbb))
* **112-02:** wire tenant selector state into admin shell ([3342ba2](https://github.com/szTheory/mailglass/commit/3342ba20ea265b0efbfd7acea6cce10cd47d1a62))
* **112-03:** implement theme cookie root seam ([d5418f2](https://github.com/szTheory/mailglass/commit/d5418f212504974636c0f52dae3ce2e0945b034a))
* **112-03:** route theme picker through persistence ([f4337ef](https://github.com/szTheory/mailglass/commit/f4337ef356a0a3762150f905ce5fe6e518362f85))
* **112-04:** add structural active cue to nav pills ([08b25b6](https://github.com/szTheory/mailglass/commit/08b25b6406772a52413ba837d0e1c2d71ec53afb))
* **112-05:** add read-model pagination metadata APIs ([4c78d23](https://github.com/szTheory/mailglass/commit/4c78d23fdef46ec4bb67814d4c6f74f380a8c6b5))
* **112-06:** wire honest pagination and shell gates ([781c75e](https://github.com/szTheory/mailglass/commit/781c75e434da65f55840977de674ddb58602c518))
* **113-01:** add public Components.data_state/1 with four distinct kinds ([78cd04b](https://github.com/szTheory/mailglass/commit/78cd04b4e2cdfa3829fd96fbef349585234a47df))
* **113-01:** embed inbox, lock-closed, clock outline SVGs in heroicons-inline.js ([06341e5](https://github.com/szTheory/mailglass/commit/06341e5da5f95d1b29d16b80d07e193cfdbd9647))
* **113-02:** dual table+card delivery presentation with four data-state branches and long-value handling ([532a8b1](https://github.com/szTheory/mailglass/commit/532a8b1748ebbda35496263624c5e7c8b948cf19))
* **113-03:** upgrade inbound records_list to dual table+card, four data-state branches, KPI certification ([ef049c4](https://github.com/szTheory/mailglass/commit/ef049c484e0c8f957d40588aa71268c5542e5148))
* **113-04:** add Phase 113 gallery specimens — data_state, deliveries_list, records_list, long-value stress ([9a70caa](https://github.com/szTheory/mailglass/commit/9a70caac49d190335dabc6e1c1ddb6f446e2c506))
* **113-04:** extend conformance gates, rebuild bit-clean CSS bundle, update stale copy assertions ([ee01e6a](https://github.com/szTheory/mailglass/commit/ee01e6a83f64ebd433d7d46f0a26112c7b98a925))
* **113-04:** extend structural spec with responsive/overflow/status/data-state proof and migrate legacy consumers ([c5f7d03](https://github.com/szTheory/mailglass/commit/c5f7d03b66125464809036b35bba13f454a4ab4e))
* **114-01:** add SPACE-GATE + GROUP-GATE + card to conformance gates ([b6c95a0](https://github.com/szTheory/mailglass/commit/b6c95a07f4fe14f8214aa3d8d99d290bad09b2cf))
* **114-01:** extract thin &lt;.card&gt; shell primitive into Components ([63c8e4a](https://github.com/szTheory/mailglass/commit/63c8e4ab5d00bc142ea47e907df6a0f6b3211757))
* **114-02:** add data-region to operator + inbound detail-column wrappers ([1c953a6](https://github.com/szTheory/mailglass/commit/1c953a694186311351d209c922393f601f9870d8))
* **114-02:** add three public composed-group fns + gallery specimens ([4b67928](https://github.com/szTheory/mailglass/commit/4b67928a65b971f0bf90f69242c6a98cae361f87))
* **114-03:** swap 7 group shells to &lt;.card&gt; + sweep spacing ([0b6c966](https://github.com/szTheory/mailglass/commit/0b6c9663d2bee40615a9d0a52dd80dec1f0f9a53))
* **115-01:** align shell tenant copy verbatim, patch 320px header, remove theme-picker transition ([b3ff46f](https://github.com/szTheory/mailglass/commit/b3ff46f8709391cfbadec067a3818ba3a5aa09f2))
* **115-01:** replace deliveries + inbound list state copy with locked verbatim strings ([9728250](https://github.com/szTheory/mailglass/commit/97282501e224d158086f372752e49540c3aaf353))
* **115-02:** add origin-aware overlay var + state-layer transition scoping + overscroll-contain ([7c934b4](https://github.com/szTheory/mailglass/commit/7c934b4de535405691dccc574be7b18d034367ec))
* **115-02:** guard replay-modal scroll-chaining; keep centered origin ([a6e7d48](https://github.com/szTheory/mailglass/commit/a6e7d48c9b45c30c793d1e907f90ff6106185649))
* **115-03:** add VOICE-GATE + MOTION-GATE origin/theme checks to conformance ([1d1e8c3](https://github.com/szTheory/mailglass/commit/1d1e8c3366dd72d9a7dfd82bff669c9f3df614bd))
* **115-04:** add FLOW e2e walk + structural motion/320 specs; patch 320px overflow ([a92860f](https://github.com/szTheory/mailglass/commit/a92860fbadb9884620655895646c5e9141d86aad))
* **116-01:** admin-side seed_persona_cohort!/0 + cohort integration test ([039a9da](https://github.com/szTheory/mailglass/commit/039a9da64ff4c9d8eb180d642bb44f78bb9370c9))
* **116-02:** add axe producer spec + 9-cell WCAG 2.2 AA baseline JSON ([b03536e](https://github.com/szTheory/mailglass/commit/b03536eb0eb7bf6dda56f854d16160842d682fdf))
* **116-02:** add fail-closed ExUnit axe comparator (D-04) ([3335e3a](https://github.com/szTheory/mailglass/commit/3335e3a796ef7988e0f017c37e0025c11fae9bd1))
* **116-03:** add four binary interaction-pillar gates (RATCHET-03) ([fc053e5](https://github.com/szTheory/mailglass/commit/fc053e5174a5cfea130e2b86a93f577059c25897))
* **116-04:** mirror fjordline-aps stress specimens in the gallery ([8dd4a2a](https://github.com/szTheory/mailglass/commit/8dd4a2aa2f770957f4cd7e6b1ff7b118cd4e88bb))
* **116-04:** RATCHET-02 gallery-matrix resize-loop overflow gate ([03cf185](https://github.com/szTheory/mailglass/commit/03cf185b7a6ff64879b432f1333b06343269648f))
* **116-05:** add A11 TABLE-OVERUSE-GATE count-must-not-increase floor ([89d62d9](https://github.com/szTheory/mailglass/commit/89d62d9a7ba4ffe9337da8f2c04cd1bba1c9ddfc))
* **116-05:** executable fail-closed Bucket-A coverage manifest + human ledger mirror ([2e70e63](https://github.com/szTheory/mailglass/commit/2e70e63f009064dd56fd7679af8aabc16e289d11))
* **116-06:** promote + re-score the 54-cell aesthetic baseline (RATCHET-04) ([804d704](https://github.com/szTheory/mailglass/commit/804d704f6b8c9a029ff54a2b7af5685b92f0f1df))
* **116-06:** promote the 9-cell axe baseline; all three comparators green (RATCHET-04) ([26dc041](https://github.com/szTheory/mailglass/commit/26dc04147db24e1b5feea65dfb6ccf89708a06a5))


### Bug Fixes

* **111-03:** use bundled replay radio class ([ac1e110](https://github.com/szTheory/mailglass/commit/ac1e110da1e9f589aec6d32eed720b39dc9facf3))
* **111:** resolve wave 2 form gate drift ([f5ef9f7](https://github.com/szTheory/mailglass/commit/f5ef9f7357c15d11e32b89e47fa020a24e04e0e3))
* **114-03:** demote support_cards box-prison + swap to &lt;.card&gt; + sweep ([aed80a7](https://github.com/szTheory/mailglass/commit/aed80a77d7e6a2f8bbad9a83a73add81ed93f986))
* **115-01:** align tenant-selector copy to locked FLOW-04 verbatim across operator overview + tests ([5e09a74](https://github.com/szTheory/mailglass/commit/5e09a74a6fd78356c2180373988d54255114ca44))
* **115-01:** sync gallery data_state specimens to locked FLOW-04 copy ([678bba5](https://github.com/szTheory/mailglass/commit/678bba5cdff032995fd2e07a79b23d7cd10d92f4))
* **116:** IN-01 cite A24 by stable STATCARD-GATE name instead of the brittle do: em-dash token ([f3f447b](https://github.com/szTheory/mailglass/commit/f3f447bb44e74a7547962e0aeedc8c08c405bb83))
* **116:** IN-02 cross-check fjordline specimen states against gallery-matrix STRESS_CELLS ([83dfd1a](https://github.com/szTheory/mailglass/commit/83dfd1a199fecfd13597e23c0566f3ccc15e0e90))
* **116:** IN-03 fail ICON-EXISTS-GATE loud when zero hero-* usages are scanned (path/scan error) ([ec38634](https://github.com/szTheory/mailglass/commit/ec386349d59777fe8b393e9f5f6c023a48195a8a))
* **116:** WR-01 make axe producer run_id unique per invocation ([705c6a6](https://github.com/szTheory/mailglass/commit/705c6a6bcdb2e2fbde92b62959683d89f710c914))
* **116:** WR-01/IN-04 regenerate axe baseline from a real producer run ([5c32f7e](https://github.com/szTheory/mailglass/commit/5c32f7e4ebffd7a2b2d0ddcd11dbdcf1b9c8a23d))
* **116:** WR-02/WR-03 enforce A16-axe system&lt;=dark parity and fail closed on a non-map rules cell ([3c3bac2](https://github.com/szTheory/mailglass/commit/3c3bac2a4c551bc9f10f41276f053b972a6eebb4))
* **116:** WR-02/WR-03 make persona drift-guard tests exercise the real property ([e72697f](https://github.com/szTheory/mailglass/commit/e72697f10debf78ed15fb8430bd4dfa96ea107aa))
* **116:** WR-04 fail the axe producer when a required overlay won't open ([296adf6](https://github.com/szTheory/mailglass/commit/296adf6a8691b102c769e946e831d9be866acc64))
* **116:** WR-05 match payload kind explicitly in admin persona materializer (fail-closed) ([be9130d](https://github.com/szTheory/mailglass/commit/be9130d6025df9a958d9f155ef21d550170c0e54))
* **admin:** add focus ring to mobile detail-back buttons ([d81b586](https://github.com/szTheory/mailglass/commit/d81b58660e1351e598ac49659f25f84e9457d59e))
* **admin:** build absolute mount-aware URLs for preview nav + assets ([65e5d2a](https://github.com/szTheory/mailglass/commit/65e5d2ad6300775320dfdc7fdcdc396939524599))
* **admin:** keep preview frame theme independent of admin chrome toggle ([70f69f8](https://github.com/szTheory/mailglass/commit/70f69f8acf94eea2bc697f2475570a38db3869de))
* **admin:** preview mount-aware URLs + operator tenant/theme/stat-card UI fixes ([766edf8](https://github.com/szTheory/mailglass/commit/766edf896befd713a46537c16ac1fb3ab5c695a6))
* **admin:** repair operator tenant scope, theme, and stat-card UI defects ([9286623](https://github.com/szTheory/mailglass/commit/928662368201c8a7b6fa46d14a1b22196f2485be))

## [1.7.0](https://github.com/szTheory/mailglass/compare/mailglass_admin-v1.6.2...mailglass_admin-v1.7.0) (2026-06-17)


### Features

* **100-01:** split preview admin chrome theme ([5542fdb](https://github.com/szTheory/mailglass/commit/5542fdbea85302e9d2fd2da354640b4758e785dd))
* **100-02:** compose responsive preview surface ([bd61aab](https://github.com/szTheory/mailglass/commit/bd61aab37366ca94de674e87f46bd229ba5aa8a5))
* **101-02:** extend voice_test.exs to cover all 3 admin surfaces ([7f5d767](https://github.com/szTheory/mailglass/commit/7f5d767e42fc0a80a4400f8921e65784812b13d2))
* **102-01:** add MOTION-GATE to check-conformance.sh ([f9e6c7e](https://github.com/szTheory/mailglass/commit/f9e6c7e15528624b7a5fc34c2e037302a04fe433))
* **102-01:** extend structural.spec.js with reduced-motion duration + enter/exit asymmetry assertions ([d8e9f52](https://github.com/szTheory/mailglass/commit/d8e9f52dfa366eee08059b077232c481a3579cd6))
* **102-02:** add --ease-symmetric token; point tab-swap at it; document MOTION-LD-06 resolution ([efea4cd](https://github.com/szTheory/mailglass/commit/efea4cd74697bed44c9728e876682646461ab7ae))
* **102-02:** add .mg-skeleton connection placeholder + [@view-transition](https://github.com/view-transition) PE; rebuild bundle ([5f8cbb8](https://github.com/szTheory/mailglass/commit/5f8cbb8ec03d75bf03f83851203624fc8f96c01d))
* **102-03:** add phx-remove exit transitions to detail panes and modals; standardize focus duration ([768dc7f](https://github.com/szTheory/mailglass/commit/768dc7f65ae59106c9b2b93bb78176551bec7ba5))
* **102-03:** MOTION-LD-12 reveal on preview CTA; un-skip enter/exit asymmetry; rebuild bundle ([eb6e150](https://github.com/szTheory/mailglass/commit/eb6e15081a05c5801629a965ced6b7bef41aa1ee))
* **103-02:** activate only-forward ratchet with schema-2 baseline and fresh re-score ([81db7e5](https://github.com/szTheory/mailglass/commit/81db7e509ee2d89ae5b1a84f16a4f7aa3ebe18cd))
* **107-01:** add Escape-to-close + real ids on inbound replay modal ([8feb0b1](https://github.com/szTheory/mailglass/commit/8feb0b1d2c93e2faa3321ffe8c5b766b644769f9))
* **107-01:** add focus-management sibling span to inbound_live.ex ([b9bfbfd](https://github.com/szTheory/mailglass/commit/b9bfbfd55e46bd62acf5696c12029833415c3f51))
* **95-02:** add ratchet_baseline_test.exs and placeholder ui-baseline-scores.json ([e886b81](https://github.com/szTheory/mailglass/commit/e886b816f3db06cc7c16e321b24a1d46525bf1a0))
* **95-03:** add structural.spec.js — 6 D-01 pillar facts × 3 surfaces ([6d1e7dc](https://github.com/szTheory/mailglass/commit/6d1e7dc30500286342d46a6386e225d0602e7c2b))
* **95-04:** seed LLM-scored baseline in ui-baseline-scores.json ([71e9817](https://github.com/szTheory/mailglass/commit/71e9817ef19846df1f28ef63e2d944ef345cf8f6))
* **97-01:** add focus-visible rings to nav_link and nav_pill ([9240691](https://github.com/szTheory/mailglass/commit/9240691b6154760d65082fb32f020a44e4553631))
* **97-01:** replace orientation_strip copy with domain-noun strings ([526aa68](https://github.com/szTheory/mailglass/commit/526aa68782c39e4ea4604e7a4ef5c624225f5271))
* **97-02:** add row focus ring + fix text-xl → text-heading on both detail_headers ([72eb261](https://github.com/szTheory/mailglass/commit/72eb261bf2f997cc783f6bd46563c73264764887))
* **97-02:** remove btn-sm from support_cards CTA buttons, add min-h-11 ([b5ee6cf](https://github.com/szTheory/mailglass/commit/b5ee6cf06bd725aee45ba44cd6a0c663430b949f))
* **97-02:** remove tracking-[0.08em] from all five filters_form label spans ([4548aa2](https://github.com/szTheory/mailglass/commit/4548aa28f862d7ca0efbd37b535ac7a207115293))
* **97-03:** add WCAG a11y attributes to replay_modal dialog ([7692507](https://github.com/szTheory/mailglass/commit/7692507312f6efb2958a32387d391b89063dfccb))
* **97-03:** wire JS focus trap for replay modal open/close ([b41b7bc](https://github.com/szTheory/mailglass/commit/b41b7bc8fa621aa18208fe937184de7d6f1bd5cd))
* **97-05:** add ARIA tab contract, focus rings, and empty HTML placeholder to tabs ([2e18d6e](https://github.com/szTheory/mailglass/commit/2e18d6e600cc250a63494dbcddbb021191c4adc1))
* **97-05:** add focus rings and replace border-l-[3px] with border-l-2 in sidebar ([741a91b](https://github.com/szTheory/mailglass/commit/741a91bf1c439eb3e54b4a3bfb76391d1b6b0aeb))
* **97-05:** add min-h-11 to all three device_frame segmented control buttons ([4a6e7fb](https://github.com/szTheory/mailglass/commit/4a6e7fbf9b02ab898f9535b285cc166dfe463e2a))
* **97-06:** add GalleryLive route and [@compile](https://github.com/compile) no_warn_undefined entry ([52cc61a](https://github.com/szTheory/mailglass/commit/52cc61acb680cc2b62b10d627d4ef849cd31b44c))
* **97-06:** create GalleryLive with complete in-code specimen list and twin-theme render ([07694c8](https://github.com/szTheory/mailglass/commit/07694c86680eeeb1590b44cbb1b56eee7640de1c))
* **97-08:** un-skip gallery describe block with real structural assertions ([f605382](https://github.com/szTheory/mailglass/commit/f6053822cbdb8d151e0a887b361589af7c1d0140))
* **98-02:** reshape operator deliveries IA ([0c4a958](https://github.com/szTheory/mailglass/commit/0c4a9589d68a297995f115c3ef4cc515a00eb852))
* **99-01:** expose inbound summary through admin gateway ([d0ef911](https://github.com/szTheory/mailglass/commit/d0ef911042f7eba2c8fa1d39e259f77786cbec48))
* **99-02:** add summary-backed inbound overview ([2ed8622](https://github.com/szTheory/mailglass/commit/2ed8622d0cb2fb2b159d845a7e8e624ff629ffe3))
* **99-02:** apply inbound responsive IA ([dc2f56f](https://github.com/szTheory/mailglass/commit/dc2f56f12dd2474a0b1be837ce973ca26eaabc1a))
* **99-02:** split inbound empty states ([ff16b4a](https://github.com/szTheory/mailglass/commit/ff16b4ad8e0d087cdd10109febbe73c16c5b6fd8))
* **99-03:** clean inbound filter and replay tokens ([da0e57d](https://github.com/szTheory/mailglass/commit/da0e57d736c760789a6cd82dcf541f2400e438d2))
* **99-03:** implement locked evidence card affordance ([e4d0334](https://github.com/szTheory/mailglass/commit/e4d0334043bf5aa59bcbd2c92c0dc9093c01266b))
* **99-03:** implement routing trace clause grid ([25b0275](https://github.com/szTheory/mailglass/commit/25b0275b493e188893103307d6fff6cee5c2c8d3))
* **99-04:** seed inbound browser state matrix ([85c37ee](https://github.com/szTheory/mailglass/commit/85c37ee3403bf1d46d2ccc28a3886a795cf8bcfd))
* **99-05:** harden advisory conformance gate ([733222f](https://github.com/szTheory/mailglass/commit/733222fa4fb97df6ae86d7838a60576037ec59de))
* **admin:** re-baseline app.css onto brandbook tokens ([ba8c8f5](https://github.com/szTheory/mailglass/commit/ba8c8f539904b3a60439dfd3caa76ab82e9a8cbb))


### Bug Fixes

* **100-03:** close preview ratchet gaps ([69f3912](https://github.com/szTheory/mailglass/commit/69f39126421024068b9ba765579ab9322f233b7b))
* **101-01:** apply three residual COPY-LD string fixes in inbound_live.ex ([5f9ae32](https://github.com/szTheory/mailglass/commit/5f9ae324d114a4719a75dd2efb3bde63f2acaaf2))
* **102-03:** align stale inbound replay-success test copy to locked COPY-LD-13 ([1b0c697](https://github.com/szTheory/mailglass/commit/1b0c69797da127abffac60c79fe3d436d6bc49bd))
* **103:** harden ratchet to fail-closed on missing cells (CR-01) ([151b064](https://github.com/szTheory/mailglass/commit/151b0641cdef0f885819508b329b78d03e7039f3))
* **95-04:** repair ui-audit.sh for agent-browser &gt;=0.27 CLI ([c6d804c](https://github.com/szTheory/mailglass/commit/c6d804c33876c34a12b6561cea8b7d8487a9c012))
* **97-01:** update orientation_strip frozen-copy tests to domain-noun strings ([36249bc](https://github.com/szTheory/mailglass/commit/36249bc03d8039db13cd55d7d6ef25080e3ae2a2))
* **97-02:** remove banned arbitrary tracking + px-5 from detail_headers and shell ([5eda726](https://github.com/szTheory/mailglass/commit/5eda726cff3c466c9bfc468a4ff355a6db0318d9))
* **97-06:** correct can_reveal? specimen default and absorb gallery specimen clicks ([56ba927](https://github.com/szTheory/mailglass/commit/56ba927267294a7136d11b05d4ffdc89492c820b))
* **97-08:** fix gallery_live.ex specimen data bugs causing Playwright failures ([9f8e4a8](https://github.com/szTheory/mailglass/commit/9f8e4a8348c8c617e542fff296a46f2295d955ae))
* **98-01:** allow suppressed status badge fallback ([b95872f](https://github.com/szTheory/mailglass/commit/b95872f2a7a3a97538472ccf9ea54a771267b88c))
* **98-01:** harden operator nil guard paths ([dbac1ad](https://github.com/szTheory/mailglass/commit/dbac1adbd725c1d4be68b069e3e60ecdcc7646f8))
* **98-03:** clean operator in-pane tracking tokens ([9b53679](https://github.com/szTheory/mailglass/commit/9b53679fae5e1d263bfd86a86f53b146b8ecafa1))
* **98-04:** harden mounted asset path detection ([eb3bcaa](https://github.com/szTheory/mailglass/commit/eb3bcaa81890571d73fdf5347309ce1a69a4af25))
* **99-05:** remove preview raw heading scale ([3de35f3](https://github.com/szTheory/mailglass/commit/3de35f3114fdff9f8dd630fac8473d164e65bf07))
* **99-05:** serialize operator browser gate ([af5e83b](https://github.com/szTheory/mailglass/commit/af5e83bba65cf80f6cfacdddee717318045e9d14))
* **99:** address inbound review findings ([75bf1f8](https://github.com/szTheory/mailglass/commit/75bf1f84c0480d5b9e666eb8c7e3782eafa265b2))
* **99:** cover denied inbound evidence contrast ([699270f](https://github.com/szTheory/mailglass/commit/699270f73c672b20f9bf0d96769e526d8d09a122))
* **99:** preserve inbound deep links beyond list cap ([2d2fe24](https://github.com/szTheory/mailglass/commit/2d2fe2430eb15452206edf97cd20c7ce3df5076d))
* **99:** resolve wave 2 component empty-state test ([2af0c22](https://github.com/szTheory/mailglass/commit/2af0c2235d7176da2cbba0b469db99a11ec3a1aa))

## [1.6.2](https://github.com/szTheory/mailglass/compare/mailglass_admin-v1.6.1...mailglass_admin-v1.6.2) (2026-06-12)


### Miscellaneous Chores

* **mailglass_admin:** Synchronize mailglass-sibling-group versions

## [1.6.1](https://github.com/szTheory/mailglass/compare/mailglass_admin-v1.6.0...mailglass_admin-v1.6.1) (2026-06-12)


### Miscellaneous Chores

* **mailglass_admin:** Synchronize mailglass-sibling-group versions

## [1.6.0](https://github.com/szTheory/mailglass/compare/mailglass_admin-v1.5.1...mailglass_admin-v1.6.0) (2026-06-12)


### Miscellaneous Chores

* **mailglass_admin:** Synchronize mailglass-sibling-group versions

## [1.5.1](https://github.com/szTheory/mailglass/compare/mailglass_admin-v1.5.0...mailglass_admin-v1.5.1) (2026-06-05)


### Bug Fixes

* **admin-test:** run inbound migrations in the browser-server DB bootstrap ([#71](https://github.com/szTheory/mailglass/issues/71)) ([615beb0](https://github.com/szTheory/mailglass/commit/615beb06445c2c2b4cbc13a28780f0995a91a58c))

## [1.5.0](https://github.com/szTheory/mailglass/compare/mailglass_admin-v1.4.5...mailglass_admin-v1.5.0) (2026-06-05)


### Features

* **demo:** one-command Docker DX with collision-free ports ([#65](https://github.com/szTheory/mailglass/issues/65)) ([466544f](https://github.com/szTheory/mailglass/commit/466544f3d011fd95bc888abda9e81cedf24e966c))

## [1.4.5](https://github.com/szTheory/mailglass/compare/mailglass_admin-v1.4.4...mailglass_admin-v1.4.5) (2026-06-03)


### Miscellaneous Chores

* **mailglass_admin:** Synchronize mailglass-sibling-group versions

## [1.4.4](https://github.com/szTheory/mailglass/compare/mailglass_admin-v1.4.3...mailglass_admin-v1.4.4) (2026-06-03)


### Miscellaneous Chores

* **mailglass_admin:** Synchronize mailglass-sibling-group versions

## [1.4.3](https://github.com/szTheory/mailglass/compare/mailglass_admin-v1.4.2...mailglass_admin-v1.4.3) (2026-06-03)


### Miscellaneous Chores

* **mailglass_admin:** Synchronize mailglass-sibling-group versions

## [1.4.2](https://github.com/szTheory/mailglass/compare/mailglass_admin-v1.4.1...mailglass_admin-v1.4.2) (2026-06-03)


### Bug Fixes

* **admin:** float optional mailglass_inbound dep to ~&gt; 1.1 (was stale ~&gt; 0.2) ([f27dff1](https://github.com/szTheory/mailglass/commit/f27dff12e19644593b5507406730f2c3631b5066))

## [1.4.1](https://github.com/szTheory/mailglass/compare/mailglass_admin-v1.4.0...mailglass_admin-v1.4.1) (2026-06-02)


### Miscellaneous Chores

* **mailglass_admin:** Synchronize mailglass-sibling-group versions

## [1.4.0](https://github.com/szTheory/mailglass/compare/mailglass_admin-v1.3.0...mailglass_admin-v1.4.0) (2026-06-02)


### Features

* **61-02:** tighten operator trust boundary routing ([1b40cf5](https://github.com/szTheory/mailglass/commit/1b40cf574a00b36201db480c75fe7c150adac3fb))
* **admin-ui:** design-system tokens, operator shell IA, motion, and visual audit ([#52](https://github.com/szTheory/mailglass/issues/52)) ([f1c17d8](https://github.com/szTheory/mailglass/commit/f1c17d8cbee3558b32988185223e34eb0f21b7b0))

## [1.3.0](https://github.com/szTheory/mailglass/compare/mailglass_admin-v1.2.0...mailglass_admin-v1.3.0) (2026-05-28)


### Features

* **999.2-01:** add deterministic capture matrix helpers ([b89b140](https://github.com/szTheory/mailglass/commit/b89b14056248d23edb6fe81e35cdd1a3a0c6a3b5))
* **999.2-01:** canonicalize preview width/theme capture state ([738a6af](https://github.com/szTheory/mailglass/commit/738a6afe03b07077f560c127572db2e61902b03d))
* **999.2-02:** add deterministic preview capture manifest contract ([3a29b76](https://github.com/szTheory/mailglass/commit/3a29b76e4096afab574cc8d9f825c9384d489e7e))
* **999.2-02:** add deterministic preview capture mix task ([80259ac](https://github.com/szTheory/mailglass/commit/80259acd7dc238f320878efc95e2b4313438c582))


### Bug Fixes

* **admin:** add --no-sandbox to preview Chromium for CI containers ([bcf787c](https://github.com/szTheory/mailglass/commit/bcf787cd076590252135ff16acb939429bf94aab))
* **admin:** preview Chromium capture passed invalid :timeout to System.cmd ([abc54c9](https://github.com/szTheory/mailglass/commit/abc54c9b31305aa714f31c14af4ddd445d3c2be0))

## [1.2.0](https://github.com/szTheory/mailglass/compare/mailglass_admin-v1.0.0...mailglass_admin-v1.2.0) (2026-05-25)


### Features

* **48-01:** admin seams — inbound gateway, topic builder, mask_recipient promotion (IADM-05) ([6874895](https://github.com/szTheory/mailglass/commit/687489532b790664a557585535577247a89a1535))
* **48-01:** wire optional inbound dep + admin test-infra (Wave 0) ([be1fd76](https://github.com/szTheory/mailglass/commit/be1fd76f3cb1f702aee77927951f94ee54560583))
* **48-02:** clone inbound sibling components (list, detail, timeline, filters, replay-modal, destructive-action) ([7f98e39](https://github.com/szTheory/mailglass/commit/7f98e391bb212890e13ee396e55dbf313ae7bc16))
* **48-02:** InboundLive shell — URL-state, tenant gate, list/detail/timeline via the gateway ([9c6ade6](https://github.com/szTheory/mailglass/commit/9c6ade6824d7b02d9ac858c353708e2457e38712))
* **48-02:** router wiring — /inbound route in operator live_session, available?/0-gated (IADM-07) ([decb24e](https://github.com/szTheory/mailglass/commit/decb24e26a662b9b17e6ae37f71de2260abbd65a))
* **48-03:** routing-trace + evidence cards wired into detail pane ([f4dc7a7](https://github.com/szTheory/mailglass/commit/f4dc7a7450718d05901e90ba41ea3b64d246f50a))
* **48-03:** tenant-gated replay confirm flow + live PubSub updates ([decb6d5](https://github.com/szTheory/mailglass/commit/decb6d555907abea54e41336fdbe0d313903a1e9))


### Bug Fixes

* **48:** detail 'From' cell shows the masked sender, not the recipient (WR-02) ([d549b3a](https://github.com/szTheory/mailglass/commit/d549b3af124989cce6052e89a0e3dedf8804c85f))
* **48:** deterministic inbound-route test ordering + operator-session assertion ([bba56a1](https://github.com/szTheory/mailglass/commit/bba56a1a9300422fee6941fd8423ab9ac76e0474))
* **48:** thread inbound search end-to-end + assert list disposition (WR-03, WR-01) ([ddb6f31](https://github.com/szTheory/mailglass/commit/ddb6f31ef5f92419788d524de4b47707c2d62dbc))
* **49:** T-49-17 tenant-scope inbound replay to prevent cross-tenant replay ([3f92c1d](https://github.com/szTheory/mailglass/commit/3f92c1d391fa1e40391db777819f5045aef6fb9b))
* **ci:** restore release readiness gates ([683f653](https://github.com/szTheory/mailglass/commit/683f653ce6252f951c82c8ab581596dc31408aeb))
* **ci:** stabilize operator browser gate ([370433d](https://github.com/szTheory/mailglass/commit/370433d5df68c2ceaf9b95bba6f2c2be2c63ea42))
* **docs:** harden core/admin README version pins + self-maintaining enforcement ([79e88d0](https://github.com/szTheory/mailglass/commit/79e88d0a3f29922457f85a8169ced310a13d6251))

## [Unreleased]

`mailglass_admin` 1.2.0 is coordinated with `mailglass` 1.2.0 (linked release).
Ships the InboundLive admin UI: `/inbound` route with list, detail, timeline,
and routing-trace views; tenant-gated replay confirm modal. Requires
`{:mailglass_inbound, "~> 0.2"}` for the inbound UI surface. No breaking
changes for existing admin users who do not use `mailglass_inbound`. See
[`mailglass_inbound` 0.2.0 CHANGELOG](../mailglass_inbound/CHANGELOG.md) for
the full inbound feature narrative.

### Added

- `MailglassAdmin.InboundLive` — mountable LiveView for inbound message
  management (IADM-01..07); gated behind `MailglassInbound` optional dep.
- `MailglassAdmin.OptionalDeps.MailglassInbound` — optional-dep gateway for
  `mailglass_inbound`, following the project's gateway pattern.

### Changed

- Stays version-paired with `mailglass` 1.2.0 release line.

## [1.0.0](https://github.com/szTheory/mailglass/compare/mailglass_admin-v1.0.0...mailglass_admin-v1.0.0) (2026-05-08)


### Bug Fixes

* **ci:** restore release readiness gates ([683f653](https://github.com/szTheory/mailglass/commit/683f653ce6252f951c82c8ab581596dc31408aeb))
* **ci:** stabilize operator browser gate ([370433d](https://github.com/szTheory/mailglass/commit/370433d5df68c2ceaf9b95bba6f2c2be2c63ea42))

## [1.0.0](https://github.com/szTheory/mailglass/compare/mailglass_admin-v1.0.0...mailglass_admin-v1.0.0) (2026-05-08)


### Bug Fixes

* **ci:** restore release readiness gates ([683f653](https://github.com/szTheory/mailglass/commit/683f653ce6252f951c82c8ab581596dc31408aeb))
* **ci:** stabilize operator browser gate ([370433d](https://github.com/szTheory/mailglass/commit/370433d5df68c2ceaf9b95bba6f2c2be2c63ea42))

## [1.0.0](https://github.com/szTheory/mailglass/compare/mailglass_admin-v1.0.0...mailglass_admin-v1.0.0) (2026-05-08)


### Bug Fixes

* **ci:** restore release readiness gates ([683f653](https://github.com/szTheory/mailglass/commit/683f653ce6252f951c82c8ab581596dc31408aeb))
* **ci:** stabilize operator browser gate ([370433d](https://github.com/szTheory/mailglass/commit/370433d5df68c2ceaf9b95bba6f2c2be2c63ea42))

## [1.0.0](https://github.com/szTheory/mailglass/compare/mailglass_admin-v0.3.2...mailglass_admin-v1.0.0) (2026-05-07)

`mailglass_admin` 1.0.0 is coordinated with `mailglass` 1.0.0 and shares the
1.x stability promise (per `guides/compatibility-and-deprecations.md`). There
is no admin-only migration story for the 1.0 cut: bump both linked sibling
packages together. See [`docs/upgrade-from-0.x.md`](../docs/upgrade-from-0.x.md)
for the bundled v0.5 → v1.1 upgrade story.

### Changed

- Stays version-paired with `mailglass` 1.0.0 release line.


### Features

* **22-02:** add operator liveview shell ([f95cee5](https://github.com/szTheory/mailglass/commit/f95cee5401d58e7012de38f2fe2da008fa0613f8))
* **22-02:** build operator admin surface ([f8a120b](https://github.com/szTheory/mailglass/commit/f8a120b19c69feb5e11f6774ac70956fbe179ab8))
* **33-01:** align operator incident docs ([cd568d8](https://github.com/szTheory/mailglass/commit/cd568d871034905f00e85650ecf162e142869dfb))
* **33-03:** add operator support card surface ([1fd4bc3](https://github.com/szTheory/mailglass/commit/1fd4bc35e041225f041ac28bd3cf98223d4ae632))
* **33-03:** add support exemplar drilldowns ([8aa247c](https://github.com/szTheory/mailglass/commit/8aa247c1e3fdb7a4b7b8226ddff128dac3adb029))
* add operator replay modal and liveview flow ([ba1ce0a](https://github.com/szTheory/mailglass/commit/ba1ce0af37e1ca625b511a87bb5a13088ebd6e00))


### Bug Fixes

* **22-03:** align admin liveview harness with root tests ([7089bc2](https://github.com/szTheory/mailglass/commit/7089bc2bb7cba0df70e9be83dac5a8a2d25d1807))
* **ci:** probe port binding + URL paths to diagnose operator_browser hang ([0a409c8](https://github.com/szTheory/mailglass/commit/0a409c8a04ee6123fa191e41dc990eade6a562bf))
* **ci:** surface operator_browser_gate stages + raise webServer timeout ([befbd02](https://github.com/szTheory/mailglass/commit/befbd0229ceb93c1ccb657681c11a10967f85166))

## [0.3.2](https://github.com/szTheory/mailglass/compare/mailglass_admin-v0.3.1...mailglass_admin-v0.3.2) (2026-04-29)


### Miscellaneous Chores

* **mailglass_admin:** Synchronize mailglass-sibling-group versions

## [0.3.1](https://github.com/szTheory/mailglass/compare/mailglass_admin-v0.3.0...mailglass_admin-v0.3.1) (2026-04-29)


### Miscellaneous Chores

* **mailglass_admin:** Synchronize mailglass-sibling-group versions

## [0.3.0](https://github.com/szTheory/mailglass/compare/mailglass_admin-v0.2.0...mailglass_admin-v0.3.0) (2026-04-29)


### Miscellaneous Chores

* **mailglass_admin:** Synchronize mailglass-sibling-group versions

## [0.3.0](https://github.com/szTheory/mailglass/compare/mailglass_admin-v0.2.0...mailglass_admin-v0.3.0) (2026-04-29)

`mailglass_admin` 0.3.0 stays version-paired with `mailglass` 0.3.0. There is
no admin-only migration story in this release; bump the sibling packages
together and take the updated core webhook/docs surface as a coordinated cut.

### Changed

- The preview package stays aligned to the core `0.3.0` release line and its
  maintainer-written release narrative.

## [0.2.0](https://github.com/szTheory/mailglass/compare/mailglass_admin-v0.1.1...mailglass_admin-v0.2.0) (2026-04-28)

`mailglass_admin` 0.2.0 is coordinated with `mailglass` 0.2.0. There is no
standalone admin codemod or admin-only rollback path: bump both sibling
packages together, run the core `mix mailglass.upgrade.v0_2` flow if your
mailables still call `Swoosh.Email.*`, and keep the preview package on the
matching sibling version.

### Changed

- Coordinated the preview package with the `mailglass` 0.2.0 message-authoring
  API and release line.
- Existing preview mounts do not need extra admin-only router or asset changes
  beyond taking the matching core release.

## [0.1.1](https://github.com/szTheory/mailglass/compare/mailglass_admin-v0.1.0...mailglass_admin-v0.1.1) (2026-04-26)


### Bug Fixes

* **release-please:** bump mailglass_admin -&gt; mailglass dep pin on every release ([eb0370f](https://github.com/szTheory/mailglass/commit/eb0370ff464d2711275b3ad8386e2be81aed38a7))
* **release-please:** move x-release-please-version annotation onto its own line ([e0b1edb](https://github.com/szTheory/mailglass/commit/e0b1edbbdfd0b2458fad1bf09987b73d141d6a21))
* **release-please:** sync mailglass_admin -&gt; mailglass dep pin via workflow sed ([9fc4009](https://github.com/szTheory/mailglass/commit/9fc40093e8844ce59bb518e153b85382913dc17d))


### Miscellaneous Chores

* release 0.1.1 ([bfd001f](https://github.com/szTheory/mailglass/commit/bfd001fdf3a994de0da74b0091c1d60972c57605))

## 0.1.0 (2026-04-26)


### Features

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
* **07-05:** release-please linked versions, protected hex publish ([0e767dd](https://github.com/szTheory/mailglass/commit/0e767ddda483928df842e76b9e94daccef52a82f))


### Bug Fixes

* **07.1-07:** expand prepublish check ([ce2f3cf](https://github.com/szTheory/mailglass/commit/ce2f3cfb4f468a08c18a232c2929037ffa39f6a2))


### Miscellaneous Chores

* release 0.1.0 ([e26b691](https://github.com/szTheory/mailglass/commit/e26b6910f8859e3489937739da9a0db37e46ad90))

## [0.1.0] - 2026-04-24

### Added
- Initial release of Mailglass Admin.
- Dev-mode preview LiveView dashboard with mailable sidebar.
- Auto-discovery of mailables via `preview_props/0`.
- HTML, Plaintext, Raw Source, and Header tabs for message inspection.
- Device toggle (Mobile/Desktop) and Dark mode preview.
- Asset build pipeline for vendored daisyUI + Tailwind.
