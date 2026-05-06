# Phase 35: Stability Contract Audit - Research

**Researched:** 2026-05-05 [VERIFIED: user prompt]  
**Domain:** Elixir/ExDoc public-contract definition and drift detection across `mailglass` and `mailglass_admin` [VERIFIED: repo grep][CITED: https://hexdocs.pm/elixir/writing-documentation.html][CITED: https://hexdocs.pm/ex_doc/ExDoc.html]  
**Confidence:** MEDIUM [VERIFIED: repo grep]

<user_constraints>
## User Constraints

### Locked Decisions
- Phase 35 scope is: "Adopters and maintainers can identify the exact stable `v1.x` contract across `mailglass` and `mailglass_admin`, including what remains internal." [VERIFIED: user prompt][VERIFIED: repo grep]
- This phase must satisfy `LOCK-01`, `LOCK-02`, `LOCK-03`, and `LOCK-04`. [VERIFIED: user prompt][VERIFIED: repo grep]
- Use the repo's recommendation-first methodology and produce one cohesive recommendation set rather than option sprawl. [VERIFIED: user prompt][VERIFIED: repo grep]

### Claude's Discretion
- No phase-specific discretion document exists yet; research scope is constrained by `ROADMAP.md`, `REQUIREMENTS.md`, `STATE.md`, `PROJECT.md`, `METHODOLOGY.md`, and Phase 34 artifacts. [VERIFIED: user prompt][VERIFIED: repo grep]

### Deferred Ideas (OUT OF SCOPE)
- No additional deferred items were provided for Phase 35 beyond the milestone-level out-of-scope list in `REQUIREMENTS.md`. [VERIFIED: user prompt][VERIFIED: repo grep]
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LOCK-01 | Adopter can identify the exact `mailglass` core modules, behaviours, mix tasks, telemetry names, structs, and documented fields that are stable for `v1.x`. [VERIFIED: repo grep] | Use compiled-doc metadata plus one canonical core contract page; do not infer stability from `Boundary` exports alone. [VERIFIED: repo grep][CITED: https://hexdocs.pm/elixir/writing-documentation.html] |
| LOCK-02 | Adopter can identify the exact `mailglass_admin` router, auth, and operator-service seams that are stable for `v1.x`, and which admin UI details remain internal. [VERIFIED: repo grep] | Add a first-class admin contract document and tighten `mailglass_admin` HexDocs curation; current admin docs config is too thin for this requirement. [VERIFIED: repo grep][CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |
| LOCK-03 | Maintainer can classify exported but non-contract surfaces as internal or sibling-package-only so accidental public surface does not expand during `v1.x`. [VERIFIED: repo grep] | Treat exported/internal classification as a separate audited inventory; `@doc false` and `Boundary` exports are signals, not the contract. [VERIFIED: repo grep][CITED: https://hexdocs.pm/elixir/writing-documentation.html] |
| LOCK-04 | Stable public APIs carry complete `@since` and deprecation metadata so the contract is visible in generated docs, not only in planning notes. [VERIFIED: repo grep] | Verify with `Code.fetch_docs/1` against compiled docs; source grep alone is insufficient. [CITED: https://hexdocs.pm/elixir/writing-documentation.html][CITED: https://hexdocs.pm/elixir/Module.html] |
</phase_requirements>

## Summary

Phase 35 should be planned as a documentation-and-verification audit, not a feature build. The repo already has three useful foundations: a large core contract file at [docs/api_stability.md](/Users/jon/projects/mailglass/docs/api_stability.md:1), existing docs contract tests at [test/mailglass/docs_contract_test.exs](/Users/jon/projects/mailglass/test/mailglass/docs_contract_test.exs:1), and a narrow public-surface audit task at [lib/mix/tasks/mailglass.stability.check.ex](/Users/jon/projects/mailglass/lib/mix/tasks/mailglass.stability.check.ex:1). [VERIFIED: repo grep] However, those foundations do not yet satisfy the Phase 35 milestone because the core contract file still speaks in "`v0.2` API freeze" terms, `mailglass_admin` has no equivalent canonical contract page, and current docs config does not clearly separate stable seams from internal ones across both packages. [VERIFIED: repo grep]

The strongest implementation path is to keep ExDoc and compiled Elixir doc metadata as the contract source of truth. Elixir stores docs metadata in compiled bytecode and explicitly supports `:since`, `:deprecated`, `@doc false`, and `@moduledoc false`; ExDoc consumes that metadata and supports curated extras and module grouping. [CITED: https://hexdocs.pm/elixir/writing-documentation.html][CITED: https://hexdocs.pm/elixir/Module.html][CITED: https://hexdocs.pm/ex_doc/ExDoc.html] That means Phase 35 should define one explicit stable-contract inventory per package, backfill missing metadata on truly stable APIs, and add automated tests that fail when compiled docs drift from the promised contract. [VERIFIED: repo grep][CITED: https://hexdocs.pm/elixir/writing-documentation.html]

The main planning risk is contract ambiguity, not missing tooling. The codebase currently exposes more via `Boundary` and compiled module visibility than the roadmap intends to promise, especially around `mailglass_admin` and some helper surfaces. [VERIFIED: repo grep] There is also a version-source mismatch: both `mix.exs` files still declare `0.3.2`, while planning artifacts describe the project as `0.5.0` and `v0.6` complete; that mismatch must be resolved before Phase 35 can claim truthful `@since` history. [VERIFIED: repo grep]

**Primary recommendation:** Plan Phase 35 around a compiled-doc-driven contract inventory: extend core contract docs, add a new admin contract document, classify exported-but-internal surfaces explicitly, and verify `@since`/deprecation coverage with automated `Code.fetch_docs/1` tests. [VERIFIED: repo grep][CITED: https://hexdocs.pm/elixir/writing-documentation.html][CITED: https://hexdocs.pm/ex_doc/ExDoc.html]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Core `mailglass` stable-contract inventory | CDN / Static | API / Backend | The user-facing artifact is published HexDocs/static docs, but the truth comes from compiled modules and Mix tasks in the library codebase. [VERIFIED: repo grep][CITED: https://hexdocs.pm/ex_doc/ExDoc.html][CITED: https://hexdocs.pm/elixir/writing-documentation.html] |
| `mailglass_admin` stable router/auth/operator seam inventory | CDN / Static | Frontend Server (SSR) | The stable promise is documentation, but the documented seam describes Phoenix router macros, LiveView mount/session behavior, and auth/session contracts. [VERIFIED: repo grep] |
| Internal vs sibling-only surface classification | API / Backend | CDN / Static | The classification decision belongs in source/doc metadata and maintenance checks, then gets rendered into docs. [VERIFIED: repo grep][CITED: https://hexdocs.pm/elixir/writing-documentation.html] |
| `@since` and deprecation completeness verification | API / Backend | CDN / Static | Coverage must be checked from compiled docs metadata before docs generation, then surfaced in generated docs. [CITED: https://hexdocs.pm/elixir/writing-documentation.html][CITED: https://hexdocs.pm/elixir/Module.html] |

## Project Constraints (from CLAUDE.md)

- Mailglass is a Phoenix transactional-email framework with sibling Hex packages; `mailglass_inbound` is out of the current milestone and must not be pulled into Phase 35 scope. [VERIFIED: repo grep]
- Marketing email, campaigns, multi-channel notifications, and broad product-boundary expansion are permanently out of scope. [VERIFIED: repo grep]
- Errors are a public API contract and must stay pattern-matchable by struct/type rather than message string. [VERIFIED: repo grep]
- Telemetry names and metadata are contractual and must never include PII. [VERIFIED: repo grep]
- Optional dependencies must stay behind `Mailglass.OptionalDeps.*` gateways and the `mix compile --no-optional-deps --warnings-as-errors` lane remains mandatory. [VERIFIED: repo grep][CITED: https://hexdocs.pm/mix/Mix.Tasks.Compile.html]
- Open/click tracking stays opt-in and must never be enabled on auth-carrying messages. [VERIFIED: repo grep]
- Release flow uses linked sibling-package versions and `mailglass_admin/mix.exs` must pin `{:mailglass, "== <version>"}` for publish builds. [VERIFIED: repo grep]
- Docs, errors, logs, and UI language must follow the project's exact/clear maintainer voice rather than marketing language. [VERIFIED: repo grep]

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir docs metadata + `Code.fetch_docs/1` | 1.19.5 local runtime [VERIFIED: local command] | Read the actual compiled contract for modules, functions, callbacks, and types, including `:since` and `:deprecated`. [CITED: https://hexdocs.pm/elixir/writing-documentation.html][CITED: https://hexdocs.pm/elixir/Module.html] | This is the only trustworthy source for what HexDocs will render; regex over source comments is weaker. [CITED: https://hexdocs.pm/elixir/writing-documentation.html] |
| `ex_doc` | 0.40.1, published 2026-01-31 [VERIFIED: mix hex.info][CITED: https://hexdocs.pm/ex_doc/changelog.html] | Generate HexDocs, extras, module groups, and grouped docs navigation. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] | The repo already uses ExDoc in both packages, so Phase 35 should refine that configuration rather than add another docs layer. [VERIFIED: repo grep] |
| ExUnit docs-contract tests | Elixir 1.19.5 local runtime [VERIFIED: local command][VERIFIED: repo grep] | Enforce contract drift in CI and local verification. [VERIFIED: repo grep] | Existing docs tests already guard README/guide contracts; Phase 35 should extend the same pattern for stable-surface coverage. [VERIFIED: repo grep] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `boundary` | 0.10.4, published 2024-09-25 [VERIFIED: mix hex.info] | Signal which modules are exported between internal package boundaries. [VERIFIED: repo grep] | Use as drift input only; do not equate exports with public `v1.x` contract. [VERIFIED: repo grep] |
| `nimble_options` | 1.1.1, published 2024-05-25 [VERIFIED: mix hex.info] | Keeps router macro option schemas explicit and doc-friendly. [VERIFIED: repo grep] | Relevant when documenting stable router/auth seam options in `mailglass_admin`. [VERIFIED: repo grep] |
| `actionlint` | 1.7.12 local [VERIFIED: local command] | Validate workflow changes if Phase 35 adds contract-proof jobs or docs gates. [VERIFIED: local command] | Use only if the phase edits CI/workflow files. [VERIFIED: repo grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Code.fetch_docs/1`-based audit | Raw grep/AST-only scan | Faster to script, but it does not verify what compiled docs actually expose. [CITED: https://hexdocs.pm/elixir/writing-documentation.html] |
| ExDoc extras + groups | README-only contract documentation | Simpler, but `mailglass_admin` already demonstrates drift risk when README and generated docs are not curated together. [VERIFIED: repo grep] |
| Explicit stable/internal inventory | `Boundary` exports as the contract | Incorrect for this repo: `Mailglass` exports clearly internal modules and `mailglass_admin` exports less than the roadmap says is stable. [VERIFIED: repo grep] |

**Installation:** No new package is recommended for Phase 35; use the existing docs/test stack already declared in both `mix.exs` files. [VERIFIED: repo grep]

**Version verification:** Verified with `mix hex.info ex_doc`, `mix hex.info boundary`, and `mix hex.info nimble_options` during this session. [VERIFIED: mix hex.info]

## Architecture Patterns

### System Architecture Diagram

```text
lib/*.ex + mailglass_admin/lib/*.ex
        |
        v
Elixir doc metadata (`@doc`, `@typedoc`, `@moduledoc`, `:since`, `:deprecated`)
        |
        +----> `Code.fetch_docs/1` audit tests and Mix tasks
        |              |
        |              +----> fail on missing metadata / leaked contract drift
        |
        v
Canonical contract extras
(`docs/api_stability.md` + recommended admin contract page)
        |
        v
ExDoc config (`extras`, `groups_for_modules`, optional `groups_for_docs`)
        |
        v
Generated HexDocs / maintainer-facing docs
        |
        +----> adopters find stable v1.x seams
        +----> maintainers see internal vs sibling-only boundaries
```

### Recommended Project Structure
```text
docs/
├── api_stability.md                  # core stable contract inventory (existing)
mailglass_admin/
├── docs/
│   └── api_stability.md              # recommended new admin contract inventory
test/
├── mailglass/
│   └── stability_contract_test.exs   # recommended compiled-doc audit
mailglass_admin/test/
├── mailglass_admin/
│   └── stability_contract_test.exs   # recommended admin compiled-doc audit
```

### Pattern 1: Compiled-Docs-First Contract Audit
**What:** Audit the stable surface from compiled docs metadata, not from comments or grep. [CITED: https://hexdocs.pm/elixir/writing-documentation.html]  
**When to use:** For `LOCK-01`, `LOCK-03`, and especially `LOCK-04`. [VERIFIED: repo grep]  
**Example:**
```elixir
# Source: https://hexdocs.pm/elixir/writing-documentation.html
@doc since: "1.3.0"
def world(name) do
  IO.puts("hello #{name}")
end

# Source: https://hexdocs.pm/elixir/Module.html
{:docs_v1, _, _, _, _, _, docs} = Code.fetch_docs(MyApp.Hello)
```

### Pattern 2: Curated HexDocs Contract Surface
**What:** Put the stable contract into ExDoc extras/module groups so adopters see it where they already read docs. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html]  
**When to use:** For the core and admin contract inventories. [VERIFIED: repo grep]  
**Example:**
```elixir
# Source: https://hexdocs.pm/ex_doc/ExDoc.html
docs: [
  extras: ["README.md", "docs/api_stability.md"],
  groups_for_modules: [
    Stable: [MyApp, MyApp.Router],
    Internal: [MyApp.Hidden]
  ]
]
```

### Pattern 3: Explicitly Hidden Internal Helpers
**What:** Use `@moduledoc false` for truly internal modules; do not rely on `@doc false` alone to imply privacy. [CITED: https://hexdocs.pm/elixir/writing-documentation.html]  
**When to use:** When classifying exported-but-non-contract helpers under `LOCK-03`. [VERIFIED: repo grep]  
**Example:**
```elixir
# Source: https://hexdocs.pm/elixir/writing-documentation.html
defmodule MyApp.Hidden do
  @moduledoc false
end
```

### Anti-Patterns to Avoid
- **Treating `Boundary` exports as the public contract:** `Mailglass` exports internal modules such as `Mailglass.Outbound.Projector`, `Mailglass.PubSub`, and `Mailglass.OptionalDeps.Oban`, while `mailglass_admin` exports only `Router` even though the roadmap requires a stable auth seam too. [VERIFIED: repo grep]
- **Using `@doc false` as if it makes an API private:** Elixir docs explicitly say hidden docs do not make a function private or non-importable. [CITED: https://hexdocs.pm/elixir/writing-documentation.html]
- **Checking `@since` with grep only:** Phase 35 needs compiled-doc truth because that is what users will see in HexDocs. [CITED: https://hexdocs.pm/elixir/writing-documentation.html][CITED: https://hexdocs.pm/elixir/Module.html]
- **Leaving `mailglass_admin` on README-only contract discoverability:** its current docs config has no extras or module groups, which is too weak for `LOCK-02`. [VERIFIED: repo grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Stable-surface discovery | Custom regex scanner over source files | `Code.fetch_docs/1` + focused ExUnit assertions | It audits the compiled docs chunk that ExDoc will render. [CITED: https://hexdocs.pm/elixir/writing-documentation.html] |
| Docs information architecture | Ad hoc README sections only | ExDoc `extras`, `groups_for_modules`, and optional `groups_for_docs` | ExDoc already supports the grouping behavior this phase needs. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] |
| Privacy semantics | Convention-only hidden helpers | `@moduledoc false` for internal modules and explicit inventory classification | `@doc false` does not make a function private. [CITED: https://hexdocs.pm/elixir/writing-documentation.html] |
| Release-history inference | Guesswork from planning notes | Source-controlled version metadata + resolved current package version source of truth | `@since` is only useful if version history is truthful. [VERIFIED: repo grep][CITED: https://hexdocs.pm/elixir/writing-documentation.html] |

**Key insight:** Phase 35 should not invent a second contract system; it should tighten the existing Elixir/ExDoc contract system until generated docs and maintenance checks agree. [VERIFIED: repo grep][CITED: https://hexdocs.pm/elixir/writing-documentation.html][CITED: https://hexdocs.pm/ex_doc/ExDoc.html]

## Common Pitfalls

### Pitfall 1: Boundary/Public Contract Confusion
**What goes wrong:** Maintainers treat exported modules as the stable `v1.x` promise. [VERIFIED: repo grep]  
**Why it happens:** `Boundary` is already heavily used, so it is easy to mistake compile-time access rules for adopter-facing API commitment. [VERIFIED: repo grep]  
**How to avoid:** Maintain a separate stable/internal/sibling-only inventory and verify it in docs/tests. [VERIFIED: repo grep]  
**Warning signs:** The inventory includes modules currently grouped as `Internal` in `mix.exs` docs config, or excludes `MailglassAdmin.Auth` even though the roadmap requires an auth seam. [VERIFIED: repo grep]

### Pitfall 2: Hidden Docs Mistaken for Hidden APIs
**What goes wrong:** A function marked `@doc false` is treated as safe to leave public without classification. [CITED: https://hexdocs.pm/elixir/writing-documentation.html]  
**Why it happens:** The docs disappear from HexDocs, which looks like privacy. [CITED: https://hexdocs.pm/elixir/writing-documentation.html]  
**How to avoid:** Either move helpers into `@moduledoc false` internal modules or classify them explicitly as internal/sibling-only in the contract page. [CITED: https://hexdocs.pm/elixir/writing-documentation.html]  
**Warning signs:** Public helper functions remain callable/importable but have no place in the stable contract inventory. [CITED: https://hexdocs.pm/elixir/writing-documentation.html][VERIFIED: repo grep]

### Pitfall 3: Metadata Drift Hidden by Source Grep
**What goes wrong:** Source looks annotated, but compiled docs still lack `:since` or doc text on the promised stable APIs. [CITED: https://hexdocs.pm/elixir/Module.html]  
**Why it happens:** Multi-use doc attributes merge metadata, hidden docs are excluded, and public callbacks/types can remain undocumented even when nearby functions are documented. [CITED: https://hexdocs.pm/elixir/Module.html][VERIFIED: repo grep]  
**How to avoid:** Fail tests on `Code.fetch_docs/1` results for stable modules/functions/callbacks/types. [CITED: https://hexdocs.pm/elixir/writing-documentation.html]  
**Warning signs:** Current compiled-doc audit already shows gaps such as undocumented `MailglassAdmin.Auth` public types/callbacks and undocumented/no-`since` core callbacks/types/functions. [VERIFIED: repo grep]

### Pitfall 4: Version-History Mismatch Corrupts `@since`
**What goes wrong:** The contract page and compiled docs claim one introduction history while package metadata claims another. [VERIFIED: repo grep]  
**Why it happens:** Planning artifacts say current packages are `0.5.0`, but both package manifests still declare `0.3.2`, and `mailglass_admin/README.md` still instructs adopters to install `~> 0.1`. [VERIFIED: repo grep]  
**How to avoid:** Resolve version-source-of-truth before finalizing `LOCK-04`; otherwise `@since` annotations are not trustworthy. [VERIFIED: repo grep]  
**Warning signs:** Any new contract inventory has to explain why docs, README snippets, and `mix.exs` versions disagree. [VERIFIED: repo grep]

## Code Examples

Verified patterns from official sources:

### `:since` and soft-deprecation metadata
```elixir
# Source: https://hexdocs.pm/elixir/writing-documentation.html
@doc since: "1.3.0"
def world(name) do
  IO.puts("hello #{name}")
end

# Source: https://hexdocs.pm/elixir/Module.html
@doc deprecated: "Use Foo.bar/2 instead"
def old_api(arg), do: ...
```

### ExDoc grouping for contract visibility
```elixir
# Source: https://hexdocs.pm/ex_doc/ExDoc.html
docs: [
  extras: ["README.md", "docs/api_stability.md"],
  groups_for_modules: [
    Stable: [MyApp, MyApp.Router, MyApp.Auth],
    Internal: [MyApp.Hidden]
  ]
]
```

### Compiled-doc verification sketch
```elixir
# Source: https://hexdocs.pm/elixir/writing-documentation.html
{:docs_v1, _, _, _, _, _, docs} = Code.fetch_docs(MyApp.Auth)

for {{kind, name, arity}, _, _, doc, meta} <- docs,
    doc != :hidden,
    kind in [:function, :callback, :type],
    is_nil(meta[:since]) do
  raise "#{inspect(MyApp.Auth)} missing :since for #{kind} #{name}/#{arity}"
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hand-maintained freeze notes only | Compiled docs metadata plus generated docs and audit tests | Elixir docs metadata and `Code.fetch_docs/1` are current in Elixir 1.19.5 docs; ExDoc 0.40.1 is current in this repo. [CITED: https://hexdocs.pm/elixir/writing-documentation.html][VERIFIED: mix hex.info] | Phase 35 should verify what users actually read, not just markdown notes. [CITED: https://hexdocs.pm/elixir/writing-documentation.html] |
| README-only discoverability for admin contract | ExDoc-curated extras/module groups for package-specific seams | ExDoc supports this in current docs. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html] | `mailglass_admin` can meet `LOCK-02` without inventing a custom docs site. [VERIFIED: repo grep] |
| Hidden function docs used as pseudo-privacy | Explicit hidden modules and stable/internal inventory | Current Elixir docs explicitly warn against equating hidden docs with privacy. [CITED: https://hexdocs.pm/elixir/writing-documentation.html] | Prevents accidental public-surface growth during `v1.x`. [CITED: https://hexdocs.pm/elixir/writing-documentation.html] |

**Deprecated/outdated:**
- Treating the current [docs/api_stability.md](/Users/jon/projects/mailglass/docs/api_stability.md:1) wording as the final `v1.x` contract is outdated because it is core-only and still framed as a "`v0.2 API Freeze Policy`". [VERIFIED: repo grep]
- Treating [mailglass_admin/README.md](/Users/jon/projects/mailglass/mailglass_admin/README.md:1) as sufficient contract documentation is outdated for `LOCK-02` because the package's ExDoc config currently omits extras and module grouping. [VERIFIED: repo grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A 30-day freshness window is reasonable for this research because the phase relies mostly on stable Elixir/ExDoc documentation and current repo state. [ASSUMED] | Metadata | The planner may over-trust this research if a fast follow-up changes repo versions or docs policy sooner. |

## Resolved Decisions

1. **Authoritative version history for `@since` metadata**
   - Decision: the source-controlled package manifests in [`mix.exs`](/Users/jon/projects/mailglass/mix.exs:4) and [`mailglass_admin/mix.exs`](/Users/jon/projects/mailglass/mailglass_admin/mix.exs:4) are the authoritative version source for package history during Phase 35 planning. Planning artifacts describing `0.5.0` / `v0.6` milestone state are milestone-progress markers, not package-version truth. [VERIFIED: repo grep]
   - Impact on planning: `LOCK-04` work must treat stale README/planning version language as drift to be corrected, and it must not rewrite `@since` history to match milestone labels. Use the package manifests plus existing source annotations as the baseline. [VERIFIED: repo grep]

2. **`MailglassAdmin.Auth` contract status**
   - Decision: `MailglassAdmin.Auth` is part of the intended stable `v1.x` contract because the roadmap explicitly includes the admin auth seam in Phase 35 scope. It should be documented as a first-class adopter-owned behaviour seam, even if the top-level `Boundary` export remains narrow. [VERIFIED: repo grep]
   - Impact on planning: Phase 35 must update package-local docs and point-of-use docs so adopters can discover the auth seam without inferring it indirectly from router examples. [VERIFIED: repo grep]

3. **Canonical contract document shape**
   - Decision: keep one canonical contract page per published package. `mailglass` continues to use [`docs/api_stability.md`](/Users/jon/projects/mailglass/docs/api_stability.md:1), while `mailglass_admin` should gain its own package-local contract page surfaced through `mailglass_admin` ExDoc configuration. [VERIFIED: repo grep][CITED: https://hexdocs.pm/ex_doc/ExDoc.html]
   - Impact on planning: shared root docs may still cross-link the package contracts, but `LOCK-02` requires a package-local admin artifact and `mailglass_admin/mix.exs` docs curation rather than README-only discoverability. [VERIFIED: repo grep]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | `Code.fetch_docs/1`, tests, docs build | ✓ [VERIFIED: local command] | 1.19.5 [VERIFIED: local command] | — |
| Mix | docs/test/task execution | ✓ [VERIFIED: local command] | 1.19.5 [VERIFIED: local command] | — |
| Hex | package/version verification via `mix hex.info` | ✓ [VERIFIED: mix hex.info] | bundled via local Mix install [VERIFIED: mix hex.info] | — |
| `actionlint` | workflow validation if CI is edited | ✓ [VERIFIED: local command] | 1.7.12 [VERIFIED: local command] | manual YAML review only, weaker [VERIFIED: local command] |

**Missing dependencies with no fallback:**
- None for the recommended docs-and-audit approach. [VERIFIED: local command][VERIFIED: repo grep]

**Missing dependencies with fallback:**
- None detected. [VERIFIED: local command]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit on Elixir 1.19.5, with package-local tests in both `mailglass` and `mailglass_admin`. [VERIFIED: local command][VERIFIED: repo grep] |
| Config file | [`config/test.exs`](/Users/jon/projects/mailglass/config/test.exs:1) and [`mailglass_admin/config/test.exs`](/Users/jon/projects/mailglass/mailglass_admin/config/test.exs:1). [VERIFIED: repo grep] |
| Quick run command | `mix test test/mailglass/docs_contract_test.exs --warnings-as-errors` and `cd mailglass_admin && mix test test/mailglass_admin/post_installer_smoke_test.exs test/mailglass_admin/operator_live_test.exs --warnings-as-errors` and `mix docs --warnings-as-errors`. [VERIFIED: repo grep][CITED: https://hexdocs.pm/mix/Mix.Tasks.Compile.html] |
| Full suite command | `mix test --warnings-as-errors` and `cd mailglass_admin && mix test --warnings-as-errors`. [VERIFIED: repo grep] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LOCK-01 | Core stable inventory matches documented modules/behaviours/tasks/telemetry/structs/fields. [VERIFIED: repo grep] | unit/docs-contract | `mix test test/mailglass/docs_contract_test.exs test/mailglass/stability_contract_test.exs --warnings-as-errors` | `docs_contract_test.exs` exists; `stability_contract_test.exs` is a Wave 0 gap. [VERIFIED: repo grep] |
| LOCK-02 | Admin stable inventory matches router/auth/operator seams and marks UI internals internal. [VERIFIED: repo grep] | unit/docs-contract + LiveView smoke | `cd mailglass_admin && mix test test/mailglass_admin/stability_contract_test.exs test/mailglass_admin/operator_live_test.exs --warnings-as-errors` | `operator_live_test.exs` exists; `stability_contract_test.exs` is a Wave 0 gap. [VERIFIED: repo grep] |
| LOCK-03 | Exported but unsupported surfaces are classified and do not silently expand. [VERIFIED: repo grep] | unit/task | `mix mailglass.stability.check --no-compile` plus new compiled-doc contract tests | Existing task exists but only checks Swoosh type leaks; scope must expand or be complemented. [VERIFIED: repo grep] |
| LOCK-04 | Stable APIs expose complete `:since` and deprecation metadata in generated docs. [VERIFIED: repo grep] | unit/docs-metadata + docs build | `mix test test/mailglass/stability_contract_test.exs --warnings-as-errors` and `cd mailglass_admin && mix test test/mailglass_admin/stability_contract_test.exs --warnings-as-errors` and `mix docs --warnings-as-errors` | Missing direct metadata tests today. [VERIFIED: repo grep] |

### Sampling Rate
- **Per task commit:** run the smallest affected docs/contract test file plus `mix docs --warnings-as-errors` when docs config or public metadata changes. [VERIFIED: repo grep][CITED: https://hexdocs.pm/mix/Mix.Tasks.Compile.html]
- **Per wave merge:** rerun both package contract tests and the docs build. [VERIFIED: repo grep]
- **Phase gate:** compiled-doc stability tests and `mix docs --warnings-as-errors` must be green before `/gsd-verify-work`. [VERIFIED: repo grep][CITED: https://hexdocs.pm/mix/Mix.Tasks.Compile.html]

### Wave 0 Gaps
- [ ] [`test/mailglass/stability_contract_test.exs`](/Users/jon/projects/mailglass/test/mailglass): compiled-doc inventory and metadata audit for the core package. [VERIFIED: repo grep]
- [ ] [`mailglass_admin/test/mailglass_admin/stability_contract_test.exs`](/Users/jon/projects/mailglass/mailglass_admin/test/mailglass_admin): compiled-doc inventory and metadata audit for admin stable seams. [VERIFIED: repo grep]
- [ ] `mailglass_admin` ExDoc curation update in [`mailglass_admin/mix.exs`](/Users/jon/projects/mailglass/mailglass_admin/mix.exs:178): extras and module grouping are currently absent. [VERIFIED: repo grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Document `MailglassAdmin.Auth` as the stable adopter-owned auth seam instead of leaking internal UI mechanics. [VERIFIED: repo grep] |
| V3 Session Management | yes | Keep the contract on router session whitelists and `__operator_session__/2` semantics, not DOM details. [VERIFIED: repo grep] |
| V4 Access Control | yes | Stable docs must preserve operator-access vs destructive-action boundaries and not broaden replay authority accidentally. [VERIFIED: repo grep] |
| V5 Input Validation | yes | Keep router/auth option schemas explicit and verified; `NimbleOptions` is already the repo standard for these seams. [VERIFIED: repo grep] |
| V6 Cryptography | no | Phase 35 documents existing contract boundaries; it does not add new crypto primitives. [VERIFIED: repo grep] |

### Known Threat Patterns for this Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Accidental public auth or operator seam expansion | Elevation of Privilege | Stable/internal inventory plus compiled-doc tests on the admin contract. [VERIFIED: repo grep] |
| Hidden-but-callable helper treated as unsupported without classification | Tampering | Use `@moduledoc false` or explicit internal classification; do not rely on `@doc false` alone. [CITED: https://hexdocs.pm/elixir/writing-documentation.html] |
| Incorrect `@since` / deprecation metadata causing unsafe adoption paths | Repudiation / Tampering | Verify with `Code.fetch_docs/1` and docs build in CI. [CITED: https://hexdocs.pm/elixir/writing-documentation.html] |

## Sources

### Primary (HIGH confidence)
- Repo artifacts: [`REQUIREMENTS.md`](/Users/jon/projects/mailglass/.planning/REQUIREMENTS.md:1), [`ROADMAP.md`](/Users/jon/projects/mailglass/.planning/ROADMAP.md:1), [`STATE.md`](/Users/jon/projects/mailglass/.planning/STATE.md:1), [`PROJECT.md`](/Users/jon/projects/mailglass/.planning/PROJECT.md:1), [`METHODOLOGY.md`](/Users/jon/projects/mailglass/.planning/METHODOLOGY.md:1), Phase 34 research/verification, [`mix.exs`](/Users/jon/projects/mailglass/mix.exs:1), [`mailglass_admin/mix.exs`](/Users/jon/projects/mailglass/mailglass_admin/mix.exs:1), [`docs/api_stability.md`](/Users/jon/projects/mailglass/docs/api_stability.md:1), [`mailglass_admin/README.md`](/Users/jon/projects/mailglass/mailglass_admin/README.md:1), [`lib/mix/tasks/mailglass.stability.check.ex`](/Users/jon/projects/mailglass/lib/mix/tasks/mailglass.stability.check.ex:1), and docs-contract tests. [VERIFIED: repo grep]
- https://hexdocs.pm/elixir/writing-documentation.html - `:since`, `:deprecated`, `@doc false`, `@moduledoc false`, and `Code.fetch_docs/1`. [CITED: https://hexdocs.pm/elixir/writing-documentation.html]
- https://hexdocs.pm/elixir/Module.html - docs metadata mechanics for `@doc`, `@typedoc`, `@moduledoc`, and compiled-doc availability. [CITED: https://hexdocs.pm/elixir/Module.html]
- https://hexdocs.pm/ex_doc/ExDoc.html - `extras`, `groups_for_modules`, `groups_for_docs`, and docs configuration model. [CITED: https://hexdocs.pm/ex_doc/ExDoc.html]
- https://hexdocs.pm/ex_doc/changelog.html - current `ex_doc` version `0.40.1` and publish date `2026-01-31`. [CITED: https://hexdocs.pm/ex_doc/changelog.html]
- https://hexdocs.pm/mix/Mix.Tasks.Compile.html - `--warnings-as-errors` and `--no-optional-deps` behavior. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Compile.html]
- https://hexdocs.pm/mix/Mix.Tasks.Deps.html - optional dependency compile guidance. [CITED: https://hexdocs.pm/mix/Mix.Tasks.Deps.html]

### Secondary (MEDIUM confidence)
- `mix hex.info ex_doc`, `mix hex.info boundary`, and `mix hex.info nimble_options` - current locked versions and publish dates from Hex. [VERIFIED: mix hex.info]

### Tertiary (LOW confidence)
- None. [VERIFIED: repo grep]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - the docs/test/tooling stack is already present in-repo and verified against official Elixir/ExDoc docs. [VERIFIED: repo grep][CITED: https://hexdocs.pm/elixir/writing-documentation.html][CITED: https://hexdocs.pm/ex_doc/ExDoc.html]
- Architecture: MEDIUM - the recommendation is clear, but public-vs-internal classification still has one unresolved version-history ambiguity and one admin-auth contract ambiguity. [VERIFIED: repo grep]
- Pitfalls: HIGH - each major pitfall is directly visible in current repo state or explicitly documented by Elixir docs. [VERIFIED: repo grep][CITED: https://hexdocs.pm/elixir/writing-documentation.html]

**Research date:** 2026-05-05 [VERIFIED: user prompt]  
**Valid until:** 2026-06-04 [ASSUMED]
