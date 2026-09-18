---
phase: 166-earned-greens-and-controls-that-can-pass
plan: 05
subsystem: infra
tags: [github-actions, ci-cache, hex-deps, demo-app, mix-lock]

# Dependency graph
requires:
  - phase: 166-04
    provides: "release-please rate-limit retry/skip code (CTRL-02/CTRL-03), sequencing only"
provides:
  - "An isolated CI build step that resolves reference/demo_app's mailglass/mailglass_admin/mailglass_inbound deps from Hex with --check-locked and compiles, leaving the existing path-dep demo build untouched (GREEN-04)"
  - "reference/demo_app/mix.lock refreshed to the current published sibling line (2.6.0/2.6.0/2.3.0), a precondition GREEN-04 needed to compile at all"
  - "Lane-specific cache keys on both trust lanes, and a committed docs/ci-cache-isolation.md demonstrating FINDINGS.md FG-4's cross-lane-cache-contamination premise is refuted by construction (GREEN-05, Parts 1 and 3 complete; Part 2 pending a real CI run — see Task 3)"
affects: [166-06, phase-167-merges, ci-workflow]

actuals:
  tokens: 21000
  tasks: 2
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Isolation-by-scratch-copy: when a working-tree-relative env-var override (MIX_DEPS_PATH/MIX_BUILD_PATH) breaks a native-code build (cowlib's erlang.mk), rsync a copy with default paths into a scratch directory instead of overriding paths in place."
    - "Cache-version-hash refutation: actions/cache SHA-256-hashes the declared path list into the cache version and filters candidates server-side by that version before restore-keys prefix matching is even considered; extraction is all-or-nothing with no path argument. This makes cross-path-list cache collisions structurally impossible, independent of key-string collisions."

key-files:
  created:
    - docs/ci-cache-isolation.md
  modified:
    - .github/workflows/ci.yml
    - reference/demo_app/mix.lock
    - .planning/REQUIREMENTS.md
    - .planning/phases/166-earned-greens-and-controls-that-can-pass/deferred-items.md

key-decisions:
  - "Both blockers a prior executor halted on were resolved by the orchestrator before this execution and are re-verified here, not re-litigated: (1) the demo app's frozen 2.0.0 lock cannot compile against mailglass_admin's :navigation router dependency (introduced 2.1.0) — fixed by refreshing only the three mailglass sibling lock entries to 2.6.0/2.6.0/2.3.0, the current published line reference/demo_app/mix.exs's ~> 2.0 constraints already permit; (2) MIX_DEPS_PATH/MIX_BUILD_PATH overrides reproducibly break cowlib's erlang.mk build — fixed by isolating via an rsync scratch copy with default paths instead, rather than a new CI job (which would require job-count-parity registration in Mailglass.CILanes.all_classified_lanes/0 — more blast radius for the same signal)."
  - "GREEN-04's isolated build lives as a step inside the existing required support_contract_core job, not a new job — matching the plan's own reasoning for avoiding registry/drift-guard coupling, and consistent with how a new dedicated job (even advisory) would still need lane-classification registration in this codebase."
  - "docs/ci-cache-isolation.md's Part 2 (CI-observed restore evidence) cannot be produced pre-push; it is left as an explicit placeholder describing the expected first-run cache-miss shape, to be populated by Task 3's post-merge/post-push evidence gathering — mirroring the 166-04 precedent for CTRL-02/CTRL-03's post-merge observations."
  - "The note's own 'no hedged verdict' acceptance criterion caught its own draft: the literal substring 'probably fine' appeared inside a disclaiming clause ('why this table is sufficient — not \"probably fine\"'). Reworded to avoid the substring entirely rather than relying on quoting/negation to satisfy a literal grep check."

patterns-established:
  - "Scratch-copy isolation for a broken env-var-override path: rsync --exclude the tracked deps/_build directories into a scratch path, then run mix with default paths inside the copy. Avoids fighting a native-code build's assumption of default build paths."

requirements-completed: []  # GREEN-04/GREEN-05 code + note are implemented but NOT marked complete — GREEN-05's own acceptance bar requires real CI-observed evidence (Part 2) not yet available, and GREEN-04's post-merge confirmation row is likewise pending. See "Post-Merge Verification" / deferred-items.md.

coverage:
  - id: D1
    description: "GREEN-04: support_contract_core gains an isolated step that resolves reference/demo_app's three mailglass sibling packages from Hex with --check-locked and compiles, while the existing path-dep demo install/compile steps above it are byte-unchanged in diff and the path-dep deps/ directory is unmodified."
    requirement: "GREEN-04"
    verification:
      - kind: other
        ref: "local scratch-copy run: MAILGLASS_DEMO_DEPS=hex mix deps.get --check-locked && mix compile — exit 0, HEX_BUILD_ISOLATED (path-dep deps/ dir md5-identical before/after)"
        status: pass
      - kind: other
        ref: "grep -c MAILGLASS_DEMO_DEPS .github/workflows/ci.yml == 1; git diff --quiet reference/demo_app/mix.lock reference/demo_app/mix.exs against the final commit; actionlint .github/workflows/ci.yml clean"
        status: pass
    human_judgment: true
    rationale: "The isolated build is proven locally and the diff shape is proven mechanically, but GREEN-04's own acceptance criterion includes a post-merge confirmation ('confirm on the post-merge main run that the step resolved from Hex and compiled') — an observation this execution context cannot produce. Recorded as pending in deferred-items.md."
  - id: D2
    description: "reference/demo_app/mix.lock refreshed to mailglass 2.6.0 / mailglass_admin 2.6.0 / mailglass_inbound 2.3.0, a precondition GREEN-04 needed since the frozen 2.0.0 lock cannot satisfy mailglass_admin's :navigation router dependency."
    verification:
      - kind: other
        ref: "git diff --stat reference/demo_app/mix.lock == 3 insertions(+), 3 deletions(-); diff against pre-update lock shows only the three mailglass/mailglass_admin/mailglass_inbound lines changed"
        status: pass
    human_judgment: false
  - id: D3
    description: "GREEN-05: trust_lane_repo_head and trust_lane_clean_baseline cache keys are disambiguated with lane-specific segments (mix-trust-repo-head-… / mix-trust-clean-baseline-…), no other actions/cache step's key or path changed, and a reference/host_app/deps listing step lands before each lane's mix deps.get."
    requirement: "GREEN-05"
    verification:
      - kind: other
        ref: "python3 yaml parse: trust_lane_repo_head and trust_lane_clean_baseline cache keys DISTINCT; actionlint clean; git diff -- .github/workflows/ci.yml touches only the Task-1 step range and the two trust-lane cache/listing blocks"
        status: pass
      - kind: integration
        ref: "mix test test/scripts/ — 475 tests, 0 failures, 27 excluded"
        status: pass
    human_judgment: false
  - id: D4
    description: "docs/ci-cache-isolation.md commits a three-part demonstration (not assertion) that FINDINGS.md FG-4's cross-lane cache contamination premise is refuted: Part 1 key-space table + actions/cache version-hash and all-or-nothing-extraction mechanism + D-14 closing facts; Part 2 CI-observed restore evidence (placeholder, pending real run — see Task 3); Part 3 local lock-authority proof that reference/host_app/mix.lock resolves 2.0.0, not a live published version."
    requirement: "GREEN-05"
    verification:
      - kind: other
        ref: "test -s docs/ci-cache-isolation.md; grep -c reference/host_app/deps docs/ci-cache-isolation.md == 6; grep -i 'probably fine|likely fine|should be fine' docs/ci-cache-isolation.md — no match"
        status: pass
      - kind: other
        ref: "Part 3 lock-authority proof run locally: reference/host_app/mix.lock pins mailglass/mailglass_admin/mailglass_inbound at 2.0.0; MIX_ENV=dev mix deps.get reports 'All dependencies are up to date' with git status clean afterward"
        status: pass
    human_judgment: true
    rationale: "Parts 1 and 3 are fully demonstrated with local evidence and pass all mechanical acceptance checks, but the requirement's own acceptance bar names three parts, and Part 2 (CI-observed restore log lines from a real run) cannot be produced pre-push. Task 3 defers this to the maintainer per the plan's own design (checkpoint:human-verify, gate=\"blocking-human\")."

duration: 55min
completed: 2026-09-18
status: complete
---

# Phase 166 Plan 05: GREEN-04/GREEN-05 — Demo App Hex Pins and Trust-Lane Cache Refutation Summary

**An isolated CI build now proves the demo app's Hex pins resolve and compile (after refreshing the frozen 2.0.0 lock to the current 2.6.0/2.6.0/2.3.0 line, which the tracked lock could not previously compile against), and `docs/ci-cache-isolation.md` demonstrates by construction that trust-lane cache cross-contamination is structurally impossible — with real CI-observed evidence still pending a post-push run.**

## Performance

- **Duration:** 55 min
- **Started:** 2026-09-18T02:05:00Z (approx)
- **Completed:** 2026-09-18T03:00:00Z (approx)
- **Tasks:** 2 of 3 completed autonomously; Task 3 (checkpoint:human-verify, `gate="blocking-human"`) explicitly deferred
- **Files modified:** 4 tracked (`.github/workflows/ci.yml`, `reference/demo_app/mix.lock`, `.planning/REQUIREMENTS.md`, `deferred-items.md`), 1 created (`docs/ci-cache-isolation.md`)

## Accomplishments

- GREEN-04: an isolated Hex-resolution build of `reference/demo_app` now runs inside
  `support_contract_core`, resolving all three mailglass sibling packages from Hex with
  `--check-locked` and compiling — proven locally end-to-end with the path-dep build's `deps/`
  directory verified byte-unchanged before and after.
- `reference/demo_app/mix.lock`'s three sibling entries were refreshed from the frozen 2.0.0 to
  the current published 2.6.0/2.6.0/2.3.0 line — a precondition discovered and resolved before
  GREEN-04's build could compile at all, since `mailglass_admin` gained a hard `:navigation`
  router dependency at 2.1.0 the 2.0.0 lock cannot satisfy.
- GREEN-05: both trust lanes' cache keys are now lane-specific
  (`mix-trust-repo-head-…` / `mix-trust-clean-baseline-…`), and each gained a
  `reference/host_app/deps` listing step immediately before its `deps.get` to observe restore
  behavior directly.
- `docs/ci-cache-isolation.md` commits a three-part demonstration refuting FINDINGS.md FG-4: a
  key-space table of all 18 `mix-`-keyed `actions/cache` steps (five distinct path lists, so five
  independent cache entries — not one shared cache) plus the `actions/cache` version-hash and
  all-or-nothing-extraction mechanism that makes cross-path-list collision structurally
  impossible; and a local lock-authority proof that `reference/host_app`'s trust-lane `deps.get`
  resolves the pinned 2.0.0 line, not a live published version.

## Task Commits

Each task was committed atomically:

1. **Precondition fix (unblocking Task 1):** `chore(deps): refresh demo_app hex pins to published 2.6.0/2.6.0/2.3.0 line` — `2fb6d5d1` (chore)
2. **Task 1: GREEN-04 — isolated hex-resolution demo build step** — `2a1dafca` (feat)
3. **Task 2: GREEN-05 — trust-lane cache disambiguation + isolation note** — `c418db4f` (docs)

Task 3 (checkpoint:human-verify, `gate="blocking-human"`) is not committed as complete — see
"Next Phase Readiness" below.

**Plan metadata:** (this commit, after this SUMMARY)

## Files Created/Modified

- `.github/workflows/ci.yml` — one new step in `support_contract_core` (GREEN-04); lane-specific
  cache keys + evidence-listing steps in both trust lanes (GREEN-05).
- `reference/demo_app/mix.lock` — three mailglass sibling entries refreshed to
  2.6.0/2.6.0/2.3.0; every other entry, and `mix.exs`, unchanged.
- `docs/ci-cache-isolation.md` — new committed GREEN-05 deliverable.
- `.planning/REQUIREMENTS.md` — GREEN-04/GREEN-05 rows: `Pending` → `Implemented, evidence
  pending`.
- `.planning/phases/166-earned-greens-and-controls-that-can-pass/deferred-items.md` — 166-05
  section documenting both resolved-blocker deviations and the Task 3 pending-evidence checklist.

## Decisions Made

See `key-decisions` in frontmatter above. In summary: both prior-executor blockers were resolved
by the orchestrator and independently re-verified here (lock refresh for the demo app's
`:navigation` dependency; scratch-copy isolation instead of the broken `MIX_DEPS_PATH`/
`MIX_BUILD_PATH` override, and instead of a new CI job); GREEN-05's note is left with an honest
placeholder for Part 2 rather than fabricated evidence; a hedge-language self-check caught and
fixed its own draft wording.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Refreshed `reference/demo_app/mix.lock`'s three mailglass sibling entries**
- **Found during:** Task 1 (GREEN-04 isolated build)
- **Issue:** The plan explicitly prohibited editing `reference/demo_app/mix.lock` (D-12 assumed
  the 2.0.0-pinned lock already compiles under `MAILGLASS_DEMO_DEPS=hex`). A prior executor
  discovered this assumption is false: `mailglass_admin` gained a hard `:navigation` router
  dependency at 2.1.0 that the 2.0.0 lock cannot satisfy, so `mix compile` fails.
- **Fix:** Orchestrator resolved this before this execution, explicitly lifting the prohibition
  for a narrow lock refresh: ran `MAILGLASS_DEMO_DEPS=hex mix deps.update mailglass
  mailglass_admin mailglass_inbound` to move only those three entries to the current published
  line (2.6.0/2.6.0/2.3.0). `mix.exs`'s `~> 2.0` constraints were never edited.
- **Files modified:** `reference/demo_app/mix.lock`
- **Verification:** `git diff --stat` shows exactly 3 lines changed; a subsequent isolated
  `mix deps.get --check-locked && mix compile` succeeds against the refreshed lock.
- **Committed in:** `2fb6d5d1`

**2. [Rule 3 - Blocking] Isolation mechanism swapped from `MIX_DEPS_PATH`/`MIX_BUILD_PATH` override to a scratch-copy build**
- **Found during:** Task 1 (GREEN-04 isolated build)
- **Issue:** The plan's literal acceptance text named `MIX_DEPS_PATH`/`MIX_BUILD_PATH` env-var
  overrides as the isolation mechanism. A prior executor reproduced (5 runs, isolated variable)
  that this override breaks cowlib's `erlang.mk` build locally.
- **Fix:** Orchestrator-resolved: build an rsync scratch copy of `reference/demo_app` +
  `reference/persona_spec` (preserving their sibling directory relationship, since
  `mix.exs`'s `@persona_spec_dir` is `Path.expand("../persona_spec", __DIR__)`) with default
  `deps`/`_build` paths inside `/tmp/mailglass_demo_hex_proof`, rather than overriding paths on
  the working tree. A new dedicated CI job (the orchestrator's stated first preference) was
  considered and rejected: this codebase's `lane_classification_drift_test.exs` enforces a
  job-count-parity check against `Mailglass.CILanes.all_classified_lanes/0`, so *any* new
  `ci.yml` job — required or merely advisory — requires a lane-registry update, which is more
  coupling/blast-radius for the same signal than a step inside the existing required
  `support_contract_core` job.
- **Files modified:** `.github/workflows/ci.yml`
- **Verification:** Local isolated run: `HEX_BUILD_ISOLATED` (path-dep `deps/` directory
  md5-identical before/after the isolated build); `mix deps.get --check-locked && mix compile`
  exit 0 with no `Mix.Dep.LockError`/"the lock is outdated" in output; `grep -c
  MAILGLASS_DEMO_DEPS .github/workflows/ci.yml` == 1; `actionlint` clean.
- **Committed in:** `2a1dafca`

**3. [Rule 1 - Bug] Self-caught hedge-language violation in the note's own prose**
- **Found during:** Task 2 (GREEN-05 note verification)
- **Issue:** The acceptance criterion "the note contains no hedged verdict — the strings
  'probably fine', 'likely fine' and 'should be fine' do not appear in it" is a literal substring
  check. The first draft of `docs/ci-cache-isolation.md` used the phrase inside a disclaiming
  clause ("why this table is sufficient — not 'probably fine'"), which still matches the literal
  grep even though the sentence's meaning is the opposite of hedging.
- **Fix:** Reworded to "why this table demonstrates non-contamination rather than asserting it" —
  avoiding the substring entirely rather than relying on quoting/negation to satisfy a
  mechanical check.
- **Files modified:** `docs/ci-cache-isolation.md`
- **Verification:** `grep -in 'probably fine|likely fine|should be fine' docs/ci-cache-isolation.md`
  — no match.
- **Committed in:** `c418db4f`

---

**Total deviations:** 3 auto-fixed (2 Rule 3 blocking, 1 Rule 1 bug)
**Impact on plan:** All three were necessary to make GREEN-04/GREEN-05 actually true rather than
cosmetically green — exactly this milestone's standing goal. The two Rule 3 fixes were both
pre-authorized by explicit orchestrator resolution before this execution began; the Rule 1 fix
is a same-task self-correction caught by re-running the plan's own verification command before
declaring the task done. No scope creep — nothing outside GREEN-04/GREEN-05's own files changed.

## Issues Encountered

None beyond the two pre-resolved blockers and the self-caught hedge-language issue documented
above as deviations.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

**Task 3 (checkpoint:human-verify, `gate="blocking-human"`) is explicitly PENDING, not skipped or
silently passed.** Per this plan's own design and the checkpoint protocol (`gate="blocking-human"`
is never auto-approved, including in auto-mode), Part 2 of `docs/ci-cache-isolation.md` requires a
real CI run to observe what `actions/cache` restore actually materialized — that cannot be
produced from this sequential-executor context, which has no push/PR-creation mandate. A full
checklist for completing Task 3 is recorded in `deferred-items.md` under `## 166-05` and repeated
here:

1. Push this branch (or merge to `main`) so CI runs with the newly disambiguated trust-lane cache
   keys for the first time.
2. From that run, collect both trust lanes' cache-restore log lines (hit/miss + resolved key) and
   the new `reference/host_app/deps` listing step's output.
3. Paste both, plus the run URL, into `docs/ci-cache-isolation.md` Part 2, annotating the expected
   first-run cache miss as a cold start (D-16), not a regression.
4. Confirm on the same or a subsequent `main` run that `support_contract_core`'s "Prove demo app
   Hex pins" step resolved from Hex and compiled (GREEN-04's own post-merge confirmation row).
5. Present the completed note to the maintainer for the yes/no Task 3's `resume-signal` calls for.

Until then, `.planning/REQUIREMENTS.md`'s GREEN-04/GREEN-05 rows stay `Implemented, evidence
pending` — code and note are real, demonstrated locally in full, but the acceptance bar's
CI-observed half is not yet available. Ready for `166-06` and the Phase 167 merges to supply
these observations, per D-37.

## Self-Check: PASSED

- `docs/ci-cache-isolation.md` — FOUND on disk.
- `git log --oneline --all --grep="166-05"` returns 3 commits (`2fb6d5d1`, `2a1dafca`, `c418db4f`),
  all present in `git log`.
- `.github/workflows/ci.yml` — `actionlint` clean, YAML parses, trust-lane cache keys confirmed
  `DISTINCT` via a Python/YAML parse.
- `mix test test/scripts/` — 475 tests, 0 failures, 27 excluded.

---
*Phase: 166-earned-greens-and-controls-that-can-pass*
*Completed: 2026-09-18*
