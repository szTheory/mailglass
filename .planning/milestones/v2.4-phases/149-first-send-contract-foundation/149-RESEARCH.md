# Phase 149: First-Send Contract Foundation - Research

**Researched:** 2026-08-02  
**Domain:** Elixir/Phoenix transactional-message preflight, rendering, and tenancy contract  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

## Implementation Decisions

### Tenancy contract
- **D-01:** Shared outbound preflight treats the configured `Mailglass.Tenancy.SingleTenant` resolver as an implicit valid tenant `"default"` when no process-local tenant stamp exists.
- **D-02:** Any configured custom tenancy implementation remains fail-closed: absent, invalid, or unrestorable tenant context produces a typed, actionable tenancy failure and must never fall back to tenant `"default"`.

### Envelope preflight and error contract
- **D-03:** Add one shared, pure envelope/body validation gate used by outbound paths before rendering, suppression checks, rate-limit consumption, persistence, job insertion, or provider dispatch.
- **D-04:** Recipient validation counts every entry across the native Swoosh `to`, `cc`, and `bcc` collections and accepts exactly one total envelope recipient. Zero recipients and every multi-recipient combination are rejected without silently selecting or dropping an address.
- **D-05:** Body validation accepts only supported shapes with a non-empty HTML and/or plaintext body. Unsupported functions, values, or empty-body shapes fail explicitly before a delivery row or job exists.
- **D-06:** Envelope/body preflight failures reuse `%Mailglass.SendError{type: :preflight_rejected}` with bounded, actionable, non-PII context. Do not introduce a separate public error family for these cases.

### Rendering and published configuration
- **D-07:** `Mailglass.Renderer` is the single implementation point for body precedence and renderer configuration so direct render, synchronous send, async preparation, and preview observe the same semantics.
- **D-08:** Preserve adopter-authored plaintext. Text-only messages remain non-empty and sendable without manufacturing an HTML body.
- **D-09:** Generate automatic plaintext only for HTML-only messages when `renderer.plaintext` is enabled; disabling it leaves HTML-only mail without generated plaintext and never deletes explicit plaintext.
- **D-10:** Honor `renderer.css_inliner`: `:premailex` uses the current inliner and `:none` skips CSS inlining while retaining the rest of the render pipeline.

### the agent's Discretion
- Exact internal validator/helper module boundaries, provided all outbound entry points share the same pure pre-side-effect gate.
- Exact non-PII context keys/messages beneath the locked `%Mailglass.SendError{type: :preflight_rejected}` public contract.
- Test-file decomposition and implementation sequencing within the locked behavior above.

### Deferred Ideas (OUT OF SCOPE)

- Complete private outbound-envelope fidelity and atomic durable enqueue — Phase 150.
- Sync/async wire equivalence, structured dispatch outcomes, retry honesty, and private-payload lifecycle — Phase 151.
- Recipient fan-out — future requirement RCPT-01, explicitly outside v2.4.
- Native HEEx assigns, new providers/integrations, sent-message snapshots, and admin visual changes remain milestone-level deferrals.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FIRST-01 | Default SingleTenant sends sync and durable async as `"default"` without a process stamp. | Normalize the effective tenant in shared preflight before all per-tenant work; cover both public paths. |
| FIRST-02 | Custom tenancy fails closed for absent, invalid, or unrestorable context. | Preserve an explicit process-stamp check for every non-`SingleTenant` resolver; worker restoration remains a negative-contract test. |
| FIRST-03 | Exactly one recipient across `to`, `cc`, and `bcc`; all other shapes typed-error. | Aggregate the three native Swoosh recipient lists in one pure validator. |
| FIRST-04 | Recipient rejection precedes all rendering and side effects. | Put the shared gate before tracking, suppression, rate limiter, renderer, persistence, enqueue, and adapter routing. |
| FIRST-05 | Preserve authored plaintext; text-only sends; generate only when configured. | Rework `Renderer.render/2` as a body-shape-aware pipeline that does not overwrite explicit text. |
| FIRST-06 | Renderer switches affect direct, sync, async, and preview equally. | Read validated renderer config in `Mailglass.Renderer`; retain every caller's existing `Renderer.render/1` convergence. |
| FIRST-07 | Invalid body/envelope shapes typed-error before delivery/job creation; never drop data. | Validator returns the existing bounded `SendError :preflight_rejected`; assert zero database rows/jobs/fake deliveries. |
</phase_requirements>

## Summary

Phase 149 is a convergence-and-ordering change, not a new transport or persistence design. `Mailglass.Outbound` currently runs `Tenancy.assert_stamped!/0` at the start of sync, async, and batch paths, which rejects an unstamped default resolver despite `Tenancy.current/0` already producing `"default"` for `SingleTenant`. It also allows the renderer to run before recipient cardinality is checked. [VERIFIED: codebase grep]

`Mailglass.Renderer.render/2` is already the correct single rendering seam for direct render, both outbound modes, and admin preview. Today it renders `html_body`, always derives plaintext, always calls `Premailex`, and replaces `text_body`; this contradicts the published `renderer.plaintext` / `renderer.css_inliner` schema and the locked authored-text contract. [VERIFIED: codebase grep]

**Primary recommendation:** Introduce one pure outbound preflight that first normalizes/validates tenancy and then validates the complete Swoosh envelope and body shape; make `Renderer` body-shape-aware and config-driven, while keeping all existing side-effecting work after those gates. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Default-tenant normalization and custom-tenancy failure | API / Backend | Database / Storage | The process-local tenancy resolver is evaluated before outbound work and determines the tenant persisted later. [VERIFIED: codebase grep] |
| Envelope cardinality and body-shape rejection | API / Backend | — | This is pure business validation over `%Swoosh.Email{}` and must finish before side effects. [VERIFIED: codebase grep] |
| HTML/HEEx render, plaintext precedence, and CSS inlining | API / Backend | Frontend Server (preview consumer) | `Mailglass.Renderer` is a pure core pipeline; preview calls it rather than owning a rendering fork. [VERIFIED: codebase grep] |
| Sync delivery and async enqueue | API / Backend | Database / Storage | Outbound persists deliveries/events and delegates provider or async dispatch after preflight. [VERIFIED: codebase grep] |
| Preview display parity | Frontend Server (SSR/LiveView) | API / Backend | The LiveView displays output from the core renderer and does not dispatch. [VERIFIED: codebase grep] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Existing `mailglass` core modules | repository source | Own the stable send, tenancy, typed-error, and renderer contracts. | The phase changes existing seams; it must not add an alternate public pipeline. [VERIFIED: codebase grep] |
| `swoosh` | 1.26.3 locked; 1.27.0 published 2026-07-29 | Native `%Swoosh.Email{}` envelope/body representation. | Swoosh publicly models `to`, `cc`, `bcc`, `html_body`, and `text_body` separately; aggregate its three envelope lists. [CITED: https://hexdocs.pm/swoosh/Swoosh.Email.html] |
| `premailex` | 1.0.0 locked | Current HTML CSS inliner. | It is the already-installed implementation selected by `renderer.css_inliner: :premailex`. [VERIFIED: codebase grep] |
| `floki` | 0.38.4 locked | Existing plaintext extraction parse tree. | Retain it for the HTML-only generation branch only. [VERIFIED: codebase grep] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Phoenix | 1.8.9 locked | HEEx function component rendering. | Only when `html_body` is the supported 1-arity component shape. [VERIFIED: codebase grep] |
| Phoenix LiveView | 1.1.32 locked | Admin preview consumer. | Regression-test renderer parity; do not add preview rendering logic. [VERIFIED: codebase grep] |
| Oban | existing optional dependency | Durable async queue path. | Test preflight before `Ecto.Multi` job insertion; private-envelope and atomic-enqueue changes stay in Phase 150. [VERIFIED: codebase grep] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| One pure shared preflight | Per-entry-point validation | Duplicates ordering rules and risks a sync/async/batch divergence. [VERIFIED: codebase grep] |
| Renderer-owned body precedence | Outbound/preview-specific transformations | Breaks the established shared-renderer guarantee and makes preview unrepresentative. [VERIFIED: codebase grep] |
| Existing `SendError :preflight_rejected` | New body/envelope error struct | Contradicts the locked public error contract and stable closed SendError type set. [VERIFIED: codebase grep] |

**Installation:** No package installation is needed for this phase. [VERIFIED: codebase grep]

## Architecture Patterns

### System Architecture Diagram

```text
%Message{} / %Swoosh.Email{}
          |
          v
  [shared pure outbound preflight]
  tenancy -> effective tenant OR typed tenancy error
  envelope(to+cc+bcc) + body shape -> typed SendError OR message
          |
          +-- error --> return; no render/rate-limit/DB/job/provider work
          |
          v
  Tracking guard -> suppression -> rate limiter -> stream policy
          |
          v
  Mailglass.Renderer
  explicit text preserved | HTML-only optional plaintext | optional CSS inline
          |
          +--> direct render --> caller / preview LiveView
          |
          +--> sync --> persist queued --> adapter dispatch --> persist outcome
          |
          +--> async --> route -> persist/enqueue (Phase 150 ownership unchanged)
```

### Recommended Project Structure

```text
lib/mailglass/
├── outbound.ex                 # calls one pure preflight before all side effects
├── outbound/preflight.ex       # preferred internal home for tenancy/envelope/body helpers
├── renderer.ex                 # only body precedence/config/inlining implementation
└── tenancy.ex                  # resolver-aware effective-tenant helper, if it keeps public contract clearer

test/mailglass/
├── outbound/preflight_test.exs # pure and no-side-effect matrix
├── outbound/deliver_later_test.exs
├── renderer_test.exs
└── tenancy_test.exs
```

### Pattern 1: Normalize then validate before all effectful stages

**What:** Have one internal preflight return `{:ok, normalized_message}` or `{:error, %Mailglass.SendError{type: :preflight_rejected}}` before tracking, suppression, rate limiting, rendering, persistence, enqueue, or dispatch. [VERIFIED: codebase grep]

**When to use:** Sync `send/deliver`, `deliver_later`, and each batch item; ensure a raw `%Swoosh.Email{}` becomes a Message with the normalized tenant before it enters that common path. [VERIFIED: codebase grep]

**Example:**

```elixir
# Source: project-established with-short-circuit pattern in lib/mailglass/outbound.ex
with {:ok, message} <- Preflight.run(message),
     :ok <- Tracking.Guard.assert_safe!(message),
     :ok <- Suppression.check_before_send(message),
     :ok <- RateLimiter.check(message),
     :ok <- Stream.policy_check(message),
     {:ok, rendered} <- Renderer.render(message) do
  # The first persistence or enqueue operation belongs here.
end
```

### Pattern 2: Preserve explicit text; render HTML only when present

**What:** Treat a non-empty explicit `text_body` as authoritative. Render an HTML body only if it is a supported binary or 1-arity HEEx function; derive text only when HTML exists, text is absent/empty, and `renderer.plaintext` is enabled. Run Premailex only for HTML when `renderer.css_inliner == :premailex`. [VERIFIED: codebase grep]

**When to use:** Only inside `Mailglass.Renderer`, so direct render, synchronous send, asynchronous preparation, and preview retain identical output. [VERIFIED: codebase grep]

### Anti-Patterns to Avoid

- **Checking only `to`:** Swoosh has independent `to`, `cc`, and `bcc` fields, so this silently permits a multi-recipient envelope. [CITED: https://hexdocs.pm/swoosh/Swoosh.Email.html]
- **Calling `Tenancy.assert_stamped!/0` before resolving `SingleTenant`:** It rejects the configured default despite `current/0` already defining the implicit `"default"` semantics. [VERIFIED: codebase grep]
- **Rendering before cardinality/body validation:** It permits rejected input to consume renderer work and obscures the required no-side-effect ordering. [VERIFIED: codebase grep]
- **Always assigning generated text:** It destroys adopter-authored text and makes text-only Messages empty/invalid. [VERIFIED: codebase grep]
- **Implementing `:none` as a second renderer:** Skip only the inlining stage; retain HEEx rendering, text handling, and `data-mg-*` stripping. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Email address construction/normalization | New recipient representation or parser | Native `Swoosh.Email` lists and setters | The public Swoosh contract already defines mailbox list fields and append/replace setter semantics. [CITED: https://hexdocs.pm/swoosh/Swoosh.Email.html] |
| CSS transformation | New CSS inliner | Existing `Premailex.to_inline_css/1` branch | The phase only needs configuration dispatch, not a new inlining engine. [VERIFIED: codebase grep] |
| HTML-to-text parser | A second text generator | Existing `Renderer.to_plaintext/1` / Floki walker | Existing handling includes mailglass plaintext strategy attributes and stripping behavior. [VERIFIED: codebase grep] |
| Public error family | A new validation exception | `%Mailglass.SendError{type: :preflight_rejected}` | The stable error type set and user decision require this one public failure surface. [VERIFIED: codebase grep] |

**Key insight:** The hard work here is contract convergence and effect ordering, not new infrastructure. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Default tenant is resolved but never applied to the Message

**What goes wrong:** A single-tenant Message created without an explicit `tenant_id` can pass a resolver check but still reach suppression/rate-limit/persistence with `nil`. [VERIFIED: codebase grep]

**How to avoid:** Preflight must return the normalized Message carrying `tenant_id: "default"`, not merely return `:ok`; custom resolvers must still require a real valid stamp. [VERIFIED: codebase grep]

**Warning signs:** A successful default send creates a delivery/event with nil tenant, or custom-tenancy tests receive a default tenant. [VERIFIED: codebase grep]

### Pitfall 2: Body validation rejects or transforms valid text-only Messages

**What goes wrong:** Existing `Renderer.render/2` turns `html_body: nil` into `""`, derives `""` text, and overwrites authored plaintext. [VERIFIED: codebase grep]

**How to avoid:** Validate non-empty HTML and/or text before renderer effects; only derive plaintext for the HTML-only branch under the enabled setting. [VERIFIED: codebase grep]

**Warning signs:** `text_body("hello")` becomes empty after `Renderer.render/1`, or HTML-only output changes with `plaintext: false` by gaining text. [VERIFIED: codebase grep]

### Pitfall 3: Negative tests prove only database absence

**What goes wrong:** A rejected message can still consume a rate-limit token, call the renderer, or call the fake adapter without creating a row. [VERIFIED: codebase grep]

**How to avoid:** Instrument/replace seams in focused tests: assert no render telemetry, no rate-limit consumption, no delivery/event rows, no Oban job, and no Fake delivery for malformed input. [VERIFIED: codebase grep]

**Warning signs:** Tests only query `Delivery` or only test sync. [VERIFIED: codebase grep]

### Pitfall 4: Phase-150 durable-envelope work leaks into Phase 149

**What goes wrong:** Repairing async preflight by redesigning metadata/job arguments expands into private payload fidelity and enqueue atomicity. [VERIFIED: codebase grep]

**How to avoid:** Limit async changes to validating before existing insertion/enqueue mechanics. Keep private envelope, atomic durable enqueue, and wire equivalence deferred. [VERIFIED: codebase grep]

## Code Examples

### Recipient aggregation with bounded context

```elixir
# Source: Swoosh Email field contract + Phase 149 locked decision D-04
defp validate_recipient_count(%Swoosh.Email{} = email) do
  recipients = List.wrap(email.to) ++ List.wrap(email.cc) ++ List.wrap(email.bcc)

  case length(recipients) do
    1 -> :ok
    0 -> {:error, Mailglass.SendError.new(:preflight_rejected, context: %{reason_class: :missing_recipient})}
    count -> {:error, Mailglass.SendError.new(:preflight_rejected, context: %{reason_class: :recipient_count_invalid, recipient_count: count})}
  end
end
```

Do not put addresses, subject text, HTML, plaintext, or `inspect(email)` in the context or telemetry. [VERIFIED: codebase grep]

### Renderer body precedence branch

```elixir
# Source: Phase 149 locked decisions D-07 through D-10
case {supported_html?(email.html_body), non_empty?(email.text_body), renderer_config()} do
  {{:ok, html}, true, config} ->
    {:ok, put_rendered_html_preserving_text(message, html, config)}

  {{:ok, html}, false, %{plaintext: true} = config} ->
    {:ok, put_rendered_html_and_generated_text(message, html, config)}

  {{:ok, html}, false, %{plaintext: false} = config} ->
    {:ok, put_rendered_html(message, html, config)}

  {:absent, true, _config} ->
    {:ok, message}
end
```

The exact helper names are discretionary; the branch behavior is locked. [VERIFIED: codebase grep]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Separate implicit assumptions in each outbound entry point | One shared pure preflight followed by shared renderer | Phase 149 plan | Ensures consistent rejection and no-side-effect ordering for sync, async, and batch. [VERIFIED: codebase grep] |
| Unconditional renderer plaintext/inlining | Published configuration controls only the relevant rendering stages | Phase 149 plan | Makes docs, direct rendering, sending, and preview agree. [VERIFIED: codebase grep] |

**Deprecated/outdated:** Treating `Tenancy.assert_stamped!/0` as the first universal preflight stage is incompatible with the locked default `SingleTenant` contract. [VERIFIED: codebase grep]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Mailglass.OptionalDeps.Oban`'s existing test harness can assert no job insertion without adding new infrastructure. | Validation Architecture | Test implementation may need a focused helper or a different existing Oban assertion seam. [ASSUMED] |

## Resolved Questions

1. **Private helper boundary: use internal `Mailglass.Outbound.Preflight`.**
   - Decision: Extract `Mailglass.Outbound.Preflight` under the existing `Mailglass.Outbound` namespace. It is contained by the `Mailglass.Outbound` Boundary, does not declare a sibling Boundary, and is not added to `Mailglass.Outbound`'s `exports:` list, so it remains internal rather than becoming adopter-facing API. [VERIFIED: `lib/mailglass/outbound.ex`; `test/mailglass/boundary_test.exs`]
   - Dependency proof: `Mailglass.Outbound` already declares `deps: [Mailglass]`; the root `Mailglass` Boundary exports the only modules the pure helper needs (`Mailglass.Message`, `Mailglass.Tenancy`, `Mailglass.TenancyError`, and `Mailglass.SendError`). The helper must not reference Renderer, Repo, Oban, RateLimiter, Suppression, Tracking, or adapters. [VERIFIED: `lib/mailglass.ex`; `lib/mailglass/outbound.ex`]
   - Verification: compile with the Boundary compiler enabled via `mix compile --warnings-as-errors`, then run `mix test test/mailglass/boundary_test.exs --warnings-as-errors` to pin Outbound's root-only dependency and the helper's non-exported status. This resolves the extraction choice without changing public Boundary exports. [VERIFIED: `mix.exs`; `test/mailglass/boundary_test.exs`]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir/Mix | Compile and ExUnit | ✓ | Elixir/Mix 1.19.5, OTP 28 | — [VERIFIED: local environment] |
| PostgreSQL | Existing DataCase and async persistence assertions | ✓ | server accepts connections on `:5432`; `psql` 14.17 | — [VERIFIED: local environment] |
| Oban dependency | Existing durable async path tests | ✓ | project optional dependency; version from lockfile not independently probed | Existing Task.Supervisor path is not durable and cannot prove FIRST-01's durable branch. [VERIFIED: codebase grep] |
| Docker | Optional local service support | ✓ | 29.5.2 | Direct local Postgres is already running. [VERIFIED: local environment] |

**Missing dependencies with no fallback:** None. [VERIFIED: local environment]

**Missing dependencies with fallback:** None. [VERIFIED: local environment]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit under Mix 1.19.5 [VERIFIED: local environment] |
| Config file | `test/test_helper.exs` and `config/test.exs` [VERIFIED: codebase grep] |
| Quick run command | `mix test test/mailglass/outbound/preflight_test.exs test/mailglass/outbound/deliver_later_test.exs test/mailglass/renderer_test.exs test/mailglass/tenancy_test.exs --warnings-as-errors` [VERIFIED: codebase grep] |
| Full suite command | `mix test --warnings-as-errors` [VERIFIED: codebase grep] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FIRST-01 | Unstamped `SingleTenant` sync and durable async normalize to `"default"`; delivery/event/job carry the default tenant. | integration | `mix test test/mailglass/outbound/preflight_test.exs test/mailglass/outbound/deliver_later_test.exs --warnings-as-errors` | ✅ extend |
| FIRST-02 | Custom unstamped/invalid async worker context rejects without fallback. | unit + integration | `mix test test/mailglass/tenancy_test.exs test/mailglass/outbound/preflight_test.exs --warnings-as-errors` | ✅ extend |
| FIRST-03 | Zero and all `to`/`cc`/`bcc` multi-recipient combinations return typed bounded errors. | unit | `mix test test/mailglass/outbound/preflight_test.exs --warnings-as-errors` | ✅ extend |
| FIRST-04 | Invalid recipient never renders, limits, persists, queues, or dispatches. | integration | `mix test test/mailglass/outbound/preflight_test.exs test/mailglass/outbound/deliver_later_test.exs --warnings-as-errors` | ✅ extend |
| FIRST-05 | Explicit text survives; text-only sends; HTML-only generated text follows switch. | unit + integration | `mix test test/mailglass/renderer_test.exs test/mailglass/outbound/preflight_test.exs --warnings-as-errors` | ✅ extend |
| FIRST-06 | `plaintext` and `css_inliner` configuration parity across direct/sync/async/preview. | unit + integration + LiveView | `mix test test/mailglass/renderer_test.exs test/mailglass/outbound_test.exs mailglass_admin/test/mailglass_admin/preview_live_test.exs --warnings-as-errors` | ✅ extend |
| FIRST-07 | Unsupported body/envelope shapes produce `SendError :preflight_rejected` before row/job. | unit + integration | `mix test test/mailglass/outbound/preflight_test.exs test/mailglass/outbound/deliver_later_test.exs --warnings-as-errors` | ✅ extend |

### Sampling Rate

- **Per task commit:** Run the focused files affected by the task, with `--warnings-as-errors`. [VERIFIED: codebase grep]
- **Per wave merge:** Run the Phase 149 quick command. [VERIFIED: codebase grep]
- **Phase gate:** `mix test --warnings-as-errors` must be green before `$gsd-verify-work`. [VERIFIED: codebase grep]

### Wave 0 Gaps

- [ ] Extend `mailglass_admin/test/mailglass_admin/preview_live_test.exs` with a renderer-parity regression that changes each renderer setting in an isolated test. [VERIFIED: codebase grep]
- [ ] Add/extend an assertion seam for zero Oban jobs on preflight rejection if existing tests do not expose one. [ASSUMED]
- [ ] Add config-isolated renderer tests that restore `Application` state and relevant config cache after each case. [VERIFIED: codebase grep]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No authentication surface is changed. [VERIFIED: codebase grep] |
| V3 Session Management | no | No session/token surface is changed. [VERIFIED: codebase grep] |
| V4 Access Control | yes | Fail closed for custom tenancy; never substitute the default tenant. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | One pure body/envelope validator before every outbound side effect. [VERIFIED: codebase grep] |
| V6 Cryptography | no | No cryptographic mechanism is added or changed. [VERIFIED: codebase grep] |

### Known Threat Patterns for outbound preflight

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Custom tenant context missing or lost in a worker falls into another tenant | Elevation of Privilege | Require/restamp a valid custom tenant; only the configured `SingleTenant` resolver may normalize to `"default"`. [VERIFIED: codebase grep] |
| Recipient list causes unintended fan-out or address loss | Tampering | Count all native lists and reject every count other than one; do not choose a primary recipient before validation. [CITED: https://hexdocs.pm/swoosh/Swoosh.Email.html] |
| Invalid input consumes quotas or creates durable artifacts | Denial of Service | Place pure validation before renderer, rate limiter, DB writes, jobs, and provider calls. [VERIFIED: codebase grep] |
| PII leaks through public error context | Information Disclosure | Permit only reason classes/counts; exclude recipient addresses and message/body data. [VERIFIED: codebase grep] |

## Sources

### Primary (HIGH confidence)

- `lib/mailglass/outbound.ex` — current sync/async/batch ordering, route resolution, persistence boundaries, primary-recipient assumption. [VERIFIED: codebase grep]
- `lib/mailglass/renderer.ex` — existing pure renderer pipeline and current overwrite/unconditional-inliner behavior. [VERIFIED: codebase grep]
- `lib/mailglass/tenancy.ex` and `lib/mailglass/tenancy/single_tenant.ex` — resolver-specific default and strict stamped API distinction. [VERIFIED: codebase grep]
- `lib/mailglass/config.ex` — published renderer options and validation schema. [VERIFIED: codebase grep]
- `test/mailglass/outbound/preflight_test.exs`, `test/mailglass/outbound/deliver_later_test.exs`, `test/mailglass/renderer_test.exs`, `test/mailglass/tenancy_test.exs` — nearest test seams. [VERIFIED: codebase grep]
- `docs/api_stability.md` — stable typed-error inventory and closed SendError type set. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)

- [Swoosh.Email documentation](https://hexdocs.pm/swoosh/Swoosh.Email.html) — `to`, `cc`, `bcc`, HTML, and plaintext field/setter contract. [CITED: https://hexdocs.pm/swoosh/Swoosh.Email.html]
- [Phoenix components documentation](https://phoenix.hexdocs.pm/components.html) — HEEx function-component model. [CITED: https://phoenix.hexdocs.pm/components.html]

### Tertiary (LOW confidence)

- None. [VERIFIED: codebase grep]

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — all required libraries are already locked in the project; no installation decision is needed. [VERIFIED: codebase grep]
- Architecture: HIGH — all public entry points and their current convergence/separation seams are local source. [VERIFIED: codebase grep]
- Pitfalls: HIGH — each is directly demonstrated by current source ordering or field assignment. [VERIFIED: codebase grep]

**Research date:** 2026-08-02  
**Valid until:** 2026-09-01 (repository-local implementation research) [ASSUMED]
