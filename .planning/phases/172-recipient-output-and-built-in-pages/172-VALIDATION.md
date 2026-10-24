---
phase: "172"
slug: "recipient-output-and-built-in-pages"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-09"
---

# Phase 172 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Existing ExUnit suites; existing Playwright/demo-browser evidence |
| **Config file** | Root `mix.exs`; `reference/demo_app/mix.exs`; `mailglass_admin/package.json` |
| **Quick run command** | `ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix test test/mailglass/renderer_test.exs test/mailglass/compliance/unsubscribe_controller_test.exs --warnings-as-errors --seed 1` |
| **Full suite command** | `node /Users/jon/.codex/gsd-core/bin/gsd-tools.cjs run-with-timeout 600 -- bash scripts/gsd-regression-gate.sh` |
| **Estimated runtime** | Up to 600 seconds by the configured gate timeout; a prior run completed within that bound |

The local researcher could not resolve Mix through its initial plain `asdf exec` probe. The project gate exports the repository's locked Erlang/Elixir versions before invoking Mix; use that repository toolchain or CI if the local shim remains unavailable. Browser evidence remains distinct from delivered email-client rendering.

---

## Sampling Rate

- **After every task commit:** Run the focused ExUnit command for the changed component, renderer, controller, or demo path.
- **After every plan wave:** Run the changed requirement's focused suites; do not repeat the full cross-project browser gate on unrelated waves.
- **Before `$gsd-verify-work`:** Run `bash scripts/gsd-regression-gate.sh` and the existing demo browser evidence command if the reference scenario changes.
- **Max feedback latency:** 600 seconds for the configured full regression gate.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 172-01-01 | 01 | 1 | MAILUX-02 | T-172-01 | Registered public-component Mailable remains inspectable beside AtlasDesk's bespoke renderer | integration | `(cd reference/demo_app && ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix test test/mailglass_demo/mailer_preview_scenarios_test.exs --warnings-as-errors --seed 1)` | ✅ existing demo Mailable suite; extend assertions | ✅ pass |
| 172-01-02 | 01 | 1 | MAILUX-01 | T-172-01 | Escaping, component hierarchy, type scale, email-safe default fonts, section rhythm, width, alt, theme, presentation and VML contracts remain intact | unit/component | `ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix test test/mailglass/config_test.exs test/mailglass/components/content_test.exs test/mailglass/components/button_test.exs test/mailglass/components/row_test.exs test/mailglass/components/vml_preservation_test.exs --warnings-as-errors --seed 1` | ✅ component and config defaults pinned by focused tests | ✅ pass |
| 172-01-03 | 01 | 1 | MAILUX-01, MAILUX-02 | T-172-02 | Browser preview distinguishes both authoring paths, keeps long output readable, and captures focused 375/320px email evidence; no recipient-client claim | browser | `bash scripts/run_demo_browser_evidence.sh` | ✅ existing demo browser evidence; assert content/layout and save email iframe screenshots | ✅ pass |
| 172-02-01 | 02 | 1 | MAILUX-03 | T-172-03 | Nested and unmarked anchors retain one useful destination in readable order | unit | `ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix test test/mailglass/renderer_test.exs --warnings-as-errors --seed 1` | ✅ renderer suite includes nested heading URL regression | ✅ pass |
| 172-02-02 | 02 | 1 | MAILUX-03 | T-172-04 | Unicode, image alternative, marker stripping, CSS inlining and text-body replacement remain covered | unit/integration | `ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix test test/mailglass/renderer_test.exs test/mailglass/components/vml_preservation_test.exs --warnings-as-errors --seed 1` | ✅ existing suites; extended assertions | ✅ pass |
| 172-02-03 | 02 | 1 | MAILUX-03, D-06 | T-172-04 | Mailable guides accurately explain renderer-generated plaintext across all five examples | docs contract | `ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix test test/mailglass/docs_contract_test.exs --warnings-as-errors --seed 1` | ✅ existing docs-contract suite; extend assertions | ✅ pass |
| 172-03-01 | 03 | 2 | MAILUX-04 | T-172-05, T-172-07 | Valid GET is informational, escaped and non-mutating; page typography, reading column, redirect and POST stay intact | integration/controller | `ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix test test/mailglass/compliance/unsubscribe_controller_test.exs --warnings-as-errors --seed 1` | ✅ controller assertions pin page font, spacing and no-card composition | ✅ pass |
| 172-03-02 | 03 | 2 | MAILUX-04 | T-172-06, T-172-07 | Invalid/expired pages keep 404/410 without disclosure; POST event/idempotency and current guide contract remain covered | integration/controller/docs | `ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix test test/mailglass/compliance/unsubscribe_controller_test.exs test/mailglass/docs/unsubscribe_guide_test.exs --warnings-as-errors --seed 1` | ✅ controller and guide contract suites; review correction verified | ✅ pass |
| 172-03-03 | 03 | 2 | MAILUX-04 | T-172-08 | Actual embedded page copy wraps without horizontal overflow at 320px and 200% zoom; invalid and expired states carry the approved cue | browser | `bash scripts/run_demo_browser_evidence.sh` | ✅ existing Playwright lane; verifies 1280/320/160px geometry and saves state screenshots at 1280/320px | ✅ pass |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. Add focused cases to existing component, renderer, controller, documentation-contract, and demo evidence suites. A fixed-state route inside the reference demo app allows the existing Playwright lane to render the actual embedded HEEx page for geometry assertions; no new framework, dependency, CI lane, or user-facing Mailglass route is needed.

---

## Manual-Only Verifications

All in-scope phase behaviors have automated verification. Playwright checks state copy, rendered widths, element ordering, and narrow CTA height, and captures focused browser screenshots for AI visual review without user UAT. The existing browser job remains advisory in CI; do not report it as blocking required CI proof or promote it. Actual delivered-message rendering in Gmail, Outlook, Apple Mail, image-disabled states, and client dark modes is outside this phase and must not be reported as verified.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency stays within 600 seconds for the full gate
- [x] `nyquist_compliant: true` set after validation

**Approval:** automated validation audit completed 2026-10-09; every in-scope machine-observable requirement has passing automated evidence. Recipient-client rendering remains explicitly outside this phase and unverified.

## Validation Audit 2026-10-09

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

## Phase-Level Review Follow-Up — 2026-10-09

- Focused follow-up command: `ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix test test/mailglass/config_test.exs test/mailglass/components/content_test.exs test/mailglass/components/button_test.exs test/mailglass/components/row_test.exs test/mailglass/components/vml_preservation_test.exs test/mailglass/compliance/unsubscribe_controller_test.exs --warnings-as-errors --seed 1` — 57 tests, 0 failures.
- Required regression gate after the source changes: core 79 tests, Admin 593 tests (1 excluded), inbound 3 properties plus 480 tests (3 excluded), connected browser 30 tests — all passed. The first browser launch was blocked by the macOS workspace sandbox; the same gate passed when rerun outside that sandbox.
- Latest focused Playwright rerun after screenshot/CTA refinements: 2 tests passed (unsubscribe states and invoice preview); the Mailable scenario suite passed 11/11. Persistent screenshots under `artifacts/browser-evidence/` show the three unsubscribe states at 1280/320px and the invoice output at 375/320px. The preview CTA is now “Review invoice”; the invoice ID remains in nearby live text, and the narrow screenshot shows the action on one line.
- Latest full advisory browser lane before the CTA-only copy refinement reported 73 passing checks, 2 unrelated existing failures (Helios empty-state heading and inbound detail header), and 0 flaky retries. The focused post-refinement checks passed; the broader advisory lane remains informational and does not replace the required regression gate.
- Fresh code review is clean (12 changed source/test files, no findings). Fresh UI review scores 24/24, and its visual review is backed by saved screenshots in `artifacts/browser-evidence/` plus automated viewport and touch-target assertions. Recipient-client email rendering remains out of scope and unverified.
