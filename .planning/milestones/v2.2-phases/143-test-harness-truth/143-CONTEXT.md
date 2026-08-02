# Phase 143: Test-Harness Truth - Context

**Gathered:** 2026-07-29 (discuss mode, four parallel research agents + live verification)
**Status:** Ready for planning

<domain>
## Phase Boundary

The Ecto Sandbox ownership-leak mechanism is understood and fixed — not masked, not tagged away, not
silenced by serialization — Core Full Suite is genuinely green across the full toolchain/schema matrix,
and there is a recorded, evidence-backed answer to whether it should gate a release.

**In scope:** HARNESS-01, HARNESS-02, HARNESS-03, HARNESS-04.

**Out of scope** (inherited from `.planning/REQUIREMENTS.md` "Out of Scope" and `.planning/STATE.md`
"v2.2 Scope Locks", both binding):

- **No CI topology rewrite.** No splitting, merging, or restructuring workflows beyond what a named
  requirement demands. The authorized job-shape changes are exactly: the two `advisory-matrix.yml`
  renames (D-19), two `env:` additions (D-15), and the `gate-ci-green` extension (D-22).
- **Do NOT move Core Full Suite into `ci.yml`.** Explicitly rejected in REQUIREMENTS.md — four matrix
  legs on every PR is the wall-clock cost SEED-006 exists to address. HARNESS-04 is **publish-gating
  only**, never merge-gating.
- **No release cut.** v2.2 ships no Hex release; 2.1.3 / 2.1.3 / 2.1.1 stand. This phase's gate change
  therefore ships unexercised by a real release — D-29 covers how it gets exercised anyway.
- **No new runtime dependency**, and no new dev/test dependency either — every mechanism below uses
  `ex_unit`, `ecto_sql`, `db_connection`, `credo`, and `jason`, all already present.
- **Never manufacture green.** No `@tag :skip`, no new `--exclude` tags, no blanket `async: false`.
  SEED-007 and HARNESS-03 forbid it. **Phase 143 changes no file's `async:` value** (D-11).
- **No lane re-classification other than Core Full Suite.** Phase 141 recorded the 24-row disposition
  table; this phase adds a *separate* advisory-matrix axis and touches no `ci.yml` row.
- Product features, admin UI work, `ICON-EXISTS-GATE` (CONFORM-02, Phase 144), the publish fan-out race
  (TRUTH-08, Phase 144), the `if: pat_present`-skip-but-green shape (TRUTH-02, Phase 144).

</domain>

<decisions>
## Implementation Decisions

All four gray areas were researched in parallel by dedicated agents; every load-bearing claim below was
independently re-verified against the repo, `deps/`, or the live GitHub API before being locked here.
Citations are `file:line` in this worktree unless marked otherwise.

### A. Mechanism Confirmation (HARNESS-01)

- **D-01: The mechanism is confirmed, and it is not what HARNESS-01 and ROADMAP criterion 1 say it is.**
  `:already_shared` is returned from exactly one place — `deps/db_connection/lib/db_connection/ownership/manager.ex:148-159`
  — and **only when the pool is in `{:shared, pid}` with that `pid` still alive and different from the
  requester**. A *dead* shared owner is transparently replaced (`manager.ex:156`). `start_owner!/2` does
  `:ok = mode(repo, {:shared, self()})` at `deps/ecto_sql/lib/ecto/adapters/sql/sandbox.ex:458` inside an
  **unlinked** `Agent.start` (`:451`) — that bare `:ok =` is the `{:badmatch, :already_shared}` in SEED-007.

  **The account:** a test acquires shared mode via an unlinked owner Agent, and the code that releases it
  is separated from the acquisition by statements that can raise. When one raises, the owner Agent
  survives — alive, holding `{:shared, agent_pid}` — and every subsequent `async: false`
  `start_owner!(shared: true)` raises until something calls `Sandbox.mode/2` or the ownership timeout
  expires. Three corrections follow, all verified:

  1. **The nine `:auto`-mode files HEAL a leaked owner; they do not collide with it.** `Sandbox.mode(repo, :auto)`
     checks the proxy in and resets the mode (`manager.ex:402` `unshare/2`). ROADMAP criterion 1's stated
     leading hypothesis is half backwards. This also explains why the lane is 194-red rather than
     668-red, and why no single file reproduces it.
  2. **`Mailglass.DataCase` is EXONERATED.** HARNESS-01 names it "the dominant shared-mode acquisition
     site, 35 files" and therefore a leading candidate. `data_case.ex:35-36` registers
     `on_exit(stop_owner)` on the line *immediately following* acquisition — Ecto's own documented
     idiom, and the correct discipline. It is the control, not the culprit.
  3. **Only `async: false` tests are affected.** `start_owner!(shared: false)` succeeds under a leaked
     owner. This is a falsifiable prediction the Wave-1 evidence must satisfy (D-04).

  — **Reversibility:** reversible — a written account; superseded by better evidence if Wave 1 refutes it.

- **D-02: The two confirmed leak sites, both verified by direct read.**
  - `test/mailglass/properties/webhook_idempotency_convergence_test.exs:51-69` — **two** leak windows
    around a **ten-minute** `ownership_timeout`: (a) `CitextProbe.run`, `Tenancy.put_current`, and two
    `TRUNCATE`s sit *between* `start_owner!(shared: true)` at `:52` and the `on_exit` registration at
    `:64` — a raise there leaks with no cleanup registered at all; (b) inside `on_exit`,
    `Sandbox.stop_owner(owner)` at `:68` is the **last** statement after two `TRUNCATE`s that can raise.
    The suite reports **31 `42P01 undefined_table` failures** — a raising TRUNCATE in either window is
    sufficient. The v2.2 citext fix, which made `CitextProbe` re-raise permanent faults instead of
    masking them, widened window (a).
  - `test/support/mailer_case.ex:93` vs `:185` — the same shape, with **92 lines** of unguarded window
    including `Fake.checkout()`, `Phoenix.PubSub.subscribe`, and `start_supervised!({Oban, ...})` at
    `:160` (whose own moduledoc warns the `oban_jobs` table may be missing).

  **Corollary the planner must budget for:** the 194 `:already_shared` and the 31 `42P01` failures are
  most likely **one causal chain, not two**. Treat them as a single investigation.
  — **Reversibility:** reversible.

- **D-03: What is confirmed vs. what Wave 1 must still prove.** The *mechanism class* is confirmed
  (synthetic reproduction against the real `Mailglass.TestRepo`: leak a live shared owner → next
  `start_owner!(shared: true)` raises `{:badmatch, :already_shared}` at `sandbox.ex:458`; `shared: false`
  survives; `stop_owner` recovers; `mode(:auto)` heals). **What is NOT yet proven is which actual test
  leaks first in the real suite.** HARNESS-01's "empirically confirmed before the fix is written" bar is
  met only when the instrumented run names the culprit. Wave 1 still runs, and it may refute D-01/D-02.
  — **Reversibility:** reversible.

- **D-04: The evidence bar is artifact class (b+): a written mechanism account, backed by a committed ledger dump from an instrumented full-suite run, plus a deterministic *mechanism-level* regression test.** Do **not** promise a deterministic *full-suite* reproduction — SEED-007 establishes that no
  single file reproduces it, and the healing behavior (D-01.1) makes even a fixed file-pair unstable
  across seeds. Promising it would set the phase up to either fail or fake it.

  The instrumented run must satisfy two falsifiable predictions, both recorded pass/fail:
  1. Every `:already_shared` failure is in an `async: false` module; **zero** in `async: true`.
  2. The test immediately preceding the first `:already_shared` shows a ledger start with no matching stop.

  — **Reversibility:** reversible.

- **D-05: Ordering/seed bisection is REJECTED as the diagnostic.** Two independent reasons, both verified:
  (a) because `:auto` files heal (D-01.1), leaker and victim are not adjacent, so delta-debugging
  converges on the wrong pair; (b) `--max-cases` is a no-op for this bug — ExUnit runs sync modules
  strictly **after all** async modules, one at a time (`ExUnit.Runner.async_loop/4`), so there is no
  async/sync overlap to serialize away. Keep `--seed 0` only as a *stabilizer* so the ledger artifact is
  reproducible, and record the `--max-cases 1`-changes-nothing negative control once, as evidence that
  serialization is not the answer. Also **rejected:** an ExUnit `:telemetry` handler (neither
  `Ecto.Adapters.SQL.Sandbox` nor `DBConnection.Ownership` emits ownership telemetry — verified against
  `deps/`; this is a dead end, do not plan it), and a `dev/mix/tasks/` diagnostic task (the
  instrumentation must run *inside* `mix test`; use `MAILGLASS_SANDBOX_TRACE=1 mix test` instead, so the
  lane command stays unchanged).
  — **Reversibility:** reversible.

### B. Fix Shape & Recurrence Guard (HARNESS-01 / SEED-007 DoD #3)

- **D-06: One sanctioned door — `Mailglass.TestSupport.SandboxOwnership` at `test/support/sandbox_ownership.ex`.**
  Its non-negotiable invariant: **the release callback is registered before any other setup work can
  raise**, and every Ecto return value is matched rather than discarded. Public surface:
  `checkout!/1`, `unsandboxed_module/1` (a `setup` callback), `unsandboxed/2` (wrapping
  `Sandbox.unboxed_run/2`), `probe/1`, `assert_manual!/2`, `live_holder/0`.

  **Placement is deliberate:** `test/support/` — not `lib/` (which would incur `docs/api_stability.md`
  + `test/mailglass/stability_contract_test.exs` obligations in the **required** Support Contract Core
  lane, for zero adopter value) and not `dev/` (that is maintainer Mix tooling). `test/support/` is
  already on `elixirc_paths(:test)` (`mix.exs:115`), excluded from the Hex tarball by the `files:`
  whitelist, and already hosts `Mailglass.TestSupport.CitextProbe` — so the namespace is established.
  — **Reversibility:** costly — undo touches 13 test files plus the Credo check's allowlist.

- **D-07: Second confirmed defect (S2) — four raw `Sandbox.mode(repo, {:shared, self()})` calls are provable no-ops whose discarded return value is telling them so.** Verified at `mailer_case.ex:158`,
  `mailer_case.ex:248`, `deliver_many_test.exs:17`, `deliver_later_test.exs:37`. All four run *after*
  `start_owner!(shared: true)` has already put the pool in `{:shared, agent_pid}`; the test process is
  not the registered owner and the agent is alive, so `manager.ex:154` returns `:already_shared` and
  changes nothing. The comment at `mailer_case.ex:153-157` asserts a guarantee the code does not
  provide. **A check that cannot do its job and reports green — inside the test harness of the milestone
  that exists to eliminate exactly that.**

  **Correction to the research, verified here:** these are *redundant*, not *broken*. The intent ("Oban
  internal processes can access the DB") is **already satisfied** by `start_owner!(shared: true)` — the
  pool genuinely is in shared mode. So the fix is **deletion plus comment correction, and it is a
  behavior-preserving change**. Do not plan for `set_mailglass_global` semantics to change; they will
  not. This removes four of the six raw mode call sites.
  — **Reversibility:** reversible.

- **D-08: Recurrence guard is TWO layers, because neither substitutes for the other.**
  - **Detection — one ExUnit formatter, `Mailglass.TestSupport.SuiteTruthFormatter`
    (`test/support/suite_truth_formatter.ex`).** Probes the pool at every `:module_finished` of an
    `async: false` module, names the offending module the instant it leaks, heals the pool so the
    remaining ~1200 tests still yield signal, and records a violation. **Zero opt-in — ExUnit routes
    every module through it regardless of case template**, so a new mode-switching file is covered the
    day it is written. A per-file `on_exit` postcondition (what SEED-007 DoD #3 literally suggests) is
    **rejected as a standalone** because it is opt-in — a new file that forgets it is invisible, which
    is the exact failure mode being guarded. It is folded into `checkout!/1` instead, where it cannot be
    forgotten.
  - **Prevention — custom Credo check `Mailglass.Credo.NoRawSandboxOwnership`
    (`credo_checks/no_raw_sandbox_ownership.ex`).** Bans `Ecto.Adapters.SQL.Sandbox.{mode, start_owner!,
    stop_owner, checkout, checkin}` under `test/` outside the helper. This is the repo's native
    enforcement idiom — 20 checks already live in `credo_checks/`, `.credo.exs` already lints `test/`
    and already carries `requires: ["./credo_checks/*.ex"]`. Skeleton and config shape copy
    `no_raw_swoosh_send_in_lib.ex` verbatim (module-stack prewalk, alias resolution,
    `included_path_prefixes`, `allowed_modules`); it must resolve `alias Ecto.Adapters.SQL.Sandbox`,
    which six of the nine `:auto` files use.
  — **Reversibility:** reversible.

- **D-09: ONE formatter, not three.** All three research streams independently proposed a formatter
  (ownership ledger, hygiene probe, failure-signature tally). They are merged into
  `SuiteTruthFormatter`, which handles `:module_finished` (hygiene probe + heal) and `:test_finished`
  (failure-signature tally), and **delegates every policy judgment to pure functions** on
  `SandboxOwnership` and `SuiteFloor` so the negative-control tests drive the real code path rather than
  a re-implementation. Registered via `ExUnit.configure(formatters: [ExUnit.CLIFormatter,
  Mailglass.TestSupport.SuiteTruthFormatter])` in `test_helper.exs` — **not** the `--formatter` CLI flag,
  which *replaces* the default list.
  — **Reversibility:** reversible.

- **D-10: The healing call is safe only because sync modules run strictly after, and strictly serially to, async modules** (`ExUnit.Runner.async_loop/4` waits for `map_size(running) == 0` before spawning
  any sync module). Healing via `Sandbox.mode(repo, :manual)` checks in **all** connections, so running
  it while async modules were live would be catastrophic. The reliance must be commented at the call
  site; it is exercised on both the 1.18/OTP27 and 1.19/OTP28 legs, so a future Elixir change surfaces
  as a matrix divergence rather than silent corruption.
  — **Reversibility:** reversible.

- **D-11: Async policy — a test earns `async: false` only by mutating state global to the pool or the VM.** Exactly three sanctioned reasons: (1) pool-mode mutation (`shared: true` or
  `unsandboxed_module/1`), (2) `Application.put_env/3` on a key the code under test reads (Oban.Testing
  mode, `:async_adapter`, `:adapter`), (3) committed non-transactional DB state (DDL, TRUNCATE,
  migrations). **Cross-process delivery is NOT a reason** — `Sandbox.allow/3` covers it. Reasons 1 and 3
  become mechanical (both helpers raise from an `async: true` module, in the shape of the existing I-12
  Oban guard at `mailer_case.ex:84-91`); reason 2 stays convention plus that guard. Policy text lives in
  the `SandboxOwnership` moduledoc, where a contributor lands from the raise.

  **Phase 143 changes no file's `async:` value.** SEED-007 forbids serializing the bug away, and there
  is a second reason: HARNESS-02's four-leg evidence is only interpretable if the async/sync split is
  byte-identical before and after.
  — **Reversibility:** reversible.

- **D-12: `Sandbox.unboxed_run/2` becomes the documented idiom for new tests needing committed writes, but migrating the existing nine `:auto` files to it is DEFERRED.** Six of them genuinely need pool-wide
  `:auto` because `Ecto.Migrator.with_repo/2` spawns a process `unboxed_run` cannot cover
  (`migration_test.exs:19-22` documents this). The three property files could migrate, but that is a
  test redesign mid-milestone, and Phase 143's job is signal restoration. Ship `unsandboxed/2` as the
  preferred forward idiom; migrate the nine files only to `setup :unsandboxed_module`, whose
  registered-first revert preserves today's semantics exactly (reverse `on_exit` order ⇒ the file's own
  baseline-restore still runs while `:auto` is in effect). **`migration_test.exs` and
  `upgrade_v2_schema_migration_test.exs` have non-trivial teardown and must be verified file-by-file.**
  — **Reversibility:** reversible.

### C. Anti-Vacuity Proof (HARNESS-03)

- **D-13: Counts come from `ExUnit.after_suite/1`, never from parsing the CLI summary line.** The
  callback receives `%{total:, failures:, excluded:, skipped:}` — typespec verified **identical** in
  Elixir v1.18.4 and v1.19.5 source. Shell parsing is rejected on correctness, not just brittleness:
  `mix test`'s `N tests` is `total - excluded`, **not** executed, so a shell parser is wrong before it
  starts; the line is also pluralized and conditional across versions. `after_suite` additionally
  exposes `ExUnit.configuration()[:exclude]` — the *effective* merged tag set including CLI
  `--exclude` — which D-14 depends on.
  — **Reversibility:** reversible.

- **D-14: The load-bearing invariant is the PINNED EXCLUSION-TAG ALLOWLIST, not the count floor.**
  Checked by set-equality **in both directions** against the `--exclude` tokens in `advisory-matrix.yml`
  plus `test_helper.exs`'s conditional `ExUnit.configure(exclude: [:public_only])`. A new `@tag :foo` +
  `--exclude foo` fails on the *tag name* before any arithmetic matters; both-directions equality also
  kills dead allowlist entries. The floor answers "how many ran"; this answers "which categories were
  allowed not to run," and it is the stronger guarantee.
  — **Reversibility:** reversible.

- **D-15: Policy lives in `Mailglass.TestSupport.SuiteFloor` (`test/support/suite_floor.ex`) — hardcoded constants, deliberately.** A direct sibling in spirit to `Mailglass.CILanes`: hardcoded values, a
  drift meta-test, a negative control. Committed baseline JSON/text files are **rejected** — a threshold
  a machine rewrites is an artifact, not a decision (the SimpleCov `.last_run.json` failure mode:
  ratchets on flakes, awkward under parallel CI). Enforcement is opt-in via `MAILGLASS_SUITE_FLOOR=1`,
  set on the two `advisory-matrix.yml` full-suite steps, so focused local runs and `mix verify.*`
  aliases never misfire — and the opt-in itself is held in place by the drift test (D-18).
  — **Reversibility:** reversible.

- **D-16: Floors are PER-SCHEMA and comparison is `>=` with manual raises.** The legs legitimately
  differ — `test_helper.exs` excludes `:public_only` on any non-public schema. A single global floor
  would have to equal the minimum, blinding the `public` leg. `==` is rejected (fails on every added
  test); auto-update from CI is rejected (D-15). Rot is handled by a **warn-only nudge** into
  `$GITHUB_STEP_SUMMARY` when `executed > floor + 40`, never a hard failure. Measure all four legs before
  pinning; if 1.18 and 1.19 diverge, re-key on `{schema, elixir_minor}` rather than lowering to the
  minimum. **Add no safety margin** — a margin is slop that silently absorbs the first regression.

  **`skipped == 0` is REJECTED because it is false today** — 5 × `@tag :skip` + 3 × `@moduletag :skip`
  already exist. Pin a measured *ceiling* instead.
  — **Reversibility:** reversible.

- **D-17: The `:already_shared` count becomes a first-class named signature, not a grep and not an inference.** ROADMAP criterion 3 wants "exactly zero, not fewer." "Implied by `failures == 0`" is true
  today and worthless tomorrow: the moment the lane goes red for three unrelated reasons plus forty
  leaked owners, it reads as "43 failures" and the regression identity is lost — **precisely the SEED-007
  pain**, where every one of these was reported as "citext probe exhausted" and the lane looked like a
  flaky database race for months. Grepping the workflow log is rejected: log text is not a contract, and
  it would false-positive on any test *named* after the bug — a test someone will plausibly write during
  HARNESS-01. Implementation: the formatter (D-09) classifies failures by named signature
  (`:already_shared`, `:sandbox_ownership`, `:undefined_table`, `:citext_probe`, `:other`) and
  `SuiteFloor` asserts `already_shared == 0`.

  **Signature-laundering guard:** because D-06 replaces the raw `{:badmatch, :already_shared}` with a
  composed error, the tally must count **both** the raw signature and the new guard's error, or
  criterion 3 passes vacuously. This is mandatory, not optional.
  — **Reversibility:** reversible.

- **D-18: Two probes, different in kind — both required.**
  1. **"The floor fails when tests are removed/excluded" needs NO CI.** It is pure arithmetic over the
     pure `SuiteFloor.violations/1`, driven by synthetic reports in
     `test/scripts/suite_floor_contract_test.exs` — the `lane_classification_drift_test.exs:161-229`
     negative-control idiom. It runs in the **required** `mix_task_tests` lane via
     `verify.ci_lane_contract`, whose `test test/scripts/` glob auto-collects it (**no `mix.exs` change
     needed**).
  2. **"The lane catches a real regression" genuinely needs CI**, because the thing under test is the
     wiring. Reuse `gate-self-test.yml` with two new inputs (`required_only: false`,
     `deadline_minutes`) — `workflow_dispatch` only, run once as phase evidence, **never scheduled**
     (a scheduled probe opens real PRs against `main` on a cadence and burns SEED-006 wall-clock).
     Add a distinct **"the polled check never appeared"** outcome that prints the checks it *did* see,
     rather than passing by timeout.
  — **Reversibility:** reversible.

- **D-18a: FINDING — the existing `gate-self-test.yml` is vacuous against `CI Green`, and Phase 143 is the first honest use of it.** Verified: the only two `mix test` invocations in `ci.yml` (`:355`,
  `:362`) are both `working-directory: mailglass_inbound`; every root-project lane runs an explicit file
  list (`verify.support_contract.core`) or a directory glob (`verify.ci_lane_contract` →
  `test test/scripts/`). **No `ci.yml` lane runs the root `mix test` over `test/`**, so the injected
  `test/gate_self_test/intentional_failure_test.exs` is executed by no required lane and a default-input
  run should report `leaked`. `Core Full Suite` is the first lane whose run command actually reaches the
  injection point. **Record this finding and verify it live; do NOT fix `ci.yml` coverage here** — that
  is a topology change this phase is forbidden. Route it to Phase 144 / `.planning/TOOLING-DEFECTS.md`.
  — **Reversibility:** reversible.

- **D-18b: Explicitly declined as over-engineering** (record the reasoning so it is not re-litigated):
  mutation testing (`muzak` unmaintained since Dec 2022, `muzak_pro` commercial; answers a different and
  much larger question at N-mutants × a 1401-test Postgres suite — directly opposed to SEED-006);
  coverage gates / `excoveralls` (measures line execution, not test execution; new dep; four legs of
  wall-clock); uploading counts to an external service (new trust boundary, and a check that "cannot
  verify" when the service is down — the exact anti-pattern v2.2 exists to kill); a per-test-name
  manifest (fails on every rename); flaky-test quarantine/retry (SEED-006 names it explicitly).

  **Accepted gap, named rather than papered over:** none of this proves the tests *assert usefully* — a
  test rewritten to `assert true` still counts as executed. Say so in the `SuiteFloor` moduledoc so
  nobody mistakes the floor for a stronger claim than it makes.
  — **Reversibility:** reversible.

### D. Publish Gating & Lane Naming (HARNESS-04)

- **D-19: Core Full Suite BECOMES publish-gating — but only the two Elixir 1.18 / OTP 27 legs**
  (`schema public` and `schema mailglass`), matched by **exact equality** on runtime name. The
  1.19/OTP 28 legs, Provider Compatibility, and Inbound Full Suite stay advisory — classified,
  enumerated, warned on, never blocking.

  **The trade, argued honestly.** Against gating: the ecosystem norm is dramatically weaker (Bandit
  publishes on tag push with *zero* test gating; Phoenix, Ecto, Oban, Req, Broadway have no publish gate
  at all), and on a hands-free auto-merging pipeline a wedged gate is a silent unattended stall. For
  gating: the seven required lanes are narrow contract/file lists, so **today a total core regression can
  reach Hex without a single red light** — which is SEED-007's corrected finding. The asymmetry decides
  it: a blocked release costs the maintainer 30 minutes and one dispatch; a published broken core costs
  every adopter and **cannot be unpublished after 60 minutes on Hex**. Gate — and pay for it with a
  documented override (D-23) rather than by narrowing the gate.

  **Why the floor pair only:** this repo's own prior research already settled it —
  `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md:167` ("Keep branch protection tied to a
  smaller required matrix") and `:329`, under anti-patterns, *"use one gigantic matrix as required
  status."* Ecto and Oban both confine `--warnings-as-errors` to a single matrix row for the same
  reason. LD-13's floor-coincidence invariant is preserved: the gated legs are exactly the declared
  `~> 1.18` floor.
  — **Reversibility:** costly — undo touches the registry, `publish-hex.yml`, `MAINTAINING.md`, and
  four drift assertions; but it is a config-shaped change, not a contract break.

- **D-20: `Inbound Full Suite Advisory` is NOT gated despite being green today.** It runs with `--seed 0`
  pinned specifically to dodge a known phase-45 property-test pool flake (`advisory-matrix.yml:353` and
  its comment). A lane whose green depends on a hardcoded seed chosen to avoid a known nondeterminism is
  not trustworthy enough to gate a publish. Record the reason; revisit when SEED-006/LD-8 removes the pin.
  — **Reversibility:** reversible.

- **D-21: Renames — required, but for a sharper mechanical reason than "honesty."**
  - `core_full_suite_advisory` → job id `core_full_suite`, name `Core Full Suite (Elixir ${{...}} / OTP ${{...}} / schema ${{...}})`
  - `core_latest_elixir_advisory` → job id `core_full_suite_next_toolchain_advisory`, name
    `Core Full Suite Next Toolchain Advisory (...)`

  Honesty is the Phase 141/142 precedent (`Credo Strict` → `Design System Conformance`;
  `Deps Audit Advisory` → `Deps Audit`) — a lane that gates a publish while calling itself "Advisory" is
  the defect this milestone exists to fix. "Next" rather than "Latest" because *latest* implies
  preferred; *next* reads as the forward-compat canary it is (brand book: prefer the direct word).

  **The mechanical reason, verified live against three name forms.** Both jobs currently interpolate the
  **same** `name:` template, and GitHub reports three different strings depending on event:
  | Event | Reported name |
  |---|---|
  | `push` (run `30464215272`) | four distinct, fully-interpolated, **suffix-free** names |
  | `pull_request` (run `30464262578`) | the 1.19 job collapses to **ONE `skipped` entry** carrying the **literal uninterpolated template** `Core Full Suite Advisory (Elixir ${{ matrix.elixir }} / OTP ${{ matrix.otp }} / schema ${{ matrix.schema }})` — byte-identical to the 1.18 job's declared name |
  | declared (`CIYaml.job_names/1`) | one entry — `MapSet.new(Map.values(...))` **collapses the two identical templates** |

  So (a) exact-equality matching is safe on the gate's path because publish reads a tag/push run where
  names are interpolated and suffix-free — **no rename is needed for gate matching**; but (b) any
  registry↔YAML set-equality drift test would claim 4-leg coverage while proving 2, and (c) on PR runs a
  skipped job reports a string identical to the gating job's declared name. **That** is what makes the
  rename load-bearing. `Core Full Suite (` and `Core Full Suite Next Toolchain Advisory (` diverge at
  position 16, so neither is a prefix of the other.
  — **Reversibility:** costly — display-name changes ripple to `MAINTAINING.md`, drift tests, and
  maintainer muscle memory.

- **D-22: `gate-ci-green` must SELF-HEAL `advisory-matrix.yml` by dispatch — this is the default path, not an edge case.** Verified against the live API:
  | SHA | commit | `ci.yml` runs | `advisory-matrix.yml` runs |
  |---|---|---|---|
  | `25c74ca0` | `chore: release main (#149)` — **bot-merged** | 1 (`workflow_dispatch`, the existing self-heal) | **0** |
  | `3edc95f0` | human-merged | 1 (`push`) | 1 (`push`) |

  The release-please anti-recursion gap suppresses `push` for **both** workflows, and
  `advisory-matrix.yml` has no `release:` trigger — so **every** release would deadlock on `(missing)`
  without a dispatch. Implement as **one step, two dispatches, one shared 30-minute deadline, polled
  concurrently** — never a second serial 30-minute wait, which would turn a 30-minute worst case into 60.
  — **Reversibility:** reversible.

- **D-23: The gate decision table — three rules, stated plainly.**
  1. **A gating leg that is absent is not green.** `(missing)`, `cancelled`, and `skipped` all BLOCK with
     the same weight as `failure`. This is the v2.2 core theme, and it mirrors the existing
     `REQUIRED_LANES` presence loop that `lane_classification_drift_test.exs:267-281` already guards.
  2. **Absent is never *permanently* blocking** — Phase 0 self-heals by dispatch (D-22), the deadline is
     bounded, and every message names the exact recovery command. The deadlock HARNESS-04's parenthetical
     warns about is prevented by *scope* (floor legs only) + *self-heal* + *override*, not by softening
     "missing."
  3. **An advisory leg's absence is warned, not blocked** — honest, because its recorded classification
     says it gates nothing. The 1.19 legs' absence on `pull_request` is a *designed* outcome of
     `if: github.event_name != 'pull_request'`, and the message must say so rather than leaving the
     maintainer to wonder.
  4. **An unclassified advisory-matrix lane that is RED blocks; green warns** — mirroring the existing
     `publish-hex.yml:351-354` posture. The hard failure belongs in the drift meta-test on the PR that
     adds the lane.

  Plus a **dispatch-only override** (`skip_core_full_suite_gate` + a *required* free-text
  `core_full_suite_gate_skip_reason`), inert on `github.event_name == 'release'` so the hands-free path
  can never self-skip, with the reason echoed into `$GITHUB_STEP_SUMMARY`. This is the release-availability
  half of the trade and is what makes gating affordable; it must not become the habit (D-30 risk).
  — **Reversibility:** reversible.

- **D-24: Registry shape — a THIRD axis, disjoint by construction.** Add
  `@advisory_matrix_gating_lanes` (2) and `@advisory_matrix_advisory_lanes` (5) to
  `test/support/ci_lanes.ex`, with accessors. **Do NOT fold them into `all_classified_lanes/0`** — that
  accessor is bound by set-equality to `ci.yml`'s 24 jobs, and folding would break four assertions at
  once. The existing hardcoded counts (`:71`=3, `:88`=12, `:105`=2, `:143`=7, `:252`/`:257`/`:455`=24)
  are **unchanged**; this change is additive, not a bucket move. State that explicitly in the plan so a
  planner does not "helpfully" merge them.

  Requires new `Mailglass.CIYaml.expanded_matrix_job_names/1` (template + `matrix.include` expansion to
  runtime names), because `job_names/1` returns *declared* names and collapses the duplicate templates.
  — **Reversibility:** reversible.

- **D-25: `MAINTAINING.md` gets a NEW `## Advisory Matrix Lanes` section under its OWN heading.**
  ⚠️ **The single easiest thing to get wrong in this phase:** `parse_disposition_table/1`
  (`lane_classification_drift_test.exs:613-626`) bounds itself via `find_required_checks_section/1`'s
  `"\n## "` split and asserts exactly 24 rows at `:455`. Adding rows inside `## Required Checks` turns
  that into a 31-row failure. The 7-row advisory-matrix table must live under its own `## ` heading.
  Also rewrite `:259-265` ("none gates a merge" is now half-true) and amend `:212-216` (the
  never-promote-a-matrix-lane note is true for *statically*-named matrix jobs; advisory-matrix jobs
  interpolate every axis and carry no runtime suffix, which is why exact-equality gating is safe there).
  — **Reversibility:** reversible.

- **D-26: Branch protection is NOT touched.** The required-context set stays exactly
  `{CI Green, Guard Release Trigger}`, asserted by `required_checks_test.exs:45-58`. Publish-gating lives
  entirely inside `gate-ci-green` and is not a GitHub required status check. Touching
  `scripts/setup_branch_protection.sh` would risk re-creating the job-`id`-vs-display-`name` incident
  that opened this milestone. Also **not** touched: `ci_parity_drift_test.exs` — `mix ci` runs
  `--exclude flaky` while the lane runs `--exclude requires_workspace`, so adding a parity matcher would
  be a false parity claim. Record as a deliberate non-change (parity ≠ classification, Phase 141 D-02).
  — **Reversibility:** reversible.

### E. Sequencing & Evidence

- **D-27: Wave order is fixed by the requirements' own sequencing constraints.**
  - **Wave 1 — Evidence before fix (HARNESS-01).** Instrumentation + ledger + instrumented full-suite
    runs on both schema axes at `--seed 0`, captured **before any fix**. Records the two D-04
    predictions pass/fail. May refute D-01/D-02; the plan must accept that.
  - **Wave 2 — Fix + guard.** `SandboxOwnership`, call-site migration (13 files), the four S2 deletions
    (D-07), the Credo check, the formatter's hygiene half.
  - **Wave 3 — Anti-vacuity + rename.** `SuiteFloor`, signature tally, `suite_floor_contract_test.exs`,
    the two `advisory-matrix.yml` renames + `CIYaml.expanded_matrix_job_names/1` + registry axis + drift
    assertions + `MAINTAINING.md` section. Floors are **measured from green CI runs, not locally**, so
    this wave's floor-pinning task depends on Wave 2 being green.
  - **Wave 4 — Gating (HARNESS-04), behind a blocking checkpoint (D-28).**

  The rename lands in Wave 3, **decoupled from gating** — it is independently valuable (it fixes the
  declared-name collision so the drift tests can be honest) and safe without any gate change.
  — **Reversibility:** reversible.

- **D-28: A D-14-style blocking checkpoint gates Wave 4 — "observed green in the shape the gate will actually read it," not "merged."** All five must hold and be pasted into the phase artifact:
  1. Both gating legs green on **three consecutive completed runs across three distinct `main` SHAs**
     (ROADMAP criterion 2's "repeated runs and seeds").
  2. At least one of those is a **`schedule` (cron)** run — plain `main` SHA, cold cache, no PR context.
  3. One **`workflow_dispatch` run on a tag-shaped ref** with both gating legs green. This is the only
     proof of the exact code path the gate will use, and the one nobody would think to run.
  4. HARNESS-03's deliberate-failure probe has **already gone red** against the renamed lane. A lane
     never observed catching an injected regression must not be given veto power over a publish.
  5. The executed-test-count floor is merged and green — otherwise the gate would enforce a vacuum.
  — **Reversibility:** reversible.

- **D-29: The gate gets exercised despite "no release cut" — a rehearsal PAIR, both recorded as criterion-4 evidence.**
  - **Positive:** after the commit lands on `main`, create a throwaway annotated tag on `main`, dispatch
    `publish-hex.yml` with `dry_run: true`. `publish-core`'s "Skip if version already on Hex" guard
    (`publish-hex.yml:394-401`) resolves the existing version as published and skips, so there is no
    publish side effect. **The tag must be created AFTER the merge** — `workflow_dispatch` runs the
    workflow file as it exists at the dispatched ref, so dispatching against an existing release tag
    would run the *old* gate and prove nothing.
  - **Negative:** a branch with one deliberately failing core test, tagged, dispatched with
    `dry_run: true`; confirm the gate blocks and `publish-core` never starts. This is what turns ROADMAP
    criterion 4's "demonstrably blocks a Hex publish (not merely a PR merge)" from an assertion into
    evidence.
  - Delete both tags afterward; record both run URLs.
  — **Reversibility:** reversible.

- **D-30: Known risks accepted, recorded rather than discovered later.**
  - **Fan-out multiplication (live today):** the last release fired **two** `publish-hex` runs within 2
    seconds (the Phase 144/TRUTH-04 race). Both would find zero advisory-matrix runs and both dispatch.
    Mitigate by querying on `head_sha` (both tags resolve to the same SHA) plus a short randomized
    settle before dispatching, re-checking after. Worst case is one redundant ~10-minute run.
    **Do NOT** change `advisory-matrix.yml`'s concurrency group to `github.sha` to dedupe — with
    `cancel-in-progress: true` the two runs would cancel each other and **both** gates would read
    `cancelled` and block. Add a comment pinning the current group shape as load-bearing.
  - **Floating toolchain on a gating lane:** the legs resolve `elixir-version: "1.18"` loosely while the
    artifact is validated with `.tool-versions` strict, so a new 1.18.x deprecation warning can turn the
    release gate red with no repo change. **Keep it floating** — "supports Elixir 1.18" means adopters
    compile on whatever 1.18.x they have, so a warning-level regression *is* an adopter-visible defect
    the maintainer should see before publishing. The override is its pressure valve.
  - **Wall-clock:** every release now waits for a cold-cache dispatched matrix run (~10:30 observed).
    Noted as a SEED-006 input; do not optimize here.
  - **Credo Strict is publish-gating, not merge-gating** (TRUTH-09), so a raw `Sandbox.mode` call can
    merge and only bite at publish. Promoting that lane is out of scope. Net posture after this phase:
    two independent **publish-gating** layers, zero merge-gating for sandbox hygiene. Record as a known,
    bounded gap.
  - **New YAML parsing is vacuous-pass-prone** — `expanded_matrix_job_names/1` must carry the
    `required_checks_test.exs:30-34` anti-vacuity idiom plus a negative control.
  — **Reversibility:** reversible.

- **D-31: Upstream artifact amendments this phase MUST make** (Phase 141 set the precedent with its
  TRUTH-09 requirement amendment — never silently diverge from a requirement):
  - **HARNESS-01** in `.planning/REQUIREMENTS.md`: `Mailglass.DataCase` is exonerated as a candidate; the
    confirmed sites are `webhook_idempotency_convergence_test.exs` and `mailer_case.ex`'s acquire/release
    gap. The `mailer_case.ex:158`/`:248` entry is correct but for a different reason than stated (D-07).
  - **ROADMAP Phase 143 criterion 1**: the `:auto` files *heal* rather than *collide*; record the
    corrected mechanism.
  - **HARNESS-02 vs HARNESS-04 scope split**: HARNESS-02 is judged on lane content (**all four** legs
    green in the evidence); HARNESS-04's gating scope is deliberately narrower (**two** legs). State this
    explicitly so a future reader does not mistake the narrower gate for a failure to meet HARNESS-02.
  - **`test/support/ci_lanes.ex:54-63`**: the exclusions moduledoc calls Core Full Suite a "cron-only
    canary." The *parity* exclusion stays correct; the name and the classification claim change.
  — **Reversibility:** reversible.

### Claude's Discretion

The user asked for a single coherent recommendation set rather than choosing per-question, so every
decision above is Claude's call, made under the CLAUDE.md decision policy (research → synthesize →
decide → escalate rarely). The genuinely strategic fork — **whether to gate a publish at all** (D-19) —
was researched from both sides and decided on the cost-asymmetry argument rather than escalated, because
it is reversible config, not a contract break. If the maintainer disagrees with gating, D-19 and Wave 4
can be dropped wholesale without disturbing Waves 1-3; HARNESS-04 would then be recorded as a
deliberate "not gating, and here is why" decision, which ROADMAP criterion 4 explicitly permits
("**whether** Core Full Suite is now release-gating").

Left to the planner: exact task decomposition, file-by-file `on_exit`-ordering verification order for the
nine `:auto` files, and the precise wording of the composed failure messages (drafts exist in the
research; brand voice per `brandbook/brand-book.md`).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & milestone intent
- `.planning/REQUIREMENTS.md` — HARNESS-01..04 (§ "HARNESS — Test-harness truth") and § "Out of Scope",
  which **rejects** making Core Full Suite merge-gating. Binding.
- `.planning/ROADMAP.md` § "Phase 143: Test-Harness Truth" — goal + four success criteria. Criterion 1's
  stated hypothesis is corrected by D-01.
- `.planning/STATE.md` §§ "v2.2 Milestone Intent", "v2.2 Scope Locks" — "make every green check mean
  what it says"; SEED-006 is deliberately sequenced *after* this milestone.
- `.planning/seeds/SEED-007-sandbox-ownership-leak.md` — evidence table, "Where To Start Reading",
  Definition of Done, and the **binding** "What Has Already Been Ruled Out" list. Do not re-investigate
  anything on it.

### Prior-phase decisions this phase builds on
- `.planning/phases/141-lane-truth-foundation/141-CONTEXT.md` — the lane-registry idiom, the three-bucket
  classification axis, D-04's removal of the `/ Advisory \(/` convention regex in favor of explicit array
  membership.
- `.planning/phases/142-supply-chain-remediation-gating/142-CONTEXT.md` — D-04 (atomic-commit rule), D-05
  (the nine-site blast-radius style this phase's D-24/D-25 copy), D-06 (rename-for-honesty precedent),
  D-14 (the blocking-checkpoint pattern D-28 copies), D-15 (unit-test-vs-CI-probe split D-18 copies).

### The code under change
- `test/support/data_case.ex:35-36` — the **correct** acquire/release idiom; the control, not the culprit.
- `test/support/mailer_case.ex:93,158,185,248` — the 92-line acquire/release gap and two of the four S2
  no-ops. Also `:84-91`, the existing I-12 raise whose shape D-11's guards copy.
- `test/mailglass/properties/webhook_idempotency_convergence_test.exs:51-69` — the two leak windows.
- `test/mailglass/outbound/deliver_many_test.exs:17`, `deliver_later_test.exs:37` — the other two S2 no-ops.
- `test/test_helper.exs` — suite bootstrap, the `MAILGLASS_SCHEMA` handling, the conditional
  `ExUnit.configure(exclude: [:public_only])` (load-bearing for D-14/D-16), and the closing
  `Sandbox.mode(TestRepo, :manual)`.
- The nine `:auto`-mode files enumerated in SEED-007 — `migration_test.exs` and
  `upgrade_v2_schema_migration_test.exs` have non-trivial teardown (D-12).

### CI registry, gate, and drift tests
- `.github/workflows/advisory-matrix.yml` — `core_full_suite_advisory` (:20-21) and
  `core_latest_elixir_advisory` (:133-134); the LD-13 comment block (:127-147); the inbound `--seed 0`
  pin (:353) that D-20 turns on; `concurrency` (:15-17).
- `.github/workflows/publish-hex.yml` — `gate-ci-green`, its `REQUIRED_LANES` / `ADVISORY_LANES` /
  `PUBLISH_GATING_LANES` arrays, the ci.yml self-heal step, the `(missing)` marker, and
  `publish-core`'s "Skip if version already on Hex" guard (:394-401) that makes D-29's rehearsal safe.
- `.github/workflows/gate-self-test.yml` — the deliberate-failure-probe precedent HARNESS-03 names;
  `check_name` input (:19-22), injection point (:75-91), fail-closed paths (:131-145), cleanup (:45-58).
- `test/support/ci_lanes.ex` — the four-bucket registry; `:54-63` exclusions moduledoc (D-31);
  `all_classified_lanes/0` (:207-210) which D-24 must **not** touch.
- `test/support/ci_yaml.ex` — `job_names/1` returns *declared* names (the collapse D-21 documents).
- `test/scripts/lane_classification_drift_test.exs` — negative-control idiom (:161-229), the `(missing)`
  marker guard (:267-281), `parse_disposition_table/1` (:613-626) and the 24-row assertion (:455) that
  D-25 must not break.
- `test/scripts/required_checks_test.exs:30-34,45-58` — anti-vacuity idiom; the locked branch-protection set.
- `MAINTAINING.md` — § "Required Checks" 24-row table; `:212-216` matrix-lane note; `:259-265`
  advisory-matrix paragraph.
- `mix.exs:115` (`elixirc_paths(:test)`), `:296-298` (`verify.ci_lane_contract`), `:388-394` (`mix ci`).
- `.credo.exs` + `credo_checks/no_raw_swoosh_send_in_lib.ex` — the custom-check skeleton D-08 copies.

### Voice, conventions, and prior research
- `brandbook/brand-book.md` — **source of truth for voice** (newer than `prompts/mailglass-brand-book.md`;
  prefer this). Errors name the cause and stay composed; copy helps the reader recover; prefer the direct
  word. Every failure message in this phase is maintainer-facing microcopy and is held to it.
- `CLAUDE.md` — engineering DNA; the release-pipeline anti-recursion footgun D-22 confirms.
- `prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md:156,161,167,329` — settles D-19's
  floor-subset gating: keep required matrices small; "use one gigantic matrix as required status" is
  listed as an anti-pattern.
- `prompts/ecto-best-practices-deep-research.md`, `prompts/elixir-best-practices-deep-research.md`,
  `prompts/mailglass-engineering-dna-from-prior-libs.md`.
- `.planning/research/v2.2/SUMMARY.md`, `.planning/TOOLING-DEFECTS.md` (destination for D-18a).

### External (verified during research)
- `deps/db_connection/lib/db_connection/ownership/manager.ex:148-159` — the only `:already_shared` source.
- `deps/ecto_sql/lib/ecto/adapters/sql/sandbox.ex:448-465` — `start_owner!/2`, the unlinked `Agent.start`
  and the `:ok =` badmatch site; `:492-501` — Ecto's own warning that mode changes check in all connections.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`Mailglass.CILanes` + `test/scripts/*_drift_test.exs`** — the hardcoded-registry + drift-meta-test +
  negative-control idiom. `SuiteFloor` (D-15) and the advisory-matrix axis (D-24) are deliberate siblings,
  so there is **no new idiom** for a future maintainer to learn.
- **`verify.ci_lane_contract` (`mix.exs:296-298`)** — globs `test test/scripts/`, so
  `suite_floor_contract_test.exs` is auto-collected into the **required** `mix_task_tests` lane with
  **no `mix.exs` change**.
- **`credo_checks/` (20 checks) + `.credo.exs` `requires:`** — already lints `test/`; the new check is
  fill-in-the-blanks, not new machinery.
- **`gate-self-test.yml`** — already parameterized by `check_name`, already fail-closed on SUCCESS and on
  timeout, already cleans up branches/PRs. Extend with two inputs; do not rebuild.
- **`Mailglass.TestSupport.CitextProbe`** — establishes the `test/support/` + `TestSupport` namespace the
  three new modules join.
- **`mailer_case.ex:84-91`** — the existing I-12 "raise at setup with an actionable message" guard whose
  shape D-11's async guards copy.

### Established Patterns
- **Atomic commit for any classification move** (142 D-04): splitting leaves `main` with a registry that
  disagrees with the gate, failing `verify.ci_lane_contract` — the exact defect Phase 141 closed.
- **"A check that cannot verify must not report green"** (Phase 141, and the whole milestone). It binds
  the new guards too: an unreachable repo is a `:cannot_verify` **violation**, not silence; a probe that
  cannot observe its lane reports failure, not a timeout pass.
- **Mechanical proof over narrative** (HARNESS-03, Phases 141/142): every claim gets a drift test and a
  negative control that exercises the *same* function the real path uses.
- **`lib/` vs `dev/` vs `test/support/` placement is load-bearing** (142 D-01): `lib/` incurs
  `api_stability.md` + `stability_contract_test.exs` obligations in a required lane. Nothing here goes to
  `lib/`.

### Integration Points
- `test/test_helper.exs` — two additions: `SuiteFloor.install()` and the formatter registration (D-09,
  D-13). Placed after the `Mailglass.Config.schema()` read, since the report builder needs it.
- `.github/workflows/advisory-matrix.yml` — two `env:` lines (D-15) and two renames (D-21). No new jobs.
- `.github/workflows/publish-hex.yml` — the dual-workflow self-heal step (D-22), two new arrays, the
  decision-table block, and the override inputs (D-23). Existing ci.yml verdict logic stays byte-identical.
- `test/support/ci_lanes.ex` + `ci_yaml.ex` — additive third axis + `expanded_matrix_job_names/1` (D-24).
- `MAINTAINING.md` — a **new top-level section** (D-25), never rows inside § "Required Checks".

</code_context>

<specifics>
## Specific Ideas

- **The maintainer is the user.** Every guard failure is maintainer-facing microcopy held to
  `brandbook/brand-book.md`: name the cause, stay composed, and give the next command. The canonical
  shape is `Delivery blocked: <specific cause>` (see `dev/mix/tasks/mailglass.repo.hygiene.ex:71-84`),
  never "Oops!". The jobs-to-be-done for a leak message, in order: *which file did it*, *why cleanup
  didn't run*, *the one-line edit that fixes it* — nothing else. Full drafts for all message classes
  exist in the research and should be carried into the plan largely as written.
- **Fail loud and early, not 200 failures later.** The formatter names the offending module at
  `:module_finished` and heals the pool so the remaining ~1200 tests still produce signal — the run still
  fails, but it fails *readably*. This is the direct antidote to SEED-007's "every one of these was
  reported as citext probe exhausted."
- **Name the accepted gaps rather than papering over them:** the floor does not prove assertions are
  meaningful (D-18b); sandbox hygiene is publish-gating only, never merge-gating (D-30); the 1.19 legs
  may still be red when HARNESS-04 lands and that is by design (D-31).

</specifics>

<deferred>
## Deferred Ideas

- **Migrating the three property files from `:auto` to `Sandbox.unboxed_run/2`** — a genuine improvement
  (process-local instead of pool-global, removing the bug class for those files), but it is a test
  redesign mid-milestone. Ship `unsandboxed/2` as the documented forward idiom now; migrate later (D-12).
  The six migration/schema files **cannot** migrate — `Ecto.Migrator.with_repo/2` spawns a process
  `unboxed_run` cannot cover.
- **Fixing `gate-self-test.yml`'s vacuity against `CI Green`** (D-18a) — no `ci.yml` lane runs the root
  `mix test`, so the probe's injection point is unreachable there. Phase 143 records and verifies the
  finding; fixing `ci.yml` coverage is a topology change this phase is forbidden. → Phase 144 /
  `.planning/TOOLING-DEFECTS.md`.
- **Promoting the Credo lane (sandbox-hygiene enforcement) to merge-gating** — would close the
  publish-only gap in D-30, but lane re-classification beyond Core Full Suite is out of scope here.
- **Gating `Inbound Full Suite Advisory`** — blocked on removing its `--seed 0` flake pin (D-20).
  Revisit with SEED-006/LD-8.
- **The publish fan-out race** (two `publish-hex` runs per release train) — observed live during this
  research (D-30). Already scoped as TRUTH-08 / Phase 144; this phase only designs around it.
- **SEED-006 CI/CD efficiency work** — the dispatched matrix run adds ~10:30 to every release, and the
  per-directory `deps.get` cost from Phase 142 compounds. Deliberately sequenced after v2.2:
  "optimizing a pipeline whose greens are not trustworthy just makes it lie faster."
- **Mutation testing / coverage gates / external count reporting** — explicitly declined with reasoning
  recorded in D-18b so they are not re-litigated.

</deferred>

---

*Phase: 143-Test-Harness Truth*
*Context gathered: 2026-07-29*
