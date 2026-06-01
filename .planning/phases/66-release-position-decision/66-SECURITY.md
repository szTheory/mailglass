---
phase: 66
slug: release-position-decision
status: verified
threats_open: 0
asvs_level: 1
created: 2026-06-01
---

# Phase 66 - Security

Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| prior proof artifacts -> Phase 66 decision record | Earlier phase evidence is reused to justify the publish-line decision; stale or contradictory inputs would corrupt the decision. | Phase 63/64/65 verification evidence, current Hex/package truth, release-position decision data |
| release-blocking commands -> verification artifact | Required Mix commands become release-governance truth for this phase. | Command results, exit codes, publish proof, current version truth |
| release-position artifact -> version-truth files | Governance decision is translated into package versions, README pins, changelog prose, and publish-summary fields. | Candidate version, source ref, release notes, docs pins |
| candidate release files -> publish proof | Candidate files must survive the existing publish-check lane without contradicting manifest or README truth. | Package metadata, manifest version, package files, dependency pins |
| planning state -> future milestone selection | State and roadmap wording controls whether later work reopens broad feature growth prematurely. | Milestone posture, roadmap status, release/maintenance routing |

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-66-01 | Tampering | `66-VERIFICATION.md` evidence capture | mitigate | Fresh `mix verify.stability_contract`, `mix mailglass.publish.check --package mailglass_inbound`, and current version evidence are captured in `66-VERIFICATION.md`; current re-run passed on 2026-06-01. | closed |
| T-66-02 | Repudiation | `66-RELEASE-POSITION.md` | mitigate | `66-RELEASE-POSITION.md` names the active `1.0.0` candidate path, cites Phase 63/64/65 evidence, cites final Phase 66 commands, and documents the `0.4.0` fallback if a blocker appears. | closed |
| T-66-03 | Spoofing | release automation narrative | mitigate | `66-VERIFICATION.md` verifies release-please plus fallback-only `workflow_dispatch` remains the active release topology; `.github/workflows/release-please.yml` and `.github/workflows/publish-hex.yml` retain that topology. | closed |
| T-66-04 | Tampering | candidate version truth | mitigate | `mailglass_inbound/mix.exs`, `.release-please-manifest.json`, README/install guide pins, and `.planning/publish/mailglass_inbound-publish-summary.json` are aligned to `1.0.0`; `jq` parity check and publish check pass. | closed |
| T-66-05 | Repudiation | `mailglass_inbound/CHANGELOG.md` release notes | mitigate | The `1.0.0` changelog entry includes adopter action, exact verification commands, operator-impacting notes, stable/internal/deferred boundaries, and canonical compatibility links. | closed |
| T-66-06 | Tampering | feature-growth gate in `.planning/STATE.md` / `.planning/ROADMAP.md` | mitigate | State and roadmap keep Phase 66 release-position and maintenance/release ceremony posture while preserving feature-growth guardrail language. | closed |
| T-66-07 | Spoofing | release automation fallback story | mitigate | No second publish path or linked-version topology change was introduced; release-please remains canonical and `workflow_dispatch` remains fallback-only. | closed |

Status: open / closed. Disposition: mitigate / accept / transfer.

## Accepted Risks Log

No accepted risks.

## Security Audit 2026-06-01

| Metric | Count |
|--------|-------|
| Threats found | 7 |
| Closed | 7 |
| Open | 0 |

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-01 | 7 | 7 | 0 | Codex |

## Verification Evidence

| Check | Result | Evidence |
|-------|--------|----------|
| `mix verify.stability_contract` | pass | Re-run 2026-06-01; stability/docs contract lane green. |
| `mix mailglass.publish.check --package mailglass_inbound` | pass | Re-run 2026-06-01; publish proof completed with `conflict=0`. |
| `jq -r '.version, .manifest_version, .source_ref' .planning/publish/mailglass_inbound-publish-summary.json` | pass | `1.0.0`, `1.0.0`, `v1.0.0`. |
| release-position artifact smoke check | pass | Required `1.0.0`, fallback, command, canonical-doc, and prior-phase citations are present. |
| release notes and planning guardrail smoke check | pass | Changelog compatibility routing and state/roadmap feature-growth guardrail language are present. |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

Approval: verified 2026-06-01
