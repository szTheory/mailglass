# Phase 20 Discuss Log

**Date:** 2026-04-30
**Phase:** 20 - Config Schema & Installer Surface for SES + Resend
**Mode:** Discuss (research-backed, subagent fan-out)

## Summary

The user asked for a one-shot, research-heavy recommendation set that minimizes decision burden on them, emphasizes strong DX, and pushes this posture left into GSD where possible. Four focused research passes were run:

1. Config schema parity for SES + Resend
2. Installer example surface
3. Publish-check failure contract for installer golden drift
4. Project-level GSD preference capture

The resulting recommendations were synthesized into the locked decisions in `20-CONTEXT.md`.

## User Direction Captured

- Research each meaningful decision deeply before deciding.
- Compare pros, cons, tradeoffs, ecosystem norms, and prior art from successful libraries.
- Learn from both good patterns and footguns in adjacent tools and frameworks.
- Prioritize coherent recommendations, principle of least surprise, strong developer ergonomics, and user-friendly defaults.
- Shift this preference left within GSD where possible, except for truly high-impact decisions the user might reasonably care about directly.

## Area 1: Config schema parity

### Research result

Recommended direction:
- Add only the exact SES and Resend keys already consumed and documented today.

Rejected alternative:
- Pre-expose a broader speculative provider config surface now.

### Why it won

- Fixes the actual contract-drift bug without inventing API debt.
- Matches idiomatic Elixir library posture: validate the real consumed surface, not hypothetical knobs.
- Keeps `Mailglass.Config`, docs, runtime behavior, and tests aligned.
- Preserves room to widen later without deprecating a bunch of dead keys.

## Area 2: Installer example surface

### Research result

Recommended direction:
- Keep the generated webhook snippet narrow and default-aligned, then explicitly teach opt-in provider expansion nearby.

Rejected alternative:
- Generate the full supported-provider list in the installer snippet.

### Why it won

- Matches Phoenix least surprise and the actual router default surface.
- Avoids copy-paste broadening of public endpoints for adopters who do not need every provider.
- Reduces future installer-golden churn when provider support changes.
- Keeps the installer as a safe bootstrap, not a product brochure.

## Area 3: Publish-check failure contract

### Research result

Recommended direction:
- Add a dedicated typed publish/release exception for installer golden drift, then render it through the normal Mix task failure path.

Rejected alternatives:
- Keep only a plain message-string failure.
- Reuse `Mailglass.ConfigError` for release hygiene.

### Why it won

- Fits Mailglass's real sibling-exception architecture.
- Preserves testable structured failure semantics without making CLI UX weird.
- Avoids taxonomy dilution and message-string coupling.
- Keeps the Mix task boring and actionable at the boundary.

## Area 4: GSD preference capture

### Research result

Recommended direction:
- Capture the preference at three layers:
  - Phase 20 context immediately
  - `.planning/METHODOLOGY.md` as the durable analytical lens
  - `.planning/config.json` with `workflow.discuss_mode: "assumptions"` as the default workflow behavior

Rejected alternatives:
- Keep the preference phase-local only.
- Add a methodology file without flipping the workflow default.

### Why it won

- Stops rediscovering the same posture every phase.
- Uses built-in GSD consumption points rather than undocumented hacks.
- Makes assumptions-first analysis the default while preserving the ability to escalate genuinely high-impact choices.

## Outcome

Phase 20 context is ready for planning. Downstream planning should assume:

- narrow honest SES/Resend config validation parity
- installer snippet that stays default-aligned and opt-in friendly
- typed publish-check drift failure that honors the existing error hierarchy
- assumptions-first, decisive-by-default project workflow posture
