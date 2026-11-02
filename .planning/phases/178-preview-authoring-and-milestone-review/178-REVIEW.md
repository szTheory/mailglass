---
phase: 178-preview-authoring-and-milestone-review
reviewed: 2026-10-29T00:00:00Z
depth: standard
base: 61e90275f01f9927d2f8ab3bbfd3ba7f9099dffc
files_reviewed: 24
files_reviewed_list:
  - mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex
  - mailglass_admin/lib/mailglass_admin/preview/scenario_label.ex
  - mailglass_admin/lib/mailglass_admin/preview/sidebar.ex
  - reference/persona_spec/quick_view_scenarios.ex
  - reference/persona_spec/quick_view_scenarios.json
  - reference/demo_app/storybook/preview_authoring.story.exs
  - reference/demo_app/assets/e2e/phase178-stories.spec.js
  - mailglass_admin/e2e/support/real-zoom.cjs
  - mailglass_admin/e2e/phase178-real-zoom.spec.js
  - mailglass_admin/e2e/structural.spec.js
  - mailglass_admin/e2e/flows.spec.js
  - mailglass_admin/e2e/axe-baseline.spec.js
  - mailglass_admin/test/support/feedback_ledger.ex
  - mailglass_admin/test/mailglass_admin/phase178_prohibition_contract_test.exs
  - scripts/check_phase178_candidate.sh
  - scripts/test_check_phase178_candidate.sh
  - scripts/phase178_cost_disposition.cjs
  - scripts/phase178_cost_disposition.test.cjs
  - test/mailglass/state_md_contract_test.exs
  - reference/demo_app/mix.lock
  - .planning/publish/mailglass_admin-files.expected
  - mailglass_admin/docs/phase174-review.md
  - mailglass_admin/test/mailglass_admin/preview_live_test.exs
  - mailglass_admin/test/mailglass_admin/feedback_ledger_test.exs
findings:
  critical: 0
  warning: 3
  info: 1
  total: 4
status: issues_found
---

# Phase 178: Code Review Report

**Reviewed:** 2026-10-29
**Depth:** standard
**Scope:** `git diff 61e90275..HEAD -- . ':(exclude).planning'` (31 files, 6531 insertions) against `CLAUDE.md` (Engineering DNA and Things Not To Do), decisions D-01 to D-15 and the plan threat registers.

## Summary

The product change is small and holds up: three `lib/` files, all in the Preview surface. The rest is test support, browser specs, the exact-SHA candidate launcher and the hosted-cost derivation. The defects that mattered were found by running the full local gate, not by reading the new code: the `mailglass_admin` package file allowlist had gone stale (so the `Mix Task Tests` CI Green need would have failed on the candidate), two browser pins still expected the old selector link name, and one axe producer spent 9 minutes timing out. All three are fixed.

Attack surfaces I traced:

- **Atom creation (CLAUDE.md "Things Not To Do", PRVUX-07).** `ScenarioLabel` only reads atoms that `Discovery` already returned; `humanize/1` and `technical/2` take atoms and produce strings. `MailglassDemo.QuickViewScenarios.preview_authoring/1` turns manifest strings into atoms only through the closed `@authoring_atoms` table, and an unknown name raises `ArgumentError` instead of calling `String.to_atom/1`. No new `String.to_atom` or `String.to_existing_atom` appears under `lib/`, `reference/` or `scripts/`; the only uses are in tests (`String.to_atom/1` once, to build a hostile fixture scenario, and `String.to_existing_atom/1` in two contract assertions), and the P-contract asserts that the production source contains no `String.to_atom`.
- **HTML escaping and hostile names.** Every label, technical identity and read-only note reaches the page through HEEx text or attribute interpolation. The `title={inspect(@mod)}` attribute is escaped. Scenario and Mailable names containing markup, RTL or combining characters are covered by `scenario_label_test.exs` ("hostile names escaped").
- **Label collisions.** `collision_key/1` compares NFC-normalized, downcased labels, and a colliding scenario falls back to its raw atom, so two options cannot read the same. `Map.fetch!(collisions, ...)` in `put_scenarios/3` is total because `collisions` is built from the same `humanized` map. `disambiguate/1` always terminates: `1..longest` ends at the full segment list, and the `nil` branch falls back to `inspect/1`.
- **Accessibility references.** The form-level note id (`preview-assigns-readonly-note`) is rendered exactly when `readonly_values?/1` is true and the editable branch renders, and every read-only display references it; `assert_ids_closed!/1` and the P2 contract test cover every state. The selector summary is `aria-labelledby` the visible identity element, so the accessible name equals the visible text (no label-in-name mismatch).
- **Behavior preserved (D-06).** `reset_assigns` and `preview_live.ex` are byte-identical to `phase_base_sha`; the P5 contract test asserts the restore and error-clear behavior.
- **Launcher safety (T-178-14 class).** `check_phase178_candidate.sh` validates the SHA as 40 hex, refuses ports 4015 and 5415 and the owner project name, scopes every `docker compose` call to its own project, and `--teardown` accepts only a `/tmp/mailglass-phase178.*` run parent whose worktree is `<parent>/candidate`. GitHub access is read-only `gh api`. No `git push`, `gh pr`, or `gh workflow` write exists in any new script.
- **Cost derivation.** `phase178_cost_disposition.cjs` reads local raw JSON, performs no network call, and writes only the paths it is given.
- **Gate integrity (T-178-21).** `git diff --stat 61e90275..HEAD` over `axe-baseline.json`, `storybook-axe-approved.json`, `check_phase174_evidence.cjs`, `.github/workflows`, `config/quality`, `config/test_exceptions.exs`, `.tool-versions` and `.planning/release-target.json` is empty. `reference/demo_app/mix.lock` changed once, by the orchestrator's lock refresh (`8c02bf7e`, bandit 1.14.1 and swoosh 1.29.3, resolving D-178-03-A), and it is not a gate file.

## Warnings

### WR-01: `mailglass_admin` package allowlist missing six shipped files (Mix Task Tests would fail on the candidate)

**File:** `.planning/publish/mailglass_admin-files.expected`
**Issue:** `mix mailglass.publish.check --allowlist-only`, a step of the `mix_task_tests` CI Green need, exited with `[conflict] compare allowlist` and `Delivery blocked: package files diff`. Six files that the admin package now ships were absent from the allowlist: `docs/phase175-review.md`, `lib/mailglass_admin/inbound/address_list.ex`, `lib/mailglass_admin/operator/filter_commit.ex`, `lib/mailglass_admin/operator/results_status.ex`, `lib/mailglass_admin/preview/return_context.ex` and `lib/mailglass_admin/preview/scenario_label.ex`. Phases 175 to 178 added them, and `.planning/publish/` is checked by the Mix Task Tests lane only on a PR, so no earlier phase saw it. This is the known allowlist-not-in-PR-CI class (project memory, "1.10.2 patch"). The hosted `CI Green` aggregate would have gone red, and the candidate cannot afford a rerun.
**Fix:** Copy the `.actual` list the task produced over the allowlist (six added lines, nothing removed), then re-run the lane. Done in `0c2d999b`.

### WR-02: Two browser pins still expect the old exact selector link name

**File:** `mailglass_admin/e2e/flows.spec.js:767` and `mailglass_admin/e2e/structural.spec.js:1064`
**Issue:** Plan 178-04 renders each selector option as a humanized label with the raw atom beneath it, so the link's accessible name is `Welcome default welcome_default`. Both specs located the link with `{ name: "welcome_default", exact: true }`, which no longer matches. Plan 178-04's targeted browser greps did not include these two cases ("Preview edge: index redirects into the unified scenario layout at 320" and "Operator replay modal, nav, preview theme controls, and preview summary controls meet target-size floor"), so the first full run of the Operator Browser Gate was the first to execute them. Each failed twice (one retry) at the 30 s timeout. The hosted Operator Browser Gate is advisory but would have gone red with titles that no recorded source matches, which stops plan 178-09.
**Fix:** Match the link by `/^Welcome default\s+welcome_default$/` in both specs. Done in `de8e21b8`.

### WR-03: The deliveries axe producer opens a Delivery that has no replay control

**File:** `mailglass_admin/e2e/axe-baseline.spec.js:111-120`
**Issue:** `openDeliveries` clicks `operator-delivery-row` `.first()`, then waits for `operator-replay-open`, which only the replayable Delivery renders. Every replay case in `flows.spec.js` selects the fourth visible row. The three cells "scan deliveries / light, dark, system" therefore waited 90 s per attempt with one retry each, 9 minutes in total. That is not a Phase 178 regression (plan 177-07 reproduced it at `03e2cc35`), but it matters to this candidate for two reasons. The one-worker run passed the test server's 20 minute sandbox-owner lifetime (`OperatorBrowserServer`), so every later case failed with a DB ownership error; and the hosted job has a 30 minute budget that the lost time would eat.
**Fix:** Select the fourth visible Delivery row, as the replay cases do. Done in `de8e21b8`. The overlay fold now opens the real dialog, which the producer's own WR-04 comment says it must.

## Info

### IN-01: A retained-input test passes by skipping on a clean checkout

**File:** `scripts/phase178_cost_disposition.test.cjs:302-305`
**Issue:** "reproduces the retained Phase 174 ci-job, cost enrichment and disposition from raw inputs" runs only when `reference/demo_app/tmp/demo_browser_evidence/ci/40498413906-attempt-1/ci-job.json` exists. That directory is untracked, so on a CI checkout the test skips (with an explicit `skip:` reason and a `skip: retained 174 inputs absent` line) and reports as skipped, not passed. The file is not in any `ci.yml` step, and the other cases in it (`validateCiJob`, `validateHostedCost`, the disposition table) run unconditionally from synthetic inputs.
**Fix:** None required. The skip is explicit and labeled, which is the honest form of a local-only fixture. Moving the retained inputs into git would add roughly the evidence directory's size to the repository for no gate benefit.

---

_Reviewed: 2026-10-29_
_Reviewer: Claude (inline standard-depth review; the `gsd-code-review` skill was not used because it commits through `gsd-sdk query commit`, which sweeps the owner's dirty `.planning` work)_
_Depth: standard_
