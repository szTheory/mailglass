# Phase 171 Regression Gate

## Why this gate exists

GSD did not recognize the repository's Mix test setup and selected `true` as its generic test
command. The root umbrella suite is also a known non-green baseline, so running it as the phase
gate both failed to give useful phase evidence and consumed the full timeout. The repository now
uses `bash scripts/gsd-regression-gate.sh` as its explicit GSD test command. This gives future phase
execution a bounded, repeatable regression gate without adding a dependency or changing GitHub CI.

The gate favors recurring signal per run: core renderer/operator contracts, the required Admin
Support Contract suite, deterministic inbound tests, and connected browser journeys for the
recent operator and preview phases. The expensive 1,000-case inbound property suite remains in its
dedicated CI lane instead of being repeated on every unrelated phase.

## Run and evidence

Command used:

```sh
node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs run-with-timeout 600 -- bash scripts/gsd-regression-gate.sh
```

Result: **passed**.

| Gate slice | Result |
|---|---:|
| Root renderer, operator, replay, and timeout-evidence contracts | 72 tests, 0 failures |
| Admin Support Contract suite | 593 tests, 0 failures, 1 excluded |
| Inbound deterministic suite | 480 tests, 0 failures, 3 excluded |
| Connected Phase 170 and preview browser journeys | 30 passed (41.9 seconds) |

The final browser run required no test retries. The first invocation in the tool sandbox was blocked
before browser assertions by macOS Mach-port permissions; the same configured gate passed when rerun
with host-level Chromium permissions. The runner retries only a reported `EADDRINUSE` /
address-in-use startup collision, up to three total port selections; it does not retry assertion or
application failures. The gate snapshots and restores the historical Phase 168 and Phase 169
browser artifact directories on every exit, preserving the workspace's prior evidence. The Admin
suite's bare-URL tenant test now renders the connected view before asserting its deferred canonical
patch, so the assertion waits for the behavior it covers. The host-owned Preview route guard is
also pinned by a router test that checks both the guide's boundary language and the example's
`:dev_routes` wrapper.

The browser checks cover the Phase 171 scenario picker, editable assigns, output tabs, responsive
layout, and independent preview width/appearance controls. These checks exercise machine-observable
acceptance criteria; no owner UAT handoff remains for them. A preview capture remains evidence of
the local renderer preview pipeline only, not proof of email-client rendering.

## Scope

The broad root umbrella suite and the entire browser suite are deliberately not the recurring GSD
gate. The root suite has a documented non-green baseline unrelated to this phase, and the complete
browser suite exceeded the execution timeout during the initial attempt. The focused browser
selection includes Phase 170 and Phase 171 preview journeys. A broader local attempt also exercised
Phase 168/169 cases and found unrelated failures in the inbound replay-modal focus journey and
Phase 169 suppression-refresh journey; those cases remain in the full `test:operator-browser` suite
in the required GitHub Actions `operator_browser_gate`. Do not weaken or remove those dedicated CI
checks to make this local gate pass.
