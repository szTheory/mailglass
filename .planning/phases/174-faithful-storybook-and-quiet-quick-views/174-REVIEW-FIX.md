---
phase: 174-faithful-storybook-and-quiet-quick-views
reviewed: 2026-10-27T11:32:12Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - mailglass_admin/e2e/flows.spec.js
  - mailglass_admin/lib/mailglass_admin/inbound_live.ex
  - reference/demo_app/assets/scripts/check-demo-browser-evidence.cjs
  - reference/demo_app/assets/scripts/check-demo-browser-evidence.test.cjs
  - reference/demo_app/assets/scripts/evidence-output-path.cjs
  - reference/demo_app/assets/scripts/evidence-output-path.test.cjs
  - scripts/check_phase174_evidence.cjs
  - scripts/check_phase174_evidence.test.cjs
  - scripts/run_demo_browser_evidence.sh
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
status: clean
---

# Phase 174: Code Review Fix Verification

**Reviewed:** 2026-10-27T11:32:12Z  
**Depth:** standard, focused on the three findings in `174-REVIEW.md` and regressions introduced by commit `18c6cf32cc25d531dd8f7c85d62f3b852606e2e5`  
**Files Reviewed:** 9  
**Status:** clean

## Summary

All three original findings are fixed in the current source. The reviewed changes close the symlink escape, direct focus into inbound full detail, and include the missing route and Storybook inputs in the source digest. No new critical or warning findings were identified in the repair.

## Original Finding Verification

### CR-01: FIXED — Symlinked evidence path can delete data outside the evidence root

`reference/demo_app/assets/scripts/evidence-output-path.cjs:8-26` keeps the lexical root-boundary check and then `lstat`s every absolute path component, rejecting symlinks including those in the evidence root and candidate's parents. `scripts/run_demo_browser_evidence.sh:31-40` validates the run-owned path before creating its directory. The evidence checker validates its root and `retained` destination before staging at `reference/demo_app/assets/scripts/check-demo-browser-evidence.cjs:358-362`; it archives prior retained evidence with a rename rather than recursive deletion at lines 371-380. Checkpoint writes use `O_NOFOLLOW` at lines 395-412. The added tests verify parent and retained symlink rejection, preserve outside markers, and preserve prior retained evidence (`reference/demo_app/assets/scripts/evidence-output-path.test.cjs:17-45`).

### WR-01: FIXED — Inbound full-detail transition returns focus to a hidden row

The full-detail back link now has the stable `inbound-detail-back` ID and runs `JS.focus` when mounted (`mailglass_admin/lib/mailglass_admin/inbound_live.ex:595-608`). The existing quick-view removal focus behavior remains for closing the overlay (`mailglass_admin/lib/mailglass_admin/inbound_live.ex:797-808`). The browser flow now verifies that opening full detail focuses its back link, and returning to quick view focuses the close control (`mailglass_admin/e2e/flows.spec.js:1809-1815`).

### WR-02: FIXED — Source digest omits changed route and story inputs

`scripts/check_phase174_evidence.cjs:72-99` now explicitly includes the router, page controller, theme-picker story, inbound route implementation and records list, asset controller, Persona scenario source, and admin flow inputs. Its quick-view Storybook glob now matches `.exs` as well as `.ex` and `.heex` at lines 169-179. `computeSourceIdentity` hashes the selected files' current bytes at lines 182-200. The added test asserts the six previously missing route/story sources are selected and that changing each one's bytes changes the digest while the revision stays fixed (`scripts/check_phase174_evidence.test.cjs:591-616`).

## New Findings

None.

---

_Reviewed: 2026-10-27T11:32:12Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard, focused follow-up_
