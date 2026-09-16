# Phase 164: Repository Truth Reconciliation and Closeout - Context

**Gathered:** 2026-08-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Reconcile maintainer, version, release, recovery, package, tracked/generated artifact, and ignore-rule truth with the settled protected-release and package facts from Phases 161-163. Preserve contractual and forensic proof, remove only evidence-backed junk or stale output, and finish with a rerunnable closeout verdict bound to the clean canonical `main`, exact protected-CI identity, explained scheduled/recovery outcomes, and one disposition for every audited item. Product, API, schema, provider, admin UI, dependency, CI-topology, broad-timeout, release-authority, and ceremonial-publication changes remain out of scope.

</domain>

<decisions>
## Implementation Decisions

### Maintainer and Package Truth Surface
- **D-01:** Use layered authority when sources disagree: executable controls and immutable/live GitHub, Git, and Hex facts win; `MAINTAINING.md` is the human operational entry point that explains those controls; planning records remain preserved historical evidence rather than current instructions.
- **D-02:** Rewrite the current supported path clearly while retaining useful historical procedures in place with explicit version or milestone applicability. Historical guidance must not read as an alternative current runbook.
- **D-03:** Derive or contract-check current package-version claims against package manifests and public Hex facts. Current adopter docs may use supported compatibility constraints; old constraints remain only in explicitly historical or upgrade-bounded guides.
- **D-04:** Keep one current state-based release and recovery path in `MAINTAINING.md`, with exact supported commands, identities, and authorization conditions. Link to historical evidence for provenance rather than copying obsolete recovery instructions forward.

### Artifact and Ignore-Rule Disposition
- **D-05:** Create one tracked disposition ledger for every audited artifact and ignore rule. Each row records its path or pattern, producer, tracked/ignored state, authority, reproducibility, currentness, supporting evidence, and exactly one final outcome.
- **D-06:** Keep contractual, forensic, planning, release, publish, and other durable-consumer evidence tracked and discoverable. Reproducible diagnostics, caches, and machine-local noise remain untracked unless a durable consumer proves they are part of the repository contract.
- **D-07:** A committed ignore rule must name a shared project producer and use the narrowest safe path. User-specific tooling belongs in local or global excludes where practical. Do not add broad exclusions for `.planning/`, release, publish, scheduled-control, or generated-host evidence.
- **D-08:** Classify the current root `scheduled-control-sweep.json` as stale generated output: its 2026-08-25 rows predate the completed current-main scheduled evidence, no repository producer or consumer references the root filename, and its SHA-256 is `331810b4b1724452f0e2707c800230e52fabea01c3773d362b3a1240040ece7e`. Record that identity and reason in the ledger, then remove the root file; do not promote it to canonical proof or hide it with a broad ignore rule.

### Reproducible Quiet-Repository Closeout
- **D-09:** Use dual proof: a tracked durable ledger preserves documentation, artifact, ignore-rule, and disposition facts, while one rerunnable machine report proves volatile exact-main state. Do not create a self-referential committed “final snapshot” whose evidence becomes stale when that snapshot is committed.
- **D-10:** “Clean canonical workspace” means `/Users/jon/projects/mailglass` on `main`, with `HEAD` equal to `origin/main`, zero tracked or untracked entries in stable Git porcelain output, and no contractual or forensic evidence concealed by ignore rules. Classified ignored caches and machine-local files do not themselves make the workspace dirty.
- **D-11:** Required protected checks must pass for the exact current `main` SHA. Every applicable scheduled or recovery control must carry valid event, run, workflow-SHA, and artifact provenance and end in either pass or an already-defined evidence-backed policy-blocked disposition. Pending, `cannot-check`, unexplained red, stale identity, or mismatched artifact/summary evidence prevents a quiet verdict.
- **D-12:** Every audited item and ignore rule must have exactly one evidence-backed `retain`, `update`, `archive`, `remove`, or `ignore` disposition. Any unclassified, duplicate, stale-without-outcome, or missing-evidence row fails closeout.

### the agent's Discretion
- Exact ledger filename and schema, provided it is tracked, diffable, machine-checkable, and carries every field and completeness rule in D-05 and D-12.
- Exact current-doc section layout and link placement, provided the layered authority and historical applicability boundaries remain unmistakable.
- Exact reuse or extension seam for the rerunnable closeout check, provided it builds on existing workspace, repository-hygiene, scheduled-control, and exact-SHA monitoring assets rather than adding a new maintenance service.
- Exact capture timestamps, command ordering, and workflow-artifact filenames, provided all live claims are identity-bound and the human and machine surfaces consume the same result.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Contract and Settled Decisions
- `.planning/ROADMAP.md` § Phase 164 — fixed goal, dependency, and success criteria.
- `.planning/REQUIREMENTS.md` § Repository Truth and Closeout — TRTH-01 through TRTH-03 and milestone exclusions.
- `.planning/PROJECT.md` § Current Milestone: v2.7 Repository Stewardship & Operational Hygiene — maintenance-only intent, target features, and scope locks.
- `.planning/STATE.md` § Accumulated Context — completed Phase 161-163 facts, exact protected run, and automated-verification posture.
- `.planning/phases/161-canonical-workspace-and-evidence-preservation/161-CONTEXT.md` — recoverability-first workspace and proof decisions.
- `.planning/phases/161-canonical-workspace-and-evidence-preservation/161-WORKSPACE-INVENTORY.md` — inventoried canonical workspace, worktree, ref, and retained-evidence identities.
- `.planning/phases/161-canonical-workspace-and-evidence-preservation/161-PRESERVATION-RECONCILIATION.tsv` — evidence-backed one-to-one preservation dispositions.
- `.planning/phases/162-protected-release-and-scheduled-control-recovery/162-CONTEXT.md` — protected exact-digest authority and three-state control semantics.
- `.planning/phases/162-protected-release-and-scheduled-control-recovery/162-RELEASE-RECONCILIATION.md` — append-only PR, release, package, control, schedule, and recovery facts.
- `.planning/phases/162-protected-release-and-scheduled-control-recovery/162-UAT.md` — verified current-main scheduled-control provenance and artifact agreement.
- `.planning/phases/162-protected-release-and-scheduled-control-recovery/162-VERIFICATION.md` — completed AUTO requirement evidence.
- `.planning/phases/163-deterministic-release-path-timeout-repairs/163-CONTEXT.md` — narrow timeout-boundary and exact protected-proof constraints.
- `.planning/phases/163-deterministic-release-path-timeout-repairs/163-VERIFICATION.md` — final exact-code protected run `33002642359` and completed DTRM proof.

### Current Documentation and Version Truth
- `MAINTAINING.md` — active maintainer entry point whose release, recovery, package, and historical guidance must be reconciled.
- `README.md` — current core/admin adopter constraints and supported entry commands.
- `mailglass_admin/README.md` — current admin package constraints and setup guidance.
- `mailglass_inbound/README.md` — current inbound/core package constraints and operational guidance.
- `CHANGELOG.md` — published version history; historical entries remain history rather than current instructions.
- `mix.exs` — current core package version and package metadata.
- `mailglass_admin/mix.exs` — current admin package version and sibling constraints.
- `mailglass_inbound/mix.exs` — current inbound package version and sibling constraints.
- `.release-please-manifest.json` — release-please component version state.
- `release-please-config.json` — component, linked-version, and release-exclusion configuration.
- `.planning/release-target.json` — protected candidate and publication lifecycle ledger.
- `.planning/publish/mailglass-publish-summary.json` — tracked core publish proof.
- `.planning/publish/mailglass_admin-publish-summary.json` — tracked admin publish proof.
- `.planning/publish/mailglass_inbound-publish-summary.json` — tracked inbound publish proof.
- `.planning/publish/mailglass-files.expected` — tracked core package-content allowlist.
- `.planning/publish/mailglass_admin-files.expected` — tracked admin package-content allowlist.
- `.planning/publish/mailglass_inbound-files.expected` — tracked inbound package-content allowlist.

### Executable Release, Schedule, and Closeout Truth
- `.github/workflows/release-please.yml` — proposal-only ordinary entry points and protected exact-candidate authority.
- `.github/workflows/repo-hygiene.yml` — scheduled/control repository-hygiene evidence and artifact handling.
- `.github/workflows/post-publish-smoke.yml` — immutable-target post-publish recovery and scheduled behavior.
- `.github/workflows/scheduled-control-evidence.yml` — read-only scheduled-control evidence sweep.
- `.github/scheduled-controls.json` — scheduled-control registry and artifact contracts.
- `.github/workflows/ci.yml` — protected required and release-path checks.
- `dev/mix/tasks/mailglass.repo.hygiene.ex` — existing read-only workspace/repository status audit and JSON reporting.
- `scripts/verify_workspace_evidence.sh` — canonical workspace and preserved-evidence verification.
- `scripts/scheduled_control_evidence.sh` — exact event/run/workflow-SHA scheduled evidence validation.
- `scripts/ci_monitor.cjs` — exact-run and exact-SHA CI inspection surface.
- `scripts/release_policy.exs` — protected release-target and authority semantics.
- `scripts/check_post_publish_target.sh` — exact immutable post-publish target validation.
- `scripts/verify_published_release.sh` — public package and immutable publication proof.
- `test/mailglass/publish/maintaining_release_gate_contract_test.exs` — executable maintainer-release guidance contract.
- `test/mix/tasks/mailglass.repo.hygiene_test.exs` — repository-hygiene status and artifact contract.
- `test/scripts/workspace_evidence_contract_test.exs` — canonical workspace/preservation proof contract.
- `test/scripts/scheduled_control_evidence_test.exs` — scheduled-control provenance and verdict contract.
- `test/scripts/required_checks_test.exs` — protected required-context contract.

### Ignore Rules in the Audit Surface
- `.gitignore` — repository-wide shared generated-output and local-tool exclusions.
- `mailglass_admin/.gitignore` — admin-package generated-output exclusions.
- `mailglass_inbound/.gitignore` — inbound-package generated-output exclusions.
- `reference/demo_app/.gitignore` — demo-host generated-output exclusions.
- `reference/host_app/.gitignore` — reference-host generated-output exclusions.
- `test/example/.gitignore` — generated test-host exclusions.

No external specification is canonical for this phase. Live GitHub, Git, Actions, and Hex facts must be freshly captured through the repository’s bounded evidence tools.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mix mailglass.repo.hygiene --check` already emits bounded text and JSON repository findings and distinguishes pass, policy-blocked, and cannot-check outcomes.
- `scripts/verify_workspace_evidence.sh` plus the Phase 161 inventory/reconciliation artifacts already prove canonical identity, reachability, preservation, and disposition invariants.
- `.github/scheduled-controls.json`, `scripts/scheduled_control_evidence.sh`, and `.github/workflows/scheduled-control-evidence.yml` already provide the registry and read-only exact-provenance sweep needed for closeout.
- `scripts/ci_monitor.cjs` can inspect exact workflow runs, PR identities, required checks, logs, and artifacts without dispatching, merging, or releasing.
- Package manifests, Release Please state, release-target state, and tracked publish summaries/allowlists already expose the version and package-content truths that docs should project.

### Established Patterns
- Live/executable facts outrank stale prose, but `MAINTAINING.md` remains the human entry point and must explain the actual supported path.
- Evidence corrections append; contractual or forensic records are never silently rewritten or hidden by a broad ignore rule.
- Human summaries and machine artifacts must consume the same persisted result and agree on status, identity, and digest.
- Verification is automated by default; exact protected SHA and exact scheduled-run provenance matter more than branch-name or latest-run assumptions.
- Cleanup is classification-first and recoverability-first. Untracked or ignored does not mean disposable, and absence from `main` does not prove junk.

### Integration Points
- Documentation: `MAINTAINING.md`, the three package READMEs, historical/upgrade guides, and tests that enforce release/support claims.
- Artifact classification: all changed tracked/generated paths, all six repository ignore files, the tracked planning/publish proof set, and the stale root `scheduled-control-sweep.json`.
- Final workspace: `/Users/jon/projects/mailglass` must return to exact, clean `main` after the Phase 164 protected merge.
- Final remote proof: exact-SHA required checks and the three registered scheduled controls, with evidence-valid policy outcomes and no pending or cannot-check row.

</code_context>

<specifics>
## Specific Ideas

- Current package truth is core `2.5.0`, admin `2.5.0`, and inbound `2.2.0`; current docs should project compatible constraints from those sources rather than duplicate unchecked exact claims.
- `MAINTAINING.md` currently says release-please auto-merges after CI and includes an old `~> 1.3` / `~> 1.0` smoke example. Preserve the historical value but make its non-current applicability explicit while documenting the protected exact-digest path as current.
- The stale root sweep’s digest and reason for removal are locked in D-08 so cleanup remains auditable even though the file itself should not survive closeout.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within the fixed Phase 164 truth-reconciliation and closeout scope.

</deferred>

---

*Phase: 164-repository-truth-reconciliation-and-closeout*
*Context gathered: 2026-08-26*
