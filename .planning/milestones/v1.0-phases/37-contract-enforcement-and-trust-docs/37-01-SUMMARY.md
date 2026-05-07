---
phase: 37-contract-enforcement-and-trust-docs
plan: 01
subsystem: testing-docs
tags: [testing, docs, fake-adapter, oban, proof]
requires:
  - phase: 36
    provides: compatibility posture and existing support-contract lanes
provides:
  - canonical testing guide for Fake, inline async, Oban, cross-process, and PubSub lanes
  - deterministic docs proof for the testing contract
  - aligned public helper docs for TestAssertions, MailerCase, and Oban helpers
affects: [guides, support-contract-core, tier1-docs]
tech-stack:
  added: []
  patterns: [canonical guide plus deterministic docs test]
key-files:
  created: [test/mailglass/docs/testing_guide_test.exs]
  modified: [guides/testing.md, lib/mailglass/test_assertions.ex, test/support/mailer_case.ex, test/support/oban_helpers.ex]
requirements-completed: [PROOF-03]
completed: 2026-05-05
---

# Phase 37-01 Summary

Published the canonical adopter-facing testing contract in `guides/testing.md`, covering the baseline `deliver/2` and `deliver_later/2` path first, then the explicit Oban, cross-process, and PubSub exception lanes.

## Verification

- `mix test test/mailglass/docs/testing_guide_test.exs test/mailglass/test_assertions_test.exs test/mailglass/mailer_case_test.exs test/mailglass/test_assertions_pubsub_test.exs --warnings-as-errors`

## Notes

- The docs proof was intentionally written against shipped semantics rather than aspirational wording, so helper drift now fails fast.
- No task-specific commit was created because the repository already contained unrelated local modifications.
