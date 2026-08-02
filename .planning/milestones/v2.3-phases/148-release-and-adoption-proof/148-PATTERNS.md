# Phase 148: Release and Adoption Proof - Pattern Map

**Mapped:** 2026-08-01  
**Files analyzed:** 6 expected modifications (four workflow/config files and two contract tests)  
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.github/workflows/publish-hex.yml` | config / release workflow | event-driven | its existing `publish-core` / `publish-admin` / `publish-inbound` job graph | exact |
| `.github/workflows/release-please.yml` | config / release workflow | event-driven / transform | its existing sibling-pin sync step | exact |
| `.github/workflows/post-publish-smoke.yml` | config / published E2E workflow | event-driven / request-response | its existing `consumer-install` and evidence jobs | exact |
| `test/scripts/linked_release_concurrency_test.exs` | test / workflow contract | transform | its existing publish-job block extractor and static-concurrency checks | exact |
| `test/mailglass/publish/post_publish_smoke_contract_test.exs` | test / workflow contract | transform | its existing `consumer-install` job assertions | exact |
| `.github/workflows/ci.yml` | config / CI proof-bundle workflow | event-driven / batch | `installer_host_smoke` calling the shared consumer harness | role-match |

Existing canonical evidence is exercised, not rewritten: `test/mailglass/webhook/ingest_auto_suppress_test.exs`, `test/mailglass/suppression_test.exs`, `test/mailglass/docs_contract_test.exs`, and `mailglass_admin/test/mailglass_admin/operator_live_test.exs`. `scripts/consumer_install_smoke.sh` is also reused unchanged.

## Pattern Assignments

### `.github/workflows/publish-hex.yml` (config/release workflow, event-driven)

**Analog:** `.github/workflows/publish-hex.yml` existing core/admin/inbound publication graph.

**Trigger and protected-publication pattern** (lines 3-61):

```yaml
on:
  release:
    types: [published]
  workflow_dispatch:
    inputs:
      tag:
        required: true
      package:
        type: choice
        options: [mailglass, mailglass_admin, mailglass_inbound, all]

concurrency:
  group: mailglass-linked-release-fanout
  cancel-in-progress: false
```

Keep the release event as the canonical path, retain manual package selection for recovery, and leave the static non-cancelling group intact. Publication jobs retain `environment: hex-publish` and place `HEX_API_KEY` only on the actual publish step (lines 715-763 and 779-883).

**Core publish predicate** (lines 715-723):

```yaml
publish-core:
  needs: [gate-ci-green]
  if: |
    github.event_name == 'release' ||
    (github.event_name == 'workflow_dispatch' &&
     github.event.inputs.package != 'mailglass_admin' &&
     github.event.inputs.package != 'mailglass_inbound')
```

Release events should select the linked core/admin branch only. Make prepublish predicates equally event-aware: the current inbound prepublish condition at lines 130-135 tests only dispatch inputs and would run on release events because those inputs are empty.

**Dependent-job guard pattern** (lines 779-803):

```yaml
publish-admin:
  needs: [gate-ci-green, publish-core, publish-inbound]
  if: |
    always() &&
    (
      (github.event_name == 'workflow_dispatch' &&
       github.event.inputs.package == 'mailglass_admin' &&
       needs.gate-ci-green.result == 'success' &&
       needs.publish-core.result == 'skipped' &&
       needs.publish-inbound.result == 'skipped') ||
      (github.event_name == 'release' &&
       needs.publish-inbound.result == 'success')
    )
```

Adapt this exact guarded style, but remove inbound from the core/admin release dependency path: admin should depend on `gate-ci-green` and successful `publish-core`, while inbound is eligible only for explicit `workflow_dispatch` package choices. Preserve `always()` plus explicit prerequisite result checks so a failed gate cannot expose a publish environment.

**Inbound manual-only branch to preserve** (lines 885-906):

```yaml
publish-inbound:
  needs: [publish-core]
  if: |
    always() &&
    (
      (github.event_name == 'workflow_dispatch' &&
       github.event.inputs.package == 'mailglass_inbound' &&
       needs.publish-core.result == 'skipped') ||
      (github.event_name == 'workflow_dispatch' &&
       github.event.inputs.package != 'mailglass' &&
       github.event.inputs.package != 'mailglass_admin' &&
       needs.publish-core.result == 'success')
    )
```

Do not delete idempotency. Each publication block probes Hex, emits `skip=true`, and guards `mix hex.publish` with `steps.idempotency.outputs.skip != 'true'` (core lines 746-755; admin lines 864-880).

---

### `.github/workflows/release-please.yml` (config/release workflow, event-driven/transform)

**Analog:** the existing “Sync sibling package -> mailglass dep pin” release-PR step at lines 173-276.

**Authenticated release-PR mutation pattern** (lines 173-192):

```yaml
- name: Checkout main for sync step
  if: ${{ steps.release-preflight.outputs.should_run == 'true' && steps.release.outputs.prs_created == 'true' }}
  uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1
  with:
    fetch-depth: 0
    token: ${{ secrets.RELEASE_PLEASE_PAT }}

- name: Sync sibling package -> mailglass dep pin on release-please branch
  if: ${{ steps.release-preflight.outputs.should_run == 'true' && steps.release.outputs.prs_created == 'true' }}
  run: |
    set -euo pipefail
    BRANCH=release-please--branches--main
    git fetch origin "$BRANCH":"$BRANCH"
    git checkout "$BRANCH"
```

Keep the preflight and PR-created guards, PAT-backed checkout, fixed release branch, narrow diff, and bot commit/push pattern. This is the established anti-recursion-safe path; do not create an alternate sync workflow.

**Manifest ownership and conditional inbound mutation pattern** (lines 194-255):

```bash
CORE_VERSION=$(jq -r '.["."]' .release-please-manifest.json)
CORE_MM=$(echo "$CORE_VERSION" | cut -d. -f1,2)
INBOUND_VERSION=$(jq -r '.["mailglass_inbound"]' .release-please-manifest.json)

if [ -n "$INBOUND_VERSION" ] && [ "$INBOUND_VERSION" != "null" ]; then
  # inbound README/install-guide/publish-summary changes only live here
fi
```

The linked pair gets core-derived README pins; inbound has independent manifest ownership. Tighten the existing sync paths (lines 257-275) so an unchanged inbound 2.1.1 is neither modified nor included in a release-PR commit merely because core/admin become 2.4.0.

---

### `.github/workflows/post-publish-smoke.yml` (config/published E2E workflow, event-driven/request-response)

**Analog:** the existing `consumer-install` job at lines 312-381 and tracker/evidence flow at lines 508-652.

**Published-version and direct-output pattern** (lines 320-380):

```yaml
consumer-install:
  needs: [cron-guard, wait-for-hexdocs]
  if: ${{ needs.cron-guard.outputs.should_run == 'true' }}
  env:
    VERSION: ${{ needs.cron-guard.outputs.version }}
  steps:
    - name: Check published inbound compatibility
      id: inbound-compat
      env:
        VERSION: ${{ needs.cron-guard.outputs.version }}
        VERSION_INBOUND: ${{ needs.cron-guard.outputs.version_inbound }}
    - name: Run consumer-install smoke (published Hex versions)
      env:
        DEP_MODE: hex
        VERSION: ${{ needs.cron-guard.outputs.version }}
        VERSION_INBOUND: ${{ needs.cron-guard.outputs.version_inbound }}
        INCLUDE_INBOUND: ${{ steps.inbound-compat.outputs.include_inbound }}
      run: bash scripts/consumer_install_smoke.sh
```

Use the same output/env hand-off and shared script. Make the unchanged inbound compatibility check positive and deterministic for `mailglass 2.4.0` + `mailglass_inbound 2.1.1`; do not silently turn an incompatible inbound result into a skipped consumer dependency.

**Retained evidence/summary pattern** (lines 586-637):

```yaml
close-publish-smoke-tracker-on-success:
  needs: [cron-guard, wait-for-index, wait-for-hexdocs, consumer-install, published-trust-journey, retracted-check]
  if: >-
    ${{ needs.cron-guard.outputs.should_run == 'true' &&
        needs.consumer-install.result == 'success' &&
        needs.published-trust-journey.result == 'success' }}
```

```javascript
const body = [
  `Resolved: post-publish-smoke green for v${version}.`,
  `- SHA: \`${context.sha}\``,
  `- OPS-01 guard: \`consumer-install\` succeeded`,
  `- Evidence artifact: \`${artifactName}\``
].join("\n");
```

Follow the existing bounded Hex/HexDocs polling and artifact conventions. Any Phase 148 proof summary must contain only tag/SHA, resolved versions, commands, and outcomes—never credentials or consumer data.

---

### `test/scripts/linked_release_concurrency_test.exs` (test/workflow contract, transform)

**Analog:** this file itself, especially its named job extractor at lines 74-103.

**Imports and fixture pattern** (lines 1-8):

```elixir
defmodule Mailglass.Scripts.LinkedReleaseConcurrencyTest do
  use ExUnit.Case, async: true

  @publish_path Path.expand("../../.github/workflows/publish-hex.yml", __DIR__)
  @smoke_path Path.expand("../../.github/workflows/post-publish-smoke.yml", __DIR__)
  @shared_group "mailglass-linked-release-fanout"
end
```

**Targeted source-contract pattern** (lines 37-48 and 74-103):

```elixir
source = File.read!(@publish_path)
job = extract_publish_job!(source, package)

assert job =~ "mix hex.info #{package} \"${VERSION}\""
assert job =~ "skip=true"
assert job =~ "steps.idempotency.outputs.skip != 'true'"
```

```elixir
lines = String.split(source, "\n")
[{_header, start_index}] = matches

lines
|> Enum.drop(start_index)
|> Enum.take_while(fn line ->
  line == "  #{job_name}:" or not Regex.match?(~r/^  [a-z][a-z0-9-]*:$/, line)
end)
|> Enum.join("\n")
```

Extend this test rather than adding a YAML parser or whole-file equality fixture. Assert the release-event branch excludes inbound, `publish-admin.needs` excludes inbound but requires core/gate success, and explicit inbound-only dispatch remains present. Retain static concurrency and all three idempotency assertions.

---

### `test/mailglass/publish/post_publish_smoke_contract_test.exs` (test/workflow contract, transform)

**Analog:** existing post-publish workflow slicing at lines 10-14, 30-53, and 83-86.

**Job-block assertion pattern** (lines 30-53):

```elixir
workflow = File.read!(@workflow_path)
consumer_install = extract_job!(workflow, "consumer-install", "published-trust-journey")

assert consumer_install =~ "Run mix mailglass.install"
assert consumer_install =~ "Compile, fail on warnings"
assert consumer_install =~ "set -euo pipefail"
```

```elixir
defp extract_job!(workflow, start_key, next_key) do
  [_before, rest] = String.split(workflow, "\n  #{start_key}:\n", parts: 2)
  [job | _after] = String.split(rest, "\n  #{next_key}:\n", parts: 2)
  job
end
```

Add compact string assertions for the exact `DEP_MODE=hex`, `VERSION=2.4.0`, `VERSION_INBOUND=2.1.1`, and positive compatibility/evidence semantics selected by the implementation. Keep `@moduletag :requires_workspace`, since this suite deliberately exercises workspace-level workflow contracts.

---

### `.github/workflows/ci.yml` (config/CI proof bundle, event-driven/batch)

**Analog:** the existing shift-left installer-host job at lines 147-176.

**Shared harness invocation pattern** (lines 147-176):

```yaml
# Shift-left of the post-publish consumer-install smoke: runs the SAME
# scripts/consumer_install_smoke.sh against the WORKING TREE (local path deps)
env:
  DEP_MODE: path
  MAILGLASS_PATH: ${{ github.workspace }}
  WORK_DIR: ${{ runner.temp }}
run: bash scripts/consumer_install_smoke.sh
```

If a dedicated pre-release proof-bundle job is added, make it a narrowly named job that invokes the exact canonical suppression/docs tests and the package-local operator test. Do not duplicate `consumer_install_smoke.sh`; path mode remains the CI shift-left proof, while Hex mode remains post-publication evidence.

## Shared Patterns

### Protected release authorization

**Sources:** `.github/workflows/publish-hex.yml` lines 715-763 and 779-883.  
**Apply to:** every changed publish job.

```yaml
environment: hex-publish
...
env:
  HEX_API_KEY: ${{ secrets.HEX_API_KEY }}
```

Keep this only after explicit event/package and successful-prerequisite guards. Never pass the key to PR CI, workflow summaries, or artifacts.

### Static linked-release serialization

**Sources:** `.github/workflows/publish-hex.yml` lines 59-61; `.github/workflows/post-publish-smoke.yml` lines 27-29.  
**Apply to:** all modified release/published-smoke paths.

```yaml
concurrency:
  group: mailglass-linked-release-fanout
  cancel-in-progress: false
```

### Workflow-contract testing

**Sources:** `test/scripts/linked_release_concurrency_test.exs` lines 37-48, 74-103; `test/mailglass/publish/post_publish_smoke_contract_test.exs` lines 83-93.  
**Apply to:** release graph and published-smoke changes.

Use `File.read!`, a named job-block extractor, and precise positive/negative string assertions. This project deliberately tests load-bearing workflow semantics without introducing a full YAML fixture or parser.

### Consumer smoke modes

**Source:** `scripts/consumer_install_smoke.sh` lines 22-75.  
**Apply to:** CI and post-publish workflows.

```bash
DEP_MODE="${DEP_MODE:-path}"
...
"hex" ->
  v = System.get_env("VERSION") || raise "hex mode requires VERSION"
  vi = System.get_env("VERSION_INBOUND") || ""
  inbound = if System.get_env("INCLUDE_INBOUND") == "true" and vi != "", do: ...
```

Path mode injects sibling paths; Hex mode pins published core/admin and optionally inbound. Reuse it unchanged in both lanes.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| No separate proof-collector script is required | utility | batch | Existing workflow summaries/artifacts and the focused test commands cover the evidence requirement; adding a second consumer harness is explicitly out of scope. |

## Metadata

**Analog search scope:** `.github/workflows/`, `test/scripts/`, `test/mailglass/publish/`, `scripts/`  
**Files scanned:** 14  
**Pattern extraction date:** 2026-08-01
