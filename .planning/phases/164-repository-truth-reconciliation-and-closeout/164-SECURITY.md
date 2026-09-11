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

| Threat ID | Category | Component | Severity | Disposition | Mitigation / Evidence | Status |
|-----------|----------|-----------|----------|-------------|-----------------------|--------|
| T-164-01 | Tampering | stale sweep removal | high | mitigate | Locked digest and singular removal contract | closed |
| T-164-02 | Repudiation | disposition ledger schema | high | mitigate | Required fields, enum, and duplicate checks | closed |
| T-164-03 | Tampering | ignore-rule preservation | high | mitigate | Six-file ignore inventory plus canonical stable-ID/profile bindings reject added, swapped, or proof-hiding relationships | closed |
| T-164-04 | Elevation of Privilege | protected release authority | high | mitigate | Exact candidate/digest and repository-admin contract | closed |
| T-164-05 | Spoofing | CI evidence | high | mitigate | Exact CI identity and malformed-data failure | closed |
| T-164-06 | Repudiation | historical guidance | medium | mitigate | Explicit historical applicability contract | closed |
| T-164-07 | Spoofing | package compatibility | medium | mitigate | Manifest-derived compatibility tests | closed |
| T-164-08 | Tampering | historical documentation | medium | mitigate | Current and historical sections tested separately | closed |
| T-164-09 | Tampering | ledger subject inventory | high | mitigate | Bidirectional exact set equality rejects missing and fabricated subjects | closed |
| T-164-10 | Repudiation | ledger completeness | high | mitigate | Nonblank fields and exact enums | closed |
| T-164-11 | Information Disclosure | ignore scope | medium | mitigate | Six ignore files derived and narrow visibility tested | closed |
| T-164-12 | Spoofing | closeout Git/CI identity | high | mitigate | Branch, SHA, run, and CI head checks | closed |
| T-164-13 | Tampering | scheduled evidence predicate | high | mitigate | Exact registered-control set plus complete workflow/run/reason/payload/archive bindings are enforced and mutation-tested | closed |
| T-164-14 | Repudiation | aggregate verdict precedence | high | mitigate | A production-script fixture substitutes only the canonical checkout constant, then executes cannot-check, pending, policy-blocked/pass, and all-pass outcomes while preserving component sources | closed |
| T-164-15 | Elevation of Privilege | evidence command authority | high | mitigate | No dispatch, rerun, merge, or publish surface | closed |
| T-164-16 | Spoofing | CI run selection | high | mitigate | Attempt-one exact-SHA CI selection and raw re-query | closed |
| T-164-17 | Elevation of Privilege | finalizer authority | high | mitigate | Phase-164-only lexical regular-file authentication precedes realpath resolution; the complete transitive dependency manifest is authenticated from HEAD, materialized under one private authority root, and removed in `finally` on every exit path | closed |
| T-164-18 | Spoofing | protected-main freshness | high | mitigate | Final decision re-fetches origin/main, reasserts identities, and preserves a blocked report if main advances | closed |
| T-164-19 | Tampering | persisted component evidence | high | mitigate | Canonicalized CI/scheduled sources are independently revalidated and incomplete evidence is rejected | closed |
| T-164-20 | Repudiation | report provenance | high | mitigate | Persist timestamp, repository/SHA/run, sources, statuses, reasons | closed |
| T-164-21 | Elevation of Privilege | closeout operations | high | mitigate | No dispatch, rerun, merge, tag, or publish | closed |
| T-164-22 | Tampering | ledger enums | high | mitigate | Exact currentness/disposition and stale-outcome rules | closed |
| T-164-23 | Repudiation | required subjects | high | mitigate | Derive required subjects from Git, plans, proof, verification, ignores | closed |
| T-164-24 | Tampering | duplicate subjects | medium | mitigate | Ordering-independent duplicate rejection | closed |
| T-164-25 | Spoofing | repository authority | high | mitigate | Canonical checkout, normalized origin, GitHub owner/repository, `GH_HOST`, and `GH_REPO` are pinned | closed |
| T-164-26 | Tampering | ledger semantic authority | high | mitigate | Literal `ls-files --stage -z` parsing accepts exactly one byte-exact stage-0 record and rejects missing, duplicate, malformed, mismatched, or stage-1/2/3 records; genuine unmerged-index regressions pass | closed |
| T-164-27 | Repudiation | local capture paths | high | mitigate | Private random capture directories, private component directories, temporary leaves, and atomic renames are symlink-safe | closed |
| T-164-28 | Elevation of Privilege | remote behavior | high | mitigate | Read-only remote behavior | closed |
| T-164-36 | Tampering | freshness authority | high | mitigate | Registry-specific age decision remains in scheduled sweep | closed |
| T-164-37 | Spoofing | scheduled provenance | high | mitigate | SHA, attempt, event, branch, status, workflow-SHA mutation tests | closed |
| T-164-38 | Repudiation | sweep completeness | high | mitigate | Successful top-level sweep and exact complete control envelope are required and adversarially tested | closed |
| T-164-39 | Elevation of Privilege | scheduled controls | medium | mitigate | No workflow/rerun/authorization/release surface | closed |
| T-164-49 | Spoofing | protected-main and CI identity | high | mitigate | Exact canonical checkout, branch, HEAD/origin SHA equality, and finalizer-selected attempt-one normal push CI were independently verified in Plan 164-14 | closed |
| T-164-50 | Tampering | scheduled evidence set/provenance | high | mitigate | Exact registry equality plus per-control attempt, event, workflow, SHA, status, reason, freshness, payload digest, and archive digest checks passed in Plan 164-14 | closed |
| T-164-51 | Repudiation | pre-verification versus terminal boundary | high | mitigate | `164-FINALIZATION.md` and `164-14-SUMMARY.md` explicitly classify the accepted capture as pre-verification-only and require terminal recapture after tracked completion metadata | closed |
| T-164-52 | Elevation of Privilege | remote workflow/release controls | high | mitigate | Plan 164-14 completed through read-only queries and transient credential injection with no dispatch, rerun, push, merge, authority change, or publication operation | closed |
| T-164-58 | Elevation of Privilege | non-historical maintainer release guidance | high | mitigate | The whole pre-historical `MAINTAINING.md` region requires protected exact-candidate dispatch plus fresh repository-admin authorization and rejects automatic, reviewer-free, and approval-free variants | closed |
| T-164-59 | Repudiation | historical v0.1/v0.5 authority provenance | medium | mitigate | The exact, singular `## Historical release procedures` boundary is enforced and the legacy rationale appears only beneath it with explicit historical applicability | closed |
| T-164-60 | Tampering | executable protected-release controls | low | accept | Plan 164-16 changed only documentation and its contract; executable release-control paths remained unchanged | closed |
| T-164-63 | Tampering | downstream finalizer and temporary materialization | high | mitigate | The downstream HEAD blob is materialized in a mode-0700 private directory as a mode-0500 file, executed by private path, and removed in `finally` on success and failure | closed |
| T-164-64 | Repudiation | standalone validator invocation | medium | mitigate | Missing and invalid CLI arguments emit bounded diagnostics and exit nonzero; canonical invocation and module loading are covered by subprocess regressions | closed |
| T-164-105 | Repudiation | required-CI host coupling | high | mitigate | `phase_164_ci_hermeticity` plus `mix verify.ci_lane_contract` observed 380 selected, 5 controlled-host exclusions, and 0 failures after Plan 164-25 | closed |
| T-164-106 | Spoofing | caller-selected repository authority | high | mitigate | `phase_164_canonical_loader` observed 1 selected, 48 excluded, and 0 failures; the installed matrix rejects foreign repositories before dispatch | closed |
| T-164-107 | Elevation of Privilege | forged PATH/tools | high | mitigate | `phase_164_trusted_toolchain` observed 3 selected, 46 excluded, and 0 failures; forged Git/Bash/gh/jq/Mix/Node/Elixir markers never execute | closed |
| T-164-108 | Spoofing | unrelated installation OID | high | mitigate | `phase_164_reinstall_contract` observed 3 selected, 46 excluded, and 0 failures, while `phase_164_installed_production_boundary` observed 5 selected, 44 excluded, and 0 failures against the approved source OID and digest | closed |
| T-164-109 | Repudiation | terminal no-later-write evidence | high | mitigate | Requires the Plan 164-28 summary, passed ordinary verification, protected completion metadata, exact-main attempt-1 push CI, natural schedules, and then the ignored terminal report with no later tracked write | open — lifecycle evidence pending |
| T-164-SC | Tampering | package supply chain | low | accept | No package-manager install or dependency change occurred; Plan 164-27 installed only human-approved project-authored Git blob `2c7cf25c4ac004df3f960a5e8cb37cf8aef68c97` with SHA-256 `0dbcc03466f4da863c63d46ac2f314b4a260e45388e8f770c608d0eb02d8676e` and retained the superseded `ca760f78ab0901dbc537e20ec6c231314afffa7932dd8f1850f4935cabc8b7d9` bytes | accepted |

## Superseding Gap-Reconciliation Assessment

The 2026-09-10 verifier and review correctly contradicted the earlier blanket
`secured` claim: required-CI host coupling, caller-selected repository
authority, forged PATH/tools, and an unrelated installation OID were not yet
closed at that audit point. Plans 164-25 through 164-27 subsequently repaired
those seams. T-164-105 through T-164-108 are closed only by the named observed
regressions above, not by the earlier audit prose. The current installed source
OID is `2c7cf25c4ac004df3f960a5e8cb37cf8aef68c97`; source and installed bytes
share SHA-256
`0dbcc03466f4da863c63d46ac2f314b4a260e45388e8f770c608d0eb02d8676e`.

T-164-109 remains open. Ordinary verification must evaluate the complete
tracked implementation after the Plan 164-28 summary exists. Only protected
completion metadata may follow before all tracked state reaches protected
`main`; exact attempt-1 normal push CI and natural schedules must then authorize
the installed read-only capture. Until that sequence completes, terminal
protected-main evidence remains absent and pending. No code test,
controlled-host installation result, or manual dispatch substitutes for it.

## Accepted Risks Log

T-164-SC is explicitly accepted because this phase performs no package-manager
installation or dependency change. The installed artifact is a
human-approved, project-authored Git blob with exact OID and digest evidence;
this acceptance does not weaken repository, executable, installation-ancestry,
or terminal lifecycle checks.

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

## Sign-Off

- [x] All registered threats were inspected at ASVS L1.
- [ ] T-164-109 remains open until terminal protected-main evidence is captured in the mandated lifecycle order.
- [x] T-164-SC is explicitly accepted without any package-manager install or dependency change.
- [x] `threats_open: 1` reflects the pending high-severity terminal lifecycle item.
- [x] `status: pending_terminal` prevents an early secured or completed claim.

**Approval:** implementation mitigations are reconciled at ASVS L1 through Plan 164-28 Task 1, but Phase 164 is not yet security-final. T-164-109 remains open until the ordinary verifier, protected completion metadata, exact-main CI/natural schedules, and ignored no-later-write terminal capture complete in order.
