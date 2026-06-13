---
phase: 94
plan: "03"
subsystem: mailglass_admin
tags:
  - css
  - design-system
  - tokens
  - testing
  - brand
dependency_graph:
  requires:
    - "94-01"
    - "94-02"
  provides:
    - "TOKEN-01"
    - "TOKEN-02"
    - "TOKEN-04"
    - "TOKEN-05"
  affects:
    - mailglass_admin
    - priv/static/app.css
tech_stack:
  added: []
  patterns:
    - daisyUI theme via var(--mg-*) custom property references
    - compiled-bundle parity test with Jason oracle + hex normalization
key_files:
  created:
    - mailglass_admin/test/mailglass_admin/token_parity_test.exs
  modified:
    - mailglass_admin/assets/css/app.css
    - mailglass_admin/priv/static/app.css
    - mailglass_admin/test/mailglass_admin/brand_test.exs
    - mailglass_admin/mix.exs
decisions:
  - "[94-03] app.css @import uses 3-level path ../../../brandbook/tokens.css; verified inlined in compiled bundle"
  - "[94-03] token_parity_test uses tier-aware extraction for dark-theme tokens from [data-theme=dark] CSS block"
  - "[94-03] hex comparison normalizes #fff shorthand to #ffffff for reliable equality; String.downcase on both sides"
  - "[94-03] All three tasks committed atomically per plan constraint: no intermediate commit leaves CI red"
metrics:
  duration: "~6 minutes"
  completed: "2026-06-13T19:36:04Z"
  tasks_completed: 3
  files_changed: 5
---

# Phase 94 Plan 03: Token Re-Baseline onto Canonical Brand Summary

Atomic re-baseline: app.css imports brandbook/tokens.css as single source of truth; both daisyUI theme blocks rewritten to pure var(--mg-*) references; parity test added and CI lane wired.

## What Was Built

**Task 1 — Rewrite mailglass_admin/assets/css/app.css and rebuild the compiled bundle**

Added `@import "../../../brandbook/tokens.css"` as the first declaration in app.css (before `@import "tailwindcss"`). Rewrote all `--color-*` slots in the mailglass-light and mailglass-dark daisyUI theme blocks to reference `var(--mg-*)` custom properties — no raw hex literals remain in theme selectors. Applied seven token-role corrections: base-200 light (Mist→White/surface-raised), base-300 light (Ice→Mist-edge/border), accent light (Ink→Glass), info light (Glass→Glass-deep/info-solid), base-300 dark (Ink-overlay→Ink-edge/border), secondary dark (Slate→Mist-soft/text-muted), error dark (off-palette D47368→Crimson-bright/error-solid). Added four previously absent -content slots per theme (info, success, warning, error). Rebuilt priv/static/app.css via `mix mailglass_admin.assets.build`.

**Task 2 — Create token_parity_test.exs (green against rebuilt bundle)**

Created `mailglass_admin/test/mailglass_admin/token_parity_test.exs` with:
- Structural assertion (TOKEN-01): refutes any `--color-*: #hex` pattern inside `[data-theme=mailglass-*]` blocks
- Value-equality assertion (TOKEN-04): iterates the full `@mapping` (40 entries across both themes), verifies each slot references `var(--mg-*)`, resolves the token from the tier-correct (`:light`/`:dark`) key in tokens.json, extracts the inlined value from the compiled CSS using block-scoped regex, and compares via hex normalization (handles `#fff` ↔ `#ffffff` shorthand)

**Task 3 — Update brand_test.exs and mix.exs**

Updated the three literal-hex assertions in brand_test.exs lines 44-52 to the two-tier var+hex form: each assertion now checks `var(--mg-*)` reference in the theme block AND that the resolved hex is inlined in compiled CSS (with both spaced and unspaced colon form). Added `token_parity_test.exs` to `verify.support_contract.admin` alias in mix.exs.

## Verification Results

| Gate | Result |
|------|--------|
| `grep -n '@import.*brandbook' app.css` | Line 9: `@import "../../../brandbook/tokens.css"` |
| No raw hex in --color-* lines | Clean (grep returns empty) |
| `grep -c '--mg-color-background' priv/static/app.css` | 1 (inlined) |
| `bash check-conformance.sh` | `OK: design-system conformance clean.` exit 0 |
| `mix test token_parity_test.exs` | 2 tests, 0 failures |
| `mix test brand_test.exs` | 5 tests, 0 failures |
| `mix verify.support_contract.admin` | 43 tests, 0 failures |
| `mix verify.preview` | 199 tests, 0 failures (1 excluded), exit 0 |
| No lib files changed | Confirmed |

## Deviations from Plan

**1. [Rule 1 - Bug] Three tasks committed atomically instead of individually**
- **Found during:** Task 1 verification
- **Issue:** verify.preview includes the full test suite (including brand_test.exs). After rewriting app.css in Task 1, brand_test.exs's old hex assertions failed, causing verify.preview to exit non-zero. The plan's explicit requirement is "no intermediate commit leaves main red on a required lane."
- **Fix:** Executed Tasks 2 and 3 before committing, then committed all five files as a single atomic commit per the plan's stated intent: "This plan merges as one green unit."
- **Files modified:** All five plan files in one commit
- **Commit:** 4c867a44

**2. [Rule 1 - Bug] brand_test.exs token assertions needed both spaced and no-space colon forms**
- **Found during:** Task 3 verification
- **Issue:** Tailwind minification removes spaces in CSS property declarations (`--mg-color-background:#f8fbfd`, not `--mg-color-background: #f8fbfd`). The plan's example assertions used a spaced form only.
- **Fix:** Added `or` fallback for no-space form in all six new brand_test assertions, matching the existing `or` pattern already used in that file.
- **Files modified:** `mailglass_admin/test/mailglass_admin/brand_test.exs`
- **Commit:** 4c867a44

**3. [Rule 1 - Bug] token_parity_test needs tier-aware dark-token extraction**
- **Found during:** Task 2 verification (first run)
- **Issue:** The initial `extract_mg_token_value` function always returned the first occurrence of each `--mg-color-*` token, which is the `:root`/light-theme declaration. Dark-theme tokens (`color.dark.*` tier) have different values that appear only in the `[data-theme=dark]` CSS block.
- **Fix:** Added a `tier` parameter (`:light`/`:dark`) to the extraction function. For `:dark`, extract the value from within the `[data-theme=dark]{...}` block using a scoped regex. Updated `@mapping` entries to include `{mg_token, tier}` tuples.
- **Files modified:** `mailglass_admin/test/mailglass_admin/token_parity_test.exs`
- **Commit:** 4c867a44

## Decisions Made

- **@import path:** `../../../brandbook/tokens.css` (3 levels up from `assets/css/`; build cwd is `mailglass_admin/`) verified correct by `grep -c '--mg-color-background' priv/static/app.css` returning 1.
- **Non-color slots preserved as literals:** `--radius-selector`, `--radius-field`, `--radius-box`, `--border`, `--depth`, `--noise` kept as literal values per plan; no var() conversion.
- **Hex normalization in parity test:** `normalize_hex/1` expands 3-digit shorthand (`#fff` → `#ffffff`) before comparing to oracle, making the test robust to Tailwind's CSS minification.

## Requirements Coverage

| Requirement | Status |
|-------------|--------|
| TOKEN-01 (no raw hex in --color-* lines, --mg-* inlined) | GREEN — structural assertion in parity test + source rewrite |
| TOKEN-02 (light/dark slot remap via brandbook tokens) | GREEN — brand_test + parity test both pass |
| TOKEN-04 (parity oracle + CI lane) | GREEN — token_parity_test.exs in verify.support_contract.admin |
| TOKEN-05 (bundle rebuilt + committed) | GREEN — priv/static/app.css rebuilt and committed; mix verify.preview exits 0 |

## Self-Check

**Files exist:**
- `mailglass_admin/assets/css/app.css` — FOUND (modified, contains @import)
- `mailglass_admin/priv/static/app.css` — FOUND (rebuilt, committed)
- `mailglass_admin/test/mailglass_admin/token_parity_test.exs` — FOUND (new)
- `mailglass_admin/test/mailglass_admin/brand_test.exs` — FOUND (modified)
- `mailglass_admin/mix.exs` — FOUND (modified)

**Commits exist:**
- `4c867a44` — FOUND: feat(admin): re-baseline app.css onto brandbook tokens

## Self-Check: PASSED
