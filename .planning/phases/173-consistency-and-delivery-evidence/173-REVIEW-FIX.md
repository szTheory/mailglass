---
phase: 173
status: fixed
iterations: 1
fixed: 3
skipped: 0
deferred: 0
---

# Phase 173: Code Review Fixes

## Fixed Issues

### CR-01: Mixed capture dirtiness can be recorded as a clean candidate — BLOCKER

- Reject inconsistent `candidate_dirty` values while building a checkpoint; derive the aggregate conservatively.
- Require every retained capture to explicitly prove `candidate_dirty: false` before exact-candidate acceptance.
- Added Node and fake-candidate regressions for mixed dirty/clean capture metadata.
- Validation: 12 evidence Node tests passed; `bash scripts/test_check_phase173_candidate.sh` passed.
- Commit: `ae0de199`.

### WR-01: Default Compose E2E run lacks the reset identity required by its specs — WARNING

- Route the supported `make demo-e2e` entry point through the existing randomized, disposable Compose runner.
- Document that this target uses an isolated app/database and does not reset the retained demo.
- Keep direct Compose use fail-closed when no run-owned identity is supplied.
- Validation: `bash scripts/test_run_demo_browser_evidence.sh` passed, including its assertion that `make demo-e2e` invokes the wrapper.
- Commit: `03b43c54`.

### WR-02: Actual capture writer accepts non-PNG bytes as screenshot evidence — WARNING

- Validate the PNG signature, complete IHDR chunk and CRC, legal color/depth/encoding fields, and bounded nonzero dimensions before hashing actual capture bytes.
- Replace the truncated success fixture with a valid PNG and reject non-PNG and truncated-IHDR fixtures.
- Validation: focused ExUnit suite passed (11 tests); both changed Elixir files pass `mix format --check-formatted`.
- Commit: `4e8d9e5b`.

## Skipped Issues

None.

## Verification Boundary

These fixes close all findings from the Phase 173 source review. They do not create exact-SHA required CI evidence or resolve the owner-controlled acceptance inputs recorded by Plan 06. The actual candidate gate was not rerun because it consumes acceptance paths that remain excluded from this work.
