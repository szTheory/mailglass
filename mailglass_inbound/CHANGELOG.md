# Changelog

All notable changes to `mailglass_inbound` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.2] - 2026-05-06

### Added

- Canonical manual setup documentation for the `mailglass_inbound` package.
- Postmark and SendGrid provider guides with contract-tested durability and replay wording.
- Oban-backed async execution with bounded Task.Supervisor fallback semantics.

### Changed

- Repo-root verification now treats inbound docs and sibling-package release proof as release-blocking truth.
