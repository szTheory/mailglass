---
phase: 143
plan: gap-closure-dialyzer-and-class-c
subsystem: test-harness
tags: [harness-01, d-31, class-c, dialyzer, sandbox, flake, release-verification]
status: complete
requires:
  - "Mailglass.TestSupport.SandboxOwnership — checkout!/1, assert_manual!/3, probe/1, live_holder/1, mode_manual!/1 (plans 143-01/04/07/08 + the two prior gap closures)"
  - "Mailglass.TestSupport.SuiteFloor + SuiteTruthFormatter (plans 143-01/09)"
provides:
  - "mode_manual!/2 — succeed-or-raise, with an injectable :mode_fun seam"
  - "LeakError :refused_with field + its own message/1 clause"
  - "assert_manual!/3 exhausted-bound classification — live holder raises, dead holder is a verified pass"
  - "guard_shared_checkout_from_async!/1 made fail-closed (three-way async_classification/1)"
  - "SuiteFloor.violation_class() — the closed violation-name atom set as a named type"
affects:
  - "test/support/sandbox_ownership.ex, test/support/suite_floor.ex, test/mailglass/test_support/sandbox_ownership_test.exs"
key-files:
  created: []
  modified:
    - test/support/sandbox_ownership.ex
    - test/support/suite_floor.ex
    - test/mailglass/test_support/sandbox_ownership_test.exs
metrics:
  dialyzer-errors-before: 4
  dialyzer-errors-after: 0
  dialyzer-ignore-entries-added: 0
  race-hunt-runs: 11
  race-hunt-reproductions: 0
  mutation-checks: 5
  new-tests: 10
---

# Phase 143 Gap Closure: the four Dialyzer contracts, and the Class C `already_shared` hunt

Two independent tasks. Both closed — but **Task 2's directed diagnosis is refuted**, and the
correction is the substance of this document. Read §5 before §6.

---

## 1. Task 1 — the four Dialyzer errors

`.dialyzer_ignore.exs` is at its hard 15-entry cap (D-08-07), so every one is fixed at the
source. **No ignore entry was added; the file is byte-identical.**

Verified with the CI lane's own configuration (`ci.yml` sets `MIX_ENV: test` for the
`Dialyzer (Elixir 1.18 / OTP 27)` job — a bare `mix dialyzer` runs in `:dev`, where
`elixirc_paths/1` excludes `test/support` and none of these four errors appear at all):

| | Command | Result | Exit |
|---|---|---|---|
| **Before** | `MIX_ENV=test mix dialyzer` | `Total errors: 20, Skipped: 16, Unnecessary Skips: 0` | 2 |
| **After** | `MIX_ENV=test mix dialyzer` | `Total errors: 16, Skipped: 16, Unnecessary Skips: 0` | 0 |

4 real → 0 real. The 16 skipped are unchanged and all still used (`Unnecessary Skips: 0`,
`list_unused_filters: true` satisfied).

### 1a. `sandbox_ownership.ex:729:missing_range` — substantive, as suspected

```
Type specification return types:  :ok
Missing from spec:                :already_shared | :not_found | :not_owner
```

`mode_manual!/1` was spec'd `:ok` while returning `Ecto.Adapters.SQL.Sandbox.mode/2`'s full
range verbatim — a `!`-suffixed function handing back a non-success as if it were a result
nobody has to look at. All three call sites discard the return (`test_helper.exs:168`,
`deliver_many_test.exs:45`, `deliver_later_test.exs:63`), so a refusal was being dropped on the
floor: the suite could have booted against a pool whose mode was never established and reported
nothing at all.

Now succeed-or-raise, so the `@spec` is true **by construction** rather than by hope.

- **Raises `LeakError`, not a bespoke exception.** `SuiteTruthFormatter.signature/1` matches
  `%SandboxOwnership.LeakError{}` and folds it into D-17's `:already_shared` tally. A refusal
  raised under a new name would be classified `:other`, the tally would stay at zero, and
  ROADMAP criterion 3 would pass vacuously — the exact failure `LeakError`'s own moduledoc
  warns about. A test pins this (`signature/1` on the new error returns `:already_shared`).
- **A new `:refused_with` field with its own `message/1` clause.** A refusal code is *not* a
  pool mode; rendering `:already_shared` inside the existing "the pool is still `<mode>`"
  sentence would state a fact nobody observed. The clause pair follows `BaselineError`'s
  existing `reason: nil`-first precedent. A test asserts the refusal message does **not**
  contain "the pool is still".
- **No non-raising variant.** Checked before changing, as directed: no call site
  pattern-matches the result, so a silent variant would immediately recreate the defect.
- **Injectable `:mode_fun` / `:caller`**, mirroring the established `probe_fun:` /
  `schema_fun:` / `search_path_fun:` idioms, so both refusal branches are provable without
  corrupting the live pool.

Both refusal branches are **unreachable on today's dependencies** — Ecto documents the write as
always successful for `:manual` (`sandbox.ex:501-503`), and db_connection's manager replies
`:ok` on both of its `:manual` clauses (`manager.ex:165-172`). That is precisely why leaving
the check out was tempting, and precisely why it is worth three lines: an unreachable branch
that would be catastrophic if reached.

### 1b/1c. `suite_floor.ex:330/338:contract_supertype` — `@spec` dropped, deliberately

`skipped_ceiling/0` (`non_neg_integer()` vs `1_000_000_000`) and `nudge_margin/0`
(`non_neg_integer()` vs `40`). Both return a bare module attribute, so under `:underspecs` the
honest contract reads as a supertype of the literal.

**Weighed as directed, and the literal spec is the worse option.**
`@spec skipped_ceiling() :: 1_000_000_000` is a spec that lies on the next edit:
`@skipped_ceiling` is an explicit D-27 placeholder that **plan 143-10 re-pins from a green
1.18/OTP 27 CI run**, and `@nudge_margin` is a tunable design constant. Pinning the spec to
today's value turns every future re-pin into a mechanical "edit the spec to match the value"
step — spec-rot taught as routine, and the type signature becomes a second copy of the constant
rather than a contract about it.

Dropping the `@spec` states nothing false and loses no checking: dialyzer still infers and
checks the exact value at every call site. The real contract ("a non-negative integer; callers
must not depend on the value") now lives in the `@doc` and in
`test/scripts/suite_floor_contract_test.exs`, which already reads both accessors live and
computes its fixtures from them rather than hardcoding either number.

A block comment above both accessors records this, and explicitly forbids the tempting
non-fix: routing the constant through a `Map.get/3` indirection to blind the analyzer (the
shape `executed_floor/1` happens to have for its own reasons). Widening a contract to defeat
an analyzer is the same class of move as a check that reports green without observing its
subject.

*Rejected alternative:* removing `:underspecs` from `mix.exs`'s dialyzer flags. `mix.exs`
invites this ("revisit removing `:underspecs` after the ≤15-entry baseline is hit"), but it
would weaken checking repo-wide and invalidate several existing ignore entries, which
`list_unused_filters: true` then fails CI on. Out of scope for a gap closure.

### 1d. `suite_floor.ex:345:contract_supertype` — narrowed, because narrowing is right here

`violation_classes/0` is now `[violation_class(), ...]`, with `violation_class()` a named
closed union declared adjacent to `@violation_classes` and reused in `violation()`'s `name:`
field (previously `atom()`). Matches this project's documented closed-`:type`-atom-set DNA, and
the adjacency is load-bearing: an atom added to one and not the other now fails `mix dialyzer`,
because the function's success typing *is* the attribute's contents.

---

## 2. Task 2 — the race hunt: 11 runs, 0 reproductions

Every run from a freshly reset DB
(`MIX_ENV=test mix ecto.drop -r Mailglass.TestRepo --quiet && MIX_ENV=test mix ecto.create -r Mailglass.TestRepo --quiet`),
`MAILGLASS_SCHEMA=mailglass mix test --seed 79310 --warnings-as-errors --exclude requires_workspace`,
read from **raw `mix test` output only**.

| Runs | Concurrency | Result | `already_shared` |
|---|---|---|---|
| 1–5 | default (`max_cases: 36`) | 23 properties, 1549 tests, **0 failures**, 7 skipped (14 excluded) | 0 |
| 6–8 | `--max-cases 2` (CI's 2-core shape) | same, **0 failures** | 0 |
| 9–11 | `--max-cases 72` (over-subscribed) | same, **0 failures** | 0 |

**11 runs, 0 reproductions.** Script and per-run logs:
`/Users/jon/.claude/jobs/9fc6b2c7/tmp/race_hunt.sh`, `race-{1..11}-*.log`.

**Local non-reproduction was never going to be conclusive, for a reason worth recording:** the
failing leg is Elixir 1.18.4 / OTP 27 on a 2-core GitHub runner. `.tool-versions` pins exactly
that, but asdf is not installed on this machine — the local toolchain is Homebrew Elixir 1.19.5
/ OTP 28 on 18 cores. `--max-cases 2` caps ExUnit's async concurrency but does **not**
reproduce a 2-core scheduler or a loaded runner. As it turns out (§5), runner load is the whole
mechanism, so this axis of the hunt was structurally incapable of reproducing it.

---

## 3. What the audit ruled out

- **`WebhookSignatureFailureTest` is a victim, not a culprit.** Its own `setup` only TRUNCATEs
  and registers a matching `on_exit`. Its shared acquisition comes from `MailerCase.setup`
  (via `WebhookCase`), which goes through `checkout!/1` — release registered on the very next
  statement. The acquire/release ordering invariant is intact here.
- **Both originally-confirmed leak sites are clean.**
  `webhook_idempotency_convergence_test.exs:60` and `mailer_case.ex:93` both route through
  `checkout!/1`. No acquire-then-work-then-register-release shape remains anywhere in the tree.
- **`sandbox_ownership_test.exs` cannot leak past its own module.** It deliberately creates raw
  shared owners with `stop_owner` only at the end of each test body, but its module-level
  `setup` registers `on_exit(fn -> Sandbox.mode(:manual) end)` **first**, so it runs **last**
  and heals regardless of assertion outcome. Its two `ExUnit.OnExitHandler.run/2` +
  `register/1` tests consume that healing callback, but only after it has already run.
- **A *dead* leaked owner can never produce `:already_shared`.** `Sandbox.stop_owner/1` is
  `GenServer.stop/1` — synchronous. `manager.ex:156-157` transparently replaces a dead shared
  owner. So `:already_shared` requires a **live**, never-released Agent. This is what
  eventually localised the real defect.
- **The `:already_shared` SASL crasher at 15:11:40 in the CI log is not a failure.** It is
  `sandbox_ownership_test.exs`'s deliberate "leak reproduces" test firing inside
  `assert_raise`; the log shows passing dots resuming immediately after it. Exactly the
  grep-inflation 143-MECHANISM.md §2 warns about.

---

## 4. The one hole the audit did find in the async guard

The directive asked whether `guard_shared_checkout_from_async!/1` actually catches a shared
checkout from an `async: true` module. **It does for a labelled test process, and it had two
silent-pass holes otherwise** — both the "a check that cannot observe its subject reported
success" shape this milestone exists to remove:

1. `calling_test_module/0` reads `Process.get(:"$process_label")`. Decompiling `ExUnit.Runner`
   (1.19.5) shows exactly **one** `Process.set_label` call site in the entire module, inside
   `spawn_test_monitor/4` — the per-test process only. A `setup_all` block, an `on_exit`
   runner process, and any spawned `Task` therefore carry no label, resolve to `nil`, and fell
   through to `:ok`: the pool went into process-global shared mode on the word of a guard that
   never ran.
2. `async_module?/1` returned `false` for any module not exporting `__ex_unit__/1` —
   indistinguishable from a genuine `async: false`.

Replaced by a three-way `async_classification/1` (`:async | :sync | :unknown`) where
`:unknown` raises, naming the injectable `calling_module_fun:` as the sanctioned door for a
caller that legitimately runs outside a labelled test process.

**Neither hole has a live call site today** (audited: every `checkout!(shared: true)` in the
repo runs from a labelled test process). That is exactly when a hole is cheapest to close. A
positive-control test (`FakeSyncModule` still gets through) keeps the fail-closed pair from
passing against a guard that simply raises unconditionally.

---

## 5. Root cause — corrected, with the CI log as evidence

**The directed diagnosis is refuted.** It named D-31 **Class C** — "pool mode left at
`{:shared, pid}`, the class `checkout!/1`'s acquire-then-immediately-register-release invariant
exists to prevent." That invariant was never violated. There is no ordering defect to find, and
no site to fix through that door.

The orchestrator's excerpt showed `exception error: no match of right hand side value
already_shared`, which reads as the `{:badmatch, :already_shared}` collision. Downloading the
job log (`gh api repos/szTheory/mailglass/actions/jobs/90913824954/logs` — read-only, no CI
minutes) shows those are **two different events, 134 seconds apart**. The quoted line is the
SASL crasher at `15:11:40`, which is the deliberate `assert_raise` test (§3) and caused no
failure. The **actual and only** failure, at `15:13:53`, is:

```
1) property every Postmark signature failure raises exactly one of 7 atoms; no partial writes
   (Mailglass.Properties.WebhookSignatureFailureTest)
   test/mailglass/properties/webhook_signature_failure_test.exs:75
   ** (Mailglass.TestSupport.SandboxOwnership.LeakError) ... released a Sandbox owner but the
      pool is still {:shared, #PID<0.6430.0>}, not :manual. ...
   stacktrace:
     (mailglass 2.2.1) test/support/sandbox_ownership.ex:705:
       Mailglass.TestSupport.SandboxOwnership.do_assert_manual!/5
     (ex_unit 1.18.4) lib/ex_unit/on_exit_handler.ex:136: ExUnit.OnExitHandler.exec_callback/1
```

Not a badmatch. Not a collision. **`checkout!/1`'s own release ran exactly as designed, and its
release-*verification* raised.**

`checkout!/1`'s `on_exit` calls `stop_owner/1` — a synchronous `GenServer.stop/1` — and only
then `assert_manual!/3`. So its owner is **guaranteed dead** by the time the assertion runs. The
`{:shared, #PID<0.6430.0>}` it observed is the ownership manager not having processed the
proxy's `:DOWN` yet: `manager.ex:241-243` runs `owner_down/2` and `unshare/2` together, so that
state is transient and self-clearing by construction, and `manager.ex:156-157` replaces a dead
shared owner outright, so it blocks nothing.

The default bound is 30 attempts × 5ms ≈ 150ms. `webhook_signature_failure_test.exs` runs 200
property iterations × 4 statements ≈ 800 round trips through the shared connection immediately
before releasing — the precise "heavy pool churn before releasing" case `checkout!/1`'s own
`@doc` already documents (and which `webhook_idempotency_convergence_test.exs` already widens
to 6s for, having measured 564–1131ms locally). On this 18-core box the manager catches up
inside 150ms; on a loaded 2-core runner it does not.

**Whether the assertion passed was decided by CI runner load, not by whether anything leaked.**
That is the defect.

---

## 6. The fix — a narrowing, deliberately not a widened timeout

`do_assert_manual!/5`'s exhausted-bound branch now **classifies** instead of assuming, using
the same discriminator `manager.ex:153` itself uses (and the same mode-then-liveness read
`live_holder/1` already performs):

- **Holder ALIVE** → `LeakError`, exactly as before. This is HARNESS-01's leak: `manager.ex:153-154`
  replies `:already_shared` to the next `start_owner!(shared: true)`, which badmatches at
  `sandbox.ex:458`.
- **Holder DEAD** → verified pass. `manager.ex:156-157` replaces it; the next shared
  acquisition provably succeeds.
- **Every other unhealed mode** (`:auto`, `:cannot_verify`, anything a future db_connection
  adds) → still raises. Non-observation never reads as success.

The full bound is still spent first — a clean `:manual` reading is preferred, and the liveness
proof is only ever the fallback (pinned by its own test, which counts probe invocations).

**Why this is a narrowing and not a weakened assertion.** The predicate verified is now exactly
the one this function exists to protect — *"the next `start_owner!(shared: true)` will not
collide"* — instead of the strictly-stronger-but-partly-irrelevant proxy *"the mode field
currently reads `:manual`"*. It can never green-light a live holder, which is the only state
that blocks anything.

**Widening the bound was considered and rejected.** It would have made the same flake rarer
while leaving the verdict decided by load, and it edges toward the 120s `ownership_timeout` at
which a genuine leak self-heals — i.e. it is the option that actually masks the real class. The
bound is unchanged at ~150ms.

### 6a. Third finding, fixed for consistency

`unsandboxed_module/1`'s `on_exit` revert called `Ecto.Adapters.SQL.Sandbox.mode(repo, :manual)`
raw and **discarded the result**, while the acquire on the line above matched `:ok` — the same
discarded-signal defect §1a just hardened. It now routes through `mode_manual!/2`, attributed to
the calling module.

---

## 7. Mutation checks (non-vacuity)

Each guard shown to fail when its defect is reintroduced, everything else in place. Every
mutation reverted from a byte-identical backup and the tree re-verified (§8).

| # | Defect reintroduced | Result |
|---|---|---|
| M1 | `mode_manual!/2` returns `Sandbox.mode/2`'s value verbatim again | **2 failures** — the refusal-raise test and the D-17-tally test |
| M2 | `checkout!/1`'s `on_exit` skips `stop_owner/1` for shared owners (a **live** leaked owner — operationally the ordering defect the directive hypothesised) | **15 failures** across 3 modules, every one `{:badmatch, :already_shared}`; `signature tally: already_shared=15`, `[VIOLATION] already_shared` fired |
| M3 | `:unknown` async classification falls through to `:ok` again | **2 failures** — both fail-closed guard tests |
| M4 | Exhausted bound raises regardless of holder liveness (pre-fix shape) | **2 failures** — the dead-holder test and the full-bound test |
| M5 | Dead-holder carve-out taken on the *first* probe, skipping the bound | **1 failure** — the full-bound test |

**M2 is the decisive one.** It is the exact proof the directive asked for: with the liveness
carve-out in place, a genuinely leaked **live** owner still produces the full HARNESS-01
signature — 15 raw badmatches and a `already_shared=15` tally. The carve-out masks nothing.

---

## 8. Acceptance

Every run from a freshly reset DB, `--warnings-as-errors`, read from raw `mix test` output only
— never the SuiteFloor ledger or the formatter.

| Gate | Command | Result | Exit |
|---|---|---|---|
| Dialyzer | `MIX_ENV=test mix dialyzer` | `Total errors: 16, Skipped: 16, Unnecessary Skips: 0` | 0 |
| Format | `mix format --check-formatted` | clean | 0 |
| Credo | `mix credo --strict` | `3906 mods/funs, found no issues.` | 0 |
| mailglass axis | `MAILGLASS_SCHEMA=mailglass mix test --seed 374117 --exclude requires_workspace` | 23 properties, **1556 tests, 0 failures**, 7 skipped (14 excluded) | 0 |
| public axis | `mix test --seed 783091 --exclude requires_workspace` | 23 properties, **1557 tests, 0 failures**, 7 skipped (13 excluded) | 0 |

`signature tally: already_shared=0, formatter_violations=0` on both axes.

**Test-count delta, reconciled exactly:** mailglass 1546 → 1556, public 1547 → 1557. Both +10 =
3 (`mode_manual!/2`) + 3 (fail-closed async guard, incl. its positive control) + 4
(`assert_manual!/3` classification). No pre-existing test was removed, skipped, excluded, or
weakened. `.dialyzer_ignore.exs` is byte-identical.

---

## 9. Deviations from the directed scope

1. **Task 2's root cause is corrected, not confirmed.** The directive named Class C (pool mode
   left `{:shared, pid}` by an acquire/release ordering defect). The CI log shows the ordering
   invariant held and the *release-verification bound* raised instead (§5). The directive's
   own instruction — "if you cannot localise it, say so plainly" — is met by localising it to a
   different defect, with the job log as evidence, rather than by fixing the hypothesised one.
2. **Diagnosed from the CI log, not from a local repro.** 11 local runs reproduced nothing, and
   §2 explains why they structurally could not. The fix is derived from the exact failure term
   plus `db_connection`'s manager source, and is proven by mutation (§7) rather than by
   before/after flake counts.
3. **Two fixes beyond the directed one**: the fail-closed async guard (§4, explicitly requested
   as an audit item, and it did turn up holes) and `unsandboxed_module/1`'s discarded revert
   (§6a, not requested — same defect class as Task 1, two lines).
4. **`@spec`s removed rather than narrowed** on two accessors (§1b/1c). Removing a spec is a
   reduction in declared surface; the reasoning for preferring it over a literal spec is written
   at the call site so a future reader does not "restore" it.

## 10. Not closed

- **The Class C flake is fixed at its verification layer, but has not been observed to
  recur-or-not on the real 1.18/OTP 27 CI leg.** No CI run was dispatched (process constraint).
  The next natural push to this branch is the confirmation; if
  `WebhookSignatureFailureTest` raises `LeakError` again with a **live** holder pid, this
  SUMMARY's §5 diagnosis is wrong and the Class C hypothesis is back on the table.
- **`webhook_signature_failure_test.exs` still runs 800 statements through a shared connection
  with the default settle bound.** With the liveness classification this is no longer
  load-sensitive, so the per-module `settle_attempts:` widening that
  `webhook_idempotency_convergence_test.exs` carries was deliberately **not** copied to it —
  that would have been the timeout-widening fix §6 rejects.
- **`probe/1` is untouched**, per the standing constraint, and remains mode-keyed rather than
  liveness-keyed (`live_holder/1`'s doc argues why that is correct for its consumer). A
  `{:shared, dead_pid}` observed at a module boundary would therefore still be reported by
  `SuiteTruthFormatter` as a hygiene violation. Not observed on any run here
  (`formatter_violations=0` throughout), and healing at a module boundary is orders of
  magnitude more settled than at an `on_exit`; recorded so a future occurrence is not a surprise.
- **The formatter's `:module_finished`-only blind spot is unchanged** (143-MECHANISM.md §7).
  Nothing here narrows it.

## Self-Check: PASSED

- `test/support/sandbox_ownership.ex` — modified, present
- `test/support/suite_floor.ex` — modified, present
- `test/mailglass/test_support/sandbox_ownership_test.exs` — modified, present
- `.dialyzer_ignore.exs` — unchanged (`git diff` empty)
- Working tree clean of all five mutations; dialyzer, format, credo and both acceptance axes
  re-verified on the committed state
