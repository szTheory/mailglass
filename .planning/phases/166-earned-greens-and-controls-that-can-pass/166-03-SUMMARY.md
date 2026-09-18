---
phase: 166-earned-greens-and-controls-that-can-pass
plan: 03
subsystem: supply-chain-security
tags: [cowlib, hex-audit, accepted-advisories, faketime, ctrl-04, security-allowlist]

requires:
  - phase: 166-02
    provides: suite-floor enforcement on the required deterministic lane, so the plan lands on a truthfully-green baseline
provides:
  - Both cowlib advisory entries (`EEF-CVE-2026-43966`, `EEF-CVE-2026-43969`) rewritten with a
    permanent-refusal `:reason` (six closed upstream PR numbers, maintainer position + security-strategy
    URL, 2026-09-17 source verification against cowlib 2.20.0, OSV re-confirmation with no `fixed`
    event, no-upgrade-escape fact, Cowboy/Gun framework-layer mitigation, named falsifiable re-check)
  - `recheck_by: ~D[2027-03-17]` on both entries (D-30, 6-month extension, maintainer-confirmed)
  - Date-boundary test suite retargeted to the new boundary, landed in the same commit as the data edit
  - Defused the 2026-10-26 Hex Audit calendar time bomb (CTRL-04) truthfully — no upgrade exists, no
    date-override escape hatch was added
  - Explicit maintainer confirmation of the lib/ exemption (D-31), the substituted clock-proof evidence,
    and the new recheck date
affects: [166-04, 166-05, any future phase touching mix mailglass.audit or accepted_advisories.ex]

actuals:
  tokens: 14000
  tasks: 4
  commits: 1
  plan_head_before: 05d97b67f47327d01427bc26f0c2248242ebe8bd

tech-stack:
  added: []
  patterns:
    - "Lockstep commit for control expiry data + its boundary tests, to avoid a deterministic red window (D-33, third occurrence of the Phase 125 pin-drift shape)"
    - "Permanent-refusal advisory framing: cite closed upstream PRs, maintainer statement, direct source verification date, OSV re-confirmation, no-upgrade-escape fact, and framework-layer mitigation, plus a named falsifiable re-check — rather than a stale 'not yet fixed' framing"

key-files:
  created: []
  modified:
    - lib/mailglass/supply_chain/accepted_advisories.ex
    - test/mailglass/supply_chain/accepted_advisories_test.exs

key-decisions:
  - "Clock-fake mechanism: faketime does NOT intercept the BEAM clock on this toolchain (OTP 27, macOS/arm64) — worse than merely 'unverified,' faketime fails to fake even /bin/date here because macOS SIP strips DYLD_INSERT_LIBRARIES from protected binaries. The fallback branch was FORCED by the toolchain, not chosen for convenience."
  - "Maintainer ACCEPTED the fallback evidence (real un-faked `mix mailglass.audit --kind hex` run plus the committed date-boundary test) as satisfying CTRL-04's 'clock faked to 2026-12-01' acceptance clause. A literal system-clock fake was NOT achieved on this machine; this run is never described as a faked-clock run."
  - "Maintainer CONFIRMED the lib/ exemption: `lib/mailglass/supply_chain/accepted_advisories.ex` is the milestone's named exemption to D-31's 'no product code changes' constraint. Verified diff: 55 changed lines, all `:reason`/`:recheck_by` values plus the `@entries` header comment; no `def`, `defp`, guard, or default argument changed; `expired_entries/1` and `unused_entries/1` intact; the stale 'no upstream fix as of cowlib 2.19.0' string returns 0 hits in lib/."
  - "Maintainer CONFIRMED `recheck_by: ~D[2027-03-17]` (6-month extension per D-30) with the named falsifiable re-check: does a cowlib release above 2.20.0 validate input, or does OSV add a `fixed` event."

patterns-established:
  - "When a plan's designed verification mechanism (faketime) fails on the local toolchain for a structural reason (SIP), name the structural cause explicitly rather than reporting a bare negative — it changes how future re-attempts should be scoped (don't retry faketime on this machine; a Linux CI runner may behave differently)."

requirements-completed: [CTRL-04]

coverage:
  - id: D1
    description: "Both cowlib advisory entries rewritten with permanent-refusal `:reason` text and `recheck_by: ~D[2027-03-17]`, landed in the same commit as their boundary tests"
    requirement: "CTRL-04"
    verification:
      - kind: unit
        ref: "test/mailglass/supply_chain/accepted_advisories_test.exs — all boundary-date cases"
        status: pass
      - kind: other
        ref: "mix run -e IO.inspect(expired_entries/1) at ~D[2027-03-17] (empty) and ~D[2027-03-18] (both ids, declaration order)"
        status: pass
    human_judgment: false
  - id: D2
    description: "`mix mailglass.audit --kind hex` passes past the old 2026-10-26 expiry, by the mechanism Task 1 measured (fallback: real un-faked run), with zero unused allowlist entries"
    requirement: "CTRL-04"
    verification:
      - kind: unit
        ref: "mix mailglass.audit --kind hex (real, un-faked run — exit 0, no expired ids, no unused entries)"
        status: pass
      - kind: unit
        ref: "test/mailglass/supply_chain/ test/scripts/ full suite (495 tests, 0 failures, 27 excluded)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Maintainer explicitly confirmed the lib/ exemption, the substituted clock-proof evidence, and the new recheck date before the PR opens"
    human_judgment: true
    rationale: "This is a blocking-human checkpoint by design (D-31 scope-drift risk on a 'no product code changes' milestone, and a control-integrity decision on whether substituted evidence satisfies the acceptance clause) — not something automation can certify on its own."

duration: 4min
completed: 2026-09-17
status: complete
---

# Phase 166 Plan 03: Defuse the Cowlib Advisory Time Bomb (CTRL-04) Summary

**Rewrote both cowlib advisory entries from a stale "not yet fixed" framing to a permanent-refusal framing with a 6-month `recheck_by` extension, defusing the 2026-10-26 Hex Audit calendar time bomb truthfully — no upgrade exists and no date-override escape hatch was added.**

## Performance

- **Duration:** 4 min (Task 4 continuation only; Tasks 1-3 completed in a prior session)
- **Tasks:** 4/4
- **Files modified:** 2 (`accepted_advisories.ex`, `accepted_advisories_test.exs`)

## Accomplishments

- Measured (not assumed) that `faketime` does not intercept the BEAM clock on this toolchain, and identified the structural cause (macOS SIP stripping `DYLD_INSERT_LIBRARIES` from protected binaries) rather than leaving it an unexplained negative.
- Rewrote both `EEF-CVE-2026-43966` and `EEF-CVE-2026-43969` entries in `accepted_advisories.ex` with a permanent-refusal `:reason`: six closed upstream `ninenines/cowlib` PR numbers (154, 163, 164, 165, 166, 169), the maintainer's 2026-08-06 position on `ninenines/cowlib#167` with the security-strategy URL, a 2026-09-17 direct source verification against cowlib 2.20.0, the 2026-09-09 OSV re-confirmation with no `fixed` event, the no-upgrade-escape fact (cowlib 2.20.0 is newest; cowboy 2.19.0 requires it), and the Cowboy 2.16.0+/Gun 2.4.0+ framework-layer mitigation.
- Moved `recheck_by` on both entries to `~D[2027-03-17]` and retargeted every hardcoded boundary date in the test file in the same commit, avoiding the deterministic-red window that splitting the change would have produced (D-33).
- Demonstrated, by the fallback mechanism, that `mix mailglass.audit --kind hex` passes with zero expired entries and zero unused entries — proving the control still fires correctly at the new boundary without a literal system-clock fake.
- Obtained explicit maintainer sign-off on all three items gating the PR: the lib/ exemption, the substituted clock-proof evidence, and the new recheck date.

## Task Commits

1. **Task 1: Decide the clock-fake mechanism (faketime probe)** — no commit (probe-only; no tracked file modified). Verdict: FALLBACK forced.
2. **Task 2: Rewrite both advisory entries and their boundary tests in one atomic commit** — `ba2cb5b7` (feat)
3. **Task 3: Demonstrate the audit passes past the old expiry** — no commit (evidence-capture only). Real un-faked `mix mailglass.audit --kind hex` exit 0; `mix test test/mailglass/supply_chain/ test/scripts/` = 495 tests, 0 failures, 27 excluded.
4. **Task 4: Confirm the CTRL-04 lib/ exemption and clock-proof mechanism (checkpoint:human-verify)** — no code commit; maintainer confirmation recorded below.

**Plan metadata:** (this commit, docs)

## Files Created/Modified

- `lib/mailglass/supply_chain/accepted_advisories.ex` - Both cowlib entries' `:reason` and `:recheck_by` rewritten (data-only; no `def`/`defp`/guard/default-argument change)
- `test/mailglass/supply_chain/accepted_advisories_test.exs` - Boundary-date assertions retargeted to `~D[2027-03-17]` / `~D[2027-03-18]`

## Decisions Made

### 1. Clock-proof mechanism: fallback, forced by the toolchain — not chosen for convenience

Task 1's probe (`faketime '2026-12-01 00:00:00' elixir -e '...'`) did **not** print `2026-12-01`. This
plan's own executor investigated further and found the negative result is worse than "unverified": on
this machine (OTP 27, macOS/arm64), `faketime` fails to fake even `/bin/date`, because macOS System
Integrity Protection (SIP) strips `DYLD_INSERT_LIBRARIES` from protected system binaries before they
run. `faketime`'s interception mechanism is a dynamic-library preload; SIP defeats it at the OS level
before Erlang's clock reads ever enter the picture. This is recorded honestly: **a literal system-clock
fake was not achieved on this toolchain, and no step in this plan claims one occurred.**

The fallback substituted two pieces of real evidence instead:
- A real, un-faked `mix mailglass.audit --kind hex` run, proving the audit passes at today's actual
  date (2026-09-17) with neither cowlib id reported expired and zero unused entries.
- The committed date-boundary test (`test/mailglass/supply_chain/accepted_advisories_test.exs`),
  proving via `expired_entries/1` logic — not a faked wall clock — that the empty-list boundary holds
  exactly at `~D[2027-03-17]` and both ids flip to expired at `~D[2027-03-18]`.

**Maintainer decision (Task 4, item 2): ACCEPTED.** The maintainer confirmed this fallback evidence
satisfies CTRL-04's "clock faked to 2026-12-01" acceptance clause in substance, while explicitly
requiring — and receiving — the honest record that the literal clock fake did not happen and why.

### 2. lib/ exemption: CONFIRMED, PR description to state it explicitly

D-31 recorded `accepted_advisories.ex` as the milestone's sole named exemption to "no product code
changes," because CTRL-04 cannot be satisfied without editing it. The orchestrator independently
verified the `ba2cb5b7` diff before presenting it: 55 changed lines total (53 insertions, 27
deletions across both files), confined in `accepted_advisories.ex` to the two entry maps' `:reason` /
`:recheck_by` values plus the `@entries` header comment — no `def`, `defp`, guard, or default
argument changed. `expired_entries/1` and `unused_entries/1` are byte-for-byte intact. The stale
"no upstream fix as of cowlib 2.19.0" string returns 0 hits anywhere in `lib/` (`grep -c` confirmed).

**Maintainer decision (Task 4, item 1): CONFIRMED.** The maintainer confirmed this reads as a
data-only edit and directed that the PR description name the exemption explicitly, so a reviewer does
not read the `lib/` diff as scope drift.

### 3. `recheck_by: ~D[2027-03-17]` — CONFIRMED as the standing decision

Per D-30 (a 6-month extension from the original 2026-10-26/2027-03-17-style window), both entries now
carry the same `recheck_by` date, with the named falsifiable re-check for the next cycle: does a
cowlib release above 2.20.0 add input validation, or does OSV add a `fixed` event to either advisory.

**Maintainer decision (Task 4, item 3): CONFIRMED.** The date and the falsifiable re-check stand as
the decision to act on.

## Deviations from Plan

None beyond the mechanism-selection branch the plan itself designed for. The plan explicitly planned
for both the faketime-works and faketime-fails outcomes (Task 1); the fallback branch taken here is a
foreseen path, not an unplanned deviation. The additional diagnosis (SIP stripping
`DYLD_INSERT_LIBRARIES`) goes beyond what Task 1 required to record, but strengthens the honesty of
the negative result and is documented for any future attempt on a different (e.g. Linux CI) runner.

## Issues Encountered

None beyond the above. The `checkpoint:human-verify` gate at Task 4 worked exactly as designed:
execution halted cleanly after Task 3, and this continuation records the maintainer's three explicit
answers rather than assuming any of them.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- CTRL-04 is closed: both cowlib advisory entries are truthfully justified past the old 2026-10-26
  expiry, with a real re-verification date of 2027-03-17 and no maintainer-settable bypass (D-32 held).
- `mix mailglass.audit --kind hex` and the full `accepted_advisories`/`scripts` test lane are proven
  green on the current commit.
- The Post-Merge Verification row in the plan (re-run the selected clock-proof command on `main` after
  merge, and record it as the second un-faked half of the evidence, not a faked run) is owed to
  `166-VALIDATION.md` and is NOT satisfied by this SUMMARY alone — it requires a post-merge action.
- Ready to proceed to the next plan in Phase 166's wave sequence.

---
*Phase: 166-earned-greens-and-controls-that-can-pass*
*Completed: 2026-09-17*
