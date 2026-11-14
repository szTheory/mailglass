# Rolling UI milestone proposal

2026-10-26. **Upstream proposal only.** No milestone active; no version, requirement IDs, phase counts, task plans or execution assigned. [UPSTREAM-SCOPE.md](UPSTREAM-SCOPE.md) is the current authority and OpenGSD handoff. This short projection refines the earlier Delivery-first phase-shaped proposal after the owner's live review.

## Recommended rolling sequence

| Envelope | User outcome | Scope and stopping boundary |
|---|---|---|
| **Next: recorded UX repairs + faithful Storybook** | Operators understand Health, filter both lists directly, inspect useful evidence and recover safely; authors choose/edit previews coherently. Repaired areas use real production rendering in stories. | Resolve the named [current feedback](../../todos/2026-10-26-owner-review-health-preview-controls.md) and unresolved [earlier feedback](../../todos/2026-10-25-owner-review-pr302-ui-feedback.md). Fix mount/font/theme/hook fidelity and retain scenarios/real-route proof alongside repairs. Stop when feedback is resolved and reproducible, not when the app is fully storied. |
| **Following: whole-job scenario depth** | Maintainers zoom from supported jobs into areas, patterns and components, reproducing real states without rebuilding incidents. | Expand high-value Delivery/Inbound/Preview and author/recipient cases, representative projection parity and useful Gallery migration. Start with three existing cohorts; new profiles need a distinct risk. Stop at diminishing returns and measured maintainability. |
| **Conditional later: consolidate and maintain** | One canonical inventory with little duplication, bounded review and trustworthy feedback. | Account for old cases/assertions, keep compact curation notes, measure runtime. Retain the documented package route pending compatibility disposition. This can be ordinary closeout rather than another milestone. Quiet maintenance is acceptable. |

Only the next envelope is ready for formal scoping. OpenGSD owns requirements, phases/plans, estimates, detailed design, execution and verification. If it needs splitting, retain a destination/rationale for every feedback item and trim speculative infrastructure before deferring known repairs.

## Named feedback belongs near the front

- Health hierarchy and grouped freshness/refresh, preserving actionable issues and deep links.
- Auto-apply filters on **both** collections with URL/Back/focus behavior; custom dates separate.
- Quiet quick-view arrows; discoverable, truthful replay; X-close, requested success toast and clear in-dialog error/retry outcomes.
- Complete ordinary authorized Inbound addresses, useful technical detail and coherent raw-source presentation; sensitive raw/trace policies separate.
- Consistent suppression Refresh/Retry and user-facing copy, without unproved auto-freshness or a nonexistent removal action.
- Preview reset/helper text and readable scenario/module identity; compact Account control and coherent shell without a fake Preview picker.
- Storybook navigation preserving /dev, production typography/assets/themes/hooks, then stories beyond primitives.

Detailed decisions and tradeoffs: [scope brief](UPSTREAM-SCOPE.md), [product](SCOPING-PRODUCT.md), [engineering](SCOPING-ENGINEERING.md), [evidence](SCOPING-EVIDENCE.md). These are scope inputs, not implementation authorization in this session.

## Minimum acceptance direction

Use **repair + retained realistic story + proof at the real affected boundary**. Cover relevant normal/error/empty/stale/permission/content cases; light/dark; narrow/wide/content-container widths; keyboard/focus and applicable System/motion/real-zoom behavior. Preserve account/auth/replay/rendering contracts. Fresh comparisons and expected/executed counts underpin new ratchet claims.

No exhaustive screenshot grid, six-profile quota, wholesale extraction, generic fixture/view framework, paid CI judge or new dependency is prerequisite. Provisional extra CI budget: **≤5 wall minutes / ≤10 runner-minutes including setup**, pending measurement. Ecto demo startup still needs Postgres. Owner review addresses judgment; machines close observable acceptance under D-52.

## Exclusions and downstream questions

Next-envelope exclusions: rebrand, capability/provider growth, custom dates, account-aware Preview, interactive unsubscribe submission, Gallery-route deletion, CI-wide redesign and comprehensive catalogue migration. F7 token-route mounting is a named following-envelope candidate.

Resolve downstream: Health composition; selector/action hierarchy; shared presentation/hook seams; filter history; whether same-Account return warrants a narrow host navigation capability; measured gate placement. No broad interview to reconfirm filter/address directions.

## Inspection environment

Review stack: Compose project mailglass-storybook-review; HTTP 4015, Postgres 5415. Direct stat cards: http://localhost:4015/dev/storybook/primitives/stat_card. Theme Picker workaround: http://localhost:4015/dev/storybook/primitives/theme_picker. Mount-prefix/serif defects remain unfixed; a recorded launch does not guarantee future uptime.

Stop only this stack, retaining data/build caches:

```sh
COMPOSE_PROJECT_NAME=mailglass-storybook-review docker compose -f compose.demo.yml down
```

Owner WIP remains untouched. No official ROADMAP/REQUIREMENTS, product/dependency files changed. No publication, merge or deployment follows from this proposal.
