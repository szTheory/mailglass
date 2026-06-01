# Phase 69: Click - Research

**Researched:** 2026-06-01  
**Domain:** Phoenix controller-driven demo UX and maintainer docs alignment  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### Dashboard Scope
- **D-01:** Refine the existing `MailglassDemoWeb.PageController.home/2`
  dashboard into the click-around hub instead of introducing a new LiveView or
  duplicating MailglassAdmin screens.
- **D-02:** Keep the dashboard as demo-app glue under `MailglassDemoWeb`; do not
  move dashboard behavior into `mailglass`, `mailglass_admin`, or
  `mailglass_inbound`.
- **D-03:** The dashboard should summarize the deterministic Northstar corpus
  and guide users into real preview/operator surfaces. It is a hub, not a second
  admin implementation.

### Navigation And Auth
- **D-04:** Keep dashboard links pointed at real mounted Mailglass surfaces:
  `/dev/mail`, `/demo/login?return_to=/ops/mail?tenant_id=northstar`, and
  `/demo/login?return_to=/ops/mail/inbound?tenant_id=northstar`.
- **D-05:** Preserve the simple demo-only login/session glue and safe
  `return_to` filtering. Do not add production auth/account management.
- **D-06:** Keep reset controls explicitly destructive and demo-only. The reset
  path may stay on the dashboard, but copy must make clear that it truncates and
  reseeds deterministic demo evidence tables.

### Docs Shape
- **D-07:** Use `reference/demo_app/README.md` as the canonical short
  quickstart and "what to click" guide.
- **D-08:** Keep root README references brief and directional if they need
  cleanup. Avoid scattering canonical demo truth across root, admin, and demo
  docs.
- **D-09:** Docs must explain the persona/JTBD, seeded outbound and inbound data,
  preview scenarios, reset behavior, Compose quickstart, dependency mode, and
  the demo-vs-contract boundary.

### UX Copy And Visual Polish
- **D-10:** Make the dashboard more guided and inspectable while keeping it
  calm, operator-focused, and evidence-first.
- **D-11:** Use Mailglass domain language consistently: preview, mailable,
  delivery, event, suppression, inbound record, evidence, routing trace, replay,
  tenant.
- **D-12:** Avoid marketing-page gloss, production-app account UI, analytics
  dashboards, and claims that demo routes, selectors, copy, screenshots, or DOM
  shape are stable public API.

### Verification Boundary
- **D-13:** Add focused Phase 69 verification around controller output, safe
  links, docs content, reset wording, and dashboard route coverage.
- **D-14:** Full Playwright journey expansion, screenshots, deterministic
  browser checkpoints, and `demo_browser_evidence.v1` artifact hardening remain
  Phase 70 work.
- **D-15:** Browser tests may remain as smoke seeds if already present, but Phase
  69 should not depend on private MailglassAdmin DOM shape as the stable proof
  of DEMO-03/DX-03.

### the agent's Discretion
- Exact dashboard layout and copy, provided it stays responsive, readable, and
  operator-focused.
- Whether dashboard verification is implemented as controller tests, static
  source assertions, or a small phase verifier, provided DEMO-03 and DX-03 are
  directly covered.
- Whether root README gets a minor pointer refresh, provided the demo README
  remains canonical.

### Deferred Ideas (OUT OF SCOPE)
- Full Playwright coverage for preview, outbound operator, inbound operator,
  replay, screenshots, and checkpoints remains Phase 70.
- Published-Hex-only demo gate after the live `mailglass_inbound` `1.0.0`
  release remains FUTR-01.
- Provider-matrix demo breadth beyond representative seeded stories remains
  FUTR-02.
- Ecosystem integrations from `SEED-003` remain FUTR-03.
</user_constraints>

## Summary

Phase 69 should be implemented as a targeted refinement of the existing controller-rendered dashboard and docs, not a new subsystem. The current app already has the correct seams: dashboard route, safe login redirect filtering, deterministic summary data, and mounted preview/operator/inbound surfaces. [VERIFIED: codebase grep]

The highest-value planning strategy is to constrain edits to `reference/demo_app` plus minimal root README pointer cleanup, then add verification that checks link safety, required dashboard content, and docs completeness for DEMO-03 and DX-03. Keep browser-depth proof deliberately deferred to Phase 70. [VERIFIED: codebase grep]

**Primary recommendation:** Keep Phase 69 as controller+docs polish on existing seams; prove outcomes with focused ExUnit/doc assertions, not expanded Playwright contracts. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Dashboard hub UI | Frontend Server (SSR) | Browser / Client | `PageController.home/2` renders full HTML and route cards server-side. [VERIFIED: codebase grep] |
| Demo summary counts | API / Backend | Database / Storage | `DemoData.summary/0` aggregates deliveries/events/inbound/suppressions from repo tables. [VERIFIED: codebase grep] |
| Safe operator navigation | API / Backend | Frontend Server (SSR) | `safe_return_to/1` whitelists local `/ops/mail` paths before redirect. [VERIFIED: codebase grep] |
| Reset action wording + behavior | Frontend Server (SSR) | API / Backend | Dashboard copy and reset endpoints live in controller actions; backend reseeds deterministic corpus. [VERIFIED: codebase grep] |
| Canonical click-around docs | Static docs | — | Demo quickstart and persona/JTBD live in `reference/demo_app/README.md`. [VERIFIED: codebase grep] |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix` | `~> 1.8` | Controller/router rendering and request pipeline in demo app | Already used by demo app; no new UI framework needed. [VERIFIED: codebase grep] |
| `phoenix_live_view` | `~> 1.1` | Mounted operator/inbound surfaces linked from dashboard | Existing operator surfaces are mounted through admin router macros. [VERIFIED: codebase grep] |
| `mailglass` | `~> 1.3` (or local path) | Preview + outbound data model and operator seams | Demo app already targets this dependency mode switch. [VERIFIED: codebase grep] |
| `mailglass_admin` | `~> 1.3` (or local path) | `/dev/mail` preview and `/ops/mail*` operator routing seams | Dashboard must link to these real mounted surfaces. [VERIFIED: codebase grep] |
| `mailglass_inbound` | `~> 0.3.0` (or local path) | Inbound operator/router and seeded inbound evidence | Required for inbound click path in phase scope. [VERIFIED: codebase grep] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `@playwright/test` | `^1.59.1` (lock shows `1.60.0`) | Existing smoke e2e seed for Phase 70 handoff | Keep as smoke seed only; do not promote to stable proof in Phase 69. [VERIFIED: codebase grep] |
| ExUnit (`mix test`) | bundled | Controller and docs-adjacent assertions | Primary verification lane for this phase. [VERIFIED: codebase grep] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Controller-rendered hub | New LiveView dashboard | Adds lifecycle/state complexity with no requirement gain for DEMO-03/DX-03. [VERIFIED: codebase grep] |
| Focused ExUnit checks | Broad Playwright coverage now | Violates D-14 scope split with Phase 70 evidence hardening. [VERIFIED: codebase grep] |

**Installation:** No new external packages required for Phase 69. [VERIFIED: codebase grep]

## Package Legitimacy Audit

No package installation is required in this phase; legitimacy gate is not applicable. [VERIFIED: codebase grep]

## Architecture Patterns

### System Architecture Diagram

```text
Browser request GET "/" 
  -> Phoenix Router "/" 
  -> PageController.home/2 
  -> DemoData.summary/0 
  -> Repo aggregates + inbound count
  -> HTML dashboard (cards + reset form)
  -> User clicks card
      -> /dev/mail (preview) OR
      -> /demo/login?return_to=/ops/mail... (safe filter + session) -> /ops/mail...
      -> /demo/login?return_to=/ops/mail/inbound... -> /ops/mail/inbound...
  -> Optional POST /demo/reset -> DemoData.reset! -> redirect "/"
```

### Recommended Project Structure
```text
reference/demo_app/
├── lib/mailglass_demo_web/controllers/   # dashboard/login/reset behavior
├── lib/mailglass_demo_web/router.ex      # mounted preview/operator/inbound routes
├── lib/mailglass_demo/demo_data.ex       # deterministic summary/reset corpus
├── test/mailglass_demo_web/              # controller safety/wording checks
└── README.md                             # canonical quickstart + persona/JTBD
```

### Pattern 1: Controller-As-Hub, Mounted-Surfaces-As-Product
**What:** Keep dashboard logic thin and route to existing mounted product surfaces.
**When to use:** When click-around UX is meant to expose existing product flows, not reimplement them.
**Example:**
```elixir
# Source: reference/demo_app/lib/mailglass_demo_web/controllers/page_controller.ex
<a class="card" href="/dev/mail">...</a>
<a class="card" href="/demo/login?return_to=/ops/mail?tenant_id=#{summary.tenant_id}">...</a>
```

### Anti-Patterns to Avoid
- **Dashboard feature duplication:** Rebuilding operator UI on home page creates drift and breaks D-03 intent. [VERIFIED: codebase grep]
- **Open redirect regression:** Expanding `return_to` beyond local allowed paths weakens safety checks already covered in tests. [VERIFIED: codebase grep]
- **Docs truth fragmentation:** Spreading canonical quickstart across multiple docs increases drift against D-07/D-08. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Demo auth/session | New auth/accounts system | Existing `/demo/login` session glue + safe redirect filter | Scope explicitly excludes production auth. [VERIFIED: codebase grep] |
| Preview/operator UI | Custom copy of admin LiveViews | Existing mounted `mailglass_admin` seams | Prevents divergence and contract overreach. [VERIFIED: codebase grep] |
| Seed corpus bookkeeping | Ad-hoc dashboard constants | `DemoData.summary/0` + `DemoData.reset!/0` | Keeps UI aligned with deterministic corpus state. [VERIFIED: codebase grep] |

**Key insight:** Phase value comes from guided navigation and docs clarity, not from adding new runtime primitives. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Phase 70 Scope Pull-In
**What goes wrong:** Planning includes screenshot/checkpoint hardening now.
**Why it happens:** Existing Playwright seed creates temptation to over-extend.
**How to avoid:** Gate Phase 69 verification on controller/docs outcomes only.
**Warning signs:** Tasks mention deterministic checkpoint artifacts as acceptance criteria.

### Pitfall 2: Unsafe Return-To Changes
**What goes wrong:** Redirect accepts external/unsafe paths.
**Why it happens:** Convenience edits to login flow bypass `safe_return_to/1`.
**How to avoid:** Keep whitelist behavior and retain security tests.
**Warning signs:** Missing assertion for `"//evil.example/phish"` fallback.

### Pitfall 3: Reset UX Understates Destruction
**What goes wrong:** Users cannot tell reset truncates/reseeds evidence tables.
**Why it happens:** Copy optimization removes explicit destructive warning.
**How to avoid:** Preserve explicit destructive wording in UI/docs/tests.
**Warning signs:** No mention of truncation/reseed in dashboard or README reset section.

## Code Examples

### Safe Redirect Guard
```elixir
# Source: reference/demo_app/lib/mailglass_demo_web/controllers/page_controller.ex
if is_nil(uri.scheme) and is_nil(uri.host) and operator_path?(uri.path) do
  return_to
else
  default_operator_path()
end
```

### Demo Reset Endpoint Warning Contract
```elixir
# Source: reference/demo_app/lib/mailglass_demo_web/controllers/page_controller.ex
json(%{
  status: "ok",
  warning: "Destructive demo reset endpoint: truncates and reseeds demo evidence tables.",
  summary: DemoData.summary()
})
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `reference/host_app` as rich click-around proof | `reference/demo_app` as realistic click-around proof | v1.5 phase sequencing | Keeps host app narrow, moves UX evidence to dedicated demo app. [VERIFIED: codebase grep] |

**Deprecated/outdated:**
- Treating demo DOM/routes/copy as stable public API is explicitly disallowed by current docs boundary language. [VERIFIED: codebase grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | No additional external package installs are needed for this phase. [ASSUMED] | Standard Stack / Package Legitimacy Audit | Planner may miss an install step if new tooling is later introduced. |

## Open Questions (RESOLVED)

1. **RESOLVED: Should root README pointer text be adjusted now or left as-is?**
   - What we know: Root README already points to `reference/demo_app` demo path. [VERIFIED: codebase grep]
   - Decision: Leave root README and admin package docs out of Phase 69 unless execution discovers a broken or misleading pointer. The canonical quickstart and click-path truth stays in `reference/demo_app/README.md` per D-07 and D-08.
   - Planning impact: `69-02-PLAN.md` intentionally updates only `reference/demo_app/README.md` and its docs contract test; this resolves the roadmap's admin-docs drift concern by preventing canonical truth from being scattered across admin docs.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Demo app/test execution | ✓ | `1.19.5` | — |
| Mix | Verification commands | ✓ | `1.19.5` | — |
| Docker | Compose quickstart (`DX-03`) | ✓ | `29.5.2` | Run demo app directly via `mix phx.server` |
| Node.js | Existing Playwright smoke seed | ✓ | `v22.14.0` | Skip e2e lane in Phase 69 acceptance |
| npm | Browser smoke seed install | ✓ | `11.1.0` | Use existing cached deps in compose volume |

**Missing dependencies with no fallback:**
- None. [VERIFIED: local command probes]

**Missing dependencies with fallback:**
- None. [VERIFIED: local command probes]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Phoenix ConnCase) + Playwright smoke seed |
| Config file | `reference/demo_app/test/test_helper.exs` and `reference/demo_app/assets/playwright.config.cjs` |
| Quick run command | `cd reference/demo_app && mix test test/mailglass_demo_web/page_controller_security_test.exs` |
| Full suite command | `cd reference/demo_app && mix test --warnings-as-errors` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DEMO-03 | Dashboard links to preview/outbound/inbound surfaces | controller + route assertions | `cd reference/demo_app && mix test` (add/extend dashboard test) | ❌ Wave 0 |
| DX-03 | Docs include quickstart, persona/JTBD, seeded-data click path, reset semantics | docs static assertion | `rg -n "Quickstart|Persona|JTBD|Reset|northstar|dev/mail|ops/mail" reference/demo_app/README.md` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `cd reference/demo_app && mix test test/mailglass_demo_web/page_controller_security_test.exs`
- **Per wave merge:** `cd reference/demo_app && mix test --warnings-as-errors`
- **Phase gate:** Full suite green before `$gsd-verify-work`

### Wave 0 Gaps
- [ ] `reference/demo_app/test/mailglass_demo_web/page_controller_dashboard_test.exs` — direct DEMO-03 dashboard card/link coverage
- [ ] `reference/demo_app/test/mailglass_demo/docs_contract_test.exs` — DX-03 docs contract assertions

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Demo-only login/session glue with restricted redirect target |
| V3 Session Management | yes | Session keys set in controller and consumed by operator mount auth |
| V4 Access Control | yes | Operator routes protected by demo auth seam and unauthorized path fallback |
| V5 Input Validation | yes | `return_to` URI parsing + local-path whitelist |
| V6 Cryptography | yes | `Plug.Crypto.secure_compare/2` for reset token match |

### Known Threat Patterns for Phoenix demo stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Open redirect via `return_to` | Spoofing | Keep strict local-path/operator-path allowlist and tests |
| Unauthorized destructive reset call | Tampering | Require header token + secure compare + explicit warning contract |
| Over-claiming demo DOM as stable API | Repudiation | Keep docs boundary language and avoid selector-based phase acceptance |

## Sources

### Primary (HIGH confidence)
- `reference/demo_app/lib/mailglass_demo_web/controllers/page_controller.ex` - dashboard, login safety, reset wording, token guard
- `reference/demo_app/lib/mailglass_demo_web/router.ex` - mounted route surfaces for demo click path
- `reference/demo_app/README.md` - canonical quickstart/persona/JTBD/reset/dependency mode boundary
- `reference/demo_app/lib/mailglass_demo/demo_data.ex` - deterministic summary/reset corpus
- `reference/demo_app/test/mailglass_demo_web/page_controller_security_test.exs` - redirect/token safety coverage
- `.planning/phases/69-click/69-CONTEXT.md` - locked decisions and deferred boundaries
- `.planning/REQUIREMENTS.md` - DEMO-03 and DX-03 requirement targets
- `.planning/config.json` - nyquist validation enabled

### Secondary (MEDIUM confidence)
- None.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all stack claims are directly backed by `mix.exs`, router/controller, and existing demo docs/tests.
- Architecture: HIGH - responsibilities map directly to current controller/router/data boundaries.
- Pitfalls: HIGH - pitfalls derive from locked scope boundaries and existing security/test seams.

**Research date:** 2026-06-01  
**Valid until:** 2026-07-01
