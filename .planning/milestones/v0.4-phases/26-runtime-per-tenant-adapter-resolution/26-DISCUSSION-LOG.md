# Phase 26: runtime-per-tenant-adapter-resolution - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-01
**Phase:** 26-runtime-per-tenant-adapter-resolution
**Mode:** assumptions
**Areas analyzed:** resolver ownership, fallback semantics, async timing, persistence, runtime architecture, ecosystem precedents

## Assumptions Presented

### Resolver ownership
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Per-tenant outbound routing should live on `Mailglass.Tenancy` as an optional callback returning a stable adapter ref, with concrete adapter tuples resolved through a Mailglass-owned config registry. | Confident | `lib/mailglass/tenancy.ex`, `guides/multi-tenancy.md`, `lib/mailglass/outbound.ex`, explorer subagent synthesis, Elixir optional callback idioms |

### Default behavior
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Single-tenant apps must preserve today’s global-adapter default path with zero migration burden. | Confident | `config/config.exs`, `config/runtime.exs`, `lib/mailglass/tenancy/single_tenant.ex`, `test/mailglass/tenancy_test.exs` |

### Async timing
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Fully late-bound dispatch-time provider resolution is too surprising once per-tenant routing exists; queue-time route intent should be persisted. | Likely | `lib/mailglass/outbound.ex`, `lib/mailglass/outbound/worker.ex`, `lib/mailglass/outbound/delivery.ex`, async-timing subagent research, Oban uniqueness docs |

### Runtime architecture
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Phase 26 should avoid a new registry/cache singleton and keep route resolution explicit and stateless first. | Confident | `lib/mailglass/outbound.ex`, absence of current registry implementation, `.planning/milestones/v0.1-research/PITFALLS.md`, Elixir library guidelines |

### Ecosystem fit
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Mailglass should resemble Django/Anymail/Bamboo-style runtime backend selection more than named-mailer-per-tenant systems. | Likely | Rails/Laravel/Django/Anymail/Symfony/Bamboo precedent review; local Swoosh adapter shape |

## Corrections Made

No corrections — the user asked to discuss all areas, have the agent decide, research broadly, and produce one cohesive recommendation set with escalation reserved for very impactful choices.

## External Research

- Resolver seam patterns: optional callbacks and low-surprise Elixir library design. Sources:
  - `https://hexdocs.pm/elixir/1.4.5/behaviours.html`
  - `https://hexdocs.pm/elixir/1.18.0/library-guidelines.html`
  - `https://hexdocs.pm/swoosh/Swoosh.Adapter.html`
- Queue and runtime config posture:
  - `https://hexdocs.pm/oban/unique_jobs.html`
  - `https://hexdocs.pm/elixir/config-and-distribution.html`
- Cross-ecosystem mail transport selection:
  - `https://guides.rubyonrails.org/action_mailer_basics.html`
  - `https://laravel.com/docs/13.x/mail`
  - `https://docs.djangoproject.com/en/dev/topics/email/`
  - `https://anymail.dev/en/v12.0/tips/multiple_backends/`
  - `https://hexdocs.pm/bamboo/Bamboo.Mailer.html`

## Global Preference Recorded

The user explicitly reinforced the existing project preference for:

- broad research before recommendations
- one cohesive recommendation set rather than broad option menus
- decisive-by-default downstream planning and execution
- escalation only for very impactful contract, security, trust, tenant-boundary, or maintainer-burden decisions

This preference is reflected in:

- `26-CONTEXT.md` as the local Phase 26 decision posture
- `.planning/METHODOLOGY.md` by strengthening recommendation-first / high-impact-escalation language
- `.planning/config.json` already using `workflow.discuss_mode: "assumptions"`
