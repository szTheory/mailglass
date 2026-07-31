# Phase 144: Signal & Drift Integrity - Research

**Researched:** 2026-07-31
**Domain:** GitHub Actions release/CI signal integrity and static admin-asset conformance
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Honest Verification Outcomes

- **D-01:** Standardize all three unavailable-verification paths on an explicit, visibly failing outcome
  using the repository's established `if: always()` plus explicit-failure pattern and a precise remediation
  message. The three surfaces are `.github/workflows/branch-protection-drift.yml`'s reassertion job,
  `.github/workflows/ci.yml`'s Branch Protection Advisory job, and `mailglass.repo.hygiene`'s
  `branch_protection` sub-check. Missing credentials, missing tooling, or an inaccessible endpoint must be
  distinguishable from verified drift and from verified no-drift.

- **D-02:** `Branch Protection Advisory` remains publish-gating under the Phase 141 three-tier lane
  contract when its cannot-check path becomes genuinely failable. Do not let the truth fix accidentally
  reclassify or demote the lane.

- **D-03:** Put the recurring read-only protection comparison in the existing scheduled
  `.github/workflows/branch-protection-drift.yml`; do not create another workflow or desired-state
  registry. `scripts/setup_branch_protection.sh --print-expected-json` remains the canonical expected-state
  generator, and `scripts/verify-branch-protection.sh` remains the normalized live comparison seam.

- **D-04:** Add an anti-vacuous workflow-contract regression test that specifically proves the protected
  status context uses the reported job display name rather than the YAML job id. Follow the existing
  contract-test patterns in `test/scripts/required_checks_test.exs` and
  `test/scripts/guard_release_trigger_test.exs`; a parser that matches nothing must fail.

### Dynamic Icon Integrity

- **D-05:** Extend verification of the existing `ICON-EXISTS-GATE`; do not rebuild or broaden its product
  purpose. Use a deliberately missing dynamic `hero-*` value in a throwaway test fixture to prove names
  resolved through `@icon`, `option.icon`, `stat_severity_icon/1`, interpolation, or lookup maps are checked
  against the vendored icon inventory. The negative fixture must fail the real gate and be removed after
  the proof.

- **D-06:** The lasting implementation must cover the dynamic-construction class, not hardcode the two
  historical missing icons or merely add their literal names to a scan. Preserve the existing vendored
  inventory as the source of truth and add no dependency.

### Linked-Release Fan-out

- **D-07:** Give `.github/workflows/publish-hex.yml` and
  `.github/workflows/post-publish-smoke.yml` a release-independent concurrency key so both tag events from
  one linked-version release train serialize rather than racing in ref-specific groups. Fix both identical
  patterns in this phase; do not defer the smoke workflow independently.

- **D-08:** Preserve the existing idempotent successful no-op for an already-published version. A
  redundant serialized run must report success with "nothing to do," never turn a release that shipped
  successfully into a failed release signal.

### Release-Trigger Recovery

- **D-09:** Treat `.github/workflows/release-please.yml`'s existing hourly scheduled recovery as the
  selected TRUTH-04 fix. Preserve its preflight handling of fully present tags, partial release state, and
  `autorelease: tagged`; add durable contract evidence and maintainer-facing documentation proving the
  recovery is visible, idempotent, and cannot double-fire alongside another trigger.

- **D-10:** Do not replace the release triggers or introduce a new topology solely to remove the bounded
  schedule delay. The accepted tradeoff is recovery on the existing hourly cadence, provided the delay and
  recovery behavior are durably documented where future release maintainers will find them.

### the agent's Discretion

- Exact step names, remediation wording, and test-file boundaries, provided each outcome remains distinct
  and anti-vacuous.
- The implementation technique used to resolve dynamic icon values, provided it proves the whole bounded
  dynamic class and does not rebuild the gate.
- The exact shared concurrency-group string, provided it is independent of tag/ref and is identical in
  intent across publish and post-publish smoke.

### Deferred Ideas (OUT OF SCOPE)

None — analysis stayed within the fixed Phase 144 boundary. Pipeline optimization remains sequenced to
SEED-006 after this milestone.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CONFORM-02 | Verify the existing icon gate covers dynamic names, not only literal calls. | Extend the gate's reference extraction and prove it with a temporary missing dynamic fixture that fails the real executable. |
| TRUTH-02 | A check that cannot run never reports success. | Replace credential-skipped outcomes with an `always()` explicit failure and preserve separate drift/no-drift paths. |
| TRUTH-03 | Scheduled live protection comparison catches job-id/display-name mismatch. | Keep the canonical expected JSON and verifier; add a parser-backed display-name contract test with an anti-vacuity assertion. |
| TRUTH-04 | Release-please anti-recursion recovery is fixed or formally accepted. | Preserve the hourly scheduler/preflight; add workflow-contract tests and maintainer documentation for cadence, no-op, partial-state failure, and trigger exclusion. |
| TRUTH-06 | Repo hygiene distinguishes blocked from cannot-check. | Map unavailable `gh`/token/verifier failures to an explicit inconclusive status and ensure aggregate exit status is non-success. |
| TRUTH-08 | Linked release fan-out cannot race or falsely fail after success. | Replace both ref-derived concurrency keys with one release-independent serialization contract, while preserving per-package Hex idempotency. |
</phase_requirements>

## Summary

Phase 144 should be planned as four narrow integrity slices: protection-verification truth, icon-reference coverage, linked-release serialization, and release-please recovery evidence. The repository already owns all required seams: expected branch-protection JSON is generated by `scripts/setup_branch_protection.sh`, comparison is `scripts/verify-branch-protection.sh`, CI workflow contracts live under `test/scripts/`, the icon inventory is vendored, and publish steps already skip a version that Hex reports as released. [VERIFIED: codebase grep]

The central distinction is three-way, never binary: **verified clean**, **verified drift/blocked**, and **could not verify**. GitHub documents that skipped jobs report Success, so PAT-gated skipped verification is a false-green state; an `always()` reporting/failure path is therefore necessary after any precondition failure. [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-jobs-with-conditions?apiVersion=2022-11-28] The phase must retain Phase 141's classification: `Branch Protection Advisory` is publish-gating, even when its newly honest failure path begins to fail. [VERIFIED: codebase grep]

**Primary recommendation:** Implement and test the four existing seams in separate plans; do not add dependencies, a workflow, or a second desired-state registry.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Branch-protection desired/live comparison | CI automation | GitHub branch-protection API | Repository scripts generate desired state and normalize the API response; workflows only orchestrate them. [VERIFIED: codebase grep] |
| Cannot-check classification | CI automation | Maintainer CLI | Workflows and `mailglass.repo.hygiene` must expose a non-success outcome for unavailable credentials/tooling. [VERIFIED: codebase grep] |
| Dynamic icon inventory verification | Static build/conformance | Admin source tree | The shell gate compares source-derived references with the vendored Heroicon key inventory. [VERIFIED: codebase grep] |
| Linked release serialization | CI automation | Hex package registry | Workflow-level concurrency prevents concurrent release-event fan-out; each publish job retains its registry idempotency check. [VERIFIED: codebase grep] |
| Release trigger recovery | CI automation | GitHub releases/PR labels | `release-please.yml` preflight reads expected tags and `autorelease: tagged` before invoking release-please. [VERIFIED: codebase grep] |

## Project Constraints (from AGENTS.md)

No `AGENTS.md` exists. [VERIFIED: codebase grep]

Applicable directives from `CLAUDE.md`:

- Keep all third-party Actions pinned to commit SHAs; Phase 144 should not introduce an action or unpinned reference. [VERIFIED: CLAUDE.md]
- Use Conventional Commits; preserve the no-Node project posture. [VERIFIED: CLAUDE.md]
- The three-tier CI contract is authoritative; no topology rewrite or accidental lane reclassification. [VERIFIED: CLAUDE.md; 141-CONTEXT.md]
- Release publishing is hands-free from protected refs; `HEX_API_KEY` remains protected by `hex-publish`. [VERIFIED: CLAUDE.md]
- Do not manually edit `.planning/STATE.md`. [VERIFIED: CLAUDE.md]

## Standard Stack

### Core

| Library / tool | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| GitHub Actions workflow YAML + shell | Repository-pinned actions | Executes scheduled comparison, release fan-out, and recovery. | Existing automation platform; Phase scope explicitly forbids a topology replacement. [VERIFIED: codebase grep] |
| Bash + `gh` + `jq` | Bash 5.2.37; gh 2.95.0; jq 1.7.1 locally | Generates, fetches, normalizes, and compares branch protection. | Existing scripts already depend on these tools and provide the canonical seam. [VERIFIED: local environment; codebase grep] |
| ExUnit | Project test framework | Parses and asserts workflow/script contracts. | `mix verify.ci_lane_contract` runs every `test/scripts/*_test.exs` in the publish-gating `Mix Task Tests` lane. [VERIFIED: mix.exs; ci.yml] |
| Existing Bash conformance gate | Repository script | Diff source-derived Heroicon names against vendored `heroicons-inline.js`. | Existing `ICON-EXISTS-GATE` is the authorized extension point. [VERIFIED: codebase grep] |

### Supporting

| Library / tool | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| `actions/github-script` | SHA-pinned in workflows | Existing release gate polling and conclusions. | Do not expand it for this phase unless a contract assertion needs its existing behavior inspected. [VERIFIED: codebase grep] |
| `mix hex.info` | Existing Hex client | Detects already-published package versions. | Preserve each package's success/no-op guard exactly when serialization is added. [VERIFIED: codebase grep] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Extend existing scheduled protection workflow | New drift workflow | Rejected by locked D-03; would duplicate ownership and desired-state concerns. [VERIFIED: 144-CONTEXT.md] |
| Extend `ICON-EXISTS-GATE` | New asset registry/DSL | Rejected by phase boundary; it would broaden a bounded static conformance gate. [VERIFIED: 144-CONTEXT.md] |
| Workflow contract parsers | YAML parser dependency | Rejected by repository precedent and no-dependency boundary; hand parsers plus anti-vacuity checks are already established. [VERIFIED: 141-CONTEXT.md; codebase grep] |

**Installation:** None. This phase adds no package or Action. [VERIFIED: 144-CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
scheduled / PR / release event
             |
             v
  existing workflow or Mix task
             |
      +------+-------------------------------+
      |                                      |
      v                                      v
precondition available?                 unavailable precondition
      |                                      |
      v                                      v
canonical verifier / inventory        precise remediation message
      |                                      |
  +---+---+                                  v
  |       |                         explicit failing outcome
  v       v                                  |
clean   verified drift                       v
  |       |                         non-green maintainer signal
  v       v
success  explicit failure

linked release tags --> publish-hex / smoke workflows --> shared, ref-independent
                                                       concurrency serialization
                                                       --> idempotent per-package Hex check
```

The same workflow must never use a skipped path to represent unavailable verification, because GitHub marks skipped jobs successful. [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-jobs-with-conditions?apiVersion=2022-11-28]

### Recommended Project Structure

```text
.github/workflows/
├── branch-protection-drift.yml      # scheduled read-only comparison + honest outcomes
├── ci.yml                           # Branch Protection Advisory + lane contract remains publish-gating
├── publish-hex.yml                  # shared release serialization + existing Hex no-op
├── post-publish-smoke.yml           # matching shared serialization
└── release-please.yml               # hourly recovery preflight
scripts/
├── setup_branch_protection.sh        # sole expected-state generator
└── verify-branch-protection.sh       # sole normalized live comparator
test/scripts/
└── *_test.exs                        # anti-vacuous workflow contracts
mailglass_admin/scripts/
└── check-conformance.sh              # extended dynamic-icon extraction and inventory diff
```

### Pattern 1: Explicit unavailable-verification failure

**What:** Let prerequisite detection run, then have an `if: always()` terminal step branch to three explicit outcomes: verifier success, verifier drift, or precondition unavailable; only the first exits zero. [VERIFIED: 144-CONTEXT.md]

**When to use:** Any check whose claimed subject is live/external and cannot be observed without a credential, executable, or reachable endpoint. [VERIFIED: 144-CONTEXT.md]

**Example:**

```yaml
# Source: GitHub job-condition documentation and Phase 144 locked D-01
- name: Report branch-protection verification outcome
  if: always()
  run: |
    if [ "${{ steps.check-pat.outputs.pat_present }}" != "true" ]; then
      echo "Cannot verify branch protection: configure BRANCH_PROTECTION_PAT with Administration read access." >&2
      exit 1
    elif [ "${{ steps.verify-protection.outcome }}" != "success" ]; then
      echo "Branch protection drifted: run scripts/setup_branch_protection.sh main." >&2
      exit 1
    fi
```

The planner must keep unavailable and drift messages distinct, and must make the verifier step itself `continue-on-error` only when the terminal `always()` step converts its outcome into the authoritative failure. [VERIFIED: ci.yml; 144-CONTEXT.md]

### Pattern 2: Anti-vacuous text-contract parser

**What:** Parse only the bounded workflow block under test, assert the parser found it, then assert the exact invariant and prove a modified in-memory negative control would violate the same assertion. [VERIFIED: test/scripts/guard_release_trigger_test.exs; test/scripts/lane_classification_drift_test.exs]

**When to use:** Workflow semantics that cannot be safely covered locally by executing GitHub Actions. [VERIFIED: codebase grep]

**Example:**

```elixir
# Source: repository contract-test pattern
assert job_block != nil, "Anti-vacuity: expected job block was not parsed"
assert required_contexts == ["CI Green", reported_display_name]
refute required_contexts == ["CI Green", yaml_job_id]
```

The required regression must prove `Guard Release Trigger` (display name), not `guard-release-trigger` (YAML id), is the context emitted and registered in `REQUIRED_CHECKS`. [VERIFIED: 144-CONTEXT.md; scripts/setup_branch_protection.sh; test/scripts/guard_release_trigger_test.exs]

### Pattern 3: Bounded dynamic icon reference expansion

**What:** Preserve the existing literal scan and inventory diff, then add source-aware extraction for values that flow through the single `Components.icon/1` boundary: helper clauses returning `hero-*`, map fields such as `icon: "hero-*"`, and interpolated/lookup construction only when each member can be statically enumerated. [VERIFIED: components.ex; 144-CONTEXT.md]

**When to use:** Templates use `<.icon name={...}>` rather than literal class attributes. [VERIFIED: components.ex]

**Implementation constraint:** If a construct cannot be statically resolved to a finite set, fail the gate with a remediation message rather than silently ignoring it; the scope allows bounded dynamic values, not arbitrary runtime input. [ASSUMED]

### Pattern 4: Shared release serialization plus idempotency

**What:** Use matching workflow-level concurrency groups that do not contain `github.ref`, tag input, or release tag. Keep `cancel-in-progress: false`, and retain per-package `mix hex.info ... | grep Released:` checks. [VERIFIED: 144-CONTEXT.md; publish-hex.yml]

**When to use:** Linked release tags resolve to one release commit but trigger separate `release: published` runs. [VERIFIED: 144-CONTEXT.md]

GitHub Actions serializes runs that share a concurrency group; with `cancel-in-progress: false`, an active run is not cancelled. [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency]

### Anti-Patterns to Avoid

- **Skip-only credential gates:** a skipped GitHub job is displayed as success, so it cannot stand for an unperformed live check. [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-jobs-with-conditions?apiVersion=2022-11-28]
- **A second expected-protection document:** creates a competing desired-state source and violates D-03. [VERIFIED: 144-CONTEXT.md]
- **Whole-file text assertions:** may match unrelated YAML and pass without proving the intended job/input. Use bounded extractors plus anti-vacuity checks. [VERIFIED: test/scripts/lane_classification_drift_test.exs]
- **A ref/tag-derived release group:** keeps the two linked tags in separate groups and preserves the race. [VERIFIED: publish-hex.yml; post-publish-smoke.yml]
- **Hardcoding historical icons:** proves only individual strings, not dynamic construction. [VERIFIED: 144-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Desired branch-protection model | Another JSON/YAML registry | `setup_branch_protection.sh --print-expected-json` | Existing source already drives apply and verifier comparison. [VERIFIED: scripts/setup_branch_protection.sh; scripts/verify-branch-protection.sh] |
| Live branch protection comparison | New API client | `verify-branch-protection.sh` | It already fetches GitHub protection, normalizes variant response shapes, sorts JSON, and diffs. [VERIFIED: scripts/verify-branch-protection.sh] |
| Workflow semantics test framework | YAML dependency or generic parser | Existing `test/scripts` bounded parser style | The project deliberately uses no-dependency anti-vacuous source contracts. [VERIFIED: 141-CONTEXT.md; codebase grep] |
| Icon inventory | New dependency/registry | Vendored `assets/vendor/heroicons-inline.js` keys | Locked source of truth for this gate. [VERIFIED: 144-CONTEXT.md; check-conformance.sh] |
| Publish retry behavior | Custom release-reconciliation path | Existing `mix hex.info` idempotency guards | The three publish jobs already treat an existing Hex version as a successful no-op. [VERIFIED: publish-hex.yml] |

**Key insight:** Phase 144 gains trust by composing and contract-testing existing authority boundaries, not by introducing an abstraction layer. [VERIFIED: 144-CONTEXT.md]

## Common Pitfalls

### Pitfall 1: Making only the verifier failure visible

**What goes wrong:** Missing PAT/tooling still skips the verifier, then a summary-only step exits zero. [VERIFIED: branch-protection-drift.yml; ci.yml]

**How to avoid:** Terminalize each branch under `if: always()` and fail explicitly for unavailable, drift, and inaccessible endpoint; use distinct text for each. [VERIFIED: 144-CONTEXT.md]

### Pitfall 2: Accidentally changing Phase 141's lane disposition

**What goes wrong:** Fixing `Branch Protection Advisory` makes it fail, but an edit removes it from `PUBLISH_GATING_LANES` or classifies it as advisory/required. [VERIFIED: ci_lanes.ex; publish-hex.yml]

**How to avoid:** Add/retain contract assertions that its display name remains in the publish-gating registry and not in `ci_green.needs`. [VERIFIED: 141-CONTEXT.md; codebase grep]

### Pitfall 3: A test proves the wrong context string

**What goes wrong:** `guard-release-trigger` can be parsed from YAML while GitHub reports the `name: Guard Release Trigger` string. [VERIFIED: 144-CONTEXT.md]

**How to avoid:** Parse the actual job block and its `name:`, compare it to `REQUIRED_CHECKS`, assert the historical id is not used, and use an anti-vacuity guard. [VERIFIED: 144-CONTEXT.md; test/scripts/guard_release_trigger_test.exs]

### Pitfall 4: A dynamic-icon fixture is only a literal scan test

**What goes wrong:** Putting a missing literal `hero-*` next to an existing dynamic call can fail the old regex without exercising the dynamic extraction path. [VERIFIED: check-conformance.sh; 144-CONTEXT.md]

**How to avoid:** The temporary fixture must route a missing value through the exact supported dynamic representation and the proof must show the real gate fails before fixture removal. Keep the lasting extractor responsible for that representation. [VERIFIED: 144-CONTEXT.md]

### Pitfall 5: Serialization silently drops a linked run

**What goes wrong:** GitHub concurrency normally permits only one pending run in a group, so a third concurrent dispatch can replace a pending run unless queue behavior is made intentional. [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency]

**How to avoid:** The plan must test/inspect the exact concurrency semantics chosen and retain idempotent no-op publishing; do not claim that a shared group alone guarantees every queued run executes. [ASSUMED]

### Pitfall 6: Treating partial tag state as a no-op

**What goes wrong:** A partly-created linked release train can hide a broken release if preflight simply returns success. [VERIFIED: release-please.yml]

**How to avoid:** Preserve its present-tags/missing-tags hard failure; contract tests must distinguish it from the fully-present no-op and `autorelease: tagged` no-op. [VERIFIED: release-please.yml; 144-CONTEXT.md]

## Code Examples

### Correct release-independent concurrency shape

```yaml
# Source: Phase 144 D-07; GitHub Actions concurrency documentation
concurrency:
  group: mailglass-linked-release-fanout
  cancel-in-progress: false
```

The final string is discretionary, but both workflows must express the same release-independent intent; do not include `${{ github.ref }}`, `github.event.release.tag_name`, or dispatch tag input. [VERIFIED: 144-CONTEXT.md]

### Existing successful no-op shape to retain

```bash
# Source: .github/workflows/publish-hex.yml
if mix hex.info mailglass "${VERSION}" 2>/dev/null | grep -q "Released:"; then
  echo "Version ${VERSION} of mailglass already on Hex — skipping publish (idempotency guard)."
  echo "skip=true" >> "$GITHUB_OUTPUT"
fi
```

The same pattern exists for `mailglass_admin` and `mailglass_inbound`. [VERIFIED: publish-hex.yml]

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| `if: pat_present` skips all meaningful verification | Terminal explicit outcome after prerequisite detection | Makes unavailable verification non-green instead of indistinguishable from clean. [VERIFIED: 144-CONTEXT.md] |
| Ref-scoped workflow concurrency | Shared release-independent serialization | Coordinates linked tags that point to the same train. [VERIFIED: 144-CONTEXT.md] |
| Literal-only Heroicon grep | Literal scan plus bounded dynamic-reference expansion | Covers the defined dynamic call-site class without a new inventory. [VERIFIED: 144-CONTEXT.md] |
| Recovery exists only as workflow comments | Executable contract plus maintainer-facing recovery/cadence documentation | Makes the accepted bounded delay and idempotency durable. [VERIFIED: 144-CONTEXT.md] |

## Recommended Decomposition

1. **TRUTH-02 / TRUTH-03 / TRUTH-06 — Branch-protection signal truth.** Modify only `branch-protection-drift.yml`, `ci.yml`, and `dev/mix/tasks/mailglass.repo.hygiene.ex`; add focused `test/scripts` workflow/task contract coverage. Keep `setup_branch_protection.sh` and `verify-branch-protection.sh` as the only desired/live seams. [VERIFIED: 144-CONTEXT.md]
2. **CONFORM-02 — Dynamic icon proof.** Extend `mailglass_admin/scripts/check-conformance.sh` with bounded dynamic reference resolution and add a shell or ExUnit fixture harness that writes a temporary supported dynamic source value, proves the real command fails, then cleans it in `on_exit`/trap. Run the normal gate as its fast validation. [VERIFIED: 144-CONTEXT.md; check-conformance.sh]
3. **TRUTH-08 — Linked-release serialization.** Change both workflow concurrency blocks atomically; add a source-contract test that extracts both groups, rejects ref/tag expressions, asserts `cancel-in-progress: false`, and confirms all existing three idempotency guards remain. [VERIFIED: 144-CONTEXT.md; publish-hex.yml]
4. **TRUTH-04 — Recovery proof and docs.** Add bounded `release-please.yml` contract tests covering hourly schedule, full-tag no-op, partial-tag failure, pending versus `autorelease: tagged`, and the `should_run` guard; update the existing maintainer recovery section rather than creating a new document. [VERIFIED: release-please.yml; CONTRIBUTING.md; 144-CONTEXT.md]

The first two slices can be independent after current worktree changes are respected; the release slices touch different workflows/tests and can follow in either order. [VERIFIED: codebase grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Any non-finite dynamic icon construction should fail rather than be excluded. | Architecture Pattern 3 | May be too strict for an intended runtime-controlled icon surface. |
| A2 | Shared group semantics alone may not guarantee every queued linked run executes under bursty dispatch. | Pitfall 5 | A test may need to assert queue configuration or revise the release strategy. |

## Open Questions

1. **Can the dynamic icon namespace be fully enumerated with the existing source forms?**
   - What we know: `components.ex` contains `@icon`, `option.icon`, helper-return, and lookup-map forms; the gate presently only extracts literal `hero-*` tokens. [VERIFIED: components.ex; check-conformance.sh]
   - What's unclear: Whether any valid icon is assembled from unbounded runtime input elsewhere in the admin source tree. [ASSUMED]
   - Recommendation: Begin implementation with a source inventory (`<.icon name={` call sites plus helper/map forms). If any unbounded input exists, fail closed with an explicit exception/additional fixture decision rather than silently under-covering it. [ASSUMED]

2. **Do two linked tag events ever produce more than one queued sibling run?**
   - What we know: the phase requires serialization of both tag events and GitHub documents one pending run by default in a group. [VERIFIED: 144-CONTEXT.md; CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency]
   - What's unclear: Whether the repository's actual release event timing can create a third competing run (for example a manual recovery). [ASSUMED]
   - Recommendation: Make the contract explicit about desired behavior for manual dispatch while retaining idempotent no-op behavior; do not claim exact FIFO/execution guarantees without an observed GitHub run. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Bash | conformance and protection scripts | ✓ | 5.2.37 | — |
| `gh` | live protection/release workflow interactions | ✓ | 2.95.0 | GitHub Actions runner uses the existing scripts; local run requires authentication/token. |
| `jq` | protection JSON generation/normalization | ✓ | 1.7.1 | — |
| Elixir / Mix dependencies | workflow contract tests | △ | OTP 28 installed; dependencies stale | Run `mix deps.get` before local ExUnit validation. [VERIFIED: local command] |

**Missing dependencies with no fallback:** None for implementation; local ExUnit verification is currently blocked by the lock/dependency mismatch until dependencies are fetched. [VERIFIED: local command]

**Missing dependencies with fallback:** None. [VERIFIED: local environment]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (project-defined) [VERIFIED: mix.exs] |
| Config file | `test/test_helper.exs` [VERIFIED: codebase grep] |
| Quick run command | `mix test test/scripts/required_checks_test.exs test/scripts/guard_release_trigger_test.exs --warnings-as-errors` [VERIFIED: existing test paths] |
| Full phase contract command | `mix verify.ci_lane_contract` [VERIFIED: mix.exs; ci.yml] |
| Icon gate command | `bash mailglass_admin/scripts/check-conformance.sh` [VERIFIED: ci.yml] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| CONFORM-02 | Dynamic missing Heroicon causes the real gate to fail, normal tree passes. | shell integration / fixture | `bash mailglass_admin/scripts/check-conformance.sh` via fixture harness | ❌ Wave 0 |
| TRUTH-02 | Both workflow cannot-check paths end visibly failed with distinct remediation. | workflow source contract | `mix verify.ci_lane_contract` | ❌ Wave 0 |
| TRUTH-03 | Required context equals job display name, not YAML id; parser cannot match empty. | workflow/script contract | `mix test test/scripts/required_checks_test.exs --warnings-as-errors` | Partial — extend existing |
| TRUTH-04 | Hourly recovery/preflight branches and maintainer cadence documentation remain. | workflow/docs contract | `mix verify.ci_lane_contract` or focused test | ❌ Wave 0 |
| TRUTH-06 | Hygiene returns inconclusive/cannot-check rather than drift for unavailable verifier. | unit/source contract | focused ExUnit task test | ❌ Wave 0 |
| TRUTH-08 | Both workflows share non-ref concurrency and no-op guards remain. | workflow source contract | `mix verify.ci_lane_contract` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** focused ExUnit contract test(s) plus the conformance shell gate when its script changes. [VERIFIED: existing project patterns]
- **Per wave merge:** `mix verify.ci_lane_contract`. [VERIFIED: mix.exs]
- **Phase gate:** full contract suite green and one deliberate, uncommitted dynamic-icon negative fixture observed failing before its cleanup. [VERIFIED: 144-CONTEXT.md]

### Wave 0 Gaps

- [ ] A focused `test/scripts` contract file or extensions proving branch-protection unavailable/drift/clean paths and display-name versus job-id behavior.
- [ ] A repo-hygiene unit-test seam; no focused task tests currently cover `branch_protection/1` outcome semantics. [VERIFIED: codebase grep]
- [ ] A fixture harness for the real dynamic-icon gate with guaranteed cleanup.
- [ ] Source-contract coverage for both release concurrency blocks and `release-please` recovery preflight/docs.
- [ ] Local dependencies: `mix deps.get` before running ExUnit; baseline attempt failed because Ecto's lock is stale. [VERIFIED: local command]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | Yes | PAT presence/permissions are explicit preconditions and failures name required remediation. [VERIFIED: workflow comments; 144-CONTEXT.md] |
| V3 Session Management | No | No application session behavior changes. [VERIFIED: phase scope] |
| V4 Access Control | Yes | Branch-protection administration remains restricted to the existing fine-grained PAT/workflow boundary. [VERIFIED: branch-protection-drift.yml] |
| V5 Input Validation | Yes | Validate branch/tag derived data through existing script and workflow boundaries; do not splice tag values into script bodies. [VERIFIED: publish-hex.yml] |
| V6 Cryptography | No | No cryptographic implementation changes. [VERIFIED: phase scope] |

### Known Threat Patterns for CI/release automation

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Missing/rotated admin credential masquerades as protection compliance | Tampering | Explicit failure with precondition-specific remediation; never skip to green. [VERIFIED: 144-CONTEXT.md] |
| Wrong status-context string leaves protection unenforced | Tampering | Contract-test exact display-name equality against canonical required contexts. [VERIFIED: 144-CONTEXT.md] |
| Two linked tag events publish concurrently | Tampering / DoS | Shared workflow concurrency plus existing idempotent registry checks. [VERIFIED: 144-CONTEXT.md] |
| Recovery reruns an already-tagged release | Repudiation / DoS | Preserve full-tag and `autorelease: tagged` preflight no-op, while partial state fails. [VERIFIED: release-please.yml] |

## Sources

### Primary (HIGH confidence)

- Local repository workflows/scripts/tests named in the Context canonical references — concrete current implementation and required seams. [VERIFIED: codebase grep]
- `.planning/phases/144-signal-drift-integrity/144-CONTEXT.md` — locked decisions and phase boundary. [VERIFIED: codebase grep]
- `.planning/phases/141-lane-truth-foundation/141-CONTEXT.md` and `.planning/phases/143-test-harness-truth/143-CONTEXT.md` — three-tier and anti-vacuity precedents. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)

- [GitHub Actions concurrency](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency) — concurrency group and pending-run behavior. [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency]
- [GitHub job conditions](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-jobs-with-conditions?apiVersion=2022-11-28) — skipped job Success conclusion and `always()` behavior. [CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-jobs-with-conditions?apiVersion=2022-11-28]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — no package choice; all relevant tools and files exist in the repository. [VERIFIED: codebase grep]
- Architecture: HIGH — boundaries are locked by phase Context and witnessed in current seams. [VERIFIED: 144-CONTEXT.md; codebase grep]
- Pitfalls: HIGH — each is the historical or current failure mode recorded in requirements/context/workflows; GitHub concurrency queue nuance is MEDIUM. [VERIFIED: codebase grep; CITED: https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/control-workflow-concurrency]

**Research date:** 2026-07-31
**Valid until:** 2026-08-07 (GitHub Actions semantics are externally evolving; repository evidence remains current to the checked-out commit).
