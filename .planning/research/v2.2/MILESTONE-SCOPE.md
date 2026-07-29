# v2.2 Scope: CI Signal Integrity & Supply-Chain Hygiene

**Status:** OPENED as milestone v2.2 — research complete, corrections applied
**Drafted:** 2026-07-28
**Corrected:** 2026-07-28 after four-agent research (see `SUMMARY.md`)
**Phases:** 141-144 (v2.1 ended at 140)

> **Read the corrections before planning.** Research contradicted this document
> in three places, and each correction changes what the work actually is:
> `MAINTAINING.md` **exists** (TRUTH-07), CONFORM-02's gate is **already
> shipped**, and a **hidden third gating tier** (TRUTH-09) is the real mechanism
> behind the release failures. Corrected items are marked inline.

---

## Why this milestone

On 2026-07-28 a single character-class typo in branch protection was found to
have silently held the repository for 24 days. Live protection required the
status context `guard-release-trigger` (the job **id**); the workflow reports
`Guard Release Trigger` (the job **display name**). GitHub matches on the
reported name, so the required context was never reported by anything and every
PR sat permanently `BLOCKED`.

Consequences, none of which were visible from the repo's own green checks:

1. **22 PRs blocked**, including a release PR with auto-merge enabled since 2026-07-04.
2. **Four HIGH-severity CVEs unpatched**, because the dependabot PRs carrying the
   fixes could not merge.
3. **`branch-protection-drift.yml` reported SUCCESS the whole time** — it guards
   its own comparison behind `if: pat_present == 'true'`, so with no PAT it skips
   the check and still posts green.

The unifying defect is that **several signals were not telling the truth**, and
the check built to catch exactly this was itself blind.

Maintenance and trust-restoration only. Explicitly **not** product expansion,
redesign, or a release-cut milestone.

---

## Already delivered on 2026-07-28 (do NOT re-plan)

Shipped to `main` and released as 2.1.3 / 2.1.3 / 2.1.1:

- **Branch protection corrected** to `{CI Green, Guard Release Trigger}` via the
  repo's own `scripts/setup_branch_protection.sh`; zero drift against
  `--print-expected-json`.
- **Nine advisories patched** (four HIGH): phoenix, hpax, plug, postgrex, swoosh
  (PR #134) and cowboy, cowlib (PR #139). Note `hpax` was transitive —
  **dependabot never files those**, which is why it accumulated.
- **All 7 admin design-system conformance gates green** (PR #136), including two
  heroicons (`hero-check`, `hero-information-circle`) that were rendering
  invisible with nothing catching it.
- **Dialyzer clean** — `Operator.Deliveries.list_providers/2` (PR #136).
- **Stale `mailglass_admin` publish allowlist fixed** (PR #134) — the actual
  cause of the 2.1.0 publish failure.
- **Citext probe made honest** (PR #137) — it rescued every `Postgrex.Error`,
  retried, and reported "citext probe exhausted" for unrelated faults. Now only
  the poisoned-OID surface retries; everything else re-raises intact.
- **`migration_test.exs` baseline restoration fixed** (PR #137) — restoration was
  gated on a recorded migration version, so a dropped-but-still-recorded schema
  skipped restore entirely.

---

## Remaining scope

### Phase 141 — Supply-chain remediation (VULN)

- ~~**VULN-01**: resolve the outstanding `mix hex.audit` advisories.~~ **DONE**
- **VULN-02**: finish dispositioning the dependency backlog. 13 dependabot PRs
  were left with auto-merge enabled on 2026-07-28; confirm they landed or were
  closed with reason.
- **VULN-03**: promote the Hex Audit lane from advisory to gating (add to
  `ci_green.needs` + `Mailglass.CILanes.required_lanes()`), so a new HIGH
  advisory blocks merge instead of accumulating.

  **Must wire allowlist logic into the CI-side lane first** *(research,
  2026-07-28)*. The `hex_audit` job in `ci.yml` runs bare `mix hex.audit` with
  **zero allowlist logic** — only `publish.check`'s `@accepted_advisories` honors
  the cowlib exceptions, and only at the publish gate. Promoting the lane to
  `ci_green.needs` without wiring the same allowlist in will immediately
  red-block every PR on already-accepted advisories.

  **Also decide scope:** this item names only "Hex Audit," but `Deps Audit`
  (`mix_audit`) is the lane that actually covers **transitive** dependencies —
  i.e. the `hpax` case that motivated VULN-04. Decide explicitly in phase 141
  whether one or both are promoted.
- **VULN-04**: a documented triage cadence that **covers transitive
  dependencies**. `hpax` (HIGH) was never going to be filed by dependabot; it was
  found only by reading audit output directly.

### Phase 142 — Test-harness truth (HARNESS)

See **[SEED-007](../../seeds/SEED-007-sandbox-ownership-leak.md)** for the full
evidence, call-site map, and ruled-out list.

- **HARNESS-01**: fix the Ecto Sandbox ownership leak — 194 of 242 core-suite
  failures are `{:badmatch, :already_shared}` from `Sandbox.start_owner!/2`.
- **HARNESS-02**: Core Full Suite green across all four matrix legs.
- **HARNESS-03**: confirm the recovered tests genuinely execute and assert —
  not skipped, excluded, or tagged away to manufacture green.
- **HARNESS-04**: decide whether Core Full Suite should become release-gating.
  It is **not** today: it lives in `advisory-matrix.yml`, and `gate-ci-green`
  inspects `ci.yml` only. A full-suite regression therefore cannot block a
  publish — arguably the more interesting gap.

### Phase 143 — Design-system conformance (CONFORM)

- ~~**CONFORM-01**: vendor the two missing heroicons.~~ **DONE**
- ~~**CONFORM-03**: clear the remaining conformance gates.~~ **DONE**
- ~~**CONFORM-02**: fail the build when a `<.icon name="hero-X">` has no vendored
  SVG.~~ **LARGELY DONE — verify, do not rebuild.** *(corrected 2026-07-28 by
  research)* `ICON-EXISTS-GATE` already ships at
  `mailglass_admin/scripts/check-conformance.sh:148-179`, added in the same PR
  #136 this document already credits for the icon fixes. What remains is
  **confirming coverage**, specifically the dynamic call sites in
  `components.ex` (`name={@icon}`, `name={option.icon}`,
  `name={stat_severity_icon(@severity)}`) that a literal-string grep cannot see.
- **CONFORM-04**: rename the lane. It is called "Credo Strict" but credo passes;
  it actually dies in `mailglass_admin/scripts/check-conformance.sh`. The
  misleading name is why nobody looked at it for weeks.

  **Coupled to TRUTH-07/TRUTH-09 — must land together.** Renaming a job changes
  its reported status-check name, and `gate-ci-green` matches lanes **by name**.
  Because this lane sits in the hidden third tier (TRUTH-09), renaming it without
  first deciding its classification either preserves the accidental-gating bug
  under a new name, or silently demotes a de-facto-gating lane to advisory as an
  unreviewed side effect.

### Phase 144 — Lane truth & drift-proofing (TRUTH)

- ~~**TRUTH-01**: Dialyzer clean.~~ **DONE**
- **TRUTH-02**: `branch-protection-drift.yml` must not report SUCCESS while
  skipping its comparison — a skipped check reports neutral/failure, never green.
- **TRUTH-03**: verify live protection against
  `scripts/setup_branch_protection.sh --print-expected-json` on a schedule, and
  regression-guard the drift that caused this milestone.
- **TRUTH-04**: fix or formally accept the release-trigger anti-recursion gap.
  Bot-auto-merged release PRs do not fire release-please's `push` trigger, so
  tagging waits on an hourly cron. **This cost ~30 minutes three separate times
  on 2026-07-28.**
- **TRUTH-05**: every advisory lane gets a recorded disposition — promote,
  keep-with-reason, or retire. No lane sits red indefinitely undecided.
- **TRUTH-06**: `repo-hygiene` must distinguish "genuinely blocked" from "cannot
  check" (its `branch_protection` sub-check 403s and reports as drift).
- **TRUTH-07** *(new; corrected 2026-07-28 by research)*: reconcile the **three**
  definitions of "advisory". `test/support/ci_lanes.ex` lists ten advisory lanes;
  `gate-ci-green` in `publish-hex.yml` hardcodes two plus a `/ Advisory (/`
  regex; and `MAINTAINING.md:152-191` lists eleven. All three disagree on
  membership.

  **Correction:** the earlier claim that `MAINTAINING.md` "has never existed in
  this repository" was **wrong**. The file exists (370 lines at the repo root,
  since commit `5f8d7f4a`) and `ci_lanes.ex`'s docstring cites it *accurately*.
  It is **stale**, not phantom. Fittingly, this milestone's own scope document
  contained an untrue claim about a signal — the same class of defect it exists
  to fix.

- **TRUTH-09** *(new, from research)*: classify the **hidden third gating tier**.
  Nine-plus `ci.yml` jobs — Credo Strict, Dialyzer, Hex Audit, Format Check,
  Compile Warnings as Errors, Docs Warnings as Errors, Mix Task Tests, Inbound
  Test, Inbound Compile No Optional Deps, Installer Golden Gate, Trust Lane Clean
  Baseline — are in **neither** `ci_green.needs` (merge-gating) **nor**
  `gate-ci-green`'s advisory list. They therefore silently block **Hex publish**
  while never blocking a **PR merge**, and nobody decided that on purpose. This
  is the verified mechanism behind the 2.1.1 gate failure that SEED-007 cites,
  and it means "Credo Strict" is de-facto release-gating today despite being
  declared advisory in `ci_lanes.ex` — which makes CONFORM-04's rename a live
  hazard rather than cosmetics.
- **TRUTH-08** *(new)*: the publish fan-out races itself. Two `publish-hex` runs
  fire (one per tag) and race on `publish-core`; one wins, the other reports
  failure on an already-published package. Harmless but it makes a successful
  release look failed.

---

## Non-goals

- No product features, no redesign, no new adopter-facing surface.
- Not a release-cut milestone.
- Not a CI topology rewrite — the lane structure is sound; the signals were not.

## Sequencing note

**[SEED-006](../../seeds/SEED-006-ci-cd-efficiency-audit.md)** (CI/CD efficiency
audit) is deliberately sequenced *after* this milestone. Optimizing a pipeline
whose greens are not trustworthy just makes it lie faster.
