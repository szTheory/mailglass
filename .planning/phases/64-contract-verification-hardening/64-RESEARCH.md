# Phase 64: Contract Verification Hardening - Research

**Researched:** 2026-05-31  
**Domain:** Elixir stability-contract verification (compiled docs + docs drift + Mix alias wiring)  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Add `mailglass_inbound/test/mailglass_inbound/stability_contract_test.exs` as the authoritative compiled-doc proof for `mailglass_inbound`.
- **D-02:** The package-local stability test should assert `@moduledoc since:` for stable runtime modules, stable structured error modules, stable Mix task modules, and adopter-facing testing helper modules.
- **D-03:** The package-local stability test should assert `@doc since:`, macro metadata, and callback metadata for stable public functions, macros, and callbacks that adopters call directly. It must not assert metadata for internal helpers, generated implementation functions, `@doc false` entries, worker modules, provider modules, replay internals, queue names, direct Oban job shapes, or operator UI details.
- **D-04:** Include adopter-facing testing helpers in compiled-doc since checks because they ship from `lib/` and are part of the package API. Keep them in the separate `testing` contract bucket; do not promote them into runtime `stable`.
- **D-05:** Root `test/mailglass/stability_contract_test.exs` should prove wiring only. Root tests should assert that the aggregate stability lane runs the inbound package contract lane, not duplicate the full inbound inventory.
- **D-06:** Use a centralized inbound docs-contract assertion as the Phase 64 lock for stable inbound structured-error `:type` sets. It should cover `MailglassInbound.MIMEError`, `MailglassInbound.SignatureError`, and `MailglassInbound.S3FetchError`.
- **D-07:** The centralized assertion should parse each error module section in `mailglass_inbound/docs/api_stability.md`, extract the `Closed :type set` bullet list, and compare it exactly, in order, to that module's `__types__/0` return value rendered as backticked atom tokens.
- **D-08:** Keep the per-error unit tests that assert each module's exact `__types__/0` list. Those tests own local struct semantics; the centralized docs-contract assertion owns code/docs drift.
- **D-09:** Add an explicit `Closed :type set` list for `MailglassInbound.MIMEError` in `mailglass_inbound/docs/api_stability.md` so MIME receives the same docs lock as Signature and S3.
- **D-10:** Do not generate docs from code or code from docs in this phase. `mailglass_inbound/docs/api_stability.md` remains the canonical contract inventory; executable tests enforce drift.
- **D-11:** Extend package-local inbound docs-contract tests as the primary guard for PROOF-03. Root `mailglass.docs.check` may mirror broad Tier-1 rules, but release-line truth and inbound over-claim detection belong first in `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs`.
- **D-12:** Version and install-pin truth should use structured comparisons against `mailglass_inbound/mix.exs` where possible. At minimum, README and inbound install-guide `{:mailglass_inbound, "~> X.Y"}` pins must match the package current major/minor.
- **D-13:** Stale release-line prose should be guarded in current adoption and release-position docs, especially `README.md`, `docs/inbound-install.md`, `docs/api_stability.md`, and the `CHANGELOG.md` Unreleased section. Released historical changelog sections may mention old versions.
- **D-14:** Semantic over-claim guards should combine exact known-forbidden phrases with scoped regex checks. Stable/adoption docs must fail on public replay API claims, stable worker/queue claims, provider-module extension claims, replay-as-fresh wording, synthetic/operator UI shipped claims, and stale inbound `1.x` stability claims.
- **D-15:** Deferred/internal wording remains allowed when it clearly frames the capability as not promised. Tests should inspect contract sections where possible so phrases such as `public replay API` are allowed in `deferred` but forbidden in `stable` and adoption prose.
- **D-16:** Make `mailglass_inbound` own its support-contract verification through a package-local `verify.support_contract.inbound` alias.
- **D-17:** Root `mix verify.stability_contract` should call `cmd --cd mailglass_inbound mix verify.support_contract.inbound` rather than listing inbound test files directly.
- **D-18:** The inbound support-contract lane should run the docs-contract test, the compiled-doc stability metadata test, and focused closed-set contract proof in one `mix test ... --warnings-as-errors` invocation.
- **D-19:** `mailglass_inbound/mix.exs` should define `cli/0` preferred envs for `verify.support_contract.inbound` and may expose package-local `verify.stability_contract` as a delegate to `verify.support_contract.inbound` for maintainer DX.
- **D-20:** Keep `verify.docs.contract.inbound` docs-only unless a later phase explicitly changes its meaning. The broader support-contract lane should stay distinct.

### the agent's Discretion

- Planner may decide whether closed-set proof lives inside `docs_contract_test.exs` or a focused `closed_contract_sets_test.exs`, as long as the inbound support-contract alias includes it and failures remain diagnostic.
- Planner may decide the exact helper names for compiled-doc assertions by mirroring root/admin style.
- Planner should fix existing stale inbound install/release-line wording discovered during discussion if tests expose it, but only within the Phase 64 proof scope.

### Deferred Ideas (OUT OF SCOPE)

None - discussion stayed within Phase 64 contract-verification scope.

The following remain explicitly out of scope for v1.4 feature work unless a future milestone separately promotes them: matcher expansion beyond recipient/subject/headers, mailbox lifecycle callbacks beyond `process/1`, public replay API, public provider extension API, public worker/queue contract, synthetic inbound development UI, `gen_smtp` listener work, and ecosystem integrations.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROOF-01 | `mix verify.stability_contract` proves inbound contract docs and compiled-doc metadata | Package-local `stability_contract_test.exs` + inbound alias + root alias delegation/wiring assertions |
| PROOF-02 | Inbound closed atom/type sets stay locked to docs | Centralized docs-contract parser for `Closed :type set` + keep local unit tests |
| PROOF-03 | Docs checks block over-claims and stale release-line claims | Extend inbound docs-contract checks for forbidden claims + release/install drift checks |
</phase_requirements>

## Summary

Phase 64 should harden `mailglass_inbound` by making its stability contract executable at the package boundary, then wiring root verification to that boundary instead of duplicating file-level test paths. [VERIFIED: codebase grep]  
Today, root `verify.stability_contract` still calls inbound docs test directly (`cmd --cd mailglass_inbound mix test ...docs_contract_test.exs`), and root stability wiring tests assert that exact string. [VERIFIED: codebase grep]

The strongest reusable pattern is already present: compiled-doc metadata proof helpers in root/core and `mailglass_admin`, plus extensive inbound docs-contract assertions. [VERIFIED: codebase grep]  
The gap is inbound package-local compiled-doc proof and a package-local support alias that aggregates docs-contract + compiled-doc + closed-set checks. [VERIFIED: codebase grep]

**Primary recommendation:** Implement inbound package-owned `verify.support_contract.inbound`, add inbound `stability_contract_test.exs` with `Code.fetch_docs/1` assertions for locked public surfaces, centralize closed-set docs lock checks in inbound docs-contract, and update root verification to delegate to that alias. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Compiled-doc `since` contract proof | API / Backend | — | Elixir compiled docs and tests execute in package test runtime, not UI/runtime client |
| Closed `:type` docs lock | API / Backend | Database / Storage | Assertions compare module contract (`__types__/0`) vs canonical docs inventory |
| Docs over-claim / stale release-line guards | API / Backend | — | ExUnit + regex/text assertions over package docs are backend verification tasks |
| Root aggregate verification wiring | API / Backend | — | Mix alias orchestration is root build/test pipeline concern |

## Project Constraints (from AGENTS.md)

No repository `AGENTS.md` file exists at project root. [VERIFIED: codebase grep]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | 1.19.5 | Compile/test/docs metadata runtime | Existing project runtime; all current verification lanes use Mix/ExUnit [VERIFIED: local env] |
| OTP | 28 | Beam runtime | Current local/runtime baseline for project tooling [VERIFIED: local env] |
| ExUnit (`mix test`) | bundled | Contract proof tests | Existing stability/docs tests are ExUnit-based in root/admin/inbound [VERIFIED: codebase grep] |
| Mix aliases + `cmd --cd` | bundled | Package-local + root aggregate verification lanes | Already used by root/admin verification architecture [VERIFIED: codebase grep] |
| `Code.fetch_docs/1` | bundled | Compiled-doc metadata extraction (`:since`) | Already used in root/admin stability contract tests [VERIFIED: codebase grep] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Regex + file parsing helpers | bundled | Contract section extraction / forbidden-phrase checks | Docs-contract tests and closed-set comparison checks |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Package-local compiled-doc assertions | Rely only on docs prose checks | Misses missing/stale `@moduledoc/@doc since` metadata drift |
| Root direct file invocation for inbound | Root delegates to inbound support alias | Delegation is better ownership boundary and scales with inbound contract lanes |

**Installation:**  
No new packages are required for this phase. [VERIFIED: codebase grep]

## Package Legitimacy Audit

Not applicable: Phase 64 introduces no new external dependencies/packages. [VERIFIED: codebase grep]

## Architecture Patterns

### System Architecture Diagram

```text
Root mix verify.stability_contract
  -> verify.support_contract.core
  -> cmd --cd mailglass_admin mix verify.support_contract.admin
  -> cmd --cd mailglass_inbound mix verify.support_contract.inbound   (new)
       -> mix test --warnings-as-errors
          -> docs_contract_test.exs (plus closed-set section assertions)
          -> stability_contract_test.exs (new compiled-doc metadata proof)
          -> optional focused closed_contract_sets_test.exs (if chosen)
  -> mailglass.docs.check
  -> compile --no-optional-deps --warnings-as-errors
```

### Recommended Project Structure

```text
mailglass_inbound/
├── mix.exs                                   # inbound cli preferred_env + support aliases
├── docs/api_stability.md                     # canonical contract inventory
└── test/mailglass_inbound/
    ├── docs_contract_test.exs                # docs drift + over-claim + closed-set docs lock
    ├── stability_contract_test.exs           # new compiled-doc proof
    └── (optional) closed_contract_sets_test.exs
test/mailglass/
└── stability_contract_test.exs               # root wiring-only assertions
```

### Pattern 1: Package-Owned Support Contract Lane
**What:** Each package owns its own support-contract alias; root aggregates via `cmd --cd`. [VERIFIED: codebase grep]  
**When to use:** Sibling package with independent contract proof responsibilities.  
**Example:** `mailglass_admin` already ships `verify.support_contract.admin` and root delegates to it. [VERIFIED: codebase grep]

### Pattern 2: Compiled-Doc Metadata Proof by `Code.fetch_docs/1`
**What:** Assert module metadata and per-entry metadata (`:function`, `:macro`, `:callback`, `:type`) using helper functions. [VERIFIED: codebase grep]  
**When to use:** Lock `@moduledoc since:` and `@doc since:` claims as executable contract.

### Anti-Patterns to Avoid

- **Root duplicates inbound surface inventory:** causes split ownership and high drift risk.
- **Asserting internal/generated entries in compiled docs:** over-locks internals and blocks maintenance changes.
- **String-only release checks without structured version parsing:** weak against pin drift and false positives.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Contract verification orchestration | Custom shell scripts outside Mix alias graph | Mix aliases + `cmd --cd` | Existing project verification architecture already standardized |
| Docs metadata extraction | Manual parser for BEAM docs chunks | `Code.fetch_docs/1` | Existing root/admin pattern is stable and already proven |

**Key insight:** Reuse existing root/admin contract proof idioms; Phase 64 is hardening-by-alignment, not invention. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Wiring Tests Assert Old Direct Inbound Command
**What goes wrong:** Root stability test expects old `cmd --cd mailglass_inbound mix test ...docs_contract_test.exs` string. [VERIFIED: codebase grep]  
**How to avoid:** Update root wiring assertions in same change as alias rewiring.

### Pitfall 2: Missing `@moduledoc since` on Stable Inbound Modules
**What goes wrong:** Several stable inbound modules currently lack explicit `@moduledoc since`, so new compiled-doc proof will fail immediately. [VERIFIED: codebase grep]  
**How to avoid:** Plan includes either metadata additions or explicit scope selection aligned to locked decisions.

### Pitfall 3: MIME Closed Type Set Not Explicit in Docs
**What goes wrong:** `MIMEError` section lacks `Closed :type set` bullets while Signature/S3 have them. [VERIFIED: codebase grep]  
**How to avoid:** Add MIME closed-set section and central parser assertions.

### Pitfall 4: Over-claim Guards Too Broad or Unscoped
**What goes wrong:** Blocking deferred-context wording by scanning whole file naively.
**How to avoid:** Section-scoped checks (forbid in `stable`/adoption prose, permit in `deferred` explanatory context).

## Code Examples

### Compiled-Doc Entry Metadata Helper Pattern

```elixir
defp docs!(module) do
  assert {:docs_v1, _, :elixir, _, _, metadata, docs} = Code.fetch_docs(module)
  %{metadata: metadata, docs: docs}
end

defp entry_meta!(module, kind, name, arity) do
  %{docs: docs} = docs!(module)
  case Enum.find(docs, fn
         {{^kind, ^name, ^arity}, _, _, _, _} -> true
         _ -> false
       end) do
    {{^kind, ^name, ^arity}, _, _, _, meta} -> meta
    nil -> flunk("missing #{inspect(kind)} #{inspect(module)}.#{name}/#{arity}")
  end
end
```

Source: root/admin stability tests. [VERIFIED: codebase grep]

### Root Alias Delegation Pattern

```elixir
"verify.stability_contract": [
  "verify.support_contract.core",
  "cmd --cd mailglass_admin mix verify.support_contract.admin",
  "cmd --cd mailglass_inbound mix verify.support_contract.inbound"
]
```

Source: existing root/admin pattern + Phase 64 required inbound target. [VERIFIED: codebase grep]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Root directly runs inbound docs test file | Root delegates to package support-contract alias | Phase 64 target | Better ownership, easier lane composition |
| Per-error docs match checks only in individual tests | Central docs-contract closed-set drift assertion | Phase 64 target | Stronger drift detection across all stable error modules |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Stable inbound Mix tasks to assert in compiled-doc test are module-level only (no function-level checks needed) | Architecture Patterns / planning guidance | Could under-assert task API metadata |
| A2 | `MailglassInbound.InboundMessage.Signals` does not need inclusion in stable compiled-doc list for PROOF-01 | Pitfalls / assertion scope | Could miss a stable nested type/module contract if intended public |

## Open Questions (RESOLVED)

1. **Exact stable inbound module list for `@moduledoc since` checks**
   - RESOLVED: The compiled-doc proof scope is the explicit Phase 64 plan split already locked in planning: Plan `64-01` covers the stable runtime seams, Plan `64-02` covers the stable structured-error modules plus stable Mix task modules, and Plan `64-03` covers the adopter-facing testing helpers.
   - RESOLVED: Nested support modules such as `InboundMessage.Signals` remain out of scope unless execution discovers that a plan-owned public surface explicitly requires them. The proof follows the plan-owned module list rather than inferring new stable modules.

2. **Where to place closed-set central assertion**
   - RESOLVED: The default Phase 64 location is `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs`, matching D-06 through D-10 and Plan `64-04`.
   - RESOLVED: A separate focused file is only acceptable if execution shows `docs_contract_test.exs` becomes materially less readable; if that happens, `verify.support_contract.inbound` must still include the focused closed-set proof so the support-contract lane stays complete.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `mix` | All verification commands | ✓ | 1.19.5 | — |
| Erlang/OTP | Beam test runtime | ✓ | 28 | — |
| `node` | ancillary tooling in repo (not core to phase) | ✓ | v22.14.0 | — |
| `npm` | ancillary tooling in repo (not core to phase) | ✓ | 11.1.0 | — |

All required phase dependencies are available. [VERIFIED: local env]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (bundled with Elixir/Mix) |
| Config file | `test/test_helper.exs` (repo convention) |
| Quick run command | `mix test test/mailglass_inbound/stability_contract_test.exs --warnings-as-errors` |
| Full suite command | `mix verify.stability_contract` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROOF-01 | Inbound compiled-doc metadata + root lane proof | unit/integration | `mix verify.stability_contract` | ❌ Wave 0 (`stability_contract_test.exs` inbound) |
| PROOF-02 | Closed type sets locked to docs | unit | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` | ✅ (extend) |
| PROOF-03 | Over-claim + stale release-line guard failures | unit | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` | ✅ (extend) |

### Sampling Rate

- **Per task commit:** `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors`
- **Per wave merge:** `mix verify.stability_contract`
- **Phase gate:** `mix verify.stability_contract` green

### Wave 0 Gaps

- [ ] `mailglass_inbound/test/mailglass_inbound/stability_contract_test.exs` — compiled-doc metadata proof for inbound stable/testing surfaces
- [ ] `mailglass_inbound/mix.exs` alias + `cli/0` updates for `verify.support_contract.inbound`
- [ ] root `mix.exs` alias rewiring + root stability wiring assertion updates

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | N/A (phase is docs/contract verification) |
| V3 Session Management | no | N/A |
| V4 Access Control | yes | Fail-closed contract tests preventing accidental public API expansion |
| V5 Input Validation | yes | Strict docs token/regex assertions in tests |
| V6 Cryptography | no | No crypto changes in phase scope |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Contract over-claim (docs imply unshipped/stable surface) | Tampering | Explicit forbidden-phrase assertions scoped by section |
| Silent drift between code and docs | Repudiation | Centralized docs vs `__types__/0` equality checks + compiled-doc metadata proof |
| Verification bypass via alias drift | Elevation of privilege | Root wiring test + root alias delegates to package-owned lane |

## Sources

### Primary (HIGH confidence)

- `mix.exs`, `mailglass_inbound/mix.exs`, `mailglass_admin/mix.exs` - alias architecture, preferred envs, current wiring. [VERIFIED: codebase grep]
- `test/mailglass/stability_contract_test.exs`, `mailglass_admin/test/mailglass_admin/stability_contract_test.exs` - compiled-doc proof pattern and wiring assertions. [VERIFIED: codebase grep]
- `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` - existing inbound docs-contract guard coverage and extension points. [VERIFIED: codebase grep]
- `mailglass_inbound/docs/api_stability.md` - canonical stable/testing/internal/deferred and closed-set docs truth. [VERIFIED: codebase grep]
- `mailglass_inbound/lib/mailglass_inbound/*.ex` selected stable/testing/error modules - actual public metadata surfaces and missing/available `since`. [VERIFIED: codebase grep]
- Local toolchain commands (`mix --version`, OTP probe) - environment availability. [VERIFIED: local env]

### Secondary (MEDIUM confidence)

- None.

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - entirely derived from repository and local environment.
- Architecture: HIGH - existing root/admin/inbound patterns are explicit in code/tests.
- Pitfalls: HIGH - directly observed from current wiring and doc/test asymmetries.

**Research date:** 2026-05-31  
**Valid until:** 2026-06-30
