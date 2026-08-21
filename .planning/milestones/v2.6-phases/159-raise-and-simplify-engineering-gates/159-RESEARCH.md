# Phase 159: Raise and Simplify Engineering Gates - Research

**Researched:** 2026-08-17
**Domain:** Elixir/Mix quality gates, GitHub Actions merge policy, and multi-package validation
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- Autonomously raise the engineering bar significantly.
- Protected merge proof must be deterministic and fail closed.
- Do not perform CI churn or a topology rewrite for its own sake; make the smallest coherent changes that make the protected signal honest.
- Browser, demo, preview, and admin-visual evidence stays advisory and must be visibly unable to masquerade as merge proof.
- Do not change admin/operator UI behavior.
- Keep core, admin, and inbound independently released packages.
- Optimize for one-maintainer simplicity: centralize repeated setup and policy rules only when it preserves required check identity and makes the contract easier to audit.

### the agent's Discretion

- Choose the exact protected-lane inventory, provided it covers every QUAL-03 required behavior and remains explicitly tested.
- Choose the smallest reusable CI setup mechanism and policy-manifest format that preserve sibling package isolation.
- Establish coverage floors only after measuring the canonical suites on the pinned CI toolchain.
- Define expiry formats, owners, and deterministic acknowledgement mechanisms for skips, flakes, and asynchronous tests.
- Sequence quality debt cleanup and gate promotion to keep each plan slice independently verifiable.

### Deferred Ideas (OUT OF SCOPE)

- Product features, public API changes, provider expansion, data migrations, and release publication.
- Admin/operator UI behavior, browser UX, preview visuals, or design-system work.
- Promoting browser/demo/preview/provider-live/next-toolchain/clean-baseline/publish-only evidence into merge requirements.
- Recombining sibling packages, introducing a monorepo build system, or wholesale CI topology redesign.
- Optimizing CI duration beyond repeated unsafe setup and cache/key duplication necessary for correctness.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Research support |
|---|---|
| QUAL-01 | Root formatter scope contract and one mechanical formatted baseline. |
| QUAL-03 | Tested required-lane manifest and fail-closed CI Green promotion. |
| QUAL-04 | Separate advisory inventory with negative aggregate assertions. |
| QUAL-05 | Locked package setup and package/toolchain/environment cache isolation. |
| QUAL-06 | Measurement-first core/inbound coverage floors plus critical-path contracts. |
| QUAL-07 | Inbound Dialyzer, no ignored shipped warnings, no increased ignores. |
| QUAL-08 | Expiring function/file/check complexity-exception ledger. |
| QUAL-09 | Bidirectional skip/flaky/sleep registry and deterministic async acknowledgement. |
| QUAL-10 | Local composite setup and versioned/tested release policy. |
| QUAL-11 | Dependabot, Docker, timeout, and least-privilege workflow policy checks. |
</phase_requirements>

## Summary

The correct Phase 159 shape is a policy-and-proof ratchet, not a CI topology rewrite. `CI Green` currently accepts only eight explicit leaf results, while QUAL-03 requires more behavior than those leaves cover. The policy script itself already fails closed for malformed, missing, duplicate, or failing results, so retain it as the evaluator and give it a complete, tested required-lane inventory. [VERIFIED: `.github/workflows/ci.yml`, `scripts/ci_green_policy.sh`]

Repair baseline quality commands before making them required. Root `mix ci` currently stops in Credo and inbound `mix ci` stops at formatting; root formatter inputs do not include inbound. Core has ExCoveralls configured but no enforced coverage floor; inbound has neither coverage configuration nor Dialyzer configuration. [VERIFIED: Phase 158 verification] [VERIFIED: `mix.exs`, `mailglass_inbound/mix.exs`, formatter files]

**Primary recommendation:** Build and test the required/advisory policy harness first; normalize formatting and package-scoped locked setup; replace unaccountable nondeterminism; measure coverage on the pinned toolchain; ratchet static-analysis exceptions; then promote the complete required set into CI Green.

## Architectural Responsibility Map

| Capability | Primary tier | Secondary tier | Rationale |
|---|---|---|---|
| Merge verdict | CI policy script | GitHub Actions | Versioned repository logic must decide required results; YAML executes it. [VERIFIED: `scripts/ci_green_policy.sh`] |
| Dependency/cache/toolchain setup | Local composite action | package lockfiles | Setup is repeated plumbing but must remain package-scoped. [VERIFIED: Phase 159 audit] |
| Formatting/tests/coverage/static analysis | Mix aliases and test scripts | CI jobs | Local commands remain reproducible and CI promotes their result. [VERIFIED: mixfiles] |
| Exceptions | Registry + validator | ExUnit/Credo/Dialyzer | Exceptions must be source-controlled and fail when expired. [VERIFIED: requirements] |
| Browser/demo/preview/admin-visual | Advisory workflows | CI policy | Visible evidence, never protected merge proof. [VERIFIED: ROADMAP.md] |

## Exact Baseline

| Finding | Evidence | Consequence |
|---|---|---|
| Root formatter excludes inbound; inbound has a separate formatter. | [VERIFIED: `.formatter.exs`, `mailglass_inbound/.formatter.exs`] | Expand root scope, format once, and test the scope contract. |
| CI Green receives eight leaf results only. | [VERIFIED: `.github/workflows/ci.yml`] | Required manifest must enumerate all QUAL-03 proof and reject advisory names. |
| 47 `mix deps.get` calls omit `--check-locked`; 29 cache keys hash `**/mix.lock`. | [VERIFIED: Phase 159 audit] | Composite setup needs explicit package, lockfile, environment, and build inputs. |
| Core coverage is configured but unenforced; inbound has no coverage tool/floor. | [VERIFIED: mixfiles] | Measure first on the pinned CI toolchain; do not invent percentages. |
| Core has 15 Dialyzer ignores (9 in shipped `lib`); inbound has no Dialyxir config, ignore file, or job. | [VERIFIED: Phase 159 audit] | Add inbound analysis and no-growth validation; minimize shipped-code ignores. |
| Credo disables 13 checks globally, including Nesting and Cyclomatic Complexity. | [VERIFIED: `.credo.exs`, Phase 159 audit] | Replace blanket disables with a machine-readable check/file/function/score/owner/expiry ledger. |
| Static scan found about 12 skip/flaky declarations and 17 sleep sites; existing `SuiteFloor` is test-count-only (1576/1575) and inbound has no equivalent. | [VERIFIED: Phase 159 audit, `test/support/suite_floor.ex`] | Use bidirectional registry validation; replace readiness waits with acknowledgements, while allowing clock/TTL/liveness exceptions. |
| 42/50 jobs lack explicit timeout; workflows have broad `issues: write`; Postgres images are mutable tags. | [VERIFIED: Phase 159 audit] | Enforce timeout, least privilege, and Docker-input policy mechanically. |
| Dependabot covers three Mix directories and actions, not Docker; Docker OTP patch differs from `.tool-versions`. | [VERIFIED: `.github/dependabot.yml`, `.tool-versions`, `dev/toolchain/Dockerfile`] | Add Docker coverage and make toolchain parity claim/check exact or intentionally scoped. |
| Root CI Credo and inbound formatting currently fail. | [VERIFIED: Phase 158 verification] | Baseline repair must precede protected promotion. |

## Standard Stack

| Tool | Current state | Use in Phase 159 |
|---|---|---|
| Mix/ExUnit | Native root/inbound validation surface. [VERIFIED: mixfiles] | Keep aliases local-reproducible; CI invokes their exact commands. |
| ExCoveralls | Core `~> 0.18`; inbound absent. [VERIFIED: `mix.exs`, inbound mixfile] | Measure then enforce non-decreasing floors in both packages. |
| Credo | Root `~> 1.7` plus custom checks. [VERIFIED: `mix.exs`, `.credo.exs`] | Repair baseline and turn global complexity disables into expiring ledger entries. |
| Dialyxir | Root `~> 1.4`; inbound absent. [VERIFIED: mixfiles] | Add inbound configuration/job and ratchet root/inbound ignores. |
| Local GitHub composite action | No new package needed. [ASSUMED] | Centralize safe Beam/cache/dependency setup without renaming jobs. |

**Installation:** No external package installation is recommended. [VERIFIED: user constraints]

## Package Legitimacy Audit

No packages are introduced; package legitimacy verification is not applicable. [VERIFIED: research scope]

## Architecture Patterns

### System Architecture Diagram

```text
changed PR --> change classifier --> required-lane manifest --> named required jobs
                                  \-> advisory inventory -----> advisory jobs
named required results ----------------------------------------> CI Green policy --> protected verdict
```

### Pattern 1: Tested policy-as-data

Use one versioned required/advisory inventory and mutation tests that fail for an omitted required lane, duplicate result, advisory lane in the aggregate, permissive `continue-on-error`, or changed check identity. The existing evaluator already rejects malformed/missing/duplicate/failing results. [VERIFIED: `scripts/ci_green_policy.sh`, Phase 158 architecture-guard pattern]

### Pattern 2: Package-scoped locked setup

A local composite action takes package directory, exact lockfile, Mix environment, and build path explicitly; it runs `mix deps.get --check-locked` and derives cache keys from those values rather than `hashFiles('**/mix.lock')`. [VERIFIED: QUAL-05, Phase 159 audit] [ASSUMED]

### Pattern 3: Measure, then ratchet

Record coverage only from the pinned CI toolchain and canonical deterministic commands. Commit that measured floor, reject regression, and lower exception counts only through explicit expiring ledger changes. [VERIFIED: user decision, requirements] [ASSUMED]

### Pattern 4: Bidirectional exception registry

Registry entries must name every skip/flaky/sleep exception and every source declaration must map back to a record. Validate owner, reason, expiry, and allowed category; expire dates fail CI. [VERIFIED: QUAL-09] [ASSUMED]

### Anti-Patterns to Avoid

- **Promote all existing jobs:** violates the locked advisory boundary. [VERIFIED: requirements]
- **One generic monorepo runner:** hides independently released package boundaries and is a topology rewrite. [VERIFIED: user constraints]
- **Global Credo disables:** permit new complexity debt indefinitely. [VERIFIED: `.credo.exs`]
- **Timing sleeps for async completion:** use message/task/monitor/telemetry acknowledgement, except documented TTL/clock/liveness waits. [VERIFIED: Phase 159 audit] [ASSUMED]
- **Fabricated coverage thresholds:** no number is valid until the pinned toolchain measures it. [VERIFIED: user decision]

## Don't Hand-Roll

| Problem | Use instead | Why |
|---|---|---|
| Aggregate verdict | Existing `scripts/ci_green_policy.sh` | Explicit inputs already fail closed. [VERIFIED: script] |
| Test runner | Mix aliases and ExUnit | Existing environment/compile conventions live there. [VERIFIED: mixfiles] |
| Cache backend | `actions/cache` in local composite setup | Centralize key construction, not a new cache system. [VERIFIED: workflows] |
| Async completion | OTP messages, monitors, task results, telemetry, or mailbox assertions | Observes completion rather than guessing elapsed time. [ASSUMED] |

## Common Pitfalls

### Protected promotion before baseline repair

Current root Credo and inbound formatter failures would make a newly required lane permanently red. Repair and verify the commands before they enter the required manifest. [VERIFIED: Phase 158 verification]

### Cache abstraction that loses package identity

Cross-package/global-lock keys make a green job evidence about the wrong dependency graph. Require explicit action inputs and mutation-test cache-key composition. [VERIFIED: Phase 159 audit]

### Prose-only exception tracking

Comments are not executable expiration. The validator must fail missing or expired records and detect both unregistered declarations and stale registry records. [VERIFIED: QUAL-08, QUAL-09]

## Code Examples

```yaml
# Planned adaptation of existing actions/cache keys
key: mix-${{ runner.os }}-${{ inputs.package }}-${{ hashFiles('.tool-versions') }}-${{ inputs.mix_env }}-${{ hashFiles(inputs.lockfile) }}
```

Package and lockfile must be explicit; never use `hashFiles('**/mix.lock')`. [VERIFIED: Phase 159 audit]

```elixir
# Planned exception-record shape
%{source: "test/example_test.exs:42", kind: :skip, owner: "maintainer", reason: "upstream issue", expires_on: ~D[2026-09-01]}
```

Validator rejects absent metadata, expired records, unknown sources, and declarations absent from the registry. [ASSUMED]

## State of the Art

| Old approach | Current approach | Impact |
|---|---|---|
| Selected CI Green leaves embedded in YAML. | Tested required/advisory policy inventory. | Protected proof is complete and auditable. [VERIFIED: CI workflow, requirements] |
| Separate root/inbound formatting reach. | One root formatter baseline. | Root validation cannot miss inbound drift. [VERIFIED: formatter files] |
| Global complexity disables. | Bounded expiring exception ledger. | No unreviewed new exceptions. [VERIFIED: `.credo.exs`, requirements] |

## Assumptions Log

| # | Claim | Risk if wrong |
|---|---|---|
| A1 | A local composite action preserves named check identity. | Use a narrow shared shell script instead. |
| A2 | Acknowledgements can replace targeted readiness sleeps. | Add a minimal test seam per affected subsystem. |
| A3 | Every current exception can be represented in one registry. | Add documented category-specific schema without weakening validation. |

## Open Questions

1. **Coverage floors:** Measure exact root/inbound floors on pinned CI before implementation; no threshold is locked now. [VERIFIED: user decision]
2. **SES config Credo warning:** Preserve behavior with a focused test, then choose either a narrow custom-check allowance or validated-config routing; do not suppress. [VERIFIED: Phase 158 verification]
3. **Complexity ledger baseline:** Inventory exact current check/file/function/score values before setting expiry dates. [VERIFIED: `.credo.exs`]

## Environment Availability

| Dependency | Available | Note |
|---|---|---|
| Elixir/Mix | ✓ | `.tool-versions` pins Elixir 1.18.4 and OTP 27.3.4.13. [VERIFIED: `.tool-versions`] |
| PostgreSQL | Not probed | This research did not run DB/full suites by instruction. [VERIFIED: task constraint] |
| GitHub Actions | Repository-configured | Local contract tests validate policy before remote execution. [VERIFIED: workflow files] |

## Validation Architecture

| Requirement | Test / command target | Wave 0 state |
|---|---|---|
| QUAL-01 | Root formatter scope mutation test + `mix format --check-formatted` | Missing |
| QUAL-03/04 | CI Green manifest/evaluator mutation tests | Missing |
| QUAL-05/10/11 | Composite/cache/toolchain/workflow-policy contract tests | Missing |
| QUAL-06 | Pinned-toolchain coverage measurement + critical-path commands | Missing |
| QUAL-07/08 | Inbound Dialyzer, Credo, exception-ledger validation | Missing |
| QUAL-09 | Bidirectional skip/flaky/sleep registry validator and focused async tests | Missing |

## Security Domain

| ASVS category | Applies | Control |
|---|---|---|
| V4 Access Control | Yes | Default read-only workflow permission; scoped write permissions only for mutation jobs. [VERIFIED: QUAL-11] |
| V5 Input Validation | Yes | Policy validators reject malformed, missing, duplicate, stale, and expired records. [VERIFIED: existing CI policy, requirements] |

| Threat | Mitigation |
|---|---|
| Skipped/bypassed required check | Explicit aggregate inputs and mutation-tested fail-closed evaluator. [VERIFIED: existing policy] |
| Cross-package/unlocked cache | Locked package-scoped setup/cache key. [VERIFIED: QUAL-05] |
| Mutable build service input | Docker image inventory/pin policy. [VERIFIED: QUAL-11] |

## Dependency-Ordered Plan Slices

1. **Policy harness:** required/advisory manifest, evaluator mutation tests, and exact CI inventory contract. Files: `scripts/ci_green_policy.sh`, `test/scripts/*contract_test.exs`, `ci.yml`. QUAL-03/04/10.
2. **Formatter and locked setup:** root formatter expansion, one inbound normalization, local composite action, package/cache/toolchain contract. Files: formatter files, affected inbound source/tests, `.github/actions/*`, workflows. QUAL-01/05/10.
3. **Determinism governance:** bidirectional skip/flaky/sleep registry; replace selected readiness sleeps with acknowledgements, retain categorized clock/TTL/liveness exceptions. Files: registry/validator and focused tests. QUAL-09.
4. **Coverage and critical paths:** pinned-toolchain measurement, non-decreasing floors, core/inbound critical-path contracts. Files: mixfiles, coverage/support tests, CI jobs. QUAL-06.
5. **Static-analysis ratchet:** fix Credo baseline, add inbound Dialyzer, introduce complexity and ignore ledgers with expiration/no-growth. Files: `.credo.exs`, Dialyzer config/ignore scripts, inbound mixfile, validators/tests. QUAL-07/08.
6. **Protected promotion:** add all and only green required commands to CI Green; prove advisory jobs excluded. Files: manifest/policy, `ci.yml`, tests. QUAL-03/04.
7. **Workflow hardening and release policy extraction:** timeout/permission/Docker/Dependabot contract; move large release shell/JS policy to versioned tested scripts without changing check names. Files: workflows, Docker inputs, dependabot, scripts/tests. QUAL-05/10/11.

## Sources

### Primary (HIGH confidence)

- `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, and Phase 158 verification — scope and current baseline.
- `mix.exs`, `mailglass_inbound/mix.exs`, `.formatter.exs`, `.credo.exs`, `.github/workflows/ci.yml`, `.github/dependabot.yml`, and `scripts/*` — current implementation.
- Phase 159 audit supplied by the orchestrator — counted dependency/cache, exception, timeout, permission, and Docker gaps.

### Secondary (MEDIUM confidence)

- Context7 research plan selected documentation sources for Mix/GitHub Actions, but Context7 CLI/MCP was unavailable; external documentation claims are not used as authoritative evidence.

### Tertiary (LOW confidence)

- A1–A3 are implementation hypotheses to validate in Wave 0.

## Metadata

**Confidence breakdown:** Standard stack HIGH; architecture HIGH; pitfalls HIGH for observed gaps and ASSUMED for unprototyped mechanics.

**Research date:** 2026-08-17
**Valid until:** 2026-08-24
