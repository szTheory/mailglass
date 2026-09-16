---
phase: 162
slug: protected-release-and-scheduled-control-recovery
status: verified
threats_open: 0
asvs_level: 1
created: 2026-08-25
---

# Phase 162 — Security

> Per-phase security contract for protected release recovery and scheduled-control evidence.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| GitHub and Hex APIs → tracked evidence | Remote bytes and availability are evidence, never authority. | Run metadata, PR metadata, package versions, tags, digests |
| Workflow trigger → protected release lifecycle | Ordinary push, schedule, and digest-free dispatch remain proposal-only. | Event identity, actor identity, candidate digest |
| Dispatcher permission response → PAT consumers | Only an exact repository-admin response may unlock protected steps. | Collaborator permission JSON and authorization output |
| Scheduled run → retained verification | Manual or stale runs cannot substitute for current schedule evidence. | Event, run ID, workflow SHA, head SHA, logs, artifacts |
| Result producer → summary and artifact | Human-readable and machine-readable verdicts share one canonical result. | Bounded status, reason, identities, payload digest |
| Release ledger → immutable target proof | Publication evidence cannot select a fallback or authorize a release. | Lifecycle, versions, target SHA, tag SHAs, content digest |
| GitHub CLI bytes → hygiene classification | Successful transport does not imply valid JSON or a valid list shape. | Run and pull-request JSON |
| Retained evidence → later disposition | Historical evidence is append-only and cannot be rewritten to manufacture success. | Phase 161 inventory and Phase 162 reconciliation |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-162-01 | Tampering / Repudiation | Release identities | high | mitigate | Timestamped exact identities; reconciliation contract | closed |
| T-162-02 | Elevation of Privilege | Disposition ledger | high | mitigate | Exact-candidate protected path remains sole authority | closed |
| T-162-03 | Tampering | Retained WT-03 evidence | high | mitigate | Append-only evidence gate and hash contract | closed |
| T-162-04 | Repudiation | Unavailable remote data | medium | mitigate | Explicit `cannot-check` acquisition state | closed |
| T-162-05 | Elevation of Privilege | Ordinary triggers | critical | mitigate | Negative-authority release-trigger fixtures | closed |
| T-162-06 | Tampering | Candidate identities | high | mitigate | Exact digest, SHA, version, and mismatch checks | closed |
| T-162-07 | Repudiation | Control versus schedule evidence | high | mitigate | Event/run provenance and schedule-only verifier | closed |
| T-162-08 | Information Disclosure | Workflow token | medium | mitigate | Read-only permissions and bounded artifacts | closed |
| T-162-09 | Tampering / Repudiation | Aggregate classification | high | mitigate | Three-state precedence tests | closed |
| T-162-10 | Tampering | Workflow summary | high | mitigate | Summary and upload consume identical JSON | closed |
| T-162-11 | Elevation of Privilege | Workflow permissions | high | mitigate | Read-only permission and topology contracts | closed |
| T-162-12 | Denial of Service | Non-pass exit policy | low | accept | Intentional fail-closed exit retains evidence | closed |
| T-162-13 | Elevation of Privilege | Target checkout | critical | mitigate | Protected policy owner and exact target checks | closed |
| T-162-14 | Tampering | Tag and package set | high | mitigate | Three-tag SHA and authorized digest checks | closed |
| T-162-15 | Spoofing / Tampering | Fallback target | high | mitigate | No `main`, latest-release, or event-tag fallback | closed |
| T-162-16 | Repudiation | Unpublished scheduled outcome | medium | mitigate | Artifact-first bounded outcome | closed |
| T-162-17 | Repudiation | Run provenance | high | mitigate | Event, run, workflow SHA, and head SHA envelope | closed |
| T-162-18 | Tampering | Artifact and summary agreement | high | mitigate | Archive and payload digest verification | closed |
| T-162-19 | Elevation of Privilege | Evidence gathering | high | mitigate | Credential-free read-only monitor | closed |
| T-162-20 | Repudiation | Elapsed-time evidence | medium | mitigate | Current-main pending/cannot-check classification | closed |
| T-162-21 | Repudiation | Capture EXIT handling | high | mitigate | Executed pass/mismatch cleanup fixtures | closed |
| T-162-22 | Tampering | Capture-to-result fields | high | mitigate | Exact output-to-JSON assertions | closed |
| T-162-23 | Elevation of Privilege | Ordinary release triggers | high | mitigate | Protected-command negative assertions | closed |
| T-162-24 | Denial of Service | Temporary worktree cleanup | medium | mitigate | Guarded cleanup fixtures | closed |
| T-162-25 | Tampering | Target resolution | high | mitigate | Exact lifecycle, tag, digest, and version gates | closed |
| T-162-26 | Repudiation | Resolution artifact | high | mitigate | Every outcome emits one provenance artifact | closed |
| T-162-27 | Elevation of Privilege | Fallback/publication paths | high | mitigate | No alternate ref or publication mutation | closed |
| T-162-28 | Denial of Service | Mandatory upload | medium | mitigate | Pass and non-pass artifact contracts | closed |
| T-162-29 | Elevation of Privilege | Idle scheduled result | critical | mitigate | Idle schedule cannot invoke protected commands | closed |
| T-162-30 | Spoofing / Tampering | Proposal discovery | high | mitigate | Exact query and cardinality validation | closed |
| T-162-31 | Repudiation | Pending artifact | high | mitigate | Provenance-bearing pending result | closed |
| T-162-32 | Denial of Service | Normal idle schedule | medium | mitigate | Only bounded idle-pending is successful | closed |
| T-162-33 | Spoofing / Tampering | CI run selection | high | mitigate | Exact checkout commit selector | closed |
| T-162-34 | Tampering | Returned CI run | high | mitigate | Head SHA and terminal-success equality | closed |
| T-162-35 | Repudiation | Scheduled evidence | high | mitigate | Checkout SHA retained; no branch/manual substitute | closed |
| T-162-36 | Elevation of Privilege | Hygiene workflow | medium | mitigate | Read-only workflow remains unchanged | closed |
| T-162-37 | Elevation of Privilege | Trigger classification | critical | mitigate | Exact protected dispatch remains sole crossing | closed |
| T-162-38 | Tampering / Repudiation | Post-merge result | high | mitigate | Protected and proposal-only tails are exclusive | closed |
| T-162-39 | Denial of Service | Final proposal gate | high | mitigate | Protected lifecycle excludes inapplicable gate | closed |
| T-162-40 | Spoofing | Candidate digest | high | mitigate | Exact digest, source, checks, and merge-tree validation | closed |
| T-162-41 | Tampering | GitHub run-list response | high | mitigate | Non-raising decode and list-shape guard | closed |
| T-162-42 | Denial of Service | CI decode boundary | high | mitigate | Malformed success becomes bounded `cannot-check` | closed |
| T-162-43 | Spoofing | Returned CI identity | high | mitigate | Exact checkout/run SHA comparison | closed |
| T-162-44 | Repudiation | Cannot-check evidence | medium | mitigate | Serialized checkout SHA and recovery detail | closed |
| T-162-12-01 | Elevation of Privilege | Protected dispatch | high | mitigate | Fresh exact admin permission before protected chain | closed |
| T-162-12-02 | Spoofing | Permission response | high | mitigate | Actor-bound response with exact role and boolean | closed |
| T-162-12-03 | Information Disclosure | PAT consumers | high | mitigate | Denied dispatcher cannot reach PAT-bearing steps | closed |
| T-162-12-04 | Repudiation | Authorization decision | medium | mitigate | Named query step and inspectable failure log | closed |
| T-162-12-SC | Tampering | Action supply chain | low | accept | No new action; existing actions remain SHA-pinned | closed |
| T-162-13-01 | Tampering | PR JSON boundary | high | mitigate | Decode without raising and require list shape | closed |
| T-162-13-02 | Repudiation | Hygiene JSON evidence | high | mitigate | Malformed paths traverse real JSON CLI boundary | closed |
| T-162-13-03 | Denial of Service | PR decoder | medium | mitigate | Bang decoder removed; bounded result retained | closed |
| T-162-13-04 | Elevation of Privilege | Release/repository controls | low | accept | Read-only classification change adds no authority | closed |
| T-162-13-SC | Tampering | Package supply chain | low | accept | No package or dependency change | closed |

All 54 plan-authored threats have a disposition. No threat at or above the configured `high` blocking threshold remains open.

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-162-01 | T-162-12 | Honest policy-block and cannot-check states intentionally fail CI after retaining their evidence. | Phase 162 plan | 2026-08-25 |
| AR-162-02 | T-162-12-SC | No action dependency changed; existing references remain immutable SHA pins. | Phase 162 plan | 2026-08-25 |
| AR-162-03 | T-162-13-04 | The PR decoder repair is read-only and cannot reach release authority. | Phase 162 plan | 2026-08-25 |
| AR-162-04 | T-162-13-SC | No package or dependency surface changed. | Phase 162 plan | 2026-08-25 |

---

## Verification Evidence

- `mix test test/scripts/phase_162_release_reconciliation_test.exs test/scripts/release_trigger_recovery_test.exs test/mix/tasks/mailglass.repo.hygiene_test.exs test/mailglass/publish/post_publish_smoke_contract_test.exs test/scripts/scheduled_control_evidence_test.exs test/scripts/release_policy_contract_test.exs --seed 0` — 81 tests, 0 failures.
- `actionlint .github/workflows/scheduled-control-evidence.yml` — passed.
- `shellcheck scripts/scheduled_control_evidence.sh` — passed.
- Live read-only sweep produced one verified current-main run and two bounded pending pre-deployment runs; it did not use manual dispatch as proof.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-25 | 54 | 54 | 0 | Codex inline security audit |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-08-25
