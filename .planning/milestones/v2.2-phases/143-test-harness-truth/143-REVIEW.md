---
phase: 143-test-harness-truth
reviewed: 2026-07-31T00:00:00Z
depth: standard
files_reviewed: 51
files_reviewed_list:
  - .github/workflows/advisory-matrix.yml
  - .github/workflows/gate-self-test.yml
  - .github/workflows/publish-hex.yml
  - credo_checks/no_raw_app_env_restore.ex
  - credo_checks/no_raw_sandbox_ownership.ex
  - credo_checks/no_raw_search_path_mutation.ex
  - scripts/assert_gating_toolchain.sh
  - test/mailglass/compliance/unsubscribe_controller_test.exs
  - test/mailglass/compliance/unsubscribe_test.exs
  - test/mailglass/compliance_test.exs
  - test/mailglass/credo/integration_test.exs
  - test/mailglass/credo/no_raw_app_env_restore_test.exs
  - test/mailglass/credo/no_raw_sandbox_ownership_test.exs
  - test/mailglass/credo/no_raw_search_path_mutation_test.exs
  - test/mailglass/demo_data_test.exs
  - test/mailglass/docs_contract_test.exs
  - test/mailglass/mailer_case_test.exs
  - test/mailglass/migration_test.exs
  - test/mailglass/operator/support_summary_test.exs
  - test/mailglass/outbound/deliver_later_test.exs
  - test/mailglass/outbound/deliver_many_test.exs
  - test/mailglass/outbound_test.exs
  - test/mailglass/properties/idempotency_convergence_test.exs
  - test/mailglass/properties/unsubscribe_post_idempotency_property_test.exs
  - test/mailglass/properties/unsubscribe_property_test.exs
  - test/mailglass/properties/webhook_idempotency_convergence_test.exs
  - test/mailglass/properties/webhook_suppression_convergence_test.exs
  - test/mailglass/repo_test.exs
  - test/mailglass/router/unsubscribe_router_test.exs
  - test/mailglass/schema_axis_boot_order_test.exs
  - test/mailglass/schema_isolation_immutability_test.exs
  - test/mailglass/schema_isolation_integration_test.exs
  - test/mailglass/schema_prefix_hardening_test.exs
  - test/mailglass/shipped_migration_divergence_test.exs
  - test/mailglass/test_support/sandbox_ownership_test.exs
  - test/mailglass/test_support/suite_truth_formatter_test.exs
  - test/mailglass/upgrade_v2_schema_migration_test.exs
  - test/mix/tasks/mailglass.gen.unsubscribe_test.exs
  - test/reference_host/trust_runner_checkpoint_contract_test.exs
  - test/scripts/lane_classification_drift_test.exs
  - test/scripts/mechanism_account_contract_test.exs
  - test/scripts/suite_floor_contract_test.exs
  - test/support/ci_lanes.ex
  - test/support/ci_yaml.ex
  - test/support/data_case.ex
  - test/support/mailer_case.ex
  - test/support/sandbox_ownership.ex
  - test/support/suite_floor.ex
  - test/support/suite_truth_formatter.ex
  - test/test_helper.exs
findings:
  critical: 0
  warning: 2
  info: 0
  total: 2
status: issues_found
---

# Phase 143: Code Review Report

**Reviewed:** 2026-07-31T00:00:00Z
**Depth:** standard
**Files Reviewed:** 51
**Status:** issues_found

## Summary

Reviewed the supplied CI workflows, Credo checks, test harness support modules, and affected tests. The sanctioned `search_path` helper introduces an SQL-injection-capable construction at the exact seam intended to make search-path changes safe. The gate self-test accepts a zero-minute deadline despite promising positive-only input, causing a resource-creating run that cannot observe its gate.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Search-path values are interpolated directly into SQL

**File:** `test/support/sandbox_ownership.ex:1067`

**Issue:** `with_search_path!/3` inserts the public `search_path` argument directly into a `SET` statement; the restoration at line 1070 repeats the pattern with the database-returned value. A caller can therefore terminate the statement and execute arbitrary SQL, e.g. `"public; DROP SCHEMA public CASCADE; --"`. This is especially risky because this helper is the one Credo explicitly exempts from the raw-search-path rule, so the static guard will not catch unsafe new callers.

**Fix:** Pass the value as a PostgreSQL parameter through `set_config`, which has identical session scope but does not parse user-controlled text as SQL:

```elixir
repo.query!("SELECT set_config('search_path', $1, false)", [search_path])
# ...
repo.query!("SELECT set_config('search_path', $1, false)", [prior])
```

Add a regression test using a value containing a semicolon and assert it is treated as one search-path value (or rejected), never executed as a second statement.

### WR-02: Zero-minute deadlines bypass the promised preflight validation

**File:** `.github/workflows/gate-self-test.yml:60-73`

**Issue:** The validation describes `deadline_minutes` as a positive integer but accepts `0`. The workflow then creates and pushes the synthetic-failure branch and draft PR before the polling loop computes `DEADLINE=$((SECONDS + 0))`; the loop never executes and the self-test fails as `never-appeared`. This creates remote resources and a red workflow without ever observing the selected check, contrary to the workflow's fail-closed probe contract.

**Fix:** Reject zero before any branch/PR creation:

```sh
if [ "$DEADLINE_MINUTES" -lt 1 ] || [ "$DEADLINE_MINUTES" -gt "$MAX" ]; then
  echo "ERROR: deadline_minutes must be between 1 and ${MAX}." >&2
  exit 1
fi
```

---

_Reviewed: 2026-07-31T00:00:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
