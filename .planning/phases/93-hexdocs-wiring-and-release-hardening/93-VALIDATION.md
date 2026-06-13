---
phase: 93
slug: hexdocs-wiring-and-release-hardening
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-13
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
| **Full suite command** | per-package `mix docs` ×3 + lint-logic table run (`bash test/guard-release-trigger-cases.sh`) + `diff <(mix hex.info ...) manifest` version-truth check |
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

Task IDs are filled in once the planner emits PLAN.md files; the requirement →
assertion mapping below is the binding contract each task's
`<acceptance_criteria>` must satisfy.

| Task (plan TBD) | Wave | Requirement | Secure Behavior | Test Type | Automated Command |
|-----------------|------|-------------|-----------------|-----------|-------------------|
| SVG width/height | 1 | HEXD-01 | Assets carry explicit `width`/`height` matching viewBox aspect; no new visual drift | source | `grep -E 'width="164" height="156"' brandbook/assets/logo-mark.svg && grep -E 'width="16" height="16"' brandbook/assets/favicon.svg` |
| ex_doc `logo:`/`favicon:` ×3 | 1 | HEXD-01 | All three `docs/0` reference canonical `brandbook/` via relative path, no per-package copy, no `:files` change | source | `grep -c 'logo:.*brandbook/assets/logo-mark.svg' mix.exs && grep -c '../brandbook/assets/logo-mark.svg' mailglass_admin/mix.exs mailglass_inbound/mix.exs` |
| Local `mix docs` proof ×3 | 2 | HEXD-02 | Logo+favicon copied to `doc/assets/`, no new warnings, non-bumping commit type | behavior | per-package `mix docs` then `ls doc/assets/logo.svg doc/assets/favicon.svg` + `! grep -i warning` on build log |
| `exclude-paths` config add | 1 | RELH-01 | Root `.` package excludes guarded paths so brand/planning/sibling-only commits never bump core | source | `jq -e '.packages["."]["exclude-paths"] \| index("brandbook") and index(".planning") and index("prompts")' release-please-config.json` |
| guard-lint workflow | 1 | RELH-01 | New required workflow fires on every PR (no `paths-ignore`); FAILs brand-only-bump, PASSes mixed + non-bumping | behavior | `bash test/guard-release-trigger-cases.sh` (exits 0 only if all 5 edge cases assert correctly) |
| Version reconciliation | 2 | RELH-02 | In-repo manifest/@version/pins == live Hex (1.6.2/1.6.2/1.3.1); inbound pin `== 1.6.2` (published → no red main) | source | `jq -r '."."' .release-please-manifest.json \| grep -qx 1.6.2 && grep -q '@version "1.6.2"' mix.exs && grep -q '{:mailglass, "== 1.6.2"}' mailglass_inbound/mix.exs` |
| `.planning` memory correction | 2 | RELH-02 | STATE/CLAUDE/release-memory assert 1.6.2/1.6.2/1.3.1; tags fetched + kept (not deleted) | source | `! grep -rn '1.6.1/1.6.1/1.3.0' .planning/STATE.md CLAUDE.md && git tag --list 'mailglass-v1.6.2' \| grep -q .` |

*Status legend: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements:

- ex_doc 0.40.1 already resolved in all three lockfiles (`mix docs` works today).
- `jq` and `grep`/`rg` available locally for config/source assertions.
- `gh` CLI available for the guard-lint's `gh pr view --json files` query; the
  lint's pure decision logic is unit-testable offline via a fixture-driven shell
  test (`test/guard-release-trigger-cases.sh`) with no GitHub round-trip.
- `mix hex.info` provides live version truth for the RELH-02 reconciliation check.

*No new test framework install required.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Logo/favicon actually visible on hexdocs.pm | HEXD-02 | HexDocs only re-renders on the next `hex.publish`; this phase cuts no release (locked HexDocs-latency decision) — wiring is inert until each package's next natural release | After a future natural release, open `hexdocs.pm/mailglass` and confirm the sealed-flap mark in the 48×48 header and the favicon in the browser tab. Not gating for Phase 93. |
| Guard-lint blocks a real brand-only `feat:` PR end-to-end on GitHub | RELH-01 | Full proof needs a live PR against branch protection; offline fixture test covers the decision logic | Open a throwaway PR titled `feat: x` touching only `brandbook/` and confirm the `guard-release-trigger` required check goes red and blocks merge. Optional belt-and-suspenders demonstration. |

---

## Validation Sign-Off

- [x] Every requirement (HEXD-01, HEXD-02, RELH-01, RELH-02) has a deterministic automated assertion
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all infrastructure (no install needed)
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** draft 2026-06-13
