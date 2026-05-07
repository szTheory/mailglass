# Changelog

All notable changes to `mailglass_inbound` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
