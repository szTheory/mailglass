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
