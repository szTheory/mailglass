# Phase 66: Release Position Decision - Research

**Researched:** 2026-06-01  
**Domain:** Release-position decision and release-evidence closure for `mailglass_inbound`  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Plan Phase 66 around promoting `mailglass_inbound` to `1.0.0`, not
  a final `0.x`, if the phase re-runs the release-blocking verification lanes
  and finds no blocker. The v1.4 lock evidence is already strong enough that
  the default decision should be promotion, with the final check serving as the
  proof gate rather than another product-design round.
- **D-02:** Keep the fallback explicit: if Phase 66 verification finds a real
  stability or release blocker, cut one final `0.x` confidence release with
  clear "next is 1.0" framing instead of weakening the `1.0.0` compatibility
  promise.
- **D-03:** Treat Phase 66 as evidence collation, verification, and release
  posture documentation. It should not expand the stable surface or change the
  Phase 63 stable/testing/internal/deferred inventory except to fix discovered
  release-blocking drift.
- **D-04:** The release decision should cite committed evidence from the v1.4
  lock: Phase 63 inventory reconciliation, Phase 64 executable stability
  contract proof, Phase 65 compatibility/docs/DX verification, current Hex
  release truth, and the current release-blocking verification commands.
- **D-05:** Phase 66 planning should include a fresh verification pass for at
  least `mix verify.stability_contract` and `mix mailglass.publish.check
  --package mailglass_inbound`, then record the results in the phase artifacts
  and release notes.
- **D-06:** Write release notes in a sober operational style: adopter action
  required, verification commands, behavior changes, operator-impacting
  changes, compatibility posture, and explicit stable/internal/deferred
  boundaries.
- **D-07:** Route compatibility truth to
  `mailglass_inbound/docs/api_stability.md` and the compatibility guide instead
  of restating a second contract in the changelog. Release notes may summarize
  the posture, but the canonical contract remains the inventory and executable
  support-contract lane.
- **D-08:** Avoid hype or ambiguity. The release note should say plainly that
  `mailglass_inbound` is being promoted to the `1.0.0` compatibility line only
  because the stable contract is explicit, narrow, documented, and verified.
- **D-09:** Treat release ceremony mechanics as follow-on implementation detail:
  update inbound version truth, dependency pins, README install pins,
  changelog/release notes, release-please manifest/config expectations, and
  publish-summary evidence consistently during execution.
- **D-10:** Start from current package truth: `mailglass_inbound` is currently
  `0.3.0` in `mailglass_inbound/mix.exs`, `.release-please-manifest.json`, and
  Hex.pm. Phase 66 should not assume a hidden unpublished inbound version.
- **D-11:** Keep release automation aligned with existing repo patterns:
  release-please owns version bump PRs, package publish checks own tarball and
  metadata truth, and the manual `workflow_dispatch` publish fallback remains
  the documented recovery path if GitHub release fanout is blocked.

### the agent's Discretion
- Planner may decide whether to express the release decision as a dedicated
  `66-RELEASE-POSITION.md`, a changelog section, or both, as long as REL-01 and
  REL-02 are directly satisfied and downstream release ceremony work has one
  unambiguous source of truth.
- Planner may decide the exact release-blocking verification command set beyond
  the required stability contract and inbound publish check, but should prefer
  existing repo-native lanes over inventing new release gates.

### Deferred Ideas (OUT OF SCOPE)
None - analysis stayed within Phase 66 scope.

The following remain explicitly out of scope for v1.4 feature work unless a
future milestone separately promotes them: matcher expansion beyond recipient,
subject, and headers; mailbox lifecycle callbacks beyond `process/1`; public
replay API; public provider extension API; public worker/queue contract;
synthetic inbound development UI; `gen_smtp` listener work; ecosystem
integrations; and admin DOM/component guarantees.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REL-01 | Explicit inbound `1.0.0` vs final `0.x` decision from committed evidence | Evidence-gate commands, release-truth files, and decision rubric below |
| REL-02 | Release notes explain contract posture without hype/ambiguity | Release note schema and canonical-source routing below |
| REL-03 | No broad feature-growth milestone opens before this decision | State/roadmap guardrail and planning-state update requirement below |
</phase_requirements>

## Summary

Phase 66 should be planned as a release-governance phase, not a product-change phase. The repo already has the key proof lanes (`mix verify.stability_contract`, package-level publish check, docs-contract enforcement, release automation topology), so planning should focus on rerunning those lanes, capturing fresh evidence, and converting that evidence into a binary release decision with documented fallback. [VERIFIED: codebase grep]

Current package truth is coherent across source and registry: `mailglass_inbound` is `0.3.0` in `mailglass_inbound/mix.exs`, `.release-please-manifest.json`, and Hex release metadata (released 2026-05-29). That makes Phase 66 a decision on whether to promote to `1.0.0` now versus one explicit confidence `0.x` release, not a discovery of unknown version state. [VERIFIED: codebase grep] [VERIFIED: hex registry via mix hex.info]

**Primary recommendation:** Plan for a default `1.0.0` promotion path gated by fresh green runs of `mix verify.stability_contract` and `mix mailglass.publish.check --package mailglass_inbound`; only switch to final `0.x` if those runs expose a real blocker. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Release position decision artifact | API / Backend | — | Decision is repository/process truth derived from backend verification lanes |
| Stability contract verification | API / Backend | Frontend Server (SSR) | Mix aliases/tests are backend-owned; docs consistency touches rendered docs |
| Publish-readiness proof (`mailglass.publish.check`) | API / Backend | CDN / Static | Tarball, metadata, and changelog checks govern package artifacts |
| Release automation consistency (release-please + publish workflow) | API / Backend | — | CI workflows and version manifest control release state transitions |
| Planning-state gate against feature growth | API / Backend | — | `.planning` state and roadmap are backend/project governance artifacts |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | 1.19.5 | Build/test/release runtime | Existing project baseline and CI-compatible release tooling [VERIFIED: local command] |
| Erlang/OTP | 28 | BEAM runtime | Current runtime for all Mix verification lanes [VERIFIED: local command] |
| Mix aliases (`verify.stability_contract`) | repo-defined | Contract proof gate | Canonical aggregated lane already wired across core/admin/inbound [VERIFIED: codebase grep] |
| `mix mailglass.publish.check` | repo-defined | Pre-publish release blocker checks | Enforces tarball, metadata, dependency, changelog, and advisory checks [VERIFIED: codebase grep] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| release-please action | pinned commit (`googleapis/release-please-action@45996e...`) | Version PR automation | Use for normal version bump + sibling pin syncing path [VERIFIED: codebase grep] |
| GitHub Actions publish workflow | repo workflow | Publish and fallback dispatch | Use for tagged release path, `workflow_dispatch` for fallback recovery [VERIFIED: codebase grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Existing Mix verify/publish lanes | New ad hoc Phase 66 scripts | Adds duplicate, less-trusted release gates and drift risk [VERIFIED: codebase grep] |
| release-please managed bump | Manual version edits only | Higher human error risk for linked pin/version sync [VERIFIED: codebase grep] |

**Installation:**  
No new external packages are required for Phase 66 planning/execution. [VERIFIED: codebase grep]

## Package Legitimacy Audit

Not applicable for this phase: no new third-party package installation is part of the recommended Phase 66 implementation path. [VERIFIED: codebase grep]

## Architecture Patterns

### System Architecture Diagram

```text
Input: Existing lock evidence + fresh verify commands
   |
   v
Run release-blocking lanes
  - mix verify.stability_contract
  - mix mailglass.publish.check --package mailglass_inbound
   |
   v
Decision point: any real blocker?
   |                      |
  no                     yes
   |                      |
   v                      v
Promote to 1.0.0      Final explicit 0.x confidence release
   |                      |
   +----------+-----------+
              v
Write release-position artifact + release notes
              |
              v
Update planning state to keep broad feature-growth blocked until decision closure
```

### Recommended Project Structure
```text
.planning/phases/66-release-position-decision/
├── 66-RESEARCH.md          # this document
├── 66-PLAN*.md             # planner outputs
├── 66-RELEASE-POSITION.md  # recommended decision artifact (or equivalent)
└── 66-VERIFICATION.md      # evidence capture from required commands
```

### Pattern 1: Evidence-First Release Decision
**What:** Treat release decision as an explicit output from green verification lanes plus current release truth.  
**When to use:** Any package-line promotion (`0.x` -> `1.0.0`) with existing contract tests.  
**Example:**
```bash
mix verify.stability_contract
mix mailglass.publish.check --package mailglass_inbound
mix hex.info mailglass_inbound 0.3.0
```

### Anti-Patterns to Avoid
- **Re-arguing contract scope in Phase 66:** Scope was locked in Phases 63-65; Phase 66 is decision and evidence collation only. [VERIFIED: codebase grep]
- **Splitting compatibility truth across multiple contradictory files:** Keep canonical truth in `mailglass_inbound/docs/api_stability.md` + compatibility guide; changelog should summarize. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Release proof aggregation | Custom one-off scripts | `mix verify.stability_contract` and `mix mailglass.publish.check` | Existing lanes are already contract-tested and repo-native |
| Version choreography | Manual multi-file sync process | release-please + existing workflow sync steps | Already encodes sibling pin + README pin behavior |
| Publish fallback process | New emergency flow | Existing `workflow_dispatch` fallback in `publish-hex.yml` | Recovery path already documented and implemented |

**Key insight:** Phase 66 should consume established release controls, not invent new ones. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Treating docs summaries as canonical contract
**What goes wrong:** Changelog wording drifts from canonical stability docs.  
**Why it happens:** Teams duplicate compatibility guarantees in release notes.  
**How to avoid:** Keep release notes as summary; route guarantee truth to `api_stability.md` and compatibility guide.  
**Warning signs:** Contradictory stable/internal/deferred wording between files.

### Pitfall 2: Promoting to `1.0.0` without rerunning release gates
**What goes wrong:** Decision references stale evidence and misses regression drift.  
**Why it happens:** Prior phase passes are assumed current.  
**How to avoid:** Require fresh pass artifacts for Phase 66 decision record.  
**Warning signs:** No command output timestamps in Phase 66 artifacts.

## Code Examples

### Required Phase 66 verification lane
```bash
# canonical aggregate contract proof
mix verify.stability_contract

# canonical package pre-publish blocker lane
mix mailglass.publish.check --package mailglass_inbound
```

### Current release truth check
```bash
mix hex.info mailglass_inbound 0.3.0
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Implicit confidence-based release posture | Explicit evidence-gated release-position phase | v1.4 (Phase 66 definition) | Binary, auditable decision and reduced ambiguity |
| Broad roadmap expansion while package line uncertain | Feature-growth blocked until release-position decision | v1.4 convergence rule | Prevents premature scope expansion |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Recommended optional artifact name `66-RELEASE-POSITION.md` is acceptable if planner chooses it | Architecture Patterns | Low; can be replaced by changelog section + verification file |

## Open Questions

1. **Where should the final binary decision be canonicalized?**
   - What we know: CONTEXT allows dedicated artifact, changelog section, or both.
   - What's unclear: Team preference for audit/readability.
   - Recommendation: Planner should pick one canonical source plus cross-links.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/Mix | Verification commands | ✓ | Elixir 1.19.5 / Mix 1.19.5 | — |
| Erlang/OTP | Runtime for verification | ✓ | OTP 28 | — |
| jq | Workflow/release metadata checks | ✓ | 1.7.1 | — |
| gh | Release workflow interactions | ✓ | 2.93.0 | GitHub UI/manual |

**Missing dependencies with no fallback:** none  
**Missing dependencies with fallback:** none

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (built into Elixir) [VERIFIED: codebase grep] |
| Config file | `mix.exs` aliases and test paths [VERIFIED: codebase grep] |
| Quick run command | `mix verify.stability_contract` |
| Full suite command | `mix test --warnings-as-errors` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REL-01 | Explicit release decision from committed evidence | integration/process | `mix verify.stability_contract && mix mailglass.publish.check --package mailglass_inbound` | ✅ |
| REL-02 | Release-note posture accuracy and no-hype wording | docs contract + manual review | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` | ✅ |
| REL-03 | Feature-growth block remains until decision complete | governance/manual | `rg -n "release-position decision|feature-growth" .planning/STATE.md .planning/ROADMAP.md` | ✅ |

### Sampling Rate
- **Per task commit:** `mix verify.stability_contract`
- **Per wave merge:** `mix verify.stability_contract && mix mailglass.publish.check --package mailglass_inbound`
- **Phase gate:** both required commands green with captured output

### Wave 0 Gaps
- [ ] No dedicated automated assertion currently enforces REL-03 planning-state wording; keep manual governance check in plan.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | N/A (release decision phase) |
| V3 Session Management | no | N/A |
| V4 Access Control | yes | GitHub environment/permissions in publish workflows |
| V5 Input Validation | yes | Mix task option parsing + fail-closed checks in publish check task |
| V6 Cryptography | yes | Existing signature verification surfaces remain unchanged; avoid contract drift |

### Known Threat Patterns for Elixir release workflow stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Shipping with stale/contradictory contract docs | Tampering | docs-contract + stability-contract lanes before decision |
| Publishing wrong package/version linkage | Tampering | `mailglass.publish.check` metadata/linked-version checks |
| Unsafe manual publish fallback use | Repudiation | tag-based `workflow_dispatch` contract and documented fallback path |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/66-release-position-decision/66-CONTEXT.md` - locked decisions, scope, evidence expectations
- `.planning/REQUIREMENTS.md` - REL-01/02/03 definitions
- `.planning/STATE.md` - current milestone guardrails and blocked feature-growth posture
- `.planning/ROADMAP.md` - Phase 66 goal/success criteria
- `mix.exs`, `mailglass_inbound/mix.exs` - canonical verification aliases and current version truth
- `lib/mix/tasks/mailglass.publish.check.ex` - publish-check gate semantics
- `.github/workflows/release-please.yml`, `.github/workflows/publish-hex.yml` - release automation topology and fallback
- `.release-please-manifest.json`, `release-please-config.json` - version manifest and package topology
- `mailglass_inbound/docs/api_stability.md`, `guides/compatibility-and-deprecations.md` - canonical contract/compatibility sources
- Local command evidence run on 2026-06-01:
  - `mix hex.info mailglass_inbound 0.3.0`
  - `mix verify.stability_contract`
  - `mix mailglass.publish.check --package mailglass_inbound`
  - `mix --version`, `elixir --version`, `jq --version`, `gh --version`

### Secondary (MEDIUM confidence)
- none

### Tertiary (LOW confidence)
- none

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - directly verified from repository and executed commands
- Architecture: HIGH - locked by CONTEXT decisions and existing workflow topology
- Pitfalls: HIGH - derived from documented contract boundaries and release gates

**Research date:** 2026-06-01  
**Valid until:** 2026-07-01
