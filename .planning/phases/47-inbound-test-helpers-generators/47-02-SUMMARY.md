---
phase: 47-inbound-test-helpers-generators
plan: 02
subsystem: testing
tags: [igniter, sourceror, mix-task, generators, codemod, inbound, scaffolding]

# Dependency graph
requires:
  - phase: 39-41 (mailglass_inbound v1.1)
    provides: MailglassInbound.Router DSL (route/2 + @route_schema), MailglassInbound.Mailbox behaviour (process/1, :accept outcome)
  - phase: 47-01 (parallel, Wave 1)
    provides: MailglassInbound.MailboxCase (referenced as string-template text only; not needed at build time)
provides:
  - mix mailglass.gen.inbound_route (idempotent Sourceror-zipper route insertion + shared add-route helper)
  - mix mailglass.gen.inbound_router (new router scaffold with use + sample route)
  - mix mailglass.gen.mailbox (mailbox + route stub via shared helper + MailboxCase test stub)
affects: [50-inbound-documentation-pass, inbound DX parity, adopter onboarding]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Idempotent Sourceror-zipper route insertion via move_to_function_call_in_current_scope + argument_equals?"
    - "Shared public add-route helper on the route generator, reused by the mailbox generator (no duplicated zipper logic)"
    - "Test-module FooTest last-segment suffix to keep Igniter from relocating .exs test stubs"

key-files:
  created:
    - lib/mix/tasks/mailglass.gen.inbound_route.ex
    - lib/mix/tasks/mailglass.gen.inbound_router.ex
    - lib/mix/tasks/mailglass.gen.mailbox.ex
    - test/mix/tasks/mailglass.gen.inbound_route_test.exs
    - test/mix/tasks/mailglass.gen.inbound_router_test.exs
    - test/mix/tasks/mailglass.gen.mailbox_test.exs
  modified: []

key-decisions:
  - "gen.mailbox test stub uses the FooTest last-segment suffix (not Foo.Test) so Igniter does not relocate the .exs into a nested directory"
  - "Test-file path derived from the source location (lib/ -> test/, .ex -> _test.exs), computed before create_module for order-independence"
  - "Dry-run write-suppression is Igniter's CLI-layer contract; the self-tests assert --dry-run is an accepted, harmless global flag that still computes the diff (not in any schema)"

patterns-established:
  - "Shared idempotent add-route helper: gen.inbound_route exposes add_route/4 + route_already_present?/2 + router_module/2 as the single insertion path; gen.mailbox reuses them"
  - "Missing-router handling: find_and_update_module {:error, _} -> Igniter.add_notice telling the user to run gen.inbound_router first (no auto-create)"

requirements-completed: [IGEN-01, IGEN-02, IGEN-03, IGEN-04]

# Metrics
duration: 11min
completed: 2026-05-23
---

# Phase 47 Plan 02: Inbound Igniter Generators Summary

**Three core Igniter generators — gen.inbound_route (idempotent Sourceror-zipper route insertion), gen.inbound_router (router scaffold), gen.mailbox (mailbox + route stub + MailboxCase test stub) — with the dup-scan add-route helper shared between route and mailbox generators.**

## Performance

- **Duration:** ~11 min
- **Started:** 2026-05-23T21:09:16Z
- **Completed:** 2026-05-23T21:20:00Z
- **Tasks:** 3 (all TDD: RED -> GREEN)
- **Files created:** 6

## Accomplishments

- `mix mailglass.gen.inbound_route <pattern> <Mailbox>` appends a `route/2` to an existing router idempotently. The dup-scan uses `Igniter.Code.Function.move_to_function_call_in_current_scope/4` + `argument_equals?/3`; insertion uses `Igniter.Code.Common.add_code/3` with the keyword `placement: :after` form. A second run produces no change (verified by run-twice `assert_unchanged`).
- Single-statement router bodies (only `use MailglassInbound.Router`) are handled: `add_code` promotes the single-child do-block, the route lands AFTER the `use`, and the result parses as valid Elixir (Pitfall 4 covered).
- `mix mailglass.gen.inbound_router <Module>` scaffolds a new router with `use MailglassInbound.Router` and a sample `route/2` that matches `@route_schema`.
- `mix mailglass.gen.mailbox <Module>` scaffolds: (1) a mailbox with `@behaviour MailglassInbound.Mailbox` + a default `process/1` returning the neutral `:accept` (no auth heuristics); (2) a route stub via the shared add-route helper; (3) a test stub that `use MailglassInbound.MailboxCase`. A missing router emits an actionable "run mix mailglass.gen.inbound_router first" notice instead of crashing.
- The dup-scan + add-route logic is factored into the route generator's public `add_route/4`, `route_already_present?/2`, `router_module/2`, `route_code/2`, and `parse_module/1` — gen.mailbox calls `InboundRoute.add_route/4` rather than re-implementing the zipper edit.
- `--dry-run` works for all three as Igniter's free global switch (it is NOT in any task's option schema).

## Task Commits

Each task was committed atomically (TDD test -> feat):

1. **Task 1: gen.inbound_route** - `c25c91c` (test) -> `cb846c2` (feat)
2. **Task 2: gen.inbound_router** - `9aeae4f` (test) -> `6e8036b` (feat)
3. **Task 3: gen.mailbox** - `ca0c1ce` (test) -> `7dc9af5` (feat)

_TDD gate sequence intact: each feature has a `test(...)` commit before its `feat(...)` commit._

## Files Created/Modified

- `lib/mix/tasks/mailglass.gen.inbound_route.ex` - Idempotent route insertion + shared add-route helper (`add_route/4`, `route_already_present?/2`, `router_module/2`, `route_code/2`, `parse_module/1`).
- `lib/mix/tasks/mailglass.gen.inbound_router.ex` - New-router scaffold (`use MailglassInbound.Router` + sample route).
- `lib/mix/tasks/mailglass.gen.mailbox.ex` - Mailbox + route stub (via shared helper) + MailboxCase test stub; missing-router notice.
- `test/mix/tasks/mailglass.gen.inbound_route_test.exs` - Idempotency run-twice `assert_unchanged`, single-statement-body, no-double-insert, dry-run cases.
- `test/mix/tasks/mailglass.gen.inbound_router_test.exs` - Scaffold-shape, bare-name resolution, parse-shape, dry-run cases.
- `test/mix/tasks/mailglass.gen.mailbox_test.exs` - Mailbox shape, MailboxCase test stub, route-stub-via-helper, idempotency, missing-router notice, dry-run cases.

## Decisions Made

- **Test-stub module naming (`FooTest`, not `Foo.Test`):** During Task 3, `Igniter.create_new_file` was relocating the test stub from `support_test.exs` to `support/_test.exs` because the in-content module name `Test.Inbound.Support.Test` drove Igniter's path normalization. Switched the generated test module to the conventional last-segment suffix (`Test.Inbound.SupportTest`), which keeps the file at the expected `_test.exs` path and matches standard ExUnit/Phoenix convention.
- **Test path derived from source location, computed before `create_module`:** to be order-independent against the rewrite mutations that `create_module/3` introduces.
- **Dry-run self-tests assert "accepted + diff computed", not "no in-memory source":** In the `Igniter.Test` harness, `--dry-run` does not suppress the in-memory rewrite (suppression happens at the real-disk-write layer in `Igniter.do_or_dry_run`). The honest, passing assertion is that `--dry-run` is a recognized global flag that does not break the task and still produces the intended diff; the "writes nothing" guarantee is Igniter's framework contract, satisfied structurally by keeping `dry_run` out of every schema.

## Deviations from Plan

None - plan executed exactly as written. All three generators, the shared helper, the idempotency/single-statement/dry-run/missing-router self-tests, and the `placement: :after` keyword form match the plan's tasks and acceptance criteria. The two implementation decisions above (test-module naming, test-path derivation) are routine generator-correctness details within the plan's "template contents are Claude's Discretion" (D-47) latitude, not scope changes.

## Issues Encountered

- **Igniter test-stub path relocation (resolved):** see Decisions Made above — fixed by using the `FooTest` last-segment module suffix.
- **Worktree dep environment:** the worktree had no `deps`/`_build`; ran `mix deps.get` (resolved to the locked Igniter 0.8.0 / rewrite 1.3.0 / sourceror 1.12.0). The pre-existing `mailglass.gen.mailable_test.exs` fails under this dep set because it relies on a custom `assert_file_content` helper that calls `Rewrite.source!` after `apply_igniter!` — a pre-existing breakage from the Igniter 0.8 upgrade, out of scope for this plan. My new self-tests use the official `Igniter.Test` helpers (`apply_igniter!` + `assigns.test_files`, `assert_unchanged`, `diff/2`, `apply_igniter` notices) and pass cleanly.

## Threat Model Compliance

- **T-47-05 (Tampering — arbitrary code into router):** mitigated. `add_code` builds a structured `route/2` AST node from `route(Mailbox, recipient: ...)`; module/recipient args flow through `Module.concat` / `inspect`, never eval.
- **T-47-06 (Tampering — double-insert corruption):** mitigated. Idempotent dup-scan via `move_to_function_call_in_current_scope` + `argument_equals?`; run-twice `assert_unchanged` self-tests pass.
- **T-47-07 (Tampering — single-statement body):** mitigated. `add_code` single-child block promotion; explicit single-statement-body self-test asserts route-after-use + parse-shape.
- **T-47-08 (generated mailbox unsafe defaults):** accepted (LOW). Generated `process/1` returns neutral `:accept`, no auth heuristics.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- IGEN-01..04 satisfied; inbound scaffolding now has parity with outbound's `mix mailglass.gen.mailable`.
- The three generators are ready to be documented in Phase 50 (Inbound Documentation Pass) and referenced by adopter onboarding guides.
- No blockers. Note for the orchestrator: the pre-existing `mailglass.gen.mailable_test.exs` failure under Igniter 0.8 / rewrite 1.3 is a separate, pre-existing item (custom `assert_file_content` helper relying on removed `Rewrite.source!` semantics) and is unrelated to this plan.

## Self-Check: PASSED

All 6 created files exist on disk; all 7 commits (6 task commits + SUMMARY) exist in git history.

---
*Phase: 47-inbound-test-helpers-generators*
*Completed: 2026-05-23*
