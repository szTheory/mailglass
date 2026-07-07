---
gsd_state_version: 1.0
milestone: v2.1
milestone_name: Postgres + Admin URL Hardening)
current_phase: 139
current_phase_name: Admin asset first-load/deep-link proof
status: verifying
stopped_at: Completed 138-04-PLAN.md
last_updated: "2026-07-07T22:09:10.677Z"
last_activity: 2026-07-07
last_activity_desc: Phase 138 complete, transitioned to Phase 139
progress:
  total_phases: 3
  completed_phases: 1
  total_plans: 4
  completed_plans: 4
  percent: 33
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-07-07 - after Phase 138 completion)

**Core value:** Email you can see, audit, and trust before it ships. Mailglass turns "did the email go out, render correctly, and reach the inbox?" from a guessing game into observable, replayable, debuggable infrastructure.
**Current focus:** Phase 139 — Admin asset first-load/deep-link proof

## Current Position

Phase: 139 — Admin asset first-load/deep-link proof
Plan: Not started
Status: Phase 139 ready for discussion/planning
Last activity: 2026-07-07 — Phase 138 complete, transitioned to Phase 139

## v2.1 Milestone Intent

- **Maintenance/hardening only (NOT feature growth).** v2.0 shipped the dedicated `mailglass` Postgres
  schema, but its release debug campaign proved a real class of missing-`prefix:` bugs can be masked when
  tests patch the DB `search_path`. Admin asset URL handling also has a partial mount-aware fix, but lacks
  broad first-load/deep-link proof across preview/operator/inbound/gallery/error paths and arbitrary mount
  roots.

- **Goal.** Make schema-isolated runtime paths and admin first-load asset URLs fail closed with focused
  gates, while avoiding product capability growth, UI redesign, router API churn, or a full no-search-path
  suite migration.

- **Locked decisions (research, 2026-07-07):** (1) explicit Ecto `prefix:` remains the correctness
  mechanism; `search_path` may be test/host convenience only; (2) start with surgical fixes, hostile
  runtime tests, and a static guard instead of hand-editing every fixture; (3) preserve root-relative
  computed admin asset URLs through `MountPathHook`/`MountPath`/layout `css_url`; (4) browser proof uses
  CSS/font network assertions and computed styles, not screenshots or pixel diffs; (5) broader UI
  verification discipline and SEED-003 ecosystem integrations remain deferred.

## v2.1 Scope Locks

- **No product expansion.** No new providers, transports, routes, or release cut.
- **No admin redesign.** No token, component, motion, layout, or brand refresh work beyond computed-style
  proof that existing styles load.

- **No public router macro option change** unless a phase proves the current mount-aware path cannot
  satisfy the requirement; document the tradeoff before widening scope.

- **No full no-search-path suite migration.** Create the focused fail-closed lane and static guard first;
  broader fixture cleanup stays future work unless it becomes necessary to make the focused proof honest.

- **Phase numbers continue at 138.** v2.0's 132-137 artifacts are shipped history.

## Roadmap Snapshot

| Phase | Name | Focus |
|-------|------|-------|
| 138 | Schema-prefix no-search-path hardening | Fix concrete missing-prefix runtime risks, add hostile no-search-path DB proof, and add a static guard for raw repo/Multi callback prefix omissions (SCHEMA-01..04, GATE-01..02) |
| 139 | Admin asset first-load/deep-link proof | Harden and prove mount-aware stylesheet URLs across preview/operator/inbound/gallery/scenario/error/query routes and arbitrary alternate mount roots (AAU-01..04, GATE-03) |
| 140 | Verification, docs reconciliation, and closeout | Run focused verification lanes, update stale docs/backlog that describe resolved asset limitations, preserve deferred scope, and prepare milestone closeout (DOC-01..02, all gates) |

**Execution order:** 138 -> 139 -> 140. Phase 138 closes the data-correctness follow-up first; Phase 139
then handles the admin first-load surface; Phase 140 reconciles docs/backlog and confirms the milestone can
close without dragging in the deferred UI-verification or ecosystem milestones.

**Research flags:** none blocking. Per-phase planning may inspect unfamiliar Ecto/Phoenix edges, but the
milestone-level decisions above are settled.

## v2.0 Shipped Snapshot

v2.0 Postgres Schema Isolation shipped 2026-07-04: mailglass 2.0.0 / mailglass_admin 2.0.0 /
mailglass_inbound 2.0.0 are live on Hex. All six phases (132-137) completed and the audit passed. The
closeout follow-up feeding v2.1 is the test/runtime `search_path` masking risk discovered during the
release debug campaign.

## Decisions

- [109-03] BORDER-GATE uses an explicit raw Tailwind palette list rather than a generic `[a-z]+-[0-9]` suffix so semantic DaisyUI tokens like `border-base-300` remain valid.
- [109-03] Ratchet schema v3 seeds the `system` axis from each block's existing light score and preserves prior/current run IDs; Phase 109 does not perform a pillar re-score.
- [109-04] System/default theme proof remains structural: no explicit `data-theme` under OS light/dark emulation, no JS hook/storage/picker, and no `data-theme="system"`.
- [109-04] Icon-only controls subject to the 44px target floor need both `min-h-11` and `min-w-11`; `btn-square btn-sm` alone is only 32px wide.
- [92-01] Root README uses `brandbook/examples/readme-header.svg` directly as the first visible brand surface.
- [92-01] `brandbook/examples/og-card.png` is the only committed v1.10 binary exception for GitHub social preview upload.
- [92-01] GitHub social-preview upload remains manual because no documented write API exists.
- [92-02] Admin logo rendering uses inline `currentColor` SVG so the sealed-flap lockup inherits light/dark admin chrome color while the stable `logo.svg` route remains served.
- [92-02] The admin CSS bundle is committed when `mix verify.preview` rebuilds `priv/static/app.css`, because the gate requires bundle-clean output.
- [v1.10] Active brand voice and visual identity source is now `brandbook/brand-book.md`; prompt-era brand research remains preserved as provenance, not as an active source pointer.
- [v1.10] Research pre-settled (see `.planning/research/v1.10-brand-adoption/ADOPTION-MECHANICS.md`): ex_doc 0.40.1 supports SVG logo/favicon but requires explicit width/height attrs (fable SVGs are viewBox-only — must add); use relative paths into canonical `brandbook/` (no per-package copies, no `files:` allowlist change); `docs:`/`chore:` commits are release-safe under release-please defaults; GitHub social preview is Settings-UI-only (no write API); og-card export via `npx playwright screenshot --viewport-size=2400,1260`; CLAUDE.md + `mailglass_admin/docs/design-system.md:5` are the only tracked reference-sweep targets.
- [v1.10] HexDocs latency accepted: `logo:`/`favicon:` wiring is inert on hexdocs.pm until the next natural release of each package — this milestone does not force a release to make logos visible.
- [86-01] Dark feedback backgrounds decided and verified at first candidates: success-bg #142B22 (6.56), warning-bg #2B2314 (7.37), error-bg #2E1B1E (6.65), info-bg #11293A (11.18) — each `{kind}-text` >= 4.5:1 on its bg.
- [86-01] Worst-surface contrast figures recomputed against the SHIPPED surface set: `surface-selected` is the worst surface in both themes (dark text-muted 6.66 = AA there, AAA elsewhere); the 86-foundations-decisions.md matrix is authoritative over research worst-case quotes. border-input <3:1 on selected surfaces resolved as a usage rule (form controls never sit on selected rows).
- [v1.9] Research pre-settled in the fable brandbook research summary: DTCG-2025.10 token format (two tiers, hex strings), `--mg-*` CSS naming with `[data-theme="dark"]` reassignment, Glass #277B96 passes AA on white (4.82:1), six computed fix hexes for the four contrast failures, codex dark ramp adopted, font stacks honest about system-ui fallback, GitHub SVG rules (outlined paths, explicit hex fills, no bare currentColor in file assets).
- [D-25] v1.8 brand-system work is a repo-artifact milestone, not product expansion: all artifacts stay under `brandbook/`, no API/package code changes, no binary-heavy collateral, and prompt-era brand strategy is preserved. `572f3eb2` is a draft artifact commit, not milestone completion evidence.
- [D-24] v1.7 admin UI polish is a sanctioned adopter-visible-quality investment under D-23 convergence rule; delivered within the brand book (Fork B) by applying the shipped design system more completely, with a real in-library Operator Overview landing + generalized orientation (Fork A).
- [v1.7] Anti-churn contract: no build task ships without citing a Phase 74 gap-register row at severity ≥ 3. The gap register is the gate.
- [v1.7] Linked-version release mechanics: admin minor bump mechanically produces matched releases for core + inbound (no API change — administrative only). Acknowledged in milestone scope, not a surprise.
- [v1.7] Fork A locked: Operator Overview as a `:overview` action on existing `OperatorLive` (zero router-macro change), not a sibling LiveView. Orientation strip generalized into `Shell.orientation_strip/1`.
- [v1.7] Fork B locked: pop/joy via consistent motion + expressive seed data + sharper hierarchy within the current brand book. No brand-book amendment. No new visual loudness.
- [76-01] status_badge/1 renders icon+label with literal-string-only defp helpers for JIT safety; normalize_inbound_outcome/1 is public for cross-module import (admin-side adapter, never touches mailglass_inbound locked 1.0 schema)
- [Phase ?]: Fallback clauses added to status helpers for phantom atoms (suppressed, nil) — badge-outline per UI-SPEC Conflict 1
- [76-06] heroicons-inline.js: self-contained standalone-binary-compatible Tailwind plugin replaces Node.js-dependent heroicons.js; 12 outline SVGs embedded inline; wired via @plugin in app.css
- [77-04] Bundle-clean gate (D-08, GAP-19): mix verify.preview exits 0; priv/static/ confirmed no-op / bit-identical after Phase 77 HEEx id-attribute changes; citext_probe.ex Boundary declaration + voice_test script-strip fixed pre-existing verify.preview blockers
- [79-01] check-conformance.sh TYPE-GATE requires grep -v text-base-content (Footgun-6: DaisyUI semantic color token, not a type-scale violation; without exclusion every file using text-base-content produces a false failure)
- [79-02] replay timeline badge text: event_badge/1 returns "Replay audit" as a truthy sentinel (controls badge rendering), not the visible text; status_label(:webhook_replay_succeeded) = "Replay succeeded" is what the DOM contains; replay_event_label(:webhook_replay_succeeded) = "Webhook replay completed" is the row title
- [79-02] preview-orientation e2e: preview-orientation only renders when @mailables == []; use /ops/browser-preview-empty test route (sets mailables=[] in session) to reach this state in a test server that has explicit fixture mailables configured
- [79-03-A] Textual audit finding derived from code review; agent-browser available but demo boot causes swoosh lock drift (Pitfall 5); durable artifact is textual per D-01
- [79-03-B] GAP-22 reconfirmed permanent v1.7 DEFERRED at severity 3 per design-system.md lines 152-159; no code change
- [79-03-C] 74-GAP-REGISTER.md NOT modified; all closure evidence in 79-GAP-CLOSEOUT.md per frozen-artifact pattern
- [80-01] Existing `brandbook/` assets are draft inputs from commit `572f3eb2`, not approved Phase 81-84 outputs.
- [80-01] `BRAND-GAP-NN` rows are stable downstream citation anchors; severity 4-5 rows require explicit closure or documented deferral before Phase 84 closeout.
- [80-01] Phase 80 approves only the audit/register gate in `brandbook/brand-audit.md`; final tokens, logos, copy, specimens, package proof, and validation scripts remain downstream work.
- [Phase 87]: 87-01: one shared LOGO-CRAFT glyph library underpins all round-1 wordmarks; the eight concepts are independent
- [88-01]: favicon scale chips drawn inline with explicit fills — img obeys OS prefers-color-scheme, not the page toggle
- [88-01]: page marks drawn from live tokens (pane=text, seal=accent) reproducing the logo color program in both themes
- [Phase 89]: readme-header fills restricted to Glass+Slate — the only token pair >=3:1 on both GitHub grounds (computed 4.82/3.93, 5.47/3.46)
- [Phase 89]: Diagram labels use a purpose-built 14-glyph stencil set, not wordmark glyphs — label craft kept distinct from wordmark craft
- [Phase ?]: [94-01] Advisory TYPE-lg/xl and TRACK-[ gates run in CI with continue-on-error until Phase 98/99 cleans known violations (D-08, RATCHET-03)
- [Phase ?]: [95-02] D-08 commit 2 satisfied: ExUnit shape/range baseline assertion green in verify.support_contract.admin before Playwright structural spec (95-03). if-false guard pattern used to keep compare_baselines/2 as defp without triggering --warnings-as-errors
- [Phase ?]: Phase 95 baseline: Radius/Color/Elevation all score 4 across all surfaces — token discipline from Phase 94 holding
- [Phase ?]: Phase 95 baseline: Preview Motion+A11y scored 2 — dark-mode absence (theme param ignored) tracked as GAP-03 sev=3
- [96-02] IA-LD-01..09 locked: master-detail viewport split (390px stacked, 768px 40-60, 1440px 33-67), filter-label token class (GAP-04 close via IA-LD-04 — text-label uppercase font-bold text-secondary, no tracking-[0.08em]), filter disclosure mobile-only toggle, orientation strip placement, inbound overview tier spec (GROUP-02 IA layer via IA-LD-09), Preview <details>/<summary> sidebar, empty-state placement rules (GAP-02 reference via IA-LD-07)
- [Phase ?]: MOTION-LD-01..14 locked: ease-out only ≤300ms per element transform/opacity only prefers-reduced-motion snaps to instant GAP-02 closes via MOTION-LD-12 focusable CTA
- [Phase ?]: [STATE-LD-05..22] 22 component-state locked decisions; focus gaps in nav_link/deliveries_list/sidebar; GAP-01 fixed in support_cards; GAP-04 fixed in filters_form; routing_trace/evidence_card reveal models correctly partitioned; MOTION-LD-01..14 locked (Phase 96-03)
- [Phase ?]: DARK-LD-01..08 locked: dark elevation tier order, border-input upgrade for WCAG 1.4.11, focus-ring Ice confirmed, GAP-03 prescription for Phase 100
- [Phase ?]: [96-05] COPY-LD-01..16 locked: 16 microcopy decisions mapping thoughtful-maintainer voice to per-surface JTBDs; error pattern '[Noun] [past-tense verb]: [specific cause]'; 'Oops' named canonical anti-pattern; GAP-02 copy close via COPY-LD-05 (Preview CTA 'Preview the first Mailable'); GAP-04 copy close via COPY-LD-10 ('Window' to 'Time window')
- [Phase ?]: ring-primary semantic token used for focus rings (nav_link/nav_pill) — resolves Glass in light, Ice in dark per DARK-LD-03
- [Phase ?]: theme_toggle btn-sm retained: btn-sm sets height via --size CSS var; min-h-11 sets min-height — different properties, effective 44px touch target confirmed
- [Phase ?]: ring-inset used on deliveries_list row button (not ring-offset) — button spans full list item width, offset ring would clip at li boundary
- [Phase ?]: text-heading token replaces banned text-xl in both detail_header h2 elements (STATE-LD-12, UI-SPEC Typography)
- [Phase ?]: tracking-[0.08em] removed from all five filters_form label spans — heading letter-spacing handled by global h1/h2/h3 rule (STATE-LD-13, GAP-04)
- [Phase ?]: btn-sm removed from support_cards CTA buttons; tier-1 gets px-md + min-h-11, tier-2 ghost gets px-sm + min-h-11 for 44px touch-target floor (STATE-LD-14, GAP-01)
- [Phase ?]: Focus trap for assign-controlled modal uses phx-mounted/phx-remove on :if conditional span in operator_live.ex render template — no client JS hook needed
- [Phase ?]: id=replay-open-btn added to detail_header trigger button as JS.focus return target for modal close
- [97-05]: device_frame min-h-11 added alongside btn-sm — btn-sm uses --size CSS var, min-h-11 sets min-height independently; both coexist, effective 44px touch target (STATE-LD-20)
- [97-05]: ring-inset used on tabs tab buttons (inline inside tablist — offset ring would clip at tablist boundary; same rationale as deliveries_list row) (STATE-LD-21)
- [97-05]: border-l-2 replaces border-l-[3px] in both sidebar scenario_classes clauses — nearest Tailwind scale value, aligns with nav_link border-l-2 at shell.ex:207, arbitrary value removed (STATE-LD-22)
- [Phase ?]: Phase 97 Plan 06: GalleryLive with complete specimen matrix
- [97-08]: Flash testids use exact gallery state names (gallery-flash-error-kind not gallery-flash-error) — matched from gallery_live.ex @specimens; sidebar scenario keys must be atoms not strings for Atom.to_string/1; NaiveDateTime specimens must use UTC DateTime for format_datetime/1
- [Phase 99-01]: Summary totals are computed from tenant-scoped inbound records, not the capped list read model. — Phase 99 Plan 01 established the internal inbound summary seam required for GROUP-02.
- [Phase 99-01]: The selected outcome filter is ignored for summary denominator and breakdown. — Phase 99 Plan 01 established the internal inbound summary seam required for GROUP-02.
- [Phase 99-01]: Admin access to the summary stays behind the existing optional-dependency apply/3 gateway. — Phase 99 Plan 01 established the internal inbound summary seam required for GROUP-02.
- [Phase 99]: [99-03] Admin CSS bundle is committed after class changes to preserve the bundle-clean gate.
- [Phase 99]: [99-03] RoutingTrace keeps matcher verdict truth upstream and only changes presentation.
- [Phase 99]: [99-03] EvidenceCard keeps raw payload bytes absent in redacted and denied states; :revealed is the only raw-rendering state.
- [Phase 99]: [99-04] Inbound browser state coverage stays on the existing `/ops/browser-reset` path; no second seed endpoint was added.
- [Phase 99]: [99-04] No-match browser row selection uses the visible `No match` status badge because the list intentionally omits subject text.
- [Phase 99]: [99-04] Malformed inbound IDs now render the existing detail-error state instead of reaching the UUID-cast query path.
- [Phase 99]: [99-05] Advisory TYPE-lg/xl and TRACK gates now fail closed in CI; Preview cleanup was limited to text-xl -> text-heading. — Phase 99 D-14 required the former advisory gate to block regressions after cleanup.
- [Phase 99]: [99-05] Operator browser gate runs with --workers=1 because /ops/browser-reset uses shared deterministic seed state. — The broad gate failed under concurrent resets and passed 45/45 after serialization, matching the focused 99-04 shared-seed evidence.
- [Phase ?]: @banned_words module attribute makes banned-word list data-driven across all three surfaces
- [Phase ?]: LD-12 asserted using HTML-entity form (HEEx escapes apostrophes in text nodes as &#39;)
- [102-01] MOTION-GATE added to check-conformance.sh: two grep passes ban layout-property transitions (MOTION-LD-10) and stray ease-in (MOTION-LD-01); piped grep -v exclusions for ease-in-out + --ease-symmetric used instead of POSIX-incompatible lookahead. Reduced-motion Playwright test clicks first delivery row to bring .motion-reveal into DOM before asserting computed animationDuration/transitionDuration ≤ 0.05s. Enter/exit asymmetry test.fixme scaffold pending Plan 102-03.
- [102-02] --ease-symmetric: var(--ease-in-out) added to @theme; .motion-tab-swap switched to var(--ease-symmetric) (MOTION-LD-05). MOTION-LD-06 resolution: focus rings → --duration-instant (90ms, ≤100ms); row hover → --duration-fast (150ms). phx-connected/phx-loading are CSS classes on the LiveView container element (not body attributes) — confirmed against LV 1.1.28 runtime; .mg-skeleton uses .phx-loading/.phx-connected class selectors. @view-transition PE inside @media (prefers-reduced-motion: no-preference) — required wrapper because global reduce block does not cover VT pseudo-elements. Bundle rebuilt bit-clean.
- [Phase ?]: [103-02] Schema-2 baseline armed: compare_baselines activated, anti-vacuity guard enforced, preview Motion+A11y rose 2→3
- [103-03] All 6 CI gates confirmed green (2026-06-16-phase-103): support_contract.admin 56/56, verify.preview 236/236 (bundle-clean), conformance OK, conformance-advisory OK, motion OK, Playwright structural 54/54 (0 skips — Phase 102-03 fixme completed). Release posture 1.6.2/1.6.2/1.3.1 verified read-only; RELH-01 intact; inbound re-pin PENDING/deferred (D-13, DISC-2 divergence from Phase-79 precedent).
- [ASSESS-2026-06-16] **Next-step done-assessment verdict (repo-local, 3-agent exploration):** mailglass is **~88–90% done** — band "strong; ONE meaningful adopter wedge remains, rest is diminishing returns." Code surface alone is ~92% (all 10 `guides/jobs.md` jobs map to shipped/tested code; ~243 test files; 6 webhook + 4 inbound providers real). The library is feature-complete for its scope — **stop adding capability.**
- [ASSESS-2026-06-16] **Recommended next milestone: "Adopter Onboarding & Day-2 Confidence" (suggest v1.12)** — convert the one weak axis (onboarding/day-2 DX). Done-enough: installer fails closed on the webhook-`Plug.Parsers` conflict (silent prod 401 today, `apply.ex:64-74`); fix broken README quickstart; "week 1" guide arc; production go-live checklist (surface `mix mail.doctor`); unified error/troubleshooting guide; sharpen migration-from-swoosh "why". Then **cut the staged Hex release** (v1.7–v1.11 are prepare-only, not on Hex) + inbound exact-pin re-pin (D-13). Then replay-modal a11y (WR-03). Full wedge spec: `.planning/threads/adopter-onboarding-day2-confidence.md`.
- [ASSESS-2026-06-16] **Diminishing-returns / DO-NOT-build-without-pull:** core email-template HEEx component uplift (recipient-facing polish, not an adopter wedge), SEED-003 ecosystem integrations, synthetic inbound dev UI, Cloudflare routing, gen_smtp, more providers. Risk here is **overbuilding, not underbuilding**.
- [ASSESS-2026-06-16] **Doc-drift flagged:** `.planning/research/JTBD-COVERAGE.md` is 5 milestones stale (dated 2026-05-23, covers up to inbound 0.1.0 / v1.2). Its *curve/conclusion* ("after v1.2 inbound + golden example, diminishing returns — wait for pull") has been **borne out** by v1.4–v1.11; only its status tables are stale. Staleness banner added; full refresh is a precondition before any *feature-discovery* pass (not needed for the onboarding wedge). Stale threads inbound-stability-lock-prep + next-milestone-adopter-trust-proof marked resolved.
- [ASSESS-2026-06-17] **Post-v1.12 next-step assessment verdict (repo-local, 1 thorough source-sweep agent + direct reads):** the last identified adopter wedge (onboarding/day-2 DX) is **CLOSED** and the prepare-only release backlog is **drained** — v1.12 shipped both. Repo source confirms no foundational or important-but-narrow gap remains. **Done-% ≈ 93–95% (near-done / diminishing returns).** **There is NO recommended next feature milestone.** Honest next move = **explicit quiet maintenance** (D-23 posture). `adopter-onboarding-day2-confidence.md` closed (exit signal met). Source-sweep caveat: agent flagged the SQLSTATE 45A01 ledger trigger as "app-code only" — false alarm; the trigger lives in the `mailglass.gen.migration` template (not `lib/`), D-15 validated.
- [ASSESS-2026-06-17] **Only remaining concrete work is maintenance-tier (no milestone):** (a) harden `publish-hex.yml` `gate-ci-green` `isAdvisory()` to classify "Demo Browser Evidence" advisory by name; (b) deferred reference baseline pin bump `~> 1.4` → `~> 1.7` (coordinated 5-file change). Tracked in new thread `release-pipeline-maintenance.md`. Use `/gsd-quick`, not `/gsd-new-milestone`.
- [ASSESS-2026-06-17] **Expansion tail re-confirmed flat:** SEED-003 ecosystem integrations, Cloudflare Email Routing, synthetic inbound dev UI, `gen_smtp` listener, more providers, core HEEx email-template uplift — all pull-gated / diminishing-returns, no signal through v1.12. Risk remains **overbuilding, not underbuilding**. Pending todo "refresh outbound admin UI look and feel" (2026-06-13) is effectively **subsumed by v1.11's fractal three-surface uplift** — the `.planning/todos/pending/` dir is now empty; STATE "Pending Todos" reference is stale and should be treated as resolved.
- [Phase 110]: Theme picker exposes an event attr that renders per-option phx-click plus phx-value-theme values; persistence and no-FOUC remain downstream scope.
- [Phase 110]: Theme choices are native radios with closed atom values :system, :light, and :dark; no aria-pressed, storage, hook, or explicit data-theme=system behavior was introduced.
- [Phase 110]: Stat-card severity uses the existing vendored Heroicons inventory rather than adding new icons in Plan 110-01.
- [Phase 110-primitives]: The shell passes `event="set_theme"` into the public `Components.theme_picker/1` and relies on component-rendered `phx-value-theme` values. — Plan 110-02 kept theme option rendering owned by the public primitive while shell LiveViews handle only URL patch semantics.
- [Phase 110-primitives]: Theme `system` remains absence of an explicit query value; `Shell.set_theme_path/2` removes `theme` while preserving unrelated query params. — This preserves the Phase 110/112 boundary: Plan 110-02 wires selection semantics without adding storage, cookies, hooks, or no-FOUC root ownership.
- [Phase 110-03]: GalleryLive renders public primitive components for nav_link, nav_pill, tenant_chip, theme_picker, and stat_card. — This makes the gallery certify the same component API used by shell and overview surfaces.
- [Phase 110-03]: Gallery system specimens are inherited-theme wrappers with stable test ids and no data-theme attribute. — System remains absence of explicit theme choice while preserving light and dark specimen coverage.
- [Phase 110-primitives]: 110-04: Primitive conformance now fails closed on copy drift, non-canonical stat cards, and missing vendored Heroicons.
- [Phase 110-primitives]: 110-04: Primitive structural proof uses computed styles and DOM semantics, not screenshots, pixel diffs, axe, storage, matchMedia, or theme hooks.
- [Phase 110-primitives]: 110-04: Repeated gallery theme_picker specimens use unique native radio group names so per-cell checked state remains real.
- [Phase 110-primitives]: 110-04: Preview URL assertions follow the existing canonical width/theme ordering.
- [Phase 111-forms]: filter_field/1 derives control id/name/value from Phoenix.HTML.FormField metadata first, while keeping explicit id/name/value overrides for gallery and certification surfaces. — This satisfies FORM-01/FORM-02 while preserving non-form gallery certification use cases.
- [Phase 111-forms]: Read-only select/checkbox-style controls use display-only rendering with aria-readonly and a hidden input only when submit_readonly is true and a value/name exist. — HTML readonly is not valid for select/checkbox controls, and hidden submission is only emitted when the value must submit.
- [Phase 111-forms]: Invalid filter primitives render visible Action needed recovery copy plus hero-exclamation-circle, not color alone. — FORM-02 requires recovery-oriented errors and validation state that never relies on color alone.
- [Phase 111-02]: Filter wrappers remain thin components that delegate all control HEEx to Components.filter_field/1 and filter_section/1. — Plan 111-02 kept wrapper call-site ownership while removing duplicated label/control/help/error markup from operator and inbound filter modules.
- [Phase 111-02]: filter_errors is a %{"field" => "message"} side map computed from raw URL/form params before normalization. — This keeps recovery metadata explicit while preserving map-backed Phoenix forms and existing read-model filter contracts.
- [Phase 111-02]: Invalid apply_filters submissions render normalized form values and recovery copy without push_patch; valid submissions retain URL-backed patch behavior. — Invalid values stay correctable without mutating the current URL or widening tenant/data boundaries.
- [Phase 111-03]: Preview atom and unsupported assign values render as aria-readonly display rows without hidden submitted values. — PreviewLive preserves missing read-only keys from current assigns, avoiding type-eroding string coercion.
- [Phase 111-03]: Operator replay target radio identity is derived from sanitized webhook_event_id values with provider/event/linkage descriptions. — The target ID remains stable and traceable while keeping label and aria-describedby wiring explicit.
- [Phase 111-03]: Inbound replay remains a single-target confirmation modal with dialog labelling and no replay target radio group. — Inbound has no ambiguous replay target branch, so certification is a no-radio component contract rather than extra controls.
- [Phase ?]: Dual table+card delivery presentation from single @deliveries assign (DATA-01 operator slice)
- [Phase ?]: operator-deliveries-list legacy testid preserved on ul; operator-deliveries-cards added as wrapper div — Plan 04 migrates
- [Phase ?]: UI-SPEC copywriting contract applied to deliveries empty states: No deliveries have been recorded yet. / No deliveries match the current filters.
- [Phase ?]: Inbound records_list recipient column added to table (after Outcome) so mask_recipient/1 applies in BOTH presentations
- [Phase ?]: UI-SPEC copy adopted for inbound empty states: No records / No records have been recorded yet. / No records match the current filters.
- [Phase ?]: Scoped DATA-05 overflow to offsetWidth-vs-aside-width check
- [Phase ?]: noMatchRow() uses filter({visible:true}) to work at both mobile and desktop viewports
- [Phase ?]: Gallery overflow proof deferred to live-page assertions; gallery cells too narrow at 320px for meaningful per-cell check
- [Phase ?]: UI-SPEC copy changes from Plan 03 require concurrent updates to voice_test and components_test assertions
- [114-01]: Components.card/1 thin shell drops the decorative DaisyUI `card` class (no DaisyUI card layout relied on); GROUP-GATE/PRIMITIVE-DRIFT signatures match the dropped-class shape
- [114-01]: SPACE-GATE/GROUP-GATE scope to an explicit 8-file GROUP_SURFACES array, never `$LIB` recursion (17 other lib files share the off-grid numerics — Pitfall 1 / D-12)
- [114-01]: card/1 added to PRIMITIVE-DRIFT as a standalone def-check, NOT the gallery render_specimen awk loop (composed specimens register differently — plan 02)
- [Phase 114]: Composed-group specimens delegate from gallery dispatcher to public composed_*/1 fns (capturable for Floki proof); smoke assertion in operator_live_test.exs binds specimen to production detail column — D-10: lab must render the same composition the live view does; harness lives in operator_live_test.exs
- [Phase ?]: 114-03: shadow-raised passed via card/1 :global @rest class-merge (no components.ex edit); border-l-4 status rules paired with colored count + label (WCAG 1.4.1)
- [Phase ?]: Plan 114-04: Floki top-down ancestor-depth proof (no Floki.parent) is the authoritative GROUP-02 depth check; grep is only a tripwire
- [Phase ?]: Plan 114-04: Playwright composed-group geometry scopes to the light theme wrapper + direct-sibling [data-group-card]; narrow-width overflow asserts no descendant exceeds the viewport
- [Phase ?]: 116-01: A1 path-dep is circular (demo depends on admin); fell back to a shared reference/persona_spec/ dir compiled into both demo + admin test builds via absolute elixirc_paths
- [Phase ?]: 116-01: DemoData.reset! seeds the persona cohort at harness boot (Personas.seed!/1) — feeds RATCHET-04; canonical fjordline literals via Personas.specimen_literals/0 for plan 116-04 to mirror
- [Phase ?]: Phase 116-02: axe WCAG 2.2 AA ratchet established (9-cell axe-baseline.json schema 1, screenshot-free producer, fail-closed comparator with per-rule diff)
- [Phase ?]: [116-03] Interaction pillar (RATCHET-03): four binary Playwright gates (panel-above-scrim, scroll-chaining, focus-restore, CLS) across deliveries/inbound/preview x light/dark/system; CLS threshold 4px (<=8px ceiling), 0px floor on synchronous inbound mount; screenshot-free, no pixel-diff
- [Phase ?]: [116-03] Preview-pane centroid hit-test clamped to the visible viewport intersection (tall device frame extends past the fold; raw centroid returned elementFromPoint null) — Rule 1 fix in assertCentroidHitsPanel
- [Phase ?]: [116-04] Gallery mirrors the fjordline-aps persona literals as inlined SOURCE TEXT (not a runtime Personas call): the persona spec is test-only-compiled, so the dev/prod gallery cannot reference it; the drift-guard reads gallery_live.ex as text for byte-consistency
- [Phase ?]: [116-04] RATCHET-02 matrix gate enforces per-specimen overflow for EVERY cell at the 320/390 mobile floors; at md+ a documented wide-shell allowlist exempts intrinsically-wide pre-existing card/SVG specimens (gallery-shell property) but still fails closed on NEW specimen overflow
- [116-05] Bucket-A closure is an executable fail-closed manifest (bucket_a_coverage_test.exs): all 24 defects A1..A24 cite a guard literal asserted to physically exist (gate name / e2e test title / axe ref / persona literal); a renamed/deleted guard fails the manifest, never passes vacuously.
- [116-05] A11 TABLE-OVERUSE-GATE floor = 3 (deliveries_list, records_list, preview/tabs — all genuinely tabular); the match pattern is "<table" + whitespace, which excludes the @moduledoc backtick prose form so header/doc text cannot inflate the count.
- [116-05] 6 net-new Bucket-A guards landed (A3, A4/A23, A16-system, A21, A22, A11); ~18 cite existing green guards from phases 109-115 + plans 116-02/03. All 24 ship status: live (no downgrades), so 116-06's phase gate accounts for a full 24/24 closure.
- [Phase ?]: v1.13 ratchet-arm armed (116-06): 54-cell aesthetic + 9-cell axe baselines promoted current->prior with distinct run_ids; all three fail-closed comparators green (22 tests, 0 failures)
- [Phase ?]: Storybook theme bridge uses per-variation template-level data-theme (not color_mode class picker); admin components key off data-theme which a CSS class cannot drive without a forbidden app.css alias (D-08).
- [Phase ?]: phoenix_storybook css_path = served committed bundle URL /dev/mail/css-<md5>; no new asset build, app.css untouched (D-07).
- [Phase ?]: [118-02] Both judgment gates (nav-active-correctness, no-nav-duplication) are test.fixme asserting the correct end-state (D-12); flip green in Phase 119, armed into the floor in Phase 123 (D-13); not in any required CI lane.
- [Phase ?]: 121-01: Inbound gated into no-data/no-match/populated cond off empty_state_for/2; orientation strip empty-pane-only; data_state escalates only when records == []
- [Phase ?]: [121-03] Replay-modal focus-trap uses pure-LiveView.JS focus-sentinel spans (tabindex=0 + phx-focus={JS.focus(to:)}) wrapping to stable Close/Confirm ids — render-state-independent, byte-identical across inbound+operator modals; double-submit lock is phx-disable-with=Replaying… (D-14).
- [Phase ?]: 121-02 reveal a11y + PII-free reveal telemetry — ARIA disclosure (aria-expanded/aria-controls) + re-redact collapse + aria-live region; [:mailglass_admin, :inbound, :reveal_raw, :stop] with tenant_id/record_id/outcome only; D-10 redacted-default + pure authorize_reveal/1 untouched
- [Phase ?]: 121-04: Inbound empty-pane-only judgment gate (POPULATED/NO-DATA/NO-MATCH by testid count); T-121-10 no-data inbound-filters count-0 security boundary armed
- [Phase ?]: 121-04: operator-inbound persona re-shoot deferred to Phase 123 — demo webServer boot needs a baseline-drifting mix deps.get; D-17 fallback applied (no fabricated run)
- [Phase ?]: Phase 122 closed green-only-forward; persona re-shoot deferred to Phase 123 per D-17; app.css untouched + TokenParity green (D-13); floor held, no pillar re-score
- [Phase 123]: D-09 accept-indigo: phoenix_storybook 1.2.0 explorer chrome accepted as dev-only cosmetic; no config accent hook exists, theming needs dep CSS override or Node build (both forbidden); title already set to brand name
- [Phase 123]: D-11 storybook inventory complete as-is: 5 brand primitives match components.ex with zero attribute drift; 119-122 introduced no new theme-sensitive primitive; no story files added
- [Phase ?]: COH-01 coherence proof closed: DEFECT-REGISTER all 10 findings RESOLVED/HELD + Phase 123 cross-surface coherence sign-off (five hats + three personas verbatim, green-floor citation, no new automated coherence gate, D-06 single-ledger). Persona re-shoot grounded in existing .cache evidence + green floor — demo unrunnable in-env per plan authorization.
- [Phase ?]: ci_green aggregate job (if: always(), 5 required leaf needs) is sole required branch-protection context alongside Guard Release Trigger
- [Phase ?]: changes detection gate (hand-rolled git diff) replaces workflow-level paths-ignore; workflow always triggers, leaves skip individually
- [Phase 128]: mix ci inbound test step uses 'mix test --exclude property' with NO --seed 0 — Consumes Phase 127 DET-02 determinism; a seed pin would regress it
- [Phase 128]: deps.unlock --check-unused kept out of ci.fast — Lock carries orphaned transitive entries (castore, unicode_util_compat) that would red the check; cleaning them is a deferred follow-up (matches PR #104)
- [Phase 128]: Mailglass.CILanes is the single Elixir-side source for required+advisory CI lane identity; GATE-03 and the MIXCI-03 parity-drift test read it, and the parity test carries a durable no-seed assertion making DET-02 permanent. — One-definition-of-green (D-LD-10): the two CI surfaces (human aliases vs per-job matrix) stay coherent via a shared source + a fail-loud drift test, not duplicated literals.
- [Phase ?]: Phase 130-01: deps.audit publish-gate parses mix_audit GHSA output as a peer function; GHSA-vs-EEF-CVE ID asymmetry is intended
- [Phase ?]: Phase 130-01: OSV EEF-CVE-2026-43966/43969 resolve HTTP 200 natively; staleness gate runs on live data with try/rescue/catch fail-open
- [Phase ?]: [130-02] Dependabot sibling coverage added for /mailglass_admin + /mailglass_inbound only; frozen reference/ baselines excluded (reference-baseline-coupling).
- [Phase ?]: [130-02] 1.19/OTP28 advisory lives in a NEW core_latest_elixir_advisory job with job-level 'if: github.event_name != pull_request' (only matrix-toolchain PR exclusion); name matches isAdvisory(), toolchain-scoped cache key, LD-13 invariant in workflow + mix.exs.
- [Phase ?]: [130-02] OPEN A2: setup-beam v1.24.0 resolving '1.19'/'28' on ubuntu-latest is confirmable only by a live run; setup failure is advisory-acceptable (never blocks PR/publish).
- [Phase ?]: 132-01: Mailglass.Identifier is the single Postgres unquoted-identifier chokepoint; migration path delegates to it
- [Phase ?]: 132-01: Config.schema/0 uses :__miss__ sentinel self-heal; validate once at the cache-write boundary
- [Phase ?]: 132-02: MailglassInbound.Config.schema/0 mirrors core exactly (same default/validator/error/key/sentinel/warm_schema); reuses core Mailglass.Identifier — no inbound-local regex or error type; reads :mailglass_inbound env only (boundary law)
- [Phase ?]: 132-02: closed pre-existing gap — inbound validate_at_boot!/0 was defined but never called; now the first statement of Application.start/2 (fails fast at boot on a bad :schema). mix credo N/A in inbound (no credo dep); use compile --warnings-as-errors + format --check-formatted as the style gate
- [Phase ?]: FACADE-03 zero-code-change proof confirmed
- [Phase ?]: no admin lib changes needed; facade injects prefix: Config.schema() transparently
- [Phase ?]: D-06 split: dedicated integration test in Phase 133; full-suite CI matrix axis deferred to Phase 134 (raw-DDL qualification needed first)
- [Phase ?]: admin config/test.exs must pin :schema to 'public'; facade otherwise injects prefix:'mailglass' on all ops and citext probe exhausts
- [Phase ?]: [134-01] Migration.up/down inject prefix: Config.schema() via Keyword.put_new (MIGR-01); migrated_version/1 untouched.
- [Phase ?]: [134-01] maybe_create_schema/1 is up/1 first action (gated create_schema, honors create_schema: false); maybe_drop_schema/1 fires only at teardown version 0 with DROP SCHEMA RESTRICT never CASCADE (MIGR-02).
- [Phase ?]: [134-01] Non-public-prefix down full round-trip + citext/trigger qualification deferred to 134-02; 134-01 proves DROP SCHEMA RESTRICT via the exact emitted DDL to avoid corrupting shared public.citext mid-suite.
- [Phase ?]: 137-01: 2.0 reference-baseline lock regen deferred to Plan 02 post-publish; mix.exs pins landed now
- [Phase ?]: 137-01: reference baseline adopts mailglass default schema (no :schema public pin) per D-07
- [Phase 138]: Explicit per-operation Ecto prefix opts on raw callback repo calls — Repo.multi_opts() is the correctness mechanism for raw Ecto.Multi callback reads/writes; connection search_path remains only test/host convenience.
- [Phase 138]: Source-contract assertions accompany hostile runtime schema-prefix tests — The replay runtime proof can pass through Ecto-loaded prefix metadata before explicit raw callback opts are present, so source-contract assertions keep the focused lane fail-closed.
- [Phase 138]: Keep MailglassInbound.Repo as the default facade for inbound replay extension points; supplied raw repos receive explicit local schema opts.
- [Phase 138]: Inbound raw-repo prefix contract tests use capture repos and avoid subject/body/header/raw MIME diagnostics.
- [Phase 138]: Projection Multi writes in the fake adapter and webhook reconciler are schema-prefix-sensitive and must pass per-operation prefix opts. — Ecto.Multi operation opts do not inherit from the transaction executor; explicit Repo.multi_opts() keeps these writes independent of connection search_path.
- [Phase 138]: RawRepoPrefixContract is production-path scoped and treats Repo.multi_opts(), schema_opts(), prefix:, and configured local prefix opts helpers as compliant. — The guard must catch recurrence without creating noisy false positives in tests, migrations, or existing facade-owned prefix helpers.
- [Phase 138-04]: Expose Phase 138 proof as mix verify.schema_prefix, a focused lane rather than a full dual-schema matrix or full-suite alias.
- [Phase 138-04]: Document the dual-schema advisory matrix as broad canary coverage because its harness aligns Config.schema/0 and connection search_path.
- [Phase 138-04]: Use cmd mix test for the second root ExUnit file in verify.schema_prefix so Mix task deduplication cannot skip the RawRepoPrefixContract test.

## Quick Tasks Completed

| Date | Task | Files |
|---|---|---|
| 2026-06-17 | Classify "Demo Browser Evidence" as advisory in `publish-hex.yml` `gate-ci-green` (added to `ADVISORY_LANES` — non-required browser lane predates the `<name> Advisory (...)` convention, would have wrongly blocked a release) | `.github/workflows/publish-hex.yml` |
| 2026-06-18 | Triage + merge held dep PRs (thread item 4): #76 premailex 0.3.20→**1.0.0** (major — validated `to_inline_css/1` unaffected, renderer suite 20/20 green locally; `9c3bbfea`) + #75 swoosh 1.26.0→**1.26.1** (root-lock-only patch, NOT trust-lane-coupled; `50b49206`). Both stale `Compile No Optional Deps` reds were a transient ex_doc dep-cache race, cleared by update-branch + rerun. | `mix.exs`, `mix.lock` (via PR merges) |
| 2026-06-18 | Fix-or-retire `Core Full Suite Advisory` (thread item 5) → **FIX**. Permanently-red lane's 9 failures were all workspace-only dev tooling (reference-host/demo/post-publish-smoke needing sibling MailglassInbound + reference-app deps), NOT lib regressions. Tagged 5 modules `@moduletag :requires_workspace` + `--exclude` in the lane (it's the ONLY lane running the full core `mix test` — ~120 lib files no required lane covers, so retiring was wrong). Lane now **green** (`abadbb32`). | 5 test files, `.github/workflows/advisory-matrix.yml` |
| 2026-06-18 | De-hardcode trust-lane baseline (thread item 2) so dep/version bumps are **zero-touch**. Clean-baseline guard + contract test were version-coupled (hardcoded `1.4.5` literals → 5-file hand-edit every release). Made guard assert `:hex` source + well-formed version (no literal), test version-agnostic, widened pins `~> 1.4`→`~> 1.0`, refreshed both reference locks 1.4.5/1.4.5/1.1.5 → **1.7.0/1.7.0/1.4.0**. host_app compiles clean; both Trust Lane CI jobs green (`7cbef50b`). | 2 mix.exs, 2 mix.lock, `check_clean_baseline_hex_only.sh`, `ci_trust_lane_contract_test.exs` |
| 2026-06-30 | **Fix shipped-migration divergence (live correctness bug; 1.10.2 owed).** Surfaced by the quality/CI/PG-schema audit (`/Users/jon/.claude/plans/software-quality-evaluation-prompt-txt-purring-bunny.md`). The shipped dispatcher (`@current_version 4`) created `mailglass_deliveries` WITHOUT `idempotency_key`/`status`/`last_error` + the deliveries idempotency partial unique index that the runtime (`delivery.ex:112-122`, `outbound.ex` upsert) requires — those existed ONLY in the internal TestRepo migration, so CI was green while fresh adopter installs broke. Reproduce-first: new adopter-path test failed RED (`42703 column "idempotency_key" does not exist`) at HEAD, GREEN after V05. Added `v05.ex` (prefix-threaded, where-clause matches `outbound.ex` conflict_target char-for-char), bumped `@current_version` 4→5, reconciled the TestRepo `00000000000002` migration onto the V05 single source of truth. PR #100 merged; **SHIPPED to Hex as 1.10.2/1.10.2/1.5.4 on 2026-07-01** (publish run `28525073712`). Release recovery needed 3 tag-move cycles: (1) `.planning/publish/mailglass-files.expected` was missing v05.ex (allowlist gate — only runs at release, not in PR CI → Milestone-1 gap); (2) the inbound `{:mailglass, "== X"}` exact-pin ordering trap (`stability_contract_test` requires pin==core@version; core only bumps inside the release PR → the re-pin must land direct-to-main as a transient-red SHA → Milestone-1 P0: switch to `~>`); (3) admin lock carried retired `plug 1.20.1` (→ 1.20.2). **Audit finding for the schema-isolation milestone:** V01's events immutability trigger is hard-bound to `public` (`ON mailglass_events`, not prefix-qualified) — confirmed it collides under a non-public prefix; left untouched (out of scope), tracked for Milestone 2. | `lib/mailglass/migrations/postgres/v05.ex` (new), `postgres.ex`, `test/mailglass/shipped_migration_divergence_test.exs` (new), `migration_test.exs`, `priv/repo/migrations/00000000000002_*.exs` |

## Performance Metrics

**Velocity:**

- Phase 123 Plan 01: 2 tasks, 3 files, ~3 min — ratchet promoted+re-scored only-forward (run_id 2026-06-28-phase-123, ratchet_baseline_test 4/4 green); two judgment gates armed (de-disclaim + floor inventory ~26→~28); priv/static byte-unchanged
- v1.9 phases completed: 6 (85-90), 7 plans — shipped 2026-06-12, gate 9/9 first run, maintainer A/B sign-off
- v1.8 phases completed: 3 through GSD (80-82), 5 plans; phases 83-84 closed superseded 2026-06-11
- v1.7 phases completed: 6 (74-79), 22 plans — admin UI IA & design-system polish v2; audit passed (19/19 reqs, 7/7 seams, 3/3 flows); shipped 2026-06-05
- v1.6 phases completed: 3 (71-73), 6 plans, 5 tasks
- v1.5 phases completed: 4 (67-70), 8 plans, 14 tasks
- v1.4 phases completed: 4 (63-66), 12 plans, 22 tasks

## Deferred Items

Items acknowledged and deferred at the v1.7 milestone close on 2026-06-05:

| Category | Item | Status |
|----------|------|--------|
| seed | 003-ecosystem-integrations | dormant |
| uat | Phase 76 — 76-HUMAN-UAT.md (4 browser-visual scenarios) | resolved-downstream |
| verification | Phase 76 — 76-VERIFICATION.md | resolved-downstream |

Items inherited at the v1.8 close-superseded on 2026-06-11 (now owned by v1.9):

| Category | Item | Status |
|----------|------|--------|
| asset | `brandbook/` wordmark is live `<text>` in macOS-only Avenir Next | superseded-by-v1.9 (LOGO-08: outlined paths only) |
| tokens | `brandbook/tokens.json` planning-language leakage | superseded-by-v1.9 (FOUND-04, GATE-01 denylist grep) |
| a11y | contrast validation never ran in v1.8 | superseded-by-v1.9 (FOUND-03, BOOK-06, GATE-01) |
| dark | dark tokens exist but undemonstrated | superseded-by-v1.9 (BOOK-04 toggle re-skins every specimen) |

**Guardrail:** do not auto-promote `SEED-003-ecosystem-integrations` at milestone open. Re-rank against adopter-impact wedges first.

Items acknowledged and deferred at the v1.10 milestone close on 2026-06-13:

| Category | Item | Status |
|----------|------|--------|
| todo | refresh-outbound-admin-ui-look-and-feel (2026-06-13) | deferred — follow-up design-system milestone candidate (out of v1.10 scope) |
| uat | Phase 92 — 92-HUMAN-UAT.md | resolved (0 pending scenarios) |
| Phase 87 P01 | 49 minutes | 3 tasks | 12 files |
| Phase 88 P01 | 27min | 3 tasks | 4 files |
| Phase 89 P01 | 28min | 4 tasks | 10 files |
| Phase 91 P01 | 10 min | 2 tasks | 3 files |
| Phase 91 P02 | 3h 9m | 2 tasks | 71 files |
| Phase 91 P03 | 2 min | 2 tasks | 10 files |
| Phase 91 P04 | 1 min | 2 tasks | 1 files |
| Phase 92 P01 | 10 min | 3 tasks | 3 files |
| Phase 92 P02 | 38 min | 3 tasks | 4 files |
| Phase 94 P01 | 10 minutes | 2 tasks | 3 files |
| Phase 94 P02 | 5min | 1 tasks | 1 files |
| Phase 94 P03 | 6 | 3 tasks | 5 files |
| Phase 95 P02 | 10 minutes | 2 tasks | 3 files |
| Phase 95 P03 | 15 minutes | 1 tasks | 1 files |
| Phase 95 P04 | 600 | 3 tasks | 3 files |
| Phase 96 P01 | 18 | 1 tasks | 1 files |
| Phase 96 P02 | 22 | 1 tasks | 1 files |
| Phase 96 P03 | 35 | 1 tasks | 1 files |
| Phase 96 P04 | 45 | 1 tasks | 1 files |
| Phase 96 P05 | 35 | 1 tasks | 1 files |
| Phase 97 P01 | 5min | 3 tasks | 1 files |
| Phase 97 P02 | 104 | 3 tasks | 5 files |
| Phase 97 P03 | 236 | 2 tasks | 3 files |
| Phase 97 P04 | 7min | 3 tasks | 0 files |
| Phase 97 P05 | 175 | 3 tasks | 3 files |
| Phase 97 P06 | 323 | 2 tasks | 2 files |
| Phase 97 P07 | 3min | 2 tasks | 1 files |
| Phase 97 P08 | 420 | 2 tasks | 3 files |
| Phase 97 P08 | 420 | 2 tasks | 3 files |
| Phase 98 P01 | 15 min | 3 tasks | 5 files |
| Phase 98 P02 | 8 min | 3 tasks | 3 files |
| Phase 98 P03 | 7 min | 3 tasks | 4 files |
| Phase 98 P04 | 23 min | 3 tasks | 11 files |
| Phase 99 P01 | 5 min | 2 tasks | 3 files |
| Phase 99 P03 | 5 min | 3 tasks | 6 files |
| Phase 99 P02 | 10 min | 3 tasks | 5 files |
| Phase 99 P04 | 51 min | 3 tasks | 7 files |
| Phase 99 P05 | 8 min | 3 tasks | 6 files |
| Phase 100 P01 | 11 min | 2 tasks | 6 files |
| Phase 100 P02 | 5 min | 3 tasks | 6 files |
| Phase 100 P03 | 9 min | 3 tasks | 4 files |
| Phase 101-microcopy-pass P01 | 85 | 1 tasks | 1 files |
| Phase 101 P02 | 6 minutes | 1 tasks | 1 files |
| Phase 103 P01 | 8 minutes | 2 tasks | 1 files |
| Phase 103 P02 | 11 minutes | 3 tasks | 3 files |
| Phase 103 P03 | 4min | 2 tasks | 1 files |
| Phase 103 P04 | 5min | 1 tasks | 2 files |
| Phase 106 P01 | 144 | 2 tasks | 2 files |
| Phase 106 P02 | 8 | 3 tasks | 3 files |
| Phase 107 P01 | 2min | 3 tasks | 4 files |
| Phase 109 P03 | 8 min | 2 tasks | 3 files |
| Phase 109 P04 | 9 min | 2 tasks | 3 files |
| Phase 110 P01 | 8 min | 2 tasks | 3 files |
| Phase 110-primitives P02 | 8 min | 3 tasks | 6 files |
| Phase 110-primitives P03 | 8 min | 2 tasks | 1 files |
| Phase 110-primitives P04 | 45min | 3 tasks | 6 files |
| Phase 111-forms P01 | 7min | 2 tasks | 3 files |
| Phase 111 P02 | 9min | 2 tasks | 7 files |
| Phase 111 P03 | 8 min | 2 tasks | 6 files |
| Phase 113 P01 | 10 minutes | 3 tasks | 3 files |
| Phase 113 P02 | 25 | 3 tasks | 2 files |
| Phase 113 P03 | 8 minutes | 3 tasks | 2 files |
| Phase 113 P04 | 24 | 3 tasks | 8 files |
| Phase 114 P01 | 6min | 3 tasks | 3 files |
| Phase 114 P02 | 12 min | 3 tasks | 4 files |
| Phase 114 P03 | 10 min | 3 tasks | 8 files |
| Phase 114 P04 | 5 min | 2 tasks | 2 files |
| Phase 116 P01 | 14min | 3 tasks | 7 files |
| Phase 116 P02 | 12 min | 3 tasks | 5 files |
| Phase 116 P03 | 18 min | 2 tasks | 1 files |
| Phase 116 P04 | 14min | 2 tasks | 3 files |
| Phase 116 P05 | 7 min | 3 tasks | 4 files |
| Phase 116 P06 | 17min | 3 tasks | 4 files |
| Phase 118 P01 | 11min | 3 tasks | 12 files |
| Phase 118 P02 | 4min | 2 tasks | 1 files |
| Phase 118 P03 | 33min | 2 tasks | 2 files |
| Phase 121 P01 | 24min | 3 tasks | 4 files |
| Phase 121 P03 | 7 min | 2 tasks | 2 files |
| Phase 121 P04 | 5min | 3 tasks | 3 files |
| Phase 122 P02 | 6 min | 3 tasks | 7 files |
| Phase 122 P03 | 3min | 2 tasks | 1 files |
| Phase 123 P02 | 3 | 2 tasks | 1 files |
| Phase 123 P03 | 8min | 2 tasks | 1 files |
| Phase 125 P01 | 1200 | 3 tasks | 17 files |
| Phase 126 P01 | 8 | 3 tasks | 3 files |
| Phase 128 P01 | 4 min | 5 tasks | 7 files |
| Phase 128 P02 | 4 min | 2 tasks | 4 files |
| Phase 130 P01 | 2 sessions | 3 tasks | 6 files |
| Phase 130 P02 | 9min | 3 tasks | 4 files |
| Phase 131 P01 | 2 sessions | 9 tasks | 8 files |
| Phase 132 P01 | 6min | 3 tasks | 5 files |
| Phase 132 P02 | 3min | 2 tasks | 3 files |
| Phase 133 P01 | 10 | 3 tasks | 8 files |
| Phase 133 P02 | 15min | 3 tasks | 5 files |
| Phase 134 P01 | ~13 min | 3 tasks | 3 files |
| Phase 134 P02 | ~18 min | 3 tasks | 3 files |
| Phase 134 P03 | 55min | 3 tasks | 10 files |
| Phase 138 P01 | 9 min | 2 tasks | 3 files |
| Phase 138 P02 | 5 min | 2 tasks | 4 files |
| Phase 138 P03 | 10 min | 2 tasks | 7 files |
| Phase 138 P04 | 3 min | 2 tasks | 2 files |

## Accumulated Context

### Roadmap Evolution

- 2026-06-26: v1.14 roadmap created. Phases 118-124, numbering continues from v1.13 (last phase 117). All 14 REQ-IDs mapped to exactly one phase, 100% coverage (METHOD-01/02 + STORY-01/02 → 118; SHELL-01/02/03 → 119; DELIV-01 → 120; INB-01 → 121; PREV-01 → 122; COH-01/02 → 123; REL-01/02 → 124). Follows the maintainer-approved seed (`.planning/research/v1.14/MILESTONE-SEED.md` P0-P6) one-to-one: top-down, JTBD/IA-led, biggest-impact-first. Strictly sequential critical path 118 → … → 124. Binding sequencing: (1) Phase 118 (adversarial persona-critic harness + screenshot-backed defect register) is a HARD precondition for the keystone shell redesign (119) — the hit-list drives every surface redesign; (2) each surface redesign (120 → 121 → 122) inherits the prior surface's cleaned-up patterns; full pillar re-score + new judgment-gate arming (nav-active-correctness, no-nav-duplication) happens ONLY in Phase 123; release cut last (124). Cross-cutting acceptance criteria (light/dark/system × 320→wide × happy/empty/error/boundary; WCAG 2.2 AA; Emil-Kowalski motion; on-brand microcopy; idempotent only-forward inheriting the v1.13 ratchet floor) baked into every surface phase. Research flags: Phase 118 (persona-critic harness design + `phoenix_storybook` sandbox-CSS integration, `only: :dev`) + Phase 119 (GOV.UK IA + overview-as-triage) need light `/gsd-plan-phase` research; 120-124 plan directly. Release ACTUALLY CUT at close (D-28): admin-minor drags matched core+inbound; D-13 inbound exact-pin re-pin.
- 2026-06-18: v1.13 roadmap created. Phases 109-117, numbering continues from v1.12 (last phase 108). All 36 REQ-IDs mapped to exactly one phase, 100% coverage (REL-01 precondition + FND-01..05 → 109; PRIM-01..07 → 110; FORM-01..03 → 111; SHELL-01..06 → 112; DATA-01..05 → 113; GROUP-01..03 → 114; FLOW-01..04 → 115; RATCHET-01..05 → 116; REL-02..03 → 117). Adopts the research-converged, adversarially-grounded dependency-ordered fractal build order A–H from `.planning/research/v1.13/SUMMARY.md`, mapped to 109–116, with H's release reqs split into a dedicated closeout phase 117 (v1.12 precedent) for cleaner success criteria. Strictly sequential critical path 109 → … → 117. Two binding sequencing constraints encoded as explicit dependencies: (1) merge PR #86 (REL-01) BEFORE Phase 109; (2) tighten gates BEFORE re-baselining — gates tightened inside each phase, full pillar re-score ONLY in Phase 116. RATCHET-01 multi-tenant stress cohort is the keystone dependency: lands late (116) but gates the final score. Research flags: Phase 112 (core `list_tenants` projection shape) + Phase 116 (axe-JSON baseline format + ratchet schema-v3 cell-count) need light `/gsd-plan-phase` research; 109/110/111/113/114/115 plan directly. Release ACTUALLY CUT at close (D-28): admin-minor drags matched core+inbound via linked-version releases; D-13 inbound exact-pin re-pin.
- 2026-06-13: v1.11 roadmap created. Phases 94-103, numbering continues from v1.10 (last phase 93). All 34 REQ-IDs mapped to exactly one phase, 100% coverage (TOKEN-01..05 + RATCHET-03 → 94; RATCHET-01/02/04/05 → 95; RESEARCH-01..05 → 96; COMP-01..03 + GALLERY-01/02 → 97; cross-surface GROUP-01/PAGE-01/02/RESP-01/FLOW-01/02/A11Y-01/02 anchored on operator → 98; GROUP-02/03 → 99; PAGE-03 → 100; COPY-01 → 101; MOTION-01/02 → 102; 103 is closeout-only). Critical path 94 → 95 → 96 → 97 → {98,99,100 parallel} → {101,102 parallel} → 103. Cross-cutting GROUP/PAGE/RESP/FLOW/A11Y reqs counted once at their operator anchor (98) and re-applied per-surface on 99/100. Phase 94 tightens conformance gates FIRST (tighten-then-re-baseline) so the token re-baseline can't regress silently. Release prepare-only; admin-minor bump drags matched core+inbound via linked-version releases.
- 2026-06-12: v1.10 roadmap created. Phases 91-93, numbering continues from v1.9 (last phase 90). All 10 REQ-IDs (FOLD-01..03 → 91, SURF-01..03 → 92, HEXD-01..02 + RELH-01..02 → 93) mapped to exactly one phase, 100% coverage. Strictly linear critical path 91 → 92 → 93. RELH-02 flagged potentially blocked-on-external (in-flight release train must settle). Adoption mechanics pre-settled in `.planning/research/v1.10-brand-adoption/ADOPTION-MECHANICS.md`.
- 2026-06-11: v1.9 roadmap created. Phases 85-90, numbering continues from v1.8 (last phase 84). All 22 REQ-IDs (BRIEF/FOUND/LOGO-05..08/BOOK-04..07/COLL/COPY/GATE) mapped to exactly one phase, 100% coverage. Strictly linear critical path. Phase 87 carries a hard maintainer-selection pause with a two-rejection circuit breaker. Research pre-settled token format, contrast fixes, and SVG portability rules in the fable brandbook research summary.
- 2026-06-11: v1.8 closed superseded (audit verdict gaps_found, accepted). Residual gaps inherited by v1.9; `brandbook/` frozen at `09a84dd4` as the A/B baseline.
- 2026-06-03: v1.7 milestone opened. Roadmap created for Phases 74-79. Phase numbering continues from v1.6 (last phase 73). All 19 REQ-IDs mapped to exactly one phase with 100% coverage.
- 2026-06-03 convergence posture: after v1.7, default posture returns to maintenance/quiet unless concrete adopter pull or contract gap says otherwise. v1.8/v1.9 brand milestones are repo-artifact work, not product expansion.

### Pending Todos

- **Fix `post-publish-smoke` `wait-for-index` missing checkout step** — The `wait-for-index` job uses `version-file: .tool-versions` in `setup-beam` but has no `actions/checkout` step. Works on scheduled runs (runner workspace reuse), fails on dispatch/release paths (fresh runners). Maintenance-tier fix: add a checkout step to `wait-for-index`. Low priority — scheduled smoke still runs nightly; consumer smoke is the SHIP-02 proof.
- **Remove the cowlib advisory allowlist when upstream fixes** (`.planning/todos/pending/2026-06-30-remove-cowlib-advisory-allowlist-when-upstream-fixes.md`) — v1.14 added a narrow temporary allowlist in `publish.check` for 2 unfixable cowlib advisories (EEF-CVE-2026-43966/43969). Maintenance-tier `/gsd-quick` when cowlib ships a patch.
- **Run the UI browser/persona gate during phases, not only at release** (`.planning/backlog/ui-browser-gate-during-phases-not-only-at-release.md`) — v1.14 post-mortem: deferred phase verification let 7 browser-gate regressions reach the release ceremony. Fold into the next admin-UI milestone's method; surface via `/gsd-review-backlog`.
- ~~Refresh outbound admin UI look and feel~~ — superseded by v1.11's fractal three-surface uplift + v1.14 operator IA redesign (resolved; the 2026-06-13 todo file is stale).

## Pre-existing Cleanup Backlog (Not v1.10 Scope)

`.planning/phases/` still contains leftover backlog phase directories (999.1, 999.2) from earlier milestones. Run `/gsd-cleanup` before active phase execution if name-collision risk appears.

## Session Continuity

**Last session:** 2026-07-07T14:12:01.971Z
**Stopped at:** Completed 138-04-PLAN.md
**Resume file:** None

- 2026-06-19: **Phase 111 context gathered in assumptions mode.** Decisions captured in
  `.planning/phases/111-forms/111-CONTEXT.md`; audit trail in
  `.planning/phases/111-forms/111-DISCUSSION-LOG.md`. Locked: shared `filter_field` /
  `filter_section` ownership in `MailglassAdmin.Components`; mandatory operator/inbound filter
  extraction plus audit/certification of existing authored admin form controls; explicit
  label/help/error/`aria-describedby`/`aria-invalid` contracts; honest disabled vs read-only
  semantics; stable DOM identity for normal LiveView filter patch focus retention; existing
  component/gallery/Playwright/conformance proof only, no pixel diff or runtime dependency. Next:
  `/gsd-plan-phase 111`.

- 2026-06-18: **Phase 110 complete.** Public primitives landed in
  `MailglassAdmin.Components` (`nav_link`, `nav_pill`, `tenant_chip`, `theme_picker`,
  `stat_card`), real shell/overview surfaces and the gallery consume them, and fail-closed
  primitive drift/stat-card/icon inventory gates plus compiled-browser structural proof are
  active. Verification passed 7/7 PRIM requirements with no human UAT. Next intended v1.13
  phase: Phase 111 Forms; leftover backlog directories 999.1/999.2 are not the active
  milestone path.

- 2026-06-18: **Phase 110 context gathered in assumptions mode.** Decisions captured in
  `.planning/phases/110-primitives/110-CONTEXT.md`; audit trail in
  `.planning/phases/110-primitives/110-DISCUSSION-LOG.md`. Locked: public primitive ownership in
  `MailglassAdmin.Components`; 3-way theme picker as radio-group/segmented semantics with `system`
  as absence of explicit theme; canonical `stat_card` plus STATCARD/icon-exists gates; WCAG 2.2
  AA 24x24 target-size gate with the roadmap's 44x44 floor preserved unless a documented dense
  exception/GAP is recorded. Next: `/gsd-plan-phase 110`.

- 2026-06-18: **Phase 109 complete.** Plan 04 added structural system/default theme proof, WCAG-style focus/target-size assertions, operator+inbound replay modal `elementFromPoint` hit-tests, and final no-scope-creep validation. Auto-fixed preview theme/frame icon buttons with `min-w-11` to satisfy the 44px target floor; CSS bundle rebuilt and clean. Final proof green: PR #86 merged, conformance OK, ratchet 4/4, support contract 59/59, verify.preview 256/256 with 1 excluded, browser 58/58, package manifests unchanged, no axe/screenshot/theme-hook creep. Next: Phase 110 primitives ready to plan.

- 2026-06-18: **Phase 109 Plan 03 completed.** Tightened `check-conformance.sh` with z-index, focus-ring, root-isolation, token-scope, radius, shadow, border, and arbitrary-size gates; bumped the ratchet baseline to schema v3 with light/dark/system cells seeded from existing light scores. Verification green: root/package conformance, focused ratchet ExUnit, and JSON run-id/system-shape assertion. Next: execute Phase 109 Plan 04 structural WCAG/system proof and final validation.

- 2026-06-18: **v1.13 "Admin Design-System Stress Test & UX Uplift (v3)" roadmap created.** `.planning/ROADMAP.md` rewritten with v1.13 as the active milestone (Phases 109-117 full detail; v1.11/v1.12 collapsed into archived `<details>`), `.planning/REQUIREMENTS.md` traceability finalized to phase numbers (36/36 mapped 109–117, 0 unmapped), STATE.md updated (frontmatter total_phases=9, position at Phase 109 ready-to-plan, v1.13 intent/scope-locks/roadmap-snapshot). Numbering continues from v1.12's last phase 108. Next: merge PR #86 (REL-01 binding precondition), then `/gsd-plan-phase 109` (or `/gsd-discuss-phase 109` first).

- 2026-06-17: **Repo-hygiene pass (no milestone, no Hex publish).** Got local git + GitHub + CI + GSD
  into a clean known-good state. Pushed the 3 unpushed `main` commits (incl. the `/gsd-quick` Demo
  Browser Evidence classifier fix `1e0e60b1`); main CI green. Triaged open PRs **6 → 2**: merged the
  4 safe patch bumps via maintainer admin-override (#74 actions/checkout 6.0.3, #77 ex_doc 0.40.3,
  #78 credo 1.7.19, #83 phoenix_live_view 1.1.32 — squash; final combined HEAD `cba0351d` CI green);
  **held #75 swoosh + #76 premailex OPEN** with hold comments (baseline coupling / major bump).
  Deleted both obsolete local `preserve/*` branches (local-only). Confirmed clean: working tree, 0
  stashes, single worktree, 0 open issues, GSD `status: shipped`. **Durable gotcha:** dependabot PRs
  stay `BLOCKED` pending the 1 required review even with all checks green; `enforce_admins: false` so
  approve + `gh pr merge --admin --squash` is the path (only required status check is
  `guard-release-trigger`). **Two open follow-ups parked** in `release-pipeline-maintenance.md`
  "NEXT-SESSION FOCUS": (A) held PRs #75/#76 dependency review; (B) `Core Full Suite Advisory`
  fix-or-retire. Next: fresh session, `/gsd-quick` either item.

- 2026-06-17: **Post-v1.12 next-step assessment run (NO milestone opened).** Repo-local: one thorough
  source-sweep agent across all 3 packages + direct reads of PROJECT/ROADMAP/STATE/threads/v1.12 audit.
  **Verdict: the last adopter wedge (onboarding/day-2) is closed and the release is cut; ~93–95% done;
  no recommended next feature milestone; default to quiet maintenance.** Bookkeeping written: closed
  `adopter-onboarding-day2-confidence.md` (exit signal met); refreshed `project-convergence-posture.md`
  (post-v1.12 read + release implication RESOLVED) and `transport-expansion-watchlist.md` (review
  date); opened `release-pipeline-maintenance.md` for the two maintenance-tier follow-ups; added three
  ASSESS-2026-06-17 decisions + refreshed Operator Next Steps. Shift-left: added
  `preferences.milestone_discovery.research_lens` to config.json (low-risk). No feature code touched.
  Next: maintainer's call — quiet maintenance, or `/gsd-quick` one of the pipeline-maintenance items.

- 2026-06-17: **v1.12 SHIPPED — Phase 108 complete, milestone closed.** Cut the first real linked-version Hex release since 1.6.2: **mailglass 1.7.0 / mailglass_admin 1.7.0 / mailglass_inbound 1.4.0 live on Hex**, inbound + admin re-pinned `{:mailglass, "== 1.7.0"}` (D-13 / REL-02). Release commit `0411d485`, PR #84. The v1.7–v1.12 body had never hit full CI (local phase execution only); pushing it before merging surfaced + fixed **six pre-flight CI regressions**: format (doctor/test files), Installer Host Smoke (fail-closed installer correctly blocked stock endpoint → smoke uses `--force`), Dialyzer (`mailglass.doctor` `run/1` no_return suppressed), ex_doc (guides linked unregistered files + wrong `resolve_outbound_adapter_ref` arity), `mix mailglass.docs.check` (stale `~> 0.3` token vs phase-105 `~> 1.6`), and Demo Browser Evidence (v1.11 responsive split → Playwright strict-mode locator). Publish fan-out raced (one run/release-event; two `publish-core` race-losers + a post-publish-smoke index-timeout — all disproven against Hex; re-dispatched smoke green). Hands-free auto-merge didn't fire (advisory lanes red + RP cron churn); merged via maintainer admin-override after explicit go/no-go, all required checks green. Consumer smoke proved Hex resolution + `install --force`. Milestone archived (`v1.12-{ROADMAP,REQUIREMENTS,MILESTONE-AUDIT}.md`); MILESTONES/PROJECT/ROADMAP/RETROSPECTIVE updated; REQUIREMENTS.md removed; tag `v1.12`. **Follow-up:** harden `publish-hex.yml` `gate-ci-green` `isAdvisory()` to classify "Demo Browser Evidence" advisory by name. Next: `/gsd-new-milestone`.

- 2026-06-17: **Phase 106 Plan 02 completed.** Registered both day-2 guides in `mix.exs` `extras:` and `Guides:` group (2 occurrences each). Added 4 new OPS-01/OPS-02 docs-contract assertions to `docs_contract_test.exs` (registration x2, section-presence checklist, error-coverage all-ten). Corrected `docs/api_stability.md`: "six" → "ten" error structs + `Mailglass.StreamPolicyError` added to stable list. 32 tests, 0 failures, 1 pre-existing skip. Commits: 90c7f562 (mix.exs) + ec6a834b (contract tests) + 6c7c51f3 (api_stability.md). **Phase 106 complete.** Next: execute Phase 107 (Inbound Replay-Modal A11y Parity).

- 2026-06-17: **Phase 106 Plan 01 completed.** Created `guides/production-go-live-checklist.md` (7-section go-live checklist: deliverability/mail.doctor, webhook wiring/mailglass.doctor, secret provisioning, Oban queue sizing, per-tenant adapter routing, suppression strategy, telemetry) and `guides/errors-and-troubleshooting.md` (10-section unified error struct map in @error_modules order, StreamPolicyError sourced from module, all sections routing to api_stability.md) — OPS-01/OPS-02. Commits: fdace05a (checklist) + 146bec54 (errors guide). Next: execute Phase 106 Plan 02 (mix.exs registration + docs-contract assertions).

- 2026-06-17: **Phase 105 Plan 03 completed.** Reordered `guides/getting-started.md` to end on `## Next steps` — updated 401 troubleshooting entry to reflect Phase 104 fail-closed behavior (`Mix.raise`, `--force` escape hatch, `mix mailglass.doctor` verification) — DOCS-02. Added `## Next steps` section with 6-step week-one arc (jobs → authoring-mailables → preview → webhooks → testing → telemetry) and link to `learning-path.md`. Added `"Getting Started ends on a Next steps section"` contract assertion to `docs_contract_test.exs` (Regex.scan `~r/^## (.+)$/m` + List.last + link/doctor checks). 28 tests, 0 failures, 1 skip. Commits: d5658a27 (guide reorder) + 7591cfbd (contract assertion). Phase 105 complete. Next: execute Phase 106 (Day-2 Guides).

- 2026-06-17: **Phase 105 Plan 02 completed.** Fixed README Quickstart with config-first `config :mailglass` block (verbatim from getting-started.md, repo: + adapter: + telemetry:, framed as installer-generated confirmation) — DOCS-01. Added `guides/learning-path.md` bullet to README Documentation index. Updated `guides/migration-from-swoosh.md` with value-prop opener paragraph ("Swoosh handles transport; mailglass adds the framework layer…" with all 7 keywords) before subordinate-reference framing; bumped stale `~> 0.3` dep pins to `~> 1.6` — DOCS-04. Added two new docs_contract_test.exs assertions: "Quickstart contains a config-first block before the deliver() example" (byte-offset ordering) and "migration-from-swoosh opens with the value-prop pitch before subordinate framing" (7 keywords + refute ~> 0.3). 27 tests, 0 failures, 1 skip. Commits: dbc906d9 (README) + 7375be20 (migration guide) + 7dc19714 (test assertions). Next: execute Phase 105 Plan 03.

- 2026-06-17: **Phase 105 Plan 01 completed.** Created `guides/learning-path.md` (49-line ordered week-1 arc: getting-started → jobs → authoring-mailables → preview → webhooks → testing → telemetry; plus going-deeper section). Registered `"guides/learning-path.md"` in both `mix.exs` `extras:` and `groups_for_extras: [Guides: ...]` immediately after getting-started. Added `"learning-path is registered in both mix.exs docs lists"` test to `docs_contract_test.exs` (Regex.scan count >= 2 + File.exists? assertions). All 25 docs-contract tests green (1 pre-existing skip). Commits: 1830b79a (guide) + 309d0584 (registration + test). Next: execute Phase 105 Plan 02.

- 2026-06-17: **Phase 104 Plan 02 completed.** All 104-01 RED tests turned GREEN: fail-closed `validate_preflight/1` in `apply.ex` (returns `{:error, {:unmanaged_parser_conflict, path}}` without `--force`, `:ok` with `--force` or no conflict); threaded as first `with :ok <-` link in `Apply.run/2`; `format_error/1` clause added with actionable message naming endpoint path, silent-401 risk, `CachingBodyReader` fix, and `--force`. `Mailglass.Installer.Doctor` created (static `File.read!` scan, no app boot, three-state exit mapping); `Mix.Tasks.Mailglass.Doctor` created (Boundary-classified, thin CLI shell). 17 installer lane tests green; `mix compile --warnings-as-errors` clean; `mix credo --strict` clean. Commits: 194fc8b2 (apply.ex + mailglass.install.ex) + 29ae7bc4 (doctor.ex + mailglass.doctor.ex). Phase 104 complete. Next: execute Phase 105 (Onboarding Docs: Quickstart Fix + Learning Arc).
- 2026-06-17: **Phase 104 Plan 01 completed.** RED test files for INSTALL-01/02/03 created: `install_fail_closed_test.exs` (3 tests, 2 failures — tuple and task-level non-zero-exit assertions; INSTALL-02 `--force` ordering passes as expected) and `mailglass_doctor_test.exs` (3 tests, 3 failures — `UndefinedFunctionError` for `Mailglass.Installer.Doctor` module). Both files compile, run, and are RED for the right reasons. Commits: d631b56d (fail-closed test) + fa78adff (doctor test). INSTALL-01..04 requirements marked complete. Next: execute Phase 104 Plan 02 (implementation).

- 2026-06-16: **Next-milestone-step assessment run (no milestone opened).** Repo-local, 3 parallel
  Explore agents (adopter onboarding / real shipped surface / strategic frontier) + direct reads.
  Verdict: mailglass is feature-complete for its scope (~88–90% overall, ~92% code axis); the single
  highest-leverage remaining wedge is **adopter onboarding / day-2 DX** (broken README quickstart,
  silent webhook-`Plug.Parsers` 401 footgun, no week-1 arc, no go-live checklist, scattered error
  docs) + **cutting the staged release** (v1.7–v1.11 prepare-only, not on Hex). Everything else
  (core-component uplift, SEED-003, transport expansion, more providers) is diminishing-returns /
  pull-gated. Bookkeeping written: new thread `adopter-onboarding-day2-confidence.md`; resolved
  stale threads `inbound-stability-lock-prep` + `next-milestone-adopter-trust-proof`; review-stamped
  `transport-expansion-watchlist`; refreshed `project-convergence-posture` to post-v1.11; STATE
  Decisions + PROJECT candidate-list re-ranked; JTBD-COVERAGE.md staleness banner added; two
  low-risk config prefs added (writeback `refresh-jtbd-coverage-if-stale`, `done_lens`). No feature
  code touched. Next: maintainer kicks off `/gsd-new-milestone` with the onboarding/day-2 wedge.

- 2026-06-16: **v1.11 mailglass_admin Design-System Uplift SHIPPED + archived.** Milestone audit `status: passed` (34/34 requirements, 10/10 phases, 16/16 integration, 7/7 flows). Archived `milestones/v1.11-ROADMAP.md` + `v1.11-REQUIREMENTS.md` + `v1.11-MILESTONE-AUDIT.md`; MILESTONES.md/PROJECT.md/ROADMAP.md/RETROSPECTIVE.md evolved; `REQUIREMENTS.md` removed (fresh for next milestone); tagged `v1.11`. Stats corrected to true scope (10 phases / 42 plans) — the `milestone.complete` CLI inflation was avoided by archiving manually. Release prepare-only (no Hex cut); PENDING inbound exact-pin re-pin (D-13) deferred until a real release. Next: `/gsd-new-milestone`.
- 2026-06-16: Phase 103 Plan 03 completed. Full 6-gate battery confirmed green (2026-06-16-phase-103): support_contract.admin 56/56, verify.preview 236/236 (bundle-clean), conformance OK, conformance-advisory OK, motion OK, Playwright structural 54/54 (0 skips — Phase 102-03 fixme completed). Release posture 1.6.2/1.6.2/1.3.1 verified read-only; RELH-01 intact; inbound re-pin recorded as single PENDING ceremony action (D-13, deliberately not performed). Prepare-only readiness note written as 103-03-SUMMARY.md. Next: execute Phase 103 Plan 04 (milestone audit regeneration — D-14/D-15 LAST step).
- 2026-06-16: Phase 102 Plan 02 completed. --ease-symmetric: var(--ease-in-out) token added to @theme; .motion-tab-swap switched to var(--ease-symmetric) (MOTION-LD-05); MOTION-LD-06 resolution documented in :root duration block (focus rings → --duration-instant 90ms, hover → --duration-fast 150ms). .mg-skeleton connection-state placeholder (opacity-only, .phx-loading/.phx-connected CSS class selectors — confirmed against LV 1.1.28 runtime). @view-transition PE inside @media (prefers-reduced-motion: no-preference). priv/static/app.css rebuilt bit-clean. Both conformance gates clean; Playwright reduced-motion 4/4 pass. Next: execute Phase 102 Plan 03 (phx-remove exit attribute on operator/inbound).
- 2026-06-16: Phase 102 Plan 01 completed. MOTION-GATE added to check-conformance.sh (two grep passes: layout-property transitions MOTION-LD-10, stray ease-in MOTION-LD-01); exits 0 on clean tree, exits 1 on both probes. structural.spec.js extended: computed-duration assertion (animationDuration/transitionDuration ≤ 0.05s under emulateMedia reduced-motion — MOTION-02 proof) + FACT 7 enter/exit asymmetry describe block with test.fixme pending 102-03. 40/41 structural tests pass, 1 skipped (fixme). Next: execute Phase 102 Plan 02 (CSS/HEEx motion uplift).

- 2026-06-14: Phase 97 Plan 08 completed. structural.spec.js gallery describe block un-skipped with 5 real getByTestId + twin-theme assertions; GAP-05 flipped to fixed in RATCHET-GAP-REGISTER.md; 3 gallery_live.ex specimen data bugs fixed (NaiveDateTime→DateTime, missing occurred_at, string→atom sidebar scenario keys) — Playwright gallery tests 5/5 green. Phase 97 is complete (8/8 plans done); next: Phase 97 verification then Phase 98.

- 2026-06-14: Phase 96 Plan 04 completed. DARK-MODE.md dossier created at `.planning/research/v1.11/DARK-MODE.md` with 8 DARK-LD-NN locked decisions. Codebase-grounded: extracted all [data-theme="dark"] tokens from brandbook/tokens.css with computed WCAG contrast ratios. Critical finding: --mg-color-border #315069 fails WCAG 1.4.11 (2.06:1 on dark surface) — DARK-LD-02 locks mandatory upgrade to border-input #62809A in app.css mailglass-dark theme block. Focus-ring Ice #A6EAF2 confirmed (12.98:1 min on base, 8.40:1 worst-case on selected — all pass). Phase 86 dark-feedback figures confirmed verbatim (DARK-LD-05). GAP-03 (preview ignores dark theme) prescription locked: preview_live.ex data-theme already wired at line 225; Phase 100 must confirm handle_params path and produce visual diff (DARK-LD-06). OS dark-mode integration: do not force dark_chrome:false at mount; defer to daisyUI prefersdark:true (DARK-LD-08). RESEARCH-04 marked complete. Next: execute 96-05 (Microcopy dossier).
- 2026-06-14: Phase 96 Plan 03 completed. COMPONENT-STATES.md dossier created at `.planning/research/v1.11/COMPONENT-STATES.md` with 22 STATE-LD-NN locked decisions. Full D-09 archetype inventory (22 archetypes) enumerated from real codebase with file:line citations. Key decisions: STATE-LD-05 status_badge display-only with all 22 atoms locked; STATE-LD-06 nav_link/nav_pill focus-ring addition (WCAG 2.4.7); STATE-LD-13 filters_form drops tracking-[0.08em] (GAP-04); STATE-LD-14 support_cards removes btn-sm from CTA buttons (GAP-01); STATE-LD-17 replay_modal a11y additions (aria-labelledby + Escape + focus trap); STATE-LD-18/19 corrects D-09 conflation (routing_trace has no reveal; evidence_card owns redacted/revealed/denied). RESEARCH-03 marked complete. Next: execute 96-04 (Dark-mode pitfalls dossier).
- 2026-06-14: Phase 96 Plan 02 completed. IA.md dossier created at `.planning/research/v1.11/IA.md` with 9 LOCKED DECISIONS (IA-LD-01..09). Decisions lock: master-detail split by viewport (390px stacked/768px 40-60/1440px 33-67), filter disclosure mobile-only toggle (LiveView.JS), filter labels use text-label token (GAP-04 close signal via IA-LD-04), orientation strip placement per viewport and surface, inbound overview/at-a-glance tier spec (GROUP-02 IA layer via IA-LD-09), Preview sidebar uses native <details>/<summary>, empty/loading state placement rules (GAP-02 reference via IA-LD-07). RESEARCH-02 complete. Next: execute 96-03 (Component-state matrices).
- 2026-06-14: Phase 96 Plan 01 completed. MOTION.md dossier created at `.planning/research/v1.11/MOTION.md` with 14 MOTION-LD-NN locked decisions (MOTION-LD-01..14). Decisions lock: ease-out only for unidirectional transitions, ≤300ms per element, transform/opacity only (color permitted at fast token for state layers), prefers-reduced-motion snaps all transitions to instant, mount-trigger via phx-mounted/LiveView.JS only. MOTION-LD-12 provides the GAP-02 downstream close signal (preview empty-state focusable CTA). RESEARCH-01 marked complete. Next: execute 96-02 (IA dossier).
- 2026-06-13: RELH-02 reconciliation complete (93-03). Live Hex was authoritative at 1.6.2/1.6.2/1.3.1 (published 2026-06-12); the release-state memory was CORRECT; the in-repo state (1.6.1/1.6.1/1.3.0) was STALE. In-repo manifest + @version + dep pins advanced to 1.6.2/1.6.2/1.3.1 via non-bumping chore(release): commit. Remote 1.6.x tags fetched and kept (fetch+KEEP disposition; these are real published releases, do NOT delete). Harmless linked-version quirk: mailglass_admin-v1.6.1 tag exists on origin but admin 1.6.1 was never published to Hex (linked-version release PR tagged both; admin Hex publish failed/skipped; admin jumped 1.5.1 → 1.6.2). Current confirmed versions: mailglass 1.6.2 / mailglass_admin 1.6.2 / mailglass_inbound 1.3.1.
- 2026-06-13: Phase 93 context gathered in assumptions mode. Decisions captured in `.planning/phases/93-hexdocs-wiring-and-release-hardening/93-CONTEXT.md`; audit in the sibling `93-DISCUSSION-LOG.md`. Two judgment calls confirmed at recommended: RELH-01 hardens via an enforced CI commit-type lint (guarding `brandbook/`/`.planning/`/`prompts/`), RELH-02 investigates Hex live before reconciling (version truth contradictory: in-repo manifest+mix.exs+pin say 1.6.1/1.6.1/1.3.0, memory says 1.6.2/1.6.2/1.3.1, no local 1.6.x package tags). Mechanics pre-settled in ADOPTION-MECHANICS.md. Next: `/gsd-plan-phase 93`.
- 2026-06-13: Plan 92-02 completed. The admin placeholder wordmark is replaced with the sealed-flap outlined `currentColor` asset, `Components.logo/1` renders the lockup inline for theme-safe admin chrome, logo bundle tests ban live text/font dependencies, and `cd mailglass_admin && mix verify.preview` passed. Phase 92 is complete; next: plan/execute Phase 93 for HexDocs wiring and release hardening.
- 2026-06-13: Plan 92-01 completed. README now displays `brandbook/examples/readme-header.svg`, `brandbook/examples/og-card.png` is committed at 2400x1260 and 59,562 bytes, and `brandbook/README.md` documents the manual GitHub Settings > Social preview upload path. Next: execute 92-02 for the admin wordmark surface.
- 2026-06-13: Phase 92 UI-SPEC approved in `.planning/phases/92-surface-propagation/92-UI-SPEC.md`; 6/6 UI checker dimensions passed with no recommendations. Next: `/gsd-plan-phase 92`.
- 2026-06-12: Phase 92 context gathered in assumptions mode. Decisions captured in `.planning/phases/92-surface-propagation/92-CONTEXT.md`; discussion audit in `.planning/phases/92-surface-propagation/92-DISCUSSION-LOG.md`. Next: `/gsd-plan-phase 92`.
- 2026-06-12: Phase 91 planning complete. Research, validation, pattern map, and four executable plans were created under `.planning/phases/91-folder-adoption-and-reference-reconciliation/`; plan-checker passed after revisions for research resolution, validation map alignment, pattern references, and D-10 diff-scope proof. Next: `/gsd-execute-phase 91`.
- 2026-06-12: Phase 91 context gathered in assumptions mode with explicit subagent research. Decisions captured in `.planning/phases/91-folder-adoption-and-reference-reconciliation/91-CONTEXT.md`; discussion audit in `.planning/phases/91-folder-adoption-and-reference-reconciliation/91-DISCUSSION-LOG.md`. Next: `/gsd-plan-phase 91`.
- 2026-06-12: v1.10 roadmap created (Phases 91-93). `.planning/ROADMAP.md` rewritten for v1.10 (milestone history, v1.9 collapsed details, and 999.x backlog preserved), `.planning/REQUIREMENTS.md` traceability filled (10/10 → Phases 91-93), STATE updated. Next: `/gsd-plan-phase 91` (or `/gsd-discuss-phase 91` first).
- 2026-06-12: v1.9 shipped (Phases 85-90; gate 9/9 first run, maintainer A/B sign-off). v1.10 "Brand Adoption" opened; requirements defined (10 REQ-IDs); adoption mechanics researched under `.planning/research/v1.10-brand-adoption/`.
- 2026-06-11: v1.8 closed superseded; milestone audit `gaps_found` accepted. Archives at `.planning/milestones/v1.8-*`. `brandbook/` frozen at `09a84dd4` as the codex A/B baseline. v1.9 "Brand Book Fable" opened; requirements defined (22 REQ-IDs); research synthesized for the fable brandbook milestone.
- 2026-06-10: Phase 82 completed; maintainer selected `concept-07r-no-idot-02-tighter-gap` out-of-band; canonical assets promoted and brand docs rewritten around it.
- 2026-06-05: v1.7 shipped and archived (Phases 74-79, audit passed). Live versions as of 2026-06-05: `mailglass` 1.5.1 / `mailglass_admin` 1.5.1 / `mailglass_inbound` 1.3.0.
- v0.1 through v1.0 archived in `.planning/milestones/v0.1-*` through `.planning/milestones/v1.0-*`; v1.1-v1.8 likewise archived under `.planning/milestones/`.

## Operator Next Steps

- **Active milestone: v1.14 Operator IA & Lived-Experience Redesign** (opened 2026-06-26).
  Roadmap created (Phases 118-124, 14 REQ-IDs, 100% coverage). This is an adopter-visible *quality*
  milestone under D-23 convergence (the method-inverting top-down/JTBD-led redesign) — NOT
  product-capability growth. **Next: `/gsd-plan-phase 118`** (or `/gsd-discuss-phase 118` first).
  Phase 118 is the hard precondition (persona-critic harness + defect register) for the keystone shell
  redesign in 119. Surface order 119 → 120 → 121 → 122, then coherence/ratchet (123), then Hex release
  (124). The post-v1.12 "quiet maintenance" posture is superseded for the duration of v1.14.

- **Maintenance thread `release-pipeline-maintenance.md` — ✅ FULLY CLOSED (2026-06-18).** All items done:
  ✅ (1) `gate-ci-green` advisory-classifier fix (`1e0e60b1`).
  ✅ (4) held dep PRs #76 premailex 1.0.0 + #75 swoosh 1.26.1 merged (quick `260617-syd`; `9c3bbfea`/`50b49206`).
  ✅ (5) `Core Full Suite Advisory` lane fixed → green (quick `260617-tgw`; `abadbb32`).
  ✅ (2) trust-lane baseline de-hardcoded + refreshed to 1.7.0 → dep/version bumps are now **zero-touch**
  (quick `260618-1qj`; `7cbef50b`). No remaining maintenance work; release pipeline is clean + low-maintenance.

- **Before any *feature-discovery* pass** (only if reconsidering expansion): refresh
  `.planning/research/JTBD-COVERAGE.md` (now 6 milestones stale) — its conclusion still holds, only
  its status tables are stale. Not needed for maintenance work.

- Expansion candidates remain pull-gated (watchlist `transport-expansion-watchlist.md`): SEED-003,
  Cloudflare Email Routing, synthetic inbound dev UI, `gen_smtp` listener, more providers.
