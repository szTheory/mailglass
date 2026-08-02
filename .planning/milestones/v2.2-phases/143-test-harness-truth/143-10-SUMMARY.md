---
phase: 143-test-harness-truth
plan: 10
subsystem: test-harness
tags: [harness-02, harness-03, suite-floor, anti-vacuity, d-14, d-16, d-27, ci-evidence]
status: complete
requires:
  - "143-09 — Mailglass.TestSupport.SuiteFloor with placeholder thresholds, and its contract test"
  - "143-08 — the exclusion-tag allowlist and its both-directions check"
  - "Green Advisory Matrix run 30568802513 — the only permitted source for the pinned numbers (D-27)"
provides:
  - "Per-schema executed floors measured from a green 1.18/OTP 27 CI run: public 1576, mailglass 1575"
  - "Skipped ceiling pinned at 7, measured on both legs"
  - "MAILGLASS_SUITE_FLOOR=1 on both advisory-matrix.yml full-suite steps — enforcement is live"
  - "A drift assertion that fails if either occurrence of the opt-in disappears"
  - "Research assumption A1 confirmed on Elixir 1.18.4: after_suite/1 carries all four count keys"
affects:
  - "test/support/suite_floor.ex, test/scripts/suite_floor_contract_test.exs"
  - ".github/workflows/advisory-matrix.yml, test/scripts/lane_classification_drift_test.exs"
tech-stack:
  added: []
  patterns:
    - "Threshold pinned in two places on purpose: the constant, plus a drift tripwire in the contract test citing the source run ID"
    - "Run scope as an explicit argument to a pure function, so 'the operator deliberately narrowed this run' is never mistaken for 'coverage was silently lost'"
key-files:
  created: []
  modified:
    - test/support/suite_floor.ex
    - test/scripts/suite_floor_contract_test.exs
    - .github/workflows/advisory-matrix.yml
    - test/scripts/lane_classification_drift_test.exs
decisions:
  - "Pinned the floors per-schema (public 1576 / mailglass 1575) rather than per {schema, elixir_minor}: D-16's re-keying instruction applies to an OBSERVED divergence, and the 1.19 legs have never run on this branch, so no divergence has been observed."
  - "Fixed the exclusion_allowlist_unknown_tag false positive on `:test` inside this plan rather than deferring it. Task 2's own action is 'confirm the exclusion-tag allowlist against the green run's effective exclusion sets', the fix is the same shape as the already-recorded `:requires_workspace` narrowing, and the instrument being pinned is the instrument that was crying wolf."
  - "Made the executed floor, growth nudge and skipped ceiling evaluate only on a run that declares itself a complete suite. Pinning real floors would otherwise have printed '[VIOLATION] Only 4 test(s) executed, below the pinned floor of 1576' on every focused developer run — a false alarm introduced by this very commit."
  - "Did NOT re-pin the floors to include the 14 tests this plan adds. There is no green CI run containing them; D-27 permits pinning only from green CI evidence, and the >= comparison absorbs growth by design."
metrics:
  duration: "~2h"
  completed: "2026-07-30"
  floors-pinned: 2
  mutations-run: 2
  new-tests: 14
---

# Phase 143 Plan 10: Pin the anti-vacuity thresholds and turn enforcement on — Summary

**The numbers stopped being placeholders. Per-schema executed floors of 1576 (public) and 1575 (mailglass) and a skipped ceiling of 7 are pinned from the two green Elixir 1.18.4 / OTP 27 legs of Advisory Matrix run `30568802513`, enforcement is live on both full-suite steps, and a suite that loses one test file now exits non-zero while ExUnit still reports `0 failures`.**

---

## Task 1 — the four-leg green checkpoint, and what the evidence actually is

**Run `30568802513`** (`Advisory Matrix`, branch `gsd/phase-143-test-harness-truth`, head SHA `369577b0`, `pull_request` event, 2026-07-30T18:04:22Z) — overall conclusion `success`.

| Job | Leg | Conclusion | Seed | `after_suite` counts | executed |
|---|---|---|---|---|---|
| `90959947929` | Elixir 1.18.4 / OTP 27.3.4.15 / schema `public` | `success` | 478127 | `total: 1596, excluded: 13, skipped: 7, failures: 0` | **1576** |
| `90959948064` | Elixir 1.18.4 / OTP 27.3.4.15 / schema `mailglass` | `success` | 43820 | `total: 1596, excluded: 14, skipped: 7, failures: 0` | **1575** |
| — | Elixir 1.19 / OTP 28 / schema `public` | **`skipped`** | — | — | — |
| — | Elixir 1.19 / OTP 28 / schema `mailglass` | **`skipped`** | — | — | — |

`signature tally: already_shared=0, formatter_violations=0` on both green legs.

### The checkpoint was met in substance, not in the letter — recorded plainly

Task 1 asked for **four** green Core Full Suite legs. **Two ran.** `core_latest_elixir_advisory` carries `if: github.event_name != 'pull_request'` (`advisory-matrix.yml:152`), and every Advisory Matrix run this branch has ever produced was a `pull_request` event:

```
30568802513 pull_request success   369577b0
30564591156 pull_request failure   7e149ad5
30561673620 pull_request failure   355e7ebb
30557831075 pull_request success   60349d87
30555218236 pull_request failure   7a6c4f90
30516126767 pull_request failure   fd13d390
```

So the 1.19/OTP 28 legs have not merely failed to be green — they have never executed on this branch at all, and the process constraints for this plan forbid dispatching a workflow to make them. This is not a hedge: it is the reason the floors are keyed on schema alone (see Task 2), and it is the single largest open item this plan leaves behind (see "Still Open").

The two legs that **do** exist are the two that matter most: they are the gating toolchain (Elixir 1.18.4 / OTP 27, the `~> 1.18` floor `mix.exs` declares), and per HARNESS-04's scope split they are the only publish-gating pair. Pinning from them is pinning from the leg the floor is meant to guard.

### Research assumption A1 — CONFIRMED on the gating toolchain

A1 held that `ExUnit.after_suite/1`'s callback map carries `:total`, `:failures`, `:excluded` and `:skipped` on Elixir 1.18.4. It had only ever been verified on 1.19.5 locally. `check/1` reads all four with `Map.fetch!/2`, so a missing key raises `KeyError` rather than printing; both 1.18.4 jobs printed a complete count line, which is a live observation of the four-key shape on the gating toolchain rather than an inference from a typespec. Recorded in the moduledoc next to the `Map.fetch!/2` guard, with the run ID.

### The exclusion sets agreed with the allowlist exactly, in the shape Task 2 predicted

```
job-public.log:704     Excluding tags: [:requires_workspace]
job-mailglass.log:703  Excluding tags: [:requires_workspace, :public_only]
```

The public leg carries one fewer token than the mailglass leg and the difference is exactly `:public_only` — precisely what `expected_exclusion_tags/1` asserts, confirmed against live CI output rather than against the code that produces it.

---

## Task 2 — the thresholds

### What was pinned

| Constant | Value | Source |
|---|---|---|
| `@executed_floors["public"]` | **1576** | run `30568802513`, job `90959947929`: `1596 - 13 - 7` |
| `@executed_floors["mailglass"]` | **1575** | run `30568802513`, job `90959948064`: `1596 - 14 - 7` |
| `@skipped_ceiling` | **7** | identical on both legs of the same run |
| `@nudge_margin` | 40 | unchanged — a fixed design constant, never a placeholder |

No safety margin. The measured minimum is pinned exactly, per-schema, compared with `>=`. The one-test spread between the axes is exactly why D-16 forbids a single global floor: `test_helper.exs` excludes `:public_only` on any non-`"public"` schema, so a global floor would have to equal 1575 and would blind the public leg to losing a test.

The skipped ceiling's comment records the grep-versus-measured discrepancy explicitly: a grep of `test/` finds more skip declarations (5 × `@tag :skip` + 3 × `@moduletag :skip`) than the 7 ExUnit reaches, because some sit inside modules the lane's `--exclude requires_workspace` removes wholesale. Raising the constant to match the grep would silently lift the ceiling for every currently-unreachable skip.

Every constant carries its source run ID, its job ID, its arithmetic and its date, plus the "a future legitimate change must update this count deliberately, not delete the guard" instruction in `lane_classification_drift_test.exs:247-265`'s message style.

### Three defects the real numbers made load-bearing

Each was latent while every threshold was `0` or `1_000_000_000`, and each became live the instant real values were pinned.

**1. `[VIOLATION] exclusion_allowlist_unknown_tag: Suite excluded :test` on every `--only` lane.** Visible on **both** legs of the green run, and the orchestrator flagged it independently:

```
Excluding tags: [:test]
Including tags: [:schema_prefix]
[VIOLATION] exclusion_allowlist_unknown_tag: Suite excluded :test, which is not one of
SuiteFloor's known exclusion-tag sources ([:public_only, :requires_workspace]). ...
```

`mix test --only foo` is implemented by ExUnit as the pair `exclude: [:test], include: [foo]`. The `:test` token is the mechanism of scoping a run, not a category anyone stopped covering, and this repo reaches it constantly — `mix verify.schema_prefix`, the three `--only phase_0N_uat` aliases in `mix.exs`, and any `mix test file.exs:12` a developer types.

Fixed by discounting `:test` from the unknown set **when, and only when, the run carries a non-empty include set**. It was deliberately NOT added to `@known_exclusion_tags`, which names the two sources that legitimately withhold coverage; `:test` is not one of them. A bare `--exclude test` with no include set still violates — that excludes the entire suite, nobody means it, and the executed floor catches the same run a second time when it collapses to zero.

This is the same correction, with the same reasoning, as the `:requires_workspace` narrowing already recorded in the moduledoc — where an early draft false-positived on `mix test test/mailglass/test_support/`. Verified live on the exact lane that produced the CI violation:

```
$ mix test test/mailglass/schema_prefix_hardening_test.exs --only schema_prefix --warnings-as-errors
Excluding tags: [:test]
Including tags: [:schema_prefix]
4 tests, 0 failures
  total: 4, excluded: 0, skipped: 0, executed: 4, failures: 0
  0 violation(s).
```

**2. The floor itself would have cried wolf on every focused run — a false alarm this commit would have introduced.** With the floor at 1576, `mix test path/to/one_test.exs` prints `[VIOLATION] executed_floor: Only 4 test(s) executed ... below the pinned floor of 1576`. That is not a regression; it is a developer running one file. Shipping it would have taught the whole team to skim past VIOLATION lines — the same corrosion as defect 1, at a hundred times the frequency, and it is the failure the phase exists to eliminate rather than to install.

The executed floor, the growth nudge and the skipped ceiling are claims about a **complete** suite, so they are now evaluated only on a run that declares itself one via `MAILGLASS_SUITE_FLOOR`. **This removes no enforcement**: `check/1` already gated `System.halt/1` on the same variable, so no run that previously failed can now pass — only the false lines printed by runs that were never going to enforce are gone. The counts themselves still print on every run, so D-13's "the numbers stay fully visible" intent is untouched.

The scope is stated on its own line, in both directions, so a reader who expected a lane to enforce can see at a glance that it did not declare itself a full suite:

```
scope: FULL SUITE (MAILGLASS_SUITE_FLOOR=1) — executed floor 1576, skipped ceiling 7 enforced;
       a violation halts this run.

scope: scoped run (MAILGLASS_SUITE_FLOOR unset) — the executed floor, growth nudge and skipped
       ceiling describe a COMPLETE suite and were not evaluated. The exclusion allowlist and the
       :already_shared / formatter assertions above did run, and nothing halts this run.
```

That is "not applicable to this run, and here is why" — never silence, and never a green that hides a skipped check.

**3. An unpinned schema axis would have passed while measuring nothing.** `executed_floor/1` answers `0` for an unknown schema, and `executed >= 0` always holds. Harmless when every floor was 0; a silent vacuity hole the moment they were real. `floor_violation/3` now checks `pinned_schemas/0` for membership first and reports an unmeasured axis as a violation naming the axes that *are* pinned.

### Contract tests added (11)

- The three thresholds pinned a **second** time as a drift tripwire citing run `30568802513` and the per-job arithmetic — not a second source of truth, a tripwire on the first, so re-pinning is a deliberate two-file act with the D-27 rule in front of whoever does it.
- An anti-vacuity guard that no floor can sit near zero. Every floor boundary test in that file is written *relative to* `executed_floor/1`, so a future edit resetting the floors to their placeholder `0` would leave all of them passing while enforcing nothing.
- Negative controls for each of the three fixes: the `--only` discount does not fire without an include set and does not launder an unrelated unknown tag travelling with `:test`; the scope gate is proven not to be an off switch (the same four-test report **does** violate when the run declares full-suite scope, and the every-run checks survive the gate); the default scope argument is the STRICT reading, so a call site that forgets it over-reports rather than passing vacuously; the unpinned axis violates and does not additionally nudge.

`git diff --name-only .github/` was empty for this task, as its acceptance criteria require.

---

## Task 3 — enforcement live, and the opt-in guarded

`MAILGLASS_SUITE_FLOOR: "1"` added to the **existing** `env:` block on both full-suite steps — `core_full_suite_advisory` (`:127`) and `core_latest_elixir_advisory` (`:246`) — each immediately alongside `MAILGLASS_SCHEMA`, each under a comment naming HARNESS-03 and stating why the variable is opt-in.

| Acceptance criterion | Result |
|---|---|
| `grep -c 'MAILGLASS_SUITE_FLOOR' .github/workflows/advisory-matrix.yml` | **2** |
| Any `run:` line changed | **none** (`git diff -U0` shows no `run:` in the diff) |
| New job / step / job-level / workflow-level env block | **none** |
| `actionlint .github/workflows/advisory-matrix.yml` | exit 0 |
| `mix test test/scripts/lane_classification_drift_test.exs --warnings-as-errors` | 26 tests, 0 failures |

The comments were deliberately reworded to refer to "the second env entry below" rather than repeating the variable name, so the raw `grep -c` count is exactly 2 as the plan specifies rather than 4.

### The drift assertions

Enforcement lives at the intersection of two things — the pinned constants in `SuiteFloor` and this env entry on the lane step — and only one of the two is visible to an Elixir test. Three assertions were added, none of the pre-existing ones touched (the 24-row `ci.yml` count, the two set-equality tests and the `(missing)`-marker guard are all intact and passing):

1. Exactly two occurrences of the **literal** `MAILGLASS_SUITE_FLOOR: "1"` — the value, not merely the key, since `SuiteFloor` compares against `"1"` exactly, so `"0"` or `"true"` would silently disable the gate while leaving the key in place.
2. An anti-vacuity guard naming the parser: the workflow file was found, is non-empty, and does contain the entry — so a moved or renamed file fails on *that*, rather than comparing 0 against 0.
3. A negative control proving the counting function observes a deletion.

### The demonstrated failure (Task 3's acceptance criterion)

One occurrence removed from the real workflow, `mix test test/scripts/lane_classification_drift_test.exs`:

```
26 tests, 2 failures

1) test advisory-matrix.yml's suite-floor opt-in (HARNESS-03) the full-suite steps carry the
   suite-floor env entry exactly twice, with the literal value SuiteFloor compares against
   expected exactly 2 `MAILGLASS_SUITE_FLOOR: "1"` entries in advisory-matrix.yml — one on each
   full-suite step (core_full_suite_advisory's and core_latest_elixir_advisory's) — got 1.

2) ... negative control: deleting one occurrence from the parsed source makes the count assertion
   report it — sanity check failed: the unmodified workflow should already carry both entries
```

Restored from backup; `grep -c` back to 2; the lane re-runs 26/0.

### What was NOT done: the post-change dispatch

Task 3's final acceptance criterion asks for a dispatched `advisory-matrix.yml` run confirming all four legs green with enforcement active. **The process constraints for this plan forbid dispatching GitHub Actions runs and forbid pushing**, so this is not done and is recorded as open rather than claimed. What stands in its place is stated exactly in "Still Open" below, along with the local enforced-lane runs that make a red first CI run unlikely but not impossible.

---

## Anti-vacuity: the floor proven to fail when coverage collapses

The governing rule was "prove it with a mutation — force the executed count below the floor, show the build fails, revert." Done twice, on the real suite, reading raw `mix test` exit codes.

### Positive controls — the pinned floors pass on the real suite, with enforcement live

Both from a freshly dropped and re-created `Mailglass.TestRepo`.

| Command | Report | Exit |
|---|---|---|
| `MAILGLASS_SUITE_FLOOR=1 mix test --seed 783091 --exclude requires_workspace` | `total: 1610, excluded: 13, skipped: 7, executed: 1590, failures: 0` / `scope: FULL SUITE ... executed floor 1576, skipped ceiling 7 enforced` / `0 violation(s).` | **0** |
| `MAILGLASS_SCHEMA=mailglass MAILGLASS_SUITE_FLOOR=1 mix test --seed 374117 --exclude requires_workspace` | `total: 1610, excluded: 14, skipped: 7, executed: 1589, failures: 0` / `executed floor 1575, skipped ceiling 7 enforced` / `0 violation(s).` | **0** |

### The mutation — a silently lost test file, with ExUnit still reporting zero failures

`test/mailglass/docs_contract_test.exs` (33 tests) moved out of `test/` — the classic silent-coverage-loss shape — then the enforced public lane run against a fresh DB:

```
Finished in 87.5 seconds (1.5s async, 85.9s sync)
23 properties, 1541 tests, 0 failures, 6 skipped (13 excluded)

== Mailglass.TestSupport.SuiteFloor (schema "public") ==
  total: 1577, excluded: 13, skipped: 6, executed: 1558, failures: 0
  signature tally: already_shared=0, formatter_violations=0
  scope: FULL SUITE (MAILGLASS_SUITE_FLOOR=1) — executed floor 1576, skipped ceiling 7 enforced;
         a violation halts this run.
  [VIOLATION] executed_floor: Only 1558 test(s) executed on schema "public", below the pinned
  floor of 1576. Tests were silently lost or newly excluded — ...

MUTATION_EXIT_CODE=1
```

**`0 failures` and exit code `1`.** That is the whole point of the instrument: ExUnit was perfectly happy, and the build failed anyway because 32 fewer tests ran than the last green gating run executed. The file was restored and verified byte-identical (`shasum -a 256 -c` → `OK`); `git status --short` is clean of it.

The second mutation is the Task 3 drift demonstration above — the workflow half of the same guard, proven to fail on deletion and restored.

---

## Verification — raw `mix test` / `mix dialyzer` / `mix credo` output only

No SuiteFloor ledger line and no formatter output was used to validate itself; the SuiteFloor blocks quoted above are the subject under test, never the evidence for it. Every suite run below was preceded by `MIX_ENV=test mix ecto.drop -r Mailglass.TestRepo --quiet && MIX_ENV=test mix ecto.create -r Mailglass.TestRepo --quiet`.

| Gate | Command | Result | Exit |
|---|---|---|---|
| mailglass axis | `MAILGLASS_SCHEMA=mailglass mix test --seed 374117 --exclude requires_workspace` | 23 properties, **1573 tests, 0 failures**, 7 skipped (14 excluded) | 0 |
| public axis | `mix test --seed 783091 --exclude requires_workspace` | 23 properties, **1574 tests, 0 failures**, 7 skipped (13 excluded) | 0 |
| Dialyzer | `MIX_ENV=test mix dialyzer` | `Total errors: 16, Skipped: 16, Unnecessary Skips: 0` / `done (passed successfully)` | 0 |
| Format | `mix format --check-formatted` | clean | 0 |
| Credo | `mix credo --strict` | `3912 mods/funs, found no issues.` | 0 |
| Scripts lane | `mix test test/scripts/ --warnings-as-errors` | 86 tests, 0 failures | 0 |
| Workflow lint | `actionlint .github/workflows/advisory-matrix.yml` | clean | 0 |

`--warnings-as-errors` on every suite run. `signature tally: already_shared=0, formatter_violations=0` on both axes. `.dialyzer_ignore.exs` is untouched (`git diff HEAD` empty) and no entry was added — it stays at its hard cap.

### The test-count delta, reconciled exactly

Local executed went 1576 → **1590** (public) and 1575 → **1589** (mailglass): **+14 on both axes**, which is exactly the 14 tests this plan adds (11 in `suite_floor_contract_test.exs`, 3 in `lane_classification_drift_test.exs`). No pre-existing test was removed, skipped, excluded, tagged away, serialized around, or weakened. No file's `async:` value changed.

**The floors were deliberately NOT re-pinned to 1590/1589.** No green CI run contains these 14 tests, and D-27 permits pinning only from green CI evidence — a local number measured on Elixir 1.19.5 is exactly what the rule forbids. The `>=` comparison absorbs the growth by design, and +14 sits inside the 40-test nudge margin, so the next CI run should show neither a violation nor a nudge. Re-pinning to 1590/1589 from the first green run that contains them would be legitimate and is not required.

Note on comparing count lines across toolchains: ExUnit 1.18 prints its `N tests` inclusive of exclusions while 1.19 prints it exclusive, so the CLI lines are not directly comparable (CI's `1573 tests, 13 excluded` and local's `1574 tests, 7 skipped (13 excluded)` describe different totals). Everything above is reconciled through the unambiguous `total:/excluded:/skipped:/executed:` line, which comes from `after_suite/1` rather than from any summary-line parse.

---

## Deviations from Plan

### 1. [Rule 1 — Bug] The `:test` false positive was fixed, not deferred

Described in full under Task 2. Scope justification: Task 2's own action instructs "confirm the exclusion-tag allowlist against the green run's effective exclusion sets ... if the observed set contains any token beyond the two allowlisted, stop"; `test/support/suite_floor.ex` and `test/scripts/suite_floor_contract_test.exs` are both in the plan's `files_modified`; and the defect is in the very instrument this plan exists to pin. Commit `6820eca6`.

### 2. [Rule 2 — Missing critical functionality] The scope gate on the floor/nudge/ceiling

Pinning real floors would otherwise have introduced a false `[VIOLATION]` on every focused run in the repo. Provably non-weakening (enforcement was already gated on the same variable), and covered by four new negative controls including one proving the gate is not an off switch. Commit `6820eca6`.

### 3. [Rule 2 — Missing critical functionality] The unpinned-schema violation

`Map.get(@executed_floors, schema, 0)` was harmless while every floor was 0 and became a silent vacuity hole the moment they were real. Commit `6820eca6`.

### 4. Task 1's checkpoint was satisfied by two green legs, not four

Recorded under Task 1. The other two are structurally unable to run on a `pull_request` event and the process constraints forbid dispatching. Not a defect introduced here, but a material narrowing of the evidence base that the plan assumed would be wider.

### 5. Task 3's post-change dispatch was not performed

Forbidden by the process constraints. Recorded under Task 3 and in "Still Open".

---

## Known Stubs

None. No placeholder, sentinel, TODO or FIXME remains in `test/support/suite_floor.ex`; every threshold is a measured integer.

## Threat Flags

None. No network surface, auth path, file-access pattern or trust-boundary schema change. The one new trust relationship — "a number read from a CI job log becomes a permanent enforcement threshold" (T-143-33) — is mitigated as the threat register directs: each constant carries its source run ID, job ID and date, and the contract test repeats them as a tripwire.

---

## Still Open

1. **The 1.19 / OTP 28 legs have never run on this branch, and now carry enforcement.** They are `skipped` on every `pull_request` event by design (`advisory-matrix.yml:152`). The floors they will enforce were measured on the 1.18 legs. The `>=` comparison makes the risk one-directional — a 1.19 leg executing at least as many tests passes; one executing fewer reds an **advisory**, non-blocking job visibly rather than passing silently — which is the correct direction for an unmeasured leg, but it is a real possibility on the first push or nightly cron. If it happens, D-16 says re-key the constant on `{schema, elixir_minor}` and record the divergence; it does **not** say lower the 1.18 number. The relevant corroboration (not a pin): local Elixir 1.19.5 reports the same `after_suite` `total` as CI's 1.18.4 for the same tree — 1596 on both, the CLI *formatting* being what differs — so a divergence is not expected.
2. **No post-change `advisory-matrix.yml` dispatch with enforcement live.** Forbidden by this plan's process constraints. The substitutes are the two local enforced full-suite runs above, both exit 0 at the pinned floors, and the `make toolchain` harness is available for a 1.18.4/OTP 27 confirmation should one be wanted before the next push.
3. **`REQUIREMENTS.md` marks HARNESS-02 and HARNESS-03 `[x]`, and at least HARNESS-02's stated bar is not met by available evidence.** HARNESS-02 reads "Core Full Suite passes across all four matrix legs"; two of four have green evidence and two have never executed. HARNESS-03 additionally requires "a deliberate-failure probe following the existing `gate-self-test.yml` pattern pointed at Core Full Suite", which is plan `143-12`'s deliverable, not this one's. **Nothing in `REQUIREMENTS.md` was flipped by this plan, in either direction** — plan `143-14` owns that file — but the discrepancy is recorded here with evidence so it is reconciled deliberately rather than inherited.
4. **The `--only` discount is asserted by unit tests, not by a Credo check or a lane assertion.** A future `--exclude` added to a `--only` alias would be caught, but a future ExUnit that implements `--only` differently would not be. The runtime report is the enforcement.
5. **Prior gap closures' open items are unchanged and none are narrowed here**: no full-clock reproduction of the 120s ownership timeout, `probe/1` remains mode-keyed rather than liveness-keyed, and the formatter's `:module_finished`-only blind spot (`143-MECHANISM.md` §7) is untouched.

---

## Self-Check: PASSED

| Claim | Verification |
|---|---|
| `test/support/suite_floor.ex` modified, no placeholder remains | present; `grep -c PLACEHOLDER` → 0 |
| `test/scripts/suite_floor_contract_test.exs` modified | present; 34 tests, 0 failures |
| `.github/workflows/advisory-matrix.yml` modified | present; `grep -c MAILGLASS_SUITE_FLOOR` → 2; `actionlint` exit 0 |
| `test/scripts/lane_classification_drift_test.exs` modified | present; 26 tests, 0 failures |
| Commit `6820eca6` (Task 2) | in `git log` |
| Commit `93b92ad1` (Task 3) | in `git log` |
| Mutated files restored | `docs_contract_test.exs` sha256 `OK`; `advisory-matrix.yml` restored from backup, count back to 2 |
| `.dialyzer_ignore.exs` untouched | `git diff HEAD` empty |
