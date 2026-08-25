# Phase 161: Canonical Workspace and Evidence Preservation - Pattern Map

**Mapped:** 2026-08-21  
**Files analyzed:** 2  
**Analogs found:** 2 / 2

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.planning/phases/161-canonical-workspace-and-evidence-preservation/161-WORKSPACE-INVENTORY.md` | verification evidence / planning artifact | batch / transform | `.planning/milestones/v1.10-phases/91-folder-adoption-and-reference-reconciliation/91-gate-evidence.md` | role-match |
| `.planning/phases/161-canonical-workspace-and-evidence-preservation/161-VALIDATION.md` | validation contract | batch / transform | `.planning/milestones/v2.3-phases/148-release-and-adoption-proof/148-VALIDATION.md` | exact |

Phase 161 has no application source, Mix task, or test-file change in scope. `dev/mix/tasks/mailglass.repo.hygiene.ex` and its test are read-only safety precedents; the new inventory must use native Git evidence around that existing behavior rather than extend it.

## Pattern Assignments

### `.planning/phases/161-canonical-workspace-and-evidence-preservation/161-WORKSPACE-INVENTORY.md` (verification evidence / planning artifact, batch / transform)

**Primary analog:** `.planning/milestones/v1.10-phases/91-folder-adoption-and-reference-reconciliation/91-gate-evidence.md`

**Supporting analogs:** `.planning/milestones/v2.6-phases/160-certification-documentation-and-release/160-06-SUMMARY.md`; `.planning/release-target.json`

**Evidence header and phase-base pattern** (91 gate evidence, lines 1-14):

```markdown
# Phase 91 Gate Evidence - canonical brandbook/ adoption

- **Date:** 2026-06-12
- **Gate script:** `.planning/phases/91-folder-adoption-and-reference-reconciliation/gate.sh` (run from repo root)
- **Phase scope:** FOLD-01, FOLD-02, FOLD-03

## Phase Base

Phase base: `63701373af556a6c4fbc9d48f0d1a2d7c31782fb`
```

**Reproducible-command / captured-result pattern** (91 gate evidence, lines 15-30):

```markdown
## Wave 0 Gate Setup

Command:

```bash
bash -n .planning/phases/91-folder-adoption-and-reference-reconciliation/gate.sh
```

Output:

```text
```

Exit code: 0
```

**Evidence-preserving release-ledger pattern** (160 summary, lines 98-106):

```markdown
## Files Created/Modified

- `.planning/release-target.json` — final tag, publication, Hex checksum, smoke-run, and checkpoint-digest ledger.
- `.github/workflows/publish-hex.yml` — fail-closed control-SHA recovery that preserves immutable-tag publication inputs.
- `.planning/phases/160-certification-documentation-and-release/160-06-SUMMARY.md` — durable release and recovery record.
```

**Copy direction:** Start with a dated, immutable-at-capture header, then use one durable table row per worktree, stash, relevant local/remote ref and divergent range, selected unreachable object, and release artifact. Each row must record identity/path or object ID; observed state; content and unique-work command/result; reachability command/result; evidence reference; one allowed disposition (`retain`, `handoff`, `merge`, `archive`, or `remove`); preservation ref or Phase 162 handoff; and the permitted next action. Put full commands and short captured outputs beneath the matrix, using the command/output/exit-code convention above. Record the canonical root as `/Users/jon/projects/mailglass` on `main`, separately stating its clean working tree, exact capture-time divergence, the locked explained seven-commit range, and its non-release-clean status until upstream settlement. Do not convert the document into a remote PR/tag/Hex interpretation; link those uncertainties to Phase 162.

---

### `.planning/phases/161-canonical-workspace-and-evidence-preservation/161-VALIDATION.md` (validation contract, batch / transform)

**Analog:** `.planning/milestones/v2.3-phases/148-release-and-adoption-proof/148-VALIDATION.md`

**Frontmatter and purpose pattern** (lines 1-12):

```markdown
---
phase: 148
slug: release-and-adoption-proof
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-01
---

# Phase 148 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
```

**Per-task verification matrix pattern** (lines 37-47):

```markdown
## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | 0/1 | REL-01 | T-148-01 | Release events cannot expose secrets or republish inbound; manual inbound-only dispatch remains explicit | workflow contract | `mix test test/scripts/linked_release_concurrency_test.exs --warnings-as-errors` | ❌ W0 extension | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*
```

**Wave-0 gap checklist pattern** (lines 51-56):

```markdown
## Wave 0 Requirements

- [ ] Extend `test/scripts/linked_release_concurrency_test.exs` (or add a focused peer contract test) ...
- [ ] Add a deterministic compatibility assertion ...
- [ ] Define a credential-free, PII-free release-proof summary/artifact location.
```

**Copy direction:** Retain the already-established Phase 161 frontmatter, infrastructure, sampling cadence, threat table, and sign-off structure. When the inventory plan is finalized, replace draft task IDs/plans/waves only with actual plan ownership and keep the validation commands read-only, fixed-argument Git commands. Its Wave 0 section should continue to treat the inventory schema and preservation-before-removal gate as the evidence dependency; do not turn a blocked Mix dependency state into a Phase 161 dependency change.

## Shared Patterns

### Fail-closed canonical-state assessment

**Source:** `dev/mix/tasks/mailglass.repo.hygiene.ex` (lines 103-155)

**Apply to:** Canonical-root inventory row, validation assertions, and every release-clean statement.

```elixir
{ahead, behind, upstream_status} =
  case git(repo, ["rev-list", "--left-right", "--count", "@{upstream}...HEAD"]) do
    {output, 0} ->
      [behind, ahead] =
        output
        |> String.trim()
        |> String.split(~r/\s+/, trim: true)
        |> Enum.map(&String.to_integer/1)

      {ahead, behind, :ok}

    {output, _} ->
      {0, 0, %{status: "unknown", message: String.trim(output)}}
  end

case upstream_status do
  :ok ->
    blocked? = dirty? || ahead > 0 || behind > 0
    check(:git_state, if(blocked?, do: :blocked, else: :pass), ..., details)
  _ when dirty? ->
    check(:git_state, :blocked, "Local git state is not release-clean.", details)
  _ ->
    unknown(:git_state, "Git upstream comparison could not be established; configure a resolvable upstream and retry.", details)
end
```

Record upstream uncertainty and every ahead/behind count as non-release-clean; a clean worktree is insufficient. The inventory must state actual measured values and retain the seven-commit semantic explanation rather than normalizing history.

### Preservation before any Git-managed removal

**Source:** `dev/mix/tasks/mailglass.repo.hygiene.ex` (lines 88-101); `MAINTAINING.md` (lines 9-15)

**Apply to:** Every dirty worktree, stash, unique/detached candidate, uncertain ref, and selected unreachable object.

```elixir
if dirty? || ahead > 0 do
  branch = "preserve/repo-hygiene-#{timestamp()}"
  {_, 0} = git(repo, ["branch", branch])
  Mix.shell().info("Created preservation branch #{branch}.")
else
  Mix.shell().info("No local preservation branch needed.")
end
```

```markdown
The release branch must start from a clean worktree with no local ahead/behind
drift from `origin/main`. If local work exists, preserve it on a named
`preserve/*` branch before release work continues.
```

The plan may use a named `preserve/*` ref or an explicit Phase 162 handoff, but must record it before an ordinary non-force removal. No reset, force removal, branch `-D`, stash clear/drop, history rewrite, force push, garbage collection, or bulk deletion belongs in this phase.

### Release proof is tracked evidence, not scratch output

**Source:** `MAINTAINING.md` (lines 63-75)

**Apply to:** Detached candidate diffs, `.planning/publish/*-publish-summary.json`, and `.planning/release-target.json` inventory rows.

```markdown
The files under `.planning/publish/*-publish-summary.json` are tracked release
proof snapshots, not scratch output.

- Refresh them with `mix mailglass.publish.check` for the affected package(s).
- Review the diff together with the paired `*-files.expected` allowlist diff.
- Commit the snapshot update when the underlying package contents or version
  truth changed intentionally.

Do not gitignore these files: `test/mailglass/stability_contract_test.exs`
reads the inbound summary directly as part of the sibling-package release
contract.
```

Classify each artifact individually and retain or hand it off until its content and provenance are assessed. The inventory may record that remote meaning remains unsettled, but must not resolve PR, checks, tags, Hex, or scheduled automation before Phase 162.

### Native Git command boundary

**Source:** `dev/mix/tasks/mailglass.repo.hygiene.ex` (lines 428-438)

**Apply to:** All command references in the inventory and validation contract.

```elixir
defp git_output(repo, args) do
  repo
  |> git(args)
  |> elem(0)
end

defp git(repo, args), do: cmd(repo, "git", args)

defp cmd(repo, executable, args) do
  System.cmd(executable, args, cd: repo, stderr_to_stdout: true)
end
```

Use native Git porcelain and fixed, quoted argument lists (`worktree list --porcelain -z`, `status`, `stash`, `for-each-ref`, `rev-list`, `log`, `diff`, `show`, `tag`, and `fsck`). Capture commands and results; do not add a cleanup service, parse `.git` internals, or use external-state tooling.

## No Analog Found

None. The inventory is a new, more comprehensive artifact, but Phase 91 supplies the repository’s durable command/evidence layout and the hygiene task supplies its preservation semantics.

## Metadata

**Analog search scope:** `.planning/phases/`, `.planning/milestones/`, `dev/mix/tasks/`, `test/mix/tasks/`, `MAINTAINING.md`, and `.planning/release-target.json`  
**Files scanned:** 8  
**Pattern extraction date:** 2026-08-21
