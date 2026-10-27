# Thread: Fractal Storybook and UI quality

Opened/refreshed: 2026-10-26. Status: v2.10 UI Repairs & Faithful Storybook active; requirements and roadmap approved; implementation not started.

## Formal milestone admission — 2026-10-26

The owner invoked `$gsd-new-milestone` using the upstream scope and rolling proposal, then approved the v2.10 envelope, reuse of existing research, all 31 [requirements](../REQUIREMENTS.md) and the five-phase [roadmap](../ROADMAP.md). Phase 174 establishes faithful Storybook plus quiet quick-view controls; 175 completes the early Delivery investigation/replay path; 176 repairs both filters and Inbound evidence; 177 addresses Health/Account navigation; 178 completes Preview controls and milestone review. Stories and connected proof accompany every repair, with final coverage reconciliation in 178.

Only the next envelope is admitted. Deeper whole-job breadth, new profiles, F7, custom dates and comprehensive Gallery consolidation remain future work. Safe navigation-only same-Account return from Preview is explicitly included (UXF-10); Account-scoped Preview data and auth/session expansion are excluded. All implementation requirements remain unchecked. The upstream research below records the pre-admission context and rationale.

## Durable owner intent

The owner calls this the next major UI-quality opportunity. Storybook should let them inspect the real interface at every useful scale: **components → small groups → areas within a section → whole sections → whole pages per job**. Situations cover realistic happy paths, errors and boundaries; impossible or redundant scenarios are aggressively pruned. This also encourages composable, data-driven Phoenix views rather than hardcoded markup and special cases.

Synthetic adopter profiles should feel believable: different B2B/B2C products and industries, hosted and self-hosted where supported, a new account and power users. Distinguish the adopting product, its Accounts and the engineers/support operators using Mailglass. Reuse the existing cohort and validate domain/read-model invariants. No real PII, secrets, marketing mail or invented product capabilities.

The design target is intentional, elegant and professionally composed: restrained colors, correct typography, clear hierarchy, no redundant explanations, consistent user-facing domain language, useful affordances, efficient jobs and natural navigation. Preserve current Mailglass identity. “iPhone-designed” means a high craft bar, not an iOS imitation. Mobile-first responsiveness, light/dark/System, keyboard/reduced-motion and realistic available container widths are standing criteria.

Research across relevant stakeholders, synthesize one recommendation, and stop at diminishing returns. Prefer small existing-tool extensions over new dependencies. Machines own observable correctness; bounded advisory review and the owner own judgment. Don't seek owner reapproval for automated acceptance already proved (D-52).

## Current authoritative proposal

- [Upstream scope and OpenGSD handoff](../research/ui-quality-engine/UPSTREAM-SCOPE.md) — current scope/sequencing authority, refined after the owner's live review.
- [One-page inventory](../research/ui-quality-engine/INVENTORY.md).
- [Decisions, rubric, conflicts and stopping rules](../research/ui-quality-engine/RECOMMENDATIONS.md).
- [Rolling milestone proposal](../research/ui-quality-engine/MILESTONE-PROPOSAL.md).
- [Architecture](../research/ui-quality-engine/ARCHITECTURE.md), [personas/design](../research/ui-quality-engine/PERSONAS-DESIGN.md), [automation/accessibility/CI](../research/ui-quality-engine/AUTOMATION.md).
- Seed: [SEED-009](../seeds/SEED-009-fractal-storybook.md).

The prior [2026-10-25 recommendations](../research/storybook-fractal/RECOMMENDATIONS.md) remain historical and are refined by the current synthesis. The cross-repo methodology source is `/Users/jon/Documents/ui-storybook-stresstest-methodology-prompt.txt`; this record captures its project-specific intent so resumption does not depend on that external file.

## Sequence and boundaries

1. Resolve the named owner feedback across Health, Deliveries, Inbound and Preview, pairing each useful repair with faithful stories and real-route proof. Complete one Delivery job early; don't defer known cross-surface repairs behind catalogue work.
2. Expand whole-job scenario depth and representative projection parity using the proven seams; add adopter profiles only for distinct risks.
3. Conditionally consolidate remaining inventory/review upkeep. This may be ordinary maintenance rather than another milestone.

The upstream sequence is a rolling proposal, not three implementation commitments. The formal admission above activates only the first envelope. OpenGSD owns phase/plan decomposition, design validation, execution and verification. Re-evaluate after each horizon; stop when the next addition has no distinct supported job/state or regression value. The upstream work made no product/dependency or formal planning changes; the subsequent milestone initialization created the approved requirements and roadmap. Eventual published Gallery-route removal requires a concrete compatibility disposition; keep it during migration now.

The [2026-10-26 owner review register](../todos/2026-10-26-owner-review-health-preview-controls.md) captures the latest screenshots and reaffirms previously deferred filters, raw-source hierarchy and useful Inbound addresses. The three scoping reviews distinguish settled directions from finite downstream hypotheses. Ordinary To is already full; the remaining concrete ordinary address defect is masked detail From. Suppression Refresh/Retry remains necessary pending proven equivalent invalidation. Preview is not account-scoped and current static links do not preserve dynamic Account return. Start from the existing three cohorts; six profiles are not prerequisite.

## Current live inspection

- Started isolated Compose project `mailglass-storybook-review`; HTTP 4015, Postgres 5415.
- Open in Chrome: `http://localhost:4015/dev/storybook/primitives/stat_card`.
- Existing Storybook: 5 primitives, 35 variations, no situation descriptions or composed area/screen stories; Gallery has 119 specimens / 32 families.
- `/dev/storybook` and sidebar navigation drop `/dev`; direct deep links work. Pinned router warns against non-root enclosing scopes.
- Stat cards render serif because Storybook's sandbox explicitly overrides inherited typography. Admin really ships the six Inter/Inter Tight/IBM Plex Mono WOFF2 faces. Plan a fidelity fix, not a brand change or fallback acceptance.
- Native data-attribute theming exists in pinned 1.2.0. Current backend has no shared production hook adapter. Static stories cannot prove connected action/focus semantics.

Stop only this review stack with `COMPOSE_PROJECT_NAME=mailglass-storybook-review docker compose -f compose.demo.yml down`; keep it available while the owner reviews. Owner WIP `.planning/config.json`, `prompt.txt`, and the archived `.gitkeep` remain untouched and must never be staged incidentally.

## Next action

Run `$gsd-plan-phase 174` to plan Faithful Storybook and Quiet Quick Views; `$gsd-discuss-phase 174` is available for additional context gathering. Read the approved requirements/roadmap plus `UPSTREAM-SCOPE.md`; reuse the settled research and investigate only actual implementation uncertainties. Milestone initialization is complete; no product implementation has begun.
