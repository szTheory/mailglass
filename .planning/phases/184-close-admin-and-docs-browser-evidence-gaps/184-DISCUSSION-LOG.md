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
