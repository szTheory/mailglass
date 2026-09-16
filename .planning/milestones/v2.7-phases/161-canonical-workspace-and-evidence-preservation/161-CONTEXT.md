# Phase 161: Canonical Workspace and Evidence Preservation - Context

**Gathered:** 2026-08-21 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish one explained, clean canonical `main` checkout and recoverably disposition every linked workspace, stash, relevant ref or divergent range, unreachable-object finding, and local release leftover. Phase 161 inventories and preserves evidence before cleanup; it does not reconcile remote PR, check, tag, Hex, or scheduled-automation state, which belongs to Phase 162.

</domain>

<decisions>
## Implementation Decisions

### Durable Pre-Mutation Evidence
- **D-01:** Create one tracked inventory before any cleanup mutation. It must record every linked worktree and its cleanliness, every stash, each relevant local or remote ref and divergent range, local release leftovers, and any unreachable Git-object findings selected for assessment.
- **D-02:** Each inventory entry must include an explicit `retain`, `handoff`, `merge`, `archive`, or `remove` disposition plus the unique-work, reachability, and evidence reference supporting that outcome.
- **D-03:** Dirty worktrees, stash contents, and unreachable or uncertain objects are preservation candidates until their contents and reachability have been assessed; absence from `main` is not evidence that they are disposable.

### Canonical Main Semantics
- **D-04:** `/Users/jon/projects/mailglass` on branch `main` is the sole canonical workspace for this phase.
- **D-05:** Record its clean but `ahead 7` relationship to `origin/main` as the v2.6 archive/retrospective and v2.7 initialization range. Do not normalize, reset, or discard that range merely to manufacture alignment.
- **D-06:** The canonical workspace is not release-clean until its upstream relationship is explicitly settled; a clean working tree alone is insufficient.

### Recoverability-First Disposition Boundary
- **D-07:** Retain or hand off every branch, detached candidate, stash, archive ref, and uncertain loose object until unique-work and reachability evidence is recorded.
- **D-08:** Before ordinary Git-managed removal, preserve unique or uncertain work on a named recoverable ref or in a documented handoff. Do not use bulk deletion, force removal, history rewriting, reset, or force-push cleanup.
- **D-09:** Phase 161 may identify and preserve local release leftovers, but it must hand remote release-state questions to Phase 162 rather than deciding the meaning of PR #222, checks, tags, Hex state, or scheduled automation.

### the agent's Discretion
- Exact tracked inventory filename and layout, provided it remains diffable, reviewable, and maps every inventoried item to evidence and a disposition.
- Exact ordering and batching of read-only Git evidence commands.
- Exact recoverable-ref names beyond following the repository's established named-preservation convention.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Contract
- `.planning/ROADMAP.md` § Phase 161 — fixed goal, success criteria, and handoff boundary with Phase 162.
- `.planning/REQUIREMENTS.md` § Workspace Integrity and Evidence Preservation — WSPC-01 through WSPC-04 and destructive-cleanup exclusions.
- `.planning/PROJECT.md` § Current Milestone: v2.7 Repository Stewardship & Operational Hygiene — milestone intent, target features, and maintenance-only scope locks.
- `.planning/STATE.md` § Accumulated Context — current sequencing and evidence-first project decisions.
- `.planning/METHODOLOGY.md` — decisive-by-default, honest-surface, and recommendation-first lenses that constrain planning.

### Existing Maintenance and Release Evidence
- `MAINTAINING.md` § Release Flow — canonical cleanliness and upstream-alignment requirements before release work.
- `MAINTAINING.md` § Publish Summary Snapshot Protocol — tracked publish summaries are release proof, not disposable scratch output.
- `dev/mix/tasks/mailglass.repo.hygiene.ex` — existing read-only audit and named `preserve/*` branch behavior; apply mode does not delete or merge work.
- `.planning/release-target.json` — current tracked local release ledger to inventory and preserve, without attempting Phase 162 reconciliation.
- `.planning/milestones/v2.6-phases/160-certification-documentation-and-release/160-06-SUMMARY.md` — durable record of the completed v2.6 protected publication and exact-Hex adoption evidence.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mix mailglass.repo.hygiene --check`: Existing read-only repository audit with text and JSON output.
- `Mix.Tasks.Mailglass.Repo.Hygiene.apply_safe_actions/1`: Existing narrow preservation behavior that creates a named `preserve/*` ref when local state is dirty or ahead, without deleting or merging work.
- Native Git plumbing and porcelain: `git worktree list --porcelain`, `git status`, `git stash`, `git branch`, `git rev-list`, `git merge-base`, `git log`, `git diff`, `git show`, `git tag`, and `git fsck` provide the required inventory, divergence, reachability, and unique-work evidence without new tooling.
- `.planning/publish/*-publish-summary.json`, `.planning/release-target.json`, and archived Phase 160 artifacts: Existing tracked evidence sources for identifying local release leftovers and preserving provenance.

### Established Patterns
- Release cleanliness is fail-closed: `MAINTAINING.md` and the hygiene task require a clean tree and zero ahead/behind drift, and unknown upstream state does not count as a pass.
- Preservation precedes cleanup: the existing hygiene apply path creates a recoverable branch and intentionally performs no deletion or merge.
- Planning and release artifacts are contractual or forensic proof. They must be classified individually rather than hidden by broad ignore rules.
- The current root `main` range ahead of `origin/main` is explained by seven v2.6 archive/retrospective and v2.7 planning commits, so divergence must be documented rather than treated as generic residue.
- The detached release-candidate worktree has modifications to all three tracked publish summaries; at least one stash and multiple unreachable commits also require content-level assessment before disposition.

### Integration Points
- Canonical workspace: `/Users/jon/projects/mailglass` on `main`.
- Linked workspace set: the four branch-attached `/private/tmp/mailglass-release-*` worktrees and the detached release-candidate worktree must be covered by the inventory.
- Git object set: the current stash, local and remote archive/release refs, divergent commit ranges, reflog/reachability findings, and local release proof artifacts feed the disposition record.
- Phase 162 handoff: unresolved remote release meanings and any retained recovery conditions must be explicit inputs to Protected Release and Scheduled-Control Recovery.

</code_context>

<specifics>
## Specific Ideas

No additional user-specified mechanics. Use the confirmed recoverability-first assumptions and established repository patterns.

</specifics>

<deferred>
## Deferred Ideas

- Remote PR #222, branch-protection, Actions-run, tag, published-Hex, and scheduled-control reconciliation — Phase 162.
- Database property-test and browser-gallery timeout repairs — Phase 163.
- Final maintainer documentation, tracked/generated artifact, ignore-rule, and repository-organization reconciliation — Phase 164.
- CI efficiency overhaul (SEED-006) — outside v2.7.

### Reviewed Todos (not folded)

None — no pending todos matched Phase 161.

</deferred>

---

*Phase: 161-canonical-workspace-and-evidence-preservation*
*Context gathered: 2026-08-21*
