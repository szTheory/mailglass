# Phase 148: Release and Adoption Proof - Research

**Researched:** 2026-08-01
**Domain:** Hex release automation, published-package adoption proof, and B2C regression evidence
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Release Boundary
- **D-01:** Release Please must produce linked `mailglass` and `mailglass_admin` 2.4.0 only. Preserve `mailglass_inbound` at 2.1.1.
- **D-02:** Reconcile the publish fan-out so a core/admin release neither republishes inbound nor requires an inbound publish to complete.
- **D-03:** Preserve the existing protected Hex publication posture; this phase adapts the release path to the locked package boundary rather than introducing a second release mechanism.

### Proof and Published Surface
- **D-04:** Treat the existing focused suppression tests as the canonical PROOF-02 evidence: stream unsubscribe remains stream-scoped, while complaint and hard-bounce suppression remains address-wide and blocks transactional delivery.
- **D-05:** Treat the existing B2C docs-contract tests as the canonical PROOF-03 evidence: every B2C example parses against current APIs and the guide remains included in the published HexDocs/package surface.
- **D-06:** Include the existing tenant-scoped LiveView refresh and foreign-tenant rejection test in the release-proof bundle so Phase 147's browser-facing behavior is ratcheted into release evidence.
- **D-07:** Reuse `scripts/consumer_install_smoke.sh` for both the shift-left local-path proof and the post-publication Hex-mode proof. Release completion requires the clean published-package consumer path, not only a workspace/path-dependency pass.

### Completion Boundary
- **D-08:** External B2C launch gates remain recorded production-adoption blockers, but they are not completion criteria for the Mailglass 2.4.0 release.
- **D-09:** Do not add Crosswake integration, sibling-product behavior, or a `crosswake_mailglass` package in this phase.

### the agent's Discretion
- Exact workflow dependency and conditional structure used to remove inbound from the core/admin release fan-out, provided the existing release protections remain intact.
- Exact commands and artifact format used to collect the focused release-proof bundle.
- Whether a compatibility check is implemented as a focused test, workflow assertion, or both, provided unchanged inbound 2.1.1 is proven compatible with core 2.4.0.

### Deferred Ideas (OUT OF SCOPE)
- Sigra/host magic-link validation and consumption journey — external production launch gate.
- Chimeway/host category-level one-click preferences — external production launch gate.
- Parapet complaint paging, Accrue payment journeys, and host email recovery — external production launch gates.
- Crosswake integration and any `crosswake_mailglass` package — explicitly outside the Mailglass package boundary.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROOF-02 | Stream unsubscribe is not transactional suppression; bounce and complaint remain address-wide. | Existing focused webhook and pre-send suppression tests provide canonical runnable evidence. |
| PROOF-03 | B2C examples parse and the guide is in published HexDocs/package surface. | Existing docs-contract test parses every B2C fence; root package metadata includes the guide in tarball and HexDocs extras/groups. |
| REL-01 | Publish linked core/admin 2.4.0, retain inbound 2.1.1, and pass a clean Hex consumer smoke. | The Release Please linked group, publish fan-out graph, post-publish polling, and shared consumer harness identify the exact implementation seams. |
</phase_requirements>

## Summary

Phase 148 is primarily a release-graph correction and evidence orchestration phase, not a new product feature. The repository already has the three requested behavioral proofs and a two-mode clean-consumer harness. The source manifest is currently `mailglass`/`mailglass_admin` 2.3.0 and `mailglass_inbound` 2.1.1; the Release Please manifest has the same values, while `release-please-config.json` links only the core and admin components. [VERIFIED: codebase grep]

The blocking mismatch is isolated to `.github/workflows/publish-hex.yml`: a release event currently starts `publish-inbound`, and `publish-admin` lists it in `needs` and requires its success. That contradicts the independently versioned inbound contract. GitHub Actions skips dependent jobs after a failed or skipped `needs` job unless their condition deliberately handles it, so the clean fix is to make the core/admin release path depend only on `gate-ci-green` and `publish-core`, while preserving the explicit inbound-only dispatch path. [VERIFIED: codebase grep] [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax]

**Primary recommendation:** Add a tested core/admin-only release-event branch to `publish-hex.yml`, retain manual inbound-only publication, retain protected `hex-publish` and all CI gates, then collect one focused proof bundle before Release Please and rely on existing post-publish Hex/HexDocs waits plus the Hex-mode consumer smoke after the tags publish. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Release version calculation | CI / release automation | GitHub Releases | Release Please owns component grouping and tags. [VERIFIED: codebase grep] |
| Protected Hex package publication | CI / release automation | Hex registry | `publish-hex.yml` owns gated jobs and `hex-publish` environment access. [VERIFIED: codebase grep] |
| Linked core/admin resolution | Package metadata | Hex registry | Admin uses the published core under `MIX_PUBLISH=true`; linked release versions keep the pair aligned. [VERIFIED: codebase grep] |
| Inbound compatibility proof | CI / published consumer | Hex registry | Existing inbound 2.1.1 is an optional installed dependency in the Hex smoke and must resolve with published core 2.4.0. [VERIFIED: codebase grep] |
| B2C/suppression/operator evidence | Test suite | Postgres/PubSub test support | Tests prove domain behavior before release; no production data migration is involved. [VERIFIED: codebase grep] |

## Project Constraints (from CLAUDE.md)

- Keep `mailglass`, `mailglass_admin`, and `mailglass_inbound` as sibling Hex packages; linked releases are core/admin only. [VERIFIED: CLAUDE.md]
- Preserve protected-ref publication and `hex-publish`; do not introduce a second release path or expose `HEX_API_KEY` in PR jobs. [VERIFIED: CLAUDE.md]
- Use Conventional Commits, pin third-party GitHub Actions by SHA, and keep docs language direct and exact. [VERIFIED: CLAUDE.md]
- Do not place PII in telemetry or expand scope into marketing email, Crosswake, or external adopter systems. [VERIFIED: CLAUDE.md]
- Preserve the mandatory `mix compile --no-optional-deps --warnings-as-errors` posture and committed admin static bundle rule. [VERIFIED: CLAUDE.md]

## Standard Stack

### Core

| Library / system | Version | Purpose | Why Standard |
|------------------|---------|---------|--------------|
| Release Please | configured action v5.0.0 SHA | Produces package release PRs/tags; linked-versions group contains core/admin only. | It is the repository’s established release authority. [VERIFIED: codebase grep] |
| GitHub Actions | hosted workflow platform | Gates and publishes the release fan-out. | Existing workflows preserve anti-recursion recovery, static non-cancelling concurrency, protected environment, and idempotency guards. [VERIFIED: codebase grep] |
| Hex + HexDocs | current hosted registry/docs service | Delivers packages and published docs. | `mix hex.publish` ships configured package files and automatically publishes docs to HexDocs. [CITED: https://hex.pm/docs/publish] |
| ExUnit / Mix | Elixir 1.19.5 / OTP 28 locally | Focused behavioral and workflow-contract evidence. | Existing tests are the canonical proof assets. [VERIFIED: local environment and codebase grep] |

### Supporting

| System | Purpose | When to Use |
|--------|---------|-------------|
| `scripts/consumer_install_smoke.sh` | Generates a fresh Phoenix app, injects dependencies, runs installer/OPS-01/compile/boot/HTTP proof. | CI path mode and post-release Hex mode only; do not duplicate its body. [VERIFIED: codebase grep] |
| `post-publish-smoke.yml` | Polls registry/HexDocs and runs the published consumer/trust journey. | On a core release tag or manual recovery/rehearsal tag. [VERIFIED: codebase grep] |
| `test/scripts/linked_release_concurrency_test.exs` | Guards static shared concurrency and publish job idempotency. | Update alongside release workflow graph changes. [VERIFIED: codebase grep] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Editing the existing protected workflow | A separate core/admin publication workflow | Rejected: violates D-03, duplicates sensitive release controls, and risks drift. [VERIFIED: CONTEXT.md] |
| Existing shared consumer harness | A new standalone published-install script | Rejected: violates D-07 and duplicates installer behavior. [VERIFIED: CONTEXT.md] |
| Compatibility assertion against inbound 2.1.1 | Republishing inbound | Rejected: violates D-01/D-02; inbound has a published `~> 2.0` core dependency seam. [VERIFIED: CONTEXT.md and codebase grep] |

**Installation:** No external packages are required for this phase. [VERIFIED: codebase grep]

## Architecture Patterns

### System Architecture Diagram

```text
feature/release commit
        |
        v
Release Please ──> linked release PR: mailglass 2.4.0 + admin 2.4.0
        |                 (inbound manifest stays 2.1.1)
        v
GitHub release events for core/admin tags
        |
        v
publish-hex: prepublish + CI gate
        |
        +--> publish-core ──> wait for Hex index ──> publish-admin (MIX_PUBLISH=true)
        |                                                |
        |                                                v
        |                                        Hex + HexDocs
        |
        +--> no inbound publish job on release event
        |
        v
post-publish-smoke (core tag only)
        +--> wait core/admin Hex + HexDocs
        +--> assert inbound 2.1.1 compatibility, if included
        +--> consumer_install_smoke.sh DEP_MODE=hex
        +--> published reference-host trust journey
```

The smoke workflow already ignores non-core release tags, so the admin linked tag does not run a duplicate smoke. [VERIFIED: codebase grep]

### Recommended Project Structure

```text
.github/workflows/
├── publish-hex.yml                # release-event and manual package selection graph
├── post-publish-smoke.yml         # published core/admin verification + inbound compatibility
└── release-please.yml             # release PR/tag creation and core/admin doc-pin sync
test/
├── scripts/linked_release_concurrency_test.exs  # release workflow contract
├── mailglass/publish/             # post-publish workflow contracts
└── mailglass/                     # suppression/docs-contract evidence
mailglass_admin/test/mailglass_admin/operator_live_test.exs # LiveView proof
scripts/consumer_install_smoke.sh  # shared clean consumer harness
```

### Pattern 1: Event-aware fan-out with explicit manual packages

**What:** On `release`, enable only core and admin publication. On `workflow_dispatch`, retain explicit choices for core-only, admin-only, inbound-only, and all. `publish-admin` should list only prerequisite jobs it logically requires, so an inbound-only job neither blocks nor races the linked pair. [VERIFIED: codebase grep]

**When to use:** Every release-event condition and `needs` chain touched by this phase, including prepublish checks. Do not merely skip the final inbound `mix hex.publish`; a release-event inbound prepublish job or an admin dependency still makes inbound required. [VERIFIED: codebase grep]

**Example:**

```yaml
# Source: repository pattern + GitHub Actions needs documentation
publish-admin:
  needs: [gate-ci-green, publish-core]
  if: >
    always() &&
    ((github.event_name == 'release' && needs.publish-core.result == 'success') ||
     (github.event_name == 'workflow_dispatch' && ...))
```

GitHub documents that `needs` is a successful-completion dependency and `always()` is needed only when a job must inspect prerequisite results after a skip/failure. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax]

### Pattern 2: Keep version ownership in the manifest/config, not workflow inference

**What:** Let Release Please’s linked group calculate `mailglass` + `mailglass_admin`; preserve `mailglass_inbound` as an independent package/manifest entry. Do not infer inbound’s version from core during the release PR sync step. [VERIFIED: codebase grep]

**When to use:** Updating release PR synchronization and test expectations. The existing sync step already reads inbound’s own manifest value conditionally; it must leave the inbound files untouched when no inbound release is requested. [VERIFIED: codebase grep]

### Pattern 3: One behavior proof command, one published proof command

**What:** Make a focused `mix test` command the pre-release evidence artifact, then use the existing post-publish workflow as the release-window proof. The local path harness is a shift-left check; it cannot satisfy REL-01 by itself. [VERIFIED: CONTEXT.md and codebase grep]

**Recommended focused command:**

```bash
mix test \
  test/mailglass/webhook/ingest_auto_suppress_test.exs \
  test/mailglass/suppression_test.exs \
  test/mailglass/docs_contract_test.exs \
  --warnings-as-errors

cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors
```

Add a small named alias or workflow step only if it keeps these exact canonical files visible and avoids a second test implementation. [ASSUMED]

### Anti-Patterns to Avoid

- **Leaving `publish-admin.needs` coupled to `publish-inbound`:** an inbound skip/failure blocks the desired core/admin release because `needs` propagates skips/failures. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax]
- **Turning the inbound compatibility check into a silent skip:** REL-01 requires that unchanged inbound be proven compatible; require a positive 2.1.1/core-2.4.0 resolution assertion when inbound is part of the published consumer set. [VERIFIED: CONTEXT.md]
- **Publishing inbound to make its old package observable:** this violates the locked independent version boundary. [VERIFIED: CONTEXT.md]
- **Replacing Hex-mode smoke with path mode:** path mode proves current-tree integration, not artifacts adopters install. [VERIFIED: CONTEXT.md and codebase grep]
- **Changing static concurrency group:** linked tags fire close together; repository contract tests require the shared static non-cancelling group. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don’t Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Fresh Phoenix consumer validation | A second bespoke fixture/app | `scripts/consumer_install_smoke.sh` in `path` and `hex` modes | It already exercises dependency injection, installer, OPS-01, compilation, boot, and `/dev/mail/` HTTP response. [VERIFIED: codebase grep] |
| Registry/doc availability | Ad-hoc sleeps | Existing bounded Hex and HexDocs polling in `post-publish-smoke.yml` | Registry and docs publication are asynchronous enough to require bounded readiness checks. [VERIFIED: codebase grep] |
| Version pairing | Custom tag/version parser | Release Please linked-versions config | Core/admin pairing is already declared in one canonical config. [VERIFIED: codebase grep] |
| Workflow graph parsing assertions | Brittle full-YAML equality test | Existing targeted workflow-contract test style | Existing tests slice named job blocks and assert load-bearing dependency/command strings. [VERIFIED: codebase grep] |

**Key insight:** the release path is already mature; Phase 148 should alter the smallest possible conditional/dependency surface and extend its contract tests, not redesign publication. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Inbound is skipped but still blocks admin

**What goes wrong:** Removing only the inbound publish condition leaves `publish-admin.needs: publish-inbound`; a skipped prerequisite prevents the desired linked admin publish. [VERIFIED: codebase grep]

**How to avoid:** Remove inbound from the admin `needs` array and write assertions for the release-event condition, core success prerequisite, and retained inbound-only dispatch branch. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax]

### Pitfall 2: Prepublish work still declares inbound release dependency

**What goes wrong:** Release-event expressions use empty `github.event.inputs.package`, so current `!= mailglass`/`!= mailglass_admin` tests cause inbound prepublish work during a core/admin release. [VERIFIED: codebase grep]

**How to avoid:** Make each prepublish job/step predicate explicit about `github.event_name == 'release'` and the release pair versus a manually selected package. [VERIFIED: codebase grep]

### Pitfall 3: Compatibility proof recognizes any `~>` line, not the locked release pair

**What goes wrong:** The existing smoke’s text predicate accepts any recognized core compatibility syntax; it is useful as a general guard but does not alone prove `mailglass_inbound 2.1.1` resolved with `mailglass 2.4.0`. [VERIFIED: codebase grep]

**How to avoid:** Add a focused workflow-contract assertion or a dedicated Hex-mode resolver check pinned to `VERSION=2.4.0`, `VERSION_INBOUND=2.1.1`, and `INCLUDE_INBOUND=true`; the actual post-publication run remains the decisive proof. [ASSUMED]

### Pitfall 4: Version/doc pin sync mutates inbound on a core/admin-only PR

**What goes wrong:** `release-please.yml` currently includes inbound README/docs/publish-summary in its generic sync paths. A core/admin-only release must not create misleading inbound version/docs edits. [VERIFIED: codebase grep]

**How to avoid:** Restrict inbound-specific substitutions and `git add` paths to when Release Please actually created an inbound version change; leave core/admin README sync intact. [ASSUMED]

### Pitfall 5: Release evidence is not retained or reviewable

**What goes wrong:** Human-only terminal output makes it unclear which release proof ran against the release SHA. [ASSUMED]

**How to avoid:** Add a concise workflow summary/artifact containing commands, SHA/tag, resolved package versions, and test outcomes; do not store PII or package credentials. [ASSUMED]

## Code Examples

### Core/admin-only release eligibility

```yaml
# Source: repository `publish-hex.yml` conditional pattern
if: >
  always() &&
  (
    (github.event_name == 'release' && needs.publish-core.result == 'success') ||
    (github.event_name == 'workflow_dispatch' &&
      github.event.inputs.package == 'mailglass_admin' &&
      needs.gate-ci-green.result == 'success' &&
      needs.publish-core.result == 'skipped') ||
    (github.event_name == 'workflow_dispatch' &&
      github.event.inputs.package == 'all' &&
      needs.publish-core.result == 'success')
  )
```

This shape is illustrative; the planner must preserve all existing dry-run/idempotency/secret-exposure guards when applying it. [ASSUMED]

### Published package compatibility smoke

```bash
# Source: scripts/consumer_install_smoke.sh
DEP_MODE=hex \
VERSION=2.4.0 \
VERSION_INBOUND=2.1.1 \
INCLUDE_INBOUND=true \
WORK_DIR="${RUNNER_TEMP}" \
bash scripts/consumer_install_smoke.sh
```

The script’s Hex mode pins core and admin to `VERSION` and inbound to `VERSION_INBOUND` only when `INCLUDE_INBOUND=true`, then creates a new `phx.new` host, installs, compiles with warnings-as-errors, boots, and requires HTTP 200 from `/dev/mail/`. [VERIFIED: codebase grep]

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| Exact sibling core pin dragged inbound on each core release. | Inbound publishes with `~> 2.0` and is optional in admin; core/admin remain linked. | Core 2.4.0 can retain inbound 2.1.1 if resolution proof passes. [VERIFIED: codebase grep] |
| Separate path and published installer logic. | One parameterized consumer script with `DEP_MODE=path|hex`. | Shift-left and release proof exercise the same consumer journey. [VERIFIED: codebase grep] |
| Release-tag workflow runs assumed normal push CI. | CI gate self-dispatches CI/advisory workflows for bot-merged release SHAs. | Preserve this anti-recursion recovery behavior while editing fan-out. [VERIFIED: codebase grep] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A focused assertion can pin the inbound 2.1.1/core 2.4.0 compatibility contract before the actual Hex release. | Common Pitfalls | Could give premature confidence if it does not exercise the registry solver. |
| A2 | Inbound-specific Release Please sync paths should be conditional on an inbound version change. | Common Pitfalls | Could require a slightly different release-please action output or manifest-diff implementation. |
| A3 | A release-proof summary/artifact is the appropriate evidence format. | Common Pitfalls | The project may prefer a CI summary-only convention. |
| A4 | A named alias/workflow step is useful if it exposes, rather than obscures, the canonical proof files. | Architecture Patterns | Could add avoidable automation surface. |

## Open Questions

1. **Which existing release workflow contract tests cover the new core/admin-only fan-out?**
   - What we know: `linked_release_concurrency_test.exs` verifies all three publish job idempotency blocks but not their event conditions; `post_publish_smoke_contract_test.exs` validates published-smoke shape. [VERIFIED: codebase grep]
   - What's unclear: whether a new targeted test or an extension to that test best fits current conventions. [VERIFIED: codebase grep]
   - Recommendation: extend `linked_release_concurrency_test.exs` with job-block condition/`needs` assertions; add a separate test only if it remains shorter and more fail-loud. [ASSUMED]

2. **Does the release-pr sync currently see a reliable per-component release output?**
   - What we know: it receives `prs_created` and reads manifest entries, including inbound, unconditionally. [VERIFIED: codebase grep]
   - What's unclear: whether release-please action output identifies changed components directly in this pinned version. [VERIFIED: codebase grep]
   - Recommendation: use the release PR branch’s manifest diff or release PR changed files as the fallback deterministic condition; do not rely on guessed action outputs. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir / Mix | Focused proof tests and consumer harness | ✓ | Elixir 1.19.5 / OTP 28 | CI pins project toolchain. [VERIFIED: local environment] |
| PostgreSQL | Suppression/operator tests | ✓ | accepting on local port 5432 | CI service container. [VERIFIED: local environment] |
| Docker | CI-like service/reference-host work | ✓ | 29.5.2 | Local Postgres already available for focused core tests. [VERIFIED: local environment] |
| GitHub CLI | Release recovery/manual inspection | ✓ | 2.95.0 | GitHub Actions canonical path. [VERIFIED: local environment] |
| Hex credentials / protected environment | Actual release | Not locally evaluated | — | `hex-publish` GitHub environment only. [VERIFIED: codebase grep] |

**Missing dependencies with no fallback:** Actual `HEX_API_KEY`/protected environment access is intentionally unavailable locally; the release must run through the established GitHub workflow. [VERIFIED: codebase grep]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (repository Mix projects) [VERIFIED: codebase grep] |
| Config file | `test/test_helper.exs`, package-local test helpers [VERIFIED: codebase grep] |
| Quick run command | Focused core proof command plus package-local operator test command above [VERIFIED: codebase grep] |
| Full suite command | `mix ci` and package CI lanes; protected publish additionally gates `ci.yml` and advisory matrix. [VERIFIED: codebase grep] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROOF-02 | Webhook maps unsubscribe to stream scope; complaint/hard-bounce to address scope; pre-send blocks transactional delivery. | unit/integration | `mix test test/mailglass/webhook/ingest_auto_suppress_test.exs test/mailglass/suppression_test.exs --warnings-as-errors` | ✅ |
| PROOF-03 | B2C fences parse and guide is registered in docs extras/groups/package files. | unit/contract | `mix test test/mailglass/docs_contract_test.exs --warnings-as-errors` | ✅ |
| PROOF-01 release bundle | Tenant updates refresh without reload and foreign tenant events do not update UI. | LiveView integration | `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors` | ✅ |
| REL-01 pre-release | Release events publish only core/admin and admin no longer waits on inbound; inbound-only dispatch remains safe. | workflow contract | `mix test test/scripts/linked_release_concurrency_test.exs --warnings-as-errors` after extension | ❌ Wave 0 extension |
| REL-01 published | Clean fresh consumer resolves published 2.4.0 core/admin with 2.1.1 inbound and boots. | published E2E | `post-publish-smoke.yml` invokes `DEP_MODE=hex ... scripts/consumer_install_smoke.sh` | ✅ workflow; release-only evidence |

### Sampling Rate

- **Per task commit:** focused workflow contract plus the touched canonical test file(s). [ASSUMED]
- **Per wave merge:** focused proof bundle and `mix ci` when workflow code changes. [ASSUMED]
- **Phase gate:** green protected publish gate and successful `post-publish-smoke.yml` Hex-mode consumer run for core 2.4.0. [VERIFIED: CONTEXT.md and codebase grep]

### Wave 0 Gaps

- [ ] Extend `test/scripts/linked_release_concurrency_test.exs` (or add a narrow peer contract test) to assert release-event core/admin-only fan-out and inbound-only manual path.
- [ ] Add a deterministic compatibility assertion for unchanged `mailglass_inbound` 2.1.1 versus core 2.4.0, while retaining the live published resolver smoke as final proof.
- [ ] Define the release-proof summary/artifact location and ensure it contains no credentials or PII.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No application authentication change. [VERIFIED: phase scope] |
| V3 Session Management | no | No session behavior change. [VERIFIED: phase scope] |
| V4 Access Control | yes | Preserve protected ref and `hex-publish` environment; do not move `HEX_API_KEY` to PR/release artifacts. [VERIFIED: CLAUDE.md and codebase grep] |
| V5 Input Validation | yes | Keep tag-based manual dispatch and existing semver/guard checks; do not dispatch publication against `main`. [VERIFIED: codebase grep] |
| V6 Cryptography | no | No cryptographic implementation change. [VERIFIED: phase scope] |

### Known Threat Patterns for release automation

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Secret exposure from a wrongly enabled publish job | Information disclosure / elevation | Keep protected environment, existing `needs` success checks, and explicit event/package predicates. [VERIFIED: codebase grep] |
| Accidental inbound republish | Tampering | Release-event conditions must exclude inbound; retain inbound only as an explicit manual package choice. [VERIFIED: CONTEXT.md] |
| Duplicate linked-tag execution | Availability / integrity | Keep static `mailglass-linked-release-fanout` concurrency with `cancel-in-progress: false`. [VERIFIED: codebase grep] |
| Bot merge has no CI run on release SHA | Availability | Preserve gate self-dispatch/recovery workflow behavior. [VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)

- Repository workflows, manifests, package metadata, scripts, and focused tests — exact package graph, existing proof assets, and candidate seams. [VERIFIED: codebase grep]
- [`CONTEXT.md`](148-CONTEXT.md) — locked scope, package boundary, and proof decisions. [VERIFIED: codebase grep]
- [Hex publishing documentation](https://hex.pm/docs/publish) — tarball files and automatic HexDocs publication. [CITED: https://hex.pm/docs/publish]

### Secondary (MEDIUM confidence)

- [GitHub Actions workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax) — `needs`, skipped dependency propagation, `always()`, and conditional job behavior. [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax]

### Tertiary (LOW confidence)

- None beyond the explicitly logged implementation-shape assumptions. [VERIFIED: research analysis]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all systems and versions are repository-local and release paths are established. [VERIFIED: codebase grep]
- Architecture: HIGH — release fan-out dependency conflict is directly present in workflow YAML; `needs` semantics are confirmed by official docs. [VERIFIED: codebase grep] [CITED: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax]
- Pitfalls: HIGH — failure modes derive from current predicates/dependencies; only exact test/artifact shape is intentionally left discretionary. [VERIFIED: codebase grep]

**Research date:** 2026-08-01
**Valid until:** 2026-08-31
