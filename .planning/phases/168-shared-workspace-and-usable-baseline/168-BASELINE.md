# Phase 168 Rendered Baseline and Evidence

backup_archive: /private/tmp/mailglass-168-preserved-workspace-20261007.tar.gz
backup_sha256: fa62a6fa7bc996522feb73886d2cf6f3a574361c7fa5005a0cfd1a600b896490
preserved_head: cba961712dcf9c35a40b248ca968a25830317e70
cleanup_sha: f668e0703076ac59526a63fb5167aeb7cee0d405
reconciled_head: 9db9f0141d0d29fcc6e008d53104c3a917bb9b0d
served_revision: 9db9f0141d0d29fcc6e008d53104c3a917bb9b0d
served_css_url: http://localhost:4015/ops/mail/css-390c8d481bfdb50f0ca2638b6e7fd0b5
served_css_sha256: f65c16baa68729d2899a85dbc3e190ad9fde714a8d8b6d20de47cd548e4951dc
before_capture: .planning/phases/168-shared-workspace-and-usable-baseline/artifacts/before/{health,deliveries,inbound}-{390,1440}.png (six Playwright captures; Light theme; 100% zoom; DPR 1)
pre_edit_gate_passed_at: 2026-10-07T18:26:52Z
pre_edit_gate_output: PASS: archive digest, required archive entries, exact dirty-path dispositions, cleanup source, checkout/served revision, served CSS URL/hash, and before capture recorded
after_served_revision: 9db9f0141d0d29fcc6e008d53104c3a917bb9b0d (mounted checkout; phase source changes present in working tree)
after_served_css_url: http://localhost:4015/ops/mail/css-c194069d2b5dc52f59a9660066dc3a02
after_served_css_sha256: 9fdd13bc40e0427c87d536ea26a0d924893fde2e2c7982d249a25e27a7ce9076
after_capture: .planning/phases/168-shared-workspace-and-usable-baseline/artifacts/after/{health,deliveries,inbound}-{390,1440}.png

## Workspace Preservation and Reconciliation

The backup archive contains exact `status.txt`, `worktree.patch`, `index.patch`, `deleted-paths.txt`, branch and HEAD records, copies of modified files, and originals of the two pre-existing deleted files. Its SHA-256 is recorded above. Each initial status path has an explicit disposition:

disposition[.planning/.continue-here.md]: deleted (pre-existing deletion, preserved)
disposition[.planning/HANDOFF.json]: deleted (pre-existing deletion, preserved)
disposition[.planning/STATE.md]: modified (parent GSD phase-start update; retained for SDK state workflow)
disposition[.planning/config.json]: modified (pre-existing local runtime configuration; preserved)
disposition[.planning/state.json]: modified (parent GSD phase-start update; retained)
disposition[mailglass_admin/test/mailglass_admin/voice_test.exs]: modified (byte-identical to the authoritative cleanup change; subsumed by merge)

The checkout began at `cba961712dcf9c35a40b248ca968a25830317e70` on local `main`. A fresh fetch located authoritative `origin/main` at cleanup squash `f668e0703076ac59526a63fb5167aeb7cee0d405`. The local planning lineage was nine commits ahead of its common base; cleanup was one commit ahead. The changed-file patch hash for cleanup and the staged merge delta both equal `c854d7da57f27615d58055638597563a675514fd30934b136358b8d4bad77565`. A two-parent merge commit `9db9f0141d0d29fcc6e008d53104c3a917bb9b0d` integrates cleanup while preserving the local planning history. The cleanup SHA is now an ancestor of the served checkout. No path-based source copy or history rewrite was used.

The demo is served on `http://localhost:4015` from the checkout mounted at `/workspace`; `docker exec mailglass-demo-demo-1 git rev-parse HEAD` returned the `served_revision` above. The exact operator stylesheet response URL and SHA-256 are recorded above; the response hash matched `mailglass_admin/priv/static/app.css` at capture time.

## Before Specimens

Fixture/persona: documented AtlasDesk demo login, Northstar Logistics, tenant ID `northstar`. Host: `localhost:4015`. Browser: Chromium via Playwright; theme: Light; OS appearance: default; zoom 100%; device scale factor 1; viewports are CSS pixels. Interaction state: initial route state after demo login, no filters, selection or pending navigation. Chrome was also used for direct inspection of Health, Deliveries, and configured Inbound on the live served application.

| Page | Route | Viewport | Screenshot | Observed before state |
|---|---|---:|---|---|
| Health | `/ops/mail?tenant_id=northstar` | 390x900 | `artifacts/before/health-390.png` | No shared Account identity in operator chrome; compact navigation wraps. |
| Deliveries | `/ops/mail?tenant_id=northstar&view=deliveries` | 390x900 | `artifacts/before/deliveries-390.png` | Account exists only as a page filter and is hidden while filters are collapsed; no stable tenant ID in chrome. |
| Inbound | `/ops/mail?tenant_id=northstar&view=inbound` | 390x900 | `artifacts/before/inbound-390.png` | Account exists only in filter controls; configured Northstar messages render. |
| Health | `/ops/mail?tenant_id=northstar` | 1440x900 | `artifacts/before/health-1440.png` | No shared Account identity in operator chrome. |
| Deliveries | `/ops/mail?tenant_id=northstar&view=deliveries` | 1440x900 | `artifacts/before/deliveries-1440.png` | Account is duplicated in page filters rather than the shared shell; no stable tenant ID in chrome. |
| Inbound | `/ops/mail?tenant_id=northstar&view=inbound` | 1440x900 | `artifacts/before/inbound-1440.png` | Configured Northstar messages render; account context is not shared in shell. |

## Review and Confirmation

Pre-edit rendered review confirmed all three actual served routes and their source/asset identity. The six baseline screenshots provide the desktop and compact reference at 1440x900 and 390x900.

The after review covered the same three routes at both widths on the restarted AtlasDesk demo. The selected Account label `Northstar Logistics` and full stable ID `northstar` are visible in the shared topbar at every route and viewport. The compact and desktop screenshots show the separate Change Account control and appearance controls; the 390px root had 0px horizontal overflow on all three pages. Inbound still shows a horizontally wide received-time table at 1440px, a pre-existing content issue owned by later UI work. The served CSS response SHA matches the rebuilt `mailglass_admin/priv/static/app.css` exactly.

Correction batch: the first browser interaction review found that the existing Quick view is an `aria-modal` dialog, so it correctly prevents clicking the shell behind it. The rendered flow now verifies that the account option URL drops `delivery_id`, closes the modal through its normal control, and then performs the actual account switch. No change to modal focus behavior was made. The test checks the switched Account's full ID and delivery detail scoped to `fjordline-aps`.

Confirmation: Playwright verified account context text and no root overflow across all six route/viewport combinations; the keyboard Enter key and a 390px touch tap both open the native Account menu (two options in the AtlasDesk fixture). The focused end-to-end account switch passed at 1280x900 on the separate `browser-tenant` harness with its Northstar/Fjordline test fixture. It confirmed the URL scope, removal of the prior delivery ID, and Fjordline delivery detail. The visual artifacts and test fixture remain distinct from the AtlasDesk demo baseline.

## Task 2 Review and Confirmation

After removing the page-level Account selectors, the restarted demo rendered Deliveries and configured Inbound with exactly one shared shell switcher. Both forms contain `input#filters_tenant_id[type=hidden][name="filters[tenant_id]"][value="northstar"]`; neither has an Account select. Provider and status/outcome/time selectors remain. Submitting the Inbound search retained `tenant_id=northstar` in the URL and in the hidden field. The account context stays in the shell independently of filter panel state. Browser DOM review on the served application found 0px root horizontal overflow on both routes.

The account menu was stress-reviewed at 320x900 and 390x900 CSS pixels with two duplicate long non-ASCII labels (`Ångström Partner Solutions — International Account Service Center — 東京`) and distinct long mixed-script IDs. The menu stayed bounded (288px / 352px), rows wrapped to 125px / 104px tall, each row's scroll width matched its client width, and root overflow stayed at 0px. This was a DOM content substitution for layout review; the live AtlasDesk fixture itself provides Northstar Logistics and Fjordline A/S labels. Live page text and the focused assertions cover the distinct exact empty-state and multi-Account chooser copy.

The asset build completed successfully. No stylesheet bytes changed in this task; the served URL remained `http://localhost:4015/ops/mail/css-c194069d2b5dc52f59a9660066dc3a02`, and both the built file and served response hashed to `9fdd13bc40e0427c87d536ea26a0d924893fde2e2c7982d249a25e27a7ce9076`. The live demo container restarted at source commit `8473783c988f275dbd11669fb8035f0ba519db4c` with the Task 2 LiveView sources compiled from the mounted working tree.

Focused command: `mix test test/mailglass_admin/operator/shell_test.exs test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs --seed 1` ran 174 tests (172 passed, 2 failed). The two failures are the pre-existing invalid-filter assertions that search the full LiveView document for `not-real`, which also occurs in the embedded Phoenix JavaScript; both are recorded in `deferred-items.md`. No Task 2 test failed.

## Task 3 Review and Confirmation

The focused shell command passed: `mix test test/mailglass_admin/admin_shell_test.exs test/mailglass_admin/operator/shell_test.exs --seed 1` reported 27 tests, 0 failures. Shell tests now assert that Preview remains when configured and Inbound is omitted when the optional surface is unavailable even if a path was supplied. Existing tests cover active `aria-current`, visible border/bold cues, and scope-only cross-surface paths.

The live AtlasDesk review covered operator Health, Deliveries and Inbound at 320, 390, 768 and 1440 CSS px, plus Preview at 320 and 768. The visible nav changes at the 768px breakpoint, and both sidebar and mobile sets mark the committed surface with `aria-current="page"`. Operator links keep `tenant_id=northstar`; a Health transition from a selected Inbound record removed `outcome` and `inbound_id`. Preview remained a separate surface with no operator Account context or switcher. At 320px, keyboard focus on Change Account showed an outline and a 44px target. The app toolbar and navigation remained within viewport bounds.

An offline click from Health to Deliveries triggered a full-document navigation and Chromium displayed its native `ERR_INTERNET_DISCONNECTED` page; after network restoration, normal direct navigation recovered the application. Because no app document is available during a total network outage, this path cannot render the in-app recovery message. This covers the non-renderable failure case; no route-change recovery copy was observed.

The required document-level overflow review found a pre-existing issue outside the shell/nav: the Health page's invisible `.mg-stat-card-tooltip` extends 1px past the viewport at 320px and 164px at 768px, while operator Deliveries/Inbound at 320px and Preview at 320/768px had 0px overflow. The tooltip overflow is logged in `deferred-items.md`; it was not changed because it is independent of the navigation and shell task. The current served bundle remains URL `http://localhost:4015/ops/mail/css-c194069d2b5dc52f59a9660066dc3a02`, SHA-256 `9fdd13bc40e0427c87d536ea26a0d924893fde2e2c7982d249a25e27a7ce9076`; this task made no CSS or HEEx class changes.

## Task 1 Review and Confirmation

Fixture/persona: AtlasDesk demo, Northstar Logistics (`tenant_id=northstar`). The live demo was served from the mounted checkout at `http://localhost:4015`; its Git HEAD was `be146c327f37ec5e9775aed65b298c4dcf9c88c3` while these task changes were uncommitted in the shared mount. Routes: Health `/ops/mail?tenant_id=northstar`; Deliveries `/ops/mail?tenant_id=northstar&view=deliveries`. Light and dark themes were reviewed. Captures use CSS pixel viewports and are in `artifacts/plan02/` (`168-task1-confirm-health-{320,390,720,768,1440}-{light,dark}.png` and `168-task1-deliveries-{320,390,720,768,1440}-{light,dark}.png`). The 720px CSS viewport was used to inspect the reflow expected at approximately 200% zoom on the 1440px review display; browser zoom itself was not changed for these captures.

The first rendered pass at 768px exposed Health metric cards that were too compressed in the three-column layout. The correction moves the three-column breakpoint to `lg`, then the confirmation pass verified readable labels and status values at all reviewed widths. The hidden `.mg-stat-card-tooltip` is now constrained to its stat card; at widths 320, 390, 720, 768 and 1440, in both themes, `documentElement.scrollWidth` and `body.scrollWidth` matched the viewport. This resolves the prior 1px overflow at 320px and 164px overflow at 768px recorded in Task 3 review and deferred item #37.

Deliveries now leads with its collection before filters. At 320px, the long exact delivery ID wraps without clipping and the masked recipient can wrap; at 768px, the table is inside a labeled, keyboard-focusable horizontal scroll region. The AtlasDesk fixture rendered all 16 deliveries. The built source bundle `mailglass_admin/priv/static/app.css` and served route `http://localhost:4015/ops/mail/css-61746f114342e2b0d49498a0fe73e560` both hash to `f69967633993c46a60cdb72e21e11c9ea7147574efda513964476bd7e562a20e`.

The invalid operator-filter test previously searched the full LiveView HTML for `not-real`; since the page embeds Phoenix JavaScript containing that literal, the assertion now checks the rendered `#filters_event` options directly and still proves the invalid value is rejected from the filter choices. Focused verification passed: 87 tests, 0 failures across operator LiveView, token parity and bundle tests. See `deferred-items.md` for the corresponding inbound assertion still awaiting Task 2.

## Plan 168-02 Task 2 Review and Confirmation

Fixture/persona: AtlasDesk demo, Northstar Logistics (`tenant_id=northstar`) on the mounted checkout at `http://localhost:4015`. The Deliveries filter panel was reviewed in the live browser at 320 CSS px with default values and again with invalid validation values; Inbound was reviewed at 320 CSS px with provider/outcome/time controls and field-specific errors. The `168-task2-inbound-validation-320.png` capture records retained invalid values, associated correction text, and the narrow layout. `168-task2-inbound-keyboard-focus.png` records keyboard focus on the time-window control with a visible outline. The page and body remained 320px wide.

Correction batch: Apply filters now keeps a fixed 160px width and 44px minimum height while showing `Applying filters…`, so pending feedback does not move the adjacent Clear filters action. The same busy behavior is present on both Operator and Inbound filter forms. Focused coverage asserts busy copy and stable width, retained invalid input, and the correction message association. `components_test.exs` was also aligned with Plan 01's shared Account shell: filter components no longer claim a duplicate Account field. The old full-document `not-real` checks were narrowed to their respective filter option elements because the embedded Phoenix client contains those characters; the operator and inbound invalid values are still checked against the actual options, with validation and tenant-scope assertions intact.

Keyboard review confirmed the time-window control's visible focus indicator at 320px. Chrome DevTools iPhone SE emulation reported `navigator.maxTouchPoints = 1`; in that emulated device context, the Deliveries Filters control opened and Provider, Status, Time window, Apply filters and Clear filters were present. The native device toolbar was closed afterward and Chrome returned to 100% zoom and System theme. Earlier Task 2 review used actual Chrome 200% zoom at an effective 320 CSS px; controls fit at 44px minimum height in both light and dark. Focused verification passed: 246 tests, 0 failures across component, operator and inbound LiveView checks. No CSS bundle bytes changed for this task; the source and served bundle remain in lockstep.

## Plan 168-02 Task 3 Review and Confirmation

The batch review covered the no-activity Account selector, a filtered-empty Delivery list, stale and unavailable Delivery data states, and the longest AtlasDesk Delivery specimen. The no-activity LiveView state asserts the approved `No Accounts with mail activity` heading and the `Send a Message` / `tenant_id` explanation. The filtered-empty component retains its distinct `No deliveries match the current filters.` copy and Clear filters action. Rendered component checks confirm stale data says `This view may be out of date.` and `Refresh the view to check for updates.`; unavailable data says `This view could not be updated.` and gives the exact administrator recovery sentence. The stale state no longer invents an observation time such as 14:32.

In the live AtlasDesk demo at `http://localhost:4015`, I opened the longest Delivery at 200% browser zoom and continued from Quick view to full detail. Full detail remained readable and exposed the original long recipient, exact Delivery UUID, provider message ID, and localized timestamp; the UTC value remains available through its timestamp control. The text stayed visible in the detail card, not behind hover. Focused test coverage also renders a non-ASCII recipient (`māil+東京@example.com`), Account label (`Ångström 東京`), and provider message ID (`msg-Ångström-東京`) and verifies their exact text plus the exact UTC timestamp.

Correction batch: replaced the synthetic stale timestamp and generic stale/unavailable wording with the approved cause-specific copy, and aligned the remaining legacy overview chooser text with the shared Account wording. No CSS classes or tokens changed, so no asset rebuild was needed; the existing source and served bundle remain byte-identical. Confirmation passed with `mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/voice_test.exs --seed 1`: 98 tests, 0 failures, 1 excluded. The voice test's obsolete chooser copy expectations were updated to the approved UI-SPEC strings; its existing syntax repair and all substantive chooser checks remain intact.
