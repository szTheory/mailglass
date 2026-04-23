---
phase: 03-transport-send-pipeline
plan: "12"
subsystem: core
tags: [bug-fix, security, reliability, events, outbound, projector, batch-error]
dependency_graph:
  requires: ["03-08"]
  provides: [ME-01-closed, ME-02-closed, ME-03-closed, ME-04-closed, ME-05-closed]
  affects:
    - lib/mailglass/events.ex
    - lib/mailglass/errors/batch_failed.ex
    - lib/mailglass/outbound.ex
    - lib/mailglass/outbound/projector.ex
tech_stack:
  added: []
  patterns:
    - "Map.put_new_lazy with &Mailglass.Clock.utc_now/0 for deterministic timestamps in tests"
    - "String.to_existing_atom with nested try/rescue for safe atom resolution from DB strings"
    - "rescue + catch :exit in same defp for comprehensive PubSub error handling"
    - "Private pattern-match function (provider_tag/1) as safe alternative to Map.get on term()"
key_files:
  created: []
  modified:
    - lib/mailglass/events.ex
    - lib/mailglass/errors/batch_failed.ex
    - lib/mailglass/outbound.ex
    - lib/mailglass/outbound/projector.ex
    - test/mailglass/events_test.exs
    - test/mailglass/errors/batch_failed_test.exs
decisions:
  - "provider_tag/1 uses two pattern-match clauses (map with :adapter key vs wildcard) rather than is_map guard — cleaner intent signal and directly documents the contract that only map-shaped responses with an :adapter key contribute a meaningful tag"
  - "build_rehydrated_message/2 private helper extracted to avoid duplicating Swoosh.Email assembly across both resolution paths in rehydrate_message/1"
  - "ME-03 nested try/rescue structure: outer rescues ArgumentError on Elixir-prefixed atom, falls through to bare mod_str path; inner rescues ArgumentError on bare atom — each rescue returns a distinct :why context key (:module_not_loaded vs :atom_not_found)"
metrics:
  duration: "9min"
  completed_date: "2026-04-23"
  tasks_completed: 3
  files_changed: 6
---

# Phase 3 Plan 12: Medium-severity code review gap closure (ME-01..ME-05) Summary

**One-liner:** Five surgical fixes across four files — Clock.utc_now for deterministic test timestamps, BatchFailed clause simplification, to_existing_atom atom-table hardening, PubSub :exit catch, and provider_tag pattern-match for non-map adapter responses.

## What Was Built

Closed all five ME-severity issues identified in `03-REVIEW.md` before Phase 4. Each fix is independently revertable.

### ME-01 — Events.normalize/1 uses Mailglass.Clock.utc_now/0

`lib/mailglass/events.ex` line 160: Changed `&DateTime.utc_now/0` to `&Mailglass.Clock.utc_now/0` in `Map.put_new_lazy`. `Clock.Frozen.freeze/1` in tests now produces deterministic `occurred_at` timestamps in `Events.append/1` calls. Unblocks Phase 6 LINT-12 (`NoDirectDateTimeNow`).

### ME-02 — BatchFailed.format_message simplified

`lib/mailglass/errors/batch_failed.ex` lines 77-81: Replaced `length(ctx[:failures] || []) |> then(fn 0 -> ctx[:failed_count] || "some" end)` with the direct `ctx[:failed_count] || "some"`. The original `fn 0 ->` clause raised `FunctionClauseError` when `ctx[:failures]` was a non-empty list (length > 0, clause never matched). Confirmed by TDD RED test using `context: %{count: 3, failed_count: 1, failures: [%{id: "abc"}]}`.

### ME-03 — rehydrate_message uses to_existing_atom on both paths

`lib/mailglass/outbound.ex` `rehydrate_message/1`: Replaced `String.to_atom("Elixir." <> mod_str)` with `String.to_existing_atom/1` on both the primary and fallback resolution paths. Nested `try/rescue` structure: outer rescues `ArgumentError` on the `"Elixir." <> mod_str` atom (falls through to bare `mod_str` path); inner rescues `ArgumentError` on the bare atom path. Each failure returns a structured `SendError{type: :adapter_failure, reason_class: :mailable_unresolvable}` with distinct `:why` context keys (`:module_not_loaded` vs `:atom_not_found`). Extracted `build_rehydrated_message/2` private helper to avoid duplicating Swoosh.Email assembly.

### ME-04 — Projector.safe_broadcast/2 catches :exit

`lib/mailglass/outbound/projector.ex` `safe_broadcast/2`: Added `catch :exit, reason ->` clause after the existing `rescue`. `Phoenix.PubSub.broadcast/3` uses a GenServer call internally which exits when the server is stopped (application shutdown, supervisor restart). The delivery is already committed before broadcast — this exit must not propagate to the caller. Returns `:ok` and logs at debug level.

### ME-05 — provider_tag/1 replaces Map.get on provider_response

`lib/mailglass/outbound.ex` `do_send_after_preflight`: Replaced `inspect(Map.get(dispatch_result.provider_response, :adapter, :unknown))` with `provider_tag(dispatch_result.provider_response)`. Added two-clause private function:

```elixir
defp provider_tag(%{adapter: a}), do: inspect(a)
defp provider_tag(_), do: "unknown"
```

`provider_response` is `adapter-defined (term())` — custom adapters may return tuples, atoms, strings, or nil. `Map.get/3` on a non-map term raises `BadMapError`.

## Tests Added

- `test/mailglass/events_test.exs`: New `"append/1 — Clock integration"` describe block with frozen clock test verifying `event.occurred_at == frozen` after `Clock.Frozen.freeze/1`.
- `test/mailglass/errors/batch_failed_test.exs`: New `"format_message/2 — ME-02 regression"` describe block with three tests: failed_count from context, non-empty failures in context does not raise FunctionClauseError, all_failed count from context.

## Verification Results

```
grep "DateTime.utc_now" lib/mailglass/events.ex     → 0 matches (ME-01 closed)
grep "Clock.utc_now" lib/mailglass/events.ex        → 1 match
grep 'fn 0 ->' lib/mailglass/errors/batch_failed.ex → 0 matches (ME-02 closed)
grep "String\.to_atom(" lib/mailglass/outbound.ex   → 0 matches (ME-03 closed)
grep "String.to_existing_atom" outbound.ex          → 5 matches
grep ":exit, reason" projector.ex                   → 1 match (ME-04 closed)
grep "Map.get(dispatch_result.provider_response"    → 0 matches (ME-05 closed)
grep "defp provider_tag" lib/mailglass/outbound.ex  → 2 matches
grep -c "rewrite_if_enabled" outbound.ex            → 3 (Plan 08 wiring preserved)
mix test --only phase_03_uat                        → 62 tests, 0 failures
mix compile --warnings-as-errors                    → clean
mix compile --no-optional-deps --warnings-as-errors → clean
```

## Deviations from Plan

### Auto-fixed Issues

None — plan executed exactly as written with one structural addition.

**1. [Rule 2 - Enhancement] Extracted build_rehydrated_message/2 private helper**
- **Found during:** Task 2 (ME-03)
- **Issue:** The plan's target structure duplicated ~10 lines of Swoosh.Email assembly across both resolution branches of `rehydrate_message/1`
- **Fix:** Extracted `defp build_rehydrated_message/2` to avoid duplication; both branches call the helper
- **Files modified:** `lib/mailglass/outbound.ex`
- **Commit:** 745cad4

**2. [Rule 1 - Bug] ME-02 RED test needed ctx[:failures] inside context map, not opts[:failures]**
- **Found during:** Task 1 TDD RED phase
- **Issue:** Initial test passed `failures: [%{id: "abc"}]` as a top-level opt; `format_message` receives `opts[:context]` not opts directly, so `ctx[:failures]` was nil and `length(nil || []) = 0` — `fn 0 ->` matched, test passed in RED unexpectedly
- **Fix:** Updated test to pass `context: %{count: 3, failed_count: 1, failures: [%{id: "abc"}]}` — now `ctx[:failures]` is non-empty, triggering the actual `FunctionClauseError`
- **Files modified:** `test/mailglass/errors/batch_failed_test.exs`
- **Commit:** d5d6461

## Known Stubs

None — all fixes are complete with no placeholders or TODOs.

## Threat Flags

None — all threat mitigations from the plan's STRIDE register are applied:
- T-3-12-01 (atom exhaustion via String.to_atom on DB string) — mitigated by ME-03
- T-3-12-02 (:exit from PubSub shutdown propagating to Task worker) — mitigated by ME-04
- T-3-12-03 (BadMapError from non-map provider_response) — mitigated by ME-05
- T-3-12-04 (wall-clock timestamps despite frozen test clock) — mitigated by ME-01

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| lib/mailglass/events.ex | FOUND |
| lib/mailglass/errors/batch_failed.ex | FOUND |
| lib/mailglass/outbound.ex | FOUND |
| lib/mailglass/outbound/projector.ex | FOUND |
| test/mailglass/events_test.exs | FOUND |
| test/mailglass/errors/batch_failed_test.exs | FOUND |
| .planning/phases/03-transport-send-pipeline/03-12-SUMMARY.md | FOUND |
| commit d5d6461 (test RED) | FOUND |
| commit e9fb86f (fix ME-01+ME-02) | FOUND |
| commit 745cad4 (fix ME-03) | FOUND |
| commit 1d7c9bb (fix ME-04+ME-05) | FOUND |
