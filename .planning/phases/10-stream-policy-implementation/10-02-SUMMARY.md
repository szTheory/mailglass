---
phase: 10-stream-policy-implementation
plan: 02
subsystem: stream_policy
tags: [policy, runtime, error_struct]
requires: [10-01]
provides: [StreamPolicyError, policy_check]
affects: [pipeline, adapter]
tech-stack:
  added: []
  patterns: [error_struct, telemetry]
key-files:
  created:
    - lib/mailglass/errors/stream_policy_error.ex
  modified:
    - lib/mailglass/stream.ex
    - test/mailglass/stream_test.exs
key-decisions:
  - Return `{:error, %StreamPolicyError{}}` for invalid streams instead of raising, enabling seamless integration into `with` macro pipelines.
  - Mitigated T-10-02 by explicitly requiring a `mailable` for the `:bulk` stream to ensure auditability.
metrics:
  duration: 15
  tasks-completed: 2
  files-touched: 3
---

# Phase 10 Plan 02: Runtime StreamPolicy Stage Implementation Summary

Implemented runtime enforcement of stream policies returning a structured error, securing the pipeline boundary and preventing untraceable bulk messaging.

## Overview

The `Mailglass.Stream.policy_check/1` function now actively enforces rules such as requiring a `:mailable` on the `:bulk` stream to satisfy the `Feedback-ID` tracking requirements and prevent anonymous mass emailing. By returning `{:error, %StreamPolicyError{}}` instead of raising, existing callers relying on `with :ok <- Stream.policy_check(msg)` are unaffected and error handling works correctly.

## Tasks Completed

- **Task 1: Define Mailglass.StreamPolicyError**
  - Created a new error struct adhering to `Mailglass.Error` behaviour with `:detail` fields mapping to violation context.
- **Task 2: Implement real policy_check/1** (Commits: `3c77645`, `968992d`)
  - Updated `policy_check/1` to intercept `:bulk` streams missing a `mailable` and return a precise `StreamPolicyError`.
  - Added unit tests to `test/mailglass/stream_test.exs` ensuring runtime checks fail correctly.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocker] Fixed struct compile deadlock between Message and Stream**
- **Found during:** Task 2 (GREEN phase compilation)
- **Issue:** Using `%Message{}` in `Stream.policy_check` parameters while `Message` had `require Mailglass.Stream` created a cyclic struct dependency that failed full-project compilation.
- **Fix:** Switched `policy_check/1` to match on map form `%{__struct__: Mailglass.Message}` to eliminate compile-time `Message` struct dependency.
- **Files modified:** `lib/mailglass/stream.ex`
- **Commit:** `968992d`

## Threat Flags

None. The T-10-02 mitigation (`mailable` required for `:bulk`) was successfully incorporated as planned.

## Known Stubs

None found.

## Self-Check: PASSED
