# Phase 58: Verify-First Webhook + Operator Path - Research

**Researched:** 2026-05-27  
**Domain:** Elixir/Phoenix reference-host trust runner, signed inbound webhook verification, operator diagnosis evidence  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
## Implementation Decisions

### Runner Contract
- **D-01:** Keep `mix verify.reference_host.journey` as the only supported trust-runner entrypoint for Phase 58.
- **D-02:** Extend the existing `trust_runner.v1` checkpoint semantics without renaming the Phase 57 stage keys: `install`, `preview`, `send`, `webhook_ingest`, and `operator_troubleshooting`.
- **D-03:** Treat Phase 58 as a semantic deepening of the existing `webhook_ingest` and `operator_troubleshooting` stages, not as a replacement checkpoint schema.

### Webhook Verification Path
- **D-04:** Execute webhook proof through the maintained reference host's public inbound route into `MailglassInbound.Ingress.Plug`.
- **D-05:** Use one existing reference-host provider route, Postmark or SendGrid, with real provider verification semantics. Do not call provider modules directly and do not rely on lower-level test drivers as the primary trust proof.
- **D-06:** Preserve the Phase 52 public-seam boundary: the reference host may use public route wiring and public ingress plugs only, with no copied provider internals or internal-module coupling.

### Negative Signature Assertion
- **D-07:** Include a deterministic failing-signature assertion that proves the real ingress path returns `401` with a closed rejected/signature reason.
- **D-08:** The negative assertion must prove verify-first ordering by showing forged input does not proceed into tenant resolution, persistence, or mailbox execution.

### Operator Diagnosis Scenario
- **D-09:** Use the existing deterministic `:no_match` routing diagnosis surface as the non-happy-path operator scenario.
- **D-10:** Checkpoint operator evidence under the existing `operator_troubleshooting` stage instead of inventing a separate operator evidence schema.
- **D-11:** Operator evidence should align with existing routing-trace / doctor-style evidence shapes: deterministic finding or trace data, closed status language, observed facts, remediation, and machine-readable fields where available.

### Claude's Discretion
- Exact provider choice for the representative signed route, as long as it uses a real reference-host public route and real provider verification.
- Exact checkpoint field additions, provided `trust_runner.v1`, stage names, deterministic ordering, and existing validator compatibility are preserved or intentionally extended.
- Exact test file split and helper names for positive/negative route proof and operator diagnosis proof.

### Deferred Ideas (OUT OF SCOPE)
## Deferred Ideas

- Required repo-head and clean-baseline CI trust lanes are Phase 59 scope.
- Published-version trust proof, post-publish smoke reliability closure, and release checklist gating are Phase 60 scope.
- Docs boundary/contract positioning is Phase 61 scope.
- Provider-matrix broadening, `gen_smtp` transport expansion, and ecosystem integrations remain out of scope for v1.3.
</user_constraints>

## Summary

Phase 58 should deepen the existing Phase 57 trust-runner pipeline rather than add a new command or schema. The canonical command is already `mix verify.reference_host.journey`, which delegates to `mailglass.trust.run`; the runner already orders `install -> preview -> send -> webhook_ingest -> operator_troubleshooting` and writes a deterministic JSON checkpoint. [VERIFIED: mix.exs, lib/mix/tasks/mailglass.trust.run.ex:30-63, lib/mix/tasks/mailglass.trust.run.ex:95-137]

The recommended representative webhook path is Postmark through the reference host route `POST /inbound/:tenant_id/postmark`. This satisfies the locked public-seam requirement because the route enters `MailglassInbound.Ingress.Plug` and the plug invokes the real Postmark verifier before tenant resolution, normalization, persistence, and execution. [VERIFIED: reference/host_app/lib/mailglass_reference_host_web/router.ex:19-22, mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex:68-132, mailglass_inbound/lib/mailglass_inbound/ingress/providers/postmark.ex]

The operator path should use the existing `:no_match` routing-trace surface, not the doctor CLI as the primary proof. `InboundLive` renders `RoutingTrace` only for `:no_match`, gets trace data through the optional inbound gateway's `explain_routes/2`, and existing tests already pin deterministic route-card evidence and copy. [VERIFIED: mailglass_admin/lib/mailglass_admin/inbound_live.ex:316-323, mailglass_admin/lib/mailglass_admin/inbound_live.ex:357-371, mailglass_admin/test/mailglass_admin/inbound_live_test.exs:338-407]

**Primary recommendation:** Use a Postmark route-level Phoenix/Plug proof for `webhook_ingest`, add closed negative-signature evidence to the same stage, and checkpoint a deterministic `:no_match` routing-trace diagnosis under `operator_troubleshooting` while preserving `trust_runner.v1` and the five existing stage names. [VERIFIED: 58-CONTEXT.md, codebase inspection]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Trust-runner orchestration | Mix task / CLI | Reference host | `Mix.Tasks.Mailglass.Trust.Run` owns stage execution and checkpoint writing; the reference host supplies the public route surface. [VERIFIED: lib/mix/tasks/mailglass.trust.run.ex:34-63] |
| Signed webhook verification | Inbound API / Plug | Provider module | The public route dispatches to `MailglassInbound.Ingress.Plug`; the plug builds the request and calls provider `verify!` before tenant/persistence work. [VERIFIED: reference/host_app/lib/mailglass_reference_host_web/router.ex:19-22, mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex:68-132] |
| Negative signature proof | Inbound API / Plug | Test fixtures | Signature errors map to `401` JSON with `status: rejected` and closed reason; proof must assert no tenant/persistence/execution side effects. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex:123-132, mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs] |
| Operator diagnosis | Admin/operator surface | Inbound routing gateway | `InboundLive` requests route explanations only for `:no_match`; the inbound gateway owns route reflection. [VERIFIED: mailglass_admin/lib/mailglass_admin/inbound_live.ex:357-371] |
| Checkpoint evidence | Core reference-host support | Shell validator | `TrustCheckpoint.encode/1` owns schema, ordering, and hash; `scripts/check_trust_runner_checkpoint.sh` validates the artifact contract. [VERIFIED: lib/mailglass/reference_host/trust_checkpoint.ex:24-64, scripts/check_trust_runner_checkpoint.sh] |

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| JOUR-03 | Webhook proof executes the real verify-first route path with signed payloads plus one failing-signature assertion. [VERIFIED: .planning/REQUIREMENTS.md] | Reference-host Postmark route exists; plug verifies before tenant resolution; Postmark verifier raises closed `Mailglass.SignatureError` reasons. [VERIFIED: reference/host_app/lib/mailglass_reference_host_web/router.ex:19-22, mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex:68-132, mailglass_inbound/lib/mailglass_inbound/ingress/providers/postmark.ex] |
| JOUR-04 | Operator troubleshooting includes one scripted non-happy-path flow with deterministic evidence and diagnosis. [VERIFIED: .planning/REQUIREMENTS.md] | Existing `:no_match` operator route-trace UI and tests provide deterministic evidence language, route cards, matcher kinds, and masked actual recipient behavior. [VERIFIED: mailglass_admin/lib/mailglass_admin/inbound_live.ex:316-371, mailglass_admin/test/mailglass_admin/inbound_live_test.exs:338-407] |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Use Elixir/Phoenix conventions and no Node toolchain for this phase. [VERIFIED: CLAUDE.md]
- Preserve sibling-package boundaries: `mailglass`, `mailglass_admin`, and `mailglass_inbound` are separate packages. [VERIFIED: CLAUDE.md]
- Use pluggable behaviours and public seams rather than internal coupling. [VERIFIED: CLAUDE.md]
- Treat structured errors as public contracts; pattern-match structs or closed atoms, never message strings. [VERIFIED: CLAUDE.md]
- Never put PII in telemetry metadata, responses, or operator default surfaces. [VERIFIED: CLAUDE.md]
- Keep optional dependencies behind `Mailglass.OptionalDeps.*` gateways and preserve `mix compile --no-optional-deps --warnings-as-errors`. [VERIFIED: CLAUDE.md]
- Do not recover from webhook signature failures; `Mailglass.SignatureError` is fail-closed. [VERIFIED: CLAUDE.md]
- Do not call provider internals from the reference host; Phase 52 public-seam boundary forbids copied provider internals and internal-module coupling. [VERIFIED: 58-CONTEXT.md, test/reference_host/public_seams_contract_test.exs]
- Use brand voice that is clear, exact, confident, warm, modern, and technical. [VERIFIED: CLAUDE.md]

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir / Mix | 1.19.5 | Mix task runner, ExUnit tests, application config | Current local runtime for this repo; `mailglass.trust.run` is a Mix task. [VERIFIED: `elixir --version`, `mix --version`, lib/mix/tasks/mailglass.trust.run.ex] |
| Erlang/OTP | 28 / erts-16.3 | Runtime and `:crypto` hashing | `TrustCheckpoint` hashes ordered checkpoint rows with `:crypto.hash(:sha256, ...)`. [VERIFIED: `elixir --version`, lib/mailglass/reference_host/trust_checkpoint.ex:58-64] |
| Phoenix | 1.8.7 | Reference-host routing and admin LiveView route mounting | Reference host router uses `Phoenix.Router`; lockfile pins Phoenix 1.8.7. [VERIFIED: reference/host_app/lib/mailglass_reference_host_web/router.ex:1-23, mix.lock] |
| Plug | 1.19.2 | Public inbound ingress plug and request/response testing | `MailglassInbound.Ingress.Plug` implements `@behaviour Plug`; lockfile pins Plug 1.19.2. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex:1-66, mix.lock] |
| Phoenix LiveView | 1.1.30 | Existing admin operator surface | `MailglassAdmin.InboundLive` uses `Phoenix.LiveView`; lockfile pins LiveView 1.1.30. [VERIFIED: mailglass_admin/lib/mailglass_admin/inbound_live.ex, mix.lock] |
| Jason | 1.4.5 | JSON checkpoint and ingress response encoding | Runner writes JSON with `Jason.encode_to_iodata!`; plug returns JSON bodies with `Jason.encode!`. [VERIFIED: lib/mix/tasks/mailglass.trust.run.ex:183-190, mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex:760, mix.lock] |
| Ecto / Postgrex | Ecto 3.14.0 / Postgrex 0.22.2 | Existing inbound persistence and operator fixtures | Operator and inbound tests use `Ecto.Adapters.SQL.Sandbox`; lockfile pins Ecto/Postgrex. [VERIFIED: mailglass_inbound/test/mailglass_inbound/test/ingress_test.exs, mix.lock] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Boundary | 0.10.4 | Compile-time architectural boundary checks in core | Keep if editing core trust-runner modules; the trust task uses `Boundary`. [VERIFIED: lib/mix/tasks/mailglass.trust.run.ex:1-2, mix.lock] |
| Mox | 1.2.0 | Test doubles in existing test stack | Use only if a new behaviour-backed test double is needed; current phase can likely use simple modules/process dictionary helpers as existing plug tests do. [VERIFIED: mix.lock, mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs] |
| StreamData | 1.3.0 | Property tests in existing stack | Not needed for Phase 58 deterministic proof; keep proof examples fixed and repeatable. [VERIFIED: mix.lock, phase success criteria] |
| Python 3 | 3.14.4 | Shell checkpoint validator implementation | `scripts/check_trust_runner_checkpoint.sh` runs an embedded Python JSON/hash validator. [VERIFIED: `python3 --version`, scripts/check_trust_runner_checkpoint.sh] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Postmark representative route | SendGrid representative route | SendGrid is valid, but requires multipart/raw MIME request shaping; Postmark JSON + Basic Auth is simpler while still exercising real provider verification and the public route. [VERIFIED: reference/host_app/lib/mailglass_reference_host_web/router.ex:19-22, mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex:373-396, provider modules] |
| Route-level Phoenix/Plug proof | Direct provider module calls | Direct calls violate locked D-05/D-06 because the primary proof must enter through reference-host public route wiring. [VERIFIED: 58-CONTEXT.md] |
| Operator doctor CLI proof as primary JOUR-04 evidence | Admin `:no_match` routing trace | Doctor remains useful supporting evidence, but D-09 locks the deterministic `:no_match` routing diagnosis surface; `InboundLive` already displays route-trace evidence for `:no_match`. [VERIFIED: 58-CONTEXT.md, mailglass_admin/lib/mailglass_admin/inbound_live.ex:357-371] |

**Installation:**
```bash
mix deps.get
```

**Version verification:** Versions above were verified from `mix.lock` and local CLI output in this session; no npm packages apply because this phase uses the existing Elixir/Phoenix stack. [VERIFIED: mix.lock, `elixir --version`, `mix --version`]

## Architecture Patterns

### System Architecture Diagram

```text
mix verify.reference_host.journey
  -> Mix.Tasks.Mailglass.Trust.Run
    -> install / preview / send checks
    -> webhook_ingest stage
      -> Phoenix reference-host router
        -> POST /inbound/:tenant_id/postmark
          -> MailglassInbound.Ingress.Plug
            -> build request from raw cached body + headers
            -> verify Postmark credentials first
              -> valid credentials: resolve tenant -> normalize -> persist -> dispatch -> 200 inserted/duplicate
              -> bad credentials: SignatureError -> 401 rejected, no tenant/persist/dispatch
    -> operator_troubleshooting stage
      -> seed/load deterministic :no_match record
        -> MailglassAdmin.InboundLive routing_trace_for/2
          -> Optional inbound gateway explain_routes/2
          -> deterministic route-card evidence
    -> TrustCheckpoint.encode/1
      -> schema_version trust_runner.v1
      -> five ordered stages
      -> deterministic checkpoint_sha256
      -> scripts/check_trust_runner_checkpoint.sh validation
```

### Recommended Project Structure

```text
lib/
├── mix/tasks/mailglass.trust.run.ex              # Stage orchestration and proof collection
└── mailglass/reference_host/trust_checkpoint.ex  # Deterministic checkpoint encoder

test/
├── reference_host/
│   ├── trust_runner_*_test.exs                   # Command/checkpoint contract tests
│   └── webhook_operator_*_test.exs               # Recommended new route/operator proof tests
└── support/reference_host/
    └── trust_runner_fixtures.ex                  # Stable fixture IDs and reusable proof data

scripts/
└── check_trust_runner_checkpoint.sh              # Artifact schema/order/hash validator
```

### Pattern 1: Additive Checkpoint Evidence

**What:** Preserve `schema_version: "trust_runner.v1"`, existing stage names, and deterministic sorting while adding bounded evidence fields to checkpoint rows only if the validator and tests are updated deliberately. [VERIFIED: lib/mailglass/reference_host/trust_checkpoint.ex:6-16, scripts/check_trust_runner_checkpoint.sh]

**When to use:** Use this for `webhook_ingest` and `operator_troubleshooting` evidence so Phase 59/60 can consume one stable artifact shape. [VERIFIED: 58-CONTEXT.md]

**Example:**
```elixir
# Source: lib/mailglass/reference_host/trust_checkpoint.ex
%{
  "stage_key" => "webhook_ingest",
  "status" => "completed",
  "fixture_id" => "trust.webhook_ingest.001",
  "evidence" => %{
    "provider" => "postmark",
    "route" => "/inbound/:tenant_id/postmark",
    "positive_status" => 200,
    "negative_status" => 401,
    "negative_reason" => "bad_credentials",
    "verified_before_tenant" => true
  }
}
```

### Pattern 2: Public Route Proof

**What:** Build a Plug/Phoenix connection against `MailglassReferenceHostWeb.Router` so the request enters through `/inbound/:tenant_id/postmark`, then assert the response and side-effect markers. [VERIFIED: reference/host_app/lib/mailglass_reference_host_web/router.ex:19-22, mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs]

**When to use:** Use for JOUR-03 tests and runner stage implementation; avoid direct provider-module calls as the primary proof. [VERIFIED: 58-CONTEXT.md]

**Example:**
```elixir
# Source: reference host route + existing plug test patterns
conn =
  Plug.Test.conn(:post, "/inbound/tenant-123/postmark", postmark_payload)
  |> Plug.Conn.put_req_header("content-type", "application/json")
  |> Plug.Conn.put_req_header("authorization", "Basic " <> Base.encode64("postmark:secret"))
  |> Plug.Conn.put_private(:raw_body, postmark_payload)

conn = MailglassReferenceHostWeb.Router.call(conn, [])
assert conn.status in [200, 401]
```

### Pattern 3: Verify-First Negative Assertion

**What:** Assert bad credentials return `401` with `status: "rejected"` and a closed reason, while tenant resolution, persistence, and mailbox execution markers remain absent. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex:123-132, mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs]

**When to use:** Required for JOUR-03 negative-signature proof. [VERIFIED: .planning/REQUIREMENTS.md]

**Example:**
```elixir
# Source: mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs
assert conn.status == 401
assert Jason.decode!(conn.resp_body)["status"] == "rejected"
assert Jason.decode!(conn.resp_body)["reason"] in ["bad_credentials", "missing_header", "malformed_header"]
refute Process.get(:mailglass_inbound_tenant_resolved)
refute Process.get(:mailglass_inbound_last_handoff)
refute Process.get(:mailglass_inbound_last_execution_result)
```

### Pattern 4: Operator No-Match Evidence

**What:** Use a deterministic `:no_match` inbound record and route explanation output as the non-happy-path diagnosis. [VERIFIED: mailglass_admin/lib/mailglass_admin/inbound_live.ex:316-371, mailglass_admin/test/mailglass_admin/inbound_live_test.exs:351-407]

**When to use:** Required for JOUR-04 and checkpoint `operator_troubleshooting` stage. [VERIFIED: 58-CONTEXT.md]

**Example:**
```elixir
# Source: mailglass_admin/test/mailglass_admin/inbound_live_test.exs
assert html =~ ~s(data-testid="inbound-routing-trace")
assert html =~ "Routing trace"
assert html =~ "Why this message did not match"
assert html =~ "Recipient"
assert html =~ "Subject"
```

### Anti-Patterns to Avoid

- **Direct provider proof:** Calling `MailglassInbound.Ingress.Providers.Postmark.verify!/3` proves the verifier but not the reference-host route path. Use the public route as the proof entrypoint. [VERIFIED: 58-CONTEXT.md]
- **Renaming stage keys:** Changing `webhook_ingest` or `operator_troubleshooting` breaks Phase 57 and downstream Phase 59/60 consumers. [VERIFIED: 58-CONTEXT.md, lib/mix/tasks/mailglass.trust.run.ex:30-32]
- **Message-string assertions for failures:** Match response status and closed reason atoms/strings, not exception message text. [VERIFIED: CLAUDE.md, mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex:123-132]
- **PII in evidence:** Keep checkpoint and operator evidence to provider, route, status, closed reason, and masked/structural route facts; do not include raw payload bodies or recipient addresses. [VERIFIED: CLAUDE.md, mailglass_admin/test/mailglass_admin/inbound_live_test.exs:396-407]
- **Doctor-only operator proof:** `mailglass.inbound.doctor` is deterministic but D-09 locks `:no_match` routing diagnosis as the Phase 58 scenario. [VERIFIED: 58-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Webhook signature verification | Custom Basic Auth/signature parser in the runner | `MailglassInbound.Ingress.Plug` via reference-host route | The plug already verifies before tenant work and maps closed signature reasons. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex:68-132] |
| Provider normalization | Test-only provider parsing in Phase 58 | Existing Postmark provider and fixture payloads | Provider normalization already exists and is tested; Phase 58 is about public route trust proof. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/ingress/providers/postmark.ex, mailglass_inbound/test/mailglass_inbound/test/ingress_test.exs] |
| Route diagnosis | New matcher/explainer implementation | Existing inbound gateway `explain_routes/2` consumed by `InboundLive` | The UI intentionally reflects router semantics instead of re-implementing matching. [VERIFIED: mailglass_admin/lib/mailglass_admin/inbound_live.ex:357-371] |
| Checkpoint hashing | Ad hoc JSON/string hashing | `Mailglass.ReferenceHost.TrustCheckpoint.encode/1` and shell validator | Existing encoder and validator pin ordering and deterministic SHA. [VERIFIED: lib/mailglass/reference_host/trust_checkpoint.ex:24-64, scripts/check_trust_runner_checkpoint.sh] |
| CLI entrypoint | New mix alias/task | `mix verify.reference_host.journey` | D-01 locks it as the only supported trust-runner entrypoint. [VERIFIED: 58-CONTEXT.md, mix.exs] |

**Key insight:** The value of Phase 58 is route-level proof and operator evidence alignment, not new low-level verification logic. The repo already has the verification and diagnosis primitives; the plan should connect them through the stable public seams and checkpoint contract. [VERIFIED: codebase inspection]

## Common Pitfalls

### Pitfall 1: Proving the Provider, Not the Route
**What goes wrong:** Tests call provider modules or plug internals directly and still leave JOUR-03 unmet. [VERIFIED: 58-CONTEXT.md]  
**Why it happens:** Existing provider tests are convenient and already verify seams. [VERIFIED: mailglass_inbound/test/mailglass_inbound/test/ingress_test.exs]  
**How to avoid:** Add a test/helper that invokes `MailglassReferenceHostWeb.Router.call/2` for `/inbound/:tenant_id/postmark`. [VERIFIED: reference/host_app/lib/mailglass_reference_host_web/router.ex:19-22]  
**Warning signs:** Test imports `MailglassInbound.Ingress.Providers.*` or bypasses `MailglassReferenceHostWeb.Router`. [VERIFIED: test/reference_host/public_seams_contract_test.exs]

### Pitfall 2: Losing Verify-First Ordering Evidence
**What goes wrong:** The negative test asserts only `401`, but not that tenant resolution/persistence/execution were skipped. [VERIFIED: .planning/REQUIREMENTS.md, 58-CONTEXT.md]  
**Why it happens:** `401` alone proves rejection but not ordering. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex:68-132]  
**How to avoid:** Instrument test-only tenancy/persistence/execution markers and assert they remain nil on forged input. [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs]  
**Warning signs:** No assertion equivalent to `refute Process.get(:mailglass_inbound_tenant_resolved)`. [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs]

### Pitfall 3: Breaking Checkpoint Determinism
**What goes wrong:** Adding maps/lists with unstable order changes `checkpoint_sha256` unexpectedly. [VERIFIED: lib/mailglass/reference_host/trust_checkpoint.ex:52-64]  
**Why it happens:** Current hash uses only ordered row triples; adding evidence requires a deliberate canonicalization choice if evidence participates in hashing. [VERIFIED: lib/mailglass/reference_host/trust_checkpoint.ex:58-64]  
**How to avoid:** Keep the hash contract on the existing row triple and validate evidence separately with `scripts/check_trust_runner_checkpoint.sh`; do not include evidence in `checkpoint_sha256` during Phase 58. [VERIFIED: scripts/check_trust_runner_checkpoint.sh, 58-CONTEXT.md]
**Warning signs:** Dry-run checkpoint tests fail intermittently or `scripts/check_trust_runner_checkpoint.sh` rejects valid evidence. [VERIFIED: test/reference_host/trust_runner_checkpoint_contract_test.exs]

### Pitfall 4: Treating LiveView DOM as Stable API
**What goes wrong:** The runner depends on specific DOM/component structure beyond deterministic evidence semantics. [VERIFIED: mailglass_admin/docs/operator-trust.md]  
**Why it happens:** Existing routing-trace tests assert HTML for UI behavior. [VERIFIED: mailglass_admin/test/mailglass_admin/inbound_live_test.exs]  
**How to avoid:** Checkpoint machine-readable operator evidence from route trace/finding data, not arbitrary CSS or component internals. [VERIFIED: 58-CONTEXT.md, mailglass_admin/docs/operator-trust.md]  
**Warning signs:** Checkpoint stores full rendered HTML or raw payload bytes. [VERIFIED: CLAUDE.md]

### Pitfall 5: Widening Scope to Provider Matrix or CI Lanes
**What goes wrong:** Phase 58 becomes a broad provider/CI/release project. [VERIFIED: 58-CONTEXT.md]  
**Why it happens:** Phase 59 and 60 are adjacent trust-proof work. [VERIFIED: .planning/ROADMAP.md]  
**How to avoid:** Use one provider route and local deterministic runner evidence only. [VERIFIED: 58-CONTEXT.md]  
**Warning signs:** Plans add Mailgun/SES/Resend coverage, repo-head gates, or published-version smoke checks. [VERIFIED: 58-CONTEXT.md]

## Code Examples

Verified patterns from repository sources:

### Runner Stage Pipeline
```elixir
# Source: lib/mix/tasks/mailglass.trust.run.ex
@stage_pipeline [:install, :preview, :send, :webhook_ingest, :operator_troubleshooting]
```

### Checkpoint Encoding Contract
```elixir
# Source: lib/mailglass/reference_host/trust_checkpoint.ex
%{
  "schema_version" => @schema_version,
  "claim_boundary" => @claim_boundary,
  "checkpoint_count" => Enum.count(normalized_rows),
  "checkpoint_sha256" => checkpoint_sha256(normalized_rows),
  "checkpoints" => normalized_rows
}
```

### Reference Host Public Inbound Route
```elixir
# Source: reference/host_app/lib/mailglass_reference_host_web/router.ex
scope "/inbound" do
  pipe_through :mailglass_webhooks
  post "/:tenant_id/postmark", MailglassInbound.Ingress.Plug, provider: :postmark
  post "/:tenant_id/sendgrid", MailglassInbound.Ingress.Plug, provider: :sendgrid
end
```

### Signature Failure Response
```elixir
# Source: mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex
e in [SignatureError, InboundSignatureError] ->
  resp = send_json(conn, 401, %{status: "rejected", reason: Atom.to_string(e.type)})
  {resp, %{provider: provider, status: :rejected}}
```

### Operator Routing Trace
```elixir
# Source: mailglass_admin/lib/mailglass_admin/inbound_live.ex
defp routing_trace_for(inbound_router, %{outcome: :no_match, record: record}) do
  if gateway_available?() do
    apply(@gateway, :explain_routes, [inbound_router, record])
  else
    []
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| File-presence trust-runner stage signals | Real semantic proof for `webhook_ingest` and `operator_troubleshooting` | Phase 58 target after Phase 57 | Replace placeholder checks in runner stages with deterministic route and operator evidence while retaining stage keys. [VERIFIED: lib/mix/tasks/mailglass.trust.run.ex:115-137, 58-CONTEXT.md] |
| Direct provider seam tests | Reference-host public route proof | Phase 58 target | Satisfies JOUR-03 by exercising Phoenix route -> ingress plug -> provider verification. [VERIFIED: 58-CONTEXT.md, reference/host_app/lib/mailglass_reference_host_web/router.ex] |
| Deferred boundary language in checkpoint | Bounded completed claim for signed-negative webhook + operator diagnosis | Phase 58 target | `claim_boundary` must no longer say the Phase 58 work is deferred after this phase completes. [VERIFIED: lib/mailglass/reference_host/trust_checkpoint.ex:8, scripts/check_trust_runner_checkpoint.sh] |

**Deprecated/outdated:**
- Checkpoint claim text saying signed-negative webhook and non-happy-path diagnosis are deferred to Phase 58 should be updated during implementation. [VERIFIED: lib/mailglass/reference_host/trust_checkpoint.ex:8, scripts/check_trust_runner_checkpoint.sh]
- `test/reference_host/trust_runner_command_contract_test.exs` currently asserts the Phase 58 deferred language remains; Phase 58 should update that contract. [VERIFIED: test/reference_host/trust_runner_command_contract_test.exs]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|

All claims in this research were verified or cited from repository files, local command output, or locked phase context; no user confirmation is needed before planning. [VERIFIED: codebase inspection]

## Open Questions (RESOLVED)

1. **RESOLVED: Should checkpoint evidence participate in `checkpoint_sha256`?**
   - What we know: Current hash covers `stage|status|fixture_id` rows only. [VERIFIED: lib/mailglass/reference_host/trust_checkpoint.ex:58-64]
   - Decision: Preserve the existing row hash for compatibility. Phase 58 evidence must be validated separately by `scripts/check_trust_runner_checkpoint.sh` and contract tests under `webhook_ingest` and `operator_troubleshooting`. [VERIFIED: 58-CONTEXT.md]
   - Planning implication: Plans must not authorize changing `checkpoint_sha256` semantics. If a future phase needs evidence hashing, it requires an explicit checkpoint contract decision before implementation.

2. **RESOLVED: Where should route-level proof helpers live?**
   - What we know: Existing deterministic fixtures live in `test/support/reference_host/trust_runner_fixtures.ex`; existing route/plug proof patterns live in inbound tests. [VERIFIED: test/support/reference_host/trust_runner_fixtures.ex, mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs]
   - Decision: Add production-accessible reference-host proof support under `lib/mailglass/reference_host/` for runner-executed route/operator proof, and use `test/support/reference_host/trust_runner_fixtures.ex` only for deterministic fixture data shared by tests. [VERIFIED: lib/mix/tasks/mailglass.trust.run.ex, test/support/reference_host/trust_runner_fixtures.ex]
   - Planning implication: Runner evidence must be derived from executing deterministic proof code, not by returning literal maps after source-text checks. Route-level tests should call the same proof support or assert the same observed values.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Mix task and ExUnit | Yes | 1.19.5 | None needed. [VERIFIED: `elixir --version`] |
| Erlang/OTP | Runtime and SHA hashing | Yes | OTP 28 / erts-16.3 | None needed. [VERIFIED: `elixir --version`] |
| Mix | Runner and test aliases | Yes | 1.19.5 | None needed. [VERIFIED: `mix --version`] |
| Python 3 | Checkpoint validator script | Yes | 3.14.4 | Reimplement validator in Elixir only if Python unavailable. [VERIFIED: `python3 --version`, scripts/check_trust_runner_checkpoint.sh] |
| PostgreSQL test DB | Inbound/admin integration tests | Not probed in this research | — | Planner should include DB setup or use existing test aliases that create/drop `Mailglass.TestRepo` where needed. [VERIFIED: mix.exs aliases, test files] |

**Missing dependencies with no fallback:**
- None confirmed in this research. [VERIFIED: local CLI probes]

**Missing dependencies with fallback:**
- PostgreSQL service availability was not probed; many existing integration tests assume test DB access, while route-level proof can be built with fake persistence/execution if full DB is unavailable. [VERIFIED: mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs, mailglass_inbound/test/mailglass_inbound/test/ingress_test.exs]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix. [VERIFIED: test/test_helper.exs, many `*_test.exs`] |
| Config file | `config/test.exs`, `mailglass_inbound/config/test.exs`, `mailglass_admin/config/test.exs`. [VERIFIED: `rg --files`] |
| Quick run command | `MIX_ENV=test mix test test/reference_host --warnings-as-errors` [VERIFIED: existing test layout] |
| Full suite command | `MIX_ENV=test mix verify.reference_host.journey && ./scripts/check_trust_runner_checkpoint.sh && MIX_ENV=test mix test --warnings-as-errors --exclude flaky` [VERIFIED: mix.exs, scripts/check_trust_runner_checkpoint.sh] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| JOUR-03 | Positive signed Postmark webhook goes through reference-host route into real ingress plug and returns deterministic success evidence. | integration/route | `MIX_ENV=test mix test test/reference_host/webhook_operator_path_test.exs --warnings-as-errors` | No - Wave 0. [VERIFIED: current test files] |
| JOUR-03 | Negative Postmark signature goes through same route and returns `401` rejected with closed reason before tenant/persistence/execution. | integration/route | `MIX_ENV=test mix test test/reference_host/webhook_operator_path_test.exs --warnings-as-errors` | No - Wave 0. [VERIFIED: current test files] |
| JOUR-04 | Scripted `:no_match` operator scenario emits deterministic route-trace/finding evidence under `operator_troubleshooting`. | integration/unit | `MIX_ENV=test mix test test/reference_host/webhook_operator_path_test.exs mailglass_admin/test/mailglass_admin/inbound_live_test.exs --warnings-as-errors` | Partial - UI tests exist; runner checkpoint proof missing. [VERIFIED: mailglass_admin/test/mailglass_admin/inbound_live_test.exs] |
| JOUR-03/JOUR-04 | Trust runner writes a checkpoint with updated Phase 58 evidence while preserving stage names/order and `trust_runner.v1`. | contract/smoke | `MIX_ENV=test mix verify.reference_host.journey && ./scripts/check_trust_runner_checkpoint.sh` | Partial - runner/checkpoint tests exist; Phase 58 evidence checks missing. [VERIFIED: test/reference_host/trust_runner_checkpoint_contract_test.exs, scripts/check_trust_runner_checkpoint.sh] |

### Sampling Rate

- **Per task commit:** `MIX_ENV=test mix test test/reference_host --warnings-as-errors`
- **Per wave merge:** `MIX_ENV=test mix verify.reference_host.journey && ./scripts/check_trust_runner_checkpoint.sh`
- **Phase gate:** `MIX_ENV=test mix test --warnings-as-errors --exclude flaky` plus checkpoint validator before `/gsd-verify-work`. [VERIFIED: existing test/alias structure]

### Wave 0 Gaps

- [ ] `test/reference_host/webhook_operator_path_test.exs` - covers JOUR-03 route-level positive/negative proof and JOUR-04 operator evidence checkpoint behavior. [VERIFIED: current test files]
- [ ] Update `test/reference_host/trust_runner_command_contract_test.exs` - remove Phase 58 deferred-language expectation after implementation. [VERIFIED: test/reference_host/trust_runner_command_contract_test.exs]
- [ ] Update `test/reference_host/trust_runner_checkpoint_contract_test.exs` - assert completed Phase 58 claim boundary and evidence fields. [VERIFIED: test/reference_host/trust_runner_checkpoint_contract_test.exs]
- [ ] Update `scripts/check_trust_runner_checkpoint.sh` - validate completed Phase 58 semantics in checkpoint JSON. [VERIFIED: scripts/check_trust_runner_checkpoint.sh]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | Yes | Provider Basic Auth/signature verification through real ingress provider before tenant work. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/ingress/providers/postmark.ex, mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex:68-132] |
| V3 Session Management | Yes for operator UI only | Existing `mailglass_operator_routes/2` session whitelist and mount/action auth seams; Phase 58 should not add a new auth surface. [VERIFIED: reference/host_app/lib/mailglass_reference_host_web/router.ex:25-39, mailglass_admin/docs/operator-trust.md] |
| V4 Access Control | Yes | Tenant-scoped inbound operator loads and replay authorization; negative webhook must not reach tenant resolution. [VERIFIED: mailglass_admin/lib/mailglass_admin/inbound_live.ex:339-390, mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs] |
| V5 Input Validation | Yes | Closed provider list in `Ingress.Plug.init/1`, closed signature response reasons, and outcome allow-list in admin filters. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex:43-56, mailglass_admin/lib/mailglass_admin/inbound_live.ex:447-456] |
| V6 Cryptography | Yes | Do not hand-roll hashing/signature verification; use existing provider verifier and existing checkpoint SHA256 encoder. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/ingress/providers/postmark.ex, lib/mailglass/reference_host/trust_checkpoint.ex:58-64] |
| V9 Communications | Yes | Webhook ingress is the HTTP boundary; forged requests must fail closed with no tenant/persistence side effects. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex:68-132] |

### Known Threat Patterns for Elixir/Phoenix Webhook + Operator Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Forged webhook advances into tenant/persistence work | Spoofing / Tampering | Verify request first, raise closed signature errors, assert no tenant/persistence/execution markers on bad input. [VERIFIED: mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex:68-132] |
| Provider response leaks PII on failure | Information Disclosure | Static closed response bodies and PII-free telemetry/checkpoint evidence. [VERIFIED: CLAUDE.md, mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex:322-363] |
| Operator view leaks another tenant's record | Information Disclosure / Elevation of Privilege | Tenant-required loads and tenant-scoped detail/timeline fetches. [VERIFIED: mailglass_admin/lib/mailglass_admin/inbound_live.ex:432-445, mailglass_admin/test/mailglass_admin/inbound_live_test.exs] |
| Runner over-claims trust proof | Repudiation | Bounded `claim_boundary`, deterministic evidence, and executable checkpoint validator. [VERIFIED: lib/mailglass/reference_host/trust_checkpoint.ex, scripts/check_trust_runner_checkpoint.sh] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/58-verify-first-webhook-operator-path/58-CONTEXT.md` - locked phase decisions, discretion, deferred scope.
- `.planning/REQUIREMENTS.md` - JOUR-03 and JOUR-04 requirement text.
- `.planning/ROADMAP.md` - Phase 58 goal and success criteria.
- `CLAUDE.md` - project constraints, security/PII conventions, public-seam posture.
- `mix.exs` - `verify.reference_host.journey` alias and local dependency declarations.
- `mix.lock` - resolved package versions.
- `lib/mix/tasks/mailglass.trust.run.ex` - canonical runner stage pipeline and checkpoint writing.
- `lib/mailglass/reference_host/trust_checkpoint.ex` - schema, claim boundary, stage order, checkpoint hash.
- `test/support/reference_host/trust_runner_fixtures.ex` - deterministic stage fixture IDs.
- `scripts/check_trust_runner_checkpoint.sh` - checkpoint validator.
- `reference/host_app/lib/mailglass_reference_host_web/router.ex` - public inbound routes and operator route mounting.
- `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` - verify-first order and closed signature response.
- `mailglass_inbound/lib/mailglass_inbound/ingress/providers/postmark.ex` - recommended representative provider verification.
- `mailglass_inbound/lib/mailglass_inbound/ingress/providers/sendgrid.ex` - alternative representative provider verification.
- `mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs` - side-effect marker and negative-signature patterns.
- `mailglass_inbound/test/mailglass_inbound/test/ingress_test.exs` - provider verify/normalize seam tests.
- `mailglass_admin/lib/mailglass_admin/inbound_live.ex` - `:no_match` routing-trace operator surface.
- `mailglass_admin/test/mailglass_admin/inbound_live_test.exs` - deterministic routing-trace evidence tests.
- `mailglass_inbound/lib/mix/tasks/mailglass.inbound.doctor.ex`, `mailglass_inbound/lib/mailglass_inbound/internal/doctor.ex`, `mailglass_inbound/lib/mailglass_inbound/operator/formatter.ex` - supporting operator finding shape.
- `mailglass_admin/docs/operator-trust.md` - stable operator seams and intentionally internal UI details.

### Secondary (MEDIUM confidence)

- Local CLI probes: `elixir --version`, `mix --version`, `python3 --version`. [VERIFIED: shell]

### Tertiary (LOW confidence)

- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - versions verified from `mix.lock` and local CLI output.
- Architecture: HIGH - phase is constrained by existing code paths and locked context.
- Pitfalls: HIGH - each pitfall is tied to existing tests, current implementation, or explicit phase decisions.

**Research date:** 2026-05-27  
**Valid until:** 2026-06-26 for codebase-local planning; re-run dependency/version checks before dependency upgrades or after major branch drift.
