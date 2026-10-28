# Phase 177 — Health composition (OUTUX-06)

**Status:** research recommendation for planning. No code changed. 2026-10-28.
**Decision:** use a constrained **single reading column** (Candidate A), measured against one
deliberately grouped alternative (Candidate B) at real container widths. Lock A when it passes
the hard gates. Ship B only if A fails a gate that B passes (see § 5).

---

## 0. What exists today (grounding)

| Piece | Where | Current behaviour |
|---|---|---|
| Observation row (period, Last checked, Refresh) | `mailglass_admin/lib/mailglass_admin/operator_live.ex` ~L742–768 (inline in the LiveView, **not** in `HealthOverview`) | The period sits on the left. "Last checked" and Refresh are pushed right with `sm:ml-auto`, so the row splits across the full content width. At narrow widths, CSS `order-*` reorders the visual sequence to period → Refresh → timestamp, while the DOM sequence is period → timestamp → Refresh. Visual order and DOM order disagree (WCAG 1.3.2 risk). |
| Verdict + issue rows + per-panel notices | `operator/health_overview.ex` `overview/1`, left `<section>` | Rows are full-width `divide-y` lines with the count, an underlined label link (`py-xs`, so **no `min-h-11`**) and a 24px help icon. Stale rows get a plain-text "Last retrieved" tag. Non-ready panels render `<p role="status">` notices. |
| Recent activity | same file, right `<section>` | An `h2` at body size with two links (`min-h-11`). Layout is `lg:grid-cols-[minmax(0,2fr)_minmax(0,1fr)]`. |
| Populations | `operator_live.ex` `health_issues/7` ~L2849 | Only nonzero issues appear, in a fixed order: failed, bounced, rejected and deferred deliveries; failed and unrouted inbound; failed and unmatched webhooks. Each issue has its own deep link (`event=`, `outcome=`, `focus=`). |
| Shell | `operator/shell.ex` | `md:grid-cols-[15rem_1fr]`, `max-w-7xl`. |
| Container-query precedent | `assets/css/app.css` ~L678, 753 | `.operator-deliveries-layout { container-type: inline-size }`. A comment there explains why: the sidebar can leave less than 768px at tablet widths. Tailwind is 4.1.12, so the core `@container` / `@md:` variants are also available. |
| Rules | `mailglass_admin/docs/design-system.md` § "Investigation controls and health signals" | "Keep a refresh control adjacent to its observation timestamp … Other context, such as the observation period … stays separate." **This conflicts with OUTUX-06** (period, freshness and Refresh form one group) and must be amended in the same change. |
| Owner feedback | `.planning/todos/2026-10-25-health-overview-layout-owner-feedback.md`, `…2026-10-26-owner-review-health-preview-controls.md` | "Two columns awkward/crowded." Rows span far beyond their content. Activity floats unrelated to the list. The meta row is split across the full width. **Keep:** specific items and their deep links. The owner also asked for proof that each deep link lands on the matching records. |
| Existing proof | `e2e/phase169-journey.spec.js` ~L320–370; `e2e/health-tooltips.spec.js`; `operator_live_test.exs` (~L4640, 5737, 5791); `persona_cohort_test.exs:116` | The phase169 test checks widths 320/390/768/1440 for no overflow, 16px body text, 14px labels and that the period precedes the status in the DOM. It **asserts the current 2-column grid** (`metricColumns == (width < 1024 ? 1 : 2)`) through a brittle `> div:nth-child(2)` selector. That assertion has to change. |
| Stories | `reference/demo_app/storybook/` | **There is no Health story.** The Inbound evidence story (`inbound_evidence.story.exs`, iframe container, local theme radios) is the pattern to copy. |

**Estimated content widths.** These are derived from the classes above and still need measuring
(test step 1). At a 768px viewport, the shell main is about 480px. At 1024px, about 736px. That is
where the `lg:` 2fr/1fr split currently starts, leaving roughly 480px for issues and 240px for
activity. That split is the crowding. At 1440px, about 1150px. The viewport `lg:` breakpoint fires
when the *content* is still tablet-sized. This is the same defect the Deliveries container query
already fixed.

---

## 1. Operator job (who / when / why)

- **Who:** an on-call engineer or support operator. They arrive from an alert, a customer ticket
  or a routine check, often on a laptop and sometimes on a phone.
- **Job:** "Is anything wrong with this Account's mail right now? If so, where do I go?" The page
  is a **triage router**, not an analytics view. Google's SRE guidance makes the same point:
  every signal on the page should be actionable, and symptoms come before causes.
- **Read order:** (1) Can I trust what I'm seeing? That means the period, how fresh it is, and how
  to refresh it. (2) The verdict. (3) Which specific problems exist, and their links. (4) Optional
  context: how much traffic there was.
  The first item is a one-glance qualifier, so it belongs **before** the verdict, compact and
  together. That order is already enforced by the existing "period precedes status" assertion.
- **Activity is context, not action.** Its own help text says "Activity alone does not confirm
  successful delivery." Activity therefore cannot sit beside the issues at equal visual rank.

---

## 2. Recommended composition (Candidate A — constrained single column)

DOM order equals visual order at every width. No CSS `order-*` and no `flex-row-reverse`.

```
┌ main (container: inline-size) ──────────────────────────────────────────┐
│ ┌ health column  max-w ≈ 42rem, left-aligned ─────────────┐             │
│ │ ① Observation group  (role=group, one wrapping cluster) │  intentional│
│ │    Last 7 days (i) · Last checked 10:42 AM  [⟳ Refresh] │  whitespace │
│ │ ② Verdict   ⚠ Needs attention                           │             │
│ │             Some checks could not be updated.           │             │
│ │ ③ Issues    2  Bounced deliveries (i)                   │             │
│ │             1  Unrouted inbound messages (i) Not refreshed            │
│ │ ④ Notices   Unmatched events weren't refreshed. …       │             │
│ │ ── hairline ─────────────────────────────────────────── │             │
│ │ ⑤ Recent activity (label-size heading)                  │             │
│ │    Outbound  6 deliveries updated · Inbound 3 received  │             │
│ └─────────────────────────────────────────────────────────┘             │
└─────────────────────────────────────────────────────────────────────────┘
```

1. **Observation group** (`data-testid="operator-health-observation"`, `role="group"`,
   `aria-label="Health check period and freshness"`). One `flex flex-wrap items-center gap-x-sm
   gap-y-xs` cluster at `text-label text-secondary`, **left-aligned at every width**, with no
   `ml-auto` split. Order: period text + help, then "Last checked <timestamp>", then the Refresh
   button. Wrap "Last checked" and Refresh in an inner `inline-flex flex-wrap` sub-cluster so that
   when wrapping happens, the period breaks away first and Refresh stays with its timestamp. That
   also satisfies the existing design-system adjacency rule. Refresh stays `btn btn-ghost` with
   `min-h-11` and keeps its visible label: the icon plus "Refresh health", or "Refreshing…" while
   loading. Give it a stable `min-width` so the cluster does not reflow during loading.
2. **Verdict.** Keep the `h2`, the icon and the text. The icon is decorative; the words carry the
   status, which covers WCAG 1.4.1.
3. **Issue list** (primary). A semantic `<ul>`/`<li>`. Each row is a
   `grid grid-cols-[minmax(3ch,auto)_minmax(0,1fr)]`: a right-aligned tabular count, then the
   label link, the help icon and an optional text stale tag. **Give the label link `min-h-11`**
   (today it only has `py-xs`), matching the activity links and the repo's 44px convention. The
   24×24 help icon meets WCAG 2.5.8 through its own size. Dividers run only across the constrained
   column. That removes the "long empty divider" defect without padding hacks.
   **Order stays the fixed taxonomy order. Never sort by count, and never colour or weight a row
   by count.**
4. **Per-panel notices.** These stay inside the status section, after the issues and before
   activity. They are what makes stale or unavailable data intelligible next to the verdict.
5. **Recent activity** (subordinate). Visually subordinate, structurally intact:
   - Keep `<section aria-labelledby>` and `h2` for screen-reader landmark navigation. Style the
     heading at `text-label font-bold text-secondary`, below the verdict's `text-heading`.
   - Separate it from the issues with `mt-lg` plus a top hairline (`border-t border-base-300
     pt-md`). It shares the column's left edge, so the relationship is explicit and nothing floats.
   - The two items share one row at a container width of 30rem or more (`@container` variant).
     Below that they stack. Counts use `font-bold` at body size, **not** heading size. Links keep
     `min-h-11`.
6. **Column width.** About 42rem (`max-w-2xl`). That keeps labels near their counts and lines
   within a readable measure, roughly 45–75 characters. The rest of the content area on the right
   is intentionally empty at 1280px and wider.

**Move the observation markup into `HealthOverview`** as `observation/1`, and split
`overview/1` into `verdict`, `issue_list` and `activity` function components. LiveViews keep the
loading, params and commands, as the milestone's trust boundary requires. This lets one Storybook
story render the production presentation of the whole Health area, and it lets Candidate B be
assembled from **the same** components (§ 5), so populations cannot change by construction.
`health_issues/7` and the path builders must not change.

### Per-width behaviour (container widths, not viewport)

| Content width (viewport) | Behaviour |
|---|---|
| About 288px (320) | The observation group wraps to 2–3 lines; the period is on line 1, and the timestamp and Refresh stay together (Refresh may drop under the timestamp, still inside the group). Issue rows: count, then a label that may wrap to 2 lines. Activity items stack. No horizontal overflow. |
| About 358px (390) | The same, with fewer wraps. Long Unicode Account names live in the shell, not here. |
| About 480px (768) | The observation group fits on one or two lines. Activity sits in one row. Single column. *(This is the current tablet defect width.)* |
| About 736px (1024) | Single column, about 672px wide, with a small right gutter. **No 2:1 split.** |
| About 1150px (1280/1440) | A 672px column, left-aligned. About 450px of intentional whitespace. |
| 200%/400% browser zoom | Equivalent to the narrow rows above. Container queries follow automatically (WCAG 1.4.10). |

---

## 3. State matrix

| State | Observation group | Verdict | Issues | Notices | Activity |
|---|---|---|---|---|---|
| Normal, issues | "Last 7 days · Last checked 10:42 AM · Refresh health" | Needs attention | Nonzero rows only, fixed order | none | counts |
| Normal, no issues, active | same | "No issues found" + "No recorded problems in this period." | none | none | counts |
| Empty (no activity) | same | "No mail activity in this period" (recommended, see § 4) | none | none | "0 deliveries updated" / "0 messages received", still linked |
| Stale (partial refresh failure) | "Last checked" = this attempt's time | **Never an all-clear** (existing rule). Shows "Needs attention" if known issues exist, otherwise "Health check incomplete" | Known rows kept; stale rows carry the text tag | "<Panel> wasn't refreshed. Showing results from <timestamp>." | Last retrieved value, or "unavailable" |
| Unavailable (first read failed) | Period may read "Observation period unavailable"; Refresh is still present and focusable | "Health check incomplete" + "Refresh to try again." | none | "<Panel> couldn't be loaded." | "Outbound activity unavailable" (still a link, so it remains a way to recover) |
| Inbound absent | unchanged | unchanged | no inbound rows | no inbound notice | outbound only (the existing `Map.has_key?` rule) |
| Long content | wraps without overflow; a long localized timestamp wraps inside the sub-cluster | wraps under `max-w-prose` | large counts (≥ 100,000) widen the count column through `minmax(3ch,auto)`; labels wrap | wraps | wraps |
| Refreshing | button reads "Refreshing…", width stable, focus stays on the button | unchanged until the patch arrives | unchanged | unchanged | unchanged |

Partial issue lists are bounded: at most 8 categories, so the list can never push activity
indefinitely below the fold.

---

## 4. Copy (ux-writing pass; brand voice: clear, exact, calm under failure)

| Today | Recommend | Why |
|---|---|---|
| Row tag "Last retrieved" (no time shown) | **"Not refreshed"** | The tag alone doesn't say what is wrong. "Not refreshed" states the fact, and the time lives in the notice. |
| "Unmatched events: last retrieved 10:31 AM." | **"Unmatched events weren't refreshed. Showing results from 10:31 AM."** | Names the cause, then what is on screen. |
| "Webhook processing: could not be loaded." | **"Webhook processing couldn't be loaded."** | Same meaning, natural sentence. |
| "No recent mail activity" | **"No mail activity in this period"** | "Recent" is vague. The period is explicit in the group directly above. |
| "Activity unavailable" | **"Outbound activity unavailable" / "Inbound activity unavailable"** | Says which half is missing. |
| Toast "Some health data could not be refreshed." | **"Some health checks couldn't be refreshed. Showing the last results retrieved."** | Says what the operator is now looking at. |
| "Refresh health" / "Refreshing…" / "Last checked" / "Needs attention" / "No issues found" / "Health check incomplete" | **keep** | Already exact. "Checked" truthfully describes an attempt, not a success. |
| Issue labels and help text | **keep verbatim** | These are population definitions. Changing them is out of scope. |

Copy changes affect `operator_live_test.exs` (~L4640, 4761, 5737, 5791) and
`persona_cohort_test.exs:116`. Update those in the same plan. Run `voice_test.exs`.

---

## 5. Bounded comparison: A vs B

**Candidate B (deliberately grouped).** The observation group spans the top. Below it,
`@container (min-width: 56rem)` gives `grid-cols-[minmax(0,42rem)_16rem] gap-xl justify-start`:
the issues column, then an **aside** for activity framed as `bg-base-200 rounded-box p-md`,
top-aligned with the verdict. The columns are sized to their content, not 2fr/1fr. Below 56rem it
is identical to A. DOM order: observation, status, activity.

**Bounds.** Exactly two candidates. Fixed scenarios: normal-many (all 8 categories), one issue,
none-active, empty, stale-partial (`phase169-health-partial`), unavailable (an armed reader fault),
and long-count. Fixed container widths: 288, 358, 480, 736 and 1150px. Light theme for every case;
dark only at 358 and 1150. One design pass, then one adversarial check (§ 8). Nothing else
varies.

**How to run it (no new dependencies).**
1. Add `reference/demo_app/storybook/operator/health.story.exs` (iframe container, theme radios as
   in `inbound_evidence.story.exs`). Variations are state × width. Each renders inside a wrapper
   `<div style="width:{w}px" class="operator-health-layout">`, which exercises the container
   queries directly. During the comparison only, the story adds a story-local
   `composition: :a | :b` attribute that arranges **the same production function components**.
   Production code has no toggle.
2. Write one throwaway Playwright spec, run once from the scratchpad, using the same
   `page.evaluate` geometry style as `phase169-journey.spec.js` and `health-tooltips.spec.js`. It
   writes `177-health-comparison.json` and screenshots into the phase directory.
3. Apply the decision rule. Delete B from the story. Keep A's variations as the retained scenarios
   (STORY-07 / success criterion 4). Record the numbers in the phase decision record.

**Hard gates (both candidates must pass; failing any one eliminates a candidate):**
- G1: no overflow (`scrollWidth - clientWidth ≤ 1`) at every width.
- G2: DOM order = visual order for the ordered landmarks (observation, verdict, each issue,
  notices, activity), comparing `compareDocumentPosition` against bounding-box `top`/`left`.
- G3: period, timestamp and Refresh share one `[role=group]` ancestor. The horizontal gap between
  the timestamp's right edge and Refresh is ≤ 16px when they share a line. When they don't, the
  vertical gap is ≤ 8px.
- G4: every link and button in `operator-overview-health` is ≥ 44px tall, or ≥ 24×24 with
  WCAG 2.5.8 spacing (help icons).
- G5: the population fingerprint is byte-identical to the pre-change fingerprint (the set of
  `{testid, count, href}`).
- G6: the verdict and stale cues are present as text; no state is distinguished by colour alone.
- G7: no new axe violations (the existing axe baseline and the storybook-axe lane).

**Tie-breakers (measured, decide in this order):**
1. **Scan path:** the vertical distance from the observation group's top to the last issue's
   bottom. Lower wins.
2. **Row slack:** the issue row's width minus its content width (count + label + help). Lower
   wins; the owner's "empty divider" defect.
3. **Activity subordination:** the activity heading's font-size is below the verdict's, the
   activity count's font-size is ≤ the issue count's, and activity does not visually precede any
   issue (its top ≥ the verdict's top in B; ≥ the last issue's bottom in A).
4. **Simplicity:** the number of layout rules and breakpoints. Fewer wins.

**Expected outcome: A.** It ties or wins on 1, 2 and 4. B's only advantage is filling the
1150px whitespace, and it reintroduces "activity beside the list", which the owner reported twice.
If A fails G3 or G4 at 288px and B passes, B cannot rescue it, because the two are identical
below 56rem. Fix A instead.

---

## 6. Retained test assertions (merge-blocking lanes; reuse existing helpers)

**Playwright** (extend `e2e/phase169-journey.spec.js`'s width loop and `e2e/health-tooltips.spec.js`; widths 320/390/768/1024/1280/1440):
- Replace `metricColumns == (width<1024?1:2)` with `getComputedStyle(health column).gridTemplateColumns` resolving to a single column, plus `healthColumn.getBoundingClientRect().width ≤ 42*16+1`. Address elements by `data-testid`, not `nth-child`.
- G1–G4 and G6 as above, on the real route `/ops/mail?tenant_id=browser-tenant`, plus `?scenario=phase169-health-partial` and an armed `browser-mutate` reader fault for the unavailable state.
- **Deep-link landing (owner request):** for each `[data-testid$="-link"]` issue row, read the count, click, assert the URL params (`event=`, `outcome=`, `focus=`/`webhook_event_id`) and assert that the visible matching rows equal the count when it is ≤ the page size. Today `operator.spec.js:549` and `phase169-journey.spec.js:502` cover two rows; this covers all of them.
- Focus: Tab from the Account control reaches period help, then timestamp copy, then Refresh, then issue links in DOM order. Each focused element has a non-`none` outline (`mg-focus-ring`). It must not be obscured (WCAG 2.4.11).
- Refresh: the existing repeated-click test stays. Add that focus remains on Refresh after the patch, and that `#mg-copy-toast` (`role=status aria-live=polite`) carries the success or partial message.
- Storybook: add the Health variations to the storybook-axe selection so they share the axe lane.

**ExUnit** (`operator_live_test.exs`):
- A population-fingerprint golden: render the overview for the fixture Account and assert the exact list of `{testid, count, href}`. Capture it **before** the refactor (G5). It must also fail if issues are re-sorted by count, which makes it a mutation proof against inferring severity from count.
- Structure: the observation group contains the period, timestamp and button (Floki). Activity follows status in the DOM. No `order-` classes inside `operator-overview-health`.
- Stale or unavailable never renders "No issues found" (existing rule; keep the test).

---

## 7. Accessibility notes

- **1.3.2 Meaningful Sequence:** remove today's `order-2`/`order-3` reordering.
- **4.1.3 Status Messages:** keep one polite live region (the toast). The per-panel notices are
  persistent `<p role="status">` elements, which can announce on every patch and duplicate the
  toast after a failed refresh. Recommend plain `<p>` elements. They are static explanatory text,
  and the toast announces the change.
- **2.5.8 Target Size:** issue links go to `min-h-11`. Help icons stay at 24×24.
- **1.4.1 Use of Colour:** the verdict and stale states are text-led, and icons are `aria-hidden`.
- **1.4.10 Reflow:** container queries keep 400% zoom at 1280px (= 320 CSS px) identical to the
  phone layout.

---

## 8. Adversarial check (against Candidate A)

1. **"A wide empty right side looks unfinished at 1440."** Real risk; the owner's complaint is
   aesthetic. Counter: a constrained measure is standard practice (GOV.UK two-thirds column,
   45–75ch readability). Every alternative fills the space with low-value content. If the owner
   still rejects it, the fallback is B: brand/visual identity is a legitimate D-52 owner hand-off.
   Do **not** fill the space with zero-count KPI cards, which the design system bans.
2. **"Uniform rows hide that 50 failed matters more than 1 deferred."** That is accepted by the
   requirement. The fixed taxonomy order already lists hard failures before delays, and it is
   defined, not computed. Adding colour or weight per count would violate "no severity from count
   alone". Guarded by the fingerprint test.
3. **"Grouping the period with freshness contradicts design-system.md."** True. Amend the section
   in the same change: the period and the timestamp are both *observation basis*; Refresh stays
   adjacent to the timestamp.
4. **"Activity below 8 rows is invisible on mobile."** It is bounded: at most 8 rows of about 44–64px
   each. It is subordinate by intent, and it remains a heading for screen-reader navigation.
5. **"Container queries break the Storybook/real-route parity."** The opposite holds. Viewport
   breakpoints are what break parity, because the story iframe has no sidebar. The parity check:
   the real route at 768 viewport must equal the story at a 480px container (compare the
   G2/G3 measurements).
6. **"'Last checked' lies when part of the refresh failed."** It names the attempt time, and
   per-panel notices carry the last successful time. Keep both, and keep them distinct.
7. **"Moving markup out of the LiveView might move logic."** Restrict the move to presentation
   only (attrs in, HEEx out). `retry_health`, `health_issues/7` and `load_health_observations`
   stay in `OperatorLive`.

No material issue remains after these mitigations, so one design pass plus this check suffices.

---

## 9. Rejected alternatives

- **Keep 2fr/1fr and add padding.** The owner explicitly said padding alone does not solve it, and
  the viewport breakpoint misfires at tablet widths.
- **Refresh in the page header or shell actions.** It would separate Refresh from freshness and
  crowd the Account and theme controls (UXF-09 is compacting those).
- **A health score or KPI-card grid.** It drops specific items and links; the owner's "keep" list
  and the design system both forbid it.
- **Sorting or colouring by count.** It infers severity from count, which is prohibited.
- **Auto-refresh or polling.** It changes the freshness semantics, adds noise to live regions, and
  was not requested. Manual Refresh stays.
- **Activity as sparklines or charts.** It invents a time-series population, and it is decoration
  for a triage page.

---

## 10. Prior art (patterns, not imitation)

- **Grafana / Kibana / Datadog:** the time range picker and the refresh control are always one
  adjacent cluster. This is the strongest precedent for "period + freshness + Refresh = one
  group". Grafana docs: https://grafana.com/docs/grafana/latest/dashboards/use-dashboards/ ;
  Kibana: https://www.elastic.co/guide/en/kibana/current/set-time-filter.html
- **Oban Web:** state counts are filter links into the matching job list. That matches our
  "specific issue → scoped deep link". https://hexdocs.pm/oban_web
- **Sentry Issues:** a list of specific problems, each opening the evidence. Users choose the
  ordering explicitly (it is not inferred from volume alone). https://docs.sentry.io/product/issues/
- **Postmark / SendGrid / Mailgun stats dashboards:** rate charts and KPI tiles answer "how are we
  trending", not "what do I fix now". They are the anti-pattern for this job. (Product
  familiarity; not re-verified in this pass.)
- **Status pages (Atlassian Statuspage, GitHub Status):** a verdict sentence first, then the
  components, with "last updated" stated plainly.
- **GOV.UK layout:** a two-thirds reading column with whitespace accepted.
  https://design-system.service.gov.uk/styles/layout/
- **Google SRE, "Monitoring Distributed Systems":** pages must be actionable; symptoms before
  causes. https://sre.google/sre-book/monitoring-distributed-systems/

## Sources

- WCAG 2.2: 1.3.2 https://www.w3.org/WAI/WCAG22/Understanding/meaningful-sequence ·
  1.4.1 https://www.w3.org/WAI/WCAG22/Understanding/use-of-color ·
  1.4.10 https://www.w3.org/WAI/WCAG22/Understanding/reflow ·
  2.4.11 https://www.w3.org/WAI/WCAG22/Understanding/focus-not-obscured-minimum ·
  2.5.8 https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum ·
  4.1.3 https://www.w3.org/WAI/WCAG22/Understanding/status-messages
- MDN, CSS container queries: https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_containment/Container_queries
- Tailwind v4 container queries: https://tailwindcss.com/docs/responsive-design#container-queries
- Repo: `brandbook/brand-book.md` § Voice; `mailglass_admin/docs/design-system.md` § Investigation
  controls and health signals; owner todos cited in § 0; `.planning/REQUIREMENTS.md` acceptance
  "Composition and interaction" / "Responsive/accessibility evidence".
