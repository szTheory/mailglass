---
phase: 160-certification-documentation-and-release
plan: 04
subsystem: protected-three-package-release
tags: [release, github-actions, hex, provenance, exact-artifacts, fail-closed]
requires: [REL-03, REL-04]
provides:
  - protected exact-candidate policy for core, admin, and independently versioned inbound
  - credential-free rehearsal and separately authorized release/publication dispatches
  - exact-Hex adoption proof with durable generated-host and trust-runner evidence
  - external publication verifier bound to one protected workflow and candidate
affects: [release-authorization, package-publication, post-publish-certification]
tech-stack:
  added: []
  patterns: [protected-control-checkout, candidate-as-data, canonical-content-digest, immutable-run-evidence]
key-files:
  created:
    - scripts/release_policy.exs
    - scripts/verify_published_release.sh
    - test/scripts/release_policy_test.exs
    - test/scripts/verify_published_release_test.exs
  modified:
    - .github/workflows/release-please.yml
    - .github/workflows/publish-hex.yml
    - .github/workflows/post-publish-smoke.yml
    - CONTRIBUTING.md
    - scripts/release_policy_content_digest.sh
    - scripts/release_policy_expected_tags.sh
    - scripts/release_policy_hex_release_state.sh
    - scripts/release_policy_validate_target.sh
    - test/scripts/release_policy_contract_test.exs
    - test/scripts/linked_release_concurrency_test.exs
    - test/scripts/release_trigger_recovery_test.exs
    - test/scripts/workflow_hardening_contract_test.exs
key-decisions:
  - "The complete release unit is always mailglass, mailglass_admin, and mailglass_inbound; core/admin remain linked while inbound keeps its independently proposed version."
  - "Caller-selected proposal and release trees are data only; policy and digest helpers execute from separately checked out protected-main controls."
  - "Release proposal merge/tag creation and Hex publication are two distinct exact-digest dispatches, each inert without the required lifecycle and authority."
  - "Publication completion requires a canonical protected run, its exact successful live job graph, and a run-owned proof artifact bound to candidate digest, tag SHA, and all versions."
requirements-completed: []
completed: 2026-08-19
---

# Phase 160 Plan 04: Protected Three-Package Release Preparation Summary

The repository now has a tested, fail-closed release path for core, admin, and
independently versioned inbound. Candidate capture, rehearsal, release creation,
Hex publication, and exact-Hex adoption have explicit lifecycle boundaries and
immutable evidence. The current target remains inactive; this plan performed no
merge, tag, GitHub release, package publication, or admin/operator UI change.

## Accomplishments

- Extracted one exact release-policy owner for package-set validation, stable
  versions, manifest/source equality, candidate and content digests, proposal
  identity, authorization lifecycle, final tag identity, publication evidence,
  and adoption completion.
- Bound the candidate to the Release Please proposal head/source SHAs and a
  canonical SHA-256 digest over each package's exact Hex file whitelist. The
  mutable release ledger is excluded from that content identity.
- Made proposal capture execute from protected controls against an isolated
  proposal worktree. Fresh runners install and compile the protected policy
  runtime before capture; caller-controlled trees never supply executable
  policy or digest helpers.
- Disarmed ordinary auto-merge. Push, schedule, release events, and digestless
  dispatches remain proposal-only or inert. The documented protected sequence
  uses one exact digest across separate release and publication dispatches.
- Kept dry-run credential-free and read-only while requiring the full package
  set, exact proposal SHA/content, source versions, and available CI evidence.
  Only the live exact-digest path can reach job-local Actions writes or the
  protected Hex environment.
- Required the canonical core release tag, all three expected tags on one SHA,
  and ordered core → admin → inbound publication. Hex idempotency compares the
  registry checksum with the SHA-256 of the actual outer package tar and fails
  closed on transport, HTTP, malformed, ambiguous, retired, or mismatched state.
- Parameterized the post-publish proof with three exact public versions and the
  immutable final SHA. The generated host runs the full twenty-stage Plan 01
  journey in both supported migration orders without path/git dependencies.
- Persisted separate generated-host and trust-runner checkpoints plus their
  SHA256SUMS record as durable adoption evidence outside temporary workspaces.
- Added real CLI lifecycle validation for captured, authorized, published, and
  completed targets. Naive or legacy direct flag placement now fails loudly.
- Added an external read-only publication verifier. It requires the canonical
  repository/workflow, exact successful seven-job live graph, one retry-safe
  run artifact, matching candidate digest/core tag/tag SHA/three versions,
  distinct GitHub release IDs, exact tag refs, and active checksum-matching Hex
  releases. Artifact archives and their uncompressed proof are size-bounded.
- Updated the later human-gated plans so published and completed evidence is
  executable and exact. Plans 05 and 06 still require explicit digest-bound
  human authorization before irreversible external action.

## Representative Commits

- `5a712117` — extract release candidate policy
- `3f29ff77` — prepare protected release dispatch
- `8679d9a1` — capture synchronized release proposals
- `cf63655b` — unify publishable content digest
- `89c0d3d8` — bind protected release to main
- `34c6856c` — run full exact-Hex host proof
- `461bb69e` — isolate release proposal execution
- `cf6c754f` — validate release evidence lifecycle
- `fadcceb5` — bind durable release evidence
- `fa162f2c` — add external publication verification
- `dbe6376b` — bind publication run to candidate
- `300fdec4` — harden publication proof recovery
- `e0b0c9d4` — bound actual publication proof extraction

## Verification

- Focused release, policy, workflow, generated-host, post-publish, trust-runner,
  and external-evidence suite: 94 tests, 0 failures.
- `actionlint` passed for Release Please, publish, and post-publish workflows.
- `bash -n` and ShellCheck passed for all release, proof, and verifier helpers.
- Focused Elixir formatting and `git diff --check` passed.
- Independent adversarial review drove protected-control isolation, exact-Hex
  proof expansion, lifecycle execution, manifest/source binding, durable proof
  retention, live-job verification, run-to-candidate provenance, retry-safe
  artifact replacement, canonical ref enforcement, and archive bounds.

## Deviations and Review Fixes

The initial workflow contracts left several identities adjacent rather than
cryptographically or structurally connected. Review converted those seams into
explicit comparisons: protected controls versus candidate data, proposal versus
manifest/source, run versus live jobs, run artifact versus candidate digest,
and publication versus exact registry checksums. Each repair was introduced by
a hostile failing test before its implementation.

The publication verifier lives in the repository before Plan 06 so the later
irreversible checkpoint has an executable acceptance gate rather than prose or
schema validation alone. This is preparation only and does not complete REL-04.

## Scope Confirmation

No release proposal was merged, no tag or GitHub release was created, no Hex
credential was used, and no package was published. The release target remains
inactive. No admin/operator UI code, route, LiveView, styling, navigation, or
browser behavior changed.

## Self-Check: PASSED

Plan 04's release machinery is deterministic, all-package, protected, and
externally inert. The next step is Plan 05 candidate capture and its explicit
digest-bound authorization checkpoint.
