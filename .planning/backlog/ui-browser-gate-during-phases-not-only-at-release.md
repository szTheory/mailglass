# Backlog seed: run the real UI browser/persona gate during phases, not only at release

> **Origin.** Surfaced by the v1.14 release post-mortem (2026-06-30). This is a
> **method/process improvement** for future admin-UI milestones, to be folded into
> the next UI milestone's verification method when one opens. Not a product feature.

## Problem (what went wrong in v1.14)

The entire v1.14 body (128 commits) was built on local `main` and **never pushed
/ CI'd** until the release ceremony. Phases 119–123 repeatedly **deferred** the
browser/persona re-shoots ("demo unrunnable in-env", cached evidence, D-17
fallback) and signed surfaces off green on that cached basis.

The release push was the **first real CI run** of the redesign and immediately
surfaced **7 Operator Browser Gate failures** — 2 genuine a11y regressions
(preview backdrop `aria-pressed`, inbound reveal ARIA disclosure), 3 stale specs,
and 1 CI-only Linux-Chromium gallery overflow. None of these were caught during
the phases that introduced them, because the gate that catches them was never run.
This turned the release ceremony into a multi-cycle debug + fix-forward marathon.

## Goal

Make the operator browser gate (and persona re-shoots) a **per-phase verification
gate**, not a release-time afterthought — so UI regressions are caught in the
phase that introduces them, and the release gate is a confirmation, not a
discovery.

## Candidate scope (decide when the next UI milestone opens)

- Make `cd mailglass_admin && npx playwright test --config=playwright.config.cjs
  --workers=1` (the operator browser gate) a **required** check in each UI phase's
  verification, with the demo/operator server bootable in-env (it IS bootable
  locally — `OperatorBrowserServer` auto-boots via the playwright webServer; the
  phases' "demo unrunnable in-env" assumption was wrong/avoidable).
- Resolve the "demo unrunnable in-env" baseline-drift blocker (the thing that kept
  pushing persona re-shoots to D-17 fallback) so persona evidence is fresh, not cached.
- Consider a lightweight pre-release "first real CI on the body" checkpoint (push
  the body to a branch and run full CI) **before** the release ceremony, so the
  ceremony never doubles as the first integration test.

## Already proven

The gate reproduces locally and is fast (~1.7 min, 160 tests). The v1.14 recovery
demonstrated the whole loop works in-env — the gap was process (deferral), not
capability.

## Context

`.planning/threads/v1.14-release-paused-dep-security-wave.md`,
`.planning/debug/resolved/operator-browser-gate-v114.md`,
`.planning/milestones/v1.14-MILESTONE-AUDIT.md`. Surface via `/gsd-review-backlog`
when the next admin-UI milestone is scoped.
