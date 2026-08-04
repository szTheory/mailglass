---
phase: 153-generated-host-proof-docs-and-release-gate
plan: 08
subsystem: release-automation
tags: [elixir, github-actions, hex, phoenix, postgres]
requires:
  - phase: 153-07
    provides: resolver-selected package set, exact candidate gate, and release proof ledger
provides:
  - Protected publication of mailglass 2.4.1, mailglass_admin 2.4.1, and mailglass_inbound 2.1.2
  - Ledger-bound proof of the exact candidate, approvals, deployments, Hex archives, and HexDocs
  - Public-registry generated-host and published reference-host trust journeys
affects: [milestone-v2.4, release-automation, post-publish-smoke]
tech-stack:
  added: []
  patterns: [exact-SHA release proof, cold-fixture precompilation, environment-aligned consumer smoke]
key-files:
  created: [.planning/phases/153-generated-host-proof-docs-and-release-gate/153-08-SUMMARY.md]
  modified: [.github/workflows/post-publish-smoke.yml, scripts/consumer_install_smoke.sh, mix.exs, test/mailglass/demo_data_test.exs, test/mailglass/install/install_first_preview_smoke_test.exs, test/mailglass/publish/post_publish_smoke_contract_test.exs, test/scripts/linked_release_concurrency_test.exs, reference/demo_app/mix.lock, .planning/phases/153-generated-host-proof-docs-and-release-gate/153-RELEASE-PROOF.md]
key-decisions:
  - "The protected tag may move only after fresh exact-SHA CI and advisory matrices pass for each replacement candidate."
  - "Cold release fixtures compile before root tests, and consumer compile/boot use the same explicit Mix environment."
  - "Post-publish full generated-host proof requires a healthy Postgres service because it is Ecto-backed."
patterns-established:
  - "Release CI must provision every fixture and build environment explicitly; warm checkout state is never evidence."
  - "Published completion uses canonical Hex-served tarball hashes and a separate Hex-only downstream journey."
requirements-completed: [REL-17]
coverage:
  - id: D1
    description: Protected workflow published only the approved exact candidate and package set.
    requirement: REL-17
    verification:
      - kind: integration
        ref: https://github.com/szTheory/mailglass/actions/runs/30922262406
        status: pass
      - kind: integration
        ref: mix run scripts/verify_release_proof.exs -- --ledger .planning/phases/153-generated-host-proof-docs-and-release-gate/153-RELEASE-PROOF.md --stage complete
        status: pass
    human_judgment: false
  - id: D2
    description: Exact public Hex packages pass the complete generated-host and trust journeys.
    requirement: REL-17
    verification:
      - kind: e2e
        ref: https://github.com/szTheory/mailglass/actions/runs/30927455604
        status: pass
    human_judgment: false
  - id: D3
    description: Workflow and verifier contracts reject release identity or environment drift.
    requirement: REL-17
    verification:
      - kind: unit
        ref: mix test test/mailglass/publish/post_publish_smoke_contract_test.exs test/scripts/release_proof_verifier_test.exs --seed 0
        status: pass
    human_judgment: false
duration: 14h recovery window
completed: 2026-08-04
status: complete
---

# Phase 153 Plan 08: Protected Publication and Exact-Hex Proof Summary

**The ledger-approved candidate shipped through GitHub's protected environment, and the exact public packages passed generated-host, trust, docs, and retirement checks.**

## Accomplishments

- Published `mailglass` 2.4.1, `mailglass_admin` 2.4.1, and `mailglass_inbound` 2.1.2 from candidate `587c9d1a09944de02220b3fa121ce937677a8c3a` through the protected `publish-hex` workflow.
- Closed cold-runner parity gaps in native dependency builds, reference host/demo fixture preparation, and consumer compile/boot environments without bypassing any release gate.
- Completed a fresh Hex-only generated-host journey, published reference-host trust journey, Hex/HexDocs propagation checks, and not-retired verification.
- Bound the final ledger to the successful publish run, protected approvals/deployments, tag SHA, versions, and canonical Hex tarball checksums.

## Task Commits

1. Release candidate dependency and cold-runner repairs: `f033c313`, `4cc41405`, `a98cef2b`, `d99ef3e5`, `5552e0a4`, `24b5d903`, `fc6bd11d`, `9c60fd04`.
2. Final published-candidate consumer environment alignment: `587c9d1a`.
3. Post-publication smoke database provisioning: `cca6b061`.

## Publication Evidence

- Candidate tag: `mailglass-v2.4.1` → `587c9d1a09944de02220b3fa121ce937677a8c3a`.
- Exact-SHA CI: [30920859359](https://github.com/szTheory/mailglass/actions/runs/30920859359), 24/24 jobs passed.
- Exact-SHA advisory matrix: [30920861820](https://github.com/szTheory/mailglass/actions/runs/30920861820), 7/7 jobs passed.
- Protected publication: [30922262406](https://github.com/szTheory/mailglass/actions/runs/30922262406), all three publish jobs passed.
- Corrected exact-Hex post-publish proof: [30927455604](https://github.com/szTheory/mailglass/actions/runs/30927455604), all required jobs passed.
- Final verifier: `release proof verified for mailglass-v2.4.1`.

## Deviations from Plan

### Auto-fixed Issues

1. Native release CI initially used an isolated Mix build path that broke `yamerl` compilation on the clean Elixir 1.18 runner; release CI now uses the native test build and cleans it before full parity checks.
2. Workspace-tagged root tests depended on warm reference fixtures; host and demo dependencies are now fetched and compiled before the root suite.
3. The demo fixture's cold `ecto.create` compilation exceeded ExUnit's default timeout; the demo app is precompiled and the subprocess-heavy test has an explicit 180-second budget.
4. Consumer smoke compiled under inherited `MIX_ENV=test` but booted under `dev`; compile and server now share `MIX_ENV=dev`.
5. Post-publish consumer proof invoked an Ecto-backed journey without Postgres; the job now provisions a health-checked Postgres service.

**Total deviations:** 5 release-path correctness fixes. All were required to make cold publication and public-registry proof match the already-green split CI behavior; no product scope was added.

## Issues Encountered

- Failed publish attempts performed no Hex uploads; publication jobs remained skipped until the final protected run.
- The first post-publish smoke failed before its journey because PostgreSQL was absent. The workflow opened its failure tracker automatically; the corrected green rerun executed the success closeout path.
- Complete-stage verification initially compared prepublication local archive hashes with canonical Hex-served tarball hashes. The final ledger records the canonical live hashes required by complete verification.

## User Setup Required

None. Protected environment approvals were applied through the authorized GitHub reviewer account.

## Next Phase Readiness

Phase 153 and milestone v2.4 are ready for verification and milestone closeout. The released package set is public, documented, unretired, and installable from Hex with no local dependency fallback.

## Self-Check: PASSED

- Summary, ledger, successful workflow runs, public packages, HexDocs, and complete-stage verifier evidence all exist.

---
*Phase: 153-generated-host-proof-docs-and-release-gate*
*Completed: 2026-08-04*
