# CI Lane + Branch-Protection Recommendation (for CLOSE-02 / Phase 51)

> Synthesized 2026-05-24 during `/gsd-verify-work 47` from three parallel research
> agents (internal conventions + history; external Elixir CI test-lane idioms;
> external branch-protection idioms). Persisted here so Phase 51 (which owns
> CLOSE-02) executes a coherent, pre-researched plan instead of re-deriving it.
> **Q1 (mix-task/generator CI lane) was implemented during this session** (see
> "Status" below). **Q2 (branch protection) is recorded here for Phase 51** — it
> touches repo settings + needs a PAT, so it was deliberately NOT front-run.

## Status

- **Q1 — DONE (2026-05-24):** Added `verify.mix_tasks` alias (directory-scoped
  `test test/mix/tasks/`) + `Mix Task Tests (Elixir 1.18 / OTP 27)` ci.yml job.
  Closes the gap where all five `mix mailglass.gen.*` generator tests (inbound +
  outbound) ran only in the non-blocking `advisory-matrix.yml` full suite. Now
  publish-blocking automatically via `gate-ci-green`'s inverted allowlist.
- **Q2 — DEFERRED to Phase 51 / CLOSE-02 (this document is the plan).**

## Key facts that frame both decisions

1. **The core package deliberately does NOT run a blanket `mix test` in blocking
   CI.** Phase 34 (commit `6b4732f`, 2026-05-05) split the old monolithic `Tests
   (Elixir 1.18 / OTP 27)` job into concern-specific jobs (`Support Contract
   Core`, `Support Contract Admin`, `Compile No Optional Deps`, …) running
   curated `verify.*` aliases. Engineering DNA mandates "one `verify.<concern>`
   per focused concern — never a kitchen-sink verify task."
2. **The stale required-check string.** `scripts/setup_branch_protection.sh`
   still lists `"Tests (Elixir 1.18 / OTP 27)"` as required — a job name that
   **ceased to exist on 2026-05-05**. Phase 34 RESEARCH explicitly said this
   reference "should be removed during the manual branch-protection update."
3. **Branch protection was never live.** `044.5-BRANCH-PROTECTION-EVIDENCE.md`
   (2026-05-07): REST → 404 "Branch not protected", GraphQL `[]`, Rulesets `[]`.
   "configuration-never-installed." The drift workflow no-ops without
   `BRANCH_PROTECTION_PAT` (never set).
4. **The publish gate is the only functioning gate today.** `gate-ci-green` in
   `publish-hex.yml` blocks Hex publish unless every `ci.yml` job is green except
   those in `ADVISORY_LANES` (currently only `'Operator Browser Gate'`). Its own
   comment says "Re-strict after Phase 51 closeout."

## The footgun this fixes (authoritative)

GitHub matches required status checks by **exact job-name string**. Two failure
modes, depending on whether protection is applied:
- **Applied + name matches no job →** PRs block forever on "Expected — Waiting
  for status to be reported." (This is what the stale `"Tests…"` string would do
  if the script were ever run.)
- **Not applied (today) →** the required-check list is inert; nothing blocks; the
  repo *looks* protected (script + drift cron exist) but isn't.
- Bonus trap for matrix lanes: **a skipped required check counts as passing** —
  red upstream can merge through a `needs:`-skipped dependent.

Refs: GitHub Docs "Troubleshooting required status checks";
emmer.dev "Skippable GitHub Status Checks Aren't Really Required";
GitHub community discussions #26698, #54877.

## Recommended Q2 approach: aggregator gate + minimal protection (prefer Ruleset)

**The structural root-cause fix is the aggregator / "all-green" gate pattern** —
used by aiohttp, attrs, structlog, pytest, PyCA cryptography, pip-tools,
setuptools (mature, security-sensitive, small/solo-team OSS, the closest analogs
to mailglass).

1. **Add one aggregator job** to `ci.yml` (name it `CI` or `ci-required`) that
   `needs:` every gating lane and runs `if: always()`:
   ```yaml
   ci:
     if: always()
     needs: [format_check, compile_warnings, compile_no_optional_deps,
             support_contract_core, mix_task_tests, inbound_test,
             inbound_compile_no_optional_deps, credo_strict, dialyzer,
             docs_warnings_as_errors, hex_audit, installer_golden_gate,
             support_contract_admin]
     runs-on: ubuntu-latest
     steps:
       - uses: re-actors/alls-green@release/v1
         with:
           jobs: ${{ toJSON(needs) }}
           allowed-failures: ''   # advisory lanes (e.g. Operator Browser Gate) go here
   ```
   - `re-actors/alls-green` correctly fails when a dependency fails (a naive
     `if: always()` + `needs:` job reports success even when deps fail — the sharp
     edge alls-green exists to handle). Pure-bash alternative:
     `if: contains(needs.*.result, 'failure') || contains(needs.*.result, 'cancelled') → exit 1`.
   - `allowed-failures` maps 1:1 onto the existing "Fake adapter blocks /
     real-provider sandbox is advisory" rule (D-13) — list advisory lanes there.
2. **Delete the per-job name list** from `setup_branch_protection.sh` (including
   the dead `"Tests…"` string). Branch protection requires **only `ci`**. Lane
   renames/additions never touch protection again — you only edit the `needs:`
   list (reviewed as code in the PR). The new `Mix Task Tests` lane from Q1 is
   just one more `needs:` entry.
3. **Actually apply protection — minimal solo-maintainer settings:**
   - Required status check: **`ci` only**, strict (up-to-date) = **off** (friction
     with little payoff at this scale).
   - Required approving reviews: **0** — a solo maintainer cannot approve their
     own PR; requiring ≥1 with no second human is a self-lockout.
   - `allow_force_pushes: false`, `allow_deletions: false` (the safety floor).
   - Admin enforcement: keep an escape hatch. Prefer a **Ruleset bypass list**
     (add the maintainer with audited bypass) over the blunt `enforce_admins`
     toggle. Current script's `enforce_admins: false` is the honest single-eye
     posture documented in MAINTAINING.md — don't silently strengthen it.
4. **Prefer migrating to a committed Repository Ruleset (JSON) over the bash +
   REST + drift-cron + PAT machinery.** Rulesets are API-first, layerable, have
   bypass lists, are visible to read-access users, and export/import as JSON
   (one stable artifact applied once via `gh api …/rulesets --input ruleset.json`).
   This retires the PAT-expiry / cron-no-op fragility entirely. Caveat: ruleset
   **"Evaluate" (dry-run) mode and org "required workflows" are Enterprise-only**;
   on a personal repo rulesets are just Active/Disabled — the wins here are bypass
   lists + visibility + clean JSON, not the Enterprise governance features.
5. **5-min precondition (cheap insurance):** `git log` / issue check on *why*
   protection was never applied (PAT never provisioned vs. an earlier
   `enforce_admins` lockout someone backed out of) before applying — so we don't
   re-introduce a problem already discovered.

This satisfies CLOSE-02's stated acceptance (repo-as-code OR documented owner
runbook) while eliminating the name-drift class of bug rather than patching one
instance of it.

## Why NOT the alternatives for Q2

- **(A) Just flag it:** leaves `main` ungated + the script misleading; the stale
  name stays a tripwire. Lowest cost now, highest cost later.
- **(B) Fix the stale names in the script:** restores a gate but re-arms the same
  brittleness (next rename re-breaks it) and still depends on the unset PAT.
  Treats the symptom; the Q1 lane addition alone would already make the list
  stale again.

## Q1 rationale (already implemented) — for the record

- **Directory-scoped, not file-enumerated.** Every successful Elixir lib (Ecto,
  Phoenix, Oban, Plug, Broadway, Absinthe, Finch, Ash/Igniter) runs generator/
  mix-task tests via the whole suite, a directory path, or `@moduletag` + `--only`
  — **never a hand-maintained file list.** Enumerated lists are the drift footgun
  (new file silently escapes CI). `test test/mix/tasks/` auto-includes new files,
  is non-vacuous, and avoids the `--only` zero-match vacuity risk Phase 34 warned
  about (`34-03-PLAN.md:118` "no `--only` tag gates, no merged root `mix test`").
- **Igniter generator tests are in-memory** (`Igniter.Test`) — no subprocess, no
  DB of their own; but the core `test_helper` boots `Mailglass.TestRepo`, so the
  CI job still provisions Postgres + `mix ecto.create`.
- **Dedicated job, not folded into `Support Contract Core`** — keeps one focused
  concern per check (engineering DNA); a generator regression shows as
  `Mix Task Tests ❌`, not hidden under a "support contract" label.
- **Follow-up worth considering (not blocking):** the existing
  `verify.support_contract.core` / `verify.provider_compatibility` aliases are
  themselves file-enumerated and carry the same drift risk. Consider migrating
  them to directory/tag scope, or add a meta-test that globs each directory and
  asserts no `*_test.exs` is missing from its alias, so drift fails loudly.

## Sources

- re-actors/alls-green: https://github.com/re-actors/alls-green
- Skippable status checks: https://emmer.dev/blog/skippable-github-status-checks-aren-t-really-required/
- GitHub required status checks troubleshooting: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/collaborating-on-repositories-with-code-quality-features/troubleshooting-required-status-checks
- GitHub Rulesets: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets
- Branch-protection solo-maintainer guide: https://mcginniscommawill.com/posts/2026-03-24-github-branch-protection-deep-dive/
- Mix.Tasks.Test (directory paths): https://hexdocs.pm/mix/Mix.Tasks.Test.html
- Igniter.Test harness: https://hexdocs.pm/igniter/Igniter.Test.html
- Ecosystem CI: Ecto, Phoenix, Oban, Plug, Broadway, Absinthe, Finch, Bandit, Ash/Igniter `.github/workflows/` (see agent report)
