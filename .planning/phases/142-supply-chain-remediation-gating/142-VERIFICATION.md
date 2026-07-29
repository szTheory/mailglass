---
phase: 142-supply-chain-remediation-gating
verified: 2026-07-29T01:00:00Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 142: Supply-Chain Remediation & Gating Verification Report

**Phase Goal:** Every dependency advisory this repository can detect — direct or transitive —
either blocks a merge or carries a recorded, time-boxed exception; nothing accumulates silently the
way `hpax` and the 13-PR dependabot backlog did.
**Verified:** 2026-07-29
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | The CI-side `hex_audit` lane honors the same `@accepted_advisories` allowlist `publish.check` uses, read from one source — landed and green BEFORE the next criterion (VULN-05 hard precondition for VULN-03) | ✓ VERIFIED | `mix mailglass.audit --kind hex` run live from repo root (this session) exits 0 and prints `Accepted (mailglass_admin): EEF-CVE-2026-43966 is an accepted-allowlist finding.` and the same for `EEF-CVE-2026-43969` — genuine detection-then-suppression, not vacuous absence. `lib/mailglass/supply_chain/accepted_advisories.ex` is the sole allowlist (`grep -c "@accepted_advisories" lib/mix/tasks/mailglass.publish.check.ex` = 0; `mailglass.publish.check.ex` thin-delegates to `Mailglass.SupplyChain.AcceptedAdvisories.unaccepted_audit_findings/1` etc.). 142-03-SUMMARY.md records this same evidence from a real CI run (PR #144) landing BEFORE 142-04's promotion commit (`34702fde`, timestamped after `142-03`'s checkpoint). |
| 2 | Both Hex Audit and Deps Audit lanes are merge-gating (`ci_green.needs` + `Mailglass.CILanes.required_lanes()`), a PR with a new HIGH-severity advisory with an available fix cannot merge, a PR touching only accepted cowlib advisories merges cleanly | ✓ VERIFIED | `ci.yml`'s `ci_green.needs` (lines 1151-1152) and its shell result-loop (lines 1163-1164) both list `hex_audit` and `deps_audit_advisory`. `test/support/ci_lanes.ex`'s `@required_lanes` (lines 80-88) lists `"Hex Audit (Elixir 1.18 / OTP 27)"` and `"Deps Audit (Elixir 1.18 / OTP 27)"` — 7 entries. `deps_audit_advisory`'s job block (ci.yml:570-601) has NO `continue-on-error: true` (confirmed via direct read and via `awk` scoped grep). No HIGH-severity threshold exists anywhere (`git diff 34702fde~1 34702fde -- mix.exs test/scripts/ci_parity_drift_test.exs | grep -iE "severity|HIGH"` returns nothing) — gate blocks on any non-allowlisted finding, matching D-08. |
| 3 | Every allowlisted advisory carries a recorded reason and re-check/expiry date; the lane visibly flags any entry whose upstream fix has landed rather than aging out silently | ✓ VERIFIED | Both entries in `lib/mailglass/supply_chain/accepted_advisories.ex` carry `:reason`, `:accepted_on: ~D[2026-07-28]`, `:recheck_by: ~D[2026-10-26]`. `expired_entries/1` (strictly-after semantics) and `unused_entries/1` (matched-finding staleness) are both implemented, unit-tested (`test/mailglass/supply_chain/accepted_advisories_test.exs`), and wired into `evaluate(:hex, ...)` in `dev/mix/tasks/mailglass.audit.ex` (lines 137-146) — both checks hard-fail the lane with a named entry, not a generic message. |
| 4 | Every dependabot PR left with auto-merge enabled as of 2026-07-28 is confirmed merged or closed with a recorded reason; none indeterminate | ✓ VERIFIED | Live `gh pr list --repo szTheory/mailglass --state open --json number,author,autoMergeRequest --jq '[.[] | select(.author.login == "dependabot[bot]" or .author.login == "app/dependabot") | select(.autoMergeRequest != null)] | length'` (run this session) returns `0`. All 12 named PRs individually confirmed `MERGED` via live `gh pr view`; PR #96 confirmed `CLOSED`, `mergedAt: null` (genuine merge conflict, closed with a recorded reason, not blind-rearmed). PR #132 confirmed live: maintainer-authored (`szTheory`), auto-merge armed, correctly flagged in 142-02-SUMMARY.md as adjacent-but-out-of-scope (not a dependency PR) and left untouched. |
| 5 | A written triage cadence names who reads raw `mix hex.audit` output, how often, and response expectation by severity | ✓ VERIFIED | `MAINTAINING.md:296-341` § "Dependency Advisory Triage", placed strictly between `## Retract Decision Tree` (:253) and `## Security Response SLA` (:341) — outside the `## Required Checks` (:132) section's parsed boundary (next heading `## Bus Factor & Continuity` at :236). States who (`szTheory`), what (`mix mailglass.audit --kind hex/deps`, wrapping `mix hex.audit`/`mix deps.audit`, across all three Mix projects), how often (weekly + on red), response-by-severity (HIGH/CRITICAL 14 days, MEDIUM 30 days, LOW next triage), and explicitly states Dependabot cannot auto-file a Hex transitive-dependency fix requiring a parent bump, citing the `hpax` precedent. |

**Score:** 5/5 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/mailglass/supply_chain/accepted_advisories.ex` | Single allowlist source, alias-aware matching, expiry/unused checks | ✓ VERIFIED | Exists, substantive (215 lines), wired (called from both `dev/mix/tasks/mailglass.audit.ex` and `lib/mix/tasks/mailglass.publish.check.ex`), data flows real (live `mix mailglass.audit --kind hex` run genuinely detects+suppresses both cowlib advisories). |
| `dev/mix/tasks/mailglass.audit.ex` | `mix mailglass.audit --kind hex\|deps` Mix task | ✓ VERIFIED | Exists, substantive (171 lines, real `System.cmd` subprocess orchestration, no stubs), wired into `ci.yml`'s `hex_audit`/`deps_audit_advisory` steps and `mix.exs`'s `:ci` alias. |
| `test/mailglass/supply_chain/accepted_advisories_test.exs` + `test/mix/tasks/mailglass.audit_test.exs` | Unit test coverage | ✓ VERIFIED | 38 tests across supply_chain + audit_test + audit_allowlist_test, 0 failures (run live this session). |
| `.github/workflows/ci.yml` (hex_audit/deps_audit_advisory/ci_green) | Rewired steps, merge-gating promotion | ✓ VERIFIED | Confirmed by direct read: both jobs call `mix mailglass.audit --kind <hex\|deps>`; both are `ci_green.needs` members; `continue-on-error: true` absent from `deps_audit_advisory`; stale `isAdvisory()` comment absent; renamed to `Deps Audit (Elixir 1.18 / OTP 27)`. |
| `test/support/ci_lanes.ex` | `required_lanes/0` = 7, `all_classified_lanes/0` totals 24 | ✓ VERIFIED | Read directly: `@required_lanes` has 7 entries including both audit lanes; `@advisory_classified_lanes` (3) + `@publish_gating_lanes` (12) + `@structural_lanes` (2) + required (7) = 24. |
| `.github/workflows/publish-hex.yml` | `REQUIRED_LANES`/`ADVISORY_LANES`/`PUBLISH_GATING_LANES` mirror `ci_lanes.ex` | ✓ VERIFIED | Read directly: matches exactly. |
| `MAINTAINING.md` | 24-row disposition table + new Triage section | ✓ VERIFIED | Both promoted rows present (`classification: required`, `disposition: keep-with-reason`); `## Dependency Advisory Triage` section present and correctly placed. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `ci.yml` `hex_audit`/`deps_audit_advisory` steps | `mix mailglass.audit --kind hex\|deps` | `run:` step | WIRED | Direct read of ci.yml lines 567-568, 599-600. |
| `ci_green.needs` + result-loop | `hex_audit`/`deps_audit_advisory` | GitHub Actions `needs:` + shell loop | WIRED | Both additions present together (D-07 requirement satisfied — `continue-on-error` also removed). |
| `mailglass.publish.check.ex` | `Mailglass.SupplyChain.AcceptedAdvisories` | thin-delegation | WIRED | `unaccepted_audit_findings/1`/`unaccepted_deps_audit_findings/1` are one-line delegations; `@accepted_advisories` fully deleted. |
| `mix.exs` `:ci` alias | `mailglass.audit --kind hex\|deps` | alias step list | WIRED | `mix.exs:403-404` confirmed. |
| `MAINTAINING.md` § Dependency Advisory Triage | `lane_classification_drift_test.exs`'s 24-row parser | section boundary (`\n## ` split) | WIRED, non-interfering | Placed after `## Required Checks`'s boundary; `test/scripts/` suite (40 tests) passes including the 24-row anti-vacuity assertion. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Hex Audit lane detects+suppresses both live cowlib advisories | `mix mailglass.audit --kind hex` (live, this session) | Exit 0; printed `Accepted (mailglass_admin): EEF-CVE-2026-43966 is an accepted-allowlist finding.` and `EEF-CVE-2026-43969` | ✓ PASS |
| Deps Audit lane clean scan | `mix mailglass.audit --kind deps` (live, this session) | Exit 0, "all findings accepted" | ✓ PASS |
| `test/scripts/` drift meta-test suite (lane_classification_drift, ci_parity_drift, required_checks, conformance_advisory) | `MIX_ENV=test mix test test/scripts/ --warnings-as-errors` | 40 tests, 0 failures | ✓ PASS |
| Supply-chain + audit + publish-check-delegation unit tests | `MIX_ENV=test mix test test/mailglass/supply_chain/ test/mix/tasks/mailglass.audit_test.exs test/mailglass/publish/audit_allowlist_test.exs --warnings-as-errors` | 38 tests, 0 failures | ✓ PASS |
| `mix verify.ci_lane_contract` | same as test/scripts/ | 40 tests, 0 failures | ✓ PASS |
| Full compile with warnings-as-errors | `mix compile --warnings-as-errors` | exit 0 | ✓ PASS |
| Zero indeterminate dependabot PRs | `gh pr list ... --jq '[...] | length'` (live, this session, authenticated as szTheory) | `0` | ✓ PASS |
| All 12 dependabot PRs merged, #96 closed | `gh pr view <N> --json state,mergedAt` for each (live, this session) | 12x MERGED, #96 CLOSED/mergedAt:null | ✓ PASS |
| #132 correctly flagged out-of-scope | `gh pr view 132 --json author,autoMergeRequest,state` (live) | author szTheory, autoMergeRequest non-null, OPEN — matches SUMMARY's claim | ✓ PASS |
| D-04 atomicity: nine sites in one commit | `git show --stat 34702fde` / `git diff 34702fde~1 34702fde --stat` | Exactly 6 files (all nine edit-site groups), one commit | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| VULN-05 | 142-01 | CI-side audit lanes honor shared allowlist, one source | ✓ SATISFIED | See Truth 1 above. |
| VULN-06 | 142-01 | Recorded reason + re-check date per entry, staleness surfaced | ✓ SATISFIED | See Truth 3 above. |
| VULN-02 | 142-02 | Dependabot backlog dispositioned individually, zero indeterminate | ✓ SATISFIED | See Truth 4 above, live-verified. |
| VULN-03 | 142-03/142-04 | Both lanes merge-gating, no HIGH threshold | ✓ SATISFIED | See Truth 2 above; D-14 checkpoint (142-03) precedes promotion (142-04) per timestamps/commit order. |
| VULN-04 | 142-05 | Written triage cadence covering transitive deps | ✓ SATISFIED | See Truth 5 above. |

All five phase requirement IDs (VULN-05, VULN-03, VULN-06, VULN-02, VULN-04) are declared across the five plans' frontmatter and map 1:1 to REQUIREMENTS.md's checklist (all marked `[x]` complete, phase 142, "Complete" in the traceability table). No orphaned requirements found for this phase.

### Anti-Patterns Found

None. Grep for `TODO|FIXME|HACK|XXX|TBD` across the phase's newly-created/modified source files (`accepted_advisories.ex`, `mailglass.audit.ex`, `mailglass.publish.check.ex`) returns no matches. No hardcoded empty-return stubs, no placeholder text, no debt markers.

### D-14 Wave-Ordering Verification

Confirmed structurally, not just by SUMMARY narrative: 142-03 (the D-14 checkpoint, recording live CI evidence + negative control) is a `checkpoint:human-verify` plan whose SUMMARY records a real CI run (PR #144, job 90481258959) predating 142-04's promotion commit. Git log order confirms 142-04's commit `34702fde` lands after 142-03's completion commit `45242ac9`. The precondition text in 142-04-PLAN.md ("Halt and report if that SUMMARY is missing or does not contain both excerpts") was honored — 142-03-SUMMARY.md contains both excerpts verbatim (live CI log naming both suppressed advisories; local negative-control output naming `EEF-CVE-2026-43969` on failure).

### Human Verification Required

None. All must-haves were independently reproducible via direct codebase reads, live command execution, and live `gh` API queries during this verification pass — no item required exclusively human/visual judgment beyond what the phase's own `verification: judgment` prohibitions (VULN-02's "no blanket disposition", VULN-04's "sustainable SLA tone") already resolved during execution with recorded reasoning in the SUMMARYs, which this verification found consistent with the actual dispositions and text.

### Gaps Summary

No gaps found. All five ROADMAP success criteria are independently verified against the live codebase and live GitHub state — not merely SUMMARY claims. The atomic promotion commit (`34702fde`) touches exactly the six files it claims, the allowlist mechanism genuinely detects-and-suppresses (not vacuously clean), the dependabot backlog is genuinely zero-indeterminate as of a live re-query in this session, and the triage documentation satisfies its four literal content requirements without corrupting the 24-row disposition-table parser.

---

_Verified: 2026-07-29_
_Verifier: Claude (gsd-verifier)_
