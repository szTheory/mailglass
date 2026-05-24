---
phase: 47
slug: inbound-test-helpers-generators
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-23
validated: 2026-05-24
---

# Phase 47 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from the `## Validation Architecture` section of `47-RESEARCH.md`.
> Audited retroactively 2026-05-24 — all 11 requirements have green automated coverage.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir, OTP 27) + `Igniter.Test` for generator self-tests |
| **Config file** | `mailglass_inbound/test/test_helper.exs` (+ root `mailglass/test/test_helper.exs` for generators) |
| **Quick run command** | `cd mailglass_inbound && mix test test/mailglass_inbound/test_assertions_test.exs --seed 0` (per-file, deterministic) |
| **Full suite command** | `cd mailglass_inbound && mix test test/mailglass_inbound/{fixtures,test_assertions,mailbox_case}_test.exs test/mailglass_inbound/test/ingress_test.exs --seed 0` (helpers) + `mix test test/mix/tasks/mailglass.gen.inbound_route_test.exs test/mix/tasks/mailglass.gen.inbound_router_test.exs test/mix/tasks/mailglass.gen.mailbox_test.exs --seed 0` (generators, from repo root) |
| **Estimated runtime** | ~30–60 seconds per package |

> **Flake note (project memory):** full `mailglass_inbound` `mix test` intermittently fails with a DB pool `tcp recv:closed` via the Phase 45 1000-iter property test. Use `--seed 0` or scope per-file for deterministic green. Bare root `mix test` has ~57 unrelated Oban failures in worktrees — scope generator tests to `test/mix/tasks/`.

---

## Sampling Rate

- **After every task commit:** Run the relevant per-file quick command
- **After every plan wave:** Run the full suite command for the affected package
- **Before `/gsd:verify-work`:** Full suite must be green (scoped, `--seed 0`)
- **Max feedback latency:** ~60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| Fixtures builders | 47-01 | 1 | ITEST-07 | T-47-01..04 | No key/cert on disk; every payload round-trips the REAL provider `verify!`/`normalize` (SES via primed `CertCache`); forged SES signature rejected | unit | `cd mailglass_inbound && mix test test/mailglass_inbound/fixtures_test.exs --seed 0` | ✅ | ✅ green |
| Test.Ingress driver | 47-03 | 2 | ITEST-06 | T-47-09..12 | Drives real `Persist.persist/2 → Execution.execute/2` (sync); unweakened Postmark `verify!`; sandbox-rolled-back writes | unit | `cd mailglass_inbound && mix test test/mailglass_inbound/test/ingress_test.exs --seed 0` | ✅ | ✅ green |
| TestAssertions — 4 matcher styles | 47-03 | 2 | ITEST-01 | T-47-09..12 | Positive + wrong-value/unsupported-key negative for no-arg / keyword / predicate / pattern styles | unit | `cd mailglass_inbound && mix test test/mailglass_inbound/test_assertions_test.exs --seed 0` | ✅ | ✅ green |
| TestAssertions — outcome assertions | 47-03 | 2 | ITEST-02 | T-47-09..12 | `assert_inbound_{accepted,ignored,rejected,bounced}` each match their atom + refute another (locked enum) | unit | `cd mailglass_inbound && mix test test/mailglass_inbound/test_assertions_test.exs --seed 0` | ✅ | ✅ green |
| TestAssertions — routing assertions | 47-03 | 2 | ITEST-03 | T-47-09..12 | `assert_inbound_routed_to/1` + `assert_inbound_no_match/0` positive + refutation | unit | `cd mailglass_inbound && mix test test/mailglass_inbound/test_assertions_test.exs --seed 0` | ✅ | ✅ green |
| TestAssertions — negative path | 47-03 | 2 | ITEST-04 | T-47-09..12 | `assert_no_inbound_received/0` both paths (no capture passes; capture present fails) | unit | `cd mailglass_inbound && mix test test/mailglass_inbound/test_assertions_test.exs --seed 0` | ✅ | ✅ green |
| MailboxCase template | 47-04 | 3 | ITEST-05 | T-47-13..16 | App-env repo checkout (no `TestRepo` literal); no app-env leak across case run; `CertCache`/`S3Fetcher.Fake` reset each setup | unit | `cd mailglass_inbound && mix test test/mailglass_inbound/mailbox_case_test.exs --seed 0` | ✅ | ✅ green |
| gen.mailbox | 47-02 | 1 | IGEN-01 | T-47-05, T-47-08 | Structured AST route insertion (no eval); neutral `:accept` default (no auth heuristics); missing-router notice | generator (`Igniter.Test`) | `mix test test/mix/tasks/mailglass.gen.mailbox_test.exs --seed 0` | ✅ | ✅ green |
| gen.inbound_router | 47-02 | 1 | IGEN-02 | T-47-05 | Scaffold-shape + bare-name resolution + parse-shape | generator (`Igniter.Test`) | `mix test test/mix/tasks/mailglass.gen.inbound_router_test.exs --seed 0` | ✅ | ✅ green |
| gen.inbound_route (idempotent) | 47-02 | 1 | IGEN-03 | T-47-05..07 | Run-twice `assert_unchanged`; single-statement-body promotion; no double-insert | generator (`Igniter.Test`) | `mix test test/mix/tasks/mailglass.gen.inbound_route_test.exs --seed 0` | ✅ | ✅ green |
| `--dry-run` all generators | 47-02 | 1 | IGEN-04 | T-47-05..07 | `--dry-run` accepted as free global flag, computes diff, writes nothing (Igniter framework contract; absent from every option schema) | generator (`Igniter.Test`) | `mix test test/mix/tasks/mailglass.gen.inbound_route_test.exs test/mix/tasks/mailglass.gen.inbound_router_test.exs test/mix/tasks/mailglass.gen.mailbox_test.exs --seed 0` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

**Research-mandated invariants — all present and green:**
- **Generator idempotency:** run-twice `assert_unchanged` on the second run — `mailglass.gen.inbound_route_test.exs:67/83/92`, `mailglass.gen.mailbox_test.exs:65`. ✅
- **No-optional-deps compile gate:** `cd mailglass_inbound && mix compile --no-optional-deps --warnings-as-errors` → exit 0 (the four helpers + generators hard-require no optional deps). ✅
- **Fixture round-trip:** every `Fixtures`-built payload feeds the REAL provider `verify!`/`normalize` seam; the signed-SNS fixture verifies through the real `SES` verifier via primed `CertCache`. ✅
- **Self-test of assertions:** matchers assert on both positive and negative (`assert_no_inbound_received`) paths. ✅

---

## Wave 0 Requirements

All self-test files exist on disk and run green (no Wave-0 backfill needed — tests shipped with the implementation under TDD):

- [x] `mailglass_inbound/test/mailglass_inbound/test_assertions_test.exs` — self-tests for ITEST-01..04
- [x] `mailglass_inbound/test/mailglass_inbound/mailbox_case_test.exs` — MailboxCase setup/teardown coverage (ITEST-05)
- [x] `mailglass_inbound/test/mailglass_inbound/test/ingress_test.exs` — Test.Ingress persist→sync-execute path (ITEST-06)
- [x] `mailglass_inbound/test/mailglass_inbound/fixtures_test.exs` — fixture round-trips through real verifiers (ITEST-07)
- [x] `test/mix/tasks/mailglass.gen.mailbox_test.exs` — `Igniter.Test` create + idempotency (IGEN-01)
- [x] `test/mix/tasks/mailglass.gen.inbound_router_test.exs` — `Igniter.Test` create scaffold (IGEN-02)
- [x] `test/mix/tasks/mailglass.gen.inbound_route_test.exs` — `Igniter.Test` source-edit + run-twice `assert_unchanged` + `--dry-run` (IGEN-03/04)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `--dry-run` console preview readability | IGEN-04 | Igniter's `--dry-run` output is a human preview; the FACT of no-write is automatable via `assert_unchanged`, but the readability of the diff is a human read | Run `mix mailglass.gen.inbound_route ... --dry-run` and confirm the patch preview is legible |

*Everything else has automated verification.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-05-24 — Nyquist-compliant (0 gaps).

---

## Validation Audit 2026-05-24

| Metric | Count |
|--------|-------|
| Requirements audited | 11 |
| COVERED (green) | 11 |
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

**Method:** Reconstructed the requirement→test map from `47-0{1..4}-SUMMARY.md`, confirmed each of the 11 requirements (ITEST-01..07, IGEN-01..04) maps to a test file on disk, and ran both scoped suites:
- Inbound helpers (`fixtures` + `test_assertions` + `mailbox_case` + `test/ingress`): **39 tests, 0 failures** (`--seed 0`).
- Generators (`inbound_route` + `inbound_router` + `mailbox`): **15 tests, 0 failures** (`--seed 0`).
- No-optional-deps compile gate (inbound): **exit 0**.

All four research-mandated invariants (generator idempotency, no-optional-deps gate, fixture round-trip, assertion positive+negative self-test) are present and green. No test generation was required; the phase shipped its self-tests under TDD.
