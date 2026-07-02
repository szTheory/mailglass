---
phase: 130-supply-chain-workflow-hygiene
plan: 02
subsystem: infra
tags: [ci, dependabot, dependency-review, github-actions, advisory-matrix, supply-chain, elixir, otp]

# Dependency graph
requires:
  - phase: 130-supply-chain-workflow-hygiene (Plan 01)
    provides: mix_audit deps.audit publish gate + OSV staleness gate (this plan runs after, touching only YAML + one mix.exs comment)
provides:
  - Dependabot coverage for the two active sibling packages (mailglass_admin, mailglass_inbound)
  - Advisory dependency-review-action step in actionlint.yml (PR-only, non-blocking, HIGH+ severity)
  - core_latest_elixir_advisory job (Elixir 1.19 / OTP 28) — push+cron only, never PR/required
  - LD-13 floor-coincidence invariant documented in advisory-matrix.yml and mix.exs
affects: [release-pipeline, supply-chain, ci-lanes, future-elixir-otp-floor-bumps]

# Tech tracking
tech-stack:
  added: ["actions/dependency-review-action@v5.0.0 (SHA-pinned)"]
  patterns:
    - "Advisory-on-PR (LD-4): continue-on-error + PR-only guard, never blocks a PR"
    - "Job-level if: github.event_name != 'pull_request' — only mechanism to exclude a matrix row from PR events"
    - "Toolchain-parameterized cache key (matrix.elixir-matrix.otp) prevents cross-toolchain artifact bleed"
    - "advisory-matrix.yml is EXEMPT from the Phase 129 version-file/.tool-versions cache contract (it tests specific named toolchains)"

key-files:
  created: []
  modified:
    - .github/dependabot.yml
    - .github/workflows/actionlint.yml
    - .github/workflows/advisory-matrix.yml
    - mix.exs

key-decisions:
  - "Sibling dependabot entries added for /mailglass_admin and /mailglass_inbound only; reference/host_app and reference/demo_app deliberately excluded (frozen baselines, reference-baseline-coupling)."
  - "dependency-review step uses fail-on-severity: high + continue-on-error + PR-only if guard; no pull-requests: write permission (scan-only mode, contents: read sufficient)."
  - "1.19/OTP28 row lives in a NEW job (core_latest_elixir_advisory), not a matrix row on the existing job, so the job-level PR-exclusion if: can apply (GitHub Actions has no per-matrix-row if)."
  - "New advisory job name 'Core Full Suite Advisory (Elixir 1.19 / OTP 28)' contains 'Advisory (' so publish-hex.yml isAdvisory() classifies it non-blocking."
  - "No provider_compatibility 1.19 row added — only the core advisory row is in scope for SUPPLY-05 (provider tests need live sandbox creds; OTP28 compat out of scope)."

patterns-established:
  - "Pattern: latest-Elixir advisory coverage is a separate job with a job-level PR-exclusion if:, toolchain-scoped cache key, and an LD-13 invariant comment tying tested version back to the declared mix.exs floor."

requirements-completed: [SUPPLY-02, SUPPLY-04, SUPPLY-05]

coverage:
  - id: D1
    description: "Dependabot watches /mailglass_admin and /mailglass_inbound mix.lock weekly; frozen reference/ baselines excluded"
    requirement: "SUPPLY-02"
    verification:
      - kind: other
        ref: "grep -c 'directory:' .github/dependabot.yml == 4 AND grep mailglass_admin/mailglass_inbound present AND no 'reference' string"
        status: pass
    human_judgment: false
  - id: D2
    description: "Advisory dependency-review-action step in actionlint.yml (SHA-pinned v5.0.0, continue-on-error, PR-only, fail-on-severity: high)"
    requirement: "SUPPLY-04"
    verification:
      - kind: other
        ref: "grep dependency-review-action@a1d282b + continue-on-error: true + github.event_name == 'pull_request' + fail-on-severity: high in .github/workflows/actionlint.yml; actionlint clean"
        status: pass
    human_judgment: false
  - id: D3
    description: "core_latest_elixir_advisory job (Elixir 1.19/OTP28, job-level PR-exclusion if:, toolchain-scoped cache key, LD-13 invariant in workflow + mix.exs)"
    requirement: "SUPPLY-05"
    verification:
      - kind: other
        ref: "grep core_latest_elixir_advisory + \"github.event_name != 'pull_request'\" + '1.19' + '28' + 'LD-13' in advisory-matrix.yml; grep 'LD-13' mix.exs; actionlint clean"
        status: pass
    human_judgment: false
  - id: D4
    description: "OPEN QUESTION A2 — does setup-beam v1.24.0 resolve '1.19' + '28' on ubuntu-latest? Unresolvable at authoring time (requires a live CI run)."
    verification: []
    human_judgment: true
    rationale: "Toolchain availability on ubuntu-latest can only be confirmed by a real push/cron run of the new job; the row is advisory (a setup failure is red-advisory, never a blocked PR/publish), so this does not gate the plan."

# Metrics
duration: 9min
completed: 2026-07-02
status: complete
---

# Phase 130 Plan 02: Supply-Chain Perimeter (YAML/Config Guards) Summary

**Dependabot sibling coverage, an advisory PR-only dependency-review step, and a 1.19/OTP28 latest-Elixir advisory job — pure YAML/config plus one mix.exs LD-13 comment, zero product code.**

## Performance

- **Duration:** ~9 min
- **Completed:** 2026-07-02
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments
- Dependabot now watches the two active sibling packages (`/mailglass_admin`, `/mailglass_inbound`) on a weekly schedule; the frozen `reference/` baselines remain unwatched (avoiding the coordinated 5-file-change trap).
- `actionlint.yml` gained an advisory `dependency-review-action@v5.0.0` (SHA-pinned) step that scans PR dependency changes for HIGH+ vulnerabilities without ever blocking a PR (`continue-on-error: true`, PR-only guard).
- `advisory-matrix.yml` gained a `core_latest_elixir_advisory` job for Elixir 1.19 / OTP 28 that runs on push+cron+dispatch only (never on PR, never required), named to match `isAdvisory()` in `publish-hex.yml`, with a toolchain-scoped cache key.
- The LD-13 floor-coincidence invariant is documented both in the new job header and next to the `elixir: "~> 1.18"` floor in `mix.exs`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add dependabot sibling entries** - `d3693d67` (ci)
2. **Task 2: Add dependency-review advisory step to actionlint.yml** - `41d904f6` (ci)
3. **Task 3: Add 1.19/OTP28 advisory matrix row + LD-13 invariant** - `85a4b276` (ci)

## Files Created/Modified
- `.github/dependabot.yml` - Two new `mix` ecosystem entries (`/mailglass_admin`, `/mailglass_inbound`); now 4 `directory:` lines total.
- `.github/workflows/actionlint.yml` - New `Dependency review` step (SHA-pinned v5.0.0, `continue-on-error: true`, `if: github.event_name == 'pull_request'`, `fail-on-severity: high`).
- `.github/workflows/advisory-matrix.yml` - New `core_latest_elixir_advisory` job (job-level `if: github.event_name != 'pull_request'`, matrix Elixir 1.19 / OTP 28, toolchain-parameterized cache key, LD-13 comment block).
- `mix.exs` - LD-13 invariant comment above the `elixir: "~> 1.18"` floor declaration.

## Decisions Made
- **reference/ excluded from dependabot** — frozen deterministic baselines; adding them would trip the reference-baseline-coupling 5-file-change trap.
- **New job, not a matrix row, for 1.19/OTP28** — job-level `if:` is the only mechanism GitHub Actions provides to exclude a toolchain from PR events (no per-matrix-row `if`).
- **No provider_compatibility 1.19 row** — provider tests need live sandbox credentials; OTP28 provider compat is out of scope for SUPPLY-05. Core advisory only.
- **advisory-matrix.yml exempt from the Phase 129 version-file cache contract** — its purpose is to test specific named toolchains, so the matrix drives `elixir-version`/`otp-version` directly and the cache key is toolchain-parameterized (not `.tool-versions`-hashed).
- **contents: read is sufficient** — dependency-review runs in scan-only mode (no PR comment posting), so no `pull-requests: write` permission was added.

## Deviations from Plan

None - plan executed exactly as written. The `mix.exs` change was scoped to the single LD-13 comment; Plan 01's `mix_audit` additions were left untouched (verified via `git diff --stat`: mix.exs +4 lines only).

## Issues Encountered
None. `actionlint` was available locally and reported clean on both modified workflow files (`advisory-matrix.yml`, `actionlint.yml`). All three grep-based verify blocks passed.

## Open Questions

### OPEN QUESTION A2 (research) — setup-beam resolving Elixir 1.19 / OTP 28

The new `core_latest_elixir_advisory` job passes bare `elixir-version: "1.19"` / `otp-version: "28"` to `erlef/setup-beam@fc68ffb...` (v1.24.0). Whether v1.24.0 can resolve those exact version strings on `ubuntu-latest` cannot be confirmed at authoring time — it requires a live push/cron run.

**Resolution/assumption (documented per plan requirement):**
- If setup-beam **can** resolve `"1.19"` + `"28"`, the row runs the full advisory suite and gives early warning of latest-line breakage.
- If setup-beam **cannot** resolve them, the row fails at the setup step. This is **advisory-acceptable**: the job carries a job-level `if: github.event_name != 'pull_request'`, is never required, and its name matches `isAdvisory()` — so a red setup is a red advisory, never a blocked PR or blocked publish.
- No action is needed unless/until a maintainer wants the row green. Likely remedies then: use a more specific version string (e.g. an exact patch like `"1.19.0"` / `"28.0"`), or wait for setup-beam's build index to include the release. This is intentionally left as a live-CI observation rather than a speculative pre-tuning.

## Next Phase Readiness
- Supply-chain perimeter is complete across Plan 01 (deps.audit + OSV staleness gates) and Plan 02 (dependabot sibling coverage + dependency-review + latest-Elixir advisory).
- No product code changed (D-23 infra-only). No Hex release implied by this plan.
- First push of the phase branch will confirm OPEN QUESTION A2 empirically: verify `core_latest_elixir_advisory` appears in the push/cron run list but NOT in a PR's required-checks context.

## Self-Check: PASSED

All 4 modified files present on disk; all 3 task commits (`d3693d67`, `41d904f6`, `85a4b276`) exist in git history.

---
*Phase: 130-supply-chain-workflow-hygiene*
*Completed: 2026-07-02*
