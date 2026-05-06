---
phase: 37-contract-enforcement-and-trust-docs
plan: 03
subsystem: support-contract
tags: [verification, docs-check, mix-aliases, stability]
requires:
  - plan: 37-01
    provides: canonical testing guide and docs proof
  - plan: 37-02
    provides: canonical admin trust doc and semantic admin proof
provides:
  - semantic repo-root `verify.stability_contract` entrypoint
  - Tier 1 docs checks for testing and operator trust docs
  - compiled-doc and wiring assertions for root and admin stability proof
affects: [mix-aliases, scripts, docs-check, maintaining]
tech-stack:
  added: []
  patterns: [compose existing proof lanes, lightweight semantic enforcement]
key-files:
  created: []
  modified: [mix.exs, mailglass_admin/mix.exs, scripts/verify_support_contract.sh, lib/mix/tasks/mailglass.docs.check.ex, MAINTAINING.md, test/mailglass/docs_contract_test.exs, test/mailglass/stability_contract_test.exs, mailglass_admin/test/mailglass_admin/stability_contract_test.exs]
requirements-completed: [PROOF-01, PROOF-02]
completed: 2026-05-05
---

# Phase 37-03 Summary

Strengthened the support-contract workflow into one semantic repo-root proof entrypoint, `mix verify.stability_contract`, while keeping the enforcement lightweight and based on the existing core lane, admin lane, and no-optional-deps compile lane.

## Verification

- `bash scripts/verify_support_contract.sh`
- `mix test test/mailglass/docs_contract_test.exs test/mailglass/stability_contract_test.exs --warnings-as-errors`
- `cd mailglass_admin && mix test test/mailglass_admin/stability_contract_test.exs test/mailglass_admin/operator_trust_doc_test.exs --warnings-as-errors`

## Notes

- Tier 1 docs drift checks now treat `guides/testing.md` and `mailglass_admin/docs/operator-trust.md` as release-blocking truth.
- The admin support-contract alias now covers the trust-doc and stability proof tests, so the repo-root workflow actually exercises both sibling-package contract surfaces.
