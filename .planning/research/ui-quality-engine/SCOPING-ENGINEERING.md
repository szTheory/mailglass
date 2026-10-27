# Upstream engineering scope: owner review controls and evidence

Date: 2026-10-26. Research input to later OpenGSD scoping, not requirements, phase planning or execution. Read the new owner-review note, current synthesis and current source. No code, dependency, milestone or protected-WIP edit. This note adds the newly relevant decisions rather than repeating the initial Storybook inventory.

**Version reality:** `mailglass_admin/mix.lock` resolves Phoenix 1.8.16 / LiveView **1.2.13**; the demo lock resolves Phoenix 1.8.16 / LiveView **1.1.33**, with PhoenixStorybook **1.2.0**. Recommendations use capabilities common to those LiveView lines. No version upgrade is a prerequisite.

## 1. Auto-apply both lists through the existing parameter lifecycle

**Current evidence.** OperatorLive and InboundLive both bind their filter form to `phx-change="validate_filters"` and `phx-submit="apply_filters"`. Change currently updates draft validation/provider options; submit normalizes, builds a path, avoids a same-location patch and then patches. `handle_params/3` owns committed URL filters and data reads. The form includes hidden Account identity, not the current page. Both use current time-window choices; neither requires a custom date widget to auto-apply.

**Recommended default.** One form-level change path validates the entire current form and commits valid filters through the existing URL patch/`handle_params` path. Selects act immediately; text search uses **300ms native debounce** as a starting default. Keep submit handling as an immediate keyboard/Enter commit, without a visible Apply button or duplicate read path. Keep Clear as an explicit action. `Components.filter_field/1` already forwards global attributes to its native control; this is not a reason to build a JavaScript filter controller.

Use `replace` for debounced text updates so pauses do not fill history with query fragments; normal history entries for deliberate select, Clear, pagination and object navigation. Back/Forward restores the URL's form/results/selection; it need not replay each typed prefix. `_target` identifies the changed control without tracking speculative editing sessions. Alternative: replace **all** auto-filter updates, simpler but Back cannot retrace deliberate filter choices. Reject a timer-based push-once/replace-during-burst history machine absent an observed need.

A meaningful filter change resets page to 1; pagination preserves the committed filters. Preserve the existing scoped selected-object/deep-link rules rather than opportunistically selecting another row. A filter commit may clear list-only selection as existing submit does; direct exact detail must remain independently resolvable. Account switching continues to use its current safe filter/selection invalidation contract. Do not turn auto-apply into a new promise that filters carry unchanged across every surface.

On invalid input, show the raw draft and specific validation while keeping the last committed URL/results identifiable; do not run a fallback query silently. On read failure, retain existing scoped stale/unavailable/error behavior. Native form-change loading can indicate work without replacing the table with a skeleton on every keystroke. Keep focus and typed text stable, avoid redundant same-URL patches and announce meaningful results/errors without chatty per-keystroke messages. Current reads are synchronous LiveView work: **do not introduce async tasks, cancellation tokens, request sequence IDs or custom races** unless measurement/reproduction demonstrates a need.

**Evidence still needed:** connected tests for rapid typing→select→Enter, Clear before a pending debounce, Back/Forward while search is focused, reconnect form recovery, page>1 filter changes and read failures. Native LiveView resets pending debounce when a different field changes or form submits; whole-form handling must use the latest search value in that immediate commit. If Back leaves a focused input with a newer client value, resolve that demonstrated DOM/URL mismatch narrowly and verify on **both pinned clients**, rather than assuming a newer client-only option exists everywhere. Custom date ranges are a separate product/API scope item.

Primary sources: [LiveView 1.1.33 form bindings](https://github.com/phoenixframework/phoenix_live_view/blob/v1.1.33/guides/client/form-bindings.md) documents full-form events, `_target`, focused-input behavior and recovery; [1.1.33 rate limiting](https://github.com/phoenixframework/phoenix_live_view/blob/v1.1.33/guides/client/bindings.md) and [1.2.13 bindings](https://phoenix-live-view.hexdocs.pm/1.2.13/bindings.html) describe native debounce/reset; [1.2.13 navigation](https://phoenix-live-view.hexdocs.pm/1.2.13/live-navigation.html) establishes patch/params and history replacement. Sources support the mechanisms; the history policy above is this project's recommendation.

## 2. Useful full ordinary inbound addresses, with diagnostic boundaries intact

The owner has settled the ordinary display requirement: **authorized operators should see complete sender and recipient addresses**. This does not require another permission prompt or a new reveal action for ordinary From/To.

| Surface | Current source | Recommended scope |
|---|---|---|
| Full-detail From | `inbound/detail_header.ex:124–145`, `sender_display/1`, extracts atom/string address-map keys or strings, then calls `mask_recipient/1` | Render the complete usable sender addresses, retaining safe escaped output, missing/malformed fallbacks and multiple-address handling. Preserve names if the actual presentation contract supports them; do not guess an address from a name. |
| Ordinary To/recipient | `inbound/records_list.ex:197–201,273–280`; `inbound/quick_view.ex:109–116`; detail header via `Components.message_identity` | Already receives/displays the full envelope recipient. Audit full/narrow/cards/copy/title output for consistency rather than calling this an everywhere-masked defect. Distinguish envelope recipient from parsed header To; never relabel one as the other. |
| Quick-view From | Quick view currently omits a From cell | If ordinary sender identity is needed here, use the same minimal address presenter. Adding a sender column to every list is a separate density choice, not required to remove masking. |
| Routing simulation / matcher diagnostics | `inbound/routing_trace.ex:171–175,227–247` masks recipient/subject/matcher values and withholds sensitive header literals | Keep the safe diagnostic policy during this change. An ordinary From fix is not authority for blanket trace unmasking. |
| Raw source / verification facts | `inbound/evidence_card.ex`, `InboundLive` reveal handling and safe projections | Keep existing reveal authorization, allowlists and redaction. Telemetry/log policy remains PII-free; test captures use synthetic addresses. |

Alternative: retain ordinary masks and add another reveal interaction. Reject it: it contradicts the owner's explicit operator usefulness requirement and adds friction to already authorized evidence. Evidence to close: source-backed field map plus authorized full/quick/narrow and missing/multiple/Unicode cases; unauthorized/account-isolation and raw/trace boundaries remain real-route tests. Never globally delete masking helpers merely because one caller changes.

## 3. Suppression Refresh is a real read, so improve placement before deleting it

`Operator.SuppressionCard` is a read-only view. Its bottom control calls `retry_suppression`; `OperatorLive:464` re-reads the selected Delivery within committed Account scope and marks ready/unavailable. Full-detail loads also read it. The read model (`lib/mailglass/operator/suppressions.ex`) checks active rows against **current clock time**, selects one matching Account-local record and reports removal policy; it does not observe every custom store/provider restriction.

OperatorLive subscribes to Account delivery events and refreshes visible state on matching `delivery_updated` messages. This does **not** demonstrate that standalone suppression edits, removals or expiry always trigger invalidation. A previously read match can age without a new delivery event.

**Default:** retain Refresh/Retry as a quiet section-header action, consistently aligned with sibling evidence actions. Keep ready-empty, matched and failed-read-with-last-known-record distinct; use plain “Refresh”/“Try again” with clear section context. Add a truthful last-successful-read label only if captured at the actual successful read. No timer/polling or “live” badge is warranted by this layout change. Keep unknown expiry as Unavailable, not Never expires. Replace “Public removal command” with user-facing guidance about whether the host application can remove the record; do not invent an on-screen removal button.

Alternative: one page-level refresh that re-reads every shown evidence population. This can remove a local control **only after** proving equivalent coverage, partial-failure handling and freshness scope; it is more than relocating an icon. Evidence needed: direct refresh success/failure, external suppression change/expiry, retained stale record and account/selection change. The simplest recommendation has no broader invalidation redesign.

## 4. Preview shares navigation, not Account-scoped data

Preview loads Mailable scenario defaults and local edits. `preview_surface_paths/1` reads the host's configured `:navigation` paths; `Router.__preview_session__/2` whitelists mailables, theme and navigation and deliberately excludes operator identity/Account session state. The demo's configured operator destinations currently hardcode Northstar. Existing static paths establish destinations, **not dynamic selected-Account round-trip**.

**Default:** share coherent shell/navigation/control styling while keeping Preview Account-independent. Do not display a functioning-looking Account picker that affects nothing, tenant-filter scenario defaults or widen session/auth pass-through. Compact the real Account control on operator surfaces. Retain full author identity while making scenario labels readable and secondary actions consistent.

Browser Back and host-provided destinations are the available return mechanisms today. If preserving the exact operator Account/filter context across Preview is required, scope a small **navigation-only return-context** capability explicitly: a validated host-approved local destination, custom mount support, direct-entry fallback and no authority granted by the URL. That is a separate boundary to settle upstream; do not claim current static configuration already solves it. Reject storing a global “current account” merely for shell symmetry.

## 5. Extract the smallest seams that expose the actual problems

The first useful stories can call existing FiltersForm, SuppressionCard, detail header, quick-view, replay and Preview subcomponents. Add an area/page component only when surrounding context changes the job or behavior being reviewed; pass explicit view data/paths, not the socket. Leave loading, params, authorization, commands and replay correlation in the production LiveViews. Hook-dependent focus must reuse production hooks through Storybook's supported adapter, not load another socket or copy modal logic.

The previously established Storybook 1.2.0 route/font/theme/CSS/hook fidelity gate remains first. Prove one repaired area in its real page and its story before expanding extraction. Local example harnesses may demonstrate state transitions but cannot replace connected filter history, authorization or replay checks. No blanket rewrite, new fixture framework or dependency is justified by these feedback items.
