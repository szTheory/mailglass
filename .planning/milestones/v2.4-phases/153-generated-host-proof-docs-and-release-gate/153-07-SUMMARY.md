---
phase: 153-generated-host-proof-docs-and-release-gate
plan: 07
subsystem: release-automation
tags: [elixir, git, github-actions, hex, release-please]
requires:
  - phase: 153-06
    provides: executable generated-host journey and release documentation
provides:
  - Per-package tag-based changed-package resolver with linked core/admin selection
  - Credential-free protected prepublish gate contract and PII-free evidence ledger
affects: [153-08, release-please, publish-hex]
tech-stack:
  added: []
  patterns: [per-package reachable-tag comparison, target-set fail-closed validation]
key-files:
  created: [scripts/resolve_release_packages.exs, test/scripts/release_package_resolver_test.exs, .planning/phases/153-generated-host-proof-docs-and-release-gate/153-RELEASE-PROOF.md]
  modified: [.github/workflows/release-please.yml, .github/workflows/publish-hex.yml, scripts/generated_host_proof.sh]
key-decisions:
  - "Package ownership is resolved from each package's latest reachable version tag; core/admin form a linked closure and inbound remains independent."
  - "Publication remains behind resolver agreement, local package-shaped proof, repository CI, package checks, and protected candidate-SHA CI."
requirements-completed: [REL-17]
coverage:
  - id: D1
    description: Deterministic release selection and exact target-set validation.
    requirement: REL-17
    verification:
      - kind: unit
        ref: mix test test/scripts/release_package_resolver_test.exs --seed 0
        status: pass
    human_judgment: false
  - id: D2
    description: Protected prepublication workflow contract.
    requirement: REL-17
    verification:
      - kind: unit
        ref: mix test test/scripts/linked_release_concurrency_test.exs test/scripts/release_trigger_recovery_test.exs --seed 0
        status: pass
    human_judgment: true
    rationale: Protected CI requires an authorized immutable remote candidate SHA.
duration: 9min
completed: 2026-08-03
status: complete
---

# Phase 153 Plan 07: Deterministic Release Resolution and Candidate Gate Summary

**Per-package reachable-tag release selection and a credential-free prepublish gate now bind every publish attempt to an auditable candidate.**

## Accomplishments

- Added resolver tests covering source, packaged docs, linked core/admin, independent inbound, first-release, divergent tag, and target mismatch cases.
- Added a deterministic standalone resolver and updated the target set to include changed inbound packaged documentation.
- Wired resolver validation, local generated-host journey, repository CI, selected-package checks, and bounded candidate evidence ahead of publication credentials.

## Task Commits

1. Task 1 RED: `09cfef78` — changed-package resolution tests.
2. Task 1 GREEN: `291030ad` — deterministic resolver and target agreement.
3. Task 2 RED: `12e968b4` — protected prepublish-gate contracts.
4. Task 2 GREEN: `00a76882` — candidate gate, evidence ledger, and all-stage command support.
5. Formatting follow-up: `1d5cd0c6` — resolver test formatting.

## Verification

- Passed: `mix test test/scripts/release_package_resolver_test.exs test/scripts/linked_release_concurrency_test.exs test/scripts/release_trigger_recovery_test.exs --seed 0` (23 tests).
- Resolver observed locally: `mailglass`, `mailglass_admin`, and `mailglass_inbound` using their reachable package tags.
- Not green: `mix ci` stopped at pre-existing formatter failures in `test/mailglass/docs_contract_test.exs` and `lib/mailglass/optional_deps/oban.ex`; neither is owned by this plan.
- Not fully observed: `DEP_MODE=local bash scripts/generated_host_proof.sh --stage all` began and left a valid migrate checkpoint, but did not produce complete all-stage evidence in this environment.
- Not available: protected CI evidence for the candidate SHA, because this plan did not push, dispatch, tag, publish, or invoke credentials.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 3 - Blocking] Added the documented `--stage all` generated-host alias.
- Found during: Task 2 verification.
- Issue: the planned full-journey command was rejected as an invalid stage.
- Fix: sequentially invoke every supported stage under the same reversible command.
- Files modified: `scripts/generated_host_proof.sh`.
- Commit: `00a76882`.

## Known Stubs

None.

## Next Phase Readiness

Plan 08 can use the resolver and prepublish workflow contract. It must obtain authorized remote candidate-SHA CI evidence and complete the exact Hex-only post-publication action; neither was attempted here.

## Self-Check: PASSED

- Resolver, tests, workflows, ledger, and all task commits exist.
