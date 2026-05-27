# Phase 58: verify-first-webhook-operator-path - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-05-27
**Phase:** 58-verify-first-webhook-operator-path
**Mode:** assumptions
**Areas analyzed:** Runner Contract, Webhook Verification Path, Negative Signature Assertion, Operator Diagnosis Scenario

## Assumptions Presented

### Runner Contract

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 58 should keep `mix verify.reference_host.journey` as the only runner entrypoint and extend the existing `trust_runner.v1` checkpoint semantics without renaming stage keys. | Confident | `.planning/phases/57-deterministic-trust-runner-fixtures/57-CONTEXT.md`; `mix.exs`; `lib/mix/tasks/mailglass.trust.run.ex`; `lib/mailglass/reference_host/trust_checkpoint.ex` |

### Webhook Verification Path

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Webhook proof should execute the reference host's public inbound route into `MailglassInbound.Ingress.Plug`, using an existing Postmark or SendGrid route/provider verification path rather than direct provider-module calls or lower-level test drivers. | Confident | `.planning/phases/52-trust-scope-lock-reference-host-baseline/52-CONTEXT.md`; `reference/host_app/lib/mailglass_reference_host_web/router.ex`; `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` |

### Negative Signature Assertion

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| The deterministic negative case should assert the real ingress plug returns `401` with a closed signature reason and does not proceed into tenant resolution or persistence. | Confident | `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex`; `mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs` |

### Operator Diagnosis Scenario

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| The operator non-happy path should use the existing deterministic `:no_match` routing diagnosis surface, and checkpoint it under `operator_troubleshooting` rather than inventing a separate operator evidence schema. | Likely | `mailglass_admin/lib/mailglass_admin/inbound_live.ex`; `mailglass_admin/test/mailglass_admin/inbound_live_test.exs`; `mailglass_inbound/lib/mix/tasks/mailglass.inbound.doctor.ex`; `mailglass_inbound/lib/mailglass_inbound/operator/formatter.ex`; `mailglass_inbound/lib/mailglass_inbound/internal/doctor.ex` |

## Corrections Made

No corrections - all assumptions accepted via workflow fallback because interactive questions are unavailable in Default mode.

## External Research

No external research was performed. The codebase and prior phase context provided enough evidence for Phase 58 planning decisions.
