---
gsd_state_version: "1.0"
milestone: v2.10
milestone_name: UI Repairs & Faithful Storybook
current_phase: 178
current_phase_name: Preview Authoring and Milestone Review
status: executing
stopped_at: Completed 178-12-PLAN.md
last_updated: "2026-10-29T13:14:09.799Z"
last_activity: 2026-10-29
last_activity_desc: Phase 178 execution started
state_head: 3597a79e57cb7a1a5059c10006415e6624466fd8
progress:
  total_phases: 5
  completed_phases: 4
  total_plans: 50
  completed_plans: 42
  percent: 80
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-10-27)

**Core value:** Email you can see, audit, and trust before it ships.
**Current focus:** Phase 178 — Preview Authoring and Milestone Review

> **Note on the sections below.** Some of the accumulated context that follows is v2.7-era prose that
> has since been corrected — `## Operator Next Steps

- Phase 175 is complete: 8/8 UAT rows closed `source: automated` by `mailglass_admin/test/mailglass_admin/phase175_prohibition_contract_test.exs` (16 tests, one red mutation per prohibition). Full admin suite 677/0 under `--seed 0`; VERIFICATION `passed`; security has 0 open threats. No owner verification is outstanding.
- Next: `/gsd-discuss-phase 176` (no CONTEXT.md yet). D-52 and `.planning/METHODOLOGY.md` apply, including the 2026-10-27 judgment-tier prohibition clause: author must-NOT items as `verification: test`.

## Current Position

Phase: 178 (Preview Authoring and Milestone Review) — EXECUTING
Plan: 5 of 12
Status: Ready to execute
Last activity: 2026-10-29 — Phase 178 execution started

Progress: [████████░░] 80%

## v2.9 Roadmap Shape (historical; shipped and archived)

The progress statements below are retained execution history; v2.9 is complete.

- Phases 168–173 own all 28 approved requirements. Phases 168–172 are complete; Phase 170 independently passed 30/30 must-haves across INUX-01–04, and Phase 172 passed 9/9 must-haves across MAILUX-01–04. Phase 173 remains.
- Phase 168 passed 96/96 plan truths and 5/5 roadmap truths. Phase 169 passed 100 positive must-haves, including 82 UI states, with five negative constraints individually adjudicated. Phase 170 completed eight plans across six waves; its verification, 21-threat security audit, clean code review, package suites, and connected browser checks passed. D-52 leaves no machine-observable owner UAT. Later slices follow ROADMAP.md.
- Code-first; equal engineer and support/on-call operator priority; bounded direct visual inspection and existing automated checks.
- The approved unsubscribe boundary covers truthful GET/invalid/expired pages; interactive browser submission remains deferred.

## v2.8 Roadmap Shape

Historical scope for the completed v2.8 milestone follows. Its no-Phase-168 restriction does not apply to the approved v2.9 roadmap.

- **Phase 166** — GREEN-01..05 + CTRL-01..05 (10 requirements). First because fixing a false green can
  surface previously-unrun failures (GREEN-01 exposes 325 never-executed admin tests; all 510 pass
  locally today, so blast radius is bounded but nonzero), and because CTRL-04 has a calendar deadline
  of **2026-10-27**.

- **Phase 167** — DOCS-01..06 + STAND-01 (7 requirements). Genuinely independent; safely last.
- **Exactly two phases. There is no Phase 168.** Hard timebox 5 working days, WIP limit: at most one PR open at a time.
- **CORRECTION (2026-09-18), appended rather than rewritten.** The `/gsd-audit-milestone v2.8` audit
  found that CTRL-02/CTRL-03 are blocked by a defect in the control Phase 166 shipped, not by scope
  that "did not fit." Phase **167.1** was inserted to close it. The literal constraint holds — there
  is still no Phase 168 — and the boundedness rule is honored in substance: 167.1 fixes a committed
  v2.8 requirement rather than admitting new scope. Nothing outside the 17 requirements was accepted.
  On day 5, ship what is done and close regardless.

- **Stop line:** every claim the repo makes about itself is either true or tested. Anything discovered
  that is not one of the 17 requirements is **filed, not fixed**.

- **Standing prohibition:** no phase may satisfy a requirement by weakening a gate, relaxing a
  fail-closed control, deleting an expiry, lowering a test's rigor, or narrowing a generator.
  Pre-refused by name: `cron-guard` `continue-on-error` / dropping a cron; deleting the
  `recheck_by` / `unused_entries` machinery; lowering `max_runs` or narrowing the inbound property
  generator.

- **No product code changes.** DOCS-05's `css_inliner` disposition is the single permitted `lib/` change.
- Known cross-file locksteps: GREEN-03 ⇒ `@suite_floor_env_occurrences` 2 → 3 in
  `lane_classification_drift_test.exs:56` *in the same change*; DOCS-04 ⇒
  `guides/migration-from-swoosh.md:31-32` and `test/mailglass/docs_contract_test.exs:558` move together
  (Phase 125 pin-drift shape); CTRL-02 + CTRL-03 are cause and symptom of one red and land together.

## Lifecycle Authority

- **v2.7 is archived.** The canonical audit passed (16/16 requirements, 5/5 phases, 16/16 integration,
  5/5 flows, Nyquist compliant) and `milestone.complete v2.7 --confirm` ran on 2026-09-15 under the
  scoped `git.create_tag=false` override defined in `165-FINALIZATION.md` §2, restored byte-for-byte
  afterward. Archived to `.planning/milestones/v2.7-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md` and
  `v2.7-phases/`. **No `v2.7` tag exists and none may be created.**

- Closeout type: `override_closeout`. `init.manager` projected Phases 161 and 165 `stale` — a timestamp
  heuristic firing on the runbook-mandated completion-metadata commits, not an unverified phase; both
  VERIFICATION.md records are `status: passed` (161: 21/21, 165: 5/5).

- **Known verification overrides: 0 newly acknowledged, 0 carried forward.** The pre-close artifact
  audit's 27 open items (23 deferred, 3 UAT gaps, 1 verification gap) all belong to already-archived
  milestones (v0.2, v1.1, v1.13, v1.14, v2.0, v2.2) and were deliberately not acknowledged into v2.7;
  acknowledging them would attribute foreign debt to this milestone. They remain open against their own.

- Phase 164 completed successfully at protected-main SHA
  `851e3640f7f0eb6e784611d157e3a7329f87e2dc`. Its ignored terminal report is immutable historical
  evidence only; Phase 164 pending/current-authority statements retained in the accumulated execution
  history below are not live milestone blockers or v2.7 terminal authority.

- **Sections 1–5(CI) of `165-FINALIZATION.md` are complete.** Canonical audit, archive preview,
  approved archive, final tracked convergence, and protected-main integration all ran. The archive is
  on protected `main` at **`79247dafbb3b2d3a56114127e1e96e62cbcf33db`** (PR #257, squash), and the
  push-CI requirement is satisfied exactly: workflow `CI`, event `push`, branch `main`, that exact SHA,
  attempt 1, completed/success (run 35108991834). The runbook now lives at
  `milestones/v2.7-phases/165-reconcile-terminal-proof-and-milestone-archive-ordering/165-FINALIZATION.md`.

- **v2.7 closes ARCHIVED WITHOUT TERMINAL PROOF. Sections 6–7 are not achievable under current
  policy and are not pending work.** The runbook also requires all three registered scheduled controls
  to report `completed/success` at that exact SHA. All three fail closed *by design*, on one shared
  root cause — the batch of PRs (fourteen, at the time) this milestone accepted as permanent
  operational debt while left open:
  `repo-hygiene` → `blocked` / "open PR(s) require disposition before release";
  `post-publish-smoke` → `blocked` / `scheduled_target_not_published` (PR #222 is an
  authorized-but-unpublished target); `release-please` → `blocked` / `proposal_identity_mismatch`
  (the same open #222 proposal). Clearing them would require closing those PRs, publishing a release,
  or relaxing the controls' fail-closed semantics — each explicitly on the runbook's own Forbidden
  Operations list. Phase 165 therefore demands green evidence from controls Phase 162 deliberately made
  fail-closed under exactly the condition v2.7 chose to accept. Recorded as a known contract
  contradiction, not a gap in the milestone: the archive is complete and green on protected `main`, and
  the terminal report was always ignored-only evidence, never the deliverable.

- **CORRECTION (2026-09-16), appended rather than rewritten so the archived reasoning stays readable
  as written:** the bullet above attributes the `release-please` → `proposal_identity_mismatch` red to
  open proposal PR #222. That attribution is **wrong**. #222 was closed on 2026-09-16 and the control
  stayed red. The real cause was `.planning/release-target.json`, frozen at `status: authorized` /
  `publication: not_started` since the 2.5.0 release on 2026-08-20 — 0 successes in 100 runs. Fixed in
  PR #266 (ledger closed out to `inactive`); PR #267 adds the missing close-out path, since nothing in
  the pipeline ever wrote the ledger and every release would otherwise strand it the same way. This
  does **not** reopen §6–7: `repo-hygiene` and `post-publish-smoke` remain blocked on the accepted
  open-PR debt exactly as recorded, so the terminal-proof conclusion is unchanged.

- Re-opening §6–7 is a **deliberate future decision**, valid only if the accepted debt is disposed or
  the terminal contract is relaxed. Until then, absence of schedule evidence is the expected steady
  state — never authority to dispatch, rerun, close a PR, or publish.

- At v2.7's close, repository hygiene was policy-blocked by open PRs accepted as operational debt; that
  count is not snapshotted here because it changes independently of this file — run
  `mix mailglass.repo.hygiene --check` or `gh pr list --state open` for the current figure. Legacy
  quick tasks stay outside v2.7, and no PR closure, tag push, branch deletion, workflow dispatch or
  rerun, merge bypass, release, or publication is authorized by this record.

## Performance Metrics

**Velocity:**

- Total plans completed: 147
- Average duration: 14m
- Total execution time: 72m

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 161. Canonical Workspace and Evidence Preservation | 5 | 72m | 14m |
| 162. Protected Release and Scheduled-Control Recovery | 13 | — | — |
| 163. Deterministic Release-Path Timeout Repairs | 8 | — | — |
| 164. Repository Truth Reconciliation and Closeout | 44 | — | — |
| 165 | 5 | - | - |
| 167 | 4 | - | - |
| 168 | 10 | - | - |
| 170 | 8 | - | - |
| 171 | 4 | - | - |
| 172 | 3 | - | - |
| 173.1 | 5 | - | - |
| 174 | 6 | - | - |
| 175 | 6 | - | - |
| 176 | 15 | - | - |
| 177 | 11 | - | - |
**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 161 P01 | 12m | 2 tasks | 2 files |
| Phase 161 P02 | 24m | 2 tasks | 2 files |
| Phase 161 P03 | 12m | 2 tasks | 3 files |
| Phase 161 P04 | 20m | 2 tasks | 2 files |
| Phase 161 P05 | 4m | 1 tasks | 2 files |
| Phase 162-protected-release-and-scheduled-control-recovery P01 | 5min | 2 tasks | 3 files |
| Phase 162-protected-release-and-scheduled-control-recovery P02 | 9m | 1 tasks | 2 files |
| Phase 162-protected-release-and-scheduled-control-recovery P03 | 4m | 2 tasks | 3 files |
| Phase 162 P04 | 4m | 1 tasks | 2 files |
| Phase 162 P05 | 45min | 2 tasks | 3 files |
| Phase 162-protected-release-and-scheduled-control-recovery P06 | 8m | 1 tasks | 2 files |
| Phase 162-protected-release-and-scheduled-control-recovery P07 | 16m | 1 tasks | 2 files |
| Phase 162 P08 | 15m | 1 tasks | 2 files |
| Phase 162 P09 | 5min | 1 tasks | 2 files |
| Phase 162-protected-release-and-scheduled-control-recovery P10 | 4m | 1 tasks | 2 files |
| Phase 162 P11 | 3m | 1 tasks | 2 files |
| Phase 162 P12 | 8m | 1 tasks | 2 files |
| Phase 162 P13 | 4min | 1 tasks | 2 files |
| Phase 163 P01 | blocked close-out | 1 task | 2 files |
| Phase 163 P02 | 5m | 1 task | 3 files |
| Phase 163 P03 | blocked close-out | 0 tasks | 1 file |
| Phase 163 P04 | continuation | 3 tasks | 8 files |
| Phase 163 P05 | continuation | 3 tasks | 8 files |
| Phase 163 P06 | 8m | 2 tasks | 5 files |
| Phase 163 P07 | protected wait | 1 task | 1 file |
| Phase 163 P08 | 8m | 2 tasks | 7 files |
| Phase 164 P01 | 4m | 1 tasks | 3 files |
| Phase 164-repository-truth-reconciliation-and-closeout P02 | 3m | 1 tasks | 2 files |
| Phase 164-repository-truth-reconciliation-and-closeout P03 | 3m | 1 tasks | 4 files |
| Phase 164 P04 | 8m | 1 tasks | 2 files |
| Phase 164 P05 | 9m | 2 tasks | 3 files |
| Phase 164 P06 | 1m | 1 tasks | 1 files |
| Phase 164 P07 | 4m | 1 tasks | 1 files |
| Phase 164 P08 | 4m | 2 tasks | 3 files |
| Phase 164 P09 | 5m | 2 tasks | 3 files |
| Phase 164 P12 | 15m | 1 tasks | 3 files |
| Phase 164 P13 | 6min | 2 tasks | 2 files |
| Phase 164 P14 | 7min | 1 tasks | 1 files |
| Phase 164 P15 | 18min | 3 tasks | 9 files |
| Phase 164 P16 | 3min | 1 tasks | 2 files |
| Phase 164 P17 | 13min | 2 tasks | 4 files |
| Phase 164 P18 | 15min | 1 tasks | 2 files |
| Phase 164 P19 | 24min | 2 tasks | 5 files |
| Phase 164 P20 | 7min | 1 tasks | 2 files |
| Phase 164 P21 | 22min | 2 tasks | 5 files |
| Phase 164 P22 | 6min | 2 tasks | 10 files |
| Phase 164 P23 | 6min | 3 tasks | 4 files |
| Phase 164-repository-truth-reconciliation-and-closeout P24 | 21min | 2 tasks | 10 files |
| Phase 164 P25 | 13min | 2 tasks | 7 files |
| Phase 164 P26 | 10min | 2 tasks | 3 files |
| Phase 164 P27 | 4min | 3 tasks | 7 files |
| Phase 164 P28 | 23min | 2 tasks | 9 files |
| Phase 164 P29 | 15min | 2 tasks | 4 files |
| Phase 164 P30 | 11min | 2 tasks | 3 files |
| Phase 164-repository-truth-reconciliation-and-closeout P31 | 16min | 2 tasks | 4 files |
| Phase 164 P32 | 34min | 2 tasks | 5 files |
| Phase 164 P33 | 17min | 2 tasks | 5 files |
| Phase 164 P34 | 25min | 2 tasks | 8 files |
| Phase 164 P35 | 34m | 2 tasks | 9 files |
| Phase 164 P36 | 95m | 1 tasks | 2 files |
| Phase 164 P40 | 7m | 2 tasks | 2 files |
| Phase 164 P42 | 36m | 2 tasks | 1 files |
| Phase 164 P43 | 4m | 2 tasks | 2 files |
| Phase 164 P41 | 9m | 2 tasks | 2 files |
| Phase 164 P44 | 25m | 2 tasks | 5 files |
| Phase 165 P01 | 61m | 2 tasks | 10 files |
| Phase 165 P02 | 117m | 2 tasks | 4 files |
| Phase 165 P03 | 4m | 2 tasks | 4 files |
| Phase 165 P04 | 8m | 2 tasks | 1 files |
| Phase 165 P05 | 25m | 2 tasks | 4 files |
| Phase 166 P01 | 24min | 3 tasks | 5 files |
| Phase 166 P02 | 15min | 2 tasks | 2 files |
| Phase 166 P03 | 4min | 4 tasks | 2 files |
| Phase 166 P04 | 6m | 2 tasks | 4 files |
| Phase 166 P05 | 55min | 2 tasks | 5 files |
| Phase 166 P06 | 55min | 2 tasks | 6 files |
| Phase 167 P01 | 25min | 3 tasks | 3 files |
| Phase 167 P04 | 12m | 3 tasks | 5 files |
| Phase 167 P02 | 20min | 2 tasks | 4 files |
| Phase 167 P03 | 15min | 3 tasks | 8 files |
| Phase 167.1 P01 | 24m | 3 tasks | 2 files |
| Phase 167.1 P02 | 12min | 2 tasks | 2 files |
| Phase 168 P1 | 48 | 3 tasks | 26 files |
| Phase 168 P02 | 53m | 3 tasks | 34 files |
| Phase 168 P03 | 5 min | 2 tasks | 8 files |
| Phase 168 P04 | 60min | 3 tasks | 22 files |
| Phase 169 P01 | 24m | 3 tasks | 31 files |
| Phase 169 P02 | 24m | 2 tasks | 9 files |
| Phase 169 P03 | 21m | 3 tasks | 16 files |
| Phase 169 P04 | 22m | 2 tasks | 17 files |
| Phase 169 P05 | ~2h 25m | 2 tasks | 35 files |
| Phase 168 P05 | 16min | 1 tasks | 2 files |
| Phase 168 P10 | 6m | 2 tasks | 11 files |
| Phase 170 P01 | 16 min | 2 tasks | 5 files |
| Phase 170 P02 | 11 min | 2 tasks | 11 files |
| Phase 170 P03 | 8 min | 2 tasks | 4 files |
| Phase 170 P04 | 8 min | 2 tasks | 4 files |
| Phase 170 P05 | 13min | 2 tasks | 15 files |
| Phase 170 P06 | 15min | 2 tasks | 10 files |
| Phase 170 P07 | 6m | 2 tasks | 3 files |
| Phase 170 P08 | 82m | 2 tasks | 17 files |
| Phase 171 P01 | 14m | 2 tasks | 7 files |
| Phase 171 P02 | 13min | 2 tasks | 5 files |
| Phase 171 P03 | 17min | 2 tasks | 6 files |
| Phase 171 P04 | 25min | 2 tasks | 16 files |
| Phase 172 P02 | 8min | 3 tasks | 8 files |
| Phase 172 P03 | 9min | 3 tasks | 8 files |
| Phase 173 P05 | 27min | 2 tasks | 13 files |
| Phase 173 P06 | 7m | 1 tasks | 2 files |
| Phase 173 P07 | 21min | 2 tasks | 16 files |
| Phase 173 P08 | 32min | 2 tasks | 4 files |
| Phase 174 P01 | 25min | 2 tasks | 6 files |
| Phase 174 P02 | 26m | 2 tasks | 10 files |
| Phase 174 P03 | 31min | 2 tasks | 7 files |
| Phase 174 P04 | 33m43s | 2 tasks | 10 files |
| Phase 174 P05 | 86m | 3 tasks | 17 files |
| Phase 174 P06 | 4h29m | 2 tasks | 24 files |
| Phase 175 P01 | 23m | 2 tasks | 11 files |
| Phase 175 P02 | 21min | 2 tasks | 8 files |
| Phase 175 P03 | ~29m (approximate) | 3 tasks | 13 files |
| Phase 175 P04 | 30min | 2 tasks | 8 files |
| Phase 175 P05 | 19min 22s | 2 tasks | 18 files |
| Phase 175 P06 | 121m | 3 tasks | 180 files |
| Phase 176 P01 | 12 min | 3 tasks | 6 files |
| Phase 176 P02 | 10 min | 3 tasks | 8 files |
| Phase 176 P03 | 14min | 2 tasks | 10 files |
| Phase 176 P04 | 10 min | 3 tasks | 7 files |
| Phase 176 P05 | 14 min | 2 tasks | 6 files |
| Phase 176 P06 | 16 min | 2 tasks | 7 files |
| Phase 176 P07 | 40 min | 3 tasks | 7 files |
| Phase 176 P08 | 25 min | 3 tasks | 6 files |
| Phase 176 P09 | 15 min | 3 tasks | 4 files |
| Phase 176 P10 | 35 min | 4 tasks | 9 files |
| Phase 176 P11 | 6 min | 2 tasks | 6 files |
| Phase 176 P12 | 10 min | 2 tasks | 8 files |
| Phase 176 P13 | 25min | 3 tasks | 3 files |
| Phase 176 P15 | 9 min | 2 tasks | 8 files |
| Phase 176 P14 | 25 min | 2 tasks | 3 files |
| Phase 177 P01 | 6 min | 3 tasks | 11 files |
| Phase 177 P02 | 25min | 2 tasks | 2 files |
| Phase 177 P03 | 20min | 3 tasks | 6 files |
| Phase 177 P04 | 45min | 2 tasks | 8 files |
| Phase 177 P05 | 25 min | 2 tasks | 8 files |
| Phase 177 P10 | 20 min | 2 tasks | 5 files |
| Phase 177 P06 | 10 min | 3 tasks | 10 files |
| Phase 177 P07 | 25 min | 3 tasks | 8 files |
| Phase 177 P08 | 18 min | 3 tasks | 3 files |
| Phase 177 P09 | 40min | 3 tasks | 8 files |
| Phase 177 P11 | 45 min | 3 tasks | 6 files |
| Phase 178 P01 | 7 min | 2 tasks | 5 files |
| Phase 178 P02 | 6 min | 2 tasks | 5 files |
| Phase 178 P03 | 9 min | 3 tasks | 5 files |
| Phase 178 P12 | 12 min | 2 tasks | 1 files |

## Accumulated Context

### Pending Todos

(none)

### Roadmap Evolution

- Phase 165 added: Reconcile terminal proof and milestone archive ordering
- Phase 167.1 inserted after Phase 167: Close gap: CTRL-02/CTRL-03 — proposal control cannot produce evidence when should_run=false (URGENT)
- Phase 173.1 inserted after Phase 173: Address tech debt: demo auth + browser evidence (from v2.9-MILESTONE-AUDIT.md) (URGENT)

### Decisions

- v2.7 is evidence-first, bounded maintenance: no product/API/schema/UI work, dependency churn, CI-efficiency redesign, speculative architecture, or forced release.
- Preserve and inventory workspace/release state before cleanup; reconcile immutable release facts before scheduled-control recovery; repair observed timeouts only at their narrow seams; complete documentation/artifact truth last.
- A manual dispatch does not substitute for applicable observed scheduled-run evidence; unavailable automation must report an honest blocked or cannot-check outcome.
- [Phase 161]: Canonical `main` is clean but remains non-release-clean until Phase 162 settles upstream drift; historical captures stay immutable and current-state corrections append.
- [Phase 161]: Dirty, detached, stash, release, and unreachable evidence remains preserved unless content- and graph-aware review proves a safe action.
- [Phase 161]: All 12 archive identities have independent named preservation refs; the verified cleanup queue had no eligible `remove` row.
- [Phase 161]: WT-03 dirty publish-summary evidence remains retained; Phase 162 owns release interpretation.
- [Phase 161]: Workspace/evidence verification is automated through the live Git auditor and disposable-repository CI contracts; 15/15 UAT checks require no human review.
- [Phase 162]: PR #222 remains retained only for a future exact candidate-digest protected dispatch; its live head and authorized ledger candidate are distinct identities.
- [Phase 162]: Only a fresh exact repository-admin response authorizes protected release steps; ordinary push, schedule, and empty-digest dispatch paths remain proposal-only.
- [Phase 162]: External GitHub bytes require decode and list-shape validation; unavailable evidence is `cannot-check`, and summaries consume the same persisted result as retained artifacts.
- [Phase 162]: Scheduled-control UAT binds event, run, and workflow SHA to protected `main`; all three current-main evidence chains verified on 2026-08-26 without manual substitution.
- [Phase 163]: Bounded non-reproduction of the historical database cancellation authorizes no speculative repair; the existing deterministic lane now captures the next structured recurrence automatically.
- [Phase 163]: Protected recurrence evidence selected finite exact-owner bounds: 240 seconds for the complete gallery, 60 seconds for four structural test bodies, and 20 minutes for browser-only sandbox ownership; global timeout, retry, worker, and job policy remain unchanged.
- [Phase 163]: Human UAT is removed from timeout proof; local integration and normally triggered exact-SHA protected jobs are the release-path authority.
- [Phase 163]: Normal PR run 33002642359 passed Core Deterministic and Operator Browser at exact final repair SHA f8bf029f; all four DTRM requirements and Nyquist validation are complete.
- [Phase ?]: D-08 removes only the verified stale root sweep and retains Phase 162 proof as the durable source.
- [Phase ?]: Disposition rows require a complete twelve-column schema, unique subjects, and a closed disposition enum.
- [Phase ?]: MAINTAINING.md now projects executable protected-release authority; Phase 38/73 procedures are historical provenance only.
- [Phase ?]: Current package compatibility guidance is scoped in each README and derives expected major.minor values from package manifests.
- [Phase ?]: Historical and upgrade-bounded version evidence remains untouched.
- [Phase ?]: Repository-truth audit scope derives from committed ignore rules, Git-tracked proof, and Phase 164 plan files.
- [Phase ?]: Closeout remains read-only and writes volatile report evidence under the existing ignored tmp/ rule.
- [Phase ?]: A quiet verdict requires exact main, exact successful CI, current provenance-valid controls, and a valid exact-one ledger.
- [Phase ?]: Plan 164-07 must re-query protected main SHA 00bce87d77ce9d8a74ad0f42de5d8ce71ef054fb and CI run 33020041269; no manual substitute is accepted.
- [Phase ?]: Closeout accepts only exact protected-main identity, normally triggered push CI, and current provenance-valid scheduled evidence.
- [Phase ?]: The final report remains ignored runtime evidence rather than a self-invalidating tracked snapshot.
- [Phase ?]: Exact currentness is an enum; stale context belongs in rationale rather than the enum field.
- [Phase ?]: The repository-truth inventory derives from committed ignore rules, tracked proof, Phase 164 plans, and verification evidence.
- [Phase ?]: Closeout accepts only the physical canonical repository, Phase 164 ledger, and ignored tmp output boundary.
- [Phase ?]: The shared full-ledger validator, rather than a local partial parser, decides ledger validity.
- [Phase 164]: Pre-verification proves implementation behavior at protected-main SHA 382ebb0a33ad12d8bb11cc67fa4ef9a943b37a9d; Plan 164-12 metadata intentionally makes it non-terminal without changing implementation behavior. — Ordinary verification needs non-circular implementation evidence before tracked completion metadata, while terminal proof must bind the later exact SHA.
- [Phase 164]: Independent raw-source verification corrected only the CI jq grouping defect and retained every other attempt-one provenance criterion. — The plan intended to compare the stringified databaseId to the selected run; parentheses restore that meaning without weakening evidence authority.
- [Phase 164]: Production behavior remains unchanged; Plan 164-13 locks the existing validator and closeout seams through named hostile fixtures. — The gap was missing explicit rerunnable regression coverage, not a remaining production defect.
- [Phase 164]: Late-dirt regressions inject untracked state at exact stable-porcelain boundaries. — This proves a clean preflight observation cannot override dirty state introduced by component or report writes.
- [Phase 164]: Pre-verification passed at protected-main SHA d903b040c72fff62a69a57cacbcc7e7d7c2f6167; tracked completion metadata makes this capture non-terminal. — Terminal proof must be regenerated only after the refreshed verifier and all completion metadata reach protected main.
- [Phase 164]: Natural attempt-one scheduled failures count only through evidence-valid policy-blocked artifacts. — No dispatch, rerun, authority change, or alternate identity may manufacture closeout evidence.
- [Phase 164]: Terminal authority inspects every commit after verified_implementation_sha relative to its first parent, preserving forbidden change-then-revert history without traversing unrelated second-parent history.
- [Phase 164]: Scheduled freshness is the closed interval from zero through each tracked registry maximum; malformed and negative ages have no clock-skew exception.
- [Phase 164]: Out-of-root hostile fixtures are recursively removed only while exclusive allocation, lstat identity, resolved parent, exact basename, and invocation token all remain valid.
- [Phase 164]: Current bus-factor guidance binds release progress to the protected exact-candidate dispatch and fresh exact repository-admin authorization; green gates alone grant no authority. — This keeps all current-facing maintainer prose aligned with the executable protected workflow.
- [Phase 164]: The original v0.1/v0.5 hands-free rationale remains discoverable only after the exact Historical release procedures boundary. — Historical provenance stays available without reading as a second current runbook.
- [Phase 164]: Tracked ledger state now requires a regular file plus one exact literal-pathspec Git-index return equal to the subject.
- [Phase 164]: Finalize-phase authenticates both executable links and runs only a mode-0500 private downstream HEAD materialization removed in finally.
- [Phase 164]: Tracked proof requires one exact NUL-delimited stage-0 Git-index record. — Nonzero, additional, malformed, or byte-mismatched staged records cannot establish tracked repository identity.
- [Phase 164]: The project-local command supports only Phase 164 and rejects every other positive phase before repository discovery because no other phase has an authenticated downstream mapping.
- [Phase 164]: All finalization code and data is authenticated and fully materialized before Bash; the live checkout remains authoritative only for Git, GitHub, ignored-output, and repository-identity observations.
- [Phase 164]: Validation records name the repaired production seams and preserve observed non-vacuous results. — The final proof map must describe the behavior delivered by Plans 164-18 and 164-19 rather than retain Plan-17-era closure claims.
- [Phase 164]: Terminal finalization remains pending after ordinary verification and protected completion-metadata integration. — Plan 164-20 reconciles tracked documentation only and does not substitute test evidence for the separately governed exact-main terminal capture.
- [Phase 164]: The standalone loader captures one full HEAD commit OID, uses it for every tree/blob authority operation, rechecks HEAD immediately before dispatch, and executes only privately materialized authenticated bytes. — Mutable checkout bytes cannot establish or replace repository finalization authority.
- [Phase 164]: Phase 164 terminal history is the explicit 48-path PLAN/SUMMARY set for 01 through 24; later plans must deliberately update both loader and shell constants. — Completeness must not shrink when either member of a numbered pair disappears.
- [Phase 164]: Repository-truth inventory considers completed plan declarations. — Unexecuted future plans and their external installation paths are not current audited subjects.
- [Phase 164]: The installed /Users/jon/.local/bin/mailglass-finalize-phase executable is the sole current Phase 164 verdict entry point; the removed project-local slash command is historical provenance only. — This removes checkout evaluation from the trust root while preserving explicit implementation history.
- [Phase 164]: Retired extension subjects remain exact ledger identities with historical remove dispositions and explicit replacement evidence naming scripts/mailglass_finalize_phase_loader.mjs. — Executable removal must preserve audit identity, origin, and current replacement authority.
- [Phase 164]: Human approval authorized only the exact persisted absent-destination installation tuple. — Any change in source OID, digest, destination, mode, or prior-object disposition invalidates authorization before mutation.
- [Phase 164]: The installed loader remains bound to the approved source OID while rollback is inapplicable for the absent destination. — The exact approved committed bytes were atomically installed at mode 0500 and both version and self-check probes passed.
- [Phase 164]: Installed-boundary tests authenticate the immutable Plan 164-23 approval tuple before direct subprocess attacks and never import the retired checkout extension. — This makes the actually installed command, not a test-local import, the production authority under test.
- [Phase 164]: Plan 164-24 records automated production-boundary proof only; terminal finalization remains pending. — Ordinary verification and protected completion-metadata integration remain separately ordered lifecycle events.
- [Phase 164]: The generic required lane retains test/scripts directory discovery and excludes exactly phase_164_installed_production_boundary; no workflow or required-lane topology changes are needed. — Protected CI must use only tracked repository state while preserving all fixture-backed contracts.
- [Phase 164]: Installed-host assertions remain fail-closed under one explicit preferred-test-environment alias and are never treated as repository-runner evidence. — Fixture-backed and installed-host groups are distinct execution authorities and neither substitutes for the other.
- [Phase 164]: Production finalization selects only /Users/jon/projects/mailglass with normalized origin szTheory/mailglass before dependency enumeration.
- [Phase 164]: Finalization validates absolute Node, Git, Bash, gh, jq, Mix, and Elixir identities and passes an allowlisted child environment with reconstructed PATH.
- [Phase 164]: Phase 164 terminal history is the exact PLAN/SUMMARY pair set 01 through 28.
- [Phase 164]: Human approval authorized only source OID 2c7cf25c4ac004df3f960a5e8cb37cf8aef68c97 and its complete source-bound replacement tuple; every repository, tool, prior-object, and rollback field was revalidated before mutation.
- [Phase 164]: The superseded ca760f78 loader remains recoverable as a private digest-addressed mode-0400 object, while the operational command is now the approved 0dbcc034 hardened loader.
- [Phase 164]: Installation readiness was proven without invoking canonical pre-verification or terminal finalization; protected lifecycle ordering remains unchanged.
- [Phase 164]: Plans 164-25 through 164-27 close the four implementation findings; T-164-109 and terminal protected-main evidence remain pending.
- [Phase 164]: The authorized terminal history is exactly one PLAN and SUMMARY for every number 01 through 28.
- [Phase 164]: Plan 164-28 stops after summary readiness; ordinary verification and terminal finalization remain later ordered boundaries.
- [Phase 164]: Plan 164-27 remains the single installed authority tuple; approval bytes are parsed as data and matched field-for-field before installed execution.
- [Phase 164]: The controlled-host tag is excluded by test_helper on every schema axis and is re-enabled only by the exact named --only alias.
- [Phase 164]: Disposable loader attacks remain repository-only tests and discover Node through the active test environment rather than a version-specific launcher.
- [Phase 164]: Authority ignore subjects now use declared-order lstat and non-raising reads, returning missing_authority_subject for absent/non-regular inputs and unreadable_authority_subject only for regular-file read failures.
- [Phase 164]: Plan 164-29 test/test_helper.exs is exact-one ledger subject M-34 so completed-plan discovery remains canonical after summary activation.
- [Phase 164]: Phase 164 terminal history remains one singular exact PLAN/SUMMARY pair set; its explicit authenticated bound advances from 28 to 34. — Exact numeric source constants, not globs or planning prose, define terminal membership.
- [Phase 164]: The Plan 164-27 installation is preserved prior proof but is superseded-pending until Plans 164-32 and 164-33 approve and install the changed loader bytes. — Tracked byte drift invalidates current installed readiness without rewriting prior provenance.
- [Phase 164]: Human approval authorized only source OID 1cfee7802de808f690fe5413b22a57e7ab802488 and its complete Plan 164-32 tuple; every bound identity was revalidated immediately before and after approval publication.
- [Phase 164]: Plan 164-32 records approval only; the Plan 164-27 installed loader and absent rollback target remain unchanged until Plan 164-33.
- [Phase 164]: Plan 164-33 consumed only the complete immutable Plan 164-32 approval tuple; path authority did not extend to future source or lifecycle actions.
- [Phase 164]: Plan 164-27 bytes remain recoverable only through the exact private mode-0400 digest-addressed rollback; they are not a second active authority.
- [Phase 164]: Controlled-host assertions remain isolated in the installed-boundary alias while disposable repository attacks remain repository-only.
- [Phase 164]: TRTH-03, Phase 164 completion, protected-main integration, and terminal finalization remain pending after Plan 164-33.
- [Phase 164]: Repository-only CI, controlled-host installation readiness, ordinary verification, protected completion metadata, exact-main remote evidence, and terminal capture remain separate ordered authorities.
- [Phase 164]: The active installed authority is the exact Plan 164-32 tuple proven by Plan 164-33; Plan 164-27 remains immutable prior provenance only.
- [Phase 164]: Plan 164-34 completes execute-plan reconciliation without completing TRTH-01/02/03 or Phase 164; T-164-109 and terminal no-later-write evidence remain pending.
- [Phase 164]: Finalization runtime authority is the versioned physical Elixir 1.19.5 and Erlang 28 closure, not asdf shims or inherited ASDF selectors. — The exact sanitized child environment must execute every authenticated runtime member before Bash dispatch.
- [Phase 164]: The Node-authenticated commit remains immutable data through finalizer and closeout. — Every later repository observation validates the captured OID rather than recapturing or substituting authority.
- [Phase 164]: Proposal and installed-host test groups remain outside repository-only CI behind dedicated non-vacuous aliases. — Repository evidence, human approval, and controlled-host proof are distinct authorities.
- [Phase 164]: Tracked ledger subjects require lstat regular worktree entries before Git-index identity is evaluated. — This prevents symlink targets and every other non-regular entry type from becoming repository truth.
- [Phase 164]: Exact-one stage-0 Git records are accepted only in modes 100644 and 100755. — Structurally valid non-regular objects receive a stable invalid-index-mode failure after exact identity is established.
- [Phase 164]: Repository-only attacks authenticate and dispatch exclusively inside disposable canonical repositories; controlled-host proof remains separate.
- [Phase 164]: Disposable fixtures bind origin/main to current HEAD or its predecessor to prove ahead counts zero and one explicitly.
- [Phase 164]: Plan 164-37 is the current approval authority and Plan 164-38 is the current installed-loader authority.
- [Phase 164]: Plan 164-23 remains only as superseded earlier-generation installation provenance inside the historical boundary.
- [Phase 164]: Completed-plan artifact discovery accepts an empty list only for a standalone explicit files_modified: [] declaration; every missing or malformed shape fails with a stable tag.
- [Phase 164]: repo_root must prove Git work-tree identity before ls-files, while authority_root remains a directory-only policy fixture boundary.
- [Phase 164]: Completed Plans 164-40 through 164-43 contribute provenance only through structurally declared modified subjects, each resolving to exactly one current complete ledger row.
- [Phase 164]: Fresh repository-only and controlled-host results remain separate ordinary authorities; T-164-109 stays open until the terminal lifecycle completes.
- [Phase 165]: Phase 165 terminal authority uses a separately staged v2.7 loader/finalizer and leaves the Phase 164 pair byte-identical.
- [Phase 165]: Installed-host proof remains opt-in and excluded from repository CI; repository fixtures authenticate and execute staged bytes only.
- [Phase 165]: Phase 161 Plan 04 owns WSPC-01, WSPC-03, and WSPC-04 completion claims; WSPC-02 remains owned by Plan 05.
- [Phase 165]: Canonical validation refreshes retain historical green evidence while adding current workflow audit trails; they do not reinterpret Phase 164 terminal authority.
- [Phase 165]: Phase 164 terminal evidence remains immutable successful history; Phase 165 owns the separate pre-archive reconciliation and eventual archived-v2.7 terminal authority. — Live lifecycle ledgers must not treat the completed Phase 164 proof as current milestone authority.
- [Phase 165]: The v2.7 lifecycle remains exactly Phases 161-165 with the same 16 requirements, accepted 14-PR debt, and no legacy quick-task attribution. — D-09 through D-11 preserve scope and evidence-backed debt without inventing new ownership.
- [Phase 165]: state.json is generated only by publishStateContract, with a second publication required after final archive-related Markdown edits. — Machine state must derive from the final human-authored lifecycle sources at both pre-archive and post-archive boundaries.
- [Phase 165]: Plan 165-04 approved an absent/create predecessor with no backup and a guarded remove_created rollback bound to regular-file type, mode 0500, and the approved digest.
- [Phase 165]: Plan 165-04 used same-filesystem atomic no-overwrite publication so a raced destination cannot be replaced beyond the approved tuple.
- [Phase 165]: Plan 165-04 proved installed readiness only; the v2.7 terminal invocation remains ordered after archive and protected evidence gates.
- [Phase 165]: Canonical milestone audit and archive begin only after execute-phase returns with passed ordinary verification and completion metadata.
- [Phase 165]: The archive checkpoint binds a fresh exact preview while scoped git.create_tag=false is restored byte-for-byte before convergence.
- [Phase 165]: Final state publication and commit precede protected exact-SHA evidence and the one permitted installed terminal invocation.
- [Phase 166]: GREEN-01/GREEN-02: widened verify.support_contract.admin to directory-scoped run (325 newly-executed tests) and wired a measured ExCoveralls coverage floor for mailglass_admin, demonstrated (not asserted) to fire on regression.
- [Phase 166]: GREEN-03: enforced the anti-vacuity suite floor on the required core_deterministic_suite lane by setting MAILGLASS_SUITE_FLOOR: "1" in ci.yml, guarded by a new occurrence-count drift test mirroring the advisory-matrix.yml trio; no floor constants were re-pinned (measured 2134 executed vs 1576 floor, 7 skipped == 7 ceiling).
- [Phase 166]: Clock-proof: faketime does not intercept the BEAM clock on this toolchain (macOS SIP strips DYLD_INSERT_LIBRARIES); maintainer accepted the fallback evidence (real un-faked audit run + committed date-boundary test) as satisfying CTRL-04's clock-fake clause.
- [Phase 166]: lib/ exemption confirmed by maintainer: accepted_advisories.ex data-only edit (recheck_by + reason text) is CTRL-04's named exemption to the milestone's no-product-code-changes constraint (D-31).
- [Phase 166]: recheck_by: ~D[2027-03-17] confirmed as the standing decision for both cowlib advisory entries (D-30), with named falsifiable re-check for next cycle.
- [Phase 166]: CTRL-02/CTRL-03 code changes (release-please early-return deletion + bounded classify-and-retry) are implemented and merged, but their acceptance criteria are post-merge observations (a green push run at an already-tagged SHA; three consecutive agreeing push/schedule runs). Carried as explicitly pending evidence per D-37 — not marked complete — until 166-05/166-06 or Phase 167 merges naturally supply the observations.
- [Phase 166]: D-20's release-please.yml line citations (:119/:179) are stale; the semantic clause (the gh api calls that already classify to cannot-check) governs. Verified the two gh pr list calls at lines 572/684 are the correct and only wrap targets; maintainer confirmed this reading.
- [Phase 166]: 166-05: GREEN-04 isolation uses an rsync scratch copy with default paths, not MIX_DEPS_PATH/MIX_BUILD_PATH (broke cowlib's erlang.mk build) or a new CI job (requires lane-registry registration). — Both prior-executor blockers resolved by orchestrator and re-verified locally before implementation.
- [Phase 166]: 166-05: reference/demo_app/mix.lock's three mailglass sibling entries refreshed to the published 2.6.0/2.6.0/2.3.0 line so GREEN-04's hex build can compile (frozen 2.0.0 lock predates mailglass_admin's :navigation dependency). — mix.exs ~> 2.0 constraints already permit this; only the lock was stale.
- [Phase ?]: CTRL-01: post-publish-smoke resolves an inactive ledger's published baseline via a new baseline-versions verb + ledger-status peek; distinct cron-guard baseline output never reuses completed=true
- [Phase ?]: CTRL-05: repo-hygiene cannot_check exits a distinct nonzero code from blocked; PR predicate widened to open >14d (day-granularity) OR failing required check
- [Phase ?]: [Phase 167]: MAINTAINING.md's exclude-paths count is derived from release-please-config.json at test time (count_word!/1 1..30 map), never a second hardcoded literal — proven via a live mutation.
- [Phase ?]: [Phase 167]: MAINTAINING.md/CONTRIBUTING.md publish-fan-out and sibling-pin claims corrected (required_reviewers gate named explicitly, bare ~> 2.0 sibling constraint replaces the stale fix(inbound) floor-bump instruction).
- [Phase ?]: [Phase 167]: New MAINTAINING.md ## Release Close-Out runbook added and pinned with File.exists?/1 over every scripts/*.sh|.exs path it names, proven via a rename-and-revert mutation.
- [Phase ?]: [Phase 167]: DOCS-01/STAND-01 — STATE.md's ongoing PR/issue state is delegated to a live gh audit script (scripts/check_state_md_pr_refs.sh) and pinned offline by refusing the shape of a hardcoded open-count claim, not by asserting today's count; the three mix Dependabot entries are grouped (minor+patch) and carry an `open-pull-requests-limit` of 3, with majors and security-updates left individually reviewable.
- [Phase ?]: [Phase 167]: CLAUDE.md's sibling-pin/auto-merge release-mechanics claims corrected (bare ~> + linked-versions replaces the stale == pin; disarmed-auto-merge + protected candidate-digest dispatch replaces the false auto-merges-on-green claim); README.md links guides/upgrading-to-v2_0.md (wildcard-generalized); CHANGELOG.md's 2.0.0 section additively names the Phases 132-137 schema-isolation move.
- [Phase ?]: [Phase 167]: DOCS-04's migration-guide version lockstep dissolved permanently (not re-tightened) — the guide's ~> X.Y pin joins release-please.yml's existing pin-resync sed loop + SYNC_PATHS, and docs_contract_test.exs asserts it dynamically via package_major_minor!/dependency_constraint!, mirroring the README contract test.
- [Phase ?]: [Phase 167]: DOCS-05's css_inliner: :none rejected at validation (not honored) per the milestone's single-permitted-lib-change pre-authorization — the key validated but had zero effect and zero adopter-facing documentation; NimbleOptions now raises naming :premailex.
- [Phase ?]: [Phase 167]: DOCS-05's outbound.ex moduledoc and api_stability.md injected-forms list corrected against source (Reconciler resolves orphan webhook Events, not orphan :queued Deliveries; the actual Mailglass.Message import/new(assigns \\ [])/defoverridable new: 1 replace three wrong claims), both pinned by source-coupled ExUnit assertions rather than proofread.
- [Phase ?]: [Phase 167.1]: D-05 widening added exactly one new admissible pass pair (pending / proposal_awaiting_release_action) to release-please.yml's twin predicates -- a positive observation reachable only after gh pr list succeeded and exactly one open proposal was counted; capture-proposal's should_run gate left byte-identical so an un-gated discovery can never validate a pre-sibling-sync digest.
- [Phase ?]: [Phase 167.1]: CTRL-02/CTRL-03's structural block is closed (167.1-01 merged the code fix), but both requirements' Accept clauses are post-merge observations this plan cannot produce -- they remain evidence-pending, not complete. Plan 02 owns the harvest.
- [Phase ?]: CTRL-02/CTRL-03 requirement prose corrected to name the measured conflated-should_run-flag mechanism (D-06); both Accept clauses left byte-identical
- [Phase 168]: Keep tenant_id as the URL and filter-submission scope; remove duplicate Account filter selection.
- [Phase 168]: Keep selected Account identity and scope switching in shared operator chrome; keep Preview outside production Account scope.
- [Phase 168]: Preserve host-owned tenant resolution and authorization; Account option links are navigation aids only.
- [Phase 168, superseded by Phase 169]: Health now uses the approved two-column arrangement and one column below 768px; the earlier three-column decision is historical.
- [Phase 168]: Filter submit busy labels use fixed-width buttons to preserve action position.
- [Phase 168]: Stale/unavailable Delivery states use approved recovery copy and never invent an observation time.
- [Phase 168]: Keep System, Light and Dark visible beside native radio controls and preserve the existing persisted preference.
- [Phase 168]: Use explicit alert/status live regions, exact UTC timestamp names and keyboard-accessible feedback dismissal.
- [Phase 168]: Render missing timestamps as Unavailable and never invent stale observation times.
- [Phase 168]: Quick view returns focus only to the stable row ID matching its URL-selected delivery.
- [Phase 168]: Gallery Flash specimens render inline so they cannot obscure other gallery controls.
- [Phase 168]: Replay request and replay completion remain distinct; missing evidence is labeled unavailable.
- [Phase 169]: Keep exact Delivery selection independent of the current page and time window.
- [Phase 169]: Retain compatible filters across Account switches while clearing page and object evidence IDs.
- [Phase 169]: Use content-column width for the table-to-card breakpoint.
- [Phase 169]: Keep the five Health populations independently readable with windowed evidence bound to one as-of instant; active suppressions remain current-at-read.
- [Phase 169]: Resolve exact Account webhook and Event IDs independently from Delivery list membership, and name a Delivery only when a unique persisted linkage exists.
- [Phase 169]: Keep exact support read functions documentation-hidden while exporting their module through the core boundary for Admin use.
- [Phase 169]: Show at most 100 chronological Events, detect overflow with row 101, and resolve selected Events independently by Account, Delivery, and Event.
- [Phase 169]: Keep exact recorded UTC values visible and make local time a separately labeled supplement.
- [Phase 169]: Present one current Mailglass suppression match separately from historical Events and Account-wide active-record totals.
- [Phase 169]: Freeze the selected webhook ID and material Account, Delivery, provider, receipt-time, and eligibility facts at review open.
- [Phase 169]: Re-read and compare the same target before host authorization; reject stale or replaced review without selecting a substitute.
- [Phase 169]: Use command-returned row counts for local outcomes and persisted audit reads only for terminal evidence.
- [Phase 169]: Do not expose raw audit metadata, actor identifiers, failure reasons, or exception bodies in operator feedback.
- [Phase 169]: Final Back to deliveries clears selected Delivery, full-detail mode, and exact support focus while preserving Account and committed list state, per the approved UI spec.
- [Phase 169]: Keep dev-gallery theme specimens stacked through tablet widths; use actual available content width for production collection layout.
- [Phase 169]: Terminal audit database write failure is trigger-tested at core and LiveView boundaries; safe failure feedback retains context while normalized writes roll back.
- [Phase 169]: Exact support records use neutral labels with current status and proven reconciliation linkage. Explicit new replay review refreshes candidates; private dialog correlation rejects old queued confirms.
- [Phase 168]: Keep Delivery technical identifiers intact and use browser-verified arbitrary wrapping to close the 320–1440px overflow gap.
- [Phase 168]: UXF-03: enforce the approved 4px spacing grid across seven shared operator, Inbound, and Preview templates with source, generated CSS, and rendered browser assertions.
- [Phase 168]: UXF-03 rendered spacing verification remains in the existing advisory operator-browser lane.
- [Phase 170]: Only literal :no_change callback results assert no mutation; ignore and failures stay distinct. — Execution history must preserve an authoritative callback fact without inferring state from unrelated outcomes.
- [Phase 170]: Only SES auth :sns_x509 is rendered as a fixed authentication fact; all other verification input is unavailable in ordinary evidence. — Provider maps can contain personal data, credentials, route bindings, exception text, and markup. An exact allowlist prevents arbitrary values from reaching ordinary HTML while retaining one source-backed safe fact.
- [Phase 170]: RoutingTrace is explicitly labeled as a simulation of the currently configured router. — Persisted ExecutionRun and durable route-binding records are historical facts. Current rules may change and cannot establish which route ran when the message arrived.
- [Phase 170]: The routing disclosure uses native HTML details and summary elements. — Browser-owned disclosure semantics keep keyboard operation and expanded state aligned with visibility without adding JavaScript or duplicating state in LiveView.
- [Phase 170]: Latest fresh disposition uses inserted_at descending with ExecutionRun ID descending as the tie-breaker. — A deterministic shared order keeps list and exact detail aligned when persisted runs have equal insertion timestamps.
- [Phase 170]: Keep :no_change distinct from :ignore in list, detail, filter, and timeline vocabulary.
- [Phase 170]: Map nil latest-fresh outcome to No history; reserve No match for literal :no_match.
- [Phase 170]: Omit free-form outcome_reason and failure metadata from the operator timeline.
- [Phase 170]: Tenant-scoped replay eligibility uses stored binding/history, never current-router matching. — Eligibility must explain the exact stored replay target without guessing or leaking raw evidence.
- [Phase 170]: A replay review is a short-lived snapshot, not an authorization token. — At confirmation, reread the selected tenant/record and eligibility, then use the existing host authorization immediately before replay.
- [Phase 170]: Replay consequence copy must name the recorded Mailbox and stored message behavior. — Operators must distinguish execution with current code from current-router simulation and provider redelivery.
- [Phase 170]: Replay review identifiers are consumed server side; busy wording describes only local in-flight work.
- [Phase 170]: Replay outcome feedback is derived from the returned structured result and remains separate from later timeline reads.
- [Phase 170]: Selected history is labeled through its last successful scoped read and refreshed through an explicit native control.
- [Phase 170]: Replay command feedback remains separate from the timestamped history snapshot; native Refresh history performs the next scoped timeline read.
- [Phase 170]: The deterministic browser fixture persists the same durable execution-route binding required by replay eligibility.
- [Phase 170]: Actual 200% zoom stacks shell actions and gives the evidence disclosure 44.1px minimum height for strict 44px acceptance.
- [Phase 170]: INUX-01 through INUX-04 remain unclassified/unresolved in the spec-less edge probe; no taxonomy was assigned.
- [Phase 171]: Display the full Mailable module path and scenario in the compact picker so narrow layouts retain the selected identity.
- [Phase 171]: Render discovery, missing-scenario, and discovery-error states separately with actionable copy for each.
- [Phase 171]: Describe Preview as Mailglass.Renderer output and keep route exposure under the host application's dev guard.
- [Phase 171]: Treat a valid empty preview_props/0 list as a missing-scenario setup state.
- [Phase 171]: Edit only text, integer, float, boolean, and calendar-valid Date defaults with complete, type-preserving parsers.
- [Phase 171]: Keep maps, structs, atoms, and timezone-sensitive DateTimes read-only with guidance to edit the Mailable scenario.
- [Phase 171]: Retain renderer artifacts only after success and label prior output as not current during pending, validation, and render errors.
- [Phase 171]: Retry through the existing render event and reset to the selected scenario defaults.
- [Phase 171]: Label Preview outputs by provenance and distinguish the shared Renderer stage from downstream preflight and delivery.
- [Phase 171]: Use manual-activation tabs so arrow-key focus remains local and does not send a LiveView event.
- [Phase 171]: Mount the script-disabled HTML iframe only while its panel is selected, with remote resource behavior documented.
- [Phase 171]: Label preview widths as CSS pixels, with concise visible values and complete accessible names.
- [Phase 171]: Keep controls stacked until the wide breakpoint and remove the spacing-token max-width that collapsed the selected identity.
- [Phase 171]: Treat preview browser screenshots as preview-pipeline evidence only, not recipient-client or email dark-mode certification.
- [Phase 172]: Keep Renderer.render/2 responsible for replacing text_body from rendered HTML while retaining the public setter.
- [Phase 172]: Use the existing Floki traversal and normalization; do not add a dependency or alternate MIME path.
- [Phase 172]: Valid GET remains informational and does not change subscription state.
- [Phase 172]: Fixed state atoms render failure copy without recipient or token assigns.
- [Phase 172]: Configured redirect applies to GET only; POST remains the mutation path.
- [Phase 173]: Evidence resets require a strict run-owned project identity plus the existing token.
- [Phase 173]: Only validated pinned baseline bytes and revalidated sanitized PNG pairs can enter candidate evidence.
- [Phase 173]: UIQ-03 remains Pending until required exact-SHA CI, clean acceptance inputs, local regression, and retained evidence all pass.
- [Phase 173]: Bind current browser and preview evidence to candidate SHA 3d6314bae62729b921b6ed7049adbda5181c5b64.
- [Phase 173]: Keep the retained preview and detached candidate available for owner review, with exact scoped cleanup commands recorded.
- [Phase 173]: Leave UIQ-03 incomplete until owner acceptance, full local gate proof and exact-SHA required CI Green are established.
- [Phase 173]: Use sparse exclusions before candidate materialization and exclude both protected inputs from Docker contexts.
- [Phase 173]: Install only lockfile-pinned Mix/npm dependencies in the detached candidate and restore only candidate-generated demo lock drift.
- [Phase 173]: Keep delivery incomplete until required exact-SHA CI Green and protected owner acceptance are verified.
- [Phase ?]: v2.10 reuses the supplied ui-quality-engine scope and focused research; no additional milestone ecosystem pass and no change to workflow.research. — Owner chose reuse; upstream stopping rule says implementation research belongs at actual phase uncertainties.
- [Phase 174]: The retained Delivery Storybook variations use the compile-time JSON scenario manifest through a pure projection builder; empty Helios remains connected-route-only.
- [Phase 174]: Fixed-overlay component stories keep a 600px iframe canvas so Storybook content-height sizing does not clip them.
- [Phase 174]: Keep Inbound native disabled buttons and compare raw :accept at the production component boundary.
- [Phase 174]: Normalize only generated selected IDs and documented timestamp precision or anchors; preserve meaningful projection values exactly.
- [Phase 174]: Keep unavailable and empty cases within their real rendering and route proof boundaries.
- [Phase 174]: Use one canonical production hooks.js asset and assign it to Storybook's hook registry without socket creation.
- [Phase 174]: Count sockets by browsing document because the Storybook explorer and preview iframe each own a legitimate transport.
- [Phase 174]: Keep the pinned Phoenix LiveView and PhoenixStorybook versions; verify both resolved clients instead of upgrading.
- [Phase 174]: Keep Light/Dark/System preference and OS resolution on the retained story root; do not write the authenticated host preference or create another socket.
- [Phase 174]: Serve production hooks plus the local theme adapter from a Demo-only versioned route. The pinned PhoenixStorybook macro evaluates use options before module attributes, so js_path uses the computed literal hash with a compile-time equality guard.
- [Phase 174]: Scope Inter, Inter Tight, and IBM Plex Mono to the production .mg-admin-root, display, and code roles while retaining existing global defaults.
- [Phase 174]: Keep source CSS, compiled bundle, and served response digests as separate receipt fields; assert byte equality only for built and served CSS.
- [Phase 174]: Reuse Admin's locked @axe-core/playwright dependency in a dedicated Storybook scan config.
- [Phase 174]: Require independent report identity and exact rule/target/scenario/state/theme fingerprint comparison.
- [Phase 174]: Keep incomplete Axe results explicitly triaged against a reproduced pre-repair report; approve no violations.
- [Phase 174]: Make each quick-view dialog focusable and use native disabled Delivery boundary buttons.
- [Phase 174]: Keep the selected Phase 174 sweep in the existing advisory Demo Browser Evidence job; do not promote it to a protected required context.
- [Phase 174]: Measure the full hosted job against a same-profile successful baseline; report the observed 15-second wall-budget overage without implying causality or critical-path latency.
- [Phase 174]: Keep Axe violation approvals empty and retain incomplete findings as incomplete even when triage removes them from the untriaged count.
- [Phase 174]: Keep Delivery's inert boundary and Inbound's native disabled-button boundary semantics distinct.
- [Phase 174]: Leave non-Phase-174 feedback with its named Phase 175–178 owners; defer set-wide STORY-07 and zoom reconciliation to Phase 178.
- [Phase 174]: D-52 reaffirmed: target zero owner UAT; automate observable criteria, repair routine defects, and close evidence-backed rows without confirmation. — Owner requested shift-left integration/e2e/smoke/seam proof, justified reuse of existing CI lanes, and durable records that prevent repeated UAT loops; see .planning/METHODOLOGY.md.
- [Phase 175]: Replay target identity remains server-owned; browser events supply only the validated entry origin.
- [Phase 175]: Quick view and Full detail share ReplayAction, with review entry shown only for exact or explicitly ambiguous target sets.
- [Phase 175]: Keep suppression refresh on the existing tenant, recipient, and stream-scoped query; prove external changes through fresh reads without changing domain semantics.
- [Phase 175]: Show only recorded expiry and known reason-based policy; label unknown expiry and policy as not recorded.
- [Phase 175]: The shared replay shell owns accessible overlay presentation; domain wrappers keep identity, eligibility, commands and outcomes distinct.
- [Phase 175]: Lower the Inbound quick-view layer while replay review is open so modal pointer actions remain reachable and selected context stays mounted.
- [Phase 175]: Replay failures stay mounted and recovery uses a fresh exact-scope review.
- [Phase 175]: Unavailable target evidence allows review again without enabling replay confirmation.
- [Phase 175]: Keep authorization, audit, and idempotency at the existing command boundary; revocation control is test-only.
- [Phase 175]: Keep empty Helios route-only and never fabricate a selected Delivery record.
- [Phase 175]: Retain Axe incomplete findings separately from violations and add separately identified review runs.
- [Phase 175]: Check every current Axe contrast selector match in the story root and keep the lowest ratio per selector.
- [Phase 175]: Refresh persisted fidelity source identity and executed case inventory when the source changes.
- [Phase 175]: Keep Phase 175 selection composable with the existing isolated Phase 174 runner and CI lane.
- [Phase 175]: Require exact nonempty expected/executed case IDs and current source/asset identity; process exit alone is not evidence.
- [Phase 175]: Retain Axe incomplete findings as incomplete and preserve failed historical evidence with rendered triage separate.
- [Phase 175]: Use the isolated mailglass_demo_phase175_05 database because the default Demo database had a migration ledger but lacked the Demo schema; leave default untouched.
- [Phase 175]: The eight judgment-tier prohibitions (UXF-12, OUTUX-07/08, REPLAY-04..08) are machine-checked by `phase175_prohibition_contract_test.exs` (mutation-proven) and closed as automated UAT. D-52 now covers prohibitions; see METHODOLOGY.md.
- [Phase 176]: Phase 176-01: window_hours=168 stays in committed filter URLs; only blanks and page=1 are dropped, query keys sorted
- [Phase 176]: Phase 176-01: filter commits read the Account only from socket.assigns.selected_tenant_id; hidden filters_tenant_id input deleted
- [Phase 176]: Phase 176-01: search edit history = push first commit, replace later ones, tracked via pending/last commit kind settled in handle_params; canonicalize and recover replace
- [Phase 176]: Inbound contacts: dedupe key is {local part exact, domain downcased}; unparseable = not exactly one @ with non-empty sides; spoof flagged when display name embeds a different address
- [Phase 176]: message_identity derives its recipient label from context (:inbound -> Delivered to) with no new public attr; Inbound Quick view projection unwidened
- [Phase 176]: Evidence card: one persistent disclosure toggle; caption and toggle render only when evidence is present; reveal handlers/telemetry unchanged
- [Phase 176]: 176-04: stale count hidden (D-15); stale title carries HH:MM UTC load time with a Components.timestamp line
- [Phase 176]: 176-04: persistent sr-only status region text is a pure function of settled read state (ResultsStatus.text/1); drafts never change it
- [Phase 176]: 176-05: checksum stays out of the five evidence facts as a scope choice (InboundEvidence stores raw_mime_sha256/fingerprint); payload size/header count are nil when unknown and render Unavailable, never 0
- [Phase 176]: 176-06: FilterSearchSync updated() hook path ships (demo LV 1.1.33 spike 2 passed, admin LV 1.2.13 3 passed); no push_event fallback
- [Phase 176]: 176-06: any hooks.js body change must re-pin the demo Storybook review-JS md5 in reference/demo_app/dev/mailglass_demo_web/storybook.ex
- [Phase 176]: Plan 07: Inbound filter_draft_params retains a rejected outcome/window only for a field in error, so a blank window never becomes a Custom period option
- [Phase 176]: Plan 07: Inbound same_location? canonicalizes both queries; committed Inbound URLs keep window_hours=168
- [Phase 176]: 176-08: inbound-evidence-* scenarios stay out of axe_selection (20); a11y for revealed/denied/invalid proven on connected routes in 176-10
- [Phase 176]: Inbound retry_inbound derives the selected record id from the page URI so Retry after a failed detail read keeps the URL selection
- [Phase 176]: Inbound stale retention keys on tenant/provider/outcome/search/window/page; only a same-key failed read is :stale, any other key is an error with no rows
- [Phase 176]: 176-10: coupled browser reds were Phase 175 and plan 176-03 spec drift, fixed in specs only; axe 'no new violations' measured against a per-collection, per-theme neutral baseline because Deliveries row buttons carry a Phase 113 aria-selected-on-button defect
- [Phase 176]: 176-11: Evidence card size and reveal share raw_source/1 (raw_payload first, then raw_mime); size is byte size of the revealed text; unencodable payload stays the source (Unavailable); nothing stored hides the reveal control; denial announced from the persistent status region (UI-SPEC rows superseded per D-26).
- [Phase 176]: 176-12: copy_value accessible name is "Copy <label>: <value>" (WCAG 2.5.3), fixed in the shared component for all 13 call sites; browser locators use full exact name where value in scope, anchored regex elsewhere
- [Phase 176]: 176-13: Deliveries treats a non-default window as a filter (non_default_window?/1); mobile toggle uses mg-inbound-filters-open class; PubSub refresh keeps status text (D-16); blank window_hours = absent (bounded D-13)
- [Phase 176]: 176-15: Draft note unchanged (D-12 as written); it co-occurs with the URL note, which is keyed on filter_url_invalid (assigned only in handle_params)
- [Phase 176]: 176-15: WR-05 fixed in product: rejected enum value stays selected as an enabled 'Not applied: <value>' option (enabled so re-post does not silently clear the filter)
- [Phase 176]: 176-14: P9..P13 gap prohibitions are mutation-proven contract describes; P13 asserts the URL note present and never the draft note absent (D-12/D-13)
- [Phase 177]: 177-01: Preview Back destination is rebuilt only from host navigation plus a closed-set surface and opaque id (ReturnContext); minting skipped for non-local preview_path (A3); theme sanitizer rejects dot segments (A2)
- [Phase 177]: 177-02: Health goldens are issues/activity keyword blocks; seeded ids masked as {key} in hrefs; quiet seed used for the empty state
- [Phase 177]: 177-04: Health column is a plain block (no grid gap) so status mt-md and activity mt-lg hairline spacing is not doubled; per-issue help stays the default tertiary field_help
- [Phase 177]: 177-05: Health notice sentences come from a closed notice_copy(status, panel) clause set; stale clauses return the lead-in and the shared timestamp follows
- [Phase 177]: 177-10: demo AdminAuth denies logged-out :operator_access with /demo/login?return_to=<arrival path+query> from get_connect_info(:uri); safe_return_to/1 stays the single validator
- [Phase 177]: 177-06: SurfaceNav scope attr defaults to :preview so a forgotten call site shows no Account identity; Account menu anchors to the header below md (spans group) and the details at md+ (aligns with summary)
- [Phase 177]: 177-07: Account-control e2e locators scope through the visible scope group (option/status/id) rather than visibility-filtering hidden-until-open elements; aria-label removed from role-less Account context div (axe aria-prohibited-attr)
- [Phase 177]: 177-08: Health composition A (single 42rem column) wins the bounded A vs B comparison; both pass G1-G7, tie-breakers 1-3 tie, layout rules 3 vs 8 decides; production unchanged
- [Phase 177]: 177-08: unavailable Health state is produced by arming a one-shot failed_ingest fault on Deliveries and reopening Health from the scope nav; empty uses the helios-void persona
- [Phase 177]: 177-09: northstar_normal Health story mirrors the real route's no-issue derivation; parity test also compares activity totals; story iframes resolved by stable id prefix
- [Phase 177]: 177-11: Phase 177 prohibitions are 16 violation-list detectors in phase177_prohibition_contract_test.exs, each mutation-proven; the docs rule guards against ever claiming the push_patch Account switch re-runs host authorization (gap captured as an open todo)
- [Phase 177]: 177-11: Pre-existing core (3), format (10 files), credo (6) and axe-baseline (3) failures recorded with pre-phase evidence in 177-AUTOMATION.md and deferred-items.md, not fixed
- [Phase 178]: 178-01: Preview read-only note wording kept verbatim after ux-writing review; editable fields describe only their own parse error (described_by/2), read-only displays reference preview-assigns-readonly-note
- [Phase 178]: 178-02: feedback ledger rule is phase-independent (never reads owner_phase), archive roots globbed, pointers must be path or path#anchor
- [Phase 178]: 178-03: D-14 honored via slim sibling scripts/check_phase178_candidate.sh (173 script cannot run for non-173 candidates); launcher/teardown act only on mailglass-phase178-review-* projects and /tmp/mailglass-phase178.* parents
- [Phase 178]: 178-03: cost disposition refuses runs whose head_sha is not the candidate SHA and never zero-fills a missing job; runner platform comes from a published label table or a saved job log, recorded in provenance
- [Phase 178]: D-16: STATE.md permanent facts re-homed to the v2.8 DOCS-01 record; prohibitions stay on STATE.md

## Quick Tasks Completed

| Date | Task | Outcome |
|------|------|---------|
| 2026-09-16 | [dispose the 14 open dependabot PRs](quick/260916-g7k-dispose-the-14-open-dependabot-prs/SUMMARY.md) | Open PRs 15 → 1. All 13 dependabot PRs were single-lockfile bumps colliding on 3 lockfiles; consolidated into one refresh (#260 → `753a840c`) and closed as superseded. #222 (Hex release proposal) deliberately left open. |
| 2026-09-16 | [scope release-please core exclude-paths](quick/260916-i5g-scope-release-please-core-exclude-paths-/260916-i5g-SUMMARY.md) | Core package was rooted at `.` and claimed `scripts/`, `.github/`, `dev/`, `test/`, `reference/`, `ci/`, `test_js/`, so tooling commits registered as core library features. `exclude-paths` widened 5 → 12 tracked entries (#263 → `ff52bb66`). Empty proposal #222 (2.6.0/2.6.0/2.3.0, zero adopter payload) closed. Same defect class as RELH-01. |
| 2026-09-16 | [add a release-target ledger close-out path](quick/260916-ldh-add-a-close-out-path-so-a-published-rele/260916-ldh-SUMMARY.md) | Nothing in the pipeline ever *wrote* the ledger, so every real release stranded it and failed `release-please` closed (`proposal_identity_mismatch`; the 2.5.0 strand ran ~4 weeks, 0/100 runs green). Added a non-authorizing `close-out` verb to `release_policy.exs` (can only ever emit `status: inactive`, re-validates its own output), an evidence-gated `release_policy_close_out.sh` (live Hex proof, checksums read from the API and re-verified, tag must resolve), and an in-memory self-heal in the capture control reporting `release_target_closed_out`. Publishing stayed `contents: read` — no new permissions. Stacked on #266. |

## Deferred Items

| Category | Item | Status | Deferred At | Milestone |
|----------|------|--------|-------------|-----------|
| debug_sessions | delivery-detail-overflow-168 | diagnosed | 2026-10-26 | v2.9 |
| debug_sessions | operator-browser-gate-pr302 | awaiting_human_verify | 2026-10-26 | v2.9 |
| seeds | SEED-261010-gad (operator date range and live filters) | dormant | 2026-10-26 | v2.9 |
| seeds | SEED-261010-hjp (inbound filters auto-apply and live search) | dormant | 2026-10-26 | v2.9 |
| deferred_items | Phase 168/deferred-items.md (v2.9): both entries record resolution in 168-02 | acknowledged | 2026-10-26 | v2.9 |
| deferred_items | Phase 171/deferred-items.md (v2.9): no open items; two assertions updated | acknowledged | 2026-10-26 | v2.9 |
| seeds | SEED-008-delivery-absence-detection | active | 2026-09-19 | v2.8 |
| uat_gaps | Phase 76/76-HUMAN-UAT.md (v1.7) | partial | 2026-09-19 | v2.8 |
| uat_gaps | Phase 22/22-HUMAN-UAT.md (v0.4) | superseded | 2026-09-19 | v2.8 |
| uat_gaps | Phase 16/16-HUMAN-UAT.md (v0.3) | partial | 2026-09-19 | v2.8 |
| verification_gaps | Phase 76/76-VERIFICATION.md (v1.7) | human_needed | 2026-09-19 | v2.8 |
| deferred_items | Phase 143/deferred-items.md (v2.2): emitted-body warning | acknowledged | 2026-09-19 | v2.8 |
| deferred_items | Phase 143/deferred-items.md (v2.2): migration-module redefinition warnings | acknowledged | 2026-09-19 | v2.8 |
| deferred_items | Phase 143/deferred-items.md (v2.2): upgrade migration down-test | acknowledged | 2026-09-19 | v2.8 |
| deferred_items | Phase 143/deferred-items.md (v2.2): schema-isolation down-test | acknowledged | 2026-09-19 | v2.8 |
| deferred_items | Phase 143/deferred-items.md (v2.2): isolated five-file mailglass-axis artifact | acknowledged | 2026-09-19 | v2.8 |
| deferred_items | Phase 143/deferred-items.md (v2.2): RepoTest config-schema-drift record | acknowledged | 2026-09-19 | v2.8 |
| deferred_items | Phase 143/deferred-items.md (v2.2): SchemaPrefixHardeningTest record | acknowledged | 2026-09-19 | v2.8 |
| deferred_items | Phase 143/deferred-items.md (v2.2): PersistenceIntegrationTest record | acknowledged | 2026-09-19 | v2.8 |
| deferred_items | Phase 143/deferred-items.md (v2.2): Igniter Rewrite.Error record | acknowledged | 2026-09-19 | v2.8 |
| deferred_items | Phase 143/deferred-items.md (v2.2): tenancy app-env leak record | acknowledged | 2026-09-19 | v2.8 |
| deferred_items | Phase 134/deferred-items.md (v2.0): pre-existing format drift | acknowledged | 2026-09-19 | v2.8 |
| deferred_items | Phase 134/deferred-items.md (v2.0): pre-existing Credo warning | acknowledged | 2026-09-19 | v2.8 |
| deferred_items | Phase 137/deferred-items.md (v2.0): trust-lane contract record | acknowledged | 2026-09-19 | v2.8 |
| deferred_items | Phase 137/deferred-items.md (v2.0): reference-baseline lock regeneration | acknowledged | 2026-09-19 | v2.8 |
| deferred_items | Phase 118/deferred-items.md (v1.14): preview asset rebuild drift | acknowledged | 2026-09-19 | v2.8 |
| deferred_items | Phase 121/deferred-items.md (v1.14): selected_delivery warning | acknowledged | 2026-09-19 | v2.8 |
| deferred_items | Phase 122/deferred-items.md (v1.14): Plan 122-01 compile warning | acknowledged | 2026-09-19 | v2.8 |
| deferred_items | Phase 122/deferred-items.md (v1.14): Plan 122-03 preview reshoot | acknowledged | 2026-09-19 | v2.8 |
| deferred_items | Phase 123/deferred-items.md (v1.14): pre-existing compile warning | acknowledged | 2026-09-19 | v2.8 |
| deferred_items | Phase 116/deferred-items.md (v1.13): operator-browser matrix failures | acknowledged | 2026-09-19 | v2.8 |
| deferred_items | Phase 44/deferred-items.md (v1.1): package build directories ignored incompletely | acknowledged | 2026-09-19 | v2.8 |
| deferred_items | Phase 09/deferred-items.md (v0.2): test-suite failure record | acknowledged | 2026-09-19 | v2.8 |
| deferred_items | Phase 11/deferred-items.md (v0.2): pre-existing Credo findings | acknowledged | 2026-09-19 | v2.8 |
| Scope lock | CI efficiency overhaul (SEED-006) | Deferred outside v2.7 | 2026-08-21 | v2.7 |

## Session Continuity

Last session: 2026-10-29T13:14:09.275Z
Stopped at: Completed 178-12-PLAN.md
Resume file: None

## Operator Next Steps

- Phase 174 is complete: 3/3 automated UAT rows, 148/148 cold and warm acceptance cases, no owner verification outstanding. Durable proof and replay commands: `.planning/phases/174-faithful-storybook-and-quiet-quick-views/174-AUTOMATION.md`.
- Next: `$gsd-plan-phase 175`. Apply D-52 and `.planning/METHODOLOGY.md`: target zero owner UAT, automate observable criteria, reuse justified CI coverage and do not reopen already-proved checks without relevant changes or new failures.

### Blockers

- 178-03: reference/demo_app/mix.lock is behind upstream (bandit 1.14.1, swoosh 1.29.3) so fresh isolated demo launches from main fail 'mix deps.get --check-locked'; blocks isolated-demo gates in 178-05/07/09/10 until a chore(deps) demo lock refresh (see deferred-items.md D-178-03-A)
