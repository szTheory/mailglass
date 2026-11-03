# Phase 176: Direct Filters and Useful Inbound Evidence - Context

**Gathered:** 2026-10-27 (assumptions mode, research-first fan-out: codebase analyzer + LiveView filter research + inbound address/raw-source research; decided per CLAUDE.md Decision Policy without owner escalation)
**Status:** Ready for planning

<domain>
## Phase Boundary

Operators can find records directly in either collection (Deliveries, Inbound) and inspect useful ordinary Inbound contact/raw-source evidence while URL, Account and private-disclosure contracts remain truthful.

In scope: FILTER-01..04 (auto-apply filters on both collections, history/pagination/Account semantics, invalid-input and failed-read truthfulness), INUX-05 (complete ordinary Inbound addresses, envelope vs header distinction), INUX-06 (Raw provider source card hierarchy).

Out of scope: custom date ranges (SEED-261010-gad remainder), async reads, widening the `mailglass_inbound` list projection, IDNA/punycode conversion, unmasking routing diagnostics.
</domain>

<decisions>
## Implementation Decisions

### Commit path (FILTER-01, FILTER-02)
- **D-01:** Reuse the existing form → `push_patch` → `handle_params` → synchronous read path on both LiveViews. No `start_async`, no custom search controller, no new dependency. `phx-change` becomes the commit point: normalize → if error-free and `same_location?` is false → patch to canonical path. Keep `phx-submit` as the Enter commit (it flushes pending debounce — LV client increments the debounce cycle on submit). Remove the visible Apply button and its `phx-disable-with`.
- **D-02:** `phx-debounce="300"` on the search input only. Selects have no debounce. Not `"blur"`.
- **D-03:** Enter works by HTML implicit submission (each form has exactly one implicit-submission-blocking text field). Pin it with a browser test that fails if a second text/date field is added without restoring a submit control. No hidden submit button.
- **D-04:** Remove `load_provider_options` from the change handler (`handle_params` already loads it) so debounced commits don't add a read.
- **D-05:** Never disable or show a loading state on the search input during commits (it drops focus/caret).

### History, pagination and Account (FILTER-03)
- **D-06:** History policy lives in one pure function (unit-tested) returning `:push | :replace`:
  - select change → push; Enter → push (no-op if `same_location?`); Clear → push; pagination → push;
  - debounced search commits → first commit of a "search edit" pushes, later debounced commits replace until a non-search commit/Enter/Clear ends the edit (track via an assign such as `:last_commit_kind`);
  - tenant canonicalization and reconnect recovery → always replace.
- **D-07:** Fix the existing Back trap: `:canonicalize_tenant` (`operator_live.ex:~221`, `inbound_live.ex:~510`) must patch with `replace: true`.
- **D-08:** Every filter commit drops `page` (explicit in code, not incidental) and drops selection (`delivery_id`/`inbound_id`/`full`). Pagination links are built from committed params. Canonical URLs drop defaults/blanks and build query strings from a sorted keyword list.
- **D-09:** Commits take `tenant_id` from server-held `socket.assigns.selected_tenant_id`; the hidden form `tenant_id` is ignored for commits (remove it if nothing else needs it). Account switching stays with the Account selector. `handle_params` remains the URL authorization gate.
- **D-10:** Focused-input Back/Forward: add a small copy-paste JS hook on the search input — a `popstate` listener marks a pending history navigation; in `updated()`, if pending and `el.dataset.committed !== el.value`, set the value. Server renders `data-committed` from committed params. Do NOT use `phx-patch-focused` (only LV ≥1.2.8; admin requires `~> 1.1`; demo is 1.1.33; and it would clobber typing after debounced commits). The hook ships in the admin's committed `priv/static` bundle — rebuild and commit it (CLAUDE.md "Things Not To Do" #6; mind the token-parity bundle landmine: rebuild JS only, verify TokenParityTest).
- **D-11:** Reconnect: `phx-auto-recover="recover_filters"` restores the draft and, only if valid and different from the URL, commits with replace. Never pushes.

### Invalid input and failed reads (FILTER-04)
- **D-12:** Draft (`filter_form`) and committed (`filter_params`) stay separate. An invalid draft never commits: keep draft visible, `aria-invalid` + inline error linked by `aria-describedby`, specific copy. Results stay those of the committed URL; while an invalid draft is pending, show one short note that results still reflect the previous filters. Inbound gains Operator's raw-draft retention (`filter_draft_params` pattern) so its select never contradicts its error.
- **D-13:** Invalid values arriving via URL keep today's non-silent behavior (field error "… was not applied"), and results are explicitly labeled as excluding that filter. No unlabeled fallback population.
- **D-14:** Failed read, same committed query → keep rows labeled stale ("Showing results from HH:MM; refresh failed") — today's Operator rule. Failed read, new query → error panel ("Couldn't load deliveries/inbound messages for these filters") with Retry that re-reads without pushing history; no old rows, no empty-state copy, no fallback query, no counts. URL keeps the attempted (committed) filters.
- **D-15:** Fix the Operator `collection_header` that renders "0 deliveries" on error; hide the count when not `:ready` (Inbound already does). Inbound gains same-query stale retention and Retry for parity.
- **D-16:** One persistent polite `role="status"` region per collection, present from first render, updated only after `handle_params` settles a commit ("24 deliveries match", "No deliveries match these filters", "Couldn't load deliveries"). No announcements for drafts/keystrokes; never move focus.

### Inbound contact display (INUX-05)
- **D-17:** Full-detail header renders a `<dl>` in order: **From**, **Reply-To** (only if present), **To**, **Cc** (only if present), **Delivered to** = `envelope_recipient` with hint "SMTP envelope recipient (RCPT TO), used for routing". Bcc omitted from default view. No invented Return-Path.
- **D-18:** `message_identity`'s recipient label becomes context-aware: Operator keeps "To"; Inbound (detail header and Quick view) uses "Delivered to". Quick view keeps only the envelope recipient — do not widen the `mailglass_inbound` list projection (would force an inbound release for a display change).
- **D-19:** Stop masking From in `sender_display/1`; render display name + `<addr>` as separate HEEx-escaped spans (no `raw`). Drop the name when missing or equal to the address; when the name contains an `@` differing from the addr-spec, show both (spoof cue).
- **D-20:** Multiple addresses: all, in header order, one per line (`<ul role="list">` in the `<dd>`); dedupe exact duplicates within a field only (domain case-insensitive, local part case-sensitive); over 5 → first 5 + native `<details>` "Show N more".
- **D-21:** Missing values are field-specific, never a bare "—": From → "No From header"; To → "No To header"; Delivered to → "Not recorded by provider"; Cc/Reply-To rows hidden when empty; unparseable → "Unparseable address" + escaped original.
- **D-22:** Unicode/EAI shown as received (UTF-8). Long values wrap with `[overflow-wrap:anywhere]` (existing pattern `detail_header.ex:51`); never truncate in detail views. List-row truncation stays (detail shows the full value). Per-address copy via existing `Components.copy_value`.
- **D-23:** Keep `Components.mask_recipient/1` / `mask_value/1` (public, `@doc since: "0.2.0"`). Routing-trace matcher expected/actual and subject masking stays unchanged. Do not cite D-30 as authority (PROJECT.md D-30 is the B2C safety profile); authority is `UPSTREAM-SCOPE.md` §76 and the ROADMAP planning focus.

### Raw provider source card (INUX-06)
- **D-24:** One header group: `h3` "Raw provider source" + one disclosure button labeled with the action ("Reveal raw source" / "Hide raw source", persistent `aria-expanded`/`aria-controls`) + one caption "May contain personal information." Remove the "Raw source locked" badge, the inner second "Hide raw source" button, and the "hidden by default" paragraph. Don't say "logged" (telemetry is not an audit log). On mobile the button wraps below the heading full-width `min-h-11`.
- **D-25:** One compact `<dl>` (`grid sm:grid-cols-2 lg:grid-cols-4`) with uniform `dt`/`dd` styles: Provider, Received, Payload size (thousands-separated bytes), Header count, Provider authentication. No checksum (none stored).
- **D-26:** Truth fixes: `payload_byte_size` and `header_count` return `nil` (render "Unavailable") instead of 0 on unknown/encode failure. Revealed-but-empty → "Provider sent an empty payload." Not stored → keep "No raw provider source was stored for this message." and hide the button. Denied → "You don't have permission to reveal raw source." via the existing `role="status"` region. `<pre>` gets `tabindex="0"` + `aria-label` (keyboard-scrollable).
- **D-27:** Authorization, state atoms (`:redacted`/`:revealed`/`:denied`), reset-on-selection, and PII-free telemetry stay unchanged. Remove the dead `can_reveal?` attr (unused; auth happens at action time).

### Verification (D-52 shift-left)
- **D-28:** ExUnit (merge-blocking `verify.support_contract.admin`): commit/no-commit, canonical paths, page reset, pagination preserving filters, tenant-field tampering ignored, history-policy pure function, invalid draft retention, URL-invalid labeling, fault-injected `:error` vs `:stale` (existing `operator_read_fault` seam), Back via `render_patch`, address rendering cases (long/Unicode/missing/multiple/display-name spoof), evidence card states, reveal auth.
- **D-29:** Playwright (Operator Browser Gate vs LV 1.2.13; demo e2e vs LV 1.1.33) for client-only behavior: `history.length` deltas per search edit, Enter and Clear during pending debounce, focus/caret stability, Back/Forward with focus in search (D-10 hook), reconnect with no added history entry, status-region text after settle, axe on invalid/error states. Report these lanes as advisory (not in `ci_green.needs`).
- **D-30:** (phase-local; unrelated to PROJECT.md D-30) `phase176_prohibition_contract_test.exs` (template: `phase175_prohibition_contract_test.exs`), each must-NOT mutation-proven: no visible Apply button; routing trace still masks; "Delivered to" bound to `envelope_recipient` and "To" to header `to`; denied/unauthorized routes never contain raw-payload sentinel bytes; reveal/detail telemetry metadata contains no addresses; unknown size/count never renders "0"; failed new-query read never renders empty-state copy or a count.
- **D-31:** Update coupled tests/specs that assert Apply or masked From (`operator_live_test.exs:184,318,363,380`, `inbound_live_test.exs:786`, `inbound/components_test.exs:327-374`, e2e `inbound-layout.spec.js:173-184`, `phase175-inbound.spec.js:137`, `phase169-journey.spec.js:571`). Trace-masked contracts (`inbound_live_test.exs:1220-1246,2259-2287`) stay.
- **D-32:** Retained scenarios: replace masked gallery fixtures (`gallery_live.ex:597,1279-1311`) with synthetic worst-case data; add production-component stories for EvidenceCard and Inbound DetailHeader driven by the existing scenario manifest (`reference/persona_spec/quick_view_scenarios.ex/.json`), no invented props.

### Claude's Discretion
- Exact debounce value may move within 250–400ms if browser tests show flakiness.
- Exact microcopy wording may be polished in a UI-SPEC within brand voice, keeping meaning.
- Whether the hidden `tenant_id` input is deleted or merely ignored.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` — Phase 176 goal, success criteria, planning focus
- `.planning/REQUIREMENTS.md` — FILTER-01..04, INUX-05, INUX-06
- `.planning/METHODOLOGY.md` — D-52 shift-left verification; must-NOT items authored `verification: test`
- `.planning/research/ui-quality-engine/UPSTREAM-SCOPE.md` (§63-76) — feedback dispositions incl. auto-apply and From unmasking authority
- `.planning/research/ui-quality-engine/AUTOMATION.md` — lane/gate facts
- `.planning/seeds/SEED-261010-gad-operator-date-range-and-live-filters.md`, `.planning/seeds/SEED-261010-hjp-inbound-filters-auto-apply-and-live-search.md`
- `.planning/phases/175-delivery-investigation-and-safe-replay/175-UI-SPEC.md` (deferred auto-apply to 176), `175-PATTERNS.md`
- `.planning/milestones/v2.9-phases/170-*/170-CONTEXT.md` D-05/D-06 (prior masked-identity decision being refined)
- `mailglass_admin/test/mailglass_admin/phase175_prohibition_contract_test.exs` — contract-test template
- `brandbook/brand-book.md` — voice and visual rules
- RFC 5321 §2.3.1/§3.3 (envelope vs headers), RFC 5322 §3.6.2–3.6.3, RFC 6531/6532; WHATWG implicit submission; WCAG 3.2.2 On Input; LV 1.2.13 `push_patch/2` `:replace`
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `apply_filters` + `same_location?` (`operator_live.ex:249-274,2320-2326`; `inbound_live.ex:249-268`) — normalize/canonical-path/no-op guard to move into the change path.
- `build_path`/`normalize_page` (`operator_live.ex:2208-2229,2409-2417`) — canonicalization and page drop.
- `filter_draft_params` (`operator_live.ex:181,1273-1279`) — raw-draft retention to port to Inbound.
- Operator stale/error read logic (`operator_live.ex:1554-1565,1778-1780`), `retry_deliveries` (`:433-442`), `operator_read_fault` seam.
- `filter_field` passes `:global` attrs (`components.ex:917-946`); `phx-debounce` precedent `preview/assigns_form.ex:88`.
- `Components.copy_value`, `[overflow-wrap:anywhere]` pattern (`inbound/detail_header.ex:51`).
- Scenario manifest + stories: `reference/persona_spec/quick_view_scenarios.ex`, `reference/demo_app/storybook/quick_views/inbound.story.exs`.

### Established Patterns
- Reads are synchronous in `handle_params`; LV processes events serially, so no out-of-order results.
- Tenant isolation enforced in read models (`lib/mailglass/operator/deliveries.ex:108-116`; `mailglass_inbound/.../internal/operator/records.ex:112-120`).
- Reveal auth at action time (`inbound_live.ex:432-444,1754-1768`); telemetry metadata limited to `tenant_id`/`record_id`/`outcome` (`:1780-1790`).

### Integration Points
- Forms: `operator_live.ex:931-978`, `inbound_live.ex:690-748`; field components `operator/filters_form.ex`, `inbound/filters_form.ex`.
- Lists: `operator/deliveries_list.ex:50-110,286-354`; `inbound/records_list.ex:56-131,199-203,378-400`.
- Inbound display: `inbound/detail_header.ex:37-146`, `inbound/quick_view.ex:114-121`, `components.ex:554-582` (`message_identity`), `inbound/evidence_card.ex`, `inbound/routing_trace.ex:171-249`.
- Schema: `mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_record.ex:46-51` (`envelope_recipient` string; `from/to/cc/bcc/reply_to` arrays of `%{address, name?}`).
- Clients: admin LV 1.2.13 (`mailglass_admin/mix.lock`), demo LV 1.1.33 (`reference/demo_app/mix.lock`). Admin JS hooks ship in committed `mailglass_admin/priv/static`.
</code_context>

<specifics>
## Specific Ideas

- Owner reaffirmed auto-apply on both collections (2026-10-26) — not a question of whether to keep Apply.
- "Another copy-paste is better than another dep": the focus hook and all behavior use LV/browser primitives only.
</specifics>

<deferred>
## Deferred Ideas

- Custom date ranges (From/To, timezone, DST) — SEED-261010-gad; separate from removing Apply.
- IDNA/punycode display and homograph (UTS #39 confusable) flagging for IDN domains — no stdlib IDNA; needs its own decision on implementation vs dependency.
- Header To/Cc in Inbound Quick view — requires widening the `mailglass_inbound` list projection (inbound release).
- Async reads (`start_async` + query-key guard) — only if measured p95 justifies it.

### Reviewed Todos (not folded)
None — no pending todos matched Phase 176.
</deferred>
