# Phase 47: Inbound Test Helpers + Generators - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-23
**Phase:** 47-inbound-test-helpers-generators
**Mode:** assumptions
**Areas analyzed:** Module packaging, Test.Ingress fake-provider seam, Generators (Igniter), SES SNS signed fixture

## Assumptions Presented

### Area 1 — Module packaging (lib vs test/support, which package)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| All four helpers (TestAssertions, MailboxCase, Test.Ingress, Fixtures) ship in `mailglass_inbound/lib/`, packaged to Hex | Likely | `mailglass_inbound/mix.exs:113` files manifest; `lib/mailglass/test_assertions.ex` ships in lib but `test/support/mailer_case.ex` does not; ITEST-05 requires adopter `use MailglassInbound.MailboxCase`; Swoosh ships TestAssertions only |

### Area 2 — Test.Ingress fake-provider seam
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Test.Ingress calls `Persist.persist/2` → sync `Execution.execute/2` directly, reusing existing opt seams; no faked conn, no new `trigger_event/3` | Confident | `inbound_idempotency_convergence_test.exs:99-102`; `execution.ex:14-60` (async dispatch vs sync execute); plug opt seams `plug.ex:442-447,488-493`; `ses.ex:265-275` |

### Area 3 — Generators (Igniter source-editing vs file writes, placement)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Three Igniter mix tasks in core `mailglass/lib/mix/tasks/`; gen.mailbox/gen.inbound_router create, gen.inbound_route zipper-edits idempotently; `--dry-run` via Igniter built-in | Likely | All 12 mix tasks in core; `mailglass_inbound/mix.exs:65-92` no igniter dep, root `mix.exs:164` has it; `mailglass.gen.mailable.ex:10-61` (create); `mailglass.upgrade.v0_2.ex:33-88` (zipper + dry-run); `router.ex:39-72` DSL target |

### Area 4 — SES SNS signed fixture
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `Fixtures.build_ses_sns_payload/1` mints RSA keypair in code, signs canonical SNS, primes real `CertCache.put/3`; no `.pem`, no `CertCache.Fake` | Confident | `ses_provider_test.exs:26-352` (working signed-fixture helpers); `webhook_fixtures.ex:194-246` (identical outbound approach); filesystem search confirms no `CertCache.Fake` exists |

## ROADMAP Corrections Surfaced (verified against code)

- **`:async_execution_impl` does not exist.** Outbound HI-01 snapshots
  `:async_adapter`/`:async_adapter_impl` (`mailer_case.ex:120-204`); inbound uses
  `OptionalDeps.Oban.runner()` (`execution.ex:21`) with no global `_impl` key.
  MailboxCase's job is to make sync `execute/2` the default test path, not snapshot
  a nonexistent key. → D-47-12.
- **`SES.CertCache.Fake` does not exist** (ROADMAP "hardest sub-task" assumed it).
  Real path is in-memory keypair + real `CertCache.put/3`. → D-47-13.

## Corrections Made

No corrections — all assumptions confirmed (single "Yes, proceed" confirmation).

## External Research

Not performed in discuss-phase. Two repo-internal research items captured in
CONTEXT.md canonical_refs for the plan-phase researcher:
1. Igniter 0.8 source-editing idiom for idempotent `route/2` insertion (vendored
   at `mailglass_inbound/deps/igniter/`).
2. Confirm the exact global app-env MailboxCase must snapshot (SES
   `:s3_fetcher`/`:s3_retry_opts`, Oban testing-mode global) — no
   `:async_execution_impl` key exists.
