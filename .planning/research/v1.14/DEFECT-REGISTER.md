# v1.14 — DEFECT REGISTER (the prioritized, screenshot-backed hit-list)

> **Authored:** 2026-06-26 · **Method:** METHOD-01 persona-critic walkthrough (Phase 118 Plan 03).
> **Scope:** MILESTONE (sibling to `MILESTONE-SEED.md` / `STRESS-TEST-PROMPT.md`) so Phases 119–123
> consume it without reaching into an archived phase dir (D-05).
> **Binding rubric:** `.planning/research/v1.14/STRESS-TEST-PROMPT.md` (the fractal A–G audit scope +
> footgun list + viewport/theme/state matrix + the Apple-like deliberate-IA bar). This register judges
> against that bar — redundancy / earns-its-place / least-surprise / info-dump-vs-streamlined /
> hierarchy / microcopy / semantic-icons / cross-surface-consistency — **not just WCAG nits.**
> **This phase CATALOGUES only.** No catalogued defect is fixed here — fixes are Phases 119–123.

## How to read this register

- **Cataloguing-only contract.** Phase 118 is a pure tooling/method phase. Nothing below is fixed in
  this phase; each finding names a precise fix-direction + site so 119–123 are surgical, not
  exploratory.
- **Every finding cites its exact cell:** `surface / persona / viewport / theme / state` + the
  **screenshot path** under `.planning/research/v1.14/.cache/screenshots/` (git-ignored evidence, D-02
  — paths are cited, images are never inlined). The seam that produced them is
  `reference/demo_app/assets/e2e/persona-screenshots.spec.js` (Plan 03 Task 1).
- **Severity:** **Critical** (breaks the operator's core JTBD / a trust-eroding correctness-of-IA bug),
  **High** (a clear redundancy/info-dump/least-surprise violation on a top-2 surface), **Medium**
  (cross-surface inconsistency / polish / state-handling), **Low** (cosmetic / review-surface / env).
- **Five hats (D-04, fixed vocabulary):** `dev-evaluator` · `library-integrator` ·
  `maintainer-debugging` · `operator/on-call-SRE-under-stress` · `security-reviewer`.
- **Three personas (D-03, fixed vocabulary):** `northstar` (many/high-count/error) ·
  `fjordline-aps` (one/long-ID/non-ASCII/null) · `helios-void` (zero-data).
- **`any`** in a cell = a persona-independent dev-only review surface (storybook / preview / gallery).

## Surface priority (biggest-impact-first, drives Phase order 119→122)

| # | Surface | Route | Phase |
|---|---------|-------|-------|
| 1 | App-shell + Nav + **Operator Overview** | `/ops/mail?tenant_id=<persona>` | **119 (keystone)** |
| 2 | **Deliveries** | `/ops/mail?...&view=deliveries` | 120 |
| 3 | Inbound | `/ops/mail/inbound?...` | 121 |
| 4 | Preview | `/dev/mail` | 122 |
| — | Storybook / Gallery (review surfaces) | `/dev/storybook`, `/dev/mail/gallery` | review aids (123 finalize) |

---

## Executive summary (do-first-if-limited)

The single root cause the maintainer named is confirmed by the evidence: **the Operator Overview is a
homepage that mostly points elsewhere, and the app-shell nav lies about where you are.** Three
independent redundancy paths all lead to "Deliveries" (sidebar nav · orientation-strip card · "Navigate"
card), and the sidebar **always highlights Deliveries even on Overview** (false-active-nav). The
all-clear state (fjordline / helios) makes the info-dump worst: nothing needs attention, yet the
operator scrolls past 6 cards + a duplicate nav block. Fix order is the roadmap order: **119 nails the
shell + overview (D-headline defects below), 120 streamlines Deliveries (drop the repeated orientation
strip + filters-on-empty), 121/122 inherit the cleaned-up patterns, 123 re-arms the gates.**

**Biggest wins (in 119):** (1) give Overview its own nav identity + fix `active={@view}`; (2) delete the
"Navigate" card block; (3) make the orientation strip empty-pane-only. These three alone convert the #1
pain surface from info-dump to a deliberate triage destination.

**Headline defects (the named, precise-site set Phase 119 owns):**

| Tag | Severity | Site | One-liner |
|-----|----------|------|-----------|
| **D-NAV-ACTIVE** | Critical | `operator_live.ex:349` (caller literal; **shell is correct**) | Sidebar always shows Deliveries active, even on Overview |
| **D-NAV-DUP** | High | `operator_live.ex:416-448` (`operator-overview-nav`) | "Navigate" cards duplicate the always-visible sidebar |
| **D-ORIENT-REDUNDANT** | High | `operator/shell.ex:361-424` orientation strip | Same "Deliveries / Delivery never arrived?…" card repeats on Overview AND Deliveries AND empty Deliveries |
| **D-OVERVIEW-SIGNPOST** | High | `operator_live.ex` overview branch | Overview is a homepage that points elsewhere, not a triage destination |

> **Phase-119 test cross-reference (Pitfall 2 — do not get blindsided):** `mailglass_admin/e2e/operator.spec.js:352-368`
> (VERIF-02) currently asserts `data-testid="operator-overview-nav"` **IS visible**. The drafted
> `no-nav-duplication` gate (`mailglass_admin/e2e/judgment.spec.js`, Plan 02) asserts its **absence**.
> When Phase 119 deletes the Navigate card block (D-NAV-DUP), it **MUST** update/remove
> `operator.spec.js:352-368` in the same phase or the operator browser gate goes red. Flagged here so
> 119 plans the test change alongside the deletion.

---

## Critical

### D-NAV-ACTIVE — Sidebar nav always highlights "Deliveries", even on the Overview route
- **Cell:** App-shell+Overview / northstar / 1440 / light / happy →
  `.cache/screenshots/overview-northstar-1440-light.png` (also `…-dark.png`,
  `overview-fjordline-aps-1440-dark.png`, `overview-northstar-375-light.png` — the bug is present in
  **every** overview cell, all personas, all viewports, all themes).
- **Hats:** operator/on-call-SRE-under-stress (primary — "where am I?" must never lie under stress);
  dev-evaluator (first-impression credibility).
- **Rubric (STRESS-TEST-PROMPT D — Navigation):** "Users always know where they are; active item
  obvious in light+dark; nav matches location." This is the canonical **tabs/nav-without-correct-active-state**
  footgun, at the app-shell level.
- **Evidence:** On `/ops/mail?tenant_id=northstar` (the Overview landing) the left sidebar renders
  **Deliveries** with the active treatment (accent left-border + bold) while the page heading is
  "Operator overview". There is no Overview nav item at all, so the shell has nothing correct to
  highlight.
- **Root cause (Pitfall 3 — name the precise site):** `mailglass_admin/lib/mailglass_admin/operator_live.ex:349`
  passes the **literal** `active={:deliveries}` to the shell regardless of `@view`. The **shell is
  correct** — `operator/shell.ex:219` does `active={@active == :deliveries}` / `@active == :inbound`
  and keys `data-theme` correctly. Do **not** rewrite the shell.
- **Fix-direction (Phase 119):** introduce an **Overview** nav item with its own identity in the
  sidebar (`operator/shell.ex:216-244` nav block gains a `:overview` link), and have the caller pass
  `active={@view}`-equivalent (`:overview` on the landing, `:deliveries` on `&view=deliveries`,
  `:inbound` on inbound) instead of the hardcoded literal. The drafted `nav-active-correctness` gate
  (`judgment.spec.js`) encodes the end-state (`aria-current="page"` on Overview, Deliveries inactive) —
  flip it `test.fixme`→`test` when fixed.
- **Status:** CATALOGUED (fix = Phase 119). Drafted gate already asserts the correct end-state.

---

## High

### D-NAV-DUP — The "Navigate" card block duplicates the always-visible sidebar
- **Cell:** App-shell+Overview / northstar / 1440 / light / happy →
  `.cache/screenshots/overview-northstar-1440-light.png`; all-clear duplication is starkest at
  fjordline / helios → `overview-fjordline-aps-1440-dark.png`; mobile stack →
  `overview-northstar-375-light.png`.
- **Hats:** dev-evaluator (redundancy reads as unfinished); operator/on-call-SRE (wasted scroll under
  stress); library-integrator (an adopter mounting this surface inherits the redundancy).
- **Rubric (D — Navigation / F — Component groups / the "earns-its-place" + "no redundant UI" bar):**
  repeated patterns should be implemented once; a card that re-offers what the persistent sidebar
  already offers does not earn its place.
- **Evidence:** below Health, a **"Navigate"** section renders two large cards — **View Deliveries** and
  **View Inbound** — each a button to a destination that the **left sidebar already exposes
  permanently** (Deliveries, Inbound). On the all-clear fjordline overview the entire lower half of the
  page is this duplicate nav block; nothing actionable.
- **Site:** `mailglass_admin/lib/mailglass_admin/operator_live.ex:416-448` (the
  `data-testid="operator-overview-nav"` `<div>` containing the two `card` blocks).
- **Fix-direction (Phase 119):** **delete** the `operator-overview-nav` block. Overview's value is
  triage (actionable health), not signposting to nav the shell already provides. **MUST** also update
  `operator.spec.js:352-368` (VERIF-02) in the same phase — see Pitfall-2 cross-reference above. The
  drafted `no-nav-duplication` gate (`judgment.spec.js`) asserts `operator-overview-nav` count 0.
- **Status:** CATALOGUED (fix = Phase 119, paired with the VERIF-02 test update).

### D-ORIENT-REDUNDANT — The orientation strip repeats verbatim across surfaces and states
- **Cell:** Deliveries / northstar / 1440 / light / happy →
  `.cache/screenshots/deliveries-northstar-1440-light.png`; the SAME strip on Overview →
  `overview-northstar-1440-light.png`; and on the **empty** Deliveries (helios) →
  `deliveries-helios-void-1440-light.png`.
- **Hats:** dev-evaluator; operator/on-call-SRE (the strip pushes the actual data table down).
- **Rubric (E/F — orientation should teach the empty/onboarding path, not tax every populated view;
  STRESS-TEST IA "progressive disclosure over walls of controls"):** the same
  **"Deliveries — Delivery never arrived? Start here. / Replay changed nothing?… / Address keeps getting
  blocked?…"** orientation card renders on the **Overview** AND below the **populated Deliveries table**
  AND below the **empty Deliveries** state — three times, identical copy, regardless of context.
- **Evidence:** the lifebuoy-icon "Deliveries" orientation card is byte-identical across
  `overview-northstar-1440-light.png`, `deliveries-northstar-1440-light.png`, and
  `deliveries-helios-void-1440-light.png`. On the populated table it sits *below* 16 rows of real data
  the operator came for; on Overview it duplicates the top "Deliveries" card's intent.
- **Site:** `mailglass_admin/lib/mailglass_admin/operator/shell.ex:361-424` (generic
  `orientation_strip/1`), called unconditionally on these surfaces.
- **Fix-direction (Phase 119 sets the pattern; 120 applies to Deliveries):** make orientation
  **empty-pane-only** — show the teach-the-next-step strip when there is no data / no selection, and
  suppress it once real rows/detail are present. This is the roadmap's explicit "orientation strip →
  empty-pane-only" for 119.
- **Status:** CATALOGUED (pattern set in 119, applied to Deliveries in 120).

### D-OVERVIEW-SIGNPOST — Overview is a homepage that mostly points elsewhere, not a triage destination
- **Cell:** App-shell+Overview / fjordline-aps / 1440 / dark / all-clear →
  `.cache/screenshots/overview-fjordline-aps-1440-dark.png`; northstar attention-state →
  `overview-northstar-1440-light.png`; mobile info-dump →
  `overview-northstar-375-light.png`.
- **Hats:** operator/on-call-SRE (the landing should answer "what needs me now?" in one glance);
  dev-evaluator (the first screen sets the product's perceived quality).
- **Rubric (G — Pages/flows: identify the page's top 1–3 actions; the Apple-like deliberate-IA bar;
  "info-dump vs streamlined"):** the Overview's content is, top-to-bottom: a subtitle that says
  "Navigate to Deliveries to inspect individual sends", a "Deliveries" orientation card, a Health row,
  and a "Navigate" duplicate-nav block. The only *bespoke* value is the **Health** row
  (Recent failures / Orphan backlog / Active suppressions / Overall status). Everything else points
  away.
- **Evidence:** on the all-clear fjordline overview, **every** health card reads 0 / "All clear" /
  "Clear", yet the page is the same length as the attention state — the operator scrolls past a
  duplicate nav block to learn "nothing is wrong." The page does not surface *what to do next* when
  something IS wrong (northstar: "Recent failures 1 — Needs attention" is a count, not a link into the
  failing sends).
- **Fix-direction (Phase 119):** Overview → a **real triage destination**: actionable health stats that
  link into the filtered failing/orphan/suppressed sends; collapse the all-clear state to a calm,
  short "all clear" rather than a full-height info-dump; drop the signpost subtitle + Navigate block
  (covered by D-NAV-DUP). Health counts should be **click-throughs**, not dead numbers.
- **Status:** CATALOGUED (fix = Phase 119; this is the "Overview → real triage destination" milestone
  intent).

### D-FILTERS-ON-EMPTY — Deliveries renders the full filter toolbar (with an "Open delivery" CTA) on a zero-data tenant
- **Cell:** Deliveries / helios-void / 1440 / light / empty →
  `.cache/screenshots/deliveries-helios-void-1440-light.png` (also `…-dark`, `…-375-*`).
- **Hats:** operator/on-call-SRE (controls that act on nothing); dev-evaluator (least-surprise);
  security-reviewer (the FILTERS card's "Narrow Deliveries without widening the tenant scope" promise
  must hold even in the empty state — the prefilled single-tenant scope is correct here; flag any future
  fix that lets the empty-state filter widen scope).
- **Rubric (C — Forms / E — empty/zero states: "empty states explain the next step"; the
  "weird-pagination-when-nothing-to-paginate" + "disabled-looks-enabled" footgun family):** on a
  tenant with **0 results**, the surface still shows the full **FILTERS** card (Tenant prefilled,
  Provider placeholder, Status/Event/Time-window selects) plus an enabled **"Open delivery"** button —
  filters and an open-CTA that can only ever act on an empty set. Two orientation blocks
  (the "Deliveries" strip AND the "Select a delivery…" helper) also both render.
- **Evidence:** `deliveries-helios-void-1440-light.png` shows "0 results", the empty-state inbox icon +
  "No deliveries have been recorded yet." (good copy), but **above** it the complete filter toolbar and
  an active Open-delivery button, and **below** it two redundant orientation blocks.
- **Fix-direction (Phase 120, inheriting 119's empty-pane pattern):** in the genuine zero-data state,
  de-emphasize/withhold the filter toolbar + open-CTA (nothing to filter or open) and show a single
  empty/onboarding pane — not filters + empty + double orientation. Distinguish **no-data** from
  **no-match-for-filters** (the latter keeps filters so the operator can clear them).
- **Status:** CATALOGUED (fix = Phase 120 Deliveries redesign).

---

## Medium

### D-LABEL-TRIPLING — "Deliveries" is the label of the nav item, the page title, AND the orientation card simultaneously
- **Cell:** Deliveries / northstar / 1440 / light / happy →
  `.cache/screenshots/deliveries-northstar-1440-light.png`.
- **Hats:** dev-evaluator; operator/on-call-SRE (visual noise).
- **Rubric (D/F — "same term for same concept everywhere" is good; **three simultaneous instances of
  the same word as three different component types** is hierarchy noise):** on the Deliveries surface
  the word "Deliveries" appears as (1) the active sidebar nav item, (2) the page `<h1>` title, and (3)
  the orientation-strip card heading — three different visual weights for one concept in one viewport.
- **Fix-direction (Phase 120):** keep the nav item + page title (canonical), drop the orientation-card
  heading duplication (subsumed by D-ORIENT-REDUNDANT's empty-pane-only fix).
- **Status:** CATALOGUED (resolved as a side-effect of D-ORIENT-REDUNDANT in 120).

### D-MOBILE-INFODUMP — On mobile the Overview is a long single-column scroll of mostly-signpost content
- **Cell:** App-shell+Overview / northstar / 375 / light / happy →
  `.cache/screenshots/overview-northstar-375-light.png` (and the 320 system spot-check
  `…-320-system` family on Deliveries).
- **Hats:** operator/on-call-SRE (mobile = the on-call context); dev-evaluator (mobile-first bar).
- **Rubric (Foundations breakpoints / G mobile-first):** at 375 the Overview stacks subtitle →
  orientation card → 4 health cards → 2 Navigate cards into a tall scroll where >half is signpost /
  duplicate-nav. The top-nav also shows the same false-active "Deliveries".
- **Fix-direction (Phase 119, mobile-first):** the same Overview-as-triage + drop-Navigate-block fixes
  shorten the mobile scroll to the calm health summary; verify the 320/375 floors after the 119
  redesign.
- **Status:** CATALOGUED (fix = Phase 119; verify at the 320/375 floors).

### D-THEME-PARITY — Light/dark render at parity on the shipped surfaces (positive finding; hold the floor)
- **Cell:** overview northstar light vs dark →
  `.cache/screenshots/overview-northstar-1440-light.png` / `…-1440-dark.png`; deliveries fjordline
  dark → `deliveries-fjordline-aps-1440-dark.png`; system spot-checks →
  `deliveries-northstar-1440-system.png`.
- **Hats:** accessibility-minded dev-evaluator; operator/on-call-SRE (dark is the on-call default).
- **Finding:** dark mode is a genuine re-skin (Ink surfaces, Ice accents on buttons, semantic status
  colors hold contrast), and the system theme resolves to dark under `prefers-color-scheme: dark` —
  the v1.13 floor (9-cell axe + 54-cell aesthetic) is visibly holding. **No regression to introduce.**
- **Fix-direction:** none — this is the **only-move-forward floor** the redesign must not break. Recorded
  so 119–122 re-verify light/dark/system parity per surface after each redesign (the matrix is in the
  seam already).
- **Status:** CATALOGUED as a guardrail (no fix; hold the line).

---

## Low

### D-STORYBOOK-BRAND — The storybook explorer chrome is off-brand (phoenix_storybook default indigo)
- **Cell:** Storybook / any / 1440 / light / happy → `.cache/screenshots/storybook-any-1440-light.png`
  (and `…-375-*`, `…-dark`).
- **Hats:** dev-evaluator (the review surface itself should feel on-brand); library-integrator.
- **Finding:** the explorer header renders **"MAILGLASS ADMIN"** + a book glyph in phoenix_storybook's
  default **indigo/violet**, not the mailglass palette (Ink/Glass/Ice). The *sandbox* (the component
  preview area) correctly uses the committed admin bundle per Plan 01 (D-07), but the explorer **chrome**
  is the library default. This is a dev-only review surface, so it is cosmetic — but worth a token pass
  if cheap.
- **Fix-direction (optional, Phase 123 finalize):** if phoenix_storybook exposes a theme/title hook,
  set the title + accent to the mailglass brand; otherwise accept the default (it is dev-only and never
  ships to adopters).
- **Status:** CATALOGUED (Low; review-surface chrome only).

### D-STORYBOOK-STALE-BOOT — `/dev/storybook` 500s under hot-reload until the demo container is freshly booted (environment caveat, not a code defect)
- **Cell:** Storybook / any / 1440 / light → first-pass evidence captured the `UndefinedFunctionError`
  (`PhoenixStorybook.Router is not available`); after a clean `docker restart` the route returned 302
  and rendered (re-shot — current `.cache/screenshots/storybook-any-1440-light.png` shows the working
  explorer).
- **Hats:** dev-evaluator; maintainer-debugging.
- **Finding:** Plan 01 added `live_storybook` to the demo router; a demo container that was **already
  running before that commit** cannot hot-reload the `live_storybook` macro and returns 500 on
  `/dev/storybook`. A fresh `make demo` (or `docker restart`) resolves it. The operator surfaces
  hot-reload fine; only the storybook live-route needs a clean boot. This validates Plan 01's pending
  **D2 human_judgment** item ("load `/dev/storybook` against a running `make demo` and confirm it
  renders") — confirmed working **after a clean boot**.
- **Fix-direction:** none code-side. Document in the run-the-demo DX (storybook requires a fresh demo
  boot after the dep was added) — a docs/onboarding note, not a v1.14 surface-redesign item.
- **Status:** CATALOGUED (Low; environment/boot caveat, not a surface defect).

---

## Coverage map (sampled cells → register)

The seam shot a **prioritized 66-cell sample** (not the ~1,620-cell Cartesian sweep), weighted
biggest-impact-first. The findings above draw on these anchor cells (full set in
`.cache/screenshots/`):

| Surface | Personas shot | Viewports × themes | Key state cells | Findings drawn |
|---------|---------------|--------------------|-----------------|----------------|
| Overview (#1) | northstar, fjordline-aps, helios-void | {375,1440}×{light,dark} + system/320/768 | attention (northstar), all-clear (fjordline), zero (helios) | D-NAV-ACTIVE, D-NAV-DUP, D-OVERVIEW-SIGNPOST, D-MOBILE-INFODUMP, D-THEME-PARITY |
| Deliveries (#2) | all three | {375,1440}×{light,dark} + system/320/768 | populated (northstar/fjordline), empty (helios) | D-ORIENT-REDUNDANT, D-FILTERS-ON-EMPTY, D-LABEL-TRIPLING |
| Inbound (#3) | all three | {375,1440}×{light,dark} | populated + empty | (inherits Deliveries patterns; no net-new headline defect — 121 applies 120's cleanup) |
| Preview (#4) | any | {375,1440}×{light,dark} | mailable list | (consistent with patterns; 122 applies established cleanup) |
| Storybook | any | {375,1440}×{light,dark} | explorer | D-STORYBOOK-BRAND, D-STORYBOOK-STALE-BOOT |
| Gallery | any | {375,1440}×{light,dark} | ratchet specimens | (retained byte-unchanged per STORY-02; no redesign defect) |

> **Auditable coverage:** every finding cites a concrete cell + screenshot path; the seam is rerunnable
> (`DEMO_BASE_URL=http://127.0.0.1:4015 DEMO_EVIDENCE_RESET_TOKEN=<token> npx playwright test e2e/persona-screenshots.spec.js`)
> so 119–122 can re-shoot the same cells after each redesign to verify only-forward improvement.

## Phase consumption guide (what each downstream phase owns)

- **Phase 119 (App-shell + Nav + Overview — keystone):** D-NAV-ACTIVE, D-NAV-DUP,
  D-OVERVIEW-SIGNPOST, D-MOBILE-INFODUMP + set the empty-pane-only orientation pattern
  (D-ORIENT-REDUNDANT). **MUST** update `operator.spec.js:352-368` (VERIF-02) when deleting
  `operator-overview-nav`. Flip `judgment.spec.js` gates `test.fixme`→`test` once fixed.
- **Phase 120 (Deliveries):** apply the empty-pane pattern (D-ORIENT-REDUNDANT, D-FILTERS-ON-EMPTY,
  D-LABEL-TRIPLING); distinguish no-data vs no-match.
- **Phase 121 (Inbound) / 122 (Preview):** inherit 119/120's cleaned-up patterns; re-shoot the cells to
  prove consistency.
- **Phase 123 (cross-surface coherence + ratchet re-arm):** arm `nav-active-correctness` +
  `no-nav-duplication` into the floor; optionally address D-STORYBOOK-BRAND; re-verify D-THEME-PARITY
  across all four surfaces.
- **Hold the floor everywhere (D-THEME-PARITY guardrail):** light/dark/system parity and the inherited
  v1.13 ratchet floor are only-move-forward — no regression at any step.

---
*Authored 2026-06-26 · Phase 118 Plan 03 (METHOD-01) · seam: `reference/demo_app/assets/e2e/persona-screenshots.spec.js` · evidence: `.planning/research/v1.14/.cache/screenshots/` (git-ignored).*
