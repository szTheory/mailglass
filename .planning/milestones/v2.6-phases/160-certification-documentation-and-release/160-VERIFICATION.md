---
phase: 160-certification-documentation-and-release
verified: 2026-08-20T23:10:41Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
requirements:
  - REL-01
  - REL-02
  - REL-03
  - REL-04
automated_evidence:
  - "22 generated-host/trust-runner contract tests: 0 failures"
  - "36 reconciliation/release-policy/publication-verifier tests: 0 failures"
  - "72 core/inbound documentation-contract tests: 0 failures (1 documented historical skip)"
  - "14 post-publish/adoption contract tests: 0 failures"
  - "release_policy verify-complete: completed=true"
  - "fresh protected-publication verifier passed against a published lifecycle view of the completed immutable ledger"
---

# Phase 160: Certification, Documentation, and Release Verification Report

**Phase Goal:** A real generated host and protected publication prove the additive v2.6 package family is accurate, documented, and adoptable from Hex.
**Verified:** 2026-08-20T23:10:41Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A generated Phoenix/Ecto/Postgres host proves fresh install, durable send/queue behavior, upgrades and rollbacks, idempotent reruns, custom modules, multiple repositories, and non-public schema prefixes. | ✓ VERIFIED | `scripts/generated_ecto_host_proof.sh` requires the exact ordered 20-stage manifest. Its focused contracts passed (22 tests). The immutable exact-Hex smoke artifact contains all 10 stages in both core-first and inbound-first order, all `passed`; its SHA-256 is `0dc107…3157fc0`, equal to the completed ledger. |
| 2 | Current v2 documentation accurately identifies additive interfaces, active deprecations, and v3 removal targets without stale milestone claims. | ✓ VERIFIED | Core/inbound docs contracts and `mix mailglass.docs.check` passed; 47 core tests (one historical skip) and 25 inbound tests passed. The contract mutation tests reject stale lifecycle and fabricated admin/operator promises. |
| 3 | Repository manifests match live Hex versions before a protected release candidate is created. | ✓ VERIFIED | The immutable release tag `0f0b06861b1cbb2e89f44ea4f40db754effc4017` declares `2.5.0/2.5.0/2.2.0`, exactly matching fresh Hex release checksums. The reconciliation mutation suite passed (36 combined policy/reconciler/verifier tests); its current-tree live check correctly reports drift because the post-release development checkout deliberately remains at the prior `2.4.1/2.4.1/2.1.2` baseline. This does not contradict the time-qualified pre-candidate requirement. |
| 4 | The protected pipeline publishes additive core, admin, and inbound releases, and an exact-Hex host completes post-publish adoption proof with existing operator behavior preserved. | ✓ VERIFIED | Fresh GitHub API evidence shows publication run `32416453778` completed successfully with exactly prepublish, CI gate, core, admin, inbound, and smoke-dispatch jobs. Fresh external verifier confirmed all three GitHub releases/tags/Hex artifacts for the ledger’s candidate and tag SHA. Smoke run `32425143336` completed successfully; its downloaded artifact hashes match the ledger’s generated-host and trust-runner digests. Focused post-publish contracts passed (14 tests). |

**Score:** 4/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `scripts/generated_ecto_host_proof.sh` | Generated-host certification journey | ✓ VERIFIED | Substantive 1,244-line harness invokes public generators, runtime/database assertions, and exact checkpoint validation; workflow executes it in `exact_hex` mode. |
| `test/scripts/generated_ecto_host_proof_test.exs` | Negative controls for host stages | ✓ VERIFIED | Included in the fresh 22-test focused contract run. |
| `docs/api_stability.md` and `mailglass_inbound/docs/api_stability.md` | Public v2 stability/deprecation contracts | ✓ VERIFIED | Wired to core and inbound documentation contract suites; tests passed. |
| `scripts/reconcile_release_versions.exs` | Fail-closed live/repository reconciler | ✓ VERIFIED | Parses three manifests/constraints, queries Hex read-only, and its hostile-input suite passed. |
| `scripts/release_policy.exs` and `.planning/release-target.json` | Candidate, authorization, publication, and completion ledger | ✓ VERIFIED | `verify-complete` passed with the exact 2.5.0/2.5.0/2.2.0 package set and immutable tag SHA. |
| `.github/workflows/publish-hex.yml` and `.github/workflows/post-publish-smoke.yml` | Protected publication and exact-Hex adoption wiring | ✓ VERIFIED | Policy digest gates core → admin → inbound; smoke consumes three named exact versions, forbids path fallback, and runs host/trust proofs. Contract suite passed. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `scripts/generated_ecto_host_proof.sh` | Public core/inbound migration tasks | Generated `mix mailglass.gen.migration` and `mix mailglass.inbound.gen.migration` calls | ✓ WIRED | The harness calls generated wrappers against `Host.Repo` and `Host.InboundRepo`, rather than repository test DDL. |
| Documentation upgrade guide | Generated-host commands | Repo-explicit migration commands | ✓ WIRED | Documentation contract requires the public commands used by the harness. |
| Reconciler | `.release-please-manifest.json` | Exact three-package parse and comparison | ✓ WIRED | Fresh mutation suite exercises missing/duplicate/malformed/retired/conflicting evidence failures. |
| `publish-hex.yml` | `post-publish-smoke.yml` | Exact candidate digest, ordered all-package publication, protected smoke dispatch | ✓ WIRED | Live run completed each required job; workflow source requires successful inbound publication before dispatch. |
| `post-publish-smoke.yml` | Exact Hex artifacts | Three exact versions and immutable target ref | ✓ WIRED | Workflow sets `MAILGLASS_PACKAGE_MODE=exact_hex`, passes all three version outputs, and executes host plus trust-runner proof. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Generated-host proof | Ordered checkpoint rows | Disposable host runtime and PostgreSQL queries | Downloaded immutable smoke artifact contains 20 non-empty passed rows | ✓ FLOWING |
| Release ledger | Publication/adoption evidence | GitHub Actions runs, GitHub releases/tags, and Hex release records | Fresh GitHub/Hex checks matched ledger IDs, tag SHA, versions, and checksums | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Completion ledger validates all required identities | `mix run … release_policy.exs … verify-complete .planning/release-target.json` | `completed=true`, exact versions and both immutable run URLs | ✓ PASS |
| Publication remains externally verifiable | `bash scripts/verify_published_release.sh <published lifecycle view>` | Exact candidate/tag/release/Hex evidence verified | ✓ PASS |
| Exact-Hex and trust workflow wiring resists mutation | `mix test test/mailglass/publish/post_publish_smoke_contract_test.exs test/reference_host/trust_runner_checkpoint_contract_test.exs --warnings-as-errors` | 14 tests, 0 failures | ✓ PASS |
| Generated-host checkpoints are non-vacuous | `mix test test/scripts/generated_ecto_host_proof_test.exs test/reference_host/trust_runner_command_contract_test.exs test/reference_host/trust_runner_checkpoint_contract_test.exs --warnings-as-errors` | 22 tests, 0 failures | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
| --- | --- | --- | --- |
| REL-01 | 160-01 | Real generated host proves install, durable delivery, migration, repo, and prefix behavior | ✓ SATISFIED | 20-stage exact-Hex artifact plus fresh 22-test host/trust contracts. |
| REL-02 | 160-02 | Current additive v2 API/stability documentation | ✓ SATISFIED | Docs checker plus 72 focused core/inbound contract tests. |
| REL-03 | 160-03, 160-04, 160-05 | Reconcile live/repository versions before protected candidate | ✓ SATISFIED | Fail-closed reconciler/policy test suite; immutable tag and fresh Hex exact-version evidence. |
| REL-04 | 160-04, 160-05, 160-06 | Protected all-package publication and exact-Hex adoption proof | ✓ SATISFIED | Fresh protected publication verifier, GitHub run/job evidence, smoke artifact digest verification, and 14 focused contracts. |

No requirement mapped to Phase 160 is orphaned from the phase plans.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `docs/api_stability.md` | 1446 | “not yet implemented” | ℹ️ Info | Documents a reserved historical v0.5 hook; it is outside the v2.6 release claim and does not feed user-visible phase behavior. |
| `scripts/generated_ecto_host_proof.sh` | 387, 393 | “not available” failure messages | ℹ️ Info | Explicit fail-closed Hex availability checks, not placeholders. |

No untracked `TBD`, `FIXME`, or `XXX` debt marker was found in the reviewed implementation files.

### Human Verification Required

None. The release outcome, exact package identities, runtime host stages, and protected workflow evidence all have executable or immutable external evidence.

## Notes

`scripts/verify_published_release.sh` deliberately accepts only `status: published`; the final ledger is correctly `completed`. To re-check immutable external publication evidence without mutating the repository ledger, verification used an equivalent temporary published lifecycle view with adoption evidence removed. The same script then passed against GitHub and Hex.

The post-release working checkout keeps prior baseline manifest versions, so `mix run scripts/reconcile_release_versions.exs --check-live` now emits the expected drift to public 2.5.0/2.5.0/2.2.0. The pre-candidate condition is proven by the immutable release tag and ledger, not by requiring a development checkout to keep release-version declarations after publication.

---

_Verified: 2026-08-20T23:10:41Z_
_Verifier: the agent (gsd-verifier)_
