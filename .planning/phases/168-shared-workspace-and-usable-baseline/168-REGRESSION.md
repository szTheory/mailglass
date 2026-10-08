# Phase 168 — Automated Regression Gate

Final execution after Plan 10's operator-fixture correction was run on `fece85d26dabf34573e08b246985b80ff7f72651`. Runtime: Elixir `1.18.4-otp-27`, Erlang `27.3.4.15`, `MIX_ENV=test`.

## Command discovery

No `workflow.test_command` is configured, and the root `Makefile` has no `test:` target. GSD's generic fallback does not recognize this Mix monorepo and resolves to `true`; that is not test evidence. The Phase 168 suite was run explicitly from `mailglass_admin`. The requested repository-pinned Elixir/Erlang patch versions are not installed locally, so the installed Elixir 1.18.4 / OTP 27 pair was selected through asdf overrides.

## Results

| Gate | Command | Result |
|---|---|---|
| Root core suite, attempted as the generic cross-phase check | `ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 mix test --seed 1` | 2,200 tests; 10 failures, 9 invalid, 27 excluded, 7 skipped. Failures include stale release metadata/design-system test fixtures, sibling-directory writes blocked by the workspace sandbox, and workspace/demo dependency lock mismatches. These failures are outside the Phase 168 Plan 10 source scope; the check is recorded as non-green, not waived as passing. |
| Full Admin integration and component suite | From `mailglass_admin`: `ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 mix test --seed 1` | 551 tests, 0 failures, 1 excluded |
| Full operator browser suite, including Phase 168 acceptance, 120-cell responsive/theme matrix, accessibility scans, and Phase 169 journeys | From `mailglass_admin`: `ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 BROWSER_SERVER_PORT=4102 npm run --silent test:operator-browser` | 199 passed, 1 skipped, 0 failed; 3.2 minutes |

The single browser skip is the existing guarded structural case for an absent header-anchored overlay. The focused Plan 10 browser test and full browser suite both passed with host browser-process permission after the sandbox denied Chromium's macOS Mach port setup. The Admin suite passed inside the standard workspace sandbox. All 10 failures in the root core suite were surfaced; the operator/Admin and browser suites that cover the Phase 168 changes are green.

## Gate disposition

Continue to the independent Phase 168 verifier: the Plan 10 focused tests, the full Admin suite, and the full Playwright suite pass; the root-suite failures are in release/design-system fixtures and restricted-workspace dependency/sandbox setup outside Plan 10's changed files. Keep the root suite non-green in this record and carry its setup failures into separate project health work rather than asking the owner to repeat deterministic UI acceptance.

## CI disposition

The same Playwright suite already runs in the `operator_browser_gate` GitHub Actions job on code changes; the local `mix ci.browser` alias runs the same suite. The job is advisory and excluded from `CI Green`'s required-gate aggregation, consistent with the zero-Node adopter boundary. This phase did not change required-check policy. These tests provide repeatable browser evidence without asking for manual UAT.
