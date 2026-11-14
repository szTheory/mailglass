# Phase 180: Reproducible Admin Bundle and Before-Catalog - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-11-14
**Phase:** 180-reproducible-admin-bundle-and-before-catalog
**Mode:** assumptions, with a four-agent fan-out per the owner's research-first brief (CLAUDE.md Decision Policy). No user confirmation round: no strategic fork remained after research, so decisions were locked and documented.
**Areas analyzed:** reproducible generator and drift gate; html-owned theme; before-catalog capture and storage

## Assumptions Presented and Research Findings

### Reproducible generator and drift gate
| Assumption / finding | Confidence | Evidence |
|---|---|---|
| Only `app.css` is generated; Tailwind 4.1.12 build is byte-reproducible | Confident (local), Likely (Linux x64) | two agents measured; mac-arm64 vs linux-arm64 identical |
| Gate is red at HEAD: Phase 179 `copy.ex` "prose" word adds 2,260 bytes of `.prose` rules | Confident | both agents; rewording or `@source not` makes it byte-identical |
| `verify.preview` `git diff` step is never run in CI; moduledoc claim is false | Confident | `ci.yml` has no caller |
| Enforce in required `support_contract_admin` (alias step + ExUnit contract test), no new job | Likely | `ci_policy.exs` `active_required`; new job = ~6 registration surfaces |
| Prior art: Phoenix, LiveView, LiveDashboard, Oban Web have no drift gate; closest is actions/typescript-action check-dist and rust-analyzer sourcegen | Confident | agent read each `ci.yml` |
| June "raw-inline theme blocks" landmine does not reproduce | Likely | fresh builds emit canonical `--color-*: var(--mg-*)` |

**Disagreement resolved:** research advisor proposed moving the task to `dev/` so it does not ship; analyzer proposed keeping it in `lib`. Decided: keep in `lib` (documented, allowlisted surface); planner may split compare logic into `dev/` only if the publish lane stays green.
**Disagreement resolved:** `@source not "../../lib/.../copy.ex"` (analyzer) vs `@source not inline("prose")` (advisor). Decided: inline form.

### html-owned theme
| Assumption / finding | Confidence | Evidence |
|---|---|---|
| Server-rendered cookie theme on `<html>` is already the architecture | Confident | `root.html.heex:2`, `ThemeController`, redirect flow |
| Nested attributes at `admin_shell.ex:33`, `tabs.ex:66`, `gallery_live.ex:138,148` | Confident | grep and read |
| Preview html/text panels force light under admin dark: demonstrated shadowing | Confident | `tabs.ex:178-186` |
| Shell-versus-html disagreement: latent only | Likely | no visible repro in current paths |
| Email body is an iframe srcdoc, so theme cannot leak; use `color-scheme` on iframe | Likely | `tabs.ex:106`; iframe `color-scheme` handling unsettled across browsers |

**Disagreement resolved:** analyzer would keep the Preview and Gallery nested scopes as "intentional"; research and success criterion 3 ("only `<html>` carries `data-theme`") say remove all. Decided: remove all.

### Before-catalog
| Assumption / finding | Confidence | Evidence |
|---|---|---|
| Demo app already has the three personas and screen routes (`persona-screenshots.spec.js`) | Confident | read by analyzer |
| Delivery cases partly seeded; nine still missing | Likely | `LENS-FINDINGS.md` section C vs `DemoData` |
| Committed PNGs plus manifest; ~250 tracked PNGs precedent; `.planning` non-shippable | Confident | `mix.exs` files lists, release-please `exclude-paths` |
| Existing screenshot dirs are git-ignored; v1.14 shots untracked | Confident | `.gitignore`, `.cache` |

**Disagreements resolved:** (a) path: phase dir (analyzer) vs `research/` (advisor) → `research/` because archive moves phase dirs; (b) capture tool: demo Playwright spec (analyzer) vs new admin script (advisor) → demo spec, script as fallback; (c) timing: first vs last → last, after the BRPIPE-02 fix, with `nested_theme_attr_count` recorded; (d) size: ~40 shots / 4-5 MB vs ~120 / 30 MB → hard cap 80 images / 15 MB.

## Corrections Made

No user corrections requested; decisions follow the research-first policy. The owner can veto any D-NN mid-plan.

## External Research

- Tailwind 4.1 `@source not inline()` and class detection (tailwindcss.com).
- daisyUI 5 theme selectors; Tailwind v4 dark mode; MDN `color-scheme`; csswg-drafts #13843 and #13796 (iframe `color-scheme`, April 2026).
- Playwright screenshot determinism (`animations`, `caret`, `clock`, `emulateMedia`).
- Git LFS free quota (10 GiB), hosted visual-diff vendors (rejected).

## Open verification items for the planner

- Linux x64 byte equality (first plan task: throwaway CI dry run).
- Whether a trailing `--output` overrides the config `--output` in `mix tailwind default ...`.
- `mix mailglass.publish.check` / `mailglass_admin-files.expected` unaffected if the task stays in `lib`.
- Guard Release Trigger kind for an `assets/css/app.css` edit.
