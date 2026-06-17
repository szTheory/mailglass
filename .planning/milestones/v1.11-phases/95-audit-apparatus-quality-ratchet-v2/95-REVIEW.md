---
phase: 95-audit-apparatus-quality-ratchet-v2
reviewed: 2026-06-14T00:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - mailglass_admin/test/mailglass_admin/ratchet_baseline_test.exs
  - mailglass_admin/e2e/structural.spec.js
  - mailglass_admin/scripts/ui-audit.sh
  - mailglass_admin/mix.exs
  - mailglass_admin/docs/ui-baseline-scores.json
findings:
  critical: 0
  warning: 3
  info: 6
  total: 9
status: issues_found
---

# Phase 95: Code Review Report

**Reviewed:** 2026-06-14
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Phase 95 is a test/apparatus phase: a fail-closed ExUnit baseline assertion, a Playwright structural-assertion spec, a bash screenshot harness, a one-line mix alias edit, and a 36-cell JSON data artifact. No production runtime code, no auth, no new deps.

The core ratchet machinery is sound. The ExUnit shape/range/coverage assertions are real and non-vacuous (they collect-and-report all violations, fail closed on a missing file, and reject non-integer and `nil` scores). The `if false, do: compare_baselines(...)` dead-code idiom is a legitimate, well-documented way to keep an intentionally-uncalled `defp` from tripping `--warnings-as-errors`.

The defects worth flagging cluster in the Playwright spec, where two tests are written to **pass unconditionally** (GAP-posture) in a way that defeats their stated assertion, plus a robustness gap in the focus/click flow. None rise to Critical — there is no security surface, no PII, no data-loss path, and the apparatus is dev/test-only and excluded from the Hex tarball. But the GAP-posture "always-green" assertions are warnings because they silently mask regressions a reader would reasonably assume are guarded.

## Warnings

### WR-01: Two structural-spec tests assert nothing and cannot fail

**File:** `mailglass_admin/e2e/structural.spec.js:108-144` (Operator touch target), `mailglass_admin/e2e/structural.spec.js:293-330` (Preview focus ring)

**Issue:** The Operator touch-target test ends with `expect(typeof box.height).toBe("number")` — a tautology that is true for every possible boundingBox. The actual touch-target requirement (`>= 44px`) is only mentioned in a comment. The test is structurally incapable of catching a regression: if a future change drops the primary CTA to 4px, or grows the known 21px button past 44px (the supposed reason it is GAP-posture), the test stays green either way. The "GAP-posture" framing justifies not *failing* today, but the chosen escape hatch removes the assertion entirely rather than scoping it.

The Preview focus-ring test has the same shape inverted: it `return`s early (passes) whenever there are zero focusable elements OR `focus()` times out. So the day someone adds a focusable CTA to the empty state (the stated Phase 100 fix), the test will start exercising the real `outlineWidth > 0` assertion — but until then it asserts nothing, and there is no machine-checked link tying "passes via early return" to "the GAP is still open." If the empty state silently gains a non-focusable element later, behavior is unguarded.

This is the classic soft-review trap the apparatus exists to prevent: a green test that proves nothing. It should at minimum record the real measured value somewhere a regression can be detected, or be converted to `test.fixme()`/`test.skip()` with the GAP id so the deferral is machine-visible rather than a silently-passing assertion.

**Fix:** Make the deferral explicit instead of asserting a tautology. Two acceptable shapes:

```js
// Option A: scope the real assertion to the known-bad element and mark it expected-fail
test.fixme("Operator: primary CTA >= 44px (GAP-01, fix in Phase 98)", async ({ page }) => {
  // ... real assertion: expect(box.height).toBeGreaterThanOrEqual(44);
});

// Option B: keep it green but assert the GAP is still in the register (regression-detecting)
// e.g. read RATCHET-GAP-REGISTER.md and assert GAP-01 status === "open";
//      if the button is fixed, box.height >= 44 AND the register must be updated.
const box = await primaryBtn.boundingBox();
if (box.height >= 44) {
  // GAP-01 appears resolved — force a deliberate update of the register, don't silently pass
  throw new Error("Operator CTA now >= 44px — close GAP-01 and assert >= 44 here");
}
```

For the Preview focus-ring test, replace the silent `return` on the zero-focusable branch with `test.skip(true, "GAP-02: preview empty state has no focusable CTA — fix Phase 100")` so the skip is reported, not hidden inside a passing test.

### WR-02: Reduced-motion tests do not assert reduced motion

**File:** `mailglass_admin/e2e/structural.spec.js:241-261`

**Issue:** FACT 4 is titled "reduced-motion suppresses animation," but all three tests only call `emulateMedia({reducedMotion: "reduce"})` and then assert that a content element `toBeVisible()`. Visibility of `operator-deliveries-list` / a heading / `preview-orientation` is already asserted by the `openOperator` / `openInbound` / `openPreview` helpers without reduced motion — so these tests would pass identically with the `emulateMedia` line deleted. They do not observe `animation-duration`, `transition-duration`, or any motion property, so they cannot detect a violation where reduced-motion is honored nowhere. This is a vacuous pillar assertion masquerading as a motion check.

**Fix:** Assert a motion property is actually suppressed under the emulated preference, e.g. sample a known-animated element and verify its computed `animation-duration`/`transition-duration` collapses (or is `0s`) under reduced motion:

```js
const dur = await page.locator("[data-testid='operator-deliveries-list']").evaluate(
  el => getComputedStyle(el).transitionDuration
);
// Under prefers-reduced-motion the design system should zero transitions
expect(dur === "0s" || dur === "").toBeTruthy();
```

If no surface element animates today, record that as an explicit GAP/skip rather than a passing visibility check, so the test is not silently green for the wrong reason.

### WR-03: Accent-allowlist check is dead for every element it is run against

**File:** `mailglass_admin/e2e/structural.spec.js:342-412` (helper at 44-63)

**Issue:** Each accent test calls `isAccentAllowlisted(page, locator)` on a fixed set of structural containers — `body`, `getByTestId("operator-deliveries-list")`, `getByRole("navigation")`, `preview-orientation`. None of those elements can ever match `[aria-selected='true']`, `[aria-current='page']`, `.btn-primary`, or `:focus-visible` (the latter is explicitly skipped in the helper). So `allowlisted` is always `false` and the `if (!allowlisted)` branch always runs. The allowlist logic is dead code in this context — it adds a per-element `evaluate` round-trip and the appearance of nuance, but never changes behavior. Worse, because the chosen locators are guaranteed non-accent containers, the test would also pass if the allowlist were inverted or broken; it only meaningfully checks "these 2-3 specific containers are not accent-colored," which is a much weaker fact than the section title ("accent color only on allowlisted elements") implies.

This is not a correctness bug in what it asserts, but the gap between the stated fact ("only on allowlist") and the actual fact ("these few containers are not accent") is a maintainability/credibility hazard for an apparatus whose whole purpose is to prevent soft assertions.

**Fix:** Either (a) drop the unused `isAccentAllowlisted` call for these containers and rename the assertion to what it actually verifies ("core structural containers are not accent-colored"), or (b) make it a real allowlist scan: enumerate all elements whose computed color/background equals `ACCENT_LIGHT_RGB` and assert each one matches an allowlist selector. Option (b) is the assertion the title promises:

```js
const offenders = await page.evaluate((accent) => {
  const allow = ["[aria-selected='true']","[aria-current='page']",".btn-primary"];
  return [...document.querySelectorAll("*")]
    .filter(el => { const cs = getComputedStyle(el);
      return cs.color === accent || cs.backgroundColor === accent; })
    .filter(el => !allow.some(sel => el.matches(sel)))
    .map(el => el.tagName + "." + el.className);
}, ACCENT_LIGHT_RGB);
expect(offenders).toEqual([]);
```

## Info

### IN-01: `aria-selected` assertion after click relies on LiveView round-trip without explicit settle

**File:** `mailglass_admin/e2e/structural.spec.js:77-79`

**Issue:** `firstRow.click()` triggers a LiveView patch that sets `aria-selected="true"` server-side. The following `toHaveAttribute` auto-retries (Playwright web-first assertion), so this is not currently flaky. Flagged only because the spec elsewhere depends on socket-connected behavior and the summary documents a parallel-worker DB race; if the socket is not connected the attribute never updates and this fails as a timeout rather than a clear message. No change required; consider a comment noting the LiveView dependency.

### IN-02: `tenantId` is duplicated across spec files instead of shared

**File:** `mailglass_admin/e2e/structural.spec.js:4`

**Issue:** `const tenantId = "browser-tenant"` and the entire `openOperator` helper are copy-pasted verbatim from `operator.spec.js`. The comments even say "Mirrors operator.spec.js ... exactly." Two copies of an auth-handshake helper will drift; when `openOperator` changes in one file (as it already has — note the h1-level disambiguation comment in operator.spec.js), the copy must be hand-synced. Consider extracting a shared `e2e/helpers.js`.

**Fix:** Extract `openOperator`/`tenantId` to a shared module and `require` it in both specs.

### IN-03: `shot()` swallows agent-browser failures, harness can report success after silent misses

**File:** `mailglass_admin/scripts/ui-audit.sh:53-57`

**Issue:** `agent-browser open` redirects both streams to `/dev/null` and `screenshot` pipes through `tail -1`. With `set -o pipefail` a hard non-zero from `agent-browser screenshot` would still surface, but `agent-browser open` failures are fully discarded (`>/dev/null 2>&1` with no status check), so a navigation that 404s or never loads can still produce a screenshot of an error page, and the script prints "Done. 18 PNGs written" regardless of how many actually landed. For an ad-hoc local tool this is acceptable, but the final "18 PNGs" message is asserted, not verified.

**Fix:** After the loops, verify the count before printing success: `count=$(ls "$OUT"/*.png 2>/dev/null | wc -l); [ "$count" -eq 18 ] || { echo "WARN: expected 18 PNGs, got $count"; exit 1; }`.

### IN-04: Fixed 1-second `sleep` after navigation is a brittle race proxy

**File:** `mailglass_admin/scripts/ui-audit.sh:55,90`

**Issue:** `sleep 1` after `agent-browser open` is a fixed wait for page render. On a cold demo container or slow LiveView socket connect, 1s may capture a half-rendered or unauthenticated frame; on a warm box it wastes time. The script header acknowledges socket-not-connected risk. Since these PNGs feed the LLM scoring baseline, a mistimed capture silently corrupts a score cell. Acceptable for an ad-hoc tool but worth a comment or a readiness check (poll for a known element) instead of a blind sleep.

### IN-05: Preview dark/light produce identical screenshots — wasted matrix cells with no marker

**File:** `mailglass_admin/scripts/ui-audit.sh:72-81`

**Issue:** The header comment and Plan 04 summary both state the preview surface ignores the theme param, so `preview-*-dark.png` is byte-identical to `preview-*-light.png`. The script still captures both (by design, to let the GAP register note the absence), but nothing in the output marks the two as known-duplicates, so a future maintainer LLM-scoring the matrix could waste effort or mis-score the "dark" cell as if it were a real dark render. This is exactly the gap recorded as GAP-03; flagged here only so the capture-time duplication is visible at the script level. No fix required given GAP-03 tracks it.

### IN-06: `compare_baselines/2` treats a vanished cell as a regression via `|| 0`

**File:** `mailglass_admin/test/mailglass_admin/ratchet_baseline_test.exs:90-96`

**Issue:** When Phase 103 wires the real call site, a cell present in `prior` but missing in `current` resolves to `current_score = 0`, `0 < prior_score` → flagged as a regression with message `"N → 0 (REGRESSION)"`. That is arguably correct (a dropped cell *is* a regression), but it conflates "score dropped" with "cell missing," and the coverage test (`all 36 cells present`) would already fail independently — so the regression message could be a confusing secondary failure. Minor; the function is uncalled in Phase 95. Consider, at Phase 103 wire-up, treating a missing current cell as a distinct error rather than a numeric regression to `0`.

**Fix (defer to Phase 103):** branch on `current_score == nil` separately from `current_score < prior_score`.

---

_Reviewed: 2026-06-14_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
