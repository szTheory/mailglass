# Phase 161: Canonical Workspace and Evidence Preservation - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-08-21
**Phase:** 161-canonical-workspace-and-evidence-preservation
**Mode:** assumptions
**Areas analyzed:** Durable Pre-Mutation Evidence, Canonical Main Semantics, Recoverability-First Disposition Boundary

## Assumptions Presented

### Durable Pre-Mutation Evidence

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Create one tracked inventory before any cleanup, recording each worktree and its cleanliness, stash, relevant ref/range, unreachable-object finding, disposition, and evidence reference. | Confident | `.planning/REQUIREMENTS.md` WSPC-01..04; `MAINTAINING.md`; dirty detached candidate publish summaries; `stash@{0}`; read-only `git fsck --no-reflogs --unreachable` findings |

### Canonical Main Semantics

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Treat `/Users/jon/projects/mailglass` on `main` as the sole canonical workspace, documenting rather than discarding its clean `ahead 7` state; it is not release-clean until the upstream relationship is settled. | Confident | Root checkout at `5a5e0950`; `origin/main` at `6c4b2846`; seven archive/retrospective/planning commits; `MAINTAINING.md`; `dev/mix/tasks/mailglass.repo.hygiene.ex` |

### Recoverability-First Disposition Boundary

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Retain or hand off each branch, detached candidate, stash, archive ref, and uncertain loose object until reachability and unique-work evidence exists; then use ordinary Git-managed removal and leave remote release reconciliation to Phase 162. | Confident | Multiple refs with history not reachable from `main`; preservation-only hygiene apply path; `.planning/ROADMAP.md` phase boundary; `.planning/release-target.json`; archived `160-06-SUMMARY.md` |

## Corrections Made

No corrections — all assumptions confirmed by the user.

## Methodology Applied

- **Decisive-By-Default Research Posture:** The codebase and Git evidence supported one recoverability-first approach without routine option sprawl.
- **Honest Surface Area:** Cleanliness, divergence, artifact status, and unreachable findings remain explicit; no state is renamed or hidden to manufacture a clean result.
- **Recommendation-First Synthesis:** The three assumptions were presented as one cohesive recommendation set and confirmed without modification.
- **Compatibility Contract Ergonomics:** No public compatibility or deprecation contract changes are in phase scope, so this lens raised no additional decision.

