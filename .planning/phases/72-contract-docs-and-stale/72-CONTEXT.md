# Phase 72: Contract Docs and Stale - Context

**Gathered:** 2026-06-02 (assumptions mode with subagent research)
**Status:** Ready for planning

<domain>
## Phase Boundary

Update public wording and executable docs/release checks for
`mailglass_inbound`'s own stable `1.0` contract.

This phase covers DOC-01, DOC-02, and PROOF-02. It is a docs-truth and
stale-claim guard phase: public docs must describe `mailglass_inbound` as an
independent stable `1.0` package line routed through
`mailglass_inbound/docs/api_stability.md`, while preserving the matched
`mailglass` / `mailglass_admin` `1.x` sibling line. It may fix package
source-ref/tag-shape metadata and publish-summary truth where stale release
claims depend on them. It must not publish the package, record Hex/HexDocs
evidence, update reference/demo published-Hex pins that cannot resolve before
publish, force a core/admin release, or add inbound feature-growth scope.
</domain>

<decisions>
## Implementation Decisions

### Contract Wording
- **D-01:** Public wording should say one thing everywhere:
  `mailglass_inbound` has its own independent stable `1.0` contract documented
  in `mailglass_inbound/docs/api_stability.md`.
- **D-02:** Preserve the matched `mailglass` / `mailglass_admin` `1.x` sibling
  line as a separate compatibility story. Do not imply that core, admin, and
  inbound are one matched three-package `1.x` release line.
- **D-03:** Replace stale wording that says inbound is excluded from the
  `1.x` compatibility promise, remains outside the `v1.x` stability promise,
  or is supported only through `mailglass_inbound` `0.x`. Correct replacements
  should distinguish "not part of the linked core/admin version group" from
  "not stable."
- **D-04:** Keep `mailglass_inbound/docs/api_stability.md` inventory-shaped:
  stable, testing, internal, and deferred sections remain the canonical
  contract source. README, jobs, maintainer, and compatibility docs may
  summarize and route readers there, but should not become competing contract
  inventories.

### Stale-Claim Guard Shape
- **D-05:** Extend existing proof seams rather than creating a new verifier.
  Use package-local inbound docs-contract assertions for inbound-specific
  semantic claims, root docs-contract/stability tests for aggregate release
  topology, and `mix mailglass.docs.check` for Tier 1 public-doc required and
  forbidden tokens.
- **D-06:** Prefer exact stale-phrase guards for known bad claims and dynamic
  parsing only where it materially improves durability, such as version pins,
  `release-please-config.json` linked-version membership, manifest versions,
  and package-specific source refs.
- **D-07:** Do not ban every mention of `1.x` around inbound. The correct
  posture is: inbound is not part of the matched core/admin `1.x` group, but
  it does have its own stable `1.0` contract and future inbound semantic breaks
  require a deprecation bridge or inbound major-version change.

### Release Topology And Source Refs
- **D-08:** Treat release topology truth as part of Phase 72's stale-claim
  surface: `release-please-config.json` has three packages, but the
  linked-versions group includes only core/admin; `.release-please-manifest.json`
  currently records core/admin `1.3.0` and inbound `1.0.0`.
- **D-09:** Planning should consider correcting inbound package docs/source
  metadata from generic sibling-group or `v1.0.0` refs to package-tag refs
  such as `mailglass_inbound-v1.0.0`, and should refresh the inbound publish
  summary if source/package metadata truth changes.
- **D-10:** Keep Phase 73 separate: live Hex index, HexDocs URLs, workflow run
  URLs, post-publish smoke/install proof, fallback usage, and the 60-minute
  revert/retire decision are publish-evidence work, not Phase 72 work.

### Public Surface Targets
- **D-11:** Treat these as primary Phase 72 public/trust surfaces:
  `guides/compatibility-and-deprecations.md`, `guides/jobs.md`, root
  `README.md`, `MAINTAINING.md`, `mailglass_inbound/README.md`,
  `mailglass_inbound/docs/api_stability.md`,
  `mailglass_inbound/docs/inbound-install.md`, relevant package tables/status
  sections, `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs`,
  `test/mailglass/docs_contract_test.exs`,
  `test/mailglass/stability_contract_test.exs`, and
  `lib/mix/tasks/mailglass.docs.check.ex`.
- **D-12:** Known stale surfaces include the compatibility guide support matrix
  and deprecation-DX horizons, `guides/jobs.md` and its current contract test,
  a `MAINTAINING.md` JTBD refresh note that still says inbound is outside the
  `v1.x` promise, and inbound package source-ref metadata.
- **D-13:** Reference/demo app published-Hex pins (`~> 0.3`) are visible stale
  examples but should remain Phase 73 unless the planner can frame them as
  pending-publish truth without requiring unresolvable lockfile churn.

### Ecosystem Lessons And DX
- **D-14:** Copy the useful pattern from Rails Action Mailbox and Laravel Mail:
  docs should make the adopter workflow obvious end-to-end. Do not copy the
  footgun of blurring framework semantics with provider implementation details.
- **D-15:** Copy Anymail's honesty about normalized provider support and
  limited/unsupported seams, but avoid matrix sprawl. Mailglass should keep
  provider stability at the `MailglassInbound.Ingress.Plug` option/semantic
  level and keep provider modules internal.
- **D-16:** Keep docs voice calm, exact, and maintainer-like: docs are part of
  the product, examples are contract surfaces, and small honest surfaces beat
  broad claims.

### the agent's Discretion
- Planner may choose exact assertion names and exact string tokens, provided
  the checks fail on stale inbound `0.x`/outside-`v1.x` claims in current
  public docs while allowing historical changelog or archived context.
- Planner may choose whether topology guards live in root docs-contract tests,
  root stability-contract tests, or both, provided they remain deterministic
  and run through existing support-contract/docs lanes.
- Planner should use existing repo-native commands and avoid creating another
  release truth engine.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope
- `.planning/ROADMAP.md` - Phase 72 goal, v1.6 success criteria, and
  requirement mapping.
- `.planning/REQUIREMENTS.md` - DOC-01, DOC-02, PROOF-02, v1.6 traceability,
  and out-of-scope table.
- `.planning/PROJECT.md` - v1.6 milestone intent, convergence posture, and
  release-governance guardrails.
- `.planning/STATE.md` - current Phase 72 position and v1.6 scope locks.
- `.planning/METHODOLOGY.md` - decisive-by-default, honest-surface,
  recommendation-first, and compatibility-contract lenses.
- `.planning/phases/71-inbound-release-truth-preflight/71-CONTEXT.md` - Phase
  71 release-truth decisions and stale-claim deferral to Phase 72.
- `.planning/phases/71-inbound-release-truth-preflight/71-VERIFICATION.md` -
  evidence that broad stale claims and reference/demo pins were deferred.

### Prior Locked Contract Decisions
- `.planning/milestones/v1.4-phases/63-inbound-contract-inventory-reconciliation/63-CONTEXT.md`
  - stable/testing/internal/deferred inbound inventory decisions.
- `.planning/milestones/v1.4-phases/64-contract-verification-hardening/64-CONTEXT.md`
  - compiled-doc, docs-contract, closed-set, and support-contract proof
  decisions.
- `.planning/milestones/v1.4-phases/65-compatibility-docs-and-dx-lock/65-CONTEXT.md`
  - adoption, compatibility, operator, testing, and admin trust decisions.
- `.planning/milestones/v1.4-phases/66-release-position-decision/66-CONTEXT.md`
  - `mailglass_inbound` `1.0.0` release-position decision.

### Public Docs And Drift Guards
- `README.md` - current root package-family wording and inbound stable `1.0`
  table.
- `guides/compatibility-and-deprecations.md` - main Phase 72 compatibility
  target; currently contains stale inbound exclusion and `0.x` horizons.
- `guides/jobs.md` - public JTBD guide; currently contains stale outside
  `v1.x` inbound boundary.
- `MAINTAINING.md` - maintainer release/JTBD/runbook wording, fallback path,
  and required-vs-advisory proof boundary.
- `mailglass_inbound/README.md` - canonical inbound adoption lane and install
  pin.
- `mailglass_inbound/docs/api_stability.md` - canonical inbound stable/testing/
  internal/deferred contract inventory.
- `mailglass_inbound/docs/inbound-install.md` - subordinate install guide and
  provider-support wording.
- `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` -
  package-local inbound docs-contract assertions.
- `test/mailglass/docs_contract_test.exs` - root docs/JTBD contract assertions.
- `test/mailglass/stability_contract_test.exs` - root release topology and
  publish-proof assertions.
- `lib/mix/tasks/mailglass.docs.check.ex` - Tier 1 docs drift checker.

### Release Topology And Package Truth
- `release-please-config.json` - package topology and linked-version grouping.
- `.release-please-manifest.json` - current package version truth.
- `.github/workflows/release-please.yml` - release tag derivation and sibling
  dependency pin sync behavior.
- `.github/workflows/publish-hex.yml` - package selector, fallback tag input,
  publish order, and inbound-only dispatch behavior.
- `mailglass_inbound/mix.exs` - inbound package metadata, source refs, docs
  refs, version, and `MIX_PUBLISH=true` core dependency pin.
- `.planning/publish/mailglass_inbound-publish-summary.json` - inbound
  publish-summary snapshot that may need source-ref refresh if metadata changes.
- `.planning/publish/mailglass_inbound-files.expected` - inbound package
  allowlist.

### Prompt And External Research Inputs
- `prompts/elixir-opensource-libs-best-practices-deep-research.md` - docs as
  product, examples as contracts, Hex package hygiene, versioned docs/source
  links.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md` - Release
  Please, Hex publish, docs warnings-as-errors, deterministic CI/release
  posture.
- `prompts/mailglass-engineering-dna-from-prior-libs.md` - prior-library
  convergence on docs-contract tests, Release Please, package whitelists, and
  release proof.
- `prompts/mailglass-brand-book.md` - Mailglass voice: clear, calm, exact,
  visible, no hype.
- Rails Action Mailbox / Action Mailer docs - workflow clarity and provider
  semantics lessons.
- Anymail docs and changelog - honest cross-provider support and stability
  matrix lessons.
- Laravel Mail docs - developer workflow clarity and escape-hatch framing.
- Postmark, SendGrid, and Resend docs - provider operational facts that should
  inform docs without becoming stable Mailglass provider-module contracts.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` already
  checks install pins, active/deferred over-claims, provider-module boundaries,
  operator semantics, testing-DX rules, and closed error type docs.
- `test/mailglass/docs_contract_test.exs` already pins `guides/jobs.md`
  freshness and currently guards stale outside-`v1.x` wording that Phase 72
  should replace.
- `test/mailglass/stability_contract_test.exs` already reads package manifests,
  publish summaries, workflows, `mailglass_inbound/mix.exs`, and README truth.
- `lib/mix/tasks/mailglass.docs.check.ex` already centralizes Tier 1 required
  and forbidden tokens, including several inbound docs.
- `mix mailglass.publish.check --package mailglass_inbound` already refreshes
  package/publish-summary evidence when package metadata changes.

### Established Patterns
- Stability is semantics-first and defined by canonical inventories, not by
  module reachability or generated docs visibility.
- Package-local tests own package-local contract truth; root tests verify
  aggregate docs/release topology.
- Mix tasks are appropriate for coarse deterministic docs checks; ExUnit tests
  are better for semantic routing, JSON parsing, and version/topology proof.
- Public examples and install snippets are treated as contract surfaces in this
  repo and in the prompt corpus.
- Required release proof is deterministic repo/package/workflow evidence;
  provider-live checks and ecosystem canaries remain advisory unless a release
  claim depends on them.

### Integration Points
- Planning should likely edit `guides/compatibility-and-deprecations.md`,
  `guides/jobs.md`, `MAINTAINING.md`, `mailglass_inbound/mix.exs`, docs-check
  rules, root docs/stability tests, and inbound docs-contract tests.
- Planning should inspect whether root `README.md`, `mailglass_inbound/README.md`,
  `mailglass_inbound/docs/api_stability.md`, and
  `mailglass_inbound/docs/inbound-install.md` need wording touch-ups or only
  guard coverage.
- If `mailglass_inbound/mix.exs` source refs change, regenerate
  `.planning/publish/mailglass_inbound-publish-summary.json` through the
  existing publish-check lane rather than hand-editing the snapshot.
</code_context>

<specifics>
## Specific Ideas

The user requested deeper one-shot synthesis using subagents, including:
pros/cons/tradeoffs, idiomatic Elixir/Phoenix/Plug/Ecto posture, lessons from
popular adjacent frameworks/libraries, prompt-directory guidance, high DX, and
a cohesive recommendation set that avoids handing decisions back.

Four research tracks were run:
- Elixir/Phoenix idioms for docs-contract and stale-claim guards.
- Adjacent ecosystem lessons from Rails, Anymail, Laravel, and provider docs.
- Release/runbook topology and exact stale-claim surfaces.
- `prompts/` directory synthesis.

The synthesized recommendation is deliberately cohesive:
keep the phase narrow, correct public truth, use existing executable proof
lanes, preserve inbound's independent stable `1.0` contract, preserve
core/admin's matched `1.x` sibling line, and leave live publish evidence to
Phase 73.
</specifics>

<deferred>
## Deferred Ideas

### Phase 73 Publish Evidence
- Reference/demo app published-Hex pins and lockfiles.
- Hex index URL, HexDocs URL, workflow run URL, smoke/install proof, fallback
  usage, and 60-minute revert/retire decision.

### Out Of v1.6 Scope
- Matcher expansion, lifecycle callbacks, public replay API, provider extension
  API, public worker/queue contract, synthetic inbound UI, `gen_smtp` listener,
  Cloudflare recipe docs, ecosystem integrations, demo app enhancements,
  screenshot workflow expansion, planning-directory cleanup, broad source
  hygiene, and forced core/admin release work.

### Reviewed Todos
None - no pending todos matched Phase 72.
</deferred>

---

*Phase: 72-contract-docs-and-stale*
*Context gathered: 2026-06-02*
