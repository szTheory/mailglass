---
phase: "168"
slug: "shared-workspace-and-usable-baseline"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-07"
---

# Phase 168 — Validation Strategy

Execution audit completed on 2026-10-07. All 11 tasks have automated coverage and passing final results. Direct visual evidence and its remaining limitations are recorded separately in `168-BASELINE.md`; automated coverage does not imply that all 52 visual criteria have passed.

## Test Infrastructure

| Property | Value |
| --- | --- |
| Framework | Existing ExUnit/LiveView tests and opt-in Playwright suite |
| Config | `mailglass_admin/mix.exs`, `mailglass_admin/playwright.config.cjs` |
| Quick command (repository root) | `cd mailglass_admin && mix test test/mailglass_admin/admin_shell_test.exs test/mailglass_admin/components_test.exs test/mailglass_admin/operator/shell_test.exs --seed 1` — failure signal: nonzero exit or `0 tests`. |
| Phase integration command (repository root) | `cd mailglass_admin && mix test test/mailglass_admin/admin_shell_test.exs test/mailglass_admin/components_test.exs test/mailglass_admin/operator/shell_test.exs test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/token_parity_test.exs test/mailglass_admin/bundle_test.exs test/mailglass_admin/voice_test.exs --seed 1` — failure signal: nonzero exit or `0 tests`. |
| Asset build (repository root) | `cd mailglass_admin && mix mailglass_admin.assets.build` — failure signal: nonzero exit or expected `priv/static/app.css` absent. |
| Existing browser command (repository root) | `npm --prefix mailglass_admin run test:operator-browser` — failure signal: nonzero exit, no tests found, or a parsed zero executed/passed test count. |
| Runtime | Focused runs and the complete browser run finished during execution; exact timings were not retained consistently. No timing claim is made. |

Executed with `ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15` and `BROWSER_SERVER_PORT=4102` for the isolated browser fixture. Commands require the package's documented toolchain/database setup. Resolve host Elixir/OTP mismatch through the existing gating-toolchain container when necessary; do not change CI or dependency policy. Browser fixture host and AtlasDesk demo are distinct; label evidence accordingly. The existing opt-in browser harness is not a new product Node toolchain.

## Sampling Rate

- After an implementation task: run the smallest existing checks covering that task, with an observable nonzero/missing-assertion failure condition in its plan.
- After a plan wave: run affected integration and asset checks. Rebuild source CSS before bundle checks and before rendered review.
- Before Phase 168 verification: affected checks and the specified direct-browser matrix must pass; source assertions alone cannot establish visual quality or focus behavior.
- Keep review bounded to one inspection, one corrective batch, and one confirmation per coherent slice; extend only for a concrete unresolved blocker.
- Feedback target: under 120 seconds for focused checks; measure actual timing in execution and report slower prerequisites honestly.

## Per-Task Verification Map

Every command is rooted at the repository checkout. Existing test targets and the `mailglass_admin` package path were verified against tracked source; three focused Playwright cases named `Phase 168 Account scope`, `Phase 168 Quick view focus`, and `Phase 168 confirmation focus` were added to tracked `e2e/flows.spec.js`. The additional four cases in `e2e/phase168-plan03-acceptance.spec.js` exercise OS scheme changes, reduced motion, fallback assets, transient feedback, and repeated LiveView patches. Pass below refers to automated task coverage; consult the baseline inventory for direct visual acceptance.

| Task | Wave | Requirements | Automated command and failing signal | Direct browser acceptance | Threat refs | Status |
| --- | ---: | --- | --- | --- | --- | --- |
| 168-01 T1 | 1 | UXF-01/02/07 | Python pre-edit evidence check in Plan 01 verifies the outside-worktree backup digest, archived status and per-path dispositions, cleanup/source and served-CSS fields; rerun it with `npm --prefix mailglass_admin run test:operator-browser -- --grep "Phase 168 Account scope"`; failure on missing evidence, nonzero exit, no tests found, or parsed zero executed/passed count | Served before/after, 390/1440, real Account switch, full ID/URL/scope | T-168-01/02 | pass |
| 168-01 T2 | 1 | UXF-02/06/07 | `cd mailglass_admin && mix test test/mailglass_admin/operator/shell_test.exs test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs --seed 1`; nonzero or `0 tests` | 320/390, collapsed filters, zero/one/many, long/duplicate names, configured Inbound | T-168-01 | pass |
| 168-01 T3 | 1 | UXF-02/07 | `cd mailglass_admin && mix test test/mailglass_admin/admin_shell_test.exs test/mailglass_admin/operator/shell_test.exs --seed 1`; nonzero or `0 tests` | 320/768/1440, active nav, absent optional Inbound, focus, committed route | T-168-02 | pass |
| 168-02 T1 | 2 | UXF-03/06 | `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/token_parity_test.exs test/mailglass_admin/bundle_test.exs --seed 1`; nonzero or `0 tests` | 320/390/768/1440, 200% zoom, Light/Dark, long/non-ASCII/absent facts | T-168-04 | pass |
| 168-02 T2 | 2 | UXF-04/07 | `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs --seed 1`; nonzero or `0 tests` | Keyboard/touch filter states, busy/invalid/disabled, 320 and zoom | T-168-03 | pass |
| 168-02 T3 | 2 | UXF-06 | `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/voice_test.exs --seed 1`; nonzero or `0 tests` | No activity/no match/stale/unavailable and full original values | T-168-04 | pass |
| 168-03 T1 | 3 | UXF-04/05 | `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs test/mailglass_admin/token_parity_test.exs test/mailglass_admin/bundle_test.exs --seed 1`; nonzero or `0 tests` | Three visible labels, OS change/reload while System checked, Admin/preview | T-168-05 | pass |
| 168-03 T2 | 3 | UXF-04/06/08 | `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs --seed 1`; nonzero or `0 tests` | No/pending/error/stale feedback, exact time, reduced motion, repeated patch | T-168-06 | pass |
| 168-04 T1 | 4 | UXF-07/08 | `cd mailglass_admin && mix test test/mailglass_admin/token_parity_test.exs test/mailglass_admin/bundle_test.exs --seed 1`; nonzero or `0 tests` | Before/after panel at 320/390/768/1440 and zoom/reduced motion | T-168-07 | pass |
| 168-04 T2 | 4 | UXF-06/07 | `npm --prefix mailglass_admin run test:operator-browser -- --grep "Phase 168 Quick view focus"`; nonzero, no tests found, or parsed zero executed/passed count | Keyboard/touch open/close, trap/return, long content, empty/error | T-168-07 | pass |
| 168-04 T3 | 4 | UXF-01/06/07/08 | `npm --prefix mailglass_admin run test:operator-browser -- --grep "Phase 168 confirmation focus"`; nonzero, no tests found, or parsed zero executed/passed count | Exact target, busy/denied/recent-auth/outcome, focus and reduced motion | T-168-08/09 | pass |

The same `168-BASELINE.md` specimen ledger is updated through the serialized waves. Each task's browser pass is one batched inspection, one corrective batch, and one confirmation. An additional pass requires a recorded concrete blocker.

## UI-SPEC Criterion Allocation

| Explicit state criteria | Plan/tasks | Count | Evidence route |
| --- | --- | ---: | --- |
| E1 shared shell/navigation | 168-01 T3 | 4 | Nav checks plus committed-route desktop/narrow inspection |
| E2 Account context/switch | 168-01 T1-T2 | 8 | Switch browser path, scoped LiveView checks and zero/one/many inspection |
| E3 Appearance picker | 168-03 T1 | 6 | Component/token checks and OS/reload browser matrix |
| E4 Filters/controls | 168-02 T2 | 6 | Component/LiveView checks and interactive states at width/zoom |
| E5 Working summaries/Delivery collection | 168-02 T1/T3 | 8 | Operator checks and Health/Deliveries specimen matrix |
| E6 Quick view/confirmation | 168-04 T1-T3 | 8 | Asset/parity checks, focused browser paths and focus review |
| E7 Feedback/status/timestamps | 168-03 T2 | 6 | Component/LiveView checks and repeated-update review |
| E8 Mark/icons | 168-03 T2 | 6 | Component/bundle checks and enlarged/fallback inspection |
| **Total** | | **52** | All 52 appear individually in plan `must_haves.truths` as `E#/category` items. |

Fallback edge probe: six empty/encoding rows for UXF-03/06/07 have explicit truths in Plans 02/04; five unclassified rows for UXF-01/02/04/05/08 remain flagged assumptions in Plans 01-03. Descriptor-less recalled prohibitions remain flagged-unverified in plan frontmatter; no invented wired check or green disposition is claimed.

## Wave 0 Requirements

- Existing test infrastructure is available. No framework installation is planned.
- Reconcile preserved source with merged cleanup while retaining unrelated work; run Plan 01's Python evidence gate against the preserved backup and source/served-CSS fields, then record its passing output/time and directly inspect the current before specimens before UI edits. Rerun the evidence gate with Task 1's browser path before marking that task done.
- Record toolchain, database, browser and fixture prerequisites. Treat unavailable prerequisites as unverified, never as passing.
- Add focused regressions only for demonstrated gaps in the approved behaviors; retain substantive authorization/scope/action checks when presentation assertions change.

## Manual-Only Verifications

“Manual” means direct browser/visual inspection, which the executing agent may perform with browser tools.

| Behavior | Requirement | Why direct inspection | Instructions |
| --- | --- | --- | --- |
| Identified before/after specimens | UXF-01 | Historical artifacts and source checks do not prove current output | Record source/asset identity, route, fixture/persona, theme/OS scheme, viewport, zoom, state, issue and capture. |
| Reflow, readable exact values and targets | UXF-02, UXF-03, UXF-04, UXF-06, UXF-07 | Markup does not prove clipping/readability | Inspect representative 320/390/768/1440 CSS px and 200% zoom, long/non-ASCII names/IDs, touch and keyboard. |
| Theme preference versus effective scheme | UXF-05 | Cookie/radio assertions do not prove OS response | Choose System; change OS scheme; navigate and reload; verify System remains selected and email appearance remains independent. |
| Overlay focus and motion | UXF-07, UXF-08 | Structural focus hooks do not prove actual focus/animation | Open/close Quick view and confirmation; cycle focus, Escape/dismiss, return focus; inspect reduced motion and repeated LiveView patches. |
| Applicable adverse states | UXF-01..08 | Fixtures need truthful, visible state | Cover UI-SPEC's 52 criteria through a representative matrix; distinguish unavailable/denied/empty/partial/stale, never fabricate a success. |

## Validation Sign-Off

- [x] Every task has an automated verification or explicit prerequisite; direct-browser evidence and limitations are recorded.
- [x] No three consecutive implementation tasks lack automated feedback.
- [x] No missing test targets or watch-mode commands.
- [x] Actual outcomes recorded; missing exact timings disclosed above.
- [x] `nyquist_compliant: true` set only when established by the appropriate validation workflow.

**Approval:** Automated coverage validated 2026-10-07. Phase goal and visual acceptance await the independent UI audit and verifier.

## Execution Results

- Pre-edit backup/source/served-asset Python gate passed before UI changes (2026-10-07T18:26:52Z).
- Final affected ExUnit batch: 302 tests, 0 failures, 1 excluded. Earlier obsolete presentation assertions were repaired without weakening scope or authorization checks.
- Final complete opt-in Playwright suite: 183 passed, 0 failed, 1 existing guarded skip.
- Rebuilt CSS matched the live demo response: SHA-256 `b19d6219708e6f73b65dcf144db5483b2a848678ab95957deffea45bbc26e783`.
- Evidence: all four execution summaries and `168-BASELINE.md`, including direct viewport/zoom/focus/motion results. Pending and partial visual states remain explicitly identified there.

## Planning Review

2026-10-07: Independent plan checker passed after one targeted revision to enforce the backup, reconciliation, and served-baseline prerequisites before UI edits. Final review reported no blockers or warnings. Deterministic planning probes resolve all 11 task verification commands and their failure statements. Coverage gates found all 8 requirements, 11 decisions, and 52 explicit UI state criteria represented. These are planning checks; product tests, baseline capture, and rendered acceptance remain pending.

## Validation Audit 2026-10-07

| Metric | Count |
|---|---|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

## Post-Audit Confirmation

Corrective commit `ed53da64`: full ExUnit 513 tests, 0 failures, 1 excluded; full Playwright 184 passed, 0 failures, 1 guarded skip (2m36s); focused post-format Playwright 8 passed. Automated task coverage remains complete. Current generated/served CSS SHA-256: `c04faaedbf0bb15352be22f0afa040b7f87119a6a89f59e3d96c2012b6aa42b7`. Independent goal verification remains the final gate; visual Partial/N/A rows are not silently converted to passes.
