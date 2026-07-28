# Architecture Research — v2.2 CI Signal Integrity & Supply-Chain Hygiene

**Domain:** CI/release pipeline + test-harness architecture (maintenance milestone — NOT product architecture)
**Researched:** 2026-07-28
**Confidence:** HIGH (every claim below is cited to a file/line read directly in this worktree; two claims from `.planning/research/v2.2/MILESTONE-SCOPE.md` are corrected against the actual repo state — see "Corrections to the scope doc")

**Scope discipline:** this is an integration map for phases 141–144, not a redesign. No new
workflow files, no lane restructuring, no `ci_green` topology change are recommended. Every
change below is: promote a lane's classification, add a step to an existing job, widen a
`concurrency:` group, or fix a call site — all changes a single-commit PR can carry.

---

## Corrections to the scope doc

Two claims in `MILESTONE-SCOPE.md` / `SEED-007` do not survive a direct read of the repo. Both
change how phases 142 and 144 should be scoped — surfacing them here rather than letting a
phase plan silently inherit a wrong premise.

### Correction 1 — `MAINTAINING.md` exists. It is stale, not absent.

TRUTH-07 in `MILESTONE-SCOPE.md` states: *"the docstring cites `MAINTAINING.md` as the
authoritative split — that file has never existed in this repository."*

`MAINTAINING.md` exists at the repo root, 370 lines, added in `5f8d7f4a` ("feat(07-03): land
docs spine, guides, governance, and contract tests") — one of the earliest commits in the
repo's history. `test/support/ci_lanes.ex`'s docstring cites **lines 152–191**; that exact range
is real and contains a "Required Checks" / advisory-split section that precisely matches the
current 5-lane required set. So the citation is not a lie about a nonexistent file — it is a
citation to a **real but incomplete/stale document**:

- `MAINTAINING.md:154-158` — the 5 required contexts — is **current and correct**: `Support
  Contract Core`, `Support Contract Admin`, `Compile No Optional Deps`, `Trust Lane Repo Head`,
  `Installer Host Smoke`. Matches `CILanes.required_lanes/0` and `ci_green.needs` exactly.
- `MAINTAINING.md:180-191` — "advisory signal, not branch-protection truth" — lists **11
  lanes**: `Format Check`, `Compile Warnings as Errors`, `Mix Task Tests`, `Inbound Test`,
  `Inbound Compile No Optional Deps`, `Operator Browser Gate`, `Preview Capture Advisory`,
  `Core Full Suite Advisory`, `Provider Compatibility Advisory`, `Branch Protection Advisory`,
  `Provider Live Advisory`. This list **partially overlaps but does not match** either
  `CILanes.advisory_lanes/0` (11 lanes: the ci.yml six above plus `Credo Strict`, `Dialyzer`,
  `Docs Warnings as Errors`, `Hex Audit`, `Deps Audit Advisory`, minus `Preview Capture
  Advisory`/`Core Full Suite Advisory`/`Provider Compatibility Advisory`/`Branch Protection
  Advisory`/`Provider Live Advisory`) or `gate-ci-green`'s `ADVISORY_LANES` (2 explicit +
  regex). It predates `Credo Strict`'s conformance-script content, `Dialyzer`, `Hex Audit`,
  `Docs Warnings as Errors`, `Deps Audit Advisory`, `Installer Golden Gate`, and `Trust Lane
  Clean Baseline` all being added to `ci.yml` and never folded back into this doc.

**Effect on TRUTH-07:** there are not two conflicting registries to reconcile, there are (at
least) **three**: `CILanes.ex`, `gate-ci-green`'s hardcoded JS arrays, and `MAINTAINING.md`'s
prose — and none of the three match. `MAINTAINING.md` is real, must be corrected (not created),
and needs to become either (a) generated from `CILanes.ex` or (b) covered by a new meta-test the
same way `required_checks_test.exs` (GATE-03) and `ci_parity_drift_test.exs` (MIXCI-03) already
cover the ci.yml/mix.exs pairing. Neither existing meta-test touches `MAINTAINING.md` or
`publish-hex.yml`.

### Correction 2 — CONFORM-02's icon-existence gate already exists.

`MILESTONE-SCOPE.md` lists CONFORM-02 ("fail the build when a `<.icon name="hero-X">` has no
vendored SVG — close the invisible-icon class permanently, not just the two instances") as
**open** remaining scope (not struck through, unlike CONFORM-01/03).

`mailglass_admin/scripts/check-conformance.sh:148-179` already contains an `ICON-EXISTS-GATE`
that does exactly this: it greps every `hero-[a-z0-9-]+` usage under `mailglass_admin/lib/**/*.ex`,
diffs it against the keys vendored in `assets/vendor/heroicons-inline.js`, and fails (`exit 2` /
`errors+1`) on any usage with no matching key — plus a fail-loud guard (IN-03) against the scan
silently finding zero usages (a path/cwd bug that would otherwise pass vacuously). `git log -S
"ICON-EXISTS-GATE"` shows it was added in `31588bb4` — **the same PR #136** that
`MILESTONE-SCOPE.md`'s "Already delivered" section credits with fixing the two known invisible
icons (`hero-check`, `hero-information-circle`).

**Effect on CONFORM-02:** the general-case gate this line item asks for is already built and
already runs in `ci.yml`'s `credo_strict` job. What is **not** true is that this gate blocks
anything — see the next section: `credo_strict` (which is where `check-conformance.sh` actually
lives) is not in `ci_green.needs`, so `ICON-EXISTS-GATE` failing does not block a PR merge. Phase
143 should verify this gate still covers the codebase (it may — `mailglass_admin/lib` is the only
place `hero-*` classes appear; the script's own comment notes "no `.heex` partials exist in this
codebase") and spend its budget on CONFORM-04 (the naming/gating problem) rather than re-building
CONFORM-02. If a residual gap is found (e.g. a future `.heex` file, or `mailglass_admin/assets`
JS/HEEx string literals the grep misses), scope it narrowly — the general mechanism does not need
inventing.

---

## System overview — where lane identity lives (Question 1)

```
┌────────────────────────────────────────────────────────────────────────────┐
│ SOURCES OF TRUTH FOR "is lane X required or advisory?"                      │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                                │
│  test/support/ci_lanes.ex           Elixir-side canonical list.              │
│    @required_lanes (5)              Cited by 2 meta-tests below.             │
│    @advisory_lanes_ci (10)          Docstring cites MAINTAINING.md:152-191   │
│    @advisory_lanes_browser (1)      (real file, STALE — see Correction 1).   │
│         │                                                                     │
│         │ verified by (GATE-03)                                              │
│         ▼                                                                     │
│  test/scripts/required_checks_test.exs                                       │
│    - REQUIRED_CHECKS (setup_branch_protection.sh) == {CI Green,             │
│      Guard Release Trigger}                    [GATE-01, hardcoded 2]        │
│    - ci_green.needs display names == CILanes.required_lanes/0  [GATE-03]     │
│    - no required leaf is permanently if:-disabled                            │
│         │                                                                     │
│         │ verified by (MIXCI-03)                                             │
│         ▼                                                                     │
│  test/scripts/ci_parity_drift_test.exs                                       │
│    - mix ci ∪ mix ci.browser covers every required+advisory CILanes entry    │
│      by identity+flag-set (NOT publish-hex.yml — see gap below)              │
│                                                                                │
│  .github/workflows/ci.yml                                                    │
│    ci_green.needs: [5 job KEYS]           <- verified == CILanes (GATE-03)   │
│    23 other jobs exist; only these 5 gate merge                              │
│                                                                                │
│  .github/workflows/publish-hex.yml (gate-ci-green step)                      │
│    REQUIRED_LANES (JS array, 5 display names)  <- NOT machine-verified       │
│    ADVISORY_LANES (JS array, 2 explicit)       <- against CILanes.ex or      │
│    + regex /  Advisory \(/                        MAINTAINING.md. No test    │
│                                                     reads publish-hex.yml.    │
│                                                                                │
│  scripts/setup_branch_protection.sh                                          │
│    REQUIRED_CHECKS = {CI Green, Guard Release Trigger}  <- verified (GATE-01)│
│                                                                                │
│  MAINTAINING.md:152-191                                                       │
│    Prose required (5, current) + advisory (11, STALE — see Correction 1)     │
│    Cited by CILanes.ex docstring. NOT machine-verified against anything.     │
│                                                                                │
└────────────────────────────────────────────────────────────────────────────┘
```

### The hidden third tier: "not required, not advisory-recognized" = silently release-blocking

This is the load-bearing finding for TRUTH-07/VULN-03/CONFORM-04. `gate-ci-green` (in
`publish-hex.yml`) computes blocking failures as:

```js
jobs.filter(j => j.conclusion !== 'success' && j.conclusion !== 'skipped')
    .filter(j => !isAdvisory(j.name))          // isAdvisory: ADVISORY_LANES.startsWith() OR / Advisory \(/
    .filter(j => !REQUIRED_LANES.includes(j.name))
```

Any `ci.yml` job that is (a) not one of the 5 `REQUIRED_LANES` and (b) whose name does not match
`ADVISORY_LANES` or the `/ Advisory \(/` regex **blocks the Hex publish if it fails, even though
it never blocked the PR merge** (because it isn't in `ci_green.needs` either). Cross-referencing
every job actually defined in `ci.yml` against `REQUIRED_LANES` + `isAdvisory()`:

| Job (`name:` in ci.yml) | In `ci_green.needs`? | Recognized advisory by `gate-ci-green`? | Effective status |
|---|---|---|---|
| Support Contract Core / Admin, Compile No Optional Deps, Trust Lane Repo Head, Installer Host Smoke | Yes (5) | n/a | **Required** (PR + publish) |
| Deps Audit Advisory | No | Yes (regex ` Advisory (`) | Advisory (correct) |
| Preview Capture Advisory | No | Yes (regex) | Advisory (correct) |
| Operator Browser Gate | No | Yes (explicit array) | Advisory (correct) |
| Demo Browser Evidence | No | Yes (explicit array) | Advisory (correct) |
| **Format Check** | No | **No** | **Silently publish-blocking** |
| **Compile Warnings as Errors** | No | **No** | **Silently publish-blocking** |
| **Credo Strict** (contains `check-conformance.sh` + `check_credo_suppressions.sh` + `check_motion_conformance.sh` + `credo --strict`) | No | **No** | **Silently publish-blocking** |
| **Dialyzer** | No | **No** | **Silently publish-blocking** |
| **Docs Warnings as Errors** | No | **No** | **Silently publish-blocking** |
| **Hex Audit** | No | **No** | **Silently publish-blocking** |
| **Mix Task Tests** | No | **No** | **Silently publish-blocking** |
| **Inbound Test** | No | **No** | **Silently publish-blocking** |
| **Inbound Compile No Optional Deps** | No | **No** | **Silently publish-blocking** |
| **Installer Golden Gate** | No | **No** (not in `CILanes.ex` at all) | **Silently publish-blocking** |
| **Trust Lane Clean Baseline** | No | **No** (not in `CILanes.ex` either; `required_checks_test.exs` explicitly asserts it is *not* required, per D-04 — but says nothing about its publish-gate status) | **Silently publish-blocking** |
| **Branch Protection Advisory** | No | **No** — the job name has no `(` after "Advisory", so the regex `/ Advisory \(/` does not match, and it's not in the explicit array | **Silently publish-blocking in principle** (in practice this job's only substantive step uses `continue-on-error: true`, so the job itself never actually fails — see TRUTH-02 below) |

This is exactly what SEED-007 observed in the 2.1.1 gate failure ("named `Credo Strict` and
`Dialyzer`... never mentioned Core Full Suite") — those two are release-gating today, just not
merge-gating, and neither `CILanes.ex` (which calls them "advisory") nor `MAINTAINING.md`
(silent on them) says so. **Reconciling "one definition of advisory" (TRUTH-07) means picking,
for each of these 9+ jobs, one of two outcomes: (a) genuinely advisory — add to `gate-ci-green`'s
`ADVISORY_LANES` (or rename to the `<Name> Advisory (...)` convention so the regex catches it),
or (b) genuinely required — add to `ci_green.needs` + `CILanes.required_lanes()` (GATE-03 already
enforces set-equality once edited).** CONFORM-04's rename ("Credo Strict" → something naming
`check-conformance.sh`) is a prerequisite for deciding (a) vs (b) for that one lane honestly, but
renaming alone does not change its publish-gating status — that requires a `gate-ci-green` edit
either way.

### What a single-source-of-truth reconciliation touches (concrete file list)

1. `test/support/ci_lanes.ex` — decide per-lane classification; this is the canonical Elixir list.
2. `.github/workflows/publish-hex.yml` `gate-ci-green` step — `REQUIRED_LANES` / `ADVISORY_LANES`
   JS arrays must be edited to match (2) below, since no test currently enforces this pairing.
3. **New meta-test** (does not exist today) — parse `publish-hex.yml`'s `REQUIRED_LANES` +
   `ADVISORY_LANES` (+ the `/ Advisory \(/` convention) and assert set-equality against
   `CILanes.required_lanes()` / `CILanes.advisory_lanes()`, the same pattern
   `required_checks_test.exs` already uses for `ci.yml`. This closes the exact gap the "hidden
   third tier" table above exposes.
4. `MAINTAINING.md:152-191` — rewrite to match the reconciled list (or, better, replace the prose
   list with a generated block / a pointer to `mix mailglass.ci_lanes` output so it cannot drift
   again — a new mix task is optional scope, not required to close TRUTH-07).
5. `scripts/setup_branch_protection.sh` `REQUIRED_CHECKS` — **untouched** for any purely
   required↔advisory reclassification within `ci.yml`, because branch protection is locked to the
   two aggregate contexts (`CI Green`, `Guard Release Trigger`) by design (GATE-01 asserts this
   set exactly). Only touch this file if a *new* top-level required-check context (not a leaf
   under `CI Green`) is ever introduced — out of scope for 141-144.

---

## VULN-03 — promoting Hex Audit from advisory to gating

**What changes, concretely (four files, no topology change):**

| File | Change |
|---|---|
| `.github/workflows/ci.yml` | Add `hex_audit` to `ci_green.needs` (and to the `Evaluate required lane results` step's `for job_result in ...` loop). No other edit to the `hex_audit` job itself — it already runs unconditionally on `changes.outputs.code == 'true'`, already runs `mix hex.audit` with no `continue-on-error`. |
| `test/support/ci_lanes.ex` | Move `"Hex Audit (Elixir 1.18 / OTP 27)"` from `@advisory_lanes_ci` to `@required_lanes`. |
| `test/scripts/required_checks_test.exs` (GATE-03) | No edit needed — it reads `CILanes.required_lanes()` and `ci_green.needs` programmatically; it will simply start asserting the new pairing. The `@v1_0_lock_entries` list at the top of the file does not need Hex Audit added (that list is about a *different*, historical distinction — lanes that moved from `REQUIRED_CHECKS` to `ci_green.needs`; Hex Audit was never in `REQUIRED_CHECKS`). |
| `test/scripts/ci_parity_drift_test.exs` (MIXCI-03) | `matcher_for/1`'s table already has an entry for `"Hex Audit (Elixir 1.18 / OTP 27)" => &any_step?(&1, "hex.audit")` (line 113) — this table indexes by lane *name*, not by required/advisory bucket, so it needs **no edit**; `all_lanes/0` (`required_lanes() ++ advisory_lanes()`) will simply source the name from the other list after step 2. The `anti-vacuity` test's hardcoded `length(Mailglass.CILanes.required_lanes()) == 5` assertion (line 164) **must** be bumped to `6`, or it fails as an intentional regression guard doing its job. |
| `scripts/setup_branch_protection.sh` | **No change** — confirmed by GATE-01 (`REQUIRED_CHECKS` is locked to exactly `{CI Green, Guard Release Trigger}`; a leaf promotion under the `CI Green` aggregate never touches branch protection). This is the milestone scope doc's own hedge ("note: `ci_green` is the aggregate context, so adding a leaf may need no protection change — confirm") — **confirmed true**. |
| `.github/workflows/publish-hex.yml` | Add `'Hex Audit (Elixir 1.18 / OTP 27)'` to `REQUIRED_LANES` in `gate-ci-green` — otherwise a Hex-Audit failure on the tagged SHA would (per the "hidden third tier" table above) still block a publish, just without being *named* as required-vs-incidental in the failure message. Not strictly required for VULN-03's stated goal ("blocks merge"), but leaving it out perpetuates exactly the divergence TRUTH-07 exists to close — do both in the same PR. |

**Sequencing implication:** VULN-03 is a clean, self-contained, single-lane promotion — it does
not depend on HARNESS or CONFORM work, and its file list is a subset of what TRUTH-07's broader
reconciliation touches. It can land first and stand as the worked example TRUTH-07 generalizes.

---

## HARNESS-04 — promoting Core Full Suite to release-gating: the options

**Current state (verified):** `Core Full Suite Advisory` is defined only in
`.github/workflows/advisory-matrix.yml` (`core_full_suite_advisory` job, `on: push/pull_request/
schedule/workflow_dispatch`, 2-row schema matrix). `gate-ci-green` in `publish-hex.yml` calls
`listWorkflowRuns({ workflow_id: 'ci.yml', head_sha: sha })` and `listJobsForWorkflowRun` scoped
to that one run — it **never queries `advisory-matrix.yml`'s runs at all**. This isn't a
classification bug (unlike the "hidden third tier" table above) — it's architectural invisibility:
even if `Core Full Suite Advisory` succeeded 100% of the time, `gate-ci-green` has no code path
that would ever see it. This matches SEED-007's correction precisely.

**Option A — move the lane into `ci.yml`.**
- *Mechanics:* relocate the `core_full_suite_advisory` job body into `ci.yml`, add to
  `ci_green.needs` + `CILanes.required_lanes()`, drop the now-empty matrix entry from
  `advisory-matrix.yml` (keep `core_latest_elixir_advisory` and the other advisory-matrix jobs —
  they stay advisory by design, per LD-13's floor-coincidence invariant).
- *Cost:* `ci.yml`'s `support_contract_core` job already runs a **narrow** curated subset
  (`mix verify.support_contract.core`) as the required lane, specifically kept fast/stable. The
  full suite (~1401 tests, the ~120 core test files the required lane doesn't cover) is
  materially slower and is the exact thing 194/242 sandbox-leak failures currently make
  unusable as a release gate. **Moving it into `ci.yml` before HARNESS-01/02 land would make
  every PR merge block on a lane that is currently fully red** — this is the wrong order
  regardless of which option is chosen; HARNESS-01/02 (fix the leak, prove 4-leg green) is a hard
  precondition for *any* gating option, not just this one.
- *Consistency note:* this also duplicates the dual-schema matrix (`public` + `mailglass`) inside
  the required lane, which today runs matrix-free (see the `compile_no_optional_deps` job comment
  explaining why required leaves stay matrix-free — a 1-combo matrix appends ` (1.18, 27)` to the
  job name and breaks name-based required-context matching). A 2-row schema matrix under
  `ci_green.needs` is representable (each row becomes its own `needs` key with its own display
  name), but it doubles the required-lane count for one capability and is the most topology-adjacent
  of the three options — closest to violating "no CI topology rewrite."

**Option B — teach `gate-ci-green` to inspect a second workflow (`advisory-matrix.yml`).**
- *Mechanics:* add a second `listWorkflowRuns({ workflow_id: 'advisory-matrix.yml', head_sha: sha
  })` + job-list call in the `gate-ci-green` step, and require both schema-axis rows of
  `core_full_suite_advisory` to be `success` before publish. `ci.yml`'s `support_contract_core`
  stays the fast required PR lane; `advisory-matrix.yml` stays cron+push+PR as today (already
  runs on `pull_request`, so it already has current-SHA data — no new trigger needed).
- *Cost:* the anti-recursion self-heal logic in `gate-ci-green` (`Ensure a completed ci.yml run
  exists on tagged SHA`) is currently written only for `ci.yml`; a second workflow needs the same
  self-heal (dispatch-if-missing, poll-until-complete) duplicated or generalized into a helper —
  a real but bounded increment, not a redesign. `advisory-matrix.yml` has its own
  `concurrency: group: advisory-matrix-${{ github.ref }}` already independent of `ci.yml`'s, so
  no new race is introduced.
- *This is the option that best respects "no CI topology rewrite" and "the lane structure is
  sound"* — it keeps the required-PR-lane / full-suite-canary split exactly where it is today and
  only widens what the *publish* gate additionally inspects. It is the more faithful reading of
  HARNESS-04's own framing ("decide whether Core Full Suite should become release-gating" — a
  publish-time decision, not necessarily a merge-time one).

**Option C — accept the gap (formally, per TRUTH-05's "every advisory lane gets a recorded
disposition").** Valid if HARNESS-01/02's fix doesn't fully stabilize the full suite across all
four matrix legs in time, or if the maintainer decides a single-version-single-schema
`support_contract_core` narrow lane is sufficient release evidence. Must be **written down**
(SEED-007's own Definition of Done item 4 requires "a decision is recorded"), not silently
dropped — TRUTH-05 exists precisely to prevent lanes sitting undecided.

**Recommendation for the roadmap (not a mandate — a starting point for phase 142/144
planning):** Option B is the lowest-blast-radius path that satisfies "become release-gating"
without merge-time cost or PR-lane duplication, and it composes cleanly with the VULN-03 pattern
(same `gate-ci-green` step, same `REQUIRED_LANES`-style array, just workflow-scoped). It should
not be attempted until HARNESS-01 (fix the leak) and HARNESS-02 (green across all four legs,
repeatedly) are both done — this is a hard sequencing dependency, not a preference.

---

## HARNESS-01 — Ecto Sandbox ownership-leak call-site map

SEED-007's "Where To Start Reading" section is a good starting map but **incomplete** against a
direct `grep` of every `Sandbox.mode` / `Sandbox.start_owner!` / `Sandbox.checkout` /
`Sandbox.allow` call site in `test/` (root package only — inbound and admin have independent
`TestRepo`s in independent CI jobs with independent Postgres service containers, so they cannot
cross-contaminate the core suite's in-process sandbox pool state; the leak is necessarily
intra-suite within one `mix test` invocation of the core package). Two corrections/additions to
the seed's map, found by exhaustive grep + read, follow the baseline architecture below.

### Baseline: how sandbox mode is set and where

```
test/test_helper.exs:129   Sandbox.mode(Mailglass.TestRepo, :manual)   <- baseline, set ONCE at
                                                                            suite boot, after migrations
```

Every test file's case template then does one of:

| Mechanism | Call site(s) | Mode taken | Reverted by |
|---|---|---|---|
| `DataCase` (35 files use it; 22 of those pin/imply `async: false`) | `test/support/data_case.ex:35` — `start_owner!(TestRepo, shared: not tags[:async])` | `{:shared, owner_pid}` when `async: false`; individual ownership when `async: true` | `on_exit` → `stop_owner(pid)` at `data_case.ex:36` |
| `MailerCase` (7 files) | `mailer_case.ex:93` — identical `start_owner!(TestRepo, shared: not async?)` pattern; also `mailer_case.ex:158` and `:248` set explicit `{:shared, self()}` for the Oban / `set_mailglass_global` paths | Same shared/individual split, plus explicit global-shared opt-in | `on_exit` → `stop_owner(pid)` at `mailer_case.ex:206` |
| Explicit shared-mode property tests | `deliver_many_test.exs:17`, `deliver_later_test.exs:37` — `Sandbox.mode(TestRepo, {:shared, self()})` | Shared, keyed to the test process itself (not an owner process) | `on_exit` reverts to `:manual` explicitly (`:35`, `:54`) |
| **Additional explicit shared-mode site SEED-007's map omits** | `test/mailglass/properties/webhook_idempotency_convergence_test.exs:53` — `Sandbox.start_owner!(TestRepo, shared: true, ownership_timeout: 10*60_000)` | Shared, extended 10-minute ownership timeout for the 1000-iteration property run | `on_exit` → `Sandbox.stop_owner(owner)` at `:68` — paired correctly, but it is a **fourth** explicit-shared-mode acquisition point not listed in SEED-007's "Where To Start Reading," structurally identical to the sibling `idempotency_convergence_test.exs` SEED-007 does cite as a `:auto`-switcher (it is not — this file uses `start_owner!(shared: true)`, a different mechanism than the `Sandbox.mode(:auto)` switch its sibling properties files use; conflating the two in a call-site map would miss this one). |
| Mode-switching files (`:auto` then revert to `:manual`) — matches SEED-007's list of 9 | `migration_test.exs:23/42`, `upgrade_v2_schema_migration_test.exs:61/94`, `schema_prefix_hardening_test.exs:88/110`, `schema_isolation_integration_test.exs:56/99`, `schema_isolation_immutability_test.exs:49/90`, `shipped_migration_divergence_test.exs:48/81`, `properties/webhook_suppression_convergence_test.exs:16/24`, `properties/idempotency_convergence_test.exs:43/53`, `properties/unsubscribe_post_idempotency_property_test.exs:69/103` | `:auto` (disables per-process ownership entirely — ANY process can query without checkout) | Explicit `Sandbox.mode(TestRepo, :manual)` in `on_exit`, verified present in every file grepped |
| **Additional non-owning raw checkout SEED-007's map omits** | `test/mailglass/schema_axis_boot_order_test.exs:27` — `:ok = Sandbox.checkout(TestRepo)` (no `start_owner!`, no explicit `shared:` option, `async: false`) | Individual ownership tied to the calling (test) process | **No explicit `checkin`/`stop_owner`/`on_exit` at all.** Ecto's Sandbox monitors the owning process and auto-releases on process death, which is the normal, safe pattern for a bare `checkout/1` in a short-lived ExUnit test process — flagged here only because it is architecturally distinct from every other call site (no owner-process indirection, no revert step), not because it is independently suspected as the leak's origin. |

### Where the leak most plausibly originates, given this map

SEED-007's own empirical findings stand (194 `:already_shared` failures, only reproducible
against the full suite, not any single file in isolation, not the citext probe, not migration
teardown). Given the corrected map above, the two most likely mechanism classes to investigate
first, in order:

1. **`DataCase`, not `MailerCase`, is the dominant shared-mode acquisition site by volume** (35
   files vs. 7, and DataCase is `Mailglass.DataCase` — used across the schema/persistence/webhook
   layers the sandbox-leak signature clusters around). SEED-007's citation of only
   `mailer_case.ex:93/158/248` as "where shared mode is taken" under-counts the surface area by
   roughly 5x. Any investigation into "which async:false test's owner fails to release before
   the next owner-taking test starts" must treat `data_case.ex:35` as an equal-or-greater
   candidate to `mailer_case.ex:93`, not a secondary one.
2. **The `webhook_idempotency_convergence_test.exs` extended-timeout shared owner** (10-minute
   `ownership_timeout`, `:property`-tagged, `async: false`) is architecturally the highest-risk
   single site in the whole map: an owner intentionally held far longer than ExUnit's default
   per-test timeout, running 1000 StreamData iterations, immediately adjacent (alphabetically and
   by directory) to three other `:auto`-mode-switching property files. If ExUnit's scheduler
   interleaves this file's still-open 10-minute shared owner with any `:auto`-mode file's own
   `on_exit` reverting to `:manual` mid-run, the two mode-management strategies (owner-scoped
   `{:shared, pid}` vs. suite-global `:auto`) collide on the same repo's single global mode flag
   in a way neither file's own `on_exit` can detect or guard against. This is a *hypothesis to
   test*, not a confirmed root cause — SEED-007 explicitly instructs "confirm the mechanism
   before changing anything," and that instruction still holds; this finding narrows where to
   start, it does not replace the confirmation step.

**Phase 142 planning implication:** budget investigation time proportional to the corrected
surface (DataCase's 35 files, not MailerCase's 7) and treat the `properties/` directory's four
files (three `:auto`-switchers + the one `start_owner!(shared: true, ownership_timeout: ...)`
outlier) as the highest-density cluster to instrument first, since SEED-007 already ruled out
every isolated single-file reproduction and named "cross-file global-state interaction" as the
likely shape.

---

## TRUTH-08 — the self-racing publish fan-out

**Trigger topology (verified):** `release-please-config.json`'s `linked-versions` plugin groups
`mailglass` + `mailglass_admin` (component names `"mailglass"`, `"mailglass_admin"`) — this
locks their **version numbers** together but release-please still emits one GitHub Release
(`release: published` event) **per component**, i.e. per tag (`mailglass-vX.Y.Z` and
`mailglass_admin-vX.Y.Z`, created moments apart in the same release-please run).
`publish-hex.yml`'s `on: release: types: [published]` trigger therefore fires **twice** for one
release train, each with its own `github.event.release.tag_name`.

**Root cause of the race:** `publish-hex.yml`'s top-level `concurrency:` block is:

```yaml
concurrency:
  group: publish-hex-${{ github.ref }}
  cancel-in-progress: false
```

For a `release: published` event, `github.ref` resolves to `refs/tags/<the specific tag for that
release>` — which **differs between the two triggering tags**. The two runs therefore land in
two *different* concurrency groups and run fully in parallel, not serialized. Both attempt
`publish-core` (each gated only by its own idempotency check —`mix hex.info mailglass
<VERSION> | grep "Released:"` — which races against the *other* run's in-flight
`mix hex.publish`). If run B's idempotency probe fires in the window after run A's
`hex.publish` call but before Hex.pm indexes it, B also attempts to publish the same version;
Hex.pm rejects the second publish of an already-existing version, and that step fails
non-zero — the run is reported FAILED even though the release succeeded (via run A). This is
precisely TRUTH-08's "one wins, the other reports failure on an already-published package."

**Where the fix sits:** widen the `concurrency.group` key to something invariant across both
tags of the same release train — e.g. `publish-hex-${{ github.repository }}` (fully serializes
*all* publish-hex runs repo-wide, which is safe: publishes are infrequent and the workflow is
already designed to be idempotent/skip-aware) or a computed key derived from
`.release-please-manifest.json`'s content at trigger time (more precise, more moving parts). With
`cancel-in-progress: false` already set, a widened group makes run B **queue** behind run A
rather than run concurrently; by the time B starts, its idempotency guard (`mix hex.info` /
`skip=true`) correctly no-ops `publish-core`/`publish-admin`/`publish-inbound` without ever
attempting a duplicate `hex.publish`, and B reports success (nothing to do) instead of failure
(raced to do it twice). This is a one-line `concurrency.group` edit — no job-graph change.

**Adjacent, not-explicitly-scoped observation:** `.github/workflows/post-publish-smoke.yml` has
the structurally identical pattern — `concurrency: group: post-publish-smoke-${{ ...
tag_name || github.ref }}` — also scoped per-tag, also triggered by `release: published`, also
fires twice per release train. `MILESTONE-SCOPE.md`'s TRUTH-08 text names only `publish-hex`
runs; whether to fix `post-publish-smoke.yml` in the same phase (same one-line class of fix,
same trigger topology) or leave it for a later pass is a scope call for phase 144 planning, not
a fact this research can settle — flagging it so it isn't independently "discovered" mid-phase
as a surprise.

---

## CONFORM-04 — where the rename attaches

`credo_strict` (job key) / `"Credo Strict (Elixir 1.18 / OTP 27)"` (display name) in `ci.yml`
runs, in order: `check_credo_suppressions.sh`, `check_motion_conformance.sh`,
`mailglass_admin/scripts/check-conformance.sh` (hard-fail arms — BADGE/TYPE-base/BOLD/GAP/HEX/
ICON-EXISTS per the script's own header), `check-conformance-advisory.sh` (soft arms), then
finally `mix credo --strict`. The name "Credo Strict" describes only the last of five steps. Per
`MILESTONE-SCOPE.md`: *"the misleading name is why nobody looked at it for weeks."*

**Rename mechanics** — every place the string `"Credo Strict (Elixir 1.18 / OTP 27)"` appears
verbatim must move together (a rename is a distributed literal, same class of risk as the
required-lane set):
- `.github/workflows/ci.yml` job `name:` field (the source of truth for the display string).
- `test/support/ci_lanes.ex` `@advisory_lanes_ci` entry.
- `test/scripts/ci_parity_drift_test.exs` `matcher_for/1`'s map key (line 109) **and** the
  `anti-vacuity` test's `matcher_lanes` MapSet literal (line 187) — both are exact-string keyed;
  GATE-03/MIXCI-03 will catch a missed rename as "lane with no matcher" (fail-loud, by design).
- `MAINTAINING.md` — not currently listed there at all (Correction 1 above already flags this
  file as stale for this exact lane), but if it's brought current as part of TRUTH-07, the new
  name goes in whichever list (required/advisory) is decided.
- `gate-ci-green` in `publish-hex.yml` — **not currently referenced anywhere** in that file's
  `REQUIRED_LANES`/`ADVISORY_LANES` arrays (confirming the "hidden third tier" finding above: this
  job is invisible to both classification arrays today, so it silently blocks publish under its
  *current* name and would continue to do so, silently, under any *new* name, unless CONFORM-04 is
  paired with a `gate-ci-green` classification decision).

**Recommendation:** land CONFORM-04's rename in the same change as picking this lane's
classification for `gate-ci-green` (per the TRUTH-07 reconciliation above) — renaming without
resolving the classification just gives the same undecided lane a more honest name; TRUTH-05
("every advisory lane gets a recorded disposition") applies to it either way.

---

## Suggested build order across phases 141–144

Ordering respects three hard dependencies: (a) HARNESS-01 must land before HARNESS-02/04 (can't
prove 4-leg green or decide gating on a suite whose signal is currently unusable); (b) any
`gate-ci-green` classification edit (VULN-03, part of TRUTH-07, CONFORM-04's pairing) is
independent of the sandbox work and of each other — they touch disjoint job names; (c) TRUTH-08's
`concurrency:` fix is fully independent of everything else in the milestone.

**Wave 1 — fully independent, any order, safe to parallelize:**
- **VULN-02** (dependabot backlog disposition) — process/PR triage, zero file coupling to
  anything else in the milestone.
- **VULN-03** (Hex Audit promotion) — self-contained per the file list above.
- **VULN-04** (transitive-dependency triage cadence) — documentation + process, no file coupling.
- **TRUTH-08** (publish fan-out race) — one-line `concurrency.group` widening, isolated to
  `publish-hex.yml` (+ optionally `post-publish-smoke.yml`).
- **TRUTH-02** (a skipped drift check must not report green) — NOTE: per direct read, the
  behavior described (a `if: pat_present == 'true'`-gated comparison that trivially "succeeds"
  when skipped) lives in **`ci.yml`'s `branch_protection_advisory` job**, not literally in
  `.github/workflows/branch-protection-drift.yml` (that file was split via `b99930ea` into a
  PAT-gated *apply*-only workflow with no comparison logic at all — nothing in it currently
  claims a comparison result). Route this phase's fix to the actual culprit job.
- **TRUTH-06** (repo-hygiene 403-vs-drift conflation) — isolated to
  `dev/mix/tasks/mailglass.repo.hygiene.ex`'s `branch_protection/1` (collapses any non-zero exit
  from `verify-branch-protection.sh` — genuine drift, a 403, or a network failure — into the same
  `:blocked` classification; needs to distinguish them, e.g. by exit code or `gh api` HTTP status
  parsing).
- **CONFORM-02 verification** (confirm `ICON-EXISTS-GATE` is complete — see Correction 2; likely
  near-zero remaining work, not a build item).

**Wave 2 — depends on Wave 1's TRUTH-07 groundwork conceptually, but is mechanically independent
file-work that can start in parallel once the classification decisions are made:**
- **TRUTH-07** (reconcile the three registries) — natural home for VULN-03's pattern generalized:
  decide the 9-job "hidden third tier," write the new `publish-hex.yml`-vs-`CILanes.ex` meta-test,
  correct `MAINTAINING.md:152-191`.
- **CONFORM-04** (rename + classification pairing) — best sequenced *after* or *alongside*
  TRUTH-07 since it needs the same "what does `gate-ci-green` think Credo Strict is" decision;
  doing it first just means TRUTH-07 revisits the same lane a second time.
- **TRUTH-05** (recorded disposition for every advisory lane) — falls out mechanically once
  TRUTH-07's reconciliation table exists; not separate research/build work, mostly a documentation
  pass over the table TRUTH-07 produces.

**Wave 3 — hard-sequenced, cannot parallelize internally:**
- **HARNESS-01** (root-cause + fix the sandbox leak) — must come first; corrected call-site map
  above (prioritize `DataCase`'s 35 sites and the `properties/` directory's extended-timeout
  outlier) is this phase's starting point.
- **HARNESS-02** (green across all 4 matrix legs, repeatedly) — depends on HARNESS-01.
- **HARNESS-03** (confirm recovered tests genuinely execute/assert, not skip-tagged to fake green)
  — depends on HARNESS-02's green run existing to audit.
- **HARNESS-04** (decide + implement release-gating for Core Full Suite) — depends on
  HARNESS-01/02/03 all being done; Option B (teach `gate-ci-green` to inspect
  `advisory-matrix.yml`) is the option most consistent with "no CI topology rewrite," but is
  itself independent of, and can be built in parallel with, Wave 1/2 items once HARNESS-01-03
  land — it only touches `gate-ci-green` + (optionally) `CILanes.ex`, the same seam VULN-03/
  TRUTH-07 already touch, so sequencing it *last* lets it reuse whatever meta-test infrastructure
  TRUTH-07 built for the publish-hex-vs-CILanes pairing instead of duplicating it.

**Net phase-number mapping (141/VULN, 142/HARNESS, 143/CONFORM, 144/TRUTH) vs. this dependency
graph:** the milestone's phase numbering is not itself a strict build order — VULN (141) and
CONFORM (143) items are Wave-1/near-Wave-1 independent work that could physically execute
alongside early HARNESS (142) investigation; only HARNESS's *internal* 01→02→03→04 chain and
TRUTH's (144) dependency on decisions made throughout are hard-ordered. If phases execute
strictly in number order, HARNESS-04's Option B should be deferred to land alongside or after
TRUTH-07's meta-test work despite being numbered before it, since it reuses that seam.

---

## Sources

All findings verified by direct read of this worktree, 2026-07-28:
- `.planning/PROJECT.md` (v2.2 section), `.planning/research/v2.2/MILESTONE-SCOPE.md`,
  `.planning/seeds/SEED-007-sandbox-ownership-leak.md`
- `.planning/research/milestone-cicd/CICD-RELEASE-HARDENING.md`, `SYNTHESIS.md` — historical
  (v1.15-era) context only; several of its proposals (fan-in gate, `~>` pins, cache-key
  toolchain scoping) are already shipped in the current `ci.yml`/`mix.exs`, confirmed by direct
  read rather than assumed from the dossier.
- `.github/workflows/ci.yml`, `advisory-matrix.yml`, `publish-hex.yml`, `release-please.yml`,
  `guard-release-trigger.yml`, `branch-protection-drift.yml`, `repo-hygiene.yml`,
  `post-publish-smoke.yml`
- `test/support/ci_lanes.ex`, `test/scripts/required_checks_test.exs`,
  `test/scripts/ci_parity_drift_test.exs`
- `test/support/mailer_case.ex`, `test/support/data_case.ex`, `test/test_helper.exs`, plus an
  exhaustive `grep -rn "Sandbox\.(mode|start_owner|checkout|allow)"` across `test/`,
  `mailglass_admin/test/`, `mailglass_inbound/test/`
- `scripts/setup_branch_protection.sh`, `scripts/verify-branch-protection.sh`,
  `dev/mix/tasks/mailglass.repo.hygiene.ex`
- `release-please-config.json`, `.release-please-manifest.json`
- `mailglass_admin/scripts/check-conformance.sh`, `mailglass_admin/assets/vendor/heroicons-inline.js`
- `MAINTAINING.md` (existence + content directly verified — corrects `MILESTONE-SCOPE.md` TRUTH-07)
- `.github/dependabot.yml`
- `git log` (blame/history) for `.github/workflows/branch-protection-drift.yml` and
  `mailglass_admin/scripts/check-conformance.sh` (`ICON-EXISTS-GATE` provenance) and
  `MAINTAINING.md` (existence-since-commit)

---
*Architecture research for: mailglass v2.2 CI Signal Integrity & Supply-Chain Hygiene*
*Researched: 2026-07-28*
