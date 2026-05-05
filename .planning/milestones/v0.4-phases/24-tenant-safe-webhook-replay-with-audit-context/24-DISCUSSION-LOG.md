# Phase 24 Discuss Log

**Date:** 2026-05-01
**Phase:** 24 - Tenant-Safe Webhook Replay with Audit Context
**Mode:** Discuss (all areas, research-backed, subagent fan-out)

## Summary

The user requested a one-shot, research-heavy recommendation set across all replay gray areas, with explicit tradeoffs, ecosystem precedent, DX emphasis, and minimal escalation for routine decisions. Three focused research passes were run in parallel:

1. Replay target shape and replay UX
2. Recent-auth policy and durable audit visibility
3. Safety boundaries, replay scope, and broader ecosystem/GSD posture

The resulting recommendations were synthesized into the locked decisions in `24-CONTEXT.md`.

## User Direction Captured

- Discuss all meaningful gray areas for Phase 24.
- Research each area deeply before deciding.
- Compare pros, cons, tradeoffs, ecosystem norms, and lessons from successful tools and libraries.
- Learn from both strong patterns and footguns.
- Prefer coherent, one-shot recommendations so the user does not need to arbitrate routine implementation tradeoffs.
- Shift this preference left within GSD where possible, except for truly high-impact choices the user might care about directly.

## Area 1: Replay target shape

### Research result

Recommended direction:
- Keep the canonical replay unit as a single raw `mailglass_webhook_events` row.
- Allow the delivery screen to be a convenience entrypoint, but never let “delivery replay” become a separate backend semantic.

Rejected alternatives:
- Delivery-only replay inferred from the selected delivery
- Broader delivery-wide or windowed replay as the default surface

### Why it won

- Best tenant-safety and smallest blast radius.
- Preserves exact raw-payload identity and existing ingest/idempotency semantics.
- Matches strong webhook operator precedent: specific delivery/event redelivery rather than generic state rebuild.
- Fits the current delivery-first LiveView without weakening the replay boundary.

## Area 2: Replay UX

### Research result

Recommended direction:
- Use a server-rendered LiveView modal launched from the selected delivery detail pane.

Rejected alternatives:
- Browser `confirm()` prompt
- Separate replay confirmation page
- Row-level replay actions in the master list

### Why it won

- Gives enough context for a sensitive operator action.
- Supports stale-auth messaging and multi-target chooser states without custom JS.
- Keeps operators inside the existing inspect-in-place workflow.
- Avoids ambiguous “Replay latest” shortcuts and wrong-click surfaces.

## Area 3: Recent-auth policy

### Research result

Recommended direction:
- Treat replay as `:destructive_action`.
- Require a step-up only when `recent_auth_at` is missing or stale.
- Re-check authorization at action time, not just at mount.

Rejected alternatives:
- Fresh auth for every replay click
- Multi-tiered replay policy split too early across “safe” and “dangerous” replay types

### Why it won

- Matches Phoenix/GitHub-style recent-auth posture.
- Preserves security without turning replay into a constant-friction workflow.
- Reuses the Phase 23 auth seam directly.
- Keeps the policy simple enough for a library package and a one-maintainer budget.

## Area 4: Audit visibility

### Research result

Recommended direction:
- Append durable replay facts to `mailglass_events`.
- Surface them inline in the delivery timeline when relevant and through a dedicated replay-history read model/view.

Rejected alternatives:
- Flash-only success/failure UX
- Mutable `last_replayed_*`-style fields as the primary audit store
- Hiding audit details only inside raw webhook rows

### Why it won

- Preserves append-only truth.
- Makes operator actions auditable without inventing a second mutable audit system.
- Supports both delivery-local debugging and broader incident review.
- Avoids overwriting history with “latest replay” convenience fields.

## Area 5: Safety boundaries

### Research result

Recommended direction:
- Phase 24 should only replay one stored inbound webhook request at a time.
- Treat duplicate/no-op outcomes as valid operator-visible results.
- Defer broader replay-all, backfill, or semantic rebuild tooling.

Rejected alternatives:
- Replay all webhook failures for a delivery or time window by default
- Domain-state rebuild/backfill semantics inside this phase
- Partial replay of normalized child events from one raw provider request

### Why it won

- Keeps Phase 24 aligned with `REPLAY-01..03` instead of expanding into a larger incident platform.
- Reduces support burden and surprise for adopters.
- Prevents semantic drift between “redelivery of a stored request” and “recompute the world.”

## Global preference recorded

The user explicitly prefers:

- research-first reasoning
- assumptions-first/default-to-analysis workflow behavior
- coherent recommendations over broad option menus
- decisive-by-default downstream behavior
- escalation only for materially impactful public-contract, security, retention, or tenant-boundary decisions

This preference is now reflected in:

- `24-CONTEXT.md` as the local phase decision posture
- `.planning/METHODOLOGY.md` as the durable project-level lens
- `.planning/config.json` by switching `workflow.discuss_mode` to `"assumptions"`

## Outcome

Phase 24 context is ready for planning. Downstream planning should assume:

- one exact raw-webhook replay target
- delivery-detail convenience UI over that canonical target
- modal-based replay confirmation
- action-time recent-auth enforcement through the existing auth seam
- append-only replay audit events as the durable source of truth
- broader replay/backfill surfaces deferred until explicitly scoped
