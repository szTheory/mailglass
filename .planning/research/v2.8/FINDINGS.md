# v2.8 Research Findings — Truthful Repo

**Produced:** 2026-09-17, during `/gsd-new-milestone`
**Method:** 5 parallel research agents (CI lane audit, test-suite truth, release/hygiene
terminal state, quiet-state prior art, adopter-question verification), plus direct
orchestrator verification of every dated or load-bearing claim.

This file is the durable record so the work is not re-derived. Claims marked
**[verified]** were independently confirmed by the orchestrator at source, not
taken from an agent report.

---

## 1. The headline: the repo is already quiet; `STATE.md` is not

All three suites pass locally at HEAD `7e9617b2`:

| Package | Result | Wall |
|---|---|---|
| `mailglass` (core) | 2145 tests + 23 properties, **0 fail**, 7 skipped, 27 excluded | 511s |
| `mailglass_admin` | 510 tests, **0 fail** | 4.3s |
| `mailglass_inbound` | 460 tests + 3 properties, **0 fail** (incl. the 1000-run property) | 104s |

All 26 `ci.yml` jobs green on `main`. All 7 `advisory-matrix.yml` lanes green,
including the Elixir 1.19 / OTP 28 next-toolchain legs. Zero open PRs, zero open
issues **[verified]**.

### Stale beliefs refuted

Five of seven carried "known reds" are false as of HEAD:

- `MailglassAdmin.InboundLiveTest` `:913`/`:1411` replay-flash reds — **fixed** by
  `f733fc22` (#262) and `d65a1aa8` (#268). `STATE.md:342` still calls them
  "undiagnosed" and blames unmerged PR #129; #129 and #222 are both closed.
- `voice_test` "n**oops**" dep-JS substring — **fixed**; the test now strips
  `<script>` before matching (`voice_test.exs:38-41`).
- "~57 Oban failures on bare `mix test`" — **refuted** on `main` (0 failures). A
  worktree artifact.
- "Core Full Suite Advisory is the only full-core lane, persistently red" —
  **stale on both counts**. Phase 143/D-21 renamed it `Core Full Suite` and made the
  two 1.18 legs publish-gating; separately `ci.yml` now has a *required*
  `core_deterministic_suite` running the full suite. Both green.
- Clock global-impl async leak — **fixed**, with a permanent regression guard
  (`ClockRuntimeImplTest` is `async: false` and ships a meta-test scanning for
  `async: true` + `put_env(:mailglass, :clock)`, with anti-vacuity assertions).

**Lesson:** the planning tree's own staleness was the single largest source of
false belief in this milestone's scoping. That is itself the milestone's thesis.

---

## 2. Greens that do not mean what they say

Ranked by risk. These outrank visible reds: a red costs a glance, a false green is
why the admin blind spot hid two failures for four weeks.

### FG-1 — 64% of the admin suite runs in no lane **[verified: `ci.full:328,435`]**

`verify.support_contract.admin` is a hand-enumerated **9-file allow-list** and is the
*only* ExUnit execution of `mailglass_admin/test/` anywhere — in CI or in `mix ci`.
It runs **185 of 510** admin tests. CI's own log confirms "185 tests, 0 failures".

**325 admin tests across 32 files run nowhere.** Largest: `components_test.exs` (98),
`preview_live_test.exs` (28), `operator/shell_test.exs` (26), `inbound/components_test.exs`
(20), `voice_test.exs` (18), `accessibility_test.exs` (13), `axe_baseline_test.exs` (12).

The fix already exists and is unused: `mailglass_admin`'s `verify.preview` alias runs
`test --warnings-as-errors --exclude flaky`. No workflow and no `mix ci` path invokes it.

The repo has already written down why allow-lists are wrong — `mix.exs` comments on
`verify.mix_tasks` and `verify.ci_lane_contract` call a file-enumerated list
"silently drops newly-added tests from CI — the exact drift footgun." That reasoning
was never applied to admin.

Also: core and inbound each enforce a `coveralls` floor in CI; **admin has none.**

### FG-2 — a required lane declines to enforce its own anti-vacuity gate

`core_deterministic_suite` runs the complete 2145-test suite but self-reports
"scoped run … floor not evaluated" because `MAILGLASS_SUITE_FLOOR` is unset.
Fixing it requires bumping `@suite_floor_env_occurrences` from 2 to 3 in
`lane_classification_drift_test.exs:56`.

### FG-3 — the demo app never exercises its Hex pins **[verified]**

`MAILGLASS_DEMO_DEPS` appears only in `reference/demo_app/mix.exs:76`, its README,
`mix.exs:269` (an `rg` check expecting it in `compose.demo.yml`), and `.planning/`
prose. It is set in **no workflow, and not in `compose.demo.yml` either**. Every lane
builds the demo from path deps to the working tree; its Hex pins and locked 2.0.0
entries are never exercised. The demo app does not prove the published-consumer path
it appears to prove.

### FG-4 — trust-lane cache pollution vector (needs one bounded investigation)

Both trust lanes run `mix deps.get` **unlocked** against `reference/host_app`
(`ci.yml` L1226, L1307), resolving live 2.6.0, while the required compile/coverage
lanes test locked 2.0.0. Both share a deps cache keyed on `hashFiles('**/mix.lock')`
over the same `reference/host_app/deps` path. Plausible false-green vector; unconfirmed.

---

## 3. Controls that cannot reach their own pass state

### CT-1 — `post-publish-smoke` is structurally unable to pass between releases

`cron-guard` requires `COMPLETED==true`; `release_policy.exs` `completed-versions`
demands ledger `status=="completed"`. Close-out writes `"inactive"`. **A sane ledger
and a green canary are currently mutually exclusive** — doing the release *correctly*
arms a daily red.

Bounded fix: add a `baseline-versions` verb resolving from `status=="inactive"` +
`baselines` + `required_evidence_identifiers.historical_tag_sha`, running the **same**
exact Hex checksum/endpoint proof. Zero relaxation — it verifies the published
baseline instead of the in-flight target.

### CT-2 — `release-please` push/schedule split verdict **[verified]**

Empirically red at HEAD. The push run fails at the `release-please-action` step with
`API rate limit exceeded for user ID 28652` → `RESULT_STATUS: cannot-check`,
`RESULT_REASON: github_evidence_unavailable` → guard exits 1. The *schedule* run on
effectively the same state passes.

**Two composing causes, both needed:**

1. *Cause* — proposal mode short-circuits the already-tagged preflight
   (`if [ -z "$CANDIDATE_DIGEST" ]; then should_run=true; exit 0`, `release-please.yml` ~L92),
   so a push that is **the merge of `chore: release main`** re-runs the action against a
   SHA whose tags already exist. That is the redundant heavy API work.
2. *Symptom* — the action-step failure crashes rather than being classified into the
   evidence artifact.

**[verified] It is a _secondary_ rate limit, not budget exhaustion.** All 15 buckets read
full (`core 5000/5000`, `graphql 5000/5000`) at 19:54:46 while an Actions API call 403'd
at 19:52:44. **Consequence: "drop the hourly cron to daily" would NOT fix this.** Retry
with backoff on `cannot-check` + `github_evidence_unavailable` would. Scope any change
narrowly — do not relax fail-closed semantics generally; #278 just fixed the adjacent
`no_open_proposal` bug and that lesson holds.

### CT-3 — `repo-hygiene` predicate is unstable by design

Fails `:blocked` if `open_count > 0`. Green today (0 PRs) but red during **every**
contribution, every dependabot PR, and the whole release-proposal window. Keep
fail-closed; change the predicate to "open >14d **or** failing a required check".

### CT-4 — `Hex Audit` (required) reds on 2026-10-27 with zero commits **[verified]**

| Step | Source |
|---|---|
| Both cowlib entries carry `recheck_by: ~D[2026-10-26]` | `accepted_advisories.ex:73,88` |
| `expired_entries/1` flags strictly after | `accepted_advisories.ex:190-191` |
| Expired entries append to `blocking` → `{:error, blocking}` | `dev/mix/tasks/mailglass.audit.ex:145-155` |
| `hex_audit` is in `ci_green.needs` | `ci.yml:752-753, 1392` |
| A passing test asserts the exact flip date | `accepted_advisories_test.exs:160` |

**The repository already knows, in a passing test, the precise date it will break itself.**
Nothing surfaces it until it fires.

It also reds if Hex simply stops reporting one of the two advisories
(`unused_entries/0`, D-10). Correct action: genuinely re-verify upstream and either
extend the dates with written justification or drop the entries. **Deleting the expiry
machinery would be weakening a gate for cosmetic quiet — forbidden.**

Leave alone: `mailglass.publish.check.ex:1155-1234` queries `api.osv.dev` per allowlist
id on every publish, hard-blocking on `{:stale, …}` while failing **open** on network
errors (T-130-02). That fail-open is correct.

---

## 4. Docs that are actively wrong

Ordered by how much damage they do in the moment they are read.

| File | Claim | Reality |
|---|---|---|
| `CLAUDE.md` (Commit & Branch Conventions) | Release Please PR "auto-merges on green" | That step now only echoes *"Disarmed ordinary auto-merge; a later protected exact candidate-digest dispatch is required."* (`release-please.yml` ~L755). **Most misleading live claim in the repo** — a maintainer would wait forever mid-release. |
| `CONTRIBUTING.md:187-191` | A `fix(inbound):` floor bump is required on every core minor | Mechanically false under `~> 2.0`. Causes busywork or a blocked release. |
| `CLAUDE.md:56` | `mailglass_admin/mix.exs` declares `{:mailglass, "== <version>"}` | Actually `~> 2.0`. **Contradicts line 24 of the same file.** |
| `CLAUDE.md:15` | inbound on "its own stable `1.0` contract" | 2.x |
| `MAINTAINING.md` (whole file) | — | The words "close-out"/"closeout" and `.planning/release-target.json` **never appear**. The doc a maintainer opens mid-release omits the step whose omission caused the 4-week 2.5.0 strand. |
| `MAINTAINING.md:137` | "the twelve `exclude-paths` entries" | 14 |
| `MAINTAINING.md:631,662` | "hands-free publish fan-out … can never self-skip its own gate" | `required_reviewers`, 3 manual stops |
| `guides/compatibility-and-deprecations.md:207-212` | published builds "pin the exact sibling version … the current truth the repo can defend" | Disproved by the file it cites |
| `lib/mailglass/outbound.ex` moduledoc | orphan `:queued` Delivery rows reconcilable via `Events.Reconciler` age≥5min | **Not backed by code** — the Reconciler queries *events*, not deliveries (`events/reconciler.ex:58`) |
| `docs/api_stability.md:1119` | injected `import Swoosh.Email, except: [new: 0]` | Does not exist in `mailable.ex` |
| `CHANGELOG.md:171-173` | 2.0.0 "⚠ BREAKING CHANGES" block | Contains only a release-tooling note — **not the actual schema move** |
| `README.md:280-284` | links v1.0/v0.1/Swoosh guides | Does **not** link `guides/upgrading-to-v2_0.md` |
| `.planning/research/v1.7-admin-ui-polish/PITFALLS.md:223` + the 2026-09-17 reference-lock todo | "5-file" baseline lockstep | It is **4** — two files were deliberately de-hardcoded (`.planning/quick/260618-1qj-…`) |

### Dead config — a claim the code does not honor

`config :mailglass, renderer: [css_inliner: :none]` is accepted and validated
(`config.ex:84-88`) but **never read**; Premailex always runs (`renderer.ex:73`).
Same pattern for `renderer: [plaintext: ...]`.

### ⚠ Trap: the doc fixes are not free one-liners

`guides/migration-from-swoosh.md:31-32` (`~> 2.5`) is asserted **verbatim** by
`test/mailglass/docs_contract_test.exs:558`. Bumping the guide reds the docs contract
unless L558 moves with it. This is exactly the Phase 125 pin-drift shape that already
cost this project a deterministic red once.

---

## 5. Determinism hazards (ranked, from the live runs)

1. **Core and admin share the `mailglass_test` database** — undocumented in
   `CONTRIBUTING.md`/`MAINTAINING.md`. Safe today only because `mix ci` is serial. The
   audit reproduced 4 × `Postgrex.Error 57014 query_canceled` in `PersonaCohortTest`
   (`persona_cohort_test.exs:28,48,86,96`) simply by running core + admin concurrently;
   isolated re-run passed 6/6 in 0.4s. Any parallelization, or a contributor with two
   terminals, hits this.
2. **Non-sandbox global `TRUNCATE … CASCADE`** in `OperatorFixtures.reset!/0`
   (`operator_fixtures.ex:155`) — takes ACCESS EXCLUSIVE, bypasses sandbox isolation.
3. **Inbound `shared: true` sandbox owner + 1000-run property** — the documented
   `--seed 0` dependency. See the swamp list.
4. **The one `:flaky` tag in the repo** — `tenancy_test.exs:154`; `function_exported?/3`
   returns false when the module isn't yet in the caller's code cache. Its justification
   cites `.planning/phases/02-persistence-tenancy/deferred-items.md`, **a path that no
   longer exists** (archived away). Dangling pointer. Real fix: `Code.ensure_loaded!/1`.
5. **Elixir 1.18 deprecation warnings** (`:aliases`/`:requires`/`:functions` in
   `Code.eval_quoted/3`) from `mix_config_test.exs:82` — will become errors on a
   future Elixir.

---

## 6. Prior art and the boundedness mechanism

Sources: [SQLite QM plan](https://www.sqlite.org/qmplan.html) ·
[Google SRE — alerting on SLOs](https://sre.google/workbook/alerting-on-slos/) ·
[Eliminating Toil](https://sre.google/workbook/eliminating-toil/) ·
[imbue-ai/ratchets](https://github.com/imbue-ai/ratchets) ·
[Renovate automerge](https://docs.renovatebot.com/key-concepts/automerge/) ·
[Shopify 25% rule](https://shopify.engineering/technical-debt-25-percent-rule)

**Applies:** SQLite's published testable invariants (the model for exit criteria);
Google SRE's "every alert must be immediately actionable" — `release-please` on push is
a textbook non-actionable *cause*-alert, since nothing about the SHA is wrong;
the ratchet pattern as the termination guarantee.

**Does not apply:** stale bots (zero open issues — a solution shopping for a problem,
and it would add an eighth cron); maintenance-mode declaration (still shipping).

### Anti-pattern catalog

| Name | Symptom | Antidote |
|---|---|---|
| Instrument-panel inflation | Each incident adds a control; 7 crons now red without commits | Alert budget: adding one requires retiring one |
| Cosmetic green | Gate passes by weakening the check | `cannot-check` must *retry*, never *pass* |
| Cause-alerting | Push guard fires on GitHub API weather | Alert on the symptom, not the cause |
| Campaign reflex | Every noise class becomes a phase | One-time cleanup vs standing control |
| Backlog theater | Grooming a list nobody blocks on | 0 issues / 0 PRs = done; do not invent triage |
| Sunk-cost milestone | "We're 4 phases in, let's finish the 5th" | Hard timebox + stop-the-line |

### Install a control, don't run a campaign

| Noise class | One-time | Standing control |
|---|---|---|
| Open PRs/issues | — (already zero) | WIP limit |
| Dependabot volume | done (#260) | **grouped + weekly + `open-pull-requests-limit: 3`** |
| Scheduled-job reds | fix CT-1..CT-4 | every red actionable; `cannot-check` never passes |
| Test-lane blind spots | enumerate once | **invert allow-list → directory run** |
| Doc drift | one sweep | **assert the claim in a test** (`docs_contract_test` already does this) |
| Release-ledger strands | — (closed out) | already exists (#267); leave alone |

**Boundedness mechanism chosen:** the stop line *"every claim the repo makes about
itself is either true or tested."* Finite surface, and each fix is either a test
assertion or a deletion — both self-sustaining. Backup: hard 5-day timebox; on day 5,
ship what is done and close regardless.

---

## 7. Swamp list — explicitly NOT in v2.8

- **Inbound `--seed 0` property flake.** Root cause is `shared: true` + `TRUNCATE CASCADE`
  at 1000 iterations against a pooled sandbox. Fixing it properly means redesigning the
  property harness's isolation; fixing it cheaply means lowering `max_runs` or narrowing
  the generator — **weakening a test to get a green, which this repo forbids**. Current
  state is honest: documented in `ci_lanes.ex` and `MAINTAINING.md:431`, and the lane is
  deliberately non-gating *because* of it — "a lane whose green depends on a seed chosen
  to avoid a known nondeterminism is not trustworthy enough to gate a publish." The most
  honest piece of debt in the repo. **Leave documented.**
- **Phase 164/165 controlled-host tests (~30).** Machine-pinned by absolute path and
  digest, excluded in `test_helper.exs` itself, tied to an archived milestone. Portability
  is a rewrite of the finalizer's trust model. Leave quarantined.
- **The ~30 source-text-grep tests** (`File.read!(...) =~ "..."`). Defensible as
  drift-guards because the real execution runs in separate CI jobs. Cosmetically
  unsatisfying, not broken.
- **SEED-006 CI efficiency overhaul.** Already deferred out of v2.7. Note FG-1's fix
  makes CI *slower*; accept that.
- **`.planning/` archive prose.** Only 4 loose one-off audit `.md` files at root; the rest
  is past-tense provenance the audit trail depends on. Rewriting `==`/"hands-free" claims
  there would falsify history. Skip entirely.
- **`.tool-versions`.** The pinned 27.3.4.13 / 1.18.4 is the correct CI contract; the
  local gap is the contributor's.
- **Reference baseline advance.** Not needed for 2.6.0 — `~> 2.0` pins and locked 2.0.0
  agree, so `--check-locked` passes. Realized zero-commit reds are *third-party* drift
  only (phoenix 1.8.13; boundary 0.11.0 mid-PR on #276, fixed by `f2ceb4af`).

## 8. Do-not-touch

`hex-publish` `required_reviewers`; the fail-closed ledger state machine and `capture`
preconditions; `AcceptedAdvisories` expiry dates (bump only with fresh evidence); the
exact-version `== X.Y.Z` pins in smoke scripts (deliberate); 130 release tags;
`.planning/config.json` (user WIP); `reference/` determinism; `guard-release-trigger`'s
`Release-As:` escape hatch; the core package's `"."` root; `trust_lane_clean_baseline`'s
deliberately **non-required** status (`ci.yml` L1259-1260 + contract test L39 — do not add
it); the OSV fail-open branch; the `Code.string_to_quoted!`-not-`eval` lockfile walker in
`check_clean_baseline_hex_only.sh`.

## 9. Already fixed — removed from scope during scoping

- **Close-out baseline-of-record guard.** `scripts/check_published_baseline_of_record.sh`
  is **already wired** into `release_policy_close_out.sh:110` as of `#279` (`7e9617b2`),
  *after* the 2.6.0 close-out red at `29464056` **[verified]**. The dangerous half — going
  red two commits later and training the maintainer to expect red at close-out — is closed.
  What remains is ergonomic: the guard *detects* disagreement across the four records but
  does not *advance* the three hand-edited ones, so close-out still needs a manual edit.

  The script's own header states the thesis of this milestone better than anything else in
  the tree: *"A release ceremony that reliably ends red trains the maintainer to expect red
  at close-out, which is exactly when a real regression gets waved through."*

---

*Research persisted 2026-09-17 per CLAUDE.md Decision Policy step 1.*
