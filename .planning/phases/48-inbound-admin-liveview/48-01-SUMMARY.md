---
phase: 48-inbound-admin-liveview
plan: 01
subsystem: testing
tags: [optional-deps, ecto, tenancy, pubsub, reflection, boundary, liveview, inbound]

# Dependency graph
requires:
  - phase: 45-inbound-telemetry-idempotency-foundation
    provides: "InboundRecord/InboundEvidence/ExecutionRun schemas, MailglassInbound.Repo facade, MailglassInbound.PubSub.Topics, MailglassInbound.Internal.Replay, MailglassInbound.Router.Matcher"
  - phase: 47-inbound-test-helpers-generators
    provides: "MailglassInbound.Fixtures + MailglassInbound.MailboxCase sandbox patterns"
provides:
  - "Floating optional mailglass_inbound dep in mailglass_admin (path local-dev, ~> 0.2 on publish, never ==, out of release-please PINS)"
  - "Admin test DB carries inbound migrations + config :mailglass_inbound, :repo so InboundLive fixtures insert"
  - ":inbound_router operator-routes opt (D-48-07) threaded into __operator_session__"
  - "MailglassInbound.Router.Matcher.explain/2 routing-trace reflection (IADM-04)"
  - "MailglassInbound.Internal.Operator.{Records,Timeline,Detail} tenant-required-or-empty read-model (IADM-01)"
  - "MailglassAdmin.OptionalDeps.MailglassInbound runtime gateway (available?/0 + apply/3 wrappers)"
  - "MailglassAdmin.PubSub.Topics.inbound_record_inserted/1 consumer-side builder (IADM-05)"
  - "MailglassAdmin.Components.mask_recipient/1 — one audited public PII-masking definition"
affects: [48-02, 48-03, inbound-admin-liveview, operator-dashboard, routing-trace-card]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Floating optional sibling dep (mirror mailglass_dep/0 structure but ~> 0.2 + optional:true, out of PINS)"
    - "Runtime apply/3 gateway for an optional sibling (Code.ensure_loaded? + @compile no_warn_undefined + available?/0); Boundary deps unchanged"
    - "Tenant-required-or-empty read-model (blank tenant -> []/nil, never raises) with explicit tenant_id where + Tenancy.scope/2"
    - "In-module reflection reusing the existing private predicates (single source of truth)"
    - "Consumer-side PubSub topic builder mirroring a producer-side builder byte-for-byte (parity test)"
    - "One audited public PII-masking helper (no drifting private copies)"

key-files:
  created:
    - mailglass_admin/lib/mailglass_admin/optional_deps/mailglass_inbound.ex
    - mailglass_admin/test/mailglass_admin/pub_sub/topics_test.exs
    - mailglass_admin/test/support/inbound_test_router.ex
    - mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex
    - mailglass_inbound/lib/mailglass_inbound/internal/operator/timeline.ex
    - mailglass_inbound/lib/mailglass_inbound/internal/operator/detail.ex
    - mailglass_inbound/test/mailglass_inbound/router/matcher_test.exs
    - mailglass_inbound/test/mailglass_inbound/internal/operator/records_test.exs
  modified:
    - mailglass_admin/mix.exs
    - mailglass_admin/config/test.exs
    - mailglass_admin/test/test_helper.exs
    - mailglass_admin/test/support/endpoint_case.ex
    - mailglass_admin/lib/mailglass_admin/router.ex
    - mailglass_admin/lib/mailglass_admin/pub_sub/topics.ex
    - mailglass_admin/lib/mailglass_admin/components.ex
    - mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex
    - mailglass_inbound/lib/mailglass_inbound/router/matcher.ex

key-decisions:
  - "Read-model fetch_tenant_id returns :blank (yielding []/nil) rather than raising like the outbound fetch_tenant_id! — the plan's V1 contract is tenant-required-OR-EMPTY (D-48-04), so the admin gateway never crashes on an unset tenant."
  - "Added :inbound_router to @operator_opts_schema (Rule 3): the plan instructed threading the opt through the synthetic router, but the NimbleOptions schema rejected the unknown key — adding the schema entry is the seam D-48-07 requires."
  - "topics_test.exs placed at test/ (not the lib/ path in files_modified) so the plan's `mix test test/...topics_test.exs` verify command discovers it."
  - "Pre-existing citext_probe.ex reraise Credo warning (exit 16) is out of scope — logged to deferred-items.md; no LINT-06 PrefixedPubSubTopics violation introduced."

patterns-established:
  - "Optional sibling gateway: conditional-compile + apply/3 wrappers keep the consumer free of compile-time references to the optional dep, and Boundary deps stays unchanged so --no-optional-deps compiles."
  - "Inbound read-models live in the OWNING package (Internal.Operator.*, @moduledoc false) and tenant-gate on every query; the admin reaches them only via the runtime gateway."

requirements-completed: [IADM-01, IADM-04, IADM-05]

# Metrics
duration: ~25min
completed: 2026-05-24
---

# Phase 48 Plan 01: Inbound Admin LiveView — Wave 0 Cross-Package Seams Summary

**Laid every cross-package seam InboundLive depends on: a floating optional inbound dep + admin test-DB wiring, `Router.Matcher.explain/2` routing-trace reflection, a tenant-required-or-empty `Internal.Operator.{Records,Timeline,Detail}` read-model, a runtime `OptionalDeps.MailglassInbound` gateway, the consumer-side `inbound_record_inserted/1` topic builder, and a single audited `mask_recipient/1` — all unit/property-tested, no `InboundLive` touched.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-05-24T16:58:00Z
- **Completed:** 2026-05-24T17:11:00Z
- **Tasks:** 4
- **Files modified:** 17 (8 created, 9 modified)

## Accomplishments

- Admin now compiles BOTH with inbound (path dep) and with `--no-optional-deps` (inbound stripped) — the optional-dep contract holds (V4).
- The admin test DB carries inbound migrations and resolves `config :mailglass_inbound, :repo`, so InboundLive-suite fixtures (InboundRecord + InboundEvidence + ExecutionRun) can be inserted (proven by Task 3's records_test inserting full chains).
- `Router.Matcher.explain/2` returns a per-clause verdict list whose AND equals `matches_route?/2` for every route × message over nil/exact/regex matchers × present/absent/nil actuals × header AND-semantics (V3, 500-run property + 8 example tests).
- The inbound read-model is tenant-required-or-empty with cross-tenant isolation, an `__outcomes__/0`-cast outcome filter, and ExecutionRun (never the replay-run schema) as the lineage source (V1, 14 tests).
- Admin and inbound topic builders return the byte-identical string (V8 parity, 4 tests); `mask_recipient/1` is now one public `Components` definition called by `deliveries_list`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Cross-package dependency + admin test-infra wiring** — `4f0a24d` (feat)
2. **Task 2: Router.Matcher.explain/2 reflection + property test** — `1ac9dc1` (feat)
3. **Task 3: Inbound read-model Internal.Operator.{Records,Timeline,Detail} + tenancy test** — `96dc169` (feat)
4. **Task 4: Admin seams — gateway, topic builder, mask_recipient promotion** — `fceba62` (feat)

_TDD tasks were committed as single feat commits (test + impl together) after reaching green; the test files and source ship in the same commit per task._

## Files Created/Modified

**Created:**
- `mailglass_admin/lib/mailglass_admin/optional_deps/mailglass_inbound.ex` — conditional-compile runtime gateway: `available?/0` + `apply/3` wrappers (`list_records`/`timeline`/`detail`/`explain`/`replay`).
- `mailglass_admin/test/mailglass_admin/pub_sub/topics_test.exs` — V8 topic-parity test against the inbound builder.
- `mailglass_admin/test/support/inbound_test_router.ex` — synthetic adopter inbound router (one route of each matcher kind) + a minimal test mailbox.
- `mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex` — recent-inbound list read-model.
- `mailglass_inbound/lib/mailglass_inbound/internal/operator/timeline.ex` — all-runs chronological lineage read-model.
- `mailglass_inbound/lib/mailglass_inbound/internal/operator/detail.ex` — record + evidence + latest-fresh matched-outcome read-model (adds the tenant gate Replay omits).
- `mailglass_inbound/test/mailglass_inbound/router/matcher_test.exs` — V3 reflection property + examples.
- `mailglass_inbound/test/mailglass_inbound/internal/operator/records_test.exs` — V1 tenancy + outcome-cast + timeline/detail isolation.

**Modified:**
- `mailglass_admin/mix.exs` — `mailglass_inbound_dep/0` floating optional helper + a deps line.
- `mailglass_admin/config/test.exs` — `config :mailglass_inbound, :repo, MailglassAdmin.TestRepo`.
- `mailglass_admin/test/test_helper.exs` — inbound migrations into the admin test DB; start `:mailglass_inbound`.
- `mailglass_admin/test/support/endpoint_case.ex` — threads `inbound_router:` into the synthetic operator routes.
- `mailglass_admin/lib/mailglass_admin/router.ex` — `:inbound_router` opt schema + `__operator_session__` surfacing.
- `mailglass_admin/lib/mailglass_admin/pub_sub/topics.ex` — `inbound_record_inserted/1` consumer builder.
- `mailglass_admin/lib/mailglass_admin/components.ex` — public `mask_recipient/1` + `mask_email/2` + `mask_value/1`.
- `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex` — calls `Components.mask_recipient/1`; private copies deleted.
- `mailglass_inbound/lib/mailglass_inbound/router/matcher.ex` — `@doc false explain/2` + `clause_verdict` type.

## Decisions Made

- **Tenant-required-OR-EMPTY, not raise-on-blank.** The outbound analog (`Mailglass.Operator.Deliveries.fetch_tenant_id!`) raises on a blank tenant; the plan's V1 contract (D-48-04) is that a blank/missing tenant returns `[]`/`nil`. I implemented `fetch_tenant_id/1` returning `:blank` so the admin gateway never surfaces a crash on an unset tenant context — this is the deliberate divergence from the analog.
- **`Tenancy.scope/2` is a no-op under the test env's SingleTenant resolver, so cross-tenant isolation is enforced by the explicit `tenant_id` where-clause.** Both are present on every query (belt-and-suspenders): the where-clause guarantees isolation today, and `Tenancy.scope/2` (inbound's first usage) honors an adopter's real resolver.
- **`topics_test.exs` lives in `test/`, not `lib/`.** The plan's `files_modified` listed `lib/.../topics_test.exs`, but the verify command and acceptance grep both reference `test/mailglass_admin/pub_sub/topics_test.exs`; the verify command is authoritative for test discovery.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added `:inbound_router` to `@operator_opts_schema`**
- **Found during:** Task 1 (test-infra wiring)
- **Issue:** The plan instructed threading `inbound_router:` into the synthetic adopter's `mailglass_operator_routes` invocation (D-48-07), but `mailglass_operator_routes/2` validates opts via `NimbleOptions.validate(opts, @operator_opts_schema)` and the schema had no `:inbound_router` key — passing it raised `ArgumentError` at compile time, blocking the task.
- **Fix:** Added an `inbound_router: [type: {:or, [:atom, nil]}, default: nil, doc: ...]` entry to `@operator_opts_schema` and surfaced it (atom, never cookie-sourced) in `__operator_session__/2`. This is the seam D-48-07 requires; the LiveView consumes it in a later wave.
- **Files modified:** `mailglass_admin/lib/mailglass_admin/router.ex`
- **Verification:** Both compile lanes green; `endpoint_case.ex` compiles with the opt threaded.
- **Committed in:** `4f0a24d` (Task 1 commit)

**2. [Rule 1 - Bug] Fixed test generator + call-site argument shape**
- **Found during:** Tasks 2 and 3 (RED→GREEN iteration)
- **Issue:** (a) The matcher property's `headers_gen` used `map_of` over a 3-element key pool, raising `StreamData.TooManyDuplicatesError`. (b) Two records_test call sites passed a bare `"tenant-a"` string where `list_records/2` expects a map/keyword filter, raising `FunctionClauseError`.
- **Fix:** Widened the header-name generator to a roomy alphanumeric space (so unique-key generation never exhausts) while keeping overlap with the clause names; corrected the two call sites to `%{tenant_id: ...}`.
- **Files modified:** `mailglass_inbound/test/mailglass_inbound/router/matcher_test.exs`, `mailglass_inbound/test/mailglass_inbound/internal/operator/records_test.exs`
- **Verification:** matcher_test green (2 properties + 8 tests); records_test green (14 tests).
- **Committed in:** `1ac9dc1` (Task 2), `96dc169` (Task 3)

---

**Total deviations:** 2 auto-fixed (1 blocking schema gap, 1 test bug)
**Impact on plan:** Both auto-fixes were necessary to complete the planned work; no scope creep. The `:inbound_router` schema addition is the exact seam D-48-07 calls for. The read-model's blank-tenant-returns-empty behavior is the plan's stated V1 contract, not a deviation.

## Issues Encountered

- **Stale admin test DB state.** A first `mix test` of the topics test failed on `relation "..._mailgun_fingerprint_idx" already exists` — leftover inbound state from an interrupted migration in the admin DB. Resolved with `mix ecto.drop -r MailglassAdmin.TestRepo && mix ecto.create`. Confirmed core (`00000000000001..5`) and inbound (`20260506..20260523`) migration versions do not overlap, so the two sets coexist cleanly in `schema_migrations`; the test_helper migration is idempotent on a clean DB.

## Deferred Issues

- Pre-existing Credo `reraise` warning in `mailglass_admin/test/support/citext_probe.ex:36` (file not modified by this plan) makes `mix credo --strict` exit 16. Out of scope; logged to `.planning/phases/48-inbound-admin-liveview/deferred-items.md`. No PrefixedPubSubTopics (LINT-06) violation was introduced — all topics route through the builder.

## User Setup Required

None - no external service configuration required. (mix.lock changes from `mix deps.get` were intentionally NOT committed per the worktree/mailglass policy; the orchestrator reconciles intentional new-dep lock entries per package.)

## Next Phase Readiness

- Wave 1 (plan 48-02) can clone the OperatorLive shell against ready seams: the gateway (`OptionalDeps.MailglassInbound`), the read-models, `explain/2`, and the topic builder all exist and are unit/property-tested.
- The synthetic adopter router exposes `inbound_router:` so Wave 2's routing-trace card has declared inbound routes to reflect via `__mailglass_inbound_routes__/0`.
- Blocker/concern: none for downstream waves. The mix.lock for `mailglass_admin` must be reconciled centrally (new `mailglass_inbound` path/optional entry) — handled by the orchestrator, not committed here.

## Threat Surface

No new security-relevant surface beyond the plan's `<threat_model>`. The gateway (T-48-03), read-models (T-48-01), mix.exs dep (T-48-02), and mask_recipient promotion (T-48-04) are exactly the registered surfaces; all mitigations are implemented (Tenancy.scope/2 + tenant where-clause on every read-model query; floating optional dep out of PINS; Boundary deps unchanged; one audited mask definition).

## Self-Check: PASSED

All 8 created source/test files verified present on disk; all 5 commits
(4 task commits + SUMMARY) verified in git log; working tree clean (mix.lock
intentionally excluded per worktree/mailglass policy).

---
*Phase: 48-inbound-admin-liveview*
*Completed: 2026-05-24*
