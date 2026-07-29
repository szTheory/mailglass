# Phase 142: Supply-Chain Remediation & Gating - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-07-28
**Phase:** 142-supply-chain-remediation-gating
**Mode:** assumptions
**Calibration:** minimal_decisive (`.planning/config.json` `preferences.vendor_philosophy: opinionated`)
**Areas analyzed:** Shared Allowlist Mechanism (VULN-05); Lane Promotion & Drift-Test Blast Radius
(VULN-03); Exception Expiry, Backlog & Triage (VULN-06 / VULN-02 / VULN-04); Wave Ordering

## Assumptions Presented

### Shared Allowlist Mechanism (VULN-05)

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Allowlist + parsers extract to `lib/Mailglass.SupplyChain.AcceptedAdvisories`; new **dev-path** task `mix mailglass.audit` invoked by both CI lanes; `publish.check` delegates | Confident | `mailglass.publish.check.ex:62`, `:1113`, `:1188`; `mix.exs:114-116` (dev on elixirc_paths, excluded from Hex `files:`); `dev/mix/tasks/mailglass.repo.hygiene.ex:1-7` + `repo-hygiene.yml:43` precedent; tarball-isolation compile at `:936-965`; `docs/api_stability.md:53,133` + `stability_contract_test.exs:43-50` |
| Entries gain `:aliases`, `:package`, `:severity`, `:reason`, `:accepted_on`, `:recheck_by`; match by id **or** alias | Confident | `hex.audit` keys `EEF-CVE-2026-4396{6,9}`; `mix_audit` reports GHSA form only; `mailglass.publish.check.ex:1179-1186` documents the asymmetry as an accepted hole |
| Audit scope widens root-only → all three Mix projects (`hex.audit` per dir; `deps.audit --path` from root) | Likely | Live: root `hex.audit`/`deps.audit` clean; `mailglass_admin` reports both cowlib advisories; cowlib 2.19.0 in `mailglass_admin/mix.lock:7`, absent from root lock; `ci.yml:567-568` root-only; `deps/mix_audit/lib/mix_audit/cli.ex:12` (`--path`), verified working from root |

### Lane Promotion & Drift-Test Blast Radius (VULN-03)

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Promotion is ONE atomic commit across nine sites incl. four hardcoded counts | Confident | `ci.yml:1150-1155`, `:1157-1176`, `:581`, `:575-580`; `ci_lanes.ex:80,95-96,112,130`; `publish-hex.yml:204,228,238`; `MAINTAINING.md:197,210`; `lane_classification_drift_test.exs:71,88,143`; `ci_parity_drift_test.exs:161`; totality assertion at `lane_classification_drift_test.exs:236-272` (24 jobs; 5+4+13+2 → 7+3+12+2); wired via `verify.ci_lane_contract` (`mix.exs:296-298`) |
| `Deps Audit Advisory` renamed `Deps Audit (Elixir 1.18 / OTP 27)`; `setup_branch_protection.sh` untouched | Likely | Phase 141 rename precedent; `required_checks_test.exs:45-58` asserts `{CI Green, Guard Release Trigger}` exactly; blast radius `ci.yml:571`, `ci_lanes.ex:96,112`, `publish-hex.yml:229`, `ci_parity_drift_test.exs:114,188`, `MAINTAINING.md:197` |
| Gate blocks on **any** non-allowlisted finding; no HIGH-severity merge threshold | Likely | `mailglass.publish.check.ex:1068-1110`, `:1142-1177` already block on any non-accepted finding; `.planning/research/v2.2/PITFALLS.md:187-201` |

### Exception Expiry, Backlog & Triage (VULN-06 / VULN-02 / VULN-04)

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Expiry rests on two local deterministic signals (`recheck_by` date; allowlist-entry-unused) — **not** OSV fix-detection; OSV stays warn-only | Confident *(revised by research — see below)* | Live `api.osv.dev` queries; `mailglass.publish.check.ex:1218-1295`; mirego DB closes cowlib range at `<= 2.16.1` |
| VULN-04 cadence → new `## Dependency Advisory Triage` in `MAINTAINING.md`, adjacent to `## Security Response SLA` (`:296`), **after** `## Required Checks` | Confident | Table parser splits on `"\n## "` (`lane_classification_drift_test.exs:607-611`), rejects non-7-cell rows, asserts exactly 24 rows (`:455-468`); `SECURITY.md:11-24` is adopter-facing intake |
| VULN-02 = exactly 13 open dependabot PRs, all auto-merge armed (#131, #130, #125, #124, #116, #115, #114, #112, #111, #108, #106, #96, #95), dispositioned individually; maintainer PR #132 adjacent/out of scope | Confident | Live `gh` as `szTheory`: 16 open, 13 by `app/dependabot`, all `autoMergeRequest` non-null; supersession visible (#114 vs merged #78; #115/#125 both `phoenix_live_view` 1.2.8); `.planning/research/v2.2/PITFALLS.md:676-681` |

### Wave Ordering

| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| W1 (VULN-05+06 mechanism ‖ VULN-02 backlog) → W2 (atomic promotion) → W3 (VULN-04 docs + proof) | Confident | VULN-05 declared a hard precondition for VULN-03 in `REQUIREMENTS.md` and ROADMAP criterion 1 |
| W2 gates on **observed green with cowlib actually in scope**, not on "W1 merged" | Confident | Root `hex.audit` clean today — a root-only W1 would look green for the wrong reason |

## Corrections Made

No corrections — the user reviewed the presented set and selected "Yes, proceed."

The one substantive change to the initial analysis was made **by external research, before presentation**,
not by user correction:

### Exception Expiry (VULN-06)
- **Original assumption (analyzer):** extend the existing OSV staleness classifier from "withdrawn only" to
  also detect a `fixed` event in `affected[].ranges[].events`, hard-failing on "fix landed."
- **Revised to:** two local deterministic checks (`recheck_by` date + allowlist-entry-unused) as the
  forcing function; OSV `fixed` detection demoted to optional warn-only enrichment, with its absence
  explicitly treated as "no signal" rather than as evidence the entry is still valid.
- **Reason:** live OSV data refuted the mechanism. See External Research below.

## External Research

Two topics were flagged by the analyzer as unanswerable from the codebase. Both were researched and both
changed or firmed a decision.

### Topic 1 — Does OSV record "a fix landed" for EEF/Erlang advisories?

- **Finding:** No — not for the two advisories actually allowlisted. `EEF-CVE-2026-43966` and
  `EEF-CVE-2026-43969` (schema_version 1.7.5) carry `affected[].ranges[].events: [{"introduced": "2.9.0"}]`
  only — no `fixed`, no `last_affected`, no top-level `withdrawn`. Both were `modified` 2026-07-14, *after*
  the fix commits, and still assert every version ≥ 2.9.0 is affected. `EEF-CVE-2026-43969` has a
  `references[].type == "FIX"` commit link; `EEF-CVE-2026-43966` does not, and has **no GHSA alias at all**.
  The GHSA alias `GHSA-g2wm-735q-3f56` uses `last_affected: 2.16.1`, not `fixed`. EEF *can* populate `fixed`
  — plug, phoenix, swoosh, and cowboy advisories all do — so this is a per-record gap, plausibly because the
  fix landed in the `erlef/cowlib` fork rather than a ninenines release the CNA tracked.
  - Corollary finding: mirego's `elixir-security-advisories` records `first_patched_versions:` as an **empty
    list entry** for cowlib but closes `vulnerable_version_ranges` at `<= 2.16.1` — so **`mix deps.audit`
    already stops flagging cowlib 2.19.0** while OSV still flags it. `EEF-CVE-2026-43966` is not in the
    mirego DB under cowlib at all. The `@accepted_advisories` rationale text ("no upstream fix as of
    2.17.1") is therefore already stale by two minor versions.
- **Source:** `api.osv.dev/v1/vulns/{EEF-CVE-2026-43966,EEF-CVE-2026-43969,GHSA-g2wm-735q-3f56}`;
  `api.osv.dev/v1/query` for cowlib@2.19.0 and @2.17.1;
  `raw.githubusercontent.com/mirego/elixir-security-advisories/master/packages/cowlib/GHSA-g2wm-735q-3f56.yml`;
  `hex.pm/api/packages/cowlib`; local `mix.lock` / `mailglass_admin/mix.lock`.
- **Confidence impact:** Resolves the VULN-06 mechanism to **Confident**, but for the *opposite* design than
  first assumed. A `fixed`-event gate would silently never fire for exactly the entries it exists to police
  — worse than no gate, because it manufactures confidence. Locked as CONTEXT.md D-10.

### Topic 2 — What `conclusion` does the Jobs API report for job-level `continue-on-error: true`?

- **Finding:** Job-level and step-level differ, and the difference is decisive here.
  - Step-level `continue-on-error` → step `outcome: failure`, step `conclusion: success`, **job
    `conclusion: success`**.
  - Job-level `continue-on-error` → **job `conclusion: failure`** (red X in the UI, and in the Jobs REST
    API) but **`needs.<job>.result: success`**, and run-level `conclusion: success`.
  - Never `neutral` or `skipped` — the runner overwrites any `neutral` PATCH at job completion.
  - Consequence: deleting `continue-on-error: true` is **not necessary for `gate-ci-green`** — it already
    reads `job.conclusion` (`publish-hex.yml:293-296`, `:315`) and already sees the failure; only the
    `ADVISORY_LANES` classification (`:228-233` → `core.warning` at `:356-361`) suppresses it. But deletion
    **is mandatory for `ci_green`/PR blocking**, because `ci_green` (`ci.yml:1146-1173`) evaluates
    `needs.<job>.result`, which job-level `continue-on-error` masks to `success`. Neither the array move nor
    the deletion works alone.
  - Also surfaced: `ci.yml:578-580`'s comment claims classification works via an `isAdvisory()` naming
    convention in `publish-hex.yml`. **That function no longer exists** — Phase 141 replaced it with explicit
    array membership. So the rename is not mechanically required, contrary to what the comment implies.
- **Empirical status:** docs-derived, not observed in-repo. A scan of the 100 most recent `ci.yml` runs plus
  30 each of `post-publish-smoke.yml`, `provider-live.yml`, `actionlint.yml` found the case has never
  occurred — every job that has ever had a failed step lacks `continue-on-error`, and
  `Deps Audit Advisory` has only ever been `success` or `skipped`. Secondary web sources conflict on the
  job-level value.
- **Source:** `raw.githubusercontent.com/github/docs/main/content/actions/reference/workflows-and-actions/workflow-syntax.md`
  L896-898 (step-level) and L1176-1180 (job-level);
  kenmuse.com/blog/how-to-handle-step-and-job-errors-in-github-actions/;
  github.com/orgs/community/discussions/15452; `gh api repos/szTheory/mailglass/actions/...` over 190 runs.
- **Confidence impact:** Firms CONTEXT.md D-07 to **Confident** on the mandatory-for-`ci_green` claim, and
  corrects D-06's rationale (rename kept for signal honesty, not mechanism). The residual uncertainty on the
  job-level REST value is one-directional and safe: if it were `success`, deletion becomes necessary for
  `gate-ci-green` too — which the phase does regardless.

## Methodology

`.planning/METHODOLOGY.md` carries four lenses. Three fired:

- **Decisive-By-Default Research Posture** — calibration `minimal_decisive` produced one recommendation per
  area rather than option menus. No routine tradeoff was surfaced to the user.
- **Recommendation-First Synthesis** — the release/publish-posture escalation bar was evaluated against the
  one genuinely strategic fork in this phase (D-08: block-on-any-finding vs. a HIGH-severity merge
  threshold). It was presented as an explicitly offered correction target rather than as a blocking
  question, and the user accepted the recommended default. The merge-gating promotion itself was not
  escalated: Phase 141 already recorded `promote` as the disposition for both lanes, and VULN-03 states it
  as a requirement — the decision was made upstream, not here.
- **Honest Surface Area** — drove D-01's `lib/`-data / `dev/`-task split (keeps a maintainer tool off the
  stable public Mix-task contract at `docs/api_stability.md`) and D-09 (delete a comment describing a
  mechanism that no longer exists).

**Compatibility Contract Ergonomics** did not fire — this phase changes no public contract, deprecation, or
support horizon. D-01 is specifically shaped to keep it that way.

## Todos

- **Folded:** `2026-06-30-remove-cowlib-advisory-allowlist-when-upstream-fixes.md` (match score 0.6).
  Phase 141 explicitly deferred it to Phase 142/VULN-06, and D-10's unused-entry check automates exactly
  what the todo asks a human to remember. Research showed it is **already actionable** — mirego no longer
  flags cowlib 2.19.0.
- **Reviewed but not folded:** none.
