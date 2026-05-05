# Phase 34: Verification & Regression Closure - Research

**Researched:** 2026-05-05
**Domain:** CI contract design, package-local verification ownership, and support-surface regression coverage [VERIFIED: repo grep]
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md) [VERIFIED: repo grep]

### Locked Decisions
- **D-34-01:** Do not define Phase 34 success around one monolithic repo-root `mix test` claiming to verify the whole repo. That is the wrong abstraction for a sibling-package codebase.
- **D-34-02:** Keep package-local suites authoritative:
  - root `mix test` remains authoritative for `mailglass` core
  - `mailglass_admin` keeps its own authoritative suite(s)
  - any top-level verification entrypoint introduced in Phase 34 should be an honest orchestrator over those package-local authorities
- **D-34-03:** The `MAT-03` gate should be a dedicated required support-contract gate, not “every available test in both packages must pass.”
- **D-34-04:** The required Phase 34 verification contract should cover three buckets:
  - core support-contract regression bundle
  - admin/operator support-contract regression bundle
  - consumer-shape contract such as compile without optional deps
- **D-34-05:** Required support-contract jobs must be explicit, always-run, and non-vacuous. Avoid conditional/skipped required jobs and avoid tag-only gates that can pass with zero matching tests.

### Bootstrap reliability and trust semantics
- **D-34-06:** Workflow/test bootstrap reliability is the highest-risk seam in this phase because it determines whether maintainers can trust automation at all.
- **D-34-07:** Phase 34 should harden the verification entrypoints it declares authoritative. Broad repo-wide reruns that are still noisy or structurally broader than `MAT-03` may remain advisory, but they must not be mislabeled as the release gate.
- **D-34-08:** Do not centralize `mailglass` and `mailglass_admin` bootstrap lifecycle into one opaque global helper just to manufacture a fake root gate. Keep ownership local to each package’s `test_helper` / case-template structure.
- **D-34-09:** Do not paper over bootstrap instability with broad retry/rescue behavior that can hide real failures. Retry-based probes such as `CitextProbe` are acceptable only with clear honesty boundaries and package-local ownership.

### Advisory vs required lanes
- **D-34-10:** Keep real-provider / live-provider workflows advisory. Do not promote networked third-party provider lanes to required PR gates.
- **D-34-11:** Split the current advisory space into two clearer contracts:
  - deterministic provider-smoke / compatibility coverage that can be required if it does not depend on external network, secrets, or timing-sensitive provider behavior
  - true provider-live canary coverage that stays advisory on cron and `workflow_dispatch`
- **D-34-12:** If an advisory workflow duplicates required CI without adding meaningful signal, repurpose it into deterministic smoke/compatibility coverage or remove it. Avoid placebo advisory jobs.
- **D-34-13:** Advisory failures should remain triaged and visible, but advisory semantics must stay explicit: they are canaries and release evidence, not branch-protection truth.

### Support-truth contract priorities
- **D-34-14:** After verification-entrypoint trust, the next highest priority is the truthfulness contract around telemetry, support summaries, support docs, and support cards.
- **D-34-15:** Phase 34 should preserve and expand automated contract coverage that proves support surfaces say only what mailglass can actually know about delivery, replay, reconcile, and backlog state.
- **D-34-16:** Replay/reconcile should stay on a focused regression-retention track in this phase. Preserve the Phase 32 semantics and keep targeted regression coverage; do not broaden Phase 34 into new replay/reconcile product design.
- **D-34-17:** Provider/advisory workflow coverage belongs in this phase only as an explicit documented gate and signal posture, not as a new required merge blocker.

### Recommendation-first workflow posture
- **D-34-18:** Downstream Phase 34 research, planning, and implementation should be recommendation-first and one-shot by default:
  - research broadly
  - compare tradeoffs internally
  - return one cohesive recommendation set
  - avoid option sprawl
- **D-34-19:** Shift this posture left within GSD for this project: escalate only for very impactful choices the user is likely to care about directly.
- **D-34-20:** For this phase, “very impactful” means choices that materially change:
  - public verification/release contract
  - user trust semantics or overclaim/underclaim risk
  - branch-protection or CI required-check posture
  - tenant/privacy/security boundaries
  - long-term maintainer burden in a significant way

### the agent's Discretion
- Exact workflow/job names, mix aliases, and script locations for the support-contract gate.
- Exact composition of the core/admin targeted regression bundles, as long as they remain support-critical, explicit, and non-vacuous.
- Exact docs wording that clarifies required vs advisory verification posture.
- Exact file/module placement for any verification orchestrator or helper introduced in this phase.

### Deferred Ideas (OUT OF SCOPE)
- Turning live-provider or networked third-party checks into required PR gates.
- Broadening Phase 34 into new support-console or observability-product features.
- Reworking replay/reconcile product semantics beyond retaining regression coverage.
- Treating broad full-suite reruns as the `MAT-03` release contract before they are stable and honestly scoped.
</user_constraints>

<phase_requirements>
## Phase Requirements [VERIFIED: repo grep]

| ID | Description | Research Support |
|----|-------------|------------------|
| MAT-03 | Maintainer has automated verification for the highest-risk deferred regression and production-support gaps before `v1.0`. | Use one explicit required support-contract gate composed of a core regression bundle, an admin/operator regression bundle, and a no-optional-deps consumer-shape check; keep broad full suites and provider-live lanes advisory. [VERIFIED: repo grep][CITED: https://hexdocs.pm/mix/Mix.Tasks.Test.html][CITED: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/about-status-checks] |
</phase_requirements>

## Summary

Phase 34 should formalize an honest verification contract instead of trying to make the entire repo look like one authoritative root suite. The repo already has the ingredients for that contract: the root `tests` job covers core `mailglass`, `admin_smoke_gate` proves a separate admin-required seam can work, the Phase 33 support bundle already exercises docs, telemetry, support-summary, replay/reconcile, and operator LiveView behavior, and both packages already own their own bootstrap lifecycle in separate `test_helper` files. [VERIFIED: repo grep]

The current gap is contract clarity, not lack of tests. `ci.yml` still labels broad root `mix test` as the main required test job, `advisory-matrix.yml` currently duplicates the same compile/test shape on the same Elixir/OTP version, and `provider-live.yml` is correctly advisory but isolated from the rest of the story. GitHub documents that skipped jobs can still look successful and that workflow-level skipping can block required checks in pending state, so Phase 34 should avoid conditional required jobs and should give each required lane a unique, always-run name. [VERIFIED: repo grep][CITED: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/about-status-checks][CITED: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks?apiVersion=2022-11-28][CITED: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches]

**Primary recommendation:** Add one thin top-level Phase 34 verifier that orchestrates three explicit authorities: a root/core support-contract bundle, a `mailglass_admin` operator/support bundle, and `mix compile --no-optional-deps --warnings-as-errors`; make those jobs the required truth, keep provider-live advisory, and repurpose or remove the duplicate advisory matrix. [VERIFIED: repo grep][CITED: https://hexdocs.pm/mix/Mix.Tasks.Test.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Required support-contract orchestration | CI workflow layer | Mix alias / script layer | GitHub Actions should expose the required checks explicitly, while Mix aliases provide honest local entrypoints. [VERIFIED: repo grep][CITED: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches] |
| Core support-truth regression bundle | `mailglass` package test suite | Core docs/guides | The root package already owns docs, telemetry, replay/reconcile, and support-summary contracts. [VERIFIED: repo grep] |
| Admin/operator support regression bundle | `mailglass_admin` package test suite | Root package fixtures/test DB | Operator support cards and smoke behavior live under `mailglass_admin` and should stay package-local. [VERIFIED: repo grep] |
| Bootstrap hardening | Package-local `test_helper` + case templates | `CitextProbe` helpers | Both packages already initialize repos and sandbox mode locally; Phase 34 should harden those entrypoints, not replace them. [VERIFIED: repo grep][CITED: https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.Sandbox.html] |
| Provider-live canary signal | Advisory workflow layer | Issue-tracking notification job | Networked provider checks are canaries and should remain outside branch-protection truth. [VERIFIED: repo grep] |

## Project Constraints (from CLAUDE.md)

- No Node toolchain assumptions in the main product architecture; introducing Node-backed required verification would conflict with the repo’s stated posture. [VERIFIED: repo grep]
- Fake-adapter coverage is the merge-blocking trust base; real-provider tests stay advisory on cron and `workflow_dispatch`. [VERIFIED: repo grep]
- Optional dependencies must continue to compile cleanly behind `Mailglass.OptionalDeps.*`; `mix compile --no-optional-deps --warnings-as-errors` is a required consumer-shape contract. [VERIFIED: repo grep]
- Support, telemetry, and operator surfaces must stay honest and privacy-minimized; Phase 34 should expand tests that prevent overclaiming or PII leakage. [VERIFIED: repo grep]
- Sibling packages keep separate ownership boundaries; Phase 34 should not collapse `mailglass` and `mailglass_admin` into one opaque bootstrap abstraction. [VERIFIED: repo grep]
- Third-party GitHub Actions are expected to be SHA-pinned when CI is edited. [VERIFIED: repo grep]

## Standard Stack

### Core
| Library / Tool | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `mix test` file-path selection | Mix v1.19.5 docs | Run explicit support-contract bundles by file path instead of relying on broad repo defaults. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Test.html] | Mix explicitly supports passing files/directories after `mix test`, which is the cleanest way to make required bundles explicit and non-vacuous. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Test.html] |
| `Ecto.Adapters.SQL.Sandbox` | Ecto SQL v3.13.5 docs / repo dep `~> 3.13` | Package-local DB ownership for async and spawned-process tests. [CITED: https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.Sandbox.html][VERIFIED: repo grep] | The docs recommend manual mode plus `start_owner!`; the repo already follows that pattern in case templates and `test_helper` bootstrap. [CITED: https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.Sandbox.html][VERIFIED: repo grep] |
| GitHub Actions required job checks | Current GitHub Docs | Surface required support-contract lanes with unique names and always-run semantics. [CITED: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/about-status-checks][CITED: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches] | GitHub’s branch-protection model works best when the required checks are explicit, unique, and not conditionally skipped. [CITED: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks?apiVersion=2022-11-28][CITED: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches] |

### Supporting
| Library / Tool | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Phoenix.LiveViewTest` | repo dep `~> 1.1` [VERIFIED: repo grep] | Keep operator support-card and drilldown behavior package-local in `mailglass_admin`. [VERIFIED: repo grep] | Use for the required admin/operator support bundle. [VERIFIED: repo grep] |
| `Swoosh.Adapters.Sandbox` | Swoosh v1.25.1 docs | Deterministic mail assertions without external providers. [CITED: https://hexdocs.pm/swoosh/Swoosh.Adapters.Sandbox.html] | Use if Phase 34 adds deterministic provider-compat or mail-delivery assertions that should remain required. [CITED: https://hexdocs.pm/swoosh/Swoosh.Adapters.Sandbox.html] |
| `actionlint` | local 1.7.12 [VERIFIED: repo grep] | Validate workflow YAML when Phase 34 edits CI contracts. [VERIFIED: repo grep] | Run on every CI-workflow change. [VERIFIED: repo grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Explicit file-based support bundles | tag-only required suites | Tag-only required jobs can pass vacuously if no tests match; the repo already has a historical example of this with `admin_smoke_gate`. [VERIFIED: repo grep] |
| Thin orchestrator over package-local authorities | single repo-root “truth” suite | This would overclaim what the root package can authoritatively verify in a sibling-package repo and would fight the already-separate bootstrap ownership. [VERIFIED: repo grep] |
| Advisory provider-live canary | required networked provider lanes | Required networked lanes would import external flake, secrets, and provider timing into branch-protection truth, which conflicts with repo policy. [VERIFIED: repo grep] |

**Installation:**
```bash
# No new Hex packages are recommended for Phase 34.
# The standard stack is already present in the repo.
mix deps.get
cd mailglass_admin && mix deps.get
```

**Version verification:** The repo already pins the relevant verification stack in `mix.exs`, `mailglass_admin/mix.exs`, and workflow YAML; this phase is contract work, not dependency-selection work. [VERIFIED: repo grep]

## Architecture Patterns

### System Architecture Diagram

```text
Pull request / push
  -> GitHub Actions required checks
    -> Core Support Contract job
      -> root package bootstrap (`test/test_helper.exs`)
      -> explicit core files:
         docs contract
         operator incident guide contract
         support summary
         telemetry
         replay / reconciler regressions
    -> Admin Support Contract job
      -> `mailglass_admin/test/test_helper.exs`
      -> explicit admin files:
         operator_live support cards / drilldowns
         post_installer smoke
    -> Consumer Shape job
      -> `mix compile --no-optional-deps --warnings-as-errors`
  -> Advisory checks
    -> broad full-suite reruns (if retained)
    -> deterministic provider-compat smoke (optional, only if local/deterministic)
    -> provider-live cron / workflow_dispatch canary
      -> failure issue/comment tracking
```

The data flow above matches current repo ownership boundaries and the GitHub check model: PRs enter CI, CI fans out into explicit required contracts, and advisory signal remains visibly separate from merge-blocking truth. [VERIFIED: repo grep][CITED: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/about-status-checks]

### Recommended Project Structure
```text
.github/workflows/
├── ci.yml                         # required support-contract jobs + consumer-shape job
├── advisory-matrix.yml            # repurpose to deterministic compat smoke or remove
└── provider-live.yml              # advisory canary only

mix.exs                            # root/top-level honest verifier alias
mailglass_admin/mix.exs            # admin-local verifier alias if needed

test/
├── test_helper.exs                # core bootstrap authority
├── support/                       # core case templates / CitextProbe
└── mailglass/                     # explicit core support-contract files

mailglass_admin/test/
├── test_helper.exs                # admin bootstrap authority
├── support/                       # admin case templates / bootstrap helpers
└── mailglass_admin/               # explicit admin support-contract files
```

### Pattern 1: Thin Top-Level Verifier
**What:** Add one honest top-level entrypoint that shells into explicit root and admin commands rather than pretending root `mix test` covers everything. [VERIFIED: repo grep]
**When to use:** For local maintainer workflows and required CI jobs. [VERIFIED: repo grep]
**Example:**
```elixir
# Source: repo pattern + Mix file selection docs
defp aliases do
  [
    "verify.support_contract": [
      "test test/mailglass/docs_contract_test.exs "
      <> "test/mailglass/docs/operator_incident_support_guide_test.exs "
      <> "test/mailglass/operator/support_summary_test.exs "
      <> "test/mailglass/webhook/telemetry_test.exs "
      <> "test/mailglass/telemetry_test.exs "
      <> "test/mailglass/webhook/replay_test.exs "
      <> "test/mailglass/webhook/reconciler_test.exs --warnings-as-errors",
      "cmd cd mailglass_admin && mix test "
      <> "test/mailglass_admin/operator_live_test.exs "
      <> "test/mailglass_admin/post_installer_smoke_test.exs --warnings-as-errors",
      "compile --no-optional-deps --warnings-as-errors"
    ]
  ]
end
```

### Pattern 2: Package-Local Bootstrap Ownership
**What:** Keep setup and sandbox lifecycle local to each package’s `test_helper` and case templates. [VERIFIED: repo grep]
**When to use:** Always; especially when hardening bootstrap reliability. [VERIFIED: repo grep]
**Example:**
```elixir
# Source: https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.Sandbox.html
setup tags do
  pid = Ecto.Adapters.SQL.Sandbox.start_owner!(MyApp.Repo, shared: not tags[:async])
  on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  :ok
end
```

### Pattern 3: Advisory Canaries Stay Explicitly Advisory
**What:** Leave networked provider checks on `schedule` and `workflow_dispatch`, with failure tracking, but outside required PR truth. [VERIFIED: repo grep]
**When to use:** For real provider credentials, third-party network calls, or timing-sensitive provider behavior. [VERIFIED: repo grep]
**Example:**
```yaml
# Source: repo pattern
on:
  schedule:
    - cron: "33 6 * * *"
  workflow_dispatch:
```

### Anti-Patterns to Avoid
- **Monolithic repo-root truth claim:** The root `tests` job currently runs `mix test --warnings-as-errors`, but that is broader than `MAT-03` and does not cover `mailglass_admin` as a package-local authority. [VERIFIED: repo grep]
- **Conditional required jobs:** GitHub documents that skipped jobs can still report success and that skipped workflows can leave required checks pending; required Phase 34 jobs should therefore be unconditional and always requested. [CITED: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/about-status-checks][CITED: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks?apiVersion=2022-11-28]
- **Tag-only required smoke suites:** The repo already had a vacuous tagged smoke gate incident; required jobs should name files or otherwise prove non-zero scope. [VERIFIED: repo grep]
- **Retry wrappers that hide bootstrap failure:** `CitextProbe` is acceptable because its scope is explicit and package-local; Phase 34 should not add blanket retry/rescue behavior around whole required jobs. [VERIFIED: repo grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Required support gate orchestration | custom global bootstrap runner spanning both packages | thin Mix alias or small shell/script orchestrator over package-local commands | The repo already has separate authorities; a global runner would hide ownership and increase debugging cost. [VERIFIED: repo grep] |
| DB test isolation | custom connection-sharing logic | `Ecto.Adapters.SQL.Sandbox.start_owner!/stop_owner` and existing case templates | Ecto already provides the ownership model the repo needs for async and shared tests. [CITED: https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.Sandbox.html] |
| Deterministic mail assertions | provider-live required tests | `Swoosh.Adapters.Sandbox` or the repo’s fake/local adapters | Official Swoosh docs position the sandbox for async-safe deterministic test delivery. [CITED: https://hexdocs.pm/swoosh/Swoosh.Adapters.Sandbox.html] |
| CI skip semantics | bespoke “green if skipped” conventions | GitHub-required checks with always-run jobs and unique names | GitHub already defines the semantics; Phase 34 should align with them instead of inventing a parallel policy. [CITED: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/about-status-checks][CITED: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches] |

**Key insight:** Phase 34 is a contract-clarification phase, not a framework-selection phase; most risk comes from mislabeled verification, not missing testing primitives. [VERIFIED: repo grep]

## Common Pitfalls

### Pitfall 1: Required Checks That Can Succeed Without Verifying Anything
**What goes wrong:** A required job passes even though it matched zero meaningful tests. [VERIFIED: repo grep]
**Why it happens:** Tag-only selection and historical drift between CI selectors and actual test files. [VERIFIED: repo grep]
**How to avoid:** Use explicit file lists or other provably non-vacuous selectors for required bundles. [VERIFIED: repo grep][CITED: https://hexdocs.pm/mix/Mix.Tasks.Test.html]
**Warning signs:** The repo already documents a prior `admin_smoke_gate` zero-match incident. [VERIFIED: repo grep]

### Pitfall 2: Required Checks Hidden Behind Skip Conditions
**What goes wrong:** A required check appears green or stays pending for reasons unrelated to verification truth. [CITED: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/about-status-checks][CITED: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks?apiVersion=2022-11-28]
**Why it happens:** Job-level `if:` and workflow-level path/branch filtering interact differently in GitHub checks. [CITED: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks?apiVersion=2022-11-28]
**How to avoid:** Keep required Phase 34 jobs always-run in the workflows that branch protection expects. [CITED: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks?apiVersion=2022-11-28]
**Warning signs:** Required checks missing from a PR or stuck in pending state after a docs-only or path-filtered change. [CITED: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks?apiVersion=2022-11-28]

### Pitfall 3: Placebo Advisory Coverage
**What goes wrong:** An advisory workflow runs the same compile/test shape as required CI and adds no new signal. [VERIFIED: repo grep]
**Why it happens:** Advisory lanes accumulate historically and stop differentiating themselves. [VERIFIED: repo grep]
**How to avoid:** Repurpose the advisory matrix to deterministic compat smoke or remove it if it remains duplicative. [VERIFIED: repo grep]
**Warning signs:** Same Elixir/OTP row, same DB setup, same `mix test --exclude provider_live` pattern as required CI. [VERIFIED: repo grep]

### Pitfall 4: Broad Retry Logic Masks Real Bootstrap Breakage
**What goes wrong:** CI becomes green by retrying around root causes instead of fixing the declared entrypoint. [VERIFIED: repo grep]
**Why it happens:** Bootstrap flake is painful, so the temptation is to add rescue/retry at the workflow layer. [ASSUMED]
**How to avoid:** Keep retries limited to the explicit `CitextProbe` seam and make the declared required entrypoints structurally honest. [VERIFIED: repo grep]
**Warning signs:** Required jobs start passing after reruns while direct file-bundle commands still fail locally. [ASSUMED]

## Code Examples

Verified patterns from official sources and the repo:

### Explicit File-Scoped Verification
```bash
# Source: https://hexdocs.pm/mix/Mix.Tasks.Test.html
mix test test/mailglass/docs_contract_test.exs test/mailglass/webhook/replay_test.exs --warnings-as-errors
```

### Sandbox Ownership for Package-Local Tests
```elixir
# Source: https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.Sandbox.html
setup tags do
  pid = Ecto.Adapters.SQL.Sandbox.start_owner!(MyApp.Repo, shared: not tags[:async])
  on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  :ok
end
```

### Deterministic Mail Delivery in Tests
```elixir
# Source: https://hexdocs.pm/swoosh/Swoosh.Adapters.Sandbox.html
setup do
  :ok = Swoosh.Adapters.Sandbox.checkout()
  on_exit(&Swoosh.Adapters.Sandbox.checkin/0)
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| “root suite is the whole truth” | package-local authorities orchestrated by explicit CI contracts | Current recommendation for Phase 34, aligned with current repo structure on 2026-05-05 [VERIFIED: repo grep] | Makes `MAT-03` honest and keeps sibling-package ownership intact. [VERIFIED: repo grep] |
| advisory matrix duplicating required compile/test | advisory lane must add differentiated deterministic signal or be removed | Current recommendation for Phase 34 on 2026-05-05 [VERIFIED: repo grep] | Reduces placebo CI and clarifies which failures maintainers should act on immediately. [VERIFIED: repo grep] |
| live-provider lane as generic extra workflow | live-provider canary with explicit failure triage and no branch-protection truth | Already present in `provider-live.yml` [VERIFIED: repo grep] | Keeps external flake out of required gates while preserving operational evidence. [VERIFIED: repo grep] |

**Deprecated/outdated:**
- Using tag-only required gates as the primary proof surface is outdated for this repo because it already produced a vacuous-pass incident. [VERIFIED: repo grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The maintainer is willing to change GitHub branch-protection required-check names to match any new Phase 34 jobs. | Open Questions / Validation Architecture | New jobs could exist in YAML but never become the actual required contract. |
| A2 | Broad retry logic would be considered unacceptable if proposed at the workflow layer, beyond the existing package-local `CitextProbe` use. | Common Pitfalls | A plan might over-constrain future reliability work if the maintainer wanted more workflow-level mitigation. |

## Resolved Questions

1. **Which job names should Phase 34 treat as branch-protection truth?**
   - What we know: The workflow files define candidate jobs such as `tests`, `admin_smoke_gate`, and `operator_browser_gate`, but branch-protection configuration is not stored in the repo. [VERIFIED: repo grep]
   - Final decision: Phase 34 treats only these three jobs as the required `MAT-03` truth contract: `Compile No Optional Deps (Elixir 1.18 / OTP 27)`, `Support Contract Core (Elixir 1.18 / OTP 27)`, and `Support Contract Admin (Elixir 1.18 / OTP 27)`. Any previous required reference to `Tests (Elixir 1.18 / OTP 27)` should be removed during the manual branch-protection update. [VERIFIED: repo grep][CITED: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches]

2. **How should `operator_browser_gate` be classified?**
   - What we know: It currently sits in `ci.yml` and depends on Node 22 + Playwright, which makes it heavier than the required support-contract lanes. [VERIFIED: repo grep]
   - Final decision: `operator_browser_gate` stays as browser evidence in CI, but it is explicitly advisory and not part of the required `MAT-03` three-bucket truth contract. If branch protection currently marks it required, the Phase 34 manual setup step must remove that required-check reference. [VERIFIED: repo grep]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | local verification commands | ✓ | 1.19.5 [VERIFIED: repo grep] | CI floor remains Elixir 1.18 in workflow YAML. [VERIFIED: repo grep] |
| Mix | local verification commands | ✓ | 1.19.5 [VERIFIED: repo grep] | None needed. |
| `psql` | local Postgres connectivity / manual DB checks | ✓ | 14.17 [VERIFIED: repo grep] | Rely on GitHub Actions Postgres service if local DB is unavailable. [VERIFIED: repo grep] |
| `pg_isready` | local/CI bootstrap checks | ✓ | 14.17 [VERIFIED: repo grep] | None in CI; it is already used by workflows. [VERIFIED: repo grep] |
| Node.js | current browser gate only | ✓ | 22.14.0 [VERIFIED: repo grep] | If browser coverage becomes advisory, Phase 34’s required contract does not depend on Node. [VERIFIED: repo grep] |
| `actionlint` | validating workflow edits | ✓ | 1.7.12 [VERIFIED: repo grep] | None as strong; YAML edits should use it. [VERIFIED: repo grep] |

**Missing dependencies with no fallback:**
- None found for the recommended required contract. [VERIFIED: repo grep]

**Missing dependencies with fallback:**
- None found locally; GitHub-hosted runner differences remain the main execution environment caveat. [VERIFIED: repo grep]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit + Phoenix.LiveViewTest [VERIFIED: repo grep] |
| Config file | `config/test.exs` and `mailglass_admin/config/test.exs` [VERIFIED: repo grep] |
| Quick run command | `mix test test/mailglass/docs_contract_test.exs test/mailglass/docs/operator_incident_support_guide_test.exs test/mailglass/operator/support_summary_test.exs test/mailglass/webhook/telemetry_test.exs test/mailglass/telemetry_test.exs test/mailglass/webhook/replay_test.exs test/mailglass/webhook/reconciler_test.exs --warnings-as-errors` and `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/post_installer_smoke_test.exs --warnings-as-errors` and `mix compile --no-optional-deps --warnings-as-errors` [VERIFIED: repo grep] |
| Full suite command | `mix test --warnings-as-errors` and `cd mailglass_admin && mix test --warnings-as-errors` [VERIFIED: repo grep] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MAT-03 | Core support truth stays aligned across docs, telemetry, replay/reconcile, and support-summary surfaces. [VERIFIED: repo grep] | unit/integration | `mix test test/mailglass/docs_contract_test.exs test/mailglass/docs/operator_incident_support_guide_test.exs test/mailglass/operator/support_summary_test.exs test/mailglass/webhook/telemetry_test.exs test/mailglass/telemetry_test.exs test/mailglass/webhook/replay_test.exs test/mailglass/webhook/reconciler_test.exs --warnings-as-errors` | ✅ |
| MAT-03 | Admin/operator support surfaces stay truthful, tenant-scoped, and non-vacuous. [VERIFIED: repo grep] | LiveView integration / smoke | `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/post_installer_smoke_test.exs --warnings-as-errors` | ✅ |
| MAT-03 | Consumer shape still works with optional deps removed. [VERIFIED: repo grep] | compile contract | `mix compile --no-optional-deps --warnings-as-errors` | ✅ |

### Sampling Rate
- **Per task commit:** run the smallest affected support-contract bundle plus `actionlint` for workflow edits. [VERIFIED: repo grep]
- **Per wave merge:** rerun both package bundles and the no-optional-deps compile command. [VERIFIED: repo grep]
- **Phase gate:** all three required bundle commands green before `/gsd-verify-work`. [VERIFIED: repo grep]

### Wave 0 Gaps
- None — the test framework, representative support-contract tests, and workflow-lint tooling already exist; Phase 34 needs alias/job composition and contract clarification, not new infrastructure. [VERIFIED: repo grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase 34 should not introduce new auth mechanics; only preserve existing operator boundaries in regression coverage. [VERIFIED: repo grep] |
| V3 Session Management | no | Same reason as V2 for this phase scope. [VERIFIED: repo grep] |
| V4 Access Control | yes | Keep tenant-scoped operator/support regressions in the required admin bundle. [VERIFIED: repo grep] |
| V5 Input Validation | yes | Docs/support-surface contract tests should continue rejecting stale or unsafe wording/examples. [VERIFIED: repo grep] |
| V6 Cryptography | no | Phase 34 is not adding new crypto paths. [VERIFIED: repo grep] |

### Known Threat Patterns for this Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| False green from skipped or vacuous required jobs | Tampering / Repudiation | Explicit always-run required jobs with unique names and non-vacuous selectors. [CITED: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/about-status-checks][CITED: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches] |
| Cross-tenant or overclaiming support UI regressions | Information Disclosure / Tampering | Keep `operator_live_test.exs` and support-summary tests inside the required contract. [VERIFIED: repo grep] |
| Required CI depending on third-party provider/network health | Denial of Service | Keep provider-live on advisory cron / `workflow_dispatch`. [VERIFIED: repo grep] |

## Sources

### Primary (HIGH confidence)
- Repo artifacts (`34-CONTEXT.md`, `REQUIREMENTS.md`, `STATE.md`, `ROADMAP.md`, `PROJECT.md`, `METHODOLOGY.md`, Phase 33 verification/validation docs, `ci.yml`, `advisory-matrix.yml`, `provider-live.yml`, `mix.exs`, `mailglass_admin/mix.exs`, package test helpers, support-contract tests) - current local contract and implementation seams. [VERIFIED: repo grep]
- https://hexdocs.pm/mix/Mix.Tasks.Test.html - explicit file selection, `test_helper` loading, warnings-as-errors semantics. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Test.html]
- https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.Sandbox.html - sandbox ownership and package-local DB test patterns. [CITED: https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.Sandbox.html]
- https://hexdocs.pm/swoosh/Swoosh.Adapters.Sandbox.html - deterministic mail testing without live providers. [CITED: https://hexdocs.pm/swoosh/Swoosh.Adapters.Sandbox.html]
- https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/about-status-checks - skipped-job semantics and check model. [CITED: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/about-status-checks]
- https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks?apiVersion=2022-11-28 - required-check pending/skip behavior and latest-SHA rules. [CITED: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks?apiVersion=2022-11-28]
- https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches - unique required-check naming and branch-protection behavior. [CITED: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches]

### Secondary (MEDIUM confidence)
- None needed. All material external claims were taken from primary docs. [VERIFIED: repo grep]

### Tertiary (LOW confidence)
- None. [VERIFIED: repo grep]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - the recommended tools and semantics are either already in the repo or documented in primary sources. [VERIFIED: repo grep][CITED: https://hexdocs.pm/mix/Mix.Tasks.Test.html]
- Architecture: HIGH - the package-local ownership boundaries and current workflow duplication are directly visible in the repo. [VERIFIED: repo grep]
- Pitfalls: MEDIUM - the main pitfalls are well-grounded, but branch-protection configuration itself is external to the repo. [VERIFIED: repo grep][CITED: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks?apiVersion=2022-11-28]

**Research date:** 2026-05-05
**Valid until:** 2026-06-04
