# Phase 41: SendGrid Ingress And Mailbox Routing - Research

**Researched:** 2026-05-06  
**Domain:** SendGrid inbound parse ingress, multipart/raw-MIME normalization, post-commit mailbox execution, and append-only execution lineage inside `mailglass_inbound`  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### SendGrid ingress security and DX
- **D-41-01:** Ship SendGrid inbound as strict shared-secret/basic-auth ingress, not signed Parse security policies.
- **D-41-02:** This is architectural, not accidental: SendGrid inbound arrives as `multipart/form-data`, and Plug multipart parsing does not use the `:body_reader` seam already used for Postmark raw-body verification.
- **D-41-03:** Keep the adopter-facing ingress story narrow: one SendGrid mount/config path and one documented shared-secret/basic-auth setup.
- **D-41-04:** Signed multipart verification is future work only if the project is willing to own a raw-body-first multipart ingress seam.

### SendGrid normalization and stable contract discipline
- **D-41-05:** `%MailglassInbound.InboundMessage{}` stays unchanged.
- **D-41-06:** Require SendGrid raw MIME delivery. If the `email` part is absent, reject with explicit configuration/help error.
- **D-41-07:** Normalize primarily from raw MIME plus provider envelope metadata, not convenience multipart fields.
- **D-41-08:** For SendGrid: `provider == :sendgrid`, `provider_message_id == nil`, RFC `Message-ID` maps to `message_id`, and `envelope_recipient` comes from provider envelope data.
- **D-41-09:** Keep SendGrid-only facts in evidence, not the stable struct.

### Provider-specific duplicate protection
- **D-41-10:** Do not assume `provider_message_id` is the only ingress idempotency anchor.
- **D-41-11:** Keep Postmark duplicate collapse on `(tenant_id, provider, provider_message_id)`.
- **D-41-12:** For SendGrid, use a deterministic raw-MIME fingerprint scoped by `(tenant_id, provider)`.
- **D-41-13:** Duplicate ingress is an ingress-truth concern and must not trigger mailbox execution again.

### Mailbox execution timing and recording
- **D-41-14:** Execute mailboxes inline only after successful persistence commit.
- **D-41-15:** Do not call `Mailbox.process/1` inside the persistence transaction.
- **D-41-16:** Fresh ingress sequence: verify -> normalize -> persist canonical+evidence -> route -> execute matched mailbox inline -> append lineage row.
- **D-41-17:** `:no_match` is distinct from `:ignore`.
- **D-41-18:** exceptions/exits/throws/invalid return shapes are execution failures, not mailbox outcomes.
- **D-41-19:** Once persistence succeeds, ingress should still acknowledge with `200` even if mailbox execution records `:reject`, `:bounce`, `:ignore`, `:no_match`, or `:failed`.

### Execution lineage and replay truth
- **D-41-20:** Generalize the replay-only lineage model into one append-only execution lineage model shared by fresh processing and replay.
- **D-41-21:** Each execution attempt must point at the canonical row and evidence row and record source, mailbox identity, outcome, reason/failure metadata, timestamp, and small internal metadata.
- **D-41-22:** Do not mutate the canonical inbound row with latest execution state.
- **D-41-23:** Replay means rerun processing against stored inbound truth, not re-ingest.
- **D-41-24:** Default replay runs the originally matched mailbox, not current router reevaluation.
- **D-41-25:** Replay reuses stored canonical and evidence truth without re-normalizing by default.

### Deferred
- Async/Oban execution, bounded fallback semantics, synthetic UI, signed multipart verification, and broader matcher expansion stay out of Phase 41.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INGRESS-02 | Maintainer can verify and normalize SendGrid inbound payloads into the canonical inbound model through a first-party ingress plug. | Use a SendGrid-specific multipart ingress path that authenticates with explicit shared-secret/basic-auth config, requires the raw `email` part, and normalizes from raw MIME plus provider envelope metadata into the existing `%MailglassInbound.InboundMessage{}` contract. Official SendGrid docs show the webhook is `multipart/form-data`, expose the `email` raw-MIME field when that option is enabled, and warn that multipart parsing can break signature validation. Plug docs state `:body_reader` is not used by `Plug.Parsers.MULTIPART`, which supports the phase decision to avoid signed verification here. [VERIFIED: .planning/REQUIREMENTS.md, .planning/phases/41-sendgrid-ingress-and-mailbox-routing/41-CONTEXT.md, mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex][CITED: https://www.twilio.com/docs/sendgrid/for-developers/parsing-email/setting-up-the-inbound-parse-webhook][CITED: https://www.twilio.com/docs/sendgrid/for-developers/parsing-email/securing-your-parse-webhooks][CITED: https://hexdocs.pm/plug/Plug.Parsers.html] |
| STORE-02 | Operator can replay a stored inbound message through routing and mailbox processing without pretending it is a newly received provider event. | Generalize the current replay-only table into append-only execution lineage, persist a SendGrid raw-MIME fingerprint for duplicate collapse, execute matched mailboxes only after commit, and make replay rerun the stored canonical/evidence pair against the originally matched mailbox by default. The existing `ReplayRun` schema already proves the record/evidence linkage and outcome normalization pattern that should be broadened rather than bypassed. [VERIFIED: .planning/REQUIREMENTS.md, mailglass_inbound/lib/mailglass_inbound/inbound_records.ex, mailglass_inbound/lib/mailglass_inbound/inbound_records/replay_run.ex, mailglass_inbound/test/mailglass_inbound/replay_test.exs][CITED: https://www.twilio.com/docs/sendgrid/for-developers/parsing-email/inbound-email/][CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
</phase_requirements>

## Project Constraints

- Keep the stable public contract narrow: `%MailglassInbound.InboundMessage{}`, `MailglassInbound.Router`, and `MailglassInbound.Mailbox` remain the public adopter-facing slice. Provider and persistence internals stay internal.
- Preserve tenant scope on canonical rows, evidence rows, and execution lineage.
- Keep raw MIME, provider-only multipart fields, spam/auth verdicts, and attachment blobs in evidence only.
- Avoid using provider retry behavior as mailbox retry behavior; persistence truth and execution truth are separate.
- Prefer one honest SendGrid ingress story over a larger mode matrix.

## Summary

Phase 41 should be planned as the inbound package’s first proof that provider variance and real mailbox execution can coexist without widening the stable public contract. The decisive shape is:

1. Add a SendGrid-specific multipart ingress seam that uses explicit app-controlled auth and requires the raw MIME `email` part.
2. Normalize from raw MIME plus the provider envelope into the locked `%InboundMessage{}` struct while storing provider-specific fields only in evidence.
3. Split persistence truth from execution truth: persist first, then route and execute post-commit, then append one execution lineage row for either fresh ingress or replay.
4. Keep replay honest by reusing stored canonical/evidence truth and defaulting to the originally matched mailbox.

Two external facts drive the phase boundary. First, current SendGrid docs show inbound parse posts `multipart/form-data`, and the raw full MIME payload is delivered via the `email` field when that option is enabled. Second, Plug’s own docs state `Plug.Parsers` `:body_reader` is not used by `Plug.Parsers.MULTIPART`, which means the existing Postmark raw-body verification pattern does not transfer cleanly to signed SendGrid multipart ingress. That directly supports the context’s shared-secret/basic-auth recommendation for this phase instead of a misleading “signed verification supported” claim. [CITED: https://www.twilio.com/docs/sendgrid/for-developers/parsing-email/setting-up-the-inbound-parse-webhook][CITED: https://www.twilio.com/docs/sendgrid/for-developers/parsing-email/securing-your-parse-webhooks][CITED: https://hexdocs.pm/plug/Plug.Parsers.html]

The mailbox execution half should follow existing Mailglass truth-boundary discipline: the transaction commits canonical and evidence truth first, then the side effect runs outside the transaction, and the result is captured as append-only lineage. The current `ReplayRun` model already demonstrates the right outcome normalization and append-only posture; Phase 41 should generalize that model so fresh ingress and replay share one execution history instead of inventing separate truth paths. [VERIFIED: lib/mailglass/outbound.ex, lib/mailglass/webhook/ingest.ex, mailglass_inbound/lib/mailglass_inbound/inbound_records.ex, mailglass_inbound/test/mailglass_inbound/replay_test.exs]

**Primary recommendation:** plan Phase 41 as `SendGrid multipart ingress -> raw-MIME-first normalization -> provider-specific duplicate-safe persistence -> post-commit route/match -> inline mailbox execution -> append-only execution lineage`, with replay implemented as another execution source over stored canonical/evidence truth.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| SendGrid multipart ingress | Frontend Server (SSR) | API / Backend | The mounted Plug owns multipart parsing, request auth, and explicit operator-facing HTTP outcomes. |
| Raw MIME extraction and evidence capture | API / Backend | Database / Storage | The phase requires the `email` MIME part as canonical parse truth and stores it in evidence for replay/debugging. |
| Canonical normalization | API / Backend | — | `%InboundMessage{}` remains the stable in-memory routing and mailbox value object. |
| Duplicate collapse | Database / Storage | API / Backend | Provider-specific uniqueness and fingerprinting belong at the persistence boundary. |
| Mailbox execution | API / Backend | — | The runner invokes the stable `Mailbox.process/1` contract after commit and classifies invalid/failed outcomes. |
| Execution lineage and replay | Database / Storage | API / Backend | Append-only history points back to immutable receive truth and distinguishes `:fresh` from `:replay`. |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `plug` | `1.19.1` | Mounted ingress plug and multipart parsing | Current repo stack; official docs explain why `:body_reader` does not help multipart verification directly. [VERIFIED: mix.lock][CITED: https://hexdocs.pm/plug/Plug.Parsers.html] |
| `phoenix` | `1.8.5` | Adopter mount path and request lifecycle | Phase 41 still needs one ordinary Plug/Phoenix ingress path, not a new subsystem. [VERIFIED: mix.lock] |
| `ecto` / `ecto_sql` | `3.13.5` | Persistence, transactions, and schema evolution | Post-commit execution and provider-specific dedupe need explicit transaction boundaries and migrations. [VERIFIED: mix.lock][CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| Postgres | local project default | Durable canonical/evidence rows plus duplicate/execution invariants | Provider-specific indexes and append-only execution history should be enforced in storage, not by convention. |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `mail_parser` or repo-local MIME parsing seam | repo decision | Parse raw MIME into stable message fields | Use only if it can preserve the locked `%InboundMessage{}` shape and evidence boundaries without inventing provider quirks. |
| `MailglassInbound.Router.Matcher` | repo-local | First-match routing | Reuse the existing matcher unchanged for Phase 41 routing decisions. |
| `MailglassInbound.Mailbox` | repo-local | Stable mailbox callback | Use the locked `process/1` contract and classify invalid return shapes as execution failures. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Shared-secret/basic-auth for Phase 41 | Signed SendGrid Parse verification | Current SendGrid docs require the exact raw multipart request body for signature validation, and Plug multipart parsing bypasses the repo’s existing `:body_reader` seam. Claiming this works with the current shape would be dishonest. [CITED: https://www.twilio.com/docs/sendgrid/for-developers/parsing-email/securing-your-parse-webhooks][CITED: https://hexdocs.pm/plug/Plug.Parsers.html] |
| Require the raw `email` MIME part | Best-effort normalization from convenience multipart fields alone | Convenience fields are lossy and make attachments/body fidelity weaker; the context explicitly prefers raw MIME as source of truth. [CITED: https://www.twilio.com/docs/sendgrid/for-developers/parsing-email/setting-up-the-inbound-parse-webhook] |
| Shared execution lineage for fresh and replay | Keep a replay-only table and invent a second fresh-execution table | That would split essentially identical truth into two internal models and make operator reasoning harder. |
| SendGrid MIME fingerprint dedupe | Overload `provider_message_id` with RFC `Message-ID` | RFC `Message-ID` is not a provider delivery id and can be absent or reused; the context explicitly rejects this overload. |

**Installation:**
```bash
mix deps.get
mix compile --warnings-as-errors
```

## RESEARCH COMPLETE
