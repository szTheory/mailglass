---
status: resolved
trigger: "CI run 40226888519 Core Deterministic Suite seed 165497: sandbox_ownership_test.exs:251 probe got {:leaked, {:shared, #PID<0.5535.0>}}"
created: 2026-10-25T20:10:00Z
updated: 2026-10-25T21:30:00Z
---

## Current Focus

bug_class: Heisenbug (timing-dependent, seed-ordered)
reasoning_checkpoint:
  hypothesis: "checkout!(shared: true)'s on_exit can return while the pool still reads {:shared, <its own dead owner>}, because the ownership manager monitors the PROXY (manager.ex:278), not the owner, and the proxy exits only after it handles the owner's DOWN and finishes its own termination; assert_manual!/3 then accepts the dead holder after ~150ms. The next sync module inherits that state; SandboxOwnershipTest heals only in on_exit AFTER each test, so its first test (seed 165497 puts :251 first) probes {:shared, dead_pid} and fails."
  confirming_evidence:
    - "`mix test sandbox_ownership_test.exs --seed 165497 --trace` lists :251 as the FIRST test in the module"
    - "every Sandbox shared-mode producer outside this file goes through checkout!/1 (grep + NoRawSandboxOwnership credo); a LIVE holder would have raised LeakError in that module's on_exit, so the inherited holder must have been dead"
    - "manager.ex:241-243 unshares only on the proxy DOWN; assert_manual!/3 dead-holder branch returns :ok without healing"
  falsification_test: "suspend the owner's proxy (:sys.suspend) so it cannot exit, run checkout!'s on_exit chain, probe: if probe is :ok WITHOUT the fix, hypothesis is wrong"
  fix_rationale: "make checkout!'s release complete: when the bound is exhausted and the pool still names the release's OWN (now provably dead) owner, write :manual via mode_manual!/2. The release then leaves the pool :manual regardless of proxy teardown latency, so no successor inherits shared mode."
  blind_spots: "could not reproduce the CI interleaving locally (load-dependent); preceding module in CI is unknown (sync order = parallel-require load order)"
  candidate_causes:
    - "code: checkout!/1 on_exit release incomplete under proxy teardown latency"
    - "environment: CI 2-core runner load lengthening proxy teardown (contributing, not fixable test-side)"
    - "code: SandboxOwnershipTest asserts a clean baseline it never establishes before its first test"
  and_gate: "yes — needs (a) a preceding sync module whose last test used a shared checkout with slow proxy teardown AND (b) a seed ordering a probe-asserting test first in SandboxOwnershipTest. Fixing (a) at the release removes the class for every successor."

hypothesis: H1 — the failing test ran FIRST in SandboxOwnershipTest (only the first test is unprotected by the file's per-test `Sandbox.mode(:manual)` on_exit), and the immediately-preceding async:false module's last `checkout!(shared: true)` on_exit stopped its owner, the ownership manager had not yet processed the owner :DOWN, and `assert_manual!/3` accepted the dead-holder `{:shared, dead_pid}` state after its ~150ms bound. The next module's first probe read that transient state.
test: full-suite repro with `mix test --warnings-as-errors --seed 165497`; then `--trace` style ordering to identify the preceding module
expecting: failure reproduces locally (maybe not — load-dependent); preceding module does heavy shared-pool churn
next_action: wait for background seed run, inspect log

## Symptoms

expected: probe(Mailglass.TestRepo) == :ok at sandbox_ownership_test.exs:264
actual: {:leaked, {:shared, #PID<0.5535.0>}}
errors: 1 failure / 2219 tests, formatter signature tally already_shared=0, formatter_violations=0
reproduction: CI seed 165497, `mix test --warnings-as-errors`, MIX_ENV=test, max_cases 8
started: first occurrence in run 40226888519; branch changes only Playwright spec + docs

## Eliminated

- hypothesis: the failing test itself enters shared mode
  evidence: every opts variant raises in guard_shared_checkout_from_async!/1 before start_owner!/2
  timestamp: 2026-10-25T20:10:00Z
- hypothesis: SandboxOwnershipTest races an async module
  evidence: module is `async: false`; ExUnit 1.18 runs sync modules strictly after async ones
  timestamp: 2026-10-25T20:10:00Z

## Evidence

- timestamp: 2026-10-25T20:10:00Z
  checked: test/support/sandbox_ownership.ex assert_manual!/3
  found: after a 30x5ms bound, `{:shared, holder}` with a DEAD holder is accepted as :ok (documented, CI run 30555218236)
  implication: a sync module can finish while the manager still reports {:shared, dead_pid}; whatever runs next observes it
- timestamp: 2026-10-25T20:10:00Z
  checked: sandbox_ownership_test.exs setup
  found: only an on_exit `Sandbox.mode(:manual)`; nothing normalizes the pool BEFORE the first test
  implication: only the first test in file order is exposed to the previous module's tail state

- timestamp: 2026-10-25T21:00:00Z
  checked: full `mix test --warnings-as-errors --seed 165497` locally (pre-fix)
  found: the sandbox failure did NOT reproduce (load-dependent); only failure was phase_164_repository_truth_test:261, caused by an untracked local `.gsd/.gitignore` (`*`) — clean worktree check-ignore exits 1
  implication: CI interleaving not locally reproducible by seed alone; need a deterministic fixture
- timestamp: 2026-10-25T21:10:00Z
  checked: new test suspending the owner's proxy (:sys.suspend) around checkout!'s release, in an isolated on_exit scope
  found: PRE-FIX release returned :ok and probe read {:leaked, {:shared, #PID<0.674.0>}} — the exact CI signature; POST-FIX probe reads :ok
  implication: hypothesis confirmed; release was incomplete under proxy teardown latency

## Resolution

root_cause: "checkout!(shared: true)'s on_exit release could return with the pool still `{:shared, <its own dead owner>}`: the ownership manager unshares only on the checkout proxy's :DOWN, the proxy outlives the owner while tearing down, and assert_manual!/3 accepts a dead holder after its ~150ms bound. The next async:false module inherited the shared mode; with seed 165497 SandboxOwnershipTest's first test probed it."
fix: "checkout!/1's shared release now calls complete_release!/3: if the pool still names this release's own (already stopped) owner, write :manual via mode_manual!/2. Any other state untouched; live holders still raise in assert_manual!/3."
oracle_type: specified
verification: "RED->GREEN on new regression test (sandbox_ownership_test.exs:637); touched file + shared-checkout consumers 113 tests 0 failures at seeds 165497 and 0; full core --seed 0: 2220 tests, 1 failure (local-only .gsd/.gitignore env artifact, unrelated), formatter_violations=0, already_shared=0; credo --strict clean"
files_changed: [test/support/sandbox_ownership.ex, test/mailglass/test_support/sandbox_ownership_test.exs]

## Resolution confirmed

Core Deterministic Suite green on PR #306 run 40230737105 (head 02280f19) and on the main push run 40233264923 (merge f04ba0c6). Fix: 02280f19.
