---
phase: 179-compatibility-policy-status-map-and-brand-pin
plan: 02
subsystem: docs-governance
tags: [compatibility-policy, api-stability, contract-test, mutation-proof, brand-v2, elixir]

requires:
  - phase: 179-01
    provides: "test/mailglass/outbound/suppressed_not_persisted_test.exs, the proof file the Not sent section cites"
provides:
  - "docs/brand-v2-compatibility.md: 26-row machine-readable stays table, gloss table, Not sent answer, same-atom note, pinned-test list, links to the three stability inventories"
  - "MailglassAdmin.BrandV2CompatPolicyTest: table parser, seven-kind verifier, reverse check over Mailglass.Operator.*, duplicate, required-name and cited-path guards, per-kind teeth"
  - "docs/api_stability.md pointer to the policy by absolute URL"
affects: [180-reproducible-bundle, 181-tokens-fonts-logo, 182-on-screen-words, 183-announcement-gate]

actuals:
  tokens: 8633
  tasks: 2
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Marker-delimited markdown table parsed by the test that guards it, with no second list"
    - "Subset check by kind plus a reverse check, so removals fail and additions force a decision"
    - "Self-checks assert membership of the planted failure, not equality with the whole result, so a broken table reddens only the real alarm test"

key-files:
  created:
    - docs/brand-v2-compatibility.md
    - mailglass_admin/test/mailglass_admin/brand_v2_compat_policy_test.exs
  modified:
    - docs/api_stability.md

key-decisions:
  - "The policy lives at repo-root docs/, in no Hex files list and not an ExDoc extra, so neither tarball allowlist changes (publish check conflict=0 for all three packages)"
  - "api_stability.md links to the policy by absolute GitHub URL; a relative .md link to a non-extra fails the required docs build"
  - "Names are compared as exact binaries after trimming ASCII whitespace and one pair of backticks; the parser rejects a malformed row, a changed header and a missing separator instead of skipping them"
  - "grep rows accept :atom or atom: keyword form; proof paths must be repo-relative (Path.safe_relative)"
  - "Atoms in verifier names are looked up with String.to_existing_atom, so a typo in the doc reads as not exported and never mints atoms"

requirements-completed: [BRPOL-01]

coverage:
  - id: T1
    description: "Every public name in the policy exists in live code by its kind; removing one turns the test red with a message naming docs/brand-v2-compatibility.md"
    requirement: BRPOL-01
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/brand_v2_compat_policy_test.exs#compat table every row verifies against live code"
        status: pass
    human_judgment: false
  - id: T2
    description: "Reverse check: every Mailglass.Operator.* module in Application.spec has a module row"
    requirement: BRPOL-01
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/brand_v2_compat_policy_test.exs#compat table every Mailglass.Operator module has a module row"
        status: pass
    human_judgment: false
  - id: T3
    description: "False-green guards: markers, empty table, required names, tenant_id homes, duplicates, exact-binary cells, row-order independence, read-only async test"
    requirement: BRPOL-01
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/brand_v2_compat_policy_test.exs#parser, teeth, compat table"
        status: pass
    human_judgment: false
  - id: T4
    description: "Each guard goes red under a recorded mutation and is restored"
    requirement: BRPOL-01
    verification:
      - kind: other
        ref: "Mutation run section below: N1-N5 with exit codes and red excerpts"
        status: pass
    human_judgment: false
  - id: T5
    description: "api_stability.md points at the policy and the required docs lane stays green"
    requirement: BRPOL-01
    verification:
      - kind: other
        ref: "MIX_ENV=dev mix docs --warnings-as-errors and mix mailglass.docs.check, both exit 0"
        status: pass
    human_judgment: false

duration: 10min
completed: 2026-11-14
status: complete
plan_head_before: f5c707e961d09adbe7960071c11985a1d906f0c9
plan_head_after: bcf802a1519e864861e8741e0e23bc4f6d151fca
---

# Phase 179 Plan 02: Brand v2 Compatibility Policy Summary

**A repo-root policy doc whose 26-row "stays" table is parsed and verified against live code by an admin test (seven kinds, a reverse check over `Mailglass.Operator.*`, false-green guards, five recorded mutations), with the Not sent answer, the gloss table and the pinned-test list written down and `docs/api_stability.md` pointing at it.**

## Performance

- **Duration:** about 10 min wall clock (started 2026-11-14T05:08:16Z)
- **Tasks:** 2 (Task 1 a tracer slice, Task 2 the full inventory), plus one test refinement commit
- **Files:** 3 (2 created, 1 modified)

## Accomplishments

- `docs/brand-v2-compatibility.md` lists every name that stays: the seven `Mailglass.Operator.*` modules, `mailglass_operator_routes/1` and `/2`, `SupportSummary.read_orphan_backlog/1`, the `Delivery.status` (5), `Event.type` (20) and `reject_reason` (7) enums, `tenant_id` on three schemas plus the router session key and the Operator mount URL param, the `mailglass:deliveries:#{tenant_id}` topic, `:operator_access`, `:orphan_backlog`, two telemetry names and the router options `deliveries_path`, `live_session_name`, `account_labels`.
- The doc states the rule that on-screen and docs words are glossed, never renamed, with a four-row gloss table (Operator to Admin, Tenant to Account, Deliveries to Activity, orphan / unmatched to "provider reports match no email"), the Not sent answer with its citations, the same-atom note for inbound outcomes, the four tests that pin the current words, and links to the three stability inventories.
- `MailglassAdmin.BrandV2CompatPolicyTest` (28 tests, `async: true`, read-only) parses the table and verifies each row by kind, runs the reverse check, and refuses a false green (markers, empty table, malformed row, changed header, required names, tenant_id homes, duplicates, cited paths that do not exist).
- `docs/api_stability.md` carries one pointer sentence with an absolute URL; the docs build and docs check stay green.

## Task Commits

1. **Task 1 (tracer): one row parsed from the doc and verified against live code** - `0417ede7` (docs)
2. **Task 2: full inventory, every verifier kind, reverse check, prose sections, api_stability pointer** - `ffe877b3` (docs)
3. **Test refinement: isolate self-checks from table health** - `bcf802a1` (test)

**Plan metadata:** recorded in the final docs commit that carries this file.

Commit count is measured from the ledger (`git rev-list --count f5c707e9..HEAD` returned 3 at SUMMARY write), not narrated.

## Verification

All run with `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27`.

- **Policy test, `cd mailglass_admin && mix test test/mailglass_admin/brand_v2_compat_policy_test.exs --warnings-as-errors`:** 28 tests, 0 failures.
- **With the neighbours the plan names (`operator_trust_doc_test.exs`, `stability_contract_test.exs`):** 35 tests, 0 failures (run before the refinement commit; the refinement changed only the policy test's self-checks).
- **Admin lane, `cd mailglass_admin && mix verify.support_contract.admin`:** 1292 tests (1264 after plan 01 plus 28), 0 failures, 1 excluded, exit 0. This lane proves BRPOL-01 (required via `ci_green`).
- **Core `mix test test/mailglass/docs_contract_test.exs --warnings-as-errors`:** exit 0 (61 total, 60 executed, 0 failures).
- **`MIX_ENV=dev mix docs --warnings-as-errors`:** exit 0, no "documentation references file" and no `warning:` lines.
- **`MIX_ENV=dev mix mailglass.docs.check`:** exit 0, "Tier 1 docs match the stability contract".
- **`MIX_ENV=test mix mailglass.publish.check --allowlist-only`:** `conflict=0` for mailglass, mailglass_admin and mailglass_inbound (no tarball change).
- **`mix format --check-formatted`:** exit 0 at the repo root and inside `mailglass_admin`.
- **Acceptance greps:** table rows in the marker region 27 (header plus 26), `grep -c "brand-v2-compatibility.md" docs/api_stability.md` 1, relative-link guard 0, `File.write|Application.put_env` 0, `async: true` 1, `compat-table:start` 1.

## Mutation run

Each mutation was applied to a tracked file, the policy test was run, the file was restored with `git checkout -- <file>`, and the test was re-run green. All commands run from `mailglass_admin/`: `mix test test/mailglass_admin/brand_v2_compat_policy_test.exs --warnings-as-errors`. Excerpts are verbatim from the run logs.

The first run of N1 to N4 (against the commit `ffe877b3` test) gave two failures each, because two self-checks (the row-order test and the reverse-check teeth) were coupled to the health of the real table. Those self-checks were refined in `bcf802a1` to assert membership of the planted failure, and N1 to N4 were re-run in full against the final test. The record below is the second run.

**N1 - add a module row `Mailglass.Operator.Bogus` to the doc** (expects the subset check red)
- Edit: `docs/brand-v2-compatibility.md`, one row inserted after the `Mailglass.Operator.Timeline` row.
- Result: exit **2**, `28 tests, 1 failure`: `compat table every row verifies against live code`.
- Red excerpt: `docs/brand-v2-compatibility.md lists public names that the code no longer provides:` / `- Mailglass.Operator.Bogus (module): module Mailglass.Operator.Bogus is not loaded`.
- Restore: `git checkout -- docs/brand-v2-compatibility.md`. Post-restore: exit 0, `28 tests, 0 failures`.

**N2 - delete the `Mailglass.Operator.Tenants` row** (expects the reverse check red)
- Edit: the row removed from the table.
- Result: exit **2**, `28 tests, 1 failure`: `compat table every Mailglass.Operator module has a module row`.
- Red excerpt: `docs/brand-v2-compatibility.md has no module row for ["Mailglass.Operator.Tenants"]. A new Operator module needs a decision: add a row, which commits to keeping the name.`
- Restore: `git checkout -- docs/brand-v2-compatibility.md`. Post-restore: exit 0, `28 tests, 0 failures`.

**N3 - add `:bogus` to the `Delivery.status` proof list** (expects the enum subset check red)
- Edit: `[:queued, :sent, :dispatched, :failed, :suppressed]` to `[..., :suppressed, :bogus]`.
- Result: exit **2**, `28 tests, 1 failure`: `compat table every row verifies against live code`.
- Red excerpt: `- Mailglass.Outbound.Delivery.status (enum): [:bogus] are not live Mailglass.Outbound.Delivery.status values (live values: [:queued, :sent, :dispatched, :failed, :suppressed])`.
- Restore: `git checkout -- docs/brand-v2-compatibility.md`. Post-restore: exit 0, `28 tests, 0 failures`.

**N4 - point the `:operator_access` proof at `lib/mailglass/suppression.ex`** (expects the grep check red; that file contains no `operator_access`)
- Edit: the proof cell of the `:operator_access` row.
- Result: exit **2**, `28 tests, 1 failure`: `compat table every row verifies against live code`.
- Red excerpt: `- :operator_access (grep): :operator_access not found in lib/mailglass/suppression.ex`.
- Restore: `git checkout -- docs/brand-v2-compatibility.md`. Post-restore: exit 0, `28 tests, 0 failures`.

**N5 - delete the name from the code** (added beyond the plan: proves the stated prohibition from the code side)
- Edit: in `mailglass_admin/lib/mailglass_admin/auth.ex`, `@type action :: :operator_access | :destructive_action | atom()` to `@type action :: :destructive_action | atom()`.
- Result: exit **2**, `28 tests, 1 failure`: `compat table every row verifies against live code`.
- Red excerpt: `- :operator_access (grep): :operator_access not found in mailglass_admin/lib/mailglass_admin/auth.ex`.
- Restore: `git checkout -- mailglass_admin/lib/mailglass_admin/auth.ex`. Post-restore: exit 0, `28 tests, 0 failures`.

After the run, `git status --short` shows only the orchestrator's `.planning/state.json` edit; no mutation was left behind.

## Docs lane latency

Measured with `time` on a warm dev build, machine load average 20 to 47 (shared, heavily loaded):

| Command | Real seconds | User / sys |
|---------|--------------|------------|
| `MIX_ENV=dev mix docs --warnings-as-errors` | **11.8 s** | 3.59 s / 2.68 s |
| `MIX_ENV=dev mix mailglass.docs.check` | **2.2 s** | 0.65 s / 0.78 s |

Later plans can budget about 14 s for both gates on a warm build; a cold build adds the dev compile.

## RED run (TDD)

Task 2 is `tdd="true"` and `workflow.tdd_mode` is off, so the plan prescribes one commit. The fail-first check was still run: the full Task 2 test was run against the committed one-row Task 1 doc (the new doc kept aside in the session scratchpad, the file restored with `git checkout --`, then the new doc copied back). Result: `28 tests, 10 failures` (reverse check, required names, tenant_id homes, cited paths, gloss table, the stability links and the deleted-row teeth). With the full doc: `28 tests, 0 failures`.

## Decisions Made

- The test parses strictly: a malformed row, a changed header or a missing separator is an error naming the cause, never a skipped line.
- `Event.type` lists all 20 live atoms in the proof cell with subset semantics, so adding an event type never fails this test; removing one does.
- Verifier names are checked with `String.to_existing_atom`, so a typo in the doc is reported as "not exported" and creates no atoms.
- The required-name guard is a minimum-content check, not the verification list: the table remains the only list of names that are verified.
- `tenant_id` has its own guard (three schema rows, the router session key row, the Operator mount URL param row, the topic row) because a bare "contains tenant_id" would pass with any one of them.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Self-checks coupled to table health**
- **Found during:** Task 2 mutation run (first pass of N1 to N4)
- **Issue:** the row-order self-test and three reverse-check, duplicate and required-name teeth tests asserted equality with the whole result computed from the real table, so one broken row reddened two tests and made the mutation excerpts ambiguous about which test was the alarm.
- **Fix:** assert membership of the planted failure instead of equality, so only the real alarm test goes red.
- **Files modified:** `mailglass_admin/test/mailglass_admin/brand_v2_compat_policy_test.exs`
- **Commit:** `bcf802a1`

### Additions inside scope (not deviations)

- Beyond the plan's list: a malformed-row and changed-header parser test, a per-kind teeth test over 16 planted bad rows (each asserting the reason names the cause), a cited-path scan teeth test, a `tenant_id` homes guard, a required-citation test, and the code-side mutation N5.
- Task 2's mutations were run after its commit (so `git checkout --` restores the committed doc), and the self-check refinement is a third commit. The plan listed two commits; the extra one carries only the fix above.

**Total deviations:** 1 auto-fixed (Rule 1). **Impact on plan:** none on scope or requirements.

## Known limits (recorded, not stubs)

- The router option rows (`deliveries_path`, `live_session_name`, `account_labels`) are plain substring greps of `router.ex`. They prove the name is still spelled in the router source, not that the operator macro still accepts the option; `live_session_name` also appears in the preview schema, so the grep cannot tell the two apart. A stronger check would need the private NimbleOptions schema or a compiled sample router.
- Grep proofs for atoms accept the `:atom` and `atom:` forms anywhere in the file, including comments.

## Issues Encountered

None. The shared machine was loaded (load average 20 to 47) but every run finished well inside its limit.

## Known Stubs

None. No placeholder data, no `TODO`/`FIXME`, no skipped tests in the new files.

## Threat Flags

None. The plan added a doc, a read-only test and one doc sentence: no endpoint, auth path, file write or trust-boundary schema change, and no telemetry metadata. `mix.lock` files are untouched. T-179-04 and T-179-05 are mitigated as planned (guards plus the recorded mutation run; subset plus reverse check).

## User Setup Required

None.

## Next Phase Readiness

- The 182 and 183 work that changes words on screens and in docs now has a tested list of public names that must not move and a gloss table that defines the vocabulary; enforcement on an allowlist of screens and docs stays with those phases, and the four pinned tests are named in the doc so they are left unedited.
- Adding a new `Mailglass.Operator.*` module now fails `compat table every Mailglass.Operator module has a module row` until a row is added, which is the intended decision point.

---
*Phase: 179-compatibility-policy-status-map-and-brand-pin*
*Completed: 2026-11-14*

## Self-Check: PASSED

- Created files `docs/brand-v2-compatibility.md` and `mailglass_admin/test/mailglass_admin/brand_v2_compat_policy_test.exs` exist, as does the modified `docs/api_stability.md`.
- Commits `0417ede7`, `ffe877b3` and `bcf802a1` are ancestors of HEAD.
- The required sections (Mutation run with N1 to N4, Docs lane latency) are present.
