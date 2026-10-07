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

## Plan 168-03 Task 1 Review and Confirmation

Fixture/persona: AtlasDesk demo, Northstar Logistics (`tenant_id=northstar`), served from the mounted checkout at `http://localhost:4015`. The container ran at checkout HEAD `840d8bd72ddd1d0061a994208aa426be8300434c` after a container restart recompiled the HEEx changes. On the operator Health and Preview surfaces, the shared fieldset visibly reads `Appearance` and each native choice shows its icon plus `System`, `Light`, or `Dark`; exactly one radio remains selected. Light persisted from Health to Preview, Dark applied to operator chrome while the Preview email/backdrop stayed light, and System remained selected after a Preview reload. Browser zoom was reviewed at 100% and 200% on the available 1512×900 display; all labels remained visible. The seeded Preview content remained independent of the operator chrome preference.

The browser's current OS color scheme was light. The native OS setting was not changed, so an OS scheme transition was not directly exercised in this review. System's root-theme mapping and `prefers-color-scheme` CSS remain covered by existing theme and token behavior; the selected System radio remained stable through reload. Focused verification passed after the visible-label assertions were added: `mix test test/mailglass_admin/components_test.exs test/mailglass_admin/token_parity_test.exs test/mailglass_admin/bundle_test.exs --seed 1` reported 106 tests, 0 failures.

The generated stylesheet did not change for these markup-only utilities. Source `mailglass_admin/priv/static/app.css` and the served asset at `http://localhost:4015/ops/mail/css-61746f114342e2b0d49498a0fe73e560` both hash to `f69967633993c46a60cdb72e21e11c9ea7147574efda513964476bd7e562a20e`.

## Plan 168-03 Task 2 Review and Confirmation

Fixture/persona: AtlasDesk demo, Northstar Logistics (`tenant_id=northstar`), served from the mounted checkout at `http://localhost:4015`. After compiling the Task 2 changes, the `mailglass-demo-demo-1` container was restarted from checkout HEAD `031aee42f2540e786e3f621fe053613e09fd5497`. The live Inbound surface was inspected at browser zoom 100% and 200%; both kept the Account and Appearance controls visible, and the list remained readable. Light, Dark, and System selections were checked. The System radio remained selected when returning from Dark. The host OS was in Light mode and was not changed, so a System-following OS transition was not directly exercised.

The no-feedback Health state stayed banner-free. Inbound and Deliveries exposed distinct domain outcome text including No match, Rejected, Bounced, Accepted, Ignored, and Failed. Keyboard/assistive technology inspection exposed the exact recorded UTC value (for example `Recorded at 2026-10-07 20:06:18 UTC`) in the timestamp's accessible name/help text without requiring hover. Zoom was restored to 100% after review. The demo did not have a transient error flash, missing icon/font asset, or controllable pending state to trigger directly; focused component and LiveView tests cover explicit alert/status semantics, dismiss controls, long-copy wrapping, missing-time fallback, status labels and stable refresh identifiers. Reduced-motion was not emulated in the browser; the existing reduced-motion stylesheet rule remains in place.

The rebuilt bundle was served at `http://localhost:4015/ops/mail/css-316597e65daebb104f7022f799c83a88`; its SHA-256, `8521ab1444602cbf306192bdd84df36fb9523056e9d9ead727c46d45c8c03abc`, matched `mailglass_admin/priv/static/app.css`. The focused component/operator/inbound command passed 248 tests with 0 failures; the additional token parity and bundle command passed 8 tests with 0 failures. Existing Oban-unavailable environment warnings were emitted by the test runs.

## Plan 168-03 Bounded Acceptance Follow-up

Fixture/persona: isolated `browser-tenant` gallery fixture; test server on port 4102. Playwright ran `e2e/phase168-plan03-acceptance.spec.js` with one worker and reported 4 passed. Theme behavior was checked at 1280x900 CSS px, gallery feedback at 320x900 CSS px, with browser `colorScheme` and `reducedMotion` emulation. No host OS setting was changed.

The System preference stayed checked and the root `data-theme` attribute stayed absent while emulated OS Light computed to `rgb(248, 251, 253)` and emulated OS Dark computed to `rgb(13, 27, 42)`. Explicit Dark continued computing to `rgb(13, 27, 42)` under emulated Light, and explicit Light stayed `rgb(248, 251, 253)` under emulated Dark. System remained selected across Preview navigation and reload, and the computed Preview chrome palette followed emulated Dark.

At 320px, the disposable gallery rendered an assertive error alert with a focusable 44x44 dismiss control, long recovery copy, loading feedback, missing timestamp (`Unavailable`), and recorded timestamp accessible name `Recorded at 2026-10-07 20:06:18 UTC`. Long unbroken copy measured 178px client width and 178px scroll width. The stale specimen showed truthful refresh guidance with no synthetic `14:32` time. Reduced-motion emulation reduced the observed animation duration to `1e-05s`. The test blocked five font requests and hid decorative `svg[aria-hidden=true]` styling; feedback copy, controls, theme labels, and the Mailglass logo's accessible name remained available. These are disposable browser fixture conditions, not evidence of a physical font or icon failure.

The existing LiveView filter patch kept its support-detail node and produced zero new animation starts. Replaying the no-op refresh kept the success status node and text stable, recorded zero status-node mutations, retained the same delivery detail, and produced zero new animation starts. These DOM/live-region observations verify patch stability; actual screenreader speech output was not tested. Successful feedback came from the operator shell; error/loading and timestamp fallback specimens came from the existing component gallery.

Command: `BROWSER_SERVER_PORT=4102 OPERATOR_BASE_URL=http://127.0.0.1:4102 ./node_modules/.bin/playwright test --config=playwright.config.cjs --workers=1 e2e/phase168-plan03-acceptance.spec.js` (with the configured Elixir/OTP versions). No stylesheet source changed in this follow-up; the generated bundle remains SHA-256 `8521ab1444602cbf306192bdd84df36fb9523056e9d9ead727c46d45c8c03abc`. The served-asset URL captured during Plan 03 remains `http://localhost:4015/ops/mail/css-316597e65daebb104f7022f799c83a88`.

## Plan 168-04 Task 1 Review and Confirmation

Fixture/persona: disposable `browser-tenant` browser harness at `http://127.0.0.1:4102`; Direct Chrome review also used the AtlasDesk Northstar Delivery route at `http://localhost:4015/ops/mail?tenant_id=northstar&view=deliveries`. Source checkout HEAD was `93c5a61357dcdec0c44f87c13b03a2583de4542a`. The panel positioning now comes from `mailglass_admin/assets/css/app.css`; the rebuilt `mailglass_admin/priv/static/app.css` and served stylesheet `http://localhost:4015/ops/mail/css-52ce1efcbb874c638e2de6f5213d6a37` both hash to `19c8afedef5d24615ac832dc7f28cb7a051b7625d0051414ef9784e572bdb686`. `root.html.heex` retains only the unrelated local-time style.

The before specimen was the AtlasDesk Quick view at a 1512x792 CSS viewport, System preference with the host's Light appearance, selected first Delivery, keyboard/mouse open, 100% browser zoom. It showed the right-edge panel above the scrim with account, provider, exact Delivery ID, latest outcome and timestamp. After the stylesheet move, the disposable fixture was captured after its 220ms reveal at 320x900, 390x900, 768x900 and 1440x900 CSS pixels in System/Light appearance; captures are `artifacts/plan04/quick-view-{320,390,768,1440}-light.png`. The panel stayed inside the viewport, used a bottom sheet below 768px and a right-side panel capped at 42rem from 768px, retained its own scroll region, and layered above the scrim. The 320px specimen is the narrower layout sample for enlarged-content fit; the literal browser zoom setting was not changed during this task. Plan 168-02 Task 3 already records a direct 200% Chrome review that opened the Delivery Quick view before continuing to full detail.

Rendered acceptance command used the existing Playwright harness on port 4102 with a temporary focused viewport probe and one worker; all four widths, Escape dismissal, panel/scrim layer order, mobile 90vh bound/scroll and reduced-motion duration at or below 0.001s passed. `mix test test/mailglass_admin/token_parity_test.exs test/mailglass_admin/bundle_test.exs --seed 1` passed 9 tests with 0 failures. The browser harness emitted the existing Oban-unavailable and best-effort inbound-execution warnings.

## Plan 168-04 Task 2 Review and Confirmation

- **Source:** `mailglass_admin/lib/mailglass_admin/operator/quick_view.ex`, `operator_live.ex`, `operator/deliveries_list.ex`, and `e2e/flows.spec.js`. The URL remains the source of selected `delivery_id`; a focus-return selector is accepted only when it matches that record's stable desktop or mobile row ID.
- **Rendered route/fixture:** isolated browser tenant at `http://127.0.0.1:4102/ops/mail?tenant_id=browser-tenant&view=deliveries`; separate seeded browser fixture, 320 × 900 CSS px. The same case switches to a 1280 × 900 desktop viewport.
- **Observed:** the named `Delivery quick view` dialog opens by Enter from a mobile button and desktop table row. Focus enters Close, stays contained when tabbing after Open full detail, and Escape/Close return to the exact originating row. The complete UUID wraps without horizontal overflow at 320px. A nonexistent URL ID shows the detail error only; it renders no fallback record fields or Full detail action.
- **Evidence:** `npm run test:operator-browser -- --grep "Phase 168 Quick view focus|Operator error: delivery_id"` — 2 passed. `mix test test/mailglass_admin/operator_live_test.exs --seed 1` — 80 passed. The browser command rebuilds `priv/static/app.css` before starting the isolated Playwright server.
- **Unavailable evidence:** nil event type, timestamp, and provider use the explicit `Unavailable` treatment. Available Account, Provider, latest event, timestamp, and Delivery ID remain visible without title-only access.

## Plan 168-04 Task 3 Review and Confirmation

- **Source/route/fixture:** `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex` and `operator_live.ex`; isolated browser tenant at `http://127.0.0.1:4102/ops/mail?tenant_id=browser-tenant&view=deliveries`, 320 × 900 CSS px with Chromium touch emulation. The live fixture contains an exact replay target (`browser-exact-delivery` provider event); a fixed old `recent_auth_at` drives the existing server denial.
- **Light/dark and motion:** with System selected, the confirmation panel's computed surface color followed emulated Light → Dark → Light. Under `prefers-reduced-motion: reduce`, computed animation and transition durations were each ≤0.001s.
- **Observed:** the dialog is named “Confirm webhook replay for …” and describes the existing replay operation. The exact webhook event ID remains visible. Holding the real LiveView response after Confirm kept that target visible while the button read “Replaying…” and was disabled. Releasing the response showed “Replay completed with new work” plus the separate recorded requested/completed audit events. No downstream Delivery success was inferred. A stale-auth denial retained the modal and exact target with “Recent authentication is required.”; Escape returned focus to Replay webhook. A delivery with no eligible target displayed Replay unavailable and rendered no target ID or Confirm action.
- **Evidence:** `npm run test:operator-browser -- --grep "Phase 168 confirmation focus"` — 1 passed. The case ran in an isolated touch-enabled Chromium context, intercepted only its LiveView response for the pending probe, and left denial/success replies intact.

## Plan 168 Final Confirmation

- **Rendered browser suite:** `npm run test:operator-browser` on isolated harness port 4102 — 183 passed, 0 failed, 1 existing guarded skip. The initial full run exposed mobile overflow in Inbound metadata and Preview error identifiers, a 768px gallery sidebar overflow, a theme-picker pointer affordance, an Account chooser locator ambiguity, and fixed Flash specimens covering focusable gallery controls. These were corrected in this phase; the final full suite passed.
- **ExUnit:** focused shell, components, operator, inbound, voice, token parity and bundle checks — 302 tests, 0 failures, 1 excluded.
- **Gallery obstruction diagnosis:** at 320px, `elementFromPoint` found the fixed Flash toast at viewport `(16,16)` covering the nav-link focus target. Gallery-only Flash specimens now render inline; the same hover/focus/disabled/touch-target matrix passes, and the test asserts the gallery has no fixed Flash toast.
- **Demo asset identity:** restarted only `mailglass-demo-demo-1`. The demo stylesheet route `/dev/mail/css-a5aa8f353f9543034287ed8382ce0e70` and rebuilt `mailglass_admin/priv/static/app.css` both hash to `b19d6219708e6f73b65dcf144db5483b2a848678ab95957deffea45bbc26e783`; source `assets/css/app.css` hash is `2810f438d6452966d00f02e4a41cc203f414af6a9cc3a36a17099ae4af87a9f9`.

## Final UI-SPEC Coverage Inventory (52 Criteria)

Status records the execution evidence in this baseline. `Partial` and `Pending` remain unproven states and are not treated as passes.

| Criterion | Status | Evidence / limit |
|---|---|---|
| E1 / loading | Partial | Plan 168-01 nav/route checks; no delayed navigation fixture. [168-01 summary](168-01-SUMMARY.md) |
| E1 / error | Pending | Failed navigation recovery was not triggered in this execution. |
| E1 / overflow | Pass | Plan 168-02 320/390/768/1440 and 200% shell review. [168-02 summary](168-02-SUMMARY.md) |
| E1 / long-text | Partial | Configured nav labels and accessible names inspected; no long localized destination fixture. |
| E2 / empty | Pass | No-activity chooser specimen and empty/filtered distinction. [168-02 summary](168-02-SUMMARY.md) |
| E2 / loading | Pending | Account switch pending state was not delayed in a browser fixture. |
| E2 / error | Pending | A rejected Account switch was not induced. |
| E2 / populated | Pass | Northstar scope, stable ID, selector and row scoping. [Account scope case](../../../mailglass_admin/e2e/flows.spec.js) |
| E2 / partial | Pass | Missing host label fallback and permitted selected ID checks. [168-01 summary](168-01-SUMMARY.md) |
| E2 / overflow | Pass | Narrow Account header/filter and 200% review. [168-02 summary](168-02-SUMMARY.md) |
| E2 / zero-one-many | Pass | No-activity, one-Account auto-select and multi-Account switch evidence. [168-01 summary](168-01-SUMMARY.md) |
| E2 / long-text | Pass | Duplicate/non-ASCII Account labels and full IDs inspected. [168-01 summary](168-01-SUMMARY.md) |
| E3 / empty | Pass | System is selected by default; explicit System/Light/Dark radios remain available. [Plan 03 acceptance](../../../mailglass_admin/e2e/phase168-plan03-acceptance.spec.js) |
| E3 / loading | Partial | Palette updates promptly; persistence failure/latency was not induced. [Plan 03 acceptance](../../../mailglass_admin/e2e/phase168-plan03-acceptance.spec.js) |
| E3 / error | Pending | Preference persistence failure was not induced. |
| E3 / partial | Pass | System selection followed emulated OS light/dark and survived navigation/reload. [Plan 03 acceptance](../../../mailglass_admin/e2e/phase168-plan03-acceptance.spec.js) |
| E3 / overflow | Pass | Theme controls reflowed at the narrow and desktop viewports. [168-02 summary](168-02-SUMMARY.md) |
| E3 / long-text | Partial | 200% labels were reachable; enlarged-text browser setting was not separately emulated. [168-02 summary](168-02-SUMMARY.md) |
| E4 / empty | Pass | Unset filters preserved visible default meanings. [168-02 summary](168-02-SUMMARY.md) |
| E4 / loading | Pass | Stable busy/filter patch retained values and prevented duplicate submit. [Plan 03 acceptance](../../../mailglass_admin/e2e/phase168-plan03-acceptance.spec.js) |
| E4 / error | Pass | Invalid filter values retained and showed field-specific correction. [168-02 summary](168-02-SUMMARY.md) |
| E4 / partial | Pass | Provider/status/window filters preserved unrelated valid values. [168-02 summary](168-02-SUMMARY.md) |
| E4 / overflow | Pass | 320/390/768/1440 and 200% control fit review. [168-02 summary](168-02-SUMMARY.md) |
| E4 / long-text | Partial | Visible labels fit; no artificially long option/correction fixture. |
| E5 / empty | Pass | No activity, filtered-empty and no-selection states stayed distinct. [168-02 summary](168-02-SUMMARY.md) |
| E5 / loading | Partial | Existing busy/stale states reviewed; cold-load latency was not injected. [Plan 03 acceptance](../../../mailglass_admin/e2e/phase168-plan03-acceptance.spec.js) |
| E5 / error | Pass | Stale and unavailable data copy/recovery remained distinct. [168-02 summary](168-02-SUMMARY.md) |
| E5 / populated | Pass | Health summary and selected Delivery full evidence were inspected. [168-02 summary](168-02-SUMMARY.md) |
| E5 / partial | Pass | Missing timestamps/metrics use Unavailable; no synthetic stale time. [168-02 summary](168-02-SUMMARY.md) |
| E5 / overflow | Pass | Health/Delivery surfaces bounded at 320/390/768/1440 and 200%. [168-02 summary](168-02-SUMMARY.md) |
| E5 / zero-one-many | Pass | Page counts and one/many Delivery results retain existing semantics. [168-02 summary](168-02-SUMMARY.md) |
| E5 / long-text | Pass | Full recipient/provider IDs visible in detail without hover at 200%. [168-02 summary](168-02-SUMMARY.md) |
| E6 / empty | Pass | No selection keeps Quick view closed; zero-target Replay has no Confirm. [Quick view](../../../mailglass_admin/e2e/flows.spec.js), [confirmation](../../../mailglass_admin/e2e/flows.spec.js) |
| E6 / loading | Pass | Delayed LiveView reply showed disabled “Replaying…” with exact target retained. [confirmation case](../../../mailglass_admin/e2e/flows.spec.js) |
| E6 / error | Pass | Nonexistent ID never substitutes a record; stale auth retains exact target and cause. [Quick view](../../../mailglass_admin/e2e/flows.spec.js), [confirmation](../../../mailglass_admin/e2e/flows.spec.js) |
| E6 / populated | Pass | Quick view identity/outcome and requested/completed Replay audit were visible. [Quick view](../../../mailglass_admin/e2e/flows.spec.js), [confirmation](../../../mailglass_admin/e2e/flows.spec.js) |
| E6 / partial | Partial | Nil event/provider/time render Unavailable; nil-value browser fixture was not seeded. [operator_live_test.exs](../../../mailglass_admin/test/mailglass_admin/operator_live_test.exs) |
| E6 / overflow | Pass | 320px Quick view wraps the full UUID, scrolls within the panel, and traps focus; screenshots: `artifacts/plan04/`. |
| E6 / zero-one-many | Pass | Zero unavailable state, one exact target browser path, and ambiguous explicit-choice LiveView tests. [operator tests](../../../mailglass_admin/test/mailglass_admin/operator_live_test.exs) |
| E6 / long-text | Partial | UUID wrapping and full target IDs verified; no non-ASCII ID fixture (Delivery IDs are UUIDs). |
| E7 / empty | Pass | No event renders no feedback; missing time uses Unavailable. [168-03 summary](168-03-SUMMARY.md) |
| E7 / loading | Pass | Text busy feedback, stable live region and reduced-motion response verified. [Plan 03 acceptance](../../../mailglass_admin/e2e/phase168-plan03-acceptance.spec.js) |
| E7 / error | Pass | Cause-specific auth, stale and unavailable messages remained visible. [confirmation](../../../mailglass_admin/e2e/flows.spec.js), [168-02 summary](168-02-SUMMARY.md) |
| E7 / populated | Pass | Explicit status badge and exact UTC timestamp labels inspected. [168-02 summary](168-02-SUMMARY.md) |
| E7 / overflow | Partial | Feedback fit the sampled 320px dialog; long error-copy scaling was not separately seeded. |
| E7 / long-text | Partial | Technical IDs and feedback remained readable; no maximum-length failure message fixture. |
| E8 / empty | Pass | Hiding decorative SVGs preserved labels and the Mailglass accessible brand name. [Plan 03 acceptance](../../../mailglass_admin/e2e/phase168-plan03-acceptance.spec.js) |
| E8 / loading | Pass | Blocking font requests preserved fallback text and controls. [Plan 03 acceptance](../../../mailglass_admin/e2e/phase168-plan03-acceptance.spec.js) |
| E8 / error | Partial | Blocked-font/decorative-icon simulation passed; actual missing local font file was not removed. |
| E8 / populated | Pass | Theme-aware Mailglass mark and existing icon set rendered. [168-03 summary](168-03-SUMMARY.md) |
| E8 / overflow | Pass | Logo/icons remained in reserved bounds at 320/768/1440 and touch viewports. [168-03 summary](168-03-SUMMARY.md) |
| E8 / long-text | Partial | Enlarged navigation labels were reviewed at 200%; custom fallback text was not injected. |
