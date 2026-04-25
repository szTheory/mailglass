# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-04-24

### Added

- Initial release of Mailglass core.
- HEEx-native component library with Outlook fallbacks.
- Pure-function render pipeline with auto-plaintext and CSS inlining.
- Multi-tenancy support with `tenant_id` on all records.
- Append-only event ledger with Postgres trigger protection.
- Webhook normalization for Postmark and SendGrid.
- Delivery status reconciliation and orphan event linking.
- `mix mailglass.install` for easy onboarding.
- Dev-mode preview LiveView dashboard.
- Documentation spine with 9 guides and contract tests.
