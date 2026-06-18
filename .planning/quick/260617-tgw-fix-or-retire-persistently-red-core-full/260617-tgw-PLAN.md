---
quick_id: 260617-tgw
description: Fix-or-retire persistently-red Core Full Suite Advisory lane
status: in-progress
date: 2026-06-18
---

# Quick Task 260617-tgw: Fix-or-retire `Core Full Suite Advisory` lane

## Objective

Resolve thread `release-pipeline-maintenance.md` item 5: the
`Core Full Suite Advisory (Elixir 1.18 / OTP 27)` lane (in `advisory-matrix.yml`)
is red on essentially every push/PR. A permanently-red advisory lane = zero signal
and masks real regressions. Decide fix-or-retire and make the lane mean something.

## Investigation

- Lane runs `mix test --warnings-as-errors` (the **complete** core suite).
- Latest run: **`1191 tests, 9 failures`** (memory's "~57 Oban failures" was stale).
- All 9 failures are in **5 maintainer dev-tooling modules**, zero in `lib/`:
  - `Mailglass.ReferenceHost.CompileSmokeTest`
  - `Mailglass.ReferenceHost.WebhookOperatorPathTest` (×4 — `MailglassInbound.* :nofile`)
  - `Mailglass.ReferenceHost.TrustRunnerCheckpointContractTest` (×2)
  - `Mailglass.DemoDataTest` (shells out to `reference/demo_app`)
  - `Mailglass.Publish.PostPublishSmokeContractTest`
- Root cause = **environment mismatch**: these need the full repo workspace
  (sibling `MailglassInbound` compiled, reference/host_app + demo_app with fetched
  deps). The isolated-core lane (`mix deps.get && mix test`) never sets that up, so
  they fail structurally — and they fail identically locally; they have **never**
  been green in CI.
- **Why not just retire?** The required green lanes run only narrow curated file
  lists (`verify.support_contract.core` = 11 files; provider-compat ≈ 11 files). Of
  157 core test files, the bulk (renderer, outbound, most of `test/mailglass/**`)
  run **only** in this advisory lane. Retiring would drop the only CI coverage of
  ~120 lib test files.

## Decision: FIX (quarantine), not retire

Tag the 5 workspace-only dev-tooling modules `@moduletag :requires_workspace` and add
`--exclude requires_workspace` to the advisory lane. Their behaviors are already
covered in CI by dedicated green lanes (Trust Lane, Demo Browser Evidence, publish-hex
post-publish-smoke), so no real coverage is lost; the lane now runs the ~1180 real lib
tests as a meaningful green canary.

(Considered + rejected: setting up the full workspace in the lane — high CI complexity
+ demo_app swoosh-lock-drift footgun, overkill for an advisory lane.)

## Tasks

1. Add `@moduletag :requires_workspace` (with rationale comment) to the 5 modules;
   add `--exclude requires_workspace` + explanatory comment to `advisory-matrix.yml`.
   - verify: `mix test <5 modules> --exclude requires_workspace` → all excluded, 0 fail;
     a normal lib test still runs green. ✓ (done: 13 excluded, renderer 20/20)
   - done: committed `abadbb32`.
2. Push to main; confirm the `Core Full Suite Advisory` lane goes **green**.
   - verify: Advisory Matrix run for the fix SHA = success.
   - done: lane green → thread item 5 closeable.
