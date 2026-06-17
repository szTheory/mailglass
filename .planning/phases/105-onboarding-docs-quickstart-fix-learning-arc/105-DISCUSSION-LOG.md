# Phase 105: Onboarding Docs — Quickstart Fix + Learning Arc - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-17
**Phase:** 105-onboarding-docs-quickstart-fix-learning-arc
**Mode:** assumptions
**Areas analyzed:** DOCS-01 (README quickstart), DOCS-02 (getting-started Next steps),
DOCS-03 (learning-path index), DOCS-04 (migration-from-swoosh "why" opener)

## Assumptions Presented

### DOCS-01 — README Quickstart Config-First
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Insert config-first block into README Quickstart before the deliver example; reuse getting-started:24-32 verbatim; frame as installer-generated; add a contract assertion for `config :mailglass`/`repo:`/`adapter:` | Confident | `README.md:86-122` has no config block before `Mailglass.deliver()`; `guides/getting-started.md:24-32` is the working snippet; `docs_contract_test.exs:108-114` is the mirror pattern |

### DOCS-02 — getting-started Next steps
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Reorder so guide ends on a new `## Next steps` arc (jobs→authoring→preview→webhooks→testing→operate); keep troubleshooting before it; update the 401 entry for Phase 104 fail-closed/`--force`/`mix mailglass.doctor` | Confident | `getting-started.md:89-104` currently ends on troubleshooting; 104-CONTEXT.md D-06 hands the `--force` guide prose to 105 |

### DOCS-03 — learning-path index
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Create standalone `guides/learning-path.md`; register in BOTH `mix.exs` extras + groups_for_extras(Guides); link from README index + Next steps; README index stays a flat link list | Confident | `mix.exs:383-427` shows both lists; v1.12 docs guardrail mandates BOTH registrations; 17 guides currently unordered |

### DOCS-04 — migration-from-swoosh "why" opener
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Add value-prop opener (transport vs framework layer: preview/webhooks/audit ledger/suppressions/multi-tenancy) above current line-3 deferral; keep canonical-lane pointers; add a keyword+ordering contract assertion | Confident | `migration-from-swoosh.md:1-11` opens with a subordinate-reference deferral, not a pitch |
| Fix stale `~> 0.3` dep pins in the same guide to `~> 1.x` | Likely | `migration-from-swoosh.md:26-27` pin `~> 0.3`; not covered by the dynamic README-pin test |

## Corrections Made

No corrections — user selected "Yes, proceed"; all four DOCS assumptions plus the two Likely
items (fix stale migration pins; gating shape = planner's discretion) confirmed as locked.

## External Research

None — entirely internal docs work against a known contract mechanism
(`docs_contract_test.exs` + `docs_helpers.ex`). `needs_research` empty; external_research step
skipped.
