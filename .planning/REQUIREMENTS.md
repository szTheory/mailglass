# Requirements: mailglass v2.8 — Truthful Repo

**Defined:** 2026-09-17
**Core Value:** Email you can see, audit, and trust before it ships.
**Milestone goal:** Make every claim the repository makes about itself either true or tested.
**Evidence base:** `.planning/research/v2.8/FINDINGS.md` (5 parallel research agents + direct
orchestrator verification of every dated or load-bearing claim).

**Hard timebox:** 5 working days. **WIP limit:** 1 open PR at a time. **Two phases, no third.**

---

## The stop line

> Every claim the repo makes about itself is either true or tested.

Anything discovered during execution that is not one of the requirements below is **filed, not
fixed**. If the work does not fit in two phases, that is evidence the scope was wrong — not that it
needs a third phase. On day 5, ship what is done and close the milestone regardless.

## The standing prohibition

**No requirement below may be satisfied by weakening a gate, relaxing a fail-closed control, deleting
an expiry, lowering a test's rigor, or narrowing a generator.** Every change must be auditable as
*"made a control able to reach its own pass state"* — and each PR's diff is reviewed against that
sentence. Three specific temptations were identified in research and are pre-refused:

- Making `cron-guard` `continue-on-error`, or dropping a cron, to silence `post-publish-smoke`.
- Deleting the `recheck_by` / `unused_entries` machinery to make `Hex Audit` permanently green.
- Lowering `max_runs` or narrowing the generator on the inbound property test.

---

## v2.8 Requirements

### Greens That Lie (GREEN)

Signals that currently report success without earning it. **These outrank visible reds:** a red costs
a glance; a false green is why the admin blind spot hid two failures for four weeks.

- [x] **GREEN-01**: The full `mailglass_admin` test suite executes in CI. The hand-enumerated 9-file
      allow-list in `verify.support_contract.admin` is replaced by a directory-scoped run (the
      existing, uninvoked `verify.preview` alias is the intended mechanism), in both CI and `mix ci`.
      *Accept:* the `Support Contract Admin` lane log reports ≥510 tests, not 185, with 0 failures.

- [x] **GREEN-02**: `mailglass_admin` enforces a coverage floor in CI, as core and inbound already do.
      *Accept:* the admin lane fails when coverage drops below the committed threshold.

- [x] **GREEN-03**: The required `core_deterministic_suite` lane enforces its own anti-vacuity floor.
      `MAILGLASS_SUITE_FLOOR: "1"` is set, and `@suite_floor_env_occurrences` in
      `lane_classification_drift_test.exs:56` moves 2 → 3 in the same change.
      *Accept:* the lane's log prints `scope: FULL SUITE (MAILGLASS_SUITE_FLOOR=1)` instead of
      "scoped run … floor not evaluated".

- [x] **GREEN-04**: The demo app exercises its Hex pins in at least one lane. `MAILGLASS_DEMO_DEPS`
      is set where the demo is built, so the published-consumer path is actually proven.
      *Accept:* a CI lane resolves the demo app's Hex deps rather than path deps to the working tree.

- [ ] **GREEN-05**: The trust-lane deps-cache pollution vector is resolved or refuted in writing. Both
      trust lanes run `mix deps.get` unlocked against `reference/host_app` (`ci.yml` L1226, L1307),
      resolving live 2.6.0, while required lanes test locked 2.0.0 — sharing a cache keyed on
      `hashFiles('**/mix.lock')` over the same path.
      *Accept:* either the cache keys are disambiguated, or a committed note demonstrates the lanes
      cannot contaminate each other. **A "probably fine" verdict does not satisfy this.**

### Controls That Cannot Pass (CTRL)

Fail-closed controls that are structurally unable to reach their own success state. Every fix here
adds a path to *earn* green; none relaxes a gate.

- [x] **CTRL-01**: `post-publish-smoke` can pass on its schedule between releases. A
      `baseline-versions` resolution path handles `status == "inactive"` using `baselines` +
      `required_evidence_identifiers.historical_tag_sha`, running the **same** exact Hex
      checksum/endpoint proof against the published baseline.
      *Accept:* a `workflow_dispatch` of the schedule path against the current `inactive` ledger exits
      0 and uploads `post-publish-resolution.json`. Dispatch semantics for a live release are unchanged.

- [ ] **CTRL-02**: `release-please` no longer re-runs the action against an already-tagged SHA on the
      push event. The tagged-PR preflight skip is restored for `push` in proposal mode
      (`release-please.yml` ~L92): `release-preflight` correctly reports that the release-please action
      should not re-run once `main`'s manifest tags all exist, but the proposal-evidence steps were
      gated on that same flag, so the control could not observe the repository it reports on; Phase
      167.1 decouples discovery from that flag.
      *Accept:* the merge of a `chore: release main` PR produces a green `release-please` push run.

- [ ] **CTRL-03**: A transient GitHub API failure is retried, not reported as a control failure. An
      action-step failure is classified into the evidence artifact rather than crashing, and
      `cannot-check` + `github_evidence_unavailable` is treated as retryable with backoff.
      *Accept:* three consecutive pushes to `main` produce `success`, and `push` and `schedule` at the
      same SHA agree. **`cannot-check` must still never report as `pass`.**
      *Note:* the 2026-09-18 audit measured the GitHub API quota at 5000/5000 during the reds — it was
      not exhausted. The root cause was the same conflated `should_run` flag CTRL-02 corrects (Phase
      167.1), not a rate limit; reducing cron frequency remains not a fix and remains out of scope.

- [x] **CTRL-04**: The `Hex Audit` calendar time bomb is defused truthfully before it fires. Both
      cowlib advisories (`EEF-CVE-2026-43966`, `EEF-CVE-2026-43969`, `recheck_by: ~D[2026-10-26]`) are
      genuinely re-verified upstream, then either extended with written justification or removed if
      upstream now has a fix.
      *Accept:* `mix mailglass.audit --kind hex` passes with the system clock faked to 2026-12-01, and
      each entry's disposition cites the evidence it was re-verified against.
      **Deleting `expired_entries/1` or `unused_entries/1` does not satisfy this.**

- [ ] **CTRL-05**: `repo-hygiene` distinguishes a non-verdict from an alarm, and its PR predicate
      stops firing on healthy activity. `cannot_check` is separated from `blocked` in the exit code,
      and the predicate changes from `open_count > 0` to "open >14d **or** failing a required check".
      *Accept:* two consecutive scheduled runs conclude `success` with `status: pass`, and a freshly
      opened healthy PR does not turn it red.

### Claims That Are Wrong (DOCS)

Documentation that actively misleads at the moment it is read. Ordered by damage done. **Each
correction must be pinned by a test or generated, not merely proofread** — that is what makes this
milestone terminate rather than recur.

- [x] **DOCS-01**: `STATE.md` contains no claim contradicted by HEAD. The `## Operator Next Steps` and
      Session Continuity blocks are truthed up: the two `InboundLiveTest` reds (fixed in `f733fc22` /
      `d65a1aa8`), PR #222 and #129 (both closed), and the "14 open PRs" accepted-debt count (now zero).
      *Accept:* no statement in `STATE.md` is falsified by `gh pr list`, `gh issue list`, or a live
      suite run.

- [x] **DOCS-02**: `CLAUDE.md` describes the release pipeline as it actually behaves. Specifically the
      auto-merge claim (the step now echoes *"Disarmed ordinary auto-merge; a later protected exact
      candidate-digest dispatch is required"*), the `{:mailglass, "== <version>"}` sibling-pin claim at
      :56 which contradicts line 24 of the same file, and the inbound "stable `1.0` contract" claim
      at :15.
      *Accept:* a maintainer following `CLAUDE.md` through a release is never told to wait for
      something that will not happen.

- [x] **DOCS-03**: The release-mechanics docs are correct and complete. `CONTRIBUTING.md:187-191`'s
      mandatory `fix(inbound):` floor bump (mechanically false under `~> 2.0`) is retired;
      `MAINTAINING.md`'s "twelve `exclude-paths`" (:137, actually 14) and "hands-free publish fan-out"
      (:631, :662 — there are three `required_reviewers` stops) are corrected; and **`MAINTAINING.md`
      gains the close-out section it has never had** — the ledger state machine and
      `release_policy_close_out.sh`, whose omission caused the 4-week 2.5.0 strand.
      *Accept:* a reader who has never seen the ledger can complete close-out from `MAINTAINING.md`
      alone.

- [x] **DOCS-04**: Version claims in guides are correct, and the two-file lockstep is respected.
      `guides/migration-from-swoosh.md:31-32` (`~> 2.5`) is asserted **verbatim** by
      `test/mailglass/docs_contract_test.exs:558` — both move together, or the guide is brought under
      the release-please README-sync so it stops drifting every minor.
      `guides/compatibility-and-deprecations.md:207-212`'s exact-sibling-pin claim is corrected.
      *Accept:* the docs contract is green and no guide asserts a version the tree disproves.
      ⚠ *This is the Phase 125 pin-drift shape. It is not a free one-liner.*

- [x] **DOCS-05**: Code-level documentation does not overpromise, and no config key is accepted
      without effect. `config :mailglass, renderer: [css_inliner: :none]` is validated
      (`config.ex:84-88`) but never read — Premailex always runs (`renderer.ex:73`); it is either
      honored or rejected at validation. `lib/mailglass/outbound.ex`'s moduledoc claim that orphan
      `:queued` Delivery rows are reconcilable via `Events.Reconciler` is corrected (the Reconciler
      queries *events*, `events/reconciler.ex:58`). `docs/api_stability.md:1119`'s injected
      `import Swoosh.Email, except: [new: 0]`, which does not exist in `mailable.ex`, is corrected.
      *Accept:* no accepted config key is inert, and no moduledoc describes behavior absent from code.

- [x] **DOCS-06**: The v2.0 upgrade path is discoverable and honestly labeled. `README.md:280-284`
      links `guides/upgrading-to-v2_0.md` alongside the v1.0/v0.1/Swoosh guides, and
      `CHANGELOG.md:171-173`'s 2.0.0 "⚠ BREAKING CHANGES" block names the actual Postgres schema move
      rather than only a release-tooling note.
      *Accept:* a 1.x adopter reaching the README finds the v2 upgrade guide without prior knowledge.

### One Standing Control (STAND)

The mechanism that makes quiet self-sustaining. **Exactly one new control** — the alert budget says
adding more requires retiring some.

- [x] **STAND-01**: Dependabot produces batched, scheduled, reviewable PRs instead of a serial pileup.
      Each `mix` entry in `.github/dependabot.yml` gains grouping for minor/patch, a weekly schedule,
      and `open-pull-requests-limit: 3`. Majors stay ungrouped so a breaking bump is individually
      reviewable.
      *Accept:* a week's bumps arrive as ≤1 PR per lock directory, and CI is green on them with no
      hand edits.
      *Counter-argument accepted:* a grouped PR that reds blocks every bump inside it and loses
      per-dep bisection. Mitigation is the minor/patch `update-types` split; if a group reds, drop the
      culprit with `ignore` and re-run rather than ungrouping.

---

## Exit criteria

The milestone is complete when all of the following hold. Each is verifiable in under a minute.

1. The `Support Contract Admin` lane reports ≥510 tests, 0 failures.
2. The required `core_deterministic_suite` lane prints `scope: FULL SUITE`.
3. A `workflow_dispatch` of `post-publish-smoke`'s schedule path exits 0 against an `inactive` ledger.
4. Three consecutive pushes to `main` yield a green `release-please` run, with `push` and `schedule`
   agreeing at the same SHA.

5. `mix mailglass.audit --kind hex` passes with the clock faked to 2026-12-01.
6. `grep` for the corrected doc claims returns nothing, and the docs contract test is green.
7. No statement in `STATE.md` is falsified by `gh pr list`, `gh issue list`, or a live suite run.
8. **No diff in this milestone removes or weakens a gate.** Each PR is reviewable as "made a control
   able to reach its own pass state."

---

## Out of Scope

Explicitly excluded, with reasoning, so it is not re-argued mid-milestone.

| Item | Reason |
|---|---|
| Inbound `--seed 0` property flake | Root cause is `shared: true` + `TRUNCATE CASCADE` at 1000 iterations against a pooled sandbox. A proper fix redesigns the property harness's isolation; a cheap fix means lowering `max_runs` or narrowing the generator — **weakening a test to get a green**. Current state is honest and documented (`MAINTAINING.md:431`), and the lane is deliberately non-gating *because* of it. Leave documented. |
| Phase 164/165 controlled-host tests (~30) | Machine-pinned by absolute path and digest, excluded in `test_helper.exs` itself, tied to an archived milestone. Portability is a rewrite of the finalizer's trust model. Leave quarantined. |
| ~30 source-text-grep tests (`File.read!(…) =~ …`) | Defensible drift-guards; the real execution runs in separate CI jobs. Cosmetically unsatisfying, not broken. |
| SEED-006 CI efficiency overhaul | Already deferred out of v2.7. Note GREEN-01 makes CI *slower*; that is accepted. |
| `.planning/` archive prose cleanup | Only 4 loose one-off audit files at root; the rest is past-tense provenance the audit trail depends on. Rewriting historical `==` / "hands-free" claims would falsify history. |
| `.tool-versions` | The pinned 27.3.4.13 / 1.18.4 is the correct CI contract; the local gap is the contributor's. |
| Reference-baseline advance for 2.6.0 | Not needed — `~> 2.0` pins and locked 2.0.0 agree, so `--check-locked` passes. Realized zero-commit reds are third-party drift only. |
| Auto-advancing all four published-baseline records at close-out | The dangerous half is **already fixed**: `check_published_baseline_of_record.sh` is wired into `release_policy_close_out.sh:110` as of #279, so the disagreement now fails loudly *before* the ledger write. What remains is ergonomic. Filed, not fixed. |
| Registering the other 4 scheduled workflows in the evidence sweep | Would move noise, not remove it — the sweep would then red on `provider-live`'s live-provider flakiness. Gate on each being independently green first. |
| Shared `mailglass_test` database between core and admin | Real determinism hazard (reproduced: 4 × `Postgrex.Error 57014` when suites run concurrently), but safe today because `mix ci` is serial. Filed as a todo; de-fanging it is S–M and did not make the timebox. |
| The one `:flaky` tag (`tenancy_test.exs:154`) | Fixable in one line (`Code.ensure_loaded!/1`), and its justification cites an archived path that no longer exists. Genuinely small — **admit it only if the timebox has room after the requirements above.** |
| SEED-008 delivery-absence detection | Real adopter pull from a real incident, but product expansion. Planted, not built. |
| Any product code change | This milestone touches CI, controls, docs, and test wiring only. DOCS-05's `css_inliner` disposition is the single permitted `lib/` change, and it may be resolved by rejecting the key at validation. |

---

## Traceability

Populated 2026-09-17 during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| GREEN-01 | Phase 166 | Complete |
| GREEN-02 | Phase 166 | Complete |
| GREEN-03 | Phase 166 | Complete |
| GREEN-04 | Phase 166 | Complete |
| GREEN-05 | Phase 166 | Implemented, evidence pending |
| CTRL-01 | Phase 166 | Complete |
| CTRL-02 | Phase 166 | Implemented, evidence pending |
| CTRL-03 | Phase 166 | Implemented, evidence pending |
| CTRL-04 | Phase 166 | Complete |
| CTRL-05 | Phase 166 | Implemented, evidence pending |
| DOCS-01 | Phase 167 | Complete |
| DOCS-02 | Phase 167 | Complete |
| DOCS-03 | Phase 167 | Complete |
| DOCS-04 | Phase 167 | Complete |
| DOCS-05 | Phase 167 | Complete |
| DOCS-06 | Phase 167 | Complete |
| STAND-01 | Phase 167 | Complete |

**Coverage:**

- v2.8 requirements: 17 total
- Mapped to phases: 17 ✓ (Phase 166: 10 — GREEN-01..05, CTRL-01..05; Phase 167: 7 — DOCS-01..06, STAND-01)
- Unmapped: 0
- Duplicated across phases: 0

Roadmap: `.planning/ROADMAP.md` (created 2026-09-17).

---
*Requirements defined: 2026-09-17*
