# Phase 49: Inbound Runtime Operator Tooling - Research

**Researched:** 2026-05-25
**Domain:** Elixir/Mix tasks · ETS leaky-bucket rate limiting · batched Postgres retention deletes · framework-owned typed struct contracts · `mailglass_inbound` package
**Confidence:** HIGH (this is a "clone proven outbound patterns into inbound, adapt the deltas" phase; all anchors read in-session, all 30 decisions pre-locked)

> **Framing:** D-49-01..30 are settled. This document is NOT a design re-litigation. It is the implementation-detail + validation-architecture brief that lets the planner write concrete tasks without re-reading every anchor. Every code excerpt below was read from the live tree on 2026-05-25.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions (D-49-01..D-49-30 — verbatim binding)

These are the binding constraints. The full text lives in `49-CONTEXT.md`; the operative
shape per decision, as it bears on planning, is summarized in the sections below. The
non-negotiable spine:

- **D-49-01 / D-49-02 / D-49-03 (architecture + config):** Every new surface lives **inside
  `mailglass_inbound`**. Core gains NO dependency on inbound. New validated
  `MailglassInbound.Config` (NimbleOptions, reads `:mailglass_inbound` app env) — do NOT add
  inbound keys to core `Mailglass.Config`. Config key shape is locked (retention +
  rate_limit keyword trees, `:infinity` disables a retention class).
- **D-49-04 / D-49-05 / D-49-06 (mix tasks + doctor):** Three thin
  `Mix.Tasks.Mailglass.Inbound.{Doctor,Replay,Prune}` shells delegating to
  `MailglassInbound.Internal.{Doctor,Prune}` + existing `Internal.Replay`. Shared
  `MailglassInbound.Operator.Formatter` (`render_human/2` + `render_json/1`). Doctor is
  **DNS-free**, three-state exit code (`0`/`1`/`2`), finding shape locked.
- **D-49-07 / D-49-08 (route-conflict):** REUSE `Router.Matcher.matches_route?/2` — never
  re-implement match semantics. Structural-subsumption + witness-probe → `fail`;
  regex-vs-regex → `warn`. Add a compile-time `:source` (file+line via `__CALLER__`) field to
  `Router.Route`.
- **D-49-09 / D-49-10 (replay/prune CLI tiers):** `Internal.Replay.replay/2` stays
  single-record; the task resolves selectors → id list → iterates. Replay = `[y/N]` tier
  (non-destructive). Prune = `--dry-run` + typed-confirmation-above-threshold + `--yes` tier
  (destructive).
- **D-49-11..D-49-18 (rate limiter):** Inbound-local `MailglassInbound.RateLimiter` + own
  `RateLimiter.TableOwner` ETS table (`:mailglass_inbound_rate_limit`). Copy core's
  leaky-bucket + OTP-27 ETS opts verbatim. **No new dep.** Three buckets fail-fast via `with`
  (tenant → recipient → sender_domain), each returns its OWN `Retry-After`. Placement:
  `Ingress.Plug.do_call/2` post-verify, after `resolve_tenant!`, before persist, **never
  raise** → HTTP 429. PII: sender keyed on domain only; telemetry/body carry bucket *type*,
  never value. Per-node only.
- **D-49-19..D-49-24 (suppression + signals):** Compute flag in `Ingress.Persist` before
  `insert_record/4` via core `Mailglass.SuppressionStore.check/2` (NOT the outbound facade);
  **degrade OPEN** on error/empty-from. New `suppression_flagged` boolean column. New
  `:signals` field on `%InboundMessage{}` typed as nested `%InboundMessage.Signals{}`
  (NOT `:metadata`). Safe dot-access + one `suppression_flagged?/1` predicate. **No
  auto-bounce, no auto-suppression.** Reserve `:assigns` (do not add now).
- **D-49-25..D-49-30 (prune/retention):** Shared-table model (`ExecutionRun`/`ReplayRun`
  share `mailglass_inbound_replay_runs`, discriminated by `source`). FKs stay
  `on_delete: :nothing`; explicit child-first ordered batched deletes. Batched idiom =
  `DELETE ... WHERE id IN (SELECT id ... LIMIT 1000 FOR UPDATE SKIP LOCKED)` wrapped in
  `pg_try_advisory_lock`. `Internal.Prune.prune/0` is Oban-independent; thin Oban worker
  behind `Code.ensure_loaded?` guard, never auto-registered. Mix task runs `prune/0`
  synchronously WITH OR WITHOUT Oban.

### Claude's Discretion (from CONTEXT.md — verbatim)

- Exact internal function names/signatures of `MailglassInbound.{Config, RateLimiter,
  RateLimiter.TableOwner, Internal.Doctor, Internal.Prune, Operator.Formatter}`.
- Exact NimbleOptions schema field names within the locked config key shape (D-49-03).
- Exact replay batch-selection query module/shape (D-49-09).
- Exact `pg_try_advisory_lock` key constant + the prune typed-confirmation row threshold (D-49-10/27).
- Exact witness-probe construction for route-conflict detection, within the matcher-reuse +
  warn-on-regex constraint (D-49-07).
- Exact `Signals` struct field ordering and the precise wording of its closed-contract
  moduledoc note (D-49-21).

### Deferred Ideas (OUT OF SCOPE — verbatim)

- Operator / Mailgun+SES setup / routing-debug **docs** for this tooling → Phase 50 (IDOC-*).
- **Cluster-global (cross-node) rate limiting** (Redis/Mnesia backend) — node-local ETS is
  the v1.2 posture.
- Taking **Hammer / PlugAttack** as a rate-limit dep — explicitly not now.
- Inbound **`:assigns`** (adopter-writable) field — reserved name only.
- Per-signal predicate helpers beyond `suppression_flagged?/1`.
- Switching inbound FKs to **`ON DELETE CASCADE`** — rejected.
- Future `Signals` fields (spf_pass / dkim_pass / dmarc_pass / spam_score / auto_response).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description (REQUIREMENTS.md lines 89-93, 34) | Research Support |
|----|-----------|------------------|
| **IOPS-01** | `mix mailglass.inbound.doctor` runs DNS-free checks (routes compile + don't conflict, mailboxes exist + implement behaviour, signing keys configured, MIME backend available); exit-coded for CI; mirrors `mix mail.doctor`. | Doctor shell clone (§Doctor), three-state exit (D-49-05), DNS-free check list (D-49-06), conflict detection via matcher reuse (§Route-Conflict). |
| **IOPS-02** | `mix mailglass.inbound.replay --record-id/--since/--tenant` over `Internal.Replay.replay/2` with destructive-action confirmation unless `--yes`. | Selector→id-list→iterate (§Replay), `Mix.shell().yes?/1` `[y/N]`-default-No, existing `replay/2` unchanged. |
| **IOPS-03** | `mix mailglass.inbound.prune` retains records 90d/evidence 30d/execution_runs 90d/replay_runs 30d (configurable), Oban-optional + mix fallback, mirrors `Webhook.Pruner`, batched LIMIT 1000. | Batched advisory-locked sweep (§Prune), shared-table window split (D-49-25), config tree (D-49-03). |
| **IOPS-04** | Post-verify rate limiter, 3 buckets (tenant/sender_domain/recipient), no `:transactional` bypass, configured via Config, emits telemetry on rate-trip, no auto-suppression. | Inbound-local limiter (§Rate Limiter), plug placement (D-49-14), telemetry span (D-49-17). REQ says "via `Mailglass.Config`" → **deviation D-49-02:** inbound-local `MailglassInbound.Config`. |
| **IOPS-05** | Suppressed-sender mail persists with `:suppression_flagged` boolean on `InboundRecord`, surfaced in IADM-02, reaches mailbox callbacks via `%InboundMessage{}.metadata.suppression_flagged`, no auto-bounce. | Flag column + signals contract (§Suppression). REQ says `.metadata.suppression_flagged` → **deviation D-49-21:** ships as `.signals.suppression_flagged` (SESI-04-erratum precedent). |
| **MIME-03** | `mailglass.inbound.doctor` reports MIME backend availability + which optional dep is in use. | `Mailglass.OptionalDeps.GenSmtp.available?/0` + `Application.spec(:gen_smtp, :vsn)` (§Doctor MIME check) — neither trips `NoBareOptionalDepReference`. |

**Two documented literal-REQ deviations (both pre-decided, both have erratum precedent):**
1. IOPS-04 "via `Mailglass.Config`" → inbound-local `MailglassInbound.Config` (boundary law, D-49-02).
2. IOPS-05 `.metadata.suppression_flagged` → `.signals.suppression_flagged` (D-49-21).
</phase_requirements>

## Summary

Phase 49 is the inbound sibling of mailglass's shipped outbound operator toolbox. Five of the
six deliverables are direct clones of proven core modules with a small, enumerated set of
inbound-specific adaptations; the sixth (the `:signals` struct contract) is the one genuinely
novel public-API decision and it was the single item the advisors researched rather than
assumed. The work is overwhelmingly "copy structure, change the deltas":

- **Doctor** clones `mix mail.doctor`'s shell (`OptionParser strict:` + `validate_cli!/3` +
  `Mix.Task.run("app.start")` + `--format` allowlist) and `Mailglass.Deliverability.Formatter`'s
  `render_human/2` + `render_json/1`. The deltas: it is DNS-free (pure reflection over a router
  module), it adds a three-state exit code, and its hardest check (route-conflict) reuses
  `Router.Matcher.matches_route?/2` rather than re-implementing match semantics.
- **Replay/Prune CLIs** are thin shells over package-local `Internal.*` modules. Replay reuses
  the shipped single-record `Internal.Replay.replay/2` unchanged. Prune mirrors
  `Webhook.Pruner`'s structure but upgrades two things: it batches (`LIMIT 1000` +
  `FOR UPDATE SKIP LOCKED` + `pg_try_advisory_lock`) and it runs synchronously with or without
  Oban.
- **Rate limiter** copies `Mailglass.RateLimiter` + `TableOwner` verbatim into an inbound-local
  module with its own ETS table, dropping the `:transactional` bypass and the
  `%Mailglass.Message{}` coupling. It sits in `Ingress.Plug.do_call/2` post-verify and never
  raises — it returns the existing `{resp, meta}` 429 tuple.
- **Suppression flag-only** computes the flag in `Ingress.Persist` via core
  `Mailglass.SuppressionStore.check/2` (degrade-OPEN), persists a boolean column, and projects
  it through a new typed `%InboundMessage.Signals{}` nested struct.

**Primary recommendation:** Plan this as ~3 plans/waves: (1) Config + RateLimiter + plug
placement + telemetry extension; (2) suppression flag column + Signals struct + persist
wiring + IADM-02 select; (3) the three mix tasks + Internal.{Doctor,Prune} + Operator.Formatter
+ Route.`:source` field + Oban prune worker. Each plan's tests are the gate — see §Validation
Architecture. Clone aggressively; resist re-engineering the proven patterns.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `inbound.doctor` config validation | Mix/CLI (`Mix.Tasks.*`) | Internal service (`Internal.Doctor`) | CLI shell parses + exits; reflection logic is unit-testable in the service. DNS-free → no I/O tier. |
| Route-conflict detection | Internal service (`Internal.Doctor`) | Router (`Matcher.matches_route?/2`) | Detection *reuses* the runtime matcher — single source of truth for match semantics. |
| `inbound.replay` CLI | Mix/CLI | Internal service (`Internal.Replay`) | CLI resolves selectors → id list; `replay/2` (shipped) does the per-record append. |
| `inbound.prune` retention | Internal service (`Internal.Prune`) + DB | Mix/CLI + optional Oban worker | Batched DELETE logic is Oban-independent (DB tier); CLI and cron are thin entry points. |
| Ingress rate limiting | Ingress plug (`Ingress.Plug`) + ETS (`RateLimiter`) | Config (`MailglassInbound.Config`) | Post-verify gate at the HTTP boundary; ETS is node-local in-memory state. |
| Suppression flag compute | Persist (`Ingress.Persist`) + core `SuppressionStore` | DB column + Execution projection | Flag is computed once at INSERT where tenant+message+txn live; column is source of truth. |
| `signals.suppression_flagged` read | Public struct (`InboundMessage.Signals`) | Execution (`message_from_record/1`) | Framework writes the column, projects to typed struct; adopter reads in `process/1`. |

## Standard Stack

This phase adds **no new external dependencies** (D-49-11 explicitly rejects Hammer/PlugAttack;
core already ships every primitive to copy). All "stack" entries are already in
`mailglass_inbound/mix.exs` and verified present in `mix.lock`.

### Core (already present — versions verified from mix.lock 2026-05-25)
| Library | Version (lock) | Purpose in this phase | Why Standard |
|---------|------|---------|--------------|
| `nimble_options` | 1.1.1 `[VERIFIED: mix.lock]` | `MailglassInbound.Config` schema + boot validation (D-49-02) | Already the config-validation idiom across core (`Mailglass.Config`) and inbound (`Router` route schema). |
| `ecto_sql` | ~> 3.13 `[VERIFIED: mix.exs]` | Batched retention `DELETE`, `fragment/1` for `FOR UPDATE SKIP LOCKED` + advisory locks | Already the persistence layer. |
| `oban` | 2.22.1 (optional) `[VERIFIED: mix.lock]` | Optional prune cron worker behind `Code.ensure_loaded?(Oban.Worker)` (D-49-28) | Established optional-dep pattern (`Webhook.Pruner`, inbound `Execution.Worker`). |
| `gen_smtp` | 1.3.0 (optional) `[VERIFIED: mix.lock]` | MIME-backend availability + version reporting for doctor (MIME-03) | Already gated via `Mailglass.OptionalDeps.GenSmtp`. |
| `:telemetry` (via deps) | n/a | `[:mailglass_inbound, :rate_limit | :prune | :suppression_flag, ...]` spans (D-49-17/23/29) | Single-span surface already established (`MailglassInbound.Telemetry`). |
| ETS (OTP 27 stdlib) | OTP 27 | Inbound-local rate-limit counter table | Core `RateLimiter.TableOwner` is the verbatim template. |

### Alternatives Considered (all rejected by locked decisions — listed for plan-checker context)
| Instead of | Could Use | Why rejected (decision) |
|------------|-----------|-------------------------|
| Inbound-local ETS limiter | `Hammer 7.x` / `PlugAttack` | A library shouldn't force a rate-limit dep; core ships the primitive to copy (D-49-11). |
| Inbound-local limiter | Reuse `Mailglass.RateLimiter` | It is `%Message{}`-bound, reads `:mailglass` env, has `:transactional` bypass, ETS owned by core's supervisor (absent in inbound-only runtime) (D-49-11). |
| `ON DELETE CASCADE` | Postgres cascade | Can't express independent windows (evidence 30d ≠ records 90d); un-batches a parent delete (D-49-26). |
| `:metadata` map on InboundMessage | Free map | `:metadata` is reserved for *adopter-owned* data framework-wide; framework facts go on `:signals` (D-49-21). |
| `X-RateLimit-*` headers | Quota-advertisement headers | Consumer is a webhook poster that honors `Retry-After`; IETF draft not yet RFC (D-49-15). |

## Package Legitimacy Audit

> No external packages are installed in this phase. All libraries used are already declared in
> `mailglass_inbound/mix.exs` and resolved in the committed `mix.lock`. Versions were verified
> against the lockfile in-session (see Core table). No slopcheck run is required because no new
> install occurs.

| Package | Registry | Status | Disposition |
|---------|----------|--------|-------------|
| (none added) | — | — | Phase adds zero dependencies (D-49-11) |

**Packages removed due to slopcheck [SLOP] verdict:** none (no install).
**Packages flagged as suspicious [SUS]:** none (no install).

---

## Architecture Patterns

### System Architecture Diagram

```
                         ┌──────────────────── PRE-DEPLOY (offline) ───────────────────┐
                         │                                                              │
  operator $ mix mailglass.inbound.doctor                                              │
        │                                                                               │
        ▼                                                                               │
  Mix.Tasks.Mailglass.Inbound.Doctor.run/1                                             │
   (OptionParser strict:, validate_cli!/3, Mix.Task.run "app.start")                   │
        │ delegates                                                                     │
        ▼                                                                               │
  MailglassInbound.Internal.Doctor.run/1 ──► checks (ALL DNS-FREE):                    │
        │   • router configured? compiles?            (cannot_diagnose ⇒ exit 2)        │
        │   • ≥1 route defined                                                          │
        │   • each route.mailbox: Code.ensure_compiled!/1 + function_exported?(:process,1)│
        │   • signing keys present (read :mailglass_inbound config; NEVER verify sig)    │
        │   • MIME backend: OptionalDeps.GenSmtp.available?/0 + Application.spec(:gen_smtp,:vsn)│
        │   • ROUTE CONFLICT ──► reuse Router.Matcher.matches_route?/2                  │
        │         - structural subsumption (broad-before-narrow) ⇒ fail                │
        │         - witness-probe (synthesize InboundMessage from later route)         │
        │         - regex-vs-regex ⇒ warn                                              │
        ▼                                                                               │
  Operator.Formatter.render_human/2 | render_json/1 ──► stdout + exit(0|1|2)           │
                         └──────────────────────────────────────────────────────────────┘

  ┌──────────────────────────── RUNTIME (request path) ─────────────────────────────┐
  │  provider POST ─► Ingress.Plug.call ─► do_call/2                                  │
  │       1. build_request! ─► resolve_config! ─► verify_request!  (SIGNATURE GATE)   │
  │            forgery raises ─► 401 (never reaches limiter — no budget burned)       │
  │       2. resolve_tenant! ─► tenant_id                                             │
  │  ┌───►  3. ★ NEW: RateLimiter.check(tenant_id, recipient, sender_domain)          │
  │  │           with: tenant(1000) → recipient(500) → sender_domain(200)             │
  │  │           trip ⇒ {resp,meta}: 429 + Retry-After (NEVER raise)                  │
  │  │           emit [:mailglass_inbound, :rate_limit, :stop] (bucket TYPE only)     │
  │  │       4. ★ persist path: Persist.persist/2                                      │
  │  │            └─ compute flag: SuppressionStore.check(%{tenant_id, address:        │
  │  │                 downcase(first(from))})  ──► degrade OPEN on error/empty        │
  │  │            └─ insert_record/4 with suppression_flagged: bool column             │
  │  │            └─ emit [:mailglass_inbound, :ingress, :suppression_flag, :stop]     │
  │  │       5. Execution.dispatch ─► Execution.message_from_record/1                  │
  │  └────────       projects column ─► %InboundMessage{signals: %Signals{...}}        │
  │                  ─► mailbox.process(message) reads signals.suppression_flagged?    │
  └──────────────────────────────────────────────────────────────────────────────────┘

  ┌──────────────────────── MAINTENANCE (cron or on-demand) ────────────────────────┐
  │  mix mailglass.inbound.prune    OR    Oban cron (if Oban loaded, never auto-reg)  │
  │       │ both call ──────────────────────────────┐                                 │
  │       ▼                                          ▼                                 │
  │  Internal.Prune.prune/0  (Oban-INDEPENDENT, the workhorse)                        │
  │       pg_try_advisory_lock(<stable key>)  ──► not acquired ⇒ {:ok, :locked_out}   │
  │       child-first ordered batched deletes (FK on_delete: :nothing):               │
  │         replay_runs(source=:replay 30d) → fresh_runs(source=:fresh 90d)           │
  │           → evidence(30d) → records(90d)                                          │
  │       each: DELETE WHERE id IN (SELECT id ... LIMIT 1000 FOR UPDATE SKIP LOCKED)  │
  │            looped until affected < 1000                                           │
  │       emit [:mailglass_inbound, :prune, :stop] (per-table counts, no PII)         │
  └──────────────────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities (file-to-implementation map)

| File (new unless noted) | Responsibility |
|---|---|
| `mailglass_inbound/lib/mailglass_inbound/config.ex` (NEW) | NimbleOptions schema + validated accessors for `:mailglass_inbound` retention + rate_limit (D-49-02/03). |
| `mailglass_inbound/lib/mailglass_inbound/rate_limiter.ex` (NEW) | Leaky-bucket `check/3` (or `check/1` over a small key struct), 3-bucket `with`, builds `Mailglass.RateLimitError` internally. Cloned from core `RateLimiter`. |
| `mailglass_inbound/lib/mailglass_inbound/rate_limiter/table_owner.ex` (NEW) | Init-and-idle GenServer owning `:mailglass_inbound_rate_limit` ETS table (OTP-27 opts verbatim). |
| `mailglass_inbound/lib/mailglass_inbound/application.ex` (EDIT) | Add `RateLimiter.TableOwner` child to children list. Do NOT auto-register prune worker. |
| `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` (EDIT) | Insert rate-limit check in `do_call/2` (post-verify, post-tenant, pre-persist) returning `{resp, meta}` 429 on trip. |
| `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex` (EDIT) | Compute `suppression_flagged` in `persist/2` before `insert_record/4`; thread into attrs. |
| `mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_record.ex` (EDIT) | Add `suppression_flagged :boolean` field + to `@cast` (not `@required`). |
| `mailglass_inbound/priv/repo/migrations/*_add_suppression_flagged.exs` (NEW) | `add :suppression_flagged, :boolean, null: false, default: false`. |
| `mailglass_inbound/lib/mailglass_inbound/inbound_message.ex` (EDIT) | Add `:signals` field defaulting to `%Signals{}`; define nested `Signals` struct + types. |
| `mailglass_inbound/lib/mailglass_inbound/execution.ex` (EDIT) | `message_from_record/1` populates `signals: %Signals{suppression_flagged: record.suppression_flagged}`. |
| `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex` (EDIT) | Add `suppression_flagged: record.suppression_flagged` to the `select/3` map (IADM-02). |
| `mailglass_inbound/lib/mailglass_inbound/router/route.ex` (EDIT) | Add `:source` (`{file, line}`) field. |
| `mailglass_inbound/lib/mailglass_inbound/router.ex` (EDIT) | Capture `__CALLER__.file/.line` in `route/2`, set `Route.source`. |
| `mailglass_inbound/lib/mailglass_inbound/telemetry.ex` (EDIT) | Add `rate_limit_span` / `prune` emit / `suppression_flag` emit; extend D-45-03 whitelist with `bucket, limit, retry_after, flagged` + per-table prune counts. |
| `mailglass_inbound/lib/mailglass_inbound/internal/doctor.ex` (NEW) | DNS-free check runner returning the locked finding shape + summary. |
| `mailglass_inbound/lib/mailglass_inbound/internal/prune.ex` (NEW) | Pure batched advisory-locked sweep `prune/0`, Oban-independent. |
| `mailglass_inbound/lib/mailglass_inbound/operator/formatter.ex` (NEW) | `render_human/2` + `render_json/1`, cloned from `Deliverability.Formatter`. |
| `mailglass_inbound/lib/mix/tasks/mailglass.inbound.doctor.ex` (NEW) | CLI shell (exit 0/1/2). |
| `mailglass_inbound/lib/mix/tasks/mailglass.inbound.replay.ex` (NEW) | CLI shell: selectors → id list → iterate `replay/2`, `[y/N]`/`--yes`. |
| `mailglass_inbound/lib/mix/tasks/mailglass.inbound.prune.ex` (NEW) | CLI shell: `--dry-run` + typed confirm + `--yes`, runs `prune/0` sync regardless of Oban. |
| `mailglass_inbound/lib/mailglass_inbound/prune/worker.ex` (NEW) | Thin Oban worker behind `if Code.ensure_loaded?(Oban.Worker)` calling `prune/0` + `available?/0` stub in `else`. |

### Pattern 1: Mix-task shell over Internal service (clone of `mail.doctor`)
**What:** OptionParser `strict:` → `validate_cli!/3` (reject `rest`/`invalid`/bad `--format`) →
`Mix.Task.run("app.start")` → delegate to internal module → format → emit.
**When:** All three tasks.
**Example (verbatim shape from `lib/mix/tasks/mail.doctor.ex:22-81`):**
```elixir
# Source: lib/mix/tasks/mail.doctor.ex (read 2026-05-25)
def run(argv) do
  {opts, rest, invalid} =
    OptionParser.parse(argv, strict: [format: :string, strict: :boolean, verbose: :boolean])

  validate_cli!(opts, rest, invalid)
  Mix.Task.run("app.start")
  # ... delegate to Internal.Doctor, format, exit with code
end

defp validate_cli!(opts, rest, invalid) do
  if rest != [], do: Mix.raise("... unexpected positional arguments ...")
  if invalid != [], do: Mix.raise("... unknown option(s) ...")
  format = Keyword.get(opts, :format, "human")
  unless format in ["human", "json"], do: Mix.raise("... invalid format ...")
  :ok
end
```
**Key delta for doctor:** core `mail.doctor` uses `Mix.raise` for ALL failures (so a failed
DNS check is `Mix.Error` → exit 1). Phase 49 doctor needs the **three-state exit** (D-49-05),
so it must NOT `Mix.raise` on findings — it inspects the summary and calls `exit({:shutdown, N})`
with `N ∈ {0,1,2}`. `Mix.raise`/`validate_cli!` is still correct for *CLI misuse* (bad flags).

### Pattern 2: Each task `use Boundary, classify_to:` — BUT inbound has no boundary compiler yet
**What:** Core mix tasks declare `use Boundary, classify_to: Mailglass`
(`mail.doctor.ex:2`). **`[VERIFIED: grep]` the inbound package does NOT run the `:boundary`
compiler** (only `mailglass` core lists `compilers: [:boundary | Mix.compilers()]` in
`mix.exs:15`; `mailglass_inbound/mix.exs` has no boundary entry and no `use Boundary` anywhere
in its `lib/`).
**Implication for planner:** D-49-04 says each task should `use Boundary, classify_to:` the
inbound package. Taken literally that requires *also* adding the boundary compiler + a root
`use Boundary` to `mailglass_inbound`. The planner should treat the boundary classification as
**conditional**: if the inbound package gains boundary enforcement in this phase it is a
separate, larger task; otherwise omit `use Boundary` from the inbound tasks (it would not
compile without the compiler) and rely on the existing convention + the `no_warn_undefined`
discipline. `[ASSUMED]` — flag for confirmation; the safest default is "do not introduce the
boundary compiler in Phase 49; skip `use Boundary` on inbound tasks." (See Assumptions Log A1.)

### Pattern 3: Leaky-bucket ETS, cloned verbatim with deltas dropped
**What:** Copy `Mailglass.RateLimiter.check_bucket/2` + `TableOwner.init/1` verbatim; drop the
`%Mailglass.Message{stream: :transactional}` clause and the `%Message{}`-extraction helpers.
**Example (the load-bearing ETS update — core `rate_limiter.ex:109-141`):**
```elixir
# Source: lib/mailglass/rate_limiter.ex:109-141 (read 2026-05-25)
defp check_bucket(type, sub_key) do
  {capacity, refill_per_ms} = limits_for(type, sub_key)
  key = {type, sub_key}
  now_ms = System.monotonic_time(:millisecond)
  :ets.insert_new(@table, {key, capacity, now_ms})            # first-hit seed
  [{^key, tokens, last}] = :ets.lookup(@table, key)
  restore = if tokens < 0, do: abs(tokens), else: 0
  elapsed_ms = max(0, now_ms - last)
  refilled = round(elapsed_ms * refill_per_ms)
  total_add = min(restore + refilled, capacity - tokens)
  result =
    :ets.update_counter(@table, key,
      [{2, total_add, capacity, capacity}, {3, 0, 0, now_ms}, {2, -1}],
      {key, capacity, now_ms})
  case result do
    [_refilled, _ts, new_tokens] when new_tokens >= 0 -> :ok
    _ -> {:error, refill_per_ms}
  end
end
```
**ETS opts to copy verbatim (`table_owner.ex:46-54`):** `[:set, :public, :named_table,
read_concurrency: true, write_concurrency: :auto, decentralized_counters: true]` — but with
table name `:mailglass_inbound_rate_limit`.
**Bucket order delta (D-49-13):** tenant (1000/min) → recipient (500/min) → sender_domain
(200/min), fail-fast via `with`. The tripped bucket returns ITS OWN `refill_per_ms` →
`Retry-After`. Do not compute a cross-bucket max.

### Pattern 4: 429 via non-raising `{resp, meta}` tuple in the plug
**What:** Mirror the existing `do_call/2` egress idiom — every branch returns `{resp, meta}`,
never raises for a non-forgery outcome. The rate-limit trip is a NEW branch inserted between
`resolve_tenant!` and `persist_and_respond`.
**Example (the established 429-shaped sibling — `plug.ex:159-161`):**
```elixir
# Source: mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex (read 2026-05-25)
e in TenancyError ->
  resp = send_json(conn, 422, %{status: "tenant_unresolved", reason: Atom.to_string(e.type)})
  {resp, %{provider: provider, status: :tenant_unresolved}}
```
**For the limiter (D-49-14):** after `tenant_id = resolve_tenant!(...)`, before
`normalize_request!`/persist:
```elixir
# pseudocode — concrete shape is planner discretion
case MailglassInbound.RateLimiter.check(tenant_id, recipient_addr, sender_domain) do
  :ok ->
    persist_and_respond(conn, provider, request, facts, opts)
  {:error, %Mailglass.RateLimitError{} = err} ->
    bucket = bucket_type(err)            # :tenant | :recipient | :sender_domain
    retry_after_s = ceil(err.retry_after_ms / 1000)
    resp =
      conn
      |> put_resp_header("retry-after", Integer.to_string(retry_after_s))
      |> send_json(429, %{status: "rate_limited", bucket: Atom.to_string(bucket)})
    {resp, %{provider: provider, tenant_id: tenant_id, status: :rate_limited,
             bucket: bucket, limit: err.context[:limit], retry_after: retry_after_s}}
end
```
**Critical placement subtlety:** the limiter check belongs inside `persist_and_respond/5`
(which is where `resolve_tenant!` is currently called — `plug.ex:179-180`), NOT in the
top-level `do_call/2` `case` (verify happens there, tenant does not). The witness for "verify
already happened" is that `persist_and_respond` is only reached on `{:ok, facts}` / legacy
bare-map — i.e. AFTER a successful verify. So: insert the check at the top of
`persist_and_respond/5`, immediately after `tenant_id = resolve_tenant!(...)`.

### Pattern 5: Framework-owned typed nested struct (the `Ecto.Schema.Metadata` archetype)
**What:** Add `:signals` (defaulting to `%Signals{}`) to `%InboundMessage{}`; define a nested
`MailglassInbound.InboundMessage.Signals` struct with every field enumerated, defaulted,
non-nil. Adopter reads via safe dot-access; framework writes via
`message_from_record/1`.
**Why a struct not a map (D-49-21):** `:metadata` is reserved framework-wide for *adopter-owned*
data (`Mailglass.Message` has `:metadata` + `put_metadata/3`; the domain-language doc defines
Metadata = application-defined). Reusing that name for framework-derived facts inverts its
meaning. The `Ecto.Schema.Metadata`/`__meta__` precedent (framework writes, adopter reads,
dialyzer-checkable) is exactly this shape.
**Example (the field to add to `inbound_message.ex`):**
```elixir
# NEW nested struct (sibling module or inline in inbound_message.ex)
defmodule MailglassInbound.InboundMessage.Signals do
  @moduledoc "Framework-derived, read-only inbound signals. Framework writes; adopter reads."
  @type t :: %__MODULE__{suppression_flagged: boolean()}
  defstruct suppression_flagged: false
end

# in %InboundMessage{} defstruct + @type:  signals: Signals.t()  (default %Signals{})
```
**Backward-compat guarantee (D-49-22):** every `Signals` field is defaulted → safe dot-access
returns the default (`false`) even for **pre-migration records projected through the struct**
(`message_from_record/1` reads `record.suppression_flagged`, which for an old row is the DB
`NOT NULL DEFAULT false` value). Existing `process/1` clauses keep matching; the change is
purely additive.

### Pattern 6: Batched advisory-locked retention delete (NEW idiom — first in repo)
**What:** `[VERIFIED: grep]` no advisory-lock or `FOR UPDATE SKIP LOCKED` usage exists anywhere
in `lib/` or `mailglass_inbound/lib/` today — Phase 49 introduces it. `Webhook.Pruner` uses an
unbounded `Repo.delete_all(from w in WebhookEvent, where: ...)` (`pruner.ex:97-103`).
**The idiom (D-49-27), per-table:**
```elixir
# pseudocode — concrete query is planner discretion
defp delete_batched(repo, schema, window_filter) do
  Stream.repeatedly(fn ->
    {count, _} =
      repo.delete_all(
        from(r in schema,
          where: r.id in subquery(
            from(s in schema, where: ^window_filter, select: s.id, limit: 1000,
                 lock: "FOR UPDATE SKIP LOCKED")
          )
        )
      )
    count
  end)
  |> Enum.reduce_while(0, fn count, acc ->
    if count < 1000, do: {:halt, acc + count}, else: {:cont, acc + count}
  end)
end
```
**Advisory lock wrapper (single-run guard, D-49-27):**
```elixir
# pg_try_advisory_lock is non-blocking; returns boolean. Bail if not acquired.
case repo.query!("SELECT pg_try_advisory_lock($1)", [@prune_lock_key]) do
  %{rows: [[true]]} ->
    try do
      # ... ordered child-first batched deletes ...
    after
      repo.query!("SELECT pg_advisory_unlock($1)", [@prune_lock_key])
    end
  %{rows: [[false]]} ->
    {:ok, :locked_out}
end
```
**`@prune_lock_key`** is a stable `bigint` constant (planner discretion, D-49-10/27 — e.g. a
hash of `"mailglass_inbound_prune"` truncated to int8). Advisory locks are session-scoped; the
`after` unlock is important (or use `pg_try_advisory_xact_lock` inside a transaction, which
auto-releases on commit — but the batched loop must NOT be one giant transaction, so
session-level lock + explicit unlock is the correct shape).
**Window split (D-49-25):** four logical windows → three physical tables:
- `mailglass_inbound_replay_runs` WHERE `source = :replay` AND age > replay_runs_days (30d)
- `mailglass_inbound_replay_runs` WHERE `source = :fresh` AND age > execution_runs_days (90d)
- `mailglass_inbound_evidence` WHERE age > evidence_days (30d)
- `mailglass_inbound_records` WHERE age > records_days (90d)
**Order (child-first, D-49-26):** delete replay_runs (both source filters) → evidence →
records. FKs are `on_delete: :nothing` (`...storage_foundation.exs:37-38,65-72`), so a
mis-ordered delete fails loudly on the FK constraint (the designed safety net). Read/filter
`source` via **`ExecutionRun`** (it maps `source`; `ReplayRun` does NOT — D-49-25) or a
schemaless query.

### Pattern 7: Oban-optional worker behind file-top guard (clone of `Webhook.Pruner`)
**What:** `Webhook.Pruner` is `if Code.ensure_loaded?(Oban.Worker) do ... else <stub with
available?/0 → false> end` (`pruner.ex:1,117-130`). Clone this for the inbound prune worker,
but the worker's `perform/1` just calls `Internal.Prune.prune/0`. The mix task does NOT gate on
Oban (D-49-28 upgrade — webhook task `exit({:shutdown, 1})` when Oban absent at
`mailglass.webhooks.prune.ex:54`; inbound runs `prune/0` synchronously regardless).
**Boot warning:** mirror the consolidated `maybe_warn_missing_oban_for_webhook_workers/0`
pattern (core `application.ex:88-111`) with a `:persistent_term` once-per-node gate. **Do NOT
auto-register the cron** (D-49-28) — document `0 3 * * *` in Phase 50.

### Anti-Patterns to Avoid
- **Re-implementing route match semantics in the doctor.** REUSE `Matcher.matches_route?/2`
  (and `Matcher.explain/2` if useful) — a second copy drifts from runtime and emits false
  positives/negatives (D-49-07).
- **Letting the rate limiter raise.** It must return the `{resp, meta}` 429 tuple; a raise
  escapes the rescue allowlist as a 500 and the provider retry-storms (D-49-14, mirrors the
  S3FetchError lesson in `plug.ex:134-157`).
- **Gating the suppression check (degrade-CLOSED).** A store error must NOT block inbound mail —
  flag is diagnostic, not a gate. `{:error,_}` / empty-from → `false` (D-49-19).
- **Using the outbound `Mailglass.Suppression.check_before_send/1` facade.** It reads swoosh
  `:to` and emits *outbound* telemetry — wrong direction. Use `SuppressionStore.check/2` (the
  configured store) directly (D-49-19).
- **Naming the new field `:metadata`.** It is `:signals` (D-49-21).
- **One giant transaction for the prune sweep.** Batching exists precisely to avoid long locks /
  replication lag; wrap with a session advisory lock, loop small DELETEs (D-49-27).
- **Adding inbound keys to core `Mailglass.Config`.** Core reads `:mailglass` env only; adding
  inbound keys inverts the package dependency (D-49-02).
- **Putting bucket VALUES (recipient address, sender) in telemetry or the 429 body.** Only the
  bucket TYPE (D-49-16/17).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Route match equality/regex/wildcard | A second matcher in the doctor | `MailglassInbound.Router.Matcher.matches_route?/2` (+ `explain/2`) | Single source of truth; a copy drifts → false conflict reports (D-49-07). |
| Token-bucket refill math | New algorithm | Copy `Mailglass.RateLimiter.check_bucket/2` + ETS opts verbatim | OTP-27-tuned, crash-semantics-documented, already production-proven (D-49-12). |
| Rate-limit error struct | New exception | `Mailglass.RateLimitError` (`:per_tenant`/`:per_domain` types) | Errors-as-contract; reuse the struct, build it internally (D-49-11/14). |
| Suppression lookup (tenant-scoped, downcased, domain+address+stream union) | New query | `Mailglass.SuppressionStore.check/2` via configured store | Tenant scoping + downcasing + union already correct (`suppression_store/ecto.ex`) (D-49-19). |
| MIME-backend availability/version | `Code.ensure_loaded?(:mimemail)` inline | `Mailglass.OptionalDeps.GenSmtp.available?/0` + `Application.spec(:gen_smtp, :vsn)` | Bare refs trip `NoBareOptionalDepReference` (MIME-03, D-49-06). |
| Human/JSON output | New formatter | Clone `Mailglass.Deliverability.Formatter` (`render_human/2`+`render_json/1`) | Parity-tested shape (`mail_doctor_task_test.exs:120-122`) (D-49-04). |
| CLI confirmation prompt | New prompt loop | `Mix.shell().yes?/1` (defaults No on empty) | Established Mix idiom; `--yes` skips, never removes (D-49-09/10). |
| Single-run cron guard | App-level mutex / DB flag table | `pg_try_advisory_lock` | Non-blocking, session-scoped, race-safe vs cron-tick + manual run (D-49-27). |

**Key insight:** Five of six deliverables already exist for outbound. The value is in
*adapting the deltas precisely* (drop `:transactional`, own ETS table, batch the delete, run
without Oban, DNS-free) — not re-deriving the patterns. The only from-scratch design is the
`Signals` struct, and even that follows the `Ecto.Schema.Metadata` archetype.

## Runtime State Inventory

> This is a feature phase, not a rename/migration. The only persisted-state change is the new
> `suppression_flagged` column. No external runtime state (n8n, Task Scheduler, SOPS, etc.)
> embeds any Phase-49 identifier.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | New `suppression_flagged` boolean column on `mailglass_inbound_records`. Existing rows backfill via `NOT NULL DEFAULT false`. | One generated migration (adopters run it). No data migration of existing rows needed — default backfills them. |
| Live service config | None — verified by inspecting `:mailglass_inbound` config (only provider blocks today; new `retention`/`rate_limit` keys are additive defaults). | Config is read at runtime via the new `MailglassInbound.Config`; no out-of-git service config. |
| OS-registered state | None — verified. No Task Scheduler / launchd / systemd registration. The Oban prune cron is **documented, never auto-registered** (D-49-28). | None. |
| Secrets/env vars | None new. The rate limiter and doctor read existing provider signing-key config; no new secret keys. | None. |
| Build artifacts / installed packages | New ETS table `:mailglass_inbound_rate_limit` created at boot by the new `RateLimiter.TableOwner` child (ephemeral; dies with owner per D-22). | Add child to `MailglassInbound.Application`; nothing to clean up — ETS state is not load-bearing across crashes. |

**The canonical question — after every file is updated, what runtime systems still have stale
state?** Only the ETS rate-limit table, which is intentionally ephemeral (resets to empty on
TableOwner restart; worst case 1 minute of burst allowance, per D-22 crash semantics). The DB
column is the suppression-flag source of truth and self-backfills.

## Common Pitfalls

### Pitfall 1: Rate-limit check placed before verify → unauthenticated-DoS amplifier
**What goes wrong:** If the limiter runs before signature verification, a forged-payload flood
consumes a tenant's budget, locking out legitimate mail.
**Why it happens:** `do_call/2`'s verify is at the top of the `try` (`plug.ex:107`); it's
tempting to add the check right after `build_request!`.
**How to avoid:** Insert the check in `persist_and_respond/5` (reached only on a verified
`{:ok, facts}` / bare-map), after `resolve_tenant!` (D-49-14). The signature gate is the wall.
**Warning sign:** a test that trips the limiter without a valid signature passes.

### Pitfall 2: SES fetch-before-tenant ordering interacts with limiter placement
**What goes wrong:** SES's `verify!/2` does a bounded S3 GetObject *inside verification*, before
tenant resolution (`plug.ex:75-95`). Since the limiter sits post-verify/post-tenant, this is
fine — but a planner could wrongly conclude "verify is expensive, limit earlier."
**Why it happens:** The verify cost is non-trivial for SES.
**How to avoid:** Keep the limiter post-verify. The S3 fetch is signature-gated, so only
authentic SNS messages reach it — it is not an unauthenticated DoS vector (the CONTEXT note in
`plug.ex:88-94` documents exactly this) (D-49-14).
**Warning sign:** limiter check appears before the verify `case`.

### Pitfall 3: Degrade-CLOSED suppression (blocking mail on a store hiccup)
**What goes wrong:** `SuppressionStore.check/2` returns `{:error, :invalid_key}` (malformed
key — `ecto.ex:96`) or an infra error; if treated as "suppressed," legitimate inbound mail is
blocked or mis-flagged.
**Why it happens:** Defensive instinct treats unknown as suspicious.
**How to avoid:** `{:suppressed,_}` → `true`; `:not_suppressed` → `false`; `{:error,_}` AND
empty/missing `from` → `false` (degrade OPEN) (D-49-19). The flag is diagnostic, never a gate;
there is no auto-bounce (D-49-23).
**Warning sign:** any branch where a store error sets the flag or short-circuits persist.

### Pitfall 4: Selecting `source` via the wrong schema in the pruner
**What goes wrong:** `ReplayRun` and `ExecutionRun` map the SAME table
(`mailglass_inbound_replay_runs`), but only `ExecutionRun` maps the `source` column
(`execution_run.ex:38-42` vs `replay_run.ex:37` — ReplayRun has no `source` field). Querying
`source` through `ReplayRun` raises/returns nothing.
**Why it happens:** Two schemas, one table, easy to grab the wrong alias.
**How to avoid:** Filter `source` via `ExecutionRun` or a schemaless query (D-49-25).
**Warning sign:** `from(r in ReplayRun, where: r.source == :replay)` — compile-time field error.

### Pitfall 5: Forgetting the FK delete order → loud failure (this is the safety net working)
**What goes wrong:** Deleting `records` before `evidence`/`replay_runs` raises an FK violation
(`on_delete: :nothing`).
**Why it happens:** Natural to think "delete the parent."
**How to avoid:** Child-first: replay_runs → evidence → records (D-49-26). The FK is the
intentional guard rail (a CASCADE would silently un-batch the delete).
**Warning sign:** `Ecto.ConstraintError` / `foreign_key_violation` mid-sweep — fix the order,
don't switch to CASCADE.

### Pitfall 6: Doctor `Mix.raise` swallows the three-state exit code
**What goes wrong:** Cloning `mail.doctor` too literally — it `Mix.raise`es on every failure, so
a failing check becomes a `Mix.Error` (exit 1) and "cannot diagnose" (exit 2) is unreachable.
**Why it happens:** The clone source uses `Mix.raise` for both CLI misuse and check failures.
**How to avoid:** `Mix.raise` (via `validate_cli!`) only for CLI misuse (bad flags/positional/
format). For findings, compute the summary and `exit({:shutdown, N})` with `N` from the
pass/warn/fail/cannot-diagnose tally (D-49-05).
**Warning sign:** a doctor that always exits 0 or 1, never 2.

### Pitfall 7: `:signals` non-defaulted field → `KeyError` on pre-migration / hand-built messages
**What goes wrong:** If `:signals` (or any `Signals` field) lacks a default, dot-access on an
older record or a test-built `%InboundMessage{}` raises `KeyError`.
**Why it happens:** Struct fields without defaults are `nil`; a nested struct without a default
is missing.
**How to avoid:** `:signals` defaults to `%Signals{}`; every `Signals` field is defaulted +
non-nil (D-49-21/22). `message_from_record/1` always sets `signals:` from the column (which is
`NOT NULL DEFAULT false`).
**Warning sign:** `msg.signals.suppression_flagged` raises on any code path.

### Pitfall 8: Telemetry whitelist not extended → `NoPiiInTelemetry` lint fails
**What goes wrong:** The new spans carry `bucket`/`limit`/`retry_after`/`flagged`/per-table
counts; the D-45-03 whitelist in `MailglassInbound.Telemetry` (and the `NoPiiInTelemetry`
allowlist) lists only the existing 11 keys (`telemetry.ex:39`).
**Why it happens:** The whitelist is enforced by a Credo check across the module + every caller.
**How to avoid:** Extend the whitelist with the new PII-free keys (D-49-17) AND update the
`NoPiiInTelemetry` allowlist. Validate by RUNNING credo (per project memory — credo changes are
validated by running, not grepping).
**Warning sign:** `mix credo --strict` flags the new metadata keys.

## Code Examples

### MIME backend report (MIME-03, no bare optional-dep ref)
```elixir
# Source: lib/mailglass/optional_deps/gen_smtp.ex:57 + mix.lock (read 2026-05-25)
backend_available? = Mailglass.OptionalDeps.GenSmtp.available?()   # Code.ensure_loaded?(:gen_smtp_client)
backend_name = "gen_smtp (:mimemail)"
backend_version =
  case Application.spec(:gen_smtp, :vsn) do
    vsn when is_list(vsn) -> List.to_string(vsn)   # ~c"1.3.0" → "1.3.0"
    _ -> nil
  end
# finding: status = if backend_available?, do: :pass, else: :warn
```

### Mailbox reading the signal (adopter-facing — D-49-22)
```elixir
# pattern-match in the head (encouraged):
def process(%MailglassInbound.InboundMessage{
      signals: %MailglassInbound.InboundMessage.Signals{suppression_flagged: true}
    }), do: {:reject, :sender_suppressed}

def process(%MailglassInbound.InboundMessage{} = msg) do
  if MailglassInbound.InboundMessage.suppression_flagged?(msg), do: ..., else: :accept
end
```

### Suppression check from persist (degrade-OPEN — D-49-19)
```elixir
# Source seam: mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex insert_record/4 attrs
defp compute_suppression_flag(tenant_id, %InboundMessage{from: from}) do
  store = Application.get_env(:mailglass, :suppression_store, Mailglass.SuppressionStore.Ecto)
  case first_from_address(from) do
    nil -> false                                   # empty/missing from → degrade OPEN
    address ->
      case store.check(%{tenant_id: tenant_id, address: String.downcase(address)}) do
        {:suppressed, _entry} -> true
        :not_suppressed -> false
        {:error, _} -> false                       # store hiccup → degrade OPEN
      end
  end
end
# NOTE: no :stream key (outbound concept). first_from_address pulls .address of List.first(from).
```

### Route `:source` capture (D-49-08)
```elixir
# Source seam: mailglass_inbound/lib/mailglass_inbound/router.ex route/2 macro
defmacro route(mailbox, opts) do
  source = {__CALLER__.file, __CALLER__.line}      # captured at compile time
  # ... existing expand/validate ...
  route = %Route{mailbox: ..., recipient: ..., subject: ..., headers: ..., source: source}
  quote bind_quoted: [route: Macro.escape(route)], do: @mailglass_inbound_routes route
end
# Route.source then surfaces "router.ex:12" in conflict findings.
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Outbound-only operator tooling (`mail.doctor`, `Webhook.Pruner`, `RateLimiter`) | Inbound siblings with deltas | Phase 49 (this) | Operator parity inbound↔outbound. |
| Unbounded `delete_all` retention (`Webhook.Pruner`) | Batched `LIMIT 1000` + `FOR UPDATE SKIP LOCKED` + advisory lock | Phase 49 | Bounded locks, no replication-lag spikes (IOPS-03). |
| Prune task exits 1 when Oban absent (`webhooks.prune`) | Prune runs `prune/0` synchronously regardless of Oban | Phase 49 | Oban-less adopters get a working prune (D-49-28). |
| DNS-bound doctor (`mail.doctor`) | DNS-free reflection-only doctor | Phase 49 | Fast, offline, CI-friendly, no network flake (D-49-06). |
| Framework facts via free maps | Typed `%Signals{}` nested struct on `%InboundMessage{}` | Phase 49 | Dialyzer-checkable, pattern-matchable, backward-compatible public contract (D-49-21). |

**Deprecated/outdated:** None introduced. `ReplayRun` remains the "legacy narrow projection"
(does not map `source`); use `ExecutionRun` for lineage queries (pre-existing, reaffirmed by
D-49-25).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The inbound package does NOT add the `:boundary` compiler in Phase 49, so inbound mix tasks should OMIT `use Boundary, classify_to:` (it would not compile without the compiler). D-49-04 mentions `use Boundary`; literally honoring it requires also wiring the boundary compiler + root `use Boundary` into `mailglass_inbound`, which is a larger scope. | Pattern 2 | If wrong (boundary compiler IS intended for inbound this phase), the tasks need `use Boundary` AND the package needs compiler wiring — a meaningfully larger task. Recommend confirming in discuss/plan. `[VERIFIED: grep]` confirms boundary compiler is absent today. |
| A2 | The rate-limit recipient key uses the full recipient address (envelope_recipient / first `to`), and the sender_domain key is the domain of the first `from`. D-49-16 permits full recipient address (routing identity, node-local ETS). Exact key extraction is planner discretion. | Pattern 3, §Rate Limiter | Wrong key granularity → buckets too coarse/fine. Low risk; D-49-16 is explicit on PII rules. |
| A3 | `pg_try_advisory_lock` session-level (not `_xact_`) is correct because the batched sweep must NOT be one transaction. Lock + explicit `pg_advisory_unlock` in an `after`. | Pattern 6 | If a transaction-scoped lock were used around the loop, the loop would hold one long txn (defeating batching). Low risk; standard Postgres retention idiom. |
| A4 | `suppression_flagged` is computed from `List.first(message.from)`'s `:address` (per D-49-19 "downcased :address of List.first(message.from)"). Inbound `from` is a list of `%{address:, name:}` maps (`inbound_message.ex:28-31`). | §Suppression | If `from` shape differs at the persist seam, extraction breaks. `[VERIFIED]` shape from `inbound_message.ex`. Low risk. |

## Open Questions (RESOLVED)

1. **Should Phase 49 introduce the `:boundary` compiler into `mailglass_inbound`?**
   - What we know: D-49-04 says each task should `use Boundary, classify_to:` the package;
     core uses this everywhere. `[VERIFIED: grep]` inbound has no boundary compiler/declarations.
   - What's unclear: whether D-49-04's `use Boundary` intends to also bring the compiler in, or
     was written assuming it already existed (it does not).
   - Recommendation: default to NOT introducing the boundary compiler this phase (skip
     `use Boundary` on inbound tasks); flag in plan-phase for a one-line user confirmation.
     This is the safest interpretation — adding the compiler is a separate hardening task and
     would force boundary annotations across the whole inbound package.
   - **RESOLVED (plan-phase, 2026-05-25):** Orchestrator-approved deviation — `49-03-PLAN.md`
     OMITS `use Boundary` on the inbound mix tasks. The boundary LAW (inbound depends on core,
     never the reverse) is still honored; only the compile-time annotation is skipped because
     `mailglass_inbound` does not run the `:boundary` compiler. See the BOUNDARY NOTE in
     49-03's `<context>`. Deviation from D-49-04's literal wording, flagged for user override.

2. **Exact `Retry-After` rounding (ceil to seconds) for sub-second refill windows.**
   - What we know: `err.retry_after_ms` can be < 1000 for high-capacity buckets;
     `Retry-After` is integer seconds.
   - What's unclear: whether to floor-to-1 (always advertise ≥1s) or round.
   - Recommendation: `max(1, ceil(ms/1000))` — never advertise 0 (a poster honoring 0 retries
     immediately). Planner discretion; assert ≥1 in the test.
   - **RESOLVED (plan-phase, 2026-05-25):** Adopted in `49-01-PLAN.md` Task 2 —
     `max(1, ceil(retry_after_ms / 1000))`, with a `>= 1 second` assertion in `plug_test.exs`.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| PostgreSQL (`pg_try_advisory_lock`, `FOR UPDATE SKIP LOCKED`) | Prune batched delete + advisory lock | ✓ (project is Postgres-only, D-PROJECT) | 12+ assumed (both features ≥ 9.5) | none needed — Postgres-only by design |
| `oban` | Optional prune cron worker | ✓ (in lock, optional) | 2.22.1 | mix task runs `prune/0` synchronously (D-49-28) |
| `gen_smtp` (`:mimemail`) | Doctor MIME-backend report | ✓ (in lock, optional) | 1.3.0 | doctor reports `:warn` "MIME backend unavailable" when absent |
| ETS (OTP 27) | Rate-limit counter table | ✓ (stdlib) | OTP 27 | none — required |
| `nimble_options` | `MailglassInbound.Config` schema | ✓ (in lock) | 1.1.1 | none — required |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** Oban (→ synchronous mix prune), gen_smtp (→ doctor warns).

## Validation Architecture

> nyquist_validation is not disabled in `.planning/config.json` (no `workflow.nyquist_validation:
> false` present) → this section is REQUIRED. It is the input to VALIDATION.md.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.18) + StreamData 1.3 (property tests) |
| Config file | `mailglass_inbound/test/test_helper.exs` (Postgres-backed `MailglassInbound.TestRepo`) |
| Quick run command | `cd mailglass_inbound && mix test test/mailglass_inbound/<file>_test.exs --seed 0` |
| Full suite command | `cd mailglass_inbound && mix test --seed 0` |
| Seed note | `[VERIFIED: MEMORY.md]` full inbound suite intermittently flakes (DB pool `recv:closed`) via a phase-45 1000-iter property test → use `--seed 0` or scope per-file for deterministic green. Exclude that flake from phase pass/fail. |
| Sync requirement | Rate limiter + pruner + config tests MUST be `async: false` (shared ETS table + Application env mutation + DB CASCADE truncation — mirror `RateLimiterTest`/`PrunerTest`). |

### Phase Requirements → Test Map
| Req | Behavior | Test Type | Automated Command (per-file) | File |
|-----|----------|-----------|------------------------------|------|
| IOPS-01 | Doctor exits 0 all-pass; 1 on fail / warn-under-`--strict`; 2 cannot-diagnose; human+JSON parity | unit (CLI) + unit (Internal.Doctor) | `mix test test/mix/tasks/mailglass_inbound_doctor_test.exs` | ❌ Wave 0 |
| IOPS-01 | Route-conflict: subsumption→fail, witness-probe shadow→fail, regex-vs-regex→warn, names line numbers | unit | `mix test test/mailglass_inbound/internal/doctor_test.exs` | ❌ Wave 0 |
| MIME-03 | Doctor reports backend name + `:vsn`; warns when absent | unit | (same doctor test) | ❌ Wave 0 |
| IOPS-02 | Replay CLI: `--record-id`/`--since`/`--tenant` AND-combine → id list → iterate; `[y/N]` default-No; `--yes` skips; 0 matches → exit 0 "nothing to replay"; appends `source: :replay` | integration | `mix test test/mix/tasks/mailglass_inbound_replay_test.exs` | ❌ Wave 0 |
| IOPS-03 | Prune: LIMIT-1000 batching loops until <1000; advisory-lock single-run (second concurrent run → `:locked_out`); child-first order; `:infinity` disables a window; per-table telemetry counts | integration | `mix test test/mailglass_inbound/internal/prune_test.exs` | ❌ Wave 0 |
| IOPS-03 | Prune mix task runs synchronously with AND without Oban | integration | `mix test test/mix/tasks/mailglass_inbound_prune_test.exs` | ❌ Wave 0 |
| IOPS-04 | 3-bucket leaky-bucket trips at tenant/recipient/sender_domain limits; tripped bucket's own `Retry-After`; 429 body+telemetry carry bucket TYPE not value; no PII keys; post-verify (forgery burns no budget) | unit + integration | `mix test test/mailglass_inbound/rate_limiter_test.exs` + `.../ingress/plug_test.exs` | ❌ Wave 0 / EXTEND |
| IOPS-05 | Suppressed-sender mail persists with `suppression_flagged: true`; degrades OPEN on store error/empty-from; surfaces in IADM-02 select; reaches mailbox via `signals.suppression_flagged`; pre-migration record projects default `false`; no auto-bounce | integration + unit | `mix test test/mailglass_inbound/ingress/persist_test.exs` + `.../inbound_message_test.exs` + `.../internal/operator/records_test.exs` | ❌ Wave 0 / EXTEND |

### Per-deliverable validation detail

**1. `inbound.doctor` (IOPS-01, MIME-03)**
- *Minimal observable behaviors:* exit code is exactly the locked three-state mapping;
  human output groups findings + summary line; JSON is one `%{summary, findings}` object;
  human/JSON/runtime contract stay in parity (mirror `mail_doctor_task_test.exs:120-122`).
- *Test seams/fixtures:* a **fake router module** defined in the test with (a) a clean set of
  routes, (b) a broad-before-narrow pair (catch-all `recipient: nil` before a specific string),
  (c) a witness-probe shadow pair (an exact-string route shadowed by an earlier broader one),
  (d) a regex-vs-regex pair. A **fake mailbox** that implements `process/1` and one that does
  NOT (to exercise the behaviour check). Pass the router via an opt so `Internal.Doctor` reads
  `__mailglass_inbound_routes__/0` from the fixture, not app config.
- *Layer:* `Internal.Doctor` logic = pure unit (no DB, no DNS — that is the whole point). The
  Mix task = thin CLI unit test asserting exit codes via `catch_exit` and stdout via
  `capture_io` (mirror `run_task!/1` in `mail_doctor_task_test.exs:182-190`).
- *Coverage concern:* the three-state exit must be asserted for all three states explicitly
  (Pitfall 6). `--strict` warn-promotes-to-fail is a distinct case. Route-conflict must assert
  the line-number string appears (D-49-08 `:source`).

**2. `inbound.replay` (IOPS-02)**
- *Minimal observable behaviors:* selector resolution produces the right id set (AND-combine);
  per-record `replay/2` is invoked once each; `[y/N]` defaults No (no replay on empty input);
  `--yes` skips the prompt; zero matches → exit 0 with the "nothing to replay" message; replay
  appends an `ExecutionRun` with `source: :replay` (no UPDATE).
- *Test seams/fixtures:* seed N inbound records across two tenants + two `--since` windows;
  inject a fake `Mix.shell()` (use `Mix.Shell.Process` + `assert_received {:mix_shell, :yes?,
  _}` or a stub) to assert the prompt is shown / suppressed by `--yes`; a stub `Internal.Replay`
  (opt-injectable, mirror `replay_test.exs`'s `ReplayExecution`/`ReplayRepo` process-dict stubs)
  to count `replay/2` calls without a real execution. For the append assertion, use the real DB
  path and `Repo.aggregate(ExecutionRun, :count)` before/after + assert `source == :replay`.
- *Layer:* selector→id-list query = unit; prompt/`--yes`/exit-0-on-empty = CLI unit; append +
  `source: :replay` = integration (real repo).
- *Coverage concern:* the `[y/N]`-default-No path is the destructive-confirmation gate — assert
  that an empty/`"n"` answer performs NO replay. `--dry-run` reports count+scope with no change.

**3. `inbound.prune` (IOPS-03)**
- *Minimal observable behaviors:* over-window rows deleted, in-window rows kept, per the four
  windows; deletes happen in batches of ≤1000 looping until <1000; `pg_try_advisory_lock`
  serializes (a second concurrent sweep returns `{:ok, :locked_out}` and deletes nothing);
  child-first order (no FK violation); `:infinity` on a class → that class deletes 0 without
  issuing the DELETE (mirror `pruner_test.exs:73-80`); telemetry `[:mailglass_inbound, :prune,
  :stop]` carries per-table counts only.
- *Test seams/fixtures:* a **seeded over-window dataset** — insert ≥1001 records older than 90d
  (+ their evidence + fresh/replay runs) to force ≥2 batch iterations; assert remaining count
  and iteration count (e.g. instrument batch count via telemetry or a returned `%{... iterations}`
  map). For the **advisory-lock single-run** test: acquire the lock in the test process via
  `Repo.query!("SELECT pg_try_advisory_lock($1)", [key])`, then call `prune/0` and assert
  `{:ok, :locked_out}`; release. (Postgres advisory locks are per-session; the sandboxed test
  connection counts as a session — verify the sandbox mode allows this, else use a separate
  checked-out connection.) For `:infinity`: set the config key, assert 0 deleted AND that no
  DELETE was issued (count unchanged). Use `async: false` + `TRUNCATE ... CASCADE` setup like
  `PrunerTest`.
- *Layer:* batching + advisory lock + order + `:infinity` = integration (real Postgres — these
  behaviors are SQL-level and cannot be unit-faked). Window-day math + config parsing = unit.
- *Coverage concern:* the LIMIT-1000 boundary is the load-bearing assertion (IOPS-03) — must
  prove ≥2 iterations on a 1001+ dataset, not just "rows deleted." The advisory-lock test is
  the trickiest seam (session semantics under Ecto Sandbox) — budget extra time; a fallback is
  to assert the lock is *attempted* (telemetry/log) if true cross-session locking is hard under
  sandbox.

**4. Ingress rate limiter (IOPS-04)**
- *Minimal observable behaviors:* fresh bucket allows up to capacity, then `{:error,
  %RateLimitError{}}`; the FIRST-tripping bucket (tenant→recipient→sender_domain order) sets the
  error; its `retry_after_ms` drives `Retry-After`; the 429 body is `%{status: "rate_limited",
  bucket: "<type>"}`; telemetry meta carries `bucket/limit/retry_after`, NO recipient/sender/
  email; independent buckets per key; refill over time restores tokens; **post-verify** (a
  forged request returns 401 and burns no budget).
- *Test seams/fixtures:* mirror `RateLimiterTest` exactly — `async: false`, reset ETS via
  `:ets.delete_all_objects(:mailglass_inbound_rate_limit)` in setup, set
  `:mailglass_inbound` rate_limit config per test, snapshot/restore. **Concurrent-load** test:
  spawn M > capacity tasks via `Task.async_stream` hitting the same key and assert exactly
  `capacity` succeed and the rest `{:error, _}` (proves ETS atomicity under concurrency — the
  `decentralized_counters`/`write_concurrency: :auto` claim). For the **plug placement** test:
  extend `plug_test.exs` — drive a verified request through `Ingress.Plug` with a tiny capacity
  and assert the 2nd+ request gets 429 + `Retry-After`; drive a FORGED request and assert 401
  with the limiter NOT consulted (budget intact afterward).
- *Layer:* token-bucket math + bucket order + PII-free error = unit (`rate_limiter_test.exs`);
  concurrent atomicity = unit/property-ish (concurrency harness); post-verify placement + 429
  egress + telemetry = integration (`plug_test.exs`).
- *Coverage concern:* the post-verify invariant (Pitfall 1) and the per-bucket-`Retry-After`
  (not cross-bucket max) are the two non-obvious correctness properties — assert both directly.
  Telemetry PII-absence asserted via `refute Map.has_key?(meta, :recipient/:to/:email/:sender)`.

**5. Suppression flag-only (IOPS-05)**
- *Minimal observable behaviors:* a message whose first `from` address is on the tenant's
  suppression list persists with `suppression_flagged: true`; a non-suppressed sender → `false`;
  store `{:error, _}` → `false` (degrade OPEN); empty/missing `from` → `false`; the flag
  surfaces in the IADM-02 `Internal.Operator.Records.list_records/2` select; the column projects
  to `%InboundMessage{signals: %Signals{suppression_flagged: ...}}` via `message_from_record/1`;
  a **pre-migration record** (column defaulted `false`) projects `false` without `KeyError`;
  mailbox `process/1` receives the flag; NO auto-bounce (a suppressed sender still reaches the
  mailbox unless the adopter rejects); telemetry `[:mailglass_inbound, :ingress,
  :suppression_flag, :stop]` carries `%{flagged, tenant_id, provider}` only.
- *Test seams/fixtures:* a **suppressed-sender fixture** — `record/2` a suppression entry for
  `tenant_id` + `from`-address (via the configured `SuppressionStore.Ecto`), then run
  `Persist.persist/2` and assert the inserted record's `suppression_flagged`. A **degrade-OPEN
  fixture** — inject a stub suppression store (via `config :mailglass, suppression_store: Stub`
  with `on_exit` restore) whose `check/2` returns `{:error, :boom}`, assert `false` + persist
  still succeeds. An **empty-from fixture** — `%InboundMessage{from: []}` → `false`. For the
  Signals projection: build/insert a record with `suppression_flagged: true`, call
  `message_from_record/1`, assert `msg.signals.suppression_flagged == true` and
  `suppression_flagged?/1`. For pre-migration default: build a record without setting the column
  (gets DB default `false`) and assert projection is `false` (no `KeyError`) — also a pure
  struct test: `%InboundMessage{}.signals.suppression_flagged == false`.
- *Layer:* flag computation + degrade-OPEN + empty-from = integration (real store) + unit (stub
  store); Signals struct defaults + projection = unit; IADM-02 select = integration (extend
  `records_test.exs`); no-auto-bounce = unit (assert mailbox still invoked).
- *Coverage concern:* degrade-OPEN is the safety-critical branch (Pitfall 3) — assert BOTH that
  the flag is `false` AND that persist succeeds on a store error. The pre-migration/struct-default
  path (Pitfall 7) guards the public contract — assert dot-access never raises.

### Sampling Rate
- **Per task commit:** the per-file quick command for the file(s) the task touches (`--seed 0`).
- **Per wave merge:** full inbound suite `--seed 0`, excluding the known phase-45 property flake.
- **Phase gate:** full inbound suite green (`--seed 0`) + `mix credo --strict` green (telemetry
  whitelist extension is credo-enforced — RUN credo, don't grep) before `/gsd:verify-work`.
  Note core `voice_test.exs` "Oops" failure is pre-existing dep-JS noise — exclude from
  pass/fail (MEMORY).

### Wave 0 Gaps
- [ ] `test/mix/tasks/mailglass_inbound_doctor_test.exs` — IOPS-01/MIME-03 (CLI exit codes + parity)
- [ ] `test/mailglass_inbound/internal/doctor_test.exs` — IOPS-01 (DNS-free checks + conflict detection)
- [ ] `test/mix/tasks/mailglass_inbound_replay_test.exs` — IOPS-02 (selectors + confirm + `--yes`)
- [ ] `test/mailglass_inbound/internal/prune_test.exs` — IOPS-03 (batching + advisory lock + order + `:infinity`)
- [ ] `test/mix/tasks/mailglass_inbound_prune_test.exs` — IOPS-03 (sync-with/without-Oban)
- [ ] `test/mailglass_inbound/rate_limiter_test.exs` — IOPS-04 (buckets + concurrency + PII-free)
- [ ] `test/mailglass_inbound/config_test.exs` — D-49-02/03 (schema validation + `:infinity`)
- [ ] EXTEND `test/mailglass_inbound/ingress/plug_test.exs` — IOPS-04 (post-verify 429 placement)
- [ ] EXTEND `test/mailglass_inbound/ingress/persist_test.exs` — IOPS-05 (flag compute + degrade-OPEN)
- [ ] EXTEND `test/mailglass_inbound/inbound_message_test.exs` — IOPS-05 (Signals defaults + predicate)
- [ ] EXTEND `test/mailglass_inbound/internal/operator/records_test.exs` — IOPS-05 (select surfaces flag)
- [ ] Test fixtures: fake router (clean/subsumption/witness/regex), fake mailboxes (impl/no-impl),
      suppressed-sender + degrade-OPEN stub store, seeded over-window (1001+) dataset
- [ ] Migration test: `suppression_flagged` backfill default on existing rows

*(No framework install needed — ExUnit + StreamData already present per `mix.exs`.)*

## Security Domain

> `security_enforcement` is not `false` in config → included.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no (signature verify is pre-existing, upstream of this phase) | provider signature gate in `Ingress.Plug` (unchanged) |
| V3 Session Management | no | n/a (stateless webhook ingress) |
| V4 Access Control | yes | tenant scoping: rate-limit buckets keyed on resolved `tenant_id` (post `resolve_tenant!`); suppression check + admin select via `Mailglass.Tenancy.scope/2` |
| V5 Input Validation | yes | NimbleOptions config schema (`MailglassInbound.Config`); OptionParser `strict:` + `validate_cli!/3` on all three tasks; ILIKE-escaping already in `records.ex` |
| V6 Cryptography | no (no new crypto; doctor NEVER verifies signatures, only checks key presence — D-49-06) | reuse `Mailglass.OptionalDeps.GenSmtp` for MIME, no hand-rolled crypto |
| V7 Error Handling/Logging | yes | no PII in telemetry (extended D-45-03 whitelist); 429 body carries bucket TYPE only; degrade-OPEN logs no PII |

### Known Threat Patterns for mailglass_inbound + Phase 49 surfaces
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unauthenticated-DoS budget exhaustion (forged flood consumes a tenant's rate budget) | Denial of Service | Limiter is POST-verify — forgery returns 401 before any budget read (D-49-14, Pitfall 1) |
| PII leak via rate-limit telemetry / 429 body (sender/recipient address) | Information Disclosure | Sender keyed on DOMAIN; telemetry+body carry bucket TYPE only, never value (D-49-16/17) |
| Backscatter (auto-bouncing webhook-accepted mail → collateral spam to forged senders, blocklisting) | (reputational/abuse) | Flag-only, NO auto-bounce / NO auto-suppression (D-49-23) |
| Cross-tenant data exposure in prune / replay / admin select | Information Disclosure / Elevation | Tenant-scoped queries throughout; suppression `check/2` scopes internally via `Tenancy.scope` |
| Concurrent prune races (cron tick + manual run double-delete / lock contention) | Tampering / DoS | `pg_try_advisory_lock` single-run guard → second run `{:ok, :locked_out}` (D-49-27) |
| SQL injection via CLI selectors (`--tenant`, `--record-id`, `--since`) | Tampering | Parameterized Ecto queries (never interpolate); `--since` parsed via `DateTime`/`NaiveDateTime` |
| Signature verification bypass via doctor (operator thinks keys are valid because doctor "passed") | Spoofing | Doctor checks key PRESENCE only and says so; NEVER verifies a signature (D-49-06) — finding text must be honest about this |

## Project Constraints (from CLAUDE.md)

These CLAUDE.md directives bear directly on Phase 49 and are binding (same authority as locked
decisions):

- **Boundary law:** `mailglass_inbound` → `mailglass` only; one-directional. All new surfaces in
  inbound; core gains no inbound dep (D-49-01).
- **No PII in telemetry:** never `:to/:from/:body/:html_body/:subject/:headers/:recipient/
  :email/:sender`. New spans carry counts/types/ids only (D-49-16/17/23/29). Whitelist must be
  extended AND `NoPiiInTelemetry` allowlist updated.
- **Errors as a public API contract — pattern-match the struct, never the message string.** Reuse
  `Mailglass.RateLimitError` struct; match `%RateLimitError{type: ...}` (Things-Not-To-Do #7).
- **Append-only `mailglass_inbound` tables:** retention DELETEs ARE allowed (no UPDATE/DELETE
  trigger on inbound tables — `[VERIFIED]` storage_foundation migration has none); replay APPENDS
  `source: :replay` (no UPDATE).
- **Optional deps gated through `OptionalDeps.*` + `available?/0`:** Oban prune worker behind
  `Code.ensure_loaded?(Oban.Worker)`; MIME via `OptionalDeps.GenSmtp` — no bare refs
  (`NoBareOptionalDepReference`). `mix compile --no-optional-deps --warnings-as-errors` must stay
  green (do NOT run `--no-optional-deps --force` on shared `_build` per MEMORY).
- **Don't use `name: __MODULE__` to register singletons in library code** (#8) — but
  `RateLimiter.TableOwner` is the documented exception (core's has a `LINT-07` allowlist entry +
  `api_stability.md` note; inbound's must get the same allowlist treatment).
- **Multi-tenancy first-class:** `tenant_id` on every record + `Tenancy.scope/2` on every inbound
  query (admin select, suppression check).
- **Brand voice for CLI/error text:** "Inbound doctor blocked: --format must be human or json" —
  specific, composed, no "Oops!" (`mailglass-brand-book.md`).
- **`mix.lock` discipline:** this phase adds NO deps, so `mix.lock` should NOT change. If it
  does, exclude transitive drift from commits (MEMORY).
- **Planner branch reconcile:** `gsd-planner` creates `plan/phase-49`; this repo keeps docs on
  main → ff-merge back + delete the branch after confirming (MEMORY).

## Sources

### Primary (HIGH confidence — read in-session 2026-05-25)
- `49-CONTEXT.md` — D-49-01..30, canonical refs, code anchors (binding).
- `REQUIREMENTS.md:34,89-93` — IOPS-01..05 + MIME-03 exact wording.
- `ROADMAP.md:192-213` — Phase 49 goal, success criteria 1-5, hardest sub-tasks.
- Core anchors: `lib/mix/tasks/mail.doctor.ex`, `lib/mailglass/deliverability/formatter.ex`,
  `lib/mailglass/webhook/pruner.ex`, `lib/mix/tasks/mailglass.webhooks.prune.ex`,
  `lib/mailglass/rate_limiter.ex` + `rate_limiter/{table_owner,supervisor}.ex`,
  `lib/mailglass/errors/rate_limit_error.ex`, `lib/mailglass/suppression_store.ex` + `ecto.ex`,
  `lib/mailglass/config.ex`, `lib/mailglass/application.ex`,
  `lib/mailglass/optional_deps/gen_smtp.ex`.
- Inbound anchors: `ingress/plug.ex`, `ingress/persist.ex`, `inbound_message.ex`,
  `execution.ex`, `mailbox.ex`, `router.ex` + `router/{matcher,route}.ex`,
  `internal/replay.ex`, `internal/operator/records.ex`, `telemetry.ex`, `application.ex`,
  `optional_deps.ex`, all four `inbound_records/*.ex` schemas, `schema.ex`.
- Migrations: `..._create_mailglass_inbound_storage_foundation.exs` (FK `on_delete: :nothing`,
  no DELETE/UPDATE trigger), `..._generalize_replay_runs_to_execution_lineage.exs` (`source`).
- Tests (pattern source): `test/mailglass/rate_limiter_test.exs`,
  `test/mailglass/webhook/pruner_test.exs`, `test/mix/tasks/mail_doctor_task_test.exs`,
  `mailglass_inbound/test/mailglass_inbound/replay_test.exs`.
- `mix.lock` / `mailglass_inbound/mix.exs` — version + boundary-compiler verification.

### Secondary (MEDIUM — CONTEXT external precedents, verified by CONTEXT 2026-05-25)
- Ecto.Schema.Metadata, Broadway.Message, Plug.Conn `:assigns`/`:private` — the `:signals`
  typed-nested-struct archetype.
- Rails ActionMailbox `incinerate_after` (30d), backscatter avoidance.
- Postgres time-based retention (batched `DELETE ... FOR UPDATE SKIP LOCKED`, advisory locks);
  Oban.Plugins.Pruner.
- Credo three-tier exit statuses; clig.dev exit-code/`--json`/dry-run conventions.

### Tertiary (LOW — none needed)
- None. This phase is fully grounded in the in-repo anchors + locked decisions; no
  unverified web claims load-bearing.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new deps; all versions verified from mix.lock.
- Architecture: HIGH — all surfaces clone read-in-session anchors with enumerated deltas.
- Pitfalls: HIGH — derived directly from the anchor code + locked decisions, not speculation.
- Validation: HIGH — test seams mirror existing `RateLimiterTest`/`PrunerTest`/`mail_doctor`
  patterns; the two harder seams (advisory-lock-under-sandbox, batch-iteration assertion) are
  flagged with fallbacks.
- One MEDIUM open item: whether to introduce the `:boundary` compiler into inbound (A1/Q1).

**Research date:** 2026-05-25
**Valid until:** ~2026-06-24 (stable — internal code anchors + locked decisions; re-verify only
if `mailglass_inbound` package structure or core `RateLimiter`/`Pruner` change before planning).

## RESEARCH COMPLETE
