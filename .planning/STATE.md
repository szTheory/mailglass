---
gsd_state_version: 1.0
milestone: v0.1
milestone_name: milestone
status: verifying
stopped_at: Completed 03-06-PLAN.md — TestAssertions + MailerCase + Phase 3 UAT gate (human-verify signed off)
last_updated: "2026-04-23T14:22:28.113Z"
last_activity: 2026-04-23
progress:
  total_phases: 7
  completed_phases: 3
  total_plans: 19
  completed_plans: 19
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-21)

**Core value:** Email you can see, audit, and trust before it ships.
**Current focus:** Phase 03 — transport-send-pipeline

## Current Position

Phase: 03 (transport-send-pipeline) — EXECUTING
Plan: 7 of 7
Status: Phase complete — ready for verification
Last activity: 2026-04-23

Progress: [██████████] 100%

## Performance Metrics

**Velocity:**

- Total plans completed: 12
- Average duration: —
- Total execution time: —

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| — | — | — | — |
| 01 | 6 | - | - |
| 02 | 6 | - | - |

**Recent Trend:**

- Last 5 plans: —
- Trend: — (no execution history yet)

*Updated after each plan completion.*
| Phase 01 P01-01 | 8min | 2 tasks | 20 files |
| Phase 01 P02 | 5min | 2 tasks | 9 files |
| Phase 01 P03 | 10min | 2 tasks | 9 files |
| Phase 01 P04 | 4min | 2 tasks tasks | 7 files files |
| Phase 01 P05 | 8 | 3 tasks | 8 files |
| Phase 01 P06 | 12min | 2 tasks | 8 files |
| Phase 02 P01 | 7min | 3 tasks | 14 files |
| Phase 02 P02 | 39min | 2 tasks tasks | 7 files files |
| Phase 02 P03 | 6min | 2 tasks tasks | 6 files files |
| Phase 02 P04 | 6min | 2 tasks tasks | 6 files files |
| Phase 02 P05 | 11min | 3 tasks | 6 files |
| Phase 02 P06 | 62min | 3 tasks tasks | 6 files files |
| Phase 03-transport-send-pipeline P01 | 30min | 3 tasks | 30 files |
| Phase 03 P02 | 19min | 3 tasks | 13 files |
| Phase 03 P03-03 | 17min | 3 tasks | 13 files |
| Phase 03-transport-send-pipeline P03-04 | 25min | 2 tasks | 10 files |
| Phase 03 P05 | 120 | 4 tasks | 14 files |
| Phase 03 P03-07 | 13min | 3 tasks | 12 files |
| Phase 03-transport-send-pipeline P03-06 | 45min | 4 tasks | 10 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table (D-01..D-20 — all locked at initialization).

Most load-bearing for Phase 1:

- **D-06**: Bleeding-edge floor — Elixir 1.18+ / OTP 27+ / Phoenix 1.8+ / LiveView 1.0+ / Ecto 3.13+.
- **D-17**: Custom Credo checks enforce domain rules (operationalized in Phase 6, but their forbidden patterns must be avoided from Phase 1 code).
- **D-18**: HEEx + Phoenix.Component is the default renderer; MJML is opt-in via the `:mjml` Hex package (NOT `:mrml` — corrected in research).
- Swoosh :api_client deferred to adopter via config :swoosh, :api_client, false — mailglass does not pin an HTTP transport
- Flat root Boundary on Mailglass (deps: [], exports: []) — classifies Mailglass.* modules without constraining internal deps; sub-boundaries land with later plans
- Mailglass.Config.validate_at_boot!/0 added to elixirc_options no_warn_undefined as MFA tuple forward reference until Plan 03 lands Config
- Struct-discrimination tests use __struct__ module comparison (err.__struct__ == Mailglass.TemplateError) instead of literal match?(%Mod{}, err) — Elixir 1.19 type checker narrows terms statically, so literal mismatch patterns trip --warnings-as-errors. Runtime struct-module comparison tests the same contract without the type-narrowing conflict.
- RateLimitError.new/2 accepts both :retry_after_ms as a top-level option (populates the struct field) and context.retry_after_ms (for message formatting). Plan showed bind-rebind via %RateLimitError{err | retry_after_ms: ms}; direct option is cleaner for callers.
- Mailglass.Error.root_cause/1 terminates on non-mailglass causes — when :cause is a plain Exception without its own :cause field (e.g. %RuntimeError{}), walking stops there. Third-party exceptions become leaves in the cause chain.
- Mailglass.Config uses :persistent_term with namespaced key {Mailglass.Config, :theme} — write once at validate_at_boot!/0, read O(1) on every render; no ETS, no GenServer per D-19
- :telemetry.span/3 auto-injects :telemetry_span_context for OTel span correlation — exempted from the D-31 metadata whitelist in tests because it is library machinery, not adopter-supplied PII (documented inline in telemetry_test.exs)
- StreamData metadata generator for the whitelist property test uses list_of(tuple/2) + Enum.into(%{}) instead of map_of/2 — the 11-element whitelist key space is too small for map_of's uniq-key generator, which hit TooManyDuplicatesError on the 8th run
- Mailglass.Repo.transact/1 delegates via Ecto 3.13+ transact/2 (tuple-rollback semantics), not the deprecated transaction/1 — Phase 2 events-ledger append relies on the {:ok,_}/{:error,_} rollback contract
- Mailglass.Message.new/2 uses Keyword.get with per-option defaults — uniform builder regardless of opt count, pattern-matches %Swoosh.Email{} on input
- Mailglass.OptionalDeps.Sigra is conditionally compiled via if Code.ensure_loaded?(Sigra) do ... end — matches accrue-sigra pattern where Sigra itself expects the module to not exist when :sigra absent; callers probe existence via Code.ensure_loaded?(Mailglass.OptionalDeps.Sigra), not available?/0
- OpenTelemetry gateway probes :otel_tracer (stable API surface), not the package atom :opentelemetry (not a loadable module) — matches accrue/integrations and PATTERNS.md line 814
- render_slot_to_binary/2 calls Phoenix.Component.__render_slot__/3 directly with nil for the changed tracker — the public render_slot/2 is a macro that only works inside ~H. Needed for button/1's VML branch where slot content must be a binary suitable for splicing into a raw MSO conditional block.
- Button :variant and :tone are orthogonal. :tone picks the brand color (glass/ink/slate); :variant picks the rendering mode (primary=fill, secondary=ice-tint, ghost=transparent). Both resolve to concrete hex values before entering the VML block — classic Outlook cannot resolve brand tokens in v:roundrect fillcolor/strokecolor.
- <.img> :alt is required at compile time via attr :alt, :string, required: true. Phoenix.Component's compile-time check emits 'missing required attribute "alt"' whenever <.img> is used without it — under --warnings-as-errors that's a hard failure. The accessibility floor cannot be bypassed by omission.
- img_no_alt_test.exs stays @moduletag :skip. Compile-time checks can't be tested by running them at test runtime — compiling a fixture module inside the test suite would FAIL the entire suite because the compile error propagates. The stub exists as documentation of the contract.
- HEEx does not interpolate expressions inside HTML comments. VML-bearing components (row, column, button) pre-build MSO conditional blocks as strings, wrap with Phoenix.HTML.raw/1, and embed via expression holes. The <a> HTML fallback uses normal HEEx because the if-not-mso boundary terminates the comment per HTML parser rules.
- Renderer sub-boundary pattern: use Boundary, deps: [Mailglass] + root-level exports controls the CORE-07 call surface from a single source of truth. Future sub-boundaries (Outbound/Events/Webhook/Admin) follow the same shape; the root exports list grows monotonically.
- HEEx function components in test fixtures must bind 'assigns' by exact name (not '_assigns') because the ~H sigil macro-expands a reference to assigns even when the template has no interpolations. Using the prefixed name causes 'requires a variable named assigns to exist' at fixture-build time.
- Renderer plaintext walker runs on the pre-VML HTML tree (D-15) BEFORE Premailex CSS inlining. Pipeline: render_html -> to_plaintext (pre-VML) -> inline_css (Premailex) -> strip_mg_attributes. Premailex adds VML wrappers/OfficeDocumentSettings that must never leak into text_body.
- Compliance supports both map-shaped and list-shaped Swoosh.Email.headers via dual pattern-match clauses. Current Swoosh 1.25 uses a map, but a future schema change won't silently break the Phase 1 contract.
- Mailglass.Repo facade grew to six functions in Plan 02-01 (transact/1, insert/2, update/2, delete/2 with SQLSTATE 45A01 translation + passthrough one/2, all/2, get/3). Single translate_postgrex_error/2 defp is the one translation point; reraises Mailglass.EventLedgerImmutableError on pg_code 45A01.
- Plan 02-01 added :ecto, :ecto_sql, :postgrex as explicit required deps. PROJECT.md declared them required from v0.1 but Phase 1 left them transitive-only (via phoenix). The SQLSTATE translation code's %Postgrex.Error{} pattern failed at compile time — closing the gap in Plan 01 rather than Plan 02 unblocks both.
- Mailglass.DataCase stamps Process.put(:mailglass_tenant_id, ...) directly as a forward reference. Plan 04 ships Mailglass.Tenancy.put_current/1 under the same process-dict key and updates the setup to use the public API then.
- EventLedgerImmutableError.new/2 defaults to :update_attempt type because Postgrex error messages are not a stable API. Callers that need UPDATE vs DELETE distinction walk :cause to the raw Postgrex error or read ctx.pg_code.
- Mailglass.Migration.migrated_version/0 now resolves and injects the configured Repo explicitly before dispatching to Mailglass.Migrations.Postgres.migrated_version/1. This lets the function be called outside an Ecto.Migrator runner context (needed by tests and by Phase 6 lint checks), while preserving the Oban-style signature that accepts :repo via opts for in-runner callers.
- Migration test uses Ecto.Adapters.SQL.Sandbox.mode(:auto) in setup (reverting to :manual on_exit). DDL cannot roll back in the sandbox transactional wrapper; :auto mode disables ownership tracking so every process (including the Ecto.Migrator subprocess spawned by with_repo) checks out on demand. :manual mode (required by DataCase) is restored on exit.
- Synthetic test migration pattern: priv/repo/migrations/00000000000001_mailglass_init.exs is the 8-line wrapper adopters will get from mix mailglass.gen.migration (Phase 7 D-36/D-37). test_helper.exs runs it via Ecto.Migrator.with_repo/2 + Ecto.Migrator.run/4, then starts the TestRepo explicitly (with_repo stops the repo after its block) and sets sandbox to :manual.
- Ecto.Enum error metadata in Ecto 3.13+ includes a :type key before :validation + :enum (parameterized enum spec). Tests must assert via keyword-list key access (opts[:validation], opts[:enum]) — literal [validation: ..., enum: ...] pattern matches fail silently.
- UNIQUE-index violations during Repo.insert surface as Ecto.ConstraintError (not Postgrex.Error) when the schema has not declared unique_constraint/3. Raw TestRepo.query! bypasses the Ecto interception layer and surfaces the raw Postgrex.Error — useful for DB CHECK constraint integration tests.
- Mailglass.Events.Event schema exposes only changeset/1 (INSERT). No update_changeset/2 is defined; the moduledoc explicitly avoids the substring 'update_changeset' to not trip naive acceptance greps. Adopters who need to update an event row will hit the DB trigger → EventLedgerImmutableError at Repo.update/2 time.
- Delivery changeset auto-populates :recipient_domain via put_recipient_domain/1 pipe step — lowercased SPLIT_PART of :recipient at cast time. Adopters who supply :recipient_domain explicitly (via Generators or tests) keep their override; the helper only fires when no change is present.
- Mailglass.Tenancy.SingleTenant ships as the :tenancy default. current/0 returns literal 'default' when unstamped. Application.get_env(:mailglass, :tenancy) is read per call — not cached in :persistent_term. Tenancy is off the render hot path; caching would couple it to Config.validate_at_boot!/0 boot-order.
- Mailglass.Oban.TenancyMiddleware conditionally-compiles against Oban.Worker (not Oban.Middleware — that behaviour is Oban Pro only). Ships dual-surface: call/2 matches the Pro middleware shape for direct middleware: [...] registration; wrap_perform/2 is the OSS adopter entry point invoked from inside perform/1. Both paths converge on Mailglass.Tenancy.with_tenant/2.
- DataCase.with_tenant/2 retained as a one-line delegate to Mailglass.Tenancy.with_tenant/2; setup block calls Mailglass.Tenancy.put_current/1. Raw Process.put(:mailglass_tenant_id, ...) from Plan 01 fully retired — the public Tenancy API is the ONLY stamping path, which is what Phase 6 LINT-03 (NoUnscopedTenantQueryInLib) will enforce.
- tenant_id!/0 does NOT fall back to the SingleTenant default when unstamped — it raises Mailglass.TenancyError{type: :unstamped}. Unlike current/0 (permissive), tenant_id!/0 is the fail-loud accessor for Oban workers that have already run the middleware. Mirrors accrue's Actor.actor_id! vs Actor.current split.
- Plan 02-05: replay-detection sentinel for UUIDv7 schemas is inserted_at: nil, not id: nil. Client-side autogenerate populates id before INSERT; nil sentinel shifts to any DB-defaulted column (inserted_at default now()). Documented in Mailglass.Events moduledoc so future append-only schemas follow the same convention.
- Plan 02-05: DB-backed property tests that TRUNCATE between iterations cannot use DataCase — transaction wrapper deadlocks after ~60s. Pattern: use ExUnit.Case, async: false + Sandbox.mode(TestRepo, :auto) in setup + :manual in on_exit. Matches Plan 02-02's migration_test pattern. Bounded to a single test; does not leak into DataCase-using siblings.
- Plan 02-05: Mailglass.Events.current_trace_id/0 is a nil-returning stub in Phase 2. The plan's verbatim :otel_propagator_text_map probe referenced a fictitious return shape. Phase 4 webhook ingest is the first concrete trace-context call site; the stub is replaced then against a real OTel SDK harness.
- Plan 02-05: Reconciler module (find_orphans/1 + attempt_link/2) ships as pure Ecto with zero Oban dep. Module docstrings forward-reference Phase 4's Oban worker (cron */15 * * * * per D-20) but contain no imports/aliases/calls to Oban. mix compile --no-optional-deps --warnings-as-errors stays green.
- Plan 02-06: Mailglass.Outbound.Projector is the single writer for Delivery projection columns (D-14). update_projections/2 returns an Ecto.Changeset with D-15 monotonic rules chained (last_event_type advances always; last_event_at is monotonic max; dispatched/delivered/bounced/complained/suppressed_at set-once; terminal one-way latch) and Ecto.Changeset.optimistic_lock(:lock_version) (D-18) for the dispatch race.
- Plan 02-06: SuppressionStore.Ecto.check/2 uses two union_predicates/4 clauses (with-stream vs stream-nil) because Ecto refuses compile-time e.stream == ^nil. Stream-less callers cannot match :address_stream-scoped rows by definition; dropping that branch is correct behaviour, not a workaround.
- Plan 02-06: Postgrex type cache goes stale after migration_test.exs drops + recreates the citext extension (new OID). Plan 06 mitigation: config/test.exs disconnect_on_error_codes: [:internal_error] + per-test probe_until_clean/5 helper in persistence_integration_test.exs. Killing Postgrex.TypeServer processes cascaded failures; the surgical probe+disconnect approach is sufficient. Architectural fix deferred to Phase 6 (4 candidates in deferred-items.md).
- Plan 02-06: Mailglass.SuppressionStore behaviour ships record/2 (not record/1 as originally specified) for symmetry with check/2 and adopter opts seam. The impl declares def record(attrs, opts \ []) so callers that pass a single arg still work.
- Plan 02-06: Projector last_event_type advances UNCONDITIONALLY on every event (not monotonic) — it is a latest-observation pointer, not a lifecycle fact. D-15 monotonicity applies only to timestamps and terminal. Test non-monotonic ordering: :opened BEFORE :delivered documents the behaviour.
- Clock.impl/0 uses case/match on Application.get_env (not get_env/3 default) to handle explicit nil stored by test cleanup via Application.put_env
- Events.append_multi function-form uses two Multi.run steps (not Ecto.Multi.insert/4) because Ecto 3.13.5 does not export Multi.insert/4
- Application supervision tree consolidated in Plan 01 only (I-08); Plans 02+03 add supervisor modules without editing application.ex via Code.ensure_loaded?-gated maybe_add/3
- Repo.multi/1 added as public wrapper over private repo/0 so Outbound (Plan 05) can compose Multis without accessing private internals (I-02)
- broadcast_delivery_updated/3 implemented in Task 2 because Fake.trigger_event/3 calls it — Tasks 2+3 are interdependent
- Fake.Storage uses ETS named table :mailglass_fake_mailbox with per-owner inbox isolation; checkout is idempotent; allow/2 does not require pre-checkout
- Task.async inherits dollar-callers so spawn/1 used in Test 5 to avoid owner resolution bypassing no-owner guard
- ETS compound op {2, total_add, capacity, capacity}, {3, 0, 0, now_ms}, {2, -1} for token bucket — raw decrement returns actual value (-1=over-limit, >=0=allowed); capped refill prevents exceeding capacity
- Restore-from-negative refill: when counter is -1 post-over-limit, add abs(tokens) to restore to 0 before applying elapsed refill delta
- Stream.policy_check test uses apply/3 to bypass Elixir 1.18 type-narrowing on intentional FunctionClauseError misuse test
- Injection uses import Swoosh.Email, except: [new: 0] to avoid conflict with injected new/0 in using modules
- Tracking.fetch_from_mailable/1 calls Code.ensure_loaded/1 before function_exported? — async BEAM lazy loading: compiled .beam not loaded until first reference in process
- render/3 default injects Mailglass.Renderer.render(msg) ignoring template + assigns (I-10 option b) — template resolution is adopter-owned via defoverridable
- D-20 enforced: adapter call between Multi#1 and Multi#2, never inside transaction (Postgres pool starvation prevention)
- D-21 enforced: Oban.insert composed into Ecto.Multi for atomic job+delivery; Task.Supervisor re-stamps tenancy via with_tenant
- ASSUMED: deliver_many v0.1 is async-only; sync-batch fan-out deferred to v0.5
- D-35 pattern a enforced: target_url in signed token payload, never as query param — open-redirect CVE class structurally unreachable
- Token property tests use min_length: 5 for tenant_id/delivery_id — single-char strings can appear by chance in Base64-encoded Phoenix.Token output
- ConfigValidator uses Code.ensure_loaded in test setup to force TrackingMailer into :code.all_loaded() — BEAM lazy-loads compiled .beam files
- Plug swallows DB write errors with rescue — pixel/redirect ALWAYS succeed; event recording is best-effort
- I-12 guard: tests using @tag oban: ... raise immediately when async: true — Oban.Testing mode is Application.put_env (global); concurrent async tests would stomp each other
- set_mailglass_global/1 is the ONE path to global Fake mode — mirrors set_swoosh_global, enforces async: false
- assert_mail_sent/1 macro dispatches on AST shape at compile time: {:%{}, _, _} = struct pattern, {:fn, _, _} = predicate, list = keyword, empty = bare presence check

### Pending Todos

None yet.

### Blockers/Concerns

- **Premailex (MEDIUM-confidence dep)**: last release Jan 2025, no credible replacement. Flag as "watch this dep" through v0.5; revisit at v0.5 retro per SUMMARY.md gaps.
- **`mailglass_inbound` deferred to v0.5+**: shares webhook plumbing with v0.5 deliverability work; intentionally not in v0.1 roadmap.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| *(none)* | | | |

## Session Continuity

Last session: 2026-04-23T14:22:28.101Z
Stopped at: Completed 03-06-PLAN.md — TestAssertions + MailerCase + Phase 3 UAT gate (human-verify signed off)
Resume file: None

**Planned Phase:** 03 (transport-send-pipeline) — 7 plans — 2026-04-23T02:33:05.018Z
