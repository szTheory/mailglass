# Phase 169: Outbound Investigation and Recovery - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents. Decisions are in `169-CONTEXT.md`; supporting comparisons and primary sources are in `169-DECISION-BRIEF.md`.

**Date:** 2026-10-07
**Mode:** assumptions, followed by owner-requested specialist research and delegated adoption
**Areas:** journey/UX, evidence semantics, Phoenix/Ecto/navigation, recovery/trust, accessibility/visual/motion, privacy/reliability/DX

## Initial assumptions presented

| Assumption | Confidence then | Evidence |
| --- | --- | --- |
| Health should state Account/window and link matching evidence; unknown is not healthy | Likely | OperatorLive and core SupportSummary |
| Exact delivery detail should resolve independently of current list page/filters and preserve return context | Likely | OperatorLive page-only selection and support delivery links |
| Delivery history, current suppression, and Account support facts need separate scope and truthful next steps | Confident | Timeline, Suppressions, SupportCards, SuppressionCard |
| Outbound replay confirms one stored provider webhook with distinct requested/new/no-change/failure outcomes | Confident | ReplayTargets, Webhook.Replay, ReplayModal, inherited Phase 168 trust decisions |

The first response requested confirmation before writing context, following discuss-phase's interactive contract. No Phase 169 artifact was written before the owner responded.

## Owner steering and authorization

The owner supplied their research boilerplate and asked to “fan out enumerate breadth + depth of decision points … to the point of useful diminishing returns,” synthesize recommendations coherently with the project, and “auto follow those.” They emphasized idiomatic Elixir/Plug/Ecto/Phoenix, proven product lessons, DX, operator jobs, accessible coherent UI, current brand authority, and applicable `prompts/` research.

This explicitly delegated recommendation adoption. No further default-confirmation round was needed. It did not invoke phase planning/execution, merge/publication, or a global auto-advance preference change.

## Research performed

- Initial typed GSD assumptions analyzer reviewed current source and prior decisions; returned four areas and no essential external research gap for the initial narrow discussion.
- Owner then broadened research. Three parallel specialists each examined twelve comparisons: UI/IA/accessibility/copy/motion; Phoenix/Ecto/exact navigation/DX; evidence/recovery/trust/reliability.
- Specialists read relevant `prompts/` material, current product and scope, current brandbook, and implementation. They consulted 13 primary documentation references, distinguishing documented facts from recommendations.
- Parent applied Impeccable context/Operate/Shape guidance and the existing code-first decision. No visual-world reset or new design artifact was inferred from the loader's missing DESIGN.md result. Existing source and Phase 168 evidence establish the incumbent UI.
- Local scratch reports: `/private/tmp/mailglass-169-ui-research.md`, `/private/tmp/mailglass-169-phoenix-research.md`, `/private/tmp/mailglass-169-recovery-research.md`. Their durable synthesis is the decision brief; downstream work does not depend on these temporary paths.

## Corrections and refinements to the initial assumptions

- Keep the actual requested Health window/default 168h and fix hard-coded 24h labels; count units and destinations need explicit agreement.
- Repair empty-list render precedence as well as exact lookup; clear exact support IDs on Account switch; honor exact support links after newer exemplars appear.
- A current suppression is one Ecto match with store/scope/expiry limits. Public removal semantics permit policy removal despite the reader's contradictory classification.
- Replay targets a whole stored request; provider batches can affect multiple deliveries in the same Account. Confirmation must state this and retain the reviewed ID through refresh.
- New work means new normalized event rows. No change can arise from zero normalized input, not only duplicates. Requested-only is a real unrecorded-completion state; terminal audit persistence cannot be guaranteed after every failure.
- Timeline timestamps often represent local recording, and ordinary linked provider events were classified as requested replay by metadata. Use actual event types and source/time meaning.
- Preserve first 100 timeline ordering with disclosed overflow and separately reachable exact selected/replay evidence. No general history pagination was added to scope.
- Native actions, shortcut isolation, copy feedback, motion, and return focus have source-derived risks to exercise later; this research did not claim runtime accessibility failure or success.

## Methodology applied

- **Recommendation-first / decisive default:** alternatives were compared internally, then one set adopted under the owner's instruction.
- **Honest surface area:** no universal healthy statement, synthetic delivery outcome, unsupported repair action, or unproved data completeness.
- **Compatibility ergonomics:** stable read-model returns, host auth/session/config, tenant/schema-prefix behavior and prebuilt assets remain intact; necessary new helper reachability must be explicitly classified.
- **Current authority:** current product/scope/source and brandbook outrank historical roadmap/branding proposals. Contradictory explanatory trust prose is corrected against the actual outbound command while preserving stable guarantees.

## Coverage and stopping decision

The 36 comparisons were consolidated into 26 context decisions covering OUTUX-01–05. No remaining disagreement needs an owner preference. Further general research repeats the same boundaries; the next useful evidence is UI design and implementation-time behavior. This is the useful diminishing-returns point requested by the owner.

No pending todos matched Phase 169. Considered expansions are explicitly deferred without new backlog commitments. No application boot, source implementation, tests, browser capture, benchmark, current remote CI check, or formal plan was performed.

## Next workflow

Phase 169 context is ready. Recommended next command: `$gsd-ui-phase 169`, then `$gsd-plan-phase 169`. Existing `workflow.auto_advance` and chain flag are false; this discussion does not start either workflow automatically.
