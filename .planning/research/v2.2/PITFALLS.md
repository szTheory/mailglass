# Domain Pitfalls — v2.2 CI Signal Integrity & Supply-Chain Hygiene

**Domain:** Adding CI-integrity and supply-chain-hygiene capabilities to an existing,
still-releasing Elixir/Phoenix CI pipeline (GitHub Actions + Hex.pm + branch protection +
release-please), on a mature multi-package repo.
**Researched:** 2026-07-28
**Confidence:** HIGH — every pitfall below is grounded directly in this repo's own
workflow YAML, `test/support/ci_lanes.ex`, `scripts/setup_branch_protection.sh`, and the
seeds/milestone-scope documents that record the originating incident (not generic CI
advice, and not web research — this is repo forensics).

## Meta-Pitfall (read first)

This milestone exists because a guard built to catch drift (`branch-protection-drift.yml`)
itself skipped silently and reported SUCCESS the whole time — and because a seed
(SEED-007) originally asserted a false causal claim (sandbox leak blocks Hex releases)
that was corrected only after someone checked the actual gate logic. **Every fix in
phases 141-144 is itself a new signal-emitting artifact, and every one of them can
reproduce the exact failure mode this milestone exists to close.** Before accepting any
phase 141-144 deliverable as done, ask: *if this check's precondition silently failed to
hold, would it report green, or would it report red/neutral?* If the honest answer is
"green," it is not done — it is the next SEED-007.

## Likely Implementation Sequence (for phase mapping)

1. **Phase 141 (VULN)** — supply-chain remediation: disposition the dependabot backlog,
   promote Hex Audit from advisory to gating, close the transitive-dependency blind spot.
2. **Phase 142 (HARNESS)** — fix the sandbox leak, prove Core Full Suite is genuinely
   green (not manufactured), decide on release-gating.
3. **Phase 143 (CONFORM)** — close the invisible-icon class, rename the mislabeled
   "Credo Strict" lane without silently reclassifying its gating status.
4. **Phase 144 (TRUTH)** — the check-the-checks phase: fix `branch-protection-drift.yml`
   itself, add a live-protection regression guard, resolve the two-definitions-of-advisory
   split, fix the anti-recursion gap and the self-racing publish fan-out.

Note the dependency direction: 144 hardens the *meta*-layer that 141-143 land inside.
Landing 144's drift-detection and advisory-reconciliation work **before** 141-143 gives
each of those phases a working alarm to catch their own regressions — sequencing 144 last
means phases 141-143 execute with the same blind spots that caused this milestone.

---

## Critical Pitfalls

### Pitfall 1: Vacuous / self-blinding guards — "skip" quietly renders as "pass"

**What goes wrong:**
A guard is written to compare live state against expected state, but the comparison is
wrapped in a precondition (`if: pat_present == 'true'`, `if: secret != ''`, a try/rescue
that swallows an API 403, an `if [ -f ... ]` that silently no-ops when the file is
missing). When the precondition is false, the step is skipped — and GitHub Actions
reports a skipped step/job as a non-failing, effectively-green result unless something
explicitly re-asserts failure. This is the literal, already-shipped-this-milestone defect
in `branch-protection-drift.yml`.

**Why it happens:**
"Only run this if we have the credential" is the natural, reasonable-looking way to write
a job that depends on an optional secret. Nobody writes `if: pat_present == 'true'`
intending to hide a failure — the skip is meant to mean "cannot check," but GitHub Actions
has no native distinction between "cannot check" and "checked and fine," and neither does
a human skimming a green checkmark.

**How to avoid:**
- Every conditional guard must have an explicit **else** branch that posts a *visible,
  non-green* signal — `core.setFailed`, a `neutral`/`action_required` check conclusion, or
  at minimum a `::warning::`/`::error::` annotation plus a job-summary line that a human
  scanning checks (not reading logs) will see. "Green because it didn't run" must never be
  reachable.
- Prefer failing loud over guessing: if `BRANCH_PROTECTION_PAT` is required for a
  drift-detection job to mean anything, missing it should make the job **fail**, not skip
  — unless there's a documented reason the maintainer accepts running fully blind (and
  even then, the summary should say "UNVERIFIED," not omit mention).
  `branch-protection-drift.yml` (the *apply* workflow, distinct from the drift-check that
  caused the incident) already gets the "documented, visible, no-op" version right —
  compare TRUTH-02/03's fix against that pattern.
- Add a meta-test (following the existing `required_checks_test.exs` "guard against a
  vacuous pass" pattern already in this repo — see its explicit
  `assert MapSet.size(array_set) > 0` check) for every new drift-checking mechanism:
  assert the parser/comparator actually produced a non-empty result before trusting an
  empty diff.

**Warning signs:**
- Any `if:` condition gating a comparison/assertion step, with no corresponding failure
  path when the condition is false.
- A job whose only failure path is `exit 1` inside a step that itself sits behind another
  conditional.
- "Skipped" appearing as an acceptable terminal state for a check that exists specifically
  to catch drift or regression.

**Phase to address:** Phase 144 (TRUTH-02, TRUTH-06). Cross-cutting — apply the same audit
to every new check phases 141-143 add.

---

### Pitfall 2: Manufactured green — recovered tests that pass because they don't run

**What goes wrong:**
HARNESS-01/02 fix the sandbox-ownership leak so Core Full Suite goes from ~fully-red to
green. The fastest way to make a red suite green is not to fix it — it's to tag the
failing tests `@tag :skip`, add them to an `--exclude` list, delete flaky assertions, or
convert hard assertions into soft/logged warnings. Any of these produces the same visible
signal (green checkmark) as a genuine fix, and — per this milestone's own meta-pitfall —
green is exactly the signal category this milestone exists to stop trusting blindly.

**Why it happens:**
Under time pressure, "make it green" and "fix the bug" feel like the same task, and a
`--exclude requires_workspace`-style flag already exists in this exact lane
(`advisory-matrix.yml`) as a *legitimate* pattern — so a new exclusion added during the
sandbox fix would not look anomalous by itself. There's no natural forcing function that
distinguishes "excluded for a documented structural reason" from "excluded because it was
inconvenient to fix."

**How to avoid — concrete, verifiable anti-vacuity techniques for HARNESS-03:**
1. **Test-count floor assertion.** SEED-007 already recorded the baseline: 1401 core
   tests, 242 failures pre-fix. Add a meta-check (CI step or ExUnit test) that asserts the
   suite's *executed* test count (from the ExUnit formatter/JSON output) is `>= 1401`
   (or exactly the pre-fix count, adjusted only for tests deliberately added/removed with
   a recorded reason). A drop in executed-test count with a rising pass rate is the single
   strongest tell of tag-away manufacturing.
2. **Skip/exclude diff gate.** Diff the set of `@tag :skip`, `@moduletag :skip`,
   `@tag exclude:` (or `ExUnit.configure(exclude: ...)`) markers before vs. after the
   HARNESS-01 fix. Any new entry must carry the same `# Reason:` / `# Tracking:` comment
   discipline this repo already enforces for Credo suppressions
   (`scripts/check_credo_suppressions.sh`) — reuse that exact pattern here rather than
   inventing a new one.
3. **Failure-signature reconciliation, not failure-count reconciliation.** SEED-007's own
   evidence table is signature-keyed (`{:badmatch, :already_shared}`: 194,
   `42P01 undefined_table`: 31, worktree-env artifacts: 14). The fix is only proven when
   the `:already_shared` signature specifically goes to zero *and* the suite's total
   failure count matches the sum of the remaining, independently-understood signatures —
   not merely "fewer red tests than before." A fix that makes the number smaller by
   accident (e.g., an unrelated flake stopped reproducing) is not the fix SEED-007 asked
   for.
4. **Deliberate-failure probe, adapted from the existing `gate-self-test.yml` pattern.**
   This repo already has exactly the right template: inject a synthetic
   `assert false` into a throwaway branch/PR, confirm the target check goes red, then
   clean up. Do the same thing against `Core Full Suite Advisory` specifically (not just
   `CI Green`, which `gate-self-test.yml` already covers): open a disposable PR that
   breaks one previously-green core assertion and confirm the now-green lane reports the
   break. If it doesn't, the "fix" only removed the ambient noise floor and never restored
   the lane's ability to detect real regressions — which is the whole point of HARNESS-02/03.
5. **Mutation-adjacent spot check.** Pick 3-5 of the newly-passing tests (weighted toward
   ones the SEED-007 call-site map flags — `deliver_many_test.exs`,
   `deliver_later_test.exs`, and the nine mode-switching files) and manually invert one
   assertion in each locally; confirm each fails. This is cheap, targeted, and catches the
   "assertion was already vacuous before the sandbox bug ever mattered" case that a
   count-only check would miss.

**Warning signs:**
- The PR that closes HARNESS-01 touches test *tags* or `ExUnit.configure(exclude:)` in
  addition to (or instead of) `test/support/mailer_case.ex` / sandbox lifecycle code.
- Executed-test count in the fixed run is lower than 1401 with no recorded reason.
- The written mechanism account (SEED-007 Definition-of-Done item 1) is missing or vague
  — "it's green now" without "here is why `:already_shared` was being raised and here is
  what changed so it no longer is."
- No sandbox-mode assertion (SEED-007 item 3 — e.g. asserting `:manual` mode at the end of
  each mode-switching file) shipped alongside the fix.

**Phase to address:** Phase 142 (HARNESS-01, HARNESS-02, HARNESS-03). HARNESS-04's
release-gating decision should be made only after these anti-vacuity checks pass — gating
on a lane that was manufactured green would recreate the exact 24-day blind-spot pattern,
just moved into the release-blocking path instead of out of it.

---

### Pitfall 3: Promoting an advisory lane to gating creates a release deadlock

**What goes wrong:**
VULN-03 promotes Hex Audit from advisory to gating. Advisory lanes accumulate exactly the
kind of debt that makes a naive promotion dangerous: transitive advisories with no
upstream patch available yet (this repo's own history — `hpax` sat unpatched because
dependabot never files transitive PRs), a currently-red advisory lane at promotion time,
or a future advisory with no fix for weeks. The moment a currently-non-blocking lane
becomes required, any one of those turns into "every PR is blocked, indefinitely, with no
path to green" — the same shape of outage this milestone exists to prevent, just
self-inflicted instead of accidental.

**Why it happens:**
"Advisory lanes should be gating" is directionally correct (it's the entire point of
VULN-03) but the promotion is usually specified as a boolean flip (advisory → required)
without also specifying the escape valve: what happens when the gate is red for a reason
nobody can fix today. Without that valve, the first unfixable advisory becomes an
unplanned repeat of the guard-release-trigger 24-day lockout, except now it's "working as
designed."

**How to avoid:**
- Gate on **severity, not presence**: block merge only on newly-introduced HIGH (or
  configurably HIGH+CRITICAL) advisories with an available patched version, not on every
  advisory `mix hex.audit` reports. This mirrors what the milestone's own history shows
  worked: the nine advisories patched on 2026-07-28 were actionable because a fix
  existed.
- Build a **time-boxed, expiring allowlist mechanism** from day one, not as a later
  patch: an advisory with no available fix gets a recorded disposition (`keep-with-reason`
  per TRUTH-05's own vocabulary) and a **review-by date**, not a permanent silent
  exclusion. An allowlist entry with no expiry is how "advisory-only, no bounded review"
  debt accumulates in the first place — this is exactly the failure mode VULN-04's
  "documented triage cadence" is meant to close, so wire the cadence into the gating
  mechanism itself rather than bolting it on afterward.
- Ship the promotion and the disposition/allowlist mechanism as one atomic change, not
  sequentially — flipping the gate live before the escape valve exists guarantees at least
  one lockout window during rollout.
- Sequence-check against TRUTH-05 ("every advisory lane gets a recorded disposition"):
  VULN-03 should not gate a lane that phase 144 hasn't yet dispositioned, or the two
  phases will contradict each other mid-milestone.

**Warning signs:**
- The promotion PR changes only `ci_green.needs` / `Mailglass.CILanes.required_lanes()`
  with no accompanying allowlist/disposition/expiry mechanism.
- An advisory with no available upstream fix exists at promotion time and is not
  explicitly dispositioned before the flip.
- No forcing function surfaces transitive advisories (VULN-04) before the gate goes live —
  gating on a lane that still can't see `hpax`-class issues just gates on a false sense of
  completeness.

**Phase to address:** Phase 141 (VULN-03, VULN-04), coordinated with Phase 144 (TRUTH-05).

---

### Pitfall 4: "Fixing" the Ecto Sandbox leak by reducing coverage instead of curing it

**What goes wrong:**
Several superficially-reasonable responses to `{:badmatch, :already_shared}` make the
symptom disappear while silently reducing what the suite actually proves:

- **Rescue/mask the badmatch.** Wrapping `Sandbox.start_owner!/2` in a rescue that retries
  or swallows `:already_shared` makes the crash disappear but leaves the underlying
  leaked-ownership state in place — the next test in that leaked state may now run against
  the wrong connection/transaction instead of crashing loudly. This is strictly worse than
  the current red suite: red-but-honest becomes green-but-wrong.
- **Blanket `async: false`.** Serializing everything sidesteps ownership races by removing
  concurrency, but 3-4x's suite runtime and, more importantly, doesn't explain the
  mechanism — SEED-007's Definition-of-Done explicitly requires "the mechanism is
  explained, not just suppressed." A slow, mysteriously-green suite is not a satisfied
  DoD.
- **Global shared mode.** Switching the whole suite to `{:shared, self()}` permanently
  (rather than only where a test genuinely needs cross-process DB access, as
  `mailer_case.ex`'s `set_mailglass_global/1` already does deliberately) removes per-test
  isolation — two tests can now silently observe each other's uncommitted writes, and a
  transaction-rollback assertion can pass for the wrong reason.
- **Per-test ownership checkouts inside `setup_all`.** `Sandbox.start_owner!/2` called in
  `setup_all` ties ownership to the whole module's lifetime, not the test process — later
  tests in the module inherit a connection whose transaction state doesn't match the
  test's own. This is a plausible *unintentional* variant of the leak itself, not just a
  bad fix for it — worth explicitly ruling in or out during the mechanism investigation.
- **Multi-repo/multi-package mode disagreement.** `mailglass_inbound`'s test suite runs
  under `--seed 0` specifically to dodge a related pool flake (per this repo's own
  `advisory-matrix.yml` comments); a core-suite fix that changes shared-vs-manual default
  behavior without checking `mailglass_inbound`'s `MailglassInbound.TestRepo` and the
  cross-package property tests (`webhook_suppression_convergence_test.exs`,
  `idempotency_convergence_test.exs`, `unsubscribe_post_idempotency_property_test.exs` —
  already on SEED-007's list) risks fixing core while quietly breaking inbound's own
  sandbox contract, or vice versa.

**Why it happens:** each of these makes local `mix test` (or CI) go green fast, and none
of them requires understanding *why* `:already_shared` fires — which is exactly the
harder, correct work SEED-007 demands ("Confirm the mechanism before changing anything;
do not 'fix' it by making tests async: false, which would hide it and slow the suite" —
already called out verbatim in the seed itself).

**How to avoid:**
- Treat SEED-007's "What Has Already Been Ruled Out" list as load-bearing: don't
  re-investigate the citext OID race, `migration_test.exs` teardown, the other schema
  teardown tests, `demo_data_test.exs`, or `shipped_migration_divergence_test.exs` — the
  leak requires the *full suite* to reproduce (cross-file global-state interaction), so
  investigate ordering/cleanup interactions between `mailer_case.ex`'s explicit
  `{:shared, self()}` call sites (lines 93, 158, 248 per the seed) and the nine
  `:auto`-mode-switching files, not any single file in isolation.
- Specifically verify whether `on_exit` callbacks that set shared/`:auto` mode always run
  and always run in the right order relative to the next test's `start_owner!` — a crash
  mid-test, or `on_exit` callbacks registered before a later crash, can skip cleanup.
  (Concretely worth checking as part of the mechanism writeup: does every code path that
  calls `Sandbox.mode(repo, {:shared, self()})` have a matching `Sandbox.mode(repo,
  :manual)` in its `on_exit`, executed unconditionally? Any call site missing that
  symmetry is a candidate root cause, not just a suspect to note in passing.)
- The DoD's ownership-hygiene assertion (item 3 — assert `:manual` mode at end of each
  mode-switching file) should be added as a **permanent regression guard**, not a one-time
  debug aid — this is the mechanism that prevents this exact leak from recurring silently
  after the fix ships.
- Re-run the fixed suite **repeatedly, across seeds, across all four matrix legs**
  (1.18/OTP27 and 1.19/OTP28 × `public`/`mailglass` schema — HARNESS-02's literal
  requirement) before declaring done. A leak this order-dependent may not reproduce on
  every seed; one green run proves little.

**Warning signs:**
- Any `rescue` or `catch` clause added near `Sandbox.start_owner!/2` calls.
- A diff that changes `async: true` → `async: false` on tests that were not previously
  failing, without a written explanation of why that specific test needed serialization.
- `Sandbox.mode(repo, :shared)` or `{:shared, ...}` calls added outside the existing,
  deliberate `set_mailglass_global/1` / Oban-dispatch call sites.
- The fix passes on one seed/one matrix leg but wasn't verified across all four.
- No written mechanism account accompanies the fix (SEED-007 DoD item 1).

**Phase to address:** Phase 142 (HARNESS-01, HARNESS-02).

---

### Pitfall 5: Branch-protection automation — id/name mismatch, PAT scope, and self-lockout

**What goes wrong, in three related shapes:**

1. **Job `id` vs. `name` context mismatch** (the exact originating defect). GitHub Actions
   status checks are matched by the **reported check name** (the job's `name:` field, or
   its matrix-expanded display name), never by the job's YAML `id:`. Required-context
   configuration that uses the id (`guard-release-trigger`) instead of the display name
   (`Guard Release Trigger`) will never be satisfied by anything, and — per Pitfall 1 —
   nothing about that state looks red; it just looks perpetually pending/blocked, which is
   easy to misdiagnose as "CI is slow" rather than "this can never pass." This repo has
   **two current mechanisms for this exact class of bug**: `setup_branch_protection.sh`'s
   `REQUIRED_CHECKS` array (now display-name-correct: `"CI Green"`, `"Guard Release
   Trigger"`) and `publish-hex.yml`'s `gate-ci-green` step, which independently hardcodes
   `REQUIRED_LANES` as job **display names** matched via `j.name === lane` against the
   GitHub Actions Jobs API. Any future edit to either list that types an `id:` instead of
   a `name:` — or that renames a job's `name:` field without updating both copies plus
   `test/support/ci_lanes.ex` — reproduces the incident in miniature.
2. **PAT scope and expiry.** `branch-protection-drift.yml`'s re-assertion workflow depends
   on `BRANCH_PROTECTION_PAT`, a fine-grained PAT scoped to "Administration: Read and
   write." Fine-grained PATs expire (GitHub caps them at 1 year); an expired or
   insufficiently-scoped PAT makes the `gh api` call 403, and if that 403 isn't
   distinguished from "drift confirmed absent," it either silently no-ops (Pitfall 1) or
   is misreported as drift (see next point).
3. **API 403s misreported as drift, or a "fix" that locks out the maintainer.** A script
   that "corrects" branch protection into whatever shape it computed from a 403/degraded
   read risks pushing a *wrong* ruleset live — e.g., re-asserting protection with a stale
   or empty context list, or (if ever extended to `enforce_admins`/PR-review settings)
   locking the sole maintainer out of `main` entirely, since `setup_branch_protection.sh`
   currently sets `enforce_admins: false` and `required_pull_request_reviews: null`
   specifically because a single-maintainer repo cannot self-review.

**Why it happens:** job id and job display name look interchangeable to a human editing
YAML (`credo_strict:` / `name: Credo Strict (...)` sit two lines apart), but GitHub's
check-run API treats them as unrelated strings; nothing in the YAML schema warns about the
mismatch. PAT expiry is a silent, calendar-driven failure with no compile-time signal.
"Read-then-write" reconciliation scripts default to trusting whatever they last read,
which is dangerous exactly when the read itself is degraded.

**How to avoid:**
- **Single source of truth, verified by a meta-test, not just documented.** This repo
  already has the right shape — `Mailglass.CILanes.required_lanes/0` as the canonical
  Elixir-side list, verified against `ci.yml`'s `ci_green.needs` by
  `required_checks_test.exs` (GATE-03). Extend that same set-equality discipline to
  `publish-hex.yml`'s `REQUIRED_LANES` JS array and `setup_branch_protection.sh`'s
  `REQUIRED_CHECKS` array — today they're documented as "kept in lockstep" by comment, but
  confirm (as part of TRUTH-03) that a meta-test actually parses and diffs all these
  copies, not just the `ci.yml`-vs-`CILanes` pair `required_checks_test.exs` already
  covers.
- **Distinguish "drift confirmed" from "cannot verify."** A 403/network failure from the
  GitHub API must produce a distinct, clearly-labeled outcome (`action_required`/neutral
  with "PAT missing/expired/insufficient scope — protection NOT verified this run") —
  never silently folded into either "green" or "drift detected." This is the direct fix
  for TRUTH-06's `repo-hygiene` `branch_protection` sub-check, and the same discipline
  belongs in `branch-protection-drift.yml`.
- **Read-only verification and write-capable reassertion stay separate roles**, which this
  repo already does correctly (`branch-protection-drift.yml`'s scheduled job only
  re-asserts a known-good `expected_json`; it never derives the desired state from a
  possibly-degraded read). Preserve that separation — never let a "fix drift" script
  compute its target state from the same read that might be 403'ing.
- **PAT expiry monitoring.** Add a lightweight calendar/expiry check (fine-grained PATs
  report an expiry date via the GitHub API) so an about-to-expire `BRANCH_PROTECTION_PAT`
  surfaces as a visible warning weeks before it goes silent, not as a rediscovered
  Pitfall-1 blind spot.
- **Never let an automated script touch `enforce_admins`, `required_pull_request_reviews`,
  or `restrictions` toward a locked state without a human-reviewed diff first** — for a
  single-maintainer repo, those three fields have exactly one safe value
  (`false`/`null`/`null`) and `setup_branch_protection.sh` should keep asserting them
  explicitly (as it already does) rather than ever computing them dynamically.

**Warning signs:**
- Any place a job's YAML `id:` (kebab-case, e.g. `guard-release-trigger`) is used where a
  display name (Title Case, e.g. `Guard Release Trigger`) is expected, or vice versa.
- `REQUIRED_CHECKS` / `REQUIRED_LANES` / `CILanes.required_lanes/0` diverge and no
  automated test catches it (only comment-level "keep in sync" promises).
- A 403 from any GitHub API call inside a hygiene/drift check produces the same downstream
  branch as "checked, no drift."
- Any workflow computes desired branch-protection state from a live read rather than a
  checked-in `expected_json`.

**Phase to address:** Phase 144 (TRUTH-03, TRUTH-06 primarily); the id/name discipline
also directly informs Phase 143's CONFORM-04 rename (Pitfall 7 below) since it's the same
underlying class of bug.

---

### Pitfall 6: Concurrency guards and self-racing publish fan-out

**What goes wrong:**
Two related but distinct hazards live under "concurrency correctness for a publish
workflow":

1. **`cancel-in-progress: true` cancelling the run that would have published.** This repo
   already gets this right for `publish-hex.yml` — `concurrency: { group:
   publish-hex-${{ github.ref }}, cancel-in-progress: false }` — deliberately, because
   cancelling an in-flight Hex publish mid-tarball-upload is far worse than letting two
   runs queue. `ci.yml`'s `cancel-in-progress: true` is correct for a *pre-merge* CI lane
   (superseding an in-flight run for an old push is desirable), but that same setting on a
   publish-adjacent workflow would be a live incident waiting to happen. **The pitfall for
   this milestone is copy-paste**: if TRUTH-04's anti-recursion fix or TRUTH-08's
   self-race fix touches `publish-hex.yml`'s concurrency block, or if a new workflow is
   added that also gates/reacts to `release: published`, defaulting to the `cancel-
   in-progress: true` pattern used everywhere else in this repo (`ci.yml`,
   `advisory-matrix.yml`, `repo-hygiene.yml` all use `false` for schedule-driven repeats
   but the *pattern* of "true is the norm" is easy to reach for) would reintroduce exactly
   this hazard on the one workflow where it's most dangerous.
2. **The already-documented self-racing publish fan-out (TRUTH-08).** Because
   `publish-hex.yml` triggers on `release: published` and tagging happens per-package
   (core, admin, inbound cut separately but linked), two tag events can each independently
   fire a full `publish-hex` run. Both runs race on `publish-core`; the idempotency guard
   (`Skip if version already on Hex` — `mix hex.info mailglass "${VERSION}"` before
   publishing) makes the *outcome* safe (a package is never double-published), but the
   losing run's `Publish mailglass to Hex.pm` step still reports whatever its own
   `hex.publish` invocation returns, which can read as a failure on an already-successful
   release. A green release "looking failed" is corrosive in exactly the way this
   milestone is about — a human sees red and starts an unnecessary incident response for a
   release that actually shipped.
3. **A genuinely-new race, not just a stale-report one, is still possible**: if the
   idempotency check (`mix hex.info` returning "Released:") races against Hex.pm's own
   indexing propagation delay (the workflow already retries `deps.get` for this exact
   propagation lag elsewhere — see the `mix deps.unlock --all` retry loops in
   `publish-admin`/`publish-inbound`), a losing run could observe "not yet released" and
   attempt to publish concurrently with the winning run's actual upload — Hex.pm's own
   uniqueness constraint is the real backstop here, not the idempotency pre-check.

**Why it happens:** the pipeline's per-package tag/release model is not naturally
mutually-exclusive at the workflow-trigger level — GitHub Actions has no built-in
"exactly one of these concurrent triggers wins, others no-op cleanly" primitive; the
idempotency-guard pattern approximates it but doesn't make the *reporting* of the losing
run honest.

**How to avoid:**
- Fix TRUTH-08 by making the **losing run's outcome explicitly distinguishable from a real
  failure** — e.g., have the idempotency check control the job's own conclusion (skip
  cleanly, or succeed-with-a-"skipped, already published elsewhere" annotation) rather
  than letting a redundant `hex.publish` call run and fail/no-op ambiguously. If two runs
  legitimately need to fire per multi-package release, prefer collapsing them at the
  trigger/dispatch layer (a single coordinating workflow_run trigger, or a concurrency
  group keyed by *package* rather than by `github.ref` so redundant runs for the *same*
  package genuinely queue/cancel against each other, while independent packages still
  proceed in parallel) over patching the symptom.
- Leave `cancel-in-progress: false` on `publish-hex.yml` untouched by this milestone's
  other fixes; if TRUTH-04's anti-recursion self-heal (which already dispatches `ci.yml`
  from inside `gate-ci-green`) needs its own concurrency scoping, key it so it cannot
  cancel a run already inside the publish steps.
- For TRUTH-04 specifically (the anti-recursion gap costing ~30 minutes three times):
  verify whichever fix ships doesn't *also* introduce a race — e.g., if the fix is "have
  `guard_release_trigger`'s bot-merge path explicitly re-trigger release-please's `push`
  handling," confirm that trigger can't double-fire alongside the existing hourly-cron
  fallback for the same release, which would recreate hazard #2 one layer up the pipeline.

**Warning signs:**
- Any new/edited workflow reacting to `release:` or `push` tag events without a
  concurrency group scoped to the resource being mutated (the package, not just the ref).
- `cancel-in-progress: true` appearing anywhere in a workflow that can reach a
  `HEX_API_KEY`-bearing step.
- A workflow run's overall conclusion is `failure` while its idempotency-guard step logged
  "already on Hex — skipping" — that combination should never coexist without an explicit,
  intentional non-zero exit distinguishing "redundant, harmless" from "genuinely broken."

**Phase to address:** Phase 144 (TRUTH-04, TRUTH-08).

---

### Pitfall 7: Renaming a CI lane silently changes which strings it matches — and, here, its gating status

**What goes wrong:**
CONFORM-04 renames the lane currently called "Credo Strict" (misleading — it also runs
the suppression-docs check, motion-conformance check, design-system conformance
hard-fail arms, and the design-system advisory arms, with `mix credo --strict` as only the
*last* of five steps). A job's reported check-run name is its `name:` field
(`Credo Strict (Elixir 1.18 / OTP 27)`), and that exact string is independently referenced
in at least three places that don't share a common source:

1. `test/support/ci_lanes.ex` — lists it verbatim in `@advisory_lanes_ci`, declaring it
   *advisory*.
2. `publish-hex.yml`'s `gate-ci-green` step — does **not** list it in `REQUIRED_LANES`
   (correct, it's not one of the 5 required leaf lanes) but **also does not match it** in
   `ADVISORY_LANES` (`['Operator Browser Gate', 'Demo Browser Evidence']`) or the generic
   `/ Advisory \(/` suffix pattern (its name has no " Advisory (" substring). That means
   under the current script, a red "Credo Strict" lane falls into the *third*,
   catch-all `blockingFailures` bucket — "non-required, non-advisory failures still
   block." **This lane is already accidentally gating today**, contradicting its own
   documented "advisory" status in `ci_lanes.ex` — this is precisely the TRUTH-07
   divergence the milestone scope calls out, and it is very likely the actual mechanism
   behind SEED-007's own corrected evidence: "the 2.1.1 gate failure named `Credo Strict`
   and `Dialyzer`" as the reason release was blocked.
3. `Mailglass.CILanes.advisory_lanes/0` feeds the `mix ci` / `mix ci.browser` local-parity
   aliases (MIXCI-03) — a rename without updating this list breaks local reproduction of
   the CI surface, independent of any gating question.

Renaming the `name:` field without touching all three surfaces produces one of two silent
outcomes: (a) the new name still falls through to the same accidental-gating catch-all
under a different string — no visible change, the misclassification just persists
relabeled — or (b) whoever does the rename, seeing the "advisory" label in `ci_lanes.ex`,
"fixes" the mismatch by finally adding the new name to `gate-ci-green`'s `ADVISORY_LANES`
— which silently **demotes a lane that has been functioning as a release gate into a
non-blocking one**, a real behavior change smuggled inside a cosmetic rename.

**Why it happens:** GitHub's check-run identity is name-based, and this pipeline has (by
its own honest admission in TRUTH-07) two different, disagreeing definitions of
"advisory" living in two files with no shared source and a cited authority
(`MAINTAINING.md`) that has never existed in the repo. A rename is the kind of change that
looks purely cosmetic and invites a fast, unreviewed edit.

**How to avoid:**
- Treat the rename as a **three-part atomic change**, not a find-and-replace: update the
  `name:` field in `ci.yml`, the corresponding string in
  `test/support/ci_lanes.ex`, and explicitly decide (don't default) whether the renamed
  lane belongs in `gate-ci-green`'s `ADVISORY_LANES`/`REQUIRED_LANES`/neither — and record
  that decision, since today's "neither" is what makes it accidentally-gating.
- Resolve TRUTH-07 **as part of, not after,** CONFORM-04: reconcile
  `ci_lanes.ex`'s ten-lane advisory list against `gate-ci-green`'s two-lane
  `ADVISORY_LANES` + suffix-pattern matcher before or in the same change that renames this
  specific lane, since the rename is the exact case that exposes the divergence.
  Concretely, decide and document: is "Credo Strict" (post-rename) meant to block
  release, or not? Whichever answer is chosen, make `gate-ci-green` match it
  *explicitly* (add to `ADVISORY_LANES` if non-blocking is intended, or add to
  `REQUIRED_LANES` + branch protection if blocking is intended) rather than continuing to
  rely on the accidental third-bucket behavior.
- Extend (or confirm) a meta-test that verifies `gate-ci-green`'s `REQUIRED_LANES` +
  `ADVISORY_LANES` set-cover *every* job name that appears in `ci_green.needs` plus
  `Mailglass.CILanes.advisory_lanes/0` — i.e., no job name should be able to silently fall
  into the undocumented third bucket. `required_checks_test.exs` already proves the
  `ci.yml`-vs-`CILanes` pair; this milestone should close the remaining `publish-hex.yml`
  gap so a future rename can't reproduce this again.
- Delete or replace the `MAINTAINING.md` citation in `ci_lanes.ex`'s moduledoc with the
  actual authoritative source once TRUTH-07 lands — a docstring citing a file that has
  never existed is itself a small instance of Pitfall 1 (a "citation" nobody can verify).

**Warning signs:**
- A grep for the old lane name (`"Credo Strict"` or `'Credo Strict'`) after the rename PR
  merges returns any hits outside historical `.planning/` artifacts.
- `gate-ci-green`'s classification of the renamed lane is unchanged from before the rename
  (i.e., nobody made the required/advisory/neither decision explicit — it just silently
  carried the old accidental status under a new string).
- The rename PR's diff touches only `ci.yml`'s `name:` field.

**Phase to address:** Phase 143 (CONFORM-04), tightly coordinated with Phase 144
(TRUTH-07). Land TRUTH-07's reconciliation in the same PR as the rename, or immediately
before it — not after, when the divergence would otherwise persist under the new name for
however long the gap between phases lasts.

---

### Pitfall 8: Build-time icon-existence gate — checking two known instances instead of the class

**What goes wrong:**
The two invisible heroicons (`hero-check`, `hero-information-circle`) were fixed as
specific instances (CONFORM-01, DONE). CONFORM-02 asks for the *class* to be closed
permanently. This repo already has a real, general mechanism for this
(`mailglass_admin/scripts/check-conformance.sh`'s `ICON-EXISTS-GATE`: `grep -rhoE
'hero-[a-z0-9-]+' "$LIB" --include="*.ex"` diffed against the vendored
`heroicons-inline.js` keys) — which is good and already covers static/conditional-literal
usage like
`name={if @preview_frame_dark_chrome, do: "hero-sun", else: "hero-moon"}` correctly,
because both branches are literal strings the regex can see. The remaining, genuine gap is
**dynamically-constructed icon names**: any future `name={"hero-" <> status}`,
`name={"hero-#{variant}"}`, or a lookup-table `%{ok: "hero-check", error: "hero-x-circle"}`
whose keys are matched at runtime rather than written as a literal `hero-x` token adjacent
to the `hero-` prefix. A regex-based static scan cannot see the resulting string at all
(string concatenation) or sees only the literal fragment before the interpolation
(`hero-` with nothing after it, which the current `sed 's/^hero-//'` would reduce to an
empty string and silently drop from `used_icons` rather than flag as suspicious).

**Why it happens:** grep/regex scanning is the cheapest way to build this gate and is
correct for the vast majority of real usage (literal or branch-literal icon names), so it
looks complete after fixing the two known cases — the dynamic-construction gap only shows
up when someone later refactors a `case`/cond` chain of literal icon names into a lookup
map "for cleanliness," which is a natural, well-intentioned refactor that reintroduces the
exact invisible-icon risk this gate exists to prevent.

**How to avoid:**
- Extend the existing scan (don't replace it — it's a working, cheap first line of
  defense) with an explicit **class-level detector**: flag any `hero-` occurrence
  immediately followed by `<>`, `#{`, or that appears inside a `%{...}` literal whose
  values aren't all grep-matchable `hero-[a-z0-9-]+` tokens. Treat any such match as a
  build failure requiring either (a) converting it to a closed, literal `case`/`cond` the
  static scanner can already see, or (b) an explicit allowlist entry the gate script
  enumerates and checks by hand against the vendored icon set.
- Prefer, if feasible without expanding this milestone's scope (it's maintenance-only —
  weigh against the "no CI topology rewrite" scope lock): a **compile-time** guard inside
  `Components.icon/1` itself (e.g., a `@compile` step or Igniter-style codegen check that
  runs during `mix compile` and can see interpolated values at the AST level, or at
  minimum a runtime `raise` in dev/test when an unknown `hero-*` name is rendered) as a
  defense-in-depth layer behind the static CI scan — the CI scan catches it before merge
  for the common case; the compile/runtime check catches whatever the regex can't see.
- Whatever detector ships, prove it actually fires: add a throwaway dynamic-icon-name test
  fixture (mirroring the `used_icons` empty-scan self-check already in the script — "IN-03:
  distinguish a genuinely icon-free lib from a scan/path error") that intentionally
  constructs a `hero-` name dynamically and confirms the gate fails on it, then remove the
  fixture. This is the same deliberate-failure-probe discipline as Pitfall 2's HARNESS-03
  guidance, applied to CONFORM-02.

**Warning signs:**
- Any `<>` or `#{` within 20 characters of a `"hero-` literal in `mailglass_admin/lib`.
- A `case`/`cond` of literal icon names refactored into a map/lookup structure.
- The `ICON-EXISTS-GATE`'s `used_icons` scan silently produces fewer entries after a
  refactor that visibly still renders more distinct icons in the UI than before (a strong
  sign the regex stopped seeing some of them).

**Phase to address:** Phase 143 (CONFORM-02).

---

### Pitfall 9: Two definitions of "advisory," one non-existent cited authority

**What goes wrong:**
`test/support/ci_lanes.ex` declares ten advisory lanes (`@advisory_lanes_ci` +
`@advisory_lanes_browser`) and cites `MAINTAINING.md` (lines 152-191) as the
authoritative source for the required-vs-advisory split. `publish-hex.yml`'s
`gate-ci-green` independently hardcodes a two-entry `ADVISORY_LANES` array plus a
suffix-pattern matcher. **`MAINTAINING.md` has never existed in this repository.** Any
future contributor (human or agent) who trusts the docstring's citation and edits only
`ci_lanes.ex` when adding/removing an advisory lane will silently leave `gate-ci-green`'s
independent, hardcoded classification stale — which is exactly how "Credo Strict" ended up
accidentally gating (Pitfall 7) without anyone deciding that on purpose.

**Why it happens:** the comment describing the split as authoritative was presumably
written when `MAINTAINING.md` was planned or drafted elsewhere and never actually
committed, or the file was renamed/removed without updating the citation. A confidently-
worded docstring citation is more persuasive than it should be — nobody double-checks a
citation that reads as settled.

**How to avoid:**
- Pick exactly one authoritative source and make it executable, not prose-only. The
  cleanest fix consistent with this repo's existing pattern (Elixir-side `CILanes` module
  as source, YAML/script copies verified against it by meta-test — already proven for the
  required-lane set via GATE-03) is to extend that same discipline to the advisory
  classification: either have `gate-ci-green` compute its advisory/required split from a
  machine-readable artifact `CILanes` also produces (e.g., a generated JSON the JS step
  reads), or add a meta-test that diffs `gate-ci-green`'s hardcoded arrays against
  `CILanes.advisory_lanes/0` / `required_lanes/0` the same way `required_checks_test.exs`
  already diffs `setup_branch_protection.sh` against `ci.yml`.
- Either write the cited `MAINTAINING.md` for real (if a prose explanation genuinely adds
  value beyond the executable source) or delete the citation. A citation to a
  non-existent file is worse than no citation — it actively misleads.

**Warning signs:**
- Any doc comment citing a specific file path — verify the path resolves before trusting
  the claim it's backing.
- `ci_lanes.ex`'s advisory list and `gate-ci-green`'s `ADVISORY_LANES` array have different
  cardinality (ten vs. two, today) with no reconciling comment explaining the gap as
  intentional.

**Phase to address:** Phase 144 (TRUTH-07), landed alongside or before Phase 143's
CONFORM-04 rename (see Pitfall 7).

---

### Pitfall 10: Dependabot auto-merge backlog and the transitive-dependency blind spot

**What goes wrong:**
Two related supply-chain gaps: (1) PRs left with auto-merge armed but never confirmed
landed or explicitly closed accumulate silently — auto-merge only fires once required
checks pass, so a PR sitting behind the guard-release-trigger-class of blocker (or any
other transient block) just sits, armed and forgotten, until someone audits the list by
hand (which is exactly what VULN-02 now has to do for the 13 left over from 2026-07-28).
(2) Dependabot only opens PRs for **direct** dependency advisories declared in
`mix.exs`/`mix.lock` top-level entries per package-ecosystem config
(`dependabot.yml` here covers `/`, `/mailglass_admin`, `/mailglass_inbound`, and
`github-actions` — four directories, each scanning only its own direct deps). `hpax` was
HIGH-severity and **transitive** (pulled in by `mint`/`gun`-style HTTP stacks, not a
direct dep), so dependabot never filed anything for it — the only reason it was found was
someone reading raw `mix hex.audit` output by hand.

**Why it happens:** dependabot's ecosystem-scanning model is fundamentally
direct-dependency-first for auto-PR generation (transitive advisories show up in GitHub's
Dependency Graph/Security tab, but don't automatically generate a fix PR the way direct
ones do, since there's often no single top-level version bump that resolves them cleanly).
Auto-merge-and-forget works fine until a PR's required checks never go green for reasons
unrelated to the dependency change itself (branch protection drift is a perfect example)
— nothing distinguishes "auto-merge is quietly waiting on a real review" from "auto-merge
is permanently stuck because the merge gate itself is broken."

**How to avoid:**
- VULN-04's "documented triage cadence" must explicitly include a **transitive-advisory
  sweep** step — reading `mix hex.audit`'s full output (not just dependabot's PR queue) on
  a recurring cadence, since that's the only path that surfaced `hpax`. Automate this as a
  scheduled job that greps/parses `mix hex.audit` output for advisories whose package
  isn't a direct dependency in any of the four `dependabot.yml`-covered manifests, and
  flags those specifically (they're the ones dependabot structurally cannot self-heal).
- For the backlog itself (VULN-02): don't just merge everything with auto-merge still
  armed — audit each one, since auto-merge sitting live for weeks means the base branch
  has likely moved and the PR may need a rebase, may now conflict with a since-landed
  fix, or may have been superseded by a newer advisory PR for the same package.
- Add a lightweight recurring check (could piggyback on `repo-hygiene`) that flags any
  open PR with auto-merge enabled and no activity/check progress for N days — the
  generalizable version of "don't let armed-and-forgotten accumulate," independent of
  what broke the specific 2026-07-28 backlog.

**Warning signs:**
- `mix hex.audit` output contains an advisory for a package with no corresponding entry in
  any of the four `dependabot.yml` scan targets' direct dependencies.
- Any PR with auto-merge enabled and a last-updated timestamp older than one normal CI
  cycle.
- A triage cadence document that only says "review dependabot PRs" without a separate step
  for reading raw audit output.

**Phase to address:** Phase 141 (VULN-02, VULN-04).

---

### Pitfall 11: `repo-hygiene`'s 403 conflated with "genuinely blocked"

**What goes wrong:**
`repo-hygiene.yml`'s `mix mailglass.repo.hygiene --check` includes a `branch_protection`
sub-check that, per TRUTH-06, currently 403s and reports that as "drift" rather than as
"could not verify." A 403 from the GitHub API (insufficient token scope, rate limiting, a
revoked/expired credential) is a **completely different operational condition** from
"branch protection is live and differs from expected" — the first needs a credential fix,
the second needs `scripts/setup_branch_protection.sh` to be re-run. Conflating them into
one "drift" signal sends whoever's triaging toward the wrong fix, and — worse — makes a
genuinely-fine protection state look broken (false alarm fatigue), which is precisely the
condition that makes a maintainer start ignoring red hygiene reports altogether, setting
up the next real drift to go unnoticed.

**Why it happens:** the simplest implementation of "check X against expected X" doesn't
distinguish "the check ran and X differs" from "the check couldn't run" — both paths often
fall through the same `if actual != expected` comparison unless the code explicitly
branches on the HTTP status / exception type first.

**How to avoid:**
- `mix mailglass.repo.hygiene`'s `branch_protection` sub-check must catch the
  specific 403/auth-failure case before attempting the diff, and report a distinct status
  (`error`/`unknown`, not `fail`/`drift`) with the actual HTTP status and a suggested next
  step ("check `GH_TOKEN`/`RELEASE_HYGIENE_PAT` scope") in the message.
- Confirm the token `repo-hygiene.yml` actually uses (`RELEASE_HYGIENE_PAT` falling back
  to `GITHUB_TOKEN`) has read access to branch-protection settings — the default
  `GITHUB_TOKEN` may not, depending on repo settings, which would make the 403 the
  *common* case rather than a rare edge case worth handling.
- Surface this distinction in `repo-hygiene.json`'s per-check status field (already
  structured as `.checks[] | {status, name, message}` per the workflow's summary step) so
  downstream consumers (the step summary, any future dashboard) can render "unknown" and
  "failed" differently rather than both reading as red.

**Warning signs:**
- `repo-hygiene`'s `branch_protection` check status is `fail` at a time when
  `setup_branch_protection.sh --print-expected-json` and a manual `gh api` check confirm
  protection is actually correct.
- The hygiene check's failure message doesn't include an HTTP status code or exception
  type — just a generic "drift detected" string.

**Phase to address:** Phase 144 (TRUTH-06).

---

### Pitfall 12: The anti-recursion self-heal becomes its own new blind spot

**What goes wrong:**
TRUTH-04 addresses the documented gap: bot-auto-merged release PRs don't fire
release-please's `push` trigger (GitHub anti-recursion), so tagging silently waits on the
hourly cron — costing ~30 minutes, three times, on 2026-07-28. `gate-ci-green` already
has a partial self-heal for the *sibling* anti-recursion gap (missing `ci.yml` runs on a
bot-merged SHA — it dispatches `ci.yml` and waits up to 30 minutes). Whatever TRUTH-04
ships for the release-please trigger gap risks the same shape of new problem: a
self-dispatch/self-heal mechanism that itself has a silent failure mode (the dispatch
call fails, the wait times out with an ambiguous message, or the self-heal fires
concurrently with the hourly cron and double-processes the same release).

**Why it happens:** "fix the recursion gap by adding another automated trigger" is the
natural instinct, but every new automated trigger in this pipeline is itself a new signal
that can lie, per this milestone's meta-pitfall. A self-heal that isn't itself
observable (no summary line distinguishing "self-heal fired and worked" from "self-heal
never got a chance to fire because the precondition was wrong") reproduces Pitfall 1 one
layer deeper.

**How to avoid:**
- If TRUTH-04 adds a new automated trigger (e.g., having `guard_release_trigger` or a
  dedicated workflow explicitly re-invoke release-please's tagging logic when it detects a
  bot-merged release commit with no tag yet), make its action **visible and idempotent**:
  log/summarize whenever it fires, and guard against firing concurrently with the existing
  hourly cron for the *same* pending release (compare against Pitfall 6's self-racing
  fan-out — this is the same hazard one step earlier in the pipeline).
- If TRUTH-04 instead formally **accepts** the gap (the milestone scope explicitly allows
  "fix or formally accept" as valid outcomes) — document the accepted ~30-minute-per-event
  cost somewhere durable (CONTRIBUTING.md, the workflow's own comments — both already
  partially do this) and make sure the *acceptance* itself doesn't quietly become "nobody
  remembers this is expected," which would turn a documented, bounded 30-minute wait back
  into an unexplained mystery the next time someone hits it.
- Whichever path is chosen, add it to the same GATE-03-style meta-test coverage this
  pipeline already leans on for other cross-file consistency claims, if the fix touches
  more than one workflow file.

**Warning signs:**
- A new self-dispatch/self-heal mechanism with no corresponding "did it fire" log line or
  step summary.
- The fix works for the specific 2026-07-28 sequence but wasn't tested against the case
  where the hourly cron and the new trigger race for the same release.
- "Formally accept" is chosen but the acceptance isn't written down anywhere a future
  maintainer would find it before spending 30 minutes confused again.

**Phase to address:** Phase 144 (TRUTH-04).

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems, specific to this milestone.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|-----------------|------------------|
| Tagging failing tests `@tag :skip` to green Core Full Suite | Fast, visible green | Manufactured signal — exact meta-pitfall this milestone exists to close | Never, without a `# Reason:`/`# Tracking:` comment and a corresponding test-count-floor check proving no coverage loss |
| Blanket `async: false` to dodge sandbox races | Removes flake without root-causing | 3-4x slower suite, hides the real ownership-leak mechanism, contradicts SEED-007's explicit DoD | Never as the terminal fix; acceptable only as a temporary, explicitly-labeled diagnostic step while isolating the mechanism |
| Hardcoding a lane-name string in a second location instead of reading the shared `CILanes` source | Fast, no cross-file plumbing | Recreates the exact `REQUIRED_LANES`/`ADVISORY_LANES`/`ci_lanes.ex` divergence already documented as TRUTH-07 | Never for new lanes; only tolerable for the existing copies until a meta-test closes the gap (tracked, not indefinite) |
| Adding an advisory-lane allowlist entry with no expiry | Unblocks merge immediately | Becomes a permanent, silently-decaying exception — the VULN-03 deadlock pitfall in miniature | Only with a recorded review-by date, never permanent |
| A drift-check wrapped in `if: <precondition>` with no failure-path else branch | Simple to write, doesn't need to handle the missing-precondition case | Reproduces the exact `branch-protection-drift.yml` incident | Never — every conditional guard needs an explicit non-green else branch |

## Integration Gotchas

Mistakes specific to this pipeline's external integrations.

| Integration | Common Mistake | Correct Approach |
|-------------|-----------------|-------------------|
| GitHub branch protection / status checks API | Configuring required contexts by job `id` instead of reported `name` | Always use the exact `name:` field (post-matrix-expansion) as it appears in the Checks API; verify with `gh api repos/OWNER/REPO/commits/SHA/check-runs` against a real run, not by reading YAML alone |
| GitHub Actions Jobs API (`listJobsForWorkflowRun`) | Matching job names with a substring/prefix heuristic (`isAdvisory`'s `startsWith`/regex) that silently admits a false match or false non-match on rename | Prefer exact-set membership against a shared, meta-tested source list over pattern matching wherever the job-name set is finite and known |
| Hex.pm publish + indexing | Treating `mix hex.publish --yes` success as immediate availability | This pipeline already retries `mix hex.info` polling correctly (`Wait for Hex.pm to index`) — preserve that pattern in any new publish-adjacent automation rather than assuming synchronous availability |
| Dependabot | Assuming dependabot PRs cover all advisories `mix hex.audit` would report | Dependabot only files for direct deps per configured `dependabot.yml` directory; transitive advisories need a separate raw-audit-output sweep (Pitfall 10) |
| Fine-grained PATs (branch protection, repo hygiene) | Treating a PAT as a "set once, forget" secret | Fine-grained PATs expire (max 1 year); track expiry and alert before it lapses into another silent Pitfall-1 skip |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Letting `publish-admin`/`publish-inbound` run when a preceding required job (`gate-ci-green`, `publish-core`) failed rather than merely being skipped | `HEX_API_KEY` exposure on a dispatch that should never have reached the publish step — this repo's own comments record this as the *original* bug behind the current `needs.publish-core.result == 'skipped'` (not `!= 'failure'`) guards | Any new job gated on `secrets.HEX_API_KEY` must check upstream job `.result` explicitly for `'success'`/`'skipped'-for-the-right-reason`, never rely on default `needs:` short-circuiting alone, and any change to phase 144's fan-out logic must preserve this exact distinction |
| Widening `BRANCH_PROTECTION_PAT` or `RELEASE_HYGIENE_PAT` scope "to make the 403 go away" | Overprivileged long-lived credential increases blast radius if leaked, for a problem that's usually a missing specific permission, not a systemic scope gap | Diagnose the exact missing permission from the 403 response before broadening scope; fine-grained PATs support minimal, specific permission sets — use them |
| A drift-fixing script deriving desired branch-protection state from a live (possibly attacker-influenced or degraded) API read | A compromised or 403-degraded read could cause the "fix" to assert an incorrect, less-protected state | Keep the desired state as a checked-in, code-reviewed constant (`expected_json`) — never computed at runtime from a live read, which this repo already does correctly; preserve that design under any TRUTH-03 changes |

## "Looks Done But Isn't" Checklist

Use this against every phase 141-144 deliverable before calling it done — each item ties
directly to this milestone's meta-pitfall.

- [ ] **Any new/modified guard or check:** verify it has an explicit, visible failure path
      when its precondition (secret present, API reachable, file exists) is false — not
      just a silent skip. (Pitfall 1)
- [ ] **HARNESS-01/02/03 (sandbox fix):** executed-test count is `>= 1401` (or the delta is
      explained), the `:already_shared` signature count is exactly 0 across all four
      matrix legs and multiple seeds, a written mechanism account exists, and a
      deliberate-failure probe against `Core Full Suite Advisory` (not just `CI Green`)
      confirms it still catches real regressions. (Pitfall 2, 4)
- [ ] **VULN-03 (advisory→gating promotion):** an expiring-allowlist/disposition mechanism
      ships in the *same* change as the gate flip, not after. (Pitfall 3)
- [ ] **Any branch-protection-adjacent script change:** confirm required-context strings
      are display names verified against a real Checks API response, not just eyeballed
      against YAML. (Pitfall 5)
- [ ] **Any workflow touching `release:`/tag events:** confirm concurrency scoping can't
      cancel an in-flight publish and that a redundant/idempotency-skipped run reports a
      status distinguishable from a genuine failure. (Pitfall 6)
- [ ] **CONFORM-04 (lane rename):** grep for the old name returns zero hits outside
      historical `.planning/` artifacts, and the renamed lane's required/advisory/neither
      classification was an explicit decision, not an inherited accident. (Pitfall 7, 9)
- [ ] **CONFORM-02 (icon gate):** a dynamic/interpolated icon-name fixture was used to
      prove the gate actually fails on the class, not just the two historical instances,
      then removed. (Pitfall 8)
- [ ] **TRUTH-06 (repo-hygiene):** a forced 403 (e.g., temporarily using a scopeless token
      in a manual dispatch) produces a visibly different status than a forced real drift.
      (Pitfall 11)

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|-----------------|-----------------|
| A guard is discovered to have been vacuously green (Pitfall 1 class) | MEDIUM | Audit every PR/release that passed while the guard was blind (same as the 22-PR/4-CVE audit already done for the originating incident); fix the guard; add the meta-test; do not silently re-arm without the retrospective |
| Sandbox fix later found to have been manufactured (tags/exclusions crept in) | MEDIUM-HIGH | Revert the tagging/exclusion diff specifically (not the whole fix), re-run the full anti-vacuity checklist (Pitfall 2), and re-open SEED-007's DoD as unmet |
| An advisory-to-gating promotion causes an unplanned lockout | LOW-MEDIUM | `workflow_dispatch` an emergency allowlist entry with a short (days, not weeks) expiry and a linked tracking issue; never silently revert the gate to advisory without recording why |
| A branch-protection "fix" locks out the maintainer | HIGH (time-sensitive) | GitHub org/repo owner can always override branch protection via the Settings UI regardless of required-status-check state (protection doesn't apply to the repo-admin's ability to change protection itself) — use that path immediately, then fix and re-review the script before re-running it |
| Renamed lane silently changed gating status (Pitfall 7) | LOW | Diff `gate-ci-green`'s effective classification before/after against a real Checks API run on the same SHA; restore intended status explicitly, backed by the meta-test fix from Pitfall 7/9 |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|-------------------|----------------|
| 1. Vacuous/self-blinding guards | Phase 144 (TRUTH-02, TRUTH-06) | Force the precondition false in a test run; confirm a non-green, visible result |
| 2. Manufactured green (HARNESS-03) | Phase 142 (HARNESS-03) | Test-count floor + signature reconciliation + deliberate-failure probe against Core Full Suite Advisory, all green |
| 3. Advisory→gating deadlock | Phase 141 (VULN-03), coordinated with 144 (TRUTH-05) | Simulate an unfixable HIGH advisory; confirm the allowlist/disposition path unblocks merge without silently disabling the gate |
| 4. Sandbox-fix coverage-reducing shortcuts | Phase 142 (HARNESS-01, HARNESS-02) | Green across all 4 matrix legs, multiple seeds; written mechanism account; permanent `:manual`-mode regression assertion present |
| 5. Branch-protection id/name + PAT + lockout | Phase 144 (TRUTH-03) | Meta-test diffs all required-context copies (`CILanes`, `ci.yml`, `publish-hex.yml`, `setup_branch_protection.sh`) against a live Checks API response |
| 6. Concurrency/self-racing publish | Phase 144 (TRUTH-04, TRUTH-08) | Simulate two tag events firing near-simultaneously; confirm the losing run's reported status is distinguishable from a real failure |
| 7. Lane-rename gating drift | Phase 143 (CONFORM-04), with 144 (TRUTH-07) | Old name absent from all three surfaces; new lane's required/advisory status is an explicit, tested decision |
| 8. Icon-existence gate blind to dynamic names | Phase 143 (CONFORM-02) | Deliberate dynamic-icon-name fixture fails the gate, then is removed |
| 9. Two definitions of "advisory" | Phase 144 (TRUTH-07) | Meta-test set-equality between `CILanes` and `gate-ci-green`'s hardcoded arrays; `MAINTAINING.md` citation resolved or removed |
| 10. Dependabot backlog + transitive blind spot | Phase 141 (VULN-02, VULN-04) | Documented cadence includes a raw `mix hex.audit` sweep, not just dependabot PR review; backlog explicitly dispositioned |
| 11. repo-hygiene 403-vs-drift conflation | Phase 144 (TRUTH-06) | Forced 403 produces a status distinct from forced real drift |
| 12. Anti-recursion self-heal becomes new blind spot | Phase 144 (TRUTH-04) | New trigger logs/summarizes every fire; tested against concurrent-with-cron race; or acceptance is durably documented |

## Sources

- `.planning/PROJECT.md` (Current Milestone: v2.2 section)
- `.planning/research/v2.2/MILESTONE-SCOPE.md`
- `.planning/seeds/SEED-007-sandbox-ownership-leak.md` (including its own documented
  correction of an earlier wrong inference — the direct precedent for this milestone's
  meta-pitfall)
- `.planning/research/PITFALLS.md` (v1 project-level register — no entries duplicated;
  this file is scoped specifically to CI-integrity/supply-chain additions)
- `.github/workflows/publish-hex.yml`, `branch-protection-drift.yml`,
  `guard-release-trigger.yml`, `advisory-matrix.yml`, `repo-hygiene.yml`,
  `gate-self-test.yml`, `ci.yml`
- `scripts/setup_branch_protection.sh`
- `mailglass_admin/scripts/check-conformance.sh`
- `test/support/ci_lanes.ex`, `test/scripts/required_checks_test.exs`
- `test/support/mailer_case.ex` (sandbox-mode call sites referenced in SEED-007)
- `.github/dependabot.yml`

---
*Pitfalls research for: mailglass v2.2 CI Signal Integrity & Supply-Chain Hygiene*
*Researched: 2026-07-28*
