---
phase: "169"
slug: "outbound-investigation-and-recovery"
status: approved
reviewed_at: "2026-10-07 22:41:30 UTC"
shadcn_initialized: false
preset: none
created: "2026-10-07"
---

# Phase 169 — UI Design Contract

> Visual and interaction contract for outbound investigation and recovery. Inherited shell and tokens come from Phase 168; the phase-specific journey is Health → matching evidence → Delivery → review → replay result → return.

## Design System

| Property | Value |
|----------|-------|
| Tool | Manual — existing Mailglass design system; no shadcn |
| Preset | Not applicable |
| Component library | Phoenix.Component / HEEx; Tailwind v4 and vendored daisyUI utilities |
| Icon library | Vendored Heroicons Tailwind plugin, rendered inline |
| Font | Inter for UI/body; Inter Tight for headings; IBM Plex Mono for identifiers/code |

Use the current Mailglass brandbook and Phase 168 implementation as visual authority. Keep the shared shell, persistent Account context/switcher, desktop sidebar, compact navigation, theme picker, prebuilt CSS asset model, and mounted-route compatibility. Do not add React, shadcn, a client-JS build, a registry, a new theme, or a competing visual identity. Preserve the flat workbench surfaces and sealed-flap mark; no glassmorphism, gradients, bevels, decorative noise, or ornamental motion.

This phase owns outbound Email health, Delivery investigation, selected-delivery evidence, current suppression context, Account-scoped webhook support evidence, and exact stored webhook replay. It does not add resend, bulk recovery, suppression mutation, manual reconciliation, raw payload reveal/export, timeline search/pagination, or provider-absence detection. Inbound, preview, recipient journeys, and final shared gallery/documentation work remain in later phases.

The two primary audiences are engineers and support/on-call operators. Lead with the recorded domain fact and its consequence; show exact technical identifiers and times alongside the fact they explain. Keep implementation narration and phase terminology out of operator-facing copy.

### Composition and responsive behavior

- Retain the Phase 168 shared shell and current selected Account identity in view on every outbound surface. Account scope remains URL/host-resolved state, not a filter and not an authorization decision inferred from activity-derived options.
- At `md` (768 CSS px) and wider, use the existing sidebar and bounded `max-w-7xl` content frame. Below 768px, use the existing horizontal navigation row; allow topbar and page content to wrap. At 320px and 200% browser zoom, essential content and actions remain reachable without page-level horizontal scrolling.
- Use a page heading followed by the primary task surface. On Health, place the selected Account, “Email health,” and observed interval before summary metrics. On Deliveries, put heading and applied search/filter context before the results. On Delivery detail, order content as identity and recorded outcome → timeline → current matching suppression → clearly scoped Account webhook evidence → eligible action.
- Health metrics use a responsive two-column arrangement where labels remain readable, and one column below 768px. Do not use three compressed desktop columns below the established 768px breakpoint. Keep count, unit, observation window, and matching evidence link together; use no generic decorative chart.
- The Delivery collection is a semantic native table only when its available content width is at least 768 CSS px. Columns, in order: Delivery/recipient (masked as today), recorded outcome, latest recorded event, provider, and recorded/updated time. Each row has a visible “Open delivery” link or button; row click may be an additional pointer affordance but is never the only opener. Use compact cards in the same field order below 768px of available content width, including at a 768px viewport when the sidebar leaves less room. This content-width table threshold is separate from the existing 768px shell breakpoint. The collection remains 20 records per page with deterministic ordering and existing count/page semantics.
- Put filters immediately above results. Use a named disclosure when collapsed, showing the committed provider, latest-recorded-event, window, and page context in its summary. Keep draft values distinct from applied values; “Apply filters” commits them and “Clear filters” restores defaults. The event label is **Latest recorded event** because it does not search all history or compute delivery success. Keep Account selection in the shared shell, outside filters.
- Preserve the existing responsive Quick view overlay and full-detail route. Quick view confirms exact Delivery identity and recorded outcome first; provide a clear “View full details” action. Full detail retains a visible “Back to deliveries” action and the selected Account/filter/page context. Do not turn these steps into a wizard or replace route/history semantics with client-only state.
- Keep names, subjects, recipients, event IDs, webhook IDs, provider references, and full UTC times visible or available through a keyboard/touch-operable detail. Wrapping is preferred over truncation. A `title` attribute or hover-only disclosure is never the only way to read a value.

### Health observation layout

Show the actual validated interval in one consistent form: `Observed from {start} to {end} UTC ({hours} hours)`. Default is 168 hours; preserve valid custom positive-window deep links. Do not relabel the window as 24 hours, round it to a different period, or invent a freshness threshold. Display “Last checked {time} UTC” only when the read supplies that time. When no check time is available, show “Last checked: Unavailable.”

Each metric presents a plain-language name, count and unit, observation basis, and a same-kind destination when one exists. Failed/dead webhook processing is counted by receipt time; unmatched evidence counts unresolved event records in the window; replay/reconcile totals describe recorded audit facts. Active suppressions are current records, independent of the observation window. Label suppression counts as **records**, never recipients. Provider and latest-event filters on Deliveries do not silently narrow Account Health metrics.

Health links must match their evidence population: failed processing opens failed-webhook evidence; unmatched records open unmatched evidence. A named latest/oldest example must say it is an example. An active suppression count may separately link to historical suppressed Deliveries only when the destination is labeled as that distinct historical population. Exact support links keep their requested Account-scoped object identity; if it cannot be resolved, show that object's unavailable state instead of substituting a newer exemplar. Account-wide support evidence stays available when no Delivery matches.

Never display a universal “Healthy”/“All systems operational” claim. A confirmed zero may say only that no matching persisted evidence was observed for the stated interval or current read. Keep unaffected Health sections visible when one observation fails. Distinguish zero, no matching records, missing selection, unavailable read, stale retained data, and partial evidence.

### Delivery identity, navigation, and history

- Resolve an explicitly requested Delivery by exact ID and selected Account independently of current page, provider/event filters, and window. Retain requested ID separately from its loaded row. If it is valid but outside the visible result set, explain that and retain the exact record in Quick view/full detail; do not silently clear or substitute it.
- A malformed ID receives a recoverable “Invalid delivery link” state. A missing or foreign-Account ID receives a non-disclosing “Delivery unavailable” state. Both keep the selected Account and a route back to Deliveries; neither exposes whether a foreign record exists.
- An out-of-range page is distinct from an empty Account. A valid old selection stays open through refresh even if the latest event no longer matches the current filter. Keep useful filter drafts, selected identity, focus, and review identity through refresh. Delivery PubSub invalidation means persisted Delivery facts were reread; do not call all support and suppression panels continuously live.
- “Back to deliveries” clears the selected Delivery, full-detail mode, and exact support-event focus, then returns to the list without reopening Quick view. Browser Back/Forward mirrors deliberate URL navigation. Preserve Account, committed filters, page, and custom mount routes during Health → evidence → Delivery → Quick view → full detail → return.
- Switching Account clears Delivery, event, webhook, page, and transient confirmation IDs. Preserve only compatible filter/category context. Keep the new Account label and its data committed together; do not show a new label above old-scope evidence during a pending switch.
- Activity-derived Account choices are navigation aids only. Preserve host-owned tenant resolution and authorization. Do not infer denial from an ID absent in the option list.

### Recorded evidence and timeline

Keep event facts in chronological order using the existing timeline presentation and a maximum of 100 displayed Delivery events. Use the existing 101st-row limit to detect overflow and say how many events are not shown when that count is known; do not imply that the visible slice is complete. Preserve latest replay evidence separately through existing replay-history data, and describe that source honestly rather than calling its query bounded.

If an exact support link targets a timeline event outside the visible slice, show that scoped selected event as a separate “Selected event” fact, with its relationship to the displayed timeline. Never replace it with a visible event or say it is absent merely because it fell outside the first 100. General history pagination, search, and export remain out of scope.

For each event, show its recognized event/status name, explicit source, exact stored timestamp, and useful recorded details. Preserve distinctions among local dispatch/handoff, provider observations, and replay/reconcile audit facts. Dispatch means the provider accepted handoff; provider-reported delivered means the receiving mail server accepted the message. Neither means inbox placement or that a person read it. Keep earlier adverse events visible. Unknown event types use an “Unknown event” label with no confident success fallback.

Classify replay from its explicit event types, not from `webhook_event_id` metadata alone. Label Mailglass receipt/recorded time as recorded time; show provider occurrence time only when that value was stored and attributed as provider time. Render missing values as “Unavailable.” Show exact UTC with stored precision; local formatting may supplement but never replace the exact value. Use explicit semantic controls named “Copy event ID” and “Copy recorded time”; keep each original value visible and announce copy success or failure accessibly.

Render only this explicit diagnostic display allowlist: recognized event/state label; source; provider name; stored Delivery, Event, webhook/request, and provider-reference IDs; stored Mailglass received/recorded time and explicitly attributed provider occurrence time; selected safe reason/scope/expiry fields already supported by the detail projection; and known replay/audit result counts returned by the existing command. Keep recipient masking in list and Quick view, and honor existing authorization for detailed evidence. Never render metadata wholesale or put raw/signed webhook bodies, session data, arbitrary error content, or unreviewed metadata in the UI, URLs, client logs, or telemetry. Do not describe host actor identifiers as anonymous or enrich them.

### Suppression and Account webhook evidence

Separate three evidence groups visually and semantically: selected-Delivery ledger facts, its current matching suppression (if any), and Account-wide webhook support facts. Label an association to this Delivery, another Delivery, or no established Delivery only when persisted linkage proves it. Never attach an unlinked Account example to the selected Delivery.

For a current matching suppression, show the recorded scope (address/domain), reason, source, and expiry where available. Operator-facing label: **Current matching suppression recorded in Mailglass.** Explain briefly that this is one recorded match, not a complete view of configured-store or provider policy; no displayed match does not prove there is no external restriction. The implementation currently reads one active Ecto match, which is a technical seam, not operator copy. Address/domain scope crosses streams within the selected Account, not Accounts. Expiry and removal eligibility are separate facts. Complaint/unsubscribe removal is blocked; policy removal is supported by the public command, but no Admin removal action or claim that removal permits delivery is added.

Webhook evidence names its concrete subject and scope. Distinguish failed processing from unmatched Events and from successful/ordinary replay history. Use matching destinations and exact requested evidence identities. When no matching Delivery exists, retain the standalone Account-scoped support evidence and explain the absence of a linked Delivery without implying the evidence is missing.

### Exact replay review and outcome

Replay is an existing consequential action on a stored webhook request, not a resend and not an outbound Mailbox action. Offer **Review webhook replay** only where an existing eligible target is available. Keep the existing modal and zero/one/many candidate behavior:

1. With zero targets, explain why review is unavailable and show no Confirm action.
2. With one target, display it as an explicitly reviewed target; do not silently execute it.
3. With multiple targets, require a deliberate choice before showing that target's review details.

The review panel shows the selected Account, stored webhook/request ID, provider, received time, and proven Delivery linkage(s). Explicitly disclose that replay reprocesses the entire stored request through current normalization and may write Event records or update Delivery/suppression records for multiple Deliveries within the Account. A selected Delivery is the entry point, not a promise that the stored request affects only that Delivery. Never claim a provider receipt or a new outbound send.

Freeze the exact reviewed webhook ID, including the single-target case. On Confirm, re-read current Account/Delivery eligibility and membership for that same ID, then invoke host-owned action-time authorization immediately before execution. If the target disappeared, was replaced, or material reviewed facts changed, keep context and require a refreshed review. Never substitute another candidate. Preserve host-owned recent-auth behavior and useful denial guidance. Do not introduce package-owned authorization rules or an Account allowlist.

Use **Confirm replay** as the confirmation button. Keep the exact target visible while pending, announce “Replaying…” and disable duplicate confirmation. Enforce a server-side consumed/open-review guard as well as the disabled control. Closing the dialog after submission does not claim cancellation. Do not claim exactly-once across tabs/operators or add automatic retries, distributed locks, or a public nonce API.

Keep command feedback separate from durable persisted evidence. The outcome copy must reflect only the existing command result:

| Result | User-facing copy |
|--------|------------------|
| Request recorded, no terminal fact recorded | **Replay requested.** Completion has not been recorded yet. Check the webhook evidence again for a recorded result. |
| New normalized Events recorded | **Replay recorded {count} new Event(s).** This does not confirm mail delivery or clear Health observations. |
| No new normalized Events | **Replay completed with no new Event records.** No new Event records were added. This does not confirm mail delivery or resolve the recorded Health concerns. |
| Failure/denial | **Replay could not be completed: {cause}.** Your selected Account and Delivery remain selected. Follow the supported provider or host guidance shown below. |
| Command result known; persisted audit refresh unavailable | Show the actual command result copy above. Add: **The latest persisted replay evidence could not be refreshed.** Keep command feedback and persisted evidence visibly separate; do not suppress the known command result. |
| Command response unavailable and no terminal fact recorded | **The replay result could not be confirmed.** No terminal result is available in the recorded evidence. Do not claim completion or infer failure. |

Show an exact new-event count only when returned by the command. Map `{cause}` only through an allowlist of established user-facing categories: authorization/recent-auth required, reviewed target unavailable or changed, stored request unavailable, replay processing failed, or result persistence unavailable. Never render raw exception text; for an unmapped cause use **The replay could not be completed. Follow your host's investigation guidance.** Do not convert “no new rows” into failure, a nonzero audit count into error color, a request record into completion, or a request with no terminal fact into “still running” or inferred failure. These outcomes do not establish event-to-Delivery linkage, mail delivery, or cleared Health counts. Preserve previous adverse history and Account/Delivery context after success, no-change, failure, stale review, or denial.

Replay and background reconciliation are distinct. Reconciliation links existing unmatched evidence; it is not a generic Delivery repair action. Direct next steps to the supported host/provider investigation or existing maintenance documentation appropriate to the recorded cause. Do not add manual reconciliation or suppression-removal controls.

### Focus, keyboard, motion, and theme

- Use native table semantics and ordinary links/buttons; do not create an ARIA grid. Keep filter disclosure names and expanded states accurate. Ensure visible focus at all times and at least 44×44px hit areas for interactive controls, including icon-only actions.
- Scope keyboard shortcuts so inputs, copy controls, scrolling, and native browser/assistive technology keys retain their behavior. Announce changed selected identity and action outcomes once; do not re-announce the entire timeline on LiveView patches.
- Preserve the shared modal focus hook, contained background interaction, Escape behavior, and return focus to the visible initiating control. If the initiating row/control was removed or moved after refresh/reflow, return to a logical visible fallback such as the matching Delivery opener or “Back to deliveries.”
- Keep Light, Dark, and System visible in the shared shell and preserve the persisted preference. Status meaning always includes text/icon, never color alone. Use neutral styling for policy facts, no-change outcomes, and dismissal. Use the accent for the Review webhook replay opener and selected-row/current-timeline cues paired with explicit selected/current text or icon. Confirm replay uses the existing error/sensitive-action color treatment from ReplayModal; this marks a consequential protected confirmation, not a new destructive action. Reserve failure styling for actual failures.
- Navigation, filter application, keyboard work, and live patches are immediate. Do not choreograph timeline rows or animate keyboard-initiated actions. Reuse `--duration-instant` (90ms), `--duration-fast` (150ms), and `--duration-reveal` (220ms): routine control state changes use 90–150ms; overlay/detail reveal is at most 220ms. Use existing easing tokens and limit motion to opacity/transform; respect reduced motion by removing movement and reducing transitions to effectively instant. Pending feedback appears only for real in-flight work. Do not show fake progress, optimistic replay completion, or replace the copied value.

## Component Inventory

Enumerated by `node -e 'const fs=require("fs");const s=fs.readFileSync("mailglass_admin/lib/mailglass_admin/components.ex","utf8");const names=[...new Set([...s.matchAll(/^  def ([a-z_]+)\([^\n]*assigns[^\n]*\) do$/gm)].map(m=>m[1]))];const mix=fs.readFileSync("mailglass_admin/mix.exs","utf8");const version=mix.match(/@version "([^"]+)"/)[1];console.log(names.length,JSON.stringify(names),"mailglass_admin@"+version);'` — 15 components — `mailglass_admin@2.6.0` — 2026-10-07.

This non-exhaustive list records known-good first-party HEEx components, not a closed allowlist. Check the current component source before choosing a component outside this list.

| Component | Import path | Notes |
|-----------|-------------|-------|
| `icon/1`, `logo/1` | `MailglassAdmin.Components` | Existing Heroicons and theme-aware sealed-flap mark. |
| `flash/1`, `badge/1`, `status_badge/1`, `data_state/1` | `MailglassAdmin.Components` | Explicit text/icon state; never rely on color alone. |
| `nav_link/1`, `nav_pill/1` | `MailglassAdmin.Components` via `MailglassAdmin.SurfaceNav` | Shared desktop/compact active semantics. |
| `tenant_chip/1` | `MailglassAdmin.Components` | Account context primitive; compose with existing shell switching behavior. |
| `theme_picker/1` | `MailglassAdmin.Components` | Preserve visible System, Light, Dark native radio choices. |
| `stat_card/1`, `card/1` | `MailglassAdmin.Components` | Use when the information hierarchy fits; avoid repeated card framing. |
| `filter_section/1`, `filter_field/1` | `MailglassAdmin.Components` | Keep labels, draft values, and validation visible. |
| `timestamp/1` | `MailglassAdmin.Components` | Show exact recorded time with accessible full-value detail. |

## Spacing Scale

Use the existing 4px grid. Do not introduce off-grid spacing values. Control dimensions are separate from spacing tokens; all targets, including icon-only actions, are at least 44×44px.

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon gaps and inline alignment |
| sm | 8px | Compact element spacing |
| md | 16px | Default control/content spacing |
| lg | 24px | Section padding and grouping |
| xl | 32px | Layout gaps |
| 2xl | 48px | Major section breaks |
| 3xl | 64px | Page-level separation where content allows |

Exceptions: 44px minimum interactive target; the existing 36px visual tab is allowed only inside a non-overlapping 44px target. Reuse 4px selector/field radius and 8px box radius. Ordinary surfaces remain flat; retain established raised/overlay shadows and named z-layers from Phase 168. Focus and essential control boundaries remain distinguishable in both themes.

## Typography

Use only the installed 400 and 700 weights. Use Inter Tight for headings and IBM Plex Mono at 14px for exact identifiers/code. Implement sizes as fixed rem equivalents at the default root size while preserving browser/user text sizing and font fallbacks.

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | 16px | 400 | 1.5 |
| Label | 14px | 400 | 1.4 |
| Heading | 20px | 700 | 1.2 |
| Display | 28px | 700 | 1.2 |

## Color

Carry forward the current semantic light/dark palette. Surface percentages describe approximate screen area, not literal per-component quotas.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | Light `#F8FBFD` (`Paper`); dark `#0D1B2A` (`Ink`) | Page ground and primary work surface |
| Secondary (30%) | Light `#FFFFFF`; dark `#152538` | Sidebar, grouped panels, menus, and dialogs |
| Accent (10%) | Light `#277B96` (`Glass`); dark `#A6EAF2` (`Ice`) | Review opener, selected Delivery edge, active navigation cue, timeline current marker, visible focus emphasis |
| Destructive / protected confirmation | Light `#B42318`; dark `#E29089` | Actual failures and existing consequential protected confirmation treatment |

Accent is reserved for: Review webhook replay opener; selected Delivery edge; active navigation and current timeline marker with explicit selected/current text or icon; visible keyboard-focus emphasis. Confirm replay uses the existing sensitive-action/error color treatment, as a consequential protected confirmation; do not imply a new destructive capability. Dismissal stays neutral. Semantic success, warning, error, and info use existing theme tokens and labeled text/icons. Replay no-change or positive audit counts are neutral, not red. Do not color every card, status, or interactive element with the accent.

## Copywriting Contract

Voice: plain English, exact nouns, strong verbs, short sentences. Distinguish recorded facts from inferred state. Bracketed values below are populated only from actual evidence; never fabricate a count, time, identifier, or cause.

| Element | Copy |
|---------|------|
| Primary CTA | **Review webhook replay** |
| Confirmation CTA | **Confirm replay** |
| Empty Health evidence | Heading: **No matching evidence in this period**. Body: **No recorded {failed webhook attempts/unmatched Events} were found from {start} to {end} UTC. This does not verify provider delivery or rule out evidence that was not recorded.** |
| Empty Delivery collection | Heading: **No Deliveries recorded**. Body: **No Deliveries were recorded for this Account in the selected period.** |
| Filtered-empty Delivery collection | Heading: **No Deliveries match these filters**. Body: **Change or clear a filter to see more results.** Action: **Clear filters** |
| Invalid delivery link | Heading: **Invalid delivery link**. Body: **This link does not contain a valid Delivery ID. Check the link or return to Deliveries.** Action: **Back to deliveries** |
| Missing/foreign selection | Heading: **Delivery unavailable**. Body: **This Delivery could not be opened in the selected Account. Check the link or return to Deliveries.** Action: **Back to deliveries** |
| Valid selection outside results | Heading: **Delivery is outside these results**. Body: **This Delivery is outside the current page, filters, or time window. The requested Delivery remains selected.** Action: **Back to deliveries** |
| Out-of-range page | Heading: **Page unavailable**. Body: **This page is beyond the available results. Return to the first page to continue.** Action: **Return to first page** |
| Partial evidence | Heading: **Some evidence is unavailable**. Body: **Available evidence is shown. Unavailable fields could not be read and do not mean that no records exist.** |
| Timeline overflow | **At least one additional Event is not shown in this timeline. The full history is not available in this view.** Do not invent the total count. |
| Selected event outside timeline slice | Heading: **Selected event**. Body: **This exact Event is outside the displayed timeline. It is shown here because the link selected it.** Show its recorded relationship to the displayed slice. |
| Error state | **These {Health observations/Delivery details/webhook records} could not be loaded. Other available sections remain visible.** Use the supported action label **Retry observations**, **Retry details**, or **Retry webhook evidence** for the affected read. |
| Stale evidence | **Showing the last retrieved evidence from {time} UTC. Refresh to check again.** If time is unavailable, say **Last checked: Unavailable.** Never invent an observation time. |
| Replay with no target | **No eligible stored webhook request is available to replay for this selection.** Do not show Confirm. |
| Dismiss replay review | Button: **Close replay review**. Closing after submission does not claim that the submitted command was cancelled. |
| Copy controls | Buttons: **Copy event ID** and **Copy recorded time**. Announce **Event ID copied** / **Recorded time copied** or **Could not copy {value}. Select and copy it manually.** |
| Replay target changed | **This webhook request changed or is no longer eligible. Review the current request before replaying.** |
| Replay denied | **Replay was not authorized. Your Account and Delivery selection were kept. Follow your host's access or recent-auth guidance, then review the request again.** |
| Destructive confirmation | **None in this phase.** Replay is a consequential action and uses the exact-target review/confirmation above; do not add a destructive or suppression-removal action. |

Keep cause-specific inline field validation beside the field and retain the user's useful input. Map validation/replay causes to established user-facing categories only; never place raw exception text in a copy placeholder. Distinguish no records, no filter matches, read failure, stale data, partial evidence, invalid link, missing/foreign selection, out-of-range page, timeline overflow, and denied/unavailable evidence; never render failure as an empty or zero state.

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| None | None | Not applicable — no shadcn or third-party registry; use first-party HEEx and existing vendored assets. |

## Requirement and Decision Traceability

| Requirement | Contract coverage |
|-------------|-------------------|
| OUTUX-01 | Health interval/unit semantics, honest zero/stale/unavailable states, and matching evidence destinations |
| OUTUX-02 | Filters, exact selection independent of list constraints, Quick view/full detail, return/history, and empty/invalid states |
| OUTUX-03 | Recorded timeline, event source/time labels, exact UTC, dispatch-versus-delivered language, and preserved adverse history |
| OUTUX-04 | Separate Delivery/current suppression/Account webhook evidence, proven associations, and supported next steps |
| OUTUX-05 | Exact-target replay review, action-time reauthorization, pending/duplicate guard, batch consequence, and truthful outcomes |

The visual system and interaction baseline inherit Phase 168. Phase-specific authority is `.planning/phases/169-outbound-investigation-and-recovery/169-CONTEXT.md` D-01–D-26; layout and copy discretion resolves within those locked decisions. This contract does not claim current rendered behavior or runtime verification. Implementation acceptance and before/after evidence remain future execution work.

## UI Considerations

**82 resolved (explicit), 0 backstop, 0 unresolved** across 11 surfaces. These are implementation acceptance criteria, not proof that the running UI satisfies them.

**Provenance and decision authority:** GSD `@opengsd/gsd-core@1.16.0`, compiled `ui-consideration-probe.cjs <elements.json> <resolutions.json>`, run 2026-10-07 after independent seven-dimension verification. The initial prose classifier raised 37 items, including five unclassified surfaces. Under the owner's Phase 169 instruction to synthesize and automatically adopt coherent recommendations, the orchestrator reread each described surface and added the real form/list/navigation/content semantics missing from the heuristic. The final authored kinds below are the union of detected and applicable missed kinds. The engine validated all 82 explicit resolutions, with no unclassified elements or orphan resolutions. This records delegated recommendations; it does not claim a separate owner confirmation of this table.

| Element | Surface | Adopted kinds |
|---------|---------|---------------|
| E1 | Inherited shell, Account selection and appearance | nav, form, list-collection, interactive-control, static-content |
| E2 | Filters and applied-context summary | form, list-collection, interactive-control, static-content |
| E3 | Email health observations and destinations | list-collection, interactive-control, static-content |
| E4 | Delivery results and pagination | list-collection, nav, interactive-control, static-content |
| E5 | Quick view, full detail and return navigation | list-collection, nav, interactive-control, static-content |
| E6 | Timeline and exact selected event | list-collection, interactive-control, static-content |
| E7 | Current matching suppression | list-collection, interactive-control, static-content |
| E8 | Account webhook/support evidence | list-collection, nav, interactive-control, static-content |
| E9 | Replay target selection, review and confirmation | form, list-collection, interactive-control, static-content |
| E10 | Feedback, status, timestamps and copy controls | interactive-control, static-content |
| E11 | Brand mark and status/action icons | media, static-content |

The resolutions reference the Copywriting Contract and inherited Phase 168 copy rather than duplicating it. `resolved / explicit` means a concrete truth the planner must lift into acceptance coverage. Inherited shell/theme behavior is checked at the outbound integration boundary; it does not reopen the shared design system.

| Element | Category | Status | Verification | Acceptance truth |
|---------|----------|--------|--------------|------------------|
| E1 | empty | resolved | explicit | With no Account selected, show the inherited chooser; distinguish no Accounts with activity from no selection. Appearance always retains a valid System/Light/Dark choice. |
| E1 | loading | resolved | explicit | Keep navigation readable and the committed Account paired with its own data while switching; expose real pending work without a new Account label over old evidence. |
| E1 | error | resolved | explicit | A denied or failed switch/navigation retains a correctly labeled committed scope or shows scoped unavailability using inherited recovery copy; activity options never decide authorization. |
| E1 | populated | resolved | explicit | The selected Account name and stable ID, active destination, and operable appearance choice remain visible above outbound content at all supported widths. |
| E1 | partial | resolved | explicit | Missing host labels fall back to the stable Account ID; a permitted explicit Account remains selectable even when absent from activity-derived options. |
| E1 | overflow | resolved | explicit | The compact navigation and topbar wrap; Account choice remains reachable in its native bounded control without page-level horizontal scrolling. |
| E1 | zero-one-many | resolved | explicit | Preserve explicit unselected routes, single-Account auto-selection when tenant_id is omitted, and deliberate multiple-Account choice; configured destinations appear once. |
| E1 | long-text | resolved | explicit | Long Account labels and IDs wrap without hiding appearance, active navigation, or focus; the full stable identifier remains keyboard/touch readable. |
| E2 | empty | resolved | explicit | Default filters show the actual 168-hour interval and unrestricted provider/event choices; an empty required window stays a visible invalid draft rather than silently applying. |
| E2 | loading | resolved | explicit | While applying filters, preserve useful draft input and clearly distinguish the pending request from committed result context; show busy feedback only for actual pending work. |
| E2 | error | resolved | explicit | Malformed, unsupported-shaped, or numerically unsafe filter input gets field-associated validation; reveal invalid fields, retain useful input, and keep committed results correctly labeled. |
| E2 | populated | resolved | explicit | Provider, Latest recorded event, window, Apply filters, and Clear filters appear above results; the collapsed summary states committed values and page context. |
| E2 | partial | resolved | explicit | Missing optional filter values mean their established unrestricted defaults; valid custom positive windows remain representable instead of being replaced by a preset. |
| E2 | overflow | resolved | explicit | Controls, summaries, and action buttons reflow into the content width without clipping field errors or the apply/clear actions. |
| E2 | zero-one-many | resolved | explicit | Native options retain an unambiguous current value for default, single active, and multiple active filters; no active filters still leaves the disclosure and Apply/Clear discoverable. |
| E2 | long-text | resolved | explicit | Long provider/event labels and custom-window summaries remain readable; labels and validation wrap instead of shrinking below the type scale. |
| E3 | empty | resolved | explicit | Without an Account, defer observations to the chooser; confirmed zero uses the limited observation copy, while a failed or missing read never supplies a zero. |
| E3 | loading | resolved | explicit | Keep last retrieved metrics visibly stale during a failed/pending refresh; if no data has loaded, show a labeled loading region without fake zero values or an invented check time. |
| E3 | error | resolved | explicit | A failed observation uses the matching retry/error copy, preserves unaffected sections, and never enables a destination pretending that the failed read succeeded. |
| E3 | populated | resolved | explicit | Metrics show their unit, actual observation window or current-record basis, actual check time when supplied, and an evidence destination of the same kind. |
| E3 | partial | resolved | explicit | Unavailable metrics stay explicitly unavailable next to available metrics; the partial-evidence notice identifies the affected section without declaring overall health. |
| E3 | overflow | resolved | explicit | Metric labels, units, interval and evidence actions wrap in two columns where readable and one below the shell breakpoint; counts and their units stay together. |
| E3 | zero-one-many | resolved | explicit | Use correct singular/plural units for 0, 1, and many records; a single latest/oldest exemplar is named as such and never presented as the complete population. |
| E3 | long-text | resolved | explicit | Long exact interval/check times and exemplar identifiers wrap or expose their complete value through an operable detail; no essential meaning relies on hover. |
| E4 | empty | resolved | explicit | Separate no Account, no Deliveries in the period, filtered-empty results, and an out-of-range page using the contract's distinct copy and supported recovery actions. |
| E4 | loading | resolved | explicit | Retain the committed results with accurate pending context during rereads; initial absence gets an actual loading state and does not appear as an empty Account. |
| E4 | error | resolved | explicit | A failed list read provides a retry while preserving Account, useful filters, requested selection, and correctly labeled retained rows; it never substitutes an empty collection. |
| E4 | populated | resolved | explicit | Show at most 20 ordered records, masked recipient identity, recorded outcome, latest event, provider, exact-time access, and an explicit Open delivery control. |
| E4 | partial | resolved | explicit | Missing provider/reference/time values are Unavailable; an unknown event remains unknown and a latest audit fact is visibly distinct from a delivery outcome. |
| E4 | overflow | resolved | explicit | Use a native table only with at least 768px available content width; otherwise use cards in the same field order. Page controls and full-value access remain reachable at 320px and zoom. |
| E4 | zero-one-many | resolved | explicit | Zero uses the appropriate empty state; one remains a normal record; many retain deterministic 20-row pagination and truthful page/count context without fabricating totals. |
| E4 | long-text | resolved | explicit | Long and non-ASCII subjects, masked recipients, IDs, and event labels wrap or have keyboard/touch-accessible full detail without squeezing the 16px body. |
| E5 | empty | resolved | explicit | Invalid links and missing/foreign Account selections use their separate copy; no result rows cannot hide a valid exact selected Delivery or standalone support evidence. |
| E5 | loading | resolved | explicit | Retain the requested Delivery identity independently of the loaded row during rereads; pending detail remains scoped and does not silently close when list membership changes. |
| E5 | error | resolved | explicit | Detail unavailability keeps Account/filter/page and the requested ID, with supported Retry details and Back to deliveries; foreign records are not disclosed. |
| E5 | populated | resolved | explicit | Quick view leads with identity/outcome and View full details; full detail orders timeline, current suppression, and Account evidence, with Back to deliveries visibly available. |
| E5 | partial | resolved | explicit | Missing detail fields or support panels remain explicitly unavailable while known identity and evidence stay visible; exact selections outside results get the dedicated explanation. |
| E5 | overflow | resolved | explicit | Overlays fit the viewport with a scrollable content region and reachable close/action controls; modal focus stays contained and returns to a visible logical fallback. |
| E5 | zero-one-many | resolved | explicit | There is one exact selected Delivery at a time; page-relative previous/next/position appear only when it belongs to that page, including the one-row case. |
| E5 | long-text | resolved | explicit | Long identity and exact times wrap inside Quick view and detail; back/full-detail/close controls retain their label, hit target, and visible focus. |
| E6 | empty | resolved | explicit | A successfully read empty ledger states that no events are recorded for this Delivery; an unavailable timeline or selected-event read is never described as empty. |
| E6 | loading | resolved | explicit | Keep the visible chronology and selected-event identity stable during an actual refresh; do not replay entrance animations or imply an incomplete read is the whole history. |
| E6 | error | resolved | explicit | Timeline or exact-event failure retains other detail and supplies scoped retry/unavailable feedback; no visible event substitutes for a failed exact selection. |
| E6 | populated | resolved | explicit | Render the oldest 100 events chronologically with explicit source and stored time, preserving dispatch/provider/audit distinctions and adverse history. |
| E6 | partial | resolved | explicit | Missing stored fields are Unavailable and unknown event types remain neutral; local recorded time is never relabeled provider time, and linkage metadata alone never means replay. |
| E6 | overflow | resolved | explicit | Fetch the 101st row through the existing limit to detect undisplayed history, show overflow copy without an invented count, and show a selected scoped event outside the slice separately. |
| E6 | zero-one-many | resolved | explicit | Handle 0, 1, 100, and more than 100 events explicitly; latest replay evidence remains separately reachable and is not falsely described as coming from a bounded history query. |
| E6 | long-text | resolved | explicit | Event names, IDs, safe reason text and exact UTC timestamps wrap with semantic copy controls; original values remain visible after copying. |
| E7 | empty | resolved | explicit | A successful no-match read says no current matching suppression recorded in Mailglass was found; it does not prove absence of configured-store or provider restrictions. |
| E7 | loading | resolved | explicit | Keep any retained current match explicitly associated with its retrieval state; do not show a new no-match assertion while the read is pending. |
| E7 | error | resolved | explicit | An unavailable suppression read uses scoped unavailable/retry feedback and leaves historical ledger facts visible; a failure never becomes permission to send. |
| E7 | populated | resolved | explicit | Show one current matching record with reason, scope, source and expiry where stored, separate from historical suppression events and Account-wide metrics. |
| E7 | partial | resolved | explicit | Missing source/expiry is Unavailable rather than inferred permanent/expired; complaint/unsubscribe removal restrictions and policy removability are described separately from expiry. |
| E7 | overflow | resolved | explicit | The definition list reflows within available width and allows long address/domain/scope values to wrap without creating a nested data table or hiding guidance. |
| E7 | zero-one-many | resolved | explicit | Zero means no match from this reader; one is a single selected current match, never an exhaustive restriction list; Account totals remain a separate record population. |
| E7 | long-text | resolved | explicit | Long safe reason, source, address/domain and stream values remain readable; operator copy uses Mailglass domain language and explains Account-local scope. |
| E8 | empty | resolved | explicit | Distinguish no persisted evidence of the named kind, an unresolved exact object, and no proven Delivery linkage; standalone support evidence works with no matching Delivery rows. |
| E8 | loading | resolved | explicit | Retain the exact requested event/webhook ID and label retained evidence during refresh; a moving latest/oldest exemplar never replaces an explicit selection. |
| E8 | error | resolved | explicit | A missing/foreign object or unavailable read gets non-disclosing scoped recovery; other evidence remains visible, and failed reads cannot become No failures. |
| E8 | populated | resolved | explicit | Use concrete failed-webhook, unmatched-event, replay, or reconciliation headings with their own scope and safe IDs/times; only proven linkage enables a named Delivery handoff. |
| E8 | partial | resolved | explicit | Unavailable time/provider/linkage remains explicit; unlinked Account evidence is never attached to whichever Delivery is open, and partial panels retain their usable facts. |
| E8 | overflow | resolved | explicit | Long evidence and safe detail wrap in vertical sections with accessible copy actions; the layout does not become a new unbounded record browser or raw-payload view. |
| E8 | zero-one-many | resolved | explicit | Counted records and shown exemplars stay distinct at 0, 1, and many; an exact object link resolves itself even if newer examples exist. |
| E8 | long-text | resolved | explicit | Safe support IDs/references and concrete headings wrap; full-value access and supported next-step links remain keyboard/touch operable. |
| E9 | empty | resolved | explicit | Zero eligible targets uses replay-unavailable copy with no Confirm action; multiple targets initially require a deliberate choice rather than an implicit first selection. |
| E9 | loading | resolved | explicit | Pending replay keeps the reviewed target visible, disables Confirm, and consumes the server review once; closing after submit never claims cancellation or triggers an automatic retry. |
| E9 | error | resolved | explicit | Denied, stale/changed, missing-target, command-failure and persisted-evidence-failure states use safe cause-specific feedback; retain scope and require review again where eligibility changed. |
| E9 | populated | resolved | explicit | Review shows Account, exact stored request ID, provider, received time and proven linkage, discloses full-request/batch effects, and revalidates the same target with action-time host authorization. |
| E9 | partial | resolved | explicit | Unavailable optional evidence is labeled; incomplete eligibility or a missing exact reviewed target prevents confirmation. Known command feedback remains visible separately from missing terminal audit evidence. |
| E9 | overflow | resolved | explicit | The candidate list and modal body scroll within the viewport; reviewed identity, neutral Close replay review and reachable Confirm remain available without background interaction. |
| E9 | zero-one-many | resolved | explicit | Handle zero, one explicit reviewed target, and many deliberately selected targets; freeze the chosen ID even in the one-target case and never substitute a newer candidate. |
| E9 | long-text | resolved | explicit | Long exact target IDs, provider references and consequence copy wrap within the review; action labels, 44px targets, focus containment and focus return remain intact. |
| E10 | loading | resolved | explicit | Announce only real read/action pending state; requested-only durable replay evidence means completion has not been recorded, not an indefinitely running command. |
| E10 | error | resolved | explicit | Copy failure retains the selectable original and announces manual-copy guidance; action errors expose only supported safe cause mappings, never raw exceptions or payloads. |
| E10 | overflow | resolved | explicit | Feedback, badges, exact times and copy controls wrap together without replacing the original value, covering another control, or causing page-level horizontal scrolling. |
| E10 | long-text | resolved | explicit | Specific Copy event ID/Copy recorded time labels remain accessible with full values; changed identity and action outcome are announced once, without rereading the full ledger. |
| E11 | empty | resolved | explicit | Missing decorative imagery does not remove the Mailglass wordmark or text status/action meaning; no task depends on an icon being present. |
| E11 | loading | resolved | explicit | Use the existing inline/local icon and logo assets without new remote requests or content-sized skeletons; labels remain usable throughout rendering. |
| E11 | error | resolved | explicit | An unavailable icon/asset leaves its text or accessible action name intact; broken media cannot become the sole representation of a state. |
| E11 | populated | resolved | explicit | Use the incumbent sealed-flap mark and Heroicons at established sizes; decorative icons are hidden from assistive technology and meaningful controls retain accessible names. |
| E11 | overflow | resolved | explicit | Icons retain their fixed intended size while accompanying text wraps; focus outlines and 44px action targets remain unclipped in both themes. |
| E11 | long-text | resolved | explicit | Long accessible/visible state labels wrap independently of decorative icons; icons supplement text instead of replacing it. |

**Open UX dimensions and connected proof:** Before implementation edits, capture the current served revision/CSS, route, fixture, theme/OS, viewport/zoom and interaction state. Use representative 320, 390, 768 and 1440 CSS-pixel views, 200% zoom, Light/Dark/System with OS-change/reload, reduced motion, keyboard and touch, and long/non-ASCII values. Exercise the connected Health → same-kind evidence → exact Delivery → Quick view/full detail → reviewed replay → result → return path, including off-page/out-of-window and no-result exact links, Account changes, Back/Forward, filter drafts, 100/101-event boundaries, current versus historical suppression, zero/one/many/replaced/denied replay targets, duplicate queued confirmation, disconnect/latency, copy failure and missing terminal evidence. Preserve native control keys, visible focus, modal background containment and logical focus return after reflow/removal. Reuse focused core/LiveView/browser checks and the bounded inspection → corrective batch → confirmation cycle from CONTEXT D-26; this document adds no completed-test claim or new testing platform.

## Checker Sign-Off

- [x] Dimension 1 Copywriting: PASS
- [x] Dimension 2 Visuals: PASS
- [x] Dimension 3 Color: PASS
- [x] Dimension 4 Typography: PASS
- [x] Dimension 5 Spacing: PASS
- [x] Dimension 6 Registry Safety: PASS
- [x] Dimension 7 Inventory Provenance: PASS

**Approval:** Approved by independent gsd-ui-checker after one targeted refinement; all seven dimensions passed with no recommendations. The orchestrator then resolved the post-verification state-coverage probe above under the owner's delegation.
