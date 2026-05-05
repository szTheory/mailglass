# Feature Landscape

**Domain:** Phoenix transactional email framework v1.0 stability lock
**Project:** mailglass
**Researched:** 2026-05-05
**Overall confidence:** HIGH

## Scope Principle

This milestone should add **stability guarantees, proof, and enforcement for the existing transactional/admin core**. It should not expand the product boundary. Successful frameworks earn trust here by doing three things well:

- **They define what is public and what is internal.** Django explicitly treats documented APIs as stable and internals as exempt. Mailglass should do the same for `mailglass` and `mailglass_admin`.
- **They deprecate slowly and predictably.** Elixir documents a staged deprecation path and only removes deprecated surface in a major release. Mailglass should adopt a 1.x-compatible version of that discipline.
- **They make the happy path testable and inspectable.** Rails, Swoosh, Bamboo, and Django all win trust by making previews/tests first-class instead of forcing adopters to invent harnesses.

## Table Stakes

Features adopters should expect before trusting a `1.0.0` library in production.

| Feature | Why Expected | Complexity | Depends On | Notes |
|---------|--------------|------------|------------|-------|
| **Public API inventory with explicit stability classes** | A `1.0` promise is meaningless unless adopters can tell what is stable. | Med | `docs/api_stability.md`, current module exports, admin router macros | Mark each surface as `stable`, `advanced-but-public`, or `internal`. Include `mailglass_admin` macros/config knobs, not just core functions. |
| **Published deprecation and compatibility policy** | Teams need to know how long warnings live, what can break in patch/minor releases, and what security exceptions exist. | Low | Existing v0.2 freeze doc | Recommended rule: no removals in `1.x`; deprecate with docs + warnings + upgrade path; patch releases may fix bugs, minor releases may add API, only security/data-correctness can force emergency breakage. |
| **Upgrade guarantees with proof artifacts** | “Stable” needs evidence, not a promise. | Med | install flow, smoke tests, existing docs checks, publish checks | Fresh-install smoke app, previous-minor upgrade smoke app, and docs-backed upgrade guide should all pass in CI. |
| **Stable admin mount/config contract** | `mailglass_admin` is part of the declared core. Route macros and required config must stop drifting. | Med | current admin router/tests, auth contract, asset packaging | Lock macro options, mount expectations, and operator-safe route semantics. Do not promise internal LiveView component markup. |
| **Warning-backed migration path for any remaining legacy entrypoints** | Adopted libraries leave escape hatches but make the preferred path obvious. | Med | existing deprecated v0.1 APIs, codemods, upgrade task | Finish the story around any still-supported legacy APIs so warnings are accurate, tested, and documented. |
| **Fail-fast compatibility checks** | Stable libraries catch misconfiguration and version drift early. | Med | publish checks, stability check task, docs checks | Extend current checks toward actionable failures: wrong sibling version pins, missing required docs, leaked internal types, unsupported config combinations. |

## Differentiators

Features that are not strictly required for `1.0`, but materially increase trust and reduce support load.

| Feature | Value Proposition | Complexity | Depends On | Notes |
|---------|-------------------|------------|------------|-------|
| **Contract-enforcement CI for public surface drift** | Turns the stability promise into a regression gate instead of maintainer memory. | Med | current `mix mailglass.stability.check`, exported-module list, API docs | Recommended scope: check public module/function/type inventory and known stable macro/config shapes. Avoid a brittle full AST ABI checker. |
| **Versioned “supported upgrade paths” document** | Anymail earns trust by being explicit about supported versions and pinning guidance. Mailglass should do the same for adopter upgrades and version floors. | Low | changelog, upgrade guides, install docs | Include supported source versions, required migrations, optional-dep caveats, and when to stay pinned. |
| **Golden example app matrix** | Strongest proof artifact for Hex adopters: install, mount admin, send mail, inspect operator UI, upgrade. | High | example app, CI buckets, release process | Better than synthetic unit tests alone because it exercises the adopter experience end to end. |
| **Stable “testing contract” guide for async and cross-process delivery** | Bamboo’s shared-mode caveat is a classic footgun. Mailglass can turn this into a trust advantage with one clear testing contract. | Low | `Mailglass.MailerCase`, `Mailglass.TestAssertions`, async adapter docs | Document exactly when to use inline, Oban manual, and global/shared test modes. |
| **Public/private boundary page for admin UI** | Least surprise for LiveView adopters: stable route/macro behavior, unstable internal DOM/component details. | Low | admin docs | Prevents users from depending on CSS/DOM internals and then calling normal UI refactors “breaking changes.” |

## Anti-Features

Things that would dilute or weaken a credible stability-lock milestone.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **New product-surface expansion** | Inbound, marketing, warmup, or workflow automation would turn a lock milestone into another beta expansion. | Keep focus on the transactional/admin core already shipped. |
| **A sweeping new abstraction layer** | Rewriting `Message`, adapters, or operator flows right before `1.0` destroys the point of the milestone. | Freeze the good surface and tighten contracts around it. |
| **Promise that every current behavior is forever stable** | Stable libraries distinguish public contract from internals. Promising LiveView DOM details, private modules, or incidental SQL shapes will trap maintenance. | Explicitly declare internals and reserve the right to change them in minors/patches. |
| **Heavyweight automated API-diff machinery** | A full ABI/AST compatibility framework is expensive, brittle, and high-maintenance for a one-maintainer library. | Add targeted enforcement around documented public surface, warnings, and upgrade smoke tests. |
| **Stability by docs only, with no verification** | A polished policy without CI proof reads as marketing. | Pair docs with smoke tests, contract checks, and release gates. |

## Milestone Shape Options

### 1. Minimal Stability Lock

**Shape**
- Finalize `api_stability.md`
- Publish a deprecation/compatibility policy
- Write a `v1.0` positioning and upgrade guide
- Do a release sweep across changelog, docs, and examples

**Pros**
- Fastest path to `1.0`
- Low implementation risk
- Good fit if maintainer capacity is extremely constrained

**Cons**
- Weakest proof story
- Higher chance of “1.0 in name, 0.x in practice” skepticism
- More support burden because regressions are caught socially, not mechanically

**Best for**
- A library that already has strong external references and broad adoption proof

### 2. Docs-Heavy Proof Milestone

**Shape**
- Everything in Minimal
- Add supported-upgrade-path docs and compatibility matrix
- Add fresh-install and previous-version upgrade smoke apps in CI
- Lock admin mount/config contract and testing contract docs
- Extend existing release/stability checks where they are already close to the problem

**Pros**
- Strong adopter-trust story without overbuilding tooling
- Maximizes least surprise and onboarding clarity
- Keeps maintenance cost reasonable for a one-person project

**Cons**
- More work than a pure docs sweep
- Still relies on some human judgment for API drift outside targeted checks

**Best for**
- Mailglass

### 3. Contract-Enforcement Milestone

**Shape**
- Everything in Docs-Heavy Proof
- Add manifest-driven public API drift detection
- Add warning/assertion coverage for deprecated paths
- Add stronger public/private classification checks for docs and code

**Pros**
- Best long-term regression resistance
- Most defensible “stable core” posture
- Reduces accidental breakage in future minors

**Cons**
- Highest engineering and maintenance cost
- Easy to overshoot into brittle tooling
- Risks spending the milestone on infrastructure instead of adopter trust artifacts

**Best for**
- Larger teams or libraries with multiple maintainers and frequent contributor churn

## Recommendation

Mailglass should choose **Shape 2: Docs-Heavy Proof Milestone**, while borrowing **two targeted elements** from Shape 3:

1. Extend the existing stability/release checks to cover the **documented public contract**.
2. Add **warning-backed verification** for any remaining deprecated entrypoints.

This is the best fit for the project arc. Mailglass already has unusually strong internals: `api_stability.md`, release checks, docs checks, custom Credo enforcement, sibling-package discipline, and a credible admin/operator surface. The missing piece for `v1.0` is not more product capability; it is converting that internal rigor into an adopter-visible trust contract with enough automated proof to be believable.

In practical terms, the milestone should feel like: **“we are freezing the core on purpose, proving upgrades/install/mount/testing work, and documenting exactly what is and is not part of the promise.”** That is stronger than a docs-only milestone and cheaper, more maintainable, and less distracting than a full compatibility framework.

## Recommended Requirement Buckets

Use these as the downstream feature categories for `REQUIREMENTS.md`.

### STAB-A: Stability Contract

- Public API inventory across `mailglass` and `mailglass_admin`
- Stable vs internal classification rules
- Versioning/deprecation policy
- Security/bugfix exception policy

### STAB-B: Upgrade and Adoption Proof

- Supported-upgrade-path matrix
- Fresh-install smoke path
- Previous-version upgrade smoke path
- Canonical `v1.0` upgrade guide

### STAB-C: Contract Enforcement

- Public API leak/drift checks
- Warning coverage for deprecated APIs
- Required docs/release artifact checks
- Sibling package version-link checks kept strict

### STAB-D: Developer Trust Surfaces

- Stable testing contract docs
- Stable admin mount/config contract docs
- Final positioning sweep clarifying scope and non-goals

## Feature Dependencies

```text
docs/api_stability.md + current exports
  -> Public API inventory
  -> Stable/internal classification

mix mailglass.stability.check + publish/docs checks
  -> Contract-enforcement CI
  -> Release gating for v1.0

Mailglass.MailerCase + Mailglass.TestAssertions + async adapter docs
  -> Stable testing contract

mailglass_admin router/auth/install surface
  -> Stable admin mount/config contract

existing changelog + upgrade task + install flow + example app
  -> Upgrade proof artifacts
```

## What Successful Projects Did Right

| Project | What they did right | Footgun they left adopters with | Mailglass takeaway |
|---------|---------------------|---------------------------------|--------------------|
| **Elixir** | Clear semver and staged deprecation policy. | None severe here; the lesson is discipline, not feature shape. | Borrow the deprecation cadence: document, warn, remove only on major. |
| **Django** | Explicit stable-vs-internal contract and narrow security exception. | Users still get burned when they depend on internals. | Document the public/private line for admin/UI internals. |
| **Anymail** | Semver, compatibility docs, long-lived ecosystem credibility, pinning guidance. | Optional/provider-specific dependency drift once caused accidental breakage. | Keep optional deps from leaking into core guarantees; be explicit about supported paths and pins. |
| **Swoosh** | Slim public API, documented telemetry, local preview/dev ergonomics. | Lower-level surface means adopters still assemble many production patterns themselves. | Keep Mailglass’s framework layer opinionated, but keep the public surface slim and documented. |
| **Bamboo** | Excellent test ergonomics and clear assertion helpers. | Cross-process/shared-mode testing surprises users. | Turn Mailglass async/Oban test semantics into a first-class documented contract. |
| **Rails Action Mailer** | Preview/testing/configuration are first-class, which builds confidence quickly. | Callbacks/interceptors/observers can multiply extension points and blur contract boundaries. | Avoid expanding hook/callback surface in the stability lock; prefer a smaller explicit contract. |
| **Oban / Oban Web** | Fail-fast startup checks and operator-facing tooling increase production trust. | Strong tooling can tempt more surface-area promises than maintainers want to support forever. | Stabilize admin mount/config and health checks, not every UI implementation detail. |

## MVP Recommendation

Prioritize:
1. **Public API and deprecation contract** across core and admin.
2. **Upgrade/install proof artifacts** in CI and docs.
3. **Targeted contract-enforcement checks** built on existing release/stability tooling.
4. **Testing/admin trust docs** so adopters know exactly what is stable.

Defer:
- Full manifest-driven compatibility tooling for every public symbol.
- Any new major product capability, provider family, or post-`v1.0` expansion.

## Sources

- Elixir compatibility and deprecations: https://hexdocs.pm/elixir/main/compatibility-and-deprecations.html
- Django API stability: https://docs.djangoproject.com/en/4.2/misc/api-stability/
- Anymail stable docs: https://anymail.dev/en/stable/index.html
- Anymail changelog: https://anymail.dev/en/latest/changelog.html
- Swoosh mailer docs: https://hexdocs.pm/swoosh/Swoosh.Mailer.html
- Swoosh local adapter/mailbox preview: https://hexdocs.pm/swoosh/Swoosh.html
- Bamboo test docs: https://hexdocs.pm/bamboo/Bamboo.Test.html
- Rails Action Mailer guide: https://guides.rubyonrails.org/action_mailer_basics.html
- Oban changelog: https://hexdocs.pm/oban/changelog.html
