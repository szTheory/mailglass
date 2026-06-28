# Phase 124: Release Cut + Milestone Closeout - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-28
**Phase:** 124-release-cut-milestone-closeout
**Mode:** assumptions (+ research validation)
**Areas analyzed:** Origin-divergence reconciliation, version targets + RP re-score, publish
allowlist + phoenix_storybook non-leak, inbound pin-drag paired release, milestone audit scope

## Assumptions Presented

### Origin-Divergence Reconciliation
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Reconcile via `git rebase origin/main` then ordinary fast-forward push; never `--force`; body is 124 individual conventional commits, 0 merge commits, so rebase yields clean linear history | Confident | `git rev-list` (124 ahead / 1 behind); `63c3f4c3 chore(deps) actions/checkout #88` is origin-only; v1.13 117-CONTEXT D-02 (clean push, but no divergence then) |
| Rebased HEAD SHA is what RP tags + `gate-ci-green` needs green ci.yml on; `#88` modified ci.yml so body must replay on top | Confident | `.github/workflows/publish-hex.yml` gate-ci-green; #88 touches ci.yml |

### Version Targets + RP Re-Score
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| core 1.10.0 / admin 1.10.0 (linked MINOR); RP self-scores from visible admin feats once body on origin; Release-As fallback only | Confident | `@version 1.9.0` in ./mix.exs + admin; ROADMAP Phase 124 + REL-01 "admin-minor drags matched core+inbound"; 117 D-02 mechanism |

### Publish Allowlist + phoenix_storybook
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Allowlist NOT stale this cycle (zero `comm` deltas); run publish.check as fail-closed confirm anyway | Confident | `comm` diffs of git ls-files vs `.planning/publish/*-files.expected`; no untracked admin lib/priv/docs |
| phoenix_storybook cannot leak — only in reference/demo_app `only: :dev`, absent from admin mix.exs | Confident | `reference/demo_app/mix.exs:49`; absent from `mailglass_admin/mix.exs` |

### Inbound Pin-Drag Paired Release
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Pin-drag will NOT auto-cut inbound release (not in linked-versions; sed pin lands as chore); needs deliberate `fix(inbound):` commit before RP PR merges | Confident | release-please.yml linked-versions covers only core+admin; mailglass_inbound/mix.exs ~lines 126-136 recovery note; publish-admin needs publish-inbound |
| Inbound pure pin-drag, no lib feature since v1.13 | Confident | `git log mailglass_inbound-v1.5.1..HEAD -- mailglass_inbound/lib` empty |

### Reference Baseline + Audit Scope
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| No reference-baseline bump (`~> 1.0` resolves any 1.x) | Confident | reference/host_app + demo_app mix.exs `~> 1.0` pins; matches 117 D-07 |
| Audit scope: 7 phases (118-124), 15 reqs (METHOD 2/STORY 2/SHELL 3/DELIV 1/INB 1/PREV 1/COH 2/SEED 1/REL 2); SEED-003 literal; REL only 2 | Confident | grep unique REQ-IDs in .planning/REQUIREMENTS.md; ROADMAP line 27 "Phases 118-124" |

## Research Performed (user-requested, release-engineering lens)

Two parallel `gsd-advisor-researcher` agents validated the two areas with genuine release-engineering
tradeoffs (git reconciliation; RP version scoring + pin-only paired release). Sources:
googleapis/release-please (commit scanning, manifest-releaser docs, issue #2425), Elixir School
"Automating Elixir Releases with Release Please", plus the repo's own MAINTAINING.md, workflows,
mix.exs comments, and the 108/117 precedents.

- **Reconciliation:** rebase (Option A) is unambiguously correct vs merge-commit (B, breaks linear
  invariant) vs cherry-pick+force (C, force-push clobber hazard). Footguns encoded: rebased HEAD =
  release/tag SHA gate-ci-green binds to; #88 modified ci.yml so replay on top; re-fetch immediately
  before rebase; never force on a post-rebase non-ff (re-fetch + re-rebase instead).
- **Version scoring:** core+admin self-score MINOR reliably from visible admin `feat` commits once on
  origin; Release-As fallback only. Footgun: a `chore:`-titled squash subject would hide feats (RP
  reads the subject on main).
- **Pin-only paired release:** confirmed RP will NOT auto-cut inbound from the sed pin alone (no
  Elixir dep-propagation plugin; `chore` doesn't score). The deliberate `fix(inbound):` commit is the
  accepted idiom across exact-version sibling-pin repos — `extra-files` was tried and no-ops.
  **The research flagged a version mismatch:** the original "1.6.0" assumption (a MINOR) conflicts
  with the `fix(inbound):` patch idiom — a pure pin bump is semver-honestly a PATCH (1.5.2).

## Corrections Made

### Inbound Version Target
- **Original assumption:** inbound ships `1.6.0` (minor) for cadence with core/admin 1.10.0.
- **Research finding:** inbound has zero lib changes — a pure pin bump is a PATCH; the documented
  `fix(inbound):` idiom auto-scores 1.5.2; 1.6.0 would require a deliberate `feat(inbound):`/`Release-As:`
  purely for visual cadence and slightly overstates the change.
- **User correction (maintainer):** **1.5.2 (patch)** — semver honesty over step-with-core optics.

## External Research
- (Settled above.) No further external research needed — every remaining unknown is settled by repo
  evidence and the heavily-precedented 108/117 ceremony template.
