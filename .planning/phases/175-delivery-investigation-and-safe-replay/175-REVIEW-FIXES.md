---
phase: 175
fixed_at: 2026-10-27T21:49:52Z
review_path: .planning/phases/175-delivery-investigation-and-safe-replay/175-REVIEW.md
iteration: 2
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 175: Code Review Fix Report

**Fixed at:** 2026-10-27T21:49:52Z

**Source review:** `175-REVIEW.md`  
**Iteration:** 2

This report carries forward the three fixes from iteration 1 and records the additional warning from the independent re-review. The source review history remains unchanged.

## Fixed Issues

### WR-01: [WARNING] Stale outbound authentication is reported as an access denial

**Files modified:** `mailglass_admin/lib/mailglass_admin/operator/destructive_action.ex`, `mailglass_admin/lib/mailglass_admin/operator_live.ex`, `mailglass_admin/lib/mailglass_admin/operator/repair_state.ex`, `mailglass_admin/test/mailglass_admin/operator_live_test.exs`, `mailglass_admin/test/mailglass_admin/operator/repair_state_test.exs`, `mailglass_admin/e2e/flows.spec.js`  
**Commit:** `42d41c8a`; browser assertion follow-up `fc262b98`  
**Applied fix:** Preserve the normalized authorization failure reason through outbound replay. Expired recent authentication now shows “Recent authentication is required.” and supports fresh review; unauthorized access retains the Account-admin denial copy and command-time authorization. The browser assertions distinguish these paths.  
**Verification:** Focused LiveView/RepairState tests passed (123 total, 0 failures; 11 selected); current-source combined cold/warm Demo/Admin/fidelity/Axe proof passed; full regression gate passed.

**Fix status:** fixed and automatically verified by the focused tests and current-source connected receipts above (D-52).

### WR-02: [WARNING] First successful re-review falsely says the exact request changed

**Files modified:** `mailglass_admin/lib/mailglass_admin/operator_live.ex`, `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex`, `mailglass_admin/test/mailglass_admin/operator_live_test.exs`  
**Commit:** `2b9a412f`; test-flow correction `093655d6`  
**Applied fix:** Track whether an existing selected target actually changed. A first successful review after an unavailable read shows the ordinary exact-request prompt. A formerly selected target that changes shows changed-request feedback. No replacement target is selected implicitly; confirmation requires deliberate selection.  
**Verification:** Focused LiveView tests passed (121 total, 0 failures; 12 selected), including initial rereview and replacement-target cases. Fresh Admin browser reports passed 10/10 in both cold and warm conditions.

**Fix status:** fixed and automatically verified by the focused tests and current-source connected receipts above (D-52).

### WR-03: [WARNING] Fidelity checker accepts arbitrary files as retained screenshots

**Files modified:** `scripts/check_phase175_evidence.cjs`, `scripts/check_phase175_evidence.test.cjs`, `scripts/run_demo_browser_evidence.sh`, `reference/demo_app/assets/e2e/storybook-fidelity.spec.js`
**Commit:** `84b24a0e`  
**Applied fix:** Require the 320px, 1440px, and actual 200% zoom screenshots in each current run evidence directory. Reject missing or extra inventory, wrong-run paths, symlinked ancestors/leaves, bad PNG signatures and corrupt chunk/CRC or compressed image data. The producer and current-source manifests cover the actual capture contract.  
**Verification:** The six checker tests pass, covering a clean decoded PNG, arbitrary text, corrupted PNG, missing inventory/capture, wrong run directory, and symlinked ancestor/leaf. Fresh cold and warm fidelity receipts validate the three real captures apiece; the final archived receipt check exits 0.

**Fix status:** fixed and automatically verified by the focused tests and current-source connected receipts above (D-52).

### WR-04: [WARNING] Screenshot validation does not enforce the required capture dimensions

**Files modified:** `scripts/check_phase175_evidence.cjs`, `scripts/check_phase175_evidence.test.cjs`, `reference/demo_app/assets/e2e/storybook-fidelity.spec.js`, `reference/demo_app/Dockerfile`, `reference/demo_app/mix.exs`, `scripts/check_phase174_evidence.cjs`, `scripts/check_phase174_evidence.test.cjs`, `scripts/check_phase175_evidence.test.cjs`

**Commits:** `31274372`, `0deab1a1`

**Applied fix:** Return decoded PNG dimensions from the existing CRC/zlib/scanline validator and bind each required screenshot to the producer's observed capture geometry: viewport width and height, DPR, zoom-adjusted effective DPR, screenshot scale, document width, and measured body content height. Retain representative 320×2153, 1440×1363, and 640×4316 positive fixtures; reject wrong-width, 1×1, and too-short images for all responsive and zoom slots. Existing corruption and unsafe-path checks remain. The resolution follow-up constrains already-locked `boundary` 0.11.0 and `websock_adapter` 0.6.0 in the Demo Mix manifest, uses `mix deps.get --check-locked` at container startup, and includes `mix.exs` in selected-source hashing.
**Verification:** Seven Phase 175 tests pass (16 combined Phase 174/175 checker tests); syntax checks and `git diff --check` pass. Fresh combined run `mailglass-evidence-20261027221513-96275-31939` exited 0 against revision `0deab1a14e28a8fb32d06a7d9e864d8d0fe508a0`, Phase 175 digest `d01817a07796768cbf874ba35715aa3945a3f59971104b362e82417244901fa7`, and Phase 174 digest `13694a3171535116a61d8ef3ed8c102cb5a664ef1d5c53fc9d401c58ba1d681c`. Cold and warm captures decode to 320×2153, 1440×1363, and 640×4316; both durable checkers pass. The lock SHA-256 remained `1472692952d9ddbd91df7a116a4b5cf28f717ca3369a7a04bf80cc94b39711d7` before and after the 450.753-second run. The configured regression gate passed Node 42/42, core 81/81, Admin 661, Inbound 3 properties + 480, and browser 31/31.

**Fix status:** fixed and automatically verified under METHODOLOGY D-52; no owner UAT checkpoint is required.

## UI Review Repairs

- Inbound quick, full-detail, and confirmation actions use the primary accent; actual failure feedback keeps semantic error colors. Full detail now uses “Review inbound replay.” Covered by inbound component and replay-modal tests. Commits: `a9670252`, `093655d6`.
- The Storybook theme helper uses `var(--shadow-overlay)` and current fidelity asserts its inline token and computed shadow. Commit: `a9670252`.
- Outbound replay modal padding and top margins use existing `p-md` and `mt-lg` aliases. Its 12px `space-y-3` is documented as deliberate `sm + xs` presentation spacing; no spacing token or framework was added. Commit: `a9670252`.

## Current-source verification

Fresh combined run: `mailglass-evidence-20261027221513-96275-31939`, exit 0, source revision `0deab1a14e28a8fb32d06a7d9e864d8d0fe508a0`, Phase 175 source digest `d01817a07796768cbf874ba35715aa3945a3f59971104b362e82417244901fa7`, Phase 174 digest `13694a3171535116a61d8ef3ed8c102cb5a664ef1d5c53fc9d401c58ba1d681c`.

- Cold and warm each produced Phase 174 Demo 101/101, hooks 6/6, fidelity 26/26, Axe 26/26 and Phase 175 Demo 4/4, connected Admin 10/10, fidelity 10/10, Axe 26/26, Delivery layout 6/6, and Inbound layout 6/6. Both archived source-bound checkers pass against the current committed source.
- Retained PNG geometry is 320×2153, 1440×1363, and 640×4316. Observed receipts bind the images to 320px and 1440px responsive viewports and an actual 200% tab-zoom capture with 320px effective viewport, initial DPR 2, effective DPR 4, and screenshot scale 2.
- Each Axe condition reports 0 violations and 116 incomplete findings; the incompletes are independently triaged and remain incomplete.
- `node --test scripts/check_phase174_evidence.test.cjs scripts/check_phase175_evidence.test.cjs`: 16/16 passed (9 Phase 174, 7 Phase 175).
- `bash scripts/gsd-regression-gate.sh`: Node contracts 42/42; core 81/81; Admin 661 tests (0 failures, 1 excluded); Inbound 3 properties + 480 tests (0 failures, 3 excluded); connected browser 31/31.
- Retained proof: `artifacts/phase175/phase175/execution.json` and condition reports/screenshots. The isolated Compose project used `mailglass_demo_phase175_05`; cleanup completed and removed its volumes.

The earlier 21:52 combined attempt exited 1 at the selected-source check with `ERROR: Phase 175 selected-source digest is stale`; its failure marker, Phase 175 reports, and exact lock diff remain in `artifacts/phase175/runner-failures/mailglass-evidence-20261027215211-71763-23440/`. The diff records `boundary` 0.11.0 → 0.12.0 and `websock_adapter` 0.6.0 → 0.7.0. The adjacent `runner-output.log` was found to belong to a separate successful 22:03 run and moved under `artifacts/phase175/historical-success/` to avoid mislabeling. The full raw stdout for the 21:52 failure was not retained after the temporary monitor log was reused; `runner-failures/README.md` records this limitation. The current 22:15 run is separate, exits 0, and is the final proof.

The current runner stdout is retained at `artifacts/phase175/runner-success-mailglass-evidence-20261027221513-96275-31939.log`. The isolated locked-resolution probe and before/after lock hashes are retained at `artifacts/phase175/dependency-resolution-probe.log`.

No owner UAT checkpoint is added for these machine-observable fixes. Hosted CI and hosted runner cost were not measured; the evidence is local Chromium proof for the selected inventory, and the 116 Axe incompletes remain an explicit limit.

---

_Fixed: 2026-10-27T21:49:52Z_

_Fixer: the agent (gsd-code-fixer)_  
_Iteration: 2_
