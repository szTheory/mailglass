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

The planner will align these requirement-level checks to concrete plan task IDs before execution.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| BRDOC-01 | 01 | 1 | BRDOC-01 | See plan threat model | README image refs resolve to local pinned bytes and use the correct renderer-specific theme variant | ExUnit contract | `mix test test/scripts/readme_image_contract_test.exs --warnings-as-errors --seed 0` | ❌ planned | ⬜ pending |
| BRDOC-02 | 01 | 1 | BRDOC-02 | See plan threat model | Generated docs retain ExDoc Lato/theme behavior and contain only the allowed CSS changes | Build + output contract | Run `mix docs` from core, admin and inbound package roots | ✅ infrastructure | ⬜ pending |
| BRDOC-03 | 02 | 2 | BRDOC-03 | See plan threat model | Design token docs match pinned sources; owner-controlled drafts remain pending and unapplied | ExUnit contract | `mix test test/scripts/brand_design_md_test.exs --warnings-as-errors --seed 0` | ❌ planned | ⬜ pending |
| BRDOC-04 | 01 | 1 | BRDOC-04 | See plan threat model | Lowercase prose is enforced while public API names and explicit exceptions remain intact; package contents match manifests | ExUnit + package check | `mix test test/scripts/brand_name_lint_test.exs test/mailglass/publish/brand_asset_allowlist_test.exs --warnings-as-errors --seed 0` and run `mix mailglass.publish.check` in each package | ❌ planned | ⬜ pending |
| BRDOC-05 | 02 | 2 | BRDOC-05 | See plan threat model | Every browser/theme/size capture is bound to the pinned favicon SHA and PNG-derived metrics | Browser capture + ExUnit validator | Run the favicon capture producer, then `cd mailglass_admin && mix test test/mailglass_admin/favicon_catalog_test.exs --warnings-as-errors --seed 0` | ❌ planned | ⬜ pending |
| BRDOC-06 | 02 | 2 | BRDOC-06 | See plan threat model | Current caution record blocks announcement and trademark text; code and package checks remain independent | Hermetic ExUnit contract | `mix test test/scripts/brand_trademark_gate_test.exs --warnings-as-errors --seed 0` | ✅ existing | ⬜ pending |

## Wave 0 Requirements

Existing ExUnit, Mix, and Playwright infrastructure covers all requirements. Add contract tests with the implementation tasks; no framework installation or new dependency is required.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Actual GitHub/Hex.pm theme rendering after the asset commit is reachable | BRDOC-01 | The pinned SHA is unavailable to remote renderers until its commit is pushed; network access is not suitable as a required CI test. | After the authorized review commit is pushed, inspect GitHub and Hex.pm in light and dark themes. No push, publish or release is part of this phase. |
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
