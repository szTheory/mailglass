---
phase: "164"
slug: repository-truth-reconciliation-and-closeout
status: pending_terminal
threats_open: 1
asvs_level: 1
block_on: high
created: "2026-09-01"
---

# Phase 164 — Security

> Retroactive ASVS L1 verification of the STRIDE registers authored in the Phase 164 plans. High-severity open threats block phase completion.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Canonical checkout | Local repository identity versus protected `szTheory/mailglass` main | repository path, remote identity, Git SHA, porcelain |
| GitHub evidence | Local finalizer versus GitHub Actions APIs and retained artifacts | workflow/run identity, attempt, event, SHA, artifact digests |
| Ignored capture area | Finalizer and closeout scripts versus predictable local paths | JSON evidence, component output, filesystem links |
| Truth ledger | Tracked disposition claims versus repository-derived inventory | subject identity, state, authority, evidence, disposition |
| Operator guidance | Documentation versus runtime dependency availability | supported commands, package scope, current contract version |

## Threat Register

The authoritative key is `{plan, threat_id}`. This preserves repeated identifiers
without conflating distinct authored definitions.

| Plan | Threat ID | Category | Component | Severity | Disposition | Mitigation / Evidence | Status |
|------|-----------|----------|-----------|----------|-------------|-----------------------|--------|
| 01 | T-164-01 | Tampering | scheduled-control-sweep.json identity | high | mitigate | Compute SHA-256 before deletion and require D-08's exact digest. Audit: mitigation verified at ASVS L1. | closed |
| 01 | T-164-02 | Repudiation | disposition ledger row | high | mitigate | Test mandatory fields, unique subject, evidence, and exact disposition enum. Audit: mitigation verified at ASVS L1. | closed |
| 01 | T-164-03 | Tampering | ignore rules | high | mitigate | Assert all six ignore files are unchanged and no proof-hiding pattern is added. Audit: mitigation verified at ASVS L1. | closed |
| 01 | T-164-SC | Tampering | package supply chain | low | accept | No package-manager install, dependency, action, or lockfile changes occur. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 02 | T-164-04 | Elevation of Privilege | MAINTAINING.md release path | high | mitigate | Contract exact-digest and repository-admin conditions and proposal-only ordinary triggers. Audit: mitigation verified at ASVS L1. | closed |
| 02 | T-164-05 | Spoofing | exact run/package observations | high | mitigate | Require exact identities and fail closed on unavailable/malformed evidence. Audit: mitigation verified at ASVS L1. | closed |
| 02 | T-164-06 | Repudiation | historical runbook boundary | medium | mitigate | Preserve linked history under explicit applicability labels. Audit: mitigation verified at ASVS L1. | closed |
| 02 | T-164-SC | Tampering | package supply chain | low | accept | No dependency or action install occurs. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 03 | T-164-07 | Spoofing | package-version claims | medium | mitigate | Derive compatibility assertions from all three manifests and retain publish-summary evidence. Audit: mitigation verified at ASVS L1. | closed |
| 03 | T-164-08 | Tampering | historical version records | medium | mitigate | Scope edits to current README sections and forbid global replacement. Audit: mitigation verified at ASVS L1. | closed |
| 03 | T-164-SC | Tampering | package supply chain | low | accept | No manifest version, dependency, lockfile, or package content changes occur. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 04 | T-164-09 | Tampering | audited subject set | high | mitigate | Derive expected sets from Git and six ignore files; require equality and unique keys. Audit: mitigation verified at ASVS L1. | closed |
| 04 | T-164-10 | Repudiation | disposition rationale/evidence | high | mitigate | Reject blank authority, currentness, consumer, evidence, disposition, or rationale fields. Audit: mitigation verified at ASVS L1. | closed |
| 04 | T-164-11 | Information Disclosure | machine-local artifacts | medium | mitigate | Retain narrow existing cache rules with named producers; never copy secrets into ledger evidence. Audit: mitigation verified at ASVS L1. | closed |
| 04 | T-164-SC | Tampering | package supply chain | low | accept | No dependency installation or package metadata change occurs. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 05 | T-164-12 | Spoofing | exact main / CI run identity | high | mitigate | Require branch, local/remote SHA equality, exact run ID, and matching CI head SHA. Audit: mitigation verified at ASVS L1. | closed |
| 05 | T-164-13 | Tampering | scheduled artifact provenance | high | mitigate | Reuse verifier and require event/run/workflow/head/artifact bindings. Audit: mitigation verified at ASVS L1. | closed |
| 05 | T-164-14 | Repudiation | aggregate status precedence | high | mitigate | Fixture-test malformed/unavailable/pending/blocked/pass branches and preserve source outputs. Audit: mitigation verified at ASVS L1. | closed |
| 05 | T-164-15 | Elevation of Privilege | release/control operations | high | mitigate | Wrapper is read-only and exposes no dispatch, rerun, merge, publish, or authorization operation. Audit: mitigation verified at ASVS L1. | closed |
| 05 | T-164-SC | Tampering | package supply chain | low | accept | No install task or dependency change occurs. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 06 | T-164-16 | Spoofing | main SHA / CI run handoff | high | mitigate | Require exact local/remote equality and independently re-query the exact run in Plan 164-07. Audit: mitigation verified at ASVS L1. | closed |
| 06 | T-164-17 | Elevation of Privilege | protected merge/release controls | high | mitigate | Checkpoint authorizes observation only and forbids bypass, dispatch substitution, and publication. Audit: mitigation verified at ASVS L1. | closed |
| 06 | T-164-SC | Tampering | package supply chain | low | accept | No package or action changes occur. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 07 | T-164-18 | Spoofing | final main/CI identity | high | mitigate | Re-fetch and require local HEAD, origin/main, report SHA, and exact CI run SHA equality. Audit: mitigation verified at ASVS L1. | closed |
| 07 | T-164-19 | Tampering | final component results | high | mitigate | Parse persisted component outputs and reject incomplete/malformed/mismatched evidence. Audit: mitigation verified at ASVS L1. | closed |
| 07 | T-164-20 | Repudiation | quiet verdict | high | mitigate | Retain timestamp, IDs, component paths, statuses, and reasons in the volatile report. Audit: mitigation verified at ASVS L1. | closed |
| 07 | T-164-21 | Elevation of Privilege | recovery/release controls | high | mitigate | Read-only invocation; no dispatch, rerun, merge, tag, or publish capability. Audit: mitigation verified at ASVS L1. | closed |
| 07 | T-164-SC | Tampering | package supply chain | low | accept | No package installation or dependency change occurs. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 08 | T-164-22 | Tampering | currentness/disposition fields | high | mitigate | Exact enum parsing plus stale-outcome tests in the shared production validator. Audit: mitigation verified at ASVS L1. | closed |
| 08 | T-164-23 | Repudiation | audited-subject completeness | high | mitigate | Derive required subjects from Git, plans, proof paths, verification evidence, and six ignore files. Audit: mitigation verified at ASVS L1. | closed |
| 08 | T-164-24 | Tampering | duplicate/adjacent ledger rows | medium | mitigate | Reject exact duplicate subjects independent of adjacency or row ordering. Audit: mitigation verified at ASVS L1. | closed |
| 08 | T-164-SC | Tampering | package supply chain | low | accept | No package-manager install, dependency, action, or lockfile change occurs. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 09 | T-164-25 | Spoofing | `--repo` identity | high | mitigate | Resolve physical path and require exact canonical equality before component execution. Audit: mitigation verified at ASVS L1. | closed |
| 09 | T-164-26 | Tampering | `--ledger` authority | high | mitigate | Require exact canonical ledger path and invoke the shared full validator. Audit: mitigation verified at ASVS L1. | closed |
| 09 | T-164-27 | Repudiation | output/porcelain ordering | high | mitigate | Require ignored canonical tmp output and recheck porcelain after atomic writes. Audit: mitigation verified at ASVS L1. | closed |
| 09 | T-164-28 | Elevation of Privilege | closeout operations | high | mitigate | Preserve read-only remote behavior; expose no dispatch, rerun, merge, publish, or authority mutation. Audit: mitigation verified at ASVS L1. | closed |
| 09 | T-164-SC | Tampering | package supply chain | low | accept | No install task, dependency, action, or lockfile change occurs. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 10 | T-164-36 | Tampering | duplicated freshness predicate | high | mitigate | Delegate age comparison exclusively to the registry-driven sweep and regression-test daily evidence beyond three hours. Audit: mitigation verified at ASVS L1. | closed |
| 10 | T-164-37 | Spoofing | scheduled run identity | high | mitigate | Retain exact expected-main, head SHA, event, branch, terminal status, and workflow-SHA assertions with one-field mutation tests. Audit: mitigation verified at ASVS L1. | closed |
| 10 | T-164-38 | Repudiation | evidence-valid provenance/result | high | mitigate | Require successful sweep, top-level and per-control evidence validity, and the established allowed result envelope. Audit: mitigation verified at ASVS L1. | closed |
| 10 | T-164-39 | Elevation of Privilege | GitHub workflow controls | medium | mitigate | Modify no workflow, dispatch, rerun, authorization, release, or publication surface. Audit: mitigation verified at ASVS L1. | closed |
| 10 | T-164-SC | Tampering | package supply chain | low | accept | No package-manager install, dependency, action, or lockfile change occurs. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 13 | T-164-45 | Tampering | ledger currentness and subject set | high | mitigate | Production-module mutation matrix covers exact enums, complete inventory, duplicate placement, and order invariance. Audit: mitigation verified at ASVS L1. | closed |
| 13 | T-164-46 | Spoofing | repository and ledger path identity | high | mitigate | Process fixtures require resolved exact canonical identities and prove preflight rejection before collection. Audit: mitigation verified at ASVS L1. | closed |
| 13 | T-164-47 | Tampering | report/component destinations | high | mitigate | Reject non-ignored/symlinked destinations and exercise final stable-porcelain precedence after writes. Audit: mitigation verified at ASVS L1. | closed |
| 13 | T-164-48 | Repudiation | regression evidence | medium | mitigate | Named tagged tests emit precise error assertions through the production seams. Audit: mitigation verified at ASVS L1. | closed |
| 13 | T-164-SC | Tampering | package supply chain | low | accept | No package-manager install, dependency, action, or lockfile change occurs. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 14 | T-164-49 | Spoofing | protected-main and CI identity | high | mitigate | Fetch and require canonical branch/HEAD/origin equality; finalizer selects and independently validates attempt-one exact-SHA normal push CI. Audit: mitigation verified at ASVS L1. | closed |
| 14 | T-164-50 | Tampering | scheduled evidence set/provenance | high | mitigate | Require exact registry set plus per-control attempt, event, workflow, SHA, status, reason, and digest checks. Audit: mitigation verified at ASVS L1. | closed |
| 14 | T-164-51 | Repudiation | pre-verification versus terminal boundary | high | mitigate | Track the lifecycle contract and label the summary-caused SHA change; terminal capture occurs only after completion metadata with no later tracked write. Audit: mitigation verified at ASVS L1. | closed |
| 14 | T-164-52 | Elevation of Privilege | remote workflow/release controls | high | mitigate | Observation-only checkpoint forbids dispatch, rerun, protection bypass, authority change, and forced publication. Audit: mitigation verified at ASVS L1. | closed |
| 14 | T-164-SC | Tampering | package supply chain | low | accept | No package-manager install, dependency, action, or lockfile change occurs. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 15 | T-164-53 | Tampering | terminal verifier-to-HEAD binding | high | mitigate | Require explicit verified implementation SHA, ancestor proof, exact per-first-parent-commit metadata path checks, and direct plus change-then-revert process regressions. Audit: mitigation verified at ASVS L1. | closed |
| 15 | T-164-54 | Repudiation | pre-verification repair prerequisites | high | mitigate | Require summaries 01-13 and prove missing Plan 13 stops before evidence collection. Audit: mitigation verified at ASVS L1. | closed |
| 15 | T-164-55 | Denial of Service | hostile fixture teardown | high | mitigate | Use exclusive allocation plus token, lstat, resolved-parent, and basename ownership checks before recursive cleanup. Audit: mitigation verified at ASVS L1. | closed |
| 15 | T-164-56 | Spoofing | scheduled `updated_at` freshness | high | mitigate | Reject malformed and negative age independently in producer sweep and terminal raw validation with boundary fixtures. Audit: mitigation verified at ASVS L1. | closed |
| 15 | T-164-57 | Repudiation | integrated TRTH-01/TRTH-02 proof | medium | mitigate | Rerun maintainer/package contracts and authoritative ledger validator with the complete focused suite. Audit: mitigation verified at ASVS L1. | closed |
| 16 | T-164-58 | Elevation of Privilege | non-historical `MAINTAINING.md` release guidance | high | mitigate | Scan the complete pre-historical region and reject automatic, reviewer-free, or approval-free authority while requiring the protected exact-candidate and repository-admin terms. Audit: mitigation verified at ASVS L1. | closed |
| 16 | T-164-59 | Repudiation | historical v0.1/v0.5 authority provenance | medium | mitigate | Retain the rationale only under the exact historical boundary with explicit version applicability. Audit: mitigation verified at ASVS L1. | closed |
| 16 | T-164-60 | Tampering | executable protected-release controls | low | accept | This plan modifies documentation and its contract only; acceptance requires no workflow or release-policy diff. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 17 | T-164-61 | Spoofing | `state=tracked` ledger rows | high | mitigate | Require regular-file type, `git --literal-pathspecs ls-files --error-unmatch -- <subject>`, exact single returned-path equality, and metacharacter/prefix-adjacency disposable-repository regressions. Audit: mitigation verified at ASVS L1. | closed |
| 17 | T-164-62 | Elevation of Privilege | finalize-phase extension dispatch | high | mitigate | Authenticate exact HEAD blobs and index/worktree equality for both the phase shim and `scripts/finalize_phase_164.sh`, then directly execute only a private materialization of the downstream committed blob. Audit: mitigation verified at ASVS L1. | closed |
| 17 | T-164-63 | Tampering | downstream finalizer and temporary materialization | high | mitigate | Keep the shim unchanged in staged/unstaged downstream mutation regressions, use restrictive permissions, source executable bytes only from the downstream Git blob, never dispatch either checkout pathname, and clean up in `finally`. Audit: mitigation verified at ASVS L1. | closed |
| 17 | T-164-64 | Repudiation | standalone validator invocation | medium | mitigate | Make every invalid invocation emit a bounded diagnostic and nonzero status under subprocess tests. Audit: mitigation verified at ASVS L1. | closed |
| 17 | T-164-SC | Tampering | package supply chain | low | accept | No package-manager install, dependency, action, or lockfile change occurs. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 18 | T-164-65 | Spoofing | `tracked_subject_in_index/2` | high | mitigate | Require one NUL-delimited exact-path stage-0 record and reject every nonzero or additional stage. Audit: mitigation verified at ASVS L1. | closed |
| 18 | T-164-66 | Tampering | Git staged-record parser | high | mitigate | Exercise malformed, multi-record, embedded-newline, metacharacter, and prefix-adjacent cases through argv-only Git calls. Audit: mitigation verified at ASVS L1. | closed |
| 18 | T-164-67 | Repudiation | tracked disposition verdict | medium | mitigate | Preserve distinct bounded errors and execute the complete production validation path in the conflict fixture. Audit: mitigation verified at ASVS L1. | closed |
| 18 | T-164-SC | Tampering | package supply chain | low | accept | No package-manager install, dependency, action, or lockfile change occurs. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 19 | T-164-68 | Spoofing | lexical phase shim / phase argument | high | mitigate | Require phase 164, lexical lstat regular-file identity, exact HEAD path authentication, then containment. Audit: mitigation verified at ASVS L1. | closed |
| 19 | T-164-69 | Tampering | transitive executable/data chain | high | mitigate | Authenticate a closed manifest, materialize all members before Bash, and reject missing/non-blob/escaping members. Audit: mitigation verified at ASVS L1. | closed |
| 19 | T-164-70 | Elevation of Privilege | hidden checkout helper mutation | high | mitigate | Execute helpers from the private HEAD authority root and prove assume-unchanged markers cannot run. Audit: mitigation verified at ASVS L1. | closed |
| 19 | T-164-71 | Information Disclosure | abandoned private materialization | medium | mitigate | Remove the complete authority root in `finally` on success, ordinary failure, and print-mode failure. Audit: mitigation verified at ASVS L1. | closed |
| 19 | T-164-72 | Repudiation | cross-phase dispatch result | high | mitigate | Reject unsupported phases before discovery and assert no downstream call/marker for alternate phase input. Audit: mitigation verified at ASVS L1. | closed |
| 19 | T-164-SC | Tampering | package supply chain | low | accept | No package-manager install, dependency, action, or lockfile change occurs. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 20 | T-164-73 | Repudiation | `164-VALIDATION.md` | high | mitigate | Map every repaired gap to a named production-seam command and record only observed results. Audit: mitigation verified at ASVS L1. | closed |
| 20 | T-164-74 | Spoofing | `164-FINALIZATION.md` lifecycle claims | high | mitigate | Describe the exact Phase-164-only lexical and HEAD-authority-root implementation, not the superseded Plan 17 chain. Audit: mitigation verified at ASVS L1. | closed |
| 20 | T-164-75 | Elevation of Privilege | terminal boundary prose | high | mitigate | Retain ordinary verification and protected completion-metadata prerequisites; do not run or claim terminal finalization. Audit: mitigation verified at ASVS L1. | closed |
| 20 | T-164-SC | Tampering | package supply chain | low | accept | No package-manager install, dependency, action, or lockfile change occurs. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 21 | T-164-76 | Tampering | commit-object authentication | high | mitigate | Capture one full OID once; address every tree/blob operation by that OID; re-check live HEAD immediately before Bash. Audit: mitigation verified at ASVS L1. | closed |
| 21 | T-164-77 | Repudiation | numbered Phase 164 history | high | mitigate | Compare captured-OID NUL tree output to the explicit exact PLAN/SUMMARY set through Plan 24, including locked baseline 01–20. Audit: mitigation verified at ASVS L1. | closed |
| 21 | T-164-78 | Elevation of Privilege | private Bash dispatch | high | mitigate | Materialize only authenticated bytes with 0700/0500/0400 modes and remove the root in finally. Audit: mitigation verified at ASVS L1. | closed |
| 21 | T-164-79 | Denial of Service | adversarial Git output | medium | mitigate | Reject malformed framing/cardinality and bound diagnostics/output. Audit: mitigation verified at ASVS L1. | closed |
| 21 | T-164-SC | Tampering | package supply chain | low | accept | No npm/pip/cargo install or third-party dependency is introduced; the later install copies one authenticated repository blob to a private user command path. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 22 | T-164-80 | Elevation of Privilege | retired `.gsd` extension | high | mitigate | Remove tracked auto-loaded code and regress hostile untracked recreation against direct installed-loader execution. Audit: mitigation verified at ASVS L1. | closed |
| 22 | T-164-81 | Repudiation | truth disposition ledger | high | mitigate | Preserve exact retired subjects, replacement evidence, and durable prior plan/summary references. Audit: mitigation verified at ASVS L1. | closed |
| 22 | T-164-82 | Spoofing | maintainer command guidance | high | mitigate | Whole-current-region tests require one exact installed command and reject the retired slash command as current authority. Audit: mitigation verified at ASVS L1. | closed |
| 22 | T-164-83 | Tampering | ignore rules | medium | mitigate | Add no exclusion for the retired extension or broader evidence paths; retain existing canonical ignore audit. Audit: mitigation verified at ASVS L1. | closed |
| 22 | T-164-SC | Tampering | package supply chain | low | accept | No package-manager dependency is installed; only project-authored loader bytes move to the explicit user command path in Plan 164-23. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 23 | T-164-84 | Tampering | loader source during installation | high | mitigate | Extract by captured OID, re-check HEAD/porcelain, and require source/destination digest equality. Audit: mitigation verified at ASVS L1. | closed |
| 23 | T-164-85 | Elevation of Privilege | destination path | high | mitigate | Reject symlink/non-regular/unexpected targets, require outside-repository containment, and install mode 0500. Audit: mitigation verified at ASVS L1. | closed |
| 23 | T-164-86 | Repudiation | install provenance | medium | mitigate | Persist the exact approved OID, digest, destination, mode, and conditional prior-object tuple in a mode-0400 checkpoint record; bind the summary to its digest. Audit: mitigation verified at ASVS L1. | closed |
| 23 | T-164-86A | Tampering | distinct prior-loader rollback | high | mitigate | Admit a distinct prior regular loader only through explicit immutable approval of digest/mode/stat identity/provenance/rollback path; reject post-approval drift, preserve it at mode 0400 before replacement, and exercise same-filesystem atomic restore plus temporary cleanup while retaining the backup. Audit: mitigation verified at ASVS L1. | closed |
| 23 | T-164-SC | Tampering | external dependency | low | accept | Installation introduces no third-party package; it copies authenticated project source into a user-owned command path. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 24 | T-164-87 | Spoofing | test subject identity | high | mitigate | Assert absolute installed path and checkpoint digest before running the production-boundary matrix. Audit: mitigation verified at ASVS L1. | closed |
| 24 | T-164-88 | Elevation of Privilege | hostile former extension | high | mitigate | Use an executable marker payload and prove direct installed invocation never imports it. Audit: mitigation verified at ASVS L1. | closed |
| 24 | T-164-89 | Repudiation | validation/finalization records | high | mitigate | Record named commands and actual counts; retain explicit non-terminal status. Audit: mitigation verified at ASVS L1. | closed |
| 24 | T-164-90 | Tampering | current documentation contract | medium | mitigate | Run whole-current-region and manifest-derived docs tests; preserve historical boundaries. Audit: mitigation verified at ASVS L1. | closed |
| 24 | T-164-SC | Tampering | installed executable and rollback provenance | high | mitigate | Bind self-check to the immutable approval-record OID, require complete summary parity, and conditionally verify the retained rollback object's non-symlink type, mode 0400, digest, and recorded restore/cleanup results before production-boundary tests. Audit: mitigation verified at ASVS L1. | closed |
| 25 | T-164-91 | Denial of Service | required CI lane | high | mitigate | Exclude only the installed-production tag from the generic directory scope and run the complete alias in verification. Audit: mitigation verified at ASVS L1. | closed |
| 25 | T-164-92 | Repudiation | installed-boundary evidence | high | mitigate | Preserve a named explicit alias with nonzero tagged tests; do not convert missing host state into a pass. Audit: mitigation verified at ASVS L1. | closed |
| 25 | T-164-93 | Tampering | CI/Mix scope mapping | high | mitigate | Source contracts bind the unchanged CI call site to exact include/exclude alias semantics. Audit: mitigation verified at ASVS L1. | closed |
| 25 | T-164-94 | Elevation of Privilege | CI topology | low | accept | No job, trigger, permission, release, or protected-check topology changes are introduced. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 25 | T-164-SC | Tampering | package supply chain | low | accept | No package-manager install or dependency change occurs. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 26 | T-164-95 | Spoofing | canonical repository selection | high | mitigate | Pin physical path and normalized origin in loader-owned code before dependency enumeration. Audit: mitigation verified at ASVS L1. | closed |
| 26 | T-164-96 | Elevation of Privilege | ambient executable lookup | high | mitigate | Pin Node startup, validate absolute Git/Bash/tool identities, and sanitize child environment/PATH. Audit: mitigation verified at ASVS L1. | closed |
| 26 | T-164-97 | Tampering | forged Git object responses | high | mitigate | Never invoke caller PATH Git; run an internally consistent fake-Git attack and require no marker. Audit: mitigation verified at ASVS L1. | closed |
| 26 | T-164-98 | Repudiation | installation provenance | high | mitigate | Require merge-base ancestry in addition to installed/current byte equality. Audit: mitigation verified at ASVS L1. | closed |
| 26 | T-164-99 | Denial of Service | missing trusted host tool | medium | mitigate | Fail before repository authentication with bounded diagnostic; installation preflight verifies readiness. Audit: mitigation verified at ASVS L1. | closed |
| 26 | T-164-SC | Tampering | package supply chain | low | accept | No package install or dependency change occurs; existing host executables are identity-validated. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 27 | T-164-100 | Tampering | installation source | high | mitigate | Extract by approved commit OID, compare digest/shebang/tool identities, never install checkout bytes. Audit: mitigation verified at ASVS L1. | closed |
| 27 | T-164-101 | Elevation of Privilege | destination replacement | high | mitigate | Blocking human approval, lstat/stat/digest rechecks, exact prior identity, atomic replacement. Audit: mitigation verified at ASVS L1. | closed |
| 27 | T-164-102 | Repudiation | prior installation provenance | high | mitigate | Preserve old approval and digest-addressed mode-0400 rollback bytes before mutation. Audit: mitigation verified at ASVS L1. | closed |
| 27 | T-164-103 | Spoofing | installed readiness | high | mitigate | Version, ancestry-aware self-check, and explicit controlled-host adversarial suite. Audit: mitigation verified at ASVS L1. | closed |
| 27 | T-164-104 | Tampering | terminal evidence ordering | high | mitigate | Forbid canonical pre-verification/terminal invocation during install and assert no report claim. Audit: mitigation verified at ASVS L1. | closed |
| 27 | T-164-SC | Tampering | external source movement | high | mitigate | Package legitimacy is not applicable; source is an authenticated in-repository Git blob and approval pins its exact digest. Audit: mitigation verified at ASVS L1. | closed |
| 28 | T-164-105 | Repudiation | validation/security records | high | mitigate | Bind every closure claim to named active tests, exact commands, and observed counts. Audit: mitigation verified at ASVS L1. | closed |
| 28 | T-164-106 | Tampering | exact numbered history | high | mitigate | Contract loader, shell, and records to exact PLAN/SUMMARY pairs 01–28. Audit: mitigation verified at ASVS L1. | closed |
| 28 | T-164-107 | Spoofing | terminal protected-main identity | high | mitigate | Require passed verifier SHA ancestry, completion-only descendants, exact successful attempt-1 push CI, and natural schedules. Audit: mitigation verified at ASVS L1. | closed |
| 28 | T-164-108 | Elevation of Privilege | terminal remote operations | high | mitigate | Preserve read-only behavior and forbid dispatch, rerun, merge, release, or publication substitutes. Audit: mitigation verified at ASVS L1. | closed |
| 28 | T-164-109 | Repudiation | no-later-write evidence | high | mitigate | Keep report ignored and document/test that no tracked artifact or metadata action follows capture. Audit: terminal protected evidence is absent and the authenticated range stops at Plan 39. | open |
| 28 | T-164-SC | Tampering | package supply chain | low | accept | No package-manager install or dependency change occurs; the installed project-authored blob was approved and identity-checked in Plan 164-27. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 29 | T-164-110 | Spoofing | installed authority proof | high | mitigate | Authenticate path/type/mode, exact approval schema, digest, committed blob, ancestry, and direct self-check. Audit: mitigation verified at ASVS L1. | closed |
| 29 | T-164-111 | Repudiation | controlled-host alias | high | mitigate | Require nonzero selected tests and exact self-check output; missing host state remains nonzero. Audit: mitigation verified at ASVS L1. | closed |
| 29 | T-164-112 | Denial of Service | protected/full suites | high | mitigate | Default-exclude the host tag and mechanically expand every alias/job entry point. Audit: mitigation verified at ASVS L1. | closed |
| 29 | T-164-113 | Tampering | disposable attack coverage | medium | mitigate | Keep all five hostile fixtures active under repository-only selection with marker assertions. Audit: mitigation verified at ASVS L1. | closed |
| 29 | T-164-SC | Tampering | package supply chain | low | accept | No package install or dependency change occurs; existing Node is discovered only for disposable tests. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 30 | T-164-114 | Denial of Service | authority subject discovery | medium | mitigate | Replace raising streams with ordered result-returning lstat/read operations. Audit: mitigation verified at ASVS L1. | closed |
| 30 | T-164-115 | Information Disclosure | CLI diagnostic | medium | mitigate | Emit stable tagged relative subjects and no exception stack. Audit: mitigation verified at ASVS L1. | closed |
| 30 | T-164-116 | Tampering | authority fallback | high | mitigate | Never substitute canonical files for missing authority-root subjects. Audit: mitigation verified at ASVS L1. | closed |
| 30 | T-164-117 | Repudiation | subject ordering | medium | mitigate | Test deterministic first-missing behavior in declared @ignore_files order. Audit: mitigation verified at ASVS L1. | closed |
| 30 | T-164-SC | Tampering | package supply chain | low | accept | No package-manager or dependency operation occurs. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 31 | T-164-118 | Tampering | terminal history range | high | mitigate | Pin exact 01-34 constants in loader/shell and regress missing/extra members. Audit: mitigation verified at ASVS L1. | closed |
| 31 | T-164-119 | Repudiation | installed readiness record | high | mitigate | Mark Plan 164-27 proof prior and require Plans 32/33 for changed bytes. Audit: mitigation verified at ASVS L1. | closed |
| 31 | T-164-120 | Spoofing | glob-derived completeness | high | mitigate | Retain explicit numeric expected-set comparison at one captured OID. Audit: mitigation verified at ASVS L1. | closed |
| 31 | T-164-SC | Tampering | package supply chain | low | accept | No package install or dependency change occurs. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 32 | T-164-121 | Tampering | proposal source | high | mitigate | Extract by full commit OID and bind SHA-256/tool identities. Audit: mitigation verified at ASVS L1. | closed |
| 32 | T-164-122 | Elevation of Privilege | approval scope | high | mitigate | Blocking human approval over a complete persisted tuple. Audit: mitigation verified at ASVS L1. | closed |
| 32 | T-164-123 | Spoofing | prior object | high | mitigate | Require exact Plan 164-27 approval digest plus installed lstat/digest/mode/stat identity. Audit: mitigation verified at ASVS L1. | closed |
| 32 | T-164-124 | Repudiation | approval parity | high | mitigate | Approval is byte-for-byte proposal plus one exact status line. Audit: mitigation verified at ASVS L1. | closed |
| 32 | T-164-SC | Tampering | external source movement | high | mitigate | Source is an authenticated project Git blob; no package-manager install occurs. Audit: mitigation verified at ASVS L1. | closed |
| 33 | T-164-125 | Tampering | installed replacement | high | mitigate | Revalidate exact approval and install only authenticated commit bytes atomically. Audit: mitigation verified at ASVS L1. | closed |
| 33 | T-164-126 | Repudiation | rollback provenance | high | mitigate | Publish verified digest-addressed mode-0400 prior bytes before replacement. Audit: mitigation verified at ASVS L1. | closed |
| 33 | T-164-127 | Spoofing | active installed proof | high | mitigate | Directly read real approval/install and assert digest, OID ancestry, version, and self-check. Audit: mitigation verified at ASVS L1. | closed |
| 33 | T-164-128 | Elevation of Privilege | terminal execution | high | mitigate | Permit only inspection modes during installation readiness. Audit: mitigation verified at ASVS L1. | closed |
| 33 | T-164-SC | Tampering | external source movement | high | mitigate | Approved source is one authenticated repository blob; no package manager participates. Audit: mitigation verified at ASVS L1. | closed |
| 34 | T-164-129 | Repudiation | validation/security records | high | mitigate | Bind claims to named active tests, exact commands, observed counts, and failure direction. Audit: mitigation verified at ASVS L1. | closed |
| 34 | T-164-130 | Tampering | canonical ledger map | high | mitigate | Add exact-one rows and final-content SHA-256 relationships with stale-hash negatives. Audit: mitigation verified at ASVS L1. | closed |
| 34 | T-164-131 | Spoofing | terminal readiness | high | mitigate | Preserve verifier/metadata/protected-main/remote-evidence ordering and T-164-109 pending. Audit: mitigation verified at ASVS L1. | closed |
| 34 | T-164-132 | Information Disclosure | validator errors | medium | mitigate | Retain stable relative tagged diagnostics without stack traces. Audit: mitigation verified at ASVS L1. | closed |
| 34 | T-164-SC | Tampering | package supply chain | low | accept | No package install or dependency change occurs. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 35 | T-164-133 | Spoofing | BEAM runtime closure | high | mitigate | Authenticate physical Mix, Elixir, and Erlang identities and execute version probes in the exact child environment. Audit: mitigation verified at ASVS L1. | closed |
| 35 | T-164-134 | Tampering | child environment | high | mitigate | Construct PATH only from authenticated tool directories and remove inherited ASDF selectors. Audit: mitigation verified at ASVS L1. | closed |
| 35 | T-164-135 | Tampering | Node-to-Bash authority handoff | high | mitigate | Pass the authenticated full OID as required data through both shell layers. Audit: mitigation verified at ASVS L1. | closed |
| 35 | T-164-136 | Elevation of Privilege | closeout command resolution | high | mitigate | Route trust-sensitive calls through required MAILGLASS_* identities. Audit: mitigation verified at ASVS L1. | closed |
| 35 | T-164-137 | Repudiation | race regression evidence | high | mitigate | Advance a fixture repository after loader capture and prove bounded failure before evidence markers. Audit: mitigation verified at ASVS L1. | closed |
| 35 | T-164-SC | Tampering | package supply chain | low | accept | No package installation or dependency change occurs. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 36 | T-164-138 | Spoofing | protected-main identity | high | mitigate | Require canonical branch plus exact HEAD/fetched-origin equality and stable porcelain. Audit: mitigation verified at ASVS L1. | closed |
| 36 | T-164-139 | Repudiation | CI provenance | high | mitigate | Independently validate workflow, event, attempt, branch, SHA, status, conclusion, and numeric run ID. Audit: mitigation verified at ASVS L1. | closed |
| 36 | T-164-140 | Elevation of Privilege | integration controls | high | mitigate | Use a blocking human-action checkpoint and the normal protected workflow without bypass or direct push. Audit: mitigation verified at ASVS L1. | closed |
| 36 | T-164-SC | Tampering | package supply chain | low | accept | No package installation or dependency change occurs. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 37 | T-164-141 | Spoofing | proposal source/CI tuple | high | mitigate | Bind full source OID/digest and independently validated attempt-one normal CI run. Audit: mitigation verified at ASVS L1. | closed |
| 37 | T-164-142 | Tampering | runtime tool tuple | high | mitigate | Bind physical path identities, normalized version outputs, and exact-child probe digest. Audit: mitigation verified at ASVS L1. | closed |
| 37 | T-164-143 | Repudiation | human approval | high | mitigate | Display ordered fields and accept one exact response for exact-copy-plus-status publication. Audit: mitigation verified at ASVS L1. | closed |
| 37 | T-164-144 | Elevation of Privilege | approval scope | high | mitigate | Separate approval from installation and exclude finalization/workflow authority. Audit: mitigation verified at ASVS L1. | closed |
| 37 | T-164-145 | Tampering | proposal/approval files | high | mitigate | Atomically publish regular non-symlink mode-0400 records and read back exact bytes. Audit: mitigation verified at ASVS L1. | closed |
| 37 | T-164-SC | Tampering | package supply chain | low | accept | No package installation or dependency change occurs. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 38 | T-164-146 | Tampering | installed replacement | high | mitigate | Revalidate exact approval and atomically install only authenticated commit bytes. Audit: mitigation verified at ASVS L1. | closed |
| 38 | T-164-147 | Repudiation | rollback provenance | high | mitigate | Publish and verify digest-addressed mode-0400 predecessor bytes before mutation. Audit: mitigation verified at ASVS L1. | closed |
| 38 | T-164-148 | Spoofing | active installed proof | high | mitigate | Directly verify real approval, installed digest/mode/OID ancestry, range, and exact-child runtime output. Audit: mitigation verified at ASVS L1. | closed |
| 38 | T-164-149 | Elevation of Privilege | terminal execution | high | mitigate | Invoke inspection modes only and preserve later lifecycle gates. Audit: mitigation verified at ASVS L1. | closed |
| 38 | T-164-SC | Tampering | package supply chain | low | accept | No package installation or dependency change occurs. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 39 | T-164-150 | Repudiation | validation/security records | high | mitigate | Bind claims to named lanes, observed counts, exact identities, stable diagnostics, and failure direction. Audit: mitigation verified at ASVS L1. | closed |
| 39 | T-164-151 | Tampering | disposition ledger | high | mitigate | Enforce exact-one 12-field rows, exact disposition, complete candidate set, and canonical relationships. Audit: mitigation verified at ASVS L1. | closed |
| 39 | T-164-152 | Spoofing | equal/adjacent subjects | high | mitigate | Compare exact normalized identities and reject duplicates, prefix collisions, and ordering-based selection. Audit: mitigation verified at ASVS L1. | closed |
| 39 | T-164-153 | Information Disclosure | validator errors | medium | mitigate | Emit bounded relative tagged diagnostics without stack traces. Audit: mitigation verified at ASVS L1. | closed |
| 39 | T-164-154 | Elevation of Privilege | terminal lifecycle | high | mitigate | Keep T-164-109 pending and place terminal execution only after the non-circular post-execution gate. Audit: mitigation verified at ASVS L1. | closed |
| 39 | T-164-SC | Tampering | package supply chain | low | accept | No package installation or dependency change occurs. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 40 | T-164-155 | Tampering | tracked subject worktree entry | high | mitigate | Require lstat type `:regular` before any index or content claim. Audit: mitigation verified at ASVS L1. | closed |
| 40 | T-164-156 | Spoofing | stage-0 Git index record | high | mitigate | Accept only exact-one byte-identical stage-0 mode 100644/100755 records. Audit: mitigation verified at ASVS L1. | closed |
| 40 | T-164-157 | Information Disclosure | public CLI diagnostic | medium | mitigate | Return subject-relative tagged errors with bounded output and no stack trace. Audit: mitigation verified at ASVS L1. | closed |
| 40 | T-164-158 | Denial of Service | malformed staged output | medium | mitigate | Retain finite NUL framing and syntax parsing with deterministic non-success. Audit: mitigation verified at ASVS L1. | closed |
| 40 | T-164-SC | Tampering | package supply chain | low | accept | No package installation or dependency change occurs. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 41 | T-164-158 | Tampering | `plan_files_modified/1` | high | mitigate | Structurally parse the opening frontmatter and reject missing/malformed metadata with stable tags. Audit: mitigation verified at ASVS L1. | closed |
| 41 | T-164-159 | Denial of Service | Git subprocess handling | medium | mitigate | Validate Git identity early and replace MatchError paths with bounded tagged errors. Audit: mitigation verified at ASVS L1. | closed |
| 41 | T-164-160 | Information Disclosure | standalone CLI | low | mitigate | Emit relative bounded diagnostics without exception/stack output. Audit: mitigation verified at ASVS L1. | closed |
| 41 | T-164-SC | Tampering | package supply chain | high | accept | No npm, pip, or cargo package install occurs in this plan. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 42 | T-164-161 | Tampering | repository-only attack fixtures | high | mitigate | Use fully disposable canonical repositories and exact mutation-specific assertions. Audit: mitigation verified at ASVS L1. | closed |
| 42 | T-164-162 | Elevation of Privilege | live pre-verification dispatch | high | mitigate | Rewrite canonical paths to fixture-owned scripts and assert no production marker/path. Audit: mitigation verified at ASVS L1. | closed |
| 42 | T-164-163 | Spoofing | origin/main fixture state | medium | mitigate | Set and assert exact remote ref state before each loader invocation. Audit: mitigation verified at ASVS L1. | closed |
| 42 | T-164-SC | Tampering | package supply chain | high | accept | No npm, pip, or cargo package install occurs in this plan. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 43 | T-164-164 | Spoofing | current finalization authority | high | mitigate | Bind current prose and tests to Plans 164-37/164-38. Audit: mitigation verified at ASVS L1. | closed |
| 43 | T-164-165 | Repudiation | Plan 164-23 history | medium | mitigate | Preserve it in a separately extracted historical region with supersession semantics. Audit: mitigation verified at ASVS L1. | closed |
| 43 | T-164-SC | Tampering | package supply chain | high | accept | No npm, pip, or cargo package install occurs in this plan. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |
| 44 | T-164-166 | Repudiation | SECURITY/VALIDATION provenance | high | mitigate | Record exact commands, actual counts, and commit only after fresh zero-exit evidence. Audit: mitigation verified at ASVS L1. | closed |
| 44 | T-164-167 | Tampering | truth-disposition ledger | high | mitigate | Enforce exact-one completed-plan subjects, vocabulary, and canonical relationship hashes. Audit: mitigation verified at ASVS L1. | closed |
| 44 | T-164-168 | Spoofing | ordinary versus terminal proof | high | mitigate | Keep T-164-109 open and explicitly label evidence as non-terminal. Audit: mitigation verified at ASVS L1. | closed |
| 44 | T-164-SC | Tampering | package supply chain | high | accept | No npm, pip, or cargo package install occurs in this plan. Audit: accepted under the plan-qualified accepted-risks entry below. | accepted |

## Security Audit — 2026-09-12

The ASVS L1 auditor reconstructed the complete plan-time register from 42
parseable `<threat_model>` blocks: 198 authored rows and 158 unique threat IDs.
After recording the already-authored T-164-94 acceptance, 197 rows are
resolved or accepted and one high-severity row remains open.

### Register Reconciliation

| Prior integrity issue | Resolution in this record |
|-----------------------|---------------------------|
| 52 authored IDs were absent | All 198 authored rows are now present. |
| T-164-105 through T-164-108 had later meanings | Plan 164-28's authored definitions are restored under plan-qualified keys. |
| T-164-158 had two definitions | Plan 40 and Plan 41 are retained as separate rows with their authored severities. |
| T-164-SC represented 40 rows and 23 definitions | Every occurrence is separately keyed by plan; 36 accepted and four mitigated dispositions remain distinct. |
| T-164-40 through T-164-44 were referenced without authored rows | They remain historical VALIDATION aliases, are not treated as authored threats, and are excluded from the 198-row register. |

### Open Threats

| Threat ID | Severity | Blocking | Evidence | Required action |
|-----------|----------|----------|----------|-----------------|
| T-164-109 | high | yes | `164-VERIFICATION.md` remains `gaps_found`; HEAD `20447b0118c4953f277c81537487ad698814fa95` is 49 commits ahead of protected main `52c07a5051d269b307831a2210f53dec0dd1ff65`; `.planning/state.json` is dirty; terminal inputs are absent; retained reports target older SHAs; and the installed finalizer authenticates only Plans 01-39 while the phase contains Plans 01-44. | Reconcile the terminal range and installed approval, rerun ordinary verification, reach clean protected exact main, obtain exact attempt-one CI and natural schedules, recheck installed approval, capture the ignored terminal report, and make no later tracked write. |

The current controlled-host installed-boundary run selected seven tests: six
passed and one correctly failed closed with `repository is not clean`. This
confirms the mitigation behavior but is not current terminal-readiness evidence.

No unregistered SUMMARY threat flags were found. Summary flags map to authored
threats, including the explicit retention of T-164-109 in
`164-35-SUMMARY.md`.

## Superseding Gap-Reconciliation Assessment

The 2026-09-10 verifier and review correctly contradicted the earlier blanket
`secured` claim. Plans 164-25 through 164-33 repaired the required-CI host
coupling, caller-selected repository authority, forged tools, unrelated
installation ancestry, fixture-only installed proof, raising authority-root
discovery, stale exact-history range, and superseded installed bytes. Closure
is bound to the named production seams above, not the earlier audit prose.

The superseding evidence retains the exact control vocabulary used by the
contract suite: required-CI host coupling, caller-selected repository authority,
forged PATH/tools, unrelated installation OID, and terminal no-later-write evidence.
The named executable seams are `phase_164_incomplete_authority_root` and
`phase_164_installed_production_boundary`; their negative paths preserve a stable
failure direction. Protected evidence includes attempt-one push CI run
`34650810638`, approval digest
`e3687bf5a2afc69a79b2677c69daa3d533549d4b6f730a30a04e32cc6d13b7cd`, installed
digest `394a47effebe04d7aaa4e098775bedd194b6f00ce6efa63eea078aa79bb9f746`, and
runtime-probe digest
`ca3c43bd04c4e21e223f39561f294885ceca2633db65a72fa29b780bcef3975d`.

| Preserved contract label | Current interpretation |
|--------------------------|------------------------|
| repository-only CI | Fresh ordinary evidence; never terminal authority. |
| controlled-host installation readiness | Read-only installed-boundary evidence; never terminal authority. |
| physical Mix/Elixir/Erlang exact-child probe | Verified runtime-identity closure. |
| immutable OID handoff | Verified Node-to-Bash authority binding. |
| Plan 164-37 approval | Human approval for the recorded proposal tuple. |
| Plan 164-38 installed authority | Active installed and rollback provenance. |

Repository-only CI and controlled-host installation readiness are deliberately
separate authorities. The former reran 398 selected tests with 7 host tests
excluded and 0 failures. The latter reran 7 selected tests with 54 excluded and
0 failures against the active Plan 164-32 source OID
`1cfee7802de808f690fe5413b22a57e7ab802488` and SHA-256
`f01859c551e6611d3bdd4dbae427cba3bc3d63e18fad7d74bbeeacf9953fffac`.
Plan 164-27 prior provenance remains immutable at OID
`2c7cf25c4ac004df3f960a5e8cb37cf8aef68c97` and digest
`0dbcc03466f4da863c63d46ac2f314b4a260e45388e8f770c608d0eb02d8676e`.

T-164-109 remains open and high. Ordinary verification must evaluate the
complete tracked implementation only after `164-39-SUMMARY.md` exists. Only
protected completion metadata may follow before all tracked state reaches
protected `main`; exact attempt-1 normal push CI and naturally scheduled
attempt-1 evidence must then authorize the installed read-only capture. Until
that sequence completes, terminal protected-main evidence remains absent and
pending. No repository test, controlled-host installation result, manual
dispatch, or this reconciliation substitutes for it, and no terminal run or
phase/requirement completion occurred here.

Plans 164-35 through 164-38 close T-164-133 through T-164-149 at ASVS L1
through observed executable, protected, approval, installation, and rollback
evidence. The physical Mix/Elixir/Erlang exact-child probe and immutable OID handoff
are repository behavior; the Plan 164-37 approval and Plan 164-38
installed authority are separate external facts. Their passing lanes do not
collapse into ordinary verification or the later terminal capture.

## Final Ordinary-Verification Reconciliation — Plan 164-44

This assessment supersedes the earlier current-count claims without deleting
them: the 397/11, 398/7, and other earlier results above remain dated layered
history under D-01, while this fresh run is the current dual-proof record under
D-09. All five prerequisite commands ran after the Plan 164-44 ledger repair at
implementation commit `91b867ab2299afb8b2392176f699e16af4fc8f4a`, and every
command exited zero before this document was edited.

| Authority layer | Exact command | Fresh result |
|-----------------|---------------|--------------|
| Canonical ledger | `elixir scripts/validate_repository_truth.exs --repo /Users/jon/projects/mailglass --ledger /Users/jon/projects/mailglass/.planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv` | `repository truth ledger: valid`; exit 0 |
| Repository-truth contract | `mix test test/scripts/phase_164_repository_truth_test.exs --warnings-as-errors --no-deps-check` | 47 selected, 0 excluded, 0 failures; exit 0 |
| Repository-only CI | `mix verify.ci_lane_contract` | 414 selected, 11 excluded, 0 failures; exit 0 |
| Controlled-host installed readiness | `mix verify.phase_164.installed_boundary` | 7 selected, 57 excluded, 0 failures; exit 0 |
| Maintainer authority | `mix test test/mailglass/publish/maintaining_release_gate_contract_test.exs --warnings-as-errors --no-deps-check` | 5 selected, 0 excluded, 0 failures; exit 0 |
| Evidence-document contract | `mix test test/mailglass/docs_contract_test.exs --only phase_164_gap_reconciliation --warnings-as-errors --no-deps-check` | 5 selected, 44 excluded, 0 failures; exit 0 after evidence edits |

These results close T-164-150 through T-164-168 as implementation and ordinary
readiness mitigations. They do not close T-164-109. D-10 clean exact main and
D-11 protected checks plus naturally scheduled evidence were not produced;
the installed command was not invoked in terminal mode; no ignored terminal
capture or no-later-tracked-write proof is claimed. Terminal protected-main
evidence remains absent and pending until the mandated lifecycle completes.

## Accepted Risks Log

T-164-94 is explicitly accepted because Plan 164-25 changed Mix alias and
test-selection contracts without changing any workflow job, trigger, permission,
release, or protected-check topology. This acceptance grants no CI or release
authority.

T-164-60 is explicitly accepted because Plan 164-16 changed only current-facing
maintainer documentation and its behavioral contract; executable release-control
paths were unchanged. This low-severity acceptance records the bounded scope and
does not grant or alter release authority.

Each plan-qualified T-164-SC row with an `accept` disposition is explicitly
accepted because that plan performs no package-manager installation or
dependency change. The Plan 24, 27, 32, and 33 T-164-SC rows instead retain
their authored `mitigate` dispositions and verified provenance controls. These
acceptances do not weaken repository, executable, installation-ancestry, or
terminal lifecycle checks.

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-01 | 33 | 22 | 11 total / 10 blocking | gsd-security-auditor |
| 2026-09-01 | 33 | 32 | 1 total / 0 blocking | gsd-security-auditor (post-remediation) |
| 2026-09-09 | 37 | 36 | 1 total / 0 blocking | execute-phase ASVS L1 short-circuit refresh through Plan 164-14 |
| 2026-09-09 | 40 | 39 | 1 total / 0 blocking | execute-phase ASVS L1 short-circuit refresh through Plan 164-16 |
| 2026-09-09 | 40 | 37 | 3 total / 2 blocking | execute-phase reconciliation after code review and goal verification |
| 2026-09-09 | 42 | 41 | 1 total / 0 blocking | gsd-security-auditor (post-Plan 164-17 trust-anchor verification) |
| 2026-09-09 | 42 | 39 | 3 total / 2 blocking | execute-phase reconciliation after code review and authoritative goal verification |
| 2026-09-10 | 42 | 41 | 1 total / 0 blocking | gsd-security-auditor (post-Plans 164-18/19 gap verification) |
| 2026-09-10 | 47 | 46 resolved | 1 blocking terminal-lifecycle item | Plan 164-28 superseding reconciliation after Plans 164-25 through 164-27 |
| 2026-09-11 | 70 | 69 resolved/accepted | 1 blocking terminal-lifecycle item | Plan 164-34 reconciliation of Plans 164-29 through 164-33 and canonical Task 2 validation |
| 2026-09-11 | 70 | 69 resolved/accepted | 1 blocking terminal-lifecycle item | gsd-security-auditor post-gap-closure verification |
| 2026-09-11 | 70 | 69 resolved/accepted | 1 blocking terminal-lifecycle item | verify-work refresh; T-164-109 evidence chain remains incomplete |
| 2026-09-12 | 106 | 105 resolved/accepted | 1 blocking terminal-lifecycle item | Plan 164-44 fresh ordinary reconciliation at implementation commit `91b867ab2299afb8b2392176f699e16af4fc8f4a` |
| 2026-09-12 | 106 | 105 resolved/accepted | 1 blocking terminal-lifecycle item | gsd-security-auditor re-audit — T-164-109 remains open: ordinary verification is `gaps_found`; Phase 164 is incomplete and 47 commits ahead of protected main; exact completion-SHA CI/natural schedules, terminal installed-authority recheck, terminal inputs/report, and no-later-tracked-write proof are absent |
| 2026-09-12 | 158 unique authored IDs | 156 provisionally closed | 2 total / 1 blocking | gsd-security-auditor escalation — consolidated register is incomplete and contains identity collisions; T-164-109 remains blocking and T-164-94 remains undocumented below threshold |
| 2026-09-12 | 198 authored rows | 197 resolved/accepted | 1 blocking | gsd-security-auditor (plan-qualified ASVS L1 reconciliation) |

## Sign-Off

- [x] Complete 198-row authored register retained under plan-qualified keys.
- [x] All available plan-time mitigations verified at ASVS L1.
- [x] T-164-94's authored low-severity acceptance is documented.
- [x] `threats_open: 1` records the sole remaining high-severity blocker.
- [x] `status: pending_terminal` prevents an early secured or completed claim.
- [ ] T-164-109 terminal protected-main evidence completed.

**Approval:** withheld. Phase 164 is not security-final. T-164-109 remains open
until the authenticated range includes Plans 01-44, ordinary verification
passes, completion metadata reaches protected exact main, exact attempt-one CI
and natural schedules are available, and the ignored no-later-write terminal
capture completes in order.
