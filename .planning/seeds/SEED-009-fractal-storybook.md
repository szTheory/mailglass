---
id: SEED-009
status: planted
planted: 2026-10-25
planted_during: v2.9 close-out (PR #302)
trigger_when: next UI-focused milestone; owner-selected UI direction reaffirmed 2026-10-26
scope: large
last_refreshed: 2026-10-26
proposal: .planning/research/ui-quality-engine/MILESTONE-PROPOSAL.md
---

# SEED-009: Fractal Storybook and realistic UI quality

## Owner intent

The owner calls this the next major UI opportunity: **components → small groups → areas within a section → whole sections → whole pages per job**. Review the actual production components under realistic synthetic adopter scenarios; retain happy, error and boundary states that really occur and aggressively prune obsolete/impossible/redundant cases. Use mobile-first/container-aware design, light/dark/System, intentional typography/hierarchy, useful user-facing language, coherent jobs/navigation and least-surprise affordances. Preserve current brand and supported domain/trust contracts.

Believable profiles span B2B/B2C and self-hosted where supported, with new/empty and power-user situations. Distinguish adopter product, customer Account and actual UI actor. Start with the existing three cohorts; add a profile only for a distinct supported risk. No six-profile quota, literal digital-twin claim, real PII or dependency is implied.

## Current scope authority

- [Upstream scope and OpenGSD handoff](../research/ui-quality-engine/UPSTREAM-SCOPE.md).
- [Short rolling proposal](../research/ui-quality-engine/MILESTONE-PROPOSAL.md).
- [Inventory](../research/ui-quality-engine/INVENTORY.md): 5 component stories, 35 variations, no composed area/screen stories; Gallery 119 specimens / 32 families.
- [Latest owner feedback](../todos/2026-10-26-owner-review-health-preview-controls.md) and [original feedback](../todos/2026-10-25-owner-review-pr302-ui-feedback.md).
- [Durable thread](../threads/ui-quality-engine.md).

Existing baseline recommendations and three focused scoping reviews are supporting rationale. The current scope supersedes the old infrastructure-first/Delivery-then-known-Inbound-repairs interpretation. Archived Phase 173 inventory allocation decisions remain history; the current direction changes future allocation without removing a published route automatically.

## Rolling direction

1. **Next candidate:** resolve named UX feedback across Health, Deliveries, Inbound and Preview, pairing repairs with faithful stories and real-route proof. Fix Storybook navigation/font/theme/hook fidelity early. Expand support only as the selected repairs need it.
2. **Following candidate:** extend whole-job scenario depth and representative projection parity through proven production presentation seams. New profiles need distinct value.
3. **Conditional later:** consolidate Gallery cases/assertions and keep review/pruning inexpensive. This may be maintenance, not another milestone. Keep the documented Gallery route until compatibility disposition.

Known repairs must not wait for the complete catalogue, generic fixture engine or judge. The scope packet supplies user outcomes, exclusions, evidence direction, tradeoffs and bounded unknowns. **OpenGSD owns milestone admission, formal requirements, phases/plans, detailed design, execution and verification.** No active milestone, official ROADMAP/REQUIREMENTS or product/dependency edits were made by this research.

## Concrete guardrails

- Storybook's current root/sidebar drops /dev; sandbox overrides Inter with serif. Correct fidelity before using captures as production design evidence. Native data-attribute theming exists in pinned 1.2.0.
- Reuse production components, CSS and hook logic; isolated stories do not prove auth/replay/URL behavior.
- Existing form change handlers validate only; auto-apply needs real URL-backed commits, not just deleting Apply.
- Show complete ordinary authorized Inbound From/To; current masked detail From is the concrete defect. Sensitive trace/raw policies remain separate.
- Suppression Refresh/Retry performs a real read; retain it pending proven equivalent invalidation. Preview is account-independent; static host links don't establish dynamic Account return.
- Pure scenarios must admit legitimate partial/out-of-order evidence. The Ecto demo still needs Postgres; faster runtime is unmeasured.
- Fresh axe comparisons, coverage counts and honest required/advisory status precede new ratchet claims. Provisional added CI budget is ≤5 wall minutes /≤10 runner-minutes including setup, pending measurement.
- No rebrand, provider growth, custom date ranges, account-aware Preview, interactive unsubscribe submission, generic framework or new dependency is prerequisite. F7 is a separate following-envelope integration candidate.
