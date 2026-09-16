---
phase: 165
fixed_at: 2026-09-13T21:17:11Z
review_path: /Users/jon/projects/mailglass/.planning/phases/165-reconcile-terminal-proof-and-milestone-archive-ordering/165-REVIEW.md
iteration: 2
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 165: Code Review Fix Report

**Fixed at:** 2026-09-13T21:17:11Z
**Source review:** `/Users/jon/projects/mailglass/.planning/phases/165-reconcile-terminal-proof-and-milestone-archive-ordering/165-REVIEW.md`
**Iteration:** 2

**Summary:**

- Findings in scope: 5
- Fixed: 5
- Skipped: 0

## Fixed Issues

### CR-01: The canonical audit workflow cannot produce the finalizer's required schema

**Files modified:** `scripts/finalize_milestone_v2_7.sh`, `test/scripts/phase_165_milestone_finalizer_test.exs`, `.planning/phases/165-reconcile-terminal-proof-and-milestone-archive-ordering/165-FINALIZATION.md`
**Commit:** 97eca96d
**Applied fix:** Aligned the finalizer with the canonical audit producer's real frontmatter, authenticated the archived audit through the final authority commit, and derived the accepted 14-PR policy from authenticated PROJECT and STATE owners. Added a canonical-schema behavior fixture and hostile wrong-milestone/debt-ledger controls. **Status:** fixed; requires human verification because this changes lifecycle acceptance logic.

### CR-02: A passing receipt does not prove live-ledger convergence or full Nyquist compliance

**Files modified:** `scripts/mailglass_finalize_milestone_loader.mjs`, `scripts/finalize_milestone_v2_7.sh`, `test/scripts/phase_165_milestone_finalizer_test.exs`
**Commit:** ccb198b1
**Applied fix:** Added authenticated final ROADMAP and RETROSPECTIVE inputs, proved live REQUIREMENTS removal, rejected stale live phase detail, required `status: validated`, `nyquist_compliant: true`, and `wave_0_complete: true` for all five phases, and recorded those outcomes in the receipt. Added hostile stale-ledger, missing-retrospective, and false/missing-Nyquist controls. **Status:** fixed; requires human verification because this changes terminal pass semantics.

### CR-03: Fresh executable installation has no authenticated, consumable authorization path

**Files modified:** `scripts/mailglass_finalize_milestone_loader.mjs`, `test/scripts/phase_165_milestone_finalizer_test.exs`, `.planning/phases/165-reconcile-terminal-proof-and-milestone-archive-ordering/165-FINALIZATION.md`
**Commit:** 48b9013d
**Applied fix:** Made proposal authority derive from the physical source checkout, require clean canonical `main == origin/main`, and reject caller-selected repository/OID inputs. Added immutable digest-bound proposal, OS-identity approval, installation, and rollback receipts; atomic predecessor backup/install/rollback; exact fresh approval wording; and mandatory terminal consumption of the receipt chain. Hostile tests reject dirty/caller-selected authority, wrong approval, and proposal tampering while a disposable positive path proves install authentication and predecessor restoration. No real approval was fabricated and no installed executable was changed. **Status:** fixed; requires human verification because this adds security-sensitive installation transition logic.

### WR-01: A false-success restore hook can leave `.planning/config.json` modified

**Files modified:** `.planning/phases/165-reconcile-terminal-proof-and-milestone-archive-ordering/165-FINALIZATION.md`, `test/scripts/phase_165_milestone_finalizer_test.exs`
**Commit:** 1c9bf0f0
**Applied fix:** Delayed the restored flag until byte comparison succeeds, added atomic fallback replacement from the private backup, and kept false-success hooks red after exact recovery. Added controls both before and after the archive confirmation checkpoint. **Status:** fixed; requires human verification because this changes cleanup-state handling.

### WR-02: Transient preflight failures permanently consume the deterministic receipt directory

**Files modified:** `scripts/mailglass_finalize_milestone_loader.mjs`, `scripts/finalize_milestone_v2_7.sh`, `test/support/mailglass_milestone_finalizer_fixture.mjs`, `test/scripts/phase_165_milestone_finalizer_test.exs`
**Commit:** 48b9013d
**Applied fix:** Moved read-only GitHub evidence selection and staged semantic validation ahead of receipt reservation, added a no-publication Bash preflight, and releases only an owned unpublished reservation on final-dispatch failure while retaining pass/blocked receipts. Added a fail-once evidence query whose identical retry succeeds. **Status:** fixed; requires human verification because this changes one-shot receipt state handling.

## Verification

Verification ran in the main checkout because `.planning/config.json` sets `workflow.use_worktrees=false`.

- `mix verify.phase_165.repository`: 22 executed, 1 expected installed-boundary exclusion, 0 failures.
- `mix verify.ci_lane_contract`: 436 executed, 12 expected exclusions, 0 failures, zero SuiteFloor violations.
- Focused authenticated install/rollback and retry controls: 2 executed, 0 failures.
- Tag-omission/restoration control: 1 executed, 22 exclusions, 0 failures.
- `node --check` passed for the shipped loader and fixture module; Bash syntax, Elixir formatting, and `git diff --check HEAD --` passed.
- The installed executable remained untouched. Current source SHA-256 is `06bd7c002fc477800a43b392db1b79a4b75c345182384f55a44fabcc8a7449b1`; installed SHA-256 remains `505707b19ab09366479243365ef2ce1b4c2a4030614eca69c40ea5f51174a6ce`. A fresh blocking-human approval is still required before the implemented install path may be exercised.
- No terminal finalization, GitHub credential use, remote/workflow/release/publication/PR mutation, dependency change, or external installation mutation occurred.
- The pre-existing dirty `.planning/config.json` and current `165-REVIEW.md` remained untouched and uncommitted.

---

_Fixed: 2026-09-13T21:17:11Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 2_
