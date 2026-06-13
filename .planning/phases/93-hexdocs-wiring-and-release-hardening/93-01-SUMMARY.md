---
phase: 93-hexdocs-wiring-and-release-hardening
plan: "01"
subsystem: brand-adoption
tags: [hexdocs, ex_doc, svg, brand, docs]
dependency_graph:
  requires: [91-folder-adoption, 92-surface-propagation]
  provides: [HEXD-01, HEXD-02]
  affects: [mix.exs, mailglass_admin/mix.exs, mailglass_inbound/mix.exs, brandbook/assets/]
tech_stack:
  added: []
  patterns: [ex_doc logo/favicon relative-path, SVG explicit width/height for ex_doc 0.40.x]
key_files:
  created: []
  modified:
    - brandbook/assets/logo-mark.svg
    - brandbook/assets/favicon.svg
    - mix.exs
    - mailglass_admin/mix.exs
    - mailglass_inbound/mix.exs
decisions:
  - "D-02: Added width/height directly to canonical SVGs in-place; no duplicate ex_doc-only copies"
  - "D-03: Root package uses brandbook/assets/ (no ../); siblings use ../brandbook/assets/ (with ../)"
  - "D-06: All commits use non-bumping types (docs:); no Hex release cut"
  - "Verified via local mix docs x3 — doc/assets/logo.svg + doc/assets/favicon.svg present in all three build outputs; no new warnings"
  - "Deps resolved per-package using MIX_DEPS_PATH pointing to each sub-package's installed deps dir"
metrics:
  duration: "~35 min"
  completed: "2026-06-13"
  tasks: 3
  files: 5
---

# Phase 93 Plan 01: HexDocs SVG Wiring Summary

**One-liner:** Sealed-flap logo and favicon wired into all three packages' HexDocs configs via ex_doc logo:/favicon: keys pointing to canonical brandbook/ assets with explicit SVG width/height for ex_doc 0.40.x compatibility.

## What Was Built

Two canonical brand SVGs gained the `width`/`height` attributes required by ex_doc 0.40.x, and all three packages' `docs/0` configs gained `logo:` and `favicon:` keys pointing to those assets via correct relative paths. A local `mix docs` build for each package confirmed the sealed-flap mark and favicon appear in `doc/assets/` with no new warnings.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Add explicit width/height to canonical brand SVGs | 57192111 | brandbook/assets/logo-mark.svg, brandbook/assets/favicon.svg |
| 2 | Add logo/favicon keys to all three docs/0 configs | 7f8f3044 | mix.exs, mailglass_admin/mix.exs, mailglass_inbound/mix.exs |
| 3 | Prove logo+favicon render via local mix docs x3 | (verification only — no source changes) | — |

## Verification Results

- **Root package:** `mix docs` exits 0; `doc/assets/logo.svg` + `doc/assets/favicon.svg` present; no new warnings
- **Admin package:** `mix docs` exits 0; `mailglass_admin/doc/assets/logo.svg` + `doc/assets/favicon.svg` present; no new warnings
- **Inbound package:** `mix docs` exits 0; `mailglass_inbound/doc/assets/logo.svg` + `doc/assets/favicon.svg` present; no new warnings (pre-existing hidden-module cross-ref warnings are unchanged)
- `reference/demo_app/mix.lock` — no drift introduced
- Generated `doc/` output not staged in any commit

## Deviations from Plan

None — plan executed exactly as written.

The only operational note: each sub-package required `MIX_DEPS_PATH` pointing to its own installed deps directory (the worktree has no local `deps/`). This is an environment detail, not a deviation from plan intent.

## Known Stubs

None. All three docs/0 configs reference the real canonical brand assets; the relative paths resolve correctly from each package dir in the monorepo checkout.

## Threat Flags

None. No new network endpoints, auth paths, file access patterns, or schema changes introduced. T-93-02 (`:files` allowlist accidentally widened) confirmed mitigated — no `:files` line changed in any diff. T-93-03 (new mix docs warning) confirmed mitigated — zero new warning lines in all three build logs attributable to these changes.
