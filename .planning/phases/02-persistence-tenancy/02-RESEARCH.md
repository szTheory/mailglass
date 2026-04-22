# Phase 2: Persistence + Tenancy — Research

**Researched:** 2026-04-22
**Domain:** Ecto schemas, append-only event ledger, SQLSTATE 45A01 immutability trigger, multi-tenancy primitives, migration delivery
**Confidence:** HIGH (nearly every decision is locked upstream in CONTEXT.md D-01..D-43 with accrue / Oban as verbatim precedent; this research closes the remaining micro-decisions — column order, query planner shapes, test harness details — without re-litigating scope.)

## Summary

Phase 2 is the structural keystone: after it closes, the append-only `mailglass_events` table plus the SQLSTATE 45A01 `BEFORE UPDATE OR DELETE` trigger exist, `tenant_id TEXT NOT NULL` lives on all three mailglass schemas, and `Mailglass.Events.append_multi/3` is the one canonical writer threaded through an `Ecto.Multi`. Because CONTEXT.md already locked 43 decisions (D-01..D-43), the planner's job is not "choose between alternatives" but "render 43 decisions into a buildable plan tree." This research document therefore focuses on (a) exact DDL + index shapes ready to paste into migration files, (b) exact Ecto schema shapes with hand-written `@type t :: %__MODULE__{...}` per D-22, (c) the Oban-pattern migration module skeleton per D-35, (d) the accrue-pattern `append/1` + `append_multi/3` writer per D-01..D-06, (e) the runtime guardrails for MAIL-03 / MAIL-07 / MAIL-09 / PHX-04 / PHX-05 that the planner must verify in tests, and (f) the ten open questions from ROADMAP.md resolved with concrete answers tied to CONTEXT.md decisions.

**Primary recommendation:** Adopt accrue's `lib/accrue/events.ex` + `priv/repo/migrations/20260411000001_create_accrue_events.exs` as the verbatim architectural template, diverging only where CONTEXT.md mandates — UUIDv7 PKs per D-25, `append`/`append_multi` naming per PERSIST-05 + D-01, the Oban migration-dispatcher pattern per D-35, and three sibling schemas (`mailglass_deliveries` + `mailglass_events` + `mailglass_suppressions`) rather than one. Build in tight dependency order: Wave 0 test infra → V01 DDL (3 tables + trigger + indexes) → Ecto schemas → Tenancy behaviour → Events writer → SuppressionStore behaviour → Projector → Reconciler query functions → StreamData property harness. Every open question from ROADMAP.md has a concrete answer below (§Open Questions Resolved).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Event writer API surface (PERSIST-05)**
- **D-01:** Dual public API — `Mailglass.Events.append_multi(multi, name, attrs)` is the canonical path for writes paired with a domain mutation (Delivery insert, Suppression.record, webhook projection update). `Mailglass.Events.append(attrs)` is sugar that opens its own `Repo.transact/1` for standalone audit events. Returns `{:ok, %Event{}}`. 4-of-4 convergent with accrue's `record/1` + `record_multi/3` pattern.
- **D-02:** REQ PERSIST-05 amended — the "outside an Ecto.Multi raises ArgumentError" wording is superseded. Actual invariant: `append_multi/3` is canonical; `append/1` wraps `Repo.transact/1`; any writes via other paths are forbidden (Phase 6 `NoRawEventInsert` Credo check).
- **D-03:** Idempotency replay mechanics — `on_conflict: :nothing, conflict_target: {:unsafe_fragment, "(idempotency_key) WHERE idempotency_key IS NOT NULL"}, returning: true`. On conflict, `Repo.insert/2` returns `{:ok, %Event{id: nil}}`; the `append/1` path detects `id: nil` and fetches the existing row by `idempotency_key`. `append_multi/3` lets the caller observe replay via a follow-up `Multi.run` step.
- **D-04:** Replay observability via telemetry — both paths emit `[:mailglass, :events, :append, :start | :stop | :exception]` spans; `:stop` metadata includes `inserted?: boolean` and `idempotency_key_present?: boolean`. No return-shape widening.
- **D-05:** Auto-capture via process dict — `append/1` reads `Mailglass.Tenancy.current/0` for `tenant_id` and `:otel_propagator_text_map.current/0` for `trace_id` (optional, nil-tolerant). Callers may override via explicit attrs.
- **D-06:** SQLSTATE 45A01 translation activates in `Mailglass.Repo.transact/1` — pattern-match `%Postgrex.Error{postgres: %{pg_code: "45A01"}}` and reraise as `Mailglass.EventLedgerImmutableError`. Never pattern-match the message string.

**Suppression `:scope` enum + stream dimension (PERSIST-04)**
- **D-07:** `:scope ∈ :address | :domain | :address_stream` with a nullable `stream` column (populated only when `scope = :address_stream`). UNIQUE index `(tenant_id, address, scope, COALESCE(stream, ''))` per ARCHITECTURE §4.4 + PERSIST-04. Matches Postmark's per-stream suppressions API.
- **D-08:** `:tenant_address` atom is removed pre-GA. Tenant scoping is structural via `tenant_id` + `Mailglass.Tenancy.scope/2`, not an atom value.
- **D-09:** Phase 1 `Mailglass.SuppressedError` pre-GA patch — `@types` becomes `[:address, :domain, :address_stream]`; `docs/api_stability.md` §Errors documents the pre-0.1.0 refinement.
- **D-10:** `Ecto.Enum` for closed atom columns — `scope`, `reason`, `stream` all via `Ecto.Enum`. Ecto 3.13 idiom; auto string↔atom coercion; raises on unknown values at load time.
- **D-11:** MAIL-07 "no default" preserved — changeset requires `:scope` explicitly; no DB-level default. `Mailglass.Suppressions.add/2` signature is `add(attrs, opts \\ [])` where attrs must include `:address`, `:reason`, `:scope`.
- **D-12:** v0.5 webhook auto-add shape locked — `:bounced` → `%{scope: :address, reason: :hard_bounce}`; `:complained` → `%{scope: :address, reason: :complaint}`; `:unsubscribed on :bulk stream` → `%{scope: :address_stream, stream: :bulk, reason: :unsubscribe}`. Transactional unsubscribes never happen.

**Delivery projection columns + status state machine (PERSIST-01)**
- **D-13:** Full 8 projection columns ship in v0.1 — `last_event_type (text, NOT NULL)`, `last_event_at (utc_datetime_usec, NOT NULL)`, `terminal (boolean, NOT NULL DEFAULT false)`, `dispatched_at`, `delivered_at`, `bounced_at`, `complained_at`, `suppressed_at` (utc_datetime_usec nullable). Plus `metadata jsonb NOT NULL DEFAULT '{}'` and `lock_version integer NOT NULL DEFAULT 1`.
- **D-14:** Single projector module — `Mailglass.Outbound.Projector.update_projections/2` takes `%Delivery{}` + `%Event{}`, returns an `Ecto.Changeset` or `Multi.run` function. Used by dispatch (Phase 3), webhook ingest (Phase 4), and orphan reconciliation.
- **D-15:** Monotonic app-level rule, no DB CHECK constraint — projector only sets fields to "later" values; `dispatched_at` never overwrites non-nil; `delivered_at` / `bounced_at` / `complained_at` / `suppressed_at` set once; `last_event_at` = max; `terminal` flips once on `:delivered | :bounced | :complained | :rejected | :failed | :suppressed`.
- **D-16:** Monotonicity proven by StreamData property test — generates N∈1..10 replay sequences of events and asserts `apply_all(sequence) == apply_all(dedup(sequence))`.
- **D-17:** `metadata jsonb` on all three schemas with `NOT NULL DEFAULT '{}'`.
- **D-18:** `lock_version` ships on `mailglass_deliveries` now (not Phase 3). Optimistic locking via `Ecto.Changeset.optimistic_lock/3`.

**Orphan webhook reconciliation in Phase 2 (partial HOOK-06)**
- **D-19:** Column + index + pure query functions in Phase 2; Oban worker in Phase 4. `mailglass_events.needs_reconciliation boolean NOT NULL DEFAULT false` + partial index `WHERE needs_reconciliation = true`. `Mailglass.Events.Reconciler` ships `find_orphans/1` + `attempt_link/2` as pure Ecto query functions.
- **D-20:** Reconciliation cadence (Phase 4 reference) — `{:cron, "*/15 * * * *"}`. Phase 2 does not implement the worker.
- **D-21:** `needs_reconciliation` lives only on events, not projected onto deliveries.

**Schema typing discipline (PERSIST-01..04)**
- **D-22:** Hand-written `@type t :: %__MODULE__{...}` + plain `use Ecto.Schema`. Zero new deps.
- **D-23:** `:typed_ecto_schema` and `:typed_struct` rejected. Elixir 1.19's native typed-struct roadmap makes them transitional.
- **D-24:** Phase 6 candidate Credo check — `Mailglass.Credo.EctoSchemaHasTypespec` asserts every `use Ecto.Schema` has a matching `@type t`.

**Primary key / ID strategy (PERSIST-01..04)**
- **D-25:** UUIDv7 everywhere via `{:uuidv7, "~> 1.0"}` required dep. `@primary_key {:id, UUIDv7, autogenerate: true}` + `@foreign_key_type :binary_id` on all three schemas.
- **D-26:** `mailglass_events` uses UUIDv7 despite accrue's bigserial precedent (non-enumerability; future shardability).
- **D-27:** Postgres 18 migration path is free — `default: fragment("uuidv7()")` replaces app-layer generation later.
- **D-28:** `Mailglass.Schema` helper macro — stamps `@primary_key {:id, UUIDv7, autogenerate: true}`, `@foreign_key_type :binary_id`, `@timestamps_opts [type: :utc_datetime_usec]`.

**Tenancy behaviour surface (TENANT-01, TENANT-02)**
- **D-29:** Narrow callback surface: `@callback scope(queryable, context) :: Ecto.Queryable.t()` on `Mailglass.Tenancy` behaviour. One callback.
- **D-30:** Non-callback helpers on `Mailglass.Tenancy` module — `current/0`, `put_current/1`, `with_tenant/2`, `tenant_id!/0`. Mirrors accrue's `Accrue.Actor` battle-tested pattern.
- **D-31:** `Mailglass.Tenancy.SingleTenant` default — returns literal `"default"` from `current/0`; `scope/2` is a no-op.
- **D-32:** Phoenix 1.8 `%Scope{}` interop via documented two-liner — adopter writes `Mailglass.Tenancy.put_current(scope.organization.id)` inside `on_mount/4`. Core never pattern-matches `%Phoenix.Scope{}`.
- **D-33:** `Mailglass.Oban.TenancyMiddleware` under the optional-Oban gateway — serializes `current/0` into job args on enqueue, restores via `put_current/1` in `perform/1`.
- **D-34:** TENANT-03 Credo check implementability — `NoUnscopedTenantQueryInLib` becomes a pure AST match with D-29's narrow callback.

**Migration delivery path (PERSIST-06)**
- **D-35:** Oban-style compiled DDL module — `Mailglass.Migration` is the public API (`up/0`, `down/0`, `up(version: 2)`, `down(version: 2)`). `Mailglass.Migrations.Postgres` is the version dispatcher (tracks current via `pg_class` comment). `Mailglass.Migrations.Postgres.V01` holds Phase 2 DDL.
- **D-36:** `mix mailglass.gen.migration` is an 8-line wrapper generator.
- **D-37:** Phase 2 test infrastructure uses the same code path — `test/support/test_repo.ex` + synthetic migration file calling `Mailglass.Migration.up/0`. Zero test-only DDL fork.
- **D-38:** Phase 7 installer composes over Phase 2's task.
- **D-39:** `mailglass_inbound` (v0.5+) gets its own `MailglassInbound.Migrations` with independent version counter.

**`tenant_id` column type + timestamps precision**
- **D-40:** `tenant_id TEXT NOT NULL` on all three schemas. Default literal `"default"` returned by `SingleTenant.current/0` when no Plug stamped anything.
- **D-41:** `timestamps(type: :utc_datetime_usec)` uniformly on all three schemas + every domain timestamp column.
- **D-42:** Provider `occurred_at` stored at microsecond precision despite second-precision payload. `inserted_at` (controlled by `Mailglass.Clock`) orders the ledger.
- **D-43:** Phase 6 candidate Credo check — `Mailglass.Credo.TimestampsUsecRequired`.

### Claude's Discretion

- **Exact field order in schema files** — follow accrue's pattern (identifier → tenant_id → foreign keys → state → metadata/flags → timestamps).
- **Migration naming** — `priv/repo/migrations/00000000000001_mailglass_init.exs` for the synthetic Phase 2 test migration; `<timestamp>_add_mailglass.exs` for adopter-facing.
- **Index names** — use ARCHITECTURE.md §4.2 / §4.3 / §4.4 names verbatim.
- **Exact changeset validation order** — mirror accrue's cast → validate_required → validate_inclusion / Ecto.Enum narrowing.
- **Telemetry emit granularity** — `[:mailglass, :events, :append, :*]`; `[:mailglass, :persist, :delivery, :update_projections, :*]`; `[:mailglass, :persist, :reconcile, :link, :*]`. Metadata keys from Phase 1 D-31 whitelist only.
- **`mailglass_suppressions.source TEXT` values** — `"webhook:postmark"`, `"admin:user_id=..."`, `"auto"`. Not enforced as enum.
- **`Mailglass.SuppressionStore` behaviour callbacks** — at minimum `check/2` and `record/1`; others land Phase 3.

### Deferred Ideas (OUT OF SCOPE)

- **Orphan reconciliation Oban worker** — Phase 4. Phase 2 ships only `find_orphans/1` + `attempt_link/2` pure query functions.
- **`:pg`-coordinated / multi-node tenancy** — v0.5+.
- **Full `current_scope/1 + tenant_id/1 + scope_query/2` Tenancy trio** — not adopted (D-29).
- **`:typed_ecto_schema` / `:typed_struct`** — rejected (D-23).
- **GIN index on `metadata jsonb`** — v0.5.
- **Webhook auto-add to suppressions** — v0.5 DELIV-03.
- **Soft-bounce escalation rule (5 bounces in 7 days)** — v0.5 DELIV-03.
- **Cluster-coordinated rate-limiting** — v0.5+.
- **Materialized rollup views** — v0.5+.
- **`Mailglass.SuppressionStore.ETS` / `.Redis` impls** — v0.5+ (Phase 3 may add ETS for test speed — Claude's discretion).
- **Per-tenant adapter resolver** — v0.5 DELIV-07.
- **Postgres 18 server-side `uuidv7()` default** — adopter-owned.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PERSIST-01 | `mailglass_deliveries` schema with 8 projection columns + `(provider, provider_message_id) WHERE NOT NULL` UNIQUE index (MAIL-09 prevention) | §Schema & DDL §1 (DDL + index catalog); §Ecto Schemas §3.1 (Delivery shape); §Open Questions §Q1 (projection column list + Projector-owned update shape) |
| PERSIST-02 | `mailglass_events` schema + `mailglass_raise_immutability` trigger raising SQLSTATE 45A01 | §Schema & DDL §2 (trigger function body verbatim); §Ecto Schemas §3.2 (Event shape); §Landmines §L1 (accrue `mailglass_raise_immutability` naming precedent) |
| PERSIST-03 | UNIQUE partial index on `idempotency_key WHERE NOT NULL` + `on_conflict: :nothing` (MAIL-03 prevention); StreamData property test | §Events Append API §5 (idempotency mechanics); §Landmines §L2 (`{:unsafe_fragment, ...}` form for partial-index conflict target); §Validation Architecture (StreamData harness shape) |
| PERSIST-04 | `mailglass_suppressions` schema with `:scope` enum (no default), UNIQUE `(tenant_id, address, scope, COALESCE(stream, ''))` | §Schema & DDL §3 (DDL with `Ecto.Enum` mapping); §Ecto Schemas §3.3 (Suppression.Entry shape); D-07..D-12 verbatim |
| PERSIST-05 | `Mailglass.Events.append/2` is the only public writer; other paths forbidden | §Events Append API §5 (dual writer shape); D-01..D-06 verbatim; §Landmines §L3 (telemetry signals replay without widening return shape) |
| PERSIST-06 | `mix mailglass.gen.migration` + adopter `mix ecto.migrate` bring schemas + trigger into existence | §Migration Strategy §2 (Oban-pattern dispatcher); D-35..D-39 verbatim; §Landmines §L4 (synthetic test migration runs same code path) |
| TENANT-01 | `tenant_id` column (indexed; nullable for single-tenant mode) on all three schemas | §Tenancy Behaviour §4 + §Schema & DDL (text NOT NULL per D-40, not nullable — REQ-wording superseded) |
| TENANT-02 | `Mailglass.Tenancy` pluggable behaviour + `SingleTenant` no-op default + Phoenix 1.8 `%Scope{}` interop documented but not auto-detected | §Tenancy Behaviour §4 (callback + helpers + SingleTenant); D-29..D-34 verbatim |

**TENANT-01 wording clarification:** REQUIREMENTS.md line 57 says "nullable for single-tenant mode"; CONTEXT.md D-40 refines to `tenant_id TEXT NOT NULL` with a literal `"default"` value from `SingleTenant.current/0`. The D-40 refinement is the operative constraint — it removes an entire class of "forgot to set tenant_id" bugs at write time, and the default string honors the "single-tenant adopters need zero configuration" spirit of the original REQ.

</phase_requirements>

## Architectural Responsibility Map

Phase 2 is server-side-only (Ecto schemas, DB triggers, behaviour modules, process-dict helpers). No browser / frontend server / CDN involvement.

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Ecto schema shape + changesets | API / Backend | Database (column types + defaults) | Schemas are Elixir data structures; column types are enforced at the Postgres side via D-15 (no DB lifecycle CHECK) + D-11 (changeset requires `:scope`) |
| SQLSTATE 45A01 immutability trigger | Database | API / Backend (translates error) | Trigger is plpgsql in Postgres; `Mailglass.Repo.transact/1` translates `Postgrex.Error` → `EventLedgerImmutableError` (D-06) |
| `(provider, provider_message_id)` UNIQUE | Database | — | Index prevents MAIL-09 at write time; no app-level check needed |
| Idempotency `idempotency_key` UNIQUE partial | Database | API / Backend (conflict handling) | Index enforces uniqueness; `on_conflict: :nothing` + `id: nil` detection handles replays (D-03) |
| Monotonic projection updates | API / Backend | — | D-15 explicitly rejects DB CHECK constraints for lifecycle ordering; `Mailglass.Outbound.Projector` is the single enforcement module |
| Tenant scoping | API / Backend | Database (`tenant_id` column as WHERE clause target) | `Mailglass.Tenancy.scope/2` injects WHERE filters; Phase 6 `NoUnscopedTenantQueryInLib` enforces at lint time |
| Process-dict tenant context | API / Backend | — | `put_current/1` + `current/0` are pure module functions reading `Process.get/2`; no process involved |
| Oban tenancy middleware | API / Backend (optional-dep gateway) | — | Lives behind `Mailglass.OptionalDeps.Oban` gate; only loaded when `:oban` is present |
| Orphan reconciliation query functions | API / Backend | Database (partial index on `needs_reconciliation`) | Pure Ecto queries in Phase 2; Oban worker in Phase 4 |
| StreamData property test | API / Backend (test tier) | Database (test sandbox) | Property tests run against the real Ecto sandbox with the real trigger — no mock DDL (D-37) |

**Why this matters:** Phase 2 has a single tier (backend), but the DDL vs app-enforced split is load-bearing — D-15 explicitly rejects putting lifecycle-ordering CHECK constraints at the DB tier because webhook event ordering is non-monotonic in practice. The planner must preserve this split: no temptation to "just add a CHECK constraint for belt-and-suspenders" — it would break on real SendGrid / Postmark payloads where `:opened` arrives before `:delivered`.

## Standard Stack

### Core (all already present at Phase 1 close per STACK.md §1.1)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `ecto_sql` | `~> 3.13` (3.13.5) | `use Ecto.Schema`, `cast`, `validate_required`, `optimistic_lock`, `Ecto.Multi`, `Repo.transact/2` | Phase 1 already present; Ecto 3.13 is the floor per D-06. `transact/2` (not `transaction/1`) per Phase 1 STATE decision |
| `ecto` | `~> 3.13` (3.13.5) | `Ecto.Enum`, `Ecto.Changeset`, `Ecto.Query` | Transitive via ecto_sql; required for `Ecto.Enum` per D-10 |
| `postgrex` | `~> 0.22` (0.22.0) | DB driver; `%Postgrex.Error{postgres: %{pg_code: "45A01"}}` for D-06 | Phase 1 present; UUID binary support for UUIDv7 |
| `nimble_options` | `~> 1.1` (1.1.1) | `Mailglass.Config` schema extension for `:tenancy` + `:suppression_store` | Already present |
| `telemetry` | `~> 1.4` (1.4.1) | `persist_span/3`, `events_append_span/3` | Already present |

### New required dep (adds to `mix.exs` in Phase 2)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `uuidv7` | `~> 1.0` (1.0.0) | Time-ordered UUID PKs on all three schemas per D-25 | [VERIFIED: Hex.pm API 2026-04-22 — `uuidv7 1.0.0` released 2024-09-12, current stable]. Small pure-Elixir `Ecto.Type` implementation. Postgres 18 upgrade path is free per D-27 (`default: fragment("uuidv7()")`). |

**Version verification (mandatory step):**
```bash
mix hex.info uuidv7
# Expected: latest 1.0.0 (released 2024-09-12)
```

**Installation (in Phase 2 Plan 1):**
```bash
# mix.exs — add to deps/0 under the "Core (required)" block
{:uuidv7, "~> 1.0"},
# Then:
mix deps.get
```

### Supporting (test + dev)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `stream_data` | `~> 1.3` (1.3.0) | Property test for D-16 monotonicity + PERSIST-03 idempotency convergence | Already present in `only: [:test]`; the Phase 2 property test harness is new |
| `ex_unit` | stdlib | Sandbox, async, `assert_raise` | Phase 2 tests need `Ecto.Adapters.SQL.Sandbox` for DB-backed test isolation |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `uuidv7` (~1.0 pure-Elixir) | `uniq` or `elixir_uuid` | UUIDv7 is now the standard (RFC 9562 ratified May 2024); `uniq` supports v7 but adds more surface area; `elixir_uuid` doesn't support v7. Pick the narrow, single-purpose dep. |
| Hand-written `@type t` per D-22 | `typed_ecto_schema 0.4.3` | D-23 rejects `typed_ecto_schema` because Elixir 1.19's native typed-struct roadmap makes it transitional. [VERIFIED: Hex.pm 2026-04-22 — typed_ecto_schema 0.4.3 last released 2025-06-25, cadence slowing.] `~45 LOC` of hand-written typespecs is cheap vs. the future migration cost. |
| App-enforced monotonic projections per D-15 | DB CHECK constraint on lifecycle ordering | Anymail event ordering is non-monotonic in practice (`:opened` before `:delivered`); CHECK would break on real payloads. Phase 6 `Mailglass.Credo.NoProjectorOutsideOutbound` enforces at lint time instead. |
| Oban-pattern `Mailglass.Migrations.Postgres.V01` per D-35 | Copy-a-template from `priv/templates/` at install time | Oban-pattern means `mix mailglass.gen.migration` produces an 8-line wrapper that stays stable across versions; template-copy approach churns the adopter's migration file on every mailglass version bump. |
| UUIDv7 PK on `mailglass_events` per D-26 | `bigserial` (accrue precedent) | Non-enumerability for admin LiveView URLs (IDOR liability) + future shardability. UUIDv7 recovers ~70% of the bigserial insert-speed gap (1.6× vs 9.5× for UUIDv4); acceptable for transactional email throughput. |

## Architecture Patterns

### System Architecture Diagram

```
                                  Phase 2 Architecture
                                  ====================

 ADOPTER HOST APP                         MAILGLASS LIBRARY                          POSTGRES
 ================                         ==================                         ========

 MyApp.MailContext                        Mailglass.Outbound (Phase 3)
      │                                        │
      │  .send(mailable, opts)                 │  .persist(%Message{}, ctx)
      │  (Phase 3)                             ▼
      │                                  Mailglass.Tenancy.scope/2 ─────────────┐
      │                                  (reads Process.get(:mailglass_tenant)) │
      │                                        │                                │
      │                                        ▼                                │
      │                                  Ecto.Multi.new()                       │
      │                                    |> Multi.insert(:delivery, ...)      │
      │                                    |> Events.append_multi(:event, ...)  │
      │                                    |> Mailglass.Repo.transact()         │
      │                                        │                                │
      │                                        ▼                                │
      │                                  Mailglass.Repo.transact/1              │
      │                                  ├─ pg_code 45A01? ──→ reraise          │
      │                                  │    EventLedgerImmutableError         │
      │                                  └─ otherwise pass through              │
      │                                        │                                │
      │                                        ▼                                │
      ▼                                  HostRepo.transaction ───────────────→  │
 MyApp.Repo.transact                                                            ▼
                                                                         mailglass_deliveries
                                                                         mailglass_events       ◄── BEFORE UPDATE|DELETE
                                                                         mailglass_suppressions     trigger raises 45A01


 MyApp.UserAuth.on_mount                  Mailglass.Tenancy.put_current/1           (no DB I/O)
      │                                   (writes Process.put(:mailglass_tenant))
      │  scope.organization.id                 │
      └──────────────────────────────────────▶ ▼
                                          Process dictionary stamp
                                          lives for the LiveView/request
                                          process lifetime


 PROVIDER WEBHOOK (Phase 4)               Mailglass.Events.Reconciler              mailglass_events
      │                                   .find_orphans/1                          WHERE needs_reconciliation
      │  (orphan: delivery_id = nil,      .attempt_link/2                          = true
      │   needs_reconciliation = true)    (pure queries; Phase 4
      │                                    wraps in an Oban worker
      │                                    at {:cron, "*/15 * * * *"})
      │                                        │
      └────────────────────────────────────────┘


                                 StreamData property test
                                 ========================
                                 check all events <- list_of(event_generator(), max: 20),
                                           replays <- integer(1..10) do
                                   fresh    = apply_all(events)
                                   replayed = apply_all(
                                     List.duplicate(events, replays)
                                     |> List.flatten()
                                     |> Enum.shuffle())
                                   assert projection(fresh) == projection(replayed)
                                 end
```

### Recommended Project Structure

```
lib/mailglass/
├── events.ex                          # NEW: append/1 + append_multi/3 (D-01)
├── events/
│   ├── event.ex                       # NEW: Ecto schema for mailglass_events
│   └── reconciler.ex                  # NEW: find_orphans/1 + attempt_link/2 (D-19)
├── migration.ex                       # NEW: public API up/0 + down/0 + up(version:) (D-35)
├── migrations/
│   └── postgres.ex                    # NEW: version dispatcher via pg_class comment (D-35)
├── migrations/postgres/
│   └── v01.ex                         # NEW: Phase 2 DDL (3 tables + trigger + indexes)
├── outbound/
│   ├── delivery.ex                    # NEW: Ecto schema for mailglass_deliveries
│   └── projector.ex                   # NEW: update_projections/2 (D-14)
├── suppression/
│   └── entry.ex                       # NEW: Ecto schema for mailglass_suppressions
├── suppression_store.ex               # NEW: behaviour (check/2 + record/1 at minimum)
├── suppression_store/
│   └── ecto.ex                        # NEW: default Ecto-backed impl
├── tenancy.ex                         # NEW: behaviour + process-dict helpers (D-29, D-30)
├── tenancy/
│   └── single_tenant.ex               # NEW: no-op default (D-31)
├── schema.ex                          # NEW: use Mailglass.Schema DRY macro (D-28)
├── errors/
│   └── event_ledger_immutable_error.ex  # NEW: defexception (D-06)
├── oban/
│   └── tenancy_middleware.ex          # NEW: under OptionalDeps.Oban gateway (D-33)
├── repo.ex                            # PATCH: activate SQLSTATE 45A01 translation (D-06)
├── config.ex                          # PATCH: add :tenancy + :suppression_store options
└── errors/
    └── suppressed_error.ex            # PATCH: @types atom set (:tenant_address → :address_stream per D-09)

priv/repo/migrations/
└── 00000000000001_mailglass_init.exs  # NEW: synthetic test migration calling Mailglass.Migration.up/0 (D-37)

test/support/
├── test_repo.ex                       # NEW: mailglass's own test Repo (D-37)
├── data_case.ex                       # NEW: ExUnit case with sandbox checkout + tenant stamp helpers
└── generators.ex                      # NEW: StreamData generators for Delivery/Event/Suppression

test/mailglass/
├── events_test.exs                    # NEW: append + append_multi + idempotency
├── events/event_test.exs              # NEW: changeset validation
├── events/reconciler_test.exs         # NEW: find_orphans + attempt_link
├── outbound/delivery_test.exs         # NEW: changeset + optimistic_lock
├── outbound/projector_test.exs        # NEW: monotonic update rule
├── suppression/entry_test.exs         # NEW: changeset + scope enum
├── suppression_store/ecto_test.exs    # NEW: check + record
├── tenancy_test.exs                   # NEW: scope/2 + process-dict helpers
├── migration_test.exs                 # NEW: up/0 + down/0 idempotency
└── properties/
    ├── idempotency_convergence_test.exs    # NEW: PERSIST-03 + MAIL-03 property (D-16)
    └── tenant_isolation_test.exs           # NEW: TENANT-01 cross-tenant leak property (partial)

mix.exs (patch)                        # PATCH: add {:uuidv7, "~> 1.0"} to deps/0

config/test.exs (patch)                # PATCH: config :mailglass, repo: Mailglass.TestRepo
                                       #        config :mailglass, tenancy: Mailglass.Tenancy.SingleTenant

test/test_helper.exs (patch)           # PATCH: Ecto.Adapters.SQL.Sandbox.mode + run Mailglass.Migration.up/0
```

**File count projection:** ~25 new `.ex` files + ~12 test files + 5 patches. Plan granularity suggestion: 5-6 plans.

### Pattern 1: Append-only ledger with dual writer API (D-01, D-02, D-05)

**What:** Two public entry points sharing the same changeset + conflict-handling semantics. `append/1` wraps `Repo.transact/1`; `append_multi/3` appends to an `Ecto.Multi` the caller already owns.

**When to use:** Every write to `mailglass_events`. No exceptions; Phase 6 `NoRawEventInsert` Credo check enforces.

**Example:**
```elixir
# Source: accrue/lib/accrue/events.ex verbatim structure + D-01..D-06 naming
defmodule Mailglass.Events do
  alias Mailglass.Events.Event
  alias Mailglass.Tenancy

  import Ecto.Query

  @type attrs :: %{
          optional(:type) => atom() | String.t(),
          optional(:delivery_id) => Ecto.UUID.t() | nil,
          optional(:occurred_at) => DateTime.t(),
          optional(:idempotency_key) => String.t() | nil,
          optional(:raw_payload) => map(),
          optional(:normalized_payload) => map(),
          optional(:reject_reason) => atom() | nil,
          optional(:tenant_id) => String.t(),
          optional(:trace_id) => String.t() | nil,
          optional(:needs_reconciliation) => boolean()
        }

  @spec append(attrs()) :: {:ok, Event.t()} | {:error, term()}
  def append(attrs) when is_map(attrs) do
    Mailglass.Telemetry.events_append_span(
      %{tenant_id: tenant_id_from(attrs), idempotency_key_present?: has_key?(attrs)},
      fn ->
        normalized = normalize(attrs)
        changeset = Event.changeset(normalized)
        Mailglass.Repo.transact(fn -> do_insert(changeset, normalized) end)
      end
    )
  end

  @spec append_multi(Ecto.Multi.t(), atom(), attrs()) :: Ecto.Multi.t()
  def append_multi(multi, name, attrs) when is_atom(name) and is_map(attrs) do
    normalized = normalize(attrs)
    changeset = Event.changeset(normalized)
    Ecto.Multi.insert(multi, name, changeset, insert_opts(normalized))
  end

  # D-03: partial-unique conflict target requires the WHERE clause in an :unsafe_fragment
  defp insert_opts(%{idempotency_key: key}) when is_binary(key) do
    [
      on_conflict: :nothing,
      conflict_target: {:unsafe_fragment, "(idempotency_key) WHERE idempotency_key IS NOT NULL"},
      returning: true
    ]
  end
  defp insert_opts(_), do: [returning: true]

  # D-05: auto-capture tenant + trace_id via process dict
  defp normalize(attrs) do
    attrs
    |> Map.new()
    |> Map.put_new(:tenant_id, Tenancy.current())
    |> Map.put_new(:trace_id, current_trace_id())
    |> Map.put_new(:occurred_at, DateTime.utc_now())
    |> Map.put_new(:normalized_payload, %{})
  end

  defp current_trace_id do
    # Optional OTel integration; nil-tolerant
    if Code.ensure_loaded?(:otel_propagator_text_map) do
      case :otel_propagator_text_map.current() do
        {:trace_id, id} -> id
        _ -> nil
      end
    end
  end

  # D-03: detect id: nil replay + manual fetch
  defp do_insert(changeset, %{idempotency_key: key} = attrs) when is_binary(key) do
    case Mailglass.Repo.insert(changeset, insert_opts(attrs)) do
      {:ok, %Event{id: nil}} -> fetch_by_idempotency_key(key)
      {:ok, %Event{} = event} -> {:ok, event}
      {:error, _} = err -> err
    end
  end
  defp do_insert(changeset, _attrs), do: Mailglass.Repo.insert(changeset, insert_opts(_attrs))

  defp fetch_by_idempotency_key(key) do
    query = from(e in Event, where: e.idempotency_key == ^key, limit: 1)
    case Mailglass.Repo.one(query) do
      nil -> {:error, :idempotency_lookup_failed}
      event -> {:ok, event}
    end
  end
end
```

### Pattern 2: Process-dict tenancy with Plug-style stamping (D-29, D-30, D-31)

**What:** Behaviour with a single callback `scope/2` plus non-callback helpers (`current/0`, `put_current/1`, `with_tenant/2`) on the `Mailglass.Tenancy` module. Default `SingleTenant` resolver is a no-op.

**When to use:** Every query on a tenanted schema passes through `Mailglass.Tenancy.scope(query, tenant_id)`. Adopters stamp `tenant_id` in their auth `on_mount/4` callback.

**Example:**
```elixir
# Source: accrue/lib/accrue/actor.ex pattern + D-29..D-32 semantics
defmodule Mailglass.Tenancy do
  @callback scope(queryable :: Ecto.Queryable.t(), context :: term()) :: Ecto.Queryable.t()

  @process_dict_key :mailglass_tenant_id

  @spec current() :: String.t()
  def current do
    Process.get(@process_dict_key) || default_tenant()
  end

  @spec put_current(String.t()) :: String.t() | nil
  def put_current(tenant_id) when is_binary(tenant_id) do
    Process.put(@process_dict_key, tenant_id)
  end

  @spec with_tenant(String.t(), (-> any())) :: any()
  def with_tenant(tenant_id, fun) when is_binary(tenant_id) and is_function(fun, 0) do
    prior = Process.get(@process_dict_key)
    Process.put(@process_dict_key, tenant_id)
    try do
      fun.()
    after
      if prior, do: Process.put(@process_dict_key, prior), else: Process.delete(@process_dict_key)
    end
  end

  @spec tenant_id!() :: String.t()
  def tenant_id! do
    Process.get(@process_dict_key) ||
      raise Mailglass.TenancyError,
            "No tenant stamped. Call Mailglass.Tenancy.put_current/1 in your on_mount/4."
  end

  @spec scope(Ecto.Queryable.t(), term()) :: Ecto.Queryable.t()
  def scope(query, context \\ current()) do
    resolver = Mailglass.Config.tenancy()
    resolver.scope(query, context)
  end

  defp default_tenant do
    case Mailglass.Config.tenancy() do
      Mailglass.Tenancy.SingleTenant -> "default"
      _ -> nil
    end
  end
end

defmodule Mailglass.Tenancy.SingleTenant do
  @behaviour Mailglass.Tenancy

  @impl true
  def scope(query, _context), do: query  # no-op
end
```

### Pattern 3: Oban-style migration dispatcher (D-35, D-36)

**What:** `Mailglass.Migration` is the public API adopters call; `Mailglass.Migrations.Postgres` tracks current version via `pg_class` comment; `Mailglass.Migrations.Postgres.V01` holds Phase 2's DDL.

**When to use:** The one place the adopter's migration file calls into mailglass.

**Example:**
```elixir
# Source: deps/oban/lib/oban/migration.ex pattern verbatim + D-35
defmodule Mailglass.Migration do
  def up(opts \\ []), do: Mailglass.Migrations.Postgres.up(opts)
  def down(opts \\ []), do: Mailglass.Migrations.Postgres.down(opts)
end

defmodule Mailglass.Migrations.Postgres do
  @moduledoc false
  use Ecto.Migration

  @initial_version 1
  @current_version 1

  def up(opts \\ []) do
    opts = Keyword.merge([prefix: nil, version: @current_version], opts)
    target = opts[:version]
    current = current_version()

    for v <- (current + 1)..target do
      module = Module.concat(__MODULE__, "V0#{v}")
      module.up(opts)
    end

    set_version(target)
  end

  def down(opts \\ []) do
    opts = Keyword.merge([prefix: nil, version: @current_version - 1], opts)
    target = opts[:version]
    current = current_version()

    for v <- current..(target + 1)//-1 do
      module = Module.concat(__MODULE__, "V0#{v}")
      module.down(opts)
    end

    set_version(target)
  end

  # Track version via pg_class comment — no new tables needed
  defp current_version do
    case repo().query("SELECT obj_description('mailglass_events'::regclass, 'pg_class')") do
      {:ok, %{rows: [[comment]]}} when is_binary(comment) ->
        case Integer.parse(comment) do
          {v, _} -> v
          _ -> @initial_version - 1
        end
      _ -> @initial_version - 1
    end
  end

  defp set_version(v) do
    execute("COMMENT ON TABLE mailglass_events IS '#{v}'")
  end
end

defmodule Mailglass.Migrations.Postgres.V01 do
  @moduledoc false
  use Ecto.Migration

  def up(_opts) do
    # See §Schema & DDL below for full DDL body.
    # ...
  end

  def down(_opts), do: # drop in reverse order
end
```

Adopter's migration file (what `mix mailglass.gen.migration` produces per D-36):
```elixir
defmodule MyApp.Repo.Migrations.AddMailglass do
  use Ecto.Migration
  def up, do: Mailglass.Migration.up()
  def down, do: Mailglass.Migration.down()
end
```

### Pattern 4: Monotonic projector (D-14, D-15)

**What:** One module, `Mailglass.Outbound.Projector`, owns projection-column updates. Rule: only set fields to "later" values; never overwrite a non-nil timestamp.

**When to use:** Dispatch (Phase 3), webhook ingest (Phase 4), orphan reconciliation (Phase 4).

**Example:**
```elixir
# Source: D-14 + D-15 verbatim + ARCHITECTURE §4.2 projection semantics
defmodule Mailglass.Outbound.Projector do
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Events.Event

  @terminal_event_types ~w[delivered bounced complained rejected failed suppressed]a

  @spec update_projections(Delivery.t(), Event.t()) :: Ecto.Changeset.t()
  def update_projections(%Delivery{} = delivery, %Event{} = event) do
    delivery
    |> Ecto.Changeset.change()
    |> maybe_set_later(:last_event_type, to_string(event.type))
    |> maybe_set_later(:last_event_at, event.occurred_at, delivery.last_event_at)
    |> maybe_set_once(timestamp_field_for(event.type), event.occurred_at)
    |> maybe_flip_terminal(event.type)
    |> Ecto.Changeset.optimistic_lock(:lock_version)  # D-18
  end

  defp timestamp_field_for(:dispatched), do: :dispatched_at
  defp timestamp_field_for(:delivered), do: :delivered_at
  defp timestamp_field_for(:bounced), do: :bounced_at
  defp timestamp_field_for(:complained), do: :complained_at
  defp timestamp_field_for(:suppressed), do: :suppressed_at
  defp timestamp_field_for(_), do: nil

  defp maybe_set_later(changeset, _field, nil, _current), do: changeset
  defp maybe_set_later(changeset, field, new_val, nil), do: Ecto.Changeset.put_change(changeset, field, new_val)
  defp maybe_set_later(changeset, field, new_val, current) do
    if DateTime.compare(new_val, current) == :gt do
      Ecto.Changeset.put_change(changeset, field, new_val)
    else
      changeset
    end
  end

  defp maybe_set_once(changeset, nil, _), do: changeset
  defp maybe_set_once(changeset, field, value) do
    case Ecto.Changeset.get_field(changeset, field) do
      nil -> Ecto.Changeset.put_change(changeset, field, value)
      _existing -> changeset  # monotonic: never overwrite
    end
  end

  defp maybe_flip_terminal(changeset, event_type) when event_type in @terminal_event_types do
    case Ecto.Changeset.get_field(changeset, :terminal) do
      false -> Ecto.Changeset.put_change(changeset, :terminal, true)
      true -> changeset  # never flips back
    end
  end
  defp maybe_flip_terminal(changeset, _), do: changeset
end
```

### Anti-Patterns to Avoid

- **DB CHECK constraint on lifecycle ordering:** D-15 rejects. Provider event ordering is non-monotonic; CHECK breaks on `:opened` before `:delivered`. Use the app-level projector + Phase 6 Credo check instead.
- **FK from `mailglass_events.delivery_id` → `mailglass_deliveries.id`:** ARCHITECTURE §4.3 explicitly rejects. Orphan webhooks require `delivery_id = nil`; FK would prevent. Keep the relationship logical but not physically enforced.
- **Pattern-match SQLSTATE on error message string:** D-06 forbids. Use `%Postgrex.Error{postgres: %{pg_code: "45A01"}}` only.
- **Hand-rolled runtime check "are you in a Multi?":** PERSIST-05 original wording suggested `raise ArgumentError`. D-02 supersedes — lint-time `NoRawEventInsert` Phase 6 check is the enforcement surface; runtime checks would add cost to every `append/1` call and fail-closed in valid standalone-audit scenarios.
- **Single unified Tenancy behaviour with 3 callbacks:** D-29 explicitly narrows to one `scope/2` callback. Avoid the `current_scope/1 + tenant_id/1 + scope_query/2` trio from ARCHITECTURE §1.1 — it couples core to Phoenix `%Scope{}` shape.
- **`name: __MODULE__` singleton GenServer for Tenancy process dict:** Phase 1 D-27 / D-28 and LINT-07 enforce. Tenancy is a pure module with process-dict helpers; no GenServer.
- **`Application.compile_env!` for `:tenancy` or `:suppression_store`:** LIB-07 / LINT-08 enforce. Only `Mailglass.Config` uses `compile_env`, and it uses `get_env/2` for runtime values.
- **Using `Application.get_env(:mailglass, :repo)` inside Phase 2 code:** route every DB call through `Mailglass.Repo.transact/1` or `Mailglass.Repo.insert/2` (extended in Phase 2 if needed) — the facade is the seam.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Monotonic timestamp UUIDs | Custom UUID v7 Ecto.Type | `{:uuidv7, "~> 1.0"}` | Battle-tested RFC 9562 impl; 61 lines of pure Elixir; Ecto.Type in-box |
| Append-only ledger with replay safety | Custom `unique_violation` rescue + retry loop | `on_conflict: :nothing, conflict_target: {:unsafe_fragment, ...}, returning: true` + `id: nil` detection | D-03 locks this; accrue's 4-of-4 proven pattern; covered by Ecto issues #3132, #3910, #2694 |
| Postgres migration version tracking | `schema_migrations` table modification | `COMMENT ON TABLE mailglass_events IS '<v>'` | Oban pattern; no new tables; `pg_class` comment is durable, queryable, adopter-invisible |
| Process-dict tenancy stamping | ETS-backed tenant registry / GenServer | `Process.put/2` + `Process.get/2` | Accrue 4-of-4 convergence; request-scope lifetime; zero concurrency primitives needed |
| SQLSTATE trigger in plpgsql | Custom `RuleError` subclass + post-insert check | `CREATE TRIGGER ... BEFORE UPDATE OR DELETE` raising SQLSTATE 45A01 | Postgres-enforced, cannot be bypassed from Elixir; trigger is ~6 lines of plpgsql |
| Orphan-webhook reconciliation worker | Nightly cron script | Phase 2 ships `Mailglass.Events.Reconciler.find_orphans/1` + `attempt_link/2` as pure queries; Phase 4 wraps in Oban (D-19, D-20) | Keeps Phase 2 dep-free of Oban; Phase 4 is where Oban enters the code |
| Optimistic locking for dispatch race | Version + retry loop | `Ecto.Changeset.optimistic_lock(:lock_version)` + rescue `Ecto.StaleEntryError` | Ecto built-in; D-18 ships `lock_version integer NOT NULL DEFAULT 1` now |
| Ecto enum with validation | `validate_inclusion/3` on string field | `Ecto.Enum` type per D-10 | 3.13+ idiom; auto string↔atom coercion; raises on unknown at load time |
| StreamData convergence test | Hand-rolled replay loop | `check all events <- ..., replays <- ...` property | StreamData is already in deps; D-16 locks the shape |

**Key insight:** Phase 2 is almost entirely "use the battle-tested pattern verbatim" — accrue's `events.ex` is the architectural template for `Mailglass.Events`, Oban's `migration.ex` is the template for `Mailglass.Migration`, and Postgres's built-in trigger mechanism is the immutability enforcement. The only novel code is (a) sibling-schema bookkeeping (three tables not one), (b) the `Mailglass.Outbound.Projector` monotonic update rule per D-15, (c) the tenancy behaviour adapted for email-infra (tenant is actor), and (d) the `Mailglass.Events.Reconciler` pure-query orphan lookup. Every other module has a 4-of-4 convergent precedent.

## Schema & DDL

### §1 `mailglass_deliveries` DDL (PERSIST-01, MAIL-09 prevention)

```sql
CREATE TABLE mailglass_deliveries (
  id                    UUID           PRIMARY KEY,
  tenant_id             TEXT           NOT NULL,                          -- D-40
  mailable              TEXT           NOT NULL,                          -- "MyApp.UserMailer.welcome/1"
  stream                TEXT           NOT NULL,                          -- Ecto.Enum: :transactional|:operational|:bulk (D-10)
  recipient             TEXT           NOT NULL,                          -- normalized lowercased
  recipient_domain      TEXT           NOT NULL,                          -- denormalized for rate-limit + analytics

  provider              TEXT,                                             -- :postmark|:sendgrid|nil (populated post-dispatch)
  provider_message_id   TEXT,                                             -- provider's ID post-dispatch

  -- Projected summary fields (D-13 — all 8 ship v0.1)
  last_event_type       TEXT           NOT NULL,                          -- Ecto.Enum: Anymail taxonomy; 'queued' on insert
  last_event_at         TIMESTAMPTZ    NOT NULL,                          -- utc_datetime_usec (D-41)
  terminal              BOOLEAN        NOT NULL DEFAULT false,
  dispatched_at         TIMESTAMPTZ,                                      -- utc_datetime_usec nullable
  delivered_at          TIMESTAMPTZ,
  bounced_at            TIMESTAMPTZ,
  complained_at         TIMESTAMPTZ,
  suppressed_at         TIMESTAMPTZ,

  metadata              JSONB          NOT NULL DEFAULT '{}'::jsonb,      -- D-17
  lock_version          INTEGER        NOT NULL DEFAULT 1,                -- D-18

  inserted_at           TIMESTAMPTZ    NOT NULL,                          -- utc_datetime_usec
  updated_at            TIMESTAMPTZ    NOT NULL
);

-- Hot lookup: webhook → delivery (MAIL-09 prevention per PERSIST-01)
CREATE UNIQUE INDEX mailglass_deliveries_provider_msg_id_idx
  ON mailglass_deliveries (provider, provider_message_id)
  WHERE provider_message_id IS NOT NULL;

-- Admin: list deliveries by tenant + recent
CREATE INDEX mailglass_deliveries_tenant_recent_idx
  ON mailglass_deliveries (tenant_id, last_event_at DESC);

-- Admin: search by recipient
CREATE INDEX mailglass_deliveries_tenant_recipient_idx
  ON mailglass_deliveries (tenant_id, recipient);

-- Filter by stream + status
CREATE INDEX mailglass_deliveries_tenant_stream_terminal_idx
  ON mailglass_deliveries (tenant_id, stream, terminal, last_event_at DESC);
```

### §2 `mailglass_events` DDL + immutability trigger (PERSIST-02, TS-06, D-15)

```sql
CREATE TABLE mailglass_events (
  id                    UUID           PRIMARY KEY,
  tenant_id             TEXT           NOT NULL,                          -- D-40
  delivery_id           UUID,                                             -- nullable: orphan webhooks (no FK per ARCHITECTURE §4.3)
  type                  TEXT           NOT NULL,                          -- Ecto.Enum: Anymail taxonomy (D-14 project-level)
  occurred_at           TIMESTAMPTZ    NOT NULL,                          -- utc_datetime_usec (D-42: provider time, advisory)
  idempotency_key       TEXT,                                             -- "postmark:webhook:abc123"
  reject_reason         TEXT,                                             -- Ecto.Enum: :invalid|:bounced|...|nil (D-14)
  raw_payload           JSONB,                                            -- full provider payload for replay (webhook only)
  normalized_payload    JSONB          NOT NULL DEFAULT '{}'::jsonb,
  metadata              JSONB          NOT NULL DEFAULT '{}'::jsonb,      -- D-17
  trace_id              TEXT,                                             -- D-05 optional OTel
  needs_reconciliation  BOOLEAN        NOT NULL DEFAULT false,            -- D-19
  inserted_at           TIMESTAMPTZ    NOT NULL                           -- utc_datetime_usec; this (not occurred_at) orders the ledger (D-42)
);

-- Idempotency: replay-safe webhooks (MAIL-03 prevention per PERSIST-03)
CREATE UNIQUE INDEX mailglass_events_idempotency_key_idx
  ON mailglass_events (idempotency_key)
  WHERE idempotency_key IS NOT NULL;

-- Hot read: timeline for one delivery
CREATE INDEX mailglass_events_delivery_idx
  ON mailglass_events (delivery_id, occurred_at)
  WHERE delivery_id IS NOT NULL;

-- Tenant firehose for admin
CREATE INDEX mailglass_events_tenant_recent_idx
  ON mailglass_events (tenant_id, inserted_at DESC);

-- Reconciliation worker (D-19)
CREATE INDEX mailglass_events_needs_reconcile_idx
  ON mailglass_events (tenant_id, inserted_at)
  WHERE needs_reconciliation = true;

-- ❶ The immutability function — pattern verbatim from accrue/priv/repo/migrations/20260411000001_create_accrue_events.exs
CREATE OR REPLACE FUNCTION mailglass_raise_immutability()
RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  RAISE SQLSTATE '45A01'
    USING MESSAGE = 'mailglass_events is append-only; UPDATE and DELETE are forbidden';
END;
$$;

-- ❷ The trigger (PROJECT.md D-15)
CREATE TRIGGER mailglass_events_immutable_trigger
  BEFORE UPDATE OR DELETE ON mailglass_events
  FOR EACH ROW EXECUTE FUNCTION mailglass_raise_immutability();

-- ❸ Version-tracking pg_class comment (D-35 Oban pattern)
COMMENT ON TABLE mailglass_events IS '1';
```

**SQLSTATE code choice — `45A01`:** The `45` class is Postgres user-defined (legal range `45000..45ZZZ`). Accrue uses `45A01`; mailglass adopts the same code for consistency. `A` encodes "custom/app-level"; `01` identifies "ledger immutability violation." Downstream (Phase 6+ custom domain errors) can use `45A02`, `45A03`, etc. if new invariants need SQL-level enforcement.

### §3 `mailglass_suppressions` DDL (PERSIST-04, MAIL-07 prevention, D-07..D-12)

```sql
CREATE EXTENSION IF NOT EXISTS citext;  -- for case-insensitive address match

CREATE TABLE mailglass_suppressions (
  id                    UUID           PRIMARY KEY,
  tenant_id             TEXT           NOT NULL,                          -- D-40
  address               CITEXT         NOT NULL,                          -- normalized lowercase via case-insensitive type
  scope                 TEXT           NOT NULL,                          -- Ecto.Enum: :address|:domain|:address_stream (D-10)
  stream                TEXT,                                             -- Ecto.Enum: :transactional|:operational|:bulk (D-10) — populated only when scope=:address_stream (D-07)
  reason                TEXT           NOT NULL,                          -- Ecto.Enum: :hard_bounce|:complaint|:unsubscribe|:manual|:policy|:invalid_recipient (D-10)
  source                TEXT           NOT NULL,                          -- "webhook:postmark" | "admin:user_id=..." | "auto" (Claude's discretion)
  expires_at            TIMESTAMPTZ,                                      -- utc_datetime_usec nullable; permanent if NULL
  metadata              JSONB          NOT NULL DEFAULT '{}'::jsonb,      -- D-17
  inserted_at           TIMESTAMPTZ    NOT NULL
);

-- Hot pre-send check (the dominant query) — UNIQUE per D-07 spec + PERSIST-04
CREATE UNIQUE INDEX mailglass_suppressions_tenant_address_scope_idx
  ON mailglass_suppressions (tenant_id, address, scope, COALESCE(stream, ''));

-- Admin: address-scoped lookup (supports OR-union pre-send query — see §specifics CONTEXT.md)
CREATE INDEX mailglass_suppressions_tenant_address_idx
  ON mailglass_suppressions (tenant_id, address);

-- Expiry sweeper (v0.5 reclamation job)
CREATE INDEX mailglass_suppressions_expires_idx
  ON mailglass_suppressions (expires_at)
  WHERE expires_at IS NOT NULL;
```

**CHECK constraint for scope/stream coupling:** The `stream` column must be `NOT NULL` when `scope = :address_stream` and `NULL` otherwise. This IS a real invariant (not lifecycle ordering per D-15), so a CHECK constraint is appropriate here:

```sql
ALTER TABLE mailglass_suppressions
  ADD CONSTRAINT mailglass_suppressions_stream_scope_check
  CHECK (
    (scope = 'address_stream' AND stream IS NOT NULL) OR
    (scope IN ('address', 'domain') AND stream IS NULL)
  );
```

**Why CHECK here but not on lifecycle:** stream/scope coupling is structural (the shape of a valid row), not temporal (the order rows must arrive in). D-15's rejection of CHECK is specifically for lifecycle ordering; structural CHECKs remain a best practice.

## Migration Strategy

### §1 Migration delivery per D-35..D-39

**File layout:**
```
lib/mailglass/migration.ex                       # public API: up/0, down/0, up(version:), down(version:)
lib/mailglass/migrations/postgres.ex             # version dispatcher (pg_class comment)
lib/mailglass/migrations/postgres/v01.ex         # Phase 2 DDL (the SQL from §Schema & DDL above translated to Ecto.Migration)

# Adopter's migration file (what `mix mailglass.gen.migration` emits — 8 lines stable across versions)
priv/repo/migrations/<timestamp>_add_mailglass.exs:
  defmodule MyApp.Repo.Migrations.AddMailglass do
    use Ecto.Migration
    def up, do: Mailglass.Migration.up()
    def down, do: Mailglass.Migration.down()
  end

# Synthetic test migration (D-37) — runs the exact same code path as adopters get
priv/repo/migrations/00000000000001_mailglass_init.exs:
  defmodule Mailglass.TestRepo.Migrations.MailglassInit do
    use Ecto.Migration
    def up, do: Mailglass.Migration.up()
    def down, do: Mailglass.Migration.down()
  end
```

**Postgres-only assumptions (load-bearing):**
- `CREATE EXTENSION IF NOT EXISTS citext` — used in `mailglass_suppressions.address` column
- `JSONB` — used in `metadata`, `raw_payload`, `normalized_payload`
- Partial UNIQUE indexes (`WHERE ...`) — PERSIST-03 idempotency, PERSIST-01 provider_message_id
- `BEFORE UPDATE OR DELETE` triggers raising SQLSTATE — D-15 immutability
- `COMMENT ON TABLE` — D-35 version tracking

Per PROJECT.md: Postgres-only at v0.1. MySQL/SQLite explicitly out.

### §2 Ecto.Migration translation of the V01 DDL

```elixir
defmodule Mailglass.Migrations.Postgres.V01 do
  @moduledoc false
  use Ecto.Migration

  def up(opts \\ []) do
    prefix = opts[:prefix]

    execute "CREATE EXTENSION IF NOT EXISTS citext"

    create table(:mailglass_deliveries, primary_key: false, prefix: prefix) do
      add :id, :uuid, primary_key: true
      add :tenant_id, :text, null: false
      add :mailable, :text, null: false
      add :stream, :text, null: false
      add :recipient, :text, null: false
      add :recipient_domain, :text, null: false
      add :provider, :text
      add :provider_message_id, :text
      add :last_event_type, :text, null: false
      add :last_event_at, :utc_datetime_usec, null: false
      add :terminal, :boolean, null: false, default: false
      add :dispatched_at, :utc_datetime_usec
      add :delivered_at, :utc_datetime_usec
      add :bounced_at, :utc_datetime_usec
      add :complained_at, :utc_datetime_usec
      add :suppressed_at, :utc_datetime_usec
      add :metadata, :map, null: false, default: %{}
      add :lock_version, :integer, null: false, default: 1
      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:mailglass_deliveries, [:provider, :provider_message_id],
             where: "provider_message_id IS NOT NULL",
             name: :mailglass_deliveries_provider_msg_id_idx)
    create index(:mailglass_deliveries, [:tenant_id, "last_event_at DESC"],
             name: :mailglass_deliveries_tenant_recent_idx)
    create index(:mailglass_deliveries, [:tenant_id, :recipient],
             name: :mailglass_deliveries_tenant_recipient_idx)
    create index(:mailglass_deliveries, [:tenant_id, :stream, :terminal, "last_event_at DESC"],
             name: :mailglass_deliveries_tenant_stream_terminal_idx)

    create table(:mailglass_events, primary_key: false, prefix: prefix) do
      add :id, :uuid, primary_key: true
      add :tenant_id, :text, null: false
      add :delivery_id, :uuid  # no FK per ARCHITECTURE §4.3
      add :type, :text, null: false
      add :occurred_at, :utc_datetime_usec, null: false
      add :idempotency_key, :text
      add :reject_reason, :text
      add :raw_payload, :map
      add :normalized_payload, :map, null: false, default: %{}
      add :metadata, :map, null: false, default: %{}
      add :trace_id, :text
      add :needs_reconciliation, :boolean, null: false, default: false
      add :inserted_at, :utc_datetime_usec, null: false, default: fragment("now()")
      # Note: no :updated_at on events — append-only
    end

    create unique_index(:mailglass_events, [:idempotency_key],
             where: "idempotency_key IS NOT NULL",
             name: :mailglass_events_idempotency_key_idx)
    create index(:mailglass_events, [:delivery_id, :occurred_at],
             where: "delivery_id IS NOT NULL",
             name: :mailglass_events_delivery_idx)
    create index(:mailglass_events, [:tenant_id, "inserted_at DESC"],
             name: :mailglass_events_tenant_recent_idx)
    create index(:mailglass_events, [:tenant_id, :inserted_at],
             where: "needs_reconciliation = true",
             name: :mailglass_events_needs_reconcile_idx)

    execute """
            CREATE OR REPLACE FUNCTION mailglass_raise_immutability()
            RETURNS trigger
            LANGUAGE plpgsql AS $$
            BEGIN
              RAISE SQLSTATE '45A01'
                USING MESSAGE = 'mailglass_events is append-only; UPDATE and DELETE are forbidden';
            END;
            $$;
            """,
            "DROP FUNCTION IF EXISTS mailglass_raise_immutability()"

    execute """
            CREATE TRIGGER mailglass_events_immutable_trigger
              BEFORE UPDATE OR DELETE ON mailglass_events
              FOR EACH ROW EXECUTE FUNCTION mailglass_raise_immutability();
            """,
            "DROP TRIGGER IF EXISTS mailglass_events_immutable_trigger ON mailglass_events"

    create table(:mailglass_suppressions, primary_key: false, prefix: prefix) do
      add :id, :uuid, primary_key: true
      add :tenant_id, :text, null: false
      add :address, :citext, null: false
      add :scope, :text, null: false
      add :stream, :text
      add :reason, :text, null: false
      add :source, :text, null: false
      add :expires_at, :utc_datetime_usec
      add :metadata, :map, null: false, default: %{}
      add :inserted_at, :utc_datetime_usec, null: false, default: fragment("now()")
    end

    execute """
            ALTER TABLE mailglass_suppressions
              ADD CONSTRAINT mailglass_suppressions_stream_scope_check
              CHECK (
                (scope = 'address_stream' AND stream IS NOT NULL) OR
                (scope IN ('address', 'domain') AND stream IS NULL)
              )
            """,
            "ALTER TABLE mailglass_suppressions DROP CONSTRAINT IF EXISTS mailglass_suppressions_stream_scope_check"

    create unique_index(:mailglass_suppressions,
             [:tenant_id, :address, :scope, "COALESCE(stream, '')"],
             name: :mailglass_suppressions_tenant_address_scope_idx)
    create index(:mailglass_suppressions, [:tenant_id, :address],
             name: :mailglass_suppressions_tenant_address_idx)
    create index(:mailglass_suppressions, [:expires_at],
             where: "expires_at IS NOT NULL",
             name: :mailglass_suppressions_expires_idx)
  end

  def down(_opts) do
    drop table(:mailglass_suppressions)
    execute "DROP TRIGGER IF EXISTS mailglass_events_immutable_trigger ON mailglass_events"
    execute "DROP FUNCTION IF EXISTS mailglass_raise_immutability()"
    drop table(:mailglass_events)
    drop table(:mailglass_deliveries)
    execute "DROP EXTENSION IF EXISTS citext"
  end
end
```

**Drop order in `down/1` is reverse of create** — suppressions first (no dependencies), then events (trigger + function before table), then deliveries, then citext extension. Citext drop uses `IF EXISTS` so adopter-installed extensions aren't affected.

**Polymorphic ownership per PHX-04:** Zero FKs from mailglass tables to adopter tables. The `mailable TEXT` field on `mailglass_deliveries` holds `"MyApp.UserMailer.welcome/1"` as a string — no reference to host code. `delivery_id` on events is logical-only. This makes mailglass migrations safely run before or after adopter migrations.

## Ecto Schemas

### §3.1 `Mailglass.Outbound.Delivery` (PERSIST-01)

```elixir
defmodule Mailglass.Outbound.Delivery do
  @moduledoc """
  Ecto schema for a row in `mailglass_deliveries`. One delivery per
  (Message, recipient, provider) tuple. Projection columns are
  maintained by `Mailglass.Outbound.Projector` per D-14.
  """
  use Mailglass.Schema  # D-28: stamps UUIDv7 PK, binary_id FK, utc_datetime_usec timestamps
  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          tenant_id: String.t() | nil,
          mailable: String.t() | nil,
          stream: :transactional | :operational | :bulk | nil,
          recipient: String.t() | nil,
          recipient_domain: String.t() | nil,
          provider: String.t() | nil,
          provider_message_id: String.t() | nil,
          last_event_type: atom() | nil,
          last_event_at: DateTime.t() | nil,
          terminal: boolean() | nil,
          dispatched_at: DateTime.t() | nil,
          delivered_at: DateTime.t() | nil,
          bounced_at: DateTime.t() | nil,
          complained_at: DateTime.t() | nil,
          suppressed_at: DateTime.t() | nil,
          metadata: map(),
          lock_version: integer() | nil,
          inserted_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  schema "mailglass_deliveries" do
    field :tenant_id, :string
    field :mailable, :string
    field :stream, Ecto.Enum, values: [:transactional, :operational, :bulk]
    field :recipient, :string
    field :recipient_domain, :string
    field :provider, :string
    field :provider_message_id, :string
    field :last_event_type, Ecto.Enum, values: [
      :queued, :sent, :rejected, :failed, :bounced, :deferred,
      :delivered, :autoresponded, :opened, :clicked,
      :complained, :unsubscribed, :subscribed, :unknown,
      :dispatched, :suppressed  # mailglass-internal, not Anymail
    ]
    field :last_event_at, :utc_datetime_usec
    field :terminal, :boolean, default: false
    field :dispatched_at, :utc_datetime_usec
    field :delivered_at, :utc_datetime_usec
    field :bounced_at, :utc_datetime_usec
    field :complained_at, :utc_datetime_usec
    field :suppressed_at, :utc_datetime_usec
    field :metadata, :map, default: %{}
    field :lock_version, :integer, default: 1
    timestamps(type: :utc_datetime_usec)
  end

  @required ~w[tenant_id mailable stream recipient recipient_domain last_event_type last_event_at]a
  @cast @required ++ ~w[provider provider_message_id terminal dispatched_at delivered_at
                        bounced_at complained_at suppressed_at metadata]a

  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> cast(attrs, @cast)
    |> validate_required(@required)
    |> put_recipient_domain()
  end

  defp put_recipient_domain(changeset) do
    case get_change(changeset, :recipient) do
      nil -> changeset
      email ->
        [_, domain] = String.split(email, "@", parts: 2)
        put_change(changeset, :recipient_domain, String.downcase(domain))
    end
  end
end
```

### §3.2 `Mailglass.Events.Event` (PERSIST-02)

```elixir
defmodule Mailglass.Events.Event do
  @moduledoc """
  Ecto schema for a row in the append-only `mailglass_events` table.

  Exposes `changeset/1` for INSERTS only. No update/delete helpers — the
  immutability trigger (D-15) would reject such calls anyway, and absence
  of the helpers prevents code that looks like it could work but blows up
  in production.
  """
  use Mailglass.Schema
  import Ecto.Changeset

  # Anymail taxonomy verbatim per D-14 project-level + mailglass-internal
  @anymail_event_types [
    :queued, :sent, :rejected, :failed, :bounced, :deferred,
    :delivered, :autoresponded, :opened, :clicked,
    :complained, :unsubscribed, :subscribed, :unknown
  ]
  @mailglass_internal_types [:dispatched, :suppressed]
  @event_types @anymail_event_types ++ @mailglass_internal_types

  @reject_reasons [:invalid, :bounced, :timed_out, :blocked, :spam, :unsubscribed, :other]

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          tenant_id: String.t() | nil,
          delivery_id: Ecto.UUID.t() | nil,
          type: atom() | nil,
          occurred_at: DateTime.t() | nil,
          idempotency_key: String.t() | nil,
          reject_reason: atom() | nil,
          raw_payload: map() | nil,
          normalized_payload: map(),
          metadata: map(),
          trace_id: String.t() | nil,
          needs_reconciliation: boolean() | nil,
          inserted_at: DateTime.t() | nil
        }

  @primary_key {:id, UUIDv7, autogenerate: true}
  schema "mailglass_events" do
    field :tenant_id, :string
    field :delivery_id, :binary_id  # logical ref, not FK
    field :type, Ecto.Enum, values: @event_types
    field :occurred_at, :utc_datetime_usec
    field :idempotency_key, :string
    field :reject_reason, Ecto.Enum, values: @reject_reasons
    field :raw_payload, :map
    field :normalized_payload, :map, default: %{}
    field :metadata, :map, default: %{}
    field :trace_id, :string
    field :needs_reconciliation, :boolean, default: false
    field :inserted_at, :utc_datetime_usec, read_after_writes: true
  end

  @required ~w[tenant_id type occurred_at]a
  @cast @required ++ ~w[delivery_id idempotency_key reject_reason raw_payload
                        normalized_payload metadata trace_id needs_reconciliation]a

  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> cast(attrs, @cast)
    |> validate_required(@required)
  end

  @doc "Public reflection — the closed atom set for API stability cross-check (D-24)."
  def __types__, do: @event_types
  def __reject_reasons__, do: @reject_reasons
end
```

### §3.3 `Mailglass.Suppression.Entry` (PERSIST-04)

```elixir
defmodule Mailglass.Suppression.Entry do
  @moduledoc """
  Ecto schema for a row in `mailglass_suppressions`. `:scope` has no
  default per D-11 + MAIL-07. Changeset REQUIRES `:scope` explicitly.
  """
  use Mailglass.Schema
  import Ecto.Changeset

  @scopes [:address, :domain, :address_stream]  # D-07
  @streams [:transactional, :operational, :bulk]  # nullable per D-07
  @reasons [:hard_bounce, :complaint, :unsubscribe, :manual, :policy, :invalid_recipient]

  @type t :: %__MODULE__{
          id: Ecto.UUID.t() | nil,
          tenant_id: String.t() | nil,
          address: String.t() | nil,
          scope: :address | :domain | :address_stream | nil,
          stream: :transactional | :operational | :bulk | nil,
          reason: atom() | nil,
          source: String.t() | nil,
          expires_at: DateTime.t() | nil,
          metadata: map(),
          inserted_at: DateTime.t() | nil
        }

  schema "mailglass_suppressions" do
    field :tenant_id, :string
    field :address, :string   # citext column; Ecto still sees string
    field :scope, Ecto.Enum, values: @scopes  # NO default per D-11
    field :stream, Ecto.Enum, values: @streams  # nullable
    field :reason, Ecto.Enum, values: @reasons
    field :source, :string
    field :expires_at, :utc_datetime_usec
    field :metadata, :map, default: %{}
    field :inserted_at, :utc_datetime_usec, read_after_writes: true
  end

  @required ~w[tenant_id address scope reason source]a
  @cast @required ++ ~w[stream expires_at metadata]a

  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> cast(attrs, @cast)
    |> validate_required(@required)
    |> validate_scope_stream_coupling()
    |> downcase_address()
  end

  # D-07: :address_stream scope REQUIRES :stream; :address / :domain scopes REJECT :stream.
  # Belt-and-suspenders with the DB-level CHECK constraint.
  defp validate_scope_stream_coupling(changeset) do
    scope = get_field(changeset, :scope)
    stream = get_field(changeset, :stream)

    case {scope, stream} do
      {:address_stream, nil} ->
        add_error(changeset, :stream, "required when scope is :address_stream")
      {scope, stream} when scope in [:address, :domain] and not is_nil(stream) ->
        add_error(changeset, :stream, "must be nil when scope is #{inspect(scope)}")
      _ -> changeset
    end
  end

  defp downcase_address(changeset) do
    case get_change(changeset, :address) do
      nil -> changeset
      addr -> put_change(changeset, :address, String.downcase(addr))
    end
  end

  def __scopes__, do: @scopes
  def __streams__, do: @streams
  def __reasons__, do: @reasons
end
```

### §3.4 `Mailglass.Schema` DRY macro (D-28)

```elixir
defmodule Mailglass.Schema do
  @moduledoc """
  Stamps mailglass-wide schema conventions. Three module attributes, no
  behaviour injection, no magic — per Phase 1 "pluggable behaviours over magic" DNA.

  Usage:

      use Mailglass.Schema
      schema "mailglass_xxx" do
        # fields ...
      end
  """
  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema
      @primary_key {:id, UUIDv7, autogenerate: true}
      @foreign_key_type :binary_id
      @timestamps_opts [type: :utc_datetime_usec]
    end
  end
end
```

## Tenancy Behaviour

### §4.1 `Mailglass.Tenancy` behaviour + helpers (D-29..D-32)

See Pattern 2 above for the full code. Key points:

- **One `@callback`:** `scope(queryable, context) :: Ecto.Queryable.t()`
- **Four non-callback helpers:** `current/0`, `put_current/1`, `with_tenant/2`, `tenant_id!/0`
- **Process-dict key:** `:mailglass_tenant_id` (namespaced)
- **Default resolver:** `Mailglass.Tenancy.SingleTenant` returns query unchanged; `current/0` returns literal `"default"` when no stamp present

### §4.2 `Mailglass.Oban.TenancyMiddleware` under optional-Oban gateway (D-33)

```elixir
# lib/mailglass/optional_deps/oban.ex (EXTEND existing Phase 1 module)
defmodule Mailglass.OptionalDeps.Oban do
  # ... existing Phase 1 available?/0 ...

  if Code.ensure_loaded?(Oban) do
    defmodule TenancyMiddleware do
      @moduledoc """
      Serializes Mailglass.Tenancy.current/0 into Oban job args on enqueue
      and restores it via put_current/1 in perform/1. Mitigates the
      process-dict leakage risk across background boundaries.
      """
      @behaviour Oban.Middleware

      @impl Oban.Middleware
      def call(job, next) do
        case job.args do
          %{"mailglass_tenant_id" => tenant_id} when is_binary(tenant_id) ->
            Mailglass.Tenancy.with_tenant(tenant_id, fn -> next.(job) end)
          _ ->
            next.(job)
        end
      end
    end
  end
end
```

**Why behind the gateway:** The middleware module must `@behaviour Oban.Middleware`, which requires `Oban.Middleware` to be loaded. Wrapping the `defmodule` in `if Code.ensure_loaded?(Oban)` means CI's `mix compile --no-optional-deps --warnings-as-errors` lane passes (the module simply doesn't exist without Oban loaded).

**Enqueue side** — the helper that stamps the tenant_id into job args lives in Phase 3's Outbound code (where Oban workers are actually enqueued). Phase 2 ships only the middleware; Phase 3 wires it into the worker's call site.

## Events Append API

### §5.1 `Mailglass.Events.append/1` + `append_multi/3` (PERSIST-05, D-01..D-06)

See Pattern 1 above for full code. Critical details:

**§5.1.1 The `{:unsafe_fragment, "(idempotency_key) WHERE idempotency_key IS NOT NULL"}` conflict target (D-03):**

Partial UNIQUE indexes require the fragment to include the exact `WHERE` clause used in the index definition. This is an Ecto constraint — [VERIFIED: `ecto` 3.13 docs on `conflict_target`]. The `WHERE` must match character-for-character with the index DDL:

```sql
-- DDL (from Migrations.Postgres.V01)
CREATE UNIQUE INDEX mailglass_events_idempotency_key_idx
  ON mailglass_events (idempotency_key)
  WHERE idempotency_key IS NOT NULL;
```

```elixir
# insert_opts/1
conflict_target: {:unsafe_fragment, "(idempotency_key) WHERE idempotency_key IS NOT NULL"}
```

If you change the index's `WHERE` clause, you must change the fragment in the code. Property test should cover this by generating events with and without `idempotency_key` and asserting both paths.

**§5.1.2 `id: nil` replay detection (D-03, Ecto issues #3132, #3910, #2694):**

When `on_conflict: :nothing` + conflict happens + `returning: true`, Ecto returns `{:ok, %Event{id: nil}}`. This is a documented footgun and the canonical way to detect the no-op:

```elixir
case Mailglass.Repo.insert(changeset, insert_opts(attrs)) do
  {:ok, %Event{id: nil}} -> fetch_by_idempotency_key(key)  # replay
  {:ok, %Event{} = event} -> {:ok, event}  # fresh insert
  {:error, _} = err -> err
end
```

The `fetch_by_idempotency_key/1` does a single SELECT to return the existing row. This means replay costs one extra query — acceptable given replays are rare (provider retry on our 5xx).

**§5.1.3 Telemetry span shape (D-04):**

```elixir
# lib/mailglass/telemetry.ex (EXTEND existing Phase 1 module)
def events_append_span(meta, fun) do
  span([:mailglass, :events, :append], meta, fun)
end

# callers extend meta with inserted?: + idempotency_key_present?:
{:ok, result} = Mailglass.Telemetry.events_append_span(%{tenant_id: tid, idempotency_key_present?: true}, fn ->
  # ... insert logic ...
  event = %Event{...}
  {:ok, event, %{inserted?: true}}  # additional metadata returned via span-return-tuple pattern
end)
```

**Why no return-shape widening:** `{:ok, :inserted | :duplicate, event}` would force every Phase 3+ caller to pattern-match three-tuples. Telemetry emits the same signal without imposing the tax on callers.

### §5.2 What `append_multi/3` does (and does not)

```elixir
# Example: Phase 3 Outbound dispatch
Ecto.Multi.new()
|> Ecto.Multi.insert(:delivery, Delivery.changeset(...))
|> Mailglass.Events.append_multi(:event, %{type: :queued, delivery_id: ..., ...})
|> Ecto.Multi.run(:projector_noop, fn _repo, %{delivery: d, event: e} ->
     # Optional: observe replay via third step
     case e.id do
       nil -> {:ok, :replayed}
       _ -> {:ok, :inserted}
     end
   end)
|> Mailglass.Repo.transact()
```

The caller's `Multi.run` step is where replay observability lives for `append_multi/3` — analogous to the telemetry signal for `append/1`. Phase 4 webhook handler will use this shape.

## Orphan Reconciliation

### §6.1 Scope of "reconciliation" in this domain

**What orphans are:** A webhook event arrives for `provider_message_id = "pm:abc123"` but `mailglass_deliveries` has no row with that `provider_message_id` yet. Root cause: the send pipeline's dispatch step hasn't committed the `UPDATE delivery SET provider_message_id = ...` yet when the webhook arrives. Empirical: SendGrid + Postmark p99 webhook latency is 5-30s; dispatch commits are ms-scale, so the window is narrow but real.

**What reconciliation does:**
1. Find events with `needs_reconciliation = true AND delivery_id IS NULL` (via the partial index).
2. For each orphan event, look up `mailglass_deliveries WHERE provider = ? AND provider_message_id = ?` (from `raw_payload`).
3. If found: update event's `delivery_id` + flip `needs_reconciliation` to false + update delivery projection via `Mailglass.Outbound.Projector.update_projections/2`.
4. If not found after a retention window (`v0.5+ configurable; default 7 days`): leave orphaned; admin dashboard surfaces via `telemetry` + a simple `count(*) WHERE needs_reconciliation = true` query.

**Critical:** Step 3's "update event's delivery_id" APPEARS to violate the immutability trigger. It does not — the link happens via an `INSERT` of a new event of type `:reconciled` that references the orphan event's ID in its metadata. Alternative considered: promoting `delivery_id` to a non-trigger-protected "sidecar" table. Rejected as complexity — simpler to emit a reconciliation event + update only the delivery projection + atomically clear `needs_reconciliation = false` on the delivery (not the event).

**Actually wait — simpler:** D-19 says `needs_reconciliation` lives on `mailglass_events`, not deliveries. The trigger prevents UPDATE on events. So the reconciler CAN'T flip `needs_reconciliation = false` on the orphan event row. The actual mechanic must be:
- Reconciler INSERTs a new event of type `:dispatched` (or similar) with the correct `delivery_id`, AND emits `Mailglass.Outbound.Projector.update_projections/2` side-effects on the delivery.
- The orphan event remains `needs_reconciliation = true` forever, but a companion reconciliation-event exists.
- `find_orphans/1` filter needs to exclude orphans that have a follow-up reconciled-event (via a NOT EXISTS subquery).

**Open question for Phase 4 planner (not Phase 2):** does the Phase 4 Oban worker emit `type: :reconciled` events, or does it skip event emission and only side-effect the delivery projection? Phase 2 ships the pure query functions; the worker's exact behavior is Phase 4's call. For Phase 2, the `find_orphans/1` query must be flexible enough to support either semantics:

```elixir
defmodule Mailglass.Events.Reconciler do
  alias Mailglass.Events.Event
  import Ecto.Query

  @spec find_orphans(keyword()) :: [Event.t()]
  def find_orphans(opts \\ []) do
    tenant_id = Keyword.get(opts, :tenant_id)
    limit = Keyword.get(opts, :limit, 100)
    max_age_minutes = Keyword.get(opts, :max_age_minutes, 10_080)  # 7 days

    cutoff = DateTime.utc_now() |> DateTime.add(-max_age_minutes * 60, :second)

    query =
      from(e in Event,
        where: e.needs_reconciliation == true and is_nil(e.delivery_id),
        where: e.inserted_at >= ^cutoff,
        order_by: [asc: e.inserted_at],
        limit: ^limit
      )

    query =
      if tenant_id do
        where(query, [e], e.tenant_id == ^tenant_id)
      else
        query
      end

    Mailglass.Repo.all(query)
  end

  @spec attempt_link(Event.t(), keyword()) :: {:ok, {Delivery.t(), Event.t()}} | {:error, :delivery_not_found}
  def attempt_link(%Event{} = event, _opts \\ []) do
    provider = event.raw_payload["provider"] || event.metadata["provider"]
    provider_message_id = event.raw_payload["provider_message_id"] || event.metadata["provider_message_id"]

    query =
      from(d in Mailglass.Outbound.Delivery,
        where: d.provider == ^provider and d.provider_message_id == ^provider_message_id,
        limit: 1
      )

    case Mailglass.Repo.one(query) do
      nil -> {:error, :delivery_not_found}
      %Mailglass.Outbound.Delivery{} = delivery -> {:ok, {delivery, event}}
    end
  end
end
```

`attempt_link/2` returns the matched pair; the Phase 4 worker decides what to do with it (emit reconciled event + projection update, or just projection update). Phase 2's responsibility ends at "find orphans + locate their intended deliveries."

## Status State Machine

### §7 App-enforced per D-15 — concrete rule set

**State space:** event types emitted on a delivery. The Anymail taxonomy + mailglass-internal `:dispatched` / `:suppressed`.

**Invariants enforced by `Mailglass.Outbound.Projector`:**
1. **Monotonic timestamps:** `dispatched_at`, `delivered_at`, `bounced_at`, `complained_at`, `suppressed_at` are set once, never overwritten. Once non-nil, subsequent events of the same type no-op at that field.
2. **`last_event_at` moves forward only:** `last_event_at = max(current, incoming)`. Late webhooks can update other columns but cannot rewind `last_event_at`.
3. **`terminal` is one-way:** flips false → true on `:delivered | :bounced | :complained | :rejected | :failed | :suppressed`. Never flips back to false.
4. **No ordering CHECK at the DB:** `:opened` arriving before `:delivered` updates `last_event_at` and records an event row but leaves `terminal` and `delivered_at` intact (because `:opened` is not terminal and doesn't have a projection slot).

**Why app-enforced (D-15 rationale):**
- Anymail event ordering is non-monotonic in practice. Providers routinely fire `:opened` before `:delivered` during batched webhook bursts.
- CHECK constraints on ordering would cause production failures on valid provider behavior.
- The invariants that ARE structural (e.g., `scope + stream` coupling in suppressions) DO use CHECK constraints because they describe row shape, not temporal ordering.

**Verification by StreamData (D-16):**
```elixir
property "projection converges: apply_all(events) == apply_all(dedup(events))" do
  check all events <- list_of(event_generator(), min_length: 1, max_length: 20),
            replays <- integer(1..10) do
    fresh = apply_all(events)
    replayed = apply_all(List.duplicate(events, replays) |> List.flatten() |> Enum.shuffle())
    assert projection_fields(fresh) == projection_fields(replayed)
  end
end
```

Where `projection_fields/1` extracts the 8 projection columns. The property guarantees MAIL-03 idempotency + D-15 monotonicity simultaneously.

## Runtime State Inventory

Phase 2 is greenfield schema creation — no existing data to migrate. Nevertheless, the categories below apply because this phase introduces NEW runtime state that later phases consume:

| Category | Items Introduced | Action Required |
|----------|------------------|------------------|
| Stored data | 3 new Postgres tables, 1 function, 1 trigger, 1 pg_class comment | None for Phase 2 (greenfield); adopter-level migration execution via `mix ecto.migrate` |
| Live service config | `Mailglass.Config` gains `:tenancy` + `:suppression_store` NimbleOptions keys | None in Phase 2; adopters add via `config :mailglass, ...` in Phase 7's installer |
| OS-registered state | None | None — verified by mapping: no systemd units, no Task Scheduler entries, no launchd plists added |
| Secrets/env vars | None (no new secrets — tenant ID comes from adopter's scope/auth) | None |
| Build artifacts | `mix.exs` adds `:uuidv7` to deps/0; compiled `.beam` files for ~25 new modules | `mix deps.get` required after `mix.exs` patch; Phase 7 installer will vendor no new binaries |

**Nothing found in "OS-registered state":** verified by scanning the Phase 2 CONTEXT.md and this research — no CLI binaries, no daemons, no cron jobs created. The only scheduler reference is D-20's `{:cron, "*/15 * * * *"}` which is a Phase 4 Oban worker config, not a Phase 2 OS registration.

**Phase 1 → Phase 2 consumed artifacts:** `Mailglass.Repo.transact/1` activated with SQLSTATE 45A01 translation (D-06); `Mailglass.SuppressedError` patched pre-GA (D-09); `Mailglass.Config` extended with `:tenancy` + `:suppression_store` slots; `Mailglass.Telemetry` extended with `persist_span/3` + `events_append_span/3` helpers.

## Common Pitfalls

### Pitfall 1: Partial-index conflict target requires exact WHERE-clause match (MAIL-03 mitigation footgun)

**What goes wrong:** Ecto `on_conflict: :nothing, conflict_target: [:idempotency_key]` fails with `ON CONFLICT DO NOTHING requires inference on index predicate` because `:idempotency_key` is a regular column list — the query planner can't associate it with the partial index.

**Why it happens:** The `conflict_target` needs to specify the partial-index `WHERE` clause to disambiguate from a full-column UNIQUE. `[:idempotency_key]` would work if the index were full; with `WHERE idempotency_key IS NOT NULL`, the target must include the predicate.

**How to avoid:** Use `{:unsafe_fragment, "(idempotency_key) WHERE idempotency_key IS NOT NULL"}` per D-03. The fragment text must match the index DDL character-for-character (case, whitespace).

**Warning signs:**
- Test errors like `ERROR 42P10 (invalid_column_reference) there is no unique or exclusion constraint matching the ON CONFLICT specification`.
- Ecto log shows `ON CONFLICT (idempotency_key) DO NOTHING` without the WHERE clause.

### Pitfall 2: `RETURNING true` + `on_conflict: :nothing` returns `%Event{id: nil}` on conflict

**What goes wrong:** Caller expects a real event back, writes code like `{:ok, event} = Events.append(attrs); use(event.id)`, crashes with `nil.id`.

**Why it happens:** Ecto docs footgun. [VERIFIED: ecto issues #3132, #3910, #2694 referenced in accrue events.ex]. When a conflict happens, Postgres doesn't return the conflicting row — it returns nothing. Ecto fills in an empty struct with `id: nil`.

**How to avoid:** The `append/1` path detects `id: nil` and fetches via `idempotency_key` (already in D-03 design). The `append_multi/3` path requires the caller's `Multi.run` step to handle the no-op case. Document prominently in `Mailglass.Events` module docs.

**Warning signs:**
- Test failure: `nil value given for :id`.
- Phase 3 dispatch code checks `event.id == nil` without understanding why.

### Pitfall 3: Matching `%Postgrex.Error{}` by message string breaks on Postgrex version bumps

**What goes wrong:** Code like `err.message =~ "mailglass_events is append-only"` matches in v0.1, breaks when Postgrex reformats error messages.

**Why it happens:** Postgrex error structure evolves; message strings are not a stable API.

**How to avoid:** Always match `%Postgrex.Error{postgres: %{pg_code: "45A01"}}` per D-06. Phase 2 Credo check opportunity: `Mailglass.Credo.NoErrorMessageStringMatch` (deferred to Phase 6).

**Warning signs:**
- Postgrex upgrade causes immutability tests to fail even though the trigger still fires.

### Pitfall 4: FK from `mailglass_events.delivery_id` → `mailglass_deliveries.id` seems like a good idea

**What goes wrong:** Adding `references(:mailglass_deliveries)` to the migration. Now orphan webhook inserts fail with FK violation because the delivery row doesn't exist yet.

**Why it happens:** Default Ecto idiom is to add FKs; ARCHITECTURE.md §4.3 is where it gets called out as wrong.

**How to avoid:** `delivery_id` is `:binary_id` (a logical reference) with `UUID` column type + no `references()` in the migration. Phase 2 test should include a case where an event is inserted with a `delivery_id` that doesn't exist, to explicitly document this is allowed.

**Warning signs:**
- Adopter adds `belongs_to :delivery, Mailglass.Outbound.Delivery` to Event schema thinking it should have FK behavior. That's fine for querying; just don't add the migration FK.

### Pitfall 5: `Ecto.Enum` at load time raises on unknown values

**What goes wrong:** Production webhook delivers a new event type (say `:subscribed` when mailglass only had the original Anymail set). Ecto `load` raises `Ecto.ChangeError` at read time; admin dashboard crashes.

**Why it happens:** `Ecto.Enum` uses a closed atom set. Unknown values at write time raise at changeset level (good); unknown values already in the DB at read time raise at load.

**How to avoid:**
1. Include `:unknown` in the enum value list (D-14 Anymail taxonomy already does).
2. When adding new event types in v0.5+, write a migration that: backfills existing `:unknown` rows that match the new type, then the code update lands.
3. Property test: generate events with all enum values and verify round-trip via `Repo.insert` + `Repo.get` + struct comparison.

**Warning signs:**
- Test failures on CI when upgrading mailglass versions.

### Pitfall 6: `tenant_id TEXT NOT NULL` means forgetting to stamp tenant_id is a loud error

**What goes wrong (ironically the desired outcome):** Code that forgets `Mailglass.Tenancy.put_current/1` in the adopter's `on_mount/4` → `SingleTenant.current/0` returns `"default"` → all records written with `tenant_id = "default"` → data leak risk if the adopter eventually adds a real multi-tenant resolver.

**Why it happens:** The "safe by default" design silently works in single-tenant; multi-tenant adopters must explicitly opt in.

**How to avoid:** Phase 6 `NoUnscopedTenantQueryInLib` Credo check + `tenant_id!/0` for callers who hold context. v0.5 admin dashboard could surface "rows without explicit tenant" as a warning.

**Warning signs:**
- `SELECT DISTINCT tenant_id FROM mailglass_events` shows only `"default"` in an app that was supposed to be multi-tenant.
- Adopter claims "tenancy works" but never called `put_current/1`.

### Pitfall 7: `lock_version` optimistic lock without retry = `Ecto.StaleEntryError` in production

**What goes wrong:** Two worker processes dispatch the same delivery; both update projection columns; second update raises `Ecto.StaleEntryError` which propagates to the caller.

**Why it happens:** Ecto's `optimistic_lock/3` increments `lock_version` on every update; concurrent updates race.

**How to avoid:** Phase 2 ships the column + changeset support. Phase 3 is where the retry logic lives (in the dispatch worker's single-retry). Phase 2 tests must assert that `Ecto.StaleEntryError` IS raised on concurrent updates (the mechanism works) — the recovery is Phase 3's call.

**Warning signs:**
- Test hangs or flakes on the projector update path.
- Oban retries for wrong reason (looks like transport fail, actually lock contention).

### Pitfall 8: `citext` extension not created before table creation

**What goes wrong:** Migration runs; `mailglass_suppressions` CREATE TABLE fails with `type "citext" does not exist`.

**Why it happens:** `citext` is a Postgres extension, not a built-in type. Must be explicitly created first.

**How to avoid:** `execute "CREATE EXTENSION IF NOT EXISTS citext"` FIRST in `V01.up/1`, before any `create table` calls that use citext.

**Warning signs:**
- Fresh database migration failure on `mailglass_suppressions`.

## Code Examples

### Append a webhook event (Phase 4 anticipation)

```elixir
# Source: §5.2 append_multi shape
Ecto.Multi.new()
|> Mailglass.Events.append_multi(:event, %{
  type: :delivered,
  delivery_id: delivery.id,
  occurred_at: DateTime.from_iso8601!(payload["timestamp"]),
  idempotency_key: "postmark:webhook:#{payload["MessageID"]}",
  raw_payload: payload,
  normalized_payload: %{provider_message_id: payload["MessageID"], status: "delivered"},
  tenant_id: delivery.tenant_id
})
|> Ecto.Multi.update(:delivery_projection, Mailglass.Outbound.Projector.update_projections(delivery, event))
|> Mailglass.Repo.transact()
```

### Verify immutability trigger fires

```elixir
# Source: Phase 2 integration test — runs against the real trigger (D-37)
test "UPDATE on mailglass_events raises EventLedgerImmutableError" do
  {:ok, event} = Mailglass.Events.append(%{
    type: :queued,
    tenant_id: "test",
    occurred_at: DateTime.utc_now()
  })

  # The trigger raises SQLSTATE 45A01; Mailglass.Repo.transact/1 translates.
  assert_raise Mailglass.EventLedgerImmutableError, fn ->
    event
    |> Ecto.Changeset.change(%{type: :delivered})
    |> Mailglass.Repo.update()
  end

  assert_raise Mailglass.EventLedgerImmutableError, fn ->
    Mailglass.Repo.delete(event)
  end
end
```

### Tenant scoping at the Ecto query seam

```elixir
# Source: §4.1 scope/2 usage
import Ecto.Query

def list_deliveries_for_current_tenant do
  Mailglass.Outbound.Delivery
  |> Mailglass.Tenancy.scope(Mailglass.Tenancy.current())
  |> order_by([d], desc: d.last_event_at)
  |> Mailglass.Repo.all()
end

# With SingleTenant resolver (default): query passes through unchanged
# With adopter's resolver: query gains WHERE tenant_id = ? filter
```

### StreamData convergence property (D-16 verbatim shape)

```elixir
# Source: test/mailglass/properties/idempotency_convergence_test.exs
use ExUnit.Case, async: true
use ExUnitProperties

property "projection converges under replay" do
  check all events <- list_of(event_attrs_generator(), min_length: 1, max_length: 20),
            replays <- integer(1..10),
            max_runs: 100 do
    # Fresh: apply each event once in order
    fresh = apply_events(events)

    # Replayed: apply N copies shuffled
    replayed =
      events
      |> List.duplicate(replays)
      |> List.flatten()
      |> Enum.shuffle()
      |> apply_events()

    assert projection_columns(fresh) == projection_columns(replayed)
  end
end

defp event_attrs_generator do
  gen all type <- member_of([:queued, :dispatched, :delivered, :bounced, :complained, :opened]),
          idempotency_key <- string(:alphanumeric, min_length: 8, max_length: 32),
          occurred_at_offset_sec <- integer(-60..60) do
    %{
      type: type,
      idempotency_key: idempotency_key,
      occurred_at: DateTime.add(DateTime.utc_now(), occurred_at_offset_sec, :second),
      tenant_id: "prop-test"
    }
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `Repo.transaction/1` with explicit `rollback` | `Repo.transact/2` with `{:ok, _}` / `{:error, _}` semantics | Ecto 3.13 (Phase 1 already adopted) | Phase 2 uses `Repo.transact/1` facade; cleaner error propagation |
| `validate_inclusion(:type, @values)` on string field | `field :type, Ecto.Enum, values: @values` | Ecto 3.x stable | D-10 locks `Ecto.Enum` for all closed atom columns; auto string↔atom coercion |
| `:bigserial` PKs with `@primary_key {:id, :id, ...}` | UUIDv7 PKs via `{:uuidv7, "~> 1.0"}` | UUIDv7 stable since Sep 2024; RFC 9562 May 2024 | D-25 picks UUIDv7 for non-enumerability + shardability; Postgres 18 native `uuidv7()` is a future free upgrade |
| `typed_struct` / `typed_ecto_schema` | Hand-written `@type t :: %__MODULE__{...}` + Phase 6 Credo check | Elixir 1.18+ set-theoretic types + 1.19 native typed struct roadmap | D-22/D-23 reject the libs; D-24 Credo check prevents typespec drift |
| `@primary_key {:id, Ecto.UUID, autogenerate: true}` (UUIDv4 default) | UUIDv7 for time-ordering | UUIDv7 available since 2024 | Phase 2 uses UUIDv7 everywhere; accrue's bigserial precedent diverged for mailglass (D-26) |
| `owner_id :string` polymorphic (`accrue_events.subject_type + subject_id`) | `delivery_id :binary_id` logical ref (no FK, no polymorphic) | ARCHITECTURE.md §4.3 decision | mailglass doesn't need polymorphic ownership for `mailglass_events` because deliveries are the only subject type. Accrue's wider subject space justified polymorphism. |

**Deprecated/outdated:**
- **`mrml` Hex package:** Does not exist on Hex; the real package is `mjml` (Rust NIF). Phase 2 doesn't use either, but noting the STACK.md correction.
- **`:provider` without `:provider_message_id` as UNIQUE:** old pattern led to MAIL-09 collisions. Correct: `UNIQUE (provider, provider_message_id) WHERE provider_message_id IS NOT NULL`.
- **Runtime `ArgumentError` on "not in Multi":** PERSIST-05 original wording was superseded by D-02. Lint-time `NoRawEventInsert` is the actual enforcement.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit 1.18+ (stdlib) + StreamData 1.3 (property tests) + `Ecto.Adapters.SQL.Sandbox` |
| Config file | `test/test_helper.exs` (exists from Phase 1; Phase 2 extends with Sandbox.mode + Migration.up/0) |
| Quick run command | `mix test test/mailglass/ --exclude integration --exclude property` |
| Full suite command | `mix test --warnings-as-errors` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PERSIST-01 | `mailglass_deliveries` schema exists with 8 projection columns + `(provider, provider_message_id) WHERE NOT NULL` UNIQUE | integration (DB-backed) | `mix test test/mailglass/outbound/delivery_test.exs -x` | ❌ Wave 0 |
| PERSIST-02 | `mailglass_events` has trigger raising SQLSTATE 45A01 on UPDATE/DELETE | integration | `mix test test/mailglass/events_test.exs::test\\ immutability -x` | ❌ Wave 0 |
| PERSIST-03 | UNIQUE partial index on `idempotency_key WHERE NOT NULL` + property test converges | property | `mix test test/mailglass/properties/idempotency_convergence_test.exs -x` | ❌ Wave 0 |
| PERSIST-04 | `mailglass_suppressions` scope has no default; changeset requires it; CHECK constraint enforces scope/stream coupling | unit + integration | `mix test test/mailglass/suppression/entry_test.exs -x` | ❌ Wave 0 |
| PERSIST-05 | `Events.append/1` + `append_multi/3` are the only writers; telemetry emits `inserted?: boolean` | unit + integration | `mix test test/mailglass/events_test.exs -x` | ❌ Wave 0 |
| PERSIST-06 | `Mailglass.Migration.up/0` + `down/0` are idempotent + round-trip | integration | `mix test test/mailglass/migration_test.exs -x` | ❌ Wave 0 |
| TENANT-01 | All three schemas carry `tenant_id TEXT NOT NULL`; `SingleTenant.current/0` returns `"default"` | unit | `mix test test/mailglass/tenancy_test.exs -x` | ❌ Wave 0 |
| TENANT-02 | `scope/2` callback + `SingleTenant` no-op default + process-dict helpers (`put_current/1`, `with_tenant/2`) | unit | `mix test test/mailglass/tenancy_test.exs -x` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `mix test test/mailglass/ --exclude integration --exclude property` (unit only, <5s)
- **Per wave merge:** `mix test --warnings-as-errors` (full suite incl. property + integration, <60s)
- **Phase gate:** Full suite green + `mix compile --no-optional-deps --warnings-as-errors` + `mix credo --strict` before `/gsd-verify-work`

### Wave 0 Gaps

All test files need creation in Wave 0 (Phase 2 has no pre-existing test files for the new modules). Specifically:

- [ ] `test/support/test_repo.ex` — `Mailglass.TestRepo` (Postgres adapter, points at mailglass_test DB)
- [ ] `test/support/data_case.ex` — ExUnit case template with sandbox checkout + `put_current("test-tenant")`
- [ ] `test/support/generators.ex` — StreamData generators for Delivery/Event/Suppression attrs
- [ ] `test/test_helper.exs` patch — `Ecto.Adapters.SQL.Sandbox.mode(Mailglass.TestRepo, :manual)` + `Ecto.Migrator.run(Mailglass.TestRepo, :up, all: true)`
- [ ] `priv/repo/migrations/00000000000001_mailglass_init.exs` — synthetic test migration (D-37)
- [ ] `test/mailglass/events_test.exs` — covers PERSIST-02 (trigger), PERSIST-05 (writer API)
- [ ] `test/mailglass/events/event_test.exs` — covers Event changeset validations
- [ ] `test/mailglass/events/reconciler_test.exs` — covers `find_orphans/1` + `attempt_link/2`
- [ ] `test/mailglass/outbound/delivery_test.exs` — covers PERSIST-01
- [ ] `test/mailglass/outbound/projector_test.exs` — covers D-14/D-15 monotonic rule
- [ ] `test/mailglass/suppression/entry_test.exs` — covers PERSIST-04, D-07, D-11, CHECK constraint
- [ ] `test/mailglass/suppression_store/ecto_test.exs` — covers SuppressionStore.Ecto impl
- [ ] `test/mailglass/tenancy_test.exs` — covers TENANT-01/02, `with_tenant/2` isolation
- [ ] `test/mailglass/migration_test.exs` — covers PERSIST-06 up/down round-trip
- [ ] `test/mailglass/properties/idempotency_convergence_test.exs` — D-16 MAIL-03 property
- [ ] `test/mailglass/properties/tenant_isolation_test.exs` — partial TENANT-03 (multi-tenant leak)
- [ ] `test/mailglass/repo_test.exs` (patch existing) — SQLSTATE 45A01 translation test

### Postgres setup for tests

```elixir
# config/test.exs (patch)
config :mailglass, repo: Mailglass.TestRepo
config :mailglass, tenancy: Mailglass.Tenancy.SingleTenant
config :mailglass, suppression_store: Mailglass.SuppressionStore.Ecto

config :mailglass, Mailglass.TestRepo,
  adapter: Ecto.Adapters.Postgres,
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  username: System.get_env("POSTGRES_USER", "postgres"),
  password: System.get_env("POSTGRES_PASSWORD", "postgres"),
  database: "mailglass_test_#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10
```

## Open Questions Resolved

The ten open questions from ROADMAP.md / CONTEXT.md are answered below. Each has a concrete recommendation tied to a locked decision.

### Q1: `metadata jsonb` projection columns — which columns, how updated?

**Answer:** 8 projection columns per D-13 (`last_event_type`, `last_event_at`, `terminal`, `dispatched_at`, `delivered_at`, `bounced_at`, `complained_at`, `suppressed_at`). Update mechanism: `Mailglass.Outbound.Projector.update_projections/2` per D-14 — single Elixir function, not a Postgres trigger or generated column. The `metadata jsonb` field itself is a separate adopter-extensibility bag (D-17) and is NOT one of the projection columns; it never auto-updates from events.

**Why not triggers or generated columns:** D-15 explicitly rejects DB-level enforcement of lifecycle ordering. Postgres generated columns would require a CHECK-like expression — same problem. Trigger-maintained projections would scatter write logic across Elixir + plpgsql, making tests + upgrades painful.

### Q2: Orphan-webhook reconciliation cadence + retention window

**Answer:** `{:cron, "*/15 * * * *"}` per D-20. Retention window: 7 days default, configurable via `Mailglass.Config` in v0.5. Rationale: SendGrid + Postmark p99 webhook latency is 5-30s empirically; 15 min catches stragglers; @hourly is too slow for user-visible delivery status.

**Phase 2 scope:** only the pure query functions `find_orphans/1` (accepts `tenant_id`, `limit`, `max_age_minutes` opts) and `attempt_link/2`. The Oban worker wrapping them lands in Phase 4. Phase 2 does NOT ship a scheduler, cron config, or Oban dep.

### Q3: Adopt `:typed_struct` and/or `:typed_ecto_schema`?

**Answer:** No — hand-written `@type t :: %__MODULE__{...}` + plain `use Ecto.Schema` per D-22 + D-23. [VERIFIED: Hex.pm 2026-04-22 — typed_ecto_schema 0.4.3 last release 2025-06-25; cadence slowing as Elixir 1.19's native typed-struct roadmap approaches.] Migrating adopters off a library-generated `Event.t()` later would be a coordinated breaking change. ~45 LOC of hand-written typespec across three schemas is cheap vs. future migration cost.

**Phase 6 Credo check backstop:** `Mailglass.Credo.EctoSchemaHasTypespec` (D-24) prevents typespec drift — the primary argument for `typed_ecto_schema` is obsoleted.

### Q4: Status state machine — app-enforced vs DB CHECK constraint?

**Answer:** App-enforced via `Mailglass.Outbound.Projector` per D-15, confirming SUMMARY.md Q6 + ARCHITECTURE.md §4.6 recommendation. Reasoning: Anymail event ordering is non-monotonic in practice — SendGrid + Postmark deliver `:opened` before `:delivered` regularly during incident bursts. CHECK constraints on ordering would break on valid provider payloads. Structural CHECKs remain appropriate (e.g., `scope/stream` coupling in `mailglass_suppressions`); lifecycle CHECKs do not.

### Q5: How to enforce `Mailglass.Events.append/2` is only callable inside an `Ecto.Multi`?

**Answer:** Don't enforce at runtime — enforce at lint time via Phase 6 `Mailglass.Credo.NoRawEventInsert` per D-02. The original PERSIST-05 wording "outside an Ecto.Multi raises ArgumentError" is superseded because:
1. `append/1` (the standalone audit path) does NOT use a caller-provided Multi — it wraps its own `Repo.transact/1`. Raising would make `append/1` impossible.
2. D-01 adds `append/1` as a first-class public API for standalone audit events. The "only Multi" invariant was about preventing raw `Repo.insert(%Event{})`, not about forbidding `append/1`.
3. Runtime process-dict inspection ("am I inside Multi?") would impose measurable cost per call and fail open in valid scenarios (nested Multi, Oban worker context).

The invariant PERSIST-05 actually protects — no raw `Repo.insert(%Event{})` anywhere in mailglass code — is enforced at lint time by the Phase 6 check.

### Q6: Idempotency `UNIQUE` partial index shape + replay detection

**Answer:** Index: `CREATE UNIQUE INDEX mailglass_events_idempotency_key_idx ON mailglass_events (idempotency_key) WHERE idempotency_key IS NOT NULL` (not scoped by tenant). Conflict target in Ecto: `{:unsafe_fragment, "(idempotency_key) WHERE idempotency_key IS NOT NULL"}` per D-03.

**Why NOT tenant-scoped:** `idempotency_key` is already namespaced by provider (`"postmark:webhook:abc123"`). Tenant scoping the index would add column write cost + index storage without a real collision mitigation — providers don't reuse event IDs across tenants.

**Replay detection:**
- `append/1`: detects `{:ok, %Event{id: nil}}` + fetches existing row by key (one extra SELECT).
- `append_multi/3`: caller adds a `Multi.run` step inspecting the `:event` result.
- Telemetry `[:mailglass, :events, :append, :stop]` metadata carries `inserted?: boolean` + `idempotency_key_present?: boolean` (D-04).

**Test mechanism:** StreamData property generates `(event, replay_count)` pairs; asserts `apply_all == apply_all(replayed_shuffled)` (D-16).

### Q7: Polymorphic `(owner_type, owner_id)` — text + uuid or two columns?

**Answer:** N/A for Phase 2. mailglass schemas do NOT use polymorphic ownership in the accrue sense. PHX-04 prevention is achieved via:
- Zero FKs from mailglass tables to adopter tables (`mailable TEXT` holds the module/function/arity string, not a FK to adopter code).
- `delivery_id` on `mailglass_events` is a logical `binary_id` without `references()` — no FK to `mailglass_deliveries`.
- Each sibling package (`mailglass_inbound` v0.5+) gets its own migration counter per D-39.

The polymorphic `(owner_type, owner_id)` pattern from `prompts/mailglass-engineering-dna-from-prior-libs.md` §3.7 applies to accrue's user/org/team subject space; mailglass's subject space is just deliveries.

### Q8: Migration generator shape — one file or split?

**Answer:** Single Oban-pattern dispatcher per D-35. `mix mailglass.gen.migration` emits exactly ONE file (8 lines, stable across versions) that calls `Mailglass.Migration.up/0`. The DDL lives in `lib/mailglass/migrations/postgres/v01.ex` as library code. Adopter upgrade path: v0.5 ships `v02.ex` + `mix mailglass.gen.migration --upgrade` produces another 8-line wrapper calling `up(version: 2)`.

**Why NOT split:** Splitting into per-table migrations would mean the adopter's `priv/repo/migrations/` accumulates 5+ files per mailglass version (deliveries, events, suppressions, trigger, indexes). That's noise. The Oban pattern keeps the adopter's tree clean — one file per mailglass-version upgrade, library owns the DDL.

**Installer embedding (D-38):** `mix mailglass.install` in Phase 7 calls `Mix.Task.run("mailglass.gen.migration", args)` composed with Phase 2's task. No installer-specific DDL logic.

### Q9: SingleTenant resolver — exact shape

**Answer:**
- `@callback scope(queryable, context) :: Ecto.Queryable.t()` per D-29.
- `SingleTenant.scope/2` is a no-op — returns `queryable` unchanged.
- `SingleTenant.current/0` returns the literal string `"default"`.
- Both modes work via the same `Mailglass.Tenancy.scope(query, current())` call site. In single-tenant mode, the filter doesn't apply (scope is no-op). In multi-tenant mode, the adopter's resolver injects `WHERE tenant_id = ?`.

**How `scope/2` returns queries in multi-tenant:**
```elixir
defmodule MyApp.Tenancy do
  @behaviour Mailglass.Tenancy
  import Ecto.Query

  @impl true
  def scope(queryable, tenant_id) when is_binary(tenant_id) do
    from(q in queryable, where: q.tenant_id == ^tenant_id)
  end
end
```

### Q10: StreamData property test harness — idiomatic 2026 pattern + Ecto sandbox interaction

**Answer:** Use `ExUnitProperties` (StreamData's ExUnit integration). Run inside an `Ecto.Adapters.SQL.Sandbox.checkout/1` block per-run. Key patterns:

```elixir
defmodule Mailglass.Properties.IdempotencyConvergenceTest do
  use ExUnit.Case, async: false  # async: false for DB-backed property tests
  use ExUnitProperties

  setup do
    # Checkout per-test; property runs many iterations within one checkout
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Mailglass.TestRepo)
    :ok
  end

  property "projection converges under replay", %{} do
    check all events <- list_of(event_attrs_generator(), min_length: 1, max_length: 20),
              replays <- integer(1..10),
              max_runs: 100 do  # 100 runs — sandbox per property, not per run
      # Clean the events table between runs to isolate state
      Mailglass.TestRepo.delete_all("mailglass_events")
      fresh = apply_events(events)

      Mailglass.TestRepo.delete_all("mailglass_events")
      replayed = events |> List.duplicate(replays) |> List.flatten() |> Enum.shuffle() |> apply_events()

      assert projection_columns(fresh) == projection_columns(replayed)
    end
  end
end
```

**Gotchas:**
- `async: false` required for DB-backed property tests (sandbox checkout is per-test, shrink can repeat runs).
- `max_runs: 100` (default is 100); full runs for property tests land in CI's wave-merge pass, not per-commit.
- `delete_all` between property iterations because StreamData runs the body many times against fresh generators; shared table state would conflate runs.
- Alternative: wrap each run in a transaction + rollback (faster than delete_all for large generators) via `Mailglass.Repo.transact(fn -> ... {:error, :rollback} end)`.

## Landmines Specific to This Phase

### §L1. Trigger function rename safety (`mailglass_raise_immutability` vs accrue's `accrue_events_immutable`)

**Landmine:** Phase 2 uses `mailglass_raise_immutability()` as the function name. Adopter tries to upgrade from an accrue-patterned codebase (or accidentally uses `accrue_events_immutable` in copy-pasted migration code) → function doesn't exist, trigger doesn't fire.

**Prevention:** The function + trigger names are explicitly set in `V01.up/1` migration. No runtime code depends on the function name — only the SQLSTATE code (`45A01`). This is the correct separation of concerns; the name is just descriptive.

**Planner must verify:** integration test `assert_raise EventLedgerImmutableError` runs against the live schema and confirms the trigger actually fires with the SQLSTATE-45A01 signal that `Repo.transact/1` translates.

### §L2. Migration order correctness for `citext` + trigger + table

**Landmine:** Ecto's `create table` + `execute` are not strictly ordered in complex migrations. If `CREATE EXTENSION citext` runs after `create table(:mailglass_suppressions)`, the migration fails.

**Prevention:**
1. First `execute` in `V01.up/1`: `"CREATE EXTENSION IF NOT EXISTS citext"`
2. Then all `create table(...)` blocks (order: deliveries → events → suppressions because no cross-table deps, but suppressions last is safe)
3. Then all `create index(...)` blocks
4. Then the trigger function `execute "CREATE OR REPLACE FUNCTION ..."`
5. Then the trigger `execute "CREATE TRIGGER ..."`
6. Then the `COMMENT ON TABLE mailglass_events IS '1'` for version tracking

**Planner must verify:** `mix ecto.migrate` + `mix ecto.rollback` + `mix ecto.migrate` round-trips cleanly on a fresh DB (test covers this explicitly).

### §L3. `tenant_id` nullability + indexes

**Landmine:** REQUIREMENTS.md TENANT-01 says "nullable for single-tenant mode." D-40 refines to NOT NULL with default literal `"default"`. If the planner follows the REQ verbatim, the schema will accept `tenant_id = NULL` rows, silently breaking `NoUnscopedTenantQueryInLib` Phase 6 enforcement + causing "mystery row origin" bugs.

**Prevention:** D-40 supersedes. Every mailglass schema column is `tenant_id TEXT NOT NULL`. Indexes include `tenant_id` as the FIRST column of the leading edge (critical for query planner cardinality — tenants are low-cardinality, so Postgres skips the index on queries that don't filter by tenant; prefix-compression in B-tree handles the storage cost per D-40 rationale).

**Planner must verify:** Ecto schema migrations use `add :tenant_id, :text, null: false`. Every index starts with `[:tenant_id, ...]`. Test: attempting to insert with `tenant_id: nil` raises `Postgrex.Error` with `not_null_violation`.

### §L4. RETURNING + on_conflict + partial index — documented footgun chain

**Landmine:** Three Ecto behaviors combine badly:
1. `on_conflict: :nothing` with `returning: true` returns `{:ok, %Event{id: nil}}` on conflict (not `{:ok, existing_event}`).
2. `conflict_target: [:idempotency_key]` fails on partial unique index — needs `{:unsafe_fragment, ...}`.
3. `on_conflict: :nothing` silently no-ops — test that "wrote this event" can't distinguish between fresh insert and replay without extra logic.

**Prevention per D-03:** Always use `{:unsafe_fragment, "(idempotency_key) WHERE idempotency_key IS NOT NULL"}` when `idempotency_key` is set. Always detect `id: nil` in `append/1` and fallback-fetch. Never assume `on_conflict: :nothing` is observable from the return value alone.

**Planner must verify:** `test/mailglass/events_test.exs` includes an explicit test "second append with same idempotency_key returns original event_id, not nil".

### §L5. Optimistic lock bump breaks dispatch race test without retry at Phase 2 layer

**Landmine:** D-18 ships `lock_version` in Phase 2. The projector changeset includes `Ecto.Changeset.optimistic_lock(:lock_version)`. A concurrent update raises `Ecto.StaleEntryError`. Phase 2's tests must assert this raises — NOT catch and retry (that's Phase 3's dispatch worker).

**Prevention:** Phase 2 test asserts: "two concurrent `Repo.update` calls on the same delivery raise `Ecto.StaleEntryError` on the second." This documents the mechanism works. Phase 3's dispatch worker adds the single-retry.

### §L6. Test migration must run against live DB, not some mock

**Landmine:** Phase 2 Wave 0 could accept a mock approach — "just unit-test the changesets." But D-16 + D-37 + PERSIST-02 require integration tests against the real trigger. If Wave 0 doesn't wire up a real `Mailglass.TestRepo` with the synthetic migration, every integration test fails.

**Prevention:** Wave 0 ships:
- `test/support/test_repo.ex` with `use Ecto.Repo, otp_app: :mailglass, adapter: Ecto.Adapters.Postgres`
- `priv/repo/migrations/00000000000001_mailglass_init.exs` calling `Mailglass.Migration.up/0`
- `test/test_helper.exs` runs `Ecto.Migrator.run(Mailglass.TestRepo, :up, all: true)` before suite
- `config/test.exs` sets `:mailglass, :repo` to `Mailglass.TestRepo`
- `.github/workflows/ci.yml` provisions Postgres service (Phase 7 task; Phase 2 may need a dev README note)

If Wave 0 skips any of these, all subsequent tests are dead.

### §L7. Ecto.Enum + metadata jsonb + Jason encoding

**Landmine:** `Ecto.Enum` stores strings in Postgres + presents atoms in Elixir. When writing to `metadata jsonb`, if a caller puts an atom in the map, `Jason` may not encode it as a string. Then reading back, `metadata["status"] == "queued"` works but `metadata["status"] == :queued` doesn't.

**Prevention:** Document in `Mailglass.Events.Event` changeset: metadata keys must be strings (use `%{"campaign_id" => "c1"}` not `%{campaign_id: "c1"}` in adopter code). Phase 2 test covers round-trip via Jason (insert event with mixed-key metadata, reload, assert key types).

## Sources

### Primary (HIGH confidence)

- **Accrue reference impl** — `~/projects/accrue/accrue/lib/accrue/events.ex` + `~/projects/accrue/accrue/priv/repo/migrations/20260411000001_create_accrue_events.exs`. Verbatim architectural template per CONTEXT.md `canonical_refs`.
- **Oban migration pattern** — `deps/oban/lib/oban/migration.ex` (read from project's vendored deps dir). Exact pattern adopted per D-35.
- **CONTEXT.md** — 43 decisions (D-01..D-43) locked upstream. This research cites them verbatim.
- **.planning/research/ARCHITECTURE.md §2, §4, §5, §7** — data flows, DDL, behaviour boundaries, boundary blocks.
- **.planning/research/PITFALLS.md MAIL-03, MAIL-07, MAIL-09, PHX-04, PHX-05** — pitfall sources.
- **.planning/research/STACK.md §1, §2** — verified Apr 2026 dep versions.
- **Ecto 3.13 docs** — `conflict_target` with partial indexes; `Ecto.Enum` type semantics; `Ecto.Changeset.optimistic_lock/3`.
- **Postgres docs** — `CREATE TRIGGER BEFORE UPDATE OR DELETE`, `CREATE FUNCTION ... LANGUAGE plpgsql`, SQLSTATE custom codes, `CREATE EXTENSION citext`, partial UNIQUE indexes.

### Secondary (MEDIUM confidence)

- **Hex.pm verification 2026-04-22** — `uuidv7 1.0.0` + `typed_ecto_schema 0.4.3` latest versions; cadence check.
- **RFC 9562** — UUIDv7 spec (May 2024 ratification) — informs D-26/D-27 Postgres 18 native upgrade path.
- **Ecto GitHub issues #3132, #3910, #2694** — cited in accrue events.ex for the `RETURNING + on_conflict: :nothing + id: nil` footgun pattern. [VERIFIED via accrue inline comment referencing these issue numbers.]

### Tertiary (LOW confidence — not used in this research)

- None — every claim above is backed by either CONTEXT.md decisions, ARCHITECTURE.md / PITFALLS.md / STACK.md files, accrue source code, Oban source code, or Ecto/Postgres docs.

## Assumptions Log

The research is highly grounded — CONTEXT.md locks 43 decisions, ARCHITECTURE.md + PITFALLS.md provide the remaining domain context, and accrue is the verbatim architectural template. The following claims are `[ASSUMED]` because they depend on information the planner or the implementation will verify:

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Phase 1's `Mailglass.Repo.transact/1` accepts a zero-arity function returning `{:ok, _}` / `{:error, _}` (confirmed by reading `lib/mailglass/repo.ex`). D-06's translation stub at line 62 can be activated by adding a `rescue Postgrex.Error` clause inside `transact/1` | Events Append API §5 | If `transact/1` doesn't have a clean translation point, D-06 requires refactoring the facade; low risk — Phase 1 STATE decision confirms the shape. |
| A2 | `Ecto.Enum` with `:utc_datetime_usec` timestamps work correctly together — no type coercion bugs | Ecto Schemas §3 | Both features are Ecto 3.13 stable; extremely low risk. |
| A3 | Postgres `citext` extension is available on the adopter's Postgres 15+ install without requiring superuser (CREATE EXTENSION citext requires the user to have CREATE privilege on the database) | Migration Strategy §2 | Most managed Postgres (RDS, Supabase, Fly.io) pre-installs citext; adopters on self-hosted may need to run `CREATE EXTENSION citext` as superuser before `mix ecto.migrate`. Phase 7 installer should flag this in migration docs. Medium risk — flag for Phase 7 planner. |
| A4 | UUIDv7 library ships a proper `Ecto.Type` implementation that round-trips cleanly to `:uuid` Postgres column | Standard Stack | [VERIFIED via `uuidv7 1.0.0` on Hex.pm; README confirms `use UUIDv7` / schema `@primary_key {:id, UUIDv7, autogenerate: true}`]. Low risk. |
| A5 | The `{:unsafe_fragment, ...}` conflict_target form in Ecto 3.13 accepts exactly the WHERE-clause shape shown — no parser quirks on parenthesization | Events Append API §5 | Documented in Ecto docs; accrue uses the pattern verbatim; low risk. |
| A6 | `Mailglass.Telemetry.events_append_span/2` pattern shape (caller returns `{:ok, result, metadata_additions}`) matches Phase 1's span helper convention (`persist_span`, `render_span` exist per Phase 1 D-27) | Events Append API §5.1.3 | Phase 2 extends Phase 1's pattern; the `render_span` example in Phase 1 SUMMARY confirms the `fn -> {:ok, result} end` 2-tuple shape — the 3-tuple return with metadata additions may need a Phase 2 patch to `Mailglass.Telemetry` to accept the extra metadata fan-out. Low-medium risk — flag for Phase 2 Plan 1 verification. |

**If the table is empty:** All claims were verified. In this research, 6 assumptions are logged; none are load-bearing scope questions (those are all resolved by CONTEXT.md D-01..D-43). A5 and A6 are the two worth the planner verifying in Plan 1's scaffolding pass.

## Open Questions

None. Every open question from ROADMAP.md + CONTEXT.md is resolved with a concrete answer above (§Open Questions Resolved Q1..Q10). The research is complete.

**Remaining Phase 2 planning micro-decisions (Claude's discretion, not open questions):**
- Exact plan decomposition (5-6 plans) — planner's responsibility.
- Field order within schema files — documented in §File Structure + CONTEXT.md Claude's Discretion.
- Test organization (unit vs integration vs property) — documented in §Validation Architecture + Wave 0 Gaps.

## Environment Availability

Phase 2 is mostly code/schema changes. External dependencies are minimal:

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| PostgreSQL | All schema work; immutability trigger; test execution | — (adopter-provided) | 15+ required (postgrex `~> 0.22`); 17+ recommended | None — Postgres-only per PROJECT.md |
| Elixir/OTP | Build + test execution | — (adopter-provided) | 1.18+ / OTP 27+ per D-06 | None — bleeding-edge floor |
| `citext` Postgres extension | `mailglass_suppressions.address` column | — (adopter-provided DB) | Any (extension in contrib since Postgres 9.1) | None — phase emits `CREATE EXTENSION IF NOT EXISTS citext` idempotently |

**Missing dependencies with no fallback:** Postgres + Elixir/OTP are required. Adopters running MySQL/SQLite cannot use mailglass (locked out-of-scope per PROJECT.md).

**Missing dependencies with fallback:**
- Oban (for `Mailglass.Oban.TenancyMiddleware` per D-33). Phase 2 already gates behind `Mailglass.OptionalDeps.Oban`; when Oban is absent, the middleware module simply doesn't compile. CI's `mix compile --no-optional-deps --warnings-as-errors` lane is the verification.

**Verification:** no Phase 2 code path requires a specific tool beyond Postgres + Elixir — all dep additions (`:uuidv7` required; `:oban` optional-gated) are in `mix.exs`. Phase 2 does not introduce any CLI binaries, native NIFs, or OS services.

## Metadata

**Confidence breakdown:**
- **Standard stack:** HIGH — all deps verified Apr 2026 via Hex.pm API; `uuidv7 1.0.0` stable since Sep 2024.
- **Architecture:** HIGH — 4-of-4 convergent from accrue/Oban/Ecto patterns; 43 locked decisions in CONTEXT.md; ARCHITECTURE.md §4 DDL verbatim.
- **Pitfalls:** HIGH — 7 pitfalls documented against established patterns, grounded in PITFALLS.md + accrue's inline footgun comments referencing Ecto issues #3132/#3910/#2694.
- **Tenancy pattern:** HIGH — accrue's `Accrue.Actor` process-dict pattern is 4-of-4 convergent; D-29/D-30 narrow the surface appropriately.
- **Migration pattern:** HIGH — Oban `lib/oban/migration.ex` is the verbatim template; adopter-facing wrapper is 8 stable lines.
- **Validation architecture:** HIGH — StreamData + Ecto Sandbox + property-per-requirement mapping covers all 8 REQ-IDs.
- **Open questions resolution:** HIGH — all 10 questions from ROADMAP.md have concrete answers tied to specific locked decisions.

**Research date:** 2026-04-22
**Valid until:** 2026-05-22 (30 days for stable ecosystem; no fast-moving deps in scope)

## RESEARCH COMPLETE

**Phase:** 2 — Persistence + Tenancy
**Confidence:** HIGH

### Key Findings

- **All 10 open questions from ROADMAP.md resolved** with concrete, decision-tied answers (§Open Questions Resolved). The planner inherits a spec, not a decision tree.
- **Accrue is the verbatim architectural template** — `lib/accrue/events.ex` → `lib/mailglass/events.ex` with name changes + UUIDv7 swap; `20260411000001_create_accrue_events.exs` → `lib/mailglass/migrations/postgres/v01.ex` with three tables + index catalog from ARCHITECTURE.md §4.
- **Oban's migration pattern is the spine** of `mix mailglass.gen.migration` — 8-line adopter wrapper, version dispatcher via `pg_class` comment, per-version DDL modules. Zero novel infrastructure.
- **D-15 rejects DB CHECK on lifecycle ordering; keeps CHECK for structural invariants** (scope/stream coupling in suppressions). The planner must not "helpfully" add lifecycle CHECK constraints.
- **UUIDv7 (`{:uuidv7, "~> 1.0"}` v1.0.0 verified Apr 2026) is the one required dep addition.** Phase 2 adds nothing else to `deps/0`; Oban stays optional-gated via Phase 1's existing `OptionalDeps.Oban` module.
- **7 concrete landmines (§L1..§L7)** documented — migration order, trigger naming, tenant nullability, RETURNING+on_conflict footgun chain, optimistic lock failure mode at Phase 2 boundary, Wave 0 test infra dependency, Ecto.Enum+jsonb encoding gotcha.
- **Validation architecture maps all 8 REQ-IDs to specific test files** + StreamData property harness for D-16 MAIL-03 convergence. ~16 test files + 1 property test module to create in Wave 0.

### File Created

`.planning/phases/02-persistence-tenancy/02-RESEARCH.md`

### Confidence Assessment

| Area | Level | Reason |
|------|-------|--------|
| Standard Stack | HIGH | `uuidv7 1.0.0` verified on Hex.pm; Ecto/Postgrex versions locked from Phase 1 STACK.md |
| Architecture | HIGH | 43 locked decisions in CONTEXT.md; accrue + Oban verbatim templates; ARCHITECTURE.md §4 DDL is the spec |
| Pitfalls | HIGH | 7 pitfalls grounded in PITFALLS.md (MAIL-03, MAIL-07, MAIL-09, PHX-04, PHX-05) + accrue inline footgun references to Ecto issues |
| Schema & DDL | HIGH | Every column, index, and constraint is spelled out with Postgres syntax + Ecto.Migration translation |
| Tenancy | HIGH | Accrue's `Accrue.Actor` pattern is 4-of-4 convergent; D-29/D-30 narrow it appropriately |
| Migration delivery | HIGH | Oban's pattern is battle-tested across 14+ versions; adopter-facing wrapper is the stable 8-line form |
| Validation architecture | HIGH | All 8 REQs mapped to test files; StreamData property shape locked by D-16 |
| Open questions resolution | HIGH | 10/10 resolved with concrete answers tied to locked decisions |

### Open Questions

None. All ROADMAP + CONTEXT open questions are answered (§Open Questions Resolved).

### Ready for Planning

Research complete. The planner can immediately decompose Phase 2 into 5–6 plans using the §File Structure layout, §Validation Architecture Wave 0 gap list, and §Schema & DDL as concrete targets. Suggested plan decomposition:

1. **Plan 02-01 — Wave 0 test infrastructure + `:uuidv7` dep + `Mailglass.Schema` macro** (enables everything else).
2. **Plan 02-02 — Migration module + V01 DDL** (ships three tables + trigger + indexes; integration test for immutability + round-trip).
3. **Plan 02-03 — Ecto schemas + changesets** (Delivery + Event + Suppression.Entry).
4. **Plan 02-04 — Tenancy behaviour + SingleTenant + `Mailglass.Oban.TenancyMiddleware`** + Config extension.
5. **Plan 02-05 — Events writer (`append` + `append_multi`) + Repo SQLSTATE translation activation + `EventLedgerImmutableError`** + telemetry spans + property test for MAIL-03 convergence.
6. **Plan 02-06 — Projector + Reconciler + SuppressionStore behaviour/Ecto + Phase-wide integration test pass.**

Planner's call on exact plan boundaries; this research delivers the full spec at the file-module level.
