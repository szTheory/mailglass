# Changelog

All notable changes to `mailglass_admin` will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning coordinated with `mailglass` core via Release Please linked-versions.

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
