# Phase 60: release-trust-gate-drift-prevention - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in 60-CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-29
**Phase:** 60-release-trust-gate-drift-prevention
**Mode:** assumptions
**Areas analyzed:** Published-version + clean-baseline trust journey (EVID-03/EVID-02); OPS-01 hackney regression protection; OPS-02 release-checklist/cadence enforcement

## Assumptions Presented

### Area 1 — Published-version + clean-baseline trust journey (EVID-03, EVID-02)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Trust runner is unshipped (root `dev/` tree); both lanes run repo-root runner with `--host-root reference/host_app` | Confident | `dev/mix/tasks/mailglass.trust.run.ex`; root `mix.exs:100-102,325-327` (dev compiled :dev/:test, `:files` ships lib only); alias only in root `mix.exs:229-231`, absent in `reference/host_app/mix.exs:38-42` |
| Clean-baseline/published-version property = `reference/host_app` on Hex deps `~> 1.3`, not path deps; bump `mix.exs` (`~> 1.2`) + refresh `mix.lock` | Confident | `reference/host_app/mix.exs:32-34`; `scripts/check_clean_baseline_hex_only.sh`; `59-VERIFICATION.md:79` |
| EVID-02 = `trust_lane_clean_baseline` in `ci.yml`; EVID-03 = same mechanism on `post-publish-smoke.yml`, POST-publish sentinel | Confident | `post-publish-smoke.yml:310-438`; `publish-hex.yml:115,139-141` (gate-ci-green inspects ci.yml); hands-free publish lock |
| 59-02-PLAN Edit B (`working-directory: reference/host_app` + bare task call) is superseded/impossible | Confident | `59-VERIFICATION.md:42`; `59-02-SUMMARY.md:85-93` |

### Area 2 — OPS-01 hackney regression protection + issue #32
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Root cause fixed (installer emits `config :swoosh, :api_client, false`); keep repo-local unit guard | Confident | `install_first_preview_smoke_test.exs:16-20` |
| No live workflow guard yet; "completion" was one-time local run; add hackney/api_client assertion to `consumer-install`; close #32 only after next green smoke | Confident (gap) / Likely (exact guard placement) | completed hackney todo; `gh issue view 32` → OPEN; `post-publish-smoke.yml:367-438,408-411` |

### Area 3 — OPS-02 release-checklist / cadence
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Edit `MAINTAINING.md` to add green trust evidence as release gate + closeout requirement | Confident | `MAINTAINING.md:26-44,123-176,241-249` |
| Reconcile "Required Checks" list — omits Phase 59 `Trust Lane Repo Head` | Confident | `MAINTAINING.md:144-147`; `59-VERIFICATION.md:41,56` |
| Fix stale manual-approval-gate lines (~24, ~260) — contradict locked hands-free publish | Confident | `MAINTAINING.md:24,260,181-188`; `release-please.yml:215-232`; `publish-hex.yml` env has no reviewers |
| Optional machine-checkable doc-contract test | Likely | repo precedent `install_first_preview_smoke_test.exs:30-39` |

## Corrections Made

No corrections — all three assumption areas confirmed ("Yes, proceed").

## Escalated Decisions

One strategic fork was surfaced to the user (branch-protection / trust-contract posture):

- **clean-baseline lane gate posture** — User chose **Publish-gate-only (A1 lock)**: the lane gates publish via `gate-ci-green` but is NOT added to `REQUIRED_CHECKS`. Recorded as D-04. Reversible later.

## External Research

None performed — codebase provided sufficient evidence for all three areas.
