---
phase: 150-private-envelope-and-atomic-durable-enqueue
reviewed: 2026-08-02T20:21:00Z
depth: standard
files_reviewed: 29
files_reviewed_list:
  - docs/api_stability.md
  - guides/getting-started.md
  - guides/jobs.md
  - guides/production-go-live-checklist.md
  - lib/mailglass/application.ex
  - lib/mailglass/config.ex
  - lib/mailglass/migrations/postgres.ex
  - lib/mailglass/migrations/postgres/v06.ex
  - lib/mailglass/optional_deps.ex
  - lib/mailglass/optional_deps/oban.ex
  - lib/mailglass/outbound.ex
  - lib/mailglass/outbound/envelope.ex
  - lib/mailglass/outbound/payload.ex
  - lib/mailglass/outbound/worker.ex
  - lib/mix/tasks/mailglass.upgrade.v2_schema.ex
  - test/mailglass/application_test.exs
  - test/mailglass/config_test.exs
  - test/mailglass/core_send_integration_test.exs
  - test/mailglass/docs_contract_test.exs
  - test/mailglass/docs_migration_smoke_test.exs
  - test/mailglass/migration_test.exs
  - test/mailglass/outbound/deliver_later_test.exs
  - test/mailglass/outbound/deliver_many_test.exs
  - test/mailglass/outbound/envelope_test.exs
  - test/mailglass/outbound/worker_test.exs
  - test/mailglass/test_support/sandbox_ownership_test.exs
  - test/mailglass/upgrade_v2_schema_migration_test.exs
  - test/support/mailer_case.ex
  - test/support/sandbox_ownership.ex
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
status: clean
---

# Phase 150: Code Review Report

**Reviewed:** 2026-08-02T20:21:00Z
**Depth:** standard
**Files Reviewed:** 29
**Status:** clean (fixed in review-fix iteration 1)

## Summary

The two Critical findings from this review were fixed in review-fix iteration 1. See `150-REVIEW-FIX.md` for the changes, commits, and verification record.

## Narrative Findings (AI reviewer)

## Resolved Critical Issues

### CR-01: Mailglass schema prefix is incorrectly forced onto Oban jobs

**Status:** fixed — `31062190`

**File:** `/Users/jon/projects/mailglass/lib/mailglass/outbound.ex:431-440`  
**Issue:** The durable multi passes `Repo.multi_opts()` to `Oban.insert/4`. That adds `prefix: Mailglass.Config.schema()` (normally `"mailglass"`) to the Oban insert. Oban merges passed options over its own configured prefix, so a normal Oban instance configured with its default `"public"` prefix attempts to write `mailglass.oban_jobs`, a table Mailglass never creates and that Oban's poller does not read. The advertised default production configuration passes readiness but every enqueue rolls back. This was reproduced with `MAILGLASS_SCHEMA=mailglass mix test test/mailglass/outbound/deliver_later_test.exs:187 --warnings-as-errors`, which returned the adapter failure/rollback.

**Fix:** Do not pass Mailglass persistence options to Oban. Keep `Repo.multi_opts()` on Delivery/Event/Payload steps only, and invoke the gateway without a `prefix` override so Oban uses its own configured prefix:

```elixir
|> Mailglass.OptionalDeps.Oban.insert(:job, fn %{delivery: d} ->
  Mailglass.Outbound.Worker.new(%{
    "delivery_id" => d.id,
    "mailglass_tenant_id" => tenant_id
  })
end)
```

Add a durable enqueue integration test on the non-public `MAILGLASS_SCHEMA=mailglass` axis with Oban left at its normal public prefix.

### CR-02: Oban-absent durable sends crash instead of returning the typed fail-closed error

**Status:** fixed — `7fd2a06c`

**File:** `/Users/jon/projects/mailglass/lib/mailglass/outbound.ex:379`  
**Issue:** `Mailglass.Outbound.Worker` is conditionally compiled only when `Oban.Worker` is present, but this line calls `Mailglass.Outbound.Worker.queue()` before `OptionalDeps.Oban.ready?/1` can detect that Oban is absent. In a `--no-optional-deps` build the Worker module does not exist, so the default `:oban` path raises `UndefinedFunctionError` rather than returning `{:error, %Mailglass.SendError{context: %{reason_class: :dependency_unavailable}}}`. That violates the documented fail-closed return contract.

**Fix:** Keep the canonical queue identity in a module that is always compiled (or use the literal atom at this call site) and pass it to the gateway without touching the conditional worker:

```elixir
with :ok <- Mailglass.OptionalDeps.Oban.ready?(:mailglass_outbound) do
  enqueue_oban(rendered, adapter_ref, opts)
end
```

Add a no-optional-dependencies runtime test that invokes `deliver_later/2` with `:oban` selected and asserts the typed `:dependency_unavailable` error.

---

_Reviewed: 2026-08-02T20:21:00Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
