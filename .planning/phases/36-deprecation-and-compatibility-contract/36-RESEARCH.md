# Phase 36: Deprecation and Compatibility Contract - Research

**Researched:** 2026-05-05
**Domain:** Elixir/Hex library compatibility, deprecation, and upgrade-contract policy
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-36-01:** Publish one canonical root compatibility guide separate from the
  stability inventories. Keep `docs/api_stability.md` and
  `mailglass_admin/docs/api_stability.md` focused on stable/internal surface
  inventory; they should point to the compatibility guide rather than absorb
  support policy, upgrade steps, and deprecation rules.
- **D-36-02:** README, admin README, maintainers docs, and ExDoc extras should
  all point to the same canonical compatibility guide instead of carrying
  partially independent policy text.

### Support matrix posture
- **D-36-03:** The support matrix should be narrow, semantic, and honest rather
  than aspirational. Document supported floors and tested lanes, not a large
  combinatorial matrix the repo does not prove.
- **D-36-04:** The documented `1.x` runtime/support posture should align with
  current package metadata and project boundaries:
  - Elixir `~> 1.18`
  - OTP `27+`
  - Phoenix `~> 1.8`
  - Phoenix LiveView `~> 1.1`
  - Ecto / Ecto SQL `~> 3.13`
  - Postgres 14+
- **D-36-05:** Postgres-only remains part of the compatibility contract.
  `mailglass` should not imply support for broader database/runtime
  combinations just because adjacent libraries are broader.
- **D-36-06:** `mailglass_admin` should be documented as a matched sibling, not
  an independently drifting package. Matching release lines are required, and
  publish-time exact pinning remains the source of truth for released package
  compatibility.
- **D-36-07:** `mailglass_inbound` remains outside the `v1.x` compatibility
  promise for this milestone.
- **D-36-08:** Optional dependencies should be documented as supported
  integration lanes when present, while the core compile/support contract stays
  green without them. Do not elevate optional third-party ecosystems to equal
  weight with the core stable contract.

### Stable lane vs compatibility lane
- **D-36-09:** The canonical `1.x` adopter-facing API posture is
  Message-first and root-entrypoint-first:
  - `Mailglass.deliver*`
  - native `Mailglass.Message` setters
  - `Mailglass.Message.update_swoosh/2` as the one blessed advanced Swoosh
    escape hatch
- **D-36-10:** Phase 36 should define two distinct lanes:
  - **Stable lane**: the documented `1.x` front door
  - **Compatibility lane**: a small, explicitly bounded set of retained legacy
    bridges that exist to make `0.x -> 1.0` upgrades low-friction
- **D-36-11:** The compatibility lane should stay small and non-expanding after
  `1.0`. It exists to ease adoption, not to freeze every reachable historical
  surface.
- **D-36-12:** `Mailglass.Outbound.send/2` must stop living in an ambiguous
  half-public state. Downstream work should treat it as a legacy compatibility
  bridge, not as part of the preferred stable front door. Root `Mailglass`
  delivery verbs remain canonical.

### Deprecation policy
- **D-36-13:** No documented adopter-facing API deprecated in `1.x` should be
  removed before `v2.0`, except for narrow security, data-loss, signature
  verification, or severe correctness emergencies that are explicitly called
  out in release notes.
- **D-36-14:** Every deprecated or legacy-supported path must have a documented
  replacement. “Supported” without a replacement path is not acceptable in the
  `1.x` compatibility contract.
- **D-36-15:** Distinguish two kinds of retained old paths in docs:
  - **Deprecated (warning-emitting)**: supported through `1.x`, but expected
    to break strict consumer builds that run with `--warnings-as-errors`
  - **Legacy supported alias/path (non-warning)**: old path still works
    silently, has a documented replacement, and must carry an explicit support
    horizon no earlier than `v2.0`
- **D-36-16:** Warning behavior should be documented honestly per path.
  Downstream docs should say whether a retained path is compiler-warning,
  task-warning, docs-only, or silent. Do not flatten these into one generic
  “deprecated but supported” bucket.
- **D-36-17:** Patch releases should avoid introducing new deprecations except
  for security/correctness emergencies. Minor releases may add deprecations but
  should not remove documented deprecated APIs.

### Upgrade-path shape
- **D-36-18:** Publish one canonical “latest released `0.x` -> `1.0`” guide.
  Existing guides such as `guides/upgrading-from-v0_1.md` and
  `guides/migration-from-swoosh.md` should become subordinate step references,
  not the whole upgrade story.
- **D-36-19:** The canonical upgrade guide should explicitly name:
  - legacy entrypoints that remain acceptable through `1.x`
  - legacy entrypoints that should be migrated immediately for strict CI users
  - required code changes
  - expected warning behavior
  - matched-version sibling-package expectations
- **D-36-20:** The codemod and transitional migration tasks remain useful
  tooling, but they should not be accidentally promoted into long-term stable
  contract surface.

### Strict-CI and DX posture
- **D-36-21:** Warnings-as-errors adopters are a first-class audience in this
  phase. The compatibility contract should explicitly tell them which retained
  paths are effectively unsafe for new code because they emit warnings under
  strict compile/test settings.
- **D-36-22:** Do not add clever new warning infrastructure just to simulate a
  larger compatibility story. Favor honest docs, small inventories, and light
  enforcement checks over maintainability-heavy warning systems.
- **D-36-23:** Phase 37 should inherit a proof shape that validates a
  deprecation-DX inventory: surface, replacement, warning channel,
  `--warnings-as-errors` impact, support-until version, and proof artifact.

### Recommendation-first downstream posture
- **D-36-24:** Downstream research, planning, and execution for compatibility,
  deprecation, release, and trust-doc phases should default to one-shot,
  recommendation-first synthesis. Re-open choices only when they materially
  affect public contract, maintainer support burden, or user trust semantics.
- **D-36-25:** For this phase, downstream agents should prefer the narrowest
  honest compatibility promise that preserves smooth upgrades from the latest
  real `0.x` line.

### the agent's Discretion
- Exact canonical guide filename and section ordering.
- Exact wording for the support matrix and exception clauses, as long as they
  remain narrow, explicit, and truthful.
- Exact doc/test/check locations used to enforce the deprecation-DX inventory.
- Exact handling of maintainer-facing `verify.phase_*` aliases, as long as
  their support horizon and audience are documented honestly.

### Deferred Ideas (OUT OF SCOPE)
- Broad runtime matrix expansion beyond the documented floors actually proven by
  CI and release rehearsal.
- Making optional third-party integrations first-class equal-weight guarantees
  inside the `1.x` stable contract.
- Adding heavyweight runtime deprecation telemetry or custom warning systems.
- Stabilizing every currently reachable legacy/transitional surface instead of
  keeping a small explicit compatibility lane.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| COMPAT-01 | Adopter can read one canonical `1.x` versioning and deprecation policy that explains patch, minor, and major guarantees plus security/correctness exceptions. | Canonical guide, two-lane policy, and exception clause recommendations below define the single source of truth. |
| COMPAT-02 | Adopter can read one support matrix covering runtime floors, Phoenix/Postgres scope, sibling-package expectations, and optional-dependency support lanes. | Repo-backed support matrix recommendation uses `mix.exs`, `mailglass_admin/mix.exs`, CI lanes, and support-contract scripts already present. |
| COMPAT-03 | Adopter can follow a canonical `0.x -> 1.0` upgrade guide that covers remaining legacy entrypoints, required code changes, and expected warning behavior. | Upgrade-guide recommendation consolidates the existing v0.1->v0.2 and raw-Swoosh guides under one `0.x -> 1.0` path. |
| COMPAT-04 | Maintainer can verify that any still-supported deprecated path has a documented replacement, warning behavior where possible, and no planned removal before `v2.0`. | Deprecation-DX inventory, docs checks, and compiled-doc/test extensions define the proof shape. |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- `mailglass`, `mailglass_admin`, and `mailglass_inbound` are sibling Hex packages, and `mailglass_inbound` is still out of the `v1.0` scope. [VERIFIED: repo grep]
- The project is Phoenix-first, Postgres-only, and explicitly excludes broad compatibility-matrix expansion. [VERIFIED: repo grep]
- Errors are a public API contract, telemetry must avoid PII, optional dependencies must compile cleanly under `mix compile --no-optional-deps --warnings-as-errors`, and custom Credo checks enforce domain rules. [VERIFIED: repo grep]
- Recommendation-first, honest-surface, and warnings-as-errors ergonomics are explicit project methodology, not optional style preferences. [VERIFIED: repo grep]

## Summary

Phase 36 should publish one canonical compatibility guide and treat every other adopter-facing document as a pointer to that guide, because the repo already has separate core/admin stability inventories and already uses docs drift checks to protect Tier 1 wording. [VERIFIED: repo grep]

The repo already exposes real compatibility seams that need classification rather than invention: `Mailglass.Message.new/2` is compiler-deprecated, raw `%Swoosh.Email{}` delivery is still supported through `Mailglass.Outbound.send/2` and `Mailglass.deliver/2`, the v0.2 codemod is a transitional Mix task, exact `mailglass_admin` sibling pinning is enforced at publish time, and deprecated `verify.phase_*` aliases still exist for one release cycle. [VERIFIED: repo grep]

The external policy baseline is clear: SemVer requires an explicit public API and at least one minor release with deprecation before major-version removal, Elixir reserves compatibility exceptions for security/bug/compiler-warning/import cases and removes deprecated features only on a major line, and Mix/Hex explicitly distinguish optional dependencies plus the `--no-optional-deps --warnings-as-errors` validation lane. [CITED: https://semver.org/] [CITED: https://hexdocs.pm/elixir/1.18.0/compatibility-and-deprecations.html] [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html]

**Primary recommendation:** Ship `guides/compatibility-and-deprecations.md` as the canonical `1.x` policy, keep the stable lane small (`Mailglass.deliver*`, native `Mailglass.Message` setters, `update_swoosh/2`), keep the compatibility lane explicit and non-expanding, and prove it with docs/tests instead of new runtime warning machinery. [VERIFIED: repo grep] [CITED: https://hexdocs.pm/elixir/1.18.0/compatibility-and-deprecations.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Canonical `1.x` policy publication | Docs / ExDoc | Repo root docs | The contract is consumed through guides, README links, and generated docs rather than runtime behavior. [VERIFIED: repo grep] |
| Runtime floor and support matrix truth | `mix.exs` / `mailglass_admin/mix.exs` metadata | CI | Floors and sibling pinning already live in package metadata and are only honest if CI proves the documented lanes. [VERIFIED: repo grep] |
| Deprecated-path classification | Source docs and upgrade guides | Tests/checks | Warning behavior and replacements come from code annotations plus docs, while trust comes from checks such as `Code.fetch_docs/1` tests and docs drift checks. [VERIFIED: repo grep] [CITED: https://hexdocs.pm/elixir/1.15.8/writing-documentation.html] |
| Strict-CI adopter guidance | Canonical guide | CI/support-contract scripts | The repo already treats `--warnings-as-errors` and `--no-optional-deps` as contract truth, so the guide must explain those semantics directly. [VERIFIED: repo grep] [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html] |
| Upgrade-path proof | Migration smoke tests | Maintainer runbook | Existing migration and docs smoke tests already model the proof surface that should back the `0.x -> 1.0` path. [VERIFIED: repo grep] |

## Standard Stack

### Core

| Library / Artifact | Version | Purpose | Why Standard |
|--------------------|---------|---------|--------------|
| Elixir | `~> 1.18` floor in both packages | Public runtime floor for the `1.x` contract | Both package manifests already declare this floor, so the support matrix should repeat it rather than invent a broader claim. [VERIFIED: repo grep] |
| Phoenix | `~> 1.8` | Supported framework scope | Root README and both `mix.exs` files already frame Phoenix 1.8 as the supported line. [VERIFIED: repo grep] |
| Phoenix LiveView | `~> 1.1` | Admin/preview support scope | Root README and `mailglass_admin/mix.exs` already align on LiveView 1.1. [VERIFIED: repo grep] |
| Ecto / Ecto SQL | `~> 3.13` | Data-layer support floor | The repo requires Ecto 3.13 and uses Postgres features that make broader DB promises dishonest. [VERIFIED: repo grep] |
| PostgreSQL | `14+` documented floor | Storage support scope | The root README already documents Postgres 14+, and the project scope remains Postgres-only. [VERIFIED: repo grep] |
| ExDoc + compiled docs metadata | `ex_doc ~> 0.40` and `Code.fetch_docs/1` | Point-of-use `since` / deprecation truth and proof | ExDoc surfaces `since`/`deprecated` metadata, and Elixir documents `Code.fetch_docs/1` as the bytecode source for those docs. [VERIFIED: repo grep] [CITED: https://hexdocs.pm/elixir/1.15.8/writing-documentation.html] |

### Supporting

| Library / Artifact | Version | Purpose | When to Use |
|--------------------|---------|---------|-------------|
| Igniter codemod task | `igniter ~> 0.7` | Transitional v0.2 codemod | Keep it as upgrade tooling in the compatibility lane, not as stable front-door API. [VERIFIED: repo grep] |
| `mix mailglass.docs.check` | local task | Tier 1 wording drift check | Extend it to require compatibility-guide links/tokens and to forbid stale package/version language. [VERIFIED: repo grep] |
| `test/mailglass/docs_migration_smoke_test.exs` | local test | Upgrade-guide executable proof | Extend it to cover the canonical `0.x -> 1.0` path and strict-CI notes. [VERIFIED: repo grep] |
| `test/mailglass/stability_contract_test.exs` and admin counterpart | local tests | Compiled-doc truth for stable/deprecated surfaces | Reuse the `Code.fetch_docs/1` pattern for the deprecation-DX inventory. [VERIFIED: repo grep] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| One canonical compatibility guide | Split policy text across README, admin README, MAINTAINING, and stability docs | The repo already uses docs-token enforcement and separate stability inventories, so duplicated policy text would drift quickly. [VERIFIED: repo grep] |
| Narrow tested support matrix | Broad framework/database matrix | The repo only proves one Elixir/Phoenix/Postgres lane plus optional-dep compilation, so a broader matrix would be aspirational rather than honest. [VERIFIED: repo grep] |
| Docs + metadata + light checks | New custom runtime warning/deprecation subsystem | Elixir already distinguishes docs-only deprecation metadata from compiler warnings, and the methodology explicitly rejects heavy warning machinery for this phase. [CITED: https://hexdocs.pm/elixir/1.15.8/writing-documentation.html] [VERIFIED: repo grep] |
| Exact sibling-line promise | Independent admin compatibility story | `mailglass_admin` already pins exact core versions at publish time, so pretending the package drifts independently would contradict shipped behavior. [VERIFIED: repo grep] |

**Version verification:** Phase 36 should use the repo-declared floors and pins already present in [`mix.exs`](/Users/jon/projects/mailglass/mix.exs:4) and [`mailglass_admin/mix.exs`](/Users/jon/projects/mailglass/mailglass_admin/mix.exs:4), because this phase is defining the compatibility promise for this repo rather than selecting new dependency versions. [VERIFIED: repo grep]

## Architecture Patterns

### System Architecture Diagram

```text
Repo metadata + source docs
    |
    v
Canonical compatibility guide
    |
    +--> README / mailglass_admin README pointers
    |
    +--> MAINTAINING release-policy pointer
    |
    +--> ExDoc extras / HexDocs navigation
    |
    +--> 0.x -> 1.0 upgrade guide
    |
    v
Docs drift checks + compiled-doc tests + migration smoke
    |
    v
Support-contract CI + release rehearsal inputs
```

### Recommended Project Structure

```text
guides/
├── compatibility-and-deprecations.md   # Canonical 1.x policy and support matrix
├── upgrading-to-v1_0.md                # Canonical latest-0.x -> 1.0 path
├── upgrading-from-v0_1.md              # Subordinate step reference
└── migration-from-swoosh.md            # Subordinate parity/escape-hatch reference

docs/
├── api_stability.md                    # Stable/internal core inventory
└── ...                                 # Other stable docs remain focused

mailglass_admin/
└── docs/api_stability.md               # Stable/internal admin inventory
```

### Pattern 1: Canonical Guide + Pointer Model

**What:** Put versioning, deprecation, support-matrix, sibling-package, and exception policy in one canonical guide, and make README/admin README/MAINTAINING/ExDoc point to it rather than restating it. [VERIFIED: repo grep]

**When to use:** Always for adopter-facing compatibility policy in this repo, because Phase 35 already established separate stable-surface inventories and the docs checker already protects pointer docs. [VERIFIED: repo grep]

**Example:**

```elixir
@doc since: "1.3.0"
@deprecated "Use Foo.bar/2 instead"
```

Source: Elixir documentation metadata guidance. [CITED: https://hexdocs.pm/elixir/1.15.8/writing-documentation.html]

### Pattern 2: Two-Lane Contract

**What:** Define a stable lane for preferred `1.x` APIs and a compatibility lane for retained legacy paths, with each compatibility item carrying `replacement`, `warning_channel`, `strict_ci_impact`, `support_until`, and `proof_artifact`. [VERIFIED: repo grep] [CITED: https://hexdocs.pm/elixir/1.18.0/compatibility-and-deprecations.html]

**When to use:** For every adopter-reachable legacy path that still exists in code or docs, especially `Mailglass.Message.new/2`, raw `%Swoosh.Email{}` delivery, and deprecated `verify.phase_*` aliases. [VERIFIED: repo grep]

**Example inventory shape:**

```text
surface: Mailglass.Message.new/2
replacement: native Mailglass.Message setters
warning_channel: compiler (@deprecated)
strict_ci_impact: breaks with --warnings-as-errors
support_until: v2.0
proof_artifact: compiled-doc test + upgrade-guide mention
```

### Pattern 3: Repo-Proven Support Matrix

**What:** Document supported floors, tested CI lanes, matched sibling-package expectations, and optional-dependency posture, but avoid claiming a combinatorial matrix the repo does not exercise. [VERIFIED: repo grep] [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html]

**When to use:** For COMPAT-02 support documentation and all future release-trust docs. [VERIFIED: repo grep]

**Example:** Mix recommends validating optional dependencies with `mix compile --no-optional-deps --warnings-as-errors`, and this repo already runs that lane in CI and in `scripts/verify_support_contract.sh`. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html] [VERIFIED: repo grep]

### Anti-Patterns to Avoid

- **Compatibility policy inside `docs/api_stability.md`:** Phase 35 intentionally scoped those files to stable/internal inventory, so adding support policy there would conflate surface classification with lifecycle rules. [VERIFIED: repo grep]
- **Hard-deprecating every old path immediately:** Elixir's model distinguishes soft documentation deprecation from hard warning emission, and the project methodology explicitly prioritizes strict-CI ergonomics. [CITED: https://hexdocs.pm/elixir/1.18.0/compatibility-and-deprecations.html] [VERIFIED: repo grep]
- **Patch-release warning surprises:** New compiler warnings can break downstream builds under `--warnings-as-errors`, so patch releases should reserve new deprecations for emergency exceptions only. [CITED: https://hexdocs.pm/elixir/1.18.0/compatibility-and-deprecations.html]
- **Treating raw `%Swoosh.Email{}` parity as a forever-stable front door:** The current repo only documents it as migration parity, while the preferred lane is Message-first and root-entrypoint-first. [VERIFIED: repo grep]

## Plan Recommendations

### Recommended Canonical Files

- Add `guides/compatibility-and-deprecations.md` as the single canonical `1.x` policy page. [VERIFIED: repo grep]
- Add `guides/upgrading-to-v1_0.md` as the single canonical latest-`0.x` to `1.0` path, with `guides/upgrading-from-v0_1.md` and `guides/migration-from-swoosh.md` reduced to subordinate references. [VERIFIED: repo grep]
- Add both new guides to ExDoc extras in the root package, and point `README.md`, `mailglass_admin/README.md`, `docs/api_stability.md`, `mailglass_admin/docs/api_stability.md`, and `MAINTAINING.md` at them. [VERIFIED: repo grep]

### Recommended Compatibility Lane Inventory

| Surface | Recommended Classification | Replacement | Warning Channel | `--warnings-as-errors` Impact | Support-Until | Proof Shape |
|---------|----------------------------|-------------|-----------------|------------------------------|---------------|-------------|
| `Mailglass.Message.new/2` | Deprecated compatibility path | Native `Mailglass.Message` setters or `new_from_use/2` path | Compiler warning via existing `@deprecated` | Unsafe for strict CI in new code | `v2.0` earliest | `Code.fetch_docs/1` test + canonical guide + upgrade guide. [VERIFIED: repo grep] |
| Raw `%Swoosh.Email{}` passed to `Mailglass.deliver/2` | Legacy-supported compatibility path | `Mailglass.Message` and `Mailglass.Mailable` | Silent at compiler level; docs-only caution | Safe to compile, but not preferred for new code | `v2.0` earliest | Migration smoke test + guide wording. [VERIFIED: repo grep] |
| `Mailglass.Outbound.send/2` | Legacy-supported compatibility bridge, not preferred front door | `Mailglass.deliver/2` | Currently silent; document as compatibility-only unless Phase 36 explicitly changes it | Safe today, but should be documented as non-canonical | `v2.0` earliest | docs/stability check exemptions + compatibility inventory. [VERIFIED: repo grep] |
| `mix mailglass.upgrade.v0_2` | Transitional upgrade tool, not stable front-door API | Canonical `0.x -> 1.0` guide | Task/runtime warnings for ambiguous cases | N/A | No removal before `v2.0` if still documented | docs migration smoke + guide references. [VERIFIED: repo grep] |
| `verify.phase01`, `verify.phase_01`, `verify.phase_02`, `verify.phase_03`, `verify.phase_04`, `verify.phase_05`, `verify.phase_07` | Maintainer-facing deprecated aliases | Semantic `verify.*` aliases | Silent aliasing today; docs-only deprecation unless changed later | Safe internally, but should not appear in adopter docs | One release cycle as already commented in repo | docs check forbids stale mention in adopter docs. [VERIFIED: repo grep] |

### Recommended Canonical Support Matrix

| Topic | Recommendation | Evidence |
|------|----------------|----------|
| Elixir floor | Support `~> 1.18`; document local development on newer Elixir as non-contract unless CI expands. | Both packages declare `elixir: "~> 1.18"`, while CI only proves Elixir 1.18 / OTP 27. [VERIFIED: repo grep] |
| OTP floor | Support OTP `27+`; do not promise OTP 28 behavior until CI expands. | README says `27+`, but CI is pinned to OTP 27 and Elixir's own compatibility policy shows patch/minor support nuances across OTP lines. [VERIFIED: repo grep] [CITED: https://hexdocs.pm/elixir/1.18.0/compatibility-and-deprecations.html] |
| Phoenix scope | Support `~> 1.8` only. | Repo manifests and README agree on Phoenix 1.8. [VERIFIED: repo grep] |
| LiveView scope | Support `~> 1.1` where `mailglass_admin` is involved. | Repo manifests and README agree on LiveView 1.1. [VERIFIED: repo grep] |
| Ecto / DB scope | Support `Ecto/Ecto SQL ~> 3.13` and Postgres 14+ only. | Repo metadata and root README already document this. [VERIFIED: repo grep] |
| `mailglass_admin` compatibility | Promise matched release lines only, with exact core pin at publish time. | `mailglass_admin/mix.exs` publishes `{:mailglass, "== 0.3.2"}` today. [VERIFIED: repo grep] |
| `mailglass_inbound` | Explicitly out of the `1.x` promise. | README, roadmap, and context all exclude it. [VERIFIED: repo grep] |
| Optional dependencies | Document them as supported integration lanes when present, while core compile/support truth remains the no-optional-deps lane. | Mix documents optional-dependency semantics and explicitly recommends a no-optional-deps warnings-as-errors compile lane, which this repo already runs. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html] [VERIFIED: repo grep] |

### Likely Plan Slices

1. **Canonical docs slice:** add the root compatibility guide and root `0.x -> 1.0` upgrade guide; update README/admin README/MAINTAINING/stability docs/ExDoc navigation to point at them. [VERIFIED: repo grep]
2. **Compatibility inventory slice:** classify each retained compatibility surface, document its replacement/warning/support-until semantics, and make strict-CI guidance explicit. [VERIFIED: repo grep]
3. **Proof slice:** extend `mix mailglass.docs.check`, `test/mailglass/docs_contract_test.exs`, `test/mailglass/docs_migration_smoke_test.exs`, and stability-contract tests or add a dedicated `compatibility_contract_test.exs` to prove the deprecation-DX inventory. [VERIFIED: repo grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Deprecation lifecycle semantics | Custom policy unrelated to Elixir/Hex norms | SemVer + Elixir compatibility/deprecation posture | The official ecosystem already defines public-API declaration, deprecate-before-major-removal, and exception classes. [CITED: https://semver.org/] [CITED: https://hexdocs.pm/elixir/1.18.0/compatibility-and-deprecations.html] |
| Runtime warning framework | Custom warning registry or telemetry channel | Existing `@deprecated`, docs metadata, and docs/tests | Elixir explicitly separates docs metadata from compiler warnings, which fits the repo's light-enforcement preference. [CITED: https://hexdocs.pm/elixir/1.15.8/writing-documentation.html] [VERIFIED: repo grep] |
| Support matrix generator | Hand-maintained combinatorial matrix | Repo-backed floors + CI lanes + support script | The repo already has one honest root support-contract entrypoint and narrow CI lanes. [VERIFIED: repo grep] |
| Upgrade proof harness | New end-to-end migration framework | Existing docs migration smoke + support contract + release runbook | The needed proof primitives already exist and only need Phase 36-specific coverage. [VERIFIED: repo grep] |

**Key insight:** Phase 36 is a contract-publication phase, not an infrastructure phase, so the cheapest trustworthy plan is to tighten docs, metadata, and tests around already-shipped behavior. [VERIFIED: repo grep]

## Common Pitfalls

### Pitfall 1: Promise More Than CI Proves

**What goes wrong:** The guide promises OTP 28, broader Postgres versions, or independent optional-dependency support even though CI only proves Elixir 1.18 / OTP 27 plus a no-optional-deps lane. [VERIFIED: repo grep]

**Why it happens:** README and local machines can drift ahead of CI, and Elixir itself allows compatibility with newer OTP releases on patch lines without implying full support posture. [VERIFIED: repo grep] [CITED: https://hexdocs.pm/elixir/1.18.0/compatibility-and-deprecations.html]

**How to avoid:** Phrase the matrix as supported floors plus tested lanes, and reserve broader language for future phases after CI expansion. [VERIFIED: repo grep]

**Warning signs:** The guide starts listing version combinations that do not appear in `mix.exs`, CI, or the release runbook. [VERIFIED: repo grep]

### Pitfall 2: Flatten Deprecated and Legacy-Supported Into One Bucket

**What goes wrong:** Strict-CI adopters cannot tell whether a retained path emits a compiler warning, a task warning, or nothing at all. [VERIFIED: repo grep]

**Why it happens:** Elixir explicitly separates docs deprecation metadata from compiler `@deprecated` warnings, so "deprecated" alone is not specific enough. [CITED: https://hexdocs.pm/elixir/1.15.8/writing-documentation.html]

**How to avoid:** Document the warning channel per surface and add it to the deprecation-DX inventory. [VERIFIED: repo grep]

**Warning signs:** A guide says "supported through 1.x" without also naming replacement, warning channel, and strict-CI impact. [VERIFIED: repo grep]

### Pitfall 3: Let README and Guides Diverge

**What goes wrong:** Root docs still advertise `~> 0.3` snippets or raw-Swoosh parity without the same lifecycle framing as the canonical guide. [VERIFIED: repo grep]

**Why it happens:** The repo already has multiple Tier 1 docs plus admin docs, and `mix mailglass.docs.check` currently protects only a subset of compatibility wording. [VERIFIED: repo grep]

**How to avoid:** Make README/admin README/MAINTAINING pointers only, and expand docs-check tokens to require canonical-guide references. [VERIFIED: repo grep]

**Warning signs:** New compatibility text appears in README but not in a canonical guide or docs-check rule. [VERIFIED: repo grep]

### Pitfall 4: Patch-Release Deprecations Break Strict Consumers

**What goes wrong:** A patch release adds a new warning-emitting deprecation and downstream builds fail under `--warnings-as-errors`. [CITED: https://hexdocs.pm/elixir/1.18.0/compatibility-and-deprecations.html]

**Why it happens:** Elixir reserves the right to introduce warnings, but library maintainers still choose when to emit them; patch releases are the wrong place absent an emergency. [CITED: https://hexdocs.pm/elixir/1.18.0/compatibility-and-deprecations.html]

**How to avoid:** Put "no new hard deprecations in patch releases except security/correctness emergencies" directly in the policy. [VERIFIED: repo grep]

**Warning signs:** A patch release plan changes `@deprecated` annotations or warning-producing task behavior without an emergency rationale. [VERIFIED: repo grep]

## Code Examples

Verified patterns from official sources and this repo:

### Documentation Metadata With Compiler Warning

```elixir
@doc since: "1.3.0"
@deprecated "Use Foo.bar/2 instead"
```

Source: Elixir documentation metadata and compiler deprecation guidance. [CITED: https://hexdocs.pm/elixir/1.15.8/writing-documentation.html]

### Compiled-Docs Proof

```elixir
assert {:docs_v1, _, :elixir, _, _, metadata, docs} = Code.fetch_docs(module)
```

Source: Existing repo test pattern plus Elixir `Code.fetch_docs/1` guidance. [VERIFIED: repo grep] [CITED: https://hexdocs.pm/elixir/1.15.8/writing-documentation.html]

### Optional-Dependency Compatibility Lane

```text
mix compile --no-optional-deps --warnings-as-errors
```

Source: Mix optional-dependency guidance and existing repo CI/support contract. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html] [VERIFIED: repo grep]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Reachable/exported API implies compatibility promise | Explicitly documented public API and stability inventory | SemVer baseline; already applied in Phase 35 docs | Phase 36 should extend the model to lifecycle policy, not revert to reachability-based promises. [CITED: https://semver.org/] [VERIFIED: repo grep] |
| "Deprecated" as one vague bucket | Separate docs metadata, compiler warnings, and legacy-supported silent paths | Long-standing Elixir docs/deprecation model | Phase 36 should document warning channel per retained surface. [CITED: https://hexdocs.pm/elixir/1.15.8/writing-documentation.html] [CITED: https://hexdocs.pm/elixir/1.18.0/compatibility-and-deprecations.html] |
| Broad support claims | Narrow repo-proven floors plus explicit optional-dep lane | Current repo CI/support-contract posture | Keeps the contract honest for a single-maintainer library. [VERIFIED: repo grep] |

**Deprecated/outdated:**

- Duplicated compatibility policy across multiple docs: it invites drift and conflicts with the repo's existing docs-check enforcement posture. [VERIFIED: repo grep]
- Treating `mailglass_admin` as an independently drifting package: published packages already use exact sibling pinning. [VERIFIED: repo grep]

## Assumptions Log

All material compatibility claims in this document were verified in this session or cited from primary sources. No user-confirmation assumptions remain.

## Open Questions

No unresolved contract questions remain for planning.

Resolved in this research pass:

1. **`Mailglass.Outbound.send/2` classification**
   - Decision: keep `Mailglass.Outbound.send/2` as a silent legacy-supported compatibility bridge through `1.x`, with `Mailglass.deliver/2` remaining the canonical public delivery verb. [VERIFIED: repo grep]
   - Rationale: this matches D-36-12, D-36-15, and D-36-21 by removing ambiguity without imposing new compile-time warnings on strict-CI adopters in Phase 36. [VERIFIED: repo grep]
   - Consequence for planning: Phase 36 should document `send/2` as compatibility-only, require a documented replacement/support horizon/proof artifact, and defer any stronger deprecation pressure to an explicit future decision rather than smuggling it into this phase. [VERIFIED: repo grep]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | docs/tests/check commands | ✓ | 1.19.5 | CI lane on Elixir 1.18 / OTP 27 remains the release truth. [VERIFIED: repo grep] |
| Mix | docs/tests/check commands | ✓ | 1.19.5 | none. [VERIFIED: repo grep] |
| PostgreSQL client | smoke/test verification | ✓ | 14.17 (`psql`) | CI already provisions Postgres service for support-contract jobs. [VERIFIED: repo grep] |
| PostgreSQL server | local DB-backed tests | Unknown locally | — | CI uses `postgres:16-alpine`; local planner should not assume a running server. [VERIFIED: repo grep] |

**Missing dependencies with no fallback:**

- None identified for planning the docs/check work itself. [VERIFIED: repo grep]

**Missing dependencies with fallback:**

- Local running PostgreSQL service may be absent, but CI-backed proof still exists for support-contract and migration smoke work. [VERIFIED: repo grep]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit with compiled-doc assertions via `Code.fetch_docs/1`. [VERIFIED: repo grep] |
| Config file | none; Mix project config and `test/` structure drive tests. [VERIFIED: repo grep] |
| Quick run command | `mix test test/mailglass/docs_contract_test.exs test/mailglass/docs_migration_smoke_test.exs --warnings-as-errors` and `cd mailglass_admin && mix test test/mailglass_admin/stability_contract_test.exs --warnings-as-errors`. [VERIFIED: repo grep] |
| Full suite command | `bash scripts/verify_support_contract.sh && mix docs --warnings-as-errors`. [VERIFIED: repo grep] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| COMPAT-01 | Canonical policy page exists and Tier 1 docs point to it | docs contract | `mix test test/mailglass/docs_contract_test.exs --warnings-as-errors && mix mailglass.docs.check` | Partial; extend existing files. [VERIFIED: repo grep] |
| COMPAT-02 | Support matrix matches repo floors, sibling pin, and optional-dep lane | docs contract + compile smoke | `bash scripts/verify_support_contract.sh` | Partial; existing command proves lanes, not guide tokens. [VERIFIED: repo grep] |
| COMPAT-03 | Canonical `0.x -> 1.0` guide stays executable | migration smoke | `mix test test/mailglass/docs_migration_smoke_test.exs --warnings-as-errors` | Partial; extend existing smoke to the new guide. [VERIFIED: repo grep] |
| COMPAT-04 | Every retained compatibility path has replacement/warning/support-until proof | compiled-doc + inventory test | `mix test test/mailglass/stability_contract_test.exs --warnings-as-errors` plus new compatibility inventory test | Gap; existing stability tests cover `since`, not full deprecation-DX inventory. [VERIFIED: repo grep] |

### Sampling Rate

- **Per task commit:** `mix test test/mailglass/docs_contract_test.exs test/mailglass/docs_migration_smoke_test.exs --warnings-as-errors` plus admin counterpart when touched. [VERIFIED: repo grep]
- **Per wave merge:** `bash scripts/verify_support_contract.sh`. [VERIFIED: repo grep]
- **Phase gate:** `bash scripts/verify_support_contract.sh && mix docs --warnings-as-errors`. [VERIFIED: repo grep]

### Wave 0 Gaps

- [ ] Add canonical compatibility-guide tokens to `lib/mix/tasks/mailglass.docs.check.ex`. [VERIFIED: repo grep]
- [ ] Extend `test/mailglass/docs_contract_test.exs` to assert the new canonical guide pointers and stale-token bans. [VERIFIED: repo grep]
- [ ] Extend `test/mailglass/docs_migration_smoke_test.exs` to target the new `0.x -> 1.0` guide instead of only subordinate guides. [VERIFIED: repo grep]
- [ ] Add a dedicated compatibility/deprecation inventory test or extend stability tests so COMPAT-04 proves replacement, warning channel, support-until version, and proof artifact per retained surface. [VERIFIED: repo grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | This phase does not change runtime auth behavior. [VERIFIED: repo grep] |
| V3 Session Management | no | This phase documents compatibility policy rather than session behavior. [VERIFIED: repo grep] |
| V4 Access Control | no | No access-control code changes are required in the recommended plan slices. [VERIFIED: repo grep] |
| V5 Input Validation | yes | Docs-check and inventory tests should validate exact required/forbidden tokens so stale or overbroad claims fail fast. [VERIFIED: repo grep] |
| V6 Cryptography | yes | The policy should explicitly reserve narrow security/signature/correctness exceptions, matching existing security and retire guidance. [VERIFIED: repo grep] [CITED: https://hexdocs.pm/elixir/1.18.0/compatibility-and-deprecations.html] |

### Known Threat Patterns for This Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Silent security break forces incompatible fix | Tampering | Explicit security/correctness exception clause in the compatibility guide plus release-note requirement and MAINTAINING retire/patch rules. [VERIFIED: repo grep] [CITED: https://hexdocs.pm/elixir/1.18.0/compatibility-and-deprecations.html] |
| Warning-emitting deprecation breaks strict downstream CI | Denial of service | Distinguish hard-warning deprecations from silent legacy support and ban new hard deprecations in patch releases except emergencies. [CITED: https://hexdocs.pm/elixir/1.18.0/compatibility-and-deprecations.html] |
| Overbroad optional-dep promise | Spoofing | Tie optional-dependency language to the existing no-optional-deps compile lane and document them as integration lanes, not baseline requirements. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html] [VERIFIED: repo grep] |
| Sibling-package drift | Tampering | Keep exact `mailglass_admin` publish pin and matched-release documentation in the support matrix. [VERIFIED: repo grep] |

## Sources

### Primary (HIGH confidence)

- Repo files required by the phase prompt and related tests/checks - current compatibility reality, support matrix truth, and proof hooks. [VERIFIED: repo grep]
- https://semver.org/ - public API declaration and deprecate-before-major-removal baseline. [CITED: https://semver.org/]
- https://hexdocs.pm/elixir/1.18.0/compatibility-and-deprecations.html - Elixir compatibility exceptions, deprecation stages, and major-only removals. [CITED: https://hexdocs.pm/elixir/1.18.0/compatibility-and-deprecations.html]
- https://hexdocs.pm/elixir/1.15.8/writing-documentation.html - `:since`, docs deprecation metadata, `@deprecated`, and `Code.fetch_docs/1` guidance. [CITED: https://hexdocs.pm/elixir/1.15.8/writing-documentation.html]
- https://hexdocs.pm/mix/Mix.Tasks.Deps.html - optional dependency semantics and recommended `--no-optional-deps --warnings-as-errors` validation lane. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html]

### Secondary (MEDIUM confidence)

- https://hex.pm/docs/usage - Hex dependency-resolution and lockfile behavior context. [CITED: https://hex.pm/docs/usage]

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH - all recommended floors, pins, and proof tools are already present in repo metadata or official Elixir/Mix docs. [VERIFIED: repo grep] [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html]
- Architecture: HIGH - the canonical-guide plus proof-check model matches existing repo structure and project methodology. [VERIFIED: repo grep]
- Pitfalls: HIGH - each pitfall is grounded either in explicit Elixir compatibility rules or in already-shipped repo behavior. [VERIFIED: repo grep] [CITED: https://hexdocs.pm/elixir/1.18.0/compatibility-and-deprecations.html]

**Research date:** 2026-05-05
**Valid until:** 2026-06-04

## RESEARCH COMPLETE
