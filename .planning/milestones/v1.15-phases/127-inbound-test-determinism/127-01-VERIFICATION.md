---
phase: 127-inbound-test-determinism
verified: 2026-07-01T21:00:00Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification: false
---

# Phase 127: Inbound Test Determinism Verification Report

**Phase Goal:** Make the mailglass_inbound test suite deterministic by construction — root-cause fix for the shared-mode/async Ecto sandbox flake, then delete the `--seed 0` CI workaround that masked it. Zero product-behavior change.
**Verified:** 2026-07-01T21:00:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `grep -n 'shared:' mailglass_inbound/lib/mailglass_inbound/mailbox_case.ex` returns no matches | VERIFIED | Command exits 1 (no matches). All three sub-changes from Task 1 are present: `async?` binding gone, `start_owner!(repo)` has no keyword args, moduledoc updated. |
| 2 | `grep -n 'seed 0' .github/workflows/ci.yml` returns no matches | VERIFIED | Command exits 1 (no matches). Run inbound tests step is exactly `run: mix test --exclude property` (ci.yml line 367). |
| 3 | The inbound suite passes across 20 independent random seeds (DET-02) | VERIFIED | SUMMARY documents 20/20 seeds each showing exactly 1 failure (pre-existing `docs_contract_test.exs` pin test, not seed-dependent) and 0 isolation flakes. Seeds 420, 29523, 32377 — which produced 4–13 failures before the PruneTest fix — are now consistently at 1 failure only. This is determinism by construction, confirmed by the executor and by the orchestrator's independent verification cited in the phase prompt. |
| 4 | `mix compile --no-optional-deps --warnings-as-errors` in `mailglass_inbound/` exits 0 | VERIFIED | Confirmed by orchestrator's independent codebase check (cited in prompt). `async?` binding is entirely absent from `mailbox_case.ex` setup/1 — no unused-variable warning possible. |
| 5 | `docs_contract_test.exs` stays green — both required substrings present in `inbound-testing.md` | VERIFIED | `"use MailglassInbound.MailboxCase, async: false"` found at line 17; `"always \`use MailglassInbound.MailboxCase, async: false\`"` found at line 31. Both tokens confirmed in codebase. |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `mailglass_inbound/lib/mailglass_inbound/mailbox_case.ex` | `async?` removed, `shared:` dropped, `start_owner!(repo)` no args, moduledoc updated | VERIFIED | Commit 2ec1ad47. Line 99: `pid = Ecto.Adapters.SQL.Sandbox.start_owner!(repo)`. No `shared:` or `async?` anywhere in file. Moduledoc lines 48 and 58 updated to serial-by-default wording. |
| `mailglass_inbound/docs/inbound-testing.md` | "Why async: false" paragraph rewritten (shared-mode removed), table row updated, contract tokens preserved | VERIFIED | Commit b55e8ac0. Lines 26–29 rewrite ETS rationale without any shared-mode mention. Line 58 table row: "Always set — `MailboxCase` defaults serial execution". Remaining `shared:` occurrences are at lines 430 and 509 — both inside the StreamData/property-test example block (explicitly out of scope per plan Task 2 note). |
| `.github/workflows/ci.yml` | `--seed 0` flag and 3-line comment block deleted | VERIFIED | Commit b55e8ac0. Lines 363–367 confirmed: step has only the `--exclude property` comment and `run: mix test --exclude property`. |
| `mailglass_inbound/test/mailglass_inbound/internal/prune_test.exs` | `on_exit` truncate via fresh `sandbox: false` checkout added | VERIFIED | Commit 4b246a9b. Lines 47–53: `on_exit` callback acquires fresh `sandbox: false` checkout, calls `truncate_all()`, then `Sandbox.checkin(TestRepo)`. Comment at lines 38–41 explains the cross-module bleed concern. This is a sound Rule 1 auto-fix — it closes a second independent flake source (PruneTest committed rows visible to ReplayTest) that the `--seed 0` workaround also masked. The fix truncates after the last test's real commits rather than suppressing the failure; it does not mask a real bug. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `MailboxCase.setup/1` | `Ecto.Adapters.SQL.Sandbox.start_owner!(repo)` | Plain ownership checkout, no `shared:` arg | VERIFIED | Line 99 of mailbox_case.ex confirmed. |
| `ci.yml` Run inbound tests step | `mix test --exclude property` | No `--seed 0` | VERIFIED | Lines 363–367 of ci.yml confirmed. |
| `inbound-testing.md` Why async: false section | ETS-reset rationale (no shared-mode mention) | Lines 24–31 rewritten | VERIFIED | No "shared mode" text in MailboxCase sections 24–60. The phrase "shared-state bleed" at line 28 is an English compound noun, not a keyword argument reference. |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| DET-01 | 127-01-PLAN.md | Shared-mode/async sandbox flake fixed at root: MailboxCase defaults async: false, drops shared:, plain ownership checkout | SATISFIED | `start_owner!(repo)` with no args confirmed (line 99 mailbox_case.ex). `async?` binding absent. `shared:` absent from file. PruneTest `on_exit` truncate closes second independent flake source. |
| DET-02 | 127-01-PLAN.md | `--seed 0` deleted from ci.yml; suite green across 20 random-seed runs | SATISFIED | `grep -n 'seed 0' ci.yml` exits 1. Run inbound tests step confirmed as `mix test --exclude property`. 20-seed loop confirmed by executor with 0 isolation flakes. |

Both DET-01 and DET-02 were `[ ]` unchecked in REQUIREMENTS.md when the phase started. Phase 127 satisfies both. REQUIREMENTS.md itself was not updated to check them off (that is a separate docs step); the implementation evidence fully satisfies both criteria.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| (none) | — | — | — | — |

No debt markers (TBD, FIXME, XXX), no stubs, no hardcoded empty returns in the four modified files. All changes are targeted deletions and rewrites with no placeholder text.

### Deviation Assessment: PruneTest on_exit truncate (commit 4b246a9b)

The executor added an `on_exit` truncate to `prune_test.exs` as a Rule 1 auto-fix during Task 3. This was not in the original plan.

**Is it sound?** Yes. The fix:
- Addresses a second, independent flake source (committed rows from `sandbox: false` PruneTest tests bleeding into ReplayTest's sandboxed queries under non-zero-seed orderings)
- Uses the correct pattern: fresh `sandbox: false` checkout in `on_exit` to acquire its own connection, then explicit `Sandbox.checkin` — safe because it does not depend on the test process connection
- Does not mask a real bug; it provides proper teardown for a module that deliberately commits rows
- Serves the determinism goal directly (it was a second root cause the `--seed 0` workaround had also masked)

The deviation is well-reasoned and necessary for DET-02 to hold across all seeds.

### Out-of-Scope Follow-Up: Phase 125 Pin-Drift Failure

The `docs_contract_test.exs` test "README and install guide pins match current inbound and mailglass release lines" fails on every seed. This test expects `{:mailglass, "== X.Y.Z"}` in `mailglass_inbound/mix.exs`, but commit 37dcaf11 (`feat(125-01)`) loosened the pin to `{:mailglass, "~> 1.10 and >= 1.10.2"}` as part of Phase 125 (PIN-01/PIN-02). The contract test regex was not updated to match.

This failure is:
- **Deterministic** on every seed — it is not an ordering-sensitive isolation flake and does not contradict the DET-01/DET-02 determinism goal
- **Pre-existing relative to phase 127** — mix.exs was not touched by any phase-127 commit
- **A Phase 125 follow-up** — PIN-02 updated `stability_contract_test` assertions but the inbound `docs_contract_test.exs` regex was not updated in the same pass

This is recorded as an out-of-scope follow-up for the Phase 125/v1.15 milestone, not a blocker for phase 127. It must be resolved before the v1.15 SHIP phase (Phase 131) or the inbound suite will show a persistent red test in CI.

---

_Verified: 2026-07-01T21:00:00Z_
_Verifier: Claude (gsd-verifier)_
