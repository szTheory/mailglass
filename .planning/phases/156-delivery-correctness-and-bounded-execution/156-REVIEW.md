---
phase: 156-delivery-correctness-and-bounded-execution
reviewed: 2026-08-17T07:09:26Z
depth: deep
files_reviewed: 54
files_reviewed_list:
  - docs/api_stability.md
  - lib/mailglass/adapters/swoosh.ex
  - lib/mailglass/application.ex
  - lib/mailglass/errors/send_error.ex
  - lib/mailglass/optional_deps/oban.ex
  - lib/mailglass/outbound.ex
  - lib/mailglass/outbound/async_adapter.ex
  - lib/mailglass/outbound/async_adapter/task_supervisor.ex
  - lib/mailglass/outbound/worker.ex
  - lib/mailglass/rate_limiter.ex
  - lib/mailglass/rate_limiter/atomic_bucket.ex
  - lib/mailglass/rate_limiter/table_owner.ex
  - lib/mailglass/tracking/plug.ex
  - lib/mailglass/webhook/provider_name.ex
  - lib/mailglass/webhook/replay.ex
  - mailglass_inbound/lib/mailglass_inbound/application.ex
  - mailglass_inbound/lib/mailglass_inbound/execution.ex
  - mailglass_inbound/lib/mailglass_inbound/execution/worker.ex
  - mailglass_inbound/lib/mailglass_inbound/rate_limiter.ex
  - mailglass_inbound/lib/mailglass_inbound/rate_limiter/table_owner.ex
  - mailglass_inbound/test/mailglass_inbound/async_execution_test.exs
  - mailglass_inbound/test/mailglass_inbound/ingress/persist_test.exs
  - mailglass_inbound/test/mailglass_inbound/mailbox_execution_test.exs
  - mailglass_inbound/test/mailglass_inbound/rate_limiter_test.exs
  - mailglass_inbound/test/mailglass_inbound/worker_test.exs
  - test/mailglass/adapters/swoosh_test.exs
  - test/mailglass/application_test.exs
  - test/mailglass/error_test.exs
  - test/mailglass/outbound/deliver_later_test.exs
  - test/mailglass/outbound/deliver_many_test.exs
  - test/mailglass/outbound/telemetry_test.exs
  - test/mailglass/outbound/worker_test.exs
  - test/mailglass/rate_limiter_test.exs
  - test/mailglass/rate_limiter_supervision_test.exs
  - test/mailglass/tracking/plug_test.exs
  - test/mailglass/webhook/replay_test.exs
  - lib/mailglass/migration.ex
  - lib/mailglass/migration_generator.ex
  - lib/mailglass/migrations/legacy_toy.ex
  - lib/mailglass/migrations/postgres.ex
  - lib/mix/tasks/mailglass.gen.migration.ex
  - mailglass_inbound/lib/mix/tasks/mailglass.inbound.gen.migration.ex
  - mailglass_inbound/test/mix/tasks/mailglass_inbound_replay_test.exs
  - test/example/README.md
  - test/mailglass/publish/post_publish_smoke_contract_test.exs
  - test/support/installer_fixture_helpers.ex
  - scripts/consumer_install_smoke.sh
  - scripts/generated_ecto_host_proof.sh
  - mailglass_inbound/lib/mailglass_inbound/migration.ex
  - mailglass_inbound/test/mix/tasks/mailglass_inbound_gen_migration_test.exs
  - test/mailglass/install/install_first_preview_smoke_test.exs
findings:
  critical: 1
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 156: Code Review Report

**Reviewed:** 2026-08-17T07:09:26Z
**Depth:** deep
**Files Reviewed:** 54
**Status:** issues_found

## Summary

The prior Phase 156 durable-route review remains clean: evidence authority is atomic and tenant-bound, job tampering is rejected, legacy jobs cancel safely, and no atom/PII/transaction regression was introduced.

The Plan 06 owner-serialized fallback restores the missing-table path, serializes admission, and reinserts a taken tuple on its normal result paths. Both the CAS and owner transitions now use a monotonic effective clock, preserve `last_seen` and fractional remainder across a regression, and continue to cap tokens correctly. Stale CAS callers lose their replacement and re-read the reinserted tuple; lifecycle call failures stay bounded and fail closed. No new limiter defect was found. Focused core limiter tests pass (18 tests), and the combined inbound limiter/execution suite passed five consecutive runs (35 tests each).

Final CI-closure changes were also reviewed at deep depth. The Oban gateway now selects Oban's documented four-argument `Multi` overload (`Oban.insert_all(Oban, multi, name, jobs)`), preserving a single transaction rather than using the synchronous insertion contract. The migration changes only make the declared finite version and `:ok` result contracts match established runtime behavior. The installer fixture explicitly scopes its temporary repository configuration and restores the process-global setting. The inbound replay test now provides the same durable router/mailbox binding that production ingress persists; route resolution remains finite and atom-safe. No correctness, security, optional-dependency, or migration regression was found in this delta.

The new repo-bound generated wrappers correctly pass their selected host Repo into both install and upgrade directions, and the consumer smoke's random database is scoped to its generated host. However, the separate generated-Ecto-host proof was not updated for the changed generated source and now rejects the valid wrappers before it can migrate them.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Generated-host CI proof rejects the newly generated repo-bound wrappers

**File:** `scripts/generated_ecto_host_proof.sh:144-145`

**Issue:** Commit `d7c5031c` changes generator output to `Mailglass.Migration.up(repo: Host.Repo)` and `MailglassInbound.Migration.up(repo: Host.Repo)`, but this required CI proof still requires the exact zero-argument text `Mailglass.Migration.up()` / `MailglassInbound.Migration.up()`. Those `rg` checks fail immediately for every newly generated host, so the `Generated Ecto host proof` step in the required `Installer Host Smoke` job exits before `mix ecto.migrate`. This makes main CI red and prevents the new adopter-smoke path from certifying the behavior it was intended to cover.

**Fix:** Update the assertions to check the repo-bound calls (ideally the exact `Host.Repo` wrappers) and add a regression test covering the proof/source contract. For example:

```bash
if ! rg -q 'Mailglass\.Migration\.up\(repo: Host\.Repo\)' "${migrations_path}"/*_mailglass_install.exs ||
    ! rg -q 'MailglassInbound\.Migration\.up\(repo: Host\.Repo\)' "${migrations_path}"/*_mailglass_inbound_install.exs; then
  echo "Generated wrappers did not delegate to both public package façades with Host.Repo." >&2
  exit 1
fi
```

---

_Reviewed: 2026-08-17T07:09:26Z_
_Reviewer: gsd-code-reviewer_
_Depth: deep_
