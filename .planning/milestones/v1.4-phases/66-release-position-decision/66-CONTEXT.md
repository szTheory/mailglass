# Phase 66: Release Position Decision - Context

**Gathered:** 2026-06-01 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Decide and document whether `mailglass_inbound` is ready for `1.0.0` or needs
one final explicit `0.x` confidence release.

This phase covers REL-01, REL-02, and REL-03. It is an evidence-backed release
position and release-notes phase only. It must not add matcher expansion,
lifecycle callbacks, public replay API, provider extension API, worker/queue
contract, synthetic inbound dev UI, ecosystem integrations, `gen_smtp` listener
work, or any other broad feature-growth scope.
</domain>

<decisions>
## Implementation Decisions

### Release Position
- **D-01:** Plan Phase 66 around promoting `mailglass_inbound` to `1.0.0`, not
  a final `0.x`, if the phase re-runs the release-blocking verification lanes
  and finds no blocker. The v1.4 lock evidence is already strong enough that
  the default decision should be promotion, with the final check serving as the
  proof gate rather than another product-design round.
- **D-02:** Keep the fallback explicit: if Phase 66 verification finds a real
  stability or release blocker, cut one final `0.x` confidence release with
  clear "next is 1.0" framing instead of weakening the `1.0.0` compatibility
  promise.

### Evidence Gate
- **D-03:** Treat Phase 66 as evidence collation, verification, and release
  posture documentation. It should not expand the stable surface or change the
  Phase 63 stable/testing/internal/deferred inventory except to fix discovered
  release-blocking drift.
- **D-04:** The release decision should cite committed evidence from the v1.4
  lock: Phase 63 inventory reconciliation, Phase 64 executable stability
  contract proof, Phase 65 compatibility/docs/DX verification, current Hex
  release truth, and the current release-blocking verification commands.
- **D-05:** Phase 66 planning should include a fresh verification pass for at
  least `mix verify.stability_contract` and `mix mailglass.publish.check
  --package mailglass_inbound`, then record the results in the phase artifacts
  and release notes.

### Release Notes Shape
- **D-06:** Write release notes in a sober operational style: adopter action
  required, verification commands, behavior changes, operator-impacting
  changes, compatibility posture, and explicit stable/internal/deferred
  boundaries.
- **D-07:** Route compatibility truth to
  `mailglass_inbound/docs/api_stability.md` and the compatibility guide instead
  of restating a second contract in the changelog. Release notes may summarize
  the posture, but the canonical contract remains the inventory and executable
  support-contract lane.
- **D-08:** Avoid hype or ambiguity. The release note should say plainly that
  `mailglass_inbound` is being promoted to the `1.0.0` compatibility line only
  because the stable contract is explicit, narrow, documented, and verified.

### Release Automation And Version Truth
- **D-09:** Treat release ceremony mechanics as follow-on implementation detail:
  update inbound version truth, dependency pins, README install pins,
  changelog/release notes, release-please manifest/config expectations, and
  publish-summary evidence consistently during execution.
- **D-10:** Start from current package truth: `mailglass_inbound` is currently
  `0.3.0` in `mailglass_inbound/mix.exs`, `.release-please-manifest.json`, and
  Hex.pm. Phase 66 should not assume a hidden unpublished inbound version.
- **D-11:** Keep release automation aligned with existing repo patterns:
  release-please owns version bump PRs, package publish checks own tarball and
  metadata truth, and the manual `workflow_dispatch` publish fallback remains
  the documented recovery path if GitHub release fanout is blocked.

### the agent's Discretion
- Planner may decide whether to express the release decision as a dedicated
  `66-RELEASE-POSITION.md`, a changelog section, or both, as long as REL-01 and
  REL-02 are directly satisfied and downstream release ceremony work has one
  unambiguous source of truth.
- Planner may decide the exact release-blocking verification command set beyond
  the required stability contract and inbound publish check, but should prefer
  existing repo-native lanes over inventing new release gates.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope
- `.planning/ROADMAP.md` - Phase 66 goal, requirements, success criteria, and
  v1.4 non-goals.
- `.planning/REQUIREMENTS.md` - REL-01, REL-02, REL-03 and the v1.4 out-of-scope
  table.
- `.planning/PROJECT.md` - v1.4 release-position intent, convergence posture,
  current package versions, and stability-lock scope guardrails.
- `.planning/STATE.md` - current position, v1.4 preflight locks, and prior
  release/trust decisions.
- `.planning/METHODOLOGY.md` - decisive-by-default, honest-surface,
  recommendation-first, and compatibility-contract lenses.

### v1.4 Lock Evidence
- `.planning/phases/63-inbound-contract-inventory-reconciliation/63-CONTEXT.md`
  - stable/testing/internal/deferred inventory decisions.
- `.planning/phases/64-contract-verification-hardening/64-CONTEXT.md` -
  executable compiled-doc, docs-contract, closed-set, and root verification
  decisions.
- `.planning/phases/65-compatibility-docs-and-dx-lock/65-CONTEXT.md` -
  compatibility, docs, operator, testing, and admin trust decisions.
- `.planning/phases/65-compatibility-docs-and-dx-lock/65-VERIFICATION.md` -
  passed Phase 65 verification evidence.

### Contract And Release Files
- `mailglass_inbound/docs/api_stability.md` - canonical inbound stable/testing/
  internal/deferred contract inventory.
- `guides/compatibility-and-deprecations.md` - compatibility and deprecation
  posture, including inbound stable/internal/deferred guidance.
- `mailglass_inbound/README.md` - canonical inbound adoption lane and install
  pin.
- `mailglass_inbound/CHANGELOG.md` - target package changelog/release notes.
- `mailglass_inbound/mix.exs` - inbound package version, dependency pins,
  support-contract aliases, and publish metadata.
- `.release-please-manifest.json` - current release-please version truth.
- `release-please-config.json` - release-please package topology.
- `.github/workflows/release-please.yml` - release PR sync behavior for sibling
  dependency pins and README pins.
- `.github/workflows/publish-hex.yml` - publish gate, tag-based fallback, and
  package-specific publish behavior.
- `mix.exs` - root `verify.stability_contract` aggregate lane.
- `lib/mix/tasks/mailglass.publish.check.ex` - publish-summary and tarball
  checks used as release-blocking proof.
- `.planning/publish/mailglass_inbound-publish-summary.json` - last committed
  inbound publish-summary snapshot.

### Live/Local Evidence Gathered During Discussion
- `mix hex.info mailglass_inbound 0.3.0` - confirmed `mailglass_inbound 0.3.0`
  was released on 2026-05-29 with dependency `mailglass == 1.3.0`.
- `mix verify.stability_contract` - passed during discussion with core/admin/
  inbound support-contract lanes and docs check green.
- `mix mailglass.publish.check --package mailglass_inbound` - completed during
  discussion with `conflict=0`.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `mailglass_inbound/docs/api_stability.md` already contains the narrow stable,
  testing, internal, and deferred inbound inventory that should anchor the
  `1.0.0` posture.
- `mailglass_inbound/test/mailglass_inbound/stability_contract_test.exs` already
  proves compiled-doc `since` metadata for stable runtime, error, operator, and
  testing helper entrypoints.
- `mailglass_inbound/test/mailglass_inbound/docs_contract_test.exs` already
  fails closed on contract over-claims, stale release-line wording, adoption
  drift, compatibility drift, operator trust drift, testing-DX drift, and admin
  trust-boundary drift.
- Root `mix verify.stability_contract` already delegates to
  `mailglass_inbound` package-local support-contract verification.
- `mix mailglass.publish.check --package mailglass_inbound` already produces
  tarball, allowlist, denylist, metadata, dependency, and advisory evidence for
  the inbound package.

### Established Patterns
- Stability is semantics-first and defined by canonical contract inventories,
  not module reachability or ExDoc visibility.
- Release notes should summarize compatibility posture while routing guarantee
  truth to canonical docs and executable verification lanes.
- Package-local checks own package-local contract proof; root lanes aggregate
  sibling package proof.
- Internal and deferred surfaces must remain named and bounded so `1.0.0` does
  not accidentally promise provider-module APIs, replay APIs, worker/queue
  contracts, or admin UI implementation details.

### Integration Points
- Planning should likely produce a release-position artifact plus changelog/
  release-note updates.
- Execution should update `mailglass_inbound` version and pins only through the
  repo's existing release/versioning conventions.
- Verification should run the existing stability contract and inbound publish
  checks, then preserve their evidence in phase artifacts.
- Project state should continue blocking broad feature-growth work until the
  release-position decision is complete.
</code_context>

<specifics>
## Specific Ideas

The user confirmed the assumption set as presented. No corrections were made.

The confirmed recommendation is to default to `mailglass_inbound` `1.0.0`
promotion if the Phase 66 verification pass stays green. The fallback is a final
explicit `0.x` confidence release only if verification finds a real blocker.
</specifics>

<deferred>
## Deferred Ideas

None - analysis stayed within Phase 66 scope.

The following remain explicitly out of scope for v1.4 feature work unless a
future milestone separately promotes them: matcher expansion beyond recipient,
subject, and headers; mailbox lifecycle callbacks beyond `process/1`; public
replay API; public provider extension API; public worker/queue contract;
synthetic inbound development UI; `gen_smtp` listener work; ecosystem
integrations; and admin DOM/component guarantees.
</deferred>

---

*Phase: 66-release-position-decision*
*Context gathered: 2026-06-01*
