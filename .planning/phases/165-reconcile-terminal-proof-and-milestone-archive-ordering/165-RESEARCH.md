# Phase 165: Reconcile terminal proof and milestone archive ordering - Research

**Researched:** 2026-09-13
**Domain:** Repository lifecycle attestation, GSD milestone archival, and protected-main evidence
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Lifecycle authority and ordering
- **D-01:** Treat `tmp/phase-164-finalize.FGINGn/report.json` as immutable historical evidence for Phase 164 at `851e3640f7f0eb6e784611d157e3a7329f87e2dc`; never edit, rerun, or cite it as authority for Phase 165 or the archived milestone.
- **D-02:** Add a separate, narrowly v2.7-scoped milestone terminal authority. Leave `/Users/jon/.local/bin/mailglass-finalize-phase 164` and its Phase 164 contract unchanged.
- **D-03:** The milestone authority must expose one installed command accepting only `v2.7`, authenticate the final archived layout, and write only ignored evidence.
- **D-04:** Enforce this order: reconcile metadata and terminal machinery; validate, verify, and complete Phase 165; write a passing canonical audit; preview and execute the full milestone archive; finish every archive-related tracked commit and protected integration; obtain exact attempt-one push CI and natural scheduled evidence for that final archive SHA; run the milestone finalizer once.
- **D-05:** No later v2.7 lifecycle mutation may follow terminal capture. Future milestones are outside the proof's exact archived-SHA claim.

### Minimal reconciliation and scope
- **D-06:** Repair the strict three-source metadata by adding `WSPC-01`, `WSPC-03`, and `WSPC-04` to the appropriate Phase 161 summary frontmatter. The planner must confirm the smallest truthful summary placement against plan ownership; `161-04-SUMMARY.md` is the preferred target because Plan 161-04 owns the final workspace-requirement verification task.
- **D-07:** Re-run validation for Phases 161 and 163 so current validation records use the workflow-recognized `status: validated` while preserving their existing green Nyquist evidence.
- **D-08:** Reconcile ROADMAP, PROJECT, STATE, and `state.json` so they include Phase 165 and contain no stale claim that the Phase 164 terminal step remains pending or is still authoritative for milestone completion.
- **D-09:** Phase 165 receives no new REQ-ID and does not remap the sixteen existing v2.7 requirements.
- **D-10:** Preserve the evidence-backed repository-hygiene policy block. Do not close the fourteen PRs, force a release, change product behavior or workflow topology, upgrade dependencies, or perform destructive cleanup.
- **D-11:** Exclude legacy quick tasks from v2.7 archival because the current completion workflow cannot attribute them accurately to this milestone.

### Verification and operator contract
- **D-12:** Phase 165 needs both an ordinary pre-archive gate and a terminal post-archive gate. Ordinary verification must include focused negative coverage for stale audit data, incomplete archive layout, dirty or moving HEAD, caller-selected or rerun CI, non-natural schedules, and tracked-output leakage.
- **D-13:** Before archival, the canonical audit must report no critical gaps, strict requirements `16/16`, phases `5/5`, integration `16/16`, flows `5/5`, and compliant validation for all five phases. The PR-hygiene policy block remains explicitly disclosed as accepted operational debt.
- **D-14:** The archive dry-run must identify a non-null audit target and exactly Phases 161–165, with quick tasks excluded. Completion must archive ROADMAP, REQUIREMENTS, the canonical audit, and all five phase directories; MILESTONES, PROJECT, STATE, and `state.json` must agree that v2.7 is complete and archived.
- **D-15:** The final milestone report must pass at exact clean `HEAD == origin/main`, authenticate the archived evidence, use exact attempt-one push CI and natural attempt-one schedules, and prove no later v2.7 write.
- **D-16:** Existing approval covers repository-local planning, metadata repair, tests, audit generation, and archive dry-run. Require a fresh exact-tuple approval before creating or changing an installed external terminal executable, and require explicit `--confirm` immediately before the milestone archive mutation.
- **D-17:** Remote tag push, branch deletion, workflow dispatch or rerun, merge bypass, release, and publication remain unauthorized.

### the agent's Discretion
- Exact repository-local module names and internal decomposition for the v2.7 finalizer.
- Exact test-fixture organization and diagnostic wording, provided the authority and negative-case requirements above remain fail-closed.
- Whether machine-state reconciliation is performed by existing GSD helpers or a narrowly scoped repository utility, provided all tracked sources converge truthfully.

### Deferred Ideas (OUT OF SCOPE)

- Closing the fourteen policy-blocked PRs, creating a release, pushing a tag, deleting branches, publishing artifacts, changing workflow topology, dependency upgrades, and product/API/schema/UI work are outside Phase 165.
- Historical quick-task archival is excluded rather than misattributed to v2.7.

### Reviewed Todos (not folded)

None — no pending todo matched Phase 165.
</user_constraints>

## Summary

Phase 165 is a lifecycle-ordering correction, not a feature phase. The historical Phase 164 report records `"expected_main_sha": "851e3640f7f0eb6e784611d157e3a7329f87e2dc"`, `"ci_run_id": "34728247096"`, and `"status": "pass"`; its hygiene component separately records `"status": "blocked"` and `"reason": "14 open PR(s) require disposition before release."` [VERIFIED: tmp/phase-164-finalize.FGINGn/report.json:2-18,31-43] Phase 165 must preserve that report, repair the bookkeeping which the strict milestone audit exposed, then establish a new authority over the final archived commit.

The baseline audit is precise about the current defects: `status: gaps_found`, `requirements: 13/16`, `phases: 4/4`, `integration: 16/16`, `flows: 5/5`; `WSPC-01`, `WSPC-03`, and `WSPC-04` lack SUMMARY claims; Phases 161 and 163 are not workflow-classified as validated; and the canonical audit was not written. [VERIFIED: tmp/v2.7-MILESTONE-AUDIT.md:1-61] These are metadata and lifecycle gaps only: the same audit records no orphaned requirements, `16/16` wired integrations, and `5/5` complete flows. [VERIFIED: tmp/v2.7-MILESTONE-AUDIT.md:64-73,90-125]

The decisive planning fact is that `milestone.complete --confirm` is not the last tracked mutation. It archives the source documents and phase directories, but the workflow then reorganizes ROADMAP, makes an archive safety commit, removes live REQUIREMENTS, writes the retrospective, and updates STATE. [VERIFIED: /Users/jon/.codex/gsd-core/workflows/complete-milestone.md:520-564,566-632,634-715] Therefore the finalizer must bind the commit after every archive-related tracked write and state reconciliation, not the commit created by the archive command itself.

**Primary recommendation:** Plan Phase 165 as a single fail-closed chain: metadata repair → separate milestone-finalizer implementation and fixture proof → ordinary Phase 165 verification/completion → passing canonical audit → exact dry-run gate → explicit archive confirmation → all post-archive tracked commits and state publication → protected final SHA → attempt-one push CI plus natural attempt-one schedules → one installed terminal capture → immutable stop.

## Phase Requirements

Phase 165 intentionally receives no new requirement ID. The existing traceability table quotes `"v2.7 requirements: 16 total"`, `"Mapped to phases: 16"`, and `"Unmapped: 0"`; its rows remain assigned only to Phases 161–164. [VERIFIED: .planning/REQUIREMENTS.md:55-82] The planner should map Phase 165 tasks to context decisions D-01 through D-17 and to phase success criteria, not modify requirement ownership.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Strict metadata reconciliation | Repository planning metadata | GSD audit | REQUIREMENTS, VERIFICATION, SUMMARY, and VALIDATION are the audit's independent inputs. [VERIFIED: /Users/jon/.codex/gsd-core/workflows/audit-milestone.md:110-180] |
| Ordinary Phase 165 gate | Repository test/verification tier | Protected CI | Fixture-backed contracts prove behavior before archive state exists. [VERIFIED: test/scripts/phase_164_closeout_test.exs:139-175; mix.exs:294-313] |
| Milestone archive mutation | GSD lifecycle tier | Git history | The completion command owns archive copies, audit movement, phase-directory moves, and state publication. [VERIFIED: /Users/jon/.codex/gsd-core/bin/lib/milestone.cjs:811-887,1077-1161] |
| Final archive convergence | Git/repository tier | GSD state publisher | Later workflow edits must finish before the final SHA is selected. [VERIFIED: /Users/jon/.codex/gsd-core/workflows/complete-milestone.md:558-632,634-715] |
| Remote evidence | GitHub Actions service boundary | Local finalizer | The existing selector requires exact `"CI"`, `"push"`, attempt `1`, branch `"main"`, exact SHA, completed success; schedules require attempt `1`, event `"schedule"`, branch `"main"`, and exact SHA. [VERIFIED: scripts/finalize_phase_164.sh:88-108,198-242] |
| Terminal attestation | Host-installed authority | Ignored `tmp/` evidence | The loader pattern authenticates a captured Git commit and private materialization before dispatch, while report output remains outside tracked authority. [VERIFIED: scripts/mailglass_finalize_phase_loader.mjs:240-250,295-370,476-527; scripts/finalize_phase_164.sh:245-280] |

## Standard Stack

### Core

No new package or dependency is needed; `.planning/REQUIREMENTS.md` explicitly places `"Dependency, action, Beam, Node, browser, or database upgrades"` out of scope. [VERIFIED: .planning/REQUIREMENTS.md:40-53]

| Tool | Verified Version | Purpose | Why Standard Here |
|---|---:|---|---|
| Node.js | `v24.19.0` | Installed loader, SHA-256, private materialization, bounded subprocesses | Existing authority pins `NODE: "/Users/jon/.asdf/installs/nodejs/24.19.0/bin/node"`. [VERIFIED: scripts/mailglass_finalize_phase_loader.mjs:1-35; executable `--version` probe] |
| Git | `2.41.0` pinned authority | Exact commit/blob/index/history and clean-tree checks | Existing authority pins `GIT: "/opt/homebrew/Cellar/git/2.41.0/bin/git"`. [VERIFIED: scripts/mailglass_finalize_phase_loader.mjs:26-35; executable `--version` probe] |
| GNU Bash | `5.2.37` | Fail-closed orchestration of repository and evidence checks | Existing authority pins `BASH: "/opt/homebrew/Cellar/bash/5.2.37/bin/bash"`. [VERIFIED: scripts/mailglass_finalize_phase_loader.mjs:26-35; executable `--version` probe] |
| GitHub CLI | `2.95.0` | Read-only protected run and repository identity queries | Existing authority pins `GH: "/opt/homebrew/Cellar/gh/2.95.0/bin/gh"`. [VERIFIED: scripts/mailglass_finalize_phase_loader.mjs:26-35; executable `--version` probe] |
| jq | `1.7.1-apple` | Closed-shape CI and schedule evidence validation | Existing authority pins `JQ: "/usr/bin/jq"`. [VERIFIED: scripts/mailglass_finalize_phase_loader.mjs:26-35; executable `--version` probe] |
| Mix/Elixir | `1.19.5` | ExUnit fixture and installed-boundary contract tests | Existing authority quotes `EXPECTED_ELIXIR_VERSION = "1.19.5"`. [VERIFIED: scripts/mailglass_finalize_phase_loader.mjs:32-47; sanitized executable probes] |
| Erlang/OTP | `28` | Physical BEAM closure authenticated by loader | Existing authority quotes `EXPECTED_OTP_RELEASE = "28"`. [VERIFIED: scripts/mailglass_finalize_phase_loader.mjs:32-47,193-230; sanitized executable probe] |
| GSD milestone/audit workflows | installed local runtime | Canonical three-source audit, archive dry-run/mutation, and state publication | These workflows already own the lifecycle semantics; Phase 165 should compose them, not fork them. [VERIFIED: /Users/jon/.codex/gsd-core/workflows/audit-milestone.md:110-227; /Users/jon/.codex/gsd-core/workflows/complete-milestone.md:508-632] |

### Supporting

| Facility | Version/Contract | Purpose | When to Use |
|---|---|---|---|
| ExUnit | project existing | Hostile disposable-repository fixtures and controlled-host isolation | Every repository-local finalizer behavior; keep installed-host tests opt-in. [VERIFIED: mix.exs:294-313; test/test_helper.exs:45-53] |
| Git porcelain v1 | `--porcelain=v1 --untracked-files=all` | Stable machine-readable cleanliness | At entry, after each evidence-producing component, before report publication, and at final return. [CITED: https://git-scm.com/docs/git-status] |
| GitHub Actions context semantics | `run_attempt` starts at `1` and increments on rerun | Reject rerun evidence and bind trigger/SHA identity | Remote CI and schedule evidence selection. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/contexts] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Separate v2.7 milestone authority | Broaden the Phase 164 loader | Rejected by locked D-02; the Phase 164 loader quotes `SUPPORTED_PHASE = "164"` and live Phase 164 dependencies. [VERIFIED: scripts/mailglass_finalize_phase_loader.mjs:20-94] |
| Canonical GSD archive command | Manual copy/move scripts | Loses the command's single scope derivation, dry-run parity, safety guards, and state publication. [VERIFIED: /Users/jon/.codex/gsd-core/bin/lib/milestone.cjs:790-865,1077-1161] |
| Existing state publisher | Hand-authored `state.json` | Creates a second interpretation of milestone, phase, and smart-entry state. [VERIFIED: /Users/jon/.codex/gsd-core/bin/lib/state-contract.cjs:3-43,267-359] |

**Installation:** No package installation. Creating or changing the external milestone executable is a separate human-approved exact-tuple file mutation, not dependency installation.

## Package Legitimacy Audit

Not applicable. Phase 165 installs no external package and changes no dependency manifest. [VERIFIED: .planning/REQUIREMENTS.md:40-53]

## Architecture Patterns

### System Architecture Diagram

```text
Tracked metadata repair
  ├─ Phase 161 SUMMARY claims
  ├─ Phase 161/163 validation reruns
  └─ ROADMAP / PROJECT / STATE / state.json convergence
                │
                v
Separate v2.7 finalizer source + disposable archived-layout tests
                │
                v
Ordinary Phase 165 validation + verification + completion
                │
                v
Canonical milestone audit
  ├─ fail if score != 16/16, 5/5, 16/16, 5/5
  ├─ fail if any validation is not compliant
  └─ preserve 14-PR policy debt as disclosed non-release state
                │
                v
milestone.complete --dry-run
  ├─ fail if audit is null
  ├─ fail unless phase set is exactly 161..165
  └─ fail unless quick == []
                │
                v
Explicit approval → milestone.complete --confirm
                │
                v
Archive mutation → ROADMAP/PROJECT/STATE/retrospective/state.json edits
                │
                v
All tracked archive commits → protected origin/main exact SHA
                │
                v
attempt-1 push CI + natural attempt-1 schedules for exact SHA
                │
                v
Installed milestone finalizer (once) → ignored terminal report
                │
                v
STOP: no later v2.7 lifecycle write
```

### Recommended Project Structure

Names are the planner's discretion; the following narrow split is recommended. [ASSUMED]

```text
scripts/
├── mailglass_finalize_milestone_loader.mjs  # installed trust boundary; accepts only v2.7
└── finalize_milestone_v2_7.sh               # archived-layout and remote-evidence verifier
test/scripts/
└── phase_165_milestone_finalizer_test.exs   # disposable archive fixtures + host tag
.planning/phases/165-.../
├── 165-VALIDATION.md
├── 165-VERIFICATION.md
└── 165-SUMMARY.md
```

### Pattern 1: Separate immutable authority

**What:** Copy the trusted-loader architecture, not its Phase 164 constants. The new loader must have its own identity, accepted argument `v2.7`, source path, archived dependency manifest, installation tuple, rollback record, and report schema. [VERIFIED: scripts/mailglass_finalize_phase_loader.mjs:20-94,123-230,424-527]

**When to use:** Only for the post-archive terminal action. Repository tests and ordinary verification must never call the canonical terminal mode.

### Pattern 2: Authenticate an archived manifest, not a live directory convention

**What:** Materialize from one captured final HEAD every file that establishes milestone truth: archived ROADMAP, archived REQUIREMENTS, archived canonical audit, all five archived phase directories' required proof files, MILESTONES, PROJECT, STATE, `state.json`, and the finalizer's executable dependencies. The GSD archive creator quotes targets for `${version}-ROADMAP.md`, `${version}-REQUIREMENTS.md`, `${version}-MILESTONE-AUDIT.md`, and `${version}-phases`. [VERIFIED: /Users/jon/.codex/gsd-core/bin/lib/milestone.cjs:837-849,866-887,1097-1107]

**When to use:** Both fixture-based ordinary tests and the installed terminal run. Do not fall back to live `.planning/phases/164-*`, `.planning/ROADMAP.md`, or `.planning/REQUIREMENTS.md` after archival.

### Pattern 3: Two gates with distinct authority

**What:** The ordinary gate proves implementation against disposable pre/post-archive fixtures and may run before Phase 165 completion. The terminal gate observes the real final archive SHA only after the audit, archive, later tracked edits, final commit, protected integration, exact CI, and natural schedules. The prior verifier explicitly says `"This report is ordinary verification, not terminal evidence."` [VERIFIED: .planning/phases/164-repository-truth-reconciliation-and-closeout/164-VERIFICATION.md:98-107]

**When to use:** Preserve this separation in plan waves and test tags; never make a repository-only test result satisfy terminal acceptance.

### Pattern 4: Semantic archive and audit validation

**What:** Validate content, not merely path existence. The audit must have `status: passed`, exact scores, no critical gaps, all five validation records compliant, and the accepted PR policy debt. The archive must have the exact five-phase set and the expected archived/live truth split. The audit workflow defines `passed`, `gaps_found`, and `tech_debt` and the strict three-source status matrix. [VERIFIED: /Users/jon/.codex/gsd-core/workflows/audit-milestone.md:138-227]

**When to use:** In both the archive dry-run gate and final report generator. A stale but structurally valid audit must fail.

### Pattern 5: Publish machine state from canonical owners

**What:** After the last ROADMAP/STATE mutation, invoke the existing `publishStateContract(cwd)` and require the exact result vocabulary `"published"`, `"no_planning_dir"`, or `"write_failed"`; success is only `{published: true, reason: "published"}`. [VERIFIED: /Users/jon/.codex/gsd-core/bin/lib/state-contract.cjs:70-94,310-359] The publisher derives the milestone, phases, statuses, and next action from their canonical owners. [VERIFIED: /Users/jon/.codex/gsd-core/bin/lib/state-contract.cjs:133-175,252-308]

**When to use:** Once all human-authored archive metadata is final and before the final archive commit. `milestone.complete` already publishes once at its mutation boundary, but later workflow edits can make that early snapshot stale. [VERIFIED: /Users/jon/.codex/gsd-core/bin/lib/milestone.cjs:1149-1161; /Users/jon/.codex/gsd-core/workflows/complete-milestone.md:558-715]

### Anti-Patterns to Avoid

- **Modify the Phase 164 loader or shell:** It is a historical authority with exact `"164"`, `1` through `44`, and live paths; changing it violates D-02 and consumes unrelated reapproval. [VERIFIED: scripts/mailglass_finalize_phase_loader.mjs:20-94; scripts/finalize_phase_164.sh:13-19]
- **Treat archive-command success as terminal state:** The completion workflow has later tracked writes. [VERIFIED: /Users/jon/.codex/gsd-core/workflows/complete-milestone.md:558-715,856-868]
- **Accept file existence as archive proof:** A stale audit or incomplete/mixed live/archive layout can exist while being semantically false. The strict audit matrix makes missing SUMMARY metadata partial even when verification passed. [VERIFIED: /Users/jon/.codex/gsd-core/workflows/audit-milestone.md:138-155]
- **Select caller-provided GitHub run IDs:** Derive the one acceptable run from read-only run lists and exact identity fields. [VERIFIED: scripts/finalize_phase_164.sh:88-108,198-242]
- **Write terminal output before all checks finish:** A late dirty/moving-HEAD condition must either prevent output or rewrite the ignored report to non-pass without leaving a pass artifact. [VERIFIED: scripts/finalize_phase_164.sh:56-86,245-280]
- **Archive quick tasks:** Quick archival is opt-in/default-off and has no per-milestone provenance; locked D-11 requires leaving it off. [VERIFIED: /Users/jon/.codex/gsd-core/workflows/complete-milestone.md:512-518,538-546]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Requirements satisfaction | A Phase 165-specific checkbox parser | Canonical audit workflow | It already cross-references REQUIREMENTS, VERIFICATION, and SUMMARY and treats missing claims as partial. [VERIFIED: /Users/jon/.codex/gsd-core/workflows/audit-milestone.md:110-155] |
| Nyquist classification | A local `status` heuristic | Re-run validate-phase, then audit classification | Compliance is exactly `status: validated`, `nyquist_compliant: true`, and all tasks green. [VERIFIED: /Users/jon/.codex/gsd-core/workflows/audit-milestone.md:157-184] |
| Archive moves | Manual `cp`/`mv` | `milestone.complete --dry-run`, then `--confirm` | Dry-run and mutation share one routed phase-set derivation. [VERIFIED: /Users/jon/.codex/gsd-core/bin/lib/milestone.cjs:790-865,1077-1107] |
| Machine-readable planning state | Literal JSON edits | `publishStateContract` | It composes existing canonical owners and performs atomic best-effort publication. [VERIFIED: /Users/jon/.codex/gsd-core/bin/lib/state-contract.cjs:3-43,310-359] |
| Cleanliness parser | Locale/config-sensitive `git status` text parsing | porcelain v1 with all untracked paths | Porcelain v1 is documented as stable for scripts. [CITED: https://git-scm.com/docs/git-status] |
| Rerun detection | Run-number guesses or timestamps | Exact `attempt == 1` plus trigger, branch, and SHA | GitHub exposes `run_attempt`, which increments on rerun; existing code already enforces the full tuple. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/contexts] [VERIFIED: scripts/finalize_phase_164.sh:88-108,198-242] |
| Cryptographic digest | Custom hash implementation | Node `createHash("sha256")` and Git object IDs | The established loader uses Node crypto and Git tree/blob authority. [VERIFIED: scripts/mailglass_finalize_phase_loader.mjs:3-18,295-370] |

**Key insight:** The phase's complexity is authority composition and ordering. Reusing the canonical audit/archive/state owners prevents Phase 165 from creating competing definitions of “complete.”

## Runtime State Inventory

| Category | Items Found | Action Required |
|---|---|---|
| Stored data | Planning truth is stored in tracked Markdown plus `.planning/state.json`; the current JSON quotes milestone `"v2.7 — Repository Stewardship & Operational Hygiene (Planned)"`, phases only `"161"` through `"164"`, and next command `"/gsd:new-milestone"`. [VERIFIED: .planning/state.json:1-33] No application database migration is authorized by this phase. [VERIFIED: .planning/REQUIREMENTS.md:40-53] | Reconcile tracked planning documents, then republish `state.json`; do not touch application datastores. |
| Live service config | GitHub holds branch protection, Actions runs, and scheduled-run state outside Git; Phase 165 is authorized only to read exact evidence. Dispatch, rerun, merge bypass, and workflow-topology mutation are locked out. [VERIFIED: .planning/phases/165-reconcile-terminal-proof-and-milestone-archive-ordering/165-CONTEXT.md:31-37] | Query only; accept naturally occurring evidence for the final SHA. Preserve the disclosed fourteen-PR policy block. |
| OS-registered state | `/Users/jon/.local/bin/mailglass-finalize-phase` is the installed Phase 164 authority and must remain unchanged; its loader quotes `SUPPORTED_PHASE = "164"`. [VERIFIED: scripts/mailglass_finalize_phase_loader.mjs:20-35] | Create a distinct installed milestone command only after fresh exact-tuple approval; preserve predecessor/rollback facts and mode `0500` using the established installation pattern. [ASSUMED] |
| Secrets/env vars | The trusted child environment allowlists `"GH_TOKEN"` and `"GITHUB_TOKEN"` while reconstructing PATH; it rejects inherited ASDF selectors. [VERIFIED: scripts/mailglass_finalize_phase_loader.mjs:148-220] | Consume GitHub credentials ephemerally; exclude tokens and environment dumps from reports and tracked files. |
| Build artifacts / installed packages | The historical report under `tmp/` is ignored evidence; the installed loader and any digest-addressed rollback are external host artifacts. No package build or dependency upgrade is needed. [VERIFIED: tmp/phase-164-finalize.FGINGn/report.json:1-43; .planning/REQUIREMENTS.md:40-53] | Never overwrite the historical report; give the new terminal report its own ignored directory/schema and retain exact installed provenance. |

## Common Pitfalls

### Pitfall 1: Repairing metadata but leaving the audit partial

**What goes wrong:** Adding the three missing SUMMARY values without re-running Phases 161 and 163 validation still leaves Nyquist non-compliant.

**Why it happens:** Current frontmatter is exactly `status: complete`, `nyquist_compliant: true` for both phases, while the audit recognizes only `status: validated` as compliant. [VERIFIED: .planning/phases/161-canonical-workspace-and-evidence-preservation/161-VALIDATION.md:1-8; .planning/phases/163-deterministic-release-path-timeout-repairs/163-VALIDATION.md:1-10; /Users/jon/.codex/gsd-core/workflows/audit-milestone.md:169-180]

**How to avoid:** Use the validation workflow; do not manually flip the status without its evidence reconciliation.

### Pitfall 2: Archiving before the audit is canonical and non-null

**What goes wrong:** The archive succeeds without moving an audit, leaving terminal evidence unable to authenticate the required artifact.

**Warning sign:** The observed dry run currently reports `"audit": null`; it otherwise lists exactly the five phase directories and `"quick": []`. [VERIFIED: `gsd-tools query milestone.complete v2.7 --name "Repository Stewardship & Operational Hygiene" --dry-run`, executed 2026-09-13]

**How to avoid:** Make the exact dry-run JSON a blocking automated assertion immediately before the confirmation checkpoint.

### Pitfall 3: Selecting the wrong terminal SHA

**What goes wrong:** Evidence binds the archive-command commit or safety commit, but REQUIREMENTS deletion, retrospective, STATE, PROJECT, ROADMAP, or `state.json` changes later.

**How to avoid:** Define one final archive commit after every tracked archive-related mutation, then forbid any v2.7 tracked write after protected integration and terminal capture.

### Pitfall 4: Running the stock tag step in the wrong place

**What goes wrong:** The stock workflow creates a local annotated tag before its final REQUIREMENTS-deletion commit, then offers to push it. [VERIFIED: /Users/jon/.codex/gsd-core/workflows/complete-milestone.md:856-868; /Users/jon/.codex/gsd-core/workflows/complete-milestone/steps/git-tag.md:1-27] That tag cannot represent the final archived SHA.

**How to avoid:** Skip the stock tag section for this bookkeeping milestone and do not push a tag; this follows the locked no-release/no-tag-push boundary. [ASSUMED]

### Pitfall 5: Letting `state.json` lag final Markdown truth

**What goes wrong:** The archive command publishes state before later ROADMAP/STATE edits.

**How to avoid:** Republish from canonical owners after the final Markdown edits, assert `published`, include `state.json` in the final tracked commit, and authenticate it in the finalizer.

### Pitfall 6: Weak negative fixtures

**What goes wrong:** Tests change only a path name while never reaching the intended authority boundary, or accept a stale audit because it parses.

**How to avoid:** For every required hostile case, assert the stable failure tag and separately prove non-dispatch/non-output. Existing Phase 164 tests enforce lane isolation and non-vacuity. [VERIFIED: test/scripts/phase_164_closeout_test.exs:139-175]

## Code Examples

Verified patterns from project and official sources follow.

### Stable cleanliness check

```bash
# Source: scripts/finalize_phase_164.sh:26-28 and official git-status docs
"$MAILGLASS_GIT" -C "$repo" status --porcelain=v1 --untracked-files=all
```

Treat any non-empty result or command failure as non-clean; do not ignore untracked report leakage. [VERIFIED: scripts/finalize_phase_164.sh:26-28,266-270] [CITED: https://git-scm.com/docs/git-status]

### Exact attempt-one push CI selector

The existing closed values are quoted verbatim: `"CI"`, `"push"`, `1`, `"main"`, `"completed"`, and `"success"`. [VERIFIED: scripts/finalize_phase_164.sh:91-108]

```jq
# Source: scripts/finalize_phase_164.sh:91-108
select(
  .workflowName == "CI" and
  .event == "push" and
  .attempt == 1 and
  .headBranch == "main" and
  .headSha == $sha and
  .status == "completed" and
  .conclusion == "success"
)
```

### Archive preview and mutation boundary

```bash
# Source: complete-milestone.md:520-529
gsd_run query milestone.complete "v2.7" \
  --name "Repository Stewardship & Operational Hygiene" \
  --dry-run

# Only after explicit approval and exact preview assertions:
gsd_run query milestone.complete "v2.7" \
  --name "Repository Stewardship & Operational Hygiene" \
  --confirm
```

The exact version and milestone name are existing planning values, not newly invented code vocabulary. [VERIFIED: .planning/REQUIREMENTS.md:1-6; .planning/PROJECT.md:78-81]

### Canonical state publication

The exported entry point is quoted verbatim as `publishStateContract`, with success reason `"published"`. [VERIFIED: /Users/jon/.codex/gsd-core/bin/lib/state-contract.cjs:70-94,327-359]

```javascript
// Source: gsd-core/bin/lib/state-contract.cjs:327-359
const { publishStateContract } = require(
  "/Users/jon/.codex/gsd-core/bin/lib/state-contract.cjs"
);
const result = publishStateContract(process.cwd());
if (!result.published || result.reason !== "published") process.exit(1);
```

Calling the installed compiled module directly is a recommended one-run implementation detail; a narrowly scoped repository wrapper is also permitted by locked discretion if the planner needs a stable tested seam. [ASSUMED]

## Recommended Plan Decomposition

1. **Metadata and audit-input repair:** Add `requirements-completed: [WSPC-01, WSPC-03, WSPC-04]` to `161-04-SUMMARY.md`; the three values are quoted by locked D-06, and the exact list-shaped YAML field is established by `requirements-completed: [WSPC-02]` in the adjacent summary. [VERIFIED: .planning/phases/165-reconcile-terminal-proof-and-milestone-archive-ordering/165-CONTEXT.md:23-25; .planning/phases/161-canonical-workspace-and-evidence-preservation/161-04-SUMMARY.md:1-30; .planning/phases/161-canonical-workspace-and-evidence-preservation/161-05-SUMMARY.md:21-35] Re-run validation for 161 and 163, then reconcile current metadata to Phase 165.
2. **Repository-local terminal machinery:** Implement the separate v2.7 loader/shell and fixture suite. Include positive pre/post-archive fixtures and every D-12 negative case. Keep canonical terminal dispatch impossible from the required repository lane.
3. **External installation checkpoint:** Once the source tuple is final and protected as required by the plan, present exact source OID, digest, destination, mode, prior-object disposition, runtime closure, and rollback for fresh approval. Install and run inspection/self-check plus controlled-host tests, but do not run terminal mode.
4. **Ordinary phase close:** Run focused tests and the required lane, write Phase 165 VALIDATION/VERIFICATION/SUMMARY, and complete Phase 165 metadata. Do not claim milestone terminal status.
5. **Strict audit gate:** Run the canonical audit only after all five phases are complete and validation-compliant. Assert exact D-13 scores and retained 14-PR debt.
6. **Archive preview checkpoint:** Assert non-null audit, exact phase set 161–165, no skipped phase archive, and empty quick set. Obtain explicit confirmation only after presenting this preview.
7. **Archive and final tracked convergence:** Run `milestone.complete --confirm`, verify archive paths, perform the workflow's later ROADMAP/PROJECT/STATE/retrospective/REQUIREMENTS changes, republish `state.json`, and commit every tracked archive artifact. Skip unauthorized branch deletion, remote tag push, dispatch/rerun, release, and publication.
8. **Protected terminal gate:** Integrate normally, establish final clean `HEAD == origin/main`, wait for exact attempt-one push CI and all natural attempt-one schedules, run the installed milestone finalizer once, verify ignored-only output, then make no later v2.7 lifecycle mutation.

This ordering follows the locked lifecycle and the observed GSD mutation sequence. [VERIFIED: .planning/phases/165-reconcile-terminal-proof-and-milestone-archive-ordering/165-CONTEXT.md:16-37; /Users/jon/.codex/gsd-core/workflows/complete-milestone.md:508-715]

## State of the Art

| Old Approach | Current Approach for Phase 165 | Why It Changed | Impact |
|---|---|---|---|
| Phase-only terminal proof over live planning paths | Milestone terminal proof over final archived paths | Phase 165 planning invalidated Phase 164's former terminal claim and archive relocation changes the authoritative paths. [VERIFIED: .planning/phases/165-reconcile-terminal-proof-and-milestone-archive-ordering/165-CONTEXT.md:6-21,93-97] | Separate authority and archived manifest are mandatory. |
| Audit after terminal capture | Audit before archive and terminal capture | Canonical audit is tracked and archive input; any later tracked audit invalidates no-later-write proof. [VERIFIED: tmp/v2.7-MILESTONE-AUDIT.md:37-41,142-146] | The audit becomes a pre-archive gate. |
| Four-phase milestone accounting | Five-phase accounting with no new requirement | ROADMAP now contains a Phase 165 stub while current progress and machine state still stop at 164. [VERIFIED: .planning/ROADMAP.md:367-383; .planning/state.json:1-33] | All lifecycle artifacts must converge before audit. |
| Archive command treated as completion boundary | Final tracked archive SHA after surrounding workflow writes | GSD performs later ROADMAP, REQUIREMENTS, retrospective, and STATE actions. [VERIFIED: /Users/jon/.codex/gsd-core/workflows/complete-milestone.md:558-715,856-868] | Protected evidence must target the later SHA. |

**Deprecated/outdated:** Any current-facing claim that Phase 164 terminal evidence remains pending or is milestone completion authority is stale. ROADMAP currently quotes `"Phase completion remains pending"`, and STATE quotes `"terminal evidence remains pending"`; both require Phase 165 reconciliation. [VERIFIED: .planning/ROADMAP.md:193-195; .planning/STATE.md:28-38]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | Recommended repository-local names are `mailglass_finalize_milestone_loader.mjs`, `finalize_milestone_v2_7.sh`, and `phase_165_milestone_finalizer_test.exs`. | Recommended Project Structure | Low: planner may choose other narrow names. |
| A2 | The distinct installed command should use the same mode-0500, exact-tuple, rollback-aware installation pattern as Phase 164. | Runtime State Inventory | Medium: exact destination and prior-object state must be computed immediately before approval. |
| A3 | Skip the stock local tag step because it occurs before the final archive commit and would not identify the final archived SHA. | Common Pitfalls | Medium: planner must ensure workflow orchestration can omit the section without changing global tag policy. |
| A4 | Invoke the installed GSD `publishStateContract` export directly after final metadata edits unless the planner chooses a tested narrow wrapper. | Architecture / Code Examples | Medium: compiled internal path is environment-specific, although present and inspected in this session. |

## Open Questions

1. **Exact installed milestone-command destination and predecessor state**
   - What we know: It must be separate from `/Users/jon/.local/bin/mailglass-finalize-phase`, accept only `v2.7`, and require a fresh exact-tuple approval.
   - What's unclear: The destination does not exist as a locked discrete value yet; its lstat identity and any predecessor can only be known at approval time.
   - Recommendation: Use `/Users/jon/.local/bin/mailglass-finalize-milestone` as the proposal default, but treat the entire tuple as unapproved until the checkpoint. [ASSUMED]

2. **How to omit the stock tag section for this one completion**
   - What we know: Configuration defaults quote `"create_tag": true`; the tag step precedes the final deletion commit and offers a remote push. [VERIFIED: /Users/jon/.codex/gsd-core/bin/shared/config-defaults.manifest.json:17-23; /Users/jon/.codex/gsd-core/workflows/complete-milestone.md:856-868]
   - What's unclear: Whether the orchestrator will supply a section manifest excluding `git-tag` or execute the required archive sequence explicitly.
   - Recommendation: Exclude `git-tag` for this run without changing the repository-wide default; record the omission as the locked no-release/no-tag-push posture. [ASSUMED]

No open question blocks repository-local planning. Both unresolved details belong to the already-required narrow checkpoints.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---:|---:|---|
| `/Users/jon/.asdf/installs/nodejs/24.19.0/bin/node` | Loader | ✓ | 24.19.0 | None; exact physical path is part of authority. |
| `/opt/homebrew/Cellar/git/2.41.0/bin/git` | Git authority | ✓ | 2.41.0 | None; exact physical path is part of authority. |
| `/opt/homebrew/Cellar/bash/5.2.37/bin/bash` | Verifier shell | ✓ | 5.2.37 | None; exact physical path is part of authority. |
| `/opt/homebrew/Cellar/gh/2.95.0/bin/gh` | Read-only GitHub evidence | ✓ | 2.95.0 | Wait/report blocked; never substitute dispatch/rerun. |
| `/usr/bin/jq` | Evidence parsing | ✓ | 1.7.1-apple | None in terminal path. |
| `/Users/jon/.asdf/installs/elixir/1.19.5-otp-28/bin/{mix,elixir}` | ExUnit / runtime probe | ✓ | 1.19.5 | None; exact physical path is part of authority. |
| `/Users/jon/.asdf/installs/erlang/28.4.1/bin/erl` | BEAM closure | ✓ | OTP 28 | None; exact physical path is part of authority. |
| `/Users/jon/.codex/gsd-core/bin/gsd-tools.cjs` | Audit/archive/state workflows | ✓ | runtime identity verified during init | Manual archival is not an acceptable fallback. |

Every listed executable path was probed in this session; the loader source independently declares the same closed tool set. [VERIFIED: scripts/mailglass_finalize_phase_loader.mjs:26-47; environment probes 2026-09-13]

**Missing dependencies with no fallback:** None observed.

**Missing dependencies with fallback:** None observed. Remote evidence may be temporally unavailable; the fallback is to remain non-terminal and wait, not to manufacture substitute evidence.

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit under Mix/Elixir 1.19.5, using disposable Git repositories and subprocess assertions |
| Config file | `mix.exs`; `test/test_helper.exs` |
| Quick run command | `mix test test/scripts/phase_165_milestone_finalizer_test.exs --exclude phase_165_installed_production_boundary --warnings-as-errors --no-deps-check` [ASSUMED] |
| Full suite command | `mix verify.ci_lane_contract` plus the dedicated controlled-host alias after approved installation [ASSUMED] |

The current required alias automatically discovers all `test/scripts/*_test.exs` but explicitly excludes controlled-host Phase 164 tests; the test helper applies the same global exclusion. [VERIFIED: mix.exs:294-313; test/test_helper.exs:45-53] Phase 165 should add a matching `phase_165_installed_production_boundary` exclusion and dedicated alias without changing `.github/workflows` topology. [ASSUMED]

### Phase Decisions → Test Map

| Decision | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| D-02/D-03 | Separate loader accepts only `v2.7`; Phase 164 command remains byte-identical | unit/integration | focused Phase 165 ExUnit file + Phase 164 self-check | ❌ Wave 0 |
| D-12 | Stale audit and incomplete archive fail before remote query/dispatch | unit | focused Phase 165 ExUnit file | ❌ Wave 0 |
| D-12/D-15 | Dirty checkout and moving HEAD fail closed | integration with disposable Git repo | focused Phase 165 ExUnit file | ❌ Wave 0 |
| D-12/D-15 | Selected/rerun CI and non-natural schedules fail; exact attempt-one tuples pass | unit with captured JSON | focused Phase 165 ExUnit file | ❌ Wave 0 |
| D-03/D-12 | Output is ignored-only; tracked/untracked leakage fails final cleanliness | integration | focused Phase 165 ExUnit file | ❌ Wave 0 |
| D-13 | Canonical audit exact scores and all-five Nyquist compliance | docs/semantic contract | audit generation + Phase 165 verification assertion | ❌ Wave 0 |
| D-14 | Dry-run audit non-null, exact five phases, quick empty; final layout complete | command integration | GSD dry-run JSON assertion + disposable post-archive fixture | ❌ Wave 0 |
| D-16 | Installed bytes match approved tuple; no terminal dispatch in readiness proof | controlled-host | dedicated `mix verify.phase_165.installed_boundary` [ASSUMED] | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** focused Phase 165 fixture test, plus `node --check` and `bash -n` for changed finalizer sources. [ASSUMED]
- **Per wave merge:** `mix verify.ci_lane_contract`; run controlled-host alias only after exact installation approval. [ASSUMED]
- **Phase gate:** Full required repository lane, installed readiness proof, validation reconciliation, and ordinary verification must be green before canonical audit.
- **Terminal gate:** Not a test-suite substitute; it requires the actual protected final SHA, exact remote evidence, and one installed invocation.

### Wave 0 Gaps

- [ ] `test/scripts/phase_165_milestone_finalizer_test.exs` — archived-layout fixtures and all D-12 negative cases. [ASSUMED]
- [ ] `165-VALIDATION.md` — decision-to-test map and observed commands.
- [ ] Phase 165 controlled-host exclusion/alias — keeps external state outside repository-only CI. [ASSUMED]
- [ ] Disposable canonical audit/archive fixtures — exact five phases, stale audit, missing archive member, tracked-output leakage, and final state agreement.

## Security Domain

Security enforcement is active by default at ASVS level `1`, blocking on `"high"`; the project config does not override these values. [VERIFIED: /Users/jon/.codex/gsd-core/bin/shared/config-defaults.manifest.json:25-61; .planning/config.json:15-40]

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | No new user authentication | GitHub CLI identity and normalized `szTheory/mailglass` repository identity are existing external-service authentication boundaries. [VERIFIED: scripts/finalize_phase_164.sh:40-53,272-277] |
| V3 Session Management | No | No application session or browser state is introduced. [VERIFIED: .planning/REQUIREMENTS.md:40-53] |
| V4 Access Control | Yes | Exact command vocabulary, canonical physical repo, authenticated installed bytes, exact approval tuple, and no dispatch/rerun/merge bypass. [VERIFIED: scripts/mailglass_finalize_phase_loader.mjs:123-145,240-268,424-527; .planning/phases/165-reconcile-terminal-proof-and-milestone-archive-ordering/165-CONTEXT.md:31-37] |
| V5 Input Validation | Yes | Full lowercase 40-hex commit OIDs, exact `v2.7`, closed JSON shapes, exact archive manifest, bounded diagnostics, and fail-closed path regularity. Existing full-OID and physical-file patterns are established. [VERIFIED: scripts/mailglass_finalize_phase_loader.mjs:20-53,123-145; scripts/finalize_phase_164.sh:30-38] |
| V6 Cryptography | Yes | Node SHA-256 plus Git commit/tree/blob identity; never implement a custom digest. [VERIFIED: scripts/mailglass_finalize_phase_loader.mjs:3-18,222-230,295-370] |

### Known Threat Patterns for the Finalizer Stack

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Replaced/symlinked installed executable or tool | Spoofing / Elevation | lstat regular file, physical realpath equality, safe owner/mode, exact digest/source OID, closed absolute tool paths. [VERIFIED: scripts/mailglass_finalize_phase_loader.mjs:123-145,424-467] |
| Mutable checkout bytes used after authority capture | Tampering | One captured HEAD OID; authenticate and privately materialize all executable/data dependencies; recheck HEAD before dispatch. [VERIFIED: scripts/mailglass_finalize_phase_loader.mjs:240-268,295-370,476-527] |
| Caller-selected or rerun remote evidence | Spoofing / Repudiation | Derive run from authoritative list; require trigger, attempt 1, main, exact SHA, completed status, and accepted conclusion. [VERIFIED: scripts/finalize_phase_164.sh:88-108,198-242] |
| Token or raw environment leakage | Information disclosure | Allowlist environment keys; pass token ephemerally; never serialize credentials or environment dumps. [VERIFIED: scripts/mailglass_finalize_phase_loader.mjs:148-174] |
| Oversized/error output or hanging probes | Denial of service | Bounded diagnostic slices, subprocess timeouts, fixed output buffers, closed manifests. [VERIFIED: scripts/mailglass_finalize_phase_loader.mjs:20-21,96-118,177-190] |
| Pass report survives late repository mutation | Tampering / Repudiation | Re-fetch/revalidate exact final main and cleanliness after component/report work; convert late failure to non-pass. [VERIFIED: scripts/finalize_phase_164.sh:56-86,245-280] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/165-reconcile-terminal-proof-and-milestone-archive-ordering/165-CONTEXT.md` — locked scope, ordering, gates, and mutation approvals.
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/PROJECT.md`, `.planning/STATE.md`, `.planning/state.json` — active milestone truth and exact current drift.
- `tmp/v2.7-MILESTONE-AUDIT.md` — strict baseline gaps and scores.
- `tmp/phase-164-finalize.FGINGn/report.json` — immutable historical terminal observation.
- `scripts/mailglass_finalize_phase_loader.mjs`, `scripts/finalize_phase_164.sh`, `test/scripts/phase_164_closeout_test.exs`, `mix.exs`, `test/test_helper.exs` — established local authority/test patterns.
- `/Users/jon/.codex/gsd-core/workflows/audit-milestone.md` — three-source and Nyquist classification contract.
- `/Users/jon/.codex/gsd-core/workflows/complete-milestone.md` and `/Users/jon/.codex/gsd-core/bin/lib/milestone.cjs` — archive and post-archive mutation ordering.
- `/Users/jon/.codex/gsd-core/bin/lib/state-contract.cjs` — canonical state publisher.

### Secondary (MEDIUM confidence)

- [Git status porcelain documentation](https://git-scm.com/docs/git-status) — stable scripted cleanliness output.
- [GitHub Actions contexts](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts) — run-attempt and trigger/SHA context semantics.

### Tertiary (LOW confidence)

- None used as implementation authority. Naming and one-run orchestration recommendations are explicitly `[ASSUMED]`.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — every tool/path comes from the existing authenticated loader and was probed locally.
- Architecture: HIGH — derived from locked decisions, current executable trust boundaries, and inspected GSD archive/audit sources.
- Pitfalls: HIGH — each major failure mode is either present in the baseline audit, demanded by CONTEXT, or implied directly by inspected mutation order.
- Exact new filenames/destination and stock-tag omission mechanism: LOW — deliberately left as planner decisions and logged assumptions.

**Research date:** 2026-09-13
**Valid until:** 2026-10-13 for repository-local patterns; re-run archive dry-run and environment/remote probes immediately before mutation.
