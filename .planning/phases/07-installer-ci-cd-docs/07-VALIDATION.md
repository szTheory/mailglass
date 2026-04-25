---
phase: 07
slug: installer-ci-cd-docs
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-24
---

# Phase 07 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) + GitHub Actions workflow checks |
| **Config file** | `mix.exs`, `test/test_helper.exs`, `.github/workflows/ci.yml` |
| **Quick run command** | `mix test` |
| **Full suite command** | `mix format --check-formatted && mix compile --warnings-as-errors && mix compile --no-optional-deps --warnings-as-errors && mix test && mix credo --strict && mix dialyzer && mix docs --warnings-as-errors && mix hex.audit` |
| **Estimated runtime** | ~240 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test`
- **After every plan wave:** Run `mix test && mix credo --strict`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 300 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 07-01-01 | 01 | 1 | INST-01, INST-02 | T-07-01 | Installer does not clobber existing host files; writes conflict sidecars | integration | `mix test test/example` | ✅ / ❌ W0 | ⬜ pending |
| 07-02-01 | 02 | 1 | CI-01..CI-07 | T-07-02 | CI enforces required quality gates and blocks insecure release paths | workflow | `actionlint && mix test` | ✅ / ❌ W0 | ⬜ pending |
| 07-03-01 | 03 | 2 | DOCS-01..DOCS-05, BRAND-02, BRAND-03 | T-07-03 | Docs compile and examples are executable without exposing secrets | docs + doctest | `mix docs --warnings-as-errors` | ✅ / ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/example/` — golden fixture and snapshot assertions for installer idempotency
- [ ] `.github/workflows/live-provider.yml` — non-blocking cron + manual provider sandbox lane
- [ ] `guides/` source files for all required ExDoc guides and README quick-start compile checks

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| First preview-styled email in under 5 minutes on fresh Phoenix host | INST-01, INST-02, DOCS-01 | Time-to-first-success and developer ergonomics are environment-dependent | Run installer in clean host app, follow getting-started steps, time end-to-end setup, capture elapsed time and result screenshot/log |
| Protected-ref release + Hex publish approval flow | CI-05, CI-06 | Needs repository permissions, environments, and reviewer approvals | Trigger dry-run release on protected branch, verify environment approval gate, confirm no publish path from PR branches |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 300s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
