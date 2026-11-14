---
phase: 176-direct-filters-and-useful-inbound-evidence
plan: "16"
subsystem: operator-authorization
tags: [liveview, authorization, account-switch, inbound, deliveries]
dependency_graph:
  requires: [176-14]
  provides: [FILTER-03, INUX-05, pre-handle-params-account-authorization]
  affects: [MailglassAdmin.Operator.Mount, OperatorLive, InboundLive, MailglassAdmin.Auth]
tech_stack:
  added: []
  patterns: [server-side LiveView handle_params lifecycle hook, namespaced socket private state]
key_files:
  created:
    - mailglass_admin/test/mailglass_admin/operator_account_authorization_test.exs
  modified:
    - mailglass_admin/lib/mailglass_admin/operator/mount.ex
    - mailglass_admin/test/support/endpoint_case.ex
    - mailglass_admin/test/mailglass_admin/phase177_prohibition_contract_test.exs
    - mailglass_admin/docs/operator-trust.md
    - mailglass_admin/docs/api_stability.md
decisions:
  - Reuse the existing :operator_access callback and result normalization for changed tenant_id parameters.
  - Capture the trusted operator session in the private hook closure and keep the last approved tenant key in socket private state.
  - Keep activity-derived Account options as navigation data; the host callback remains the Account grant authority.
metrics:
  duration: "8 minutes"
  completed: 2026-11-02
  commits: 0
status: complete
plan_head_before: 2700133fc25b94012e14f14de11cefc0c597f568
plan_head_after: 2700133fc25b94012e14f14de11cefc0c597f568
actuals:
  tokens: 8056
  tasks: 3
  commits: 0
---

# Phase 176 Plan 16: Account-change authorization Summary

The shared operator mount now checks changed `tenant_id` parameters through the existing host authorization callback before either LiveView reads the proposed Account.

## Completed Tasks

1. **Denied Deliveries Account patch tracer:** extracted the existing mount authorization behavior and attached an internal `:handle_params` hook. The failing-first test showed the forbidden patch rendered normal content after an observed query. After the guard was added, the forbidden patch redirects before any query, while an allowed Account patch still reads through the existing connected view.
2. **Both routes and callback contract:** added connected Deliveries and Inbound coverage, including selected/full-detail patch denial, default and custom redirects, stale-auth default messaging, activity-free host-approved Accounts, normalized success shapes, trusted session and actor context, exact callback counts, and absent/blank tenant keys. Same-Account filter, page, and selection patches do not cause another callback.
3. **Trust contract and final gate:** updated operator trust and API stability docs, revised the Phase 177 documentation detector to allow the verified Account-change callback while rejecting blanket patch-time and full `on_mount` claims, then ran the focused and full local test suites.

## Verification

- `mix format` on the four changed Elixir files completed successfully.
- Task 1 red run failed at the expected assertion: the forbidden patch returned rendered content instead of a redirect, after the allowed patch proved the SQL observer was active.
- Account authorization and Phase 177 prohibition tests: **65 passed**.
- Task 2 auth/router/Deliveries/Inbound regression suite: **335 passed**.
- Task 3 authorization/Phase 177 contract and navigation suite: **97 passed**.
- Full Admin suite with seed 0: **1,210 passed, 0 failures, 1 excluded**. The suite emitted expected fault-injection logs and existing deprecation/runtime warnings.
- No browser, Playwright, Docker, hosted CI, or deployment action was run.

## Deviations and Commit Limitation

No implementation deviations. The workspace `.git` directory is read-only in this execution environment, and the parent instruction explicitly limits staging to assigned paths and forbids broadening scope. No task or metadata commit was created; the six assigned source/doc/test files and this summary remain in the working tree. `STATE.md`, `ROADMAP.md`, and `REQUIREMENTS.md` were left untouched to preserve the owner's unrelated work.

## Self-Check: PASSED

All six plan artifacts and this summary are present. The current HEAD still matches the recorded plan start because commits were unavailable under the read-only `.git` boundary; there are no commit hashes to verify.
