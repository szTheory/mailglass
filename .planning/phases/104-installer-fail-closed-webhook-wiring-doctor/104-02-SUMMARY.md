---
phase: 104-installer-fail-closed-webhook-wiring-doctor
plan: 02
subsystem: installer
tags: [fail-closed, installer, webhook-wiring, doctor, static-scan, mix-task]
dependency_graph:
  requires: [104-01]
  provides: [INSTALL-01, INSTALL-02, INSTALL-03, INSTALL-04]
  affects: []
tech_stack:
  added: []
  patterns: [fail-closed-with-chain, static-file-scan, three-state-exit-code, boundary-classified-mix-task]
key_files:
  modified:
    - lib/mailglass/installer/apply.ex
    - lib/mix/tasks/mailglass.install.ex
  created:
    - lib/mailglass/installer/doctor.ex
    - lib/mix/tasks/mailglass.doctor.ex
decisions:
  - "validate_preflight/1 fail-closed via {:error, {:unmanaged_parser_conflict, path}} — returns :ok on --force and on both no-conflict branches (no-endpoint-file + no-conflict else) so the with-chain happy path is preserved"
  - "format_error/1 new clause inserted before the catch-all (line 147) — rides the existing {:error, reason} -> Mix.raise(format_error(reason)) rail at lines 61-62, no new routing"
  - "Mailglass.Installer.Doctor uses static File.read! scan only — no app.start, no Code.ensure_loaded?, no function_exported? (D-09)"
  - "cannot_diagnose counted separately from fail in summarize/1 via evidence flag — ensures exit 2 (missing endpoint) is distinct from exit 1 (absent wiring)"
  - "use Boundary, classify_to: Mailglass on mailglass.doctor.ex (copied from mail.doctor.ex:2) — required because core runs the :boundary compiler (Pitfall 5)"
  - "Mailglass.Installer.Templates accessors used for managed-block markers in doctor.ex — never hardcoded strings (single source of truth)"
metrics:
  duration: "8 minutes"
  completed: "2026-06-17"
  tasks: 2
  files: 4
---

# Phase 104 Plan 02: Installer Fail-Closed + Webhook-Wiring Doctor — GREEN Implementation Summary

## One-Liner

Fail-closed installer preflight (validate_preflight/1 → {:error, {:unmanaged_parser_conflict, path}} → Mix.raise with actionable message) and a static-scan `mix mailglass.doctor` (0/1/2 exit codes) turning all 104-01 RED tests GREEN.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Fail-closed validate_preflight/1 + Apply.run/2 wiring + format_error/1 clause (INSTALL-01/02) | 194fc8b2 | lib/mailglass/installer/apply.ex, lib/mix/tasks/mailglass.install.ex |
| 2 | New mix mailglass.doctor task + Mailglass.Installer.Doctor static-scan runner (INSTALL-03) | 29ae7bc4 | lib/mailglass/installer/doctor.ex, lib/mix/tasks/mailglass.doctor.ex |

## What Was Built

### Task 1: apply.ex + mailglass.install.ex (INSTALL-01/02)

**EDIT 1 — `validate_preflight/1` fail-closed:**
Replaced the warn-and-discard `Mix.shell().info([:yellow, ...])` block (apply.ex:66-73) with a fail-closed shape. When the endpoint exists, the managed block is stripped, and `plug Plug.Parsers` without `body_reader` is detected:
- No `--force`: returns `{:error, {:unmanaged_parser_conflict, endpoint_path}}`
- With `--force`: returns `:ok`

Both the no-conflict `else` and the no-endpoint-file `else` (the `if File.exists?` branch) now explicitly return `:ok` — critical for the `with :ok <- validate_preflight(opts)` chain to pass through the happy path (Pitfall 2 from plan RESEARCH.md).

**EDIT 2 — `Apply.run/2` with-chain:**
Changed the bare `validate_preflight(opts)` statement (return discarded) into the first link of the `with` chain: `with :ok <- validate_preflight(opts), {:ok, manifest} <- ...`. The `@spec` is unchanged — `{:error, {:unmanaged_parser_conflict, _}}` is already covered by `{:error, term()}`.

**EDIT 3 — `format_error/1` new clause (mailglass.install.ex):**
Added one `defp format_error({:unmanaged_parser_conflict, endpoint_path})` clause before the catch-all at line 147. The message names: endpoint path, the silent-401 production risk, `body_reader: {Mailglass.Webhook.CachingBodyReader, :read_body, []}` as the fix, and `--force` as the escape hatch. The new error rides the existing `{:error, reason} -> Mix.raise(format_error(reason))` rail (lines 61-62) — unchanged.

### Task 2: doctor.ex + mailglass.doctor.ex (INSTALL-03)

**`Mailglass.Installer.Doctor` (lib/mailglass/installer/doctor.ex):**
Pure static runner. `run/1` resolves `otp_app` via `Plan.detect_otp_app()` and derives `endpoint_path = "lib/#{otp_app}_web/endpoint.ex"`. Three branches in a `cond`:
- `not File.exists?(endpoint_path)` → `cannot_diagnose_finding/1` (evidence contains `cannot_diagnose: true`)
- `wired?(File.read!(endpoint_path))` → `pass_finding/1`
- else → `fail_finding/1`

`wired?/1` checks `String.contains?(contents, "body_reader") and String.contains?(contents, "Mailglass.Webhook.CachingBodyReader")`. Managed-block markers are sourced from `Templates.endpoint_webhook_block_start/0` and `endpoint_webhook_block_end/0` — never hardcoded. `summarize/1` counts cannot_diagnose findings separately from fail (via `evidence.cannot_diagnose` flag), mirroring the inbound doctor pattern.

No `app.start`, no `Code.ensure_loaded?`, no `function_exported?` — the scan is entirely static file I/O (D-09).

**`Mix.Tasks.Mailglass.Doctor` (lib/mix/tasks/mailglass.doctor.ex):**
Thin CLI shell. Header: `use Boundary, classify_to: Mailglass` (copied from `mail.doctor.ex:2`) then `use Mix.Task`. `run/1` parses `--verbose` flag, validates CLI (Mix.raise only for bad flags/positionals — exit 2 must stay reachable), calls `Mailglass.Installer.Doctor.run([])`, renders output via `render_output/2`, then `exit({:shutdown, exit_code(result.summary)})`. `exit_code/1` maps: `cannot_diagnose > 0 → 2`, `fail > 0 → 1`, else `0`.

## Verification Results

```
mix test test/mailglass/install/
17 tests, 0 failures, 2 skipped

mix compile --warnings-as-errors
Generated mailglass app (no Boundary warnings)

mix credo --strict lib/mailglass/installer/apply.ex lib/mix/tasks/mailglass.install.ex
48 mods/funs, found no issues.

mix credo --strict lib/mailglass/installer/doctor.ex lib/mix/tasks/mailglass.doctor.ex
18 mods/funs, found no issues.

git diff --quiet lib/mix/tasks/mail.doctor.ex → PASS (untouched)
```

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — all implementation is complete and wired end-to-end.

## Threat Flags

None — no new network endpoints, auth paths, secrets, or schema changes. The net security effect is a REDUCTION in footgun risk (T-104-03: silent prod 401 is now blocked at install time).

## Self-Check: PASSED

- [x] `lib/mailglass/installer/apply.ex` exists and modified
- [x] `lib/mix/tasks/mailglass.install.ex` exists and modified
- [x] `lib/mailglass/installer/doctor.ex` exists (new)
- [x] `lib/mix/tasks/mailglass.doctor.ex` exists (new)
- [x] Commit 194fc8b2 exists (Task 1)
- [x] Commit 29ae7bc4 exists (Task 2)
- [x] `grep -c 'unmanaged_parser_conflict' apply.ex` = 1
- [x] `grep -c 'unmanaged_parser_conflict' mailglass.install.ex` = 1
- [x] `grep -c '--force' mailglass.install.ex` = 3 (in format_error, moduledoc, and optparser)
- [x] `grep -c 'Mailglass.Webhook.CachingBodyReader' mailglass.install.ex` = 1
- [x] `grep -c 'use Boundary, classify_to: Mailglass' mailglass.doctor.ex` = 1
- [x] `grep -E 'app\.start|ensure_loaded|function_exported' doctor.ex` returns nothing
- [x] exit_code has three distinct branches (cannot_diagnose>0→2, fail>0→1, true→0)
- [x] `git diff --quiet lib/mix/tasks/mail.doctor.ex` — PASS
- [x] All 17 installer lane tests green, 0 failures
- [x] `mix compile --warnings-as-errors` clean (no Boundary warning)
- [x] `mix credo --strict` clean on all 4 files
