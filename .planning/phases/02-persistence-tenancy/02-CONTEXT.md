# Phase 2: Persistence + Tenancy — Context

**Gathered:** 2026-04-22
**Status:** Ready for planning

<domain>
## Phase Boundary

The append-only event ledger exists, the SQLSTATE 45A01 immutability trigger fires on every `UPDATE`/`DELETE` attempt against `mailglass_events`, and `tenant_id` lives on every mailglass-owned schema so multi-tenancy is structural rather than retrofitted. At the close of Phase 2 a developer can run `mix mailglass.gen.migration` + `mix ecto.migrate` against a Phoenix 1.8 host and have three tables (`mailglass_deliveries`, `mailglass_events`, `mailglass_suppressions`) plus the immutability trigger in place, with `Mailglass.Events.append_multi/3` as the canonical event writer and `Mailglass.Tenancy.scope/2` as the query-scoping seam consumed by Phase 3+.

**8 REQ-IDs:** PERSIST-01..06 (schemas + migrations + Events writer), TENANT-01..02 (tenant_id + Tenancy behaviour). TENANT-03 (the Credo enforcement check) is Phase 6 — the behaviour surface below makes that check implementable.

**Out of scope for this phase (lands later):** Mailable behaviour and Outbound facade (Phase 3), Adapter behaviour and Fake adapter (Phase 3), RateLimiter + Suppression.check_before_send (Phase 3), Webhook plug + HMAC verification (Phase 4), Orphan reconciliation Oban worker — only the pure query functions ship here (Phase 4), Admin LiveView (Phase 5), Custom Credo checks (Phase 6), Installer (Phase 7). v0.5 items (webhook auto-add to suppression, stream-policy enforcement, mail.doctor) are further out.

</domain>

<decisions>
## Implementation Decisions

### Event writer API surface (PERSIST-05)

- **D-01:** **Dual public API** — `Mailglass.Events.append_multi(multi, name, attrs)` is the canonical path for writes paired with a domain mutation (Delivery insert, Suppression.record, webhook projection update). `Mailglass.Events.append(attrs)` is sugar that opens its own `Repo.transact/1` for standalone audit events (admin-issued suppression, tenant provisioning, `mix mail.doctor` breadcrumbs). Returns `{:ok, %Event{}}`. 4-of-4 convergent with accrue's `record/1` + `record_multi/3` pattern; solves the real ergonomic problem that roughly half of ledger writes have no companion mutation.
- **D-02:** **REQ PERSIST-05 amendment (planner owns)** — the current wording "Calling outside an `Ecto.Multi` raises an `ArgumentError`" is too strict. Amend to: "`append_multi/3` is canonical for writes accompanying domain mutations; `append/1` is sugar that wraps `Repo.transact/1` for standalone audit events. Writes via any path other than `Mailglass.Events.*` are forbidden (Phase 6 `NoRawEventInsert` Credo check)." The invariant PERSIST-05 protects — no raw `Repo.insert(%Event{})` anywhere in mailglass code — is preserved.
- **D-03:** **Idempotency replay mechanics** — `on_conflict: :nothing, conflict_target: {:unsafe_fragment, "(idempotency_key) WHERE idempotency_key IS NOT NULL"}, returning: true`. On conflict, `Repo.insert/2` returns `{:ok, %Event{id: nil}}` (documented Ecto footgun, issues [#3132](https://github.com/elixir-ecto/ecto/issues/3132) / [#3910](https://github.com/elixir-ecto/ecto/issues/3910) / [#2694](https://github.com/elixir-ecto/ecto/issues/2694)); the `append/1` path detects `id: nil` and fetches the existing row by `idempotency_key`. The `append_multi/3` path lets the caller observe it via a follow-up `Multi.run` step if they care.
- **D-04:** **Replay observability via telemetry, not return shape** — both paths emit `[:mailglass, :events, :append, :start | :stop | :exception]` spans; `:stop` metadata includes `inserted?: boolean` and `idempotency_key_present?: boolean`. Adopters get replay signal without widening the return type to `{:ok, :inserted | :duplicate, event}`. Phase 4 Webhook.Handler hooks this metadata for replay counters without a second DB query.
- **D-05:** **Auto-capture via process dict** — `append/1` reads `Mailglass.Tenancy.current/0` to stamp `tenant_id` on the event row; reads `:otel_propagator_text_map.current/0` for `trace_id` (optional, nil-tolerant). Do NOT invent an `Mailglass.Actor` module — tenant IS the actor in email infrastructure. Callers may override either by passing `:tenant_id` / `:trace_id` explicitly.
- **D-06:** **SQLSTATE 45A01 translation activates in `Mailglass.Repo.transact/1`** — the Phase 1 forward-reference stub (`lib/mailglass/repo.ex:62`) becomes live code: pattern-match `%Postgrex.Error{postgres: %{pg_code: "45A01"}}` and reraise as `Mailglass.EventLedgerImmutableError`. Both `append/1` (which wraps transact) and any adopter transact block flow through this single translation point. Never pattern-match the error message string.

### Suppression `:scope` enum + stream dimension (PERSIST-04)

- **D-07:** **`:scope ∈ :address | :domain | :address_stream`** with a nullable `stream` column (only populated when `scope = :address_stream`). Matches Postmark's per-stream suppressions API (closest precedent), matches the UNIQUE index `(tenant_id, address, scope, COALESCE(stream, ''))` both ARCHITECTURE.md §4.4 and PERSIST-04 already designed for, and covers the v0.5 DELIV-03 webhook auto-add shape without a schema migration.
- **D-08:** **`:tenant_address` atom is removed pre-GA.** Tenant scoping is structural via the `tenant_id` column + `Mailglass.Tenancy.scope/2` (enforced at lint time by Phase 6's `NoUnscopedTenantQueryInLib`), not an atom value. The atom was semantically redundant with every row already carrying `tenant_id`.
- **D-09:** **Phase 1 `Mailglass.SuppressedError` pre-GA patch (planner owns)** — `@types` becomes `[:address, :domain, :address_stream]` (from `[:address, :domain, :tenant_address]`). `docs/api_stability.md` §Errors documents: "SuppressedError `:type` atom set was refined pre-0.1.0 from `:tenant_address` → `:address_stream` to match the suppression table's scope column. No deprecation cycle owed because 0.1.0 has not shipped." D-07 of Phase 1 (closed atom set policy) permits this pre-GA revision.
- **D-10:** **`Ecto.Enum` for closed atom columns** — `scope :: :address | :domain | :address_stream`, `reason :: :hard_bounce | :complaint | :unsubscribe | :manual | :policy | :invalid_recipient`, `stream :: :transactional | :operational | :bulk` (nullable). Ecto 3.13 idiom; auto string↔atom coercion; raises on unknown values at load time. Replaces accrue's `validate_inclusion` pattern (which was pre-Ecto.Enum).
- **D-11:** **MAIL-07 "no default" preserved** — the changeset requires `:scope` explicitly; there is no DB-level default. `Mailglass.Suppressions.add/2` signature is `add(attrs, opts \\ [])` where `attrs` must include `:address`, `:reason`, `:scope`. No silent fallback to `:address`.
- **D-12:** **v0.5 webhook auto-add shape is locked** by D-07 — `:bounced` → `%{scope: :address, reason: :hard_bounce}`, `:complained` → `%{scope: :address, reason: :complaint}`, `:unsubscribed` on `:bulk` stream → `%{scope: :address_stream, stream: :bulk, reason: :unsubscribe}`. Transactional unsubscribes never happen (no List-Unsubscribe header on `:transactional` per DELIV-02).

### Delivery projection columns + status state machine (PERSIST-01)

- **D-13:** **Full 8 projection columns ship in v0.1** on `mailglass_deliveries` — `last_event_type (text, NOT NULL)`, `last_event_at (utc_datetime_usec, NOT NULL)`, `terminal (boolean, NOT NULL DEFAULT false)`, `dispatched_at`, `delivered_at`, `bounced_at`, `complained_at`, `suppressed_at` (all `utc_datetime_usec`, nullable). Plus `metadata jsonb NOT NULL DEFAULT '{}'` for adopter extensibility and `lock_version integer NOT NULL DEFAULT 1` for Phase 3 dispatch-race optimistic locking. Shipping the full set at v0.1 means v0.5 admin + adopter telemetry queries run against already-populated rows with zero backfill Oban job over a mature events ledger.
- **D-14:** **Single projector module** — `Mailglass.Outbound.Projector.update_projections/2` (takes a `%Delivery{}` + `%Event{}`, returns an `Ecto.Changeset` or a `Multi.run` function). The SAME module is used by dispatch (Phase 3), webhook ingest (Phase 4), and orphan reconciliation (Phase 4+). No projection update happens outside this module (Phase 6 candidate Credo check).
- **D-15:** **Monotonic app-level rule, no DB CHECK constraint** — the projector only sets fields to "later" values: `dispatched_at` never overwrites a non-nil value; `delivered_at` / `bounced_at` / `complained_at` / `suppressed_at` are set once and stay; `last_event_at` updates to `max(current, new)`. `terminal` flips `false → true` on `:delivered | :bounced | :complained | :rejected | :failed | :suppressed` and never flips back. Late `:opened` after `:bounced` updates `last_event_at` and records the event row but leaves `terminal` and `bounced_at` intact. Per research Q6 + ARCHITECTURE.md §4.2: CHECK constraints on lifecycle ordering are brittle because Anymail event ordering is non-monotonic in practice (providers deliver `:opened` before `:delivered` regularly).
- **D-16:** **Monotonicity proven by StreamData** — a single property test generates `N in 1..10` replay sequences of events and asserts `apply_all(sequence) == apply_all(dedup(sequence))`. This test covers MAIL-03 (webhook idempotency), D-15 (monotonicity), and exposes regressions in the projector before they reach adopters.
- **D-17:** **`metadata jsonb`** lands on all three schemas (`mailglass_deliveries`, `mailglass_events`, `mailglass_suppressions`) with `NOT NULL DEFAULT '{}'`. GIN-indexable in v0.5 without schema churn. Adopters stash campaign IDs, A/B variant tags, etc. without column migrations.
- **D-18:** **`lock_version` on `mailglass_deliveries`** ships now (not Phase 3 when the dispatch race actually manifests) — adding it later is an `ALTER TABLE` with default backfill. Optimistic locking via `Ecto.Changeset.optimistic_lock/3`; `Ecto.StaleEntryError` handled in the dispatch path with a single retry.

### Orphan webhook reconciliation in Phase 2 (partial HOOK-06)

- **D-19:** **Column + index + pure query functions in Phase 2; Oban worker in Phase 4.** `mailglass_events.needs_reconciliation boolean NOT NULL DEFAULT false` + partial index `WHERE needs_reconciliation = true`. `Mailglass.Events.Reconciler` module ships with `find_orphans/1` and `attempt_link/2` as pure Ecto query functions — no Oban dep, no scheduler, no behaviour lock-in. Phase 4 wraps these in a thin Oban worker via `Mailglass.Oban.Reconciler`.
- **D-20:** **Reconciliation cadence (Phase 4 reference)** — `{:cron, "*/15 * * * *"}` (every 15 minutes). Empirical SendGrid + Postmark p99 webhook latency is 5-30 seconds; a 15-minute sweep catches stragglers without thundering-herd on a hot events-ledger table. `@hourly` is too slow for user-visible delivery status; 5-minute is premature optimization. Adopter-triggered `mix mailglass.reconcile` surfaces in v0.5 ops UI.
- **D-21:** **`needs_reconciliation` lives only on events, not projected onto deliveries** — deliveries are mutable; the flag's lifecycle semantics (the worker sets it false after linking) would diverge from deliveries' projection semantics (monotonic). A delivery is never "waiting for itself"; the flag describes an *event* whose `delivery_id` is nullable.

### Schema typing discipline (PERSIST-01..04)

- **D-22:** **Hand-written `@type t :: %__MODULE__{...}` + plain `use Ecto.Schema`** on all three schemas. Zero new deps. Matches Phase 1's 6 error structs + `Message` struct aesthetic.
- **D-23:** **`:typed_ecto_schema` and `:typed_struct` rejected** — Elixir 1.19's native typed-struct roadmap (José Valim's Dashbit posts) makes `:typed_ecto_schema` a transitional dep whose raison d'être expires within mailglass's 5+ year framework horizon. Migrating adopters off a library-generated `Event.t()` later would be a coordinated breaking change. ~45 LOC of hand-written typespec across three schemas is cheap compared to that future migration cost.
- **D-24:** **Phase 6 candidate Credo check** — `Mailglass.Credo.EctoSchemaHasTypespec` asserts every `use Ecto.Schema` module has a matching `@type t :: %__MODULE__{...}`. Cheap AST match; obsoletes the "typespec drift" argument for `:typed_ecto_schema`.

### Primary key / ID strategy (PERSIST-01..04)

- **D-25:** **UUIDv7 everywhere via `{:uuidv7, "~> 1.0"}` required dep** (martinthenth/uuidv7 — small, pure-Elixir, stable Ecto.Type). `@primary_key {:id, UUIDv7, autogenerate: true}` + `@foreign_key_type :binary_id` on all three schemas. PERSIST-01's "id (uuidv7)" literal is honored.
- **D-26:** **`mailglass_events` uses UUIDv7 despite accrue's bigserial precedent.** Two reasons mailglass diverges: (1) mailglass events correlate to webhook-driven deliveries that are referenced by admin LiveView URLs — non-enumerability is genuinely load-bearing, and bigserial would create a Phase 5 IDOR liability; (2) D-09 multi-tenancy posture expects future shardability. UUIDv7's time-ordering recovers ~70% of the bigserial insert-speed gap (1.6× vs 9.5× for UUIDv4) — acceptable for transactional-email throughput (peaks in thousands of events/sec, not millions).
- **D-27:** **Postgres 18 migration path is free** — when adopters upgrade, `default: fragment("uuidv7()")` replaces app-layer generation with zero schema change. UUIDv7 binary representation is identical. No re-key ever.
- **D-28:** **`Mailglass.Schema` helper macro** — a tiny DRY `use Mailglass.Schema` macro stamps `@primary_key {:id, UUIDv7, autogenerate: true}`, `@foreign_key_type :binary_id`, `@timestamps_opts [type: :utc_datetime_usec]`. Three module attributes, no behaviour injection, no "magic" — consistent with Phase 1's "pluggable behaviours over magic" DNA.

### Tenancy behaviour surface (TENANT-01, TENANT-02)

- **D-29:** **Narrow callback surface: `@callback scope(queryable, context) :: Ecto.Queryable.t()`** on `Mailglass.Tenancy` behaviour. One callback, not three. The `current_scope/1 + tenant_id/1 + scope_query/2` trio from ARCHITECTURE §1.1 is not adopted — it couples core to Phoenix %Scope{} shape and violates TENANT-02's "documented but not auto-detected" constraint.
- **D-30:** **Non-callback helpers on `Mailglass.Tenancy` module** — `current/0` (reads process dict, returns `tenant_id` binary or raises `Mailglass.TenancyError` if unset on a tenanted call path), `put_current/1` (Plug/middleware stamps process dict), `with_tenant/2` (block form for tests), `tenant_id!/0` (fail-loud variant for callers that already hold context). Mirrors accrue's `Accrue.Actor` battle-tested pattern — 4-of-4 DNA convergence.
- **D-31:** **`Mailglass.Tenancy.SingleTenant` default** — returns the literal string `"default"` from `current/0` when nothing was stamped and `scope/2` is a no-op that returns the query unchanged. Single-tenant adopters need zero configuration; it's the default resolver in `Mailglass.Config`.
- **D-32:** **Phoenix 1.8 `%Scope{}` interop via documented two-liner** — adopter writes `Mailglass.Tenancy.put_current(scope.organization.id)` inside `MyAppWeb.UserAuth.on_mount/4` (or equivalent). The "Integrating with Phoenix 1.8 scopes" guide (Phase 7 DOCS-02 sibling) covers this. Core never pattern-matches on `%Phoenix.Scope{}` — host-generated struct shapes vary; mailglass stays Phoenix-agnostic at the core, idiomatic at the guides layer.
- **D-33:** **`Mailglass.Oban.TenancyMiddleware` under the optional-Oban gateway** — when `Oban` is loaded, this middleware serializes `Mailglass.Tenancy.current/0` into job args on enqueue and restores it via `put_current/1` in `perform/1`. Mitigates the process-dict-leakage risk of Option B across background boundaries. Lives in `lib/mailglass/optional_deps/oban.ex` next to the existing `Oban` gateway. Without Oban, the `Task.Supervisor` fallback path from D-07-project runs in the caller's process — tenant context is inherited naturally.
- **D-34:** **TENANT-03 Credo check implementability** — with D-29's narrow `scope/2` callback, `NoUnscopedTenantQueryInLib` becomes a pure AST match: every `Repo.*` call whose schema module is in `[Mailglass.Outbound.Delivery, Mailglass.Events.Event, Mailglass.Suppression.Entry]` must appear inside a `Mailglass.Tenancy.scope/2` wrapping call. Bypass via `scope: :unscoped` opt emits a telemetry audit event per TENANT-03.

### Migration delivery path (PERSIST-06)

- **D-35:** **Oban-style compiled DDL module, not copy-a-template.** `Mailglass.Migration` is the public API (`up/0`, `down/0`, `up(version: 2)`, `down(version: 2)`). `Mailglass.Migrations.Postgres` is the version dispatcher (tracks current applied version via `pg_class` comment, Oban pattern). `Mailglass.Migrations.Postgres.V01` holds the Phase 2 DDL — three tables, indexes, trigger function, trigger. V02 lands v0.5 schema evolution (stream-policy columns, GIN on metadata).
- **D-36:** **`mix mailglass.gen.migration` is an 8-line wrapper generator** — writes a file to `priv/repo/migrations/<timestamp>_add_mailglass.exs` containing `use Ecto.Migration; def up, do: Mailglass.Migration.up(); def down, do: Mailglass.Migration.down()`. Adopter upgrade path for v0.5: `mix mailglass.gen.migration --upgrade` generates a new wrapper calling `Mailglass.Migration.up(version: 2)`.
- **D-37:** **Phase 2 test infrastructure uses the same code path** — `test/support/test_repo.ex` + a single synthetic migration file in `priv/repo/migrations/` that calls `Mailglass.Migration.up/0` in `test/test_helper.exs`. The SQLSTATE 45A01 trigger fires in tests because it is the same trigger adopters get; zero test-only DDL fork. `assert_raise EventLedgerImmutableError, fn -> Repo.update(event) end` runs against production DDL.
- **D-38:** **Phase 7 installer composes over Phase 2's task** — `mix mailglass.install` calls `Mix.Task.run("mailglass.gen.migration", args)` + adds config wiring + generates a default mailable. Golden-diff CI (D-12 project-level) fingerprints the stable 8-line wrapper — only the timestamp prefix varies, trivially normalized.
- **D-39:** **`mailglass_inbound` sibling package (v0.5+) gets its own `MailglassInbound.Migrations`** with an independent version counter. Distinct Ecto migration timestamps = deterministic `mix ecto.migrate` order regardless of install sequence. PHX-04 migration-ordering pitfall neutralized structurally.

### `tenant_id` column type + timestamps precision (PERSIST-01..04, TENANT-01)

- **D-40:** **`tenant_id TEXT NOT NULL`** on all three schemas. Default literal `"default"` (the string) returned by `Mailglass.Tenancy.SingleTenant.current/0` when no Plug stamped anything. Honors Phase 1's locked `Message.tenant_id :: String.t() | nil`. Accepts UUID-typed / integer-typed / subdomain-slug-typed tenants without a coerce-at-boundary contract. Index-size cost (~2.25× vs native UUID column) is bounded: hot indexes prefix on low-cardinality tenant (typically <100 per deployment); Postgres 16 B-tree dedup compresses the prefix efficiently.
- **D-41:** **`timestamps(type: :utc_datetime_usec)` uniformly** on all three schemas, plus every domain timestamp column (`occurred_at`, `last_event_at`, `dispatched_at`, `delivered_at`, `bounced_at`, `complained_at`, `suppressed_at`) as `utc_datetime_usec`. Microsecond precision resolves same-millisecond webhook batches (SendGrid/Postmark routinely arrive within 1ms of each other during incident bursts). Matches accrue's 4-of-4 DNA. `Mailglass.Clock` injection round-trips cleanly — `utc_datetime` would silently truncate the usec in frozen-time tests.
- **D-42:** **Provider `occurred_at` stored at microsecond precision despite second-precision payload** — the extra digits zero-pad. Our microsecond `inserted_at` (controlled by `Mailglass.Clock`) orders the ledger; provider clocks are advisory. Admin UI and telemetry both read `inserted_at` as truth.
- **D-43:** **Phase 6 candidate Credo check** — `Mailglass.Credo.TimestampsUsecRequired` asserts every `timestamps/1` call in mailglass code uses `type: :utc_datetime_usec`. One AST rule, prevents drift.

### Claude's Discretion

- **Exact field order in schema files** — follow accrue's pattern (identifier columns → tenant_id → foreign keys → state columns → metadata/flags → timestamps at bottom).
- **Migration naming** — `priv/repo/migrations/00000000000001_mailglass_init.exs` for the synthetic Phase 2 test migration; adopter-facing migration naming is `<timestamp>_add_mailglass.exs` (the filename the `gen.migration` task produces).
- **Index names** — use the ARCHITECTURE.md §4.2 / §4.3 / §4.4 names verbatim (`mailglass_deliveries_provider_msg_id_idx`, `mailglass_events_idempotency_key_idx`, etc.) so they're grep-able and stable across versions.
- **Exact changeset validation order** in `Mailglass.Events.Event.changeset/1` — mirror accrue's cast → validate_required → validate_inclusion / Ecto.Enum narrowing pattern.
- **Telemetry emit granularity** — `[:mailglass, :events, :append, :*]` spans at write time; `[:mailglass, :persist, :delivery, :update_projections, :*]` for the projector; `[:mailglass, :persist, :reconcile, :link, :*]` when the (Phase-4-owned) worker attempts a link via Phase 2's pure functions. Metadata keys drawn only from the Phase 1 whitelist (D-31 of Phase 1).
- **`mailglass_suppressions.source TEXT` column values** — follow ARCHITECTURE §4.4 convention (`"webhook:postmark"`, `"admin:user_id=..."`, `"auto"`). Not enforced as an enum — this is a human-readable audit breadcrumb, not a filterable column.
- **`Mailglass.SuppressionStore` behaviour callbacks** — at minimum `check/2` and `record/1`; others land in Phase 3 when Outbound.preflight calls into the behaviour. Phase 2 ships only the Ecto impl; Phase 3 adds an ETS impl for test speed.

### Folded Todos

None — no pending todos matched Phase 2.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project locked context

- `.planning/PROJECT.md` — Key Decisions D-01..D-20 (project-level, pre-existing, locked). Most load-bearing for Phase 2: D-06 (bleeding-edge floor), D-09 (multi-tenancy first-class), D-13 (Fake adapter as release gate — forward reference), D-14 (Anymail taxonomy verbatim), D-15 (append-only events table + SQLSTATE 45A01 trigger).
- `.planning/REQUIREMENTS.md` — §Persistence (PERSIST-01..06), §Multi-Tenancy (TENANT-01..02, forward-ref TENANT-03), §Tracking & Privacy (TRACK-01 forward-ref). The 8 REQ-IDs delivered by Phase 2.
- `.planning/ROADMAP.md` — Phase 2 success criteria (5 checks), depends on Phase 1, pitfalls guarded against (MAIL-03, MAIL-07, MAIL-09, PHX-04, PHX-05 partial).
- `.planning/STATE.md` — current position; Phase 1 complete 2026-04-22.

### Phase 1 artifacts Phase 2 consumes

- `.planning/phases/01-foundation/01-CONTEXT.md` — D-01..D-33 from Phase 1; most load-bearing for Phase 2: D-27 (`Mailglass.Telemetry` surface with `persist_span` / `events_append_span` landing in Phase 2), D-30 (4-level event path convention), D-31 (metadata whitelist — PII-free columns on projections must flow cleanly into this).
- `docs/api_stability.md` — locks SuppressedError `:type` atom set + Telemetry event catalog + Mailglass.Adapter return shape (forward-ref to Phase 3). **Phase 2 edits §Errors** (SuppressedError pre-GA patch per D-09 above) and **extends §Telemetry** with the new spans.
- `lib/mailglass/repo.ex:62` — the SQLSTATE 45A01 translation stub activated by D-06.
- `lib/mailglass/idempotency_key.ex` — Phase 1 ships sanitized keys (512-byte cap, ASCII-only). Phase 2 consumes these via the `Mailglass.Events.append_multi/3` path.
- `lib/mailglass/message.ex` — `Message.tenant_id :: String.t() | nil`, `Message.stream :: :transactional | :operational | :bulk`. Phase 2 schemas match these types (D-40 + D-10).
- `lib/mailglass/errors/suppressed_error.ex` — **Phase 1 artifact patched by D-09** (`:tenant_address` → `:address_stream`).
- `lib/mailglass/config.ex` — Phase 2 extends the NimbleOptions schema with `:tenancy` (behaviour module) and `:suppression_store` (behaviour module) slots.
- `lib/mailglass/telemetry.ex` — Phase 2 adds `persist_span/3` and `events_append_span/3` helpers per Phase 1 D-27 convention.
- `lib/mailglass/optional_deps/oban.ex` — Phase 2 **extends** with `Mailglass.Oban.TenancyMiddleware` per D-33.

### Research synthesis

- `.planning/research/SUMMARY.md` §"Phase 2: Persistence + Immutability" + Q5 (`:typed_struct` adoption), Q6 (status state machine), and the "Research Flags" table. Phase 2 sits in the MEDIUM research bucket; this CONTEXT.md closes all open questions flagged there.
- `.planning/research/ARCHITECTURE.md` §2.1 (hot-path data flow; informs projection updates), §2.3 (failure modes + `lock_version` justification), §4.1 (schema conventions — binary_id, timestamps_usec, tenant_id TEXT, metadata jsonb), §4.2 (`mailglass_deliveries` DDL + indexes), §4.3 (`mailglass_events` DDL + immutability trigger), §4.4 (`mailglass_suppressions` DDL — the UNIQUE index that D-07 honors), §4.6 (status state machine = app-enforced recommendation), §5 (behaviour boundaries — `Mailglass.Tenancy` + `Mailglass.SuppressionStore`), §7 (boundary blocks for `Mailglass.Events` ↛ `Mailglass.Outbound`).
- `.planning/research/PITFALLS.md` — MAIL-03 (idempotency end-to-end; covered by D-03 + D-16), MAIL-07 (suppression scope; covered by D-07..D-12), MAIL-09 (provider_message_id collision; covered via `(provider, provider_message_id) WHERE provider_message_id IS NOT NULL` UNIQUE on deliveries), PHX-04 (cross-package migration ordering; covered by D-39), PHX-05 partial (tenant scope; covered by D-29..D-34, full enforcement Phase 6).
- `.planning/research/STACK.md` §Required Deps (verify `{:uuidv7, "~> 1.0"}` does not conflict with the pinned version set) + §Optional Deps + §`mix compile --no-optional-deps` lane.

### Engineering DNA + domain language

- `prompts/mailglass-engineering-dna-from-prior-libs.md` §3.6 (append-only ledger; `Multi`-invariant for every mutation; accrue's canonical pattern), §3.8 (`binary_id` + `utc_datetime_usec` + `metadata jsonb` schema conventions), §2.4 (errors as public API contract — informs SQLSTATE 45A01 translation in D-06), §2.7 (test pyramid — StreamData property test for MAIL-03 in D-16).
- `prompts/mailer-domain-language-deep-research.md` §12 ("facts first, summaries second" — informs full 8 projection columns in D-13), §13 (canonical nouns: Delivery, Event, Suppression), §16 (status as projection, not authoritative state), §525-554 (four scope examples including "tenant + stream + address" — informs D-07).
- `prompts/ecto-best-practices-deep-research.md` §6.2 (DB-enforced correctness only for true invariants — informs D-15 rejection of lifecycle CHECK constraints).

### Accrue reference implementation (sibling-constraint + prior-art)

- `~/projects/accrue/accrue/lib/accrue/events.ex` — `record/1` + `record_multi/3` dual API; process-dict actor/trace_id capture; `on_conflict: :nothing` + `id: nil` + manual fetch for idempotency replay; `pg_code: "45A01"` pattern-match for immutability re-raise. Mailglass diverges only in function names (`append` not `record`) and ID type (UUIDv7 not bigserial).
- `~/projects/accrue/accrue/lib/accrue/events/event.ex` — Ecto.Schema shape for the event row; changeset discipline. Reference but not verbatim — mailglass schema carries mailglass-specific columns (`delivery_id`, `idempotency_key`, `raw_payload`, `normalized_payload`, `needs_reconciliation`).
- `~/projects/accrue/accrue/priv/repo/migrations/20260411000001_create_accrue_events.exs` — the SQLSTATE 45A01 trigger migration **pattern**. Phase 2 adopts the DDL verbatim except for renamed function/trigger: `mailglass_raise_immutability()` + `mailglass_events_immutable` trigger.
- `~/projects/accrue/accrue/lib/accrue/actor.ex` — process-dict pattern that D-30 mirrors for `Mailglass.Tenancy.current/0` / `put_current/1` / `with_tenant/2`.
- `~/projects/accrue/accrue/test/test_helper.exs` — TestRepo bootstrap pattern D-37 mirrors.

### Oban reference (migration delivery pattern)

- `deps/oban/lib/oban/migration.ex` — the public API contract D-35 mirrors: `up/0`, `down/0`, `up(version:)`.
- `deps/oban/lib/oban/migrations/postgres.ex` — version tracking via `pg_class` comment.
- `deps/oban/lib/oban/migrations/postgres/v01.ex` (and v02..v14) — per-version DDL modules. Phase 2 ships V01 only.

### External standards

- RFC 5322 + RFC 8058 (forward-ref, v0.5).
- Anymail event taxonomy — https://anymail.dev/en/stable/sending/tracking/ — event types used in `Event.type` (Ecto.Enum) per D-14 project-level. Phase 2 stores the atoms; Phase 4 maps provider events into them.
- Postmark Suppressions API + SendGrid Suppression Groups + Mailgun Suppressions + AWS SES Account-Level Suppression List — spiritual precedents for D-07's per-stream scope.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets (Phase 1 shipped)

- **`Mailglass.Repo.transact/1`** (`lib/mailglass/repo.ex`) — facade resolving to host-configured `Ecto.Repo`. Phase 2 activates the SQLSTATE 45A01 translation stub at line 62 (D-06).
- **`Mailglass.IdempotencyKey.for_webhook_event/2` + `for_provider_message_id/2`** (`lib/mailglass/idempotency_key.ex`) — sanitized keys with 512-byte cap. Phase 2 consumes these in `Events.append_multi/3` and the `(tenant_id, provider_message_id)` UNIQUE index relies on the sanitizer keeping the keys clean.
- **`Mailglass.Message`** (`lib/mailglass/message.ex`) — locks `tenant_id :: String.t() | nil` and `stream` enum. Phase 2 column types match.
- **`Mailglass.Config`** (`lib/mailglass/config.ex`) — NimbleOptions schema, the sole legitimate caller of `Application.compile_env*` per Phase 1 D-26. Phase 2 adds `:tenancy` (atom / behaviour module) and `:suppression_store` (atom / behaviour module) options.
- **`Mailglass.Telemetry`** (`lib/mailglass/telemetry.ex`) — span helpers per Phase 1 D-27. Phase 2 adds `persist_span/3` and `events_append_span/3`; reuses the existing metadata whitelist from Phase 1 D-31.
- **`Mailglass.Error` + `Mailglass.SuppressedError`** (`lib/mailglass/error.ex`, `lib/mailglass/errors/suppressed_error.ex`) — struct hierarchy with closed `:type` atom sets. Phase 2 patches SuppressedError `:type` (D-09) and introduces `Mailglass.EventLedgerImmutableError` as a new struct with `:type ∈ :update_attempt | :delete_attempt` following the same `defexception` + `@behaviour Mailglass.Error` pattern.
- **`Mailglass.OptionalDeps.Oban`** (`lib/mailglass/optional_deps/oban.ex`) — gateway pattern. Phase 2 adds `Mailglass.Oban.TenancyMiddleware` as an additional export behind the same `available?/0` gate.

### Established Patterns (from Phase 1)

- **Closed atom sets with `__types__/0` + `api_stability.md` cross-check test** — Phase 2 Event type atoms (the Anymail taxonomy) and Suppression scope atoms follow this pattern.
- **`defp sanitize` + boundary normalization** — Phase 2 suppression addresses normalize to lowercase via `citext` column + changeset `downcase` step.
- **Boundary blocks** — Phase 1 ships `Mailglass` root boundary with `deps: []`. Phase 2 adds sub-boundaries: `Mailglass.Events` (deps: `Mailglass.Repo`, `Mailglass.Telemetry`, `Mailglass.Error`, `Mailglass.IdempotencyKey`; notably NOT `Mailglass.Outbound` per ARCHITECTURE §7), `Mailglass.Tenancy` (deps: `Mailglass.Config`, `Mailglass.Error`).
- **`mix compile --no-optional-deps --warnings-as-errors`** CI lane — Phase 2 must continue passing. The `Mailglass.Oban.TenancyMiddleware` sits behind the existing Oban gateway; the `:uuidv7` dep is REQUIRED (not optional), so it's always compiled.

### Integration Points

- **`mix.exs` required deps** — Phase 2 adds `{:uuidv7, "~> 1.0"}`. Verify this does not conflict with `:ecto_sql ~> 3.13` + `:phoenix ~> 1.8` resolution.
- **`config/config.exs` + `config/test.exs`** — Phase 2 adds `:tenancy` (defaults to `Mailglass.Tenancy.SingleTenant`), `:suppression_store` (defaults to `Mailglass.SuppressionStore.Ecto`).
- **`test/support/test_repo.ex`** — new file. Mailglass's own test Repo; configured in `config/test.exs` as `:repo`. Phase 1 tests use `Mailglass.Repo` facade with no repo configured (facade raises ConfigError); Phase 2 flips this by configuring `Mailglass.TestRepo` in `:test`.
- **`priv/repo/migrations/00000000000001_mailglass_init.exs`** — new file, synthetic migration calling `Mailglass.Migration.up/0`. Runs in `test/test_helper.exs` via `Ecto.Migrator.run/4`.
- **Phase 3 hook points** — `Mailglass.Outbound` (Phase 3) depends on `Mailglass.Events.append_multi/3`, `Mailglass.Outbound.Projector.update_projections/2`, `Mailglass.Tenancy.scope/2`, `Mailglass.Suppression.check_before_send/1` (Phase 3 adds the public function, Phase 2 ships the underlying SuppressionStore).
- **Phase 4 hook points** — `Mailglass.Webhook.Plug` (Phase 4) depends on `Mailglass.Events.append_multi/3`, `Mailglass.Events.Reconciler.attempt_link/2`, `Mailglass.Outbound.Projector.update_projections/2`. All three ship in Phase 2; Phase 4 wraps them in the 3-line webhook Multi.

</code_context>

<specifics>
## Specific Ideas

- **Accrue is the ancestral library.** Mailglass's event ledger is a near-twin of accrue's (same trigger name pattern, same dual writer API, same process-dict capture). Divergence points are deliberate and documented: UUIDv7 not bigserial (D-25/26), `append` not `record` (naming honors PERSIST-05's verb), `Mailglass.Tenancy` not `Accrue.Actor` (tenant-centric, not actor-centric — email infra doesn't have a meaningful "admin" vs "user" vs "system" actor taxonomy).
- **Oban is the migration-delivery ancestor.** `Mailglass.Migration.up(version: N)` is the Oban wrapper pattern verbatim. Forever-stable 8-line adopter migration; version counter lives in `pg_class` comment.
- **Postmark's per-stream suppression API is the suppression-scope ancestor.** `:address_stream + stream` column mirrors Postmark's data model exactly.
- **`Phase 6 candidate Credo checks`** recorded from Phase 2 decisions (planner should flag these for Phase 6):
  1. `Mailglass.Credo.NoRawEventInsert` — raw `Repo.insert(%Event{})` or `Repo.insert_all("mailglass_events", ...)` flagged (D-02).
  2. `Mailglass.Credo.EctoSchemaHasTypespec` — every `use Ecto.Schema` in mailglass code has `@type t :: %__MODULE__{...}` (D-24).
  3. `Mailglass.Credo.TimestampsUsecRequired` — every `timestamps/1` uses `type: :utc_datetime_usec` (D-43).
  4. `Mailglass.Credo.NoProjectorOutsideOutbound` — only `Mailglass.Outbound.Projector.update_projections/2` writes to delivery projection columns (D-14).
  These complement the 12 LINT-01..LINT-12 checks already in REQUIREMENTS.md.
- **StreamData convergence test shape** (informs the planner's test decomposition of D-16):
  ```
  property "applying N replays of a sequence converges to applying each unique event once" do
    check all events <- list_of(event_generator(), min_length: 1, max_length: 20),
              replays <- integer(1..10) do
      fresh = apply_all(events)
      replayed = apply_all(List.duplicate(events, replays) |> List.flatten() |> Enum.shuffle())
      assert projection(fresh) == projection(replayed)
    end
  end
  ```
- **`EventLedgerImmutableError` struct shape** (D-06 translation target):
  ```elixir
  defmodule Mailglass.EventLedgerImmutableError do
    @behaviour Mailglass.Error
    @types [:update_attempt, :delete_attempt]
    @derive {Jason.Encoder, only: [:type, :message, :context]}
    defexception [:type, :message, :cause, :context]
    # follows the Phase 1 D-01..D-09 error-struct pattern verbatim
  end
  ```
- **Suppression lookup predicate** for Phase 3 preflight (not shipped in Phase 2, but the index shape must support it):
  ```sql
  SELECT 1 FROM mailglass_suppressions
  WHERE tenant_id = $tenant_id
    AND (
      (scope = 'address' AND address = $recipient) OR
      (scope = 'domain' AND address = $recipient_domain) OR
      (scope = 'address_stream' AND address = $recipient AND stream = $stream)
    )
    AND (expires_at IS NULL OR expires_at > now())
  LIMIT 1
  ```
  The existing UNIQUE index `(tenant_id, address, scope, COALESCE(stream, ''))` serves (scope, address) lookups; an additional `(tenant_id, address)` btree may be added in Phase 3 for the OR-union query planner — not required in Phase 2.

</specifics>

<deferred>
## Deferred Ideas

- **Orphan reconciliation Oban worker** — Phase 4. Phase 2 ships only the pure query functions (`find_orphans/1`, `attempt_link/2`) per D-19. Cadence (`*/15 * * * *` cron) is locked in D-20 but implemented in Phase 4.
- **`:pg`-coordinated / multi-node tenancy** — v0.5+. Phase 2's process-dict pattern (D-30) is correct for v0.1 single-node; multi-node coordination (e.g., per-tenant rate-limiter consensus) is explicitly deferred to v0.5 with a real benchmark (ARCHITECTURE §3.3 flags this).
- **Full `current_scope/1 + tenant_id/1 + scope_query/2` Tenancy trio** — not adopted (D-29). If Phase 3 Outbound pressures arise for more callbacks, revisit then. The single `scope/2` + process-dict helpers suffice for v0.1.
- **`:typed_ecto_schema` / `:typed_struct`** — rejected (D-23). Elixir 1.19 native typed structs will obviate. Revisit post-v1.0 if typespec drift becomes a real pain point.
- **GIN index on `metadata jsonb`** — v0.5 when adopter usage justifies the write-side cost. Phase 2 ships the column + `NOT NULL DEFAULT '{}'` (D-17) so adding the index later is a single migration with no schema change.
- **Webhook auto-add to suppressions** — v0.5 DELIV-03. Phase 2 ships the suppression schema + scope shape (D-07, D-12 locks the auto-add write shape ahead of time); the writer lives in the v0.5 webhook handler.
- **Soft-bounce escalation rule (5 bounces in 7 days → hard suppress)** — v0.5 DELIV-03. Phase 2 has no bounce counter.
- **Cluster-coordinated rate-limiting** — v0.5+ (ARCHITECTURE §3.3). Phase 3 ships ETS-backed single-node rate-limiter.
- **Materialized rollup views** — v0.5+ when volume justifies. The 8 projection columns (D-13) cover admin queries through v1.0.
- **`Mailglass.SuppressionStore.ETS` / `.Redis` impls** — v0.5+. Phase 2 ships the behaviour + Ecto default; Phase 3 may add an ETS impl for test speed (Claude's discretion).
- **Per-tenant adapter resolver** — v0.5 DELIV-07. Phase 2's Tenancy behaviour surface doesn't preclude it; the v0.5 work plugs into the same `current/0` + `scope/2` shape.
- **Postgres 18 server-side `uuidv7()` default** — adopter-owned once they upgrade PG. D-27 documents the zero-schema-change migration path; mailglass never forces the switch.

### Reviewed Todos (not folded)

None — no pending todos matched Phase 2.

</deferred>

---

*Phase: 02-persistence-tenancy*
*Context gathered: 2026-04-22*
