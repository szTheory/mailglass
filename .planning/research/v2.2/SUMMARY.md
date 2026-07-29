# Project Research Summary

**Project:** mailglass v2.2 "CI Signal Integrity & Supply-Chain Hygiene"
**Domain:** CI/CD signal integrity + supply-chain hygiene + Ecto test-harness correctness (maintenance/trust-restoration milestone — no product surface)
**Researched:** 2026-07-28
**Confidence:** HIGH (nearly every claim is cited to a file/line read directly in this worktree; the few web-sourced ecosystem claims are flagged MEDIUM below)

## Executive Summary

This milestone exists because a job-id-vs-display-name typo in branch protection silently blocked 22 PRs and 4 unpatched HIGH CVEs for 24 days, while the guard built to catch exactly that drift (`branch-protection-drift.yml`) itself skipped silently and reported SUCCESS. Fittingly, research corrected the milestone's own scope doc in four places (see below) — the same "signal that lies" failure mode this milestone exists to close nearly re-created itself inside the planning artifact. Every tool needed already exists in the repo (`mix_audit`, `hex.audit`, OSV staleness checks, `Mailglass.CILanes`, the `ci_green` fan-in aggregator, REST-based branch-protection scripts); this is wiring and honesty work on existing machinery, not a tool-adoption or topology-rewrite milestone.

The core structural finding is a **hidden third gating tier**: 9+ `ci.yml` jobs (Format Check, Compile Warnings as Errors, Credo Strict, Dialyzer, Docs Warnings as Errors, Hex Audit, Mix Task Tests, Inbound Test, Inbound Compile No Optional Deps, Installer Golden Gate, Trust Lane Clean Baseline) are neither in `ci_green.needs` (so they never block a PR merge) nor recognized by `gate-ci-green`'s advisory-name matcher (so they silently DO block Hex publish if they fail). "Credo Strict" is one of them — this is the verified mechanism behind the 2.1.1 gate failure that SEED-007 originally misattributed to the sandbox leak. Reconciling this (TRUTH-07) is the load-bearing fix the rest of the milestone hangs off; VULN-03's Hex Audit promotion and CONFORM-04's lane rename are both special cases of the same underlying reconciliation and should be sequenced to reuse it, not solved independently.

The primary risk is repeating the meta-pitfall inside the fix itself: every new/edited guard in phases 141-144 is itself a signal that can lie the same way. Two items need special care — VULN-03 must not gate on Hex Audit without wiring the existing `@accepted_advisories` allowlist into the CI-side lane, or it reds every PR on the already-accepted cowlib advisories immediately; and HARNESS-01 (the sandbox leak) has a plausible mechanism hypothesis, not a confirmed root cause, and must not be "fixed" by tagging tests away, going blanket `async: false`, or otherwise manufacturing green without explaining the mechanism.

## Corrections to the Original Scope Doc — Surface These Prominently

`MILESTONE-SCOPE.md` (the pre-research scope document) contains four factual errors that research corrected. Requirements and roadmap work MUST use the corrected facts, not the scope doc's claims, or they will re-plan already-delivered work or plan against false premises.

1. **`MAINTAINING.md` DOES exist** — 370 lines, repo root, since commit `5f8d7f4a`, one of the earliest commits in the repo's history. `ci_lanes.ex`'s docstring citation to `MAINTAINING.md:152-191` is accurate and real (that range genuinely contains a required/advisory split). The scope doc's TRUTH-07 claim ("that file has never existed in this repository") is **wrong** — the file is merely **stale**: its 5-required-lane list (lines 154-158) is current and correct, but its 11-lane advisory list (lines 180-191) predates `Credo Strict`, `Dialyzer`, `Docs Warnings as Errors`, `Hex Audit`, `Deps Audit Advisory`, `Installer Golden Gate`, and `Trust Lane Clean Baseline` all being added to `ci.yml`. **Correction to TRUTH-07's framing:** there are not two disagreeing definitions of "advisory" to reconcile — there are **three**: `CILanes.ex` (10 lanes), `gate-ci-green`'s hardcoded JS arrays (2 explicit + regex), and `MAINTAINING.md`'s stale prose (11 lanes, none of the three match).

2. **CONFORM-02 appears already delivered.** `mailglass_admin/scripts/check-conformance.sh:148-179` already contains `ICON-EXISTS-GATE` — greps every `hero-[a-z0-9-]+` call site under `mailglass_admin/lib`, diffs against `heroicons-inline.js`'s vendored keys, fails on any mismatch, and has a fail-loud vacuity guard against a zero-usage false pass. `git log -S "ICON-EXISTS-GATE"` shows it landed in `31588bb4` — the **same PR #136** the scope doc credits with fixing the two known invisible icons. What is NOT true is that this gate blocks anything: it lives inside `credo_strict`, which is not in `ci_green.needs`, so a red `ICON-EXISTS-GATE` never blocks a PR merge today. **Phase 143 should VERIFY/confirm coverage** (the gate is complete for literal/branch-literal icon names; the genuine remaining gap is dynamically-constructed names — `<.icon name={@icon}>`, `name={option.icon}`, `name={stat_severity_icon(@severity)}` — which a pure regex scan cannot see) rather than rebuild the mechanism from scratch.

3. **A hidden third gating tier exists**, silently release-blocking without merge-blocking. `gate-ci-green` (in `publish-hex.yml`) computes blocking failures as "not one of 5 `REQUIRED_LANES`, not matched by `ADVISORY_LANES`/the `/ Advisory \(/` regex" → block. 9+ jobs fall into this undocumented catch-all, including **Credo Strict**, which means it is de-facto release-gating *today* despite `CILanes.ex` declaring it advisory. This is the verified, concrete mechanism behind SEED-007's corrected evidence ("the 2.1.1 gate failure named `Credo Strict` and `Dialyzer`... never mentioned Core Full Suite").

4. **HARNESS-01's call-site map (inherited from SEED-007) was incomplete.** Exhaustive grep of every `Sandbox.mode`/`start_owner!`/`checkout`/`allow` call site shows `Mailglass.DataCase` (35 files, ~5x the surface SEED-007 cited) is the dominant shared-mode acquisition site — not `MailerCase` (7 files) as the seed emphasized. Additionally, `test/mailglass/properties/webhook_idempotency_convergence_test.exs:53` is a **4th explicit-shared-mode site** the seed omitted entirely (`start_owner!(shared: true, ownership_timeout: 10*60_000)` — architecturally the highest-risk single site in the map: a 10-minute-held shared owner running 1000 property iterations, directly adjacent to three `:auto`-mode-switching sibling files). Investigation budget for phase 142 should weight `DataCase`'s 35 files and the `properties/` directory's 4-file cluster accordingly, not `MailerCase`'s 7.

## Key Findings

### Recommended Stack

No new dependency, tool, or GitHub Action is needed anywhere in this milestone (`mix_audit ~> 2.1`, `mix hex.audit`, the OSV staleness check in `mailglass.publish.check.ex`, `dependabot.yml`'s 4-directory coverage, `Mailglass.CILanes`, and the hand-rolled `ci_green` aggregator are all already shipped and correctly chosen). Any recommendation suggesting a new dependency should be treated as a red flag against the "no CI topology rewrite" lock. All changes are: promote a lane's classification, add a step to an existing job, widen a `concurrency:` group, or fix a call site.

**Core mechanisms (already present — confirm, don't replace):**
- `mix_audit ~> 2.1` — scans fully-resolved `mix.lock` (direct + transitive) against the OSV-backed `elixir-security-advisories` DB; already found `hpax` correctly, the gap was gating not detection.
- `mix hex.audit` — flags retired packages, complementary (not redundant) to `mix_audit`.
- OSV.dev staleness re-check (`mailglass.publish.check.ex:1218-1290`) — re-queries every `@accepted_advisories` allowlist entry, fails open on OSV outage.
- `Ecto.Adapters.SQL.Sandbox.mode/2` raw calls (as opposed to `start_owner!`/`stop_owner`) are the confirmed leak surface class — HexDocs-documented `:already_shared` trigger condition ("another process set `{:shared, _}` and is still alive").

### Expected Features / Scope

Framed as trust-restoration, not product expansion — "table stakes" means what a well-run single-maintainer Elixir/Hex OSS repo needs, not adopter-facing features.

**Must land (table stakes, low-risk, unlocks everything else):**
- VULN-04 documented triage cadence (incl. transitive-dependency sweep) — defines the vocabulary VULN-03 needs; should conceptually precede VULN-03 even if phases execute in written order.
- TRUTH-07 reconcile the three advisory-lane registries into one.
- CONFORM-04 rename the misleading "Credo Strict" lane — should land together with or immediately before/after TRUTH-07, since the rename is the exact case that exposes the classification divergence.
- TRUTH-02 fix "skip reports green" (lives in `ci.yml`'s `branch_protection_advisory` job, not literally in `branch-protection-drift.yml` — that file was split via `b99930ea` into a PAT-gated apply-only workflow with no comparison logic at all; route the fix to the actual culprit job).
- TRUTH-06 repo-hygiene blocked-vs-cannot-check distinction — same fix pattern as TRUTH-02.

**Requires real design surface (do after the above):**
- VULN-03 promote Hex Audit to gating, WITH the shared allowlist wired into the CI-side lane — the bare `mix hex.audit` job today has zero allowlist logic; gating it as-is reds immediately on the already-accepted cowlib advisories.
- CONFORM-02 verification pass + explicit scoping decision for dynamic icon-name call sites (not a rebuild).
- TRUTH-03 scheduled drift verification + regression guard, depends on TRUTH-02 landing first.
- TRUTH-05 every advisory lane gets a recorded disposition, depends on TRUTH-07's reconciliation table (mostly falls out mechanically once that table exists).

**Genuinely differentiated, higher complexity — scope carefully:**
- OSV staleness re-check for allowlisted advisories (differentiator vs. peer Elixir OSS repos — only Ash runs any in-CI security scanning at all among 10 surveyed).
- Dated/max-age enforcement on allowlist entries.

**Explicitly not this milestone (anti-features):**
- Auto-remediation/auto-merge policy changes for dependency PRs (sequencing violation — needs signal-integrity guarantees this milestone is *building*, not consuming before they exist).
- Any wall-clock/cost/matrix-shrinking change — that's SEED-006, locked to run *after* this milestone.
- A generalized asset-existence framework for the icon gate (over-engineering; the existing grep-and-diff shell-gate pattern, matching this repo's own `PRIMITIVE-DRIFT-GATE`/`FORM-DRIFT-GATE`, is sufficient).
- Job-graph/trigger topology restructuring, with one narrow, explicitly-flagged exception: splitting `credo_strict` into two jobs (Credo vs. conformance) is defensible as a rename + one job-boundary split, not a redesign — flag as an explicit phase-143 decision point, not an assumption.

### Architecture Approach

This is an integration map, not a redesign — every change is confined to editing existing YAML/Elixir files in place (adjust a `needs:` array, widen a `concurrency:` group, add a step, fix a call site). Suggested build order across phases 141-144, respecting three hard dependencies:

**Wave 1 (fully independent, parallelizable):** VULN-02 (dependabot backlog disposition), VULN-03 (Hex Audit promotion — self-contained file list), VULN-04 (triage cadence doc), TRUTH-08 (publish fan-out race — one-line concurrency fix), TRUTH-02 (skip≠green, routed to the correct job), TRUTH-06 (repo-hygiene 403-vs-drift), CONFORM-02 verification (near-zero remaining work).

**Wave 2 (mechanically independent but conceptually builds on Wave 1's classification decisions):** TRUTH-07 (reconcile the three registries — natural home for generalizing VULN-03's pattern, decide the 9-job hidden-third-tier fate, write a new publish-hex.yml-vs-CILanes meta-test, correct `MAINTAINING.md:152-191`), CONFORM-04 (rename + classification pairing — best sequenced alongside or after TRUTH-07 since it needs the same "what does gate-ci-green think this lane is" decision), TRUTH-05 (falls out of TRUTH-07's reconciliation table).

**Wave 3 (hard-sequenced, cannot parallelize internally):** HARNESS-01 (root-cause + fix the sandbox leak, using the corrected call-site map) → HARNESS-02 (green across all 4 matrix legs, repeatedly) → HARNESS-03 (confirm recovery is genuine, not manufactured) → HARNESS-04 (decide + implement release-gating for Core Full Suite; recommended approach is "Option B" — teach `gate-ci-green` to additionally inspect `advisory-matrix.yml`'s runs, rather than moving the full suite into `ci.yml` as a required PR lane, which would make every PR merge block on a currently-red 1401-test suite before HARNESS-01/02 land).

Net: the milestone's phase numbering (141/VULN, 142/HARNESS, 143/CONFORM, 144/TRUTH) is not itself a strict build order — VULN and CONFORM items are Wave-1/near-Wave-1 work that can execute alongside early HARNESS investigation; only HARNESS's internal 01→02→03→04 chain and TRUTH's dependency on decisions made throughout are hard-ordered.

### Critical Pitfalls (top 5 of 12 documented)

1. **Vacuous/self-blinding guards** — a conditional guard (`if: pat_present == 'true'`) with no failure-path else branch renders "skip" as "pass." This is the literal, already-shipped-this-milestone originating defect. Avoid: every conditional guard needs an explicit non-green else branch; prefer failing loud over silently skipping.
2. **Manufactured green** — the fastest way to make Core Full Suite green is to tag failing tests away, not fix them. Avoid via concrete anti-vacuity checks for HARNESS-03: test-count floor (`>= 1401`), skip/exclude diff gate with mandatory `# Reason:` comments, failure-signature reconciliation (the `:already_shared` count must go to exactly zero, not just "fewer failures"), and a deliberate-failure probe against `Core Full Suite Advisory` specifically (mirroring the repo's own `gate-self-test.yml` pattern).
3. **Advisory→gating promotion creates a release deadlock** — flipping VULN-03's boolean without an escape valve (severity-gated blocking + a time-boxed expiring allowlist, shipped atomically with the promotion) reproduces the guard-release-trigger 24-day lockout, self-inflicted.
4. **"Fixing" the sandbox leak by reducing coverage** — rescue/mask the badmatch, blanket `async: false`, global shared mode, or `setup_all`-scoped checkouts all make the symptom disappear while making the suite prove less (or prove the wrong thing). SEED-007's own explicit instruction stands: confirm the mechanism before changing anything.
5. **Renaming a CI lane silently changes its gating status** — "Credo Strict" is *already* accidentally release-gating today (falls into the undocumented third bucket). A naive rename either perpetuates the misclassification under a new string, or someone "fixes" the apparent ci_lanes.ex/gate-ci-green mismatch by adding the new name to `ADVISORY_LANES` — silently **demoting** a lane that has been functioning as a release gate, a real behavior change smuggled inside a cosmetic rename. Treat the rename as a three-part atomic change with an explicit, recorded required/advisory/neither decision.

## Implications for Roadmap

### Phase 141: Supply-Chain Remediation (VULN)
**Rationale:** Mostly Wave-1 independent, low-risk, high trust-restoration value; VULN-04's cadence doc should conceptually precede VULN-03's gate flip even if executed in the same phase.
**Delivers:** Dispositioned dependabot backlog (VULN-02); Hex Audit promoted to gating WITH shared allowlist wired into the CI-side lane, not just a bare `needs:` edit (VULN-03); documented triage cadence covering transitive dependencies (VULN-04).
**Avoids:** Pitfall 3 (advisory→gating deadlock) — ship promotion + escape valve atomically; Pitfall 10 (dependabot backlog + transitive blind spot).

### Phase 142: Test-Harness Truth (HARNESS)
**Rationale:** Hard-sequenced internally (01→02→03→04); must not be attempted in isolation from the corrected call-site map, and HARNESS-04 cannot be decided until 01-03 are proven, not just green once.
**Delivers:** Root-caused (not masked) sandbox-leak fix; Core Full Suite green across all 4 matrix legs, repeatedly, with anti-vacuity proof (test-count floor, signature reconciliation, deliberate-failure probe); a recorded decision on Core Full Suite release-gating (Option B — teach `gate-ci-green` to also inspect `advisory-matrix.yml` — is the researched recommendation, not a mandate).
**Avoids:** Pitfall 2 (manufactured green), Pitfall 4 (coverage-reducing shortcuts).
**Research flag:** HARNESS-01's root cause is a HYPOTHESIS (the `webhook_idempotency_convergence_test.exs` 10-minute shared-owner / `:auto`-mode-file interaction), not a confirmed mechanism — needs empirical confirmation via instrumentation before a fix is written.

### Phase 143: Design-System Conformance (CONFORM)
**Rationale:** CONFORM-02 is largely already delivered — verify, don't rebuild; CONFORM-04's rename must not land without an explicit classification decision, and is best sequenced alongside or immediately after TRUTH-07 since both touch the same "what does gate-ci-green think this lane is" question.
**Delivers:** Confirmed icon-existence gate coverage with explicit scoping of dynamic call sites (fixture-proven, not assumed); lane renamed with an explicit, recorded required/advisory/neither decision replacing today's accidental third-bucket gating.
**Avoids:** Pitfall 7 (lane-rename gating drift), Pitfall 8 (icon gate blind to dynamic names — prove with a deliberate fixture, then remove it).

### Phase 144: Lane Truth & Drift-Proofing (TRUTH)
**Rationale:** This phase hardens the meta-layer the other three phases land inside; TRUTH-07's reconciliation is the load-bearing fix (both VULN-03 and CONFORM-04 are special cases of it) and should generalize the pattern rather than being solved three separate times.
**Delivers:** Single reconciled definition of "advisory" across `CILanes.ex`, `gate-ci-green`'s JS arrays, and a corrected (not newly-written) `MAINTAINING.md:152-191`, backed by a new meta-test; skip-reports-green fixed at its actual location (`ci.yml`'s `branch_protection_advisory` job); scheduled live-vs-expected branch-protection drift comparison with a real else-branch; repo-hygiene 403-vs-drift distinction; release-trigger anti-recursion gap fixed-or-formally-accepted; every advisory lane gets a recorded disposition; publish fan-out race fixed via a widened `concurrency.group` (one-line change, `publish-hex-${{ github.ref }}` → a ref-invariant group).
**Avoids:** Pitfall 1 (vacuous guards), Pitfall 5 (id/name mismatch class), Pitfall 6 (self-racing concurrency), Pitfall 9 (two/three definitions of advisory), Pitfall 11 (403-vs-drift), Pitfall 12 (self-heal becomes new blind spot).

### Phase Ordering Rationale

- HARNESS's internal chain (01→02→03→04) is the only genuinely hard cross-phase sequencing constraint driven by data dependency (can't decide gating on an unproven suite).
- **CONFORM-04 (lane rename) is coupled to TRUTH-07 (advisory reconciliation) and they should land together** — renaming without resolving the `gate-ci-green` classification just gives the same undecided/accidentally-gating lane a more honest name.
- **VULN-03 (promote Hex Audit) must wire allowlist logic into the CI-side lane**, not just flip `ci_green.needs` — otherwise it red-blocks every PR on the already-accepted cowlib advisories the moment it's promoted, self-inflicting the exact outage class this milestone exists to prevent.
- VULN and CONFORM phase-numbering does not imply they must wait for HARNESS — they are Wave-1/near-Wave-1 independent file-work and can execute in parallel with early HARNESS investigation.

### Research Flags

Needs deeper research/investigation during planning:
- **Phase 142 (HARNESS-01):** the sandbox-leak mechanism is a hypothesis (extended-timeout shared owner colliding with `:auto`-mode sibling files), not confirmed — instrument and confirm before writing the fix.
- **Phase 142 (HARNESS-04):** the release-gating mechanism choice (Option A/B/C) is a phase-planning decision with real tradeoffs already laid out in ARCHITECTURE.md — treat as a decision point, not a given.
- **Phase 143 (CONFORM-04):** whether to split `credo_strict` into two jobs vs. rename-in-place is an explicit phase-143 decision point (the one narrow structural exception to the no-topology-rewrite lock).

Phases with well-documented, low-ambiguity patterns (standard mechanical edits, skip deep research-phase):
- **Phase 141 (VULN-02, VULN-04):** documentation + process work, no novel mechanism.
- **Phase 144 (TRUTH-08):** confirmed root cause, one-line `concurrency.group` fix, no further investigation needed.
- **Phase 144 (TRUTH-02, TRUTH-06):** same "tri-state instead of binary" fix pattern applied to two known files.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Every recommended mechanism confirmed by direct read of this repo's own workflow/source files plus primary HexDocs/GitHub Docs sources; only GitHub's native "neutral" conclusion mechanism is MEDIUM (community-discussion sourced, no official docs page). |
| Features | HIGH (repo-specific) / MEDIUM-HIGH (ecosystem precedent) | Repo-specific findings read directly from `.github/workflows/`, `ci_lanes.ex`, `MAINTAINING.md`, `check-conformance.sh`; general OSS-convention claims are web-verified but not primary-sourced in all cases. |
| Architecture | HIGH | Every claim cited to a specific file/line read directly in this worktree; two claims from the original scope doc were actively corrected against live repo state, not assumed. |
| Pitfalls | HIGH | Grounded in this repo's own workflow YAML and the SEED-007 incident record, not generic CI advice. |

**Overall confidence:** HIGH

### Gaps to Address

- **HARNESS-01's root cause is unconfirmed.** The leading hypothesis (10-minute shared-owner/`:auto`-mode collision in the `properties/` directory) is explicitly flagged as "a hypothesis to test, not a confirmed root cause" by the architecture research itself — phase 142 must budget time to instrument and confirm before writing a fix, per SEED-007's own "confirm the mechanism before changing anything" instruction.
- **CONFORM-02's dynamic icon-name coverage decision is unresolved.** Whether to statically resolve `defp ..._icon/1` return clauses or accept a runtime-assertion fallback for the 4+ dynamic call sites is a scoping decision, not yet made — phase 143 should decide and document, not silently under-cover it as happened with the original two invisible icons.
- **HARNESS-04's Option A/B/C choice is a recommendation (Option B), not a mandate** — the maintainer or phase-142 planning may weigh the tradeoffs differently; this should be treated as an open decision point at plan time, not assumed settled.
- **TRUTH-04's fix-or-accept choice is explicitly left open** by the original scope doc and not resolved by research — whichever path is chosen, it must avoid introducing a new self-heal blind spot (Pitfall 12) and must be durably documented if "accept" is chosen.
- **`post-publish-smoke.yml` has the identical ref-scoped concurrency bug as `publish-hex.yml`'s TRUTH-08** but is not named in the original scope doc's TRUTH-08 text — flagged by research as a scope call for phase 144 planning (fix in the same phase, same one-line class of change, or defer explicitly) rather than left to be independently "discovered" mid-phase as a surprise.

## Sources

### Primary (HIGH confidence — read directly, this repository, 2026-07-28)
- `.github/workflows/ci.yml`, `publish-hex.yml`, `branch-protection-drift.yml`, `guard-release-trigger.yml`, `advisory-matrix.yml`, `repo-hygiene.yml`, `gate-self-test.yml`, `post-publish-smoke.yml`, `release-please.yml`
- `test/support/ci_lanes.ex`, `test/scripts/required_checks_test.exs`, `test/scripts/ci_parity_drift_test.exs`
- `test/support/mailer_case.ex`, `test/support/data_case.ex`, `test/test_helper.exs`, plus exhaustive grep of `Sandbox.(mode|start_owner|checkout|allow)` across `test/`, `mailglass_admin/test/`, `mailglass_inbound/test/`
- `scripts/setup_branch_protection.sh`, `scripts/verify-branch-protection.sh`, `dev/mix/tasks/mailglass.repo.hygiene.ex`
- `lib/mix/tasks/mailglass.publish.check.ex`, `mailglass_admin/scripts/check-conformance.sh`, `mailglass_admin/assets/vendor/heroicons-inline.js`, `mailglass_admin/lib/mailglass_admin/components.ex`
- `MAINTAINING.md` (existence + content verified directly — corrects the scope doc's TRUTH-07 claim), `.github/dependabot.yml`, `release-please-config.json`, `.release-please-manifest.json`
- `git log -S`/blame for `branch-protection-drift.yml`, `check-conformance.sh` (`ICON-EXISTS-GATE` provenance), `MAINTAINING.md` existence-since-commit
- `.planning/PROJECT.md` (v2.2 section), `.planning/research/v2.2/MILESTONE-SCOPE.md`, `.planning/seeds/SEED-007-sandbox-ownership-leak.md`, `.planning/research/milestone-cicd/CICD-RELEASE-HARDENING.md` and `SYNTHESIS.md`

### Secondary (HIGH-MEDIUM confidence, web-verified 2026-07-28)
- `hexdocs.pm/mix_audit`, `github.com/mirego/mix_audit`, `hexdocs.pm/hex/Mix.Tasks.Hex.Audit.html`
- `docs.github.com` — Dependabot security updates + version updates, supported ecosystems, required-status-check troubleshooting, branch-protection REST/GraphQL reference, concurrency control
- `ecto-sql.hexdocs.pm/Ecto.Adapters.SQL.Sandbox.html` (v3.14.0) — `mode/2`, `start_owner!/2`, `stop_owner/1` semantics
- GitHub community discussions #9875, #82744 (no native job-level "neutral" conclusion), #26698, #130684 (required-context matching failure mode)
- ElixirForum threads on `setup_all` + Sandbox anti-pattern

### Tertiary (LOW-MEDIUM confidence, needs validation)
- General OSS-ecosystem convention claims (severity-tiered SLA shape, Dependabot noise-reduction practices) — consistent across multiple independent sources but not independently primary-sourced in every case.

---
*Research completed: 2026-07-28*
*Ready for roadmap: yes*
