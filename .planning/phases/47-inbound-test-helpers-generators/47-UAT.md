---
status: complete
phase: 47-inbound-test-helpers-generators
source: [47-01-SUMMARY.md, 47-02-SUMMARY.md, 47-03-SUMMARY.md, 47-04-SUMMARY.md]
started: 2026-05-24T11:53:08Z
updated: 2026-05-24T11:58:30Z
verification: self-verified (Claude ran every check; no manual UAT)
---

## Current Test

[testing complete]

## Tests

### 1. Fixtures build a canonical message + real-verifier provider payloads
expected: `Fixtures.build_inbound_message/1` returns a valid `%InboundMessage{}` (non-nil tenant_id, `[%{address:}]` from/to, generated provider_message_id, overridable subject/body); the four `build_*_payload` builders each round-trip through the REAL provider verify!/normalize (SES via primed CertCache, no disk/network; forged SES sig rejected). Self-test: 8 tests, 0 failures.
result: pass
evidence: "Part of the inbound helper run: `mix test fixtures_test.exs test/ingress_test.exs test_assertions_test.exs mailbox_case_test.exs docs_contract_test.exs --seed 0` → 52 tests, 0 failures. Real Postgres INSERTs + raw_mime/provider_message_id dedupe SELECTs observed in query log."

### 2. gen.inbound_router scaffolds a new router
expected: `mix mailglass.gen.inbound_router MyApp.InboundRouter` creates `lib/my_app/inbound_router.ex` with `use MailglassInbound.Router` + a sample `route/2` matching `@route_schema`; valid Elixir; bare name resolves to app namespace.
result: pass
evidence: "Core generator suite: `mix test test/mix/tasks/mailglass.gen.inbound_route_test.exs mailglass.gen.inbound_router_test.exs mailglass.gen.mailbox_test.exs --seed 0` → 15 tests, 0 failures (real Igniter.Test harness: scaffold-shape, bare-name resolution, parse-shape, dry-run)."

### 3. gen.inbound_route inserts a route idempotently
expected: Against an existing router, `mix mailglass.gen.inbound_route <pattern> <Mailbox>` appends a `route/2` after `use`; second run = no change (idempotent); single-statement body handled; result parses.
result: pass
evidence: "Covered by the 15-test core generator suite — run-twice `assert_unchanged`, single-statement-body, no-double-insert cases all green."

### 4. gen.mailbox scaffolds mailbox + route stub + test stub
expected: `mix mailglass.gen.mailbox MyApp.SupportMailbox` creates a mailbox (`@behaviour`, default `process/1` → `:accept`, no auth heuristics), inserts a route stub via the shared helper, and a MailboxCase test stub at the right `_test.exs` path; missing router → actionable notice, no crash.
result: pass
evidence: "Covered by the 15-test core generator suite — mailbox shape, MailboxCase test stub, route-stub-via-helper, idempotency, missing-router notice cases all green. Full `test/mix/tasks/` dir = 39 tests, 0 failures (no regression to outbound gen.mailable)."

### 5. Test driver + assertions drive the real persist/execute path
expected: `Test.Ingress.receive_inbound/2` runs real `Persist.persist → Execution.execute` (sync) + emits capture tuple; `assert_inbound_received/accepted/routed_to` read it; `receive_provider_payload/3` runs the REAL unweakened verifier; replays dedupe; no-route → `:no_match`. Self-test: 21 tests, 0 failures.
result: pass
evidence: "Part of the 52-test inbound helper run (ingress_test.exs + test_assertions_test.exs). Query log shows real fresh/replay runs (Postmark id-dedupe + SES raw_mime-dedupe converging to 1 record + 1 fresh run)."

### 6. MailboxCase template works end-to-end
expected: `use MailglassInbound.MailboxCase` checks out the Ecto sandbox on the app-env repo (no TestRepo literal), imports TestAssertions, aliases Fixtures/Test, sets tenancy, resets CertCache/S3Fetcher.Fake; full drive+assert runs with no DB connection error; snapshots NO app-env key. Self-test passes.
result: pass
evidence: "Part of the 52-test inbound helper run (mailbox_case_test.exs). App-env-repo checkout + no-leak + no-TestRepo-literal assertions green."

### 7. Testing helpers ship to Hex under an ExDoc "Testing" group
expected: `MIX_PUBLISH=true mix hex.build --unpack` includes all four helpers under `lib/` (fixtures.ex, mailbox_case.ex, test_assertions.ex, test/ingress.ex); no `:ex_unit` dep; mix.exs "Testing" ExDoc group lists the four; docs-contract test asserts they're documented.
result: pass
evidence: "hex.build --unpack → all four PRESENT under lib/ (Saved to mailglass_inbound-0.1.0); no `:ex_unit` dep in mix.exs; `Testing:` group at mix.exs:142 lists all four; docs_contract_test.exs green within the 52-test run."

## Cross-cutting gates (verified, not part of the 7 deliverable tests)

- Inbound optional-dep compile: `cd mailglass_inbound && mix compile --no-optional-deps --warnings-as-errors --force` → EXIT 0
- Inbound format: `mix format --check-formatted` on the 4 new lib files → EXIT 0
- Core optional-dep compile: `mix compile --no-optional-deps --warnings-as-errors --force` → EXIT 0
- Core format: `mix format --check-formatted` on the 3 generator sources → EXIT 0

## Summary

total: 7
passed: 7
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none — all 7 deliverables verified green by direct execution]

## Notes (non-blocking, surfaced to maintainer)

- CI coverage: the 3 generator self-tests + the inbound helper tests run in CI today only via `advisory-matrix.yml`'s full `mix test` (push + PR + daily cron). They are NOT in the curated `verify.support_contract.core` allow-list (the `Support Contract Core` ci.yml job runs an explicit file list that omits `test/mix/tasks/*` and the new inbound helper files).
- Branch protection: live `main` returns HTTP 404 "Branch not protected". The REL-10 "Tests (Elixir 1.18 / OTP 27)" required gate from `scripts/setup_branch_protection.sh` is not applied (drift workflow no-ops without `BRANCH_PROTECTION_PAT`). No status check currently blocks merge. Also: that required-check name maps to no current ci.yml job (likely stale after the suite was split into Support Contract Core / Inbound Test / etc.).
