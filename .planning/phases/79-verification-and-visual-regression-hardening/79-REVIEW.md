---
phase: 79-verification-and-visual-regression-hardening
reviewed: 2026-06-04T00:00:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - mailglass_admin/docs/design-system.md
  - mailglass_admin/e2e/operator.spec.js
  - mailglass_admin/scripts/check-conformance.sh
  - mailglass_admin/test/support/endpoint_case.ex
  - mailglass_admin/test/support/operator_fixtures.ex
  - mailglass_inbound/mix.exs
findings:
  critical: 0
  warning: 4
  info: 3
  total: 7
status: issues_found
---

# Phase 79: Code Review Report

**Reviewed:** 2026-06-04
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

Reviewed the Phase 79 source changes: a new design-system conformance shell
script, expanded Playwright e2e coverage, two test-support fixes
(`operator_fixtures.ex` jsonb[] cast, `endpoint_case.ex` empty-preview route),
an expanded design-system doc, and the `mailglass_inbound` exact-pin bump.

Several claims in the phase summaries were verified empirically rather than
trusted: the `operator_fixtures.ex` jsonb[] change was exercised directly
against the test repo (it inserts correctly — Postgrex handles `{:array, :map}`
columns natively, including empty-list defaults); the conformance script was
run from both the repo root and from inside `mailglass_admin/`; the
`preview_empty` session route was traced through `router.ex:298-301` to confirm
the empty-mailables override works; and the e2e row-index assumptions were
verified against the deterministic `desc: last_event_at, inserted_at, id`
ordering plus UUIDv7 monotonic ids.

**No blocking defects.** The fixture fix is correct (not a bug). The headline
concerns are in the conformance script — it has a false-negative blind spot, two
over-broad regexes, and silently passes when run from the wrong directory — plus
a release-process regression: the inbound pin bump used `chore` where every prior
sibling release used `fix(inbound)`, which will prevent the pin from shipping.

## Warnings

### WR-01: Conformance TYPE-GATE silently drops real violations on lines that also contain `text-base-content`

**File:** `mailglass_admin/scripts/check-conformance.sh:31`
**Issue:** The gate is `grep -rE 'text-(sm|base|xs)' ... | grep -v 'text-base-content'`.
The `grep -v` filters at the *line* level, not the *token* level. In HEEx,
`text-base-content` (the default text color) is routinely combined with a size
utility in the same `class` attribute. A genuine violation such as
`class="text-sm text-base-content"` or `<span class="text-xs font-bold text-base-content">`
is **silently dropped** because the whole line matches the `text-base-content`
exclusion. Verified:

```
$ printf 'class="text-sm text-base-content"\n' | grep -E 'text-(sm|base|xs)' | grep -v 'text-base-content'
(no output — exit 1 — violation MISSED)
```

This means the gate the script advertises (TYPE-GATE) can be bypassed by the
single most common color class in the codebase. The "Footgun-6 exclusion" comment
(lines 9-11, 26-30) documents the *intent* but the implementation over-reaches.
**Fix:** Exclude only the specific token, not the whole line. Use a negative
look-around-free approach with word boundaries, e.g.:
```bash
# match the size utilities only, and only as standalone tokens:
if grep -rEn 'text-(sm|base|xs)(\b|[^-])' "$LIB" --include="*.ex" 2>/dev/null \
     | grep -vE 'text-base-content'; then
```
Better: anchor the size match so `text-base-content` never matches the size
pattern in the first place (then no `grep -v` is needed):
```bash
grep -rEn 'text-(sm|xs)\b|text-base($|[^-])' "$LIB" --include="*.ex"
```

### WR-02: Conformance script silently false-passes when run from outside the monorepo root

**File:** `mailglass_admin/scripts/check-conformance.sh:15`
**Issue:** `LIB="mailglass_admin/lib"` is a path relative to the monorepo root.
`mailglass_admin` is its own Hex package with its own `mix.exs`; its CI lane very
plausibly runs with cwd = `mailglass_admin/`. From there the path resolves to the
non-existent `mailglass_admin/mailglass_admin/lib`. Each gate is wrapped in
`if grep ... 2>/dev/null; then` — grep against a missing directory prints its
error to the swallowed stderr and exits non-zero, so the `if` is false, no error
is counted, and the script prints **"OK: design-system conformance clean."** with
exit 0 while having scanned nothing. Verified:

```
$ cd mailglass_admin && bash scripts/check-conformance.sh
OK: design-system conformance clean.   # exit 0 — but LIB does not exist here
```

A conformance gate that passes by scanning zero files is worse than no gate.
**Fix:** Resolve `LIB` relative to the script location and assert the dir exists:
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${SCRIPT_DIR}/../lib"
[[ -d "$LIB" ]] || { echo "FAIL: lib dir not found at $LIB" >&2; exit 2; }
```

### WR-03: Inbound pin bump uses `chore` commit type — Release Please will not ship the `== 1.5.0` pin

**File:** `mailglass_inbound/mix.exs:116`
**Issue:** The `MIX_PUBLISH` branch pin was bumped `== 1.4.5` → `== 1.5.0` and
committed as `chore(79): bump mailglass_inbound exact-pin...` (commit `144e037d`).
Every prior sibling release bumped this exact line with a **`fix(inbound):`**
commit — verified in history:
```
fix(inbound): track mailglass core pin to == 1.4.5 for the 1.4.5 linked release
fix(inbound): track mailglass core pin to == 1.4.4 for the 1.4.4 linked release
fix(inbound): track mailglass core pin to == 1.4.3 ...
```
`mailglass_inbound` is NOT in the linked-versions group (only `mailglass` +
`mailglass_admin` are — `release-please-config.json`), so its version bump is
driven solely by its own releasable commits. A `chore` commit is neither a
version-bumping nor changelog-emitting conventional-commit type, so Release Please
will not open an inbound release PR. Result: core+admin ship 1.5.0, but the
published `mailglass_inbound` stays at 1.1.5 and continues to declare
`{:mailglass, "== 1.4.5"}` — adopters who upgrade core to 1.5.0 hit a dependency
conflict, which is precisely the failure this pin bump was meant to prevent. This
also contradicts the project memory note "inbound exact-pin needs manual
`fix(inbound)` bump each core release."
**Fix:** Re-commit the pin change (or add a follow-up commit) with an
inbound-scoped releasable type, matching the established convention:
```
fix(inbound): track mailglass core pin to == 1.5.0 for the 1.5.0 linked release
```

### WR-04: Conformance HEX-GATE and GAP-GATE regexes are over-broad (false-positive landmines)

**File:** `mailglass_admin/scripts/check-conformance.sh:47,55`
**Issue:** Two gates use unbounded numeric/hex patterns that match far more than
intended, so a future legitimate change will fail CI with a misleading message:

- **HEX-GATE** (`#[0-9a-fA-F]{3,6}`) matches any `#` followed by 3-6 hex-ish
  chars — including HTML anchor fragments and DOM id refs, e.g.
  `href="#abc123"`, `phx-value-id="#deadbeef"`. It also matches 4- and 5-char
  runs that are not valid CSS hex (valid CSS hex is exactly 3/4/6/8 digits), and
  has no word boundary so a brand-palette hex quoted in a `@moduledoc`
  (`#0D1B2A`) would also trip it. Verified all four benign strings above match.
- **GAP-GATE** (`gap-(3|4|6)`) has no trailing boundary, so it matches `gap-32`,
  `gap-64`, and `gap-3xl` — yet `--spacing-...3xl (…/32/48/64)` are documented
  design-system spacing tokens. Verified `gap-32`, `gap-64`, `gap-3xl` all match.

These do not fail on today's codebase, but as written they will produce false
failures and erode trust in the gate.
**Fix:** Add boundaries / restrict to valid forms:
```bash
# HEX-GATE: valid CSS hex only, not anchor fragments
grep -rEn 'color[^#]*#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})\b' "$LIB" --include="*.ex"
# GAP-GATE: standalone numeric gap tokens only
grep -rEn 'gap-(3|4|6)(\b|[^0-9a-z-])' "$LIB" --include="*.ex"
```

## Info

### IN-01: `preview_empty` route mutates session that persists across the redirect

**File:** `mailglass_admin/test/support/endpoint_case.ex:107-111`
**Issue:** `preview_empty/2` writes `put_session("mailables", [])` then redirects
to `/dev/mail/`. The `[]` session value persists in the cookie for the remainder
of that browser session and is honored by `__preview_session__/2`
(`router.ex:298-301`) on every subsequent preview load — `browser-login`/
`browser-reset` do not clear it. In the current e2e suite this is harmless
because Playwright gives each test a fresh browser context and the
preview-orientation test is terminal, but the route leaves the session in a
non-default state with no reset path. **Fix:** Document the one-shot intent in the
comment, or add a companion route that clears the key, so a future test that
reuses the context after this route isn't silently given empty mailables.

### IN-02: Magic timeout literal in the replay-completed timeline assertion

**File:** `mailglass_admin/e2e/operator.spec.js:128`
**Issue:** `{ timeout: 10000 }` is a bare magic number applied to a single
timeline assertion while every sibling assertion uses the default. If the replay
fan-out is genuinely slower than the default elsewhere, the other timeline
assertions on lines 129-131 will flake before this one's longer timeout helps.
**Fix:** Lift to a named constant (e.g. `const REPLAY_SETTLE_MS = 10_000;`) and
apply it consistently to the post-confirm timeline assertions, or remove it if
the default suffices.

### IN-03: design-system.md GAP-22 disposition straddles two phases without a single source of truth

**File:** `mailglass_admin/docs/design-system.md:171-178`
**Issue:** The GAP-22 note says it is "tracked as GAP-22 and deferred to Phase 79
(VERIF-04)" while also stating it is "held at severity 3 — it does not block Phase
79 closeout before the decision is reconfirmed there." This leaves the doc as the
de facto owner of an open deferral decision that the doc itself says must be
"reconfirmed" elsewhere. A doc is a poor home for an undecided disposition.
**Fix:** Point to the authoritative GAP register / closeout artifact
(`79-GAP-CLOSEOUT.md`) for the live disposition and keep the design-system doc to
the stable architectural statement ("relative asset URLs can load unstyled on a
hard refresh of a deep link; in-app navigation is unaffected").

---

_Reviewed: 2026-06-04_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
