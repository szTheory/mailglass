---
phase: 125-sibling-pin-loosening-keystone-atomic
plan: "01"
subsystem: release-pipeline
tags: [pin-loosening, publish-check, release-please, stability-contract, changelog]
dependency_graph:
  requires: []
  provides: [PIN-01, PIN-02, PIN-03, PIN-04, PIN-05]
  affects: [mailglass_inbound/mix.exs, mailglass_admin/mix.exs, release-please.yml, publish.check, stability_contract_test]
tech_stack:
  added: []
  patterns:
    - "Shared private predicate `mailglass_constraint_admits_core?/2` built on `Version.match?/2` for admit-~>-reject-== contract"
key_files:
  created: []
  modified:
    - mailglass_inbound/mix.exs
    - mailglass_admin/mix.exs
    - lib/mix/tasks/mailglass.publish.check.ex
    - test/mailglass/stability_contract_test.exs
    - mailglass_admin/test/mailglass_admin/mix_config_test.exs
    - .github/workflows/release-please.yml
    - .planning/publish/mailglass_inbound-publish-summary.json
    - .planning/publish/mailglass-publish-summary.json
    - .planning/publish/mailglass_admin-publish-summary.json
    - CONTRIBUTING.md
    - CHANGELOG.md
    - mailglass_admin/CHANGELOG.md
    - mailglass_inbound/CHANGELOG.md
    - MAINTAINING.md
  deleted:
    - test/fixtures/release_please_sed_test.sh
    - test/fixtures/mix_exs_release_please_sed/mix.exs.before
    - test/fixtures/mix_exs_release_please_sed/mix.exs.after
decisions:
  - "Inbound pin: ~> 1.10 and >= 1.10.2 (floor excludes broken 1.10.0/1.10.1 deliveries-migration core versions — mirrors Ash ~> 3.5 and >= 3.5.13 precedent)"
  - "Admin pin: ~> 1.10 (bare ~> safe because admin is in the linked-versions release group)"
  - "Shared predicate mailglass_constraint_admits_core?/2 used by both verify_deps and verify_linked_constraint in publish.check"
  - "Removed mailglass_admin/mix.exs and mailglass_inbound/mix.exs from SYNC_PATHS in release-please.yml (no longer modified per release)"
  - "Auto-fixed: stability_contract_test line 86 asserted PINS array entry that was deleted — updated to assert inbound README + publish-summary presence instead"
metrics:
  duration: "~25 minutes"
  completed: "2026-07-01"
  tasks_completed: 3
  files_changed: 17
status: complete
---

# Phase 125 Plan 01: Sibling Pin Loosening (Keystone Atomic Change) Summary

Replace both sibling `{:mailglass, "== X.Y.Z"}` exact pins with pessimistic `~>` constraints and retire every gate enforcing exact equality — as ONE indivisible atomic change unblocking hands-free core patch releases.

## What Was Built

### Task 1: Loosen both sibling pins + relax publish.check gates (PIN-01, PIN-02)

**`mailglass_inbound/mix.exs`** — `mailglass_dep/0` MIX_PUBLISH branch:
- Before: `{:mailglass, "== 1.10.2"}`
- After: `{:mailglass, "~> 1.10 and >= 1.10.2"}`

The dated trap comment (lines ~114-136) describing the transient-RED re-pin window was rewritten to describe the new `~>` reality: the window is gone, a core patch no longer requires a paired inbound release.

**`mailglass_admin/mix.exs`** — `mailglass_dep/0` MIX_PUBLISH branch:
- Before: `{:mailglass, "== 1.10.2"}`
- After: `{:mailglass, "~> 1.10"}`

The associated comment was updated to explain why bare `~> 1.10` is safe (admin is in the linked-versions group).

**`lib/mix/tasks/mailglass.publish.check.ex`** — `verify_deps/1` and `verify_linked_constraint/1`:
- Replaced the `"== " <> version when version == ctx.root_version` accept-branches with calls to a new shared private predicate `mailglass_constraint_admits_core?/2`
- Predicate: `not String.starts_with?(req, "==") and Version.match?(core_version, req)`
- On the accept path, `verify_deps` records the actual `~>` requirement string (not `"== #{version}"`) into the `sibling_publish_pin_key` context field — so `mailglass_inbound_publish_pin` in the regenerated summary carries the `~>` string
- Brand-voice failure messages for `==` pin and `~>` that doesn't admit core version

### Task 2: Delete == sed rewrites + retire three dead gates (PIN-02, PIN-03)

**`.github/workflows/release-please.yml`**:
- Deleted: `echo "Target dep pin: {:mailglass, \"== $CORE_VERSION\"}"` (~:161)
- Deleted: `PINS=(...)` array with `mailglass_admin/mix.exs:mailglass` and `mailglass_inbound/mix.exs:mailglass` entries
- Deleted: the `for entry in "${PINS[@]}"` loop with the sed-anchor exit-1 guard and the `sed -i -E "s/\{:${dep}, \"== ...\".../"` rewrite (~:170-185)
- Deleted: `mailglass_admin/mix.exs` and `mailglass_inbound/mix.exs` from `SYNC_PATHS` (no longer modified per release)
- **Definite edit (1)**: summary-jq `--arg pin` changed from `"== ${CORE_VERSION}"` to `"~> ${CORE_MM} and >= ${CORE_VERSION}"` (where `CORE_MM` derives from `CORE_VERSION`)
- **Definite edit (2)**: release commit message changed from `"sync sibling mailglass dep pins to == $CORE_VERSION + inbound README pin"` to `"sync inbound README \`~>\` pin + publish-summary to core $CORE_VERSION"`
- Kept intact: all `~>` README/installer sed rewrites (inbound README, core/admin READMEs, inbound-install.md)
- Updated leading comment to accurately describe CORE_VERSION's role in the surviving rewrites

**`.planning/publish/mailglass_inbound-publish-summary.json`**:
- Before: `"mailglass_inbound_publish_pin": "== 1.10.2"`
- After: `"mailglass_inbound_publish_pin": "~> 1.10 and >= 1.10.2"`
- Additionally regenerated by `publish.check` run (Task 3 ordered proof) — field kept as `~>`

**Deleted files**:
- `test/fixtures/release_please_sed_test.sh` — regression test for the deleted `==` sed step
- `test/fixtures/mix_exs_release_please_sed/mix.exs.before` — companion fixture (orphan)
- `test/fixtures/mix_exs_release_please_sed/mix.exs.after` — companion fixture (orphan)

**`mailglass_admin/test/mailglass_admin/mix_config_test.exs`**:
- Relaxed `"MIX_PUBLISH=true pins mailglass to the exact current version"` test to assert a pessimistic `~>` constraint via `refute String.starts_with?(req, "==")` + `assert Version.match?(version, req)`
- Removed entire `describe "release-please sed-anchor regex stability (REL-05)"` block (87-123) — the sed it guarded no longer exists
- `extract_function_body/3` helper retained (used by the remaining relaxed test)

**`test/mailglass/stability_contract_test.exs`** — BOTH tests relaxed:

(A) Pin-shape test (~line 105): replaced `assert inbound_mix =~ ~r/\{:mailglass, "== \d+\.\d+\.\d+"\}/` with:
- Extract requirement string via `Regex.run(~r/\{:mailglass, "([^"]+)"\}/, inbound_mix)`
- `refute String.starts_with?(inbound_req, "==")`
- `assert Version.match?(expected_core_version, inbound_req)`

(B) Preflight-consistency test (~line 116-183): relaxed TWO `==` assertions:
- Line ~154-159: replaced regex match on `"== #{expected_core_version}"` with the same admit-`~>`-reject-`==` contract using the extracted `inbound_req_for_preflight`
- Line 179: replaced `assert summary["mailglass_inbound_publish_pin"] == "== #{expected_core_version}"` with:
  ```elixir
  refute String.starts_with?(summary_pin, "==")
  assert Version.match?(expected_core_version, summary_pin)
  ```

**`CONTRIBUTING.md`**: Rewrote `## Why we sed mix.exs after release-please runs` section. Now accurately describes what the sed step DOES (README `~>` pins + publish-summary) and explicitly states it does NOT touch sibling `mix.exs` files. Documents the new `~>` reality: core patch = no sibling change; core minor = deliberate `fix(inbound):` floor-bump.

### Task 3: CHANGELOG entries + MAINTAINING.md rollback doc + ordered proof (PIN-04, PIN-05)

**CHANGELOG entries (all three packages)**:
- `CHANGELOG.md` (core): "sibling packages now depend on mailglass via pessimistic `~>` constraints instead of exact pins, ending the paired-release-per-core-patch requirement"
- `mailglass_admin/CHANGELOG.md`: "mailglass_admin now depends on `mailglass ~> 1.10` instead of an exact pin"
- `mailglass_inbound/CHANGELOG.md`: LD-5 verbatim — "mailglass_inbound now depends on `mailglass ~> 1.10 and >= 1.10.2` instead of an exact pin; you may upgrade core patch releases without waiting for a paired inbound release"

**MAINTAINING.md**: Extended `## Retract Decision Tree` with a new "`~>` Sibling Pin: Rollback Lever for a Bad Core Patch" subsection documenting `mix hex.retire mailglass X.Y.Z security|invalid --message "<140 chars>"` as the replacement for the `==` wall, with the resolver-degrees-of-freedom rationale (LD-5).

## PIN-05 Ordered Proof (before/after)

### Step 1: publish.check passes for all three packages (GREEN on bare main SHA)

```
MIX_PUBLISH=true mix mailglass.publish.check --package mailglass
→ Pre-publish check result for mailglass: create=2 update=5 unchanged=10 conflict=0

MIX_PUBLISH=true mix mailglass.publish.check --package mailglass_admin
→ Pre-publish check result for mailglass_admin: create=2 update=5 unchanged=9 conflict=0

MIX_PUBLISH=true mix mailglass.publish.check --package mailglass_inbound
→ Pre-publish check result for mailglass_inbound: create=2 update=5 unchanged=9 conflict=0
```

**Latent-red proof**: The inbound run REGENERATED `.planning/publish/mailglass_inbound-publish-summary.json`. The regenerated `mailglass_inbound_publish_pin` field came out as `"~> 1.10 and >= 1.10.2"` — NOT `"== 1.10.2"`. The latent red is closed.

### Step 2: stability_contract_test BOTH tests GREEN against REGENERATED summary

```
mix test test/mailglass/stability_contract_test.exs
→ 6 tests, 0 failures
```

The preflight-consistency test's line-179 assertion (`Version.match?` of `summary_pin` against `expected_core_version = "1.10.2"`) passed against the freshly-regenerated `"~> 1.10 and >= 1.10.2"` — proving it is not a self-invalidating latent red.

Core @version on main is `1.10.2` (unchanged) — this is the exact scenario that was RED before: the old test required `summary["mailglass_inbound_publish_pin"] == "== 1.10.2"` which was only true transiently (after a re-pin commit, before core bumped). The relaxed test is GREEN on any bare main SHA.

### Step 3: admin config test GREEN

```
cd mailglass_admin && mix test test/mailglass_admin/mix_config_test.exs
→ 4 tests, 0 failures
```

### Regenerated publish-summary diff (the ~> change)

Before (committed):
```json
"mailglass_inbound_publish_pin": "== 1.10.2"
```

After (committed pre-edit + confirmed by regeneration):
```json
"mailglass_inbound_publish_pin": "~> 1.10 and >= 1.10.2"
```

### Simulated core patch touches zero sibling pin lines (PROOF)

```bash
# Old sed anchor pattern: \{:mailglass, "== [0-9]+\.[0-9]+\.[0-9]+"\}
grep -cE '\{:mailglass, "== [0-9]+\.[0-9]+\.[0-9]+"\}' mailglass_admin/mix.exs   → 0
grep -cE '\{:mailglass, "== [0-9]+\.[0-9]+\.[0-9]+"\}' mailglass_inbound/mix.exs → 0
```

PROOF PASS: zero sibling pin lines would be touched by the old sed step. A core patch release now leaves both sibling `mix.exs` files byte-identical.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] stability_contract_test line 86 asserted deleted PINS array entry**

- **Found during:** Task 3 (first `mix test` run)
- **Issue:** `assert workflow =~ "\"mailglass_inbound/mix.exs:mailglass\""` — this was asserting the `PINS=(...)` array entry that Task 2 deleted. After deletion the test failed with `=~ false`.
- **Fix:** Replaced the assertion with two that check what the workflow DOES contain to prove inbound tracking: `assert workflow =~ "mailglass_inbound/README.md"` and `assert workflow =~ "mailglass_inbound-publish-summary.json"` — both remain true because the surviving `~>` README sed rewrites and SYNC_PATHS still reference inbound.
- **Files modified:** `test/mailglass/stability_contract_test.exs`
- **Commit:** 37dcaf11 (included in atomic task commit)

### Intentional scope additions

**Publish-summary JSON regeneration for core + admin packages**: The `publish.check` runs for mailglass and mailglass_admin (Task 3 proof) also regenerated their respective summary JSONs (`.planning/publish/mailglass-publish-summary.json` and `.planning/publish/mailglass_admin-publish-summary.json`). The core summary picked up a new `v05.ex` migration file entry and updated linked_versions; the admin summary updated its linked_versions and `mailglass_admin_publish_pin` (from `"== 1.9.0"` to `"~> 1.10"`). These are legitimate artifacts of the verify step and were committed with the atomic change.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. This is a pure infra/DX change: dependency constraints, CI workflow, and gate assertions only. Scope fence (D-23) held.

## Self-Check

### Created files exist
- `.planning/phases/125-sibling-pin-loosening-keystone-atomic/125-01-SUMMARY.md`: PRESENT (this file)

### Key commits exist
```
git log --oneline | grep 37dcaf11
→ 37dcaf11 feat(125-01): loosen sibling pins from == to ~> (keystone atomic change)
```

### Self-Check: PASSED
