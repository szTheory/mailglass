---
phase: 47
slug: inbound-test-helpers-generators
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-23
---

# Phase 47 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from the `## Validation Architecture` section of `47-RESEARCH.md`.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir, OTP 27) + `Igniter.Test` for generator self-tests |
| **Config file** | `mailglass_inbound/test/test_helper.exs` (+ root `mailglass/test/test_helper.exs` for generators) |
| **Quick run command** | `cd mailglass_inbound && mix test test/mailglass_inbound/test_assertions_test.exs --seed 0` (per-file, deterministic) |
| **Full suite command** | `cd mailglass_inbound && mix test --seed 0` (inbound) + `cd .. && mix test test/mix/tasks/ --seed 0` (generators) |
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
| (planner fills) | — | — | ITEST-/IGEN- | — | — | unit | `mix test ...` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

> The planner populates this map from RESEARCH.md's Validation Architecture. Mandatory entries that MUST appear (per research):
> - **Generator idempotency:** each generator self-test runs the task **twice** and asserts `assert_unchanged` on the second run (`Igniter.Test`).
> - **No-optional-deps compile gate:** `mix compile --no-optional-deps --warnings-as-errors` passes (the four helpers + generators must not hard-require optional deps).
> - **Fixture round-trip:** each `Fixtures`-built provider payload feeds the REAL provider `verify!`/`normalize` seam and round-trips green (the signed-SNS fixture verifies through the real `SES` verifier via primed `CertCache`).
> - **Self-test of assertions:** `TestAssertions` matchers assert on both the positive and negative (`assert_no_inbound_received`) paths.

---

## Wave 0 Requirements

- [ ] `mailglass_inbound/test/mailglass_inbound/test_assertions_test.exs` — self-tests for ITEST-01..04
- [ ] `mailglass_inbound/test/mailglass_inbound/mailbox_case_test.exs` — MailboxCase setup/teardown coverage (ITEST-05)
- [ ] `mailglass_inbound/test/mailglass_inbound/test/ingress_test.exs` — Test.Ingress persist→sync-execute path (ITEST-06)
- [ ] `mailglass_inbound/test/mailglass_inbound/fixtures_test.exs` — fixture round-trips through real verifiers (ITEST-07)
- [ ] `mailglass/test/mix/tasks/mailglass_gen_mailbox_test.exs` — `Igniter.Test` create + idempotency (IGEN-01)
- [ ] `mailglass/test/mix/tasks/mailglass_gen_inbound_router_test.exs` — `Igniter.Test` create + idempotency (IGEN-02)
- [ ] `mailglass/test/mix/tasks/mailglass_gen_inbound_route_test.exs` — `Igniter.Test` source-edit + run-twice `assert_unchanged` (IGEN-03/04)

*Planner refines exact file paths against the chosen module layout.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| `--dry-run` console preview readability | IGEN-04 | Igniter's `--dry-run` output is a human preview; the FACT of no-write is automatable via `assert_unchanged`, but the readability of the diff is a human read | Run `mix mailglass.gen.inbound_route ... --dry-run` and confirm the patch preview is legible |

*Everything else has automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
