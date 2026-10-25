---
created: 2026-10-24T00:00:00.000Z
title: Playwright specs write screenshots straight into committed .planning phase evidence
area: testing
files:
  - mailglass_admin/e2e/flows.spec.js:24 (writes 168 gap-closure PNGs)
  - mailglass_admin/e2e/structural.spec.js:2467 (writes 168 review-fix PNGs)
  - mailglass_admin/e2e/phase169-journey.spec.js:9 (writes 169 artifacts/after PNGs)
  - reference/demo_app/assets/e2e/demo.spec.js (writes 172 browser-evidence PNGs via the compose bind mount)
priority: backlog
---

## Problem

Any local e2e run overwrites frozen, committed phase evidence with renders of the current UI.
On 2026-10-24 the tidy-up found 29 such PNGs under phases 168/169 silently modified (heights
changed, e.g. delivery-720 1899→2002px) and had to restore them with `git checkout`.

## Fix direction

Write captures to an ignored output directory by default (`tmp/` or Playwright `outputDir`),
and copy into `.planning/phases/*/artifacts/` only when an explicit env var such as
`MAILGLASS_CAPTURE_PHASE_EVIDENCE=<phase>` is set. Archived phases must never be write targets.
