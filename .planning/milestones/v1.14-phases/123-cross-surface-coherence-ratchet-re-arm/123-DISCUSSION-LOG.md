# Phase 123: Cross-surface coherence + ratchet re-arm - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-28
**Phase:** 123-cross-surface-coherence-ratchet-re-arm
**Mode:** assumptions
**Areas analyzed:** Re-score mechanics, Arming the judgment gates, Cross-surface coherence proof artifact, Storybook + gallery finalization, Asset/persona/paired-test landmines

## Assumptions Presented

### Re-score mechanics (COH-02)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| JSON-only promotion: copy current→prior, new current.run_id, LLM re-score fresh current, only-forward meet-or-beat | Confident | `ratchet_baseline_test.exs:46-62,85-92,97-124`; `ui-baseline-scores.json:35` still `run_id 2026-06-20-phase-116` |
| Only 3 record-surfaces scored (54 cells); overview/shell NOT a baseline surface | Confident | `ratchet_baseline_test.exs:26` hardcoded `@surfaces` |

### Arming the judgment gates (COH-02 / METHOD-02)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Gates already execute green in CI; arming = de-disclaim + document, not wire | Confident | `playwright.config.cjs` testDir globs e2e; `ci.yml:643-714` required lane runs `test:operator-browser`; gate names in 0 yml/0 sh files; live `test(` at `judgment.spec.js:76,103` |
| No `ci.yml` change; NOT in `check-conformance.sh` (grep can't read rendered nav state) | Confident | D-11 chose rendered-DOM Playwright; conformance is grep-based |

### Cross-surface coherence proof artifact (COH-01)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Persona-critic re-run + DEFECT-REGISTER Status closures + maintainer sign-off; no new automated coherence gate | Likely | MILESTONE-SEED method (critics+sign-off catch what gates can't); DEFECT-REGISTER per-finding `Status:` ledger + Phase 123 consumption note |

### Storybook + gallery finalization (COH-01)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| gallery byte-unchanged; D-STORYBOOK-BRAND accept indigo (dep CSS, not themeable via css_path); D-STORYBOOK-STALE-BOOT docs-only; story-inventory consistency check | Likely | DEFECT-REGISTER marks both Low/dev-only; indigo in dep `priv/static/css/phoenix_storybook-*.css`; `storybook.ex` title/sandbox already set |

### Asset / persona / paired-test landmines
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| No committed bundle rebuild (TokenParity trap); persona re-shoot is evidence only; axe needs no re-shoot | Confident | 118-CONTEXT:186-187 landmine; `axe-baseline.json` run_ids both 2026-06-21; persona-drift-guard treats `Personas.spec/0` as SSOT |

## Corrections Made

No corrections — user selected "Yes, proceed"; all five areas confirmed as presented.

## External Research

Not performed. The lone codebase-unsettleable point (whether phoenix_storybook v1.2 exposes an
explorer-chrome theming hook) is non-blocking: the decisive default — accept the indigo as a dev-only
cosmetic per the DEFECT-REGISTER fix-direction — holds regardless of the answer, and chasing it via dep-CSS
edits or a Node build is explicitly banned. Folded into D-09 rather than spending a research round.
