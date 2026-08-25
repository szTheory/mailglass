---
phase: 160-certification-documentation-and-release
plan: 02
subsystem: public-documentation-contract
tags: [docs, compatibility, deprecations, migrations, inbound]
requires: [REL-02]
provides:
  - executable core and inbound v2.6 additive-interface inventories
  - explicit core v2 deprecation replacements and v3 removal targets
  - Repo-explicit, prefix-safe generated migration guidance
affects: [release-certification, generated-host-adoption, package-stability]
tech-stack:
  added: []
  patterns: [negative-control documentation tests, package-owned contract inventory, historical-provenance labeling]
key-files:
  created: []
  modified:
    - docs/api_stability.md
    - guides/compatibility-and-deprecations.md
    - guides/upgrading-to-v2_0.md
    - guides/b2c-first-adopter.md
    - mailglass_inbound/docs/api_stability.md
    - mailglass_inbound/docs/inbound-install.md
    - test/mailglass/docs_contract_test.exs
    - test/mailglass/upgrade_v2_docs_test.exs
    - mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs
key-decisions:
  - "Core v2.6 additive API is limited to the public migration generator/facade/error seams and SendError additions; Runtime and extracted pipelines remain internal."
  - "Every retained core compatibility bridge has a present replacement and v3.0 removal target; inbound has no active v2 deprecations or v3 removals."
  - "Admin is compatibility-tested as a sibling package, not described as a new operator UI or behavior surface."
requirements-completed: [REL-02]
completed: 2026-08-18
---

# Phase 160 Plan 02: Executable v2 Documentation Contract Summary

Core and inbound now publish an executable v2.6 contract that distinguishes
additive adopter seams from internal architecture, names every active core
deprecation with its replacement and v3 target, and keeps package migration
ownership explicit.

## Accomplishments

- Added fail-first core and inbound documentation contracts with injected bad
  fixtures for missing ownership, additive interfaces, deprecation status,
  replacements, removal targets, stale version claims, and fabricated
  admin/operator behavior promises.
- Mapped every newly claimed interface to a loaded Mix task, exported public
  function, error type, or struct field so the contract is not token-only or
  vacuous.
- Reframed the core inventory as v2.x and documented the v2.6 migration
  generator/facade, fail-closed migration metadata error, and additive
  `Mailglass.SendError` fields without promoting Runtime or extracted pipeline
  collaborators.
- Added the current compatibility table for `Mailglass.Message.new/2`,
  `Mailglass.Outbound.send/2`, raw Swoosh delivery, the v0.2 upgrade task, and
  legacy signature atoms. Each row includes current status, replacement, and
  a v3.0 removal target; no v2 surface was removed or renamed.
- Added exact Repo-explicit core/inbound generator commands and package-local
  prefix examples to the v2 upgrade guide, tied to the generated-host proof.
- Corrected inbound install truth from the historical two-provider posture to
  the four shipped stable provider lanes, and documented the independent
  inbound migration facade and package anchor.
- Removed the B2C launch dependency on an operator dashboard. Durable alerts or
  background checks are sufficient for the alpha; no admin/operator UI code or
  behavior was changed.

## Commits

- `9984b629` — specify the fail-first v2 documentation contract
- `ca867356` — sharpen stale/UI negative controls
- `dc03dc16` — make missing-token mutation controls non-vacuous
- `42352b58` — cover duplicate inbound facts in negative controls
- `98194a5b` — reconcile additive core/inbound v2 documentation
- `27db846b` — avoid ExDoc promotion of hidden collaborators
- `2f8d617c` — retain explicitly labeled inbound contract provenance

## Verification

- `mix verify.stability_contract` — core 97 executed tests plus one property,
  admin 116 tests, and inbound 33 tests; all passed (one historical core skip).
- `mix mailglass.docs.check` — Tier 1 docs contract passed.
- `mix test test/mailglass/docs_contract_test.exs test/mailglass/upgrade_v2_docs_test.exs --warnings-as-errors`
  — 47 tests, 0 failures, 1 historical skip.
- `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors`
  — 25 tests, 0 failures.
- `mix docs --warnings-as-errors` — root HTML, Markdown, and EPUB docs generated
  without warnings.
- Scoped root/inbound format checks and `git diff --check` passed.

## Deviations and Notes

### Corrected stale provider guidance

The planned reconciliation exposed a real contradiction: the inbound stability
inventory already promises Postmark, SendGrid, Mailgun, and SES, while the
install guide still claimed only the first two were stable. The install guide
now names all four. The old sentence remains only in an explicitly labeled
historical note because the existing Tier 1 checker still recognizes that
legacy token; current truth is stated immediately above it and protected by a
new positive assertion.

### Standalone inbound ExDoc baseline

The required root `mix docs --warnings-as-errors` passes. A diagnostic
standalone inbound ExDoc run still reports pre-existing hidden-internal links
and repo-relative links across files outside this plan. The two warnings this
plan initially introduced were removed; no new inbound ExDoc warning remains
from the v2.6 snapshot.

## Scope Confirmation

No package version, release target, tag, publication workflow, runtime behavior,
admin/operator UI code, styling, navigation, or browser behavior changed.

## Self-Check: PASSED

REL-02 is current, package-owned, additive-only, and executable.
