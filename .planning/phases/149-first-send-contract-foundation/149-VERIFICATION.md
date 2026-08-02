---
phase: 149-first-send-contract-foundation
verified: 2026-08-02T18:52:21Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 149: First-Send Contract Foundation Verification Report

**Phase Goal:** A clean default-tenant adopter can send one valid, correctly rendered message while invalid tenancy, recipient, and body shapes fail before side effects.
**Verified:** 2026-08-02T18:52:21Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | An unstamped `SingleTenant` caller can send synchronously or choose durable async delivery owned by `"default"`. | ✓ VERIFIED | `Preflight.run/1` resolves only `SingleTenant` via `Tenancy.current/0` and writes `tenant_id` before downstream stages ([preflight.ex](/Users/jon/projects/mailglass/lib/mailglass/outbound/preflight.ex:7)). `do_send/2` and `do_deliver_later/2` invoke it first ([outbound.ex](/Users/jon/projects/mailglass/lib/mailglass/outbound.ex:286), [outbound.ex](/Users/jon/projects/mailglass/lib/mailglass/outbound.ex:349)). Fresh focused tests exercise persisted and Fake-adapter-visible sync/async ownership. |
| 2 | Custom tenancy fails closed when context is missing, blank, invalid, or absent in a worker. | ✓ VERIFIED | Non-`SingleTenant` resolvers use strict `Tenancy.tenant_id!/0`; blank ids raise `%TenancyError{type: :unstamped}` ([preflight.ex](/Users/jon/projects/mailglass/lib/mailglass/outbound/preflight.ex:30)). Fresh tests cover missing, blank, valid, and lost task context with zero persistence/adapter effects. |
| 3 | Exactly one valid recipient across `to`/`cc`/`bcc` is accepted; zero or multi-recipient shapes reject with a typed preflight error before side effects. | ✓ VERIFIED | `Message.sole_recipient/1` preserves the native field and rejects every count other than one ([message.ex](/Users/jon/projects/mailglass/lib/mailglass/message.ex:127)); preflight maps failure to `:preflight_rejected` ([preflight.ex](/Users/jon/projects/mailglass/lib/mailglass/outbound/preflight.ex:48)). Fresh tests cover zero, duplicate, cross-field, malformed, sync, async, and field-aware idempotency cases. |
| 4 | Body semantics and both renderer settings have the same observable effect in direct render, sync send, async send, and preview. | ✓ VERIFIED | `Renderer.render/2` reads `Config.renderer/0` once ([renderer.ex](/Users/jon/projects/mailglass/lib/mailglass/renderer.ex:64)); explicit nonblank text is retained and generated text is limited to HTML-only messages ([renderer.ex](/Users/jon/projects/mailglass/lib/mailglass/renderer.ex:97)). Preview calls the same renderer ([preview_live.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/preview_live.ex:833)). Fresh core and admin support-contract runs exercised all consumers. |
| 5 | Unsupported envelope/body content fails explicitly before a delivery row or job exists; recipient/content is never silently dropped. | ✓ VERIFIED | Preflight rejects malformed envelopes and any unsupported supplied body component before rendering ([preflight.ex](/Users/jon/projects/mailglass/lib/mailglass/outbound/preflight.ex:48), [preflight.ex](/Users/jon/projects/mailglass/lib/mailglass/outbound/preflight.ex:68)). Fresh sync/async tests assert typed errors and unchanged rows/jobs/tasks/Fake deliveries. The review's former HTML-plus-invalid-text failure is covered by tests and fixed in the source. |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/mailglass/outbound/preflight.ex` | Pure tenancy, envelope, and body gate | ✓ VERIFIED | Exists; substantive validation; invoked first by sync, async, and batch preflight. |
| `lib/mailglass/outbound.ex` | Shared outbound convergence and field-aware idempotency | ✓ VERIFIED | Entry points call preflight before renderer/effects; idempotency includes recipient field. |
| `lib/mailglass/renderer.ex` + `lib/mailglass/config.ex` | Single renderer-owned precedence/config implementation | ✓ VERIFIED | Renderer reads validated config and controls text/CSS behavior. |
| `mailglass_admin/lib/mailglass_admin/preview_live.ex` | Preview consumes production renderer | ✓ VERIFIED | `build_and_render/3` calls `Mailglass.Renderer.render/1`. |
| Phase tests and first-send documentation | Regression proof and accurate adopter contract | ✓ VERIFIED | All declared artifacts exist, are substantive, and their fresh support/docs checks passed. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `Outbound` | `Outbound.Preflight` | `do_send/2`, `do_deliver_later/2`, `preflight_single/1` | ✓ WIRED | Manual source trace confirms `Preflight.run/1` is the first `with` stage at all three call sites. |
| `Preflight` | `Tenancy` | resolver-aware `current/0` / `tenant_id!/0` | ✓ WIRED | Source selects default only for `SingleTenant`; custom resolver remains strict. |
| `Renderer` | `Config` | `Config.renderer/0` | ✓ WIRED | Read once per render before body/config transformation. |
| `PreviewLive` | `Renderer` | `Mailglass.Renderer.render/1` | ✓ WIRED | Production preview directly delegates to the core renderer. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `Outbound.Preflight` | `tenant_id` | configured resolver / strict process context | Normalized value is persisted and sent to the Fake adapter in exercised sync/async tests. | ✓ FLOWING |
| `Outbound` | recipient/body | Native Swoosh email fields | Validated native field/body reaches persistence and adapter; rejected inputs create no durable/job/provider effect. | ✓ FLOWING |
| `PreviewLive` | rendered HTML/text | `Mailglass.Renderer.render/1` result | LiveView parity test inspects HTML/Text output under both renderer configurations. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| FIRST-01 through FIRST-07 core behavior, including former review fixes | `mix test test/mailglass/outbound/preflight_test.exs test/mailglass/outbound/deliver_later_test.exs test/mailglass/renderer_test.exs test/mailglass/outbound_test.exs test/mailglass/outbound/deliver_many_test.exs test/mailglass/tenancy_test.exs --warnings-as-errors` | 119 tests, 0 failures | ✓ PASS |
| Required core support and docs contract | `mix verify.support_contract.core && mix mailglass.docs.check` | 1 property, 195 tests, 0 failures, 1 skipped; docs check OK | ✓ PASS |
| Required preview parity/support contract | `cd mailglass_admin && mix verify.support_contract.admin` | 144 tests, 0 failures | ✓ PASS |
| Boundary and compilation integrity | `mix compile --warnings-as-errors`; `mix test test/mailglass/boundary_test.exs --warnings-as-errors` | Compile clean; 7 tests, 0 failures | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| FIRST-01 | 149-01, 149-04 | Unstamped `SingleTenant` sync/async ownership is `"default"`. | ✓ SATISFIED | Public-path persisted/Fake sync and async tests pass fresh. |
| FIRST-02 | 149-01, 149-04 | Custom tenancy is fail-closed. | ✓ SATISFIED | Strict resolver source plus missing/blank/lost-context tests pass fresh. |
| FIRST-03 | 149-02, 149-04 | Exactly one native recipient total is accepted. | ✓ SATISFIED | Cardinality, malformed-envelope, sole-field, and idempotency regressions pass fresh. |
| FIRST-04 | 149-02, 149-04 | Rejection precedes render, limits, persistence, jobs, and dispatch. | ✓ SATISFIED | Negative-control sync/async tests pass fresh. |
| FIRST-05 | 149-03, 149-04 | Explicit plaintext/text-only/HTML-only semantics hold. | ✓ SATISFIED | Direct, sync, and async rendering assertions pass fresh. |
| FIRST-06 | 149-03, 149-04 | Plaintext/CSS settings are consistent across all consumers. | ✓ SATISFIED | Core and LiveView parity tests pass fresh. |
| FIRST-07 | 149-02, 149-04 | Unsupported shapes yield typed errors before durable effects. | ✓ SATISFIED | Invalid-body/envelope sync/async zero-effect tests pass fresh. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `docs/api_stability.md` | 1448 | “v0.5 hook reserved — not yet implemented” | ℹ️ Info | Predates Phase 149 (`a5e016ec`, 2026-04-23), explicitly scopes a future List-Unsubscribe hook, and is unrelated to this phase's contract. No phase-introduced stub/debt marker found. |

## Gaps Summary

No gaps found. The two blockers in `149-REVIEW.md` were independently checked in the final source and covered by fresh tests: unsupported plaintext alongside valid HTML now rejects before effects, and `to`/`cc`/`bcc` participate separately in the idempotency key.

---

_Verified: 2026-08-02T18:52:21Z_
_Verifier: the agent (gsd-verifier)_
