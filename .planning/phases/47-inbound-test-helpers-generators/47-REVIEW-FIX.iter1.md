---
phase: 47-inbound-test-helpers-generators
fixed_at: 2026-05-24T11:03:00Z
review_path: .planning/phases/47-inbound-test-helpers-generators/47-REVIEW.md
iteration: 1
findings_in_scope: 7
fixed: 7
skipped: 0
status: all_fixed
---

# Phase 47: Code Review Fix Report

**Fixed at:** 2026-05-24T11:03:00Z
**Source review:** .planning/phases/47-inbound-test-helpers-generators/47-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 7 (CR-01 + WR-01..WR-06; Info findings IN-01..IN-04 out of scope)
- Fixed: 7
- Skipped: 0

All work was done in an isolated git worktree on branch `gsd-reviewfix/47-…`,
one atomic commit per finding, then fast-forwarded back to `main`. The repo's
pre-existing unrelated dirty files (`.planning/REQUIREMENTS.md`, `CLAUDE.md`,
`MAINTAINING.md`, root `mix.exs`/`mix.lock`, `test/mailglass/docs_contract_test.exs`)
were never staged — each commit used explicit per-path `git add` / `git commit -- <path>`.
The root `mix.lock` drift introduced by `mix deps.get` during testing was reverted
(`git checkout -- mix.lock`) and never committed.

## Fixed Issues

### CR-01: Shipped README / MailboxCase usage example is broken — second assertion always fails

**Files modified:** `mailglass_inbound/README.md`, `mailglass_inbound/lib/mailglass_inbound/mailbox_case.ex`
**Commit:** 67e0828
**Applied fix:** Rewrote the canonical onboarding example in both the README and
the `MailboxCase` moduledoc to drive ONE assertion per capture (matching the
minimal correct form in the review and the discipline already encoded in the
package's own test files). Destructured the `Test.Ingress.receive_inbound/2`
return to show the accept outcome + routed mailbox, dropped the second consuming
`assert_inbound_accepted()`, and added an inline note explaining that each
`assert_inbound_*` consumes the captured tuple (`assert_received`), so a second
assertion needs a second drive.
**Verification:** Tier 1 (re-read) + Tier 2 (`Code.string_to_quoted!` parse-check
on `mailbox_case.ex`). Documentation-only; no test asserts the example text.

### WR-01: Version metadata drift across mix.exs, `@since` tags, and README deps

**Files modified:** `mailglass_inbound/lib/mailglass_inbound/test_assertions.ex`, `mailglass_inbound/docs/api_stability.md`, `mailglass_inbound/README.md`, `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs`
**Commit:** f912ffa
**Applied fix:** Resolved to the internally consistent published truth `0.1.0`
(the package's `mix.exs @version`, left unchanged as the source of truth):
- `TestAssertions` `@doc since: "0.2.0"` → `"0.1.0"` (all occurrences).
- `api_stability.md` `@since 0.2.0` for `SignatureError` and `S3FetchError` → `0.1.0`
  (exactly the two references WR-01 names).
- README install pins `{:mailglass_inbound, "~> 0.3.2"}` → `~> 0.1`, and
  `{:mailglass, "~> 0.3.2"}` → `~> 1.0` (matching the core `@version "1.0.0"` and
  the `{:mailglass, "== 1.0.0"}` publish pin in inbound `mix.exs`).
- Added a docs-contract test asserting the README `mailglass_inbound` pin's
  `major.minor` equals `Mix.Project.config()[:version]`, so the pin can never
  drift from the artifact again.

Scope note: other `@doc since: "0.2.0"` / `"0.5.0"` tags exist in non-phase-47
modules (`signature_error.ex`, `s3_fetch_error.ex`, `mime.ex`, `telemetry.ex`,
`optional_deps.ex`, `mailglass_inbound.ex`, …). WR-01's `File:` list scopes the
fix to the `TestAssertions` macros, the two `api_stability.md` references, and
the README pins; those source-module tags are pre-existing and out of this
finding's scope, so they were intentionally left untouched.
**Verification:** Tier 1 + Tier 2 (parse-check on both `.ex` files) + ran
`mix test test/mailglass_inbound/docs_contract_test.exs --seed 0` → 13 tests,
0 failures (the new pin-tracking assertion passes; clean compile, no warnings).

### WR-02: `TestAssertions` outcome/routing assertions document "most recent" but read FIFO (oldest)

**Files modified:** `mailglass_inbound/lib/mailglass_inbound/test_assertions.ex`
**Commit:** 0955571
**Applied fix:** Replaced "the most recent captured inbound" with accurate
language across all six outcome/routing assertion `@doc`s
(`assert_inbound_accepted/ignored/rejected/bounced`, `assert_inbound_routed_to`,
`assert_inbound_no_match`): "the next captured inbound" plus a note that
`assert_received` is FIFO (oldest unconsumed) and consumes the matched tuple, so
drive one message per assertion. This pairs with the CR-01 one-drive-per-assertion
discipline.
**Verification:** Tier 1 + Tier 2 (parse-check) + confirmed zero remaining
"most recent" occurrences. Documentation-only.

### WR-03: `gen.mailbox` test scaffold's commented hint references undefined functions and a non-existent option

**Files modified:** `lib/mix/tasks/mailglass.gen.mailbox.ex`
**Commit:** 6e44f97
**Applied fix:** Threaded the generated `mailbox` module into `test_stub_body/2`
and rewrote the commented hint to the actual capture lane the helpers exist for:
`Fixtures.build_inbound_message(subject: "hi")` →
`Test.Ingress.receive_inbound(message, routes: [%MailglassInbound.Router.Route{mailbox: <GeneratedMailbox>}])`
→ `assert_inbound_accepted()`, with the one-assertion-per-drive note. This fixes
all three defects: undefined `build_inbound_message/1` (now `Fixtures.`-qualified),
the non-existent `:recipient` option (now uses the real `:subject`/routes lane),
and the undefined bare `process/1` (replaced by the driven capture + assertion).
**Verification:** Tier 1 + Tier 2 (parse-check) + ran
`mix test test/mix/tasks/mailglass.gen.mailbox_test.exs --seed 0` → 6 tests,
0 failures. The generator emits the hint commented out, so the runnable
correctness is the load-bearing aspect; generator tests confirm generation works.

### WR-04: `__match_keyword__` emits a self-contradictory error for non-binary `:from`/`:to`

**Files modified:** `mailglass_inbound/lib/mailglass_inbound/test_assertions.ex`, `mailglass_inbound/test/mailglass_inbound/test_assertions_test.exs`
**Commit:** 8a337ee
**Applied fix:** Added explicit `{:from, v}` / `{:to, v}` clauses (after the
`is_binary` guards, before the catch-all) that flunk with
"from/to matcher expects a bare address string, got: …" so a non-binary value
(e.g. the address-list shape the struct stores) no longer falls through to the
"Unsupported matcher key: :from. Supported: … :from …" catch-all message that
listed `:from` as both unsupported and supported. Added a regression test
asserting the accurate message and the absence of the contradictory text for
both `:from` and `:to`.
**Verification:** Tier 1 + Tier 2 (parse-check) + ran
`mix test test/mailglass_inbound/test_assertions_test.exs --seed 0` → 16 tests,
0 failures. This finding touched runtime matching logic; the new regression test
empirically confirms the new clauses fire with the correct message (not a flag
needing human verification — behavior is asserted by the suite).

### WR-05: `Test.Ingress.receive_provider_payload(:ses, …)` primes the process-global `CertCache` ETS but never resets it

**Files modified:** `mailglass_inbound/lib/mailglass_inbound/fixtures.ex`, `mailglass_inbound/lib/mailglass_inbound/test/ingress.ex`
**Commit:** 8ccf099
**Applied fix:** Chose the review's preferred documentation fix (keeps the helper
free of an `:ex_unit` runtime dependency at call time). Added a prominent
`{: .warning}` admonition to `Fixtures.build_ses_sns_payload/1` and a "SES
cross-test hygiene" section to the `Test.Ingress` moduledoc, both stating that
SES fixtures prime the process-global `Mailglass.Webhook.Providers.SES.CertCache`
(shared across concurrent async tests, 24h non-evicting entries) and that suites
not using `MailglassInbound.MailboxCase` must `setup do: …CertCache.reset()`
between tests. Noted that `MailboxCase` already resets it and the
Postmark/SendGrid/Mailgun lanes touch no process-global state.
**Verification:** Tier 1 + Tier 2 (parse-check on both `.ex` files) + clean
`mix compile --warnings-as-errors` on the inbound package. Documentation-only.

### WR-06: Documented `Test.Ingress` raw_mime-dedupe path for SendGrid/SES via `receive_inbound/2` is untested

**Files modified:** `mailglass_inbound/test/mailglass_inbound/test/ingress_test.exs`
**Commit:** 5db3bf8
**Applied fix:** Added two tests to the `receive_inbound/2` describe block:
1. A SendGrid convergence test driving the same canonical message + identical
   `evidence: %{raw_mime: ...}` three times, asserting `record_count() == 1` and
   `fresh_run_count() == 1` (proves the documented `md5(raw_mime)` dedupe path
   converges on replay — the existing convergence proofs only used
   `provider_message_id` dedupe or `receive_provider_payload`).
2. A discrimination test: two distinct `raw_mime` payloads (with `provider_message_id: nil`
   to model real SendGrid, so the only discriminator is the fingerprint) produce
   two records and two fresh runs.

Implementation note discovered while writing the test: a unique index exists on
`(tenant_id, provider, provider_message_id) WHERE provider_message_id IS NOT NULL`
(`add_postmark_ingress_idempotency` migration). The discrimination test therefore
uses `provider_message_id: nil` so the second insert is gated purely by the
raw_mime fingerprint, not the provider-id index. The convergence test reuses a
single message (auto-id) safely because the raw_mime dedupe short-circuits to
`:duplicate` before any second insert.
**Verification:** Tier 1 + Tier 2 (parse-check) + ran
`mix test test/mailglass_inbound/test/ingress_test.exs --seed 0` → 8 tests,
0 failures (6 original + 2 new). Both new tests pass, proving the contract holds
and the fingerprint discriminates.

## Post-fix verification (cross-file)

Ran all four touched inbound test files together:
`mix test test_assertions_test.exs test/ingress_test.exs mailbox_case_test.exs docs_contract_test.exs --seed 0`
→ **40 tests, 0 failures.** Generator suite
`mix test test/mix/tasks/mailglass.gen.mailbox_test.exs --seed 0` → 6 tests, 0 failures.
The known intermittent inbound flake (DB pool tcp recv:closed) was not hit;
`--seed 0` was used throughout for a deterministic signal.

Which findings were verified green vs. documentation-only:
- Code/test-behavior verified green by the suite: WR-01 (docs-contract test),
  WR-03 (generator test), WR-04 (matcher regression test), WR-06 (dedupe tests).
- Documentation-only (parse-checked + compiled, no test exercises the prose):
  CR-01, WR-02, WR-05.

## Skipped Issues

None — all 7 in-scope findings were fixed.

(Info findings IN-01..IN-04 were explicitly out of scope for this `critical_warning`
run and were not attempted.)

---

_Fixed: 2026-05-24T11:03:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
