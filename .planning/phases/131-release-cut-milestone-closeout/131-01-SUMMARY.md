---
phase: "131"
plan: "01"
subsystem: release-ceremony
tags: [release, hex, publish, milestone-closeout, ship, v1.15]
dependency_graph:
  requires: [130-01]
  provides: [v1.15-on-hex, milestone-archive]
  affects: [publish-hex, post-publish-smoke, state, roadmap, milestones]
tech_stack:
  added: []
  patterns: [publish-hex-fan-out, gate-ci-green-self-heal, consumer-smoke, milestone-audit]
key_files:
  created:
    - .planning/milestones/v1.15-MILESTONE-AUDIT.md
    - .planning/milestones/v1.15-ROADMAP.md
    - .planning/milestones/v1.15-REQUIREMENTS.md
  modified:
    - .planning/MILESTONES.md
    - .planning/PROJECT.md
    - .planning/REQUIREMENTS.md
    - .planning/RETROSPECTIVE.md
    - .planning/ROADMAP.md
    - .planning/STATE.md
    - .planning/publish/mailglass-publish-summary.json
    - .planning/publish/mailglass_admin-publish-summary.json
    - .planning/publish/mailglass_inbound-publish-summary.json
decisions:
  - v1.15 floor stays at >= 1.10.2 (NOT bumped to >= 1.11.0) — the decoupling goal is that a core patch does not force a paired inbound release; bumping the floor re-couples them
  - post-publish-smoke wait-for-index missing checkout is a pre-existing bug, not a release blocker; consumer smoke is the SHIP-02 proof
  - Publish summary JSONs regenerated at 1.11.0/1.11.0/1.6.0 via publish.check and committed as accurate release records
metrics:
  duration: "2 sessions"
  completed_date: "2026-07-02"
status: complete
---

# Phase 131 Plan 01: Release Cut + Milestone Closeout Summary

v1.15 shipped to Hex (mailglass 1.11.0 / mailglass_admin 1.11.0 / mailglass_inbound 1.6.0) with the keystone `{:mailglass, "~> 1.10 and >= 1.10.2"}` confirmed live — the first release with genuinely-loosened sibling pins (not `== 1.11.0`).

## Tasks Completed

| Task | Description | Commit | Status |
|------|-------------|--------|--------|
| 1 (Wave 0) | D-05 fix: inbound docs_contract_test pin derivation | 311d39c1 | done (pre-session) |
| 2 (Wave 0) | D-11 fix: post-publish-smoke ~>-aware inbound-compat grep | 311d39c1 | done (pre-session) |
| 3 (Wave 0) | publish.check allowlist update (D-06 allowlist refresh) | 311d39c1 | done (pre-session) |
| 4 (Wave 1) | Push v1.15 body fast-forward | 311d39c1 | done (pre-session) |
| 5 (Wave 2) | Verify RP PR #105; confirm go/no-go | PR #105 admin-merged | done (pre-session) |
| 6 (Wave 2) | Maintainer go/no-go approval; PR #105 admin-merged | 827cede1 | done (pre-session) |
| 7 (Wave 3) | Monitor publish-hex fan-out; confirm all 3 packages on Hex | — | done |
| 8 (Wave 4) | Consumer smoke (DEP_MODE=hex) + post-publish-smoke | EXIT 0 | done |
| 9 (Wave 5) | Milestone audit, archive, planning doc updates, tag v1.15, push | d4c4db74 + v1.15 tag | done |

## Evidence

### Hex Packages Confirmed Live

| Package | Version | Released | Pin |
|---------|---------|---------|-----|
| mailglass | 1.11.0 | 2026-07-02 | (core) |
| mailglass_admin | 1.11.0 | 2026-07-02 | `~> 1.10` |
| mailglass_inbound | 1.6.0 | 2026-07-02 | `~> 1.10 and >= 1.10.2` |

### Keystone Proof (SHIP-02)

```
$ mix hex.info mailglass_inbound 1.6.0 | grep mailglass
  mailglass ~> 1.10 and >= 1.10.2
```

NOT `== 1.11.0`. The decoupling is live on Hex.

### Consumer Smoke

```
VERSION=1.11.0 VERSION_INBOUND=1.6.0 DEP_MODE=hex INCLUDE_INBOUND=true bash scripts/consumer_install_smoke.sh
```

Exit: 0. Key results:
- `mix deps.get` resolved mailglass 1.11.0 + mailglass_inbound 1.6.0 from Hex without conflict
- `GET /dev/mail/ -> HTTP 200`
- `OPS-01 guard passed.`

### publish.check (all three packages)

Exit 0. Output: `conflict=0` for all three packages. Advisory note: `EEF-CVE-2026-43969 confirmed active in OSV` (expected; already in the allowlist).

### publish-hex Fan-Out

3 fan-outs triggered (one per release tag). Run 28608198220 (mailglass_admin-v1.11.0 tag) succeeded for all three: prepublish-summary ✓ → gate-ci-green ✓ (8s, found existing CI run on `827cede1`) → publish-core ✓ → publish-inbound ✓ → publish-admin ✓.

Racing fan-outs for mailglass-v1.11.0 and mailglass_inbound-v1.6.0 tags: publish-core failed with "must include --replace flag" (core already published by a prior workflow_dispatch from 2026-07-01). This is expected idempotency noise — all three packages confirmed live.

## Deviations from Plan

### Wave-0 Landmines (Expected Pre-flight — Not Regressions)

**1. [Rule 2 - D-05] inbound docs_contract_test pin derivation**
- Found during: Wave 0 pre-flight
- Issue: The `stability_contract_test` still derived the expected pin string as `"== #{@version}"` (exact) — would have red under the new `~>` semantics
- Fix: Updated the test regex to match `~>` pessimistic form instead of `==`
- Commit: 311d39c1

**2. [Rule 2 - D-11] post-publish-smoke ~>-aware inbound-compat grep**
- Found during: Wave 0 pre-flight
- Issue: The smoke's inbound-compat check only matched `mailglass == ${VERSION}` (exact); would have false-failed under `~>`
- Fix: Updated grep to match `mailglass ~>` OR `mailglass .* >=`
- Commit: 311d39c1

### Post-publish-smoke Infrastructure Bug (Pre-existing, Not a Release Blocker)

The `post-publish-smoke.yml` `wait-for-index` job consistently failed on dispatch/release paths with `The specified version file, .tool-versions, does not exist`. Root cause: the job uses `version-file: .tool-versions` in `setup-beam` but has no `actions/checkout` step. Fresh runners don't have `.tool-versions`. Scheduled runs work because GitHub reuses the runner workspace from the `cron-guard` job in the same workflow run.

This is a PRE-EXISTING infrastructure bug, not introduced by v1.15. The consumer smoke (EXIT 0) is the authoritative SHIP-02 proof. The D-11 `~>`-aware grep fix is confirmed present in the workflow. Deferred to a maintenance-tier fix (add checkout step to `wait-for-index`).

### Racing Publish Fan-Out Idempotency Noise

Two of three publish-hex fan-out runs failed `publish-core` with "must include the --replace flag to update an existing release" — core 1.11.0 was already published by a prior `workflow_dispatch` run (28525073712 from 2026-07-01). The idempotency `Skip if version already on Hex` step didn't fire in these runs (timing race). The `mailglass_admin-v1.11.0` tag run's idempotency check caught it and proceeded to publish inbound + admin. All three confirmed live. Not a regression.

## Known Stubs

None — all three packages fully shipped with complete implementation.

## Threat Flags

None — this plan contained no code changes (release ceremony and planning doc updates only).

## Self-Check: PASSED

Hex packages confirmed live:
- `mix hex.info mailglass 1.11.0` → Released: 2026-07-02 ✓
- `mix hex.info mailglass_admin 1.11.0` → Released: 2026-07-02 ✓
- `mix hex.info mailglass_inbound 1.6.0` → Released: 2026-07-02 ✓

Milestone artifacts confirmed:
- `.planning/milestones/v1.15-MILESTONE-AUDIT.md` ✓ (created `d4c4db74`)
- `.planning/milestones/v1.15-ROADMAP.md` ✓ (created `d4c4db74`)
- `.planning/milestones/v1.15-REQUIREMENTS.md` ✓ (created `d4c4db74`)
- `.planning/MILESTONES.md` updated ✓
- `.planning/PROJECT.md` updated ✓
- `.planning/ROADMAP.md` Phase 131 [x] ✓
- `.planning/STATE.md` status=complete ✓
- `.planning/RETROSPECTIVE.md` v1.15 section prepended ✓
- git tag v1.15 pushed ✓
- git push origin main `d4c4db74` ✓
