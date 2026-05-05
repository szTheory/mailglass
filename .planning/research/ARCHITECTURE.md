# Architecture Research: v1.0 Stability Lock

**Project:** mailglass
**Domain:** Phoenix/Elixir transactional email library + sibling admin package
**Researched:** 2026-05-05
**Confidence:** HIGH

## Recommendation

Ship `v1.0` as an **explicit contract system**, not a policy memo and not a heavyweight compatibility framework.

For this repo, the right architecture is:

1. Keep the current contract-driven direction (`docs/api_stability.md`, support-contract tests, `mailglass.stability.check`).
2. Narrow the declared `v1.x` stable surface to the seams adopters and the sibling admin package actually need.
3. Mark everything else clearly internal in docs and module docs, even if it remains technically callable.
4. Add CI gates that prove the declared contract, instead of trying to infer “public API” from every exported module.

This is the least-surprising path for Elixir libraries: documented APIs are the promise, `@deprecated`/doc metadata carry migration intent, and changelog-driven minor releases introduce deprecations before any `v2.0` removal. Elixir’s documentation guidance treats docs as a user contract and explicitly warns that `@doc false` hides items from docs but does not make them private. SemVer requires the public API to be declared before `1.0.0`. That fits mailglass well because the repo already has a real contract document and contract tests rather than a purely social promise. Sources: [SemVer](https://semver.org/), [Elixir writing docs](https://hexdocs.pm/elixir/1.12/writing-documentation.html), [Elixir Module docs](https://hexdocs.pm/elixir/main/Module.html), [Elixir compatibility/deprecations](https://hexdocs.pm/elixir/main/compatibility-and-deprecations.html).

## Stable Seams for v1.x

Treat these as the **declared stable surface**. They should be documented, versioned, and CI-guarded.

### Core adopter contract

| Surface | Stability level | Notes |
|---------|-----------------|-------|
| `Mailglass` root verbs (`deliver*`) | Stable | Primary entrypoint. Keep names, arities, and return shapes stable through `v1.x`. |
| `Mailglass.Message` | Stable | Struct fields, public setters, and documented escape hatches are adopter-facing API. Additive fields only in `v1.x`. |
| `Mailglass.Mailable` | Stable | `use` opts, injected functions, overridable callbacks, and `preview_props/0` optional callback are part of the contract. |
| `Mailglass.Outbound.Delivery` | Stable | Result struct and documented status/error semantics are relied on by adopters and admin. |
| `Mailglass.Error*` structs | Stable | Closed atom sets, shared fields, and pattern-match guidance are already contract material. |
| `Mailglass.Config` documented keys/accessors | Stable | Freeze documented config keys and accessor semantics; additions may be minor releases if optional/defaulted. |
| `Mailglass.Adapter` | Stable | Third-party adapter seam. Callback signatures and return shape are load-bearing. |
| `Mailglass.Tenancy` | Stable | Callback signatures and documented context maps are public extension points. |
| `Mailglass.Router` | Stable | Public router macro contract. Options and route semantics must remain compatible in `v1.x`. |
| `Mailglass.Compliance.Unsubscribe` | Stable | Token and URL-generation helpers are adopter-facing. |
| `Mailglass.Tracking` documented helpers | Stable | Keep documented function semantics and token contracts stable. |
| Telemetry event names documented for adopters | Stable | Event names and required metadata keys should not churn in `v1.x`. Additive metadata is fine. |
| Mix tasks documented in README/guides | Stable | `mailglass.install`, `mail.doctor`, generators, and upgrade tasks are user workflow contract. |

### Sibling admin integration contract

| Surface | Stability level | Notes |
|---------|-----------------|-------|
| `MailglassAdmin.Router` macros | Stable | These are the real admin integration seam. Freeze options, route shape, and session whitelist semantics. |
| `MailglassAdmin.Auth` behaviour | Stable | Callback result shape is the authorization contract. |
| `Mailglass.Operator.*` read models consumed by `mailglass_admin` | Stable but narrow | Freeze inputs/outputs used by the admin package. Do **not** broaden into a generic reporting API. |
| `Mailglass.Operator.SupportSummary` | Stable but narrow | Support/incident contract is valuable proof surface; keep semantics stable. |

### Persistence/runtime contract

| Surface | Stability level | Notes |
|---------|-----------------|-------|
| Generated migration API (`Mailglass.Migration`, migration generator) | Stable | Adopters need predictable setup/upgrade behavior. |
| Core persisted concepts | Stable | `deliveries`, `events`, `suppressions`, append-only ledger semantics, tenancy semantics. |
| Table internals | Additive-only | New columns/indexes/triggers are fine in `v1.x`; renames/drops/meaning changes are not. |

## Keep Internal

These should remain explicitly internal, even if some stay public for technical reasons.

| Surface | Why it should stay internal |
|---------|-----------------------------|
| `Mailglass.Webhook.Provider` and provider implementations | The repo already treats this as sealed. Freezing it would lock provider internals too early. |
| `Mailglass.Webhook.Ingest`, caches, reconciler internals | Operational internals that need refactor freedom. |
| `Mailglass.Outbound.Projector` | Important implementation detail, but not a user seam. |
| `Mailglass.Repo` internals | Translation and transaction plumbing should stay maintainers-only. |
| `Mailglass.Renderer` internals beyond documented entrypoints | Rendering behavior matters; internal module decomposition does not. |
| `MailglassAdmin` LiveViews/components/controllers/assets internals | DOM shape, assigns, CSS asset names, and internal event handling should not become compatibility promises. |
| Support/admin UI markup | Useful to test functionally, not a public library API. |
| CI alias names that are not documented as user workflows | Maintainer ergonomics, not adopter contract. |

Practical rule: if a module exists primarily because one mailglass package calls another mailglass package, document it as **internal sibling-package API** unless adopters are meant to build against it directly.

## Contract Boundaries to Make Explicit

### 1. Public API boundary

Use `docs/api_stability.md` as the authoritative contract index for `mailglass`, and add a matching `mailglass_admin` section or sibling doc for:

- stable modules
- stable structs and fields
- stable callbacks
- stable config keys
- stable telemetry names
- stable mix tasks
- explicitly internal modules

Do not rely on Boundary exports alone. Boundary is an enforcement aid, not the public API definition.

### 2. Admin/runtime boundary

Keep the admin package contract narrow:

- `MailglassAdmin.Router` owns mounting and session whitelisting
- `MailglassAdmin.Auth` owns adopter authorization
- `Mailglass.Operator.*` owns read-model/service queries used by admin

Do **not** freeze:

- LiveView event names
- socket assigns
- component modules
- CSS/JS asset names
- HTML structure

That matches Phoenix/Plug practice: stable router and behaviour seams, flexible internals.

### 3. Compatibility boundary

Promise compatibility at the level adopters can reasonably depend on:

- documented module/function names and arities
- documented struct fields
- documented callback signatures
- documented error/type atoms
- documented route macros and options
- documented telemetry events
- documented DB invariants and generated migration workflow

Do **not** promise compatibility for:

- undocumented exported helpers
- private query composition details
- raw provider payload shapes
- internal event metadata keys not documented as public
- internal admin DOM or CSS hooks

## Deprecation Policy

Use one policy across core and admin packages:

1. `v1.x` minor releases may **add** API and may **deprecate**, but may not remove or silently repurpose documented contract surface.
2. Any deprecation must include:
   - `@deprecated` for functions/macros that should emit warnings
   - `@doc deprecated:` metadata for modules/types/callbacks where warning emission is unavailable or undesirable
   - changelog entry
   - upgrade note with replacement
   - contract test coverage for both old and new path while the deprecation lives
3. Removal waits until `v2.0`, except for security fixes or severe correctness issues.
4. Deprecated surface should survive **at least one minor release** before removal; for mailglass, the better practical promise is “survives the entire `v1.x` line unless security/correctness forces earlier action.”

This mirrors mature Elixir ecosystem behavior: deprecations are introduced in minors with docs and warnings, not surprise removals. Sources: [Elixir Module docs](https://hexdocs.pm/elixir/main/Module.html), [Plug changelog](https://hexdocs.pm/plug/changelog.html), [Phoenix changelog](https://hexdocs.pm/phoenix/changelog.html), [Ecto changelog](https://hexdocs.pm/ecto/changelog.html).

## Upgrade Guarantees for v1.x

Publish these guarantees explicitly:

- **Patch releases:** no breaking API/config/schema changes; bug fixes only.
- **Minor releases:** additive config/API/schema changes only; deprecated APIs remain available.
- **Core database contract:** no destructive migration required for normal minor upgrades; schema evolution is forward-additive.
- **Admin contract:** existing `mailglass_admin` mounts and auth behaviour continue to work across `v1.x`.
- **Provider compatibility:** provider additions are additive; existing provider configuration and normalized event semantics remain stable.
- **Observability:** documented telemetry event names remain stable for `v1.x`.

## Approach Comparison

| Approach | Pros | Cons | Recommendation |
|---------|------|------|----------------|
| Policy-only | Cheap, fast | Too easy to drift; no proof artifact; users cannot tell what is actually frozen | Reject |
| Tests + policy | Better than social contract; low tooling cost | Still ambiguous unless the contract surface is written down precisely | Accept only as a baseline |
| Explicit public-contract docs + contract tests + CI gates | Clear public surface, real proof, fits existing repo direction | Slightly more maintenance | **Choose this** |

Mailglass is already closer to the third model than the first two. `v1.0` should complete that move rather than invent a new mechanism.

## New vs Modified Repo Surfaces

### Modify

- `docs/api_stability.md`
  Expand from “closed sets + selected APIs” into the authoritative `v1.x` contract map.
- module docs on public entrypoints
  Make stable/internal intent explicit.
- existing support-contract tests
  Retarget them as `v1.x` contract proof, not only milestone proof.
- existing `mailglass.stability.check`
  Keep as a focused leak guard; extend only where it catches real regressions.

### Add

- `docs/upgrading.md` or `UPGRADING.md`
  Single place for deprecations and migration guidance.
- `docs/admin_contract.md` or a `mailglass_admin` section in stability docs
  Router/auth/runtime contract for the sibling package.
- `mix verify.stability` aliases in both packages
  Aggregate contract tests into one obvious gate.
- a checked-in “stable surface inventory”
  Lightweight, human-reviewed list of stable modules/functions/structs. Do not build a full semantic AST diff engine.

## Suggested CI/Proof Artifacts

Keep proof simple and reviewable:

1. **Contract docs**: `docs/api_stability.md` plus admin contract doc.
2. **Contract tests**:
   - closed-set tests for atoms/enums
   - return-shape tests for root entrypoints
   - router macro compile tests
   - auth behaviour normalization tests
   - upgrade smoke tests for deprecated paths
3. **Static checks**:
   - `mailglass.stability.check`
   - no-doc-leak check for internal modules meant to stay hidden
   - boundary checks
4. **Release proof**:
   - `mix hex.package diff mailglass <last_version>..<new_version>` and equivalent for `mailglass_admin` as release-review artifact, not per-PR CI

Lesson from adjacent ecosystems: Rust’s `cargo-semver-checks` shows the value of CI-enforced compatibility, but Elixir lacks an equally mature first-party equivalent. Mailglass should copy the principle, not the complexity: explicit contract plus focused CI checks is enough for `v1.0`. Source: [Cargo semver compatibility](https://doc.rust-lang.org/cargo/reference/semver.html), [Hex package diff](https://hexdocs.pm/hex/Mix.Tasks.Hex.Package.html).

## Build Order

1. **Declare the boundary**
   - update `docs/api_stability.md`
   - add admin contract doc
   - classify modules as stable or internal
2. **Align code to the boundary**
   - add/clean `@deprecated`, `@doc deprecated:`, `@doc false`, `@moduledoc false`
   - stop documenting modules that should not be public contract
3. **Add proof**
   - core stability verify alias
   - admin stability verify alias
   - contract tests for stable seams only
4. **Publish upgrade story**
   - `UPGRADING.md`
   - changelog/deprecation policy
5. **Freeze release discipline**
   - release checklist includes package diff and contract-gate pass

## Risks to Avoid

### Freezing too broadly

- Treating every exported module as `v1.x` contract
- Freezing admin DOM/component internals
- Freezing webhook/provider internals
- Freezing support-query implementation details instead of their service outputs

This would make normal refactoring feel like a major-version event.

### Freezing too narrowly

- Only promising `Mailglass.deliver/2`
- Leaving config, structs, telemetry, and admin router/auth behavior implicit
- Saying operator read models are internal while `mailglass_admin` depends on them as real package seams

This would make `1.0` feel ceremonial instead of trustworthy.

## Practical Path for This Repo

For mailglass specifically, the cohesive direction is:

- **Stable in `v1.x`:** root send API, message/mailable/adapter/tenancy/config contracts, documented error and event atoms, router macros, admin router/auth seam, operator read-model outputs consumed by `mailglass_admin`, documented telemetry names, generated migration workflow.
- **Internal in `v1.x`:** provider internals, renderer/projector/repo plumbing, admin LiveView/component structure, undocumented helpers, internal CI plumbing.
- **Policy:** deprecate in minors, remove in `v2.0` only, except security/correctness.
- **Proof:** docs + contract tests + focused CI gates + release-time package diff.

That gives maintainers room to keep the engine flexible while giving adopters the thing `v1.0` is supposed to mean: a clear, durable contract they can safely build on.

## Sources

- SemVer: https://semver.org/
- Elixir docs, writing docs: https://hexdocs.pm/elixir/1.12/writing-documentation.html
- Elixir `Module` docs (`@deprecated`, doc metadata): https://hexdocs.pm/elixir/main/Module.html
- Elixir compatibility/deprecations: https://hexdocs.pm/elixir/main/compatibility-and-deprecations.html
- Hex publishing docs: https://hex.pm/docs/publish
- Hex package diff task: https://hexdocs.pm/hex/Mix.Tasks.Hex.Package.html
- Plug router docs: https://hexdocs.pm/plug/Plug.Router.html
- Plug changelog: https://hexdocs.pm/plug/changelog.html
- Phoenix changelog: https://hexdocs.pm/phoenix/changelog.html
- Ecto changelog: https://hexdocs.pm/ecto/changelog.html
- Cargo SemVer compatibility: https://doc.rust-lang.org/cargo/reference/semver.html
