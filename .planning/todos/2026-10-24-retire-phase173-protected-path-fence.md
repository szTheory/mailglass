---
created: 2026-10-24T00:00:00.000Z
title: Retire the Phase 173 protected-path fence machinery
area: ci-cd
files:
  - scripts/check_phase173_candidate.sh (pathspec exclusions, sparse-checkout rules, deliverable skips)
  - scripts/test_check_phase173_candidate.sh (sparse/dockerignore/skip contract + mutations)
  - .dockerignore (final two "Protected demo inputs" rules)
priority: after-v2.9-merge
---

## Context

Phase 173 fenced `reference/demo_app/README.md` and `reference/demo_app/assets/e2e/demo.spec.js`
because they held uncommitted owner edits. The owner lifted the fence on 2026-10-24; both files
are committed (8a6a1b95) and the demo browser CI wrapper runs the full Playwright suite again.

The candidate gate still sparse-excludes the two files. While the gate exists that is useful
(demo.spec.js would otherwise write 172 evidence PNGs into the clean candidate and fail its
cleanliness check — see the e2e-evidence todo), so the fence was left in place deliberately.

## Fix

When the Phase 173 candidate gate is retired with the v2.9 archive (or the e2e-evidence todo is
fixed), delete the sparse rules, pathspec exclusions, deliverable skips, the two `.dockerignore`
rules, and the matching contract assertions/mutations in one commit.
