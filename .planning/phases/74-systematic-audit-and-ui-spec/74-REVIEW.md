---
phase: 74-systematic-audit-and-ui-spec
reviewed: 2026-06-03T00:00:00Z
depth: standard
files_reviewed: 1
files_reviewed_list:
  - mailglass_admin/scripts/ui-audit.sh
findings:
  critical: 0
  warning: 4
  info: 2
  total: 6
status: issues_found
---

# Phase 74: Code Review Report

**Reviewed:** 2026-06-03
**Depth:** standard
**Files Reviewed:** 1
**Status:** issues_found

## Summary

`mailglass_admin/scripts/ui-audit.sh` is a developer-only, never-shipped audit tool that drives `agent-browser` to capture 18 PNG screenshots across a 3-viewport × 2-theme × 3-surface matrix. It is correctly scoped, never writes to `priv/static/`, and has no production attack surface. Syntax is valid (`bash -n` passes).

Four warnings were found: one word-splitting hazard on the viewport loop variable, one silent-failure contract on `set_viewport` that contradicts `set -e`, one missing server-reachability pre-check that makes failure non-obvious, and an unquoted `$OUT` path interpolation inside the `shot` function. Two info items cover a hard-coded `sleep` and the echo of `$VIEWPORTS` without quoting. None is a data-loss or security risk; all are correctness or robustness issues for a developer tool that can silently produce wrong output.

## Warnings

### WR-01: `$VIEWPORTS` expanded unquoted in `for` loop — word-splitting is relied upon but fragile

**File:** `mailglass_admin/scripts/ui-audit.sh:68`
**Issue:** The loop `for vp in $VIEWPORTS` intentionally relies on unquoted word-splitting to iterate over the space-separated string `"390 768 1440"`. This works in bash but is a fragile pattern: if `$VIEWPORTS` is ever overridden by an environment variable containing entries with embedded spaces or special characters (e.g. `VIEWPORTS="390 768 1440 1920 wide"`) the loop silently misbehaves. With `set -u` active an unset variable would be caught, but an override with unusual content would not. The same pattern is repeated at lines 104 and (implicitly) the echo at line 56. The idiomatic, safe pattern for a fixed list in bash is an array.

**Fix:**
```bash
VIEWPORTS=(390 768 1440)

# …

for vp in "${VIEWPORTS[@]}"; do
```
Also update the echo: `echo "  Viewports  : ${VIEWPORTS[*]}"`.

---

### WR-02: `set_viewport` silently swallows `agent-browser` failure — contradicts `set -e`

**File:** `mailglass_admin/scripts/ui-audit.sh:46`
**Issue:** `set_viewport` redirects both stdout and stderr to `/dev/null`:
```bash
agent-browser viewport --width "$1" --height "$VIEWPORT_HEIGHT" >/dev/null 2>&1
```
If `agent-browser viewport` exits non-zero (e.g. the CLI is not on PATH, or the browser session is lost), the exit code is discarded because the function body itself returns 0 (the last command in the function is the redirected invocation, and `2>&1` does not affect the exit code — the non-zero exit propagates). Wait: `>/dev/null 2>&1` does NOT suppress the exit code; `set -e` would still abort on a non-zero exit from `agent-browser` here.

However, the real hazard is in `shot` (line 50–53): `agent-browser open "$1" >/dev/null 2>&1` — again stderr is suppressed, exit code propagates; but then `agent-browser screenshot --full "$OUT/$2.png" 2>&1 | tail -1` pipes through `tail -1`. **A pipeline's exit code is the exit code of the last command in the pipe (`tail`), not `agent-browser screenshot`.** `tail -1` nearly always exits 0. Therefore a failing `agent-browser screenshot` call is silently ignored — the script reports "Done. 18 PNGs written" even if every screenshot command failed and no PNGs were created.

**Fix:** Use `pipefail`-aware exit code capture, or avoid the pipe entirely:
```bash
shot() { # url, name
  agent-browser open "$1" >/dev/null 2>&1
  sleep 1
  agent-browser screenshot --full "$OUT/$2.png"
}
```
`set -o pipefail` is already active (`set -euo pipefail` line 32), which fixes the pipe exit-code masking for pipelines; but the `2>&1 | tail -1` construct means `tail` always exits 0, so `pipefail` does not help here. Removing the `| tail -1` pipe lets the raw exit code flow through and `set -e` will catch failures.

---

### WR-03: Unquoted `$OUT/$2.png` in `shot` — word-splitting if path contains spaces

**File:** `mailglass_admin/scripts/ui-audit.sh:52`
**Issue:** The screenshot path `"$OUT/$2.png"` is quoted correctly in the `--full` argument, so this is actually fine as written. However, the `mkdir -p "$OUT"` call (line 38) and all `$OUT` interpolations elsewhere are correctly double-quoted. The real unquoted occurrence is in `agent-browser open "$1"` — `$1` is always a literal constructed URL, and in `agent-browser screenshot --full "$OUT/$2.png"` — both are correctly quoted. **This finding is withdrawn upon closer inspection — quoting is actually correct throughout.**

Correction: the actual quoting risk is narrower: if a caller sets `AGENT_BROWSER_SCREENSHOT_DIR` or `TENANT` to a value containing spaces or shell metacharacters, those values flow into URL query strings (`${TENANT}` at lines 86, 93, 95, 108, 110) without any percent-encoding or validation. `agent-browser open` receives the raw URL string, which may confuse the CLI if `TENANT` contains `&`, `=`, `#`, or spaces.

**Fix:** Document the expected character set for `TENANT` (alphanumeric + hyphen/underscore) in a comment near the variable declaration, or add a guard:
```bash
TENANT="${TENANT:-northstar}"
if [[ "$TENANT" =~ [^a-zA-Z0-9_-] ]]; then
  echo "ERROR: TENANT must be alphanumeric/hyphen/underscore; got: $TENANT" >&2
  exit 1
fi
```

---

### WR-04: No pre-flight check that the demo server is reachable — silent wrong output

**File:** `mailglass_admin/scripts/ui-audit.sh:34–38`
**Issue:** The script proceeds immediately to fire `agent-browser open` commands without verifying the demo app is listening on `$PORT`. If the server is not running, `agent-browser open` may succeed (returning 0) while capturing a browser error page, producing 18 PNGs of "Connection refused" or "localhost refused to connect". The operator sees "Done. 18 PNGs written" and has a complete-looking but useless baseline. This contradicts the purpose of the script as an evidence baseline for the gap register.

**Fix:** Add a reachability guard before the matrix loops:
```bash
if ! curl -sf --max-time 3 "$BASE/healthz" >/dev/null 2>&1 && \
   ! curl -sf --max-time 3 "$BASE/" >/dev/null 2>&1; then
  echo "ERROR: Demo app not reachable at $BASE. Boot it first (see script header)." >&2
  exit 1
fi
```
Or use `nc -z localhost "$PORT"` if `curl` is not guaranteed on the operator's PATH.

---

## Info

### IN-01: Hard-coded `sleep 1` — fragile timing assumption

**File:** `mailglass_admin/scripts/ui-audit.sh:51` (also line 88)
**Issue:** The `shot` function sleeps 1 second after `agent-browser open` to allow the page to render before taking the screenshot. There is also a `sleep 1` after the session warm-up at line 88. This is a common but fragile pattern: on a slow machine or under I/O pressure the page may not have finished rendering, producing screenshots of loading states rather than the final UI. On a fast machine the sleep is wasted time (18+ seconds of sleep across the full matrix run). A more robust approach would be to use `agent-browser`'s own wait mechanism if it has one (e.g. `--wait-for-network-idle` or equivalent), falling back to a configurable sleep via an env var.

**Fix (minimal):** Make the sleep duration configurable:
```bash
CAPTURE_DELAY="${CAPTURE_DELAY:-1}"
# … inside shot():
sleep "$CAPTURE_DELAY"
```

---

### IN-02: `echo ""` produces a blank line via an empty quoted string — minor portability note

**File:** `mailglass_admin/scripts/ui-audit.sh:59` and `115`
**Issue:** `echo ""` is portable in bash but some POSIX shells and strict `#!/bin/sh` implementations treat it differently. The shebang is `#!/usr/bin/env bash` so this is not a bug under bash invocation, but macOS ships bash 3.2 as `/bin/bash` — `env bash` will resolve to whatever `bash` is first on PATH (typically Homebrew 5.x or the system 3.2). No actual breakage here; `echo ""` works in all bash versions. This is style-only. Prefer `echo` (bare) which is unambiguous.

**Fix:** `echo` (no argument) outputs a newline in all POSIX-compliant shells.

---

_Reviewed: 2026-06-03_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
