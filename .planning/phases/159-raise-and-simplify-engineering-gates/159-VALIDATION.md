---
phase: 159
slug: raise-and-simplify-engineering-gates
status: ready
nyquist_compliant: true
created: 2026-08-17
---
# Phase 159 — Validation Strategy

| Plan | Wave | Requirements | Proof |
|---|---:|---|---|
| 01 | 1 | QUAL-03,04,10 | CI policy fixtures/mutations and lane/parity contracts |
| 02 | 2 | QUAL-01,05,10 | formatter scope mutation, both formatter checks, setup action contract |
| 03 | 3 | QUAL-09 | bidirectional exception registry mutations and focused acknowledgement tests |
| 04 | 4 | QUAL-06 | pinned-toolchain measurement then immutable coverage/critical-path floor tests |
| 05 | 5 | QUAL-07,08 | inbound Dialyzer plus Credo/ignore/ledger mutation tests |
| 06 | 6 | QUAL-03,04,05,10 | complete CI Green inventory and advisory-exclusion negative controls |
| 07 | 7 | QUAL-05,10,11 | workflow/Docker/Dependabot/release-policy parser contracts |

## Wave-zero rules

- Every policy, registry, ledger, formatter scope, setup action, coverage parser,
  and workflow parser gets a deliberate failing fixture before it protects CI.
- Coverage values are absent until an Elixir 1.18/OTP27 canonical run records
  them; test-count floors (`1576/1575`) are never reused as coverage.
- Required job display names remain stable. Browser/demo/preview/provider-live,
  next-toolchain, clean-baseline and publish-only evidence remain advisory.
- No plan may modify `mailglass_admin/lib`, assets, router, LiveViews, or
  operator behavior. Docs/configuration contracts only are allowed if needed.

## Final phase verification

Run all focused contract suites, both package formatter/no-optional/static-analysis commands, the new coverage floor commands, `mix ci`, inbound `mix ci`, workflow-policy/release-policy tests, and `git diff --check`. Phase completion requires CI Green policy fixtures to prove that missing/failed/duplicate required results fail and advisory results cannot pass the aggregate.
