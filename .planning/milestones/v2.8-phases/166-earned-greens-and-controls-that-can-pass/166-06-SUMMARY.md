---
phase: 166-earned-greens-and-controls-that-can-pass
plan: 06
subsystem: infra
tags: [ci, github-actions, elixir, release-engineering, mix-task]

requires:
  - phase: 166-05
    provides: trust-lane cache-key disambiguation and the GREEN-04 isolated Hex-resolution build (unrelated files; sequencing dependency only)
provides:
  - "A baseline-versions resolution path in scripts/release_policy.exs that lets post-publish-smoke resolve an inactive ledger's published baseline"
  - "A workflow_dispatch mode=baseline input on post-publish-smoke.yml that exercises the schedule path on demand, without waiting for a natural cron fire"
  - "A distinct cron-guard baseline output, never a reuse of completed=true, so the fail-closed control never lies about what it verified"
  - "A --baseline-mode flag on check_post_publish_target.sh that bypasses only the unsatisfiable 64-hex digest check in baseline mode"
  - "repo-hygiene's cannot_check aggregate exiting a distinct nonzero code ({:shutdown, 2}) from blocked's {:shutdown, 1}"
  - "repo-hygiene's PR predicate widened from any-open-PR to open >14d (whole-day granularity) OR a failing required check"
affects: [phase-167-docs, release-mechanics-docs]

actuals:
  tokens: 7616
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Ledger-status peek before verb selection: read .planning/release-target.json's status field with jq before choosing which already-validated release_policy.exs verb to invoke, rather than parsing partial JSON in a second place."
    - "Distinct boolean signal instead of signal reuse: a fail-closed control that needs a new resolvable state emits a NEW named output (baseline) rather than overloading an existing one (completed) to a value that would misdescribe what was actually verified."
    - "Exit-code split for non-verdict vs. alarm: a mix task's cannot_check aggregate gets its own nonzero exit code, distinct from a confirmed blocked alarm, so an unobservable control can never look like either a pass or the same failure class as a real block."

key-files:
  created: []
  modified:
    - .github/workflows/post-publish-smoke.yml
    - scripts/release_policy.exs
    - scripts/check_post_publish_target.sh
    - dev/mix/tasks/mailglass.repo.hygiene.ex
    - test/mix/tasks/mailglass.repo.hygiene_test.exs
    - test/mailglass/publish/post_publish_smoke_contract_test.exs

key-decisions:
  - "The literal single-line command-selection assertion in test/mailglass/publish/post_publish_smoke_contract_test.exs (an existing coupling test not listed in the plan's read_first) had to be updated to match the new multi-line ledger-status-peek branch it now pins -- the old any-schedule-always-completed-versions assertion is the exact behavior CTRL-01 changes by design."
  - "Chose day-granularity (not raw elapsed seconds) for the 14-day PR-age boundary in repo-hygiene: comparing raw DateTime.diff seconds against exactly 14*86400 is flaky under real audit-run latency (a PR created exactly 14 days ago can drift to 14 days + a few seconds by the time the predicate runs, silently flipping 'not blocked' to 'blocked'). div(diff_seconds, 86_400) > 14 tolerates any latency under 24h with zero loss of the documented boundary semantics."
  - "cannot_check exits {:shutdown, 2}, blocked stays {:shutdown, 1} -- chosen to preserve every existing test/consumer that already asserts {:shutdown, 1} for a confirmed block, changing only the previously-collapsed cannot-check path."

requirements-completed: [CTRL-01, CTRL-05]

coverage:
  - id: D1
    description: "post-publish-smoke's schedule path can resolve a published baseline from an inactive ledger via a new baseline-versions verb, re-validated through the shared full-ledger validator, running the same exact Hex checksum/endpoint proof; live-dispatch guards (40-hex ref, exact-SemVer, all 4 required inputs, 64-hex digest) are unconditionally retained on the live-dispatch path."
    requirement: CTRL-01
    verification:
      - kind: unit
        ref: "test/scripts/release_policy_contract_test.exs, test/scripts/release_policy_test.exs, test/scripts/release_policy_close_out_test.exs, test/scripts/scheduled_control_evidence_test.exs, test/scripts/workflow_hardening_contract_test.exs, test/mailglass/publish/post_publish_smoke_contract_test.exs"
        status: pass
      - kind: other
        ref: "elixir scripts/release_policy.exs baseline-versions .planning/release-target.json via mix run --require --no-start (the bare `elixir FILE args` form named in the plan's own verify block never calls cli/1 -- see Deviations)"
        status: pass
      - kind: manual_procedural
        ref: "post-merge workflow_dispatch of post-publish-smoke.yml with mode=baseline against the inactive ledger"
        status: unknown
    human_judgment: true
    rationale: "CTRL-01's acceptance criterion is inherently post-merge (a workflow_dispatch on main) and is milestone exit criterion 3; tracked as pending evidence in deferred-items.md, never assumed passing."
  - id: D2
    description: "repo-hygiene's cannot_check aggregate exits a distinct nonzero code from blocked, and the PR predicate blocks only on >14-day age or a failing required check (never any open PR), with a null/malformed rollup classifying to not-failing rather than crashing."
    requirement: CTRL-05
    verification:
      - kind: unit
        ref: "test/mix/tasks/mailglass.repo.hygiene_test.exs (26 tests, including the 8 new D-35 cases and the exit-code-split case)"
        status: pass
      - kind: manual_procedural
        ref: "two consecutive naturally-triggered scheduled repo-hygiene runs post-merge"
        status: unknown
    human_judgment: true
    rationale: "CTRL-05's acceptance criterion needs two real cron firings, which cannot be dispatched or manufactured (plan prohibition); tracked as pending evidence in deferred-items.md, never assumed passing."

duration: 55min
completed: 2026-09-17
status: complete
---

# Phase 166 Plan 06: CTRL-01 baseline resolution + CTRL-05 exit-code split Summary

**post-publish-smoke gains a ledger-status-peeked baseline resolution path so its daily cron can pass between releases, and repo-hygiene's cannot-check now exits a distinct nonzero code from blocked with a PR predicate that only fires on stale age or a failing required check.**

## Performance

- **Duration:** ~55 min
- **Started:** 2026-09-17T22:37:00Z (first toolchain export)
- **Completed:** 2026-09-17T23:32:00Z
- **Tasks:** 2 of 3 (Task 3 is `checkpoint:human-verify`, carried as pending post-merge evidence)
- **Files modified:** 6

## Accomplishments

- **CTRL-01:** `scripts/release_policy.exs` gained a `baseline-versions` verb resolving an
  inactive-status ledger's `baselines` + `required_evidence_identifiers.historical_tag_sha`
  through the same `validate_target/1` every other verb uses. `post-publish-smoke.yml`'s resolve
  job now peeks the ledger's `status` field (via `jq`) before choosing a verb: a schedule fire (or
  an on-demand `workflow_dispatch` via the new optional `mode: baseline` input) against an
  inactive ledger resolves the published baseline instead of failing closed forever on a
  completed target that does not exist between releases. `cron-guard` emits a distinct `baseline`
  output (never reusing `completed=true`), and `check_post_publish_target.sh`'s 64-hex digest
  requirement is bypassed only behind a new `--baseline-mode` flag. Every live-dispatch guard --
  the 40-hex ref regex, the exact-SemVer assertions, all 4 pre-existing `required: true` inputs,
  the unconditional digest check on the live path -- is unchanged.
- **CTRL-05:** `dev/mix/tasks/mailglass.repo.hygiene.ex`'s `run/1` now maps `cannot_check` to
  `{:shutdown, 2}`, distinct from `blocked`'s `{:shutdown, 1}`; neither is 0. `pull_requests/1`'s
  `gh pr list --json` field list gained `createdAt` and `statusCheckRollup`; the any-open-PR
  predicate is replaced with "blocked when any open PR is older than 14 days (whole-day
  granularity, immune to audit-run latency) OR has a failing required check, otherwise pass" --
  written test-first per the plan's `tdd="true"` marking, with 8 new cases covering every named
  edge (empty list, 3-day healthy, exactly-14-day, 15-day, failing rollup, null/absent rollup,
  `gh` query failure, the exit-code split itself).
- Discovered and fixed 3 test failures in the coupling test
  `test/mailglass/publish/post_publish_smoke_contract_test.exs` (not in the plan's read_first
  list) that pinned the exact pre-change shell text of the resolver step -- two were legitimate
  behavior-pinning updates the new design requires, one was a real `set -u` "unbound variable"
  bug the new code introduced (see Deviations).

## Task Commits

1. **Task 1: CTRL-01 baseline resolution path** - `bc9a3f68` (feat)
2. **Task 2: CTRL-05 exit-code split + PR predicate, TDD** - `73f8e6ea` (test; implementation and
   the pinning test cases landed in the same commit per the plan's explicit D-35 lockstep
   instruction, which supersedes the generic RED-then-GREEN commit split)
3. **Task 3: post-merge evidence** - checkpoint, not committed (see below)

**Plan metadata:** committed alongside this SUMMARY (see Deliverables commit below)

## Files Created/Modified

- `.github/workflows/post-publish-smoke.yml` - new `mode` workflow_dispatch input; resolve job
  peeks ledger status and selects `baseline-versions` for an inactive ledger; `cron-guard` gains a
  distinct `baseline` output and accepts it alongside `completed`
- `scripts/release_policy.exs` - new `baseline-versions` CLI verb
- `scripts/check_post_publish_target.sh` - new `--baseline-mode` flag bypassing only the 64-hex
  digest check
- `dev/mix/tasks/mailglass.repo.hygiene.ex` - exit-code split; widened PR JSON fields; new
  `pr_predicate/1`, `pr_stale?/1`, `pr_failing_check?/1`, `check_conclusion_failing?/1`; `pr_message/3`
- `test/mix/tasks/mailglass.repo.hygiene_test.exs` - 8 new D-35 cases + exit-code-split case;
  3 pre-existing `{:shutdown, 1}` cannot-check assertions updated to the new distinct code
- `test/mailglass/publish/post_publish_smoke_contract_test.exs` - literal command-selection
  assertion updated to match the new ledger-status-peek branch

## Decisions Made

See `key-decisions` in frontmatter. Summarized: (1) fixed an out-of-read_first coupling test in
lockstep rather than leaving it red; (2) chose day-granularity for the 14-day PR-age boundary to
eliminate real timing flakiness while preserving the documented boundary semantics exactly;
(3) picked `{:shutdown, 2}` for `cannot_check` to minimize blast radius on existing `{:shutdown, 1}`
block-path consumers.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `${digest_flags[@]}` empty-array expansion under `set -u` fails on bash 3.2**
- **Found during:** Task 1, running the plan's own coupling-test verification
- **Issue:** The first draft of the digest-bypass call built an optional-flag bash array
  (`digest_flags=(); [ "$baseline_mode" = true ] && digest_flags+=(--baseline-mode); ... "${digest_flags[@]}"`).
  `/bin/bash` on macOS (3.2.57, the default system bash and what
  `test/mailglass/publish/post_publish_smoke_contract_test.exs` invokes explicitly by hardcoded
  path) treats an empty array's `"${arr[@]}"` expansion as an unbound-variable error under
  `set -u`, even though GNU bash 4.4+ tolerates it. This is exactly the class of bug a real GH
  Actions runner (bash 5.x on Ubuntu) would likely NOT surface, making it a latent landmine.
- **Fix:** Replaced the array with two full explicit invocations of
  `check_post_publish_target.sh`, one per branch (`if baseline_mode ... else ...`), avoiding
  bash-array expansion entirely.
- **Files modified:** `.github/workflows/post-publish-smoke.yml`
- **Verification:** `test "real resolver shell preserves pass, blocked, and cannot-check
  resolution semantics"` in the coupling test, which executes the extracted step script under
  `/bin/bash` directly, passes.
- **Committed in:** `bc9a3f68` (Task 1 commit)

**2. [Rule 1 - Bug] `$INPUT_MODE` unbound under `set -u` when the env var is genuinely absent**
- **Found during:** Task 1, same verification pass
- **Issue:** `[ "$EVENT_NAME" = "workflow_dispatch" ] && [ "$INPUT_MODE" = "baseline" ]` references
  `$INPUT_MODE` unconditionally once the left side of `&&` is true. In real CI, GitHub Actions
  always sets the `INPUT_MODE` env var literal (empty string for non-baseline dispatches), so
  this never fires there -- but the coupling test's `Classify trigger` fixture invokes the
  extracted step script without setting `INPUT_MODE` at all, which is also a legitimate
  defensive-scripting gap (any future caller of this step script outside the GH Actions
  environment would hit the same crash).
- **Fix:** Both `$INPUT_MODE` references use `${INPUT_MODE:-}` instead.
- **Files modified:** `.github/workflows/post-publish-smoke.yml`
- **Verification:** `test "post-publish resolver paths materialize one bounded resolution before
  upload"` in the coupling test passes.
- **Committed in:** `bc9a3f68` (Task 1 commit)

**3. [Rule 1 - Bug] Coupling test's literal single-line command-selection assertion pinned the
exact pre-change behavior CTRL-01 exists to change**
- **Found during:** Task 1, same verification pass
- **Issue:** `test/mailglass/publish/post_publish_smoke_contract_test.exs` (an existing file not
  named in the plan's `read_first` list for this task) asserted the literal string
  `if [ "$EVENT_NAME" = "schedule" ]; then command="completed-versions"; fi` verbatim. This is
  exactly the always-completed-versions-for-schedule behavior CTRL-01's whole point is to change
  (a schedule fire against an inactive ledger must now resolve `baseline-versions` instead).
- **Fix:** Replaced the single literal assertion with assertions on the new multi-line
  ledger-status-peek branch (`if [ "$EVENT_NAME" = "schedule" ]; then` / `command="completed-versions"`
  / `if [ "$ledger_status_peek" = "inactive" ]; then` / `command="baseline-versions"` /
  `baseline_mode=true`), each still substring-matched against the real resolver step text.
- **Files modified:** `test/mailglass/publish/post_publish_smoke_contract_test.exs`
- **Verification:** the full 12-test coupling file passes with `--include requires_workspace`.
- **Committed in:** `bc9a3f68` (Task 1 commit)

**4. [Rule 1 - Bug] The plan's own Task 1 `<automated>` verify command for `baseline-versions`
never calls `cli/1`**
- **Found during:** Task 1, running the plan's exact verify command
  (`elixir scripts/release_policy.exs baseline-versions .planning/release-target.json`)
- **Issue:** `scripts/release_policy.exs`'s trailing code only halts loudly on specific
  `--`-prefixed banned flag spellings (`--validate-candidate`, `--verify-published`,
  `--verify-complete`); a bare positional command like `baseline-versions` matches none of those
  and is silently a no-op -- `elixir FILE ARGS` loads the module and evaluates the trailing
  `case System.argv() do ... end` but never invokes `Mailglass.ReleasePolicy.cli(System.argv())`.
  Confirmed by running the identical form with an intentionally bogus command
  (`elixir scripts/release_policy.exs totally-bogus-command /nonexistent/path`), which also
  exits 0 with no output -- proving the literal verify command as written cannot distinguish a
  working verb from a broken one.
- **Fix:** Ran the correct invocation form the workflow itself uses:
  `mix run --no-start --no-compile --no-deps-check --require scripts/release_policy.exs -e
  'Mailglass.ReleasePolicy.cli(System.argv())' -- "baseline-versions" ".planning/release-target.json"`,
  which confirmed `baseline-versions` emits all three exact SemVer triples, the historical tag
  SHA, the three Hex checksums, and the three Hex endpoints read from the ledger.
- **Files modified:** none (verification-only; not a code fix)
- **Verification:** see the `coverage.D1` entry above; output captured and matches the ledger's
  `baselines` and `required_evidence_identifiers` exactly.
- **Committed in:** n/a (no file change; documented here per Rule 1's "auto-fix bugs" umbrella
  applied to a broken verification command)

---

**Total deviations:** 4 auto-fixed (all Rule 1 - bugs discovered while verifying Task 1; none
touch Task 2's files). **Impact on plan:** all four were necessary for correctness of the diff or
its verification; none relaxed a gate, widened scope, or touched files outside this plan's
`files_modified` list except the one coupling test, which the plan's own change made stale.

## Issues Encountered

None beyond the deviations above.

## User Setup Required

None - no external service configuration required.

## Task 3 Status: PENDING EVIDENCE (not passing, not skipped)

Task 3 is `checkpoint:human-verify`, `gate="blocking-human"`, and is inherently post-merge:

- **CTRL-01** needs a `workflow_dispatch` of `post-publish-smoke.yml` with `mode=baseline` run
  against `main` after this PR merges, confirming exit 0, the uploaded
  `post-publish-resolution.json` artifact, and that its resolved versions/tag SHA match the
  ledger's baseline values. This is milestone exit criterion 3 -- per the plan, it is the item
  that must not be dropped if the timebox tightens.
- **CTRL-05** needs two consecutive NATURALLY-TRIGGERED scheduled `repo-hygiene` runs (never a
  `workflow_dispatch` or re-run manufactured to produce them), both concluding `success` with an
  overall `pass`, with at least one healthy PR open across both firings.

Both are logged as an explicit checklist in
`.planning/phases/166-earned-greens-and-controls-that-can-pass/deferred-items.md` under `## 166-06`
for whoever picks this up post-merge. `.planning/REQUIREMENTS.md`'s CTRL-01 and CTRL-05 rows are
set to `Implemented, evidence pending` -- never `Complete` -- until both are observed.

## Next Phase Readiness

- Phase 166 (Earned Greens and Controls That Can Pass) has all 10 requirements (GREEN-01..05,
  CTRL-01..05) implemented; GREEN-04, GREEN-05, CTRL-01, CTRL-02, CTRL-03, CTRL-05 all carry
  pending post-merge evidence tracked in `deferred-items.md`. CTRL-04 is the only fully `Complete`
  control requirement.
- Phase 167 (documentation corrections) is unblocked and does not depend on any of this plan's
  pending evidence.
- No blockers for merging this plan's work; the checkpoint at Task 3 is explicitly deferred, not
  a merge gate for the code changes themselves.

---
*Phase: 166-earned-greens-and-controls-that-can-pass*
*Completed: 2026-09-17*

## Self-Check: PASSED

All 8 claimed files verified present on disk; both task commit hashes (`bc9a3f68`, `73f8e6ea`)
verified present in `git log --oneline --all`.
