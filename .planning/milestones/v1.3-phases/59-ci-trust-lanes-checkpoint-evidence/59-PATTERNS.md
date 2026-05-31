# Phase 59: ci-trust-lanes-checkpoint-evidence — Pattern Map

**Mapped:** 2026-05-27
**Files analyzed:** 5 (3 modified, 2 created)
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.github/workflows/ci.yml` *(modified — add 2 jobs)* | config (CI workflow) | event-driven (push/PR trigger) | `preview_capture_advisory` job in same file (`ci.yml:676-808`) | exact (1:1 "runner → validator → upload-artifact" template) |
| `scripts/setup_branch_protection.sh` *(modified — add 1 entry + 1 line)* | config (branch-protection source of truth) | request-response (idempotent `gh api PUT`) | self (lines 17-21 `REQUIRED_CHECKS`, lines 23-42 `print_expected_text`) | exact (additive in-place pattern) |
| `.github/workflows/gate-self-test.yml` *(modified — add `check_name` input + name filter)* | config (CI self-test workflow) | event-driven (workflow_dispatch) | self (lines 13-19 `workflow_dispatch.inputs`, lines 117-141 poll loop with `startswith("Tests (")`) | exact (parameterize an existing literal) |
| `scripts/check_clean_baseline_hex_only.sh` *(new)* | utility (bash + inline `elixir -e`) | batch (one-shot validator: read, assert, exit) | `scripts/check_trust_runner_checkpoint.sh` (existing exec validator) | role-match (same wrapper shape: shebang + `set -euo pipefail` + arg parsing + heredoc-embedded interpreter + exit codes) |
| `test/scripts/required_checks_test.exs` *(new)* | test (ExUnit contract test) | request-response (file read + assertion) | `test/reference_host/trust_runner_command_contract_test.exs` (existing pinned-tokens contract test) | role-match (file-content contract test in ExUnit) |

## Pattern Assignments

### `.github/workflows/ci.yml` — add `trust_lane_repo_head` and `trust_lane_clean_baseline` jobs

**Analog:** `.github/workflows/ci.yml::preview_capture_advisory` (lines 676-808)

**Job header pattern** (lines 676-705 — copy verbatim except `name:`, drop Node, drop `PREVIEW_CAPTURE_ROOT`):
```yaml
preview_capture_advisory:
  name: Preview Capture Advisory (Elixir 1.18 / OTP 27 / Node 22)
  runs-on: ubuntu-latest
  strategy:
    matrix:
      include:
        - elixir: "1.18"
          otp: "27"
          node: "22"
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
```

**Pinned-Action checkout + setup-beam pattern** (lines 706-713 — copy verbatim, including SHA comments):
```yaml
steps:
  - name: Checkout
    uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd  # v6.0.2
  - name: Set up OTP + Elixir
    uses: erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93  # v1.24.0
    with:
      elixir-version: ${{ matrix.elixir }}
      otp-version: ${{ matrix.otp }}
```

**Cache pattern — repo-head lane** (adapted from `compile_no_optional_deps` lines 101-107 which is the simpler single-path form):
```yaml
- name: Cache deps
  uses: actions/cache@27d5ce7f107fe9357f9df03efb73ab90386fccae  # v5.0.5
  with:
    path: deps
    key: ${{ runner.os }}-mix-${{ hashFiles('**/mix.lock') }}
    restore-keys: |
      ${{ runner.os }}-mix-
```

**Cache pattern — clean-baseline lane** (D-09 requires distinct key prefix; see RESEARCH Pattern 4):
```yaml
- name: Cache reference-host deps
  uses: actions/cache@27d5ce7f107fe9357f9df03efb73ab90386fccae  # v5.0.5
  with:
    path: reference/host_app/deps
    key: ${{ runner.os }}-mix-reference-host-${{ hashFiles('reference/host_app/mix.lock') }}
    restore-keys: |
      ${{ runner.os }}-mix-reference-host-
```

**Validator-then-upload pattern** (lines 784-799 — the 1:1 EVID-04 template):
```yaml
- name: Validate preview capture checkpoint contract
  run: |
    bash scripts/check_preview_capture_checkpoint.sh \
      --manifest "${{ env.PREVIEW_CAPTURE_ROOT }}/manifest.json" \
      --checkpoint "${{ env.PREVIEW_CAPTURE_ROOT }}/checkpoint.json" \
      --screenshots-dir "${{ env.PREVIEW_CAPTURE_ROOT }}/screenshots"
- name: Upload preview capture advisory artifact
  uses: actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02  # v4
  with:
    name: preview-capture-advisory-${{ github.run_id }}
    if-no-files-found: error
    retention-days: 14
    path: |
      ${{ env.PREVIEW_CAPTURE_ROOT }}/screenshots
      ${{ env.PREVIEW_CAPTURE_ROOT }}/manifest.json
      ${{ env.PREVIEW_CAPTURE_ROOT }}/checkpoint.json
```

**Substitutions for the two new lanes** (per D-04..D-15):
- `mix mailglass_admin.preview.capture …` → `mix verify.reference_host.journey` (no flags — keep runner default checkpoint path per D-06)
- `bash scripts/check_preview_capture_checkpoint.sh …` → `bash scripts/check_trust_runner_checkpoint.sh` (repo-head: no `--checkpoint` flag, default path; clean-baseline: `--checkpoint reference/host_app/tmp/mailglass_trust_runner/checkpoint.json`)
- Artifact `name:` → `trust-runner-repo-head-${{ github.run_id }}` and `trust-runner-clean-baseline-${{ github.run_id }}` (D-13)
- Artifact `retention-days:` → **`90`** (D-14, not `14`)
- Artifact `path:` → single exact file (no directory; Pitfall 6): `tmp/mailglass_trust_runner/checkpoint.json` for repo-head, `reference/host_app/tmp/mailglass_trust_runner/checkpoint.json` for clean-baseline
- Keep the **exact same pinned upload-artifact SHA** `ea165f8d65b6e75b540449e92b4886f43607fa02` (D-11)
- Keep `if-no-files-found: error` (D-12)
- Job names use literal strings (Anti-pattern in RESEARCH): `Trust Lane Repo Head (Elixir 1.18 / OTP 27)`, `Trust Lane Clean Baseline (Elixir 1.18 / OTP 27)`

**Discretionary "human-glance hash" step** (recommended in CONTEXT Discretion §3; pattern lifted from `$GITHUB_STEP_SUMMARY` usage in `branch_protection_advisory` lines 822-829 + RESEARCH Code Examples lines 603-607):
```yaml
- name: Print checkpoint SHA for human-glance evidence
  run: |
    echo "## Trust Runner Checkpoint (repo head)" >> "$GITHUB_STEP_SUMMARY"
    jq -r '"- schema_version: \(.schema_version)\n- claim_boundary: \(.claim_boundary)\n- checkpoint_count: \(.checkpoint_count)\n- checkpoint_sha256: \(.checkpoint_sha256)"' \
      tmp/mailglass_trust_runner/checkpoint.json >> "$GITHUB_STEP_SUMMARY"
```

**Anti-patterns to avoid** (all verified in RESEARCH):
- No `if:` condition on either new job (Pitfall 2: `gate-ci-green` treats `skipped` as non-blocking)
- No `${{ }}`-interpolated job `name:` (Anti-pattern: branch protection matches the literal string)
- No alternative upload-artifact SHA (Anti-pattern: keep Dependabot surface at one SHA)
- No directory-level `path:` on upload-artifact (Pitfall 6: specify the exact `checkpoint.json` file)

---

### `scripts/setup_branch_protection.sh` — add 1 entry to `REQUIRED_CHECKS` + mirror line in `print_expected_text`

**Analog:** self (the file is its own pattern — the entire edit is additive)

**Current `REQUIRED_CHECKS` block** (lines 17-21 — append exactly one line):
```bash
REQUIRED_CHECKS=(
  "Support Contract Core (Elixir 1.18 / OTP 27)"
  "Support Contract Admin (Elixir 1.18 / OTP 27)"
  "Compile No Optional Deps (Elixir 1.18 / OTP 27)"
)
```

**Current `print_expected_text` heredoc** (lines 23-42 — append exactly one bullet under the existing list, before the blank line and the "Expected non-context branch protection fields:" header):
```bash
print_expected_text() {
  cat <<'TEXT'
Expected required status checks:
  - Support Contract Core (Elixir 1.18 / OTP 27)
  - Support Contract Admin (Elixir 1.18 / OTP 27)
  - Compile No Optional Deps (Elixir 1.18 / OTP 27)

Expected non-context branch protection fields:
  ...
TEXT
}
```

**Post-Phase 59 shape — add the repo-head lane only** (D-02 + RESEARCH §A1: only the repo-head lane is in `REQUIRED_CHECKS`; the clean-baseline lane is required at the `gate-ci-green` publish-gate layer only):
```bash
REQUIRED_CHECKS=(
  "Support Contract Core (Elixir 1.18 / OTP 27)"
  "Support Contract Admin (Elixir 1.18 / OTP 27)"
  "Compile No Optional Deps (Elixir 1.18 / OTP 27)"
  "Trust Lane Repo Head (Elixir 1.18 / OTP 27)"
)
```
And the matching bullet in `print_expected_text`:
```
  - Trust Lane Repo Head (Elixir 1.18 / OTP 27)
```

**Critical:** the two strings MUST be byte-identical to the `name:` value of the `trust_lane_repo_head` job in `ci.yml`. The expected JSON downstream (`expected_json()` lines 44-65) reads the array, so any drift between job-name and array-entry silently passes the `branch_protection_advisory` drift check but fails the actual branch-protection lookup.

---

### `.github/workflows/gate-self-test.yml` — parameterize `check_name` (Wave 0 gap)

**Analog:** self (lines 13-19 `inputs:`, lines 117-141 poll loop)

**Existing input pattern** (lines 13-19):
```yaml
on:
  workflow_dispatch:
    inputs:
      cleanup_only:
        description: "Only clean up stale gate-self-test branches/PRs (no new run)"
        type: boolean
        default: false
```

**Existing poll loop with hardcoded `Tests (` prefix** (lines 117-141 — the literal that needs parameterization):
```bash
DEADLINE=$((SECONDS + 1500))
while [ $SECONDS -lt $DEADLINE ]; do
  STATUS=$(gh pr checks "$PR" --required --json name,state \
    --jq '.[] | select(.name | startswith("Tests (")) | .state' \
    | head -1)
  case "$STATUS" in
    FAILURE|FAILED|CANCELLED|TIMED_OUT)
      echo "Tests check returned ${STATUS} — gate is enforcing halt-on-failure"
      echo "result=blocked" >> "$GITHUB_OUTPUT"
      exit 0
      ;;
    SUCCESS)
      echo "ERROR: Tests check returned SUCCESS on a synthetic-failure PR"
      ...
```

**Pattern to apply** (extend, do not rewrite):
1. Add a new input under the existing `cleanup_only` input, following the same `description:` / `type:` / `default:` shape:
   ```yaml
   check_name:
     description: "Required-check name prefix to poll (e.g., 'Tests (' or 'Trust Lane Repo Head (')"
     type: string
     default: "Tests ("
   ```
2. In the poll loop's `--jq` selector, replace the literal `"Tests ("` with `"${{ inputs.check_name }}"` (inside the bash heredoc; shell-quoting must be preserved). Update the surrounding `echo` strings to reference `${{ inputs.check_name }}` in place of the literal `"Tests check"`.
3. The synthetic-failure injection (`test/gate_self_test/intentional_failure_test.exs`, lines 73-86) **stays as-is** — an `assert false` test reliably fails every required lane that runs ExUnit, including the trust-runner journey lane (which calls `mix verify.reference_host.journey` → eventually exercises ExUnit-backed proofs). No new fixture needed.

**Anti-pattern to avoid:** do not split the workflow into a second self-test workflow. The existing one is parameterizable in <10 lines of diff.

---

### `scripts/check_clean_baseline_hex_only.sh` — new bash + inline `elixir -e` validator

**Analog:** `scripts/check_trust_runner_checkpoint.sh` (existing executable validator)

**Shebang + safety pragmas pattern** (lines 1-4 of the analog):
```bash
#!/usr/bin/env bash
# Validate deterministic trust-runner checkpoint contract artifacts.

set -euo pipefail
```

**Default-with-override + arg-parse pattern** (lines 6-37 of the analog):
```bash
CHECKPOINT_PATH="tmp/mailglass_trust_runner/checkpoint.json"

usage() {
  cat <<'EOF'
Usage: check_trust_runner_checkpoint.sh [options]
...
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --checkpoint)
      CHECKPOINT_PATH="${2:-}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Trust runner checkpoint validation blocked: unknown option '$1'" >&2
      usage >&2
      exit 1
      ;;
  esac
done
```

**Missing-file guard pattern** (lines 39-42 of the analog — this is the Pitfall 3 mitigation):
```bash
if [[ ! -f "$CHECKPOINT_PATH" ]]; then
  echo "Trust runner checkpoint validation blocked: missing checkpoint at '$CHECKPOINT_PATH'" >&2
  exit 1
fi
```

**Heredoc-embedded interpreter pattern** (lines 44-230 of the analog — note `python3 - "$ARG" <<'PY' … PY`; new script uses `elixir -e "..."` instead):
```bash
python3 - "$CHECKPOINT_PATH" <<'PY'
import hashlib
import json
...
PY
```

**Failure-message convention** (lines 32-33, 40 of the analog): every error message starts with the script's purpose noun + `"blocked: <specific reason>"` and writes to `stderr` (`>&2`). New script follows: `"Clean-baseline Hex-first check blocked: …"` (matches RESEARCH Code Examples line 709).

**New-script shape to write** (RESEARCH §"Hex-First Source Script" lines 700-735 is the authoritative form; copy verbatim with these pieces from the analog locked in):
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
        IO.puts(:stderr, \"Hex-first violation: #{name} missing from $LOCK_PATH\")
        System.halt(1)
    end
  end)
"
```

**File-mode contract:** must be created with `chmod +x` to match all other `scripts/*.sh` (verified `ls -la /Users/jon/projects/mailglass/scripts/`: all `.sh` files are `-rwxr-xr-x`).

---

### `test/scripts/required_checks_test.exs` — new ExUnit contract test

**Analog:** `test/reference_host/trust_runner_command_contract_test.exs` (existing pinned-tokens contract test)

**Module + use pattern** (lines 1-2 of the analog):
```elixir
defmodule Mailglass.ReferenceHost.TrustRunnerCommandContractTest do
  use ExUnit.Case, async: true
```

**Path-as-module-attr pattern** (lines 4-7 of the analog — uses `Path.expand("../../...", __DIR__)` for paths relative to the test file):
```elixir
@mix_path Path.expand("../../mix.exs", __DIR__)
@task_path Path.expand("../../lib/mix/tasks/mailglass.trust.run.ex", __DIR__)
@readme_path Path.expand("../../reference/host_app/README.md", __DIR__)
@claim_boundary "reference-host trust-journey confidence only; signed Postmark webhook verification and no-match operator diagnosis proven by deterministic runner evidence"
```

**Token-presence contract test pattern** (lines 9-29 of the analog — read file once, then `Enum.each` over expected tokens with descriptive assertion messages):
```elixir
test "JOUR-01 canonical command and deterministic stages are pinned" do
  files_with_content = [
    {@mix_path, File.read!(@mix_path)},
    {@task_path, File.read!(@task_path)}
  ]

  required_tokens = [
    "verify.reference_host.journey",
    "mailglass.trust.run",
    "install",
    ...
  ]

  Enum.each(required_tokens, fn token ->
    assert token_present?(files_with_content, token),
           "JOUR-01 command drift: required token missing #{inspect(token)}"
  end)
end
```

**Helper-fn-at-bottom pattern** (lines 52-54 of the analog):
```elixir
defp token_present?(files_with_content, token) do
  Enum.any?(files_with_content, fn {_path, content} -> String.contains?(content, token) end)
end
```

**Apply to new test:**
- Module name: `Mailglass.Scripts.RequiredChecksTest` (or `Mailglass.Scripts.SetupBranchProtectionTest` — match the existing `Mailglass.ReferenceHost.<Thing>ContractTest` naming convention)
- `use ExUnit.Case, async: true` (no DB)
- `@script_path Path.expand("../../scripts/setup_branch_protection.sh", __DIR__)`
- Two tests:
  1. `"REQUIRED_CHECKS contains the locked v1.3 lane names"` — asserts the array contains `"Support Contract Core (Elixir 1.18 / OTP 27)"`, `"Support Contract Admin (Elixir 1.18 / OTP 27)"`, `"Compile No Optional Deps (Elixir 1.18 / OTP 27)"`, and `"Trust Lane Repo Head (Elixir 1.18 / OTP 27)"`.
  2. `"print_expected_text mirrors REQUIRED_CHECKS"` — asserts that for every name in `REQUIRED_CHECKS`, a `  - <name>` bullet appears in the `print_expected_text` heredoc (catches the drift where someone updates the array but forgets the heredoc).
- Implementation choice: read the file content once and use `String.contains?/2` over expected tokens — same pattern as the analog. (Alternative: shell out to `bash scripts/setup_branch_protection.sh --print-expected` and diff. The simpler content-match form matches the analog's posture.)
- **Test location:** create `test/scripts/` directory. There is currently no `test/scripts/` directory in the repo (verified `find /Users/jon/projects/mailglass/test -type d -maxdepth 2`), but `test/reference_host/`, `test/credo_checks/`, `test/example/`, `test/mix/`, `test/mailglass/`, `test/support/` all exist as siblings — adding `test/scripts/` follows the convention of one directory per logical surface.

---

## Shared Patterns

### Pinned-Action SHA reuse (CLAUDE.md "Things Not To Do" + D-11)
**Source:** `.github/workflows/ci.yml` lines 707, 710, 791 (canonical SHAs)
**Apply to:** both new `ci.yml` jobs
```yaml
actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd      # v6.0.2
erlef/setup-beam@fc68ffb90438ef2936bbb3251622353b3dcb2f93      # v1.24.0
actions/cache@27d5ce7f107fe9357f9df03efb73ab90386fccae         # v5.0.5
actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02  # v4
```
**Do not introduce a new SHA** — Dependabot bumps one place for all jobs.

### `set -euo pipefail` + stderr-only error output (shell scripts)
**Source:** `scripts/check_trust_runner_checkpoint.sh:4`, `scripts/setup_branch_protection.sh:9`
**Apply to:** new `scripts/check_clean_baseline_hex_only.sh`
```bash
#!/usr/bin/env bash
set -euo pipefail
```
All failure messages go to `>&2`. All success messages go to stdout.

### `Path.expand("../../<repo-relative>", __DIR__)` for test-file file refs
**Source:** `test/reference_host/trust_runner_command_contract_test.exs:4-7`, `test/reference_host/trust_runner_checkpoint_contract_test.exs:7`
**Apply to:** new `test/scripts/required_checks_test.exs`
```elixir
@script_path Path.expand("../../scripts/setup_branch_protection.sh", __DIR__)
```

### Required-lane job-name convention: `Title Case (Elixir 1.18 / OTP 27)`
**Source:** `scripts/setup_branch_protection.sh:17-21` (3 entries), `.github/workflows/ci.yml::compile_no_optional_deps name:` (line 86), `::hex_audit name:` (line 461)
**Apply to:** the two new `ci.yml` job `name:` values and the new `REQUIRED_CHECKS` entry
- `Trust Lane Repo Head (Elixir 1.18 / OTP 27)`
- `Trust Lane Clean Baseline (Elixir 1.18 / OTP 27)`

The repo-head string is byte-identical across `ci.yml::trust_lane_repo_head.name`, `setup_branch_protection.sh::REQUIRED_CHECKS`, and the `print_expected_text` bullet.

### `$GITHUB_STEP_SUMMARY` append for human-glance evidence
**Source:** `.github/workflows/ci.yml::branch_protection_advisory` lines 822-829, `lines 846-858`
**Apply to:** the optional checkpoint-hash echo step in both new lanes
```yaml
- name: ...
  run: |
    {
      echo "## ..."
      echo ""
      echo "- ..."
    } >> "$GITHUB_STEP_SUMMARY"
```

### Conventional-commit prefix `ci(...)` for `ci.yml` + `scripts/setup_branch_protection.sh` edits
**Source:** CLAUDE.md "Commit & Branch Conventions"; `.github/workflows/pr-title.yml` enforces.
**Apply to:** the Wave 1 commit that lands all three modified files atomically (D-02 + Pitfall 1: must be a single commit).

---

## No Analog Found

None. Every Phase 59 surface has a strong existing analog (rated as "exact" or "role-match"). The clean-baseline lane's `elixir -e` snippet is novel content but its **wrapper** (`bash` shebang + `set -euo pipefail` + arg parse + heredoc-embedded interpreter + exit codes) maps 1:1 to `scripts/check_trust_runner_checkpoint.sh`.

---

## Metadata

**Analog search scope:**
- `.github/workflows/` — every workflow file inspected; `ci.yml` (859 lines) is the primary template, `gate-self-test.yml` (170 lines) self-parameterizes
- `scripts/` — 8 shell scripts inspected; `check_trust_runner_checkpoint.sh` and `setup_branch_protection.sh` are the canonical analogs
- `test/reference_host/` — pinned-tokens / pinned-content contract tests already established as repo convention
- `test/scripts/` — does not exist; new directory follows the existing one-dir-per-surface convention

**Files scanned:** 7 (full reads or targeted Read+offset) — `ci.yml`, `setup_branch_protection.sh`, `gate-self-test.yml`, `check_trust_runner_checkpoint.sh`, `trust_runner_command_contract_test.exs`, `trust_runner_checkpoint_contract_test.exs`, plus shell directory listing.

**Pattern extraction date:** 2026-05-27
