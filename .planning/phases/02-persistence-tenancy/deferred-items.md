# Phase 02 Deferred Items

## Pre-existing flaky test (found during 02-05 execution)

**File:** `test/mailglass/tenancy_test.exs:116`
**Test:** `behaviour contract — SingleTenant implements @behaviour Mailglass.Tenancy`
**Frequency:** ~1 in 5 runs
**Root cause candidate:** `function_exported?/3` can return `false` when the target module is not yet loaded in the calling process's code cache. The module IS defined (compile-time @impl annotation would have caught a missing scope/2) but `function_exported?` checks loaded state, not definition. Fix: use `Code.ensure_loaded?(Mailglass.Tenancy.SingleTenant) and function_exported?(Mailglass.Tenancy.SingleTenant, :scope, 2)`.
**Scope:** Not touched by Plan 05; pre-exists from Plan 04. Logging here rather than auto-fixing per SCOPE BOUNDARY rule.
