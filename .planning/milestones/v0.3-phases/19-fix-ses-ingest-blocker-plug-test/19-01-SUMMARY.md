---
phase: 19-fix-ses-ingest-blocker-plug-test
plan: "01"
subsystem: webhook-ingest
requirements-completed: [SES-01, SES-03]
tags:
  - webhook
  - ses
  - ingest
  - bugfix

dependency_graph:
  requires:
    - Phase 16 SES verify!/3 and normalize/2 (already implemented)
  provides:
    - ":ses-aware ingest seam — guard and derive clause in ingest.ex"
  affects:
    - lib/mailglass/webhook/ingest.ex

tech_stack:
  added: []
  patterns:
    - "Guard list mirroring: ingest_multi/3 guard matches plug.ex @valid_providers atom for atom"
    - "Dispatch table extension: new defp clause body byte-identical to sibling :mailgun/:resend clauses"

key_files:
  modified:
    - lib/mailglass/webhook/ingest.ex

decisions:
  - "No new architectural decisions — pure seam widening; no new modules, tables, or dependencies"

metrics:
  duration: "~10 minutes"
  completed: "2026-04-30"
  tasks_completed: 2
  files_modified: 1
---

# Phase 19 Plan 01: SES Ingest Seam Widening Summary

Two surgical edits to `lib/mailglass/webhook/ingest.ex` close the v0.3.0-MILESTONE-AUDIT BLOCKER: `:ses` added to `ingest_multi/3` guard and a new `derive_webhook_provider_event_id(:ses, _, [first | _])` clause inserted, enabling signed SES Notifications to traverse the full ingest pipeline without `FunctionClauseError`.

## What Was Done

### Task 19-01-01 — Add `:ses` to `ingest_multi/3` guard (commit `4152f47`)

**File:** `lib/mailglass/webhook/ingest.ex` line 122

**Before:**
```elixir
    when provider in [:postmark, :sendgrid, :mailgun, :resend] and is_binary(raw_body) and
```

**After:**
```elixir
    when provider in [:postmark, :sendgrid, :mailgun, :ses, :resend] and is_binary(raw_body) and
```

Atom ordering now mirrors `lib/mailglass/webhook/plug.ex:84` `@valid_providers` exactly.
Change: 1 insertion + 1 deletion — no other lines touched.

### Task 19-01-02 — Add `derive_webhook_provider_event_id(:ses)` clause (commit `76125c4`)

**File:** `lib/mailglass/webhook/ingest.ex` — inserted between `:mailgun` clause (line 366) and `:resend` clause (line 373)

**Verbatim diff (8 lines added):**
```elixir
+  # SES (SNS) populates `provider_event_id` as "#{sns_message_id}:#{email}" via
+  # `Mailglass.Webhook.Providers.SES.build_provider_event_id/3`. Stable across SNS
+  # retries because both fields come from the signed payload. Same dispatch as
+  # Mailgun/Resend.
+  defp derive_webhook_provider_event_id(:ses, _raw_body, [first | _]) do
+    extract_event_provider_id(first) || ""
+  end
+
```

Clause body is byte-identical to `:mailgun` and `:resend` siblings: `extract_event_provider_id(first) || ""`.
`extract_event_provider_id/1` reads `Event.metadata["provider_event_id"]` — already populated by `Mailglass.Webhook.Providers.SES.build_event/8` as `"#{sns_message_id}:#{email}"`.

## Verification Results

```
mix compile --warnings-as-errors       → exit 0 (clean)
mix format --check-formatted           → exit 0 (formatter-stable)
mix credo --strict ingest.ex           → 0 issues (24 mods/funs checked)
mix test test/mailglass/webhook/       → 206 tests, 0 failures
```

## Requirements Closed

| Requirement | Description | Status |
|-------------|-------------|--------|
| SES-01 | text/plain SNS parsing reaches `ingest_multi/3` without crashing | Complete |
| SES-03 | RSA-verified SES events get a stable `provider_event_id` | Complete |

## Threat Model Dispositions

| Threat | Mitigation | Result |
|--------|------------|--------|
| T-19-01 (DoS via FunctionClauseError) | `:ses` added to guard — pipeline completes instead of crashing → HTTP 200 | Mitigated |
| T-19-02 (Repudiation — no idempotency key) | `:ses` derive clause populates `provider_event_id`; UNIQUE collision returns 200 on SNS retries | Mitigated |

## Next Consumer

**Plan 19-02** — Plug-level integration test for the now-working SES ingest seam.
The test will exercise `Mailglass.Webhook.Plug.call/2` end-to-end with a real signed SES Notification payload, asserting HTTP 200, a persisted `WebhookEvent` row, and that no PII leaks into logs.

## Deviations from Plan

None — plan executed exactly as written. Both tasks required `mix deps.get` first (worktree had no compiled deps), which is expected and not a deviation.

## Self-Check: PASSED

- `lib/mailglass/webhook/ingest.ex` modified: confirmed
- Commit `4152f47` exists: confirmed
- Commit `76125c4` exists: confirmed
- 206 tests, 0 failures: confirmed
