# Phase 13 Plan 04 Summary

## Outcome

Rehearsed the `0.2.0` release mechanics on the pinned Release Please v4 path, removed the stale prepublish allowlist surprise, and documented `workflow_dispatch` from the reviewed release tag as the canonical fallback when publish or smoke do not fan out automatically.

## Completed Work

- Refreshed `.planning/publish/mailglass-files.expected` so the core package allowlist matches the shipped v0.2 surface instead of failing on stale entries.
- Hardened `mix mailglass.publish.check` so the `mailglass_admin` package verifies in published-mode isolation locally, making the release-day prepublish command authoritative for both sibling packages.
- Recorded exact rehearsal evidence in `.planning/phases/13-v0-2-release-ceremony/13-04-REHEARSAL.md`:
  - `gh release view v0.2.0` returned `release not found`
  - successful publish rehearsal run: `24963219717`
  - downstream smoke failure evidence showing the old `VERSION=main` problem: `24963360022`
- Updated the release workflow comments and maintainer runbook to lock the `0.2.0` fallback contract:
  - stay on Release Please v4 for this cut
  - review the generated release PR diff before merge
  - if release fan-out fails, dispatch `publish-hex` from `mailglass-v0.2.0`
  - if smoke fan-out fails, dispatch `post-publish-smoke` from that same tag

## Commits

- `41e9c02` `fix(13-04): refresh prepublish gate for v0.2 surface`
- `b8d05ce` `docs(13-04): record release rehearsal fallback contract`

## Verification

Required prepublish verification:

```bash
mix mailglass.publish.check --package mailglass && mix mailglass.publish.check --package mailglass_admin
```

Result:

- passed

Required rehearsal artifact verification:

```bash
test -f .planning/phases/13-v0-2-release-ceremony/13-04-REHEARSAL.md
rg -n "^Rehearsal ref: .+" .planning/phases/13-v0-2-release-ceremony/13-04-REHEARSAL.md
rg -n "^Release Please run URL: https://github.com/.+/actions/runs/[0-9]+" .planning/phases/13-v0-2-release-ceremony/13-04-REHEARSAL.md
rg -n "^Publish rehearsal run URL: https://github.com/.+/actions/runs/[0-9]+" .planning/phases/13-v0-2-release-ceremony/13-04-REHEARSAL.md
rg -n "^Outcome: (automatic-trigger-confirmed|workflow_dispatch-fallback-required)$" .planning/phases/13-v0-2-release-ceremony/13-04-REHEARSAL.md
rg -n "^Fallback decision: (automatic release chain|workflow_dispatch for 0.2.0)$" .planning/phases/13-v0-2-release-ceremony/13-04-REHEARSAL.md
rg -n "workflow_dispatch|fallback|release PR diff" MAINTAINING.md .github/workflows/release-please.yml .github/workflows/publish-hex.yml .github/workflows/post-publish-smoke.yml
```

Result:

- passed

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking issue] `mailglass_admin` local prepublish isolation did not match publish-mode dependency behavior**
- **Found during:** Task 1 verification
- **Issue:** `mix mailglass.publish.check --package mailglass_admin` could fail locally in the temp compile/audit path even though the CI publish workflow uses `MIX_PUBLISH=true`.
- **Fix:** Updated `lib/mix/tasks/mailglass.publish.check.ex` so prod deps, isolated compile, and audit runs consistently use published-mode dependency resolution for `mailglass_admin`.
- **Files modified:** `lib/mix/tasks/mailglass.publish.check.ex`
- **Commit:** `41e9c02`

## Residual Blocker For 13-05

No technical blocker remains from 13-04. The only residual risk for 13-05 is operational: if the real `0.2.0` release event does not fan out automatically, the maintainer must use the rehearsed `workflow_dispatch` fallback from `mailglass-v0.2.0` for publish and smoke.
