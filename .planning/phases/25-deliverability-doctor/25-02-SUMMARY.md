---
phase: 25-deliverability-doctor
plan: "02"
subsystem: infra
tags: [deliverability, dns, spf, dkim, dmarc, stream_data]
requires:
  - phase: 25-01
    provides: shared deliverability result contract and normalized DNS fact collection
provides:
  - SPF analyzer with recursive lookup and void-lookup accounting
  - explicit-selector DKIM analyzer with revoked and weak-key advisories
  - DMARC analyzer with policy posture and tag advisories
affects: [deliverability, mix-task, formatter, admin]
tech-stack:
  added: []
  patterns: [pure protocol analyzers, evidence-first findings, selector-specific uncertainty]
key-files:
  created:
    - lib/mailglass/deliverability/spf.ex
    - lib/mailglass/deliverability/dkim.ex
    - lib/mailglass/deliverability/dmarc.ex
    - test/mailglass/deliverability/spf_test.exs
    - test/mailglass/deliverability/dkim_test.exs
    - test/mailglass/deliverability/dmarc_test.exs
    - test/mailglass/properties/deliverability_spf_property_test.exs
  modified:
    - .planning/phases/25-deliverability-doctor/25-02-SUMMARY.md
key-decisions:
  - "Keep SPF, DKIM, and DMARC analyzers pure over normalized fact buckets so later runtime aggregation can reuse the same contract."
  - "Model DKIM trust per explicit selector only; empty selector input returns cannot_verify instead of guessed provider defaults."
  - "Expose lookup counts, visited includes and redirects, and DMARC posture as facts so formatter and later plans can explain outcomes without reparsing prose."
patterns-established:
  - "Deliverability analyzers return %{findings, facts} and never raise on malformed DNS-shaped input."
  - "Protocol warnings and cannot_verify outcomes include evidence fields instead of collapsing uncertainty into binary pass/fail."
requirements-completed: [DOCTOR-01, DOCTOR-02, DOCTOR-03]
duration: 6min
completed: 2026-05-01
---

# Phase 25 Plan 02: Deliverability Protocol Analyzer Summary

**SPF recursion-aware lookup diagnostics plus explicit-selector DKIM and policy-aware DMARC findings that preserve uncertainty instead of guessing**

## Performance

- **Duration:** 6 min
- **Started:** 2026-05-01T20:39:00Z
- **Completed:** 2026-05-01T20:45:07Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments
- Added an SPF analyzer that distinguishes missing, malformed, weak-terminal, lookup-limit, void-lookup, and resolver-uncertain states with evidence.
- Added an explicit-selector DKIM analyzer that treats missing selectors as `cannot_verify`, flags revoked keys, and warns on weak selector posture without claiming domain-wide success.
- Added a DMARC analyzer that classifies `p=none`, `p=quarantine`, and `p=reject` correctly while surfacing alignment, reporting, and subdomain-policy advisories.

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement the SPF analyzer with structural failure and uncertainty accounting** - `176adc6` (feat)
2. **Task 2: Implement explicit-selector DKIM and policy-aware DMARC analyzers** - `df2d6fd` (feat)

## Files Created/Modified
- `lib/mailglass/deliverability/spf.ex` - recursive SPF parsing, lookup accounting, structural failure detection, and evidence-rich findings
- `lib/mailglass/deliverability/dkim.ex` - explicit-selector DKIM findings for missing selectors, malformed data, revoked keys, delegated CNAMEs, and weak keys
- `lib/mailglass/deliverability/dmarc.ex` - DMARC policy posture analysis with tag parsing and advisory findings for alignment, `rua`, and `sp`
- `test/mailglass/deliverability/spf_test.exs` - representative SPF cases for missing, multiple, malformed, weak-terminal, lookup-pressure, and void-lookup outcomes
- `test/mailglass/properties/deliverability_spf_property_test.exs` - property coverage proving recursive lookup pressure at or above 10 never returns `:pass`
- `test/mailglass/deliverability/dkim_test.exs` - DKIM selector, revoked key, malformed data, and CNAME delegation coverage
- `test/mailglass/deliverability/dmarc_test.exs` - DMARC monitoring, multiple-record, malformed-tag, and enforcement-advisory coverage

## Decisions Made
- Used selector-specific `pass`, `warn`, `fail`, and `cannot_verify` findings for DKIM rather than inventing a domain-level DKIM verdict.
- Counted SPF lookup-causing mechanisms structurally and followed nested include/redirect TXT records through the resolver seam to keep lookup-limit findings honest.
- Recorded DMARC `posture` in the facts bucket so later plans can reuse enforcement state for BIMI readiness without inferring it from prose.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first SPF test pass exposed an unconfigured nested include fixture and an off-by-one lookup-count generator in the property suite; both were corrected before the Task 1 commit.
- The first DKIM/DMARC compile pass surfaced an invalid guard in a helper; it was fixed before the Task 2 commit.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `Mailglass.Deliverability.run/1` can now aggregate SPF, DKIM, and DMARC analyzer output without changing the result contract.
- DMARC posture is available as structured facts for the MX/BIMI and formatter work planned next.
- The property and unit suites now pin the trust-sensitive uncertainty semantics that future runtime and formatter plans must preserve.

---
*Phase: 25-deliverability-doctor*
*Completed: 2026-05-01*
