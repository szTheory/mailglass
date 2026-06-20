---
phase: 116-fixtures-idempotent-ratchet-arm
plan: 01
subsystem: testing
tags: [fixtures, multi-tenant, personas, drift-guard, ecto, exunit, boundary, demo-app]

# Dependency graph
requires:
  - phase: 112-app-shell-navigation-tenant-seam
    provides: "Mailglass.Operator.Tenants.list_tenants/2 tenant picker seam (keys off distinct non-null Delivery.tenant_id)"
provides:
  - "MailglassDemo.Personas — single declarative persona cohort spec (spec/0 + seed!/1 + specimen_literals/0)"
  - "Three-persona stress cohort: northstar (many/high-count/error), fjordline-aps (one/long-ID/non-ASCII/null), helios-void (no-data)"
  - "Demo seed (DemoData.reset!) materializes the cohort at every harness boot — input to RATCHET-04"
  - "Admin test-support OperatorFixtures.seed_persona_cohort!/0 — same cohort into TestRepo via shared spec dir"
  - "Fail-closed persona drift-guard across the 3 materializers (D-07)"
  - "Canonical stress literals (non-ASCII names, long delivery id, long Mailable name) plan 116-04 must mirror"
affects: [116-04-gallery, 116-05-bucket-a, 116-06-ratchet-arm, gallery, tenant-picker, demo-run]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Single declarative spec materialized by N thin builders, guarded fail-closed against drift"
    - "Shared canonical-spec directory compiled into multiple apps via absolute elixirc_paths (A1 fallback for circular path deps)"
    - "Code.ensure_loaded?(Boundary)-guarded use Boundary so a pure shared file stays boundary-clean in the admin app and dep-free in the demo app"

key-files:
  created:
    - "reference/persona_spec/personas.ex"
    - "mailglass_admin/test/mailglass_admin/persona_cohort_test.exs"
    - "mailglass_admin/test/mailglass_admin/persona_drift_guard_test.exs"
  modified:
    - "reference/demo_app/lib/mailglass_demo/demo_data.ex"
    - "reference/demo_app/mix.exs"
    - "mailglass_admin/mix.exs"
    - "mailglass_admin/test/support/operator_fixtures.ex"

key-decisions:
  - "A1 outcome: path dep on whole mailglass_demo app is a CIRCULAR path dep (demo depends on mailglass_admin) — fell back to a shared pure spec dir compiled into both builds"
  - "Non-ASCII from[].name display names live in Delivery.metadata['from'] (the outbound Delivery schema has no structured `from` field)"
  - "Long delivery id stored as provider_message_id; long Mailable name as mailable; truncation stress via those columns"
  - "DemoData.reset! seeds the cohort at harness boot (Personas.seed!/1) — confirmed; feeds RATCHET-04 / plan 116-06"

patterns-established:
  - "Drift-guard reads spec/0 + specimen_literals/0 as single source of truth; spec persona without a materialization fails closed"
  - "Forward-compatible gallery byte-consistency check: vacuous until 116-04 adds fjordline specimens, fails closed once it does"

requirements-completed: [RATCHET-01]

# Metrics
duration: 14min
completed: 2026-06-20
status: complete
---

# Phase 116 Plan 01: Multi-Tenant Persona Stress-Fixture Cohort Summary

**A single declarative `MailglassDemo.Personas` spec materialized by three thin builders (demo seed, admin test-support, gallery-bound literals) with a fail-closed drift-guard — landing northstar/fjordline-aps/helios-void as the keystone stress substrate so the Phase-112 tenant picker has >=2 selectable tenants and a real no-data edge.**

## Performance

- **Duration:** ~14 min
- **Started:** 2026-06-20T20:50:52Z
- **Completed:** 2026-06-20T21:04:33Z
- **Tasks:** 3
- **Files modified:** 7 (3 created, 4 modified)

## Accomplishments

- **`reference/persona_spec/personas.ex`** — the single source of truth: `spec/0` (3 persona maps + 8 edge-case assignments per D-08 + the canonical stress payload literals), `seed!/1` (demo-Repo materializer for fjordline-aps; helios-void by absence; northstar no-op'd because the existing lifecycle seeds it), and `specimen_literals/0` (the gallery-shared literals).
- **Demo seed wired** — `DemoData.reset!` now calls `Personas.seed!(Repo)`; the harness boot (`seeds.exs → reset!`) materializes all three personas. Seed assertion green: distinct non-null `Delivery.tenant_id == ["fjordline-aps","northstar"]` (helios-void correctly absent).
- **Admin-side materializer** — `OperatorFixtures.seed_persona_cohort!/0` reads `Personas.spec/0` and produces the same cohort into `TestRepo`. `persona_cohort_test.exs` (6 tests) asserts: 3 personas seed; `list_tenants/2` returns >=2 incl northstar+fjordline-aps; helios-void absent; helios-void direct-URL renders the no-data overview + deliveries empty copy with no crash (T-116-03).
- **Fail-closed drift-guard** — `persona_drift_guard_test.exs` (7 tests) treats `spec/0` as canonical, asserts the admin materializer cannot diverge (a spec persona without a materialization fails the comparison), asserts the closed 8-edge-case set, and asserts byte-exact spec literals — pinning the values 116-04 must mirror.

## Task Commits

Each task was committed atomically:

1. **Task 1: Declarative Personas spec + parameterized demo seeding** — `fcf56362` (feat)
2. **Task 2: Test-only spec sharing + admin seed_persona_cohort!/0 + cohort test** — `039a9da6` (feat)
3. **Task 3: Persona drift-guard (3 materializers cannot diverge)** — `1ec70439` (test)

_TDD note: Task 1's RED was the inline `mix run` seed assertion failing (`Personas` module absent → `{:error, :nofile}`); GREEN was the spec module + wiring making it print SEED_OK._

## Files Created/Modified

- `reference/persona_spec/personas.ex` (created) — canonical persona cohort spec, pure module (core schemas only) + guarded `use Boundary`.
- `reference/demo_app/lib/mailglass_demo/demo_data.ex` (modified) — `reset!` calls `Personas.seed!(Repo)`.
- `reference/demo_app/mix.exs` (modified) — include the shared `../persona_spec` dir in elixirc_paths (absolute `Path.expand`).
- `mailglass_admin/mix.exs` (modified) — include the shared `../reference/persona_spec` dir in the `:test` elixirc_paths.
- `mailglass_admin/test/support/operator_fixtures.ex` (modified) — `seed_persona_cohort!/0` admin-side materializer.
- `mailglass_admin/test/mailglass_admin/persona_cohort_test.exs` (created) — cohort integration assertion (6 tests).
- `mailglass_admin/test/mailglass_admin/persona_drift_guard_test.exs` (created) — fail-closed drift-guard (7 tests).

## Decisions Made

- **A1 (path-dep compilability) outcome — FALLBACK APPLIED.** A `{:mailglass_demo, path: "../reference/demo_app", only: [:test]}` dep is structurally impossible: the demo app already depends on `mailglass_admin`, so the back-dep is a circular path dep (`** (Mix) ... another project with the same name was already defined`). Per the plan's documented Pitfall-3 fallback, the canonical `Personas` spec was moved to a shared pure directory `reference/persona_spec/` and that single file is compiled directly into BOTH the demo app and the admin `:test` build via absolute-path `elixirc_paths`. This preserves the single-source-of-truth requirement (admin test-support reads `MailglassDemo.Personas.spec/0`) without crossing into prod or the `--no-optional-deps` lane.
- **Boundary classification of the shared file.** The admin app runs the `:boundary` compiler, which flagged the external `MailglassDemo.Personas` as "not included in any boundary" and failed `--warnings-as-errors`. Resolved with a `Code.ensure_loaded?(Boundary)`-guarded top-level `use Boundary, check: [in: false, out: false]` (the documented test-support idiom) — green in admin, inert in the demo app (which doesn't run the boundary compiler).
- **Where the non-ASCII display names live.** The outbound `Delivery` schema has no structured `from` field, so `from[].name` display names (`"Bjørn Hansen"`, `"山田太郎"`) are stored in `Delivery.metadata["from"]`. The drift-guard reads them from there.
- **Verify-query alias correction.** The plan's inline seed assertion referenced `Mailglass.Delivery`; the actual schema module is `Mailglass.Outbound.Delivery` (the plan's read_first authorized this adjustment). Used the correct module throughout.

## Exact Persona Literals (for plan 116-04 to mirror verbatim)

| Specimen | Value |
|----------|-------|
| Non-ASCII display name (Latin extended) | `Bjørn Hansen` |
| Non-ASCII display name (CJK) | `山田太郎` |
| Long delivery ID (provider_message_id) | `del_01JXW9ZQKB3V1N4P2RMT7FHCG` (28 chars) |
| Long Mailable module name (mailable) | `Mailglass.Demo.Mailables.TransactionalEmailWithVeryLongModuleName` (64 chars) |
| Null branch | one `:delivered` Event with `reject_reason: nil` |

`fjordline-aps` recipient: `bjorn.hansen@fjordline-aps.example`. These are exposed programmatically via `MailglassDemo.Personas.specimen_literals/0`; 116-04 should consume that function, not re-type the literals.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Path-dep on whole demo app is a circular path dep — applied documented fallback**
- **Found during:** Task 2 (test-only path dep)
- **Issue:** `{:mailglass_demo, path: "../reference/demo_app", only: [:test], runtime: false}` failed `mix deps.get` with "another project with the same name was already defined" — the demo app depends on `mailglass_admin`, so the back-dep is circular.
- **Fix:** Moved the canonical `personas.ex` to a shared pure dir `reference/persona_spec/` and compiled it into both apps via absolute `elixirc_paths` (the plan's stated Pitfall-3 fallback). Single source of truth preserved.
- **Files modified:** reference/persona_spec/personas.ex (moved), reference/demo_app/mix.exs, mailglass_admin/mix.exs
- **Verification:** Both apps compile `--warnings-as-errors` green; `MailglassDemo.Personas.spec/0` loads in the admin test env.
- **Committed in:** 039a9da6 (Task 2 commit)

**2. [Rule 3 - Blocking] Boundary compiler flagged the shared external module**
- **Found during:** Task 2 (admin test compile)
- **Issue:** Admin's `:boundary` compiler raised "MailglassDemo.Personas is not included in any boundary", failing `--warnings-as-errors` (EXIT=1).
- **Fix:** Added a `Code.ensure_loaded?(Boundary)`-guarded top-level `use Boundary, check: [in: false, out: false]` to the shared file. Boundary-clean in admin; inert in the demo app.
- **Files modified:** reference/persona_spec/personas.ex
- **Verification:** `MIX_ENV=test mix compile --warnings-as-errors` EXIT=0; demo dev compile EXIT=0.
- **Committed in:** 039a9da6 (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 3 — blocking). Both are exactly the A1/Pitfall-3 fallback the plan anticipated. No scope creep.
**Impact on plan:** The shared-dir mechanism replaces the path-dep mechanism but delivers the identical contract (admin test-support consumes the one spec). All success criteria met.

## Issues Encountered

- **Demo-app mix.lock premailex drift (pre-existing, not committed).** The demo_app's frozen baseline lock pins `premailex 0.3.20`, but the current core path-dep requires `premailex ~> 1.0`, so `mix compile`/`mix run` in the demo app needed `mix deps.get` (which also bumps swoosh to 1.26.1). This is the documented baseline-coupling drift. Resolved deps transiently to run the seed assertion; the committed `mix.lock` was left untouched (no lock changes in any commit). This drift is unrelated to this plan and is logged for the milestone's release/baseline coordination.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- **RATCHET-04 / plan 116-06:** Confirmed — `DemoData.reset!` seeds the full cohort at harness boot, so the demo_app Playwright suite (RATCHET-04) runs against rich cohort data with no new harness.
- **Plan 116-04 (gallery widening, Wave 2):** Must consume `MailglassDemo.Personas.specimen_literals/0` for the fjordline specimens. The drift-guard's forward-compatible gallery check is vacuous until 116-04 adds fjordline-namespaced specimens, then fails closed on any byte divergence.
- **No blockers.** The cohort, admin materializer, and drift-guard are all green; `list_tenants/2` returns exactly northstar + fjordline-aps (helios-void absent), giving the Phase-112 picker its >=2-tenant render reason.

## Self-Check: PASSED

- Created files verified on disk: `reference/persona_spec/personas.ex`, `persona_cohort_test.exs`, `persona_drift_guard_test.exs`, `116-01-SUMMARY.md`.
- Task commits verified in git history: `fcf56362`, `039a9da6`, `1ec70439`.
- Verification re-run green: demo dev compile WAE (0), admin test compile WAE (0), 13/13 persona tests pass.

---
*Phase: 116-fixtures-idempotent-ratchet-arm*
*Completed: 2026-06-20*
