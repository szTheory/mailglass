# Phase 11: RFC 8058 List-Unsubscribe - Validation

## Goal
Ship RFC 8058 one-click unsubscribe end-to-end in core mailglass: rotation-safe signed tokens, atomic stream-aware header injection, a built-in GET confirmation page plus idempotent POST flow, deterministic router mounting, a read-only generator task, property coverage, and adopter-facing docs.

## Truths
- `Mailglass.Compliance.Unsubscribe` signs only `delivery_id`, verifies against the current endpoint first, then configured `previous_secrets`, and fails fast when `byte_size(url) > 900`.
- `Mailglass.Tenancy` can optionally override the unsubscribe host through `compliance_host/1`, while the global compliance host remains the fallback.
- `Mailglass.Compliance` keeps generic RFC header injection on `%Swoosh.Email{}` and introduces a message-aware unsubscribe path so stream rules stay load-bearing.
- `inject_unsubscribe_headers/2` is the only allowed path that sets `List-Unsubscribe` and `List-Unsubscribe-Post`, and it sets both headers together or neither.
- GET `/mailglass/unsubscribe/:token` renders a built-in standalone confirmation page by default and may redirect only on the GET branch when configured.
- POST `/mailglass/unsubscribe/:token` returns HTTP 200 on first write and replay, never redirects, and records durable unsubscribe state through append-only events with deterministic idempotency.
- `Mailglass.Lifecycle` exists as a transactional seam in Phase 11, with the behavior contract introduced before controller integration.
- The unsubscribe router macro uses Phoenix's accumulated `:phoenix_routes` attribute to fail on verb/path collisions before a shadowed mount can ship.
- `mix mailglass.gen.unsubscribe` prints setup instructions only and writes zero files.
- StreamData properties cover rotation, expiry, replay convergence, URL safety, and stream-conditional header behavior.
- Docs tell adopters how to configure the feature, verify DKIM `h=` coverage for both unsubscribe headers, rotate secrets safely, and validate ESP-specific behavior.

## Artifacts
- `lib/mailglass/config.ex` — compliance schema and accessor surface
- `lib/mailglass/lifecycle.ex` — transactional lifecycle behavior and default implementation
- `lib/mailglass/tenancy.ex` — optional `compliance_host/1` callback
- `lib/mailglass/compliance/unsubscribe.ex` — token, URL, and tenant-host resolution service
- `lib/mailglass/compliance.ex` — message-aware unsubscribe injection seam
- `credo_checks/require_atomic_unsubscribe_headers.ex` — lint guard for atomic header writes
- `lib/mailglass/compliance/unsubscribe_controller.ex` — GET/POST controller flow
- `lib/mailglass/compliance/unsubscribe_html.ex` and `lib/mailglass/compliance/unsubscribe_html/confirm.html.heex` — built-in confirmation page
- `lib/mailglass/router.ex` — unsubscribe mount macro with collision checks
- `lib/mix/tasks/mailglass.gen.unsubscribe.ex` — read-only checklist generator
- `test/mailglass/compliance/unsubscribe_test.exs` — unit coverage for token, config, and tenancy host override behavior
- `test/mailglass/compliance/unsubscribe_controller_test.exs` — controller flow coverage
- `test/mailglass/router/unsubscribe_router_test.exs` — macro, path, and collision coverage
- `test/mailglass/properties/unsubscribe_property_test.exs` and `test/mailglass/properties/unsubscribe_post_idempotency_property_test.exs` — property coverage
- `guides/unsubscribe.md` and `guides/dkim-setup.md` — adopter documentation

## Key Links
- from: `lib/mailglass/compliance/unsubscribe.ex` to: `lib/mailglass/config.ex` via: centralized compliance config access
- from: `lib/mailglass/compliance/unsubscribe.ex` to: `lib/mailglass/tenancy.ex` via: optional `compliance_host/1` override before global-host fallback
- from: `lib/mailglass/compliance.ex` to: `lib/mailglass/compliance/unsubscribe.ex` via: stream-aware atomic header injection
- from: `lib/mailglass/compliance/unsubscribe_controller.ex` to: `lib/mailglass/lifecycle.ex` via: in-transaction lifecycle hook application
- from: `lib/mailglass/compliance/unsubscribe_controller.ex` to: `lib/mailglass/events.ex` via: append-only unsubscribe event persistence
- from: `lib/mailglass/router.ex` to: `deps/phoenix/lib/phoenix/router.ex` via: compile-time `:phoenix_routes` collision detection
- from: `lib/mix/tasks/mailglass.gen.unsubscribe.ex` to: `lib/mailglass/router.ex` via: generator output matches runtime mount contract
- from: `guides/dkim-setup.md` to: RFC 8058 behavior via: DKIM `h=` coverage for `List-Unsubscribe` and `List-Unsubscribe-Post`
