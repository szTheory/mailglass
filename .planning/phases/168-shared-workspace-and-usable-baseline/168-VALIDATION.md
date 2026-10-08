---
phase: "168"
slug: "shared-workspace-and-usable-baseline"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-10-07"
---

# Phase 168 — Validation Strategy

Execution audit refreshed on 2026-10-08. All 23 tasks across Plans 01–10 have automated coverage and passing final results. Direct visual evidence and its limits are recorded separately in `168-BASELINE.md`; the baseline inventory retains its evidence labels and does not imply every specimen passed.

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

| Task | Wave | Requirements / gap | Automated command and failing signal | Direct browser acceptance | Threat refs | Status |
| --- | ---: | --- | --- | --- | --- | --- |
| 168-05 T1 | 5 | UXF-03, G-168-5 | `npm --prefix mailglass_admin run test:operator-browser -- --grep "Phase 168 Delivery Mailable wrapping"`; nonzero, no matching test, zero executed/passed, or failed exact-text/wrapping/geometry assertion | Exact long Mailable remains readable at 320/390/768/1440 CSS px and actual 200% browser zoom; zoom factor is read back from Chromium | T-168-10 | pass |
| 168-06 T1 | 6 | UXF-06, G-168-6 | `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs --only g_168_6 --seed 1`; nonzero, zero tests, missing badge, or dispatch snapshot shown instead of latest downstream outcome | Outcome semantics across responsive views are additionally covered by the complete browser suite | — | pass |
| 168-06 T2 | 6 | UXF-03, G-168-5 / 200% readability | `ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 BROWSER_SERVER_PORT=4102 npm --prefix mailglass_admin run test:operator-browser -- --grep "Phase 168 Delivery Mailable wrapping"`; nonzero, no matching test, zero executed, missing/empty artifact, zoom readback other than 2, or failed text/line/geometry assertions | Playwright sets and reads real Chromium tab zoom 2; separate CSS viewport screenshots remain accurately labeled | T-168-SC | pass |
| 168-07 T1 | 6 | UXF-02, G-168-7 | `cd mailglass_admin && ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 mix test test/mailglass_admin/operator_live_test.exs --only g_168_7 --seed 1`; nonzero, zero/tagless test, LiveView exit, or prior Account exact evidence displayed | — | T-168-12 | pass |
| 168-07 T2 | 6 | UXF-06, G-168-10 | `cd mailglass_admin && ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 mix test test/mailglass_admin/operator_live_test.exs --only g_168_10 --seed 1`; nonzero, zero/tagless test, prior-window value shown, or same-window stale fallback lost | — | — | pass |
| 168-07 T3 | 6 | UXF-07, G-168-9 | `cd mailglass_admin && ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 mix test test/mailglass_admin/operator_live_test.exs --only g_168_9 --seed 1`; nonzero, zero/tagless test, LiveView exit, pending state retained, target changed/lost, or retry bypasses authorization | — | T-168-13 | pass |
| 168-08 T1 | 6 | UXF-04/07/08, G-168-8 | `cd mailglass_admin && ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 mix test test/mailglass_admin/preview_live_test.exs --only g_168_8 --seed 1`; nonzero, zero/tagless test, wrong clear-flash key, or rendered feedback remains after dismissal | — | T-168-15 | pass |
| 168-09 T1 | 7 | UXF-04 | `ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 BROWSER_SERVER_PORT=4102 npm --prefix mailglass_admin run test:operator-browser -- --grep 'Phase 168 (Delivery Mailable wrapping|Account scope)'`; nonzero, fewer than two tests, `getZoom()` not exactly `2`, the combined zoom/viewport not exactly 320 CSS px, a shared control/radio label outside the viewport or clipping its box, or document horizontal overflow | At actual Chromium zoom 2, topbar controls and every radio label are checked for visibility, viewport bounds, element scroll geometry, and document overflow at both 720px and 320px CSS layout widths | T-168-16 | pass |
| 168-09 T2 | 7 | UXF-03 | Same focused browser command; nonzero, fewer than two tests, rendered text differing from its complete expected fixture value, clipped/unreachable final character, 320px combined viewport/zoom failure, or document overflow | At actual Chromium zoom 2 and again at 320px CSS layout width, Delivery ID is compared with the selected row ID; Mailable/provider/provider-message ID with fixed fixture values; and event ID/recorded UTC timestamp with fixture attributes. The Delivery explanation is also checked at 320px. Element text-range/final-character and container geometry plus document overflow are checked. The selected first event has no provider event ID or provider-occurrence timestamp, and the test asserts both are absent rather than treating them as covered value examples. | T-168-16 | pass |
| 168-09 T3 | 7 | UXF-08 | Same focused browser command; nonzero, fewer than two tests, no visible polite atomic pending status, a pending-status ID not matching the numeric token shape, changed committed Account/data while held, or stale pending status after completion | Real Account option click with held LiveView patch; checks `role=status`, `aria-live=polite`, `aria-atomic=true`, numeric ID independent of the tenant ID, old scope/data during pending, and new scope/status clear after release | T-168-16 | pass |
| 168-10 T1 | 8 | UXF-03, D-03 | `cd mailglass_admin && ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 mix test test/mailglass_admin/components_test.exs test/mailglass_admin/operator/shell_test.exs --seed 1`; nonzero or zero tests | — | T-168-17 | pass |
| 168-10 T2 | 8 | UXF-03, D-03 | `cd mailglass_admin && ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 mix test test/mailglass_admin/token_parity_test.exs --seed 1` and `ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 BROWSER_SERVER_PORT=4102 npm --prefix mailglass_admin run test:operator-browser -- --grep "Phase 168 shared spacing"`; nonzero, zero tests, an offending half-step class/missing source or bundle utility, or computed margin/row gap not equal to 4px | Existing browser case reads computed style from a rendered Inbound error icon and Preview scenario list using served CSS | T-168-17 | pass |

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

None remain as owner UAT. The previously listed machine-observable visual, interaction, theme, zoom, and adverse-state checks now have current automated evidence in the existing ExUnit/Playwright stack. Historical screenshot and specimen notes remain in `168-BASELINE.md` as evidence context and limitations, not an owner checkpoint.

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

## Validation Audit 2026-10-08

| Metric | Count |
|---|---|
| Plans / summaries audited | 8 / 8 |
| Tasks with automated coverage | 18 / 18 |
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

The audit checked all eight PLAN/SUMMARY pairs, the corresponding current ExUnit and Playwright regressions, UAT and phase verification ledgers, and D-52 in `METHODOLOGY.md`/`PROJECT.md`. Plans 05–08 add deterministic browser and LiveView coverage; no further test artifact was needed. Current supplied phase-wide evidence: ExUnit 550 tests, 0 failures, 1 excluded; operator Playwright 198 passed, 0 failed, 1 existing guarded skip. No owner UAT remains.

## Plan 09 Gap-Closure Validation 2026-10-08

| Metric | Count |
|---|---|
| Plans / summaries audited | 9 / 9 |
| Tasks with automated coverage | 21 / 21 |
| Plan 09 behavioral regressions run | 2 / 2 |
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Reviewed `168-09-PLAN.md`, `168-09-SUMMARY.md`, the current Playwright assertions, prior validation/UAT evidence, and D-52. The existing `Phase 168 Delivery Mailable wrapping` test exercises actual Chromium tab zoom via `setZoom`/`getZoom`, asserts the factor is exactly 2, then checks shared controls, radios, and each radio label at 720px CSS width. It next sets the browser viewport to 640 device pixels while preserving 2x tab zoom and asserts both `window.innerWidth` and the document client width are exactly 320 CSS px; it rechecks all controls and labels, every complete fixture-backed Delivery/timeline value, the Delivery explanation, and document overflow at that combined condition. Element text-range/final-character, container, and viewport geometry remain part of the checks. The event fixture selected by this test has no provider-event ID or provider-occurrence timestamp; the test asserts that those optional fields are absent. The delayed `Phase 168 Account scope` test uses the real switcher and holds the LiveView response while checking visible `role=status` with polite/atomic semantics, a numeric status ID (rather than tenant-ID-derived selector content), the old committed Account/data pair, then the new Account and cleared pending node. The shell implementation uses the enumerated option index for `JS.show` and status IDs, so punctuation in a tenant ID cannot change the selector target; the browser regression also fails if the ID is changed back to an interpolated tenant ID.

Latest post-strengthening verification: `ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 BROWSER_SERVER_PORT=4102 npm --prefix mailglass_admin run test:operator-browser -- --grep 'Phase 168 (Delivery Mailable wrapping|Account scope)'` — **2 passed, 0 failed**, including the combined 200% zoom/320px CSS layout assertions. No new test artifact, dependency, CI requirement, or owner UAT is needed. The later full regression gate in `168-REGRESSION.md` passed 542 Admin tests and 198 browser tests, with 1 excluded Admin test and 1 existing guarded browser skip; it supersedes the earlier transient-failure note in the initial execution summary.

## Post-Audit Confirmation

Corrective commit `ed53da64`: full ExUnit 513 tests, 0 failures, 1 excluded; full Playwright 184 passed, 0 failures, 1 guarded skip (2m36s); focused post-format Playwright 8 passed. Automated task coverage remains complete. Current generated/served CSS SHA-256: `c04faaedbf0bb15352be22f0afa040b7f87119a6a89f59e3d96c2012b6aa42b7`. Independent goal verification remains the final gate; visual Partial/N/A rows are not silently converted to passes.


## Plan 10 Gap-Closure Validation 2026-10-08

| Metric | Count |
|---|---|
| Plans / summaries audited | 10 / 10 |
| Tasks with automated coverage | 23 / 23 |
| Plan 09 behavioral regressions rechecked | 2 / 2 (existing recorded run) |
| Plan 10 source/CSS ExUnit checks run | 135 passed, 0 failed |
| Plan 10 rendered Playwright checks run | 1 passed, 0 failed |
| Gaps found | 0 |
| Resolved | 0 (existing assertions already cover both tasks) |
| Escalated | 0 |

Reviewed all ten PLAN/SUMMARY pairs, this validation map, Plan 10's source and browser assertions, and D-52 in `.planning/METHODOLOGY.md`. The TokenParity regression enumerates six templates, rejects half-step Tailwind spacing utilities with file/class diagnostics, and checks source and generated CSS for the 4px `--spacing-xs` token and `mt-xs`/`gap-xs` rules. The `Phase 168 shared spacing` Playwright case opens the existing Inbound and Preview fixtures and reads computed `marginTop` and `rowGap`; both must equal `4px`. No duplicate test was needed.

Reran `cd mailglass_admin && ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 mix test test/mailglass_admin/token_parity_test.exs test/mailglass_admin/components_test.exs test/mailglass_admin/operator/shell_test.exs --seed 1` — **135 tests, 0 failures**. Reran `ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 BROWSER_SERVER_PORT=4102 npm --prefix mailglass_admin run test:operator-browser -- --grep "Phase 168 shared spacing"` — **1 passed, 0 failed**. Chromium initially failed to launch under the restricted sandbox (Mach-port permission); the same focused command passed with the approved elevated browser setup. Plan 10 summary records the asset build passing; it was not rerun because it writes the generated implementation bundle. No owner UAT is required under D-52.

Current audit disposition: **23 / 23 tasks have automated coverage; Plans 09 and 10's focused checks pass; no gaps are open or escalated.**
