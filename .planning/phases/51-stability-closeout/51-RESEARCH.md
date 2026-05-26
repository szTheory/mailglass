# Phase 51: Stability Closeout - Research

**Researched:** 2026-05-26 [VERIFIED: local environment probe]  
**Domain:** Stability-debt closeout across planning artifacts, GitHub branch-protection automation, ExUnit/Ecto test harness isolation, and historical audit reconciliation. [VERIFIED: .planning/ROADMAP.md]  
**Confidence:** MEDIUM [VERIFIED: research synthesis]

<user_constraints>
## User Constraints (from CONTEXT.md)

Verbatim copy from `.planning/phases/51-stability-closeout/51-CONTEXT.md`. [VERIFIED: .planning/phases/51-stability-closeout/51-CONTEXT.md]

### Locked Decisions
- **D-01:** Treat `CLOSE-01` as bookkeeping repair, not new stability-contract implementation. Phase 35 already shipped and its proof artifacts exist; the defect is that `35-VALIDATION.md` still carries stale draft-state fields (`wave_0_complete: false`, pending task rows).
- **D-02:** Keep branch protection repo-as-code. Update the existing `gh api` desired-state script and scheduled drift workflow to match the current required-check truth instead of replacing them with a manual-only runbook.
- **D-03:** Use `MAINTAINING.md` and the current support-contract buckets as the source of truth for required checks, then align the script/workflow to that truth.
- **D-04:** Fix the bare `mix test` citext failure structurally in the test harness or migration flow. The current probes stay as a safety net, but the phase should remove the underlying shared-type-cache invalidation path rather than adding more retry-only mitigation.
- **D-05:** Resolve boundary warnings narrowly in the support-summary and admin-probe verification paths without widening runtime package boundaries. Default to adjusting test/support seams and helper placement rather than relaxing architectural boundaries.
- **D-06:** Audit the old Phase 4 WR-01..WR-06 items against current code individually. Fix any item that still reproduces or still represents a live risk; otherwise close it explicitly with rationale in the milestone audit rather than reopening historical refactors by default.
- **D-07:** Fold the already-known post-`v1.2` release-engineering leftovers into this closeout pass where they overlap the stability-debt boundary: branch-protection automation drift, release/publish workflow truth cleanup, and related carry-forward bookkeeping discovered in Phase 50.7.

### Claude's Discretion
- Exact artifact update sequence across validation, milestone audit, and maintenance docs.
- Exact shape of any supporting verification scripts or test-harness refactors.
- Whether specific WR items are fixed in code or closed-no-action after audit, as long as each item is explicitly justified.

### Deferred Ideas (OUT OF SCOPE)
None — analysis stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CLOSE-01 | Phase 35 Nyquist bookkeeping `wave_0_complete: false` is corrected; verification audit re-runs cleanly. [VERIFIED: .planning/REQUIREMENTS.md] | Re-run and reconcile archived validation artifacts instead of rebuilding Phase 35 behavior. [VERIFIED: .planning/phases/51-stability-closeout/51-CONTEXT.md] |
| CLOSE-02 | GitHub branch-protection automation via `gh api` script in `scripts/` or explicit owner runbook. [VERIFIED: .planning/REQUIREMENTS.md] | Keep repo-as-code, add a read-only verifier, and align required-check strings with `MAINTAINING.md` + live CI job names. [VERIFIED: .planning/phases/51-stability-closeout/51-CONTEXT.md] [CITED: https://docs.github.com/en/rest/branches/branch-protection] |
| CLOSE-03 | Bare `mix test` citext-OID-cache race is fixed so `mix test` is green from a clean clone. [VERIFIED: .planning/REQUIREMENTS.md] | First make the race deterministic, then remove or isolate the shared type-cache invalidation path caused by dropping and recreating `citext`. [VERIFIED: mix.exs] [VERIFIED: test/mailglass/persistence_integration_test.exs] [VERIFIED: test/mailglass/migration_test.exs] |
| CLOSE-04 | Boundary warnings in support-summary and admin probe verification paths are resolved. [VERIFIED: .planning/REQUIREMENTS.md] | Fix test/support seams narrowly; do not widen runtime package boundaries. [VERIFIED: .planning/phases/51-stability-closeout/51-CONTEXT.md] |
| CLOSE-05 | Phase 4 WR-01..WR-06 items are addressed or formally closed-no-action with rationale in `.planning/milestones/v1.0-MILESTONE-AUDIT.md`. [VERIFIED: .planning/REQUIREMENTS.md] | Use the v0.1 audit list as the canonical ledger, audit each item against current code, then either patch or close with explicit rationale. [VERIFIED: .planning/milestones/v0.1-MILESTONE-AUDIT.md] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Mailglass is a Phoenix/Ecto/Postgres library with zero Node toolchain in the product code; Phase 51 should not introduce a Node runtime dependency for runtime fixes. [VERIFIED: CLAUDE.md]
- Boundary-enforced module hierarchy is non-negotiable; CLOSE-04 must not “fix” warnings by broadening runtime boundaries. [VERIFIED: CLAUDE.md]
- Optional dependencies must stay behind `Mailglass.OptionalDeps.*`; this phase should not bypass those seams while touching verification paths. [VERIFIED: CLAUDE.md]
- `mailglass_events` is append-only; any WR closeout touching webhook/event flows must not introduce UPDATE/DELETE semantics on event rows. [VERIFIED: CLAUDE.md]
- Telemetry metadata must remain PII-free; any WR-05 assessment must preserve that posture when auditing tenant-resolution callbacks. [VERIFIED: CLAUDE.md]
- `mix verify.stability_contract` is the semantic proof entrypoint for trust-facing compatibility claims; closeout should extend that proof honestly rather than replace it. [VERIFIED: CLAUDE.md] [VERIFIED: mix.exs]

## Summary

Phase 51 is a reconciliation phase, not a feature phase: four of the five requirements close pre-existing proof debt that is already documented in planning or workflow artifacts, and only CLOSE-03 and part of CLOSE-04 plausibly require substantive code changes in the runtime/test harness. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/PROJECT.md] [VERIFIED: .planning/milestones/v1.0-MILESTONE-AUDIT.md]

The repo already contains the main closeout seams: `35-VALIDATION.md` is the stale Nyquist artifact for CLOSE-01, `scripts/setup_branch_protection.sh` plus `.github/workflows/branch-protection-drift.yml` are the existing branch-protection assets for CLOSE-02, `mix verify.cold_start` and the paired `CitextProbe` modules document the current citext workaround for CLOSE-03, and the carried-forward boundary/WR debt is explicitly tracked in `PROJECT.md`, `STATE.md`, and the v0.1/v1.0 milestone audits. [VERIFIED: .planning/milestones/v1.0-phases/35-stability-contract-audit/35-VALIDATION.md] [VERIFIED: scripts/setup_branch_protection.sh] [VERIFIED: .github/workflows/branch-protection-drift.yml] [VERIFIED: mix.exs] [VERIFIED: test/support/citext_probe.ex] [VERIFIED: mailglass_admin/test/support/citext_probe.ex] [VERIFIED: .planning/STATE.md]

The highest-risk work is CLOSE-03 because the current root alias deliberately excludes `:migration_roundtrip` from `verify.cold_start`, and both the probe comments and migration tests confirm that dropping and recreating `citext` poisons prepared plans and the shared Postgrex type cache. [VERIFIED: mix.exs] [VERIFIED: test/mailglass/persistence_integration_test.exs] [VERIFIED: test/mailglass/migration_test.exs] CLOSE-02 is operationally sensitive but technically narrow: GitHub’s REST API still expects exact required-check contexts when using classic branch protection, so stale job-name strings will produce false assurance or stuck merges unless Phase 51 adds a read-only verification path and aligns the desired state with the current CI buckets. [VERIFIED: scripts/setup_branch_protection.sh] [VERIFIED: MAINTAINING.md] [VERIFIED: .github/workflows/ci.yml] [CITED: https://docs.github.com/en/rest/branches/branch-protection] [CITED: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks]

**Primary recommendation:** Plan Phase 51 as four slices in this order: artifact reconciliation baseline, branch-protection truth-as-code, deterministic citext reproduction plus harness fix, then boundary-warning cleanup plus WR-by-WR audit closure. [VERIFIED: research synthesis]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Phase 35 Nyquist closeout | Planning artifacts | Verification docs | The defect is in archived validation bookkeeping, not in current library behavior. [VERIFIED: .planning/phases/51-stability-closeout/51-CONTEXT.md] |
| Branch-protection automation | GitHub repo settings / CI | Maintainer docs | The repo already has a desired-state script and drift workflow; they need truth alignment, not a new subsystem. [VERIFIED: scripts/setup_branch_protection.sh] [VERIFIED: .github/workflows/branch-protection-drift.yml] |
| Citext race remediation | Test harness / Database | CI cold-start smoke | The race is caused by schema teardown/rebuild interacting with Postgrex/Ecto sandbox state, not by user-facing app logic. [VERIFIED: test/mailglass/persistence_integration_test.exs] [VERIFIED: test/mailglass/migration_test.exs] |
| Boundary warning closeout | Compile-time architecture boundary | Test/support helpers | The carried warnings point at support-summary/admin-probe verification seams, and the context explicitly forbids widening runtime boundaries. [VERIFIED: .planning/phases/51-stability-closeout/51-CONTEXT.md] [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex] |
| WR-01..WR-06 closure | Historical audit ledger | Current webhook/reconcile code | The phase must compare preserved audit findings against live code and either patch or formally close them. [VERIFIED: .planning/milestones/v0.1-MILESTONE-AUDIT.md] |

## Standard Stack

### Core

| Library / Tool | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / Mix | Local env has `Elixir 1.19.5` and `mix`; CI job names target Elixir `1.18` / OTP `27`. [VERIFIED: local environment probe] [VERIFIED: .github/workflows/ci.yml] | Run ExUnit aliases, `mix boundary`, and migration/cold-start verification. [VERIFIED: mix.exs] | The repo already encodes all required proof entrypoints as Mix aliases. [VERIFIED: mix.exs] |
| Ecto + Ecto SQL | `3.13.5` / `3.13.5`. [VERIFIED: mix.lock] | Own migrations, sandbox behavior, and multi-step verification flows involved in the citext race. [VERIFIED: mix.lock] [VERIFIED: test/mailglass/migration_test.exs] | CLOSE-03 lives at the Ecto migrator/sandbox boundary; new abstractions would hide the real fault line. [VERIFIED: test/mailglass/persistence_integration_test.exs] |
| Postgrex | `0.22.0`. [VERIFIED: mix.lock] | Owns prepared plans and type cache behavior behind the citext OID failure. [VERIFIED: mix.lock] [VERIFIED: test/support/citext_probe.ex] | The failure mode is explicitly documented as a Postgrex type-cache issue in repo comments. [VERIFIED: test/support/citext_probe.ex] |
| Boundary | `0.10.4`. [VERIFIED: mix.lock] | Compile-time package-boundary enforcement for CLOSE-04. [VERIFIED: mix.lock] [VERIFIED: test/mailglass/boundary_test.exs] | Boundary is already the project’s locked architectural enforcement mechanism. [VERIFIED: CLAUDE.md] |
| GitHub CLI + REST API | `gh 2.89.0`; branch-protection endpoints current as of GitHub Docs crawl dates in this session. [VERIFIED: local environment probe] [CITED: https://docs.github.com/en/rest/branches/branch-protection] | Apply and verify branch-protection state for CLOSE-02. [VERIFIED: scripts/setup_branch_protection.sh] | The locked decision is repo-as-code with `gh api`, not a manual UI-only process. [VERIFIED: .planning/phases/51-stability-closeout/51-CONTEXT.md] |

### Supporting

| Library / Tool | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `actionlint` | `1.7.12`. [VERIFIED: local environment probe] | Validate workflow edits for branch-protection drift / smoke jobs. [VERIFIED: local environment probe] | Run whenever `.github/workflows/*` changes. [VERIFIED: .planning/milestones/v1.0-MILESTONE-AUDIT.md] |
| `jq` | `1.7.1`. [VERIFIED: local environment probe] | Compare `gh api` JSON responses in a future `verify-branch-protection.sh`. [VERIFIED: local environment probe] | Use for read-only diff/assertion logic in advisory verification scripts. [ASSUMED] |
| Phoenix / LiveView | `1.8.5` / `1.1.28`. [VERIFIED: mix.lock] | Relevant only because the support-summary warning is consumed from `mailglass_admin` operator UI code. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex] | Touch only if boundary cleanup requires moving or reclassifying the `SupportSummary` seam. [VERIFIED: .planning/phases/51-stability-closeout/51-CONTEXT.md] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing `gh api` branch-protection script | Repository ruleset JSON committed to the repo | Rulesets improve visibility and bypass modeling, but Phase 51 is explicitly locked to updating the existing repo-as-code script/workflow rather than replacing it. [VERIFIED: .planning/phases/51-stability-closeout/51-CONTEXT.md] [CITED: https://docs.github.com/en/rest/repos/rules?apiVersion=2026-03-10] |
| Structural citext fix | More retries in `CitextProbe` | More retries would preserve nondeterminism and keep the shared invalidation path alive, which violates D-04. [VERIFIED: .planning/phases/51-stability-closeout/51-CONTEXT.md] [VERIFIED: test/support/citext_probe.ex] |
| Narrow helper relocation / classification fix | Widening Boundary deps for core/admin modules | Widening boundaries would silence the symptom by weakening the project’s architectural contract. [VERIFIED: CLAUDE.md] [VERIFIED: .planning/phases/51-stability-closeout/51-CONTEXT.md] |

**Installation:**
```bash
# No new Hex or npm packages are required by the recommended plan.
# Phase 51 should use the existing repo stack plus local tools already present:
# gh, jq, actionlint, mix.
```

**Version verification:** Versions above come from `mix.lock` and local environment probes, not training-time recall. [VERIFIED: mix.lock] [VERIFIED: local environment probe]

## Architecture Patterns

### System Architecture Diagram

Derived from the current closeout seams and success criteria. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/51-stability-closeout/51-CONTEXT.md]

```text
Archived audit debt / CI drift / test sharp edge
        |
        v
Slice 1: reconcile archived proof artifacts
  35-VALIDATION.md + milestone audits + closeout ledger
        |
        +-----------------------------+
        |                             |
        v                             v
Slice 2: branch-protection truth   Slice 3: citext race reproduction
  MAINTAINING.md -> gh api script     migration_roundtrip + cold-start lane
  -> read-only verify script          -> harness or migration isolation fix
        |                             |
        v                             v
advisory CI proof + owner apply   clean-clone green proof
        |                             |
        +-------------+---------------+
                      |
                      v
Slice 4: boundary warning cleanup + WR-01..06 final disposition
  mix boundary --no-checkout -> milestone audit rationale
                      |
                      v
Final closeout: v1.0/v1.2 debt ledger reaches zero compounding-debt findings
```

### Recommended Project Structure

```text
.planning/phases/51-stability-closeout/   # Research, plan, and execution artifacts for the closeout
.planning/milestones/                     # Historical audits to reconcile, not rewrite wholesale
scripts/                                  # Owner-apply and CI-verify shell entrypoints
.github/workflows/                        # Drift/advisory proof workflows
test/support/                             # Core citext probe and harness seams
mailglass_admin/test/support/             # Admin-local citext probe and support harness seams
test/mailglass/                           # Persistence, migration, boundary, and support-summary proof
```

### Pattern 1: Audit-Fix-Reconcile
**What:** Start by proving whether a debt item is artifact-only or behaviorally live, then patch the narrowest source of truth and rerun the proof. [VERIFIED: research synthesis]  
**When to use:** CLOSE-01 and CLOSE-05, and for any release-engineering leftovers carried forward from Phase 50.7. [VERIFIED: .planning/phases/50.7-v1-2-repo-hygiene-pass/50.7-01-SUMMARY.md]  
**Example:**
```markdown
<!-- Source: .planning/milestones/v1.0-phases/35-stability-contract-audit/35-VALIDATION.md -->
1. Re-run the Phase 35 verification command set.
2. Update `wave_0_complete` and stale task rows in the archived validation artifact.
3. Append the evidence to the milestone audit instead of creating a second parallel truth source.
```

### Pattern 2: Separate Owner-Apply From CI-Verify
**What:** Keep one script that mutates branch protection with admin credentials and a separate read-only verifier that CI can run without changing live state. [VERIFIED: research synthesis]  
**When to use:** CLOSE-02. [VERIFIED: .planning/REQUIREMENTS.md]  
**Example:**
```bash
# Source: GitHub REST branch-protection docs + current setup script
gh api repos/$OWNER/$REPO/branches/main/protection
gh api repos/$OWNER/$REPO/branches/main/protection/required_status_checks
```
Source: [GitHub branch-protection REST docs](https://docs.github.com/en/rest/branches/branch-protection). [CITED: https://docs.github.com/en/rest/branches/branch-protection]

### Pattern 3: Reproduce First, Then Remove the Shared Invalidator
**What:** For citext, the fix sequence should be “make the race deterministic, then eliminate or isolate the `DROP EXTENSION citext` path from the shared pool,” not “hide it behind more retries.” [VERIFIED: mix.exs] [VERIFIED: test/mailglass/persistence_integration_test.exs]  
**When to use:** CLOSE-03. [VERIFIED: .planning/REQUIREMENTS.md]  
**Example:**
```elixir
# Source: mix.exs + test/support/citext_probe.ex
"verify.cold_start": [
  "ecto.drop -r Mailglass.TestRepo --quiet",
  "ecto.create -r Mailglass.TestRepo --quiet",
  "test --warnings-as-errors --exclude flaky --exclude migration_roundtrip"
]
```

### Anti-Patterns to Avoid

- **Rewriting historical artifacts without rerunning proof:** CLOSE-01 is a bookkeeping repair, but the roadmap still requires the verification audit to rerun cleanly. [VERIFIED: .planning/ROADMAP.md]
- **Using CI verification to mutate live branch protection:** advisory proof should read and compare state; only owner-run apply should write settings. [CITED: https://docs.github.com/en/rest/branches/branch-protection]
- **Fixing citext by increasing probe retries:** that preserves the shared invalidation path and keeps green runs nondeterministic. [VERIFIED: test/support/citext_probe.ex]
- **Silencing CLOSE-04 by widening runtime boundaries:** that contradicts CLAUDE.md and the locked context decision. [VERIFIED: CLAUDE.md] [VERIFIED: .planning/phases/51-stability-closeout/51-CONTEXT.md]
- **Closing WR-01..06 as a group:** the requirement and context both demand item-by-item disposition with rationale. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/51-stability-closeout/51-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Branch-protection inspection | HTML scraping or UI-only checklists | `gh api` against GitHub branch-protection endpoints | GitHub already exposes the authoritative branch-protection JSON and required-status-check APIs. [CITED: https://docs.github.com/en/rest/branches/branch-protection] |
| Branch-protection drift proof | A mutating cron-only script as the only signal | A read-only verifier script plus the existing owner-apply script | Verification needs to be safely runnable in CI and by reviewers without admin write side effects. [VERIFIED: research synthesis] |
| Citext race closure | More nested rescue/retry loops | Structural isolation of schema-teardown tests or type-cache reset boundary | The current probes are explicitly documented as mitigation, not desired end state. [VERIFIED: .planning/phases/51-stability-closeout/51-CONTEXT.md] [VERIFIED: test/support/citext_probe.ex] |
| Boundary-warning cleanup | Broader `deps:` or cross-package shortcuts | Test/support relocation or classification fixes | The phase constraint is to resolve warnings narrowly without widening runtime package boundaries. [VERIFIED: .planning/phases/51-stability-closeout/51-CONTEXT.md] |
| WR closeout | New “summary” debt doc detached from milestone audit | Append explicit rationale to `.planning/milestones/v1.0-MILESTONE-AUDIT.md` | CLOSE-05 names that audit file as the formal closure ledger. [VERIFIED: .planning/ROADMAP.md] |

**Key insight:** Most of Phase 51 is not “build new machinery”; it is “connect existing authoritative seams so the repo’s trust posture matches reality.” [VERIFIED: research synthesis]

## Common Pitfalls

### Pitfall 1: Bookkeeping Repair That Never Re-Runs Proof
**What goes wrong:** Archived validation files are edited to look green, but the underlying verification commands are not rerun. [VERIFIED: .planning/ROADMAP.md]  
**Why it happens:** CLOSE-01 is genuinely a bookkeeping issue, which makes it tempting to treat as docs-only. [VERIFIED: .planning/phases/51-stability-closeout/51-CONTEXT.md]  
**How to avoid:** Make the first slice rerun the Phase 35 proof lane before editing `35-VALIDATION.md` and the downstream audit references. [VERIFIED: research synthesis]  
**Warning signs:** `wave_0_complete` flips to `true` without fresh evidence in the phase summary or audit. [ASSUMED]

### Pitfall 2: Idempotent Branch Script With Stale Check Names
**What goes wrong:** The script stays syntactically valid but enforces required checks that no longer exist, producing false assurance or permanently pending PRs. [VERIFIED: scripts/setup_branch_protection.sh] [VERIFIED: .github/workflows/ci.yml] [CITED: https://docs.github.com/en/rest/branches/branch-protection]  
**Why it happens:** GitHub branch protection still keys required checks by exact context strings in the classic endpoint. [CITED: https://docs.github.com/en/rest/branches/branch-protection]  
**How to avoid:** Derive desired check names from `MAINTAINING.md` plus current workflow job names, and make CI run a read-only verifier rather than re-applying mutations. [VERIFIED: MAINTAINING.md] [VERIFIED: .github/workflows/ci.yml]  
**Warning signs:** The script still references `"Tests (Elixir 1.18 / OTP 27)"`, which no longer exists as a CI job. [VERIFIED: scripts/setup_branch_protection.sh] [VERIFIED: .github/workflows/ci.yml]

### Pitfall 3: Non-Deterministic Citext Fixes
**What goes wrong:** Local reruns appear green, but clean-clone or reordered suite runs still fail because the underlying shared cache invalidation path remains. [VERIFIED: mix.exs] [VERIFIED: test/mailglass/persistence_integration_test.exs]  
**Why it happens:** The current root cold-start alias excludes `:migration_roundtrip`, so the main semantic proof lane does not currently exercise the exact teardown/recreate path. [VERIFIED: mix.exs]  
**How to avoid:** Add a deterministic repro command first, then choose between migration isolation and cache-reset containment based on observed behavior. [VERIFIED: .planning/ROADMAP.md]  
**Warning signs:** The only “proof” is that `CitextProbe.run/1` stopped exhausting locally. [VERIFIED: test/support/citext_probe.ex]

### Pitfall 4: Boundary Cleanup by Architectural Capitulation
**What goes wrong:** Boundary warnings disappear only because core/admin dependencies were widened. [VERIFIED: .planning/phases/51-stability-closeout/51-CONTEXT.md]  
**Why it happens:** Helper seams are easier to move than dependency graphs are to understand. [ASSUMED]  
**How to avoid:** Start from the known hotspots: the support-summary indirection in `OperatorLive` and the duplicated admin/root citext probes. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex] [VERIFIED: test/support/citext_probe.ex] [VERIFIED: mailglass_admin/test/support/citext_probe.ex]  
**Warning signs:** Boundary warnings disappear only after edits to root `deps:` declarations rather than helper/module relocation. [ASSUMED]

### Pitfall 5: Dishonest WR Closure
**What goes wrong:** Historical WR items get blanket “already fixed” text without checking current code paths. [VERIFIED: .planning/milestones/v0.1-MILESTONE-AUDIT.md]  
**Why it happens:** The original review artifact is not easily discoverable in the current phase workspace, so the milestone audit becomes the de facto ledger. [VERIFIED: local codebase search]  
**How to avoid:** Treat the v0.1 milestone audit list as canonical input, map each WR to current code, and record either “fixed by X” or “closed-no-action because Y changed.” [VERIFIED: .planning/milestones/v0.1-MILESTONE-AUDIT.md]  
**Warning signs:** CLOSE-05 updates only `.planning/milestones/v1.0-MILESTONE-AUDIT.md` prose without code-path references for each WR item. [ASSUMED]

## Code Examples

Verified patterns from repo sources and official docs:

### Current Cold-Start Alias Documents the Gap
```elixir
# Source: mix.exs
"verify.cold_start": [
  "ecto.drop -r Mailglass.TestRepo --quiet",
  "ecto.create -r Mailglass.TestRepo --quiet",
  "test --warnings-as-errors --exclude flaky --exclude migration_roundtrip"
]
```

### Current Core Citext Probe Documents the Existing Mitigation
```elixir
# Source: test/support/citext_probe.ex
def run(opts \\ []) do
  repo = Keyword.get(opts, :repo, Mailglass.TestRepo)
  probe_fun = Keyword.get(opts, :probe_fun, &default_probe/1)
  ...
  do_probe(repo, max_attempts, max_attempts, probe_fun)
end
```

### GitHub Branch-Protection API Surface the Verifier Should Read
```bash
# Source: GitHub Docs
gh api repos/$OWNER/$REPO/branches/$BRANCH/protection
gh api repos/$OWNER/$REPO/branches/$BRANCH/protection/required_status_checks
```
Source: [GitHub branch-protection REST docs](https://docs.github.com/en/rest/branches/branch-protection). [CITED: https://docs.github.com/en/rest/branches/branch-protection]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual/external branch-protection confirmation | Repo-owned desired-state shell script plus drift workflow, still needing truth alignment | Present by the v1.0/v1.1 release closeout period and still carried into Phase 51. [VERIFIED: scripts/setup_branch_protection.sh] [VERIFIED: .github/workflows/branch-protection-drift.yml] | CLOSE-02 should finish automation by adding truthful verification, not by starting from scratch. [VERIFIED: .planning/phases/51-stability-closeout/51-CONTEXT.md] |
| Monolithic blocking `mix test` gate | Focused CI buckets plus `verify.*` aliases, with advisory full-suite lanes | By current `ci.yml` / `mix.exs` state. [VERIFIED: .github/workflows/ci.yml] [VERIFIED: mix.exs] | CLOSE-03 cannot rely only on existing blocking lanes because the citext race sits outside the normal focused proof path. [VERIFIED: mix.exs] |
| Accepted non-blocking boundary noise | Target is zero warnings on `mix boundary --no-checkout` | Set explicitly in Phase 51 roadmap success criteria. [VERIFIED: .planning/ROADMAP.md] | CLOSE-04 needs a real architectural cleanup, not a re-acceptance note. [VERIFIED: .planning/ROADMAP.md] |

**Deprecated/outdated:**

- Stale required-check context `"Tests (Elixir 1.18 / OTP 27)"` in `scripts/setup_branch_protection.sh` is outdated relative to the current CI job graph. [VERIFIED: scripts/setup_branch_protection.sh] [VERIFIED: .github/workflows/ci.yml]
- Treating `.planning/publish/*-publish-summary.json` as disposable generated output is already superseded by Phase 50.7 and must not be reintroduced while closing related audit debt. [VERIFIED: .planning/phases/50.7-v1-2-repo-hygiene-pass/50.7-01-SUMMARY.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `jq` is the best supporting tool for a future `verify-branch-protection.sh` implementation. [ASSUMED] | Standard Stack | Low; a pure-shell or Elixir JSON parser could replace it. |
| A2 | Boundary warning fixes will likely come from helper relocation/classification rather than runtime dependency edits. [ASSUMED] | Common Pitfalls | Medium; if the true warning source is elsewhere, the slice may need broader code search before edits. |
| A3 | A fresh rerun of Phase 35 proof will be sufficient to justify `wave_0_complete: true` without any underlying behavior changes. [ASSUMED] | Summary / Pattern 1 | Medium; if Phase 35 proof now regresses, CLOSE-01 stops being bookkeeping-only. |
| A4 | The current live GitHub repo state still needs explicit re-verification beyond the historical 044.5 evidence. [ASSUMED] | Open Questions | Medium; if protection is already installed differently, the script/verifier must reconcile to live truth rather than old assumptions. |

## Open Questions

1. **What is the exact current live branch-protection state on `main`?**
   - What we know: the repo contains a desired-state script, a drift workflow, and historical evidence that protection was absent during the 044.5 ceremony. [VERIFIED: scripts/setup_branch_protection.sh] [VERIFIED: .github/workflows/branch-protection-drift.yml] [VERIFIED: .planning/PROJECT.md]
   - What's unclear: no live `gh api` read against the actual repository state was performed in this session. [ASSUMED]
   - Recommendation: make the first CLOSE-02 task a read-only `gh api` inventory and use that output to set the canonical expected JSON before changing scripts. [VERIFIED: research synthesis]

2. **Can the citext race be fixed by isolating the migration roundtrip, or does Postgrex cache state need an explicit harness reset?**
   - What we know: the current repo comments identify shared prepared-plan/type-cache poisoning after `DROP/CREATE EXTENSION citext`, and the cold-start alias currently excludes the roundtrip test. [VERIFIED: test/support/citext_probe.ex] [VERIFIED: mix.exs]
   - What's unclear: whether isolation alone is enough in the present dependency/runtime mix, or whether a broader test boot ordering change is required. [ASSUMED]
   - Recommendation: dedicate the first CLOSE-03 slice to a deterministic repro command and capture its failure mode before choosing the final remediation. [VERIFIED: .planning/ROADMAP.md]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `gh` | CLOSE-02 apply/verify scripts | ✓ [VERIFIED: local environment probe] | `2.89.0` [VERIFIED: local environment probe] | None for repo-as-code; manual GitHub UI would violate locked decision D-02. [VERIFIED: .planning/phases/51-stability-closeout/51-CONTEXT.md] |
| `jq` | Likely JSON assertion helper for CLOSE-02 verify script | ✓ [VERIFIED: local environment probe] | `jq-1.7.1` [VERIFIED: local environment probe] | Parse in Elixir or shell if needed. [ASSUMED] |
| `actionlint` | Workflow verification for CLOSE-02/CLOSE-03 | ✓ [VERIFIED: local environment probe] | `1.7.12` [VERIFIED: local environment probe] | None as strong; regex-only workflow checks would be weaker. [ASSUMED] |
| `mix` | All closeout proof lanes | ✓ [VERIFIED: local environment probe] | present; repo CI targets Elixir `1.18` / OTP `27`, local env surfaced Elixir `1.19.5` / OTP `28`. [VERIFIED: local environment probe] [VERIFIED: .github/workflows/ci.yml] | None. |
| PostgreSQL CLI/server | Local reproduction of CLOSE-03 | ✓ [VERIFIED: local environment probe] | `14.17` [VERIFIED: local environment probe] | CI-backed reproduction if local DB state differs. [ASSUMED] |

**Missing dependencies with no fallback:**

- None identified in this session. [VERIFIED: local environment probe]

**Missing dependencies with fallback:**

- None identified in this session, but local Mix verification is currently blocked by dependency lock drift until `mix deps.get` or a clean clone is used. [VERIFIED: local command failure on `mix boundary --no-checkout`]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit plus shell/workflow verification. [VERIFIED: .planning/milestones/v1.0-phases/35-stability-contract-audit/35-VALIDATION.md] |
| Config file | `config/test.exs`, `mailglass_admin/config/test.exs`, `.github/workflows/*.yml`. [VERIFIED: .planning/milestones/v1.0-phases/35-stability-contract-audit/35-VALIDATION.md] [VERIFIED: .github/workflows/ci.yml] |
| Quick run command | Task-local: `mix test test/mailglass/stability_contract_test.exs test/mailglass/operator/support_summary_test.exs test/mailglass/persistence_integration_test.exs test/mailglass/migration_test.exs test/mailglass/boundary_test.exs --warnings-as-errors` plus `cd mailglass_admin && mix test test/mailglass_admin/stability_contract_test.exs test/mailglass_admin/test_support/citext_probe_test.exs --warnings-as-errors` as touched scope demands. [VERIFIED: file inventory] [ASSUMED] |
| Full suite command | `mix verify.stability_contract && mix verify.cold_start && actionlint .github/workflows/ci.yml .github/workflows/branch-protection-drift.yml .github/workflows/post-publish-smoke.yml`. [VERIFIED: mix.exs] [VERIFIED: local environment probe] [ASSUMED] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CLOSE-01 | Phase 35 validation artifact is rerun and reconciled honestly. [VERIFIED: .planning/ROADMAP.md] | docs + proof rerun | Re-run the Phase 35 proof commands from `35-VALIDATION.md`, then `rg -n "wave_0_complete: true|Approval:" .planning/milestones/v1.0-phases/35-stability-contract-audit/35-VALIDATION.md`. [VERIFIED: .planning/milestones/v1.0-phases/35-stability-contract-audit/35-VALIDATION.md] [ASSUMED] | ✅ |
| CLOSE-02 | Branch-protection desired state and advisory verification match current required checks. [VERIFIED: .planning/ROADMAP.md] | shell + workflow + live API | `bash scripts/verify-branch-protection.sh` plus `actionlint .github/workflows/branch-protection-drift.yml`. [VERIFIED: .planning/ROADMAP.md] [ASSUMED] | ❌ Wave 0 |
| CLOSE-03 | Bare `mix test` is green from a clean clone, covering the citext race path. [VERIFIED: .planning/ROADMAP.md] | cold-start integration | New clean-clone smoke command should include `mix deps.get && mix test --warnings-as-errors` or an equivalent workflow lane that does not exclude `migration_roundtrip`. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: mix.exs] [ASSUMED] | ❌ Wave 0 |
| CLOSE-04 | `mix boundary --no-checkout` reports zero warnings. [VERIFIED: .planning/ROADMAP.md] | compile-time boundary check | `mix boundary --no-checkout`. [VERIFIED: .planning/ROADMAP.md] | ✅ |
| CLOSE-05 | WR-01..WR-06 are patched or explicitly closed with rationale. [VERIFIED: .planning/ROADMAP.md] | audit + targeted tests/grep | Targeted webhook/reconcile tests for any code fixes plus `rg -n "WR-01|WR-02|WR-03|WR-04|WR-05|WR-06" .planning/milestones/v1.0-MILESTONE-AUDIT.md`. [VERIFIED: .planning/milestones/v0.1-MILESTONE-AUDIT.md] [ASSUMED] | ✅ |

### Sampling Rate

- **Per task commit:** Run the smallest touched proof lane plus any relevant shell/workflow checks. [VERIFIED: research synthesis]
- **Per wave merge:** `mix verify.stability_contract` and any touched workflow/script validation. [VERIFIED: mix.exs]
- **Phase gate:** clean-clone citext proof, `mix boundary --no-checkout`, branch-protection advisory verification, and milestone-audit reconciliation must all be green or explicitly justified before `/gsd-verify-work`. [VERIFIED: .planning/ROADMAP.md]

### Wave 0 Gaps

- [ ] `scripts/verify-branch-protection.sh` — required by the roadmap success criteria but not present in the repo today. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: local file inventory]
- [ ] A committed clean-clone or CI smoke lane that proves bare `mix test` without excluding the migration-roundtrip path. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: mix.exs]
- [ ] Local dependency sync before boundary/cold-start commands can run in this checkout; `mix boundary --no-checkout` currently stops on dependency lock drift. [VERIFIED: local command failure on `mix boundary --no-checkout`]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase 51 does not introduce new end-user auth flows. [VERIFIED: phase scope] |
| V3 Session Management | no | No session-layer changes are in scope. [VERIFIED: phase scope] |
| V4 Access Control | yes | GitHub branch protection and environment approval remain the release-governance control surface. [VERIFIED: MAINTAINING.md] [CITED: https://docs.github.com/en/rest/branches/branch-protection] |
| V5 Input Validation | yes | Shell scripts should validate repo/branch/API responses before asserting pass, especially in read-only verification mode. [ASSUMED] |
| V6 Cryptography | no | No new cryptographic logic is recommended; branch-protection work uses GitHub-authenticated API calls, not custom crypto. [CITED: https://docs.github.com/en/rest/branches/branch-protection] |

### Known Threat Patterns for This Phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| False proof from stale branch-check names | Tampering | Read live branch-protection JSON and compare it to documented required checks. [VERIFIED: scripts/setup_branch_protection.sh] [VERIFIED: MAINTAINING.md] [CITED: https://docs.github.com/en/rest/branches/branch-protection] |
| Silent weakening of architecture boundaries | Elevation of privilege | Keep boundary fixes narrow and re-run `mix boundary --no-checkout`. [VERIFIED: .planning/phases/51-stability-closeout/51-CONTEXT.md] |
| Historical audit laundering | Repudiation | Append rationale and fresh evidence in the milestone audit instead of silently editing conclusions. [VERIFIED: .planning/ROADMAP.md] |
| Nondeterministic green CI hiding shared-cache faults | Denial of service | Add deterministic clean-clone/cold-start proof that exercises the citext teardown path. [VERIFIED: mix.exs] [VERIFIED: .planning/ROADMAP.md] |

## Sources

### Primary (HIGH confidence)

- `.planning/ROADMAP.md` - Phase 51 goal, requirements, success criteria, and implementation notes. [VERIFIED: .planning/ROADMAP.md]
- `.planning/REQUIREMENTS.md` - CLOSE-01..05 definitions and traceability. [VERIFIED: .planning/REQUIREMENTS.md]
- `.planning/phases/51-stability-closeout/51-CONTEXT.md` - locked decisions and phase boundary. [VERIFIED: .planning/phases/51-stability-closeout/51-CONTEXT.md]
- `.planning/PROJECT.md`, `.planning/MILESTONES.md`, `.planning/STATE.md` - current milestone state and accepted carry-forward debt. [VERIFIED: codebase grep]
- `.planning/milestones/v1.0-phases/35-stability-contract-audit/35-VALIDATION.md` - stale Nyquist bookkeeping artifact. [VERIFIED: .planning/milestones/v1.0-phases/35-stability-contract-audit/35-VALIDATION.md]
- `.planning/milestones/v1.0-MILESTONE-AUDIT.md` and `.planning/milestones/v0.1-MILESTONE-AUDIT.md` - canonical debt ledgers for CLOSE-01 and CLOSE-05. [VERIFIED: codebase grep]
- `scripts/setup_branch_protection.sh`, `.github/workflows/branch-protection-drift.yml`, `.github/workflows/ci.yml`, `MAINTAINING.md` - current branch-protection and required-check truth. [VERIFIED: codebase grep]
- `mix.exs`, `mix.lock`, `test/support/citext_probe.ex`, `mailglass_admin/test/support/citext_probe.ex`, `test/mailglass/persistence_integration_test.exs`, `test/mailglass/migration_test.exs`, `test/mailglass/boundary_test.exs`, `mailglass_admin/lib/mailglass_admin/operator_live.ex`, `lib/mailglass/operator/support_summary.ex` - citext and boundary proof seams. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)

- GitHub Docs: branch-protection REST endpoints. [CITED: https://docs.github.com/en/rest/branches/branch-protection]
- GitHub Docs: repository rulesets REST endpoints. [CITED: https://docs.github.com/en/rest/repos/rules?apiVersion=2026-03-10]
- GitHub Docs: troubleshooting required status checks. [CITED: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks]

### Tertiary (LOW confidence)

- None. All non-local claims are tied to official GitHub documentation; remaining uncertainty is captured in the Assumptions Log. [VERIFIED: research synthesis]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - versions and tools were verified from `mix.lock` and local probes. [VERIFIED: mix.lock] [VERIFIED: local environment probe]
- Architecture: MEDIUM - slice ordering and remediation shape are strongly grounded in codebase evidence, but the exact citext fix and current live branch-protection state still require execution-time confirmation. [VERIFIED: codebase evidence] [ASSUMED]
- Pitfalls: HIGH - each major pitfall is directly documented in roadmap/context/comments or follows from official GitHub behavior. [VERIFIED: codebase evidence] [CITED: GitHub docs URLs above]

**Research date:** 2026-05-26 [VERIFIED: local environment probe]  
**Valid until:** 2026-06-25 for repo-internal findings; re-verify live GitHub settings sooner if Phase 51 execution is delayed. [VERIFIED: research synthesis]
