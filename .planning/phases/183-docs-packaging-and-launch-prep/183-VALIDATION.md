---
phase: "183"
slug: "docs-packaging-and-launch-prep"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-11-16"
---

# Phase 183 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Elixir ExUnit, Mix tasks and existing Playwright browser tooling |
| **Config file** | Root and package `mix.exs`; `mailglass_admin/e2e/` Playwright configuration |
| **Quick run command** | `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/scripts/brand_trademark_gate_test.exs --warnings-as-errors --seed 0` |
| **Full suite command** | Root `mix test`, then `mix test` in `mailglass_admin/` and `mailglass_inbound/` |
| **Estimated runtime** | Targeted tests under 30 seconds; full suite and browser capture duration to be recorded during execution |

## Sampling Rate

- **After every task commit:** Run the task's targeted ExUnit contract or the smallest relevant package check.
- **After every plan wave:** Run the core/admin/inbound suites and all three package `mix docs` and `mix mailglass.publish.check` checks.
- **Before `$gsd-verify-work`:** All required suites, docs builds, package checks and favicon evidence validation must be green.
- **Max feedback latency:** 30 seconds for a targeted test; longer checks run in the background.

## Per-Task Verification Map

Plan 02 runs in wave 1; plan 01 runs in wave 2 after its pinned assets and guide exist. Every task creates its own focused regression contracts before implementation and retains explicit failure conditions in PLAN.md. Task IDs below are concrete execution IDs.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 183-02-01 | 02 | 1 | BRDOC-06 | T-183-01, T-183-02 | Actual caution denies; registers/dates/production flags fail closed; encoded public claims are checked without a publish prerequisite | Hermetic ExUnit and actual CLI tracer | `mix test test/scripts/brand_trademark_gate_test.exs --warnings-as-errors --seed 0` | ✅ existing, extended | ⬜ pending |
| 183-02-02 | 02 | 1 | BRDOC-03 | T-183-06 | Design parity, narrow Inter exception and pending paired patches preserve canonical owner files | ExUnit contract | `mix test test/scripts/brand_design_md_test.exs test/mailglass/docs_contract_test.exs --warnings-as-errors --seed 0`; Admin token/guide tests listed in plan | ❌ new contract planned | ⬜ pending |
| 183-02-03 | 02 | 1 | BRDOC-05 | T-183-03, T-183-04, T-183-05 | Atomic manifest-driven update; complete browser matrix; independent PNG metrics; repository-only checklist | Source-pin ExUnit, browser producer, required Admin validator | `mix test test/scripts/brand_pin_test.exs --warnings-as-errors --seed 0`; `node mailglass_admin/e2e/favicon-capture.cjs --capture`; `cd mailglass_admin && mix test test/mailglass_admin/favicon_catalog_test.exs --warnings-as-errors --seed 0` | ❌ producer/validator planned | ⬜ pending |
| 183-01-01 | 01 | 2 | BRDOC-01, BRDOC-02 | T-183-07, T-183-08, T-183-11 | Core real docs retain pinned bytes, native font/theme, syntax-only CSS and the current claim boundary | Real build, tagged output ExUnit, headless local browser | `mix docs`; `mix test test/scripts/readme_image_contract_test.exs test/scripts/brand_docs_contract_test.exs --only core --warnings-as-errors --seed 0`; `node mailglass_admin/e2e/docs-theme-contract.cjs --package core` | ❌ new contracts planned | ⬜ pending |
| 183-01-02 | 01 | 2 | BRDOC-01, BRDOC-02 | T-183-07, T-183-08 | Both sibling outputs enforce the same full default contract; all six static-media UI behaviors are checked | Two real builds, default ExUnit and browser | Separate `mix docs` in Admin/Inbound; `mix test test/scripts/readme_image_contract_test.exs test/scripts/brand_docs_contract_test.exs --warnings-as-errors --seed 0`; `node mailglass_admin/e2e/docs-theme-contract.cjs --all` | ❌ new contracts planned | ⬜ pending |
| 183-01-03 | 01 | 2 | BRDOC-04, BRDOC-06 separation | T-183-09, T-183-10, T-183-11 | Effective prose/API exceptions; actual tarball/pin/golden/digest equality; full readiness remains independent of announcement denial | ExUnit, corpus CLI and all-three full package checks | `mix test test/scripts/brand_name_lint_test.exs test/mailglass/publish/brand_asset_allowlist_test.exs test/mailglass/docs/operator_incident_support_guide_test.exs --warnings-as-errors --seed 0`; `mix run --no-start scripts/brand_name_lint.exs check`; `mix mailglass.publish.check --allowlist-only`; separate full `--package mailglass`, `--package mailglass_admin`, `--package mailglass_inbound` runs | ❌ new contracts planned | ⬜ pending |

All Mix commands use `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27` as written in the plans. Focused checks target under 60 seconds; real docs/full package/browser checks run in the background and retain their actual elapsed time. Every automated command has a sibling `fails_when` in its task. No watch mode or new required CI job is introduced. Tests/producer are authored in the same task before behavior; new paths are not claimed to exist already.

## Wave 0 Requirements

Existing ExUnit, Mix, and Playwright infrastructure covers all requirements. Add contract tests with the implementation tasks; no framework installation or new dependency is required.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Actual GitHub/Hex.pm theme rendering after the asset commit is reachable | BRDOC-01 | Network rendering is advisory; offline commit/blob/pin contracts and local generated-doc browser checks are required. | After authorized review delivery makes the asset commit reachable, inspect both themes when the remote surface is available. Do not publish a release or create a remote tag just to produce this evidence. |
| Applying CLAUDE.md and PRODUCT.md changes | BRDOC-03 | These owner-controlled files require owner sign-off. | Review the pending patch pair and run its recorded apply/check instructions only after owner sign-off. |
| Register/counsel trademark search and any announcement decision | BRDOC-06 | The current search record is caution and an agent cannot perform or upgrade the legal review. | Owner/counsel reviews named registers and updates the record; no announcement or ™ claim is made while it remains blocked. |

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s for targeted checks
- [ ] `nyquist_compliant: true` set in frontmatter after validation audit

**Approval:** pending
