---
created: 2026-11-02
source: Phase 178 Cycle 08–09 CI efficiency review; owner standing rule to optimize observed CI
status: open
title: Select expensive CI lanes by changed surface
area: ci-cd
priority: follow-up
---

# Select expensive CI lanes by changed surface

## Evidence

Cycle 08 CI run [41490274664](https://github.com/szTheory/mailglass/actions/runs/41490274664) used 113.53 runner-minutes and took 17m11s end to end. Its longest jobs were Operator Browser Gate (16m54s, including 14m16s in the browser suite), Core Deterministic Suite (15m27s), and Demo Browser Evidence (15m12s, including 15m in evidence capture).

Advisory Matrix run [41490274743](https://github.com/szTheory/mailglass/actions/runs/41490274743) used 34.42 runner-minutes. Its two Core Full Suite schema jobs consumed 26 runner-minutes and completed before the required CI run ended.

The changed-path gate in `.github/workflows/ci.yml` currently emits only a broad `code` flag. A genuinely inbound-only change could avoid the Operator Browser and Demo Browser lanes and skip the Core Full Suite schema advisory matrix, saving about 58 runner-minutes. On the measured CI run this would save only about 72 seconds of wall time because the required Core Deterministic Suite remains on the critical path.

The current Phase 178 PR already includes UI changes from earlier commits. Its acceptance also requires browser evidence on the exact candidate SHA, so these lanes must run for this candidate.

## Additional Cycle 09 findings

Cycle 09's PR CI run took 18m01 and used 119.12 runner-minutes; the exact-SHA dispatch took 18m58 and used 117.18. `CI Green` itself completed 4m48 and 4m33 sooner than the saved baseline, while the full two-run owner-review sequence plus its six small/advisory workflows used 267.60 runner-minutes. The measured 8.43/6.50 runner-minute per-CI-run overages are supported only for that preapproved UI review cycle; they do not change ordinary budgets.

The Operator Browser Gate took 18m41 end to end. Playwright reports a 14.6-minute test suite and calls out `e2e/structural.spec.js` at 5.6 minutes, with a recommendation to parallelize slow files. Review whether that file's tests are isolated before splitting it or enabling test-level parallelism; measure wall and runner time without dropping assertions.

The Operator log has 110 PostgreSQL `role "root" does not exist` messages at ten-second intervals. `.github/workflows/ci.yml` uses bare `pg_isready` for Postgres health checks in 12 service definitions. Confirm that this is the source, then set the health-check user explicitly (likely `-U postgres`) and verify the service still becomes healthy with no repeated auth errors. This is a log-noise cleanup; the current lanes passed, and no runtime saving is claimed.

These are follow-up changes only. Cycle 09 reached its eight-workflow cap, so no workflow edits or additional runs are part of that candidate.

## Proposed change

Add a fail-closed changed-surface classifier and contract tests. Keep the inbound dual-schema suites for inbound changes. Run the expensive browser lanes whenever UI, admin, Storybook, demo, evidence, shared workflow, or mixed-scope inputs change. Skip the Core Full Suite schema advisory matrix only for a narrowly classified inbound-only change. Scheduled and manual full runs remain complete. Leave the two required branch-protection checks and `ci_green_policy.sh` semantics unchanged.

Test the classifier against inbound-only, UI-only, mixed, workflow, publish-input, docs-only, push, pull-request, and workflow-dispatch cases. A classification uncertainty should run the broader set. Prove that every Phase 178 candidate with UI changes still runs both browser lanes at its exact SHA.

## Acceptance

- The measured runner-minute reduction is confirmed on a truly inbound-only change.
- Required `CI Green` and `Guard Release Trigger` behavior is unchanged.
- UI and mixed changes retain exact-SHA browser evidence; scheduled and manual workflows stay full.
- No new dependency is added.
