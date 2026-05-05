---
phase: 27
slug: release-install-closure
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-02
---

# Phase 27 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source of truth: §"Validation Architecture (Dimension 8)" in `27-RESEARCH.md`.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.18, OTP 27) |
| **Config file** | `test/test_helper.exs`, `mix.exs` (`test_paths: ["test"]`) |
| **Quick run command** | `mix test test/mailglass/install/install_first_preview_smoke_test.exs --warnings-as-errors` |
| **Golden refresh command** | `MIX_INSTALLER_ACCEPT_GOLDEN=1 mix test test/mailglass/install/install_golden_test.exs --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Estimated runtime** | ~30 sec (install dir) / ~3-5 min (full suite) |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/mailglass/install/ --warnings-as-errors`
- **After every plan wave:** Run `mix test --warnings-as-errors`
- **Before `/gsd-verify-work`:** Full suite must be green AND at least one of REL-18 Proof A or Proof B captured in verification artifact
- **Max feedback latency:** 30 seconds for per-commit sampling

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 27-01-* | 01 | 1 | REL-17 | — | Generated `runtime.exs` does not crash a fresh Phoenix host on boot (sentinel) | unit | `mix test test/mailglass/install/install_first_preview_smoke_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 27-01-* | 01 | 1 | REL-17 | — | Generated installer file tree matches expected snapshot | golden | `mix test test/mailglass/install/install_golden_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 27-01-* | 01 | 1 | REL-17 | — | E2E: add deps → `mix mailglass.install` → compile WAE → boot endpoint → `GET /dev/mail/` 200 | live workflow | local rehearsal sequence (manual) OR `post-publish-smoke.yml` `consumer-install` job after publish | ✅ | ⬜ pending |
| 27-02-* | 02 | 2 | REL-18 | — | Release-event triggers smoke automatically with canonical `release.tag_name` | live workflow rehearsal | Proof A: `gh workflow run post-publish-smoke.yml -f tag=mailglass-v0.3.2` (fallback path proves canonical+fallback together) OR Proof B: observe v0.4.0 ship | ✅ | ⬜ pending |
| 27-02-* | 02 | 2 | REL-18 | — | Workflow comments accurately describe canonical/fallback distinction | doc lint | manual review of YAML diff (no concurrency-key drift) | n/a | ⬜ pending |
| 27-03-* | 03 | 3 | D-27-08/09 | — | Active planning state reflects post-fix contract (Issue #25/#9 no longer named as active gaps) | doc grep | `grep -n 'Issue #25\|Issue #9' .planning/STATE.md .planning/REQUIREMENTS.md .planning/PROJECT.md` returns 0 active-state matches (archived milestone v0.3 docs preserved) | n/a | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Wave 0 is **complete** — both `install_first_preview_smoke_test.exs` and `install_golden_test.exs` already exist. No new framework, no new fixtures, no new conftest equivalent needed.

Optional discretionary add: a literal-string sentinel assertion inside `install_first_preview_smoke_test.exs` that explicitly checks the generated `runtime.exs` contains `config :swoosh, :api_client, false` and does NOT contain `Swoosh.ApiClient.Finch`. Planner may include this in plan 27-01 as a small regression sentinel.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real fresh-host install boot | REL-17 | Requires standing up a Phoenix host outside the umbrella; not part of CI test suite. Already covered by `post-publish-smoke.yml` `consumer-install` job after the next real publish. | Optional pre-publish local rehearsal: in a scratch Phoenix app, add `{:mailglass, path: "../mailglass"}`, run `mix deps.get && mix mailglass.install && MIX_ENV=dev mix compile --warnings-as-errors && mix phx.server`, curl `http://localhost:4000/dev/mail/`. |
| Release-day smoke run | REL-18 | Requires either an actual hex publish or a `workflow_dispatch tag=...` rehearsal against a previously-published tag. | Proof A: `gh workflow run post-publish-smoke.yml -f tag=mailglass-v0.3.2` and observe success. Proof B: defer until v0.4.0 ship and capture the release.published smoke run as evidence. |
| Concurrency-group key preserved | REL-18 | YAML edit safety — preventing accidental key drift requires human eyeball on the diff. | After plan 27-02 commits, `git show -- .github/workflows/post-publish-smoke.yml` and confirm the `concurrency:` block (around line 23) is byte-identical to pre-edit. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or are listed in Manual-Only Verifications above
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (n/a — no MISSING references)
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s for per-commit sampling
- [ ] `nyquist_compliant: true` set in frontmatter at execute-phase wrap-up

**Approval:** pending
