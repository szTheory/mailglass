---
phase: 125-sibling-pin-loosening-keystone-atomic
verified: 2026-07-01T14:00:00Z
status: passed
score: 7/7 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 125: Sibling Pin Loosening (Keystone Atomic Change) Verification Report

**Phase Goal:** Kill the exact-pin release dance — replace both sibling `{:mailglass, "== X.Y.Z"}` exact pins with pessimistic `~>` constraints and relax every gate that enforced exact equality, as ONE indivisible atomic change, so a core patch release no longer drags a paired sibling release and a bare main SHA is GREEN with an unchanged core @version.

**Verified:** 2026-07-01T14:00:00Z
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| #   | Truth                                                                                                                                       | Status     | Evidence                                                                                                                                                                                           |
|-----|---------------------------------------------------------------------------------------------------------------------------------------------|------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1   | Inbound published dep is `{:mailglass, "~> 1.10 and >= 1.10.2"}`; admin is `{:mailglass, "~> 1.10"}` (PIN-01)                              | VERIFIED   | `mailglass_inbound/mix.exs` line 129: `{:mailglass, "~> 1.10 and >= 1.10.2"}`. `mailglass_admin/mix.exs` line 145: `{:mailglass, "~> 1.10"}`. No `"== 1.10.2"` literal in either file.           |
| 2   | stability_contract_test asserts inbound pin ADMITS core @version via Version.match? and REJECTS bare `==` (PIN-02)                         | VERIFIED   | Both tests relaxed: pin-shape test (lines 110-120) and preflight-consistency test (lines 172-184) use `refute String.starts_with?(..., "==")` + `assert Version.match?`. 6 tests, 0 failures.     |
| 3   | Committed `mailglass_inbound_publish_pin` is the `~>` string AND preflight-consistency line ~179 asserts admit-`~>`-reject-`==` (PIN-02/05) | VERIFIED   | `.planning/publish/mailglass_inbound-publish-summary.json` line 120: `"mailglass_inbound_publish_pin": "~> 1.10 and >= 1.10.2"`. The test's line ~207-212 asserts `refute starts_with?(pin, "==")` + `Version.match?`. |
| 4   | publish.check `verify_deps` and `verify_linked_constraint` accept any `~>` that Version.match?-es core @version and reject `==` (PIN-02)   | VERIFIED   | Shared private predicate `mailglass_constraint_admits_core?/2` at line 854: `not String.starts_with?(req, "==") and Version.match?(core_version, req)`. Used in both `verify_deps` (line 779) and `verify_linked_constraint` (line 829). |
| 5   | release-please.yml no longer contains `== X.Y.Z` sibling sed rewrites; a simulated core patch touches zero sibling pin lines (PIN-03)     | VERIFIED   | `PINS=(` absent; no `sed .*==` rewrite; no `pins to ==`; no `"== ${CORE_VERSION}"` jq arg. The jq `--arg pin "~> ${CORE_MM} and >= ${CORE_VERSION}"` (line 210) emits `~>`. Sibling `mix.exs` files removed from `SYNC_PATHS`. grep confirms 0 `== [0-9]` matches in either sibling file. |
| 6   | CHANGELOG entry in all three packages + MAINTAINING.md documents `mix hex.retire` as the rollback lever (PIN-04)                           | VERIFIED   | Core CHANGELOG lines 21-23: pessimistic `~>` / ending paired-release. Admin CHANGELOG lines 11-12: `~> 1.10` instead of exact pin. Inbound CHANGELOG lines 12-14: LD-5 verbatim wording. MAINTAINING.md lines 239-260: full `~>` Sibling Pin rollback subsection with resolver-degrees-of-freedom rationale and `mix hex.retire mailglass X.Y.Z` command. |
| 7   | The whole change is green on a bare main SHA where core @version is unchanged — the scenario that was RED before (PIN-05)                   | VERIFIED   | `mix test test/mailglass/stability_contract_test.exs` → 6 tests, 0 failures. `cd mailglass_admin && mix test test/mailglass_admin/mix_config_test.exs` → 4 tests, 0 failures. All run on bare main SHA with core @version = 1.10.2 (unchanged). |

**Score:** 7/7 truths verified (0 present, behavior-unverified)

---

### Required Artifacts

| Artifact                                                          | Expected                                    | Status      | Details                                                                                    |
|-------------------------------------------------------------------|---------------------------------------------|-------------|--------------------------------------------------------------------------------------------|
| `mailglass_inbound/mix.exs`                                       | Pin + trap comment updated                  | VERIFIED    | `~> 1.10 and >= 1.10.2` at line 129; comment rewrites lines 114-126 describe new `~>` reality. |
| `mailglass_admin/mix.exs`                                         | Pin + comment updated                       | VERIFIED    | `~> 1.10` at line 145; comment lines 135-148 describe linked-versions safety reasoning.    |
| `lib/mix/tasks/mailglass.publish.check.ex`                        | Relaxed verify_deps / verify_linked_constraint | VERIFIED | Shared predicate `mailglass_constraint_admits_core?/2` at lines 850-856; used at lines 779, 829. |
| `test/mailglass/stability_contract_test.exs`                      | Both tests relaxed (admit-~>-reject-==)     | VERIFIED    | Pin-shape test lines 106-120; preflight-consistency test lines 172-184 and 207-212.        |
| `.planning/publish/mailglass_inbound-publish-summary.json`        | `mailglass_inbound_publish_pin` = `~>` string | VERIFIED  | Line 120: `"~> 1.10 and >= 1.10.2"` — not `"== 1.10.2"`.                                 |
| `mailglass_admin/test/mailglass_admin/mix_config_test.exs`        | Relaxed pin; REL-05 block removed           | VERIFIED    | Test line 52-56: `refute starts_with?` + `Version.match?`. REL-05 describe block absent.  |
| `CHANGELOG.md`, `mailglass_admin/CHANGELOG.md`, `mailglass_inbound/CHANGELOG.md` | Constraint-change entries   | VERIFIED    | All three carry the required entries per PIN-04.                                           |
| `MAINTAINING.md`                                                  | `mix hex.retire` rollback documented        | VERIFIED    | Lines 239-260: full subsection with command, rationale, and contrast to old `==` behavior. |
| `test/fixtures/release_please_sed_test.sh`                        | Deleted                                     | VERIFIED    | File absent: `test ! -f` confirms.                                                         |
| `test/fixtures/mix_exs_release_please_sed/mix.exs.before`        | Deleted                                     | VERIFIED    | File absent.                                                                               |
| `test/fixtures/mix_exs_release_please_sed/mix.exs.after`         | Deleted                                     | VERIFIED    | File absent.                                                                               |
| `CONTRIBUTING.md`                                                 | `==` sed section removed / rewritten        | VERIFIED    | Section now titled "How release-please syncs README install pins (and what it no longer does)"; accurately describes `~>` reality; no reference to `==` sed or REL-05.  |

---

### Key Link Verification

| From                                         | To                                                             | Via                                                                   | Status   | Details                                                                                                                                          |
|----------------------------------------------|----------------------------------------------------------------|-----------------------------------------------------------------------|----------|--------------------------------------------------------------------------------------------------------------------------------------------------|
| `publish.check verify_deps`                  | `mailglass_constraint_admits_core?/2`                          | Call at line 779                                                      | WIRED    | Shared predicate invoked by both verification functions; records `~>` req string into `sibling_publish_pin_key` on accept path.                  |
| `publish.check verify_linked_constraint`     | `mailglass_constraint_admits_core?/2`                          | Call at line 829                                                      | WIRED    | Same shared predicate; consistency with `verify_deps` guaranteed.                                                                                |
| `stability_contract_test` line ~179          | `.planning/publish/mailglass_inbound-publish-summary.json`     | `json!()` read + `summary["mailglass_inbound_publish_pin"]` assertion | WIRED    | Test reads the committed JSON; asserts `refute starts_with?(summary_pin, "==")` + `Version.match?`. JSON field is `"~> 1.10 and >= 1.10.2"`.    |
| `release-please.yml` jq block                | `.planning/publish/mailglass_inbound-publish-summary.json`     | `--arg pin "~> ${CORE_MM} and >= ${CORE_VERSION}"` at line 210-211   | WIRED    | Future release ceremonies will write the `~>` string into the field, keeping JSON + test assertion consistent.                                   |
| `release-please.yml` SYNC_PATHS              | Sibling `mix.exs` files                                        | Absence (removed from SYNC_PATHS)                                     | WIRED    | Both `mailglass_admin/mix.exs` and `mailglass_inbound/mix.exs` absent from SYNC_PATHS; a core patch release no longer touches those files.       |

---

### Behavioral Spot-Checks

| Behavior                                                                  | Command                                                                    | Result                   | Status  |
|---------------------------------------------------------------------------|----------------------------------------------------------------------------|--------------------------|---------|
| stability_contract_test BOTH tests GREEN on bare main SHA                 | `mix test test/mailglass/stability_contract_test.exs`                      | 6 tests, 0 failures      | PASS    |
| admin mix_config_test GREEN (relaxed pin + REL-05 removed)                | `cd mailglass_admin && mix test test/mailglass_admin/mix_config_test.exs`  | 4 tests, 0 failures      | PASS    |
| No `== ` literal in sibling mix.exs                                       | `grep -n '"== ' mailglass_inbound/mix.exs mailglass_admin/mix.exs`         | (no output)              | PASS    |
| `PINS=(` absent from release-please.yml                                   | `grep -n 'PINS=(' .github/workflows/release-please.yml`                    | (no output)              | PASS    |
| `~>` jq arg in release-please.yml (not `"== ${CORE_VERSION}"`)           | `grep -n 'arg pin' .github/workflows/release-please.yml`                   | `--arg pin "~> ${CORE_MM} and >= ${CORE_VERSION}"` | PASS |
| Commit message no longer references `==`                                  | `grep -n 'sync.*==' .github/workflows/release-please.yml`                  | (no output)              | PASS    |

---

### Requirements Coverage

| Requirement | Description                                                                                            | Status    | Evidence                                                                    |
|-------------|--------------------------------------------------------------------------------------------------------|-----------|-----------------------------------------------------------------------------|
| PIN-01      | Both sibling pins replaced with `~>` behind MIX_PUBLISH                                               | SATISFIED | `mailglass_inbound/mix.exs:129`, `mailglass_admin/mix.exs:145`              |
| PIN-02      | stability_contract_test + publish.check assert admit-`~>`-reject-`==` via Version.match?              | SATISFIED | `mailglass_constraint_admits_core?/2`; both test files relaxed; tests GREEN  |
| PIN-03      | Two `== X.Y.Z` sed rewrites deleted; core patch touches zero sibling pin lines                        | SATISFIED | `PINS=(` absent; SYNC_PATHS stripped; grep confirms 0 `==` matches in sibling files |
| PIN-04      | CHANGELOG entries + `mix hex.retire` rollback lever documented                                        | SATISFIED | All 3 CHANGELOGs; MAINTAINING.md lines 239-260                              |
| PIN-05      | Whole change lands atomically; GREEN on bare main SHA with unchanged core @version                    | SATISFIED | Single commit `37dcaf11`; both test suites GREEN on main with core = 1.10.2 |

---

### D-23 Scope Fence

Commit `37dcaf11` stat shows 17 files changed — all within pins, gates, workflow, docs, and test fixtures. No `lib/mailglass/**` runtime path appears in the diff. No migrations or routes modified. Scope fence held.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| (none) | — | — | — | — |

No `TBD`, `FIXME`, `XXX`, placeholder returns, or stub patterns found in the modified files.

---

### Human Verification Required

None. All required truths are verifiable programmatically and the behavioral tests passed on the live codebase.

---

## Gaps Summary

No gaps. All seven must-have truths are VERIFIED by direct codebase inspection and passing behavioral tests. The atomicity and latent-red-closure claims are real:

- The committed publish-summary JSON carries `"~> 1.10 and >= 1.10.2"` (not the stale `"== 1.10.2"`).
- The preflight-consistency test's line ~179 assertion uses `refute/assert Version.match?` — not the old `== "== #{expected_core_version}"` string equality — and the test is GREEN on the live bare main SHA.
- The `PINS=(` sed loop and its `==` rewrite are absent from `release-please.yml`; the jq arg emits `~>`.
- Three deleted fixture files are confirmed absent.
- Both scoped test suites run clean: 6+4 tests, 0 failures.

---

_Verified: 2026-07-01T14:00:00Z_
_Verifier: Claude (gsd-verifier)_
