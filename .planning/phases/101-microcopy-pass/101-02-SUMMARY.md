---
phase: 101-microcopy-pass
plan: "02"
subsystem: mailglass_admin
tags: [voice-test, conformance, microcopy, COPY-LD, banned-words, data-driven]
dependency_graph:
  requires: [101-01]
  provides: [COPY-01-conformance-gate]
  affects: [mailglass_admin/test/mailglass_admin/voice_test.exs]
tech_stack:
  added: []
  patterns: [data-driven-banned-words, script-strip, source-grep-guard, operator-conn-session]
key_files:
  created: []
  modified:
    - mailglass_admin/test/mailglass_admin/voice_test.exs
decisions:
  - "@banned_words module attribute makes banned-word list data-driven and cheaply extensible (D-09)"
  - "strip_scripts/1 extracted as private helper; reused on all three surfaces to avoid phoenix.mjs noops false positive (D-10)"
  - "LD-12 asserted using HTML-entity form 'didn&#39;t' because HEEx escapes apostrophes in text nodes"
  - "Inbound surface mounted with ?provider=no-such-provider filter to force :filtered empty state for LD-03 assertion without seeding records"
  - "Flash strings covered by source-level File.read! grep guards per D-11 (flash-only strings not present in first render)"
metrics:
  duration: "6 minutes"
  completed: "2026-06-16"
  tasks_completed: 1
  files_modified: 1
---

# Phase 101 Plan 02: Microcopy Pass — Voice Conformance Check (3 Surfaces) Summary

**One-liner:** Extended voice_test.exs with data-driven @banned_words, strip_scripts/1 helper, and Operator + Inbound describe blocks covering banned-word refutation, per-surface canonical-string assertions (LD-03/11/12/14/16), and source-level flash string guards (LD-13/16).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Extend voice_test.exs with data-driven 3-surface conformance check | a3982c36 | mailglass_admin/test/mailglass_admin/voice_test.exs |

## New Tests Added

### Structure Overview

| Describe Block | Tests Added | Purpose |
|---|---|---|
| `banned exclamations` (refactored) | 1 (refactored) | Preview banned-word check — now uses @banned_words + strip_scripts/1 |
| `Operator surface (/ops/mail)` | 2 | Banned-word + canonical strings for operator surface |
| `Inbound surface (/ops/mail/inbound)` | 2 | Banned-word + canonical strings for inbound surface |
| `Flash string source guards` | 2 | Source-level grep guards for action-only flash strings |

**Total new tests: 6** (2 Operator + 2 Inbound + 2 source guards). Existing 3 Preview tests preserved and passing.

### Canonical Strings Asserted Per Surface

| LD-ID | Surface | String Asserted | Assertion Type |
|-------|---------|----------------|----------------|
| LD-11 | Operator | "Delivery never arrived? Start here." | Rendered HTML |
| LD-14 / spot-check | Operator | "Operator overview" | Rendered HTML (initial mount heading) |
| LD-03 | Inbound | "No InboundMessages match these filters" | Rendered HTML (filtered empty state) |
| LD-12 | Inbound | "InboundMessage didn&#39;t route as expected? Inspect the routing trace." | Rendered HTML (HTML-entity apostrophe) |
| LD-16 | Inbound | "Select an InboundMessage to inspect its Mailbox routing, execution timeline, and raw evidence." | Rendered HTML (no-selection pane) |
| LD-13 | Inbound (flash) | "InboundMessage's timeline" | Source-level grep (inbound_live.ex) |
| LD-16 | Inbound (flash) | Full locked string in put_flash context | Source-level grep (inbound_live.ex) |

### Design Decisions

**@banned_words attribute (D-09):** Added at module level as `~w[oops whoops "uh oh" "something went wrong"]`. Each surface's banned-word test uses `Enum.each(@banned_words, ...)` — one new provider or surface extends the check in a single list edit.

**strip_scripts/1 helper (D-10):** Extracted the existing inline `Regex.replace(~r/<script\b[^>]*>.*?<\/script>/si, html, "")` into a `defp strip_scripts(html)` helper. The existing Preview test was refactored to call `html |> strip_scripts() |> String.downcase()`. All three surfaces use this helper.

**HTML-entity apostrophe in LD-12 (deviation Rule 1 fix):** HEEx text nodes HTML-escape apostrophes as `&#39;`. The source string is `"InboundMessage didn't route..."` with a straight apostrophe, but the rendered HTML contains `didn&#39;t`. The assertion uses the HTML-entity form directly. This is NOT a copy violation — the rendered text is correct; it's a test implementation detail.

**Inbound filtered empty state for LD-03:** The voice test mounts `/ops/mail/inbound?tenant_id=voice-test-tenant&provider=no-such-provider`. The `provider` filter parameter makes `filters_active?/1` return true (line 530 in inbound_live.ex), forcing `empty_state_for/2` to return `:filtered` → "No InboundMessages match these filters". No record seeding required.

**Source-level guards for flash strings (D-11):** `inbound_live.ex` lines 219 and 227 only fire on user actions (`confirm_replay` event). The voice test uses `File.read!("lib/mailglass_admin/inbound_live.ex")` (CWD-relative from `mailglass_admin/`) to assert the locked strings exist in source — this covers action-only copy without requiring event dispatch.

**operator_conn/1 private helper:** Added to replicate the session shape from `OperatorLive` and `InboundLive` tests (same `current_user_id`, `auth_method`, `recent_auth_at` keys) so operator-guarded routes mount correctly.

## Verification

```
cd mailglass_admin && mix test test/mailglass_admin/voice_test.exs --seed 0
```

Exit code: 0. Output: "9 tests, 0 failures (1 excluded)" — the excluded test is the pre-existing `@tag :skip` on the persistent_term gating test.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] HEEx apostrophe HTML-entity encoding in LD-12 assertion**

- **Found during:** Task 1 (first test run)
- **Issue:** The plan's `<behavior>` block specifies asserting `"InboundMessage didn't route as expected? Inspect the routing trace."` with a straight apostrophe, but HEEx escapes apostrophes in text nodes as `&#39;`. The test failed with the straight-apostrophe form.
- **Fix:** Changed the assertion to use the HTML-entity form: `"InboundMessage didn&#39;t route as expected? Inspect the routing trace."`. The source string in shell.ex is unchanged (correct straight apostrophe); only the test assertion uses the entity form to match actual rendered output.
- **Files modified:** mailglass_admin/test/mailglass_admin/voice_test.exs
- **Commit:** a3982c36 (same commit — fixed before final commit)

## Self-Check: PASSED

- [x] `mailglass_admin/test/mailglass_admin/voice_test.exs` modified — confirmed
- [x] Commit `a3982c36` exists — confirmed (`git log --oneline -1` shows it)
- [x] `@banned_words` module attribute present — confirmed
- [x] `defp strip_scripts/1` helper present — confirmed
- [x] `describe "Operator surface (/ops/mail)"` block present — confirmed
- [x] `describe "Inbound surface (/ops/mail/inbound)"` block present — confirmed
- [x] `describe "Flash string source guards"` block present — confirmed
- [x] 9 tests pass, 1 excluded (pre-existing skip) — confirmed
- [x] Existing 3 describe blocks preserved and passing — confirmed
- [x] No new test files created — confirmed
