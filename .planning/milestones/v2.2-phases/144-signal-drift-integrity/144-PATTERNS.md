# Phase 144: Signal & Drift Integrity - Pattern Map

**Mapped:** 2026-07-31
**Files analyzed:** 12 (9 modify, 3 focused contract tests to create; test filenames are discretionary)
**Analogs found:** 12 / 12

This phase deliberately extends existing authority boundaries. Do not add a desired-state
registry, a workflow, an Action, or an icon dependency. `setup_branch_protection.sh` remains
the expected-state generator and `verify-branch-protection.sh` remains the live comparator.

## File Classification

| New/Modified File | Op | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|---|
| `.github/workflows/branch-protection-drift.yml` | MODIFY | CI config | scheduled request-response | `.github/workflows/ci.yml:1091-1139` | same verification flow |
| `.github/workflows/ci.yml` | MODIFY | CI config | request-response | `.github/workflows/branch-protection-drift.yml:20-53` | same credential preflight |
| `dev/mix/tasks/mailglass.repo.hygiene.ex` | MODIFY | Mix task / utility | request-response | itself `:188-215`, `:345-355` | self |
| `test/scripts/required_checks_test.exs` | MODIFY | meta-test | file-I/O → transform | `test/scripts/guard_release_trigger_test.exs:97-115` | exact display-name contract |
| `mailglass_admin/scripts/check-conformance.sh` | MODIFY | conformance utility | batch transform | itself `:148-181` | self |
| `test/scripts/icon_exists_gate_test.exs` (or focused equivalent) | CREATE | integration/meta-test | file-I/O → batch | `test/scripts/conformance_advisory_test.exs:8-63` | exact temporary-fixture harness |
| `.github/workflows/publish-hex.yml` | MODIFY | CI/release config | event-driven | itself `:56-61`, `:743-755` | self |
| `.github/workflows/post-publish-smoke.yml` | MODIFY | CI/release config | event-driven | `.github/workflows/publish-hex.yml:56-61` | same workflow-level serialization |
| `test/scripts/release_integrity_test.exs` (or focused equivalent) | CREATE | workflow-contract test | file-I/O → transform | `test/scripts/guard_release_trigger_test.exs:122-154`; `required_checks_test.exs:159-176` | role match |
| `.github/workflows/release-please.yml` | MODIFY only if durable comments/contract seam require it | CI/recovery config | scheduled event-driven | itself `:3-20`, `:40-108` | self |
| `CONTRIBUTING.md` | MODIFY | maintainer documentation | static | its recovery section `:148-166` | self |
| `test/scripts/branch_protection_truth_test.exs` (or focused equivalent) | CREATE | workflow/task contract test | file-I/O → transform | `test/scripts/required_checks_test.exs:21-57`; `test/scripts/guard_release_trigger_test.exs:122-154` | exact |

## Pattern Assignments

### `.github/workflows/branch-protection-drift.yml` (CI config, scheduled request-response)

**Primary analog:** `.github/workflows/ci.yml:1091-1139`

Keep the existing job, schedule, secret output name, checkout pin, and canonical script call.
Replace the current green skip with a final `if: always()` reporting step which differentiates
the unavailable precondition from a verifier drift failure. This is the same preflight shape
already used by the CI advisory:

```yaml
# .github/workflows/branch-protection-drift.yml:25-53
- name: Check for BRANCH_PROTECTION_PAT secret
  id: check-pat
  env:
    PAT_SET: ${{ secrets.BRANCH_PROTECTION_PAT != '' }}
  run: |
    if [ "$PAT_SET" = "true" ]; then
      echo "pat_present=true" >> "$GITHUB_OUTPUT"
    else
      echo "pat_present=false" >> "$GITHUB_OUTPUT"
      # summary text is written here
    fi

- name: Re-assert branch protection
  if: steps.check-pat.outputs.pat_present == 'true'
  env:
    GH_TOKEN: ${{ secrets.BRANCH_PROTECTION_PAT }}
    GITHUB_REPOSITORY_OWNER: ${{ github.repository_owner }}
    GITHUB_REPOSITORY: ${{ github.repository }}
  run: ./scripts/setup_branch_protection.sh main
```

**Implementation constraint:** D-01 calls this path a verification outcome even though the
workflow owns reassertion. Preserve its owner-controlled mutation role and add an explicit
failure/reporting step after prerequisite/operation outcomes; do not create a competing
read-only scheduled workflow.

### `.github/workflows/ci.yml` (CI config, request-response)

**Primary analog:** its current `branch_protection_advisory` job at `:1091-1139`.

The verifier already uses `continue-on-error: true`, which makes a terminal `always()` step
the authoritative outcome. Retain that step id and its environment, then collapse summary and
exit behavior into one three-way terminal branch:

```yaml
# .github/workflows/ci.yml:1117-1139
- name: Verify branch protection
  if: steps.check-pat.outputs.pat_present == 'true'
  id: verify-protection
  continue-on-error: true
  env:
    GH_TOKEN: ${{ secrets.BRANCH_PROTECTION_PAT }}
    GITHUB_REPOSITORY_OWNER: ${{ github.repository_owner }}
    GITHUB_REPOSITORY: ${{ github.repository }}
  run: ./scripts/verify-branch-protection.sh main

- name: Write advisory summary
  if: steps.check-pat.outputs.pat_present == 'true'
  run: |
    if [ "${{ steps.verify-protection.outcome }}" = "success" ]; then
      echo "Live branch protection matches the expected read-only ruleset."
    else
      echo "Live branch protection drifted from the expected ruleset."
      echo "Review the verifier step log and re-apply with ./scripts/setup_branch_protection.sh main."
    fi
```

The final step must use `if: always()` and visibly fail separately for missing PAT/tooling/endpoint
and verified drift. Do not change the job display name `Branch Protection Advisory` or its
publish-gating classification in `publish-hex.yml`.

### `dev/mix/tasks/mailglass.repo.hygiene.ex` (Mix task, request-response)

**Primary analog:** the existing branch-protection sub-check at `:188-215`; aggregate status
at `:345-355`.

```elixir
# dev/mix/tasks/mailglass.repo.hygiene.ex:188-214
defp branch_protection(repo) do
  script = Path.join(repo, "scripts/verify-branch-protection.sh")

  cond do
    !File.exists?(script) ->
      unknown(:branch_protection, "Branch-protection verifier is missing.", %{})

    System.find_executable("gh") == nil || is_nil(System.get_env("GH_TOKEN")) ->
      unknown(:branch_protection, "GH_TOKEN and gh are required for branch-protection truth.", %{})

    true ->
      case cmd(repo, script, ["main"]) do
        {output, 0} -> check(:branch_protection, :pass, "Branch protection matches expected rules.", %{output: String.trim(output)})
        {output, _} -> check(:branch_protection, :blocked, "Branch protection differs from expected rules.", %{output: String.trim(output)})
      end
  end
end
```

```elixir
# dev/mix/tasks/mailglass.repo.hygiene.ex:345-355
defp status(checks) do
  if Enum.any?(checks, &(&1.status == :blocked)), do: :blocked, else: :pass
end

defp unknown(name, message, details) do
  check(name, :unknown, message, details)
end
```

Make `:unknown` / `:cannot_check` an aggregate non-success (while keeping it distinct from
`:blocked`) and let `branch_protection/1` distinguish unavailable verifier prerequisites from a
nonzero live comparison. Preserve the `%{name, status, message, details}` data shape and both
JSON/text emitters.

### `test/scripts/required_checks_test.exs` (meta-test, file-I/O → transform)

**Primary analog:** `test/scripts/guard_release_trigger_test.exs:97-115`.

Put the job-id versus display-name regression beside the existing required-context parser. The
test must parse the bounded `guard-release-trigger` job block/name, prove a nonempty parser
result, compare its display name to `REQUIRED_CHECKS`, and refute use of the YAML id.

```elixir
# test/scripts/guard_release_trigger_test.exs:97-115
job_names =
  source
  |> String.split("\n")
  |> Enum.filter(&Regex.match?(~r/^    name: .+$/, &1))
  |> Enum.map(fn line ->
    [[_, name]] = Regex.scan(~r/^    name: (.+)$/, line)
    String.trim(name)
  end)

assert job_names != [], "No job name: lines found ..."
assert @expected_job_name in job_names
```

Use the existing parser/anti-vacuity convention rather than a whole-file `contains?` assertion:

```elixir
# test/scripts/required_checks_test.exs:21-42
array_set = parse_required_checks(source)
bullet_set = parse_print_expected_bullets(source)
assert MapSet.size(array_set) > 0, "parsed no REQUIRED_CHECKS entries — parser or script format changed"
assert MapSet.size(bullet_set) > 0, "parsed no print_expected_text bullets — parser or script format changed"
only_in_array = MapSet.difference(array_set, bullet_set)
only_in_bullets = MapSet.difference(bullet_set, array_set)
```

### `mailglass_admin/scripts/check-conformance.sh` (conformance utility, batch transform)

**Primary analog:** the existing `ICON-EXISTS-GATE` at `:148-181`.

Retain the temp-file lifecycle, nonempty scan guard, vendored inventory extraction, `comm` diff,
and shared `errors` accumulator. Extend *used icon* extraction only: literal regex output must be
unioned with statically enumerable dynamic values that pass through `<.icon name={...}>`.

```bash
# mailglass_admin/scripts/check-conformance.sh:151-180
used_icons="$(mktemp)"
available_icons="$(mktemp)"
missing_icons="$(mktemp)"
trap 'rm -f "$used_icons" "$available_icons" "$missing_icons"' EXIT

grep -rhoE 'hero-[a-z0-9-]+' "$LIB" --include="*.ex" 2>/dev/null |
  sed 's/^hero-//' |
  sort -u > "$used_icons"

[[ -s "$used_icons" ]] || { echo "FAIL: ICON-EXISTS-GATE — zero hero-* usages scanned in $LIB ..." >&2; exit 2; }

grep -E '^[[:space:]]*"[-a-z0-9]+":' "$HEROICONS" 2>/dev/null |
  sed -E 's/^[[:space:]]*"([-a-z0-9]+)".*/\1/' |
  sort -u > "$available_icons"
comm -23 "$used_icons" "$available_icons" > "$missing_icons"
```

The dynamic source inventory to cover is real and bounded: `option.icon` at
`components.ex:394`, helper-return invocation at `:465` with finite clauses at `:766-770`,
attribute/fallback resolution at `:493-521`, and map values at `:564-569`. The icon boundary
itself is a class built from `@name` at `components.ex:39-49`. Do not hardcode historical icon
names, and fail closed with a remediation if a dynamic form cannot be finitely resolved.

### `test/scripts/icon_exists_gate_test.exs` (CREATE, integration test, file-I/O → batch)

**Primary analog:** `test/scripts/conformance_advisory_test.exs:8-63`.

Copy the isolated temp directory, `on_exit` cleanup, copied real script, source fixture, command
execution, and explicit exit/output assertions. Unlike the advisory test, preserve the target
script's expected directory layout (script, `lib`, and vendored asset path) so the real
`ICON-EXISTS-GATE` executes. The negative fixture must encode a missing `hero-*` through one
supported dynamic representation, not as a bare literal.

```elixir
# test/scripts/conformance_advisory_test.exs:8-34
tmp = Path.join(System.tmp_dir!(), "mailglass-advisory-#{System.unique_integer([:positive])}")
script_dir = Path.join(tmp, "scripts")
lib_dir = Path.join(tmp, "lib")
on_exit(fn -> File.rm_rf!(tmp) end)
File.mkdir_p!(script_dir)
File.mkdir_p!(lib_dir)
File.cp!(@script_path, Path.join(script_dir, "check-conformance-advisory.sh"))

{output, status} = System.cmd("bash", [Path.join(script_dir, "check-conformance-advisory.sh")], stderr_to_stdout: true)
assert status == 1
assert output =~ "FAIL: ..."
```

### `.github/workflows/publish-hex.yml` and `.github/workflows/post-publish-smoke.yml` (CI config, event-driven)

**Primary analog:** `publish-hex.yml:56-61`; counterpart `post-publish-smoke.yml:23-29`.

Change both complete workflow-level concurrency blocks atomically to the same release-independent
intent and retain `cancel-in-progress: false`. The current ref/tag-derived groups are the exact
regression class to remove:

```yaml
# .github/workflows/publish-hex.yml:56-61
concurrency:
  group: publish-hex-${{ github.ref }}
  cancel-in-progress: false

# .github/workflows/post-publish-smoke.yml:27-29
concurrency:
  group: post-publish-smoke-${{ github.event.inputs.tag || github.event.release.tag_name || github.ref }}
  cancel-in-progress: false
```

Retain all three successful idempotency guards in publishing:

```bash
# .github/workflows/publish-hex.yml:746-755
if mix hex.info mailglass "${VERSION}" 2>/dev/null | grep -q "Released:"; then
  echo "Version ${VERSION} of mailglass already on Hex — skipping publish (idempotency guard)."
  echo "skip=true" >> "$GITHUB_OUTPUT"
fi
# The publish step is conditional: if: steps.idempotency.outputs.skip != 'true'
```

The equivalent blocks at `:864-880` and `:966-982` cover `mailglass_admin` and
`mailglass_inbound`; keep all three. The shared group must not contain `github.ref`, an event
tag, or dispatch tag input.

### `test/scripts/release_integrity_test.exs` (CREATE, workflow contract, file-I/O → transform)

**Primary analogs:** `required_checks_test.exs:159-176` (bounded parser) and
`guard_release_trigger_test.exs:122-154` (indent-bounded YAML extraction).

Create one focused source-contract module covering both serialization and recovery. Parser helpers
must return `nil`/empty on a missed block; tests must assert nonempty/nonnull before checking:

```elixir
# test/scripts/guard_release_trigger_test.exs:132-153
case Enum.find_index(lines, &(&1 =~ ~r/^\s{2}pull_request:$/)) do
  nil -> nil
  start_idx ->
    [header | rest] = Enum.drop(lines, start_idx)
    children = Enum.take_while(rest, fn line -> Regex.match?(~r/^\s{4,}/, line) or line == "" end)
    Enum.join([header | children], "\n")
end
```

Assert both workflow groups are equal, static, and `cancel-in-progress: false`; negative-control an
in-memory source with a ref expression. For `release-please.yml`, assert the hourly cron, complete-tag
no-op, partial-state `exit 1`, `autorelease: tagged` no-op, and the action's
`should_run == 'true'` guard from the real preflight at `release-please.yml:68-108`.

### `CONTRIBUTING.md` (maintainer documentation, static)

**Primary analog:** the recovery section at `:148-166`.

Update this existing section instead of creating a second release runbook. It must say that the hourly
schedule is the bounded recovery path, identify the maximum delay, retain manual dispatch/tag fallback,
and describe why complete tags and `autorelease: tagged` safely no-op while partial tag state fails.

```markdown
# CONTRIBUTING.md:159-166
**Recovery:** land any subsequent commit on `main` via a **non-`GITHUB_TOKEN`
identity ... The publish jobs are idempotent (`mix hex.info` guards), so a re-trigger is
always safe. Manually creating the releases with `gh release create <tag>` is an
equivalent fallback — `release: published` is the canonical publish trigger.
```

## Shared Patterns

### Honest unavailable verification

**Sources:** `.github/workflows/ci.yml:1095-1139`; `dev/mix/tasks/mailglass.repo.hygiene.ex:188-215`.
**Apply to:** both workflow verification paths and the hygiene `branch_protection` sub-check.

- Keep preflight, verifier, and terminal reporting separate.
- Use `if: always()` for the terminal workflow step when a prerequisite or a `continue-on-error`
  verifier can fail.
- Emit distinct unavailable / drift / clean messages, and return non-success for unavailable.

### Canonical branch-protection data flow

**Sources:** `scripts/setup_branch_protection.sh:12-55`; `scripts/verify-branch-protection.sh:17-80`.
**Apply to:** workflows and hygiene only by invoking these scripts; do not duplicate expected JSON or
normalization.

```bash
# scripts/verify-branch-protection.sh:72-81
if [ "$(jq -S . <<<"${EXPECTED_JSON}")" = "$(jq -S . <<<"${LIVE_NORMALIZED}")" ]; then
  echo "OK: branch protection matches expected ruleset for ${REPO}@${BRANCH}."
  exit 0
fi
echo "DRIFT: branch protection differs from expected ruleset for ${REPO}@${BRANCH}." >&2
diff -u <(jq -S . <<<"${EXPECTED_JSON}") <(jq -S . <<<"${LIVE_NORMALIZED}") || true
exit 1
```

### Anti-vacuous workflow contracts

**Sources:** `test/scripts/required_checks_test.exs:27-42`; `test/scripts/guard_release_trigger_test.exs:122-154`.
**Apply to:** all new source-contract tests.

Parse only the bounded block, assert it was found, assert the invariant, then run the same parser
against an in-memory broken copy and assert it detects the break. Never use a whole-file substring as
the sole proof of a workflow invariant.

### Static icon inventory

**Sources:** `mailglass_admin/scripts/check-conformance.sh:148-181`; `mailglass_admin/lib/mailglass_admin/components.ex:39-49`.
**Apply to:** the expanded extractor and its fixture test.

The vendored `heroicons-inline.js` keys are authoritative; the conformance script owns lifecycle,
inventory, set difference, and error accumulation. Components are evidence of supported bounded dynamic
forms, not a new registry.

### Linked release serialization and safe retries

**Sources:** `.github/workflows/publish-hex.yml:56-61`, `:746-755`, `:864-880`, `:966-982`.
**Apply to:** both release-published workflow concurrency blocks and the release contract test.

Make serialization shared and ref-independent; do not alter the registry `mix hex.info` no-op behavior.

## No Analog Found

None. The three new focused contract-test files use established `test/scripts` ExUnit patterns. Exact
file boundaries/names remain discretionary, but they must be picked up by the existing `test/scripts/`
contract lane and retain the listed anti-vacuity behavior.

## Metadata

**Analog search scope:** `.github/workflows`, `scripts`, `dev/mix/tasks`, `test/scripts`,
`mailglass_admin/scripts`, `mailglass_admin/lib`, `CONTRIBUTING.md`
**Files scanned:** 16 primary workflow/script/test/component/doc files
**Pattern extraction date:** 2026-07-31
