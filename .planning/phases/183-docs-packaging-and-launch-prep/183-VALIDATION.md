---
phase: "183"
slug: "docs-packaging-and-launch-prep"
status: partial
nyquist_compliant: false
wave_0_complete: true
created: "2026-11-16"
audited_at: "2026-11-17T03:30:13Z"
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
| 183-02-01 | 02 | 1 | BRDOC-06 | T-183-01, T-183-02 | Actual caution denies; registers/dates/production flags fail closed; encoded public claims are checked without a publish prerequisite | Hermetic ExUnit and actual CLI tracer | `mix test test/scripts/brand_trademark_gate_test.exs --warnings-as-errors --seed 0` | ✅ existing, extended | 🟢 verified |
| 183-02-02 | 02 | 1 | BRDOC-03 | T-183-06 | Design parity, narrow Inter exception and pending paired patches preserve canonical owner files | ExUnit contract | `mix test test/scripts/brand_design_md_test.exs test/mailglass/docs_contract_test.exs --warnings-as-errors --seed 0`; `cd mailglass_admin && mix test test/mailglass_admin/token_parity_test.exs test/mailglass_admin/operator/health_overview_test.exs --warnings-as-errors --seed 0` | ✅ created | 🟢 verified |
| 183-02-03 | 02 | 1 | BRDOC-05 | T-183-03, T-183-04, T-183-05 | Atomic manifest-driven update; complete browser matrix; independent PNG metrics; repository-only checklist | Source-pin ExUnit, browser producer, required Admin validator | `mix test test/scripts/brand_pin_test.exs --warnings-as-errors --seed 0`; `PLAYWRIGHT_BROWSERS_PATH=/private/tmp/mailglass-183-02-playwright node mailglass_admin/e2e/favicon-capture.cjs --capture` (single authorized run); `cd mailglass_admin && mix test test/mailglass_admin/favicon_catalog_test.exs --warnings-as-errors --seed 0` | ✅ created | 🟢 verified |
| 183-01-01 | 01 | 2 | BRDOC-01, BRDOC-02 | T-183-07, T-183-08, T-183-11 | Core real docs retain pinned bytes, native font/theme, syntax-only CSS and the current claim boundary | Real build, tagged output ExUnit, headless local browser | `mix docs`; `mix test test/scripts/readme_image_contract_test.exs test/scripts/brand_docs_contract_test.exs --only core --warnings-as-errors --seed 0`; `node mailglass_admin/e2e/docs-theme-contract.cjs --package core` | ✅ created | 🟡 partial — output build/check recorded green; clean-checkout/browser wiring gap below |
| 183-01-02 | 01 | 2 | BRDOC-01, BRDOC-02 | T-183-07, T-183-08 | Both sibling outputs enforce the same full default contract; all six static-media UI behaviors are checked | Two real builds, default ExUnit and browser | Separate `mix docs` in Admin/Inbound; `mix test test/scripts/readme_image_contract_test.exs test/scripts/brand_docs_contract_test.exs --warnings-as-errors --seed 0`; `node mailglass_admin/e2e/docs-theme-contract.cjs --all` | ✅ created | 🟡 partial — clean-checkout/browser wiring gap below |
| 183-01-03 | 01 | 2 | BRDOC-04, BRDOC-06 separation | T-183-09, T-183-10, T-183-11 | Effective prose/API exceptions; actual tarball/pin/golden/digest equality; full readiness remains independent of announcement denial | ExUnit, corpus CLI and all-three full package checks | `mix test test/scripts/brand_name_lint_test.exs test/mailglass/publish/brand_asset_allowlist_test.exs test/mailglass/docs/operator_incident_support_guide_test.exs --warnings-as-errors --seed 0`; `mix run --no-start scripts/brand_name_lint.exs check`; `mix mailglass.publish.check --allowlist-only`; separate full `--package mailglass`, `--package mailglass_admin`, `--package mailglass_inbound` runs | ✅ created | 🟢 verified |

All Mix commands use `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27` as written in the plans. Focused checks target under 60 seconds; real docs/full package/browser checks run in the background and retain their actual elapsed time. Every automated command has a sibling `fails_when` in its task. No watch mode or new required CI job is introduced. Tests/producer are authored in the same task before behavior; new paths are not claimed to exist already.

## Wave 0 Requirements

Existing ExUnit, Mix, and Playwright infrastructure covers all requirements. Add contract tests with the implementation tasks; no framework installation or new dependency is required.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Actual GitHub/Hex.pm/HexDocs theme rendering after the asset commit is reachable | BRDOC-01 | Platform rendering is external to local byte/build checks. | After authorized review delivery makes the asset commit reachable, inspect both themes on GitHub, Hex.pm, and HexDocs when each surface is available. Do not publish a release or create a remote tag just to produce this evidence. |
| Generated docs visual review after the output-path gap is closed | BRDOC-01, BRDOC-02 | The automated browser assertions do not replace a human visual inspection. | After the three-package browser contract can target generated output, inspect the mark and lockup in both themes at desktop and 375 px; verify the tagline stays separate and nothing overflows. |
| Applying CLAUDE.md and PRODUCT.md changes | BRDOC-03 | These owner-controlled files require owner sign-off. | Review the pending patch pair and run its recorded apply/check instructions only after owner sign-off. |
| Register/counsel trademark search and any announcement decision | BRDOC-06 | The current search record is caution and an agent cannot perform or upgrade the legal review. | Owner/counsel reviews named registers and updates the record; no announcement or ™ claim is made while it remains blocked. |
| Favicon capture-order acceptance without recapture | BRDOC-05 | The saved pixels cannot independently prove when decoding occurred relative to the original screenshot. | Review the accepted catalog and capture sequence to confirm `img.decode()` completes before screenshot; do not repeat the single authorized capture. Keep the WebKit/Safari limitation explicit. |
| Social-card upload/read-back, if the owner chooses to do it | BRDOC-05 | Public identity and account changes are owner-controlled. | The repository checklist is ready; upload and verify only as an owner action. No upload or personal-avatar change is evidenced here. |

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references; existing ExUnit/Mix/Playwright infrastructure is sufficient
- [x] No watch-mode flags
- [ ] Feedback latency < 30s is not established by the recorded command output
- [ ] `nyquist_compliant: true` set in frontmatter after validation audit

**Approval:** Partial. Plan 183-03 implemented clean-checkout output selection and required CI wiring. Its output and focused workflow contracts passed, but the local browser did not start and the unchanged full root suite failed. Keep Nyquist false and the phase verification at `gaps_found`; manual platform, owner-file, and legal handoffs remain pending.

## Gap-closure validation planned — 183-03

| Task | Requirement | Threat Ref | Planned evidence | Status |
|------|-------------|------------|------------------|--------|
| 183-03 task 1 | BRDOC-01, BRDOC-02 | T-183-12, T-183-14, T-183-15 | Default fixture/source test without checkout docs; explicit-root standalone real-output checks; one background serial three-package build/output/browser run using existing pinned Chromium; both native themes and 375px layout for all packages; owned temp-output cleanup | 🟡 Partial — source/fixture tests, three builds, output contract and cleanup passed; Chromium failed at launch before theme/layout scenarios |
| 183-03 task 2 | BRDOC-02 | T-183-13 | Structural workflow tests and in-memory mutation rejection; unchanged existing CI gate/identity contracts; full normal root `mix test --warnings-as-errors` with all generated README outputs absent | 🟡 Partial — focused contracts passed; default root suite ended with 7 failures and is not green |

The standalone real-output contract is outside default root test discovery and is wired into the existing required Docs job after three same-job builds. Default root fixture/mutation/source checks stay active. Local browser mode consumes the same fresh outputs and uses `/private/tmp/mailglass-183-02-playwright`; its one attempt reached the installed binary but Chromium failed at macOS bootstrap registration before any scenario. No download, favicon capture, preview, or remote CI action occurred. Core docs kept the existing warnings-as-errors policy; Admin/Inbound warnings were preserved. The original clean-checkout wiring issue is implemented, but phase verification remains partial because browser behavior and the full default root suite are not green.

## Validation Audit Record — 2026-11-17

**Verdict: PARTIAL.** The two final plans, their summaries, the final verification report, and review/fix evidence show substantive behavioral checks for all six requirements. The focused tests and package/docs checks reported green are recorded as green above. Nyquist compliance remains false because the generated-doc contract is not clean-checkout runnable and the browser runner cannot consume the temporary output paths used by final verification.

### Evidence Reviewed

- `183-02-PLAN.md` and `183-02-SUMMARY.md`: focused trademark, design, pin, and favicon checks; one authorized 108-cell favicon capture; independent 13-test catalog validation. The plan-02 summary says the full core/Admin/Inbound regression and final docs/package checks were still pending its successor plan.
- `183-01-PLAN.md` and `183-01-SUMMARY.md`: README, generated-doc, lint, package-payload, and three-package readiness contracts. The summary records all three docs builds/output checks and browser checks as passed, plus targeted core/Admin/Inbound lanes and full package checks.
- `183-VERIFICATION.md`: isolated temporary docs builds and output checks passed for all packages; `mix test test/scripts/brand_docs_contract_test.exs:15 --warnings-as-errors --seed 0` failed because ignored `doc/` outputs were absent; `node mailglass_admin/e2e/docs-theme-contract.cjs --all` was not run because it hardcodes those repo output paths. The report marks BRDOC-02 implementation satisfied while documenting this test/CI wiring blocker.
- `183-REVIEW-FIX.md`: WR-03's plural-Gettext regression test (12 tests) and adopter-corpus lint passed after the final fix. `183-REVIEW.md` is clean, but explicitly says the reviewer ran no tests; its clean verdict is not treated as validation evidence.

### Known Partial Blocker

The original `test/scripts/brand_docs_contract_test.exs:15` generated-output dependency is resolved: that assertion now runs in a standalone output contract outside root discovery, and the required docs job builds all three packages before invoking it. The local native-theme/layout browser check remains unverified because Chromium failed at startup. The unchanged full root suite also failed in seven tests, recorded by name in `183-03-SUMMARY.md`; their baseline attribution is unverified. Keep the phase partial until the browser and full-suite gates are reconciled.

No new test was added in this audit: the behavioral output test already exists, and the identified gap is its generated-output/CI wiring. This record does not claim full CI completion. The unrelated CI run described by plan 01 was still in progress at the recorded observation, and plan 02 records no CI run.

### Manual Handoffs Preserved

GitHub, Hex.pm, and HexDocs theme rendering; the paired CLAUDE.md/PRODUCT.md owner review; trademark-register/counsel review and any announcement decision; and optional social-card upload/read-back remain external owner or legal actions. The favicon capture remains a single authorized run; real Safari tab chrome was not observed, and no additional capture is authorized.

## Execution Re-verification — 183-03

- The root source/fixture contract passed with all three checkout README outputs absent (4 tests).
- One serial validation invocation built core (2s), Admin (1s), and Inbound (1s); the standalone three-package output contract passed (1s), and the owned temporary root was removed by the EXIT trap.
- Admin and Inbound emitted existing hidden-link/cross-package warnings. Core retained `--warnings-as-errors` and passed.
- Browser verification is blocked: installed Chromium SIGTRAPed during `bootstrap_check_in` with permission denied (1100). No package scenario ran; there was no browser install or second attempt.
- Focused workflow, required-check, lane parity, and classification contracts passed (85 tests). Mutation controls rejected removing the script, Inbound locked-dependency step, or CI Green edge.
- The unchanged full root suite ran with default discovery and all generated README outputs absent. It finished in 399.8s with 2,448 tests, 7 failures, 27 excluded, and 7 skipped. Exact failure names and first locations are in `183-03-SUMMARY.md`; baseline attribution is explicitly unverified. Three Phase 164 cases could not create sibling fixtures outside the workspace writable root.
- No hosted CI was dispatched. The original clean-checkout wiring issue is implemented, but phase verification remains partial until browser behavior and the full-suite failures are reconciled.

The local command for any later authorized browser re-verification is `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 PLAYWRIGHT_BROWSERS_PATH=/private/tmp/mailglass-183-02-playwright bash scripts/verify_brand_docs.sh --browser`. This execution did not repeat the browser attempt or dispatch remote CI.
