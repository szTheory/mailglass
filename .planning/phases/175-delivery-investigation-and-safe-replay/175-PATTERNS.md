# Phase 175: Delivery Investigation and Safe Replay - Pattern Map

**Mapped:** 2026-10-27  
**Files/seams classified:** 28 classification entries, including one new composed story with filename undecided  
**Analogs found:** 27 / 28 (the new composed job story has a component-story analog, but no exact composition analog)

## File Classification

| New/Modified File or seam | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `mailglass_admin/lib/mailglass_admin/operator_live.ex` | controller / LiveView | event-driven, request-response | same module replay and suppression handlers | exact |
| `mailglass_admin/lib/mailglass_admin/inbound_live.ex` | controller / LiveView | event-driven, request-response | same module replay handlers | exact |
| `mailglass_admin/lib/mailglass_admin/operator/quick_view.ex` | component | transform | sibling Inbound quick view; see 174-PATTERNS | exact sibling |
| `mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex` | component | transform | sibling Delivery quick view; see 174-PATTERNS | exact sibling |
| `mailglass_admin/lib/mailglass_admin/operator/replay_action.ex` | component | transform | same module eligibility/evidence panel | exact |
| `mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex` | component | event-driven | Inbound replay modal | sibling |
| `mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex` | component | event-driven | Delivery replay modal | sibling |
| `mailglass_admin/priv/static/hooks.js` | utility / hook | event-driven | `ModalFocusTrap` hook | exact |
| `mailglass_admin/lib/mailglass_admin/controllers/assets.ex` | controller / asset bridge | event-driven | `mailglass:toast` listener and hook bootstrap | exact |
| `mailglass_admin/lib/mailglass_admin/layouts/root.html.heex` | component / layout | event-driven | `mg-copy-toast` status region | exact |
| `mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex` | component | request-response | same card read-state branches | exact |
| `mailglass_admin/lib/mailglass_admin/components.ex` | component / utility | transform | `technical_details/1`, `data_state/1` | exact |
| `mailglass_admin/lib/mailglass_admin/operator/detail_header.ex` | component | transform | Inbound detail header | sibling |
| `mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex` | component | transform | Delivery detail header | sibling |
| `mailglass_admin/lib/mailglass_admin/operator/repair_state.ex` | utility | transform | availability and command-result copy | exact |
| `lib/mailglass/operator/suppressions.ex` | service / model query | request-response | tenant-scoped suppression read | exact |
| `lib/mailglass/operator/replay_targets.ex` | service / model query | request-response | exact Delivery replay-target list | exact |
| `lib/mailglass/webhook/replay.ex` | service / command | request-response | exact outbound replay command | exact |
| `mailglass_admin/test/mailglass_admin/operator_live_test.exs` | test | request-response | existing suppression/replay tests | exact |
| `mailglass_admin/test/mailglass_admin/inbound_live_test.exs` | test | request-response | existing Inbound replay tests | exact |
| `mailglass_admin/test/mailglass_admin/components_test.exs` | test | transform | shared component assertions | exact |
| `mailglass_admin/test/mailglass_admin/inbound/components_test.exs` | test | transform | Inbound detail component assertions | exact |
| `mailglass_admin/test/mailglass_admin/auth_actions_contract_test.exs` | test / guard | request-response | existing authorization contract guard | exact |
| `mailglass_admin/e2e/flows.spec.js` and `structural.spec.js` | test | request-response | existing keyboard/focus and route DOM flows; see 174-PATTERNS | exact behavior |
| `reference/persona_spec/quick_view_scenarios.ex` and `.json` | fixture / config | transform | retained synthetic scenario manifest/builders | exact |
| `reference/demo_app/storybook/quick_views/delivery.story.exs` | provider / component story | transform | existing production Delivery quick-view story | role-match |
| New composed Delivery investigation Storybook story (name TBD) | provider / component story | transform | existing Delivery story above | role-match; composition gap |
| `reference/demo_app/assets/e2e/outbound-replay.spec.js` | test | request-response | connected replay and durable audit assertion | exact |

All named existing source and test paths above were confirmed with `git ls-files`; no `.gsd` runtime mirror paths are used. New story filename is intentionally not guessed.

## Pattern Assignments

### Replay entry and action-time checks — both LiveViews

Outbound freezes the selected target and review ID when opening review, then rereads the Delivery and exact target, resolves the frozen selection, authorizes, and invokes the established command. Extend its presentation state while preserving this sequence (`operator_live.ex:381-401,509-558`):

```elixir
{:ok, socket} <-
  DestructiveAction.authorize(
    socket,
    socket.assigns.operator_auth[:adapter],
    delivery,
    target
  ),
{:ok, result} <-
  Replay.execute(%{
    tenant_id: tenant_id,
    delivery_id: delivery_id,
    webhook_event_id: target.webhook_event_id,
    actor: socket.assigns.operator_actor
  }) do
```

Inbound has a distinct frozen review shape (`inbound_live.ex:363-382`) and fresh check (`:1145-1208`): retain `{tenant_id, record_id, eligibility}`, reject tenant/selection/eligibility changes, reread the same record and recorded Mailbox, authorize, then call the existing gateway (`:1018-1029,1264-1269`). Do not unify outbound webhook and inbound Mailbox command/result semantics.

### Domain-specific replay dialogs and shared focus behavior

Keep `Operator.ReplayModal` and `Inbound.ReplayModal` as separate wrappers. Their explanatory copy and identity fields are domain-specific (`operator/replay_modal.ex:31-69,112-129`; `inbound/replay_modal.ex:24-79,94-116`). Keep the shared `ModalFocusTrap` hook, start/end sentinels, Escape event, close control, and LiveView focus-return sentinel. The tracked hook is `mailglass_admin/priv/static/hooks.js:1-25`; the wrappers already contain the sentinel markup. LiveView focus returns through `operator_live.ex:1068-1093` and `inbound_live.ex:851-855`.

For feedback, add/retain a dialog-local `role="status"`/`aria-live="polite"` region and explicit retry/re-review action. Current outbound failure branches write flash while leaving the modal mounted (`operator_live.ex:563-614`); Inbound stale/auth/command failures close it and flash (`inbound_live.ex:1037-1079`). Treat these as the implementation gap, not the error pattern to copy. Keep command failures in the open dialog and require fresh eligibility before confirmation.

### Toast and result reporting

The existing toast bridge is `push_event(socket, "mailglass:toast", %{message: message, error: ...})` (`operator_live.ex:489-494`), handled by `assets.ex:227-245`; the root layout exposes the accessible `role="status"`, `aria-live="polite"`, `aria-atomic="true"` region (`layouts/root.html.heex:31-43`). Send success through this event and keep modal close behavior. Outbound result copy distinguishes newly normalized Events from no-op (`operator/repair_state.ex:77-87`). Inbound result copy describes the recorded Mailbox outcome (`inbound_live.ex:1082-1107`); refresh of its selected timeline stays explicit (`:1109-1120`).

### Scoped suppression and truthful state

Reuse the current server read call and tenant, recipient, and stream context (`operator_live.ex:1375-1394`); the service filters by `tenant_id` and expiry before matching (`lib/mailglass/operator/suppressions.ex:17-52`). Preserve prior facts when refresh fails, but render them as stale; without prior facts use unavailable. Keep the card read-only, with the existing refresh action (`operator/suppression_card.ex:39-49,96-110`). Use the shared `Components.data_state/1` kind vocabulary (`components.ex:710-752`) where its presentation fits. Existing retry/state test starts at `operator_live_test.exs:491`.

### Technical details open by default

`Components.technical_details/1` already selects `details` versus `div` from `collapsible` and wraps values (`components.ex:584-609`). Full Delivery and Inbound headers currently set the prop based on identifier availability (`operator/detail_header.ex:60-87`; `inbound/detail_header.ex:83-97`). Set the full-detail calls non-collapsible; preserve the component default and quick-view implementations, which already pass `collapsible={false}`.

### Synthetic scenario to production Storybook

Use `MailglassDemo.QuickViewScenarios` and its retained JSON manifest as the synthetic fact source (`reference/persona_spec/quick_view_scenarios.ex:11-16,18-56`); builders add the real component assign/route contract. Existing `Storybook.QuickViews.Delivery` renders `MailglassAdmin.Operator.QuickView.quick_view/1` in an iframe and references these scenario builders (`reference/demo_app/storybook/quick_views/delivery.story.exs:1-8,32-50`). Build the composed investigation scenario from production components and those bounded synthetic facts. A Storybook variation documents composition only; connected review, authorization, toast, and persisted result stay in browser/EUnit evidence.

### Connected verification and retained evidence

Extend the current Admin ExUnit suites listed above; relevant seams include outbound retained-match failure (`operator_live_test.exs:491`), unavailable and fresh-review paths (`:909-1217`), and Inbound command/result behavior (`inbound_live_test.exs:1300-1387,1580-1600`). Extend the connected Admin Playwright route/focus approach in `flows.spec.js` and `structural.spec.js`; 174-PATTERNS.md records the existing quick-view keyboard/focus and measured-target helpers. Extend `reference/demo_app/assets/e2e/outbound-replay.spec.js:19-74` to assert the success toast while preserving its current command path, modal-close, and durable replay audit/event assertions. Keep the existing auth-action guard and demo grant unchanged. Use the existing scenario manifest and test evidence; no generic fixture framework or evidence runner is needed.

## Shared Patterns

| Concern | Source and use |
|---|---|
| Fresh authorization | Both host LiveViews own exact-record revalidation and `DestructiveAction.authorize`; quick views dispatch the same handler for the server-selected record. Never trust a client-supplied target or skip the action-time read. |
| Focus | Domain modal markup + tracked `ModalFocusTrap` hook + originating trigger focus sentinel. Preserve exact trigger return when adding quick-view entry points. |
| Toast | `mailglass:toast` event and root status region; use for success announcements, while failed/stale/denied review is shown inside the mounted modal. |
| State copy | `RepairState` and suppression card map structured states/results to operator language. Keep data-state semantics aligned with ready/empty/stale/unavailable and do not infer expiry or a new delivery. |
| Evidence | Storybook uses synthetic data and production components; connected Admin/demo Playwright paths establish interaction, auth, persistence, and Account/list-context behavior. |

## No Exact Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| New composed Delivery investigation Storybook story (filename TBD) | provider / component story | transform | Existing `delivery.story.exs` is a production quick-view story, but no retained story composes the complete technical facts + suppression + replay-review job. Use that story and the existing scenario builder as the nearest patterns; keep behavioral proof in connected tests. |

## Metadata

**Analog search scope:** Only the Phase 175 source/test seams named in `175-RESEARCH.md` and `175-UI-SPEC.md`, plus related patterns recorded in `174-PATTERNS.md`.  
**Tracked-source gate:** All existing analogs verified with `git ls-files`.  
**Pattern extraction date:** 2026-10-27
