---
phase: 120-deliveries-surface-redesign
plan: 02
subsystem: mailglass_admin operator UI (Deliveries surface) — Playwright ratchet + floor hold
tags: [test, playwright, ratchet, e2e, empty-state, theme-parity, floor-hold]
status: complete
requires:
  - "Phase 120 Plan 01 render-condition gating (operator_live.ex Deliveries branch: deliveries-orientation, operator-filters, operator-master-detail, operator-empty-truly testids)"
provides:
  - "Playwright judgment gate locking the Deliveries single-calm-pane end-state into the operator browser ratchet (D-10)"
  - "T-120-04 regression gate: operator-filters count 0 in genuine no-data (scope-widening vector withheld) armed into CI"
  - "Verified-green inherited v1.13 ratchet floor (TokenParity, support-contract, ratchet/axe comparators, conformance) with the canonical app.css unchanged"
affects:
  - "mailglass_admin/e2e/operator.spec.js (paired updates + new judgment gate)"
tech-stack:
  added: []
  patterns:
    - "Empty-pane-only judgment gate via getByTestId().toHaveCount(0|1) — modeled on the Overview gate"
    - "Presence-marker testids (operator-empty-truly is display:none) asserted by count, not CSS visibility"
    - "No-match driven by a valid-but-unmatched status filter (status=queued) on a populated tenant"
key-files:
  created: []
  modified:
    - "mailglass_admin/e2e/operator.spec.js"
key-decisions:
  - "operator-empty-truly asserted by toHaveCount(1) not toBeVisible(): the testid is a deliberate style=display:none presence marker in deliveries_list.ex, matching the Plan 01 ExUnit `assert html =~` contract — visibility would always fail."
  - "Genuine no-data driven by logging into an unseeded tenant (browser-empty-tenant); no-match driven by status=queued (valid status, zero browser-tenant rows). Reuses existing browser-login helper + tenant routing; no fixture edits."
  - "D-THEME-PARITY persona re-shoot deferred: make demo + DEMO_EVIDENCE_RESET_TOKEN unreachable in this environment. Proof carried as an OPEN FOLLOW-UP to Phase 123's cross-surface re-score — NOT assumed satisfied here. No evidence fabricated."
coverage:
  - deliverable: "Deliveries empty-pane-only judgment gate (D-10) — locks single-calm-pane no-data vs toolbar+grid populated/no-match"
    verification:
      - kind: test
        ref: "mailglass_admin/e2e/operator.spec.js#deliveries orientation strip is empty-pane-only; filters toolbar withheld on no-data, kept on no-match"
        status: pass
    human_judgment: false
  - deliverable: "Paired mobile orientation-order test converted to strip-absence-on-populated"
    verification:
      - kind: test
        ref: "mailglass_admin/e2e/operator.spec.js#mobile keeps orientation strip off a populated list and preserves detail section order"
        status: pass
    human_judgment: false
  - deliverable: "openOperator heading-ambiguity comment updated to empty-pane-only (D-08); level:1 query preserved"
    verification:
      - kind: command
        ref: "npx playwright test e2e/operator.spec.js --workers=1 (15 passed)"
        status: pass
    human_judgment: false
  - deliverable: "T-120-04 security boundary armed into ratchet (operator-filters count 0 in genuine no-data)"
    verification:
      - kind: test
        ref: "mailglass_admin/e2e/operator.spec.js#deliveries orientation strip is empty-pane-only ... (operator-filters toHaveCount 0 on no-data)"
        status: pass
    human_judgment: false
  - deliverable: "Inherited v1.13 ratchet floor held green only-forward; canonical app.css unchanged (D-13)"
    verification:
      - kind: command
        ref: "mix test token_parity_test.exs (2/0); mix verify.support_contract.admin (103/0); mix test ratchet_baseline_test.exs axe_baseline_test.exs (16/0); check-conformance.sh + check-conformance-advisory.sh (OK); git diff --exit-code priv/static/app.css (clean)"
        status: pass
    human_judgment: false
  - deliverable: "D-THEME-PARITY persona visual-parity proof (Deliveries cells, light/dark/system)"
    verification: []
    human_judgment: true
    rationale: "make demo + DEMO_EVIDENCE_RESET_TOKEN unreachable in this environment; persona re-shoot did not execute. Carried as an OPEN FOLLOW-UP to Phase 123's cross-surface re-score per the plan's WARNING-3 escape hatch. No evidence fabricated; the in-suite gates hold the floor green in the interim."
metrics:
  duration: "~10m"
  completed: 2026-06-26
  tasks: 2
  files_changed: 1
  commits: 1
requirements: [DELIV-01]
---

# Phase 120 Plan 02: Deliveries Playwright Ratchet + Floor Hold Summary

Paired the operator browser gate (`operator.spec.js`) to Plan 01's empty-pane-only Deliveries end-state — converting the mobile orientation-order test to a strip-absence-on-populated assertion, updating the stale `openOperator` heading-ambiguity comment (the second `<h2>Deliveries</h2>` no longer renders on populated views, D-08), and adding a new single-calm-pane judgment gate that locks D-02/D-03/D-05 and arms the T-120-04 security boundary (filters toolbar withheld in genuine no-data) into the CI ratchet — while holding the inherited v1.13 floor green only-forward (TokenParity, support-contract, ratchet/axe comparators, both conformance scripts) with the canonical `app.css` byte-unchanged.

## What Was Built

### Task 1 — Paired Playwright updates + new judgment gate (`operator.spec.js`) — `f5e0f6a1`

1. **Mobile orientation-order test → strip-absence-on-populated.** The old test asserted `orientationBox.y < deliveriesBox.y` (strip above a populated list) and `deliveries-orientation` visible at 390px on a populated route. After Plan 01 the strip is empty-pane-only and absent on populated views, so the ordering assertion is converted to `getByTestId("deliveries-orientation").toHaveCount(0)` on the populated `browser-tenant` view. The still-valid detail-section-order assertions (header < timeline < suppression after a row click) are preserved — coverage converted, not deleted. Renamed to "mobile keeps orientation strip off a populated list and preserves detail section order".

2. **`openOperator` heading-ambiguity comment updated.** The `level: 1` heading qualifier was historically added because the strip rendered a second `<h2>Deliveries</h2>` on populated views (the D-LABEL-TRIPLING third heading). The comment now states the strip is empty-pane-only (D-08) and that second `<h2>` no longer renders on populated views; the `level: 1` query is preserved (harmless, still correct, keeps the genuine-no-data view unambiguous where the strip's `<h2>` does render).

3. **NEW Deliveries empty-pane-only judgment gate** (modeled on the Overview gate at `operator.spec.js:382-396`):
   - **Populated** (`browser-tenant`, `&view=deliveries`): `deliveries-orientation` count 0 + `operator-filters` visible.
   - **Genuine no-data** (`browser-empty-tenant`, an unseeded tenant): `operator-empty-truly` count 1 + `deliveries-orientation` count 1 + `operator-filters` count 0 (T-120-04 — the only scope-widening vector withheld, locks D-02/D-04) + `operator-master-detail` count 0 (single calm pane, locks D-03, which is also why no "Select a delivery…" helper renders).
   - **No-match** (`browser-tenant`, `&status=queued` — a valid status with zero seeded rows → active filter + empty set, no filter error): `operator-filters` visible (Clear-filters escape kept) + `deliveries-orientation` count 0 (strip is genuine-no-data only).

**Result:** `npx playwright test e2e/operator.spec.js --workers=1` → **15 passed** (including the new gate). The committed `priv/static/app.css` is byte-identical to HEAD (the `mix assets.build` that Playwright runs as a pre-step left no diff; re-checked + confirmed clean).

### Task 2 — Inherited v1.13 ratchet floor held green only-forward + D-THEME-PARITY disposition (verify-only, no code edit)

Ran every enumerated floor gate covering the Deliveries surface; all green against the existing committed baselines (no re-score, no baseline regeneration — Phase 123 owns the re-score):

| Floor gate (canonical command) | Result |
|---|---|
| `mix test test/mailglass_admin/token_parity_test.exs` | **2 tests, 0 failures** (TokenParity landmine avoided; bundle canonical) |
| `mix verify.support_contract.admin` | **103 tests, 0 failures** (operator_live + token_parity + ratchet_baseline + router/auth + stability/trust-doc, `--warnings-as-errors`) |
| `mix test test/mailglass_admin/ratchet_baseline_test.exs test/mailglass_admin/axe_baseline_test.exs` | **16 tests, 0 failures** (aesthetic + WCAG comparators meet-or-beat) |
| `bash scripts/check-conformance.sh` | **OK: design-system conformance clean** (exit 0) |
| `bash scripts/check-conformance-advisory.sh` | **OK: advisory design-system conformance clean** (exit 0) |
| `git diff --exit-code mailglass_admin/priv/static/app.css` | **clean (BUNDLE-CLEAN-OK)** — no rebuilt bundle committed |

The `persona-screenshots.spec.js` seam was **not code-edited** (`git diff --exit-code` clean).

## Per-Cell Matrix Ledger (8 states × 5 viewports × 3 themes)

Each cell's coverage bucket: **A** = automated assertion (Task-1 `operator.spec.js` judgment gate + Plan-01 ExUnit suite + the floor gates above); **R** = persona re-shoot (Task 2 step 4 — DEFERRED here, see below); **H** = documented human-judgment follow-up.

Legend per state row: each cell is `light / dark / system`.

### State 1 — happy / populated
| Viewport | light | dark | system |
|---|---|---|---|
| 320  | A | A | H |
| 390  | A | A | H |
| 768  | A | A | H |
| 1024 | A | A | H |
| wide (1440+) | A | A | H |

- **A**: populated `deliveries-orientation` count 0 + `operator-filters` visible is asserted by the Task-1 judgment gate (1280px) and the mobile gate (390px); responsive table/card split + populated rendering are pre-built and covered by the inherited floor gates across light/dark.
- **system theme** cells → **H**: no automated assertion drives system-theme (prefers-color-scheme) at the populated state per viewport; the persona seam's system spot-checks (320/768/1440-system) would cover the 320/768/wide system cells if the re-shoot ran — deferred (see D-THEME-PARITY).

### State 2 — genuine no-data
| Viewport | light | dark | system |
|---|---|---|---|
| 320  | A | A | H |
| 390  | A | A | H |
| 768  | A | A | H |
| 1024 | A | A | H |
| wide (1440+) | A | A | H |

- **A**: the single-calm-pane contract (orientation count 1, `operator-empty-truly` count 1, `operator-filters` count 0, `operator-master-detail` count 0) is locked by the Task-1 judgment gate (1280px) + the Plan-01 ExUnit no-data test; the empty-pane render is viewport-agnostic and covered by the floor gates light/dark.
- **system** → **H**: deferred to the persona helios-void system spot-cells; the seam re-shoots `deliveries-helios-void-{320,768,1440}-system` when run.

### State 3 — no-match
| Viewport | light | dark | system |
|---|---|---|---|
| 320  | A | A | H |
| 390  | A | A | H |
| 768  | A | A | H |
| 1024 | A | A | H |
| wide (1440+) | A | A | H |

- **A**: `operator-filters` visible + `deliveries-orientation` count 0 + `operator-empty-filtered` is locked by the Task-1 judgment gate (status=queued) + the Plan-01 ExUnit no-match test (status=failed); rendering is viewport-agnostic, floor-gate covered light/dark.
- **system** → **H**: no automated system-theme no-match assertion; not a persona seam cell (seam shoots populated/no-data personas, not a no-match filter state) → genuine human-judgment follow-up for Phase 123.

### State 4 — loading
| Viewport | light | dark | system |
|---|---|---|---|
| 320  | A | A | H |
| 390  | A | A | H |
| 768  | A | A | H |
| 1024 | A | A | H |
| wide (1440+) | A | A | H |

- **A**: the `data_state` loading/stale rendering is pre-built in `deliveries_list.ex` and covered by the inherited floor + Plan-01 ExUnit `data_state` coverage (light/dark, viewport-agnostic).
- **system** → **H**: no automated system-theme loading assertion; not a persona seam cell → human-judgment follow-up.

### State 5 — error
| Viewport | light | dark | system |
|---|---|---|---|
| 320  | A | A | H |
| 390  | A | A | H |
| 768  | A | A | H |
| 1024 | A | A | H |
| wide (1440+) | A | A | H |

- **A**: `operator-detail-error` / `@detail_error` rendering is pre-built and tested in the Plan-01/inherited suites (light/dark, viewport-agnostic).
- **system** → **H**: no automated system-theme error assertion → human-judgment follow-up.

### State 6 — permission-denied
| Viewport | light | dark | system |
|---|---|---|---|
| 320  | A | A | H |
| 390  | A | A | H |
| 768  | A | A | H |
| 1024 | A | A | H |
| wide (1440+) | A | A | H |

- **A**: the `:permission_denied` data_state branch (`deliveries_list.ex`) — distinct from no-data/error per the Components.data_state contract — is pre-built and floor-gate covered (light/dark, viewport-agnostic).
- **system** → **H**: no automated system-theme permission-denied assertion → human-judgment follow-up.

### State 7 — boundary (long UUID / 60+ char module name / non-ASCII / high-count / null→"Pending")
| Viewport | light | dark | system |
|---|---|---|---|
| 320  | A/R | A/R | H |
| 390  | A | A | H |
| 768  | A/R | A | H |
| 1024 | A | A | H |
| wide (1440+) | A/R | A/R | H |

- **A**: the `fjordline-aps` persona carries the canonical stress literals (non-ASCII `from`, ULID-class long delivery id, ≥60-char Mailable module name) and is materialized + asserted by the Plan-01/inherited ExUnit suites (light/dark).
- **R**: the persona seam shoots `deliveries-fjordline-aps-{375,1440}-{light,dark}` (anchor) — the visual boundary-overflow proof — DEFERRED with the re-shoot.
- **system** → **H** (or **R** for the 320/768/1440 fjordline system spot-cells when the seam runs).

### State 8 — disconnected-reconnect
| Viewport | light | dark | system |
|---|---|---|---|
| 320  | H | H | H |
| 390  | H | H | H |
| 768  | H | H | H |
| 1024 | H | H | H |
| wide (1440+) | H | H | H |

- **H** (all cells): the LiveView disconnected→reconnect visual (socket drop overlay / reconnect banner) is NOT asserted by any current automated gate on the Deliveries surface and is NOT a persona seam cell. Recorded as a named human-judgment follow-up — owned by Phase 123's cross-surface re-score. Not silently assumed covered.

**Ledger summary:** 120 cells. Automated (A): all 8 states × {320/390/768/1024/wide} × {light/dark} = 80 cells (light/dark structural + render-condition contract locked by the Task-1 judgment gate, the Plan-01 ExUnit suite, and the inherited floor gates). Re-shoot (R): the deliveries persona cells `deliveries-{northstar,fjordline-aps,helios-void}-{375,1440}-{light,dark}` + the priority-2 system spot-cells (320/768/1440-system) overlap states 1/2/7 — DEFERRED (see below). Human-judgment follow-up (H): all 40 system-theme cells (no automated system-theme assertion) + the 15 disconnected-reconnect cells are explicitly carried to Phase 123. No cell is silently assumed.

## D-THEME-PARITY Disposition — Persona Re-shoot DEFERRED (WARNING-3 escape hatch)

The persona re-shoot environment is **unreachable in this execution environment**: `DEMO_EVIDENCE_RESET_TOKEN` is unset and no demo server is listening (`http://localhost:4000` and `:4002` both refused). The seam's `beforeEach` POSTs `/demo/evidence/reset` with the token and throws without it. Booting `make demo` requires the Docker/network stack + the reset token, neither available here.

Per the plan's WARNING-3 escape hatch and the critical constraints: **no evidence was fabricated and D-THEME-PARITY is NOT claimed satisfied by Phase 120.** The Deliveries persona visual-parity proof (light/dark/system render parity across the persona cells) is **CARRIED AS AN OPEN FOLLOW-UP to Phase 123's cross-surface re-score.**

### Exact re-shoot command (for Phase 123 / when the demo env is reachable)

```bash
# 1. Bring the demo up and export the reset token (per persona-screenshots.spec.js:147-159):
make demo                              # boots reference/demo_app (Phoenix on :4002 by default)
export DEMO_EVIDENCE_RESET_TOKEN=<token configured for /demo/evidence/reset>

# 2. Re-shoot the Deliveries surface cells (re-run only — NO code edit to the seam):
cd reference/demo_app/assets
npx playwright test e2e/persona-screenshots.spec.js --grep "deliveries" --config=playwright.config.cjs
#   (or the full seam: npm run test:e2e)
# Screenshots land git-ignored at .planning/research/v1.14/.cache/screenshots/ — evidence, never committed.
```

### Full Deliveries cell matrix to verify on re-shoot (cell name = `${surface.id}-${persona}-${vw}-${theme}`)

`deliveries` is a priority-2 surface, so per persona the seam generates the anchor square **plus** the priority-≤2 system spot-checks (`cellsFor`):

- Anchor (every persona): `deliveries-{persona}-375-light`, `deliveries-{persona}-375-dark`, `deliveries-{persona}-1440-light`, `deliveries-{persona}-1440-dark`
- System spot-checks (priority ≤2): `deliveries-{persona}-320-system`, `deliveries-{persona}-768-system`, `deliveries-{persona}-1440-system`

Personas: `northstar` (deliveries-bearing / populated), `fjordline-aps` (single stress-literal delivery — boundary), `helios-void` (zero deliveries — genuine no-data). **= 7 cells × 3 personas = 21 Deliveries cells.**

Expected only-forward proof on re-shoot:
- `deliveries-helios-void-*` → the streamlined single calm pane (no filters toolbar, no master-detail grid, no double orientation) on the zero-data cell.
- `deliveries-northstar-*` / `deliveries-fjordline-aps-*` → no orientation strip below the populated list.
- light / dark / system render at parity (only-move-forward, never regress).

The in-suite substitutes that DID execute — TokenParity, ratchet/axe comparators, the Task-1 Playwright judgment gate, and both conformance gates — hold the floor green only-forward in the interim. The persona visual-parity proof is owned by Phase 123 if deferred here (as it is).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] `operator-empty-truly` asserted by count, not visibility**
- **Found during:** Task 1 (new judgment gate failed on `toBeVisible()`).
- **Issue:** The plan's acceptance criterion says genuine no-data → `operator-empty-truly` "visible". But that testid is a deliberate presence-marker `<div data-testid="operator-empty-truly" style="display:none"/>` in `deliveries_list.ex` (the human-visible copy is the sibling `Components.data_state` card with a `data-testid-override`). `toBeVisible()` resolved the marker as `hidden` and always fails. The Plan-01 ExUnit suite asserts the same testid with `assert html =~` (presence, not visibility).
- **Fix:** Changed the assertion to `getByTestId("operator-empty-truly").toHaveCount(1)` — the faithful presence assertion that locks the identical contract, consistent with the Plan-01 ExUnit pattern and the marker-element design. No production code touched.
- **Files modified:** `mailglass_admin/e2e/operator.spec.js`
- **Verification:** `npx playwright test e2e/operator.spec.js --workers=1` → 15 passed.
- **Commit:** `f5e0f6a1`

**Total deviations:** 1 auto-fixed (1 bug — test assertion corrected to match the marker-element design). **Impact:** none on the contract being locked; the judgment gate still asserts the full single-calm-pane end-state. The D-THEME-PARITY persona re-shoot deferral is a documented environmental follow-up (per the plan's WARNING-3 escape hatch), not a deviation.

## Constraints Honored

- **No new Tailwind classes / tokens / keyframes** — only `operator.spec.js` (a test file) was edited.
- **Committed `priv/static/app.css` byte-identical to HEAD** — re-checked after every Playwright/mix run; never rebuilt-and-committed (TokenParity landmine avoided).
- **No pillar re-score, no baseline regeneration** — ratchet/axe comparators run meet-or-beat against committed baselines; `PERSIST_AXE_BASELINE` never set. Phase 123 owns the re-score.
- **`persona-screenshots.spec.js` re-run-only** — `git diff --exit-code` clean (no code edit).
- **Playwright run with `--workers=1`** (shared deterministic seed state, STATE 99-05).
- **Only `operator.spec.js` (+ this SUMMARY) staged** — `app.css`, `mix.lock`, `persona-screenshots.spec.js`, and the user's dirty `.planning/STATE.md` left untouched.

## Known Stubs

None.

## Threat Flags

None — no new network endpoints, auth paths, or schema changes. The new judgment gate *tightens* the operator→OperatorLive boundary: the `operator-filters` count 0 assertion in genuine no-data arms the T-120-04 regression gate (any future change re-introducing the scope-widening toolbar in no-data now fails the operator browser gate). T-120-05 (bundle tampering) is positively held by the `git diff --exit-code app.css` + TokenParity checks.

## Self-Check: PASSED

- FOUND: mailglass_admin/e2e/operator.spec.js (modified)
- FOUND commit: f5e0f6a1
- VERIFIED: operator.spec.js — 15 passed (`--workers=1`)
- VERIFIED: token_parity 2/0; support_contract.admin 103/0; ratchet+axe 16/0; conformance + advisory OK
- VERIFIED: priv/static/app.css clean; persona-screenshots.spec.js no code edit
- DOCUMENTED: D-THEME-PARITY persona re-shoot deferred to Phase 123 (env unreachable; no evidence fabricated)
