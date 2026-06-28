# v1.14 Milestone Seed — Operator IA & Lived-Experience Redesign

> Seed brief for `/gsd-new-milestone` (code **v1.14**). Approved by maintainer 2026-06-26.
> Binding quality bar: `./STRESS-TEST-PROMPT.md` (must not be diluted).
> Mirror of the approved plan `~/.claude/plans/what-s-the-point-of-zany-taco.md`.

## Why (root cause)

Three admin-UI design milestones shipped (v1.7/v1.11/v1.13), yet clicking the real `make demo`
surfaces obvious IA/usability problems on the operator landing (`/ops/mail?tenant_id=northstar`):
sidebar **always highlights "Deliveries"** even on the overview (hardcoded `active={:deliveries}` at
`operator_live.ex:349`); a **"Navigate" section** (`operator_live.ex:416-448`) renders two cards
duplicating the always-visible sidebar; the **overview is a homepage that mostly points elsewhere**
(generic orientation strip + health stats + redundant nav cards). Root cause: prior passes were
**bottom-up + structural-gate-verified** → clean primitives on muddy pages, because no structural
gate can ask "is this page redundant / coherent / least-surprising."

## Thesis

Invert the method: **top-down, JTBD/IA-led**, with a **judgment-level review loop** (adversarial
persona critics + maintainer sign-off) that catches taste/redundancy/IA problems gates can't.
Ruthlessly de-duplicated, Apple-like deliberate IA. Mobile-first, light/dark/system, WCAG 2.2 AA,
Emil-Kowalski-grade motion, on-brand microcopy. **Idempotent — only-forward, no regressions** (inherit
the full v1.13 ratchet floor).

## Locked decisions (maintainer, 2026-06-26)

1. **Overview → real triage destination.** Keep it but de-dupe: remove redundant nav cards + generic
   orientation strip, give it its own nav item (fixes active-nav bug), make health stats actionable/
   drill-down.
2. **Review method → persona critics, mostly autonomous.** Adversarial persona/JTBD agents produce a
   prioritized, screenshot-backed defect register; execute autonomously off the hit-list with
   **phase-boundary checkpoints** (before/after per surface), not per-fix UAT.
3. **Release → ship to Hex** (linked-version like v1.13: admin-minor drags core+inbound; D-13 inbound
   exact-pin re-pin; consumer + post-publish smoke; audit + archive).
4. **Preview surface → adopt `phoenix_storybook` as `only: :dev`.** Zero-Node is an *adopter-facing*
   guarantee; a dev-only dep doesn't touch it (adopters never install it / build its assets; shipped
   `priv/static/app.css` unchanged). Our dev/CI gaining Node is accepted. Integration tasks: (a) wire
   committed `app.css` as the storybook **sandbox stylesheet** (reuse bundle, no new JS build
   expected); (b) **keep `/dev/mail/gallery`** as the ratchet/structural-contract surface, add
   storybook as the interactive review surface alongside (consolidate later if desired).

## Method — persona-critic loop

Personas/hats: dev-evaluator, library-integrator, maintainer-debugging, operator/on-call-SRE-under-
stress, security-reviewer. Stress data: `northstar` (many/high-count/error), `fjordline-aps` (one/
long-ID/non-ASCII/null), `helios-void` (zero-data) from `reference/persona_spec/personas.ex`. Agents
screenshot each surface from live `make demo` (Playwright) + storybook/gallery across
320/375/768/1024/1440 × light/dark/system × happy/empty/loading/error/permission-denied/boundary/
disconnected. Rubric (gates can't ask): redundancy/earns-its-place; IA clarity & least-surprise; nav
reflects location; info-dump vs streamlined; crowding/breathing-room; hierarchy; microcopy; modal/
scroll/focus footguns; semantic icons; cross-surface consistency. Output: one prioritized severity-
ranked screenshot-backed defect register. Promote findings into NEW durable gates where expressible
(nav-active-correctness; no-nav-duplication-on-overview).

## Surfaces (top-down, biggest-impact first)

1. App-shell + Nav + Overview (#1 pain) → 2. Deliveries (core JTBD) → 3. Inbound (consistency) →
4. Preview (consistency) → 5. Cross-surface coherence + review surface.

## Proposed phases (roadmapper to refine)

- **P0** Method + Audit + Storybook stand-up (persona-critic harness; defect register; add
  phoenix_storybook dev-only + sandbox CSS; keep gallery for ratchets; floor inheritance; draft new
  gates).
- **P1** App-shell + Nav + Overview redesign (fix active-nav bug; Overview nav item; delete redundant
  cards; orientation strip → empty-pane-only; actionable health stats; microcopy; full matrix +
  persona stress).
- **P2** Deliveries surface end-to-end. **P3** Inbound consistency. **P4** Preview consistency.
- **P5** Cross-surface coherence + review-surface finalize + ratchet re-arm (re-score only-forward;
  arm new judgment gates).
- **P6** Release cut + closeout (linked Hex release, inbound re-pin, smokes, audit + archive).

## Idempotent floor (inherit, keep green, re-score only upward)

~28 gates total: ~26 grep-based conformance gates (`mailglass_admin/scripts/check-conformance.sh`)
+ 2 armed judgment gates — **nav-active-correctness** and **no-nav-duplication**
(`mailglass_admin/e2e/judgment.spec.js`), which run in the required `operator_browser_gate` Playwright
lane (`playwright.config.cjs` testDir "./e2e" glob), NOT in `check-conformance.sh` (grep cannot read
rendered active-nav state — D-05). Plus the 54-cell aesthetic baseline
(`docs/ui-baseline-scores.json`, `ratchet_baseline_test`); 9-cell axe baseline (`docs/axe-
baseline.json`); 24-item Bucket-A manifest (`bucket_a_coverage_test.exs`); persona drift-guard. Tokens
in `mailglass_admin/assets/css/app.css` + `brandbook/` are source of truth. Recipient-facing email
templates OUT of scope.

## Critical anchors

`operator_live.ex` (349 hardcoded active; 373-448 overview/redundant cards); `operator/shell.ex`
(nav 216-244; orientation strip 361-424); `inbound_live.ex`; `preview_live.ex`; `gallery_live.ex`;
`router.ex`; `components.ex` + `operator/` & `inbound/` groups; ratchets in `scripts/` + `e2e/` +
`test/.../*baseline*`; demo in `reference/demo_app/` + `Makefile` (`make demo`) +
`reference/persona_spec/personas.ex`.
