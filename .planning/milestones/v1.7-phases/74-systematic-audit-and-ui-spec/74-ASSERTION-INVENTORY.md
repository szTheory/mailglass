---
phase: 74
plan: 02
artifact: AUDIT-03
status: baseline-frozen
created: 2026-06-04
---

# 74-ASSERTION-INVENTORY — Before-Baseline: E2E Heading and Seed-Count Assertions

> AUDIT-03 before-baseline. Zero production code was changed and zero e2e spec files were
> modified during Phase 74. The two source files are READ-ONLY in this phase. This inventory
> captures every `test()` heading, every heading/copy/testid assertion, and the seed-count
> baseline so Phase 79 can perform a deliberate before/after diff after build phases 75-78 ripple them.

**Source files inventoried (unmodified):**
- `mailglass_admin/e2e/operator.spec.js` — 5 `test()` blocks under `describe("operator browser gate")`
- `reference/demo_app/assets/e2e/demo.spec.js` — 3 `test()` blocks under `describe("mailglass demo evidence")`

---

## Section 1 — operator.spec.js Assertion Inventory

**File:** `mailglass_admin/e2e/operator.spec.js`
**Describe block:** `"operator browser gate"` (line 23)
**Total test() blocks:** 5

### openOperator helper (lines 13-21) — shared setup, called by all 5 tests

| spec_file:line | assertion kind | exact asserted string / value | ripple risk |
|---|---|---|---|
| operator.spec.js:14 | seed-reset | `GET /ops/browser-reset` → `ok()` | Phase 78 (SEED-02) — if reset endpoint changes behavior |
| operator.spec.js:17-18 | navigation | goto `/ops/browser-login?tenant_id=browser-tenant&return_to=/ops/mail?tenant_id=browser-tenant` | Phase 75 (IA-03) — if operator URL structure changes |
| operator.spec.js:19 | heading | `getByRole("heading", { name: "Deliveries", exact: true })` | **HIGH — Phase 75 (IA-03)**: IA vocabulary pass may rename "Deliveries"; this assertion will break if heading text changes |
| operator.spec.js:20 | testid | `getByTestId("operator-deliveries-list")` | Low — testid stable unless list container restructured |

### test() 1: "desktop keeps list/detail in two panes and preserves read-only selection flow" (line 24)

| spec_file:line | assertion kind | exact asserted string / value | ripple risk |
|---|---|---|---|
| operator.spec.js:28 | viewport | `{ width: 1280, height: 900 }` | Low — viewport unchanged |
| operator.spec.js:30 | testid | `getByTestId("operator-deliveries-list-card")` | Low — card wrapper testid; stable unless restructured |
| operator.spec.js:31 | testid | `getByTestId("operator-detail-column")` | Low — layout pane testid; stable |
| operator.spec.js:32 | testid | `getByTestId("operator-empty-detail")` | Medium — Phase 75 (IA-03): Operator Overview `:overview` action replaces the empty-detail slot; this testid may no longer appear on initial load if overview replaces empty state |
| operator.spec.js:34 | visibility | `emptyDetail.toBeVisible()` | Medium — same as above (Phase 75 ripple) |
| operator.spec.js:36-41 | layout | `deliveriesCard.boundingBox()` y <= `detailColumn.boundingBox()` y | Low — two-pane layout invariant unchanged |
| operator.spec.js:43 | testid (nth) | `operator-delivery-row` index 0 | Phase 78 (SEED-02) — seed row order may change if seeds are re-ordered |
| operator.spec.js:47 | attribute | `aria-selected="true"` on row | Low — attribute contract stable |
| operator.spec.js:48 | attribute | `data-selected="true"` on row | Low — attribute contract stable |
| operator.spec.js:49 | URL | `/ops/mail?` | Low — URL structure stable |
| operator.spec.js:50 | URL | `delivery_id=` query param | Low — query param name stable |
| operator.spec.js:52 | testid | `getByTestId("operator-detail-header")` | Low — detail header testid; stable |
| operator.spec.js:53 | copy-text | `operator-detail-header` contains `"browser-selected@example.com"` | Low — seeded fixture value; stable unless seeds renamed |
| operator.spec.js:54-56 | copy-text | `operator-detail-header` contains `"Replay is unavailable."` | Low — Phase 77 (motion) does not change copy strings |
| operator.spec.js:57 | testid | `getByTestId("operator-timeline")` | Low — timeline testid stable |
| operator.spec.js:58 | testid | `getByTestId("operator-suppression-card")` | Low — suppression card testid stable |
| operator.spec.js:59 | copy-text | `operator-suppression-card` contains `"ops:review"` | Low — suppression label from seeded fixture; stable |
| operator.spec.js:60 | testid | `getByTestId("operator-replay-open")` | Low — replay trigger testid stable |
| operator.spec.js:61 | element count | `getByRole("button", { name: /remove suppression/i })` has count 0 | Low — read-only mode invariant |

### test() 2: "mobile stacks list before detail and preserves detail section order" (line 64)

| spec_file:line | assertion kind | exact asserted string / value | ripple risk |
|---|---|---|---|
| operator.spec.js:65 | viewport | `{ width: 390, height: 844 }` | Low — viewport unchanged |
| operator.spec.js:68 | testid | `getByTestId("operator-deliveries-list-card")` | Low — stable |
| operator.spec.js:69 | testid | `getByTestId("operator-detail-column")` | Low — stable |
| operator.spec.js:72-76 | layout | `deliveriesCard.boundingBox()` y < `detailColumn.boundingBox()` y | Low — mobile-first stacking invariant unchanged |
| operator.spec.js:78 | testid (nth) | `operator-delivery-row` index 0 click | Phase 78 (SEED-02) — seed row order |
| operator.spec.js:80 | testid | `getByTestId("operator-detail-header")` boundingBox | Low — stable |
| operator.spec.js:81 | testid | `getByTestId("operator-timeline")` boundingBox | Low — stable |
| operator.spec.js:82 | testid | `getByTestId("operator-suppression-card")` boundingBox | Low — stable |
| operator.spec.js:85-88 | layout | header.y < timeline.y < suppression.y (section order invariant) | Low — DOM order invariant; stable unless Phase 76 restructures detail panel |

### test() 3: "exact replay flow shows ready copy and records a new-work outcome" (line 91)

| spec_file:line | assertion kind | exact asserted string / value | ripple risk |
|---|---|---|---|
| operator.spec.js:92 | viewport | `{ width: 1280, height: 900 }` | Low |
| operator.spec.js:95 | testid (nth) | `operator-delivery-row` index 3 | **Phase 78 (SEED-02)** — seed row index 3 is the "exact" replay row; if seed order changes this breaks |
| operator.spec.js:98 | copy-text | `operator-detail-header` contains `"browser-exact@example.com"` | Low — seeded fixture; stable unless renamed |
| operator.spec.js:99 | copy-text | `operator-detail-header` contains `"Replay is ready."` | Low — Phase 77 does not change copy |
| operator.spec.js:101 | testid | `getByTestId("operator-replay-open")` click | Low — replay trigger stable |
| operator.spec.js:103 | testid | `getByTestId("operator-replay-modal")` | Low — modal testid stable |
| operator.spec.js:104-108 | copy-text | modal contains `"Replay is ready."`, `"Confirm to replay that stored request."`, `"browser-exact-delivery"` | Low — Phase 77 motion-only; copy unchanged |
| operator.spec.js:109 | testid | `getByTestId("operator-replay-confirm")` click | Low — confirm button testid stable |
| operator.spec.js:111 | copy-text | `getByText("Replay completed with new work.")` visible | Low — flash message copy; stable |
| operator.spec.js:112-114 | copy-text | `operator-detail-header` contains `"Last replay: completed · new work"` | Low — status line copy; stable |
| operator.spec.js:115-117 | copy-text | `operator-timeline` contains `"Replay audit"`, `"completed"`, `"new work"` | Low — timeline event strings; stable |

### test() 4: "ambiguous replay flow requires an explicit choice before confirm is available" (line 120)

| spec_file:line | assertion kind | exact asserted string / value | ripple risk |
|---|---|---|---|
| operator.spec.js:121 | viewport | `{ width: 1280, height: 900 }` | Low |
| operator.spec.js:124 | testid (nth) | `operator-delivery-row` index 2 | **Phase 78 (SEED-02)** — seed row index 2 is the "ambiguous" replay row; seed reorder breaks this |
| operator.spec.js:126 | copy-text | `operator-detail-header` contains `"browser-ambiguous@example.com"` | Low — fixture stable |
| operator.spec.js:127-130 | copy-text | `operator-detail-header` contains `"Replay is choice required."` | Low — copy stable |
| operator.spec.js:132 | testid | `getByTestId("operator-replay-open")` click | Low |
| operator.spec.js:134 | testid | `getByTestId("operator-replay-modal")` visible | Low |
| operator.spec.js:135-143 | copy-text | modal contains `"Replay is choice required."`, `"The operator UI will not guess across multiple replayable webhook rows."`, `"browser-ambiguous-delivery-1"`, `"browser-ambiguous-delivery-2"` | Low — copy stable |
| operator.spec.js:144 | element count | `getByTestId("operator-replay-confirm")` has count 0 (before choice) | Low — UI state invariant |
| operator.spec.js:146 | interaction | `getByRole("radio", { name: /browser-ambiguous-delivery-2/i })` check | Low — fixture name stable |
| operator.spec.js:147 | testid | `getByTestId("operator-replay-confirm")` visible (after choice) | Low — UI state invariant |

### test() 5: "noop replay flow keeps no-change wording visible in the browser" (line 150)

| spec_file:line | assertion kind | exact asserted string / value | ripple risk |
|---|---|---|---|
| operator.spec.js:151 | viewport | `{ width: 1280, height: 900 }` | Low |
| operator.spec.js:154 | testid (nth) | `operator-delivery-row` index 1 | **Phase 78 (SEED-02)** — seed row index 1 is the "noop" replay row; seed reorder breaks this |
| operator.spec.js:156 | copy-text | `operator-detail-header` contains `"browser-noop@example.com"` | Low — fixture stable |
| operator.spec.js:157-159 | copy-text | `operator-detail-header` contains `"Replay is ready."` | Low |
| operator.spec.js:161 | testid | `getByTestId("operator-replay-open")` click | Low |
| operator.spec.js:161 | testid | `getByTestId("operator-replay-confirm")` click | Low |
| operator.spec.js:163 | copy-text | `getByText("Replay completed with no change.")` visible | Low — flash copy stable |
| operator.spec.js:164-166 | copy-text | `operator-detail-header` contains `"Last replay: completed · no change"` | Low |
| operator.spec.js:167-168 | copy-text | `operator-timeline` contains `"completed"`, `"no change"` | Low |

### operator.spec.js — Testid Summary (prior-baseline)

All testids used in operator.spec.js. Phase 75 adds new testids for the Operator Overview. This set is the prior-baseline so new additions are deliberate, not accidental:

| testid | used in test() blocks |
|---|---|
| `operator-deliveries-list` | openOperator helper (all 5 tests) |
| `operator-deliveries-list-card` | test 1, test 2 |
| `operator-detail-column` | test 1, test 2 |
| `operator-empty-detail` | test 1 |
| `operator-delivery-row` (nth) | openOperator + test 1 + test 2 + test 3 + test 4 + test 5 |
| `operator-detail-header` | test 1 + test 3 + test 4 + test 5 |
| `operator-timeline` | test 1 + test 2 + test 3 + test 5 |
| `operator-suppression-card` | test 1 + test 2 |
| `operator-replay-open` | test 3 + test 4 + test 5 |
| `operator-replay-modal` | test 3 + test 4 |
| `operator-replay-confirm` | test 3 + test 4 + test 5 |

**Testids NOT present in this baseline** (expected to be added by build phases):
- Any testid for the Operator Overview landing (Phase 75: `operator-overview-*`)
- Any testid for `orientation_strip` on Deliveries/Inbound/Preview (Phase 75)

---

## Section 2 — demo.spec.js Assertion Inventory

**File:** `reference/demo_app/assets/e2e/demo.spec.js`
**Describe block:** `"mailglass demo evidence"` (line 3)
**Total test() blocks:** 3

### test.beforeEach — Seed Reset Contract (lines 4-11)

| spec_file:line | assertion kind | exact asserted string / value | ripple risk |
|---|---|---|---|
| demo.spec.js:5 | seed-count / seed-reset | `POST /demo/evidence/reset` with header `x-mailglass-demo-reset-token` → `ok()` | **Phase 78 (SEED-02)** — this is the canonical seed-reset contract; any seed expansion in Phase 78 MUST keep this endpoint contract intact in the same commit; the endpoint response must remain `ok()` |

### test() 1: "dashboard links to preview and operator surfaces" (line 13)

| spec_file:line | assertion kind | exact asserted string / value | ripple risk |
|---|---|---|---|
| demo.spec.js:14 | navigation | goto `"/"` | Low |
| demo.spec.js:15 | heading | `getByRole("heading", { name: "Northstar Ops", exact: true })` | **HIGH — Phase 75 (IA-03)**: IA vocabulary pass could touch the demo dashboard heading; any heading rename breaks this assertion |
| demo.spec.js:16 | copy-text | `getByText("Deliveries", { exact: true })` visible | **HIGH — Phase 75 (IA-03)**: same as above; "Deliveries" text on the dashboard is a ripple candidate if IA vocabulary is updated |
| demo.spec.js:18 | link/nav | `getByRole("link", { name: /preview mailables/i })` click | Low — nav link label stable |
| demo.spec.js:19 | URL | `/dev/mail` | Low |
| demo.spec.js:20 | copy-text | `getByText("AccountMailer")` visible | **Phase 78 (SEED-02)** — depends on seeded mailable class name; stable unless seeds rename the mailer |

### test() 2: "outbound operator opens with seeded delivery evidence" (line 23)

| spec_file:line | assertion kind | exact asserted string / value | ripple risk |
|---|---|---|---|
| demo.spec.js:25 | navigation | goto `"/"` then click link | Low |
| demo.spec.js:26 | link/nav | `getByRole("link", { name: /outbound operator/i })` click | Low — nav link label stable |
| demo.spec.js:27 | URL | `/ops/mail?tenant_id=northstar` | Low — URL stable; `northstar` tenant ID is a seeded constant |
| demo.spec.js:28 | heading | `getByRole("heading", { name: "Deliveries", exact: true })` | **HIGH — Phase 75 (IA-03)**: same "Deliveries" heading ripple risk as operator.spec.js:19; both must be updated together if IA renames the surface |
| demo.spec.js:29 | testid | `getByTestId("operator-deliveries-list")` visible | Low — testid stable |
| demo.spec.js:31 | testid / seed-count | `getByTestId("operator-delivery-row").first()` must exist (implicit) | **Phase 78 (SEED-02)** — at least one seeded delivery row must exist post-reset; seed expansion must not break minimum-count invariant |
| demo.spec.js:31 | attribute | `operator-delivery-row.first()` getAttribute `"phx-value-id"` non-null | Phase 78 (SEED-02) — seed row must carry the `phx-value-id` attribute |
| demo.spec.js:32 | navigation | goto deep-link `/demo/login?return_to=/ops/mail?tenant_id=northstar&delivery_id={id}` | Low — deep-link auth path stable |
| demo.spec.js:34 | testid | `getByTestId("operator-detail-header")` visible | Low — testid stable |
| demo.spec.js:35 | testid | `getByTestId("operator-timeline")` visible | Low — testid stable |

### test() 3: "inbound operator opens with seeded support mailbox evidence" (line 37)

| spec_file:line | assertion kind | exact asserted string / value | ripple risk |
|---|---|---|---|
| demo.spec.js:39 | navigation | goto `"/"` then click link | Low |
| demo.spec.js:40 | link/nav | `getByRole("link", { name: /inbound operator/i })` click | Low — nav link label stable |
| demo.spec.js:41 | URL | `/ops/mail/inbound?tenant_id=northstar` | Low — URL stable |
| demo.spec.js:42 | heading | `getByRole("heading", { name: "Inbound records", exact: true })` | **HIGH — Phase 75 (IA-03)**: IA vocabulary pass may rename "Inbound records" to align with the Orientation Strip heading contract ("Inbound"); this is a direct ripple candidate |
| demo.spec.js:43 | testid | `getByTestId("inbound-records-list")` visible | Low — testid stable unless inbound list container is restructured |
| demo.spec.js:45 | testid / seed-count | `getByTestId("inbound-record-row").first()` must exist (implicit) | **Phase 78 (SEED-02)** — at least one seeded inbound row must exist post-reset; seed expansion must not break minimum-count invariant |
| demo.spec.js:45 | attribute | `inbound-record-row.first()` getAttribute `"phx-value-id"` non-null | Phase 78 (SEED-02) — seed row must carry the `phx-value-id` attribute |
| demo.spec.js:46 | navigation | goto deep-link `/demo/login?return_to=/ops/mail/inbound?tenant_id=northstar&inbound_id={id}` | Low — deep-link auth path stable |
| demo.spec.js:47 | testid | `getByTestId("inbound-detail-header")` visible | Low — testid stable |

### demo.spec.js — Testid Summary (prior-baseline)

| testid | used in test() blocks |
|---|---|
| `operator-deliveries-list` | test 2 |
| `operator-delivery-row` (first) | test 2 |
| `operator-detail-header` | test 2 |
| `operator-timeline` | test 2 |
| `inbound-records-list` | test 3 |
| `inbound-record-row` (first) | test 3 |
| `inbound-detail-header` | test 3 |

### Seed-Count Baseline Summary

The `beforeEach` seed-reset (`POST /demo/evidence/reset`) defines the structural invariants every test depends on. This is the Phase 78 change surface:

| Implicit count | What the test requires | Ripple rule for Phase 78 |
|---|---|---|
| Outbound delivery rows >= 1 | `operator-delivery-row.first()` must exist for deep-link test | Phase 78 SEED-02 changes seeds in the SAME commit as updating these assertions; never in a separate PR |
| Inbound record rows >= 1 | `inbound-record-row.first()` must exist for deep-link test | Same rule |
| "AccountMailer" mailable class visible | `getByText("AccountMailer")` in Preview after link click | Stable unless seeds rename the mailable |

---

## Section 3 — Before-Baseline PNG Path References

> **D-06 compliance:** PNG binaries are NEVER committed. They are gitignored reproducible
> evidence written under `tmp/ui-audit/` by `scripts/ui-audit.sh` (the extended version per
> D-07). The committed durable artifact is this path inventory only. Phase 79 re-runs the
> same script to the same paths for VERIF-01 before/after diff.

The extended `ui-audit.sh` writes screenshots under `tmp/ui-audit/` using the naming convention
`{surface}-{viewport}-{theme}.png`. The full before-baseline matrix (390/768/1440 x light/dark
x 3 surfaces = 18 paths) is:

### Preview Surface

| Path | Viewport | Theme |
|---|---|---|
| `tmp/ui-audit/preview-390-light.png` | 390px mobile | light |
| `tmp/ui-audit/preview-390-dark.png` | 390px mobile | dark |
| `tmp/ui-audit/preview-768-light.png` | 768px tablet | light |
| `tmp/ui-audit/preview-768-dark.png` | 768px tablet | dark |
| `tmp/ui-audit/preview-1440-light.png` | 1440px desktop | light |
| `tmp/ui-audit/preview-1440-dark.png` | 1440px desktop | dark |

### Deliveries / Outbound Operator Surface

| Path | Viewport | Theme |
|---|---|---|
| `tmp/ui-audit/deliveries-390-light.png` | 390px mobile | light |
| `tmp/ui-audit/deliveries-390-dark.png` | 390px mobile | dark |
| `tmp/ui-audit/deliveries-768-light.png` | 768px tablet | light |
| `tmp/ui-audit/deliveries-768-dark.png` | 768px tablet | dark |
| `tmp/ui-audit/deliveries-1440-light.png` | 1440px desktop | light |
| `tmp/ui-audit/deliveries-1440-dark.png` | 1440px desktop | dark |

### Inbound Operator Surface

| Path | Viewport | Theme |
|---|---|---|
| `tmp/ui-audit/inbound-390-light.png` | 390px mobile | light |
| `tmp/ui-audit/inbound-390-dark.png` | 390px mobile | dark |
| `tmp/ui-audit/inbound-768-light.png` | 768px tablet | light |
| `tmp/ui-audit/inbound-768-dark.png` | 768px tablet | dark |
| `tmp/ui-audit/inbound-1440-light.png` | 1440px desktop | light |
| `tmp/ui-audit/inbound-1440-dark.png` | 1440px desktop | dark |

**Total paths:** 18 (3 surfaces x 3 viewports x 2 themes)

**Gitignore contract:** `tmp/` is gitignored by `.gitignore` `/tmp/`. These files are reproducible
by running the extended `scripts/ui-audit.sh`. Phase 79 re-runs the same matrix to the same paths
and performs the VERIF-01 before/after diff using image-comparison tooling. The PNG binaries NEVER
appear in any commit, PR, or Hex package artifact.

---

## Ripple-Risk Summary

High-ripple assertions that build phases MUST update deliberately (not accidentally):

| Assertion | Source | Build phase | Update rule |
|---|---|---|---|
| `getByRole("heading", { name: "Deliveries", exact: true })` | operator.spec.js:19 (openOperator) + demo.spec.js:28 | Phase 75 (IA-03) | If heading text changes, update BOTH spec files in the same commit |
| `getByRole("heading", { name: "Northstar Ops", exact: true })` | demo.spec.js:15 | Phase 75 (IA-03) | Update demo.spec.js if dashboard heading changes |
| `getByText("Deliveries", { exact: true })` | demo.spec.js:16 | Phase 75 (IA-03) | Update if IA renames the Deliveries nav item on the demo dashboard |
| `getByRole("heading", { name: "Inbound records", exact: true })` | demo.spec.js:42 | Phase 75 (IA-03) | Orientation strip heading contract may rename to "Inbound"; update demo.spec.js |
| `getByTestId("operator-empty-detail")` | operator.spec.js:32/34 | Phase 75 (IA-03) | May be replaced by overview landing; update or remove |
| `operator-delivery-row` index 1, 2, 3 | operator.spec.js:154, 124, 95 | Phase 78 (SEED-02) | Seed reorder must update row indices in same commit |
| `POST /demo/evidence/reset` -> `ok()` | demo.spec.js:5 (beforeEach) | Phase 78 (SEED-02) | Reset endpoint contract must stay intact; any schema change updates this test in same commit |
| `operator-delivery-row.first()` exists | demo.spec.js:31 | Phase 78 (SEED-02) | Seed expansion must not drop outbound rows below 1 |
| `inbound-record-row.first()` exists | demo.spec.js:45 | Phase 78 (SEED-02) | Seed expansion must not drop inbound rows below 1 |
