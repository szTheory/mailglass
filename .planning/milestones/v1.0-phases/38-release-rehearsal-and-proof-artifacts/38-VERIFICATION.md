---
phase: 38-release-rehearsal-and-proof-artifacts
verified: 2026-05-06T08:48:00Z
status: passed
score: 4/4 must-haves verified
overrides_applied: 0
deferred:
  - truth: "Live branch-protection confirmation remains external closeout proof rather than repo-controlled truth."
    addressed_in: "Accepted release-closeout debt"
    evidence: "38-03-BRANCH-PROTECTION-NOTE.md and 38-03-RELEASE-RECORD.md explicitly record this as manual/external proof."
human_verification: []
---

# Phase 38: Release Rehearsal & Proof Artifacts Verification Report

**Phase Goal:** Maintainers have fresh proof artifacts showing the documented install, upgrade, docs, and sibling-package release flow are trustworthy enough for `v1.0`.
**Verified:** 2026-05-06T08:48:00Z
**Status:** passed
**Re-verification:** Yes - after fresh proof reruns on 2026-05-06

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Maintainers can prove a clean Phoenix app can install released `mailglass` and `mailglass_admin` packages, mount admin, and complete the documented first-send workflow. | ✓ VERIFIED | Release smoke workflow and test mirror align in [.github/workflows/post-publish-smoke.yml](/Users/jon/projects/mailglass/.github/workflows/post-publish-smoke.yml:230), [test/mailglass/install/install_first_preview_smoke_test.exs](/Users/jon/projects/mailglass/test/mailglass/install/install_first_preview_smoke_test.exs:1), and [test/mailglass/install/install_first_send_smoke_test.exs](/Users/jon/projects/mailglass/test/mailglass/install/install_first_send_smoke_test.exs:1); the install/first-send bundle passed on 2026-05-06. |
| 2 | Maintainers can prove the latest `0.x` upgrade path reaches `v1.0` using the documented migration steps and strict smoke checks. | ✓ VERIFIED | [guides/upgrading-to-v1_0.md](/Users/jon/projects/mailglass/guides/upgrading-to-v1_0.md:224), [test/mailglass/docs_migration_smoke_test.exs](/Users/jon/projects/mailglass/test/mailglass/docs_migration_smoke_test.exs:1), and [38-02-REHEARSAL-EVIDENCE.md](/Users/jon/projects/mailglass/.planning/phases/38-release-rehearsal-and-proof-artifacts/38-02-REHEARSAL-EVIDENCE.md:25) align, and `mix verify.docs.migration` passed on 2026-05-06. |
| 3 | Maintainers can verify tarball contents, HexDocs inputs, and sibling-package version pins before publish so release artifacts match the documented contract. | ✓ VERIFIED | [mix mailglass.publish.check --package mailglass] and [mix mailglass.publish.check --package mailglass_admin] both completed successfully on 2026-05-06; the machine-readable proofs exist in [.planning/publish/mailglass-publish-summary.json](/Users/jon/projects/mailglass/.planning/publish/mailglass-publish-summary.json:1) and [.planning/publish/mailglass_admin-publish-summary.json](/Users/jon/projects/mailglass/.planning/publish/mailglass_admin-publish-summary.json:1), and the human-readable bundle exists in [38-01-PREPUBLISH-PROOF.md](/Users/jon/projects/mailglass/.planning/phases/38-release-rehearsal-and-proof-artifacts/38-01-PREPUBLISH-PROOF.md:1). |
| 4 | Maintainers can execute a release checklist that includes required CI buckets and manual external checks for a trustworthy `v1.0` cut. | ✓ VERIFIED | [MAINTAINING.md](/Users/jon/projects/mailglass/MAINTAINING.md:112), [38-03-RELEASE-CHECKLIST.md](/Users/jon/projects/mailglass/.planning/phases/38-release-rehearsal-and-proof-artifacts/38-03-RELEASE-CHECKLIST.md:1), and [38-03-RELEASE-RECORD.md](/Users/jon/projects/mailglass/.planning/phases/38-release-rehearsal-and-proof-artifacts/38-03-RELEASE-RECORD.md:1) provide the coherent checklist/record pair, while [38-03-BRANCH-PROTECTION-NOTE.md](/Users/jon/projects/mailglass/.planning/phases/38-release-rehearsal-and-proof-artifacts/38-03-BRANCH-PROTECTION-NOTE.md:1) keeps the remaining external debt explicit. |

**Score:** 4/4 truths verified

### Deferred Items

Items not yet met but explicitly accepted as external/manual release-closeout proof.

| # | Item | Addressed In | Evidence |
| --- | --- | --- | --- |
| 1 | Live branch-protection confirmation is still external proof rather than repo-controlled truth. | Accepted release-closeout debt | [38-03-BRANCH-PROTECTION-NOTE.md](/Users/jon/projects/mailglass/.planning/phases/38-release-rehearsal-and-proof-artifacts/38-03-BRANCH-PROTECTION-NOTE.md:1) and [38-03-RELEASE-RECORD.md](/Users/jon/projects/mailglass/.planning/phases/38-release-rehearsal-and-proof-artifacts/38-03-RELEASE-RECORD.md:18) explicitly record the limitation. |

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `.planning/publish/mailglass-publish-summary.json` | Machine-readable core publish proof | ✓ VERIFIED | Refreshed by `mix mailglass.publish.check --package mailglass` on 2026-05-06. |
| `.planning/publish/mailglass_admin-publish-summary.json` | Machine-readable admin publish proof | ✓ VERIFIED | Refreshed by `mix mailglass.publish.check --package mailglass_admin` on 2026-05-06. |
| `38-01-PREPUBLISH-PROOF.md` | Canonical human-readable proof bundle | ✓ VERIFIED | Exists and remains the authoritative proof bundle. |
| `38-02-REHEARSAL-EVIDENCE.md` | Install/upgrade rehearsal evidence | ✓ VERIFIED | Exists and records both install and upgrade rehearsal facts. |
| `38-03-RELEASE-CHECKLIST.md` | Narrow manual/external release checklist | ✓ VERIFIED | Exists with repo-proved and manual/external sections. |
| `38-03-RELEASE-RECORD.md` | Populated release record | ✓ VERIFIED | Exists with rehearsal values and explicit `not run` markers for live-only fields. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `.github/workflows/post-publish-smoke.yml` | `test/mailglass/install/install_first_preview_smoke_test.exs` | workflow/test mirror | ✓ WIRED | The workflow and repo-local smoke test still mirror the same install -> compile -> boot -> `GET /dev/mail/` path. |
| `guides/getting-started.md` | `test/mailglass/install/install_first_send_smoke_test.exs` | first-send proof lane | ✓ WIRED | The guide-backed first-send path is executable and tested. |
| `guides/upgrading-to-v1_0.md` | `test/mailglass/docs_migration_smoke_test.exs` | strict upgrade proof | ✓ WIRED | The canonical guide names the strict verification commands and the smoke test enforces them. |
| `mix mailglass.publish.check` | `.planning/publish/*-publish-summary.json` | durable proof export | ✓ WIRED | Both package summaries were refreshed successfully on 2026-05-06. |
| `MAINTAINING.md` | `38-03-RELEASE-CHECKLIST.md` | release-day proof forms | ✓ WIRED | Maintainer docs now point at the explicit Phase 38 checklist and record. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Install + first-send + upgrade smoke bundle | `mix test test/mailglass/install/install_first_preview_smoke_test.exs test/mailglass/install/install_first_send_smoke_test.exs test/mailglass/docs_migration_smoke_test.exs --warnings-as-errors` | `29 tests, 0 failures` in the 2026-05-06 root milestone bundle | ✓ PASS |
| Strict upgrade proof | `mix verify.docs.migration` | `9 tests, 0 failures` | ✓ PASS |
| Release workflow lint | `actionlint .github/workflows/publish-hex.yml .github/workflows/post-publish-smoke.yml .github/workflows/release-please.yml .github/workflows/branch-protection-drift.yml` | Succeeded | ✓ PASS |
| Core publish proof | `mix mailglass.publish.check --package mailglass` | `Pre-publish check result for mailglass: create=2 update=5 unchanged=10 conflict=0` | ✓ PASS |
| Admin publish proof | `mix mailglass.publish.check --package mailglass_admin` | `Pre-publish check result for mailglass_admin: create=2 update=5 unchanged=9 conflict=0` | ✓ PASS |
| Core docs build | `mix docs --warnings-as-errors` | Succeeded | ✓ PASS |
| Admin docs build | `cd mailglass_admin && mix docs --warnings-as-errors` | Succeeded | ✓ PASS |
| Repo-root stability proof | `bash scripts/verify_support_contract.sh` | Root and admin lanes both passed on 2026-05-06 | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `RELS-01` | `38-02` | Maintainer can prove a clean app can install packages, mount admin, and complete the documented first-send workflow. | ✓ SATISFIED | Install smoke, first-send proof, and rehearsal evidence all align and pass. |
| `RELS-02` | `38-02` | Maintainer can prove the latest `0.x` upgrade path reaches `v1.0` using documented migration steps and smoke checks. | ✓ SATISFIED | Canonical upgrade guide, migration smoke test, and strict migration alias all passed. |
| `RELS-03` | `38-01` | Maintainer can verify tarball contents, HexDocs inputs, and sibling-package version pins before publish. | ✓ SATISFIED | Both publish-check runs completed successfully and refreshed the machine-readable summaries. |
| `RELS-04` | `38-03` | Maintainer can execute a rehearsed release checklist including required CI buckets and manual external checks. | ✓ SATISFIED | Checklist and record exist and explicitly capture the remaining external proof boundary honestly. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `38-03-BRANCH-PROTECTION-NOTE.md` | 1 | External branch-protection closeout remains manual | ⚠️ Warning | This is honest accepted debt, not a broken release-proof flow. |

### Gaps Summary

No Phase 38 goal-blocking gaps remain in repo-controlled proof.

One external/manual closeout item remains by design: branch-protection confirmation is recorded as accepted external debt rather than as repo-truth automation. That does not invalidate the rehearsed release-proof contract, but it remains milestone tech debt.

---

_Verified: 2026-05-06T08:48:00Z_
_Verifier: Codex_
