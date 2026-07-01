---
phase: 129-cache-key-plt-correctness
plan: "01"
subsystem: ci
tags: [ci, cache, toolchain, setup-beam, github-actions]
dependency_graph:
  requires: []
  provides: [.tool-versions canonical toolchain source, toolchain-hashed cache keys, version-file setup-beam across all canonical lanes]
  affects: [.github/workflows/ci.yml, .github/workflows/publish-hex.yml, .github/workflows/post-publish-smoke.yml, .github/workflows/repo-hygiene.yml, .github/workflows/provider-live.yml]
tech_stack:
  added: [.tool-versions (asdf format, erlang 27.3.4.13 + elixir 1.18.4)]
  patterns: [setup-beam version-file + version-type:strict, toolchain-hashed per-env cache key]
key_files:
  created: [.tool-versions]
  modified:
    - .github/workflows/ci.yml
    - .github/workflows/publish-hex.yml
    - .github/workflows/post-publish-smoke.yml
    - .github/workflows/repo-hygiene.yml
    - .github/workflows/provider-live.yml
decisions:
  - "Pinned erlang 27.3.4.13 + elixir 1.18.4 (exact patches from green ci.yml run 28420773972 on 2026-06-30; OTP-27.3.4.13 is the latest OTP 27 build on ubuntu-24.04 builds.hex.pm)"
  - "Kept dialyzer job matrix (elixir/otp dims) intact — PLT cache key uses ${{ matrix.otp }}/${{ matrix.elixir }}; Plan 02 owns PLT block rewrite; stripping matrix now would leave PLT cache key with empty dims"
  - "Stripped toolchain-only 1-row matrices from: format_check, compile_warnings, mix_task_tests, inbound_test, inbound_compile_no_optional_deps, credo_strict, docs_warnings_as_errors, hex_audit, installer_golden_gate"
  - "Kept matrix (node dim only) for operator_browser_gate and preview_capture_advisory; stripped elixir/otp dims"
  - "repo-hygiene.yml and publish-hex.yml: key updated, no restore-keys added (both already had no restore-keys)"
metrics:
  duration: "6m 57s"
  completed: "2026-07-01"
  tasks_completed: 3
  tasks_total: 3
  files_created: 1
  files_modified: 5
  setup_beam_blocks_updated: 28
  deps_cache_blocks_updated: 17
  matrices_stripped: 9
status: complete
---

# Phase 129 Plan 01: Canonical Toolchain Single Source + Cache-Key Rewrite Summary

Single-line summary: `.tool-versions` pins OTP 27.3.4.13 / Elixir 1.18.4 as the sole toolchain source; all 28 canonical-lane setup-beam blocks read it via version-file; all 17 canonical deps/_build cache blocks gain a toolchain-hash dim, eliminating cross-toolchain stale-cache cross-contamination.

## Tasks Completed

| Task | Description | Commit | Files |
|------|-------------|--------|-------|
| 1 | Create `.tool-versions` canonical OTP/Elixir source | c6d019a8 | `.tool-versions` (new) |
| 2 | Point all canonical-lane setup-beam blocks at `.tool-versions` | 6c7f359d | 5 workflow files |
| 3 | Rewrite canonical deps/_build cache keys to toolchain-hashed shape | 35bef2a0 | 4 workflow files (provider-live had no cache blocks) |

## Exact Pinned Versions

| Tool | Version | Resolution Source |
|------|---------|-------------------|
| erlang | `27.3.4.13` | `OTP-27.3.4.13` from `builds.hex.pm/builds/otp/amd64/ubuntu-24.04/builds.txt`; confirmed from "Installing Erlang/OTP OTP-27.3.4.13" log line in ci.yml run 28420773972 (2026-06-30, main branch, green) |
| elixir | `1.18.4` | `v1.18.4-otp-27` from `builds.hex.pm/builds/elixir/builds.txt`; confirmed from "Installing Elixir v1.18.4-otp-27" log in same run; setup-beam auto-appends `-otp-27` suffix, so `.tool-versions` declares bare `1.18.4` |

## What Changed

### Task 1: `.tool-versions`
New file at repo root:
```
erlang 27.3.4.13
elixir 1.18.4
```
`setup-beam`'s `parseToolVersionsFile` reads `erlang` → otp-version, `elixir` → elixir-version. Under `version-type: strict`, the action does an exact manifest lookup (no range expansion). The elixir spec `1.18.4` is auto-qualified to `v1.18.4-otp-27` by setup-beam using the resolved OTP major.

### Task 2: Setup-beam version-file sweep (28 blocks across 5 files)
All `elixir-version`/`otp-version` inputs replaced with:
```yaml
version-file: .tool-versions
version-type: strict
```
Toolchain-only single-row matrices stripped from 9 jobs. Two jobs (operator_browser_gate, preview_capture_advisory) retained their matrices with only the `node: "22"` dim. Dialyzer matrix retained (PLT cache key uses `${{ matrix.otp }}`/`${{ matrix.elixir }}`; Plan 02 cleans it up).

### Task 3: Cache key rewrite (17 deps blocks + 1 key-only block)
Old shape:
```yaml
key: ${{ runner.os }}-mix-${{ hashFiles('**/mix.lock') }}
restore-keys: |
  ${{ runner.os }}-mix-
```
New shape (canonical lanes with restore-keys):
```yaml
key: mix-${{ runner.os }}-${{ hashFiles('.tool-versions') }}-${{ env.MIX_ENV || 'dev' }}-${{ hashFiles('**/mix.lock') }}
restore-keys: |
  mix-${{ runner.os }}-${{ hashFiles('.tool-versions') }}-${{ env.MIX_ENV || 'dev' }}-
```
publish-hex.yml and repo-hygiene.yml: same key shape, no restore-keys (exact-or-cold).

PLT cache block in dialyzer (`${{ runner.os }}-dialyzer-plt-...`) is unchanged — Plan 02 owns it.

## Scope Fences Respected

- `advisory-matrix.yml`: not opened, not modified
- `publish-hex.yml` REQUIRED_LANES literals (~205-208): untouched (`Support Contract Core (Elixir 1.18 / OTP 27)` etc.)
- All job `name:` display strings: unchanged
- All third-party Action SHA pins: unchanged
- Dialyzer PLT cache block: unchanged

## Deviations from Plan

### Auto-handled: Dialyzer matrix retention

The plan says to strip toolchain-only single-row matrices. The dialyzer job had such a matrix (`elixir: "1.18", otp: "27"`), but its PLT cache block (which Plan 02 owns) uses `${{ matrix.otp }}` and `${{ matrix.elixir }}` in the cache key. Stripping the matrix would make those expand to empty strings, producing a broken PLT cache key. Decision: keep the dialyzer matrix until Plan 02 rewrites the PLT block with the `hashFiles('.tool-versions')`-based key. This is consistent with the plan's guidance: "if collapsing the toolchain matrix would change any job name: that interpolates matrix values, KEEP the matrix" — extended here to: if collapsing would break an out-of-scope cache key, KEEP the matrix.

This is a conservative deviation, not a functionality gap. Plan 02 will resolve it.

## Verification Gates

| Gate | Result |
|------|--------|
| Task 1: `.tool-versions` exists with `erlang 27.*` + `elixir 1.18*` | OK |
| Task 2: 28 setup-beam blocks, 28 have version-file, 0 leftover elixir-version/otp-version | OK (sb=28, vf=28, leftover=0) |
| Task 3: 0 old `${{ runner.os }}-mix-` keys; 42 toolchain hash occurrences >= floor=24 | OK (old=0, toolchain=42, floor=24) |

## Known Stubs

None. This is a pure CI/infra change with no UI, data, or product stubs.

## Threat Flags

None. Changes are scoped to GitHub Actions YAML and `.tool-versions`. No new network endpoints, auth paths, or schema changes introduced.

## Self-Check

### Created files exist:
- `.tool-versions`: FOUND
- `.github/workflows/ci.yml`: FOUND (modified)
- `.github/workflows/publish-hex.yml`: FOUND (modified)
- `.github/workflows/post-publish-smoke.yml`: FOUND (modified)
- `.github/workflows/repo-hygiene.yml`: FOUND (modified)
- `.github/workflows/provider-live.yml`: FOUND (modified)

### Commits exist:
- `c6d019a8`: FOUND (Task 1 - .tool-versions)
- `6c7f359d`: FOUND (Task 2 - setup-beam version-file)
- `35bef2a0`: FOUND (Task 3 - cache key rewrite)

## Self-Check: PASSED
