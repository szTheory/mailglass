---
phase: 133-repo-facade-prefix-injection-multi-threading
plan: "01"
subsystem: core/schema-isolation
tags:
  - schema-prefix
  - ecto-multi
  - facade
  - FACADE-01
  - FACADE-02
dependency_graph:
  requires:
    - "132-01 (Mailglass.Config.schema/0 accessor + :persistent_term cache)"
  provides:
    - "put_prefix/1 (private) — schema prefix injected via Keyword.put_new at every facade op"
    - "multi_opts/1 (public) — per-step prefix injector for Ecto.Multi builders"
    - "aggregate/4 with optional opts arg (3-arg callers source-compatible)"
    - "Events.insert_opts/1 both clauses carry prefix: Config.schema()"
    - "Outbound 5 Multi builder steps + inner insert_all carry prefix: Config.schema()"
    - "Escalation insert_suppression carries prefix: Config.schema()"
    - "unresolved_orphans_query/2 bakes prefix via put_query_prefix/2 (belt-and-suspenders)"
  affects:
    - "134 (migration entrypoint — depends on this facade being correct)"
    - "135 (inbound mirror — mirrors this pattern)"
tech_stack:
  added: []
  patterns:
    - "Keyword.put_new(opts, :prefix, Mailglass.Config.schema()) — explicit caller :prefix wins"
    - "Ecto.Query.put_query_prefix/2 — bakes prefix into correlated subquery struct"
    - "Ecto.Multi per-step opts threading (Repo.multi_opts/1)"
key_files:
  created: []
  modified:
    - lib/mailglass/repo.ex
    - lib/mailglass/events.ex
    - lib/mailglass/outbound.ex
    - lib/mailglass/suppression/escalation.ex
    - lib/mailglass/operator/support_summary.ex
    - config/test.exs
    - test/mailglass/repo_test.exs
    - test/mailglass/repo_multi_test.exs
decisions:
  - "config/test.exs pins :schema to 'public' so existing suite continues using public schema; schema-isolation tests override per-test via Application.put_env"
  - "put_prefix/1 is private (lives beside repo/0); multi_opts/1 is public (lives beside multi/2) — no new Mailglass.Persistence module"
  - "aggregate/3 callers in operator/suppressions.ex and operator/deliveries.ex remain source-compatible via default opts arg"
  - "escalation.ex insert opts carry prefix: Config.schema() explicitly for clarity even though the facade Repo.insert/2 also injects it — belt-and-suspenders"
  - "replay_targets.ex audit: both load_candidate/3 raw-string queries are top-level Repo.one calls — covered by facade; no code change needed"
metrics:
  duration: "~10 minutes"
  completed: "2026-07-02T22:45:00Z"
  tasks_completed: 3
  files_modified: 8
status: complete
---

# Phase 133 Plan 01: Repo Facade Prefix Injection + Multi Threading Summary

Threaded runtime `prefix: Config.schema()` injection through the `Mailglass.Repo` facade (universal choke point) and per-step into the three `Ecto.Multi` builders, plus one defensive `put_query_prefix/2` on the correlated orphans subquery.

## What Was Built

**One-liner:** Runtime schema prefix injection via `put_prefix/1` + `multi_opts/1` through every mailglass read/write, with per-step Multi builder threading in Events/Outbound/Escalation and defensive `put_query_prefix` on the orphans subquery.

### Artifacts This Phase Produces

| Artifact | Location | Description |
|----------|----------|-------------|
| `put_prefix/1` (private) | `lib/mailglass/repo.ex` | Injects `prefix: Config.schema()` via `Keyword.put_new` into every delegated op |
| `multi_opts/1` (public, `opts \\ []`) | `lib/mailglass/repo.ex` | Per-step prefix injector for Multi builders in domain modules |
| `aggregate/4` with `opts \\ []` | `lib/mailglass/repo.ex` | 3-arg callers remain source-compatible; opts passed to underlying repo |
| `insert_opts/1` both clauses | `lib/mailglass/events.ex` | Both the idempotency-key clause and fallback carry `prefix: Config.schema()` |
| 5 Multi builder steps | `lib/mailglass/outbound.ex` | All insert/insert_all/update steps carry `Repo.multi_opts()` |
| Inner `repo.insert_all` | `lib/mailglass/outbound.ex` | Inner step in `insert_batch/1` carries `prefix:` explicitly (footgun 2: inner steps don't inherit executor opts) |
| `insert_suppression` opts | `lib/mailglass/suppression/escalation.ex` | `Repo.insert` opts carry `prefix: Config.schema()` |
| `put_query_prefix/2` | `lib/mailglass/operator/support_summary.ex` | Correlated not-exists subquery gets prefix baked into query struct |

## Decisions Made

1. **`config/test.exs` gets `config :mailglass, :schema, "public"`** — the existing test suite runs against `public` (pre-2.0). The dedicated schema-isolation integration test (Plan 02 FACADE-04) creates its own `mailglass` schema in-process.

2. **`multi_opts/1` is public in `Mailglass.Repo`** — domain modules (Events, Outbound, Escalation) need to call it from outside the facade module. No new `Mailglass.Persistence` module created.

3. **`aggregate/4` default arg** — The two existing 3-arg callers (`operator/suppressions.ex:63`, `operator/deliveries.ex:32`) are source-compatible with the new `aggregate(queryable, agg, field, opts \\ [])` signature.

4. **Escalation has explicit prefix in opts** — Even though `Repo.insert/2` now injects prefix via `put_prefix/1`, the explicit `prefix: Config.schema()` in `insert_suppression`'s opts makes the threading site visible in code review and provides belt-and-suspenders.

## Replay Targets Audit Conclusion

`lib/mailglass/operator/replay_targets.ex` — **top-level coverage confirmed, no code change.**

Both `load_candidate/3` queries:
- `from(webhook_event in "mailglass_webhook_events", ...)` at l.101 → `Repo.one(Tenancy.scope(query, tenant_id))` at l.112
- `from(webhook_event in "mailglass_webhook_events", ...)` at l.124 → `Repo.one(Tenancy.scope(query, tenant_id))` at l.137

Both execute as top-level queryables through the facade's `Repo.one/2`, which now calls `put_prefix(opts)`. They are NOT wrapped as subqueries anywhere else in the codebase. `fetch_delivery/2` (l.52) and `fetch_delivery_events/2` (l.65) also run through `Repo.one`/`Repo.all` — covered by the facade.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical config] Added `config :mailglass, :schema, "public"` to test.exs**
- **Found during:** Task 1 GREEN verification
- **Issue:** Without a `:schema` config in `test.exs`, `Config.schema/0` returns `"mailglass"` (the Phase 132 default), but the test database tables live in `public`. The citext probe (and all existing tests) use `Mailglass.Repo.one/2` which now injects `prefix: "mailglass"` — tables not found, 11-attempt exhaustion.
- **Fix:** Added `config :mailglass, :schema, "public"` to `config/test.exs` so the entire test suite uses `public`. The repo_test.exs prefix-injection tests override this per-test via `Application.put_env + :persistent_term.erase` with a `CapturingFakeRepo` that doesn't hit the real DB.
- **Files modified:** `config/test.exs`
- **Commit:** `be7a16a6`

**2. [Rule 1 - Credo] Removed planning artifact tokens from comments**
- **Found during:** Task 3 verification (`mix credo --strict`)
- **Issue:** Comments in `lib/mailglass/events.ex` and `lib/mailglass/operator/support_summary.ex` contained `Phase 133` and `D-05` — banned by `Mailglass.Credo.NoPlanningArtifactComments` check (patterns `\bPhase\s+\d+` and `\bD-\d{1,3}\b`).
- **Fix:** Rewrote comments to use behavior-focused rationale without artifact tokens.
- **Files modified:** `lib/mailglass/events.ex`, `lib/mailglass/operator/support_summary.ex`
- **Commit:** `de34a2ea`

## Known Stubs

None — all threading sites are wired to `Mailglass.Config.schema()` (the live persistent_term-cached value). No placeholder data or hardcoded schema strings.

## Threat Flags

None — no new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries beyond the intended prefix injection described in the plan's threat model.

## Verification Results

- `mix test test/mailglass/repo_test.exs` — 28 tests, 0 failures
- `mix test test/mailglass/repo_multi_test.exs` — 10 tests, 0 failures
- `mix compile --warnings-as-errors` — clean
- `mix credo --strict` — 0 issues in changed files (1 pre-existing `D-15` in inbound app.ex, out of scope)
- `grep -rn '@schema_prefix' lib/` — no results (D-03 satisfied)
- `grep -c 'defp put_prefix' lib/mailglass/repo.ex` — 1
- `grep -c 'def multi_opts' lib/mailglass/repo.ex` — 1
- `grep -c 'put_query_prefix' lib/mailglass/operator/support_summary.ex` — 1
- All `{:unsafe_fragment, ...}` conflict targets byte-unchanged
- Postgrex.Error rescue blocks + `translate_postgrex_error/2` in repo.ex byte-unchanged

## Commits

| Hash | Message |
|------|---------|
| `c7d7cd97` | test(133-01): add failing tests for put_prefix/1 + multi_opts/1 facade injection (RED) |
| `be7a16a6` | feat(133-01): add put_prefix/1 + multi_opts/1 to Mailglass.Repo facade (GREEN) |
| `bb880c83` | test(133-01): add failing tests for Events Multi builder prefix threading (RED) |
| `a3abe87f` | feat(133-01): thread prefix per-step into Events/Outbound/Escalation Multi builders (GREEN) |
| `de34a2ea` | feat(133-01): defensive put_query_prefix on orphans subquery + fix Credo comments |

## Self-Check: PASSED

All created/modified files confirmed present on disk. All 5 task commits confirmed in git log.
