---
phase: 03-transport-send-pipeline
plan: "04"
subsystem: mailable-behaviour-tracking
tags: [mailable, tracking, guard, auth-stream, behaviour, macro, tdd]
dependency_graph:
  requires:
    - phase-01-core
    - phase-02-persistence-tenancy
    - 03-01 (Message.mailable_function, ConfigError atoms, Tenancy)
    - 03-02 (Adapters.Fake, FakeFixtures stub)
    - 03-03 (RateLimiter, Suppression, Stream preflight)
  provides:
    - Mailglass.Mailable behaviour + __using__ macro (AUTHOR-01)
    - Mailglass.Message.new_from_use/2, update_swoosh/2, put_function/2
    - Mailglass.Tracking.enabled?/1 (TRACK-01)
    - Mailglass.Tracking.Guard.assert_safe!/1 (D-38)
    - FakeFixtures.TestMailer + TrackingMailer using real use macro
    - api_stability.md §Mailable + §Message Helpers + §Tracking sections
  affects:
    - Plan 05 Outbound.send/2 — calls Guard.assert_safe!/1 as precondition
    - Plan 06 Tracking.Rewriter — reads Tracking.enabled?/1 per mailable
    - Phase 5 admin — discovers mailables via function_exported?(__mailglass_mailable__, 0)
    - Phase 6 Credo TRACK-02 — AST-inspects @mailglass_opts attribute
tech_stack:
  added: []
  patterns:
    - "defmacro __using__ + quote bind_quoted + @before_compile injection pattern"
    - "behaviour_info(:optional_callbacks) OTP API for optional callback verification"
    - "Code.ensure_loaded/1 before function_exported? for async-safe module probing"
    - "@compile {:no_warn_undefined, Module} injected into using modules for forward refs"
    - "Regex.match? on Atom.to_string/1 for auth-stream function name guard"
key_files:
  created:
    - lib/mailglass/mailable.ex
    - lib/mailglass/tracking.ex
    - lib/mailglass/tracking/guard.ex
    - test/mailglass/mailable_test.exs
    - test/mailglass/tracking/guard_test.exs
    - test/mailglass/tracking/default_off_test.exs
    - test/mailglass/tracking_test.exs
  modified:
    - lib/mailglass/message.ex (new_from_use/2, update_swoosh/2, put_function/2)
    - test/support/fake_fixtures.ex (upgraded from stub to real use macro)
    - docs/api_stability.md (§Mailable, §Message Helpers, §Tracking)
decisions:
  - "Injection uses import Swoosh.Email, except: [new: 0] to avoid conflict with injected new/0"
  - "Tracking.fetch_from_mailable/1 calls Code.ensure_loaded/1 before function_exported? — async test isolation: compiled .beam files are loaded lazily; function_exported? returns false before load in concurrent test processes"
  - "Test 7 (injection line count) uses Code.string_to_quoted + AST walk rather than calling __using__ as a function — macros are not callable at runtime as regular functions"
  - "Test 9 (optional_callbacks) uses behaviour_info(:optional_callbacks) — the correct OTP API; module_info(:attributes)[:optional_callbacks] returns nil in Elixir"
  - "@compile {:no_warn_undefined, Mailglass.Outbound} injected into using modules to suppress forward-ref warnings until Plan 05 ships Outbound"
  - "render/3 default injects Mailglass.Renderer.render(msg) ignoring template and assigns (I-10 option b locked) — template resolution is adopter-owned; override via defoverridable"
metrics:
  duration: "25min"
  completed: "2026-04-23"
  tasks: 2
  files_created: 7
  files_modified: 3
---

# Phase 3 Plan 04: Mailable behaviour + Tracking Guard Summary

**One-liner:** `use Mailglass.Mailable` macro (≤20 AST forms, 12 actual) with `@mailglass_opts` reflection, `__mailglass_mailable__/0` admin marker, and `Mailglass.Tracking.Guard.assert_safe!/1` D-38 runtime auth-stream enforcement raising `%ConfigError{type: :tracking_on_auth_stream}`.

## What Shipped

### Mailglass.Mailable behaviour + `__using__/1` macro (AUTHOR-01)

**Behaviour callbacks:**

```elixir
@callback new() :: Mailglass.Message.t()
@callback render(Mailglass.Message.t(), atom(), map()) ::
            {:ok, Mailglass.Message.t()} | {:error, Mailglass.TemplateError.t()}
@callback deliver(Mailglass.Message.t(), keyword()) ::
            {:ok, term()} | {:error, Mailglass.Error.t()}
@callback deliver_later(Mailglass.Message.t(), keyword()) ::
            {:ok, term()} | {:error, Mailglass.Error.t()}
@optional_callbacks preview_props: 0
@callback preview_props() :: [{atom(), map()}]
```

**Injection (12 top-level AST forms — budget ≤20 per LINT-05, target 15 per D-09):**

1. `@behaviour Mailglass.Mailable`
2. `@before_compile Mailglass.Mailable`
3. `@mailglass_opts opts`
4. `@compile {:no_warn_undefined, Mailglass.Outbound}`
5. `import Swoosh.Email, except: [new: 0]`
6. `import Mailglass.Components`
7. `def __mailglass_opts__/0`
8. `def new/0`
9. `def render/3`
10. `def deliver/2`
11. `def deliver_later/2`
12. `defoverridable new: 0, render: 3, deliver: 2, deliver_later: 2`

**`@before_compile` hook** injects `__mailglass_mailable__/0 :: true` — the Phase 5
admin dashboard discovery marker.

**`__mailglass_opts__/0` reflection** — compile-time bridge read by:
- Phase 6 Credo TRACK-02 (AST inspection)
- Phase 3 `Mailglass.Tracking.Guard.assert_safe!/1` (runtime)
- Phase 5 admin preview (discovering mailable opts for the UI)

### Mailglass.Message helpers

Three new helpers ship alongside the macro (needed to make the adopter pattern ergonomic):

- `new_from_use/2` — called by injected `new/0`; seeds `%Message{}` from `use` opts + `Tenancy.current/0`
- `update_swoosh/2` — applies a transformation to the inner `%Swoosh.Email{}`; canonical adopter pipe pattern
- `put_function/2` — stamps `:mailable_function` field; required for D-38 Guard to fire

### FakeFixtures upgraded

`test/support/fake_fixtures.ex` now uses the real `use Mailglass.Mailable` macro:

- `TestMailer` — `stream: :transactional`, no tracking opts, `welcome/1` + `password_reset/1`
- `TrackingMailer` — `stream: :operational, tracking: [opens: true, clicks: true]`, `campaign/1`

Both fixtures call `Message.update_swoosh/2` + `Message.put_function/2` — the canonical adopter pattern.

### Mailglass.Tracking facade (TRACK-01)

`enabled?/1` reads `module.__mailglass_opts__()` and returns `%{opens: boolean, clicks: boolean}`.
Pixel injection and link rewriting are deferred to Plan 06 (`Mailglass.Tracking.Rewriter`).

**Code.ensure_loaded/1 call** — required before `function_exported?` in async test contexts.
Compiled `.beam` files are loaded lazily by the BEAM VM; `function_exported?` returns false for
an unloaded module even if the `.beam` exists. This was caught during Task 2 RED phase.

### Mailglass.Tracking.Guard (D-38)

`assert_safe!/1` closes the gap between Phase 6 Credo (static AST) and runtime metaprogramming:

- Regex: `^(magic_link|password_reset|verify_email|confirm_account)` — prefix match
- `nil mailable_function` → `:ok` (T-3-04-01 accepted; Credo primary for this case)
- Error context: `%{mailable: module_atom, function: fun_atom}` — PII-free (T-3-04-03 verified)

### api_stability.md extensions

Three new sections:
- `§Mailable` — behaviour callbacks, use opts vocabulary, injection budget, __mailglass_opts__/0 + __mailglass_mailable__/0 contracts, defoverridable surface
- `§Message Helpers` — new_from_use/2, update_swoosh/2, put_function/2
- `§Tracking` — enabled?/1 return contract, Guard.assert_safe!/1 locked contract, regex lock, dual-enforcement architecture

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] import Swoosh.Email conflicts with injected new/0**
- **Found during:** Task 1 compilation
- **Issue:** `import Swoosh.Email` imports `Swoosh.Email.new/0`, which conflicts with the injected `def new/0` in the using module.
- **Fix:** Changed to `import Swoosh.Email, except: [new: 0]`.
- **Files modified:** `lib/mailglass/mailable.ex`
- **Commit:** 074a28c

**2. [Rule 1 - Bug] Test 7 + Test 11 called __using__ as a runtime function**
- **Found during:** Task 1 test execution
- **Issue:** `__using__` is a macro — calling `Mailglass.Mailable.__using__(opts)` at runtime raises `UndefinedFunctionError`.
- **Fix:** Test 7 rewrote to use `Code.string_to_quoted` + AST walk to count injection forms. Test 11 rewrote to check `function_exported?(SampleMailer, :component, 2)` + source parsing for the quote block body.
- **Files modified:** `test/mailglass/mailable_test.exs`
- **Commit:** 074a28c

**3. [Rule 1 - Bug] Test 9 used wrong API for @optional_callbacks**
- **Found during:** Task 1 test execution
- **Issue:** `module_info(:attributes)[:optional_callbacks]` returns `nil` in Elixir; `@optional_callbacks` is processed by the compiler into OTP's `behaviour_info/1` mechanism, not stored as a module attribute.
- **Fix:** Changed to `Mailglass.Mailable.behaviour_info(:optional_callbacks)` which returns `[preview_props: 0]`.
- **Files modified:** `test/mailglass/mailable_test.exs`
- **Commit:** 074a28c

**4. [Rule 1 - Bug] Moduledoc contained "import Phoenix.Component" string failing acceptance grep**
- **Found during:** Task 1 acceptance criteria check
- **Issue:** The moduledoc section "Does NOT inject" contained the literal string `import Phoenix.Component`, causing `grep -q "import Phoenix.Component"` to match the file.
- **Fix:** Rewrote the moduledoc to say "`Phoenix.Component` — adopters opt in per-mailable by importing it themselves." Removes the literal `import Phoenix.Component` string from the file.
- **Files modified:** `lib/mailglass/mailable.ex`
- **Commit:** 074a28c

**5. [Rule 1 - Bug] Tracking.enabled?/1 returned false in async tests**
- **Found during:** Task 2 test execution
- **Issue:** `function_exported?(TrackingMailer, :__mailglass_opts__, 0)` returned `false` when run in `async: true` tests alongside other tests. The module IS compiled but the BEAM VM loads `.beam` files lazily; `function_exported?` returns false before the module is loaded into the calling process's namespace in concurrent execution contexts.
- **Fix:** Added `Code.ensure_loaded(mailable)` call at the start of `fetch_from_mailable/1` before the `function_exported?` check.
- **Files modified:** `lib/mailglass/tracking.ex`
- **Commit:** dc932ea

## Open Question Resolution

**Renderer.render/3 signature (I-10 — option b locked):** The injected `render/3` ignores both `template` and `assigns` and delegates to `Mailglass.Renderer.render(msg)` (Phase 1 single-arity). Template resolution is adopter-owned — adopters call `Message.update_swoosh/2` to build the `%Swoosh.Email{}` before calling `deliver/2`. This keeps the injection budget tight and aligns with Phase 5 admin preview calling `Renderer.render/1` directly.

## Known Stubs

None — all fixtures now use the real `use Mailglass.Mailable` macro. The `@tag skip: "Plan 05 ships Mailglass.Outbound"` on Test 12 in mailable_test.exs is intentional deferred coverage, not a correctness stub.

## Threat Flags

None — all T-3-04-xx threats were evaluated during implementation:
- T-3-04-01 (nil mailable_function bypass): documented and tested (Test 10)
- T-3-04-03 (PII in ConfigError context): verified PII-free via Tests 6-7

## Self-Check: PASSED

Files created/present:
- lib/mailglass/mailable.ex ✓
- lib/mailglass/tracking.ex ✓
- lib/mailglass/tracking/guard.ex ✓
- test/mailglass/mailable_test.exs ✓
- test/mailglass/tracking/guard_test.exs ✓
- test/mailglass/tracking/default_off_test.exs ✓
- test/mailglass/tracking_test.exs ✓

Commits:
- 074a28c: feat(03-04): Mailglass.Mailable behaviour + __using__ macro + @before_compile ✓
- dc932ea: feat(03-04): Tracking facade + Guard auth-stream runtime enforcement ✓
