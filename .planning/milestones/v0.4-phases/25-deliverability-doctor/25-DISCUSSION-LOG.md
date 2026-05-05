# Phase 25: deliverability-doctor - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions live in `25-CONTEXT.md`. This log preserves the reasoning that led there.

**Date:** 2026-05-01
**Phase:** 25-deliverability-doctor
**Mode:** assumptions + research synthesis
**Areas analyzed:** phase shape, CLI contract, findings model, protocol scope, architecture posture, decision posture

## Assumptions Presented

### Phase shape
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Phase 25 should stay a DNS-focused operator diagnostic, not a general deliverability platform. | Confident | `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `README.md`, `lib/mailglass/events.ex` |

### CLI contract
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| The Mailglass-native contract should prefer explicit `--domain` input over positional or inferred targets. | Likely | `lib/mix/tasks/mailglass.install.ex`, `lib/mix/tasks/mailglass.publish.check.ex`, `lib/mix/tasks/mailglass.docs.check.ex`, `lib/mix/tasks/mailglass.suppressions.resync.ex` |

### Findings model
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| The task should output structured operator findings with honest `cannot_verify` states rather than binary pass/fail claims. | Confident | `.planning/REQUIREMENTS.md`, `.planning/PROJECT.md`, `lib/mailglass/errors/config_error.ex`, `guides/dkim-setup.md` |

### Protocol scope
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Standards-aware SPF/DKIM/DMARC/MX/BIMI checks are useful; holistic deliverability scoring would be misleading. | Likely | `guides/dkim-setup.md`, `README.md`, project scope docs, external standards research |

### Architecture posture
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| A reusable runtime module plus thin Mix wrapper is the right fit for Mailglass. | Likely | `mix.exs`, Mix task patterns, project methodology, Phoenix context guidance |

## Corrections Made

No corrections were requested. The user explicitly asked for deep research and a one-shot cohesive recommendation set rather than an interview-driven correction loop.

## External Research

### CLI contract and task ergonomics
- `mix mail.doctor --domain example.com` is the best fit for Mailglass even though positional args are common in Mix broadly. The deciding factor is local repo coherence and anti-surprise posture.
- Sources:
  - `checkdmarc`
  - Phoenix Mix generators
  - Mix and Hex task docs
  - `npm doctor`
  - Django `check`
  - Bundler `bundle doctor`

### Findings model and UX
- The strongest model is:
  - grouped protocol sections
  - human-first default output
  - `--verbose` for evidence
  - `--format json` from day one
- Trust requires separating “observed bad configuration” from “insufficient evidence to verify.”
- Sources:
  - Mix task docs
  - Credo output formats
  - ESLint formatter model
  - Django system checks
  - Gmail sender guidelines
  - BIMI Group guidance

### Protocol scope and operator truthfulness
- SPF, DMARC, MX, and BIMI readiness are high-signal DNS checks.
- DKIM requires selector knowledge; DNS alone cannot honestly prove active signing without known selectors or message evidence.
- Do not turn optional or readiness-oriented findings into fake hard failures.
- Sources:
  - RFC 7208
  - RFC 6376
  - RFC 7489
  - RFC 7505
  - Google sender guidance
  - dmarcian
  - MXToolbox
  - BIMI Group

### Architecture and dependencies
- The idiomatic Elixir/Phoenix pattern is reusable runtime module plus thin CLI adapter.
- Native OTP DNS behind a tiny Mailglass-owned resolver seam is preferable to new runtime dependencies in Phase 25.
- Sources:
  - Phoenix contexts guidance
  - Mix task guidance
  - OTP `:inet_res`
  - Credo
  - `ex_check`
  - `doctor`
  - ESLint programmatic API pattern

## Final Recommendation Snapshot

- Keep Phase 25 DNS-only and operator-trust-first.
- Use `mix mail.doctor --domain example.com` as the only canonical target contract.
- Ship grouped human output, `--verbose`, and `--format json`.
- Implement standards-aware structural checks plus bounded advisories.
- Keep DKIM honest: explicit selectors or `cannot_verify`.
- Build a reusable internal diagnostic engine with a thin Mix task wrapper and no new runtime dependencies by default.
- Push the GSD posture further left: research broadly, recommend one cohesive default, escalate only for truly high-impact contract or trust decisions.
