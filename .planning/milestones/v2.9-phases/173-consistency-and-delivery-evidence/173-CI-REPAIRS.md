---
phase: 173
status: verifying
candidate_sha: cea2f46a37b15d33592e06bcc8c4baf43c4db5ea
previous_candidate_sha: 8b4ce3e9643dd1b6a64cc5c96213245bb284512a
branch: gsd/phase-173-delivery-8b4ce3e9
run_id: 38069265370
run_status: completed
required_ci_green: success
ci_repairs: verified
owner_acceptance: unverified
updated_at: 2026-10-10T17:03:50Z
---

# Phase 173 CI repairs

> Follow-up: `173-TOOLTIP-FIX.md` records the user-requested tooltip fix at 8a40b853. `173-DELIVERY-CHECKS.md` records final candidate 9b6e60e4, with all local delivery predicates and all 26 exact-SHA CI jobs passed, and the current review at http://127.0.0.1:59905/dev/mail. The CI results, resource identities and cleanup instructions below are historical for cea2f46a; the existing 55483 service now uses the separate tooltip override and final repair worktree. Owner acceptance remains unverified.

The user requested implementation of the bounded repair route in `173-REMOTE-CI.md`. Commit `3332a97f` repairs the original failures; follow-up `cea2f46a37b15d33592e06bcc8c4baf43c4db5ea` closes the newly exposed Admin coverage and fixture-boundary gaps and is the current delivery candidate. The same delivery branch was advanced normally for both commits. [CI run 38069265370](https://github.com/szTheory/mailglass/actions/runs/38069265370), attempt 1, was dispatched at 2026-10-10T16:50:19Z and completed/success. All 26 jobs passed. The exact-SHA required [CI Green aggregate](https://github.com/szTheory/mailglass/actions/runs/38069265370/job/114265525145) completed/success at 2026-10-10T17:02:23Z. The CI repair task is verified; Phase 173 remains verifying because owner acceptance is outstanding.

The preceding [run 38068164402](https://github.com/szTheory/mailglass/actions/runs/38068164402) completed/failure. Every required lane passed except Admin coverage: all 605 tests passed, but coverage was 4247/5230 (81.20%), below the existing 83.517034% floor. Required CI Green correctly rejected that result. The deterministic core suite passed in its normal checkout, including the README-dependent fixture unavailable in local sparse mode. Demo Browser Evidence and Operator Browser Gate both passed. The run finished before the next dispatch, so no in-progress job was canceled.

## Changes

- Reconciled the demo lock with its dependency requirements and verified both workspace and isolated Hex modes with `--check-locked`. Only its four existing dependency updates were taken from the original owner's lock; the original file remains untouched.
- Formatted the three rejected core tests and updated the three existing test-exception line references. No exclusions or expiry extensions were added.
- Made the explicit extra-mailer dry-run test exercise local mode; retained the CI tests that accept exactly HappyMailer and reject other mailers.
- Split renderer heading dispatch into function clauses while preserving strategy precedence and rendering behavior.
- Corrected the Repo facade's return specs for schema, map and scalar selections; narrowed the two SupportSummary getter specs to their guaranteed linkage keys. Removed the two resolved Dialyzer ignores and corresponding ledger entries. Strict warnings and unused-filter checks remain enabled.
- Prevented ExDoc autolinks to three hidden functions without changing their documented stability boundary.
- Replaced flagged sizing/focus/layer utilities with shared CSS, added the upstream Heroicons 2.2.0 x-mark SVG, and rebuilt committed Admin CSS. The replay correction is in `operator/replay_modal.ex`, not the inbound replay module.
- Made CI's existing six exact pinned synthetic baselines available in a fresh checkout. The producer validates the committed pack, provisions only pinned bytes, and refuses different existing destinations or symlinks. Runtime captures remain ignored. The candidate launcher and its contract fixtures now use the same committed pack.
- Repaired the Dialyzer retry with `--force-check --plt`, preserving its failure condition and strict final analysis.
- Added 15 behavior tests for Account identity fallback and selector retention, safe replay evidence wording, Account-scoped replay target cardinality, stale request mutation, exact Events beyond the bounded timeline, and current suppression versus historical outcome. The full Admin suite now has 620 tests. Its existing coverage floor, file scope and exclusions are unchanged.
- Kept the browser fixture's webhook lookup on its established SQL path and loaded the resulting row through TestRepo. This removes the compile-time Webhook query from the Admin production boundary, preserving Boundary's strict compile check.

## Local verification before publication

| Check | Result |
|---|---|
| Final affected renderer/Repo/SupportSummary tests | 65 tests, zero failures |
| Full core suite in sparse candidate | 23 properties and 2,215 tests; one failure, 27 excluded, seven skipped. The sole failure is the demo docs fixture's missing sparse-excluded README; it is not a local full pass. |
| Admin suite with CI=true, including follow-up | 620 tests, zero failures, one existing exclusion |
| Unchanged Admin coverage floor | Passed: 4378/5231 covered lines (83.693366%), above 3334/3992 and 83.517034% baseline |
| Follow-up behavior regressions | 15 tests, zero failures |
| Strict `mix verify.preview` after fixture repair | Passed: no-optional-deps compile with warnings-as-errors, 620 tests, asset rebuild and committed CSS parity |
| Root formatting, docs warnings-as-errors, design conformance | Passed |
| Strict Credo and static-analysis ledger | 560 source files, no Credo issues; ledger current, owned, expiring and non-growing |
| Strict Dialyzer | Passed; 14 existing skips, zero unused filters |
| Real PLT retry reproduction | Deleted only the isolated candidate PLT, retained its hash, rebuilt successfully with the new command, then passed strict analysis |
| Demo workspace and isolated Hex dependency locks | `mix deps.get --check-locked` passed; isolated Hex compile with warnings-as-errors passed |
| Pinned baseline provisioning tests | Four tests passed, including altered/missing bytes and symlink rejection |
| Candidate contract matrix and shell syntax | Passed; synthetic protected sentinels remained unmaterialized |

The final full-core command pinned Erlang 27 and Elixir 1.18.4 and selected Bash 5 explicitly. Earlier aborted runtime-diagnostic attempts do not count as passing verification. The unchanged README-dependent test must run in remote CI's normal checkout; no local test was removed or relaxed to accommodate the fence.

## Isolation and remaining work

The repair worktree is `/private/tmp/mailglass-phase173-ci-repair-lw4_w1ad/candidate`, detached and clean after commit. The original workspace remains at `8b4ce3e9` with its owner edits preserved. Both protected original demo files remain fenced, and both paths were omitted before materializing the repair and fresh gate worktrees.

The fresh exact-SHA candidate gate completed at 2026-10-10T16:57:14Z with all local predicates passed: Core 79 tests; Admin 620/one existing exclusion; Inbound three properties plus 480/three existing exclusions; connected browser 30 passed; strict preview assets passed; five required routes answered successfully; built/served CSS matched; six clean current/baseline PNG pairs passed exact SHA and byte validation. Candidate scoped status is clean, and all four Mix locks match HEAD. Exit 1 records exactly the still-pending required CI job and unverified owner acceptance. Log: `/private/tmp/mailglass-phase173-repair-full-gate-cea2f46a.log`.

Local bare-Mix calls received the pinned Elixir `MIX_HOME` and `MIX_ARCHIVES`, as well as Erlang 27 and Bash 5. This fixed the local archive mismatch without changing a test or gate. CI watch log: `/private/tmp/mailglass-phase173-followup-ci-watch-38069265370.log`. Current remote Admin lane 114263197009 passed both 620-test invocations and the unchanged coverage floor. The deterministic core lane 114263196902, Demo Browser Evidence 114263196901, Operator Browser Gate 114263197050 and Preview Capture Advisory 114263197258 all passed for this exact SHA.

After CI completed, the ignored delivery record's CI fields were refreshed from the verified `ci_monitor.cjs inspect` result. The original local-completion record is preserved beside it as `delivery-candidate.before-ci-completion.json`. Local evidence was retained for the same clean SHA; no tests were bypassed or attributed to a new run. The current record has passed local checks and required CI, remains `incomplete`, and lists exactly one failure: protected owner acceptance is unverified.

## Current review resources

- Review URL: http://127.0.0.1:55483/dev/mail
- Exact clean sparse candidate: `/private/tmp/mailglass-phase173.bvJb17QO/candidate`
- Retained Compose project: `mailglass-phase173-review-cea2f46a-20261010165422-30235-22143`
- Ports: HTTP 55483, PostgreSQL 55484
- Built and served CSS SHA-256: `f1da29567a33884236908e974792aabd3d10b4f73f18aa0eb0f5b60536a226da`
- Current local record: `/private/tmp/mailglass-phase173.bvJb17QO/candidate/reference/demo_app/tmp/demo_browser_evidence/delivery-candidate.json`
- Sanitized screenshot proof: the same evidence directory's `retained/`, with a checkpoint and 12 validated PNGs

All review resources are explicitly retained. The separate evidence Compose project cleaned only its own containers and volumes. To remove only the current retained preview after review:

```sh
docker compose -p "mailglass-phase173-review-cea2f46a-20261010165422-30235-22143" -f "/private/tmp/mailglass-phase173.bvJb17QO/candidate/compose.demo.yml" down
git worktree remove "/private/tmp/mailglass-phase173.bvJb17QO/candidate"
rmdir "/private/tmp/mailglass-phase173.bvJb17QO"
```

These commands were recorded, not executed. Preserve the older review resources below.

The intermediate `3332a97f` local gate completed/incomplete: package suites, readiness, CSS identity and six pinned screenshot pairs passed, but connected browser setup loaded an incompatible global Hex archive and strict preview compile exposed the fixture query Boundary warning. The earlier progress statement that all local browser/asset checks had passed was premature and was corrected. Its retained preview at http://127.0.0.1:50601/dev/mail and worktree `/private/tmp/mailglass-phase173.PqxoMW6u/candidate` remain preserved; its partial record is historical evidence only.

The older review preview at http://127.0.0.1:63769/dev/mail and its candidate `/private/tmp/mailglass-phase173.rNJ8Lp8c/candidate` are preserved. No merge, release, main write, protected original-file access, or acceptance on the owner's behalf occurred. Authenticated owner acceptance is the remaining delivery prerequisite; Phase 173 and UIQ-03 remain incomplete. The 24/27 goal-verification report is a historical snapshot; it was not silently re-scored or marked passed during this CI repair.
