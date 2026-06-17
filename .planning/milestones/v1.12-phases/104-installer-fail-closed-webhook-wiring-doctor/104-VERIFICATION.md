---
phase: 104-installer-fail-closed-webhook-wiring-doctor
verified: 2026-06-16T23:01:00Z
status: passed
score: 6/6 must-haves verified
overrides_applied: 0
---

# Phase 104: Installer Fail-Closed + Webhook-Wiring Doctor Verification Report

**Phase Goal:** Make `mix mailglass.install` fail closed with an actionable error (+ `--force` escape hatch) when it can't safely wire the webhook body_reader — routing the already-detected `Plug.Parsers` conflict through a fail path so silent production webhook 401s become impossible. Add a verifiable post-install webhook-wiring check (`mix mailglass.doctor`).
**Verified:** 2026-06-16T23:01:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `mix mailglass.install` fails closed (`Mix.raise`, non-zero exit) with actionable message on unmanaged `Plug.Parsers` lacking `:body_reader` | VERIFIED | `validate_preflight/1` (apply.ex:46-76) returns `{:error, {:unmanaged_parser_conflict, endpoint_path}}` when conflict detected and `--force` absent; the `{:error, reason} -> Mix.raise(format_error(reason))` rail at mailglass.install.ex:61-62 delivers the raise |
| 2 | The actionable message names the endpoint path, the silent-401 risk, the `body_reader` fix, and `--force` | VERIFIED | `format_error({:unmanaged_parser_conflict, endpoint_path})` clause at mailglass.install.ex:147-161 names all four elements: path interpolated in the message, "silently returns 401 in production", `Mailglass.Webhook.CachingBodyReader, :read_body, []`, and `--force` |
| 3 | `--force` proceeds past the conflict; managed parser block lands ABOVE the unmanaged one | VERIFIED | `validate_preflight/1` returns `:ok` when `Keyword.get(opts, :force, false)` is true (apply.ex:65); insertion uses existing `:ensure_block`/`insert_after_anchor` which inserts after `use Phoenix.Endpoint` (before any later `plug Plug.Parsers`); INSTALL-02 byte-index ordering test is GREEN |
| 4 | `Apply.run/2` contract preserved (`{:ok, result_map()} | {:error, term()}`); every `validate_preflight/1` branch returns `:ok` or `{:error, ...}` | VERIFIED | `@spec` at apply.ex:27 unchanged; all four branches of `validate_preflight/1` return `:ok` or `{:error, {:unmanaged_parser_conflict, _}}`; install idempotency tests (happy path) are GREEN confirming no regression on the `with` chain |
| 5 | `mix mailglass.doctor` confirms CachingBodyReader wiring via static endpoint scan and exits 0/1/2 | VERIFIED | `Mailglass.Installer.Doctor.run/1` does a pure `File.read!` scan; `Mix.Tasks.Mailglass.Doctor.exit_code/1` maps `cannot_diagnose > 0 → 2`, `fail > 0 → 1`, else `0`; all three doctor test cases GREEN |
| 6 | Wave 0 tests (104-01) are GREEN; `mix credo --strict` (lib/) clean | VERIFIED | `mix test test/mailglass/install/` → 17 tests, 0 failures, 2 skipped; credo clean reported in 104-02-SUMMARY.md and confirmed by no debt markers in any phase-modified file |

**Score:** 6/6 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/mailglass/installer/apply.ex` | `validate_preflight/1` returning conflict tuple (unless `--force`); threaded as first `with`-link of `Apply.run/2` | VERIFIED | Line 32: `with :ok <- validate_preflight(opts),`; lines 46-76 implement the fail-closed shape with all branches returning `:ok` or `{:error, ...}` |
| `lib/mix/tasks/mailglass.install.ex` | `format_error/1` clause for `{:unmanaged_parser_conflict, _}` carrying actionable message | VERIFIED | Clause at lines 147-161; inserted before catch-all at line 163; rides existing error rail at lines 61-62; `maybe_raise_conflict_error/1` (108-112) untouched |
| `lib/mailglass/installer/doctor.ex` | `Mailglass.Installer.Doctor.run/1` — pure static endpoint scan returning `%{summary, findings}` | VERIFIED | Module exists; `run/1` at lines 42-59; uses `Plan.detect_otp_app/0`, `File.read!`, `String.contains?`; no `app.start`, `Code.ensure_loaded?`, `function_exported?` |
| `lib/mix/tasks/mailglass.doctor.ex` | Thin CLI shell with three-state exit codes (0/1/2), Boundary-classified | VERIFIED | `use Boundary, classify_to: Mailglass` at line 2; `exit_code/1` has three distinct branches (lines 98-103); no `Mix.Task.run("app.start")` |
| `test/mailglass/install/install_fail_closed_test.exs` | Three test cases covering INSTALL-01 (tuple + task-level) and INSTALL-02 (`--force` ordering) | VERIFIED | File exists; tuple assertion at line 51 matches `{:error, {:unmanaged_parser_conflict, _path}}` directly via `Apply.run/2`; task-level assertion wraps `run_install!` in `assert_raise`; INSTALL-02 uses `:binary.match/2` byte-index ordering |
| `test/mailglass/install/mailglass_doctor_test.exs` | Three test cases covering INSTALL-03 (0/1/2 summary states) | VERIFIED | File exists; all three doctor states tested (`fail == 0 and cannot_diagnose == 0`, `fail > 0`, `cannot_diagnose > 0`); each runs inside `File.cd!(fixture_root, ...)` |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `lib/mailglass/installer/apply.ex` | `lib/mix/tasks/mailglass.install.ex format_error/1` | `{:error, {:unmanaged_parser_conflict, path}}` → `Apply.run` with-chain → `{:error, reason}` → `Mix.raise(format_error(reason))` | WIRED | `validate_preflight/1` returns the error tuple; it propagates through the `with` chain; `format_error/1` clause matches the tuple at mailglass.install.ex:147 |
| `lib/mix/tasks/mailglass.doctor.ex` | `lib/mailglass/installer/doctor.ex` | `run/1` → `Mailglass.Installer.Doctor.run([])` → `exit({:shutdown, exit_code(result.summary)})` | WIRED | Line 40: `result = Mailglass.Installer.Doctor.run([])`; line 46: `exit({:shutdown, exit_code(result.summary)})` |
| `lib/mailglass/installer/doctor.ex` | `lib/<app>_web/endpoint.ex` | Static `File.read!` scan via `Plan.detect_otp_app/0` + `Templates` markers | WIRED | `otp_app = Plan.detect_otp_app()` at line 43; `endpoint_path = "lib/#{otp_app}_web/endpoint.ex"` at line 44; `wired?/1` checks for `body_reader` and `Mailglass.Webhook.CachingBodyReader` |

### Data-Flow Trace (Level 4)

Not applicable — phase delivers installer/mix-task logic (no dynamic data rendering, no DB queries, no React-style state). All data flows are static file I/O traced above in key links.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Installer test lane: 17 tests, 0 failures | `mix test test/mailglass/install/` | 17 tests, 0 failures, 2 skipped | PASS |
| `unmanaged_parser_conflict` present in apply.ex | `grep -c 'unmanaged_parser_conflict' lib/mailglass/installer/apply.ex` | 1 | PASS |
| `unmanaged_parser_conflict` present in mailglass.install.ex | `grep -c 'unmanaged_parser_conflict' lib/mix/tasks/mailglass.install.ex` | 1 | PASS |
| `validate_preflight` is first with-link in `Apply.run/2` | `grep -n 'with :ok <- validate_preflight' lib/mailglass/installer/apply.ex` | line 32 | PASS |
| Doctor has no runtime reflection or app boot | `grep -E 'app\.start\|ensure_loaded\|function_exported' lib/mailglass/installer/doctor.ex` | no output | PASS |
| `use Boundary` present in mailglass.doctor.ex | `grep -c 'use Boundary, classify_to: Mailglass' lib/mix/tasks/mailglass.doctor.ex` | 1 | PASS |
| `mail.doctor.ex` untouched | `git diff --quiet lib/mix/tasks/mail.doctor.ex` | exit 0 | PASS |

### Probe Execution

No probe scripts declared in this phase. Static checks above cover all INSTALL-01..04 behaviors.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| INSTALL-01 | 104-01, 104-02 | `mix mailglass.install` fails closed (`Mix.raise`, non-zero exit) on unmanaged `Plug.Parsers` without `:body_reader` | SATISFIED | `validate_preflight/1` returns `{:error, {:unmanaged_parser_conflict, path}}`; format_error/1 clause raises via existing rail; INSTALL-01 tests GREEN |
| INSTALL-02 | 104-01, 104-02 | `--force` escape hatch proceeds past conflict; managed parser inserted above unmanaged one | SATISFIED | `validate_preflight/1` returns `:ok` on `force: true`; insertion uses existing `:ensure_block` anchor logic (unchanged); INSTALL-02 byte-ordering test GREEN |
| INSTALL-03 | 104-01, 104-02 | New `mix mailglass.doctor` static scan of endpoint confirms CachingBodyReader wiring; exits 0/1/2 | SATISFIED | `Mailglass.Installer.Doctor` and `Mix.Tasks.Mailglass.Doctor` exist; three-state exit codes confirmed; doctor tests GREEN |
| INSTALL-04 | 104-01, 104-02 | Fail-closed, `--force`, and doctor paths covered by tests following `install_idempotency_test.exs` fixture pattern | SATISFIED | 6 test cases across two test files; all use `new_fixture_root!/1` + `File.cd!` fixture pattern; 17-test installer lane GREEN |

No orphaned requirements — REQUIREMENTS.md traceability table maps INSTALL-01..04 exclusively to Phase 104, and all four are accounted for.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| (none found) | — | — | — | — |

Scanned all four phase-modified files (`apply.ex`, `mailglass.install.ex`, `doctor.ex`, `mailglass.doctor.ex`) for `TBD`, `FIXME`, `XXX`, placeholder strings, empty returns, and hardcoded empty data. Zero findings.

### Human Verification Required

None. All phase behaviors have automated verification per VALIDATION.md. The doctor's static scan is exercised entirely within the install-fixture harness — no UI, no real-time behavior, no external services.

### Gaps Summary

No gaps. All six must-have truths are VERIFIED, all four requirement IDs are SATISFIED, all artifacts are substantive and wired, no debt markers detected, and the installer test lane is clean at 17 tests, 0 failures.

---

_Verified: 2026-06-16T23:01:00Z_
_Verifier: Claude (gsd-verifier)_
