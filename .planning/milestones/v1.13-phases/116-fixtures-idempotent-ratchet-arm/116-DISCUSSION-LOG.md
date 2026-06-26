# Phase 116: Fixtures + Idempotent Ratchet-Arm - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-20
**Phase:** 116-fixtures-idempotent-ratchet-arm
**Mode:** assumptions (+ user-requested research-driven synthesis)
**Areas analyzed:** Ratchet primitives (interaction pillar + axe baseline); Stress-fixture cohort +
gallery matrix; Bucket-A closure (RATCHET-05)

## Assumptions Presented

### Ratchet schema + interaction pillar + axe baseline
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Interaction pillar = separate binary Playwright gate, NOT a 7th scored pillar; matrix stays 54-cell schema 3 | Confident | `ratchet_baseline_test.exs:27` hardcodes 6 pillars; existing binary interaction assertions in `structural.spec.js` |
| Axe baseline = new separate JSON, per-surface counts meet-or-beat (exact format flagged for research) | Likely | SUMMARY/ROADMAP flag the format as the open Phase-116 question; `@axe-core/playwright` absent today |

### Stress-fixture cohort shape + demo_app run
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Cohort lands in demo_data.ex (human run) + gallery static specimens (lab); hand-enumerated, not generated | Confident | `seeds.exs` shim → `DemoData.reset!`; gallery is in-code no-DB; e2e seeds `browser-tenant` ≠ demo_app |
| 8 edge cases spread across 2–3 personas, surfaced through scoped `list_tenants` | Confident | RATCHET-01 text + `PHASE112-SHELL-GATE` + existing 2-tenant demo_data |

### Bucket-A closure (RATCHET-05)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Primarily verify-and-lock; back-fill net-new guards only for cohort/interaction residue | Likely | PITFALLS pitfall→fractal-level map; most gates already in `check-conformance.sh` |

## Corrections Made

No corrections to the assumptions' *direction*. Instead of confirming-as-is, the user invoked the
project's research-first decision policy: spawn per-area research subagents (pros/cons/tradeoffs,
idiomatic Elixir/Phoenix, lessons from comparable design systems, DX, `prompts/`/brandbook), then
one-shot a coherent recommendation set. Three `gsd-advisor-researcher` agents ran in parallel; their
decisive recommendations were synthesized and locked verbatim into CONTEXT.md D-01..D-12. The user
selected **"Lock all, write CONTEXT.md."**

Net effect: the assumptions were upgraded from directional to fully-specified, fail-closed, file-level
decisions:
- **Area A:** axe format resolved to **hybrid (per-surface×theme counts meet-or-beat + rule-id
  breakdown)** in a separate `docs/axe-baseline.json` (schema 1) with an ExUnit comparator cloning
  `ratchet_baseline_test.exs`; interaction pillar confirmed as a binary `structural.spec.js` gate;
  score matrix stays 54-cell schema 3.
- **Area B:** one canonical persona spec `reference/demo_app/lib/mailglass_demo/personas.ex` +
  three thin builders + a drift-guard test; personas `northstar`/`fjordline-aps`/`helios-void`
  mapped to the 8 edge cases; gallery viewport via a Playwright resize loop over stable testids;
  RATCHET-04 extends the existing demo Playwright suite.
- **Area C:** audit-first with a ~18 verify / ~6 author-new split (A3, A4/A23, A16-system, A21, A22,
  A11); durable closure via an executable `bucket_a_coverage_test.exs` manifest that asserts each
  cited guard physically exists, under the `RATCHET-GAP-REGISTER` stable-ID contract.

## External Research

Three parallel `gsd-advisor-researcher` agents (web + codebase + `prompts/`):
- **Axe/ratchet structure** — concluded hybrid counts+rule-id baseline (rejected node-fingerprint
  snapshots as brittle to v1.13 DOM churn, and bare allowlists as false-green-prone); interaction as
  binary gate (an LLM scoring a static PNG can't observe hit-test/scroll/focus). Sources: Playwright
  accessibility-testing docs; axe-playwright npm.
- **Fixture cohort** — concluded a single declarative persona spec with mechanical per-consumer
  builders, library-purity preserved via test-only path dep; gallery viewport structural-only to
  avoid the 324-cell explosion. Sources: Storybook CSF / writing-stories.
- **Bucket-A closure** — concluded audit-first + executable manifest (the only option CI keeps
  honest against traceability-doc drift); classified all 24 defects into ~18 already-guarded (cited)
  vs ~6 net-new residue.

Deferred to plan-phase research (ROADMAP already flags it): the exact `@axe-core/playwright` 4.11.x
`AxeResults.violations[]` wire shape + harness compatibility. Directional format is LOCKED.
