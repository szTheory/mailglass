---
created: 2026-09-18T00:00:00.000Z
title: "support_contract_admin runs the 510-test admin suite twice"
area: ci
files:
  - .github/workflows/ci.yml (support_contract_admin job)
priority: later
origin: 166-REVIEW.md WR-04, carried via .planning/phases/166-*/deferred-items.md
---

## Problem

The admin suite runs once via `verify.support_contract.admin` and again under
the coverage step. Wasteful, and it doubles the flake surface of a **required**
job.

Not a correctness defect — deprioritized accordingly.

## Note before changing it

Related: the admin lane is already known to be an allow-list running only 185
of 510 admin tests (see v2.8 req GREEN-01). Settle the coverage question and
the double-run together rather than separately — they touch the same job.
