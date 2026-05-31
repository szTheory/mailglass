# Phase 61: docs-contract-boundary-enforcement - Research

**Researched:** 2026-05-31  
**Domain:** Elixir docs-contract enforcement for trust-boundary language and canonical contract routing  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Treat `reference/host_app` docs as usage-proof evidence only. They must explicitly avoid framing the reference host as canonical API stability or compatibility contract truth.
- **D-02:** Keep the reference host positioned as a thin maintained trust-proof baseline using public seams only, not as a second product surface or fixture seed.
- **D-03:** Every trust-journey-facing doc surface touched by this phase should route guarantee semantics to canonical stability artifacts: `docs/api_stability.md`, `mailglass_admin/docs/api_stability.md`, `mailglass_inbound/docs/api_stability.md`, and the relevant executable contract checks/tests.
- **D-04:** Prefer the broader enforcement path for trust-entry docs, not only the currently enumerated Tier 1 docs, when those surfaces make trust or contract claims. Likely candidates include `reference/host_app/README.md`, `reference/host_app/SCOPE.md`, `MAINTAINING.md`, `guides/webhooks.md`, `guides/webhook-troubleshooting.md`, and `mailglass_admin/docs/operator-trust.md`.
- **D-05:** Extend existing deterministic docs enforcement rather than adding a parallel mechanism. Primary seams are `mix mailglass.docs.check` (`lib/mix/tasks/mailglass.docs.check.ex`) and docs/contract tests under `test/mailglass/` and `test/reference_host/`.
- **D-06:** Verification must fail on language that implies reference-host internals, provider internals, checkpoint implementation details, or dev-only trust-runner implementation modules are public API guarantees.
- **D-07:** Language about internals reachable during reference/trust flows should route guarantees to stability inventories and semantic seams, not to implementation reachability.
- **D-08:** If internal implementation names must appear in trust docs, allow them only with explicit non-contract framing plus nearby canonical stability links. Do not apply a blanket ban that would make troubleshooting docs less useful.

### the agent's Discretion
- Exact forbidden-token and required-token lists are planner/implementer discretion, provided they are deterministic, scoped to trust-contract drift, and do not over-block legitimate technical troubleshooting language.
- Exact split between Mix-task checks and ExUnit contract tests is planner/implementer discretion, provided `DOCB-03` is enforced in CI-compatible verification.

### Deferred Ideas (OUT OF SCOPE)
- Provider-matrix broadening remains out of scope for v1.3.
- `SEED-003-ecosystem-integrations` promotion remains deferred.
- `gen_smtp` listener or transport-class expansion remains deferred.
- Changing CI trust-lane required-check posture remains out of scope; Phase 60 locked clean-baseline as publish-gate-only.

### Reviewed Todos (not folded)
- `.planning/todos/pending/2026-05-28-add-clean-baseline-trust-lane-after-republish.md` - reviewed as a weak match; not folded because Phase 60 already folded and superseded it.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DOCB-01 | Reference-app docs clearly state they are usage proof artifacts, not API-contract truth. | Add required boundary tokens to `reference/host_app/README.md` + `reference/host_app/SCOPE.md` checks in existing docs checker and ExUnit contract tests. [VERIFIED: codebase grep] |
| DOCB-02 | Reference journey docs link to canonical stability contract documents and tests for guarantee semantics. | Enforce canonical-link tokens to `docs/api_stability.md`, `mailglass_admin/docs/api_stability.md`, `mailglass_inbound/docs/api_stability.md`, and trust-runner contract tests where trust claims appear. [VERIFIED: codebase grep] |
| DOCB-03 | Docs contract verification enforces boundary language so reference internals are not presented as public API. | Extend `Mix.Tasks.Mailglass.Docs.Check` + `test/mailglass/docs_contract_test.exs` and `test/reference_host/*contract_test.exs` with deterministic forbidden/required wording assertions. [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 61 should be implemented as an extension of the existing deterministic docs-contract system, not a new enforcement path. The project already treats docs drift as release-significant via `mix mailglass.docs.check`, `mix verify.stability_contract`, and CI jobs that execute those checks. [VERIFIED: codebase grep]

The trust boundary is already conceptually present: `reference/host_app/README.md` frames confidence as reference-host trust-journey evidence, and core/admin/inbound stability inventories already define canonical contract truth documents. The implementation work for this phase is to convert that posture into stronger deterministic checks at the trust-entry docs surfaces called out in Phase 61 context. [VERIFIED: codebase grep]

**Primary recommendation:** Add deterministic required/forbidden tokens for trust-boundary wording to existing `mailglass.docs.check` and companion ExUnit docs-contract tests, with explicit canonical-link routing and scoped non-contract allowances for troubleshooting/internal naming. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Deterministic docs boundary lint (`mix mailglass.docs.check`) | API / Backend | — | Implemented as Mix task in repo code and executed in CI verification lanes. [VERIFIED: codebase grep] |
| Contract assertions for trust docs | API / Backend | — | ExUnit test suites pin docs tokens and boundary phrases. [VERIFIED: codebase grep] |
| Canonical contract source-of-truth docs | CDN / Static | API / Backend | Markdown files are static artifacts; guarantee semantics come from code-tested contract docs. [VERIFIED: codebase grep] |
| Trust-runner claim-boundary wording | CDN / Static | API / Backend | Wording is documented in `reference/host_app` docs and enforced by reference-host contract tests. [VERIFIED: codebase grep] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | 1.19.5 (local toolchain) | Compile/run Mix task + ExUnit contract tests | Repo-native execution environment for docs enforcement and CI aliases. [VERIFIED: codebase grep] |
| ExUnit (built-in) | bundled with Mix 1.19.5 | Deterministic docs contract tests | Existing docs contracts are already implemented and release-gated through ExUnit. [VERIFIED: codebase grep] |
| Mix task system | Mix 1.19.5 | Deterministic token-based docs checks | Existing enforcement seam is `Mix.Tasks.Mailglass.Docs.Check`. [VERIFIED: codebase grep] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Bash | 5.2.37 | Scripted contract validation shell glue | For checkpoint-contract and support-contract wrappers already in repo scripts. [VERIFIED: codebase grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Extend `mailglass.docs.check` | New standalone lint/test task | Violates D-05 and duplicates enforcement paths, increasing drift risk. [VERIFIED: codebase grep] |

**Installation:**  
No new external packages are required for this phase. [VERIFIED: codebase grep]

## Architecture Patterns

### System Architecture Diagram
```text
Trust/Reference Docs (*.md)
        |
        v
mix mailglass.docs.check (required/forbidden token checks)
        |
        +----> ExUnit docs contract tests (core + reference_host)
        |             |
        v             v
  mix verify.stability_contract ----> CI required/advisory lanes
        |
        v
Merge/Release trust claims allowed only when boundary wording stays compliant
```

### Recommended Project Structure
```text
lib/mix/tasks/
  mailglass.docs.check.ex              # deterministic docs checker (extend here)
test/mailglass/
  docs_contract_test.exs               # core docs contract assertions
test/reference_host/
  trust_runner_command_contract_test.exs
  trust_runner_checkpoint_contract_test.exs
reference/host_app/
  README.md
  SCOPE.md
guides/
  webhooks.md
  webhook-troubleshooting.md
mailglass_admin/docs/
  operator-trust.md
docs/
  api_stability.md
```

### Pattern 1: Deterministic Token Contracts
**What:** Encode boundary policy as explicit required/forbidden tokens per file path in `@tier1_surface_rules`. [VERIFIED: codebase grep]  
**When to use:** For trust-boundary claims where wording drift must fail CI deterministically. [VERIFIED: codebase grep]  
**Example:**
```elixir
# Source: lib/mix/tasks/mailglass.docs.check.ex
@tier1_surface_rules %{
  "README.md" => %{required: [...], forbidden: [...]}
}
```

### Pattern 2: Pair Mix-task policy with ExUnit contract tests
**What:** Keep docs policy in Mix task and pin crucial narrative claims in focused ExUnit docs tests. [VERIFIED: codebase grep]  
**When to use:** For high-risk trust wording where policy needs both breadth (task) and precise guardrails (tests). [VERIFIED: codebase grep]  

### Anti-Patterns to Avoid
- **Parallel docs enforcement mechanism:** Adds split-brain policy and violates locked decision D-05. [VERIFIED: codebase grep]
- **Blanket ban on internal names:** Breaks useful troubleshooting language and violates D-08; require explicit non-contract framing instead. [VERIFIED: codebase grep]
- **Only checking README-level docs:** Misses trust-entry docs drift called out by D-04 (`webhooks`, `operator-trust`, `MAINTAINING`, reference host docs). [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Docs-boundary enforcement | New parser engine or ad hoc reviewer checklist | Existing `mix mailglass.docs.check` + ExUnit contracts | Existing deterministic system already integrated into CI and alias gates. [VERIFIED: codebase grep] |
| Contract guarantee source routing | New “contract index” tooling | Existing `api_stability.md` docs + contract tests links | Canonical inventories already exist and are referenced in docs/test posture. [VERIFIED: codebase grep] |

**Key insight:** This phase is policy-hardening on proven enforcement seams, not infrastructure expansion. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Over-blocking troubleshooting docs
**What goes wrong:** Docs checks fail legitimate references to internal modules used for diagnosis. [VERIFIED: codebase grep]  
**Why it happens:** Forbidden tokens are too broad or lack non-contract exceptions. [VERIFIED: codebase grep]  
**How to avoid:** Add scoped allow-framing tokens (for example “implementation detail” + canonical stability links nearby). [ASSUMED]  
**Warning signs:** Frequent false-positive failures in `guides/webhooks.md` / `operator-trust.md` edits. [ASSUMED]

### Pitfall 2: Partial surface coverage
**What goes wrong:** Boundary language is fixed in one file but drifts in another trust-entry file. [VERIFIED: codebase grep]  
**Why it happens:** Checker scope remains Tier-1 legacy list without Phase-61 trust doc additions. [VERIFIED: codebase grep]  
**How to avoid:** Extend path coverage for reference-host and trust docs identified in D-04. [VERIFIED: codebase grep]  
**Warning signs:** PRs that pass despite wording drift in `reference/host_app/*` trust language. [ASSUMED]

### Pitfall 3: Mix-task/test drift
**What goes wrong:** Mix task and ExUnit enforce different wording contracts. [VERIFIED: codebase grep]  
**Why it happens:** Updates land in only one enforcement seam. [VERIFIED: codebase grep]  
**How to avoid:** Update both checker rules and focused tests in same plan wave. [ASSUMED]  
**Warning signs:** CI passes one lane and fails another for same docs change. [ASSUMED]

## Code Examples

Verified patterns from repository sources:

### Deterministic docs-check gate
```elixir
# Source: lib/mix/tasks/mailglass.docs.check.ex
issues =
  leak_issues(paths)
  |> Kernel.++(tier1_surface_issues())
  |> Kernel.++(preview_boundary_issues())
```

### Stability-contract gate composes docs check
```elixir
# Source: mix.exs alias verify.stability_contract
"verify.stability_contract": [
  "verify.support_contract.core",
  "cmd --cd mailglass_admin mix verify.support_contract.admin",
  "cmd --cd mailglass_inbound mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors",
  "mailglass.docs.check",
  "compile --no-optional-deps --warnings-as-errors"
]
```

### Reference-host claim-boundary pin
```elixir
# Source: test/reference_host/trust_runner_command_contract_test.exs
@claim_boundary "reference-host trust-journey confidence only; signed Postmark webhook verification and no-match operator diagnosis proven by deterministic runner evidence"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual/implicit docs boundary review | Deterministic token contracts in Mix task + ExUnit | Present by 2026-05-31 in current repo state | CI-enforceable docs posture; less subjective review drift. [VERIFIED: codebase grep] |
| Reference host framed only as baseline narrative | Claim-boundary phrase pinned in docs and tests | Present by 2026-05-31 in current repo state | Enables DOCB enforcement expansion without inventing new trust language base. [VERIFIED: codebase grep] |

**Deprecated/outdated:**
- Treating exported/reachable internal modules as implied contract truth is explicitly rejected by canonical stability docs. [VERIFIED: codebase grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Adding explicit “implementation detail” framing token near internal names is the lowest-noise exception strategy. | Common Pitfalls | Could over/under-block until tuned. |
| A2 | CI false positives are likely if token checks expand without staged calibration. | Common Pitfalls | Planner may underestimate stabilization wave. |

## Open Questions

1. **How broad should new trust-doc path coverage be in first cut?**
   - What we know: D-04 explicitly prefers broader trust-entry coverage and names likely docs. [VERIFIED: codebase grep]
   - What's unclear: Whether to include all named candidates immediately or stage in two waves for noise control. [ASSUMED]
   - Recommendation: Wave 1 include all D-04 named files, Wave 2 tune tokens based on first CI pass outcomes. [ASSUMED]

2. **Where should non-contract internal-name allowance be encoded?**
   - What we know: D-08 requires allowance with explicit non-contract framing and canonical links. [VERIFIED: codebase grep]
   - What's unclear: Whether allowance should be in Mix task token list only, ExUnit regex assertions only, or both. [ASSUMED]
   - Recommendation: Encode minimum policy in Mix task and pin exemplar phrasing in ExUnit tests. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `elixir` | Mix-task/docs-test execution | ✓ | 1.19.5 | — |
| `mix` | Verification aliases and task runs | ✓ | 1.19.5 | — |
| `bash` | Script wrappers (`verify_support_contract`, checkpoint checks) | ✓ | 5.2.37 | — |
| `rg` | Fast repo scanning during implementation | ✓ | 15.1.0 | `grep` |

**Missing dependencies with no fallback:** none.  
**Missing dependencies with fallback:** none.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (built into Elixir test stack) [VERIFIED: codebase grep] |
| Config file | `mix.exs` aliases + `test/` suites [VERIFIED: codebase grep] |
| Quick run command | `mix test test/mailglass/docs_contract_test.exs test/reference_host/trust_runner_command_contract_test.exs --warnings-as-errors` [VERIFIED: codebase grep] |
| Full suite command | `mix verify.stability_contract` [VERIFIED: codebase grep] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DOCB-01 | Reference host docs explicitly usage-proof only | unit/contract | `mix test test/reference_host/trust_runner_command_contract_test.exs --warnings-as-errors` | ✅ |
| DOCB-02 | Trust docs route guarantee truth to canonical stability artifacts | unit/contract + lint | `mix test test/mailglass/docs_contract_test.exs --warnings-as-errors && mix mailglass.docs.check` | ✅ |
| DOCB-03 | Boundary wording enforced against internal-as-public claims | lint + contract | `mix mailglass.docs.check && mix test test/mailglass/docs_contract_test.exs test/reference_host/trust_runner_command_contract_test.exs --warnings-as-errors` | ✅ |

### Sampling Rate
- **Per task commit:** `mix mailglass.docs.check`
- **Per wave merge:** `mix test test/mailglass/docs_contract_test.exs test/reference_host/trust_runner_command_contract_test.exs --warnings-as-errors`
- **Phase gate:** `mix verify.stability_contract`

### Wave 0 Gaps
- [ ] Add/extend focused DOCB assertions in `test/reference_host/*` and `test/mailglass/docs_contract_test.exs` for D-04 trust surfaces. [VERIFIED: codebase grep]
- [ ] Extend `@tier1_paths`/surface rules in `lib/mix/tasks/mailglass.docs.check.ex` for reference-host and trust-entry docs. [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | N/A for this docs-enforcement phase scope. [VERIFIED: codebase grep] |
| V3 Session Management | no | N/A for this docs-enforcement phase scope. [VERIFIED: codebase grep] |
| V4 Access Control | no | N/A for this docs-enforcement phase scope. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Deterministic token/regex checks in docs checker and ExUnit assertions. [VERIFIED: codebase grep] |
| V6 Cryptography | no | No cryptographic implementation changes in this phase. [VERIFIED: codebase grep] |

### Known Threat Patterns for Elixir docs-contract enforcement

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Trust-boundary drift in docs | Tampering | Deterministic required/forbidden token checks in `mailglass.docs.check` + CI gating. [VERIFIED: codebase grep] |
| Internal-module guarantee confusion | Spoofing | Explicit non-contract framing and canonical API stability links in trust docs. [VERIFIED: codebase grep] |
| Silent policy bypass via unscanned docs | Repudiation | Extend checker path coverage to D-04 trust-entry docs and pin with tests. [VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)
- `lib/mix/tasks/mailglass.docs.check.ex` - existing deterministic docs checker architecture and rule model. [VERIFIED: codebase grep]
- `test/mailglass/docs_contract_test.exs` - existing docs contract testing patterns and CI-level expectations. [VERIFIED: codebase grep]
- `test/reference_host/trust_runner_command_contract_test.exs` - trust-runner command and claim-boundary pin. [VERIFIED: codebase grep]
- `test/reference_host/trust_runner_checkpoint_contract_test.exs` - claim-boundary/checkpoint contract posture. [VERIFIED: codebase grep]
- `reference/host_app/README.md` and `reference/host_app/SCOPE.md` - current usage-proof and scope boundary language. [VERIFIED: codebase grep]
- `docs/api_stability.md`, `mailglass_admin/docs/api_stability.md`, `mailglass_inbound/docs/api_stability.md` - canonical contract truth docs. [VERIFIED: codebase grep]
- `mix.exs` - verify aliases and docs check integration in release gating. [VERIFIED: codebase grep]
- `.github/workflows/ci.yml` - CI execution of docs checks and trust lane contracts. [VERIFIED: codebase grep]
- `.planning/phases/61-docs-contract-boundary-enforcement/61-CONTEXT.md` - locked decisions D-01..D-08 and scope. [VERIFIED: codebase grep]
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`, `.planning/config.json` - requirement mapping and workflow validation/security toggles. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)
- None.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - existing tools and seams are explicit in repo and CI.
- Architecture: HIGH - deterministic enforcement architecture already implemented.
- Pitfalls: MEDIUM - rooted in existing seams, but token-tuning noise levels require first implementation pass.

**Research date:** 2026-05-31  
**Valid until:** 2026-06-30
