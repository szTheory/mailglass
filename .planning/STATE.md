---
gsd_state_version: 1.0
milestone: v1.12
milestone_name: Adopter Onboarding & Day-2 Confidence
status: verifying
last_updated: "2026-06-17T02:56:41.417Z"
last_activity: 2026-06-17
progress:
  total_phases: 17
  completed_phases: 13
  total_plans: 50
  completed_plans: 50
  percent: 76
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-16 — after v1.11 milestone close)

**Core value:** Email you can see, audit, and trust before it ships. Mailglass turns "did the email go out, render correctly, and reach the inbox?" from a guessing game into observable, replayable, debuggable infrastructure.
**Current focus:** Phase 104 — installer-fail-closed-webhook-wiring-doctor

## Current Position

Phase: 104 (installer-fail-closed-webhook-wiring-doctor) — COMPLETE
Plan: 2 of 2
Status: Phase complete — all plans executed, implementation verified
Last activity: 2026-06-17

## v1.12 Milestone Intent

- Convert the one remaining adopter wedge from the 2026-06-16 next-step assessment: onboarding /
  day-2 DX. mailglass is feature-complete for its scope (~92% code axis) — this milestone removes
  the friction/footguns between "evaluating" and "in production," then **publishes** the accumulated
  v1.7–v1.12 polish to Hex. Friction-removal + release, NOT feature growth (D-23 convergence holds).

- Headline fix (the dangerous gap): `mix mailglass.install` warns-then-continues on an unmanaged
  `Plug.Parsers` conflict (`installer/apply.ex:47-76`), producing a silent production webhook 401.
  Make it fail closed (route through the `Mix.raise` path the task already uses) with a `--force`
  escape hatch + a verifiable post-install webhook-wiring doctor check.

- Plus: fix the broken README quickstart, add a first-week learning arc + go-live checklist +
  unified error/troubleshooting guide, sharpen migration-from-swoosh's "why"; fold in the inbound
  replay-modal a11y parity (ex-v1.11 WR-03); then cut the real linked-version Hex release + D-13
  inbound exact-pin re-pin.

## v1.12 Scope Locks

- **Onboarding / DX + release only.** No new product capability, providers, transports, or routes.
- **Code changes confined to** the installer (`mailglass/lib/mailglass/installer/*` + install/doctor
  mix tasks) and the admin inbound replay modal. No outbound/webhook/inbound runtime-contract,
  schema, or public-error-set changes. A11Y-01 is a quality-parity item, not a feature.

- **Docs guardrails:** every guide code block must parse (`docs_contract_test.exs`); canonical
  telemetry/error vocabulary (`docs/api_stability.md`); no over-claims; new guides registered in
  BOTH `mix.exs` `extras:` and `groups_for_extras: [Guides: …]`.

- **Zero Node toolchain;** admin CSS bundle rebuilt + committed if classes change
  (`git diff --exit-code priv/static/`) for the a11y phase.

- **Release posture: ACTUALLY CUT** (D-28) — the deliberate change from v1.7/v1.11 prepare-only.
  Admin-minor bump drags matched core+inbound; D-13 inbound exact-pin re-pin after the PR merges.

## Roadmap Snapshot

| Phase | Name | Focus |
|-------|------|-------|
| 104 | Installer Fail-Closed + Webhook-Wiring Doctor | Fail closed (Mix.raise) on unmanaged `Plug.Parsers` conflict + `--force` escape hatch + verifiable webhook-wiring doctor check; tests-first (INSTALL-01..04) |
| 105 | Onboarding Docs: Quickstart Fix + Learning Arc | Config-first README quickstart, getting-started "Next steps", learning-path index, migration-from-swoosh "why" opener; docs-contract gated (DOCS-01..04) |
| 106 | Day-2 Guides: Go-Live Checklist + Error/Troubleshooting | New production-go-live-checklist.md + unified errors-and-troubleshooting.md; registered in mix.exs docs + docs-contract gated (OPS-01/02) |
| 107 | Inbound Replay-Modal A11y Parity (WR-03) | Operator-style focus-trap + Escape on admin inbound replay modal; Playwright structural assertion; bundle clean (A11Y-01) |
| 108 | Release Cut + Milestone Closeout | Cut real linked-version Hex release (CHANGELOG, admin-minor drags core+inbound); D-13 inbound re-pin; Hex resolution + post-publish smoke; milestone audit (REL-01/02) |

**Critical path:** 104 → 105 → 106 → 108, with 107 in parallel and 108 gated on all.
**Sequencing notes:** 105/106 both touch `mix.exs` docs `extras:`/`groups_for_extras:` and
`docs_contract_test.exs`, so they serialize (105 first, so the day-2 guides can reference the new
fail-closed behavior + doctor from 104). 107 is admin-UI and independent. 108 is the single
closeout gate and the actual Hex publish.

## Decisions

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

## Performance Metrics

**Velocity:**

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

## Accumulated Context

### Roadmap Evolution

- 2026-06-13: v1.11 roadmap created. Phases 94-103, numbering continues from v1.10 (last phase 93). All 34 REQ-IDs mapped to exactly one phase, 100% coverage (TOKEN-01..05 + RATCHET-03 → 94; RATCHET-01/02/04/05 → 95; RESEARCH-01..05 → 96; COMP-01..03 + GALLERY-01/02 → 97; cross-surface GROUP-01/PAGE-01/02/RESP-01/FLOW-01/02/A11Y-01/02 anchored on operator → 98; GROUP-02/03 → 99; PAGE-03 → 100; COPY-01 → 101; MOTION-01/02 → 102; 103 is closeout-only). Critical path 94 → 95 → 96 → 97 → {98,99,100 parallel} → {101,102 parallel} → 103. Cross-cutting GROUP/PAGE/RESP/FLOW/A11Y reqs counted once at their operator anchor (98) and re-applied per-surface on 99/100. Phase 94 tightens conformance gates FIRST (tighten-then-re-baseline) so the token re-baseline can't regress silently. Release prepare-only; admin-minor bump drags matched core+inbound via linked-version releases.
- 2026-06-12: v1.10 roadmap created. Phases 91-93, numbering continues from v1.9 (last phase 90). All 10 REQ-IDs (FOLD-01..03 → 91, SURF-01..03 → 92, HEXD-01..02 + RELH-01..02 → 93) mapped to exactly one phase, 100% coverage. Strictly linear critical path 91 → 92 → 93. RELH-02 flagged potentially blocked-on-external (in-flight release train must settle). Adoption mechanics pre-settled in `.planning/research/v1.10-brand-adoption/ADOPTION-MECHANICS.md`.
- 2026-06-11: v1.9 roadmap created. Phases 85-90, numbering continues from v1.8 (last phase 84). All 22 REQ-IDs (BRIEF/FOUND/LOGO-05..08/BOOK-04..07/COLL/COPY/GATE) mapped to exactly one phase, 100% coverage. Strictly linear critical path. Phase 87 carries a hard maintainer-selection pause with a two-rejection circuit breaker. Research pre-settled token format, contrast fixes, and SVG portability rules in the fable brandbook research summary.
- 2026-06-11: v1.8 closed superseded (audit verdict gaps_found, accepted). Residual gaps inherited by v1.9; `brandbook/` frozen at `09a84dd4` as the A/B baseline.
- 2026-06-03: v1.7 milestone opened. Roadmap created for Phases 74-79. Phase numbering continues from v1.6 (last phase 73). All 19 REQ-IDs mapped to exactly one phase with 100% coverage.
- 2026-06-03 convergence posture: after v1.7, default posture returns to maintenance/quiet unless concrete adopter pull or contract gap says otherwise. v1.8/v1.9 brand milestones are repo-artifact work, not product expansion.

### Pending Todos

- Refresh outbound admin UI look and feel (`.planning/todos/pending/2026-06-13-refresh-outbound-admin-ui-look-and-feel.md`) — follow-up design-system milestone candidate from Phase 92 human UAT.

## Pre-existing Cleanup Backlog (Not v1.10 Scope)

`.planning/phases/` still contains leftover backlog phase directories (999.1, 999.2) from earlier milestones. Run `/gsd-cleanup` before active phase execution if name-collision risk appears.

## Session Continuity

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

- **v1.12 Adopter Onboarding & Day-2 Confidence is OPEN** (Phases 104–108, 13 REQ-IDs; REQUIREMENTS.md
  + ROADMAP.md written 2026-06-16). Next: `/gsd-plan-phase 104` (or `/gsd-discuss-phase 104` first).
- Decisions locked this session: D-28 actually cut the Hex release at close (not prepare-only);
  D-29 fold inbound replay-modal a11y (ex-WR-03) into v1.12 as Phase 107.

- Phase 108 release-cut checklist is recorded in the milestone plan / thread — confirm staged
  versions, land feat/fix commits so Release Please proposes the bump, then D-13 inbound re-pin
  after merge.

- Before any *feature-discovery* pass (not needed for this milestone): refresh
  `.planning/research/JTBD-COVERAGE.md` (5 milestones stale) or formally adopt the convergence
  verdict in its place.
