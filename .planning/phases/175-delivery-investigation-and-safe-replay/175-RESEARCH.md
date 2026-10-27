# Phase 175: Delivery Investigation and Safe Replay - Research

**Researched:** 2026-10-27  
**Domain:** Phoenix LiveView operator workflows, scoped suppression reads, outbound webhook replay, inbound Mailbox replay, retained Storybook scenarios  
**Confidence:** HIGH for current code and test seams; MEDIUM for design recommendations and external ASVS mapping

## User Constraints

CONTEXT.md is intentionally absent. Use the approved roadmap and requirements as the scope source.

- Roadmap planning focus: “Keep the already-fixed demo grants, auth-action contract guard and replay-success e2e completed. Share presentation, not outbound/inbound command semantics. Isolated stories cannot prove replay execution, authorization or persisted outcomes. Existing list filters can support the early job; new auto-apply behavior follows in Phase 176.” [VERIFIED: .planning/ROADMAP.md:135]
- Project boundary: preserve brand, domain, authorization, Account, exact replay, and rendering contracts; add no generic view/fixture framework or capability/provider growth. [VERIFIED: .planning/PROJECT.md:27]
- Phase assignment constraint: no generic fixture framework, new APIs/providers, auto-apply filters (Phase 176), or weakening gates.
- Keep changes within the approved Admin and demo/story/evidence envelope; preserve existing dependencies and add no public API or provider surface. [VERIFIED: .planning/PROJECT.md:27; .planning/ROADMAP.md:135]

## Summary

Phase 175 should complete one connected Delivery investigation path and carry the same replay-dialog quality into Inbound. Reuse the current host LiveViews, tenant-scoped read models, replay commands, auth adapters, toast surface, and tests. The most direct changes are: render full-detail technical groups open by default; put a reachable replay entry in both quick views; make unavailable outbound replay informational rather than an enabled CTA; distinguish stale last-known suppression data from a wholly unavailable read; and keep stale/denied/failed replay feedback in the dialog or provide an explicit re-review route.

The safety backend is already substantial. Outbound freezes the exact selected target, rereads the selected Delivery and target at confirmation, authorizes through the host, and calls the existing replay command. Inbound separately freezes the selected record and recorded Mailbox eligibility, then rereads and authorizes before its command. Preserve these distinct command and outcome contracts. Success must use the existing accessible toast event; outbound evidence distinguishes new work from no change, while Inbound describes the recorded Mailbox outcome and must not claim a new inbound provider delivery. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex:509-558; mailglass_admin/lib/mailglass_admin/inbound_live.ex:1018-1107; lib/mailglass/webhook/replay.ex:23-36]

**Primary recommendation:** Add presentation affordances and truthful in-dialog state around the existing exact-review/action-time authorization paths; validate them in focused LiveView tests and one connected Delivery E2E, while retaining a composed production-component Storybook scenario for layout review.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|---|---|---|---|
| Delivery/Inbound list selection, URL/Account/filter preservation, dialog state | Frontend Server (LiveView) | Browser / Client | LiveViews already own params, selection, event handlers, assigns, and focus-return sentinels. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex:623-636,1068-1093; mailglass_admin/lib/mailglass_admin/inbound_live.ex:851-855] |
| Suppression refresh and replay eligibility | API / Backend | Database / Storage | Existing read models use tenant-scoped queries; keep the selected Account and record IDs at the server boundary. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex:1375-1394; lib/mailglass/operator/replay_targets.ex:15-29,47-65] |
| Replay authorization, idempotency, audit, and durable result | API / Backend | Database / Storage | Existing commands own effects and durable records; the LiveView should present their outcome, not reproduce their rules. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex:526-558; mailglass_admin/lib/mailglass_admin/inbound_live.ex:1018-1029; lib/mailglass/webhook/replay.ex:63-105,277-294] |
| Dialog keyboard/focus, close affordance, toast announcement | Browser / Client | Frontend Server (LiveView) | Existing ModalFocusTrap hook, LiveView focus sentinels, and server-toast event provide the base behavior. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex:31-50; mailglass_admin/lib/mailglass_admin/controllers/assets.ex:227-245] |
| Retained composed Delivery scenario | Browser / Client (Storybook) | Frontend Server (LiveView) | Storybook renders production components for static review; connected proof must remain a real LiveView/browser path. [VERIFIED: reference/demo_app/storybook/quick_views/delivery.story.exs:1-8,32-50; .planning/ROADMAP.md:126,135] |

## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| UXF-12 | An operator opening full Delivery or Inbound detail can read grouped technical evidence below primary facts without first expanding a disclosure. | Both full-detail headers pass a condition that renders identifiers inside a collapsed details disclosure; the shared component supports a non-collapsible rendering. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator/detail_header.ex:60-87; mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex:83-97; mailglass_admin/lib/mailglass_admin/components.ex:584-609] |
| OUTUX-07 | An operator can refresh suppression evidence and retry a failed read through a consistently placed action with truthful ready, empty, stale and unavailable outcomes. | Reuse the existing scoped suppression read and refresh action; preserve old data on failed reads but label it stale when present. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex:464-479,1375-1394,1477-1491; mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex:39-49,96-110] |
| OUTUX-08 | An operator can understand suppression expiry and supported removal in plain language, without an invented removal button or treating unknown expiry as never expiring. | Keep this card read-only; improve copy for unknown expiry and supported/blocked policy without adding a mutation control. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex:80-110,136-144] |
| REPLAY-04 | An operator can enter replay review from either quick view as well as full detail for the exact selected eligible record. | Full detail already has exact review; quick views currently lack an entry point. Reuse the same server handler and target resolution. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator/quick_view.ex:1-241; mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex:1-215; mailglass_admin/lib/mailglass_admin/operator_live.ex:381-401; mailglass_admin/lib/mailglass_admin/inbound_live.ex:359-382] |
| REPLAY-05 | An operator can understand why replay is unavailable before opening a dialog, without a dead-end primary replay action. | The outbound full-detail component currently always renders its primary button. Gate it on the exact availability state and show reason copy without a CTA when unavailable. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator/replay_action.ex:21-64; mailglass_admin/lib/mailglass_admin/operator/repair_state.ex:8-14,52-68] |
| REPLAY-06 | An operator can review a concise, identifiable stored request in a shared accessible dialog with X-close, Escape, focus containment/return and a clearly labelled primary action. | Keep outbound stored webhook identity and Inbound recorded Mailbox identity distinct; share only dialog shell/presentation and keyboard behavior. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex:31-69,112-129; mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex:24-79,94-116; mailglass_admin/lib/mailglass_admin/operator_live.ex:1078-1093; mailglass_admin/lib/mailglass_admin/inbound_live.ex:851-855] |
| REPLAY-07 | An operator completing a permitted replay sees the dialog close, an accessible success toast and updated evidence reflecting the actual domain outcome. | Reuse the existing toast event. Preserve outbound new-work/no-change counts and Inbound recorded run outcome; do not invent Events or provider delivery. [VERIFIED: mailglass_admin/lib/mailglass_admin/controllers/assets.ex:227-245; mailglass_admin/lib/mailglass_admin/operator/repair_state.ex:77-87; mailglass_admin/lib/mailglass_admin/inbound_live.ex:1082-1107] |
| REPLAY-08 | An operator whose replay fails sees an inline error in the open dialog and a safe retry or explained re-review path without flicker, hidden errors or an unexplained disabled-review dead end. | Outbound failure branches currently write flash feedback while the modal remains open; Inbound closes the modal for stale, auth, and command failures. Add visible dialog feedback and safe retry/re-review state without changing authorization. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex:559-614; mailglass_admin/lib/mailglass_admin/inbound_live.ex:1031-1079] |
| STORY-07 | A maintainer can find retained production-component pattern/area/job scenarios for each repair, including one complete Delivery investigation path and relevant reachable adverse states. | Add a narrowly scoped composed Delivery job story using production components and the existing synthetic-scenario source pattern; retain connected proof for actions and persistence. Phase 175 delivers the early complete path, while STORY-07 remains owned by Phase 178. [VERIFIED: reference/demo_app/storybook/quick_views/delivery.story.exs:1-50; reference/persona_spec/quick_view_scenarios.ex:1-56; .planning/REQUIREMENTS.md:160; .planning/ROADMAP.md:126,135] |

Requirement descriptions above are copied verbatim from [.planning/REQUIREMENTS.md:21,33-47,61]; the Phase 175 ownership boundary is explicit in [.planning/ROADMAP.md:124-130].

## Standard Stack

Use the existing stack and locks; no external package install is needed for this phase. [VERIFIED: .planning/PROJECT.md:27; mailglass_admin/package-lock.json:26-33; reference/demo_app/assets/package-lock.json:12-20]

| Existing technology | Locked version / role | Planning use |
|---|---|---|
| Phoenix LiveView | Admin lock: 1.2.13; demo lock: 1.1.33. [VERIFIED: mailglass_admin/mix.lock:38; reference/demo_app/mix.lock:39] | Keep list state, commands, authorization, and URL navigation in the existing LiveViews. |
| Phoenix Storybook | 1.2.0 in the demo lock. [VERIFIED: reference/demo_app/mix.lock:41] | Retain the composed static production-component scenario in the current demo Storybook. |
| Playwright | Admin lock: @playwright/test 1.59.1; demo lock: 1.60.0. [VERIFIED: mailglass_admin/package-lock.json:26-33; reference/demo_app/assets/package-lock.json:12-20] | Use the existing Admin browser harness for connected operator states and the existing demo replay E2E for the durable success path. |
| Existing Mailglass read/command modules | Scoped suppression read, outbound replay targets/command, Inbound eligibility/replay adapter. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex:1375-1394; lib/mailglass/operator/replay_targets.ex:15-29; mailglass_admin/lib/mailglass_admin/inbound_live.ex:1018-1029] | Reuse them. Add no public API, provider, or custom replay implementation. |

**Installation:** None. Keep lockfiles and dependencies unchanged.

**Package legitimacy:** Not applicable; the phase does not install external packages.

## Architecture Patterns

### System Architecture

    Operator
      -> DeliveryLive (Account, list selection, filters)
        -> tenant-scoped suppression read
        <- ready / empty / stale / unavailable evidence
        -> exact selected record and target
          -> replay review dialog
            -> fresh Delivery and target reread
              -> host authorization
                -> outbound replay command
                  -> durable Events, audit, projections
                    -> actual outcome -> detail refresh + accessible toast

    Operator
      -> InboundLive (Account and selected record)
        -> inbound replay review dialog
          -> reread record and recorded Mailbox eligibility
            -> host authorization
              -> distinct Inbound replay command
                -> recorded execution outcome
                  -> actual outcome -> command feedback + accessible toast

The two host LiveViews remain command owners. Outbound revalidation and authorization are already in sequence before Replay.execute; Inbound has a separate revalidation, authorization, and replay path. Share a small accessible dialog shell if useful, while keeping each domain's request identity, command, eligibility, and result copy separate. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex:526-558; mailglass_admin/lib/mailglass_admin/inbound_live.ex:1018-1071; .planning/ROADMAP.md:129-130,135]

### Recommended Project Structure

Keep additions next to the existing components and browser coverage:

    mailglass_admin/lib/mailglass_admin/operator/detail_header.ex       # full Delivery evidence
    mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex        # full Inbound evidence
    mailglass_admin/lib/mailglass_admin/operator/replay_action.ex       # truthful outbound availability
    mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex        # outbound dialog feedback
    mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex         # inbound dialog feedback
    mailglass_admin/lib/mailglass_admin/operator_live.ex                # list state, reads, auth, commands
    mailglass_admin/lib/mailglass_admin/inbound_live.ex                 # list state, auth, commands
    reference/demo_app/storybook/                                     # retained composed story
    mailglass_admin/e2e/flows.spec.js                                  # connected Admin path
    reference/demo_app/assets/e2e/outbound-replay.spec.js               # durable replay success proof

The paths above are existing source paths, not a proposed new framework. [VERIFIED: source files opened this session]

### Pattern 1: Keep scoped reads and effects in the host LiveViews

Outbound LiveView reads suppression from the selected Delivery recipient and stream plus the current Account; the read model scopes its query by tenant. Continue routing refresh through that seam. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex:1375-1394; lib/mailglass/operator/suppressions.ex:13-52]

    Suppressions.get_delivery_suppression_state(
      %{
        tenant_id: filter_params["tenant_id"],
        recipient: delivery.recipient,
        stream: delivery.stream
      },
      []
    )

For replay, add presentation state around the current selected record; do not pass a browser-supplied target directly to the command. Confirmation must keep the existing fresh read, snapshot comparison, host authorization, and domain command sequence. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex:526-558; mailglass_admin/lib/mailglass_admin/inbound_live.ex:1018-1029]

### Pattern 2: Retain a composed story from synthetic facts and production components

The Delivery quick-view story already points at the production quick-view function and obtains its assigns through the small QuickViewScenarios builder. Extend this style for a composed Delivery investigation example; do not turn the manifest into a universal fixture/view framework. Static story assertions cover visible composition only. [VERIFIED: reference/demo_app/storybook/quick_views/delivery.story.exs:1-8,32-50; reference/persona_spec/quick_view_scenarios.ex:1-5,18-56; .planning/ROADMAP.md:126,135]

    attributes = MailglassDemo.QuickViewScenarios.delivery(scenario_id)

### UX writing guidance

Use the requested ux-writing skill and the project voice: clear, exact, warm, technical, and actionable; name the cause and next step in errors, use a short imperative primary action, and avoid “Oops!” [CITED: /Users/jon/.agents/skills/ux-writing/SKILL.md; VERIFIED: CLAUDE.md:62-67]

- Outbound replay dialog should state that it reprocesses the stored webhook request and does not resend outbound mail. Keep target identity compact and scannable; remove repeated “selected target”/“reviewed request” framing.
- The close control should be a visible X with the accessible name “Close”; Escape, trap, and return focus to the exact trigger for both quick-view and full-detail entry.
- Keep current Mailglass match, other stores unchecked, expiry unknown, and removal policy in separate plain-language facts. Do not use “never expires” for a missing expiry.
- On failure, name the relevant problem and the safe next action inside the open dialog. A success toast should name the actual result: outbound new work or no change; Inbound recorded run outcome.

## Don't Hand-Roll

| Problem | Don't build | Reuse |
|---|---|---|
| Tenant/record replay eligibility | New controller, endpoint, target lookup, or browser-authoritative check | Existing ReplayTargets, Inbound eligibility read, action-time reread and host authorization. [VERIFIED: lib/mailglass/operator/replay_targets.ex:15-29; mailglass_admin/lib/mailglass_admin/operator_live.ex:526-545; mailglass_admin/lib/mailglass_admin/inbound_live.ex:1018-1027] |
| Replay idempotency and audit | New replay pipeline or fake “success Event” | Existing domain command, event idempotency key, audit/result transaction. [VERIFIED: lib/mailglass/webhook/replay.ex:63-105,277-294] |
| Accessible toast/focus trap | New JS dependency or duplicate notification layer | Existing mailglass:toast event and ModalFocusTrap/focus-return sentinels. [VERIFIED: mailglass_admin/lib/mailglass_admin/controllers/assets.ex:227-245; mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex:31-50; mailglass_admin/lib/mailglass_admin/operator_live.ex:1078-1093] |
| Suppression policy | A local UI query or removal mutation | Existing scoped suppression read; this UI remains read-only. [VERIFIED: lib/mailglass/operator/suppressions.ex:13-52; mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex:1-13,104-111] |
| Test fixtures/story runtime | Generic fixture system or a new Storybook framework | Existing deterministic scenario source/manifest and Phoenix Storybook. [VERIFIED: reference/persona_spec/quick_view_scenarios.ex:1-16; reference/demo_app/mix.lock:41] |

## Current State and Safe Reuse Seams

- Full Delivery passes collapsible=true when either Mailable or provider ID exists; full Inbound passes collapsible=true when provider ID exists. The shared technical_details component renders a details/summary when collapsible and a div when not. Set the full-detail headers to non-collapsible while leaving the generic component default and quick-view patterns alone. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator/detail_header.ex:60-87; mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex:83-97; mailglass_admin/lib/mailglass_admin/components.ex:584-609]
- Both production QuickView components omit replay entry; an existing test explicitly verifies outbound replay CTA appears only after full Delivery selection, and the Inbound structural browser test says replay lives in Full detail. Add a quick-view entry for the selected record in both domains and preserve list route/account/filter context. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator/quick_view.ex:115-170; mailglass_admin/lib/mailglass_admin/inbound/quick_view.ex:89-150; mailglass_admin/test/mailglass_admin/operator_live_test.exs:815-837; mailglass_admin/e2e/structural.spec.js:1416-1420; .planning/ROADMAP.md:126,128]
- ReplayAction currently renders “Review webhook replay” regardless of availability. RepairState already supplies exact/ambiguous/unavailable explanatory copy; render an action only for actionable states, with a non-action explanation for unavailable. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator/replay_action.ex:21-64; mailglass_admin/lib/mailglass_admin/operator/repair_state.ex:8-14,52-68]
- Suppression read failure retains a previously read match and marks the read unavailable; UI text already warns that the match may be out of date, but the badge remains “Unavailable.” Represent a retained match as stale, and use unavailable where there is no prior fact to display. Keep the existing retry action and read call; a successful manual read already reflects expiry or an external update. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex:464-479,1375-1394,1477-1491; mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex:39-49,80-110; lib/mailglass/operator/suppressions.ex:13-52]
- Outbound failures currently set flash while the modal remains mounted; this does not give a visible in-dialog error. Inbound closes its dialog on stale review, auth denial, and command error, then writes page feedback. Add a live region in each dialog and distinguish retryable read/command errors from stale/denied reviews that require a fresh explicit review. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex:559-614; mailglass_admin/lib/mailglass_admin/inbound_live.ex:1031-1079]
- The toast infrastructure already listens for the LiveView event and renders a role=status, aria-live page toast; outbound success currently assigns inline command feedback and closes the modal without pushing that toast. Reuse it for outbound and inbound success. [VERIFIED: mailglass_admin/lib/mailglass_admin/controllers/assets.ex:227-245; mailglass_admin/lib/mailglass_admin/layouts/root.html.heex:31-41; mailglass_admin/lib/mailglass_admin/operator_live.ex:553-558; mailglass_admin/lib/mailglass_admin/inbound_live.ex:1031-1036]
- The source declares the result statuses as follows:

      @type outcome_status :: :replayed | :noop

  Preserve the UI distinction between new normalized Events and zero new Events. [VERIFIED: lib/mailglass/webhook/replay.ex:24; mailglass_admin/lib/mailglass_admin/operator/repair_state.ex:27-49,77-87]
- Inbound result feedback describes a recorded Mailbox run. Keep the manual timeline refresh contract and do not fabricate a new provider Event or imply provider redelivery. [VERIFIED: mailglass_admin/lib/mailglass_admin/inbound_live.ex:1082-1107,1109-1120; .planning/PROJECT.md:1103-1111]
- The connected demo replay test already drives the production authorization and replay command, checks modal close and a durable replay audit row. Extend that proof with the requested toast; do not replace or loosen the existing assertions. [VERIFIED: reference/demo_app/assets/e2e/outbound-replay.spec.js:3-7,19-74]
- The current retained Delivery Storybook story is a quick-view-only production component story. Add one composed scenario for technical facts, suppression, and replay review in the Delivery investigation job; keep failure/retry actions in connected proof because stories cannot establish authorization or persistence. [VERIFIED: reference/demo_app/storybook/quick_views/delivery.story.exs:1-50; .planning/ROADMAP.md:126,135]

## Common Pitfalls

1. **Enabling a dead-end replay CTA.** Availability copy beside an always-enabled button still invites an action that cannot proceed. Ensure unavailable state has a reason and no primary replay trigger; test both quick view and full detail. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator/replay_action.ex:21-64]
2. **Calling retained facts current after a failed read.** If a previous match remains visible, label it stale and identify the read as unavailable; if no prior match exists, do not render the empty-ready state. Test the initial failure and retry success paths. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex:464-479,1463-1468; mailglass_admin/lib/mailglass_admin/operator/suppression_card.ex:39-49,96-101]
3. **Showing a global flash behind a modal.** Outbound currently leaves the modal open but writes failures to flash; Inbound closes the modal for failure. Render errors in the dialog and retain a usable retry or explicit re-review path. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex:563-613; mailglass_admin/lib/mailglass_admin/inbound_live.ex:1037-1071]
4. **Treating replay as mail delivery.** Outbound replay reprocesses a stored webhook and can add zero new Events; Inbound replay uses recorded Mailbox identity. Copy and tests must reflect each command’s actual result, not claim provider receipt/redelivery. [VERIFIED: mailglass_admin/lib/mailglass_admin/operator/replay_modal.ex:54-58; mailglass_admin/lib/mailglass_admin/operator/repair_state.ex:77-87; mailglass_admin/lib/mailglass_admin/inbound/replay_modal.ex:47-52]
5. **Relying on stories for behavioral proof.** Static component variations do not prove connected LiveView state, authorization, persistence, or Account isolation. Keep one connected browser path and server tests for the adversarial states. [VERIFIED: .planning/ROADMAP.md:126,135; .planning/METHODOLOGY.md:3-18]

## Code Examples

The existing scoped suppression read is the intended seam:

    Suppressions.get_delivery_suppression_state(
      %{
        tenant_id: filter_params["tenant_id"],
        recipient: delivery.recipient,
        stream: delivery.stream
      },
      []
    )

Source: [VERIFIED: mailglass_admin/lib/mailglass_admin/operator_live.ex:1380-1388]

Retained Storybook data stays synthetic and the story invokes the production component; the existing builder is a small pattern to extend:

    attributes = MailglassDemo.QuickViewScenarios.delivery(scenario_id)

Source: [VERIFIED: reference/persona_spec/quick_view_scenarios.ex:18-56]

## State of the Art

| Old approach | Current recommendation | Impact |
|---|---|---|
| Collapsed full-detail technical IDs | Show the grouped technical block by default below primary facts | Aligns full Delivery and Inbound with the accepted UXF-12 requirement; no new data source. [VERIFIED: .planning/REQUIREMENTS.md:21; source header/component lines above] |
| Enabled replay CTA when target cannot be resolved | Explain unavailability before a dialog and remove the primary action | Avoids a misleading dead end while keeping action-time checks authoritative. [VERIFIED: .planning/ROADMAP.md:128; mailglass_admin/lib/mailglass_admin/operator/replay_action.ex:21-64] |
| Flash-only or page-only replay failure | Inline dialog feedback with retry or explicit re-review | Keeps the error visible at the decision point without weakening one-shot review checks. [VERIFIED: .planning/ROADMAP.md:130; relevant handler lines above] |
| ASVS v4 category labels | Use ASVS 5.0.0 chapter names and identifiers | v5 reorganized validation and authorization chapters; do not copy a v4 template’s category numbers. [CITED: https://asvs.owasp.org/; https://github.com/OWASP/ASVS/blob/master/5.0/docs_en/OWASP_Application_Security_Verification_Standard_5.0.0_en.xml] |

## Assumptions Log

| # | Claim | Section | Risk if wrong |
|---|---|---|---|
| — | No factual claims are tagged [ASSUMED]; scope and current seams were checked against approved planning artifacts and opened source files. | — | — |

## Open Questions

None block planning. Choose exact short success/error sentences during implementation using the requested ux-writing guidance; do not change the domain’s replay semantics to fit copy.

## Environment Availability

| Dependency | Required by | Available | Version / observation | Fallback |
|---|---|---|---|---|
| Elixir / OTP | ExUnit, Admin browser webServer, demo E2E | ✓ with explicit asdf selection | Project pins Erlang 27.3.4.13 and Elixir 1.18.4; installed shim resolves with ASDF_ELIXIR_VERSION=1.18.4-otp-27. [VERIFIED: .tool-versions:1-2; local version probe] | Use the explicit environment prefix in commands below. |
| Mix dependencies | LiveView and command tests | ✓ | mailglass_admin/deps and reference/demo_app/deps exist. [VERIFIED: local availability probe] | — |
| PostgreSQL | Scoped reads and durable replay tests | ✓ | pg_isready reports /tmp:5432 accepting connections. [VERIFIED: local availability probe] | — |
| Docker | Demo service / browser evidence | ✓ | Docker server responds with version 29.5.2. [VERIFIED: local availability probe] | — |
| Node / npm and Playwright packages | Admin and demo browser tests | ✓ | Node v26.10.0, npm 11.19.1; both project-local Playwright installations exist. [VERIFIED: local availability probe; package locks cited above] | — |
| Demo reset token | Existing demo replay E2E reset | Required by test | Test reads DEMO_EVIDENCE_RESET_TOKEN; keep the value out of logs and supply it through the existing environment. [VERIFIED: reference/demo_app/assets/e2e/outbound-replay.spec.js:9-17] | Use the existing authorized demo evidence environment. |

elixir and mix do not resolve through the current local .tool-versions entry without the explicit asdf environment override; the installed matching Elixir/OTP pair works with that override. [VERIFIED: .tool-versions:1-2; local version probe]

## Validation Architecture

Nyquist validation is enabled in .planning/config.json. Reuse the existing ExUnit and Playwright suites; no Wave 0 framework or package install is needed. [VERIFIED: .planning/config.json; existing test files and package scripts]

### Test Framework

| Property | Value |
|---|---|
| Server tests | ExUnit through Mix |
| Connected Admin browser tests | Playwright; Admin package script builds assets and runs with one worker. [VERIFIED: mailglass_admin/package.json:1-10; mailglass_admin/playwright.config.cjs:1-15] |
| Connected demo E2E | Playwright; existing config serializes tests around shared destructive demo reset. [VERIFIED: reference/demo_app/assets/package.json:1-9; reference/demo_app/assets/playwright.config.cjs:1-23] |
| Quick run | Focused ExUnit files below; connected browser command filtered to the Phase 175 test name. |

### Phase Requirements → Test Map

| Req ID | Behavior to prove | Test boundary |
|---|---|---|
| UXF-12 | Delivery and Inbound full detail render grouped technical values without an unopened disclosure. | LiveView/component assertions plus connected route DOM assertion in both domains. Extend existing operator_live_test, inbound_live_test, components_test, and inbound/components_test. [VERIFIED: those test paths exist; current headers cite above] |
| OUTUX-07/08 | Account-scoped refresh sees empty/current/expired or externally changed facts; a failure with prior data reads as stale; no-prior-data failure is unavailable; unknown expiry and removal policy are plain-language and read-only. | Suppression service/LiveView tests for scoped query, state transitions, retry, and absent mutation controls; connected UI assertion for action location and status. Existing retained-match failure test is operator_live_test.exs:491. [VERIFIED: mailglass_admin/test/mailglass_admin/operator_live_test.exs:491] |
| REPLAY-04/05 | Open from outbound and Inbound quick views and full detail for the exact selected record; stale/changed/denied target shows the reason without fallback target or dead-end CTA. | LiveView tests for exact snapshot, action-time reread and authorization; connected browser route for quick-view entry and account/filter/selection retention. Existing stale/denied/retry cases are in operator_live_test.exs. [VERIFIED: mailglass_admin/test/mailglass_admin/operator_live_test.exs:909-1217; mailglass_admin/e2e/structural.spec.js:1416-1420] |
| REPLAY-06 | X control has accessible name Close; Escape closes, focus stays in dialog while open and returns to the exact originating quick-view/full-detail trigger. | Connected Playwright with keyboard/focus assertions for outbound and Inbound; retain existing ModalFocusTrap hook. |
| REPLAY-07 | Permitted outbound new-work and no-change outcomes close the dialog, announce a toast, and show actual command/evidence result; Inbound announces recorded run outcome without inventing a provider Event. | ExUnit result assertions plus existing replay E2E extended to assert toast and durable audit/event; Inbound LiveView assertions for each outcome. Existing outbound no-op/server success tests are at operator_live_test.exs:1241-1306. [VERIFIED: test file paths/lines] |
| REPLAY-08 | Auth denial, changed/stale review, read failure, and command failure remain visible in the open dialog with a usable retry or explicit fresh-review route; failed/duplicate submission causes no extra replay. | LiveView tests with existing read-fault and authorization seams; connected browser assert the visible dialog error and focus/CTA state. Keep auth-actions contract guard. |
| STORY-07 | A retained composed Delivery investigation scenario shows production-component detail/evidence/replay presentation and an adverse state. | Storybook/Axe render assertion plus manifest/source review; connected behavior is covered separately above. |

### Focused Commands

Run the focused Admin server tests from mailglass_admin:

    ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/components_test.exs test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/inbound/components_test.exs test/mailglass_admin/auth_actions_contract_test.exs

Run the connected Admin browser test from mailglass_admin after adding the Phase 175-named flow:

    ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm run test:operator-browser -- --grep "Phase 175"

Run the retained successful demo replay proof from reference/demo_app/assets after extending its toast assertion:

    ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm run test:e2e -- --grep "outbound replay from the demo"

The Playwright configs start the existing test/demo servers when no external base URL is supplied; the demo reset test requires the established reset-token environment. [VERIFIED: mailglass_admin/playwright.config.cjs:1-15; reference/demo_app/assets/playwright.config.cjs:1-23; reference/demo_app/assets/e2e/outbound-replay.spec.js:9-17]

### Wave 0 Gaps

No test framework or fixture infrastructure is missing. Add focused assertions to existing suites and one connected Admin flow for quick-view replay, Account/filter/selection preservation, focus behavior, and scoped suppression refresh. Extend the existing demo replay E2E to assert the success toast. Retain the existing authorization contract guard and demo grant unchanged. [VERIFIED: mailglass_admin/test/mailglass_admin/auth_actions_contract_test.exs:1-24; reference/demo_app/lib/mailglass_demo_web/admin_auth.ex:11-31; reference/demo_app/assets/e2e/outbound-replay.spec.js:19-74]

## Security Domain

Use OWASP ASVS 5.0.0 chapter names; ASVS describes a verification standard, not phase certification. v5 stable source confirms these exact chapter identifiers/titles. [CITED: https://asvs.owasp.org/; https://github.com/OWASP/ASVS/blob/master/5.0/docs_en/OWASP_Application_Security_Verification_Standard_5.0.0_en.xml]

| ASVS 5.0.0 category | Applies | Standard control for this phase |
|---|---|---|
| V1 Encoding and Sanitization | Yes | Keep HEEx output escaped; do not render raw stored webhook/provider content in technical summaries. |
| V2 Validation and Business Logic | Yes | Treat URL selection and LiveView event parameters as untrusted; re-resolve exact record/target server-side at confirmation. |
| V6 Authentication | Inherited | Keep the mounted host authentication/session contract; this phase adds no login or identity provider. |
| V7 Session Management | No new change | Modal state must not widen or replace the current host session contract. |
| V8 Authorization | Yes | Preserve tenant scope and call host authorization immediately before each distinct replay command. |
| V11 Cryptography | No | No crypto or token behavior changes. |
| V14 Data Protection | Yes | Display only existing bounded projections; preserve Account isolation and avoid exposing new raw Inbound evidence. |
| V16 Security Logging and Error Handling | Yes | Preserve audit/idempotency and terminal failure semantics; show safe actionable copy, not raw provider payloads or exception details. |

| Threat pattern | STRIDE | Existing mitigation to preserve |
|---|---|---|
| Cross-Account or substituted record/target ID | Elevation of privilege / Information disclosure | Tenant-scoped reread, frozen exact selection, snapshot comparison, action-time host authorization. |
| Duplicate or stale confirmation | Tampering | One-shot review identity, fresh eligibility read, existing idempotent domain command. |
| Replay failure shown only behind modal | Information disclosure / Repudiation | In-dialog safe error plus explicit retry or re-review; retain durable audit outcome. |
| Stale suppression presented as current | Tampering | Separate read state from retained last-known data and label it stale. |

The demo adapter is deliberately permissive for a logged-in demo operator; its grant is not production policy. The auth contract test already protects the set of authorization actions. Preserve the exact current tuple and all four demo callbacks:

    @known_actions [:destructive_action, :operator_access, :replay_inbound, :reveal_raw]

Source: [VERIFIED: mailglass_admin/test/mailglass_admin/auth_actions_contract_test.exs:24; reference/demo_app/lib/mailglass_demo_web/admin_auth.ex:14-31]

## Sources

### Primary project sources

- .planning/ROADMAP.md — Phase 175 goal, acceptance criteria, boundary, and planning focus.
- .planning/REQUIREMENTS.md — exact requirement wording and ownership.
- .planning/research/ui-quality-engine/UPSTREAM-SCOPE.md, MILESTONE-PROPOSAL.md, RECOMMENDATIONS.md, SCOPING-PRODUCT.md, SCOPING-ENGINEERING.md, SCOPING-EVIDENCE.md, and INVENTORY.md — approved milestone envelope and retained-story constraints.
- .planning/todos/2026-10-25-owner-review-pr302-ui-feedback.md and .planning/todos/2026-10-26-owner-review-health-preview-controls.md — unresolved replay and suppression feedback.
- Phase 174 artifacts 174-RESEARCH.md, 174-AUTOMATION.md, 174-PATTERNS.md, 174-01-SUMMARY.md, 174-06-SUMMARY.md, 174-VERIFICATION.md, 174-UAT.md, and 174-VALIDATION.md — continuity for retained Storybook and connected evidence.
- CLAUDE.md and .planning/METHODOLOGY.md — project engineering rules, voice, and machine-observable validation policy.
- Production source/test paths cited inline above.

### UX writing

- /Users/jon/.agents/skills/ux-writing/SKILL.md — requested writing guidance loaded for this research.

### External primary source

- https://asvs.owasp.org/ — OWASP ASVS 5.0.0 official site.
- https://github.com/OWASP/ASVS/blob/master/5.0/docs_en/OWASP_Application_Security_Verification_Standard_5.0.0_en.xml — official versioned chapter/category definitions.

## Metadata

**Confidence breakdown**
- Standard stack: HIGH — versions and browser scripts read from current project locks/configs.
- Architecture and reuse seams: HIGH — current source files, tests, story, and phase artifacts opened directly.
- Security category mapping: MEDIUM — names checked against official OWASP ASVS 5.0.0 sources; the table maps only the relevant phase controls.
- UX copy: MEDIUM — exact final sentences remain implementation work under the requested writing guidance.

**Research date:** 2026-10-27  
**Valid until:** 2026-11-26 for local architecture; re-check dependency locks if they change.
