# Phase 94: Token Re-Baseline onto Canonical Brand - Pattern Map

**Mapped:** 2026-06-13
**Files analyzed:** 8 (2 new, 6 modified)
**Analogs found:** 8 / 8

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `mailglass_admin/test/mailglass_admin/token_parity_test.exs` | test | file-I/O + transform | `mailglass_admin/test/mailglass_admin/brand_test.exs` | exact (same compiled-bundle seam) |
| `mailglass_admin/scripts/check-conformance-advisory.sh` | shell-gate | request-response | `mailglass_admin/scripts/check-conformance.sh` | exact (same 5-gate structure, same BASH_SOURCE anchor) |
| `mailglass_admin/assets/css/app.css` | CSS-token-config | transform | itself (existing daisyUI theme blocks) | exact (same `@plugin daisyui-theme` block shape) |
| `mailglass_admin/test/mailglass_admin/accessibility_test.exs` | test | transform | itself (existing `contrast_ratio/2` + `luminance/1`) | exact (extend in place) |
| `mailglass_admin/test/mailglass_admin/brand_test.exs` | test | file-I/O | itself (lines 44-52, literal-hex assertions) | exact (update in place) |
| `mailglass_admin/scripts/check-conformance.sh` | shell-gate | request-response | itself (lines 45, TYPE-GATE block) | exact (extend TYPE-GATE regex in place) |
| `scripts/check_motion_conformance.sh` | shell-gate | request-response | itself (line 18, THRASH_PATTERN) | exact (extend THRASH_PATTERN in place) |
| `.github/workflows/ci.yml` | CI-config | event-driven | itself (lines 399-404, `credo_strict` job) | exact (insert 2 steps after line 402) |
| `mailglass_admin/mix.exs` | build-alias | transform | itself (lines 189-191, `verify.support_contract.admin` alias) | exact (add one test path to list) |

---

## Pattern Assignments

### `mailglass_admin/test/mailglass_admin/token_parity_test.exs` (new — test, file-I/O + transform)

**Analog:** `mailglass_admin/test/mailglass_admin/brand_test.exs`
**Also reference message-style:** `mailglass_admin/test/mailglass_admin/bundle_test.exs`

**Module header + use pattern** (brand_test.exs lines 1-13):
```elixir
defmodule MailglassAdmin.TokenParityTest do
  @moduledoc """
  Fail-closed compiled-bundle parity test (TOKEN-04).

  Reads the compiled `priv/static/app.css` and asserts:
  1. No raw `#hex` appears on any `--color-*` line inside a daisyUI theme selector
     (the TOKEN-01 no-raw-hex structural rule).
  2. Every daisyUI `--color-*` slot in both themes resolves via `var(--mg-*)` to
     the oracle value from `brandbook/tokens.json`.

  If this test fails with "expected var(--mg-*) but got #hex", the bundle is stale.
  Run `cd mailglass_admin && mix mailglass_admin.assets.build && git add priv/static/`
  and commit. If it fails with a value mismatch, either `brandbook/tokens.json` was
  updated without re-syncing `app.css`, or `app.css` was hand-edited — never hand-edit
  `priv/static/app.css`. `actual` is what currently SHIPS.
  """

  use ExUnit.Case, async: true

  @tag :token_parity
```

**Compiled-bundle path seam** (brand_test.exs lines 15-23 — copy verbatim):
```elixir
  @css_path Path.join([
              Application.app_dir(:mailglass_admin, "priv"),
              "static",
              "app.css"
            ])

  setup do
    css = File.read!(@css_path)
    {:ok, css: css}
  end
```

**Oracle path pattern** (from RESEARCH.md §token_parity_test seam):
```elixir
  # Three levels up from test/mailglass_admin/ → monorepo root → brandbook/
  @tokens_path Path.expand(Path.join([__DIR__, "..", "..", "..", "brandbook", "tokens.json"]))

  setup_all do
    assert File.exists?(@tokens_path),
           "tokens.json not found at #{@tokens_path} — run from mailglass_admin/"
    {:ok, tokens: Jason.decode!(File.read!(@tokens_path))}
  end
```

**Failure message style** (bundle_test.exs lines 23-25 — match exactly):
```elixir
      assert size < 150_000, "app.css is #{size} bytes; PREV-06 budget is <150KB"
```
For parity test: `"#{theme} #{slot} must reference #{expected_mg_token}; actual: #{actual_value}. Bundle is stale or app.css hand-edited — run mix mailglass_admin.assets.build"`

**@mapping structure** (from RESEARCH.md §`@mapping` shape):
```elixir
  # {theme_name, daisyui_slot} => mg_token_name
  # This map IS the slot-to-role contract; a token rename forces a deliberate edit here.
  @mapping %{
    {"mailglass-light", "--color-base-100"} => "--mg-color-background",
    {"mailglass-light", "--color-base-200"} => "--mg-color-surface-raised",
    {"mailglass-light", "--color-base-300"} => "--mg-color-border",
    # ... full table from RESEARCH.md §Full Per-Slot daisyUI Mapping Table
  }
```

**No-raw-hex structural assertion** (from CONTEXT.md D-02):
```elixir
  test "no raw hex in any --color-* line inside daisyUI theme selectors", %{css: css} do
    # Extract each [data-theme=mailglass-*] { ... } block then scan lines.
    # A line matching `--color-[a-z-]+: #[0-9a-fA-F]` is a TOKEN-01 violation.
    refute css =~ ~r/\[data-theme=mailglass-[^\]]+\]\s*\{[^}]*--color-[a-z-]+:\s*#[0-9a-fA-F]/s,
           "TOKEN-01 violation: raw hex literal on a --color-* line inside a daisyUI theme block. " <>
           "All --color-* values must reference var(--mg-*). Run mix mailglass_admin.assets.build."
  end
```

**@tag convention** (convenience selector only, not excluded from any CI lane):
```elixir
  @tag :token_parity
  test "..." ...
```

---

### `mailglass_admin/scripts/check-conformance-advisory.sh` (new — shell-gate, request-response)

**Analog:** `mailglass_admin/scripts/check-conformance.sh` (full file, lines 1-89)

**Header + BASH_SOURCE anchor pattern** (check-conformance.sh lines 1-25 — copy exactly, adapt description):
```bash
#!/usr/bin/env bash
# Advisory conformance gates for mailglass_admin — TYPE-GATE (text-lg/xl) + TRACK-GATE.
# These patterns have known violations deferred to Phase 98/99; run CI with
# continue-on-error: true until those markup phases flip them to hard-fail.
# See CONTEXT.md D-08 for the advisory/hard-fail split rationale.
#
# This script ALWAYS exits 0 — it is purely advisory. Violations are printed
# to stdout so CI logs them, but main stays green.
#
# Phase 99 task: flip this script's exit-code contract to hard-fail (remove `|| true`
# or change `exit 0` to `exit $errors`) after migrating the 5 text-xl/lg sites
# and defining --tracking-eyebrow in brandbook/tokens.css.

set -euo pipefail

# BASH_SOURCE anchor — cwd-independent (same as check-conformance.sh lines 22-24)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${SCRIPT_DIR}/../lib"
[[ -d "$LIB" ]] || { echo "FAIL: lib dir not found at $LIB" >&2; exit 2; }
```

**Gate block pattern** (check-conformance.sh lines 28-33 — adapt for advisory gates):
```bash
# TYPE-GATE (advisory): text-lg/xl/2xl/3xl/4xl/5xl in HEEx.
# Use semantic tokens instead: text-heading (20px), text-display (28px).
# 5 known violations (preview_live, detail_header ×2, replay_modal ×2) — Phase 98/99.
if grep -rEn 'text-(lg|xl|2xl|3xl|4xl|5xl)\b' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "WARN: TYPE-GATE (advisory) — text-lg/xl found; fix in Phase 98/99 (use text-heading/display)" >&2
fi

# TRACK-GATE (advisory): arbitrary tracking-[…] JIT utilities in HEEx.
# Named tracking-tight/wide/normal are allowed. tracking-[0.08em] bypasses
# the token contract; define --tracking-eyebrow in brandbook/tokens.css first.
# ~43 known violations (all tracking-[0.08em]) — Phase 98/99.
if grep -rEn 'tracking-\[' "$LIB" --include="*.ex" 2>/dev/null; then
  echo "WARN: TRACK-GATE (advisory) — arbitrary tracking-[…] found; fix in Phase 98/99" >&2
fi

echo "OK: advisory conformance check complete (violations above are logged, not blocking)."
exit 0
```

**Critical difference from analog:** This script exits 0 unconditionally (advisory). The analog (`check-conformance.sh`) exits 1 on any violation. Do NOT use the `errors=0` / `$errors -gt 0` / `exit 1` pattern from the analog — that makes the script hard-fail. The CI `continue-on-error: true` is a second safety net; the script itself must exit 0.

---

### `mailglass_admin/assets/css/app.css` (modified — CSS-token-config, transform)

**Analog:** itself — existing `@plugin "../vendor/daisyui-theme"` blocks (lines 16-77)

**@import insertion point** (add before line 5 `@import "tailwindcss"`):
```css
/* Resolves to: <monorepo-root>/brandbook/tokens.css (build cwd = mailglass_admin/) */
/* The standalone Tailwind v4.1.12 binary inlines all --mg-* declarations into      */
/* priv/static/app.css at build time. Adopted apps only consume the pre-resolved     */
/* bundle; brandbook/ is excluded from the Hex tarball (mix.exs :files).             */
@import "../../../brandbook/tokens.css";
```

**Existing daisyUI theme block shape to preserve** (app.css lines 16-46 — current structure):
```css
@plugin "../vendor/daisyui-theme" {
  name: "mailglass-light";
  default: true;
  prefersdark: false;
  color-scheme: "light";

  /* Brand book §7.3 — canonical palette mapped to daisyUI semantic tokens */
  --color-base-100: #F8FBFD;   /* current — will become var(--mg-color-background) */
  ...

  --radius-selector: 0.25rem;  /* NON-COLOR: keep as literal values */
  --radius-field: 0.25rem;
  --radius-box: 0.5rem;
  --border: 1px;
  --depth: 0;
  --noise: 0;
}
```

**After rewrite — `--color-*` lines become** (pattern from RESEARCH.md D-03):
```css
  --color-base-100: var(--mg-color-background);
  --color-base-200: var(--mg-color-surface-raised);
  --color-base-300: var(--mg-color-border);
  --color-base-content: var(--mg-color-text);
  --color-primary: var(--mg-color-accent);
  --color-primary-content: var(--mg-color-background);
  ...
```

**Non-color slots** (app.css lines 40-46 — copy verbatim, no `var()` rewrite):
```css
  --radius-selector: 0.25rem;
  --radius-field: 0.25rem;
  --radius-box: 0.5rem;
  --border: 1px;
  --depth: 0;
  --noise: 0;
```

---

### `mailglass_admin/test/mailglass_admin/accessibility_test.exs` (modified — test, transform)

**Analog:** itself — existing `contrast_ratio/2` and `luminance/1` (lines 72-100)

**Reusable private function signatures** (lines 72-100 — do NOT copy, they already exist):
```elixir
  defp contrast_ratio("#" <> _ = hex_a, "#" <> _ = hex_b) do ...
  defp luminance("#" <> hex) do ...
  defp parse_hex(<<r1, r2, g1, g2, b1, b2>>) do ...
  defp hex_pair(a, b) do ...
  defp linearize(c) do ...
```

**Existing describe block pattern** (lines 15-43 — copy structure for new blocks):
```elixir
  describe "canonical contrast pairs" do
    test "Ink on Paper — 15.9:1 (AA + AAA)" do
      assert contrast_ratio("#0D1B2A", "#F8FBFD") >= 15.0
    end
    ...
  end
```

**Borderline-pair pattern with upper bound** (lines 45-67 — copy for the decorative-border pinning):
```elixir
  describe "borderline pair (documents typography restriction)" do
    test "Glass on Paper is the borderline AA-body case ..." do
      ratio = contrast_ratio("#277B96", "#F8FBFD")
      assert ratio >= 4.5, "... ratio #{ratio} must clear the AA-body floor ..."
      assert ratio < 5.0, "... ratio #{ratio} unexpectedly exceeds 5.0 ..."
    end
  end
```

**New describe blocks to add** (from RESEARCH.md §accessibility_test.exs seam):
```elixir
  describe "dark-mode token fixes (TOKEN-03)" do
    test "muted text #B8CAD4 on Ink #0D1B2A — AA 4.5:1" do
      # Was Slate #5C6B7A = 3.18:1 (FAIL). Fix = --mg-color-text-muted #B8CAD4.
      assert contrast_ratio("#B8CAD4", "#0D1B2A") >= 4.5
    end

    test "error solid #E29089 on Ink #0D1B2A — AA 4.5:1" do
      # Was off-palette #D47368. Fix = --mg-color-error-solid #E29089.
      assert contrast_ratio("#E29089", "#0D1B2A") >= 4.5
    end

    test "primary-content Ink #0D1B2A on Ice #A6EAF2 — AA 4.5:1 (unchanged, regression pin)" do
      assert contrast_ratio("#0D1B2A", "#A6EAF2") >= 4.5
    end
  end

  describe "border role is intentionally sub-3:1 (WCAG 1.4.11 decorative exemption)" do
    test "light border #C7DCE5 on Paper #F8FBFD — decorative, exempt, pinned < 3.0" do
      # WCAG 1.4.11 applies to *control boundaries* only; decorative hairlines/dividers
      # are exempt. Pin sub-3.0 so a future contributor cannot silently darken the border
      # token to "fix" a false violation without explicit design approval.
      ratio = contrast_ratio("#C7DCE5", "#F8FBFD")
      assert ratio < 3.0,
             "Light border is intentionally decorative (sub-3:1). " <>
             "If this fails, the border token was darkened — requires explicit design approval."
    end

    test "dark border #315069 on Ink #0D1B2A — decorative, exempt, pinned < 3.0" do
      ratio = contrast_ratio("#315069", "#0D1B2A")
      assert ratio < 3.0,
             "Dark border is intentionally decorative (sub-3:1). Same exemption as light border."
    end
  end
```

---

### `mailglass_admin/test/mailglass_admin/brand_test.exs` (modified — test, file-I/O)

**Analog:** itself — lines 44-52 (three literal-hex assertions that will go red after var-rewrite)

**Lines to replace** (brand_test.exs lines 44-52 — current form that breaks):
```elixir
      assert lowered =~ "--color-base-100: #f8fbfd" or lowered =~ "--color-base-100:#f8fbfd",
             "mailglass-light --color-base-100 must map to Paper"

      assert lowered =~ "--color-primary: #277b96" or lowered =~ "--color-primary:#277b96",
             "mailglass-light --color-primary must map to Glass"

      assert lowered =~ "--color-base-content: #0d1b2a" or
               lowered =~ "--color-base-content:#0d1b2a",
             "mailglass-light --color-base-content must map to Ink"
```

**Replacement pattern** (two-tier per CONTEXT.md D-02 spec + brand_test.exs assertion style):
```elixir
      # After var-rewrite: assert the var reference in the theme block
      assert css =~ "--color-base-100: var(--mg-color-background)" or
               css =~ "--color-base-100:var(--mg-color-background)",
             "mailglass-light --color-base-100 must reference --mg-color-background"

      # And: assert the token value is inlined from brandbook/tokens.css
      assert String.downcase(css) =~ "--mg-color-background: #f8fbfd",
             "--mg-color-background token (#F8FBFD Paper) must be inlined in compiled CSS"

      assert css =~ "--color-primary: var(--mg-color-accent)" or
               css =~ "--color-primary:var(--mg-color-accent)",
             "mailglass-light --color-primary must reference --mg-color-accent"

      assert String.downcase(css) =~ "--mg-color-accent: #277b96",
             "--mg-color-accent token (#277B96 Glass) must be inlined in compiled CSS"

      assert css =~ "--color-base-content: var(--mg-color-text)" or
               css =~ "--color-base-content:var(--mg-color-text)",
             "mailglass-light --color-base-content must reference --mg-color-text"

      assert String.downcase(css) =~ "--mg-color-text: #0d1b2a",
             "--mg-color-text token (#0D1B2A Ink) must be inlined in compiled CSS"
```

**Untouched sections** (keep verbatim, zero edits):
- Lines 26-37: "brand palette hex values" describe block — still valid (the six hex values still appear in inlined `--mg-*` declarations)
- Lines 56-65: "mailglass-dark theme" describe block — `[data-theme=mailglass-dark]` selector check is compile-form only, unaffected
- Lines 68-82: "visual DON'Ts" describe block — `backdrop-filter`, `--depth: 0`, `--noise: 0` checks are unaffected

---

### `mailglass_admin/scripts/check-conformance.sh` (modified — shell-gate, request-response)

**Analog:** itself — line 45, TYPE-GATE grep pattern

**Current TYPE-GATE line** (line 45 — the only line to change):
```bash
if grep -rEn 'text-(sm|xs)\b|text-base($|[^-])' "$LIB" --include="*.ex" 2>/dev/null; then
```

**After extension** (D-07 — add `lg|xl|2xl|3xl|4xl|5xl` to the `\b` arm only):
```bash
if grep -rEn 'text-(sm|xs|lg|xl|2xl|3xl|4xl|5xl)\b|text-base($|[^-])' "$LIB" --include="*.ex" 2>/dev/null; then
```

**Critical constraints (from script's own comments):**
- The `text-base($|[^-])` arm is UNCHANGED — this is the Footgun-6 exclusion that prevents `text-base-content` from matching. The new size tokens all use `\b` which is correct and sufficient.
- The `echo "FAIL: TYPE-GATE..."` message on the next line stays unchanged.
- The `errors=$((errors + 1))` counter stays unchanged.
- The BADGE/BOLD/GAP/HEX gates are NOT touched.
- The new TYPE-lg/xl arm goes into the HARD script (this file), but the 5 known violations means this would fail — per D-08, the new TYPE-lg/xl and TRACK-GATE patterns are advisory only. Therefore: the `lg|xl|2xl|3xl|4xl|5xl` arm goes in `check-conformance-advisory.sh`, NOT in this hard script. This script's TYPE-GATE remains `text-(sm|xs)\b|text-base($|[^-])` only.

**No other changes** to this file (TRACK-GATE is advisory-only, goes in advisory script).

---

### `scripts/check_motion_conformance.sh` (modified — shell-gate, request-response)

**Analog:** itself — line 18, THRASH_PATTERN

**Current THRASH_PATTERN** (line 18 — the only line to change):
```bash
THRASH_PATTERN='transition-height|transition-max-height|transition-padding|transition-all|duration-[3-9][0-9][0-9]|duration-[0-9]{4,}'
```

**Extended THRASH_PATTERN** (D-07 — add layout-property transitions + arbitrary JIT form):
```bash
THRASH_PATTERN='transition-(height|max-height|padding|width|spacing|margin|inset|top|right|bottom|left)\b|transition-all|transition-\[(width|height|margin|padding|inset|top|right|bottom|left)|duration-[3-9][0-9][0-9]|duration-[0-9]{4,}'
```

**Pass B EASE_PATTERN** (line 28 — DO NOT CHANGE, D-07 "verify only, no change"):
```bash
EASE_PATTERN='ease-in-out|ease-linear|ease-in[^-]'
```
Note: `ease-in[^-]` already catches bare `ease-in` without matching `ease-in-out` or `--ease-in-out`. Verify and leave untouched.

**No other changes** to this file.

---

### `.github/workflows/ci.yml` (modified — CI-config, event-driven)

**Analog:** itself — lines 395-404, `credo_strict` job step sequence

**Current sequence** (lines 395-404 — the insertion context):
```yaml
      - name: Verify suppression docs (shell gate)
        run: bash scripts/check_credo_suppressions.sh
      - name: Verify motion conformance (shell gate)
        run: bash scripts/check_motion_conformance.sh
      - name: Run Credo strict
        run: mix credo --strict
```

**New steps to insert after line 402** (between motion step and Credo step — D-06, D-08):
```yaml
      - name: Verify design-system conformance (shell gate — hard-fail arms)
        # Wires the previously-DEAD check-conformance.sh (D-06, RATCHET-03).
        # Five hard-closed gates: BADGE / TYPE-base / BOLD / GAP / HEX.
        # Script is BASH_SOURCE-anchored — cwd-independent, run from repo root.
        run: bash mailglass_admin/scripts/check-conformance.sh
      - name: Verify design-system conformance (advisory arms — TYPE-lg/xl + TRACK)
        # Advisory until Phases 98/99 clean the 5 text-xl/lg and ~43 tracking-[0.08em] sites.
        # continue-on-error keeps main green; flip to hard-fail in Phase 99 plan.
        continue-on-error: true
        run: bash mailglass_admin/scripts/check-conformance-advisory.sh
```

**Step naming convention** (match existing steps in the job — "Verb noun (qualifier)"):
- "Verify suppression docs (shell gate)" → "Verify design-system conformance (shell gate — hard-fail arms)"
- `continue-on-error` key is at the step level, same indentation as `name` and `run`

**`support_contract_admin` job** (lines 576+): No structural changes. The parity test is wired via the `mix.exs` alias update only.

---

### `mailglass_admin/mix.exs` (modified — build-alias, transform)

**Analog:** itself — lines 189-191, `verify.support_contract.admin` alias

**Current alias** (lines 189-191):
```elixir
      "verify.support_contract.admin": [
        "test test/mailglass_admin/post_installer_smoke_test.exs test/mailglass_admin/operator_live_test.exs test/mailglass_admin/operator_trust_doc_test.exs test/mailglass_admin/stability_contract_test.exs test/mailglass_admin/router_test.exs test/mailglass_admin/auth_test.exs --warnings-as-errors"
      ],
```

**After update** (append `token_parity_test.exs` to the test path string):
```elixir
      "verify.support_contract.admin": [
        "test test/mailglass_admin/post_installer_smoke_test.exs test/mailglass_admin/operator_live_test.exs test/mailglass_admin/operator_trust_doc_test.exs test/mailglass_admin/stability_contract_test.exs test/mailglass_admin/router_test.exs test/mailglass_admin/auth_test.exs test/mailglass_admin/token_parity_test.exs --warnings-as-errors"
      ],
```

**Note:** `accessibility_test.exs` and `brand_test.exs` are NOT in this alias (they run in the broader `verify.preview` suite). Only the new parity test joins the required support-contract lane.

---

## Shared Patterns

### Compiled-bundle read seam
**Source:** `mailglass_admin/test/mailglass_admin/brand_test.exs` lines 15-23
**Apply to:** `token_parity_test.exs` (new file) — copy this exact path construction verbatim
```elixir
@css_path Path.join([
            Application.app_dir(:mailglass_admin, "priv"),
            "static",
            "app.css"
          ])

setup do
  css = File.read!(@css_path)
  {:ok, css: css}
end
```

### BASH_SOURCE anchor pattern (cwd-independence)
**Source:** `mailglass_admin/scripts/check-conformance.sh` lines 22-24
**Apply to:** `check-conformance-advisory.sh` (new file) — copy verbatim
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${SCRIPT_DIR}/../lib"
[[ -d "$LIB" ]] || { echo "FAIL: lib dir not found at $LIB" >&2; exit 2; }
```

### Fail-closed error counting pattern
**Source:** `mailglass_admin/scripts/check-conformance.sh` lines 25, 84-89
**Apply to:** Hard gates in `check-conformance.sh` (unchanged). Do NOT use in advisory script.
```bash
errors=0
# ... each gate: errors=$((errors + 1))
if [[ $errors -gt 0 ]]; then
  echo "FAIL: design-system conformance violations found ($errors gate(s) failed)" >&2
  exit 1
fi
echo "OK: design-system conformance clean."
```

### Test failure message naming the fix
**Source:** `mailglass_admin/test/mailglass_admin/bundle_test.exs` lines 23-25
**Apply to:** All assertions in `token_parity_test.exs`
Pattern: `"<what failed>; <self-serve fix command>"` — never just assert without a message.

### `use ExUnit.Case, async: true`
**Source:** All three existing test analogs (brand_test.exs line 13, accessibility_test.exs line 13, bundle_test.exs line 13)
**Apply to:** `token_parity_test.exs` — always `async: true` (pure file I/O, no DB/port)

---

## No Analog Found

None. All 8 files have direct analogs in the codebase. All patterns are extend-in-place or copy-from-sibling.

---

## Metadata

**Analog search scope:** `mailglass_admin/test/mailglass_admin/`, `mailglass_admin/scripts/`, `scripts/`, `mailglass_admin/assets/css/`, `mailglass_admin/mix.exs`, `.github/workflows/ci.yml`
**Files read:** 9 source files (brand_test.exs, bundle_test.exs, accessibility_test.exs, check-conformance.sh, check_motion_conformance.sh, ci.yml, mix.exs, app.css, plus CONTEXT.md + RESEARCH.md as upstream inputs)
**Pattern extraction date:** 2026-06-13
