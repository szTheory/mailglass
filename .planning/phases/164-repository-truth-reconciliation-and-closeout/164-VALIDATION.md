---
phase: 164
slug: repository-truth-reconciliation-and-closeout
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-26
revised: 2026-09-10
---

# Phase 164 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. The contract covers every executor task in Plans 164-01 through 164-24 plus the terminal non-plan finalization gate required after all tracked GSD metadata reaches protected main.

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
| 164-FINAL | post-execution gate | after phase.complete integration | TRTH-03 | T-164-40, T-164-41, T-164-42, T-164-43, T-164-44 | Final protected metadata SHA has attempt-1 normal push CI, attempt-1 natural schedules, ignored identity/report state, independently verified raw sources, and no later tracked commit | live lifecycle gate | `/Users/jon/.local/bin/mailglass-finalize-phase 164` | ignored `finalization-inputs.json`, report, CI source, scheduled source | ⚠️ external terminal capture pending |

*Status: ✅ automated capability green · ⚠️ external evidence still required*

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

- [x] All executor tasks across all twenty-four plans have an automated verification row, plus one explicit terminal post-execution lifecycle gate.
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
