# Phase 40: Postmark Ingress and Replayable Persistence - Research

**Researched:** 2026-05-06 [VERIFIED: local system date]  
**Domain:** Postmark inbound webhook verification, canonical inbound normalization, replayable persistence, and route-compatibility proof inside `mailglass_inbound` [VERIFIED: .planning/ROADMAP.md, .planning/phases/40-postmark-ingress-and-replayable-persistence/40-CONTEXT.md]  
**Confidence:** HIGH [VERIFIED: repo code + official Postmark/Plug/Ecto/Rails/Anymail docs]

<user_constraints>
## User Constraints (from CONTEXT.md)

Verbatim copy from `40-CONTEXT.md`. [VERIFIED: .planning/phases/40-postmark-ingress-and-replayable-persistence/40-CONTEXT.md]

### Locked Decisions

### Phase boundary and delivery shape
- **D-40-01:** Phase 40 stops at `verify -> normalize -> persist -> route
  compatibility`. It should not call `Mailbox.process/1` yet.
- **D-40-02:** First real mailbox execution should start in Phase 41, with
  async/Oban and bounded fallback semantics remaining Phase 42 work. Do not
  smuggle runner semantics into ingress storage work.
- **D-40-03:** The user-facing Phase 40 story must be honest: “Postmark ingress
  and replayable storage are real now; mailbox execution is next.” Do not
  market the provider slice as end-to-end processing before the execution phase
  lands.

### Ingress architecture
- **D-40-04:** Follow the existing Mailglass webhook house pattern:
  - adopter-facing mount/config seam outside
  - provider-specific verification/normalization inside
  - conn-free provider contract
  - verify before tenant resolution, persistence, or routing
- **D-40-05:** Keep the provider seam internal and sealed. The stable public
  contract is the inbound package’s adopter-facing ingress/routing surface, not
  a user-extensible provider behaviour in Phase 40.
- **D-40-06:** Reuse the existing raw-body capture and ingress-choke-point style
  already used in `mailglass` webhooks. Capture exact request bytes only on the
  inbound ingress path, not globally across unrelated routes.
- **D-40-07:** Align Postmark authentication with the current Mailglass
  webhook posture and Postmark guidance:
  - support HTTP Basic Auth as the default protection seam
  - keep IP allowlisting optional
  - fail closed on unverifiable requests

### Canonical normalization
- **D-40-08:** Normalize Postmark inbound data only into the already-locked
  `%MailglassInbound.InboundMessage{}` fields. Do not widen the public struct
  for Postmark-only quirks.
- **D-40-09:** Map Postmark’s `MessageID` into `provider_message_id`, and map
  the RFC `Message-Id` header into `message_id` when present. Keep those two
  identifiers distinct.
- **D-40-10:** Map Postmark’s `OriginalRecipient` into the canonical
  `envelope_recipient` field. Do not route only on visible `To` headers when
  the provider gives the actual RCPT target.
- **D-40-11:** Normalize sender and recipient fields from Postmark’s structured
  contact data, not from legacy string fields when the richer shape is already
  available.
- **D-40-12:** Preserve honest provider limitations in the normalized shape:
  - BCC may be absent or partial by provider design
  - stripped-reply/body helpers are provider conveniences, not universal truth
  - attachment bytes are evidence, not canonical attachment metadata

### Persistence and replay semantics
- **D-40-13:** Persist one canonical inbound row plus one linked evidence row in
  one package-local transaction using `Ecto.Multi`-style semantics. The durable
  truth boundary is:
  - canonical adopter-facing normalized row
  - raw provider evidence row
- **D-40-14:** Treat Postmark retries and manual replays as ingress idempotency
  concerns, not as new fresh receives. The recommended dedupe anchor is
  `(tenant_id, provider, provider_message_id)` for Postmark-backed rows.
- **D-40-15:** The evidence row should preserve:
  - raw webhook JSON payload
  - selected raw request headers
  - verification facts
  - parse warnings
  - attachment blobs when the provider payload includes them
- **D-40-16:** `raw_mime` may remain `nil` for Postmark in Phase 40 if the
  provider webhook does not deliver a trustworthy raw-message artifact directly.
  Do not fake raw MIME by reconstructing it from parsed fields.
- **D-40-17:** Do not write `ReplayRun` rows during fresh ingress. Replay
  lineage rows remain execution-history artifacts for actual replay work, not
  receive-time storage.
- **D-40-18:** Replay must stay clearly separate from fresh receive semantics:
  a later replay reuses stored evidence linked to the original inbound record;
  it is not inserted as a brand-new inbound message.

### Routing compatibility and DX
- **D-40-19:** Phase 40 should prove route compatibility against the normalized
  message shape, but that proof should stay narrow:
  - matcher can evaluate the normalized message
  - no-match is explicit and non-exceptional
  - matched mailbox identity may be surfaced internally
  - mailbox execution does not happen yet
- **D-40-20:** Do not broaden the router or mailbox contracts as a side effect
  of Postmark ingress work. Body matching, attachment matching, fan-out, hooks,
  and runner options remain deferred exactly as Phase 39 declared.
- **D-40-21:** The public DX should feel idiomatic for Phoenix/Plug/Ecto:
  - one obvious mount/config path
  - one stable normalized value object
  - one durable transaction boundary
  - explicit success/rejection/duplicate outcomes
  Avoid callback soup, hidden global state, or implicit provider magic.

### Lessons from adjacent ecosystems
- **D-40-22:** Borrow from Rails Action Mailbox what it got right:
  - durable inbound records before app-specific processing
  - explicit routing/mailbox separation
  - debugging/forensics value of retained inbound evidence
  Do not copy its heavier built-in lifecycle/retention machinery into this
  phase.
- **D-40-23:** Borrow from Anymail what it got right:
  - normalize one common inbound message surface
  - keep provider specifics accessible but outside the core normalized shape
  - design for webhook retries and duplicate delivery attempts up front
- **D-40-24:** Learn from the footguns those ecosystems expose:
  - too much hidden processing behind signals/jobs obscures idempotency
  - too much built-in workflow surface increases support burden
  - “reachable” provider internals quickly get treated as public API if the
    docs are not explicit and tests do not enforce the boundary

### Recommendation-first workflow posture
- **D-40-25:** For inbound-provider work, downstream research and planning
  should default to one cohesive recommendation set and escalate only when a
  choice would materially change:
  - the stable public contract
  - tenant/security trust boundaries
  - replay/audit truth semantics
  - irreversible retention/security posture
  - major long-term maintainer burden

### the agent's Discretion
- Exact internal module names for inbound ingress plug/router/provider seams.
- Exact unique index and conflict-handling shape used to make Postmark ingress
  idempotent.
- Exact normalized field mapping helpers and parse-warning representation.
- Exact return shape for internal route-compatibility proof, as long as it does
  not imply mailbox execution has already started.

### Deferred Ideas (OUT OF SCOPE)
None explicitly listed in `40-CONTEXT.md` beyond the locked phase exclusions above. [VERIFIED: .planning/phases/40-postmark-ingress-and-replayable-persistence/40-CONTEXT.md]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INGRESS-01 | Maintainer can verify and normalize Postmark inbound payloads into the canonical inbound model through a first-party ingress plug. [VERIFIED: .planning/REQUIREMENTS.md] | Reuse the existing Mailglass webhook choreography: raw-body capture via Plug `:body_reader`, verify first, then tenant resolution, then pure normalization into `%MailglassInbound.InboundMessage{}` through an internal sealed Postmark provider module. [VERIFIED: lib/mailglass/webhook/caching_body_reader.ex, lib/mailglass/webhook/plug.ex, lib/mailglass/webhook/provider.ex][CITED: https://hexdocs.pm/plug/Plug.Parsers.html][CITED: https://postmarkapp.com/developer/webhooks/webhooks-overview] |
| STORE-01 | Operator can persist each inbound message as both normalized canonical data and raw provider source material sufficient for replay and debugging. [VERIFIED: .planning/REQUIREMENTS.md] | Write one canonical `mailglass_inbound_records` row and one `mailglass_inbound_evidence` row in a single `Ecto.Multi` transaction, add Postmark-specific idempotency on `(tenant_id, provider, provider_message_id)`, and return explicit `:stored` or `:duplicate` outcomes without creating `ReplayRun` rows. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/inbound_records/*.ex, mailglass_inbound/priv/repo/migrations/20260506163000_create_mailglass_inbound_storage_foundation.exs, .planning/phases/40-postmark-ingress-and-replayable-persistence/40-CONTEXT.md][CITED: https://hexdocs.pm/ecto/Ecto.Multi.html][CITED: https://postmarkapp.com/support/article/understanding-inbound-webhook-retries-in-postmark] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Do not widen the stable public contract beyond `%MailglassInbound.InboundMessage{}`, `MailglassInbound.Router`, and `MailglassInbound.Mailbox`; provider internals stay internal even if reachable. [VERIFIED: CLAUDE.md, mailglass_inbound/docs/api_stability.md]
- Keep tenant scope explicit on persisted records and route inputs; this repo treats multi-tenancy as first-class and not retrofittable. [VERIFIED: CLAUDE.md, mailglass_inbound/lib/mailglass_inbound/inbound_message.ex, mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_record.ex]
- Use explicit seams, not magic: one obvious ingress plug/mount path, one sealed internal Postmark module, one transaction boundary. [VERIFIED: CLAUDE.md, .planning/phases/40-postmark-ingress-and-replayable-persistence/40-CONTEXT.md]
- Preserve honest evidence boundaries and do not put PII in telemetry metadata or logs. [VERIFIED: CLAUDE.md, lib/mailglass/webhook/plug.ex]
- Keep optional Oban behind package-local gateways; Phase 40 must not leak runner or job semantics into ingress work. [VERIFIED: CLAUDE.md, mailglass_inbound/lib/mailglass_inbound/optional_deps.ex, .planning/ROADMAP.md]

## Summary

Phase 40 should be planned as an inbound twin of the existing webhook ingest seam, not as a workflow engine. The recommended shape is one adopter-facing Plug mount, one internal Postmark verifier/normalizer, one `Ecto.Multi` that writes canonical plus evidence rows, and one narrow route-compatibility proof that stops before mailbox execution. [VERIFIED: .planning/phases/40-postmark-ingress-and-replayable-persistence/40-CONTEXT.md, lib/mailglass/webhook/plug.ex, lib/mailglass/webhook/ingest.ex, mailglass_inbound/lib/mailglass_inbound/router/matcher.ex]

Postmark’s docs make three planning facts non-optional: inbound requests arrive as JSON webhooks, Basic Auth is the recommended protection seam, and failed non-`200` responses are retried automatically with manual retry support later. That means idempotent persistence is not polish; it is part of the ingress contract. [CITED: https://postmarkapp.com/developer/webhooks/inbound-webhook][CITED: https://postmarkapp.com/developer/webhooks/webhooks-overview][CITED: https://postmarkapp.com/support/article/understanding-inbound-webhook-retries-in-postmark][CITED: https://postmarkapp.com/support/article/870-what-are-inbound-error-messages]

The decisive recommendation is to implement Phase 40 around four internal steps: capture exact bytes, verify Postmark credentials before tenancy, normalize only into the existing `%InboundMessage{}` fields, and persist one canonical row plus one evidence row under a Postmark-specific partial unique index on `(tenant_id, provider, provider_message_id)` where `provider_message_id IS NOT NULL`. Then run `Router.Matcher.match/2` against the normalized struct and return an internal proof result such as `{:matched, route}` or `:no_match`, with no mailbox execution. [VERIFIED: .planning/phases/40-postmark-ingress-and-replayable-persistence/40-CONTEXT.md, mailglass_inbound/lib/mailglass_inbound/inbound_message.ex, mailglass_inbound/lib/mailglass_inbound/router/matcher.ex, mailglass_inbound/priv/repo/migrations/20260506163000_create_mailglass_inbound_storage_foundation.exs][CITED: https://postmarkapp.com/developer/user-guide/inbound/parse-an-email][CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]

**Primary recommendation:** plan Phase 40 as `Plug body_reader -> ingress plug -> internal Postmark verify/normalize -> inbound Ecto.Multi -> route-compatibility proof`, with duplicate ingress returning success semantics rather than creating a second record. [VERIFIED: lib/mailglass/webhook/caching_body_reader.ex, lib/mailglass/webhook/plug.ex, lib/mailglass/webhook/ingest.ex, .planning/phases/40-postmark-ingress-and-replayable-persistence/40-CONTEXT.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Raw inbound HTTP capture | Frontend Server (SSR) | API / Backend | The Phoenix/Plug entrypoint owns exact request bytes and request headers before JSON decoding. [VERIFIED: lib/mailglass/webhook/caching_body_reader.ex][CITED: https://hexdocs.pm/plug/Plug.Parsers.html] |
| Postmark authentication | API / Backend | Frontend Server (SSR) | Verification is conn-free logic, but the mounted Plug supplies auth headers and optional remote IP. [VERIFIED: lib/mailglass/webhook/provider.ex, lib/mailglass/webhook/providers/postmark.ex][CITED: https://postmarkapp.com/developer/webhooks/webhooks-overview] |
| Tenant resolution | API / Backend | — | Tenant identity must be resolved only after a verified request and before persistence. [VERIFIED: lib/mailglass/webhook/plug.ex, .planning/phases/40-postmark-ingress-and-replayable-persistence/40-CONTEXT.md] |
| Canonical normalization | API / Backend | — | `%MailglassInbound.InboundMessage{}` is a backend value object used for routing and later mailbox execution. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/inbound_message.ex] |
| Canonical/evidence persistence | Database / Storage | API / Backend | The durable truth boundary is package-local Postgres storage written transactionally. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/inbound_records/*.ex, mailglass_inbound/priv/repo/migrations/20260506163000_create_mailglass_inbound_storage_foundation.exs][CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| Route-compatibility proof | API / Backend | — | Phase 40 only proves matcher compatibility against normalized messages; execution remains deferred. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/router/matcher.ex, .planning/phases/40-postmark-ingress-and-replayable-persistence/40-CONTEXT.md] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `plug` | `1.19.1` [VERIFIED: mix.lock] | Raw-body capture and first ingress Plug seam | Official Plug docs support custom `:body_reader`, which matches the repo’s existing `CachingBodyReader` pattern and avoids duplicating request parsing logic. [VERIFIED: lib/mailglass/webhook/caching_body_reader.ex][CITED: https://hexdocs.pm/plug/Plug.Parsers.html] |
| `phoenix` | `1.8.5` [VERIFIED: mix.lock] | Adopter-mounted route/endpoint integration | The phase needs only a normal Phoenix/Plug mount path, not a new runtime subsystem. [VERIFIED: mix.lock, .planning/phases/40-postmark-ingress-and-replayable-persistence/40-CONTEXT.md] |
| `ecto` | `3.13.5` [VERIFIED: mix.lock] | Changesets and schema-backed persistence | The repo already uses Ecto as the persistence contract and Phase 40 needs dynamic transaction steps plus conflict handling. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/inbound_records/*.ex][CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| `ecto_sql` | `3.13.5` [VERIFIED: mix.lock] | Transaction execution and migrations | Phase 40 needs one migration for idempotency and one transaction boundary for write-path correctness. [VERIFIED: mix.lock, mailglass_inbound/priv/repo/migrations/20260506163000_create_mailglass_inbound_storage_foundation.exs] |
| `jason` | `~> 1.4` declared, current lockfile-backed install in repo [VERIFIED: mix.exs, mix.lock] | JSON payload decoding | Postmark inbound posts JSON, and existing Mailglass webhook providers already normalize decoded provider payloads from raw JSON. [VERIFIED: lib/mailglass/webhook/providers/postmark.ex][CITED: https://postmarkapp.com/developer/webhooks/inbound-webhook] |
| Postgres | `14.17` available locally [VERIFIED: local env probe] | Durable canonical/evidence storage plus unique index enforcement | The project is Postgres-only and relies on database invariants for truth semantics. [VERIFIED: CLAUDE.md, local env probe] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `nimble_options` | `~> 1.1` declared [VERIFIED: mix.exs, mailglass_inbound/mix.exs] | Plug/router option validation | Use for adopter-facing ingress Plug opts so mount-time errors stay explicit and early. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/router.ex] |
| `Mailglass.Webhook.CachingBodyReader` pattern | repo-local [VERIFIED: lib/mailglass/webhook/caching_body_reader.ex] | Exact raw-body capture | Reuse the pattern on inbound JSON routes rather than inventing a second body-capture mechanism. [VERIFIED: lib/mailglass/webhook/caching_body_reader.ex][CITED: https://hexdocs.pm/plug/Plug.Parsers.html] |
| `Mailglass.Webhook.Provider` posture | repo-local [VERIFIED: lib/mailglass/webhook/provider.ex] | Sealed conn-free provider seam | Mirror this posture for internal inbound Postmark verification/normalization so provider churn stays internal. [VERIFIED: lib/mailglass/webhook/provider.ex, .planning/phases/40-postmark-ingress-and-replayable-persistence/40-CONTEXT.md] |
| `MailglassInbound.Repo` | repo-local [VERIFIED: mailglass_inbound/lib/mailglass_inbound/repo.ex] | Host-repo facade | Use for all persistence so the sibling package stays host-configured and does not own its own Repo. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/repo.ex] |
| `MailglassInbound.Router.Matcher` | repo-local [VERIFIED: mailglass_inbound/lib/mailglass_inbound/router/matcher.ex] | Narrow route-compatibility proof | Use after commit to prove normalized messages fit the Phase 39 router contract without running mailboxes. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/router/matcher.ex] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| One internal ingress Plug with `provider: :postmark` [VERIFIED: .planning/phases/40-postmark-ingress-and-replayable-persistence/40-CONTEXT.md] | A public provider behaviour adopters can implement | That would make provider internals de facto public API too early, which the context explicitly forbids. [VERIFIED: .planning/phases/40-postmark-ingress-and-replayable-persistence/40-CONTEXT.md, mailglass_inbound/docs/api_stability.md] |
| Partial unique index on `(tenant_id, provider, provider_message_id)` plus explicit duplicate outcome [VERIFIED: 40-CONTEXT.md] | Blind insert of every webhook attempt | Postmark retries non-`200` deliveries and supports manual retry, so blind inserts would create false fresh receives and replay confusion. [CITED: https://postmarkapp.com/support/article/understanding-inbound-webhook-retries-in-postmark] |
| `raw_mime: nil` unless Postmark provides `RawEmail` directly [VERIFIED: 40-CONTEXT.md] | Reconstruct MIME from parsed fields | Postmark documents an actual `RawEmail` field only when that option is enabled; reconstructing MIME would fabricate evidence rather than preserve it. [CITED: https://postmarkapp.com/manual] |
| Lowercase normalized header keys for matcher input [VERIFIED: mailglass_inbound/lib/mailglass_inbound/router/matcher.ex] | Preserve source-case header names | The current matcher does exact header-name lookup, so preserving mixed case would create avoidable route misses. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/router/matcher.ex, turn0view1/Headers example from Postmark docs] |

**Installation:**
```bash
mix deps.get
mix compile --warnings-as-errors
```
[VERIFIED: mix.exs, mailglass_inbound/mix.exs]

**Version verification:** Phase 40 does not need new third-party packages; reuse the repo’s locked Phoenix/Plug/Ecto/Jason stack and add only package-local modules plus one migration for idempotency. [VERIFIED: mix.exs, mailglass_inbound/mix.exs, mix.lock]

## Architecture Patterns

### System Architecture Diagram

```text
Postmark inbound webhook
        |
        v
Phoenix route / mounted inbound plug
        |
        v
Plug.Parsers with inbound-only body_reader
        |
        v
raw_body + req_headers
        |
        v
internal Postmark verifier
        |
        +--> reject => 401/403-style failure response, no tenant resolution, no writes
        |
        v
tenant resolution
        |
        v
pure Postmark normalizer
        |
        +--> %MailglassInbound.InboundMessage{}
        |         |
        |         v
        |   MailglassInbound.Router.Matcher.match/2
        |         |
        |         +--> {:matched, route}
        |         \--> :no_match
        |
        v
Ecto.Multi
  - insert/find canonical inbound row
  - insert/find evidence row
  - classify stored vs duplicate
        |
        v
explicit ingress result
  - {:stored, inbound_record, route_result}
  - {:duplicate, inbound_record, route_result}
  - {:rejected, reason}
```
[VERIFIED: lib/mailglass/webhook/plug.ex, lib/mailglass/webhook/ingest.ex, mailglass_inbound/lib/mailglass_inbound/router/matcher.ex, .planning/phases/40-postmark-ingress-and-replayable-persistence/40-CONTEXT.md]

### Recommended Project Structure

```text
mailglass_inbound/
├── lib/mailglass_inbound/ingress.ex                    # public/adopter-facing mount/config seam
├── lib/mailglass_inbound/ingress/plug.ex               # single inbound orchestrator
├── lib/mailglass_inbound/ingress/provider.ex           # internal sealed behaviour
├── lib/mailglass_inbound/ingress/providers/postmark.ex # verify + normalize
├── lib/mailglass_inbound/ingress/persist.ex            # Ecto.Multi write path
├── lib/mailglass_inbound/ingress/result.ex             # explicit stored/duplicate/rejected result shape
├── lib/mailglass_inbound/inbound_records/...           # existing canonical/evidence/replay schemas
└── test/mailglass_inbound/ingress/...                  # provider, plug, and persistence proof
```
[VERIFIED: 40-CONTEXT.md discretion areas, existing repo module layout]

### Pattern 1: Verify Before Tenancy Or Persistence
**What:** Keep verification ahead of tenant resolution, normalization side effects, and DB writes. [VERIFIED: lib/mailglass/webhook/plug.ex, 40-CONTEXT.md]  
**When to use:** Always for inbound webhook entrypoints. [VERIFIED: 40-CONTEXT.md]  
**Example:**
```elixir
# Source: lib/mailglass/webhook/plug.ex
{raw_body, headers} = extract_headers_and_raw_body!(conn)
config = resolve_config!(:postmark, conn)
:ok = Postmark.verify!(raw_body, headers, config)
tenant_id = resolve_tenant!(:postmark, conn, raw_body, headers)
```

### Pattern 2: Normalize Into The Stable Value Object Only
**What:** Map Postmark JSON into `%MailglassInbound.InboundMessage{}` without adding provider-only fields. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/inbound_message.ex, 40-CONTEXT.md]  
**When to use:** For all provider parsing output in Phase 40 and 41. [VERIFIED: 40-CONTEXT.md, .planning/ROADMAP.md]  
**Example:**
```elixir
# Source fields: Postmark inbound webhook docs + mailglass_inbound InboundMessage
%InboundMessage{
  tenant_id: tenant_id,
  provider: :postmark,
  provider_message_id: payload["MessageID"],
  message_id: header_value(payload["Headers"], "Message-Id"),
  envelope_recipient: payload["OriginalRecipient"],
  from: contact_list(payload["FromFull"]),
  to: contact_list(payload["ToFull"]),
  cc: contact_list(payload["CcFull"]),
  bcc: contact_list(payload["BccFull"]),
  reply_to: reply_to_contacts(payload),
  subject: payload["Subject"],
  headers: normalize_headers(payload["Headers"]),
  sent_at: parse_rfc2822(payload["Date"]),
  received_at: DateTime.utc_now(),
  text_body: payload["TextBody"],
  html_body: payload["HtmlBody"],
  attachments: attachment_manifest(payload["Attachments"])
}
```
[CITED: https://postmarkapp.com/developer/user-guide/inbound/parse-an-email][VERIFIED: mailglass_inbound/lib/mailglass_inbound/inbound_message.ex]

### Pattern 3: One Multi For Canonical Row + Evidence Row
**What:** Use `Ecto.Multi` to coordinate duplicate lookup, canonical insert-or-fetch, and evidence insert-or-fetch in one transaction. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]  
**When to use:** Every fresh ingress write path. [VERIFIED: 40-CONTEXT.md]  
**Example:**
```elixir
# Source pattern: Ecto.Multi docs + lib/mailglass/webhook/ingest.ex
Ecto.Multi.new()
|> Ecto.Multi.run(:existing_record, fn repo, _changes ->
  {:ok, repo.get_by(InboundRecord,
    tenant_id: tenant_id,
    provider: "postmark",
    provider_message_id: message.provider_message_id
  )}
end)
|> Ecto.Multi.insert(:inbound_record, record_changeset, on_conflict: :nothing, conflict_target: [:tenant_id, :provider, :provider_message_id])
|> Ecto.Multi.run(:record, fn repo, %{existing_record: existing, inbound_record: inserted} ->
  {:ok, existing || inserted || repo.get_by!(InboundRecord,
    tenant_id: tenant_id,
    provider: "postmark",
    provider_message_id: message.provider_message_id
  )}
end)
|> Ecto.Multi.insert(:evidence, evidence_changeset, on_conflict: :nothing, conflict_target: [:inbound_record_id])
|> MailglassInbound.Repo.transact()
```
[CITED: https://hexdocs.pm/ecto/Ecto.Multi.html][VERIFIED: lib/mailglass/webhook/ingest.ex, mailglass_inbound/lib/mailglass_inbound/repo.ex]

### Anti-Patterns to Avoid

- **Routing on visible `To` only:** Postmark supplies `OriginalRecipient`; using `To` alone breaks plus-address and forwarded-mail routing. [CITED: https://postmarkapp.com/developer/user-guide/inbound/parse-an-email]
- **Reconstructing raw MIME:** Preserve `RawEmail` only when Postmark includes it; otherwise leave `raw_mime` nil. [CITED: https://postmarkapp.com/manual]
- **Provider-specific field creep into `%InboundMessage{}`:** Keep `MailboxHash`, `StrippedTextReply`, spam headers, and attachment bytes out of the stable struct. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/inbound_message.ex, 40-CONTEXT.md][CITED: https://postmarkapp.com/developer/webhooks/inbound-webhook]
- **Treating duplicates as failures:** Non-`200` responses trigger retries, so duplicate ingress should resolve to a success-class outcome after verifying/persisting idempotently. [CITED: https://postmarkapp.com/support/article/understanding-inbound-webhook-retries-in-postmark]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Raw-body access | A second ad hoc body-capture plug | Plug `:body_reader` with the existing caching pattern | Plug already supports a custom body reader, and the repo already has a proven implementation. [CITED: https://hexdocs.pm/plug/Plug.Parsers.html][VERIFIED: lib/mailglass/webhook/caching_body_reader.ex] |
| Transaction choreography | Manual nested `Repo.insert` / rollback branches | `Ecto.Multi` with `run`, `insert`, and explicit duplicate classification | `Ecto.Multi` already models dependent transaction steps and error short-circuiting. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| Webhook auth scheme | Custom HMAC or token format for Postmark inbound | HTTP Basic Auth as default, optional IP allowlist as a second gate | This matches Postmark guidance and the repo’s current Postmark webhook posture. [CITED: https://postmarkapp.com/developer/webhooks/webhooks-overview][VERIFIED: lib/mailglass/webhook/providers/postmark.ex] |
| Replay provenance | New rows that look like fresh receives | Existing `ReplayRun` lineage later, linked to stored evidence | The schemas already separate fresh receive truth from replay execution history. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/inbound_records/replay_run.ex, 40-CONTEXT.md] |
| Raw MIME fallback | Synthesized MIME text from parsed JSON | `raw_mime` only when `RawEmail` is present | Reconstructed MIME is not trustworthy evidence. [CITED: https://postmarkapp.com/manual] |

**Key insight:** Phase 40 is mostly integration work between already-existing patterns. The plan should spend effort on idempotency, trustworthy evidence capture, and explicit outcomes, not on inventing new public extension surfaces. [VERIFIED: lib/mailglass/webhook/*.ex, mailglass_inbound/lib/mailglass_inbound/*.ex, 40-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Header Normalization Drift
**What goes wrong:** Routes that should match on headers do not match even though the payload contains the header. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/router/matcher.ex]  
**Why it happens:** `Router.Matcher` does exact map-key lookup, while Postmark headers arrive as a list of `%{"Name" => ..., "Value" => ...}` entries with source casing. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/router/matcher.ex][CITED: https://postmarkapp.com/developer/webhooks/inbound-webhook]  
**How to avoid:** Normalize header names to lowercase strings at parse time and keep matcher lookups lowercase. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/router/matcher.ex]  
**Warning signs:** Tests pass for body/subject but fail for header routes using mixed-case names. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/router/matcher.ex]

### Pitfall 2: Duplicate Ingress Creates Fake Fresh Receives
**What goes wrong:** Retries or manual replays create multiple canonical inbound rows for the same Postmark message. [CITED: https://postmarkapp.com/support/article/understanding-inbound-webhook-retries-in-postmark]  
**Why it happens:** The write path does not anchor idempotency on `provider_message_id`, or it returns non-`200` after persistence. [VERIFIED: 40-CONTEXT.md][CITED: https://postmarkapp.com/support/article/870-what-are-inbound-error-messages]  
**How to avoid:** Add a partial unique index, treat duplicates as explicit ingress outcomes, and keep response mapping success-class once truth is already durable. [VERIFIED: 40-CONTEXT.md, lib/mailglass/webhook/plug.ex]  
**Warning signs:** More than one `mailglass_inbound_records` row shares the same tenant/provider/provider_message_id triplet. [VERIFIED: recommended migration shape derived from 40-CONTEXT.md]

### Pitfall 3: Routing On Display Recipients Instead Of `OriginalRecipient`
**What goes wrong:** Plus-address or forwarded inbound routes miss the correct mailbox. [CITED: https://postmarkapp.com/developer/user-guide/inbound/parse-an-email]  
**Why it happens:** `To`/`ToFull` reflect visible headers, while `OriginalRecipient` captures the actual inbound target address. [CITED: https://postmarkapp.com/developer/user-guide/inbound/parse-an-email]  
**How to avoid:** Always map `OriginalRecipient` to `envelope_recipient`. [VERIFIED: 40-CONTEXT.md]  
**Warning signs:** Messages visible as `support@example.com` in headers do not match plus-address routes that should have matched the inbound target. [CITED: https://postmarkapp.com/developer/user-guide/inbound/parse-an-email]

### Pitfall 4: Fabricated Evidence
**What goes wrong:** Stored evidence looks complete but was reconstructed from parsed fields rather than preserved from the provider payload. [VERIFIED: 40-CONTEXT.md]  
**Why it happens:** The implementation tries to populate `raw_mime` or attachment contents even when Postmark did not send them. [CITED: https://postmarkapp.com/manual]  
**How to avoid:** Store raw payload JSON, selected request headers, verification facts, parse warnings, and attachment blobs only when present; leave `raw_mime` nil when `RawEmail` is absent. [VERIFIED: 40-CONTEXT.md][CITED: https://postmarkapp.com/manual]  
**Warning signs:** Evidence rows contain MIME-looking data even when the webhook JSON had no `RawEmail` field. [CITED: https://postmarkapp.com/manual]

### Pitfall 5: Verify After Tenant Resolution
**What goes wrong:** Invalid requests can influence tenant lookup paths or generate noisy app behavior before rejection. [VERIFIED: lib/mailglass/webhook/plug.ex]  
**Why it happens:** The ingress plug resolves tenancy before auth because it needs per-tenant config. [VERIFIED: lib/mailglass/webhook/plug.ex]  
**How to avoid:** Match the existing Mailglass webhook order: verify first, then tenant resolution, then persistence. [VERIFIED: lib/mailglass/webhook/plug.ex, 40-CONTEXT.md]  
**Warning signs:** Tenant resolution tests are hit during auth-failure cases. [VERIFIED: lib/mailglass/webhook/plug.ex]

## Code Examples

Verified patterns from official and repo-primary sources:

### Capture Raw Request Bytes For JSON Parsing
```elixir
# Source: https://hexdocs.pm/plug/Plug.Parsers.html
defmodule CacheBodyReader do
  def read_body(conn, opts) do
    with {:ok, body, conn} <- Plug.Conn.read_body(conn, opts) do
      conn = update_in(conn.assigns[:raw_body], &[body | &1 || []])
      {:ok, body, conn}
    end
  end
end

plug Plug.Parsers,
  parsers: [:urlencoded, :json],
  pass: ["text/*"],
  body_reader: {CacheBodyReader, :read_body, []},
  json_decoder: Jason
```
[CITED: https://hexdocs.pm/plug/Plug.Parsers.html]

### Drive Dependent Transaction Steps With `Ecto.Multi.run/3`
```elixir
# Source: https://hexdocs.pm/ecto/Ecto.Multi.html
Ecto.Multi.run(multi, :write, fn _repo, %{image: image} ->
  with :ok <- File.write(image.name, image.contents) do
    {:ok, nil}
  end
end)
```
[CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]

### Prove Route Compatibility Without Executing A Mailbox
```elixir
# Source: mailglass_inbound/lib/mailglass_inbound/router/matcher.ex
case MailglassInbound.Router.Matcher.match(routes, inbound_message) do
  {:ok, route} -> {:matched, route.mailbox}
  :no_match -> :no_match
end
```
[VERIFIED: mailglass_inbound/lib/mailglass_inbound/router/matcher.ex]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Process webhook and domain behavior inline in one callback | Persist durable inbound truth first, then separate routing and later mailbox execution | Established by Action Mailbox and similar modern inbound systems; current Rails guide still preserves record-first processing in 2026 docs. [CITED: https://guides.rubyonrails.org/action_mailbox_basics.html] | Reduces ambiguity around retries, debugging, and later replay. [CITED: https://guides.rubyonrails.org/action_mailbox_basics.html] |
| Treat provider payload as the public app contract | Normalize one common inbound message and keep raw ESP data separately accessible | Current Anymail inbound docs still split normalized message data from raw `esp_event`. [CITED: https://anymail.dev/en/stable/inbound/] | Supports multi-provider expansion without polluting the stable public struct. [CITED: https://anymail.dev/en/stable/inbound/] |
| Infer replay handling later | Design for duplicate/retry behavior at ingress time | Current Anymail and Postmark guidance both call out duplicate/retry realities explicitly. [CITED: https://anymail.dev/en/stable/inbound/][CITED: https://postmarkapp.com/support/article/understanding-inbound-webhook-retries-in-postmark] | Makes idempotency part of the first write path instead of a retrofit. [CITED: https://anymail.dev/en/stable/inbound/][CITED: https://postmarkapp.com/support/article/understanding-inbound-webhook-retries-in-postmark] |

**Deprecated/outdated:**
- Reconstructing raw MIME from provider-parsed JSON is outdated for evidence storage; preserve the provider’s raw artifact only when the provider actually sends one. [CITED: https://postmarkapp.com/manual]
- Public provider extension seams are premature for this package phase; the current repo contract inventory keeps provider internals internal. [VERIFIED: mailglass_inbound/docs/api_stability.md, 40-CONTEXT.md]

## Assumptions Log

All substantive implementation claims in this research were verified against the current repo or cited from official documentation. No user confirmation is required before planning. [VERIFIED: this document]

## Open Questions

1. **What exact public module should adopters mount?**
   - What we know: The phase wants one obvious adopter-facing ingress path and a sealed internal provider seam. [VERIFIED: 40-CONTEXT.md]
   - What's unclear: Whether the stable public mount should be `MailglassInbound.Ingress.Plug`, `MailglassInbound.Ingress`, or a small router helper.
   - Recommendation: Decide this in planning, but keep only one public ingress mount module and keep provider-specific modules internal. [VERIFIED: 40-CONTEXT.md, mailglass_inbound/docs/api_stability.md]

2. **Should the route-compatibility proof run inside or after the write transaction?**
   - What we know: The matcher is pure and mailbox execution is deferred. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/router/matcher.ex, 40-CONTEXT.md]
   - What's unclear: Whether the plan wants matcher proof included in the returned transaction result or performed after commit.
   - Recommendation: Persist first, then run the pure matcher after commit so duplicate/store semantics stay DB-focused and route proof cannot affect durability. [VERIFIED: lib/mailglass/webhook/ingest.ex pattern, 40-CONTEXT.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Compile and test `mailglass_inbound` | ✓ [VERIFIED: local env probe] | `1.19.5` [VERIFIED: local env probe] | — |
| Erlang/OTP | Runtime | ✓ [VERIFIED: local env probe] | `28` [VERIFIED: local env probe] | — |
| Mix | Compile and test commands | ✓ [VERIFIED: local env probe] | `1.19.5` [VERIFIED: local env probe] | — |
| PostgreSQL client | Storage-related verification and migration work | ✓ [VERIFIED: local env probe] | `14.17` [VERIFIED: local env probe] | — |
| Host configured Repo | Actual persistence integration tests | project-dependent [VERIFIED: mailglass_inbound/lib/mailglass_inbound/repo.ex, mailglass_inbound/test/mailglass_inbound/persistence_test.exs] | — | Use unit-level changeset and fake-repo tests if no live Repo is configured yet. [VERIFIED: mailglass_inbound/test/mailglass_inbound/persistence_test.exs] |
| Live Postmark account | Advisory live-provider checks only | not required for planning [VERIFIED: project posture + test strategy] | — | Use fixtures and Plug tests for PR-blocking coverage. [VERIFIED: CLAUDE.md, existing test posture] |

**Missing dependencies with no fallback:**
- None for planning. Actual DB-backed integration tests still require the host app to provide a configured Repo. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/repo.ex]

**Missing dependencies with fallback:**
- A live Postmark stream is not required for Phase 40 proof; fixture-based tests are sufficient for the plan’s primary verification loop. [VERIFIED: CLAUDE.md, existing test posture]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit on Mix/Elixir [VERIFIED: mailglass_inbound/test/test_helper.exs, mix.exs] |
| Config file | `mix.exs`, `config/test.exs`, `mailglass_inbound/test/test_helper.exs` [VERIFIED: repo files] |
| Quick run command | `mix test mailglass_inbound/test/mailglass_inbound` [VERIFIED: repo structure] |
| Full suite command | `mix test` [VERIFIED: mix.exs] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| INGRESS-01 | Reject unverifiable Postmark inbound requests before tenancy/persistence | unit + Plug integration | `mix test mailglass_inbound/test/mailglass_inbound/ingress/postmark_provider_test.exs mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs` | ❌ Wave 0 |
| INGRESS-01 | Normalize Postmark payload fields into canonical `%InboundMessage{}` including `OriginalRecipient`, `MessageID`, structured contacts, headers, and attachment manifest | unit | `mix test mailglass_inbound/test/mailglass_inbound/ingress/postmark_provider_test.exs` | ❌ Wave 0 |
| STORE-01 | Persist one canonical row plus one evidence row in one transaction | integration | `mix test mailglass_inbound/test/mailglass_inbound/ingress/persist_test.exs` | ❌ Wave 0 |
| STORE-01 | Duplicate Postmark ingress reuses existing truth instead of inserting a second fresh receive | integration | `mix test mailglass_inbound/test/mailglass_inbound/ingress/persist_test.exs` | ❌ Wave 0 |
| INGRESS-01 / STORE-01 | Route matcher can evaluate the normalized message without mailbox execution | unit | `mix test mailglass_inbound/test/mailglass_inbound/ingress/route_compatibility_test.exs` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `mix test mailglass_inbound/test/mailglass_inbound`
- **Per wave merge:** `mix test`
- **Phase gate:** Full relevant inbound package tests green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `mailglass_inbound/test/mailglass_inbound/ingress/postmark_provider_test.exs` — covers verify/normalize semantics for `INGRESS-01`
- [ ] `mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs` — covers response mapping, verify-before-tenancy, and duplicate/no-match handling
- [ ] `mailglass_inbound/test/mailglass_inbound/ingress/persist_test.exs` — covers canonical/evidence transaction and idempotency for `STORE-01`
- [ ] `mailglass_inbound/test/mailglass_inbound/ingress/route_compatibility_test.exs` — covers matcher proof against normalized Postmark messages
- [ ] If no live Repo-backed test helper exists for inbound persistence, add one shared fixture helper under `mailglass_inbound/test/support/` before implementation. [VERIFIED: current inbound tests are mostly contract/unit-level]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes [VERIFIED: webhook auth is part of ingress trust boundary] | HTTP Basic Auth default, optional IP allowlist, fail closed on verification failure. [CITED: https://postmarkapp.com/developer/webhooks/webhooks-overview][VERIFIED: lib/mailglass/webhook/providers/postmark.ex] |
| V3 Session Management | no [VERIFIED: webhook endpoint is stateless] | — |
| V4 Access Control | yes [VERIFIED: tenant resolution and provider trust boundary] | Verify first, then resolve tenant, then scope persistence to explicit `tenant_id`. [VERIFIED: lib/mailglass/webhook/plug.ex, mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_record.ex] |
| V5 Input Validation | yes | `NimbleOptions` for opts, changesets for persistence, explicit parser helpers for provider payload shape. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/router.ex, inbound record schemas] |
| V6 Cryptography | yes | `Plug.Crypto.secure_compare/2` for Basic Auth credential comparison; no custom crypto. [VERIFIED: lib/mailglass/webhook/providers/postmark.ex] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Forged webhook POST | Spoofing | Basic Auth verification before any other work, optional IP allowlist, HTTPS-only deployment guidance. [CITED: https://postmarkapp.com/developer/webhooks/webhooks-overview][VERIFIED: lib/mailglass/webhook/providers/postmark.ex] |
| Cross-tenant record creation | Elevation of privilege | Resolve tenant only after verification and stamp every canonical/evidence row with `tenant_id`. [VERIFIED: lib/mailglass/webhook/plug.ex, mailglass_inbound/lib/mailglass_inbound/inbound_records/*.ex] |
| Retry storm duplicates | Denial of service / Repudiation | Partial unique index, explicit duplicate outcome, and success-class response after durable write. [VERIFIED: 40-CONTEXT.md][CITED: https://postmarkapp.com/support/article/understanding-inbound-webhook-retries-in-postmark] |
| Evidence leakage in logs or telemetry | Information disclosure | Keep payload bytes, headers, and message content out of telemetry/log metadata; store only in evidence tables with redaction. [VERIFIED: CLAUDE.md, lib/mailglass/webhook/plug.ex, mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_evidence.ex] |
| Oversized or malformed payload abuse | Denial of service | Keep Plug parser limits explicit on inbound routes and reject malformed/unauthorized requests early. [VERIFIED: lib/mailglass/webhook/caching_body_reader.ex][CITED: https://hexdocs.pm/plug/Plug.Parsers.html] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/40-postmark-ingress-and-replayable-persistence/40-CONTEXT.md` - locked phase scope, sequencing, and decisions. [VERIFIED: local file]
- `.planning/REQUIREMENTS.md` - `INGRESS-01` and `STORE-01`. [VERIFIED: local file]
- `lib/mailglass/webhook/plug.ex` - verify-first orchestration pattern. [VERIFIED: local file]
- `lib/mailglass/webhook/provider.ex` - sealed conn-free provider seam precedent. [VERIFIED: local file]
- `lib/mailglass/webhook/providers/postmark.ex` - current Postmark auth posture and `secure_compare` use. [VERIFIED: local file]
- `lib/mailglass/webhook/ingest.ex` - current `Ecto.Multi` ingest pattern. [VERIFIED: local file]
- `lib/mailglass/webhook/caching_body_reader.ex` - raw-body capture implementation. [VERIFIED: local file]
- `mailglass_inbound/lib/mailglass_inbound/inbound_message.ex` - stable canonical value object contract. [VERIFIED: local file]
- `mailglass_inbound/lib/mailglass_inbound/router/matcher.ex` - route-proof seam and header lookup behavior. [VERIFIED: local file]
- `mailglass_inbound/lib/mailglass_inbound/inbound_records/*.ex` - canonical/evidence/replay schema boundaries. [VERIFIED: local files]
- `https://postmarkapp.com/developer/webhooks/inbound-webhook` - inbound JSON shape, `MessageID`, `OriginalRecipient`, structured contact fields. [CITED: https://postmarkapp.com/developer/webhooks/inbound-webhook]
- `https://postmarkapp.com/developer/webhooks/webhooks-overview` - Basic Auth recommendation and optional IP allowlisting. [CITED: https://postmarkapp.com/developer/webhooks/webhooks-overview]
- `https://postmarkapp.com/developer/user-guide/inbound/parse-an-email` - inbound field semantics and example payload. [CITED: https://postmarkapp.com/developer/user-guide/inbound/parse-an-email]
- `https://postmarkapp.com/manual` - `RawEmail` availability and inbound webhook Basic Auth guidance. [CITED: https://postmarkapp.com/manual]
- `https://postmarkapp.com/support/article/understanding-inbound-webhook-retries-in-postmark` - retry behavior and manual retry posture. [CITED: https://postmarkapp.com/support/article/understanding-inbound-webhook-retries-in-postmark]
- `https://postmarkapp.com/support/article/870-what-are-inbound-error-messages` - 2-minute webhook response wait and failed inbound behavior. [CITED: https://postmarkapp.com/support/article/870-what-are-inbound-error-messages]
- `https://hexdocs.pm/plug/Plug.Parsers.html` - custom `:body_reader` pattern. [CITED: https://hexdocs.pm/plug/Plug.Parsers.html]
- `https://hexdocs.pm/ecto/Ecto.Multi.html` - `run`, dependent steps, and transaction composition. [CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]

### Secondary (MEDIUM confidence)

- `https://guides.rubyonrails.org/action_mailbox_basics.html` - durable inbound record + explicit routing/mailbox separation precedent. [CITED: https://guides.rubyonrails.org/action_mailbox_basics.html]
- `https://anymail.dev/en/stable/inbound/` - normalized inbound message plus raw ESP event separation and duplicate-awareness precedent. [CITED: https://anymail.dev/en/stable/inbound/]

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - the phase reuses already-locked repo dependencies and official Plug/Ecto APIs. [VERIFIED: mix.lock][CITED: https://hexdocs.pm/plug/Plug.Parsers.html][CITED: https://hexdocs.pm/ecto/Ecto.Multi.html]
- Architecture: HIGH - the ingress shape is strongly constrained by Phase 40 context plus existing webhook and inbound package code. [VERIFIED: 40-CONTEXT.md, lib/mailglass/webhook/*.ex, mailglass_inbound/lib/mailglass_inbound/*.ex]
- Pitfalls: HIGH - the main failure modes are directly evidenced by current matcher/storage code and official Postmark retry/raw-email behavior. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/router/matcher.ex, 40-CONTEXT.md][CITED: https://postmarkapp.com/support/article/understanding-inbound-webhook-retries-in-postmark][CITED: https://postmarkapp.com/manual]

**Research date:** 2026-05-06 [VERIFIED: local system date]  
**Valid until:** 2026-06-05 for repo-local architecture; re-check Postmark support/docs before implementation if planning slips beyond 30 days. [VERIFIED: current research date][CITED: https://postmarkapp.com/support/article/understanding-inbound-webhook-retries-in-postmark]

## RESEARCH COMPLETE

**Phase:** 40 - Postmark Ingress and Replayable Persistence [VERIFIED: .planning/ROADMAP.md]  
**Confidence:** HIGH [VERIFIED: this document]

### Key Findings

- Reuse the existing Mailglass webhook house style: inbound-only raw-body capture, conn-free provider verification, verify-first ordering, and one transaction boundary. [VERIFIED: lib/mailglass/webhook/*.ex, 40-CONTEXT.md]
- Postmark inbound retries make idempotent persistence a first-class requirement; plan a partial unique index on `(tenant_id, provider, provider_message_id)` and explicit duplicate outcomes. [VERIFIED: 40-CONTEXT.md][CITED: https://postmarkapp.com/support/article/understanding-inbound-webhook-retries-in-postmark]
- Normalize only into the locked `%MailglassInbound.InboundMessage{}` fields, especially mapping `OriginalRecipient` to `envelope_recipient` and keeping `provider_message_id` distinct from RFC `message_id`. [VERIFIED: 40-CONTEXT.md, mailglass_inbound/lib/mailglass_inbound/inbound_message.ex][CITED: https://postmarkapp.com/developer/user-guide/inbound/parse-an-email]
- Store raw evidence honestly: payload JSON, selected headers, verification facts, parse warnings, and attachment blobs; keep `raw_mime` nil unless Postmark supplies `RawEmail`. [VERIFIED: 40-CONTEXT.md, mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_evidence.ex][CITED: https://postmarkapp.com/manual]
- Keep the Phase 40 route proof narrow: matcher evaluation only, no mailbox execution, no replay-run creation during fresh ingress. [VERIFIED: 40-CONTEXT.md, mailglass_inbound/lib/mailglass_inbound/router/matcher.ex, mailglass_inbound/lib/mailglass_inbound/inbound_records/replay_run.ex]

### File Created
`/Users/jon/projects/mailglass/.planning/phases/40-postmark-ingress-and-replayable-persistence/40-RESEARCH.md` [VERIFIED: this file path]

### Confidence Assessment

| Area | Level | Reason |
|------|-------|--------|
| Standard Stack | HIGH | Reuses existing repo dependencies and official Plug/Ecto APIs; no speculative new library choice is needed. [VERIFIED: mix.lock][CITED: https://hexdocs.pm/plug/Plug.Parsers.html][CITED: https://hexdocs.pm/ecto/Ecto.Multi.html] |
| Architecture | HIGH | The phase is tightly constrained by locked context decisions and already-shipped webhook/inbound seams. [VERIFIED: 40-CONTEXT.md, lib/mailglass/webhook/*.ex, mailglass_inbound/lib/mailglass_inbound/*.ex] |
| Pitfalls | HIGH | The main risks are directly supported by current code behavior and current Postmark docs. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/router/matcher.ex][CITED: https://postmarkapp.com/support/article/understanding-inbound-webhook-retries-in-postmark][CITED: https://postmarkapp.com/manual] |

### Open Questions

- Exact public ingress module name for the adopter mount seam.
- Whether route-compatibility proof is returned from the transaction result or run immediately after commit.

### Ready for Planning

Research complete. Planner can now create `PLAN.md` files for Phase 40. [VERIFIED: this document]
