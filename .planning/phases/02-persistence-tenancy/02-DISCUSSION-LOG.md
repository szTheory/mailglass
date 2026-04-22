# Phase 2: Persistence + Tenancy — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `02-CONTEXT.md` — this log preserves the alternatives considered
> and the research backing each choice.

**Date:** 2026-04-22
**Phase:** 02-persistence-tenancy
**Areas discussed:** Event writer API; Suppression `:scope` enum; Delivery projection columns + status state machine; Orphan reconciliation; `:typed_struct` / `:typed_ecto_schema`; ID strategy; Tenancy behaviour surface; Migration delivery path; `tenant_id` type + timestamps precision.

---

## Area selection

**Question:** Which areas do you want to discuss for Phase 2 (Persistence + Tenancy)?

| Option | Description | Selected |
|--------|-------------|----------|
| Event writer API surface | Multi-only (PERSIST-05 literal) vs dual record/record_multi (accrue precedent); idempotency replay fallback shape | ✓ |
| Suppression `:scope` enum + stream dimension | `:tenant_address` vs `:address_stream` + separate stream column; ship per-stream in v0.1 or defer to v0.5 | ✓ |
| Projection columns + status state machine | Full 8 projection fields vs minimal; app-enforced vs hybrid CHECK vs unconstrained | ✓ |
| Orphan reconciliation + `:typed_struct` decisions | Column+index only vs worker stub now; `:typed_ecto_schema` vs hand-written @type specs | ✓ |

**User direction:** Research each via subagents — pros/cons/tradeoffs, Elixir/Plug/Ecto/Phoenix idioms, lessons from popular libs in the space (including other languages), coherent cross-area recommendations, dev-UX emphasized.

---

## Area 1 — Event writer API surface

**Research agent:** `gsd-advisor-researcher` (Sonnet, quality profile).

### Options considered

| Option | Description | Selected |
|--------|-------------|----------|
| A. Multi-only `append(multi, name, attrs)` (literal PERSIST-05) | Strictest REQ reading. Every caller builds an `Ecto.Multi` even for one-row writes. | |
| B. Dual `append/1` + `append_multi/3` (accrue-parity) | `append_multi/3` canonical for writes paired with domain mutations; `append/1` sugar wrapping `Repo.transact/1` for standalone audit events. | ✓ |
| C. Opaque `changeset_for/1` returning a changeset | Caller chooses `Multi.insert` vs `Repo.insert`; externalizes idempotency fallback. | |
| D. Dual API with explicit replay tuple `{:ok, :inserted, event} \| {:ok, :duplicate, event}` | Wider return shape for replay observability. | |

**User's choice:** B (adopted). Replay observability handled via telemetry `inserted?: boolean` metadata (D-04) rather than widening the return shape (Option D).

**Notes:** REQ PERSIST-05 wording needs a one-line amendment ("`append_multi/3` is canonical; `append/1` is sugar wrapping `Repo.transact/1`") — flagged to planner as a required breadcrumb. SQLSTATE 45A01 translation lives inside `Mailglass.Repo.transact/1` (Phase 1 forward-reference stub activates). Idempotency mechanics: `on_conflict: :nothing` + `id: nil` sentinel + manual fetch (Ecto footgun issues [#3132](https://github.com/elixir-ecto/ecto/issues/3132), [#3910](https://github.com/elixir-ecto/ecto/issues/3910), [#2694](https://github.com/elixir-ecto/ecto/issues/2694)).

**Sources cited:** [Ecto Constraints and Upserts](https://hexdocs.pm/ecto/constraints-and-upserts.html), [Ecto.Multi docs](https://hexdocs.pm/ecto/Ecto.Multi.html), [Commanded.EventStore](https://hexdocs.pm/commanded/Commanded.EventStore.html), Peter Ullrich's [Upserts with Ecto guide](https://peterullrich.com/complete-guide-to-upserts-with-ecto), accrue reference at `~/projects/accrue/accrue/lib/accrue/events.ex`.

---

## Area 2 — Suppression `:scope` enum + stream dimension

**Research agent:** `gsd-advisor-researcher` (Sonnet, quality profile).

### Options considered

| Option | Description | Selected |
|--------|-------------|----------|
| A. Keep Phase-1 `:address \| :domain \| :tenant_address`; no stream column | SuppressedError unchanged; smallest v0.1 surface. | |
| B. `:address \| :domain \| :address_stream` + nullable stream column; pre-GA patch SuppressedError | Matches Postmark precedent; UNIQUE index already designed for it; drops redundant `:tenant_address`. | ✓ |
| C. Minimum `:address \| :domain`; defer per-stream to v0.5 | Strictly smallest v0.1; v0.5 ships column + atom + webhook writer together. | |
| D. Encode stream INTO atom (`:address_bulk`, `:address_transactional`) | No stream column; cartesian atom explosion. | |

**User's choice:** B (adopted). `:tenant_address` is semantically redundant once `tenant_id` is on every row; tenant scoping is structural via `Mailglass.Tenancy.scope/2`, not an atom value. Pre-GA patch to `lib/mailglass/errors/suppressed_error.ex` (remove `:tenant_address`, add `:address_stream`) flagged to planner — permissible per Phase 1 D-07's closed-atom-set rules while pre-0.1.0.

**Notes:** `Ecto.Enum` replaces accrue's `validate_inclusion` (Ecto 3.13 idiom). MAIL-07 "no default" preserved — changeset requires `:scope` explicitly. v0.5 DELIV-03 webhook auto-add shapes locked: `:bounced` → `%{scope: :address, reason: :hard_bounce}`, `:complained` → `%{scope: :address, reason: :complaint}`, `:unsubscribed` on `:bulk` → `%{scope: :address_stream, stream: :bulk, reason: :unsubscribe}`.

**Sources cited:** [Postmark Suppressions API](https://postmarkapp.com/developer/api/suppressions-api), [SendGrid Suppression Groups](https://docs.sendgrid.com/for-developers/sending-email/suppressions), [AWS SES Account-Level Suppression List](https://docs.aws.amazon.com/ses/latest/dg/sending-email-suppression-list.html), [Mailgun Suppressions](https://help.mailgun.com/hc/en-us/articles/360012287493), `prompts/mailer-domain-language-deep-research.md` §150-170, §525-554.

---

## Area 3 — Delivery projection columns + status state machine

**Research agent:** `gsd-advisor-researcher` (Sonnet, quality profile).

### Options considered

| Option | Description | Selected |
|--------|-------------|----------|
| A. Full 8 columns + app-enforced monotonic projector + `lock_version` + `metadata jsonb` | Ship complete in v0.1; zero backfill in v0.5. | ✓ |
| B. Minimal 3 columns (`last_event_type, last_event_at, terminal`) + defer rest to v0.5 | Smallest Phase 2 surface; backfill Oban job required in v0.5. | |
| C. Full 8 + hybrid `terminal` CHECK constraint | DB-enforces one bug class; brittle on future terminal-set changes. | |
| D. Full 8, unconstrained (callers own monotonicity) | Violates engineering DNA; MAIL-03 unprovable. | |

**User's choice:** A (adopted). Pay schema cost when data volume is lowest; v0.5 admin queries run on already-populated rows. Monotonic rule (only set to "later" values; `terminal` flips once) enforced in `Mailglass.Outbound.Projector.update_projections/2` — single write path shared by dispatch, webhook ingest, and reconciliation. StreamData convergence test proves `apply_N(events) == apply_once(dedup(events))`.

**Notes:** `terminal = true` on `:delivered | :bounced | :complained | :rejected | :failed | :suppressed`. Late `:opened` after `:bounced` updates `last_event_at` but leaves `terminal` and `bounced_at` intact. `lock_version` ships now (not Phase 3) — adding later is `ALTER TABLE` with default backfill. `metadata jsonb NOT NULL DEFAULT '{}'` on all three schemas; GIN-indexable in v0.5 without schema churn.

**Sources cited:** [Anymail Tracking](https://anymail.dev/en/stable/sending/tracking/), `prompts/mailer-domain-language-deep-research.md` §12 ("facts first, summaries second") + §16 ("status as projection"), `prompts/ecto-best-practices-deep-research.md` §6.2, ARCHITECTURE.md §2.3 + §4.2 + §4.6.

---

## Area 4 — Orphan reconciliation + `:typed_struct` decisions

**Research agent:** `gsd-advisor-researcher` (Sonnet, quality profile).

### 4a. Orphan reconciliation options

| Option | Description | Selected |
|--------|-------------|----------|
| A. Column + partial index only (no code) | Smallest Phase 2; schema inert until Phase 4. | |
| B. Column + index + stub `Reconciler` raising `NotImplementedError` | Publishes contract shape early; stubs-that-raise violate error discipline. | |
| C. Column + index + pure query functions (no Oban, no scheduling) | Phase 2 owns the SQL; Phase 4 wraps in Oban worker. | ✓ |
| D. Defer everything to Phase 4 | Post-release schema migration; violates "shape locked at v0.1". | |

**User's choice:** C (adopted). `Mailglass.Events.Reconciler.find_orphans/1` + `attempt_link/2` ship as pure Ecto query functions in Phase 2. Phase 4 wraps in thin Oban worker with `{:cron, "*/15 * * * *"}` cadence (empirical SendGrid/Postmark p99 = 5-30s; 15min catches stragglers without thunder). `needs_reconciliation` lives only on events, not projected onto deliveries.

### 4b. `:typed_struct` / `:typed_ecto_schema` options

| Option | Description | Selected |
|--------|-------------|----------|
| A. Hand-written `@type t :: %__MODULE__{...}` + plain `use Ecto.Schema` | Zero new deps; matches Phase 1. | ✓ |
| B. `:typed_ecto_schema` | Actively maintained (v0.4.3, Jun 2025); 26 dependants. Transitional dep per Elixir 1.19 roadmap. | |
| C. `:typed_struct` | Last release Feb 2022; not Ecto-aware — wrong tool. | |
| D. Internal `Mailglass.Schema` macro reflecting fields into types | Owns destiny; metaprogramming tax; violates "no magic". | |

**User's choice:** A (adopted). Elixir 1.19 native typed structs will obviate `:typed_ecto_schema`; 5+ year framework horizon wants neutrality. ~45 LOC of typespec across 3 schemas is cheap. Phase 6 Credo check candidate: `Mailglass.Credo.EctoSchemaHasTypespec`.

**Sources cited:** [typed_struct](https://hex.pm/packages/typed_struct), [typed_ecto_schema](https://hex.pm/packages/typed_ecto_schema), [José Valim set-theoretic types](https://elixir-lang.org/blog/2022/10/05/my-future-with-elixir-set-theoretic-types/), [Dashbit data evolution blog](https://dashbit.co/blog/data-evolution-with-set-theoretic-types), [Stripe webhook reliability docs](https://docs.stripe.com/webhooks), [Anymail](https://anymail.dev/).

---

## Discretion-item selection (round 2)

**Question:** Which Claude's-Discretion item do you want to turn into a real decision?

| Option | Description | Selected |
|--------|-------------|----------|
| ID strategy (UUIDv7 vs alternatives) | | ✓ |
| Tenancy behaviour surface | | ✓ |
| Migration delivery path (Phase 2 vs Phase 7) | | ✓ |
| `tenant_id` column type + timestamps precision | | ✓ |

All four selected; same research-subagent treatment applied.

---

## Area 5 — Primary key / ID strategy

**Research agent:** `gsd-advisor-researcher` (Sonnet, quality profile).

### Options considered

| Option | Description | Selected |
|--------|-------------|----------|
| A. UUIDv7 everywhere via `:uuidv7` hex dep | Time-ordered; globally unique; no IDOR; PERSIST-01 literal. | ✓ |
| B. UUIDv4 everywhere | Zero deps; 9.5× slower inserts at 20M rows due to fragmentation. | |
| C. Mixed: bigserial events + UUIDv7 deliveries/suppressions | Matches accrue events precedent; cognitive overhead. | |
| D. Bigserial everywhere | Fastest inserts; IDOR liability on admin URLs disqualifies. | |

**User's choice:** A (adopted). Divergence from accrue's bigserial-for-events is deliberate: mailglass events reference deliveries visible in admin URLs (IDOR risk), and D-09 multi-tenancy wants shardability. UUIDv7 recovers ~70% of the bigserial insert gap (1.6× vs 9.5× for UUIDv4). Postgres 18 migration path: `fragment("uuidv7()")` replaces app-layer generation with zero schema change when adopters upgrade. Add `{:uuidv7, "~> 1.0"}` as required dep.

**Notes:** `Mailglass.Schema` helper macro (D-28) stamps `@primary_key {:id, UUIDv7, autogenerate: true}` + `@foreign_key_type :binary_id` + `@timestamps_opts [type: :utc_datetime_usec]` across the three schemas — no magic, just shared module attributes.

**Sources cited:** [Ecto.UUID v3.13](https://hexdocs.pm/ecto/Ecto.UUID.html), [martinthenth/uuidv7](https://github.com/martinthenth/uuidv7), [ryanwinchester/uuidv7](https://github.com/ryanwinchester/uuidv7), [UUIDv7 vs bigserial benchmarks (Medium, 2025)](https://medium.com/@jamauriceholt.com/uuid-v7-vs-bigserial-i-ran-the-benchmarks-so-you-dont-have-to-44d97be6268c), [UUID Benchmark War](https://ardentperf.com/2024/02/03/uuid-benchmark-war/), [Andy Atkinson — Avoid UUIDv4 PKs](https://andyatkinson.com/avoid-uuid-version-4-primary-keys), [Postgres 18 uuidv7()](https://aiven.io/blog/exploring-postgresql-18-new-uuidv7-support), [Moroz — UUIDv6/v7 as Ecto PK](https://moroz.dev/blog/using-uuidv6-or-v7-as-primary-key-in-ecto/). accrue reference migrations at `~/projects/accrue/accrue/priv/repo/migrations/`.

---

## Area 6 — Tenancy behaviour surface

**Research agent:** `gsd-advisor-researcher` (Sonnet, quality profile).

### Options considered

| Option | Description | Selected |
|--------|-------------|----------|
| A. Minimal `scope/2` only | Smallest callback surface; forces explicit threading at every call site. | |
| B. accrue-style `current/0` + `scope/2` + helper module | Process-dict auto-capture; mirrors `Accrue.Actor`; 4-of-4 DNA match. | ✓ |
| C. Full trio `current_scope/1 + tenant_id/1 + scope_query/2` | Over-specifies; couples core to Phoenix %Scope{} shape. | |
| D. Phoenix-native: accept `%Phoenix.Scope{}` directly | Violates TENANT-02 "documented but not auto-detected"; host-generated struct shape varies. | |

**User's choice:** B (adopted). One callback (`scope/2`) on the behaviour; non-callback helpers `current/0 / put_current/1 / with_tenant/2 / tenant_id!/0` on `Mailglass.Tenancy` module read/write process dict. Adopter wires a Plug that calls `Mailglass.Tenancy.put_current(scope.organization.id)` — documented two-liner, satisfies TENANT-02 "documented but not auto-detected" exactly. `Mailglass.Oban.TenancyMiddleware` (optional-Oban gateway) serializes/restores across background boundaries — mitigates process-dict cross-tenant leakage.

**Notes:** TENANT-03 Credo check becomes implementable as pure AST match. `Mailglass.Tenancy.SingleTenant` default returns literal `"default"` from `current/0`. Admin v0.5 `on_mount` extracts from adopter's `%Scope{}` and calls `put_current/1` — admin package depends only on `Mailglass.Tenancy`.

**Sources cited:** [mix phx.gen.auth — Phoenix 1.8.5](https://hexdocs.pm/phoenix/mix_phx_gen_auth.html), [Phoenix 1.8.0 blog](https://www.phoenixframework.org/blog/phoenix-1-8-released), [Ash Multitenancy](https://hexdocs.pm/ash/multitenancy.html), [Phoenix scopes vs authorization (Curiosum)](https://curiosum.com/blog/phoenix-scopes-authorization-permit-phoenix). accrue reference at `~/projects/accrue/accrue/lib/accrue/actor.ex` + `~/projects/sigra/lib/sigra/scope.ex`.

---

## Area 7 — Migration delivery path

**Research agent:** `gsd-advisor-researcher` (Sonnet, quality profile).

### Options considered

| Option | Description | Selected |
|--------|-------------|----------|
| 1. `mix mailglass.gen.migration` standalone task + template copy | Adopter-facing mix task; matches `mix ecto.gen.migration` mental model. | |
| 2. Templates only; Phase 2 tests use `Ecto.Migrator` inline | Deferred public API; breaks PERSIST-06 literal. | |
| 3. Defer task to Phase 7; Phase 2 tests inline migrations | Smallest Phase 2; fixture/production divergence risk. | |
| 4. Compiled DDL module (`Mailglass.Migration.up/down`, Oban-style) | 8-line adopter wrapper; DDL lives in `lib/`; version-bump upgrade path. | ✓ |

**User's choice:** 4 (adopted). `Mailglass.Migration` public API; `Mailglass.Migrations.Postgres` dispatcher; `Mailglass.Migrations.Postgres.V01` for Phase 2 DDL. Adopter runs `mix mailglass.gen.migration` → 8-line wrapper calling `Mailglass.Migration.up()`. v0.5 upgrade: `--upgrade` flag generates wrapper calling `Mailglass.Migration.up(version: 2)` (Oban proven across 14 versions). Phase 2 test infra uses the same code path — trigger fires in tests because it's the same trigger adopters run. Phase 7 installer composes over the Phase 2 task.

**Notes:** Version tracking via `pg_class` comment (Oban pattern). Golden-diff CI fingerprints the stable wrapper; only timestamp prefix varies. `mailglass_inbound` sibling gets its own `MailglassInbound.Migrations` module with independent version counter — PHX-04 migration-ordering pitfall neutralized.

**Sources cited:** Oban reference at `deps/oban/lib/oban/migration.ex` + `deps/oban/lib/oban/migrations/postgres.ex` + per-version `v01.ex..v14.ex`. accrue counter-example at `~/projects/accrue/accrue/lib/accrue/install/templates.ex` (template-copy approach mailglass does NOT follow).

---

## Area 8 — `tenant_id` column type + timestamps precision

**Research agent:** `gsd-advisor-researcher` (Sonnet, quality profile).

### Options considered

| Option Bundle | Description | Selected |
|---------------|-------------|----------|
| A. `tenant_id TEXT NOT NULL` + `utc_datetime_usec` uniformly | Honors Phase 1 `String.t() \| nil` lock; accepts any adopter tenant shape; microsecond event ordering. | ✓ |
| B. TEXT tenant_id + mixed timestamp precision (usec for ordering-sensitive, utc_datetime for summary) | Aligns summary columns with Phoenix generator defaults; two-rule schema foot-gun. | |
| C. UUID tenant_id + `utc_datetime_usec` uniformly | Native 16-byte index; breaks Phase 1 lock; excludes slug-tenant adopters. | |
| D. Polymorphic `tenant_type + tenant_id` TEXT + usec | Maximally flexible; solves a problem no adopter has. | |

**User's choice:** A (adopted). `tenant_id TEXT NOT NULL` honors Phase 1's `Message.tenant_id :: String.t() | nil` lock; `Mailglass.Tenancy.SingleTenant.current/0` returns literal `"default"`. All timestamp columns + `timestamps/1` use `utc_datetime_usec` — resolves same-millisecond webhook batches; matches accrue's 4-of-4 DNA; `Mailglass.Clock` round-trips cleanly without usec truncation. Phase 6 Credo check candidate: `Mailglass.Credo.TimestampsUsecRequired`.

**Notes:** Index-size cost (~2.25× vs native UUID) is bounded because tenant cardinality is low (typically <100 per deployment) — Postgres 16 B-tree dedup compresses the prefix efficiently.

**Sources cited:** [UUID vs TEXT PK performance](https://www.codestudy.net/blog/postgresql-using-uuid-vs-text-as-primary-key/), [Cybertec — unexpected downsides of UUID keys](https://www.cybertec-postgresql.com/en/unexpected-downsides-of-uuid-keys-in-postgresql/), [Upgrading to Ecto 3 usec](https://elixirforum.com/t/upgrading-to-ecto-3-anyway-to-easily-deal-with-usec-it-complains-with-or-without-usec/22137), [UTC timestamps in Ecto](http://www.creativedeletion.com/2019/06/17/utc-timestamps-in-ecto.html), [Oban scheduling jobs](https://hexdocs.pm/oban/scheduling_jobs.html).

---

## Claude's Discretion

Items left to Claude's judgment (defaulted without further discussion):
- Schema file field order (matches accrue convention).
- Migration file naming (`<timestamp>_add_mailglass.exs`).
- Index names (verbatim from ARCHITECTURE.md §4.2-§4.4).
- Changeset validation order in `Mailglass.Events.Event.changeset/1` (cast → validate_required → Ecto.Enum narrowing).
- Telemetry emit granularity (4-level convention from Phase 1 D-30).
- `mailglass_suppressions.source TEXT` values are human-readable breadcrumbs, not an enum.
- `Mailglass.SuppressionStore` behaviour callbacks: `check/2` + `record/1` at minimum; more land in Phase 3.

---

## Deferred Ideas

Preserved in `02-CONTEXT.md` `<deferred>` section. Highlights:
- Orphan reconciliation Oban worker → Phase 4.
- `:pg`-coordinated multi-node tenancy → v0.5+.
- Full `current_scope/1 + tenant_id/1 + scope_query/2` Tenancy trio → not adopted unless Phase 3 pressures demand.
- `:typed_ecto_schema` / `:typed_struct` → rejected; Elixir 1.19 native typed structs will obviate.
- GIN index on `metadata jsonb` → v0.5 when adopter usage justifies.
- Webhook auto-add to suppressions → v0.5 DELIV-03.
- Cluster-coordinated rate-limiting + materialized rollup views → v0.5+.
- Postgres 18 server-side `uuidv7()` → adopter-owned on PG upgrade.

---

## Breadcrumbs the planner must own (summary)

1. **REQ PERSIST-05 amendment** in `.planning/REQUIREMENTS.md` — update wording to distinguish `append_multi/3` (canonical) from `append/1` (sugar wrapping `Repo.transact/1`).
2. **Phase 1 `Mailglass.SuppressedError` pre-GA patch** — `@types` from `[:address, :domain, :tenant_address]` to `[:address, :domain, :address_stream]`; `docs/api_stability.md` §Errors documents the pre-0.1.0 revision.
3. **`Mailglass.Oban.TenancyMiddleware`** added to `lib/mailglass/optional_deps/oban.ex` inventory; tests cover serialize-on-enqueue + restore-on-perform.
4. **`{:uuidv7, "~> 1.0"}`** added to `mix.exs` required deps; verify resolution against `:ecto_sql ~> 3.13` + `:phoenix ~> 1.8`.
5. **`Mailglass.Schema`** helper macro in `lib/mailglass/schema.ex` stamping `@primary_key` + `@foreign_key_type` + `@timestamps_opts` for the three Phase 2 schemas.

Each carried into `02-CONTEXT.md` as a numbered decision (D-02, D-09, D-33, D-25, D-28).
