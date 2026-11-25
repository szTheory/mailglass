# Phase 179: Compatibility Policy, Status Map and Brand Pin - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md. This log preserves the analysis.

**Date:** 2026-11-13
**Phase:** 179-compatibility-policy-status-map-and-brand-pin
**Mode:** assumptions, with a three-agent fan-out per the owner's research-first boilerplate (no interactive correction round; the Decision Policy and METHODOLOGY say to decide and escalate only strategic forks)
**Areas analyzed:** status map; "Not sent" semantics; Copy and contract test; compatibility policy; brand pin; trademark record; CI/release kinds

## Agents
1. gsd-assumptions-analyzer: codebase trace (atoms, suppression path, copy locations, policy inventory, lanes).
2. general-purpose: prior art and ecosystem (policy format, status vocab in Postmark/SendGrid/Resend, pin precedent).
3. general-purpose: trademark/name-collision search methodology and actual results.

## Conflicts between agents and how they were resolved
| Question | Agent A | Agent B | Decision |
|---|---|---|---|
| Policy location | new section in `docs/api_stability.md` | new `docs/brand-v2-compatibility.md` | New file (roadmap says "policy file"; avoids growing the stability doc), linked both ways. D-12 |
| Pin location | root `brand.pin.json` | `brandbook/brand.pin.json` | `brandbook/` (core `exclude-paths`; root is a core release path). D-16 |
| Pin URL | commit-pinned raw URL | Pages URL | Commit-pinned raw URL (immutable, verified). D-16 |
| Trademark record | `.planning/brand/*.md` with YAML front matter | `.planning/research/brand-v2-adoption/*.json` | JSON in research dir (no YAML dep; survives archive). D-20 |
| Atom count | 26 | 26 (25 badge atoms + `:subscribed`) | 26; amend BRPOL-02 wording. D-01 |
| Where status map lives | admin | admin | Admin. D-02 |

## Assumptions presented (and outcome)
| Assumption | Confidence | Evidence | Outcome |
|---|---|---|---|
| Universe is 26 atoms | Confident | `components.ex` 1360-1388, `event.ex:34-71` | Locked D-01 |
| StatusMap/Copy in admin, not core | Likely | core `files:` allowlist, public API | Locked D-02 |
| Classification table | Likely | LENS-FINDINGS line 17 | Locked D-03; `:complained`/`:unsubscribed` flagged as veto-able |
| `:suppressed` never persisted by lib | Confident | `suppression.ex`, `outbound.ex`, `persistence.ex`, `projector.ex` | Locked D-06 with new zero-row DB test |
| Copy starts with verbatim labels, new words `wired: false` | Likely | existing component/voice pins | Locked D-07 |
| Render + closed-set scan contract test | Likely | phase175 template | Locked D-09/D-10 |
| Policy table parsed by test, subset + reverse check | Likely | `docs_check`, stability_contract_test | Locked D-13/D-14 |
| Pin + hermetic tamper test, no skip-if-no-zip | Likely | `test_exceptions.exs` keying | Locked D-16..D-19 |
| Trademark record fails gate by design, no time-bomb in CI | Likely | TM agent decision rule | Locked D-20..D-23 |
| No lane/mix.exs edits; `refactor(admin):` for lib | Confident | `ci.yml`, guard script | Locked D-24..D-26 |

## Corrections Made
No interactive corrections. Two upstream corrections were applied to the plan inputs: "25 atoms" -> 26, and the unverified "Not sent" question answered from code.

## Items for owner veto (cheap to reverse)
- `:complained` and `:unsubscribed` classified "not a delivery status".
- `:queued` in the Sent class (qualified label in Phase 182).
- `refactor(admin):` for the no-visible-change `Copy`/`StatusMap` commit, so no release is proposed by this phase.

## Owner hand-off (not blocking)
- ~15 min browser pass over USPTO / TMview / WIPO / WHOIS (runbook with full URLs to be produced by the plan), and the counsel call.

## External Research
See `.planning/research/brand-v2-adoption/PHASE-179-RESEARCH.md`. Unverified: member names inside the brand zip (`unzip -l` in the executor); whether `Components.__components__()` exposes attr `values:`.
