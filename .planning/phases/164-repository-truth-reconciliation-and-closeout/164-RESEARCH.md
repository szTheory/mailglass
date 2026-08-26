# Phase 164: Repository Truth Reconciliation and Closeout - Research

**Researched:** 2026-08-26
**Domain:** Repository-operational truth, durable evidence, and maintainer closeout
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

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

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within the fixed Phase 164 truth-reconciliation and closeout scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| TRTH-01 | Maintainer, version, release, recovery, and package guidance agrees with settled workflow, published state, and supported commands. | Layered authority, manifest/Hex checks, explicit current-vs-historical doc boundary, and the existing executable guidance contract. |
| TRTH-02 | Every changed tracked/generated artifact and ignore rule has an evidence-backed classification; only demonstrable junk is removed and proof remains discoverable. | One audited-row ledger with exact disposition enum, producer/consumer evidence, and ignore-rule scope review. |
| TRTH-03 | A maintainer can reproduce final closeout evidence for clean canonical workspace, green protected main CI, explained control outcomes, and every disposition. | A non-committed, rerunnable report composed from the existing hygiene, preservation, scheduled-control, and exact-CI seams. |
</phase_requirements>

## Summary

This is a reconciliation phase, not a release-system redesign. Use the current executable controls and live identities as the authority layer, project their facts into one clearly labelled current maintainer path, and retain prior phase records as historical proof. [VERIFIED: repository inspection]

The repository already has the necessary primitives: `mix mailglass.repo.hygiene --check --format json` emits bounded three-state hygiene evidence; `scripts/verify_workspace_evidence.sh` validates Phase 161 preservation records; `scripts/scheduled_control_evidence.sh sweep` binds every registered scheduled control to exact `main` and its retained artifact; and `scripts/ci_monitor.cjs`/`gh` inspect an exact CI run. [VERIFIED: repository inspection]

**Primary recommendation:** Add a tracked, schema-tested Phase 164 truth/disposition ledger and a small rerunnable closeout command/report that composes those existing checks; update `MAINTAINING.md` and doc contracts in the same change; remove only the locked stale root sweep after recording its exact identity. [VERIFIED: repository inspection]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Current maintainer release/recovery instructions | Repository documentation | GitHub Actions | Docs explain, but protected workflow code is the authority. [VERIFIED: repository inspection] |
| Package/version truth | Package manifests / Hex | Documentation | Manifests and live Hex records establish facts; README constraints project supported adoption. [VERIFIED: repository inspection] |
| Artifact and ignore-rule dispositions | Tracked planning artifact | Git index / working tree | A committed ledger makes classifications reviewable while Git establishes tracked/ignored state. [VERIFIED: repository inspection] |
| Volatile quiet-repository verdict | Local command/report | GitHub Actions / Hex | It must query exact current identities at runtime, so committing it as a snapshot would stale it. [VERIFIED: repository inspection] |
| Scheduled/recovery provenance | GitHub Actions artifacts | Local verifier | The registered workflows produce the evidence; the existing script validates event, run, SHA, age, and artifact agreement. [VERIFIED: repository inspection] |

## Project Constraints (from AGENTS.md)

`AGENTS.md` is absent. The project-level constraints discovered in `CLAUDE.md` still apply: preserve append-only planning/release evidence; do not conceal proof with broad ignores; retain exact-SHA evidence; do not change release authority, CI topology, product/API/schema, dependencies, or broad timeouts in this maintenance phase. [VERIFIED: repository inspection]

## Standard Stack

### Core

| Tool / asset | Version | Purpose | Why Standard |
|---|---:|---|---|
| Git porcelain + refs | Git 2.41.0 locally | Exact canonical branch, `HEAD`, upstream, tracked/untracked state | Existing hygiene code already bases release cleanliness on Git state. [VERIFIED: local environment and repository inspection] |
| `mix mailglass.repo.hygiene` | Repository task | Bounded local/remote hygiene JSON | It already defines `pass`, `blocked`, and `cannot-check` behavior and is used by scheduled hygiene. [VERIFIED: repository inspection] |
| `scripts/verify_workspace_evidence.sh` | Repository script | Preserve/recheck Phase 161 inventory and reconciliation evidence | Its static/live modes validate stable IDs, exact dispositions, recovery refs, and canonical conditions. [VERIFIED: repository inspection] |
| `scripts/scheduled_control_evidence.sh` | Repository script | Validate/sweep scheduled control provenance | It requires scheduled event, completed run, `main`, exact workflow/head SHA, retained artifact, and freshness. [VERIFIED: repository inspection] |
| GitHub CLI `gh` | 2.95.0 locally | Read current GitHub `main`, CI, artifacts, and workflow metadata | Existing hygiene and scheduled-control scripts already use it; no new service is needed. [VERIFIED: local environment and repository inspection] |

### Supporting

| Tool / asset | Purpose | When to Use |
|---|---|---|
| `scripts/ci_monitor.cjs` | Exact run/PR/workflow observation | Use for identity-bound final CI evidence, never “latest main” inference. [VERIFIED: repository inspection] |
| `.planning/release-target.json` | Candidate lifecycle and version state | Treat as policy/candidate evidence, not a replacement for live Hex or current manifests. [VERIFIED: repository inspection] |
| `test/mailglass/docs_contract_test.exs` and `test/mailglass/publish/maintaining_release_gate_contract_test.exs` | Prevent stale maintainer statements | Extend tests when current instructions replace stale current-facing text. [VERIFIED: repository inspection] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|---|---|---|
| Composed local closeout command | A committed “final snapshot” JSON | Rejected: a commit changes `HEAD`, so its own exact-state claim goes stale. [VERIFIED: Phase 164 CONTEXT.md D-09] |
| One disposition ledger | Ad hoc prose in multiple docs | Rejected: it cannot mechanically prove completeness/uniqueness or one outcome per item. [VERIFIED: Phase 164 CONTEXT.md D-05, D-12] |
| Existing control scripts | New maintenance service/workflow | Rejected by phase scope and duplicates established audited seams. [VERIFIED: Phase 164 CONTEXT.md; repository inspection] |

**Installation:** No external packages are required or authorized for this phase. [VERIFIED: Phase 164 CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
                     tracked source facts                 live / immutable facts
     manifests, docs, workflows, ignore files          Git refs, GitHub runs, Hex API
                       |                                      |
                       +----------> audit collector <----------+
                                           |
                       +-------------------+-------------------+
                       |                                       |
             tracked truth/disposition ledger        rerunnable volatile report
        (all rows, authority, evidence, outcome)    (canonical main / CI / controls)
                       |                                       |
                       +-------------------+-------------------+
                                           |
                              closeout verdict: pass / fail
                                           |
                  maintainer reads current MAINTAINING.md path
```

The ledger must reference rather than duplicate mutable live results; the rerunnable report must emit the exact queried IDs/SHA/timestamp and must be ignored or otherwise left untracked as machine-local output. [VERIFIED: Phase 164 CONTEXT.md D-09; repository inspection]

### Recommended Project Structure

```text
.planning/phases/164-repository-truth-reconciliation-and-closeout/
├── 164-TRUTH-DISPOSITION.(md|tsv|json)  # tracked canonical audit ledger
├── 164-CLOSEOUT.md                       # stable usage / evidence contract, if needed
└── 164-RESEARCH.md                        # planning input
scripts/
└── <existing verification seam or focused closeout wrapper> # emits untracked report
test/scripts/
└── phase_164_*_test.exs                  # schema, completeness, and negative-path contracts
```

Use the repository’s existing naming and test placement conventions; choose one ledger format that the test can parse deterministically. [VERIFIED: repository inspection]

### Pattern 1: Layered-authority projection

**What:** Read live/executable facts first, then rewrite current human guidance to point at those commands/identities; label old instructions as historical or upgrade-specific rather than deleting evidence. [VERIFIED: Phase 164 CONTEXT.md D-01 through D-04]

**When to use:** Every time `MAINTAINING.md`, an adopter README, a manifest, `release-target.json`, historical release forms, and Hex differ or use different eras of version language. [VERIFIED: repository inspection]

**Example:**

```markdown
## Current protected release and recovery path

1. Start from a clean canonical `main` and run `mix mailglass.repo.hygiene --check`.
2. Use the protected exact-candidate workflow path described by
   `.github/workflows/release-please.yml`; ordinary push, schedule, and blank
   dispatch runs are proposal-only.
3. Inspect the exact resulting run and package/publication facts before calling
   the release complete.

## Historical v1.0 smoke example (archived applicability)

The following constraints document the v1.0 release record only; they are not
the current installation recommendation.
```

The first section must be implemented only with commands/identities verified against the final committed workflow and package truth. [VERIFIED: repository inspection]

### Pattern 2: One-row, one-disposition ledger

**What:** Audit every scoped artifact and ignore pattern in exactly one machine-checkable row. [VERIFIED: Phase 164 CONTEXT.md D-05, D-12]

**Required fields:** `id`, `subject/path-or-pattern`, `kind`, `producer`, `state` (tracked/ignored/untracked), `authority`, `reproducibility`, `currentness`, `durable_consumer`, `evidence`, `disposition`, and `rationale`. The validator must reject duplicate subjects, missing evidence, and any disposition outside `retain|update|archive|remove|ignore`. [VERIFIED: Phase 164 CONTEXT.md D-05, D-12]

**Classification rule:** A tracked durable proof artifact remains `retain` (or `update` where current content must change); reproducible local diagnostic output is `ignore` only when its narrow pattern names a shared producer; stale root `scheduled-control-sweep.json` is `remove` with its D-08 digest and reason. [VERIFIED: Phase 164 CONTEXT.md D-06 through D-08]

### Pattern 3: Two-phase closeout proof

**What:** Commit durable classification/documentation facts first. Then, after the protected merge, run an uncommitted report against canonical `main`; that report is the volatile closeout proof. [VERIFIED: Phase 164 CONTEXT.md D-09 through D-11]

**Why:** Before merge the local branch cannot truthfully claim `HEAD == origin/main`; after committing a snapshot, a self-referential exact-head snapshot would become stale. [VERIFIED: Phase 164 CONTEXT.md D-09, D-10]

### Anti-Patterns to Avoid

- **Treating a successful historical PR run as final `main` proof:** inspect a run whose `headSha` equals the current protected `main` SHA. [VERIFIED: Phase 164 CONTEXT.md D-11]
- **Calling every non-green scheduled control a failure:** `blocked` is acceptable only when an existing policy reason and valid provenance explain it; `pending` and `cannot-check` fail closeout. [VERIFIED: Phase 164 CONTEXT.md D-11; repository inspection]
- **Replacing old version strings globally:** retain old constraints in specifically historical/upgrade-bounded documents such as `docs/upgrade-from-0.x.md`; update current-facing docs. [VERIFIED: repository inspection]
- **Ignoring proof to make `git status` look clean:** broad `.planning/`, release, publish, scheduled-control, or generated-host exclusions are prohibited. [VERIFIED: Phase 164 CONTEXT.md D-07]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Branch/worktree/release hygiene | Another ad hoc Git/GitHub checker | `mix mailglass.repo.hygiene --check --format json` | Existing task handles clean/blocked/cannot-check and has tests for malformed remote responses. [VERIFIED: repository inspection] |
| Preservation proof | New ref/reachability scanner | `scripts/verify_workspace_evidence.sh static|live` | Existing script checks inventory/TSV correspondence and safe removal evidence. [VERIFIED: repository inspection] |
| Scheduled evidence validation | New Actions API artifact parser | `scripts/scheduled_control_evidence.sh sweep` | Existing script validates exact scheduled run provenance, artifact binding, current `main`, and freshness. [VERIFIED: repository inspection] |
| Exact CI observation | “latest green CI” heuristic | `scripts/ci_monitor.cjs inspect <run-id>` or `gh run view` constrained to SHA | Current code has an identity-specific interface and hygiene queries CI by commit. [VERIFIED: repository inspection] |

**Key insight:** Phase 164’s value is the agreement boundary across established authorities, not new monitoring logic. [VERIFIED: Phase 164 CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Mixing candidate state with published state

**What goes wrong:** `.planning/release-target.json` currently records candidate versions `2.5.0/2.5.0/2.2.0` with status `authorized`, while current manifest and live Hex facts show those package versions publicly available. [VERIFIED: repository inspection; VERIFIED: Hex API]

**Why it happens:** The release-target ledger models a protected candidate lifecycle, whereas Hex answers public publication state. [VERIFIED: repository inspection]

**How to avoid:** Name both authority and observation timestamp in the ledger and docs; do not edit historical candidate facts to impersonate a later live package observation. [VERIFIED: Phase 164 CONTEXT.md D-01, D-03]

**Warning signs:** A current doc asserts “published” solely because a manifest or candidate ledger says a version exists. [VERIFIED: repository inspection]

### Pitfall 2: Self-invalidating closeout capture

**What goes wrong:** A committed report claims the repository is clean at a SHA that changes when the report itself is committed. [VERIFIED: Phase 164 CONTEXT.md D-09]

**How to avoid:** Store durable audit rules/rows in Git and write the final volatile report outside the tracked closeout artifacts after the merge. [VERIFIED: Phase 164 CONTEXT.md D-09]

### Pitfall 3: Removing historical documentation that is still contractual evidence

**What goes wrong:** Cleanup removes Phase 38/73 forms or v1 upgrade guidance instead of marking their applicability. [VERIFIED: repository inspection]

**How to avoid:** Preserve history and link it as provenance; current `MAINTAINING.md` must not present it as a parallel runbook. [VERIFIED: Phase 164 CONTEXT.md D-02, D-04]

### Pitfall 4: Equating ignored with disposable

**What goes wrong:** A pattern hides generated evidence, package allowlists, or planning proof to obtain a deceptively clean workspace. [VERIFIED: Phase 164 CONTEXT.md D-06, D-07]

**How to avoid:** Require a named shared producer and a narrow pattern for every committed ignore entry, then give every rule its own ledger row. [VERIFIED: Phase 164 CONTEXT.md D-05, D-07]

### Pitfall 5: Final proof captured before final `main` schedules run

**What goes wrong:** The sweep emits `pending/awaiting_current_main_schedule` when the newest scheduled control targets an earlier SHA; this is not a quiet verdict. [VERIFIED: repository inspection]

**How to avoid:** Closeout should report pending until all three registered controls have fresh, valid evidence for the post-merge `main`; a policy-blocked result is acceptable only with its validated evidence envelope. [VERIFIED: Phase 164 CONTEXT.md D-11; repository inspection]

## Code Examples

### Narrow closeout orchestration (shell shape)

```bash
# Run only after Phase 164 is merged and the canonical checkout is on main.
set -euo pipefail

mix mailglass.repo.hygiene --check --format json > "$REPORT_DIR/repo-hygiene.json"
bash scripts/verify_workspace_evidence.sh static \
  .planning/phases/161-canonical-workspace-and-evidence-preservation/161-WORKSPACE-INVENTORY.md \
  .planning/phases/161-canonical-workspace-and-evidence-preservation/161-PRESERVATION-RECONCILIATION.tsv
GITHUB_REPOSITORY=szTheory/mailglass \
  bash scripts/scheduled_control_evidence.sh sweep --output "$REPORT_DIR/scheduled-control-sweep.json"
git status --porcelain=v1 --untracked-files=all > "$REPORT_DIR/git-status.txt"
```

The implementation must additionally verify branch `main`, `HEAD == origin/main`, exact current-main CI, ledger schema/completeness, and report each source command plus captured identity; it must not turn a failed/pending/cannot-check source into success. [VERIFIED: Phase 164 CONTEXT.md D-10 through D-12; repository inspection]

### Ledger completeness test shape

```elixir
rows = Phase164Ledger.parse!(".planning/phases/164-.../164-TRUTH-DISPOSITION.tsv")
assert Enum.all?(rows, &(&1.disposition in ~w(retain update archive remove ignore)))
assert Enum.uniq_by(rows, & &1.subject) == rows
assert Enum.all?(rows, &(String.trim(&1.evidence) != ""))
assert Enum.any?(rows, &(&1.subject == "scheduled-control-sweep.json" and
                           &1.disposition == "remove" and
                           &1.evidence =~ "331810b4b1724452f0e2707c800230e52fabea01c3773d362b3a1240040ece7e"))
```

Use the actual chosen parser/schema rather than a new runtime dependency. [VERIFIED: Phase 164 CONTEXT.md D-05, D-08, D-12]

## State of the Art

| Old approach | Current approach | When Changed | Impact |
|---|---|---|---|
| Ordinary Release Please schedule/push could be read as release authority | Ordinary push/schedule/blank dispatch is proposal-only; protected exact-digest dispatch crosses the authority boundary | Phase 162 | Current docs must describe protected exact-candidate authorization, not only auto-merge prose. [VERIFIED: repository inspection] |
| Human interpretation of scheduled workflow results | Three registered controls emit retained evidence and are verified by run/SHA/artifact-aware sweep | Phase 162 | A blocked result can be factual; an unbound or stale result cannot close the repository. [VERIFIED: repository inspection] |
| Historical v1 release runbook presented alongside release flow | Package manifests and current READMEs carry the 2.5/2.5/2.2 supported constraints while v1 docs remain historical | Current repository state | The current runbook needs a conspicuous historical boundary. [VERIFIED: repository inspection; VERIFIED: Hex API] |

**Deprecated/outdated:** The `MAINTAINING.md` smoke example using core/admin `~> 1.3` and inbound `~> 1.0` is historical release evidence, not current installation guidance; retain it only under an explicit historical label or replace it with a link to the archived form. [VERIFIED: repository inspection; Phase 164 CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | RESOLVED by Plans 164-01 and 164-04: use one tracked TSV ledger with an ExUnit parser/contract. | Architecture Patterns | The Phase 161 TSV analog already fits repository conventions, exposes every D-05 field directly, and supports deterministic uniqueness, enum, and completeness assertions without a conversion layer. [VERIFIED: plan-backed resolution] |
| A2 | RESOLVED by Plans 164-05 and 164-07: use `scripts/closeout_repository_truth.sh` and write volatile output beneath existing ignored `tmp/`, specifically `tmp/phase-164-closeout/report.json`. | Recommended Project Structure | This reuses the root `/tmp/` producer-owned ignore rule, adds no new ignore entry, and preserves D-09's durable-ledger/volatile-report boundary. [VERIFIED: plan-backed resolution] |

## Open Questions (RESOLVED)

1. **RESOLVED — Which exact checked-in ledger format best fits the existing test helpers?**
   - What we know: Phase 161 uses Markdown inventory plus TSV reconciliation and validates both from shell; Phase 162 parses Markdown tables in ExUnit. [VERIFIED: repository inspection]
   - Selected resolution: Plans 164-01 and 164-04 use `.planning/phases/164-repository-truth-reconciliation-and-closeout/164-TRUTH-DISPOSITION.tsv` with an ExUnit parser in `test/scripts/phase_164_repository_truth_test.exs`.
   - Rationale: TSV matches the Phase 161 reconciliation analog, represents the twelve D-05 columns directly, and makes D-12 uniqueness, enum, and completeness assertions deterministic without a format conversion layer. [VERIFIED: Phase 164 CONTEXT.md D-05/D-12; Plans 164-01/164-04]

2. **RESOLVED — What is the exact final report path and ignore treatment?**
   - What we know: final volatile proof cannot be committed, and broad evidence ignores are prohibited. [VERIFIED: Phase 164 CONTEXT.md D-07, D-09]
   - Selected resolution: Plans 164-05 and 164-07 write `tmp/phase-164-closeout/report.json` beneath the repository's existing root `/tmp/` ignore treatment; no new ignore rule is added.
   - Rationale: the report is machine-local, rerunnable, and intentionally volatile, while the tracked ledger and usage contract remain durable. Reusing the existing narrow producer directory avoids both a self-referential committed snapshot and a new/broad proof exclusion. [VERIFIED: Phase 164 CONTEXT.md D-07/D-09; Plans 164-05/164-07]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| Git | canonical identity/status and tracked state | ✓ | 2.41.0 | — [VERIFIED: local environment] |
| GitHub CLI `gh` | exact CI, scheduled artifacts, branch state | ✓ | 2.95.0 | Existing scripts require it; no equivalent should be introduced. [VERIFIED: local environment and repository inspection] |
| Elixir/Mix | hygiene task and contract tests | ✓ | OTP 28 runtime detected | — [VERIFIED: local environment] |
| Node.js | existing `ci_monitor.cjs` | ✓ | v24.19.0 | `gh run view` is available for narrow direct inspection. [VERIFIED: local environment] |
| `jq` | scheduled-control and JSON contracts | ✓ | 1.7.1 | — [VERIFIED: local environment] |
| Hex public API | published package facts | ✓ | live responses read on 2026-08-26 | `mix hex.info` only if the live API becomes unavailable. [VERIFIED: Hex API] |

**Missing dependencies with no fallback:** None observed. [VERIFIED: local environment]

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit / Mix project tests [VERIFIED: repository inspection] |
| Config file | `mix.exs`, `test/test_helper.exs` [VERIFIED: repository inspection] |
| Quick run command | `mix test test/mailglass/publish/maintaining_release_gate_contract_test.exs test/scripts/scheduled_control_evidence_test.exs --warnings-as-errors --no-deps-check` [VERIFIED: repository inspection] |
| Full suite command | `mix ci.fast` for repository-fast checks; use the phase’s focused tests before it. [VERIFIED: repository inspection] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|---|---|---|---|---|
| TRTH-01 | Current maintainer/package/recovery prose agrees with manifest, release controls, and historical applicability boundary | ExUnit docs contract | `mix test test/mailglass/publish/maintaining_release_gate_contract_test.exs test/mailglass/docs_contract_test.exs --warnings-as-errors --no-deps-check` | ✅ extend existing / Wave 0 assertions [VERIFIED: repository inspection] |
| TRTH-02 | Ledger covers each audited artifact/ignore rule once, with valid disposition/evidence; stale root file is remove-only | ExUnit or shell schema contract | `mix test test/scripts/phase_164_*_test.exs --warnings-as-errors --no-deps-check` | ❌ Wave 0 [VERIFIED: Phase 164 CONTEXT.md] |
| TRTH-03 | Rerunnable closeout command rejects dirty/wrong-ref/non-exact-CI/pending evidence and accepts only complete valid evidence | Integration/contract test plus final operational command | `mix test test/scripts/phase_164_*_test.exs --warnings-as-errors --no-deps-check` | ❌ Wave 0 [VERIFIED: Phase 164 CONTEXT.md] |

### Sampling Rate

- **Per task commit:** Focused docs/ledger/closeout test file(s). [VERIFIED: repository testing convention]
- **Per wave merge:** `mix ci.fast`. [VERIFIED: repository inspection]
- **Phase gate:** Run the closeout report only after protected merge and fresh scheduled-control evidence for exact `main`; its report must record pass or intentionally fail with its blocking state. [VERIFIED: Phase 164 CONTEXT.md D-10, D-11]

### Wave 0 Gaps

- [ ] `test/scripts/phase_164_repository_truth_test.exs` (or equivalent) — ledger schema, exact-one-disposition, all six ignore files, D-08 digest/removal record, and documentation truth contract. [VERIFIED: repository inspection]
- [ ] `test/scripts/phase_164_closeout_test.exs` (or equivalent) — fixture-backed negative paths for wrong branch/SHA, dirty state, pending/cannot-check scheduled evidence, and duplicate/missing ledger evidence. [VERIFIED: Phase 164 CONTEXT.md]
- [ ] A focused closeout wrapper/report only if existing commands cannot provide a single machine-readable verdict without reimplementing their logic. [VERIFIED: Phase 164 CONTEXT.md]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---|---|---|
| V2 Authentication | No | No end-user auth change; GitHub maintainer authorization remains existing workflow control. [VERIFIED: Phase scope and repository inspection] |
| V3 Session Management | No | No session behavior changes. [VERIFIED: Phase scope] |
| V4 Access Control | Yes | Preserve protected exact-digest/repository-admin workflow authorization; do not broaden release authority. [VERIFIED: repository inspection; Phase 164 CONTEXT.md] |
| V5 Input Validation | Yes | Parse external GitHub/Hex/Git JSON defensively and surface malformed/unavailable observations as `cannot-check`, never pass. [VERIFIED: repository inspection] |
| V6 Cryptography | No | Use existing SHA-256 identity values; add no cryptographic implementation. [VERIFIED: Phase scope] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---|---|---|
| Stale run/artifact presented as current proof | Tampering | Bind `event`, run ID, workflow SHA, head SHA, artifact digest, and freshness; reject mismatches/pending. [VERIFIED: repository inspection] |
| Broad ignore conceals contractual proof | Tampering / Repudiation | One ledger row per ignore pattern, named producer, narrow scope, and no broad evidence exclusions. [VERIFIED: Phase 164 CONTEXT.md D-05 through D-07] |
| Unauthorized release/recovery path described as supported | Elevation of Privilege | Make protected exact-candidate authority explicit and preserve workflow authorization gates. [VERIFIED: repository inspection] |
| External query failure rendered green | Repudiation | Maintain the existing `cannot-check` precedence and nonzero failure semantics. [VERIFIED: repository inspection] |

## Sources

### Primary (HIGH confidence)

- [Phase 164 CONTEXT.md](/Users/jon/projects/mailglass/.planning/phases/164-repository-truth-reconciliation-and-closeout/164-CONTEXT.md) — locked scope, disposition, and closeout decisions. [VERIFIED: repository inspection]
- [Repository hygiene task](/Users/jon/projects/mailglass/dev/mix/tasks/mailglass.repo.hygiene.ex) — existing three-state repository audit. [VERIFIED: repository inspection]
- [Scheduled-control verifier](/Users/jon/projects/mailglass/scripts/scheduled_control_evidence.sh) and [scheduled-control registry](/Users/jon/projects/mailglass/.github/scheduled-controls.json) — exact scheduled provenance and freshness rules. [VERIFIED: repository inspection]
- [Phase 162 verification](/Users/jon/projects/mailglass/.planning/phases/162-protected-release-and-scheduled-control-recovery/162-VERIFICATION.md) and [Phase 163 verification](/Users/jon/projects/mailglass/.planning/phases/163-deterministic-release-path-timeout-repairs/163-VERIFICATION.md) — settled evidence and final protected CI identity. [VERIFIED: repository inspection]
- GitHub REST/CLI observation of `main` and CI run `33002642359`; Hex public API observations for all three packages on 2026-08-26. [VERIFIED: GitHub API; VERIFIED: Hex API]

### Secondary (MEDIUM confidence)

- Context7 documentation lookup was unavailable in this environment; no external documentation was used to override repository-local operational authority. [CITED: local Context7 availability check]

### Tertiary (LOW confidence)

- None beyond the two explicit implementation-format assumptions in the Assumptions Log. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all recommended tools are already implemented, tested, and available locally. [VERIFIED: repository inspection; local environment]
- Architecture: HIGH — locked decisions prescribe a dual-proof composition over the existing controls. [VERIFIED: Phase 164 CONTEXT.md]
- Pitfalls: HIGH — each is evidenced by current stale output, existing three-state controls, or historical/current documentation split. [VERIFIED: repository inspection]

**Research date:** 2026-08-26
**Valid until:** 2026-09-02 for live GitHub/Hex identities; repository-structure findings remain valid until the phase changes them. [VERIFIED: GitHub API; Hex API]
