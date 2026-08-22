# Phase 161: Canonical Workspace and Evidence Preservation - Research

**Researched:** 2026-08-21
**Domain:** Evidence-preserving local Git workspace stewardship
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### Deferred Ideas (OUT OF SCOPE)
- Remote PR #222, branch-protection, Actions-run, tag, published-Hex, and scheduled-control reconciliation — Phase 162.
- Database property-test and browser-gallery timeout repairs — Phase 163.
- Final maintainer documentation, tracked/generated artifact, ignore-rule, and repository-organization reconciliation — Phase 164.
- CI efficiency overhaul (SEED-006) — outside v2.7.
</user_constraints>

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| WSPC-01 | Record every linked worktree, stash, relevant refs/ranges, and release leftover before mutation. | Stable `git worktree list --porcelain -z`, `git status`, `git stash`, `for-each-ref`, and `rev-list` evidence sequence. [CITED: https://git-scm.com/docs/git-worktree] [CITED: https://git-scm.com/docs/git-rev-list] |
| WSPC-02 | Explain one clean canonical `main` checkout and its upstream state. | Root path, `main`, upstream, and ahead/behind evidence must be a dedicated inventory record, separate from release-clean verdict. [VERIFIED: codebase grep] |
| WSPC-03 | Give every item a supported disposition. | Inventory schema requires identity, content/unique-work evidence, reachability evidence, disposition, and handoff/reference. [VERIFIED: codebase grep] |
| WSPC-04 | Preserve unique or uncertain work before normal removal. | Existing `preserve/*` behavior, Git’s non-forced worktree removal guard, stash inspection/branching, and named-ref preservation support a no-force workflow. [VERIFIED: codebase grep] [CITED: https://git-scm.com/docs/git-worktree] [CITED: https://git-scm.com/docs/git-stash] |

## Summary

This is a repository-stewardship phase, not an application-stack change. The implementation should create a single tracked, reviewable inventory—recommended name `161-WORKSPACE-INVENTORY.md`—before performing any cleanup. It should capture reproducible command output references and a disposition matrix for each worktree, stash, ref/range, selected unreachable object, and local release artifact. [VERIFIED: codebase grep]

The current repository confirms six worktrees: the canonical root plus five linked release worktrees. The detached candidate is dirty in all three tracked publish-summary snapshots; one stash contains a planning-config switch and a publish-summary size change. Both are evidence-bearing preservation candidates, not removable scratch state. [VERIFIED: local Git inspection]

The root workspace is clean and `main` tracks `origin/main`, but current live inspection shows `0 behind, 9 ahead`, not release-clean. The locked “ahead 7” range is still present as the v2.6 archive/retrospective plus v2.7 initialization history; two additional Phase 161 context/state commits account for the current total. Record both the locked semantic explanation and the exact measurement captured at inventory time; do not reset or otherwise normalize it. [VERIFIED: local Git inspection] [VERIFIED: codebase grep]

**Primary recommendation:** Create the tracked inventory first, prove reachability and content before each disposition, create a named `preserve/*` ref or handoff for every uncertain/unique item, then use only normal non-force Git-managed operations.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Canonical checkout status and divergence proof | Local Git repository | Tracked planning artifact | Git is authoritative for branch/upstream/reachability; the artifact makes the result reviewable. [VERIFIED: local Git inspection] |
| Linked-worktree discovery and safe retirement | Local Git repository | Filesystem | Git tracks linked worktree metadata and refuses non-forced removal of dirty trees. [CITED: https://git-scm.com/docs/git-worktree] |
| Stash and unreachable-object preservation | Local Git object database | Named refs / documented handoff | Stashes are commit-backed; reachability governs recoverability. [CITED: https://git-scm.com/docs/git-stash] [CITED: https://git-scm.com/docs/git-fsck] |
| Release-leftover classification | Tracked planning/release evidence | Phase 162 handoff | Local ledgers and publish summaries are proof artifacts; external release meaning remains deferred. [VERIFIED: codebase grep] |

## Project Constraints (from CLAUDE.md)

- Do not add a Node toolchain or new generic maintenance service; this repository is Mix/Elixir plus native Git. [VERIFIED: CLAUDE.md]
- Treat planning and release artifacts as contractual/forensic proof; do not broadly ignore or delete `.planning/` or publish evidence. [VERIFIED: CLAUDE.md] [VERIFIED: codebase grep]
- Use Conventional Commits, preserve current maintenance-only scope, and do not perform a ceremonial release. [VERIFIED: CLAUDE.md] [VERIFIED: codebase grep]
- Do not update `.planning/STATE.md` manually; GSD manages state. [VERIFIED: CLAUDE.md]
- Respect all phase exclusions: no reset, force removal, bulk deletion, history rewriting, force-push, or remote-release reconciliation. [VERIFIED: codebase grep]

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| Git | 2.41.0 installed | Worktree, ref, stash, divergence, and object reachability inspection/removal. | Native Git exposes the required evidence without a new dependency. [VERIFIED: local Git inspection] [CITED: https://git-scm.com/docs/git-worktree] |
| Existing `mix mailglass.repo.hygiene` task | repository source | Root audit and named `preserve/*` branch precedent. | Its `--check` path is read-only and `--apply` only creates a preservation branch for dirty/ahead state. [VERIFIED: codebase grep] |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| Mix / Elixir | Mix 1.19.5 / Elixir 1.19.5 | Run existing hygiene and focused test commands when dependencies are resolved. | Verify existing behavior; do not introduce a new CLI. [VERIFIED: local environment] |
| GitHub CLI | 2.95.0 installed | Existing hygiene task’s optional remote checks. | Only for Phase 162 handoff context; do not resolve remote release state in this phase. [VERIFIED: local environment] [VERIFIED: codebase grep] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Native Git evidence commands | New worktree-cleanup tool or custom service | Rejected: out of scope and duplicates authoritative local Git data. [VERIFIED: codebase grep] |
| Diffable Markdown inventory | Ephemeral shell transcript only | Rejected: a transcript cannot meet tracked/reviewable per-item disposition requirements. [VERIFIED: codebase grep] |

**Installation:** No external packages are required or permitted for this phase. [VERIFIED: codebase grep]

## Architecture Patterns

### System Architecture Diagram

```text
Read-only local evidence
  worktree list/status ─┐
  stash show/list ──────┼──> tracked 161-WORKSPACE-INVENTORY.md
  refs/ranges/log/diff ─┤        │ identity + content + reachability
  fsck/reflog evidence ─┤        v
  release proof files ──┘   disposition gate
                               ├─ retain / archive / merge: documented ref + evidence
                               ├─ handoff: explicit Phase 162 condition/reference
                               └─ remove: only after no unique/uncertain work remains
                                        │
                                        v
                              normal non-force Git-managed action
```

The workflow is deliberately one-way: evidence and a recoverable reference/handoff must exist before any mutation. [VERIFIED: codebase grep] [CITED: https://git-scm.com/docs/git-worktree]

### Recommended Artifact Structure

```text
.planning/phases/161-canonical-workspace-and-evidence-preservation/
├── 161-WORKSPACE-INVENTORY.md  # tracked pre-mutation evidence and disposition matrix
├── 161-RESEARCH.md             # planning research
└── 161-VALIDATION.md           # Nyquist requirement-to-proof map
```

### Pattern 1: Snapshot → Assess → Preserve → Act

**What:** Make a stable, committed inventory; inspect content and reachability; preserve unique/uncertain work on a named ref or handoff; only then use ordinary Git removal. [VERIFIED: codebase grep]

**When to use:** Every candidate worktree, stash, local/remote ref, divergent range, fsck-selected object, and release artifact. [VERIFIED: codebase grep]

**Example:**

```bash
# Source: https://git-scm.com/docs/git-worktree
git worktree list --porcelain -z
git -C /private/tmp/mailglass-release-candidate.3B6UyC status --short --branch

# Source: https://git-scm.com/docs/git-rev-list
git rev-list --left-right --count main...fix/release-ci-recovery
git log --left-right --cherry-mark --oneline main...fix/release-ci-recovery

# Source: https://git-scm.com/docs/git-fsck
git fsck --no-reflogs --unreachable --no-dangling
```

### Pattern 2: Every row has independently reproducible evidence

**What:** Use one inventory table row per item with these required fields: identity/path/ref/object ID; observed state; content/unique-work evidence command and result; reachability evidence command and result; disposition; preservation ref or handoff; allowed next action. [VERIFIED: codebase grep]

**When to use:** Before any command that changes a worktree registration, branch, stash, ref, or local file. [VERIFIED: codebase grep]

### Anti-Patterns to Avoid

- **Age-based cleanup:** A stale date does not prove lack of unique content or reachability. Use range/diff/object evidence. [CITED: https://git-scm.com/docs/git-branch]
- **Treating a clean tree as release-clean:** The existing task blocks on dirty, ahead, or behind state; the canonical root is currently ahead. [VERIFIED: codebase grep] [VERIFIED: local Git inspection]
- **Using `git worktree remove --force`, `git branch -D`, stash clear/drop, reset, or gc as discovery shortcuts:** They remove safeguards or put evidence at pruning risk; they contradict locked decisions. [CITED: https://git-scm.com/docs/git-worktree] [CITED: https://git-scm.com/docs/git-stash] [VERIFIED: codebase grep]
- **Explaining external PR/tag/Hex state in this phase:** Record a handoff only; Phase 162 owns remote truth. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Worktree enumeration | Path/glob scanner | `git worktree list --porcelain -z` | Porcelain is stable and includes branch/detached/lock/prunable metadata. [CITED: https://git-scm.com/docs/git-worktree] |
| Ahead/behind and unique-commit proof | Custom graph parser | `git rev-list --left-right --count` plus `--cherry-mark` / logs | Git computes symmetric-difference reachability and count. [CITED: https://git-scm.com/docs/git-rev-list] |
| Stash extraction | Manual `.git` internals inspection | `git stash show --include-untracked`; `git stash branch` when preservation is chosen | Git models stash index/worktree state and can branch from the original base. [CITED: https://git-scm.com/docs/git-stash] |
| Object reachability check | Custom loose-object walker | `git fsck --no-reflogs --unreachable --no-dangling` and `git show` | Git’s object graph traversal distinguishes ref/reflog reachability and reports candidate objects. [CITED: https://git-scm.com/docs/git-fsck] |

**Key insight:** Git’s reachability and refusal guards are the safety mechanism; the phase needs a durable decision record around them, not a replacement implementation. [CITED: https://git-scm.com/docs/git-worktree]

## Runtime State Inventory

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | Git object database contains stash entries and many `fsck --no-reflogs --unreachable` candidates, including unreachable commits; selected candidates require `git show`, ancestry, and a named ref/handoff before any removal. [VERIFIED: local Git inspection] | Evidence assessment; preservation ref or documented handoff. |
| Live service config | None for Phase 161 — remote PR/check/tag/Hex/scheduled-control state is explicitly Phase 162. [VERIFIED: codebase grep] | Record Phase 162 handoff only. |
| OS-registered state | Six Git-registered worktrees: root plus five `/private/tmp/mailglass-release-*` worktrees. [VERIFIED: local Git inspection] | Inventory each; use normal `git worktree remove` only after clean/no-unique proof and no force. |
| Secrets / env vars | None found that must change; `GH_TOKEN` is only an optional prerequisite of existing remote checks and is not part of Phase 161 cleanup. [VERIFIED: codebase grep] | None. |
| Build artifacts / installed packages | Three modified tracked publish-summary snapshots in the detached candidate; the root also tracks `.planning/release-target.json` and publish proof. [VERIFIED: local Git inspection] [VERIFIED: codebase grep] | Classify as release proof, preserve/hand off rather than discard. |

## Common Pitfalls

### Pitfall 1: Confusing reachability with value

**What goes wrong:** A commit absent from `main`, an unreachable object, or an old branch is deleted as “leftover.” [CITED: https://git-scm.com/docs/git-fsck]

**Why it happens:** `fsck --no-reflogs` intentionally reports objects excluded from reflog reachability, and dangling commits can be roots of history. [CITED: https://git-scm.com/docs/git-fsck]

**How to avoid:** Inspect content and ancestry; create `preserve/<descriptive-name>-<date>` at the object or use a documented handoff before removal. [VERIFIED: codebase grep]

**Warning signs:** A disposition has only age or “not on main” as evidence, or a command contains `--force`, `-D`, `clear`, `drop`, `reset`, `gc`, or `prune` before preservation. [VERIFIED: codebase grep]

### Pitfall 2: Losing uncommitted release proof

**What goes wrong:** The dirty detached candidate is removed before its three publish-summary diffs are classified. [VERIFIED: local Git inspection]

**Why it happens:** The files look generated, but repository policy defines publish summaries as tracked release proof. [VERIFIED: codebase grep]

**How to avoid:** Include diff stat/content, base commit, and disposition in the inventory; preserve the candidate’s HEAD and diff-bearing state before any worktree action. [VERIFIED: local Git inspection]

**Warning signs:** A plan proposes `git worktree remove` while the candidate status is dirty. Git itself rejects a non-forced removal of an unclean tree. [CITED: https://git-scm.com/docs/git-worktree]

### Pitfall 3: Manufacturing canonical alignment

**What goes wrong:** A reset or discard action makes `main` appear aligned, erasing the documented v2.6/v2.7 range. [VERIFIED: codebase grep]

**Why it happens:** Clean worktree and upstream alignment are separate conditions. [VERIFIED: codebase grep]

**How to avoid:** Record current `@{upstream}` and `rev-list` counts plus the exact commit log; leave settlement to a later protected decision. [VERIFIED: codebase grep] [CITED: https://git-scm.com/docs/git-rev-list]

## Code Examples

### Capture canonical state and divergent range

```bash
# Source: https://git-scm.com/docs/git-rev-list
git -C /Users/jon/projects/mailglass status --short --branch
git -C /Users/jon/projects/mailglass rev-parse --abbrev-ref --symbolic-full-name '@{upstream}'
git -C /Users/jon/projects/mailglass rev-list --left-right --count '@{upstream}...HEAD'
git -C /Users/jon/projects/mailglass log --left-right --cherry-mark --oneline '@{upstream}...HEAD'
```

### Preserve a stash without destructive clearing

```bash
# Source: https://git-scm.com/docs/git-stash
git stash list --date=iso
git stash show --stat --include-untracked 'stash@{0}'
git stash show --patch --include-untracked 'stash@{0}'
# If disposition is preserve: git stash branch preserve/pre-cleanup-state-20260821 'stash@{0}'
```

### Assess unreachable commits before disposition

```bash
# Source: https://git-scm.com/docs/git-fsck
git fsck --no-reflogs --unreachable --no-dangling
git show --stat --format=fuller <object-id>
git branch --contains <object-id>
git tag --contains <object-id>
# If unique or uncertain: git branch preserve/fsck-<short-object-id>-20260821 <object-id>
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Ad hoc manual deletion of extra checkouts | `git worktree` porcelain inventory plus normal removal guards | Current Git documentation | Scripts can use stable attributes and Git blocks non-force removal of dirty worktrees. [CITED: https://git-scm.com/docs/git-worktree] |
| “Branch is old / absent from main” cleanup | Reachability + content evidence + explicit disposition | Existing project hygiene policy | Prevents loss of unique commits, stashes, and forensic release artifacts. [VERIFIED: codebase grep] |

**Deprecated/outdated:** Broad cleanup actions (`git worktree remove --force`, `git branch -D`, `git stash clear`, reset, history rewrite, force push) are prohibited by the phase contract. [VERIFIED: codebase grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | None. | — | All implementation-relevant claims were verified locally or cited from official Git documentation. |

## Open Questions

1. **How should the inventory state the canonical ahead count?**
   - What we know: the locked decision describes an explained `ahead 7` archive/initialization range; current inspection is `ahead 9`, including two Phase 161 context/state commits. [VERIFIED: local Git inspection] [VERIFIED: codebase grep]
   - What's unclear: the exact count will change again when the inventory itself is committed.
   - Recommendation: state the measurement timestamp and full commit list, then separately identify the fixed seven-commit semantic range and later planning commits. This preserves the locked decision without presenting a stale count as a live measurement. [VERIFIED: local Git inspection]

2. **Which unreachable commits merit named preservation refs versus documented removal?**
   - What we know: the object database contains many unreachable commits across historical phases. [VERIFIED: local Git inspection]
   - What's unclear: content/reachability classification has not yet been recorded per selected candidate.
   - Recommendation: triage commits first by `git show`, `branch --contains`, `tag --contains`, and patch/ancestry comparison; preserve whenever evidence is incomplete or non-duplicate. [CITED: https://git-scm.com/docs/git-fsck] [CITED: https://git-scm.com/docs/git-branch]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Git | All WSPC evidence and managed cleanup | ✓ | 2.41.0 | None — required. [VERIFIED: local environment] |
| Mix / Elixir | Existing hygiene task and focused regression test | ✓ | 1.19.5 / 1.19.5 | Shell evidence remains available when dependencies are unresolved. [VERIFIED: local environment] |
| GitHub CLI | Existing optional hygiene remote checks / Phase 162 handoff only | ✓ | 2.95.0 | Record cannot-check if authentication/access is absent. [VERIFIED: local environment] [VERIFIED: codebase grep] |

**Missing dependencies with no fallback:** None for the Git inventory. [VERIFIED: local environment]

**Missing dependencies with fallback:** Mix dependency resolution is currently blocked by lock mismatches for `req` and `swoosh`; use read-only Git validation until the existing locked dependencies are restored by a separately authorized step. [VERIFIED: local command output]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit; existing task tests in `test/mix/tasks/mailglass.repo.hygiene_test.exs`. [VERIFIED: codebase grep] |
| Config file | `config/test.exs`; existing Mix project. [VERIFIED: codebase grep] |
| Quick run command | `mix test test/mix/tasks/mailglass.repo.hygiene_test.exs` — currently blocked locally until `req` and `swoosh` lock mismatches are resolved. [VERIFIED: local command output] |
| Full suite command | `mix test` — not needed for inventory-only artifact validation; execute only after dependencies are clean. [VERIFIED: codebase grep] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| WSPC-01 | Inventory enumerates all linked worktrees, stash, relevant refs/ranges, release leftovers, and selected fsck candidates before mutations. | Artifact + shell integration | `git worktree list --porcelain -z`; `git stash list`; `git for-each-ref`; `git fsck --no-reflogs --unreachable --no-dangling`; compare each result to inventory rows. | ❌ Wave 0: `161-VALIDATION.md` checklist. |
| WSPC-02 | Canonical root is `main`, clean, upstream-bearing, and its exact ahead/behind count/range are explained. | Shell integration | `git -C /Users/jon/projects/mailglass status --short --branch`; `git rev-list --left-right --count '@{upstream}...HEAD'`; inventory cross-check. | ❌ Wave 0: `161-VALIDATION.md` checklist. |
| WSPC-03 | Each inventory row contains an allowed disposition plus content, unique-work, reachability, and evidence reference. | Artifact schema review | `rg -n 'retain|handoff|merge|archive|remove' .planning/phases/161-canonical-workspace-and-evidence-preservation/161-WORKSPACE-INVENTORY.md`; manual row completeness review. | ❌ Wave 0: explicit inventory schema section. |
| WSPC-04 | Every unique/uncertain candidate is recoverably preserved before a normal Git-managed removal. | Shell integration + manual safety review | `git show-ref --verify refs/heads/preserve/<name>` or handoff reference, then `git worktree remove <clean-path>` / normal `git branch -d <name>` only when evidence permits. | ❌ Wave 0: preservation-before-removal checklist. |

### Sampling Rate

- **Per task commit:** Re-run the relevant read-only Git commands and verify the inventory diff reflects any state change. [VERIFIED: local Git inspection]
- **Per wave merge:** Re-run the entire WSPC-01 command set and compare it against dispositions. [VERIFIED: local Git inspection]
- **Phase gate:** No cleanup item may be marked removed without its prior preservation/evidence row; canonical root must remain clean and its non-release-clean upstream state must be explicit. [VERIFIED: codebase grep]

### Wave 0 Gaps

- [ ] `161-VALIDATION.md` — requirement-to-command/checklist proof for WSPC-01 through WSPC-04.
- [ ] `161-WORKSPACE-INVENTORY.md` — durable schema and first pre-mutation snapshot.
- [ ] Resolve the already-locked `req` and `swoosh` dependency state before relying on the ExUnit hygiene-task regression command; do not change dependencies as Phase 161 work. [VERIFIED: local command output]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | No new authentication surface. [VERIFIED: codebase grep] |
| V3 Session Management | No | No session surface. [VERIFIED: codebase grep] |
| V4 Access Control | Yes | Phase boundary prohibits deciding remote PR/release state; privileged remote actions remain Phase 162. [VERIFIED: codebase grep] |
| V5 Input Validation | Yes | Existing Mix task strictly parses flags; new evidence commands should use fixed argument lists and quote refs/paths. [VERIFIED: codebase grep] |
| V6 Cryptography | No | No cryptographic implementation or secret handling is introduced. [VERIFIED: codebase grep] |

### Known Threat Patterns for local Git stewardship

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Accidental loss of unique local work | Tampering / Availability | Preserve named ref or documented handoff before any removal; prohibit force/reset/history rewrite. [VERIFIED: codebase grep] |
| Incomplete inventory creates false cleanup confidence | Tampering | Use stable Git porcelain/refs/fsck commands and compare every result to a disposition row. [CITED: https://git-scm.com/docs/git-worktree] [CITED: https://git-scm.com/docs/git-fsck] |
| Release proof mistaken for generated junk | Repudiation | Treat publish summaries and release ledger as tracked evidence; hand external interpretation to Phase 162. [VERIFIED: codebase grep] |
| Shell/ref parsing ambiguity | Tampering | Use porcelain/NUL where available and fixed, quoted argument lists; do not parse `.git` internals directly. [CITED: https://git-scm.com/docs/git-worktree] |

## Sources

### Primary (HIGH confidence)

- Local Git inspection — worktrees, dirty detached candidate, stash content, refs, divergence, and fsck candidates.
- Repository sources: `dev/mix/tasks/mailglass.repo.hygiene.ex`, `test/mix/tasks/mailglass.repo.hygiene_test.exs`, `MAINTAINING.md`, `.planning/release-target.json`, and Phase 160 summary.

### Secondary (MEDIUM confidence)

- [Git worktree documentation](https://git-scm.com/docs/git-worktree) — porcelain format, clean-removal guard, lock, and linked-worktree semantics.
- [Git fsck documentation](https://git-scm.com/docs/git-fsck) — reachability, reflog exclusion, dangling-object interpretation.
- [Git stash documentation](https://git-scm.com/docs/git-stash) — stash content model and branch restoration.
- [Git rev-list documentation](https://git-scm.com/docs/git-rev-list) and [Git branch documentation](https://git-scm.com/docs/git-branch) — divergence counts, merged/non-merged and safe branch deletion semantics.

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — native Git, installed versions, and existing task verified locally.
- Architecture: HIGH — locked phase decisions and actual repository state directly define the required flow.
- Pitfalls: HIGH — confirmed dirty worktree/stash/object findings plus official Git safeguards.

**Research date:** 2026-08-21
**Valid until:** 2026-08-28 for live workspace facts; Git command semantics are stable but should be re-run immediately before execution.
