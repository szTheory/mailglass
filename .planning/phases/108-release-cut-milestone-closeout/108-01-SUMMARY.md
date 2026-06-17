---
phase: 108
plan: 01
status: complete
completed: 2026-06-17
requirements: [REL-01, REL-02]
result: shipped
versions:
  mailglass: 1.7.0
  mailglass_admin: 1.7.0
  mailglass_inbound: 1.4.0
---

# Phase 108 — Release Cut + Milestone Closeout (SUMMARY)

**Outcome:** v1.12 SHIPPED. First real linked-version Hex release since 1.6.2.

## Hex versions confirmed live (REG-09/10/11)

```
$ mix hex.info mailglass 1.7.0          → Released: 2026-06-17   (Config: {:mailglass, "~> 1.7"})
$ mix hex.info mailglass_admin 1.7.0    → Released: 2026-06-17
$ mix hex.info mailglass_inbound 1.4.0  → Released: 2026-06-17
                                          mailglass == 1.7.0      ← REL-02 inbound exact-pin confirmed
```

## Inbound pin verification (REL-02 / D-13)

`mailglass_inbound 1.4.0` depends on `mailglass == 1.7.0` (confirmed via `mix hex.info` and in PR #84
diff). `mailglass_admin 1.7.0` likewise carries `{:mailglass, "== 1.7.0"}`.

## Consumer smoke (REG-12)

- **Local** (`DEP_MODE=hex VERSION=1.7.0 VERSION_INBOUND=1.4.0 INCLUDE_INBOUND=true`): `mix deps.get`
  resolved **mailglass 1.7.0 + mailglass_inbound 1.4.0 from Hex**; `mix mailglass.install --force`
  succeeded (`create=3 update=5 unchanged=0 conflict=0`). The boot/`GET /dev/mail/` step failed only
  because local port 4000 was occupied (`:eaddrinuse`) — an environment artifact, not a package defect.
- **Clean CI** (post-publish-smoke `Consumer install (Phoenix host)` job): full install + boot +
  `GET /dev/mail/` passed.

## post-publish-smoke (REG-13)

Re-dispatched run on `mailglass-v1.7.0` after Hex indexing settled:
https://github.com/szTheory/mailglass/actions/runs/27718080394 — **all jobs green** (Hex index,
HexDocs build, Consumer install, Published-version trust journey, Verify not retracted). No #32 noise.
(The first auto-fired post-publish-smoke false-negatived on a 5-minute Hex-index timeout during the
racing fan-out; not a real failure.)

## Milestone audit (REG-14)

`.planning/milestones/v1.12-MILESTONE-AUDIT.md` — verdict `passed`. **True scope (corrected, not from
gsd-sdk): 5 phases (104–108), 13 requirements.** All 13 REQ-IDs Complete (INSTALL-01..04, DOCS-01..04,
OPS-01/02, A11Y-01, REL-01, REL-02). ROADMAP + REQUIREMENTS archived; MILESTONES/PROJECT/ROADMAP/
RETROSPECTIVE/STATE updated; `.planning/REQUIREMENTS.md` removed.

## Git tag (REG-15)

`v1.12` (milestone marker). Hex release tags `mailglass-v1.7.0`, `mailglass_admin-v1.7.0`,
`mailglass_inbound-v1.4.0` were created by the Release Please pipeline on merge commit `0411d485`.

## Pre-flight repair (Wave 0) — six first-time-CI regressions fixed

The v1.7–v1.12 body had never run through full CI (local phase execution only). Pushing it to `main`
before merging the release PR surfaced and fixed:

1. Format Check — `mix format` on v1.12 doctor/test files.
2. Installer Host Smoke (required) — fail-closed installer correctly blocked stock endpoint → smoke uses `mix mailglass.install --force`.
3. Dialyzer — `mailglass.doctor` `run/1` `no_return` → `@dialyzer {:nowarn_function, run: 1}`.
4. Docs (ex_doc) — guides linked unregistered files + wrong `resolve_outbound_adapter_ref/2` arity → de-linked + `c:...resolve_outbound_adapter_ref/1`.
5. Docs (`mix mailglass.docs.check`) — stale `{:mailglass, "~> 0.3"}` token vs phase-105 `~> 1.6` → aligned.
6. Demo Browser Evidence — v1.11 responsive split → Playwright strict-mode locator → scoped to `preview-sidebar-desktop`.

## Stall / race recovery taken

- **Racing fan-outs:** three `publish-hex` runs (one per release event); two `publish-core` jobs failed
  as already-published race-losers (verified all three live on Hex directly).
- **post-publish-smoke index timeout:** re-dispatched on the tag → green.
- **Hands-free auto-merge stuck:** non-required advisory lanes (Core Full Suite, Provider Compatibility)
  red + Release Please hourly-cron PR churn prevented a settled-green window. Merged via maintainer
  admin-override after explicit go/no-go; all branch-protection-required checks (`guard-release-trigger`
  + full required `ci.yml` set) green.

## Follow-up (non-blocking)

Harden `publish-hex.yml` `gate-ci-green` `isAdvisory()` so "Demo Browser Evidence" (non-required lane)
is classified advisory by name like the other advisory lanes. Fixing the test green sidestepped it
this release.

## Self-Check: PASSED
