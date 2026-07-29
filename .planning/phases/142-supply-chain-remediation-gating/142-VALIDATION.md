---
phase: 142
slug: supply-chain-remediation-gating
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-28
---

# Phase 142 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Seeded from `142-RESEARCH.md` § Validation Architecture (lines 593-633).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.18.4 / OTP 27.3.4.13, per `.tool-versions`) |
| **Config file** | `test/test_helper.exs` — boots `Mailglass.TestRepo`; **not needed** by this phase's own new tests (audit parsing/orchestration touches no DB) |
| **`elixirc_paths(:test)`** | `["lib", "credo_checks", "test/support", "dev"]` (`mix.exs:114-116`) — the `dev/`-hosted task compiles in `:test`, which is what makes D-01's split testable |
| **Quick run command** | `MIX_ENV=test mix test test/mailglass/supply_chain/ test/mix/tasks/mailglass.audit_test.exs test/mailglass/publish/audit_allowlist_test.exs --no-start --warnings-as-errors` |
| **Full suite command** | `mix ci` (requires Postgres + network for unrelated lanes; this phase's own tests need neither) |
| **Estimated runtime** | ~3-6 s quick · ~6-9 min full |

**Already-wired, no new CI step needed (F-research):** `verify.mix_tasks` (`mix.exs:287`, run by the
`mix_task_tests` job at `ci.yml:230`) is the directory glob `"test test/mix/tasks/ --warnings-as-errors"`.
A new `test/mix/tasks/mailglass.audit_test.exs` is picked up automatically. This is the opposite of
Phase 141's F2, where the enforcement lane had to be built first.

**Blocking precondition (F1):** `test/scripts/ci_parity_drift_test.exs`'s matchers (`:113-114`,
`:187-188`) key on the `hex.audit` / `deps.audit` step substrings in `mix.exs`'s **local `:ci` alias
text only** — they never read `ci.yml`. If Wave 1 rewires the CI-side audit jobs to `mailglass.audit`
without widening `mix.exs:395-396` in the same commit, this test stays **green while the MIXCI-03
local-parity claim silently narrows** — a vacuous green of exactly the class this milestone exists to
eliminate. Widen both in one commit, or update the matcher **and** the stale-matcher MapSet together
and record the narrowed claim explicitly.

---

## Sampling Rate

- **After every task commit:** `MIX_ENV=test mix test test/mailglass/supply_chain/ test/mix/tasks/mailglass.audit_test.exs --warnings-as-errors`
- **After every plan wave:** `mix ci.fast` (compile + credo must stay green; Waves 1 and 2 both touch
  `mix.exs` and `test/support/ci_lanes.ex`) **plus** `mix verify.ci_lane_contract`
- **Before `/gsd-verify-work`:** full `mix ci` green, **plus** criteria 1b, 2d and 4 executed once by a
  human and their observed output recorded in SUMMARY.md
- **Max feedback latency:** ~6 s (quick) / ~90 s (`ci.fast`)

---

## Per-Task Verification Map

*Seeded as draft — task IDs are assigned by the planner. `/gsd-validate-phase` fills and confirms
this table against the final PLAN.md files.*

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | 1 | VULN-05 | — | Allowlist is one source; both lanes read it | unit | `MIX_ENV=test mix test test/mailglass/supply_chain/accepted_advisories_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| TBD | TBD | 1 | VULN-05 | — | Per-directory audit sees `mailglass_admin`'s cowlib findings | unit | `MIX_ENV=test mix test test/mix/tasks/mailglass.audit_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| TBD | TBD | 1 | VULN-05 | — | Extraction does not regress the publish gate | unit | `MIX_ENV=test mix test test/mailglass/publish/audit_allowlist_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| TBD | TBD | 1 | VULN-05 | — | Local `mix ci` parity not silently narrowed (F1) | unit | `MIX_ENV=test mix test test/scripts/ci_parity_drift_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| TBD | TBD | 1 | VULN-06 | T-142-01 | Expired `recheck_by` hard-fails, naming the entry | unit | `MIX_ENV=test mix test test/mailglass/supply_chain/accepted_advisories_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| TBD | TBD | 1 | VULN-06 | T-142-01 | Unused allowlist entry hard-fails, naming the entry | unit | `MIX_ENV=test mix test test/mailglass/supply_chain/accepted_advisories_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| TBD | TBD | 1 | VULN-02 | T-142-03 | Each dependabot PR dispositioned individually, never blanket | manual | `gh pr list --repo szTheory/mailglass --state open --json number,author,autoMergeRequest` | ✅ | ⬜ pending |
| TBD | TBD | 2 | VULN-03 | — | New HIGH-with-fix exits non-zero; cowlib-only exits zero | unit | `MIX_ENV=test mix test test/mix/tasks/mailglass.audit_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| TBD | TBD | 2 | VULN-03 | — | 24-job classification totality holds post-promotion | integration | `mix verify.ci_lane_contract` | ✅ | ⬜ pending |
| TBD | TBD | 2 | VULN-03 | — | `continue-on-error: true` absent from the promoted lane | static | `MIX_ENV=test mix test test/scripts/conformance_advisory_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| TBD | TBD | 3 | VULN-04 | T-142-02 | Triage cadence documented outside the 24-row table's bounds | static | `MIX_ENV=test mix test test/scripts/lane_classification_drift_test.exs --warnings-as-errors` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Success Criteria → Concrete Checks

| # | Criterion | Runnable check | Runs where |
|---|---|---|---|
| 1 | `hex_audit` CI lane honors the shared allowlist, landed+green **before** criterion 2 | `mix mailglass.audit` (kind: hex) locally against `mailglass_admin`'s real cowlib findings → exit 0 | Local + CI |
| 1b | **D-14's precondition:** the lane is green *with cowlib in scope*, not green because it looked at nothing | A real PR run log showing the `Hex Audit` lane green **while both cowlib advisories were detected and suppressed by the allowlist** — not merely "no findings" | **Human, once** — record the observed log excerpt in SUMMARY.md. Wave 2 MUST NOT start without it. |
| 1c | The allowlist genuinely filters (anti-vacuity negative control) | Temporarily remove one `@entries` item → confirm the task now exits non-zero against `mailglass_admin`'s real findings → revert | **Human, once** — mirrors the `lane_classification_drift_test.exs:162-229` negative-control precedent Phase 141 established |
| 2 | Both lanes merge-gating; new HIGH-with-fix blocks, cowlib-only merges clean | D-15's deterministic unit test: synthetic HIGH-with-fix output → non-zero; real cowlib-only output → zero | CI (new task's own suite) |
| 2b | The 24-job classification totality (5+4+13+2 → 7+3+12+2 = 24) still holds | `mix verify.ci_lane_contract` (the Phase-141-built meta-test, now exercising Wave 2's edits) | CI (`mix_task_tests`, publish-gating) |
| 2c | Local `mix ci` parity is not silently narrowed (**F1**) | `mix ci`'s audit step(s) invoke the same command the CI lanes do; `ci_parity_drift_test.exs` passes with the **updated** matcher, not the stale one | Local + CI |
| 2d | `ci_green` actually blocks — `continue-on-error` deletion took effect (**D-07**) | Optional `gate-self-test.yml` dispatch with `check_name: "Hex Audit ("` (`gate-self-test.yml:19-22` accepts a leaf-lane prefix) | **Human, once** — the only check that proves runtime blocking rather than YAML shape |
| 3 | Every allowlisted advisory has a reason + `recheck_by`; expired/unused entries flagged | Unit tests on the expiry check (past-dated `recheck_by` fails loud) and the unused-entry check (an entry matching no current finding fails loud — **fires TODAY** against the real allowlist, per D-10/F4) | CI |
| 4 | All 13 dependabot PRs dispositioned | `gh pr list --repo szTheory/mailglass --state open --json number,author,autoMergeRequest` returns zero `app/dependabot` entries with non-null `autoMergeRequest`, OR each remaining one carries a recorded reason in the phase artifact | **Human, once**, at phase close |
| 5 | Triage cadence documented: who / how often / response-by-severity / the transitive-PR limitation | `grep -A 20 '## Dependency Advisory Triage' MAINTAINING.md` shows all four elements; **and** `lane_classification_drift_test.exs`'s section-boundary parser (`:455-468`, `:607-611`) still finds exactly 24 rows — i.e. the new section did not land inside `## Required Checks` | CI (existing meta-test, unmodified) + human read |

---

## Wave 0 Requirements

- [ ] `lib/mailglass/supply_chain/accepted_advisories.ex` — new module, `use Boundary, classify_to: Mailglass`
      (**A1/F5**, MEDIUM confidence — if the boundary call shape is wrong, `mix compile --warnings-as-errors`
      fails loudly at first build; no silent failure mode) — covers VULN-05, VULN-06
- [ ] `dev/mix/tasks/mailglass.audit.ex` — new dev-path task (covers VULN-05). **Must stay in `dev/`**:
      a `lib/`-hosted task obligates entries in `docs/api_stability.md` **and**
      `test/mailglass/stability_contract_test.exs:43-50`, which runs in the **required** Support Contract
      Core lane — red lane if missed (D-01)
- [ ] `test/mailglass/supply_chain/accepted_advisories_test.exs` — new (VULN-06 expiry + unused-entry checks)
- [ ] `test/mix/tasks/mailglass.audit_test.exs` — new; **auto-included** by the existing `verify.mix_tasks`
      directory glob, no `ci.yml` / `mix.exs` wiring needed
- [ ] `test/mailglass/publish/audit_allowlist_test.exs` — modify per **F2**: add the missing **positive**
      alias-suppression test (only a negative control exists today) and correct the now-stale docstrings at
      `:57-62`
- [ ] `mix.exs` — widen the `:ci` alias audit steps (**F1**) in the same commit as the CI-side rewire

No framework install needed. No new dependency (`.planning/research/v2.2/SUMMARY.md` lock honored).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Wave 1 is green **with the accepted advisories actually in the lane's scope** | VULN-05 | Root `mix hex.audit` is clean today. A Wave 1 that quietly stayed root-only would look green for the wrong reason and hand Wave 2 a false precondition — the exact vacuous-green class this milestone closes. No static check distinguishes "suppressed 2 findings" from "saw 0 findings" after the fact. | On the Wave 1 PR run, open the `Hex Audit` lane log. Confirm it names **both** cowlib advisories as detected **and** suppressed-by-allowlist for `mailglass_admin`. Record the excerpt in SUMMARY.md. **This is D-14's hard gate on starting Wave 2.** |
| The allowlist genuinely filters (negative control) | VULN-05 / VULN-06 | A filter that passes vacuously is this milestone's originating failure mode; proving it filters requires deliberately removing an entry. | Remove one `@entries` item → run the task against `mailglass_admin` → confirm a **named, specific** non-zero failure → revert. Record the message. |
| `continue-on-error` deletion actually blocks a merge at runtime | VULN-03 | D-07 establishes the mechanics from GitHub docs, but job-level vs step-level `conclusion`/`result` divergence is only observable on a live run. Residual uncertainty is one-directional and safe, but unverified. | Dispatch `gate-self-test.yml` with `check_name: "Hex Audit ("`, or observe a real failing-audit PR. Confirm `ci_green` reports failure rather than success. |
| All 13 dependabot PRs dispositioned individually with a recorded reason | VULN-02 | Requires authenticated GitHub API and per-PR human judgment — several are visibly superseded (#114 vs merged #78; #115/#125 duplicate the same LiveView bump in different dirs), #96 has a **real merge conflict** (F6), and #108 (`erlef/setup-beam`) is genuinely wanted. Blanket-merge and blanket-close are both wrong. | For each of #131, #130, #125, #124, #116, #115, #114, #112, #111, #108, #106, #96, #95: merge, or `gh pr close --comment "<reason>"`. Record every disposition in the phase artifact table. |
| Maintainer PR #132 state | — (out of VULN-02 scope) | Auto-merge armed and `BEHIND`, but not a *dependency* PR — the requirement says "dependency PR". | Flag its state in the phase artifact. Do **not** disposition it as part of VULN-02. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90 s
- [ ] Criteria 1b (D-14 gate), 1c, 2d and 4 executed once and their output recorded in SUMMARY.md
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
