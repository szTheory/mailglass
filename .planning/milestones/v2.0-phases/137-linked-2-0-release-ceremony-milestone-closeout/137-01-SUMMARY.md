---
phase: 137-linked-2-0-release-ceremony-milestone-closeout
plan: 01
subsystem: release-pipeline
tags: [release, dep-pins, reference-baseline, schema-isolation, 2.0]
requires:
  - v1.15 loosened-`~>` keystone (no `==` re-pin)
  - Phases 132–136 schema-isolation behavior (shipped, not built here)
provides:
  - "Sibling mix.exs core pins at ~> 2.0 (admin + inbound) so the 2.0 publish fan-out can version-solve"
  - "Reference baseline (host_app + demo_app) mix.exs advanced to ~> 2.0, dogfooding the mailglass default schema"
affects:
  - Plan 02 (release-please PR + publish fan-out) — depends on these pins landing on main first
  - Plan 02 post-publish consumer/baseline re-resolve — owns the deferred lock regeneration
tech-stack:
  added: []
  patterns:
    - "Pessimistic `~> 2.0` sibling pin (loosened, never `==`)"
    - "Coordinated reference-baseline major advance = mix.exs now, mix.lock deferred until siblings are on Hex"
key-files:
  created:
    - .planning/phases/137-linked-2-0-release-ceremony-milestone-closeout/deferred-items.md
  modified:
    - mailglass_admin/mix.exs
    - mailglass_inbound/mix.exs
    - reference/host_app/mix.exs
    - reference/demo_app/mix.exs
decisions:
  - "Lock regeneration DEFERRED to Plan 02 post-publish (2.0 not yet on Hex); locks left untouched, no fabricated entries"
  - "No `config :mailglass, :schema, \"public\"` pin added — baseline dogfoods the real 2.0 default (D-07)"
  - "Dropped inbound's `and >= 1.10.2` floor; no analog on the 2.0 line (D-05)"
metrics:
  duration: ~7m
  completed: 2026-07-03
status: complete
---

# Phase 137 Plan 01: Pre-release 2.0 dep-pin edits + reference-baseline advance Summary

Hand-landed the load-bearing pre-release edits release-please cannot make on its own — advanced both sibling `mix.exs` core pins and the two reference-baseline apps from the 1.x line to `~> 2.0` — so the Plan 02 publish fan-out can version-solve against a 2.0 core, with reference-baseline lock regeneration deliberately deferred until the 2.0 siblings are actually on Hex.

## What Was Built

- **Task 1 (D-03, D-05):** `mailglass_admin/mix.exs` and `mailglass_inbound/mix.exs` `MIX_PUBLISH == "true"` branches of `mailglass_dep/0` both now pin `{:mailglass, "~> 2.0"}`. Inbound's `and >= 1.10.2` floor was dropped entirely (it only ever excluded the broken 1.10.0/1.10.1 core builds; no analog on the fresh 2.0 line). The loosened `~>` form is preserved — no `==` re-pin was reintroduced, keeping the v1.15 keystone win. Explanatory head-comments were refreshed to name the 2.0 boundary. Path-dep local-dev branches and admin's optional `mailglass_inbound` sibling dep (`~> 1.1`) were left untouched.
- **Task 2 (D-06, D-07):** `reference/host_app/mix.exs` (3 constraints) and `reference/demo_app/mix.exs` (`mailglass_dep/0`, `mailglass_admin_dep/0`, `mailglass_inbound_dep/0` hex branches) advanced `~> 1.0` → `~> 2.0`. No `:schema "public"` opt-out added — the frozen baseline dogfoods the real 2.0 default (tables land in `mailglass.*`). `check_clean_baseline_hex_only.sh` and `ci_trust_lane_contract_test.exs` were left untouched (version-agnostic).
- **Task 3 (D-07):** Ran the clean-baseline guard and the trust-lane contract test to confirm the version move introduces no schema-qualified regression.

## Lock-regeneration path taken (required record)

**DEFERRED to Plan 02 post-publish.** The `~> 2.0` siblings are not yet on Hex (current baseline lock resolves `mailglass` 1.7.0 / `mailglass_admin` 1.7.0 / `mailglass_inbound` 1.4.0). `mix deps.get` in `reference/host_app` fails version-solving with `Because "your app" depends on "mailglass ~> 2.0" which doesn't match any versions`. Per the plan's explicit executor note, only the `mix.exs` constraint bumps were landed now; **both `mix.lock` files were left untouched** — no fabricated entries for unpublished versions, no transitive drift. The failed resolve wrote nothing to the locks (verified: `git status` showed only the two `mix.exs` files modified). Lock re-resolution is the Plan 02 post-publish consumer/baseline verification step.

## Trust-journey / clean-baseline verification split

- **Clean-baseline guard (`check_clean_baseline_hex_only.sh mix.lock` in `reference/host_app`): PASS** (exit 0). All three siblings resolve via `:hex` (1.7.0 / 1.7.0 / 1.4.0 — the unchanged, still-valid baseline lock).
- **Trust-lane contract test (`ci_trust_lane_contract_test.exs`): 4/5 pass.** The one failure (`refute job =~ ~r/^    if:/m` at `:8`) asserts the `ci.yml` trust-lane job carries no job-level `if:` gate; the job now has `if: needs.changes.outputs.code == 'true'`.
- **The FULL trust-journey lane** (which resolves siblings from Hex via `mix verify.reference_host.journey`) is re-verified empirically in **Plan 02 post-publish**, since it needs the published 2.0 artifacts.

## Schema-qualified contract update under D-07

**None.** No schema-qualified drift occurred. The single trust-lane test failure is a `ci.yml` job-structure assertion — orthogonal to table location — not a `public.*` → `mailglass.*` expectation drift. No contract expectation was updated, and (correctly) no `:schema "public"` pin was added to make an old shape reappear. D-07's anticipated checkpoint-contract drift did not materialize in the subset runnable pre-publish; it is re-checked in Plan 02.

## Deviations from Plan

### Auto-fixed Issues
None — plan executed as written.

### Out-of-Scope / Deferred (logged to deferred-items.md)

**1. [Scope boundary] Pre-existing trust-lane contract test failure**
- **Found during:** Task 3
- **Issue:** `ci_trust_lane_contract_test.exs:8` fails its `refute job =~ ~r/^    if:/m` assertion — the trust-lane job in `ci.yml` carries a job-level `if: needs.changes.outputs.code == 'true'` gate.
- **Why not fixed:** Neither `ci.yml` nor the contract test was modified by Plan 01 — both are byte-identical to the pre-plan commit `98cc27b1`. The failure is fully orthogonal to this plan's scope (`~> 2.0` pins + schema adoption) and is NOT schema-qualified drift (D-07). Per the SCOPE BOUNDARY rule, only issues directly caused by this task's changes are auto-fixed. Logged to `deferred-items.md` for a future CI-hygiene pass.
- **Files modified:** none

**2. [Plan-directed deferral] Reference-baseline lock regeneration**
- **Found during:** Task 2
- **Issue:** `mix deps.get` cannot resolve `~> 2.0` — the siblings are not on Hex until Plan 02.
- **Resolution:** Deferred per the plan's explicit executor note. Landed the `mix.exs` bumps; left both locks untouched. Owned by Plan 02 post-publish re-resolve.
- **Files modified:** none (locks intentionally unchanged)

## Known Stubs
None.

## Threat Flags
None — no new security surface. This is a release-ops setup plan; the threat register (T-137-01..04) was honored: no `==` inbound re-pin (T-137-01), sibling `~> 2.0` pins landed on main before the RP PR opens (T-137-02), locks left drift-free (T-137-03), no schema-qualified drift to suppress (T-137-04).

## Commits
- `c65f6438` chore(137-01): pin sibling core deps to ~> 2.0 (D-03, D-05)
- `0f66a71c` chore(137-01): advance reference baseline to ~> 2.0 (D-06, D-07)

## Self-Check: PASSED
- FOUND: mailglass_admin/mix.exs core pin `{:mailglass, "~> 2.0"}`
- FOUND: mailglass_inbound/mix.exs core pin `{:mailglass, "~> 2.0"}` (floor dropped, no `==`)
- FOUND: reference/host_app/mix.exs — 3× `~> 2.0`
- FOUND: reference/demo_app/mix.exs — 3× `~> 2.0`
- FOUND: no `:schema "public"` pin in either reference app
- FOUND: commit c65f6438
- FOUND: commit 0f66a71c
