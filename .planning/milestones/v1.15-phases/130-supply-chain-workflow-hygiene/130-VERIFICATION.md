---
phase: 130-supply-chain-workflow-hygiene
verified: 2026-07-02T08:46:00Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: null
  previous_score: null
---

# Phase 130: Supply Chain + Workflow Hygiene Verification Report

**Phase Goal:** Add supply-chain and workflow-hygiene guards that never red an open PR under an unfixable advisory wave — `mix_audit` advisory-on-PR/block-at-release, dependabot sibling coverage, a cowlib OSV-staleness forcing function (fail-open), `actionlint` on workflow PRs, and a non-blocking latest-Elixir advisory row.
**Verified:** 2026-07-02T08:46:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria + PLAN must_haves)

| # | Truth | Status | Evidence |
| - | ----- | ------ | -------- |
| 1 | `mix deps.audit` runs advisory (non-blocking) on PR + blocking only at publish gate; simulated unfixable advisory reds the publish gate but NOT open PRs (SUPPLY-01) | ✓ VERIFIED | ci.yml `deps_audit_advisory` job (l.553) has `continue-on-error: true` + `Advisory (` name → non-blocking on PR AND classified non-blocking by `isAdvisory()`; NOT in `ci_green.needs` (l.1133-1138). publish.check.ex `verify_deps_audit/1` (l.1142) hard-blocks on non-allowlisted finding via `fail_step`. Test proves asymmetry: `unaccepted_deps_audit_findings/1` returns non-empty for unlisted GHSA → publish would block (16 tests, 0 failures). |
| 2 | `dependabot.yml` watches `mailglass_admin` + `mailglass_inbound` sibling locks, NOT frozen reference baselines (SUPPLY-02) | ✓ VERIFIED | dependabot.yml has 4 `directory:` entries: `/`, `/mailglass_admin`, `/mailglass_inbound`, `/` (github-actions). No `reference/` string present — frozen baselines correctly excluded. |
| 3 | cowlib allowlist has OSV-staleness forcing function — loud CI warning every run + hard block at publish, fail-open on OSV outage (SUPPLY-03) | ✓ VERIFIED | publish.check.ex: loud-warn-always pre-chain call (l.119); Step 15 `verify_osv_freshness/1` (l.1269) hard-blocks on `{:stale,...}`, fail-opens (warn + continue) on `{:error,...}`. `osv_get/1` (l.1245) fail-open contract covers non-200/network/exception (`rescue`)/exit (`catch :exit`) → always `{:error, _}`. Tests: withdrawn→stale, no-withdrawn→active, malformed JSON→error, unresolvable host→error (all green). |
| 4 | `actionlint` gates `.github/workflows/**` on PR + fails malformed workflow PR; plus advisory dependency-review step (SUPPLY-04) | ✓ VERIFIED | `rhysd/actionlint@914e7df` step + `paths: .github/workflows/*.yml` PR trigger PRE-EXISTED (commit c901c317). This phase ADDED the advisory `dependency-review-action@a1d282b...` step (commit 41d904f6): `continue-on-error: true`, `if: github.event_name == 'pull_request'`, `fail-on-severity: high`, 40-char commit-SHA-pinned. actionlint ran clean on all changed workflows. |
| 5 | latest-Elixir advisory row (1.19/OTP28) runs non-blocking push+cron only, never blocks; LD-13 floor-coincidence invariant documented (SUPPLY-05) | ✓ VERIFIED | advisory-matrix.yml `core_latest_elixir_advisory` job (l.97): job-level `if: github.event_name != 'pull_request'` (l.103) → never on PR; matrix `elixir: "1.19"/otp: "28"`; name `Core Full Suite Advisory (...)` contains `Advisory (` → non-blocking classify; toolchain-scoped cache key (l.151). LD-13 invariant comment in workflow (l.91-96) AND mix.exs (l.11-14 near `elixir: "~> 1.18"`). |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `mix.exs` | `{:mix_audit, ~> 2.1, only: [:dev,:test], runtime: false}` + `deps.audit` in ci alias + LD-13 comment | ✓ VERIFIED | Dep at l.183; `"deps.audit"` at l.374 (immediately after `"hex.audit"` l.373); LD-13 comment l.11-14 by `elixir: "~> 1.18"` l.15. `mix deps.audit` resolves + runs clean. |
| `.github/workflows/ci.yml` | `deps_audit_advisory` job (continue-on-error, Advisory name, not required) | ✓ VERIFIED | Job l.553, `continue-on-error: true` l.564, `.tool-versions` version-file + Phase-129 cache-key shape, reuses pinned SHAs, absent from ci_green.needs. |
| `lib/mix/tasks/mailglass.publish.check.ex` | `verify_deps_audit/1`, OSV functions, Step 14 + 15 wired | ✓ VERIFIED | Step 14 l.186, Step 15 l.189; all 6 functions present (`verify_deps_audit`, `unaccepted_deps_audit_findings`, `check_osv_advisory_staleness`, `classify_osv_response`, `osv_get`, `verify_osv_freshness`); brand-voice `Delivery blocked:` messages. |
| `test/support/ci_lanes.ex` | lane in `@advisory_lanes_ci` | ✓ VERIFIED | `"Deps Audit Advisory (Elixir 1.18 / OTP 27)"` at l.67. |
| `test/scripts/ci_parity_drift_test.exs` | matcher + mapset entry | ✓ VERIFIED | matcher clause l.115, mapset entry l.193 (three-file-atomic registration complete). |
| `test/mailglass/publish/audit_allowlist_test.exs` | deps.audit + OSV describe blocks | ✓ VERIFIED | `unaccepted_deps_audit_findings/1` (l.63), `classify_osv_response/2` (l.133), `osv_get/1` fail-open (l.154). |
| `.github/dependabot.yml` | 2 new sibling mix entries, no reference/ | ✓ VERIFIED | 4 directory entries, siblings present, no reference. |
| `.github/workflows/actionlint.yml` | dependency-review step | ✓ VERIFIED | SHA-pinned v5.0.0 advisory step present. |
| `.github/workflows/advisory-matrix.yml` | core_latest_elixir_advisory job | ✓ VERIFIED | 1.19/OTP28 job with PR-exclusion if + LD-13 comment. |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| ci.yml deps_audit_advisory lane | publish-hex.yml gate-ci-green | `Advisory (` substring in name → isAdvisory() | ✓ WIRED | Name `Deps Audit Advisory (Elixir 1.18 / OTP 27)` contains `Advisory (`. Structural confirm only (live gate-ci-green run is Phase 131). |
| CILanes registry | MIXCI-03 parity-drift guard | three-file atomic (ci_lanes.ex + matcher_for + matcher_lanes) | ✓ WIRED | All three present; ci_parity_drift_test green (MIXCI-03 anti-vacuity passes). |
| advisory-matrix.yml 1.19 job | PR required-checks context | job-level `if: github.event_name != 'pull_request'` | ✓ WIRED | Guard at job level (l.103) — correct mechanism (no per-matrix-row if in GHA). Live PR-exclusion confirm is Phase 131. |
| osv_get/1 error paths | fail-open contract | try/rescue + catch :exit + non-200 branch | ✓ WIRED | All error paths return `{:error, _}`; never raises. Test-proven. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| deps.audit + OSV logic correct | `mix test audit_allowlist_test.exs ci_parity_drift_test.exs` | 16 tests, 0 failures | ✓ PASS |
| New advisory lane NOT in required set (GATE-03) | `mix test required_checks_test.exs` | 6 tests, 0 failures | ✓ PASS |
| mix_audit dep resolves + runs | `mix deps.audit` | `No vulnerabilities found.` exit 0 | ✓ PASS |
| workflow YAML valid | `actionlint` on 3 changed workflows | clean (no output) | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| SUPPLY-01 | 130-01 | deps.audit advisory-on-PR / block-at-publish | ✓ SATISFIED | Truth 1 |
| SUPPLY-02 | 130-02 | dependabot sibling coverage | ✓ SATISFIED | Truth 2 |
| SUPPLY-03 | 130-01 | OSV-staleness forcing function, fail-open | ✓ SATISFIED | Truth 3 |
| SUPPLY-04 | 130-02 | actionlint + dependency-review advisory step | ✓ SATISFIED | Truth 4 |
| SUPPLY-05 | 130-02 | 1.19/OTP28 advisory row + LD-13 invariant | ✓ SATISFIED | Truth 5 |

No orphaned requirements — all 5 SUPPLY IDs (REQUIREMENTS.md l.85-98, mapped to Phase 130) are claimed across the two plans and verified.

### Anti-Patterns Found

None. No `TBD`/`FIXME`/`XXX` debt markers and no `TODO`/`HACK`/`PLACEHOLDER` warning markers in any modified file. mix_audit is `runtime: false, only: [:dev,:test]` — zero adopter impact, no Node.

### Human Verification Required

None. All structural/config correctness is verified programmatically. The two documented open questions are deferred by design to Phase 131's live CI run and do NOT gate this phase:
- **A2 (setup-beam resolving 1.19/OTP28 on ubuntu-latest):** The 1.19 row is advisory + never required + `Advisory (`-named — a setup failure is a red advisory, never a blocked PR/publish. Non-gating.
- **Live CI confirmation of PR-vs-publish asymmetry (SC 1/4/5):** The phase produces no Hex release (release is Phase 131). Structural correctness — `isAdvisory()`-matching names, `continue-on-error`, job-level `if` guards, cache-key shapes — is fully verified here; the live behavioral confirmation is intrinsic to Phase 131's first push, as both SUMMARYs document.

### Gaps Summary

No gaps. All five success criteria are structurally and (where testable without a live CI run / Hex release) behaviorally verified. The `mix deps.audit` gate, OSV-staleness fail-open forcing function, dependabot sibling coverage, advisory dependency-review step, and the 1.19/OTP28 latest-Elixir advisory row are all present, wired, and — for the Elixir-code seams — proven green by ExUnit (22 tests across three suites, 0 failures). The `actionlint` workflow-PR gate pre-existed (commit c901c317); this phase correctly added only the advisory `dependency-review-action` step on top of it.

---

_Verified: 2026-07-02T08:46:00Z_
_Verifier: Claude (gsd-verifier)_
