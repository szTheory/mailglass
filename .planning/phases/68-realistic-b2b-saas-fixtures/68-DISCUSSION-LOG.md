# Phase 68: Realistic B2B SaaS Fixtures - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-06-01T21:03:01Z
**Phase:** 68-realistic-b2b-saas-fixtures
**Mode:** assumptions
**Areas analyzed:** Fixture Scope, Data Shape, Mailables, Inbound/Replay Semantics, Verification

## Assumptions Presented

### Fixture Scope
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Expand the existing `MailglassDemo.DemoData` seed/reset path rather than replacing it with a separate fixture framework. | Likely | `reference/demo_app/lib/mailglass_demo/demo_data.ex`; `reference/demo_app/mix.exs`; `reference/demo_app/priv/repo/seeds.exs` |

### Data Shape
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Deepen the existing Northstar Ops story with more realistic rows, not broaden into a provider matrix. | Likely | `.planning/REQUIREMENTS.md`; `.planning/ROADMAP.md`; `reference/demo_app/lib/mailglass_demo/demo_data.ex` |

### Mailables
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Keep demo mailables under `MailglassDemoWeb.Mailers.*` and use public `Mailglass.Mailable` / `Mailglass.Message` APIs only. | Confident | `reference/demo_app/lib/mailglass_demo_web/mailers/account_mailer.ex`; `reference/demo_app/lib/mailglass_demo_web/mailers/billing_mailer.ex`; `reference/demo_app/lib/mailglass_demo_web/mailers/operations_mailer.ex`; `.planning/phases/67-demo-app-foundation/67-CONTEXT.md` |

### Inbound/Replay Semantics
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Seed inbound truth through package-owned record/evidence/execution-run insertion helpers while preserving stored-truth semantics and explicit fresh versus replay lineage. | Likely | `reference/demo_app/lib/mailglass_demo/demo_data.ex`; `mailglass_inbound/lib/mailglass_inbound/inbound_records.ex`; `mailglass_inbound/lib/mailglass_inbound/inbound_records/execution_run.ex` |

### Verification
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Add focused deterministic seed/reset and mailer preview coverage, leaving browser journey evidence to Phase 70. | Confident | `reference/demo_app/test/mailglass_demo/demo_data_reset_test.exs`; `.planning/REQUIREMENTS.md`; `.planning/ROADMAP.md` |

## Corrections Made

No corrections - all assumptions confirmed.
