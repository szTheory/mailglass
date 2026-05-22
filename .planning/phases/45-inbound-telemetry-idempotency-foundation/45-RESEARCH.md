# Phase 45: Inbound Telemetry + Idempotency Foundation - Research

**Researched:** 2026-05-22
**Domain:** Elixir/Phoenix telemetry instrumentation, gen_smtp MIME parsing, StreamData property testing, cross-package Credo enforcement
**Confidence:** HIGH (most claims verified against in-repo source + gen_smtp 1.3.0 source)

<user_constraints>
## User Constraints (from CONTEXT.md)

CONTEXT.md locks 18 decisions (D-45-01..18). These are AUTHORITATIVE. This research
closes the remaining technical unknowns the planner needs; it does not re-derive locked choices.

### Locked Decisions (verbatim summary — full text in 45-CONTEXT.md)

**Telemetry emission + span placement:**
- **D-45-01:** Reuse `Mailglass.Telemetry.span/3` for fixed-metadata spans; add a co-located
  `MailglassInbound.Telemetry` module mirroring `Mailglass.Webhook.Telemetry.span_with_enrichment/3`
  (calls `:telemetry.span/3` directly, accepts a fn returning `result` or `{result, stop_metadata}`)
  for outcome-dependent stop metadata. Single inbound telemetry module = one Credo audit surface.
- **D-45-02:** Span wrap points are fixed (4 sites — see Architecture below):
  ingress→`Ingress.Plug.call/2`, route→`Router.Matcher.match/2`, persist→the `repo.transact`
  in `Ingress.Persist.persist/2`, execution→`Execution.execute/2` (NOT `dispatch/2`).
- **D-45-03:** Metadata PII-free: allowed = provider, tenant_id, status, latency, byte_size,
  matched-mailbox identity/no-match/candidate count, mailbox module, outcome, source, operation,
  record_type. Never recipient/sender/body/html_body/subject/headers/email/to/from.
- **D-45-04:** Handler raise-safety (TELE-05) is free from `:telemetry.span/3` semantics. No custom rescue.

**TELE-06 Credo extension:**
- **D-45-05:** Extend `NoPiiInTelemetryMeta` (`credo_checks/no_pii_in_telemetry_meta.ex`) to cover
  `mailglass_inbound/`. Determine whether this is `.credo.exs` path-scope, check-internal, or both,
  and verify boundary classification handles cross-package inbound modules.

**TELE-07 PubSub:**
- **D-45-06:** Broadcast directly on `Phoenix.PubSub` (server `Mailglass.PubSub`), POST-COMMIT, after
  `Ingress.Persist.persist/2` returns `:inserted`. Mirror `Mailglass.Outbound.Projector`. No
  telemetry-handler→PubSub bridge. Never broadcast inside the persist transaction.
- **D-45-07:** Exactly ONE new topic, per-tenant. Default `"mailglass:inbound:" <> tenant_id`.
- **D-45-08:** Topic builder lives in new `MailglassInbound.PubSub.Topics` (e.g. `inbound_record_inserted/1`).
  No inbound→admin compile dependency. Admin (Phase 48) stays a pure consumer.

**TELE-08 convergence:**
- **D-45-09:** Mirror `WebhookIdempotencyConvergenceTest`: `use ExUnit.Case, async: false` +
  `use ExUnitProperties` (NOT DataCase), `Sandbox.start_owner!(shared: true, ownership_timeout: 10*60_000)`,
  `TRUNCATE … CASCADE` between iterations, `max_runs: 1000`, `@moduletag timeout: :infinity`, `@moduletag :property`.
- **D-45-10:** Drive the real write path through synchronous `Execution.execute/2`, NOT async `dispatch/2`.
- **D-45-11:** Assert exactly one `InboundRecord` per `(tenant_id, provider, provider_message_id)` AND
  exactly one fresh `ExecutionRun` per inserted record. Dedupe anchored on
  `mailglass_inbound_records_postmark_idempotency_idx`; replays return `:duplicate`; `execute/2`
  short-circuits `%{status: :duplicate}` → `:skipped` (zero extra ExecutionRun rows).
- **D-45-12:** Generator: `gen all`, draw `provider_message_id` from a small `member_of` pool (≤4 ids)
  over `list_of(payload, max_length: 10)`, with `integer(1..10)` replay multiplier. Postmark-style
  string-keyed JSON, `MessageID` as dedupe key.

**MIME parser:**
- **D-45-13:** `MailglassInbound.MIME` is net-new. Parse via `:mimemail.decode/1` from gen_smtp 1.3.0,
  gated through `Mailglass.OptionalDeps.GenSmtp` — extend the gateway (today only `available?/0`),
  add the parse seam there, not scattered `Code.ensure_loaded?` calls.
- **D-45-14:** Decoded shape is the 5-tuple `{Type, SubType, Headers, Parameters, Body}` where
  `Parameters` is a MAP. Multipart Body = list (recurse); message/rfc822 = single tuple; leaf = binary.
  Classify attachment/inline from `Parameters.disposition`; filename from `disposition_params["filename"]`
  then `content_type_params["name"]`. Do NOT depend on `decode_attachment(s)` toggle.
- **D-45-15:** Never-raise: `:mimemail.decode/1` raises via BOTH `erlang:error/1` AND `throw/1`. Wrap in
  `try/rescue` AND `catch :throw`, consider `catch :exit` (iconv). Pass `{allow_missing_version, true}`;
  consider `{encoding, none}` to skip iconv. Return `{:error, struct}`, never raise.
- **D-45-16:** Add NEW `MailglassInbound.MIMEError` defexception, canonical shape
  `[:type, :message, :cause, :context]`, closed `:type` set `[:inbound_mime_invalid, :gen_smtp_unavailable]`.
  Public-contract addition: CHANGELOG + `@since` + `__types__/0`-style test, minor version bump.
  **(SUPERSEDES REQUIREMENTS.md MIME-04 which says `Mailglass.Error{type: :inbound_mime_invalid}` —
  `Mailglass.Error` is a behaviour/namespace with no parent struct, so a new struct is required.)**
- **D-45-17:** Degraded fallback (MIME-02): when `GenSmtp.available?/0` is false, return
  `{:error, %MailglassInbound.MIMEError{type: :gen_smtp_unavailable}}` (or documented minimal
  headers+raw-body representation). `mix compile --no-optional-deps --warnings-as-errors` must pass —
  all `:mimemail` references via the gateway.
- **D-45-18:** MIME parser built STANDALONE in Phase 45, NOT wired into Postmark/SendGrid normalization.
  First consumer is Phase 46 (Mailgun/SES raw-MIME).

### Claude's Discretion
- Exact internal fn names/signatures of `MailglassInbound.Telemetry` and the `GenSmtp` parse seam.
- Exact internal representation struct(s) returned by `MailglassInbound.MIME`.
- Exact mechanics of the `NoPiiInTelemetryMeta` cross-package scoping (config vs check internals).
- Exact StreamData generator helper shapes, provided the D-45-11 invariant holds.

### Deferred Ideas (OUT OF SCOPE)
- Wiring `MailglassInbound.MIME` into a provider normalize path → Phase 46.
- Admin LiveView subscribing to the TELE-07 topic → Phase 48.
- `mailglass.inbound.doctor` MIME backend availability (MIME-03) → Phase 49.
- Broader MIME fuzzing / attachment-shape property tests beyond dedupe convergence.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TELE-01 | `[:mailglass_inbound, :ingress, :request, :start\|:stop\|:exception]` spans per ingress, PII-free meta | Wrap `Ingress.Plug.call/2` body via new `MailglassInbound.Telemetry`. `:telemetry.span/3` gives 3-phase events. Metadata whitelist confirmed (D-45-03). See Pattern 1. |
| TELE-02 | `[:mailglass_inbound, :route, :match, *]` spans, matched/no-match/candidate-count meta | Wrap `Router.Matcher.match/2`. Returns `{:ok, Route.t()}` or `:no_match` — outcome-dependent → use enrichment span. See Pattern 1. |
| TELE-03 | `[:mailglass_inbound, :execution, :run, *]` spans (Oban + Task.Supervisor paths), mailbox/outcome/source meta | Wrap `Execution.execute/2` — the single shared sync entry both paths funnel through (worker→`execute/2`; task fallback→`execute/2`). Outcome + source computed here (verified). See Pattern 1 + Pitfall 5. |
| TELE-04 | `[:mailglass_inbound, :persist, :record, *]` spans, operation(insert/update/dedup_skip)/record_type meta | Wrap `repo.transact` in `Ingress.Persist.persist/2`. Result status `:inserted`→`insert`, `:duplicate`→`dedup_skip` (verified result shape). See Pattern 1. |
| TELE-05 | Raising handler doesn't break business logic | Free from `:telemetry.span/3` handler isolation (verified in `Mailglass.Telemetry` moduledoc + `Mailglass.Webhook.Telemetry`). No custom rescue. Test: attach a raising handler, assert pipeline still succeeds. |
| TELE-06 | All metadata passes `NoPiiInTelemetry`; check extended to cover `mailglass_inbound/` | **HARDEST. Root `.credo.exs` `included: ["lib/","test/"]` is repo-root-relative — inbound code at `mailglass_inbound/lib/` is NOT linted today.** See Pitfall 1 + Architecture "Credo coverage". Also `TelemetryEventConvention` will FALSE-POSITIVE on `:mailglass_inbound` root (see Pitfall 2). |
| TELE-07 | Inbound events surfaced through PubSub for admin LiveView | Post-commit direct broadcast mirroring `Outbound.Projector` + `safe_broadcast/2`. New `MailglassInbound.PubSub.Topics.inbound_record_inserted/1` → `"mailglass:inbound:" <> tenant_id`. See Pattern 2. |
| TELE-08 | StreamData 1000-replay convergence: one InboundRecord + one ExecutionRun per unique payload | Mirror `WebhookIdempotencyConvergenceTest` BUT **needs a real Postgres test repo for inbound — none exists today (all inbound tests use FakeRepo).** Major Wave 0 gap. See Validation Architecture + Pitfall 3. |
| MIME-01 | `MailglassInbound.MIME` parses RFC 5322 → stable internal repr (headers/parts/attachments/inline) | `:mimemail.decode/1` 5-tuple verified against gen_smtp 1.3.0 source. Parameters is a map; recurse multipart. See MIME section + Code Examples. |
| MIME-02 | Gated through `Mailglass.OptionalDeps.GenSmtp`; degraded fallback documented | Gateway exists (`available?/0` only) — extend with parse seam. `gen_smtp` declared optional in CORE mix.exs, NOT in inbound mix.exs. See Pitfall 6. |
| MIME-04 | Malformed payloads never raise; structured error | `decode/1` raises via `erlang:error` AND `throw` (both verified). `try/rescue` + `catch :throw, :exit`. Returns `{:error, %MailglassInbound.MIMEError{}}` (D-45-16 supersedes REQUIREMENTS wording). See MIME section. |
</phase_requirements>

## Summary

Phase 45 makes `mailglass_inbound` the observable, idempotent sibling of the already-shipped
outbound webhook ingest seam. Three deliverables: (1) four-level `:telemetry` spans at four fixed
wrap points, (2) a standalone `MailglassInbound.MIME` parser over `:mimemail.decode/1`, gated through
the existing `Mailglass.OptionalDeps.GenSmtp`, that never raises, and (3) a 1000-replay StreamData
convergence proof through the real persist+route+execute write path. CONTEXT.md already locks the
architecture in unusual detail and is research-backed; nearly every code anchor it names was verified
to exist with the assumed signature.

Three findings materially affect planning beyond what CONTEXT.md anticipated. **First (highest impact):
the inbound test suite has no real database** — every existing inbound test uses an in-memory `FakeRepo`
stub, and there is no inbound CI job that runs `mix test` against Postgres. The TELE-08 convergence proof
requires a real Postgres-backed repo with inbound migrations applied; standing that up (test repo, sandbox,
migration runner, CI wiring) is a Wave 0 prerequisite, not a detail. **Second: the root Credo run does not
currently lint `mailglass_inbound/` at all** — `.credo.exs` uses `included: ["lib/", "test/"]` which are
repo-root-relative, so inbound code is invisible to `mix credo --strict`. TELE-06 therefore requires both a
config/path-scope change AND a way to actually invoke Credo against the inbound tree. **Third: the existing
`TelemetryEventConvention` Credo check hard-codes `required_root: :mailglass` and will false-positive on every
`[:mailglass_inbound, ...]` event** the new spans emit — this check must be reconfigured or scoped before the
inbound spans can pass lint.

The MIME never-raise contract was verified against the actual gen_smtp 1.3.0 `mimemail.erl` source:
`decode/1` can escape through `erlang:error` (`non_mime_multipart`, `no_boundary`, `missing_boundary`,
`missing_last_boundary`, `{mime_version, _}`, `unterminated_quotes`, `unterminated_comment`) AND through
`throw` (`bad_content_type`, `bad_disposition`, `badchar`) AND through `:exit`/`:error :undef` if iconv is
invoked but `:iconv` is not installed (gen_smtp does NOT bundle iconv). A `rescue`-only wrapper is insufficient.

**Primary recommendation:** Plan four waves. Wave 0: stand up the inbound test database (repo + sandbox +
migrations) and the Credo-coverage mechanism for `mailglass_inbound/` — these unblock TELE-06 and TELE-08.
Wave 1 (parallel): `MailglassInbound.Telemetry` + the four span wrap sites (TELE-01..05); the `MailglassInbound.MIME`
parser + extended `GenSmtp` gateway + `MailglassInbound.MIMEError` (MIME-01/02/04); `MailglassInbound.PubSub.Topics`
+ post-commit broadcast (TELE-07). Wave 2: the 1000-replay convergence property (TELE-08, depends on Wave 0 DB).
Wave 3: Credo extension lands green across both packages + CI wiring (TELE-06).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Telemetry span emission | `mailglass_inbound` lib (instrumentation) | core `Mailglass.Telemetry` (reused span/3) | Inbound owns its event paths; reuses core's span wrapper + execute/3 single-emit. |
| PII enforcement (Credo) | core `credo_checks/` (the check itself) | `.credo.exs` + CI (scoping) | Check is shared tooling in core; scoping it to inbound is config + CI plumbing. |
| Post-commit PubSub broadcast | `mailglass_inbound` (producer at persist site) | core `Phoenix.PubSub`/`Mailglass.PubSub` (transport) | Producer logic lives where the commit happens; transport server is shared. Admin = pure consumer. |
| Topic string contract | `mailglass_inbound` `PubSub.Topics` (builder) | `mailglass_admin` `PubSub.Topics` (subscriber, Phase 48) | One canonical builder per producing package; admin matches the string, no edge. |
| MIME parsing | `mailglass_inbound` `MailglassInbound.MIME` | core `Mailglass.OptionalDeps.GenSmtp` (gateway) → `:mimemail` | Inbound owns the parser + internal repr; gateway in core owns the optional-dep seam. |
| MIME error contract | `mailglass_inbound` `MailglassInbound.MIMEError` | — (mirrors core `Mailglass.Error` discipline) | Package-local error; correct that it lives in inbound, not core. |
| Convergence proof | `mailglass_inbound` test suite | a real Postgres test repo (NEW infra) | Idempotency invariant is an inbound write-path property; needs real DB. |

## Standard Stack

### Core (all already in `mix.lock` — VERIFIED)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:telemetry` | 1.4.2 `[VERIFIED: mix.lock]` | Span emission + handler isolation | Project's locked telemetry primitive; `span/3` gives start/stop/exception + handler try/catch. |
| `gen_smtp` | 1.3.0 `[VERIFIED: mix.lock + GitHub source]` | `:mimemail.decode/1` MIME parsing | Already an optional dep of core (and of Swoosh). The `mimemail` module is the de-facto Erlang MIME decoder. |
| `stream_data` | 1.3.0 `[VERIFIED: mix.lock]` | Property generators for convergence proof | Project's locked property-test lib; `gen all`/`check all` macros via `ExUnitProperties`. |
| `ecto_sql` | 3.14.0 (core) / `~> 3.13` (inbound) `[VERIFIED: mix.lock + inbound mix.exs]` | `Repo.transact`, `Ecto.Adapters.SQL.Sandbox` | Sandbox + TRUNCATE idiom for the convergence proof. |
| `phoenix_pubsub` | 2.1 (via `phoenix` 1.8.7) `[VERIFIED: mix.lock]` | TELE-07 broadcast/subscribe | `Mailglass.PubSub` server already running; reuse it. |

### Supporting (in-repo modules to reuse — VERIFIED to exist)
| Module | Purpose | When to Use |
|--------|---------|-------------|
| `Mailglass.Telemetry.span/3` | Fixed-metadata span wrapper | When stop metadata == call-time metadata (no enrichment needed). |
| `Mailglass.Telemetry.execute/3` | Single-emit `:telemetry.execute` | Per-event signals inside a wrapping span (rarely needed here). |
| `Mailglass.Webhook.Telemetry.span_with_enrichment/3` (pattern) | Outcome-dependent stop metadata | The pattern `MailglassInbound.Telemetry` must MIRROR (it is `defp`, so copy the body, don't call it cross-module). |
| `Mailglass.Outbound.Projector.broadcast_delivery_updated/3` + `safe_broadcast/2` | Post-commit direct broadcast template | TELE-07 — copy `safe_broadcast/2` (rescue `[ArgumentError, RuntimeError]` + `catch :exit`). |
| `Mailglass.OptionalDeps.GenSmtp` | Optional-dep gateway (`available?/0` only today) | Extend with the MIME parse seam (D-45-13). |
| `Mailglass.ConfigError` (struct shape) | Canonical `[:type,:message,:cause,:context]` + `__types__/0` template | The exact shape `MailglassInbound.MIMEError` must follow. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `:mimemail.decode/1` | `mail` (hex `~> 0.2`, Swoosh's optional dep) | `mail` is pure Elixir (no iconv risk) but D-45-13 LOCKS gen_smtp. Out of scope to revisit. |
| Real Postgres test repo for inbound | Keep FakeRepo + assert on changeset shapes | FakeRepo CANNOT prove DB-level dedupe (the unique index is the dedupe anchor). TELE-08 REQUIRES real DB. No alternative. |
| Driving `Execution.execute/2` (sync) | `dispatch/2` (async) | D-45-10 LOCKS sync `execute/2` — async makes ExecutionRun counts non-deterministic. Verified: `dispatch/2` routes to Oban or detached Task.Supervisor. |

**No new external packages are required.** `gen_smtp` and `stream_data` are already resolved.

## Package Legitimacy Audit

> No new external packages are installed by this phase. All dependencies (`gen_smtp`, `stream_data`,
> `telemetry`, `ecto_sql`, `phoenix_pubsub`) are already present in `mix.lock` and were verified there.

| Package | Registry | Version | Source Repo | slopcheck | Disposition |
|---------|----------|---------|-------------|-----------|-------------|
| gen_smtp | hex | 1.3.0 (in lock) | github.com/gen-smtp/gen_smtp | N/A (pre-existing) | Already resolved; no new install |
| stream_data | hex | 1.3.0 (in lock) | github.com/whatyouhide/stream_data | N/A (pre-existing) | Already resolved; no new install |
| telemetry | hex | 1.4.2 (in lock) | github.com/beam-telemetry/telemetry | N/A (pre-existing) | Already resolved; no new install |

**Packages removed due to slopcheck [SLOP] verdict:** none (no new packages).
**Packages flagged as suspicious [SUS]:** none.

**One dependency-manifest change IS required (not a new package, a scoping fix):**
`gen_smtp` is declared `{:gen_smtp, "~> 1.3", optional: true}` in CORE `mailglass/mix.exs` (line 153,
VERIFIED) but is NOT declared in `mailglass_inbound/mix.exs` (VERIFIED: 0 matches). Because the
`Mailglass.OptionalDeps.GenSmtp` gateway lives in core and inbound depends on `:mailglass`, `:mimemail`
IS transitively available at runtime when the host installs `gen_smtp`. The planner must decide whether
`mailglass_inbound/mix.exs` should also declare `{:gen_smtp, "~> 1.3", optional: true}` so the inbound
package's own test/dev env can load `:mimemail` and so adopters of inbound-without-core (not a supported
shape, but worth a doc note) get the optional dep advertised. **Recommendation:** add the optional dep to
inbound mix.exs for test/dev availability — without it, the MIME tests cannot exercise the real parser in
the inbound suite. Verify `mix compile --no-optional-deps --warnings-as-errors` still passes (the gateway's
`@compile {:no_warn_undefined, [:gen_smtp_client]}` covers the client module; the parse seam must add
`:mimemail` to the no-warn list).

## Architecture Patterns

### System Architecture Diagram

```
                    ┌─────────────────────────── inbound ingress request ───────────────────────────┐
                    │                                                                                 │
                    ▼                                                                                 │
  ╔═══════════════════════════════════╗   provider verify → tenant resolve → normalize               │
  ║ Ingress.Plug.call/2               ║                                                               │
  ║  TELE-01 span                     ║   [:mailglass_inbound, :ingress, :request, start|stop|exc]    │
  ║  meta: provider, status,          ║                                                               │
  ║        byte_size, latency         ║                                                               │
  ╚═══════════════╤═══════════════════╝                                                               │
                  │ handoff{tenant_id, provider, message, evidence}                                   │
                  ▼                                                                                    │
  ╔═══════════════════════════════════╗                                                               │
  ║ Ingress.Persist.persist/2         ║                                                               │
  ║   repo.transact do                ║   TELE-04 span wraps the transact                             │
  ║     load_duplicate? ──yes──► :duplicate  [:mailglass_inbound,:persist,:record,*] op=dedup_skip    │
  ║     └─no─► insert record+evidence ║                                op=insert  record_type=...     │
  ║   end                             ║                                                               │
  ╚═══════════════╤═══════════════════╝                                                               │
                  │ {:ok, %{status: :inserted|:duplicate, route: ..., message: ...}}                  │
       ┌──────────┴───────────────┐                                                                   │
       │ status==:inserted        │ status==:duplicate                                                │
       ▼                          ▼                                                                   │
  ╔═══════════════╗      (no broadcast, no execute)                                                   │
  ║ POST-COMMIT   ║                                                                                   │
  ║ broadcast     ║  TELE-07: Phoenix.PubSub.broadcast(Mailglass.PubSub,                              │
  ║ safe_broadcast║       MailglassInbound.PubSub.Topics.inbound_record_inserted(tenant_id),         │
  ║               ║       {:inbound_record_inserted, record_id, meta})  ← OUTSIDE the transact       │
  ╚═══════╤═══════╝                                                                                   │
          │                                                                                           │
          │  Router.Matcher.match/2 (route compat already computed in persist; TELE-02 span)          │
          │  TELE-02: [:mailglass_inbound, :route, :match, *] meta: matched|no_match, candidate_count │
          ▼                                                                                           │
  ╔═══════════════════════════════════╗                                                               │
  ║ Execution.dispatch/2 (async)      ║──Oban──► Execution.Worker.perform ──► Execution.execute/2     │
  ║   runner: :oban | :task_supervisor║──Task──► Task.Supervisor child  ────► Execution.execute/2     │
  ╚═══════════════════════════════════╝                                          │                    │
                                                              ╔═══════════════════▼═══════════════╗   │
                                                              ║ Execution.execute/2  ◄── WRAP HERE ║   │
                                                              ║  TELE-03 span (single point covers ║   │
                                                              ║  BOTH async paths)                 ║   │
                                                              ║  [:mailglass_inbound,:execution,:run,*]│
                                                              ║  meta: mailbox, outcome, source    ║   │
                                                              ║  insert_execution_run (1 row)      ║   │
                                                              ╚════════════════════════════════════╝   │
                                                                                                       │
  ─────────────────────────── MIME parser (STANDALONE, no consumer wired in Phase 45) ───────────────┘
  ╔═══════════════════════════════════════════════════════════════════════════╗
  ║ MailglassInbound.MIME.parse(raw)                                           ║
  ║   if Mailglass.OptionalDeps.GenSmtp.available?()  ── no ──► {:error,       ║
  ║      │                                              %MIMEError{gen_smtp_unavailable}}             ║
  ║      ▼ yes                                                                 ║
  ║   GenSmtp.decode(raw)  (gateway parse seam)                               ║
  ║      try  :mimemail.decode(raw, [{allow_missing_version,true},{encoding,none}])                  ║
  ║      rescue error → {:error, %MIMEError{inbound_mime_invalid}}            ║   (erlang:error atoms)║
  ║      catch :throw → {:error, %MIMEError{inbound_mime_invalid}}            ║   (bad_content_type…) ║
  ║      catch :exit  → {:error, %MIMEError{inbound_mime_invalid}}            ║   (iconv missing)     ║
  ║   → {:ok, %{headers, parts, attachments, inline}}  (stable internal repr) ║
  ╚═══════════════════════════════════════════════════════════════════════════╝
```

### Recommended Module Structure (new files)
```
mailglass_inbound/lib/mailglass_inbound/
├── telemetry.ex                 # NEW: MailglassInbound.Telemetry — span/3 (fixed) + span_with_enrichment/3 (outcome)
├── mime.ex                      # NEW: MailglassInbound.MIME — parse/1,2 → stable internal repr (never raises)
├── mime_error.ex               # NEW: MailglassInbound.MIMEError — defexception, closed :type set
└── pub_sub/
    └── topics.ex                # NEW: MailglassInbound.PubSub.Topics — inbound_record_inserted/1

mailglass/lib/mailglass/optional_deps/
└── gen_smtp.ex                  # EDIT: add parse seam (decode/2 wrapper) alongside available?/0

mailglass_inbound/test/
├── support/                     # NEW (likely): test repo + data_case for real Postgres
│   ├── test_repo.ex
│   └── data_case.ex (or property_case)
├── config/test.exs              # NEW: config :mailglass_inbound, :repo + repo credentials
└── mailglass_inbound/
    ├── telemetry_test.exs       # NEW: span coverage + raise-safety (TELE-01..05)
    ├── mime_test.exs            # NEW: parse + never-raise (MIME-01,02,04)
    ├── pub_sub/topics_test.exs  # NEW: topic shape + LINT-06 (TELE-07)
    └── properties/
        └── inbound_idempotency_convergence_test.exs   # NEW: 1000-replay (TELE-08)
```

### Pattern 1: Outcome-Enrichment Telemetry Span (the inbound `MailglassInbound.Telemetry`)

**What:** A package-local span helper module that owns ALL inbound `:telemetry.span/3` calls, so the
extended `NoPiiInTelemetry` check has one surface (plus call sites) to audit. It needs BOTH shapes:
fixed-metadata (delegate to / mirror `Mailglass.Telemetry.span/3`) and outcome-enriched (mirror
`Mailglass.Webhook.Telemetry`'s private `span_with_enrichment/3` — that function is `defp`, so the body
must be COPIED, not called).

**When to use:** TELE-01..04. Ingress/persist/execution/route all need outcome in stop metadata
(status, operation, outcome, source) which is only known after the inner fn returns.

```elixir
# Source: mirrors lib/mailglass/webhook/telemetry.ex span_with_enrichment/3 (VERIFIED in-repo)
defmodule MailglassInbound.Telemetry do
  @moduledoc """
  Single span surface for mailglass_inbound (mirrors Mailglass.Webhook.Telemetry).
  All inbound :telemetry.span/3 calls live here so NoPiiInTelemetry has one audit module.
  """

  @spec ingress_span(map(), (-> result | {result, map()})) :: result when result: term()
  def ingress_span(metadata, fun), do: span([:mailglass_inbound, :ingress, :request], metadata, fun)

  @spec route_span(map(), (-> result | {result, map()})) :: result when result: term()
  def route_span(metadata, fun), do: span([:mailglass_inbound, :route, :match], metadata, fun)

  @spec persist_span(map(), (-> result | {result, map()})) :: result when result: term()
  def persist_span(metadata, fun), do: span([:mailglass_inbound, :persist, :record], metadata, fun)

  @spec execution_span(map(), (-> result | {result, map()})) :: result when result: term()
  def execution_span(metadata, fun), do: span([:mailglass_inbound, :execution, :run], metadata, fun)

  # Copied body (the webhook version is defp): supports `{result, stop_metadata}` enrichment.
  defp span(event_prefix, metadata, fun) do
    :telemetry.span(event_prefix, metadata, fn ->
      case fun.() do
        {result, %{} = stop_metadata} -> {result, stop_metadata}
        result -> {result, metadata}
      end
    end)
  end
end
```

**Call-site example (persist, TELE-04):**
```elixir
# In Ingress.Persist.persist/2 — wrap the repo.transact, derive operation from result status
MailglassInbound.Telemetry.persist_span(
  %{tenant_id: tenant_id, provider: provider, record_type: "inbound_record"},
  fn ->
    result = repo.transact(fn -> ... end)   # existing body
    operation = case result do
      {:ok, %{status: :inserted}}  -> :insert
      {:ok, %{status: :duplicate}} -> :dedup_skip
      _ -> :error
    end
    {result, %{tenant_id: tenant_id, provider: provider,
               operation: operation, record_type: "inbound_record"}}
  end
)
```

### Pattern 2: Post-Commit Direct PubSub Broadcast (TELE-07)

**What:** After `persist/2` commits with `:inserted`, broadcast on `Mailglass.PubSub` from OUTSIDE the
transaction. Mirror `Mailglass.Outbound.Projector.broadcast_delivery_updated/3` + `safe_broadcast/2`.

**When to use:** TELE-07 only. The broadcast must NOT live inside `repo.transact` (D-45-06 invariant).
The natural site is `Ingress.Plug.call/2` after `persistence.persist(...)` returns `{:ok, %{status: :inserted}}`,
which is already outside the transact (the transact is inside `Persist.persist/2`).

```elixir
# Source: mirrors lib/mailglass/outbound/projector.ex safe_broadcast/2 (VERIFIED in-repo)
defmodule MailglassInbound.PubSub.Topics do
  @doc since: "0.2.0"   # minor bump — public contract addition
  @spec inbound_record_inserted(String.t()) :: String.t()
  def inbound_record_inserted(tenant_id) when is_binary(tenant_id),
    do: "mailglass:inbound:" <> tenant_id
end

# Broadcast helper (co-located near the persist/plug site):
defp broadcast_inbound_inserted(%{tenant_id: tid, inbound_record: %{id: rid}} = result) do
  topic = MailglassInbound.PubSub.Topics.inbound_record_inserted(tid)
  meta = %{provider: result.message.provider, record_type: "inbound_record"}  # PII-free
  _ = safe_broadcast(topic, {:inbound_record_inserted, rid, meta})
  :ok
end

defp safe_broadcast(topic, payload) do
  Phoenix.PubSub.broadcast(Mailglass.PubSub, topic, payload)
rescue
  e in [ArgumentError, RuntimeError] -> require Logger; Logger.debug("[mailglass_inbound] broadcast failed (non-fatal): #{Exception.message(e)}"); :ok
catch
  :exit, reason -> require Logger; Logger.debug("[mailglass_inbound] broadcast exited (non-fatal): #{inspect(reason)}"); :ok
end
```
**LINT-06 note:** `PrefixedPubSubTopics` only checks LITERAL string args to `Phoenix.PubSub.broadcast/subscribe`
(VERIFIED: it pattern-matches `is_binary(topic)`). Because the topic comes from `Topics.inbound_record_inserted/1`
(a function call, not a literal), the check passes — exactly why D-45-08 routes through a builder. The string the
builder returns starts with `mailglass:`, so even a literal would pass.

### Anti-Patterns to Avoid
- **Calling `:telemetry.span/3` directly at the four wrap sites.** Route everything through
  `MailglassInbound.Telemetry` so `NoPiiInTelemetry` (which lints `:telemetry.span` and `:telemetry.execute`
  call sites) has one module + call sites to audit. Bare `:telemetry.span/3` scattered across files defeats
  the single-surface rationale (D-45-01).
- **Broadcasting inside `repo.transact`.** Couples PubSub availability to commit success and can fire on a
  rolled-back transaction. Broadcast post-commit, in `Plug.call/2` after `{:ok, %{status: :inserted}}` (D-45-06).
- **Wrapping `dispatch/2` for TELE-03.** `dispatch/2` enqueues (Oban) or spawns detached (Task.Supervisor);
  the outcome/source is computed in `execute/2`, and both async paths funnel through `execute/2` (VERIFIED).
- **`rescue`-only MIME wrapper.** `:mimemail.decode/1` `throw`s `bad_content_type`/`bad_disposition`/`badchar`
  which `rescue` does NOT catch — they escape and violate MIME-04. Need `catch :throw` too (and `:exit` for iconv).
- **Asserting convergence against `FakeRepo`.** The dedupe anchor is a Postgres unique index; a stub can't prove it.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Telemetry span emission | Manual `:telemetry.execute(:start)` + `try/after :stop` | `:telemetry.span/3` (via `MailglassInbound.Telemetry`) | span/3 emits start/stop/exception AND isolates handler crashes (TELE-05 free). |
| Handler raise-safety | `try/rescue` around business code "to protect it" | Nothing — `:telemetry.span/3` already isolates handlers | Custom rescue would swallow real business errors and the meta `[:telemetry,:handler,:failure]` event (D-45-04). |
| MIME / RFC 5322 parsing | Hand-rolled header/boundary/quoted-printable parser | `:mimemail.decode/1` | MIME is a tar pit: nested multipart, encoded-words, transfer-encodings, charsets. gen_smtp handles it. |
| Idempotency dedupe | App-level "have I seen this?" cache | Postgres unique index `mailglass_inbound_records_postmark_idempotency_idx` + `:duplicate` short-circuit | Race-safe at the DB; the convergence proof verifies app respects it (VERIFIED: index is unique). |
| PubSub broadcast safety | Letting broadcast exceptions bubble | `safe_broadcast/2` (rescue + catch :exit) | PubSub server may be down during shutdown; the committed row is the source of truth (mirror Projector). |
| Topic string construction | Inline `"mailglass:inbound:#{tid}"` at call site | `MailglassInbound.PubSub.Topics.inbound_record_inserted/1` | Avoids LINT-06 literal-string flag and creates a single contract point (D-45-08). |

**Key insight:** Every primitive this phase needs already exists in the outbound seam. The work is
*mirroring*, not *inventing* — the one genuinely new build is the MIME internal-representation struct
(Claude's discretion) and the never-raise wrapper around a library that raises two different ways.

## Runtime State Inventory

> Phase 45 is additive instrumentation + a new standalone parser + a new test. It is NOT a rename/
> refactor/migration of stored runtime state. Each category is answered explicitly below.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — no schema renames, no key migrations. `ExecutionRun`/`ReplayRun`/`InboundRecord` schemas unchanged. New telemetry/PubSub/MIME are not persisted. | None |
| Live service config | None — no external service config embeds new strings. The new PubSub topic `"mailglass:inbound:<tenant>"` is dynamic and runtime-only (admin subscribes in Phase 48, not now). | None |
| OS-registered state | None — no Task Scheduler / systemd / pm2 registrations involved. | None |
| Secrets / env vars | None new. `config :mailglass_inbound, :repo` already exists (FakeRepo today); Wave 0 adds a TEST-env repo config + Postgres credentials (test-only, mirrors core `config/test.exs`). | Add test-env repo config (Wave 0) |
| Build artifacts | One manifest change: `mailglass_inbound/mix.exs` SHOULD add `{:gen_smtp, "~> 1.3", optional: true}` for test/dev availability of `:mimemail` (currently absent — VERIFIED). After adding, `mix deps.get` in inbound. | Add optional dep + `mix deps.get` |

**The canonical question (after every file is updated, what runtime state still holds an old value?):**
Nothing is renamed, so nothing stale persists. The only new persistent surface is the test database
created in Wave 0, which is greenfield.

## Common Pitfalls

### Pitfall 1: Root Credo never sees `mailglass_inbound/` (TELE-06)
**What goes wrong:** You extend `NoPiiInTelemetry`'s `blocked_keys` and add inbound paths, but `mix credo
--strict` still reports zero inbound issues — because it never reads inbound files.
**Why it happens:** `.credo.exs` (root) uses `files: %{included: ["lib/", "test/"], excluded: []}` —
these are repo-root-relative globs. Inbound code lives at `mailglass_inbound/lib/` and `mailglass_inbound/test/`,
which are NOT under root `lib/`/`test/`. CI runs `mix credo --strict` ONLY from repo root
(VERIFIED: `.github/workflows/ci.yml` line 196). There is NO inbound Credo CI job (VERIFIED: no
`working-directory: mailglass_inbound` for credo). `included_path_prefixes` in two custom checks is also
`["lib/mailglass/"]` (VERIFIED: lines 30, 52 of `.credo.exs`) — even those won't match inbound.
**How to avoid:** Two viable mechanisms (planner picks one, both may be needed):
  (a) **Config path-scope:** add `"mailglass_inbound/lib/"` + `"mailglass_inbound/test/"` to root `.credo.exs`
      `included`, AND verify each custom check's own path filters (`NoBareOptionalDepReference` and
      `NoDirectDateTimeNow` use `included_path_prefixes: ["lib/mailglass/"]` — these would silently SKIP
      inbound; widen or accept they don't apply). Then `mix credo --strict` from root covers both packages
      in one run. Simplest; one CI job.
  (b) **Separate inbound Credo run:** add a `working-directory: mailglass_inbound` Credo CI step + an
      inbound `.credo.exs` that `requires: ["../credo_checks/*.ex"]`. More isolation, more CI surface.
**Recommendation:** Option (a) — widen root `.credo.exs` `included`. It is the smallest change and matches
how `mix credo --strict` is already invoked. The planner MUST verify after the change that inbound files
actually appear in `mix credo --strict` output (e.g. introduce a temporary `%{to: "x"}` in an inbound span
call and confirm it's flagged, then revert).
**Warning signs:** `mix credo --strict` runtime/file-count unchanged after adding inbound paths.

### Pitfall 2: `TelemetryEventConvention` false-positives on `:mailglass_inbound` root
**What goes wrong:** Once Credo actually lints inbound (Pitfall 1), the inbound spans
`[:mailglass_inbound, :ingress, :request]` trip `TelemetryEventConvention`, which requires the FIRST
segment to be exactly `:mailglass`.
**Why it happens:** `.credo.exs` configures `{Mailglass.Credo.TelemetryEventConvention, [required_root:
:mailglass, min_segments: 4]}` (VERIFIED line 44) and the check flags any event whose root != `required_root`
(VERIFIED: `root == required_root` guard in the check). `:mailglass_inbound` != `:mailglass`. NOTE: the check
ALSO only inspects `:telemetry.execute` calls, NOT `:telemetry.span` (VERIFIED: only one `walk/5` clause,
matching `{:., _, [:telemetry, :execute]}`). So if inbound uses `:telemetry.span/3` exclusively (it should,
per Pattern 1), the convention check may not fire on the span calls at all — but it WILL fire on any single-emit
`:telemetry.execute` (none planned for inbound, but verify).
**How to avoid:** Decide the contract: either (a) inbound events legitimately root at `:mailglass_inbound`
(they do — TELE-01..04 wording and success criteria use `[:mailglass_inbound, ...]`), so the check must accept
both roots — change `required_root` handling to allow `:mailglass` OR `:mailglass_inbound` (the check takes a
single atom param today; needs a list or a second config entry / scope), OR (b) confirm inbound emits only via
`:telemetry.span` (which the check ignores) so no change is needed. **Recommendation:** confirm (b) holds (no
`:telemetry.execute` in inbound) AND defensively widen the check to accept `:mailglass_inbound` so a future
single-emit doesn't silently break. This is a contract decision the planner should surface.
**Warning signs:** Credo fails on inbound telemetry event paths after Pitfall 1 is fixed.

### Pitfall 3: No real Postgres for the convergence proof (TELE-08)
**What goes wrong:** You write the property test mirroring `WebhookIdempotencyConvergenceTest`, but it can't
run — `MailglassInbound.Repo` raises "requires config :mailglass_inbound, :repo", and there's no test repo,
no migrations applied, no sandbox, and no CI job to run it.
**Why it happens:** Every existing inbound test uses an in-memory `FakeRepo`/`ReplayRepo` stub (VERIFIED:
`persistence_test.exs` defines `FakeRepo`; `replay_test.exs` defines `ReplayRepo`; `async_execution_test.exs`
uses process-dict stubs). The outbound proof relies on `Mailglass.TestRepo` which lives in core's
`test/support/test_repo.ex` (VERIFIED) — inbound has no equivalent. There is no inbound test job with a
`postgres` service in `.github/workflows/ci.yml` (VERIFIED: postgres services exist only for core jobs +
admin). Inbound migrations exist at `mailglass_inbound/priv/repo/migrations/` (4 files, VERIFIED) but nothing
runs them in test.
**How to avoid (Wave 0):**
  1. Create `mailglass_inbound/test/support/test_repo.ex` (an Ecto.Repo, Postgres adapter), or reuse a shared
     repo. Cleanest: a dedicated `MailglassInbound.TestRepo` configured via `config :mailglass_inbound, :repo,
     MailglassInbound.TestRepo` in a new `mailglass_inbound/config/test.exs` (mirror core `config/test.exs`
     credentials + `MIX_TEST_PARTITION`).
  2. Apply ALL 4 inbound migrations to the test DB (`Ecto.Migrator` in `test_helper.exs` or a `mix ecto.migrate`
     CI step) — including `mailglass_inbound_records_postmark_idempotency_idx` (the dedupe anchor) and the
     `mailglass_inbound_replay_runs` table (ExecutionRun + ReplayRun share it — see Pitfall 4).
  3. Add a CI job (or extend an existing one) with a `postgres:16-alpine` service that runs the inbound suite
     (at minimum the `@property` test; the property is `@moduletag timeout: :infinity` + `max_runs: 1000`, so
     consider a dedicated tagged job).
  4. Sandbox: `Sandbox.start_owner!(MailglassInbound.TestRepo, shared: true, ownership_timeout: 10*60_000)`
     and `TRUNCATE … CASCADE` between iterations (the append-only trigger forbids UPDATE/DELETE — VERIFIED the
     pattern in both core convergence tests).
**Warning signs:** Property test raises `RuntimeError ... :repo` or hangs on connection checkout.

### Pitfall 4: `ExecutionRun` and `ReplayRun` share one table — count by `source`, not by schema
**What goes wrong:** D-45-11 asserts "exactly one `ExecutionRun` per inserted record." A naive
`Repo.aggregate(ExecutionRun, :count)` also counts `ReplayRun` rows, because BOTH schemas map to the SAME
table `mailglass_inbound_replay_runs` (VERIFIED: `execution_run.ex` line 38 `schema "mailglass_inbound_replay_runs"`;
`replay_run.ex` line 37 same table). A replay during the property run would inflate the count.
**Why it happens:** The Phase-40/41 "generalize replay_runs to execution lineage" migration renamed the table's
role but kept the physical name; `ExecutionRun` distinguishes itself via the `source` enum (`:fresh | :replay`,
VERIFIED) and `ReplayRun` hard-codes `source: :replay`.
**How to avoid:** Assert "exactly one row with `source: :fresh`" per inserted `InboundRecord` (the property
drives only fresh ingress via `execute/2` with default `source: :fresh`). Query
`from(r in ExecutionRun, where: r.source == :fresh and r.inbound_record_id == ^id)` and assert count == 1.
This precisely matches success criterion 5 ("one fresh `ExecutionRun`").
**Warning signs:** ExecutionRun count > number of unique inserted records.

### Pitfall 5: `execute/2` is the convergence entry point but `dispatch/2` is the production entry point
**What goes wrong:** `Ingress.Plug.call/2` calls `execution.dispatch(result)` (VERIFIED line 206), NOT
`execute/2`. The TELE-03 span must wrap `execute/2` (D-45-02) so it covers both async paths, but the
convergence proof (D-45-10) ALSO drives `execute/2` directly (bypassing `dispatch`). These are consistent:
the span is on `execute/2`, both `dispatch` paths terminate in `execute/2`, and the proof calls `execute/2`
synchronously to avoid Oban/Task non-determinism.
**Why it happens:** `dispatch/2` → Oban worker → `execute/2`, OR → Task.Supervisor child → `execute/2`
(VERIFIED: `dispatch_task_supervisor` calls `execution.execute(persisted, ...)` in the task body, and
`Execution.Worker.perform` calls `execution.execute(persisted, ...)`).
**How to avoid:** Wrap the TELE-03 span INSIDE `Execution.execute/2` (the function body), not at the call
sites. The convergence test then exercises the exact instrumented path. Do NOT also wrap `dispatch/2` (would
double-count or emit spans for enqueue-only operations).
**Warning signs:** TELE-03 spans missing for Oban-path executions, or double spans.

### Pitfall 6: iconv is not installed — `{encoding, none}` is mandatory, not optional
**What goes wrong:** `:mimemail.decode/1` defaults `encoding` to `get_default_encoding()` →
`<<"utf-8//IGNORE">>` (VERIFIED line 1350-1351), which routes header/body decoding through
`iconv:convert/3` (VERIFIED line 339). gen_smtp does NOT bundle iconv (its docstring says you must list
`iconv` as a separate dep — VERIFIED lines 33-34, 52). If `:iconv` isn't loaded, the call raises (an
`:undef` error or, depending on the iconv binding, an `:exit`). A `rescue`-only wrapper that doesn't also
`catch :exit` could let it escape, violating MIME-04.
**Why it happens:** `decode/1` builds `?DEFAULT_OPTIONS` which sets `{encoding, get_default_encoding()}`
(VERIFIED lines 81-89) — so the iconv path is the DEFAULT.
**How to avoid:** Call `:mimemail.decode(raw, opts)` (arity 2) with explicit
`opts = [{:allow_missing_version, true}, {:encoding, :none}]`. With `encoding: none`, `decode_headers/3`
short-circuits (VERIFIED line 225 `decode_headers(Headers, _, none)`) and `decode_body` skips conversion
(VERIFIED line 616 `decode_body(Type, Body, _InEncoding, none)`) — no iconv call. Caveat: with `none`, the
caller receives bytes in the original transfer/charset encoding (no UTF-8 transcoding), which is fine for a
"stable internal representation" that records the raw decoded parts; document this. Still keep `catch :exit`
defensively.
**Note on `allow_missing_version`:** `decode/1` (arity 1) DEFAULTS `allow_missing_version` to `true` (via
`?DEFAULT_OPTIONS`, VERIFIED line 87), but the internal `decode/3` uses `false` as the proplists default
(VERIFIED line 158). Since `MailglassInbound.MIME` should call `decode/2` with explicit opts, set it
explicitly to `true` so messages lacking `MIME-Version` parse instead of raising `non_mime_multipart`.
**Warning signs:** `UndefinedFunctionError ... iconv.convert/3` or `:exit` escaping `MailglassInbound.MIME`.

## Code Examples

Verified patterns from gen_smtp 1.3.0 source and in-repo modules.

### gen_smtp `:mimemail.decode` raise/throw surface (VERIFIED against 1.3.0 source)
```
# Source: https://raw.githubusercontent.com/gen-smtp/gen_smtp/1.3.0/src/mimemail.erl
# erlang:error (caught by `rescue`):
  line 164: erlang:error(non_mime_multipart)        # multipart C-T but no MIME-Version & allow_missing_version=false
  line 223: erlang:error(non_mime)                   # ENCODE path only (decode never hits this)
  line 356: erlang:error(no_boundary)                # multipart with no boundary= parameter
  line 404: erlang:error({mime_version, Other})      # unrecognized MIME-Version value
  line 439: erlang:error(unterminated_quotes)        # header tokenizer
  line 441: erlang:error(unterminated_comment)       # header tokenizer
  line 514: erlang:error(missing_boundary)           # boundary marker absent in body
  line 516: erlang:error(missing_last_boundary)      # closing boundary absent
  line 692: erlang:error(missing_from)               # ENCODE path only
# throw (NOT caught by `rescue` — needs `catch :throw`):
  line 477,485: throw(bad_content_type)              # Content-Type lacks "/" or unparseable
  line 500:     throw(bad_disposition)               # Content-Disposition malformed
  line 659:     throw(badchar)                        # quoted-printable bad char after soft EOL
# DKIM-only throws (NOT on the decode path): {not_supported, dkim_body_relaxed}, Ed25519 OTP message.
# iconv (can :exit or :undef if :iconv not installed): line 339 iconv:convert/3 (avoided by encoding: none)
```

### Decoded 5-tuple shape (VERIFIED lines 342-403, 151-200)
```elixir
# {Type, SubType, Headers, Parameters, Body}
#   Type, SubType :: binary   e.g. <<"text">>, <<"plain">> | <<"multipart">>, <<"mixed">>
#   Headers       :: [{binary, binary}]  (proplist of decoded headers)
#   Parameters    :: MAP with keys (atoms):
#       content_type_params  => [{binary, binary}]   (e.g. [{<<"charset">>, <<"utf-8">>}, {<<"name">>, ...}])
#       disposition          => binary  (<<"inline">> default | <<"attachment">>)
#       disposition_params   => [{binary, binary}]   (e.g. [{<<"filename">>, <<"a.pdf">>}])
#       transfer_encoding    => binary  (OPTIONAL — declared in @type but NOT set by decode_component;
#                                        use Map.get(params, :transfer_encoding) — may be absent)
#   Body :: binary (leaf) | mimetuple (message/rfc822) | [mimetuple] (multipart — RECURSE)
#
# Attachment classification (D-45-14):  is_attachment = (params.disposition == <<"attachment">>)
# Filename: disposition_params["filename"] || content_type_params["name"]
```

### Never-raise parse seam (gateway extension + MIME module)
```elixir
# Source: extends lib/mailglass/optional_deps/gen_smtp.ex (VERIFIED gateway shape)
defmodule Mailglass.OptionalDeps.GenSmtp do
  @compile {:no_warn_undefined, [:gen_smtp_client, :mimemail]}   # add :mimemail to no-warn list

  def available?, do: Code.ensure_loaded?(:gen_smtp_client)

  @doc since: "1.2.0"
  @spec decode(binary(), keyword()) :: {:ok, tuple()} | {:error, term()}
  def decode(raw, opts \\ []) when is_binary(raw) do
    erl_opts = [{:allow_missing_version, true}, {:encoding, :none}] ++ opts
    {:ok, :mimemail.decode(raw, erl_opts)}
  rescue
    e -> {:error, {:error, e}}            # erlang:error atoms (no_boundary, missing_boundary, ...)
  catch
    :throw, reason -> {:error, {:throw, reason}}   # bad_content_type, bad_disposition, badchar
    :exit, reason  -> {:error, {:exit, reason}}    # iconv / eiconv unavailable
  end
end

# Source: new MailglassInbound.MIME — translates to the public error contract, never raises
defmodule MailglassInbound.MIME do
  alias Mailglass.OptionalDeps.GenSmtp
  alias MailglassInbound.MIMEError

  @spec parse(binary()) :: {:ok, map()} | {:error, MIMEError.t()}
  def parse(raw) when is_binary(raw) do
    if GenSmtp.available?() do
      case GenSmtp.decode(raw) do
        {:ok, decoded} -> {:ok, to_internal(decoded)}     # build stable repr (Claude's discretion)
        {:error, cause} ->
          {:error, %MIMEError{type: :inbound_mime_invalid,
                              message: "MIME parse failed",
                              cause: cause, context: %{byte_size: byte_size(raw)}}}
      end
    else
      {:error, %MIMEError{type: :gen_smtp_unavailable,
                          message: "gen_smtp optional dependency is not loaded",
                          cause: nil, context: %{}}}
    end
  end
end
```

### `MailglassInbound.MIMEError` (mirror `Mailglass.ConfigError` shape — VERIFIED template)
```elixir
# Source: mirrors lib/mailglass/errors/config_error.ex (VERIFIED: @types, __types__/0, @derive, defexception)
defmodule MailglassInbound.MIMEError do
  @types [:inbound_mime_invalid, :gen_smtp_unavailable]
  @derive {Jason.Encoder, only: [:type, :message, :context]}    # :cause excluded (may carry payload)
  defexception [:type, :message, :cause, :context]

  @type t :: %__MODULE__{
          type: :inbound_mime_invalid | :gen_smtp_unavailable,
          message: String.t(), cause: term() | nil, context: map()}

  @doc since: "0.2.0"   # inbound minor bump (0.1.0 → 0.2.0 at Phase 50.5)
  def __types__, do: @types

  @impl true
  def message(%__MODULE__{message: m}), do: m
end
# Note: Mailglass.Error is a behaviour with a parent @type union (VERIFIED) — MIMEError is package-local
# and does NOT add itself to Mailglass.Error's union (it lives in mailglass_inbound). Document in
# mailglass_inbound/docs/api_stability.md + add a __types__/0 test mirroring core's error_test.exs.
```

### Convergence property skeleton (mirror `WebhookIdempotencyConvergenceTest` — VERIFIED template)
```elixir
# Source: mirrors test/mailglass/properties/webhook_idempotency_convergence_test.exs (VERIFIED)
defmodule MailglassInbound.Properties.InboundIdempotencyConvergenceTest do
  use ExUnit.Case, async: false
  use ExUnitProperties
  import Ecto.Query
  alias Ecto.Adapters.SQL.Sandbox
  alias MailglassInbound.TestRepo          # NEW (Wave 0)
  alias MailglassInbound.InboundRecords.{InboundRecord, ExecutionRun}

  @moduletag :property
  @moduletag timeout: :infinity

  setup do
    owner = Sandbox.start_owner!(TestRepo, shared: true, ownership_timeout: 10 * 60_000)
    TestRepo.query!("TRUNCATE TABLE mailglass_inbound_records CASCADE", [])
    TestRepo.query!("TRUNCATE TABLE mailglass_inbound_replay_runs CASCADE", [])
    on_exit(fn -> Sandbox.stop_owner(owner) end)
    :ok
  end

  property "1000-replay convergence: one InboundRecord + one fresh ExecutionRun per unique payload" do
    check all(
            payloads <- list_of(payload_gen(), min_length: 1, max_length: 10),
            replay_count <- integer(1..10),
            max_runs: 1000
          ) do
      TestRepo.query!("TRUNCATE TABLE mailglass_inbound_records CASCADE", [])
      TestRepo.query!("TRUNCATE TABLE mailglass_inbound_replay_runs CASCADE", [])

      for p <- payloads, _ <- 1..replay_count do
        {:ok, persisted} = MailglassInbound.Ingress.Persist.persist(handoff(p), [])   # real persist
        _ = MailglassInbound.Execution.execute(persisted, source: :fresh)             # real execute (sync)
      end

      unique_ids = payloads |> Enum.map(& &1["MessageID"]) |> Enum.uniq()
      assert TestRepo.aggregate(InboundRecord, :count) == length(unique_ids)
      # Pitfall 4: count only :fresh ExecutionRun rows (table is shared with ReplayRun)
      fresh = TestRepo.aggregate(from(r in ExecutionRun, where: r.source == :fresh), :count)
      assert fresh == length(unique_ids)
    end
  end

  # D-45-12: small member_of pool so collisions occur across list elements
  defp payload_gen do
    gen all(msg_id <- member_of(["m1", "m2", "m3", "m4"]),
            record_type <- member_of(["Inbound"])) do
      %{"MessageID" => msg_id, "RecordType" => record_type, "From" => "a@b.test", "To" => "x@y.test"}
    end
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `:mimemail` Parameters as proplist (older gen_smtp 0.x/1.0) | Parameters is a MAP with `content_type_params`/`disposition`/`disposition_params` keys | gen_smtp 1.x | D-45-14 is correct — use map accessors (`Map.get`), not proplist lookups. VERIFIED in 1.3.0. |
| `Mailglass.Error{type: :inbound_mime_invalid}` (REQUIREMENTS.md MIME-04) | New `MailglassInbound.MIMEError` struct (D-45-16) | This phase | `Mailglass.Error` has no parent struct (VERIFIED) — the old wording was unimplementable. |
| Inbound tests against `FakeRepo` (in-memory) | Real Postgres test repo for the convergence proof | This phase (Wave 0) | First DB-backed inbound test; establishes infra Phases 46-49 will reuse. |

**Deprecated/outdated:**
- REQUIREMENTS.md MIME-04 wording (`Mailglass.Error{...}`): superseded by D-45-16. Plan to the struct.
- Assuming `mix credo --strict` covers inbound: it does not (root-relative paths). Plan to fix.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `transfer_encoding` key may be ABSENT from the decode Parameters map (declared in @type but not set in `decode_component`) — use `Map.get(params, :transfer_encoding)` | MIME / Code Examples | LOW — verified `decode_component` sets only 3 keys (lines 342-403); a `Map.fetch!` would crash. Use `Map.get`. |
| A2 | With `{encoding, :none}`, decoded part bytes are NOT UTF-8-transcoded (caller gets original charset/transfer encoding for leaf bodies pre-transfer-decode where applicable) | Pitfall 6 | MEDIUM — affects what the "stable internal representation" stores. If Phase 46 needs UTF-8 text, it may need iconv OR app-side transcoding. Document the degraded-charset behavior; flag for Phase 46. |
| A3 | gen_smtp does not bundle iconv, so the default encoding path raises when `:iconv` is absent | Pitfall 6 | LOW — verified by docstring (lines 33-34, 52). Worst case it's installed and the issue is moot; `encoding: none` is safe either way. |
| A4 | The cleanest TELE-06 fix is widening root `.credo.exs` `included` (option a) | Pitfall 1 | MEDIUM — option (b) separate inbound run is also valid; planner should choose and VERIFY inbound files actually get linted (the failure mode is silent). |
| A5 | A dedicated `MailglassInbound.TestRepo` (not reusing `Mailglass.TestRepo`) is the right Wave-0 shape | Pitfall 3 / Validation | MEDIUM — reusing core's TestRepo + running inbound migrations against it is also possible and may be simpler (one DB). Planner decides; either way inbound migrations must be applied. |
| A6 | Inbound emits ONLY via `:telemetry.span` (no `:telemetry.execute`), so `TelemetryEventConvention` (which only inspects `execute`) won't fire on spans | Pitfall 2 | MEDIUM — if any single-emit `:telemetry.execute([:mailglass_inbound,...])` is added, it WILL be flagged. Defensively widen the check to accept `:mailglass_inbound`. |
| A7 | Adding `{:gen_smtp, "~> 1.3", optional: true}` to `mailglass_inbound/mix.exs` is needed for inbound test/dev to load `:mimemail` | Package Audit | LOW — it's transitively available via core, but the inbound suite needs it loaded to test the real parser. Confirm `--no-optional-deps` lane stays green. |

## Open Questions

1. **Which repo backs the inbound convergence test — a new `MailglassInbound.TestRepo` or core's `Mailglass.TestRepo` with inbound migrations applied?**
   - What we know: inbound has no test DB today; inbound migrations exist at `mailglass_inbound/priv/repo/migrations/`; core has `Mailglass.TestRepo` + Postgres CI.
   - What's unclear: whether to run inbound migrations into core's test DB (one DB, simplest CI) or stand up a separate inbound test repo + CI job.
   - Recommendation: prefer a dedicated `MailglassInbound.TestRepo` configured via `config :mailglass_inbound, :repo` in a new inbound `config/test.exs`, with all 4 migrations applied in `test_helper.exs`. It keeps the package self-contained and matches the `Repo` facade design. Surface as a planning decision (Claude's discretion per D-45-09 mentions only structure).

2. **Does CI need a new job to run the inbound `@property` suite, and where?**
   - What we know: no inbound `mix test` job exists in `ci.yml`; the property is `max_runs: 1000` + `timeout: :infinity`.
   - What's unclear: whether to add a `working-directory: mailglass_inbound` test job (with postgres service) or fold inbound tests into an existing core job.
   - Recommendation: add a dedicated inbound test CI job with a `postgres:16-alpine` service (mirror `support_contract_core`); tag the 1000-run property so it can be gated/timed separately. Planner should confirm with release engineering posture.

3. **Should `TelemetryEventConvention` accept `:mailglass_inbound` as a valid root, or is span-only emission sufficient?**
   - What we know: the check only inspects `:telemetry.execute` (not `:telemetry.span`); inbound plans to use spans only.
   - What's unclear: whether any inbound single-emit will ever be needed (none in scope).
   - Recommendation: confirm no inbound `:telemetry.execute`, AND widen the check to accept `:mailglass_inbound` defensively. Low effort; prevents a future silent break.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| gen_smtp (`:mimemail`) | MIME-01/02/04 | ✓ (in mix.lock; optional dep of core) | 1.3.0 | Degraded path returns `%MIMEError{gen_smtp_unavailable}` (MIME-02) |
| stream_data | TELE-08 | ✓ (in mix.lock, `only: [:test]`) | 1.3.0 | — (required for the proof) |
| telemetry | TELE-01..05 | ✓ (in mix.lock) | 1.4.2 | — |
| PostgreSQL (test) | TELE-08 | ✓ on CI (postgres:16-alpine for core jobs) | 16 | NONE — inbound currently has no test-DB wiring (Wave 0 must add it) |
| phoenix_pubsub / `Mailglass.PubSub` | TELE-07 | ✓ (runs in host app supervision) | 2.1 | `safe_broadcast/2` no-ops if server down (best-effort) |
| iconv (`:iconv`) | gen_smtp default encoding path | ✗ (NOT bundled by gen_smtp) | — | `{encoding, :none}` skips iconv entirely (mandatory — Pitfall 6) |

**Missing dependencies with no fallback:**
- A Postgres-backed inbound TEST repo + migrations + sandbox + CI job — does not exist today; required for TELE-08. Wave 0.

**Missing dependencies with fallback:**
- `:iconv` — avoided via `{encoding, :none}`; no functional loss for a raw-parts internal representation (charset transcoding deferred to a consumer if ever needed).

## Validation Architecture

> Nyquist validation is ENABLED (`workflow.nyquist_validation: true` in `.planning/config.json`).

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit + StreamData 1.3.0 (`use ExUnitProperties`) |
| Config file | `mailglass_inbound/test/test_helper.exs` (exists; minimal — only sets swoosh api_client false + `ExUnit.start()`) |
| Quick run command | `cd mailglass_inbound && mix test --exclude property` (fast unit subset) |
| Full suite command | `cd mailglass_inbound && mix test` (requires Wave-0 Postgres) |
| Property gate | `cd mailglass_inbound && mix test --only property` (1000-run convergence; needs DB) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TELE-01 | ingress span emits start/stop/exc, PII-free meta | unit | `mix test mailglass_inbound/test/mailglass_inbound/telemetry_test.exs -x` | ❌ Wave 0 |
| TELE-02 | route span emits matched/no_match/candidate_count | unit | `mix test test/.../telemetry_test.exs -x` | ❌ Wave 0 |
| TELE-03 | execution span covers Oban + Task paths; mailbox/outcome/source meta | unit | `mix test test/.../telemetry_test.exs -x` | ❌ Wave 0 |
| TELE-04 | persist span; operation insert/dedup_skip; record_type | unit | `mix test test/.../telemetry_test.exs -x` | ❌ Wave 0 |
| TELE-05 | raising handler does not break business logic | unit | `mix test test/.../telemetry_test.exs -x` (attach raising handler, assert pipeline ok) | ❌ Wave 0 |
| TELE-06 | metadata passes NoPiiInTelemetry across both packages | lint | `mix credo --strict` (after `.credo.exs` widened to include inbound) | n/a (CI) |
| TELE-07 | post-commit broadcast on per-tenant topic; LINT-06 ok | unit | `mix test test/.../pub_sub/topics_test.exs -x` + `mix credo --strict` (LINT-06) | ❌ Wave 0 |
| TELE-08 | 1000-replay convergence: 1 InboundRecord + 1 fresh ExecutionRun | property | `cd mailglass_inbound && mix test --only property` | ❌ Wave 0 (needs DB) |
| MIME-01 | parse RFC 5322 → stable internal repr | unit | `mix test mailglass_inbound/test/mailglass_inbound/mime_test.exs -x` | ❌ Wave 0 |
| MIME-02 | gated through GenSmtp; degraded fallback returns MIMEError | unit | `mix test test/.../mime_test.exs -x` (stub `available?` false) + `mix compile --no-optional-deps --warnings-as-errors` | ❌ Wave 0 |
| MIME-04 | malformed payloads never raise; structured error | unit | `mix test test/.../mime_test.exs -x` (feed bad_content_type, no_boundary, badchar, truncated multipart) | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `cd mailglass_inbound && mix test --exclude property` (unit subset) + `mix credo --strict` (from root).
- **Per wave merge:** `cd mailglass_inbound && mix test` (full, incl. property) + `mix compile --no-optional-deps --warnings-as-errors` + `mix credo --strict`.
- **Phase gate:** Full inbound suite green (incl. 1000-run property) + Credo green across BOTH packages before `/gsd:verify-work`.

### Wave 0 Gaps
- [ ] `mailglass_inbound/test/support/test_repo.ex` — `MailglassInbound.TestRepo` (Ecto + Postgres) — required by TELE-08 (Open Q1)
- [ ] `mailglass_inbound/config/test.exs` — `config :mailglass_inbound, :repo, ...` + Postgres credentials (mirror core)
- [ ] `mailglass_inbound/test/test_helper.exs` — run all 4 inbound migrations via `Ecto.Migrator`; start the repo + sandbox manager
- [ ] (optional) `mailglass_inbound/test/support/data_case.ex` or `property_case` — shared sandbox setup
- [ ] Credo coverage mechanism for `mailglass_inbound/` — widen root `.credo.exs` `included` (Pitfall 1) AND verify it actually lints inbound; reconcile `TelemetryEventConvention` root (Pitfall 2)
- [ ] CI: inbound test job with `postgres:16-alpine` service (Open Q2), or fold into existing job
- [ ] `mailglass_inbound/mix.exs`: add `{:gen_smtp, "~> 1.3", optional: true}` (test/dev availability of `:mimemail`)
- [ ] `mailglass_inbound/docs/api_stability.md` — add `MailglassInbound.MIMEError` + `MailglassInbound.PubSub.Topics` to the stable inventory (docs_contract_test asserts the inventory)

## Project Constraints (from CLAUDE.md)

The planner must verify each plan honors these NON-NEGOTIABLE directives (CLAUDE.md authority = locked decisions):

- **Telemetry on `[:mailglass(_inbound), :domain, :resource, :action, :start|:stop|:exception]`; metadata whitelisted to counts/statuses/IDs/latencies — NEVER PII** (no `:to/:from/:body/:html_body/:subject/:headers/:recipient/:email`). Handlers that raise must not break business logic. → directly governs TELE-01..06.
- **Append-only inbound tables; tests TRUNCATE CASCADE, never UPDATE/DELETE.** → governs the TELE-08 sandbox idiom.
- **Optional deps gated through a single `Mailglass.OptionalDeps.*` module** with `available?/0` + degraded fallback; bare references banned (`NoBareOptionalDepReference`). `mix compile --no-optional-deps --warnings-as-errors` is mandatory. → governs MIME-02 gateway extension; `:mimemail` must only be referenced inside the gateway.
- **Errors as a public API contract:** structured struct, closed `:type` atom set, pattern-match by struct never by message. CHANGELOG + `@since` + `__types__/0` test for any addition. → governs `MailglassInbound.MIMEError` (D-45-16).
- **PubSub: typed topic builders only, `mailglass:`-prefixed, per-tenant (LINT-06).** → governs TELE-07.
- **Don't use `name: __MODULE__` to register singletons in library code** (`NoDefaultModuleNameSingleton`). → relevant if Wave 0 adds a repo/sandbox manager.
- **Don't call `Swoosh.Mailer.deliver/1` directly** / **don't `Application.compile_env*` outside `Mailglass.Config`** — not directly triggered here, but custom Credo checks run against inbound once coverage is added; verify no incidental violations.
- **Don't write to `mailglass_admin/priv/static/`** — N/A (no admin asset work this phase).

## Security Domain

> `security_enforcement` is not explicitly set in `.planning/config.json` (treated as enabled). This phase
> is instrumentation + parsing + testing; the security-relevant surfaces are input parsing and PII handling.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | yes | MIME parsing of attacker-controlled raw bodies → `MailglassInbound.MIME` MUST never raise (MIME-04); malformed/maliciously-crafted MIME (boundary bombs, deep nesting) returns `{:error, %MIMEError{}}`. Bound recursion depth if practical (deeply nested multipart is a known DoS vector). |
| V8 Data Protection / Privacy | yes | Telemetry metadata whitelist (no PII) — enforced by `NoPiiInTelemetry` (TELE-06). PubSub broadcast payload is PII-free (record id + provider only). MIMEError `:cause` excluded from Jason encoding (may carry payload fragments) — mirror `Mailglass.Error` `@derive only: [:type,:message,:context]`. |
| V6 Cryptography | no | No new crypto in this phase (signature verification is existing, Phase 46 territory). |
| V4 Access Control | partial | Tenant scoping is already enforced upstream (`tenant_id` resolved before persist); the new topic is per-tenant (`mailglass:inbound:<tenant>`), preventing cross-tenant subscription leakage. |

### Known Threat Patterns for Elixir/gen_smtp MIME ingest

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malformed MIME crashes the parser (DoS) | Denial of Service | `try/rescue` + `catch :throw, :exit` (MIME-04); never let a parse failure propagate. |
| Deeply nested multipart / boundary bomb (DoS) | Denial of Service | gen_smtp recurses on multipart Body; consider a max-depth guard in `to_internal/1` if attacker-controlled. Flag for Phase 46 when MIME is actually wired to a provider (this phase ships standalone). |
| iconv invocation with missing dep (crash) | Denial of Service | `{encoding, :none}` avoids iconv entirely (Pitfall 6). |
| PII leakage via telemetry/PubSub | Information Disclosure | Metadata whitelist (no recipient/sender/body/subject/headers); `NoPiiInTelemetry` lint gate (TELE-06); PubSub payload carries only record id + provider. |
| Cross-tenant event leakage via PubSub | Information Disclosure | Per-tenant topic string includes `tenant_id` (D-45-07); subscribers must scope to their tenant. |

## Sources

### Primary (HIGH confidence — verified this session)
- gen_smtp 1.3.0 `mimemail.erl` (downloaded full 3606-line source) — `decode/1,2,3`, `?DEFAULT_OPTIONS` (lines 81-89), all `erlang:error` (164/223/356/404/439/441/514/516/692) and `throw` (477/485/500/659/1597/1625) sites, Parameters map construction (342-403, 187-200), `get_default_encoding` (1350), iconv `convert` (339), `decode_headers`/`decode_body` `none` short-circuit (225/616).
- In-repo source (read directly): `lib/mailglass/telemetry.ex`, `lib/mailglass/webhook/telemetry.ex`, `lib/mailglass/outbound/projector.ex`, `lib/mailglass/pub_sub/topics.ex`, `lib/mailglass/optional_deps/gen_smtp.ex`, `lib/mailglass/error.ex`, `lib/mailglass/errors/config_error.ex`, `credo_checks/no_pii_in_telemetry_meta.ex`, `credo_checks/prefixed_pub_sub_topics.ex`, `credo_checks/telemetry_event_convention.ex`, `.credo.exs`, `test/mailglass/properties/webhook_idempotency_convergence_test.exs`, `test/mailglass/properties/idempotency_convergence_test.exs`.
- In-repo inbound source: `mailglass_inbound/lib/mailglass_inbound/{ingress/plug,ingress/persist,router/matcher,execution,execution/worker,application,optional_deps,repo,inbound_records,inbound_records/inbound_record,inbound_records/execution_run,inbound_records/replay_run}.ex`, `mailglass_inbound/mix.exs`, inbound test tree + `persistence_test.exs`/`replay_test.exs`/`async_execution_test.exs`, inbound migrations, `mailglass_inbound/docs/api_stability.md`.
- `mix.lock` (versions: gen_smtp 1.3.0, stream_data 1.3.0, telemetry 1.4.2, ecto 3.14.0, phoenix 1.8.7), `mix.exs` (gen_smtp/stream_data optional dep declarations), `.github/workflows/ci.yml` + `publish-hex.yml` (CI job inventory — confirmed no inbound test/credo job).

### Secondary (MEDIUM confidence — verified via official docs)
- https://hexdocs.pm/stream_data/StreamData.html — confirmed `member_of/1`, `list_of/2` (`:min_length`/`:max_length`), `integer/1`, `string/2`, `bind/2`, `constant/1`, `fixed_map/1` public in 1.3.0; `gen all`/`check all` are `ExUnitProperties` macros (confirmed by in-repo usage).
- https://raw.githubusercontent.com/gen-smtp/gen_smtp/1.3.0/src/mimemail.erl — WebFetch summary cross-checked against the directly-downloaded source.

### Tertiary (LOW confidence — none load-bearing)
- (none — all load-bearing claims verified against source or in-repo code.)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all versions in mix.lock; gateway/telemetry/projector modules read directly.
- Architecture (span sites, post-commit broadcast, execute/2 wrap): HIGH — every named code anchor verified to exist with the assumed signature.
- MIME raise/throw surface + options: HIGH — verified line-by-line against gen_smtp 1.3.0 source.
- TELE-06 Credo coverage gap + TelemetryEventConvention conflict: HIGH — verified `.credo.exs` paths + check source + CI invocation.
- TELE-08 test-DB gap: HIGH — verified all inbound tests use FakeRepo and no inbound Postgres CI job exists.
- Pitfalls: HIGH (1,3,4,5,6 verified in source) / MEDIUM (2 — depends on whether inbound ever uses `:telemetry.execute`).

**Research date:** 2026-05-22
**Valid until:** 2026-06-21 (30 days — gen_smtp 1.3.0 + stream_data 1.3.0 are stable; in-repo facts valid until the referenced files change).
