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
