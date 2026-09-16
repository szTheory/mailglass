# Phase 162: Protected Release and Scheduled-Control Recovery - Pattern Map

**Mapped:** 2026-08-22  
**Files analyzed:** 8 new/modified files  
**Analogs found:** 8 / 8

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/phases/162-protected-release-and-scheduled-control-recovery/162-RELEASE-RECONCILIATION.md` | evidence record | batch | `161-WORKSPACE-INVENTORY.md` | role-match |
| `dev/mix/tasks/mailglass.repo.hygiene.ex` | utility/Mix task | batch | same file | exact |
| `test/mix/tasks/mailglass.repo.hygiene_test.exs` | test | batch | same file | exact |
| `.github/workflows/repo-hygiene.yml` | workflow config | scheduled event-driven | same file | exact |
| `.github/workflows/release-please.yml` | workflow config | scheduled/request-response | same file | exact |
| `test/scripts/release_trigger_recovery_test.exs` | test | request-response | same file | exact |
| `.github/workflows/post-publish-smoke.yml` | workflow config | scheduled event-driven | same file | exact |
| `test/mailglass/publish/post_publish_smoke_contract_test.exs` | test | scheduled/event-driven | same file | exact |

Maintenance boundary: do not add a release subsystem, expand ordinary-trigger authority, mutate the ledger merely to make smoke pass, or touch Phase 163/164 work.

## Pattern Assignments

### `162-RELEASE-RECONCILIATION.md` (evidence record, batch)

**Analog:** `.planning/phases/161-canonical-workspace-and-evidence-preservation/161-WORKSPACE-INVENTORY.md`

**Capture and append-only pattern** (lines 3-10, 56-58):

```markdown
**Capture time (UTC):** `…`
**Capture HEAD / phase-base marker:** `…`
**Method:** fixed, read-only Git commands only. No checkout, ref creation,
reset, merge, prune, removal, force operation, or cleanup command was run.

Any later observation must append a new timestamp and HEAD rather than silently
rewriting this block.
```

**Per-identity matrix pattern** (lines 12-20, 77-99):

```markdown
| ID | category | identity/path | observed state | evidence ref | disposition | outcome |
| --- | --- | --- | --- | --- | --- | --- |
| REF-0018 | release tag | `mailglass-v2.5.0` | `0f0b…` | EVID-REF-GRAPH | handoff | captured |
```

Add capture time, source/command or URL, immutable identity, observation, explicit outcome, and recovery condition to every row. Keep PR #222, all three tags, retained release/recovery refs, WT-03 deltas, Actions runs, Hex responses, and ledger facts distinct even when names/OIDs coincide. Fresh unavailable remote facts must be `cannot-check`, never inferred.

### `dev/mix/tasks/mailglass.repo.hygiene.ex` (utility/Mix task, batch)

**Analog:** same file

**Aggregate / exit shape** (lines 30-58):

```elixir
result = if mode == :apply, do: (apply_safe_actions(repo); audit(repo)), else: audit(repo)
emit(result, format)
if result.status != :pass, do: exit({:shutdown, 1})

def audit(repo) do
  checks = [git_state(repo), ci_state(repo), branch_protection(repo),
            pull_requests(repo), stale_branches(repo), release_workflows(repo)]
  %{status: status(checks), generated_at: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(), repo: repo, checks: checks}
end
```

Keep nonzero exits for policy `blocked` and evidence-unavailable `cannot-check`; change only classification/serialization.

**Unknown-evidence and rendering seams** (lines 388-419):

```elixir
defp status(checks) do
  if Enum.all?(checks, &(&1.status == :pass)), do: :pass, else: :blocked
end

defp unknown(name, message, details), do: check(name, :unknown, message, details)

defp emit(result, "json") do
  result |> encode_statuses() |> Jason.encode!(pretty: true) |> Mix.shell().info()
end
```

Replace the collapsing aggregate with explicit precedence: `cannot-check`, then `blocked`, then `pass`. Map any internal atom at this boundary to the literal JSON/text spelling `cannot-check`; make this single result map feed text, JSON, summary, and artifact.

### `test/mix/tasks/mailglass.repo.hygiene_test.exs` (test, batch)

**Analog:** same file

**Distinct evidence / policy tests** (lines 63-71, 119-139):

```elixir
assert result.status == :blocked
assert check(result, :branch_protection).status == :unknown
assert check(result, :branch_protection).message =~ "verifier is missing"

assert check(result, :branch_protection).status == :blocked
assert check(result, :branch_protection).message =~ "differs from expected"
```

Update evidence-unavailable assertions to `:cannot_check`; retain `:blocked` for verified drift. Add mixed-status precedence plus independent nonzero exit checks.

**CLI format contract** (lines 152-170):

```elixir
{text, json} = …
assert text =~ "Repo hygiene: pass"
assert text =~ "pass branch_protection:"
assert Jason.decode!(json)["status"] == "pass"
```

Mirror this capture for `cannot-check` in both text and JSON.

### `.github/workflows/repo-hygiene.yml` (workflow config, scheduled event-driven)

**Analog:** same file

**Entry-point and permission pattern** (lines 3-19):

```yaml
on:
  schedule:
    - cron: "30 12 * * *"
  workflow_dispatch:
permissions:
  contents: read
  pull-requests: read
  actions: read
```

Do not change triggers, permissions, or topology.

**Artifact-first summary pattern** (lines 36-65):

```yaml
mix mailglass.repo.hygiene --check --format json | tee "$RUNNER_TEMP/repo-hygiene.json"

if [ -f "$RUNNER_TEMP/repo-hygiene.json" ]; then
  jq -r '.checks[] | "- \(.status) `\(.name)`: \(.message)"' "$RUNNER_TEMP/repo-hygiene.json"
fi
```

Preserve JSON after expected non-pass behavior and render aggregate status/reason from the same JSON rather than recomputing a verdict in shell.

### `.github/workflows/release-please.yml` (workflow config, scheduled/request-response)

**Analog:** same file

**Proposal-only authority split** (lines 3-18):

```yaml
# Pushes, digest-free manual runs, and the hourly schedule are proposal-only.
# Only a later protected workflow_dispatch carrying the exact
# dual-authorized candidate digest may cross that boundary.
workflow_dispatch:
  inputs:
    candidate_digest:
      required: false
schedule:
  - cron: "17 * * * *"
```

Never add merge/tag/publish authority to push, schedule, or digest-free dispatch.

**Protected exact-candidate gate** (lines 171-248):

```bash
run_policy validate-protected-dispatch "$control_target" "$CANDIDATE_DIGEST" > "$policy"
prs=$(gh pr list --head release-please--branches--main --base main --state open --json number,headRefOid,baseRefOid)
[ "$(jq -er 'length' <<<"$prs")" -eq 1 ]
[ "$head" = "$proposal_head" ]
[ "$base" = "$source_sha" ]
gh pr checks "$number" --required --repo "$GITHUB_REPOSITORY"
```

Repair reporting around the existing proposal path only; retain every digest, PR, check, protected-main, and content assertion.

**Auto-merge disarm** (lines 508-517):

```bash
echo "Disarmed ordinary auto-merge; a later protected exact candidate-digest dispatch is required."
```

### `test/scripts/release_trigger_recovery_test.exs` (test, request-response)

**Analog:** same file

**Workflow contract pattern** (lines 31-45):

```elixir
assert extract_trigger_block!(source, "push") =~ "branches:\n      - main"
assert extract_trigger_block!(source, "workflow_dispatch") =~ "candidate_digest:"
assert extract_trigger_block!(source, "schedule") =~ "cron: \"17 * * * *\""
```

**Executable fail-closed fixture** (lines 103-120, 143-161):

```elixir
with_fake_gh(:release_absent, fn temp_dir, env ->
  File.write!(script, preflight_script(preflight))
  assert {output, 0} = System.cmd("bash", [script], cd: @repo_root, env: …)
  assert output =~ "running release-please"
end)
```

Add a focused capture/reporting test that proves an inspectable proposal-only result without authorizing ordinary triggers. Keep fake-GitHub fixtures plus static and executable assertions.

### `.github/workflows/post-publish-smoke.yml` (workflow config, scheduled event-driven)

**Analog:** same file

**Immutable control and target checkouts** (lines 55-70):

```yaml
- name: Checkout immutable workflow control plane
  with:
    ref: ${{ github.workflow_sha }}
- name: Checkout immutable published target
  if: ${{ github.event_name == 'workflow_dispatch' }}
  with:
    ref: ${{ github.event.inputs.target_ref }}
    path: immutable-target
```

**Completed-target resolution and guard** (lines 91-168):

```bash
command="authorized-versions"
if [ "$EVENT_NAME" = "schedule" ]; then command="completed-versions"; fi
mix run … -- "$command" "$target" > "$resolved"
[ "$completed" = true ]
bash scripts/check_post_publish_target.sh --repo "$target_repo" --target "$target" \
  --target-ref "$target_ref" --core "$core" --admin "$admin" --inbound "$inbound"
```

For authorized/not-started schedules, retain the completed-target requirement. Add only bounded blocked/inapplicable report/summary/artifact before non-pass; never substitute `main`, `github.sha`, release event, or latest Hex versions.

### `test/mailglass/publish/post_publish_smoke_contract_test.exs` (test, scheduled/event-driven)

**Analog:** same file

**Immutable-ref workflow contract** (lines 82-110):

```elixir
assert resolver =~ "ref: ${{ github.workflow_sha }}"
refute resolver =~ "ref: main"
assert resolver =~ "ref: ${{ github.event.inputs.target_ref }}"
assert resolver =~ "bash scripts/check_post_publish_target.sh"
```

**Target guard integration contract** (lines 244-312):

```elixir
assert {valid_output, 0} = run_target_guard(repo, target, target_ref)
assert valid_output =~ "post-publish target verified"
assert arbitrary_status != 0
assert drift_output =~ "content digest mismatch"
assert missing_output =~ "required tag is unavailable"
```

Add scheduled authorized/not-started assertions for explicit blocked/inapplicable evidence while preserving the rejects-`main`, exact-tag, and digest contracts.

## Shared Patterns

### Protected release authority

**Source:** `.github/workflows/release-please.yml` lines 7-10, 171-248, 508-517  
**Apply to:** release-please reporting and tests.

```yaml
# Only a later protected workflow_dispatch carrying the exact
# dual-authorized candidate digest may cross that boundary.
```

### Immutable post-publish proof

**Source:** `scripts/check_post_publish_target.sh` lines 61-101  
**Apply to:** post-publish scheduled and protected-dispatch recovery.

```bash
for tag in "${expected_tags[@]}"; do
  git -C "$repo" fetch --force --no-tags origin "+refs/tags/$tag:refs/tags/$tag"
  resolved=$(git -C "$repo" rev-parse "refs/tags/${tag}^{commit}")
  [ "$resolved" = "$target_ref" ] || exit 1
done
actual_digest=$("$script_dir/release_policy_content_digest.sh" --repo "$repo" --ref "$target_ref")
[ "$actual_digest" = "$expected_digest" ] || exit 1
```

### Policy-owned lifecycle data

**Source:** `scripts/release_policy.exs` lines 317-365  
**Apply to:** protected-release and post-publish behavior.

```elixir
def cli(["completed-versions", target_path]) do
  with {:ok, json} <- File.read(target_path),
       {:ok, target} <- Jason.decode(json),
       {:ok, target} <- validate_completed_target(target) do
    IO.write("completed=true\\n")
    IO.write("target_ref=#{target["final_identity"]["tag_sha"]}\\n")
  else
    _ -> System.halt(1)
  end
end
```

Use this policy owner, not a second ledger/state machine or public “latest” inference.

## No Analog Found

None. The Phase 161 inventory is a strong forensic-evidence analog; Phase 162 extends it with fresh remote captures and explicit `cannot-check` facts.

## Metadata

**Analog search scope:** `.planning/phases/161-*`, `.github/workflows/`, `dev/mix/tasks/`, `scripts/`, `test/mix/tasks/`, `test/scripts/`, `test/mailglass/publish/`  
**Files scanned:** 12  
**Pattern extraction date:** 2026-08-22
