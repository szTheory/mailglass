# Phase 38: Release Rehearsal and Proof Artifacts - Research

**Researched:** 2026-05-06 [VERIFIED: local system date]  
**Domain:** Elixir/Hex release rehearsal, publish-proof export, and committed release evidence for sibling packages [VERIFIED: repo planning docs]  
**Confidence:** HIGH [VERIFIED: repo workflow audit]  

<user_constraints>
## User Constraints (from CONTEXT.md)

Verbatim copy from [`38-CONTEXT.md`](/Users/jon/projects/mailglass/.planning/phases/38-release-rehearsal-and-proof-artifacts/38-CONTEXT.md:1). [VERIFIED: repo file read]

### Locked Decisions
- **D-38-01:** Phase 38 should default to one coherent recommendation set and
  only re-open choices that materially affect:
  - the public `v1.0` release contract
  - irreversible publish posture
  - security/trust semantics
  - long-term maintainer burden in a meaningful way
- **D-38-02:** Keep the release proof narrow and honest. Prefer a small number
  of durable, semantically meaningful proofs over a broad ceremony that mixes
  required truth with optional nice-to-haves.
- **D-38-03:** Repo-enforceable proof should stay repo-enforced. The manual
  checklist should cover only human/external steps that the repo cannot prove by
  itself.

### Install rehearsal default
- **D-38-04:** The canonical fresh-install rehearsal should stay aligned with
  the repo’s existing release-day smoke contract:
  - create a fresh Phoenix host from the published tag/version
  - add `mailglass` and `mailglass_admin`
  - run `mix deps.get`
  - run `mix mailglass.install`
  - run `mix compile --warnings-as-errors`
  - boot the endpoint
  - verify `GET /dev/mail/` returns HTTP 200
- **D-38-05:** The default install rehearsal host should be
  `phx.new --no-ecto --no-mailer --install`, because that matches the current
  fastest revert-window smoke and the existing workflow/test contract.
- **D-38-06:** The generated `config :swoosh, :api_client, false` sentinel is
  part of the release-proof contract for fresh hosts and must remain explicitly
  verified.
- **D-38-07:** A deeper Ecto-enabled onboarding smoke may exist, but it should
  be a secondary proof lane, not the default release-window rehearsal. The
  default path should optimize for fast trustworthy release/revert feedback.

### Upgrade rehearsal default
- **D-38-08:** The canonical upgrade rehearsal should use
  `guides/upgrading-to-v1_0.md` as the single authority and treat
  `guides/upgrading-from-v0_1.md` and `guides/migration-from-swoosh.md` as
  subordinate references only.
- **D-38-09:** The upgrade target state should be the stable lane:
  - `Mailglass.deliver*`
  - native `Mailglass.Message` setters
  - `Mailglass.Message.update_swoosh/2` only as the advanced escape hatch
  - matched `mailglass` and `mailglass_admin` release lines when both ship
- **D-38-10:** The default release rehearsal should assume the latest supported
  `0.3.x -> 1.0` path, not older historical upgrade lanes.
- **D-38-11:** `Mailglass.Message.new/2` should be treated as release-blocking
  for strict adopters because it emits real deprecation warnings under
  `--warnings-as-errors`.
- **D-38-12:** Raw `%Swoosh.Email{}` delivery and `Mailglass.Outbound.send/2`
  remain compatibility-lane bridges, but they should be documented and tested as
  transitional paths, not normalized as the preferred `1.x` posture.
- **D-38-13:** The default upgrade rehearsal gate should be strict and
  recommendation-first:
  - `mix verify.docs.migration`
  - `mix verify.stability_contract`
  - `mix docs --warnings-as-errors`
  - `cd mailglass_admin && mix docs --warnings-as-errors` when admin ships

### Proof artifacts default
- **D-38-14:** Canonical Phase 38 proof should be committed in-repo, not left
  primarily as ephemeral GitHub workflow summaries or transient temp
  directories.
- **D-38-15:** The default artifact shape should be one coherent proof bundle
  that captures:
  - tarball/package contents truth
  - HexDocs input truth
  - sibling-version/pin truth
  - release rehearsal evidence
- **D-38-16:** Tarball proof should build on the existing publish-check
  allowlists and summary data rather than inventing a second packaging checker.
- **D-38-17:** HexDocs proof should capture the exact docs inputs that define
  what will be published:
  - package `files`
  - docs `extras`
  - docs grouping
  - source URL / source reference patterns
- **D-38-18:** Sibling-package proof should make the linked-version release
  contract durable and inspectable, including the release manifest versions and
  the exact `mailglass_admin` publish-mode dependency pin.
- **D-38-19:** Release evidence should include one committed rehearsal/release
  record with concrete values such as:
  - publish workflow run URL
  - post-publish smoke run URL
  - tag used
  - Hex index confirmation
  - HexDocs URLs
  - fallback path used or explicitly not needed

### Manual checklist posture
- **D-38-20:** The manual release checklist should cover only external or
  human-gated steps:
  - GitHub Environment approval
  - branch-protection / GitHub settings verification
  - tag-based fallback dispatch if publish fan-out fails
  - live Hex / HexDocs verification
  - the 60-minute manual smoke and revert decision window
- **D-38-21:** Every manual checklist item should require explicit proof data,
  not vague confirmation. Prefer run URLs, tag names, HTTP results, timer
  boundaries, and approver identity over “looks good” prose.
- **D-38-22:** The 60-minute revert window and zero-download decision remain
  fundamentally external/temporal constraints. Document them explicitly rather
  than pretending the repo can fully automate them.
- **D-38-23:** Branch-protection verification remains accepted external closeout
  debt unless Phase 38 also repairs the currently stale branch-protection helper
  assets. Until then, the checklist must call this out honestly.

### Release engineering ergonomics
- **D-38-24:** Downstream planning should prefer reusing and exporting evidence
  from existing proof seams:
  - `mix mailglass.publish.check`
  - committed tarball allowlists
  - `verify.stability_contract`
  - docs checks
  - post-publish smoke workflow
  rather than creating parallel proof systems.
- **D-38-25:** Where external precedent is helpful, Phase 38 should borrow:
  - Hex’s prepublish inspectability and post-publish consumer test posture
  - Elixir/Django/Rails style deprecate-before-break honesty
  - SQLAlchemy’s staged migration model where warnings are resolved before the
    major-version cut
- **D-38-26:** The developer experience goal is “least surprise for serious
  adopters”: one canonical install story, one canonical upgrade story, one
  canonical release-proof bundle, and one narrow honest manual checklist.

### the agent's Discretion
- Exact filenames and directory layout for the committed proof bundle.
- Exact mix-task/script export shape used to persist publish-check and docs
  inputs into durable artifacts.
- Exact wording and formatting of the release evidence/checklist docs.
- Exact whether/how to add a secondary Ecto-enabled onboarding smoke lane, as
  long as it stays secondary to the canonical fast release-window rehearsal.

### Deferred Ideas (OUT OF SCOPE)
None stated in `38-CONTEXT.md`. [VERIFIED: repo file read]
</user_constraints>

<phase_requirements>
## Phase Requirements

Verbatim requirement text comes from [`REQUIREMENTS.md`](/Users/jon/projects/mailglass/.planning/REQUIREMENTS.md:31). [VERIFIED: repo file read]

| ID | Description | Research Support |
|----|-------------|------------------|
| RELS-01 | Maintainer can prove a clean Phoenix app can install released `mailglass` and `mailglass_admin` packages from Hex, mount admin, and execute the documented first-send workflow. | Reuse the existing `post-publish-smoke` consumer-install contract as the canonical fast lane, then add a committed proof record and a narrow secondary “first-send/Ecto” seam only if required to satisfy guide wording without slowing the revert-window lane. [VERIFIED: repo workflow audit] |
| RELS-02 | Maintainer can prove an app on the latest `0.x` upgrade path can reach `v1.0` with the documented migration steps and passing smoke checks. | Treat `guides/upgrading-to-v1_0.md` as the only authority, extend docs-migration proof around `0.3.x -> 1.0`, and keep `Mailglass.Message.new/2` warning failures release-blocking for strict adopters. [VERIFIED: repo docs + tests] |
| RELS-03 | Maintainer can verify tarball contents, HexDocs inputs, and sibling-package version pins before publish so the released artifacts match the documented contract. | Export machine-readable summaries from `mix mailglass.publish.check` plus `mix.exs`/`mailglass_admin/mix.exs` docs and pin metadata into one committed proof bundle instead of inventing another packaging system. [VERIFIED: repo mix tasks + manifests] |
| RELS-04 | Maintainer can execute a rehearsed release checklist that includes required CI buckets and any manual external checks still needed for a trustworthy `v1.0` cut. | Keep the checklist narrow: CI green, environment approval, tag-based fallback, Hex/HexDocs live checks, 60-minute manual smoke/revert window, and honest branch-protection debt. [VERIFIED: MAINTAINING.md + workflow YAML] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- The repo is Phoenix-first, Postgres-only, and ships three sibling Hex packages, with `mailglass_inbound` still outside the `v1.0` phase scope. [VERIFIED: /Users/jon/projects/mailglass/CLAUDE.md]
- Linked-version sibling releases are non-negotiable, and `mailglass_admin/mix.exs` must pin `{:mailglass, "== <version>"}` in publish mode. [VERIFIED: /Users/jon/projects/mailglass/CLAUDE.md]
- `Mailglass.Adapters.Fake` remains the merge-blocking release gate, while real-provider checks stay advisory. [VERIFIED: /Users/jon/projects/mailglass/CLAUDE.md]
- Optional-dependency support must continue to compile under `mix compile --no-optional-deps --warnings-as-errors`. [VERIFIED: /Users/jon/projects/mailglass/CLAUDE.md]
- Public docs, errors, and maintainer guidance must stay honest and exact rather than broad or aspirational. [VERIFIED: /Users/jon/projects/mailglass/CLAUDE.md]

## Summary

Phase 38 is not a greenfield release-engineering phase. The repo already has the main proof seams: `mix mailglass.publish.check` for tarball/package checks, `mix mailglass.docs.check` and `mix verify.stability_contract` for contract truth, `post-publish-smoke.yml` for released-package consumer install smoke, `guides/upgrading-to-v1_0.md` plus docs-migration tests for upgrade truth, and prior committed rehearsal/evidence artifacts that show the house style for durable release records. [VERIFIED: repo workflow audit]

The main planning risk is not missing infrastructure; it is splitting truth across too many parallel artifacts. The phase should therefore center on one committed proof bundle that exports the already-authoritative package/docs/pin data, one upgrade proof lane tied to the canonical guide, and one narrow release record/checklist that captures external proof the repo cannot synthesize for itself. [VERIFIED: repo workflow audit] [CITED: https://hex.pm/docs/publish] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]

There is one important tension to plan around: RELS-01 says “first-send workflow,” while the locked default install rehearsal stays the faster no-Ecto/no-mailer `/dev/mail/` smoke path. The clean recommendation is to keep the current fast smoke as the release-window gate and satisfy any deeper first-send proof through a clearly secondary lane or committed guide-backed artifact, not by broadening the canonical release-day smoke contract. [VERIFIED: 38-CONTEXT.md + roadmap + existing smoke workflow]

**Primary recommendation:** plan this phase as four slices: export one machine-readable/human-readable proof bundle from existing seams, harden the canonical released-package install rehearsal artifact, extend the canonical `0.3.x -> 1.0` upgrade proof, and publish one narrow release checklist plus release record that captures the external steps with concrete evidence. [VERIFIED: repo workflow audit]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Pre-publish tarball/docs/pin proof export | Mix tasks at repo root [VERIFIED: `mix mailglass.publish.check`, `mix.exs`] | `.planning/publish/` committed artifacts [VERIFIED: allowlists exist] | The canonical metadata already lives in Mix tasks and package config, so Phase 38 should export that truth rather than re-scan the repo from a new script. [VERIFIED: repo audit] |
| Released-package consumer install rehearsal | GitHub Actions `post-publish-smoke.yml` [VERIFIED: workflow YAML] | ExUnit installer smoke tests [VERIFIED: `install_first_preview_smoke_test.exs`] | The workflow exercises real Hex packages in a fresh Phoenix host, while the ExUnit smoke locks the local contract shape that the workflow mirrors. [VERIFIED: repo audit] |
| Upgrade rehearsal | Canonical guides + ExUnit docs migration proof [VERIFIED: `guides/upgrading-to-v1_0.md`, `docs_migration_smoke_test.exs`] | Optional disposable fixture/app smoke [ASSUMED] | Upgrade truth is docs-first today, so planning should extend that path before considering a heavier host-app migration harness. |
| Linked-version sibling truth | `release-please-config.json`, `.release-please-manifest.json`, `mailglass_admin/mix.exs` [VERIFIED: repo file read] | Admin pin tests [VERIFIED: `mix_config_test.exs`] | The release manifest and publish-mode dep pin already define the sibling contract, and tests already guard the literal pin form. [VERIFIED: repo audit] |
| Manual release checklist and release record | `MAINTAINING.md` [VERIFIED: repo file read] | committed phase artifact [VERIFIED: prior `13-04-REHEARSAL.md` and `13-05-PUBLISH-EVIDENCE.md`] | Human-gated steps belong in the runbook, but the evidence should still be committed in phase-local docs for auditability. [VERIFIED: repo audit] |

## Standard Stack

### Core

| Library / Artifact | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `mailglass` release metadata | `0.3.2` in `mix.exs` [VERIFIED: repo file read] | Current core package version and docs/package config source | Phase 38 is rehearsing the current sibling release line, not introducing a new release tool. [VERIFIED: repo file read] |
| `mailglass_admin` release metadata | `0.3.2` in `mailglass_admin/mix.exs` [VERIFIED: repo file read] | Current admin package version and publish-mode dep pin source | The sibling-pin proof must reflect the exact publish-mode package metadata already shipped. [VERIFIED: repo file read] |
| Hex publish contract | Hex `v2.2.1` docs page [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] | Defines `--dry-run`, `mix hex.build --unpack`, docs auto-publish, and revert windows | Phase 38’s release-window semantics and inspectability posture line up directly with the official Hex contract. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] |
| Hex package publishing guide | current Hex guide [CITED: https://hex.pm/docs/publish] | Defines package metadata, included files, CI publishing cautions, and post-publish consumer testing | The repo’s release proof mirrors Hex’s own advice to inspect package contents and test the published package from a consumer app. [CITED: https://hex.pm/docs/publish] |
| ExDoc docs configuration | ExDoc `v0.39.3` docs page [CITED: https://hexdocs.pm/ex_doc/0.39.3/Mix.Tasks.Docs.html] | Defines `extras`, `groups_for_extras`, `source_url`, and `source_ref` semantics | Phase 38 needs exact HexDocs input truth, and ExDoc documents the fields the repo already uses in both `mix.exs` files. [CITED: https://hexdocs.pm/ex_doc/0.39.3/Mix.Tasks.Docs.html] |

### Supporting

| Library / Artifact | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `mix mailglass.publish.check` | local Mix task since `0.2.0` [VERIFIED: compiled docs + source] | Tarball allowlist, metadata, deps, linked-version, compile, audit, and reviewer-summary checks | Use as the single authoritative export seam for RELS-03. [VERIFIED: source audit] |
| `mix mailglass.docs.check` | local Mix task since `0.3.0` [VERIFIED: compiled docs + source] | Tier 1 docs drift guard across README/guides/admin docs | Use to keep release/install/upgrade/checklist docs honest. [VERIFIED: source audit] |
| `mix verify.stability_contract` | local alias [VERIFIED: `mix.exs`] | Repo-root proof composed from core support contract, admin support contract, and no-optional-deps compile | Use as the semantic release-truth gate before publish and in upgrade rehearsal. [VERIFIED: source audit] |
| `post-publish-smoke.yml` | current workflow [VERIFIED: workflow YAML] | Real released-package Phoenix host install, compile, boot, and `/dev/mail/` HTTP 200 proof | Use as the canonical fast release-window install posture and as the release record’s run URL source. [VERIFIED: workflow YAML] |
| `gh` CLI | `gh` available locally [VERIFIED: local env probe] | Read run URLs, release metadata, and release/manual-proof data during rehearsal or release | Use for maintainers when filling the committed rehearsal/release record. [VERIFIED: local env probe] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Exporting from `mix mailglass.publish.check` and `mix.exs` docs config [VERIFIED: repo audit] | A new standalone packaging/docs scanner [ASSUMED] | A new scanner would duplicate existing truth and create drift risk between prepublish gating and proof artifacts. [VERIFIED: repo audit] |
| One coherent proof bundle in-repo [VERIFIED: 38-CONTEXT.md] | Workflow summaries only [ASSUMED] | Workflow summaries are helpful evidence, but they are ephemeral and not enough for the durable `v1.0` proof posture locked in Phase 38. [VERIFIED: context + prior evidence patterns] |
| Canonical fast no-Ecto install smoke [VERIFIED: 38-CONTEXT.md + workflow YAML] | Making an Ecto-enabled host the default release-window gate [ASSUMED] | The slower path weakens revert-window feedback and contradicts the locked canonical smoke contract. [VERIFIED: context + workflow YAML] |
| Guide-backed upgrade proof plus targeted tests [VERIFIED: docs/tests] | A large historical matrix of old upgrade paths [ASSUMED] | The repo only promises the latest supported `0.3.x -> 1.0` path, so broader rehearsal would add maintenance cost without changing the public contract. [VERIFIED: context + guides] |

**Installation / execution:**  
```bash
mix mailglass.publish.check --package mailglass
mix mailglass.publish.check --package mailglass_admin
mix verify.stability_contract
mix test test/mailglass/install/install_first_preview_smoke_test.exs --warnings-as-errors
mix test test/mailglass/docs_migration_smoke_test.exs --warnings-as-errors
```  
[VERIFIED: repo aliases, tasks, and tests]

**Version verification:** The phase is not selecting new third-party package versions; it is rehearsing the repo’s current sibling release line (`0.3.2`) and current documented tool contracts from Hex and ExDoc. [VERIFIED: repo file read] [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] [CITED: https://hexdocs.pm/ex_doc/0.39.3/Mix.Tasks.Docs.html]

## Architecture Patterns

### System Architecture Diagram

```text
mix.exs + mailglass_admin/mix.exs
    |                     \
    |                      -> ExDoc inputs (extras, groups, source_ref, source_url)
    v
mix mailglass.publish.check
    |
    +--> allowlist / tarball / metadata / dep / linked-version summary
    |
    v
committed proof bundle
    |
    +--> release rehearsal record
    +--> release checklist
    +--> package/docs/pin truth snapshot
    |
    v
publish-hex.yml ---> Hex.pm / HexDocs
    |
    v
post-publish-smoke.yml ---> fresh Phoenix consumer app ---> install -> compile -> boot -> GET /dev/mail/
    |
    v
committed release evidence record
```
[VERIFIED: repo workflow + mix-task audit]

### Recommended Project Structure

```text
.planning/phases/38-release-rehearsal-and-proof-artifacts/
├── 38-RESEARCH.md                # This research file [VERIFIED: current output path]
├── 38-PROOF-BUNDLE.md            # One human-readable committed proof bundle [ASSUMED]
├── 38-RELEASE-CHECKLIST.md       # Narrow manual/external checklist with proof fields [ASSUMED]
└── 38-REHEARSAL-RECORD.md        # Concrete rehearsal or final release record with URLs/tags [ASSUMED]

.planning/publish/
├── mailglass-files.expected      # Existing tarball allowlist [VERIFIED: repo file read]
├── mailglass_admin-files.expected# Existing tarball allowlist [VERIFIED: repo file read]
├── mailglass-publish-summary.*   # Exported publish-check truth from existing task [ASSUMED]
└── mailglass_admin-publish-summary.* [ASSUMED]
```

### Pattern 1: Export truth from the existing publish gate

**What:** Extend `mix mailglass.publish.check` to write durable summary artifacts from the checks it already performs instead of creating a second packaging proof path. [VERIFIED: source audit]

**When to use:** Use for RELS-03 package/docs/pin proof and for any data the release checklist needs before publish. [VERIFIED: requirements + context]

**Example:**
```elixir
# Source: lib/mix/tasks/mailglass.publish.check.ex
step(counts, :unchanged, package, "check linked-version constraint", ctx, &verify_linked_constraint/1)
step(counts, :unchanged, package, "check prod deps resolution", ctx, &verify_prod_deps/1)
step(counts, :update, package, "write reviewer summary", ctx, &write_summary/1)
```
[VERIFIED: /Users/jon/projects/mailglass/lib/mix/tasks/mailglass.publish.check.ex]

### Pattern 2: Keep the release-window install lane fast and canonical

**What:** Treat the current released-package Phoenix host smoke as the release-window gate: add deps, `mix deps.get`, `mix mailglass.install`, `mix compile --warnings-as-errors`, boot, and verify `GET /dev/mail/` returns `200`. [VERIFIED: 38-CONTEXT.md + `post-publish-smoke.yml`]

**When to use:** Always for release-day trust and revert-window feedback. [VERIFIED: context + MAINTAINING.md]

**Example:**
```yaml
# Source: .github/workflows/post-publish-smoke.yml
- name: Run mix mailglass.install
  run: mix mailglass.install
- name: Compile, fail on warnings
  run: mix compile --warnings-as-errors
- name: Boot endpoint and curl /dev/mail/
```
[VERIFIED: /Users/jon/projects/mailglass/.github/workflows/post-publish-smoke.yml]

### Pattern 3: Treat upgrade proof as docs-authority plus executable smoke

**What:** Keep `guides/upgrading-to-v1_0.md` as the only upgrade authority, and make tests prove that guide’s supported lane, strict-CI posture, and subordinate-guide wiring. [VERIFIED: docs + tests]

**When to use:** For RELS-02 and any future `1.x` compatibility verification that should stay recommendation-first. [VERIFIED: requirements + methodology]

**Example:**
```elixir
# Source: test/mailglass/docs_migration_smoke_test.exs
assert canonical =~ "canonical latest-`0.x` to `1.0` upgrade guide"
assert canonical =~ "Mailglass.Outbound.send/2"
assert canonical =~ "Mailglass.deliver/2"
assert canonical =~ "mix mailglass.upgrade.v0_2"
```
[VERIFIED: /Users/jon/projects/mailglass/test/mailglass/docs_migration_smoke_test.exs]

### Anti-Patterns to Avoid

- **Parallel proof systems:** Do not add a new package/docs validator outside `mix mailglass.publish.check` and the existing docs config, because that would create two authorities for the same artifact truth. [VERIFIED: repo audit]
- **Making the slower onboarding path canonical:** Do not replace the current no-Ecto release-window smoke with a deeper host-app path; keep any Ecto/send proof secondary. [VERIFIED: 38-CONTEXT.md]
- **Ephemeral-only evidence:** Do not leave final proof only in workflow summaries or temp directories; commit the release-relevant record in-repo. [VERIFIED: 38-CONTEXT.md]
- **Checklist prose without proof fields:** Do not use “looks good” checklist items; require tag, run URL, approver, HTTP result, timer boundary, or fallback decision. [VERIFIED: 38-CONTEXT.md]

## Don’t Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Tarball inspection | A custom tarball parser or separate package manifest checker [ASSUMED] | `mix hex.build --unpack` semantics via `mix mailglass.publish.check` [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] | Hex already defines the inspectable package flow, and the repo already wraps it. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html] [VERIFIED: source audit] |
| Published-package consumer smoke | A bespoke local-only fixture unrelated to Hex [ASSUMED] | `post-publish-smoke.yml` consumer-install job plus committed evidence [VERIFIED: workflow YAML] | RELS-01 is about released packages from Hex, not path dependencies. [VERIFIED: requirements + workflow YAML] |
| HexDocs input truth | A copied docs manifest maintained by hand [ASSUMED] | `docs()` config in `mix.exs` and `mailglass_admin/mix.exs` [VERIFIED: repo file read] | The exact publish inputs already live in package config and are what ExDoc reads. [CITED: https://hexdocs.pm/ex_doc/0.39.3/Mix.Tasks.Docs.html] |
| Release evidence tracking | A heavyweight release dossier or duplicated workflow log archive [ASSUMED] | A small committed proof bundle plus one release record [VERIFIED: prior evidence files + Phase 38 decisions] | Prior artifacts show the repo favors narrow durable evidence, and Phase 38 explicitly locks that posture. [VERIFIED: repo audit] |

**Key insight:** The winning plan shape is “export and commit existing truth,” not “invent more release machinery.” [VERIFIED: repo workflow audit]

## Common Pitfalls

### Pitfall 1: RELS-01 gets over-expanded into a slower canonical smoke
**What goes wrong:** The plan broadens the release-day smoke from `/dev/mail/` proof into full Ecto/send/admin behavior and makes the revert-window gate slower and noisier. [VERIFIED: context + workflow YAML]  
**Why it happens:** The roadmap wording mentions the documented first-send workflow, but the locked install contract explicitly keeps the fast no-Ecto path canonical. [VERIFIED: roadmap + context]  
**How to avoid:** Keep the existing released-package smoke as the required gate and treat any first-send/Ecto proof as secondary and separately labeled. [VERIFIED: context]  
**Warning signs:** Planned tasks replace `--no-ecto --no-mailer` with a database-backed host or remove `/dev/mail/` from the release-window proof. [VERIFIED: context + workflow YAML]

### Pitfall 2: Proof artifacts duplicate, rather than export, package/docs truth
**What goes wrong:** The plan introduces a separate manifest or scanner for package files, docs extras, or sibling pins. [ASSUMED]  
**Why it happens:** Proof work can look like a documentation task instead of a data-export task. [ASSUMED]  
**How to avoid:** Make exported summaries come from `mix mailglass.publish.check`, `.release-please-manifest.json`, and the `docs()`/`package()` config in each `mix.exs`. [VERIFIED: repo file read]  
**Warning signs:** New scripts re-derive the same file list or docs grouping already present in the package config. [VERIFIED: repo file read]

### Pitfall 3: Release records keep transient URLs but miss the fallback decision
**What goes wrong:** The artifact records run URLs but does not say whether the canonical release event fired automatically or whether the tag-based fallback path was used. [VERIFIED: prior rehearsal artifact patterns]  
**Why it happens:** Run URLs are easy to capture; decision semantics are easier to forget. [ASSUMED]  
**How to avoid:** Require explicit fields for tag used, publish run URL, smoke run URL, fallback used/not needed, and environment approver. [VERIFIED: Phase 38 decisions + prior evidence files]  
**Warning signs:** A release record can be read without learning whether publish/smoke were automatic or manually dispatched. [VERIFIED: prior artifact expectations]

### Pitfall 4: Upgrade proof stops at docs syntax instead of strict-CI behavior
**What goes wrong:** The guide parses, but warning-producing bridges like `Mailglass.Message.new/2` are not treated as release-blocking for strict adopters. [VERIFIED: context + upgrade guide]  
**Why it happens:** Guide tests are easier than exercising the documented `--warnings-as-errors` posture. [VERIFIED: existing docs tests]  
**How to avoid:** Keep `mix verify.docs.migration`, `mix verify.stability_contract`, and docs-as-errors in the default upgrade rehearsal gate. [VERIFIED: context + aliases]  
**Warning signs:** Planned verification omits docs builds or does not distinguish warning-emitting bridges from silent compatibility bridges. [VERIFIED: upgrade guide + compatibility tests]

## Code Examples

Verified patterns from shipped sources:

### Docs input truth in `mix.exs`
```elixir
# Source: mix.exs
docs: [
  source_url: @source_url,
  source_ref: "v#{@version}",
  extras: [
    "README.md",
    "docs/api_stability.md",
    "guides/compatibility-and-deprecations.md",
    "guides/upgrading-to-v1_0.md"
  ],
  groups_for_extras: [
    Overview: ["README.md"],
    Contract: ["docs/api_stability.md", "guides/compatibility-and-deprecations.md"]
  ]
]
```
[VERIFIED: /Users/jon/projects/mailglass/mix.exs]

### Linked-version sibling proof in `mailglass_admin/mix.exs`
```elixir
# Source: mailglass_admin/mix.exs
defp mailglass_dep do
  if System.get_env("MIX_PUBLISH") == "true" do
    {:mailglass, "== 0.3.2"}
  else
    {:mailglass, path: "..", override: true}
  end
end
```
[VERIFIED: /Users/jon/projects/mailglass/mailglass_admin/mix.exs]

### Canonical released-package consumer smoke
```yaml
# Source: .github/workflows/post-publish-smoke.yml
- name: Generate Phoenix host project
  run: mix phx.new sandbox --module Sandbox --app sandbox --no-ecto --no-mailer --install
- name: Add mailglass deps
- name: mix deps.get
- name: Run mix mailglass.install
- name: Compile, fail on warnings
- name: Boot endpoint and curl /dev/mail/
```
[VERIFIED: /Users/jon/projects/mailglass/.github/workflows/post-publish-smoke.yml]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual or ambiguous release fallback semantics [VERIFIED: prior phase artifacts] | Tag-based canonical release event plus explicit `workflow_dispatch` fallback against the release tag [VERIFIED: workflow comments + MAINTAINING.md] | 2026-04-28 rehearsal captured in `13-04-REHEARSAL.md` [VERIFIED: prior artifact] | Maintainers can recover a missed fan-out without publishing from `main`. [VERIFIED: prior artifact + MAINTAINING.md] |
| Proof left mostly in workflow output [VERIFIED: prior milestone history] | Small committed rehearsal/evidence artifacts in `.planning/` [VERIFIED: `13-04-REHEARSAL.md`, `13-05-PUBLISH-EVIDENCE.md`, `27-02-EVIDENCE.md`] | 2026-04-28 and 2026-05-02 [VERIFIED: artifact dates] | Phase 38 can extend an existing durable evidence style instead of inventing one. [VERIFIED: repo audit] |
| Upgrade posture spread across older guides [VERIFIED: docs history in current guides] | One canonical `guides/upgrading-to-v1_0.md` plus subordinate references [VERIFIED: current guide text] | 2026-05-05 Phase 36 [VERIFIED: state + phase research] | RELS-02 can target one supported `0.3.x -> 1.0` story instead of a matrix. [VERIFIED: context + guides] |
| Generic docs generation assumptions [ASSUMED] | Explicit ExDoc `extras`, `groups_for_extras`, `source_url`, and `source_ref` in both packages [VERIFIED: repo file read] | already present as of 2026-05-06 [VERIFIED: repo file read] | RELS-03 can snapshot exact HexDocs inputs directly from package config. [VERIFIED: repo file read] |

**Deprecated/outdated:**
- Treating `upgrading-from-v0_1.md` or `migration-from-swoosh.md` as competing upgrade authorities is outdated; they are now subordinate references only. [VERIFIED: current guide text]
- Treating workflow summaries alone as sufficient release proof is outdated for this phase because the locked Phase 38 posture requires committed in-repo artifacts. [VERIFIED: 38-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | RELS-01 requires a secondary Ecto-enabled first-send proof lane in addition to the canonical smoke gate. | Architectural Responsibility Map, Common Pitfalls | The plan must cover the public getting-started story without over-scoping the canonical release smoke. |
| A2 | The recommended phase-local filenames (`38-PROOF-BUNDLE.md`, `38-RELEASE-CHECKLIST.md`, `38-REHEARSAL-RECORD.md`) are suitable even though the exact names are still discretionary. | Recommended Project Structure | The planner may choose a different layout, but the slice boundaries should remain the same. |

## Open Questions (RESOLVED)

1. **Does RELS-01 require a secondary Ecto-backed “first-send” proof artifact in addition to the canonical `/dev/mail/` smoke?**
   - What we know: the roadmap mentions first-send workflow, but the locked default install rehearsal is the fast no-Ecto `/dev/mail/` path. [VERIFIED: roadmap + context]
   - Resolution: add a secondary executable Ecto/send proof slice now, but keep it explicitly non-canonical for the release-window gate. [RESOLVED 2026-05-06]
   - Why: the public requirement and getting-started guide promise more than `/dev/mail/` boot readiness, so the phase needs one disposable-host first-send proof seam in addition to the fast smoke. [VERIFIED: requirements + guide + smoke workflow]

2. **Should the proof bundle export JSON, Markdown, or both from `mix mailglass.publish.check`?**
   - What we know: the task already writes reviewer-oriented summaries and the exact filename/export shape is discretionary. [VERIFIED: source audit + context]
   - What's unclear: whether downstream plans want machine-readable diffability, human readability, or both. [ASSUMED]
   - Recommendation: prefer one machine-readable artifact per package plus one human-readable phase bundle that embeds or summarizes those exports. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Mix tasks, docs builds, local smoke/test commands [VERIFIED: repo task audit] | ✓ [VERIFIED: local env probe] | `1.19.5` [VERIFIED: local env probe] | — |
| Erlang/OTP | Elixir runtime for local proof execution [VERIFIED: local env probe] | ✓ [VERIFIED: local env probe] | `28` [VERIFIED: local env probe] | — |
| Mix | All release-proof commands [VERIFIED: repo task audit] | ✓ [VERIFIED: local env probe] | `1.19.5` [VERIFIED: local env probe] | — |
| Git | Release/tag inspection and repo state [VERIFIED: workflow + runbook] | ✓ [VERIFIED: local env probe] | `2.41.0` [VERIFIED: local env probe] | — |
| `gh` CLI | Capturing run URLs and release metadata for committed evidence [ASSUMED] | ✓ [VERIFIED: local env probe] | available [VERIFIED: local env probe] | Manual browser capture if unavailable [ASSUMED] |
| PostgreSQL client tools (`psql`, `pg_isready`) | Some local test/setup flows and publish-check Postgres waits [VERIFIED: workflows/tests] | ✓ [VERIFIED: local env probe] | `14.17` [VERIFIED: local env probe] | Use workflow-hosted Postgres in CI if local tooling is absent [ASSUMED] |
| Docker | Optional local reproduction of CI-like service environments [ASSUMED] | ✓ [VERIFIED: local env probe] | `29.4.1` [VERIFIED: local env probe] | Skip local container reproduction and rely on GitHub Actions services [ASSUMED] |
| GitHub Actions environment + `HEX_API_KEY` | Real publish and environment approval [VERIFIED: workflows + MAINTAINING.md] | unknown from repo-local probes [VERIFIED: local env probe] | — | No safe fallback for actual publish; rehearsal can still proceed locally and in dry-run mode. [VERIFIED: MAINTAINING.md + Hex docs] |

**Missing dependencies with no fallback:**
- None for planning or dry-run research. Real publish still requires GitHub environment approval and `HEX_API_KEY`, which cannot be verified from the repo alone. [VERIFIED: local env probe + workflow audit]

**Missing dependencies with fallback:**
- None currently detected. [VERIFIED: local env probe]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix test aliases [VERIFIED: repo file read] |
| Config file | none explicit; Mix aliases and `test/` layout are authoritative [VERIFIED: repo audit] |
| Quick run command | `mix test test/mailglass/install/install_first_preview_smoke_test.exs --warnings-as-errors` [VERIFIED: repo tests] |
| Full suite command | `mix verify.stability_contract` [VERIFIED: repo aliases] |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RELS-01 | Released packages install into a fresh Phoenix host, `/dev/mail/` boots cleanly, and the documented first-send workflow executes in a disposable Ecto-backed host [VERIFIED: workflow + test + requirements] | workflow smoke + ExUnit contract + secondary fixture rehearsal [VERIFIED: repo audit] | `mix test test/mailglass/install/install_first_preview_smoke_test.exs --warnings-as-errors` plus a new executable first-send rehearsal test aligned with `guides/getting-started.md` [VERIFIED: repo audit] | ✅ fast smoke / ❌ first-send rehearsal |
| RELS-02 | Canonical `0.3.x -> 1.0` upgrade path remains truthful and strict-CI aware [VERIFIED: guide + tests] | docs smoke + contract test [VERIFIED: repo audit] | `mix verify.docs.migration` and `mix test test/mailglass/compatibility_contract_test.exs --warnings-as-errors` [VERIFIED: repo aliases/tests] | ✅ [VERIFIED: repo file read] |
| RELS-03 | Tarball contents, docs inputs, and sibling pins match the documented contract [VERIFIED: repo tasks/config] | Mix task + targeted tests [VERIFIED: repo audit] | `mix mailglass.publish.check --package mailglass` and `mix mailglass.publish.check --package mailglass_admin` [VERIFIED: source audit] | ✅ for tarball/pin checks; ❌ for committed proof-bundle export tests [VERIFIED: repo audit] |
| RELS-04 | Release checklist captures CI buckets and manual external checks with proof data [VERIFIED: MAINTAINING.md + context] | docs contract + artifact grep checks [ASSUMED] | likely `rg`-based verification against committed checklist/record files plus `mix verify.stability_contract` [ASSUMED] | ❌ Wave 0 [ASSUMED] |

### Sampling Rate
- **Per task commit:** `mix test <targeted file> --warnings-as-errors` or the touched Mix task command. [VERIFIED: repo testing pattern]
- **Per wave merge:** `mix verify.stability_contract`. [VERIFIED: repo aliases]
- **Phase gate:** `mix verify.stability_contract`, both `mix mailglass.publish.check --package ...` runs, docs builds with warnings as errors, and any new artifact-shape assertions green before `/gsd-verify-work`. [VERIFIED: context + aliases + tasks]

### Wave 0 Gaps
- [ ] Add deterministic tests or checks for the new proof-bundle export shape so RELS-03 is not validated only by manual file inspection. [ASSUMED]
- [ ] Add deterministic checks for the new release checklist/release record fields so RELS-04 is not validated only by prose review. [ASSUMED]
- [ ] Add the executable first-send/Ecto rehearsal test and evidence fields required by the resolved RELS-01 decision. [RESOLVED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no [ASSUMED] | N/A; publish authentication is delegated to Hex/GitHub credentials rather than app-auth code in this phase. [VERIFIED: workflow audit] |
| V3 Session Management | no [ASSUMED] | N/A for the release-proof phase itself. [ASSUMED] |
| V4 Access Control | yes [VERIFIED: workflow audit] | GitHub Environment approval, protected-ref release flow, and explicit branch-protection verification steps in `MAINTAINING.md`. [VERIFIED: MAINTAINING.md + workflow YAML] |
| V5 Input Validation | yes [VERIFIED: source audit] | Strict workflow inputs (`tag`, `package`, `dry_run`) and Mix task CLI validation for `mailglass.publish.check`/`mailglass.docs.check`. [VERIFIED: workflow YAML + task source] |
| V6 Cryptography | yes [VERIFIED: workflow audit] | Never hand-roll credential handling; use `HEX_API_KEY` secret storage and Hex/GitHub platform controls. [VERIFIED: workflow YAML + Hex publish docs] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Publishing from the wrong ref or from `main` instead of the reviewed release tag | Tampering / Elevation | Keep tag-based checkout in `publish-hex.yml` and tag-based fallback wording in `MAINTAINING.md`; record the actual tag in the committed release record. [VERIFIED: workflow YAML + MAINTAINING.md] |
| Credential exposure or unsafe republish behavior | Information Disclosure / Elevation | Publish only through the GitHub Environment gate with `HEX_API_KEY` in secrets; do not move publish to ad hoc local scripts. [VERIFIED: workflow YAML + Hex docs] |
| Artifact drift between docs claims and released package contents | Tampering / Repudiation | Reuse `mix mailglass.publish.check`, docs config export, docs checks, and committed proof artifacts. [VERIFIED: repo audit] |
| False confidence from ephemeral-only proof | Repudiation | Commit rehearsal/release records with run URLs, tag, approver, Hex/HexDocs checks, and fallback usage. [VERIFIED: context + prior artifacts] |
| Branch-protection drift outside the repo | Tampering | Keep explicit manual verification in the release checklist until the stale helper assets are repaired. [VERIFIED: 38-CONTEXT.md + branch-protection workflow] |

## Sources

### Primary (HIGH confidence)
- [`38-CONTEXT.md`](/Users/jon/projects/mailglass/.planning/phases/38-release-rehearsal-and-proof-artifacts/38-CONTEXT.md) - locked decisions and canonical refs. [VERIFIED: repo file read]
- [`REQUIREMENTS.md`](/Users/jon/projects/mailglass/.planning/REQUIREMENTS.md) - RELS-01..04 requirement text. [VERIFIED: repo file read]
- [`MAINTAINING.md`](/Users/jon/projects/mailglass/MAINTAINING.md) - release runbook, CI buckets, manual external checks, and revert window. [VERIFIED: repo file read]
- [`mix.exs`](/Users/jon/projects/mailglass/mix.exs) and [`mailglass_admin/mix.exs`](/Users/jon/projects/mailglass/mailglass_admin/mix.exs) - package files, docs config, aliases, versions, and sibling pin logic. [VERIFIED: repo file read]
- [`.github/workflows/publish-hex.yml`](/Users/jon/projects/mailglass/.github/workflows/publish-hex.yml), [`.github/workflows/post-publish-smoke.yml`](/Users/jon/projects/mailglass/.github/workflows/post-publish-smoke.yml), [`.github/workflows/release-please.yml`](/Users/jon/projects/mailglass/.github/workflows/release-please.yml), [`.github/workflows/ci.yml`](/Users/jon/projects/mailglass/.github/workflows/ci.yml) - release, smoke, linked-version, and CI gate contracts. [VERIFIED: repo file read]
- [`lib/mix/tasks/mailglass.publish.check.ex`](/Users/jon/projects/mailglass/lib/mix/tasks/mailglass.publish.check.ex), [`lib/mix/tasks/mailglass.docs.check.ex`](/Users/jon/projects/mailglass/lib/mix/tasks/mailglass.docs.check.ex), [`lib/mix/tasks/mailglass.stability.check.ex`](/Users/jon/projects/mailglass/lib/mix/tasks/mailglass.stability.check.ex) - existing proof/export seams. [VERIFIED: repo file read]
- [`test/mailglass/install/install_first_preview_smoke_test.exs`](/Users/jon/projects/mailglass/test/mailglass/install/install_first_preview_smoke_test.exs), [`test/mailglass/docs_migration_smoke_test.exs`](/Users/jon/projects/mailglass/test/mailglass/docs_migration_smoke_test.exs), [`mailglass_admin/test/mailglass_admin/mix_config_test.exs`](/Users/jon/projects/mailglass/mailglass_admin/test/mailglass_admin/mix_config_test.exs) - existing install, upgrade, and sibling-pin proof. [VERIFIED: repo file read]
- https://hex.pm/docs/publish - Hex package publishing guide. [CITED: https://hex.pm/docs/publish]
- https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html - official Hex publish, dry-run, unpack, docs publish, and revert semantics. [CITED: https://hexdocs.pm/hex/Mix.Tasks.Hex.Publish.html]
- https://hexdocs.pm/ex_doc/0.39.3/Mix.Tasks.Docs.html - official ExDoc docs-input and grouping semantics. [CITED: https://hexdocs.pm/ex_doc/0.39.3/Mix.Tasks.Docs.html]

### Secondary (MEDIUM confidence)
- https://hexdocs.pm/elixir/1.18.0/compatibility-and-deprecations.html - deprecate-before-remove and warnings-as-errors precedent used for upgrade-proof posture. [CITED: https://hexdocs.pm/elixir/1.18.0/compatibility-and-deprecations.html]

### Tertiary (LOW confidence)
- None. [VERIFIED: research log]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - the phase reuses existing repo tasks/workflows and official Hex/ExDoc docs rather than choosing a novel toolchain. [VERIFIED: repo audit] [CITED: https://hex.pm/docs/publish]
- Architecture: HIGH - install, upgrade, publish, and evidence seams are already present in code and prior artifacts. [VERIFIED: repo audit]
- Pitfalls: HIGH - the key failure modes are visible directly in locked decisions, current workflow shape, and prior rehearsal/evidence artifacts. [VERIFIED: context + repo audit]

**Research date:** 2026-05-06 [VERIFIED: local system date]  
**Valid until:** 2026-06-05 for repo-internal seams, or earlier if release workflows or package metadata change. [ASSUMED]
