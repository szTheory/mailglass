# Phase 117: Release Cut + Milestone Closeout - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-21
**Phase:** 117-release-cut-milestone-closeout
**Mode:** assumptions
**Areas analyzed:** Version Target, Publish Allowlist Hygiene, Inbound Version Line, Release Ceremony + Closeout

## Assumptions Presented

### Version Target
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Cut as MINOR 1.8.0 (core+admin), not the 1.7.1 patch PR #87 shows | Unclear (maintainer go/no-go) | PR #87 scored patch because v1.13 body is unpushed; ~35 feat commits touch mailglass_admin/lib adding public component API (Phase 110); ROADMAP/REL-02 say "admin-minor" |
| Mechanism: push v1.13 body to origin/main → RP re-scores to 1.8.0 (no Release-As override) | Confident | `git rev-parse origin/main` = 766edf89 (PR #86 merge); local main = 39613052 (+227 commits); `git merge-base --is-ancestor 03cf185b origin/main` = false |

### Publish Allowlist Hygiene
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `.planning/publish/mailglass_admin-files.expected` is stale; regenerate + commit before merge | Confident | 4 new admin/lib files missing (theme_controller.ex, mount_path.ex, mount_path_hook.ex, operator/tenants.ex); prepublish-summary runs `mix mailglass.publish.check` fail-closed (same blocker as 108) |

### Inbound Version Line
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Inbound ships paired release from D-13 exact-pin re-pin only (== 1.8.0); no feature bump | Likely | PR #87 inbound mix.exs diff = pin re-pin only, no @version change; v1.13 scope-lock admin+demo; inbound lib changes are docs: strips |

### Release Ceremony + Closeout
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Reuse 108 6-wave structure verbatim, retargeted to 1.8.0 | Confident | 108-01-PLAN.md template; MAINTAINING.md runbook |
| No reference-baseline pin bump (resolves ~> 1.0) | Confident | reference/{host_app,demo_app}/mix.exs pin all three at `~> 1.0` |
| Audit corrected scope: 9 phases (109–117), 36 reqs; not gsd-sdk counts | Confident | phase dirs 109–116 + 117 on disk; documented gsd-sdk 999.x count-inflation gotcha |
| #32 hackney smoke noise is a non-blocker | Confident | known swoosh/hackney OPS-01 false-positive |

## Corrections Made

No corrections — all assumptions confirmed.

The one Unclear item (version target) was resolved by the maintainer via AskUserQuestion:
- **Question:** Version target for the v1.13 release cut?
- **Maintainer choice:** Minor 1.8.0 (recommended) — push the v1.13 body to main so RP
  re-scores to 1.8.0/1.8.0; inbound re-pins == 1.8.0.

## External Research

None — internal release mechanics fully determined by repo state, RP config, and the 108 playbook.
