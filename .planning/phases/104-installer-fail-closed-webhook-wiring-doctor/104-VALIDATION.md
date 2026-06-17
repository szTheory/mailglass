---
phase: 104
slug: installer-fail-closed-webhook-wiring-doctor
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-16
---

# Phase 104 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `104-RESEARCH.md` ## Validation Architecture (verified against live source 2026-06-16).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.18, `~> 1.18`) |
| **Config file** | `test/test_helper.exs` (existing) — new test files in `test/mailglass/install/` |
| **Quick run command** | `mix test test/mailglass/install/install_fail_closed_test.exs` |
| **Full suite command** | `mix test test/mailglass/install/` (installer lane only — avoids ~57 unrelated Oban flakes per MEMORY) |
| **Estimated runtime** | ~10–20 seconds (installer lane) |

**Harness note:** new tests `use ExUnit.Case, async: false` + `import Mailglass.Test.InstallerFixtureHelpers` (identical to `install_idempotency_test.exs`). Do NOT gate on bare `mix test` (known unrelated Oban + `voice_test` "Oops" dep-JS flakes).

---

## Sampling Rate

- **After every task commit:** Run `mix test test/mailglass/install/install_fail_closed_test.exs` (+ the doctor file once it exists)
- **After every plan wave:** Run `mix test test/mailglass/install/`
- **Before `/gsd:verify-work`:** installer lane green + `mix credo --strict` (path-scoped to `lib/`)
- **Max feedback latency:** ~20 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 104-W0 | (Wave 0) | 0 | INSTALL-01/02/04 | — | Failing test stubs for fail-closed + `--force` ordering | unit | `mix test test/mailglass/install/install_fail_closed_test.exs` | ❌ W0 | ⬜ pending |
| 104-W0 | (Wave 0) | 0 | INSTALL-03/04 | — | Failing test stubs for doctor 0/1/2 exit codes | unit | `mix test test/mailglass/install/mailglass_doctor_test.exs` | ❌ W0 | ⬜ pending |
| 104-INSTALL-01 | impl | 1 | INSTALL-01 | — | `Apply.run/2` returns `{:error, {:unmanaged_parser_conflict, path}}` (tuple match, never message string); task exits non-zero with actionable message | unit | `mix test test/mailglass/install/install_fail_closed_test.exs` | ✅ W0 | ⬜ pending |
| 104-INSTALL-02 | impl | 1 | INSTALL-02 | — | `--force` install succeeds AND managed block index < unmanaged `plug Plug.Parsers` index in resulting endpoint.ex | unit | `mix test test/mailglass/install/install_fail_closed_test.exs` | ✅ W0 | ⬜ pending |
| 104-INSTALL-03 | impl | 1 | INSTALL-03 | — | Doctor runner returns 0 (wired) / 1 (CachingBodyReader absent) / 2 (endpoint.ex missing) via summary→exit_code map | unit | `mix test test/mailglass/install/mailglass_doctor_test.exs` | ✅ W0 | ⬜ pending |
| 104-INSTALL-04 | impl | 1 | INSTALL-04 | — | All three paths covered via `new_fixture_root!/1` + post-creation `File.write!` seeding + `File.cd!` scoping | unit | `mix test test/mailglass/install/` | ✅ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/mailglass/install/install_fail_closed_test.exs` — failing stubs for INSTALL-01, INSTALL-02, INSTALL-04
- [ ] `test/mailglass/install/mailglass_doctor_test.exs` — failing stubs for INSTALL-03, INSTALL-04
- [ ] No new shared fixtures/conftest — `Mailglass.Test.InstallerFixtureHelpers` + `test/support/example` cover all seams
- [ ] No framework install — ExUnit already present

**The seeding footgun (MUST encode in every fail-closed/`--force`/unwired test):** after `new_fixture_root!/1`, overwrite `lib/example_web/endpoint.ex` so the seeded `plug Plug.Parsers` (1) has NO `body_reader` text anywhere, AND (2) sits OUTSIDE the managed markers (`# mailglass:start/end endpoint_webhook_parser`). The default skeleton (`installer_fixture_helpers.ex:263-269`) is bare and never trips the guard — seeding is mandatory or the test passes vacuously.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| (none) | — | — | All phase behaviors have automated verification. |

*All phase behaviors have automated verification — the entire phase (including the doctor static scan) is offline and exercisable in the install-fixture harness.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (two new test files)
- [ ] No watch-mode flags
- [ ] Feedback latency < 20s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
