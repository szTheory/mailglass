# Phase 79: Verification and Visual-Regression Hardening — Pattern Map

**Mapped:** 2026-06-04
**Files analyzed:** 8 new/modified files
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `mailglass_admin/scripts/check-conformance.sh` | new-script | batch (grep-and-exit) | `scripts/check_motion_conformance.sh` | exact |
| `.planning/phases/79-.../79-GAP-CLOSEOUT.md` | evidence-doc | — | `75-03-SUMMARY.md` Gap Register Coverage table + `73-01-RELEASE-RECORD.md` structure | role-match |
| `mailglass_admin/e2e/operator.spec.js` | test-mod | request-response (Playwright DOM) | itself (extend in-place) | exact |
| `mailglass_admin/docs/design-system.md` | doc-mod | — | itself lines 123–139 (audit loop section) | exact |
| `mailglass_inbound/mix.exs` | config-mod | — | itself line 116 (exact-pin) | exact |
| `.release-please-manifest.json` | config-mod | — | itself (current 1.4.5/1.4.5/1.1.5) | exact |
| `release-please-config.json` | config-mod | — | itself (linked-versions plugin) | exact |
| `mailglass_admin/CHANGELOG.md` + core + inbound CHANGELOGs | doc-mod | — | `mailglass_admin/CHANGELOG.md` (admin sync pattern) | exact |

---

## Pattern Assignments

### `mailglass_admin/scripts/check-conformance.sh` (new-script, batch)

**Analog:** `scripts/check_motion_conformance.sh` (full file, 39 lines)

**Full analog to copy from** (`scripts/check_motion_conformance.sh`, lines 1–39):

```bash
#!/usr/bin/env bash
# Fail CI if any banned motion CSS token appears in mailglass_admin/lib/ or app.css.
# ...
set -euo pipefail

LIB="mailglass_admin/lib"
CSS="mailglass_admin/assets/css/app.css"
errors=0

# Pass A: layout-thrashing + duration tokens
THRASH_PATTERN='transition-height|transition-max-height|...'
if grep -rE "$THRASH_PATTERN" "$LIB" "$CSS" 2>/dev/null; then
  echo "FAIL: banned layout-thrashing or duration token found (see above)" >&2
  errors=$((errors + 1))
fi

# Pass B: banned easing classes — lib/ ONLY.
EASE_PATTERN='ease-in-out|ease-linear|ease-in[^-]'
if grep -rE "$EASE_PATTERN" "$LIB" 2>/dev/null; then
  echo "FAIL: banned easing class found in lib/ (see above)" >&2
  errors=$((errors + 1))
fi

if [[ $errors -gt 0 ]]; then
  echo "FAIL: motion conformance violations found (see above)" >&2
  exit 1
fi

echo "OK: motion conformance clean."
```

**Structural invariants to preserve exactly:**
- Shebang: `#!/usr/bin/env bash`
- `set -euo pipefail` on line 2 after comment block
- Variable names: `LIB="mailglass_admin/lib"` (no trailing slash), `errors=0`
- On-failure branch: print matches (no `--quiet`), echo `FAIL:` label to stderr, `errors=$((errors + 1))`
- Final block: `if [[ $errors -gt 0 ]]; then ... exit 1; fi`
- Success: `echo "OK: <gate-name> clean."`
- Exit codes: 0 = all clean, 1 = any violation

**Five gates to implement** (from `76-06-SUMMARY.md` lines 70–76 — gate names match the SUMMARY labels):

```bash
LIB="mailglass_admin/lib"
errors=0

# BADGE-GATE: defp badge_class must be zero (single canonical status→color definition)
if grep -rE 'defp badge_class' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: BADGE-GATE — defp badge_class found; route through Components.status_badge/1" >&2
  errors=$((errors + 1))
fi

# TYPE-GATE: raw type-scale utilities (text-sm, text-base, text-xs) — excluding text-base-content
# text-base-content is a DaisyUI semantic color token (Footgun-6 false positive)
if grep -rE 'text-(sm|base|xs)' "$LIB" --include="*.ex" 2>/dev/null | grep -v 'text-base-content'; then
  echo "FAIL: TYPE-GATE — raw text-scale utility found (use text-label/body/heading/display)" >&2
  errors=$((errors + 1))
fi

# BOLD-GATE: faux-bold tokens
if grep -rE 'font-(medium|semibold)' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: BOLD-GATE — faux-bold token found (use font-bold or default only)" >&2
  errors=$((errors + 1))
fi

# GAP-GATE: off-grid spacing tokens
if grep -rE 'gap-(3|4|6)' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: GAP-GATE — off-grid gap token found (use gap-sm/md/lg)" >&2
  errors=$((errors + 1))
fi

# HEX-GATE: hard-coded hex colors in HEEx
if grep -rE '#[0-9a-fA-F]{3,6}' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "FAIL: HEX-GATE — hard-coded hex color found (use semantic tokens)" >&2
  errors=$((errors + 1))
fi

if [[ $errors -gt 0 ]]; then
  echo "FAIL: conformance violations found ($errors gate(s) failed)" >&2
  exit 1
fi

echo "OK: design-system conformance clean."
```

**Key false-positive exclusion** (Pitfall 3 from RESEARCH.md): The `text-(sm|base|xs)` pattern matches the string `text-base-content` (a valid DaisyUI semantic color class). The exclusion `| grep -v 'text-base-content'` is mandatory. Without it, every file using `text-base-content` produces a false failure.

**Note on `--include="*.ex"` scope:** All five gates scope to `mailglass_admin/lib/` with `--include="*.ex"`. This matches HEEx template content embedded in `.ex` LiveView files (not `.heex` partials, which don't exist in this codebase).

---

### `.planning/phases/79-verification-and-visual-regression-hardening/79-GAP-CLOSEOUT.md` (evidence-doc)

**Analog 1 (Gap Register Coverage table structure):** `75-03-SUMMARY.md` lines 191–198

```markdown
## Gap Register Coverage

| Gap | Description | Status |
|-----|-------------|--------|
| GAP-07 | Deliveries 390px orientation readability | CLOSED — 390px Playwright test asserts deliveries-orientation visible |
| GAP-21 | a11y h1/h2 hierarchy on Overview | CLOSED — single h1 "Operator overview", h2 for Health and Navigate sections |
| GAP-22 | Deep-link unstyled CSS disposition | RECORDED — deferred to Phase 79 (VERIF-04) at severity 3 (IA-04 satisfied) |
```

**Analog 2 (separate evidence-artifact precedent):** `73-01-RELEASE-RECORD.md` — Phase 73 used a standalone artifact file (not editing the Phase 73 checklist) to record post-publish evidence. Phase 79 mirrors this with `79-GAP-CLOSEOUT.md` as the write target while `74-GAP-REGISTER.md` remains frozen/read-only.

**Row schema to carry forward** (from `74-GAP-REGISTER.md` lines 26–34):

| Column | Description |
|--------|-------------|
| `GAP-NN` | Stable ID — matches the frozen register exactly |
| `surface` | Deliveries / Inbound / Preview / Operator Overview / All |
| `description` | Short description matching the register row |
| `sev` | Original severity (from register) |
| `resolving-phase` | Phase that performed the fix |
| `resolving-commit(s)` | Git SHA(s) from the SUMMARY evidence |
| `evidence-path` | SUMMARY file path confirming closure |
| `phase-79-disposition` | `CLOSED` / `DEFERRED — <rationale>` |

**Evidence map for the five sev-4 rows** (from RESEARCH.md Area 2):

| GAP | Resolving Phase | Commits | Evidence Source |
|-----|----------------|---------|-----------------|
| GAP-01 | 76-02 | `8a4e22c4`, `3f573b75` | `.planning/phases/76-component-library-and-design-system-hardening/76-02-SUMMARY.md` |
| GAP-03 | 76-02 | `8a4e22c4`, `3f573b75` | same 76-02-SUMMARY.md |
| GAP-05 | 76-02 | `3f573b75` | same 76-02-SUMMARY.md |
| GAP-06 | 76-02 | `3f573b75` | same 76-02-SUMMARY.md |
| GAP-13 | 76-03 (restructure) + 78-01 (seeds) | `08c4b403`, `ca9c393a` (76-03) + `074b0cde` (78-01) | `76-03-SUMMARY.md` + `78-01-SUMMARY.md` |

**GAP-22 deferred block** (from `mailglass_admin/docs/design-system.md` lines 152–159):
```
GAP-22 disposition (Phase 75 / IA-04): deferred to Phase 79 (VERIF-04).
Rationale: A robust fix touches the stable asset-serving seam (the relative
css-<md5> URL resolves against the deep path on hard refresh, not the mount root).
This seam is out of churn scope for v1.7. Bug affects only hard refreshes on deep
URLs; normal in-app live navigation is unaffected. GAP-22 held at severity 3.
Phase 79 reconfirms this deferral as the permanent v1.7 disposition.
```

---

### `mailglass_admin/e2e/operator.spec.js` (test-mod, Playwright DOM)

**Analog:** itself — extend in-place following existing patterns throughout the file.

**`deliveryRow()` helper** (lines 9–11 — use this for all row selections):
```javascript
function deliveryRow(page, index) {
  return page.getByTestId("operator-delivery-row").nth(index);
}
```

**`openOperator()` helper** (lines 13–30 — call this at the top of every new test):
```javascript
async function openOperator(page) {
  const resetResponse = await page.request.get("/ops/browser-reset");
  expect(resetResponse.ok()).toBeTruthy();
  const returnTo = encodeURIComponent(`/ops/mail?tenant_id=${tenantId}`);
  await page.goto(`/ops/browser-login?tenant_id=${tenantId}&return_to=${returnTo}`);
  await expect(page.getByRole("heading", { name: "Operator overview", exact: true })).toBeVisible();
  await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries`);
  await expect(
    page.getByRole("heading", { name: "Deliveries", exact: true, level: 1 })
  ).toBeVisible();
  await expect(page.getByTestId("operator-deliveries-list")).toBeVisible();
}
```

**Existing `deliveries-orientation` assertion pattern** (lines 99–101 — mirror for `inbound-orientation` and `preview-orientation`):
```javascript
// Acceptance check for GAP-07 at 390px: orientation strip must be visible
await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries`);
await expect(page.getByTestId("deliveries-orientation")).toBeVisible();
```

**testid source** (from `operator/shell.ex:320`): The pattern `data-testid={"#{@surface}-orientation"}` produces:
- `deliveries-orientation` (surface `:deliveries`)
- `inbound-orientation` (surface `:inbound`)
- `preview-orientation` (surface `:preview`)

**New tests to add — testids from `operator_live.ex` lines 280–328:**
```javascript
// For Operator Overview structural coverage (D-05):
await expect(page.getByTestId("operator-overview")).toBeVisible();
await expect(page.getByTestId("operator-overview-health")).toBeVisible();
// Sub-testids (at least one must render; exact set depends on seed state):
// operator-overview-health-failures (line 290)
// operator-overview-health-orphans  (line 299)
// operator-overview-health-suppressions (line 308)
// operator-overview-health-allclear (line 317)
await expect(page.getByTestId("operator-overview-nav")).toBeVisible();
```

**Inbound surface navigation pattern** (lines 248–260 — mirror for inbound-orientation):
```javascript
await page.goto(`/ops/mail/inbound?tenant_id=${tenantId}`);
// then assert inbound-specific testids
```

**Replay-flow test — failing section** (lines 104–131, currently failing at line 128):
```javascript
test("exact replay flow shows ready copy and records a new-work outcome", async ({ page }) => {
  await page.setViewportSize({ width: 1280, height: 900 });
  await openOperator(page);

  const exactRow = deliveryRow(page, 3);  // index may need correction to 1
  await exactRow.click();
  await expect(page.getByTestId("operator-detail-header")).toContainText(exactRecipient);
  // ...
  await page.getByTestId("operator-replay-confirm").click();
  await expect(page.getByText("Replay completed with new work.")).toBeVisible();
  await expect(page.getByTestId("operator-detail-header")).toContainText(
    "Last replay: completed · new work"
  );
  // LINE 128 — currently fails; needs extended timeout or stable anchor:
  await expect(page.getByTestId("operator-timeline")).toContainText("Replay audit");
  await expect(page.getByTestId("operator-timeline")).toContainText("completed");
  await expect(page.getByTestId("operator-timeline")).toContainText("new work");
});
```

**Fix approach** (from RESEARCH.md Area 3):
1. Change `deliveryRow(page, 3)` to `deliveryRow(page, 1)` to anchor to `browser-exact@example.com` (confirmed by sort order: `desc: last_event_at, desc: inserted_at, desc: id`; `browser-exact` is at index 1 post Phase-78 seed expansion)
2. Add extended timeout to the `operator-timeline` assertion at line 128: `{ timeout: 10000 }` — this handles the Playwright async LiveView re-render race

**Structural test skeleton to follow** (from inbound detail test, lines 246–261):
```javascript
test("inbound detail pane carries record-keyed id", async ({ page }) => {
  await page.setViewportSize({ width: 1280, height: 900 });
  await openOperator(page);
  await page.goto(`/ops/mail/inbound?tenant_id=${tenantId}`);
  await page.getByTestId("inbound-record-row").nth(0).click();
  await expect(page).toHaveURL(/inbound_id=/);
  const inboundId = new URL(page.url()).searchParams.get("inbound_id");
  expect(inboundId).toBeTruthy();
  await expect(page.locator(`#inbound-detail-${inboundId}`)).toBeVisible();
});
```

---

### `mailglass_admin/docs/design-system.md` (doc-mod, audit loop section)

**Analog:** itself lines 123–139 — expand in-place following existing voice and format.

**Existing prose to extend** (lines 123–139):
```markdown
## Visual audit loop

Matrix: **screen × theme (light/dark) × viewport (390/768/1440) × state
(default / row-selected / modal-open / reduced-motion)**.

- **Ad-hoc (agent-browser):** `scripts/ui-audit.sh` boots the reference demo,
  walks the screens, and writes screenshots to the gitignored `tmp/ui-audit/`
  (never `priv/static/` — must not trip the bundle gate). Review the PNGs (or
  hand them to a multimodal model with this checklist as the rubric: accent
  overuse? faux-bold? non-flat shadow? off-grid spacing? contrast ≥ 4.5:1?).
- **CI regression net (Playwright):** `e2e/operator.spec.js` is the committed
  gate. Because relative asset URLs leave direct loads unstyled (see below), the
  e2e asserts structure/order/`data-testid`/text — not pixels.

State is URL-driven on every screen, so any state is reproducible by URL
(`?tenant_id=…&delivery_id=…&theme=dark`) — the audit script relies on this
rather than on driving clicks.
```

**What D-02 requires:** Expand the multimodal-model hint (currently at "hand them to a multimodal model with this checklist as the rubric") to make the **before/after LLM-critique comparison ritual explicit**:
- How to compare against the Phase 74 baseline (reference the Phase 74 baseline description, not committed PNGs)
- Which GAP rows the before/after comparison should show as improved
- The comparison rubric (the 6-pillar checklist already present above this section)

Voice match: "thoughtful maintainer" — specific and composed, not fluffy. Match the existing bullet-point structure and imperative tone ("Review the PNGs... hand them to a multimodal model..."). Do not introduce new tooling or script references. Prose only.

---

### `mailglass_inbound/mix.exs` (config-mod, exact-pin)

**Analog:** itself — targeted single-line edit only.

**Current state** (`mailglass_inbound/mix.exs` lines 114–119):
```elixir
defp mailglass_dep do
  if System.get_env("MIX_PUBLISH") == "true" do
    {:mailglass, "== 1.4.5"}
  else
    {:mailglass, path: "..", override: true}
  end
```

**Required edit:** Change `"== 1.4.5"` to `"== 1.5.0"` on line 116. The `path:` dev branch is untouched. This is the inbound exact-pin re-pin that triggers the `mailglass_inbound` 1.1.5 → 1.1.6 patch bump via Release Please.

---

### `.release-please-manifest.json` (config-mod)

**Analog:** itself — Release Please owns all version-number edits; this file is managed by the pipeline, not hand-edited. Phase 79 does NOT edit this file manually. It is shown here so the planner records the pre-Phase-79 state for traceability.

**Current state** (full file, 5 lines):
```json
{
  ".": "1.4.5",
  "mailglass_admin": "1.4.5",
  "mailglass_inbound": "1.1.5"
}
```

**Post-pipeline target** (Release Please will write this automatically when its PR lands):
```json
{
  ".": "1.5.0",
  "mailglass_admin": "1.5.0",
  "mailglass_inbound": "1.1.6"
}
```

---

### `release-please-config.json` (config-mod)

**Analog:** itself — read-only for Phase 79. No changes needed. Shown for planner reference.

**Current state** (key lines):
```json
{
  "plugins": [
    {
      "type": "linked-versions",
      "groupName": "mailglass-sibling-group",
      "components": ["mailglass", "mailglass_admin"]
    }
  ]
}
```

`mailglass_inbound` is intentionally NOT in the `components` array — it takes its own independent version. This is the permanent configuration; do not add `mailglass_inbound` to the linked group.

---

### CHANGELOG files — `CHANGELOG.md`, `mailglass_admin/CHANGELOG.md`, `mailglass_inbound/CHANGELOG.md` (doc-mod)

**Analog:** `mailglass_admin/CHANGELOG.md` — administrative sync entries are the established pattern.

**Current top of `mailglass_admin/CHANGELOG.md`** (lines 1–19):
```markdown
# Changelog

All notable changes to `mailglass_admin` will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning coordinated with `mailglass` core via Release Please linked-versions.

## [1.4.5](...) (2026-06-03)

### Miscellaneous Chores

* **mailglass_admin:** Synchronize mailglass-sibling-group versions
```

**Phase 79 convention:** Phase 79 does NOT manually edit CHANGELOG files. Release Please auto-generates entries from conventional commits. The planner should ensure all Phase 79 commits use correct conventional-commit prefixes:
- `fix(79):` — for the replay-flow e2e fix (triggers bugfix detection)
- `feat(79):` — for the conformance script (triggers minor-bump detection for linked group)
- `docs(79):` — for closeout artifacts, design-system expansion, GAP-22 reconfirmation

The Release Please pipeline will produce entries like:
```markdown
## [1.5.0](...) (2026-06-XX)

### Features
* **mailglass_admin:** add check-conformance.sh script (79: ...)

### Bug Fixes
* **mailglass_admin:** fix replay-flow e2e selector (79: ...)
```

Administrative (`Miscellaneous Chores`) entries for the core and inbound packages are expected and correct per D-11.

---

## Shared Patterns

### `set -euo pipefail` + error counter
**Source:** `scripts/check_motion_conformance.sh` lines 10–14
**Apply to:** `mailglass_admin/scripts/check-conformance.sh`
```bash
set -euo pipefail
LIB="mailglass_admin/lib"
errors=0
```
Every gate: `errors=$((errors + 1))` on failure, `exit 1` at end if `$errors -gt 0`.

### `grep -rE ... --include="*.ex"` scope
**Source:** `76-06-SUMMARY.md` lines 70–76 + RESEARCH.md Area 4
**Apply to:** All five gates in `check-conformance.sh`
All greps run over `mailglass_admin/lib/` with `--include="*.ex"`. Do NOT scan `mailglass_admin/assets/css/` for type/gap/hex gates (CSS definitions are not violations; the false-positive pattern in `check_motion_conformance.sh` for `--ease-in-out` applies there).

### Playwright structural assertion pattern
**Source:** `mailglass_admin/e2e/operator.spec.js` throughout
**Apply to:** All new tests in `operator.spec.js`
- Call `openOperator(page)` first
- Use `getByTestId(...)` for structural assertions (not `locator("h2")` etc.)
- Use `toBeVisible()` for presence, `toContainText(...)` for content
- Use `page.goto(url)` for surface switches, not click-driven navigation
- Nest all tests inside `test.describe("operator browser gate", ...)`

### Frozen-artifact + separate closeout pattern
**Source:** `73-01-RELEASE-RECORD.md` (Phase 73 precedent) + `74-GAP-REGISTER.md` anti-churn contract
**Apply to:** `79-GAP-CLOSEOUT.md`
Never edit the frozen source artifact (`74-GAP-REGISTER.md`). All closure evidence lives exclusively in the new `79-GAP-CLOSEOUT.md`. The closeout aggregates per-phase SUMMARY gap tables by reference (cite SUMMARY path + commit SHA), does not duplicate content.

---

## No Analog Found

All eight files have close analogs. None require fallback to RESEARCH.md-only patterns.

---

## Metadata

**Analog search scope:** `scripts/`, `mailglass_admin/e2e/`, `mailglass_admin/docs/`, `mailglass_inbound/`, `.planning/phases/73-*/`, `.planning/phases/74-*/`, `.planning/phases/75-*/`, `.planning/phases/76-*/`, `.planning/phases/78-*/`, repo root
**Files scanned:** 18 analog files read directly + targeted grep searches
**Pattern extraction date:** 2026-06-04
