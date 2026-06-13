---
phase: 93-hexdocs-wiring-and-release-hardening
verified: 2026-06-13T00:00:00Z
status: passed
score: 10/10 must-haves verified
overrides_applied: 0
re_verification: false
---

# Phase 93: HexDocs Wiring and Release Hardening — Verification Report

**Phase Goal:** All three packages are wired to ship the brand on HexDocs with the next natural release, and the release pipeline can never again cut a release from brand/planning-only commits.
**Verified:** 2026-06-13
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | The two canonical SVGs carry explicit width/height matching their viewBox aspect | VERIFIED | `brandbook/assets/logo-mark.svg` root element: `width="164" height="156" viewBox="-12 32 164 156"` (confirmed by grep, exit 0); `brandbook/assets/favicon.svg`: `width="16" height="16" viewBox="0 0 16 16"` (confirmed); viewBoxes unchanged (both grep -c return 1) |
| 2 | All three packages' docs/0 configs reference canonical brandbook/ logo+favicon via correct relative paths | VERIFIED | Root `mix.exs:361-362`: `logo: "brandbook/assets/logo-mark.svg"` and `favicon: "brandbook/assets/favicon.svg"` (no ../); `mailglass_admin/mix.exs:219-220` and `mailglass_inbound/mix.exs:152-153`: both use `"../brandbook/assets/logo-mark.svg"` / `"../brandbook/assets/favicon.svg"` (with ../); all six grep -c return 1 |
| 3 | mix docs renders locally for all three packages with logo/favicon visible and no new warnings | VERIFIED (worktree-proven; manual follow-up accepted per instructions) | 93-01-SUMMARY.md records: mix docs exits 0 for all three packages; doc/assets/logo.svg + doc/assets/favicon.svg confirmed present in root, admin, and inbound outputs; no new warnings |
| 4 | Every edit lands as a non-release-triggering commit type; no Hex release cut | VERIFIED | Commits 57192111 (docs:), 7f8f3044 (docs:), aa67fa67 (chore:), f244d755 (chore:), 73b5d0ce (chore(release):), 4efd37e0 (docs(state):) — all confirmed in git log; none are feat:/fix: against non-excluded paths |
| 5 | Root . release-please package excludes brand/planning/sibling paths so a brand-only commit never bumps core | VERIFIED | `release-please-config.json` `.packages["."]["exclude-paths"]` = `["brandbook", ".planning", "prompts", "mailglass_admin", "mailglass_inbound"]`; jq -e confirms all 5 entries; bare names, no ./ prefix, no / suffix; mailglass_admin and mailglass_inbound entries have NO exclude-paths |
| 6 | A new dedicated guard workflow runs on every PR (no paths-ignore) and fails bump-triggering PRs whose changed files are entirely brand/planning paths | VERIFIED | `.github/workflows/guard-release-trigger.yml` exists; triggers on `pull_request:` (grep -c = 1); NO `pull_request_target`; NO `paths-ignore`; GUARDED=( "brandbook/" ".planning/" "prompts/" ) — exactly 3 paths, no sibling dirs; least-privilege permissions: `pull-requests: read` + `contents: read` both present; `exit 1` on all-guarded bump |
| 7 | The guard's decision logic is proven offline against all edge cases | VERIFIED | `bash test/scripts/guard-release-trigger-cases.sh` exits 0; all 6 cases pass (including WR-01/WR-02 fixes from code review): mixed feat+lib/ (PASS), docs: brand-only (PASS), feat: brand-only (FAIL), fix: .planning-only (FAIL), chore!: .planning-only (FAIL), feat: empty-file-list (PASS) |
| 8 | The guard's required-check registration is set or documented as a manual follow-up | VERIFIED (documented) | 93-02-SUMMARY.md Task 3 documents the explicit manual follow-up with both UI and gh CLI options; accepted per user decision as resolved-as-documented |
| 9 | Manifest + all three @version + both core-dep pins equal 1.6.2/1.6.2/1.3.1 with inbound/admin pinning == 1.6.2; binding comment blocks intact | VERIFIED | `.release-please-manifest.json`: `.=1.6.2`, `mailglass_admin=1.6.2`, `mailglass_inbound=1.3.1`; `mix.exs @version "1.6.2"`, `mailglass_admin/mix.exs @version "1.6.2"`, `mailglass_inbound/mix.exs @version "1.3.1"`; both `{:mailglass, "== 1.6.2"}` pins confirmed; no `== 1.6.1` remains; binding comment (fix(inbound):) grep -c = 2 in inbound/mix.exs, admin binding block present |
| 10 | STATE.md + CLAUDE.md current-state assert 1.6.2/1.6.2/1.3.1 as final version truth | VERIFIED | CLAUDE.md line 17 asserts `mailglass` 1.6.2 / `mailglass_admin` 1.6.2 / `mailglass_inbound` 1.3.1 with accidental-train context added; STATE.md line 176 has full RELH-02 reconciliation note confirming 1.6.2/1.6.2/1.3.1 with tags fetched+kept and admin-v1.6.1 quirk documented; the two occurrences of "1.6.1/1.6.1/1.3.0" in STATE.md are INTENTIONAL historical references inside the reconciliation note describing the resolved discrepancy — not stale assertions |

**Score:** 10/10 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `brandbook/assets/logo-mark.svg` | logo: source with explicit width=164 height=156 | VERIFIED | width="164" height="156" present; viewBox="-12 32 164 156" untouched |
| `brandbook/assets/favicon.svg` | favicon: source with explicit width=16 height=16 | VERIFIED | width="16" height="16" present; viewBox="0 0 16 16" untouched |
| `mix.exs` | root docs/0 with logo:/favicon: brandbook/assets relative paths | VERIFIED | lines 361-362 confirmed; no ../ prefix |
| `mailglass_admin/mix.exs` | admin docs/0 with ../brandbook/assets/ logo:/favicon: | VERIFIED | lines 219-220 confirmed; ../brandbook/ prefix |
| `mailglass_inbound/mix.exs` | inbound docs/0 with ../brandbook/assets/ logo:/favicon: | VERIFIED | lines 152-153 confirmed; ../brandbook/ prefix |
| `release-please-config.json` | root . package exclude-paths array with 5 entries | VERIFIED | jq confirms ["brandbook", ".planning", "prompts", "mailglass_admin", "mailglass_inbound"]; valid JSON |
| `.github/workflows/guard-release-trigger.yml` | PR-level guard on pull_request with no paths-ignore | VERIFIED | exists; pull_request only; no paths-ignore; no pull_request_target; SHA-pin requirement satisfied (zero uses: lines — all preinstalled gh + bash) |
| `test/scripts/guard-release-trigger-cases.sh` | offline fixture test, all edge cases passing | VERIFIED | bash exit 0; 6/6 cases OK including WR-01 fix (empty file list) and WR-02 fix (BREAKING CHANGE false-positive removed) |
| `.release-please-manifest.json` | manifest at released versions 1.6.2/1.6.2/1.3.1 | VERIFIED | jq: .=1.6.2, mailglass_admin=1.6.2, mailglass_inbound=1.3.1 |
| `.planning/STATE.md` | release-state truth corrected to 1.6.2/1.6.2/1.3.1 | VERIFIED | reconciliation note at line 176; current version confirmed; historical references to 1.6.1/1.6.1/1.3.0 are intentional |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `mix.exs docs/0` | `brandbook/assets/logo-mark.svg` | ex_doc logo: relative path (root, no ../) | WIRED | `logo: "brandbook/assets/logo-mark.svg"` at line 361 |
| `mailglass_admin/mix.exs` and `mailglass_inbound/mix.exs docs/0` | `brandbook/assets/logo-mark.svg` | ex_doc logo: relative path (siblings, ../) | WIRED | both carry `"../brandbook/assets/logo-mark.svg"` |
| `.github/workflows/guard-release-trigger.yml` | PR title type + PR changed-file set | conventional-commit title regex + gh pr view --json files + all_guarded subset test | WIRED | is_bump logic at lines 47-51; GUARDED subset test at lines 67-83; exit 1 on violation confirmed |
| `release-please-config.json root . package` | release-please commit attribution | exclude-paths skips all-excluded commits | WIRED | 5-entry array present; bare names confirmed by jq |
| `.release-please-manifest.json + 3 @version + 2 pins` | live Hex 1.6.2/1.6.2/1.3.1 | D-13 gate confirmed before edits; catch-up reconciliation | WIRED | D-13 gate PASS documented in 93-03-SUMMARY.md; all version literals confirmed matching |
| `mailglass_inbound/mix.exs and mailglass_admin/mix.exs core pin` | published core 1.6.2 | `== 1.6.2` (published, safe) | WIRED | both `{:mailglass, "== 1.6.2"}` confirmed; no stale `== 1.6.1` |

---

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Guard fixture: all 6 edge cases pass | `bash test/scripts/guard-release-trigger-cases.sh` | exit 0; "All cases passed." | PASS |
| SVG width/height (logo) | `grep -E 'width="164" height="156"' brandbook/assets/logo-mark.svg` | match on root svg element | PASS |
| SVG width/height (favicon) | `grep -E 'width="16" height="16"' brandbook/assets/favicon.svg` | match on root svg element | PASS |
| exclude-paths all 5 entries | `jq -e '.packages["."]["exclude-paths"] \| ...'` | true | PASS |
| Manifest at 1.6.2/1.6.2/1.3.1 | `jq -r '."."' .release-please-manifest.json` | 1.6.2 | PASS |
| Core pin == 1.6.2 (inbound) | `grep '{:mailglass, "== 1.6.2"}' mailglass_inbound/mix.exs` | match | PASS |
| No stale == 1.6.1 pins | `grep '== 1.6.1' mailglass_admin/mix.exs mailglass_inbound/mix.exs` | no matches | PASS |

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| HEXD-01 | 93-01-PLAN.md | SVGs carry explicit width/height; all three docs/0 gain logo:/favicon: pointing at canonical brandbook/ assets via relative paths | SATISFIED | Both SVGs verified; all six logo/favicon path greps return 1; no per-package copies; no :files allowlist change |
| HEXD-02 | 93-01-PLAN.md | mix docs renders locally for all three packages with logo/favicon visible and no new warnings; edits committed as non-release-triggering types | SATISFIED | Proven in executor worktrees (accepted per instructions); all commits use non-bumping types (docs:/chore:) |
| RELH-01 | 93-02-PLAN.md | release-please can no longer cut a release from brand/planning-only commits | SATISFIED | exclude-paths (5 entries, silent secondary) + guard-release-trigger workflow (loud primary, no paths-ignore); fixture exits 0; branch-protection registration documented as manual follow-up (accepted) |
| RELH-02 | 93-03-PLAN.md | 1.6.x aftermath reconciled: tags dispositioned, inbound exact-pin bumped to released core, planning release-state docs reflect 1.6.2/1.6.2/1.3.1 | SATISFIED | Manifest + @version + pins confirmed at 1.6.2/1.6.2/1.3.1; 1.6.x tags fetched+kept; STATE.md reconciliation note + CLAUDE.md current-state both confirmed |

**Note on REQUIREMENTS.md traceability table:** The table at lines 97-100 shows HEXD-01/HEXD-02/RELH-01 as "Pending" — this is a pre-execution stale state in the planning doc (the table was not updated post-execution). The underlying implementations are fully verified above. RELH-02 is correctly marked "[x] Complete."

---

### Anti-Patterns Found

No TBD, FIXME, or XXX markers found in any phase-modified file. No stub patterns. No placeholder content.

| File | Pattern | Severity | Notes |
|------|---------|----------|-------|
| All phase-modified files | TBD/FIXME/XXX scan | None | Clean |

---

### Human Verification Required

One item is accepted-as-documented rather than requiring human action before phase close:

**Branch-protection required-check registration for guard-release-trigger**

- **Test:** After any PR runs the guard, go to GitHub Settings > Branches > main > Required status checks and add "guard-release-trigger"
- **Expected:** Subsequent PRs with bump-triggering titles and brand/planning-only files are blocked from merging
- **Why human:** GitHub API cannot register a check name that has not yet run on a PR; the guard-release-trigger workflow must fire at least once before it appears in the branch-protection picker. This is a sequencing constraint of the GitHub API, not a code gap.
- **Status:** Explicitly documented in 93-02-SUMMARY.md Task 3 with step-by-step instructions (UI and gh CLI options). Accepted as resolved-as-documented per user decision.

The guard workflow IS wired and functional — it runs on every PR and will annotate violations. It just does not yet block merges until registered as a required check. The exclude-paths defense-in-depth is active immediately.

---

### Gaps Summary

No gaps. All 10 must-haves are verified against codebase evidence. The one non-automated item (branch-protection check registration) was explicitly accepted as a documented manual follow-up by the user and recorded in the SUMMARY per the plan's checkpoint:human-action task instructions.

---

_Verified: 2026-06-13_
_Verifier: Claude (gsd-verifier)_
