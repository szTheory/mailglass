# Phase 141: Lane Truth Foundation - Research

**Researched:** 2026-07-28
**Domain:** CI/CD lane classification reconciliation + repo-metadata integrity (Elixir library, GitHub Actions)
**Confidence:** HIGH (every claim below verified against the live worktree at `dcbd6488` or the live GitHub API on 2026-07-28)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** `Mailglass.CILanes` (`test/support/ci_lanes.ex`) is the single authoritative registry. The other registries are verified against it by a test that fails on drift — not maintained independently.
- **D-02:** The classification becomes **three named buckets, not two**. Add an explicit publish-gating bucket (recommended name: `@publish_gating_lanes` / `publish_gating_lanes/0`) alongside `required_lanes/0` and `advisory_lanes/0`. Every currently-hidden `ci.yml` job defaults into it, so **today's effective publish posture is preserved byte-for-byte**. **User-confirmed decision** ("Name the third tier").
- **D-03:** This phase **amends TRUTH-09's text in `.planning/REQUIREMENTS.md`** to the three-bucket model.
- **D-04:** Delete the `/ Advisory \(/` convention regex at `publish-hex.yml:269`. `gate-ci-green` enumerates all three sets explicitly instead.
- **D-05:** The written disposition table lives in **`MAINTAINING.md` §"Required Checks"**, rewritten as one table with columns `job id | display name | classification | disposition | reason`. No new `.planning/` register.
- **D-06:** A new meta-test in `test/scripts/` parses `publish-hex.yml`'s JS array literals and `MAINTAINING.md`'s table rows and asserts them against `ci_lanes.ex`, with an anti-vacuity guard. **No new dependency.**
- **D-07:** Every lane carries a disposition of **promote / keep-with-reason / retire**. "Promote" means *recorded as the recommendation* only.
- **D-08:** `credo_strict` **splits into two jobs**: `credo_strict` (name unchanged) and `conformance_gates` (`Design System Conformance (Elixir 1.18 / OTP 27)`).
- **D-09:** Both resulting jobs land in the **publish-gating bucket**. Neither becomes merge-gating in this phase.
- **D-10:** The rename has zero branch-protection blast radius — verified live.
- **D-11:** Exact-string sites that must move atomically: `ci.yml:395`, `ci_lanes.ex:63`, `ci_parity_drift_test.exs:109` and `:187`, the new `gate-ci-green` entry, the `MAINTAINING.md` table row.
- **D-12:** Do **not** add a `mix ci` matcher entry for the new conformance lane. It belongs in the module-doc "intentional exclusions" list.
- **D-13:** Accept the extra-runner wall-clock cost. Note as SEED-006 input; do not optimize here.
- **D-14:** **`CONTRIBUTING.md:116` is corrected** (a fifth registry; all five claimed contexts are wrong).
- **D-15:** **`MAINTAINING.md`'s internal self-contradiction is resolved** (134-142 vs 153-158 vs 180-191).
- **D-16:** **The 132-137 artifact restoration is already complete and byte-exact — budget no restoration work.**
- **D-17:** Apparent gaps in `134` and `136` are not deletion damage. Do not "restore" files that never existed.
- **D-18:** The **only remaining HIST-01 work is writing the defect record** at `.planning/TOOLING-DEFECTS.md`, carrying a recognize-on-re-run symptom line.
- **D-19:** The defect record is a **dated note with mitigations**, not a blanket warning. Prescribe: pass `--archive-version` explicitly, and verify `milestones/<version>-phases/` exists after the run.

### Claude's Discretion

- Exact bucket accessor naming (`publish_gating_lanes/0` vs. an alternative) — the planner may adjust to fit `ci_lanes.ex`'s existing naming style.
- The precise column set and row ordering of the `MAINTAINING.md` disposition table.
- Whether the meta-test is one file or split across two, provided the anti-vacuity guard holds.
- Whether `changes` and `ci_green` (both structural, not check lanes) get their own classification or a documented "structural — not a check lane" marker.

### Deferred Ideas (OUT OF SCOPE)

- Re-pointing `ci_lanes.ex:16`'s citation to `MAINTAINING.md` — offered and **not selected** (but see Finding F8: the phase's own edits break it, so a one-line mechanical correction is now unavoidable).
- `Inbound Full Suite Advisory` (`advisory-matrix.yml:273`) — not selected.
- Promoting Hex Audit / Deps Audit to merge-gating — Phase 142/VULN-03.
- Making `Branch Protection Advisory` actually failable — Phase 144/TRUTH-02.
- Extending `gate-ci-green` to inspect `advisory-matrix.yml` — Phase 143/HARNESS-04.
- Wall-clock cost of the extra conformance runner — SEED-006.
- `2026-06-30-remove-cowlib-advisory-allowlist-when-upstream-fixes.md` — Phase 142/VULN-06.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description (from REQUIREMENTS.md) | Research Support |
|----|-------------|------------------|
| **TRUTH-09** | `REQUIREMENTS.md:98-102` — hidden third gating tier eliminated; every `ci.yml` job explicitly classified. | §Lane Classification Ledger gives all 24 jobs with literal display names; §`gate-ci-green` Rewrite gives the classification logic including a loud `unclassified` branch. D-03 amendment text drafted in §TRUTH-09 Amendment. |
| **TRUTH-07** | `REQUIREMENTS.md:104-106` — three (really five) disagreeing registries reconciled to one authoritative source, others verified against it by a drift test. | §Registry Reconciliation Map; §Meta-Test Design (parsers, anti-vacuity, exact hazards); **F2** (the test must be wired into a lane or it never runs). |
| **TRUTH-05** | `REQUIREMENTS.md:126-128` — every lane carries a recorded disposition. | §Lane Classification Ledger's `disposition` + `reason` columns are literal and ready to paste into `MAINTAINING.md`. |
| **CONFORM-04** | `REQUIREMENTS.md:90-94` — "Credo Strict" renamed to reflect what it runs; lands with TRUTH-07/09. | §The `credo_strict` Split gives the exact step lists for both jobs and proves the split is a safe pure-copy (**F4**). |
| **HIST-01** | `REQUIREMENTS.md:136-139` — v2.0's 132-137 restored; the `phases.clear` defect recorded. | **F7** — both restorations re-verified byte-exact with git; zero restoration work remains. §TOOLING-DEFECTS.md Content gives the record, including **F6** (D-19's primary mitigation is refuted by evidence). |
</phase_requirements>

---

## Summary

Every line citation in CONTEXT.md was re-checked against the live worktree at `dcbd6488`. **All of them are accurate** — a rare and welcome result for a milestone whose failure mode is stale citations. The 23-job `ci.yml` table, the five-registry map, the `gate-ci-green` mechanics at `publish-hex.yml:190-291`, the `ci_lanes.ex` structure, and the four `MAINTAINING.md` contradiction sites are all exactly as CONTEXT.md describes. The planner can treat CONTEXT.md's ground-truth tables as trustworthy.

That said, this research surfaced **eight findings that materially change the plan**, three of which are severe enough that following CONTEXT.md's decisions literally, without them, would ship a broken or ineffective phase. In descending order of severity:

**F1 — GitHub appends matrix values to explicitly-named matrix jobs at runtime.** `Dialyzer` actually reports as `Dialyzer (Elixir 1.18 / OTP 27) (1.18, 27)`. Three lanes are affected. Switching advisory matching from `startsWith` to exact equality — the natural reading of D-04's "enumerate explicitly" — would drop `Operator Browser Gate` and `Preview Capture Advisory` into the blocking tier, so a red browser gate would block a Hex publish. This is precisely the `PITFALLS.md:488-494` failure mode ("a real behavior change smuggled inside a cosmetic rename"), and it is invisible from the YAML alone.

**F2 — No `ci.yml` lane runs `test/scripts/` today.** The existing GATE-03 and MIXCI-03 meta-tests execute only in `advisory-matrix.yml`'s cron-only `Core Full Suite Advisory`, which `gate-ci-green` cannot even see. A new drift meta-test dropped into `test/scripts/` would satisfy success criterion 1 on paper and enforce nothing. The phase must wire the directory into an existing lane.

**F3 — `advisory_lanes/0` is a *parity* list, not a *classification* list.** Re-partitioning it into a third bucket (the literal reading of D-02) breaks `ci_parity_drift_test.exs:198-202` and silently narrows the MIXCI-03 local-parity guarantee for four lanes. The third bucket must be an **orthogonal classification axis** layered on top of the untouched parity lists.

The remaining findings are smaller but concrete: the `conformance_gates` job needs no BEAM at all (F4, making D-13's cost note ~10x pessimistic); `mix test test/scripts/ --warnings-as-errors` aborts today on a pre-existing dead assertion (F5); D-19's primary prescribed mitigation is refuted by the commit evidence (F6); both artifact restorations are confirmed complete and byte-exact (F7); and `ci_lanes.ex:16`'s citation is broken by this phase's own edits (F8).

**Primary recommendation:** Land four commits — two docs-only (green by path filter), one standalone job split (posture-neutral), and one atomic registry+gate+table+meta-test commit. Keep `startsWith` matching with full display names as the prefixes, so the JS arrays are literally equal to the Elixir registry strings and the drift meta-test reduces to four set-equality assertions.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Lane identity + classification (source of truth) | Elixir test-support module (`test/support/ci_lanes.ex`) | — | D-01; already compiled into `:test` via `elixirc_paths(:test)` (`mix.exs:114`), already read at compile time by two meta-tests. |
| Merge gating | GitHub Actions job graph (`ci.yml` `ci_green.needs`) | Branch protection (2 aggregate contexts) | `ci.yml:1133-1138`; branch protection is locked to `CI Green` + `Guard Release Trigger` and is deliberately *not* a leaf registry. |
| Publish gating | `publish-hex.yml` `gate-ci-green` JS | — | Runs against the GitHub REST API job list for a `ci.yml` run; operates on **runtime** job names (see F1), not YAML `name:` fields. |
| Drift enforcement | ExUnit meta-tests (`test/scripts/`) | — | Only tier that can span the YAML/shell/Elixir/Markdown language boundary. Requires a CI lane to execute (F2). |
| Human-readable disposition record | `MAINTAINING.md` §Required Checks | — | D-05; survives milestone archival, readable by outside contributors. |
| Tooling-defect memory | `.planning/TOOLING-DEFECTS.md` | — | D-18; deliberately milestone-independent. |

---

## Verification of CONTEXT.md's Citations

Every citation re-read at `dcbd6488`. **Live repo agrees with CONTEXT.md on all of them.**

| CONTEXT.md citation | Verified? | Notes |
|---|---|---|
| `ci.yml:394` (`credo_strict:` job key) | ✅ exact | Job key at 394, `name:` at 395. |
| `ci.yml:395` (display name) | ✅ exact | `Credo Strict (Elixir 1.18 / OTP 27)`. |
| `ci.yml:1080` (`Branch Protection Advisory`) | ✅ exact | Job key 1079, name 1080. |
| `ci.yml:1108` (`continue-on-error: true`) | ✅ exact | On the `Verify branch protection` step. |
| `ci.yml:1133-1138` (`ci_green.needs`) | ⚠️ off-by-one | `needs:` keyword is at **1133**; the five list items are **1134-1138**. Cosmetic; CONTEXT.md's range is inclusive of the keyword. |
| All 23 job line numbers in CONTEXT.md's table | ✅ exact | Independently re-derived; every `line / job id / display name` triple matches. |
| `publish-hex.yml:204-210` (`REQUIRED_LANES`) | ✅ exact | 5 elements, single-quoted. |
| `publish-hex.yml:220-223` (`ADVISORY_LANES`) | ✅ exact | 2 elements, **short prefixes**, not full names. |
| `publish-hex.yml:267-269` (`isAdvisory`) | ✅ exact | `startsWith` ∥ `/ Advisory \(/`. |
| `publish-hex.yml:273-282` (hidden tier) | ✅ exact | |
| `publish-hex.yml:284-291` (advisory warn) | ✅ exact | |
| `ci_lanes.ex:16` (MAINTAINING.md 152-191 citation) | ✅ exact | See **F8** — broken by this phase's own edits. |
| `ci_lanes.ex:29-46` (intentional exclusions) | ✅ ~exact | Section header at 29; the bullet list actually runs **31-48** (last bullet ends at 45; trailing prose 47-48). |
| `ci_lanes.ex:51-76` (the three attribute lists) | ✅ exact | |
| `ci_lanes.ex:63` (`Credo Strict` entry) | ✅ exact | **But see F9 — this line does not need to change.** |
| `MAINTAINING.md:134-142` (required-before-merge) | ✅ exact | 8 bullets incl. `mix credo --strict`, `mix dialyzer`, `mix docs --warnings-as-errors`. |
| `MAINTAINING.md:153-158` (true required set) | ✅ exact | The 5 correct contexts. |
| `MAINTAINING.md:160-164` (release trust claims) | ✅ exact | The publish-gating intent D-02 cites. |
| `MAINTAINING.md:180-191` (advisory prose) | ✅ exact | 11 short, unparenthesized names. |
| `CONTRIBUTING.md:116` | ✅ exact | Claims `Tests`, `Credo Strict`, `Dialyzer`, `actionlint`, `PR title (semantic)`. Spans **116-119**. All five wrong. |
| `ci_parity_drift_test.exs:109` (matcher key) | ✅ exact | **But see F9.** |
| `ci_parity_drift_test.exs:187` (anti-vacuity MapSet) | ✅ exact | **But see F9.** |
| `required_checks_test.exs:30-34` (anti-vacuity) | ✅ exact | |
| `required_checks_test.exs:45-58` (GATE-01) | ✅ exact | |
| `required_checks_test.exs:96-126` (GATE-03) | ✅ exact | |
| `required_checks_test.exs:159-267` (parsers) | ✅ exact | All five are `defp` — **not reusable from another file**. |
| `mix.exs:364-394` (`ci.fast` / `ci` aliases) | ✅ exact | `ci.fast` 364-369, `ci` 374-394. Neither runs any conformance shell script — **D-12 confirmed**. |
| `scripts/setup_branch_protection.sh:17-20` | ✅ exact | `REQUIRED_CHECKS=("CI Green" "Guard Release Trigger")`. |
| `conformance_advisory_test.exs:66-79` (step-block precedent) | ✅ ~exact | The `advisory_step_block/1` helper is at **77-82**; the test using it is at 66-73. Technique is as described. |
| **D-10** live branch protection | ✅ **re-verified 2026-07-28** | `gh api .../branches/main/protection --jq '.required_status_checks.contexts'` → `["CI Green","Guard Release Trigger"]`. |

**Conclusion: no plan-blocking drift in CONTEXT.md.** Only the two cosmetic range nits above.

---

## Findings That Change The Plan

### F1 — CRITICAL: matrix jobs carry a runtime name suffix; exact-equality advisory matching would break publish

`[VERIFIED: GitHub REST API, repos/szTheory/mailglass/actions/runs/{id}/jobs, 2026-07-28]`

Three `ci.yml` jobs declare a `strategy.matrix` **and** an explicit `name:` that contains no matrix expression:

| Job | `strategy:` line | Matrix |
|---|---|---|
| `dialyzer` | `ci.yml:441-445` | `include: [{elixir: "1.18", otp: "27"}]` |
| `operator_browser_gate` | `ci.yml:701-704` | `include: [{node: "22"}]` |
| `preview_capture_advisory` | `ci.yml:800-803` | `include: [{node: "22"}]` |

GitHub appends the matrix values to the explicit `name:` **when the job actually executes**. Two live runs prove it:

Run `30383484662` (lanes executed):
```
Dialyzer (Elixir 1.18 / OTP 27) (1.18, 27)
Operator Browser Gate (Elixir 1.18 / OTP 27 / Node 22) (22)
Preview Capture Advisory (Elixir 1.18 / OTP 27 / Node 22) (22)
```

Run `30384054278` (docs-only; every lane skipped, matrix never expanded):
```
Dialyzer (Elixir 1.18 / OTP 27)
Operator Browser Gate (Elixir 1.18 / OTP 27 / Node 22)
Preview Capture Advisory (Elixir 1.18 / OTP 27 / Node 22)
```

**The runtime name of a matrix lane is not stable and is never equal to its YAML `name:` when the lane runs.**

Consequences the plan must absorb:

1. **`startsWith` is load-bearing, not legacy cruft.** `ADVISORY_LANES.some(l => jobName.startsWith(l))` at `publish-hex.yml:268` is the only reason `Operator Browser Gate` is treated as advisory today. Switching to `===` makes a red browser gate block Hex publish. **This is the exact `PITFALLS.md:488-494` trap.**
2. **The `/ Advisory \(/` regex also depends on it.** It matches `Preview Capture Advisory (Elixir 1.18 / OTP 27 / Node 22) (22)` via the first ` (`. Deleting it per D-04 requires a replacement that still matches the suffixed form.
3. **The registry and the gate operate in two different name spaces.** `ci_lanes.ex` strings are YAML `name:` values; `gate-ci-green` sees runtime values. For non-matrix lanes they coincide; for the three matrix lanes they do not. This seam has never been documented and must be, or the next maintainer re-introduces the bug.
4. **Latent landmine for Phase 142/143.** `REQUIRED_LANES` uses exact `===` (`publish-hex.yml:253`) and works today only because **none of the five required lanes has a matrix** (verified: no `strategy:` on `compile_no_optional_deps`, `installer_host_smoke`, `support_contract_core`, `support_contract_admin`, `trust_lane_repo_head`). If anyone ever promotes `dialyzer` to required, `gate-ci-green` reports `Dialyzer (Elixir 1.18 / OTP 27) (missing)` and blocks **every** publish. Phase 142 promotes `hex_audit`, which is matrix-free — safe — but this belongs in `MAINTAINING.md` as a written warning.

**Recommendation:** use `startsWith` for advisory **and** publish-gating **and** structural, and keep exact `includes` for required. Populate every array with the **full YAML display name** (so `'Operator Browser Gate (Elixir 1.18 / OTP 27 / Node 22)'`, not `'Operator Browser Gate'`). This is strictly more precise than today, still prefix-matches the ` (22)` suffix, and — critically — makes the JS arrays *string-identical to the Elixir registry*, which reduces the drift meta-test to four trivial set-equality assertions.

The asymmetry (`includes` for required, `startsWith` for the rest) must carry an inline comment explaining F1, or a future "consistency cleanup" reintroduces the bug.

### F2 — CRITICAL: no `ci.yml` lane runs `test/scripts/`; the new meta-test would enforce nothing

`[VERIFIED: grep over .github/workflows/, mix.exs aliases, 2026-07-28]`

`mix.exs` declares no `test_paths`, so `test/scripts/*_test.exs` is part of the default `mix test` run. But **no `ci.yml` job runs a repo-root `mix test`**. Every core lane runs a file- or directory-scoped `verify.*` alias:

| Job | Command | Covers `test/scripts/`? |
|---|---|---|
| `support_contract_core` (`ci.yml:228`) | `mix verify.support_contract.core` → 11 enumerated files (`mix.exs:289-291`) | ❌ |
| `mix_task_tests` (`ci.yml:284`) | `mix verify.mix_tasks` → `test test/mix/tasks/` (`mix.exs:286-288`) | ❌ |
| `installer_golden_gate` (`ci.yml:633`) | `mix verify.installer.golden` → one file | ❌ |
| `inbound_test` (`ci.yml:347,354`) | `mix test` **in `mailglass_inbound/`** | ❌ |
| `support_contract_admin` (`ci.yml:694`) | `cd mailglass_admin && mix verify.support_contract.admin` | ❌ |

The only surface that runs the full core suite is `advisory-matrix.yml:114` (`core_full_suite_advisory`) — advisory, and **structurally invisible to `gate-ci-green`**, which inspects `workflow_id: 'ci.yml'` only (`publish-hex.yml:229`).

**So GATE-03 and MIXCI-03 — the repo's two existing drift meta-tests — have never gated a PR or a publish.** They run in a cron-only advisory lane. Success criterion 1 says the new meta-test "fails the build if any of the three ever drift"; dropping a file into `test/scripts/` does not achieve that.

**Recommendation (in scope — "add a step to an existing job", explicitly pre-authorized by `.planning/research/v2.2/SUMMARY.md:32`):**

1. Add a directory-scoped alias to `mix.exs` (mirroring `verify.mix_tasks`'s anti-drift rationale at `mix.exs:279-285`):
   ```elixir
   "verify.ci_lane_contract": ["test test/scripts/ --warnings-as-errors"]
   ```
   plus `"verify.ci_lane_contract": :test` in `preferred_cli_env` (`mix.exs:63-83`).
2. Add one step to the existing `mix_task_tests` job (after `ci.yml:284`). That job already provisions Postgres (`ci.yml:235-248`), sets `MIX_ENV: test`, and creates the test DB (`ci.yml:271-279`) — which the core `test_helper.exs` requires. **Zero new job, zero new lane, zero new dependency.**

**Why `mix_task_tests` and not `support_contract_core`:** `support_contract_core` is merge-gating (it is in `ci_green.needs`). Adding assertions there would change what blocks a merge, which the phase boundary explicitly forbids ("Phase 141 classifies and records; it does not change what blocks a merge"). `mix_task_tests` is publish-gating, so drift blocks a release but not a PR — consistent with the phase's own posture, and it also promotes the two existing meta-tests from "cron-only advisory" to "publish-gating" as a free bonus.

**Escalation note for the planner:** if the maintainer wants drift to block a *merge*, that is a one-line change (`support_contract_core` instead) but it is a boundary decision, not a planner's call. Recommend recording the choice explicitly in the plan rather than making it by omission.

### F3 — HIGH: `advisory_lanes/0` is a parity list; re-partitioning it breaks `ci_parity_drift_test.exs`

`[VERIFIED: test/support/ci_lanes.ex:59, test/scripts/ci_parity_drift_test.exs:128,176-202]`

`ci_lanes.ex` says so itself. Line 59: `# Hygiene lanes \`mix ci\` reproduces (verbatim ci.yml name:).` The `@doc` at 85-91 says the list is "the advisory lane display names the `mix ci` ∪ `mix ci.browser` **parity claim covers**". The single consumer, `ci_parity_drift_test.exs:128`, uses it purely as a parity input:

```elixir
defp all_lanes, do: Mailglass.CILanes.required_lanes() ++ Mailglass.CILanes.advisory_lanes()
```

The literal reading of D-02 — move `Credo Strict`, `Dialyzer`, `Hex Audit`, `Docs Warnings as Errors` out of `@advisory_lanes_ci` into a new `@publish_gating_lanes` — produces two failures:

1. **Hard test failure.** `ci_parity_drift_test.exs:176-202` builds a hardcoded `matcher_lanes` MapSet (lines 179-196) and asserts `MapSet.difference(matcher_lanes, known) == 0` where `known = all_lanes()`. Removing four lanes from `advisory_lanes/0` makes four matchers "stale" and the assertion fails.
2. **Silent guarantee loss.** More damaging: the MIXCI-03 contract ("green locally means green in CI") would stop covering credo, dialyzer, hex.audit, and docs — even though `mix ci` still runs all four (`mix.exs:368,383,385,387`). The parity claim would narrow with no test noticing. That is the same class of defect this phase exists to eliminate.

**Recommendation:** the third bucket is an **orthogonal classification axis**, not a re-partition of the parity lists.

- Leave `@advisory_lanes_ci` (`:60-71`), `@advisory_lanes_browser` (`:74-76`), `advisory_lanes/0`, `advisory_lanes_ci/0`, `advisory_lanes_browser/0` **byte-unchanged**. They answer "what does `mix ci` reproduce?"
- Add a **new, complete classification axis** answering "what is this lane's gating status?" — see §Recommended `ci_lanes.ex` Shape.
- Update the `@moduledoc` to state the two axes explicitly, so the next reader does not conflate them again. This is the single most valuable prose edit in the phase.

Result: `ci_parity_drift_test.exs` needs **zero changes**, MIXCI-03 is preserved, and D-02's "named third tier alongside `required_lanes/0` and `advisory_lanes/0`" is satisfied literally.

### F4 — the `credo_strict` split is a safe pure-copy, and needs no BEAM at all

`[VERIFIED: ci.yml:394-433; grep over the four shell scripts]`

Current `credo_strict` job (`ci.yml:394-433`), full step list:

| # | Step | Line | Needs BEAM/deps? |
|---|---|---|---|
| 1 | Checkout | 400-401 | — |
| 2 | Set up OTP + Elixir (`setup-beam`) | 402-406 | — |
| 3 | Cache deps (`actions/cache`, path `deps`) | 407-413 | — |
| 4 | Install deps (`mix deps.get`) | 414-415 | — |
| 5 | `bash scripts/check_credo_suppressions.sh` | 416-419 | **No** — awk over `.credo.exs` |
| 6 | `bash scripts/check_motion_conformance.sh` | 420-423 | **No** — grep over `mailglass_admin/lib` + `assets/css/app.css` |
| 7 | `bash mailglass_admin/scripts/check-conformance.sh` | 424-428 | **No** — grep over `mailglass_admin/lib/**/*.ex`, `BASH_SOURCE`-anchored |
| 8 | `bash mailglass_admin/scripts/check-conformance-advisory.sh` | 429-431 | **No** — same |
| 9 | `mix credo --strict` | 432-433 | **Yes** |

Job-level conditions: `runs-on: ubuntu-latest`, `needs: [changes]`, `if: needs.changes.outputs.code == 'true'`. No `services:`, no `env:`, no `strategy:`.

**No inter-step state dependency.** A grep for `mix `, `_build`, `deps/`, `priv/static`, `npm`, `node` across all four scripts returns exactly one hit — `check-conformance.sh:336`, a `grep -vF` exclusion of the literal path `optional_deps/mailglass_inbound.ex`, which is a source file, not a build artifact. Steps 5-8 read only checked-in source. **The split is a safe pure copy.**

**Recommended step lists:**

`credo_strict` — keep `name: Credo Strict (Elixir 1.18 / OTP 27)`, `needs: [changes]`, `if: needs.changes.outputs.code == 'true'`:
1. Checkout · 2. Set up OTP + Elixir · 3. Cache deps · 4. Install deps · 5. `check_credo_suppressions.sh` · 6. `mix credo --strict`

`conformance_gates` — new job, `name: Design System Conformance (Elixir 1.18 / OTP 27)`, `needs: [changes]`, `if: needs.changes.outputs.code == 'true'`:
1. Checkout · 2. `check_motion_conformance.sh` · 3. `check-conformance.sh` · 4. `check-conformance-advisory.sh`

**No `setup-beam`, no cache, no `deps.get`.** The job is checkout + three greps.

**This corrects D-13's cost note.** D-13 budgets "~2-3 min wall-clock for the extra runner (duplicated `setup-beam` / `deps.get` / cache)". The actual cost is a runner acquisition plus a checkout — roughly **20-40 seconds**, fully parallel, adding **nothing** to the critical path. This is not a re-litigation of D-13 (accepting the cost); it is a correction of the number the plan will quote as a SEED-006 input. Quoting 2-3 min would mislead that milestone's prioritization.

**Naming caveat:** `Design System Conformance (Elixir 1.18 / OTP 27)` carries an Elixir/OTP suffix for a job that runs no Elixir. Recommend **`Design System Conformance (shell gates)`** instead — it satisfies ROADMAP criterion 3 ("from the name alone") better and is honest about what the lane does. This falls under the discretion D-08 grants ("recommended display name"). If the planner prefers suffix consistency across the job list, keeping D-08's literal string is acceptable — but note that no other `(Elixir 1.18 / OTP 27)` lane is BEAM-free, so the suffix actively misleads here.

### F5 — `mix test test/scripts/ --warnings-as-errors` aborts today

`[VERIFIED: executed locally against Postgres, 2026-07-28]`

```
$ MIX_ENV=test mix test test/scripts/ --no-start
17 tests, 0 failures

$ MIX_ENV=test mix test test/scripts/ --no-start --warnings-as-errors
17 tests, 0 failures
ERROR! Test suite aborted after successful execution due to warnings while using the --warnings-as-errors option
```

Single warning site — `test/scripts/ci_parity_drift_test.exs:159-161`:

```elixir
lanes = all_lanes()
assert lanes != [],
       "Mailglass.CILanes required + advisory lanes parsed empty — ci_lanes source changed"
```

Elixir 1.18's set-theoretic type inference proves `lanes` is `dynamic(non_empty_list(term(), term()))` — because `all_lanes/0` concatenates two compile-time literal module attributes — and emits a typing violation for a comparison "which is always true".

Two consequences:

1. **Blocker for F2's wiring.** Every other `verify.*` alias in `mix.exs` uses `--warnings-as-errors`. The new `verify.ci_lane_contract` alias cannot follow the convention until this is fixed.
2. **The anti-vacuity guard at `:161` is itself dead.** The compiler proves it can never fail. It is redundant with `:164` (`assert length(Mailglass.CILanes.required_lanes()) == 5`), which *can* fail. A latent dead gate inside the repo's drift-protection machinery is on-theme for this phase and worth fixing rather than suppressing.

**Recommendation:** delete `ci_parity_drift_test.exs:159-162`'s `lanes != []` assertion as redundant (keep the `steps != []` guard at `:156-157`, which is genuinely runtime-derived from `Mix.Project.config()`, and keep the `== 5` assertion at `:164`). A ~4-line edit. Then the alias can carry `--warnings-as-errors`.

**Do not** work around this by dropping `--warnings-as-errors` from the new alias — that silently exempts `test/scripts/` from a convention every other lane honors, which is a small instance of the exact problem this phase fixes.

### F6 — D-19's primary mitigation is refuted by the commit evidence

`[VERIFIED: git log -1 --format=%B 70099869]`

D-19 prescribes two mitigations: "pass `--archive-version` explicitly, and verify `milestones/<version>-phases/` exists after the run."

The commit body of `70099869` says, verbatim:

> `gsd-tools query phases.clear --archive-version v2.1` reported `cleared: 3` but deleted the three phase directories without writing the archive.

**`--archive-version` was passed, and the defect fired anyway.** Recording "pass `--archive-version` explicitly" as *the* mitigation would write down a fix that is already known not to work — inside the document whose entire purpose is stopping a third recurrence.

**Recommendation for `.planning/TOOLING-DEFECTS.md`:**
- Demote `--archive-version` from "mitigation" to "does not prevent this — it was passed on the 2026-07-28 occurrence and the archive was still not written."
- Promote the **post-condition check** to the sole primary mitigation: after any `phases.clear`, run `ls .planning/milestones/<outgoing>-phases/` and compare the file count against `git show --stat HEAD` before committing.
- Keep the symptom line D-18 requires, verbatim from the evidence: **`cleared: N` reported with no `milestones/<version>-phases/` directory written.**

D-19's framing ("dated note with mitigations, not a blanket warning") is preserved — only the ranking of the mitigations changes, and it changes because of evidence in the repo, not opinion.

### F7 — HIST-01: both restorations verified complete and byte-exact; zero restoration work remains

`[VERIFIED: git hash-object comparison against the pre-deletion trees, 2026-07-28]`

**v2.0 phases 132-137** — `b5fed519` ("docs: start milestone v2.1") deleted 48 files under `.planning/phases/13{2..7}-*`. `a629fb82` re-added 48 files under `.planning/milestones/v2.0-phases/`. Per-file `git hash-object` vs `git rev-parse b5fed519^:<path>`:

```
ok=48  missing=0  differ=0
```

**D-16 confirmed exactly.**

**v2.1 phases 138-140** — `70099869` moved 39 files. With rename detection (`git show --name-status -M 70099869`), all 39 are **`R100`** (100% similarity) from `.planning/phases/1{38,39,40}-*` to `.planning/milestones/v2.1-phases/`. The delete and the archive landed in the **same commit**; the by-hand repair described in the commit body was completed before it was written.

```
$ find .planning/milestones/v2.1-phases -type f | wc -l
39
```

**Nothing is missing.** The defect fired twice, and both times a human repair commit restored the artifacts byte-exactly. `.planning/phases/` currently holds only `141-lane-truth-foundation/` and two `999.*` backlog dirs — the expected post-close state.

D-17 also holds: phases 134 and 136 have no `CONTEXT.md`/`DISCUSSION-LOG.md` in the pre-deletion tree either, so there is nothing to restore.

**Plan impact:** HIST-01 is a **single-artifact requirement** — write `.planning/TOOLING-DEFECTS.md`. Budget no file recovery, no git archaeology, no verification sweep beyond re-running the two commands above as evidence. **`.planning/TOOLING-DEFECTS.md` does not exist today** (verified). A grep for `phases.clear` across `.planning/**/*.md` + `CLAUDE.md` returns only `REQUIREMENTS.md:137` and `ROADMAP.md:59` — the requirement itself, not the defect record. D-18's premise is correct.

### F8 — `ci_lanes.ex:16`'s citation is broken by this phase's own edits

`[VERIFIED: test/support/ci_lanes.ex:15-17 vs MAINTAINING.md structure]`

```elixir
# ci_lanes.ex:15-17
All names here are VERBATIM the `name:` fields in `.github/workflows/ci.yml`. The
authoritative required-vs-advisory split lives in `MAINTAINING.md` (lines 152-191);
```

`MAINTAINING.md`'s `## Required Checks` section spans **132-198**. D-05 rewrites 132-191 into a single table. The hardcoded `152-191` range will point at unrelated text.

CONTEXT.md's `<deferred>` block anticipated this ("if the planner finds the range broken by its own edits, fixing it is a one-line mechanical correction — flagged here rather than silently folded in"). It **is** broken by the phase's own edits, so the correction is now unavoidable.

**Recommendation:** replace the line-number citation with a section citation — `` `MAINTAINING.md` § "Required Checks" `` — which cannot go stale. This is strictly smaller than the deferred option (re-pointing the citation target) and is the Pitfall-9 fix the deferred note describes.

### F9 — D-11 over-lists the atomic rename sites; three of the six need no change

`[VERIFIED: D-08 preserves the credo_strict display name]`

D-11 lists six sites that "must move atomically with the split". But D-08 keeps `credo_strict`'s display name **unchanged** (`Credo Strict (Elixir 1.18 / OTP 27)`). Therefore:

| D-11 site | Needs change? | Why |
|---|---|---|
| `ci.yml:395` | ❌ **No** | Display name preserved by D-08. The *new* `conformance_gates` job is an addition, not a rename. |
| `ci_lanes.ex:63` | ❌ **No** | Same string, and F3 keeps the parity list unpartitioned. |
| `ci_parity_drift_test.exs:109` | ❌ **No** | Matcher key is the unchanged display name; matcher body (`"credo --strict"`) still matches `mix.exs:368`. |
| `ci_parity_drift_test.exs:187` | ❌ **No** | Same string still present in `all_lanes()` under F3. |
| new `gate-ci-green` entry | ✅ **Yes** | `Design System Conformance ...` must be added to `PUBLISH_GATING_LANES`. |
| `MAINTAINING.md` table row | ✅ **Yes** | New row for the new lane. |

Plus one D-11 omits: `ci_lanes.ex`'s **intentional-exclusions module doc** (`:31-48`), where D-12 places the new conformance lane.

**Net: the split's blast radius is 3 sites, not 6** — and if F3 is followed, `ci_parity_drift_test.exs` is untouched by the entire phase. This materially simplifies the atomicity story (§Task Ordering).

**Caveat that keeps D-11 honest:** all four "no change" verdicts hold *only because* D-08 preserves the display name and F3 preserves the parity lists. If the planner deviates from either, D-11's full list applies. State that dependency in the plan.

---

## Lane Classification Ledger

The literal, paste-ready classification of all 24 jobs (23 existing + `conformance_gates`). Display names are verbatim `ci.yml` `name:` values, cross-checked against the live API job list from run `30384054278`.

### Required (5) — in `ci_green.needs`, merge-gating and publish-gating. Exact-match safe (no matrix).

| job id | display name | disposition | reason |
|---|---|---|---|
| `compile_no_optional_deps` | `Compile No Optional Deps (Elixir 1.18 / OTP 27)` | keep-with-reason | Optional-deps gateway is a locked engineering-DNA guarantee. |
| `installer_host_smoke` | `Installer Host Smoke` | keep-with-reason | Shift-left consumer-install proof; promoted from advisory. |
| `support_contract_core` | `Support Contract Core (Elixir 1.18 / OTP 27)` | keep-with-reason | Stability/API contract. |
| `support_contract_admin` | `Support Contract Admin (Elixir 1.18 / OTP 27)` | keep-with-reason | Sibling-package release truth. |
| `trust_lane_repo_head` | `Trust Lane Repo Head (Elixir 1.18 / OTP 27)` | keep-with-reason | Repo-head trust journey. |

### Advisory (4) — non-blocking for both merge and publish.

| job id | display name | matching | disposition | reason |
|---|---|---|---|---|
| `deps_audit_advisory` | `Deps Audit Advisory (Elixir 1.18 / OTP 27)` | prefix | **promote** (Phase 142/VULN-03) | Recorded recommendation only; not executed here (D-07). |
| `operator_browser_gate` | `Operator Browser Gate (Elixir 1.18 / OTP 27 / Node 22)` | prefix ⚠️ **matrix** | keep-with-reason | Node/Playwright; zero-Node is an adopter guarantee, so this stays advisory. |
| `demo_browser_evidence` | `Demo Browser Evidence (Docker Compose / Chromium)` | prefix | keep-with-reason | Docker-compose demo evidence; slow, environment-fragile. |
| `preview_capture_advisory` | `Preview Capture Advisory (Elixir 1.18 / OTP 27 / Node 22)` | prefix ⚠️ **matrix** | keep-with-reason | Node/Playwright preview capture. |

### Publish-gating (13) — blocks a Hex publish when red; does **not** block a merge. Preserves today's effective posture byte-for-byte.

| job id | display name | matching | disposition | reason |
|---|---|---|---|---|
| `format_check` | `Format Check (Elixir 1.18 / OTP 27)` | prefix | keep-with-reason | Cheap hygiene; reproduced by `mix ci.fast`. |
| `compile_warnings` | `Compile Warnings as Errors (Elixir 1.18 / OTP 27)` | prefix | keep-with-reason | Reproduced by `mix ci.fast`. |
| `mix_task_tests` | `Mix Task Tests (Elixir 1.18 / OTP 27)` | prefix | keep-with-reason | Generator/CLI surface; directory-scoped anti-drift. |
| `inbound_test` | `Inbound Test (Elixir 1.18 / OTP 27)` | prefix | keep-with-reason | Sibling package on its own version line. |
| `inbound_compile_no_optional_deps` | `Inbound Compile No Optional Deps (Elixir 1.18 / OTP 27)` | prefix | keep-with-reason | Sibling optional-deps gateway. |
| `credo_strict` | `Credo Strict (Elixir 1.18 / OTP 27)` | prefix | keep-with-reason | Custom Credo checks enforce domain rules at lint time. |
| `conformance_gates` | `Design System Conformance (shell gates)` **(new)** | prefix | keep-with-reason | Split from `credo_strict` per CONFORM-04; publish-gating per D-09. |
| `dialyzer` | `Dialyzer (Elixir 1.18 / OTP 27)` | prefix ⚠️ **matrix** | keep-with-reason | Slow; publish-gating is the right cost/benefit. **Never promote to required without reading F1.** |
| `docs_warnings_as_errors` | `Docs Warnings as Errors (Elixir 1.18 / OTP 27)` | prefix | keep-with-reason | HexDocs quality gate; a broken docs build ships to hex.pm. |
| `hex_audit` | `Hex Audit (Elixir 1.18 / OTP 27)` | prefix | **promote** (Phase 142/VULN-03) | Recorded recommendation only (D-07). |
| `installer_golden_gate` | `Installer Golden Gate (Elixir 1.18 / OTP 27)` | prefix | keep-with-reason | Golden-file installer output; no local-parity step. |
| `trust_lane_clean_baseline` | `Trust Lane Clean Baseline (Elixir 1.18 / OTP 27)` | prefix | keep-with-reason | `MAINTAINING.md:160-164` requires it for release trust claims; `required_checks_test.exs:78-94` (D-04) forbids making it required. Publish-gating is the only classification satisfying both. |
| `branch_protection_advisory` | `Branch Protection Advisory` | prefix | keep-with-reason | **Classification goes live when Phase 144/TRUTH-02 makes it failable.** Today its only substantive step is `continue-on-error: true` (`ci.yml:1108`), so the job never fails. Its name says "advisory" but its behavior is publish-gating — the D-04 rationale. |

### Structural (2) — not check lanes. Same blocking behavior as publish-gating (posture preserved).

| job id | display name | disposition | reason |
|---|---|---|---|
| `changes` | `Detect Non-Doc Changes` | keep-with-reason | Path filter; every other lane's `if:` reads `needs.changes.outputs.code`. Not a check. |
| `ci_green` | `CI Green` | keep-with-reason | Aggregator; it **is** one of the two branch-protection contexts. Required at the context level, not as a leaf — must never appear in `REQUIRED_LANES` (that would be a self-referential gate). |

**Totals: 5 + 4 + 13 + 2 = 24** = 23 existing `ci.yml` jobs + 1 new. Every job carries exactly one classification. **Success criterion 2 satisfied by construction.**

---

## Recommended `ci_lanes.ex` Shape

Consistent with the file's existing conventions: private module attributes holding literal lists, one `@doc` + `@spec` + one-line `def` per accessor, rationale in the `@moduledoc`.

**Add** (do not modify `@required_lanes`, `@advisory_lanes_ci`, `@advisory_lanes_browser`, or their accessors — F3):

```elixir
# Lanes that block a Hex publish when red but do NOT block a PR merge.
# gate-ci-green (publish-hex.yml) enumerates these; ci_green.needs does not.
@publish_gating_lanes [ ...13 strings from the ledger... ]

# Structural jobs — not check lanes. Classified so no ci.yml job is unrecorded
# (TRUTH-09); blocking behavior is identical to @publish_gating_lanes.
@structural_lanes [
  "Detect Non-Doc Changes",
  "CI Green"
]

@spec publish_gating_lanes() :: [String.t()]
def publish_gating_lanes, do: @publish_gating_lanes

@spec structural_lanes() :: [String.t()]
def structural_lanes, do: @structural_lanes

@doc """
Every `ci.yml` job display name, across all four classifications. The drift
meta-test asserts this set-equals the job names parsed from ci.yml, so no job
can sit unclassified (TRUTH-09).
"""
@spec all_classified_lanes() :: [String.t()]
def all_classified_lanes,
  do: @required_lanes ++ advisory_lanes_all() ++ @publish_gating_lanes ++ @structural_lanes
```

**`advisory_lanes_all/0` — the one genuinely awkward point.** `advisory_lanes/0` returns the *parity* union (`@advisory_lanes_ci ++ @advisory_lanes_browser`), which is **not** the advisory *classification* set. The classification set is the 4 lanes in the ledger; the parity set is 11. They overlap but neither contains the other:

- In parity, not advisory-classified: `Format Check`, `Compile Warnings as Errors`, `Credo Strict`, `Dialyzer`, `Docs Warnings as Errors`, `Hex Audit`, `Mix Task Tests`, `Inbound Test`, `Inbound Compile No Optional Deps` (9 — all publish-gating).
- Advisory-classified, not in parity: `Demo Browser Evidence`, `Preview Capture Advisory` (2 — the intentional exclusions at `ci_lanes.ex:33-38`).
- In both: `Deps Audit Advisory`, `Operator Browser Gate`.

So add a fourth attribute for the classification axis:

```elixir
# Lanes that block NEITHER a merge NOR a publish. This is the *classification*
# axis. Distinct from @advisory_lanes_ci / @advisory_lanes_browser, which answer
# a different question: "what does `mix ci` reproduce locally?" (MIXCI-03).
# A lane can be locally reproduced AND publish-gating (e.g. Dialyzer).
@advisory_classified_lanes [ ...4 strings from the ledger... ]
```

**The `@moduledoc` must state the two axes explicitly.** Suggested insert after the current line 27, before "## Intentional exclusions":

> ## Two independent axes
>
> This module answers two different questions, and conflating them is the defect
> Phase 141 fixed:
>
> * **Parity** (`advisory_lanes/0`, `advisory_lanes_ci/0`, `advisory_lanes_browser/0`) —
>   "does `mix ci` reproduce this lane locally?" Consumed by `ci_parity_drift_test.exs` (MIXCI-03).
> * **Classification** (`required_lanes/0`, `advisory_classified_lanes/0`, `publish_gating_lanes/0`,
>   `structural_lanes/0`) — "what does this lane block?" Consumed by the drift meta-test
>   and mirrored in `publish-hex.yml`'s `gate-ci-green` and `MAINTAINING.md`.
>
> A lane is routinely in both (`Dialyzer` is locally reproduced *and* publish-gating).
> Do not partition one axis to build the other.

**Naming verdict on D-02's discretion:** `publish_gating_lanes/0` is confirmed — it matches the file's `<adjective>_lanes` convention (`required_lanes`, `advisory_lanes_ci`, `advisory_lanes_browser`) and reads correctly at the call site. No improvement found.

**Structural-job verdict (CONTEXT.md discretion item):** give them their own `@structural_lanes` bucket rather than a marker comment. Reason: the drift meta-test's "every ci.yml job is classified" assertion needs them as *data*, and a comment is not machine-readable. Their `gate-ci-green` treatment is identical to publish-gating, so this costs nothing at runtime and buys a machine-verified criterion 2.

---

## `gate-ci-green` Rewrite Shape

Replaces `publish-hex.yml:212-223` (the `ADVISORY_LANES` block + comment) and `:267-269` (`isAdvisory`), and extends `:271-291`.

```js
// Classification mirrors Mailglass.CILanes (test/support/ci_lanes.ex), which is
// the authoritative registry (TRUTH-07/D-01). The drift meta-test
// test/scripts/lane_classification_drift_test.exs asserts these four arrays
// set-equal the Elixir registry, so editing one without the other fails CI.
//
// MATCHING RULE — DO NOT "SIMPLIFY" TO === :
// GitHub appends matrix values to a matrix job's explicit `name:` at runtime.
// `Dialyzer (Elixir 1.18 / OTP 27)` reports as
// `Dialyzer (Elixir 1.18 / OTP 27) (1.18, 27)`. Same for Operator Browser Gate
// and Preview Capture Advisory (` (22)`). Prefix matching is REQUIRED for any
// array that may contain a matrix lane. REQUIRED_LANES keeps exact equality
// because none of the five required lanes declares a matrix — and a required
// lane must be present, so the stricter test is correct there.

const REQUIRED_LANES       = [ /* 5, verbatim ci.yml name: */ ];
const ADVISORY_LANES       = [ /* 4, FULL display names, not short prefixes */ ];
const PUBLISH_GATING_LANES = [ /* 13 */ ];
const STRUCTURAL_LANES     = [ /* 2 */ ];

const startsWithAny = (name, lanes) => lanes.some(l => name.startsWith(l));

const classify = (name) => {
  if (REQUIRED_LANES.includes(name))               return 'required';
  if (startsWithAny(name, ADVISORY_LANES))         return 'advisory';
  if (startsWithAny(name, PUBLISH_GATING_LANES))   return 'publish-gating';
  if (startsWithAny(name, STRUCTURAL_LANES))       return 'structural';
  return 'unclassified';
};
```

Required-lane check at `:250-265` is **unchanged**.

Blocking / warning branches:

```js
const notGreen = jobs.filter(j => j.conclusion !== 'success' && j.conclusion !== 'skipped');

// Publish-gating + structural red => block (identical to today's fall-through).
const blockingFailures = notGreen.filter(j => {
  const c = classify(j.name);
  return c === 'publish-gating' || c === 'structural';
});

// Unclassified red => block, with a message naming the fix (today: silent fall-through).
const unclassifiedFailures = notGreen.filter(j => classify(j.name) === 'unclassified');

// Unclassified green => WARN only. See posture note below.
const unclassifiedGreen = jobs.filter(
  j => j.conclusion === 'success' && classify(j.name) === 'unclassified'
);

if (unclassifiedGreen.length > 0) {
  core.warning(
    `ci.yml has job(s) with no recorded classification. Add them to ` +
    `Mailglass.CILanes and to this step's arrays (TRUTH-09):\n` +
    unclassifiedGreen.map(j => `  - ${j.name}`).join('\n')
  );
}
// ...blockingFailures + unclassifiedFailures => core.setFailed
// ...advisory red => core.warning (unchanged from :284-291)
```

**Posture note — read before implementing.** D-02 requires today's publish posture "preserved byte-for-byte". Today, an unrecognized lane blocks **only if red**; green-but-unrecognized passes silently. Failing on green-but-unclassified would be *stronger* but is a real posture change and could surprise a release at the worst moment.

**Recommendation:** `gate-ci-green` **warns** on unclassified-and-green and **fails** on unclassified-and-red (exactly today's behavior, plus a diagnostic). The **meta-test** hard-fails on any unclassified job. Rationale: the meta-test runs on the PR that *adds* the lane — the correct place and time to catch it — while the gate runs at release time, where a hard failure on a green lane is a foot-gun. This satisfies criterion 2's "no job can silently sit in neither" (the meta-test makes it impossible to land one) without altering release behavior. **The plan must state this split explicitly** — per CONTEXT.md `<specifics>`, this choice must never be made by omission.

**Safety confirmation for the D-04 deletion.** Removing `/ Advisory \(/` is safe **only if** both regex-dependent lanes are enumerated with full names:
- `Deps Audit Advisory (Elixir 1.18 / OTP 27)` → `ADVISORY_LANES` (no matrix; prefix or exact both work)
- `Preview Capture Advisory (Elixir 1.18 / OTP 27 / Node 22)` → `ADVISORY_LANES` (**matrix — prefix required**)

Omitting either silently promotes an advisory lane to publish-blocking. `Branch Protection Advisory` correctly moves to `PUBLISH_GATING_LANES`, which is the entire point of D-04.

**Prefix-collision audit (all 24 names, full display names as prefixes):** no name in any array is a prefix of any other. The nearest miss is `Compile No Optional Deps (Elixir 1.18 / OTP 27)` vs `Inbound Compile No Optional Deps (Elixir 1.18 / OTP 27)` — the latter does not *start with* the former, so `startsWith` is unambiguous. Using full display names (rather than today's short `'Operator Browser Gate'`) is what makes this safe; short prefixes would risk collisions as lanes are added. The meta-test should assert non-collision as a standing guard.

---

## Meta-Test Design

### Where it runs

Per **F2**: new file in `test/scripts/`, executed via a new `verify.ci_lane_contract` alias wired into the existing `mix_task_tests` job. Depends on **F5**'s warning fix if `--warnings-as-errors` is used.

### Existing conventions to follow

From `required_checks_test.exs` and `conformance_advisory_test.exs`:

| Convention | Value |
|---|---|
| Module header | `use ExUnit.Case, async: true` — **no `@moduletag`, no tags at all** in any `test/scripts/` file |
| File location | `Path.expand("../../<path>", __DIR__)` (`required_checks_test.exs:4-5`) or `@repo_root Path.expand("../..", __DIR__)` + `Path.join/2` (`conformance_advisory_test.exs:4-6`). **Never `File.cwd!`.** Prefer the `@repo_root` form — it is the newer of the two and reads better with 4+ paths. |
| Registry access | Compile-time module attribute: `@x MapSet.new(Mailglass.CILanes.required_lanes())` (`required_checks_test.exs:19`). Safe because `test/support` is in `elixirc_paths(:test)` (`mix.exs:114`). |
| Anti-vacuity idiom | `assert MapSet.size(set) > 0, "parsed no <thing> — parser or <file> format changed"` (`required_checks_test.exs:30-34`, `:102-107`) |
| Drift idiom | Two `MapSet.difference/2` calls + one combined assert naming both directions (`required_checks_test.exs:36-42`) |
| Section comments | `# ---- \n # Parsers \n # ----` banner (`required_checks_test.exs:155-157`) |

### Parser reuse — the one real friction point

**All five parsers in `required_checks_test.exs:159-267` are `defp`.** They cannot be called from another module. The new test needs `parse_ci_job_names/1` (to enumerate every `ci.yml` job for the "nothing unclassified" assertion).

**Recommendation:** create `test/support/ci_yaml.ex` (`Mailglass.CIYaml`) exposing `job_names/1`, and have **only the new test** use it. **Do not refactor `required_checks_test.exs` to delegate.** Rationale: GATE-03 is the gate this phase's correctness depends on; refactoring it mid-phase risks the exact collateral damage the milestone exists to prevent. The cost is ~20 duplicated lines — cheap, and worth recording in the plan as accepted debt with a follow-up seed.

`test/support/` is already compiled in `:test` (`mix.exs:114`) and already hosts `ci_lanes.ex`, so this adds no wiring.

### Parsing `publish-hex.yml`'s JS arrays

The arrays live inside a YAML block scalar (`script: |` at `publish-hex.yml:193`) at 12-space indentation. Text-level parsing, never YAML parsing.

```elixir
defp parse_js_array(source, name) do
  case String.split(source, "const #{name} = [", parts: 2) do
    [_, rest] ->
      [chunk | _] = String.split(rest, "];", parts: 2)
      ~r/'([^']*)'/ |> Regex.scan(chunk) |> Enum.map(fn [_, s] -> s end) |> MapSet.new()
    _ -> MapSet.new()
  end
end
```

**Hazards, all checked against the live file:**

| Hazard | Status | Handling |
|---|---|---|
| The name `REQUIRED_LANES` appears in prose comments (`:198`, `:201`) and in code (`:252`, `:276`) | ⚠️ real | Split on the full `"const REQUIRED_LANES = ["` token, which occurs exactly once. **Verified unique** for all four names. |
| Quote style | single (`'`) throughout | Regex uses `'`. If the planner switches to `"`, the parser must too — assert the array is non-empty to catch it. |
| Apostrophes inside lane names | none exist | Names contain `/`, `(`, `)`, `.`, digits, spaces only. Guard: assert no parsed name contains `'`. |
| YAML block-scalar indentation | 12 spaces, uniform | Irrelevant — regex is indentation-agnostic. |
| Multi-line array literals | yes, one entry per line | Handled — `];` terminator, not newline. |
| Escaped quotes | none | — |
| Trailing `];` vs `]` | file uses `];` | Splitting on `];` is correct. Guard: if `String.split` yields 1 part, return empty set → anti-vacuity assert fires. |

**Anti-vacuity:** assert `MapSet.size/1 > 0` on all four arrays with the `required_checks_test.exs:30-34` message shape.

### Parsing `MAINTAINING.md`'s table

D-05's table: `| job id | display name | classification | disposition | reason |`.

```elixir
defp parse_disposition_table(md) do
  md
  |> String.split("\n## ")                       # bound the section
  |> Enum.find(&String.starts_with?(&1, "Required Checks"))
  |> String.split("\n")
  |> Enum.filter(&String.starts_with?(String.trim(&1), "|"))
  |> Enum.reject(&String.contains?(&1, "---"))   # separator row
  |> Enum.map(&String.split(&1, "|"))
  |> Enum.reject(&(length(&1) != 7))             # leading "" + 5 cells + trailing ""
  |> Enum.map(fn [_, id, name, cls, disp, reason, _] ->
       {trim_bt(id), trim_bt(name), trim_bt(cls), trim_bt(disp), String.trim(reason)}
     end)
  |> Enum.reject(fn {id, _, _, _, _} -> id == "job id" end)  # header row
end

defp trim_bt(s), do: s |> String.trim() |> String.trim("`")
```

**Hazards:**

| Hazard | Handling |
|---|---|
| A `\|` inside the free-text `reason` column | The `length != 7` reject would silently drop that row → **vacuity risk**. Mitigate with a positive assertion: `assert length(rows) == 24`. A dropped row then fails loudly. Also assert no `\|` appears in any display name. |
| Backticks around names | `MAINTAINING.md` wraps every check name in backticks today (`:154-158`, `:181-191`). Keep that style and strip in the parser (`trim_bt/1`). |
| The header row | Rejected by `id == "job id"`; also caught by the separator filter if the planner uses `|---|`. |
| Section boundary | `String.split("\n## ")` bounds it. Fragile if a `###` subsection is added — assert the found chunk is non-nil and the row count is exact. |
| `MAINTAINING.md` has other tables | None inside `## Required Checks` today (verified: lines 132-198 are prose + bullets only). The section bound plus the exact-count assert covers it. |

### Assertions the new test should carry

1. **Registry ↔ `publish-hex.yml`** — 4 set-equalities (required / advisory / publish-gating / structural). Trivial because F1's recommendation makes the arrays string-identical to the registry.
2. **Registry ↔ `MAINTAINING.md`** — the table's `(display name, classification)` pairs set-equal the registry's four buckets.
3. **Registry ↔ `ci.yml`** *(criterion 2, the load-bearing one)* — `MapSet.new(CIYaml.job_names(ci) |> Map.values())` set-equals `CILanes.all_classified_lanes()`. **This is what makes it impossible to land an unclassified job.** Both difference directions must be reported.
4. **Disposition completeness** (TRUTH-05) — every table row's disposition ∈ `~w(promote keep-with-reason retire)`.
5. **Matrix-lane prefix safety** *(novel, guards F1)* — for every job with a `strategy:` block in `ci.yml`, assert its display name is matched by a **prefix** rule, never by `REQUIRED_LANES`'s exact-equality array. This makes F1 machine-enforced rather than a comment someone deletes.
6. **Prefix non-collision** — no name in any array is a `String.starts_with?` prefix of another.
7. **Anti-vacuity** — non-empty guards on all four JS arrays, the markdown table, and the `ci.yml` job map; plus the exact `== 24` row count.

**One file or two?** Recommend **one** file, `test/scripts/lane_classification_drift_test.exs`. All seven assertions share the same three parsed inputs; splitting would duplicate parsing or force a shared helper for no benefit. Assertion 5 is the only one needing a second `ci.yml` parser (`strategy:` detection), which belongs in `Mailglass.CIYaml` alongside `job_names/1`.

---

## Task Ordering and Atomicity

**Does the meta-test pass against the OLD state?** **No.** Against `dcbd6488` it fails on all of assertions 1, 2, and 3 — the registry has no publish-gating bucket, `publish-hex.yml` has a 2-element short-prefix advisory array and no publish-gating array, and `MAINTAINING.md` has prose bullets rather than a table. It **cannot land first** as a red gate. It must land in the same commit as the three registries it verifies.

**Recommended sequence — four commits, `main` green after each:**

**T1 — docs-only, zero code risk.** `.planning/TOOLING-DEFECTS.md` (new) + `.planning/REQUIREMENTS.md` TRUTH-09 amendment (D-03). Both paths are under `.planning/`, so `changes.outputs.code` evaluates `false` (`ci.yml:43,57`) and every code lane skips. Closes **HIST-01** entirely and **TRUTH-09**'s requirement-text half.

**T2 — docs-only.** `CONTRIBUTING.md:116-119` correction (D-14). Also `.planning/`-adjacent in risk terms: `CONTRIBUTING.md` is not under `.planning/` or `prompts/`, so `code == true` and the full matrix runs — but the change is prose-only and touches no gate. Green.

> ⚠️ **Release-train note.** `CONTRIBUTING.md` is a repo-root file. Per `CLAUDE.md`, the 1.6.2 accidental release train was triggered by root-path commits claiming all paths in `release-please-config.json`. T1/T2 should use the `docs:` conventional-commit type (non-releasing) — **not** `feat:` or `fix:`. Worth an explicit line in the plan; this milestone is repo-artifact-only with no release intended.

**T3 — the `credo_strict` split, standalone.** `ci.yml` only: split into `credo_strict` + `conformance_gates` per F4, plus the `ci_lanes.ex` intentional-exclusions moduledoc entry (D-12, comment-only).

*Why this is safe alone:* the new `conformance_gates` job is unclassified, so it falls through `gate-ci-green` into the hidden tier — **exactly where it already effectively was** as part of `credo_strict`. `ci_green.needs` is untouched, so GATE-03 (`required_checks_test.exs:96-126`) still passes. The display name of `credo_strict` is unchanged, so `ci_parity_drift_test.exs:109/:187` still pass (**F9**). Posture is identical before and after. Green.

**T4 — the atomic commit.** All of:
- `test/support/ci_lanes.ex` — 3 new attributes + 4 new accessors + `@moduledoc` two-axes section + `:16` citation fix (**F8**)
- `.github/workflows/publish-hex.yml` — `gate-ci-green` rewrite (4 arrays, `classify/1`, branches)
- `MAINTAINING.md` — §"Required Checks" rewritten as the 24-row disposition table; resolves the 134-142 ↔ 153-158 ↔ 180-191 contradiction (D-15)
- `test/support/ci_yaml.ex` — new parser module
- `test/scripts/lane_classification_drift_test.exs` — new meta-test
- `test/scripts/ci_parity_drift_test.exs` — delete the dead `lanes != []` assertion (**F5**)
- `mix.exs` — `verify.ci_lane_contract` alias + `preferred_cli_env` entry
- `.github/workflows/ci.yml` — one step added to `mix_task_tests` (**F2**)

These **cannot** be split: the meta-test asserts three-way agreement, so any proper subset leaves it red. This is the phase's single large commit and the plan should say so plainly rather than pretending it decomposes.

**T3 before T4 (not merged into it)** because T3 is independently verifiable and posture-neutral; folding it into T4 makes an already-large atomic commit larger and mixes "does the split work?" with "does the registry agree?" If the planner prefers three commits, merging T3 into T4 is acceptable — merging T4 into anything is not.

**Never leaves `main` red:** T1/T2 skip or no-op the code matrix; T3 preserves classification behavior exactly; T4 is internally consistent by construction.

---

## Common Pitfalls

### Pitfall 1: "Cleaning up" the `includes` / `startsWith` asymmetry
**What goes wrong:** a future reader sees `REQUIRED_LANES.includes(name)` next to `startsWith` and unifies them. If they unify on `===`, three matrix lanes silently become publish-blocking. If they unify on `startsWith` for required, a lane named as a prefix of another could satisfy the required check spuriously.
**Why it happens:** the asymmetry looks like sloppiness; F1's cause is invisible in the YAML.
**How to avoid:** the inline comment block in the rewrite, **plus** meta-test assertion 5 (machine-enforced). A comment alone is not enough — this repo's whole thesis is that unverified prose drifts.
**Warning signs:** a diff touching `publish-hex.yml` that deletes the word "matrix" from a comment.

### Pitfall 2: Landing the meta-test without wiring it to a lane
**What goes wrong:** criterion 1 reads as satisfied; the test never runs on a PR or a publish; the registries drift again and nobody learns until the next release incident.
**Why it happens:** `test/scripts/` *looks* like it is covered — it is in the default `mix test` path, and `mix ci` does run it locally. The gap is CI-only and invisible without auditing `verify.*` alias contents.
**How to avoid:** F2's alias + `ci.yml` step. Verify with the `gh` check in §Validation Architecture, not by reading the YAML.
**Warning signs:** the phase's own verification only ever runs `mix test` locally.

### Pitfall 3: Partitioning the parity list to build the classification list
**What goes wrong:** `ci_parity_drift_test.exs` fails (loud, fine) — or, if someone "fixes" it by trimming `matcher_lanes` at `:179-196`, MIXCI-03's coverage silently narrows (quiet, bad).
**Why it happens:** `advisory_lanes/0`'s name suggests classification; only the comment at `:59` and the `@doc` at `:85-91` reveal it is parity.
**How to avoid:** F3's orthogonal axis + the two-axes `@moduledoc` section.
**Warning signs:** a diff that removes strings from `@advisory_lanes_ci`.

### Pitfall 4: Recording `--archive-version` as the `phases.clear` fix
**What goes wrong:** the defect record prescribes a mitigation the evidence already disproves (**F6**), and the third occurrence lands anyway.
**How to avoid:** post-condition verification as the primary mitigation; `--archive-version` demoted to "necessary but insufficient — was passed on 2026-07-28 and did not prevent it."
**Warning signs:** a TOOLING-DEFECTS.md entry with no "how you recognize it on screen" line.

### Pitfall 5: Budgeting artifact-restoration work
**What goes wrong:** the plan allocates tasks to "restore 132-137", the executor re-derives files from a stale blob, and **overwrites good artifacts** — turning a closed defect into a live one.
**How to avoid:** **F7** — both restorations are byte-exact. HIST-01 is one new file. D-16 is correct and the plan must honor it.

### Pitfall 6: Quoting D-13's 2-3 minute cost
**What goes wrong:** SEED-006 inherits a ~10x-inflated number for a job that is checkout + three greps (**F4**), and mis-prioritizes runner-cost work.
**How to avoid:** record the corrected estimate (20-40s, off the critical path) with the reason (no `setup-beam`, no `deps.get`).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---|---|---|---|
| Parsing `ci.yml` job keys → `name:` | A new YAML dependency | The `required_checks_test.exs:220-242` regex technique, lifted into `test/support/ci_yaml.ex` | `.planning/research/v2.2/SUMMARY.md:32` locks "no new dependency". The technique is proven in-repo and the anti-vacuity guards make it fail-loud. |
| Extracting a JS array from a YAML block scalar | A JS/YAML parser | `String.split/3` on the unique `const NAME = [` token + `Regex.scan(~r/'([^']*)'/)` | Same technique as `parse_required_checks/1` (`:159-166`) for shell arrays. |
| Asserting on a `ci.yml` step block | Line-number slicing | `conformance_advisory_test.exs:77-82`'s `advisory_step_block/1` marker-split | Line numbers are the failure mode this whole milestone is about. |
| Determining a lane's runtime job name | Reading `name:` from YAML | `gh api repos/.../actions/runs/{id}/jobs` | **F1.** The YAML `name:` is not the runtime name for matrix jobs. |
| A separate `.planning/` disposition register | A new register file | `MAINTAINING.md` §Required Checks (D-05) | Milestone-scoped registers do not survive archival; `ci_lanes.ex:16` already cites `MAINTAINING.md`. |

**Key insight:** every parsing problem in this phase already has a proven in-repo precedent within 300 lines of the new test file. The phase's risk is not parsing — it is the two name spaces (F1) and the two axes (F3).

---

## Validation Architecture

### Test Framework

| Property | Value |
|---|---|
| Framework | ExUnit (Elixir 1.18 / OTP 27, `.tool-versions`) |
| Config file | `test/test_helper.exs` (boots `Mailglass.TestRepo`, runs migrations — **requires Postgres**) |
| `test_paths` | not set → defaults to `["test"]`; `test/scripts/` **is** in the default run |
| `elixirc_paths(:test)` | `["lib", "credo_checks", "test/support", "dev"]` (`mix.exs:114`) |
| Quick run | `MIX_ENV=test mix test test/scripts/ --no-start` (17 tests, 0 failures at `dcbd6488`) |
| Full suite | `mix ci` (needs Postgres + network) |
| **CI execution of `test/scripts/`** | **none today (F2)** → after this phase: `mix verify.ci_lane_contract` inside `mix_task_tests` |

### Success Criteria → Concrete Checks

| # | Criterion | Runnable check | Runs where |
|---|---|---|---|
| 1 | The three registries agree; a meta-test fails on drift | `mix test test/scripts/lane_classification_drift_test.exs --warnings-as-errors` | **CI** (`mix_task_tests` via `verify.ci_lane_contract`) + local `mix ci` |
| 1b | The meta-test genuinely fails on drift (negative control) | Temporarily delete one entry from `publish-hex.yml`'s `PUBLISH_GATING_LANES`; assert the test fails; revert. Model on `ci_parity_drift_test.exs:205-221`. | **Human, once** during execution — record the observed failure message in the SUMMARY |
| 2 | No `ci.yml` job sits unclassified | Meta-test assertion 3 (set-equality of `CIYaml.job_names/1` values vs `CILanes.all_classified_lanes/0`) | **CI** |
| 2b | The classification set matches *runtime* reality, not just YAML | `gh api repos/szTheory/mailglass/actions/runs/<run>/jobs --jq '.jobs[].name'` on a run where lanes executed; every name prefix-matches exactly one array | **Human, once** — this is the only check that catches F1-class errors, because matrix suffixes do not exist in the YAML |
| 3 | Two distinguishable job names | `grep -n 'name: Credo Strict\|name: Design System Conformance' .github/workflows/ci.yml` → 2 hits; and confirm the two jobs' step lists are disjoint | **CI** (actionlint validates the YAML) + human read |
| 4 | Every lane has a written disposition | Meta-test assertion 4 (`disposition ∈ {promote, keep-with-reason, retire}`) + assertion `length(rows) == 24` | **CI** |
| 5 | 132-137 restored; defect recorded | `find .planning/milestones/v2.0-phases -type f \| wc -l` → `48`; `test -f .planning/TOOLING-DEFECTS.md`; `grep -c 'cleared:' .planning/TOOLING-DEFECTS.md` ≥ 1 | **Human, once** (already true for the first two — see F7) |

### Sampling Rate

- **Per task commit:** `MIX_ENV=test mix test test/scripts/ --warnings-as-errors`
- **Per wave merge:** `mix ci.fast` (T3/T4 touch `mix.exs`, so compile + credo must stay green)
- **Phase gate:** full `mix ci` green, plus criteria 1b / 2b executed once by a human and recorded

### Wave 0 Gaps

- [ ] `test/support/ci_yaml.ex` — `job_names/1` + `matrix_job_names/1` (covers assertions 3, 5)
- [ ] `test/scripts/lane_classification_drift_test.exs` — the 7 assertions (covers TRUTH-07/09/05)
- [ ] `mix.exs` — `verify.ci_lane_contract` alias + `preferred_cli_env` entry
- [ ] `.github/workflows/ci.yml` — `mix_task_tests` step (**without this, criterion 1 is unenforced**)
- [ ] `test/scripts/ci_parity_drift_test.exs:159-162` — remove the dead assertion (**F5**; unblocks `--warnings-as-errors`)

No framework install needed. No new dependency.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|---|---|---|---|---|
| Elixir / OTP | all Elixir work | ✓ | 1.18 / 27 (`.tool-versions`) | — |
| PostgreSQL | `test_helper.exs` boots `Mailglass.TestRepo` | ✓ | `localhost:5432` accepting connections | — |
| `gh` CLI (authenticated) | criteria 1b / 2b, D-10 re-verification | ✓ | verified against `repos/szTheory/mailglass` | Read `ci.yml` `name:` fields — **inadequate for F1**; matrix suffixes are invisible in YAML |
| `git` | F7 verification | ✓ | — | — |
| Node / Docker | not needed by this phase | n/a | — | — |

**Missing dependencies with no fallback:** none.

---

## Package Legitimacy Audit

**Not applicable — this phase installs no external packages.** `.planning/research/v2.2/SUMMARY.md:32` locks "No new dependency, tool, or GitHub Action is needed anywhere in this milestone", and every change here is a registry edit, a job split, a docs rewrite, or a test using in-repo parsing techniques. Any recommendation introducing a package should be treated as a red flag against that lock.

No new third-party GitHub Actions are introduced either; `conformance_gates` reuses `actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0` (v7.0.0), already SHA-pinned in `ci.yml` per `CLAUDE.md`'s pinning rule.

---

## Project Constraints (from CLAUDE.md)

| Directive | Impact on this phase |
|---|---|
| Conventional Commits enforced; `docs(state):` for STATE.md | T1/T2 must use `docs:` (non-releasing) — see the release-train note in §Task Ordering. |
| All third-party GitHub Actions pinned to commit SHA | `conformance_gates` copies the already-pinned `actions/checkout` SHA verbatim. |
| No Node toolchain anywhere (adopter guarantee) | `conformance_gates` is bash-only. Confirms `Operator Browser Gate` / `Preview Capture Advisory` stay advisory. |
| Errors are specific and composed; brand voice | `gate-ci-green`'s new `unclassified` message and the meta-test's failure messages must name the file and the fix ("Add them to `Mailglass.CILanes` and to this step's arrays"), not just report a mismatch. Existing precedent: `publish-hex.yml:263` "Delivery blocked: required CI lane(s) did not pass…". |
| Don't pattern-match errors by message string | N/A (no runtime error handling here). |
| `.planning/` tracked in git; commit but don't push without confirmation | Per the user's stored memory. T1/T2 are `.planning/` commits. |
| Decision Policy — research first, decide, escalate rarely | F1/F2/F3 were decided here with evidence rather than escalated. The one genuine escalation candidate is F2's merge-gating-vs-publish-gating choice for the meta-test; recommended default given, flagged for explicit recording. |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|---|---|---|
| A1 | GitHub appends matrix values only when the matrix expands (skipped matrix jobs show the bare `name:`) | F1 | Low. Both behaviors were observed on live runs; the recommendation (prefix matching) is correct under either. |
| A2 | `mix_task_tests` remains publish-gating after this phase, so drift blocks a release but not a merge | F2 | Low — it is classified publish-gating in the ledger. If Phase 142/143 promotes it, drift becomes merge-gating, which is a strengthening, not a break. |
| A3 | `MAINTAINING.md`'s `## Required Checks` section contains no other markdown table after the rewrite | Meta-Test Design | Low. Mitigated by the exact `length(rows) == 24` assertion, which fails loudly if extra rows are parsed. |
| A4 | `Design System Conformance (shell gates)` is acceptable in place of D-08's `Design System Conformance (Elixir 1.18 / OTP 27)` | F4 | Low. D-08 says "recommended display name"; either satisfies criterion 3. Planner should pick one explicitly and record it — the string must be identical across `ci.yml`, `ci_lanes.ex`, `publish-hex.yml`, and `MAINTAINING.md`. |
| A5 | Deleting `ci_parity_drift_test.exs:159-162` does not lose meaningful coverage | F5 | Low. The compiler proves the assertion always true; `:164`'s `== 5` retains the real guard. |

---

## Open Questions

1. **Should the drift meta-test block a merge or only a publish?**
   - What we know: `mix_task_tests` (publish-gating) and `support_contract_core` (merge-gating) are both one-line wiring targets. The phase boundary forbids changing what blocks a merge.
   - What's unclear: whether "fails the build" in criterion 1 means the PR build or the release build.
   - Recommendation: wire to `mix_task_tests` (publish-gating) as the in-scope default; state the choice and its consequence explicitly in the plan so it is not made by omission. Escalate to the maintainer only if they want merge-gating, which is a boundary change.

2. **Does `gate-ci-green` fail or warn on unclassified-but-green lanes?**
   - What we know: today it passes silently. Failing is stronger; warning preserves posture byte-for-byte per D-02.
   - Recommendation: warn in the gate, hard-fail in the meta-test. Documented in §`gate-ci-green` Rewrite Shape. **Must be stated explicitly** per CONTEXT.md `<specifics>`.

3. **`Design System Conformance (shell gates)` vs `(Elixir 1.18 / OTP 27)`?**
   - Recommendation: `(shell gates)` — the job runs no Elixir (F4), and criterion 3 asks for a name that tells a maintainer what failed. Planner's call under D-08's discretion.

---

## Sources

### Primary (HIGH confidence)
- Live worktree at `dcbd6488` — `.github/workflows/ci.yml` (1160 lines), `.github/workflows/publish-hex.yml` (563), `test/support/ci_lanes.ex` (106), `test/scripts/required_checks_test.exs` (268), `test/scripts/ci_parity_drift_test.exs` (232), `test/scripts/conformance_advisory_test.exs`, `mix.exs` (536), `MAINTAINING.md` (370), `CONTRIBUTING.md` (148), `scripts/setup_branch_protection.sh`, `scripts/check_credo_suppressions.sh`, `scripts/check_motion_conformance.sh`, `mailglass_admin/scripts/check-conformance.sh`, `mailglass_admin/scripts/check-conformance-advisory.sh`
- GitHub REST API, 2026-07-28 — `repos/szTheory/mailglass/branches/main/protection`; `repos/szTheory/mailglass/actions/runs/30383484662/jobs`; `.../30384054278/jobs`
- Local execution — `MIX_ENV=test mix test test/scripts/` with and without `--warnings-as-errors`
- `git` — per-file `hash-object` comparison for 48 v2.0 files and rename detection for 39 v2.1 files; commit bodies of `b5fed519`, `a629fb82`, `70099869`

### Secondary (MEDIUM confidence)
- `.planning/research/v2.2/SUMMARY.md:32` — no-new-dependency lock; split pre-authorization
- `.planning/research/v2.2/ARCHITECTURE.md:130-200` — hidden-third-tier table and file list (this research **extends** it with F1/F2/F3, which it does not cover)
- `.planning/research/v2.2/PITFALLS.md:480-500` — the smuggled-behavior-change pitfall (F1 is a concrete instance)
- `.planning/STATE.md:35-60`, `.planning/REQUIREMENTS.md:85-139`, `.planning/ROADMAP.md`

### Tertiary (LOW confidence)
- None. Every claim in this document was verified against the live repo, the live GitHub API, or local execution.

---

## Metadata

**Confidence breakdown:**
- Citation verification: **HIGH** — every CONTEXT.md citation re-read at `dcbd6488`
- Lane classification ledger: **HIGH** — cross-checked YAML `name:` fields against two live API job lists
- F1 (matrix suffixes): **HIGH** — directly observed on two live runs with opposite outcomes
- F2 (no CI lane runs `test/scripts/`): **HIGH** — exhaustive grep of every `run:` in `.github/workflows/` plus every `verify.*` alias body
- F3 (parity vs classification axes): **HIGH** — the file's own comments and its single consumer
- F4 (split safety): **HIGH** — grep proved no build-artifact dependency in any of the four scripts
- F5 (`--warnings-as-errors`): **HIGH** — executed locally
- F7 (HIST-01): **HIGH** — per-file SHA comparison, 48/48 and 39/39
- `gate-ci-green` rewrite shape: **MEDIUM-HIGH** — logic is derived, not executed; the negative-control check (criterion 1b) is the intended proof

**Research date:** 2026-07-28
**Valid until:** 2026-08-27 (30 days) — or immediately invalid if `ci.yml`'s job set, any `strategy.matrix`, or `publish-hex.yml`'s `gate-ci-green` changes. Re-run the two `gh api .../jobs` calls before implementing if any time has passed.
