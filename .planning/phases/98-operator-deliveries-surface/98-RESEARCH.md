# Phase 98: Operator / Deliveries Surface - Research

**Researched:** 2026-06-14
**Domain:** Phoenix LiveView + HEEx UI composition (daisyUI 5 / Tailwind v4 standalone, zero Node); operator-surface IA, responsive master-detail, a11y, deterministic seed harness
**Confidence:** HIGH (all findings are direct codebase reads with file:line; no external dependency research required)

## Summary

Phase 98 is an implementation phase, not a design phase. Every visual/interaction axis is locked by a v1.11 LD-ID or a CONTEXT D-0x. The job of the planner is to make the plans **executable and accurate against the current code**, which has drifted from the line numbers cited in `98-CONTEXT.md` / `98-UI-SPEC.md` because Phase 97 landed between context-gathering and now. This research re-grounds every integration point to its CURRENT location and flags the citations that no longer match.

The single most important finding the planner must internalize: **the conformance posture for `tracking-[…]` and `text-lg/xl` is ADVISORY, not hard-fail.** `98-CONTEXT.md` D-03 and `98-UI-SPEC.md` both assert "the tightened conformance grep gate (RATCHET-03) already fails on arbitrary `tracking-[…]`." That is FALSE against the current tree. `scripts/check-conformance.sh` (the hard-fail gate wired into `ci.yml:407`) has five gates — BADGE / TYPE(text-sm/xs/base) / BOLD / GAP / HEX — and **no `tracking-[…]` gate and no `text-lg/xl` gate**. Those two live in `scripts/check-conformance-advisory.sh`, which **always `exit 0`** and is wired `continue-on-error: true` (`ci.yml:411`). Its own header explicitly says "Phase 99 task: flip this script's exit-code contract to hard-fail." So removing `tracking-[0.08em]` from operator markup is correct per the LD-locks (IA-LD-04 / STATE-LD-13), but the planner must NOT assume CI currently enforces it, and must decide whether Phase 98 also flips the advisory gate to hard-fail for the operator surface or leaves that to Phase 99 (the advisory script's stated owner). Recommendation below.

The second-most important finding: the **anti-churn citation contract** (`RATCHET-GAP-REGISTER.md`) requires every build task in Phases 98–103 to cite a register row at **severity ≥ 3**, and there is currently exactly **one** operator-surface (`deliveries`) sev≥3 row: **GAP-01** (support_cards drilldown CTAs use `btn-sm` → sub-44px touch target). The other open rows are `preview` (GAP-02/03) or `inbound` (GAP-04, and GAP-04 is sev 2 anyway). The planner must either (a) map most operator tasks to GAP-01 where genuinely applicable, or (b) seed new GAP-NN rows for the gaps this phase fixes (wrong master-detail grid, operator_live `tracking-[0.08em]`, unseeded states) so each build task has a legitimate sev≥3 citation. Recommendation: seed new rows.

**Primary recommendation:** Plan against the verified locations in this document, not the CONTEXT line numbers. Treat D-03's "RATCHET-03 already fails on tracking" as incorrect — plan the markup fix from the LD-lock, and add a dedicated plan/task to either flip the advisory TRACK/TYPE gate to hard-fail (scoped to operator) or add new sev≥3 GAP rows so the anti-churn contract is satisfiable. Reach new states through the single seed via URL params (D-04) and assert them with Playwright `getByTestId` + ExUnit structural assertions, never new LLM-baseline cells (the 36-cell baseline is frozen).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Master-detail grid responsiveness (390/768/1440) | Frontend (HEEx render + Tailwind responsive classes) | — | Pure layout; CSS grid templates in `operator_live.ex` render block (IA-LD-03) |
| 390px filter disclosure toggle | Frontend (CSS `hidden md:block` + `Phoenix.LiveView.JS.toggle`) | — | Stateless, URL-param-free, no socket assign, no client JS hook (D-06, IA-LD-02) |
| In-place detail reveal-with-back at 390px | Frontend (`:if selected_delivery` + responsive classes) | LiveView (selection already in URL via `select_delivery` → `push_patch`) | IA-LD-03: NOT a new route; the existing `delivery_id` param already drives selection — only the layout treatment changes |
| State coverage (empty / filtered-empty / detail-error / suppressed) | Test harness (seed) + Frontend (render branches) | API/read-model (`Deliveries`, `detail_error_for/2`) | Branches already exist in `operator_live.ex`; the gap is seed data + URL reachability (D-04, FLOW-01) |
| CR nil-guards (CR-01/02/03) | Backend/component logic (Elixir defp clauses + attr list) | — | Defensive code, no UI change (D-05) |
| Token/spacing conformance (drop `tracking-[…]`, gap rhythm) | Frontend (HEEx class strings) | CI gate (grep conformance) | Markup-only; gate is grep-based (D-03, D-07) |
| Structural test hooks (`data-testid`) | Frontend (HEEx attrs) + Playwright (`getByTestId`) | — | D-08; queried by `e2e/structural.spec.js` |

## Standard Stack

No new packages. This phase touches only already-present deps. Verified from `mailglass_admin/mix.exs`:

| Library | Version (mix.exs) | Purpose | Why Standard |
|---------|-------------------|---------|--------------|
| `phoenix_live_view` | `~> 1.1` | LiveView + HEEx render, `Phoenix.LiveView.JS` | `JS.toggle` / `JS.focus` / `JS.focus_first` are the locked CSS+LiveView.JS-only motion/disclosure mechanism (D-06) |
| `phoenix` | `~> 1.8` | Component framework | — |
| `tailwind` | `~> 0.4` (`:dev`/`:test`, `runtime: false`) | Standalone-binary Tailwind v4 — **zero Node** | Bundle built by `mix mailglass_admin.assets.build`; gate `git diff --exit-code priv/static/` |
| daisyUI 5 | vendored (no Hex dep) | Component classes (`badge-*`, `btn-*`, `card`, `rounded-box`) | Theme via `data-theme="mailglass-light"/"mailglass-dark"` |
| heroicons | vendored inline (`heroicons-inline.js` `@plugin`, no heroicons dep) | `hero-*` icons | Adding a new `hero-*` needs SVG embedded + bundle rebuild (MEMORY: heroicons-inline plugin) |
| `@playwright/test` | (npm, e2e/ only, not a Hex dep) | Structural e2e assertions | `getByTestId` structural layer — the Nyquist DOM gate |

**Installation:** None. `[ASSUMED: no new deps]` — verified by reading `mix.exs` deps/0; this is a composition phase.

## Package Legitimacy Audit

Not applicable — **this phase installs no external packages**. No registry interaction. (Tailwind standalone binary and vendored daisyUI/heroicons are pre-existing and Node-free per the zero-Node hard rule.)

## CONTEXT.md Citation Verification (the highest-value output)

Phase 97 drift moved most cited lines. **Every integration point re-grounded below.** ✅ = matches; ⚠️ = drifted (use the verified location); ❌ = claim is factually wrong.

| CONTEXT/UI-SPEC citation | Status | CURRENT accurate location + surrounding idiom |
|--------------------------|--------|-----------------------------------------------|
| `operator_live.ex:280-363` `:overview` view (orientation_strip + Health + Navigate) | ✅ mostly | `operator_live.ex:280-363` — `<%= if @view == :overview do %>` block. `data-testid="operator-overview"` at **:281**, health grid at **:285** (`operator-overview-health`), nav at **:329** (`operator-overview-nav`). Health uses `lg:grid-cols-4` at **:287**. |
| `operator_live.ex:396` master-detail grid `lg:grid-cols-[minmax(22rem,28rem)_1fr]` | ⚠️ **:397** | `operator_live.ex:397`: `class="mt-6 grid gap-lg lg:grid-cols-[minmax(22rem,28rem)_1fr]"`. This is the grid D-02 must REPLACE with the IA-LD-03 percentage templates. `data-testid="operator-master-detail"` at **:396**. |
| `operator_live.ex:~409` deliveries-list card `h2` with banned `tracking-[0.08em]` | ⚠️ **:404** | `operator_live.ex:404`: `<h2 class="text-body font-bold uppercase tracking-[0.08em] text-secondary">Recent deliveries</h2>` inside the `operator-deliveries-list-card` aside. D-03 target. Note class is `text-body` (not `text-heading`) — D-03 says apply `text-label uppercase font-bold text-secondary` per IA-LD-04. |
| `operator_live.ex:153, :241` bare `socket.assigns.selected_delivery.id` (CR-02) | ✅ both | `:153` — `delivery_id = blank_to_nil(params["delivery_id"]) \|\| socket.assigns.selected_delivery.id` (in `handle_event("open_support_exemplar", …)`). `:240-241` — `socket.assigns.selected_delivery.id` in the `{:error, reason}` branch of `confirm_replay`. Both are genuine nil-deref risks. **CR-02 idiom note:** these are in handlers, not render; the surrounding code uses `blank_to_nil/1` and guarded `with`/`case`. A guarded private helper or `get_in(socket.assigns, [Access.key(:selected_delivery), Access.key(:id)])` is the minimal fix (D-05). |
| `operator_live.ex:550-552` `detail_error_for/2` returns `:not_found` | ✅ exact | `:550` `detail_error_for(nil, _)` → nil; **:551** `detail_error_for(_delivery_id, nil)` → `:not_found`; `:552` → nil. Confirms D-04's claim: a non-existent `?delivery_id=` yields `:not_found` (selected_delivery is nil but delivery_id is present). |
| `operator_live.ex:33` `@status_values` includes `:suppressed` | ✅ exact | `:33` `@status_values [:queued, :sent, :dispatched, :failed, :suppressed]`. Confirms `:suppressed` is filterable and CR-03 phantom-atom handling is real. |
| `suppression_card.ex:55-57` `body_copy/1` no fallback (CR-01) | ⚠️ **:55-57 confirmed, but no `:not_found` exposure** | `suppression_card.ex:55` `body_copy(%{reversibility: :immutable})`, `:56` `body_copy(%{reversibility: :reversible})`, `:57` `body_copy(%{reversibility_copy: copy})`. **No catch-all** → `FunctionClauseError` if `suppression_state` is a map lacking all three keys. CR-01: add `defp body_copy(_), do: <COPY-LD-14 fallback>` mirroring `headline/1` (which ALSO lacks a non-nil catch-all — see note below). |
| `components.ex:158-183` `status_badge` `attr :status, values:` list (CR-03) | ✅ exact | `:158-183` is the `attr :status, :atom, values: […]` list. `:suppressed` is **absent** from it (the 22 listed atoms end at `:reconciled` on `:181`). Fallback clauses `status_class/icon/label(_status)` at **:230 / :255 / :280** already render any phantom atom as `badge-outline` / `hero-question-mark-circle` / "Unknown" per STATE-LD-05. CR-03 = add `:suppressed` to the `values:` list only. |
| `shell.ex:181` gap-token rhythm | ⚠️ **:181 is `mb-lg flex flex-col gap-xs`** | `shell.ex:181`: `<div class="mb-lg flex flex-col gap-xs">` (title/subtitle stack). `orientation_strip` is at **:314-333** (`copy_for/1` at :335-366). nav aria-current at **:205** (nav_link) / **:229** (nav_pill) — CONTEXT said ~206/229; nav_link is :205. Page `h1` at **:182** (`text-heading font-bold tracking-tight`). |
| `operator_browser_server.ex:30` single seed | ✅ exact | `:30` `OperatorFixtures.seed_browser_scenario!()`. **⚠️ URL note:** server boot URL at **:33** is `/dev/mail/operator?tenant_id=…` (dev mount), but the e2e specs drive the surface via `/ops/mail` (the `:ops` auth mount). Both routes mount `OperatorLive` (`router.ex:91` dev, `router.ex:263` ops). The Playwright specs use `/ops/mail` exclusively. |
| `endpoint_case.ex:87` seed reference | ✅ exact | `endpoint_case.ex:87` `OperatorFixtures.seed_browser_scenario!()`; tenant default `"browser-tenant"` at `:92`; `return_to` default `/ops/mail?tenant_id=…` at `:93`. |
| `operator_fixtures.ex:131-133` row ordering / `@tenant_id` | ⚠️ **ordering comment at :132-135** | `@tenant_id "browser-tenant"` at **:10**. The D-07 row-index stability is governed by `last_event_at` / `received_at` ordering: rows are `hours_ago(1)` selected, `hours_ago(2)` exact/ambiguous/noop, `hours_ago(6)` failed-sendgrid, inbound `hours_ago(10)`. The comment at **:132-135** explains inbound must stay oldest. `deliveryRow(page, index)` in `operator.spec.js:9` indexes the rendered list (newest first): index 0 = selected, 1 = noop, 2 = ambiguous, 3 = exact (confirmed by `operator.spec.js:108/140/168` clicking nth(3)/nth(2)/nth(1)). **Any new seed row MUST be timed so it does not insert between existing rows** or these indices break. |
| `components.ex:196-280` `status_badge` render + clauses (UI-SPEC) | ✅ | `status_badge/1` at **:196**; `status_class/1` :207-230; `status_icon/1` :232-255; `status_label/1` :257-280; all three have `_status` fallback. |
| UI-SPEC: `text-heading` = "24px (was banned text-xl)" | ❌ **20px** | `app.css` `@theme`: `--text-heading: 20px` (line 123), `--text-display: 28px` (line 125). The UI-SPEC px annotation is wrong, but **non-load-bearing**: planners and code use the token NAME (`text-heading`), not the px. `detail_header.ex:21` already uses `text-heading` (Phase 97 fixed the old `text-xl`). The deliveries-list `h2` at `operator_live.ex:404` uses `text-body` — D-03 changes it to the IA-LD-04 label token, not `text-heading`. |
| `mix.exs:183-188` `verify.preview` bundle-clean gate | ✅ exact | `mix.exs:183-188` alias `verify.preview`: `compile --no-optional-deps --warnings-as-errors` → `test --warnings-as-errors --exclude flaky` → **`mailglass_admin.assets.build`** → `cmd git diff --exit-code priv/static/`. Confirms D-08: rebuild + commit `priv/static/app.css` or CI reds. |

## Conformance / Structural Gate Inventory (exact commands)

| Gate | File | Wired in | Current posture | What it checks (operator-relevant) |
|------|------|----------|-----------------|-------------------------------------|
| Design-system hard-fail | `mailglass_admin/scripts/check-conformance.sh` | `ci.yml:407` (hard) | **Hard-fail** | BADGE-GATE (`defp badge_class`), **TYPE-GATE (`text-sm`/`text-xs`/`text-base`)**, BOLD-GATE (`font-medium`/`font-semibold`), GAP-GATE (`gap-3`/`gap-4`/`gap-6`), HEX-GATE (`color…#hex`). **No `tracking-[…]` gate. No `text-lg/xl` gate.** |
| Design-system advisory | `mailglass_admin/scripts/check-conformance-advisory.sh` | `ci.yml:411` (`continue-on-error: true`) | **Always `exit 0`** | TYPE-GATE advisory (`text-lg/xl/2xl/3xl/4xl/5xl`), **TRACK-GATE (`tracking-\[`)**. Header says "Phase 99 task: flip … to hard-fail." Lists "~43 tracking-[0.08em] sites" as known. |
| Motion conformance | `mailglass_admin/scripts/check_motion_conformance.sh` | `ci.yml:402` | Hard | Motion vocabulary gate (not detailed here; operator uses only named motions per MOTION-LD-*) |
| Structural Playwright | `mailglass_admin/e2e/structural.spec.js` | Playwright e2e lane | Hard (test failures red) | 6 D-01 pillar facts via `getByTestId` + computed-style; operator block at lines 79-91 (ARIA), 114-150 (touch targets), 201-213 (font-weight), 247-253 (reduced-motion), 277-286 (focus rings), 348-372 (accent allowlist) |
| Operator behavioural e2e | `mailglass_admin/e2e/operator.spec.js` | Playwright e2e lane | Hard | master-detail two-pane, selection flow, replay flows, MOTION-01/02 regression, overview landing (lines 267-283), orientation strips |
| LLM-score baseline (36-cell) | `mailglass_admin/docs/ui-baseline-scores.json` + `test/mailglass_admin/ratchet_baseline_test.exs` | `verify.support_contract.admin` (`mix.exs:189-191`) | Shape/range now; meet-or-beat in Phase 103 | **FROZEN: 3 surfaces × 6 pillars × 2 themes = 36 cells.** `deliveries` is one surface. **Do NOT add new baseline keys.** |

**Tracking-`[…]` reality across the operator surface (verified by grep):** 11 sites remain —
`support_cards.ex:67,73,113,119` (4), `suppression_card.ex:24,28,32,36` (4), `replay_modal.ex:136,140` (2), `operator_live.ex:404` (1).
**Scope tension the planner must resolve:** D-03 says "Audit the WHOLE operator template … fix to token." But `support_cards.ex`, `suppression_card.ex`, and `replay_modal.ex` are **shared/uplifted components Phase 97 owned** (97-CONTEXT settled filters_form tracking removal — but not these). The deliveries-view `operator_live.ex:404` is unambiguously Phase 98. **Recommendation:** Phase 98 removes `tracking-[0.08em]` from `operator_live.ex:404` (clearly in scope) AND from `suppression_card.ex` + `support_cards.ex` + `replay_modal.ex` (these render INSIDE the operator detail pane and were not fixed in 97, so they are operator-surface markup; leaving them means the "operator surface is token-clean" claim is false and the advisory gate stays dirty). Confirm with planner whether `replay_modal`/`support_cards` belong to 98 or are deferred to Phase 99's gate-flip; if deferred, the operator advisory gate cannot be flipped to hard-fail in 98.

## Architecture Patterns

### Master-detail responsive grid (D-02 / IA-LD-03) — the central refactor

Replace `operator_live.ex:397`:
```heex
class="mt-6 grid gap-lg lg:grid-cols-[minmax(22rem,28rem)_1fr]"
```
with the IA-LD-03 percentage templates keyed to the 768/1440 tiers:
- **390px (default, no prefix):** single column — master list 100% width.
- **768px (`md:`):** `md:grid-cols-[40%_60%]`.
- **1440px — there is NO native 1440 Tailwind breakpoint.** Tailwind v4 defaults: `md`=768, `lg`=1024, `xl`=1280, `2xl`=1536. IA-LD-03 specifies the *33/67* split "at 1440." `[ASSUMED]` the intended breakpoint utility is `xl:` (1280px, the closest tier ≥ the 1024 `lg`) or a custom `[1440px]` arbitrary variant. **Open question A1** — the planner/UI-checker must pick `xl:grid-cols-[33%_67%]` vs `2xl:` vs an arbitrary `min-[1440px]:`. The UI-SPEC table says breakpoints are "the 768/1440 tiers, NOT `lg:`" — so `lg:` is explicitly banned; `xl:` or `2xl:` or arbitrary is the live choice.

**390px reveal-with-back (Claude's Discretion per D-01/IA-LD-03):** selection state is ALREADY in the URL (`select_delivery` → `push_patch` with `delivery_id`, `operator_live.ex:133-144`). At 390px, when `@selected_delivery != nil`, the detail column should occupy 100% and the master list should hide; a "Back" affordance clears `delivery_id` (a `<.link patch={build_path(@base_path, @filter_params, nil, @dark_chrome)}>` — re-using `build_path/4` at `:700` with `delivery_id=nil`). This is `:if`-toggled + responsive classes only — **NOT a new route** (the lock). The existing `mobile stacks list before detail` e2e test (`operator.spec.js:73-102`) asserts `deliveriesBox.y < detailBox.y` at 390px when **no row is selected** — the back-reveal layout must not break that (it only changes layout when a row IS selected).

### Filter disclosure at 390px (D-06 / IA-LD-02) — `JS.toggle`

`Phoenix.LiveView.JS.toggle` is **not yet used anywhere** (`grep JS.toggle lib/` → none). Existing JS usage is `JS.focus` / `JS.focus_first` (`operator_live.ex:467-468`). Pattern to add: wrap the filter `<section>` (currently `operator_live.ex:369-393`) so its inner controls carry `hidden md:block` and a visible "Filters" `<button phx-click={JS.toggle(to: "#operator-filter-panel")}>` appears only `md:hidden`. No socket assign, no client hook, URL-param-free (the lock). At ≥768px filters are always visible (`md:block` keeps them shown; the toggle button is `md:hidden`).

### Seed extension (D-04 / FLOW-01) — single dataset, URL-reachable

Extend `seed_browser_scenario!/0` (`operator_fixtures.ex:12-153`). Helpers available: `insert_delivery!/1` (defaults at :170-181), `insert_suppression!/1` (:268), `insert_event!/2`. New states and how each is REACHED (no new seed entry point):

| State (D-04 / UI-SPEC matrix) | Seed change | URL to reach | Existing render branch |
|-------------------------------|-------------|--------------|------------------------|
| Truly-empty (no deliveries) | none — reached by a tenant with no rows OR a window that excludes all | `?tenant_id=<empty-tenant>` or impossible `?window_hours=` | `deliveries_list.ex:15` `@deliveries == []` empty branch |
| Filtered-empty (tenant present, no match) | none — existing rows + non-matching filter | `?tenant_id=browser-tenant&status=bounced` (no bounced rows) or `&provider=zzz` | same empty branch (COPY-LD-01 vs COPY-LD-02 distinction must be wired — see gap) |
| No tenant | none | `/ops/mail` with no `tenant_id` | `load_deliveries(%{"tenant_id" => ""})` → `[]` (`:504`); overview shows "Select a tenant" (`:361`) |
| Detail error (`:not_found`) | none | `?tenant_id=browser-tenant&view=deliveries&delivery_id=<nonexistent>` | `operator-detail-error` cell (`:416-427`); `detail_error_for/2` returns `:not_found` |
| Active suppression present | ALREADY seeded (`:38-44` inserts suppression for `browser-selected`) | select `browser-selected` row (index 0) | `suppression_card.ex` present branch |
| `:suppressed` / novel-shape row | ADD one `insert_delivery!(%{status: :suppressed, …})` timed `hours_ago(>6)` so it sorts AFTER existing rows | filter `?status=suppressed` or scroll to it | `status_badge` fallback → `badge-outline` (CR-03 must add `:suppressed` to attr list or the badge attr validation warns) |

**Row-index stability rule (D-07, critical):** existing `deliveryRow` indices are 0=selected(h-1), 1=noop(h-2), 2=ambiguous(h-2), 3=exact(h-2), then failed-sendgrid(h-6). A new `:suppressed` row MUST be timed `hours_ago(7)` or later so it appends at the END (index ≥ 5) and does not shift indices the existing 5 operator.spec.js tests depend on. Verify by re-running `operator.spec.js` after seed change.

**COPY-LD-01 vs COPY-LD-02 gap:** the current `deliveries_list.ex:15-24` empty branch renders ONE generic copy ("No recent deliveries match these filters. Clear the filters or wait for the next send."). The UI-SPEC requires TWO distinct empty states: filtered-empty (COPY-LD-01, with reset action) vs truly-empty (COPY-LD-02, no reset). The component currently cannot distinguish them — it has no signal for "filters are non-default." **The planner must add a `filters_active?`/`empty_kind` signal** (passed from `operator_live.ex` where `@filter_params` is known) so the two copies + the conditional reset action can branch. This is a real implementation unknown, not just copy.

### Anti-patterns to avoid
- **Do NOT `push_patch` to a new route for the 390px reveal** (IA-LD-03 explicit). Selection already lives in `delivery_id`.
- **Do NOT add a socket assign for the filter toggle** (D-06 — `JS.toggle` is stateless).
- **Do NOT add a non-fallback `:suppressed` clause** to `status_class/icon/label` (CR-03 / STATE-LD-05 — the fallback is intentional; only the attr `values:` list changes).
- **Do NOT add new keys to `ui-baseline-scores.json`** (frozen 36-cell). New assertions go to `structural.spec.js` / ExUnit only.
- **Do NOT use `lg:` for the master-detail breakpoints** (IA-LD-03 bans it; use `md:`/`xl:`/arbitrary).
- **Do NOT introduce arbitrary `gap-[…]`, `px-[…]`** — hard-fail GAP-GATE catches `gap-3/4/6`; token rhythm only (D-07).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Filter show/hide at 390px | Custom JS hook or socket assign + handle_event | `Phoenix.LiveView.JS.toggle` | D-06 lock; stateless; matches existing `JS.focus` idiom |
| Status → color mapping | New `defp badge_class` in operator | `Components.status_badge/1` | BADGE-GATE hard-fails on `defp badge_class`; single source of truth |
| Recipient masking in seed/display | Inline string munging | `Components.mask_recipient/1` (`components.ex:295`) | The ONE audited masking definition; PII-min lock |
| Detail-pane entrance motion | New keyframes | `.motion-reveal` (MOTION-LD-02), already on `operator_live.ex:443` | Named motion vocabulary; motion gate |
| Reaching a new UI state in e2e | New seed script / second dataset | URL params on the single seed | D-04 lock; preserves row-index stability + single-seed harness |
| URL path building | Manual string concat | `build_path/4` (`operator_live.ex:700`) / `build_path_with_view/3` | Already handles theme, support_state, blank-stripping |

**Key insight:** Almost everything this phase needs already exists in the code — the work is *composition and conformance*, not net-new mechanism. The two genuine new mechanisms are `JS.toggle` (filter disclosure) and the `empty_kind`/`filters_active?` signal for the COPY-LD-01/02 split.

## Runtime State Inventory

This is a UI-composition + test-seed phase, not a rename/migration. No production runtime state is mutated.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — seed work writes only to the **test** DB (`MailglassAdmin.TestRepo`, truncated each run via `reset!/0` at `operator_fixtures.ex:155-161`). No prod data. | None |
| Live service config | None | None — verified: no external service touched |
| OS-registered state | None | None |
| Secrets/env vars | None | None — verified: no new env reads added |
| Build artifacts | `mailglass_admin/priv/static/app.css` MUST be rebuilt (`mix mailglass_admin.assets.build`) and **committed** if any class strings change — `verify.preview` (`mix.exs:187`) runs `git diff --exit-code priv/static/` and reds CI on drift | Rebuild + commit `priv/static/` whenever HEEx classes change |

## Common Pitfalls

### Pitfall 1: Assuming the tracking/text-lg conformance gate is already hard-fail
**What goes wrong:** Planner trusts D-03/UI-SPEC ("RATCHET-03 already fails on `tracking-[…]`") and writes no task to enforce it; the markup fix lands but nothing prevents regression, OR the planner thinks CI already reds on the existing 11 sites (it doesn't).
**Why it happens:** The CONTEXT/UI-SPEC text is factually wrong about current CI posture.
**How to avoid:** Treat the TRACK/TYPE-lg gates as ADVISORY (`check-conformance-advisory.sh`, `exit 0`, `continue-on-error: true`). If Phase 98 wants enforcement, add a task to flip the advisory gate to hard-fail (the script header documents the exact steps: remove `exit 0`, add the fail counter, remove `continue-on-error` from `ci.yml`) — but only AFTER all operator-surface sites are clean, and confirm whether `replay_modal`/`support_cards` cleanup is 98 or 99.
**Warning signs:** A plan task says "verified by RATCHET-03 grep gate" for tracking without a task that actually makes that gate hard-fail.

### Pitfall 2: New seed row shifts `deliveryRow` indices
**What goes wrong:** Adding the `:suppressed` row with a recent timestamp inserts it mid-list; `operator.spec.js` clicks the wrong row (e.g. nth(3) is no longer `browser-exact`), all 5 replay/selection tests go red.
**Why it happens:** The list renders newest-first by `last_event_at`; index positions are timestamp-derived, not stable IDs.
**How to avoid:** Time any new row `hours_ago(7)`+ so it appends last (after the `hours_ago(6)` failed-sendgrid row). Re-run `operator.spec.js` to confirm indices 0-3 unchanged (D-07).
**Warning signs:** `operator.spec.js` replay tests failing with "expected browser-exact, got browser-…".

### Pitfall 3: Heroicon added but invisible
**What goes wrong:** A back-affordance or filter-toggle chevron uses `<.icon name="hero-X">` for an icon whose SVG isn't in `heroicons-inline.js`; it renders blank and no compile/test catches it.
**Why it happens:** Icons are a hand-maintained inline plugin, not a dep (MEMORY: heroicons-inline plugin).
**How to avoid:** Reuse icons already embedded (`hero-paper-airplane`, `hero-inbox-arrow-down`, `hero-lifebuoy`, `hero-arrow-path`, `hero-exclamation-circle`, `hero-chevron-*` only if already present). If a new icon is needed, embed its SVG + rebuild bundle.
**Warning signs:** Invisible icon in the preview; bundle diff missing the new SVG.

### Pitfall 4: COPY-LD-01/02 collapsed into one empty state
**What goes wrong:** The seed reaches "filtered-empty" and "truly-empty" but the component can't tell them apart, so both render generic copy and the reset action either always or never shows.
**Why it happens:** `deliveries_list.ex` empty branch has no `filters_active?` input.
**How to avoid:** Thread a signal from `operator_live.ex` (it has `@filter_params` and `default_filter_params/0` to compare against) into `DeliveriesList` so the branch can choose copy + conditionally render reset.
**Warning signs:** Only one of COPY-LD-01 / COPY-LD-02 strings present in rendered HTML.

### Pitfall 5: `headline/1` in suppression_card also lacks a true catch-all
**What goes wrong:** CR-01 fixes `body_copy/1` but `headline/1` (`suppression_card.ex:51-53`) only matches `nil`, `:immutable`, `:reversible` — a novel-shape suppression map raises there too.
**Why it happens:** CONTEXT scopes CR-01 to `body_copy/1` only.
**How to avoid:** When seeding a "novel-shape" suppression for the matrix, ensure it has a `reversibility` key, OR extend the CR-01 fix to `headline/1`'s contract too (flag to planner; minimal-idiom catch-all mirrors the existing pattern).

## Code Examples

### CR-02 nil-safe selected_delivery read (D-05 minimal idiom)
```elixir
# operator_live.ex:153 (open_support_exemplar) and :240-241 (confirm_replay error branch)
# Source: codebase idiom — operator_live.ex uses blank_to_nil/1 + guarded with/case
# Minimal nil-safe read (no new happy-path branch):
delivery_id = blank_to_nil(params["delivery_id"]) ||
  get_in(socket.assigns, [Access.key(:selected_delivery), Access.key(:id)])
```

### CR-03 attr-list correction (D-05; one line)
```elixir
# components.ex:158-183 — add :suppressed to the values list; DO NOT add a status_class(:suppressed) clause.
# Source: STATE-LD-05 (SUMMARY.md:131) — phantom atoms fall through to the _status fallback.
attr :status, :atom,
  values: [:dispatched, :queued, :sent, :delivered, :deferred, :bounced, :failed,
           :rejected, :complained, :unsubscribed, :opened, :clicked, :autoresponded,
           :unknown, :accepted, :no_match, :ignore, :failed_ingest,
           :webhook_replay_requested, :webhook_replay_succeeded, :webhook_replay_failed,
           :reconciled, :suppressed],   # <- :suppressed added
  required: true
```

### Filter disclosure (D-06; pattern, exact markup is the planner's)
```heex
<%!-- Source: Phoenix.LiveView.JS docs + existing JS.focus usage at operator_live.ex:467 --%>
<button type="button" class="btn btn-ghost min-h-11 md:hidden"
        phx-click={JS.toggle(to: "#operator-filter-panel")}>
  Filters
</button>
<div id="operator-filter-panel" class="hidden md:block">
  <%!-- FiltersForm.fields … --%>
</div>
```

## State of the Art

| Old Approach (pre-Phase-97) | Current (verified) | When | Impact |
|-----------------------------|--------------------|------|--------|
| `detail_header` `h2` used `text-xl` | `text-heading` token (`detail_header.ex:21`) | Phase 97 | Phase 98 must NOT re-fix; UI-SPEC's "text-heading was banned text-xl" is a historical note |
| nav_link/nav_pill missing focus ring | `focus-visible:ring-2 ring-primary` present (`shell.ex:207,231`) | Phase 97 (STATE-LD-06) | A11Y-01 focus rings already met on nav — do not re-add |
| row buttons missing focus ring | `focus-visible:ring-2 ring-primary ring-inset` present (`deliveries_list.ex:38`) | Phase 97 (STATE-LD-11) | A11Y-01 already met on rows |
| gallery route absent | `/dev/mail/gallery` + 5 structural assertions (GAP-05 fixed) | Phase 97 | Not operator scope |

**Deprecated/outdated:**
- The `lg:grid-cols-[minmax(22rem,28rem)_1fr]` master-detail grid (`operator_live.ex:397`) — to be replaced by IA-LD-03 percentage templates.
- `tracking-[0.08em]` everywhere — token-banned by IA-LD-04/STATE-LD-13 (but only advisory-gated today).

## Project Constraints (from CLAUDE.md)

- **Zero Node toolchain** — Tailwind standalone binary only; no npm/Node build step for the bundle.
- **Semantic tokens only** — no hex literals, no raw palette, no arbitrary Tailwind values (HEX-GATE / GAP-GATE / TYPE-GATE enforce subsets; tracking/text-lg are advisory-only today).
- **PII minimization** — `mask_recipient/1` in all display + seed work; never put recipient/email in telemetry.
- **Append-only `mailglass_events`** — seed inserts events via `insert_event!/2`; never UPDATE/DELETE (trigger raises 45A01).
- **Multi-tenancy first-class** — `tenant_id` on every seeded record (`@tenant_id "browser-tenant"`).
- **Bundle-clean gate** — rebuild + commit `priv/static/app.css`; `git diff --exit-code priv/static/` reds CI.
- **Brand voice** — never "Oops" (COPY-LD-09); cause-naming pattern; seven domain nouns (Delivery/Message/Suppression/Event), never "Email"/"Status"/"Notification" standalone.
- **No `name: __MODULE__` singletons; no direct `Swoosh.Mailer.deliver/1`** — not relevant to this UI phase but binding.

## Validation Architecture

> Required for the Nyquist VALIDATION.md gate. Every requirement and every CONTEXT decision maps to a concrete, deterministic validation method. The harness is e2e via ONE fixed seed with URL-param-driven state nav.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir) + Playwright (`@playwright/test`, `e2e/`) |
| Config file | `mailglass_admin/mix.exs` aliases (`verify.preview`, `verify.support_contract.admin`); Playwright config in `e2e/` |
| Quick run command | `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors` |
| Conformance gate | `bash mailglass_admin/scripts/check-conformance.sh` (hard) + `…/check-conformance-advisory.sh` (advisory) |
| Bundle gate | `cd mailglass_admin && mix verify.preview` (compile → test → assets.build → `git diff --exit-code priv/static/`) |
| Full e2e | Playwright `e2e/operator.spec.js` + `e2e/structural.spec.js` against the seeded browser server |
| Seed harness | `OperatorFixtures.seed_browser_scenario!/0`; single fixed seed; URL-param state nav; tenant `browser-tenant` |

### Requirement → Validation Map

| Req / Decision | Behavior | Validation Type | Concrete method (deterministic) |
|----------------|----------|-----------------|----------------------------------|
| **GROUP-01** | Groups compose with token spacing rhythm (`gap-lg` outer, `gap-md/sm` intra), flat elevation | grep conformance + ExUnit structural | `check-conformance.sh` GAP-GATE (no `gap-3/4/6`); ExUnit assert rendered HTML contains group `data-testid="operator-*"` cells with `bg-base-200 border border-base-300 rounded-box` (no `shadow`) |
| **PAGE-01** | Overview orients first-time; deliveries serves advanced; both on-spec | Playwright structural | `operator.spec.js:267-283` overview has `operator-overview-health` + `operator-overview-nav`; deliveries master-detail two-pane (`operator.spec.js:33-71`) |
| **PAGE-02** | Happy + error + boundary states coherent | Playwright structural (per-state URL) | New `structural.spec.js` assertions: `getByTestId("operator-detail-error")` reachable via bad `delivery_id`; `operator-empty-detail` via no selection; filtered-empty via non-matching filter |
| **RESP-01** | 390/768/1440 master-detail grid correct | Playwright structural at 3 viewports | At 390 (`setViewportSize 390`): list 100%, reveal-with-back when selected (`deliveriesBox.y < detailBox.y` when unselected — `operator.spec.js:73-102`); at 768/1440 assert two-pane via boundingBox x-offset / `getByTestId("operator-master-detail")` grid-template-columns computed style |
| **FLOW-01** | Deterministic seed reaches every state by URL | ExUnit (seed) + Playwright (reach) | ExUnit assert `seed_browser_scenario!/0` inserts the new `:suppressed`/suppression rows; Playwright navigate each URL in the State Coverage matrix and assert the expected `data-testid` cell |
| **FLOW-02** | End-to-end JTBD (audit why a delivery failed) | Playwright behavioural | Existing `operator.spec.js` replay flows (exact/ambiguous/noop) + select→timeline→suppression chain (lines 33-71); extend with the failed-sendgrid row inspection |
| **A11Y-01** | Focus rings, ARIA, one h1, ≥44px targets | Playwright structural | `structural.spec.js` FACT 1 (aria-selected/aria-current, lines 79-91), FACT 2 (touch ≥44px, 114-160), FACT 5 (focus outline >0, 277-297); one-h1 via `getByRole("heading",{level:1})` count |
| **A11Y-02** | WCAG AA contrast both themes, computed | Playwright computed-style + LLM-score (existing) | `structural.spec.js` FACT 6 accent allowlist (348-372); contrast verified computed (not new baseline cell) — dark border-input mapping is in `app.css`, asserted via computed `border-color` on a sole-boundary element |
| **D-01** | Both views kept, both to spec | Playwright structural | overview testids (267-283) + deliveries testids both visible |
| **D-02** | IA-LD-03 grid percentages replace `minmax(...)` | Playwright computed-style | assert `getByTestId("operator-master-detail")` computed `grid-template-columns` resolves to 40/60 at 768 and 33/67 at chosen ≥1440 breakpoint; assert NO `minmax(22rem,28rem)` (grep ExUnit on rendered markup) |
| **D-03** | Drop `tracking-[0.08em]` from operator markup; apply label token | grep conformance (advisory→hard) + ExUnit | grep `tracking-\[` returns 0 in `operator_live.ex` (and the in-pane components if scoped to 98); ExUnit assert deliveries-list `h2` carries `text-label uppercase font-bold text-secondary` |
| **D-04** | Single-seed URL reachability, row-index stable | ExUnit + Playwright | ExUnit: row count/ordering snapshot; Playwright: all 5 existing `deliveryRow` index tests still green |
| **D-05** | CR-01/02/03 nil-guards | ExUnit unit | CR-01: `body_copy(%{})` returns fallback (no raise); CR-02: render with `selected_delivery: nil` does not raise in the two handlers (or unit-test the helper); CR-03: `status_badge` accepts `:suppressed` without attr warning + renders `badge-outline` |
| **D-06** | 390px filter `JS.toggle`, persistent ≥768 | Playwright structural | At 390: "Filters" button visible, panel `hidden` initially, toggles on click; at 768: panel visible, button `md:hidden`. grep `JS.toggle` present; assert no new socket assign (no `handle_event("toggle_filters"…)`) |
| **D-07** | Token gap rhythm, flat elevation | grep conformance | GAP-GATE clean; ExUnit assert group containers have no `shadow` class (except replay_modal) |
| **D-08** | `data-testid="operator-{group}"` kebab cells; bundle committed | Playwright + bundle gate | `getByTestId` for each new group cell; `mix verify.preview` `git diff --exit-code priv/static/` green |

### Sampling Rate
- **Per task commit:** `cd mailglass_admin && mix test test/mailglass_admin/operator_live_test.exs --warnings-as-errors` + `bash scripts/check-conformance.sh`
- **Per wave merge:** `mix verify.support_contract.admin` + Playwright `e2e/operator.spec.js e2e/structural.spec.js`
- **Phase gate:** `mix verify.preview` green (bundle committed) + full Playwright lane green + advisory gate clean for operator surface (if 98 owns the flip)

### Wave 0 Gaps
- [ ] New Playwright assertions in `e2e/structural.spec.js` for the per-state matrix (detail-error, filtered-empty, truly-empty, suppressed-row) — extend, do NOT add baseline cells
- [ ] New `data-testid` cells in `operator_live.ex` for any new group containers (D-08) — then `getByTestId` assertions
- [ ] ExUnit: `DeliveriesList` empty-state branch unit tests for COPY-LD-01 vs COPY-LD-02 (requires the new `filters_active?`/`empty_kind` signal)
- [ ] ExUnit: CR-01/02/03 unit coverage (currently no test exercises `body_copy(%{})` or nil `selected_delivery` in those two handlers)
- [ ] Seed: `:suppressed` row + (if matrix needs) a second suppression shape, timed to preserve row indices
- [ ] Decision: does Phase 98 flip `check-conformance-advisory.sh` TRACK/TYPE to hard-fail (operator-scoped), or leave to Phase 99?
- [ ] Decision (A1): which Tailwind breakpoint utility realizes the "1440" 33/67 tier (`xl:` 1280 / `2xl:` 1536 / arbitrary `min-[1440px]:`)

*(Existing infra covers: master-detail two-pane, selection flow, replay flows, MOTION-01/02, overview landing, orientation strips, focus rings, ARIA, touch targets — all already green in `operator.spec.js` / `structural.spec.js`.)*

## Security Domain

> `security_enforcement` is not set to `false` in config; including per default. This is an internal read-only operator UI behind the `:ops` auth mount; the relevant controls are PII and access, not net-new attack surface (no new routes, no new inputs beyond existing URL filter params).

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no (unchanged) | `:ops` live_session + `Operator.Mount`/Auth gate already gate `/ops/mail`; phase adds no auth surface |
| V3 Session Management | no (unchanged) | Theme/filter/selection in URL params (existing pattern) |
| V4 Access Control | yes (preserve) | Multi-tenant scoping: every read is `tenant_id`-scoped (`load_deliveries/1` requires non-empty tenant, `:504`); seed work keeps `@tenant_id` on every row |
| V5 Input Validation | yes (preserve) | Filter params normalized via `normalize_filter_params/1` + `cast_enum/2` (`:732`) against `@status_values`/`@event_values`; `String.to_existing_atom` guarded — do not weaken |
| V6 Cryptography | no | None in this surface |
| V7 Error Handling / Logging | yes | Detail-error state (`:not_found`) names the cause without leaking internals (COPY-LD-07 cause-naming, no stack/PII) |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-tenant data exposure via crafted `?tenant_id=` | Information Disclosure | Reads are tenant-scoped; UI shows the tenant chip ("whose data is on screen", forensic trust) — preserve |
| PII (recipient email) leak in rendered HTML or new seed copy | Information Disclosure | `mask_recipient/1` everywhere; seed uses `@example.com` non-PII addresses |
| Atom-table exhaustion via `?status=`/`?event=` | DoS | `String.to_existing_atom` + allowlist membership check in `cast_enum/2` (already correct) |
| New `delivery_id` reveal path leaking existence | Information Disclosure | `detail_error_for/2` returns generic `:not_found`; do not echo the raw id beyond the existing pattern |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The "1440" 33/67 tier is realized with `xl:` (1280) or `2xl:` (1536) or arbitrary `min-[1440px]:` — IA-LD-03 bans `lg:` but doesn't name the exact utility | Architecture Patterns / Wave 0 | Grid breaks at the intended viewport; structural computed-style assertion fails at 1440 |
| A2 | `replay_modal.ex`/`support_cards.ex` `tracking-[0.08em]` cleanup is in Phase 98 scope (they render inside the operator detail pane and weren't fixed in 97) | Conformance Gate Inventory | If they're Phase 99's, the operator advisory gate can't be flipped to hard-fail in 98; or out-of-scope edits land |
| A3 | No new packages needed | Standard Stack | — (low risk; verified against mix.exs) |
| A4 | COPY-LD-01/02 split requires a new `filters_active?`/`empty_kind` signal into `DeliveriesList` | Architecture Patterns / Pitfall 4 | If the planner assumes the component already distinguishes, only one empty copy ships |
| A5 | `headline/1` in suppression_card also lacks a true catch-all (CR-01 may need to extend to it) | Pitfall 5 | Novel-shape suppression seed row raises FunctionClauseError in the heading |

## Open Questions

1. **Which breakpoint utility for the 1440 tier?** (A1)
   - Known: IA-LD-03 says 33/67 "at 1440," bans `lg:`. App uses Tailwind v4 defaults (`md`768/`lg`1024/`xl`1280/`2xl`1536).
   - Unclear: exact utility. Recommendation: `xl:grid-cols-[33%_67%]` (closest standard tier ≥ the `md` 40/60), OR arbitrary `min-[1440px]:` for literal fidelity. Let the UI-checker pick; assert via computed `grid-template-columns`.

2. **Scope of `tracking-[0.08em]` cleanup + advisory-gate flip** (A2)
   - Known: 11 sites; D-03 says "whole operator template." `operator_live.ex:404` is clearly 98. `suppression_card`/`support_cards`/`replay_modal` render in-pane.
   - Unclear: whether flipping `check-conformance-advisory.sh` to hard-fail is 98 or 99 (the script header says 99). Recommendation: Phase 98 cleans ALL operator-surface sites (so the surface is genuinely token-clean) but defers the global gate-flip to Phase 99 unless the planner adds an operator-scoped hard gate.

3. **COPY-LD-01 vs COPY-LD-02 distinction mechanism** (A4)
   - Known: component renders one generic empty copy today.
   - Unclear: exact signal shape. Recommendation: pass `filters_active?` (compare `@filter_params` to `default_filter_params/0`, excluding `window_hours`) from `operator_live.ex` into `DeliveriesList`.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / mix | all build + test | ✓ (assumed; repo is active Elixir project) | `~> 1.18` | — |
| Tailwind standalone binary | `mix mailglass_admin.assets.build` | ✓ (`tailwind ~> 0.4`, vendored binary) | per mix.lock | — |
| PostgreSQL (test) | seed harness (`TestRepo`) | ✓ (assumed; existing e2e lane runs it) | — | — |
| Node.js | — | **intentionally absent** (zero-Node hard rule) | — | not needed |
| Playwright + Chromium | `e2e/*.spec.js` | ✓ in CI lane (assumed; existing specs run) | per e2e config | — |

**Missing dependencies with no fallback:** None identified — all tooling is pre-existing in the e2e/CI lanes that already run the operator specs.

## Sources

### Primary (HIGH confidence — direct codebase reads)
- `mailglass_admin/lib/mailglass_admin/operator_live.ex` (full) — render block, handlers, `detail_error_for/2`, `build_path/4`, `@status_values`
- `mailglass_admin/lib/mailglass_admin/operator/{shell,suppression_card,support_cards,filters_form,deliveries_list,detail_header}.ex`
- `mailglass_admin/lib/mailglass_admin/components.ex` — `status_badge` attr list (:158-183), fallback clauses (:230/:255/:280), `mask_recipient/1` (:295)
- `mailglass_admin/test/support/{operator_fixtures,operator_browser_server,endpoint_case}.ex` — seed harness, ordering, tenant constant
- `mailglass_admin/e2e/{operator,structural}.spec.js` — `deliveryRow`, `openOperator`, all current assertions
- `mailglass_admin/mix.exs` — `verify.preview` alias (:183-188), deps, package
- `mailglass_admin/scripts/{check-conformance,check-conformance-advisory}.sh` — gate definitions (the RATCHET-03 correction)
- `mailglass_admin/test/mailglass_admin/ratchet_baseline_test.exs` — 36-cell frozen baseline
- `mailglass_admin/assets/css/app.css` — `--text-heading: 20px`, `--text-display: 28px`
- `.github/workflows/ci.yml:399-412` — conformance gate wiring (hard vs advisory/continue-on-error)
- `.planning/research/v1.11/SUMMARY.md` — IA-LD-01..07, STATE-LD-05/06/09/11/13, MOTION-LD-02/06/09, DARK-LD-01..07, COPY-LD-01/02/14 (cited, not re-derived)
- `.planning/REQUIREMENTS.md:98-227` — GROUP-01/PAGE-01/02/RESP-01/FLOW-01/02/A11Y-01/02 acceptance text + traceability
- `.planning/RATCHET-GAP-REGISTER.md` — anti-churn sev≥3 contract; GAP-01 (only operator sev≥3 row), GAP-02/03/04
- `.planning/STATE.md` — v1.11 scope locks, frozen baseline, Phase 96/97 completion notes

### Secondary / Tertiary
- None — no WebSearch/Context7 needed; this is a closed-codebase composition phase with all decisions pre-locked.

## Metadata

**Confidence breakdown:**
- Citation verification: HIGH — every line read directly; drift table is exact.
- Conformance gate posture: HIGH — read both scripts + ci.yml wiring; the RATCHET-03 correction is verified, not inferred.
- Architecture patterns (grid/toggle/seed): HIGH for mechanism, MEDIUM for the 1440-breakpoint utility (A1) and COPY split signal (A4) which are genuine open implementation choices.
- Validation architecture: HIGH — mapped to existing + clearly-extendable harness; no new baseline cells.

**Research date:** 2026-06-14
**Valid until:** 2026-06-28 (or until any further Phase 97/98 commit touches the operator surface — re-verify line numbers if so)

## RESEARCH COMPLETE
