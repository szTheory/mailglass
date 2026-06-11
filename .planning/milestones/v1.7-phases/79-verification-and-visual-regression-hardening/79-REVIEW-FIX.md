---
phase: 79-verification-and-visual-regression-hardening
fixed_at: 2026-06-04T00:00:00Z
review_path: .planning/phases/79-verification-and-visual-regression-hardening/79-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 3
skipped: 1
status: all_fixed
---

# Phase 79: Code Review Fix Report

**Fixed at:** 2026-06-04
**Source review:** .planning/phases/79-verification-and-visual-regression-hardening/79-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope (Critical + Warning): 4
- Fixed: 3 (WR-01, WR-02, WR-04)
- Skipped: 1 (WR-03 — already resolved by a prior commit, no-op)

All three actionable conformance-script warnings were fixed in
`mailglass_admin/scripts/check-conformance.sh`. Each fix was validated by running
the script from BOTH the repo root and from inside `mailglass_admin/`, confirming
it still passes clean on today's codebase, plus targeted negative tests proving
each gate now catches the violation it used to miss (WR-01) and no longer
false-fails on valid tokens (WR-04). WR-03 was verified already resolved.

## Fixed Issues

### WR-02: Conformance script silently false-passes when run from outside the monorepo root

**Files modified:** `mailglass_admin/scripts/check-conformance.sh`
**Commit:** 55e2baa0
**Applied fix:** Replaced the cwd-relative `LIB="mailglass_admin/lib"` with a
script-relative resolution anchored on `BASH_SOURCE`
(`SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; LIB="${SCRIPT_DIR}/../lib"`)
and a `[[ -d "$LIB" ]] || { echo "FAIL: lib dir not found..." >&2; exit 2; }`
fail-loud assertion. The gate is now cwd-independent. Verified: previously
`cd mailglass_admin && bash scripts/check-conformance.sh` printed "clean" while
scanning zero files; it now resolves the real lib dir and passes legitimately
from both locations.

### WR-01: TYPE-GATE silently drops violations on lines that also contain `text-base-content`

**Files modified:** `mailglass_admin/scripts/check-conformance.sh`
**Commit:** c2bd04c3
**Applied fix:** Removed the line-level `| grep -v 'text-base-content'` exclusion
and replaced the gate with an anchored pattern that cannot match
`text-base-content` in the first place:
`grep -rEn 'text-(sm|xs)\b|text-base($|[^-])'`. `text-sm`/`text-xs` are matched
as whole tokens; `text-base` matches only when NOT followed by a hyphen (so
`text-base-content` is excluded while the raw `text-base` size utility is still
caught). Verified: a probe containing `class="text-sm text-base-content"` (the
exact case the old gate missed) now fails the gate, while the real codebase —
which uses `text-base-content` on dozens of lines — stays clean.

### WR-04: HEX-GATE and GAP-GATE regexes are over-broad (false-positive landmines)

**Files modified:** `mailglass_admin/scripts/check-conformance.sh`
**Commit:** 65c31a39
**Applied fix:** Two gates bounded:
- **GAP-GATE:** added a trailing boundary —
  `grep -rEn 'gap-(3|4|6)([^0-9a-z-]|$)'` — so `gap-32`, `gap-64`, and `gap-3xl`
  (valid documented `--spacing-...3xl/32/64` tokens) no longer trip while the
  off-grid `gap-3`/`gap-4`/`gap-6` tokens still do.
- **HEX-GATE:** scoped to a color context and valid CSS hex lengths —
  `grep -rEn 'color[^#]*#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})\b'` — so anchor
  fragments / DOM id refs (`href="#abc123"`, `phx-value-id="#deadbeef"`) and
  4-/5-char runs no longer false-fail, while a genuine `color: #0D1B2A` literal
  is still caught.

Verified with four probes: documented gap tokens pass, real off-grid gap fails,
anchor/id fragments pass, real color hex fails. The real codebase has no `#`
tokens in `lib/` and stays clean.

## Skipped Issues

### WR-03: Inbound pin bump uses `chore` commit type — Release Please will not ship the `== 1.5.0` pin

**File:** `mailglass_inbound/mix.exs:116`
**Reason:** Already resolved — no fix needed (no-op). The follow-up commit
`80321bb7 fix(inbound): track mailglass core pin to == 1.5.0 for the 1.5.0
linked release` was made after the original `chore` commit `144e037d`, supplying
the releasable `fix(inbound):` conventional-commit type the review asked for.
Verified directly: `mailglass_inbound/mix.exs:121` already reads
`{:mailglass, "== 1.5.0"}` and the `fix(inbound)` commit is present in history.
Making a new commit would be a redundant no-op, so this finding is recorded as
already-fixed rather than re-committed.

**Original issue:** The `MIX_PUBLISH` pin was bumped `== 1.4.5` → `== 1.5.0` and
committed as `chore(79):`, but `chore` is not a version-bumping/changelog-emitting
conventional-commit type, so Release Please would not open an inbound release PR —
leaving published `mailglass_inbound` declaring a stale `== 1.4.5` pin against a
1.5.0 core. The follow-up `fix(inbound)` commit closed this.

---

_Fixed: 2026-06-04_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
