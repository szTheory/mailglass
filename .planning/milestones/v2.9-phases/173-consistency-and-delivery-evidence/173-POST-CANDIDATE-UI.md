# Phase 173 — Post-candidate UI work (reconciliation record)

Recorded 2026-10-24 during the v2.9 tidy-up. The owner-requested inbound refinement
(`61dc374d`, `bb98438f`, `a17f0ee5`; see `173-INBOUND-REFINEMENT.md`) was followed by 21 more
commits on local branches `codex/health-overview-20ed2d61` and
`codex/mailglass-favicon-1c547f6c` that no other Phase 173 record described. They were
integrated into `main` by merge `6720e54b` so every cited SHA stays reachable.

**Evidence boundary.** `9b6e60e4` remains the last SHA with exact-SHA CI (run 38073415056, all
26 jobs) and the full local delivery gate. None of the commits below, nor the Phase 172 UI-review
follow-up committed as `2907f2a9..8a6a1b95`, is covered by that proof. The final v2.9 delivery
candidate is the PR head after integration, and it needs its own CI and gate run.

## Commits (`a17f0ee5..1c547f6c`, 61 files, +3945/−2102)

| SHA | Date | Subject |
|---|---|---|
| `96bad135` | 2026-10-10 | Simplify inbound summary and explain key outcomes |
| `2e4e2406` | 2026-10-10 | Refine inbound filters and timestamps |
| `6ea8321c` | 2026-10-10 | Make timestamps copyable and anchor help popovers |
| `b095bb07` | 2026-10-10 | Polish mail operator and preview UI and correct demo lifecycle fixtures |
| `0dfb7a79` | 2026-10-10 | Unify operator collection headings and capture date range filtering |
| `9abcd2c4` | 2026-10-10 | Show collection counts inline in parentheses |
| `53959ea8` | 2026-10-10 | Polish delivery and inbound inspection views |
| `55a9a1a2` | 2026-10-10 | Clarify subjects and simplify inspection ID copy controls |
| `ebf92ba7` | 2026-10-10 | test(admin): bootstrap core schema through public installer |
| `25eaad34` | 2026-10-10 | polish(admin): finish UI baseline consistency and keyboard checks |
| `60d891d8` | 2026-10-12 | polish(admin): combine account context and switcher |
| `6b82a8a7` | 2026-10-12 | polish(admin): compact mobile and tablet header layout |
| `61b80060` | 2026-10-12 | polish(admin): confirm health refresh with icon and toast |
| `b8dc5bba` | 2026-10-12 | fix(admin): preserve refresh icon and clarify webhook terminology |
| `1c5b060e` | 2026-10-12 | polish(admin): align investigation controls and health semantics |
| `6e5e6716` | 2026-10-12 | polish(admin): simplify health observation period help |
| `722a5839` | 2026-10-12 | fix(admin): keep shared help tooltips anchored through updates |
| `42d06039` | 2026-10-12 | polish(admin): remove redundant Health status captions |
| `95ecd41f` | 2026-10-12 | Prioritize actionable issues on email health |
| `20ed2d61` | 2026-10-12 | refactor(admin): focus health and unify operator UI patterns |
| `1c547f6c` | 2026-10-12 | feat(admin): use the Mailglass brand favicon across UI surfaces |

## Scope outside `mailglass_admin/`

- Core: `lib/mailglass/operator/deliveries.ex` and `test/mailglass/operator/deliveries_test.exs` (`b095bb07`).
- Demo: `demo_data.ex`, `inbound/support_mailbox.ex`, `demo_data_reset_test.exs`, `assets/e2e/cohort.spec.js`.
- Persona spec: `reference/persona_spec/personas.ex`.
- Planning: two `.planning/notes/2026-10-10-*` notes and seed `SEED-261010-gad-operator-date-range-and-live-filters`.

Several subjects are not Conventional Commits. That does not matter for the squash-merged v2.9 PR,
whose title alone feeds release-please.

## Decision: nav_link has no long-label state (2026-10-25)

Owner decision: sidebar nav labels are always short, and a label long enough to
truncate is a naming smell to fix by shortening it, not a state to support. So
`nav_link` keeps no `title` tooltip (restoring the owner's 20ed2d61 intent and
reversing 941cac11), and the long-label specimen is removed from the Gallery,
the curated Storybook, the unit test, and the structural/persona browser specs.
The candidate gate and `173-DELIVERY.md` now review the Storybook route
`nav_link?variation_id=active_light` instead. `truncate` stays as a layout
safety net only. `nav_pill` (filter pills) is unchanged and keeps its tooltip
and long-label specimen. The decision is also stated in the `nav_link` docs.
Do not reintroduce a long-label nav_link state.
