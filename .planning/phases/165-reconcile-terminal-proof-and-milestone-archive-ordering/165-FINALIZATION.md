---
phase: "165"
slug: reconcile-terminal-proof-and-milestone-archive-ordering
status: ready_after_execute_phase
terminal_authority: post_archive_only
human_checkpoints: 1
created: "2026-09-13"
---

# Phase 165 — v2.7 Post-Completion Finalization Runbook

This runbook is mandatory after the Phase 165 execute-phase workflow returns. It is not an
ordinary-plan command and none of its audit, archive, protected-integration, workflow-observation,
or terminal actions may run while Plan 165-05 is executing.

## 0. Entry Gate: Ordinary Completion Must Already Be Finished

Stop unless the entire Phase 165 execute-phase workflow has returned after all of the following:

- every `165-01` through `165-05` SUMMARY exists and has `status: complete`;
- `165-VERIFICATION.md` exists with a passing ordinary phase verdict;
- `165-VALIDATION.md` has exact frontmatter `status: validated`;
- Phase 165 completion metadata has been written and committed in ROADMAP, STATE, REQUIREMENTS,
  and the ordinary verification artifact;
- configured learnings extraction/copy, Phase 165 todo closure, and every transition hook has
  returned; and
- the checkout contains no unexplained change other than an explicitly recorded orchestrator-owned
  baseline.

The ignored terminal report is deliberately absent from this gate. It is post-archive evidence,
not a prerequisite for pre-archive validation, ordinary verification, or Phase 165 completion.
The Phase 164 report and `/Users/jon/.local/bin/mailglass-finalize-phase` command remain immutable
historical evidence only and have no v2.7 authority.

## 1. Produce the Canonical Milestone Audit

Run `/Users/jon/.codex/gsd-core/workflows/audit-milestone.md` through its normal workflow entry
only after the entry gate passes. Do not reproduce its three-source requirements, integration,
flow, or Nyquist logic in this runbook.

The newly generated live `.planning/v2.7-MILESTONE-AUDIT.md` must be non-null and must report:

- `status: passed` with no critical gap;
- requirements `16/16`;
- phases `5/5`;
- integration `16/16`;
- flows `5/5`;
- all five Phase 161-165 validation records compliant; and
- the repository-hygiene `14-PR` policy block explicitly disclosed as accepted operational debt.

Any other audit result stops the lifecycle before archive preview. Do not reinterpret or hand-edit
the canonical audit to make it pass.

## 2. Preview the Exact Archive Without Mutating It

Use `/Users/jon/.codex/gsd-core/workflows/complete-milestone.md` and the scoped executable section
below. First run its `preview` mode. It calls `init.complete-milestone`, proves that the resolved
section manifest excludes `git-tag`, and invokes the canonical command equivalent to:

```text
milestone.complete v2.7 --name "Repository Stewardship & Operational Hygiene" --dry-run
```

The preview must contain a non-null audit, exactly phase directories 161-165, `quick: []`, and no
phase-archive refusal. It must not use `--archive-quick` and performs no remote mutation.

### Tested scoped tag-omission mechanism

The section between the stable markers is executable Bash. Tests extract and run these exact bytes
against a disposable repository and stubbed initializer/archive command. Before each initialization
it copies the exact original config bytes to a private path outside the repository, installs a
restoration trap, and changes only `git.create_tag=false`. Success requires both exact original
config bytes restoration and final byte equality.

```bash
# phase165:tag-omission:start
phase_165_complete_milestone_without_tag() (
  set -eu

  phase_165_mode=${1:-}
  phase_165_approved_preview_sha=${2:-}
  phase_165_repo=${PHASE_165_REPO:-$(pwd -P)}
  phase_165_config="$phase_165_repo/.planning/config.json"
  phase_165_name='Repository Stewardship & Operational Hygiene'

  case "$phase_165_mode" in
    preview | confirm) ;;
    *) echo "phase165-archive: expected preview or confirm" >&2; exit 64 ;;
  esac
  [ -f "$phase_165_config" ] && [ ! -L "$phase_165_config" ] || {
    echo "phase165-archive: config is not one regular non-symlink file" >&2
    exit 1
  }

  phase_165_tmp=$(mktemp -d /tmp/mailglass-v2.7-archive.XXXXXX)
  case "$(cd "$phase_165_tmp" && pwd -P)" in
    "$phase_165_repo" | "$phase_165_repo"/*)
      echo "phase165-archive: private config backup resolved inside repository" >&2
      exit 1
      ;;
  esac
  phase_165_original="$phase_165_tmp/config.original"
  phase_165_override="$phase_165_tmp/config.override"
  phase_165_init_json="$phase_165_tmp/init.json"
  phase_165_preview_json="$phase_165_tmp/preview.json"
  phase_165_preview_again_json="$phase_165_tmp/preview-again.json"
  phase_165_archive_json="$phase_165_tmp/archive.json"
  cp -- "$phase_165_config" "$phase_165_original"
  chmod 0600 "$phase_165_original"
  phase_165_restored=1

  phase_165_restore_config() {
    if [ "$phase_165_restored" -eq 0 ]; then
      if [ -n "${PHASE_165_RESTORE_COMMAND:-}" ]; then
        "$PHASE_165_RESTORE_COMMAND" "$phase_165_original" "$phase_165_config"
      else
        cp -- "$phase_165_original" "$phase_165_config"
      fi
      phase_165_restored=1
    fi
    cmp -s -- "$phase_165_original" "$phase_165_config" || {
      echo "phase165-archive: exact original config bytes were not restored" >&2
      return 1
    }
  }

  phase_165_cleanup() {
    phase_165_status=$?
    trap - EXIT
    if ! phase_165_restore_config; then phase_165_status=1; fi
    rm -rf -- "$phase_165_tmp"
    exit "$phase_165_status"
  }
  trap phase_165_cleanup EXIT
  trap 'exit 130' HUP INT TERM

  phase_165_apply_override() {
    /usr/bin/jq '.git.create_tag = false' "$phase_165_original" > "$phase_165_override"
    /usr/bin/jq -e '.git.create_tag == false' "$phase_165_override" >/dev/null
    /usr/bin/jq -S 'del(.git.create_tag)' "$phase_165_original" > "$phase_165_tmp/original.semantic"
    /usr/bin/jq -S 'del(.git.create_tag)' "$phase_165_override" > "$phase_165_tmp/override.semantic"
    cmp -s -- "$phase_165_tmp/original.semantic" "$phase_165_tmp/override.semantic" || {
      echo "phase165-archive: scoped override changed more than git.create_tag=false" >&2
      exit 1
    }
    cp -- "$phase_165_override" "$phase_165_config"
    phase_165_restored=0
  }

  phase_165_gsd() {
    if [ -n "${PHASE_165_GSD_RUN:-}" ]; then
      "$PHASE_165_GSD_RUN" "$@"
    else
      gsd_run "$@"
    fi
  }

  phase_165_initialize_and_preview() {
    phase_165_preview_target=$1
    phase_165_gsd query init.complete-milestone > "$phase_165_init_json" || {
      echo "phase165-archive: init.complete-milestone failed" >&2
      return 1
    }
    /usr/bin/jq -e '
      .section_manifest != null and
      ([.section_manifest.excluded[]?] | index("git-tag") != null) and
      ([.section_manifest.included[]?] | index("git-tag") == null)
    ' "$phase_165_init_json" >/dev/null || {
      echo "phase165-archive: section manifest does not exclude git-tag" >&2
      return 1
    }
    phase_165_gsd query milestone.complete v2.7 --name "$phase_165_name" --dry-run \
      > "$phase_165_preview_target" || {
      echo "phase165-archive: canonical archive dry-run failed" >&2
      return 1
    }
    /usr/bin/jq -e '
      .dry_run == true and .version == "v2.7" and
      .would_archive.audit != null and
      .would_archive.quick == [] and
      .would_archive.phases_archive_skipped == false and
      ([.would_archive.phases[] | capture("^(?<phase>16[1-5])(?:-|$)").phase] |
        sort | unique) == ["161", "162", "163", "164", "165"] and
      (.would_archive.phases | length) == 5
    ' "$phase_165_preview_target" >/dev/null || {
      echo "phase165-archive: preview lacks non-null audit, exact phases 161-165, or empty quick set" >&2
      return 1
    }
  }

  phase_165_apply_override
  phase_165_initialize_and_preview "$phase_165_preview_json"
  phase_165_preview_sha=$(shasum -a 256 "$phase_165_preview_json" | awk '{print $1}')

  if [ "$phase_165_mode" = preview ]; then
    printf 'approved_preview_sha256=%s\n' "$phase_165_preview_sha"
    cat "$phase_165_preview_json"
    phase_165_restore_config
    exit 0
  fi

  [ -n "$phase_165_approved_preview_sha" ] &&
    [ "$phase_165_preview_sha" = "$phase_165_approved_preview_sha" ] || {
    echo "phase165-archive: preview changed; obtain fresh approval" >&2
    exit 1
  }

  # Prove restoration before the irreversible call, then recreate and recheck the scoped state.
  phase_165_restore_config
  phase_165_apply_override
  phase_165_initialize_and_preview "$phase_165_preview_again_json"
  phase_165_preview_again_sha=$(shasum -a 256 "$phase_165_preview_again_json" | awk '{print $1}')
  [ "$phase_165_preview_again_sha" = "$phase_165_approved_preview_sha" ] || {
    echo "phase165-archive: preview changed after restoration proof; obtain fresh approval" >&2
    exit 1
  }

  phase_165_gsd query milestone.complete v2.7 --name "$phase_165_name" --confirm \
    > "$phase_165_archive_json" || {
    echo "phase165-archive: canonical archive confirmation failed" >&2
    exit 1
  }
  /usr/bin/jq -e '
    .version == "v2.7" and
    .archived.roadmap == true and .archived.requirements == true and
    .archived.audit == true and .archived.phases == true and
    .archived.phases_archive_skipped == false and .archived.quick == false
  ' "$phase_165_archive_json" >/dev/null || {
    echo "phase165-archive: canonical archive result is incomplete" >&2
    exit 1
  }
  phase_165_restore_config
  printf 'phase165-archive: canonical archive confirmed\n'
)
# phase165:tag-omission:end
```

## 3. The Single Blocking-Human Archive Checkpoint

Immediately before `--confirm`, display the verified dry-run tuple: audit source/target, exact phase
directory list 161-165, empty quick list, scope-not-skipped result, milestone name, version, and the
`approved_preview_sha256` value. Ask for exactly:

> `approve exact v2.7 archive preview`

Approval authorizes only `phase_165_complete_milestone_without_tag confirm <approved_preview_sha256>`.
The confirm mode performs a fresh dry run and a second same-process preview after proving restoration.
Any changed preview, manifest, config restoration behavior, or digest requires a new preview and new
approval. This is the runbook's only human checkpoint.

## 4. Canonical Archive and Final Tracked Convergence

After exact approval, run confirm mode without `--archive-quick`. The scoped function must restore and
byte-verify the original config before any later tracked-state reconciliation or commit. If initializer,
archive, restoration, archive-result, manifest-exclusion, or final byte-equality proof fails, stop; never
hand-run a partial archive or change repository-wide policy.

Using the normal complete-milestone workflow owners, reconcile every tracked archive output:

- `.planning/milestones/v2.7-ROADMAP.md`;
- `.planning/milestones/v2.7-REQUIREMENTS.md`;
- `.planning/milestones/v2.7-MILESTONE-AUDIT.md`;
- exactly `.planning/milestones/v2.7-phases/` for Phases 161-165;
- `.planning/MILESTONES.md`, `.planning/PROJECT.md`, `.planning/ROADMAP.md`, and `.planning/STATE.md`;
- any workflow-owned retrospective; and
- the live-ledger removals, including the canonical REQUIREMENTS removal, made by archival.

After the last human-authored Markdown edit, invoke `publishStateContract(cwd)` from
`/Users/jon/.codex/gsd-core/bin/lib/state-contract.cjs`. Continue only on exact
`{published: true, reason: "published"}`. Include `.planning/state.json` and every archive-related
tracked output in the final tracked commit. Make no further tracked write after that commit.

## 5. Protected Exact-SHA Evidence

Use only the existing protected integration route, with no bypass. Wait until the final tracked commit
is the clean local `HEAD == origin/main`. For that exact full SHA require one normal push CI record with
`attempt-1`, branch `main`, completed success, and no caller-selected run. Also require one completed,
successful, natural `schedule` event at attempt-1 and exact SHA for every registered scheduled control.
Absence is a wait/block, never authority to dispatch or rerun.

## 6. One Terminal Invocation and Hard Stop

After every prior gate passes, invoke the approved installed command by command name exactly once:

```text
mailglass-finalize-milestone v2.7
```

Require one ignored-only pass report bound to the final full SHA, exact canonical audit/archive
semantics, exact attempt-1 push CI, all natural attempt-1 schedules, and the final late clean/equal HEAD
rechecks. The report is volatile evidence and must not be staged or committed.

Then enforce a **hard stop**: no later v2.7 lifecycle write, terminal write, audit refresh, archive edit,
state publication, tag, or report rewrite is allowed. A future milestone is a separate authority.

## Explicitly Forbidden Operations

This runbook never dispatches or reruns a workflow or schedule; creates a local tag; pushes a tag;
deletes a branch; bypasses protected integration; closes any of the 14 PRs; creates a release; publishes
an artifact; mutates CI topology; changes dependencies; performs destructive cleanup; or changes
product, API, schema, or UI behavior.
