---
phase: 114-component-groups
plan: 03
subsystem: ui
tags: [phoenix, liveview, heex, mailglass_admin, design-system, conformance, group-surfaces, spacing-sweep]

# Dependency graph
requires:
  - phase: 114-component-groups
    provides: "Plan 114-01 — MailglassAdmin.Components.card/1 group-surface shell + SPACE-GATE/GROUP-GATE/PRIMITIVE-DRIFT gates (red by design until this sweep)"
  - phase: 114-component-groups
    provides: "Plan 114-02 — composed-group gallery specimens + data-region instrumentation (the data-group-card lands on each group shell once this plan swaps <.card> in)"
provides:
  - "All 8 group surfaces render their outer shell through <.card> (Components.card/1) with data-group-card + preserved data-testid"
  - "support_cards box prison removed: 3 inner cards demoted to borderless bg-base-100 sunken insets with paired border-l-4 left-rule; outer shell carries shadow-raised"
  - "~93 raw off-grid spacing tokens swept to the 4px-grid semantic scale (xs..3xl) across the 8 group files"
  - "scripts/check-conformance.sh exits 0 (SPACE-GATE + GROUP-GATE + PRIMITIVE-DRIFT-GATE all green)"
affects: ["114-04 (Floki ancestor-depth proof + Playwright visual proofs build on the swept/greened surfaces)"]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Group-surface outer shell = <.card padding={:md|:lg}> with data-group-card + data-testid passed via :global @rest; the literal class on card/1 merges with a call-site class override (shadow-raised) — Phoenix LiveView appends rest class to the static class list"
    - "Box-prison fix = demote same-tone inner card (card bg-base-200 border border-base-300) to borderless bg-base-100 rounded-box inset; depth section -> inset (<=2)"
    - "Status never color-alone (WCAG 1.4.1): border-l-4 left-rule always paired with the colored text-display count + text label"
    - "Reference impls (4 timeline/trace/evidence modules) get spacing-only sweep — their bg-base-100 insets preserved verbatim"

key-files:
  created: []
  modified:
    - "mailglass_admin/lib/mailglass_admin/operator/support_cards.ex"
    - "mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex"
    - "mailglass_admin/lib/mailglass_admin/operator/detail_header.ex"
    - "mailglass_admin/lib/mailglass_admin/operator/timeline.ex"
    - "mailglass_admin/lib/mailglass_admin/inbound/routing_trace.ex"
    - "mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex"
    - "mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex"
    - "mailglass_admin/lib/mailglass_admin/inbound/timeline.ex"

decisions:
  - "Applied the optional border-l-4 left-rule to all 3 support_cards Tier-1 insets (failure=error, orphan=warning, replay=error) — hierarchy holds at narrow width and each rule is paired with the colored count + label, so it strengthens scan-ability without violating WCAG 1.4.1"
  - "shadow-raised passed as class={\"shadow-raised\"} through card/1's :global @rest; Phoenix merges it into the component's static class list (verified by clean --warnings-as-errors compile) — no edit to components.ex (plan-01 territory) needed"
  - "data-group-card given a per-surface value (e.g. data-group-card=\"operator-support-cards\") rather than a bare boolean attribute, so each group shell is individually addressable by the plan-04 Floki depth proof"

metrics:
  duration: "~10 min"
  completed: "2026-06-20"
  tasks: 3
  files_modified: 8

status: complete
---

# Phase 114 Plan 03: Group-Surface Sweep & Box-Prison Fix Summary

Swept all 8 mailglass_admin group-surface modules onto the single `<.card>` shell with semantic 4px-grid spacing, removed the lone `support_cards.ex` box prison (demoted same-tone inner cards to borderless `bg-base-100` sunken insets + `shadow-raised` outer shell), and drove the Phase 114 SPACE-GATE / GROUP-GATE / PRIMITIVE-DRIFT conformance gates from red-by-design to green (`scripts/check-conformance.sh` exits 0).

## What Shipped

- **Task 1 — `support_cards.ex` (the lone box-prison offender):** outer `<section>` swapped to `<.card padding={:md} data-group-card data-testid=... class="shadow-raised">`; the 3 Tier-1 inner `<article>` cards demoted from `card bg-base-200 border border-base-300 rounded-box p-lg` to borderless `rounded-box bg-base-100 p-lg border-l-4 border-{error|warning}` sunken insets; `text-display font-bold` count and `btn btn-primary` CTA preserved; ~8 off-grid spacing tokens swept. Commit `aed80a77`.
- **Task 2 — the 7 remaining surfaces:** suppression_card, operator/inbound detail_header, operator/inbound timeline, routing_trace, evidence_card all render their outer shell through `<.card padding={:lg}>` (`<.card>` via local `import ..., only: [card: 1]` where no `Components` alias existed; `<Components.card>` where it did). The 4 reference impls' `bg-base-100` insets preserved verbatim — spacing-only sweep (~58 tokens incl. the `gap-2` SPACE-GATE closes). Commit `0b6c9663`.
- **Task 3 — gate + bundle verification (no code change):** `scripts/check-conformance.sh` exits 0; `git diff --exit-code priv/static/app.css` clean (no new CSS utility — `shadow-raised`, `border-l-4`, `--spacing-*` all pre-exist); scoped operator (25) + inbound (21) tests pass with `--seed 0`.

## Verification

- `bash scripts/check-conformance.sh` → `OK: design-system conformance clean.` (EXIT=0)
- Post-sweep SPACE-GATE grep across the 8 files → ALL CLEAN (zero off-grid spacing numerics)
- `mix compile --warnings-as-errors` → clean
- `git diff --exit-code priv/static/app.css` → clean (bundle unchanged)
- `mix test test/mailglass_admin/operator/ --seed 0` → 25 tests, 0 failures
- `mix test test/mailglass_admin/inbound/ --seed 0` → 21 tests, 0 failures
- Scope fence (D-12): `git diff --name-only` over both task commits → exactly the 8 group modules, nothing else

## Token Sweep Map (4px grid)

`space-y-1`/`mt-1` → `-xs` (4px) · `space-y-2`/`mt-2`/`gap-2`/`mb-3`/`p-3`/`px-3`/`space-y-3`→`-sm` (8px, except space-y-3→md per plan) · `mb-4`/`p-4`/`px-4`/`pt-4`/`mt-4`/`space-y-3` → `-md` (16px) · `p-6`/`space-y-4`/`mt-6` → `-lg` (24px) · `px-2 py-1` → `px-sm py-xs`. Sizing tokens (`min-h-11`, `h-3`, `w-3`, `border-l-4`, `w-px`) and `mt-0.5` icon-alignment left untouched.

## Deviations from Plan

None — plan executed as written. The plan flagged the `border-l-4` left-rule as OPTIONAL ("ONLY if hierarchy holds at 320px"); it was applied to all 3 support_cards Tier-1 insets because the rule sits on a borderless inset with ample width and each is paired with its colored count + label, so it adds scan-ability without crowding (documented as a decision above, not a deviation).

## Self-Check: PASSED

- Commit `aed80a77` (support_cards) — FOUND
- Commit `0b6c9663` (7 surfaces) — FOUND
- All 8 modified files exist on disk — FOUND
- `scripts/check-conformance.sh` exits 0 — CONFIRMED
