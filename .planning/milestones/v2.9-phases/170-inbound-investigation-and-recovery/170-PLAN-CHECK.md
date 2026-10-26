# Phase 170 Plan Check — Revision at 3924b1d8

## VERIFICATION PASSED

**Phase:** 170 — Inbound Investigation and Recovery  
**Plans verified:** 8  
**Status:** All checks passed

### Coverage Summary

| Requirement | Plans | Status |
|---|---|---|
| INUX-01 — exact Account-scoped selection, return context, and distinct collection/read states | 170-01, 170-08 | Covered |
| INUX-02 — persisted routing/execution evidence, latest-fresh disposition, and current simulation distinction | 170-03, 170-04, 170-05, 170-08 | Covered |
| INUX-03 — progressive, permission-gated, privacy-safe evidence | 170-01, 170-03, 170-08 | Covered |
| INUX-04 — exact replay eligibility, authorization, and truthful outcomes | 170-02, 170-04, 170-05, 170-06, 170-07, 170-08 | Covered |

All four roadmap requirements are present in at least one plan's `requirements` field and have concrete implementing tasks. The 170-08 source audit also maps the phase goal, requirements, research findings, and decisions D-01 through D-18 to plans.

### Decision and architecture compliance

D-16's approved additive `:no_change` callback result is carried through the existing outcome normalization and append-only `ExecutionRun` path, internal replay, read model, Admin filter/badge/timeline, result feedback, and connected journey. Existing outcomes/signatures/schema and the optional-package boundary remain intact; no new dependency is planned.

D-17 is explicitly resolved and implemented by 170-01/170-08: only explicit gateway errors and `DBConnection.ConnectionError` (including queue timeout) become sanitized unavailable states; other exceptions propagate. D-18 is explicitly resolved and implemented by 170-07/170-08: selected lineage is a timestamped snapshot with an explicit native refresh, without polling or a new PubSub event. The remaining locked decisions are represented in tasks, and deferred ideas remain out of scope.

The responsibility map is respected: LiveView owns URL and interaction state, inbound internals own tenant-scoped reads and replay, and Admin owns safe display plus host authorization. Tenant predicates, `Tenancy.scope/2`, schema-prefix handling, current-router simulation labeling, action-time authorization, privacy rules, and accessibility requirements are assigned to the appropriate tasks.

### Plan structure and dependencies

All eight plans pass `verify.plan-structure`. All 16 tasks have files, actions, verification, and measurable done criteria. The dependency graph is acyclic and wave-consistent:

| Plan | Tasks | Wave | Depends on | Status |
|---|---:|---:|---|---|
| 170-01 | 2 | 1 | — | Valid |
| 170-02 | 2 | 1 | — | Valid |
| 170-03 | 2 | 1 | — | Valid |
| 170-04 | 2 | 2 | 170-01, 170-02 | Valid |
| 170-05 | 2 | 3 | 170-01, 170-02, 170-04 | Valid |
| 170-06 | 2 | 4 | 170-01, 170-02, 170-04, 170-05 | Valid |
| 170-07 | 2 | 5 | 170-03, 170-06 | Valid |
| 170-08 | 2 | 6 | 170-01, 170-03, 170-04, 170-05, 170-06, 170-07 | Valid |

The critical links are planned: callback result → persistence → read/render; latest-fresh projection → list/detail; exact durable eligibility → confirmation revalidation → host authorization → tenant-scoped replay; command feedback → separate timeline read/snapshot; and CSS source → committed bundle → rendered evidence. Same-wave plans 170-01/02/03 have no named shared mutable resource with an undeclared writer. Later file overlap is dependency-ordered.

### Scope and validation

Each plan has 2 tasks and an estimate below the 100,000-token budget. Estimates are low-confidence (zero historical samples), so the file counts provide the more useful scope signal. Plan 170-02 has 10 files, but its explicit cohesion rationale shows two five-file tasks supporting one additive callback contract; the estimate is 33% of budget, so this is accepted as bounded scope. Plans 170-04/05 now separate inbound read models from Admin presentation. No plan has 15+ files or 5+ tasks.

Every task has an automated verify command with a non-empty `<fails_when>` statement. Verification includes focused ExUnit checks and filtered Playwright cases. Plan 170-08 Task 2 now lists `mailglass_admin/priv/static/app.css` in both its task files and plan `files_modified`; its command runs the rendered Playwright case followed by the existing token-parity and bundle tests. These targets and the `test:operator-browser` script exist. Sampling is present in every wave; no watch-mode or suspicious error-swallowing patterns were found.

`verify.plan-structure` emits a generic one-way/checkpoint warning for 170-02 Task 1. D-16 explicitly records owner approval of this exact additive outcome and the task's reversibility rationale cites that approval, so there is no unresolved decision checkpoint. The smart-zone checks are below budget for all plans. The project has no `AGENTS.md` or local skill directory.

The phase `COVERAGE.md` remains a one-line note about external API integration; the plan set's 170-08 source audit supplies the requirement/decision traceability and was checked independently.

This was a static plan review. No tests, application, or browser were run. `FAILING_DIRECTIONS` and `VERIFY_PATHS` probe payloads were not included in the review input, so those probe-dependent dimensions were silent per their reference contracts.

### Plan Summary

| Plan | Tasks | Files | Wave | Status |
|---|---:|---:|---:|---|
| 170-01 | 2 | 5 | 1 | Valid |
| 170-02 | 2 | 10 | 1 | Valid; cohesion rationale accepted |
| 170-03 | 2 | 4 | 1 | Valid |
| 170-04 | 2 | 6 | 2 | Valid |
| 170-05 | 2 | 8 | 3 | Valid |
| 170-06 | 2 | 8 | 4 | Valid |
| 170-07 | 2 | 5 | 5 | Valid |
| 170-08 | 2 | 7 | 6 | Valid |

```yaml
issues: []
```

Plans are ready for execution. This is plan-quality approval only; no implementation or runtime validation is claimed.
