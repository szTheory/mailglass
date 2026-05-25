---
phase: 49-inbound-runtime-operator-tooling
plan: 01
subsystem: mailglass_inbound (runtime config + ingress rate limiter + telemetry)
tags: [rate-limiting, ets, nimble-options, telemetry, ingress, config, dos-deflection]
requires:
  - "MailglassInbound.Ingress.Plug.persist_and_respond/5 (existing post-verify/post-tenant seam)"
  - "Mailglass.RateLimitError struct (reused, built internally)"
  - "MailglassInbound.Telemetry single-span surface (extended)"
provides:
  - "MailglassInbound.Config — validated :mailglass_inbound retention + rate_limit accessor"
  - "MailglassInbound.RateLimiter.check/3 — 3-bucket post-verify leaky-bucket limiter"
  - "MailglassInbound.RateLimiter.TableOwner — :mailglass_inbound_rate_limit ETS owner"
  - "MailglassInbound.Telemetry.rate_limit/2, suppression_flag/2, prune/2 span helpers (for plans 02/03)"
  - "HTTP 429 + Retry-After ingress branch in Ingress.Plug"
affects:
  - "mailglass_inbound/lib/mailglass_inbound/application.ex (new supervised child)"
  - "mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex (new rate-limit branch)"
  - "mailglass_inbound/lib/mailglass_inbound/telemetry.ex (whitelist + 3 spans)"
tech-stack:
  added: []  # zero new deps (D-49-11)
  patterns:
    - "Leaky-bucket continuous-refill ETS token bucket (:ets.update_counter/4, cloned verbatim from core)"
    - "NimbleOptions schema-before-moduledoc validated config accessor (style-mirror of Mailglass.Config)"
    - "Single-span telemetry surface with PII denylist (NoPiiInTelemetryMeta) + 4-segment event convention"
    - "Non-raising {resp, meta} plug egress (429 mirrors the TenancyError 422 idiom)"
key-files:
  created:
    - mailglass_inbound/lib/mailglass_inbound/config.ex
    - mailglass_inbound/lib/mailglass_inbound/rate_limiter.ex
    - mailglass_inbound/lib/mailglass_inbound/rate_limiter/table_owner.ex
    - mailglass_inbound/test/mailglass_inbound/config_test.exs
    - mailglass_inbound/test/mailglass_inbound/rate_limiter_test.exs
  modified:
    - mailglass_inbound/lib/mailglass_inbound/application.ex
    - mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex
    - mailglass_inbound/lib/mailglass_inbound/telemetry.ex
    - mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs
decisions:
  - "Telemetry event names ship 4-segment ([:mailglass_inbound, :ingress, :rate_limit, *] and [:mailglass_inbound, :prune, :sweep, *]) to satisfy the lint-enforced TelemetryEventConvention, deviating from the CONTEXT's 3-segment names"
  - "Limiter takes plain check/3 args (no test seam) and calls MailglassInbound.RateLimiter directly from the plug (honest-surface, no dead override config)"
metrics:
  duration_minutes: 13
  tasks_completed: 3
  files_created: 5
  files_modified: 4
  tests: "42 (config 14 + rate_limiter 7 + plug 25, all green --seed 0)"
  completed: 2026-05-25
---

# Phase 49 Plan 01: Inbound Runtime Config + Post-Verify Rate Limiter Summary

Inbound ingress now has DoS deflection at the HTTP boundary: a post-verify three-bucket
leaky-bucket limiter (tenant 1000/min → recipient 500/min → sender_domain 200/min) that
returns HTTP 429 with a per-bucket `Retry-After`, plus a validated package-local
`MailglassInbound.Config` accessor and three PII-free telemetry span helpers that plans 02
(suppression) and 03 (prune) consume.

## What Was Built

- **`MailglassInbound.Config`** — NimbleOptions `@schema` declared before `@moduledoc` (so
  `NimbleOptions.docs/1` interpolates), reading the **`:mailglass_inbound`** app env (D-49-02
  boundary law — no inbound keys added to core `Mailglass.Config`). Locked D-49-03 shape:
  `retention: [records_days: 90, evidence_days: 30, execution_runs_days: 90, replay_runs_days: 30]`
  with `:infinity` accepted per class; `rate_limit:` 3-bucket tree. `validate_at_boot!/0` +
  typed `retention/0` / `rate_limit/0` accessors (defaults merge over overrides). Only the knobs
  the runtime reads — no speculative per-tenant override maps (honest-surface).
- **`MailglassInbound.RateLimiter`** — `check/3` (tenant_id, recipient, sender_domain). The
  `check_bucket/2` `:ets.update_counter/4` refill math is copied **verbatim** from
  `Mailglass.RateLimiter`. Fail-fast `with` chain in order tenant→recipient→sender_domain; the
  first bucket to trip returns **its own** `refill_per_ms` as `Retry-After` (never a cross-bucket
  max). Builds `Mailglass.RateLimitError` internally (`:per_tenant` for tenant, `:per_domain` for
  recipient + sender_domain) with PII-free `context: %{bucket, limit, retry_after_ms}`. No stream
  bypass clause, no `%Mailglass.Message{}` coupling. PII comment cites D-49-16 (sender keyed on
  domain only; recipient may key on full address — node-local ETS, never logged).
- **`MailglassInbound.RateLimiter.TableOwner`** — init-and-idle GenServer owning the
  `:mailglass_inbound_rate_limit` ETS table with OTP-27 opts copied verbatim
  (`:set, :public, :named_table, read_concurrency: true, write_concurrency: :auto,
  decentralized_counters: true`). `name: __MODULE__` carries the documented LINT-07/LIB-05
  singleton exception note. Added to `MailglassInbound.Application` children alongside
  `Task.Supervisor`. The prune Oban worker is deliberately **not** registered (D-49-28).
- **`Ingress.Plug` rate-limit branch** — inserted in `persist_and_respond/5` after
  `resolve_tenant!` + `normalize_request!`, before persist (post-verify, post-tenant, pre-persist;
  D-49-14). On `:ok` proceeds unchanged; on `{:error, %RateLimitError{}}` it **never raises** —
  classifies the bucket type, computes `retry_after_s = max(1, ceil(retry_after_ms / 1000))`, sets
  the `retry-after` header, sends 429 `%{status: "rate_limited", bucket: "<type>"}`, and returns
  the `{resp, meta}` tuple. The persisting tail was extracted into `persist_and_dispatch/7` so the
  short-circuit returns before persist without duplicating logic.
- **Three telemetry span helpers** in the single-span `MailglassInbound.Telemetry` surface:
  `rate_limit/2`, `suppression_flag/2`, `prune/2`. Whitelist extended with the PII-free keys
  `bucket, limit, retry_after, flagged, records_deleted, evidence_deleted, fresh_runs_deleted,
  replay_runs_deleted`. `suppression_flag/2` and `prune/2` are forward-looking infrastructure for
  plans 02/03 (this plan's objective explicitly requires them).

## How It Was Verified

- `cd mailglass_inbound && mix test test/mailglass_inbound/{config_test,rate_limiter_test,ingress/plug_test}.exs --seed 0` → **42 tests, 0 failures**.
- TDD gate sequence: `test(49-01)` RED commit (d41e99a) → `feat(49-01)` GREEN commits (bdc9875, e5ae195).
- `mix credo --strict` (repo root, covers `mailglass_inbound/lib/`) → **no issues** (PII denylist + 4-segment event convention both green). Validated by RUNNING credo per project memory.
- `cd mailglass_inbound && mix compile --no-optional-deps --warnings-as-errors` → **green** (no bare optional-dep refs introduced; did NOT run `--force` on shared `_build`).
- IOPS-04 success criteria proven by tests: 3-bucket trip order with per-bucket Retry-After; forged request → 401 with budget intact (post-verify invariant); rate_limit `:stop` telemetry carries bucket TYPE only (no recipient/sender/to/from/email value keys); concurrent-load test asserts exactly `capacity` successes (ETS atomicity).
- `mix.lock` (inbound + root) unchanged in all commits — phase adds zero deps.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 — Blocking] Fetched already-declared deps in the fresh worktree**
- **Found during:** Task 0 RED gate.
- **Issue:** The worktree had no `mailglass_inbound/deps` or root `deps` installed, so `mix test`/`mix credo` could not run.
- **Fix:** Ran `mix deps.get` in `mailglass_inbound/` and at the repo root. These fetch **already-declared** deps resolved from the existing lockfiles (not a new package install) — neither `mix.lock` was modified by the fetch.
- **Files modified:** none committed (deps are gitignored).
- **Commit:** n/a.

**2. [Rule 1 — Convention conflict] Telemetry event names adjusted to 4 segments**
- **Found during:** Task 2 (credo run).
- **Issue:** The CONTEXT (D-49-17/29) named the events `[:mailglass_inbound, :rate_limit, :stop]` and `[:mailglass_inbound, :prune, :stop]` — 3 final segments. The lint-enforced `TelemetryEventConvention` (Engineering DNA, `[root, domain, resource, action]`) requires **4** final segments; the 2-segment span prefixes tripped 2 credo warnings.
- **Fix:** Ship `[:mailglass_inbound, :ingress, :rate_limit, *]` (rate-limit is an ingress-path event, beside `:suppression_flag`) and `[:mailglass_inbound, :prune, :sweep, *]`. Same resource names, convention-compliant. The deviation is documented in the telemetry moduledoc and the rate_limit telemetry test asserts the corrected event name.
- **Files modified:** `mailglass_inbound/lib/mailglass_inbound/telemetry.ex`, `mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs`.
- **Commit:** e5ae195.

### Acceptance-criterion grep mismatches (no code defect)

- Task 1 criterion `grep -v '^#' rate_limiter.ex | grep -c "transactional" == 0`: the only match was a moduledoc line stating the bypass is **absent**; reworded to "No stream-based bypass clause" so the literal criterion now returns 0. There was never a `:transactional` code clause.
- Task 2 criterion `grep -n "rate_limit, :stop\|suppression_flag, :stop\|prune, :stop"`: returns nothing because the inbound telemetry module uses the single-span surface (`:telemetry.span/3`, which appends `:stop` at runtime), not literal `:telemetry.execute([..., :stop], ...)`. The three spans ARE defined (telemetry.ex lines 149/166/182) and the `:stop` emission is proven by the plug telemetry-PII test (`assert_receive {[:mailglass_inbound, :ingress, :rate_limit, :stop], ...}`). Intent (three PII-free helpers in the single-span module) is satisfied.

## Documented IOPS-04 Deviations (pre-decided, carried forward)

- IOPS-04 "configurable via `Mailglass.Config`" ships as inbound-local `MailglassInbound.Config` reading `:mailglass_inbound` (D-49-02 boundary law).

## Threat Model Coverage

- **T-49-01 (DoS, limiter placement):** limiter sits in `persist_and_respond/5` after verify + `resolve_tenant!` — forged-payload flood returns 401 before any budget is read. Asserted by the forged-401-budget-intact test.
- **T-49-02 (Info disclosure, telemetry + 429 body):** body + telemetry carry bucket TYPE only; sender keyed on domain. Asserted by the PII-absence telemetry test + the `NoPiiInTelemetryMeta` denylist (credo green).
- **T-49-03 (DoS, limiter raising → 500 storm):** the branch returns `{resp, meta}`, never raises. Asserted by the 429 test (no rescue path hit).
- **T-49-05 (Input validation, config):** `MailglassInbound.Config.validate_at_boot!/0` raises `NimbleOptions.ValidationError` on bad shapes. Asserted by config_test negative cases.
- **T-49-04 (per-node ETS):** accepted/documented (per-node scope note in the RateLimiter moduledoc, D-49-18).

## No Known Stubs

`suppression_flag/2` and `prune/2` are unused-in-this-plan but are explicitly required deliverables consumed by plans 02/03 — forward infrastructure, not stubs.
