---
phase: 49-inbound-runtime-operator-tooling
plan: 03
subsystem: mailglass_inbound
tags: [mix-tasks, doctor, replay, prune, retention, advisory-lock, mime, operator-tooling]
requires:
  - "MailglassInbound.Config.retention/0 (49-01)"
  - "MailglassInbound.Telemetry.prune/2 span (49-01)"
  - "MailglassInbound.Router.Matcher.matches_route?/2"
  - "MailglassInbound.Internal.Replay.replay/2"
  - "MailglassInbound.OptionalDeps.Oban gateway"
  - "Mailglass.OptionalDeps.GenSmtp.available?/0 (core)"
provides:
  - "mix mailglass.inbound.doctor (DNS-free three-state-exit config doctor)"
  - "mix mailglass.inbound.replay (selector -> single-record replay iteration)"
  - "mix mailglass.inbound.prune (batched advisory-locked retention sweep)"
  - "MailglassInbound.Internal.Doctor.run/1"
  - "MailglassInbound.Internal.Prune.prune/0 + lock_key/0"
  - "MailglassInbound.Operator.Formatter (render_human/2 + render_json/1)"
  - "MailglassInbound.Prune.Worker (Oban-guarded, never auto-registered)"
  - "MailglassInbound.Router.Route.:source {file, line} reflection field"
affects:
  - "mailglass_inbound/lib/mailglass_inbound/router.ex (route/2 captures __CALLER__)"
  - "mailglass_inbound/lib/mailglass_inbound/router/route.ex (:source field)"
tech-stack:
  added: []
  patterns:
    - "Batched DELETE WHERE id IN (SELECT id ... LIMIT 1000 FOR UPDATE SKIP LOCKED) looped"
    - "Session pg_try_advisory_lock single-run guard (first in repo)"
    - "Three-state mix-task exit via exit({:shutdown, N}) (0/1/2)"
    - "Route-conflict via runtime-matcher reuse + witness-probe synthesis"
    - "Oban-optional worker behind file-top Code.ensure_loaded?(Oban.Worker)"
key-files:
  created:
    - mailglass_inbound/lib/mailglass_inbound/operator/formatter.ex
    - mailglass_inbound/lib/mailglass_inbound/internal/doctor.ex
    - mailglass_inbound/lib/mailglass_inbound/internal/prune.ex
    - mailglass_inbound/lib/mailglass_inbound/prune/worker.ex
    - mailglass_inbound/lib/mix/tasks/mailglass.inbound.doctor.ex
    - mailglass_inbound/lib/mix/tasks/mailglass.inbound.replay.ex
    - mailglass_inbound/lib/mix/tasks/mailglass.inbound.prune.ex
    - mailglass_inbound/test/mailglass_inbound/internal/doctor_test.exs
    - mailglass_inbound/test/mailglass_inbound/internal/prune_test.exs
    - mailglass_inbound/test/mix/tasks/mailglass_inbound_doctor_test.exs
    - mailglass_inbound/test/mix/tasks/mailglass_inbound_replay_test.exs
    - mailglass_inbound/test/mix/tasks/mailglass_inbound_prune_test.exs
  modified:
    - mailglass_inbound/lib/mailglass_inbound/router/route.ex
    - mailglass_inbound/lib/mailglass_inbound/router.ex
decisions:
  - "Prune resolves the host repo (config :mailglass_inbound, :repo) directly, not the thin MailglassInbound.Repo facade — the facade does not expose query!/2 or delete_all/2 needed for advisory locks + batched deletes."
  - "Prune window field is inserted_at (matches Webhook.Pruner age semantics)."
  - "@prune_lock_key is a fixed bigint constant (6_318_741_290_553_217_001) so cron + ops mix runs serialize."
  - "Prune typed-confirmation threshold is 0 (always require a typed 'yes' unless --yes) — simplest honest destructive tier; counting candidate rows for a true threshold was out of scope."
  - "Doctor + replay + prune tasks omit `use Boundary` (deliberate 49-03 deviation from D-49-04 literal wording; inbound runs no :boundary compiler). Boundary law still honored."
metrics:
  duration_minutes: 23
  completed: 2026-05-25
  tasks: 3
  tests_added: 39
  files_created: 12
  files_modified: 2
---

# Phase 49 Plan 03: Inbound Operator Mix Tasks Summary

DNS-free `mix mailglass.inbound.doctor` (three-state exit + MIME-03 report + matcher-reuse route-conflict detection), selector-driven `mix mailglass.inbound.replay`, and a batched advisory-locked `mix mailglass.inbound.prune` that runs with or without Oban — the inbound sibling of the shipped outbound operator toolbox.

## What Shipped

### IOPS-01 + MIME-03 — `mix mailglass.inbound.doctor`
- `MailglassInbound.Internal.Doctor.run/1` runs entirely DNS-free reflection checks: router configured + compiles (absent -> a `:cannot_diagnose` marker), `>= 1` route, each mailbox compiled + `function_exported?(:process, 1)`, provider signing-key **presence only** (Postmark/SendGrid `:basic_auth`, Mailgun `:signing_key` — the finding text is explicit it never verifies a signature), MIME backend via `Mailglass.OptionalDeps.GenSmtp.available?/0` + `Application.spec(:gen_smtp, :vsn)` (no bare optional-dep ref).
- Route-conflict detection **reuses** `MailglassInbound.Router.Matcher.matches_route?/2` (never re-implements match semantics): structural subsumption (broad-before-narrow) -> `:fail`, witness-probe shadow (synthesize an `%InboundMessage{}` from a later route's exact-string matchers and run the earlier route's matcher) -> `:fail`, regex-vs-regex overlap -> `:warn`. Conflict findings name `router.ex:LINE` via the new `Route.:source` field.
- `MailglassInbound.Operator.Formatter` clones `Mailglass.Deliverability.Formatter` adapted to the D-49-05 finding shape `%{check, status, title, observed, remediation, evidence}`; `render_json/1` emits one `%{summary, findings}` object.
- `Mix.Tasks.Mailglass.Inbound.Doctor` computes the three-state exit (`exit({:shutdown, N})`: 2 cannot-diagnose -> 1 fail/strict-warn -> 0), with `--strict` warn-promotion, `--format human|json`, `--verbose`; `Mix.raise` is reserved for CLI misuse only.

### IOPS-02 — `mix mailglass.inbound.replay`
- Resolves `--record-id` / `--since <iso8601>` / `--tenant <id>` (AND-combinable) into an id list via a parameterized `from(r in InboundRecord, where: ...)` query (selectors never interpolated), then iterates the shipped single-record `Internal.Replay.replay/2` (which appends `source: :replay`, append-only).
- `[y/N]` defaults **No** via `Mix.shell().yes?/1`; `--yes`/`-y` skips the prompt; `--dry-run` reports count + scope without replaying; zero matches -> exit `0` with "nothing to replay."

### IOPS-03 — `mix mailglass.inbound.prune`
- `MailglassInbound.Internal.Prune.prune/0` (Oban-independent) reads windows from `MailglassInbound.Config.retention/0`, deletes in batches of 1000 (`DELETE WHERE id IN (SELECT id ... LIMIT 1000 FOR UPDATE SKIP LOCKED)` looped until `< 1000`), the whole sweep serialized by a session `pg_try_advisory_lock` (concurrent run -> `{:ok, :locked_out}`, deletes nothing). Child-first windows: replay_runs (`source=:replay` 30d) -> fresh_runs (`source=:fresh` 90d) -> evidence (30d) -> records (90d); `source` filtered via `ExecutionRun` (never `ReplayRun`). `:infinity` on a class disables that window with no DELETE issued. Emits `[:mailglass_inbound, :prune, :sweep, :stop]` with per-table counts only.
- `MailglassInbound.Prune.Worker` is an Oban worker behind a file-top `if Code.ensure_loaded?(Oban.Worker)` guard (stub `available?/0 -> false` otherwise); **never auto-registered** (the 49-01 Application already documents this).
- `Mix.Tasks.Mailglass.Inbound.Prune` runs `prune/0` **synchronously whether or not Oban is present** (no `available?()` gate — the honest improvement over `mailglass.webhooks.prune`); destructive tier is `--dry-run` + a typed `yes` confirmation + `--yes` for cron/CI.

### Supporting reflection
- `MailglassInbound.Router.Route` gains an additive `:source` (`{file, line}`) field; `Router.route/2` captures `{__CALLER__.file, __CALLER__.line}` at compile time. Backward-compatible (defaults to `nil`); runtime match semantics unchanged.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Prune resolves the host repo, not the thin `MailglassInbound.Repo` facade**
- **Found during:** Task 2 (prune internal test GREEN phase)
- **Issue:** `MailglassInbound.Repo` is a narrow delegating facade that exposes only `transact/insert/one/multi/all/get` — it has no `query!/2` (needed for `pg_try_advisory_lock`) or `delete_all/2` (needed for batched deletes). Calling `prune/0` blew up with `MailglassInbound.Repo.query!/2 is undefined`.
- **Fix:** `Internal.Prune.prune/0` resolves the configured host repo directly via `Application.get_env(:mailglass_inbound, :repo)` (a real `Ecto.Repo` with full SQL surface), keeping the `repo:` opt override for tests. Documented inline why the facade is bypassed.
- **Files modified:** `mailglass_inbound/lib/mailglass_inbound/internal/prune.ex`
- **Commit:** 0ea4bc2

**2. [Rule 3 - Blocking] Advisory-lock + batched-delete test runs on a real (non-sandboxed) connection**
- **Found during:** Task 0/2 (prune test)
- **Issue:** The batched sweep commits between batches and uses session-scoped advisory locks — neither works inside the per-test Sandbox transaction. The cross-session lock probe also needs a second real Postgrex connection.
- **Fix:** The prune test uses `Sandbox.checkout(TestRepo, sandbox: false)` + `{:shared, self()}` mode, TRUNCATEs at setup-start (rows persist across tests as real commits), and opens a separate `Postgrex` connection (clean conn opts, dropping the Sandbox pool) to hold the lock for the `{:ok, :locked_out}` assertion. This is the RESEARCH-flagged advisory-lock-under-sandbox seam, resolved with a genuine cross-session lock (no telemetry-only fallback needed).
- **Files modified:** `mailglass_inbound/test/mailglass_inbound/internal/prune_test.exs`
- **Commit:** 0ea4bc2

### Documented (carried from plan)
- `use Boundary` is omitted on all three mix tasks (orchestrator-resolved deviation from D-49-04's literal wording — `mailglass_inbound` runs no `:boundary` compiler). Each task carries a one-line comment documenting this; the boundary LAW (inbound depends on core, never the reverse) is still honored.
- The `:signals.suppression_flagged` / `MailglassInbound.Config` deviations belong to plans 49-01/49-02, not this plan.

## Verification

- `cd mailglass_inbound && mix test <5 plan-49-03 files> --seed 0` -> **39 tests, 0 failures.**
- `cd mailglass_inbound && mix compile --no-optional-deps --warnings-as-errors` -> clean (Oban worker stub branch compiles; gen_smtp via gateway). Recompiled WITH optional deps afterward and re-ran the prune suite (Oban-present path) green.
- `mix credo --strict` on all 9 touched lib files -> **no issues** (no bare optional-dep ref; prune telemetry carries counts only; the `ReplayRun` references in `prune.ex` are documentation-only — `source` is filtered via `ExecutionRun`).
- Router/matcher + docs_contract regression suites green (the `Route.:source` addition is backward-compatible).
- `mix.lock` unchanged (inbound clean; the pre-existing dirty root `mix.lock` was deliberately not staged).

## Acceptance-Criteria Greps (all satisfied)
- `pg_try_advisory_lock` present in `internal/prune.ex` (2 occurrences).
- `FOR UPDATE SKIP LOCKED` present in `internal/prune.ex` (3 occurrences).
- `source` is NOT filtered via `ReplayRun` (the 2 `ReplayRun` matches are moduledoc/comment guidance; the query uses `ExecutionRun`).
- No `available?()` Oban gate in `mailglass.inbound.prune.ex` (0).
- No `use Boundary` directive on any task (line-anchored grep: NONE; only explanatory comments).
- `matches_route?` reused in `internal/doctor.ex`; `Application.spec(:gen_smtp` MIME report present; `source:` `__CALLER__` capture present in `router.ex`.

## Known Stubs
None. The optional `Prune.Worker` Oban stub branch (`available?/0 -> false`) is the intended degraded fallback, not a placeholder. The prune typed-confirmation threshold is a deliberate "always confirm" (threshold 0); candidate-row counting for a numeric threshold is out of scope (planner discretion).

## Self-Check: PASSED
All 8 created files present on disk; all 4 commits (0f56774, 5191e57, 0ea4bc2, b8baac8) found in git history.
