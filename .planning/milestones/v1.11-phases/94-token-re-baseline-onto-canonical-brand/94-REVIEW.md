---
phase: 94-token-re-baseline-onto-canonical-brand
reviewed: 2026-06-13T19:45:11Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - .github/workflows/ci.yml
  - mailglass_admin/assets/css/app.css
  - mailglass_admin/mix.exs
  - mailglass_admin/scripts/check-conformance-advisory.sh
  - mailglass_admin/test/mailglass_admin/accessibility_test.exs
  - mailglass_admin/test/mailglass_admin/brand_test.exs
  - mailglass_admin/test/mailglass_admin/token_parity_test.exs
  - scripts/check_motion_conformance.sh
findings:
  critical: 0
  warning: 3
  info: 4
  total: 7
status: issues_found
---

# Phase 94: Code Review Report

**Reviewed:** 2026-06-13T19:45:11Z
**Depth:** standard
**Files Reviewed:** 8
**Status:** issues_found

## Summary

This phase re-baselines the admin daisyUI theme blocks onto `brandbook/tokens.css`
via `@import` + `var(--mg-*)` references (no raw hex in theme selectors), tightens
two shell conformance gates, wires a previously-dead hard-fail conformance gate plus
a new advisory gate into CI, and adds contrast/parity ExUnit coverage.

Verification performed (not assumed):

- **All 20 new/changed tests pass** — ran `accessibility_test.exs`, `brand_test.exs`,
  `token_parity_test.exs` against the committed bundle: `20 tests, 0 failures`.
- **Contrast math independently reproduced** — every accessibility assertion holds
  (e.g. Glass-on-Paper = 4.635, inside the asserted `4.5 ≤ r < 5.0` band; both
  decorative-border pairs verified `< 3.0`).
- **Parity oracle chain independently reproduced** — `{palette.*}` alias resolution
  from `tokens.json` matches the inlined bundle values for both tiers, including
  `#fff` shorthand normalization (`#fff` ↔ `#FFFFFF`).
- **All three shell gates run green** from the repo root, and the new motion regex
  was fuzzed against legit Tailwind tokens (`transition-transform`, `transition-colors`,
  `transition-[transform]`, `duration-150/200`) with zero false positives and correct
  matches on the newly-banned tokens.
- **Bundle is not stale** — the 1-line `priv/static/app.css` diff is the expected shape
  for a 2-line minified file (whole second line replaced); the bundle contains both the
  `var(--mg-*)` references and the inlined `#f8fbfd`/`#fff` values, confirming a real rebuild.

No correctness, security, or data-loss defects found. The findings below are robustness
and accuracy gaps in the conformance tooling and stale documentation/comments.

## Warnings

### WR-01: Conformance gates silently skip the two `.heex` layout files

**File:** `mailglass_admin/scripts/check-conformance-advisory.sh:34,43` (and the same pattern in `scripts/check_motion_conformance.sh:19,29`)
**Issue:** Both grep arms use `--include="*.ex"` and the companion `check-conformance.sh`
states in its header comment "no `.heex` partials exist in this codebase." That claim is
**false**: `lib/mailglass_admin/layouts/root.html.heex` and
`lib/mailglass_admin/layouts/app.html.heex` exist and are real, rendered layout templates
(added in commit `134fe516`). Any banned token (`text-xl`, `tracking-[…]`, `font-semibold`,
hard-coded hex, `transition-height`, `ease-in-out`, etc.) introduced into either `.heex`
file will pass every conformance gate undetected. I confirmed there are currently **zero**
violations in those files, so this is a latent coverage gap rather than an active escape —
but the gate advertises protection it does not provide, which is exactly the silent-drift
failure mode the BASH_SOURCE-anchoring fix (WR-02 in `check-conformance.sh`) was added to prevent.
**Fix:** Broaden the include in the in-scope new/modified scripts to cover HEEx templates:
```bash
# advisory + motion gates: scan both .ex and .heex
grep -rEn 'text-(lg|xl|2xl|3xl|4xl|5xl)\b' "$LIB" --include="*.ex" --include="*.heex" 2>/dev/null
```
and correct the stale "no `.heex` partials exist" comment.

### WR-02: `extract_mg_token_value(:dark)` truncates on the first `}` — brittle against daisyUI output shape

**File:** `mailglass_admin/test/mailglass_admin/token_parity_test.exs:190`
**Issue:** The dark-tier extractor anchors on `~r/\[data-theme=dark\]\{([^}]+)\}/`. `[^}]+`
captures up to the **first** closing brace, which is only correct because daisyUI 5 currently
emits the `[data-theme=dark]` token block as a single flat declaration list with no nested
`{}`. If a future daisyUI/Tailwind version emits a nested rule (e.g. an `@supports` or nested
selector) inside that block, the capture truncates and `extract_mg_token_value` silently
returns `nil` for any token defined after the truncation point — which the parity reducer then
reports as "not found as inlined declaration" (a confusing failure that points the maintainer
at the wrong cause: "run mix ...assets.build" when the real issue is a bundle-structure change).
Verified the current bundle's dark block is 1230 chars and matches cleanly, so this is forward-fragility,
not a present failure.
**Fix:** Either pin the assumption with an explicit assertion (fail loudly with a structure-changed
message), or extract the dark block by locating the selector start and balancing braces. Minimal hardening:
```elixir
# After Regex.run, assert the block actually contains the token we expect,
# so a structure change surfaces as "dark block shape changed" not "token missing".
```

### WR-03: `set -euo pipefail` + the unconditional `exit 0` make the advisory gate's pipefail ineffective

**File:** `mailglass_admin/scripts/check-conformance-advisory.sh:21,48`
**Issue:** The script declares `set -euo pipefail` but ends with an unconditional `exit 0`,
and CI additionally wraps the step in `continue-on-error: true` (ci.yml:411). This is
defensible by design (the script is purely advisory), but the `set -e`/`pipefail` is then
dead protection: a genuine grep error (exit 2, e.g. unreadable file) inside an `if grep ...`
is consumed by the `if` and the script still prints "OK ... complete" and exits 0. The one
real safety check that does work is the `[[ -d "$LIB" ]] || exit 2` dir guard. The risk is
low (advisory only), but the script presents stronger guarantees than it delivers, and when
Phase 99 flips this to hard-fail (per the header TODO) this latent gap becomes a correctness
gap. The flip instructions in the header (remove `exit 0`, add the error counter) should also
ensure grep-error (exit ≥2) is distinguished from grep-no-match (exit 1).
**Fix:** When converting to hard-fail in Phase 99, treat grep exit codes explicitly:
```bash
grep -rEn '...' "$LIB" --include="*.ex" --include="*.heex"; rc=$?
[[ $rc -eq 0 ]] && { echo "FAIL: ..." >&2; errors=$((errors+1)); }
[[ $rc -ge 2 ]] && { echo "FAIL: grep error scanning $LIB" >&2; exit 2; }
```

## Info

### IN-01: `scripts/check_motion_conformance.sh` is cwd-dependent while sibling gates are BASH_SOURCE-anchored

**File:** `scripts/check_motion_conformance.sh:12-13`
**Issue:** This gate uses repo-root-relative paths (`LIB="mailglass_admin/lib"`,
`CSS="mailglass_admin/assets/css/app.css"`) and silently scans nothing / errors if run from
any other cwd (confirmed: `bash scripts/check_motion_conformance.sh` from inside `mailglass_admin/`
fails with "No such file or directory"). The two `check-conformance*.sh` scripts deliberately
anchor to `BASH_SOURCE` to be cwd-independent (their header calls this out as the WR-02 fix).
The inconsistency is a footgun for local runs. CI invokes it correctly from repo root, so this
is not a CI defect.
**Fix:** Anchor `LIB`/`CSS` to `$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)` for parity
with the other gates, and assert the dirs/files exist.

### IN-02: New motion `THRASH_PATTERN` admits non-existent Tailwind tokens (harmless over-breadth)

**File:** `scripts/check_motion_conformance.sh:18`
**Issue:** The expanded alternation includes `transition-spacing`, which is not a real Tailwind
utility, and the arbitrary-value arm `transition-\[(width|height|...)` will also match inside
multi-property arbitrary values like `transition-[width,opacity]` (which contains a banned
property and is correctly banned, but also `transition-[opacity,width]` would match — intended).
No false positives were observed against the legit token set. This is cosmetic over-breadth,
not a correctness issue.
**Fix:** Optional — drop `spacing` from the property list (Tailwind has no `transition-spacing`),
or leave as a defensive superset.

### IN-03: Bundle-dependent tests couple ExUnit pass/fail to a generated artifact excluded from review

**File:** `mailglass_admin/test/mailglass_admin/brand_test.exs:21-24`, `token_parity_test.exs:88-91`
**Issue:** Both suites `File.read!` the compiled `priv/static/app.css` and assert on its content.
This is the intended design (TOKEN-04 fail-closed parity), and the `verify.preview` alias plus
the `git diff --exit-code priv/static/` gate guard against stale bundles. Noting for downstream
awareness only: a hand-edit or missed rebuild of the (review-excluded) bundle would surface here
rather than in the source files under review. The tests' own failure messages already direct the
maintainer to `mix mailglass_admin.assets.build`, which is the right remediation.
**Fix:** None required — documented for traceability.

### IN-04: Stale `@version "1.6.2"` / `== 1.6.2` self-reference in admin `mix.exs` (repo-artifact milestone)

**File:** `mailglass_admin/mix.exs:4,143`
**Issue:** The only change to `mix.exs` this phase was a 1-line edit; `@version` remains `1.6.2`
and `mailglass_dep/0` pins `{:mailglass, "== 1.6.2"}`. This is consistent with the project's
"repo-artifact milestones only, no Hex release since 1.6.2" posture (per CLAUDE.md / MEMORY),
and release-please owns the bump, so it is correct for this phase. Flagged only so a future
reviewer does not mistake the unbumped version for an oversight.
**Fix:** None — version bump is release-please's responsibility, not this phase's.

---

_Reviewed: 2026-06-13T19:45:11Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
