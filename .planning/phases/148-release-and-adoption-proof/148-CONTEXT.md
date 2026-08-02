# Phase 148: Release and Adoption Proof - Context

**Gathered:** 2026-07-31 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Run and capture the suppression, B2C documentation, and live operator proofs; release linked `mailglass` and `mailglass_admin` 2.4.0; and prove the clean published-package consumer path. Keep `mailglass_inbound` unchanged unless implementation reveals a real compatibility requirement. The external Sigra, Chimeway, Parapet, Accrue, host-recovery, and Crosswake launch gates remain outside this phase.

</domain>

<decisions>
## Implementation Decisions

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
- **D-10:** Release authorization is fully machine-gated: an active exact-version target, required CI, protected prepublish checks, and published-consumer proof replace human go/no-go and UAT.

### the agent's Discretion
- Exact workflow dependency and conditional structure used to remove inbound from the core/admin release fan-out, provided the existing release protections remain intact.
- Exact commands and artifact format used to collect the focused release-proof bundle.
- Whether a compatibility check is implemented as a focused test, workflow assertion, or both, provided unchanged inbound 2.1.1 is proven compatible with core 2.4.0.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and release contract
- `.planning/REQUIREMENTS.md` — Defines PROOF-02, PROOF-03, REL-01, and the explicit separation of external launch gates.
- `.planning/PROJECT.md` — Locks the v2.3 adopter profile, package ownership, linked core/admin 2.4.0 target, and unchanged-inbound posture.
- `.planning/STATE.md` — Records the active milestone state and inherited implementation constraints.
- `release-please-config.json` — Defines linked-version membership for core and admin.
- `.github/workflows/release-please.yml` — Generates release artifacts and synchronizes sibling dependency/documentation pins.
- `.github/workflows/publish-hex.yml` — Defines protected publication, release-event fan-out, and the inbound dependency that must be reconciled.

### Proof and adoption path
- `.github/workflows/post-publish-smoke.yml` — Canonical published-package verification path, including Hex and HexDocs availability.
- `.github/workflows/ci.yml` — Shift-left installer-host smoke and release-proof integration points.
- `scripts/consumer_install_smoke.sh` — Shared fresh-consumer smoke implementation for local-path and published-Hex modes.
- `test/mailglass/webhook/ingest_auto_suppress_test.exs` — Canonical webhook-to-suppression scope mapping proof.
- `test/mailglass/suppression_test.exs` — Canonical pre-send address-wide suppression proof for transactional delivery.
- `test/mailglass/docs_contract_test.exs` — B2C example parsing and HexDocs/package inclusion proof.
- `mailglass_admin/test/mailglass_admin/operator_live_test.exs` — Tenant-scoped live refresh and foreign-tenant rejection proof.
- `guides/b2c-first-adopter.md` — Public adopter guidance whose examples and package inclusion are under proof.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/consumer_install_smoke.sh`: Already supports local path dependencies and published Hex dependencies, so both proof stages can share one consumer harness.
- `.github/workflows/post-publish-smoke.yml`: Already waits for Hex and HexDocs, validates a Hex-only reference-host lock, and runs the published trust journey.
- `test/mailglass/docs_contract_test.exs`: Already parses B2C code blocks and asserts the guide's docs-surface inclusion.
- `mailglass_admin/test/mailglass_admin/operator_live_test.exs`: Already proves no-reload status refresh and ignores foreign-tenant events.

### Established Patterns
- Core and admin are the only linked-version members; inbound is an independent release line.
- Hex publication remains protected by the existing CI gate and `hex-publish` environment.
- Published validation reuses the shift-left consumer script instead of maintaining a second consumer harness.
- `mix.exs` explicitly includes `guides/b2c-first-adopter.md` in HexDocs extras and groups.

### Integration Points
- `.github/workflows/release-please.yml` creates the linked core/admin release artifacts and synchronizes package pins.
- `.github/workflows/publish-hex.yml` must align its release-event fan-out and job dependencies with the core/admin-only 2.4.0 boundary.
- `.github/workflows/post-publish-smoke.yml` must accept unchanged inbound and validate the versions actually available from Hex.
- `mailglass_admin/mix.exs` and `mailglass_inbound/mix.exs` accept core `~> 2.0`, providing the existing compatibility seam for core 2.4.0 and inbound 2.1.1.

</code_context>

<specifics>
## Specific Ideas

- One cohesive release-proof bundle should combine focused behavioral tests with the existing protected publish and published-consumer smoke lanes.
- Published proof must exercise the packages adopters actually install rather than substituting local path dependencies.

</specifics>

<deferred>
## Deferred Ideas

- Sigra/host magic-link validation and consumption journey — external production launch gate.
- Chimeway/host category-level one-click preferences — external production launch gate.
- Parapet complaint paging, Accrue payment journeys, and host email recovery — external production launch gates.
- Crosswake integration and any `crosswake_mailglass` package — explicitly outside the Mailglass package boundary.

</deferred>

---

*Phase: 148-release-and-adoption-proof*
*Context gathered: 2026-07-31*
