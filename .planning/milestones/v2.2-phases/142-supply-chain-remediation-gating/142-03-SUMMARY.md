---
phase: 142-supply-chain-remediation-gating
plan: 03
subsystem: infra
tags: [supply-chain, hex-audit, deps-audit, ci, checkpoint, d-14, d-15]

# Dependency graph
requires:
  - phase: 142-01
    provides: Mailglass.SupplyChain.AcceptedAdvisories + mix mailglass.audit --kind hex|deps wired into ci.yml's hex_audit and deps_audit_advisory jobs
provides:
  - Live-CI evidence that Hex Audit is green BECAUSE the shared allowlist suppressed two genuinely-detected cowlib findings in mailglass_admin (not a vacuous "no findings" pass)
  - Live negative-control evidence that removing one accepted-advisory entry makes mix mailglass.audit --kind hex exit non-zero, naming that specific advisory
  - D-14's blocking checkpoint recorded as satisfied, clearing 142-04 (the atomic merge-gating promotion) to proceed
affects: [142-04-gate-promotion]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "D-14 checkpoint evidence pattern: a plan whose sole purpose is to record verbatim live-CI + local-negative-control log excerpts as the gate in front of a promotion commit, rather than trusting 'prior plan merged' as the precondition"

key-files:
  created:
    - .planning/phases/142-supply-chain-remediation-gating/142-03-SUMMARY.md
  modified: []

key-decisions:
  - "Both required observations (live CI detected-and-suppressed run; local negative control) were supplied as verbatim evidence by the orchestrator/human from a real PR run (#144) and a real local repro, rather than re-executed inline in this plan's own task — the checkpoint's <resume-signal> explicitly accepts pasted excerpts as the resume mechanism, which is what happened here."

patterns-established: []

requirements-completed: [VULN-05, VULN-03]

coverage:
  - id: D1
    description: "A real ci.yml PR run's Hex Audit job log names BOTH EEF-CVE-2026-43966 and EEF-CVE-2026-43969 as detected in mailglass_admin AND suppressed by the allowlist — not merely 'no findings' (D-14's exact requirement)"
    requirement: "VULN-05"
    verification:
      - kind: other
        ref: "PR #144, run https://github.com/szTheory/mailglass/actions/runs/30422237349, job 90481258959 (Hex Audit, Elixir 1.18 / OTP 27), head SHA e0289746538a979a94490f8fc937dd3c4f83b890 — verbatim log excerpt recorded below"
        status: pass
    human_judgment: false
  - id: D2
    description: "A deliberate negative-control run (one @entries item temporarily removed from Mailglass.SupplyChain.AcceptedAdvisories) makes mix mailglass.audit --kind hex exit non-zero, naming that specific advisory — proving the allowlist genuinely filters rather than passing vacuously"
    requirement: "VULN-03"
    verification:
      - kind: other
        ref: "Local repro at head SHA e0289746538a979a94490f8fc937dd3c4f83b890, EEF-CVE-2026-43969 entry temporarily removed from lib/mailglass/supply_chain/accepted_advisories.ex, exit code 1, verbatim output recorded below; file restored and confirmed byte-identical via git diff --exit-code"
        status: pass
    human_judgment: false

duration: 4min
completed: 2026-07-29
status: complete
---

# Phase 142 Plan 03: D-14 Checkpoint — Wave 1 Observed Green With Cowlib Genuinely In Scope Summary

**Recorded live-CI evidence that `Hex Audit` is green because the shared allowlist suppressed two genuinely-detected cowlib advisories, plus a local negative-control proof that the allowlist fails closed — satisfying D-14's blocking gate in front of 142-04's merge-gating promotion.**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-07-29T04:00:00Z
- **Completed:** 2026-07-29T04:04:00Z
- **Tasks:** 1 (`checkpoint:human-verify`, gate="blocking")
- **Files modified:** 1 (this SUMMARY)

## Accomplishments

- Confirmed, on a real `ci.yml` PR run, that the `Hex Audit (Elixir 1.18 / OTP 27)` job log explicitly names both `EEF-CVE-2026-43966` and `EEF-CVE-2026-43969` as detected in `mailglass_admin` and suppressed by the allowlist — not a bare "no findings" pass.
- Confirmed the companion `Deps Audit Advisory (Elixir 1.18 / OTP 27)` lane on the same run also reports "all findings accepted."
- Confirmed, via a local negative control at the same HEAD, that temporarily removing the `EEF-CVE-2026-43969` entry from `Mailglass.SupplyChain.AcceptedAdvisories`'s `@entries` makes `mix mailglass.audit --kind hex` exit 1, naming that specific advisory in the blocking output — proving the allowlist genuinely fails closed rather than passing vacuously.
- Confirmed the file was restored and is byte-identical to its committed state (`git diff --exit-code` exit 0).
- Confirmed no advisory drift after merging origin/main's 12 dependabot bumps: cowlib remains pinned at 2.19.0 in `mailglass_admin/mix.lock`; `mailglass_inbound` has no cowlib entry.

## Task Commits

1. **Task 1: Confirm Wave 1 is green with cowlib genuinely in scope (D-14 gate)** - checkpoint resolved via evidence recorded in this SUMMARY (no code changes; see Plan Metadata commit below for the SUMMARY/state commit)

_This plan is a single `checkpoint:human-verify` task with `gate="blocking"`. No implementation code was written or modified — the task's entire output is the recorded evidence below, per the plan's `<output>` spec._

## Evidence: Observation 1 — real CI run, Hex Audit green because of detection-then-suppression (D-14)

- **PR:** https://github.com/szTheory/mailglass/pull/144
- **Run:** https://github.com/szTheory/mailglass/actions/runs/30422237349
- **Head SHA:** `e0289746538a979a94490f8fc937dd3c4f83b890`
- **Job:** `Hex Audit (Elixir 1.18 / OTP 27)` (job id `90481258959`) — completed/success

Verbatim log excerpt:

```
##[group]Run mix mailglass.audit --kind hex
mix mailglass.audit --kind hex
Accepted (mailglass_admin): EEF-CVE-2026-43966 is an accepted-allowlist finding.
Accepted (mailglass_admin): EEF-CVE-2026-43969 is an accepted-allowlist finding.
mix mailglass.audit --kind hex: all findings accepted.
```

Companion lane `Deps Audit Advisory (Elixir 1.18 / OTP 27)` (job id `90481258949`) — completed/success:

```
##[group]Run mix mailglass.audit --kind deps
mix mailglass.audit --kind deps
mix mailglass.audit --kind deps: all findings accepted.
```

**Why this proves detection-then-suppression rather than absence:** the `Accepted (<dir>): <id> …` line is only emitted when that directory's `hex.audit` exited non-zero having flagged the finding, and the allowlist then matched it. A vacuously-clean scan prints no such line — this is the exact distinction D-14 requires between "green because nothing was found" and "green because something real was found and correctly suppressed."

## Evidence: Observation 2 — local negative control (D-15)

Run locally at the same HEAD (`e0289746538a979a94490f8fc937dd3c4f83b890`). The `EEF-CVE-2026-43969` entry (cowlib, Cookie Request Header Injection) was temporarily removed from `@entries` in `lib/mailglass/supply_chain/accepted_advisories.ex`.

`mix mailglass.audit --kind hex` then exited **1** with:

```
Compiling 1 file (.ex)
Generated mailglass app
Delivery blocked (mailglass_admin): cowlib EEF-CVE-2026-43969
```

The file was then restored and verified byte-identical to its committed state:

```
$ git diff --exit-code lib/mailglass/supply_chain/accepted_advisories.ex
$ echo $?
0
```

Independently re-confirmed by the orchestrator. **The allowlist genuinely fails closed; it does not pass vacuously.**

## Supporting evidence

No advisory drift after merging origin/main's 12 dependabot bumps into this branch: cowlib remains pinned at `2.19.0` in `mailglass_admin/mix.lock`; `mailglass_inbound` has no cowlib entry at all.

## Files Created/Modified

- `.planning/phases/142-supply-chain-remediation-gating/142-03-SUMMARY.md` - this file, recording both D-14/D-15 evidence excerpts

## Decisions Made

- Both required observations were supplied as verbatim evidence from a real PR run (#144) and a real local repro, matching the checkpoint's `<resume-signal>` contract ("Paste both observed excerpts … or type 'approved' once both are recorded in SUMMARY.md"). No re-execution was needed inline in this plan; the evidence was independently produced and independently re-confirmed (file-restore diff) before being recorded here.

## Deviations from Plan

None - plan executed exactly as written. The single `checkpoint:human-verify` task is satisfied by the two recorded observations, matching the plan's `must_haves.truths` verbatim.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- **D-14's gate is satisfied with recorded evidence, not assumed from "142-01 merged."** Both the live-CI detected-and-suppressed excerpt and the local negative-control failure excerpt are recorded above, verbatim, with URLs/job-ids/SHA for re-opening.
- **142-04 (the atomic merge-gating promotion) is now cleared to proceed.** Its `depends_on: ["142-03"]` precondition is met: `hex_audit` is proven green for the right reason (genuine detection + suppression, not vacuous absence), and the allowlist is proven to fail closed via the negative control.
- `git status --short` shows only the pre-existing, orchestrator-owned `.planning/config.json` modification (auto-mode flag) — untouched by this plan, per instruction.

## Self-Check: PASSED

This SUMMARY.md file exists at the path above (verified via the Write tool's success). No code commits or file-path claims beyond this SUMMARY and the pre-existing evidence sources (PR #144, run 30422237349, job 90481258959/90481258949) are made in this plan.

---
*Phase: 142-supply-chain-remediation-gating*
*Completed: 2026-07-29*
