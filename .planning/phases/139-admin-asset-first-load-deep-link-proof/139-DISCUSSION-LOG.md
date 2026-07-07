# Phase 139: Admin asset first-load/deep-link proof - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-07-07T18:22:38-04:00
**Phase:** 139-admin-asset-first-load-deep-link-proof
**Mode:** assumptions
**Areas analyzed:** Mount-Aware Asset Strategy, Route Matrix Proof, Browser Gate

## Assumptions Presented

### Mount-Aware Asset Strategy

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase 139 should preserve the current computed mount-root asset URL path through `MountPathHook` -> `MountPath.base/1` -> `Layouts.css_url/1`, with only narrow hardening/proof changes. | Confident | `.planning/ROADMAP.md`, `.planning/PROJECT.md`, `.planning/backlog/admin-relative-asset-url-styling.md`, `mailglass_admin/lib/mailglass_admin/mount_path_hook.ex`, `mailglass_admin/lib/mailglass_admin/mount_path.ex`, `mailglass_admin/lib/mailglass_admin/layouts.ex`, `mailglass_admin/lib/mailglass_admin/layouts/root.html.heex` |

### Route Matrix Proof

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| The fast proof should expand Conn/LiveView first-HTML assertions across the required route matrix and add test-only alternate mount roots by reusing existing router macros, not by adding public router options. | Likely | `.planning/REQUIREMENTS.md`, `mailglass_admin/test/mailglass_admin/preview_live_test.exs`, `mailglass_admin/lib/mailglass_admin/router.ex`, `mailglass_admin/test/support/endpoint_case.ex` |

### Browser Gate

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| The browser proof should be a targeted Playwright asset-loading gate that fails on CSS/font network failures and checks token-backed computed styles, not screenshots or pixel diffs. | Likely | `.planning/REQUIREMENTS.md`, `mailglass_admin/assets/css/app.css`, `mailglass_admin/lib/mailglass_admin/controllers/assets.ex`, `mailglass_admin/playwright.config.cjs`, `mailglass_admin/e2e/structural.spec.js` |

## Corrections Made

No corrections - all assumptions confirmed. The maintainer response was: "sure".

## External Research

No external research. The codebase and active planning artifacts provided enough evidence for context capture.
