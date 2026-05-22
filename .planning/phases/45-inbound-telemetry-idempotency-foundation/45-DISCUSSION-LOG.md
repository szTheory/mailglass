# Phase 45: Inbound Telemetry + Idempotency Foundation - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-22
**Phase:** 45-inbound-telemetry-idempotency-foundation
**Mode:** assumptions
**Areas analyzed:** Telemetry emission + span placement; TELE-07 cross-package PubSub bridge; TELE-08 convergence proof; MIME parser + gen_smtp backend + error type

## Assumptions Presented

### Telemetry emission mechanism + span placement
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Reuse `Mailglass.Telemetry.span/3` + co-located `MailglassInbound.Telemetry` mirroring `Webhook.Telemetry.span_with_enrichment/3` | Confident | `lib/mailglass/telemetry.ex`, `lib/mailglass/webhook/telemetry.ex` |
| Wrap execution span on `Execution.execute/2` (covers both Oban + Task.Supervisor, where outcome is computed), not `dispatch/2` | Confident | `mailglass_inbound/lib/mailglass_inbound/execution.ex`, `execution/worker.ex` |
| Span wrap points: `Ingress.Plug.call/2`, `Router.Matcher.match/2`, `Ingress.Persist.persist/2` transact | Confident | `ingress/plug.ex`, `router/matcher.ex`, `ingress/persist.ex` |
| Raise-safety (TELE-05) inherited from `:telemetry.span/3` semantics | Confident | outbound contract precedent |

### TELE-07 cross-package telemetry→PubSub bridge
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Direct post-commit `Phoenix.PubSub.broadcast` (no telemetry-handler bridge — none exists) | Confident | `lib/mailglass/outbound/projector.ex`; admin is pure consumer |
| Exactly one per-tenant topic; default string `"mailglass:inbound:" <> tenant_id` | Likely | `lib/mailglass/pub_sub/topics.ex`, `.credo.exs` LINT-06; ROADMAP.md:88 |
| Topic builder in new `MailglassInbound.PubSub.Topics`; no inbound↔admin dep edge | Likely (escalation) | `mailglass_admin/mix.exs` (no inbound dep), `pub_sub/topics.ex` |

### TELE-08 convergence proof structure
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Mirror `WebhookIdempotencyConvergenceTest` (async:false non-DataCase, shared owner, TRUNCATE CASCADE, max_runs:1000) | Confident | `test/mailglass/properties/webhook_idempotency_convergence_test.exs` |
| Drive real path via synchronous `Execution.execute/2`, not async `dispatch/2` | Confident | `execution.ex`; `OptionalDeps.Oban.runner/0` fallback |
| Assert one InboundRecord + one ExecutionRun per unique `(tenant_id, provider, provider_message_id)` | Confident | `ingress/persist.ex` dedupe index; `execution.ex` :duplicate short-circuit |
| Generator: small `member_of` id pool + replay multiplier (research-confirmed) | Confident | in-repo outbound test idiom |

### MIME module + gen_smtp backend + error type
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `MailglassInbound.MIME` net-new, parse via `:mimemail.decode/1` gated through `OptionalDeps.GenSmtp` (extend gateway) | Confident | `lib/mailglass/optional_deps/gen_smtp.ex` (only `available?/0` today) |
| Decoded 5-tuple shape; classify attachment/inline by `Parameters.disposition`; don't trust `decode_attachment(s)` option | Confident (research) | gen_smtp 1.3.0 `mimemail.erl` |
| MIME-04 never-raise requires catching BOTH `:error` and `:throw` (and consider `:exit`) | Confident (research correction) | gen_smtp 1.3.0 `mimemail.erl` error/throw clauses |
| New `MailglassInbound.MIMEError` struct, closed types `[:inbound_mime_invalid, :gen_smtp_unavailable]` | Likely (escalation) | `lib/mailglass/error.ex` (behaviour/namespace, no parent struct; type absent) |
| MIME built standalone in Phase 45; first consumed in Phase 46 | Confident | ROADMAP.md Phase 46 dependency |

## Corrections Made

No corrections — user selected "Yes, proceed" and all four areas were locked with the
recommended defaults, including the two flagged public-contract escalation points
(TELE-07 topic string/builder home → `MailglassInbound.PubSub.Topics` +
`"mailglass:inbound:" <> tenant_id`; MIME error type → new `MailglassInbound.MIMEError`).

## External Research

- **`:mimemail` decode API (gen_smtp 1.3.0):** `decode/1,2`, returns 5-tuple
  `{Type, SubType, Headers, Parameters(map), Body}`; multipart Body is a list, leaf is
  binary; attachment/inline from `Parameters.disposition`. **Raises** via both
  `erlang:error/1` (`non_mime`, `no_boundary`, …) and `throw/1` (`bad_content_type`,
  `bad_disposition`) → wrapper must `try/rescue` + `catch :throw` (+ consider `:exit`
  from iconv). Use `{allow_missing_version, true}`; consider `{encoding, none}`. The
  `decode_attachment(s)` option spelling is inconsistent and unreliable.
  Source: gen_smtp 1.3.0 `src/mimemail.erl`; https://hexdocs.pm/gen_smtp/mimemail.html
- **StreamData generator idiom:** in-repo outbound test uses `gen all` +
  interpolated/`member_of` keys + `list_of` + `integer(1..10)` replay multiplier;
  for inbound add a small `member_of` id pool (≤4) to force cross-element collisions.
  Postmark inbound payload keys on `MessageID`. Raw MIME needs CRLF + blank line +
  `MIME-Version: 1.0`.
  Source: `test/mailglass/properties/webhook_idempotency_convergence_test.exs`; stream_data 1.3.0.
