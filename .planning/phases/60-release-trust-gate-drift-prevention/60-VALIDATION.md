---
phase: 60
slug: release-trust-gate-drift-prevention
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-29
---

# Phase 60 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `60-RESEARCH.md` → `## Validation Architecture`. This phase is
> CI/release/ops plumbing + docs, so signals split into **local-deterministic**
> (shell guards + ExUnit, run in seconds) and **CI-only** (observed on a real
> post-publish run).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.18 / OTP 27) — bundled, no install |
| **Config file** | `test/test_helper.exs` (`mix.exs` aliases route `verify.*` to `:test`) |
| **Quick run command** | `MIX_ENV=test mix test test/scripts/required_checks_test.exs test/mailglass/install/install_first_preview_smoke_test.exs` |
| **Full suite command** | `MIX_ENV=test mix test` (scope per-file in worktrees; ~57 unrelated Oban failures + `voice_test.exs` dep-JS noise are pre-existing, not phase signal) |
| **Estimated runtime** | ~5–15 seconds for the scoped quick command |
| **Workflow lint** | `actionlint` (CI-side on push); shell `shellcheck` (scripts already clean) |

---

## Sampling Rate

- **After every task commit:** Run the quick command (scoped ExUnit) plus any touched shell guard directly (`bash scripts/check_clean_baseline_hex_only.sh`, `bash scripts/check_trust_runner_checkpoint.sh`).
- **After every plan wave:** Run the full scoped ExUnit set + re-run touched shell guards.
- **Before `/gsd-verify-work`:** Scoped suite green; `actionlint`/`shellcheck` clean on edited workflows/scripts (or CI parse green).
- **Max feedback latency:** ~15 seconds (local signals). CI-only signals are validated by observing one green `post-publish-smoke` run.

---

## Per-Requirement Verification Map

> Task IDs are assigned by the planner; this maps each phase requirement to its deterministic signal.

| Requirement | Behavior | Test Type | Automated Command / Check | Where it runs | File Exists | Status |
|-------------|----------|-----------|----------------------------|---------------|-------------|--------|
| EVID-02 | Clean-baseline lane enforces Hex-first resolution, blocks path leakage | shell exit-code | `cd reference/host_app && bash ../../scripts/check_clean_baseline_hex_only.sh` → 0 happy / 1 on path leak | local + CI (`ci.yml` job) | ✅ script / ❌ ci.yml job (W0) | ⬜ pending |
| EVID-02 | Clean-baseline lane stays OUT of `REQUIRED_CHECKS` (D-04) | ExUnit | `mix test test/scripts/required_checks_test.exs`; assert clean-baseline name absent from parsed checks | local + CI | ✅ test | ⬜ pending |
| EVID-02/03 | Checkpoint contract holds | shell exit-code | `bash scripts/check_trust_runner_checkpoint.sh` → 0 (after a journey run) | local + CI | ✅ | ⬜ pending |
| EVID-03 | Published-version journey runs post-publish before trust claims | CI job green | `published-trust-journey` job green in `post-publish-smoke.yml`; checkpoint artifact uploaded | CI-only (release/cron/dispatch) | ❌ job (W0) | ⬜ pending |
| OPS-01 | Installer sets `config :swoosh, :api_client, false` (root-cause) | ExUnit | `mix test test/mailglass/install/install_first_preview_smoke_test.exs` (REL-17 sentinel) | local + CI | ✅ | ⬜ pending |
| OPS-01 | No hackney/finch reintroduced on a fresh PUBLISHED host | CI grep exit-code | new `consumer-install` guard step (config + `mix.lock` grep) → exit 1 on regression | CI-only (post-publish-smoke) | ❌ guard (W0) | ⬜ pending |
| OPS-02 | `MAINTAINING.md` requires green trust evidence; no stale approval gate | ExUnit (RECOMMENDED) | doc-contract test: trust-evidence strings present + approval-gate strings absent | local + CI | ❌ optional (W0) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Infrastructure / guards to add with implementation (no test-framework install needed — ExUnit, shellcheck-clean scripts, python3 validator all present):

- [ ] `.github/workflows/ci.yml` `trust_lane_clean_baseline` job — covers EVID-02 (mirror of `trust_lane_repo_head`, no `if:`)
- [ ] `.github/workflows/post-publish-smoke.yml` `published-trust-journey` job — covers EVID-03
- [ ] `.github/workflows/post-publish-smoke.yml` `consumer-install` hackney guard step — covers OPS-01 live signal
- [ ] (RECOMMENDED) `test/mailglass/.../maintaining_release_gate_contract_test.exs` — covers OPS-02 doc contract
- [ ] (hardening) extend `test/scripts/required_checks_test.exs` with an explicit `refute` that the clean-baseline name is absent from `REQUIRED_CHECKS`, locking D-04 against drift

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| EVID-03 published-version journey is green on a real publish | EVID-03 | Requires a live published version + generated Phoenix host; cannot run locally | Observe one green `post-publish-smoke` run (release/cron/`workflow_dispatch`); confirm `trust-runner-published-*` artifact uploaded |
| OPS-01 live guard fires/clears on a published host | OPS-01 | Same CI-only dependency | Confirm the `consumer-install` guard step ran and passed on the same green post-publish run |
| Close GitHub issue #32 | OPS-01 | `checkpoint:human-action` — close ONLY after the above run is green with the guard in place (D-07), not on the local unit test | `gh issue close 32` after verifying the green post-publish run |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s (local signals)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
