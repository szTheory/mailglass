---
phase: 47-inbound-test-helpers-generators
plan: 03
subsystem: mailglass_inbound (test helpers)
tags: [inbound, test-helpers, assertions, driver, persist, execute, capture-seam]
requires:
  - MailglassInbound.Ingress.Persist.persist/2 (real persist + route map)
  - MailglassInbound.Execution.execute/2 (SYNC; normalized outcome map)
  - MailglassInbound.Ingress.Providers.{Postmark,Sendgrid,Mailgun,SES} (real verify!/normalize)
  - MailglassInbound.Fixtures (build_inbound_message/1 + provider payload builders, Plan 01)
  - MailglassInbound.Router.Route / Router.Matcher (route compatibility)
provides:
  - MailglassInbound.Test.Ingress.receive_inbound/2
  - MailglassInbound.Test.Ingress.receive_provider_payload/3
  - MailglassInbound.TestAssertions.assert_inbound_received/0,1
  - MailglassInbound.TestAssertions.assert_inbound_{accepted,ignored,rejected,bounced}/0
  - MailglassInbound.TestAssertions.assert_inbound_routed_to/1
  - MailglassInbound.TestAssertions.assert_inbound_no_match/0
  - MailglassInbound.TestAssertions.assert_no_inbound_received/0
affects:
  - mailglass_inbound Hex package (two new lib/ modules ship via the lib glob)
  - downstream Phase 47 plans (MailboxCase imports TestAssertions; adopters import both)
tech-stack:
  added: []
  patterns:
    - Capture seam relocated into the driver — send(self(), {:inbound, msg, outcome, route}) — since inbound has no Fake.Storage analog
    - Captured outcome is the normalized execute/2 result map (not the raw mailbox atom), so assertions match the persisted ExecutionRun.outcome enum
    - receive_provider_payload/3 runs the REAL provider verify!/normalize seam (no weakened verifier); tenant_id is an opt (no %Plug.Conn{} dependency)
    - import ExUnit.Assertions from the bundled OTP :ex_unit app — no Hex dep added
key-files:
  created:
    - mailglass_inbound/lib/mailglass_inbound/test/ingress.ex
    - mailglass_inbound/lib/mailglass_inbound/test_assertions.ex
    - mailglass_inbound/test/mailglass_inbound/test/ingress_test.exs
    - mailglass_inbound/test/mailglass_inbound/test_assertions_test.exs
  modified: []
decisions:
  - "Captured outcome slot = the normalized execute/2 result map (%{outcome: :accept}, %{outcome: :reject, outcome_reason:}, %{status: :skipped} on duplicate), NOT the raw mailbox atom — so TestAssertions matches the same enum the persisted ExecutionRun.outcome carries and can never drift from what was written."
  - "receive_provider_payload/3 takes tenant_id as an option (default \"fixture-tenant\") instead of resolving it from a %Plug.Conn{} via Tenancy — the driver ships in lib/ and must not depend on Plug (Pitfall 6)."
  - "Postmark verify! is real and unweakened (T-47-11): the driver accepts a :config (basic_auth) opt + a :headers opt so the test supplies a valid Basic authorization header that the real verifier accepts."
metrics:
  duration: ~6m
  completed: 2026-05-24
  tasks: 2
  files: 4
---

# Phase 47 Plan 03: Inbound Driver + Assertions Contract Pair Summary

`MailglassInbound.Test.Ingress` (ITEST-06) drives the real `Persist.persist/2 → Execution.execute/2` (sync) write path and emits the capture tuple `send(self(), {:inbound, msg, outcome, route})`; `MailglassInbound.TestAssertions` (ITEST-01..04) reads that tuple with 4 matcher styles + outcome + routing + negative assertions. Together they form the inbound analog of outbound's `Fake.Storage`→`{:mail,_}`→`TestAssertions` triangle, with the capture seam relocated into the driver because inbound has no delivery row.

## What Was Built

**Task 1 — `MailglassInbound.Test.Ingress`** (`test` faa21c7 → `feat` 6e27951)
- `receive_inbound/2`: builds the handoff from a code-built `%InboundMessage{}`, runs `Persist.persist/2` (taking `:routes`/`:router`/`:repo`/`:evidence`), then `Execution.execute/2` with `source: :fresh` (SYNC), then `send(self(), {:inbound, message, outcome, persisted.route})`, returning `{:ok, %{message, outcome, route, persisted}}`.
- `receive_provider_payload/3`: dispatches to the REAL provider `verify!`/`normalize` seam per provider (mirroring the plug's per-provider dispatch without a `%Plug.Conn{}`), builds the handoff the way `plug.ex:build_handoff/4` does (merging verification facts into evidence), then the same persist+execute+capture chain.
- Never calls `dispatch/2` (only `Execution.execute/2`) — the `dispatch` token appears only in the moduledoc explaining why.
- Captured `outcome` is the normalized `execute/2` result map; documented in the moduledoc.

**Task 2 — `MailglassInbound.TestAssertions`** (`test` f22152a → `feat` f3e133f)
- `assert_inbound_received/0,1` in all 4 matcher styles: no-arg presence, struct/map pattern (`{:%{}, _, _}`), predicate fn (`{:fn, _, _}`), and keyword fallback dispatched at runtime by `__match_keyword__/2` (keys `:subject`, `:from`, `:to`, `:tenant`, `:provider`, `:envelope_recipient`; `:from`/`:to` match the `[%{address:}]` shape; `flunk` on unsupported keys).
- `assert_inbound_{accepted,ignored,rejected,bounced}/0` key off `outcome.outcome` against the locked enum (`:accept`/`:ignore`/`:reject`/`:bounce`).
- `assert_inbound_routed_to/1` → `%{status: :matched, mailbox: ^expected}`; `assert_inbound_no_match/0` → `%{status: :no_match}`.
- `assert_no_inbound_received/0` → `refute_received {:inbound, _, _, _}`.
- `import ExUnit.Assertions` (bundled OTP app — no `:ex_unit` Hex dep). Brand-voice `flunk` messages ("No inbound message received in this test process"), never "Oops!".

## Verification

- `cd mailglass_inbound && mix test test/mailglass_inbound/test/ingress_test.exs test/mailglass_inbound/test_assertions_test.exs --seed 0` → **21 tests, 0 failures**.
  - Ingress: receive_inbound + receive_provider_payload both reach a captured tuple; replay-convergence (Postmark id-dedupe: 3 replays → 1 record + 1 fresh run); cross-provider raw_mime-dedupe (SES: 2 replays → 1 record + 1 fresh run); no-route → `:no_match`.
  - TestAssertions: all 4 matcher styles (positive + a wrong-value/unsupported-key failure each), every outcome assertion (matches its atom + refutes another), both routing assertions (positive + refutation), and `assert_no_inbound_received/0` both paths.
- `cd mailglass_inbound && mix compile --no-optional-deps --warnings-as-errors` → **exit 0** (neither lib/ module references `Oban`/`ExAws`/`Plug.Test`).
- `mix format --check-formatted` → clean (both lib/ + test files).
- Acceptance greps: `send(self(), {:inbound` present in ingress.ex (the capture seam); no `Execution.dispatch`/`dispatch(` call in ingress.ex; `import ExUnit.Assertions` present in test_assertions.ex; no `:ex_unit` dep in mix.exs; no "Oops!" strings.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fetched inbound deps in the fresh worktree**
- **Found during:** Task 1 RED run.
- **Issue:** The worktree had no compiled deps (`mix test` would raise "the dependency is not available").
- **Fix:** Ran `mix deps.get` in `mailglass_inbound/` — fetches only already-declared lockfile deps (NOT a new package install, so the Rule 3 package-install exclusion does not apply). `git status` shows `mix.lock` unchanged.
- **Files modified:** none committed (executors exclude `mix.lock`; orchestrator owns lockfile integration).

**2. [Rule 1 - Test correctness] Postmark provider-payload tests supply real Basic auth**
- **Found during:** Task 1 GREEN run.
- **Issue:** The first draft of the `receive_provider_payload(:postmark, ...)` self-tests omitted Postmark verification credentials; the REAL `Postmark.verify!/3` raised `Mailglass.ConfigError` (basic_auth missing) — exactly as designed (T-47-11 forbids weakening the verifier).
- **Fix:** Added a `:headers` opt to the driver's Postmark `Request` build and a `postmark_opts/0` test helper supplying `config: %{basic_auth: {u, p}}` + a matching `{"authorization", "Basic …"}` header so the real verifier passes. No verifier was weakened.
- **Files modified:** `lib/mailglass_inbound/test/ingress.ex`, `test/mailglass_inbound/test/ingress_test.exs`.
- **Commit:** 6e27951.

### Notes
- The captured-outcome shape decision (normalized `execute/2` result map, not the raw mailbox atom) was Claude's Discretion per D-47-04. It is documented in the `Test.Ingress` moduledoc and consumed consistently by `TestAssertions.__assert_outcome__/1`, which reads `outcome.outcome` against the `ExecutionRun.outcome` enum (`:accept`/`:ignore`/`:reject`/`:bounce`). This is the cleanest choice: the assertions can never drift from the persisted outcome.
- `assert_*` use `assert_received`, which consumes one tuple per call. The self-tests therefore drive one capture per assertion (and two captures when a test needs a positive AND a refutation in the same body). This matches the outbound `Mailglass.TestAssertions` precedent.

## Known Stubs

None. Both modules drive the real production seams (persist, sync execute, provider verify!/normalize); no placeholder/empty/mock data path exists.

## Threat Flags

None. No new network endpoint, auth path, or schema surface is introduced beyond the threat register already documented in the plan (T-47-09..12), all mitigated as designed: the driver writes to the sandboxed test DB (rolled back per test), `receive_provider_payload/3` runs the unweakened real verifier, assertion failure messages embed only caller-supplied matcher values in the adopter's own test output, and the captured tuple carries the message's own `tenant_id`.

## Self-Check: PASSED

- FOUND: `mailglass_inbound/lib/mailglass_inbound/test/ingress.ex` (contains `send(self(), {:inbound`)
- FOUND: `mailglass_inbound/lib/mailglass_inbound/test_assertions.ex` (contains `import ExUnit.Assertions`)
- FOUND: `mailglass_inbound/test/mailglass_inbound/test/ingress_test.exs`
- FOUND: `mailglass_inbound/test/mailglass_inbound/test_assertions_test.exs`
- FOUND commits: faa21c7 (test), 6e27951 (feat), f22152a (test), f3e133f (feat)
- TDD gate sequence verified: `test()` → `feat()` for both Task 1 and Task 2.
