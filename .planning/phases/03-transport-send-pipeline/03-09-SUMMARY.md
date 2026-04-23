---
phase: 03-transport-send-pipeline
plan: "09"
subsystem: tracking-infrastructure
tags: [tracking, endpoint-resolution, hi-02, gap-closure, config-error, tdd]
dependency_graph:
  requires:
    - 03-07 (Tracking.Token, Rewriter, Plug, ConfigValidator)
  provides:
    - Mailglass.Tracking.endpoint/0 — single source of truth for Phoenix.Token endpoint resolution
    - :tracking_endpoint_missing in ConfigError @types closed set
  affects:
    - lib/mailglass/tracking/rewriter.ex (endpoint_fallback/0 removed, delegates to Tracking.endpoint/0)
    - lib/mailglass/tracking/plug.ex (private endpoint/0 removed, delegates to Tracking.endpoint/0)
tech_stack:
  added: []
  patterns:
    - "Single-function endpoint resolution replacing divergent private helpers in two modules"
    - "raise ConfigError instead of hard-coded fallback literal — fail-loud over silent wrong-key signing"
    - "TDD RED/GREEN: failing tests committed before implementation"
key_files:
  created:
    - test/mailglass/tracking/endpoint_resolution_test.exs
  modified:
    - lib/mailglass/tracking.ex (endpoint/0 added)
    - lib/mailglass/tracking/rewriter.ex (endpoint_fallback/0 removed; call site updated)
    - lib/mailglass/tracking/plug.ex (private endpoint/0 removed; two call sites updated)
    - lib/mailglass/errors/config_error.ex (:tracking_endpoint_missing added to @types + format_message)
    - test/mailglass/tracking/rewriter_test.exs (Test 10: :adapter_endpoint end-to-end)
decisions:
  - "Tracking.endpoint/0 raises :tracking_endpoint_missing rather than falling back to a hard-coded literal — mirrors the ConfigValidator pattern (:tracking_host_missing) and eliminates silent token verification failures"
  - "Resolution order preserved from Rewriter: :tracking endpoint: -> :adapter_endpoint -> raise — Plug previously skipped :adapter_endpoint, which was the root cause of HI-02"
metrics:
  duration: "2min"
  completed: "2026-04-23"
  tasks: 2
  files_created: 1
  files_modified: 5
---

# Phase 3 Plan 09: Tracking Endpoint Resolution Unification (HI-02) Summary

**One-liner:** Single `Mailglass.Tracking.endpoint/0` replaces divergent private `endpoint_fallback/0` (Rewriter) and `endpoint/0` (Plug) — eliminates silent Phoenix.Token verification failures when `:adapter_endpoint` is set without `:tracking, endpoint:`.

## What Shipped

### HI-02 Root Cause

`Tracking.Rewriter.endpoint_fallback/0` resolved:
1. `:tracking, endpoint:`
2. `:adapter_endpoint`
3. `"mailglass-tracking-default-endpoint"` (hard-coded fallback)

`Tracking.Plug.endpoint/0` resolved:
1. `:tracking, endpoint:`
2. `"mailglass-tracking-default-endpoint"` (skipped `:adapter_endpoint`)

When an adopter set `config :mailglass, :adapter_endpoint, MyApp.Endpoint` (common — matches the Plug adapter default) without `config :mailglass, :tracking, endpoint:`, the Rewriter signed tokens with `MyApp.Endpoint` and the Plug verified against the literal string `"mailglass-tracking-default-endpoint"`. Phoenix.Token derives HMAC key material from the endpoint, so verification always failed — 204 pixel responses and 404 click responses, no events recorded, no log output.

### Fix

`Mailglass.Tracking.endpoint/0` in `lib/mailglass/tracking.ex`:

```elixir
def endpoint do
  Application.get_env(:mailglass, :tracking, [])[:endpoint] ||
    Application.get_env(:mailglass, :adapter_endpoint) ||
    raise Mailglass.ConfigError.new(:tracking_endpoint_missing,
      context: %{hint: "config :mailglass, :tracking, endpoint: MyApp.Endpoint"})
end
```

Both `Rewriter.rewrite/2` and both `Plug` verify call sites now call `Mailglass.Tracking.endpoint()` — the resolution chain is identical at sign time and verify time.

### ConfigError Extension

`:tracking_endpoint_missing` added to the closed `@types` set in `lib/mailglass/errors/config_error.ex`. Brand-voice message:

> "Tracking endpoint not configured. Set `config :mailglass, :tracking, endpoint: MyApp.Endpoint` or `config :mailglass, :adapter_endpoint, MyApp.Endpoint` to enable open/click tracking."

### Tests

`test/mailglass/tracking/endpoint_resolution_test.exs` — 4 unit tests (async: true):
1. `:tracking, endpoint:` returned when set
2. `:adapter_endpoint` used when `:tracking, endpoint:` is nil
3. `:tracking, endpoint:` takes precedence over `:adapter_endpoint`
4. Raises `%ConfigError{type: :tracking_endpoint_missing}` when neither is set

`test/mailglass/tracking/rewriter_test.exs` — Test 10 (new):
- End-to-end: `Rewriter.rewrite/2` with no explicit `:endpoint` opt and only `:adapter_endpoint` configured — pixel tag injected, proves endpoint resolved without raising.

**All tracking tests:** 3 properties, 46 tests, 0 failures.

## TDD Gate Compliance

- RED gate: commit `39491d5` — `test(03-09): add failing tests for Tracking.endpoint/0 resolution (HI-02 RED)` — 4 tests, 4 failures
- GREEN gate: commit `01b5279` — `feat(03-09): Tracking.endpoint/0 — single endpoint resolution (HI-02 fix)` — 4 tests, 0 failures

## Deviations from Plan

None — plan executed exactly as written. All acceptance criteria met on first implementation pass.

## Known Stubs

None.

## Threat Mitigations Verified

| Threat | Disposition | Verification |
|--------|-------------|--------------|
| T-3-09-01 (HI-02 divergent chains) | mitigated | Single Tracking.endpoint/0; both callers confirmed by grep |
| T-3-09-02 (runtime raise in Plug) | accepted | ConfigValidator.validate_at_boot!/0 catches missing endpoint at boot |
| T-3-09-03 (:adapter_endpoint as key material) | accepted | Same security posture as explicit :tracking, endpoint: |

## Threat Flags

None — no new network endpoints, auth paths, or schema changes.

## Self-Check: PASSED

Files created/present:
- `test/mailglass/tracking/endpoint_resolution_test.exs` ✓

Files modified:
- `lib/mailglass/tracking.ex` ✓ (endpoint/0 at line 112)
- `lib/mailglass/tracking/rewriter.ex` ✓ (endpoint_fallback removed; Mailglass.Tracking.endpoint() at line 45)
- `lib/mailglass/tracking/plug.ex` ✓ (private endpoint/0 removed; 2 call sites updated)
- `lib/mailglass/errors/config_error.ex` ✓ (:tracking_endpoint_missing in @types + format_message)
- `test/mailglass/tracking/rewriter_test.exs` ✓ (Test 10 added)

Commits:
- 39491d5: test(03-09): add failing tests for Tracking.endpoint/0 resolution (HI-02 RED) ✓
- 01b5279: feat(03-09): Tracking.endpoint/0 — single endpoint resolution (HI-02 fix) ✓
- 28f6fb9: feat(03-09): add :adapter_endpoint end-to-end test in rewriter_test (HI-02 closed) ✓
