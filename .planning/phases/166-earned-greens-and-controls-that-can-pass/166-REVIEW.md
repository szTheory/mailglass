---
phase: 166-earned-greens-and-controls-that-can-pass
reviewed: 2026-09-18T00:00:00Z
depth: standard
files_reviewed: 17
files_reviewed_list:
  - .github/workflows/ci.yml
  - .github/workflows/post-publish-smoke.yml
  - .github/workflows/release-please.yml
  - config/coverage_baselines/admin.json
  - dev/mix/tasks/mailglass.repo.hygiene.ex
  - docs/ci-cache-isolation.md
  - lib/mailglass/supply_chain/accepted_advisories.ex
  - mailglass_admin/mix.exs
  - scripts/check_post_publish_target.sh
  - scripts/release_policy.exs
  - test/mailglass/publish/post_publish_smoke_contract_test.exs
  - test/mailglass/supply_chain/accepted_advisories_test.exs
  - test/mix/tasks/mailglass.repo.hygiene_test.exs
  - test/scripts/coverage_floor_contract_test.exs
  - test/scripts/lane_classification_drift_test.exs
  - test/scripts/release_policy_contract_test.exs
  - test/scripts/release_trigger_recovery_test.exs
findings:
  critical: 0
  warning: 4
  info: 2
  total: 6
status: issues_found
---

# Phase 166: Code Review Report

**Reviewed:** 2026-09-18
**Depth:** standard
**Files Reviewed:** 17
**Status:** issues_found

## Summary

Phase 166's explicit mission is anti-vacuity: every green must be earned and every fail-closed
control must have a reachable pass path. I read all 17 in-scope files plus the six plan SUMMARYs
and `deferred-items.md` to establish which deviations/gaps were already found, fixed, and
documented by the executors themselves (those are treated as ground truth per the review
instructions and are not re-reported below).

The specific traps named in the review brief were checked directly against the code, not just the
prose claiming they were handled:

- **Bash exit-status trap** (`if CMD; then ...; fi` swallowing `$?`) — the fix in
  `release-please.yml`'s `retry_gh` (`call_status=0; "$@" ... || call_status=$?`) is present and
  correct at both call sites (discovery + capture steps).
- **`set -u` / bash 3.2 empty-array crash** — the array-expansion form was removed entirely from
  `post-publish-smoke.yml`; the digest-bypass call is two fully-written explicit invocations
  (`--baseline-mode` branch / no-flag branch), not an array. Confirmed correct.
- **`:cannot_check` vs `:blocked` exit codes** — `dev/mix/tasks/mailglass.repo.hygiene.ex` maps
  `:cannot_check` to `{:shutdown, 2}` and `:blocked` to `{:shutdown, 1}`, both non-zero and
  distinct. Confirmed by direct reading and by the test suite's boundary cases.
- **64-hex digest bypass scope** — in `check_post_publish_target.sh`, the 40-hex `target_ref`
  regex, the three exact-SemVer assertions, and the tag-resolves-to-`target_ref` loop all execute
  unconditionally *before* the `if [ "$baseline_mode" = true ]` branch that skips only the digest
  check. The live-dispatch path is structurally untouched by the new flag. Confirmed correct by
  code reading (see Warning WR-02 below for the coverage gap this correctness currently rests on).
- **`baseline=true` signal distinctness** — `post-publish-smoke.yml`'s `cron-guard` job reads a
  dedicated `baseline` output and never reuses `completed=true`; `scripts/release_policy.exs`'s new
  `baseline-versions` verb emits `completed=false` / `authorized=false` / `baseline=true`
  explicitly. Confirmed correct.
- **14-day PR-age off-by-one** — `pr_stale?/1` uses `div(diff_seconds, 86_400) > 14`, and the test
  suite pins exactly-14-days-not-blocked and 15-days-blocked as separate cases. Confirmed correct,
  and a good defensive choice over raw-second comparison (documented rationale: audit-run latency).
- **Null/malformed `statusCheckRollup`** — `pr_failing_check?/1` pattern-matches `is_list(rollup)`
  and falls through to `false` (not-failing) for anything else, including `nil`; a genuinely
  malformed *list-decode* failure upstream (the whole `gh pr list` response) still routes to
  `cannot_check`, never silently to `pass`. Confirmed correct, with a test for the null-rollup case.

No blocker-level defects were found: the security-relevant boundaries the milestone exists to
protect (digest bypass scope, exit-code fail-closed semantics, live-dispatch guard
unconditionality, exact-boundary date/day arithmetic) are all implemented correctly on direct code
reading. The findings below are about gaps *around* that correct code — missing regression
coverage for the newest and most security-relevant addition, one pre-existing-but-now-more-
consequential control-masking behavior, and one piece of decorative-but-unverified provenance data
that a "measured, not asserted" milestone should not be carrying uncritically.

## Warnings

### WR-01: `--baseline-mode` digest bypass has no test that actually executes it

**File:** `scripts/check_post_publish_target.sh:89-110`, `test/mailglass/publish/post_publish_smoke_contract_test.exs`
**Issue:** This phase's own stated risk is "the 64-hex digest bypass ... must be scoped to
baseline mode only and must not be reachable on the live-dispatch path." By direct code reading,
it is correctly scoped (see Summary). But nothing in the test suite *executes* the script with
`--baseline-mode` to prove that at runtime — the only reference to `baseline_mode`/`baseline-mode`
in `test/` is a single substring assertion against the workflow YAML text
(`post_publish_smoke_contract_test.exs:61`, `assert resolver =~ "baseline_mode=true"`). The
existing execution-based test for this script, `"target guard rejects arbitrary commits, content
drift, and incomplete tag sets"` (same file, lines 376-444), calls `run_target_guard/3`, which
never passes `--baseline-mode` (see the fixed argument list at lines 671-689). So:
- No test proves the digest check is actually skipped in baseline mode (vs. e.g. a future
  refactor accidentally moving the `if [ "$baseline_mode" = true ]` check above the tag/ref/version
  guards, which would silently widen the bypass).
- No test proves a malformed `target_ref` (39/41 chars, uppercase hex) or malformed SemVer is still
  rejected under `--baseline-mode` specifically, even though the code path is shared and should
  reject them identically to the live-dispatch path.
- This script has never had a test asserting the ref/version regex *rejection* messages at all
  (`grep -rn "must be an exact 40-character" test/` returns nothing), so this gap predates the flag
  but is now materially more important because the new flag adds a genuine security-relevant
  branch to a previously branch-free validator.

**Fix:** Add cases to the existing `run_target_guard`-style harness that (a) call the script with
`--baseline-mode` and assert the digest line is skipped while the "post-publish target verified"
success path still requires all three tags to resolve to `target_ref`; (b) call it with a 39-char,
41-char, and uppercase-hex `target_ref` (both with and without `--baseline-mode`) and assert
`exit 1` / `"must be an exact 40-character..."`; (c) call it with a malformed version
(e.g. `"3.0"`, `"3.0.0-rc.1"`) and assert rejection in both modes.

### WR-02: `report_sha256` in coverage-floor baselines is recorded but never verified anywhere

**File:** `config/coverage_baselines/admin.json:10`, `scripts/check_coverage_floor.sh`,
`test/scripts/coverage_floor_contract_test.exs`
**Issue:** `config/coverage_baselines/admin.json` (new in this phase) carries a `report_sha256`
field, and `166-01-SUMMARY.md` explicitly cites it as part of the measured-not-asserted proof
("`report_sha256` matching the measuring run's `coverage/admin/excoveralls.json`"). But
`scripts/check_coverage_floor.sh` never reads or compares `report_sha256` — it only compares
`covered_lines`/`relevant_lines`/`percentage` computed live from the report's `source_files`. Grep
confirms no file under `scripts/` or `test/` references `report_sha256` at all except the baseline
JSONs themselves (`config/coverage_baselines/{core,inbound,admin}.json`). The field is therefore
pure decoration: it can drift arbitrarily from the actual measuring run without any test or CI step
ever noticing, which is exactly the "looks like it verifies something but does not" shape this
phase exists to eliminate. (This predates admin.json — core.json and inbound.json carry the same
unverified field — but the phase's own anti-vacuity framing for the *new* admin baseline leans on
this field as evidence, which is what makes it worth flagging now.)

**Fix:** Either (a) have `check_coverage_floor.sh` compute `sha256(report_json)` and assert it
equals the baseline's `report_sha256` (tightens the floor to an exact-report match, not just a
regression-inequality match), or (b) drop the field from the baseline schema and the three
committed JSONs if it is not meant to be load-bearing, so the baseline's documented shape does not
overstate what is actually checked.

### WR-03: `cannot_check` silently outranks a confirmed `blocked` verdict in the aggregate status

**File:** `dev/mix/tasks/mailglass.repo.hygiene.ex:482-488` (`status/1`)
**Issue:** `status/1`'s `cond` checks `:cannot_check` before `:blocked`:
```elixir
defp status(checks) do
  cond do
    Enum.any?(checks, &(&1.status == :cannot_check)) -> :cannot_check
    Enum.any?(checks, &(&1.status == :blocked)) -> :blocked
    true -> :pass
  end
end
```
If, for example, `git_state` genuinely confirms `:blocked` (dirty working tree) *and*, in the same
run, `ci_state` or `branch_protection` cannot be checked (e.g. `gh` missing, `GH_TOKEN` unset), the
aggregate reports `:cannot_check` — not `:blocked` — and `reason/1` surfaces the cannot-check
check's message, not the confirmed block's. This precedence predates Phase 166 (introduced in
`52f2fe35`, Phase 162), but this phase's own CTRL-05 work makes the consequence materially worse:
before this phase, `:cannot_check` and `:blocked` shared the same exit code, so masking a confirmed
block behind an unrelated cannot-check at least still exited non-zero identically either way. Now
that this phase deliberately gives `:cannot_check` its own *lower-alarm* exit code
(`{:shutdown, 2}`) specifically framed as "a non-verdict, not a confirmed alarm" (D-34), the same
masking silently downgrades a real, confirmed, actionable block into what reads to an operator as
"we just couldn't check something" — the opposite of what a fail-closed release gate should do
when one of its checks *did* return a hard alarm.
**Fix:** Invert the precedence so a confirmed `:blocked` always outranks an unrelated
`:cannot_check` in the aggregate: `cond do Enum.any?(&:blocked) -> :blocked; Enum.any?(&:cannot_check) -> :cannot_check; true -> :pass end`. A cannot-check-only run should still report
`:cannot_check`; a run with both should report the confirmed alarm.

### WR-04: `mix verify.support_contract.admin` and the coverage-floor step both run the full admin suite, independently

**File:** `.github/workflows/ci.yml:932-939`
**Issue:** `support_contract_admin` now runs `mix verify.support_contract.admin` (which is
`test --warnings-as-errors`, the full 510-test directory-scoped run per 166-01) and then, as a
separate step, `mix coveralls.json --output-dir ../coverage/admin test --warnings-as-errors` —
which independently re-runs the entire admin suite a second time under ExCoveralls
instrumentation. This is flagged as a quality/reliability note rather than a correctness bug
(performance duplication is explicitly out of scope for this review), but it does mean the "510
tests, 0 failures" claim the required lane surfaces and the coverage numbers the floor is enforced
against come from two *different* test executions in the same job, not one — so a flaky test that
passes in one run and fails in the other produces a confusing partial-red (support-contract green,
coverage step red on an unrelated flake) rather than a single coherent signal.
**Fix:** Consider running `mix coveralls.json` once and pointing `verify.support_contract.admin`'s
required-lane assertion at that same coverage run's test outcome, or explicitly document the
double-run as intentional (parity with core/inbound's separate coverage step) if left as-is.

## Info

### IN-01: `scripts/release_policy.exs`'s bare-invocation guard only catches 3 known-stale spellings

**File:** `scripts/release_policy.exs:841-853`
**Issue:** The trailing `case System.argv() do ... end` block exists specifically to fail loudly on
historical bare-invocation forms (`elixir FILE --validate-candidate`, etc.) that silently no-op
because `elixir FILE ARGS` only evaluates the module — it never calls `cli/1`. But the guard only
matches three specific legacy `--`-prefixed flags. Any other bare positional invocation — including
the exact form `166-06-SUMMARY.md` documents its own plan text prescribing
(`elixir scripts/release_policy.exs baseline-versions .planning/release-target.json`) — still
silently exits 0 with no output regardless of whether the verb is valid, as the 166-06 executor
independently discovered and worked around (see `166-06-SUMMARY.md`, Auto-fixed Issue #4). This is
already a documented, resolved deviation for this phase's own verification step (not re-reported
as a new finding against the shipped code paths, which all use the correct `--require ... -e
'Mailglass.ReleasePolicy.cli(System.argv())' --` form in both workflows). Recorded here only
because the guard itself remains a latent footgun for the *next* person who writes a bare
`elixir scripts/release_policy.exs <verb> <args>` verification command or doc snippet and gets a
silent false-pass.
**Fix:** Broaden the trailing guard to fail loudly on *any* non-empty `System.argv()` under a bare
invocation (i.e., assume every bare call needs the `--require -e cli(...)` form), rather than an
allowlist of three known-bad spellings.

### IN-02: GREEN-04/GREEN-05/CTRL-01/CTRL-02/CTRL-03/CTRL-05 post-merge evidence is honestly tracked as pending, not a defect

**File:** `.planning/phases/166-earned-greens-and-controls-that-can-pass/deferred-items.md`
**Issue:** Six of the ten phase requirements carry explicit "Implemented, evidence pending" status
in `REQUIREMENTS.md` per the SUMMARYs, because their acceptance criteria are inherently
post-merge/naturally-triggered observations (a real `chore: release main` merge, real cron firings,
a real CI run against the new cache keys) that cannot be manufactured pre-merge without violating
the plans' own explicit prohibitions on dispatching/re-running to fake evidence. This is exactly
the honest, non-vacuous posture the milestone asks for, not a finding — recorded here only so it is
visible in this artifact too: whoever closes out Phase 166 should re-check
`deferred-items.md`'s per-plan checklists before marking CTRL-01/02/03/05 and GREEN-04/05
`Complete` in `REQUIREMENTS.md`.

---
*Reviewed: 2026-09-18*
*Reviewer: Claude (gsd-code-reviewer)*
*Depth: standard*
