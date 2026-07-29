---
phase: 142-supply-chain-remediation-gating
plan: 01
subsystem: infra
tags: [supply-chain, hex-audit, deps-audit, ci, credo, boundary, mix-task]

# Dependency graph
requires:
  - phase: 141-lane-truth-foundation
    provides: Mailglass.CILanes single-source lane classification (required/advisory/publish-gating/structural) that ci_parity_drift_test.exs and this plan's matcher edits build on
provides:
  - Mailglass.SupplyChain.AcceptedAdvisories — the single accepted-advisory allowlist (id/aliases/package/severity/reason/accepted_on/recheck_by), alias-aware matching, expired_entries/1 + unused_entries/1 staleness checks
  - mix mailglass.audit --kind hex|deps (dev/ Mix task) scanning root + mailglass_admin + mailglass_inbound
  - ci.yml's hex_audit and deps_audit_advisory jobs both rewired to call the shared task
  - mailglass.publish.check.ex thin-delegated to the shared module (single source of truth, no second allowlist copy)
affects: [142-02-vuln-triage, 142-03-vuln-checkpoint, 142-04-gate-promotion]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Thin-delegation preserves an existing @doc false public test surface when extracting shared logic to a new module"
    - "Boundary classify_to: is valid ONLY for Mix tasks and protocol implementations — a plain lib/ module already inside its naming-convention boundary must NOT declare it"
    - "Per-directory subprocess invocation: mix hex.audit needs cd: (no --path flag); mix deps.audit has --path and runs from root"

key-files:
  created:
    - lib/mailglass/supply_chain/accepted_advisories.ex
    - dev/mix/tasks/mailglass.audit.ex
    - test/mailglass/supply_chain/accepted_advisories_test.exs
    - test/mix/tasks/mailglass.audit_test.exs
  modified:
    - lib/mix/tasks/mailglass.publish.check.ex
    - test/mailglass/publish/audit_allowlist_test.exs
    - .github/workflows/ci.yml
    - mix.exs
    - test/scripts/ci_parity_drift_test.exs
    - .planning/todos/completed/2026-06-30-remove-cowlib-advisory-allowlist-when-upstream-fixes.md

key-decisions:
  - "Dropped `use Boundary, classify_to: Mailglass` from the new lib/ module — classify_to is reserved for Mix tasks/protocol implementations per the Boundary library; a module already inside the Mailglass.* naming convention cannot be manually reclassified (compile error under --warnings-as-errors)."
  - "Both `--kind hex` and `--kind deps` were implemented fully in Task 1 (not staged as a stub) since the deps.audit logic was a direct reuse of the existing parser; Task 2 wired it into ci.yml/mix.exs rather than writing new logic."
  - "D-10's expired_entries/1 and unused_entries/1 run ONLY inside --kind hex evaluation (Decision 2, locked in the plan) — --kind deps applies alias-aware suppression only."

patterns-established:
  - "Pattern 1: thin-delegation — mailglass.publish.check.ex's unaccepted_audit_findings/1 and unaccepted_deps_audit_findings/1 now one-line delegate to Mailglass.SupplyChain.AcceptedAdvisories, preserving their exact @doc false 1-arity signature so existing test call sites needed zero edits."

requirements-completed: [VULN-05, VULN-06]

coverage:
  - id: D1
    description: "mix mailglass.audit --kind hex scans root + mailglass_admin + mailglass_inbound, applies the shared allowlist, and exits 0 today with both live mailglass_admin cowlib advisories (EEF-CVE-2026-43966, EEF-CVE-2026-43969) named as accepted, not silently absent"
    requirement: "VULN-05"
    verification:
      - kind: unit
        ref: "test/mailglass/supply_chain/accepted_advisories_test.exs — describe \"unaccepted_audit_findings/1\""
        status: pass
      - kind: integration
        ref: "mix mailglass.audit --kind hex (live run against repo root)"
        status: pass
    human_judgment: false
  - id: D2
    description: "mix mailglass.audit --kind deps scans the same three directories via mix deps.audit/--path, applies the same alias-aware allowlist, and exits 0 today"
    requirement: "VULN-05"
    verification:
      - kind: unit
        ref: "test/mailglass/supply_chain/accepted_advisories_test.exs — describe \"unaccepted_deps_audit_findings/1\""
        status: pass
      - kind: integration
        ref: "mix mailglass.audit --kind deps (live run against repo root)"
        status: pass
    human_judgment: false
  - id: D3
    description: "A deps.audit-shaped finding whose advisory id is the real alias GHSA-g2wm-735q-3f56 (not the primary EEF-CVE-2026-43969 id) is suppressed — F2's previously-untested positive case"
    requirement: "VULN-05"
    verification:
      - kind: unit
        ref: "test/mailglass/supply_chain/accepted_advisories_test.exs#\"suppresses a deps.audit finding whose GHSA id is a registered alias (F2)\""
        status: pass
    human_judgment: false
  - id: D4
    description: "expired_entries/1 uses strictly-after semantics: an entry due today does not block, one due yesterday does"
    requirement: "VULN-06"
    verification:
      - kind: unit
        ref: "test/mailglass/supply_chain/accepted_advisories_test.exs — describe \"expired_entries/1\""
        status: pass
    human_judgment: false
  - id: D5
    description: "unused_entries/1 reports entries in entries/0's declared list order (deterministic, not shuffled) when more than one is simultaneously unused/expired"
    requirement: "VULN-06"
    verification:
      - kind: unit
        ref: "test/mailglass/supply_chain/accepted_advisories_test.exs#\"with an empty matched_ids set, both entries are reported unused, in entries/0's declared order\""
        status: pass
    human_judgment: false
  - id: D6
    description: "mailglass.publish.check.ex reads the shared module exclusively; no second copy of the allowlist exists; F2's two stale comments are corrected; the folded todo is closed with an honest resolution"
    verification:
      - kind: unit
        ref: "test/mailglass/publish/audit_allowlist_test.exs (all tests, unchanged count)"
        status: pass
      - kind: other
        ref: "grep -c \"@accepted_advisories\" lib/mix/tasks/mailglass.publish.check.ex == 0; grep -c \"never auto-suppressed today\" (both files) == 0"
        status: pass
    human_judgment: false

duration: 16min
completed: 2026-07-29
status: complete
---

# Phase 142 Plan 01: Wire the Shared Advisory Allowlist into CI-Side Audit Lanes Summary

**`Mailglass.SupplyChain.AcceptedAdvisories` is now the ONE source both `mix mailglass.publish.check` and `mix mailglass.audit --kind hex|deps` (new, CI-wired) read, with alias-aware suppression and D-10's expired/unused staleness checks — `hex_audit` and `deps_audit_advisory` in `ci.yml` both call the new task instead of bare `mix hex.audit`/`mix deps.audit`.**

## Performance

- **Duration:** ~16 min
- **Started:** 2026-07-29T01:41:30Z
- **Completed:** 2026-07-29T01:56:00Z
- **Tasks:** 3
- **Files modified:** 11 (4 created, 7 modified) + 1 todo moved/edited

## Accomplishments

- Extracted `Mailglass.SupplyChain.AcceptedAdvisories` (`lib/`) as the single accepted-advisory allowlist source of truth: `:id`/`:aliases`/`:package`/`:severity`/`:reason`/`:accepted_on`/`:recheck_by` records, exact `:id`-or-`:aliases`-member matching (never fuzzy/prefix/cross-package), `expired_entries/1` (strictly-after `recheck_by` semantics) and `unused_entries/1` (matched-finding staleness, scoped to `--kind hex` only per Decision 2).
- Built `mix mailglass.audit --kind hex|deps` (`dev/mix/tasks/mailglass.audit.ex`), scanning root + `mailglass_admin` + `mailglass_inbound` per the fixed `@scan_dirs` literal, evaluating findings through the shared allowlist, and printing which findings were accepted (not silent) on success.
- Rewired both `ci.yml` audit jobs (`hex_audit`, `deps_audit_advisory`) to call `mix mailglass.audit --kind <hex|deps>` instead of bare `mix hex.audit`/`mix deps.audit`; `deps_audit_advisory` keeps `continue-on-error: true` untouched (Plan 04 scope).
- Widened `mix.exs`'s `:ci` alias (F1) so `mix ci` reproduces the same shared-allowlist, three-directory scan both CI lanes now run, and updated `ci_parity_drift_test.exs`'s two matcher predicates to match.
- Thin-delegated `mailglass.publish.check.ex`'s `unaccepted_audit_findings/1` / `unaccepted_deps_audit_findings/1` to the shared module (Pattern 1), deleting `@accepted_advisories` entirely — one allowlist, not two.
- Fixed F2's two stale "GHSA never auto-suppressed" claims (in `publish.check.ex` and `audit_allowlist_test.exs`) to describe the now-correct alias-aware behavior.
- Closed `.planning/todos/completed/2026-06-30-remove-cowlib-advisory-allowlist-when-upstream-fixes.md` with an honest `## Resolution`: cowlib has NOT shipped a fix (both advisories still live in `mailglass_admin` as of 2026-07-29), but the todo's underlying need — a human remembering to revisit the allowlist — is now automated by `expired_entries/1`/`unused_entries/1`.

## Task Commits

1. **Task 1: End-to-end "shared allowlist blocks a real cowlib finding" — hex.audit path only** - `3875bfe8` (feat)
2. **Task 2: Expand to `--kind deps`, wire `deps_audit_advisory`, widen `mix.exs`'s `:ci` alias (F1)** - `b0e88564` (feat)
3. **Task 3: Thin-delegate `mailglass.publish.check.ex`, fix F2's stale comments, close the folded todo** - `5dc25556` (feat)

_All three tasks were `tdd="true"`; tests were authored alongside the implementation in the same commit per task (no separate RED/GREEN commits — this plan's granularity treats each numbered task as one atomic unit, consistent with prior phase conventions in this repo)._

## Evidence: live `mix mailglass.audit --kind hex` output

Reproduced against the live repo at HEAD (`5dc25556`), the run Plan 03's checkpoint gate will ask to see reproduced on a real PR:

```
$ mix mailglass.audit --kind hex
Accepted (mailglass_admin): EEF-CVE-2026-43966 is an accepted-allowlist finding.
Accepted (mailglass_admin): EEF-CVE-2026-43969 is an accepted-allowlist finding.
mix mailglass.audit --kind hex: all findings accepted.
$ echo $?
0
```

`mix mailglass.audit --kind deps` also exits 0 (`mix mailglass.audit --kind deps: all findings accepted.`) — `mix deps.audit` is clean for cowlib 2.19.0 in every directory today (mirego's DB range excludes it, per F4), so this run reflects a genuinely clean scan rather than allowlist suppression.

## Files Created/Modified

- `lib/mailglass/supply_chain/accepted_advisories.ex` - the shared allowlist module: `entries/0`, `unaccepted_audit_findings/1`, `unaccepted_deps_audit_findings/1`, `matched_hex_audit_ids/1`, `expired_entries/1`, `unused_entries/1`
- `dev/mix/tasks/mailglass.audit.ex` - `mix mailglass.audit --kind hex|deps`, `run_check/1`, `evaluate/2` (pure, unit-tested)
- `test/mailglass/supply_chain/accepted_advisories_test.exs` - 19 tests covering suppression, negative controls, F2's alias-aware positive case, expiry/unused ordering + empty-set edges
- `test/mix/tasks/mailglass.audit_test.exs` - 7 tests covering `evaluate/2`'s aggregation/exit-decision for both kinds, including the D-10 unused-entries block on a fully-clean hex scan
- `lib/mix/tasks/mailglass.publish.check.ex` - `@accepted_advisories` deleted; thin-delegated to the shared module; F2's stale comment corrected; `check_osv_advisory_staleness/0` repointed
- `test/mailglass/publish/audit_allowlist_test.exs` - F2's stale comment/test docstring corrected; all 12 existing tests unchanged and still passing
- `.github/workflows/ci.yml` - `hex_audit` and `deps_audit_advisory`'s final steps now call `mix mailglass.audit --kind <hex|deps>`
- `mix.exs` - `:ci` alias widened from bare `hex.audit`/`deps.audit` to `mailglass.audit --kind hex`/`--kind deps`
- `test/scripts/ci_parity_drift_test.exs` - two matcher predicates updated to the new step substrings
- `.planning/todos/completed/2026-06-30-remove-cowlib-advisory-allowlist-when-upstream-fixes.md` - moved from pending, `## Resolution` section prepended

## Decisions Made

- Dropped `use Boundary, classify_to: Mailglass` from the new `lib/` module (see Deviations below) — kept correctly on the `dev/` Mix task, where `classify_to:` is the right tool.
- Implemented `--kind deps`'s real logic in Task 1 rather than a stub, since it was a direct reuse of the existing parser; Task 2's job was purely the CI/alias wiring, not new evaluation logic.
- Used fully-qualified `Mailglass.SupplyChain.AcceptedAdvisories.*` call sites in `publish.check.ex` (no `alias`) so the module boundary is unambiguous at every call site and satisfies the plan's literal grep-count acceptance criteria.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Dropped `use Boundary, classify_to: Mailglass` from the new `lib/` module**
- **Found during:** Task 1, running the plan-mandated `mix compile --warnings-as-errors` confirmation step
- **Issue:** The plan's RESEARCH F5 / pattern map instructed copying `use Boundary, classify_to: Mailglass` onto the new `lib/mailglass/supply_chain/accepted_advisories.ex` module by analogy with `Mix.Tasks.Mailglass.Publish.Check`. But the Boundary library's `classify_to:` option is valid ONLY for Mix tasks and protocol implementations (whose module names live outside their owning namespace); a plain module already named `Mailglass.SupplyChain.AcceptedAdvisories` is automatically part of the `Mailglass` boundary by naming convention and cannot be manually "reclassified" — applying the declaration raised `"only mix task and protocol implementation can be reclassified"` under `mix compile --warnings-as-errors --force`, a hard failure (exit 1), not a warning.
- **Fix:** Removed the `use Boundary` line from the `lib/` module; kept it (correctly) on `dev/mix/tasks/mailglass.audit.ex`, which IS a Mix task. Added a comment explaining why no `use Boundary` is needed.
- **Files modified:** `lib/mailglass/supply_chain/accepted_advisories.ex`
- **Verification:** `MIX_ENV=test mix compile --warnings-as-errors --force` exits 0.
- **Committed in:** `3875bfe8` (Task 1 commit)
- **Note:** This means the plan's literal acceptance-criteria grep (`grep -c "use Boundary, classify_to: Mailglass" lib/.../accepted_advisories.ex dev/.../mailglass.audit.ex` returning `2`) now returns `1` (only the `dev/` file). The stronger, correctness-defining verify command (`mix compile --warnings-as-errors`, listed first in the plan's own acceptance criteria) passes; the grep-count criterion was based on a false premise the plan itself flagged as needing confirmation ("confirm early with `mix compile --warnings-as-errors` per RESEARCH F5, do not assume") and confirmation showed the assumption wrong for this file.

**2. [Rule 1 - Bug] Removed `D-10`/`Phase 142`/`T-142-06` planning-artifact tokens from the new module's docstrings/comments**
- **Found during:** Task 3, running `mix credo --strict` as part of pre-commit verification
- **Issue:** `Mailglass.Credo.NoPlanningArtifactComments` (an existing custom check, enforced repo-wide under `lib/mailglass/`) flags `D-\d+`, `Phase \d+`, and similarly-shaped planning-provenance tokens in docstrings/comments, per CLAUDE.md's "Custom Credo checks at lint time" convention. The new module's moduledoc referenced `Phase 142/VULN-05`, `D-10`, and `T-142-06`.
- **Fix:** Reworded the affected lines to behavior-focused rationale with no planning-artifact tokens, keeping the technical meaning intact.
- **Files modified:** `lib/mailglass/supply_chain/accepted_advisories.ex`
- **Verification:** `mix credo --strict` on the touched files reports "found no issues"; `mix ci.fast` (485 files) also clean.
- **Committed in:** `5dc25556` (Task 3 commit)

**3. [Rule 1 - Bug] Ran `mix format` across all Phase 142-01 files**
- **Found during:** Task 3, running `mix format --check-formatted` as part of pre-commit verification
- **Issue:** Several lines exceeded the formatter's line-length/nesting preferences (long pipe chains, multi-line map literals) from the initial hand-written code.
- **Fix:** `mix format` on the touched files.
- **Files modified:** `lib/mix/tasks/mailglass.publish.check.ex`, `dev/mix/tasks/mailglass.audit.ex`, `test/scripts/ci_parity_drift_test.exs` (whitespace/wrapping only, no logic change)
- **Verification:** `mix format --check-formatted` passes on all touched files.
- **Committed in:** `5dc25556` (Task 3 commit)

---

**Total deviations:** 3 auto-fixed (all Rule 1 — bugs that would otherwise fail the plan's own required verify commands)
**Impact on plan:** All three fixes were required for the plan's own stated verification gates (`mix compile --warnings-as-errors`, `mix credo --strict`/`mix ci.fast`, `mix format --check-formatted`) to pass. No scope creep — no new files, no behavior change beyond what Tasks 1-3 specified. One plan acceptance-criteria grep (Boundary-declaration count) is now literally `1` instead of `2`, documented above with the stronger substitute verification that passed instead.

## Issues Encountered

None beyond the three deviations above — no blockers, no auth gates, no checkpoints (this plan is `autonomous: true` with no `checkpoint:*` tasks).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The mechanism ROADMAP criterion 1 requires ("`hex_audit` honors the shared allowlist with cowlib genuinely in scope, not vacuously") is now real and proven end-to-end against the live repo.
- VULN-06's expiry/staleness mechanism exists, is local/deterministic, and is unit-tested (19 + 7 = 26 new tests, all green).
- `mailglass.publish.check.ex`'s allowlist has exactly one source of truth — `grep -c "@accepted_advisories" lib/mix/tasks/mailglass.publish.check.ex` is `0`.
- The folded todo is closed with an honest, non-silent resolution (cowlib still unfixed; automation supersedes the manual watch).
- `deps_audit_advisory` still keeps `continue-on-error: true` — no gating change landed in this plan (D-13 Wave 1 constraint honored), leaving Plan 02/04's promotion work fully unblocked.
- Precondition for Plan 02 (VULN-02 triage) and Plan 04 (VULN-03 gate promotion): the shared allowlist is now the thing both CI lanes AND the publish gate read, so promoting `hex_audit`/`deps_audit_advisory` to merge-gating will not immediately red-block every PR on the two already-accepted cowlib advisories.

---
*Phase: 142-supply-chain-remediation-gating*
*Completed: 2026-07-29*
