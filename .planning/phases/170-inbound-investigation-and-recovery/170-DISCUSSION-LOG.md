# Phase 170: Inbound Investigation and Recovery - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-10-08
**Phase:** 170-inbound-investigation-and-recovery
**Mode:** assumptions
**Areas analyzed:** Account context and exact selection; empty/unavailable states; routing and execution truth; evidence privacy; replay eligibility and confirmation; replay results and retained history; accessibility and dependency posture

## Analysis method

Three parallel read-only reviews examined code/contracts, operator/support/design/accessibility, and security/privacy/reliability. The orchestrator checked project and prior-phase context, source, relevant tests, and official primary guidance. No files were written by the reviewers and no tests were run.

## Assumptions Presented

### Account context and exact selection
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Preserve Account, filters, page, selected record, and view state; resolve exact IDs within the selected Account independently of the current list; distinguish unavailable states. | Likely | mailglass_admin/lib/mailglass_admin/inbound_live.ex; mailglass_inbound/lib/mailglass_inbound/internal/operator/detail.ex; Phase 170 roadmap criteria |

### Routing and execution truth
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Persisted run/binding data is historical evidence; label the trace as a current-router simulation; align the list and detail headline on latest fresh execution. | Confident | mailglass_admin/lib/mailglass_admin/inbound/routing_trace.ex; mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex; detail.ex; timeline.ex |

### Evidence disclosure and privacy
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Keep raw provider data redacted behind existing reveal authorization; expose only selected safe facts and apply a field-level policy to route/header/subject values. | Likely | mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex; routing_trace.ex; inbound_live.ex; mailglass_inbound inbound evidence schema |

### Replay eligibility and confirmation
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Determine eligibility from durable evidence and a resolvable Mailbox; re-resolve exact Account scope and authorize at confirmation; prevent duplicate local submissions. | Likely | mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex; inbound_live.ex; destructive_action.ex; mailglass_inbound/lib/mailglass_inbound/internal/replay.ex |

### Replay meaning
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Replay executes the recorded Mailbox identity with current deployed code; it does not establish provider delivery or reproduce historical code. | Confident | mailglass_inbound/lib/mailglass_inbound/internal/replay.ex; execution.ex; mailglass_admin/docs/operator-trust.md |

### Replay results and no-change
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Separate a recorded run from its Mailbox outcome. Show requested/queued/no-change only when an authoritative inbound fact supplies that state; never infer no-change from :ignore. | Confident | mailglass_inbound/lib/mailglass_inbound/execution.ex; internal/replay.ex; mailglass_admin/lib/mailglass_admin/inbound_live.ex; mailglass_admin/docs/operator-trust.md |

### Accessibility and dependency posture
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Reuse existing LiveView/HEEx and native semantic controls; preserve shared keyboard, focus, status, theme, responsive, and reduced-motion decisions; add no dependency without a demonstrated gap. | Confident | Phase 168 context/UI-SPEC; mailglass_admin inbound components; Phoenix LiveView, W3C WAI/WCAG guidance |

## Corrections Made

The owner first approved adding a narrow inbound-internal no-change result while preserving stable public APIs. Code inspection then confirmed that no internal source exists: the stable `MailglassInbound.Mailbox.process/1` callback currently accepts only `:accept`, `:ignore`, `{:reject, reason}`, and `{:bounce, reason}`. The owner approved the smallest source-backed resolution: add an explicit, additive `:no_change` callback outcome and persist it through the existing ExecutionRun outcome path. Existing outcomes keep their meanings; no-change must never be inferred from `:ignore`, an unchanged projection, or a reread. This approved exception is recorded as D-16 in CONTEXT.md under D-15's concrete-requirement allowance.

The independent plan check found two remaining research questions. Planning resolved the read-failure boundary as D-17: only explicit gateway errors and `DBConnection.ConnectionError` (including queue timeout) render an unavailable state, while other exceptions propagate. Source inspection found no selected-record completion PubSub signal; existing insertion PubSub and execution telemetry do not provide one, so D-18 uses a timestamped history snapshot plus explicit refresh and adds no polling or signal. These decisions are recorded in CONTEXT.md and the revised plan tasks.

## External Research

- Phoenix LiveView 1.2.12: push_patch/2 invokes handle_params/3 for URL-backed state within the current LiveView. https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html
- W3C ARIA Authoring Practices Guide: disclosure control uses button semantics, Enter/Space, and truthful aria-expanded state. https://www.w3.org/WAI/ARIA/apg/patterns/disclosure/
- W3C WCAG 2.2, Success Criterion 4.1.3: action results and waiting/error states can be announced as programmatic status messages without moving focus. https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html
- OWASP Authorization Patterns: enforce close to the protected resource, check action/object/tenant, and validate permission on each request. https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Patterns_Cheat_Sheet.html
- OWASP Logging Cheat Sheet: mask or sanitize sensitive personal data and secrets in logs. https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html
- Rails Action Mailbox: explicit inbound processing statuses are a useful ecosystem comparison; its async job and retention defaults are not adopted. https://guides.rubyonrails.org/action_mailbox_basics.html
