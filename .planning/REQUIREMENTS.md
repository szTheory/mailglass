# Requirements: mailglass — v2.2 CI Signal Integrity & Supply-Chain Hygiene

> **Milestone v2.2 (maintenance / trust-restoration).** Make every green check mean what it says, and close
> the supply-chain gap that let four HIGH-severity advisories sit unpatched for 24 days behind a
> branch-protection typo that no signal reported.
>
> Defined 2026-07-28 from `.planning/research/v2.2/` — four parallel research agents (stack, features,
> architecture, pitfalls) plus a synthesis pass, all grounded in this repository's own workflow YAML,
> `test/support/ci_lanes.ex`, `scripts/setup_branch_protection.sh`, and `MAINTAINING.md`.
>
> This milestone is intentionally **not** a product-expansion, redesign, release-cut, or CI-topology-rewrite
> milestone. The lane structure is sound; the signals were not.

---

## Framing: what research changed

Research contradicted the original scope document in three places. Each correction changes what the work is,
and each is already applied to `.planning/research/v2.2/MILESTONE-SCOPE.md`:

| Original claim | Corrected fact |
|---|---|
| `MAINTAINING.md` "has never existed in this repository" | It **exists** — 370 lines at the repo root since `5f8d7f4a`, and `ci_lanes.ex`'s docstring cites it **accurately**. It is *stale*, not phantom. So there are **three** disagreeing advisory registries, not two. |
| CONFORM-02: build a gate that fails on missing vendored icons | **Already shipped.** `ICON-EXISTS-GATE` lives at `mailglass_admin/scripts/check-conformance.sh:148-179`, added in the same PR #136 the scope doc credits for the icon fixes. The remaining work is *verifying coverage*. |
| Core Full Suite failures were blocking releases | They were not — but a **hidden third gating tier** was. 9+ `ci.yml` jobs sit in neither `ci_green.needs` nor `gate-ci-green`'s advisory list, silently blocking Hex publish while never blocking a PR merge. |

**The load-bearing finding is the hidden third tier.** It is the verified mechanism behind the 2.1.1 gate
failure, and it means "Credo Strict" is de-facto release-gating today despite being declared advisory.

**Everything this milestone needs already exists in the repo.** `mix_audit ~> 2.1`, `mix hex.audit`, an
OSV-staleness gate, a 3-directory `dependabot.yml`, the `ci_green` fan-in, `Mailglass.CILanes`, and
`gate-self-test.yml`'s deliberate-failure-probe pattern are all shipped. **No new dependencies.**

---

## Milestone v2.2 Requirements

### VULN — Supply-chain remediation

- [ ] **VULN-02**: Every dependency PR left with auto-merge enabled on 2026-07-28 is confirmed either merged
  or closed with a recorded reason. No PR is left in an indeterminate state.

- [x] **VULN-05**: The CI-side audit lanes honor the same accepted-advisory allowlist that
  `publish.check`'s `@accepted_advisories` uses, read from **one** source rather than duplicated. Today
  `ci.yml`'s `hex_audit` runs bare `mix hex.audit` with zero allowlist logic. *(Hard precondition for
  VULN-03 — promoting the lane without this reds every PR on the already-accepted cowlib advisories.)*

- [ ] **VULN-03**: **Both** the Hex Audit and Deps Audit lanes are merge-gating — present in
  `ci_green.needs` and in `Mailglass.CILanes.required_lanes()`, with the parity-drift test updated — so a
  newly-published HIGH advisory blocks merge instead of accumulating. *(Deps Audit / `mix_audit` is the lane
  that covers transitive dependencies, i.e. the `hpax` case; Hex Audit alone would not close it.)*

- [x] **VULN-06**: Each allowlisted advisory carries a recorded reason and a re-check date, and the lane
  surfaces an entry whose upstream fix has landed, so an exception cannot silently become permanent.

- [ ] **VULN-04**: A documented triage cadence exists that explicitly covers **transitive** dependencies,
  naming who checks what, how often, and the response expectation by severity. It states plainly that
  Dependabot cannot auto-file a Hex transitive fix requiring a parent bump — documented upstream behavior,
  not a repo defect — and that reading audit output directly is therefore the only path for that class.

### HARNESS — Test-harness truth

- [ ] **HARNESS-01**: The Ecto Sandbox ownership leak is fixed, with the **mechanism empirically confirmed
  before the fix is written** rather than inferred. 194 of 242 core-suite failures are
  `{:badmatch, :already_shared}` from `Sandbox.start_owner!/2`. Leading candidates, all to be verified:
  `Mailglass.DataCase` (the dominant shared-mode acquisition site, 35 files), `mailer_case.ex:158` and
  `:248` (raw `Sandbox.mode(repo, {:shared, self()})` calls outside the `start_owner!`/`stop_owner` pair,
  whose `on_exit` never reverts to `:manual`), and
  `properties/webhook_idempotency_convergence_test.exs`.

- [ ] **HARNESS-02**: Core Full Suite passes across all four matrix legs (Elixir 1.18/OTP 27 and 1.19/OTP 28,
  each × `public` and `mailglass` schema).

- [ ] **HARNESS-03**: The recovered tests are proven to genuinely execute and assert — not skipped, excluded,
  or tagged away to manufacture green. Proof is mechanical, not narrative: a test-count floor that fails if
  the executed count drops, plus a deliberate-failure probe following the existing `gate-self-test.yml`
  pattern pointed at Core Full Suite.

- [ ] **HARNESS-04**: `gate-ci-green` inspects `advisory-matrix.yml` in addition to `ci.yml`, so a Core Full
  Suite regression blocks a Hex publish. *(Sequenced strictly after HARNESS-01..03 — gating a red lane
  deadlocks releases.)*

### CONFORM — Design-system conformance

- [ ] **CONFORM-02**: The existing `ICON-EXISTS-GATE` is **verified** to cover the whole invisible-icon
  class, not only literal-string call sites. Coverage of `components.ex`'s dynamic sites (`name={@icon}`,
  `name={option.icon}`, `name={stat_severity_icon(@severity)}`) is either proven or explicitly documented as
  a bounded, accepted gap with its reasoning. Rebuilding the gate is out of scope — it already ships.

- [x] **CONFORM-04**: The lane called "Credo Strict" is renamed to reflect what it actually runs (Credo plus
  the admin design-system conformance shell gates). **Lands together with TRUTH-07 and TRUTH-09**, never
  before: `gate-ci-green` matches lanes **by name**, and this lane sits in the hidden third tier, so a
  rename in isolation either preserves the accidental-gating bug under a new name or silently demotes a
  de-facto-gating lane.

### TRUTH — Lane truth & drift-proofing

- [x] **TRUTH-09**: The hidden third gating tier is eliminated. Every `ci.yml` job is explicitly classified
  into exactly one named bucket — **merge-gating (required)**, **publish-gating**, or **advisory** for
  check lanes, plus a **structural** bucket for the two jobs that are not check lanes (`changes` /
  `Detect Non-Doc Changes` and `ci_green` / `CI Green`) — and no job may sit in none of them and thereby
  block publish by accident. The publish-gating bucket now carries Credo Strict, Dialyzer, Hex Audit,
  Format Check, Compile Warnings as Errors, Docs Warnings as Errors, Mix Task Tests, Inbound Test, Inbound
  Compile No Optional Deps, Installer Golden Gate, Trust Lane Clean Baseline, Branch Protection Advisory,
  and the new Design System Conformance lane, each with a recorded disposition. *(Amended from the
  original two-bucket wording — the original text read "merge-gating or advisory" for every job. A
  two-bucket model would either let a Hex publish proceed on red Dialyzer / red trust-evidence lanes or
  promote them to merge-gating, contradicting D-04 for `Trust Lane Clean Baseline` and lengthening every
  PR's critical path. The named publish-gating bucket preserves today's effective publish posture
  byte-for-byte. See `.planning/phases/141-lane-truth-foundation/141-CONTEXT.md` D-02/D-03.)*

- [x] **TRUTH-07**: The three disagreeing advisory registries are reconciled to **one** authoritative source,
  with the others generated from or verified against it by a test that fails on drift. `MAINTAINING.md` is
  refreshed as part of this — it is stale, and reconciliation that leaves it stale is incomplete.

- [ ] **TRUTH-02**: A check that cannot do its work never reports success. Both instances are fixed:
  `branch-protection-drift.yml`'s `reassert-protection` job and `ci.yml`'s "Branch Protection Advisory", which
  share the identical `if: pat_present == 'true'`-skip-but-still-green shape. Since GitHub Actions has no
  native job-level neutral conclusion, the repo's own proven `if: always()` + explicit-failure idiom is the
  expected mechanism.

- [ ] **TRUTH-03**: Live branch protection is verified against `scripts/setup_branch_protection.sh
  --print-expected-json` on a schedule, and a regression guard specifically catches the job-`id`-vs-job-`name`
  context mismatch that caused this milestone.

- [ ] **TRUTH-06**: `repo-hygiene` distinguishes "genuinely blocked" from "cannot check". Its
  `branch_protection` sub-check currently 403s and reports the failure as drift.

- [ ] **TRUTH-08**: The publish fan-out no longer races itself. `publish-hex.yml`'s
  `concurrency.group` is ref-scoped (`publish-hex-${{ github.ref }}`) while release-please's linked-versions
  plugin fires two releases on two different tags, so the runs never serialize. `post-publish-smoke.yml`
  carries the identical pattern and is fixed alongside it. A successful release must not report failure.

- [x] **TRUTH-05**: Every lane carries a recorded disposition — promote, keep-with-reason, or retire. No lane
  sits red or unclassified indefinitely. *(Follows TRUTH-09/07: dispositions are recorded against the
  reconciled set, not the ambiguous one.)*

- [ ] **TRUTH-04**: The release-trigger anti-recursion gap is either fixed or formally accepted with its cost
  recorded. Bot-auto-merged release PRs do not fire release-please's `push` trigger, so tagging waits on an
  hourly cron — this cost ~30 minutes on three separate occasions on 2026-07-28.

### HIST — Planning-history integrity

- [x] **HIST-01**: v2.0's phase artifacts (132-137) are restored to `.planning/milestones/v2.0-phases/`, and
  the `gsd-tools query phases.clear` defect that deleted them without writing an archive is recorded. The
  same defect deleted v2.1's phases 138-140 during this milestone's own opening; those were caught and
  restored in commit `70099869`.

---

## Future Requirements (deferred, not this milestone)

- **CI/CD efficiency and contributor feedback latency** — wall-clock, runner cost, matrix breadth, and
  caching. Tracked as `SEED-006`, deliberately sequenced **after** v2.2. Optimizing a pipeline whose greens
  are not trustworthy just makes it lie faster.

- **Ecosystem integrations** — `SEED-003`, dormant.
- **Whole-suite no-search-path fixture cleanup** — carried from v2.1.
- **`remove-cowlib-advisory-allowlist-when-upstream-fixes`** — pending an external upstream fix; VULN-06's
  re-check mechanism should surface it automatically once the fix lands.

## Out of Scope (explicit exclusions)

- **Product features, new providers, transports, or adopter-facing surface.** This is maintenance.
- **Admin UI redesign** — no token, component, motion, layout, or brand work.
- **A CI topology rewrite.** The lane structure is sound; only the honesty of its signals changes. Splitting,
  merging, or restructuring workflows beyond what a named requirement demands is excluded.

- **A release cut.** v2.2 ships no Hex release; 2.1.3 / 2.1.3 / 2.1.1 stand.
- **Re-planning the 2026-07-28 remediation** — branch protection correction, the nine advisory patches, the
  seven conformance gates, Dialyzer, the admin publish allowlist, the honest citext probe, and the migration
  baseline restoration are shipped history.

- **Rebuilding `ICON-EXISTS-GATE`** — it exists; CONFORM-02 verifies it.
- **Making Core Full Suite merge-gating** by moving it into `ci.yml` — rejected in favor of HARNESS-04's
  publish-gating approach, because adding four matrix legs to every PR is precisely the wall-clock cost
  SEED-006 exists to address.

---

## Traceability

**Roadmap note:** phase assignment is regrouped by dependency, not by requirement-category prefix — see
`ROADMAP.md` and `STATE.md` "v2.2 Milestone Intent" for the rationale (VULN-05→VULN-03 precondition;
CONFORM-04 must land with TRUTH-07/TRUTH-09; TRUTH-07/09/05 are load-bearing and sequenced early).

| Requirement | Phase | Status |
|---|---|---|
| TRUTH-09 | Phase 141 | Complete |
| TRUTH-07 | Phase 141 | Complete |
| TRUTH-05 | Phase 141 | Complete |
| CONFORM-04 | Phase 141 | Complete |
| HIST-01 | Phase 141 | Complete |
| VULN-05 | Phase 142 | Complete |
| VULN-03 | Phase 142 | Pending |
| VULN-06 | Phase 142 | Complete |
| VULN-02 | Phase 142 | Pending |
| VULN-04 | Phase 142 | Pending |
| HARNESS-01 | Phase 143 | Pending |
| HARNESS-02 | Phase 143 | Pending |
| HARNESS-03 | Phase 143 | Pending |
| HARNESS-04 | Phase 143 | Pending |
| CONFORM-02 | Phase 144 | Pending |
| TRUTH-02 | Phase 144 | Pending |
| TRUTH-03 | Phase 144 | Pending |
| TRUTH-04 | Phase 144 | Pending |
| TRUTH-06 | Phase 144 | Pending |
| TRUTH-08 | Phase 144 | Pending |

**Coverage: 20/20 requirements mapped (100%).** No orphans, no duplicates. (Note: the roadmapping brief
referenced "21 requirements"; a direct scan of this file's checklist found 20 unique REQ-IDs across
VULN/HARNESS/CONFORM/TRUTH/HIST — all 20 are mapped above.)
