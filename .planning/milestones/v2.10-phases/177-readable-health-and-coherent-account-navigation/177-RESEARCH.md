# Phase 177: Readable Health and Coherent Account Navigation - Research

**Researched:** 2026-10-28
**Domain:** Phoenix LiveView admin chrome (Elixir/HEEx), Tailwind v4 + daisyUI bundle, Playwright operator browser lane, Storybook (demo host)
**Confidence:** HIGH (code grounding read this session) / MEDIUM (browser-geometry and demo-host behaviours not executed)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Preview return seam (UXF-10)**
- **D-01: Preview never accepts a URL.** The operator page appends two params to its configured `preview_path` link only when an Account is selected: `return_surface` ∈ {`overview`, `deliveries`, `inbound`} (closed set) and `return_tenant_id` (opaque). Preview reconstructs the destination from the host's existing `navigation[:overview_path | :deliveries_path | :inbound_path]` plus `tenant_id` (and `view=deliveries` where the existing path builder uses it). Selecting from a closed set makes open redirect structurally impossible. Rejected: a `return_to` path param validated against configured paths (larger attack surface; needs WHATWG-vs-`URI.parse` parity for `/\`, `%2F%2F`, tab/newline tricks).
- **D-02: Validation drops silently.** Both params are dropped (direct-entry fallback) if the surface is not in the set, the configured nav path is missing or not a local absolute path, or the id is blank, >255 bytes, not valid UTF-8, or contains control characters. Pure, unit-tested validator module; no error UI.
- **D-03: No public API change.** No new router option or callback; params are internal and undocumented. `__preview_session__/2` and `__operator_session__/2` stay byte-identical (asserted by test). No session, assign-sharing or client storage carrier. Docs note only that Preview `:navigation` paths should point directly at the operator surfaces.
- **D-04: The context is threaded through every Preview URL builder:** index redirect to first scenario (`first_scenario_path`), sidebar scenario patches (`preview/sidebar.ex` `scenario_path`), width patch (`build_capture_url`), and the theme round-trip. Preview rendering never depends on the params. The return is a plain full-page `href` (cross-live_session, `navigate={false}`), so Browser Back returns to Preview.
- **D-05: Destination grants no authority.** Authorization of the target Account stays with the host's existing seam: arrival re-runs `Operator.Mount` → `Auth.authorize(:operator_access, %{params: ...})`, and reads stay scoped through `Tenancy.scope`. Tests add a denying clause to `MailglassAdmin.TestOperatorAuth` for a mismatched `params["tenant_id"]` to prove unauthorized targets are not honored. Rejected: mailglass-side allow-list from `list_tenants(actor)` (activity-derived; would silently break deep links to activity-free Accounts for every adopter — reversible later if wanted).
- **D-06: Copy.** Return affordance names the surface, never the Account: "← Back to Health" / "← Back to Deliveries" / "← Back to Inbound". With validated context, Preview's Health/Deliveries/Inbound nav items carry the same `tenant_id`. Direct entry/tampered: no back link, existing static nav, no error.
- **D-07: Demo exercises dynamic return.** `reference/demo_app` Preview `navigation` points at `/ops/mail`, `/ops/mail?view=deliveries`, `/ops/mail/inbound` (replacing the static Northstar `/demo/login?return_to=…` wrappers). Logged-out direct entry keeps working via `MailglassDemoWeb.AdminAuth` deny with `to: "/demo/login?return_to=…"` (existing `deny/4` `details[:to]`). Respect reference-baseline coupling rules (no pin changes; revert transitive lock drift).
- **D-08: Folded fix.** `ThemeController.sanitized_return_to/2` uses a bare `String.starts_with?` prefix match (accepts `/ops/mailx`, sibling mounts). Replace with a segment-boundary check and reject backslashes/`//`; add regression tests.

**Compact Account control (UXF-09)**
- **D-09: Placement = scope group header.** The Account control becomes the header of a bordered nav group containing only Health, Deliveries, Inbound. Preview moves below the group after a divider, captioned "Not tied to an Account". Topbar keeps only global controls (theme). Below `md`, the control renders full-width at the top of the always-visible `mobile_nav` band with the scoped pills inside the group, preserving 168 D-01 (Account visible at every width) and fixing topbar wrap at 320/375.
- **D-10: No choice → no picker.** With zero or one Account the header is plain text (no chevron, no one-item menu). Multiple Accounts keep the existing `<details>` switcher semantics and `tenant_switch_path/2` URL ownership, 44px targets.
- **D-11: Preview shows no Account identity.** No picker, no disabled picker, no Account name or `tenant_id` text, even from validated return context (Preview has no actor; rendering a URL-supplied value into trusted chrome is spoofable). The scoped group on Preview is headed by a static "Scoped to an Account" label. `account_labels` is NOT added to the preview session.
- **D-12: Preview subtitle describes what Preview reads** (each Mailable's `preview_props/0` scenarios; no Delivery or Inbound records) and never claims "sample data" / "demo data" / Account data — adopters author `preview_props/0`, so provenance claims would be dishonest. Final wording via ux-writing in UI-SPEC.
- **D-13: Accessibility.** Scoped links wrapped in `role="group"` labelled by the header; `aria-describedby` derived from the rendered items (drops Inbound when not installed). Visible focus, non-color cues.

**Health composition (OUTUX-06)**
- **D-14: Expected winner A = single constrained reading column (~42rem), container queries not viewport breakpoints.** Order: (1) observation group (`role=group`: period + help, "Last checked", Refresh — left-aligned, Refresh stays with its timestamp when wrapping); (2) verdict + issue `<ul>`; (3) stale/unavailable notices adjacent to what they qualify; (4) Recent activity, still an `h2` for structure but styled at label size below a hairline, body-size counts.
- **D-15: Bounded comparison, not presumption.** Alternative B = primary list + content-sized aside at container ≥56rem. Both built from the same production components in a temporary story/spike at container widths 288/358/480/736/1150 (plus the real main width beside the 15rem sidebar), light and dark, fixed scenarios. Seven hard gates: no horizontal overflow; DOM order = visual order; observation group cohesive; ≥44px targets; byte-identical `{testid,count,href}` population fingerprint; text status cues; axe clean. Measured tie-breakers decide; record results as a phase artifact. Only the winner ships (no production `layout` attr). If B wins on gates, ship B — no owner call needed unless gates tie and the choice is purely visual.
- **D-16: Populations and links unchanged.** `health_issues/7` keeps its count>0 filter, fixed category order (delivery → inbound → webhook), per-issue deep links and stale markers. Counts lose the large bold gutter treatment; count never drives order, color or severity wording. Move observation markup from `operator_live.ex` into `HealthOverview` (presentation only).
- **D-17: Fixes.** Issue links get `min-h-11`; remove `role=status` from persistent notices (double-announce with toast); `order-*` visual reordering removed. Copy: "Not refreshed", "No mail activity in this period", name which activity is unavailable. Amend `docs/design-system.md` ("observation period stays separate") in the same change. Update the five affected assertions deliberately.

**Verification (D-52 — zero owner UAT)**
- **D-18: Connected ExUnit (full admin lane, `verify.support_contract.admin`):** validator table (unknown surface, blank/oversized/control-char/invalid-UTF-8 id, non-local configured path); custom mounts (`/alt/dev/console`, `/secure/console` with `navigation`); unauthorized Account denied on arrival; direct-entry fallback; context survives index redirect, scenario patch, width patch, theme round-trip; session maps unchanged; ThemeController segment boundary.
- **D-19: `phase177_prohibition_contract_test.exs`** (template phase175), each rule mutation-proven with detector self-test: no Account picker/name/`tenant_id` text on Preview; no "sample/demo data" or Account-data provenance claim; Preview not inside the scoped group; no-choice → no picker; issue order independent of count; no severity words from count; every issue keeps a deep link; Preview/Operator session keys unchanged; Back link never names an Account; `aria-describedby` omits absent Inbound. Author all must-NOTs `verification: test`.
- **D-20: Playwright:** Health comparison geometry gates; replace `metricColumns` 1-vs-2 assertion in `phase169-journey.spec.js`; every issue deep link lands on a filtered view showing the matching count; Browser Back from operator returns to Preview; Account control visible at 320/375/768/1280/1440.
- **D-21: Stories (production components, `delivery_investigation.story.exs` pattern, builders in `reference/persona_spec/quick_view_scenarios.ex/.json`):** HealthOverview — Northstar normal, Helios empty, stale, unavailable, Fjordline long/Unicode; Account control — none, one, many, long label; Preview chrome — valid return, direct entry. Fill `fb-health-crowding` and `fb-account-context` `scenario_ids` + dispositions. Stories prove rendering only; real routes prove scope and return.

### Claude's Discretion
- Exact param names may be adjusted for consistency if planning finds a clash, keeping closed-set semantics.
- Final microcopy wording (UI-SPEC, ux-writing) within D-06/D-11/D-12/D-17 constraints.
- Tie-breaker metrics for D-15.

### Deferred Ideas (OUT OF SCOPE)
- **In-Operator Account switch via `push_patch` does not re-run on_mount host auth** (pre-existing gap, `operator_live.ex:1202-1203`). Not fixed here and must not be described as fixed; capture as a todo for a security-hardening slice.
- Optional mailglass-side tenant allow-list on URL `tenant_id` (research alternative to D-05) — revisit only with the above.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OUTUX-06 | An operator can scan Health's actionable issues in a readable composition with grouped period/freshness/Refresh and subordinate activity, retaining specific deep links and truthful populations. | Health code map (sec. "Code Grounding: Health"), `max-w-2xl` trap, fingerprint golden, five-plus coupled assertions, container-query compile proof, comparison protocol, Playwright geometry lane |
| UXF-09 | A compact Account control clearly scopes Health, Deliveries and Inbound without suggesting Account-scoped Preview data. | Shell/SurfaceNav map, duplicate-render (sidebar + mobile) landmine, inbound `:unavailable` state, topbar CSS rewrite, prohibition P1-P9 grounding |
| UXF-10 | An operator entering Preview can return to the originating Account through a validated host-approved local destination, with a clear direct-entry fallback. | Preview URL-builder map, `ReturnContext` algorithm, ThemeController fix, test-router/`TestOperatorAuth` additions, LV `on_mount` params proof (1.2.13 + 1.1.33), demo AdminAuth gap |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- **Shift-left verification, zero owner UAT (D-52).** Claude runs the evidence; must-NOT prohibitions are authored `verification: test` and become mutation-proven contract tests (template `mailglass_admin/test/mailglass_admin/phase175_prohibition_contract_test.exs`). Never present a "reply yes" checkpoint for anything a machine can observe. Recurring checks go into an existing merge-blocking lane (here: full `mix verify.support_contract.admin`).
- **Decision policy:** research-first, decide, escalate rarely. Phase-level forks are already locked in CONTEXT.
- **Never** `name: __MODULE__` singletons; never PII in telemetry; match errors by struct. Not touched by this phase, but `ReturnContext` must not log or emit telemetry containing the raw `return_tenant_id`.
- **Don't write to `mailglass_admin/priv/static/` without committing the rebuilt bundle** (CI runs `git diff --exit-code`).
- **Brand/voice:** clear, exact, composed; no "Oops"; no emojis in docs/errors. Use "Account" (UI noun), not "workspace"/"tenant" in visible chrome.
- **Conventional Commits; `docs(state):` for STATE.md.** Planner-created branch must be reconciled to main (project memory).
- **Zero Node for adopters:** Playwright/axe are dev-only (`mailglass_admin/package.json` devDependencies) and do not violate this.
- **Local toolchain:** prefix every mix command with `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27`; do not "fix" `.tool-versions`. [CITED: project memory `project_local_elixir_toolchain_gap`]

## Summary

Phase 177 is a pure presentation + navigation-seam phase inside `mailglass_admin` (plus a small `reference/demo_app` wiring change and `reference/persona_spec` story data). **No new packages, no new icons, no router option, no session key.** The work decomposes cleanly: (1) a pure `MailglassAdmin.Preview.ReturnContext` validator and a `ThemeController` boundary fix; (2) operator-side minting of the two internal params in the one shared `Operator.Shell.shell/1` (covers `OperatorLive` and `InboundLive` at once) and Preview-side re-derivation + threading through five URL builders; (3) a `SurfaceNav` scope-group rewrite that re-homes `Shell.account_context/1` from the topbar `:actions` slot into the group header; (4) a `HealthOverview` recomposition that absorbs the observation markup now living in `operator_live.ex:743-769`; (5) stories/manifest, connected ExUnit, a mutation-proven prohibition contract, Playwright geometry, and a bounded A/B comparison.

Four findings change how the plan must be written and are not obvious from the UI-SPEC:

1. **`max-w-2xl` is 48px in this repo, not 42rem.** `assets/css/app.css:107-116` defines `--spacing-2xl: 48px`; Tailwind v4's `max-w-*` resolves `--spacing-*` before `--container-*`. I compiled the repo's `@theme` with the bundled Tailwind binary: `.max-w-2xl { max-width: var(--spacing-2xl); }`. The Health reading column must use a named CSS class (precedent: `.operator-deliveries-layout`, `.mg-inbound-replay-dialog { max-width: 42rem }`) or an arbitrary value, never `max-w-2xl`/`max-w-xl`/`max-w-3xl`.
2. **The Account control will be rendered twice** (sidebar `aside` is `hidden md:block`, `mobile_nav` is `md:hidden`; both always in the DOM). Every `id`, `aria-labelledby/describedby` target, `JS.show(to: "#…")` selector and `data-testid` that was unique when the control lived once in the topbar becomes a duplicate. 15 Playwright references to `operator-account-*` will hit strict-mode violations. Layout-suffixed ids and a visible-only e2e helper are required.
3. **Inbound has a real `:unavailable` tenant state with empty `tenant_options`** (`inbound_live.ex:189-205`); the UI-SPEC's "No Accounts yet" variant for empty options would contradict the page's own "Account options unavailable" card unless the shell receives the tenant state.
4. **The demo's `AdminAuth` has no logged-out `to:`** (`reference/demo_app/lib/mailglass_demo_web/admin_auth.ex`: the catch-all returns only `%{message: ...}`), so D-07's "keeps working via deny `to:`" requires adding that clause; today a logged-out hit on `/ops/mail` redirects to `unauthorized_path: "/"`. The `deny/4` seam exists; the demo adapter does not use it.

**Primary recommendation:** Build bottom-up in this order so each wave is independently green: pure validator + ThemeController fix → Health population-fingerprint golden captured **before** any Health markup change → Health recomposition → ReturnContext minting/threading → SurfaceNav/Shell scope group (with layout-suffixed ids) → CSS rewrite + bundle rebuild → demo wiring → stories/manifest → prohibition contract → Playwright + comparison artifact.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Health composition (order, wrap, container-query reflow) | Frontend Server (HEEx function components) | Browser (CSS container queries) | Markup order is server-rendered; reflow is pure CSS (`@container`), no JS |
| Health populations / deep links | API / Backend (`OperatorLive.health_issues/7`, unchanged) | — | Presentation-only phase; `health_issues/7` is `operator_live.ex:2849-2931` |
| Account scope group + header variants | Frontend Server (`Operator.Shell`, `SurfaceNav`) | Browser (`<details>` + `data-dismiss-outside` behaviour in `hooks.js`, unchanged) | Header variant is a pure function of `tenant_options` + `selected_tenant_id` + tenant state |
| Account selection state | URL (`?tenant_id=`) via `tenant_switch_path/2` | API (host `Auth.authorize`) | Locked: URL-owned, no global state (D-03/D-11) |
| Return-context minting | Frontend Server (`Operator.Shell.shell/1`, once for both LiveViews) | — | `active` attr already ∈ {overview, deliveries, inbound} = the closed set |
| Return-context validation + href derivation | Frontend Server (Preview LiveView, pure `ReturnContext`) | — | Preview has no actor; derives only from host `navigation` + URL value |
| Authorization of the target Account | API / Backend (host `MailglassAdmin.Auth` via `Operator.Mount`) | Database (`Tenancy.scope`) | Authority stays at the destination (D-05); Preview grants none |
| Theme round-trip return | API (`ThemeController`, HTTP) | Frontend Server | Sanitizer is the only open-redirect-shaped code in scope (D-08) |
| Stories/manifest | Demo host (`reference/demo_app/storybook`) | Admin test build (`quick_view_projection_test.exs`) | Manifest-first: JSON → pure builder → production assigns |

## Standard Stack

### Core (all existing; nothing is installed)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix LiveView | 1.2.13 (admin), 1.1.33 (demo) | Components, `on_mount`, `push_patch` | [VERIFIED: `mailglass_admin/deps/phoenix_live_view/mix.exs:4` `@version "1.2.13"`; `reference/demo_app/deps/phoenix_live_view/mix.exs:4` `@version "1.1.33"`] |
| Tailwind CSS (standalone binary) | 4.1.12 | Bundle build, container-query variants | [VERIFIED: `mix mailglass_admin.assets.build` output `≈ tailwindcss v4.1.12`] |
| daisyUI | 5.5.19 | Semantic theme classes | [VERIFIED: build output `daisyUI 5.5.19`] |
| ExUnit + `Phoenix.LiveViewTest` + Floki | in `mix.lock` | Merge-blocking connected/contract tests | existing lane |
| Playwright + `@axe-core/playwright` | 1.59.1 / ^4.11.2 | Operator browser gate, geometry, axe | [VERIFIED: `npx playwright --version` → 1.59.1; `mailglass_admin/package.json`] |
| phoenix_storybook (demo only, `only: :dev`) | existing | Retained production-component stories | existing `delivery_investigation.story.exs` pattern |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Closed-set `return_surface` + opaque `return_tenant_id` (locked) | `return_to` path param | Rejected in D-01 (parser-confusion surface) |
| Named CSS class for the 42rem column | `max-w-[42rem]` arbitrary value | Either avoids the `--spacing-2xl` trap; a named class matches `.operator-deliveries-layout` precedent and keeps the Playwright `<= 42*16+1` assertion stable |

**Installation:** none. `mix.exs`, `package.json`, `mix.lock` must not change (CLAUDE.md: reference baselines revert transitive lock drift).

**Version verification:** Tailwind/daisyUI/LV versions read from the files and build output above this session; no registry lookups needed because no package is added.

## Package Legitimacy Audit

No external packages are installed or added by this phase. `gsd-tools query package-legitimacy check` was not run because there is nothing to check.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| (none) | — | — | — | — | — | — |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
 Operator surfaces (one live_session: Operator.Mount -> host Auth.authorize(:operator_access, %{params: ...}))
 ┌──────────────────────────────────────────────────────────────────────────┐
 │ OperatorLive (overview|deliveries)   InboundLive                         │
 │   assigns: preview_path (from session "navigation"), selected_tenant_id, │
 │            tenant_options, tenant_state, account_labels                  │
 │            │                                                              │
 │            ▼                                                              │
 │   Operator.Shell.shell/1  ── active ∈ {:overview,:deliveries,:inbound}   │
 │      │ mints preview href:  preview_path + ?return_surface=<active>      │
 │      │                      &return_tenant_id=<selected>  (only if Account │
 │      │                      selected AND preview_path is a local path)    │
 │      ▼                                                                    │
 │   SurfaceNav.nav (rendered TWICE: sidebar + mobile band)                  │
 │      [scope group: Account header | Health | Deliveries | Inbound]        │
 │      ───────── divider ─────────                                          │
 │      Preview  (caption: Not tied to an Account)                           │
 └───────────────┬──────────────────────────────────────────────────────────┘
                 │ plain <a href> (cross live_session = full page load)
                 ▼
 Preview surface (separate live_session; session = mailables, live_session_name,
                  admin_chrome_theme_cookie, navigation — UNCHANGED)
 ┌──────────────────────────────────────────────────────────────────────────┐
 │ PreviewLive.handle_params(params, uri)                                    │
 │   ReturnContext.resolve(params_with_query, admin_navigation)              │
 │      surface ∈ closed set? navigation[surface_path] local? id valid?      │
 │        yes ─► %{surface, tenant_id, href, query_pairs}   no ─► nil        │
 │   assign :return_context  (never rendered as text; only inside href)      │
 │      │                                                                    │
 │      ├─ index redirect  first_scenario_path/3 ─ + query_pairs             │
 │      ├─ Sidebar.scenario_path / broken_path    ─ + query_pairs            │
 │      ├─ build_capture_url (width patch)         ─ + query_pairs           │
 │      ├─ preview_theme_path (return_to keeps query already) ─► ThemeController
 │      │         sanitized_return_to: segment boundary (D-08) ─► redirect   │
 │      ▼                                                                    │
 │   SurfaceNav: [Back to <Surface>] first focusable; group header           │
 │   "Scoped to an Account"; Health/Deliveries/Inbound hrefs = derived href  │
 └───────────────┬──────────────────────────────────────────────────────────┘
                 │ Back link / scoped nav (plain href)
                 ▼
 Operator arrival: Operator.Mount re-runs host Auth with %{params: %{"tenant_id" => ...}}
   deny -> {:halt, redirect to details[:to] || unauthorized_path}   (no mailglass copy)
```

### Recommended Project Structure

```
mailglass_admin/lib/mailglass_admin/
├── preview/return_context.ex        # NEW  pure validator + href/query builder (@moduledoc false)
├── operator/health_overview.ex      # EDIT split into observation/verdict/issue_list/notices/activity + overview/1
├── operator/shell.ex                # EDIT scope-group header, mint Preview href, layout-suffixed ids
├── surface_nav.ex                   # EDIT scope group + back link + divider + Preview caption
├── preview_live.ex                  # EDIT assign :return_context; thread through 3 builders; subtitle
├── preview/sidebar.ex               # EDIT accept :return_query; thread scenario_path/broken_path
├── controllers/theme_controller.ex  # EDIT segment-boundary sanitizer
├── operator_live.ex                 # EDIT remove observation markup (743-769), pass strings to HealthOverview
└── (admin_shell.ex, router.ex)      # NO API change; router.ex moduledoc :navigation bullet may gain one docs sentence
mailglass_admin/assets/css/app.css   # EDIT .operator-health-layout/column; rewrite topbar max-width:767px block
mailglass_admin/priv/static/app.css  # REBUILD + commit
mailglass_admin/test/...             # see Validation Architecture
reference/demo_app/                  # router.ex navigation; admin_auth.ex deny `to:`; storybook/operator/health.story.exs etc.
reference/persona_spec/              # quick_view_scenarios.json + .ex builders
```

### Pattern 1: Pure validator (`ReturnContext`)

**What:** One total function from `(params, navigation)` to `nil | %{surface, tenant_id, href, query_pairs}`; plus `preview_href(preview_path, surface, tenant_id)` for the operator side. Never raises, never `String.to_atom`, never logs.
**When to use:** `PreviewLive.handle_params/3` (both clauses) and `Operator.Shell.shell/1`.
**Example:**
```elixir
# Source: RETURN-DESTINATION.md §2.3 (algorithm), adapted to D-01/D-02. Local sketch, not shipped code.
@surfaces ~w(overview deliveries inbound)

def resolve(%{"return_surface" => s, "return_tenant_id" => t}, navigation)
    when is_binary(s) and is_binary(t) and s in @surfaces do
  with path when is_binary(path) <- nav_path(navigation, s),
       true <- local_path?(path),
       true <- valid_tenant_id?(t) do
    pairs = [{"return_surface", s}, {"return_tenant_id", t}]
    %{surface: s, tenant_id: t, href: put_tenant(path, t), query_pairs: pairs}
  else
    _ -> nil
  end
end
def resolve(_, _), do: nil   # list/map values, missing keys, unknown surface

# Replace-in-place so a host path like "/ops/mail?tenant_id=browser-tenant" keeps key order
# and never gains a second tenant_id:
defp put_tenant(path, t) do
  uri = URI.parse(path)
  pairs = URI.query_decoder(uri.query || "") |> Enum.to_list()
  pairs = List.keystore(pairs, "tenant_id", 0, {"tenant_id", t})
  URI.to_string(%{uri | query: URI.encode_query(pairs)})
end
```

### Pattern 2: Threading via one query-pairs helper, not per-builder logic

`ReturnContext.query_pairs(ctx)` returns `[]` for `nil`. Each Preview builder appends it with `URI.encode_query` so direct-entry URLs stay byte-identical (existing assertions such as `assert_patch(view, base_path <> "?width=375")` at `preview_live_test.exs:790` keep passing).

### Pattern 3: Retained-story data is manifest-first

JSON facts in `reference/persona_spec/quick_view_scenarios.json` → pure builder in `quick_view_scenarios.ex` → production component assigns → story + ExUnit table in `quick_view_projection_test.exs` (Phase 176 plan 08 pattern, `@tag :phase176`). Each scenario object carries `id, story_path, theme_owner, theme_picker_testid, variation_id, role_job, source, cohort, state, reason, owning_requirements, proof_boundary, feedback_ids, rendered, projection` [VERIFIED: printed from the existing `inbound-evidence-normal-contacts` entry this session].

### Anti-Patterns to Avoid

- **Per-builder hand-rolled query strings in Preview** — they silently drop the context (that is today's bug at `build_capture_url/2`, `preview_live.ex:798`, and `Sidebar.scenario_path/5`, `sidebar.ex:394-398`).
- **Rendering `return_tenant_id` anywhere but inside an `href`** (D-11/P2). Do not put it in `page_title`, flash, `data-*`, `aria-label`, or telemetry.
- **A second source of Account truth in Preview** — no `:selected_tenant_id`, `:tenant_id`, `:account_labels` assigns on `PreviewLive` (P8).
- **`order-*`/`flex-row-reverse`/`lg:` viewport breakpoints inside `HealthOverview`** (D-17, G2).
- **Reaching for `Components.stat_card/card`** for Health (banned by design system; STATCARD-GATE exists for overview sources).

## Code Grounding

All line numbers read this session from the working tree at `0e0fb29a`. Where CONTEXT cited stale numbers, the corrected number is given.

### Health (OUTUX-06)

| Item | Location | Notes |
|------|----------|-------|
| `HealthOverview.overview/1` | `operator/health_overview.ex:7-169` | Today: verdict `section[data-testid=operator-health-status]` (39-98) holds verdict + issue rows + notices; activity `section` (100-166). Outer `div.grid.gap-lg.lg:grid-cols-[minmax(0,2fr)_minmax(0,1fr)]` at line 38 is the 2:1 grid. attrs: `issues, activity, states, deliveries_path, inbound_path` (lines 7-11). |
| Verdict copy | `health_overview.ex:17-33` | `"Needs attention"`, detail `"Some checks could not be updated."`; `"Health check incomplete"`/`"Refresh to try again."`; `"No recent mail activity"`; `"No issues found"`/`"No recorded problems in this period."` |
| Issue row | `health_overview.ex:48-82` | `<div class="mt-md divide-y ...">` with `<div data-testid={issue.testid}>`; count is `<p class="mono min-w-10 ... text-heading font-bold tabular-nums">` (54); label links `py-xs` only (no `min-h-11`); stale tag text `Last retrieved` (79); `deliveries` issues use `patch`, `inbound` use `navigate` |
| Notices | `health_overview.ex:84-97` | `role="status"` on each notice; copy `"{panel}: last retrieved <timestamp>."` / `"could not be loaded."` |
| Activity | `health_overview.ex:100-166` | `h2#operator-health-activity-title`; `sm:flex-row ... lg:flex-col`; fallback `"Activity unavailable"` (133, 161) |
| Observation markup to move | `operator_live.ex:743-769` | `data-testid=operator-health-window`, `operator-health-last-checked` (`order-3 col-span-2 text-right sm:order-none`), `phx-click="retry_health"` button with `[.phx-click-loading_&]:hidden` label swap. `health_window_copy/1` `:2812-2826`, `health_window_description/1` `:2828-2835` are `defp` in OperatorLive: pass the **resulting strings** (plus `@health_observed_at`) into `HealthOverview` rather than moving the helpers. |
| Call site | `operator_live.ex:740-789` | wrapper `div[data-testid=operator-overview-health].grid.gap-md` then `HealthOverview.overview issues={health_issues(...)}` |
| Populations | `operator_live.ex:2849-2931` | `(delivery_issues ++ inbound_issues ++ webhook_issues) \|> Enum.filter(&(is_integer(&1.count) and &1.count > 0))` — verbatim at 2929-2930. Issue map keys: `count,label,help,testid,surface,path,stale?`. |
| Refresh handler | `operator_live.ex:525-540` | toast `"Email health refreshed."` / `"Some health data could not be refreshed."` (old) — UI-SPEC copy row changes the latter to `"Some health checks couldn't be refreshed. Showing the last results retrieved."` |
| Tooltips | `Components.field_help/1` | 24x24 trigger; unchanged. |

**Issue-row testids (stable):** `operator-overview-health-failures`, `operator-overview-health-orphans`, `operator-health-deliveries-{failed|bounced|rejected|deferred}`, `operator-health-inbound-{failed|no_match}`; link testid = `testid <> "-link"`; help id = `testid <> "-help"`. Notice testid `operator-health-{stale|unavailable}-{failed_ingest|orphan_backlog|delivery_activity|inbound_activity}`. Activity: `operator-health-outbound-activity`, `operator-health-inbound-activity`. [VERIFIED: health_overview.ex + operator_live.ex:2854-2923]

**Add an explicit count testid** (`issue.testid <> "-count"`) and migrate the four Floki selectors that today find the count by `p.mono` (below) to it; the UI-SPEC removes `mono` from counts, so every `p.mono` selector breaks.

#### Existing assertions that WILL break (complete list; the "five" in CONTEXT is a floor)

| File:line | Assertion | Why it breaks |
|-----------|-----------|---------------|
| `test/mailglass_admin/operator_live_test.exs:4639-4640` | `"[data-testid='operator-health-status']", "No recent mail activity"` | verdict copy -> "No mail activity in this period" |
| `operator_live_test.exs:4761` | `refute html =~ "No recent mail activity"` | becomes vacuous if copy changes; change to the new string |
| `operator_live_test.exs:5713, 5736, 5782, 5799` | `Floki.find(card, "p.mono")` | count no longer `mono` |
| `operator_live_test.exs:5737` | `Floki.text(same_window_card) =~ "Last retrieved"` | tag -> "Not refreshed" |
| `operator_live_test.exs:5756` | `changed_window_html =~ "could not be loaded"` | notice copy -> "couldn't be loaded" (apostrophe is static template text, so `html =~` works; interpolated copy would be `&#39;`-escaped) |
| `operator_live_test.exs:5791` | push_event `message: "Some health data could not be refreshed."` | toast copy |
| `operator_live_test.exs:2728` | `assert html =~ ~s(href="/dev/mail")` (tenant selected) | Preview href now carries `?return_surface=...&return_tenant_id=...` (`&amp;` in HTML) |
| `test/mailglass_admin/persona_cohort_test.exs:116` | `assert html =~ "No recent mail activity"` | verdict copy |
| `test/mailglass_admin/operator/shell_test.exs:216` | `labels == ["Health", "Preview", "Deliveries", "Inbound"]` | nav order -> Health, Deliveries, Inbound, Preview |
| `test/mailglass_admin/preview_live_test.exs:358-359` | subtitle `"See how your emails look in HTML and plain text."` | D-12 subtitle |
| `test/mailglass_admin/voice_test.exs:65` | same subtitle string | D-12 subtitle (edit in place; `voice_test.exs:114` has an `@tag :skip` but admin tests are not in the test-exception registry scan, see Pitfall 9) |
| `e2e/phase169-journey.spec.js:52` | `toContainText("Last retrieved")` | tag copy |
| `e2e/phase169-journey.spec.js:357,367` | `metricColumns` of `[data-testid="operator-overview-health"] > div:nth-child(2)` `=== (width < 1024 ? 1 : 2)` | replace with single-column + `getBoundingClientRect().width <= 42*16+1` by testid |
| `e2e/flows.spec.js:845-847, 926-928, 957-962, 1049-1052, 1477-1519, 1949-1951, 2010, 2080` ; `e2e/structural.spec.js:2546-2573` ; `e2e/inbound-layout.spec.js:195` ; `e2e/phase170-journey.spec.js:391` ; `e2e/phase175-inbound.spec.js:297` | `operator-account-switcher/-option/-context/-id/-switch-status` | duplicates (sidebar + mobile) and relocation out of the topbar; see Pitfall 2 |
| `e2e/flows.spec.js:1298-1337`, `e2e/phase168-plan03-acceptance.spec.js:58` | `getByTestId("surface-nav-sidebar").getByRole("link", {name:"Preview"/"Health"...})` | still resolve (names unchanged; "Back to Health" does not match `exact: true`); verify, do not assume |
| `e2e/health-tooltips.spec.js:58` | `toContainText("Email health refreshed.")` | unchanged (success toast copy not changed) |

Docs: `mailglass_admin/docs/design-system.md:193-195` ("...such as the observation period or section title, stays separate.") and `:209-210` ("No activity shows a neutral “No recent mail activity”.") must be amended in the same change. `token_parity_test.exs:196-230` reads the guide but pins other strings, not these (checked), so no test blocks the edit; add a docs-contract assertion to the new Phase 177 test file so the amendment cannot regress.

### Operator layout, Account control, SurfaceNav (UXF-09)

| Item | Location | Notes |
|------|----------|-------|
| `AdminShell.shell/1` slots | `admin_shell.ex:20-24, 44-51 (actions), 54-62 (sidebar: "hidden min-w-0 ... md:block"), 64-71 (mobile_nav: "... md:hidden")` | Both nav copies are always in the DOM. API unchanged by this phase. |
| `Operator.Shell.shell/1` | `operator/shell.ex:156-224` | `:actions` slot holds `<.account_context>` + `theme_picker` (184-192); `:sidebar` and `:mobile_nav` each render `SurfaceNav.nav` (193-213) |
| `account_context/1` | `shell.ex:226-318` | `<details>` only when `@tenant_options != []` (243-291); `<div :if={@tenant_options == []}>` static fallback (292-300); fallbacks `"Choose Account"` at **250 (aria-label), 259, 298**; sr-only `operator-account-id` (301-303); per-option `operator-account-switch-status-#{index}` ids (304-315) + `JS.show(to: "#operator-account-switch-status-#{index}")` (274-279) |
| `tenant_switch_path/2` | `shell.ex:99-111`; `@switch_query_keys ~w(provider status event outcome window_hours search view)` at 146 | URL ownership: keep unchanged |
| `surface_paths/4` | `shell.ex:57-65` | `overview: root <> build_query(tenant_id)`, `deliveries: ... [{"view","deliveries"}]`, `inbound: path_join(root,"inbound") <> build_query(tenant_id)` |
| `tenant_selector/1` | `shell.ex:386-440` | body selector; "Choose Account" at 431 is **retained** (asserted by `voice_test.exs:297`, `operator_live_test.exs:2568`, `inbound_live_test.exs:108`) |
| `SurfaceNav` | `surface_nav.ex:8-13` `@items` order: Health(`:overview`), Preview, Deliveries, Inbound; `attr(:active, :atom, values: [:preview, :overview, :deliveries, :inbound])` (15); `nav_class(:sidebar)` `"flex flex-col gap-xs"` / `(:mobile)` `"flex flex-wrap items-center gap-xs"`; `aria-label="Mailglass sections"`, `data-testid={"surface-nav-#{@layout}"}` (27-31) | Rewrite order -> Health, Deliveries, Inbound, divider, Preview; keep one `<nav>` landmark |
| `Components.nav_link/nav_pill` | `components.ex:243-355`; `navigate={false}` renders `<.link href>`; `@rest` global passes `id/data-*` | Reuse (PRIMITIVE-DRIFT-GATE requires Shell to consume `Components.nav_*`) |
| Tenant state | `operator_live.ex:1200-1203`: `tenant_state(nil, [], _) -> :none`, `(nil, [_t], false) -> :auto_select`, `(nil, _ts, _) -> :select_required`, `(_sel, _, _) -> :selected` | Any non-nil URL `tenant_id` is `:selected` regardless of membership (hence D-05 host-owned auth) |
| Inbound unavailable | `inbound_live.ex:189-205` (`tenant_options_state == :read_unavailable and is_nil(selected_tenant_id) -> :unavailable`), rendered at 580-587 | `Shell.shell` currently receives only `tenant_options`; add a `tenant_state` (or `options_unavailable?`) attr so the header does not say "No Accounts yet" next to "Account options unavailable" |
| Topbar CSS to rewrite | `assets/css/app.css:690-748` (`@media (max-width: 767px)`): grid on `admin-shell-topbar`; `admin-shell-actions {display: contents}`; Appearance fieldset `grid-column: 2; grid-row: 1`; `[data-testid="operator-account-context"] { grid-column: 1 / -1; grid-row: 2 }`; `operator-account-switcher > span > .text-secondary {display:none}` (hides the "Account" eyebrow on narrow!); `.mg-scope-identity {max-width: 18rem}` (340), `.mg-scope-menu {width: min(22rem, calc(100vw - 2rem))}` (344) | Preview also uses `admin-shell-topbar`/`-actions` (preview_live.ex:317-325): keep the fieldset placement rules; delete the account-specific rules. The eyebrow-hiding rule contradicts UI-SPEC (Account eyebrow stays visible). |
| Existing ExUnit coverage of the switcher | **none** (`grep operator-account\|Change Account\|Available Accounts\|Switching to test/` -> no hits) | All header variants need new tests; the only coverage today is Playwright |

### Preview URL builders and navigation (UXF-10)

| Builder | Location | Today | Needs |
|---------|----------|-------|-------|
| `handle_params` (show) | `preview_live.ex:98-161` | `params = params_with_query(params, uri)` (871-879) merges query into params | `assign(:return_context, ReturnContext.resolve(params, socket.assigns.admin_navigation))` in **both** clauses and the error/not-found branches (otherwise the back link disappears on a bad scenario URL) |
| `handle_params` (index) | `163-191` | `redirect(socket, to: first_scenario_path(mount_path, mailables, device_width))`; `"#"` when no previewable mailable | append `query_pairs`; when no mailables, index renders the empty state and still needs the back link |
| `first_scenario_path/3` | `682-693` | `build_capture_url(path, Integer.to_string(device_width))` | pass context |
| `build_capture_url/2` | `798` `base_path <> "?width=" <> width` | used by 3 callers (688, 788) | `build_capture_url(base, width, query_pairs)` |
| `sync_patch_capture_url_state/1` | `779-796` | `push_patch(to: build_capture_url(socket.assigns.base_path, width))` — **drops every unknown param** | pass `socket.assigns.return_context` |
| `Sidebar.scenario_path/5` | `preview/sidebar.ex:394-398`; used at 186-187 and 285-286 (`patch=`) | `scenario_base_path(...) <> "?width=" <> ...` | new `:return_query` attr on `picker/1` and `menu/1`; thread to `scenario_path` and `broken_path` (400-402; callers 237, 315) |
| `preview_theme_path/2` | `807-846` | `return_to = path \|> append_query_without_theme(parsed.query \|\| "") \|> put_frame_query(...)`; **already keeps other query params** | no code change needed if `page_uri` carries them; needs a test (T10) |
| `preview_surface_paths/1` | `743-762` | `preview: current_preview_path(assigns)`, `overview/deliveries/inbound` from `admin_navigation` via string-or-atom `navigation_path/2` | Health/Deliveries/Inbound -> `ctx.href`-derived (per-surface, each from its own `navigation` entry + same tenant); Preview item -> mount path **plus** `query_pairs` so clicking Preview keeps context |
| Subtitle | `preview_live.ex:349-351` | `See how your emails look in HTML and plain text.` | UI-SPEC string |
| Mobile + sidebar nav | `326-346` | two `SurfaceNav.nav` calls | add `return_href`/`return_surface` attrs and scope-header mode `:preview` |

**Navigation config shapes.** `navigation` reaches both LiveViews as a map in the session, atom-keyed (`router.ex:406-411`: `opts \|> Keyword.get(:navigation, []) \|> Enum.reject(fn {_key, value} -> value in [nil, ""] end) \|> Map.new()`); `navigation_path/2` in both LiveViews already tolerates string keys. Schema keys (verbatim, `router.ex:107-128`): `preview_path`, `overview_path`, `deliveries_path`, `inbound_path`, each `{:or, [:string, nil]}` with no locality check.

**Configured paths may already contain a query.** The synthetic test router configures Preview with `overview_path: "/ops/mail?tenant_id=browser-tenant"`, `deliveries_path: "/ops/mail?tenant_id=browser-tenant&view=deliveries"`, `inbound_path: "/ops/mail/inbound?tenant_id=browser-tenant"` (`test/support/endpoint_case.ex:48-52`), and `preview_live_test.exs:363-365` asserts those exact hrefs for direct entry. The derivation must therefore **replace `tenant_id` in place** (Pattern 1) rather than append, and direct-entry output must stay byte-identical. The demo will configure `/ops/mail?view=deliveries` (D-07), so `view=deliveries` rides in the configured path, not in mailglass code.

**Session whitelist facts (must stay byte-identical, D-03).** Preview (`router.ex:371-376`): `"mailables"`, `"live_session_name"`, `"admin_chrome_theme_cookie"`, `"navigation"`. Operator (`router.ex:385-399`): `"subject_id"`, `"tenant_id"`, `"auth_method"`, `"recent_auth_at"`, `"live_session_name"`, `"admin_chrome_theme_cookie"`, `"navigation"`, `"account_labels"`, `"inbound_router"`. Existing guard: `router_test.exs:195-246` (`assert Enum.sort(Map.keys(session)) == [...]` and `assert session["navigation"] == %{}`) and `:249-293` (`assert session == %{...}`). The Phase 177 "unchanged" test can reuse these assertions plus a `refute` on any `return_*` key.

**ThemeController.** `controllers/theme_controller.ex:52-60` (CONTEXT's `:11-19` is stale):
```elixir
cond do
  parsed.scheme || parsed.host -> mount_path
  String.starts_with?(return_to, "//") -> mount_path
  not String.starts_with?(parsed.path || "", mount_path) -> mount_path
  true -> Theme.strip_theme_query(return_to)
end
```
Fix: `path == mount_path or String.starts_with?(path, trim_trailing(mount_path, "/") <> "/")` (special-case `mount_path == "/"`), reject any `\` and any `//` in the path, and (recommended, not required by D-08) reject `.`/`..` and `%2e` segments, which browsers normalise out of the mount. Existing tests to keep green: `router_test.exs:83-152` (light/dark/system, `strips legacy theme query`, `rejects external return urls` -> `redirected_to(conn) == "/ops/mail"`). Add regression tests in the same `describe "theme persistence route"` for `/ops/mailx`, `/ops/mail%2e%2e/x`, `/ops/mail\\x`, `/ops/mail//x`, `/dev/mail/x` while mounted at `/ops/mail`.

**Operator.Mount / Auth.** `operator/mount.ex:19-26` builds `auth_context = %{params: params, session: session, socket: socket, actor: Auth.session_actor(session)}` and calls `Auth.authorize(opts[:auth], :operator_access, auth_context)`; denial -> `deny/4` uses `Map.get(details, :to, opts[:unauthorized_path])` (the redirect `to`). Verified that `params` contains the query string on **both** LiveView clients: `deps/phoenix_live_view/lib/phoenix_live_view/route.ex:94-95` `query_params = if query, do: Plug.Conn.Query.decode(query), else: %{}` and `:113` `params: Map.merge(query_params, path_params)` (admin LV 1.2.13); identical at `reference/demo_app/deps/phoenix_live_view/lib/phoenix_live_view/route.ex:60-61, 79` (demo LV 1.1.33); the static render passes `conn.params` (`static.ex:155`). So the D-05 arrival-denial proof is valid on both. It only covers **arrival** (`mount`); a `push_patch` Account switch does not re-run `on_mount` (the deferred gap) — tests must not claim otherwise.

**`MailglassAdmin.TestOperatorAuth`** (`test/support/endpoint_case.ex:349-383+`): clauses `authorize(:operator_access, %{actor: %{subject_id: nil}})`, `...%{actor: %{subject_id: "blocked"}}`, then the generic `%{actor: actor}` at 377. Insert the new denying clause **before 377**, matching `%{params: %{"tenant_id" => <sentinel>}}` (guard on `is_map(params)`: it is `:not_mounted_at_router` for non-router mounts) and returning `{:error, :unauthorized, %{message: "Operator access denied.", to: "/login"}}`. Test pattern for the redirect: `operator_live_test.exs:1084-1091` `assert {:error, {:redirect, %{to: "/login"}}} = live(...)`. Note `TestOperatorHook :audit` (`endpoint_case.ex:320-346`) runs before `Operator.Mount`; it reads `session["auth_method"]`, not params, so it does not interfere.

**Test router mounts for custom-mount proof.** `endpoint_case.ex`: `/dev` (43) Preview `/mail` with navigation; `/alt/dev` (60) Preview `/console` (`live_session_name: :mailglass_admin_preview_alt`, **no navigation**); `/ops` (73) operator `/mail` with `navigation: [preview_path: "/dev/mail"]`; `/secure` (107) operator `/console` (`live_session_name: :mailglass_admin_operator_alt`, **no navigation**). Add `navigation:` to the two alt mounts (Preview alt -> `/secure/console`, `/secure/console?view=deliveries`, `/secure/console/inbound`; operator alt -> `preview_path: "/alt/dev/console"`). Tests that mention these mounts only check asset hrefs (`admin_asset_url_test.exs:75-92`, `assets_test.exs:89`, `e2e/admin-assets.spec.js:132-159`), so the addition is low-risk.

**Demo (D-07).**
- `reference/demo_app/lib/mailglass_demo_web/router.ex:104-148` — Preview `navigation` is today `"/demo/login?return_to=%2Fops%2Fmail%3Ftenant_id%3Dnorthstar"` (+ `%26view%3Ddeliveries`, `/inbound`). Replace with `"/ops/mail"`, `"/ops/mail?view=deliveries"`, `"/ops/mail/inbound"`. Operator `navigation: [preview_path: "/dev/mail"]` (line 140) stays.
- `admin_auth.ex`: all `authorize/2` clauses match `%{actor: %{subject_id: subject_id}} when is_binary(subject_id)`; catch-all `{:error, :unauthorized, %{message: "demo operator login required"}}` has **no `:to`**, so logged-out users go to `unauthorized_path: "/"` (router.ex:146). Add a clause for `:operator_access` with a nil subject returning `to: "/demo/login?return_to=" <> URI.encode_www_form(...)`. The auth context has `params` (tenant/view/etc.) but **not** the request path, so the simplest correct redirect is `"/demo/login"` (its `safe_return_to/1` defaults to `/ops/mail?tenant_id=northstar`, `page_controller.ex:155-185`) or a `return_to` built from `params["tenant_id"]` for the overview only. This is a demo-only behaviour; record the chosen trade-off (see Open Question 1).
- Unchanged and still correct: the demo dashboard links `/demo/login?return_to=/ops/mail?tenant_id=northstar` (`page_controller_dashboard_test.exs:20-21`, `docs_contract_test.exs:26-32`, `Makefile:84-94`, `guides/run-the-demo.md`) — only the **Preview nav config** changes.
- Demo uses path deps in dev/test and Hex `~>` deps in the baseline lane (`mix.exs:65-78` `hex_deps?()`). In the Hex-baseline lane the published admin 2.6.0 lacks the return seam, so the Preview nav simply points at plain `/ops/mail…`. Do not touch pins; revert transitive lock drift (swoosh, phoenix, boundary). [CITED: project memory `project_reference_baseline_coupling`, `project_demo_app_swoosh_lock_drift`, `project_demo_app_phoenix_advisory`]

### Stories and manifest (D-21)

- Pattern file: `reference/demo_app/storybook/delivery_investigation.story.exs` — `use PhoenixStorybook.Story, :component`, `def container, do: :iframe`, a `template/0` with a `data-theme-owner` wrapper, Review-theme radio fieldset (testid `"{story}-review-theme"`), `variations/0` built from `MailglassDemo.QuickViewScenarios.<builder>(id)`, and `render_case/1` composing **production** components; `def function, do: &__MODULE__.render_case/1`.
- Builders: `reference/persona_spec/quick_view_scenarios.ex` (`delivery/1`, `inbound/1`, `delivery_investigation/1`, `inbound_evidence/1`); it is compiled into the admin **test** build via `elixirc_paths(:test)` including `@persona_spec_dir` (`mix.exs:86-87`), so an ExUnit table can exercise it (`quick_view_projection_test.exs`, Phase 176 table at `:310`).
- Manifest: 31 scenarios; `feedback` entries `fb-health-crowding` (owner_phase "177", `scenario_ids: []`, `status: "pending"`, JSON line ~1253) and `fb-account-context` (~1289). Phase 175 precedent for closing: `status: "automated"`, `scenario_ids` filled, `evidence_pointer: ".planning/phases/175-.../175-AUTOMATION.md#..."`. No script validates `evidence_pointer`; still write `177-AUTOMATION.md` and `177-HEALTH-COMPARISON.md`.
- Health needs **new** story data: `health_issues/7` is private to `OperatorLive`, so scenario JSON must carry the issue maps (`count,label,help,testid,surface,path,stale?`), `activity`, and `states` directly. Do not export `health_issues/7` for the story; a connected ExUnit table asserts the story assigns equal the LiveView-derived population for the same seed (G5).
- Preview chrome/Account-control stories render `SurfaceNav.nav` / `Shell.account_context` (or the new header component) directly; stories prove rendering only (D-21).
- Do **not** add story scenarios to `axe_selection` blindly: Phase 176 kept it at 20 entries and proved other states on connected routes. Health axe (G7) is not in the existing baseline (see Pitfall 8).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Local-path / URL safety | regexes over `/\`, `%2F%2F` | closed-set `return_surface` + `URI.parse`/`URI.query_decoder`/`URI.encode_query` on a **host-configured** path | Open redirect is structurally impossible; no parser-parity surface (D-01) |
| Query merge | string concat of `?`/`&` | `URI.query_decoder |> List.keystore |> URI.encode_query` | Preserves host query order, never duplicates `tenant_id`, encodes `a&view=x` as a value |
| Nav items / pills | new link markup | `Components.nav_link/1`, `nav_pill/1` (`navigate={false}`) | PRIMITIVE-DRIFT-GATE (`scripts/check-conformance.sh:36-87`) |
| Info tooltips | custom popovers | `Components.field_help/1` | Existing, tested, 24x24 meets WCAG 2.5.8 |
| Timestamps | `DateTime` formatting | `Components.timestamp/1` | Existing copy-to-clipboard behaviour used by `health-tooltips.spec.js:102` |
| Account switching URL | new switch logic | `Shell.tenant_switch_path/2` | URL ownership; drops record ids/theme |
| Menu dismissal | new JS hook | existing `data-dismiss-outside` / `data-dismiss-menu` in `priv/static/hooks.js` | UI-SPEC: no hooks change |
| Container reflow | JS resize observers | CSS container queries (`@container`, `@[30rem]:`) | Compiles with the bundled Tailwind 4.1.12 (verified below) |
| Prohibition tests | grep proofs | `phase175_prohibition_contract_test.exs` pattern: closed rendered corpus + regex sets + "detectors have teeth" self-test | Project memory: validate by running, mutation-prove |

**Key insight:** every security-relevant decision in this phase is made by *not accepting* input (closed set, host-configured path, host-owned auth) rather than by validating richer input. Keep it that way; any helper that parses a URL from a query param is a regression.

## Runtime State Inventory

> Not a rename/refactor/migration phase. Omitted per instructions. (Closest analogue: user-visible strings change — "Last retrieved" -> "Not refreshed", "No recent mail activity" -> "No mail activity in this period", "Choose Account" -> "Choose an Account" in header fallbacks only. These live only in source, tests, e2e specs and `docs/design-system.md`; no stored data, service config, OS registration or secret embeds them. Verified by repo-wide grep this session.)

## Common Pitfalls

### Pitfall 1: `max-w-2xl` is 48px
**What goes wrong:** the Health column renders 48px wide (or `max-w-xl` 32px).
**Why it happens:** `assets/css/app.css:110-116` declares `--spacing-xs..3xl` in `@theme`; Tailwind v4 `max-w-*` consults `--spacing-*` before `--container-*`. [VERIFIED: ran `./tailwind-macos-arm64` with the repo's spacing `@theme` and classes `max-w-2xl max-w-3xl max-w-xl`; output `.max-w-2xl { max-width: var(--spacing-2xl); }`, `.max-w-3xl { max-width: var(--spacing-3xl); }`, `.max-w-xl { max-width: var(--spacing-xl); }`; `.max-w-prose` is unaffected (`65ch`).] No current `lib/` file uses these classes, so the trap is latent.
**How to avoid:** `.operator-health-column { max-width: 42rem; }` in `assets/css/app.css` beside `.operator-deliveries-layout` (precedent: `.mg-inbound-replay-dialog {max-width: 42rem}`), or `max-w-[42rem]`. Add an ExUnit assertion that the shipped bundle contains the 42rem rule for the column class, and a Playwright `getBoundingClientRect().width <= 42*16+1` assertion by testid.
**Warning signs:** a column narrower than its first label at any width.

### Pitfall 2: Account control rendered twice -> duplicate ids/testids
**What goes wrong:** `getByTestId("operator-account-switcher")` fails Playwright strict mode (2 matches); `JS.show(to: "#operator-account-switch-status-0")` shows the hidden twin; duplicate `id`s break `aria-labelledby`/`aria-describedby` (axe `duplicate-id-aria`).
**Why it happens:** sidebar (`hidden md:block`) and mobile band (`md:hidden`) are both rendered (`admin_shell.ex:54-71`).
**How to avoid:** pass `layout` into the header component and suffix every id (`operator-account-header-sidebar|mobile`, `...-desc-...`, `operator-account-switch-status-{layout}-{index}`). Keep base `data-testid`s and add `data-layout`; update Playwright through one helper (e.g. `e2e/support/account.js` exporting a locator that adds `:visible`) used by all 15+ call sites. `<details>` open state is per instance; only the visible one is interactive.
**Warning signs:** `surface-nav-sidebar`/`surface-nav-mobile` are already layout-suffixed testids — follow that precedent for the *containers*, and keep per-control testids stable.

### Pitfall 3: Inbound `:unavailable` vs "No Accounts yet"
**What goes wrong:** header says "No Accounts yet" while the page says "Account options unavailable".
**How to avoid:** add a `tenant_state` (or `options_unavailable?`) attr to `Shell.shell/1`; render "No Accounts yet" only for `:none`; for `:unavailable` render the neutral eyebrow plus the selected label if any, else "Choose an Account" static text without a menu.

### Pitfall 4: Direct-entry URLs must stay byte-identical
**What goes wrong:** appending `?` or a trailing `&` when the context is `nil` breaks `assert_patch(view, base_path <> "?width=375")` (`preview_live_test.exs:790`), the theme redirect assertions (`:278, :723, :797, :862`) and the nav hrefs at `:363-365`.
**How to avoid:** `query_pairs(nil) == []` and a builder that returns the original string when the list is empty; golden-test the no-context outputs before editing.

### Pitfall 5: `Theme.strip_theme_query/1` and `append_query_without_theme/2` already keep unknown params
**What goes wrong (opposite direction):** assuming the theme round trip needs new code and widening ThemeController to "know" the return params.
**How to avoid:** the round trip keeps `return_*` automatically (`theme.ex:80-97`, `preview_live.ex:822-838`); only the sanitizer boundary changes (D-08). Prove with a test (T10), do not add code.

### Pitfall 6: HEEx apostrophes in assertions
**What goes wrong:** `html =~ "couldn't be loaded"` passes for static template text but fails for interpolated strings (`&#39;`).
**How to avoid:** keep UI-SPEC microcopy as static template text, or assert through `Floki.text/1` (decodes entities). Existing suppression copy uses `’` (`phase175` test) — do not mix apostrophe styles within one component without a decision.

### Pitfall 7: Bundle rebuild and the token-parity landmine
**What goes wrong:** `priv/static/app.css` is committed and canonical; CI runs `git diff --exit-code`; a rebuild can emit raw-inline daisyUI theme blocks that break `TokenParityTest`. [CITED: project memory `project_token_parity_bundle_landmine`, `project_admin_ui_phase_verification_gaps`]
**Measured today:** at `0e0fb29a`, `mix mailglass_admin.assets.build` is a **no-op** (`git status --short priv/static` empty after build), so the baseline reproduces; the landmine did not fire. `npm run test:operator-browser` runs `mix mailglass_admin.assets.build` first (`package.json` script), so *running Playwright rebuilds the bundle*.
**How to avoid:** after any class change run build -> `TokenParityTest` + `AssetsTest` -> if the theme blocks differ, restore them from the committed bundle (`git checkout -- mailglass_admin/priv/static/app.css` then re-apply only new-utility hunks) -> commit the bundle in the same change. After every Playwright run, `git status --short mailglass_admin/priv/static` and restore if dirty (Phase 176 plans used the guard `git diff --quiet -- mailglass_admin/priv/static/app.css && ... || git checkout`). Never construct class names dynamically; `@[30rem]:`/`@[56rem]:` variants must be static literals.
**Container-query compile proof:** [VERIFIED: compiled `@container @[30rem]:flex-row @[30rem]:gap-xl @[56rem]:grid-cols-[minmax(0,42rem)_16rem]` with the bundled binary -> `.\@container{container-type:inline-size}`, `@container (width >= 30rem){...}`, `@container (width >= 56rem){...}`].

### Pitfall 8: Health is not in the axe baseline
`e2e/axe-baseline.spec.js` scans `SURFACES = ["deliveries", "inbound", "preview"]` x `["light","dark","system"]` (`:37-38`) and `docs/axe-baseline.json`; the overview/Health route is **not** one of the 9 cells. G7 ("no new axe violations") therefore needs a *new* scan of `/ops/mail?tenant_id=browser-tenant` (and the partial/unavailable scenarios) in the Phase 177 spec using `AxeBuilder` with `["wcag2a","wcag2aa","wcag21a","wcag21aa","wcag22aa"]` (pattern: `e2e/phase176-filters.spec.js:1-6`), asserting zero violations, rather than "no regression vs baseline". The `preview` baseline cells may shift (Preview chrome changes): regenerate with `PERSIST_AXE_BASELINE=1` only if the change is a deliberate improvement, never to hide a regression. [CITED: spec header comment, `e2e/axe-baseline.spec.js:1-32`]

### Pitfall 9: Line-number-keyed test exceptions (does NOT apply to admin tests)
The registry check `scripts/check_test_exceptions.sh` (run by `test/scripts/test_exceptions_contract_test.exs`) compares `config/test_exceptions.exs` against `grep -REn '^[[:space:]]*@tag :(skip|flaky)|Process\.sleep\(|pg_sleep\(' test/mailglass mailglass_inbound/test` [VERIFIED: `scripts/check_test_exceptions.sh:19`]. It scans **core and inbound tests only**; `mailglass_admin/test` (including the lone `@tag :skip` at `voice_test.exs:114`) is outside it, and `config/test_exceptions.exs` has no admin or voice entry (grep returned nothing). Phase 177 edits only `mailglass_admin/`, `reference/` and `.planning/`, so this coupling cannot fire. The CONTEXT/UI-SPEC note is correct as a general landmine [CITED: project memory `project_test_exceptions_line_number_coupling`] but is a non-issue here. Still prefer new test files over growing `voice_test.exs` (edit its line-65 subtitle assertion in place). If a later task does touch `test/mailglass` or `mailglass_inbound/test`, add tests below any registered skip or in new files and run `bash scripts/check_test_exceptions.sh`.

### Pitfall 10: Preview has two topbar users
`preview_live.ex:317-325` also uses `admin-shell-actions` (theme picker, `ml-auto`). Removing the Account rules from the `@media (max-width:767px)` block must keep the Appearance-fieldset placement rules (`app.css:703-719`) working for Preview, or the theme picker regresses on narrow Preview.

### Pitfall 11: `refute` on `role="status"` in Health
`Components.timestamp`/toast regions elsewhere legitimately use `role="status"` (e.g. `operator-results-status`, switch status). The "no `role=status` on persistent notices" check must be scoped to `[data-testid^="operator-health-"]` notices, not the whole page.

### Pitfall 12: Mix build-lock stdout flake
Tests that shell to `mix run` and byte-compare stdout can see "Waiting for lock on the build directory" under full-suite contention. Phase 177 adds none; do not add any. [CITED: project memory `project_mix_build_lock_stdout_flake`]

## Code Examples

### Reading the closed-set surface from the shell (operator side)
```elixir
# Source: derived from shell.ex:156-170 attr(:active, :atom, values: [:overview, :deliveries, :inbound]) — local sketch
@surface_for %{overview: "overview", deliveries: "deliveries", inbound: "inbound"}

defp preview_href(assigns) do
  with true <- is_binary(assigns.selected_tenant_id) and assigns.selected_tenant_id != "",
       true <- ReturnContext.local_path?(assigns.preview_path) do
    ReturnContext.append(assigns.preview_path, [
      {"return_surface", @surface_for[assigns.active]},
      {"return_tenant_id", assigns.selected_tenant_id}
    ])
  else
    _ -> assigns.preview_path
  end
end
```

### Denying clause for the arrival-authorization proof
```elixir
# Source: test/support/endpoint_case.ex:368-380 (existing clauses); new clause goes BEFORE the generic `%{actor: actor}` clause
def authorize(:operator_access, %{params: %{"tenant_id" => "forbidden-account"}}) do
  {:error, :unauthorized, %{message: "Operator access denied.", to: "/login"}}
end
```

### Population fingerprint golden (capture BEFORE editing HealthOverview)
```elixir
# Pattern: operator_live_test.exs:4622-4750 render a seeded overview; reduce to {testid, count, href}
defp fingerprint(html) do
  html
  |> Floki.parse_document!()
  |> Floki.find("[data-testid='operator-overview-health'] [data-testid^='operator-health-deliveries-'],
                 [data-testid^='operator-health-inbound-'], [data-testid^='operator-overview-health-']")
  |> ...  # extract data-testid, count text, link href; compare to a committed literal list
end
```
(Use the seeded fixtures `OperatorFixtures.seed_phase169_scenario!/0`, `seed_phase169_health_partial!/0`, `insert_support_summary_fixture!` already used by the Health tests. The literal list must be captured on the **pre-refactor** commit; add a swap-counts mutation test proving order is count-independent.)

### Playwright login/seed helpers (reuse, do not reinvent)
```js
// Source: e2e/phase176-filters.spec.js:8-20, e2e/health-tooltips.spec.js:9-12
await page.request.get("/ops/browser-reset?scenario=phase169-health-partial");
await page.goto(`/ops/browser-login?tenant_id=browser-tenant&return_to=${encodeURIComponent("/ops/mail?tenant_id=browser-tenant")}`);
```
Seed scenarios available at `/ops/browser-reset` (`endpoint_case.ex:140-190`): default, `phase170-package-unavailable`, `phase170-read-unavailable`, `sole`, `accounts` (persona cohort), `phase169-exact`, `phase169-replay-{zero,one,many}`, `phase169-timeline-101`, `phase169-suppression`, `phase169-health-partial`, `phase169-support-empty`. Reader faults: `POST /ops/browser-mutate?action=arm-known-read-failure&operation=<failed_ingest|orphan_backlog|...>` with a CSRF header (`phase169-journey.spec.js:38-47`).

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Viewport breakpoints for layout (`lg:grid-cols-...`) | Container queries (`@container`, `@[30rem]:`) native in Tailwind v4 | Tailwind 4.0 | Health must follow the content column, not viewport; sidebar eats 240px at tablet widths (same reason `.operator-deliveries-layout` exists) |
| Static host-wrapped login links for Preview nav | Closed-set derived return href | this phase | demo now proves dynamic return; Northstar wrappers no longer substitute for proof (REQUIREMENTS "Navigation decision") |
| `String.starts_with?` path prefix | segment-boundary check | this phase (D-08) | closes sibling-mount confusion |

**Deprecated/outdated:** CONTEXT line refs `theme_controller.ex:11-19` (actual `:52-60`) and the research docs' operator-side membership check (superseded by D-05). RETURN-DESTINATION.md's "Previews use sample data" copy is superseded by D-12.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Demo logged-out deny should redirect to `/demo/login` (default return) because the on_mount auth context lacks the request path | Code Grounding / Demo | A logged-out user clicking "Back to Inbound" lands on Health instead of Inbound; demo-only. **RESOLVED (REFUTED, plan 177-10):** the plain `/demo/login` form contradicts locked D-07. The auth context carries `socket`, and `Phoenix.LiveView.get_connect_info(socket, :uri)` returns the full request path and query on the disconnected render (verified in LV 1.1.33 and 1.2.13 `conn_connect_info/2`), which is the only render a logged-out request reaches. The demo deny uses `to: "/demo/login?return_to=<URL-encoded path+query>"`, falling back to `/ops/mail` plus the `tenant_id`/`view` params when the URI is unavailable, and `safe_return_to/1` validates it. |
| A2 | Rejecting `.`/`..`/`%2e` segments in `sanitized_return_to` is worthwhile hardening beyond D-08's stated scope | Code Grounding / ThemeController | Over-rejection could break a legitimate `return_to`; same-origin only, so low severity either way. **RESOLVED (adopted, plan 177-01 Task 3):** rejected, with regression rows; every existing valid case keeps passing. |
| A3 | Operator minting should skip (not append) when `preview_path` is not a local absolute path (e.g. a cross-origin Preview host) | Pattern 1 | Appending would leak the Account id to another origin's logs; D-01 is silent on this, research doc §2.2 recommends skipping. **RESOLVED (adopted, plan 177-01):** `ReturnContext.operator_preview_href/3` returns a non-local `preview_path` unchanged. |
| A4 | The comparison spike can run against the demo Storybook via `reference/demo_app/assets` Playwright (`mix ecto.setup && mix phx.server`) without Docker | Validation / comparison | If the demo cannot boot locally, geometry measurement needs the compose path (`make demo`); not executed this session. **RESOLVED (avoided, plan 177-08):** the A/B spike runs on the real operator browser route (plan 177-08), so it does not depend on the demo boot; only the advisory story inventory (plan 177-09) needs the demo. |
| A5 | Container-query geometry (288..1152) behaves as the UI-SPEC predicts; only compile output was verified, not rendered geometry | Pitfall 7 | Gates G1-G4 are exactly what the spike measures; a wrong prediction changes the winner, not the plan shape. **RESOLVED (measured, plans 177-04 and 177-08):** column width and overflow are asserted on the real route in 177-04; the full G1-G7 suite and the real-width backstop at viewport 768 are measured and recorded in 177-08. |
| A6 | Adding `navigation:` to the two alt test-router mounts does not disturb existing tests | Test router | A test counting nav links on alt mounts would shift; grep found none. **RESOLVED (verified by test, plan 177-03 Task 2):** the alt-mount users (`admin_asset_url_test.exs`, `assets_test.exs`) are rerun unchanged. |
| A7 | Idle Playwright `webServer` reuse (`reuseExistingServer: !process.env.CI`) means a stale local server can mask new code | Validation | False green locally; kill port 4101 before final runs. **RESOLVED (mitigated, plans 177-07 and 177-11):** port 4101 is cleared before final browser runs. |

## Open Questions (RESOLVED)

1. **Demo logged-out redirect target (D-07).**
   - What we know: `Operator.Mount.deny/4` honours `details[:to]`; `DemoWeb.AdminAuth` returns no `:to`; the auth context carries `params` but not the path.
   - What's unclear: whether the planner wants per-surface `return_to` (needs the path, e.g. via a small `/ops` pipeline plug as RETURN-DESTINATION §2.7 suggested) or the simple `to: "/demo/login"` default.
   - Recommendation: ship `to: "/demo/login"` (one clause, no router plug; `safe_return_to/1` supplies a valid default) and cover with a demo ExUnit test; escalate nothing (reversible).
   - **RESOLVED:** the recommendation above is superseded by locked D-07, which requires the `to: "/demo/login?return_to=…"` form. Plan 177-10 builds `return_to` inside the demo adapter, with no router plug: it reads the request path and query from `Phoenix.LiveView.get_connect_info(socket, :uri)` on the disconnected render (the auth context does carry `socket`). If that is nil, it uses `/ops/mail` with the `tenant_id`/`view` arrival params. The value is URL-encoded, and the existing `safe_return_to/1` validates it. A demo ExUnit test proves that a logged-out Fjordline Deliveries return lands on Fjordline Deliveries after login.
2. **Account-header testids under duplication.** Suffix the container testids and add a visible-only locator helper, or give one copy a different testid? Recommendation: keep base testids on both, add `data-layout`, centralise `:visible` filtering in one e2e helper (Pitfall 2).
   - **RESOLVED:** adopted. Base testids stay on both copies and gain `data-layout`, and ids are layout-suffixed (plan 177-06). `e2e/support/account.cjs` is the only visible-only locator helper, and plan 177-07 migrates every spec onto it.
3. **Where the Health population golden lives.** `operator_live_test.exs` is ~5,900 lines and has no `@tag :skip`; a new file `health_population_test.exs` avoids any line-keyed coupling. Recommendation: new file.
   - **RESOLVED:** adopted. Plan 177-02 creates `mailglass_admin/test/mailglass_admin/health_population_test.exs` before any Health markup change.
4. **Storybook-axe lane for new stories.** It needs the isolated Demo service (`STORYBOOK_BASE_URL`); advisory per Phase 176 precedent. Recommendation: rely on merge-blocking ExUnit tables + demo e2e inventory spec (Phase 176 plan 08 pattern); do not extend `axe_selection` unless the plan also runs the producer.
   - **RESOLVED:** adopted. Plan 177-09 keeps the merge-blocking ExUnit render tables and adds an advisory demo inventory spec (non-blocking, exit status recorded). `axe_selection` stays at 20 entries.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir/OTP (asdf) | all ExUnit | yes (with env override) | Elixir 1.18.4 / OTP 27 via `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27` | bare `mix` fails with misleading `corrupt atom table` |
| PostgreSQL | admin test DB | yes | `/tmp:5432 - accepting connections` | — |
| Node | Playwright, scratch scripts | yes | v26.10.0 | — |
| Playwright + Chromium | operator browser lane | yes | 1.59.1; chromium-1200..1228 cached in `~/Library/Caches/ms-playwright` | — |
| `@axe-core/playwright` | G7 | yes | in `mailglass_admin/node_modules/@axe-core` | — |
| Tailwind standalone binary | bundle build | yes | `mailglass_admin/tailwind-macos-arm64` v4.1.12 | — |
| Docker | demo `make demo` / evidence script | yes | 29.5.2 | local `mix phx.server` in `reference/demo_app` |
| Demo app deps | demo e2e / Storybook | present (`_build/dev`, `_build/test`) | LV 1.1.33 | — |

Executed this session: `mix test test/mailglass_admin/router_test.exs test/mailglass_admin/operator/shell_test.exs --seed 0` -> **46 tests, 0 failures** (0.3s); `mix mailglass_admin.assets.build` -> exit clean, `priv/static` unchanged; `bash scripts/check-conformance.sh` -> `OK: design-system conformance clean.`

**Missing dependencies with no fallback:** none.
**Missing dependencies with fallback:** none.

## Validation Architecture

> `workflow.nyquist_validation` is `true` in `.planning/config.json`. Zero owner UAT (D-52): every row closes `source: automated`.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit + Phoenix.LiveViewTest (LV 1.2.13) + Floki — merge-blocking; Playwright 1.59.1 operator browser gate — advisory (project convention, Phase 176) |
| Config file | `mailglass_admin/test/test_helper.exs` (`ExUnit.start(exclude: [:skip])`); `mailglass_admin/playwright.config.cjs` (webServer `MIX_ENV=test mix run --no-halt -e "MailglassAdmin.TestSupport.OperatorBrowserServer.run!()"`, port 4101, `reuseExistingServer: !process.env.CI`) |
| Quick run command | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix test test/mailglass_admin/operator/shell_test.exs test/mailglass_admin/preview/return_context_test.exs test/mailglass_admin/phase177_*_test.exs --seed 0` |
| Full suite command | `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 mix verify.support_contract.admin` (alias = `test --warnings-as-errors`, i.e. the **entire** admin suite — `mix.exs:213-215`; the memory note about a 9-file allow-list is stale) |
| Merge-blocking auxiliary | `mix format --check-formatted`, `mix credo --strict`, `mix compile --no-optional-deps --warnings-as-errors`, `bash scripts/check-conformance.sh`, `bash scripts/check_test_exceptions.sh` (repo root; only relevant if `test/mailglass` or `mailglass_inbound/test` are touched) |

A new `*_test.exs` file under `mailglass_admin/test/` is picked up by `mix test` automatically and is therefore in `verify.support_contract.admin`; no alias edit is required.

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| UXF-10 | Validator table: unknown surface, list/map params, blank/>255-byte/non-UTF-8/control-char id, non-local or missing configured path, injection values (`a&view=x`, `#f`, `"><svg>`, U+202E), 10k-char surface; replace-in-place `tenant_id`; deterministic seeded loop (no new dep) | unit | `... mix test test/mailglass_admin/preview/return_context_test.exs --seed 0` | ❌ Wave 0 |
| UXF-10 | Session maps unchanged (`__preview_session__/2`, `__operator_session__/2`), no `return_*` key, no Account assigns on Preview | unit | `... mix test test/mailglass_admin/router_test.exs test/mailglass_admin/phase177_prohibition_contract_test.exs --seed 0` | ✅ router_test / ❌ new file |
| UXF-10 | Operator -> Preview href carries `return_surface`/`return_tenant_id` only when an Account is selected, per surface (overview, deliveries, inbound); no top-level `tenant_id`; non-local `preview_path` untouched | connected | `... mix test test/mailglass_admin/phase177_return_navigation_test.exs --only phase177 --seed 0` | ❌ Wave 0 |
| UXF-10 | Custom mounts: `/alt/dev/console` <-> `/secure/console` (test router `navigation:` added) and `/dev/mail` <-> `/ops/mail`; internal patches stay under the Preview mount | connected | same file | ❌ Wave 0 |
| UXF-10 | Context survives: index redirect, scenario patch, width patch (`render_click(view,"set_device",...)` + `assert_patch`), theme round-trip (`render_click(view,"set_theme",...)` -> `assert_redirect` -> follow `/theme/dark?return_to=` -> `live/2`) | connected | same file | ❌ Wave 0 |
| UXF-10 | Direct entry and tampered (`return_surface=evil`, non-local configured path, list-valued params) render identical chrome: no back link, static host paths, no echo | connected | same file | ❌ Wave 0 |
| UXF-10 | Unauthorized target not honored: `live(conn, "/ops/mail?tenant_id=forbidden-account")` -> `{:error, {:redirect, %{to: "/login"}}}`; also for `/secure/console` and `/ops/mail/inbound`; destination reads nothing | connected | same file + `TestOperatorAuth` clause | ❌ Wave 0 (+ edit `endpoint_case.ex`) |
| UXF-10 | Preview frame HTML identical with/without return params (independent rendering) | connected | same file | ❌ Wave 0 |
| UXF-10 | ThemeController segment boundary (`/ops/mailx`, `/ops/mail//x`, `/ops/mail\x`, dot segments, `/dev/mail/x` from `/ops/mail`), existing valid cases still redirect | controller | `... mix test test/mailglass_admin/router_test.exs --seed 0` | ✅ (add cases) |
| UXF-10 | Browser Back from operator returns to Preview; Fjordline round trip (not static Northstar) | e2e (advisory) | `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 npm --prefix mailglass_admin run test:operator-browser -- phase177-return-navigation.spec.js` ; demo: `cd reference/demo_app/assets && npm run test:e2e -- phase177-return.spec.js` | ❌ Wave 0 |
| UXF-09 | Header variants: 0 Accounts ("No Accounts yet", no `<details>`), 1 (static, no chevron/option), 2+ with/without selection ("Choose an Account", `<details>`, 44px options), Inbound `:unavailable` not "No Accounts yet"; long/Unicode label wraps | component | `... mix test test/mailglass_admin/operator/shell_test.exs test/mailglass_admin/phase177_account_scope_test.exs --seed 0` | ✅ shell_test (extend; below existing tests) / ❌ new |
| UXF-09 | Group semantics: `role="group"` labelled by header; items exactly {Health, Deliveries, Inbound?}; Preview outside; `aria-describedby` omits Inbound when unavailable; unique ids per layout | component | same | ❌ Wave 0 |
| UXF-09 | Preview: no `[data-testid^="operator-account"]`, no `<details>/<select>` Account picker, no canary `zz-canary-7f3` outside `href`; static "Scoped to an Account"; caption "Not tied to an Account"; subtitle equality | contract (mutation-proven) | `... mix test test/mailglass_admin/phase177_prohibition_contract_test.exs --trace --seed 0` | ❌ Wave 0 |
| UXF-09 | Account control visible and topbar not wrapped at 320/375/768/1280/1440; menu full band width below `md` | e2e (advisory) | `... test:operator-browser -- phase177-account.spec.js` | ❌ Wave 0 |
| OUTUX-06 | Population fingerprint `{testid,count,href}` byte-identical pre/post (captured before refactor); order independent of count (swapped-count mutation); every issue keeps its deep link; stale rows tagged; inbound absent -> no inbound rows | LiveView golden | `... mix test test/mailglass_admin/health_population_test.exs --seed 0` | ❌ Wave 0 (**commit before Health edits**) |
| OUTUX-06 | Structure: observation group (`role=group`, period + timestamp + Refresh), activity after status, no `order-` class, no `role="status"` on notices, no `mono`/`text-heading` count, `min-h-11` on issue links, unavailable/stale never "No issues found" | component/LiveView | `... mix test test/mailglass_admin/operator/health_overview_test.exs test/mailglass_admin/operator_live_test.exs --seed 0` | ❌ Wave 0 / ✅ updated |
| OUTUX-06 | Column bundle rule (42rem) present in `priv/static/app.css`; docs amended | unit | `... mix test test/mailglass_admin/token_parity_test.exs test/mailglass_admin/assets_test.exs test/mailglass_admin/phase177_*_test.exs --seed 0` | ✅ + ❌ |
| OUTUX-06 | Geometry gates G1-G4,G6,G7 at 320/390/768/1024/1280/1440 on normal, `phase169-health-partial`, armed reader fault; `phase169-journey.spec.js` `metricColumns` replaced; deep link landing for every issue row; Refresh focus retention | e2e (advisory) | `... test:operator-browser -- phase169-journey.spec.js health-tooltips.spec.js phase177-health.spec.js` | ✅ edit / ❌ new |
| OUTUX-06 | A vs B comparison recorded with numbers and winner | artifact + throwaway spec | spec run once from scratchpad against demo Storybook; result in `177-HEALTH-COMPARISON.md` | ❌ Wave 0 |
| D-21 | Retained scenarios render through production components; manifest `fb-health-crowding` and `fb-account-context` carry `scenario_ids` + dispositions | ExUnit table | `... mix test test/mailglass_admin/quick_view_projection_test.exs --only phase177 --seed 0` | ✅ (extend, new `@tag :phase177` test) |

### Sampling Rate

- **Per task commit:** the touched file's ExUnit command above plus `--only phase177 --trace` (tag all new Phase 177 tests `@moduletag :phase177`).
- **Per wave merge:** quick-run set + `mix format --check-formatted` + `mix credo --strict` + `bash scripts/check-conformance.sh` + `mix compile --no-optional-deps --warnings-as-errors`; after any class/CSS change: rebuild -> `token_parity_test.exs assets_test.exs` -> `git diff --exit-code -- mailglass_admin/priv/static/`.
- **Phase gate (before `/gsd-verify-work`):** full `mix verify.support_contract.admin` green (`--seed 0` baseline is zero failures [CITED: project memory `project_full_suite_baseline_is_zero`]); `bash scripts/check_test_exceptions.sh` (cheap sanity); Playwright specs (operator gate vs LV 1.2.13, demo e2e vs LV 1.1.33); `git status --short mailglass_admin/priv/static reference/demo_app/mix.lock reference/demo_app/mix.exs` clean.

### Wave 0 Gaps

- [ ] `mailglass_admin/test/mailglass_admin/health_population_test.exs` — fingerprint golden, **captured on the pre-refactor commit** (OUTUX-06 / G5)
- [ ] `mailglass_admin/test/mailglass_admin/preview/return_context_test.exs` — pure validator table + seeded loop (UXF-10)
- [ ] `mailglass_admin/test/mailglass_admin/phase177_return_navigation_test.exs` — connected: minting, custom mounts, persistence, fallback, unauthorized arrival, independent rendering (UXF-10)
- [ ] `mailglass_admin/test/mailglass_admin/phase177_account_scope_test.exs` — header variants, group semantics, unique ids, Inbound `:unavailable` (UXF-09)
- [ ] `mailglass_admin/test/mailglass_admin/operator/health_overview_test.exs` — component structure/copy states (OUTUX-06)
- [ ] `mailglass_admin/test/mailglass_admin/phase177_prohibition_contract_test.exs` — P1-P9 + Health prohibitions with "detectors have teeth" self-test; each rule additionally proven red by a recorded temporary source mutation (Phase 176 convention, `phase176_prohibition_contract_test.exs:24`)
- [ ] `mailglass_admin/test/support/endpoint_case.ex` edits: denying `TestOperatorAuth` clause (before line 377); `navigation:` on `/alt/dev/console` and `/secure/console`
- [ ] `mailglass_admin/e2e/phase177-{return-navigation,account,health}.spec.js` (+ shared `e2e/support` account locator helper) and edits to `phase169-journey.spec.js`, `flows.spec.js`, `structural.spec.js`, `inbound-layout.spec.js`, `phase170-journey.spec.js`, `phase175-inbound.spec.js`
- [ ] `reference/demo_app/assets/e2e/phase177-return.spec.js` (advisory; LV 1.1.33) and a demo ExUnit test for the `AdminAuth` deny `to:`
- [ ] Story files `reference/demo_app/storybook/operator/health.story.exs`, Account-control and Preview-chrome stories; manifest entries; `quick_view_scenarios.ex` builders
- [ ] `177-HEALTH-COMPARISON.md`, `177-AUTOMATION.md` (evidence pointers for the two feedback entries)

Verification of prohibition rules is by **rendered-corpus regex + closed-state enumeration**, not by grep of source (project memory `feedback_validate_credo_by_running_it`). Use `render_component/2` (as `phase175` does) for components and `live/2` + `render/1` for Preview/operator pages; `visible_text/1` = `Floki.parse_fragment! |> Floki.filter_out("script") |> Floki.text(sep: " ")`.

## Security Domain

`security_enforcement` is absent from `.planning/config.json` (treated as enabled).

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no (host-owned) | unchanged; arrival re-runs `Operator.Mount` -> host `Auth.authorize(:operator_access, ...)` |
| V3 Session Management | yes (negative) | Do **not** widen `__preview_session__/2`; no cookie/session/localStorage carrier for the Account (D-03); asserted by test |
| V4 Access Control | yes | Destination grants no authority (D-05): host auth + `Tenancy.scope`; test via `TestOperatorAuth` denying clause; known gap (patch switch skips `on_mount`) stays documented, not fixed |
| V5 Input Validation | yes | Closed-set `return_surface`; `return_tenant_id` opaque, UTF-8, 1-255 bytes, no control chars; only ever a percent-encoded query *value* in a host-configured path; HEEx attribute escaping |
| V6 Cryptography | no | none (no tokens/signing) |
| V7/V8 Logging, data protection | yes (negative) | never log/emit `return_tenant_id`; no PII in telemetry (CLAUDE.md); referrer exposure: operator URLs already carry `tenant_id`, `put_secure_browser_headers` sets `strict-origin-when-cross-origin` (RETURN-DESTINATION §4.8: verify header in the demo endpoint) |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Open redirect via return parameter (CWE-601) | Tampering | Preview never accepts a URL; derive from host-configured `navigation` + closed set (D-01); `ThemeController` segment-boundary sanitizer (D-08) |
| Parameter injection into the derived href (`a&view=x`, `#frag`) | Tampering | `URI.encode_query` value encoding; replace-in-place `tenant_id`; table-tested |
| Spoofable identity echoed into trusted chrome | Spoofing | never render `return_tenant_id` as text; canary test (P2) |
| Foreign Account deep link | Elevation / Info disclosure | host `Auth.authorize` on arrival; mailglass renders no Account-existence oracle (no mailglass copy on deny) |
| Atom exhaustion via `return_surface` | DoS | string compare against closed list, never `String.to_atom` (test with 10k-char value) |
| Session whitelist creep | Elevation | key-set equality test (existing `router_test.exs` assertions + `refute return_*`) |
| Stored/reflected XSS in Account label | Tampering | labels are HEEx-escaped; story/ExUnit with `<script>`/RTL/emoji label (`Fjordline` long-Unicode case) |
| Cross-origin leak of `tenant_id` | Info disclosure | skip minting when `preview_path` is not a local absolute path (A3) |

## Sources

### Primary (HIGH confidence)
- Repo files read this session (paths and line ranges inline above): `operator/health_overview.ex`, `operator_live.ex`, `inbound_live.ex`, `operator/shell.ex`, `surface_nav.ex`, `admin_shell.ex`, `preview_live.ex`, `preview/sidebar.ex`, `router.ex`, `controllers/theme_controller.ex`, `theme.ex`, `mount_path.ex`, `mount_path_hook.ex`, `operator/mount.ex`, `auth.ex`, `components.ex` (nav primitives), `assets/css/app.css`, `scripts/check-conformance.sh`, `mix.exs`, `package.json`, `playwright.config.cjs`, `test/support/endpoint_case.ex`, `test/mailglass_admin/{router,shell,operator_live,preview_live,voice,persona_cohort,token_parity,phase175_prohibition_contract,quick_view_projection}_test.exs`, `e2e/*.spec.js`, `reference/demo_app/{lib,storybook,assets/e2e,mix.exs}`, `reference/persona_spec/quick_view_scenarios.{ex,json}`, `mailglass_admin/docs/design-system.md`.
- `deps/phoenix_live_view/lib/phoenix_live_view/{route.ex,channel.ex,utils.ex,static.ex}` (admin 1.2.13) and `reference/demo_app/deps/phoenix_live_view/lib/phoenix_live_view/route.ex` (demo 1.1.33): on_mount `params` includes query string.
- Executed commands: `mix test` (46 pass), `mix mailglass_admin.assets.build` (no diff), `bash scripts/check-conformance.sh` (clean), bundled Tailwind compile experiments (scratchpad `…/scratchpad/tw/`).
- `.planning/research/phase-177/{RETURN-DESTINATION,ACCOUNT-CONTROL,HEALTH-COMPOSITION}.md`, `177-CONTEXT.md`, `177-UI-SPEC.md`, `176-VALIDATION.md`, `176-08-SUMMARY.md`.

### Secondary (MEDIUM confidence)
- Project memory index entries (token-parity landmine, test_exceptions line coupling (not applicable to admin tests), baseline coupling, mix build-lock flake, full-suite baseline) — recorded by the maintainer in prior sessions; behaviours re-checked where cheap (bundle rebuild is currently a no-op; the test-exception registry scans only core and inbound tests, so the coupling does not reach admin tests).

### Tertiary (LOW confidence)
- None used for load-bearing claims.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no additions; versions read from build output and mix files.
- Architecture / code map: HIGH — every location read this session; stale CONTEXT line refs corrected.
- Pitfalls: HIGH for 1 (measured), 2 (structural), 3, 4, 5, 7, 8, 9; MEDIUM for 10-12 (inferred from reading).
- Demo behaviours (AdminAuth deny, Hex-baseline lane, local demo boot): MEDIUM — read, not executed.
- Playwright geometry/comparison: MEDIUM — commands verified to exist, no spec run this session.

**Research date:** 2026-10-28
**Valid until:** 2026-11-27 (stable stack; invalidated earlier by any change to `app.css` `@theme`, `Operator.Shell`, or `PreviewLive` URL builders)
