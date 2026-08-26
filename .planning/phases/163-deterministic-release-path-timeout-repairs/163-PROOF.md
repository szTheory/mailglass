---
phase: 163-deterministic-release-path-timeout-repairs
repair_sha: 03605625c2fca8a747a94ab19d0ee1a430ab301a
implementation_sha: 9d0bcacf875ad0c88155bd16bad2996c1c57b926
protected_run_id: 32998989827
protected_verdict: success
final_signoff: pass
human_uat_required: false
---

# Phase 163 Proof

## Final verdict

All Phase 163 requirements pass through machine evidence. No human UAT,
workflow dispatch, rerun, merge, release, or policy mutation was used.

| Requirement | Verdict | Evidence |
| --- | --- | --- |
| DTRM-01 | pass | Historical structured SQLSTATE 57014 was reconstructed at its immutable SHA three times without recurrence. No speculative database repair was made; both 1,000-run invariants remain unchanged and the existing protected lane now emits sanitized exact-operation recurrence evidence. |
| DTRM-02 | pass | The focused database pair/contracts passed, the complete local deterministic suite passed, and protected Core Deterministic Suite job `98275572748` succeeded. No seed, skip, product/schema/API, database-global, or job-timeout relaxation occurred. |
| DTRM-03 | pass | Current and protected evidence attributed browser expiries to three exact matrix titles plus the browser-only sandbox owner. Finite local bounds repair those owners while all 117 cells, widths, themes, stress fixtures, and overflow assertions remain. |
| DTRM-04 | pass | Three focused gallery first attempts, the later exact-title focused sets, two complete local browser gates, and protected Operator Browser Gate job `98275572988` passed. Global timeout, retry, worker, UI, matrix, and job policy remain unchanged. |

## Immutable identities and chronology

- Database historical failure: run `32433156236`, job `96628985134`, SHA
  `81e738e74d59d1ab36c3e1dc3adc03ad6d0c0b84`, SQLSTATE 57014.
- Browser historical failure: run `32865270291`, job `97858959632`, SHA
  `fda6368bf43c49aab88e3f90da1d6af67ee77d35`.
- Final executable implementation: `9d0bcacf875ad0c88155bd16bad2996c1c57b926`.
- Protected repair identity: `03605625c2fca8a747a94ab19d0ee1a430ab301a`.
  The commits between the implementation and protected identity contain only
  append-only Phase 163 evidence; the protected tree contains the exact final
  executable implementation.

| Commit | Purpose |
| --- | --- |
| `29eb8b3f` | Structured sanitized database recurrence evidence around unchanged 1,000-run properties |
| `7b9da5b7` | Initial gallery owner repair plus browser recorder/reporter |
| `f46aad8b` | Failure-only evidence artifacts in the two existing protected lanes |
| `9b1a7c0c`–`d27de4b6` | Contract-tested read-only CI/PR/run/job/artifact inspection |
| `e8c6260f` | First protected gallery and contrast-matrix recurrence repair |
| `9d0bcacf` | Final gallery/primitive-matrix bounds and browser sandbox-owner repair |

## Focused and local proof

### Database

- Three retry-disabled disposable attempts at the historical SHA completed
  without recurrence. Boundary verdict: `inconclusive`; repair verdict: `none`.
- Precision is fail-closed: only SQLSTATE 57014 from a named wrapped operation is
  recorded; absent recurrence does not infer a boundary or authorize a change.
- Current focused pair plus recorder/workflow contracts: 2 properties, 6 tests,
  0 failures in 64.4s.
- Both properties retain unseeded generation, `max_runs: 1000`, ten-minute
  ownership, and original cleanup/settle semantics.

### Browser

| Evidence stage | Exact owner | Observed exhausted attempts | Selected finite bound |
| --- | --- | --- | ---: |
| Current CI-mode reproduction | Complete 117-cell gallery matrix | 30,002ms / 30,083ms | initially 60,000ms |
| Protected run `32994318111` | Complete gallery / inbound contrast matrix | 60,002ms / 60,047ms; 31,348ms / 31,336ms | 120,000ms / 60,000ms |
| Protected run `32996524975` | Complete gallery / primitive state-theme matrix | 120,004ms / 120,064ms; 32,530ms / 32,670ms | 240,000ms / 60,000ms |
| Protected run `32996524975` | Browser sandbox owner | 11.6m suite outlived 10m owner | 20 minutes |

- The first three repaired gallery invocations passed first attempt in 44,027ms,
  47,553ms, and 50,256ms.
- The final exact trio passed first attempt in 47.7s, 17.8s, and 12.2s.
- Final complete local `CI=true npm run test:operator-browser`: 176 passed,
  1 intentional skip in 3.8m, no retry; readiness 240ms, gallery 47.8s,
  primitive matrix 14.4s.
- Equality with every selected Playwright timeout remains exhaustion. All bounds
  are finite, title-local except the browser-only sandbox owner, and below the
  unchanged 30-minute job.

### Complete integration

| Gate | Result |
| --- | --- |
| `mix test --warnings-as-errors` | 23 properties, 1,964 tests, 0 failures, 7 intentional skips in 174.7s |
| `CI=true npm run test:operator-browser` | 176 passed, 1 intentional skip in 3.8m; no retry |
| Evidence/CI contracts | ExUnit recorder/workflow contracts, admin recorder tests, Node reporter/monitor tests all pass |
| Workflow validity | `actionlint .github/workflows/ci.yml`, phase-owned format checks, and `git diff --check` pass |

## D-01 through D-06 traceability

| Decision | Resolution |
| --- | --- |
| D-01 database attribution | Historical 57014 retained; bounded exact-SHA non-reproduction authorizes no repair and automatically captures the next exact operation. |
| D-02 database invariant | Both properties remain unseeded 1,000-run properties with unchanged ownership and settle semantics. |
| D-03 browser attribution | Monotonic readiness/test evidence distinguishes healthy boot from three exact matrix bodies and sandbox-owner lifetime. |
| D-04 browser coverage | Live discovery, `>50` guard, 117 cells, four widths, three themes, stress fixtures, overflow, and clipping remain intact. |
| D-05 local integration | Both unchanged complete release-path commands pass first attempt. |
| D-06 protected authority | Normal pull-request run `32998989827` exactly matches `repair_sha`; both named protected jobs succeeded. |

## Edge and prohibition resolution

| Candidate | Resolution/backstop |
| --- | --- |
| Database boundary | Inconclusive by three-run budget; fail-closed recorder requires a future structured 57014 before any repair. |
| Database precision | SQLSTATE and stable operation labels only; raw SQL, params, payloads, and free-form errors are excluded. |
| Database manual-review candidate | Source diff, focused contracts, complete local suite, and protected deterministic job agree; no human review remains. |
| Browser boundary | Exact title-local monotonic durations and the owner lifetime establish the four repaired boundaries. |
| Browser precision | Equality exhausts; 240s/60s/20m are finite evidence-derived ceilings, not unlimited/global test policy. |
| Browser manual-review candidate | Coverage inventory, focused timings, complete local lane, and protected browser job agree; no human review remains. |

- Transparency: original failures, non-reproduction, protected recurrences, and
  downstream ownership cascade remain recorded rather than normalized away.
- Privacy: durable evidence contains only stable operation/test/stage labels,
  integer durations, toolchain/run identities, and trace basenames; no PII.
- Proof integrity: no seed pin, retry increase, worker increase, skipped property
  or cell, UI/product/schema/API/package/dependency/action change, schedule, new
  job, manual dispatch, merge, release, or unlimited/global timeout.

## Protected reconciliation

Captured read-only on 2026-08-26 through `scripts/ci_monitor.cjs`:

| Field | Value |
| --- | --- |
| PR | https://github.com/szTheory/mailglass/pull/228 |
| Run | https://github.com/szTheory/mailglass/actions/runs/32998989827 |
| Event / status / conclusion | `pull_request` / `completed` / `success` |
| Head SHA | `03605625c2fca8a747a94ab19d0ee1a430ab301a` (exact `repair_sha`) |
| Core job | `98275572748` — `Core Deterministic Suite (Elixir 1.18 / OTP 27)` — success |
| Browser job | `98275572988` — `Operator Browser Gate (Elixir 1.18 / OTP 27 / Node 22) (22)` — success |

Core job: https://github.com/szTheory/mailglass/actions/runs/32998989827/job/98275572748

Browser job: https://github.com/szTheory/mailglass/actions/runs/32998989827/job/98275572988

## Source Coverage Audit

| Source | Coverage |
| --- | --- |
| `163-DATABASE-TIMEOUT-EVIDENCE.md` | Historical identity, three bounded reconstructions, no-repair verdict, current recurrence capture |
| `163-BROWSER-TIMEOUT-EVIDENCE.md` | Historical/current/protected ownership, all selected finite bounds, focused/full proof |
| Executable tests/support/workflow | Invariants, matrix axes, evidence reporters, failure-only artifacts, CI monitor contracts |
| Protected run `32998989827` | Exact identity and successful named deterministic/browser jobs |

`protected_verdict: success`

`final_signoff: pass`

`human_uat_required: false`
