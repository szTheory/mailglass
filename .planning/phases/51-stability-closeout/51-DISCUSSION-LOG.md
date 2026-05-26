# Phase 51: Stability Closeout - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in `51-CONTEXT.md` — this log preserves the analysis.

**Date:** 2026-05-26
**Phase:** 51-stability-closeout
**Mode:** assumptions
**Areas analyzed:** Phase 35 bookkeeping, Branch protection, Citext race, Boundary warnings, WR closeout, Release-engineering leftovers

## Assumptions Presented

### Phase 35 bookkeeping
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `CLOSE-01` is a bookkeeping reconciliation task, not a new implementation effort. | Confident | `.planning/milestones/v1.0-phases/35-stability-contract-audit/35-VALIDATION.md`; `test/mailglass/stability_contract_test.exs` |

### Branch protection
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Phase 51 should update the existing repo-as-code branch-protection assets instead of replacing them with manual-only documentation. | Likely | `scripts/setup_branch_protection.sh`; `.github/workflows/branch-protection-drift.yml`; `MAINTAINING.md` |

### Citext race
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| The current citext probes are a mitigation, but the real fix must remove or contain the shared OID invalidation path caused by schema teardown/rebuild during tests. | Likely | `test/support/citext_probe.ex`; `test/mailglass/persistence_integration_test.exs`; `test/mailglass/migration_test.exs` |

### Boundary warnings
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Boundary-warning closeout should focus on test/support and verification-lane seams rather than widening runtime module/package dependencies. | Likely | `test/mailglass/boundary_test.exs`; `lib/mailglass/operator/support_summary.ex`; milestone closeout notes in `.planning/PROJECT.md` / `.planning/MILESTONES.md` |

### WR-01..WR-06
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| The historical WR items should be re-audited against today’s code and mostly retired by explicit fix-or-rationale decisions, not by default reopening the original Phase 4 implementation. | Likely | `.planning/milestones/v0.1-MILESTONE-AUDIT.md`; `.planning/ROADMAP.md` |

### Release-engineering leftovers
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Post-`v1.2` release-engineering leftovers already surfaced by Phase 50.7 should be folded into this final stability closeout where they overlap the existing debt boundary. | Likely | `.planning/phases/50.7-v1-2-repo-hygiene-pass/50.7-01-SUMMARY.md`; `MAINTAINING.md` |

## Corrections Made

None. User response: `proceed`.

## Outcome

- Assumptions accepted as the decision baseline for Phase 51.
- `51-CONTEXT.md` written with locked implementation decisions and canonical refs.
- No deferred user corrections or scope expansions were introduced during discuss-phase.
