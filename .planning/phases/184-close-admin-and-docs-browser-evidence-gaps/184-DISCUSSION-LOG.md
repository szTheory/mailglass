# Phase 184: Close Admin and docs browser evidence gaps - Discussion Log

> **Audit trail only.** Decisions are captured in `184-CONTEXT.md`.

**Date:** 2026-11-18
**Phase:** 184-Close Admin and docs browser evidence gaps
**Areas discussed:** Candidate route, browser/runtime strategy, scope and stops

---

## Candidate route

| Option | Description | Selected |
|--------|-------------|----------|
| Up to three gap plans | Separate plans for several existing phases | |
| One scoped closure plan | One Phase 184 plan and one new candidate route | ✓ |
| Preserve the cap | Leave the observed code and evidence gaps open | |

**Owner's choice:** Authorize scoped candidate route and follow the recommendation.
**Notes:** Exactly one Phase 184 plan; keep Phase 182-07 blocked and unchanged.

## Browser/runtime strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Add or update dependencies and browser images | Expand package/runtime surface | |
| Reuse pinned browsers and fix runtime seams | Keep versions and use existing Docker browser path | ✓ |
| Skip browser evidence | Leave current journey and same-output contracts unverified | |

**Owner's choice:** Follow the recommended bounded route.
**Notes:** Diagnose preview target creation without retries or weakened assertions; use supported Node for the Admin runner; preserve Phase 174's Node 18 / Playwright 1.60 contract.

## Scope and stops

**Selected:** One exact-SHA hosted dispatch, only after local preflights. Require all CI gates, formal cost receipt, test-count match, and +5 minute wall / +10 minute runner ceilings before preview. Preserve the favicon recapture stop and prohibit merge, release, deploy, tag, or archive.

## The agent's discretion

Select the smallest code and workflow changes that satisfy the approved boundaries and existing project patterns.

## Deferred ideas

None.

## Recovery authorization after the 184-01 stop

**Date:** 2026-11-18

**Owner's choice:** Follow the recovery recommendation and authorize one additional Phase 184 plan and fresh candidate route.

**Scope:** Add plan 184-02 only, increasing the v2.11 cap from 25 to 26. First create/test the evidence verifier, capture complete baselines, and prove a no-install/no-pull candidate-owned read-only dependency snapshot. Then allow one exact-SHA push and dispatch, with the existing +5 minute wall / +10 minute runner ceilings and preview only if all phase gates pass.

**Stops preserved:** Do not retry or change the 184-01 route; no further plan/route, retry/rerun, cost overage, favicon capture, Phase 182-07 reopening, owner-WIP edits, or owner-demo disturbance.
