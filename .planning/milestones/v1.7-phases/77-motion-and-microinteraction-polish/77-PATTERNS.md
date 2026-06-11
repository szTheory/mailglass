# Phase 77: Motion and Microinteraction Polish - Pattern Map

**Mapped:** 2026-06-04
**Files analyzed:** 4 (2 modified, 1 new, 1 modified)
**Analogs found:** 4 / 4

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `mailglass_admin/lib/mailglass_admin/operator_live.ex` (modify ~line 442) | component | request-response | `mailglass_admin/lib/mailglass_admin/preview/tabs.ex:84` | exact |
| `mailglass_admin/lib/mailglass_admin/inbound_live.ex` (modify ~line 341) | component | request-response | `mailglass_admin/lib/mailglass_admin/preview/tabs.ex:84` | exact |
| `scripts/check_motion_conformance.sh` (new) | utility | batch | `scripts/check_credo_suppressions.sh` + `scripts/check_dialyzer_ignore.sh` | exact |
| `mailglass_admin/e2e/operator.spec.js` (modify) | test | request-response | same file (existing test blocks) | self-analog |

---

## Pattern Assignments

### `mailglass_admin/lib/mailglass_admin/operator_live.ex` (component, request-response)

**Change:** Add `id={"delivery-detail-#{@selected_delivery.id}"}` to the bare `motion-reveal` div at line 442. One attribute, one line diff.

**Analog:** `mailglass_admin/lib/mailglass_admin/preview/tabs.ex:84`

**Id-keyed motion pattern** (tabs.ex lines 84–94):
```heex
<div id={"preview-tab-" <> Atom.to_string(@active_tab)} class="motion-tab-swap">
  <.tab_content
    active_tab={@active_tab}
    html_body={@html_body}
    text_body={@text_body}
    raw_envelope={@raw_envelope}
    headers={@headers}
    device_width={@device_width}
    render_nonce={@render_nonce}
  />
</div>
```

**Current state of target site** (operator_live.ex lines 441–459 — BARE, no id):
```heex
<% true -> %>
  <div class="motion-reveal space-y-4">
    <DetailHeader.detail_header
      delivery={@selected_delivery}
      replay_targets={@replay_targets}
      latest_replay={latest_replay(@replay_history)}
    />
    <SupportCards.support_cards
      support_summary={@support_summary}
      support_state={@support_state}
      suppression_count={@suppression_count}
    />
    <OperatorTimeline.timeline
      timeline_events={@timeline_events}
      highlight_event_id={@support_state.event_id}
    />
    <SuppressionCard.suppression_card suppression_state={@suppression_state} />
  </div>
```

**After fix — copy this pattern:**
```heex
<% true -> %>
  <div id={"delivery-detail-#{@selected_delivery.id}"} class="motion-reveal space-y-4">
```

Mechanism: `@selected_delivery.id` changes when a different delivery is selected. LiveView's diff algorithm detects the changed `id` and performs an element replace (remove old + insert new) rather than an in-place patch. The new element's insertion fires the `mg-reveal` `@keyframes` animation exactly once per selection.

---

### `mailglass_admin/lib/mailglass_admin/inbound_live.ex` (component, request-response)

**Change:** Add `id={"inbound-detail-#{@detail.record.id}"}` to the bare `motion-reveal` div at line 341. One attribute, one line diff.

**Analog:** `mailglass_admin/lib/mailglass_admin/preview/tabs.ex:84` (same mechanism as above)

**Current state of target site** (inbound_live.ex lines 340–352 — BARE, no id):
```heex
<% true -> %>
  <div class="motion-reveal space-y-4">
    <DetailHeader.detail_header detail={@detail} />
    <Timeline.timeline runs={@runs} />
    <RoutingTrace.routing_trace
      :if={@detail[:outcome] == :no_match}
      trace={@routing_trace}
    />
    <EvidenceCard.evidence_card
      evidence={@detail[:evidence]}
      reveal_state={@reveal_state}
    />
  </div>
```

**After fix — copy this pattern:**
```heex
<% true -> %>
  <div id={"inbound-detail-#{@detail.record.id}"} class="motion-reveal space-y-4">
```

**Critical:** Use `@detail.record.id`, NOT `@selected_record.id`. The `true ->` branch activates when `@detail` is non-nil — `@detail.record` is an `%InboundRecord{}` struct guaranteed non-nil in this branch. `@selected_record` could theoretically be nil if a URL-injected `inbound_id` does not match the current filtered list, causing `nil.id` crash.

---

### `scripts/check_motion_conformance.sh` (utility, batch — NEW FILE)

**Analog:** `scripts/check_credo_suppressions.sh` and `scripts/check_dialyzer_ignore.sh`

**Full structure of analog** (check_credo_suppressions.sh lines 1–43):
```bash
#!/usr/bin/env bash
# [Purpose comment]
set -euo pipefail

FILE=".credo.exs"
errors=0

# ... awk/grep logic ...
# On a hit: errors=$((errors + 1))

if [[ $errors -gt 0 ]]; then
  echo "FAIL: [message]" >&2
  exit 1
fi

echo "OK: all credo suppressions are documented."
```

**Full structure of analog** (check_dialyzer_ignore.sh lines 1–37): demonstrates iterating over multiple file targets and a clean `for` loop + `continue` skip pattern.

**Script location:** `scripts/check_motion_conformance.sh` at the **repo root** `scripts/` directory. The `mailglass_admin/scripts/` dir contains only `ui-audit.sh` (which is explicitly NOT used per D-06). The new script goes in the same `scripts/` directory as `check_credo_suppressions.sh`.

**CI wiring:** Added as a `run: bash scripts/check_motion_conformance.sh` step in the `credo_strict` job in `.github/workflows/ci.yml`, after the existing `bash scripts/check_credo_suppressions.sh` step (lines 395–398). Mirror the existing step's name + comment format:
```yaml
- name: Verify motion conformance (shell gate)
  # Fails CI if any banned layout-thrashing or easing token appears
  # in lib/ or app.css per UI-SPEC Motion Rules (Phase 74 FROZEN contract).
  run: bash scripts/check_motion_conformance.sh
```

**Two-pass grep structure (avoids false positive on `--ease-in-out` CSS var in app.css):**

Pass A — layout-thrashing tokens, grep both `mailglass_admin/lib/` AND `mailglass_admin/assets/css/app.css`:
- `transition-height|transition-max-height|transition-padding|transition-all`
- `duration-300|duration-[4-9][0-9][0-9]|duration-[0-9]{4,}`

Pass B — easing classes, grep `mailglass_admin/lib/` ONLY (app.css has `--ease-in-out` CSS custom property at line 120 that would false-positive):
- `ease-in-out|ease-linear`
- `ease-in` (bare, not followed by `-out`) — use `ease-in[^-]` or `ease-in$` for portability across BSD grep (macOS) and GNU grep (Ubuntu CI), NOT `\b`

**Note on `ease-in` regex:** `ease-in\b` behaves differently across macOS BSD grep and Ubuntu GNU grep. Use `ease-in[^-]` or a pattern that avoids word-boundary extensions. The RESEARCH.md open question #2 flags this; the planner must verify the regex does not false-positive on `ease-in-out` in lib/ files before wiring to CI.

---

### `mailglass_admin/e2e/operator.spec.js` (test, request-response — MODIFY)

**Self-analog:** The file is its own pattern source. New tests are appended inside the existing `test.describe("operator browser gate", ...)` block.

**Existing helper functions to reuse** (operator.spec.js lines 3–30):
```javascript
const tenantId = "browser-tenant";
const selectedRecipient = "browser-selected@example.com";

function deliveryRow(page, index) {
  return page.getByTestId("operator-delivery-row").nth(index);
}

async function openOperator(page) {
  const resetResponse = await page.request.get("/ops/browser-reset");
  expect(resetResponse.ok()).toBeTruthy();
  const returnTo = encodeURIComponent(`/ops/mail?tenant_id=${tenantId}`);
  await page.goto(`/ops/browser-login?tenant_id=${tenantId}&return_to=${returnTo}`);
  await expect(page.getByRole("heading", { name: "Operator overview", exact: true })).toBeVisible();
  await page.goto(`/ops/mail?tenant_id=${tenantId}&view=deliveries`);
  await expect(page.getByRole("heading", { name: "Deliveries", exact: true, level: 1 })).toBeVisible();
  await expect(page.getByTestId("operator-deliveries-list")).toBeVisible();
}
```

**Existing test anatomy to mirror** (lines 33–71 — desktop two-pane test):
```javascript
test("desktop keeps list/detail in two panes and preserves read-only selection flow", async ({ page }) => {
  await page.setViewportSize({ width: 1280, height: 900 });
  await openOperator(page);
  // ... assertions using page.getByTestId, page.locator, expect().toBeVisible() ...
  await deliveryRow(page, 0).click();
  await expect(page).toHaveURL(/delivery_id=/);
  await expect(page.getByTestId("operator-detail-header")).toBeVisible();
});
```

**New test 1 — id-presence assertion (D-07, MOTION-01 regression gate):**
```javascript
test("delivery detail pane carries record-keyed id for animation re-fire", async ({ page }) => {
  await page.setViewportSize({ width: 1280, height: 900 });
  await openOperator(page);

  await deliveryRow(page, 0).click();

  const deliveryId = new URL(page.url()).searchParams.get("delivery_id");
  expect(deliveryId).toBeTruthy();

  await expect(page.locator(`#delivery-detail-${deliveryId}`)).toBeVisible();

  // Switch to a second delivery and verify the id changes (element replaced, not patched)
  await deliveryRow(page, 1).click();
  const deliveryId2 = new URL(page.url()).searchParams.get("delivery_id");
  expect(deliveryId2).not.toEqual(deliveryId);
  await expect(page.locator(`#delivery-detail-${deliveryId2}`)).toBeVisible();
  await expect(page.locator(`#delivery-detail-${deliveryId}`)).toHaveCount(0);
});
```

**New test 2 — reduced-motion (D-07, MOTION-02 regression gate):**
```javascript
test("motion-reveal is suppressed under prefers-reduced-motion", async ({ page }) => {
  // Emulate BEFORE navigation — emulateMedia must precede page load
  await page.emulateMedia({ reducedMotion: "reduce" });
  await page.setViewportSize({ width: 1280, height: 900 });
  await openOperator(page);

  await deliveryRow(page, 0).click();
  const deliveryId = new URL(page.url()).searchParams.get("delivery_id");
  expect(deliveryId).toBeTruthy();

  // Under reduced-motion the CSS sets animation-duration: 0.01ms !important
  // so the element is effectively immediately visible (not stuck at opacity: 0)
  await expect(page.locator(`#delivery-detail-${deliveryId}`)).toBeVisible();
});
```

**`page.emulateMedia` placement note:** Must be called BEFORE `page.goto` to ensure the media query is active when the page loads and CSS is evaluated. The pattern is: `emulateMedia` → `setViewportSize` → `openOperator` (which calls `page.goto` internally).

**Inbound id-presence test (D-07 — conditional on seed verification):** Navigate to `/ops/inbound?tenant_id=browser-tenant`, click an inbound record row, read `inbound_id` from URL, assert `#inbound-detail-<id>` is visible. Before implementing, confirm `OperatorFixtures.seed_browser_scenario!()` includes inbound records. If inbound is not seeded, add a comment explaining the gap rather than a fragile test.

---

## Shared Patterns

### Record-Keyed Id for LiveView Animation Re-Fire
**Source:** `mailglass_admin/lib/mailglass_admin/preview/tabs.ex:84`
**Apply to:** Both `operator_live.ex:442` and `inbound_live.ex:341`
```heex
<div id={"<prefix>-<record-id-expression>"} class="motion-<class>">
```
The id prefix is a stable slug (`delivery-detail-`, `inbound-detail-`, `preview-tab-`). The id value is an assign expression whose value changes when the rendered record changes. No JS hooks, no phx-mounted events — LiveView's diff handles element replacement automatically.

### Shell Conformance Gate Structure
**Source:** `scripts/check_credo_suppressions.sh` (lines 1–43) and `scripts/check_dialyzer_ignore.sh` (lines 1–37)
**Apply to:** `scripts/check_motion_conformance.sh`
```bash
#!/usr/bin/env bash
# [purpose comment]
set -euo pipefail

errors=0

# grep/awk logic — on hit: errors=$((errors + 1))

if [[ $errors -gt 0 ]]; then
  echo "FAIL: [message]" >&2
  exit 1
fi

echo "OK: [success message]"
```
Note: use `[[:space:]]*` not `\s*` for POSIX awk compatibility on macOS (pattern seen in check_credo_suppressions.sh:17).

### CI Step Wiring in `credo_strict` Job
**Source:** `.github/workflows/ci.yml:395–398`
**Apply to:** New `check_motion_conformance.sh` step
```yaml
- name: Verify suppression docs (shell gate)
  run: bash scripts/check_credo_suppressions.sh
```
Mirror the step immediately after the existing `check_credo_suppressions.sh` step. New step name: `Verify motion conformance (shell gate)`.

### Playwright Test Structure
**Source:** `mailglass_admin/e2e/operator.spec.js:32–183`
**Apply to:** New tests added inside the existing `test.describe("operator browser gate", ...)` block
- Start with `setViewportSize({ width: 1280, height: 900 })`
- Call `openOperator(page)` for navigation + session
- Use `deliveryRow(page, index)` helper for row clicks
- Use `page.locator('#...')` for id-based assertions
- Use `await expect(...).toBeVisible()` and `.toHaveCount(0)` for presence/absence

---

## No Analog Found

None — all four files have concrete analogs in the codebase.

---

## Metadata

**Analog search scope:** `mailglass_admin/lib/`, `mailglass_admin/e2e/`, `mailglass_admin/preview/`, `scripts/`, `.github/workflows/`
**Files scanned:** 8 (tabs.ex, operator_live.ex, inbound_live.ex, operator.spec.js, playwright.config.cjs, check_credo_suppressions.sh, check_dialyzer_ignore.sh, ci.yml)
**Pattern extraction date:** 2026-06-04
