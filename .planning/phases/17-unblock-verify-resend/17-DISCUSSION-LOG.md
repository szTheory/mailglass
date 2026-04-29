# Phase 17: Unblock & Verify Resend - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-29
**Phase:** 17-unblock-verify-resend
**Areas discussed:** Tracking test fix, Router wiring scope, Plug-level integration tests

---

## Tracking Test Fix

| Option | Description | Selected |
|--------|-------------|----------|
| A: `async: false` | One-line change; matches all 6 sibling tracking test files already `async: false`; idiomatic ExUnit fix for global-state-mutating tests | ✓ |
| B: Config module indirection + Mox | Keeps `async: true`; requires behaviour + mock + stub per test; significant refactor for a single misbehaving file | |
| C: Repatch / process-scoped env | Keeps `async: true`; adds an external dep; requires prod-code changes to `Tracking.endpoint/0` | |
| D: Keep `async: true`, add `@moduletag :flaky` | Zero effort; documents rather than fixes the race; unpredictable CI failures | |

**User's choice:** Research-driven recommendation (all areas delegated to agent research)
**Notes:** Research confirmed every other tracking test with Application.put_env is already async: false. Option A is the idiomatic fix with zero risk. Option B is the right architectural direction only if Tracking becomes a multi-function facade — not warranted for a single-function fix. Option D is never acceptable for a library with external contributors.

---

## Router Wiring Scope

| Option | Description | Selected |
|--------|-------------|----------|
| A: Add `:resend` to router + plug in Phase 17 | Completion of Phase 14's interrupted wire-up; enables ROADMAP success criteria 2+3 to be verified through the actual plug path; matches the pattern of every prior provider | ✓ |
| B: Defer router wiring to Phase 18 alongside docs | Phase 17 scope stays narrowly focused on test fixes; router + docs land together; but success criteria 2+3 cannot be verified through the plug without wiring | |

**User's choice:** Research-driven recommendation (all areas delegated to agent research)
**Notes:** Research found plug.ex has three missing locations beyond router.ex: @valid_providers, resolve_config!(:resend, ...), provider_module(:resend). Also found that plug_test.exs has an existing assert_raise for :resend that will need to be updated. All prior providers were wired in the same phase as their implementation — Resend is the anomaly.

---

## Plug-Level Integration Tests

| Option | Description | Selected |
|--------|-------------|----------|
| A: Full WebhookCase integration | Add :resend arm to mailglass_webhook_conn/3, Resend config to setup, stub_resend_fixture/1 exported; new resend_webhook_plug_test.exs; full parity with Mailgun/SES/Postmark/SendGrid | ✓ |
| B: Inline plug tests without WebhookCase changes | Builds conn inline; avoids touching WebhookCase; gets success criteria to green with fewer file changes | |
| C: 1-2 plug tests added to existing resend_test.exs | Minimum viable; mixes unit + integration in one file; structurally inconsistent | |

**User's choice:** Research-driven recommendation (all areas delegated to agent research)
**Notes:** Research confirmed plug_mailgun_test.exs is the direct template. WebhookFixtures.sign_resend_payload/4 and load_resend_fixture/1 already exist — only the WebhookCase arm, setup config, and the test file + fixture JSON are missing. Inconsistency (some providers with WebhookCase support, Resend without) creates contributor confusion for any future 6th provider.

---

## Claude's Discretion

- Exact `svix_timestamp` derivation in the WebhookCase :resend arm (use `System.system_time(:second)` per test, not a module-level constant)
- Whether to create fixture JSON files for all Resend event types or just `delivered.json` for the plug test (one is sufficient; unit tests cover all types inline)
- Exact test names in `resend_webhook_plug_test.exs` (follow plug_mailgun_test.exs naming convention)

## Deferred Ideas

- Resend section in `guides/webhooks.md` — deferred to Phase 18 (already in Phase 18 scope per ROADMAP)
- Additional Resend fixture files — deferred; only needed if integration tests require more than `delivered.json`
