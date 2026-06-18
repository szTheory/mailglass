---
quick_id: 260617-tgw
description: Fix-or-retire persistently-red Core Full Suite Advisory lane
status: complete
date: 2026-06-18
---

# Quick Task 260617-tgw — Summary

Resolved thread `release-pipeline-maintenance.md` item 5. **Decision: FIX (quarantine), not retire.**
The `Core Full Suite Advisory` lane is now **green** on main (commit `abadbb32`; Advisory Matrix run
on the fix SHA = both jobs success).

## Diagnosis

- Lane runs `mix test --warnings-as-errors` (the complete core suite). Latest red run:
  **`1191 tests, 9 failures`** — memory's "~57 Oban failures" was stale.
- All 9 failures were in **5 maintainer dev-tooling modules**, zero in `lib/`:
  `ReferenceHost.{CompileSmoke,WebhookOperatorPath,TrustRunnerCheckpointContract}Test`,
  `DemoDataTest`, `Publish.PostPublishSmokeContractTest`.
- **Root cause = environment mismatch:** they need the full repo workspace (sibling `MailglassInbound`
  compiled, `reference/host_app` + `demo_app` with fetched deps). The isolated-core lane never sets
  that up → they fail structurally (and identically locally); never green in CI.

## Why FIX not RETIRE

The required green lanes run only narrow curated file lists (`verify.support_contract.core` = 11
files; provider-compat ≈ 11). Of 157 core test files, the bulk (renderer, outbound, most of
`test/mailglass/**`) run **only** in this advisory lane. Retiring would silently drop the only CI
coverage of ~120 lib test files. So the lane has real value — it was just polluted by 9 structurally-
unrunnable dev tests.

## Change (commit `abadbb32`)

- `@moduletag :requires_workspace` (with rationale comment) on the 5 modules.
- `--exclude requires_workspace` (+ explanatory comment) on the advisory lane in
  `.github/workflows/advisory-matrix.yml`.
- The excluded behaviors are already covered in CI by the Trust Lane / Demo Browser Evidence /
  publish-hex post-publish-smoke lanes → no real coverage lost.

## Validation

- Local: `mix test <5 modules> --exclude requires_workspace` → 13 excluded, 0 failures; renderer
  suite 20/20 green with the exclude.
- CI: Advisory Matrix run `27730447059` on `abadbb32` → **Core Full Suite Advisory: success**
  (+ Provider Compatibility: success). Lane is now a meaningful green canary for the ~1180 lib tests.

## Considered + rejected

- **Retire the lane** — loses ~120 lib test files' only CI coverage.
- **Set up the full workspace in the lane** — high CI complexity + demo_app swoosh-lock-drift
  footgun; overkill for an advisory lane.

## Durable note

`Core Full Suite Advisory` is the ONLY CI lane running the complete core `mix test`; required lanes
run curated subsets. Keep new `:requires_workspace`-class dev tests tagged so the lane stays green.
