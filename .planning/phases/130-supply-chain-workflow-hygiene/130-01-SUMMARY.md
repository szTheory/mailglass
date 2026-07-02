---
phase: 130-supply-chain-workflow-hygiene
plan: 01
subsystem: supply-chain / release-gate
tags: [supply-chain, mix_audit, osv, publish-gate, ci-advisory-lane, tdd]
requires:
  - Phase 129 (.tool-versions version-file CI pattern, toolchain-hashed cache key)
  - Mailglass.CILanes @advisory_lanes_ci registry + MIXCI-03 parity-drift guard
provides:
  - "mix deps.audit advisory PR lane (non-blocking) + publish-gate hard-block (SUPPLY-01)"
  - "OSV-staleness forcing function for @accepted_advisories allowlist (SUPPLY-03)"
  - "public unit-testable seams: unaccepted_deps_audit_findings/1, classify_osv_response/2, osv_get/1"
affects:
  - lib/mix/tasks/mailglass.publish.check.ex
  - .github/workflows/ci.yml
  - mix.exs
  - test/support/ci_lanes.ex
  - test/scripts/ci_parity_drift_test.exs
tech-stack:
  added:
    - "mix_audit ~> 2.1 (dev/test-only, runtime: false — zero adopter impact)"
  patterns:
    - "fail-open external HTTP (OSV.dev) via try/rescue/catch — outage never blocks a security patch"
    - "advisory-lane naming contract: 'Advisory (' substring drives gate-ci-green isAdvisory()"
    - "three-file atomic CILanes registration to satisfy MIXCI-03 anti-vacuity guard"
key-files:
  created: []
  modified:
    - mix.exs
    - .github/workflows/ci.yml
    - lib/mix/tasks/mailglass.publish.check.ex
    - test/support/ci_lanes.ex
    - test/scripts/ci_parity_drift_test.exs
    - test/mailglass/publish/audit_allowlist_test.exs
decisions:
  - "unaccepted_deps_audit_findings/1 parses the mix_audit human formatter (Name:/URL: GHSA-*) as a peer function, NOT reusing the EEF-CVE-calibrated hex.audit parser (Pitfall 5)."
  - "OSV block decision lives ONLY in Step 15 (verify_osv_freshness/1); the pre-chain call is loud-warn-only and never blocks."
  - "classify_osv_response/2 extracted as a pure, @doc-false public function so stale/active/parse-error branches are unit-testable without live HTTP."
metrics:
  duration: "~2 sessions (interrupted by a transient 529; resumed to finish GREEN + close-out)"
  completed: 2026-07-02
  tasks: 3
  files: 6
status: complete
---

# Phase 130 Plan 01: deps.audit Gate + OSV Staleness Summary

Added the `mix deps.audit` (mix_audit) advisory PR lane plus a publish-time hard-block, and an OSV.dev staleness forcing-function that prevents an accepted-advisory allowlist entry from silently outliving its upstream advisory — closing the v1.14 advisory-wave gap (SUPPLY-01 + SUPPLY-03).

## What Was Built

**Task 1 (commit `3adde80b`)** — `mix.exs`: added `{:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false}` to `deps` and `"deps.audit"` to the `ci:` alias immediately after `"hex.audit"`. Dev/test-only with `runtime: false` — no adopter impact, zero Node.

**Task 2 (commit `a7c86e42`)** — `.github/workflows/ci.yml`: added the `deps_audit_advisory` job named `Deps Audit Advisory (Elixir 1.18 / OTP 27)`, `continue-on-error: true`, `needs: [changes]`, `if: needs.changes.outputs.code == 'true'`, using the Phase 129 `.tool-versions` version-file and toolchain-hashed cache key. Reuses the existing pinned action SHAs; NOT added to `ci_green.needs` (advisory, non-required).

**Task 3 — RED (commit `01c5f63c`) then GREEN (commit `8d10afdf`)** — TDD:
- `lib/mix/tasks/mailglass.publish.check.ex`:
  - `verify_deps_audit/1` (Step 14) — runs `mix deps.audit` in the tarball audit root; a non-allowlisted finding hard-blocks delivery with a `Delivery blocked:` brand-voice message; an all-allowlisted or clean scan updates ctx and passes.
  - `unaccepted_deps_audit_findings/1` — peer parser for the mix_audit human formatter (`Name:` + `URL: .../GHSA-*`), filtered against `@accepted_advisories`. `@doc false` for unit-testability.
  - `check_osv_advisory_staleness/0`, `classify_osv_response/2`, `osv_get/1`, `verify_osv_freshness/1` (Step 15) — OSV.dev staleness gate: withdrawn → hard-block, OSV outage → fail-open + loud stderr warning, active → notice.
  - A loud-warn-always OSV notice emitted once per package run *before* the step chain (never blocks).
- CILanes three-file atomic registration: `test/support/ci_lanes.ex` `@advisory_lanes_ci`, `test/scripts/ci_parity_drift_test.exs` `matcher_for/1` clause + `matcher_lanes` MapSet entry.
- `test/mailglass/publish/audit_allowlist_test.exs`: new describe blocks for `unaccepted_deps_audit_findings/1`, `classify_osv_response/2`, and `osv_get/1` fail-open contract.

## OPEN QUESTIONS Resolved

### A4 — actual `mix deps.audit` output format (SUPPLY-01)
Ran `mix deps.audit` locally after Task 1. On a clean tree it emits `No vulnerabilities found.` and exits 0. mix_audit 2.1.x uses the `mirego/elixir-security-advisories` DB and emits a multi-line block per vulnerability with `Name:` (package) and `URL: https://github.com/advisories/GHSA-xxxx-yyyy-zzzz` (GHSA ID) lines — a different ID scheme from `mix hex.audit`'s `EEF-CVE-*`. `unaccepted_deps_audit_findings/1` is anchored to this `Name:`/`URL:.../(GHSA-\S+)` format and paired with the preceding `Name:` line, exactly as the fixture tests assert. Because `@accepted_advisories` keys are EEF-CVE IDs and the mix_audit DB uses GHSA IDs, a GHSA finding is never auto-suppressed today — that asymmetry is intended (the accepted cowlib advisories are not present in the mix_audit DB), and the allowlist filter is retained so a future GHSA-keyed acceptance would work. Documented inline in code comments.

### A3 — OSV endpoint resolution for the EEF-CVE IDs (SUPPLY-03)
Ran `curl -s "https://api.osv.dev/v1/vulns/EEF-CVE-2026-43966"` and `.../EEF-CVE-2026-43969`. **Both resolve natively with HTTP 200** — no 404 fail-open needed. The `43966` payload is the cowlib "HTTP Response Splitting via Non-VCHAR Bytes" advisory; neither response carries a top-level `"withdrawn"` key, so both classify as `{:active, id}`. This confirms `check_osv_advisory_staleness/0` runs against live OSV data and the staleness gate is real (not permanently fail-open). The fail-open path remains fully covered by the `osv_get/1` unresolvable-host test and the `classify_osv_response/2` parse-error test.

## Deviations from Plan

None. The plan was executed as written. The GREEN implementation completed by a prior executor was verified structurally and behaviorally (all helpers — `compile_root/1`, `fetch_compile_deps!/2`, `mix_env/1` — present and correctly referenced) before commit. `osv_get/1` additionally includes a `catch :exit` clause beyond the plan's `try/rescue` to cover `:httpc` exit signals — a strengthening consistent with the T-130-02 fail-open contract (all error paths return `{:error, _}`).

## Verification

- `mix test test/mailglass/publish/audit_allowlist_test.exs test/scripts/ci_parity_drift_test.exs --warnings-as-errors` → **16 tests, 0 failures**.
- `mix test test/scripts/required_checks_test.exs` (GATE-03) → **6 tests, 0 failures** — the new advisory lane is NOT in the required set.
- `mix deps.audit` → clean (`No vulnerabilities found.`, exit 0); dep resolves on Hex.
- CILanes registration atomic across all three files (verified by the green MIXCI-03 parity-drift test).

## Known Stubs

None.

## Self-Check: PASSED
- Commits `3adde80b`, `a7c86e42`, `01c5f63c`, `8d10afdf` all present in `git log`.
- Modified files present: mix.exs, .github/workflows/ci.yml, lib/mix/tasks/mailglass.publish.check.ex, test/support/ci_lanes.ex, test/scripts/ci_parity_drift_test.exs, test/mailglass/publish/audit_allowlist_test.exs.

## TDD Gate Compliance
RED gate `test(130-01)` commit `01c5f63c` precedes GREEN gate `feat(130-01)` commit `8d10afdf`. Both present in git log. No REFACTOR commit needed.
