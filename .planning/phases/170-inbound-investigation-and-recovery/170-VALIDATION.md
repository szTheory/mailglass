---
phase: "170"
slug: inbound-investigation-and-recovery
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-08"
---

# Phase 170 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit in `mailglass_inbound` and `mailglass_admin`; Playwright Test for connected operator browser acceptance. |
| **Config files** | `mailglass_inbound/test/test_helper.exs`; `mailglass_admin/test/test_helper.exs`; `mailglass_admin/playwright.config.cjs`. |
| **Inbound quick run command** | From `mailglass_inbound`: `mix test test/mailglass_inbound/internal/operator/records_test.exs test/mailglass_inbound/replay_test.exs test/mailglass_inbound/async_execution_test.exs`. |
| **Admin quick run command** | From `mailglass_admin`: `mix test test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/inbound/components_test.exs test/mailglass_admin/inbound/evidence_card_test.exs test/mailglass_admin/inbound/replay_modal_test.exs`. |
| **Connected acceptance command** | From `mailglass_admin`: `npm run test:operator-browser`. |
| **Full suite commands** | `mix test --seed 1` from each of `mailglass_inbound` and `mailglass_admin`; `npm run test:operator-browser` from `mailglass_admin`; build and verify committed assets with `mix mailglass_admin.assets.build` and the existing token-parity/bundle tests when source classes change. |
| **Feedback latency** | Not measured in this planning session. Record actual duration and discovered test count during execution; split focused checks by package/module to keep task feedback bounded. |

The project pins Elixir `1.18.4` and Erlang `27.3.4.13`; research found those pins unavailable in the planning environment. Phase execution must use the pinned versions before treating Mix results as acceptance evidence. The Playwright package is installed, but browser-engine launch availability has not been verified. Do not add a test or browser dependency unless execution demonstrates the existing harness cannot meet a requirement.

## Sampling Rate

- After each inbound read/replay task commit: run the affected `mailglass_inbound` operator or replay ExUnit modules.
- After each Admin LiveView/component task commit: run the affected `mailglass_admin` inbound ExUnit modules.
- After each connected operator journey task: run its named Playwright case through `npm run test:operator-browser`.
- Before `$gsd-verify-work`: run both package suites, the complete operator browser suite, and the Admin asset/parity checks if CSS changed.
- Never report a browser interaction as verified by a component test alone; record the evidence boundary between ExUnit, connected browser, and rendered inspection.

## Per-Requirement Verification Map

| Requirement | Required observable behavior | Test locations / type | Planned automated evidence | Status |
|-------------|-----------------------------|-----------------------|----------------------------|--------|
| INUX-01 | Exact same-Account selection survives page/filter boundaries; return context is preserved; successful empty, filtered-empty, out-of-range, unavailable selection, absent package, explicit gateway error and DB connection failure are distinct; foreign IDs disclose no existence. | Inbound records ExUnit; Admin LiveView ExUnit; connected Playwright. | `mix test test/mailglass_inbound/internal/operator/records_test.exs` from `mailglass_inbound`; focused `inbound_live_test.exs`; named Phase 170 browser cases. | Pending plan tasks. |
| INUX-02 | List and detail agree on the latest fresh disposition; history is chronological; matched Mailbox, no match, failed execution, and missing history remain distinct; current-router trace is labeled as simulation. | Inbound operator ExUnit; Admin LiveView/component ExUnit. | Focused `records_test.exs` and `inbound_live_test.exs`/`components_test.exs`; include older matched followed by later fresh failure/no-match cases. | Pending plan tasks. |
| INUX-03 | Verification and route facts follow an explicit safe-field policy; raw payload/MIME is redacted by default; reveal authorization is checked at action time and resets on Account/record changes. | Admin component and LiveView ExUnit; connected keyboard/browser cases. | Focused `evidence_card_test.exs`, `inbound_live_test.exs`, and named Phase 170 browser cases with sensitive fixtures. | Pending plan tasks. |
| INUX-04 | Eligibility is revalidated for the exact Account/record at confirmation; denied, busy/duplicate, recorded failure, command failure, and unavailable history remain distinct; `:no_change` appears only when explicitly returned by Mailbox and persisted; context is retained. Selected lineage is a timestamped snapshot until an explicit refresh succeeds. | Inbound replay ExUnit; Admin LiveView/modal ExUnit; connected Playwright. | Focused `replay_test.exs`, `inbound_live_test.exs`, `replay_modal_test.exs`, and named Phase 170 browser cases. | Pending plan tasks; D-16 approves the additive explicit Mailbox outcome, which must be carried end to end. |

## Wave 0 Requirements

- [x] Existing ExUnit and Playwright infrastructure covers the phase; no framework or fixture package is identified.
- [ ] Map each final plan task to this requirement table after planner output; keep every runnable `<automated>` command paired with an observable `<fails_when>` condition in its PLAN.md.
- [ ] Confirm pinned Elixir/Erlang and the Playwright browser engine are available before execution acceptance; if a prerequisite is unavailable, record a blocker rather than a passing result.
- [ ] Implement D-16 end to end: explicitly returned `:no_change` passes through execution, append-only ExecutionRun persistence, operator projection and Admin wording; `:ignore`, projection diffs and reread results remain distinct.
- [ ] Implement D-17's narrow read failure mapping: explicit gateway error values and `DBConnection.ConnectionError` become sanitized unavailable states; all unrelated exceptions propagate.
- [ ] Implement D-18's timestamped selected-history snapshot and explicit native refresh; do not add polling or a new PubSub completion event.

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Responsive visual hierarchy, focus visibility/return, actual touch target sizing, zoom, Light/Dark/System, and reduced-motion behavior in the inherited Phase 168 visual contract. | INUX-01–INUX-04 | Browser assertions cover state and interaction, but a reviewer must inspect the rendered surface across representative viewports and modes. | Inspect the integrated inbound list → detail → evidence → replay → return flow at 320, 390, 768, and 1440 CSS-pixel widths; actual 200% browser zoom; keyboard and touch; Light/Dark/System; reduced motion; long/non-ASCII content; and empty, unavailable, denied, and busy states. Record source/served asset revision and any discrepancy. |

## Validation Sign-Off

- [ ] Every final plan task has an `<automated>` verify command or a declared Wave 0 dependency.
- [ ] No three consecutive tasks omit automated verification.
- [ ] Wave 0 covers every missing runtime/test/browser prerequisite.
- [ ] No watch-mode flags appear in commands.
- [ ] `nyquist_compliant: true` is set only after `$gsd-validate-phase` confirms coverage.

**Approval:** pending
