# Phase 141: Lane Truth Foundation - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in `141-CONTEXT.md` — this log preserves the analysis.

**Date:** 2026-07-28
**Phase:** 141-lane-truth-foundation
**Mode:** assumptions
**Calibration:** minimal_decisive (`config.json` `preferences.vendor_philosophy: opinionated`)
**Areas analyzed:** Lane Truth Registry & the Undocumented Third Bucket; CONFORM-04 Rename Blast Radius and
the Job Split; HIST-01 Residual Scope
**User interactions:** 2 (one escalated publish-posture call, one adjacent-scope multiselect)

## Assumptions Presented

### Lane Truth Registry & the Undocumented Third Bucket

| Assumption | Confidence | Evidence |
|---|---|---|
| `Mailglass.CILanes` becomes the single authoritative registry, extended from a 2-bucket list to a *total* classification; `gate-ci-green` enumerates all sets explicitly and the `/ Advisory \(/` regex is deleted | Confident | `test/support/ci_lanes.ex`; `publish-hex.yml:269`, `:273-282`; `ci.yml:1080`; `MAINTAINING.md:160-164`; `.planning/research/v2.2/PITFALLS.md:488-494` |
| The disposition table lives in `MAINTAINING.md` §"Required Checks" as one table, machine-checked by a new `test/scripts/` meta-test; no new `.planning/` register, no new dependency | Likely | `ci_lanes.ex:16`; `test/scripts/required_checks_test.exs:30-34`, `:102-107`, `:159-267`; `.planning/research/v2.2/SUMMARY.md`; `.planning/RATCHET-GAP-REGISTER.md` (milestone-scoped precedent) |

### CONFORM-04 — Rename Blast Radius and the Job Split

| Assumption | Confidence | Evidence |
|---|---|---|
| The rename has zero branch-protection blast radius | Confident (upgraded from Likely by live verification) | `scripts/setup_branch_protection.sh:17-20`; `test/scripts/required_checks_test.exs:45-58`; **live `gh api` call, see External Research** |
| Criterion 3 mandates a one-time job split, not just a rename: `credo_strict` + new `Design System Conformance (Elixir 1.18 / OTP 27)` | Likely | ROADMAP.md criterion 3 ("from the name alone"); `.planning/research/v2.2/SUMMARY.md` anti-features carve-out; `ci.yml:395`; `mix.exs:364-394` |

### HIST-01 — Residual Scope Is the Defect Record Only

| Assumption | Confidence | Evidence |
|---|---|---|
| Artifact restoration is already complete and byte-exact — 0 missing, 0 differing across 48 files | Confident | `b5fed519` (deletion), `a629fb82` (restoration), per-file SHA comparison vs `b5fed519^` |
| The 134/136 "gaps" are original, not deletion damage | Confident | `dc26471c docs(134): create phase plan` — those phases skipped the discuss step |
| The only remaining work is writing the defect record; recommended `.planning/TOOLING-DEFECTS.md` at `.planning/` root | Confident | `phases.clear` absent from `.planning/**/*.md` + `CLAUDE.md` except as the requirement itself; recorded only in `70099869`'s commit body |

## Ground-Truth Corrections to the Roadmap and Requirements

Analysis contradicted the phase's own inputs in three places. Each is applied in CONTEXT.md.

| Roadmap / REQUIREMENTS.md said | Ground truth |
|---|---|
| "9+ hidden jobs" (criterion 2, TRUTH-09) | **14 of 23** `ci.yml` jobs. The three uncounted: `changes`, `ci_green`, `Branch Protection Advisory` (the last escapes the advisory regex because its name has no `(` after "Advisory") |
| "three disagreeing advisory registries" (TRUTH-07) | **Five.** `CONTRIBUTING.md:116` is a fifth with all five of its claims wrong, and `MAINTAINING.md` contradicts *itself* (lines 134-142 vs 180-191 vs 153-158) |
| HIST-01: restore 132-137 artifacts | **Already restored, byte-exact,** in `a629fb82` |

## Corrections Made

### Bucket model (escalated per METHODOLOGY.md release/publish-posture bar)

- **Original assumption:** Name a third `publish_gating_lanes` bucket, preserving today's publish posture.
- **Tension surfaced:** TRUTH-09's literal text mandates two buckets ("merge-gating **or** advisory").
  Satisfying the letter would either let a Hex publish proceed with red Dialyzer / red audit lanes, or
  promote 5 lanes to merge-gating (contradicting D-04 for Trust Lane Clean Baseline and lengthening every
  PR's critical path).
- **User decision:** **"Name the third tier."** Assumption confirmed.
- **Consequence recorded as D-03:** the phase amends TRUTH-09's wording in `REQUIREMENTS.md` so the
  requirement does not itself become a sixth disagreeing registry.

### Adjacent truth-gaps (multiselect — 2 of 4 folded)

- **Folded — `CONTRIBUTING.md:116`** (D-14): the uncounted fifth registry; all five claimed required checks
  are wrong.
- **Folded — `MAINTAINING.md` self-contradiction** (D-15): unavoidable, since that file is being made
  authoritative.
- **Not folded — re-pointing `ci_lanes.ex:16`'s line-range citation:** consequence recorded in CONTEXT.md
  `<deferred>` (the cited `152-191` range goes stale as a direct result of D-05 — Pitfall 9).
- **Not folded — `Inbound Full Suite Advisory` (`advisory-matrix.yml:273`):** a lane in no registry, but
  outside `ci.yml` and therefore in Phase 143/HARNESS-04's seam.

## Auto-Resolved

Not applicable — `--auto` was not used.

## External Research

Two gaps were flagged by the analyzer. Both were settled locally rather than by spawning a research agent.

- **Live branch-protection state.** `gh api repos/szTheory/mailglass/branches/main/protection --jq
  '.required_status_checks.contexts'` → `["CI Green","Guard Release Trigger"]`. Confirms no `ci.yml` leaf is
  a required context, so the CONFORM-04 rename cannot strand a stale required check. Upgraded that
  assumption Likely → Confident. Verified live rather than inferred from `setup_branch_protection.sh`,
  because a script-vs-live mismatch is this milestone's originating incident.
- **Whether the `gsd-tools query phases.clear` defect is fixed upstream.** Installed `gsd-sdk v1.42.3`
  (`~/.claude/gsd-core/bin/lib/milestone.cjs`) carries three relevant mitigations: `#1871` archives phase
  dirs instead of hard-deleting, `#1447` refuses to run against uncommitted phase work, and `#2288` adds an
  explicit `--archive-version <outgoing>` override — needed because `new-milestone` runs
  `state.milestone-switch` **before** `phases.clear`, so a live STATE.md read files the archive under the
  *incoming* milestone. Changed D-18/D-19 from "warn that the command destroys data" to "record a dated note
  prescribing `--archive-version` plus a post-run check that `milestones/<version>-phases/` exists."

## Methodology Lenses Applied

All three lenses in `.planning/METHODOLOGY.md` fired.

- **Decisive-By-Default Research Posture.** All three gray areas had strong repo priors and settled research
  (`.planning/research/v2.2/ARCHITECTURE.md:130-200` already holds a near-complete tier table). Flagged as
  do-not-re-litigate: the tier table, the `MAINTAINING.md`-exists correction, and the "no new dependency"
  lock. Decided in-plan rather than surfaced as an option menu.
- **Honest Surface Area** — *the phase's whole thesis.* Flagged three things: (1) the reconciliation must not
  *widen* what the docs promise — write only what `ci_lanes.ex` + the meta-test can prove; (2)
  `CONTRIBUTING.md:116` would otherwise survive as a fresh lie (→ folded, D-14); (3) `ci_lanes.ex:16`'s
  line-range citation goes stale (→ surfaced, not folded, recorded in `<deferred>`).
- **Recommendation-First Synthesis (release/trust-contract variant, METHODOLOGY.md:27-31).** One item met the
  escalation bar — collapsing to two buckets would materially change irreversible publish posture for five
  lanes — and was escalated as the single user question. The `credo_strict` split brushes SEED-006
  (~2-3 min extra wall-clock); ROADMAP criterion 3's wording settled it without escalation, with the cost
  noted in D-13.
