---
phase: 03-transport-send-pipeline
plan: "07"
subsystem: tracking-infrastructure
tags: [tracking, token, rewriter, plug, config-validator, open-pixel, click-redirect, tdd]
dependency_graph:
  requires:
    - 03-01 (ConfigError atoms, Tenancy, Clock, Events)
    - 03-02 (Adapters.Fake, Events.append)
    - 03-04 (Tracking facade enabled?/1, Mailable behaviour, __mailglass_opts__/0)
    - 03-05 (Outbound.send/2 gap-closure item documented)
  provides:
    - Mailglass.Tracking.Token (sign/verify open+click with salts rotation, D-33..D-35)
    - Mailglass.Tracking.Rewriter (Floki HTML transform, pixel+links, D-36..D-37)
    - Mailglass.Tracking.rewrite_if_enabled/1 (facade post-render hook)
    - Mailglass.Tracking.Plug (mountable pixel+click endpoint, D-34..D-35..D-39)
    - Mailglass.Tracking.ConfigValidator (boot-time host assertion, D-32)
    - api_stability.md §Tracking.Token + §Tracking.Rewriter + §Tracking.Plug + §Tracking.ConfigValidator
  affects:
    - Phase 5 admin — can discover mailables with tracking opts via __mailglass_opts__/0
    - Phase 4 webhook — Plug event-recording path mirrors webhook append path
    - Adopter Outbound.send/2 — gap-closure: rewrite_if_enabled not yet wired in (documented)
tech_stack:
  added: []
  patterns:
    - "Phoenix.Token.sign/4 + verify/4 with salts-list iteration for rotation (D-33)"
    - "D-35 pattern a: target_url inside signed token, no ?r= query parameter (structurally unreachable open-redirect)"
    - "Floki.traverse_and_update/2 for pure HTML tree transform"
    - "Plug.Router use macro with match/dispatch plugs"
    - "Code.ensure_loaded before :code.all_loaded scan for boot-time module discovery"
    - "rescue _ -> :ok pattern in Plug to ensure pixel/redirect always succeeds despite DB errors"
key_files:
  created:
    - lib/mailglass/tracking/token.ex
    - lib/mailglass/tracking/rewriter.ex
    - lib/mailglass/tracking/plug.ex
    - lib/mailglass/tracking/config_validator.ex
    - test/mailglass/tracking/token_test.exs
    - test/mailglass/tracking/token_rotation_test.exs
    - test/mailglass/tracking/open_redirect_test.exs
    - test/mailglass/tracking/rewriter_test.exs
    - test/mailglass/tracking/plug_test.exs
    - test/mailglass/tracking/config_validator_test.exs
  modified:
    - lib/mailglass/tracking.ex (rewrite_if_enabled/1 added; moduledoc updated)
    - docs/api_stability.md (§Tracking.Token + §Tracking.Rewriter + §Tracking.Plug + §Tracking.ConfigValidator)
decisions:
  - "D-35 pattern a enforced: target_url in signed token payload, never as query param — open-redirect CVE class structurally unreachable"
  - "Defense-in-depth: verify_click/2 re-validates URI scheme at verify time in addition to sign-time check (T-3-07-10)"
  - "Token property tests use min_length: 5 for tenant_id/delivery_id/host — single-char strings can appear by chance in Base64-encoded Phoenix.Token output, producing false positives in the plaintext-exposure assertion"
  - "ConfigValidator uses Code.ensure_loaded in test setup to force TrackingMailer into :code.all_loaded() — BEAM lazy-loads compiled .beam files; function_exported? returns false before first load in a fresh process"
  - "Plug swallows DB write errors in record_open_event/record_click_event with rescue — pixel/redirect ALWAYS succeed; event recording is best-effort (image load failures cause pixel re-requests which would be double-counted anyway)"
  - "Plug aliases as TrackingPlug in test file — alias Mailglass.Tracking.Plug shadows Plug namespace, making %Plug.Conn{} resolve to Mailglass.Tracking.Plug.Conn (compile error)"
  - "rewrite_if_enabled/1 reads delivery_id from message.metadata[:delivery_id]; falls back to pre-delivery string for render-preview mode (before Delivery row is inserted)"
  - "GIF89a pixel is exactly 43 bytes — hardcoded binary literal; no runtime encoding"
  - "Rewriter collect_head_hrefs/1 uses Floki.find(doc, head a) to gather anchors inside <head> before traversal; practically rare since <head> uses <link> not <a> for canonical/prefetch"
metrics:
  duration: "13min"
  completed: "2026-04-23"
  tasks: 3
  files_created: 10
  files_modified: 2
---

# Phase 3 Plan 07: Tracking Infrastructure Summary

**One-liner:** Phoenix.Token-signed open-pixel + click-redirect tracking with salts rotation, Floki HTML rewriter, mountable Plug endpoint (GIF89a pixel + 302 redirect), and boot-time ConfigValidator — open-redirect CVE class structurally eliminated (D-35 pattern a).

## What Shipped

### Mailglass.Tracking.Token (TRACK-03, D-33..D-35)

Four public functions for signing and verifying tracking tokens:

```elixir
sign_open(endpoint, delivery_id, tenant_id) :: binary()
verify_open(endpoint, token) :: {:ok, %{delivery_id, tenant_id}} | :error
sign_click(endpoint, delivery_id, tenant_id, target_url) :: binary()
verify_click(endpoint, token) :: {:ok, %{delivery_id, tenant_id, target_url}} | :error
```

**Payload shapes:**
- Open: `{:open, delivery_id, tenant_id}`
- Click: `{:click, delivery_id, tenant_id, target_url}`

**Security properties:**
- `target_url` inside signed payload — no `?r=` param — open-redirect class structurally unreachable (D-35)
- Scheme validated at sign time (`http`/`https` only); raises `%ConfigError{type: :invalid}` for `ftp:`/`javascript:`/etc.
- Defense-in-depth scheme re-check at verify time (T-3-07-10)
- Salts rotation: HEAD signs, ALL tried at verify; remove salt to invalidate old tokens (D-33)
- `tenant_id` in payload only, never in URL path/query (D-39)
- Sign opts: `[key_iterations: 1000, key_length: 32, digest: :sha256]`

**Tests:** 12 unit tests + 3 property tests (open-redirect impossibility × 100 runs, sign/click round-trip × 100 runs, scheme-rejection × 100 runs).

### Mailglass.Tracking.Rewriter (TRACK-03, D-36..D-37)

Pure Floki-based HTML transform:

```elixir
rewrite(html_body :: String.t(), opts :: keyword()) :: String.t()
```

**Pixel injection (D-37):** `<img width="1" height="1" alt="" style="display:block;width:1px;height:1px;border:0;" />` appended as last child of `<body>`. Missing `<body>` → appended at document root.

**Link rewriting:** Replaces `<a href="...">` with `<a href="https://track.host/c/<token>">` for eligible links.

**Skip list (D-36):** `mailto:`, `tel:`, `sms:`, `data:`, `javascript:` schemes; `#fragment` anchors; scheme-less relative URLs; `<a data-mg-notrack>` (attribute stripped); `<a>` inside `<head>`.

**Plaintext invariant:** `text_body` is NEVER passed to the Rewriter. `rewrite/2` only operates on HTML strings.

**Tests:** 10 tests covering pixel injection, skip-list, data-mg-notrack stripping, head anchor exclusion, missing-body fallback, opens+clicks composition, facade dispatch.

### Mailglass.Tracking.rewrite_if_enabled/1 (Tracking facade patch)

```elixir
rewrite_if_enabled(Mailglass.Message.t()) :: Mailglass.Message.t()
```

Reads `enabled?(mailable: mod)` flags; calls `Rewriter.rewrite/2` only when `opens or clicks`. Returns message unchanged otherwise. Reads `delivery_id` from `message.metadata[:delivery_id]`; falls back to `"pre-delivery"` for preview mode.

**Gap-closure note:** `Mailglass.Outbound.send/2` (Plan 05) does not yet call `rewrite_if_enabled/1`. Adopters invoke manually between `Renderer.render/1` and `deliver/2` for v0.1. Phase 3.1 gap-closure plan wires it into the Outbound pipeline.

### Mailglass.Tracking.Plug (TRACK-03, D-34..D-35..D-39)

Mountable `Plug.Router`:

```elixir
forward "/track", Mailglass.Tracking.Plug
```

| Route | Success | Failure |
|-------|---------|---------|
| `GET /o/:token.gif` | `200 image/gif` — 43-byte GIF89a | `204` (D-39: no enumeration) |
| `GET /c/:token` | `302 Location: <target_url>` | `404` |
| Any other | `404` | — |

**No-enumeration contract (D-39):** Failed `verify_open/2` → `204` (not 404). An attacker cannot distinguish expired from invalid tokens.

**Security headers:** `Cache-Control: no-store, private, max-age=0`, `Pragma: no-cache`, `X-Robots-Tag: noindex`.

**Event recording:** Best-effort `Events.append/1` with `type: :opened` / `type: :clicked`. DB failures swallowed — pixel/redirect always succeed.

**Telemetry:** `[:mailglass, :tracking, :open|click, :recorded]` with `%{delivery_id, tenant_id}` — no PII (D-31).

**Tests:** 7 tests covering all routes, GIF89a body verification, header assertions, D-39 204/404 responses, Plug contract.

### Mailglass.Tracking.ConfigValidator (TRACK-03, D-32)

```elixir
validate_at_boot!() :: :ok
```

Walks `:code.all_loaded()` for mailable modules with tracking enabled. Raises `%ConfigError{type: :tracking_host_missing}` when any mailable has `opens: true` or `clicks: true` AND `:tracking, :host` is `nil`/`""`. Returns `:ok` otherwise.

**Tests:** 4 tests covering raise on missing host, no-raise when host configured, function exported.

## Threat Mitigations Verified

| Threat | Mitigation | Test |
|--------|-----------|------|
| T-3-07-01 (open-redirect, critical) | target_url in signed payload, no query param (D-35 pattern a) | open_redirect_test.exs property × 100 |
| T-3-07-02 (tenant_id URL leak, high) | D-39: tenant_id only in payload; 204/404 on failure | token_test.exs Test 11 |
| T-3-07-09 (Plug config missing, high) | ConfigValidator raises at boot; salts/0 raises if empty | config_validator_test.exs |
| T-3-07-10 (scheme bypass at verify, critical) | verify_click/2 re-validates scheme (defense-in-depth) | token_test.exs Tests 5-6, 13 |
| T-3-07-04 (salts rotation regression, medium) | iterate_salts tries all; Tests 7-8 verify rotation window | token_rotation_test.exs |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Property test false positive on short tenant_id strings**
- **Found during:** Task 1 GREEN phase (token_test.exs property test)
- **Issue:** Single-character strings like `"w"` can appear by chance in the Base64-encoded Phoenix.Token output. The `refute String.contains?(token, tenant_id)` assertion was triggering false positives.
- **Fix:** Changed property generator minimum lengths from 1 to 5 characters for `delivery_id`, `tenant_id`, and `host`. The 5+ character minimum makes accidental Base64 substring collisions cryptographically implausible.
- **Files modified:** `test/mailglass/tracking/token_test.exs`
- **Commit:** 828998c

**2. [Rule 1 - Bug] `alias Mailglass.Tracking.Plug` shadowed `Plug` namespace in test**
- **Found during:** Task 3 test compilation
- **Issue:** `alias Mailglass.Tracking.{Plug, Token}` made `Plug` resolve to `Mailglass.Tracking.Plug`, causing `%Plug.Conn{}` to be interpreted as `Mailglass.Tracking.Plug.Conn` — compile error.
- **Fix:** Changed to `alias Mailglass.Tracking.Plug, as: TrackingPlug` throughout the test.
- **Files modified:** `test/mailglass/tracking/plug_test.exs`
- **Commit:** 8c593a8

**3. [Rule 1 - Bug] ConfigValidator test `function_exported?` returned false in full suite**
- **Found during:** Task 3 full suite run
- **Issue:** In the full `mix test` run, `Mailglass.Tracking.ConfigValidator` was not yet loaded when the `function_exported?` test ran. The alias remaps the name at compile time but does not load the module at runtime.
- **Fix:** Added `Code.ensure_loaded(ConfigValidator)` in the specific test case. (Pattern mirrors the established decision from Plan 03-04: "Tracking.fetch_from_mailable/1 calls Code.ensure_loaded/1 before function_exported? — async BEAM lazy loading".)
- **Files modified:** `test/mailglass/tracking/config_validator_test.exs`
- **Commit:** 8c593a8

**4. [Rule 1 - Bug] `base_opts/1` private function default warning under --warnings-as-errors**
- **Found during:** Task 2 --warnings-as-errors run
- **Issue:** `defp base_opts(overrides \\ [])` with a default argument triggered "default values for optional arguments in private function are never used" warning (Elixir 1.18+).
- **Fix:** Split into `defp base_opts/0` and `defp base_opts/1` with explicit delegation.
- **Files modified:** `test/mailglass/tracking/rewriter_test.exs`
- **Commit:** a5e016e

## Gap-Closure Item

**Outbound.send/2 → rewrite_if_enabled/1 wiring:** `Mailglass.Outbound.send/2` (Plan 05) does not yet call `Tracking.rewrite_if_enabled/1` in its pipeline. For v0.1, adopters invoke it manually. A Phase 3.1 gap-closure plan should add this call between `Renderer.render/1` (step 5) and Multi#1 (Delivery INSERT) in the Outbound preflight pipeline.

## Known Stubs

None — all four modules are fully implemented. The `rewrite_if_enabled/1` → `Outbound.send/2` wiring is a gap-closure item (documented above), not a stub that prevents the plan's goal from being achieved.

## Threat Flags

None — no new network endpoints, auth paths, or schema changes introduced beyond what the plan's threat model covers.

## Self-Check: PASSED

Files created/present:

- `lib/mailglass/tracking/token.ex` ✓
- `lib/mailglass/tracking/rewriter.ex` ✓
- `lib/mailglass/tracking/plug.ex` ✓
- `lib/mailglass/tracking/config_validator.ex` ✓
- `test/mailglass/tracking/token_test.exs` ✓
- `test/mailglass/tracking/token_rotation_test.exs` ✓
- `test/mailglass/tracking/open_redirect_test.exs` ✓
- `test/mailglass/tracking/rewriter_test.exs` ✓
- `test/mailglass/tracking/plug_test.exs` ✓
- `test/mailglass/tracking/config_validator_test.exs` ✓

Modified files:
- `lib/mailglass/tracking.ex` ✓ (rewrite_if_enabled/1 added)
- `docs/api_stability.md` ✓ (§Tracking.Token + §Tracking.Rewriter + §Tracking.Plug + §Tracking.ConfigValidator)

Commits:
- b7d0776: test(03-07): add failing tests for Token sign/verify + rotation + open-redirect property ✓
- 828998c: feat(03-07): Mailglass.Tracking.Token — sign/verify open+click with salts rotation ✓
- c7204a0: test(03-07): add failing tests for Tracking.Rewriter + rewrite_if_enabled facade ✓
- a5e016e: feat(03-07): Mailglass.Tracking.Rewriter + rewrite_if_enabled facade patch ✓
- 141cae9: test(03-07): add failing tests for Tracking.Plug + ConfigValidator ✓
- 8c593a8: feat(03-07): Mailglass.Tracking.Plug + ConfigValidator + api_stability sections ✓
