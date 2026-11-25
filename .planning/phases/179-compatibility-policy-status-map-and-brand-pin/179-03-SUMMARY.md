---
phase: 179-compatibility-policy-status-map-and-brand-pin
plan: 03
subsystem: brand-pin
tags: [brand-pin, sha256, tamper-test, offline-verify, advisory-check, mutation-proof, elixir-script]

requires: []
provides:
  - "brandbook/brand.pin.json: brand book v2.0 pinned by full commit and zip sha256, with a four-asset shipped manifest"
  - "Mailglass.BrandPin (scripts/brand_pin.exs): parse, verify, check_zip, init, update, fetch and CLI; offline verify is the merge-blocking check"
  - "brandbook/v2/: byte-for-byte copies of brand.json and the three OFL texts"
  - "Hermetic 53-test tamper suite that names each failure cause, plus a no-full-book tree guard"
affects: [180-reproducible-bundle, 181-tokens-fonts-logo, 183-announcement-gate]

actuals:
  tokens: 30979
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Pure verifier over injected read_file and list_dir closures, set-equality of each owned dir against shipped[].to"
    - "Test-owned expected hash constant checked through the same detector the tamper case calls"
    - "In-memory zip reads by pin-listed member names only, on the exact bytes that were hashed"
    - "Nested brandbook/.gitignore instead of editing an audited root ignore file"

key-files:
  created:
    - scripts/brand_pin.exs
    - brandbook/brand.pin.json
    - brandbook/v2/brand.json
    - brandbook/v2/OFL-FunnelDisplay.txt
    - brandbook/v2/OFL-AtkinsonHyperlegibleNext.txt
    - brandbook/v2/OFL-AtkinsonHyperlegibleMono.txt
    - brandbook/.gitignore
    - test/scripts/brand_pin_test.exs
  modified: []

key-decisions:
  - "The verifier is scripts/brand_pin.exs tested from core test/scripts/, so it never ships in a Hex tarball and runs in both core_deterministic_suite and mix_task_tests"
  - "The /brand/ and /mailglass-brand/ ignore rules live in a new brandbook/.gitignore; the root .gitignore stays untouched because phase 164 audits every line of six ignore files"
  - "Owned-directory listing walks with File.ls and File.lstat (hidden files and symlinks count as unlisted) instead of Path.wildcard, so glob metacharacters in a path cannot change what is seen"
  - "No .gitattributes is added: a root .gitattributes would become a core-claimed path, and the size and hash checks already catch any line-ending rewrite"

requirements-completed: [BRPOL-04]

coverage:
  - id: D1
    description: "brandbook/brand.pin.json pins szTheory/mailglass-brand at the full 240bdd21 commit with the commit-derived url, zip sha256 ed96bb25 and size 1943435, and the offline verify passes against the real tree"
    requirement: BRPOL-04
    verification:
      - kind: unit
        ref: "test/scripts/brand_pin_test.exs#the committed pin"
        status: pass
      - kind: other
        ref: "mix run --no-start scripts/brand_pin.exs verify printed brand pin ok, exit 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "Each planted failure names its cause: zip hash, shipped hash, altered and CRLF-rewritten copies, unlisted and hidden files, deleted and emptied directories, empty manifest, unsafe paths, malformed commit, non-derived url"
    requirement: BRPOL-04
    verification:
      - kind: unit
        ref: "test/scripts/brand_pin_test.exs#tamper cases name their cause"
        status: pass
      - kind: other
        ref: "Mutation run section below: P1-P5 each red with the named tag, restored, green"
        status: pass
    human_judgment: false
  - id: D3
    description: "The full book is not in the tree: no brand/ path, no .zip, no BRAND.md, mailglass-brand-book.html or mailglass-one-page.html; brandbook/.gitignore holds /brand/ and /mailglass-brand/; the root .gitignore is unchanged"
    requirement: BRPOL-04
    verification:
      - kind: unit
        ref: "test/scripts/brand_pin_test.exs#the full brand book stays out of the repository tree"
        status: pass
      - kind: other
        ref: "git diff --quiet 12acab86 -- .gitignore exits 0; test/scripts/phase_164_repository_truth_test.exs matches its recorded baseline"
        status: pass
    human_judgment: false
  - id: D4
    description: "The online check is advisory and never merge-blocking; init and update refuse a zip whose sha256 differs from --expect-sha256 and write nothing; members are read in memory by pin-listed names only"
    requirement: BRPOL-04
    verification:
      - kind: unit
        ref: "test/scripts/brand_pin_test.exs#advisory zip check, update and init procedure, command line"
        status: pass
      - kind: other
        ref: "Advisory online check section below: advisory check ok against the network, exit 0"
        status: pass
    human_judgment: false

duration: 24min
completed: 2026-11-13
status: complete
plan_head_before: 7462401a5627a8ab26a445dcedf1e201ae9b98ff
plan_head_after: b08d55698f3f94f7d2892ac974377829fec5f929
---

# Phase 179 Plan 03: Brand Pin Summary

**Brand book v2.0 pinned by full commit and zip sha256 with a four-asset manifest, proven by an offline hermetic tamper suite that names each failure cause, an advisory TLS-verified online check, and a reviewed expected-hash update procedure.**

## Performance

- **Duration:** 24 min wall clock (the `mix_task_tests` lane run took about 10 of those under a load average near 30)
- **Started:** 2026-11-14T04:22:00Z (approximate; the start time was not captured at the first command)
- **Completed:** 2026-11-14T04:46:02Z
- **Tasks:** 3
- **Files modified:** 8 created, 0 modified

## Accomplishments

- `brandbook/brand.pin.json` pins `szTheory/mailglass-brand` at `240bdd214746b956162b8d4f2f82d4b178106eff`, a `url` equal to the commit-derived raw.githubusercontent.com URL, zip sha256 `ed96bb25634ed158f4aeca40d97a892aef368fcc7528ba8cc5a55489b955f87b` and size 1,943,435. The book is v2.0, dated 2026-11-13 (read from the zip's own `brand.json` and converted from "November 13, 2026").
- Only four assets were copied in, byte for byte from the downloaded zip, under `brandbook/v2/`: `brand.json` (49,366 B) and the three `OFL-*.txt` texts. All four `shasum -a 256` values equal the verified inputs in the plan. No zip file was written to disk at any point. v1 `brandbook/tokens.json` and `tokens.css` are unchanged.
- `Mailglass.BrandPin.verify/3` is pure over injected closures: it parses the pin first (rejecting unsafe paths before any read), then checks size and sha256 per asset and set-equality of each owned directory against `shipped[].to`, with hidden files and symlinks counted.
- `test/scripts/brand_pin_test.exs` has 53 tests. A test-owned `@expected_zip_sha256` is checked through `check_expected_sha256/2`, the same detector tamper case (b) calls, so a pin-only edit of the zip hash fails.
- The advisory `check` command downloaded the pinned zip with TLS peer verification and confirmed it end to end (see "Advisory online check"). `init` and `update` refuse a zip whose sha256 differs from the required `--expect-sha256` and write nothing.

## Task Commits

1. **Task 1 (tracer): end-to-end pin, four assets, real-tree verify** - `fc0c2e0e` (chore(brand))
2. **Task 2: tamper suite with named causes and the no-full-book tree check** - `5424cf60` (chore(brand))
3. **Task 3: advisory online check and update procedure, mutation run** - `b08d5569` (chore(brand))

**Plan metadata:** recorded in the final docs commit that carries this file.

Commit count is measured from the ledger (`git rev-list --count 7462401a..HEAD` returned 3 at SUMMARY write), not narrated. Every commit is `chore(brand):` because every path is in core `exclude-paths`.

The tracer gate (`HUMAN_VERIFY_MODE` end-of-phase, automated-only verify) re-ran the real-tree verify and the test after the Task 1 commit; both passed, so expansion proceeded.

## Files Created/Modified

- `scripts/brand_pin.exs` - `Mailglass.BrandPin`: `parse/1`, `zip_url/2`, `sha256_hex/1`, `check_expected_sha256/2`, `tree_read_file/1`, `tree_list_dir/1`, `verify/3`, `check_zip/2`, `fetch/2`, `init/2`, `update/3`, `serialize/1`, `cli/2`; tail guard `Mix.env() != :test` runs the CLI otherwise
- `brandbook/brand.pin.json` - the pin, stable key order, trailing newline
- `brandbook/v2/brand.json`, `OFL-FunnelDisplay.txt`, `OFL-AtkinsonHyperlegibleNext.txt`, `OFL-AtkinsonHyperlegibleMono.txt` - vendored byte copies
- `brandbook/.gitignore` - one comment line plus `/brand/` and `/mailglass-brand/`
- `test/scripts/brand_pin_test.exs` - 53 tests, all under their own ExUnit `tmp_dir` for mutations

## Lane that proves BRPOL-04

The test lives in `test/scripts/`, which runs in two required lanes: `core_deterministic_suite` (root `mix test`) and `mix_task_tests` (`mix verify.ci_lane_contract`, directory-scoped `test test/scripts/`). Root `mix.exs`, its aliases and `ci.yml` were not edited. `grep -c "test test/scripts/" mix.exs` returns 6. No advisory lane is cited as proof.

## Verification

| Check | Result |
|---|---|
| `mix test test/scripts/brand_pin_test.exs --warnings-as-errors` | 53 tests, 0 failures |
| `mix run --no-start scripts/brand_pin.exs verify` | `brand pin ok`, exit 0 |
| `mix verify.ci_lane_contract` (the `mix_task_tests` lane) | 564 tests, 1 failure, 31 excluded, exit 2; the one failure is the recorded phase 164 baseline failure below, not this plan |
| `mix format --check-formatted` at the root | exit 0; `scripts/brand_pin.exs` formatted explicitly (it is outside the formatter inputs) |
| `cd mailglass_admin && mix test test/mailglass_admin/brand_test.exs test/mailglass_admin/token_parity_test.exs --warnings-as-errors` | 10 tests, 0 failures |
| `git diff --quiet 12acab86 -- mix.lock mailglass_admin/mix.lock` | exit 0 |
| `git diff --quiet 12acab86 -- .gitignore` and the five other audited ignore files | exit 0 |
| `git diff --quiet 12acab86 -- brandbook/tokens.json brandbook/tokens.css` | exit 0 |
| `git status --porcelain brandbook` after the suite and after the mutation run | empty |

Not run: the bare root `mix test --warnings-as-errors`. The orchestrator scoped this run to the plan's targeted commands because the machine was under a load average near 30 and the previous plan's full core run took 1400 to 1900 seconds. The new test file is covered by the directory-scoped run above and its own scoped run; the `core_deterministic_suite` run itself was left to the phase gate.

## Phase 164 baseline

Recorded before Task 2 edited anything, with `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/scripts/phase_164_repository_truth_test.exs`:

- **47 tests, 1 failure.** The failing test: `git runtime rules do not conceal the retired finalize-phase extension paths` (`test/scripts/phase_164_repository_truth_test.exs:261`, `Expected false or nil, got true` for `ignored?(".gsd/extensions/finalize-phase/index.ts")`).
- Cause, confirmed: an untracked local `.gsd/.gitignore` containing `*` (`cat .gsd/.gitignore` prints `*`). It is absent from a clean CI checkout, so it is not this plan's to fix. The same failure is recorded in `179-01-SUMMARY.md` at `53f6d872`, before any phase 179 change.
- After Task 2 (the nested `brandbook/.gitignore` added): the same run gave **47 tests, 1 failure, same test name**. No new failure and none naming an `ignore:` subject. The directory-scoped lane run (564 tests, 1 failure) shows the same single failure.

## Ignore rule

The D-18 `brand/` ignore rule lives in `brandbook/.gitignore` (lines `/brand/` and `/mailglass-brand/`), never in the root `.gitignore`. `scripts/validate_repository_truth.exs` audits every non-comment line of six ignore files (the root file included) as `ignore:.gitignore:<line>` subjects that need rows in the archived phase 164 ledger, which is never edited; a new root line would turn `phase_164_repository_truth_test.exs` red. A nested `brandbook/.gitignore` is not one of the six (the tracked `.planning/ui-reviews/.gitignore` is existing precedent), and `brandbook` is in core `exclude-paths`.

Checked on the real tree: `git check-ignore -v brandbook/brand/BRAND.md brandbook/mailglass-brand/BRAND.md` matches `brandbook/.gitignore:2` and `:3`; `git check-ignore -v brand/BRAND.md mailglass-brand/BRAND.md` (repo root) matches nothing and exits 1.

**Known limit (fail-closed, not a gap):** a book unzipped at the repo root (`brand/` or `mailglass-brand/` there) is not ignored, so it shows in `git ls-files -co --exclude-standard` and the tree check goes red locally and in CI. The zip's own root directory is `mailglass-brand/`, so both unzip names are covered only when the book is unpacked inside `brandbook/`. The tree check also rejects any path starting `mailglass-brand/` at the repo root (a small superset of the plan's `brand/` prefix).

## Advisory online check

Run once against the network on 2026-11-13 (about 23:37 local time), command and output verbatim:

```
$ ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix run --no-start scripts/brand_pin.exs check
advisory check ok
exit 0
```

`check` downloaded `https://raw.githubusercontent.com/szTheory/mailglass-brand/240bdd214746b956162b8d4f2f82d4b178106eff/mailglass-brand.zip` over TLS with `verify: :verify_peer`, the system CA store and HTTPS hostname matching, confirmed the zip sha256 and size against the pin, confirmed each of the four members inside the in-memory zip against `shipped[].sha256` and `bytes`, then ran the offline verify on the real tree. This check is advisory: it is not run by any test, `ci.yml` or lane, and never blocks a merge. The merge-blocking proof is the offline test.

## Mutation run

Each mutation was applied to the committed tree, `mix test test/scripts/brand_pin_test.exs --warnings-as-errors` was run (red), the mutation was restored, and the same command was re-run (green). Driven by one script, so every step is the same command. A `mix test` run with failures exits 2.

| # | Mutation | Red exit | Red excerpt (named cause) | Restore | Green |
|---|---|---|---|---|---|
| P1 | flip one hex char of `shipped[0].sha256` in `brandbook/brand.pin.json` (`c2f77d011e` to `d2f77d011e`) | 2, 5 failures | `{:error, [asset_hash_mismatch: "brandbook/v2/brand.json"]}` | `git checkout -- brandbook/brand.pin.json` | exit 0, 53 tests, 0 failures |
| P2 | flip one hex char of the top-level `sha256` (`ed96bb25` to `fd96bb25`) | 2, 1 failure (`the committed pin records the zip hash the test owns`) | `zip_hash_unexpected: "fd96bb25634ed158f4aeca40d97a892aef368fcc7528ba8cc5a55489b955f87b"` via `check_expected_sha256/2` | `git checkout -- brandbook/brand.pin.json` | exit 0, 53 tests, 0 failures |
| P3 | append one byte to `brandbook/v2/brand.json` | 2, 7 failures | `{:error, [asset_size_mismatch: "brandbook/v2/brand.json"]}` | `git checkout -- brandbook/v2/brand.json` | exit 0, 53 tests, 0 failures |
| P4 | create `brandbook/v2/extra.txt` | 2, 5 failures | `{:error, [asset_unlisted: "brandbook/v2/extra.txt"]}` | `rm brandbook/v2/extra.txt` | exit 0, 53 tests, 0 failures |
| P5 | delete `brandbook/v2/OFL-FunnelDisplay.txt` | 2, 6 failures | `{:error, [asset_missing: "brandbook/v2/OFL-FunnelDisplay.txt"]}` | `git checkout -- brandbook/v2/OFL-FunnelDisplay.txt` | exit 0, 53 tests, 0 failures |

`git status --porcelain brandbook` was empty after every restore and after the last step. The same CLI command (`mix run --no-start scripts/brand_pin.exs verify`) printed the same named issue lines under P1, P3, P4 and P5.

A red-before-green check also ran on Task 3's tests: against the Task 1 script (which lacked `check_zip/2`, `update/3` and the `check` and `help` commands) the 53-test file gave 53 tests, 19 failures (`UndefinedFunctionError` for `check_zip/2` and `update/3`, and the CLI cases); with the Task 3 script restored it gave 53 tests, 0 failures.

## Edge coverage

| Edge | Covering tests (all in `test/scripts/brand_pin_test.exs`) |
|---|---|
| empty | (f) `:manifest_empty` and `:required_asset_absent`; (c2) zero-byte copy gives `{:asset_size_mismatch, to}`; (e2) directory emptied gives `{:asset_missing, to}` for all four with no `:asset_unlisted` |
| encoding | (c2) LF to CRLF rewrite of `OFL-FunnelDisplay.txt` gives `{:asset_size_mismatch, to}` (the test also asserts the CRLF copy is larger, so the mutation is real); (c) equal-size one-byte change gives `{:asset_hash_mismatch, to}`; pin written with stable key order (asserted) and a trailing newline (asserted) |
| idempotency | (i) `verify/3` twice on a clean and a tampered copy returns identical results; `init` against an existing pin gives `{:error, :pin_exists}`, bytes unchanged, no download; `update/3` three times gives byte-identical pin and asset files |
| concurrency | `verify/3` and `check_zip/2` are pure; every mutating test writes under its own `tmp_dir` and the file runs `async: true`; `git status --porcelain brandbook` stayed empty after the suite and the mutation run |

## Decisions Made

- The pin verifier is a `scripts/` file tested from `test/scripts/`, never under `lib/mix/tasks`, so nothing ships in the Hex tarball.
- The `brand/` ignore rule is in `brandbook/.gitignore` to leave the six audited ignore files untouched.
- `.gitattributes` is not added (research A5): it would become a core-claimed path, and the size and hash checks already catch a line-ending rewrite.
- The note recorded in the pin is the one the plan specified: offline verification is merge-blocking, the online check is advisory, update with `--expect-sha256`, bump `@expected_zip_sha256` in the same `chore(brand)` commit, never hand-edit.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Hardening] Owned-directory listing walks the tree instead of `Path.wildcard`**
- **Found during:** Task 1 (writing `tree_list_dir/1`)
- **Issue:** The plan's `Path.wildcard(Path.join([root, dir, "**", "*"]), match_dot: true)` treats glob metacharacters in the root or directory path as patterns, which could silently change what is listed and let an unlisted file through. It also follows symlinks through `File.regular?`.
- **Fix:** A recursive `File.ls` plus `File.lstat` walk lists every non-directory entry, hidden files included, so a symlink or other non-regular entry in an owned dir is reported as `:asset_unlisted` instead of being followed. The plan's intent (a hidden smuggled file is still seen) is kept and tested by the `.extra` case in tamper case (d).
- **Files modified:** `scripts/brand_pin.exs`
- **Commit:** `fc0c2e0e`

**2. [Rule 2 - Hardening] `tree_read_file/1` refuses non-regular assets**
- **Found during:** Task 1
- **Issue:** `File.read` follows a symlink, so a listed asset replaced by a symlink to a file with the same bytes would verify.
- **Fix:** The read closure uses `File.lstat` and returns `{:error, :not_regular_file}` (reported as `:asset_missing`) for anything but a regular file.
- **Files modified:** `scripts/brand_pin.exs`
- **Commit:** `fc0c2e0e`

**3. [Rule 2 - Hardening] `fetch/2` refuses a non-https url; the tree check also forbids a root `mailglass-brand/` path**
- **Found during:** Tasks 2 and 3
- **Issue:** The plan required TLS peer verification but did not say what happens with an `http://` url; the tree check named only the `brand/` prefix although the zip's own root directory is `mailglass-brand/`.
- **Fix:** `fetch/2` returns `{:error, :url_not_https}` without calling the getter (tested); the tree guard rejects any path starting `mailglass-brand/` too (detector self-test covers it).
- **Files modified:** `scripts/brand_pin.exs`, `test/scripts/brand_pin_test.exs`
- **Commits:** `fc0c2e0e`, `5424cf60`

### Process note

The script was first written in full and then trimmed to the Task 1 scope (verify, init, fetch, CLI `verify` and `init`) before the Task 1 commit, so that Task 3's tests could be shown red against a script that lacked `check_zip/2` and `update/3` (19 failures) before the full script was restored for the single Task 3 commit. The plan's task and commit boundaries are unchanged.

**Total deviations:** 3 auto-fixed (all Rule 2 hardening), 0 architectural. **Impact:** none on scope; the hardening is covered by tests.

## Issues Encountered

- `mix verify.ci_lane_contract` reports 1 failure, the pre-existing `git runtime rules do not conceal the retired finalize-phase extension paths` test caused by the untracked local `.gsd/.gitignore` (see "Phase 164 baseline"). It is identical before and after this plan's changes and absent from a clean CI checkout.
- `mix test` output carries unrelated pre-existing warnings (`OTLP exporter module opentelemetry_exporter not found`; in the admin package, `MailglassDemo.QuickViewScenarios is not included in any boundary`). Neither comes from files in this plan.

## Authentication Gates

None. The brand repository is public; the download needs no credentials.

## Known Stubs

None. No hardcoded empty values, placeholder text or unwired data in the files this plan created.

## Next Phase Readiness

- Phases 180 and 181 extend `brandbook/brand.pin.json` `shipped[]` (woff2 files and logos) and add their `owned_dirs` entry through `scripts/brand_pin.exs update`, taking woff2 hashes from the zip, never from the book's `brand.json`. The expected zip hash literal in `test/scripts/brand_pin_test.exs` is bumped in the same `chore(brand):` commit.
- Remaining for plan 179-04 (trademark record) is unaffected by this plan; no file overlap.

## Self-Check: PASSED

- All eight created files exist (`scripts/brand_pin.exs`, `brandbook/brand.pin.json`, the four `brandbook/v2/` files, `brandbook/.gitignore`, `test/scripts/brand_pin_test.exs`).
- Commits `fc0c2e0e`, `5424cf60`, `b08d5569` are ancestors of HEAD; the measured ledger count is 3.
- Acceptance criteria re-run: the four asset hashes equal the verified inputs; exactly 4 paths under `brandbook/v2/`; the pin holds the expected sha256 once; v1 tokens unchanged; 0 `.zip` paths; `/brand/` and `/mailglass-brand/` each once in `brandbook/.gitignore`; the six audited ignore files unchanged; 37 named-tag references in the test (at least 10 required) and the literal `\r\n` present; `verify_peer` 1, `:memory` 1, `zip_list_dir` 0 in the script; `git status --porcelain brandbook` empty.
