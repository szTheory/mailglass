---
phase: 122-preview-surface-redesign
plan: 03
subsystem: mailglass_admin / preview + persona evidence + token-parity floor
tags: [persona-evidence, token-parity, d-12, d-13, d-17, floor-hold, baseline-coupling]

# Dependency graph
requires:
  - phase: 122-preview-surface-redesign
    plan: 01
    provides: "theme_picker adoption + backdrop a11y (set_theme frame-aware) — same branch, complete"
  - phase: 122-preview-surface-redesign
    plan: 02
    provides: "brandbook empty/error microcopy + dead dark_chrome removal + paired voice/e2e/LiveView test updates — same branch, complete"
provides:
  - "Only-forward evidence contract for the Preview redesign: the single `preview` persona cell verified intact (4 anchor cells, no new cells) — re-shoot DEFERRED to Phase 123 per the D-17 baseline-drift fallback"
  - "Confirmed-untouched `mailglass_admin/priv/static/app.css` bundle (D-13) with TokenParityTest green"
  - "v1.13 ratchet floor + D-THEME-PARITY held green only-forward (no pillar re-score; no judgment-gate arming — Phase 123 scope)"
affects: [123-cross-surface-coherence-ratchet]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Persona re-shoot is best-effort under the D-17 fallback: when the demo Docker boot's `mix deps.get` would drift the FROZEN deterministic baseline, the re-shoot is deferred (explicit Phase-123 follow-up) rather than fabricating a green run or mutating the baseline — mirrors 121-04"
    - "Non-mutating baseline-drift probe: `mix deps.get --check-locked` reports the `=>` version bumps a plain resolve would write WITHOUT touching the lock, so the drift can be detected before deciding the fallback"
    - "Floor hold = verification-only task with zero source edit: re-run the inherited gates green; the persona spec is a re-run TARGET, not an edit (editing fires the persona drift-guard, D-12)"

key-files:
  created:
    - .planning/phases/122-preview-surface-redesign/122-03-SUMMARY.md
  modified:
    - .planning/phases/122-preview-surface-redesign/deferred-items.md

key-decisions:
  - "Persona re-shoot DEFERRED to Phase 123 (D-12 + D-17 fallback): the demo `compose.demo.yml` container CMD runs a plain `mix deps.get && mix ecto.setup && mix phx.server` against the host-mounted workspace lock; a fresh resolve drifts the frozen demo baseline (plug 1.19.2=>1.20.1, plug_cowboy 2.8.1=>2.9.0, premailex 0.3.20=>1.0.0 MAJOR, swoosh 1.26.1=>1.26.2). Per the locked fallback the proof is carried forward, not fabricated, and the baseline/lock are left byte-clean."
  - "persona-screenshots.spec.js left UNEDITED — the single `preview` dev-open cell (`:70`) already expands to exactly 4 cells (preview-any-{375,1440}-{light,dark}, persona-independent); adding/removing any cell fires the persona drift-guard (D-12). Verified via `--grep \"shot preview-\" --list` (4 tests)."
  - "No `mix assets.build` run (D-13): this phase introduced no new Tailwind class across plans 01/02 (all utilities already shipped), so the committed `priv/static/app.css` is byte-identical; a naive rebuild would emit raw-inline daisyUI 5.5.19 theme blocks that BREAK TokenParityTest."
  - "Floor HELD, not re-scored: no 54-cell pillar re-score and no new judgment-gate arming (nav-active-correctness / no-nav-duplication) performed — that is Phase 123 scope."

requirements-completed: [PREV-01]

coverage:
  - id: D1
    description: "Single `preview` persona cell intact (no new cells); re-shoot deferred per D-12/D-17 with a captured deferred-item"
    requirement: "PREV-01"
    verification:
      - kind: other
        ref: "grep -c 'kind: \"dev-open\", route: \"/dev/mail\"' persona-screenshots.spec.js == 1; node --check parses; `npx playwright test --grep \"shot preview-\" --list` enumerates exactly 4 cells (preview-any-{375,1440}-{light,dark}); spec git-clean (unedited)"
        status: pass
      - kind: other
        ref: "demo Docker boot requires a baseline-drifting `mix deps.get` (plug/plug_cowboy/premailex MAJOR/swoosh `=>` bumps confirmed via --check-locked); re-shoot DEFERRED to Phase 123 per the locked D-17 fallback (deferred-items.md Plan 122-03)"
        status: deferred
    human_judgment: true
  - id: D2
    description: "Committed asset bundle untouched (D-13); TokenParityTest green; no new Tailwind class"
    requirement: "PREV-01"
    verification:
      - kind: other
        ref: "git diff --quiet -- mailglass_admin/priv/static/app.css (working tree clean) AND no 122 commit (aef23b22~1..HEAD) touched app.css"
        status: pass
      - kind: unit
        ref: "mix test test/mailglass_admin/token_parity_test.exs → 2 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D3
    description: "v1.13 ratchet floor + D-THEME-PARITY held green only-forward; no pillar re-score / no judgment-gate arming"
    requirement: "PREV-01"
    verification:
      - kind: unit
        ref: "mix test test/mailglass_admin/preview_live_test.exs test/mailglass_admin/voice_test.exs --seed 0 → 40 tests, 0 failures (1 excluded)"
        status: pass
      - kind: other
        ref: "no 54-cell pillar re-score and no new judgment-gate arming performed this phase (deferred to Phase 123); git status shows only the deferred-items.md docs edit"
        status: pass
    human_judgment: false

# Metrics
duration: ~3 min
completed: 2026-06-28
status: complete
---

# Phase 122 Plan 03: Preview persona evidence + asset/TokenParity floor hold (phase close) Summary

**Closed the Preview surface redesign on a green-only-forward floor: verified the single `preview` persona cell is intact (4 anchor cells, no new cells — the spec is a re-run target left unedited), DEFERRED the actual re-shoot to Phase 123 under the locked D-17 baseline-drift fallback (the demo Docker boot's `mix deps.get` would drift the frozen demo baseline across plug/plug_cowboy/premailex-MAJOR/swoosh), confirmed the committed `priv/static/app.css` is byte-untouched with TokenParityTest green (D-13), and held the v1.13 ratchet floor + D-THEME-PARITY green only-forward — no 54-cell pillar re-score and no judgment-gate arming (Phase 123 scope).**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-06-28T19:21:37Z
- **Completed:** 2026-06-28T19:25:00Z
- **Tasks:** 2 (both verification / re-run + deferral — zero source edits, mirroring 121-04 Task 3)
- **Files modified:** 1 docs file (`deferred-items.md`); zero source under `lib/`; zero CSS; persona spec unedited

## Accomplishments

- **Task 1 — persona re-shoot verify + D-17 deferral (no commit; re-run/deferral only):**
  Verified `reference/demo_app/assets/e2e/persona-screenshots.spec.js` is intact and parses
  (`node --check`), enumerates exactly **one** `preview` dev-open cell (`:70`) expanding to 4
  cells `preview-any-{375,1440}-{light,dark}` (persona-independent; `--grep "shot preview-" --list`
  → 4 tests), and is git-clean (unedited — editing fires the persona drift-guard, D-12). Probed the
  demo boot non-destructively with `mix deps.get --check-locked` in `reference/demo_app`: the resolve
  reports `plug 1.19.2 => 1.20.1`, `plug_cowboy 2.8.1 => 2.9.0`, `premailex 0.3.20 => 1.0.0 (major)`,
  `swoosh 1.26.1 => 1.26.2` — i.e. the demo container CMD's plain `mix deps.get` would drift the
  FROZEN deterministic baseline. Per the locked **D-12 + D-17 fallback**, DEFERRED the actual shoot to
  Phase 123 (captured in `deferred-items.md`), with no fabricated run and the baseline `mix.lock`
  verified byte-clean.
- **Task 2 — asset bundle untouched + TokenParity + floor hold (no commit; verification only):**
  Confirmed `mailglass_admin/priv/static/app.css` is byte-identical (working tree clean AND no 122
  commit in `aef23b22~1..HEAD` touched it) — no `mix assets.build` was needed or run (D-13; plans
  01/02 introduced no new Tailwind class). `mix test test/mailglass_admin/token_parity_test.exs` →
  **2 tests, 0 failures**. Re-confirmed the inherited floor green only-forward:
  `preview_live_test.exs` + `voice_test.exs --seed 0` → **40 tests, 0 failures (1 excluded)**.
  No 54-cell pillar re-score and no judgment-gate arming were performed (Phase 123 scope).

## Task Commits

1. **Task 1: persona re-shoot verify + D-17 deferral** — no commit (re-run/deferral only; the persona
   spec is a re-run target left unedited per D-12; the deferral is captured in the docs commit below).
2. **Task 2: asset bundle untouched + TokenParity + floor hold** — no commit (verification only; zero
   source edits).

The phase-close docs (this SUMMARY + the `deferred-items.md` Plan 122-03 entry + STATE/ROADMAP/
REQUIREMENTS updates) land in the single final metadata commit.

## Files Created/Modified

- `.planning/phases/122-preview-surface-redesign/122-03-SUMMARY.md` — created (this file).
- `.planning/phases/122-preview-surface-redesign/deferred-items.md` — added the **Plan 122-03**
  D-17 persona-re-shoot deferral entry (Phase-123 follow-up, with the exact `=>` baseline-drift bumps).
- `reference/demo_app/assets/e2e/persona-screenshots.spec.js` — **unedited** (re-run target only, D-12).
- `mailglass_admin/priv/static/app.css` — **unedited** (byte-identical, D-13).

## D-17 Decision Record — why the re-shoot is deferred (not run, not fabricated)

The persona producer drives the demo through Docker (`compose.demo.yml` `demo` / `demo_e2e` services;
`make demo` / `make demo-e2e`). The `demo` container's CMD is
`mix deps.get && mix ecto.setup && mix phx.server`, run against the host-mounted workspace
(`.:/workspace`), so its `mix deps.get` resolves against and writes back the **host** `mix.lock`.
A fresh resolve wants to bump `plug`, `plug_cowboy`, `premailex` (a **major** 0.3 → 1.0), and `swoosh`
off the frozen deterministic baseline — the exact documented baseline-coupling / swoosh-lock-drift
landmine (`project_reference_baseline_coupling.md`, `project_demo_app_swoosh_lock_drift.md`). This is
the same env condition that triggered the 121-04 deferral. Per the locked fallback, the only-forward
`preview` visual delta is carried as an explicit **Phase-123** follow-up (to be captured under a
coordinated baseline bump), rather than mutating the baseline or fabricating a green run. The
`reference/demo_app/mix.lock` was confirmed byte-clean throughout (`--check-locked` refuses to write).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Task 2 verify command pointed at a stale TokenParityTest path**
- **Found during:** Task 2 (running the plan's `<automated>` verify command)
- **Issue:** The plan's verify command referenced
  `test/mailglass_admin/components/token_parity_test.exs`, which does not exist
  ("Paths given to mix test did not match"). The actual file is
  `test/mailglass_admin/token_parity_test.exs` (the same path 121-04 used).
- **Fix:** Ran the gate at the real path; **2 tests, 0 failures**. No source change — a verify-command
  path correction only.
- **Files modified:** none (verification path correction).
- **Commit:** n/a (verification only).

## Scope Discipline (Do-NOT list honored)

- No new persona cell added/removed (D-12) — spec unedited; re-shoot deferred per D-17.
- No `mix assets.build` run; committed `app.css` byte-identical (D-13).
- No 54-cell pillar re-score; no judgment-gate arming (nav-active-correctness / no-nav-duplication) —
  Phase 123 scope.
- No baseline / `mix.lock` drift committed; no fabricated demo run.

## Verification

- `grep -c 'kind: "dev-open", route: "/dev/mail"' persona-screenshots.spec.js` == **1**;
  `node --check` parses; `--grep "shot preview-" --list` enumerates exactly **4** cells.
- `git diff --quiet -- reference/demo_app/mix.lock` → **clean**.
- `git diff --quiet -- mailglass_admin/priv/static/app.css` → **clean**; no 122 commit touched it.
- `mix test test/mailglass_admin/token_parity_test.exs` → **2 tests, 0 failures**.
- `mix test test/mailglass_admin/preview_live_test.exs test/mailglass_admin/voice_test.exs --seed 0`
  → **40 tests, 0 failures (1 excluded)**.

## Threat Mitigations

- **T-122-03 (Tampering — persona baseline / `mix.lock` drift, low):** mitigated — the demo boot's
  baseline-drifting `mix deps.get` was detected via a non-mutating `--check-locked` probe and the
  re-shoot was DEFERRED per the D-17 fallback rather than committing a drifted baseline. Both
  `reference/demo_app/mix.lock` and `mailglass_admin/priv/static/app.css` verified byte-clean. No
  production artifact affected (dev-only screenshot seam + read-only floor verification).

## Known Stubs

None.

## Deferred / Open Follow-ups (Phase 123)

- **`preview` persona re-shoot (D-12 / D-17 / D-THEME-PARITY visual delta):** the 4 anchor cells
  (`preview-any-{375,1440}-{light,dark}`) are unchanged in spec but were NOT re-run — the demo Docker
  boot requires a baseline-drifting `mix deps.get` (plug/plug_cowboy/premailex-MAJOR/swoosh). Carry the
  only-forward `preview` visual proof into Phase 123 under a coordinated baseline bump (recorded in
  `deferred-items.md` Plan 122-03).
- **Cross-surface coherence finalization + judgment-gate arming + 54-cell pillar re-score** — Phase 123
  (this phase HELD the inherited floor; it did not re-score or arm).

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Phase 122 (Preview) is closed on a green only-forward floor: theme_picker adoption + backdrop a11y
  (122-01), brandbook microcopy + dead-code removal + paired tests (122-02), and this phase's evidence
  contract + asset/TokenParity hold (122-03). Phase 123 can complete the deferred `preview` persona
  re-shoot under a coordinated baseline bump and arm the new judgment gates + 54-cell re-score into the
  permanent ratchet floor.

## Self-Check: PASSED

- `122-03-SUMMARY.md` present.
- `deferred-items.md` Plan 122-03 entry present.
- `persona-screenshots.spec.js` present and unedited (re-run target, D-12); `app.css` byte-clean (D-13).
- TokenParityTest 2/0; preview_live + voice 40/0 (1 excluded); `reference/demo_app/mix.lock` clean.

---
*Phase: 122-preview-surface-redesign*
*Completed: 2026-06-28*
