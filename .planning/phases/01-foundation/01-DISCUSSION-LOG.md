# Phase 1: Foundation — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `01-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-04-22
**Phase:** 01-foundation
**Areas discussed:** Error hierarchy shape, MSO/Outlook fallback strategy, Component API style, Telemetry enforcement point

---

## Gray Area Selection

User request: "research using subagents" all four gray areas, produce coherent one-shot recommendations with pros/cons/tradeoffs, lessons from prior art across languages/frameworks, great DX/UX, principle of least surprise, cohesive with project vision.

All four gray areas selected for deep research:

| Option | Description | Selected |
|--------|-------------|----------|
| Error hierarchy shape | Separate structs vs single `%Mailglass.Error{}` with `:type` vs hybrid protocol/behaviour. Fields, serialization, raise-vs-return. | ✓ |
| MSO/Outlook fallback strategy | Aggressive (VML everywhere) vs Surgical (button + ghost tables only) vs Minimal (no VML). Dark mode, Premailex interaction, Floki plaintext. | ✓ |
| Component API style | Slot-heavy vs Attribute-heavy vs Hybrid. Theming, escape hatches, plaintext extraction, Gettext touchpoints. | ✓ |
| Telemetry enforcement point | Runtime wrapper vs Convention-only + Phase 6 Credo vs Both vs Compile-time macro. | ✓ |

**Approach:** Four parallel general-purpose research agents, each briefed with: locked constraints from PROJECT.md/REQUIREMENTS.md/research, 3-4 explicit options, required output shape (≤1,500 words each, sections: Context / Patterns studied / Tradeoff table / Footguns / Recommendation / Code snippet / Coherence notes).

---

## Area 1: Error hierarchy shape

| Option | Description | Selected |
|--------|-------------|----------|
| A. Separate structs, no parent | Six `defexception` modules, each with per-kind `:type` atom for sub-categorization. Ecto/Oban/Plug pattern. | ✓ |
| B. Single parent struct with `:type` discriminator | One `%Mailglass.Error{type: …}`. Swoosh/Stripe/Tesla pattern. | |
| C. Hybrid: protocol + per-kind structs | `Mailglass.Error` protocol/behaviour with per-kind structs conforming. Plug's exception-protocol shape. | |

**User's choice:** A (recommended), refined to "Siblings with a shared behaviour (no parent struct)" — behaviour contract + closed `:type` atom sets + `Mailglass.Error` as namespace/behaviour module, not parent struct.

**Notes:** Dialyzer precision won the tradeoff over single-struct ergonomics. Per-kind field specialization (`RateLimitError.retry_after_ms`, `SignatureError.provider`, `SendError.delivery_id`) has non-nil guarantees that a single-struct approach would lose. Closed `:type` atom sets per struct documented in `api_stability.md` with automated test asserting `__types__/0` matches docs.

**Rationale captured in D-01..D-09.**

---

## Area 2: MSO/Outlook fallback strategy

| Option | Description | Selected |
|--------|-------------|----------|
| A. Aggressive | VML everywhere, max bulletproofness | |
| B. Surgical | VML only on `<.button>` + ghost tables for `<.row>`/`<.column>` | ✓ |
| C. Minimal | No VML at all; modern-Outlook-first | |
| D. VML only on button (considered, rejected) | Missing ghost tables would break multi-column layout in classic Outlook | |

**User's choice:** B (recommended).

**Notes:** Classic Outlook EOL Oct 2026 but enterprise preservation continues ~2028. Research confirmed surgical VML is the sweet spot: ~1.1× HTML size overhead, recognizably-correct rendering in Outlook 2016/2019, zero cost in new Outlook (WebView2 ignores conditional comments). Dark mode explicitly deferred to v0.5 — Outlook.com partial-invert is unfixable. Premailex must preserve conditional comments (issue #36) — golden fixture test guards regression. Floki plaintext runs on pre-VML tree.

**Rationale captured in D-10..D-15.**

---

## Area 3: Component API style

| Option | Description | Selected |
|--------|-------------|----------|
| A. Slot-heavy / HEEx-idiomatic | All components take `inner_block`. Matches core_components. | |
| B. Attribute-heavy / Declarative | Every property is an attribute; self-closing. Matches MJML. | |
| C. Hybrid / per-component pragmatic | Content = slot, layout = slot, atomic = attribute-only | |
| D. Hybrid + brand-theme-aware | C + compile-time theme map + variant enums + `data-mg-plaintext` strategies | ✓ |

**User's choice:** D (recommended).

**Notes:** Chose D over C for the theme-map integration that ties the component API to the brand book palette (Ink/Glass/Ice/Mist/Paper/Slate) via enum variants (`variant: :primary | :secondary | :ghost`, `tone: :ink | :glass | :slate`, `bg: :paper | :mist | …`), with hex values living in `config :mailglass, :theme` and inlined styles (not CSS variables — email-client support is inconsistent). `data-mg-plaintext` strategy attributes drive a custom Floki walker, not bare `Floki.text/1`. Gettext is adopter-responsibility inside slots; `<.preheader text>` is the only attribute-translated exception. Required `alt` on `<.img>` is the accessibility floor. React Email's inline-style-merge footgun deliberately refused (content components exclude `style` from `:global` rest).

**Rationale captured in D-16..D-25.**

---

## Area 4: Telemetry enforcement point

| Option | Description | Selected |
|--------|-------------|----------|
| A. Runtime wrapper | `Mailglass.Telemetry.execute/3` validates event name + meta keys + catches handlers | |
| B. Convention-only + Phase 6 Credo | Direct `:telemetry.execute/3`; named span helpers in `Mailglass.Telemetry`; AST enforcement at lint time | ✓ |
| C. Both | Runtime wrapper + Credo | |
| D. Compile-time macro | Macro expands event paths; zero runtime cost | |

**User's choice:** B (recommended).

**Notes:** `:telemetry.execute/3` already isolates handler exceptions (per-handler try/catch + auto-detach + emits `[:telemetry, :handler, :failure]`) — CORE-03's "handlers must not break pipeline" is upheld by the library itself. Adding mailglass-side try/rescue is dead code or worse (swallows the meta-event operators need). Runtime whitelist filtering is a whitelist-regression catastrophe waiting to happen in multi-tenant systems — silent `:tenant_id` drops send debugging dark. Credo AST walk in Phase 6 catches structural drift at lint time for mailglass's own code. Named span helpers per domain (`render_span/2` in Phase 1, others land in owning phases) keep event-name literals grep-able. Low-level `execute/3` escape hatch prepends `:mailglass` for the handful of counter-style emits. No compile-time macro — module-size bloat + opaque to readers. OpenTelemetry bridging is adopter-owned via `opentelemetry_telemetry`; no `attach_otel/0` ships in v0.1.

**Rationale captured in D-26..D-33.**

---

## Claude's Discretion

Captured in `01-CONTEXT.md` §Shared discretion:

- Minimal Phase 1 Config schema (expands per phase)
- `Repo.transact/1` scaffold-only in Phase 1 (real usage Phase 2+)
- `IdempotencyKey` sanitization heuristics
- Exact error `message` string wording per `:type` (brand-voice-conformant)
- `boundary` blocks only for Phase 1 modules (no empty skeletons for later phases)
- `Mailglass.Components.layout/1` exact HEEx structure

## Deferred Ideas

Captured in `01-CONTEXT.md` §Deferred Ideas:

- Dark-mode theme variants → v0.5
- `<.bare_button>` primitive set → re-evaluate v0.5
- `Mailglass.TemplateEngine.MJML` implementation → behaviour shipped Phase 1, impl deferred
- `OptionalDeps.OpenTelemetry.attach_otel/0` helper → re-evaluate v0.5
- `tailwind-merge`-style class composer → not shipped
- `telemetry_registry` event discovery → `@moduledoc` catalog sufficient for v0.1
- `Jason.Encoder` on `:cause` chain → adopters use `root_cause/1` instead

---

*Discussion completed 2026-04-22. Research agents: 4 parallel general-purpose subagents, ~60 minutes total wall-clock.*
