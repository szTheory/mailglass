# Phase 176: Direct Filters and Useful Inbound Evidence - Research

**Researched:** 2026-10-28
**Domain:** Phoenix LiveView URL-backed filter forms (commit-on-change + debounce + history), LiveView DOM-patch/focus semantics, Inbound address/evidence presentation in `mailglass_admin`
**Confidence:** HIGH (all load-bearing mechanics read from the pinned LiveView sources and the live code; browser-only behaviors flagged where only a real browser can settle them)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Commit path (FILTER-01, FILTER-02)
- **D-01:** Reuse the existing form → `push_patch` → `handle_params` → synchronous read path on both LiveViews. No `start_async`, no custom search controller, no new dependency. `phx-change` becomes the commit point: normalize → if error-free and `same_location?` is false → patch to canonical path. Keep `phx-submit` as the Enter commit (it flushes pending debounce — LV client increments the debounce cycle on submit). Remove the visible Apply button and its `phx-disable-with`.
- **D-02:** `phx-debounce="300"` on the search input only. Selects have no debounce. Not `"blur"`.
- **D-03:** Enter works by HTML implicit submission (each form has exactly one implicit-submission-blocking text field). Pin it with a browser test that fails if a second text/date field is added without restoring a submit control. No hidden submit button.
- **D-04:** Remove `load_provider_options` from the change handler (`handle_params` already loads it) so debounced commits don't add a read.
- **D-05:** Never disable or show a loading state on the search input during commits (it drops focus/caret).

#### History, pagination and Account (FILTER-03)
- **D-06:** History policy lives in one pure function (unit-tested) returning `:push | :replace`:
  - select change → push; Enter → push (no-op if `same_location?`); Clear → push; pagination → push;
  - debounced search commits → first commit of a "search edit" pushes, later debounced commits replace until a non-search commit/Enter/Clear ends the edit (track via an assign such as `:last_commit_kind`);
  - tenant canonicalization and reconnect recovery → always replace.
- **D-07:** Fix the existing Back trap: `:canonicalize_tenant` (`operator_live.ex:~221`, `inbound_live.ex:~510`) must patch with `replace: true`.
- **D-08:** Every filter commit drops `page` (explicit in code, not incidental) and drops selection (`delivery_id`/`inbound_id`/`full`). Pagination links are built from committed params. Canonical URLs drop defaults/blanks and build query strings from a sorted keyword list.
- **D-09:** Commits take `tenant_id` from server-held `socket.assigns.selected_tenant_id`; the hidden form `tenant_id` is ignored for commits (remove it if nothing else needs it). Account switching stays with the Account selector. `handle_params` remains the URL authorization gate.
- **D-10:** Focused-input Back/Forward: add a small copy-paste JS hook on the search input — a `popstate` listener marks a pending history navigation; in `updated()`, if pending and `el.dataset.committed !== el.value`, set the value. Server renders `data-committed` from committed params. Do NOT use `phx-patch-focused` (only LV ≥1.2.8; admin requires `~> 1.1`; demo is 1.1.33; and it would clobber typing after debounced commits). The hook ships in the admin's committed `priv/static` bundle — rebuild and commit it (CLAUDE.md "Things Not To Do" #6; mind the token-parity bundle landmine: rebuild JS only, verify TokenParityTest).
- **D-11:** Reconnect: `phx-auto-recover="recover_filters"` restores the draft and, only if valid and different from the URL, commits with replace. Never pushes.

#### Invalid input and failed reads (FILTER-04)
- **D-12:** Draft (`filter_form`) and committed (`filter_params`) stay separate. An invalid draft never commits: keep draft visible, `aria-invalid` + inline error linked by `aria-describedby`, specific copy. Results stay those of the committed URL; while an invalid draft is pending, show one short note that results still reflect the previous filters. Inbound gains Operator's raw-draft retention (`filter_draft_params` pattern) so its select never contradicts its error.
- **D-13:** Invalid values arriving via URL keep today's non-silent behavior (field error "… was not applied"), and results are explicitly labeled as excluding that filter. No unlabeled fallback population.
- **D-14:** Failed read, same committed query → keep rows labeled stale ("Showing results from HH:MM; refresh failed") — today's Operator rule. Failed read, new query → error panel ("Couldn't load deliveries/inbound messages for these filters") with Retry that re-reads without pushing history; no old rows, no empty-state copy, no fallback query, no counts. URL keeps the attempted (committed) filters.
- **D-15:** Fix the Operator `collection_header` that renders "0 deliveries" on error; hide the count when not `:ready` (Inbound already does). Inbound gains same-query stale retention and Retry for parity.
- **D-16:** One persistent polite `role="status"` region per collection, present from first render, updated only after `handle_params` settles a commit ("24 deliveries match", "No deliveries match these filters", "Couldn't load deliveries"). No announcements for drafts/keystrokes; never move focus.

#### Inbound contact display (INUX-05)
- **D-17:** Full-detail header renders a `<dl>` in order: **From**, **Reply-To** (only if present), **To**, **Cc** (only if present), **Delivered to** = `envelope_recipient` with hint "SMTP envelope recipient (RCPT TO), used for routing". Bcc omitted from default view. No invented Return-Path.
- **D-18:** `message_identity`'s recipient label becomes context-aware: Operator keeps "To"; Inbound (detail header and Quick view) uses "Delivered to". Quick view keeps only the envelope recipient — do not widen the `mailglass_inbound` list projection (would force an inbound release for a display change).
- **D-19:** Stop masking From in `sender_display/1`; render display name + `<addr>` as separate HEEx-escaped spans (no `raw`). Drop the name when missing or equal to the address; when the name contains an `@` differing from the addr-spec, show both (spoof cue).
- **D-20:** Multiple addresses: all, in header order, one per line (`<ul role="list">` in the `<dd>`); dedupe exact duplicates within a field only (domain case-insensitive, local part case-sensitive); over 5 → first 5 + native `<details>` "Show N more".
- **D-21:** Missing values are field-specific, never a bare "—": From → "No From header"; To → "No To header"; Delivered to → "Not recorded by provider"; Cc/Reply-To rows hidden when empty; unparseable → "Unparseable address" + escaped original.
- **D-22:** Unicode/EAI shown as received (UTF-8). Long values wrap with `[overflow-wrap:anywhere]` (existing pattern `detail_header.ex:51`); never truncate in detail views. List-row truncation stays (detail shows the full value). Per-address copy via existing `Components.copy_value`.
- **D-23:** Keep `Components.mask_recipient/1` / `mask_value/1` (public, `@doc since: "0.2.0"`). Routing-trace matcher expected/actual and subject masking stays unchanged. Do not cite D-30 as authority (PROJECT.md D-30 is the B2C safety profile); authority is `UPSTREAM-SCOPE.md` §76 and the ROADMAP planning focus.

#### Raw provider source card (INUX-06)
- **D-24:** One header group: `h3` "Raw provider source" + one disclosure button labeled with the action ("Reveal raw source" / "Hide raw source", persistent `aria-expanded`/`aria-controls`) + one caption "May contain personal information." Remove the "Raw source locked" badge, the inner second "Hide raw source" button, and the "hidden by default" paragraph. Don't say "logged" (telemetry is not an audit log). On mobile the button wraps below the heading full-width `min-h-11`.
- **D-25:** One compact `<dl>` (`grid sm:grid-cols-2 lg:grid-cols-4`) with uniform `dt`/`dd` styles: Provider, Received, Payload size (thousands-separated bytes), Header count, Provider authentication. No checksum (none stored).
- **D-26:** Truth fixes: `payload_byte_size` and `header_count` return `nil` (render "Unavailable") instead of 0 on unknown/encode failure. Revealed-but-empty → "Provider sent an empty payload." Not stored → keep "No raw provider source was stored for this message." and hide the button. Denied → "You don't have permission to reveal raw source." via the existing `role="status"` region. `<pre>` gets `tabindex="0"` + `aria-label` (keyboard-scrollable).
- **D-27:** Authorization, state atoms (`:redacted`/`:revealed`/`:denied`), reset-on-selection, and PII-free telemetry stay unchanged. Remove the dead `can_reveal?` attr (unused; auth happens at action time).

#### Verification (D-52 shift-left)
- **D-28:** ExUnit (merge-blocking `verify.support_contract.admin`): commit/no-commit, canonical paths, page reset, pagination preserving filters, tenant-field tampering ignored, history-policy pure function, invalid draft retention, URL-invalid labeling, fault-injected `:error` vs `:stale` (existing `operator_read_fault` seam), Back via `render_patch`, address rendering cases (long/Unicode/missing/multiple/display-name spoof), evidence card states, reveal auth.
- **D-29:** Playwright (Operator Browser Gate vs LV 1.2.13; demo e2e vs LV 1.1.33) for client-only behavior: `history.length` deltas per search edit, Enter and Clear during pending debounce, focus/caret stability, Back/Forward with focus in search (D-10 hook), reconnect with no added history entry, status-region text after settle, axe on invalid/error states. Report these lanes as advisory (not in `ci_green.needs`).
- **D-30:** (phase-local; unrelated to PROJECT.md D-30) `phase176_prohibition_contract_test.exs` (template: `phase175_prohibition_contract_test.exs`), each must-NOT mutation-proven: no visible Apply button; routing trace still masks; "Delivered to" bound to `envelope_recipient` and "To" to header `to`; denied/unauthorized routes never contain raw-payload sentinel bytes; reveal/detail telemetry metadata contains no addresses; unknown size/count never renders "0"; failed new-query read never renders empty-state copy or a count.
- **D-31:** Update coupled tests/specs that assert Apply or masked From (`operator_live_test.exs:184,318,363,380`, `inbound_live_test.exs:786`, `inbound/components_test.exs:327-374`, e2e `inbound-layout.spec.js:173-184`, `phase175-inbound.spec.js:137`, `phase169-journey.spec.js:571`). Trace-masked contracts (`inbound_live_test.exs:1220-1246,2259-2287`) stay.
- **D-32:** Retained scenarios: replace masked gallery fixtures (`gallery_live.ex:597,1279-1311`) with synthetic worst-case data; add production-component stories for EvidenceCard and Inbound DetailHeader driven by the existing scenario manifest (`reference/persona_spec/quick_view_scenarios.ex/.json`), no invented props.

### Claude's Discretion
- Exact debounce value may move within 250–400ms if browser tests show flakiness.
- Exact microcopy wording may be polished in a UI-SPEC within brand voice, keeping meaning.
- Whether the hidden `tenant_id` input is deleted or merely ignored.

### Deferred Ideas (OUT OF SCOPE)
- Custom date ranges (From/To, timezone, DST) — SEED-261010-gad; separate from removing Apply.
- IDNA/punycode display and homograph (UTS #39 confusable) flagging for IDN domains — no stdlib IDNA; needs its own decision on implementation vs dependency.
- Header To/Cc in Inbound Quick view — requires widening the `mailglass_inbound` list projection (inbound release).
- Async reads (`start_async` + query-key guard) — only if measured p95 justifies it.

Also out of scope (CONTEXT `<domain>`): widening the `mailglass_inbound` list projection; unmasking routing diagnostics.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FILTER-01 | Select filters apply immediately on both collections, no visible Apply | `validate_filters` becomes the commit handler (operator_live.ex:283, inbound_live.ex:277); `same_location?` guard exists (operator_live.ex:2320, inbound_live.ex:1922); Apply button + `phx-disable-with` located (operator_live.ex:965, inbound_live.ex:735); coupled tests/specs enumerated in "Coupled Test Inventory" |
| FILTER-02 | Debounced URL-backed search retaining input/focus and an immediate Enter commit | LV 1.2.13 + 1.1.33 debounce mechanics read from source: numeric debounce flushes on blur, form submit cancels pending cycles; focused-input value skip with attrs merged; WHATWG implicit submission rule confirmed |
| FILTER-03 | Back/Forward, Clear, pagination with canonical state, useful history, page reset, Account isolation | Pure history policy module + `pending_commit_kind` state machine; patch `kind` is observable in ExUnit (probe run); `:canonicalize_tenant` Back-trap sites located; hook design with the clobber pitfall |
| FILTER-04 | Invalid filters / failed reads give specific draft/error/stale feedback, no silent fallback | Existing Operator `:stale`/`:error` logic located (operator_live.ex:1554-1565); Inbound has no stale retention and its `RecordsList` `:stale` branch replaces rows; fault seams for both LiveViews inventoried (`deliveries` is NOT in the arm whitelist) |
| INUX-05 | Complete ordinary Inbound addresses; envelope vs header To distinct; protections intact | Masked From site (detail_header.ex:131-139); `detail.record` is the full `%InboundRecord{}` (has `to/cc/reply_to`); Quick view only has `envelope_recipient`; trace masking sites (routing_trace.ex:239,247) stay |
| INUX-06 | Coherent Raw provider source card; reveal authorization and safe projections intact | Current card structure read in full; one-button toggle requires event switching; `payload_byte_size` has a latent wrong-answer bug for MIME-backed evidence; auth/telemetry sites (inbound_live.ex:432-453,1754-1790) unchanged |
</phase_requirements>

## Summary

This phase is almost entirely a **reuse and rewire** job. Both LiveViews already implement form → `push_patch` → `handle_params` → synchronous read, with a no-op guard (`same_location?`). Today `phx-change` calls `validate_filters` (draft validation only) and `phx-submit` calls `apply_filters` (the only committer). The work is: make the change handler commit, add a small pure history-policy module, delete Apply, port Operator's draft retention and stale/error read states to Inbound, and add one tiny JS hook for Back/Forward with a focused search input. No new dependency is needed or recommended.

The LiveView facts that decide the design were read from source in both pinned clients (admin 1.2.13, demo 1.1.33). Three are easy to get wrong. (1) A numeric `phx-debounce` **also fires on blur**, so clicking "Clear filters" with a debounce pending (Chromium focuses a button on mousedown) flushes the pending commit before the click arrives; "Clear during pending debounce" is "commit then clear", not "cancel". (2) A form `submit` cancels pending debounce cycles on every named input, so Enter is clean. (3) A focused text input keeps its typed value across a patch but **still receives merged attributes** (`data-committed`) and **still fires a hook `updated()`**, which is exactly what the D-10 hook needs, but the hook has a clobber hazard if the "pending history navigation" flag is not cleared (see Pitfall 3).

The INUX work is two component rewrites (`Inbound.DetailHeader` contact `<dl>`, `Inbound.EvidenceCard` header/facts) plus a context-aware recipient label in `Components.message_identity`. Two latent defects surfaced that the plan should fold in: `EvidenceCard.payload_byte_size/1` reports "2 bytes" for MIME-backed evidence (the first clause always matches because `raw_payload` defaults to `%{}`), and `Inbound.RecordsList` renders `:stale` as a replacement for the rows rather than a panel above them.

**Primary recommendation:** Build one shared pure module (`MailglassAdmin.Operator.FilterCommit`, `@moduledoc false`) for history kind + canonical-path construction, wire `validate_filters` as the commit path in both LiveViews with a `pending_commit_kind` assign consumed in `handle_params`, add the `FilterSearchSync` hook to `priv/static/hooks.js` (hand-edited, not "rebuilt"), and pin everything server-observable in the merge-blocking admin ExUnit suite (which runs in about 4 seconds for the three affected files), leaving only genuinely client-only behavior to the advisory Playwright lane.

## Project Constraints (from CLAUDE.md)

- Zero human UAT (D-52): Claude closes verification as `source: automated`; must-NOT prohibitions are authored `verification: test` and mutation-proven (template `phase175_prohibition_contract_test.exs`). Recurring checks go into an existing merge-blocking lane.
- Telemetry: never PII (no `:to`, `:from`, `:body`, `:html_body`, `:subject`, `:headers`, `:recipient`, `:email`). Reveal telemetry metadata stays `tenant_id`/`record_id`/`outcome` only.
- Errors by struct, never by message string.
- Do not write to `mailglass_admin/priv/static/` without committing the rebuilt bundle (CI `git diff --exit-code`). `hooks.js` is hand-maintained; `app.css` is produced by `mix mailglass_admin.assets.build`.
- Local toolchain: `export ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27` (bare `mix` fails with a misleading `corrupt atom table`). Do not "fix" `.tool-versions`.
- No Node toolchain for adopters (Playwright is dev-only and acceptable).
- Brand voice: specific, composed errors; no "Oops"; `voice_test.exs` bans `oops`, `whoops`, `uh oh`, `something went wrong` across rendered Preview/Operator/Inbound surfaces.
- Decision policy: research first, decide, escalate rarely; this document recommends and flags only items that could change a locked contract.
- Heroicons: new `hero-*` icons render invisibly unless embedded in `heroicons-inline.js` (UI-SPEC already forbids new icons; `ICON-EXISTS-GATE` enforces).
- Commit conventions: Conventional Commits; admin UI changes should not be `feat(...)` on the core path unless intended (release-please path claims); use scoped commit types consistent with Phase 175.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Filter commit decision (valid? same location? push vs replace) | LiveView server (`handle_event` + pure policy module) | Browser (event timing only) | URL is the source of truth; server owns authorization (`handle_params`) and Account (`selected_tenant_id`). |
| Search debounce | Browser (LV client `phx-debounce`) | — | Pure client timing; server sees only settled change events. |
| Enter-to-commit | Browser (HTML implicit submission) | LiveView (`phx-submit`) | Browser fires `submit`; LV client cancels pending debounce cycles and pushes the event. |
| Back/Forward value restore for a focused input | Browser (hook on `popstate`/`updated`) | LiveView (renders `data-committed`) | Server cannot overwrite a focused input's value; only client JS can. |
| Reconnect draft recovery | Browser (LV form recovery) | LiveView (`recover_filters` event) | LV client replays the old form's values through the named event before applying the mount patch. |
| Read, stale/error classification, retry | LiveView server (`assign_*_state`) | Read model (tenant scoping) | Reads are synchronous in `handle_params`; classification is server state. |
| Result announcement (`role="status"`) | LiveView server (text) | Browser (AT announcement) | Text assigned after a settled commit; the browser/AT does the announcing. |
| Address/evidence display | LiveView components (HEEx) | Inbound read model (full `%InboundRecord{}`) | Pure presentation; authorization stays at action time and in the tenant-scoped read. |
| Raw reveal authorization | LiveView server (`authorize_reveal/1` at action time) | — | Unchanged; bytes must never be in denied HTML. |

## Standard Stack

### Core

No new packages. Everything is already in the lockfiles.

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| phoenix_live_view (admin) | 1.2.13 | LiveView runtime + JS client | `[VERIFIED: mailglass_admin/mix.lock]` pinned `"phoenix_live_view", "1.2.13"`; requirement is `{:phoenix_live_view, "~> 1.1"}` `[VERIFIED: mailglass_admin/mix.exs:112]` |
| phoenix_live_view (demo app) | 1.1.33 | Second pinned client the admin must work against | `[VERIFIED: reference/demo_app/mix.lock and reference/demo_app/deps/phoenix_live_view/package.json "version": "1.1.33"]` |
| Phoenix.Component / HEEx | via LV | Components, `to_form`, `:global` attrs | existing |
| ExUnit + Phoenix.LiveViewTest + Floki | existing | Merge-blocking tests | existing; 236 tests across the three affected files pass in ~3.5s `[VERIFIED: ran, seed 0]` |
| Playwright | 1.59.1 | Advisory connected-browser lane | `[VERIFIED: npx playwright --version]`; Chromium builds present locally |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Tailwind 4.1.12 + vendored daisyUI 5.5.19 | existing | CSS bundle via `mix mailglass_admin.assets.build` | After HEEx changes that add utilities (see Pitfall 8) |
| `Phoenix.LiveView.JS` | LV | Existing toggles for the mobile Filters panel | keep as is |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Custom Back/Forward hook (D-10) | `phx-patch-focused` | Present in 1.2.13, **absent in the demo's 1.1.33** (0 occurrences in `phoenix_live_view.js`); it would also overwrite typing after debounced commits. Locked out by D-10. |
| `phx-debounce="300"` | `phx-throttle` / JS-side debounce | Throttle sends mid-typing events immediately; no benefit. Locked D-02. |
| Hidden submit button for Enter | Implicit submission | Locked D-03; a hidden button is an a11y smell. |

**Installation:** none.

**Version verification:** LiveView versions read from the lockfiles and `deps/*/package.json` above; no registry lookups were required because no package is added.

## Package Legitimacy Audit

No external packages are installed in this phase. The `package-legitimacy` gate is therefore not applicable.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| (none) | — | — | — | — | — | — |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
 Browser (operator)                         LiveView process (one per tab)                  Read model / DB
 ──────────────────                         ───────────────────────────────                 ───────────────
 typing in Search ──input──► [LV client debounce 300ms] ─┐
   (blur also flushes the pending debounce)              │
 select change  ───change──► (no debounce) ──────────────┤  phx-change="validate_filters"
 Enter in Search ──submit──► (cancels pending cycles) ───┤  phx-submit="apply_filters"      ┌─ commit path (same fn) ─────────────────────────┐
 Clear click    ──click───► phx-click="clear_filters" ───┤                                  │ 1. force tenant_id = assigns.selected_tenant_id  │
 reconnect ── LV form recovery ► phx-auto-recover ───────┘                                  │ 2. normalize_filter_params_with_errors            │
                                                                                            │ 3. errors? ─yes─► keep draft + inline errors +    │
                                                                                            │      "previous filters" note, NO patch            │
                                                                                            │ 4. drop page + delivery_id/inbound_id/full        │
                                                                                            │ 5. canonical path (blank/page=1 dropped, sorted)  │
                                                                                            │ 6. same_location?(page_uri, path) ─yes─► no-op    │
                                                                                            │ 7. FilterCommit.history_kind(kind, last_kind)     │
                                                                                            │ 8. set pending_commit_kind; push_patch(replace?)  │
                                                                                            └───────────────┬──────────────────────────────────┘
                                                                                                            ▼
 URL changes (push or replace) ◄──────── LV client history ◄──────────── handle_params(params, uri)  ◄── also: Back/Forward (popstate),
                                                                          │  authorization gate                 pagination links, tenant switch
                                                                          │  normalize URL params (errors → labeled)
                                                                          │  last_commit_kind = pending or nil; pending = nil
                                                                          ▼
                                                              assign_*_state ── synchronous read ──► Deliveries / Inbound read model (tenant-scoped)
                                                                          │         ├─ ok     → rows, count, announcement text
                                                                          │         ├─ fail, same query key  → :stale (retain rows, loaded_at)
                                                                          │         └─ fail, new query key   → :error (no rows/count/empty copy) + Retry
                                                                          ▼
 DOM patch ◄─── diff ◄── render: filter form (draft), data-committed (committed search), status region, list/panels
   │  focused Search keeps its typed value, but merged attrs (data-committed) apply and hook updated() fires
   ▼
 FilterSearchSync hook: popstate sets pending=true; on updated(), if pending and value != data-committed → set value, caret to end;
                        pending is cleared on next updated(), on input/keydown, and by a short timer (Pitfall 3)
```

### Recommended Project Structure

```
mailglass_admin/
├── lib/mailglass_admin/
│   ├── operator/filter_commit.ex   # NEW pure module: history_kind/2, commit_params/2, canonical_path/3 (@moduledoc false)
│   ├── operator/filters_form.ex    # attrs: committed_search, remove nothing structural (FORM-DRIFT-GATE: no raw <input>/<label>)
│   ├── inbound/filters_form.ex     # same
│   ├── inbound/detail_header.ex    # contact <dl>, drop sender_display masking
│   ├── inbound/evidence_card.ex    # header group, facts <dl>, nil-vs-0, one toggle button
│   ├── inbound/records_list.ex     # :stale = panel above rows; :error copy; Retry sibling
│   ├── operator/deliveries_list.ex # header count only when :ready; stale/error copy; Retry sibling
│   ├── components.ex               # message_identity recipient label by context (no new public component)
│   ├── operator_live.ex            # commit path, draft/committed, pending_commit_kind, announcement, replace on canonicalize
│   └── inbound_live.ex             # same + stale retention + retry + draft retention
├── priv/static/hooks.js            # + FilterSearchSync (hand-edited; embedded at compile time by controllers/assets.ex)
├── priv/static/app.css             # rebuilt only if new utilities appear (rebuild is currently byte-idempotent)
├── test/mailglass_admin/
│   ├── operator/filter_commit_test.exs            # NEW pure-function tests
│   ├── phase176_prohibition_contract_test.exs     # NEW (template: phase175_prohibition_contract_test.exs)
│   └── (operator_live_test, inbound_live_test, inbound/components_test, inbound/evidence_card_test updated)
└── e2e/phase176-filters.spec.js                   # NEW advisory Playwright (client-only behavior)
```

### Pattern 1: Single commit function with a history kind

**What:** Both LiveViews route `validate_filters` (change), `apply_filters` (submit/Enter) and `recover_filters` (reconnect) through one private `commit_filters(socket, filters, kind)` that returns `{:noreply, socket}`; `clear_filters`, pagination and canonicalization call the same history-kind function.
**When to use:** always for this phase; it is the seam the pure-function test and the prohibition contract pin.
**Example (shape, derived from the verified existing handlers):**

```elixir
# Source: operator_live.ex:249-281 (existing apply_filters) restructured; kinds per D-06
# Quoted existing values this relies on:
#   phx-change="validate_filters"   phx-submit="apply_filters"   phx-click="clear_filters"
#   "apply_filters" handler: same_location?(socket.assigns.page_uri, path) -> {:noreply, socket}
defp commit_filters(socket, filters, kind) when kind in [:search, :select, :enter, :recover] do
  filters = Map.put(filters, "tenant_id", socket.assigns.selected_tenant_id || "")   # D-09
  {normalized, errors} = normalize_filter_params_with_errors(filters)

  if map_size(errors) == 0 do
    path = canonical_path(socket, normalized)                                        # drops page + selection (D-08)

    if same_location?(socket.assigns.page_uri, path) do
      {:noreply, assign(socket, :filter_form, to_form(normalized, as: :filters))}    # draft == committed
    else
      replace? = FilterCommit.history_kind(kind, socket.assigns.last_commit_kind) == :replace
      {:noreply,
       socket
       |> assign(:pending_commit_kind, kind)
       |> push_patch(to: path, replace: replace?)}
    end
  else
    {:noreply,
     socket
     |> assign(:filter_form, to_form(filter_draft_params(filters, normalized), as: :filters))
     |> assign(:filter_errors, errors)}                                              # D-12: never commit
  end
end
```

`handle_params` then does `last = socket.assigns.pending_commit_kind; assign(last_commit_kind: last, pending_commit_kind: nil)`. Any patch that did not originate from a commit (Back/Forward, pagination link, selection, tenant switch) arrives with `pending_commit_kind == nil`, which correctly **ends** a search edit.

### Pattern 2: Pure history policy (D-06)

```elixir
defmodule MailglassAdmin.Operator.FilterCommit do
  @moduledoc false
  @type kind :: :search | :select | :enter | :clear | :page | :recover | :canonicalize
  @spec history_kind(kind(), kind() | nil) :: :push | :replace
  def history_kind(:search, :search), do: :replace   # continue an in-progress search edit
  def history_kind(:search, _other), do: :push       # first commit of a search edit
  def history_kind(kind, _last) when kind in [:recover, :canonicalize], do: :replace
  def history_kind(_kind, _last), do: :push          # select, enter, clear, page
end
```

Recommended refinement (flagged, A6): `history_kind(:enter, :search) -> :replace`, so Enter finalizing an in-flight search edit does not create a second entry for one intent. D-06's text says Enter pushes; in the common case Enter after a settled debounce is a no-op via `same_location?`, so the refinement only matters when Enter lands before the debounce fires.

### Pattern 3: Focused-input Back/Forward hook (D-10)

```javascript
// Source: design from dom_patch.ts:476-487 (focused inputs merge attrs except "value", then updates.push)
// Add to window.MailglassAdminHooks in mailglass_admin/priv/static/hooks.js
FilterSearchSync: {
  mounted() {
    this.pending = false
    this.clearPending = () => { this.pending = false }
    this.onPop = () => {
      this.pending = true
      clearTimeout(this.pendingTimer)
      this.pendingTimer = setTimeout(this.clearPending, 1500)   // Pitfall 3: never leave the flag armed
    }
    window.addEventListener("popstate", this.onPop)
    this.el.addEventListener("input", this.clearPending)         // user typing disarms
  },
  updated() {
    if (!this.pending) return
    this.pending = false
    const committed = this.el.dataset.committed ?? ""
    if (this.el.value !== committed) {
      this.el.value = committed
      this.el.setSelectionRange?.(committed.length, committed.length)
    }
  },
  destroyed() {
    window.removeEventListener("popstate", this.onPop)
    this.el.removeEventListener("input", this.clearPending)
    clearTimeout(this.pendingTimer)
  }
}
```

The element needs a stable DOM id (`filter_field` already derives `filters_search` from the form field) and `phx-hook="FilterSearchSync"`; `phx-hook` and `data-committed` pass through `filter_field`'s `:global` rest `[VERIFIED: components.ex filter_field attr :rest, :global, include: ~w(autocomplete inputmode list max min pattern placeholder step)]` (the `phx-` prefix, `data-*` and `enterkeyhint` are in Phoenix's default global set `[ASSUMED: Phoenix.Component global attribute defaults]`; a one-line component test pins it).

### Pattern 4: Read-state classification (reuse Operator's rule for Inbound)

Operator today keeps rows only when `socket.assigns.deliveries != [] and socket.assigns.deliveries_loaded_for == query_key` `[VERIFIED: operator_live.ex:1559-1561]`. Port the same to Inbound with an `inbound_loaded_for` assign set only on `:ok` reads, plus a `*_loaded_at` timestamp for the stale title.

### Anti-Patterns to Avoid

- **Disabling, re-keying or loading-stating the search input** (D-05): drops focus/caret. No `phx-disable-with`, no `disabled`, no `id` that changes per commit.
- **Mapping the draft form to committed params inside `handle_params` only**: an invalid draft would be overwritten by the next patch. Keep `filter_form` (draft) and `filter_params` (committed) separate; derive `data-committed` from `filter_params`.
- **Trusting `filters["tenant_id"]`** from the change payload (D-09). Overwrite before normalizing.
- **Using `phx-patch-focused`** (breaks demo 1.1.33; clobbers typing).
- **A second text-like input in either form** without restoring a submit control: implicit submission stops working (D-03).
- **Putting the "previous filters" note or raw markup in the `filters_form.ex` wrappers**: `FORM-DRIFT-GATE` rejects direct `<input|select|label|textarea>` and old class signatures there; keep notes in the LiveView.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Search debounce | custom server timers / JS timers | `phx-debounce="300"` | LV client already handles per-element cycles, blur flush, and submit cancellation (dom.ts:324-430) |
| Enter commit | key handlers / hidden submit | HTML implicit submission + `phx-submit` | WHATWG rule; LV cancels pending debounces on submit |
| Reconnect draft recovery | localStorage persistence | `phx-auto-recover="recover_filters"` | LV replays the old form through the named event before the mount patch (view.ts:808-900, 2607-2660) |
| History entry control | `History.pushState` from JS | `push_patch(replace: true)` | Server already knows the intent; LV skips pushState when href is unchanged |
| Collapsible "Show N more" | custom JS | native `<details>/<summary>` | Locked by D-20; no JS |
| Address parsing | RFC 5322 parser | Render the stored `%{address, name}` maps as received; label failures "Unparseable address" | Ingest already parsed them; IDNA/UTS #39 explicitly deferred |
| Copy-to-clipboard | new JS | `Components.copy_value` | Existing shared toast pattern |
| Result announcement | JS aria-live injector | one persistent server-rendered `role="status"` | D-16 |
| Query-string building | ad hoc concatenation | existing `build_path` (`URI.encode_query` over a map) | already drops blanks and `page=1`; see Open Question 1 |

**Key insight:** every behavior the phase needs exists either in LiveView's client (debounce, recovery, submit cancellation) or in this codebase (normalization, `same_location?`, stale rule, `copy_value`, masking helpers). The new code is wiring plus one 25-line hook.

## Runtime State Inventory

Not applicable. This is not a rename/refactor/migration phase. (The only persisted artifact touched is the committed `priv/static` bundle, covered in Pitfall 8.)

## Common Pitfalls

### Pitfall 1: "Clear during pending debounce" is commit-then-clear, not cancel
**What goes wrong:** A test expects that typing "abc" then clicking Clear leaves the URL untouched. In Chromium the Clear button takes focus on mousedown, the search input blurs, and LV's numeric debounce **fires immediately on blur** `[VERIFIED: dom.ts:402-424 blur listener calls triggerCycle]`. The server therefore receives `change(search=abc)` (commit, history push) and then `clear_filters` (second push).
**Why it happens:** debounce value `"300"` is numeric; only form `submit` increments the cycle to cancel `[VERIFIED: dom.ts:402-411]`.
**How to avoid:** Specify the end state (cleared URL, empty input, rows restored) and the `history.length` delta of 2 for that sequence; do not assert "no intermediate commit". Safari does not focus buttons on click, so the intermediate commit may not occur there; assert only the final state cross-browser. If a cleaner trace is wanted, the Clear control can `phx-click` with `JS.dispatch` ordering, but that is not required by FILTER-03.
**Warning signs:** a Playwright assertion on `history.length === before + 1` after typing then Clear.

### Pitfall 2: `render_change` does not model debounce
**What goes wrong:** ExUnit `render_change`/`render_hook` bypass the browser's debounce and blur logic, so unit tests cannot prove debounce timing or flush behavior.
**How to avoid:** In ExUnit pin the **DOM contract** (`phx-debounce="300"` on the search input only; no debounce on selects; `phx-hook`; `data-committed`; exactly one text-like input per form; no `type="submit"` and no `phx-disable-with` in the filter form) and the **server contract** (commit/no-commit/history kind). Leave timing to Playwright.

### Pitfall 3: The Back/Forward hook can clobber typing
**What goes wrong:** `popstate` arms `pending`. If the navigation produced no patch that touches the input (committed search unchanged), `updated()` does not run to disarm it. The next debounced commit then patches `data-committed="abc"` while the user has typed "abcd"; `updated()` sees `pending` and overwrites "abcd" with "abc".
**How to avoid:** disarm on the next `updated()`, on any `input` event, and on a short timer (the Pattern 3 sketch does all three). Add a Playwright case: Back (no search change) then type then wait for the commit and assert the input still holds the full typed text.
**Warning signs:** typed characters vanishing 300ms after a Back press.

### Pitfall 4: `Operator` and `Inbound` normalize search differently
**What goes wrong:** Operator trims search (`String.trim()` at operator_live.ex normalization) and Inbound does not (`normalize_string` only). A debounced commit while typing "foo " rewrites the URL to `search=foo` in Operator but `search=foo%20` in Inbound (the latter is dropped by `build_path` only when the whole value is blank).
**How to avoid:** decide once and test both: recommended is trimming in both at commit time, keeping the draft untrimmed so typing is unaffected. Pin with a canonical-path unit test.

### Pitfall 5: Filter commit silently drops Operator support-focus state
**What goes wrong:** the Operator URL carries `support_focus`, `support_event_id`, `support_webhook_event_id` `[VERIFIED: operator_live.ex:2565-2574]`. Today only Apply drops them (via `default_support_state()`), and the select change never patched. With commit-on-change, every routine select change would close the support-focus panel. An existing Playwright test asserts the opposite: `phase168-plan03-acceptance.spec.js:171` selects a Provider on `?support_focus=failed_ingest` and expects `operator-support-focus-detail` to remain the same node with zero animation starts.
**How to avoid:** resolve Open Question 2. Recommended: carry `socket.assigns.support_state` through filter commits (it is not a "selection" per D-08's list). If instead it is dropped, rewrite that e2e test deliberately.

### Pitfall 6: Invalid *draft* is unreachable from the normal UI
**What goes wrong:** the filter selects only offer valid options and Operator/Inbound search has no validation, so a browser user cannot produce an invalid draft by clicking. Tests that try to produce one with Playwright selects will not.
**How to avoid:** exercise invalid draft through `render_hook(view, "validate_filters", %{...})` in ExUnit (existing tests already do), and invalid URL via `page.goto(...?event=bogus)` in Playwright. Do not spend budget simulating an invalid select choice.

### Pitfall 7: `Inbound.RecordsList` `:stale` replaces the rows
**What goes wrong:** the `cond` has `@data_state == :stale -> <Components.data_state kind={:stale} ...>` **before** the rows branch `[VERIFIED: records_list.ex:94 and cond at :65]`, so a stale Inbound page shows only the panel. Operator renders the stale panel above the rows (deliveries_list.ex:58 `:if={@data_state == :stale}` outside the `cond`).
**How to avoid:** mirror Operator's layout: stale panel as a sibling above the `cond`, rows still rendered.

### Pitfall 8: New Tailwind utilities need a bundle rebuild, and it is currently safe
**What goes wrong:** classes introduced in HEEx (for example `sm:ml-auto`, `lg:grid-cols-4`) do not exist in the committed `priv/static/app.css` until it is rebuilt; ExUnit substring tests do not catch it.
**Evidence:** `mix mailglass_admin.assets.build` run on current `main` produced **no diff** in `priv/static` `[VERIFIED: ran it, git status clean]`, and `token_parity_test`, `assets_test`, `bucket_a_coverage_test` pass (21 tests, 0 failures) `[VERIFIED: ran]`. The old token-parity landmine therefore does not currently fire; still run `TokenParityTest` after any rebuild. `hooks.js` is **not** built: the assets controller embeds it at compile time (`controllers/assets.ex:64-69`, `@external_resource @hooks_path`) and `assets_test.exs:110` checks it is served once.
**How to avoid:** run the build after the last HEEx edit, commit the diff, run `git diff --exit-code priv/static/` (this is what `verify.preview` does).

### Pitfall 9: `payload_byte_size/1` answers "2 bytes" for MIME-backed evidence
**What goes wrong:** `payload_byte_size(%{raw_payload: payload}) when is_map(payload)` is the first clause `[VERIFIED: evidence_card.ex:155]`, and the schema defaults `raw_payload` to `%{}` `[VERIFIED: inbound_evidence.ex "field(:raw_payload, :map, default: %{}, redact: true)"]`. For Mailgun/SendGrid evidence whose bytes live in `raw_mime`, the map clause matches and returns `byte_size("{}")` = 2; the `raw_mime` clause at :161 is unreachable for loaded structs.
**How to avoid:** order clauses by "what actually holds the bytes": non-empty `raw_mime` → `byte_size/1`; non-empty map → encoded size; both empty → `0` only when the evidence is known-empty, `nil` ("Unavailable") when the encode fails or neither field is present. Add a table test including a `raw_mime`-backed row.

### Pitfall 10: Hidden `tenant_id` and the Account contract
**What goes wrong:** removing the hidden field changes the change payload: `filters["tenant_id"]` is absent and `normalize_filter_params_with_errors` defaults it to `""`, silently committing a URL with no Account.
**How to avoid:** always overwrite `tenant_id` from `assigns.selected_tenant_id` before normalizing (Pattern 1). `components_test.exs:1460,1509` assert `name="filters[tenant_id]"` is **absent** in other forms, so deleting the field is compatible; existing LiveView tests that send `tenant_id` in `render_hook` payloads remain valid because it is ignored.

### Pitfall 11: Two "Clear filters" buttons share `phx-click="clear_filters"`
**What goes wrong:** the toolbar button (operator_live.ex:972, inbound_live.ex:742) and the empty-state button both exist; `element(view, "[phx-click=clear_filters]")` raises "got 2" `[VERIFIED: probe run]`.
**How to avoid:** scope selectors (`#operator-filters [phx-click=clear_filters]`) or use `render_hook(view, "clear_filters", %{})`.

### Pitfall 12: Identical consecutive announcements are not re-announced
**What goes wrong:** an `aria-live` region whose text is unchanged is not re-read, so two consecutive commits that both produce "24 deliveries match" are silent.
**How to avoid:** accept (the visible count is also present) or include the active filter summary in the text; do not add noisy workarounds. Keep text identical across reconnect re-reads on purpose (UI-SPEC: no re-announce).

### Pitfall 13: Conformance gates run in merge-blocking CI
**What goes wrong:** `check-conformance.sh` (inside the required `conformance_gates` lane) bans: raw type-scale utilities (`text-sm` etc.), `font-medium/semibold`, `gap-3/4/6`, off-grid numeric spacing and a same-tone card signature **in the eight group-surface files, including `inbound/detail_header.ex` and `inbound/evidence_card.ex`**, hard-coded hex, and direct form markup in the two `filters_form.ex` wrappers.
**How to avoid:** use token utilities (`gap-sm`, `space-y-sm`, `px-md`, `mt-xs`); run `bash mailglass_admin/scripts/check-conformance.sh` (currently prints `OK: design-system conformance clean.`).

## Code Examples

### Current handlers being replaced (quoted verbatim for the plan to anchor on)

```elixir
# Source: mailglass_admin/lib/mailglass_admin/operator_live.ex:283
def handle_event("validate_filters", %{"filters" => filters}, socket) do
# ...
     |> assign(:provider_options, load_provider_options(normalized))}     # D-04: remove this line
```

```heex
<%!-- Source: operator_live.ex:944-945 and :965 --%>
phx-change="validate_filters"
phx-submit="apply_filters"
phx-disable-with="Applying filters…"
```

### Form after the change (Operator; Inbound is analogous)

```heex
<.form
  for={@filter_form}
  id="operator-filters"
  phx-change="validate_filters"
  phx-submit="apply_filters"
  phx-auto-recover="recover_filters"
  class="mt-md grid gap-md md:mt-0 xl:grid-cols-[minmax(0,1fr)_auto] xl:items-end"
>
  <FiltersForm.fields form={@filter_form} committed_search={@filter_params["search"]} ... />
  <button type="button" phx-click="clear_filters" class="btn btn-ghost min-h-11 px-md">Clear filters</button>
</.form>
```

```heex
<%!-- In FiltersForm.fields: only the search field changes; no new markup in the wrapper (FORM-DRIFT-GATE) --%>
<Components.filter_field
  field={@form[:search]}
  label="Search"
  placeholder="Subject or recipient"
  phx-debounce="300"
  phx-hook="FilterSearchSync"
  data-committed={@committed_search}
  autocomplete="off"
  enterkeyhint="search"
/>
```

### Asserting patch kind in ExUnit (probe-verified)

```elixir
# Source: probe run 2026-10-28 -> PROBE: {:push, "/ops/mail?tenant_id=test-tenant&view=deliveries"}
{ref, topic, _pid} = view.proxy
render_hook(view, "clear_filters", %{})
assert_receive {^ref, {:patch, ^topic, %{kind: :push, to: to}}}
# replace case: %{kind: :replace}; assert_patch/2 alone cannot see the kind.
```

### Address row (INUX-05) skeleton

```heex
<%!-- All text HEEx-escaped; no raw/1. Values come from detail.record (full %InboundRecord{}) --%>
<ul role="list" class="space-y-sm">
  <li :for={addr <- @shown}>
    <span :if={addr.name}>{addr.name}</span>
    <Components.copy_value value={addr.address} label={@copy_label} />
    <p :if={addr.spoof?} class="text-label text-warning">Display name contains a different address.</p>
  </li>
</ul>
<details :if={@rest != []}>
  <summary class="mg-focus-ring min-h-11 content-center text-label font-bold text-secondary">Show {length(@rest)} more</summary>
  <ul role="list" class="space-y-sm"><li :for={addr <- @rest}>...</li></ul>
</details>
```

Address maps round-trip through JSONB with **string** keys but freshly built structs use atom keys; keep the dual-key reader (`address_value/1`) that already exists in detail_header.ex.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Draft-validate on change, commit on Apply | Commit on change + debounced text + Enter | this phase | FILTER-01/02; must keep URL canonical and history sane |
| Server cannot fix a focused input's value | `phx-patch-focused` (LV ≥ 1.2.x, absent in 1.1.33) or a hook | LV 1.2 line | hook is the only option that works for both pinned clients |
| Mask all Inbound contact PII in detail | Show ordinary contact addresses to authorized operators; keep trace/subject masking | this phase (UPSTREAM-SCOPE §76) | INUX-05 |

**Deprecated/outdated:** the "Raw source locked" badge, the inner second "Hide raw source" button, and the `Raw source is hidden by default…` paragraph are removed (D-24).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `phx-patch-focused` first appeared in LV 1.2.8 (CONTEXT D-10). Verified only that it is present in 1.2.13 and absent (0 hits) in 1.1.33. | Standard Stack / Alternatives | Low; decision does not depend on the exact version |
| A2 | Chromium focuses a clicked `<button>` on mousedown (blurring the input) and Safari does not, so "Clear during pending debounce" differs by browser. | Pitfall 1 | Medium for test design only; assert end state, not intermediate commits |
| A3 | Hook `updated()` fires for a focused input in LV 1.1.33 as it does in 1.2.13 (verified in 1.2.13 `dom_patch.ts:476-487`; 1.1.33 bundle shows the same `mergeFocusedInput` call at line 2554 but `updates.push` was not read). | Pattern 3 | Medium; demo e2e (advisory) is the proof, plan a Wave 0 browser spike |
| A4 | `phx-*`, `data-*`, `enterkeyhint` pass through `Phoenix.Component` `:global` defaults. | Pattern 3 | Low; one component test settles it |
| A5 | Recommended: Enter finalizing an in-flight search edit uses `:replace` (not in D-06). | Pattern 2 | Low; alternative is the literal D-06 |
| A6 | IME composition (CJK) is not disrupted by a debounced commit because focused input values are never patched. | Pitfall list | Low; cannot be automated easily |
| A7 | Recommended server-formatted stale time as `HH:MM UTC` or `Components.timestamp`; no existing deliveries stale timestamp exists. | Open Question 3 | Low |

## Open Questions (RESOLVED)

All five questions were resolved during planning (orchestrator decisions recorded in the named plans). Plan numbers below are the post-revision numbering (checker iteration 1).

1. **Does D-08 "drop defaults" mean dropping `window_hours=168` from canonical URLs?**
   - What we know: current `build_path` drops only blanks and `page=1`; an existing test asserts the patched URL **includes** `"window_hours" => "168"` (`operator_live_test.exs:200-209`), and `same_location?` compares decoded queries, so a mismatch between "explicit default in the current URL" and "default dropped by the canonical builder" would cause a spurious replace on every commit.
   - What's unclear: whether D-08 intends a URL contract change.
   - Recommendation: keep today's shape (drop blanks and `page=1` only), treat "defaults" as the blank/`page=1` defaults, and add a canonical-path unit test. Revisit only with a deliberate URL-contract note.
   - **RESOLVED:** `window_hours=168` is kept in canonical URLs; only blanks and `page=1` are dropped, keys sorted with `Enum.sort/1` (orchestrator decision 1). Implemented in 176-01 (`FilterCommit.encode_query/1`, task 176-01-01; canonical-query unit rows, task 176-01-02).

2. **Should filter commits carry Operator `support_state`?**
   - What we know: Apply drops it today; select change did not patch so the panel survived; `phase168-plan03-acceptance.spec.js:171` expects the panel to survive a select change.
   - Recommendation: carry `support_state` (it is neither page nor selection), keeping that spec valid. If the plan chooses to drop it, update that spec explicitly.
   - **RESOLVED:** `support_state` is carried through filter commits (orchestrator decision 2). Implemented and browser-proven in 176-01 (task 176-01-01 runs `phase168-plan03-acceptance.spec.js` unchanged).

3. **Stale-result time: what is "HH:MM"?**
   - What we know: no deliveries-list timestamp exists; only `deliveries_loaded_for` is stored (operator_live.ex:1651-1654). `Components.timestamp` renders UTC server-side and localizes client-side.
   - Recommendation: store `deliveries_loaded_at` (UTC) on each `:ready` read and render it with `Components.timestamp` in the stale panel body; use `HH:MM UTC` in the sr-only status text. Brand voice allows either; tests assert the presence of the stored time, not a timezone.
   - **RESOLVED:** `loaded_at` is stored (UTC, second precision) only on successful reads; the stale title carries a server-formatted `HH:MM UTC` via `ResultsStatus.stale_title/1` and the localized `Components.timestamp` renders as a sibling line (orchestrator decision 3). Deliveries in 176-04 (task 176-04-02); Inbound parity in 176-09.

4. **D-25 states "No checksum (none stored)".** `InboundEvidence` stores `raw_mime_sha256` and `raw_mime_fingerprint` `[VERIFIED: inbound_evidence.ex schema]`. The decision to omit it stands (INUX-06 asks for five compact facts), but the rationale should read "not part of the five required facts", not "none stored". No behavior change.
   - **RESOLVED:** the checksum is omitted as a scope choice (INUX-06's five compact facts), and any doc/comment states that rationale rather than "none stored" (orchestrator decision 4). Recorded in 176-05 (the facts plan split from the former 176-03).

5. **Playwright lanes are advisory (D-29) but D-52 prefers merge-blocking.** The Operator Browser Gate is not in `ci_green.needs` `[VERIFIED: ci.yml needs list lines 1433-1452 omit the browser job at :955]`. Recommendation: follow the Phase 175 precedent (advisory for client-only behavior) and compensate with ExUnit DOM-contract pins (Pitfall 2) so a regression in any server-observable part is merge-blocking.
   - **RESOLVED:** Playwright lanes stay advisory (not in `ci_green.needs`) per D-29 and the Phase 175 precedent; every server-observable part is pinned by merge-blocking ExUnit DOM contracts (176-01-01, 176-06-01, 176-07-02) and the mutation-proven prohibition contract, with lanes reported as advisory in 176-10. (The related Enter-after-in-flight-search rule — Enter returns `:replace` when the last commit kind is `:search` — is assumption A5 / orchestrator decision 5, encoded in the `history_kind/2` truth table in 176-01-02.)

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/OTP (via ASDF override) | all mix tasks | ✓ | OTP 27.3.4.15 / Elixir 1.18.4-otp-27 (`.tool-versions` pins .13, not installed) | export `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27` |
| PostgreSQL | admin ExUnit + browser server | ✓ | accepting connections on :5432 | — |
| Node | Playwright | ✓ | v26.10.0 | — |
| Playwright + Chromium | advisory browser lane | ✓ | 1.59.1; chromium-1200..1228 cached | — |
| Admin browser server | `test:operator-browser` | ✓ | self-boots (`phase169-journey.spec.js --grep "Phase 169 filter history"` passed, 1.7s) | — |
| Demo app e2e | LV 1.1.33 coverage | ✓ deps present (`reference/demo_app/assets/node_modules`) | not executed this session | run per Phase 175 command |
| Tailwind standalone (macOS arm64) | `assets.build` | ✓ | tailwind v4.1.12, idempotent build | — |

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** none.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit + Phoenix.LiveViewTest 1.2.13 (merge-blocking); Playwright 1.59.1 (advisory) |
| Config file | `mailglass_admin/test/test_helper.exs` (`ExUnit.start(exclude: [:skip])`); `mailglass_admin/playwright.config.cjs` |
| Quick run command | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/inbound/components_test.exs --seed 0` (236 tests, 0 failures, ~3.5s today) |
| Full suite command | `cd mailglass_admin && mix verify.support_contract.admin` (= `mix test --warnings-as-errors`, `[VERIFIED: mix.exs]`) |
| Pre-merge hygiene | `mix format --check-formatted`; `mix compile --no-optional-deps --warnings-as-errors`; `mix credo --strict`; `bash scripts/check-conformance.sh`; `mix mailglass_admin.assets.build && git diff --exit-code priv/static/` |
| Browser (advisory) | `npm --prefix mailglass_admin run test:operator-browser -- phase176-filters.spec.js` (rebuilds assets first) |
| Demo (advisory, LV 1.1.33) | `npm --prefix reference/demo_app/assets run test:e2e -- --grep "Phase 176"` |
| Regression gate | `bash scripts/gsd-regression-gate.sh` (`workflow.test_command`) |

Tag new ExUnit cases `@tag :phase176` (Phase 175 precedent) so `--only phase176 --trace` can prove nonzero execution counts.

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FILTER-01 | Select change commits canonical URL; no Apply control, no `phx-disable-with`, no `type="submit"`; Clear present and no-op when nothing applied | LiveView + contract | `mix test test/mailglass_admin/operator_live_test.exs test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/phase176_prohibition_contract_test.exs --only phase176` | Wave 0 (new file + updates) |
| FILTER-01 | Tampered `filters[tenant_id]` ignored on change/submit/recover | LiveView | same | Wave 0 |
| FILTER-02 | Search input has `phx-debounce="300"`, selects have none; hook + `data-committed`; exactly one text-like input per form; `phx-auto-recover="recover_filters"` | LiveView DOM contract | same | Wave 0 |
| FILTER-02 | Debounce timing, Enter commit, focus/caret stability, Enter/Clear with pending debounce | Playwright (advisory) | `npm --prefix mailglass_admin run test:operator-browser -- phase176-filters.spec.js --grep "debounce\|Enter\|Clear"` | Wave 0 |
| FILTER-03 | `FilterCommit.history_kind/2` truth table (select/enter/clear/page push; search first push then replace; canonicalize/recover replace) | unit | `mix test test/mailglass_admin/operator/filter_commit_test.exs` | Wave 0 |
| FILTER-03 | Patch `kind` observed per commit (`view.proxy` + `assert_receive`), `:canonicalize_tenant` uses `:replace`, commit drops `page` and selection, pagination preserves filters, Back via `render_patch` | LiveView | operator/inbound live tests | Wave 0 |
| FILTER-03 | `history.length` per search edit; Back/Forward with focus in Search restores text (D-10 hook, incl. Pitfall 3 case); reconnect adds no entry | Playwright (advisory; demo for 1.1.33) | `...phase176-filters.spec.js` and demo `--grep "Phase 176"` | Wave 0 |
| FILTER-04 | Invalid draft retained with `aria-invalid`/`aria-describedby` and note; Inbound select does not contradict its error; URL-invalid labeled "…not applied" + "Showing results without the {Field} filter." | LiveView (+ axe advisory) | operator/inbound live tests | Wave 0 |
| FILTER-04 | Fault-injected `:error` (new query) vs `:stale` (same query), count hidden, no empty-state copy, Retry adds no history | LiveView with fault seams | operator: extend `arm_reader_fault!` whitelist with `"deliveries"`; inbound: `Application.put_env(:mailglass_inbound, :repo, ...)` swap with `on_exit` restore | Wave 0 (seam change) |
| FILTER-04 | Status region exists on first render, text per settled state, unchanged while drafting/reconnect | LiveView render comparison | live tests | Wave 0 |
| INUX-05 | From/Reply-To/To/Cc/Delivered-to rows, order, hidden-when-empty, missing copy, duplicates, >5 `<details>`, long/Unicode, spoof cue; "Delivered to" bound to `envelope_recipient`, "To" to header `to`; trace still masks | component + LiveView + contract | `mix test test/mailglass_admin/inbound/components_test.exs test/mailglass_admin/inbound_live_test.exs --only phase176` | Wave 0 (update lines 327-374) |
| INUX-05 | Telemetry/log metadata contains no addresses on detail/reveal | contract | `phase176_prohibition_contract_test.exs` (`:telemetry.attach` capture) | Wave 0 |
| INUX-06 | Header group, single toggle button (`aria-expanded` flips, same element), facts `<dl>`, nil renders "Unavailable", known-empty "0 bytes", MIME-backed size, empty payload copy, denied copy, `<pre tabindex="0" aria-label>`, `can_reveal?` removed | component | `mix test test/mailglass_admin/inbound/evidence_card_test.exs` | exists; update |
| INUX-06 | Denied/unauthorized HTML contains no raw sentinel bytes; reveal authorization unchanged | LiveView + contract | `inbound_live_test.exs` + prohibition contract | exists; extend |
| INUX-06 | Retained production-component stories for EvidenceCard and Inbound DetailHeader | storybook scenario + advisory axe | `mix test test/mailglass_admin/quick_view_projection_test.exs`; `node --test scripts/check_phase174_evidence.test.cjs scripts/check_phase175_evidence.test.cjs` (manifest edits must keep these green); `npm --prefix mailglass_admin run test:storybook-axe -- --grep "Phase 176"` | Wave 0 |

### Sampling Rate
- **Per task commit:** the Quick run command above (about 4 seconds), plus the single touched test file with `--only phase176`.
- **Per wave merge:** Full suite `mix verify.support_contract.admin`, `bash scripts/check-conformance.sh`, `mix credo --strict`, `mix format --check-formatted`, and the Playwright spec for the wave.
- **Phase gate:** full admin suite green, conformance clean, `git diff --exit-code priv/static/` clean after a rebuild, `TokenParityTest` green, the prohibition contract mutation-proven, advisory browser lanes executed with counts recorded.

### Wave 0 Gaps
- [ ] `test/mailglass_admin/operator/filter_commit_test.exs` — pure history-kind and canonical-path tests (FILTER-03)
- [ ] `test/mailglass_admin/phase176_prohibition_contract_test.exs` — "detectors have teeth" pattern from phase175 template (D-30)
- [ ] Add `"deliveries"` to the `arm_reader_fault!/3` whitelist in `test/support/operator_fixtures.ex:630` (only `fault:deliveries` session auth is permanent today; one-shot arming is what same-query-stale vs new-query-error needs), and to the browser mutation endpoint if Playwright needs it
- [ ] Inbound stale/error fault helper (swap `:mailglass_inbound, :repo` with `on_exit` restore; existing pattern at `inbound_live_test.exs:377,400`)
- [ ] Test helper for patch kind (`view.proxy` + `assert_receive`) shared by both live test files
- [ ] `e2e/phase176-filters.spec.js` (advisory) and a demo `Phase 176` e2e group for LV 1.1.33
- [ ] Hook spike first: confirm in a real browser that `updated()` fires for the focused search input on both clients (A3) before building on it
- [ ] Scenario manifest entries + `inbound_evidence.story.exs` (D-32); re-run `scripts/check_phase174_evidence.test.cjs` and `check_phase175_evidence.test.cjs` after editing `quick_view_scenarios.json`/`.ex`

### Coupled Test Inventory (must be updated, not just D-31's list)
Planner sweep (checker iteration 2, at cf98cc0b): `grep -rn` over `mailglass_admin/test`, `mailglass_admin/e2e`, `reference/demo_app/assets/e2e`, `reference/demo_app/test` and `reference/persona_spec` for every testid and copy string the phase removes or rewords (evidence-card testids and copy, "Verification facts", `inbound-evidence-verification`, the old no-evidence sentence, "(empty)", `can_reveal`, the Apply control and hidden tenant input, masked From forms and "Unavailable" From copy, the Deliveries/Inbound error and stale copy, the old event error). Every hit is listed below with its owning plan. Hits that need no change: `components_test.exs:1272-1448` (pass their own error strings), the status-region "Raw source revealed." assertions (text unchanged), `phase168-plan03-acceptance.spec.js:119` (gallery `data_state` specimen default copy, not the Deliveries stale panel), and the `fb-auto-apply-filters` disposition prose in `quick_view_scenarios.json` (a feedback-ledger note, not an assertion).
| File | Why |
|------|-----|
| `test/mailglass_admin/operator_live_test.exs:184,318,363,380` (and `:200-209` canonical URL shape) | assert Apply, `apply_filters`/`validate_filters` payloads, `w-40` class |
| `test/mailglass_admin/inbound_live_test.exs:786` (+ the `apply_filters` hook test ~:775-795) | invalid-submit does not patch; now invalid change does not patch |
| `test/mailglass_admin/inbound/components_test.exs:327-374` | assert masked From (`b**@s*****.test`) |
| `test/mailglass_admin/inbound/components_test.exs:376-418` | assert the From cell reads "Unavailable" for an empty and a malformed `from`; becomes "No From header" / "Unparseable address" (owner: plan 176-02 Task 1) |
| `test/mailglass_admin/inbound/components_test.exs:642-670` (describe "EvidenceCard.evidence_card/1") | asserts testid `inbound-evidence-redacted` (:657), "Raw source locked" (:659) and "Raw source is hidden by default" (:664) — owner plan 176-03 Task 1; asserts "Verification facts" (:663) — owner plan 176-05 Task 1, which removes that heading |
| `test/mailglass_admin/inbound_live_test.exs:1288-1297` | selects `[data-testid='inbound-evidence-verification']` to prove verification keys/values are withheld; plan 176-05 keeps that testid on the Provider authentication cell when it merges the two facts lists |
| `test/mailglass_admin/inbound/evidence_card_test.exs`, `inbound_live_test.exs` (~1259-1285, 2211-2227, 2359) | assert `Raw source is hidden by default…`, `inbound-evidence-redacted`, `You do not have permission to reveal…`, `inbound-evidence-re-redact`, "Raw source revealed" |
| `e2e/inbound-layout.spec.js:173,181,184`; `phase175-inbound.spec.js:137`; `phase169-journey.spec.js:569-571` (also asserts the URL does **not** change after a select, `not.toHaveURL(/event=failed/)`) | click "Apply filters" |
| `e2e/structural.spec.js:2283,2330` assert the old copy "Status was not applied. Choose a listed status."; `:~2344-2362` uses `requestSubmit()` | UI-SPEC rewords the event error to name "Latest recorded event"; submit test must keep focus semantics. The two copy assertions read gallery specimens hard-coded at `lib/mailglass_admin/gallery_live.ex:869,978` (not `@event_filter_error`), so the spec and the gallery literals change together (owner: plan 176-10 Task 3) |
| `e2e/phase168-plan03-acceptance.spec.js:171` | depends on Open Question 2 |
| `e2e/phase170-journey.spec.js`, `flows.spec.js`, `operator.spec.js` | assert evidence-card strings/testids (grep list in Sources) |
| `lib/mailglass_admin/gallery_live.ex:597,1279-1311` | masked fixtures (D-32) |
| `test/mailglass_admin/inbound_live_test.exs:384`, `:2009-2010`; `e2e/phase170-journey.spec.js:284` | Inbound read-unavailable and stale copy (owner: plan 176-09) |
| `test/mailglass_admin/operator_live_test.exs:297,327,2385,4055-4058,4101-4104` | Deliveries event-error, error and stale copy (owner: plan 176-04) |
| `test/mailglass_admin/bucket_a_coverage_test.exs` | fail-closed on renamed cited e2e titles; grep found no citation of the titles above, re-grep before renaming any e2e test |

## Security Domain

`security_enforcement` is not disabled in `.planning/config.json`; section included.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no (unchanged) | existing `MailglassAdmin.Auth` mount hook |
| V3 Session Management | no (unchanged) | existing LV session |
| V4 Access Control | **yes** | Account from server-held `selected_tenant_id` (D-09); `handle_params` stays the URL authorization gate; reveal authorized at action time via `Auth.authorize(adapter, :reveal_raw, ...)` (unchanged); tenant-scoped read models |
| V5 Input Validation | **yes** | allow-list enum casting (`cast_enum`/`normalize_enum_filter`), positive-integer parsing for `window_hours`/`page`; HEEx auto-escaping for all rendered addresses and display names (no `raw/1`) |
| V6 Cryptography | no | none |
| V7 Error Handling and Logging | **yes** | telemetry metadata whitelist (`tenant_id`/`record_id`/`outcome`); do not log filter values or addresses |
| V8 Data Protection | **yes** | raw payload bytes absent from default and denied HTML; From unmasking is limited to ordinary authorized detail, trace/subject masking retained |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Tampered hidden `tenant_id` in a change/submit/recover payload switching Accounts | Tampering / Elevation | ignore payload `tenant_id`; use `assigns.selected_tenant_id`; contract test with a foreign tenant id |
| Forged `delivery_id`/`inbound_id`/`full` carried across a commit | Information disclosure | commits drop selection params; detail reads remain tenant-scoped by the gateway |
| Raw payload bytes leaking in denied/unauthorized HTML | Information disclosure | sentinel-byte test on denied + redacted renders (exists for default; extend to denied and the new single-button markup) |
| Display-name spoofing (`"billing@paypal.example" <sender@mailer.example>`) | Spoofing | show real addr-spec always; spoof cue text; IDN/homograph (UTS #39) deferred |
| XSS through address/display name | Tampering | HEEx escaping only; add a component test with `<script>` in a display name |
| PII in telemetry/logs from the new address display | Information disclosure | no new telemetry; contract asserts reveal/detail metadata keys are exactly `tenant_id`/`record_id`/`outcome` |
| Long search/URL values | DoS | search round-trips through the URL unchanged (UI-SPEC row); no server-side size limit exists today, so verify the read-model query bounds it, and do not add one silently |

## Sources

### Primary (HIGH confidence)
- `mailglass_admin/deps/phoenix_live_view/assets/js/phoenix_live_view/dom.ts:324-430` and `live_socket.ts:1895-1990` (LV 1.2.13) - debounce, blur flush, submit cycle cancellation, ignored `change` after `input`
- `.../dom_patch.ts:170-260,474-495` and `dom.ts:637-646` (LV 1.2.13) - focused-input handling: attrs merged except `value`, `updates.push` triggers hook `updated()`, `phx-patch-focused` opt-in
- `.../view.ts:805-900,2607-2660` (LV 1.2.13) - form recovery with `phx-auto-recover` custom event; recovers only forms whose `phx-change` value is unchanged
- `reference/demo_app/deps/phoenix_live_view` 1.1.33 `priv/static/phoenix_live_view.js` - `auto-recover`, `bind-debounce`, `mergeFocusedInput` present; `patch-focused` absent
- `mailglass_admin/lib/mailglass_admin/operator_live.ex`, `inbound_live.ex`, `operator/deliveries_list.ex`, `inbound/records_list.ex`, `inbound/detail_header.ex`, `inbound/evidence_card.ex`, `operator/filters_form.ex`, `inbound/filters_form.ex`, `components.ex` (read this session; line refs inline)
- `mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_record.ex`, `inbound_evidence.ex`, `internal/operator/detail.ex` - field shapes and the full-record detail read
- `mailglass_admin/priv/static/hooks.js`, `lib/mailglass_admin/controllers/assets.ex:64-69`, `lib/mix/tasks/mailglass_admin.assets.build.ex`
- `mailglass_admin/scripts/check-conformance.sh`, `.github/workflows/ci.yml` (`ci_green.needs`, browser gate at :955), `mailglass_admin/mix.exs` aliases
- `mailglass_admin/test/support/endpoint_case.ex`, `test/support/operator_fixtures.ex:628-647` - fault seams
- Probe runs this session: patch `kind` observable via `view.proxy`; assets build idempotent; 236-test quick run green; Playwright lane runs locally
- [WHATWG HTML Living Standard, "Implicit submission"](https://html.spec.whatwg.org/multipage/form-control-infrastructure.html#implicit-submission) - no-submit-button forms submit on Enter unless more than one field "blocks implicit submission" (Text, Search, Telephone, URL, Email, Password, Date, Month, Week, Time, Local Date and Time, Number)

### Secondary (MEDIUM confidence)
- `.planning/research/ui-quality-engine/UPSTREAM-SCOPE.md` (§63-76) and `REQUIREMENTS.md` FILTER/INUX rows
- Phase 175 `175-VALIDATION.md` (proven commands) and `phase175_prohibition_contract_test.exs` (contract template)

### Tertiary (LOW confidence)
- WebSearch for the LV version that introduced `phx-patch-focused`: no changelog hit (A1)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - no additions; versions read from lockfiles/package.json
- Architecture: HIGH - all handlers and read paths read in source; patch-kind and build behavior probed
- Pitfalls: HIGH for server/LV mechanics (source-verified); MEDIUM for browser-timing items (A2, A3) that only a real browser settles

**Research date:** 2026-10-28
**Valid until:** 2026-11-27 (stable stack; re-verify LV pins if `mix.lock` changes)
