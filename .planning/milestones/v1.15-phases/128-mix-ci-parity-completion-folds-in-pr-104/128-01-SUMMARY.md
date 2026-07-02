---
phase: 128-mix-ci-parity-completion-folds-in-pr-104
plan: 01
subsystem: infra
tags: [mix-aliases, ci, dx, contributing, preflight, makefile, local-ci-parity]

# Dependency graph
requires:
  - phase: 127-determinism
    provides: "inbound suite determinism via serial MailboxCase (DET-02) — the --seed 0 deletion this plan consumes"
  - phase: 126-gate-required-checks
    provides: "the required-lane set / GATE-03 seam that Plan 02's parity-drift test hoists to one source"
provides:
  - "mix ci alias family (ci.setup / ci.fast / ci / ci.browser) in root mix.exs, env-pinned to :test"
  - "sibling-local ci / ci.fast aliases in mailglass_admin and mailglass_inbound"
  - "brand-voice preflight guard scripts (Postgres + network) that fail closed before DB/network tasks"
  - "make ci / ci-fast / ci-browser thin wrappers surfaced in make help"
  - "CONTRIBUTING repointed at the tiered mix ci workflow (no deprecated verify.phase_07 pointer)"
  - "removal of the 6 deprecated verify.phase pass-throughs + their preferred_envs entries"
affects: [129, mix-ci-parity-drift-test, publish-hex, contributing, release-engineering]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Tiered mix alias family (ci.fast strict-subset-of ci) — cheap-to-expensive fail-fast ordering"
    - "Fail-closed bash preflight guards intercept DB/network absence before the raw stacktrace surfaces"
    - "3-package fan-out via cmd --cd, mirroring verify.stability_contract"

key-files:
  created:
    - "scripts/preflight_postgres.sh"
    - "scripts/preflight_network.sh"
  modified:
    - "mix.exs"
    - "mailglass_admin/mix.exs"
    - "mailglass_inbound/mix.exs"
    - "Makefile"
    - "CONTRIBUTING.md"

key-decisions:
  - "Kept deps.unlock --check-unused OUT of ci.fast (matches PR #104's informed decision; the lock carries orphaned transitive entries — cleaning them is a deferred follow-up)"
  - "Inbound ci test step is `mix test --exclude property` with NO --seed 0 — consuming Phase 127 DET-02; reintroducing a seed pin would regress determinism"
  - "Plain Mix alias lists, not a Mix.Task / ex_check / bin/ci script — zero new deps, native fail-fast chaining"
  - "Left verify.phase67 / verify.phase69 untouched (real bodies, not deprecated pass-throughs)"

patterns-established:
  - "ci.setup and ci both run scripts/preflight_postgres.sh as their first step; the installer smoke step is preceded by scripts/preflight_network.sh"
  - "Every new alias that nests mix test or an env-sensitive compile is pinned to :test in cli/0 preferred_envs (Elixir 1.18 no-auto-promote footgun)"

requirements-completed: [MIXCI-01, MIXCI-02, MIXCI-04, MIXCI-05]

coverage:
  - id: D1
    description: "Two brand-voice preflight guard scripts fail closed with a single actionable line (no stacktrace) when Postgres/network is unreachable"
    requirement: "MIXCI-04"
    verification:
      - kind: automated
        ref: "bash -n scripts/preflight_postgres.sh && bash -n scripts/preflight_network.sh && test -x both && ! POSTGRES_HOST=203.0.113.1 POSTGRES_PORT=1 bash scripts/preflight_postgres.sh"
        status: pass
    human_judgment: false
  - id: D2
    description: "Root mix ci alias family (ci.setup/ci.fast/ci/ci.browser) exists, env-pinned; ci runs all 5 required merge gates with installer smoke last; 6 deprecated verify.phase pass-throughs removed"
    requirement: "MIXCI-01"
    verification:
      - kind: automated
        ref: "mix format --check-formatted mix.exs; grep -c verify.phase_07 mix.exs == 0; grep ci.fast/ci.browser/consumer_install_smoke.sh/check_trust_runner_checkpoint.sh/preflight_postgres.sh; ! grep 'test --exclude property --seed 0'; MIX_ENV=test mix help ci resolves"
        status: pass
    human_judgment: false
  - id: D3
    description: "Sibling-local ci/ci.fast aliases in mailglass_admin + mailglass_inbound, env-pinned; inbound test step has no --seed 0"
    requirement: "MIXCI-02"
    verification:
      - kind: automated
        ref: "cd mailglass_admin && mix format --check-formatted mix.exs && grep ci.fast/verify.support_contract.admin; cd mailglass_inbound && mix format --check-formatted mix.exs && grep ci.fast && ! grep 'test --exclude property --seed 0'; both mix help ci resolve"
        status: pass
    human_judgment: false
  - id: D4
    description: "make ci / ci-fast / ci-browser thin wrappers in .PHONY, surfaced in make help; make ci exports MAILGLASS_PATH"
    requirement: "MIXCI-02"
    verification:
      - kind: automated
        ref: "grep '^ci:.*##' / '^ci-fast:.*##' / '^ci-browser:.*##' / MAILGLASS_PATH Makefile; .PHONY includes ci; make help lists all three"
        status: pass
    human_judgment: false
  - id: D5
    description: "CONTRIBUTING Local Setup + Development Workflow rewritten to the ci.fast/ci/ci.setup/ci.browser workflow; no deprecated verify.phase_07 pointer"
    requirement: "MIXCI-05"
    verification:
      - kind: automated
        ref: "grep -c verify.phase_07 CONTRIBUTING.md == 0; grep 'mix ci.fast'/'mix ci.setup'/'mix ci.browser'/'## Commit Guidelines'"
        status: pass
    human_judgment: false

# Metrics
duration: 4min
completed: 2026-07-01
status: complete
---

# Phase 128 Plan 01: `mix ci` Parity Completion Summary

**Tiered `mix ci` alias family (ci.fast / ci / ci.setup / ci.browser) across all three sibling packages, brand-voice Postgres/network preflight guards, make wrappers, and a CONTRIBUTING rewrite — so a single local command equals the mergeable surface, with the 6 deprecated verify.phase pass-throughs removed.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-07-01T20:56:10Z
- **Completed:** 2026-07-01T21:00:37Z
- **Tasks:** 5
- **Files modified:** 7 (2 created, 5 modified)

## Accomplishments
- `mix ci` now runs all 5 required branch-protection gates (support contracts core + admin, `compile --no-optional-deps`, reference-host trust lane + checkpoint contract, installer host smoke last), cheap-to-expensive fail-fast — closing the local↔CI parity gap (LD-10).
- Brand-voice preflight guards (`preflight_postgres.sh`, `preflight_network.sh`) intercept DB/network absence before the raw DBConnection/generator stacktrace, printing one actionable line (LD-12 / MIXCI-04).
- Sibling-local `ci`/`ci.fast` aliases give a uniform "is this green?" verb inside each package; `make ci`/`ci-fast`/`ci-browser` add discoverable wrappers.
- Removed the 6 deprecated `verify.phase` pass-throughs + their `preferred_envs` entries and repointed CONTRIBUTING at the tiered workflow (MIXCI-05).
- Consumed Phase 127's `--seed 0` deletion: the inbound `ci` test step is `mix test --exclude property` with no seed pin, in both root and sibling mix.exs.

## Task Commits

Each task was committed atomically:

1. **Task 1: Brand-voice preflight guard scripts (Postgres + network)** - `8fcea591` (feat)
2. **Task 2: Root mix.exs ci alias family, preferred_envs, preflight wiring, remove deprecated pass-throughs** - `62da46ae` (feat)
3. **Task 3: Sibling ci/ci.fast aliases in mailglass_admin and mailglass_inbound** - `dae016d9` (feat)
4. **Task 4: Makefile ci/ci-fast/ci-browser thin wrappers** - `7c692776` (feat)
5. **Task 5: Rewrite CONTRIBUTING Local Setup + Development Workflow** - `b6f15e6f` (docs)

_Plan metadata commit follows this SUMMARY._

## Files Created/Modified
- `scripts/preflight_postgres.sh` - Bounded pg_isready/TCP probe; on failure prints one brand-voice line naming host:port, exits 1, no stacktrace.
- `scripts/preflight_network.sh` - Bounded curl/TCP probe of hex.pm; on failure points at `mix ci.fast` offline subset, exits 1.
- `mix.exs` - Added ci.setup / ci.fast / ci / ci.browser aliases + preferred_envs; removed the 6 deprecated verify.phase pass-throughs and their preferred_envs entries.
- `mailglass_admin/mix.exs` - ci / ci.fast aliases + preferred_envs.
- `mailglass_inbound/mix.exs` - ci / ci.fast aliases + preferred_envs (inbound test step no seed pin).
- `Makefile` - ci / ci-fast / ci-browser targets in .PHONY, surfaced in make help; ci exports MAILGLASS_PATH.
- `CONTRIBUTING.md` - Replaced Local Setup + Development Workflow with the tiered mix ci workflow; removed the deprecated verify.phase_07 pointer.

## Decisions Made
- **`deps.unlock --check-unused` kept out of `ci.fast`.** DX-MIX-CI.md §B.1 lists it, but PR #104 excluded it because the lock carries orphaned transitive entries (`castore`, `unicode_util_compat`) that would red the check on first run. Matched PR #104's informed decision (per CONTEXT specifics #3); cleaning the orphans is a deferred follow-up.
- **No `--seed 0` on the inbound test step.** DX-MIX-CI.md §B.1/§B.3 wrote `mix test --exclude property --seed 0`; Phase 127 (DET-02) made the inbound suite deterministic and deleted seed pins. Reintroducing one regresses determinism — used `mix test --exclude property` everywhere (CONTEXT specifics #2).
- **Left `verify.phase67` / `verify.phase69` untouched** — they have real bodies and are not deprecated pass-throughs (CONTEXT specifics #4).

## Deviations from Plan

None - plan executed exactly as written. The two reconciliations (no `--seed 0`, no `deps.unlock --check-unused`) were called out by the plan/CONTEXT and applied as specified — not unplanned deviations.

## Issues Encountered
None. All task `<verify>` blocks and the plan-level `<verification>` block (6 checks: format, no verify.phase_07, alias resolution, no-Postgres preflight message, make help listing, no inbound seed pin) passed on first run. mix.lock did not drift.

## Known Stubs
None - all deliverables are functional alias/script/doc code with no placeholder data paths.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- The alias bodies are the input Plan 02 (Wave 2, MIXCI-03) reads: the parity-drift test that asserts `ci ∪ ci.browser` ⊇ the required + advisory CI lanes via a shared `ci_lanes` source. That source hoist (from ci.yml / publish-hex.yml / setup_branch_protection.sh) is Plan 02's work.
- **Open PR #104 should be closed** — its partial alias draft (root `mix.exs` + CONTRIBUTING only, missing installer smoke, trust checkpoint, sibling aliases, make targets, preflight guards, and the pass-through removal) is fully superseded by this plan. Do not double-add its aliases.
- A full `mix ci` end-to-end run needs Postgres + network + a clean `reference/host_app` build (the executor's optional local smoke); the gating checks used here are deterministic and DB-free.

## Self-Check: PASSED
- `scripts/preflight_postgres.sh` — FOUND (executable)
- `scripts/preflight_network.sh` — FOUND (executable)
- Commit `8fcea591` — FOUND
- Commit `62da46ae` — FOUND
- Commit `dae016d9` — FOUND
- Commit `7c692776` — FOUND
- Commit `b6f15e6f` — FOUND

---
*Phase: 128-mix-ci-parity-completion-folds-in-pr-104*
*Completed: 2026-07-01*
