---
phase: 164
slug: repository-truth-reconciliation-and-closeout
status: ready
nyquist_compliant: true
wave_0_complete: false
created: 2026-08-26
revised: 2026-08-28
---

# Phase 164 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. The contract covers every executor task in Plans 164-01 through 164-12 plus the terminal non-plan finalization gate required after all tracked GSD metadata reaches protected main.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit / Mix project tests plus a read-only shell/JQ exact-main gate |
| **Config file** | `mix.exs`, `test/test_helper.exs` |
| **Quick run command** | `mix test test/scripts/phase_164_repository_truth_test.exs test/scripts/phase_164_closeout_test.exs test/scripts/scheduled_control_evidence_test.exs test/mailglass/publish/maintaining_release_gate_contract_test.exs test/mailglass/docs_contract_test.exs --warnings-as-errors --no-deps-check` |
| **Full suite command** | `mix ci.fast` |
| **Estimated runtime** | Each focused test command under 2 minutes; `mix ci.fast` under 15 minutes |

---

## Sampling Rate

- **After every task commit:** Run the focused automated command named by that task.
- **After every plan wave:** Run `mix ci.fast` after all implementation tasks in the wave are integrated; run the focused closeout/scheduled contracts after Waves 8 and 9.
- **Pre-verification checkpoint:** Plan 164-12 runs `/finalize-phase 164 --pre-verification` after implementation Plans 01-11 and their summaries reach protected main. The verifier independently checks this exact-SHA evidence and permits only the later Plan 12 summary/metadata handoff as a non-implementation delta.
- **After normal execute-phase metadata:** Integrate all Phase 164 SUMMARY files and the tracked VERIFICATION, ROADMAP, STATE, and REQUIREMENTS completion updates before terminal capture.
- **Post-execution finalization:** Run `/finalize-phase 164` outside phase-plan-index after the final tracked SHA receives attempt-1 normal push CI and naturally scheduled attempt-1 exact-SHA evidence. The gate writes ignored runtime artifacts only and permits no later tracked commit.
- **Max feedback latency:** 15 minutes.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | Verification Asset | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|--------------------|--------|
| 164-01-01 | 164-01 tracer | 1 | TRTH-02 | T-164-01, T-164-02, T-164-03 | The locked stale root sweep is ledgered once, digest-checked before removal, and not concealed by ignore changes | Wave 0 schema/removal contract | `mix test test/scripts/phase_164_repository_truth_test.exs --warnings-as-errors --no-deps-check` | `test/scripts/phase_164_repository_truth_test.exs` — created first by tracer | ⬜ pending |
| 164-02-01 | 164-02 | 2 | TRTH-01 | T-164-04, T-164-05, T-164-06 | Current maintainer prose preserves protected authority, fail-closed evidence semantics, and the historical boundary | docs contract | `mix test test/mailglass/publish/maintaining_release_gate_contract_test.exs --warnings-as-errors --no-deps-check` | existing test extended | ⬜ pending |
| 164-03-01 | 164-03 | 2 | TRTH-01 | T-164-07, T-164-08 | Current README constraints derive from manifests while historical records remain bounded | docs contract | `mix test test/mailglass/docs_contract_test.exs --warnings-as-errors --no-deps-check` | existing test extended | ⬜ pending |
| 164-04-01 | 164-04 | 2 | TRTH-02 | T-164-09, T-164-10, T-164-11 | Every scoped artifact and every non-comment rule in six ignore files maps bijectively to one complete evidence-backed disposition | Wave 0 expansion/schema contract | `mix test test/scripts/phase_164_repository_truth_test.exs --warnings-as-errors --no-deps-check` | tracer-created test expanded | ⬜ pending |
| 164-05-01 | 164-05 | 3 | TRTH-03 | T-164-12, T-164-13, T-164-14, T-164-15 | The wrapper fails closed on wrong identity, dirt, incomplete ledger, malformed external data, and invalid scheduled provenance | Wave 0 fixture-backed integration contract | `mix test test/scripts/phase_164_closeout_test.exs --warnings-as-errors --no-deps-check` | `test/scripts/phase_164_closeout_test.exs` — created before wrapper implementation | ⬜ pending |
| 164-05-02 | 164-05 | 3 | TRTH-03 | T-164-14, T-164-15 | The durable usage contract documents the same CLI, volatile `/tmp/` report boundary, pass conditions, and non-pass precedence enforced by the wrapper | closeout docs/CLI contract | `mix test test/scripts/phase_164_closeout_test.exs --warnings-as-errors --no-deps-check` | Plan 164-05 Task 1 test expanded/used | ⬜ pending |
| 164-06-01 | 164-06 checkpoint | 4 | TRTH-01, TRTH-02, TRTH-03 | T-164-16, T-164-17 | Only exact protected-main and a terminal normally triggered same-SHA CI identity advance; manual or authority-changing substitutes are rejected | blocking checkpoint prerequisite contract | `test -x scripts/closeout_repository_truth.sh && mix test test/scripts/phase_164_repository_truth_test.exs test/scripts/phase_164_closeout_test.exs test/mailglass/publish/maintaining_release_gate_contract_test.exs test/mailglass/docs_contract_test.exs --warnings-as-errors --no-deps-check` | implementation tests from Waves 1-3 plus human exact-main handoff | ⬜ pending |
| 164-07-01 | 164-07 | 5 | TRTH-01, TRTH-02, TRTH-03 | T-164-18, T-164-19, T-164-20, T-164-21 | A read-only re-query emits pass only for the checkpoint SHA/run with complete pass or evidence-valid blocked components and a still-clean tree | live exact-main report gate | `report=tmp/phase-164-closeout/report.json; test -s "$report" && jq -e --arg sha "<main_sha>" --argjson run "<ci_run_id>" '.status == "pass" and .head_sha == $sha and .origin_main_sha == $sha and (.ci_run_id | tonumber) == $run and ([.components[].status] | all(. == "pass" or . == "blocked"))' "$report" && test -z "$(git status --porcelain=v1 --untracked-files=all)"` | volatile report created by the task after placeholder substitution | ⬜ pending |
| 164-08-01 | 164-08 | 6 | TRTH-02 | T-164-22, T-164-23, T-164-24 | The shared production validator enforces exact currentness, stale outcomes, uniqueness, and complete repository-derived audited subjects | adversarial contract | `mix test test/scripts/phase_164_repository_truth_test.exs --warnings-as-errors --no-deps-check` | `scripts/validate_repository_truth.exs`, repository-truth test | ✅ green |
| 164-08-02 | 164-08 | 6 | TRTH-02 | T-164-22, T-164-23 | The authoritative ledger passes the same complete contract consumed by closeout | production validator | `mix run scripts/validate_repository_truth.exs -- --repo /Users/jon/projects/mailglass --ledger /Users/jon/projects/mailglass/.planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv` | canonical ledger and validator | ✅ green |
| 164-09-01 | 164-09 | 7 | TRTH-02, TRTH-03 | T-164-25, T-164-26, T-164-27, T-164-28 | Noncanonical repositories/ledgers/outputs and post-write dirt cannot pass | adversarial integration contract | `mix test test/scripts/phase_164_closeout_test.exs --warnings-as-errors --no-deps-check` | hardened closeout script and test | ✅ green |
| 164-09-02 | 164-09 | 7 | TRTH-03 | T-164-27, T-164-28 | Durable closeout guidance matches canonical identities, ignored output, and post-write cleanliness | docs/CLI contract | `mix test test/scripts/phase_164_closeout_test.exs --warnings-as-errors --no-deps-check` | `164-CLOSEOUT.md` contract assertions | ✅ green |
| 164-10-01 | 164-10 tracer | 8 | TRTH-03 | T-164-36, T-164-37, T-164-38, T-164-39 | Closeout trusts registry-specific authoritative freshness while retaining exact identity/provenance checks | TDD runtime regression | `mix test test/scripts/phase_164_closeout_test.exs test/scripts/scheduled_control_evidence_test.exs --warnings-as-errors --no-deps-check && bash -n scripts/closeout_repository_truth.sh` | production scheduled-report predicate plus dynamic fixtures | ⬜ pending |
| 164-11-01 | 164-11 | 9 | TRTH-02, TRTH-03 | T-164-40, T-164-41 | The project-local command validates phase/mode, dispatches one tracked finalizer with `pi.exec`, loads under pinned GSD 2.80.0, and exposes no `.gsd` runtime state | extension/runtime/ignore contract | Plan 164-11 Task 1 exact command, including `ASDF_NODEJS_VERSION=22.14.0 gsd --print --no-session "/finalize-phase 164 --pre-verification"` | manifest, extension source, real blocked-precondition invocation, exact ignore behavior | ⬜ pending |
| 164-11-02 | 164-11 | 9 | TRTH-03 | T-164-42, T-164-43, T-164-44 | Finalizer selects attempt-1 exact normal push CI automatically, consumes attempt-1 natural schedules, validates raw sources, and forbids later tracked writes | runtime/lifecycle contract | `mix test test/scripts/phase_164_closeout_test.exs test/scripts/scheduled_control_evidence_test.exs --warnings-as-errors --no-deps-check && bash -n scripts/finalize_phase_164.sh .planning/phases/164-repository-truth-reconciliation-and-closeout/164-FINALIZE.sh` | CI monitor attempt field, scheduled authority attempt provenance, production finalizer, phase shim, `164-FINALIZATION.md` | ⬜ pending |
| 164-11-03 | 164-11 | 9 | TRTH-02, TRTH-03 | T-164-40, T-164-41 | The extension, finalizer, lifecycle contract, and changed ignore rules have exact-one complete durable dispositions | production ledger validator | `mix run scripts/validate_repository_truth.exs -- --repo /Users/jon/projects/mailglass --ledger /Users/jon/projects/mailglass/.planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv` | canonical ledger and validator | ⬜ pending |
| 164-12-01 | 164-12 checkpoint | 10 | TRTH-03 | T-164-42, T-164-43, T-164-44 | Protected implementation SHA has attempt-1 push CI and natural schedules before verification; report is explicitly non-terminal | live pre-verification gate | `/finalize-phase 164 --pre-verification` after protected integration | ignored pre-verification inputs/report/raw sources | ⬜ pending |
| 164-FINAL | post-execution gate | after phase.complete integration | TRTH-03 | T-164-40, T-164-41, T-164-42, T-164-43, T-164-44 | Final protected metadata SHA has attempt-1 normal push CI, attempt-1 natural schedules, ignored identity/report state, independently verified raw sources, and no later tracked commit | live lifecycle gate | `/finalize-phase 164` | ignored `finalization-inputs.json`, report, CI source, scheduled source | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] **Plan 164-01 owns creation:** `test/scripts/phase_164_repository_truth_test.exs` — TSV schema, required fields, unique subject/disposition enum, locked D-08 digest/removal row, root-file absence, and unchanged ignore treatment.
- [ ] **Plan 164-04 owns expansion:** the same repository-truth test derives the full audited artifact set and all six ignore-rule sets, then enforces exact-one set equality, durable-proof discoverability, and fail-closed malformed/duplicate/missing cases.
- [ ] **Plan 164-05 Task 1 owns creation before production code:** `test/scripts/phase_164_closeout_test.exs` — disposable-repository and PATH-stub fixtures for pass, wrong branch/SHA, dirt, incomplete ledger, pending/cannot-check, malformed data, and evidence-valid policy-blocked outcomes.
- [ ] **Plan 164-05 Task 2 owns contract extension/use:** the closeout test verifies `164-CLOSEOUT.md` names the exact wrapper flags, existing `tmp/phase-164-closeout/report.json` treatment, D-10 through D-12 conditions, and volatile/untracked semantics.
- [ ] **Plan 164-10 owns freshness regression expansion:** the closeout test executes the production scheduled-report predicate with daily evidence beyond three hours and adversarial exact-provenance mutations.
- [ ] **Plan 164-11 owns the missing lifecycle primitive:** extension/ignore contracts prove only the named finalizer is versioned; closeout/scheduled tests prove attempt-1 automatic exact push-CI selection, both lifecycle modes, ignored identities, raw CI/scheduled verification, and no tracked post-capture artifact.
- [ ] **Plan 164-12 owns the non-circular external checkpoint:** the ignored pre-verification report proves protected implementation behavior before the verifier writes completion metadata and is never represented as terminal evidence.

`wave_0_complete` remains `false` until these test assets exist and their plan-specific commands have run successfully. Their creation is executor work, not evidence that the planning contract may predeclare complete.

---

## Manual / External-State Verification

| Task | Behavior | Requirement | Why External State Is Required | Verification Instructions |
|------|----------|-------------|-------------------------------|---------------------------|
| 164-06-01 | Protected-main handoff | TRTH-01, TRTH-02, TRTH-03 | Durable changes must first reach protected `main`, and normal CI/scheduled controls must produce exact-SHA evidence | Fetch origin in `/Users/jon/projects/mailglass`; require local `main` and `HEAD == origin/main`; select only a terminal normally triggered CI run whose `headSha` equals that SHA; wait for applicable registered scheduled controls to carry fresh same-SHA provenance; provide `main_sha` and `ci_run_id`. |
| 164-07-01 | Exact-main quiet verdict | TRTH-03 | Live GitHub, Git, CI, and scheduled-control evidence can only be sampled after the protected merge | Substitute the checkpoint SHA/run into the Plan 164-07 command, run the read-only wrapper, require report `status: pass`, exact identities, complete component evidence, and empty stable porcelain. Keep the report volatile beneath existing ignored `tmp/`. |
| 164-12-01 | Pre-verification exact-main capture | TRTH-03 | Ordinary verification previously failed without fresh operational proof, but terminal proof cannot precede tracked completion metadata | Integrate implementation and summaries through Plan 164-11 normally; run `/finalize-phase 164 --pre-verification`; let the verifier independently inspect attempt-1 raw sources and recognize the later Plan 12 summary as non-implementation metadata. |
| 164-FINAL | Post-execution exact-main finalization | TRTH-03 | Normal verifier output and phase.complete tracking write tracked files after the pre-verification capture; terminal evidence must follow their protected integration | Integrate every SUMMARY plus passed VERIFICATION/ROADMAP/STATE/REQUIREMENTS update to protected main; then run `/finalize-phase 164`. The command automatically selects attempt-1 exact normal push CI, consumes only attempt-1 natural schedules, independently validates raw sources, and permits no later tracked commit. |

---

## Validation Sign-Off

### Planning-contract completeness

- [x] All seventeen executor tasks across all twelve plans have an automated verification row, plus one explicit terminal post-execution lifecycle gate.
- [x] The tracer-created repository-truth test, Plan 164-04 expansion, Plan 164-05 test/wrapper and usage contract, Plan 164-06 checkpoint, and Plan 164-07 exact-main report are explicitly mapped.
- [x] TRTH-01 and TRTH-02 retain completed task-level coverage; TRTH-03 maps through the freshness repair, tracked lifecycle contract, and terminal post-execution raw-source gate.
- [x] Sampling continuity has no three consecutive tasks without automated feedback.
- [x] No watch-mode flags or error-suppressing validation fallbacks are used.
- [x] Planned focused feedback remains under the 15-minute maximum.
- [x] `nyquist_compliant: true` reflects this complete plan-time validation contract.

### Implementation completion

- [ ] Wave 0 test files have been created.
- [ ] Wave 0 focused commands have run green; only then set `wave_0_complete: true`.
- [ ] Waves 1-3 focused and wave gates have run green.
- [ ] Plan 164-06 protected-main checkpoint has supplied exact identities.
- [ ] Plan 164-07 exact-main report gate has passed on fresh live evidence.
- [ ] Plan 164-10 registry-specific freshness repair and adversarial provenance contract have run green.
- [ ] Plan 164-11 extension, narrow `.gsd` ignore boundary, finalizer, lifecycle guidance, ledger rows, and focused tests have run green.
- [ ] Plan 164-12 pre-verification protected capture has passed and ordinary verification has independently checked its raw evidence.
- [ ] All tracked Phase 164 summaries and phase.complete metadata have reached protected main before terminal `/finalize-phase 164` runs.
- [ ] The final ignored report and raw CI/scheduled sources pass independent verification with no later tracked commit.

**Approval:** Planning contract complete and Nyquist-compliant; ordinary verification proves the installed capability before phase completion, and live exact-main sign-off follows through the no-tracked-output `/finalize-phase 164` gate.
