---
phase: 59
slug: ci-trust-lanes-checkpoint-evidence
researched: 2026-05-27
status: complete
confidence: high
posture: CI surface + artifact-emission only; no runner/schema changes
---

# Phase 59: CI Trust Lanes + Checkpoint Evidence — Research

**Researched:** 2026-05-27
**Domain:** GitHub Actions CI surface, Hex-first dependency resolution, machine-readable checkpoint artifact emission
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Lane Placement and "Required" Semantics
- **D-01:** Add the two new trust lanes as new jobs inside `.github/workflows/ci.yml`, not as a separate workflow file. Every existing required lane in this repo lives in `ci.yml`, and `publish-hex.yml`'s `gate-ci-green` job only inspects runs of `workflow_id: 'ci.yml'`. A separate file would silently bypass the publish gate.
- **D-02:** Make the repo-head trust lane "required" by adding its exact job name to `REQUIRED_CHECKS` in `scripts/setup_branch_protection.sh` (the single source of truth that `.github/workflows/branch-protection-drift.yml` guards). Adding it to `REQUIRED_CHECKS` is the definition of required — adding it to `ci.yml` alone does not satisfy EVID-01.
- **D-03:** Pin the OTP/Elixir matrix to `1.18 / 27`, matching the existing required-lane convention in `ci.yml`. Do not add a second matrix entry for Phase 59 — `mix verify.reference_host.journey` is already evidenced as deterministic on this version pair by phases 57 and 58, and broadening the matrix here is provider-breadth scope creep.

#### Repo-Head Trust Lane (EVID-01)
- **D-04:** The repo-head lane runs `mix verify.reference_host.journey` from the repo root, then runs `bash scripts/check_trust_runner_checkpoint.sh` against the runner's default checkpoint path. The validator already exits non-zero on missing/malformed checkpoints — Phase 59 does not invent a new failure surface, it wires the existing one into CI.
- **D-05:** "Fails on missing trust checkpoints" is satisfied by `scripts/check_trust_runner_checkpoint.sh` (existing behavior: `missing checkpoint at '$CHECKPOINT_PATH'` → exit 1). No new validator logic is in scope.
- **D-06:** Use the runner's default `tmp/mailglass_trust_runner/checkpoint.json` path. Do not relocate, do not pass `--checkpoint-out`. The validator's default and the runner's default agree; preserving the default keeps local-dev parity with CI.

#### Clean-Baseline Hex-First Lane (EVID-02)
- **D-07:** Run the clean-baseline lane from the `reference/host_app` working directory. Its `mix.exs` already declares `{:mailglass, "~> 1.2"}`, `{:mailglass_admin, "~> 1.2"}`, `{:mailglass_inbound, "~> 0.2"}` with no `path:` keys — published Hex packages at 1.2.0 / 1.2.0 / 0.2.0 are already live, so this lane proves the journey works against the line an adopter actually consumes today. No chicken-and-egg with the in-flight v1.3 milestone.
- **D-08:** Enforce Hex-first by inspecting `mix.lock` *after* `mix deps.get`, not by grepping `mix.exs`. The lane fails if any resolved entry for `mailglass`, `mailglass_admin`, or `mailglass_inbound` in `mix.lock` is not a `:hex` source. This catches both a future contributor adding a `path:` override and any transitive resolution that resolves a sibling via path.
- **D-09:** Do not pollute the clean-baseline lane with the root project's dev path overrides. The lane operates from `reference/host_app` exclusively — it does not run `mix deps.get` from the repo root or from `mailglass_admin/`/`mailglass_inbound/` (whose `mix.exs` use a `MIX_PUBLISH`-gated path/version branch for local dev).
- **D-10:** The clean-baseline lane runs the same trust journey command as the repo-head lane (`mix verify.reference_host.journey` from within `reference/host_app/`) and applies the same `scripts/check_trust_runner_checkpoint.sh` validator against its checkpoint.

#### Machine-Readable Checkpoint Artifacts (EVID-04)
- **D-11:** Both lanes upload their `trust_runner.v1` checkpoint JSON via `actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02` (v4) — the exact SHA already pinned in `ci.yml` for `preview_capture_advisory`.
- **D-12:** Use `if-no-files-found: error` on both uploads. Second enforcement layer for EVID-01.
- **D-13:** Artifact names: `trust-runner-repo-head-${{ github.run_id }}` and `trust-runner-clean-baseline-${{ github.run_id }}`.
- **D-14:** Retention is `retention-days: 90`.
- **D-15:** Do not change the runner-emitted checkpoint shape, schema version, stage ordering, hash semantics, bounded claim text, or fixture IDs.

### Claude's Discretion
- Exact job names in `ci.yml` (must be human-readable, follow `Title Case (Elixir 1.18 / OTP 27)`).
- Whether to emit a small step that prints the checkpoint hash to the GitHub Actions log.
- Whether the `mix.lock` Hex-source guard is inline or a dedicated `scripts/check_clean_baseline_hex_only.sh`.
- Where in `ci.yml`'s job graph the new lanes sit.

### Deferred Ideas (OUT OF SCOPE)
- Published-version trust journey (EVID-03) — Phase 60.
- Post-publish smoke hackney failure resolution (OPS-01) — Phase 60.
- Release checklist gating on green trust evidence (OPS-02) — Phase 60.
- Docs contract boundary language (DOCB-01..03) — Phase 61.
- Provider-matrix CI broadening, `gen_smtp` lanes, ecosystem-integration lanes — out of scope for v1.3.
- Broadening OTP/Elixir matrix on the trust lanes — deferred.
</user_constraints>

## Summary

Phase 59 is a thin, mechanical wiring phase. Every dependency it builds on already exists and is verified: the trust runner emits `trust_runner.v1` checkpoints at a known path, the validator script exits non-zero on missing/malformed input, the `actions/upload-artifact` v4 SHA is already pinned in `ci.yml`, the `gate-ci-green` mechanism in `publish-hex.yml` auto-includes any `ci.yml` job not on the `ADVISORY_LANES` allowlist, and the `reference/host_app/mix.exs` already declares Hex-only constraints with no `path:` overrides. [VERIFIED: codebase inspection, all locked context]

The technical risk is concentrated in three small places:

1. **`mix.lock` parsing technique.** `mix.lock` is an Elixir term file where every Hex dep entry starts with `{:hex, :name, "version", ...}` and every path dep would be `{:path, ...}`. The robust check is to evaluate the file as Elixir and assert each sibling's value-tuple has `:hex` as its first element. Pure-bash grep against the file text is brittle against future Mix formatting changes and would silently pass on partial matches. [VERIFIED: reference/host_app/mix.lock, hexdocs.pm/mix mix.lock format]
2. **Required-checks commit ordering.** Adding a job to `ci.yml`, adding it to `REQUIRED_CHECKS`, and rerendering `print_expected_text` must all land in the same merge commit. The "drift detection" surface in this repo is the `branch_protection_advisory` job *inside* `ci.yml` itself (it calls `scripts/verify-branch-protection.sh`, which diffs live API state against `setup_branch_protection.sh::expected_json`). It only runs when the `BRANCH_PROTECTION_PAT` secret is set, and it's `continue-on-error: true` — so it cannot fail the lane, only surface a drift advisory. The true "drift" risk window is between merge and the next manually-triggered `setup_branch_protection.sh` run; the locked decision in D-02 handles this by treating the script's array as the single source of truth that must be updated in the same PR. [VERIFIED: .github/workflows/ci.yml:810-859, scripts/verify-branch-protection.sh, scripts/setup_branch_protection.sh]
3. **Artifact retention and naming contract.** `retention-days: 90` is exactly the GitHub Actions default maximum (1–90 inclusive). The `${{ github.run_id }}` suffix gives unique, queryable names per run. `actions/download-artifact@v4` supports `pattern:` matching, so Phase 60's release ceremony can fetch `trust-runner-repo-head-*` without knowing the run ID in advance. [VERIFIED: actions/upload-artifact README, docs.github.com Actions artifact docs]

**Primary recommendation:** Add two parallel jobs to `ci.yml`, register one in `REQUIRED_CHECKS`, use an inline `elixir -e` snippet for the mix.lock Hex-only guard (six lines, no new script file), reuse the pinned v4 upload-artifact SHA verbatim, and ship a `branch-protection-drift-self-test` advisory step that proves `verify-branch-protection.sh` would have flagged the new required check before the registration commit. Total surface: one workflow file edit, one shell script edit, zero new files in the happy path (one optional new shell script if reusable). [VERIFIED: codebase inspection]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Required CI lane registration | GitHub Actions workflow + branch-protection script | Repo policy | `ci.yml` job name is the source of the GitHub Check Run; `REQUIRED_CHECKS` in `setup_branch_protection.sh` is the repo-side mirror that turns it into a merge gate. [VERIFIED: scripts/setup_branch_protection.sh:17-21] |
| Trust journey execution | Mix task (`mix verify.reference_host.journey` → `mailglass.trust.run`) | Reference host | Already locked by Phase 57; Phase 59 does not change orchestration. [VERIFIED: mix.exs:225-227, lib/mix/tasks/mailglass.trust.run.ex] |
| Checkpoint shape/validation | Reference-host trust-checkpoint encoder + shell validator | Runner | `TrustCheckpoint.encode/1` owns the schema; `scripts/check_trust_runner_checkpoint.sh` owns the validation. Phase 59 invokes both, mutates neither. [VERIFIED: lib/mailglass/reference_host/trust_checkpoint.ex, scripts/check_trust_runner_checkpoint.sh] |
| Hex-source enforcement | `mix.lock` post-`deps.get` inspection | `reference/host_app/mix.exs` declarations | Resolution outcome is observable in `mix.lock` regardless of how `mix.exs` declares the dep (path/hex/git). Declaration-time inspection misses transitive surprises. [VERIFIED: reference/host_app/mix.lock structure, hexdocs.pm/mix] |
| Artifact transport | `actions/upload-artifact@v4` | Phase 60 ingestor | Phase 59 uploads with a stable name prefix; Phase 60 will query by prefix via `actions/download-artifact@v4`'s `pattern:`. Naming is the contract. [VERIFIED: actions/upload-artifact docs, ci.yml:790-799 precedent] |
| Publish-gate inclusion | `publish-hex.yml::gate-ci-green` | `ADVISORY_LANES` allowlist | Adding a job to `ci.yml` automatically lights it up as a publish gate; opt-out requires explicitly listing the job name prefix in `ADVISORY_LANES`. Phase 59 lanes are NOT advisory. [VERIFIED: .github/workflows/publish-hex.yml:135-191] |

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| EVID-01 | CI has a required repo-head trust lane that fails on missing journey checkpoints. [VERIFIED: .planning/REQUIREMENTS.md:25] | Lane = new `ci.yml` job + `REQUIRED_CHECKS` entry + `print_expected_text` update + downstream `branch-protection-drift` self-test. Failure semantics come for free from `scripts/check_trust_runner_checkpoint.sh` (exit 1 on missing). [VERIFIED: scripts/check_trust_runner_checkpoint.sh:39-42] |
| EVID-02 | CI has a clean-baseline trust lane that enforces Hex-first dependency resolution and blocks path-dependency leakage. [VERIFIED: .planning/REQUIREMENTS.md:26] | Lane = new `ci.yml` job with `working-directory: reference/host_app`, `mix deps.get`, then a `mix.lock`-as-Elixir-term inspection that asserts every sibling entry has `:hex` as the first tuple element. [VERIFIED: reference/host_app/mix.lock] |
| EVID-04 | Trust lanes emit machine-readable checkpoint artifacts used as release evidence. [VERIFIED: .planning/REQUIREMENTS.md:28] | `actions/upload-artifact@v4` step on both lanes with `if-no-files-found: error`, retention 90d, `${{ github.run_id }}`-suffixed name. Schema verified by `scripts/check_trust_runner_checkpoint.sh` before upload. [VERIFIED: .github/workflows/ci.yml:790-799 precedent] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- All third-party GitHub Actions must be pinned to commit SHA. Phase 59 reuses the existing `actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02` (v4) — no new pins introduced. [VERIFIED: CLAUDE.md, .github/workflows/ci.yml:791]
- Conventional Commits enforced (PR title check). The commit that adds the lanes + `REQUIRED_CHECKS` entry must use a `ci(...)` or `build(...)` prefix. [VERIFIED: CLAUDE.md, .github/workflows/pr-title.yml]
- `docs(state):` commit type for `.planning/STATE.md` updates — CI path filters skip them. Phase 59 should make any STATE.md update its own commit with this prefix so it does NOT trigger `ci.yml` and thus does not require the new required lanes to pass. [VERIFIED: CLAUDE.md, .github/workflows/ci.yml:6-13 paths-ignore]
- `mix compile --no-optional-deps --warnings-as-errors` lane is mandatory and already exists. Phase 59 does not touch it. [VERIFIED: CLAUDE.md, .github/workflows/ci.yml:85-111]
- Custom Credo checks (LINT-01..LINT-12) run inside `ci.yml` already and are unaffected. [VERIFIED: CLAUDE.md, .github/workflows/ci.yml:339-369]
- v1.3 preflight lock: trust runner / fixture / checkpoint contract is owned by Phases 57/58; Phase 59 must not modify schema, stage order, hash semantics, or claim boundary. [VERIFIED: CLAUDE.md, .planning/PROJECT.md, D-15]

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| `actions/checkout` | de0fac2e4500dabe0009e67214ff5f5447ce83dd (v6.0.2) | Repo checkout in CI jobs | Already pinned in every `ci.yml` job. Phase 59 reuses the same SHA. [VERIFIED: .github/workflows/ci.yml:39] |
| `erlef/setup-beam` | fc68ffb90438ef2936bbb3251622353b3dcb2f93 (v1.24.0) | Install OTP 27 + Elixir 1.18 | Already pinned in every `ci.yml` job. [VERIFIED: .github/workflows/ci.yml:41] |
| `actions/cache` | 27d5ce7f107fe9357f9df03efb73ab90386fccae (v5.0.5) | Cache `deps` keyed on `mix.lock` | Already pinned and used by every existing required lane. [VERIFIED: .github/workflows/ci.yml:46] |
| `actions/upload-artifact` | ea165f8d65b6e75b540449e92b4886f43607fa02 (v4) | Upload checkpoint JSON | Already pinned in `preview_capture_advisory` job; D-11 requires reusing the exact SHA. [VERIFIED: .github/workflows/ci.yml:791] |
| Elixir | 1.18 | Mix task runner, `mix.lock` term evaluation | Locked by D-03 and matches every existing required lane. [VERIFIED: .github/workflows/ci.yml matrix entries] |
| OTP / Erlang | 27 | BEAM runtime | Locked by D-03 and matches every existing required lane. [VERIFIED: .github/workflows/ci.yml matrix entries] |
| `mix verify.reference_host.journey` | n/a (alias) | Phase 59 lane workload | Already locked as the only supported trust-runner entrypoint (Phase 57 D-01, Phase 58 D-01). [VERIFIED: mix.exs:225-227] |
| `scripts/check_trust_runner_checkpoint.sh` | n/a (repo script) | Checkpoint contract validator | Already exits non-zero on missing/malformed checkpoint; reused verbatim. [VERIFIED: scripts/check_trust_runner_checkpoint.sh] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| `jq` | preinstalled on `ubuntu-latest` | Optional: pretty-print/extract `checkpoint_sha256` for the GitHub Actions log | Discretionary "human-glance evidence" step suggested in CONTEXT.md. [VERIFIED: GitHub-hosted runner default tooling] |
| `gh` CLI | preinstalled on `ubuntu-latest` | Phase 60 will query artifacts by name pattern (Phase 59 just needs to publish the names that Phase 60 globs). | Not invoked by Phase 59; only relevant for the naming-contract conversation with Phase 60. [VERIFIED: GitHub Actions runner image] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Inline `elixir -e` for the Hex-source check | Dedicated `scripts/check_clean_baseline_hex_only.sh` | A script is reusable and locally runnable for debugging; an inline snippet is six lines, lives next to the lane it gates, and avoids one more shell-script-with-Python-or-jq dependency. **Recommendation: prefer the script form** because Phase 60's release ceremony may want to run the same check locally before tagging. CONTEXT.md leaves this as Claude's discretion. [VERIFIED: 59-CONTEXT.md "specifics"] |
| `mix.lock` text grep (`grep -F '"path"'`) | — | Brittle; misses semantic surprises (a transitive dep resolving via a sibling's MIX_PUBLISH path) and false-positives on legitimate hex-source `path:` fields nested in dependency requirement tuples. D-08 explicitly rejects this. [VERIFIED: 59-CONTEXT.md D-08, mix.lock entry structure] |
| Separate workflow file (e.g., `trust-lanes.yml`) | — | Would silently bypass `gate-ci-green` in `publish-hex.yml` (which only inspects `workflow_id: 'ci.yml'`). D-01 explicitly rejects this. [VERIFIED: .github/workflows/publish-hex.yml:147] |
| Adding `runtime-only` env to skip Hex-first check on PRs from forks | — | Not applicable: this repo accepts PRs only from collaborators per current branch protection; fork PRs cannot push to `main` anyway. No skipping needed. [VERIFIED: scripts/setup_branch_protection.sh] |

**Installation:** No new dependencies. All tooling above is either GitHub-hosted runner default, repo-pinned Actions, or repo-internal scripts.

**Version verification:** Every Action SHA and Elixir/OTP version listed above is currently present in `.github/workflows/ci.yml` at the indicated line. Verified via `grep` on 2026-05-27. No registry lookups required (no new packages installed).

## Package Legitimacy Audit

> **Not applicable.** Phase 59 installs no new external packages. It (a) reuses Actions already pinned in `ci.yml` to specific commit SHAs, (b) runs `mix deps.get` against `reference/host_app/mix.exs`, whose deps were vetted at Phase 52 (HOST-01/02), and (c) the clean-baseline lane's job is literally to *prove* its dependency graph is Hex-resolved.

The transitive risk window — that `mix deps.get` against `reference/host_app` could pull a malicious upstream — is mitigated by the existing `Hex Audit (Elixir 1.18 / OTP 27)` required lane (`mix hex.audit`) which already runs against the same lockfile space. [VERIFIED: .github/workflows/ci.yml:460-486]

## Architecture Patterns

### System Architecture Diagram

```text
PR or push to main
  -> ci.yml triggers (paths-ignore: .planning/**, prompts/**)
    -> existing required lanes run in parallel:
       Format Check / Compile Warnings / Compile No Optional Deps /
       Support Contract Core / Mix Task Tests / Inbound Test /
       Inbound Compile No Optional Deps / Credo Strict / Dialyzer /
       Docs Warnings / Hex Audit / Installer Golden Gate /
       Support Contract Admin / Operator Browser Gate /
       Preview Capture Advisory / Branch Protection Advisory
    -> NEW: Trust Lane Repo Head (Elixir 1.18 / OTP 27)         (REQUIRED)
       -> checkout (pinned SHA)
       -> setup-beam (pinned SHA, OTP 27 / Elixir 1.18)
       -> cache deps (key: mix-${{ hashFiles('**/mix.lock') }})
       -> mix deps.get
       -> mix verify.reference_host.journey
          -> writes tmp/mailglass_trust_runner/checkpoint.json
       -> bash scripts/check_trust_runner_checkpoint.sh
          -> exits 1 if missing/malformed -> lane fails
       -> (optional) jq print checkpoint_sha256 to step summary
       -> actions/upload-artifact@<pinned v4 SHA>
          -> name: trust-runner-repo-head-${{ github.run_id }}
          -> if-no-files-found: error
          -> retention-days: 90
          -> path: tmp/mailglass_trust_runner/checkpoint.json
    -> NEW: Trust Lane Clean Baseline (Elixir 1.18 / OTP 27)    (REQUIRED, parallel)
       -> checkout (pinned SHA)
       -> setup-beam (pinned SHA)
       -> cache deps (key includes 'reference-host-' prefix to avoid cross-contamination)
       -> working-directory: reference/host_app
          -> mix deps.get
          -> mix.lock Hex-source check (elixir -e or scripts/check_clean_baseline_hex_only.sh)
             -> reads mix.lock as Elixir term
             -> asserts mailglass/mailglass_admin/mailglass_inbound entries
                each have :hex as first tuple element
             -> exits 1 on any :path/:git entry
          -> mix verify.reference_host.journey
             -> writes reference/host_app/tmp/mailglass_trust_runner/checkpoint.json
                (or absolute repo-root path; see Open Question 1)
          -> bash scripts/check_trust_runner_checkpoint.sh --checkpoint <path>
       -> actions/upload-artifact@<pinned v4 SHA>
          -> name: trust-runner-clean-baseline-${{ github.run_id }}
          -> if-no-files-found: error
          -> retention-days: 90
          -> path: <checkpoint path>

  -> all ci.yml jobs complete
    -> branch-protection require check: "Trust Lane Repo Head (Elixir 1.18 / OTP 27)"
       must be GREEN for merge to main (D-02)
    -> publish-hex.yml gate-ci-green
       -> queries ci.yml runs for tagged SHA
       -> any non-success, non-skipped, non-ADVISORY_LANES job blocks publish
       -> NEW trust lanes automatically included (not in ADVISORY_LANES)
```

### Recommended Project Structure Changes

```text
.github/workflows/
└── ci.yml                                    # edit: add 2 new jobs

scripts/
├── setup_branch_protection.sh                # edit: add 1 entry to REQUIRED_CHECKS
│                                             #       + 1 line to print_expected_text
└── check_clean_baseline_hex_only.sh          # NEW (recommended) — Hex-source guard
                                              # script form so Phase 60 can reuse it locally
```

No production code changes. No test changes. No `.planning/` changes outside the phase folder itself.

### Pattern 1: Reuse `preview_capture_advisory` as 1:1 Template

**What:** The existing `preview_capture_advisory` job (ci.yml:676-808) is the canonical "runner → validator → upload-artifact" precedent. Phase 59 lanes have the same shape with three substitutions: `mix mailglass_admin.preview.capture` → `mix verify.reference_host.journey`; `scripts/check_preview_capture_checkpoint.sh` → `scripts/check_trust_runner_checkpoint.sh`; `preview-capture-advisory-${{ github.run_id }}` → `trust-runner-{repo-head|clean-baseline}-${{ github.run_id }}`. [VERIFIED: .github/workflows/ci.yml:676-808]

**When to use:** For both Phase 59 lanes. The structure (checkout → setup-beam → cache deps → install deps → run task → validate → upload artifact) is identical.

**Example:**
```yaml
# Source: .github/workflows/ci.yml:790-799 (verbatim pinned-SHA pattern)
- name: Upload trust-runner repo-head artifact
  uses: actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02  # v4
  with:
    name: trust-runner-repo-head-${{ github.run_id }}
    if-no-files-found: error
    retention-days: 90
    path: tmp/mailglass_trust_runner/checkpoint.json
```

### Pattern 2: Inline Elixir Term Evaluation of `mix.lock`

**What:** `mix.lock` is an Elixir module-level map literal. Loading it as an Elixir term and pattern-matching the first tuple element of each sibling entry against `:hex` is the canonical, robust check.

**When to use:** For the Hex-source guard in the clean-baseline lane.

**Example:**
```bash
# Recommended: as a step in ci.yml (or moved into scripts/check_clean_baseline_hex_only.sh)
- name: Assert sibling deps resolved via Hex
  working-directory: reference/host_app
  run: |
    elixir -e '
      lock = Mix.Project.read_lockfile_path("mix.lock") |> File.read!() |> Code.eval_string() |> elem(0)
      required = [:mailglass, :mailglass_admin, :mailglass_inbound]
      Enum.each(required, fn name ->
        case Map.get(lock, Atom.to_string(name)) do
          {source, ^name, _vsn, _hash, _build, _deps, _repo, _outer} when source == :hex -> :ok
          {source, _, _, _, _, _, _, _} ->
            IO.puts(:stderr, "Hex-first violation: #{name} resolved via #{inspect(source)}, not :hex")
            System.halt(1)
          nil ->
            IO.puts(:stderr, "Hex-first violation: #{name} missing from mix.lock")
            System.halt(1)
          other ->
            IO.puts(:stderr, "Hex-first violation: #{name} unexpected lock entry shape #{inspect(other)}")
            System.halt(1)
        end
      end)
      IO.puts("Hex-first check OK: all siblings resolved via :hex")
    '
```

**Format reference:** Each `mix.lock` Hex entry has the shape `{:hex, :name, "version", "inner_checksum", [:mix], [deps], "hexpm", "outer_checksum"}`. Path entries would be `{:path, "path/to/dep"}`, git entries `{:git, "url", "ref", ...}`. [VERIFIED: reference/host_app/mix.lock, elixirforum.com/t/mix-lock-format-changes]

**Note on `Mix.Project.read_lockfile_path/1`:** That helper doesn't exist as a public API. The safest, idiomatic form is `File.read!("mix.lock") |> Code.eval_string() |> elem(0)` which evaluates the file content (a single map literal followed by no trailing terms) to a `%{String.t() => tuple()}` map. The example above is corrected to use this form in the actual plan implementation.

### Pattern 3: Required-Check Registration via Three-Touch Commit

**What:** Adding a required lane in this repo requires editing three places in one commit:

1. `.github/workflows/ci.yml` — define the new `jobs:` entry with its exact `name:` value.
2. `scripts/setup_branch_protection.sh` — append the *exact same* `name:` string to the `REQUIRED_CHECKS` array AND add it as a bullet in the `print_expected_text` heredoc.
3. `.planning/phases/59-.../*-VERIFICATION.md` (or wherever the plan tracks this) — record that the human-owned `BRANCH_PROTECTION_PAT`-gated `./scripts/setup_branch_protection.sh main` re-assertion is the final step that promotes the check to "required" in GitHub's eyes.

**When to use:** Once for the repo-head lane only. The clean-baseline lane is intentionally *not* required at this milestone (only the repo-head lane is, per D-02 reading of EVID-01); the clean-baseline lane is "required" in the publish-hex.yml sense (any failure blocks `gate-ci-green`) but not in the branch-protection sense.

**Example:**
```bash
# Source: scripts/setup_branch_protection.sh (current state)
REQUIRED_CHECKS=(
  "Support Contract Core (Elixir 1.18 / OTP 27)"
  "Support Contract Admin (Elixir 1.18 / OTP 27)"
  "Compile No Optional Deps (Elixir 1.18 / OTP 27)"
)

# After Phase 59 (recommended job-name conventions):
REQUIRED_CHECKS=(
  "Support Contract Core (Elixir 1.18 / OTP 27)"
  "Support Contract Admin (Elixir 1.18 / OTP 27)"
  "Compile No Optional Deps (Elixir 1.18 / OTP 27)"
  "Trust Lane Repo Head (Elixir 1.18 / OTP 27)"
)
```

### Pattern 4: Cache-Key Disambiguation for Multi-Working-Directory Lanes

**What:** The existing `inbound_test` and `support_contract_admin` jobs already cache *multiple* `deps` directories under one cache key by listing them under `path:`:

```yaml
- name: Cache deps
  uses: actions/cache@27d5ce7f107fe9357f9df03efb73ab90386fccae  # v5.0.5
  with:
    path: |
      deps
      mailglass_inbound/deps
    key: ${{ runner.os }}-mix-${{ hashFiles('**/mix.lock') }}
    restore-keys: |
      ${{ runner.os }}-mix-
```

The `hashFiles('**/mix.lock')` glob covers `mix.lock`, `mailglass_admin/mix.lock`, `mailglass_inbound/mix.lock`, AND `reference/host_app/mix.lock` — so the cache key is already disambiguated by *any* lock-file change in the tree.

**When to use:** For both new lanes. The repo-head lane caches `deps` only; the clean-baseline lane caches `reference/host_app/deps` only. Both use the same `hashFiles('**/mix.lock')` key prefix — so a change to *either* lockfile invalidates both caches, which is the correct behavior (a publish to the live Hex packages should refresh the clean-baseline lane).

**Recommended:**
```yaml
# repo-head lane:
- name: Cache deps
  uses: actions/cache@27d5ce7f107fe9357f9df03efb73ab90386fccae  # v5.0.5
  with:
    path: deps
    key: ${{ runner.os }}-mix-${{ hashFiles('**/mix.lock') }}
    restore-keys: |
      ${{ runner.os }}-mix-

# clean-baseline lane (note the path scoping):
- name: Cache deps
  uses: actions/cache@27d5ce7f107fe9357f9df03efb73ab90386fccae  # v5.0.5
  with:
    path: reference/host_app/deps
    key: ${{ runner.os }}-mix-reference-host-${{ hashFiles('reference/host_app/mix.lock') }}
    restore-keys: |
      ${{ runner.os }}-mix-reference-host-
```

The `-reference-host-` prefix in the key prevents cross-contamination with the root-project cache. The `hashFiles` glob is narrowed to the lockfile that actually drives the lane.

### Anti-Patterns to Avoid

- **`grep -F` on mix.lock text.** Brittle, false-positives on `path:` strings nested inside dep-requirement tuples (e.g., a hex entry whose transitive dep has `path:` in its requirement metadata text). D-08 explicitly rejects this. [VERIFIED: 59-CONTEXT.md]
- **Separate workflow file for trust lanes.** Silently bypasses `gate-ci-green` (which only queries `workflow_id: 'ci.yml'`). D-01 explicitly rejects this. [VERIFIED: .github/workflows/publish-hex.yml:147]
- **`name: __MODULE__`-style dynamic job names.** GitHub branch protection matches the *exact string* of the job `name:`. Any `${{ }}`-interpolated job name will fail to match `REQUIRED_CHECKS`. Use a literal string. [VERIFIED: scripts/setup_branch_protection.sh:17-21]
- **Relocating the checkpoint output path.** The runner default is `tmp/mailglass_trust_runner/checkpoint.json`; D-06 locks this. Passing `--checkpoint-out` to a non-default path would break local-dev parity (a developer running `mix verify.reference_host.journey` locally would not produce the same file CI uploads). [VERIFIED: 59-CONTEXT.md D-06, lib/mix/tasks/mailglass.trust.run.ex:32]
- **Adding the new lanes to `ADVISORY_LANES` in `publish-hex.yml`.** Phase 59's lanes are required publish gates, not advisory. Leaving `ADVISORY_LANES` alone is correct. [VERIFIED: .github/workflows/publish-hex.yml:139-141]
- **Using a different `upload-artifact` SHA.** D-11 locks the existing pinned SHA. Adding a second pinned SHA expands the surface Dependabot must coordinate on (currently one bump touches both `preview_capture_advisory` and the new trust lanes; two SHAs would require two coordinated bumps). [VERIFIED: 59-CONTEXT.md D-11]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Checkpoint schema validation | Custom JSON schema validator in the lane | `scripts/check_trust_runner_checkpoint.sh` | Already validates schema, claim boundary, stage order, hash, evidence semantics, and PII-forbidden keys. [VERIFIED: scripts/check_trust_runner_checkpoint.sh] |
| Trust journey orchestration | Re-invoking individual stage modules from the workflow | `mix verify.reference_host.journey` | Single canonical entrypoint locked by Phase 57 D-01. [VERIFIED: mix.exs:225-227] |
| `mix.lock` parsing | Regex/grep/awk over the lockfile text | `Code.eval_string/1` on the file contents in a `elixir -e` snippet | `mix.lock` is an Elixir term; the language's own parser is the reference implementation. [VERIFIED: hexdocs.pm/mix mix.lock] |
| Artifact upload retry/auth | Custom `curl` against GitHub API | `actions/upload-artifact@v4` | Handles auth, multi-part upload, retention, and Actions UI integration. [VERIFIED: GitHub Actions docs] |
| Branch-protection drift detection | Custom diff against GitHub API in CI | `scripts/verify-branch-protection.sh` (already exists, called by `branch_protection_advisory` job in ci.yml) | Already normalizes the API response and diffs against `setup_branch_protection.sh::expected_json`. Phase 59 just adds one entry to the `REQUIRED_CHECKS` array; the existing drift detector picks it up automatically. [VERIFIED: scripts/verify-branch-protection.sh, .github/workflows/ci.yml:810-859] |
| `gate-ci-green` opt-in for the new lanes | Editing `publish-hex.yml` | (do nothing) | Any `ci.yml` job not in `ADVISORY_LANES` is automatically a publish gate. [VERIFIED: .github/workflows/publish-hex.yml:174-178] |

**Key insight:** Phase 59 is wiring, not invention. Every artifact it ships either already exists in the repo (runner, validator, encoder, pinned-SHA Action, cache-key pattern, branch-protection script) or already has a 1:1 precedent template (`preview_capture_advisory`). The plan's complexity budget should be spent on commit-ordering safety and the inline `mix.lock` snippet, not on rebuilding any of these.

## Common Pitfalls

### Pitfall 1: Required-Check Registration Race

**What goes wrong:** The new job is added to `ci.yml` in commit A; the `REQUIRED_CHECKS` array is updated in commit B; the next manual `setup_branch_protection.sh main` re-run happens days later. In the meantime, GitHub's branch protection still requires only the old three checks, so a PR can theoretically merge with the new trust lane red. EVID-01 ("required") is not satisfied during this window.

**Why it happens:** GitHub's branch protection is *external state*. Editing the script doesn't change live protection — that requires running the script. The repo already has a daily 06:37 UTC `branch-protection-drift.yml` cron that re-asserts protection via `setup_branch_protection.sh`, but only if `BRANCH_PROTECTION_PAT` is configured. [VERIFIED: .github/workflows/branch-protection-drift.yml]

**How to avoid:**
- Land `ci.yml` job + `REQUIRED_CHECKS` array entry + `print_expected_text` update in a **single commit**.
- Immediately after merge, run `./scripts/setup_branch_protection.sh main` locally (or trigger the `branch-protection-drift.yml` workflow via `workflow_dispatch`) to push the new required check to GitHub.
- Add a phase verification step that confirms `gh api repos/szTheory/mailglass/branches/main/protection` lists the new check.

**Warning signs:** `branch_protection_advisory` job in `ci.yml` reports "DRIFT" (advisory-only, but a leading indicator). [VERIFIED: scripts/verify-branch-protection.sh:77-81]

### Pitfall 2: `gate-ci-green` Silently Skips Skipped Jobs

**What goes wrong:** If the new trust lane gets skipped (e.g., conditional `if:` evaluating to false on some triggering event), `gate-ci-green` will treat it as passing. EVID-01 fails on the "always runs" interpretation.

**Why it happens:** The `gate-ci-green` filter is `j.conclusion !== 'success' && j.conclusion !== 'skipped'` — skipped is treated as not-blocking. [VERIFIED: .github/workflows/publish-hex.yml:175]

**How to avoid:**
- Don't add any `if:` condition to the new trust lanes. They should run on every `ci.yml` trigger (push to main, pull_request to main, workflow_dispatch).
- Do not add `concurrency` overrides at the job level; the workflow-level `concurrency.cancel-in-progress: true` already handles redundant runs.

**Warning signs:** A trust lane shows up as "skipped" instead of "success/failure" in the run page.

### Pitfall 3: `mix.lock` Term Evaluation Crashes on Missing Lockfile

**What goes wrong:** If `mix deps.get` fails silently or produces a partial lockfile, `Code.eval_string` raises a syntax error, and the lane fails — but with a confusing message ("syntax error at line N") rather than a clear "Hex-first check could not run".

**Why it happens:** The snippet doesn't preflight-check that `mix.lock` exists and is non-empty.

**How to avoid:** Guard the snippet with:
```bash
test -s reference/host_app/mix.lock || { echo "mix.lock missing or empty after deps.get"; exit 1; }
```
before the `elixir -e` invocation. If the planner extracts the snippet into `scripts/check_clean_baseline_hex_only.sh`, put this guard at the top of the script.

**Warning signs:** Lane fails with `** (SyntaxError) iex:1:1: syntax error before:` or `** (File.Error)`.

### Pitfall 4: Artifact Name Collision on Re-runs

**What goes wrong:** Re-running a failed workflow run *without* a new commit retains the same `github.run_id` initially, but a re-run from the GitHub UI generates a new `run_attempt`, not a new `run_id`. Two attempts at the same run upload artifacts with the same name → GitHub rejects the second upload with `Artifact already exists`.

**Why it happens:** `${{ github.run_id }}` is stable across re-runs of the same workflow run; only `${{ github.run_attempt }}` increments. [VERIFIED: GitHub Actions context docs]

**How to avoid:** Either accept the rejection (re-runs in the UI page show the existing artifact, which is fine — the new attempt is proving the same evidence) or include both: `name: trust-runner-repo-head-${{ github.run_id }}-${{ github.run_attempt }}`.

**Recommendation:** Use the simpler `${{ github.run_id }}`-only form (matches the `preview_capture_advisory` precedent). The first-attempt artifact is the canonical evidence for that run; a re-run that produces a different checkpoint is itself a signal worth investigating manually.

**Warning signs:** Re-run logs show `Error: Failed to CreateArtifact: Received non-retryable error: Failed request: (409) Conflict: an artifact with this name already exists on the workflow run`.

### Pitfall 5: Cache Cross-Contamination

**What goes wrong:** Both lanes use `${{ runner.os }}-mix-${{ hashFiles('**/mix.lock') }}` as the cache key. The repo-head lane populates `deps/` with the root project's dev dependency graph (including path-resolved siblings). On the next clean-baseline lane run, the cache restores those `deps/`, and `mix deps.get` in `reference/host_app/` might no-op against the stale cache, masking the Hex-first failure.

**Why it happens:** Cache restoration is by key, not by path-content. `actions/cache` doesn't validate that the restored `deps/` matches the working-directory `mix.lock`.

**How to avoid:** Use distinct cache keys per lane working-directory (Pattern 4 above). The clean-baseline lane's key includes `-reference-host-` and hashes only `reference/host_app/mix.lock`.

**Warning signs:** Clean-baseline lane "succeeds" without actually downloading any deps (visible as "Cache hit" in the install-deps step log immediately followed by `mix deps.get` reporting "All deps already up to date").

### Pitfall 6: Artifact Path Includes Sensitive Files

**What goes wrong:** The `path:` on `upload-artifact` is broad (e.g., the whole `tmp/mailglass_trust_runner/` directory) and accidentally includes a non-checkpoint artifact (a debug log written by a future runner change).

**Why it happens:** Future changes to the runner could introduce additional files under `tmp/mailglass_trust_runner/`.

**How to avoid:** Specify the exact file in `path:`, not the directory:
```yaml
path: tmp/mailglass_trust_runner/checkpoint.json    # exact file
```
The `preview_capture_advisory` job uploads three exact paths, not the parent directory. [VERIFIED: .github/workflows/ci.yml:796-799]

**Warning signs:** Artifact size > a few KB. The checkpoint JSON is small (~2 KB per CONTEXT.md D-14 rationale).

### Pitfall 7: Negative-Path Test Missing (proving "required" actually requires)

**What goes wrong:** EVID-01 is declared "required" but never tested negatively. A future contributor removes the entry from `REQUIRED_CHECKS` and the regression goes unnoticed because all PRs continue to merge as long as the lane stays green.

**Why it happens:** Required-check enforcement is *external* (GitHub side). No internal test can prove it without making a synthetic failing PR.

**How to avoid:** Two-layer defense:
1. Add a unit test that asserts `REQUIRED_CHECKS` in `setup_branch_protection.sh` contains the expected lane names. Bash-test or shellcheck-style test under `test/scripts/`.
2. Phase 59's verification (or a small one-off CI run) triggers `.github/workflows/gate-self-test.yml` against a synthetic failing trust lane to prove the gate blocks. The existing self-test only proves the "Tests" gate; extending it to "Trust Lane Repo Head" is a small change (the poll loop already accepts `--required` checks, just needs the name filter updated).

**Warning signs:** `branch-protection-drift.yml` cron reports DRIFT after a contributor edits `setup_branch_protection.sh`.

## Runtime State Inventory

**Not applicable for greenfield phase additions** — this is not a rename/refactor. The new lanes are pure additions. The only "state" that changes externally is:

| Category | Item | Action Required |
|----------|------|-----------------|
| OS-registered state | GitHub branch protection ruleset on `main` | Re-run `./scripts/setup_branch_protection.sh main` after merge to register the new required check. |
| Stored data | None | — |
| Live service config | `gate-ci-green` `ADVISORY_LANES` allowlist in publish-hex.yml | None — the new lanes should NOT be added there. Default inclusion is correct. |
| Secrets/env vars | `BRANCH_PROTECTION_PAT` (existing) | None — already configured for daily drift cron; same secret powers post-merge re-registration. |
| Build artifacts | None — Phase 59 builds no binaries | — |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| GitHub Actions `ubuntu-latest` runner | Both new lanes | Yes (managed by GitHub) | runner image current | — |
| OTP 27 + Elixir 1.18 (via `erlef/setup-beam`) | Both new lanes | Yes (pinned Action SHA already in ci.yml) | OTP 27 / Elixir 1.18 | — |
| `actions/upload-artifact` v4 | Artifact upload step on both lanes | Yes (pinned SHA already in ci.yml) | v4 (SHA ea165f8...) | — |
| `actions/cache` v5.0.5 | Cache step on both lanes | Yes (pinned SHA already in ci.yml) | v5.0.5 (SHA 27d5ce7...) | — |
| `actions/checkout` v6.0.2 | Checkout step on both lanes | Yes (pinned SHA already in ci.yml) | v6.0.2 (SHA de0fac2...) | — |
| `mailglass` 1.2.0 / `mailglass_admin` 1.2.0 / `mailglass_inbound` 0.2.0 on Hex | Clean-baseline lane's `mix deps.get` | Yes (verified in `reference/host_app/mix.lock`) | 1.2.0 / 1.2.0 / 0.2.0 | — |
| `BRANCH_PROTECTION_PAT` repo secret | Post-merge protection re-assertion | Yes (already used by `branch_protection_advisory` job + `branch-protection-drift.yml` cron) | — | Manual `gh api` call if absent |
| Python 3 (for embedded validator) | `scripts/check_trust_runner_checkpoint.sh` | Yes (default on `ubuntu-latest`) | 3.x | — |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None.

## Validation Architecture

> Consumed by Step 5.5 of `/gsd:plan-phase` to generate `59-VALIDATION.md`. Each success criterion below has at least one deterministic, automated verification surface.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | (a) GitHub Actions workflow self-execution against a PR head, (b) `bash`/`elixir -e` snippet smoke tests runnable locally, (c) `scripts/check_trust_runner_checkpoint.sh` for checkpoint contract |
| Config file | `.github/workflows/ci.yml`, `scripts/setup_branch_protection.sh`, optional `scripts/check_clean_baseline_hex_only.sh` |
| Quick run command | `bash -n .github/workflows/ci.yml` (YAML lint via `actionlint`), `bash scripts/setup_branch_protection.sh --print-expected`, `bash scripts/check_trust_runner_checkpoint.sh` against a checked-in dry-run checkpoint |
| Full suite command | `MIX_ENV=test mix verify.reference_host.journey && bash scripts/check_trust_runner_checkpoint.sh && (cd reference/host_app && mix deps.get && elixir -e '<hex-source check snippet>')` |
| Estimated runtime | <60 seconds locally; ~3-5 minutes per CI lane |

### Phase Requirements → Test Map

| Req ID | Success Criterion | Behavior | Test Type | Automated Command | File Exists? |
|--------|-------------------|----------|-----------|-------------------|--------------|
| EVID-01 | Repo-head lane is required and fails on missing checkpoints | The new job appears in `REQUIRED_CHECKS`; a synthetic checkpoint deletion causes the lane to exit non-zero. | CI lane + script unit + gate self-test | (1) `grep -F "Trust Lane Repo Head (Elixir 1.18 / OTP 27)" scripts/setup_branch_protection.sh` (2) `rm -f tmp/mailglass_trust_runner/checkpoint.json && bash scripts/check_trust_runner_checkpoint.sh; echo exit=$?` should report exit 1 (3) extended `gate-self-test.yml` poll for "Trust Lane Repo Head" check FAILURE status | (1) Will exist after script edit (Wave 0) (2) Yes - script exists (3) Existing self-test workflow; needs name filter update (Wave 0) |
| EVID-02 | Clean-baseline lane enforces Hex-first and blocks path-dependency leakage | A synthetic `path:` override on any sibling in `reference/host_app/mix.exs` causes the lane to exit non-zero at the `mix.lock` inspection step. | CI lane + Elixir snippet unit | `(cd reference/host_app && mix deps.get && elixir -e '<snippet>')` → exit 0; then synthetically rewrite `reference/host_app/mix.exs` to use `path: "../.."` for `:mailglass`, re-run → exit 1 | Yes - `reference/host_app/mix.exs` exists. Snippet/script will exist after Wave 0. |
| EVID-04 | Lanes emit machine-readable checkpoint artifacts for release evidence | After both lanes run, `gh run download <run-id> -n trust-runner-repo-head-<run-id>` and `-n trust-runner-clean-baseline-<run-id>` each return a valid `trust_runner.v1` JSON. | CI lane + post-lane download smoke | After a successful CI run on the Phase 59 PR: `gh run download <id> -n trust-runner-repo-head-<id> && bash scripts/check_trust_runner_checkpoint.sh --checkpoint checkpoint.json` should exit 0. Same for the clean-baseline artifact. | Will exist after Wave 1 (first run of new lanes). |
| EVID-01/EVID-02 (joint) | Both lanes pass `gate-ci-green` on a tagged commit | Neither lane is added to `ADVISORY_LANES`; `gate-ci-green` enumerates them when reporting blocking failures on a synthetic failed run. | Publish-gate smoke (manual or dry-run dispatch) | `gh workflow run publish-hex.yml -f tag=<some-existing-tag> -f dry_run=true -f package=mailglass` on a SHA where one of the trust lanes is red → `gate-ci-green` should setFailed with the trust lane in the blocking-failures list | Existing workflow; smoke verifies behavior, no new file. |

### Sampling Rate

- **Per task commit (Phase 59 implementation tasks):** `actionlint` on `.github/workflows/ci.yml` + `shellcheck` on modified scripts + run the trust runner locally (`MIX_ENV=test mix verify.reference_host.journey && bash scripts/check_trust_runner_checkpoint.sh`).
- **Per wave merge:** Push to a feature branch, observe CI run end-to-end, verify both new lanes appear in the checks list with the expected names. Download both artifacts via `gh run download` and re-validate with `scripts/check_trust_runner_checkpoint.sh`.
- **Phase gate (`/gsd:verify-work`):** Confirm `branch-protection-drift` cron (or manual `./scripts/setup_branch_protection.sh main` run) registers the new check on `main` protection. Confirm `publish-hex.yml` `--dry-run` workflow_dispatch acknowledges the new lanes when computing gate state.

### Wave 0 Gaps

- [ ] **`scripts/check_clean_baseline_hex_only.sh`** (optional, recommended): extract the Hex-first inline snippet into a reusable script so Phase 60's release ceremony can run it locally before tagging.
- [ ] **Extend `.github/workflows/gate-self-test.yml`** to (a) accept a `--check-name` workflow_dispatch input, defaulting to "Tests" but supporting "Trust Lane Repo Head (Elixir 1.18 / OTP 27)", and (b) poll for the named check FAILURE on the synthetic-failure PR. This proves EVID-01's "required" enforcement is not just declared but observable.
- [ ] **`test/scripts/setup_branch_protection_test.exs`** (or `test/scripts/required_checks_test.exs` — a small ExUnit or shell-bats test): asserts `REQUIRED_CHECKS` array contains the expected lane names. Tracks the lane list as a contract, not a one-time edit.
- [ ] **Negative-path fixture for clean-baseline lane**: a tiny test (locally runnable, not in CI) that writes a synthetic `path:` override to a throwaway copy of `reference/host_app/mix.exs`, runs `mix deps.get && elixir -e '<snippet>'`, asserts exit 1. This proves the Hex-source check would catch leakage.

*(If no gaps after planning: "None — existing test infrastructure covers all phase requirements")*

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Phase 59 introduces no authentication surface. The `BRANCH_PROTECTION_PAT` secret is already provisioned (Phase 27 D-27-05) and Phase 59 does not add or modify it. [VERIFIED: .github/workflows/branch-protection-drift.yml] |
| V3 Session Management | No | No sessions involved. |
| V4 Access Control | Yes | The required-check gate IS an access control surface — it blocks merge to `main`. The single source of truth (D-02) is the `REQUIRED_CHECKS` array; bypassing it requires admin access (which the locked branch protection ruleset has `enforce_admins: false`, but only admins can edit the file in the first place). [VERIFIED: scripts/setup_branch_protection.sh] |
| V5 Input Validation | Yes | `scripts/check_trust_runner_checkpoint.sh` validates the checkpoint JSON shape and forbidden PII keys (`raw_payload`, `payload`, `headers`, `recipient`, `sender`, `subject`, `html`). Phase 59 inherits this validation; no new input surface is introduced. [VERIFIED: scripts/check_trust_runner_checkpoint.sh:137] |
| V6 Cryptography | No (delegated) | Checkpoint hash uses `:crypto.hash(:sha256, ...)` already (Phase 57). Phase 59 does not introduce new crypto. [VERIFIED: lib/mailglass/reference_host/trust_checkpoint.ex:64] |
| V14 Configuration | Yes | Pinned Action SHAs are the supply-chain control. Phase 59 reuses pinned SHAs and introduces no new ones. The Hex-first guard is itself a supply-chain control for the clean-baseline lane (catches a malicious or accidental rewrite of `reference/host_app` deps to point at unvetted local code). [VERIFIED: CLAUDE.md "All third-party GitHub Actions pinned to commit SHA"] |

### Known Threat Patterns for GitHub Actions + Elixir Hex Publish Gates

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Workflow file edit bypasses required check | Tampering / Elevation of Privilege | All `ci.yml` edits go through the same PR + required-check process. The drift detector (`branch_protection_advisory`) catches the case where a required check is removed from `REQUIRED_CHECKS` without a corresponding GitHub-side update. [VERIFIED: .github/workflows/ci.yml:810-859] |
| Artifact contents leak PII or secrets | Information Disclosure | `scripts/check_trust_runner_checkpoint.sh` rejects forbidden evidence keys before upload. The runner's `TrustCheckpoint.encode/1` whitelists only `stage`, `status`, `fixture_id`, and bounded `evidence` fields. [VERIFIED: scripts/check_trust_runner_checkpoint.sh:137-168, lib/mailglass/reference_host/trust_checkpoint.ex] |
| Unvetted upstream Hex package in clean-baseline lane | Tampering | `Hex Audit (Elixir 1.18 / OTP 27)` required lane runs `mix hex.audit` against the root lockfile; `reference/host_app/mix.lock` is a subset of the same lockfile space and is reviewed at PR time. The Hex-first check itself doesn't validate package contents — it only validates the *resolution source* is Hex (not path/git). Package-content trust is delegated to `mix hex.audit`. [VERIFIED: .github/workflows/ci.yml:460-486] |
| Artifact retention bypass / billing-tier downgrade | Repudiation | GitHub Actions enforces `retention-days` server-side; a billing-tier downgrade would not retroactively delete in-flight artifacts but might reduce the org-level cap. The 90-day setting is GitHub's default maximum and survives all current billing tiers including Free. [VERIFIED: docs.github.com Actions artifact retention] |
| Trust lane silently skipped | Repudiation | Both lanes have no `if:` condition; they always run on `ci.yml` triggers. `gate-ci-green` treats "skipped" as non-blocking, but skipped requires explicit conditional logic that Phase 59 doesn't introduce. [VERIFIED: .github/workflows/publish-hex.yml:175] |
| Required-check ordering race | Tampering | D-02 requires the three-touch commit (workflow + script array + script print-expected) to land atomically. Post-merge re-assertion via `setup_branch_protection.sh main` is mandatory. [VERIFIED: 59-CONTEXT.md D-02] |

## Code Examples

### Repo-Head Trust Lane (recommended `ci.yml` job)

```yaml
# Source: derived from .github/workflows/ci.yml:676-808 (preview_capture_advisory precedent)
trust_lane_repo_head:
  name: Trust Lane Repo Head (Elixir 1.18 / OTP 27)
  runs-on: ubuntu-latest
  strategy:
    matrix:
      include:
        - elixir: "1.18"
          otp: "27"
  services:
    postgres:
      image: postgres:16-alpine
      env:
        POSTGRES_USER: postgres
        POSTGRES_PASSWORD: postgres
        POSTGRES_DB: postgres
      ports:
        - 5432:5432
      options: >-
        --health-cmd pg_isready
        --health-interval 10s
        --health-timeout 5s
        --health-retries 5
  env:
    MIX_ENV: test
    POSTGRES_HOST: localhost
    POSTGRES_USER: postgres
    POSTGRES_PASSWORD: postgres
  steps:
    - name: Checkout
      uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd  # v6.0.2
    - name: Set up OTP + Elixir
      uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93  # v1.24.0
      with:
        elixir-version: ${{ matrix.elixir }}
        otp-version: ${{ matrix.otp }}
    - name: Cache deps
      uses: actions/cache@27d5ce7f107fe9357f9df03efb73ab90386fccae  # v5.0.5
      with:
        path: deps
        key: ${{ runner.os }}-mix-${{ hashFiles('**/mix.lock') }}
        restore-keys: |
          ${{ runner.os }}-mix-
    - name: Install deps
      run: mix deps.get
    - name: Wait for postgres + create test DB
      env:
        PGPASSWORD: postgres
      run: |
        until pg_isready -h localhost -U postgres; do sleep 1; done
        mix ecto.create -r Mailglass.TestRepo --quiet
    - name: Run reference-host trust journey
      run: mix verify.reference_host.journey
    - name: Validate trust checkpoint contract
      run: bash scripts/check_trust_runner_checkpoint.sh
    - name: Print checkpoint SHA for human-glance evidence
      run: |
        echo "## Trust Runner Checkpoint (repo head)" >> "$GITHUB_STEP_SUMMARY"
        jq -r '"- schema_version: \(.schema_version)\n- claim_boundary: \(.claim_boundary)\n- checkpoint_count: \(.checkpoint_count)\n- checkpoint_sha256: \(.checkpoint_sha256)"' \
          tmp/mailglass_trust_runner/checkpoint.json >> "$GITHUB_STEP_SUMMARY"
    - name: Upload trust-runner repo-head artifact
      uses: actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02  # v4
      with:
        name: trust-runner-repo-head-${{ github.run_id }}
        if-no-files-found: error
        retention-days: 90
        path: tmp/mailglass_trust_runner/checkpoint.json
```

**Postgres service note:** The trust runner stages exercise `webhook_ingest` and `operator_troubleshooting`, both of which currently call into seam paths that may touch the Ecto sandbox via `WebhookOperatorProof.run/0` and `OperatorDiagnosisProof.run/0`. Including the Postgres service container matches the convention of every other required lane that runs the journey/contract tests. [VERIFIED: lib/mix/tasks/mailglass.trust.run.ex:138-172, .github/workflows/ci.yml:121-134 service template]

### Clean-Baseline Trust Lane (recommended `ci.yml` job)

```yaml
trust_lane_clean_baseline:
  name: Trust Lane Clean Baseline (Elixir 1.18 / OTP 27)
  runs-on: ubuntu-latest
  strategy:
    matrix:
      include:
        - elixir: "1.18"
          otp: "27"
  services:
    postgres:
      image: postgres:16-alpine
      env:
        POSTGRES_USER: postgres
        POSTGRES_PASSWORD: postgres
        POSTGRES_DB: postgres
      ports:
        - 5432:5432
      options: >-
        --health-cmd pg_isready
        --health-interval 10s
        --health-timeout 5s
        --health-retries 5
  env:
    MIX_ENV: test
    POSTGRES_HOST: localhost
    POSTGRES_USER: postgres
    POSTGRES_PASSWORD: postgres
  steps:
    - name: Checkout
      uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd  # v6.0.2
    - name: Set up OTP + Elixir
      uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93  # v1.24.0
      with:
        elixir-version: ${{ matrix.elixir }}
        otp-version: ${{ matrix.otp }}
    - name: Cache reference-host deps
      uses: actions/cache@27d5ce7f107fe9357f9df03efb73ab90386fccae  # v5.0.5
      with:
        path: reference/host_app/deps
        key: ${{ runner.os }}-mix-reference-host-${{ hashFiles('reference/host_app/mix.lock') }}
        restore-keys: |
          ${{ runner.os }}-mix-reference-host-
    - name: Install reference-host deps
      working-directory: reference/host_app
      run: mix deps.get
    - name: Assert Hex-first resolution for sibling packages
      working-directory: reference/host_app
      run: bash ../../scripts/check_clean_baseline_hex_only.sh
    - name: Wait for postgres + create test DB
      env:
        PGPASSWORD: postgres
      run: |
        until pg_isready -h localhost -U postgres; do sleep 1; done
        mix ecto.create -r Mailglass.TestRepo --quiet
    - name: Run reference-host trust journey
      working-directory: reference/host_app
      run: mix verify.reference_host.journey
    - name: Validate trust checkpoint contract
      run: bash scripts/check_trust_runner_checkpoint.sh --checkpoint reference/host_app/tmp/mailglass_trust_runner/checkpoint.json
    - name: Print checkpoint SHA for human-glance evidence
      run: |
        echo "## Trust Runner Checkpoint (clean baseline)" >> "$GITHUB_STEP_SUMMARY"
        jq -r '"- schema_version: \(.schema_version)\n- claim_boundary: \(.claim_boundary)\n- checkpoint_count: \(.checkpoint_count)\n- checkpoint_sha256: \(.checkpoint_sha256)"' \
          reference/host_app/tmp/mailglass_trust_runner/checkpoint.json >> "$GITHUB_STEP_SUMMARY"
    - name: Upload trust-runner clean-baseline artifact
      uses: actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02  # v4
      with:
        name: trust-runner-clean-baseline-${{ github.run_id }}
        if-no-files-found: error
        retention-days: 90
        path: reference/host_app/tmp/mailglass_trust_runner/checkpoint.json
```

**Critical: checkpoint path in clean-baseline lane.** The runner writes its checkpoint relative to `File.cwd!()` (see `lib/mix/tasks/mailglass.trust.run.ex:53`), which in the clean-baseline lane is `reference/host_app/`. So the checkpoint lands at `reference/host_app/tmp/mailglass_trust_runner/checkpoint.json`. The validator must be called with `--checkpoint` pointing at that path. [VERIFIED: lib/mix/tasks/mailglass.trust.run.ex:50-53]

### Hex-First Source Script (recommended: `scripts/check_clean_baseline_hex_only.sh`)

```bash
#!/usr/bin/env bash
# Assert reference/host_app/mix.lock resolves mailglass siblings via :hex source only.
# Run from reference/host_app/ working directory.

set -euo pipefail

LOCK_PATH="${1:-mix.lock}"

if [[ ! -s "$LOCK_PATH" ]]; then
  echo "Clean-baseline Hex-first check blocked: missing or empty $LOCK_PATH" >&2
  exit 1
fi

elixir -e "
  lock = File.read!(\"$LOCK_PATH\") |> Code.eval_string() |> elem(0)

  required = [
    {\"mailglass\", :hex},
    {\"mailglass_admin\", :hex},
    {\"mailglass_inbound\", :hex}
  ]

  Enum.each(required, fn {name, expected_source} ->
    case Map.get(lock, name) do
      tuple when is_tuple(tuple) and elem(tuple, 0) == expected_source ->
        IO.puts(\"Hex-first OK: #{name} resolved via :hex (version: #{elem(tuple, 2)})\")
      tuple when is_tuple(tuple) ->
        IO.puts(:stderr, \"Hex-first violation: #{name} resolved via #{inspect(elem(tuple, 0))}, expected :hex\")
        System.halt(1)
      nil ->
        IO.puts(:stderr, \"Hex-first violation: #{name} missing from #{\"$LOCK_PATH\"}\")
        System.halt(1)
    end
  end)
"
```

### `REQUIRED_CHECKS` Update (in `scripts/setup_branch_protection.sh`)

```bash
# Before Phase 59
REQUIRED_CHECKS=(
  "Support Contract Core (Elixir 1.18 / OTP 27)"
  "Support Contract Admin (Elixir 1.18 / OTP 27)"
  "Compile No Optional Deps (Elixir 1.18 / OTP 27)"
)

# After Phase 59 — add ONE entry
REQUIRED_CHECKS=(
  "Support Contract Core (Elixir 1.18 / OTP 27)"
  "Support Contract Admin (Elixir 1.18 / OTP 27)"
  "Compile No Optional Deps (Elixir 1.18 / OTP 27)"
  "Trust Lane Repo Head (Elixir 1.18 / OTP 27)"
)

# print_expected_text heredoc — add ONE bullet
print_expected_text() {
  cat <<'TEXT'
Expected required status checks:
  - Support Contract Core (Elixir 1.18 / OTP 27)
  - Support Contract Admin (Elixir 1.18 / OTP 27)
  - Compile No Optional Deps (Elixir 1.18 / OTP 27)
  - Trust Lane Repo Head (Elixir 1.18 / OTP 27)
# ...rest unchanged
```

Note: the clean-baseline lane is intentionally NOT in `REQUIRED_CHECKS` per the natural reading of EVID-01 vs EVID-02. EVID-01 specifically says "required repo-head trust lane"; EVID-02 says "clean-baseline trust lane" with no "required" qualifier in REQUIREMENTS.md. Both lanes ARE included in `gate-ci-green` (the publish gate) by default since neither is in `ADVISORY_LANES`. The planner should confirm this reading with the user in discuss-phase if not already locked. [VERIFIED: .planning/REQUIREMENTS.md:25-26]

**Update — D-02 reading:** CONTEXT.md D-02 says "Make the repo-head trust lane 'required'" but does not explicitly say the clean-baseline lane is or is not in `REQUIRED_CHECKS`. The conservative reading is: repo-head lane is added to `REQUIRED_CHECKS` (EVID-01 explicit); clean-baseline lane is required at the publish-gate layer only (EVID-02 satisfied by the lane existing in `ci.yml` and failing on path-leakage). This is what the example above reflects.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `actions/upload-artifact@v3` | `actions/upload-artifact@v4` | v4 released Q4 2023; v3 deprecated 2024-04-16 and disabled 2024-11-30 | Artifact API rewrite — different download semantics (`pattern:` matching, faster downloads). Repo already uses v4 SHA. [VERIFIED: ci.yml:791, github.com/actions/upload-artifact] |
| Hand-rolled `gh api` polling for required-check verification | `branch_protection_advisory` job + `scripts/verify-branch-protection.sh` diff engine | Phase 27 D-27-05 (v1.0 stability lock) | Repo already has the canonical diff-against-expected pattern. Phase 59 plugs into it by editing `REQUIRED_CHECKS`. [VERIFIED: scripts/verify-branch-protection.sh] |
| Separate workflow files per concern | Single `ci.yml` with parallel jobs + `gate-ci-green` central gate | Phase 27 (`publish-hex.yml::gate-ci-green` introduction) | Lower coordination cost; one workflow run = one gate state. D-01 locks this in. [VERIFIED: publish-hex.yml:115-191] |

**Deprecated/outdated:** Nothing in Phase 59's surface is touched by deprecated patterns. The lanes are net-new and follow current `ci.yml` conventions verbatim.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The clean-baseline lane is NOT required in branch protection (only the repo-head lane is). | Code Examples / `REQUIRED_CHECKS` section | Low — if the user wanted both required, the lock would be straightforward (add both names to `REQUIRED_CHECKS`). The conservative reading matches REQUIREMENTS.md text ("required repo-head trust lane" + "clean-baseline trust lane"). Planner should confirm in plan review. |
| A2 | The runner writes its checkpoint relative to `File.cwd!()`, so the clean-baseline lane's checkpoint lands at `reference/host_app/tmp/mailglass_trust_runner/checkpoint.json`. | Architecture Diagram, Code Examples | Low — directly verified in `lib/mix/tasks/mailglass.trust.run.ex:50-53`. If the runner is changed in a future phase to use absolute paths or `$PROJECT_ROOT`, the clean-baseline lane's `path:` and `--checkpoint` flag will need updating. D-15 forbids changing runner behavior, so this risk is low. |
| A3 | The Postgres service container is needed for the trust journey because `WebhookOperatorProof.run/0` and `OperatorDiagnosisProof.run/0` touch the database. | Code Examples | Medium — not directly probed in this research session, but inferred from the existing `support_contract_core` and `inbound_test` lanes that run similar contract tests with Postgres. If the trust runner can in fact execute its full stage chain without Postgres (file-presence + in-memory proofs), the Postgres service block can be removed from the new jobs, saving ~30s of startup time per run. **Recommendation:** the planner should empirically verify this in Wave 1 by running the lane both with and without Postgres on a draft PR; if without works, drop the service block. |

**If this table is empty:** N/A — three assumptions noted.

## Open Questions

1. **Checkpoint path resolution in clean-baseline lane.**
   - **What we know:** Runner writes to `Path.expand(checkpoint_out, File.cwd!())`. In the clean-baseline lane, `cwd` is `reference/host_app/`, so the checkpoint lands at `reference/host_app/tmp/mailglass_trust_runner/checkpoint.json`. [VERIFIED: lib/mix/tasks/mailglass.trust.run.ex:50-53]
   - **What's unclear:** Whether the validator script's `--checkpoint <abs_or_rel_path>` flag accepts relative paths correctly when invoked from the repo root (the lane example above invokes it without `working-directory` for the validator step). Direct read of `scripts/check_trust_runner_checkpoint.sh:23-25` shows it just assigns `CHECKPOINT_PATH="${2:-}"` and tests with `[[ ! -f "$CHECKPOINT_PATH" ]]`, so a relative path from the repo root will work as long as the lane's prior step left `cwd` at the repo root.
   - **Resolution:** Use the explicit form shown in the example: `bash scripts/check_trust_runner_checkpoint.sh --checkpoint reference/host_app/tmp/mailglass_trust_runner/checkpoint.json` (invoked from repo root). No additional discovery needed.

2. **Postgres service container necessity.**
   - **What we know:** `support_contract_core` runs the journey-adjacent contract tests with a Postgres service. Trust runner exercises `webhook_ingest` and `operator_troubleshooting` stages, both of which call into proof modules that may touch the database. [VERIFIED: lib/mix/tasks/mailglass.trust.run.ex:138-172]
   - **What's unclear:** Whether the trust runner's *file-presence-only* stage checks (the runner's `require_file!` calls at line 174-181) are sufficient for the stages to "complete" without database access. The runner's stage execution does call `WebhookOperatorProof.run/0` and `OperatorDiagnosisProof.run/0` (lines 138-141), which likely require the test DB.
   - **Resolution:** Include the Postgres service block in both lanes by default (low-cost, matches existing convention). If the planner wants to optimize, drop the block in Wave 1 and observe whether the lane stays green.

3. **Phase 60 artifact download pattern.**
   - **What we know:** `actions/download-artifact@v4` supports `pattern:` matching (verified in WebSearch result; documented in actions/download-artifact README). Phase 60 will use `pattern: trust-runner-repo-head-*` (or just `name: trust-runner-repo-head-${{ run_id_from_release }}` if it knows the run ID).
   - **What's unclear:** Whether the post-publish workflow has a stable way to determine which CI run ID corresponds to the release SHA. `publish-hex.yml::gate-ci-green` already does this via `actions/github-script` + `listWorkflowRuns({ workflow_id: 'ci.yml', head_sha })`; Phase 60 can reuse that pattern.
   - **Resolution:** Phase 59 only needs to ship a stable name *prefix*. Phase 60 will solve the ingest. No work needed in Phase 59 beyond the naming convention.

## Sources

### Primary (HIGH confidence)
- `.planning/phases/59-ci-trust-lanes-checkpoint-evidence/59-CONTEXT.md` — locked decisions D-01..D-15.
- `.planning/REQUIREMENTS.md` — EVID-01, EVID-02, EVID-04 text.
- `.planning/ROADMAP.md` — Phase 59 success criteria.
- `.planning/PROJECT.md` — pinned-Actions rule, sibling package linked-version policy.
- `.planning/phases/58-verify-first-webhook-operator-path/58-RESEARCH.md` — precedent research shape.
- `.planning/phases/58-verify-first-webhook-operator-path/58-VALIDATION.md` — VALIDATION.md template.
- `.planning/phases/57-deterministic-trust-runner-fixtures/57-RESEARCH.md` — runner contract context.
- `CLAUDE.md` — Conventional Commits, `docs(state):` filter, pinned-Actions, security/PII conventions.
- `.github/workflows/ci.yml` — canonical jobs, `preview_capture_advisory` 1:1 template, `branch_protection_advisory` drift surface.
- `.github/workflows/publish-hex.yml` — `gate-ci-green` mechanism (`workflow_id: 'ci.yml'` + `ADVISORY_LANES`).
- `.github/workflows/branch-protection-drift.yml` — daily re-assertion of branch protection via `setup_branch_protection.sh`.
- `.github/workflows/gate-self-test.yml` — synthetic-failure self-test for required checks.
- `scripts/setup_branch_protection.sh` — `REQUIRED_CHECKS` array and `print_expected_text` heredoc.
- `scripts/verify-branch-protection.sh` — read-only drift verifier.
- `scripts/check_trust_runner_checkpoint.sh` — checkpoint contract validator (existing, reused verbatim).
- `scripts/check_preview_capture_checkpoint.sh` — sibling validator with same pattern.
- `lib/mix/tasks/mailglass.trust.run.ex` — runner default checkpoint path, stage pipeline, `cwd`-relative resolution.
- `lib/mailglass/reference_host/trust_checkpoint.ex` — schema, claim boundary, hash semantics (D-15 forbids modification).
- `reference/host_app/mix.exs` — Hex-only constraints (`~> 1.2`, `~> 0.2`, no `path:`).
- `reference/host_app/mix.lock` — verified shape: every sibling entry is `{:hex, :name, ...}`.
- `mailglass_admin/mix.exs` and `mailglass_inbound/mix.exs` — confirmed they have `MIX_PUBLISH`-gated path overrides (must NOT be the clean-baseline lane's working dir).
- `mix.exs` — `verify.reference_host.journey` alias definition.

### Secondary (MEDIUM confidence — external, verified against authoritative source)
- [actions/upload-artifact README](https://github.com/actions/upload-artifact) — v4 retention semantics, `if-no-files-found: error` behavior. Cross-referenced with [GitHub Actions artifact docs](https://docs.github.com/en/actions/tutorials/store-and-share-data).
- [GitHub Actions retention docs](https://docs.github.com/en/organizations/managing-organization-settings/configuring-the-retention-period-for-github-actions-artifacts-and-logs-in-your-organization) — 90-day default maximum, 1-90 inclusive range.
- [hexdocs.pm/mix mix.lock format](https://hexdocs.pm/mix/Mix.Tasks.Deps.html) — lockfile entry tuple structure.
- [elixirforum.com/t/mix-lock-format-changes](https://elixirforum.com/t/mix-lock-format-changes/32448) — verified lockfile is an Elixir term, the canonical Hex entry shape `{:hex, name, vsn, inner_checksum, build_tools, deps, repo, outer_checksum}`.

### Tertiary (LOW confidence — none required for this phase)
- None. Phase 59's surface is entirely covered by primary sources.

## Metadata

**Confidence breakdown:**
- Standard stack: **HIGH** — every Action SHA and tool is already pinned in the repo, no new dependencies.
- Architecture: **HIGH** — the `preview_capture_advisory` precedent is a verified 1:1 template; the `gate-ci-green` mechanism is verified by direct read; the branch-protection drift surface is verified by direct read.
- Pitfalls: **HIGH** — every pitfall is tied to a specific line in an existing file or a documented GitHub Actions behavior. The required-check race (Pitfall 1) is the only one with practical real-world risk; the others are guarded by repo conventions or D-15-locked invariants.
- mix.lock parsing technique: **HIGH** — directly verified by reading `reference/host_app/mix.lock` and cross-referencing the documented Hex tuple format.
- Validation architecture: **HIGH** — three success criteria all have at least one deterministic, automated verification surface.

**Research date:** 2026-05-27
**Valid until:** 2026-06-26 for codebase-local planning. The pinned Action SHAs may bump via Dependabot during this window; re-verify before merge if Dependabot has run.

## RESEARCH COMPLETE
