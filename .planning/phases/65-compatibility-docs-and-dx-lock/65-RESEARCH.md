# Phase 65: Compatibility, Docs, and DX Lock - Research

**Researched:** 2026-05-31
**Domain:** `mailglass_inbound` compatibility posture, docs-contract drift prevention, and operator/testing DX semantics
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Keep `mailglass_inbound/README.md` as the single canonical inbound
  adoption lane. Other inbound guides should support, deepen, and stay
  consistent with the README rather than becoming competing setup authorities.
- **D-02:** Planning should verify the full adoption path stays coherent across
  dependency pinning, `body_reader` setup, router/provider wiring, async mode,
  operator follow-through, and links to deeper guides.
- **D-03:** Express compatibility rules by routing readers to
  `mailglass_inbound/docs/api_stability.md`: explicitly inventoried stable
  inbound surfaces require a deprecation bridge or major-version change before
  breaking semantics.
- **D-04:** State that internal and deferred surfaces may change without
  deprecation, even when modules are reachable, documented for troubleshooting,
  or mentioned by tests. Reachability is not a compatibility promise.
- **D-05:** Apply the compatibility-contract ergonomics lens during planning:
  produce a small deprecation-DX inventory for any stable surface touched by
  the docs pass, including surface, replacement, warning/migration channel,
  `--warnings-as-errors` impact, support horizon, and proof artifact.
- **D-06:** Lock operator docs at command semantics for
  `mix mailglass.inbound.doctor`, `mix mailglass.inbound.replay`, and
  `mix mailglass.inbound.prune`: documented flags/options, exit semantics,
  tenant guards, confirmation tiers, destructive confirmations, prune behavior,
  and replay-over-stored-truth semantics.
- **D-07:** Keep orchestration modules, internal replay/prune/doctor helpers,
  worker modules, queue names, retry tuning, direct Oban job shapes, admin UI
  implementation details, DOM shape, components, assigns, routes, and CSS
  explicitly non-contractual.
- **D-08:** Admin/operator trust wording must not imply replay as fresh receipt,
  silent reroute, public replay API, stable UI contract, or stable
  DOM/component APIs.
- **D-09:** Center testing docs on `MailglassInbound.MailboxCase` and
  `MailglassInbound.Test.Ingress` as the default adopter harness.
- **D-10:** Make process-local capture semantics and `async: false` setup
  consequences explicit enough that adopters do not misread assertion behavior
  or sandbox boundaries.
- **D-11:** Treat the one-assertion-per-drive rule as a hard testing-DX contract:
  each assertion consumes one capture, so examples should drive a new inbound
  message for each assertion instead of stacking multiple consuming assertions
  on one capture.

### the agent's Discretion
- Planner may decide whether compatibility/deprecation wording lives in
  existing compatibility docs, inbound README sections, package-local docs, or
  all of the above, as long as there is one canonical story and drift checks
  guard the resulting contract.
- Planner may decide exact docs-contract assertion names and phrase matching,
  but checks should protect adoption consistency, compatibility posture,
  operator trust boundaries, and testing-DX rules without overfitting ordinary
  prose.

### Deferred Ideas (OUT OF SCOPE)
None - analysis stayed within Phase 65 scope.

The following remain explicitly out of scope for v1.4 feature work unless a
future milestone separately promotes them: matcher expansion beyond
recipient/subject/headers, mailbox lifecycle callbacks beyond `process/1`,
public replay API, public provider extension API, public worker/queue contract,
synthetic inbound development UI, `gen_smtp` listener work, ecosystem
integrations, and admin DOM/component guarantees.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DX-01 | Adopter can follow one canonical install/adoption path without contradictory docs. | Canonical-path ownership, required-token checks in docs-contract tests, and Tier-1 docs checks map directly to this behavior. [VERIFIED: codebase grep] |
| DX-02 | Operator can understand doctor/replay/prune commands, exit semantics, tenant guards, and destructive confirmations. | Mix task docs and task modules already encode this command-level contract and can be locked with phrase checks. [VERIFIED: codebase grep] |
| DX-03 | Testing docs clearly explain process-local assertions and one-assertion-per-drive behavior. | `MailboxCase`, `Test.Ingress`, and `TestAssertions` docs/code explicitly define consuming assertions and process-local semantics. [VERIFIED: codebase grep] |
| DX-04 | Admin/operator trust wording does not confuse replay, reroute, fresh receipt, or UI guarantees. | Admin operator-trust doc and inbound docs-contract tests already enforce anti-overclaim boundaries. [VERIFIED: codebase grep] |
</phase_requirements>

## Summary

Phase 65 is a documentation-contract hardening phase, not a runtime feature phase. The existing codebase already contains the key operator/task/testing semantics; planning should focus on aligning and locking language across README/install/operator/testing/admin-trust docs and strengthening drift checks where wording can regress. [VERIFIED: codebase grep]

The current repo already has two enforcement seams: package-local inbound docs checks (`mailglass_inbound/test/.../docs_contract_test.exs`) and root Tier-1 docs checks (`mix mailglass.docs.check`). The safest plan is to extend these seams rather than creating new bespoke verification flows. [VERIFIED: codebase grep]

**Primary recommendation:** Treat this phase as “single-story + executable wording guardrails”: update docs first, then codify exact required/forbidden wording in existing docs-contract and Tier-1 checks. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Canonical adoption path coherence across README + guides | Package docs (`mailglass_inbound/docs` + README) | Root Tier-1 docs check task | Source-of-truth is docs content; enforcement belongs in existing docs-check automation. [VERIFIED: codebase grep] |
| Compatibility/deprecation posture for stable vs internal/deferred | `mailglass_inbound/docs/api_stability.md` | `guides/compatibility-and-deprecations.md`, `docs/compatibility-and-deprecations.md` | Stable-surface taxonomy is already canonical in inbound `api_stability.md`; compatibility docs should point to it. [VERIFIED: codebase grep] |
| Operator trust semantics for doctor/replay/prune | Inbound operator docs + mix task docs | Mix task modules as semantic source | Command behavior is user-facing at CLI level; implementation modules remain internal. [VERIFIED: codebase grep] |
| Testing DX clarity (`MailboxCase`, `Test.Ingress`, assertion consumption) | Inbound testing docs + helper moduledocs | Docs-contract tests | User trust comes from examples and explicit warning text, then locked by tests. [VERIFIED: codebase grep] |
| Anti-overclaim admin/operator trust boundaries | `mailglass_admin/docs/operator-trust.md` | Inbound docs-contract + root docs check | Admin trust wording must stay aligned with inbound replay semantics and UI non-contract boundaries. [VERIFIED: codebase grep] |

## Standard Stack

### Core
| Library/Tool | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir | 1.19.5 | Compile and run docs/tests/mix tasks for this phase. | Project runtime/toolchain for all checks in this phase. [VERIFIED: codebase grep] |
| Mix | 1.19.5 | Execute docs-contract and stability verification commands. | Existing verification aliases and tasks are Mix-native. [VERIFIED: codebase grep] |
| ExUnit | bundled with Elixir OTP app | Docs-contract and stability assertions. | Existing enforcement is written as ExUnit tests. [VERIFIED: codebase grep] |

### Supporting
| Library/Tool | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `mix mailglass.docs.check` task | in-repo task | Tier-1 docs drift and trust-boundary checks. | Run after docs edits that touch README/guides/admin docs. [VERIFIED: codebase grep] |
| `mix verify.stability_contract` alias | in-repo alias | Canonical cross-package contract verification lane. | Run at phase gate and before merge. [VERIFIED: codebase grep] |
| `mailglass_inbound` docs-contract tests | in-repo test file | Inbound docs wording and contract parity checks. | Run on any inbound README/docs wording changes. [VERIFIED: codebase grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Extending existing docs-contract tests | New custom linter/task for Phase 65 only | Adds duplicate enforcement surface and increases drift risk. [VERIFIED: codebase grep] |
| Root-only wording checks | Package-local only checks | Misses cross-doc coherence at project Tier-1 docs layer. [VERIFIED: codebase grep] |

## Architecture Patterns

### System Architecture Diagram

```text
Docs edits (README/install/operator/testing/admin trust)
  -> inbound docs-contract tests assert required/forbidden claims
  -> root mailglass.docs.check validates Tier-1 phrase boundaries
  -> mix verify.stability_contract aggregates contract lanes
  -> planning/CI gate accepts only coherent adoption+compatibility story
```

### Recommended Project Structure
```text
mailglass_inbound/
  README.md
  docs/
    api_stability.md
    inbound-install.md
    inbound-operator.md
    inbound-testing.md
  test/mailglass_inbound/docs_contract_test.exs
mailglass_admin/docs/operator-trust.md
lib/mix/tasks/mailglass.docs.check.ex
guides/compatibility-and-deprecations.md
docs/compatibility-and-deprecations.md
```

### Pattern 1: Canonical-Path-First Docs
**What:** Keep one adoption path in inbound README; deeper guides elaborate without contradicting setup semantics. [VERIFIED: codebase grep]  
**When to use:** Any time inbound setup, dependency pins, provider wiring, or async mode text changes. [VERIFIED: codebase grep]

### Pattern 2: Semantics-First Compatibility Framing
**What:** State compatibility at stable semantic surfaces only; internal/deferred names are explicitly non-contract. [VERIFIED: codebase grep]  
**When to use:** Any compatibility/deprecation language across docs. [VERIFIED: codebase grep]

### Pattern 3: Command-Semantics-Only Operator Contract
**What:** Promise CLI behavior (flags, exits, confirmations, tenant guards), not internal module/job/queue details. [VERIFIED: codebase grep]  
**When to use:** Operator docs and trust docs updates. [VERIFIED: codebase grep]

### Anti-Patterns to Avoid
- **Competing setup authorities:** Multiple “primary” install paths that diverge on pins/body_reader/router/async behavior. [VERIFIED: codebase grep]
- **Reachability-as-stability wording:** Claiming visibility/exported modules imply compatibility guarantees. [VERIFIED: codebase grep]
- **Replay-overclaim language:** Any phrase that implies replay is fresh receive, silent reroute, or public replay API. [VERIFIED: codebase grep]
- **UI-contract leakage:** Implying DOM/component/LiveView shapes are stable operator API. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Docs drift detection | New standalone custom checker for this phase | Existing inbound docs-contract tests + `mix mailglass.docs.check` | Existing seams already encode contract posture and are wired into verification lanes. [VERIFIED: codebase grep] |
| Operator semantic truth source | Narrative-only prose detached from command modules | Current mix task docs + task moduledocs + docs assertions | Keeps docs aligned with executable command behavior. [VERIFIED: codebase grep] |
| Testing semantics guidance | New test harness abstraction | Existing `MailboxCase`, `Test.Ingress`, `TestAssertions` | Helpers already define process-local consuming assertion model. [VERIFIED: codebase grep] |

**Key insight:** This phase is mostly about contract language convergence and executable wording checks, not new runtime abstractions. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: “One Assertion, Many Claims” Test Examples
**What goes wrong:** Examples assert multiple consuming assertions on a single inbound drive and become flaky/misleading. [VERIFIED: codebase grep]  
**Why it happens:** `assert_inbound_*` uses `assert_received` on process mailbox, which consumes captures. [VERIFIED: codebase grep]  
**How to avoid:** Enforce “one assertion per drive” in docs and examples. [VERIFIED: codebase grep]  
**Warning signs:** Example attempts second assertion without second `Test.Ingress` drive. [VERIFIED: codebase grep]

### Pitfall 2: Operator Overclaim Drift
**What goes wrong:** Docs promise replay/public reroute/UI contracts beyond current stable posture. [VERIFIED: codebase grep]  
**Why it happens:** Replay/control-plane internals are reachable, tempting shorthand in docs. [VERIFIED: codebase grep]  
**How to avoid:** Keep replay framed as stored-truth recovery and UI internals explicitly non-contractual. [VERIFIED: codebase grep]  
**Warning signs:** Phrases like “fresh receive,” “silent reroute,” “public replay API,” “stable DOM”. [VERIFIED: codebase grep]

### Pitfall 3: Canonical Path Fragmentation
**What goes wrong:** Install/provider/operator guides drift from README path and conflict. [VERIFIED: codebase grep]  
**Why it happens:** Deep guides are edited independently without cross-doc required-token checks. [VERIFIED: codebase grep]  
**How to avoid:** Add/maintain required phrase checks and parity checks in docs-contract suite. [VERIFIED: codebase grep]  
**Warning signs:** Different dependency pins, different async guidance, missing body_reader requirements. [VERIFIED: codebase grep]

## Code Examples

### Existing Verification Lanes
```bash
# package-local inbound docs contract
cd mailglass_inbound
mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors

# root contract lane
cd ..
mix mailglass.docs.check
mix verify.stability_contract
```
Source: `mailglass_inbound/mix.exs`, `mix.exs`, `lib/mix/tasks/mailglass.docs.check.ex` [VERIFIED: codebase grep]

### Inbound Testing Contract Usage
```elixir
use MailglassInbound.MailboxCase, async: false
{:ok, _} = Test.Ingress.receive_inbound(message, router: MyApp.MailglassInboundRouter)
assert_inbound_received(subject: "Welcome")
```
Source: `mailglass_inbound/README.md`, `mailglass_inbound/docs/inbound-install.md`, `mailglass_inbound/lib/mailglass_inbound/test_assertions.ex` [VERIFIED: codebase grep]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Docs as narrative-only trust statement | Docs plus executable contract checks (`docs_contract_test` + `mailglass.docs.check` + `verify.stability_contract`) | Established by completed Phases 63-64 before Phase 65 planning | Enables fail-closed drift detection for wording/compatibility posture. [VERIFIED: codebase grep] |
| Implicit stability via visibility/reachability | Explicit stable/testing/internal/deferred inventory in inbound `api_stability.md` | Phase 63 completion (2026-05-31) | Prevents accidental contract expansion from internal names. [VERIFIED: codebase grep] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `docs/compatibility-and-deprecations.md` is present in active docs topology for this phase, not only `guides/compatibility-and-deprecations.md`. [ASSUMED] | Architecture Patterns | Planner may schedule edits/checks against a file not used in final docs flow. |

## Open Questions

1. **Which compatibility file is canonical for Phase 65 wording edits (`guides/...` vs `docs/...`)?**
   - What we know: Root docs checks include compatibility phrasing requirements and both compatibility paths are referenced in context material. [VERIFIED: codebase grep]
   - What's unclear: Whether planner should edit one file, both files, or one with strict redirect language.
   - Recommendation: Decide in Plan wave 0 and add explicit parity check if both remain active.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Mix tasks/tests for docs contract verification | ✓ | 1.19.5 | — |
| Mix | `mailglass.docs.check` and verification aliases | ✓ | 1.19.5 | — |
| ripgrep (`rg`) | Fast doc-scope phrase audits during implementation | ✓ | 15.1.0 | `grep` |

**Missing dependencies with no fallback:**
- None. [VERIFIED: local command output]

**Missing dependencies with fallback:**
- None. [VERIFIED: local command output]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (bundled with Elixir) [VERIFIED: codebase grep] |
| Config file | `mailglass_inbound/test/test_helper.exs` and root ExUnit setup via mix aliases [VERIFIED: codebase grep] |
| Quick run command | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` [VERIFIED: codebase grep] |
| Full suite command | `mix verify.stability_contract` [VERIFIED: codebase grep] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DX-01 | Canonical adoption path remains coherent and non-contradictory | contract/docs | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` | ✅ |
| DX-02 | Doctor/replay/prune semantics and guardrails are accurately described | contract/docs | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` | ✅ |
| DX-03 | Testing docs preserve process-local + one-assertion-per-drive semantics | contract/docs | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors` | ✅ |
| DX-04 | Admin trust docs avoid replay/UI overclaims | contract/docs + tier1 | `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors && cd .. && mix mailglass.docs.check` | ✅ |

### Sampling Rate
- **Per task commit:** `cd mailglass_inbound && mix test test/mailglass_inbound/docs_contract_test.exs --warnings-as-errors`
- **Per wave merge:** `mix mailglass.docs.check`
- **Phase gate:** `mix verify.stability_contract`

### Wave 0 Gaps
- [ ] Add explicit deprecation-bridge inventory assertion coverage for any newly touched stable surfaces (per D-05), if currently absent.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Operator docs must keep provider verification and operator-auth boundaries accurate, without overclaiming new auth surfaces. [VERIFIED: codebase grep] |
| V3 Session Management | yes | Admin trust docs already define operator session contract keys and scope; keep wording aligned. [VERIFIED: codebase grep] |
| V4 Access Control | yes | Replay/prune tenant guards and destructive confirmation semantics remain explicit. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | CLI flag and confirmation semantics must stay precise to avoid unsafe operator assumptions. [VERIFIED: codebase grep] |
| V6 Cryptography | yes | Signature verification framing (Mailgun/SES/Postmark contexts) must remain semantics-first and non-overclaimed. [VERIFIED: codebase grep] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Docs-induced privilege misuse (operator follows inaccurate replay/prune semantics) | Elevation of Privilege | Keep tenant guard, confirmation, and replay semantics explicit and test-locked. [VERIFIED: codebase grep] |
| Unsafe destructive operations from ambiguous prune wording | Tampering | Typed confirmations/`--yes` semantics clearly documented and tested. [VERIFIED: codebase grep] |
| Trust-boundary confusion (fresh receive vs replay) | Spoofing | Enforce “replay over stored truth, not fresh receive” wording in docs checks. [VERIFIED: codebase grep] |
| UI contract overclaim causing unsafe downstream dependencies | Repudiation | Explicitly document DOM/components as internal; avoid public UI guarantees. [VERIFIED: codebase grep] |

## Project Constraints (from AGENTS.md)

`AGENTS.md` not found in repository root; no additional project-specific directives were discovered from this file. [VERIFIED: filesystem check]

## Sources

### Primary (HIGH confidence)
- Repository source/docs/tests inspected directly via shell tools (`cat`, `rg`):  
  - `.planning/phases/65-compatibility-docs-and-dx-lock/65-CONTEXT.md`
  - `.planning/REQUIREMENTS.md`
  - `.planning/STATE.md`
  - `.planning/ROADMAP.md`
  - `mailglass_inbound/README.md`
  - `mailglass_inbound/docs/api_stability.md`
  - `mailglass_inbound/docs/inbound-install.md`
  - `mailglass_inbound/docs/inbound-operator.md`
  - `mailglass_inbound/docs/inbound-testing.md`
  - `mailglass_admin/docs/operator-trust.md`
  - `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs`
  - `lib/mix/tasks/mailglass.docs.check.ex`
  - `mailglass_inbound/lib/mix/tasks/mailglass.inbound.{doctor,replay,prune}.ex`
  - `mailglass_inbound/lib/mailglass_inbound/{mailbox_case.ex,test/ingress.ex,test_assertions.ex}`

### Secondary (MEDIUM confidence)
- None.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - directly verified from local runtime/tool versions and project mix files.
- Architecture: HIGH - based on existing docs/test/task topology already in repo.
- Pitfalls: HIGH - reflected in current docs-contract assertions and helper semantics.

**Research date:** 2026-05-31
**Valid until:** 2026-06-30
