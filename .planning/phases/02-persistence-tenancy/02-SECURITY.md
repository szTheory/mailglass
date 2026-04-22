---
phase: 2
slug: persistence-tenancy
status: verified
threats_open: 0
asvs_level: 1
created: 2026-04-22
---

# Phase 2 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
> Source of truth for threat model: `02-0{1..6}-PLAN.md` `<threat_model>` blocks. Implementation evidence verified 2026-04-22 by `gsd-security-auditor`.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| host app → `Mailglass.Repo` facade | Adopter configures `config :mailglass, :repo, MyApp.Repo`; missing/misconfigured raises `Mailglass.ConfigError` | Ecto queryables, changesets |
| Postgres → Elixir | `%Postgrex.Error{postgres: %{code: :raise_exception, pg_code: "45A01"}}` translates at the facade layer to `Mailglass.EventLedgerImmutableError` without leaking the raw plpgsql message | pg_code, operation atom (`:update`/`:delete`) |
| adopter `on_mount` → mailglass process dict | `Mailglass.Tenancy.put_current/1` is the only stamping path; raw `Process.put/2` is a Phase 6 lint violation | tenant_id binary |
| Oban enqueue → `perform/1` process | Middleware serializes `"mailglass_tenant_id"` in `job.args` (plaintext binary) and restores via `with_tenant/2` under a guard `is_binary(tenant_id)` | tenant_id binary |
| Ecto query builder → `Mailglass.Repo` | `Mailglass.Tenancy.scope/2` is the behaviour seam where tenant filtering enters; adopter resolver is trusted | tenant_id binary, Ecto.Queryable |
| caller attrs → `Events.append/1` | Tenant/trace auto-capture from process dict; `:idempotency_key` arms DB-enforced replay protection; telemetry metadata is whitelist-only | event attrs map, telemetry meta (non-PII) |
| `%Event{}` → `Projector.update_projections/2` | Monotonic-rule enforcement at Elixir layer (D-15); DB has no ordering constraints | Event struct, Delivery struct |
| concurrent dispatchers → same `%Delivery{}` | `optimistic_lock(:lock_version)` raises `Ecto.StaleEntryError` on the loser | lock_version integer |
| adopter caller → `SuppressionStore.check/2` | Lookup key MUST include `tenant_id`; pattern-match guard at function head rejects malformed keys | `{tenant_id, address, scope, stream?}` tuple |

---

## Threat Register

*Threat IDs are namespaced by plan. Duplicate IDs across plans (e.g. `T-02-05`) denote distinct dispositions in different components and are preserved verbatim from each plan's `<threat_model>`.*

| Threat ID | Plan | Category | Component | Disposition | Mitigation | Status |
|-----------|------|----------|-----------|-------------|------------|--------|
| T-02-01a | 01 | Tampering (T2 — event ledger bypass) | `Mailglass.Repo.transact/insert/update/delete` | mitigate | Single `translate_postgrex_error/2` at `lib/mailglass/repo.ex:120-131`; pg_code `"45A01"` → `EventLedgerImmutableError`; raw message not propagated. Corroborated by `test/mailglass/events_immutability_test.exs`. | closed |
| T-02-01b | 01 | Tampering | `Mailglass.SuppressedError` atom-set | mitigate | Closed `@types [:address, :domain, :address_stream]` at `lib/mailglass/errors/suppressed_error.ex:21`. `docs/api_stability.md` records D-09 pre-GA refinement. `test/mailglass/error_test.exs` pins the set. | closed |
| T-02-03a | 01 | Information Disclosure (T3 — PII in telemetry) | `Mailglass.Telemetry.events_append_span/2` | mitigate | Helpers at `lib/mailglass/telemetry.ex:108-135` pass only caller-supplied metadata; D-31 whitelist documented in moduledoc lines 25-33. No PII keys introduced by Plan 01. | closed |
| T-02-05 | 01 | Information Disclosure | `config/test.exs` DB credentials | accept | `config/test.exs:17-23` uses commit-safe `"postgres"` placeholders overridable via `System.get_env/2`. No production secrets in repo. | closed |
| T-02-02 | 02 | Tampering (T2 — immutability trigger) | `mailglass_events_immutable_trigger` | mitigate | `lib/mailglass/migrations/postgres/v01.ex:124-145` — `CREATE OR REPLACE FUNCTION mailglass_raise_immutability` + `BEFORE UPDATE OR DELETE ON mailglass_events FOR EACH ROW` raising SQLSTATE `'45A01'`. Cannot be bypassed from Elixir. | closed |
| T-02-02b | 02 | Tampering | Raw SQL bypass attempts | mitigate | DB trigger (above) is the runtime defense. Phase 6 `NoRawEventInsert` Credo lint deferred — does not affect closure. | closed |
| T-02-04 | 02 | Replay amplification (T4) | `mailglass_events_idempotency_key_idx` UNIQUE partial | mitigate | `v01.ex:89-95` — `unique_index(:mailglass_events, [:idempotency_key], where: "idempotency_key IS NOT NULL")`. WHERE clause matches `lib/mailglass/events.ex:139` `conflict_target` fragment verbatim. | closed |
| T-02-05 | 02 | Information Disclosure (T5 — cross-tenant leak) | `mailglass_suppressions` UNIQUE `(tenant_id, address, scope, COALESCE(stream,''))` | mitigate | `v01.ex:180-187` — `tenant_id` is the leading column; `COALESCE(stream, '')` normalizes NULL-vs-empty to distinct rows. | closed |
| T-02-06 | 02 | Information Disclosure | `mailglass_suppressions.address CITEXT` | mitigate | `v01.ex:10` `CREATE EXTENSION IF NOT EXISTS citext` + `v01.ex:152` `add :address, :citext`. Belt-and-suspenders: `Entry.downcase_address/1` in Plan 03. | closed |
| T-02-07 | 02 | Tampering / Information Disclosure | `DROP EXTENSION citext` in `down/0` | accept | `v01.ex:215` `DROP EXTENSION IF EXISTS citext` — intentional to keep the migration invertible; Postgres emits a notice if another extension depends on citext but does not fail. | closed |
| T-02-05a | 03 | Information Disclosure (T5 — suppression bypass) | `Suppression.Entry` scope/stream coupling | mitigate | Changeset `validate_scope_stream_coupling/1` at `lib/mailglass/suppression/entry.ex:90-108` + DB CHECK `mailglass_suppressions_stream_scope_check` at `v01.ex:166-176`. Both layers tested in `test/mailglass/suppression/entry_test.exs`. | closed |
| T-02-05b | 03 | Information Disclosure | Suppression address casing | mitigate | `entry.ex:110-115` `downcase_address/1` + citext at DB layer. Either alone suffices; together the invariant is machine-checkable. | closed |
| T-02-08 | 03 | Tampering | Event schema has no update path | mitigate | `lib/mailglass/events/event.ex:108-112` exposes only `changeset/1`. Grep confirmed zero `update_changeset`/`delete_changeset` definitions. Any stray `Ecto.Changeset.change(%Event{}, ...)` hits the trigger at `Repo.update/2`. | closed |
| T-02-09 | 03 | Tampering | `Delivery` optimistic lock | mitigate | `lib/mailglass/outbound/delivery.ex:96` `field :lock_version, :integer, default: 1`. Projector consumers chain `optimistic_lock(:lock_version)` (see T-02-02a below). | closed |
| T-02-10 | 03 | Elevation of Privilege | Hand-written typespec vs `:typed_ecto_schema` | accept | D-23 rejects `:typed_ecto_schema`. Hand-written `@type t :: %__MODULE__{...}` confirmed on all three schemas (`delivery.ex:56-77`, `event.ex:61-75`, `entry.ex:39-50`). Phase 6 candidate `EctoSchemaHasTypespec` lint will backstop drift. | closed |
| T-02-01a | 04 | Tampering (T1 — cross-tenant leak) | `Mailglass.Tenancy.scope/2` | mitigate | Behaviour callback at `lib/mailglass/tenancy.ex:40`; `scope/2` delegates to configured resolver. Single seam for tenant filtering. | closed |
| T-02-01b | 04 | Tampering | `Mailglass.Tenancy.tenant_id!/0` | mitigate | `tenancy.ex:113-119` reads the process dict directly (not via `current/0`); nil raises `TenancyError.new(:unstamped)`. Does NOT fall back to SingleTenant default. | closed |
| T-02-01c | 04 | Tampering | Process-dict key `:mailglass_tenant_id` namespacing | accept | `tenancy.ex:42` `@process_dict_key :mailglass_tenant_id`; encapsulated behind `put_current/1` + `current/0`. Adopters who write the key directly bypass the library boundary — not a security concern. | closed |
| T-02-01d | 04 | Tampering | Oban middleware serialization | mitigate | `lib/mailglass/optional_deps/oban.ex:125-133` (`wrap_perform/2`) + `:144-152` (`call/2`) pattern-match `%{"mailglass_tenant_id" => tenant_id} when is_binary(tenant_id)` then route through `with_tenant/2`. Non-binary/missing args pass through unchanged. OSS-Oban divergence (`wrap_perform` vs Pro middleware behaviour) preserves D-33 intent identically (see SUMMARY 04). | closed |
| T-02-11 | 04 | Information Disclosure | Tenant_id in Oban job args plaintext | accept | Tenant_id is not PII; if an adopter's scheme is sensitive they must pseudonymize before `put_current/1`. Documented deferral to `guides/multi-tenancy.md` (Phase 7). | closed |
| T-02-04a | 05 | Replay amplification (T4) | `Events.append/1` idempotency replay | mitigate | `lib/mailglass/events.ex:136-144` — `on_conflict: :nothing, conflict_target: {:unsafe_fragment, "(idempotency_key) WHERE idempotency_key IS NOT NULL"}`; replay detected via `inserted_at: nil` sentinel (lines 153-161) + `fetch_by_idempotency_key/1` fallback. Property test `test/mailglass/properties/idempotency_convergence_test.exs` proves convergence across 1000 iterations. See note on sentinel choice below. | closed |
| T-02-04b | 05 | Replay amplification | Non-keyed inserts always succeed | accept | Events without `:idempotency_key` produce fresh rows (no conflict target) — correct for audit-once events. Phase 4 webhook handlers MUST populate `:idempotency_key`. | closed |
| T-02-02 | 05 | Tampering (T2) | SQLSTATE 45A01 in `Events.append/1` | mitigate | `events.ex:111-115` (`append_multi`) + `events.ex:153-167` (`do_insert`) use only `Ecto.Multi.insert` / `Mailglass.Repo.insert`. No UPDATE/DELETE paths fire the trigger. Translation is dormant here but active for any `Repo.update/2` caller. | closed |
| T-02-03 | 05 | Information Disclosure (T3) | Telemetry metadata in `events_append_span/2` | mitigate | `events.ex:92-95` emits `:tenant_id`, `:idempotency_key_present?`, `:inserted?`. `events_test.exs` refutes PII keys `(:recipient, :email, :to, :subject, :body, :html_body, :headers, :from)`. D-31 whitelist honored. | closed |
| T-02-05 | 05 | Information Disclosure (T5 — Reconciler leak) | `Reconciler.find_orphans/1` cross-tenant | mitigate | `lib/mailglass/events/reconciler.ex:56-84` accepts `:tenant_id` opt (lines 57, 77-81); unscoped mode documented for admin/batch. Phase 6 `NoUnscopedTenantQueryInLib` will exempt via `scope: :unscoped` pattern. | closed |
| T-02-12 | 05 | Tampering | `attempt_link/2` — no mutation | mitigate | `reconciler.ex:107-133` uses only `Mailglass.Repo.one/1` (line 126). Pure query; returns `{:ok, {delivery, event}} \| {:error, _}`. | closed |
| T-02-01 | 06 | Tampering (T2) | Projector late/reordered event handling | mitigate | `lib/mailglass/outbound/projector.ex:82-134` — `maybe_advance_last_event/2` (DateTime.compare max), `maybe_set_once_timestamp/2` (nil-check preserves first value), `maybe_flip_terminal/2` (`true → changeset` no-op prevents reversal). All four adversarial orderings covered by projector tests. | closed |
| T-02-02a | 06 | Tampering | Projector optimistic lock bypass | mitigate | `projector.ex:69` — every Projector changeset ends with `Ecto.Changeset.optimistic_lock(:lock_version)`. A caller bypassing the Projector (D-14 violation) would need to chain the lock manually. | closed |
| T-02-05a | 06 | Information Disclosure (T5 — cross-tenant leak) | `SuppressionStore.Ecto.check/2` | mitigate | `lib/mailglass/suppression_store/ecto.ex:34-35` function head requires `%{tenant_id: tenant_id, address: address}` with `is_binary(tenant_id)` guard; query line 48 `where: e.tenant_id == ^tenant_id`; fallback line 68 returns `{:error, :invalid_key}`. Two-tenant integration test in Plan 06 Task 3 proves isolation. | closed |
| T-02-05b | 06 | Information Disclosure | `SuppressionStore.Ecto.record/1` upsert target | mitigate | `ecto.ex:116-123` — `conflict_target: {:unsafe_fragment, "(tenant_id, address, scope, COALESCE(stream, ''))"}` matches `v01.ex:183` unique_index verbatim; `on_conflict: {:replace, [:reason, :source, :expires_at, :metadata]}` excludes `tenant_id`. | closed |
| T-02-01b | 06 | Tampering (T1) | `Tenancy.scope/2` default behavior | accept | `lib/mailglass/tenancy/single_tenant.ex:19` `def scope(query, _context), do: query` — no-op under SingleTenant. Multi-tenant adopters MUST provide a resolver that injects `WHERE tenant_id = ?`. ROADMAP documents the requirement; Phase 6 `NoUnscopedTenantQueryInLib` will backstop. | closed |
| T-02-06 | 06 | Information Disclosure | Projector telemetry — `tenant_id` + `delivery_id` | mitigate | `projector.ex:62` meta `%{tenant_id: delivery.tenant_id, delivery_id: delivery.id}`; both keys on D-31 whitelist. Projector tests assert PII refutation. | closed |
| T-02-13 | 06 | Denial of Service | Unbounded `find_orphans/1` on large backlog | mitigate | `reconciler.ex:38` `@default_max_age_minutes 7 * 24 * 60`; lines 64-65 — `:limit` default 100, `:max_age_minutes` default 10080. Phase 4's worker processes one batch per 15-minute tick. | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-02-01 | T-02-05 (Plan 01) | Test-only DB credentials are commit-safe placeholder defaults (`"postgres"`) overridable via `System.get_env/2`. No production secrets in repo. | Phase 2 plan review | 2026-04-22 |
| AR-02-02 | T-02-07 (Plan 02) | `down/0` runs `DROP EXTENSION IF EXISTS citext` to keep the migration invertible. Postgres emits a notice if another extension depends on citext; leaving citext behind would produce a non-invertible migration (worse for debuggability). | Phase 2 plan review (D-07 context) | 2026-04-22 |
| AR-02-03 | T-02-10 (Plan 03) | Hand-written `@type t :: %__MODULE__{...}` on every schema rather than `:typed_ecto_schema` (D-23). ~15 lines per schema. Drift risk backstopped by Phase 6 candidate Credo check `EctoSchemaHasTypespec` (D-24). | D-23 | 2026-04-22 |
| AR-02-04 | T-02-01c (Plan 04) | Process-dict key `:mailglass_tenant_id` is encapsulated behind `put_current/1` + `current/0`. Adopter collision requires deliberate use of the same atom outside the library boundary — not a security concern. | Phase 2 plan review | 2026-04-22 |
| AR-02-05 | T-02-11 (Plan 04) | `tenant_id` serialized in Oban job args as plaintext binary. Tenant_id is an adopter-owned identifier (not PII). Adopters with sensitive schemes (e.g., email-as-tenant-id) must pseudonymize before `put_current/1`. Will be documented in `guides/multi-tenancy.md` (Phase 7). | Phase 2 plan review | 2026-04-22 |
| AR-02-06 | T-02-04b (Plan 05) | `Events.append/1` without `:idempotency_key` always produces a fresh row — correct for once-emitted audit events. Phase 4 webhook handlers MUST populate `:idempotency_key`; test coverage will assert this. | Phase 2 plan review | 2026-04-22 |
| AR-02-07 | T-02-01b (Plan 06) | `SingleTenant.scope/2` is a no-op by default (`def scope(query, _), do: query`). Multi-tenant adopters MUST supply a resolver that injects `WHERE tenant_id = ?`. ROADMAP documents the requirement; Phase 6 `NoUnscopedTenantQueryInLib` lint (deferred) will backstop. | D-09 | 2026-04-22 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-04-22 | 33 | 33 | 0 | `gsd-security-auditor` (initial audit, State B) |

### 2026-04-22 — Initial audit

All 33 threat entries across plans 01–06 verified. 26 mitigate-disposition threats confirmed by direct code inspection; 7 accept-disposition threats confirmed as still appropriate and logged above.

**Notes:**

- **Deferred Phase 6 Credo lint checks** are defense-in-depth backstops; runtime mitigations are already in place and close each threat on their own. Deferred checks: `NoRawEventInsert` (runtime: DB trigger), `NoPiiInTelemetryMeta` (runtime: test refutation), `NoUnscopedTenantQueryInLib` (runtime: `SuppressionStore.check/2` guard + `Reconciler.find_orphans/1` explicit opt), `EctoSchemaHasTypespec` (hand-checked during audit), `NoProjectorOutsideOutbound` (runtime: Projector is the only module defining `update_projections/2`).
- **Sentinel divergence from threat-register narrative (non-security):** `Events.append/1` detects `ON CONFLICT DO NOTHING` replay via `inserted_at: nil` rather than the threat-register-mentioned `id: nil`. Per SUMMARY 05 "Decisions Made", UUIDv7 is generated client-side before INSERT so `id` is always populated; `inserted_at` is the DB-defaulted field that reliably reads nil on conflict. Mitigation T-02-04a is unchanged — the `fetch_by_idempotency_key/1` fallback still fires and the property test proves convergence.
- **Oban middleware divergence (non-security):** SUMMARY 04 documents the OSS-Oban adaptation — `wrap_perform/2` replaces `@behaviour Oban.Middleware` (Pro-only), while preserving D-33 intent. Threat T-02-01d semantics are identical.
- **Sandbox-only concern (non-security, test-config):** `config/test.exs:33` adds `disconnect_on_error_codes: [:internal_error]` as a workaround for Postgrex TypeServer cache staleness after `migration_test` down-then-up cycles. Production adopters unaffected.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-04-22
