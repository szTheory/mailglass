# Phase 71: Inbound Release Truth Preflight - Context

**Gathered:** 2026-06-02 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Reconcile `mailglass_inbound` source/package truth and required-vs-advisory
proof boundaries before the inbound `1.0.0` release ceremony.

This phase covers REL-01 and PROOF-01. It is a release-truth preflight phase:
source version, release-please manifest truth, changelog truth, README/install
pins, `MIX_PUBLISH=true` dependency pin, package allowlist, publish-summary
truth, and deterministic proof boundaries. It must not perform the publish
ceremony, force a `mailglass` or `mailglass_admin` release, broaden public docs
wording beyond required truth fixes, or add inbound feature-growth scope.
</domain>

<decisions>
## Implementation Decisions

### Source And Package Truth
- **D-01:** Phase 71 should reconcile existing inbound `1.0.0` source/package
  truth, not decide the release position again. The release-position decision
  was made in Phase 66; Phase 71 is the preflight that proves source,
  manifest, changelog, publish pin, package allowlist, and publish-summary
  truth agree.
- **D-02:** Start from current source truth: `.release-please-manifest.json`
  has `mailglass_inbound` at `1.0.0`, `mailglass_inbound/mix.exs` has
  `@version "1.0.0"`, `mailglass_inbound/CHANGELOG.md` has a `1.0.0` section,
  and `.planning/publish/mailglass_inbound-publish-summary.json` records
  inbound `1.0.0`.

### Preflight Check Shape
- **D-03:** Use the existing `mix mailglass.publish.check --package
  mailglass_inbound` lane as the core Phase 71 preflight. Add or adjust
  contract checks only for stale source/package truth that this lane does not
  already pin.
- **D-04:** Do not duplicate publish-check logic in a new verifier. The
  existing task already owns tarball build, file allowlist, denylist, size,
  required files, changelog section, metadata, dependency shape, prod deps,
  isolated compile, `hex.audit`, `hex.outdated` advisory capture, and
  publish-summary writing.

### Required Versus Advisory Boundary
- **D-05:** Required proof remains deterministic repo/package evidence:
  source/package truth, release-check output, CI/tag truth, publish workflow
  mechanics, Hex/HexDocs evidence when Phase 73 runs, and smoke/install proof
  when the release is actually published.
- **D-06:** Provider-live checks and ecosystem canaries stay advisory unless a
  specific release claim explicitly depends on them. Phase 71 should clarify
  this boundary rather than making external provider state release-blocking.

### Stale Claim Handling
- **D-07:** Phase 71 should identify stale claims and package-version
  contradictions, but leave broad public wording rewrites and executable
  stale-claim guards to Phase 72 unless they directly affect REL-01 or PROOF-01
  preflight truth.
- **D-08:** Known drift to account for includes root README inbound wording,
  reference/demo dependency pins, reference/host dependency pins, and
  maintainer runbook examples that still mention `0.3`, `v0.5+`, or
  core-tag-only fallback wording. Planning should classify which items are
  Phase 71 blockers versus Phase 72 docs/guard work.

### Release Topology
- **D-09:** Keep inbound release topology independent from the linked
  core/admin version group: core/admin stay at `1.3.0`, inbound is `1.0.0`,
  and `MIX_PUBLISH=true` inbound pins `mailglass == 1.3.0`.
- **D-10:** Do not force a `mailglass` or `mailglass_admin` release for this
  phase. `release-please-config.json` links only `mailglass` and
  `mailglass_admin`; inbound is its own package release line.

### the agent's Discretion
- Planner may decide whether to express Phase 71 output as focused test
  changes, docs/runbook truth fixes, publish-summary refresh, or a release
  preflight artifact, as long as REL-01 and PROOF-01 are directly satisfied.
- Planner should prefer existing repo-native lanes and checks over inventing
  new release ceremony mechanics.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope
- `.planning/ROADMAP.md` - Phase 71 goal, v1.6 success criteria, and
  requirement mapping.
- `.planning/REQUIREMENTS.md` - REL-01, PROOF-01, v1.6 out-of-scope table, and
  traceability.
- `.planning/PROJECT.md` - v1.6 milestone intent, convergence posture, and
  release-governance scope guardrails.
- `.planning/STATE.md` - current position, v1.6 scope locks, and prior
  release/trust decisions.
- `.planning/METHODOLOGY.md` - decisive-by-default, honest-surface,
  recommendation-first, and compatibility-contract lenses.

### Prior Locked Decisions
- `.planning/milestones/v1.4-phases/63-inbound-contract-inventory-reconciliation/63-CONTEXT.md`
  - stable/testing/internal/deferred inbound inventory decisions.
- `.planning/milestones/v1.4-phases/64-contract-verification-hardening/64-CONTEXT.md`
  - executable contract and docs-drift proof decisions.
- `.planning/milestones/v1.4-phases/65-compatibility-docs-and-dx-lock/65-CONTEXT.md`
  - canonical adoption, compatibility, operator, testing, and admin trust
  decisions.
- `.planning/milestones/v1.4-phases/66-release-position-decision/66-CONTEXT.md`
  - `mailglass_inbound` `1.0.0` release-position decision and evidence gate.

### Release Truth Files
- `.release-please-manifest.json` - current release-please version truth.
- `release-please-config.json` - package topology and linked-version grouping.
- `.github/workflows/release-please.yml` - release PR sync behavior for sibling
  dependency pins and README install pins.
- `.github/workflows/publish-hex.yml` - release/fallback publish path,
  package selector behavior, CI gate, and publish ordering.
- `mailglass_inbound/mix.exs` - inbound package version, `MIX_PUBLISH=true`
  core dependency pin, package allowlist, docs extras, and support-contract
  aliases.
- `mailglass_inbound/CHANGELOG.md` - inbound `1.0.0` release-note truth.
- `mailglass_inbound/README.md` - canonical inbound adoption lane and install
  pin.
- `.planning/publish/mailglass_inbound-files.expected` - committed inbound
  package allowlist.
- `.planning/publish/mailglass_inbound-publish-summary.json` - committed
  inbound publish-summary snapshot.

### Proof And Runbook Files
- `lib/mix/tasks/mailglass.publish.check.ex` - package pre-publish check and
  publish-summary writer.
- `test/mailglass/stability_contract_test.exs` - root support-contract wiring
  and release automation/package-truth assertions.
- `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` -
  package-local inbound stale wording and over-claim guards.
- `mailglass_inbound/test/mailglass_inbound/stability_contract_test.exs` -
  package-local compiled-doc stability proof.
- `MAINTAINING.md` - maintainer release runbook, required-vs-advisory proof
  boundary, fallback path, and release-record expectations.
- `guides/compatibility-and-deprecations.md` - compatibility posture and
  inbound contract routing.
- `mailglass_inbound/docs/api_stability.md` - canonical inbound stable/testing/
  internal/deferred contract inventory.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mix mailglass.publish.check --package mailglass_inbound` already performs
  the package preflight most directly aligned with REL-01: tarball build,
  committed allowlist comparison, required-file checks, changelog section
  checks, metadata checks, dependency-shape checks, prod dependency resolution,
  isolated compile, advisory audit/outdated capture, and publish-summary
  writing.
- `.planning/publish/mailglass_inbound-publish-summary.json` already records
  the current inbound `1.0.0` version, `manifest_version`, source ref, docs
  extras, package files, linked versions, and `mailglass_inbound_publish_pin`.
- `mailglass_inbound/mix.exs` already has inbound `@version "1.0.0"` and
  `MIX_PUBLISH=true` dependency pin `{:mailglass, "== 1.3.0"}`.
- `release-please-config.json` already separates inbound from the linked
  core/admin group.
- `MAINTAINING.md` already has required-vs-advisory release-trust language
  that planners can refine instead of inventing a new posture.

### Established Patterns
- Release proof uses repo-native deterministic gates first; external provider
  live checks remain advisory unless a release claim depends on them.
- Package-local checks own package-local contract truth; root tests verify
  aggregate wiring and release automation topology.
- Release notes summarize compatibility posture while canonical contract truth
  stays in `mailglass_inbound/docs/api_stability.md` and executable
  support-contract lanes.
- Stale docs claims should be corrected honestly, but Phase 72 owns the broader
  contract wording and stale-claim guard pass.

### Integration Points
- Planning should inspect `lib/mix/tasks/mailglass.publish.check.ex`,
  `.planning/publish/mailglass_inbound-publish-summary.json`,
  `.planning/publish/mailglass_inbound-files.expected`,
  `mailglass_inbound/mix.exs`, `mailglass_inbound/CHANGELOG.md`,
  `mailglass_inbound/README.md`, root `README.md`, `MAINTAINING.md`,
  reference app dependency pins, and release workflow package selectors.
- Verification should include existing deterministic release lanes, especially
  `mix mailglass.publish.check --package mailglass_inbound`; broader stability
  or docs-contract lanes may be included if the planned edits touch those
  surfaces.
</code_context>

<specifics>
## Specific Ideas

The user confirmed the assumption set as presented. No corrections were made.

The confirmed recommendation is to keep Phase 71 narrow: prove and reconcile
truth, classify required versus advisory checks, and defer broad public wording
guard expansion to Phase 72 unless a stale claim blocks REL-01 or PROOF-01.
</specifics>

<deferred>
## Deferred Ideas

None - analysis stayed within Phase 71 scope.

The following remain explicitly out of scope for v1.6 unless a future milestone
separately promotes them: matcher expansion, lifecycle callbacks, public replay
API, provider extension API, synthetic inbound UI, `gen_smtp` listener,
Cloudflare recipe docs, ecosystem integrations, demo app enhancements,
screenshot workflow expansion, planning-directory cleanup, broad source
hygiene, and any forced core/admin release line.
</deferred>

---

*Phase: 71-inbound-release-truth-preflight*
*Context gathered: 2026-06-02*
