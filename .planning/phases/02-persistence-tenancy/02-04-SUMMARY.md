---
phase: 02-persistence-tenancy
plan: 04
subsystem: tenancy
tags: [tenancy, behaviour, oban, process-dict, optional-deps]

# Dependency graph
requires:
  - phase: 02-persistence-tenancy
    provides: "Mailglass.TenancyError from Plan 01 (the :unstamped struct raised by tenant_id!/0), Mailglass.Config :tenancy slot + config/test.exs pointing at Mailglass.Tenancy.SingleTenant from Plan 01, DataCase raw-Process.put forward-reference shim from Plan 01, existing Mailglass.OptionalDeps.Oban gateway from Phase 1"
provides:
  - "Mailglass.Tenancy behaviour — one callback: scope(queryable, context) :: Ecto.Queryable.t() (D-29)"
  - "Mailglass.Tenancy module helpers — current/0, put_current/1, with_tenant/2, tenant_id!/0, scope/2 (D-30)"
  - "Mailglass.Tenancy.SingleTenant — default no-op resolver; current/0 falls back to literal \"default\" (D-31)"
  - "Mailglass.Oban.TenancyMiddleware — conditionally-compiled (Oban.Worker guard) with dual entry: wrap_perform/2 for OSS Oban adopters, call/2 for Oban Pro middleware users (D-33)"
  - "DataCase.with_tenant/2 delegates to Mailglass.Tenancy.with_tenant/2; setup block uses put_current/1 — raw Process.put(:mailglass_tenant_id, ...) removed"
  - "Process-dict key :mailglass_tenant_id is now the ONE stamping seam — consumed by Plan 05 Events.append/1 (auto-stamps tenant_id per D-05) and Plan 06 SuppressionStore.Ecto + Outbound.Projector (scope/2)"
affects: [02-persistence-tenancy plans 05-06, 03-outbound-send (Oban enqueue stamping), 04-webhook (tenant context through job boundary), 05-admin-liveview (on_mount stamping path), 06-lint (LINT-03 NoUnscopedTenantQueryInLib)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Narrow behaviour + module helpers split: `@behaviour Mailglass.Tenancy` declares ONE callback (`scope/2`); the ergonomic helpers (`current/0`, `put_current/1`, `with_tenant/2`, `tenant_id!/0`) live on the module — adopters never implement them. Replicates the accrue `Actor` pattern verbatim with tenant-string semantics."
    - "Process-dict restore-on-raise idiom: `with_tenant/2` reads prior via `Process.get/1`, stamps new value, runs in `try/after`. On exit, `Process.delete/1` when prior was nil, `put_current/1` otherwise. Stack-safe; exception-safe."
    - "Conditional-compile on Oban.Worker (not Oban.Middleware): the `Oban.Middleware` behaviour only exists in Oban Pro. Guarding on `Oban.Worker` means the module compiles whenever OSS Oban is installed, and the same file ships a `call/2` entry point Pro adopters can register directly — no separate Pro vs OSS module."
    - "Resolver indirection through Application.get_env: `Mailglass.Tenancy.scope/2` looks up the adopter resolver via `Application.get_env(:mailglass, :tenancy)`, defaulting to `Mailglass.Tenancy.SingleTenant` when unset. Per D-19 (Phase 1 config pattern), Application.get_env is read directly — Mailglass.Config is for validation at boot, not for hot-path reads."

key-files:
  created:
    - "lib/mailglass/tenancy.ex — Mailglass.Tenancy behaviour + module helpers (146 lines)"
    - "lib/mailglass/tenancy/single_tenant.ex — Default no-op resolver (21 lines)"
    - "test/mailglass/tenancy_test.exs — 12 tests covering put/current, with_tenant restore-on-exception, tenant_id! fail-loud, scope no-op, behaviour contract (117 lines)"
    - "test/mailglass/oban/tenancy_middleware_test.exs — 8 tests covering both call/2 and wrap_perform/2 surfaces (118 lines)"
  modified:
    - "lib/mailglass/optional_deps/oban.ex — extended with conditionally-compiled Mailglass.Oban.TenancyMiddleware module (dual-surface: wrap_perform/2 + call/2); @compile no_warn_undefined list now omits Oban.Middleware (doesn't exist in OSS Oban)"
    - "test/support/data_case.ex — upgraded setup to call Mailglass.Tenancy.put_current/1; with_tenant/2 now delegates to Mailglass.Tenancy.with_tenant/2; raw Process.put removed"

key-decisions:
  - "Plan's `@behaviour Oban.Middleware` requirement cannot be met against OSS Oban 2.21 (that behaviour is Oban Pro only). Substituted a dual-surface module: `call/2` matches the shape Oban Pro's middleware behaviour expects so Pro adopters register it unchanged, plus a `wrap_perform/2` helper OSS adopters invoke from their worker's `perform/1`. Same `Mailglass.Tenancy.with_tenant/2` wrap at both entry points. Compile-guard on `Oban.Worker` (always present in OSS) instead of `Oban.Middleware`. D-33's INTENT (serialize tenant across Oban boundaries) is preserved; the registration surface shifts from `middleware: [...]` to either `middleware: [...]` (Pro) or inline `wrap_perform/2` (OSS). Guide in Phase 7 will document both."
  - "DataCase.setup no longer carries the forward-reference comment linking to Plan 04. The raw `Process.put(:mailglass_tenant_id, ...)` line is gone; `Mailglass.Tenancy.put_current/1` is the one stamping path. Plan 01's shim is fully retired. DataCase.with_tenant/2 is now a one-line delegate — keeping the public helper preserves the ergonomics for plans 05-06 without requiring test authors to switch imports."
  - "current/0 is permissive by design (returns the SingleTenant default when unstamped), tenant_id!/0 is strict (raises TenancyError). This split mirrors the accrue `Actor.current/0` vs `Actor.actor_id!/0` split and lets callers pick the right semantics. Phase 6 `NoUnscopedTenantQueryInLib` will enforce that library-internal call sites use `scope/2` + `current/0`, not `tenant_id!/0` (which is for Oban-worker adopter code after the middleware runs)."
  - "scope/2 resolver lookup reads Application.get_env directly (not Mailglass.Config.get_theme-style cache). Tenancy is not on the render hot path; every scope call reads a single atom from env. A persistent-term cache would save nanoseconds per query while coupling tenancy boot-order to Config.validate_at_boot!/0. Rejected as premature optimization."

patterns-established:
  - "Pattern 1: Tenant stamping is ALWAYS via Mailglass.Tenancy.put_current/1 — never raw Process.put. The public API is the only stamping path so Phase 6 LINT-03 can grep for the direct Process.put AND fail on it. DataCase is the canonical example; adopter on_mount callbacks follow the same shape."
  - "Pattern 2: Block-form restoration. `with_tenant/2` (Mailglass) and `wrap_perform/2` (Oban) both restore the prior tenant on raise via `try/after` + Process.get capture. Any future API that temporarily stamps tenant context follows this pattern."
  - "Pattern 3: Dual-surface optional-dep integration. When a library's behaviour doesn't exist in the OSS version (Oban.Middleware is Pro-only), ship a module that exposes BOTH the behaviour-compatible shape AND an adopter-invokable helper. Same wrap semantics at both entry points. Future Oban.Pro features (priorities, workflows) can extend this module without breaking OSS adopters."

requirements-completed: [TENANT-01, TENANT-02]

# Metrics
duration: 6min
completed: 2026-04-22
---

# Phase 02 Plan 04: Tenancy Surface Summary

**Shipped the `Mailglass.Tenancy` behaviour + process-dict helpers, the `SingleTenant` default resolver, and the conditionally-compiled Oban middleware — establishing the `:mailglass_tenant_id` process-dict seam that Plans 05 / 06 will consume and that Phase 6 LINT-03 will enforce. 20 new tests; 156 total tests green across both compile lanes.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-04-22T18:58:05Z
- **Completed:** 2026-04-22T19:04:13Z
- **Tasks:** 2
- **Files created:** 4
- **Files modified:** 2

## Accomplishments

- `Mailglass.Tenancy` behaviour surfaces exactly one callback (`scope/2`) per D-29; ergonomic helpers (`current/0`, `put_current/1`, `with_tenant/2`, `tenant_id!/0`) live on the module so adopter resolvers never implement them.
- Process-dict key `:mailglass_tenant_id` is stable across all stamping paths — DataCase, Oban middleware, adopter on_mount callbacks all route through `put_current/1`.
- `Mailglass.Tenancy.SingleTenant` ships as the default resolver (configured in `config/test.exs`); `current/0` returns literal `"default"` when unstamped.
- `tenant_id!/0` is the fail-loud variant: raises `Mailglass.TenancyError{type: :unstamped}` when the process dict is unset. Does NOT fall back to SingleTenant default — callers that need that use `current/0`.
- `Mailglass.Oban.TenancyMiddleware` ships with dual entry points:
  - `wrap_perform/2` — OSS adopters invoke from inside their `perform/1`; reads `job.args["mailglass_tenant_id"]` and wraps the body in `with_tenant/2`.
  - `call/2` — Oban Pro's middleware behaviour shape; Pro adopters register via `middleware: [...]` in Oban config.
  - Both converge on `Mailglass.Tenancy.with_tenant/2`; pass-through semantics for missing/non-binary keys; prior-tenant restoration on raise.
- `mix compile --no-optional-deps --warnings-as-errors` still passes — the middleware module is conditionally compiled against `Oban.Worker` and simply does not exist when Oban is absent.
- `Mailglass.DataCase` now delegates through the public Tenancy API — raw `Process.put(:mailglass_tenant_id, ...)` is gone; the forward-reference shim from Plan 01 is retired.
- Full test suite: **156 tests, 0 failures, 1 skipped** (up from 136 baseline — 20 new tests: 12 tenancy + 8 middleware).

## Task Commits

1. **Task 1: `Mailglass.Tenancy` behaviour + SingleTenant default + DataCase upgrade** — `c26f3b2` (feat)
2. **Task 2: `Mailglass.Oban.TenancyMiddleware` (conditionally compiled) + test** — `6588874` (feat)

## Files Created/Modified

**Created (4):**
- `lib/mailglass/tenancy.ex` — behaviour + helpers (146 lines)
- `lib/mailglass/tenancy/single_tenant.ex` — default no-op resolver (21 lines)
- `test/mailglass/tenancy_test.exs` — 12 tests (117 lines)
- `test/mailglass/oban/tenancy_middleware_test.exs` — 8 tests (118 lines)

**Modified (2):**
- `lib/mailglass/optional_deps/oban.ex` — extended with conditionally-compiled `Mailglass.Oban.TenancyMiddleware` (dual-surface: `wrap_perform/2` + `call/2`); removed `Oban.Middleware` from the `no_warn_undefined` compile attribute list since it doesn't exist in OSS Oban.
- `test/support/data_case.ex` — `setup` now calls `Mailglass.Tenancy.put_current/1`; `with_tenant/2` delegates to `Mailglass.Tenancy.with_tenant/2`; raw `Process.put` removed; updated `@moduledoc` to describe the new routing.

## Decisions Made

- **Dual-surface Oban middleware (D-33 preserved against OSS-Oban reality):** The plan assumed `Oban.Middleware` exists as an OSS behaviour it can be `@behaviour`'d against. It doesn't — that behaviour module is Oban Pro only. Rather than drop tenant-serialization through Oban boundaries entirely (D-33's whole point), the module ships BOTH:
  - `call/2` — matches Oban Pro's middleware callback shape (`job` + `next/1`) so Pro adopters register it in their `middleware: [...]` config unchanged.
  - `wrap_perform/2` — zero-arity `fun` wrapper OSS adopters invoke from inside their worker's `perform/1`.
  Both converge on `Mailglass.Tenancy.with_tenant/2`. Compile guard switches from `Oban.Middleware` (nonexistent) to `Oban.Worker` (always present with OSS Oban). Phase 7 DOCS-02 guide documents both paths.
- **No Boundary entry for `Mailglass.Tenancy`:** The root `use Boundary, deps: [], exports: [...]` in `lib/mailglass.ex` currently lists `Message, Telemetry, Config, TemplateEngine, ...`. `Mailglass.Tenancy` is not added yet because no sub-boundary calls into it directly from outside — Plan 06's `Outbound.Projector` and `SuppressionStore.Ecto` will live inside the root boundary. When Phase 3 splits `Mailglass.Outbound` into its own sub-boundary, `Tenancy` gets added to `exports:` in the same commit that adds the sub-boundary. Keeping the change atomic per Phase 1's Renderer sub-boundary precedent.
- **DataCase.with_tenant/2 stays as a delegate:** Could have removed the public helper and asked test authors to use `Mailglass.Tenancy.with_tenant/2` directly. Kept the delegate because (a) pre-existing tests in Plans 01-03 may use `DataCase.with_tenant/2` (none found in the current codebase, but the import is public), (b) the delegate is three lines, (c) it's the "use DataCase, import the helpers" idiom adopters expect from Phoenix-style case templates.
- **scope/2 uses Application.get_env, not :persistent_term:** Resolver lookup is a single atom read from `:mailglass` env. No need to cache. Keeping `:persistent_term` scoped to the brand theme (D-19) avoids boot-order coupling between Tenancy and Config.validate_at_boot!/0.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] `@behaviour Oban.Middleware` targets a Pro-only behaviour**

- **Found during:** Task 2 (`mix test test/mailglass/oban/tenancy_middleware_test.exs --warnings-as-errors`)
- **Issue:** The plan's verbatim Task 2 code declares `@behaviour Oban.Middleware` and guards the conditional compile on `Code.ensure_loaded?(Oban.Middleware)`. OSS Oban 2.21.1 (the version pinned in `mix.exs`) has NO `Oban.Middleware` module — that behaviour ships only in Oban Pro. Confirmed by:
  - `grep -rln "defmodule Oban.Middleware" deps/oban/lib/` → no matches
  - `grep -i middleware deps/oban/CHANGELOG.md` → no matches
  - `npx ctx7 docs /oban-bg/oban "middleware"` → no OSS middleware API in the documentation
  The `if Code.ensure_loaded?(Oban.Middleware) do` guard was always false in the :test env, so the `Mailglass.Oban.TenancyMiddleware` module never existed, so every test in `tenancy_middleware_test.exs` failed with `UndefinedFunctionError`.
- **Fix:** Switched the compile guard to `Code.ensure_loaded?(Oban.Worker)` (which IS present in OSS). Removed the `@behaviour Oban.Middleware` annotation. Dropped `Oban.Middleware` from the `@compile {:no_warn_undefined, [...]}` list. Added a `wrap_perform/2` public function alongside `call/2` so OSS adopters have a documented integration path without fabricating a behaviour. Both functions share the same `case args do ... Mailglass.Tenancy.with_tenant(tenant_id, fn -> ... end) ...` body — same contract, different arity. Extended the moduledoc to distinguish the OSS path (`wrap_perform/2` inside `perform/1`) from the Pro path (`call/2` registered as `middleware: [...]`).
- **Files modified:** `lib/mailglass/optional_deps/oban.ex`, `test/mailglass/oban/tenancy_middleware_test.exs` (4 new `wrap_perform/2` tests added alongside the original 4 `call/2` tests)
- **Verification:** `mix compile --warnings-as-errors` exits 0; `mix compile --no-optional-deps --warnings-as-errors` exits 0 (module absent — the whole `if Code.ensure_loaded?(Oban.Worker) do defmodule ...` elides); `mix test test/mailglass/oban/tenancy_middleware_test.exs --warnings-as-errors` → 8 tests, 0 failures.
- **Committed in:** `6588874` (Task 2 commit)
- **Impact on acceptance criteria:** Plan's criterion "lib/mailglass/optional_deps/oban.ex contains `if Code.ensure_loaded?(Oban.Middleware) do`" is NOT met as written — replaced with `Code.ensure_loaded?(Oban.Worker)`. Plan's criterion "contains `@behaviour Oban.Middleware`" is NOT met — replaced with functional surface (`call/2` + `wrap_perform/2`) that matches the Pro behaviour shape and provides an OSS-friendly helper. All other criteria (module defined, `with_tenant` wiring, test count ≥ 4, both CI lanes pass) are met. The 4 "extra" tests cover `wrap_perform/2` parity with `call/2`.

---

**Total deviations:** 1 auto-fixed (1 bug — the plan referenced a non-existent Oban OSS API)
**Impact on plan:** The deviation is bounded to the middleware surface. D-33's INTENT (serialize `Mailglass.Tenancy.current/0` across Oban job boundaries via the process dict) is preserved with identical semantics (pass-through on missing/non-binary key, restoration on raise). The registration surface diverges: Oban Pro users register unchanged via `middleware: [...]`; OSS adopters call `wrap_perform/2` inside `perform/1`. Phase 7 DOCS-02 guide needs to document both paths — flagging for the Phase 7 planner.

## Issues Encountered

Only the Oban.Middleware absence above. Tenancy behaviour + SingleTenant + DataCase upgrade (Task 1) compiled and tested on first run — the accrue `Actor` reference pattern translated to tenant-string semantics without friction. 12 tenancy tests passed on first `mix test` invocation.

## Downstream Landmines Flagged for Future Plans

- **Plan 05 (Events.append/1):** Consume `Mailglass.Tenancy.current/0` to auto-stamp `tenant_id` per D-05. `current/0` is the correct choice (permissive — falls back to SingleTenant default); `tenant_id!/0` would crash adopters who haven't stamped in a single-tenant deploy. If `current/0` returns nil (possible only when an adopter resolver is configured AND they forgot to stamp), `Event.changeset/1` will fail `validate_required([:tenant_id])` and surface a clean changeset error.
- **Plan 06 (SuppressionStore.Ecto, Outbound.Projector):** Scope every query via `Mailglass.Tenancy.scope/2`. The one-callback behaviour means the lint check (`LINT-03 NoUnscopedTenantQueryInLib`) is a simple AST match: every `Repo.(all|one|get)` of the 3 mailglass schemas must pass through `Mailglass.Tenancy.scope(query, _)`.
- **Phase 3 (Outbound.deliver_later/2):** On enqueue, read `Mailglass.Tenancy.current/0` and merge `{"mailglass_tenant_id" => current()}` into job args BEFORE calling `Oban.insert/1`. This is the Plan-04-side contract: the middleware reads the key; if Phase 3 doesn't write it, tenant context silently drops across the job boundary. Add a `Mailglass.Outbound.put_tenant_in_args/2` helper that centralizes the merge so future enqueue paths stay consistent.
- **Phase 5 (Admin LiveView):** The adopter-facing integration pattern is `Mailglass.Tenancy.put_current(scope.organization.id)` inside `on_mount/4`. Admin module should NOT auto-stamp from `Phoenix.Scope` — per D-32, core stays Phoenix-agnostic. The guide in DOCS-02 is the right layer.
- **Phase 6 (LINT-03 `NoUnscopedTenantQueryInLib`):** Credo AST match on `Repo.*(Mailglass.Outbound.Delivery | Mailglass.Events.Event | Mailglass.Suppression.Entry, ...)` call sites must verify enclosing call chain passes through `Mailglass.Tenancy.scope/2`. Bypass via `scope: :unscoped` opt per TENANT-03. Foundation for this check ships in Plan 04 — the scope/2 callback is the single wrapping seam.
- **Phase 7 (DOCS-02 multi-tenancy guide):** Document BOTH Oban integration paths (OSS `wrap_perform/2` + Pro `middleware: [...]`). Also document the Phoenix 1.8 `%Scope{}` on_mount pattern per D-32.

## Threat Surface Scan

No new security-relevant surface introduced beyond the plan's documented threat register. All T-02-01a..T-02-01d dispositions hold:
- **T-02-01a (scope/2 is the single tenant-filter seam):** Holds. `Mailglass.Tenancy.scope/2` is the ONLY behaviour callback; the lint check in Phase 6 has a deterministic AST target.
- **T-02-01b (tenant_id!/0 fails loud on unstamped):** Holds. Test `raises TenancyError when unstamped — does NOT fall back to SingleTenant default` proves the contract.
- **T-02-01c (process-dict key namespace):** Holds. `:mailglass_tenant_id` is a unique atom; `put_current/1` and `current/0` encapsulate the key so it never appears in callers.
- **T-02-01d (Oban middleware binary-guard):** Holds. Both `call/2` and `wrap_perform/2` pattern-match on `%{"mailglass_tenant_id" => tenant_id} when is_binary(tenant_id)` — non-binary and missing-key cases pass through unchanged. Test `passes through when mailglass_tenant_id is not a string` proves the guard.
- **T-02-11 (tenant_id plaintext in Oban args):** Accepted per plan. Adopters whose tenant_id scheme is PII (email-as-tenant-id) must pseudonymize before stamping; Phase 7 DOCS-02 calls this out.

No threat flags — the dual-surface middleware doesn't introduce new trust boundaries, it uses the SAME `Mailglass.Tenancy.with_tenant/2` wrap at both entry points.

## Next Plan Readiness

- `mix compile --warnings-as-errors` exits 0.
- `mix compile --no-optional-deps --warnings-as-errors` exits 0 (TenancyMiddleware module absent — conditionally compiled).
- `mix test --warnings-as-errors` → 156 tests, 0 failures, 1 skipped.
- `Mailglass.Tenancy.put_current/1`, `current/0`, `with_tenant/2`, `tenant_id!/0`, `scope/2` all present — Plan 05 `Events.append/1` can begin.
- `Mailglass.Oban.TenancyMiddleware.wrap_perform/2` available — Phase 3 `Outbound.deliver_later/2` has a clean integration shape for worker-body wrapping.
- Process-dict key `:mailglass_tenant_id` is the single stamping seam — Phase 6 LINT-03 has a clear grep target for the enforcement check.

## Self-Check: PASSED

All 4 created files exist on disk:
- `lib/mailglass/tenancy.ex`
- `lib/mailglass/tenancy/single_tenant.ex`
- `test/mailglass/tenancy_test.exs`
- `test/mailglass/oban/tenancy_middleware_test.exs`

All 2 task commits present in `git log --oneline`:
- `c26f3b2` (Task 1 feat)
- `6588874` (Task 2 feat)

Verified via:
```
[ -f lib/mailglass/tenancy.ex ] && [ -f lib/mailglass/tenancy/single_tenant.ex ] \
  && [ -f test/mailglass/tenancy_test.exs ] \
  && [ -f test/mailglass/oban/tenancy_middleware_test.exs ]
git log --oneline --all | grep -q c26f3b2
git log --oneline --all | grep -q 6588874
```

---
*Phase: 02-persistence-tenancy*
*Completed: 2026-04-22*
