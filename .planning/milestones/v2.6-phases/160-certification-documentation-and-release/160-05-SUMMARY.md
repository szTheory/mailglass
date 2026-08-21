---
phase: 160-certification-documentation-and-release
plan: 05
subsystem: exact-release-candidate-authorization
tags: [release, release-please, authorization, provenance, package-rehearsal]
requires: [REL-03, REL-04]
provides:
  - one immutable three-package candidate captured from synchronized Release Please output
  - explicit maintainer authorization bound to the exact candidate digest
  - green credential-free package and protected-CI evidence for the authorized proposal
affects: [protected-release-dispatch, package-publication, post-publish-certification]
tech-stack:
  added: []
  patterns: [digest-bound-human-authorization, exact-proposal-rehearsal, fail-closed-candidate-regeneration]
key-files:
  created:
    - .planning/phases/160-certification-documentation-and-release/160-05-SUMMARY.md
  modified:
    - .planning/release-target.json
    - .planning/publish/mailglass-files.expected
    - .planning/publish/mailglass_inbound-files.expected
    - CHANGELOG.md
    - mailglass_admin/CHANGELOG.md
    - mailglass_inbound/CHANGELOG.md
key-decisions:
  - "The first candidate was rejected after package rehearsal exposed stale core and inbound allowlists; no authorization carried across regeneration."
  - "Authorization applies only to candidate digest 372e6ae676e9cd8bdc15de9830da66d49f256327215dcbd73a480060e89fa450 and its exact proposal, versions, package set, and content digest."
  - "Plan 160-06 still requires a separate explicit publish decision before protected release automation may run."
requirements-completed: []
completed: 2026-08-20
---

# Phase 160 Plan 05: Exact Release Candidate Authorization Summary

Release Please PR #209 now represents one synchronized, fully rehearsed
three-package candidate. The maintainer explicitly authorized its exact digest,
but no release proposal was merged and no tag, GitHub release, Hex credential,
or package publication was created.

## Authorized Candidate

- Candidate digest: `372e6ae676e9cd8bdc15de9830da66d49f256327215dcbd73a480060e89fa450`
- Proposal head: `30f576536bd77cde3231d1e74608eda6cd553bb4`
- Source SHA: `f338bcedab186e5423fa9eaadf7406c71377bdf9`
- Publishable-content digest: `90cf4e86b3573e42acf1cfe2f6ff28315e951a5e315e8ac91c53b59734d9c270`
- Versions: `mailglass 2.5.0`, `mailglass_admin 2.5.0`, `mailglass_inbound 2.2.0`
- Package set: `mailglass`, `mailglass_admin`, `mailglass_inbound`
- Release Please PR: `https://github.com/szTheory/mailglass/pull/209`
- Candidate workflow run: `https://github.com/szTheory/mailglass/actions/runs/32373670493`
- Candidate artifact ID: `9408281958`

## Accomplishments

- Rejected candidate `5814bd255019d3e79a773f6ca3b0593bdf7bfc293e0ae9f7d4700b64dd7fe498`
  when its credential-free rehearsal found 16 missing core files and 5 missing
  inbound files in the golden publish inventories.
- Added only those 21 verified package inventory entries and proved all three
  package checks from a clean protected-main worktree.
- Landed corrective PR #214 on `main`, synchronized `main` into Release Please
  PR #209, and generated a new proposal identity. The old authorization digest
  was never reused.
- Copied the exact automation-generated changelog sections and candidate
  identity into the release target without selecting or editing versions by
  judgment.
- Recorded the maintainer's exact digest-bearing authorization and transitioned
  only `status` and `states.authorization` from captured to authorized.

## Representative Commits

- `2fc51f5b` — refresh v2.6 package allowlists
- `33eb7607` — record the rejected candidate blocker
- `07f32c56` — capture the synchronized exact release candidate
- `c6e4f303` — authorize the exact release candidate

Corrective PR #214 landed on `main` as `f338bced`; it was a recovery-only
allowlist fix, not the generated release proposal.

## Verification

- Release Please PR #209: 33 successful checks, 1 intentionally skipped, 0
  failed, 0 pending; merge state `CLEAN`.
- Focused release-policy suite: 14 tests, 0 failures.
- Exact candidate validation and protected-dispatch validation both returned
  the authorized digest and exact proposal/content identities above.
- Live Hex reconciliation returned `reconciled` with baselines
  `2.4.1 / 2.4.1 / 2.1.2`, matching recorded release checksums.
- Exact proposal-head rehearsals passed for core, admin, and inbound with
  `conflict=0`, including allowlist, denylist, required-file, changelog,
  metadata, dependency, isolated compile, Hex audit, dependency audit, and OSV
  freshness gates.
- `git diff --check` passed.

## Deviation and Recovery

The first candidate failed closed on stale publish inventories. With explicit
maintainer approval, a focused corrective PR was merged before candidate
regeneration. This was the only merge performed during recovery; Release Please
PR #209 remained open. Because synchronization changed the proposal head and
source SHA, the workflow generated a new candidate digest and required a fresh
explicit authorization.

## Scope Confirmation

No generated release proposal was merged, no release tag or GitHub release was
created, no Hex credential was accessed, and no package was published. Final tag
identity remains null and publication remains `not_started`.

## Self-Check: PASSED

Plan 160-05 ends with one exact authorized candidate. Plan 160-06 must obtain a
separate `publish <candidate_digest>` decision before invoking the protected
release sequence.
