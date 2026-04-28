<user_constraints>
## User Constraints (from CONTEXT.md)

*(No CONTEXT.md found. Proceeding with greenfield Phase 10 requirements.)*

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| STREAM-01 | Implement Mailglass.Stream module — closed atom set, per-mailable default resolution, Message.new_from_use/2 stamping | Requires `Message.put_stream/2` and explicit validation of the 3 allowed atoms. |
| STREAM-02 | Replace no-op seam at stream.ex:35 with real StreamPolicy stage | Returns `{:error, %Mailglass.StreamPolicyError{}}` to seamlessly pass through existing `with` statements. |
| STREAM-03 | Write Mailglass.Credo.StreamPolicyConsistent (LINT-13) | Modeled after `NoTrackingOnAuthStream`. Ast inspection for `stream: :bulk` and `tracking:` combos. |
| STREAM-04 | Update Feedback-ID format to include stream slot | Updates `Mailglass.Compliance` and `Mailglass.Config` schema. |
</phase_requirements>

# Phase 10: Stream Policy Implementation - Research

**Researched:** 2024-04-27
**Domain:** Elixir, Credo static analysis, Email Compliance (Feedback-ID)
**Confidence:** HIGH

## Summary

This phase replaces the v0.1 no-op stream seam with a strict runtime policy and a corresponding compile-time Credo check. It introduces the `Mailglass.StreamPolicyError` struct (fulfilling the roadmap's pseudo-code `%Mailglass.Error{...}`) and enforces stream rules for `:transactional`, `:operational`, and `:bulk` traffic. Finally, it extends `Mailglass.Compliance` to inject RFC 8058/Gmail-compatible `Feedback-ID` headers based on the message stream and tenant.

**Primary recommendation:** Implement `Mailglass.StreamPolicyError` as a new behaviour-compliant error struct, return `{:error, error}` from `Stream.policy_check/1` instead of natively `raise`-ing to preserve `deliver/2`'s tuple-return contract without altering call sites, and model the new Credo check directly on the AST-walking logic from `NoTrackingOnAuthStream`.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Stream Validation (Static) | Compile-time (Credo) | — | Catch misconfigured mailables early (`:bulk` without stream set, tracking on auth streams). |
| Stream Validation (Runtime) | Preflight Pipeline (`Stream`) | — | Prevents dynamic/runtime bypass of stream rules before the adapter is invoked. |
| Stream Assignment | Mailable (`use` macro) | Builder (`Message`) | Defaults set via `new_from_use/2`; runtime overrides via `Message.put_stream/2`. |
| Feedback-ID Injection | Compliance Stage | Config | Interpolates `{sender_id}:{mailable}:{tenant_id}:{stream}` just before dispatch. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `credo` | 1.7+ | Static Analysis | Mailglass already uses custom Credo checks (LINT-01..12) via `Credo.Check`. |

## Architecture Patterns

### Error Struct Design

The roadmap states: "raises `%Mailglass.Error{type: :stream_policy_violated, detail: %{rule: atom, suggestion: String.t}}`". Because `Mailglass.Error` is a behaviour, not a struct, we must create a new module `Mailglass.StreamPolicyError`.

```elixir
defmodule Mailglass.StreamPolicyError do
  @behaviour Mailglass.Error
  @derive {Jason.Encoder, only: [:type, :message, :context, :detail]}
  defexception [:type, :message, :cause, :context, :detail]
  
  @types [:stream_policy_violated]
  def __types__, do: @types
  def type(%{type: t}), do: t
  def retryable?(_), do: false
  # ...
end
```

### Runtime Check Seam

Currently `Mailglass.Outbound` has: `with :ok <- Stream.policy_check(msg)`. 
To require *zero modification* to the call site while adhering to the `{:ok, _} | {:error, _}` contract of `deliver/2`, `policy_check/1` must return the error tuple, NOT `raise` it directly.

```elixir
def policy_check(%Message{stream: :bulk, mailable_function: nil} = _msg) do
  # ... emit telemetry stop ...
  {:error, Mailglass.StreamPolicyError.new(:stream_policy_violated, 
    detail: %{rule: :bulk_requires_mailable, suggestion: "..."})}
end
```

### Credo AST Walking

Model `Mailglass.Credo.StreamPolicyConsistent` heavily on `Mailglass.Credo.NoTrackingOnAuthStream`. Use `Macro.prewalk/3` to extract `@mailglass_opts` or `use Mailglass.Mailable, opts` to detect `stream: :bulk` without a stream set, or `:transactional` with `tracking: [opens: true]`.

### Feedback-ID Configuration

Add `feedback_id` (or `sender_id`) to the `Mailglass.Config` schema:
```elixir
feedback_id: [
  type: {:or, [:string, nil]},
  default: nil,
  doc: "Sender ID prefix for Feedback-ID headers. When configured, enables automatic Feedback-ID injection."
]
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| AST Inspection | Custom parser | `Credo.Check` and `Macro.traverse` | The existing Credo checks in `credo_checks/` already solve the edge cases of Elixir AST matching for mailables. |
| Header Injection | Direct `Swoosh.Email.header` calls | `Mailglass.Compliance` | Keeps RFC logic centralized and ensures existing headers are not overwritten. |

## Common Pitfalls

### Pitfall 1: Literal Interpretation of "raises"
**What goes wrong:** The roadmap says "raises `%Mailglass.Error{...}`". If you use `raise` inside `policy_check/1`, the `with` block in `Outbound.send/2` will bubble the exception, crashing the process for `deliver_later/2` instead of returning `{:error, struct}`.
**How to avoid:** Return `{:error, %Mailglass.StreamPolicyError{...}}`. The roadmap's next clause says "existing call sites require zero modification", which proves it expects the `with` macro to fall through gracefully.

### Pitfall 2: Single-Tenant Feedback-ID
**What goes wrong:** The Feedback-ID format `{sender_id}:{mailable}:{tenant_id}:{stream}` will look like `acme:UserMailer::transactional` if `tenant_id` is `nil`.
**How to avoid:** Detect `nil` tenant IDs and replace them with a default string like `"default"` or `"global"` to prevent empty slots in the colon-separated string.

### Pitfall 3: Dynamic Stream Variables in Credo
**What goes wrong:** The Credo check assumes `stream: :bulk` is an atom, but an adopter writes `stream: @my_stream`.
**How to avoid:** Only flag violations when the AST literal is explicitly `:bulk` or `:transactional`. Fall back to runtime enforcement for dynamically-evaluated attributes.

## Code Examples

### Message Stream Setter

```elixir
# In lib/mailglass/message.ex
@doc "Overrides the message stream. Accepts only :transactional, :operational, or :bulk."
def put_stream(%__MODULE__{} = msg, stream) when stream in [:transactional, :operational, :bulk] do
  %{msg | stream: stream}
end
```

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `detail:` mapping | Error Struct Design | If `Mailglass.Error` strictly forbids `:detail` as a key, JSON encoding could break. Mitigation: add `:detail` to `@derive {Jason.Encoder}` in the new error struct. |
| A2 | Feedback-ID Config | Architecture | Assuming the config key should be `feedback_id` rather than `sender_id`. Planner should define it exactly as `feedback_id` per the requirement text. |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `mix.exs` / `test_helper.exs` |
| Quick run command | `mix test --stale` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| STREAM-01 | Stamp stream, accept only 3 atoms | unit | `mix test test/mailglass/message_test.exs` | ✅ Wave 0 |
| STREAM-02 | Runtime stream policy check | unit | `mix test test/mailglass/stream_test.exs` | ✅ Wave 0 |
| STREAM-03 | Credo check for stream rules | unit | `mix test test/mailglass/credo/stream_policy_consistent_test.exs` | ❌ Wave 0 |
| STREAM-04 | Feedback-ID injection | unit | `mix test test/mailglass/compliance_test.exs` | ✅ Wave 0 |

### Wave 0 Gaps
- [ ] `test/mailglass/credo/stream_policy_consistent_test.exs` — covers STREAM-03
- [ ] `lib/mailglass/errors/stream_policy_error.ex` — covers STREAM-02
- [ ] Property test in `stream_test.exs` using `StreamData` (per 10-05 requirement)

## Security Domain

> Omitted as this phase involves no cryptographic, authentication, or external input validation changes beyond standard AST linting.

## Sources

### Primary (HIGH confidence)
- `.planning/ROADMAP.md` - Phase 10 requirements and success criteria.
- `docs/api_stability.md` - Error structure behaviour and `Mailglass.Error` definitions.
- `lib/mailglass/outbound.ex` - Inspected `with` statement to deduce `policy_check` return semantics.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Core Elixir/Credo standard.
- Architecture: HIGH - Fully aligns with existing Preflight/Outbound patterns.
- Pitfalls: HIGH - Elixir `with` macro semantics are deterministic.

**Research date:** 2024-04-27
**Valid until:** Next major version bump (v0.5)
