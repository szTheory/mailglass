# Project Research Summary

**Project:** mailglass
**Domain:** Phoenix transactional email framework with sibling admin package
**Researched:** 2026-05-05
**Confidence:** HIGH

## Executive Summary

Mailglass is not trying to become a general email platform before `v1.0`. It is a Phoenix-first transactional email framework, built on top of Swoosh, whose `v1.0 Stability Lock` should make the existing transactional and admin core trustworthy for long-lived production adoption. The research is aligned on the product shape: keep the runtime stack and scope narrow, define the public contract explicitly, and prove that contract through docs, contract tests, upgrade smoke, and release checks.

The recommended direction is a **docs-heavy proof milestone with targeted contract enforcement**. That means no new runtime dependencies, no new abstraction layer, no product-surface expansion, and no attempt to freeze every exported module. Instead, mailglass should declare a small stable surface for `mailglass` and `mailglass_admin`, mark everything else internal, adopt a conservative `1.x` deprecation policy, and add enough CI proof that “stable” means something operationally. This is the least-surprise Elixir/Phoenix path and the best fit for a one-maintainer library.

The main risks are over-promising and under-proving. If the project freezes too much, normal refactors become semver-major. If it freezes too little, `v1.0` reads as ceremonial. The mitigation is narrow guardrails: explicit allowlists, stable-vs-internal docs, additive-only `1.x` rules, upgrade/install proof artifacts, and release rehearsal across both sibling packages.

## Key Findings

### Recommended Stack

The stack recommendation is deliberately conservative: **keep the current runtime stack exactly as-is** and spend the milestone on contract clarity, proof, and DX. The existing Elixir, OTP, Phoenix, LiveView, Ecto, Postgrex, Swoosh, ExDoc, Hex, Boundary, Credo, and Dialyzer setup is already sufficient for a credible `v1.0` lock.

The only real additions should be internal release-contract tooling and docs discipline: `@since` and deprecation metadata on stable API, ExDoc extras/grouping for the stability story, contract tests driven from compiled docs, and release aliases that verify docs, tarball contents, upgrade flow, and deprecated-path hygiene.

**Core technologies:**
- `Elixir ~> 1.18` / `OTP 27+`: keep the current floor to avoid destabilizing the milestone.
- `Phoenix 1.8+` / `LiveView 1.0+`: keep Phoenix-first coupling; do not dilute the contract with framework-agnostic ambitions.
- `Ecto` / `Postgrex`: keep the Postgres-only persistence contract; no support-matrix expansion.
- `Swoosh`: keep it as the transport layer under mailglass; stability is about the framework contract, not replacing transport.
- `ExDoc`, `Hex`, `Boundary`, `Credo`, `Dialyzer`: use the existing toolchain to define and verify the public surface instead of adding new compatibility tooling.

### Expected Features

The milestone should add trust, not capability. The must-have work is the public contract itself, upgrade proof, stable admin mount/config semantics, deprecation policy, and fail-fast release checks. The should-have work is narrowly scoped automation that enforces the documented contract and reduces future drift. Anything that expands product scope or invents a heavyweight compatibility framework should stay out.

**Must have (table stakes):**
- Public API inventory with explicit `stable`, `advanced-but-public`, and `internal` classes across `mailglass` and `mailglass_admin`.
- Published deprecation and compatibility policy for `1.x`, including no removals before `2.0` except security or severe correctness emergencies.
- Upgrade guarantees with proof artifacts: fresh install smoke, previous-version upgrade smoke, and a canonical upgrade guide.
- Stable admin mount/config contract covering router macros, auth behaviour expectations, and operator action semantics.
- Fail-fast compatibility checks for leaked internals, missing docs, broken sibling pins, and unsupported config combinations.

**Should have (competitive):**
- Contract-enforcement CI for documented public surface drift.
- Versioned supported-upgrade-path and support-matrix docs.
- Stable testing-contract documentation for async, Oban, and cross-process delivery semantics.
- Explicit admin public/private boundary docs so adopters do not depend on DOM or LiveView internals.

**Defer (post-`v1.0`):**
- `mailglass_inbound` and all inbound routing work.
- Marketing, workflow automation, or adjacent deliverability expansion.
- Heavy manifest/ABI-style compatibility tooling beyond targeted contract checks.

### Architecture Approach

The architecture recommendation is to treat `v1.0` as an **explicit contract system**. The stable seams are the adopter-facing and sibling-package-facing boundaries that already matter: root delivery API, `Mailglass.Message`, `Mailglass.Mailable`, documented error/result/config contracts, adapter and tenancy behaviours, router macros, unsubscribe/tracking helpers, telemetry names, migration workflow, `MailglassAdmin.Router`, `MailglassAdmin.Auth`, and narrow operator read-model outputs consumed by admin. Everything else stays internal, especially provider internals, repo/renderer/projector plumbing, undocumented helpers, and admin LiveView/component/DOM details.

**Major components:**
1. Core contract surfaces: delivery API, message/mailable/config/error/adapter/tenancy/telemetry/migration seams that adopters build against.
2. Sibling admin contract: router macros, auth behaviour, and operator read-model outputs needed by `mailglass_admin`.
3. Contract-proof system: stability docs, upgrade docs, compiled-doc contract tests, release aliases, and tarball/upgrade smoke artifacts.

### Critical Pitfalls

1. **Declaring stability before the contract is coherent** — resolve the `v0.2 freeze` versus `v1.0 lock` language into one authoritative `v1.x` contract.
2. **Accidentally freezing too much surface** — use an explicit public allowlist; do not let exported modules, admin UI internals, or schema details become implicit promises.
3. **Weak deprecation UX** — every deprecation needs warnings where possible, replacement guidance, changelog coverage, and an upgrade path that works under `--warnings-as-errors`.
4. **Over-broad compatibility promises** — keep support narrow: current version floors, Postgres only, Phoenix-first, and optional dependencies documented as bounded lanes rather than universal guarantees.
5. **Sibling-package release surprises** — rehearse publish/install/docs flow for both `mailglass` and `mailglass_admin` from Hex, not just path dependencies in-repo.

## Implications for Roadmap

Based on the research, the milestone should be planned as four phases. This order matches the dependency chain: define the contract first, then define migration/support rules, then tighten admin/docs boundaries, then prove the release end to end.

### Phase 1: Stability Contract Audit
**Rationale:** Nothing else is credible until the stable surface is explicitly declared and the wording conflict around prior “freeze” claims is resolved.
**Delivers:** Authoritative `v1.x` contract map for core and admin, stable/internal classification rules, `@since` coverage plan, internal-surface cleanup, and an explicit allowlist for the public surface.
**Addresses:** Public API inventory, stable admin mount/config expectations, least-surprise public contracts.
**Avoids:** Freezing the wrong surface, contradictory status language, and accidental commitments around internals.

### Phase 2: Deprecation and Compatibility Contract
**Rationale:** Once the boundary is known, mailglass needs a durable `1.x` operating policy that adopters can trust during upgrades.
**Delivers:** Deprecation policy, compatibility/support window docs, supported upgrade-path matrix, canonical upgrade guide, and warning-backed verification for any remaining legacy entrypoints.
**Addresses:** Published compatibility policy, upgrade guarantees, strong DX for warnings and migrations.
**Avoids:** Weak migration UX, vague support promises, and surprise minor-release churn.

### Phase 3: Contract Enforcement and Trust Docs
**Rationale:** The documented promise needs automation, but only where it materially protects the declared contract.
**Delivers:** Compiled-doc public API contract tests, deprecation inventory checks, release/stability verify aliases, testing-contract docs, admin boundary docs, and docs parity checks.
**Addresses:** Contract-enforcement CI, stable testing contract, stable admin public/private boundary, targeted proof artifacts.
**Avoids:** Docs-only stability, hidden drift, and brittle over-engineered compatibility tooling.

### Phase 4: Release Rehearsal and Proof Artifacts
**Rationale:** `v1.0` must be proven from the adopter’s perspective, not just inside the repo.
**Delivers:** Fresh-install smoke from Hex, previous-version upgrade smoke, tarball unpack/package diff review, sibling-package pin verification, and final docs/positioning sweep aligned to shipped scope.
**Addresses:** Upgrade/install proof, release-contract discipline, production-trustworthy adoption proof.
**Avoids:** Publish-day surprises, broken Hex artifacts, and a “stable in theory” release.

### Phase Ordering Rationale

- Phase 1 must come first because the public contract defines what later tests, docs, and release gates should enforce.
- Phase 2 belongs before deeper automation because deprecation and support policy determine which old paths must remain alive through `1.x`.
- Phase 3 groups enforcement with trust docs because both are about making the promise concrete without expanding scope.
- Phase 4 stays last because release rehearsal only has value once the contract, policy, and proof checks are already in place.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 2:** Validate exact support-window wording and any edge-case deprecation mechanics that affect `mailglass_admin` or documented mix-task workflows.
- **Phase 4:** Verify the exact release rehearsal steps for sibling Hex publishing and the minimum clean-host smoke path that best matches adopter reality.

Phases with standard patterns (skip research-phase):
- **Phase 1:** The stable/internal contract split is already well-supported by the current docs and research.
- **Phase 3:** Targeted compiled-doc contract checks, ExDoc extras/grouping, and release aliases are standard enough for direct planning.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Strong alignment across research: no new runtime deps, reuse the existing Elixir/Hex/ExDoc toolchain. |
| Features | HIGH | The feature scope is narrow and consistent: trust artifacts, not product expansion. |
| Architecture | HIGH | The recommended stable seams map directly to the current package boundaries and existing contract-driven direction. |
| Pitfalls | HIGH | Risks are concrete, repeated across sources, and directly applicable to a one-maintainer Hex library. |

**Overall confidence:** HIGH

### Gaps to Address

- Final stable-surface inventory still needs a package-by-package decision pass during planning; the research gives the direction, not the final exhaustive list.
- The exact clean-host release rehearsal workflow should be validated against current publish/docs automation before phase execution.
- Any lingering legacy entrypoints must be inventoried explicitly so the deprecation contract covers the full remaining `0.x -> 1.0` path.

## Sources

### Primary (HIGH confidence)
- [.planning/research/STACK.md](/Users/jon/projects/mailglass/.planning/research/STACK.md)
- [.planning/research/FEATURES.md](/Users/jon/projects/mailglass/.planning/research/FEATURES.md)
- [.planning/research/ARCHITECTURE.md](/Users/jon/projects/mailglass/.planning/research/ARCHITECTURE.md)
- [.planning/research/PITFALLS.md](/Users/jon/projects/mailglass/.planning/research/PITFALLS.md)
- [.planning/PROJECT.md](/Users/jon/projects/mailglass/.planning/PROJECT.md)
- [.planning/MILESTONE-ARC.md](/Users/jon/projects/mailglass/.planning/MILESTONE-ARC.md)
- Elixir compatibility and deprecations: https://hexdocs.pm/elixir/main/compatibility-and-deprecations.html
- Elixir documentation guidance: https://hexdocs.pm/elixir/writing-documentation.html
- ExDoc docs task/readme: https://hexdocs.pm/ex_doc/
- Hex package build/publish/diff docs: https://hexdocs.pm/hex/
- SemVer 2.0.0: https://semver.org/

### Secondary (MEDIUM confidence)
- Django API stability and release-process docs: https://docs.djangoproject.com/en/4.2/misc/api-stability/ , https://docs.djangoproject.com/en/4.2/internals/release-process/
- Rails maintenance policy and Action Mailer guidance: https://guides.rubyonrails.org/maintenance_policy.html , https://guides.rubyonrails.org/action_mailer_basics.html
- Swoosh docs and changelog: https://hexdocs.pm/swoosh/Swoosh.html , https://hexdocs.pm/swoosh/changelog.html
- Bamboo test docs: https://hexdocs.pm/bamboo/Bamboo.Test.html
- Anymail stable docs and changelog: https://anymail.dev/en/stable/index.html , https://anymail.dev/en/latest/changelog.html

---
*Research completed: 2026-05-05*
*Ready for roadmap: yes*
