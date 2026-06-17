---
phase: 106-day-2-guides-go-live-checklist-error-troubleshooting-map
verified: 2026-06-17T12:14:00Z
status: passed
score: 10/10 must-haves verified
overrides_applied: 0
re_verification: false
---

# Phase 106: Day-2 Guides — Go-Live Checklist + Error/Troubleshooting Map Verification Report

**Phase Goal:** Deliver two new day-2 operator guides — `guides/production-go-live-checklist.md` (OPS-01) and `guides/errors-and-troubleshooting.md` (OPS-02) — registered in HexDocs and CI-gated by docs-contract assertions.
**Verified:** 2026-06-17T12:14:00Z
**Status:** PASSED
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `guides/production-go-live-checklist.md` exists with exactly 7 ## sections | VERIFIED | `grep -c "^## "` returns 7 |
| 2 | Checklist surfaces both `mix mail.doctor` and `mix mailglass.doctor` as distinct commands with distinct purposes | VERIFIED | `mix mail.doctor` in "Deliverability" section (DNS checks, requires app.start); `mix mailglass.doctor` in "Webhook wiring" section (OFFLINE, three-state exit) |
| 3 | `guides/errors-and-troubleshooting.md` exists with exactly 10 ## sections | VERIFIED | `grep -c "^## "` returns 10 |
| 4 | StreamPolicyError has a dedicated ## section sourced from its module (`:stream_policy_violated` present, not from api_stability.md) | VERIFIED | `## StreamPolicyError` at line 123; `:stream_policy_violated` literal present; section explicitly notes the type is sourced from `stream_policy_error.ex` and that api_stability.md has no dedicated section for it |
| 5 | Every section in the errors guide routes canonical type/retryable truth to `docs/api_stability.md` | VERIFIED | Each of the 10 struct sections ends with "For the canonical closed `:type` atom set and Retryable policy, see [docs/api_stability.md](...)" |
| 6 | Errors guide cross-links `operator-incident-support.md` and `webhook-troubleshooting.md` without absorbing them | VERIFIED | Both cross-links in the intro paragraph; `operator-incident-support.md` not absorbed; `webhook-troubleshooting.md` additionally cross-linked from the SignatureError section |
| 7 | Both guides registered in mix.exs `extras:` and `groups_for_extras: [Guides: ...]` | VERIFIED | `grep -c '"guides/production-go-live-checklist.md"' mix.exs` = 2; `grep -c '"guides/errors-and-troubleshooting.md"' mix.exs` = 2; `main: "getting-started"` unchanged |
| 8 | `docs_contract_test.exs` contains OPS-01 section-presence assertion and OPS-02 error-coverage assertion | VERIFIED | Four new tests at lines 358–415; test names match plan verbatim |
| 9 | `mix test test/mailglass/docs_contract_test.exs` exits 0 | VERIFIED | 32 tests, 0 failures, 1 skipped (pre-existing Phase 38 skip) |
| 10 | `docs/api_stability.md` correctly says "ten error structs" and includes StreamPolicyError in stable list | VERIFIED | `grep "ten error structs"` = 1 match (line 214); `grep "six error structs"` = 0 matches; `Mailglass.StreamPolicyError` present at line 60 |

**Score:** 10/10 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `guides/production-go-live-checklist.md` | Pre-production verification surface for operators | VERIFIED | 7 ## sections; both doctor commands; cross-links to multi-tenancy, telemetry, dkim-setup, webhooks |
| `guides/errors-and-troubleshooting.md` | Unified error struct map | VERIFIED | 10 ## sections in @error_modules order; StreamPolicyError sourced from module |
| `mix.exs` | Docs registration for both guides | VERIFIED | 2 occurrences of each guide path (extras: + Guides:) |
| `test/mailglass/docs_contract_test.exs` | OPS-01 and OPS-02 contract assertions | VERIFIED | 4 new tests inside "Guide contracts" describe block |
| `docs/api_stability.md` | Corrected error count and stable list | VERIFIED | "six"→"ten" corrected; StreamPolicyError added |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `guides/errors-and-troubleshooting.md` | `docs/api_stability.md` | per-section remediation cross-link | VERIFIED | 11 occurrences of "api_stability" in errors guide (intro + one per struct section) |
| `guides/production-go-live-checklist.md` | `guides/multi-tenancy.md` | cross-link | VERIFIED | "[Multi-Tenancy](./multi-tenancy.md)" present |
| `test/mailglass/docs_contract_test.exs` | `mix.exs` | Regex.scan on mix_exs content | VERIFIED | Regex.scan pattern `"guides/production-go-live-checklist\.md"` in two registration tests |
| `test/mailglass/docs_contract_test.exs` | `guides/errors-and-troubleshooting.md` | File.read! + literal presence check | VERIFIED | OPS-02 test asserts all 10 short names and api_stability.md cross-link |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Docs contract suite passes with 4 new tests | `mix test test/mailglass/docs_contract_test.exs` | 32 tests, 0 failures, 1 skipped | PASS |
| Checklist has 7 ## sections | `grep -c "^## " guides/production-go-live-checklist.md` | 7 | PASS |
| Errors guide has 10 ## sections | `grep -c "^## " guides/errors-and-troubleshooting.md` | 10 | PASS |
| Both guides registered 2x in mix.exs | `grep -c '"guides/production-go-live-checklist.md"' mix.exs` | 2 | PASS |
| Both guides registered 2x in mix.exs | `grep -c '"guides/errors-and-troubleshooting.md"' mix.exs` | 2 | PASS |
| "six error structs" absent from api_stability.md | `grep -c "six error structs" docs/api_stability.md` | 0 | PASS |
| "ten error structs" present in api_stability.md | `grep "ten error structs" docs/api_stability.md` | 1 match at line 214 | PASS |
| StreamPolicyError in api_stability.md stable list | `grep "StreamPolicyError" docs/api_stability.md` | 1 match at line 60 | PASS |
| `stream_policy_violated` sourced from module, not api_stability.md | `grep "stream_policy_violated" guides/errors-and-troubleshooting.md` | present in StreamPolicyError section | PASS |
| main: "getting-started" unchanged | `grep "main:" mix.exs` | `main: "getting-started"` | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| OPS-01 | 106-01, 106-02 | `guides/production-go-live-checklist.md` with all 7 topics, registered, CI-gated | SATISFIED | File exists with 7 ## sections covering all required topics; 2 registrations in mix.exs; contract test passes |
| OPS-02 | 106-01, 106-02 | `guides/errors-and-troubleshooting.md` with all 10 structs, registered, CI-gated | SATISFIED | File exists with 10 ## sections for all 10 structs in @error_modules order; StreamPolicyError sourced from module; 2 registrations in mix.exs; contract test passes |

### Anti-Patterns Found

No debt markers (TBD, FIXME, XXX, TODO, HACK, PLACEHOLDER) found in any files created or modified by this phase. The grep hits in `docs_contract_test.exs` were within existing string-content assertions about guide text (e.g., asserting "JTBD Docs Refresh Protocol" appears in MAINTAINING.md) — not debt markers in phase-authored code.

No stub patterns found. Both guides are substantive prose with real content, not placeholder text. No hardcoded-empty returns or orphaned artifacts.

### Human Verification Required

None. All acceptance criteria are mechanically verifiable and were verified by the scoped test run and grep checks above.

### Gaps Summary

No gaps. All 10 must-have truths are verified. The phase goal is achieved.

---

_Verified: 2026-06-17T12:14:00Z_
_Verifier: Claude (gsd-verifier)_
