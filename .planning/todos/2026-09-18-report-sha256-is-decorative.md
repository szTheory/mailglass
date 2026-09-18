---
created: 2026-09-18T00:00:00.000Z
title: "report_sha256 in coverage baselines is cited as provenance but never verified"
area: controls
files:
  - config/coverage_baselines/*.json (report_sha256 field)
  - scripts/check_coverage_floor.sh (does not read it)
priority: next
origin: 166-REVIEW.md WR-02, carried via .planning/phases/166-*/deferred-items.md
---

## Problem

`report_sha256` is recorded in the coverage baseline files and cited as
provenance in SUMMARY prose, but **neither `scripts/check_coverage_floor.sh`
nor any test reads or verifies it**. It is a digest that proves nothing.

This is precisely the v2.8 theme — data presented as proof that proves nothing —
so it should not survive the milestone uninspected.

## Fix (pick one)

- Verify the digest at floor-check time, making the field load-bearing; or
- Stop citing it as evidence and remove it.

Do not leave it decorative and cited.

## Why it was not fixed in 166

It touches the Phase 166-01 coverage baseline contract rather than any control
Phase 166 was chartered to fix.
