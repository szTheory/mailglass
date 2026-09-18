---
phase: 167-truthful-documentation-and-the-standing-control
reviewed: 2026-09-18T13:45:33Z
depth: standard
files_reviewed: 10
files_reviewed_list:
  - scripts/check_state_md_pr_refs.sh
  - lib/mailglass/config.ex
  - lib/mailglass/outbound.ex
  - test/mailglass/state_md_contract_test.exs
  - test/mailglass/docs_contract_test.exs
  - test/mailglass/config_test.exs
  - config/test_exceptions.exs
  - mix.exs
  - .github/workflows/release-please.yml
  - .github/dependabot.yml
findings:
  critical: 0
  warning: 2
  info: 1
  total: 3
status: issues_found
---

# Phase 167: Code Review Report

**Reviewed:** 2026-09-18T13:45:33Z
**Depth:** standard
**Files Reviewed:** 10
**Status:** issues_found

## Summary

Reviewed the executable/logic surface of Phase 167: the new `scripts/check_state_md_pr_refs.sh` live-audit script, the `css_inliner: :none` schema-narrowing change in `lib/mailglass/config.ex`, the moduledoc-only edit to `lib/mailglass/outbound.ex`, the new `test/mailglass/state_md_contract_test.exs`, the heavily-extended `test/mailglass/docs_contract_test.exs`, `test/mailglass/config_test.exs`, `config/test_exceptions.exs`, `mix.exs`, and the `release-please.yml` sed-sync loop plus `dependabot.yml` grouping change.

Overall this is careful, well-tested work: every new docs-contract assertion is pinned against a real source artifact (`mix.exs` `@version`, `mailable.ex`'s actual `__using__` block, `release-please-config.json`'s `exclude-paths` array) rather than a hardcoded literal, which is exactly the anti-drift pattern the milestone is chasing. I ran `mix test test/mailglass/config_test.exs test/mailglass/state_md_contract_test.exs` — 30/30 pass, confirming the baseline. Verified via `git diff` and `grep` that:
- `lib/mailglass/outbound.ex`'s diff is moduledoc-only (no code lines changed).
- `css_inliner: :none` has zero remaining references outside `lib/mailglass/config.ex` and `test/mailglass/config_test.exs` (the blast-radius precondition the plan required).
- the `release-please.yml` sed expressions target distinct, non-overlapping literal prefixes (`{:mailglass,` vs `{:mailglass_admin,`) and `SYNC_PATHS` is consistent with every file the sed loop touches.
- `.github/dependabot.yml`'s `mix-minor-patch` grouping + `open-pull-requests-limit: 3` is applied uniformly across all three mix ecosystems.

The one file with a real, demonstrable defect is the new shell script — its per-reference "which STATE.md line asserts this PR's state" lookup uses an unanchored substring match that is inconsistent with the (correctly anchored) reference-extraction pass earlier in the same script, and can misattribute a reference's prose to a different reference's line under number-prefix collisions. It does not currently misfire against the live `.planning/STATE.md` content (verified: no such collision exists in today's reference set), but it is a latent correctness gap in a script whose explicit job is "a genuine contradiction must never silently resolve as `pass`."

## Warnings

### WR-01: Unanchored substring match in check_state_md_pr_refs.sh can misattribute a reference to the wrong line, silently producing a false "pass"

**File:** `scripts/check_state_md_pr_refs.sh:176`
**Issue:** The reference-extraction pass (lines 68-106) correctly anchors `#NNN` tokens so `#26` can never match inside `#260`. But the later per-reference line lookup does not reuse that anchoring:

```bash
line_with_ref=$(grep -n "$name" "$target" | head -1 | cut -d: -f2- || true)
```

`grep -n "$name"` (plain BRE, no `-w`/anchors) treats `#26` as a substring, so it also matches a line containing `#260`, `#267`, etc. `head -1` takes whichever line appears first in the file — which may not be `#26`'s own line.

Demonstrated repro:
```bash
$ printf 'PR #260 is closed and archived.\nPR #26 is open and being tracked.\n' > f.md
$ grep -n "#26" f.md | head -1
1:PR #260 is closed and archived.
```
If `#26`'s *own* line in `.planning/STATE.md` incorrectly says "open" (a real drift — GitHub actually shows it closed), but an earlier line mentioning `#260` (or any other ref sharing `26` as a numeric prefix) says "closed", the script reads the *wrong* line, sees `says_closed=true / says_open=false`, and — because live_state for `#26` really is `CLOSED` — reports `status: pass`. The genuine contradiction in `#26`'s actual sentence is never inspected. This directly violates the script's own documented invariant (comment block, lines 16-23): "a non-verdict must be observably distinct from a pass" — here a *wrong* verdict is indistinguishable from a correct pass.

This does not fire against the current `.planning/STATE.md` (verified — its live reference set is `#129, #222, #257, #260, #263, #266, #267`, none of which is a numeric prefix of another), so today's runs are safe. It will fire the moment two referenced numbers share a prefix relationship (e.g. `#26` and `#260`/`#266`/`#267` both appearing, or `#22` alongside `#222`/`#257`/etc. via any transposition) — plausible for a repo whose PR count is in the hundreds and climbing.

**Fix:** Reuse the same anchored extraction pattern used in Step 1, or add `-w`-equivalent boundaries around the literal `#`:
```bash
line_with_ref=$(grep -nE "(^|[^0-9])${name}([^0-9]|\$)" "$target" | head -1 | cut -d: -f2- || true)
```
(escape `$` appropriately inside the double-quoted heredoc/script). Better still: capture the line number already computed in Step 1's `lineno` for each `num_token`'s first occurrence, and reuse it directly instead of re-deriving it with a second, weaker grep.

### WR-02: `check_state_md_pr_refs.sh` overall exit code can mask a confirmed `blocked` verdict behind `cannot_check`

**File:** `scripts/check_state_md_pr_refs.sh:212-226`
**Issue:** Aggregation checks for `cannot_check` first and returns that as the overall status/exit code if *any* reference couldn't be resolved — even if another reference in the same run was independently confirmed `blocked` (a genuine contradiction). The per-line text/JSON output still names the blocked reference individually, so a human reading full output will see it, but a caller that only inspects the process exit code (`0`/`1`/`2`) — which is the documented three-way contract this script advertises — will see `2` (cannot_check) and may not surface the individually-blocked line, since `2` is documented as "gh unavailable/unparseable," not "at least one blocked + at least one unknown."
**Fix:** Either invert the precedence (blocked wins over cannot_check in the aggregate `overall`, since a confirmed defect is more actionable than an unresolved one), or introduce a fourth composite status (e.g. `blocked_and_cannot_check`) so exit-code-only consumers cannot mistake "some good news, some bad news" for "nothing confirmed."

## Info

### IN-01: `config/test_exceptions.exs` line-number-keyed registry is fragile — already broke once during this phase

**File:** `config/test_exceptions.exs:156`
**Issue:** The exception registry keys entries by `"file.exs:NNN"` literal line numbers (e.g. `test/mailglass/docs_contract_test.exs:746`). This phase's own commit history shows this already drifted once: `24cd5196 fix(167): re-point test-exception registry at the skipped docs test's new line` — an unrelated edit earlier in the same file shifted the `@tag :skip` test off its previously-registered line, silently desyncing the registry until caught and fixed. Nothing else in this diff introduces a new instance of the pattern, so this is a pre-existing design property being reused, not a new defect — flagging per the review brief's explicit request to note the fragility.
**Fix:** If the whatever-tool reads this registry can resolve entries by test name (`module_name.test_name`) or by a stable anchor comment instead of a raw line number, that would survive future reflow. If the tolerance/consumer requires literal line numbers for performance or simplicity, consider a lint/CI check that fails when a registered line number no longer matches the expected `@tag`/`test` construct, so drift is caught mechanically instead of by incidental discovery (as happened this phase).

---

_Reviewed: 2026-09-18T13:45:33Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
