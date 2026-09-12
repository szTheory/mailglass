---
phase: 164
slug: repository-truth-reconciliation-and-closeout
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-26
revised: 2026-09-12
---

# Phase 164 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. The contract covers the completed PLAN/SUMMARY pair set 01 through 43 plus the Plan 164-44 reconciliation and the terminal non-plan finalization gate required after all tracked GSD metadata reaches protected main.

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
- **Pre-verification checkpoint:** Plan 164-14 ran the then-current pre-verification command after the Plan 164-13 adversarial regression locks reached protected main. Plans 164-16 through 164-24 subsequently changed tracked documentation, trust-anchor implementation, installation state, and tests, so that older capture remains explicitly non-terminal; refreshed ordinary verification must evaluate the repaired implementation through Plan 164-24 before terminal finalization.
- **Plans 164-21 through 164-24:** No task ran canonical pre-verification or terminal finalization. These plans proved immutable source, exact history, installed identity, and adversarial subprocess behavior only.
- **Plans 164-25 through 164-34:** These plans establish repaired implementation, approved installed-loader readiness, bounded repository-truth diagnostics, and reconciled records only. Their test commands do not invoke canonical pre-verification or terminal finalization.
- **Plans 164-35 through 164-39:** These plans establish physical BEAM closure, immutable OID handoff, protected integration, exact approval, recoverable installation, and final tracked reconciliation. Their tests and inspection modes remain non-terminal.
- **Plans 164-40 through 164-44:** These plans harden regular-file/index truth, structural plan enumeration, disposable loader attacks, current maintainer authority, and final canonical evidence. Their fresh repository and controlled-host results remain ordinary non-terminal evidence.
- **Verified implementation lifecycle:** Plan 164-15 requires the ordinary verifier to record the exact implementation commit as `verified_implementation_sha`. Terminal finalization accepts only an ancestor SHA and inspects every subsequent first-parent commit relative to its first parent against the four exact completion-metadata paths, so change-then-revert source history remains visible.
- **After normal execute-phase metadata:** Integrate all Phase 164 SUMMARY files and the tracked VERIFICATION, ROADMAP, STATE, and REQUIREMENTS completion updates before terminal capture.
- **Post-execution finalization:** Run `/Users/jon/.local/bin/mailglass-finalize-phase 164` outside phase-plan-index after the final tracked SHA receives attempt-1 normal push CI and naturally scheduled attempt-1 exact-SHA evidence. The gate writes ignored runtime artifacts only and permits no later tracked commit.
- **Max feedback latency:** 15 minutes.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | Verification Asset | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|--------------------|--------|
| 164-01-01 | 164-01 tracer | 1 | TRTH-02 | T-164-01, T-164-02, T-164-03 | The locked stale root sweep is ledgered once, digest-checked before removal, and not concealed by ignore changes | Wave 0 schema/removal contract | `mix test test/scripts/phase_164_repository_truth_test.exs --warnings-as-errors --no-deps-check` | `test/scripts/phase_164_repository_truth_test.exs` — created first by tracer | ✅ green |
| 164-02-01 | 164-02 | 2 | TRTH-01 | T-164-04, T-164-05, T-164-06 | Current maintainer prose preserves protected authority, fail-closed evidence semantics, and the historical boundary | docs contract | `mix test test/mailglass/publish/maintaining_release_gate_contract_test.exs --warnings-as-errors --no-deps-check` | existing test extended | ✅ green |
| 164-03-01 | 164-03 | 2 | TRTH-01 | T-164-07, T-164-08 | Current README constraints derive from manifests while historical records remain bounded | docs contract | `mix test test/mailglass/docs_contract_test.exs --warnings-as-errors --no-deps-check` | existing test extended | ✅ green |
| 164-04-01 | 164-04 | 2 | TRTH-02 | T-164-09, T-164-10, T-164-11 | Every scoped artifact and every non-comment rule in six ignore files maps bijectively to one complete evidence-backed disposition | Wave 0 expansion/schema contract | `mix test test/scripts/phase_164_repository_truth_test.exs --warnings-as-errors --no-deps-check` | tracer-created test expanded | ✅ green |
| 164-05-01 | 164-05 | 3 | TRTH-03 | T-164-12, T-164-13, T-164-14, T-164-15 | The wrapper fails closed on wrong identity, dirt, incomplete ledger, malformed external data, and invalid scheduled provenance | Wave 0 fixture-backed integration contract | `mix test test/scripts/phase_164_closeout_test.exs --warnings-as-errors --no-deps-check` | `test/scripts/phase_164_closeout_test.exs` — created before wrapper implementation | ✅ green |
| 164-05-02 | 164-05 | 3 | TRTH-03 | T-164-14, T-164-15 | The durable usage contract documents the same CLI, volatile `/tmp/` report boundary, pass conditions, and non-pass precedence enforced by the wrapper | closeout docs/CLI contract | `mix test test/scripts/phase_164_closeout_test.exs --warnings-as-errors --no-deps-check` | Plan 164-05 Task 1 test expanded/used | ✅ green |
| 164-06-01 | 164-06 checkpoint | 4 | TRTH-01, TRTH-02, TRTH-03 | T-164-16, T-164-17 | Only exact protected-main and a terminal normally triggered same-SHA CI identity advance; manual or authority-changing substitutes are rejected | blocking checkpoint prerequisite contract | `test -x scripts/closeout_repository_truth.sh && mix test test/scripts/phase_164_repository_truth_test.exs test/scripts/phase_164_closeout_test.exs test/mailglass/publish/maintaining_release_gate_contract_test.exs test/mailglass/docs_contract_test.exs --warnings-as-errors --no-deps-check` | implementation tests from Waves 1-3 plus human exact-main handoff | ✅ automated prerequisite green; fresh external handoff required |
| 164-07-01 | 164-07 | 5 | TRTH-01, TRTH-02, TRTH-03 | T-164-18, T-164-19, T-164-20, T-164-21 | A read-only re-query emits pass only for the checkpoint SHA/run with complete pass or evidence-valid blocked components and a still-clean tree | live exact-main report gate | `report=tmp/phase-164-closeout/report.json; test -s "$report" && jq -e --arg sha "<main_sha>" --argjson run "<ci_run_id>" '.status == "pass" and .head_sha == $sha and .origin_main_sha == $sha and (.ci_run_id | tonumber) == $run and ([.components[].status] | all(. == "pass" or . == "blocked"))' "$report" && test -z "$(git status --porcelain=v1 --untracked-files=all)"` | volatile report created by the task after placeholder substitution | ✅ capability green; fresh external capture required |
| 164-08-01 | 164-08 | 6 | TRTH-02 | T-164-22, T-164-23, T-164-24 | The shared production validator enforces exact currentness, stale outcomes, uniqueness, and complete repository-derived audited subjects | adversarial contract | `mix test test/scripts/phase_164_repository_truth_test.exs --warnings-as-errors --no-deps-check` | `scripts/validate_repository_truth.exs`, repository-truth test | ✅ green |
| 164-08-02 | 164-08 | 6 | TRTH-02 | T-164-22, T-164-23 | The authoritative ledger passes the same complete contract consumed by closeout | production validator | `mix run scripts/validate_repository_truth.exs -- --repo /Users/jon/projects/mailglass --ledger /Users/jon/projects/mailglass/.planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv` | canonical ledger and validator | ✅ green |
| 164-09-01 | 164-09 | 7 | TRTH-02, TRTH-03 | T-164-25, T-164-26, T-164-27, T-164-28 | Noncanonical repositories/ledgers/outputs and post-write dirt cannot pass | adversarial integration contract | `mix test test/scripts/phase_164_closeout_test.exs --warnings-as-errors --no-deps-check` | hardened closeout script and test | ✅ green |
| 164-09-02 | 164-09 | 7 | TRTH-03 | T-164-27, T-164-28 | Durable closeout guidance matches canonical identities, ignored output, and post-write cleanliness | docs/CLI contract | `mix test test/scripts/phase_164_closeout_test.exs --warnings-as-errors --no-deps-check` | `164-CLOSEOUT.md` contract assertions | ✅ green |
| 164-10-01 | 164-10 tracer | 8 | TRTH-03 | T-164-36, T-164-37, T-164-38, T-164-39 | Closeout trusts registry-specific authoritative freshness while retaining exact identity/provenance checks | TDD runtime regression | `mix test test/scripts/phase_164_closeout_test.exs test/scripts/scheduled_control_evidence_test.exs --warnings-as-errors --no-deps-check && bash -n scripts/closeout_repository_truth.sh` | production scheduled-report predicate plus dynamic fixtures | ✅ green |
| 164-11-01 | 164-11 | 9 | TRTH-02, TRTH-03 | T-164-40, T-164-41 | The project-local command validates phase/mode, dispatches one tracked finalizer with `pi.exec`, loads under pinned GSD 2.80.0, and exposes no `.gsd` runtime state | extension/runtime/ignore contract | Plan 164-11 Task 1 exact command, including `ASDF_NODEJS_VERSION=22.14.0 gsd --print --no-session "/finalize-phase 164 --pre-verification"` | manifest, extension source, real blocked-precondition invocation, exact ignore behavior | ✅ green |
| 164-11-02 | 164-11 | 9 | TRTH-03 | T-164-42, T-164-43, T-164-44 | Finalizer selects attempt-1 exact normal push CI automatically, consumes attempt-1 natural schedules, validates raw sources, and forbids later tracked writes | runtime/lifecycle contract | `mix test test/scripts/phase_164_closeout_test.exs test/scripts/scheduled_control_evidence_test.exs --warnings-as-errors --no-deps-check && bash -n scripts/finalize_phase_164.sh .planning/phases/164-repository-truth-reconciliation-and-closeout/164-FINALIZE.sh` | CI monitor attempt field, scheduled authority attempt provenance, production finalizer, phase shim, `164-FINALIZATION.md` | ✅ green |
| 164-11-03 | 164-11 | 9 | TRTH-02, TRTH-03 | T-164-40, T-164-41 | The extension, finalizer, lifecycle contract, and changed ignore rules have exact-one complete durable dispositions | production ledger validator | `mix run scripts/validate_repository_truth.exs -- --repo /Users/jon/projects/mailglass --ledger /Users/jon/projects/mailglass/.planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv` | canonical ledger and validator | ✅ green |
| 164-12-01 | 164-12 checkpoint | 10 | TRTH-03 | T-164-42, T-164-43, T-164-44 | Protected implementation SHA has attempt-1 push CI and natural schedules before verification; report is explicitly non-terminal | live pre-verification gate | `/finalize-phase 164 --pre-verification` after protected integration | ignored pre-verification inputs/report/raw sources | ✅ capability green; fresh external capture required after remediation integration |
| 164-13-01 | 164-13 tracer | 11 | TRTH-02 | T-164-45 | The production ledger validator rejects forged currentness, stale-retain, vacuous/incomplete inventories, and adjacent or separated duplicate subjects while remaining order-invariant | tagged adversarial integration contract | `mix test test/scripts/phase_164_repository_truth_test.exs --only phase_164_gap_closure --warnings-as-errors --no-deps-check` | production validator plus tagged ledger mutation matrix | ✅ green (4 tests) |
| 164-13-02 | 164-13 | 11 | TRTH-03 | T-164-46, T-164-47, T-164-48 | The closeout process rejects alternate repository/ledger identities and hostile destinations before collection, and late dirt overrides a clean preflight | tagged adversarial process contract | `mix test test/scripts/phase_164_closeout_test.exs --only phase_164_gap_closure --warnings-as-errors --no-deps-check` | production closeout process plus hostile path/write fixtures | ✅ green (4 tests) |
| 164-14-01 | 164-14 checkpoint | 12 | TRTH-01, TRTH-02, TRTH-03 | T-164-49, T-164-50, T-164-51, T-164-52 | The integrated repair passes the complete focused contracts and canonical ledger, then exact protected-main pre-verification accepts only attempt-one normal CI and the complete natural scheduled-control set | focused integration plus live pre-verification gate | `mix test test/scripts/phase_164_repository_truth_test.exs test/scripts/phase_164_closeout_test.exs test/mailglass/publish/maintaining_release_gate_contract_test.exs test/mailglass/docs_contract_test.exs --warnings-as-errors --no-deps-check && elixir scripts/validate_repository_truth.exs --repo /Users/jon/projects/mailglass --ledger /Users/jon/projects/mailglass/.planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv` | 81-test focused suite, production ledger validator, and ignored exact-SHA report/raw sources | ✅ green; pre-verification capture passed at `d903b040c72fff62a69a57cacbcc7e7d7c2f6167` |
| 164-15-01 | 164-15 tracer | 13 | TRTH-03 | T-164-53 | Terminal authority requires one valid ancestor `verified_implementation_sha`; every later first-parent commit is inspected relative to its first parent against only `164-VERIFICATION.md`, `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, and `.planning/STATE.md` | isolated Git process regression and lifecycle contract | `mix test test/scripts/phase_164_closeout_test.exs --warnings-as-errors --no-deps-check && bash -n scripts/finalize_phase_164.sh` | production terminal gate, direct forbidden-source and change-then-revert fixtures, permitted metadata-only fixture, `164-FINALIZATION.md` | ✅ green |
| 164-15-02 | 164-15 | 13 | TRTH-03 | T-164-54, T-164-55 | Pre-verification requires summaries 01 through 13 before collection; lexical-prefix sibling fixtures are exclusively allocated and recursively removed only while lstat, resolved parent, basename, and invocation token still prove ownership | process prerequisite and teardown safety regression | `mix test test/scripts/phase_164_closeout_test.exs --warnings-as-errors --no-deps-check && bash -n scripts/finalize_phase_164.sh` | missing-Plan-13 collection marker, pre-existing-candidate fixture, token-replacement survival fixture | ✅ green |
| 164-15-03 | 164-15 | 13 | TRTH-03 | T-164-56, T-164-57 | Producer sweep and independent terminal raw-source validation both require `0 <= now - updated_at <= max_age_seconds` from the tracked per-control registry | two-seam temporal process regression | `mix test test/scripts/phase_164_closeout_test.exs test/scripts/scheduled_control_evidence_test.exs --warnings-as-errors --no-deps-check && bash -n scripts/finalize_phase_164.sh scripts/scheduled_control_evidence.sh` | invalid ISO-8601, one-day-future, age-zero/current, in-range, and over-age fixtures at both production predicates | ✅ green |
| 164-16-01 | 164-16 tracer | 14 | TRTH-01 | T-164-58, T-164-59, T-164-60 | Every byte before the single historical boundary rejects automatic, reviewer-free, or approval-free authority while retaining the protected exact-candidate/repository-admin model and historical v0.1/v0.5 provenance | whole-document docs contract | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/mailglass/publish/maintaining_release_gate_contract_test.exs --warnings-as-errors --no-deps-check && git diff --check` | `MAINTAINING.md` plus four active position-independent contract tests | ✅ green (4 tests) |
| 164-17-01 | 164-17 tracer | 15 | TRTH-02 | T-164-61, T-164-64 | Every tracked ledger row requires an exact regular-file subject and the sole byte-exact literal-pathspec Git-index result; direct CLI misuse fails nonzero without triggering during module load | tagged adversarial integration contract | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/scripts/phase_164_repository_truth_test.exs --only phase_164_trust_anchor --warnings-as-errors --no-deps-check` | production `RepositoryTruthLedger.validate/2` and CLI through disposable-repository and subprocess fixtures | ✅ green (3 tests) |
| 164-17-02 | 164-17 | 15 | TRTH-03 | T-164-62, T-164-63 | The real registered handler authenticates both exact HEAD executables, rejects staged-new and staged/unstaged divergence, executes only a private downstream HEAD materialization, and removes it on success or failure | tagged adversarial process contract | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/scripts/phase_164_closeout_test.exs --only phase_164_trust_anchor --warnings-as-errors --no-deps-check` | real extension handler with disposable Git repositories and real Git/Bash subprocesses | ✅ green (1 test) |
| 164-18-01 | 164-18 tracer | 16 | TRTH-02 | T-164-65, T-164-66, T-164-67 | A tracked disposition requires exactly one complete NUL-delimited stage-0 record for the byte-exact literal subject; genuine stage-1/2/3 conflicts, missing, duplicate, malformed, nonzero-stage, and mismatched records fail closed | tagged production Git-index contract | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/scripts/phase_164_repository_truth_test.exs --only phase_164_stage0_index --warnings-as-errors --no-deps-check` | production staged-record parser plus genuine unmerged disposable repository | ✅ green (4 selected, 20 excluded, 0 failures) |
| 164-19-01 | 164-19 tracer | 17 | TRTH-03 | T-164-68, T-164-71, T-164-72 | Only the lexical non-symlink regular-file Phase 164 shim is authenticated before resolution; unsupported phases never reach discovery, and print failures clean private state before reporting non-success | tagged real-dispatcher contract | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/scripts/phase_164_closeout_test.exs --only phase_164_dispatcher_boundary --warnings-as-errors --no-deps-check` | registered TypeScript handler exercised through real Git, Node, and Bash subprocesses | ✅ green (4 selected, 33 excluded, 0 failures) |
| 164-19-02 | 164-19 | 17 | TRTH-03 | T-164-69, T-164-70 | Every transitive executable and data input is authenticated and materialized from HEAD under one private authority root before Bash; hidden assume-unchanged checkout mutations cannot affect execution | tagged authenticated-chain contract | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/scripts/phase_164_closeout_test.exs --only phase_164_transitive_chain --warnings-as-errors --no-deps-check` | closed dependency manifest, private authority-root materialization, and hostile helper/data mutations | ✅ green (4 selected, 33 excluded, 0 failures) |
| 164-20-01 | 164-20 | 18 | TRTH-02, TRTH-03 | T-164-73, T-164-74, T-164-75 | Validation and finalization records describe the repaired stage-0 and authenticated-authority behavior without claiming that terminal evidence was captured during execution | complete focused suite, canonical validator, and syntax contract | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/scripts/phase_164_repository_truth_test.exs test/scripts/phase_164_closeout_test.exs test/mailglass/publish/maintaining_release_gate_contract_test.exs test/mailglass/docs_contract_test.exs test/scripts/scheduled_control_evidence_test.exs --warnings-as-errors --no-deps-check && ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 elixir scripts/validate_repository_truth.exs --repo /Users/jon/projects/mailglass --ledger /Users/jon/projects/mailglass/.planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv && bash -n scripts/finalize_phase_164.sh scripts/closeout_repository_truth.sh && git diff --check` | current validation/finalization records compared with Plans 164-18 and 164-19 production seams | ✅ green (114 tests, 0 failures, 1 pre-existing skip; ledger and syntax valid) |
| 164-21-01 | 164-21 | 19 | TRTH-03 | T-164-76, T-164-78, T-164-79 | One captured full OID governs every authenticated read; moving HEAD fails before Bash and private bytes are removed on every outcome | installed-loader precursor regression | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/scripts/phase_164_closeout_test.exs --only phase_164_immutable_loader --warnings-as-errors --no-deps-check && node --check scripts/mailglass_finalize_phase_loader.mjs && git diff --check` | standalone loader plus real Git/Node/Bash fixtures | ✅ green (7 selected, 37 excluded, 0 failures) |
| 164-21-02 | 164-21 | 19 | TRTH-03 | T-164-77, T-164-79 | Exact PLAN/SUMMARY pairs 01-24 reject middle, baseline-terminal, current-terminal, singleton, malformed, and unexpected identities before Bash | fixed-history regression and canonical validator | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/scripts/phase_164_closeout_test.exs --only phase_164_immutable_loader --warnings-as-errors --no-deps-check && bash -n scripts/finalize_phase_164.sh && ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 elixir scripts/validate_repository_truth.exs --repo /Users/jon/projects/mailglass --ledger /Users/jon/projects/mailglass/.planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv && git diff --check` | loader/shell range constants and ledger | ✅ green |
| 164-22-01 | 164-22 | 20 | TRTH-02, TRTH-03 | T-164-80, T-164-81, T-164-83 | Retired checkout extension identities remain ledgered while hostile recreation cannot influence direct loader execution | installed-boundary and ledger regression | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/scripts/phase_164_closeout_test.exs --only phase_164_installed_boundary --warnings-as-errors --no-deps-check && ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/scripts/phase_164_repository_truth_test.exs --warnings-as-errors --no-deps-check && ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 elixir scripts/validate_repository_truth.exs --repo /Users/jon/projects/mailglass --ledger /Users/jon/projects/mailglass/.planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv && git diff --check` | removed extension paths, retained ledger evidence, hostile fixture | ✅ green (3 installed-boundary tests, 0 failures) |
| 164-22-02 | 164-22 | 20 | TRTH-01, TRTH-03 | T-164-82 | Current maintainer and lifecycle prose expose only the absolute installed command and bound the old slash command to history | whole-current-region docs contract | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/mailglass/publish/maintaining_release_gate_contract_test.exs --warnings-as-errors --no-deps-check` | `MAINTAINING.md`, `164-FINALIZATION.md`, maintaining contract | ✅ green (5 tests, 0 failures) |
| 164-23-01 | 164-23 | 21 | TRTH-03 | T-164-84, T-164-85 | Clean committed source and destination lstat observations produce one private mode-0400 proposal; any source/destination drift fails before approval or mutation | immutable install preflight | `test -f /Users/jon/.local/share/mailglass/checkpoints/164-23-install-proposal.env && test ! -L /Users/jon/.local/share/mailglass/checkpoints/164-23-install-proposal.env && test "$(stat -f '%Lp' /Users/jon/.local/share/mailglass/checkpoints/164-23-install-proposal.env)" = 400` plus the Plan 164-23 fixed-key OID/digest/destination preflight | proposal record and captured Git blob digest | ✅ approved preflight observed |
| 164-23-02 | 164-23 | 21 | TRTH-03 | T-164-86, T-164-86A | Approval is exact field-for-field, mode 0400, and explicit; changed or unapproved tuples fail before installation | immutable approval-record verification | `test -f /Users/jon/.local/share/mailglass/checkpoints/164-23-install-approval.env && test ! -L /Users/jon/.local/share/mailglass/checkpoints/164-23-install-approval.env && test "$(stat -f '%Lp' /Users/jon/.local/share/mailglass/checkpoints/164-23-install-approval.env)" = 400 && test "$(grep -c '^approval_status=approved$' /Users/jon/.local/share/mailglass/checkpoints/164-23-install-approval.env)" = 1` | approval record plus exact proposal parity | ✅ approved tuple observed |
| 164-23-03 | 164-23 | 21 | TRTH-03 | T-164-84, T-164-85, T-164-86, T-164-86A | Atomic external mode-0500 install must match the approved blob; prior-object rollback evidence is conditional and any mismatch fails self-check | installed provenance/self-check | `/Users/jon/.local/bin/mailglass-finalize-phase --self-check --repo /Users/jon/projects/mailglass --expected-source-oid 7f57e1cd0aafe6d236624da98f7292e86e6de697` | installed loader, approval record, Plan 164-23 summary | ✅ green; absent-destination rollback branch recorded not-applicable |
| 164-24-01 | 164-24 | 22 | TRTH-03 | T-164-87, T-164-88, T-164-SC | Absolute installed executable accepts captured private bytes, while moving HEAD, deleted pairs 10, 20, and 24, and a hostile retired extension all fail or remain unevaluated before unauthorized Bash | installed production-boundary subprocess regression | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/scripts/phase_164_closeout_test.exs --only phase_164_installed_production_boundary --warnings-as-errors --no-deps-check` | immutable approval/summary parity plus real installed command | ✅ green (5 selected, 46 excluded, 0 failures) |
| 164-24-02 | 164-24 | 22 | TRTH-01, TRTH-02, TRTH-03 | T-164-89, T-164-90 | Current proof records and manifest-derived docs contract report installed-boundary closure without representing it as pre-verification or terminal evidence | complete focused suite, validator, syntax, docs contract | `make toolchain CMD='mix test test/scripts/phase_164_repository_truth_test.exs test/scripts/phase_164_closeout_test.exs test/mailglass/publish/maintaining_release_gate_contract_test.exs test/mailglass/docs_contract_test.exs test/scripts/scheduled_control_evidence_test.exs --warnings-as-errors' && ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 elixir scripts/validate_repository_truth.exs --repo /Users/jon/projects/mailglass --ledger /Users/jon/projects/mailglass/.planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv && node --check scripts/mailglass_finalize_phase_loader.mjs && bash -n scripts/finalize_phase_164.sh scripts/closeout_repository_truth.sh && git diff --check` | `164-VALIDATION.md`, `164-FINALIZATION.md`, stable docs contract | ✅ green (120 tests, 0 failures, 1 historical skip; ledger and syntax valid) |
| 164-25-01 | 164-25 tracer | 23 | TRTH-03 | T-164-105 | Required CI selects repository-owned tests while the host-only installed boundary remains explicit and non-vacuous | `phase_164_ci_hermeticity` source/alias contract plus required lane | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix verify.ci_lane_contract` | `mix.exs`, closeout/CI parity/SuiteFloor contracts | ✅ green (380 selected, 5 excluded, 0 failures) |
| 164-25-02 | 164-25 | 23 | TRTH-03 | T-164-105 | CI workflow and aliases cannot silently reintroduce maintainer-local host authority | focused parity and scheduled-control contracts | Plan 164-25 Task 2 command | exact alias/workflow/source negative controls | ✅ green |
| 164-26-01 | 164-26 tracer | 24 | TRTH-03 | T-164-106 | Loader-owned physical path and normalized origin reject caller-selected repository authority before enumeration | `phase_164_canonical_loader` | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/scripts/phase_164_closeout_test.exs --only phase_164_canonical_loader --warnings-as-errors --no-deps-check` | production loader and foreign-repository rejection | ✅ green (1 selected, 48 excluded, 0 failures) |
| 164-26-02 | 164-26 | 24 | TRTH-03 | T-164-107, T-164-108 | Absolute validated tools, sanitized child environment, and installation ancestry reject forged PATH and unrelated OIDs | `phase_164_trusted_toolchain` | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/scripts/phase_164_closeout_test.exs --only phase_164_trusted_toolchain --warnings-as-errors --no-deps-check` | loader/finalizer trust chain plus unrelated-history fixture | ✅ green (3 selected, 46 excluded, 0 failures) |
| 164-27-01 | 164-27 tracer | 25 | TRTH-03 | T-164-108, T-164-SC | The hardened committed source is the sole eligible reinstall input and adds no package dependency | `phase_164_reinstall_contract` | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/scripts/phase_164_closeout_test.exs --only phase_164_reinstall_contract --warnings-as-errors --no-deps-check` | source-bound reinstall readiness contract | ✅ green (3 selected, 46 excluded, 0 failures) |
| 164-27-02 | 164-27 checkpoint | 25 | TRTH-03 | T-164-108, T-164-SC | Exact immutable approval binds source, tools, destination, prior object, and rollback identity before replacement | external approval checks | Plan 164-27 Task 2 exact proposal/approval parity checks | mode-0400 proposal and approval records | ✅ approved tuple observed |
| 164-27-03 | 164-27 | 25 | TRTH-03 | T-164-106, T-164-107, T-164-108 | Installed bytes match the approved source and reject foreign repository, forged PATH, moving HEAD, and incomplete history attacks | `phase_164_installed_production_boundary` | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix verify.phase_164.installed_boundary` | absolute installed executable and controlled-host attack matrix | ✅ green (5 selected, 44 excluded, 0 failures) |
| 164-28-01 | 164-28 tracer | 26 | TRTH-01, TRTH-02, TRTH-03 | T-164-105 through T-164-109 | Durable validation/security records bind each repaired finding to its production seam and observed regression without claiming terminal completion | `phase_164_gap_reconciliation` | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/mailglass/docs_contract_test.exs test/scripts/phase_164_closeout_test.exs --only phase_164_gap_reconciliation --warnings-as-errors --no-deps-check` | this record, `164-SECURITY.md`, docs contract | ✅ green after record reconciliation |
| 164-28-02 | 164-28 | 26 | TRTH-01, TRTH-02, TRTH-03 | T-164-106, T-164-107, T-164-109 | Exact 01-28 lifecycle contract keeps terminal execution after summary, verifier, protected completion metadata, exact CI, and natural schedules | `phase_164_lifecycle_contract` plus complete phase suite | Plan 164-28 Task 2 command | `164-FINALIZATION.md`, this record, docs contract | ✅ green tracked readiness; terminal evidence remains pending |
| 164-29-01 | 164-29 tracer | 27 | TRTH-03 | T-164-110, T-164-111 | The real installed tuple is authenticated from its approval, Git blob, ancestry, regular-file mode, digest, and direct self-check | `phase_164_installed_production_boundary` | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix verify.phase_164.installed_boundary` | controlled-host approval/install proof | ✅ green (current rerun: 7 selected, 54 excluded, 0 failures) |
| 164-29-02 | 164-29 | 27 | TRTH-03 | T-164-112, T-164-113 | Every root repository/protected suite excludes the controlled-host tag while retaining all disposable source-loader attacks | exhaustive repository-only lane | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix verify.ci_lane_contract` | root ExUnit exclusion plus recursive alias/workflow contract | ✅ green (final rerun: 398 selected, 7 excluded, 0 failures) |
| 164-30-01 | 164-30 tracer | 28 | TRTH-02 | T-164-114, T-164-115, T-164-116 | An empty authority root returns one bounded tagged relative diagnostic and exit 1 without fallback or stack trace | `phase_164_incomplete_authority_root` | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/scripts/phase_164_repository_truth_test.exs --only phase_164_incomplete_authority_root --warnings-as-errors --no-deps-check` | standalone CLI and disposable authority roots | ✅ green (current rerun: 3 selected, 25 excluded, 0 failures) |
| 164-30-02 | 164-30 | 28 | TRTH-02 | T-164-114 through T-164-117 | Declared-order lstat/read results preserve deterministic first-missing behavior for partial, wrong-type, symlink, unreadable, and malformed roots | same non-vacuous focused group plus complete repository-truth suite | Plan 164-30 Task 2 command | shared validator and ordered negative controls | ✅ green |
| 164-31-01 | 164-31 tracer | 29 | TRTH-03 | T-164-118, T-164-120 | Loader and shell authenticate exactly one PLAN/SUMMARY pair for every number 01-34 and reject missing, extra, or malformed members | loader/shell terminal-range contracts | Plan 164-31 Task 1 command | tracked loader, shell, and hostile histories | ✅ green |
| 164-31-02 | 164-31 | 29 | TRTH-03 | T-164-119 | Changed 01-34 bytes remain superseded-pending until a new immutable tuple is approved and installed | lifecycle docs contract | Plan 164-31 Task 2 command | `164-FINALIZATION.md` | ✅ green; no installation or finalization |
| 164-32-01 | 164-32 tracer | 30 | TRTH-03 | T-164-121, T-164-123, T-164-124 | One non-mutating proposal binds committed source, trusted tools, exact prior installed identity, and absent rollback target | approval preflight | Plan 164-32 Task 1 command | private mode-0400 proposal | ✅ proposal observed |
| 164-32-02 | 164-32 checkpoint | 30 | TRTH-03 | T-164-122, T-164-124 | Human approval is byte-for-byte proposal parity plus one exact approval line | blocking approval verification | Plan 164-32 Task 2 verification | private mode-0400 approval | ✅ exact approval observed; no install |
| 164-33-01 | 164-33 | 30 | TRTH-03 | T-164-125, T-164-126, T-164-128 | Approved bytes are installed atomically only after exact rollback preservation; inspection modes run without terminal execution | installation/rollback checks | Plan 164-33 Task 1 command | active mode-0500 install and mode-0400 rollback | ✅ readiness observed |
| 164-33-02 | 164-33 tracer | 30 | TRTH-03 | T-164-127, T-164-128 | Active installed authority matches the Plan 164-32 tuple and exact 01-34 range while repository CI stays host-independent | both distinct aliases | `mix verify.phase_164.installed_boundary` and `mix verify.ci_lane_contract` | controlled-host proof plus repository-only isolation | ✅ green (7/54 controlled-host; 396/7 repository-only) |
| 164-34-01 | 164-34 tracer | 31 | TRTH-01, TRTH-02, TRTH-03 | T-164-129, T-164-131, T-164-109 | Durable validation/security/lifecycle records bind current production seams and preserve pending terminal ordering | `phase_164_gap_reconciliation` and `phase_164_lifecycle_contract` | Plan 164-34 Task 1 command | this record, security/finalization records, docs contract | ✅ green; terminal evidence remains pending |
| 164-34-02 | 164-34 | 31 | TRTH-02 | T-164-130, T-164-132 | Completed-plan subjects remain exact-one with current provenance and canonical relationships; incomplete roots retain bounded diagnostics | complete repository-truth contract and canonical validator | Plan 164-34 Task 2 command | ledger, validator, repository-truth test | ✅ green (30 tests; canonical validator valid) |
| 164-35-01 | 164-35 tracer | 32 | TRTH-03 | T-164-133, T-164-134 | Physical Mix, Elixir, and Erlang files execute compatible exact-child probes in one sanitized environment | authority-closure alias | `mix verify.phase_164.authority_closure` | loader, closeout tests, physical runtime tuple | ✅ green (4 selected, 60 excluded) |
| 164-35-02 | 164-35 | 32 | TRTH-03 | T-164-135 through T-164-137 | One authenticated full OID crosses both Bash boundaries and post-authentication movement fails before evidence | authority-closure alias | `mix verify.phase_164.authority_closure` | loader/finalizer/closeout and movement fixture | ✅ green (4 selected, 60 excluded) |
| 164-36-01 | 164-36 | 33 | TRTH-03 | T-164-138 through T-164-140 | Normal protected integration has one exact successful attempt-one push CI identity | protected observation | PR #249 and CI run `34650810638` | protected `main` SHA `52c07a5051d269b307831a2210f53dec0dd1ff65` | ✅ observed |
| 164-37-01 | 164-37 | 34 | TRTH-03 | T-164-141, T-164-142, T-164-145 | Exact proposal binds protected source/CI, physical toolchain, predecessor, destination, and rollback absence | proposal-boundary alias | `mix verify.phase_164.proposal_boundary` | immutable proposal | ✅ green (4 selected, 60 excluded) |
| 164-37-02 | 164-37 | 34 | TRTH-03 | T-164-143, T-164-144 | Exact human approval publishes only proposal-copy-plus-status and grants no later authority | immutable readback | approval SHA-256 `e3687bf5a2afc69a79b2677c69daa3d533549d4b6f730a30a04e32cc6d13b7cd` | ✅ observed |
| 164-38-01 | 164-38 | 35 | TRTH-03 | T-164-146, T-164-147 | Approved commit bytes replace the active command only after rollback publication | direct inspection and lifecycle contract | Plan 164-38 install/readback | installed and rollback objects | ✅ observed |
| 164-38-02 | 164-38 | 35 | TRTH-03 | T-164-148, T-164-149 | Real installed authority and repository-only CI are disjoint and non-terminal | both distinct aliases | `mix verify.phase_164.installed_boundary` and `mix verify.ci_lane_contract` | controlled-host and repository-only contracts | ✅ green (7/57 installed; 397/11 repository) |
| 164-39-01 | 164-39 tracer | 36 | TRTH-01, TRTH-03 | T-164-150, T-164-154 | Durable records bind current authority and preserve the post-summary terminal order | focused docs/lifecycle groups and authority/install aliases | Plan 164-39 Task 1 command | validation, security, finalization, docs contract | ✅ historical reconciliation retained; terminal pending |
| 164-39-02 | 164-39 | 36 | TRTH-02 | T-164-151 through T-164-153 | Exact-one ledger and canonical relationships reject empty, duplicate, adjacent, ordering, and stale substitutions | repository-truth suite and canonical validator | Plan 164-39 Task 2 command | ledger, validator, repository-truth tests | ✅ historical reconciliation retained; terminal pending |
| 164-40-01 | 164-40 tracer | 37 | TRTH-02 | T-164-155 through T-164-158 | Exact regular worktree and stage-0 index identity precede every tracked/current/hash claim | repository-truth suite and canonical validator | Plan 164-40 Task 1 command | validator and repository-truth attacks | ✅ green; final rerun included in 47-test suite |
| 164-41-01 | 164-41 tracer | 38 | TRTH-02 | T-164-158 through T-164-160 | Opening-frontmatter structure and bounded Git-root failures govern plan evidence enumeration | repository-truth suite and standalone CLI | Plan 164-41 Task 1 command | validator and repository-truth attacks | ✅ green; final rerun included in 47-test suite |
| 164-42-01 | 164-42 tracer | 39 | TRTH-03 | T-164-161 through T-164-163 | Installed-loader attacks run only in disposable repositories with fixture-owned dispatch and exact remote state | repository-only CI | `mix verify.ci_lane_contract` | closeout loader fixtures | ✅ green (414 selected, 11 excluded, 0 failures) |
| 164-43-01 | 164-43 tracer | 40 | TRTH-01, TRTH-03 | T-164-164, T-164-165 | Current Plan 164-37/38 authority is mandatory while Plan 164-23 survives only as superseded history | maintaining authority contract | `mix test test/mailglass/publish/maintaining_release_gate_contract_test.exs --warnings-as-errors --no-deps-check` | maintainer lifecycle prose and contract | ✅ green (5 selected, 0 excluded, 0 failures) |
| 164-44-01 | 164-44 tracer | 41 | TRTH-02 | T-164-167 | Every modified subject from completed Plans 164-40 through 164-43 resolves to one complete current canonical row with fresh hashes | repository-truth suite and canonical validator | Plan 164-44 Task 1 command | ledger, validator, repository-truth tests | ✅ green (47 tests; canonical validator valid) |
| 164-44-02 | 164-44 | 41 | TRTH-01, TRTH-02, TRTH-03 | T-164-166, T-164-168 | Fresh exact command/count evidence supersedes stale current claims while remaining explicitly non-terminal | five prerequisite lanes plus docs contract | Plan 164-44 Task 2 command | this record, security record, docs contract | ✅ five prerequisites green; docs contract 5 selected, 44 excluded, 0 failures after edits |
| 164-FINAL | post-execution gate | after phase.complete integration | TRTH-03 | T-164-40, T-164-41, T-164-42, T-164-43, T-164-44 | Final protected metadata SHA has attempt-1 normal push CI, attempt-1 natural schedules, ignored identity/report state, independently verified raw sources, and no later tracked commit | live lifecycle gate | `/Users/jon/.local/bin/mailglass-finalize-phase 164` | ignored `finalization-inputs.json`, report, CI source, scheduled source | ⚠️ external terminal capture pending |

*Status: ✅ automated capability green · ⚠️ external evidence still required*

---

## Gap Reconciliation — Plans 164-29 through 164-34

This assessment supersedes the stale fixture-backed and raising-path evidence
that remained after Plan 164-28. It reports fresh production-seam behavior from
the completed Plans 164-29, 164-30, and 164-33 repairs. Every command exited 0
with a nonzero selected count. These results are implementation and installation
readiness evidence only; terminal protected-main finalization has not run.

| Finding | Repair / production seam | Named active regression and exact command | Observed result | Failure direction | Security disposition |
|---------|--------------------------|-------------------------------------------|-----------------|-------------------|----------------------|
| GR-29 | Plans 164-29/33 real installed tuple proof; direct `/Users/jon/.local/bin/mailglass-finalize-phase` inspection against the exact Plan 164-32 approval | `phase_164_installed_production_boundary`; `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix verify.phase_164.installed_boundary` | 7 selected, 54 excluded, 0 failures, exit 0 | Missing/malformed approval, non-regular or wrong-mode objects, digest/OID/ancestry drift, incomplete 01-34 history, or self-check disagreement fails nonzero. | T-164-110 through T-164-113 and T-164-125 through T-164-128 closed by controlled-host evidence. |
| GR-30 | Plan 164-30 ordered non-raising authority-root discovery | `phase_164_incomplete_authority_root`; `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/scripts/phase_164_repository_truth_test.exs --only phase_164_incomplete_authority_root --warnings-as-errors --no-deps-check` | 3 selected, 25 excluded, 0 failures, exit 0; empty CLI fixture emits bounded `repository_truth: missing_ignore_subject` data with no stack trace | Empty, incomplete, wrong-type, symlinked, unreadable, or malformed roots return deterministic tagged errors and never fall back to canonical files. | T-164-114 through T-164-117 closed; T-164-132 remains enforced by the same bounded diagnostic seam. |
| GR-33 | Plans 164-29/33 exhaustive full-suite isolation; root ExUnit default exclusion plus recursive alias/workflow checks | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix verify.ci_lane_contract` | 398 selected, 7 excluded, 0 failures, exit 0 | Any unfiltered repository/protected entry point that can collect the host tag, or removal of a disposable attack, fails the alias/workflow/SuiteFloor contracts. | T-164-112 and T-164-113 closed by repository-only CI evidence. |

The active controlled-host installed tuple is Plan 164-32 source OID
`1cfee7802de808f690fe5413b22a57e7ab802488` with source/installed SHA-256
`f01859c551e6611d3bdd4dbae427cba3bc3d63e18fad7d74bbeeacf9953fffac`
and mode 0500. Plan 164-27 prior provenance remains immutable at source OID
`2c7cf25c4ac004df3f960a5e8cb37cf8aef68c97`; its installed bytes remain
recoverable with SHA-256
`0dbcc03466f4da863c63d46ac2f314b4a260e45388e8f770c608d0eb02d8676e`,
and the older Plan 164-23 object retains SHA-256
`ca760f78ab0901dbc537e20ec6c231314afffa7932dd8f1850f4935cabc8b7d9`.
None of these controlled-host facts is ordinary verification or terminal
protected-main evidence.

### Terminal handoff after Plan 164-34

The tracked closeout covers the exact PLAN/SUMMARY pair set 01 through 34.
Plan 164-34 and `164-34-SUMMARY.md` finish before ordinary verification. The
ordinary verifier must then record `status: passed` and its exact
`verified_implementation_sha`; only protected completion metadata may follow,
limited to the four authorized completion paths, before those records reach
protected `main`. That exact protected SHA must receive attempt-1 normal push
CI and naturally produced attempt-1 scheduled evidence before the installed
command may write its ignored terminal capture. No later tracked write is
authorized. T-164-109 therefore remains high and pending: terminal
protected-main evidence remains absent and pending, no terminal run occurred,
and this record makes no phase or requirement completion claim.

---

## Wave 0 Requirements

- [x] **Plan 164-01 owns creation:** `test/scripts/phase_164_repository_truth_test.exs` — TSV schema, required fields, unique subject/disposition enum, locked D-08 digest/removal row, root-file absence, and unchanged ignore treatment.
- [x] **Plan 164-04 owns expansion:** the same repository-truth test derives the full audited artifact set and all six ignore-rule sets, then enforces exact-one set equality, durable-proof discoverability, and fail-closed malformed/duplicate/missing cases.
- [x] **Plan 164-05 Task 1 owns creation before production code:** `test/scripts/phase_164_closeout_test.exs` — disposable-repository and PATH-stub fixtures for pass, wrong branch/SHA, dirt, incomplete ledger, pending/cannot-check, malformed data, and evidence-valid policy-blocked outcomes.
- [x] **Plan 164-05 Task 2 owns contract extension/use:** the closeout test verifies `164-CLOSEOUT.md` names the exact wrapper flags, existing `tmp/phase-164-closeout/report.json` treatment, D-10 through D-12 conditions, and volatile/untracked semantics.
- [x] **Plan 164-10 owns freshness regression expansion:** the closeout test executes the production scheduled-report predicate with daily evidence beyond three hours and adversarial exact-provenance mutations.
- [x] **Plan 164-11 owns the missing lifecycle primitive:** extension/ignore contracts prove only the named finalizer is versioned; closeout/scheduled tests prove attempt-1 automatic exact push-CI selection, both lifecycle modes, ignored identities, raw CI/scheduled verification, and no tracked post-capture artifact.
- [x] **Plan 164-12 owns the non-circular external checkpoint capability:** the ignored pre-verification report proves protected implementation behavior before the verifier writes completion metadata and is never represented as terminal evidence. Fresh evidence must be recaptured after remediation reaches protected main.
- [x] **Plan 164-13 owns the named adversarial regression locks:** both `phase_164_gap_closure` groups run against production seams and cover exact ledger semantics, canonical identity/output boundaries, symlink safety, and post-write dirt precedence.
- [x] **Plan 164-14 owns the refreshed protected-main checkpoint:** the complete focused suite and production validator pass before exact-SHA attempt-one CI and natural scheduled evidence are captured and independently checked.
- [x] **Plan 164-15 owns terminal integrity gap closure:** closeout and scheduled-control tests cover verified-SHA first-parent history, Plans 01–13 prerequisites, token-owned hostile fixture cleanup, and malformed/future/current/in-range/stale timestamps at both evidence seams.
- [x] **Plan 164-16 owns whole-document maintainer authority reconciliation:** the maintaining contract scans the complete non-historical region, rejects representative automatic/reviewer-free/approval-free variants wherever injected, requires exactly one historical boundary, and preserves explicitly historical v0.1/v0.5 provenance.
- [x] **Plan 164-17 owns immutable trust-anchor coverage:** the repository-truth group exercises exact Git-index membership and fail-closed CLI behavior through production `RepositoryTruthLedger` seams; the closeout group invokes the real registered extension handler and proves full shim-to-downstream HEAD authentication, immutable private execution, and cleanup under adversarial Git states.
- [x] **Plan 164-18 owns stage-aware tracked proof:** the `phase_164_stage0_index` group selected four tests and passed all four, proving exact NUL-delimited stage-0 identity and rejecting a genuine unmerged stage-1/2/3 subject through both helper and full validation paths.
- [x] **Plan 164-19 owns complete finalization authority:** the `phase_164_dispatcher_boundary` and `phase_164_transitive_chain` groups each selected four tests and passed all four, proving Phase-164-only lexical dispatch, cleanup-before-error, full pre-Bash HEAD materialization, and immunity to hidden checkout mutations.
- [x] **Plan 164-20 owns record reconciliation:** the complete focused suite, canonical validator, shell syntax, and diff checks bind these records to the executed Plan 164-18/19 behavior without running either finalization mode.
- [x] **Plan 164-21 owns immutable commit and exact-history authority:** seven selected loader tests bind reads to one captured OID and reject moving HEAD, missing pairs 10/20/24, malformed, singleton, and unexpected numbered artifacts.
- [x] **Plan 164-22 owns installed-command authority migration:** the project-local extension is retired with exact ledger provenance, and current guidance exposes only the external command.
- [x] **Plan 164-23 owns explicit installation approval:** the mode-0400 approval record, mode-0500 installed executable, approved source digest, and conditional rollback evidence are immutable inputs to later tests.
- [x] **Plan 164-24 owns production installed-boundary proof:** five selected subprocess tests invoke the absolute installed command and cover accepted private dispatch, moving HEAD, pairs 10/20/24, hostile extension self-mutation, and approval parity.

`wave_0_complete` is `true`: the test assets exist and their plan-specific commands have run successfully. This records completed executor evidence, not a plan-time predeclaration.

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

- [x] All executor tasks across all thirty-nine plans have an automated verification row, plus one explicit terminal post-execution lifecycle gate.
- [x] The tracer-created repository-truth test, Plan 164-04 expansion, Plan 164-05 test/wrapper and usage contract, Plan 164-06 checkpoint, and Plan 164-07 exact-main report are explicitly mapped.
- [x] TRTH-01 and TRTH-02 retain completed task-level coverage; TRTH-03 maps through the freshness repair, tracked lifecycle contract, and terminal post-execution raw-source gate.
- [x] Sampling continuity has no three consecutive tasks without automated feedback.
- [x] No watch-mode flags or error-suppressing validation fallbacks are used.
- [x] Planned focused feedback remains under the 15-minute maximum.
- [x] `nyquist_compliant: true` reflects this complete plan-time validation contract.

### Implementation completion

- [x] Wave 0 test files have been created.
- [x] Wave 0 focused commands have run green; `wave_0_complete: true` is set.
- [x] Waves 1-3 focused and wave gates have run green.
- [x] Plan 164-06 protected-main checkpoint supplied exact identities.
- [x] Plan 164-07 exact-main report gate passed on fresh live evidence.
- [x] Plan 164-10 registry-specific freshness repair and adversarial provenance contract have run green.
- [x] Plan 164-11 extension, narrow `.gsd` ignore boundary, finalizer, lifecycle guidance, ledger rows, and focused tests have run green.
- [x] Plan 164-12 pre-verification protected capture passed and its raw evidence was independently checked; Plan 164-14 subsequently refreshed this evidence after the Plan 164-13 regression repair.
- [x] Plan 164-13 tagged adversarial ledger and closeout groups run non-vacuously and green against production behavior.
- [x] Plan 164-14 complete focused suite, production ledger validator, and protected pre-verification capture passed with independently checked raw sources.
- [x] Plan 164-15 verified-SHA history, complete-prerequisite, owned-cleanup, and two-sided freshness regressions pass at the production seams.
- [x] Plan 164-16 whole-non-historical maintainer authority contract passes all four active tests and retains one exact historical boundary.
- [x] Plan 164-17 trust-anchor contracts pass directly against the production validator and real extension handler, including untracked regular files, literal path identity, CLI misuse, staged-new/divergent executables, immutable downstream HEAD bytes, and private-materialization cleanup.
- [x] Plan 164-18 stage-aware contracts pass four selected production-seam tests and reject genuine unmerged stage-1/2/3 index state without weakening literal stage-0 identity.
- [x] Plan 164-19 dispatcher and transitive-chain contracts pass eight selected real-handler tests, authenticate the lexical Phase 164 selector plus the closed HEAD dependency manifest before Bash, and clean the private authority root before every outcome.
- [x] Plan 164-20 documentation reconciliation maps the repaired seams and preserves terminal finalization as a separately governed post-execution action.
- [x] Plans 164-21 through 164-24 close the immutable-OID, exact-history, pre-evaluation authority, installation provenance, and installed-boundary regression gaps without running canonical pre-verification or terminal finalization.
- [x] Plans 164-25 through 164-28 repaired CI hermeticity, repository/tool authority, installation ancestry, and their first durable reconciliation without terminal execution.
- [x] Plans 164-29 through 164-33 replaced fixture proof with the real installed tuple, made every repository/protected suite host-independent, bounded incomplete-authority diagnostics, advanced exact history to 01-34, and approved/installed the current loader while preserving rollback provenance.
- [x] Plans 164-35 through 164-38 established physical-runtime/OID closure, protected integration, exact approval, recoverable installation, and disjoint repository/host proof.
- [x] Plan 164-39 summary finished before the final ordinary Phase 164 reconciliation.
- [x] Plans 164-40 through 164-43 hardened the final repository, loader, and maintainer-authority gaps, and Plan 164-44 reran the canonical ledger plus all ordinary verification lanes green.
- [ ] All tracked Phase 164 summaries and phase.complete metadata have reached protected main before terminal `/finalize-phase 164` runs.
- [ ] The final ignored report and raw CI/scheduled sources pass independent verification with no later tracked commit.

## Validation Audit 2026-09-01

The implemented test suite is green (67 tests, 0 failures, 1 skipped; Node CI-monitor tests 5/5; shell syntax passed), but it does not exercise seven adversarial boundaries identified by the Phase 164 code review.

| Metric | Count |
|--------|-------|
| Review findings audited | 7 |
| Covered | 0 |
| Partial | 4 |
| Missing | 3 |
| Implementation blockers escalated | 6 |

| Finding | Coverage | Required automated proof |
|---------|----------|--------------------------|
| CR-01 symlink overwrite | MISSING | Reject symlinked predictable component/output paths without modifying an external sentinel. |
| CR-02 incomplete scheduled sweep | PARTIAL | Reject missing/duplicate controls and altered workflow, run, reason, payload, and archive bindings. |
| CR-03 fork certification | MISSING | Reject non-authoritative origin/GitHub repository identity before evidence collection. |
| CR-04 protected-main race | PARTIAL | Advance origin/main during collection and require a final re-fetch/non-pass verdict. |
| CR-05 fabricated ledger semantics | PARTIAL | Mutate every semantic authority column and enforce closed relationships and formats. |
| CR-06 dev-only production operator docs | MISSING | Require production-capable dependency guidance for the documented operator mount. |
| WR-01 stale v1/1.0 contracts | PARTIAL | Derive current contract majors while preserving explicitly historical sections. |

These gaps were not auto-filled because adding tracked tests after the protected pre-verification capture would violate Plan 164-12's metadata-only handoff boundary. They must be resolved as implementation/test gap work followed by fresh protected evidence.

**Historical result of this audit:** validated but not Nyquist-compliant — adversarial coverage gaps and implementation blockers were open at that point and were resolved by the post-remediation audit below.

## Validation Audit 2026-09-01 — Post-Remediation

The code-review gaps and the additional task-map/documentation-contract gap are now covered by executable tests. The protected-main lifecycle captures remain external-state gates and were not misclassified as missing unit coverage.

| Metric | Count |
|--------|-------|
| Review findings re-audited | 7 |
| Review gaps covered | 7 |
| Additional Nyquist gaps covered | 1 |
| Blocking implementation gaps | 0 |
| External lifecycle gates still requiring fresh evidence | 2 |

- Complete focused Phase 164 suite after the aggregate-precedence addition: 82 tests, 0 failures, 1 skipped.
- Production closeout file, including aggregate precedence: 19 tests, 0 failures.
- Node CI-monitor contract: 5/5 passed.
- Canonical repository ledger: valid.
- Shell syntax, formatting, and `git diff --check`: passed.
- Real GSD invocation loaded the command and failed closed because the remediation branch is not canonical protected `main`.

**Approval:** Nyquist-compliant for automated coverage. Fresh pre-verification and terminal protected-main evidence remain mandatory external gates before Phase 164 can complete.

## Validation Audit 2026-09-09 — Plan 164-14 Refresh

Plan 164-14 introduced no production implementation. The existing validation strategy was re-audited against the Plan 164-13 adversarial regression locks and the Plan 164-14 exact-main evidence summary; no automated coverage gaps remain for TRTH-01, TRTH-02, or TRTH-03.

| Metric | Count |
|--------|-------|
| Requirements audited | 3 |
| Automated gaps found | 0 |
| Tagged adversarial groups | 2 |
| Tagged adversarial tests passed | 8 |
| Complete focused tests | 81 |
| Failures | 0 |
| Pre-existing skips | 1 |

- Complete focused Phase 164 suite: 81 tests, 0 failures, 1 pre-existing skip.
- Tagged production-ledger regression group: 4 tests, 0 failures.
- Tagged production-closeout regression group: 4 tests, 0 failures.
- Production authoritative-ledger CLI: `repository truth ledger: valid`.
- Closeout/finalizer shell syntax, modified Elixir formatting, and `git diff --check`: passed.
- Plan 164-14 independently recorded a passing pre-verification capture for exact protected-main SHA `d903b040c72fff62a69a57cacbcc7e7d7c2f6167` and CI run `34284583200`.

**Approval:** Current and Nyquist-compliant for automated coverage through Plan 164-14. The separate terminal `/finalize-phase 164` external-state gate remains pending and is not an automated test gap.

## Validation Audit 2026-09-09 — Plan 164-16 Closeout

Plan 164-16 closes the remaining TRTH-01 documentation gap with a behavioral contract over the complete non-historical maintainer document. Every Phase 164 executor task now has meaningful automated verification; no new automated coverage gap was found.

| Metric | Count |
|--------|-------|
| Plans audited | 16 |
| Executor tasks mapped | 24 |
| Requirements audited | 3 |
| Automated gaps found | 0 |
| Complete focused tests | 98 |
| Failures | 0 |
| Pre-existing skips | 1 |

- Complete focused Phase 164 suite: 98 tests, 0 failures, 1 pre-existing historical skip (97 executed).
- Plan 164-16 maintaining contract: 4 active tests covering the full pre-historical region, injected authority variants, retained historical provenance, and missing/duplicate boundary failure.
- Production authoritative-ledger CLI: `repository truth ledger: valid`.
- Modified ExUnit formatting, closeout/finalizer/scheduled shell syntax, executable-control diff, and `git diff --check`: passed.
- The Plan 164-14 protected-main capture predates Plan 164-16 and remains non-terminal by design. Refreshed ordinary verification must record the Plan 164-16 implementation SHA; terminal `/finalize-phase 164` remains an external-state gate after all completion metadata reaches protected main.

**Approval:** Current and Nyquist-compliant for automated coverage through Plan 164-16. Refreshed exact-SHA verification and the separate terminal protected-main capture remain mandatory lifecycle gates, not missing automated tests.

## Validation Audit 2026-09-09 — Plan 164-17 Trust Anchors

Plan 164-17 closes the two verifier-identified trust-anchor gaps with direct behavioral tests through the production seams. No additional automated test gap remains, and the separately governed terminal finalizer was not run.

| Metric | Count |
|--------|-------|
| Plans audited | 17 |
| Executor tasks mapped | 26 |
| Requirements audited | 3 |
| New trust-anchor gaps audited | 2 |
| New trust-anchor gaps resolved | 2 |
| Escalated | 0 |
| Complete focused tests | 102 |
| Failures | 0 |
| Pre-existing skips | 1 |

- TRTH-02 production-seam group: 3 tests, 0 failures; disposable Git validation rejects a regular file removed from the index, preserves literal metacharacter/prefix identity, and makes invalid standalone CLI calls bounded nonzero failures while module loading remains side-effect-free.
- TRTH-03 production-seam group: 1 test, 0 failures; the real registered extension handler rejects staged-new and staged/unstaged divergent executable links, dispatches the authenticated downstream HEAD bytes from a private path, and proves cleanup on success and failure.
- Complete focused Phase 164 suite: 102 tests, 0 failures, 1 pre-existing historical skip (101 executed).
- Production authoritative-ledger CLI: `repository truth ledger: valid`.
- Terminal `/finalize-phase 164` remains pending after refreshed ordinary verification and protected completion-metadata integration; it is an external lifecycle gate, not an automated coverage gap.

**Approval:** Current and Nyquist-compliant for automated coverage through Plan 164-17. Refreshed exact-SHA verification and the separate terminal protected-main capture remain mandatory lifecycle gates.

## Validation Audit 2026-09-10 — Plans 164-18 through 164-20 Reconciliation

Plans 164-18 and 164-19 closed the stage-0 index, lexical shim, unsupported
phase, transitive authenticated-chain, and print-cleanup gaps through named
production seams. Plan 164-20 reconciled this record and the lifecycle contract
without invoking either finalization mode.

| Metric | Count |
|--------|-------|
| Plans audited | 20 |
| Executor tasks mapped | 30 |
| New named regression groups | 3 |
| Named regression tests selected | 12 |
| Complete focused tests | 114 |
| Failures | 0 |
| Pre-existing skips | 1 |

- `phase_164_stage0_index`: 4 selected, 20 excluded, 0 failures; genuine
  stage-1/2/3 conflict state is rejected through helper and full-ledger paths.
- `phase_164_dispatcher_boundary`: 4 selected, 33 excluded, 0 failures;
  lexical Phase 164 selection, unsupported-phase rejection, and cleanup before
  print-mode failure are exercised through the real handler.
- `phase_164_transitive_chain`: 4 selected, 33 excluded, 0 failures; the closed
  HEAD dependency manifest is materialized before Bash and hidden checkout
  helper/data mutations cannot influence execution.
- Complete focused Phase 164 suite: 114 tests, 0 failures, 1 pre-existing
  historical skip (113 executed).
- Production authoritative-ledger CLI: `repository truth ledger: valid`.
- Finalizer/closeout shell syntax and `git diff --check`: passed.
- Neither Plans 164-18, 164-19, nor 164-20 ran pre-verification or terminal
  `/finalize-phase 164`.

**Approval:** Current and Nyquist-compliant for automated coverage through Plan
164-20. Ordinary verification and protected completion-metadata integration
remain prerequisites for the separate terminal `/finalize-phase 164` capture.

## Validation Audit 2026-09-10 — Plans 164-21 through 164-24 Installed Boundary

Plans 164-21 through 164-24 close the three remaining verifier attacks at the
installed production boundary. The immutable installation authority is Plan
164-23 approval OID `7f57e1cd0aafe6d236624da98f7292e86e6de697` with loader SHA-256
`ca760f78ab0901dbc537e20ec6c231314afffa7932dd8f1850f4935cabc8b7d9`.
Plan 164-24 separately captured the current execution-authority OID and proved
its loader blob remained byte-identical; it did not require current HEAD to
equal the older installation OID.

| Metric | Count |
|--------|-------|
| Plans audited | 24 |
| Remaining verifier attacks closed | 3 |
| Installed production-boundary tests | 5 selected, 46 excluded, 0 failures |
| Complete focused tests | 120 |
| Failures | 0 |
| Pre-existing historical skips | 1 |

- `phase_164_installed_production_boundary` invoked
  `/Users/jon/.local/bin/mailglass-finalize-phase` directly; no tracked source
  path or test-local import stood in for the installed process.
- The accepted fixture executed only captured-commit bytes beneath a private
  authority root and removed that root after dispatch.
- A moving HEAD exited nonzero with a bounded reason before Bash.
- Deletion of exact PLAN/SUMMARY pairs 10, 20, and 24 each exited nonzero before
  Bash, closing both middle-pair and terminal-pair shrinkage.
- An assume-unchanged hostile retired extension carried a real marker-writing
  payload, but direct installed execution never evaluated it and the marker
  remained absent.
- Before every matrix, the mode-0400 approval record, exact Plan 164-23 summary
  tuple/digest, absent-destination rollback result, installed mode/digest, and
  immutable installation-OID self-check passed.
- `T-164-87` is closed by absolute-path and checkpoint-digest identity;
  `T-164-88` by the unevaluated executable marker; `T-164-89` by this observed
  result map; and `T-164-90` by the complete manifest-derived docs contract.
- No task in Plans 164-21 through 164-24 ran canonical pre-verification or
  terminal finalization.

**Approval:** Current and Nyquist-compliant for automated coverage through Plan
164-24. Ordinary verification and protected completion-metadata integration
still precede the final installed command run; terminal finalization remains
pending and no terminal evidence is claimed here.

## Validation Audit 2026-09-11 — Plans 164-29 through 164-34 Gap Closure

The gap-closure plans retain automated coverage for every declared executor
task. The active controlled-host installation, repository-only suite boundary,
bounded authority-root diagnostics, exact 01-34 history, immutable approval and
replacement, and durable evidence reconciliation all ran green at their named
production seams. No missing or partial automated coverage was found.

| Metric | Count |
|--------|-------|
| Gap-closure plans audited | 6 |
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

- Plan 164-29/33 controlled-host proof: 7 selected, 54 excluded, 0 failures.
- Repository-only required lane after Plan 164-34: 398 selected, 7 excluded,
  0 failures.
- Plan 164-30 incomplete-authority group: 3 selected, 25 excluded, 0 failures.
- Plan 164-34 repository-truth suite: 30 tests, 0 failures; canonical validator
  valid.
- Terminal exact-main capture remains an explicit external lifecycle gate, not
  an automated coverage gap.

**Approval:** Current and Nyquist-compliant for automated coverage through Plan
164-34. Ordinary verification, protected completion-metadata integration, and
the separate terminal `/finalize-phase 164` capture remain pending in order.

## Validation Audit 2026-09-11 — Verify-Work Refresh

The current full-suite gate initially found one formatting-only validation gap
in `test/mailglass/publish/maintaining_release_gate_contract_test.exs`. The file
was formatted and the declared `mix ci.fast` gate then completed successfully.
No missing or partial behavioral coverage was found.

| Metric | Count |
|--------|-------|
| Gaps found | 1 |
| Resolved | 1 |
| Escalated | 0 |

**Approval:** Nyquist-compliant. The protected-main terminal capture remains an
external lifecycle gate and is not an automated test gap.

## Gap Reconciliation — Plans 164-35 through 164-39

This final tracked reconciliation supersedes the Plan 164-34 implementation and
installed-readiness snapshot without rewriting its historical evidence. The
current authority chain is the Plan 164-35 executable repair, Plan 164-36
protected integration, Plan 164-37 exact approval, and Plan 164-38 recoverable
installation. Plan 164-39 records those observed facts only; repository tests
and controlled-host installation readiness remain non-terminal evidence. Each
row below records a stable failure direction as well as its observed success.

| Finding | Current production seam | Named non-vacuous evidence | Observed result | Stable failure direction |
|---------|-------------------------|----------------------------|-----------------|--------------------------|
| GR-35-RUNTIME | The loader authenticates a physical Mix/Elixir/Erlang exact-child probe, removes inherited ASDF selectors, and constructs the sanitized child PATH only from authenticated tool directories. | `phase_164_runtime_closure` within `mix verify.phase_164.authority_closure` | 4 selected, 60 excluded, 0 failures, exit 0; normalized Mix `1.19.5`, Elixir `1.19.5`, OTP `28`, probe SHA-256 `ca3c43bd04c4e21e223f39561f294885ceca2633db65a72fa29b780bcef3975d`. | A shim, symlink, unsafe mode/owner, selector leak, incompatible version, or changed exact-child output returns bounded nonzero output before Bash dispatch. |
| GR-35-OID | The Node-captured full commit OID is required through finalizer and closeout, and every later repository observation compares against it. | `phase_164_oid_handoff` within `mix verify.phase_164.authority_closure`; deterministic OID-handoff movement regression | 4 selected, 60 excluded, 0 failures, exit 0 for the combined authority lane. | Missing, malformed, nonexistent, substituted, or post-authentication moving HEAD identity fails nonzero before evidence markers; checkout bytes never replace the authenticated OID. |
| GR-36-PROTECTED | Normal protected integration and exact push-CI selection bind the repair to protected source OID `52c07a5051d269b307831a2210f53dec0dd1ff65`. | Protected PR #249 and independently checked CI run `34650810638` | Workflow `CI`, event `push`, attempt `1`, branch `main`, exact head SHA, completed, success. | Direct push, bypass, dispatch, rerun, alternate SHA/run, or incomplete identity fields do not establish authority. |
| GR-37-APPROVAL | The exact Plan 164-37 approval is proposal bytes plus one approved-status line, mode 0400, and binds the protected source, CI, runtime, predecessor, destination, and rollback tuple. | `mix verify.phase_164.proposal_boundary`; approval SHA-256 `e3687bf5a2afc69a79b2677c69daa3d533549d4b6f730a30a04e32cc6d13b7cd` | 4 selected, 60 excluded, 0 failures; all 28 ordered fields revalidated before publication. | Any missing, empty, duplicated, reordered, or changed field invalidates approval and grants no installation, finalization, workflow, or release authority. |
| GR-38-INSTALLED | The active mode-0500 object is the approved Git blob, while the exact predecessor is a separate verified mode-0400 rollback. | `phase_164_installed_production_boundary`; `mix verify.phase_164.installed_boundary` | 7 selected, 57 excluded, 0 failures, exit 0; installed SHA-256 `394a47effebe04d7aaa4e098775bedd194b6f00ce6efa63eea078aa79bb9f746`; rollback SHA-256 `f01859c551e6611d3bdd4dbae427cba3bc3d63e18fad7d74bbeeacf9953fffac`. | Approval, source, digest, mode, ancestry, physical-runtime, probe, rollback, or exact 01-39 history drift fails nonzero; rollback is not a second active authority. |
| GR-39-REPOSITORY | Repository-only CI stays disjoint from proposal and controlled-host groups while retaining the disposable runtime/OID attacks. | `mix verify.ci_lane_contract` | 397 selected, 11 excluded; the initial RED-tree run exposed only the expected test-exception line shift, which was removed by keeping the registered historical skip at its canonical line. The clean GREEN rerun is required before Task 1 commit. | Any zero selection, host-group collection, removed disposable attack, SuiteFloor drift, or repository failure returns nonzero and cannot be relabeled as installed or terminal proof. |

The current tracked source recognizes the exact PLAN/SUMMARY pair set 01 through 44.
The installed authority remains bounded to 01 through 39 until a new
exact-tuple approval and recoverable replacement completes. Current maintainer and package guidance
remains unchanged: one protected release path is current, historical procedures
stay explicitly bounded, package compatibility derives from live manifests,
and protected recovery/finalization retains one fail-closed route.

### Mandatory post-Plan-164-44 handoff

`164-44-SUMMARY.md` must exist and be committed before ordinary verification.
The only valid later sequence is: ordinary verifier records `status: passed`
and its exact `verified_implementation_sha`; only the four authorized completion
metadata paths change; those descendants integrate normally through protected
`main`; the exact terminal main SHA receives successful attempt-one normal CI
and complete naturally scheduled attempt-one evidence; the Plan 164-37 approval
and the superseding installed/provenance tuple is rechecked; the installed
command performs terminal capture; then no tracked write occurs.

T-164-109 remains high and pending. Terminal protected-main evidence remains
absent and pending throughout this plan. No implementation test, repository-only
CI result, proposal/approval check, installed readiness result, Plan 164-39
execution, or its summary is terminal proof.

## Final Ordinary Verification — Plans 164-40 through 164-44

This final ordinary reconciliation supersedes current-count claims from the
397/11 and 398/7 snapshots while preserving them above as layered historical
evidence. The commands below ran after the canonical Plan 164-44 ledger repair
at implementation commit `91b867ab2299afb8b2392176f699e16af4fc8f4a` and all
exited zero before SECURITY or VALIDATION was edited.

| Authority layer | Exact command | Fresh observed result | Failure direction |
|-----------------|---------------|-----------------------|-------------------|
| Canonical ledger | `elixir scripts/validate_repository_truth.exs --repo /Users/jon/projects/mailglass --ledger /Users/jon/projects/mailglass/.planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv` | `repository truth ledger: valid`; exit 0 | Missing, duplicate, incomplete, or stale canonical evidence exits nonzero. |
| Repository truth | `mix test test/scripts/phase_164_repository_truth_test.exs --warnings-as-errors --no-deps-check` | 47 selected, 0 excluded, 0 failures; exit 0 | Regular-file, stage-0, plan-metadata, exact-one, adjacent-backup, ordering, or stale-hash mutations fail. |
| Repository-only CI | `mix verify.ci_lane_contract` | 414 selected, 11 excluded, 0 failures; exit 0 | Host collection, disposable-attack loss, floor drift, or any repository failure exits nonzero. |
| Controlled-host installed readiness | `mix verify.phase_164.installed_boundary` | 7 selected, 57 excluded, 0 failures; exit 0 | Approval, source, installation, runtime, rollback, exact-history, or repository-authority drift exits nonzero. |
| Maintainer authority | `mix test test/mailglass/publish/maintaining_release_gate_contract_test.exs --warnings-as-errors --no-deps-check` | 5 selected, 0 excluded, 0 failures; exit 0 | Missing current Plan 164-37/38 authority or unbounded Plan 164-23 history fails. |
| Evidence-document contract | `mix test test/mailglass/docs_contract_test.exs --only phase_164_gap_reconciliation --warnings-as-errors --no-deps-check` | 5 selected, 44 excluded, 0 failures; exit 0 after evidence edits | Missing current records, mitigations, or pending-terminal language fails. |

This is D-01 layered history and D-09 dual proof: repository-only behavior and
controlled-host installed readiness are separately green, not collapsed into
one authority. It is ordinary verification evidence, not terminal proof.
T-164-109 remains open. D-10 clean exact main, D-11 protected checks and
naturally scheduled evidence, installed terminal capture, and a no-later-write
observation remain absent and pending. Plan 164-44 makes no terminal lifecycle
claim and does not invoke `/Users/jon/.local/bin/mailglass-finalize-phase 164`.
