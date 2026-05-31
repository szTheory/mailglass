# Phase 62: Close gap: EVID-02/EVID-03 — current-release trust proof - Pattern Map

**Mapped:** 2026-05-31  
**Files analyzed:** 7  
**Analogs found:** 7 / 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `reference/host_app/mix.exs` | config | request-response | `reference/host_app/mix.exs` | exact |
| `reference/host_app/mix.lock` | config | transform | `reference/host_app/mix.lock` | exact |
| `scripts/check_clean_baseline_hex_only.sh` | utility | transform | `scripts/check_clean_baseline_hex_only.sh` | exact |
| `test/mailglass/publish/ci_trust_lane_contract_test.exs` | test | request-response | `test/mailglass/publish/ci_trust_lane_contract_test.exs` | exact |
| `test/mailglass/publish/post_publish_smoke_contract_test.exs` | test | request-response | `test/mailglass/publish/post_publish_smoke_contract_test.exs` | exact |
| `.github/workflows/ci.yml` | config | event-driven | `.github/workflows/ci.yml` (`trust_lane_clean_baseline`) | exact |
| `.github/workflows/post-publish-smoke.yml` | config | event-driven | `.github/workflows/post-publish-smoke.yml` (`published-trust-journey`) | exact |

## Pattern Assignments

### `reference/host_app/mix.exs` (config, request-response)

**Analog:** `reference/host_app/mix.exs`

**Dependency declaration pattern** (lines 24-35):
```elixir
defp deps do
  [
    {:phoenix, "~> 1.8"},
    {:phoenix_ecto, "~> 4.6"},
    {:ecto_sql, "~> 3.13"},
    {:postgrex, "~> 0.22"},
    {:jason, "~> 1.4"},
    {:plug_cowboy, "~> 2.7"},
    {:mailglass, "~> 1.2"},
    {:mailglass_admin, "~> 1.2"},
    {:mailglass_inbound, "~> 0.2"}
  ]
end
```

**Assignment:** keep shape/order; only bump sibling constraints in-place.

---

### `reference/host_app/mix.lock` (config, transform)

**Analog:** `reference/host_app/mix.lock`

**Hex tuple lock-entry pattern** (lines 20-22):
```elixir
"mailglass": {:hex, :mailglass, "1.2.0", ...},
"mailglass_admin": {:hex, :mailglass_admin, "1.2.0", ...},
"mailglass_inbound": {:hex, :mailglass_inbound, "0.2.0", ...},
```

**Assignment:** preserve tuple structure and source atom `:hex`; update only versions/resolver-required churn.

---

### `scripts/check_clean_baseline_hex_only.sh` (utility, transform)

**Analog:** `scripts/check_clean_baseline_hex_only.sh`

**Shell guard + lock parse pattern** (lines 5-20):
```bash
set -euo pipefail

LOCK_PATH="${1:-mix.lock}"

if [[ ! -s "$LOCK_PATH" ]]; then
  echo "Clean-baseline Hex-first check blocked: missing or empty $LOCK_PATH" >&2
  exit 1
fi

MAILGLASS_LOCK_PATH="$LOCK_PATH" elixir -e '
  lock_path = System.fetch_env!("MAILGLASS_LOCK_PATH")
  lock = File.read!(lock_path) |> Code.eval_string() |> elem(0)
```

**Core assertion loop pattern** (lines 21-38):
```elixir
required = [
  {"mailglass", :hex},
  {"mailglass_admin", :hex},
  {"mailglass_inbound", :hex}
]

Enum.each(required, fn {name, expected_source} ->
  case Map.get(lock, String.to_atom(name)) do
    tuple when is_tuple(tuple) and elem(tuple, 0) == expected_source ->
      IO.puts("Hex-first OK: #{name} resolved via :hex (version: #{elem(tuple, 2)})")
    tuple when is_tuple(tuple) ->
      IO.puts(:stderr, "Hex-first violation: #{name} resolved via #{inspect(elem(tuple, 0))}, expected :hex")
      System.halt(1)
    nil ->
      IO.puts(:stderr, "Hex-first violation: #{name} missing from #{lock_path}")
      System.halt(1)
  end
end)
```

**Error handling pattern analog:** `scripts/check_trust_runner_checkpoint.sh` lines 21-41 (unknown option/missing file hard fail).

---

### `test/mailglass/publish/ci_trust_lane_contract_test.exs` (test, request-response)

**Analog:** `test/mailglass/publish/ci_trust_lane_contract_test.exs`

**Workflow contract test structure** (lines 1-18):
```elixir
defmodule Mailglass.Publish.CITrustLaneContractTest do
  use ExUnit.Case, async: true

  @workflow_path Path.expand("../../../.github/workflows/ci.yml", __DIR__)

  test "clean-baseline trust lane remains publish-gate-only and verifies Hex-sourced host" do
    workflow = File.read!(@workflow_path)
    job = extract_job!(workflow, "trust_lane_clean_baseline", "branch_protection_advisory")

    assert job =~ "working-directory: reference/host_app"
    assert job =~ "run: bash ../../scripts/check_clean_baseline_hex_only.sh"
    assert job =~ "run: mix verify.reference_host.journey --host-root reference/host_app"
```

**Segment extraction helper pattern** (lines 24-28):
```elixir
defp extract_job!(workflow, start_key, next_key) do
  [_before, rest] = String.split(workflow, "\n  #{start_key}:\n", parts: 2)
  [job | _after] = String.split(rest, "\n  #{next_key}:\n", parts: 2)
  job
end
```

---

### `test/mailglass/publish/post_publish_smoke_contract_test.exs` (test, request-response)

**Analog:** `test/mailglass/publish/post_publish_smoke_contract_test.exs`

**Published journey contract assertions** (lines 6-22):
```elixir
test "published trust journey runs full reference-host proof and uploads checkpoint" do
  workflow = File.read!(@workflow_path)
  job = extract_job!(workflow, "published-trust-journey", "retracted-check")

  assert job =~ "needs: [cron-guard, consumer-install]"
  assert job =~ "working-directory: reference/host_app"
  assert job =~ "run: bash ../../scripts/check_clean_baseline_hex_only.sh"
  assert job =~ "run: mix verify.reference_host.journey --host-root reference/host_app"
  assert job =~ "run: bash scripts/check_trust_runner_checkpoint.sh"
end
```

**Ordering assertion pattern** (lines 37-41, 76-80):
```elixir
assert index_of(consumer_install, "Run mix mailglass.install") <
         index_of(consumer_install, "Guard against hackney/api_client regression on published install")

defp index_of(text, needle) do
  case :binary.match(text, needle) do
    {index, _length} -> index
    :nomatch -> flunk("missing expected text: #{needle}")
  end
end
```

---

### `.github/workflows/ci.yml` (config, event-driven)

**Analog:** `.github/workflows/ci.yml` (`trust_lane_clean_baseline`)

**Trust lane job pattern** (lines 880-950):
```yaml
trust_lane_clean_baseline:
  name: Trust Lane Clean Baseline (Elixir 1.18 / OTP 27)
  runs-on: ubuntu-latest
  env:
    MIX_ENV: test
  steps:
    - name: Build reference host (dev) so the journey can load sibling beams
      working-directory: reference/host_app
      env:
        MIX_ENV: dev
      run: mix deps.get && mix compile
    - name: Assert clean Hex-first baseline
      working-directory: reference/host_app
      run: bash ../../scripts/check_clean_baseline_hex_only.sh
    - name: Run reference-host trust journey
      run: mix verify.reference_host.journey --host-root reference/host_app
    - name: Validate trust checkpoint contract
      run: bash scripts/check_trust_runner_checkpoint.sh
```

**Artifact upload pattern** (lines 944-950): pinned `upload-artifact`, `if-no-files-found: error`, `retention-days: 90`, checkpoint path.

---

### `.github/workflows/post-publish-smoke.yml` (config, event-driven)

**Analog:** `.github/workflows/post-publish-smoke.yml` (`published-trust-journey`)

**Published trust job pattern** (lines 461-529):
```yaml
published-trust-journey:
  name: Published-version trust journey
  runs-on: ubuntu-latest
  needs: [cron-guard, consumer-install]
  if: ${{ needs.cron-guard.outputs.should_run == 'true' }}
  timeout-minutes: 20
  steps:
    - name: Checkout release ref
      with:
        ref: ${{ needs.cron-guard.outputs.release_ref }}
    - name: Guard reference host resolves siblings from Hex
      working-directory: reference/host_app
      run: bash ../../scripts/check_clean_baseline_hex_only.sh
    - name: Run published reference-host trust journey
      run: mix verify.reference_host.journey --host-root reference/host_app
    - name: Validate trust checkpoint contract
      run: bash scripts/check_trust_runner_checkpoint.sh
```

## Shared Patterns

### Script guard behavior
**Source:** `scripts/check_clean_baseline_hex_only.sh` lines 5-12, 27-37  
**Apply to:** Hex-baseline guard updates
```bash
set -euo pipefail
...
echo "... blocked: ..." >&2
exit 1
...
IO.puts(:stderr, "... violation ...")
System.halt(1)
```

### Workflow contract testing
**Source:** `test/mailglass/publish/ci_trust_lane_contract_test.exs` lines 24-28 and `test/mailglass/publish/post_publish_smoke_contract_test.exs` lines 70-74  
**Apply to:** both publish-lane contract tests
```elixir
[_before, rest] = String.split(workflow, "\n  #{start_key}:\n", parts: 2)
[job | _after] = String.split(rest, "\n  #{next_key}:\n", parts: 2)
```

### Trust journey command contract
**Source:** `.github/workflows/ci.yml` lines 936-938 and `.github/workflows/post-publish-smoke.yml` lines 520-522  
**Apply to:** CI + post-publish lanes
```yaml
run: mix verify.reference_host.journey --host-root reference/host_app
run: bash scripts/check_trust_runner_checkpoint.sh
```

### Scope-token contract style
**Source:** `test/reference_host/scope_lock_contract_test.exs` lines 10-29, 44-50  
**Apply to:** any new tokenized string contract for guard/version drift
```elixir
Enum.each(required_tokens, fn token ->
  assert String.contains?(scope, token), "..."
end)
```

## No Analog Found

None.

## Metadata

**Analog search scope:** `reference/`, `scripts/`, `test/`, `.github/workflows/`  
**Files scanned:** 11  
**Pattern extraction date:** 2026-05-31
