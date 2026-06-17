---
phase: 93
slug: hexdocs-wiring-and-release-hardening
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-13
validated: 2026-06-13
---

# Phase 93 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

This phase is config/CI/release-reconciliation work — verification is
**deterministic** (does the logo render, does the lint FAIL/PASS on the exact
1.6.x case, do in-repo versions match live Hex) rather than statistical
sampling. Each requirement maps to a concrete shell/`mix` assertion that runs in
under the latency budget.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Shell assertions + `mix docs` (ex_doc 0.40.1) + `gh`/`act`-free CI-logic shell test |
| **Config file** | `mix.exs` / `mailglass_admin/mix.exs` / `mailglass_inbound/mix.exs` (`docs/0`); `release-please-config.json`; `.release-please-manifest.json`; new `.github/workflows/guard-release-trigger.yml` |
| **Quick run command** | `mix docs 2>&1 \| tee /tmp/d.log && ls doc/assets/logo.svg doc/assets/favicon.svg && ! grep -i warning /tmp/d.log` |
| **Full suite command** | per-package `mix docs` ×3 + lint-logic table run (`bash test/scripts/guard-release-trigger-cases.sh`) + `diff <(mix hex.info ...) manifest` version-truth check |
| **Estimated runtime** | ~120 seconds (3× `mix docs` builds dominate) |

---

## Sampling Rate

- **After every task commit:** Run the task-specific source/`mix docs`/lint-case
  assertion from the plan task's `<acceptance_criteria>`.
- **After every plan wave:** Run the plan-level verification block.
- **Before `/gsd:verify-work`:** all three `mix docs` builds show logo+favicon
  with no new warnings; the guard-lint FAILs the brand-only-bump case and PASSes
  the mixed + non-bumping cases; in-repo manifest/@version/pins equal live Hex
  (1.6.2/1.6.2/1.3.1).
- **Max feedback latency:** 120 seconds.

---

## Per-Task Verification Map

Task IDs, commits, and statuses below reflect the executed plans (93-01/02/03).
Every requirement maps to a deterministic automated assertion re-run and
confirmed green during the 2026-06-13 validation audit.

| Task | Wave | Requirement | Commit | Secure Behavior | Test Type | Automated Command | Status |
|------|------|-------------|--------|-----------------|-----------|-------------------|--------|
| 93-01 T1: SVG width/height | 1 | HEXD-01 | 57192111 | Assets carry explicit `width`/`height` matching viewBox aspect; no new visual drift | source | `grep -E 'width="164" height="156"' brandbook/assets/logo-mark.svg && grep -E 'width="16" height="16"' brandbook/assets/favicon.svg` | ✅ |
| 93-01 T2: ex_doc `logo:`/`favicon:` ×3 | 1 | HEXD-01 | 7f8f3044 | All three `docs/0` reference canonical `brandbook/` via relative path, no per-package copy, no `:files` change | source | `grep -c 'logo:.*brandbook/assets/logo-mark.svg' mix.exs && grep -c '../brandbook/assets/logo-mark.svg' mailglass_admin/mix.exs mailglass_inbound/mix.exs` | ✅ |
| 93-01 T3: Local `mix docs` proof ×3 | 2 | HEXD-02 | (verify-only) | Logo+favicon copied to `doc/assets/`, no new warnings, non-bumping commit type | behavior | per-package `mix docs` then `ls doc/assets/logo.svg doc/assets/favicon.svg` + `! grep -i warning` on build log | ✅ |
| 93-02 T1: `exclude-paths` config add | 1 | RELH-01 | aa67fa67 | Root `.` package excludes guarded paths so brand/planning/sibling-only commits never bump core | source | `jq -e '.packages["."]["exclude-paths"] \| index("brandbook") and index(".planning") and index("prompts")' release-please-config.json` | ✅ |
| 93-02 T2: guard-lint workflow + fixture | 1 | RELH-01 | f244d755 | New workflow fires on every PR (no `paths-ignore`); FAILs brand-only-bump, PASSes mixed + non-bumping | behavior | `bash test/scripts/guard-release-trigger-cases.sh` (exits 0 only if all edge cases assert correctly — 7/7 green) | ✅ |
| 93-02 T3: required-check registration | 1 | RELH-01 | (manual) | Guard is a branch-protection required check so it blocks merges | manual | See Manual-Only — blocked by auto-mode classifier; documented follow-up | ⚠️ manual |
| 93-03 T1: D-13 live-Hex gate + tag fetch | 2 | RELH-02 | (verify-only) | Live Hex confirmed 1.6.2/1.6.2/1.3.1 before any edit; real 1.6.x tags fetched + kept | behavior | `mix hex.info mailglass` shows 1.6.2; `git tag --list 'mailglass-v1.6.2'` non-empty | ✅ |
| 93-03 T2: Version reconciliation | 2 | RELH-02 | 73b5d0ce | In-repo manifest/@version/pins == live Hex (1.6.2/1.6.2/1.3.1); inbound pin `== 1.6.2` (published → no red main) | source | `jq -r '."."' .release-please-manifest.json \| grep -qx 1.6.2 && grep -q '@version "1.6.2"' mix.exs && grep -q '{:mailglass, "== 1.6.2"}' mailglass_inbound/mix.exs` | ✅ |
| 93-03 T3: `.planning` memory correction | 2 | RELH-02 | 4efd37e0 | STATE/CLAUDE assert 1.6.2/1.6.2/1.3.1; tags fetched + kept (not deleted) | source | `! grep -rn '1.6.1/1.6.1/1.3.0' <current-state lines of> .planning/STATE.md CLAUDE.md && git tag --list 'mailglass-v1.6.2' \| grep -q .` | ✅ |

*Status legend: ⬜ pending · ✅ green · ❌ red · ⚠️ manual/flaky*

*Note: the `1.6.1/1.6.1/1.3.0` string still appears in STATE.md inside the RELH-02
**historical reconciliation note** (narrating what was stale), not in any
current-state assertion — this is expected and correct.*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements:

- ex_doc 0.40.1 already resolved in all three lockfiles (`mix docs` works today).
- `jq` and `grep`/`rg` available locally for config/source assertions.
- `gh` CLI available for the guard-lint's `gh pr view --json files` query; the
  lint's pure decision logic is unit-testable offline via a fixture-driven shell
  test (`test/scripts/guard-release-trigger-cases.sh`) with no GitHub round-trip.
- `mix hex.info` provides live version truth for the RELH-02 reconciliation check.

*No new test framework install required.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Logo/favicon actually visible on hexdocs.pm | HEXD-02 | HexDocs only re-renders on the next `hex.publish`; this phase cuts no release (locked HexDocs-latency decision) — wiring is inert until each package's next natural release | After a future natural release, open `hexdocs.pm/mailglass` and confirm the sealed-flap mark in the 48×48 header and the favicon in the browser tab. Not gating for Phase 93. |
| Guard-lint blocks a real brand-only `feat:` PR end-to-end on GitHub | RELH-01 | Full proof needs a live PR against branch protection; offline fixture test covers the decision logic | Open a throwaway PR titled `feat: x` touching only `brandbook/` and confirm the `guard-release-trigger` required check goes red and blocks merge. Optional belt-and-suspenders demonstration. |
| Register `guard-release-trigger` as a required branch-protection check | RELH-01 | The auto-mode classifier blocks the `gh api PATCH .../required_status_checks` call (shared security config), and the check must run on ≥1 PR before it is selectable | (1) Merge any PR so the guard runs once and registers as a known context; (2) add it via Settings > Branches > main > "Require status checks", or `gh api -X PATCH repos/szTheory/mailglass/branches/main/protection/required_status_checks` adding `guard-release-trigger`. Until then the guard reports status but does not block; `exclude-paths` provides active silent defense-in-depth meanwhile. (Documented in 93-02-SUMMARY Task 3.) |

---

## Validation Sign-Off

- [x] Every requirement (HEXD-01, HEXD-02, RELH-01, RELH-02) has a deterministic automated assertion
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all infrastructure (no install needed)
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-06-13

---

## Validation Audit 2026-06-13

Audited the draft VALIDATION.md against the three executed plans (93-01/02/03)
and re-ran every requirement's deterministic assertion against the live tree.

| Metric | Count |
|--------|-------|
| Requirements | 4 (HEXD-01, HEXD-02, RELH-01, RELH-02) |
| Gaps found | 0 |
| Resolved | 0 (none needed) |
| Escalated | 0 |
| Automated (green) | 4 of 4 |
| Manual-only follow-ups | 3 (hexdocs.pm render on next release; guard e2e PR proof; branch-protection required-check registration) |

**Findings:**
- All four requirements already carry a passing deterministic automated
  assertion — no test generation required.
- The one persistent test artifact, `test/scripts/guard-release-trigger-cases.sh`
  (RELH-01), exists, is committed (f244d755), and passes 7/7 edge cases.
- Per-Task Map promoted from pre-execution placeholders to real task IDs,
  commit SHAs, and confirmed-green statuses.
- Branch-protection required-check registration added to Manual-Only as an
  explicit outstanding follow-up (auto-mode classifier blocked the API call).

Phase 93 is **Nyquist-compliant**: every requirement has automated verification;
the only manual items are inherently un-automatable (live hexdocs.pm rendering,
GitHub branch-protection edit), correctly carved out as Manual-Only.
