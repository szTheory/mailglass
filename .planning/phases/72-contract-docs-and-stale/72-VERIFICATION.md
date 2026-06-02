---
phase: 72-contract-docs-and-stale
verified: 2026-06-02T10:38:00Z
status: passed
score: 20/20 must-haves verified
re_verification: false
decision_coverage:
  honored: 16
  total: 16
  not_honored: []
deferred:
  - truth: "Live Hex index URL, HexDocs URL, workflow run URL, smoke/install proof, and 60-minute revert/retire decision"
    addressed_in: "Phase 73"
    evidence: "Phase 73: Inbound 1.0 Publish Evidence — run or prepare the inbound-only publish path and record Hex, HexDocs, smoke, fallback, and 60-minute decision evidence. (explicitly excluded from Plan 03 per D-10)"
  - truth: "Reference/demo app published-Hex pins (~> 0.3) remain Phase 73 scope; no demo app lockfiles modified"
    addressed_in: "Phase 73"
    evidence: "D-13: demo app published-Hex pins are publish-evidence work belonging to Phase 73; this plan does not touch demo lockfiles (confirmed — no demo lockfile in phase-72 diff)"
---

# Phase 72: Contract Docs and Stale-Claim Guards Verification Report

**Phase Goal:** Update public wording and executable docs/release checks so `mailglass_inbound` is described as its own stable `1.0` package contract (not `v0.5+`/`0.3`/outside-stability), preserve the matched `mailglass`/`mailglass_admin` `1.x` sibling line, and pin the highest-risk stale claims (install version, package-table status, runbook smoke deps, inbound-only release wording, source_ref tag) with executable guards.
**Verified:** 2026-06-02T10:38:00Z
**Status:** passed

## Goal Achievement

### Observable Truths

Aggregated across 72-01 (11 truths), 72-02 (3), 72-03 (6). Negative-scope/exclusion truths (D-10/D-13) are moved to Deferred Items below and excluded from the score denominator as they describe work intentionally assigned to Phase 73.

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | jobs.md describes inbound as own independent stable `1.0` contract, not outside v1.x | ✓ VERIFIED | guides/jobs.md:5,416 "its own independent stable `1.0` contract"; no "outside the `v1.x` stability promise" remains |
| 2 | compat guide support-matrix row says independent `1.0` contract, not excluded from 1.x | ✓ VERIFIED | compatibility-and-deprecations.md:166 "independent `1.0` contract; see mailglass_inbound/docs/api_stability.md" |
| 3 | compat guide DX inventory support-until horizons say Through mailglass_inbound `1.x` not `0.x` | ✓ VERIFIED | compatibility-and-deprecations.md:217-219 all three rows "Through `mailglass_inbound` `1.x`"; no `0.x` horizon |
| 4 | MAINTAINING.md JTBD step 5 routes to mailglass_inbound/docs/api_stability.md, not outside-v1.x | ✓ VERIFIED | MAINTAINING.md:117-118 "its own independent `1.0` contract and routing readers to mailglass_inbound/docs/api_stability.md" |
| 5 | mix mailglass.docs.check exits 0 on corrected docs | ✓ VERIFIED | `mix verify.stability_contract` (clean tree) ends "[mailglass.docs.check] OK — Tier 1 docs match the stability contract" |
| 6 | mix test docs_contract_test.exs passes (updated freshness + MAINTAINING) | ✓ VERIFIED | Ran: docs_contract_test.exs green within 40/0/1 root run; assertions at :51,:202-203,:363,:365 |
| 7 | api_stability.md remains canonical; edited docs route there without competing inventories (D-04) | ✓ VERIFIED | Edited docs use summary+route wording pointing at mailglass_inbound/docs/api_stability.md; no duplicate inventory introduced |
| 8 | All stale-phrase guards use exact-token matching, not regex/dynamic parsing (D-06) | ✓ VERIFIED | docs.check.ex @tier1_surface_rules use literal required/forbidden strings; test guards use literal assert/refute =~ strings |
| 9 | Guards use 1.0 for inbound contract; do not ban 1.x in DX horizons describing future break policy (D-07) | ✓ VERIFIED | "independent `1.0` contract" for contract; DX horizons assert "Through `mailglass_inbound` `1.x`" (refute_over_claims! avoided per SUMMARY decision) |
| 10 | Replacement wording makes adopter workflow obvious without blurring framework/provider semantics (D-14) | ✓ VERIFIED | Prose routes to api_stability.md; provider detail kept at Plug-option level (review confirmed Job-10 callback shapes match) |
| 11 | Provider stability kept at Ingress.Plug option/semantic level; provider modules internal (D-15) | ✓ VERIFIED | compat-guide DX rows reference Plug/CachingBodyReader/Router/Mailbox public surfaces, not internal provider modules |
| 12 | inbound docs-contract test asserts corrected DX horizon wording (1.x) | ✓ VERIFIED | inbound docs_contract_test.exs:515 `assert compatibility =~ "Through \`mailglass_inbound\` \`1.x\`"` |
| 13 | inbound docs-contract test refutes stale 0.x horizon | ✓ VERIFIED | inbound docs_contract_test.exs:514 `refute compatibility =~ "Through \`mailglass_inbound\` \`0.x\`"`; both inside always-run adoption-path block |
| 14 | all existing inbound docs_contract compat-token assertions still pass | ✓ VERIFIED | Ran: `mix test docs_contract_test.exs --seed 0` → 22 tests, 0 failures |
| 15 | mailglass_inbound/mix.exs source_ref_pattern is mailglass_inbound-v%{version} (D-08) | ✓ VERIFIED | mix.exs:123 `source_ref_pattern: "mailglass_inbound-v%{version}"`; no "mailglass-sibling-group" |
| 16 | publish-summary.json source_ref_pattern reflects corrected value | ✓ VERIFIED | mailglass_inbound-publish-summary.json:201 `"source_ref_pattern": "mailglass_inbound-v%{version}"` |
| 17 | stability_contract_test.exs asserts summary source_ref_pattern == mailglass_inbound-v%{version} | ✓ VERIFIED | stability_contract_test.exs:173 `assert summary["source_ref_pattern"] == "mailglass_inbound-v%{version}"` |
| 18 | mix verify.stability_contract exits 0 (all three lanes green) | ✓ VERIFIED | Ran with untracked phase-45/48 WIP dup migration set aside: 29 tests, 0 failures + docs.check OK. See Behavioral note. |
| 19 | (72-01 README guard) docs.check forbids stale inbound posture, requires stable 1.0 | ✓ VERIFIED | docs.check.ex:77-78 required "stable 1.0" / "stable `1.0` contract inventory"; :86 forbidden "outside the `v1.x` stability promise" |
| 20 | WR-01..WR-04 review warnings resolved with substantive fixes | ✓ VERIFIED | Commits ab116f4f/fcdf5b45/5a367d8a; changelog stub-detection, --path normalization, ceremony-agnostic consistency assertions confirmed in source |

**Score:** 20/20 truths verified

### Deferred Items

Negative-scope truths intentionally assigned to Phase 73; not actionable gaps.

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Live Hex/HexDocs/workflow URLs, smoke/install proof, 60-min revert decision (D-10) | Phase 73 | Phase 73 goal: "record Hex, HexDocs, smoke, fallback, and 60-minute decision evidence" |
| 2 | Demo-app published-Hex pins (~> 0.3); no demo lockfiles modified (D-13) | Phase 73 | D-13 in 72-03 plan; confirmed no demo lockfile in phase-72 diff |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| guides/jobs.md | Corrected inbound stability header/footer | ✓ VERIFIED | "independent stable `1.0` contract" present; stale phrase gone; verify.artifacts pass |
| guides/compatibility-and-deprecations.md | Corrected matrix row + DX horizons | ✓ VERIFIED | row:166, horizons:217-219 all `1.x`; verify.artifacts pass |
| MAINTAINING.md | Corrected JTBD step 5 | ✓ VERIFIED | :117-118 routes to api_stability.md; verify.artifacts pass |
| lib/mix/tasks/mailglass.docs.check.ex | Flipped README required/forbidden + compat forbidden token + WR-02 fix | ✓ VERIFIED | :77-78 required, :86 forbidden, :264 compat token; --path normalization added (fcdf5b45) |
| test/mailglass/docs_contract_test.exs | Updated freshness + MAINTAINING assertions | ✓ VERIFIED | :51,:202-203,:363,:365 paired assert/refute guards |
| mailglass_inbound/test/.../docs_contract_test.exs | DX horizon guards + WR-01 changelog fix | ✓ VERIFIED | :514-515 horizon guards; :560-575 explicit stub detection (ab116f4f) |
| mailglass_inbound/mix.exs | Corrected source_ref_pattern | ✓ VERIFIED | :123 inbound-specific tag |
| .planning/publish/mailglass_inbound-publish-summary.json | Regenerated summary | ✓ VERIFIED | :201 corrected source_ref_pattern |
| test/mailglass/stability_contract_test.exs | source_ref assertion + WR-03/04 consistency | ✓ VERIFIED | :173 source_ref assertion; :116-150 artifact-derived consistency (5a367d8a) |

**Artifacts:** 9/9 verified

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| docs.check.ex | README.md | @tier1_surface_rules required/forbidden | ✓ WIRED | SDK reported false due to backtick-less pattern spec (`stable 1\.0` vs actual `stable \`1.0\``). Actual wiring real: README:21 "stable 1.0"; rules at docs.check.ex:77-78,86. False-negative on pattern string, not missing link. |
| docs_contract_test.exs | guides/jobs.md | File.read! freshness assertion | ✓ WIRED | SDK verified; jobs.md read + asserted at :363 |
| inbound docs_contract_test.exs | compat guide | File.read! @compatibility_path | ✓ WIRED | SDK verified |
| stability_contract_test.exs | publish-summary.json | json!/1 reads summary | ✓ WIRED | SDK verified; assertion at :173 |

**Wiring:** 4/4 connections verified (1 SDK false-negative manually confirmed WIRED)

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| DOC-01 | 72-01 | Adopter docs describe inbound as own stable 1.0 routed through api_stability.md | ✓ SATISFIED | Truths 1,2,4,7 + docs.check guard |
| DOC-02 | 72-01 | Compat docs preserve matched 1.x sibling line, separate inbound 1.0, no widened core/admin promises | ✓ SATISFIED | Truth 2,3; sibling rows preserved (review verified 28 rules map 1:1); no core/admin widening |
| PROOF-02 | 72-01/02/03 | Executable docs/release checks pin stale claims (install version, table status, runbook smoke deps, inbound-only release wording, source_ref) | ✓ SATISFIED | docs.check rules + docs_contract refute/assert guards + stability source_ref assertion; all suites green |

**Coverage:** 3/3 requirements satisfied. No orphaned requirements (REQUIREMENTS.md maps only DOC-01/DOC-02/PROOF-02 to Phase 72; all claimed by plans).

### Decision Coverage

All 16 trackable CONTEXT.md decisions are honored by shipped artifacts (16/16). Non-blocking gate — recorded for drift tracking.

## Behavioral Verification

| Check | Result | Detail |
|-------|--------|--------|
| Root suite (stability_contract + docs_check_task + docs_contract) | 40 passed, 0 failed, 1 skipped | 1 skip = known IN-01 @tag :skip Phase-38 test (not phase-72-linked) |
| Inbound docs_contract_test.exs --seed 0 | 22 passed, 0 failed | DX horizon guards green |
| mix verify.stability_contract (as-is) | ✗ fails | duplicate_column on UNTRACKED phase-45/48 WIP migration 20260508130000_*, before any phase-72 assertion |
| mix verify.stability_contract (WIP dup set aside) | 29 passed, 0 failed + docs.check OK | Proves phase-72 deliverable is correct; failure is environmental WIP pollution, not a phase-72 gap |

**Attribution note (truth 18):** `mix verify.stability_contract` fails in the current working tree solely because of `mailglass_inbound/priv/repo/migrations/20260508130000_add_suppression_flagged_to_inbound_records.exs` — an UNTRACKED file (git status `??`) that duplicates the committed `20260525000000_*` migration. No phase-72 commit touched it. Setting it aside makes all three lanes pass cleanly. This is logged in the phase's deferred-items.md and matches the documented "inbound suite flake / untracked WIP" memory. Phase 72's committed work satisfies the truth.

## Test Quality Audit

| Test File | Linked Req | Active | Skipped | Circular | Assertion Level | Verdict |
|-----------|-----------|--------|---------|----------|----------------|---------|
| test/mailglass/docs_contract_test.exs | DOC-01/02, PROOF-02 | many | 1 (Phase-38, NOT phase-72-linked) | No | Value (paired assert presence / refute stale token) | ✓ SUFFICIENT |
| mailglass_inbound/test/.../docs_contract_test.exs | PROOF-02 | 22 | 0 | No | Value (assert/refute exact tokens) | ✓ SUFFICIENT |
| test/mailglass/stability_contract_test.exs | PROOF-02 | 6 | 0 | No | Value/consistency (artifact-derived after WR-03/04) | ✓ SUFFICIENT |

**Disabled tests on requirements:** 0 (the 1 skip is an archived-Phase-38 artifact test, not linked to DOC-01/02/PROOF-02).
**Circular patterns:** 0. Guards refute against the always-populated doc files; source_ref assertion pins a literal contract value.
**Insufficient assertions:** 0.
**WR-01 adversarial cross-check:** The review's vacuous-refute concern (changelog Unreleased stub) was real and is now fixed — the guard explicitly detects the empty stub and records a visible assertion when dormant, engaging the full over-claim guard only when populated. The always-run prose guards (stable/readme_active/install_active and the DX horizon refute/assert) are NOT vacuous: they run against permanently-populated surfaces. The guards prove what they claim.

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| (none) | - | No TBD/FIXME/XXX/TODO/HACK in any phase-72-modified file | - | Clean |
| test/mailglass/docs_contract_test.exs | 249-261 | @tag :skip Phase-38 test with stale "Phase 51 closeout" follow-up note | ℹ️ Info | Known IN-01; not phase-72-linked; v1.6 quiet-maintenance posture intentionally leaves it. Acknowledged, not a blocker. |

**Anti-patterns:** 0 blockers, 0 warnings, 1 info (pre-existing, acknowledged).

The remaining Info findings IN-02 (tenancy.ex mojibake), IN-03 (jobs.md Job-3 HTML interpolation), IN-04 (docs.check re-read) were deliberately left unfixed per the v1.6 quiet-maintenance scope lock and are out of phase-72's diff (IN-02) or doc-quality-only. None block the phase goal.

## Human Verification

N/A — Infrastructure/docs-and-tooling phase with no user-facing runtime. All acceptance criteria (corrected public wording + executable guards + package metadata) are verifiable programmatically and were verified via the test suites and source inspection above.

## Gaps Summary

**No gaps found.** Phase goal achieved.

All 20 in-scope must-have truths verified, 9/9 artifacts substantive and wired, 4/4 key links wired (one SDK false-negative manually confirmed), 3/3 requirements satisfied, 16/16 decisions honored. Test suites green (40/0/1 root; 22/0 inbound; 29/0 full stability chain once unrelated untracked WIP is set aside). All four code-review Warnings (WR-01..WR-04) fixed with substantive changes. The only non-green command (`mix verify.stability_contract` in the as-is working tree) is attributable entirely to an untracked phase-45/48 WIP duplicate migration that is not part of phase 72's deliverable and not in git history — proven by re-running with the file set aside. Two negative-scope truths (live publish evidence, demo pins) are correctly deferred to Phase 73.

Ready to proceed.

---
*Verified: 2026-06-02T10:38:00Z*
*Verifier: Claude (gsd-verifier)*
