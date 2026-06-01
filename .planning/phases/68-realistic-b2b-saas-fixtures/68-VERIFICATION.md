---
phase: 68-realistic-b2b-saas-fixtures
verified: 2026-06-01T21:57:45Z
status: passed
score: 5/5 must-haves verified
overrides_applied: 0
---

# Phase 68: realistic-b2b-saas-fixtures Verification Report

**Phase Goal:** Realistic B2B SaaS fixtures: deterministic outbound/inbound/suppression/replay/mailers scenarios for demo confidence.
**Verified:** 2026-06-01T21:57:45Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Maintainer can run `mix demo.reset` and get the same named Northstar outbound and inbound corpus on every run. | ✓ VERIFIED | `reference/demo_app/mix.exs` defines `"demo.reset": ["run priv/repo/seeds.exs"]`; `reference/demo_app/priv/repo/seeds.exs` calls `MailglassDemo.DemoData.reset!`; determinism asserted in `reference/demo_app/test/mailglass_demo/demo_data_reset_test.exs`. |
| 2 | Outbound operator surfaces have deterministic invite, auth, billing, alert, suppression, webhook, and replayable evidence rows. | ✓ VERIFIED | `reference/demo_app/lib/mailglass_demo/demo_data.ex` seeds exact outbound provider IDs, webhook IDs (`demo-receipt-delivery`, `demo-usage-bounce`), suppression-linked `incident_update`, and event lineage metadata. |
| 3 | Inbound operator surfaces have deterministic accept, bounce, reject, no-match, and replay lineage rows that preserve stored-truth semantics. | ✓ VERIFIED | `reference/demo_app/lib/mailglass_demo/demo_data.ex` uses one record/evidence per story and `InboundRecords.insert_execution_run/2` for fresh/replay matrix; reset test asserts exact matrix in `reference/demo_app/test/mailglass_demo/demo_data_reset_test.exs`. |
| 4 | Preview surfaces expose deterministic invite/auth, billing, and operational scenarios with realistic B2B SaaS Ops copy. | ✓ VERIFIED | `reference/demo_app/lib/mailglass_demo_web/mailers/account_mailer.ex`, `billing_mailer.ex`, and `operations_mailer.ex` contain required deterministic fields and exact required subjects/tokens in HTML/text bodies. |
| 5 | Later browser evidence can identify preview scenarios from public scenario keys and message content without relying on DOM internals. | ✓ VERIFIED | `reference/demo_app/test/mailglass_demo/mailer_preview_scenarios_test.exs` asserts `preview_props` order, `message.mailable_function`, and `message.swoosh_email` subject/body tokens for all 6 scenarios at public message seam. |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `reference/demo_app/lib/mailglass_demo/demo_data.ex` | Deterministic Northstar fixture corpus | ✓ VERIFIED | Exists, substantive seed logic, called by seeds path. |
| `reference/demo_app/test/mailglass_demo/demo_data_reset_test.exs` | Reset determinism + scenario completeness assertions | ✓ VERIFIED | Exists, substantive snapshot assertions on counts/IDs/matrix. |
| `test/mailglass/demo_data_test.exs` | Repo-root quick validation wrapper | ✓ VERIFIED | Exists, runs nested demo-app mix commands and wildcard tests. |
| `reference/demo_app/lib/mailglass_demo_web/mailers/account_mailer.ex` | Account preview scenarios | ✓ VERIFIED | Exists, deterministic `preview_props`, exact subjects, public `Message` pipeline. |
| `reference/demo_app/lib/mailglass_demo_web/mailers/billing_mailer.ex` | Billing preview scenarios | ✓ VERIFIED | Exists, deterministic props/tokens, `Message.put_function`. |
| `reference/demo_app/lib/mailglass_demo_web/mailers/operations_mailer.ex` | Operations preview scenarios | ✓ VERIFIED | Exists, deterministic props/tokens, `Message.put_function`. |
| `reference/demo_app/test/mailglass_demo/mailer_preview_scenarios_test.exs` | Scenario contract coverage | ✓ VERIFIED | Exists, covers all 6 functions and public message fields. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `reference/demo_app/mix.exs` | `reference/demo_app/priv/repo/seeds.exs` | `"demo.reset" alias` | ✓ WIRED | Alias literal present: `"demo.reset": ["run priv/repo/seeds.exs"]`. |
| `reference/demo_app/priv/repo/seeds.exs` | `reference/demo_app/lib/mailglass_demo/demo_data.ex` | `MailglassDemo.DemoData.reset!/0` | ✓ WIRED | `MailglassDemo.DemoData.reset!()` present in seeds. |
| `test/mailglass/demo_data_test.exs` | `reference/demo_app/test/mailglass_demo/*.exs` | Nested `System.cmd` Mix test invocation | ✓ WIRED | Wrapper builds `demo_tests` via wildcard and executes `mix test ... --warnings-as-errors`. |
| `account_mailer.ex` | `lib/mailglass/message.ex` | `Message.put_function/2` + public email fields | ✓ WIRED | Message pipeline and `Message.put_function(:invite_admin/:magic_link)` used. |
| `mailer_preview_scenarios_test.exs` | `test/mailglass/demo_data_test.exs` | Root wrapper wildcard inclusion | ✓ WIRED | Wrapper wildcard includes all files under `reference/demo_app/test/mailglass_demo/*.exs`; preview test located there. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `demo_data.ex` | Seed attrs (`provider_message_id`, metadata, execution rows) | `seed_outbound!/seed_inbound!` -> Repo/InboundRecords inserts | Yes | ✓ FLOWING |
| `*_mailer.ex` modules | `assigns` rendered into subject/html/text | `preview_props/0` + function args used in `Message` pipeline | Yes | ✓ FLOWING |
| `mailer_preview_scenarios_test.exs` | `message.swoosh_email.*`, `mailable_function` | Direct calls to 6 mailer functions with deterministic props | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Root demo fixture gate passes | `mix test test/mailglass/demo_data_test.exs` | Passed (per orchestrator evidence, post-fix commit `c44a88f5`) | ✓ PASS |
| Demo app fixture tests pass | `cd reference/demo_app && MIX_ENV=test mix test test/mailglass_demo/*.exs --warnings-as-errors` | Passed (10 tests, 0 failures) | ✓ PASS |
| Full repo suite remains green after fix | `timeout 300 mix test` | Passed (`23 properties, 1163 tests, 0 failures, 7 skipped`) | ✓ PASS |

### Probe Execution

| Probe | Command | Result | Status |
| --- | --- | --- | --- |
| None declared/found for Phase 68 | `find scripts -path '*/tests/probe-*.sh'` + PLAN/SUMMARY scan | No phase probes documented | ? SKIP |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| DATA-01 | 68-01 | Maintainer can reset deterministic demo data with one command. | ✓ SATISFIED | `mix.exs` demo.reset alias -> `seeds.exs` -> `DemoData.reset!`; reset determinism test present. |
| DATA-02 | 68-01 | Demo data includes realistic outbound deliveries, timeline events, suppressions, and replayable webhook targets. | ✓ SATISFIED | Outbound/webhook/suppression scenarios seeded with fixed IDs and asserted by reset test. |
| DATA-03 | 68-01 | Demo data includes realistic inbound records, evidence, routing outcomes, replay lineage, and no-match cases. | ✓ SATISFIED | Inbound stories + execution matrix seeded and asserted in reset test. |
| DATA-04 | 68-02 | Demo mailables provide realistic preview scenarios for invite/auth, receipt, and operational alert use cases. | ✓ SATISFIED | 3 mailers enriched + preview scenario contract tests for all six functions. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| Scoped phase files | - | No `TBD/FIXME/XXX/TODO/HACK/PLACEHOLDER` or stub patterns detected | ℹ️ Info | No blocker debt markers or obvious stub implementations in verified files. |

### Gaps Summary

No blocking gaps found. Must-haves, artifacts, key links, data-flow, and requirements DATA-01..DATA-04 are verified in code and tests.

---

_Verified: 2026-06-01T21:57:45Z_  
_Verifier: the agent (gsd-verifier)_
