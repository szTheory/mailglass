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
| T-164-105 | Repudiation | required-CI host coupling | high | mitigate | The final `mix verify.ci_lane_contract` rerun observed 398 selected, 7 controlled-host exclusions, and 0 failures | closed |
| T-164-106 | Spoofing | caller-selected repository authority | high | mitigate | `phase_164_canonical_loader` observed 1 selected, 48 excluded, and 0 failures; the installed matrix rejects foreign repositories before dispatch | closed |
| T-164-107 | Elevation of Privilege | forged PATH/tools | high | mitigate | `phase_164_trusted_toolchain` observed 3 selected, 46 excluded, and 0 failures; forged Git/Bash/gh/jq/Mix/Node/Elixir markers never execute | closed |
| T-164-108 | Spoofing | unrelated installation OID | high | mitigate | Installation ancestry and the real installed tuple proof reject byte-identical loaders from unrelated history; the active controlled-host group observed 7 selected, 54 excluded, and 0 failures | closed |
| T-164-109 | Repudiation | terminal no-later-write evidence | high | mitigate | Requires the Plan 164-39 summary, passed ordinary verification, protected completion metadata, protected main, exact-main attempt-1 push CI, natural schedules, installed approval recheck, and then the ignored terminal report with no later tracked write | open — lifecycle evidence pending |
| T-164-110 | Spoofing | installed authority proof | high | mitigate | Direct `phase_164_installed_production_boundary` proof authenticates exact approval schema, path/type/mode, digest, committed blob, ancestry, and self-check | closed |
| T-164-111 | Repudiation | controlled-host alias | high | mitigate | `mix verify.phase_164.installed_boundary` selected 7 tests, excluded 54, and returned 0 failures; absent or mismatched host authority fails nonzero | closed |
| T-164-112 | Denial of Service | protected/full suites | high | mitigate | Root ExUnit exclusion plus recursive alias/workflow checks keep controlled-host installation readiness out of repository-only CI; `mix verify.ci_lane_contract` selected 396 and excluded exactly 7 | closed |
| T-164-113 | Tampering | disposable attack coverage | medium | mitigate | Five foreign-repository/source-loader attacks remain active in repository-only CI and retain marker/failure assertions | closed |
| T-164-114 | Denial of Service | authority subject discovery | medium | mitigate | Ordered result-returning lstat/read operations replace raising streams; `phase_164_incomplete_authority_root` selected 3 tests with 25 excluded and 0 failures | closed |
| T-164-115 | Information Disclosure | CLI diagnostic | medium | mitigate | Empty/incomplete roots emit bounded stable relative `repository_truth: missing_ignore_subject` diagnostics without exception stacks | closed |
| T-164-116 | Tampering | authority fallback | high | mitigate | Missing authority-root subjects return tagged failure and never substitute canonical repository files | closed |
| T-164-117 | Repudiation | subject ordering | medium | mitigate | Declared `@ignore_files` order determines the stable first-missing subject under every partial-prefix fixture | closed |
| T-164-118 | Tampering | terminal history range | high | mitigate | Loader/shell constants and hostile histories pin exactly one PLAN/SUMMARY pair for 01-39 | closed |
| T-164-119 | Repudiation | installed readiness record | high | mitigate | Plan 164-27 remains prior provenance; changed bytes required the distinct Plans 164-32/33 approval and reinstall | closed |
| T-164-120 | Spoofing | glob-derived completeness | high | mitigate | Explicit numeric expected-set comparison rejects missing, extra, or malformed history members | closed |
| T-164-121 | Tampering | proposal source | high | mitigate | Plan 164-32 extracted one committed blob by full OID and bound its SHA-256 and trusted tool identities | closed |
| T-164-122 | Elevation of Privilege | approval scope | high | mitigate | Blocking human approval covered the complete persisted replacement tuple and granted no terminal authority | closed |
| T-164-123 | Spoofing | prior object | high | mitigate | Proposal and install revalidated exact Plan 164-27 approval, installed digest/mode/lstat, and rollback absence | closed |
| T-164-124 | Repudiation | approval parity | high | mitigate | Approval is byte-for-byte proposal parity plus exactly one approval-status line | closed |
| T-164-125 | Tampering | installed replacement | high | mitigate | Plan 164-33 installed only the approved authenticated commit bytes by private materialization and atomic rename | closed |
| T-164-126 | Repudiation | rollback provenance | high | mitigate | Exact prior bytes were published and verified as the digest-addressed regular non-symlink mode-0400 rollback before replacement | closed |
| T-164-127 | Spoofing | superseded installed proof | high | mitigate | The then-active Plan 164-32 tuple was proven exactly and is now bounded prior provenance; current active authority is governed by T-164-141 through T-164-149 | closed — superseded provenance retained |
| T-164-128 | Elevation of Privilege | terminal execution | high | mitigate | Installation readiness permitted only direct `--version` and `--self-check`; no phase argument or finalization mode ran | closed |
| T-164-129 | Repudiation | validation/security records | high | mitigate | Plan 164-34 binds claims to named active tags, exact commands, observed selected/excluded counts, exit status, and failure direction | closed |
| T-164-130 | Tampering | canonical ledger map | high | mitigate | Exact-one completed-plan subjects and final canonical relationship digests are enforced with missing, duplicate, and stale-hash negatives; the full repository-truth suite passed 30 tests | closed |
| T-164-131 | Spoofing | terminal readiness | high | mitigate | Records preserve ordinary verifier → completion-only metadata → protected main → exact attempt-one CI/natural schedules → ignored capture → no later tracked write | closed |
| T-164-132 | Information Disclosure | validator errors | medium | mitigate | The active incomplete-authority CLI regression retains stable relative tagged diagnostics without stack traces | closed |
| T-164-133 | Spoofing | BEAM runtime closure | high | mitigate | The physical Mix/Elixir/Erlang exact-child probe authenticates each regular executable and binds normalized Mix, Elixir, OTP, and probe-digest output in the sanitized child environment | closed — Plan 164-35 authority lane passed 4 selected, 60 excluded |
| T-164-134 | Tampering | child environment | high | mitigate | Child PATH contains only authenticated tool directories and inherited ASDF selectors are absent | closed — hostile selector and shim fixtures fail before dispatch |
| T-164-135 | Tampering | Node-to-Bash authority handoff | high | mitigate | The immutable OID handoff is required positionally and by named flag across both Bash boundaries | closed — missing, malformed, nonexistent, and substituted OIDs fail |
| T-164-136 | Elevation of Privilege | closeout command resolution | high | mitigate | Trust-sensitive subprocesses resolve only through authenticated `MAILGLASS_*` identities in the allowlisted environment | closed — forged path/tool markers remain absent |
| T-164-137 | Repudiation | race regression evidence | high | mitigate | The OID-handoff movement regression advances fixture HEAD after loader authentication and requires bounded failure before evidence markers | closed — `phase_164_oid_handoff` is active in the non-vacuous authority lane |
| T-164-138 | Spoofing | protected-main identity | high | mitigate | Protected PR #249 integrated the exact repair; canonical branch, local HEAD, fetched origin/main, and two stable porcelain reads agreed on `52c07a5051d269b307831a2210f53dec0dd1ff65` | closed — Plan 164-36 protected observation |
| T-164-139 | Repudiation | CI provenance | high | mitigate | CI run `34650810638` independently matched workflow, push event, attempt one, main branch, exact SHA, completed status, success conclusion, and numeric ID | closed — no run-order substitution |
| T-164-140 | Elevation of Privilege | integration controls | high | mitigate | Normal protected squash merge ran only after required checks; no direct main push, protection bypass, workflow dispatch, or rerun occurred | closed — Plan 164-36 protected workflow |
| T-164-141 | Spoofing | proposal source/CI tuple | high | mitigate | Plan 164-37 approval binds the exact protected OID, loader digest, and CI run to one ordered proposal | closed — proposal boundary passed 4 selected, 60 excluded |
| T-164-142 | Tampering | runtime tool tuple | high | mitigate | Approval binds all physical tool identities, normalized version outputs, OTP release, and exact-child probe SHA-256 | closed — all 28 approval fields revalidated |
| T-164-143 | Repudiation | human approval | high | mitigate | Maintainer approval covers only proposal SHA-256 `4d580f9f4a72ed6d25afa390f53369e1e08af3dc84c92b9e008d80895c13ddcf`; approval bytes are exact-copy-plus-status | closed — approval digest `e3687bf5a2afc69a79b2677c69daa3d533549d4b6f730a30a04e32cc6d13b7cd` |
| T-164-144 | Elevation of Privilege | approval scope | high | mitigate | Approval authorizes only the displayed recoverable Plan 164-38 replacement and grants no finalization, workflow, release, or completion authority | closed — later gates remain separate |
| T-164-145 | Tampering | proposal/approval files | high | mitigate | Proposal and approval are atomic regular non-symlink mode-0400 records with exact ordered nonempty fields and readback digests | closed — byte parity verified |
| T-164-146 | Tampering | installed replacement | high | mitigate | Plan 164-38 revalidated the exact approval and installed only private materialization of the authenticated commit blob by same-directory atomic rename | closed — active digest `394a47effebe04d7aaa4e098775bedd194b6f00ce6efa63eea078aa79bb9f746` |
| T-164-147 | Repudiation | rollback provenance | high | mitigate | Exact predecessor bytes were atomically published and verified first as the digest-addressed regular mode-0400 rollback | closed — rollback digest `f01859c551e6611d3bdd4dbae427cba3bc3d63e18fad7d74bbeeacf9953fffac` |
| T-164-148 | Spoofing | active installed proof | high | mitigate | Plan 164-38 installed authority is checked directly against Plan 164-37 approval, source digest/mode/OID ancestry, exact 01-39 history, physical runtime output, and probe digest | closed — installed alias passed 7 selected, 57 excluded |
| T-164-149 | Elevation of Privilege | terminal execution | high | mitigate | Plan 164-38 invoked only version/self-check inspection; repository tests and installed readiness are not terminal proof | closed — T-164-109 retains terminal ownership |
| T-164-SC | Tampering | package supply chain | low | accept | No package-manager install or dependency change occurred; active bytes are the human-approved project-authored Plan 164-37 Git blob and Plan 164-32/27/23 objects remain exact prior provenance | accepted |

## Superseding Gap-Reconciliation Assessment

The 2026-09-10 verifier and review correctly contradicted the earlier blanket
`secured` claim. Plans 164-25 through 164-33 repaired the required-CI host
coupling, caller-selected repository authority, forged tools, unrelated
installation ancestry, fixture-only installed proof, raising authority-root
discovery, stale exact-history range, and superseded installed bytes. Closure
is bound to the named production seams above, not the earlier audit prose.

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
evidence. The physical Mix/Elixir/Erlang exact-child probe and immutable OID
handoff are repository behavior; the Plan 164-37 approval and Plan 164-38
installed authority are separate external facts. Their passing lanes do not
collapse into ordinary verification or the later terminal capture.

## Accepted Risks Log

T-164-60 is explicitly accepted because Plan 164-16 changed only current-facing
maintainer documentation and its behavioral contract; executable release-control
paths were unchanged. This low-severity acceptance records the bounded scope and
does not grant or alter release authority.

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
| 2026-09-11 | 70 | 69 resolved/accepted | 1 blocking terminal-lifecycle item | Plan 164-34 reconciliation of Plans 164-29 through 164-33 and canonical Task 2 validation |
| 2026-09-11 | 70 | 69 resolved/accepted | 1 blocking terminal-lifecycle item | gsd-security-auditor post-gap-closure verification |
| 2026-09-11 | 70 | 69 resolved/accepted | 1 blocking terminal-lifecycle item | verify-work refresh; T-164-109 evidence chain remains incomplete |

## Sign-Off

- [x] All registered threats were inspected at ASVS L1.
- [ ] T-164-109 remains open until terminal protected-main evidence is captured in the mandated lifecycle order.
- [x] T-164-60 is explicitly accepted as a low-severity documentation-only scope observation with executable controls unchanged.
- [x] T-164-SC is explicitly accepted without any package-manager install or dependency change.
- [x] `threats_open: 1` reflects the pending high-severity terminal lifecycle item.
- [x] `status: pending_terminal` prevents an early secured or completed claim.

**Approval:** implementation mitigations are reconciled at ASVS L1 through Plan 164-34 Task 1, but Phase 164 is not yet security-final. T-164-109 remains open until the ordinary verifier, protected completion metadata, exact-main CI/natural schedules, and ignored no-later-write terminal capture complete in order.
