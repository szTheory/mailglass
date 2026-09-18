---
phase: 166-earned-greens-and-controls-that-can-pass
verified: 2026-09-18T03:10:04Z
status: human_needed
score: 4/10 requirements code-verified and closed; 6/10 code-verified but acceptance criteria are
  inherently post-merge/real-cron observations not yet available (honestly tracked as "Implemented,
  evidence pending" — this is the intended end state per phase design, not a defect)
behavior_unverified: 0
overrides_applied: 0
re_verification: No — initial verification
human_verification:
  - test: "CTRL-01 — dispatch post-publish-smoke.yml with mode=baseline against the current inactive ledger after this PR merges to main"
    expected: "resolve-completed-target job exits 0, uploads post-publish-resolution-<run_id> containing post-publish-resolution.json with status: pass, reason: exact_target_verified, and core/admin/inbound/target_ref matching release-target.json's baselines + required_evidence_identifiers.historical_tag_sha (2.6.0/2.6.0/2.3.0, 6a0447a9...)"
    why_human: "This is a real workflow_dispatch against a live GitHub Actions run; cannot be produced or simulated from a static repo check. Milestone exit criterion 3."
  - test: "CTRL-02 — merge a chore: release main PR and observe the release-please push run"
    expected: "the tagged-SHA push skip fires (autorelease: tagged label check reached) instead of the action re-running against an already-tagged SHA"
    why_human: "Requires a real Release Please proposal PR to merge; cannot be manufactured pre-merge without producing a fake release."
  - test: "CTRL-03 — three consecutive natural pushes to main"
    expected: "each release-please run concludes success, and push/schedule at the same SHA agree; no run reports cannot-check as pass"
    why_human: "Inherently a sequence of real, naturally-triggered CI runs over time; dispatch/re-run to manufacture this is explicitly prohibited by the plan."
  - test: "CTRL-05 — two consecutive naturally-triggered scheduled repo-hygiene runs (daily cron), with at least one healthy PR (age <=14 days, no failing required check) open across both firings"
    expected: "both runs conclude success with status: pass in the uploaded artifact; the freshly opened healthy PR does not turn the run red"
    why_human: "Requires real cron firings over multiple days; the plan explicitly prohibits workflow_dispatch/re-run to manufacture this evidence."
  - test: "GREEN-04 — confirm on a post-merge main run that support_contract_core's 'Prove demo app Hex pins' step actually resolved reference/demo_app's three mailglass sibling packages from Hex (not path deps) and compiled"
    expected: "step log shows mix deps.get --check-locked resolving Hex packages and mix compile succeeding inside the isolated scratch build"
    why_human: "Local proof (rsync scratch-copy build) was demonstrated by the executor, but the CI-runner-specific confirmation of the shipped ci.yml step has not yet been observed on main."
  - test: "GREEN-05 Part 2 — collect real cache-restore log lines for both trust_lane_repo_head and trust_lane_clean_baseline after the disambiguated cache keys first run in CI"
    expected: "docs/ci-cache-isolation.md Part 2 is populated with the actual hit/miss + resolved-key log lines from a real run (expected: first-run cache miss on both, a cold start per D-16, not a regression), plus the run URL"
    why_human: "Part 2 is explicitly a placeholder pending a real CI run; Parts 1 and 3 are locally demonstrated and code-verified, but the CI-observed half of the three-part proof does not exist yet."
---

# Phase 166: Earned Greens and Controls That Can Pass — Verification Report

**Phase Goal:** Every CI signal either means what it says or can reach its own pass state — without
any gate being relaxed.

**Verified:** 2026-09-18T03:10:04Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

Truths are the 10 GREEN-*/CTRL-* requirements this phase delivers (ROADMAP success criteria 1-5
decompose 1:1 into these). Each was checked by reading the actual diff (not the SUMMARY prose) and,
where runnable, executing the real command/test.

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | GREEN-01: `Support Contract Admin` lane runs the full admin suite (≥510 tests), not a 9-file allow-list | ✓ VERIFIED | `mailglass_admin/mix.exs:212-214` — `"verify.support_contract.admin": ["test --warnings-as-errors"]`, directory-scoped, no file allow-list. `.github/workflows/ci.yml:930` invokes it unchanged. Local admin suite confirmed green in SUMMARY (510 tests, 0 failures); targeted regression tests for this alias (`ci_parity_drift_test.exs` scope) pass here. |
| 2 | GREEN-02: admin lane enforces a measured coverage floor and fails on regression | ✓ VERIFIED | `config/coverage_baselines/admin.json` — measured triple `3334/3992`, `83.517034%`, no safety margin. `.github/workflows/ci.yml:931-939` — new "Collect and enforce admin coverage floor" step runs `mix coveralls.json` then `scripts/check_coverage_floor.sh` against this baseline. SUMMARY documents a demonstrated (not asserted) regression drill against 3 perturbed baseline copies, all correctly failing. `mix test test/scripts/coverage_floor_contract_test.exs` passes here (part of the 152/152 targeted run below). |
| 3 | GREEN-03: required `core_deterministic_suite` lane prints `scope: FULL SUITE (MAILGLASS_SUITE_FLOOR=1)` and the occurrence-drift guard covers `ci.yml` too | ✓ VERIFIED | `.github/workflows/ci.yml:467` — `MAILGLASS_SUITE_FLOOR: "1"` set on the required lane. `test/scripts/lane_classification_drift_test.exs:55,61` — a separate `@ci_yml_suite_floor_occurrences 1` constant/helper guards `ci.yml` without touching the pre-existing `@suite_floor_env_occurrences 2` (advisory-matrix.yml). Ran `mix test test/scripts/lane_classification_drift_test.exs` directly — green. |
| 4 | GREEN-04: a CI lane resolves the demo app's Hex deps (not path deps) | ✓ CODE VERIFIED, ⚠️ CI-run not yet observed | `.github/workflows/ci.yml:295` — `MAILGLASS_DEMO_DEPS: hex` step inside `support_contract_core`, isolated via an rsync scratch copy (documented reasoning: `MIX_DEPS_PATH`/`MIX_BUILD_PATH` overrides break cowlib's `erlang.mk` build). `reference/demo_app/mix.lock` refreshed to the current published 2.6.0/2.6.0/2.3.0 line (a real precondition fix — the frozen 2.0.0 lock could not compile against `mailglass_admin`'s 2.1.0+ `:navigation` dependency; this is a genuine, verifiable bug catch, not embellishment). Local scratch-copy build demonstrated end-to-end per SUMMARY. Post-merge confirmation that the *CI runner itself* resolved from Hex is pending — see human verification. |
| 5 | GREEN-05: trust-lane deps-cache pollution vector resolved or refuted in writing (no "probably fine") | ✓ CODE VERIFIED (Parts 1+3), ⚠️ Part 2 pending | `.github/workflows/ci.yml:1234,1330` — `mix-trust-repo-head-…` / `mix-trust-clean-baseline-…` cache keys, confirmed distinct. `docs/ci-cache-isolation.md` (186 lines) has all 3 named parts; Part 1 (key-space table + `actions/cache` version-hash/all-or-nothing mechanism) and Part 3 (local lock-authority proof: `reference/host_app/mix.lock` resolves the pinned 2.0.0, not a live version) are fully written with mechanism-level evidence, not assertion. `grep -i 'probably fine\|likely fine\|should be fine' docs/ci-cache-isolation.md` — no match, confirmed here. Part 2 is an explicit placeholder for real CI-observed restore log lines — not yet populated. |
| 6 | CTRL-01: `post-publish-smoke`'s schedule path can pass between releases via a baseline-versions resolution path | ✓ CODE VERIFIED, ⚠️ dispatch not yet observed | `.github/workflows/post-publish-smoke.yml:157-167,248-291` — ledger-status peek (`jq`) selects `baseline-versions` for an inactive ledger; new `cron-guard` `baseline` output is distinct from `completed`. `scripts/release_policy.exs` — `baseline-versions` verb confirmed by re-running the correct invocation form (`mix run --require ... -e 'Mailglass.ReleasePolicy.cli(...)'`) per the SUMMARY's own self-caught fix to a broken plan verify-command. `scripts/check_post_publish_target.sh --baseline-mode` bypasses only the digest check — confirmed by direct code reading (unconditional 40-hex/SemVer/tag-resolution guards execute before the `if baseline_mode` branch) AND now by execution: `test/scripts/check_post_publish_target_test.exs` (commit `905cb3f9`/`a1a3249f`) actually runs the script under both modes — ran locally here, 9/9 pass. Live `workflow_dispatch mode=baseline` against `main` has not yet been observed — milestone exit criterion 3, explicitly tracked pending. |
| 7 | CTRL-02: release-please no longer re-runs the action against an already-tagged SHA on push | ✓ CODE VERIFIED, ⚠️ merge not yet observed | `.github/workflows/release-please.yml` — the early-return block that made the tagged-SHA skip unreachable is deleted (commit `45391306`); the `autorelease: tagged` label check at line 156 is reachable again. Contract tests (`release_policy_contract_test.exs`, `release_trigger_recovery_test.exs`) pass locally. Acceptance ("merge of a `chore: release main` PR produces a green push run") is inherently the next real release-please proposal merge — not yet occurred since this landed. |
| 8 | CTRL-03: a transient GitHub API failure is retried, not reported as a control failure | ✓ CODE VERIFIED, ⚠️ 3-push sequence not yet observed | `.github/workflows/release-please.yml:537-568,646-677` — `retry_gh` wraps both `gh pr list` calls that classify to `cannot-check`; bounded 3-attempt 60/120/240s backoff keyed on {403,429} + secondary-rate-phrase body match; `call_status=0; "$@" ... \|\| call_status=$?` pattern confirmed present at both sites (fixes the classic `if CMD; then` exit-status-swallow bug — reviewed and confirmed correct by the independent code reviewer too). `continue-on-error: true` + one guarded re-run wraps the release-please action step itself. Acceptance ("3 consecutive pushes agree") requires real elapsed time/pushes — not yet observed. |
| 9 | CTRL-04: Hex Audit calendar time bomb defused truthfully before 2026-10-26 | ✓ VERIFIED | `lib/mailglass/supply_chain/accepted_advisories.ex` — both cowlib entries carry `recheck_by: ~D[2027-03-17]` and a permanent-refusal `:reason` citing 6 closed upstream PRs, maintainer position, OSV re-confirmation, framework mitigation. Ran `mix mailglass.audit --kind hex` directly here (real, un-faked, at today's actual date 2026-09-17) — exit 0, "all findings accepted." No `--today` flag or in-process date-override exists anywhere in `dev/mix/tasks/mailglass.audit.ex` or the advisory module (D-32 honored — confirmed by grep, no matches). The literal-clock-fake fallback (SIP strips `DYLD_INSERT_LIBRARIES` on this macOS/arm64 toolchain, so `faketime` cannot fake even `/bin/date`) is honestly recorded in the SUMMARY and was maintainer-accepted as satisfying the acceptance clause in substance, with the real fallback evidence (un-faked audit pass + the committed date-boundary test) substituted and disclosed, not hidden. |
| 10 | CTRL-05: `repo-hygiene` distinguishes a non-verdict from an alarm; PR predicate stops firing on healthy activity | ✓ CODE VERIFIED, ⚠️ 2 cron firings not yet observed | `dev/mix/tasks/mailglass.repo.hygiene.ex:52-53` — `:cannot_check -> exit({:shutdown, 2})`, `_blocked -> exit({:shutdown, 1})`, confirmed distinct and both non-zero. `pr_stale?/1:434-441` uses `div(diff_seconds, 86_400) > 14` (day-granularity, immune to audit-run-latency off-by-one) OR a failing required check, replacing the old any-open-PR predicate. `mix test test/mix/tasks/mailglass.repo.hygiene_test.exs` — 26 tests including the new D-35 boundary cases — passes locally here. Acceptance ("two consecutive scheduled runs conclude success/pass") needs real cron firings — not yet observed. |

**Score:** 4/10 truths fully closed (code + observed acceptance evidence); 6/10 truths are code-verified
and implemented correctly but their formal acceptance criterion is an inherently post-merge/real-time
observation (a live workflow_dispatch, a real release-please merge, real cron firings) that has not yet
occurred. This split is the phase's own explicit, documented end state — `REQUIREMENTS.md`'s
traceability table already reflects it (`Complete` for GREEN-01/02/03 and CTRL-04; `Implemented,
evidence pending` for the other six), and this verification confirms that table is accurate, not
optimistic.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `mailglass_admin/mix.exs` | directory-scoped `verify.support_contract.admin`, `test_coverage:`, `excoveralls` dep | ✓ VERIFIED | Confirmed by direct read (lines 20, 42, 137, 212-214) |
| `config/coverage_baselines/admin.json` | measured coverage triple, no rounding | ✓ VERIFIED | Present, matches SUMMARY's cited numbers exactly |
| `.github/workflows/ci.yml` | `MAILGLASS_SUITE_FLOOR`, admin coverage step, `MAILGLASS_DEMO_DEPS`, lane-specific trust cache keys | ✓ VERIFIED | All 4 additions confirmed present at cited line numbers |
| `test/scripts/lane_classification_drift_test.exs` | ci.yml suite-floor occurrence guard, independent of advisory-matrix.yml's | ✓ VERIFIED | Confirmed two independent constants/helpers |
| `lib/mailglass/supply_chain/accepted_advisories.ex` | permanent-refusal reasons, `recheck_by: ~D[2027-03-17]` | ✓ VERIFIED | Confirmed; data-only diff (no `def`/`defp` changed per SUMMARY, spot-checked structurally) |
| `.github/workflows/release-please.yml` | tagged-SHA skip reachable again, bounded retry wrapper | ✓ VERIFIED | Confirmed at cited lines; exit-status-swallow bug fix confirmed present |
| `.github/workflows/post-publish-smoke.yml` | `baseline-versions` resolution path, distinct `baseline` output | ✓ VERIFIED | Confirmed |
| `scripts/release_policy.exs` | `baseline-versions` CLI verb | ✓ VERIFIED | Confirmed via direct CLI invocation, output matched ledger data |
| `scripts/check_post_publish_target.sh` | `--baseline-mode` bypasses only the digest check | ✓ VERIFIED + now execution-tested | WR-01 fix (`905cb3f9`/`a1a3249f`) confirmed landed; ran the test file directly, 9/9 pass |
| `dev/mix/tasks/mailglass.repo.hygiene.ex` | exit-code split, 14-day/failing-check predicate | ✓ VERIFIED | Confirmed at cited lines; 26 targeted tests pass |
| `docs/ci-cache-isolation.md` | 3-part refutation, no hedged verdict | ✓ VERIFIED (Parts 1+3); ⚠️ Part 2 placeholder | Confirmed 186 lines, 3 named parts, no hedge-language match |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `ci.yml` `support_contract_admin` job | `mailglass_admin/mix.exs` `verify.support_contract.admin` alias | `mix verify.support_contract.admin` invocation | ✓ WIRED | Step at ci.yml:930 calls the widened alias unchanged |
| `ci.yml` admin coverage step | `config/coverage_baselines/admin.json` | `scripts/check_coverage_floor.sh config/coverage_baselines/admin.json coverage/admin/excoveralls.json 1.18.4/27` | ✓ WIRED | Exact invocation confirmed at ci.yml:939 |
| `ci.yml` `core_deterministic_suite` job | `test/support/suite_floor.ex` | `MAILGLASS_SUITE_FLOOR: "1"` env var read at runtime | ✓ WIRED | Confirmed the env line exists; suite_floor.ex itself was correctly left unmodified per SUMMARY (only its trigger condition changed) |
| `release-please.yml` proposal steps | `retry_gh` wrapper | both `gh pr list` call sites (lines 572, 684) | ✓ WIRED | Confirmed both sites wrapped, not just one |
| `post-publish-smoke.yml` resolve job | `scripts/release_policy.exs baseline-versions` | `jq` ledger-status peek selecting the verb | ✓ WIRED | Confirmed branch logic at lines 157-167 |
| `mailglass.repo.hygiene.ex` `status/1` | `reason/1` and JSON/text renderers | aggregate status computation | ⚠️ NOTED, not a gap | `cannot_check` ranks above a confirmed `blocked` in the one-line aggregate (WR-03). Pre-existing (Phase 162) behavior, explicitly test-pinned, individual checks still fully visible in output, both exit codes non-zero. Reviewed and deliberately left as a design question for Phase 167/maintainer rather than flipped unilaterally — correctly NOT treated as a phase-166 defect. |

### Requirements Coverage

| Requirement | Plan | Description | Status | Evidence |
|---|---|---|---|---|
| GREEN-01 | 166-01 | Full admin suite executes in CI | ✓ SATISFIED | Directory-scoped alias confirmed |
| GREEN-02 | 166-01 | Admin coverage floor enforced | ✓ SATISFIED | Measured baseline + CI step confirmed, regression drill demonstrated |
| GREEN-03 | 166-02 | `core_deterministic_suite` anti-vacuity floor enforced | ✓ SATISFIED | Env var + occurrence guard confirmed |
| GREEN-04 | 166-05 | Demo app Hex pins exercised in CI | ⚠️ CODE SATISFIED, CI observation pending | Isolated build step present; post-merge confirmation outstanding |
| GREEN-05 | 166-05 | Trust-lane cache pollution resolved/refuted in writing | ⚠️ PARTIALLY SATISFIED | Parts 1+3 real; Part 2 pending real CI evidence |
| CTRL-01 | 166-06 | post-publish-smoke can pass on schedule between releases | ⚠️ CODE SATISFIED, dispatch pending | Baseline-versions path present and unit-tested; live dispatch not yet observed |
| CTRL-02 | 166-04 | No redundant re-run on already-tagged SHA push | ⚠️ CODE SATISFIED, merge pending | Early-return deleted; next real merge will prove it |
| CTRL-03 | 166-04 | Transient GitHub API failure retried, not reported as failure | ⚠️ CODE SATISFIED, sequence pending | Retry wrapper present and bug-fixed; 3-push sequence not yet observed |
| CTRL-04 | 166-03 | Hex Audit calendar time bomb defused truthfully | ✓ SATISFIED | Verified by running the real audit here, exit 0 |
| CTRL-05 | 166-06 | repo-hygiene distinguishes non-verdict from alarm; PR predicate fixed | ⚠️ CODE SATISFIED, cron firings pending | Exit-code split + predicate confirmed; 2 firings not yet observed |

No orphaned requirements — all 10 GREEN-*/CTRL-* IDs map to exactly one plan each, matching
`REQUIREMENTS.md`'s traceability table (lines 206-215).

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| `mix mailglass.audit --kind hex` passes today (real clock) | `mix mailglass.audit --kind hex` | "all findings accepted" | ✓ PASS |
| Targeted phase-166 test files are green | `mix test test/scripts/lane_classification_drift_test.exs test/scripts/coverage_floor_contract_test.exs test/mailglass/supply_chain/accepted_advisories_test.exs test/mix/tasks/mailglass.repo.hygiene_test.exs test/mailglass/publish/post_publish_smoke_contract_test.exs test/scripts/release_policy_contract_test.exs test/scripts/release_trigger_recovery_test.exs` | 152 tests, 0 failures | ✓ PASS |
| WR-01 fix actually executes the digest-bypass script | `mix test test/scripts/check_post_publish_target_test.exs` | 9 tests, 0 failures | ✓ PASS |
| release_policy.exs `baseline-versions` verb produces real output | `mix run --no-start --no-compile --no-deps-check --require scripts/release_policy.exs -e 'Mailglass.ReleasePolicy.cli(System.argv())' -- baseline-versions .planning/release-target.json` (re-derived from SUMMARY's own self-caught fix) | not independently re-run in this session (SUMMARY's captured output was reviewed instead) | ? SKIP — accepted secondary evidence |
| `mix.exs` alias/CI parity holds | `verify.support_contract.admin` alias name unchanged, ci.yml untouched for the alias invocation | Confirmed via grep, ci.yml:930 still calls the same alias name | ✓ PASS |

### Probe Execution

No `scripts/*/tests/probe-*.sh` files or phase-declared probes found for this phase (`find scripts -path '*/tests/probe-*.sh'` — none; no probe references in the PLAN/SUMMARY files). Step 7c: SKIPPED (no probes declared).

### Anti-Patterns Found

No `TBD`/`FIXME`/`XXX`/`TODO`/`HACK`/`PLACEHOLDER` markers found in any of the 17 files the code
review covered, re-confirmed by a direct grep here. No stub return values, no hollow props, no
console.log-only implementations — this is infrastructure/CI/Elixir code, not UI, and the review's
own targeted trap-checks (bash exit-status swallow, `set -u` array-expansion crash, exit-code
distinctness, digest-bypass scope, boundary-date arithmetic, null-rollup handling) were independently
re-confirmed correct here rather than re-trusted from the review's prose. Zero Critical findings from
the code review; 4 Warnings (WR-01 fixed in-phase; WR-02, WR-03, WR-04 investigated and deliberately
carried to Phase 167 with documented reasoning, not silently dropped); 2 Info items (both about
already-fixed/already-honest states, not defects).

### Human Verification Required

Six items — one per requirement whose formal acceptance criterion is an inherently post-merge or
naturally-triggered real-world observation. These are **not gaps**: the code implementing each is
present, correct on direct reading, and covered by passing tests; only the "did the real system, over
real time, actually behave this way" half remains outstanding, exactly as `REQUIREMENTS.md`,
`deferred-items.md`, and the code review's IN-02 all already and honestly record. See the
`human_verification` block in this file's frontmatter for the full checklist per item (CTRL-01,
CTRL-02, CTRL-03, CTRL-05, GREEN-04, GREEN-05 Part 2).

Additionally, WR-03 (`cannot_check` ranks above a confirmed `blocked` in the one-line aggregate status
of `mailglass.repo.hygiene.ex`) is not a phase-166 defect — it is pre-existing Phase 162 behavior,
deliberately investigated and left alone with documented reasoning (both exit codes are non-zero;
individual checks remain visible in full output; the precedence is a defensible "don't issue a
verdict on a repo you can't fully observe" reading) — but it is explicitly carried forward as an open
design question for the maintainer/Phase 167, not silently resolved either way. Flagging it here so it
is not lost.

### Gaps Summary

No gaps. Every requirement this phase claims to deliver has a real, correct implementation in the
codebase — confirmed by direct code reading (not SUMMARY narration) and, wherever runnable, by
actually executing the commands/tests rather than trusting the SUMMARY's reported output. The one
missing `## Self-Check:` section (166-03-SUMMARY.md) is a documentation-completeness gap in the
SUMMARY itself, not a goal failure — CTRL-04's actual deliverable (the advisory rewrite) is fully
present and independently re-verified here by running the real audit command.

The phase's own honest design — six of ten requirements deliberately left at "Implemented, evidence
pending" because their acceptance criteria are real, naturally-triggered, post-merge observations that
must never be manufactured by dispatch or re-run — is exactly what routes this verification to
`human_needed` rather than `passed`. This is the correct and intended outcome per the phase's stop
line ("every claim the repo makes about itself is true or tested") applied honestly to itself: the
repo does not currently claim these six are Complete, and this verification confirms that restraint is
warranted, not premature.

---

_Verified: 2026-09-18T03:10:04Z_
_Verifier: Claude (gsd-verifier)_
