---
phase: 173
status: verified
candidate_sha: 9b6e60e4c8724b8168f72e49d9368aa7a0adc84a
branch: gsd/phase-173-delivery-8b4ce3e9
run_id: 38073415056
run_status: completed
required_ci_green: success
owner_acceptance: unverified
updated_at: 2026-10-10T18:12:10Z
---

# Tooltip candidate delivery checks

The user approved refreshing full delivery checks and CI for the tooltip follow-up, including repairs as needed. All local predicates and all 26 remote CI jobs passed for final candidate `9b6e60e4c8724b8168f72e49d9368aa7a0adc84a` on `gsd/phase-173-delivery-8b4ce3e9`. [CI run 38073415056](https://github.com/szTheory/mailglass/actions/runs/38073415056), attempt 1, event `workflow_dispatch`, completed/success for that exact SHA. The required [CI Green aggregate](https://github.com/szTheory/mailglass/actions/runs/38073415056/job/114278087180) completed/success at 2026-10-10T18:05:26Z. The requested checks are verified; Phase 173 remains verifying because authenticated owner acceptance is outstanding.

The committed candidate launcher ran with pinned Erlang 27/Elixir 1.18 and Bash 5, creating a fresh sparse detached candidate before local checks, isolated review startup and disposable synthetic evidence. No test-mode skipping or acceptance overrides were enabled. The clean final candidate is `/private/tmp/mailglass-phase173.5839WjPE/candidate`; its review URL is http://127.0.0.1:59905/dev/mail. The existing user URL http://127.0.0.1:55483/ops/mail?tenant_id=northstar also remains running via the override documented in `173-TOOLTIP-FIX.md`, mounted from the clean repair worktree at the final SHA.

Authenticated owner acceptance remains unverified and is not inferred from this request to run checks. Phase 173 and UIQ-03 remain incomplete; the historical 24/27 goal-verification report was not re-scored. No merge, publication, main write, protected original-file access or retained-resource cleanup occurred. Original owner edits and older previews remain preserved.

## Final exact-SHA verification

| Check | Result |
|---|---|
| Local Core package gate | 79 tests, zero failures |
| Local Admin package gate | 620 tests, zero failures, one existing exclusion |
| Local Inbound package gate | Three properties and 480 tests, zero failures, three existing exclusions |
| Local connected browser gate | 30 passed (25.3s) |
| Strict preview assets | Passed: warnings-as-errors compile without optional dependencies, 620-test suite, asset rebuild and committed CSS parity |
| Retained preview and synthetic evidence | Five required routes passed; built/served CSS matched; six clean exact-SHA current/baseline pairs validated (12 PNGs) |
| Candidate integrity | Scoped status clean; all four Mix locks match HEAD |
| Remote deterministic Core job 114275353484 | 23 properties, 2,215 tests, zero failures, 27 existing exclusions, seven skips; unchanged suite floor passed |
| Remote Admin job 114275353288 | Both 620-test invocations passed with one existing exclusion; unchanged coverage floor passed ([TOTAL] 83.6%) |
| Remote Operator Browser job 114275353363 | 214 passed, one existing guarded skip; includes all four tooltip regressions and the repaired replay focus test |
| Remote workflow | All 26 jobs completed/success, including required CI Green, Demo Browser Evidence and Preview Capture Advisory |

Local gate log: `/private/tmp/mailglass-phase173-full-gate-9b6e60e4.log`. The local-completion record was captured at 2026-10-10T18:08:43.049Z. The gate's exit 1 recorded the required-CI query still pending at its query time plus unverified owner acceptance; every local predicate passed. After terminal CI success, only the CI proof and advisory fields in the ignored delivery record were refreshed using the existing secure JSON writer. Its original local-completion bytes remain alongside it in `delivery-candidate.before-ci-completion.json`. The refreshed record passes local checks, readiness, browser evidence and required CI, remains `incomplete`, and lists exactly one failure: `protected owner acceptance remains unverified`.

The refresh verified workflow name/event/attempt, branch, exact SHA, all 26 successful jobs and the successful aggregate, plus unchanged clean candidate integrity. It did not claim a second gate execution or change any acceptance field. Terminal CI evidence is `/private/tmp/mailglass-phase173-ci-inspect-38073415056.json`; raw Core, Operator and Admin logs are `/private/tmp/mailglass-phase173-ci-core-114275353484.log`, `/private/tmp/mailglass-phase173-ci-operator-114275353363.log` and `/private/tmp/mailglass-phase173-ci-admin-114275353288.log`. The read-only watch process has ended; its exit code is not used as workflow authority. The terminal inspect result is authoritative.

## Retained review resources

- Review URL: http://127.0.0.1:59905/dev/mail
- Northstar health login: http://127.0.0.1:59905/demo/login?return_to=%2Fops%2Fmail%3Ftenant_id%3Dnorthstar
- Exact clean sparse candidate: `/private/tmp/mailglass-phase173.5839WjPE/candidate`
- Compose project: `mailglass-phase173-review-9b6e60e4-20261010175507-91184-2113`
- Ports: HTTP 59905, PostgreSQL 59906; both containers healthy at final verification
- Built and served CSS SHA-256: `36e08ac7344c60d66165d225008c1421457d2db5aee8770f6678de65fb75679e`
- Delivery record: `/private/tmp/mailglass-phase173.5839WjPE/candidate/reference/demo_app/tmp/demo_browser_evidence/delivery-candidate.json`
- Sanitized screenshot evidence: the same evidence directory's `retained/`, including a checkpoint and 12 validated PNGs

The disposable evidence project `mailglass-evidence-20261010175644-24563-11176` cleaned only its own containers and volumes; no matching containers remain. The retained review project stays available for owner acceptance. Its scoped cleanup commands are recorded below, not executed:

```sh
docker compose -p "mailglass-phase173-review-9b6e60e4-20261010175507-91184-2113" -f "/private/tmp/mailglass-phase173.5839WjPE/candidate/compose.demo.yml" down
git worktree remove "/private/tmp/mailglass-phase173.5839WjPE/candidate"
rmdir "/private/tmp/mailglass-phase173.5839WjPE"
```

Do not remove the repair worktree or tooltip override while the existing 55483 preview uses them. The original workspace remains at `8b4ce3e9`. Both protected demo paths stayed unmaterialized in each new sparse candidate; their original paths were never accessed. No further automated rerun is required for this unchanged SHA. Next: obtain authenticated owner acceptance for this candidate, then refresh formal Phase 173 verification and proceed to the v2.9 audit under the applicable workflow.

## CI timing repair and refreshed run

The 8a40b853 local gate completed with all local predicates passed: Core 79 tests, Admin 620 tests/one existing exclusion, Inbound three properties and 480 tests/three existing exclusions, 30 connected browser checks, strict preview assets, five ready routes, matching built/served CSS, and six exact-SHA clean screenshot pairs. Candidate `/private/tmp/mailglass-phase173.A5RkySJv/candidate` is clean and retained with preview http://127.0.0.1:52782/dev/mail and Compose project `mailglass-phase173-review-8a40b853-20261010173618-46131-20196` on ports 52782/52783. It is now historical exact-SHA evidence.

CI run 38072110775 completed/failure with 25 successful jobs, including required CI Green 114274530959 (success at 2026-10-10T17:47:19Z). The sole failed job was the operator browser advisory: 213 passed, one existing skip, one failed existing replay confirmation focus test (also failed its retry). All four new tooltip tests passed. The full Core job 114271498737 passed 23 properties and 2215 tests with zero failures, 27 exclusions and seven skips. Admin job 114271498748 passed both 620-test invocations and the unchanged coverage floor.

The downloaded retry trace confirms a focus race: the test focused Confirm at 82810.721ms, then the Enter action sent `close_replay` at 82824.85ms. The existing mounted focus uses two requestAnimationFrame callbacks and moved focus back to Close before Enter. The original test passed locally once, consistent with timing sensitivity. Commit `9b6e60e4c8724b8168f72e49d9368aa7a0adc84a` waits for mounted Close focus, then asserts Confirm focus before Enter. Authentication denial, retained modal/target, focus trapping and all other assertions remain unchanged. No timeouts, exclusions, retries, coverage floors or production behavior changed. The repaired test passed 20 consecutive local runs (1.4m); JavaScript syntax and scoped diff checks passed. Log: `/private/tmp/mailglass-phase173-confirmation-focus-fixed.log`. Diagnostic artifact: `/private/tmp/mailglass-phase173-operator-failure-38072110775/`.

The repair was pushed normally to the same delivery branch after the failed run reached its terminal state. New exact-SHA CI 38073415056 was dispatched at 2026-10-10T17:51:03Z and completed/success as recorded above. The fresh full local gate also passed every local predicate for 9b6e60e4. Both earlier review previews remain available. CSS bytes remain `36e08ac7344c60d66165d225008c1421457d2db5aee8770f6678de65fb75679e`. Owner acceptance is still unverified.
