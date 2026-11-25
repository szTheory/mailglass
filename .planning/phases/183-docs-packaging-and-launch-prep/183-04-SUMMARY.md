---
phase: 183-docs-packaging-and-launch-prep
plan: "04"
subsystem: testing
tags:
  - favicon
  - provenance
  - Elixir
  - OTP crypto
  - ExUnit
requires:
  - phase: 183-02
    provides: Accepted favicon catalog and independent manifest/raster validator
provides:
  - Exact-manifest authentication for the accepted historical favicon producer bytes
  - Git-free positive and adversarial provenance contracts
  - Current-producer validation for all other catalog identities
affects:
  - BRDOC-05
  - Phase 183 verification
  - Phase 182 plan 07
actuals:
  tokens: 10471
  tasks: 2
  commits: 4
  plan_head_before: 48c3b310830d44a80f5ef5beb4895f23d37f42bc
  plan_head_after: 3639ceb5429d7f46a36c52d3617d3c89bd2e6329
tech-stack:
  added: []
  patterns:
    - OTP SHA-256 and Git-blob SHA-1 over bounded fixture bytes
    - Fixed-path provenance reads with lstat checks and pre-read byte caps
    - Atomic temporary-directory creation with collision retry and owned cleanup
key-files:
  created:
    - mailglass_admin/test/fixtures/favicon_provenance/accepted-producer.cjs
    - mailglass_admin/test/fixtures/favicon_provenance/accepted-producer.json
  modified:
    - mailglass_admin/test/support/favicon_catalog.ex
    - mailglass_admin/test/mailglass_admin/favicon_catalog_test.exs
key-decisions:
  - Historical acceptance requires the exact original manifest byte digest and catalog ID, then verifies the expected producer binding and independent fixture constants.
  - Historical JavaScript remains inert fixture data; runtime validation uses OTP crypto only and performs no Git or network operations.
  - All other catalog identities keep the current producer file digest comparison.
patterns-established:
  - Pin machine-readable provenance records to independent validator constants and reject any extra, missing, changed, or mistyped field.
  - Bound and lstat-check fixed evidence paths before reading archive-portable fixture data.
  - Create every top-level test temp directory with exclusive mkdir and register cleanup only after creation succeeds.
requirements-completed:
  - BRDOC-05
coverage:
  - id: D1
    description: The accepted catalog validates from a Git-free root with the exact historical producer bytes while future catalogs remain current-producer-bound.
    requirement: BRDOC-05
    verification:
      - kind: unit
        ref: test/mailglass_admin/favicon_catalog_test.exs#accepted historical producer validates from a Git-free source archive
        status: pass
      - kind: other
        ref: node --test mailglass_admin/e2e/favicon-capture-order.test.cjs
        status: pass
    human_judgment: false
duration: 38m
completed: 2026-11-18
status: complete
---

# Phase 183 Plan 04: Favicon Producer Provenance Summary

**The accepted favicon catalog now validates against its authenticated historical producer snapshot, while every other catalog remains bound to the current producer.**

## Performance

- **Duration:** Approximately 38 minutes total: roughly 21 minutes for the original execution, plus the follow-up temporary-directory hardening and report refresh.
- **Started:** Approximately 2026-11-17T23:45:00Z.
- **Completed:** 2026-11-18T00:22:36Z.
- **Tasks:** 2.
- **Files modified:** 4 plan artifacts, plus this summary.

## Accomplishments

- Added an exact, non-executable 16,209-byte copy of the historical producer and an offline record binding its source commit, blob, tree, hashes, accepted manifest, brand pin and favicon identity.
- The validator chooses historical evidence only for manifest SHA-256 `ef614ecee58a440887d1bfbede7f777d31f97ab37b61acf82c4e7d0d6c204e11` and catalog ID `favicon-299c1aa-20261116T231912Z`. It independently compares every provenance-record field with compiled constants, then validates snapshot length, SHA-256 and Git-blob identity.
- Added Git-free tests for the accepted catalog, all provenance identity fields, missing/malformed/oversized/corrupted/symlinked evidence, symlinked parent directories, raw-manifest whitespace changes, and synthetic future catalogs using the current producer digest.
- Hardened every test-owned top-level temporary directory: atomic `File.mkdir` retries collisions across VMs, and cleanup is registered only after exclusive creation succeeds.
- Kept source, served favicon, pin, manifest, PNG, pixel, threshold and Safari-disclosure checks active. No dependency was added.

## Historical Source Authentication

The exact source object was read from local Git objects; no fetch or network access was used.

| Check | Result |
| --- | --- |
| Commit exists | `ad4af34352e1d64af6fc7415306151adcb61b9e7` |
| Producer path blob | `63176497feeb85722af6a78bfb9b90c77739f376` |
| Commit root tree | `5658acb44e0907ec302a3a889ea39c349fe21552` |
| Commit ancestor of checked revision | Yes; checked against `48c3b310830d44a80f5ef5beb4895f23d37f42bc` |
| Commit time | `2026-11-16T14:56:55-05:00`, before manifest `startedAt` `2026-11-16T23:19:12.756Z` |
| Snapshot size and SHA-256 | 16,209 bytes; `bff05d778648d4d900c9e977e89227ea3290ede9490e1e7fd5de28bdda7f6ee3` |
| Recomputed Git-blob ID | `63176497feeb85722af6a78bfb9b90c77739f376` |

Read-only authentication commands included:

```text
git cat-file -e 'ad4af34352e1d64af6fc7415306151adcb61b9e7^{commit}'
git rev-parse 'ad4af34352e1d64af6fc7415306151adcb61b9e7:mailglass_admin/e2e/favicon-capture.cjs'
git rev-parse 'ad4af34352e1d64af6fc7415306151adcb61b9e7^{tree}'
git merge-base --is-ancestor ad4af34352e1d64af6fc7415306151adcb61b9e7 48c3b310830d44a80f5ef5beb4895f23d37f42bc
git show -s --format='%cI' ad4af34352e1d64af6fc7415306151adcb61b9e7
git show 'ad4af34352e1d64af6fc7415306151adcb61b9e7:mailglass_admin/e2e/favicon-capture.cjs' | shasum -a 256
git show 'ad4af34352e1d64af6fc7415306151adcb61b9e7:mailglass_admin/e2e/favicon-capture.cjs' | wc -c
```

The snapshot was written byte-for-byte from the verified blob with a shell redirect (git cat-file blob 63176497feeb85722af6a78bfb9b90c77739f376 > mailglass_admin/test/fixtures/favicon_provenance/accepted-producer.cjs) and kept mode 0644. Comparing the historical and current producer shows the capture helper was extracted/exported and the Playwright import made lazy; the current producer digest `55208b4010bd21fbb03f48754a320b1672e5d2846d919ac915d1fd9a1fc235a9` is recorded for diagnosis only, not as an allowlist.

This authenticates recorded source-byte provenance. It does not independently attest to the historical browser process and establishes no new browser or Safari observation.

## Checks

The baseline regression was run before implementation with the existing full validator:

| Command | Result |
| --- | --- |
| `mix test test/mailglass_admin/favicon_catalog_test.exs:100 --warnings-as-errors --seed 0` with the pinned ASDF environment and a 60-second cap | Expected red: one accepted-catalog assertion reported only `producer: SHA-256 differs from current file`; 13 tests, 1 failing assertion, 12 excluded; 0.4s. Log SHA-256 `8322682cdeed41d9838192d0d008761be7df85dc599d22695bd848f9c638bf4d`. |
| `mix test test/mailglass_admin/favicon_catalog_test.exs --warnings-as-errors --seed 0` with the pinned ASDF environment and a 60-second cap | Pass: 18 tests, no test errors, 10.8s. Log SHA-256 `74c4f72953c81c28183ffb2bce51cd464a95c1d770d2ee07f0b75dd1e756f5d7`. |
| Same focused ExUnit command, final Task 2 run, 60-second cap | Pass: 18 tests, no test errors, 11.0s. Log SHA-256 `e48b08905203facd33911da611f05feddb7b003e79377a416bbe519e2a25091d`. |
| Same focused ExUnit command after exclusive temporary-directory hardening, 60-second cap | Pass: 18 tests, no test errors, 10.9s. Log SHA-256 `f85cf2bc797a241d9bd44069bf1c35940fce18a83fbc83656b7f649f0c6872d1`. |
| node --test mailglass_admin/e2e/favicon-capture-order.test.cjs, 60-second cap | Pass: 1 test, 38.6ms. Log SHA-256 `8dd35fa0ec60f4ac0f2d325db911c74b1e9bcf936fcaba1b16cd0f48f3f51d4e`. |
| Targeted `mix format --check-formatted` and `git diff --check` | Pass. |

An initial ExUnit invocation caught invalid bracket-access assignment in the newly added synthetic-catalog test at compile time. It was corrected to `Map.put`/`put_in`; the bounded rerun above passed. The first formatter call omitted the repository-pinned ASDF versions and stopped before formatting; rerunning with the plan's pinned versions passed.

## Protected Bytes and Cleanup

The before/after SHA-256 inventory is byte-identical. It covers all 108 accepted PNGs plus the manifest, pin, source favicon, served favicon and current producer: 113 files total. Inventory-list SHA-256 before and after: `eed701b815a68dcff6ef082c69c1817bcc1bfb6ab05bd73ec5763d76ddd461a6`.

| Protected item | SHA-256 |
| --- | --- |
| Accepted manifest | `ef614ecee58a440887d1bfbede7f777d31f97ab37b61acf82c4e7d0d6c204e11` |
| `brandbook/brand.pin.json` | `5d853e8ba0788528879241fe4f27e6df0e5f4f181270d2f8fcf480aeab088950` |
| `brandbook/v2/favicon.svg` | `299c1aaa2dfc772bf375de0d51ef4dae0b442969684cc4d393887b87f3f037a5` |
| `mailglass_admin/priv/static/favicon.svg` | `299c1aaa2dfc772bf375de0d51ef4dae0b442969684cc4d393887b87f3f037a5` |
| Current `favicon-capture.cjs` | `55208b4010bd21fbb03f48754a320b1672e5d2846d919ac915d1fd9a1fc235a9` |

The per-file inventory is `/private/tmp/phase183-04-protected-before.sha256` and `/private/tmp/phase183-04-protected-after.sha256`; both have the same aggregate hash above. ExUnit temporary roots and external symlink targets were removed by test cleanup; a post-run scan found no owned temporary paths. No browser, capture alias, network, package installation, broad suite, build, hosted CI or release action ran.

## Task Commits

1. **Task 1: Authenticate the accepted historical producer through the full catalog validator** — `2d443e1f` (`fix(183-04): authenticate accepted favicon producer bytes`).
2. **Task 2: Prove archive portability and reject provenance substitutions** — `314890d7` (`test(183-04): cover offline provenance and producer fallback`).
3. **Task 2 follow-up: Give each test VM exclusive temporary roots** — `3639ceb5` (`test(183-04): create temporary test roots exclusively`).

## Decisions Made

- The exact original manifest bytes, catalog identity and producer path/digest are jointly required before considering historical provenance.
- The JSON record is evidence to compare against independent code constants, never authority for its own values. Both evidence files use fixed repository-relative paths, real-directory/regular-file checks and pre-read byte limits.
- OTP crypto computes SHA-256 and the standard Git-blob SHA-1 at runtime; no dependency or runtime Git operation was introduced.
- `sourceRevision` remains the approved brand source commit, not the application producer commit.
- Temporary test roots use atomic `File.mkdir` with collision retry; only successfully created roots register cleanup.

## Deviations from Plan

None. The two implementation tasks and focused verification stayed within the approved scope.

## Issues Encountered

- The first post-edit ExUnit run caught a compile error in the new test's map assignment. It was fixed before the successful bounded reruns.
- The formatter initially had no selected ASDF version; the plan-pinned environment was applied and the targeted formatting check passed.
- The phase verifier identified that per-VM unique integers alone could collide across concurrent test VMs. The temp helper now retries atomic mkdir collisions and owns cleanup only after successful creation.

## Preserved Stops and Next Gate

The consumed capture authorization and blocked alias remain stopped. No accepted manifest, PNG, pin or favicon source was changed. The owner drafts and platform/legal/publication stops remain as recorded; no public claim, social upload, archive, tag, release or publish occurred. Phase 182 plan 07 remains gated on a fresh Phase 183 verification and must not invoke the catalog capture alias.

## Self-Check: PASSED

- Both fixture files, the validator and the focused contract test exist.
- Task commits `2d443e1f`, `314890d7` and `3639ceb5` are in the checked plan history.
- The before/after protected inventory hashes match and temporary test roots are absent.

---
*Phase: 183-docs-packaging-and-launch-prep*
*Completed: 2026-11-18*
