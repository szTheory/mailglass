# Phase 72: Contract Docs and Stale - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution
> agents. Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-06-02
**Phase:** 72-contract-docs-and-stale
**Mode:** assumptions with subagent research
**Areas analyzed:** contract wording, stale-claim guards, release topology, public docs, ecosystem lessons, prompts synthesis

## Assumptions Presented

### Initial Assumption Set

| Assumption | Confidence | Evidence |
| --- | --- | --- |
| Phase 72 should update compatibility docs from "inbound is excluded/outside the 1.x promise" to "core/admin remain the matched 1.x sibling line; inbound has its own stable 1.0 contract." | Likely | `README.md`, `guides/compatibility-and-deprecations.md`, `lib/mix/tasks/mailglass.docs.check.ex`, Phase 66 context |
| Stale-claim guards should extend existing docs-contract seams rather than introduce a new checker. | Likely | `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs`, `lib/mix/tasks/mailglass.docs.check.ex`, Phase 64/65 contexts |
| Phase 72 should correct publish/fallback wording only enough to prevent stale claims; actual Hex/HexDocs/smoke evidence belongs to Phase 73. | Confident | `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `MAINTAINING.md` |
| Reference app published-Hex dependency examples should be treated as stale-claim surfaces, but lockfile churn should be planner discretion and only required if docs/tests depend on it. | Likely | `reference/host_app/mix.exs`, `reference/demo_app/mix.exs`, Phase 71 context |
| Verification should include the inbound docs contract lane and root docs check, with `mix verify.stability_contract` used if touched rules affect aggregate support-contract truth. | Confident | `MAINTAINING.md`, Phase 64 context, `test/mailglass/stability_contract_test.exs` |

## Corrections Made

The user asked to broaden the discussion and research all assumptions with
subagents, including pros/cons/tradeoffs, idiomatic Elixir/Phoenix/Plug/Ecto
practice, lessons from successful adjacent frameworks/libraries, prompt
directory guidance, and a cohesive one-shot recommendation set.

No user correction changed the phase boundary. The research deepened and
expanded the decisions.

## Subagent Research

### Elixir/Phoenix Idioms

The Elixir/Phoenix research track recommended using existing contract seams:

- package-local inbound docs-contract tests for inbound semantic claims,
- root docs/stability tests for aggregate release/runbook truth,
- `mix mailglass.docs.check` for Tier 1 public-doc tokens.

Pros:
- Aligns with existing repo architecture and ExUnit/Mix idioms.
- Avoids a second truth engine.
- Keeps failures diagnostic.

Cons:
- Literal string guards can be brittle.
- Broad forbidden phrases can block legitimate historical context.

Mitigation:
- Use exact stale phrases for known bad claims.
- Use JSON/topology parsing for release-please and manifest truth.
- Allow archival changelog/history when clearly framed as historical.

### Ecosystem Lessons

The ecosystem research track compared Rails Action Mailbox/Action Mailer,
Anymail, Laravel Mail, and provider docs.

Relevant lessons:
- Rails is strong at end-to-end workflow docs; Mailglass should copy workflow
  clarity while avoiding provider-module contract blur.
- Anymail is strong at honest cross-provider support and limited/unsupported
  distinctions; Mailglass should copy honesty without importing matrix sprawl.
- Laravel Mail has strong DX around simple usage, preview/testing, provider
  setup, and explicit escape hatches; Mailglass should keep Phoenix/Mix docs
  first-class and keep escape hatches non-contractual.
- Provider docs contain operational facts, not Mailglass public API. Normalize
  and narrow them through `MailglassInbound.Ingress.Plug`.

### Release/Runbook Topology

The release-topology research track found:

- `release-please-config.json` defines core, admin, and inbound, but the
  linked-versions group includes only core/admin.
- `.release-please-manifest.json` records core/admin `1.3.0` and inbound
  `1.0.0`.
- `MAINTAINING.md`, `guides/compatibility-and-deprecations.md`, and
  `guides/jobs.md` still contain stale outside-`v1.x` or `0.x` inbound claims.
- `mailglass_inbound/mix.exs` and the inbound publish summary likely need
  package-tag source refs such as `mailglass_inbound-v1.0.0`, not generic
  sibling-group or bare `v1.0.0` refs.
- Reference/demo published-Hex pins remain Phase 73 because inbound `1.0.0` is
  not live yet.

### Prompts Synthesis

Relevant prompt-derived guidance:

- Docs are part of the product.
- Examples and install snippets are contract surfaces.
- Package docs should be narrow, honest, versioned, and source-linked.
- Release automation should be deterministic and reviewable.
- The Mailglass voice should be clear, calm, exact, and maintainer-like.
- Avoid broad claims and preserve small honest surfaces.

## External Research

Research agents referenced these public sources:

- Rails Action Mailbox guide:
  `https://guides.rubyonrails.org/action_mailbox_basics.html`
- Rails Action Mailer guide:
  `https://guides.rubyonrails.org/action_mailer_basics.html`
- Anymail docs, ESP support, and changelog:
  `https://anymail.dev/en/latest/`,
  `https://anymail.dev/en/latest/esps/`,
  `https://anymail.dev/en/latest/changelog/`
- Laravel Mail and release docs:
  `https://laravel.com/docs/13.x/mail`,
  `https://laravel.com/docs/13.x/releases`
- Postmark inbound and webhook docs:
  `https://postmarkapp.com/developer/user-guide/inbound`,
  `https://postmarkapp.com/developer/webhooks/webhooks-overview`
- SendGrid inbound parse docs:
  `https://www.twilio.com/docs/sendgrid/ui/account-and-settings/inbound-parse`
- Resend API docs:
  `https://resend.com/docs/api-reference`,
  `https://resend.com/docs/api-reference/emails/send-batch-emails`
- Elixir/Mix/Plug/Ecto docs:
  `https://hexdocs.pm/elixir/1.18.3/Code.html#fetch_docs/1`,
  `https://mix.hexdocs.pm/main/Mix.Tasks.Test.html`,
  `https://plug.hexdocs.pm/Plug.Parsers.html`,
  `https://ecto-sql.hexdocs.pm/Ecto.Adapters.SQL.Sandbox.html`

## Final Recommendation

Phase 72 should lock words to truth:

- one canonical inbound stable `1.0` contract,
- explicit non-contract/internal/deferred boundaries,
- core/admin matched `1.x` sibling line preserved separately,
- executable stale-claim guards in existing lanes,
- package-tag/source-ref truth corrected if stale,
- live publish/install evidence deferred to Phase 73.

No scope creep was accepted.
