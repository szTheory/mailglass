---
phase: 03-transport-send-pipeline
plan: "10"
subsystem: testing
tags: [test-infrastructure, mailer-case, async-safety, oban, gap-closure, hi-01]
dependency_graph:
  requires:
    - 03-06 (MailerCase introduction — the bug originated here)
    - 03-07 (Outbound.Worker Oban dep — queue name :mailglass_outbound)
  provides:
    - Guarded async_adapter mutation in MailerCase (HI-01 closed)
    - Snapshot/restore pattern for Application env in test setup
    - Mailglass.ObanHelpers with maybe_create_oban_jobs/0
    - oban_jobs table available in test DB for @tag oban: :manual tests
  affects:
    - All adopter test suites using Mailglass.MailerCase with async: true
    - @tag oban: :manual tests that assert_enqueued(worker: Mailglass.Outbound.Worker)
tech_stack:
  added: []
  patterns:
    - "Snapshot Application env before setup, restore exact snapshot in on_exit (not hard-coded value)"
    - "unless async? do guard for global Application.put_env writes in CaseTemplate setup"
    - "Code.ensure_loaded? gate + Ecto.Migrator.with_repo for optional-dep DB migrations in test helper"
key_files:
  created:
    - test/support/oban_helpers.ex
  modified:
    - test/support/mailer_case.ex
    - test/test_helper.exs
key_decisions:
  - "HI-01 fix: guard Application.put_env(:mailglass, :async_adapter, :task_supervisor) with `unless async? do` — async: true tests never write global env"
  - "on_exit snapshots prior value via Application.get_env before setup mutations; restores exact prior (delete_env if nil, put_env otherwise) — not unconditionally :oban"
  - "Oban migrations not in priv/repo/migrations/ (adopter-owned); ObanHelpers.maybe_create_oban_jobs/0 provides runtime migration in test harness via Oban.Migrations.up/0 (v14 — latest in Oban 2.21.1)"
  - "async: true tests that need deliver_later must pass async_adapter: :task_supervisor as deliver_later/2 opt (outbound.ex:331 already honours Keyword.get(opts, :async_adapter))"
metrics:
  duration: "approx 3min"
  completed: "2026-04-23"
  tasks: 2
  files_modified: 3
requirements-completed: [TEST-02]
---

# Phase 3 Plan 10: MailerCase async-adapter env race fix (HI-01) Summary

**Closed HI-01: MailerCase global :async_adapter mutation guarded with `unless async? do`; on_exit now restores the pre-setup snapshot instead of hard-coding :oban; ObanHelpers wires Oban.Migrations.up/0 so @tag oban: :manual tests have the oban_jobs table.**

## Performance

- **Duration:** approx 3 min
- **Completed:** 2026-04-23
- **Tasks:** 2
- **Files created:** 1
- **Files modified:** 2

## What Shipped in Each Task

### Task 1: Guard async_adapter mutation and fix on_exit restore (commit 6567d3e)

`test/support/mailer_case.ex` — three changes to the `setup tags do` block:

**Change 1 — Pre-setup snapshot (line 111):**
```elixir
prior_async_adapter = Application.get_env(:mailglass, :async_adapter)
```
Captured before any mutation so on_exit can restore the exact prior state.

**Change 2 — Guard the global write (lines 158-160):**
```elixir
unless async? do
  Application.put_env(:mailglass, :async_adapter, :task_supervisor)
end
```
Concurrent async tests no longer race on this global write. Async tests that exercise `deliver_later/2` pass `async_adapter: :task_supervisor` as a per-call opt instead.

**Change 3 — Faithful on_exit restore (lines 172-176):**
```elixir
if prior_async_adapter != nil do
  Application.put_env(:mailglass, :async_adapter, prior_async_adapter)
else
  Application.delete_env(:mailglass, :async_adapter)
end
```
Replaces the unconditional `Application.put_env(:mailglass, :async_adapter, :oban)` that would silently corrupt adopter boot configs.

**Moduledoc additions:**
- "Async tests and deliver_later/2" section explaining the per-call opt pattern
- `@tag oban: :manual` doc updated with oban_jobs table prerequisite

### Task 2: Document and wire Oban :manual test path (commit 7b482f9)

**Investigation result:** No oban_jobs migration in `priv/repo/migrations/` (two files: `00000000000001_mailglass_init.exs`, `00000000000002_add_idempotency_key_to_deliveries.exs`). Oban migrations are adopter-owned. `Code.ensure_loaded?(Oban.Migrations)` returns `true` — Oban 2.21.1 is in deps.

**`test/support/oban_helpers.ex`** — new file:
- `Mailglass.ObanHelpers.maybe_create_oban_jobs/0`: calls `Oban.Migrations.up/0` via `Ecto.Migrator.with_repo/2` to create `oban_jobs` table
- Guarded by `Code.ensure_loaded?(Oban.Migrations)` — no-op when Oban absent
- `rescue _ -> :ok` makes it safe on a warmed DB (Oban uses CREATE TABLE IF NOT EXISTS semantics)
- Moduledoc documents full `@tag oban: :manual` usage pattern with `assert_enqueued/1`

**`test/test_helper.exs`** — added after mailglass migrations:
```elixir
Mailglass.ObanHelpers.maybe_create_oban_jobs()
```

## Verification Results

| Check | Result |
|-------|--------|
| `grep prior_async_adapter mailer_case.ex` | 3 lines (assignment + two uses in on_exit) |
| `grep "unless async?" mailer_case.ex` | 1 line (the guard) |
| `grep "put_env(:mailglass, :async_adapter, :oban)" mailer_case.ex` | empty (unconditional restore gone) |
| `test/support/oban_helpers.ex` exists | FOUND |
| `grep ObanHelpers test/test_helper.exs` | 1 line (wired) |
| `mix compile --warnings-as-errors` | 0 warnings |
| `mix compile --no-optional-deps --warnings-as-errors` | 0 warnings |
| `mix test --only phase_03_uat` | 61 tests, 0 failures, 2 skipped |

## Deviations from Plan

None — plan executed exactly as written.

The plan offered two oban_helpers.ex variants (documentation-only if migration present, runtime helper if absent). Migration was absent, so the runtime helper variant was created as specified.

## Threat Mitigations Verified

| Threat ID | Status |
|-----------|--------|
| T-3-10-01 (Tampering: concurrent async tests stomping :async_adapter) | MITIGATED — `unless async?` guard prevents global write for async: true tests |
| T-3-10-02 (Tampering: on_exit unconditionally restores :oban) | MITIGATED — snapshot/restore pattern preserves pre-setup value |
| T-3-10-03 (DoS: oban_jobs table missing) | MITIGATED — ObanHelpers.maybe_create_oban_jobs/0 called in test_helper.exs |

## Known Stubs

None — both changes are fully implemented. No placeholder text or hardcoded empty values introduced.

## Self-Check: PASSED

Files verified present:
- `test/support/mailer_case.ex` — FOUND (modified, commit 6567d3e)
- `test/support/oban_helpers.ex` — FOUND (created, commit 7b482f9)
- `test/test_helper.exs` — FOUND (modified, commit 7b482f9)

Commits verified:
- 6567d3e: fix(03-10): guard async_adapter mutation and fix on_exit restore — FOUND
- 7b482f9: feat(03-10): add ObanHelpers and wire maybe_create_oban_jobs — FOUND

`mix test --only phase_03_uat` re-confirmation: 61 tests, 0 failures, 2 skipped — PASSED

---
*Phase: 03-transport-send-pipeline*
*Completed: 2026-04-23*
