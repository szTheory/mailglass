---
phase: "165"
slug: reconcile-terminal-proof-and-milestone-archive-ordering
status: secured
threats_open: 0
asvs_level: 1
block_on: high
created: "2026-09-13"
updated: "2026-09-13"
---

# Phase 165 — Security

> OWASP ASVS L1 review of all five Phase 165 STRIDE registers. Every high-severity threat is blocking
> until its named evidence is green; no terminal report is ordinary-completion evidence.

## Trust Boundaries

| Boundary | Data Crossing | Fail-Closed Rule |
|----------|---------------|------------------|
| Repository to authenticated staging | full Git OID, index record, loader/finalizer bytes, SHA-256, file modes | Block on missing, non-blob, staged, working-tree, digest, path, type, or mode mismatch. |
| Tracked source to installed command | approved source tuple, predecessor identity, physical runtime closure | Block installation/readiness on tuple drift or unproved rollback; installed bytes never enter repository CI. |
| Human lifecycle records to canonical audit | requirement ownership, verification, validation, phase scope | Block unless canonical audit independently reaches 16/16, 5/5, 16/16, 5/5 and five compliant validations. |
| Audit preview to archive mutation | non-null audit, exact phase set, quick-task set, config override | Block confirm until the exact dry-run digest is approved and unchanged under a proven no-tag manifest. |
| Archive tree to generated state and final commit | archived artifacts, live ledger changes, state.json | Block protected evidence until every tracked write converges and canonical state publication succeeds. |
| Protected GitHub evidence to ignored report | exact SHA, attempt, event, branch, status, schedules | Block terminal invocation unless evidence is exact, natural, attempt-1, and read-only. |
| Report publication to final cleanliness | ignored report path, late HEAD and porcelain state | Convert late failure to blocked; never leave a pass report after authority moves or dirt appears. |

## ASVS L1 Threat Register

The authoritative key is `{plan, threat_id}`. A `closed` row means the planned mitigation is present
and its named verification passed in the owning plan or is enforced as a blocking post-completion gate.

| Plan | Threat ID | Category | Component | Severity | Disposition | Blocking Mitigation / Evidence | Status |
|------|-----------|----------|-----------|----------|-------------|--------------------------------|--------|
| 01 | T-165-01-T01 | Tampering | staged manifest and installed bytes | high | mitigate | Closed manifest, one full OID, exact index/worktree bytes, SHA-256, and private fixed modes; hostile missing/drift fixtures pass. | closed |
| 01 | T-165-01-S01 | Spoofing | CI and scheduled evidence selectors | high | mitigate | Unique exact-SHA/main/event/attempt-1 selection rejects caller IDs, reruns, dispatches, wrong SHA, and wrong branch. | closed |
| 01 | T-165-01-R01 | Repudiation | terminal report | high | mitigate | Semantic component evidence plus late HEAD/clean checks; post-report mutation produces blocked rather than pass. | closed |
| 01 | T-165-01-E01 | Elevation of privilege | repository verification lane | high | mitigate | Installed boundary is tagged, excluded by default and from required CI, and proven only by the dedicated controlled-host alias. | closed |
| 02 | T-165-02-T01 | Tampering | Phase 161 requirement ownership | high | mitigate | Exactly WSPC-01/03/04 were added to their truthful owner; four-ID and sixteen-ID cardinality gates passed. | closed |
| 02 | T-165-02-R01 | Repudiation | Phase 161/163 validation status | high | mitigate | Canonical validation refresh retained non-vacuous green rows before exact `status: validated`. | closed |
| 02 | T-165-02-I01 | Information disclosure | historical evidence | low | accept | Only already tracked planning metadata changed; no secret or runtime payload was introduced. | accepted |
| 03 | T-165-03-T01 | Tampering | ROADMAP/PROJECT/STATE scope | high | mitigate | Ledgers agree on Phases 161-165, 16 requirements, quick-task exclusion, and accepted 14-PR debt. | closed |
| 03 | T-165-03-R01 | Repudiation | state.json publication | high | mitigate | Machine state is generated only by `publishStateContract`; pre-archive publication returned the exact success tuple. | closed |
| 03 | T-165-03-S01 | Spoofing | current terminal authority wording | medium | mitigate | Phase 164 proof is explicit immutable history; archived-v2.7 authority remains pending until the post-completion runbook. | closed |
| 04 | T-165-04-T01 | Tampering | installed executable bytes | high | mitigate | Human-approved source OID/blob/SHA-256/destination/mode tuple, atomic no-overwrite publication, and post-install byte proof passed. | closed |
| 04 | T-165-04-E01 | Elevation of privilege | runtime closure | high | mitigate | Eight physical executable paths, versions, owners, modes, and digests were revalidated; installed mode is 0500. | closed |
| 04 | T-165-04-D01 | Denial of service | failed replacement | medium | mitigate | Absent/create rollback was induced and removed only the exact approved installed object before identical reinstall. | closed |
| 04 | T-165-04-R01 | Repudiation | installation authorization | high | mitigate | Plan 04 records the immutable approved tuple and rejects any source, destination, predecessor, runtime, or rollback drift. | closed |
| 05 | T-165-05-T01 | Tampering | canonical audit and archive preview | high | mitigate | Runbook blocks on exact scores, five validations, non-null audit, exact Phases 161-165, no quick tasks, and complete archive result. | closed |
| 05 | T-165-05-E01 | Elevation of privilege | archive confirmation | high | mitigate | One blocking-human checkpoint binds approval to the unchanged dry-run SHA-256 immediately before canonical confirm. | closed |
| 05 | T-165-05-R01 | Repudiation | final tracked commit | high | mitigate | Runbook requires all archive outputs, last-Markdown `publishStateContract`, final state.json commit, and no later tracked write. | closed |
| 05 | T-165-05-S01 | Spoofing | protected CI and schedule evidence | high | mitigate | Terminal gate requires clean `HEAD == origin/main`, exact-SHA attempt-1 push CI, and natural attempt-1 schedules. | closed |
| 05 | T-165-05-I01 | Information disclosure | terminal report | medium | mitigate | Finalizer emits only bounded semantic evidence below the existing ignored/private tmp boundary and rejects tracked output. | closed |
| 05 | T-165-05-D01 | Denial of service | natural scheduled evidence | low | accept | Missing natural evidence waits or blocks; no workflow dispatch, rerun, or alternate evidence is authorized. | accepted |

## Blocking Completion Gates

Ordinary Phase 165 completion is blocked if any of these cannot be proved:

- repository staging bytes and the closed manifest match their authenticated Git authority;
- installed bytes and the approved runtime/predecessor/rollback tuple match Plan 04 evidence;
- all repository, hostile, controlled-host, lane-isolation, and tag-omission fixtures pass;
- `165-VALIDATION.md` is exact `status: validated` and `165-VERIFICATION.md` passes;
- the audit and archive remain post-executor actions rather than circular ordinary prerequisites; or
- any high-severity row above is not `closed`.

Post-completion archive confirmation and terminal capture are separately blocked if any of these fail:

- canonical audit semantics or explicit 14-PR accepted-debt disclosure;
- non-null exact archive preview, unchanged human-approved preview digest, config-byte restoration,
  or the `git-tag` manifest exclusion;
- complete archived state, final `publishStateContract` success, or inclusion of state.json in the final commit;
- exact protected-main identity, attempt-1 CI, natural attempt-1 schedule evidence, or late cleanliness; or
- ignored-only output and the no-later-v2.7-write hard stop.

## Accepted Risks

| Risk | Severity | Reason | Constraint |
|------|----------|--------|------------|
| Natural schedule latency | low | Scheduled controls may not yet have run for the final archive SHA. | Wait or report blocked; never dispatch/rerun. |
| Fourteen open PRs | operational debt | Existing evidence classifies the repository-hygiene policy result as blocked without invalidating completed maintenance behavior. | Disclose as accepted 14-PR debt; do not close PRs in this lifecycle. |

## Security Sign-Off

- [x] Every high-severity threat from Plans 165-01 through 165-05 has an ASVS L1 mitigation and blocking disposition.
- [x] Staging, installed authority, audit, archive, state publication, evidence selection, and late cleanliness are fail-closed.
- [x] The scoped config mechanism is extracted from the runbook and tested for success plus initialization, archive, and restoration failures.
- [x] No dependency, CI topology, product/API/schema/UI, release, publication, tag-push, branch-delete, dispatch/rerun, or PR-close capability was added.
- [x] `threats_open: 0`; ordinary completion may proceed only while all named automated evidence stays green.
