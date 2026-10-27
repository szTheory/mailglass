---
phase: 175
fixed_at: 2026-10-27T21:07:23Z
review_path: .planning/phases/175-delivery-investigation-and-safe-replay/175-REVIEW.md
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 175: Code Review Fix Report

**Fixed at:** 2026-10-27T21:07:23Z  
**Source review:** `175-REVIEW.md`  
**Iteration:** 1

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

## UI Review Repairs

- Inbound quick, full-detail, and confirmation actions use the primary accent; actual failure feedback keeps semantic error colors. Full detail now uses “Review inbound replay.” Covered by inbound component and replay-modal tests. Commits: `a9670252`, `093655d6`.
- The Storybook theme helper uses `var(--shadow-overlay)` and current fidelity asserts its inline token and computed shadow. Commit: `a9670252`.
- Outbound replay modal padding and top margins use existing `p-md` and `mt-lg` aliases. Its 12px `space-y-3` is documented as deliberate `sm + xs` presentation spacing; no spacing token or framework was added. Commit: `a9670252`.

## Current-source verification

Fresh combined run: `mailglass-evidence-20261027205816-4815-29177`, source revision `fc262b989c1c38ab86376437ff2dc4b1ef4ea9a8`, Phase 175 source digest `0700f87bb124f955131e20fd8f69fcf87c0a50a499aa636d954b49dc9400eedb`, Phase 174 digest `7ee933bd225c6f8ae0ddf04aaa6edf2c4b07ebb99cf7cede21972e6e970897ae`.

- Cold and warm each passed Demo 4/4, connected Admin 10/10, fidelity 10/10, Axe 26/26, Delivery layout 6/6, and Inbound layout 6/6.
- Each Axe condition reports 0 violations and 116 incomplete findings; the incompletes are independently triaged and remain incomplete.
- `node --test scripts/check_phase175_evidence.test.cjs`: 6/6 passed.
- `bash scripts/gsd-regression-gate.sh`: Node contracts 41/41; core 81/81; Admin 661/661 with 1 excluded; Inbound 480/480 with 3 excluded; connected browser 31/31.
- Retained proof: `artifacts/phase175/phase175/execution.json` and condition reports/screenshots. The isolated Compose project used `mailglass_demo_phase175_05`; cleanup completed and removed its volumes.

No owner UAT checkpoint is added for these machine-observable fixes. Hosted CI and hosted runner cost were not measured; the evidence is local Chromium proof for the selected inventory, and the 116 Axe incompletes remain an explicit limit.

---

_Fixed: 2026-10-27T21:07:23Z_  
_Fixer: the agent (gsd-code-fixer)_  
_Iteration: 1_
