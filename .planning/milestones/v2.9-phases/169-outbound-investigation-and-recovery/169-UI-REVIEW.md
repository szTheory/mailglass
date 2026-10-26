# Phase 169 — UI Review

**Audited:** 2026-10-08
**Baseline:** Approved `169-UI-SPEC.md`, inherited Phase 168 system, current Mailglass brandbook
**Screenshots:** Re-reviewed the refreshed 20 after captures at 320, 390, 768, and 1440 CSS px. Captures were refreshed for the remediation at revision `8b6c7cc6e96b99991c3c0bec7a6d9e4ca9c5d10e`; the audited source remediation is commit `74225d7e`.
**Interaction captures:** off (workflow.ui_interaction_capture is false)

The refreshed images show actual connected Health, Deliveries, detail, Quick view, and replay-review states. The four prior findings have corresponding rendered and DOM/behavior regressions; I checked representative changed Health, detail, and list images against the current source. Source, built, and served CSS parity is recorded for the refreshed run. The ten original before captures remain byte-identical. I did not treat test summaries as visual proof.

## Pillar Scores

| Pillar | Score | Key Finding |
|--------|-------|-------------|
| 1. Copywriting | 3/4 | Health interval wording/order now match; the timestamp-present “Last checked:” still adds a colon absent from the contract. |
| 2. Visuals | 4/4 | The two-column Health grid, evidence-first detail order, and content-width list layout match the contract in refreshed captures. |
| 3. Color | 4/4 | Open delivery links now use the link-role token; semantic theme and status colors remain consistent. |
| 4. Typography | 4/4 | Body, label, heading, and display roles use the declared 16/14/20/28px scale and 400/700 weights. |
| 5. Spacing | 4/4 | Inspected production spacing follows the 4px grid; 44px controls and readable reflow appear in captures. |
| 6. Experience Design | 4/4 | Refreshed connected and regression evidence covers exact return state, replay order, and responsive behavior; remaining proof limits are documented. |

**Overall: 23/24**

## Priority Fixes

The four findings from the initial review are resolved in remediation `74225d7e`; I found no remaining priority-level visual or interaction defect. One minor copy refinement remains: in the timestamp-present branch, remove the colon after “Last checked” to match `169-UI-SPEC.md`. Keep the colon in “Last checked: Unavailable.” [operator_live.ex:2514-2517]

## Detailed Findings

### Pillar 1: Copywriting (3/4)

- **WARNING — Minor exact-copy mismatch remains in the timestamp-present label.** The refreshed Health images show the required `Observed from {start} to {end} UTC ({hours} hours)` before the metric grid. However, `health_checked_copy/1` currently emits `Last checked: {time} UTC`; the contract's timestamp-present form is `Last checked {time} UTC`. Remove that colon while retaining `Last checked: Unavailable.` for the nil case. [operator_live.ex:700-707,2501-2517; refreshed `health-1440.png`, `health-768.png`]
- **PASS — Scope and metric labels are generally precise.** “Active suppression records” identifies the unit; its hint distinguishes current Mailglass records from historical suppressed Delivery Events. Failed webhook and unmatched Event hints identify their populations. The hints remain available to assistive technology as screen-reader-only text. [operator_live.ex:714-729,746-761,779-797; components.ex:467-480]
- No generic “Submit”, “Click Here”, or “OK” CTA was found in the audited outbound UI. Primary actions use “Review webhook replay”, “Confirm replay”, “Apply filters”, “Clear filters”, and “Back to deliveries”.

### Pillar 2: Visuals (4/4)

- **RESOLVED — Health metric layout now follows the specified breakpoint.** Source uses `md:grid-cols-2`; refreshed captures show one column at 320/390px and two at 768/1440px, with interval/check time preceding the metric grid. [operator_live.ex:699-709; refreshed `health-1440.png`, `health-768.png`]
- **RESOLVED — Detail action now follows its evidence.** The refreshed 768px detail capture orders identity/outcome → timeline → current suppression → Account support → replay action. `ReplayAction` is a separate final section after `SupportCards`. [operator_live.ex:990-1027; refreshed `detail-768.png`]
- **PASS — Shared shell, selected Account, clear page heading, visible text labels, native collection semantics, and explicit “Open delivery” control are present.** The collection uses cards at 768px because available content is 528px, and a table at 1440px with 1200px content; this follows the content-width threshold rather than viewport width. [deliveries_list.ex:120-164,235-303; `169-BASELINE.md` after-capture width table]
- Icon-only shell controls inspected in the audited components carry accessible labels; decorative icons are hidden from assistive technology in the capture/test evidence. The current marked-up findings show no ARIA-grid substitution.

### Pillar 3: Color (4/4)

- **RESOLVED — Ordinary row links use the established link-role color.** “Open delivery →” now references `--mg-color-link`; the refreshed list image shows the ordinary link treatment while retaining accent emphasis for selected/current cues and the replay review CTA. [operator/deliveries_list.ex:302; refreshed `deliveries-768.png`; `169-BASELINE.md`, remediation DOM assertion]
- The shell's light/dark palette and semantic status colors are token-based in `assets/css/app.css`; source classes use semantic roles rather than literal hex values. Failures have text/icon as well as color, no-match is neutral, and the suppression count is labeled “Tracked”. No universal green “healthy” state appears. [assets/css/app.css:31-86; components.ex:428-490; operator_live.ex:779-797]

### Pillar 4: Typography (4/4)

- **PASS — Contract size roles are defined in the shipped CSS:** label 14px, body 16px, heading 20px, display 28px, each with the specified line-height. The audited operator templates use these role classes and `font-bold` alongside the normal inherited weight; identifiers use `mono`. [assets/css/app.css:119-126; operator_live.ex and `operator/*.ex`]
- The after-capture record reports 16px body and 14px labels at 320, 390, 768, and 1440px; image inspection confirms wrapping rather than reduced body text. I found no added font face or competing type scale in the phase UI.

### Pillar 5: Spacing (4/4)

- **PASS — Inspected app spacing follows the declared 4px scale.** Components use named `xs/sm/md/lg` values and Tailwind spacing values such as `p-6`/`gap-4` (24px/16px), which are on-grid. The arbitrary `[overflow-wrap:anywhere]` and `max-w-[18rem]` values set wrapping/width behavior, not off-grid spacing. [operator_live.ex:696-699; components.ex:456-490; operator/detail_header.ex:38-116]
- The 320/390/768/1440 capture evidence records zero page-level horizontal overflow. The responsive result cards retain an explicit opener, and the detail/replay action controls are at least 44px high in source and the recorded rendered checks. This score does not imply physical-device touch was tested.

### Pillar 6: Experience Design (4/4)

- **PASS — Exact identity and evidence states are treated distinctly in source.** Delivery back navigation drops selected Delivery/full mode/exact support focus while preserving committed Account/filter/page state; exact selected events outside the 100-event slice render separately. [operator_live.ex:955-956,2175-2178; operator/timeline.ex:117-146]
- **PASS — Loading, partial/unavailable/stale Health reads, exact support read failure, replay zero/one/many review, stale-target rejection, pending duplicate prevention, and command-versus-audit feedback have implementation and focused test coverage.** The final Back behavior matches UI-SPEC rather than the superseded expectation that exact support IDs remain after returning to the list. [operator_live.ex:866-901,2025-2046; `169-VALIDATION.md` and `169-05-SUMMARY.md`]
- **PASS — The four corrected behaviors have targeted DOM/behavior assertions and refreshed representative captures.** The 2 rendered and 9 connected Phase 169 browser cases check the old interval wording/order, column counts, detail order, and link-token regression. Post-remediation verification records 100 focused LiveView tests, 538 full Admin tests (1 excluded), 9 token-parity/bundle tests, a passing asset build/parity check, and the full browser suite at 197 passed, 1 skipped, 0 failed. The validation closeout also includes trigger-backed replay terminal-write coverage (10 core replay and 104 focused Admin operator/replay tests). [169-BASELINE.md, “After Evidence — Bounded UI Audit Remediation”; 169-VALIDATION.md, terminal-write closeout]
- The 82 explicit criteria span E1–E11 and are covered by accumulated task tests, browser assertions, and rendered evidence as feasible. This review does not claim that every criterion or state combination was manually exercised. Physical-device touch, manual OS appearance switching, and the full native 200% route/theme matrix remain outside the recorded run. The representative responsive matrix and one native 200% route-family inspection are documented; these limits did not expose a remaining implemented-flow defect. [169-BASELINE.md; 169-VALIDATION.md, “Manual-Only Verifications”]
- **Interaction capture status:** off by configuration. The refreshed static captures document connected route states; interaction behavior is supported by DOM/behavior assertions and source.

## Files Audited

- `.planning/phases/169-outbound-investigation-and-recovery/169-UI-SPEC.md`
- `.planning/phases/169-outbound-investigation-and-recovery/169-CONTEXT.md`
- `.planning/phases/169-outbound-investigation-and-recovery/169-01-PLAN.md` through `169-05-PLAN.md`
- `.planning/phases/169-outbound-investigation-and-recovery/169-01-SUMMARY.md` through `169-05-SUMMARY.md`
- `.planning/phases/169-outbound-investigation-and-recovery/169-BASELINE.md` and `169-VALIDATION.md`
- `.planning/phases/168-shared-workspace-and-usable-baseline/168-UI-SPEC.md`
- `brandbook/brand-book.md`, `brandbook/copy/microcopy.md`, `mailglass_admin/docs/design-system.md`
- `mailglass_admin/lib/mailglass_admin/operator_live.ex`
- `mailglass_admin/lib/mailglass_admin/components.ex`
- `mailglass_admin/lib/mailglass_admin/operator/deliveries_list.ex`
- `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex`
- `mailglass_admin/lib/mailglass_admin/operator/timeline.ex`
- `mailglass_admin/lib/mailglass_admin/operator/quick_view.ex`
- `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex`
- `mailglass_admin/lib/mailglass_admin/operator/support_cards.ex`
- `mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex`
- `mailglass_admin/lib/mailglass_admin/operator/shell.ex`
- `mailglass_admin/assets/css/app.css`
- Existing screenshots: 20 files under `.planning/phases/169-outbound-investigation-and-recovery/artifacts/after/`

Registry audit skipped: the approved contract declares no shadcn or third-party registry, and no `components.json` exists.

## Orchestrator Copy Follow-up

The residual timestamp-present colon was removed after the independent reassessment; the unavailable label retains `Last checked: Unavailable` as specified. Focused current-source command from `mailglass_admin`: `ASDF_ELIXIR_VERSION=1.18.4-otp-27 ASDF_ERLANG_VERSION=27.3.4.15 MIX_ENV=test mix test test/mailglass_admin/operator_live_test.exs:2214 --seed 1` — 1 selected test passed (100 discovered, 99 excluded). The assertion now requires `Last checked ` and rejects `Last checked:` for the timestamp-present state. The independent 23/24 score above is retained as the actual audit result; no new visual score is claimed.
