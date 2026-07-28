---
phase: 138-schema-prefix-no-search-path-hardening
plan: 02
subsystem: database
tags: [ecto, postgres, schema-prefix, inbound, raw-repo, tdd]

requires:
  - phase: 138-01
    provides: Core hostile runtime schema-prefix proofs and explicit raw callback prefix pattern
provides:
  - Inbound raw-repo extension-point prefix contract tests
  - Explicit local schema_opts helpers for inbound replay, execution load, and replay selector resolution
  - SCHEMA-04 proof that supplied raw repos receive explicit prefix opts while facade defaults remain intact
affects: [138-schema-prefix-no-search-path-hardening, mailglass_inbound, schema-prefix, raw-repo]

tech-stack:
  added: []
  patterns:
    - Inbound raw repo extension points use local schema_opts/0 returning prefix: MailglassInbound.Config.schema()
    - Capture-repo contract tests assert raw repo opts without subject, body, header, or raw MIME diagnostics

key-files:
  created:
    - mailglass_inbound/test/mailglass_inbound/schema_prefix_contract_test.exs
  modified:
    - mailglass_inbound/lib/mailglass_inbound/internal/replay.ex
    - mailglass_inbound/lib/mailglass_inbound/execution.ex
    - mailglass_inbound/lib/mix/tasks/mailglass.inbound.replay.ex

key-decisions:
  - "Keep MailglassInbound.Repo as the default facade for inbound replay extension points; only supplied raw repos need explicit local schema opts."
  - "Prove the raw-repo prefix contract with process-local capture repos so diagnostics stay limited to opts, counts, IDs, and statuses."

patterns-established:
  - "Inbound raw repo contract: add a local schema_opts/0 helper and pass it to repo.one/2, repo.get/3, and repo.all/2 at extension points."
  - "TDD RED for prefix contracts: capture no-opts calls as empty opts so failures are missing-prefix assertions, not undefined function errors."

requirements-completed: [SCHEMA-04]

duration: 5 min
completed: 2026-07-07
status: complete
---

# Phase 138 Plan 02: Inbound Raw-Repo Extension-Point Prefix Contract Summary

**Inbound replay raw-repo extension points now preserve facade defaults and pass explicit schema prefix opts when a raw repo is supplied.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-07-07T13:39:02Z
- **Completed:** 2026-07-07T13:44:32Z
- **Tasks:** 2 completed
- **Files modified:** 4

## Accomplishments

- Added `MailglassInbound.SchemaPrefixContractTest` covering `Internal.Replay.replay/2`, `Execution.load/2`, and `mix mailglass.inbound.replay` selector resolution.
- Added local `schema_opts/0` helpers in the three inbound raw-repo extension modules.
- Threaded `prefix: MailglassInbound.Config.schema()` through raw `repo.one/2`, `repo.get/3`, and `repo.all/2` calls without changing the default facade path.

## Task Commits

Each TDD gate was committed atomically:

1. **Task 1 RED: Inbound raw-repo prefix contract tests** - `364825c3` (`test`)
2. **Task 2 GREEN: Inbound raw-repo schema opts implementation** - `398b72b4` (`feat`)

## Files Created/Modified

- `mailglass_inbound/test/mailglass_inbound/schema_prefix_contract_test.exs` - Capture-repo contract tests for raw `one`, `get`, and `all` opts.
- `mailglass_inbound/lib/mailglass_inbound/internal/replay.ex` - Adds `schema_opts/0` and passes it to all raw replay `repo.one/2` reads.
- `mailglass_inbound/lib/mailglass_inbound/execution.ex` - Adds `schema_opts/0` and passes it to both `Execution.load/2` raw `repo.get/3` reads.
- `mailglass_inbound/lib/mix/tasks/mailglass.inbound.replay.ex` - Adds `schema_opts/0` and passes it to replay selector `repo.all/2`.

## Decisions Made

- Keep default inbound facade behavior unchanged through `Keyword.get(opts, :repo, MailglassInbound.Repo)`.
- Use module-local `schema_opts/0` helpers instead of adding a new inbound facade API for this narrow hardening pass.
- Keep tests free of subject, body, header, and raw MIME diagnostics; assertions inspect functions, opts, statuses, and generated IDs only.

## Verification

- RED gate: `cd mailglass_inbound && output=$(mix test test/mailglass_inbound/schema_prefix_contract_test.exs --warnings-as-errors 2>&1); cmd_status=$?; printf "%s\n" "$output"; test "$cmd_status" -ne 0 && printf "%s\n" "$output" | grep -E "Assertion with == failed" && printf "%s\n" "$output" | grep -E ":prefix|Keyword\.get\(opts, :prefix\)"` - passed by observing three missing-prefix assertion failures.
- GREEN gate: `cd mailglass_inbound && mix test test/mailglass_inbound/schema_prefix_contract_test.exs --warnings-as-errors` - 3 tests, 0 failures.
- Formatting: `cd mailglass_inbound && mix format --check-formatted lib/mailglass_inbound/internal/replay.ex lib/mailglass_inbound/execution.ex lib/mix/tasks/mailglass.inbound.replay.ex test/mailglass_inbound/schema_prefix_contract_test.exs` - passed.
- Source contracts: scans confirmed all three files define `schema_opts/0`, `Internal.Replay` has no bare `repo.one()` calls, `Execution.load/2` passes opts to raw `get` calls, and replay selector resolution passes opts to `repo.all/2`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Adjusted RED verification shell variable for zsh**
- **Found during:** Task 1 RED verification
- **Issue:** The plan's shell snippet used `status`, which is a read-only variable in the zsh execution shell.
- **Fix:** Re-ran the same verification with `cmd_status` while preserving the command's intended exit behavior and grep assertions.
- **Files modified:** None
- **Verification:** RED verification exited 0 only after observing the expected missing-prefix assertion failures.
- **Committed in:** Not applicable - verification command adjustment only.

---

**Total deviations:** 1 auto-handled (1 blocking verification-shell issue)
**Impact on plan:** No product or test scope change; the verification assertion stayed identical.

## Issues Encountered

- `mix format --check-formatted` required rewrapping `mailglass_inbound/lib/mailglass_inbound/execution.ex`; `mix format` was run on the changed inbound files and the check then passed.

## Known Stubs

None - only intentional ExUnit test doubles were added.

## Authentication Gates

None.

## User Setup Required

None - no external service configuration required.

## TDD Gate Compliance

- RED commit present: `364825c3`
- GREEN commit present after RED: `398b72b4`
- REFACTOR commit: none needed

## Next Phase Readiness

Ready for `138-03-PLAN.md`. SCHEMA-04 now has focused contract proof, leaving SCHEMA-03 static/raw callback guard work and the focused verification alias for later Phase 138 plans.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/138-schema-prefix-no-search-path-hardening/138-02-SUMMARY.md`.
- Key files exist: `mailglass_inbound/test/mailglass_inbound/schema_prefix_contract_test.exs`, `mailglass_inbound/lib/mailglass_inbound/internal/replay.ex`, `mailglass_inbound/lib/mailglass_inbound/execution.ex`, `mailglass_inbound/lib/mix/tasks/mailglass.inbound.replay.ex`.
- Task commits exist: `364825c3`, `398b72b4`.
- Final focused verification passed: `cd mailglass_inbound && mix test test/mailglass_inbound/schema_prefix_contract_test.exs --warnings-as-errors`.

---
*Phase: 138-schema-prefix-no-search-path-hardening*
*Completed: 2026-07-07*
