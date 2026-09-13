---
phase: "165"
slug: "reconcile-terminal-proof-and-milestone-archive-ordering"
status: draft
nyquist_compliant: true
wave_0_complete: true
human_uat_required: true
created: "2026-09-13"
updated: "2026-09-13"
---

# Phase 165 — Validation Strategy

> Finalized pre-execution validation contract for all ten tasks in Plans 165-01 through 165-05. Ordinary validation and controlled-host readiness remain distinct from the post-archive terminal observation per D-04 and D-12.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit under Mix/Elixir 1.19.5, disposable Git repositories, subprocess assertions, shell syntax checks, jq semantic checks, and canonical GSD lifecycle workflows |
| **Config files** | `mix.exs`; `test/test_helper.exs`; scoped disposable copies of `.planning/config.json` for the tag-omission contract |
| **Quick repository command** | `mix test test/scripts/phase_165_milestone_finalizer_test.exs --exclude phase_165_installed_production_boundary --warnings-as-errors --no-deps-check` |
| **Required repository lane** | `mix verify.phase_165.repository` followed by `mix verify.ci_lane_contract` |
| **Controlled-host readiness lane** | `mix verify.phase_165.installed_boundary`, only after the exact D-16 installation tuple is approved |
| **Post-archive terminal observation** | The installed `mailglass-finalize-milestone v2.7` invocation in `165-FINALIZATION.md`; excluded from ordinary validation and never a pre-archive prerequisite |
| **Estimated runtime** | Focused samples target 120 seconds or less; the controlled-host lane and naturally occurring remote evidence are separately timed authorities |

## Finalized Plan and Wave Map

| Plan | Wave | Depends On | Task IDs | Test-Creation / Evidence Dependency |
|------|------|------------|----------|------------------------------------|
| 165-01 | 1 | none | 165-01-01, 165-01-02 | Task 165-01-01 starts test-first and creates the Phase 165 ExUnit file, both finalizer sources, and both Mix lane controls before its own verification; Task 165-01-02 expands that same fixture matrix. |
| 165-02 | 1 | none | 165-02-01, 165-02-02 | Uses existing Phase 161/163 records and the existing CI lane; no Phase 165 source prerequisite. |
| 165-03 | 2 | 165-02 | 165-03-01, 165-03-02 | Consumes repaired metadata from Plan 02, then republishes the existing generated state contract from finalized Markdown. |
| 165-04 | 2 | 165-01 | 165-04-01, 165-04-02 | Consumes Plan 01's tracked source and installed-boundary lane; Task 1 is the first blocking checkpoint and Task 2 may mutate only the approved external destination. |
| 165-05 | 3 | 165-01, 165-02, 165-03, 165-04 | 165-05-01, 165-05-02 | Adds the disposable tag-omission fixture to Plan 01's test file, creates security/finalization records, and validates all ten tasks. Its post-completion archive checkpoint is the second and final checkpoint. |

Same-wave file ownership is disjoint: Plan 01 owns finalizer/test/alias files while Plan 02 owns Phase 161/163 metadata. Plan 03 and Plan 04 are both Wave 2 but respectively own tracked lifecycle ledgers and external installation state.

## Per-Task Verification Map

| Task ID | Plan | Wave | Decisions | Threat Ref | Observable / Secure Behavior | Test Type | Command ID | Artifact Availability | Status |
|---------|------|------|-----------|------------|------------------------------|-----------|------------|-----------------------|--------|
| 165-01-01 | 01 | 1 | D-01–D-05, D-10, D-12, D-16, D-17 | T-165-01-T01/S01/R01/E01 | One exact archived v2.7 path authenticates a closed manifest; proposal predecessor states are closed; repository lane cannot dispatch installed authority | tracer integration | V01 | Task creates loader, shell, test, aliases, and exclusion before verify | pending |
| 165-01-02 | 01 | 1 | D-04, D-05, D-10–D-12, D-15, D-17 | T-165-01-T01/S01/R01/E01 | Every stale, incomplete, selected, rerun, non-natural, moving, leaking, or unsafe-predecessor fixture fails closed with non-dispatch | negative integration | V02 | Expands artifacts created by 165-01-01 | pending |
| 165-02-01 | 02 | 1 | D-01, D-06, D-09 | T-165-02-T01 | Owning summary claims exactly WSPC-01, WSPC-03, WSPC-04 without changing the 16-ID ledger | semantic metadata | V03 | Existing summary modified in place | pending |
| 165-02-02 | 02 | 1 | D-01, D-07, D-09, D-13 | T-165-02-R01/I01 | Canonical Phase 161/163 validation reruns preserve evidence and yield exact `status: validated` | workflow integration | V04 | Existing validation records refreshed by canonical owner | pending |
| 165-03-01 | 03 | 2 | D-01, D-08–D-11, D-17 | T-165-03-T01/S01 | ROADMAP and PROJECT agree on phases 161-165, 16 requirements, debt disclosure, and Phase 164 historical status | semantic metadata | V05 | Existing ledgers modified after Plan 02 | pending |
| 165-03-02 | 03 | 2 | D-04, D-05, D-08, D-15 | T-165-03-R01 | STATE reflects pre-archive Phase 165 truth and canonical publisher regenerates valid state.json | generated-state integration | V06 | Existing STATE modified; existing state.json regenerated | pending |
| 165-04-01 | 04 | 2 | D-02, D-16 | T-165-04-T01/E01/R01 | Read-only proposal lstat-captures exact absent-or-safe-regular predecessor tuple before first checkpoint | controlled-host proposal | V07 | Plan 01 proposal command exists; external destination is only inspected | pending |
| 165-04-02 | 04 | 2 | D-02, D-10, D-12, D-16, D-17 | T-165-04-T01/E01/D01/R01 | Approved bytes install atomically, drift fails, rollback restores predecessor, readiness emits no terminal report | controlled-host integration | V08 | Runs only after unchanged tuple approval | pending |
| 165-05-01 | 05 | 3 | D-01–D-05, D-10, D-12–D-17 | T-165-05-T01/E01/R01/S01/I01/D01 | Security gates and canonical audit/archive runbook enforce exact-byte config restoration, no git-tag section, final convergence, and one terminal stop | documentation contract + disposable integration | V09 | Creates SECURITY/FINALIZATION; modifies Phase 165 test file | pending |
| 165-05-02 | 05 | 3 | D-04, D-09, D-12 | T-165-05-T01/R01 | Canonical validation records every finalized task, all repository/host lanes, capability decisions, and excludes terminal proof | workflow + capability contract | V10a, V10b | Modifies this record after all prior plan summaries exist | pending |

## Automated Command Registry

Commands below are the exact `<automated>` contracts from the finalized plan tasks. XML entities in PLAN.md are rendered here as their shell characters.

| ID | Finalized Command |
|----|-------------------|
| V01 | `mix test test/scripts/phase_165_milestone_finalizer_test.exs --only phase_165_tracer --warnings-as-errors --no-deps-check && bash -n scripts/finalize_milestone_v2_7.sh && mix format --check-formatted test/scripts/phase_165_milestone_finalizer_test.exs` |
| V02 | `mix test test/scripts/phase_165_milestone_finalizer_test.exs --exclude phase_165_installed_production_boundary --warnings-as-errors --no-deps-check && mix verify.phase_165.repository && mix verify.ci_lane_contract && git diff --check HEAD --` |
| V03 | `frontmatter=$(awk 'BEGIN{n=0} /^---$/{n++; next} n==1{print} n>1{exit}' .planning/phases/161-canonical-workspace-and-evidence-preservation/161-04-SUMMARY.md); for id in WSPC-01 WSPC-03 WSPC-04; do printf '%s\n' "$frontmatter" | grep -F -- "- $id" >/dev/null || exit 1; done; test "$(rg -n '^- \[[ x]\] \*\*WSPC-[0-9]{2}\*\*:' .planning/REQUIREMENTS.md | wc -l | tr -d ' ')" = 4 && git diff --check HEAD --` |
| V04 | `for file in .planning/phases/161-canonical-workspace-and-evidence-preservation/161-VALIDATION.md .planning/phases/163-deterministic-release-path-timeout-repairs/163-VALIDATION.md; do awk 'BEGIN{n=0} /^---$/{n++; next} n==1 && /^status: validated$/{ok=1} n>1{exit} END{exit ok ? 0 : 1}' "$file" || exit 1; done && mix verify.ci_lane_contract` |
| V05 | `rg -n 'Phases 161.165|Phase 165: Reconcile terminal proof and milestone archive ordering' .planning/ROADMAP.md .planning/PROJECT.md >/dev/null && test "$(rg -n '^- \[[ x]\] \*\*[A-Z]+-[0-9]{2}\*\*:' .planning/REQUIREMENTS.md | wc -l | tr -d ' ')" = 16 && ! rg -n 'Phases 161.164 \(planned\)' .planning/ROADMAP.md .planning/PROJECT.md && git diff --check HEAD --` |
| V06 | `node -e 'const {publishStateContract}=require("/Users/jon/.codex/gsd-core/bin/lib/state-contract.cjs"); const r=publishStateContract(process.cwd()); if (!(r && r.published === true && r.reason === "published")) { console.error(JSON.stringify(r)); process.exit(1); }' && jq -e 'type == "object"' .planning/state.json >/dev/null && rg -n '165|Reconcile terminal proof and milestone archive ordering' .planning/STATE.md .planning/state.json >/dev/null && git diff --check HEAD --` |
| V07 | `node scripts/mailglass_finalize_milestone_loader.mjs --installation-proposal --destination /Users/jon/.local/bin/mailglass-finalize-milestone | jq -e '.source_oid and .source_sha256 and .destination == "/Users/jon/.local/bin/mailglass-finalize-milestone" and .mode == "0500" and (.predecessor.disposition == "create" or (.predecessor.disposition == "backup_replace" and .predecessor.sha256 and .predecessor.mode and .predecessor.uid != null and .predecessor.gid != null)) and (.runtime_closure | type == "array" and length > 0) and .rollback' >/dev/null` |
| V08 | `mix verify.phase_165.installed_boundary && test -z "$(git status --porcelain=v1 --untracked-files=all)"` |
| V09 | `for token in '165-VERIFICATION.md' 'status: validated' '16/16' '5/5' '14-PR' '--dry-run' '--confirm' '161-165' 'git.create_tag=false' 'init.complete-milestone' 'git-tag' 'exact original config bytes' 'publishStateContract' 'HEAD == origin/main' 'attempt-1' 'schedule' 'hard stop'; do rg -F -- "$token" .planning/phases/165-reconcile-terminal-proof-and-milestone-archive-ordering/165-FINALIZATION.md >/dev/null || exit 1; done && mix test test/scripts/phase_165_milestone_finalizer_test.exs --only phase_165_tag_omission_fixture --warnings-as-errors --no-deps-check && rg -n 'ASVS|high|block|staging|installed|audit|archive|state|evidence|clean' .planning/phases/165-reconcile-terminal-proof-and-milestone-archive-ordering/165-SECURITY.md >/dev/null && git diff --check HEAD --` |
| V10a | `mix test test/scripts/phase_165_milestone_finalizer_test.exs --exclude phase_165_installed_production_boundary --warnings-as-errors --no-deps-check && bash -n scripts/finalize_milestone_v2_7.sh && mix verify.phase_165.repository && mix verify.phase_165.installed_boundary && mix verify.ci_lane_contract && awk 'BEGIN{n=0} /^---$/{n++; next} n==1 && /^status: validated$/{ok=1} n>1{exit} END{exit ok ? 0 : 1}' .planning/phases/165-reconcile-terminal-proof-and-milestone-archive-ordering/165-VALIDATION.md` |
| V10b | `scope_out=$(mktemp); trap 'rm -f "$scope_out"' EXIT; if cat .planning/phases/165-reconcile-terminal-proof-and-milestone-archive-ordering/165-CONTEXT.md .planning/phases/165-reconcile-terminal-proof-and-milestone-archive-ordering/165-RESEARCH.md .planning/phases/165-reconcile-terminal-proof-and-milestone-archive-ordering/165-PATTERNS.md .planning/phases/165-reconcile-terminal-proof-and-milestone-archive-ordering/165-VALIDATION.md | node /Users/jon/.codex/gsd-core/bin/lib/api-coverage.cjs --json >"$scope_out"; then exit 1; fi; jq -e '.detected == false' "$scope_out" >/dev/null && rg -n 'Spec-less probe fallback.*skipped.*no requirement IDs|assumption-delta.*detected: false|external-API detector.*detected: false' .planning/phases/165-reconcile-terminal-proof-and-milestone-archive-ordering/165-VALIDATION.md >/dev/null` |

## Sampling Rate

- **After each task commit:** run that task's command registry entry; for 165-05-02 run both V10a and V10b.
- **After Wave 1:** run `mix verify.ci_lane_contract` after merging disjoint Plan 01 and Plan 02 outputs.
- **After Wave 2:** run `mix verify.phase_165.repository`, then the separately authorized `mix verify.phase_165.installed_boundary`, and republish/check state after Plan 03.
- **Before ordinary Phase 165 verification:** run V09, V10a, and V10b; all ten task rows must carry observed evidence.
- **After ordinary execute-phase returns:** follow `165-FINALIZATION.md`; the canonical audit, archive confirmation, natural remote evidence, and terminal invocation are not ordinary task sampling.

## Wave 0 and Test-Creation Contract

- No separate Wave 0 plan is required. Task 165-01-01 is a TDD tracer: it creates `test/scripts/phase_165_milestone_finalizer_test.exs` before production implementation and runs V01 in the same task.
- Task 165-01-01 also creates the repository/installed aliases and default exclusion before any later task names those lanes.
- Task 165-05-01 adds the tag-omission fixture before V09 executes it; the fixture extracts the exact stable-marked runbook section, so documentation and tested mechanism cannot drift silently.
- Existing Phase 161/163 records, lifecycle ledgers, canonical workflow modules, and Phase 164 analogs already exist and are read-only prerequisites, not missing test scaffolds.
- The real external destination and naturally occurring GitHub evidence are runtime authorities, not Wave 0 test assets.

## Capability Decisions

- **external-API detector — detected: false.** Planning scope reuses the established read-only GitHub CLI evidence boundary and introduces no general GitHub API integration; V10b re-runs the deterministic detector over the final artifacts.
- **Spec-less probe fallback — skipped because Phase 165 has no requirement IDs** per D-09; decisions D-01–D-17 provide the phase's traceability contract.
- **assumption-delta — detected: false.** No identity checkpoint is added; the two locked mutation checkpoints remain the exact installation tuple and exact archive preview.
- Schema, database, browser, UI, dependency, and CI-topology gates are outside the locked phase boundary.

## Manual / External Authority Verifications

| Authority | Plan Boundary | Why Not Ordinary Automation | Required Evidence |
|-----------|---------------|-----------------------------|-------------------|
| Exact installed-authority tuple | 165-04 Task 1, first blocking checkpoint | External installation changes require fresh operator authority | Destination `/Users/jon/.local/bin/mailglass-finalize-milestone`; immediate lstat; absent/create or safe-regular backup_replace; exact source OID/SHA-256/mode/owner/runtime closure/rollback; no mutation before approval. |
| Exact archive preview | 165-05 post-completion checkpoint, second blocking checkpoint | `--confirm` performs the canonical lifecycle mutation | Fresh non-null audit; exact phases 161-165; quick set empty; original config bytes safely restorable; `init.complete-milestone` manifest excludes `git-tag`; no remote mutation. |
| Terminal protected evidence | Post-archive runbook, not an added checkpoint | Exact attempt-one CI and natural schedules exist only after final protected-main integration | Clean `HEAD == origin/main`; exact full SHA; ignored-only one-shot report; hard stop on later v2.7 writes. |

Exactly two explicit human checkpoints exist across the finalized plan set: 165-04 Task 1 and the 165-05 post-completion archive checkpoint.

## Validation Sign-Off

- [x] All ten finalized tasks are mapped to their actual plan, wave, decisions, threats, artifacts, and exact automated command IDs.
- [x] Test creation precedes every command that consumes a new Phase 165 test or alias.
- [x] Same-wave ownership and dependencies match PLAN frontmatter.
- [x] No three consecutive tasks lack automated verification.
- [x] No watch-mode flags are present.
- [x] Repository, controlled-host, canonical workflow, and terminal authorities are explicitly separated.
- [x] Exactly two blocking human checkpoints are identified.
- [ ] Replace pending row status with observed results during canonical validate-phase execution, then set frontmatter `status: validated`.

**Approval:** strategy reconciled before execution; observed execution evidence pending.
