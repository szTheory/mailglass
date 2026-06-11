# Phase 73: Inbound 1.0 Publish Evidence - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-02
**Phase:** 73-inbound-1-0-publish-evidence
**Mode:** assumptions
**Areas analyzed:** Publish Posture, Release-Evidence Artifact, Inbound-Only Dispatch Path, Evidence Completeness Verification

## Assumptions Presented

### Publish Posture
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Prepare-and-stage the inbound publish path; do NOT run the real `mix hex.publish` of `1.0.0` this phase; surface run-vs-prepare as a maintainer escalation | Unclear (escalation-worthy) | `REQUIREMENTS.md:11` (disjunctive REL-02); no `mailglass_inbound-v1.0.0` tag exists; reference apps pin `~> 0.3.0`; `MAINTAINING.md:232-234` irreversible after 60-min/zero-download window |

### Release-Evidence Artifact
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| New inbound-scoped `73-xx-RELEASE-RECORD.md` in phase dir, modeled on Phase 38 forms; archived forms untouched; drop obsolete approver fields | Likely | `.planning/milestones/v1.0-phases/38-release-rehearsal-and-proof-artifacts/38-03-RELEASE-RECORD.md` + `-CHECKLIST.md`; `REQUIREMENTS.md:12` field set; hands-free publish (no required reviewers) |

### Inbound-Only Dispatch Path
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| No workflow change needed; `package=mailglass_inbound` from `mailglass_inbound-v1.0.0` tag already works; phase documents + dry-run-rehearses + records | Confident | `publish-hex.yml:23-32,66-69,108-113,260-277`, `dry_run` input; `MAINTAINING.md:298`; `mailglass_inbound-publish-summary.json` source_ref |

### Evidence Completeness Verification
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Documented artifact + explicit pending markers (Phase 38 "not run" convention), no new live-asserting gate; reference pins flip to `~> 1.0` only when publish actually runs | Likely | `38-03-RELEASE-RECORD.md:9-12,29`; PROOF-01/02 required-vs-advisory line; `71-VERIFICATION.md:40-41` deferral |

### Cross-cutting defect flagged by analyzer
`MAINTAINING.md:256-257` cites `.planning/phases/38-release-rehearsal-and-proof-artifacts/...`, a directory archived to `.planning/milestones/v1.0-phases/...` — stale runbook path, broken release contract, folded into Phase 73 scope (D-10).

## Corrections Made

No corrections — the maintainer confirmed both presented question sets as the recommended option.

- **Publish posture:** chose "Prepare & stage" (Recommended) over "Run the real publish now" and "Prepare, then run if green". This resolves the escalation-worthy fork: the phase performs no irreversible Hex publish.
- **Evidence shape / runbook fix:** chose "As proposed" (Recommended) — new inbound-scoped RELEASE-RECORD in phase dir, pending markers, fix the stale `MAINTAINING.md:256-257` path, no new executable gate.

## Methodology Lenses Applied

- **Decisive-By-Default** — areas 2-4 settled with single recommendations.
- **Recommendation-First / escalation** — area 1 (irreversible publish posture) correctly escalated to the maintainer per the release/publish escalation rule rather than silently decided.
- **Honest Surface Area** — pending evidence must read as pending; stale runbook path surfaced and folded in.
- **Compatibility Contract Ergonomics** — inbound-only dispatch path and reference-pin timing handled explicitly.
