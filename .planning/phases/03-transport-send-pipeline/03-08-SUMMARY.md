---
phase: 03-transport-send-pipeline
plan: "08"
subsystem: tracking-infrastructure
tags: [tracking, outbound, pixel-injection, link-rewriting, gap-closure, track-03, tdd]
dependency_graph:
  requires:
    - 03-07 (Tracking.Token, Rewriter, rewrite_if_enabled/1)
    - 03-09 (Tracking.endpoint/0 — raises on missing config instead of hardcoded fallback)
  provides:
    - Tracking.rewrite_if_enabled/1 wired into Outbound.do_send/2, do_deliver_later/2, preflight_single/1
    - UAT Criterion 4 positive assertion: pixel present in html_body when mailable opts in
    - config/test.exs :tracking and :adapter_endpoint configured for test suite
  affects:
    - lib/mailglass/outbound.ex (three call sites added)
    - test/mailglass/core_send_integration_test.exs (Criterion 4 positive test)
    - config/test.exs (:adapter_endpoint + :tracking host/salts added)
tech_stack:
  added: []
  patterns:
    - "Insert rewrite_if_enabled call between Renderer.render/1 and next pipeline step in all three Outbound hot paths"
    - "TDD RED/GREEN: failing pixel-assertion test committed before outbound wiring"
    - "adapter_endpoint config key used in tests (NimbleOptions :tracking schema does not include :endpoint)"
key_files:
  created: []
  modified:
    - lib/mailglass/outbound.ex (rewrite_if_enabled in do_send/2, do_deliver_later/2, preflight_single/1)
    - test/mailglass/core_send_integration_test.exs (TrackingOnMailer + positive pixel test in Criterion 4)
    - config/test.exs (adapter_endpoint + :tracking host/salts for test suite)
decisions:
  - "config :mailglass, adapter_endpoint: used for test endpoint resolution rather than config :mailglass, :tracking, endpoint: — the NimbleOptions :tracking schema only accepts [:host, :scheme, :salts, :max_age]; :endpoint is not a schema key. Tracking.endpoint/0 resolves :tracking, endpoint: first, then :adapter_endpoint — both paths reach the same token key material. Adding :endpoint to the schema is a future enhancement."
  - "rewrite_if_enabled called in do_send/2 and do_deliver_later/2 BEFORE the database write (Multi#1) — uses pre-delivery string as delivery_id fallback per Plan 07 design. The rewritten HTML is stored in metadata[:rendered_html] and captured by the Fake adapter as the html_body the test asserts on."
metrics:
  duration: "15min"
  completed: "2026-04-23"
  tasks: 2
  files_created: 0
  files_modified: 3
---

# Phase 3 Plan 08: Tracking Rewriter → Outbound Wiring (TRACK-03 Gap Closure) Summary

**One-liner:** `Tracking.rewrite_if_enabled/1` wired into all three Outbound hot paths (`do_send/2`, `do_deliver_later/2`, `preflight_single/1`), closing the TRACK-03 gap so opted-in mailables receive pixel injection and link rewriting at send time.

## What Shipped

### Outbound Pipeline Wiring (3 call sites)

`lib/mailglass/outbound.ex` — three targeted additions after `{:ok, rendered} <- Renderer.render(msg)`:

**do_send/2 (line 263):**
```elixir
rewritten = Tracking.rewrite_if_enabled(rendered)
do_send_after_preflight(rewritten, opts)
```

**do_deliver_later/2 (line 326):**
```elixir
rewritten = Tracking.rewrite_if_enabled(rendered)
enqueue_via_async_adapter(rewritten, opts)
```

**preflight_single/1 (line 480):**
```elixir
{:ok, Tracking.rewrite_if_enabled(rendered)}
```

`Tracking` was already aliased at line 73 — no new alias required. The rewrite happens before any DB write, so the Fake adapter receives the rewritten HTML and `assert_mail_sent` can inspect it. The `"pre-delivery"` fallback for `delivery_id` is correct pre-persist behaviour per Plan 07 design.

### UAT Criterion 4 — Positive Assertion

`test/mailglass/core_send_integration_test.exs` — `TrackingOnMailer` module added at describe-block scope with `tracking: [opens: true, clicks: true]`:

```elixir
test "pixel injected when mailable opts in with tracking: [opens: true]" do
  assert {:ok, %Delivery{status: :sent}} =
           "uat-c4-tracking-on@example.com"
           |> TrackingOnMailer.promo()
           |> Outbound.deliver()

  assert_mail_sent(fn msg ->
    String.contains?(
      msg.swoosh_email.html_body || "",
      ~s(style="display:block;width:1px;height:1px;border:0;")
    )
  end)
end
```

Criterion 4 now has both the negative case (no pixel for plain mailable) and the positive case (pixel present for opted-in mailable).

### config/test.exs — Tracking Config

Added so `Tracking.endpoint/0` resolves without raising in the test suite (Plan 09 removed the hardcoded fallback):

```elixir
config :mailglass,
  adapter_endpoint: "mailglass-test-endpoint"

config :mailglass, :tracking,
  host: "localhost:4000",
  salts: ["test-salt"]
```

Using `adapter_endpoint:` (the second resolution path in `Tracking.endpoint/0`) rather than `:tracking, endpoint:` because the NimbleOptions `:tracking` schema does not include `:endpoint` as a valid key — adding it there would require a schema change to `config.ex`.

## TDD Gate Compliance

- RED gate: commit `f73e8b4` — `test(03-08): add failing positive-tracking pixel test (RED phase)` — 1 failure (pixel assertion false, html_body unchanged)
- GREEN gate: commit `979f8e0` — `feat(03-08): wire Tracking.rewrite_if_enabled/1 into Outbound pipeline (TRACK-03)` — 0 failures, 10 tests passing

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] config :mailglass, :tracking, endpoint: rejected by NimbleOptions schema**
- **Found during:** RED phase — boot raised `NimbleOptions.ValidationError: unknown options [:endpoint], valid options are: [:host, :scheme, :salts, :max_age]`
- **Issue:** Plan 08 specified `config :mailglass, :tracking, endpoint: "mailglass-test-endpoint"` in test.exs, but the NimbleOptions `:tracking` schema in `config.ex` does not include `:endpoint` as a valid key. `validate_at_boot!/0` calls `NimbleOptions.validate!` which rejects unknown keys.
- **Fix:** Used `config :mailglass, adapter_endpoint: "mailglass-test-endpoint"` instead. `Tracking.endpoint/0` resolution order is `:tracking, endpoint:` first, then `:adapter_endpoint` — both yield the same key material for Phoenix.Token. The `:tracking, endpoint:` path would require adding `:endpoint` to the NimbleOptions schema (a future enhancement, not in scope for this gap-closure plan).
- **Files modified:** `config/test.exs`
- **Impact:** Zero — test behaviour is identical; token signing uses the same endpoint value regardless of which config key provides it.

## Known Stubs

None — `rewrite_if_enabled/1` is fully implemented and wired. Pixel injection and link rewriting are live for opted-in mailables.

## Threat Mitigations Verified

| Threat | Disposition | Verification |
|--------|-------------|--------------|
| T-3-08-01 (Rewriter on plain-text body) | accepted | rewrite_if_enabled only modifies html_body; text_body confirmed unchanged in test |
| T-3-08-02 (Floki parse failure) | accepted | rescue in Rewriter returns msg unchanged; pipeline not disrupted |
| T-3-08-03 (delivery_id before Delivery row) | accepted | "pre-delivery" fallback used; token is signed, not plain-text |

## Threat Flags

None — no new network endpoints, auth paths, or schema changes.

## Self-Check: PASSED

Files modified:
- `lib/mailglass/outbound.ex` — 3 `rewrite_if_enabled` calls at lines 263, 326, 480 ✓
- `test/mailglass/core_send_integration_test.exs` — `TrackingOnMailer` + pixel test in Criterion 4 ✓
- `config/test.exs` — `adapter_endpoint` + `:tracking` host/salts ✓

Grep verification:
- `grep -n "rewrite_if_enabled" lib/mailglass/outbound.ex` → 3 lines ✓
- `grep "tracking" config/test.exs` → 2 lines ✓
- `grep -c "pixel injected when mailable opts in" test/mailglass/core_send_integration_test.exs` → 1 ✓

Test results:
- `mix test --only phase_03_uat` → 10 tests, 0 failures ✓
- `mix test --warnings-as-errors --only phase_03_uat --exclude flaky` → 62 tests, 0 failures ✓

Compile:
- `mix compile --warnings-as-errors` → clean ✓
- `mix compile --no-optional-deps --warnings-as-errors` → clean ✓

Commits:
- f73e8b4: test(03-08): add failing positive-tracking pixel test (RED phase) ✓
- 979f8e0: feat(03-08): wire Tracking.rewrite_if_enabled/1 into Outbound pipeline (TRACK-03) ✓
