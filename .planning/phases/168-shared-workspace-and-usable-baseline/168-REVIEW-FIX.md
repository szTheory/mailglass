# Phase 168 Review Fixes

## Fixed Issues

### WR-01: Account options lose link semantics in the accessibility tree

**Finding:** `role="listitem"` on each `<.link>` replaced its implicit link role, so screen readers could not identify the Account choices as links.

**Fix:** Render a semantic `ul > li` list and leave each Phoenix link's native anchor semantics intact. The no-selection chooser now shows the complete Account name and full `tenant_id` visibly, with wrapping layout at narrow widths. The selector test inspects the accessibility tree's link role and the visible full Account ID at 320px and 1440px.

**Evidence:** `mailglass_admin/e2e/structural.spec.js` Account chooser coverage; screenshots `artifacts/review-fix/account-chooser-320.png`, `account-options-320.png`, `selected-account-320.png`, and `account-options-1440.png`.

### WR-02: Replay focus trap escapes when the action is unavailable

**Finding:** The start sentinel focused an optional Confirm button. When no target was eligible, Confirm was absent and Shift+Tab left focus on the sentinel, allowing focus to escape an `aria-modal` dialog. A direct focus event also established that the old `phx-focus={JS.focus(...)}` value was not an executable client-side focus command.

**Fix:** Add the existing LiveView socket a small `ModalFocusTrap` hook that derives destinations from controls actually rendered, visible, and enabled in each dialog. Start and end sentinels wrap to the last and first available control. Attach it to operator and inbound Replay and Quick view dialogs; keep each dialog's existing close, Escape, eligibility, confirmation, server action, and focus-return behavior.

**Evidence:** `mailglass_admin/e2e/flows.spec.js`, `mailglass_admin/e2e/operator.spec.js`, and the inbound replay case in `flows.spec.js` exercise the normal Confirm wrap, no-target state, ambiguous unselected target, pending disabled Confirm, Quick view focus wrap, and exact trigger focus return. Full Playwright passed 184 tests with one existing guarded skip. Full ExUnit passed 513 tests with one excluded.

## UI Audit Dispositions

- **Chooser long text — fixed.** Full Account name and stable ID are visible and wrap at 320px; no tooltip is needed to discover either value.
- **Metric-card long text — fixed.** `stat_card` label and value wrap instead of truncating behind `title`; component tests cover the rendered content.
- **Essential typography — verified.** Browser-computed section navigation and status badges are at least 14px; body copy is 16px. A focused browser assertion checks the rendered sizes.
- **Spacing — false positive, no edit.** The cited `mt-1`, `mt-2`, `gap-1`, `p-4`, and `px-5` utilities are 4px-grid multiples. The audit treated utility spelling as off-grid without checking the spacing value. No mechanical class replacement was warranted.
- **Accent proportion — no measurable defect established.** Source reference counts do not measure rendered pixel area. Existing semantic accent roles were retained; no speculative palette edits were made.
- **Generic stat-card empty copy — no rendered defect.** Current operator call sites supply cause-specific copy. The reusable default was not changed without a consumer that renders it.
- **E2 Account switch loading — verified.** A browser test delays the real LiveView patch response and checks old Account identity and Delivery text remain committed until the new scope response arrives.
- **E2 Account switch error — N/A for this host contract.** The selected Account is URL scope, and the activity-derived options are explicitly not authorization. The host read contract has no separate tenant-selection denial response. The test suite does not infer unauthorized access from an absent option and no synthetic backend denial was added.
- **E3 theme persistence error — N/A for this app surface.** The existing theme controller writes the cookie on a full-page HTTP response and redirects; it has no app-managed persistence-failure state. Browser-level cookie rejection or network outage cannot produce an in-page persistence message from this route.
- **UUID non-ASCII long text — inapplicable.** Delivery target IDs are UUIDs. Their complete values wrap at 320px, and the test does not invent a non-ASCII ID contract.
- **E7 long error copy — verified by existing specimen.** Plan 03's 320px gallery test exercises long recovery copy and unbroken text, measuring equal 131px client and scroll widths.
- **E8 fallback assets — verified.** Plan 03 blocks five local font requests and hides decorative SVG styling; labels, controls, fallback text, and the Mailglass accessible name remain available. Physically deleting installed assets would test a different condition.
- **E8 enlarged text — covered by existing 200% browser zoom review.** Navigation labels remained visible and reachable; a separate text-only scaling browser mode was not available in this test setup.

The full baseline inventory and remaining honest Partial/N/A limits are in [168-BASELINE.md](168-BASELINE.md). The built stylesheet served from the restarted demo matched its source byte-for-byte: `c04faaedbf0bb15352be22f0afa040b7f87119a6a89f59e3d96c2012b6aa42b7`. The source revision before this batch was `d23a8b6d91db74c00317eaf96ac3afba3d107c95`; final corrective batch commit is recorded in the completion report.
