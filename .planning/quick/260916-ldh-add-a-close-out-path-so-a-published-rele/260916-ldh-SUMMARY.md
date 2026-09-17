---
phase: quick-260916-ldh
plan: 01
subsystem: infra
tags: [release-please, hex, elixir, github-actions, release-policy]

# Dependency graph
requires:
  - phase: quick-260916-i5g
    provides: "scoped release-please core exclude-paths so scripts/test/.github/.planning changes never trigger a release"
provides:
  - "close_out/3 + `close-out` CLI verb in scripts/release_policy.exs: a non-authorizing transition from authorized/published/completed back to inactive"
  - "scripts/release_policy_close_out.sh: evidence-gated wrapper that fetches Hex checksums live, re-verifies them through release_policy_hex_release_state.sh, resolves the release tag, and applies the transition with --write"
  - "release-please.yml capture control self-heals a stranded ledger instead of failing closed forever"
affects: [release-please.yml, publish-hex.yml, release_policy.exs and all its wrapper scripts]

# Actuals (#2632)
actuals:
  tokens: 9524
  tasks: 3
  commits: 3
plan_head_before: f6d4dca0

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Non-authorizing state-machine transition: hard-code the target shape, never derive it from caller input, then self-check the result through the same validator used everywhere else before returning it."
    - "Evidence-gated bash wrapper: fetch live evidence from an external API, then re-verify it through an existing hardened single-purpose script rather than re-implementing its checks."
    - "Bounded workflow self-heal: attempt a recovery step into a temp file first; only on success does the control's existing success path run against the healed copy, with the failure path completely unchanged."

key-files:
  created:
    - scripts/release_policy_close_out.sh
    - test/scripts/release_policy_close_out_test.exs
  modified:
    - scripts/release_policy.exs
    - test/scripts/release_policy_test.exs
    - .github/workflows/release-please.yml
    - test/scripts/release_policy_contract_test.exs

key-decisions:
  - "Close-out is a new CLI verb that prints its successor (mirrors capture-candidate's convention), not a workflow granted contents:write. The publish workflow's HEX_API_KEY-holding jobs were rejected as an authorization-expansion target for a bookkeeping fix (design_decision option b)."
  - "Accepted input statuses are authorized, published, and completed — deliberately including authorized, since the actual 2.5.0 strand shape was authorized + publication: not_started, not published."
  - "Checksums are read only from the live Hex release API and re-verified through the existing release_policy_hex_release_state.sh; the wrapper has no argument that accepts a caller-supplied checksum."
  - "Self-heal in release-please.yml operates only on the temp git-show copy of the protected-base ledger, never writes .planning/release-target.json in the working tree, and never pushes — persisting a healed ledger stays a one-command maintainer action (release_policy_close_out.sh --write)."

requirements-completed: ["QUICK-260916-ldh"]

coverage:
  - id: D1
    description: "close_out/3 and the close-out CLI verb return a hard-coded, self-validated inactive successor for an authorized/published/completed ledger and refuse every malformed or evidence-mismatched input"
    requirement: "QUICK-260916-ldh"
    verification:
      - kind: unit
        ref: "test/scripts/release_policy_test.exs (7 close-out tests, incl. non-authorizing property and baseline-advance checks)"
        status: pass
    human_judgment: false
  - id: D2
    description: "release_policy_close_out.sh fetches live Hex checksums, re-verifies them through release_policy_hex_release_state.sh, resolves the release tag, and applies --write atomically without ever accepting a caller-supplied checksum"
    requirement: "QUICK-260916-ldh"
    verification:
      - kind: unit
        ref: "test/scripts/release_policy_close_out_test.exs (10 tests: happy path, --write, endpoint-order, and 5 fail-closed refusal cases)"
        status: pass
    human_judgment: false
  - id: D3
    description: "release-please.yml capture control self-heals a stranded authorized/published/completed ledger with a distinct release_target_closed_out reason instead of failing closed forever, with no change to failure-path behavior and no write/push of the repo ledger"
    requirement: "QUICK-260916-ldh"
    verification:
      - kind: unit
        ref: "test/scripts/release_policy_contract_test.exs (new self-heal wiring test + updated capture-candidate call-site assertions)"
        status: pass
      - kind: other
        ref: "python3 -c \"import yaml; yaml.safe_load(open('.github/workflows/release-please.yml'))\" and git diff --quiet -- .planning/release-target.json"
        status: pass
    human_judgment: false

duration: 22min
completed: 2026-09-16
status: complete
---

# Phase quick-260916-ldh: Add a close-out path for stranded release-target ledgers

**Non-authorizing `close-out` verb + evidence-gated wrapper + release-please self-heal, so a real Hex release no longer strands the ledger and fails every subsequent run closed.**

## Performance

- **Duration:** 22 min
- **Started:** 2026-09-16T15:19:08-04:00
- **Completed:** 2026-09-16T15:41:01-04:00
- **Tasks:** 3
- **Files modified:** 6 (2 created, 4 modified)

## Accomplishments
- `close_out/3` and the `close-out` CLI verb in `scripts/release_policy.exs`: hard-codes the `inactive`/`unauthorized`/`not_started` successor shape, nils out candidate/proposal/digest/tag-sha fields, and re-runs `validate_target/1` on its own output before returning — so no input can make it emit an authorizing ledger.
- `scripts/release_policy_close_out.sh`: an evidence-gated wrapper that fetches each candidate package's checksum straight from the Hex release API, re-verifies it through the existing hardened `release_policy_hex_release_state.sh` (which rejects retired/malformed releases), resolves the core release tag to a real commit, and only then calls `close-out`. `--write` applies the printed successor atomically via a temp file + `mv`; any failed gate leaves the ledger byte-identical.
- `release-please.yml`'s proposal-capture control now attempts this close-out on a temp copy of the source ledger before falling back to its existing `proposal_identity_mismatch` / `release_target_completed` blocks. A successful heal reports the distinct `release_target_closed_out` reason and proceeds down the existing `inactive` capture path; a failed heal changes nothing about today's behavior.

## Task Commits

Each task was committed atomically:

1. **Task 1: Non-authorizing `close_out/3` + `close-out` CLI verb in the policy module** - `3b6d2aea` (fix)
2. **Task 2: Evidence-gated `release_policy_close_out.sh` wrapper** - `f60d14ff` (fix)
3. **Task 3: Self-heal the release-please capture control and contract-test the wiring** - `1b1a3a43` (fix)

_No separate plan-metadata commit — SUMMARY.md/STATE.md/ROADMAP.md commits are handled by the orchestrator per this run's execution contract (quick task, not a phase)._

## Files Created/Modified
- `scripts/release_policy.exs` - Added `close_out/3`, the `close-out` CLI clause, and its private helpers (`close_out_applicable/1`, `close_out_evidence_match/3`, `close_out_successor/3`, `close_out_hex_release_endpoints/1`)
- `test/scripts/release_policy_test.exs` - 7 new tests: successor shape, non-authorizing property across all three accepted statuses, refusal matrix, baseline-advance behavior (via `capture-candidate`), and CLI determinism/fail-closed behavior
- `scripts/release_policy_close_out.sh` - New evidence-gated wrapper (`--target`, `--repo`, `--write`)
- `test/scripts/release_policy_close_out_test.exs` - 10 new tests covering the happy path, `--write` atomicity, endpoint-order assertion, and 5 fail-closed refusal cases, all offline via a fake `curl` and a real temp `git` repo for tag resolution
- `.github/workflows/release-please.yml` - `captured|authorized)` and `completed)` branches now attempt `attempt_close_out` before their existing block logic; factored the inactive-target capture call into `capture_from_inactive_target()` so both call sites share one invocation
- `test/scripts/release_policy_contract_test.exs` - New self-heal wiring test plus updated call-site assertions for the refactored `capture_from_inactive_target` function name

## Decisions Made
- Close-out is a CLI verb that prints its result, mirroring `capture-candidate`'s existing convention, rather than granting any workflow `contents: write` — see `key-decisions` above and the plan's `<design_decision>` block for the full security rationale (rejecting option b).
- Accepted input statuses for close-out are `authorized`, `published`, and `completed` (not just `published`), because the actual failure this plan fixes strands the ledger at `authorized` + `publication: not_started`.
- The wrapper never accepts a caller-supplied checksum; it always fetches from Hex live and cross-checks through the existing retirement/format gate script.

## Deviations from Plan

None - plan executed exactly as written, including the design decision's explicit trigger shape (bounded self-heal in the workflow, not a direct workflow push to `main`).

## Issues Encountered
- Initial test-writing pass for the wrapper had two self-inflicted bugs, both fixed before considering the task done: (1) the fake-curl log double-counted each Hex endpoint because the wrapper's own fetch and `release_policy_hex_release_state.sh`'s independent re-verification both hit the same URL — fixed by deduping the log in the test rather than changing the (intentional) double-check design; (2) a published-ledger fixture used a hardcoded fake tag SHA instead of the real SHA of the test's own temp git repo, which only surfaced as a failure once other tests ran first and shifted line numbers used for debugging — fixed by resolving the real tag SHA in `setup` and threading it through the fixture. Neither reached committed code; both were caught and fixed during this task's own`mix test` iteration.

## User Setup Required

None - no external service configuration required. (The wrapper is invoked by the workflow and, when a maintainer chooses to persist the heal, via `scripts/release_policy_close_out.sh --write` by hand — no new secrets or permissions.)

## Next Phase Readiness
- The mechanism is in place; `.planning/release-target.json` itself is untouched by this plan (it was already closed out by hand in PR #266, which this branch stacks on).
- No further action needed for this quick task. A future genuine release-please run against a real stranded ledger is the first live exercise of the self-heal path; nothing here depends on that happening before this task is considered complete.

---
*Phase: quick-260916-ldh*
*Completed: 2026-09-16*

## Self-Check: PASSED

All created/modified files present on disk (`scripts/release_policy_close_out.sh`, `test/scripts/release_policy_close_out_test.exs`, `scripts/release_policy.exs`, `test/scripts/release_policy_test.exs`, `.github/workflows/release-please.yml`, `test/scripts/release_policy_contract_test.exs`) and all three task commits (`3b6d2aea`, `f60d14ff`, `1b1a3a43`) found in git history.
