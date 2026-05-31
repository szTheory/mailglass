# Phase 62: close-gap-evid-02-evid-03-current-release-trust-proof - Research

**Researched:** 2026-05-31  
**Domain:** Elixir/Phoenix release-trust evidence drift closure (reference host dependency truth + CI contract guard)  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Phase 62 implementation scope is the current-release dependency drift identified by the milestone audit. Fix `reference/host_app/mix.exs` from `~> 1.2` / `~> 1.2` / `~> 0.2` to `~> 1.3` / `~> 1.3` / `~> 0.3`, then refresh the reference host lock so the sibling Hex entries resolve to `mailglass` 1.3.0, `mailglass_admin` 1.3.0, and `mailglass_inbound` 0.3.0.
- **D-02:** Do not redesign the existing `trust_lane_clean_baseline` job in `.github/workflows/ci.yml` or the `published-trust-journey` job in `.github/workflows/post-publish-smoke.yml`. Those lanes already run the repo-root trust runner with `--host-root reference/host_app`; the missing proof is the reference host's release-line resolution, not lane topology.
- **D-03:** Refresh the lockfile narrowly. Prefer `mix deps.update mailglass mailglass_admin mailglass_inbound` from `reference/host_app`; accept only those sibling updates plus resolver-required patch churn that is explicitly reviewed.
- **D-04:** Fold `.planning/todos/pending/2026-05-28-add-clean-baseline-trust-lane-after-republish.md` into this phase because Phase 62 is the post-release current-line closure it was waiting for.
- **D-05:** Treat Phase 60 context as superseding the todo's stale "run from `reference/host_app`" wording. The trust runner remains repo-root orchestration via `mix verify.reference_host.journey --host-root reference/host_app`; aliases and dev-only trust tasks are not inherited from Hex dependencies.
- **D-06:** Extend `scripts/check_clean_baseline_hex_only.sh` so it asserts both source and version:
  - `mailglass` resolves via `:hex` at `1.3.0`
  - `mailglass_admin` resolves via `:hex` at `1.3.0`
  - `mailglass_inbound` resolves via `:hex` at `0.3.0`
- **D-07:** Add or extend a focused contract test so the guard cannot drift back to Hex-source-only validation. The audit found the current guard can pass while proving the old release line.
- **D-08:** Live GitHub branch-protection proof for EVID-01 is a residual/manual audit item, not Phase 62 local implementation scope. Agents can preserve notes that it remains pending, but should not plan credentialed server-side branch-protection operations as this phase's code work.
- **D-09:** Live post-publish green-run evidence remains a runtime residual after the dependency drift fix. Phase 62 should make the local repo capable of proving the current release line; observing a future green `post-publish-smoke` run is milestone-audit evidence, not a local implementation blocker.

### the agent's Discretion
- Exact wording of failure output in `scripts/check_clean_baseline_hex_only.sh`, as long as stale versions fail clearly and include expected vs actual version.
- Whether the version-specific guard contract is added to an existing publish/trust-lane contract test file or a new focused test file, following nearby test organization.

### Deferred Ideas (OUT OF SCOPE)
- Live GitHub branch-protection reassertion for EVID-01 — credentialed maintainer action, not Phase 62 local implementation.
- Observing and recording a future green `post-publish-smoke` run with `published-trust-journey` artifact — milestone audit/runtime evidence after the local drift fix.
- Adding `trust_lane_clean_baseline` to branch protection / `REQUIRED_CHECKS` — explicitly out of scope and contrary to Phase 60's publish-gate-only lock.
- Provider-matrix breadth, transport expansion, `SEED-003` ecosystem work, and new reference-app features — all outside v1.3 gap closure.
</user_constraints>

## Summary

The gap is not lane wiring; it is release-line truth in `reference/host_app`. Current constraints are still `~> 1.2`, `~> 1.2`, `~> 0.2`, and lockfile entries resolve `mailglass 1.2.0`, `mailglass_admin 1.2.0`, `mailglass_inbound 0.2.0`, so both clean-baseline and post-publish trust lanes can pass while proving stale versions. [VERIFIED: codebase grep]

The correct Phase 62 plan is a narrow integrity patch: update host constraints to `~> 1.3`/`~> 1.3`/`~> 0.3`, run scoped lock refresh, and harden `scripts/check_clean_baseline_hex_only.sh` to fail on stale versions even when source is `:hex`. Contract tests should pin this behavior in the same trust-lane contract seam already used by CI and post-publish workflow tests. [VERIFIED: codebase grep]

Root package release line is `mailglass 1.3.0`, `mailglass_admin 1.3.0`, `mailglass_inbound 0.3.0`, and Hex metadata confirms those versions were released on 2026-05-29, so the target versions are current and available. [VERIFIED: hex.info + repo manifest]

**Primary recommendation:** Implement only dependency/guard/contract-test drift closure and re-run the existing publish trust contract suite; do not redesign CI topology. [VERIFIED: context decisions]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Reference host package-line truth (`mix.exs`, `mix.lock`) | Database / Storage | API / Backend | Lockfile is canonical persisted resolution state; backend build uses it. [VERIFIED: codebase grep] |
| Hex-source + exact-version clean-baseline validation | API / Backend | Frontend Server (SSR) | Bash/Elixir lock parser is backend build-time gate; workflows call it during CI jobs. [VERIFIED: codebase grep] |
| CI clean-baseline trust proof job | API / Backend | — | Workflow executes build/test commands and emits checkpoint artifact. [VERIFIED: codebase grep] |
| Post-publish trust proof job | API / Backend | — | Release workflow runs same journey against published line and validates checkpoint. [VERIFIED: codebase grep] |
| Contract drift prevention tests | API / Backend | — | ExUnit tests pin workflow/guard string contracts and job shape. [VERIFIED: codebase grep] |

## Project Constraints (from AGENTS.md)

`AGENTS.md` not found at repository root; no project-local override constraints were discovered. [VERIFIED: filesystem check]

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | 1.19.5 | Script/test/runtime for guard and trust runner commands | Existing repo/runtime baseline for all trust-lane checks. [VERIFIED: local runtime] |
| Mix | 1.19.5 | Dependency resolution and targeted lock refresh | Native dependency manager used by host app and workflows. [VERIFIED: local runtime] |
| ExUnit | bundled with Elixir 1.19.5 | Contract tests for workflow/guard behavior | Existing test seam (`test/mailglass/publish/*`). [VERIFIED: codebase grep] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| mailglass | 1.3.0 | Target sibling package in reference host | Required to prove current-release trust line. [VERIFIED: hex.info + repo manifest] |
| mailglass_admin | 1.3.0 | Target sibling package in reference host | Required to prove current-release trust line. [VERIFIED: hex.info + repo manifest] |
| mailglass_inbound | 0.3.0 | Target sibling package in reference host | Required to prove current-release trust line. [VERIFIED: hex.info + repo manifest] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Tightening existing `check_clean_baseline_hex_only.sh` | Add an all-new second script | Duplicates logic and increases drift risk; existing script is already wired into both trust lanes. [VERIFIED: codebase grep] |
| Extending existing trust-lane contract tests | New parallel test suite | Adds maintenance overhead without better coverage for this narrow gap. [VERIFIED: codebase grep] |

**Installation:** No new external packages are required for this phase. [VERIFIED: phase scope/context]

**Version verification (current release line):**
```bash
cd reference/host_app
mix hex.info mailglass 1.3.0
mix hex.info mailglass_admin 1.3.0
mix hex.info mailglass_inbound 0.3.0
```

## Package Legitimacy Audit

Not applicable: this phase does not introduce new external packages; it only aligns existing internal dependency constraints/lock resolution. [VERIFIED: phase scope/context]

## Architecture Patterns

### System Architecture Diagram

```text
reference/host_app/mix.exs + mix.lock
        |
        v
mix deps.get / mix compile (host app)
        |
        v
scripts/check_clean_baseline_hex_only.sh
  (assert source=:hex AND exact versions)
        |
        +--------------------------+
        |                          |
        v                          v
ci.yml: trust_lane_clean_baseline  post-publish-smoke.yml: published-trust-journey
        |                          |
        v                          v
mix verify.reference_host.journey --host-root reference/host_app
        |
        v
scripts/check_trust_runner_checkpoint.sh
        |
        v
tmp/mailglass_trust_runner/checkpoint.json artifact upload
```

### Recommended Project Structure
```text
reference/host_app/               # dependency truth source for clean-baseline trust
scripts/check_clean_baseline_hex_only.sh  # source+version trust guard
test/mailglass/publish/           # trust-lane contract tests
.github/workflows/                # CI + post-publish trust lanes
```

### Pattern 1: Narrow Lock Drift Closure
**What:** Update only three sibling constraints and refresh lock with scoped deps update.  
**When to use:** Trust-lane evidence is stale because host lock resolves old published line.  
**Example:**
```bash
# Source: .planning/phases/60-release-trust-gate-drift-prevention/60-05-PLAN.md
cd reference/host_app
mix deps.update mailglass mailglass_admin mailglass_inbound
```

### Pattern 2: Guard-as-Contract
**What:** Script enforces source + version; ExUnit contract test pins invocation semantics in workflows.  
**When to use:** CI jobs may remain green despite semantic drift in script behavior.  
**Example:**
```elixir
# Source: test/mailglass/publish/ci_trust_lane_contract_test.exs
assert job =~ "run: bash ../../scripts/check_clean_baseline_hex_only.sh"
assert job =~ "run: mix verify.reference_host.journey --host-root reference/host_app"
```

### Anti-Patterns to Avoid
- **Workflow redesign creep:** Changing job topology or branch-protection model in this phase violates locked scope. [VERIFIED: context decisions]
- **Broad lock churn acceptance:** Accepting unrelated lock updates hides risk; require explicit resolver-churn review. [VERIFIED: context decisions]
- **Hex-source-only guard:** Passing `:hex` while version remains stale leaves EVID-02/EVID-03 unsatisfied. [VERIFIED: 60-VERIFICATION + milestone audit]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Lockfile parsing and sibling-source validation | Custom parser in new language/tooling | Existing `scripts/check_clean_baseline_hex_only.sh` Elixir term evaluation seam | Already integrated in both trust lanes and easier to contract-test. [VERIFIED: codebase grep] |
| Workflow trust-lane verification | Manual checklist-only review | Existing ExUnit workflow contract tests | Deterministic regression detection in CI. [VERIFIED: codebase grep] |

**Key insight:** The repo already has the right trust-lane mechanism; only release-line truth and guard strictness are drifting. [VERIFIED: context decisions + audit]

## Common Pitfalls

### Pitfall 1: False-Green Trust Proof
**What goes wrong:** Jobs pass while proving old versions. [VERIFIED: 60-VERIFICATION]  
**Why it happens:** Guard only checks `:hex` source, not exact version. [VERIFIED: script content + 60-VERIFICATION]  
**How to avoid:** Enforce expected-version map in guard and test failure messages with expected vs actual. [VERIFIED: context decisions]  
**Warning signs:** `reference/host_app/mix.lock` shows `1.2.0/1.2.0/0.2.0` while workflows are green. [VERIFIED: codebase grep]

### Pitfall 2: Over-scoped Lock Update
**What goes wrong:** Large lockfile churn obscures what changed and why. [VERIFIED: context decisions]  
**Why it happens:** Running unscoped deps refresh. [VERIFIED: context decisions]  
**How to avoid:** Use `mix deps.update mailglass mailglass_admin mailglass_inbound` only. [VERIFIED: 60-05-PLAN]  
**Warning signs:** Diff touches unrelated packages with no resolver explanation. [ASSUMED]

### Pitfall 3: Runner Invocation Drift
**What goes wrong:** Trust runner called from host app as if root alias/tasks are inherited. [VERIFIED: context decisions]  
**Why it happens:** Misunderstanding Mix alias scope and dev-only runner location. [VERIFIED: context decisions]  
**How to avoid:** Keep repo-root invocation with `--host-root reference/host_app`. [VERIFIED: workflows + context decisions]  
**Warning signs:** Commands drop `--host-root` or run trust task inside `reference/host_app`. [VERIFIED: workflow patterns]

## Code Examples

### Version Drift Probe
```bash
# Source: reference/host_app/mix.lock
rg -n '"mailglass": \{:hex, :mailglass, "1\\.3\\.0"|\
"mailglass_admin": \{:hex, :mailglass_admin, "1\\.3\\.0"|\
"mailglass_inbound": \{:hex, :mailglass_inbound, "0\\.3\\.0"' reference/host_app/mix.lock
```

### Guard Invocation in Both Lanes
```bash
# Source: .github/workflows/ci.yml and .github/workflows/post-publish-smoke.yml
rg -n "check_clean_baseline_hex_only|verify.reference_host.journey --host-root reference/host_app|check_trust_runner_checkpoint" \
  .github/workflows/ci.yml .github/workflows/post-publish-smoke.yml
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hex-source-only clean-baseline guard | Hex-source + exact-version guard (required in Phase 62) | Phase 62 planning target (2026-05-31) | Prevents stale-version false positives for EVID-02/EVID-03. [VERIFIED: context decisions + 60-VERIFICATION] |
| Assuming lane wiring implies requirement closure | Evidence must prove current release line in host lock | v1.3 milestone audit 2026-05-31 | Separates topology health from dependency-truth health. [VERIFIED: milestone audit] |

**Deprecated/outdated:**
- Treating green trust lanes as sufficient while host lock resolves old line is outdated and explicitly flagged as blocker. [VERIFIED: 60-VERIFICATION + milestone audit]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Unrelated lockfile diff lines are always suspicious unless explained | Common Pitfalls | Could overconstrain acceptable resolver churn and slow valid updates. |

## Open Questions (RESOLVED)

1. **Where to pin version-specific guard contract assertions?**
   - Resolution: Extend the existing publish trust-lane contract seam in `test/mailglass/publish/ci_trust_lane_contract_test.exs` first, because it already proves the clean-baseline job contract and keeps the regression coverage colocated with the workflow seam. [RESOLVED]
   - Follow-up rule: Add a separate script-focused test only if the assertion becomes materially harder to read or maintain inside the existing contract file. [RESOLVED]
   - Traceability: This matches the Phase 62 planning recommendation and keeps D-07 minimal-scope without introducing a parallel test seam unless readability requires it. [VERIFIED: context + plan]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `elixir` | Guard script / tests | ✓ | 1.19.5 | — |
| `mix` | deps update, tests, Hex info | ✓ | 1.19.5 | — |
| `python3` | workflow YAML parse check | ✓ | 3.14.4 | — |
| `actionlint` | workflow static lint verification | ✓ | 1.7.12 | Skip lint and rely on YAML parse + contract tests (weaker) |
| `rg` | fast verification grep commands | ✓ | 15.1.0 | `grep` |

**Missing dependencies with no fallback:**
- None.

**Missing dependencies with fallback:**
- None.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.19.5) |
| Config file | `.credo.exs` for lint; ExUnit via Mix defaults (no dedicated `test_helper` override needed for these contract tests) [VERIFIED: codebase pattern] |
| Quick run command | `MIX_ENV=test mix test test/mailglass/publish/ci_trust_lane_contract_test.exs` |
| Full suite command | `MIX_ENV=test mix test test/mailglass/publish/ci_trust_lane_contract_test.exs test/mailglass/publish/post_publish_smoke_contract_test.exs test/mailglass/publish/maintaining_release_gate_contract_test.exs test/scripts/required_checks_test.exs test/mailglass/install/install_first_preview_smoke_test.exs` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| EVID-02 | Clean-baseline lane rejects non-current host sibling resolution | contract + script | `(cd reference/host_app && bash ../../scripts/check_clean_baseline_hex_only.sh)` | ✅ |
| EVID-02 | Clean-baseline lane still invokes guard + trust journey + checkpoint validator | contract | `MIX_ENV=test mix test test/mailglass/publish/ci_trust_lane_contract_test.exs` | ✅ |
| EVID-03 | Post-publish lane still invokes same guard+journery+checkpoint flow | contract | `MIX_ENV=test mix test test/mailglass/publish/post_publish_smoke_contract_test.exs` | ✅ |
| OPS-02 (dependency) | Release-gate contracts remain aligned while gap closes | contract | `MIX_ENV=test mix test test/mailglass/publish/maintaining_release_gate_contract_test.exs test/scripts/required_checks_test.exs` | ✅ |

### Sampling Rate
- **Per task commit:** `MIX_ENV=test mix test test/mailglass/publish/ci_trust_lane_contract_test.exs test/mailglass/publish/post_publish_smoke_contract_test.exs`
- **Per wave merge:** full suite command above + `actionlint .github/workflows/ci.yml .github/workflows/post-publish-smoke.yml`
- **Phase gate:** full suite green + targeted lock/version grep + guard script success.

### Wave 0 Gaps
- [ ] Add/extend contract assertion that guard enforces exact version expectations (currently only invocation topology is pinned). [VERIFIED: current test content]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | N/A for this phase (no auth surface changes) |
| V3 Session Management | no | N/A for this phase (no session surface changes) |
| V4 Access Control | no | N/A for this phase (no authorization logic changes) |
| V5 Input Validation | yes | Strict expected map for lock entries (`name`, `source`, `version`) in guard script |
| V6 Cryptography | no | N/A for this phase |

### Known Threat Patterns for Elixir CI/workflow guard stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Dependency confusion/path leakage in trust host | Tampering | Enforce `:hex` source and expected version for sibling packages in lock guard |
| False evidence claim from stale lock resolution | Repudiation | Version-specific guard + checkpoint contract tests |
| Silent workflow drift | Tampering | ExUnit workflow contract tests + actionlint |

## Sources

### Primary (HIGH confidence)
- `/.planning/phases/62-close-gap-evid-02-evid-03-current-release-trust-proof/62-CONTEXT.md` - locked scope and decisions.
- `/.planning/phases/60-release-trust-gate-drift-prevention/60-VERIFICATION.md` - verified blocker details.
- `/.planning/v1.3-MILESTONE-AUDIT.md` - current requirement gap truth.
- `/reference/host_app/mix.exs` and `/reference/host_app/mix.lock` - actual dependency and lock versions.
- `/scripts/check_clean_baseline_hex_only.sh` - current guard behavior.
- `/test/mailglass/publish/ci_trust_lane_contract_test.exs` and `/test/mailglass/publish/post_publish_smoke_contract_test.exs` - contract test seams.
- `/.github/workflows/ci.yml` and `/.github/workflows/post-publish-smoke.yml` - lane topology and commands.
- Hex package metadata via `mix hex.info mailglass 1.3.0`, `mix hex.info mailglass_admin 1.3.0`, `mix hex.info mailglass_inbound 0.3.0`.

### Secondary (MEDIUM confidence)
- None.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - entirely repo/runtime verified.
- Architecture: HIGH - workflow/script/test seams are directly inspectable.
- Pitfalls: HIGH - backed by 60 verification + milestone audit residuals.

**Research date:** 2026-05-31  
**Valid until:** 2026-06-30 (stable for this narrow repo-local phase unless release line changes)
