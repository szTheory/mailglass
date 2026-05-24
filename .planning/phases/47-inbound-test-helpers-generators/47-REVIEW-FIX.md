---
phase: 47-inbound-test-helpers-generators
fixed_at: 2026-05-24T13:30:00Z
review_path: .planning/phases/47-inbound-test-helpers-generators/47-REVIEW.md
iteration: 2
findings_in_scope: 7
fixed: 7
skipped: 0
status: all_fixed
---

# Phase 47: Code Review Fix Report (Iteration 2)

**Source review:** `.planning/phases/47-inbound-test-helpers-generators/47-REVIEW.md`
**Iteration:** 2
**fix_scope:** all (CR + WR + IN)

**Summary**
- Findings in scope: 7
- Fixed: 7
- Skipped: 0
- Status: `all_fixed`

All work was done in an isolated worktree on `gsd-reviewfix/47-43989`, one atomic
commit per finding, then fast-forwarded to `main`. No pre-existing dirty files
were staged; no `mix.lock` drift was committed (reverted after each
`mix deps.get`). All inbound test runs used `--seed 0`.

The iteration-1 fix report (CR-01 + WR-01..WR-06) is preserved as
`47-REVIEW-FIX.iter1.md`.

## Fixed Issues

### CR-01: `receive_provider_payload/3` broken for `:sendgrid` and `:mailgun`

**Files:** `mailglass_inbound/lib/mailglass_inbound/fixtures.ex`, `mailglass_inbound/lib/mailglass_inbound/test/ingress.ex`
**Commit:** `42b80b9`
**Option taken:** Review's strongly-preferred **option (a)** — keep the four-provider
contract whole by making the fixtures self-sign against documented defaults
(mirroring `build_ses_sns_payload/1`'s self-sign-against-a-primed-cert pattern).
Option (b) was not needed.
**Applied fix:**
- SendGrid: `build_request(:sendgrid, …)` now honors `opts[:headers]` like the
  `:postmark` clause (it was silently dropping them). `build_sendgrid_payload/1`
  emits an `authorization: Basic …` header self-signed against
  `Fixtures.sendgrid_fixture_config/0` and returns a `:config`; the driver
  defaults config from the fixture's `:config` (mirrors `:ses`).
- Mailgun: `build_mailgun_payload/1` HMAC-signs the `timestamp`/`token`/`signature`
  triple against `Fixtures.mailgun_fixture_config/0` (current timestamp inside
  verify!'s skew tolerance; fresh nonce token); `build_request(:mailgun, …)`
  defaults config from the fixture's `:config`.
- The real `verify!` seams are never weakened — the fixtures now satisfy them.
  Added public `sendgrid_fixture_config/0` and `mailgun_fixture_config/0`.
  Updated the `receive_provider_payload/3` doc.
**Note:** This is a behavioral/logic fix, empirically validated — the WR-08 tests
fail before this fix and pass after (proven by stashing the source and re-running).

### WR-08: No driver-level test for `:sendgrid`/`:mailgun`

**Files:** `mailglass_inbound/test/mailglass_inbound/test/ingress_test.exs`
**Commit:** `f277ff9`
**Applied fix:** Added three `receive_provider_payload/3` tests (SendGrid
out-of-the-box accept, SendGrid raw_mime dedupe convergence through the verify!
seam, Mailgun out-of-the-box accept). Verified they fail against pre-CR-01 source
and pass after.

### WR-07: Helpers steer adopters to the internal `%Route{}` struct

**Files:** `lib/mix/tasks/mailglass.gen.mailbox.ex`, `mailglass_inbound/README.md`, `mailglass_inbound/docs/api_stability.md`, `mailglass_inbound/lib/mailglass_inbound/test/ingress.ex`
**Commit:** `d395116`
**Option taken:** Review's **second option** (most consistent with the
README/MailboxCase, which already drive routing abstractly): point adopters at the
stable `Router` authoring seam via the `:router` option instead of the
`@moduledoc false` struct.
**Applied fix:** gen.mailbox scaffold now drives `router: <App>.InboundRouter`
(the route stub it already adds); `Test.Ingress.receive_inbound/2` `:routes` doc
reframes `:router` as the adopter input and `:routes` as package-internal; README
example uses `router:`; api_stability.md states the `Route` struct is not part of
the contract.

### IN-01: gen.inbound_router scaffolds a route to non-existent `SampleMailbox`

**Files:** `lib/mix/tasks/mailglass.gen.inbound_router.ex`
**Commit:** `138b878`
**Applied fix:** Added a comment block explaining `SampleMailbox` is a placeholder
and how to replace it; kept the active route so the scaffold stays a working
starting point.

### IN-02: `parse_module/1` mints odd atoms from arbitrary strings

**Files:** `lib/mix/tasks/mailglass.gen.inbound_route.ex`
**Commit:** `645a08d`
**Applied fix:** `parse_module/1` validates the arg matches dot-separated
CamelCase (`~r/^[A-Z]\w*(\.[A-Z]\w*)*$/`) and `Mix.raise`s a clear message
otherwise. The recipient `pattern` positional is unaffected.

### IN-03: predicate clause does not handle captured-function syntax

**Files:** `mailglass_inbound/lib/mailglass_inbound/test_assertions.ex`, `mailglass_inbound/test/mailglass_inbound/test_assertions_test.exs`
**Commit:** `883c44e`
**Applied fix:** Added a `{:&, _, _}` macro clause mirroring `{:fn, _, _}` plus a
regression test. Verified the test fails with `FunctionClauseError` without the
clause and passes with it.

### IN-04: `Test.Ingress` "emits no telemetry of its own" can mislead

**Files:** `mailglass_inbound/lib/mailglass_inbound/test/ingress.ex`
**Commit:** `eeab4a7`
**Applied fix:** Reworded the PII-posture moduledoc to "adds no telemetry of its
own (the `Execution.execute/2` it drives emits the normal PII-free execution
span)".

## Skipped Issues

None.

## Verification performed

- Affected inbound suites (`ingress_test`, `fixtures_test`, `test_assertions_test`,
  `docs_contract_test`): 49/49 pass, `--seed 0`.
- Generator suites (`gen.inbound_router`, `gen.inbound_route`, `gen.mailbox`):
  15/15 pass, `--seed 0`.
- `mix compile --warnings-as-errors` and
  `mix compile --no-optional-deps --warnings-as-errors` for the inbound package:
  both clean.
- Each design-bearing/logic finding (CR-01, WR-08, IN-03) was proven
  regression-meaningful by reverting the fix and confirming the test fails.

## Cleanup

Transactional cleanup tail completed in order: fast-forward `main` → remove
worktree → delete temp branch `gsd-reviewfix/47-43989` → drop recovery sentinel.
Final state verified: no orphan reviewfix worktree/branch, sentinel absent,
pre-existing dirty files (`CLAUDE.md`, `MAINTAINING.md`, root `mix.exs`/`mix.lock`,
`test/mailglass/docs_contract_test.exs`, `guides/jobs.md`) untouched.

---

_Fixed: 2026-05-24T13:30:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 2_
