---
phase: 45-inbound-telemetry-idempotency-foundation
plan: 01
subsystem: testing
tags: [ecto, postgres, sandbox, credo, telemetry, gen_smtp, ci, mailglass_inbound]

# Dependency graph
requires:
  - phase: 44.5
    provides: shipped mailglass_inbound 0.1.0 (config-less library facade, 4 migrations, in-memory FakeRepo/ReplayRepo test stubs)
provides:
  - MailglassInbound.TestRepo (Postgres-backed test repo) + inbound config/ tree
  - migration-running test_helper.exs (all 4 inbound migrations applied, sandbox :manual)
  - dedicated inbound Postgres CI job (inbound_test)
  - Credo --strict cross-package coverage of mailglass_inbound (TELE-06 mechanism live)
  - NoBareOptionalDepReference covering inbound (catches bare :mimemail outside the gateway)
  - TelemetryEventConvention accepting the :mailglass_inbound event root
  - gen_smtp 1.3.0 as an inbound optional dep (Plan 03 MIME parser prerequisite)
  - api_stability stable inventory entries for MailglassInbound.PubSub.Topics + MailglassInbound.MIMEError
affects: [45-02, 45-03, TELE-08 replay convergence property, Plan 03 real MIME parser]

# Tech tracking
tech-stack:
  added: ["{:gen_smtp, \"~> 1.3\", optional: true} in mailglass_inbound (resolved 1.3.0)"]
  patterns:
    - "Sibling-package test repo mirrors core: use Ecto.Repo + config/test.exs :repo facade + pool-override-during-migration in test_helper"
    - "Custom Credo checks accept a LIST of allowed gateway modules per optional dep so sibling-package gateways are exempted"
    - "Credo files.included widened per-package; check-level included_path_prefixes widened selectively (Oban/GenSmtp yes, Clock no)"

key-files:
  created:
    - mailglass_inbound/test/support/test_repo.ex
    - mailglass_inbound/config/config.exs
    - mailglass_inbound/config/test.exs
    - mailglass_inbound/config/dev.exs
    - mailglass_inbound/config/prod.exs
    - mailglass_inbound/.gitignore
  modified:
    - mailglass_inbound/mix.exs
    - mailglass_inbound/mix.lock
    - mailglass_inbound/test/test_helper.exs
    - .github/workflows/ci.yml
    - .credo.exs
    - credo_checks/telemetry_event_convention.ex
    - credo_checks/no_bare_optional_dep_reference.ex
    - mailglass_inbound/docs/api_stability.md

key-decisions:
  - "Scoped NoDirectDateTimeNow to core only this phase (inbound has no clock-injection seam; routing replay-lineage timestamps through Mailglass.Clock is out of Wave-0 scope) — plan-sanctioned alternative to widening"
  - "Made NoBareOptionalDepReference gated_modules values accept a list; mapped Oban + GenSmtp to both core and MailglassInbound gateways so the inbound gateway is a legitimate call site"
  - "Did NOT commit core mix.lock churn — the worktree's mix deps.get re-resolved many core deps to newer versions; reverted to the phase base so only mailglass_inbound/mix.lock (gen_smtp) is committed"
  - "Added inbound config/{dev,prod}.exs stubs so config.exs's import_config resolves in every env"
  - "Added mailglass_inbound/.gitignore (root .gitignore anchors /_build//deps/ to repo root, not the sibling package)"

patterns-established:
  - "Inbound test DB lifecycle: ecto.create -r MailglassInbound.TestRepo, migrate all, pool override during migration, sandbox :manual"
  - "Credo check params support single-or-list gateway modules via List.wrap for cross-package gateway exemption"

requirements-completed: [TELE-06]

# Metrics
duration: 13min
completed: 2026-05-22
---

# Phase 45 Plan 01: Inbound Telemetry + Idempotency Foundation (Test/Lint Infra) Summary

**Postgres-backed MailglassInbound.TestRepo with migration-running test_helper, a dedicated inbound CI job, and cross-package Credo coverage that provably lints mailglass_inbound (TELE-06 mechanism) — the Wave 0 prerequisite that unblocks the TELE-08 replay-convergence property and inbound PII linting.**

## Performance

- **Duration:** 13 min
- **Started:** 2026-05-22T22:22:55Z
- **Completed:** 2026-05-22T22:36:15Z
- **Tasks:** 3
- **Files modified:** 16 (across all three commits)

## Accomplishments
- `MailglassInbound.TestRepo` connects to a real Postgres test DB with all 4 inbound migrations applied; the dedupe unique indexes (`mailglass_inbound_records_postmark_idempotency_idx`, `mailglass_inbound_records_sendgrid_fingerprint_idx`) exist in the test DB, and the sandbox starts in `:manual`. All 65 existing inbound unit tests pass against the new bootstrap.
- `mix credo --strict` from repo root now provably lints `mailglass_inbound/` (361 source files, up from a tree that never read inbound). The widening surfaced 7 pre-existing inbound issues; all resolved (see disposition below).
- `NoBareOptionalDepReference` now covers inbound so a bare `:mimemail`/`Oban` reference outside a gateway is caught (verified by probe — Plan 03 depends on this).
- `gen_smtp` 1.3.0 resolved into `mailglass_inbound/mix.lock` at the vetted core pin (checksum `0b73fbf…`); the no-optional-deps compile lane stays green.
- A dedicated `inbound_test` Postgres CI job was added (postgres:16-alpine, working-directory mailglass_inbound, `mix test --exclude property`).
- `api_stability.md` stable inventory now names `MailglassInbound.PubSub.Topics` and `MailglassInbound.MIMEError` (Wave 1 surfaces), keeping that file out of the parallel Wave-1 plans.

## Task Commits

Each task was committed atomically:

1. **Task 1: Inbound config + TestRepo + gen_smtp optional dep** - `f6fbe33` (feat)
2. **Task 2: Migration-running test_helper + inbound Postgres CI job** - `b07420b` (feat)
3. **Task 3: Credo cross-package coverage + TelemetryEventConvention widening + api_stability inventory** - `3879186` (feat)

**Plan metadata:** committed by the orchestrator after wave merge (worktree mode — SUMMARY committed separately below).

## Files Created/Modified
- `mailglass_inbound/test/support/test_repo.ex` - `MailglassInbound.TestRepo` (Postgres adapter, otp_app :mailglass_inbound)
- `mailglass_inbound/config/config.exs` - `import_config "#{config_env()}.exs"`
- `mailglass_inbound/config/test.exs` - TestRepo credentials + `config :mailglass_inbound, :repo, MailglassInbound.TestRepo`
- `mailglass_inbound/config/{dev,prod}.exs` - stubs so import_config resolves in all envs
- `mailglass_inbound/.gitignore` - sibling-package build artifacts (root .gitignore anchors to repo root)
- `mailglass_inbound/mix.exs` - `elixirc_paths` (test/support) + `{:gen_smtp, "~> 1.3", optional: true}`
- `mailglass_inbound/mix.lock` - gen_smtp 1.3.0 resolved
- `mailglass_inbound/test/test_helper.exs` - Ecto.Migrator run-all (pool override) + TestRepo start + sandbox :manual
- `.github/workflows/ci.yml` - new `inbound_test` job
- `.credo.exs` - files.included widened to inbound; gated_modules list-valued; NoBareOptionalDepReference + TelemetryEventConvention widened; NoDirectDateTimeNow scoped to core with rationale
- `credo_checks/telemetry_event_convention.ex` - accepts `:mailglass` or `:mailglass_inbound` roots (List.wrap)
- `credo_checks/no_bare_optional_dep_reference.ex` - gateway value may be a single module or a list
- `mailglass_inbound/docs/api_stability.md` - PubSub.Topics + MIMEError added to stable inventory

## Credo Coverage Verification (required by plan)

**Temporary blocked-reference probe result:** PASSED. Injected a throwaway `def __credo_probe__(job), do: Oban.insert(job)` into `MailglassInbound.Ingress.Persist` (a non-gateway inbound module), ran `mix credo --strict` from root, and confirmed `NoBareOptionalDepReference` flagged it with the message `Optional dependency call \`Elixir.Oban.insert\` must go through \`Elixir.Mailglass.OptionalDeps.Oban\` or ...` on the `mailglass_inbound/lib/...` path. Reverted the probe; `mix credo --strict` returns to 0 issues. This proves the widening is not silent non-coverage (RESEARCH Pitfall 1 / threat T-45-01).

**Pre-existing inbound violations surfaced by widening `files.included`:** 7 total, all in `mailglass_inbound/lib/`:

| # | Check | Location | Disposition |
|---|-------|----------|-------------|
| 1 | Readability (trailing whitespace) | ingress/persist.ex:88 | FIXED — removed the stray blank line (Rule 1) |
| 2 | NoBareOptionalDepReference (`Oban.insert`) | optional_deps.ex:66 | FIXED at the check level — false positive: line 66 is inside `MailglassInbound.OptionalDeps.Oban`, the sanctioned inbound gateway. Made gated_modules accept a list and added the inbound gateway as an allowed call site. |
| 3-7 | NoDirectDateTimeNow (`DateTime.utc_now/0`) | persist.ex:116, sendgrid.ex:45, postmark.ex:41, execution_run.ex:61, replay_run.ex:60 | SCOPED OUT — kept `NoDirectDateTimeNow` core-only this phase (inbound has no clock-injection seam; several sites stamp replay-lineage timestamps; routing them through `Mailglass.Clock` is a runtime refactor outside Wave-0). Documented inline in `.credo.exs` with a tracking note (plan-sanctioned alternative to widening). |

After dispositions, `mix credo --strict` reports 0 issues across 361 files.

## Decisions Made
- See `key-decisions` in frontmatter. The load-bearing one: the worktree's `mix deps.get` repeatedly re-resolved core deps to newer versions (e.g. ecto 3.13.5→3.14.0, decimal 2→3, sigra 0.2→1.20), rewriting the core `mix.lock`. This is a worktree-toolchain (Elixir 1.19/OTP 28) artifact and is entirely out of scope for 45-01, which only intended to add `gen_smtp` to the inbound lockfile. The core `mix.lock` was reverted to the phase base before staging; only `mailglass_inbound/mix.lock` is committed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed trailing whitespace surfaced by Credo widening**
- **Found during:** Task 3
- **Issue:** `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex:88` had a blank line with trailing whitespace, flagged once `--strict` started reading inbound.
- **Fix:** Removed the stray blank line at the start of `load_duplicate/5`.
- **Files modified:** mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex
- **Verification:** `mix credo --strict` clean.
- **Committed in:** 3879186

**2. [Rule 1 - Bug] Fixed NoBareOptionalDepReference false positive on the inbound Oban gateway**
- **Found during:** Task 3
- **Issue:** Widening the check's prefix to inbound flagged the legitimate `Oban.insert()` call inside `MailglassInbound.OptionalDeps.Oban` (the sanctioned inbound gateway). The check only exempted the single core gateway module per dep.
- **Fix:** Made `gated_modules` values accept a single module OR a list (`List.wrap` in `allowed_module?` and the message builder); mapped `Oban` and `GenSmtp` to both the core and `MailglassInbound` gateways in `.credo.exs`.
- **Files modified:** credo_checks/no_bare_optional_dep_reference.ex, .credo.exs
- **Verification:** Existing check unit tests still pass (7); `mix credo --strict` clean; probe confirms a non-gateway bare ref still fires.
- **Committed in:** 3879186

**3. [Rule 3 - Blocking] Added inbound config/{dev,prod}.exs stubs**
- **Found during:** Task 1
- **Issue:** `config.exs` uses `import_config "#{config_env()}.exs"` (mirroring core), which raises if the per-env file is missing. Core has dev/prod; inbound did not.
- **Fix:** Created minimal `dev.exs`/`prod.exs` stubs so import_config resolves in every env (e.g. docs build in :dev).
- **Files modified:** mailglass_inbound/config/dev.exs, mailglass_inbound/config/prod.exs
- **Verification:** `mix compile --no-optional-deps --warnings-as-errors` exits 0.
- **Committed in:** f6fbe33

**4. [Rule 3 - Blocking] Added mailglass_inbound/.gitignore**
- **Found during:** Task 1
- **Issue:** `mix deps.get`/`mix compile` created `mailglass_inbound/_build` and `mailglass_inbound/deps`, which the root `.gitignore` does not cover (its `/_build//deps/` patterns anchor to the repo root).
- **Fix:** Added `mailglass_inbound/.gitignore` ignoring the sibling-package build artifacts.
- **Files modified:** mailglass_inbound/.gitignore
- **Verification:** `git check-ignore` confirms both dirs are ignored.
- **Committed in:** f6fbe33

---

**Total deviations:** 4 auto-fixed (2 bugs, 2 blocking). Plus 1 scoping decision (NoDirectDateTimeNow core-only, plan-sanctioned) and 1 out-of-scope revert (core mix.lock churn).
**Impact on plan:** All auto-fixes necessary for correctness or to complete the task. No scope creep — the only new files beyond the plan's list are the config/{dev,prod}.exs stubs and .gitignore, both required for the planned changes to function.

## Issues Encountered
- **Worktree mix deps.get rewrites core mix.lock.** Running `mix deps.get` at the worktree root (needed to make `mix credo`/`mix test` runnable) re-resolved many core deps to newer versions under the local Elixir 1.19/OTP 28 toolchain, producing a large `mix.lock` diff (including major bumps). Resolved by reverting the core `mix.lock` to the phase base after each verification run and confirming the final working tree leaves it untouched. Only `mailglass_inbound/mix.lock` (gen_smtp 1.3.0) is committed. This leaves the worktree's local `deps` newer than the committed core lock; verification was run while the tree was internally consistent, then the lock restored before staging.
- **Pre-existing `mix format` drift in inbound (local 1.19/28 only).** Logged to `.planning/phases/45-inbound-telemetry-idempotency-foundation/deferred-items.md`. Affects untouched inbound files; CI pins Elixir 1.18/OTP 27 where they are formatted correctly. Not fixed (out of scope; reformatting under 1.19 would diverge from the CI baseline).

## Threat Flags
None — no new security-relevant surface beyond the plan's threat model. The test-DB and Credo-scope boundaries (T-45-01, T-45-02) were the intended mitigation targets and are now in place.

## Known Stubs
None — no hardcoded empty/placeholder data wired to UI. The `MailglassInbound.PubSub.Topics` / `MailglassInbound.MIMEError` api_stability entries document Wave-1 surfaces that land in Plans 02/03; this is intentional forward-declaration (the modules themselves are not created here), not a stub.

## User Setup Required
None - no external service configuration required. CI provides Postgres via a service container; local runs need a reachable Postgres (the existing project convention).

## Next Phase Readiness
- TELE-08's replay-convergence property (Wave 2) can now exercise the real Postgres unique-index dedupe via `MailglassInbound.TestRepo`.
- Plan 03's real MIME parser can rely on `gen_smtp`/`:mimemail` being resolvable in inbound test/dev, and `NoBareOptionalDepReference` will catch any bare `:mimemail` reference outside the (forthcoming) `MailglassInbound.OptionalDeps.GenSmtp` gateway.
- Wave-1 plans (02/03) can land `MailglassInbound.PubSub.Topics` and `MailglassInbound.MIMEError` without touching api_stability.md (already inventoried).
- Note for the orchestrator/verifier: the committed core `mix.lock` is intentionally unchanged; do not interpret the worktree's locally-upgraded `deps` as a committed change.

## Self-Check: PASSED

- All 8 created/key files present on disk.
- All 4 commits present in git history (f6fbe33, b07420b, 3879186, 3fd6c19).
- Core `mix.lock` confirmed identical to phase base (no unintended dependency churn committed).
- `gen_smtp` confirmed pinned in `mailglass_inbound/mix.lock`.

---
*Phase: 45-inbound-telemetry-idempotency-foundation*
*Completed: 2026-05-22*
