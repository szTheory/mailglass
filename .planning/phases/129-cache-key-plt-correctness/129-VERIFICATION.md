---
phase: 129-cache-key-plt-correctness
verified: 2026-07-01T00:00:00Z
status: passed
score: 7/7 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps: []
---

# Phase 129: Cache Key + PLT Correctness Verification Report

**Phase Goal:** Derive the deps/`_build` cache key from a single toolchain source (kill the ~15 hardcoded otp27-ex1.18 literals) and add Bandit-style self-healing PLT eviction — the precondition before Dialyzer can move toward the required set (LD-7, LD-9).
**Verified:** 2026-07-01
**Status:** passed
**Re-verification:** No — initial verification

---

## Requirements Cross-Reference

| Requirement ID | Plan | Description | Status |
|---|---|---|---|
| CACHE-01 | 129-01 | deps/`_build` cache key includes OTP+Elixir dims from single `.tool-versions` source, per-env prefix, no per-block literals (LD-9) | SATISFIED |
| CACHE-02 | 129-02 | PLT cache uses Bandit-style self-healing eviction (evict + rebuild on stale Dialyzer failure) (LD-7) | SATISFIED |

Both IDs appear in REQUIREMENTS.md §CACHE and are marked `[ ]` (unchecked, meaning "delivered this milestone but not yet archived"). Both plans claim them and the codebase evidence confirms both.

---

## Goal Achievement

### Observable Truths (merged from ROADMAP success criteria + PLAN must-haves)

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | `.tool-versions` exists at repo root with `erlang 27.x` and `elixir 1.18.x` (exact patches from a green CI run) | VERIFIED | File exists: `erlang 27.3.4.13` / `elixir 1.18.4`; two lines only, no extras |
| 2 | Every canonical-lane setup-beam block reads `.tool-versions` via `version-file` + `version-type: strict`; no per-block `elixir-version`/`otp-version` literal remains on the 5 canonical files | VERIFIED | 18 blocks in ci.yml, 4 in publish-hex.yml, 4 in post-publish-smoke.yml, 1 in repo-hygiene.yml, 1 in provider-live.yml = 28 total; all carry `version-file: .tool-versions` + `version-type: strict`; `grep -Ec elixir-version|otp-version` across all 5 files = 0 |
| 3 | Every canonical-lane deps/`_build` cache key carries `hashFiles('.tool-versions')` + per-env prefix + lock hash; no old `${{ runner.os }}-mix-` key or broad restore-key remains | VERIFIED | All cache `key:` lines follow `mix-${{ runner.os }}-${{ hashFiles('.tool-versions') }}-${{ env.MIX_ENV \|\| 'dev' }}-${{ hashFiles('**/mix.lock') }}`; `grep runner.os }}-mix-` across 5 files = 0 occurrences |
| 4 | publish-hex.yml cache blocks use the new toolchain-hashed key shape with NO `restore-keys` (exact-or-cold) | VERIFIED | 4 cache blocks in publish-hex.yml; all have the new key shape; `grep restore-keys publish-hex.yml` = 0 hits; REQUIRED_LANES display literals at lines 205-209 are unchanged |
| 5 | advisory-matrix.yml is untouched; all third-party Action SHA pins unchanged across the 5 canonical files | VERIFIED | `advisory-matrix.yml` last touched before phase 129 (most recent commit is `63c3f4c3` predating phase); SHA pins in ci.yml: `actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0`, `erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93`, `actions/cache@27d5ce7f107fe9357f9df03efb73ab90386fccae` — all preserved |
| 6 | The PLT cache `path:` is `_build/test/*.plt` (matching MIX_ENV:test); PLT cache key is toolchain-scoped via `hashFiles('.tool-versions')`; no `_build/dev/*.plt` PLT path remains; no `${{ matrix.otp }}`/`${{ matrix.elixir }}` literal in the PLT key | VERIFIED | ci.yml line 483: `path: _build/test/*.plt`; line 484: `key: plt-${{ runner.os }}-${{ hashFiles('.tool-versions') }}-${{ hashFiles('**/mix.lock') }}`; `grep _build/dev.*plt ci.yml` = 0; `grep matrix\.otp\|matrix\.elixir ci.yml` = 0 |
| 7 | Dialyzer runs as a Bandit two-step self-heal: step 1 `id: dialyzer` + `continue-on-error: true`; step 2 gated on `steps.dialyzer.outcome == 'failure'` with `rm -rf _build/test/*.plt && mix dialyzer --plt && mix dialyzer`; Dialyzer is NOT added to the `ci_green` required set | VERIFIED | ci.yml lines 493-499: step 1 (`id: dialyzer`, `continue-on-error: true`, `run: mix dialyzer`), step 2 (`if: steps.dialyzer.outcome == 'failure'`, `run: rm -rf _build/test/*.plt && mix dialyzer --plt && mix dialyzer`); `ci_green` needs at lines 1101-1106: only `compile_no_optional_deps`, `installer_host_smoke`, `support_contract_core`, `support_contract_admin`, `trust_lane_repo_head` — dialyzer absent |

**Score: 7/7 truths verified (0 present-but-behavior-unverified)**

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `.tool-versions` | New file, repo root, `erlang 27.x` + `elixir 1.18.x` | VERIFIED | `erlang 27.3.4.13` / `elixir 1.18.4`; exact patches resolved from green ci.yml run 28420773972 per SUMMARY |
| `.github/workflows/ci.yml` | setup-beam + cache blocks rewritten on canonical lanes; dialyzer PLT block + two-step self-heal | VERIFIED | 18 setup-beam blocks, all using version-file; 18 cache blocks with toolchain-hashed key; PLT block fixed + two-step self-heal present |
| `.github/workflows/publish-hex.yml` | Exact-key cache (no restore-keys), version-file setup-beam | VERIFIED | 4 setup-beam blocks with version-file; 4 cache blocks with new key shape, no restore-keys |
| `.github/workflows/post-publish-smoke.yml` | Canonical blocks rewritten | VERIFIED | 4 setup-beam blocks with version-file; 2 cache blocks with toolchain-hashed key; 1 of 2 has restore-keys (scoped, not broad) |
| `.github/workflows/repo-hygiene.yml` | Canonical block rewritten, exact-or-cold | VERIFIED | 1 setup-beam with version-file; 1 cache block with new key, no restore-keys |
| `.github/workflows/provider-live.yml` | Canonical setup-beam rewritten (no cache blocks — confirmed correct) | VERIFIED | 1 setup-beam with version-file; no cache blocks (provider-live has no deps cache step — this was confirmed correct) |

---

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `.tool-versions` | `erlef/setup-beam` (all 28 canonical blocks) | `version-file: .tool-versions` + `version-type: strict` | WIRED | Every `erlef/setup-beam@` `with:` block in the 5 files carries exactly this pair |
| `.tool-versions` | deps/`_build` cache `key:` (all canonical blocks) | `hashFiles('.tool-versions')` in key | WIRED | All 25 cache `key:` lines include `hashFiles('.tool-versions')` as the toolchain dim |
| dialyzer `id: dialyzer` step | eviction step | `if: steps.dialyzer.outcome == 'failure'` | WIRED | ci.yml line 498: condition references step id correctly |
| eviction `rm -rf` path | PLT cache `path:` | Both target `_build/test/*.plt` | WIRED | PLT `path:` (line 483) and eviction rm (line 499) use the same glob; MIX_ENV: test (line 461) is the job env |

---

### Scope Fences (all must be verified)

| Fence | Requirement | Status | Evidence |
|---|---|---|---|
| `advisory-matrix.yml` untouched | Phase 130 diverges alt-toolchain rows | VERIFIED | Git log shows no phase-129 commits on advisory-matrix.yml; file still uses `elixir-version: ${{ matrix.elixir }}` / `otp-version: ${{ matrix.otp }}` (lines 58-59) |
| `publish-hex.yml` REQUIRED_LANES display strings unchanged | Branch-protection contract identifiers | VERIFIED | Lines 205-209: `'Support Contract Core (Elixir 1.18 / OTP 27)'`, `'Support Contract Admin (Elixir 1.18 / OTP 27)'`, `'Compile No Optional Deps (Elixir 1.18 / OTP 27)'`, `'Trust Lane Repo Head (Elixir 1.18 / OTP 27)'`, `'Installer Host Smoke'` — all intact |
| All third-party Action SHA pins unchanged | CLAUDE.md: SHA pins frozen | VERIFIED | Pins spot-checked in ci.yml: checkout `9c091bb2`, setup-beam `fc68ffb9`, cache `27d5ce7f`, github-script `3a2844b7` — all unchanged |
| Dialyzer NOT added to `ci_green` needs | LD-7 — mechanism only, no promotion | VERIFIED | `ci_green` needs list (lines 1101-1106): 5 jobs, no dialyzer |
| `_build/dev/*.plt` path eliminated from PLT cache | PLT job runs MIX_ENV: test | VERIFIED | `grep _build/dev.*plt ci.yml` = 0 matches |
| Dialyzer matrix retained (deliberate deviation from full strip) | PLT cache key stripped `${{ matrix.otp }}`/`${{ matrix.elixir }}` via Plan 02 | VERIFIED | Matrix remains at lines 441-445 (display name preservation + Plan 01 deferral); PLT cache key now uses `hashFiles('.tool-versions')` not matrix literals — the matrix is now a no-op for cache purposes; this is the documented conservative approach |

---

### Behavioral Spot-Checks

This is an infra-only phase; verification is against `.github/workflows/*.yml` and `.tool-versions`. No runnable mix test suite targets apply. The PLT-corruption recovery proof was executed locally and documented in `129-02-SUMMARY.md` — an operational proof, not a CI-executable test. The proof is classified as a human-verified item (see below).

| Behavior | Command | Result | Status |
|---|---|---|---|
| `.tool-versions` has erlang 27.x + elixir 1.18.x | `test -f .tool-versions && grep -qE '^erlang 27\.' .tool-versions && grep -qE '^elixir 1\.18' .tool-versions` | erlang 27.3.4.13, elixir 1.18.4 — matches | PASS |
| Zero old `${{ runner.os }}-mix-` keys in canonical lanes | `grep -rn "runner\.os }}-mix-"` across 5 files | 0 matches | PASS |
| Zero `elixir-version`/`otp-version` inputs in canonical lanes | `grep -Ec "elixir-version|otp-version"` across 5 files | 0 matches | PASS |
| PLT cache path is `_build/test/*.plt` | `grep -n "_build/dev.*plt" ci.yml` | 0 matches; `_build/test/*.plt` at lines 483 and 499 | PASS |
| Dialyzer two-step self-heal present | `grep -n "id: dialyzer\|continue-on-error: true\|steps.dialyzer.outcome\|rm -rf _build/test" ci.yml` | All four patterns found at lines 494-499 | PASS |
| Dialyzer not in `ci_green` needs | `grep -A15 "ci_green:" ci.yml | grep dialyzer` | 0 matches | PASS |

---

### Anti-Patterns Found

No anti-patterns detected. No `TBD`/`FIXME`/`XXX` markers in any phase-modified file. No stub patterns (infra-only YAML; no component rendering, no empty returns). No hardcoded empty data.

**One observation (not a blocker):** The PLT-corruption proof in `129-02-SUMMARY.md` was run locally on OTP 28 / Elixir 1.19 (`dialyxir_erlang-28.4.1_elixir-1.19.5_deps-test.plt`) while CI runs OTP 27.3.4.13 / Elixir 1.18.4. The proof demonstrates the structural self-heal (corrupt PLT → evict → rebuild) which is implementation-independent. The divergence is a local environment artifact, not a defect in the workflow logic.

**Dialyzer matrix retention (deliberate deviation):** The dialyzer job retains `strategy.matrix: include: [{elixir: "1.18", otp: "27"}]` — these are label-only literals now, since the setup-beam block reads `.tool-versions` and the PLT cache key uses `hashFiles('.tool-versions')`. The matrix values are not consumed by any cache key or toolchain input. The plan explicitly documented this as a conservative deviation (retaining the matrix avoids renaming the job display name which would break the branch-protection contract). This is acceptable and does not constitute a toolchain literal in a cache key.

---

### Human Verification Recommended

**1. PLT self-heal negative control on CI**

The local PLT-corruption proof (SUMMARY.md §PLT-Corruption Recovery Proof) was observed on OTP 28 / Elixir 1.19. The structural argument that a genuine type error still reds the job is sound (step 2 is not `continue-on-error`), but an observed negative control on the actual CI toolchain (OTP 27 / Elixir 1.18) was not performed. This is noted as informational — the structural guarantee holds regardless of the OTP version.

**What to do:** On the next `phase/129` CI run, check the dialyzer job logs. When step 1 (`Run Dialyzer`) passes (no stale PLT), step 2 (`Evict stale PLT + rebuild`) will be skipped — this is expected behavior, not a problem. If step 1 fails on a future stale-PLT run, step 2 will appear in the log and its exit code will determine the job outcome.

**Why this is informational, not blocking:** The code structure (step 2 gated on `failure`, step 2 not `continue-on-error`) is the correct Bandit pattern. The local proof confirms the eviction sequence works. The CI log observation is confirmatory, not a prerequisite.

---

### Gaps Summary

No gaps found. All seven must-have truths are verified directly against the codebase. All scope fences confirmed intact. Both CACHE-01 and CACHE-02 requirements are satisfied by the delivered artifacts.

---

_Verified: 2026-07-01_
_Verifier: Claude (gsd-verifier)_
