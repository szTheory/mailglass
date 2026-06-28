---
phase: 123-cross-surface-coherence-ratchet-re-arm
plan: 02
subsystem: dev-review-surfaces
tags: [storybook, gallery, dx-docs, coherence, COH-01]
requires:
  - "123-01 (ratchet re-score + judgment-gate arming) — committed on main"
  - "Plan 01 storybook scaffold (D-07): foundations + 5 primitive stories, sandbox css_path, sandbox_class mg-admin-root"
provides:
  - "Verified storybook story inventory (5 brand primitives) consistent with shipped components.ex contract"
  - "D-09 accept-indigo finalization record (explorer chrome accepted as dev-only cosmetic)"
  - "D-STORYBOOK-STALE-BOOT DX caveat in guides/run-the-demo.md Troubleshooting"
affects:
  - "guides/run-the-demo.md"
tech-stack:
  added: []
  patterns:
    - "Story inventory cross-referenced against component attr defs (no drift = no edit)"
    - "Transitive mix.lock drift restored before commit (reference/demo_app baseline pin discipline)"
key-files:
  created: []
  modified:
    - "guides/run-the-demo.md (Troubleshooting bullet for storybook stale-boot)"
decisions:
  - "D-09 accept-indigo: phoenix_storybook 1.2.0 explorer chrome accepted as-is (dev-only cosmetic); no config-only accent hook exists in 1.2.0, theming it requires dep CSS override or a Node build — both forbidden (zero-Node guarantee, 118 D-07). title is already set to the brand name (the only clean config-level brand hook)."
  - "D-11 inventory verdict: COMPLETE AS-IS. The 5 storied brand primitives (nav_link, nav_pill, tenant_chip, theme_picker, stat_card) match the current components.ex contract with zero attribute drift; 119-122 introduced no new theme-sensitive brand primitive, so NO story files were added. card/filter_section/filter_field/data_state/status_badge are generic containers/utility components, explicitly out of scope (D-11)."
metrics:
  duration_min: 3
  completed: 2026-06-28
status: complete
---

# Phase 123 Plan 02: Storybook + Gallery Finalization Summary

Verified the dev-only storybook story inventory is consistent with the shipped admin primitives (5 brand primitives, zero drift, no files added), accepted the indigo phoenix_storybook explorer chrome as dev-only cosmetic, and documented the storybook stale-boot DX caveat in `guides/run-the-demo.md` — the COH-01 review-surface deliverable, with the gallery specimen surface and committed asset bundle left byte-unchanged.

## What Was Built

**Task 1 — Story-inventory completeness check (no code change):** Cross-referenced all five existing primitive stories against the current `mailglass_admin/lib/mailglass_admin/components.ex` attr contracts. Inventory is complete and consistent; no story added or edited. The deliverable is the verification verdict (below), not an edit.

**Task 2 — Stale-boot DX caveat:** Added a Troubleshooting bullet to `guides/run-the-demo.md` documenting the `/dev/storybook` 500 (`PhoenixStorybook.Router UndefinedFunctionError`) that occurs when the demo container predates the `phoenix_storybook` dep, and that a fresh `make demo`/`docker restart` resolves it. Docs-only, on-brand voice.

## Storybook Finalization Record

### D-11 — Story-inventory verdict: COMPLETE AS-IS (no files added)

Cross-reference of each story's `function` + `variations` attributes against the live `components.ex` attr definitions:

| Story | Component attrs (components.ex) | Story attrs used | Drift? |
|-------|--------------------------------|------------------|--------|
| `nav_link` (L194-199) | label*, icon*, href*, active, disabled, rest | label, icon, href, active, disabled | none |
| `nav_pill` (L244-248) | label*, href*, active, disabled, rest | label, href, active, disabled | none |
| `tenant_chip` (L287-288) | tenant, rest | tenant | none |
| `theme_picker` (L311-316) | selected(:system/:light/:dark), name, disabled, event, target, rest | selected, disabled | none (valid subset) |
| `stat_card` (L362-371) | label*, value, severity(neutral/info/success/warning/error), state(ready/empty/loading/unavailable), severity_label, *_text, rest | label, value, severity, state | none (all enum values valid) |

(* = required attr.) Every story's `function/0` points at a live `MailglassAdmin.Components.*/1`; every variation attribute name and enum value is in the current component contract; every theme-sensitive story sets `data-theme` at the template level per D-08 (no class→data-theme alias). **Zero drift — no story corrected.**

**No new story added.** The brand-primitive set the foundations doc fixes is the five theme-sensitive accent-bearing primitives. Phases 119–122 introduced no new such primitive — phase-122 commits were fixes/re-voicing (e.g. `theme_picker` stable `name`, preview copy), not a new brand component. The other public components are explicitly out of scope per D-11:
- `card` (114-01 "thin shell primitive") — generic container, named in D-11 as out of scope.
- `filter_section` / `filter_field` (111-01) — generic form primitives.
- `data_state` (113-01) — generic empty/error/permission-denied/stale state block, not a Glass-accent brand primitive.
- `status_badge`, `icon`, `logo`, `flash`, `badge` — utility/atom components.

Adding stories for these would over-scope "finalized" past "consistent with the redesign" (D-11). Inventory is complete as-is.

### D-09 — Accept-indigo decision: ACCEPTED (dev-only cosmetic)

The explorer-shell chrome (header "mailglass admin" + book glyph) renders in phoenix_storybook 1.2.0's default indigo/violet, served by the dep's own prebuilt CSS (`priv/static/css/phoenix_storybook-*.css`), distinct from the component **sandbox** which is already styled by the committed admin bundle via `css_path` (Plan 01, D-07). phoenix_storybook 1.2.0 exposes no config-only accent/brand-color hook for the explorer chrome — theming it would require overriding the dep CSS or adding a Node/esbuild storybook build, both forbidden by the zero-Node adopter guarantee and 118 D-07. The backend already sets `title: "mailglass admin"` (the one clean config-level brand hook). **Decision: accept the indigo chrome as-is** — it is a dev-only review surface that never ships to adopters (matches DEFECT-REGISTER D-STORYBOOK-BRAND fix-direction: "otherwise accept the default"). No dep CSS edited, no Node build added.

### D-08 / D-12 — Specimen + bundle untouched

`mailglass_admin/lib/mailglass_admin/gallery_live.ex` and `mailglass_admin/priv/static/` are byte-unchanged (zero git diff). No `mix assets.build` run.

## Deviations from Plan

None — plan executed exactly as written. Task 1's "complete as-is, add no files" branch is the documented expected outcome, not a deviation.

## Deferred Issues (out of scope — SCOPE BOUNDARY)

- **Pre-existing warning** in `mailglass_admin/lib/mailglass_admin/operator_live.ex:505` (`selected_delivery={nil}` where attr expects a `:map`). Surfaced during the verification compile of an unrelated app; this plan touched no admin lib code. Not fixed (out of scope per the executor SCOPE BOUNDARY rule — pre-existing, unrelated file). The demo_app compiled clean and `mix compile --warnings-as-errors` returned exit 0; the warning came from the admin-lib dependency compile and did not abort the build. Logged to `.planning/phases/123-cross-surface-coherence-ratchet-re-arm/deferred-items.md`.

## Repo-Hygiene Note

`mix deps.get` (required to compile demo_app — lock was stale) wrote transitive upgrades to `reference/demo_app/mix.lock` (plug 1.19.2→1.20.1, plug_cowboy 2.8.1→2.9.0, premailex 0.3.20→1.0.0, swoosh 1.26.1→1.26.2). All transitive drift, none intentional to this docs/storybook plan — `git checkout -- reference/demo_app/mix.lock` restored the baseline pin before committing. No lock change committed.

## Verification Results

- `cd reference/demo_app && mix compile --warnings-as-errors` → **exit 0** (all stories + demo app compile; demo app generated clean).
- `git diff --stat mailglass_admin/lib/mailglass_admin/gallery_live.ex` → **empty** (D-08 byte-unchanged).
- `git diff --stat mailglass_admin/priv/static/` → **empty** (D-12 no asset rebuild).
- No `reference/demo_app/deps/` edited; no Node/esbuild storybook build config added.
- `grep -qi storybook && grep -qi "make demo|restart|fresh"` on `guides/run-the-demo.md` → **CAVEAT-PRESENT**.
- D-14 paired-test discipline: `git grep` confirms no `voice_test.exs` / e2e spec greps the new doc copy (the `UndefinedFunctionError` test matches are in admin `/dev/mail` smoke tests, a different surface, and read no `guides/` markdown).
- `reference/demo_app/mix.lock` transitive drift restored to baseline before commit.

## Commits

| Task | Type | Commit | Files |
|------|------|--------|-------|
| 1 | (no committable artifact — verdict in this SUMMARY) | — | none |
| 2 | docs | `8d8666a9` | guides/run-the-demo.md |

## Self-Check: PASSED

- `123-02-SUMMARY.md` exists.
- `guides/run-the-demo.md` exists, contains the `/dev/storybook` caveat bullet.
- Commit `8d8666a9` present in git log.
