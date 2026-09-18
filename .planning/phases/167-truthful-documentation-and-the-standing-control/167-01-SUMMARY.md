---
phase: 167-truthful-documentation-and-the-standing-control
plan: 01
subsystem: docs
tags: [release-please, hex-publish, docs-contract-test, exunit, drift-guard]

requires:
  - phase: 166
    provides: false-green fixes (GREEN-01..05, CTRL-01..05) that this phase's docs corrections assume are true
provides:
  - "MAINTAINING.md's exclude-paths count derived from release-please-config.json at test time (never a second hardcoded literal)"
  - "MAINTAINING.md's publish fan-out and override wording corrected to name the real required_reviewers gate and workflow_dispatch-only override mechanism"
  - "CONTRIBUTING.md's sibling pin guidance corrected to describe the current bare `~> 2.0` constraint, retiring the stale fix(inbound): floor-bump instruction"
  - "MAINTAINING.md ## Release Close-Out runbook (five ledger states, 4-step procedure, script paths pinned with File.exists?/1)"
  - "3 new describe blocks + 4 new tests + 1 new private helper in test/mailglass/docs_contract_test.exs"
affects: [167-02, 167-03, 167-04, release ceremony docs, docs_contract_test.exs future extensions]

actuals:
  tokens: 2930
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Derived-from-source assertion for a prose count (Jason.decode! the config, read the array length, map to English word via a literal 1..30 table, never assert the word as a second hardcoded literal)"
    - "Negative-first refute + positive backstop pairing for one-off stale-phrase prose corrections, scoped narrowly enough not to false-positive on a legitimate unrelated occurrence of the same substring"
    - "Positive-only section-presence + referential-integrity assertion (Regex.scan for scripts/*.sh|.exs references, File.exists?/1 per match) for an added section with no stale string to refute"

key-files:
  created: []
  modified:
    - MAINTAINING.md
    - CONTRIBUTING.md
    - test/mailglass/docs_contract_test.exs

key-decisions:
  - "Reworded the fan-out override sentence to name the actual GitHub Actions mechanism (the skip_core_full_suite_gate input is only read on a workflow_dispatch event) rather than reusing the plan's suggested 'release event is inert for the override' phrasing verbatim, since the more precise sentence is both true and avoids implying the release event evaluates the input at all."
  - "Placed the new ## Release Close-Out section immediately after the '## Current protected release and recovery path' section (the live authoritative procedure) rather than after the historical 'Monitor the hands-free publish fan-out' step 3, which lives inside '## Historical release procedures' (explicitly marked non-authoritative, provenance-only) — close-out is the step that must follow the CURRENT protected path's step 6 (post-publish validation), not a historical numbered list that continues on to steps 4-5."
  - "Reworded CONTRIBUTING.md's major-bump sentence to avoid the phrase 'requires a deliberate' entirely (not just the fix(inbound): pairing) after the first draft's accurate 'major requires a deliberate...bump' sentence tripped its own new refute test — the test's job is to make sure a *specific defective claim* can't return, and rewording around it rather than narrowing the refute kept the guard maximally strict."

requirements-completed: [DOCS-03]

coverage:
  - id: D1
    description: "MAINTAINING.md's exclude-paths count is generated from release-please-config.json at test time, not proofread"
    requirement: DOCS-03
    verification:
      - kind: unit
        ref: "test/mailglass/docs_contract_test.exs#MAINTAINING.md contract exclude-paths count in prose is derived from release-please-config.json"
        status: pass
    human_judgment: false
  - id: D2
    description: "MAINTAINING.md no longer claims the publish fan-out is hands-free; corrected text names required_reviewers and three approval stops"
    requirement: DOCS-03
    verification:
      - kind: unit
        ref: "test/mailglass/docs_contract_test.exs#MAINTAINING.md contract publish fan-out is described as gated, not hands-free"
        status: pass
    human_judgment: false
  - id: D3
    description: "CONTRIBUTING.md no longer instructs a mandatory fix(inbound): floor-bump commit on a core minor; describes the current bare ~> 2.0 sibling constraint; the unrelated fix(inbound): example at line 161 survives"
    requirement: DOCS-03
    verification:
      - kind: unit
        ref: "test/mailglass/docs_contract_test.exs#CONTRIBUTING.md contract sibling pin guidance describes the bare ~> constraint, not a floor bump"
        status: pass
    human_judgment: false
  - id: D4
    description: "MAINTAINING.md ## Release Close-Out section exists, names the five ledger states and both close-out script paths, and every scripts/*.sh|.exs path it names is proven to exist on disk"
    requirement: DOCS-03
    verification:
      - kind: unit
        ref: "test/mailglass/docs_contract_test.exs#MAINTAINING.md contract close-out runbook names the ledger states and every script it tells the reader to run"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-09-18
status: complete
---

# Phase 167 Plan 01: Truthful Release Documentation Summary

**Corrected three false release-mechanics claims in MAINTAINING.md/CONTRIBUTING.md (stale exclude-paths count, "hands-free" publish fan-out, mandatory fix(inbound): floor bump) and added the never-before-written Release Close-Out runbook — every correction pinned by a new ExUnit assertion in `test/mailglass/docs_contract_test.exs`, with two of the three pins proven to fail against a live mutation (config-array widening, script rename) rather than assumed to work.**

## Performance

- **Duration:** ~25 min
- **Completed:** 2026-09-18T12:42:00Z
- **Tasks:** 3
- **Files modified:** 3 (MAINTAINING.md, CONTRIBUTING.md, test/mailglass/docs_contract_test.exs)

## Accomplishments
- Task 1 (tracer): MAINTAINING.md's "twelve `exclude-paths`" corrected to "fourteen", now derived from `release-please-config.json`'s `.packages["."]["exclude-paths"]` array length at test time via a new `count_word!/1` helper (1..30 literal English-word map, `flunk` outside range) — never a second hardcoded literal. RED proof and a live mutation proof (config array temporarily widened to 15 entries, confirmed RED naming "15/fifteen", then reverted) both captured in the commit body.
- Task 2: MAINTAINING.md's "Monitor the hands-free publish fan-out" heading and "the hands-free path can never self-skip its own gate" sentence reworded to name the real mechanism — one manual `required_reviewers` approval per package (three stops on a linked release), and the override input only being read on a `workflow_dispatch` event. CONTRIBUTING.md's stale `fix(inbound):` floor-bump paragraph rewritten to describe the current bare `{:mailglass, "~> 2.0"}` sibling constraint (no explicit floor); the unrelated `fix(inbound):` example commit message at line 161 is untouched.
- Task 3: New `## Release Close-Out` section in MAINTAINING.md — the five-state ledger machine (`inactive → captured → authorized → published → completed → inactive`), a 4-step runbook (confirm eligible status → `scripts/release_policy_close_out.sh --write` → the baseline guard fails loudly on disagreement rather than being bypassable → confirm `inactive` and commit the ledger change as its own reviewed PR), and `scripts/release_policy.exs`'s `close-out` CLI verb named as the underlying implementation. Pinned with a section-extraction test that asserts the five states, both script paths, and `File.exists?/1` for every `scripts/*.sh|.exs` reference found in the section — proven to fail via a live rename-and-revert mutation.

## Task Commits

1. **Task 1: TRACER — derive the exclude-paths count and correct MAINTAINING.md** - `6f8277ae` (docs)
2. **Task 2: Retire "hands-free publish fan-out" and CONTRIBUTING.md's floor bump** - `f499bc74` (docs)
3. **Task 3: Add the MAINTAINING.md Release Close-Out runbook** - `adbb91cf` (docs)

_No plan-metadata commit yet — that follows this SUMMARY per the executor's `<final_commit>` step._

## Files Created/Modified
- `MAINTAINING.md` - exclude-paths count corrected + derived; "hands-free" fan-out/override wording corrected; new `## Release Close-Out` section added
- `CONTRIBUTING.md` - sibling pin guidance paragraph rewritten to match the current bare `~> 2.0` reality
- `test/mailglass/docs_contract_test.exs` - new `describe "MAINTAINING.md contract"` (3 tests) and `describe "CONTRIBUTING.md contract"` (1 test) blocks, plus a new `count_word!/1` private helper

## Decisions Made
- The fan-out override sentence names the real GitHub Actions mechanism (input only read on `workflow_dispatch`) rather than the plan's more abstract "release event is inert" phrasing — more precise and equally true.
- `## Release Close-Out` was placed after the CURRENT "Current protected release and recovery path" section rather than immediately after the historical (explicitly non-authoritative) "Monitor the hands-free publish fan-out" step, since close-out logically follows the live path's own post-publish validation step, not a historical numbered list.
- CONTRIBUTING.md's major-bump sentence was reworded to avoid the phrase "requires a deliberate" entirely (not just narrowed relative to `fix(inbound):`), so the new negative pin stays maximally strict against the specific defective claim rather than being scoped down to accommodate an accurate sentence that happened to share wording with the stale one.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] First draft of CONTRIBUTING.md's major-bump sentence tripped its own new refute test**
- **Found during:** Task 2 (writing the pinning test for CONTRIBUTING.md)
- **Issue:** The initial corrected paragraph read "...requires a deliberate sibling constraint bump..." for the core-major case — accurate, but it reintroduced the literal phrase `requires a deliberate` that the new `refute contributing =~ "requires a deliberate"` test (scoped to catch the stale floor-bump instruction) also matches.
- **Fix:** Reworded to "...needs a sibling constraint bump..." — same meaning, no shared substring with the stale phrase.
- **Files modified:** CONTRIBUTING.md
- **Verification:** `mix test test/mailglass/docs_contract_test.exs --warnings-as-errors` green after the reword (52/53 tests passing at that point in the sequence, 0 failures).
- **Committed in:** `f499bc74` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug — self-tripped test, caught and fixed before commit)
**Impact on plan:** No scope creep; the fix is a one-word rewording caught by the plan's own new test, exactly the pinning mechanism working as designed.

## Issues Encountered
- An `awk` range-pattern verification command (`awk '/^## Release Close-Out$/,/^## /'`) used ad hoc during Task 3's manual acceptance-criteria check returned 0 for all matches — a known `awk` gotcha where the start pattern also matches the end pattern on the same line, terminating the range immediately. This was a verification-tooling artifact only; the actual Elixir regex in the pinning test (`~r/^## Release Close-Out\n([\s\S]*?)(?=^## |\z)/m`) does not have this bug and the test passes. Re-verified with a corrected `awk` script (`flag`-based, not a range pattern) confirming all required content is present.
- Task 1's `count_word!/1` helper necessarily contains the literal string `"fourteen"` as one of 30 map entries (`14 => "fourteen"`), which technically registers on the plan's acceptance-criteria grep check (`grep -vE '^\s*#' ... | grep -c '"fourteen"'` expected `0`, actual `1`). This is a structural tension in the plan's own acceptance criteria: Task 1's `<action>` explicitly requires "a private helper `defp count_word!(n)`... backed by a literal map covering at least 1..30", which necessarily contains a literal `"fourteen"` mapping entry. The intent behind the grep check — that the *word is never asserted as an expected value bypassing derivation* — is satisfied: the test never writes `assert maintaining =~ "fourteen"` directly; it always goes through `count_word!(count)` where `count` is read from the config file at test time. Documented here rather than silently working around it.

## Next Phase Readiness
- Plan 01's three tasks (tracer + two auto tasks) are complete, committed, and green against both the targeted test file and the `support_contract_core` full CI lane.
- The pinning mechanism (derived-from-source assertions in `docs_contract_test.exs`) is now proven end-to-end for this phase's remaining DOCS-0x/STAND-01 plans to reuse without re-deriving the pattern.
- No blockers for 167-02 onward.

---
*Phase: 167-truthful-documentation-and-the-standing-control*
*Completed: 2026-09-18*
