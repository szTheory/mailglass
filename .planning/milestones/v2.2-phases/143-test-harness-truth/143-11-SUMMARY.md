---
phase: 143-test-harness-truth
plan: 11
subsystem: ci-lane-truth
tags: [harness-04, d-19, d-20, d-21, d-24, d-25, d-30, d-31, runtime-names, anti-vacuity]
status: complete
requires:
  - "143-10 — the pinned suite floors and the MAILGLASS_SUITE_FLOOR opt-in on both full-suite steps"
  - "141-05/141-06 — the four-bucket registry, drift/2, and MAINTAINING.md's 24-row disposition table"
provides:
  - "Mailglass.CIYaml.expanded_matrix_job_names/1 — RUNTIME job names for advisory-matrix.yml (7)"
  - "Two distinguishable Core Full Suite job names: `core_full_suite` and `core_full_suite_next_toolchain_advisory`"
  - "A third, disjoint registry axis: advisory_matrix_gating_lanes/0 (2) and advisory_matrix_advisory_lanes/0 (5)"
  - "MAINTAINING.md § \"Advisory Matrix Lanes\" — a 7-row table under its own top-level heading"
  - "Eleven drift assertions binding workflow ↔ registry ↔ documentation, each proven non-vacuous by mutation"
affects:
  - "test/support/ci_yaml.ex, test/support/ci_lanes.ex"
  - ".github/workflows/advisory-matrix.yml, MAINTAINING.md"
  - "test/scripts/lane_classification_drift_test.exs, test/mailglass/docs_contract_test.exs"
tech-stack:
  added: []
  patterns:
    - "A parser that cannot compute its answer raises with a recovery instruction rather than returning a plausible-looking under-report"
    - "One assertion per test where a mutation must be able to single it out — ExUnit stops at the first failing assert, so a count check silently masks the disjointness check beside it"
    - "Declared-name and runtime-name spaces held in one module with per-function ownership stated in @doc, because they are two readings of the same YAML lines"
key-files:
  created: []
  modified:
    - test/support/ci_yaml.ex
    - test/support/ci_lanes.ex
    - .github/workflows/advisory-matrix.yml
    - MAINTAINING.md
    - test/scripts/lane_classification_drift_test.exs
    - test/mailglass/docs_contract_test.exs
    - test/support/suite_floor.ex
    - test/scripts/suite_floor_contract_test.exs
    - test/reference_host/trust_runner_checkpoint_contract_test.exs
    - test/mailglass/demo_data_test.exs
decisions:
  - "expanded_matrix_job_names/1 RAISES on the three shapes it cannot expand honestly, rather than returning the bare template. A registry silently seeded with a name that never matches a live job is worse than a failed parse — and the appended-suffix spelling for a statically-named matrix job is an inference from n=2, not something to guess."
  - "The parser also emits non-matrix jobs' declared names (which are their runtime names), so a future non-matrix job added to advisory-matrix.yml surfaces as an unclassified lane in the set-equality diff instead of vanishing from the comparison."
  - "MAINTAINING.md records all seven lanes as classification `advisory` today, with disposition `promote` on the two floor legs — not `publish-gating`. gate-ci-green does not read advisory-matrix.yml yet; claiming the gate before 143-12/143-13 wires it up would be the fifth premature-completion incident of this phase."
  - "The rename lineage (`core_full_suite_advisory`, `core_latest_elixir_advisory`) lives in MAINTAINING.md's reason cells, not in advisory-matrix.yml comments, so the plan's `grep -c ... == 0` acceptance criteria hold literally rather than approximately."
  - "The docs-contract fix landed as a SEPARATE commit from the atomic classification change: Task 2's acceptance criterion demands exactly four files in `git log -1 --name-only`, and the repo squash-merges, so no intermediate commit reaches main on its own."
metrics:
  duration: "~3h"
  completed: "2026-07-30"
  new-tests: 16
  mutations-run: 14
  commits: 3
---

# Phase 143 Plan 11: Runtime job names, an honest rename, and a third registry axis — Summary

**`advisory-matrix.yml`'s two Core Full Suite jobs no longer share a name. `Mailglass.CIYaml.expanded_matrix_job_names/1` reads the seven runtime lane names GitHub actually reports, a third disjoint registry axis records what each one blocks, `MAINTAINING.md` documents them under its own heading, and eleven drift assertions bind all three — every one of them shown to fail by reintroducing the defect it targets.**

Commits: `034ac958` (Task 1), `f1371927` (Task 2, atomic, four files), `9ca88b31` (rename follow-through fix).

---

## Task 1 — the runtime-name parser

`expanded_matrix_job_names/1` copies `matrix_job_names/1`'s reduce-over-lines, indent-anchored shape (this module deliberately takes no YAML dependency), extended with an in-include flag and a row accumulator: a row opens on a 10-space `- key: value` head, absorbs 12-space continuations, and the block closes on the first non-blank non-comment line that is neither. Comments are checked first, because `advisory-matrix.yml`'s include blocks carry several paragraphs of them.

Against the **pre-rename** file it returned exactly seven names, which is what makes Task 2's rename verifiable as a change rather than a coincidence:

```
Core Full Suite Advisory (Elixir 1.18 / OTP 27 / schema public)
Core Full Suite Advisory (Elixir 1.18 / OTP 27 / schema mailglass)
Core Full Suite Advisory (Elixir 1.19 / OTP 28 / schema public)
Core Full Suite Advisory (Elixir 1.19 / OTP 28 / schema mailglass)
Provider Compatibility Advisory (Elixir 1.18 / OTP 27)
Inbound Full Suite Advisory (schema public)
Inbound Full Suite Advisory (schema mailglass)
```

against `job_names/1`'s **4** keys collapsing to **3** distinct declared names. That gap is the vacuity D-24 exists to close: a set-equality test on declared names would have claimed four-leg coverage while proving two.

### It raises rather than guesses

Three shapes cannot be expanded honestly, and each raises an `ArgumentError` naming the job and the recovery:

| Shape | Why raising is the only honest answer |
|---|---|
| `name:` interpolates a matrix axis but no `include:` row was parsed | Either the workflow uses a matrix shape this parser does not read, or the indentation anchors drifted. Returning the template would seed the registry with a string no live job ever reports. |
| Matrix rows present, `name:` interpolates nothing | GitHub then appends a ` (<matrix values>)` suffix whose exact spelling this parser cannot compute. `ci.yml`'s `dialyzer` is exactly this shape. |
| A `${{ matrix.<axis> }}` naming an axis absent from the row | The leg's runtime name is not derivable. |

The moduledoc records the appended-suffix rule honestly: the **two outcomes** (`Dialyzer` suffixed, advisory-matrix jobs not) are verified against live API responses; the **rule connecting them** is an inference from n=2, and the parser refuses to act on an inference it cannot check.

### The moduledoc amendment

The "two name spaces" section stated that *every* function returns declared names. It now names which function belongs to which space, states why the two spaces stay in one module (they are two readings of the same `name:` lines), and records the suffix rule with its confidence marked.

---

## Task 2 — rename, third axis, documentation, drift assertions — one commit

`git log -1 --name-only f1371927` shows exactly the four files the plan requires:

```
.github/workflows/advisory-matrix.yml
MAINTAINING.md
test/scripts/lane_classification_drift_test.exs
test/support/ci_lanes.ex
```

### The rename

The complete set of non-comment lines the workflow diff touches:

```
-  core_full_suite_advisory:
-    name: Core Full Suite Advisory (Elixir ${{ matrix.elixir }} / OTP ${{ matrix.otp }} / schema ${{ matrix.schema }})
+  core_full_suite:
+    name: Core Full Suite (Elixir ${{ matrix.elixir }} / OTP ${{ matrix.otp }} / schema ${{ matrix.schema }})
-  core_latest_elixir_advisory:
-    name: Core Full Suite Advisory (Elixir ${{ matrix.elixir }} / OTP ${{ matrix.otp }} / schema ${{ matrix.schema }})
+  core_full_suite_next_toolchain_advisory:
+    name: Core Full Suite Next Toolchain Advisory (Elixir ${{ matrix.elixir }} / OTP ${{ matrix.otp }} / schema ${{ matrix.schema }})
```

No `run:` line, no `if:` condition, no cache key, and no `concurrency` setting changed. The concurrency block gained a comment only, recording (D-30) that its `github.ref` group shape is load-bearing: keying on the commit SHA would make two concurrent publish self-heal dispatches cancel each other, and both gates would then read a `cancelled` run and block.

`actionlint` exit 0. `scripts/setup_branch_protection.sh` unmodified; `required_checks_test.exs` 6 tests, 0 failures, so the two-entry required-context set is intact.

### The third axis

`@advisory_matrix_gating_lanes` (2) and `@advisory_matrix_advisory_lanes` (5), holding **runtime** names, with a "do not fold" note above them. `all_classified_lanes/0` is untouched, and all six pre-existing hardcoded counts are byte-identical — verified by diff:

| Count | Location | Value |
|---|---|---|
| `ADVISORY_LANES` | `:108` | 3 |
| `PUBLISH_GATING_LANES` | `:125` | 12 |
| `STRUCTURAL_LANES` | `:142` | 2 |
| `REQUIRED_LANES` | `:180` | 7 |
| `ci.yml` jobs / classified / distinct | `:289`, `:294`, `:299` | 24 |
| `MAINTAINING.md` disposition rows | `:492` | 24 |

The advisory bucket's comment records D-20 in full: `Inbound Full Suite Advisory` stays advisory despite being green because it pins `--seed 0` specifically to dodge the known phase-45 property-test pool flake — gating it would be gating on the absence of a bug nobody fixed.

The moduledoc's exclusions section (D-31) had the lane's old name; it now reads `Core Full Suite`.

### `MAINTAINING.md`

A new top-level `## Advisory Matrix Lanes` section with a 7-row table in the same 5-column shape, placed between § "Required Checks" and § "Bus Factor & Continuity". The required-checks table still parses to exactly 24 rows.

Both stale claims are rewritten:

- *"none gates a merge"* — still true, and now stated as only half the story, because two of the seven are the declared publish-gating pair.
- *"All are matrix lanes whose display names carry runtime matrix suffixes"* — **factually wrong** and removed. These jobs interpolate every axis, so nothing is appended. The never-promote note at § "Required Checks" gains the carve-out: the rule applies to *statically-named* matrix jobs (all three of `ci.yml`'s are), and a job that interpolates every axis gets no suffix, which is why exact-equality gating is safe for these.

The section records that gating the two floor legs also gates the inbound `mix deps.get`, the inbound `mix ecto.create`, and `mix verify.schema_prefix` — steps of the same job that the next-toolchain legs do not run.

**What it does not claim.** All seven rows read classification `advisory`, because `gate-ci-green` does not read `advisory-matrix.yml` yet. The two floor legs carry disposition `promote`, which the document already defines as "a recommendation only — it does not mean the lane has been executed into that state." A drift assertion binds disposition to bucket membership, so when 143-13 wires the gate up, the rows and the expectation move together.

---

## Mutation evidence — every guard, by reintroducing its defect

Fourteen mutations. Every mutated file was restored and verified byte-identical by `shasum -a 256 -c`.

### Task 1 guards

| # | Mutation | Guard(s) that fired | Observed |
|---|---|---|---|
| M1 | Deleted one `matrix.include` row (inbound `mailglass` leg) from the real workflow | count == 7; negative-control sanity | `expected exactly 7 runtime lane names ... — got 6` |
| M2 | Stripped every matrix interpolation from `provider_compatibility_advisory`'s `name:` | parser raise (static name over a matrix) | `ArgumentError: ... has 1 matrix include row(s) but its name ("Provider Compatibility Advisory") interpolates no matrix axis ... this parser cannot compute that spelling` |
| M3 | Drifted `@matrix_include_regex` from 8-space to 10-space (a YAML restyle) | parser raise (rows not parsed) | `ArgumentError: job core_full_suite_advisory declares a name that interpolates a matrix axis ... but no strategy.matrix.include: row was parsed ... Fix the parser — do not delete the job from the registry.` |
| M4 | Made the parser emit the raw template instead of substituting | count == 7; no-`${{`-survives; runtime > declared | `got 3: [... ${{ matrix.elixir }} ...]`; `still carries an uninterpolated matrix expression`; `expected ... strictly more RUNTIME names (3) than DECLARED ones (3)` |
| M5 | Emptied `advisory-matrix.yml` | anti-vacuity | `Mailglass.CIYaml.expanded_matrix_job_names/1 parsed no runtime job names ... would then compare an empty set against an empty registry and pass while proving nothing` |

### Task 2 guards

| # | Mutation | Guard(s) that fired | Observed |
|---|---|---|---|
| M6 | Reverted one registry gating lane to its pre-rename display name | YAML↔registry set-equality; MAINTAINING↔registry set-equality; negative control; disposition↔bucket | 4 failures, both drift messages naming the lane in the correct direction |
| M7 | Folded both new buckets into `all_classified_lanes/0` | leak guard + the three 24-count assertions + TRUTH-09 + exactly-one-bucket | **5 failures at once** — the empirical proof of D-24's "do not fold" |
| M8 | Demoted `## Advisory Matrix Lanes` to `### ` | required-checks 24-row count; new-section heading anti-vacuity; both table comparisons | `expected exactly 24 rows ... got 31` — D-25's exact predicted footgun, reproduced |
| M9 | Flipped a gating leg's disposition to `keep-with-reason` | disposition↔bucket binding | names the lane, its bucket, and when the expectation legitimately moves |
| M10 | Added a gating lane to the advisory bucket | *count assertion masked the disjointness check* → **guard split into its own test** (see Deviations) | — |
| M10b | Count-preserving swap putting a gating lane in the advisory bucket | disjointness (now standalone) | `these lanes are in BOTH advisory-matrix buckets: ["Core Full Suite (Elixir 1.18 / OTP 27 / schema public)"]` |
| M11 | Truncated one gating lane name so it prefixes the other | both-directions gating prefix guard + general no-prefix guard | both prefix messages, both directions |
| M12 | Put a declared `${{ }}` template in the registry | template guard | `is a declared name: TEMPLATE, not a runtime name — the registry must hold the strings GitHub reports live` |
| M13 | Renamed a `MAINTAINING.md` display name back to the "Advisory" spelling | docs-contract assert (fired first, masking the refute) | named the missing runtime name |
| M13b | Added the old name back **alongside** the new one | docs-contract **refute** | `Refute with =~ failed / right: "Core Full Suite Advisory ("` — the honesty guard proven non-vacuous on its own |

Restoration checks:

```
.github/workflows/advisory-matrix.yml: OK
test/support/ci_yaml.ex: OK
test/support/ci_lanes.ex: OK
MAINTAINING.md: OK
```

---

## Verification — raw `mix test` / `mix dialyzer` / `mix credo` output only

No SuiteFloor ledger line and no formatter output was used to validate anything here; the SuiteFloor blocks quoted below are context, never evidence. Every full-suite run was preceded by `MIX_ENV=test mix ecto.drop -r Mailglass.TestRepo --quiet && MIX_ENV=test mix ecto.create -r Mailglass.TestRepo --quiet`.

### Local (Elixir 1.19.5 / OTP 28)

| Gate | Command | Result | Exit |
|---|---|---|---|
| public axis | `mix test --seed 783091 --exclude requires_workspace --warnings-as-errors` | 23 properties, **1590 tests, 0 failures**, 7 skipped (13 excluded); `total: 1626, excluded: 13, skipped: 7, executed: 1606` | 0 |
| mailglass axis | `MAILGLASS_SCHEMA=mailglass mix test --seed 374117 --exclude requires_workspace --warnings-as-errors` | 23 properties, **1589 tests, 0 failures**, 7 skipped (14 excluded); `total: 1626, excluded: 14, skipped: 7, executed: 1605` | 0 |
| Dialyzer | `MIX_ENV=test mix dialyzer` | `Total errors: 16, Skipped: 16, Unnecessary Skips: 0` / `done (passed successfully)` | 0 |
| Format | `mix format --check-formatted` | clean | 0 |
| Credo | `mix credo --strict` | `3926 mods/funs, found no issues.` | 0 |
| Scripts lane | `mix test test/scripts/ --warnings-as-errors` | 102 tests, 0 failures | 0 |
| Workflow lint | `actionlint .github/workflows/advisory-matrix.yml` | clean | 0 |

`.dialyzer_ignore.exs` untouched (`git diff HEAD` empty); no entry added, so it stays at its hard cap of 15.

### Gating toolchain (`make toolchain`, Elixir 1.18.4 / OTP 27, 2 vCPU / 4 GB)

Run because the two prior 1.19-green/CI-red incidents make a local-only claim about gating behavior worthless, and because the new parser is new code compiled under `--warnings-as-errors` on a line this branch had not exercised.

| Command | Result | Exit |
|---|---|---|
| `make toolchain CMD='mix test test/scripts/ test/mailglass/docs_contract_test.exs --warnings-as-errors'` | **135 tests, 0 failures**, 1 skipped | 0 |
| `make toolchain CMD='MAILGLASS_SUITE_FLOOR=1 mix test --seed 783091 --exclude requires_workspace --warnings-as-errors'` | 23 properties, **1603 tests, 0 failures**, 13 excluded, 7 skipped; `executed: 1606`; `scope: FULL SUITE ... executed floor 1576, skipped ceiling 7 enforced`; `0 violation(s)` | 0 |
| `make toolchain MAILGLASS_SCHEMA=mailglass CMD='MAILGLASS_SUITE_FLOOR=1 mix test --seed 374117 --exclude requires_workspace --warnings-as-errors'` | 23 properties, **1603 tests, 0 failures**, 14 excluded, 7 skipped; `executed: 1605`; `executed floor 1575, skipped ceiling 7 enforced`; `0 violation(s)` | 0 |

No deprecation warning on 1.18.4 from any new construct — the specific risk that made this run necessary.

### The count lines reconciled across toolchains

ExUnit 1.18 prints its `N tests` **inclusive** of exclusions; 1.19 prints it exclusive. So the CLI lines differ while describing the same tree, and reconcile exactly:

| Axis | 1.19 CLI | 1.18 CLI | Reconciliation | `after_suite` (identical on both) |
|---|---|---|---|---|
| public | `1590 tests ... (13 excluded)` | `1603 tests ... 13 excluded` | 1590 + 13 = 1603 | `total: 1626, excluded: 13, skipped: 7, executed: 1606` |
| mailglass | `1589 tests ... (14 excluded)` | `1603 tests ... 14 excluded` | 1589 + 14 = 1603 | `total: 1626, excluded: 14, skipped: 7, executed: 1605` |

### The delta, accounted for exactly

Executed went **1590 → 1606** (public) and **1589 → 1605** (mailglass): **+16 on both axes**, which is exactly the 16 tests this plan adds — 5 in Task 1, 11 in Task 2 — all in `lane_classification_drift_test.exs`. The scripts lane moved 86 → 102, the same +16. No pre-existing test was removed, skipped, excluded, tagged away, serialized around, or weakened; no file's `async:` value changed.

The floors were **not** re-pinned. D-27 permits pinning only from green CI evidence, and no green CI run contains these tests. `>=` absorbs the growth: 1606 − 1576 = 30 and 1605 − 1575 = 30, both inside the 40-test nudge margin, so the next CI run should show neither a violation nor a nudge — confirmed live by the two enforced toolchain runs above, which printed `0 violation(s)` and exited 0.

---

## Deviations from Plan

### 1. [Rule 1 — Bug] The rename broke `docs_contract_test.exs`, which the scripts lane cannot see

`test/mailglass/docs_contract_test.exs:311` asserted `MAINTAINING.md =~ "Core Full Suite Advisory"`. After the rename that substring is gone — `Core Full Suite Next Toolchain Advisory` does not contain it, and the lineage cells spell the old *job key*, not the display name. The scripts lane stayed green because that test lives outside `test/scripts/`; only the full-suite acceptance run would have caught it.

Fixed in commit `9ca88b31`: the contract now pins the new `## Advisory Matrix Lanes` heading, the gating leg's full runtime name, the next-toolchain canary and the inbound legs, plus a `refute maintaining =~ "Core Full Suite Advisory ("` that keeps the dishonest spelling from creeping back. Both the assert and the refute were mutation-proven (M13 / M13b).

**Why a separate commit rather than amending `f1371927`:** Task 2's acceptance criterion demands exactly four files in `git log -1 --name-only`, and this repo squash-merges, so no intermediate branch commit reaches `main` on its own. Amending would have silently broken a stated criterion to solve a problem the merge strategy already solves.

The same commit updates five stale comment references the rename left behind (`suite_floor.ex` named the old job key while describing today's workflow; four files named the pre-rename lane). The two CI-evidence citations for run `30568802513` keep their historical accuracy — that run genuinely reported the old name — with the rename noted alongside rather than rewritten out.

### 2. [Rule 2 — Missing critical functionality] The parser raises instead of under-reporting

The plan specified expansion; it did not specify what happens when expansion is impossible. Silently returning the bare template for a statically-named matrix job would hand the registry a string no live job reports — a check that cannot observe its subject reporting success. Three raise paths added, two of them mutation-proven (M2, M3).

### 3. [Rule 2] The parser also emits non-matrix jobs' declared names

All four `advisory-matrix.yml` jobs are matrix jobs today, so the count is 7 either way. But scoping the function to matrix jobs only would mean a future non-matrix job added to that workflow vanishes from the set-equality comparison instead of surfacing as an unclassified lane. Documented in the `@doc`.

### 4. Plan prose miscounts the seven names; RESEARCH is right

The plan says "two for each Core Full Suite job and one each for the three remaining advisory-matrix jobs" — but there are two remaining jobs, and the inbound one has two rows. `143-RESEARCH.md` has it correct as `2 + 2 + 1 + 2`. Followed RESEARCH; the total of 7 is what both agree on.

### 5. The disjointness guard was split into its own test

M10 put a lane in both buckets and only the **count** assertion fired — ExUnit stops at the first failing assert, so the disjointness check beside it never ran and could not be shown non-vacuous. Split into a standalone test with a comment recording why, then re-proven with M10b, a count-preserving swap.

### 6. Two negative controls, not one

The plan asked for "a paired negative control for the new set-equality." There are two new set-equalities (workflow↔registry and documentation↔registry), so both got one, each exercising the shared `drift/2` helper rather than a re-implementation.

### 7. `find_required_checks_section/1` generalised rather than duplicated

The new table needed the same heading-bounded parser. Extracted `find_section/2` and `parse_pipe_table/1`; `parse_disposition_table/1`'s behavior is unchanged, proven by the pre-existing 24-row, distinctness, vocabulary, order-independence and negative-control assertions all staying green, and by M8 producing exactly the predicted 31-row failure.

### 8. Rename lineage moved out of the workflow

The plan's acceptance criteria require `grep -c 'core_full_suite_advisory' .github/workflows/advisory-matrix.yml` to be **0**. "Renamed from X" comments would have made it 1. The lineage now lives in `MAINTAINING.md`'s reason cells, where it is more discoverable anyway, and both greps are 0.

---

## Known Stubs

None. No placeholder, TODO, FIXME or sentinel value was introduced. Every lane name is a literal runtime string, every count a measured integer.

## Threat Flags

None. No network surface, auth path, file-access pattern or schema change at a trust boundary. The plan's five registered threats are all mitigated as directed:

| Threat | Disposition |
|---|---|
| T-143-37 (name collision) | Names diverge at index 16; asserted both directions, mutation-proven (M11) |
| T-143-38 (declared-name vacuity) | Runtime parser pinned at 7 with an explicit runtime > declared assertion, mutation-proven (M4) |
| T-143-39 (split commit) | Four files, one commit — `git log -1 --name-only f1371927` |
| T-143-40 (concurrency group) | Unchanged; comment added pinning its shape as load-bearing; diff inspected |
| T-143-41 (branch protection) | `scripts/setup_branch_protection.sh` unmodified; `required_checks_test.exs` 6/0 |

---

## Still Open

1. **No push/dispatch run confirming the runtime names after the rename.** The plan's own verification list and research assumption A5 both want a real run reporting four distinct, fully-interpolated Core Full Suite names matching the registry. Process constraints forbid dispatching workflows and pushing, so this is **not done** and is recorded as open rather than claimed. It is already a sub-item of plan `143-12`'s promotion checkpoint. What stands in its place: the parser computes the names from the workflow source and the drift test binds them to the registry and the documentation, so the only remaining unknown is whether GitHub's live interpolation matches the pre-rename evidence — which it did for the identical template shape on run `30464215272`.
2. **`gate-ci-green` still does not read `advisory-matrix.yml`.** HARNESS-04 stays `[ ]` in `REQUIREMENTS.md`; this plan delivers the registry the gate needs, not the gate. Nothing in `REQUIREMENTS.md` was flipped, in either direction — plan `143-14` owns that file.
3. **`143-10`'s HARNESS-02 / HARNESS-03 discrepancy is inherited unchanged.** HARNESS-02 is marked `[x]` although its stated bar ("all four matrix legs") has evidence for two, and HARNESS-03's deliberate-failure probe is `143-12`'s deliverable. Recorded again here so it is reconciled deliberately by `143-14`, not compounded.
4. **The parser cannot model GitHub's appended-suffix spelling.** If a future `advisory-matrix.yml` job is statically named over a matrix, `expanded_matrix_job_names/1` raises rather than guessing. That is the correct failure direction, but it means adding such a job requires extending the parser, not just the registry. The `@doc` says so.
5. **The `advisory` classification on all seven `MAINTAINING.md` rows is a snapshot, not a resting state.** Two of them move to `publish-gating` / `keep-with-reason` when `143-13` lands, and the disposition↔bucket drift assertion moves with them. A reader who finds `promote` there long after `143-13` shipped is looking at drift.
6. **Prior gap closures' open items are unchanged and none is narrowed here**: no full-clock reproduction of the 120s ownership timeout, `probe/1` remains mode-keyed rather than liveness-keyed, and the formatter's `:module_finished`-only blind spot (`143-MECHANISM.md` §7) is untouched.

---

## Self-Check: PASSED

| Claim | Verification |
|---|---|
| `Mailglass.CIYaml.expanded_matrix_job_names/1` exists with `@doc` + `@spec` | `grep -c 'def expanded_matrix_job_names' test/support/ci_yaml.ex` → 1 |
| Both job keys renamed, old ones absent | `grep -c 'core_full_suite_advisory'` → 0; `grep -c 'core_latest_elixir_advisory'` → 0 |
| New display names present exactly once each | `grep -c 'Core Full Suite (Elixir'` → 1; `grep -c 'Core Full Suite Next Toolchain Advisory (Elixir'` → 1 |
| Third axis added | `grep -Ec 'advisory_matrix_gating_lanes\|advisory_matrix_advisory_lanes' test/support/ci_lanes.ex` → 9 |
| Not folded into `all_classified_lanes/0` | `grep -A6 'def all_classified_lanes' test/support/ci_lanes.ex \| grep -c advisory_matrix` → 0 |
| Six existing counts unchanged | diff inspected; all eight count literals present at `:108 :125 :142 :180 :289 :294 :299 :492` |
| `MAINTAINING.md` has the new heading + 7 rows; required-checks still 24 | drift test 41/0, including both exact-count assertions |
| Branch protection untouched | `git diff --name-only scripts/setup_branch_protection.sh` empty |
| `actionlint` clean | exit 0 |
| Task 2 atomic | `git log -1 --name-only f1371927` → exactly 4 files |
| Commits `034ac958`, `f1371927`, `9ca88b31` | present in `git log` |
| All mutated files restored | `shasum -a 256 -c` → OK for all four |
| `.dialyzer_ignore.exs` untouched | `git diff HEAD` empty |
</content>
</invoke>
