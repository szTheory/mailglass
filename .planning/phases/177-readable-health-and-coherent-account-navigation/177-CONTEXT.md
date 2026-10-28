# Phase 177: Readable Health and Coherent Account Navigation - Context

**Gathered:** 2026-10-28 (assumptions mode, research fan-out)
**Status:** Ready for planning

<domain>
## Phase Boundary

Operators can scan actionable Health evidence, understand the scope of the compact Account control, and return from Preview to the originating Account through a safe host-supported navigation seam. Requirements: OUTUX-06, UXF-09, UXF-10 (ROADMAP.md Phase 177).

In scope: Health composition (presentation only), the Account control's placement/scope signalling on operator surfaces and Preview, a navigation-only Preview→Account return, retained production-component stories, and the connected/contract/browser proof.

Out of scope: changing Health populations or `health_issues/7` semantics; Account-scoped Preview rendering; any global current-Account state; widening Preview auth/session whitelists; Preview authoring repairs (Phase 178).
</domain>

<decisions>
## Implementation Decisions

### Preview return seam (UXF-10)
- **D-01: Preview never accepts a URL.** The operator page appends two params to its configured `preview_path` link only when an Account is selected: `return_surface` ∈ {`overview`, `deliveries`, `inbound`} (closed set) and `return_tenant_id` (opaque). Preview reconstructs the destination from the host's existing `navigation[:overview_path | :deliveries_path | :inbound_path]` plus `tenant_id` (and `view=deliveries` where the existing path builder uses it). Selecting from a closed set makes open redirect structurally impossible. Rejected: a `return_to` path param validated against configured paths (larger attack surface; needs WHATWG-vs-`URI.parse` parity for `/\`, `%2F%2F`, tab/newline tricks).
- **D-02: Validation drops silently.** Both params are dropped (direct-entry fallback) if the surface is not in the set, the configured nav path is missing or not a local absolute path, or the id is blank, >255 bytes, not valid UTF-8, or contains control characters. Pure, unit-tested validator module; no error UI.
- **D-03: No public API change.** No new router option or callback; params are internal and undocumented. `__preview_session__/2` and `__operator_session__/2` stay byte-identical (asserted by test). No session, assign-sharing or client storage carrier. Docs note only that Preview `:navigation` paths should point directly at the operator surfaces.
- **D-04: The context is threaded through every Preview URL builder:** index redirect to first scenario (`first_scenario_path`), sidebar scenario patches (`preview/sidebar.ex` `scenario_path`), width patch (`build_capture_url`), and the theme round-trip. Preview rendering never depends on the params. The return is a plain full-page `href` (cross-live_session, `navigate={false}`), so Browser Back returns to Preview.
- **D-05: Destination grants no authority.** Authorization of the target Account stays with the host's existing seam: arrival re-runs `Operator.Mount` → `Auth.authorize(:operator_access, %{params: ...})`, and reads stay scoped through `Tenancy.scope`. Tests add a denying clause to `MailglassAdmin.TestOperatorAuth` for a mismatched `params["tenant_id"]` to prove unauthorized targets are not honored. Rejected: mailglass-side allow-list from `list_tenants(actor)` (activity-derived; would silently break deep links to activity-free Accounts for every adopter — reversible later if wanted).
- **D-06: Copy.** Return affordance names the surface, never the Account: "← Back to Health" / "← Back to Deliveries" / "← Back to Inbound". With validated context, Preview's Health/Deliveries/Inbound nav items carry the same `tenant_id`. Direct entry/tampered: no back link, existing static nav, no error.
- **D-07: Demo exercises dynamic return.** `reference/demo_app` Preview `navigation` points at `/ops/mail`, `/ops/mail?view=deliveries`, `/ops/mail/inbound` (replacing the static Northstar `/demo/login?return_to=…` wrappers). Logged-out direct entry keeps working via `MailglassDemoWeb.AdminAuth` deny with `to: "/demo/login?return_to=…"` (existing `deny/4` `details[:to]`). Respect reference-baseline coupling rules (no pin changes; revert transitive lock drift).
- **D-08: Folded fix.** `ThemeController.sanitized_return_to/2` uses a bare `String.starts_with?` prefix match (accepts `/ops/mailx`, sibling mounts). Replace with a segment-boundary check and reject backslashes/`//`; add regression tests.

### Compact Account control (UXF-09)
- **D-09: Placement = scope group header.** The Account control becomes the header of a bordered nav group containing only Health, Deliveries, Inbound. Preview moves below the group after a divider, captioned "Not tied to an Account". Topbar keeps only global controls (theme). Below `md`, the control renders full-width at the top of the always-visible `mobile_nav` band with the scoped pills inside the group, preserving 168 D-01 (Account visible at every width) and fixing topbar wrap at 320/375.
- **D-10: No choice → no picker.** With zero or one Account the header is plain text (no chevron, no one-item menu). Multiple Accounts keep the existing `<details>` switcher semantics and `tenant_switch_path/2` URL ownership, 44px targets.
- **D-11: Preview shows no Account identity.** No picker, no disabled picker, no Account name or `tenant_id` text, even from validated return context (Preview has no actor; rendering a URL-supplied value into trusted chrome is spoofable). The scoped group on Preview is headed by a static "Scoped to an Account" label. `account_labels` is NOT added to the preview session.
- **D-12: Preview subtitle describes what Preview reads** (each Mailable's `preview_props/0` scenarios; no Delivery or Inbound records) and never claims "sample data" / "demo data" / Account data — adopters author `preview_props/0`, so provenance claims would be dishonest. Final wording via ux-writing in UI-SPEC.
- **D-13: Accessibility.** Scoped links wrapped in `role="group"` labelled by the header; `aria-describedby` derived from the rendered items (drops Inbound when not installed). Visible focus, non-color cues.

### Health composition (OUTUX-06)
- **D-14: Expected winner A = single constrained reading column (~42rem), container queries not viewport breakpoints.** Order: (1) observation group (`role=group`: period + help, "Last checked", Refresh — left-aligned, Refresh stays with its timestamp when wrapping); (2) verdict + issue `<ul>`; (3) stale/unavailable notices adjacent to what they qualify; (4) Recent activity, still an `h2` for structure but styled at label size below a hairline, body-size counts.
- **D-15: Bounded comparison, not presumption.** Alternative B = primary list + content-sized aside at container ≥56rem. Both built from the same production components in a temporary story/spike at container widths 288/358/480/736/1150 (plus the real main width beside the 15rem sidebar), light and dark, fixed scenarios. Seven hard gates: no horizontal overflow; DOM order = visual order; observation group cohesive; ≥44px targets; byte-identical `{testid,count,href}` population fingerprint; text status cues; axe clean. Measured tie-breakers decide; record results as a phase artifact. Only the winner ships (no production `layout` attr). If B wins on gates, ship B — no owner call needed unless gates tie and the choice is purely visual.
- **D-16: Populations and links unchanged.** `health_issues/7` keeps its count>0 filter, fixed category order (delivery → inbound → webhook), per-issue deep links and stale markers. Counts lose the large bold gutter treatment; count never drives order, color or severity wording. Move observation markup from `operator_live.ex` into `HealthOverview` (presentation only).
- **D-17: Fixes.** Issue links get `min-h-11`; remove `role=status` from persistent notices (double-announce with toast); `order-*` visual reordering removed. Copy: "Not refreshed", "No mail activity in this period", name which activity is unavailable. Amend `docs/design-system.md` ("observation period stays separate") in the same change. Update the five affected assertions deliberately.

### Verification (D-52 — zero owner UAT)
- **D-18: Connected ExUnit (full admin lane, `verify.support_contract.admin`):** validator table (unknown surface, blank/oversized/control-char/invalid-UTF-8 id, non-local configured path); custom mounts (`/alt/dev/console`, `/secure/console` with `navigation`); unauthorized Account denied on arrival; direct-entry fallback; context survives index redirect, scenario patch, width patch, theme round-trip; session maps unchanged; ThemeController segment boundary.
- **D-19: `phase177_prohibition_contract_test.exs`** (template phase175), each rule mutation-proven with detector self-test: no Account picker/name/`tenant_id` text on Preview; no "sample/demo data" or Account-data provenance claim; Preview not inside the scoped group; no-choice → no picker; issue order independent of count; no severity words from count; every issue keeps a deep link; Preview/Operator session keys unchanged; Back link never names an Account; `aria-describedby` omits absent Inbound. Author all must-NOTs `verification: test`.
- **D-20: Playwright:** Health comparison geometry gates; replace `metricColumns` 1-vs-2 assertion in `phase169-journey.spec.js`; every issue deep link lands on a filtered view showing the matching count; Browser Back from operator returns to Preview; Account control visible at 320/375/768/1280/1440.
- **D-21: Stories (production components, `delivery_investigation.story.exs` pattern, builders in `reference/persona_spec/quick_view_scenarios.ex/.json`):** HealthOverview — Northstar normal, Helios empty, stale, unavailable, Fjordline long/Unicode; Account control — none, one, many, long label; Preview chrome — valid return, direct entry. Fill `fb-health-crowding` and `fb-account-context` `scenario_ids` + dispositions. Stories prove rendering only; real routes prove scope and return.

### Claude's Discretion
- Exact param names may be adjusted for consistency if planning finds a clash, keeping closed-set semantics.
- Final microcopy wording (UI-SPEC, ux-writing) within D-06/D-11/D-12/D-17 constraints.
- Tie-breaker metrics for D-15.

### Folded Todos
- `.planning/todos/2026-10-25-health-overview-layout-owner-feedback.md` (drives D-14..D-17)
- `.planning/todos/2026-10-26-owner-review-health-preview-controls.md` (Health/Preview portions)
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/research/phase-177/RETURN-DESTINATION.md` — UXF-10 design, adversarial pass, 19-row test matrix (note: its copy "Previews use sample data" is SUPERSEDED by D-12)
- `.planning/research/phase-177/ACCOUNT-CONTROL.md` — UXF-09 design, P1–P9 prohibitions (note: its operator-side tenant allow-list is NOT adopted — see D-05)
- `.planning/research/phase-177/HEALTH-COMPOSITION.md` — OUTUX-06 composition, comparison method, gates, copy
- `.planning/ROADMAP.md` — Phase 177 section
- `.planning/REQUIREMENTS.md` — UXF-09, UXF-10, OUTUX-06; shared acceptance (Navigation decision, Composition and interaction)
- `.planning/METHODOLOGY.md` — D-52; judgment→test prohibition rule
- `.planning/research/ui-quality-engine/UPSTREAM-SCOPE.md` — Preview renders defaults; no account-aware Preview
- `.planning/todos/2026-10-25-health-overview-layout-owner-feedback.md`
- `.planning/todos/2026-10-26-owner-review-health-preview-controls.md`
- `.planning/phases/176-direct-filters-and-useful-inbound-evidence/176-CONTEXT.md` — tenant URL ownership, verification pattern
- `.planning/milestones/v2.9-phases/168-shared-workspace-and-usable-baseline/168-CONTEXT.md` — D-01 Account visibility
- `mailglass_admin/test/mailglass_admin/phase175_prohibition_contract_test.exs` — prohibition template
- `mailglass_admin/docs/api_stability.md` — router contract (must not change)
- `mailglass_admin/docs/design-system.md` — to amend (D-17)
- `brandbook/brand-book.md` — canonical brand
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `MailglassAdmin.Operator.Shell` — `surface_paths/4`, `tenant_switch_path/2`, `account_context/1`, `tenant_selector/1`
- `MailglassAdmin.SurfaceNav.nav/1`; `MailglassAdmin.AdminShell.shell/1` (`:actions`, `:mobile_nav` slots; mobile band always visible below md)
- `MailglassAdmin.MountPath.base/1` + `MountPathHook`; `MailglassAdmin.Operator.Accounts`
- `Components.field_help`, `Components.timestamp`; `retry_health` handler; `health_issues/7` (`operator_live.ex:~2849-2931`)
- Scenario builders `reference/persona_spec/quick_view_scenarios.ex/.json`

### Established Patterns
- All operator state lives in the URL (`tenant_id` on every surface); Preview carries only `width`/`frame` today.
- Session whitelists in `router.ex:354-401` ("Add keys here ONLY when intentionally surfacing them").
- Cross-live_session links are plain `href`.
- Prohibition contract tests prove detectors with source mutations.
- Stories wrap production components in a theme-owner iframe.

### Integration Points
- Operator→Preview link: `preview_path` in `operator_live.ex:120,707,717`, `inbound_live.ex:135,555,565`
- Preview: `preview_live.ex` `handle_params` (98-191), actions slot (317-325), `preview_surface_paths` (743-762), `first_scenario_path` (682-693), `build_capture_url` (798), `preview_theme_path` (807-846); `preview/sidebar.ex:186,285,394`
- Health: `operator_live.ex:739-807`, `operator/health_overview.ex`
- Tenant selection catch-all: `operator_live.ex:1202-1203`, `inbound_live.ex:1056`
- Theme sanitizer: `controllers/theme_controller.ex:11-19`
- Test endpoint/auth: `mailglass_admin/test/support/endpoint_case.ex:43-125,349-383`
- Demo: `reference/demo_app/lib/mailglass_demo_web/router.ex:104-148`, `admin_auth.ex`, `controllers/page_controller.ex:155-210`
- Coupled tests: `test/mailglass_admin/operator/shell_test.exs:216`, `test/mailglass_admin/preview_live_test.exs:361`, `e2e/{health-tooltips,operator,structural,flows,inbound-layout,phase169-journey,phase170-journey,phase175-inbound}.spec.js`
</code_context>

<specifics>
## Specific Ideas

- AWS IAM "Global" in place of the Region selector is the model for D-11's static scope label.
- Linear/Sentry/Vercel/Stripe scope-switcher-heads-the-scoped-nav is the model for D-09.
- Confirm on both LiveView clients (admin LV 1.2.13, demo LV 1.1.33) that `on_mount` params include query-string `tenant_id`, so the D-05 arrival-denial proof is valid.
</specifics>

<deferred>
## Deferred Ideas

- **In-Operator Account switch via `push_patch` does not re-run on_mount host auth** (pre-existing gap, `operator_live.ex:1202-1203`). Not fixed here and must not be described as fixed; capture as a todo for a security-hardening slice.
- Optional mailglass-side tenant allow-list on URL `tenant_id` (research alternative to D-05) — revisit only with the above.

### Reviewed Todos (not folded)
None.
</deferred>
