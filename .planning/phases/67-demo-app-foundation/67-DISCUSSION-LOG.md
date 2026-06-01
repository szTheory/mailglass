# Phase 67: Demo App Foundation - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution
> agents. Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-01
**Phase:** 67-demo-app-foundation
**Mode:** assumptions + subagent research
**Areas analyzed:** Demo App Boundary, Dependency Mode, Docker Compose DX,
Setup/Reset Semantics, Router/Auth Surface, Evidence Handoff, UI/Copy Direction,
Cross-Ecosystem Lessons

## Assumptions Presented

### Initial Assumptions

The initial assumption set was:

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| `reference/demo_app` is the intended separate demo app foundation, distinct from `reference/host_app`. | Confident | `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `reference/demo_app/*`, `reference/host_app/SCOPE.md` |
| Dual dependency mode should stay as `MAILGLASS_DEMO_DEPS=hex` for published Hex mode, with local path deps as default maintainer mode. | Confident | `reference/demo_app/mix.exs`, `reference/demo_app/README.md` |
| `compose.demo.yml` is the one-command local click-around entrypoint. | Confident | `compose.demo.yml`, `reference/demo_app/README.md` |
| Cache-aware Docker volumes for Mix, Hex, npm, Playwright, deps, and `_build` are part of the foundation. | Confident | `compose.demo.yml` |
| Current dashboard/routes are foundation-level only; richer UX/data/evidence stay in Phases 68-70. | Confident | `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md` |

## User Direction

The user asked to research and consider all assumptions deeply using subagents,
including:

- pros, cons, and tradeoffs for each approach;
- idiomatic Elixir/Plug/Ecto/Phoenix practice for this type of library/app;
- lessons from successful libraries/apps in other ecosystems;
- what those ecosystems got right and what footguns to avoid;
- strong developer ergonomics and user friendliness;
- coherent one-shot recommendations that fit Mailglass's goals and vision;
- applicable guidance from the local `prompts/` directory.

No correction to the core direction was requested. The user explicitly preferred
a synthesized recommendation set rather than another choice menu.

## Subagent Research Summary

### Codebase/Phoenix Assumptions

`gsd-assumptions-analyzer` confirmed:

- Keep `reference/demo_app` separate from `reference/host_app`.
- Preserve local path deps by default and `MAILGLASS_DEMO_DEPS=hex` for Hex mode.
- Keep `setup`, `ecto.setup`, `ecto.reset`, and a fast deterministic
  `demo.reset`.
- Keep browser dashboard/login/reset, `/dev/mail` preview, and `/ops/mail`
  operator surfaces separate.
- Stop Phase 67 at runnable foundation; defer richer scenarios and evidence to
  Phases 68-70.

### Local Prompt Corpus

The prompt synthesis found:

- The demo should prove "email made visible" through preview, timelines,
  suppressions, inbound evidence, and replay/debugging.
- The UI should feel calm and operator-focused, not like a marketing site or
  analytics casino.
- Generated Phoenix structure, thin web modules, context boundaries, and
  function-component-first UI remain the best default.
- Evidence should be browser-driven and deterministic.
- Example/demo assets must not leak into Hex packages or public API promises.

### Cross-Ecosystem Research

External ecosystem research supported:

- Rails engines use a mounted dummy host app to prove mountable integration.
- Django reusable apps emphasize quickstart clarity and package/app boundary
  discipline.
- Stripe-style sample apps show strong DX through explicit setup, env examples,
  and one recommended path.
- Storybook-style examples are useful when they are live verification surfaces,
  but can sprawl if the scenario matrix grows without discipline.
- ActionMailer/ActionMailbox reinforce preview/conductor-style local inspection,
  while also showing the footgun of confusing development inspection with
  production delivery proof.

### DX/Container/Evidence Analysis

The DX pass found the current foundation is close but should be hardened:

- Add a Phoenix readiness endpoint/healthcheck and make `demo_e2e` wait for
  healthy app state.
- Use `npm ci` instead of `npm install`.
- Ensure Playwright browser system dependencies are deterministic.
- Add a named volume for demo `assets/node_modules`.
- Reset deterministic data before browser evidence.
- Create stable evidence artifact paths and schema/checkpoint handoff for
  Phase 70.

## Corrections Made

No user corrections were made. Instead, the assumptions were expanded into a
stronger recommendation set with additional footguns and planning directives.

## External Research

The discussion used external ecosystem references as directional evidence:

- Phoenix Mix task documentation for idiomatic generated app setup/reset aliases.
- Rails engine documentation for mounted dummy host testing.
- Rails Action Mailbox documentation for conductor-style inbound local
  inspection.
- Django reusable app documentation for packaging/quickstart boundary clarity.
- Docker Compose volume documentation for named volume persistence.
- Playwright CI documentation for deterministic browser dependency setup and CI
  stability.

## Deferred During Discussion

- Full realistic demo data remains Phase 68.
- Rich dashboard/docs/click-around UX remains Phase 69.
- Browser screenshot/checkpoint evidence gate remains Phase 70.
- Provider matrix expansion and ecosystem integrations remain future work.

---

*Discussion log generated: 2026-06-01*
