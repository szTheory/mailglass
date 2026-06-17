# Phase 106: Day-2 Guides — Go-Live Checklist + Error/Troubleshooting Map - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-17
**Phase:** 106-day-2-guides-go-live-checklist-error-troubleshooting-map
**Mode:** assumptions
**Areas analyzed:** Error-map source-of-truth & structure (OPS-02); Checklist content/sourcing & overlap with existing guides (OPS-01); Docs-contract assertion shape + mix.exs registration

## Assumptions Presented

### Error-map source-of-truth & structure (OPS-02)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Single flat guide, one `##` section per error struct (10), each type-atom→cause→fix, routing canonical truth to api_stability.md | Confident | ten `defexception` modules `lib/mailglass/errors/*.ex`; `error.ex:5-8` "no parent struct"; `api_stability.md:208-420`; `docs_helpers.ex:17-19` `##`-only |
| Must cover StreamPolicyError + PublishError from moduledocs — StreamPolicyError absent from api_stability.md; summary still says "six structs" (:214) | Confident | `grep StreamPolicy docs/api_stability.md` empty; union :56-60 lists nine; `stream_policy_error.ex:12`; `error.ex:65-76` enumerates ten |

### Checklist content/sourcing & overlap with existing guides (OPS-01)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Thin orchestrating checklist cross-linking existing topic guides; `mix mail.doctor` and `mix mailglass.doctor` as two distinct commands | Confident | `mail.doctor.ex:8-19,35` (DNS, needs app.start) vs `mailglass.doctor.ex:6-31,98-104` (offline, 3-state exit); shim pattern `webhook-troubleshooting.md:1-9` |
| New errors guide cross-links — does not absorb — operator-incident-support.md (symptom-first) + webhook-troubleshooting.md (shim) | Likely | `operator-incident-support.md:1-3` canonical symptom runbook; neither in mix.exs extras; Phase-33/61 assertions pin strings `docs_contract_test.exs:231-263, :359-375` |

### Docs-contract assertion shape + mix.exs registration
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Two new describe tests (OPS-02 10-name coverage + api_stability route-link; OPS-01 section-presence literals) + learning-path-style registration test; both guides in extras: + Guides: group | Confident | `learning-path` test `docs_contract_test.exs:158-168`; section-presence :240-263, :328-341; mix.exs extras ~383-407, Guides group ~408-431, main :357 |

## Corrections Made

No corrections — user selected "Yes, proceed"; all assumptions confirmed.

## External Research

None performed — `needs_research` was empty. Docs-only phase; all source-of-truth (error
modules, both doctor tasks, api_stability.md, existing guides, contract test + helpers, mix.exs)
read directly in-repo.

## Methodology Lenses Applied

- **Decisive-By-Default:** single recommendation per area (separate-guide cross-linking over
  absorb/duplicate; route truth to api_stability.md; mirror learning-path registration test).
- **Honest Surface Area:** flagged two real surface gaps — api_stability.md has no StreamPolicyError
  section and its `Mailglass.Error` summary still says "six structs"; error.ex says "eight" but
  enumerates ten. Recorded as a Deferred Idea (adjacent, out of strict scope).
- **Recommendation-First Synthesis:** recommendations reinforce one coherent docs posture
  consistent with the repo's existing shim/canonical-guide pattern.
