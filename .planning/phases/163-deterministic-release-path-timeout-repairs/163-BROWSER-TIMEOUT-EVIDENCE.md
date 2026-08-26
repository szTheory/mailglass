# Phase 163 Browser Timeout Evidence

**Recorded:** 2026-08-26  
**Scope:** `mailglass_admin/e2e/gallery-matrix.spec.js` only; one Playwright worker; no added retries, selectors, workers, global deadlines, UI changes, dependencies, or CI changes.

## Instrumentation

- `OperatorBrowserServer.run!/0` now emits non-PII `stage=<id> elapsed_ms=<integer>` labels from `System.monotonic_time(:millisecond)` for boot, sandbox ownership, fixtures, TCP, both HTTP probes, and readiness.
- The gallery spec emits `test_body_start` and `test_body_finish` labels with its static test title and integer `process.hrtime.bigint()` elapsed milliseconds.
- Equality with a future selected deadline is defined as exhausted. No deadline was selected in this record.

## Toolchain and command

- Node: `v24.19.0`
- Playwright runner: local `@playwright/test` `1.59.1`, used by `npx playwright test`
- Assets command: `cd mailglass_admin && mix mailglass_admin.assets.build`
- Focused command, repeated exactly three times: `cd mailglass_admin && npx playwright test e2e/gallery-matrix.spec.js --config=playwright.config.cjs --workers=1`
- Focused proof retry setting: `0` (`CI` was unset; the existing configuration remains unchanged).

## Diagnostic invocations

| Run | First attempt | Readiness elapsed (ms) | Discovery/body test 1 (ms) | Stress/body test 2 (ms) | Total (ms) | Discovered cells | Coverage result |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- |
| 1 | pass | 286 | 9,175 | 885 | 13,110 | >50 | Both live-discovery and stress tests passed; required stress cells, 320/390/768/1440, light/dark/system, overflow, and 320px clipping assertions executed. |
| 2 | pass | 219 | 9,051 | 935 | 12,763 | >50 | Both live-discovery and stress tests passed; required stress cells, 320/390/768/1440, light/dark/system, overflow, and 320px clipping assertions executed. |
| 3 | pass | not retained | not retained | not retained | not retained | >50 | The completed third first attempt is confirmed by Playwright's `test-results/.last-run.json` (`status: passed`); the terminal collector did not retain its emitted monotonic labels, so no timing value is inferred. |

Observed retained ranges (runs 1–2 only): readiness `219..286ms`; discovery/body `9,051..9,175ms`; stress/body `885..935ms`; invocation total `12,763..13,110ms`.

## Existing readiness-path correlation

For each retained diagnostic run, the existing startup sequence reached all of the following before Playwright began the matrix:

1. app start and sandbox owner,
2. fixture seeding,
3. TCP connection to port 4101,
4. `GET /ops/browser-ready` → `200`, and
5. `GET /ops/browser-login?tenant_id=browser-tenant` → `302`.

The web-server owner remained singular and its configured `300,000ms` lifecycle ceiling was not changed. `playwright.config.cjs` retains the config-wide `30,000ms` test default and its existing CI retry policy.

## Attribution verdict and repair selection

**Verdict: `unattributed`.** No server-boot, TCP/HTTP-readiness, discovery/body-test-1, or stress/body-test-2 timeout reproduced inside the finite three-invocation diagnostic budget. Every attempt was first-attempt green and the final two-test Playwright result was passed.

**Repair: none.** An unambiguous reproduced owner is the Task 2 precondition. It is absent, so no readiness bound, per-test timeout, global Playwright timeout, web-server lifecycle, retry policy, worker count, matrix coverage, UI, dependency, workflow, or job deadline was altered.

**DTRM-03 boundary status: flagged-unverified.** The minimum/maximum selected timeout and one-millisecond-below/equal/above behavior cannot be derived without a reproduced owner. Equality remains defined as exhaustion if a future evidence-backed local deadline is selected.

## 2026-08-26 immutable historical reconstruction (Plan 163-05 Task 1)

### Bounded read-only Actions search

The search examined the ten most recent failed `ci.yml` runs and found five completed
`Operator Browser Gate` candidates. Four are not the original gallery timeout: run
`32865596109` / job `97860146489` at
`6ac2616a33b207474f0212c34e609c120773e6b9` failed in structural assertions while its
gallery tests passed; run `32861979884` / job `97848441478` at
`3d93f4ef4427789a682e366ca92736c4819fc61a`, run `32391678001` / job `96499176927` at
`80e00719d2db07b0916ae7b6f156f276c3fb65bb`, and run `32315530631` / job `96266849356`
at `3032ca2e627b9fae5bd36e8582172d34585187c6` either passed the gallery test or failed
another named structural test. No more than these five failed-gate candidates were
inspected.

One terminal identity does contain the historical gallery failure:

- Run: https://github.com/szTheory/mailglass/actions/runs/32865270291
- Job: https://github.com/szTheory/mailglass/actions/runs/32865270291/job/97858959632
- Event: `push`; full failing SHA: `fda6368bf43c49aab88e3f90da1d6af67ee77d35`
- Locked CI command/toolchain: `npm run test:operator-browser` →
  `mix mailglass_admin.assets.build && playwright test --config=playwright.config.cjs --workers=1`,
  Elixir `1.18` / OTP `27` / Node `22`, Playwright Chromium `v1217`.
- First failing title: `gallery matrix — RATCHET-02 resize-loop overflow gate › every gallery specimen renders without horizontal overflow across 320/390/768/1440 × light/dark/system`.
- First attempt: exhausted the existing `30,000ms` test bound after `30.3s`; the CI retry
  also failed after `32.4s`. The terminal result is retained in the job log. Its retained
  result identities are `test-results/gallery-matrix-gallery-mat-ff9cf-68-1440-×-light-dark-system/error-context.md`
  and `...-retry1/trace.zip`. The first attempt also reported an unrelated missing gallery
  wrapper; the retry exhausted while waiting at a different gallery locator. Therefore the
  historical log alone does not establish a singular local operation inside the test body.

### Disposable exact-SHA reconstruction

A disposable clone at `/tmp/mailglass-163-05-browser-repro.mO0TeD` was checked out at the
full SHA above. Its locked Mix and npm dependencies were installed, assets built, and the
exact gallery file was run three times with `CI` unset (therefore zero retries) and
`--workers=1`:

| Attempt | First attempt | Discovery/body test 1 | Stress/body test 2 | Total | Result / cleanup |
| --- | --- | ---: | ---: | ---: | --- |
| 1 | pass | 17,700ms | 1,900ms | 44,300ms | Both tests passed; Playwright web-server process exited after the run. |
| 2 | pass | 23,400ms | 1,900ms | 28,900ms | Both tests passed; Playwright web-server process exited after the run. |
| 3 | pass | 17,800ms | 1,900ms | 23,100ms | Both tests passed; Playwright web-server process exited after the run. |

The historical SHA predates the current timing labels, so exact-SHA readiness values and
stage-labelled body values were not emitted; no missing timing is inferred. Each run did
retain the complete two-test result and the original matrix source remains unchanged with
live discovery, the `>50` guard, stress cells, `320/390/768/1440`, light/dark/system,
overflow, and 320px clipping checks.

**Historical reconstruction verdict: `inconclusive`.** The immutable run confirms a
first-attempt gallery timeout at the exact SHA, but all three retry-disabled disposable
first attempts passed and the historical log identifies different in-test locator states.
It does not reproduce an unambiguous readiness or one named test-body owner. No source,
timeout, retry, worker, UI, package-script, configuration-global, lifecycle, CI-topology,
or deadline change is authorized. This entry supersedes neither the prior `unattributed`
diagnostic verdict nor its no-repair decision; it supplies the bounded evidence required
for the Task 2 maintainer decision.
