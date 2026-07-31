---
phase: 143-test-harness-truth
plan: 13
subsystem: infra
tags: [github-actions, release-pipeline, publish-gate, hex, drift-meta-test, anti-recursion]

requires:
  - phase: 143-test-harness-truth (plans 01-12 + five gap-closure plans)
    provides: a genuinely green Core Full Suite on `main`, the D-21 lane rename, the executed-count floor, the advisory-matrix registry axis, and the closed promotion checkpoint
provides:
  - "`gate-ci-green` reads `advisory-matrix.yml` as well as `ci.yml`; the two Elixir 1.18 / OTP 27 Core Full Suite legs can veto a Hex publish"
  - "A dual-workflow self-heal that DISPATCHES both workflows on the release ref under one shared 30-minute deadline, fan-out safe"
  - "A dispatch-only, release-inert override with a required and echoed reason, which lifts the wait as well as the verdict"
  - "Eight drift assertions binding the two new JS arrays, the override inputs, the presence loop and the event guard to the registry"
  - "`143-GATING-DECISION.md` — the recorded verdict, its five evidence conditions, and its three accepted costs"
affects: [143-14, release-pipeline, publish-hex, MAINTAINING.md, branch-protection]

tech-stack:
  added: []
  patterns:
    - "Dispatch-then-poll instead of look-up, for any check keyed to a release-please bot-merged SHA"
    - "One step, N workflows, one shared deadline — never a serial second deadline"
    - "Query by head_sha + randomised settle + re-check, as the fan-out dedup that does not need a concurrency-group change"
    - "Override lifts the wait as well as the verdict, so it can rescue an unobtainable subject"

key-files:
  created:
    - .planning/phases/143-test-harness-truth/143-GATING-DECISION.md
  modified:
    - .github/workflows/publish-hex.yml
    - test/scripts/lane_classification_drift_test.exs
    - test/support/ci_lanes.ex
    - MAINTAINING.md

key-decisions:
  - "Verdict `gate-floor-legs`: the two 1.18 / OTP 27 legs gate; the 1.19 / OTP 28 legs, Provider Compatibility and both Inbound legs stay advisory"
  - "The self-heal DISPATCHES advisory-matrix.yml on the release ref rather than looking a run up — a release SHA structurally has none, so a lookup-only gate would wedge every release"
  - "The override lifts the WAIT as well as the verdict, so it can rescue the case where no run is obtainable at all"
  - "The gate reads the newest COMPLETED advisory-matrix run, not the newest run, so an in-flight fan-out dispatch cannot block on timing"
  - "MAINTAINING.md's two gating rows moved advisory/promote -> publish-gating/keep-with-reason in the same commit as the gate, and the drift assertion moved with them — classification, not disposition, is now the load-bearing cell"

patterns-established:
  - "Anti-recursion self-heal: any gate keyed to a bot-merged release SHA must obtain its subject, not query for it"
  - "Fail-closed absence: missing, cancelled and skipped all block with the same weight as failure, via a presence loop over DECLARED lanes rather than a filter over returned jobs"

requirements-completed: []

coverage:
  - id: D1
    description: "The two 1.18 / OTP 27 Core Full Suite legs block a Hex publish when red, cancelled, skipped or absent"
    requirement: HARNESS-04
    verification:
      - kind: unit
        ref: "test/scripts/lane_classification_drift_test.exs — ADVISORY_MATRIX_GATING_LANES set-equality + presence-loop posture guard"
        status: pass
      - kind: other
        ref: "mutation M1: dropping the mailglass gating leg from the JS array reds 2 tests; restored byte-identical"
        status: pass
    human_judgment: false
  - id: D2
    description: "The dual-workflow self-heal dispatches and polls both workflows under one shared bounded deadline on a real release SHA"
    requirement: HARNESS-04
    verification:
      - kind: other
        ref: "actionlint + node --check on all three github-script bodies; no live release executed this path"
        status: unknown
    human_judgment: true
    rationale: "Only a real release (or plan 143-14's rehearsal) can show the tag-ref dispatch, the shared deadline and the fan-out settle behaving as designed. Static checks cannot observe a dispatch."
  - id: D3
    description: "A dispatch-only, release-inert override with a required and echoed reason"
    requirement: HARNESS-04
    verification:
      - kind: unit
        ref: "test/scripts/lane_classification_drift_test.exs — override input declaration, required marker, event guard, + paired negative control"
        status: pass
      - kind: other
        ref: "mutations M3 (strip required: true) and M4 (strip the event guard) each red the suite; restored byte-identical"
        status: pass
    human_judgment: false

status: complete
---

# Phase 143 Plan 13: Publish Gating for the Core Full Suite Floor Legs — Summary

The two Elixir 1.18 / OTP 27 `Core Full Suite` legs can now veto a Hex publish, reached by a self-heal
that **dispatches** the run rather than looking one up — because a release commit structurally has none.

---

## What changed, in the order it matters

### 1. The verdict, recorded before any wiring (Task 1)

`.planning/phases/143-test-harness-truth/143-GATING-DECISION.md` records `gate-floor-legs`, the five
promotion conditions it rests on with their run IDs, and the three accepted costs verbatim. The
decision was already the maintainer's — `143-PROMOTION-CHECKPOINT.md` § "Decision of record" says
plan 143-13 "must not re-ask" — so this record executes it rather than re-opening it. What had been
genuinely open was *when*, and the checkpoint closed:

| Condition | Evidence |
|---|---|
| C1 — three greens, three distinct `main` SHAs | `30595090072` (`d6e50388`), `30635221221` (`981b9343`), `30638980059` (`7649f96f`) |
| C2 — one of them a cron | `30607136165`, `schedule`, `d6e50388`; first green cron since 2026-07-02 |
| C3 — tag-shaped-ref dispatch | `30595564984`, throwaway tag cut from green `main`, both legs green, tag deleted |
| C4 — the probe went red | `30599206217`, both gating legs **FAILURE** on the verbatim synthetic-failure commit (PR #156) |
| C5 — floors merged and enforcing | `public: 1576`, `mailglass: 1575`, `skipped_ceiling: 7`, enforced on every leg including the previously-unmeasured 1.19 / OTP 28 pair |

### 2. The self-heal now obtains its subject instead of asking for it (Task 2)

This is the design constraint that arrived after the plan was written, and it changes the shape of
the answer rather than adding to it.

**A release commit gets no `advisory-matrix.yml` run at all.** GitHub raises no workflow for an event
made with `GITHUB_TOKEN`, release-please bot-merges the release PR, and `advisory-matrix.yml` has no
`release:` trigger. Verified live on `e88daa15` (`chore: release main (#158)`, the commit that
published 2.2.2): zero Advisory Matrix runs. It is the same anti-recursion rule CLAUDE.md already
records for `ci.yml`, and the same one that defeated `gate-self-test.yml`.

So a gate that merely **looks up** an advisory-matrix run for the publish SHA would block on a SHA
that structurally cannot have one, and would wedge the hands-free pipeline silently, on every
release, forever. The self-heal therefore **dispatches** `advisory-matrix.yml` on the release ref and
waits for it. That path is rehearsed rather than assumed: condition C3's run `30595564984` dispatched
this workflow on a tag-shaped ref and both gating legs went green.

Everything else about the step is a generalisation of the one that already existed:

- **One step, two workflows, one deadline.** The single poll loop advances both workflows each
  iteration. A serial second 30-minute wait would turn a 30-minute worst case into 60, on a pipeline
  nobody is watching.
- **Fan-out safe.** One linked-version release train publishes two tags, so two `publish-hex` runs
  can reach this step seconds apart. Both resolve to the same head SHA, so the step queries by
  `head_sha`, settles a randomised interval up to 15s, then **re-checks**: if the sibling's dispatch
  has landed it polls that run instead of dispatching again. Worst case is one redundant matrix run.
- **The fix is explicitly NOT a concurrency-group change**, and a comment says so. Keying
  `advisory-matrix.yml`'s group on the SHA would put two same-SHA dispatches in one
  `cancel-in-progress: true` group; they would cancel each other, both gates would read `cancelled`,
  and both would block. `advisory-matrix.yml`'s own concurrency comment already records this; the
  workflow was not touched.
- **`sha` and `ref` moved from `${{ }}` splices into `env:` bindings.** A tag name landing inside a JS
  string literal was pre-existing; it is no longer.
- The deadline message keeps the literal `Delivery blocked: ` prefix and names the recovery dispatch
  for each stalled workflow. The `permissions:` block is unchanged — `actions: write` already covered
  exactly this dispatch, for one workflow instead of two.

### 3. The gate decision table (Task 3)

Two new arrays hold the exact runtime names from `Mailglass.CILanes.advisory_matrix_gating_lanes/0`
(2) and `.advisory_matrix_advisory_lanes/0` (5), matched by **exact equality**. That is safe here for
a reason worth stating: unlike `ci.yml`'s statically-named matrix jobs, every `advisory-matrix.yml`
job interpolates each matrix axis into its own `name:`, so GitHub reports it fully substituted with no
appended suffix. The uninterpolated-template collapse (D-21) happens on `pull_request` runs, which
this gate never reads.

| Situation | Verdict |
|---|---|
| Gating leg failed, cancelled, skipped, or **missing** | **BLOCK** — a presence loop over the declared lanes, mirroring the required-lane loop |
| Zero advisory-matrix runs on the SHA | **BLOCK** — the zero-count fail-closed path, preserved |
| Runs exist but none completed | **BLOCK** — a run still in progress is not a green run |
| Advisory leg missing | WARN, and the message names the `if: github.event_name != 'pull_request'` job condition as the designed reason |
| Advisory leg red | WARN |
| Unclassified lane red | **BLOCK**, naming the registry and the arrays to add it to |
| Unclassified lane green | WARN |

Two details beyond the plan's letter, both fail-closed in the right direction:

- The gate reads the newest **completed** run rather than the newest run outright. The fan-out can
  leave a second dispatch still in flight on the same SHA, and reading its null conclusions would
  block a release for a reason about timing rather than about the tree. Every run on that SHA tests
  the same tree, so any completed one is a legitimate reading.
- `job.conclusion !== 'success'` is what catches cancelled, skipped **and** in-progress in one branch —
  the same shape the existing required-lane loop uses, deliberately not re-derived.

**Every pre-existing verdict path is byte-identical.** `git diff origin/main` on the workflow removes
exactly two things: the old single-workflow self-heal step it replaces, and the job comment it
rewrites. Not one line of the required-lanes array, the prefix-match helper, the `classify/1` chain,
or any existing message string was removed or edited.

### 4. The override, and the drift assertions (Task 4)

```
gh workflow run publish-hex.yml \
  -f tag=mailglass-v<version> -f package=all -f dry_run=false \
  -f skip_core_full_suite_gate=true \
  -f core_full_suite_gate_skip_reason="<why>"
```

- **Dispatch-only and inert on the release event.** Enforced once, in each consuming script, as
  `process.env.SKIP_CORE_FULL_SUITE_GATE === 'true' && context.eventName !== 'release'`. The
  hands-free path can never self-skip its own gate.
- **The reason is required** (`required: true` on the input) **and non-empty at runtime** — a blank
  reason blocks with its own message. An override with an optional reason is an override with no
  reason.
- **It lifts the wait as well as the verdict.** This is the one substantive addition to the plan's
  design, and it is what makes the override actually affordable: if GitHub Actions itself cannot
  produce an advisory-matrix run, a verdict-only override would still deadline out 30 minutes later in
  the self-heal, regardless of what the verify step would have decided. With the override active the
  self-heal simply does not add `advisory-matrix.yml` to its workflow list.
- **The reason is untrusted text and is treated as such.** Both inputs are bound through the job's
  `env:` block and read as environment values; neither is ever concatenated into a `run:` body or an
  inline expression. Before reaching the run summary the reason is collapsed to one line, reduced to a
  conservative character set — no backtick, angle bracket, ampersand, bracket, pipe, hash, asterisk or
  backslash survives — truncated to 300 characters, and rendered in a code block, never as markdown.
- **It announces itself as an exception.** A `core.warning` names it as such, and the run summary
  states plainly that the publish was not gated on the two legs.

Eight new assertions in `lane_classification_drift_test.exs`: two set-equalities against the registry
accessors with anti-vacuity size guards naming the array and the file, a disjointness check, a paired
negative control per set-equality exercising the same `drift/2` helper, a posture guard on the gating
failure message and the presence loop, an override-declaration/required-marker/event-guard test, and a
negative control for the required marker.

---

## Mutation evidence — every new guard proven non-vacuous

Each defect was reintroduced, observed firing, then reverted and confirmed byte-identical
(`diff -q` against a pre-mutation copy).

| # | Defect reintroduced | Result | Reverted |
|---|---|---|---|
| M1 | Drop `Core Full Suite (… / schema mailglass)` from `ADVISORY_MATRIX_GATING_LANES` | **2 failures** — set-equality + its negative control | byte-identical |
| M2 | Drop a next-toolchain leg from `ADVISORY_MATRIX_ADVISORY_LANES` | **2 failures** — set-equality + its negative control | byte-identical |
| M3 | Strip `required: true` from the override reason input only | **2 failures** — required-marker assertion + its negative control | byte-identical |
| M4 | Delete `&& context.eventName !== 'release'` (both occurrences) | **1 failure** — the release-inertness guard | byte-identical |
| M5 | Turn the gating presence loop into a filter over returned jobs | **1 failure** — the presence-loop posture guard | byte-identical |

**M3 also produced a finding worth keeping.** The first attempt used a global replace of
`required: true\n        type: string\n` and the suite stayed green — because the pre-existing `tag:`
input carries a byte-identical pair and absorbed the mutation. That is the *correct* outcome (the
extractor is bounded to one input's own block, so mutating a different input must not fire this
assertion), but it meant the mutation had not been performed. The in-test negative control had the
same global-replace sloppiness and was rewritten to anchor on the input key. A whole-file
`String.contains?(source, "required: true")` would have passed on `tag:`'s marker and proved nothing
about the override — which is precisely the vacuous-guard shape this phase exists to eliminate.

---

## Verification

All runs against a freshly dropped and recreated `Mailglass.TestRepo`.

| Check | Result |
|---|---|
| `mix test --seed 783091 --exclude requires_workspace` (public) | **1615 tests, 0 failures**, 7 skipped, 13 excluded; executed 1631 |
| `MAILGLASS_SCHEMA=mailglass mix test --seed 374117 --exclude requires_workspace` | **1614 tests, 0 failures**, 7 skipped, 14 excluded; executed 1630 |
| `MIX_ENV=test mix compile --force --warnings-as-errors` (209 files) | exit 0 |
| `MIX_ENV=test mix dialyzer` | passed; 16 errors, 16 skipped, **0 unnecessary skips**, no `.dialyzer_ignore.exs` entry added |
| `mix format --check-formatted` | clean |
| `mix credo --strict` | 3936 mods/funs, no issues |
| `actionlint` (all workflows) | clean |
| `mix test test/scripts/ --warnings-as-errors` | **110 tests, 0 failures** (102 before; 8 added) |
| `mix test test/scripts/required_checks_test.exs` | 6 tests, 0 failures — the required set is still exactly two entries |

**On the real gating toolchain** (`make toolchain`, Elixir 1.18.4 / OTP 27, 2 vCPU / 4 GB) — local is
1.19.5 / OTP 28 and has twice produced changes green locally that broke every gating lane, so no claim
about gating-leg behaviour rests on the local runs above:

| Axis | Result |
|---|---|
| public, `--warnings-as-errors --seed 783091` | **1628 tests, 0 failures**; executed 1631; `already_shared=0` |
| mailglass, `MAILGLASS_SUITE_FLOOR=1 --warnings-as-errors --seed 374117` | **1628 tests, 0 failures**; executed 1630 ≥ floor 1575, skipped 7 ≤ ceiling 7, **0 violations**; `already_shared=0` |

The mailglass toolchain run also exercised floor **enforcement**, not just reporting: `scope: FULL
SUITE (MAILGLASS_SUITE_FLOOR=1) — … a violation halts this run`.

Additionally, all three `actions/github-script` bodies were extracted from the YAML and passed
`node --check`. A syntax error in this workflow would otherwise surface for the first time during a
real release.

Untouched, as the plan requires: `scripts/setup_branch_protection.sh` and
`.github/workflows/advisory-matrix.yml` show no diff against `origin/main`.

---

## Deviations from Plan

### 1. [Rule 2 — required for correctness] `MAINTAINING.md` and `ci_lanes.ex` changed; both were outside `files_modified`

**Found during:** Task 3.
**Issue:** the plan's `files_modified` lists three paths, but `MAINTAINING.md` says in its own prose
*"When the gate lands, those two rows move to `publish-gating` / `keep-with-reason` in the same commit
that adds the gate,"* the drift assertion's own failure message says *"when plan 143-13 wires the gate
up, that row moves … and this expectation moves with it,"* `ci_lanes.ex` carried a `NOT YET LIVE:
gate-ci-green does not read advisory-matrix.yml today` comment, and Task 3's own
`<reversibility>` note names `MAINTAINING.md` as one of the files an undo would touch. Leaving them
would have shipped documentation that says the opposite of what the code does — the signal-honesty
defect this whole milestone exists to fix.
**Fix:** the two gating rows moved `advisory`/`promote` → `publish-gating`/`keep-with-reason`; the
section prose was rewritten; the registry comment was corrected; all in the same commits as the gate.
**Commits:** `db81e8d4`, `db6a7828`.

### 2. [Rule 2] One pre-existing drift assertion was rewritten rather than left untouched

**Found during:** Task 3. The plan says to leave every pre-existing assertion untouched and lists four
by name. The disposition-tracking assertion is not among the four, and it is the one assertion in the
file explicitly written to move when this plan landed.
**Issue:** with both buckets now `keep-with-reason`, a disposition-only check would have become
vacuous — it would pass for every row regardless of bucket.
**Fix:** the assertion now pins **classification** (`publish-gating` for the gating pair, `advisory`
for the other five), which is the cell that actually differs between buckets, plus a separate
disposition check. Strictly stronger than what it replaced. Proven by mutation: flipping one
MAINTAINING.md classification cell back to `advisory` reds it with a named message.
**Commit:** `db81e8d4`.

### 3. [Rule 2] The override lifts the self-heal's wait, not only the verify step's verdict

**Found during:** Task 4. The plan scopes the override to "the Core Full Suite classification."
**Issue:** several gated steps are network- and service-dependent (the inbound `mix deps.get`, the
inbound `mix ecto.create`). A verdict-only override handles a *failed* lane, but not an
*unobtainable* one: if no advisory-matrix run can be produced at all, the self-heal step deadlines out
30 minutes before the verify step ever runs, and the override never gets a say. That directly
contradicts "must keep a blocked release affordable."
**Fix:** with the override active the self-heal does not add `advisory-matrix.yml` to its workflow
list, and every advisory-matrix blocking path in the verify step warns instead of failing. The
unclassified-red rule still blocks, because an unclassified lane is not the Core Full Suite gate.

### 4. [Rule 2] The gate reads the newest COMPLETED run, not the newest run

**Found during:** Task 3.
**Issue:** the existing `ci.yml` lookup takes `workflow_runs[0]` unconditionally. Mirroring that for
advisory-matrix would let a second in-flight fan-out dispatch — which the fan-out mitigation
deliberately tolerates as "worst case one redundant run" — block a release with null conclusions.
**Fix:** filter to `status === 'completed'` and block if none has. Every run on that SHA tests the
same tree, so reading a completed one is legitimate; reading an in-flight one is a timing artifact.

### 5. [Documented] The required reason input adds friction to every manual dispatch

`core_full_suite_gate_skip_reason` is `required: true`, which the plan and its acceptance criteria
both demand. GitHub enforces required inputs on every dispatch, so the documented fallback command in
`MAINTAINING.md` now needs `-f core_full_suite_gate_skip_reason="n/a"` even when nothing is being
overridden. That doc was updated in the same commit. The alternative — an optional reason enforced
only at runtime — was rejected: it would leave the YAML declaration saying the reason is optional,
which is the kind of gap between declaration and behaviour this phase is about.

---

## What only a real CI run can confirm

Recorded so none of it is mistaken for settled, and so plan 143-14 knows what it is rehearsing.

1. **The dispatch-and-poll path has never executed on a real release SHA.** Everything about it is
   verified statically (`actionlint`, `node --check`, the drift assertions) plus one rehearsed
   ingredient (C3's tag-ref dispatch, run `30595564984`). The composition — resolve the release tag,
   find zero runs, settle, dispatch on the tag, poll to completion, read the jobs, render the verdict —
   has not run end to end.
2. **The shared 30-minute deadline's real headroom.** The gated leg ran 258.2s of `mix test` alone in
   run `30574508370` and 183–190s locally on the toolchain, plus `deps.get`, a warnings-as-errors
   compile, a Postgres wait, the inbound `deps.get`/`ecto.create` and `mix verify.schema_prefix`. The
   expected cost is roughly ten and a half minutes cold-cache, well inside 30 — but that is an
   estimate from adjacent runs, not a measurement of this path.
3. **The fan-out settle actually deduplicating.** Whether the second `publish-hex` run finds the
   first's dispatch inside a ≤15s window depends on real GitHub run-registration latency. If it does
   not, the designed outcome is one redundant matrix run, not a failure — but that has not been
   observed.
4. **The duplicate-publish race is still there and this change did not make it worse.** Both tags of a
   release train dispatch a fan-out including `publish-core`, so the second fails with `must include
   the --replace flag to update an existing release`. `gate-ci-green` emits no message resembling
   that string, and the new blocking messages all carry the `Delivery blocked: ` prefix and name a
   lane — so a genuine core-publish failure stays distinguishable from that noise. Fixing the race
   itself is TRUTH-08 / Phase 144, untouched here.
5. **Whether the override's summary rendering looks right.** The character-set reduction and code-block
   rendering are unit-reasoned, not eyeballed on a real summary page.

## HARNESS-04 is NOT flipped to `[x]`

`.planning/REQUIREMENTS.md` is unchanged. The gate is wired, guarded and proven non-vacuous by
mutation, but the thing HARNESS-04 actually claims — that a core regression cannot reach Hex —
depends on a code path that has never executed against a release. Plan 143-14's rehearsal is what
proves it. This phase has had four premature-completion incidents; the box stays open and the
evidence above is left for 143-14 to close it against.

## Known Stubs

None. No placeholder, no `TODO`, no skipped test, and no weakened assertion was introduced.

Two entries were appended to `.planning/WINDOWS.md`:

- `unrun-verify` — the dispatch-and-poll path has not executed on a real release SHA (item 1 above).
- `lint-warning` — `SuiteFloor`'s `executed_nudge` fires on the gating toolchain (1630 executed vs
  pinned floor 1575, 55 above the 40-test nudge margin). **Advisory only; it halts nothing, and it
  already fired on `main` before this plan** — run `30635221221`'s 1.19/public leg showed 1623
  executed against floor 1576, 47 above the margin. Re-pinning must be measured from a real CI run per
  143-10's protocol, not from a local one, so it is recorded rather than adjusted here.

## Threat Flags

None. The threat register's five `mitigate` dispositions (T-143-46 through T-143-50) are each
implemented and, where testable from Elixir, pinned by an assertion with a mutation proof. T-143-51
(`accept`) holds: the `permissions:` block is unchanged and publishing stays behind the `hex-publish`
environment, so the Hex key is never visible to pull-request jobs. No credential scoping was touched.

## Commits

| Commit | Task | What |
|---|---|---|
| `57bb75d2` | 1 | The `gate-floor-legs` verdict, its evidence, its accepted costs |
| `465c2150` | 2 | Dual-workflow self-heal: dispatch both, one shared deadline, fan-out safe |
| `db81e8d4` | 3 | The two classification arrays and the four-rule decision table |
| `db6a7828` | 4 | The dispatch-only override and eight registry-binding drift assertions |

## Self-Check: PASSED

All four commits exist in `git log`; all six created/modified files exist on disk; the working tree is
clean apart from this summary and the two `.planning/WINDOWS.md` ledger entries it describes.
