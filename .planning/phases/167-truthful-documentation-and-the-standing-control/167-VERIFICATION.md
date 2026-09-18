---
phase: 167-truthful-documentation-and-the-standing-control
verified: 2026-09-18T13:35:00Z
status: passed
score: 7/7 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 167: Truthful Documentation and the Standing Control Verification Report

**Phase Goal:** Correct false self-claims in mailglass's own documentation (release mechanics,
sibling-pin conventions, upgrade discoverability, code-adjacent doc drift) and add one standing
control (Dependabot batching) so the corrected claims and the underlying reality cannot silently
drift apart again.

**Verified:** 2026-09-18
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | DOCS-01: STATE.md contains no hardcoded open-PR/issue snapshot; points to live `gh` audit | ✓ VERIFIED | STATE.md prose (lines 32-39) delegates to `gh pr list`/`gh issue list`; `scripts/check_state_md_pr_refs.sh` run live → `pass: 7 check(s)`, exit 0, correctly resolved #222/#129 as CLOSED against live GitHub. `test/mailglass/state_md_contract_test.exs` (5 tests, 0 failures) forbids the *shape* `\d+\s+open\s+(PR\|pull request\|issue)` — a rewrite to a different number still fails. |
| 2 | DOCS-02: CLAUDE.md describes the release pipeline as it actually behaves | ✓ VERIFIED | `CLAUDE.md:56` states `~> <core-major.minor>` (matches `mailglass_admin/mix.exs`); `CLAUDE.md:119` states auto-merge is disarmed with protected candidate-digest dispatch, matching `release-please.yml:905` (`"Disarmed ordinary auto-merge; a later protected exact candidate-digest dispatch is required."`) and names `required_reviewers`/three approvals. `docs_contract_test.exs` "CLAUDE.md contract" describe block asserts both negatively and positively, scoped to the sibling-pin sentence only. |
| 3 | DOCS-03: Release-mechanics docs (MAINTAINING.md/CONTRIBUTING.md) are correct, and the exclude-paths count is *derived*, not hardcoded | ✓ VERIFIED | `release-please-config.json` has 14 exclude-paths (json-parsed); `MAINTAINING.md:168` says "fourteen" — matches. `docs_contract_test.exs:1116-1131` derives the count from the JSON file and a word map (not a duplicated literal) and refutes the stale "twelve" claim. "hands-free publish fan-out" phrase absent from MAINTAINING.md; corrected text (`:662-663`) names three `required_reviewers` stops. `## Release Close-Out` section present (`MAINTAINING.md:50-79`) naming all 5 ledger states, `scripts/release_policy_close_out.sh` (confirmed on disk, executable), and `scripts/check_published_baseline_of_record.sh` (confirmed on disk). CONTRIBUTING.md's deliberate-floor-bump instruction removed; unrelated `fix(inbound):` example at line 161 survives. |
| 4 | DOCS-04: The migration-guide sibling-pin lockstep is dissolved via a derived assertion + release-time sync, not hand-maintained agreement | ✓ VERIFIED | `docs_contract_test.exs:577-586` derives the expected pin from `package_major_minor!("mix.exs")` (currently `2.6`, matches guide's `~> 2.6` at line ~31) — no version literal. `dependency_constraint!/3` flunks with a named message if the dependency block is missing (`test/mailglass/docs_contract_test.exs:1359-1364`). `.github/workflows/release-please.yml` diff confirms `guides/migration-from-swoosh.md` was added to both the sed rewrite loop (line 441) and `SYNC_PATHS` (line 483) — the pin is now release-time generated. `guides/compatibility-and-deprecations.md` corrected from "exact sibling version" to "pessimistic `~>` constraint" (confirmed via diff). |
| 5 | DOCS-05: No config key is accepted without effect; code-adjacent docs match source | ✓ VERIFIED | `lib/mailglass/config.ex:85` narrows `css_inliner` type to `{:in, [:premailex]}` (was `[:premailex, :none]`). `test/mailglass/config_test.exs` inverted (not deleted) — `css_inliner: :none` now raises `NimbleOptions.ValidationError` naming `:premailex`; ran `mix test test/mailglass/config_test.exs` → 25 tests, 0 failures. `renderer.ex` untouched (confirmed no diff). `grep -rn css_inliner` outside `lib/mailglass/config.ex`/`test/mailglass/config_test.exs` hits only `.planning/` prose. `lib/mailglass/outbound.ex` moduledoc corrected — verified against real `lib/mailglass/events/reconciler.ex` source, which resolves orphan webhook `Event` rows (no matching Delivery), not orphan `:queued` Delivery rows; no `:queued`-reconciliation code exists anywhere in either reconciler module. `docs/api_stability.md:1119-1126`'s injected-forms/defoverridable list is asserted byte-identical (`docs_contract_test.exs:1033-1039`) against `lib/mailglass/mailable.ex`'s actual `__using__/1` quote block — confirmed matching on read. |
| 6 | DOCS-06: The v2.0 upgrade path is discoverable and honestly labeled | ✓ VERIFIED | `README.md:280` links `guides/upgrading-to-v2_0.md` (file exists on disk). Test generalizes via `Path.wildcard("guides/upgrading-*.md")` and asserts every file found is linked; an empty wildcard result flunks with a named message rather than passing vacuously (`docs_contract_test.exs:196-198`). `CHANGELOG.md`'s `## [2.0.0]` section (line 168) retains the original release-please-generated bullet verbatim (asserted at `docs_contract_test.exs`) and appends the schema-isolation breaking-change note naming Phases 132-137. |
| 7 | STAND-01: Dependabot produces batched, scheduled, reviewable PRs, not a serial pileup | ✓ VERIFIED | `.github/dependabot.yml` diff (additive-only) confirms all three `mix` entries gained `open-pull-requests-limit: 3` and a `mix-minor-patch` group scoped to `update-types: [minor, patch]`; majors stay ungrouped. `github-actions` and `docker` entries are byte-identical pre/post (diff shows zero touch). No `mix` entry added for `reference/host_app` or `reference/demo_app`. No second scheduled workflow/`.github/scheduled-controls.json` entry added (only `.github/workflows/release-please.yml` touched in the CI-adjacent surface, and that change is the DOCS-04 sed/SYNC_PATHS addition, not a new schedule). |

**Score:** 7/7 truths verified (0 present-but-behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `MAINTAINING.md` | Corrected release-mechanics prose + close-out runbook | ✓ VERIFIED | Derived exclude-paths count, hands-free claim removed, `## Release Close-Out` section complete and script-referenced |
| `CONTRIBUTING.md` | No deliberate `fix(inbound):` floor-bump instruction | ✓ VERIFIED | Removed; unrelated example survives |
| `CLAUDE.md` | Correct sibling-pin + auto-merge description | ✓ VERIFIED | Both corrected, scoped assertion in test |
| `README.md` | Links v2.0 upgrade guide | ✓ VERIFIED | Present, wildcard-generalized |
| `CHANGELOG.md` | 2.0.0 names schema-isolation breaking change | ✓ VERIFIED | Appended, original bullet intact |
| `guides/migration-from-swoosh.md` | Pin derived, not hand-maintained | ✓ VERIFIED | `~> 2.6` matches `mix.exs` `@version "2.6.0"` |
| `guides/compatibility-and-deprecations.md` | No false "exact pin" claim | ✓ VERIFIED | Corrected to `~>` constraint language |
| `.github/workflows/release-please.yml` | Migration guide added to pin-resync | ✓ VERIFIED | sed loop + SYNC_PATHS both updated |
| `lib/mailglass/config.ex` | `css_inliner: :none` rejected | ✓ VERIFIED | Type narrowed to `{:in, [:premailex]}` |
| `test/mailglass/config_test.exs` | Inverted acceptance test | ✓ VERIFIED | 25 tests, 0 failures |
| `lib/mailglass/outbound.ex` | Moduledoc matches Reconciler reality | ✓ VERIFIED | Confirmed against real reconciler source |
| `docs/api_stability.md` | Injected-forms list matches source | ✓ VERIFIED | Byte-identical `defoverridable` string, pinned |
| `.planning/STATE.md` | No hardcoded PR/issue snapshot | ✓ VERIFIED | Shape-refusing regex test, 5/5 passing |
| `scripts/check_state_md_pr_refs.sh` | Live 3-way exit-code audit | ✓ VERIFIED | Ran live: exit 0, correctly resolved all 7 references |
| `test/mailglass/state_md_contract_test.exs` | Offline pin in `support_contract_core` | ✓ VERIFIED | Present in `mix.exs` alias list (line 324); 5 tests, 0 failures |
| `.github/dependabot.yml` | Grouped minor/patch, capped at 3 | ✓ VERIFIED | Additive-only diff confirmed |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `release-please-config.json` exclude-paths | `docs_contract_test.exs` derived count | `Jason.decode!` + `count_word!/1` | ✓ WIRED | Live JSON parse used at test time, no literal |
| `test/mailglass/state_md_contract_test.exs` | `mix.exs` `support_contract_core` alias | file listed in alias command | ✓ WIRED | Confirmed present at mix.exs:324 |
| `.release-please-manifest.json`/`mix.exs` version | `guides/migration-from-swoosh.md` pin | `package_major_minor!/1` derived assertion + release-time sed | ✓ WIRED | Both the test-time derivation and the CI-time sed/SYNC_PATHS additions confirmed |
| `lib/mailglass/mailable.ex` `__using__/1` | `docs/api_stability.md` injected-forms list | byte-identical `defoverridable` string assertion | ✓ WIRED | Confirmed matching source text |
| `scripts/check_state_md_pr_refs.sh` | live GitHub via `gh` | `gh pr view`/`gh issue view` | ✓ WIRED | Ran live against szTheory/mailglass, resolved #222/#129/#257/#260/#263/#266/#267 correctly |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| config_test.exs css_inliner rejection | `mix test test/mailglass/config_test.exs` | 25 tests, 0 failures | ✓ PASS |
| docs_contract_test.exs full suite | `mix test test/mailglass/docs_contract_test.exs` | 60 tests, 0 failures, 1 skipped (pre-existing) | ✓ PASS |
| state_md_contract_test.exs | `mix test test/mailglass/state_md_contract_test.exs` | 5 tests, 0 failures | ✓ PASS |
| check_state_md_pr_refs.sh live audit | `bash scripts/check_state_md_pr_refs.sh` | `pass: 7 check(s)`, exit 0 | ✓ PASS |
| check_state_md_pr_refs.sh zero-refs contract | `bash scripts/check_state_md_pr_refs.sh --target <empty file>` | `pass: 0 references found`, exit 0 | ✓ PASS |
| support_contract_core regression lane | `mix verify.support_contract.core` | 127 total (126 executed + 1 skipped), 0 failures | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| DOCS-01 | 167-04 | STATE.md no false claims, live-audited | ✓ SATISFIED | See Truth #1 |
| DOCS-02 | 167-02 | CLAUDE.md release-pipeline accuracy | ✓ SATISFIED | See Truth #2 |
| DOCS-03 | 167-01 | MAINTAINING/CONTRIBUTING accuracy + close-out runbook | ✓ SATISFIED | See Truth #3 |
| DOCS-04 | 167-03 | Migration-guide lockstep dissolved | ✓ SATISFIED | See Truth #4 |
| DOCS-05 | 167-03 | No inert config key; code-doc drift closed | ✓ SATISFIED | See Truth #5 |
| DOCS-06 | 167-02 | v2.0 upgrade path discoverable | ✓ SATISFIED | See Truth #6 |
| STAND-01 | 167-04 | Dependabot batching/scheduling | ✓ SATISFIED | See Truth #7 |

No orphaned requirements — REQUIREMENTS.md maps exactly these 7 IDs to Phase 167, all 7 appear in plan frontmatter `requirements:` fields.

### Anti-Patterns Found

None. Scanned all 12 phase-modified non-planning files for `TBD|FIXME|XXX|TODO|HACK|PLACEHOLDER` — the only hits were false positives (the substring "TODO" inside "JTBD" in `MAINTAINING.md`/`CLAUDE.md`, and a pre-existing CHANGELOG line documenting a *past* TODO removal). No `@tag :skip` was added by this phase (the one skip in `docs_contract_test.exs` predates it, confirmed via `git show 800a0524:...`). No existing assertion was deleted — the diff on `test/mailglass/docs_contract_test.exs` shows only the stale hardcoded `~> 2.5` literal removed and replaced by the derived assertion; `test/mailglass/config_test.exs`'s acceptance case was inverted, not removed.

### Scope and Prohibition Compliance

- **`lib/` scope:** `git diff --name-only 800a0524..HEAD -- lib/` → exactly `lib/mailglass/config.ex` and `lib/mailglass/outbound.ex`. Confirmed no other `lib/` file touched, and `outbound.ex`'s change is moduledoc-only (verified via diff — no code lines changed).
- **No gate weakened:** `.github/dependabot.yml` diff is purely additive to the three `mix` entries; `github-actions` and `docker` entries are byte-identical. No `.github/scheduled-controls.json` entry added — the only workflow file touched is `release-please.yml`, and that change extends the existing sed/SYNC_PATHS mechanism rather than adding a new control.
- **Minor residual finding (non-blocking):** `.github/workflows/release-please.yml:373` still contains a stale comment ("the release PR auto-merges on green") that contradicts the corrected step echo at line 905 and the corrected CLAUDE.md prose. This comment was not touched by this phase's diff (confirmed — the phase's only edit to this file was the sed-loop/SYNC_PATHS addition at lines 441/483) and is not one of the phase's `files_modified` artifacts, so it does not block DOCS-02 (which only claims CLAUDE.md's own text is accurate — and it is). Flagging for future cleanup since it is exactly the kind of self-contradictory internal comment the v2.8 stop line cares about, but it is out of this phase's declared scope.

### Human Verification Required

None. All must-haves resolved via file inspection, derived-assertion tracing, and running the actual test files/scripts (not merely reading SUMMARY.md claims).

### Gaps Summary

No gaps. All 7 requirements are verified against the actual codebase — the corrected claims match their underlying source of truth (release-please-config.json, release-please.yml, mailable.ex, reconciler.ex, mix.exs), and each correction is pinned by a test that would fail if the claim drifted again (derived JSON/version lookups rather than duplicated literals, in line with DOCS-04's explicit intent to dissolve the two-file lockstep permanently). The one residual stale comment noted above is pre-existing, out of this phase's scope, and does not affect any of the 7 must-haves.

---

_Verified: 2026-09-18_
_Verifier: Claude (gsd-verifier)_
