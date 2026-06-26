# v1.14 — Design-System Stress-Test Prompt (binding quality bar)

> This is the user's verbatim prompt for the v1.14 "Operator IA & Lived-Experience Redesign"
> milestone. It is the **binding acceptance-criteria reference** and **must not be diluted,
> over-sanitized, or flattened** during milestone planning/execution. The newest brand book
> (`brandbook/brand-book.md`) wins over any older prompt-era research if they conflict.

## Original intent (user, verbatim)

Strengthen the **design system** of the admin/operator UI now that the brand book is strengthened.
Audit systematically at **each level of abstraction** — individual components, component groups
(meta-components / repeatable configurations, "like Storybook"), pages, and flows. For each
component AND each group as it would actually be used:

- On-brand colors/typography/padding/spacing, shape/border-radius, shadow, animation, interaction
  modes — evaluated on their own merit and amazing quality in **light + dark + system**.
- Great animations following Emil Kowalski's best practices (https://emilkowal.ski).
- Principle of least surprise; GOV.UK-style information architecture; great for onboarding +
  intermediate + advanced users along happy paths, main error cases, and boundary conditions.
- Each component AND each group judged through the **user flow / hat / JTBD** that would use it.
- Mobile-first responsive, looks great at every width.
- Micro-animations + UX microcopy knocked out of the park; internally coherent/consistent;
  award-winning professional graphic design; on-brand voice serving the JTBD.
- Adjust seed/fixture/example data where needed to exercise real user flows (happy/error/boundary/
  edge) — but the primary goal is the design system being elegant/beautiful/working, in the context
  of real user flows.
- For each decision point, research online via subagents (context-efficient), consider all
  approaches / best practices / anti-patterns / footguns / lessons from comparable UI/UX/libs/apps/
  brands/design-systems + real user feedback (loved/hated and why), weigh pros/cons/tradeoffs/
  examples, and **adversarially judge each level of abstraction** to synthesize the best one-shot
  choice. Idempotent: **only move forward in quality, no regressions.**

### Example usability issues to catch
Scroll that doesn't scroll; modal/drawer behind a dark scrim you can't interact with; awkward
scrollbars; hover states on non-interactive empty-state heroes; floating elements covering content;
misaligned elements; awkward padding / content chopped off one side; inconsistent (accidental-looking)
spacing; modals not popping/dismissing correctly or floating in a weird spot; disabled fields that
don't look disabled; weird focus/hover states; unreadable button text (same color as bg); poor dark-
mode contrast; no full system/light/dark theme picker (system default); elements flush inside
containers with no breathing room; tabs not showing active state; cards-in-cards over-boxed; weird
pagination when there's nothing to paginate; squished unreadable table columns; tables overused
instead of cards/lists; inconsistent stat-card design; icons that don't read semantically.

## Inflated companion prompt (user, verbatim — expansion layer, do not replace original)

Act as a combined team: Principal Elixir/Phoenix/LiveView architect; OSS maintainer with excellent DX
taste; design-systems lead; UI/UX/product designer; accessibility specialist; motion/interaction
designer; UX writer/content designer; QA/visual-regression engineer; SRE/operator-experience
reviewer; security/privacy reviewer for admin surfaces; adversarial regression judge.

Mission is not check-the-box — find dark spots, hidden tradeoffs, UX footguns, visual
inconsistencies, interaction failures, ecosystem anti-patterns, and compounding-dividend
opportunities for the **admin/operator UI of this Elixir/Phoenix OSS library**. Treat it as a serious
library product: beautiful, coherent, accessible, idiomatic, maintainable, host-app-friendly,
pleasant for both integrating developers and operators/admins.

**Read all context first:** original prompt, codebase, `prompts/`, newest brand book (newest wins),
existing components/LiveViews/HEEx/CSS/Tailwind/daisyUI/theme/JS-hooks/tests/fixtures/seeds/
screenshots/docs/Storybook artifacts, existing conventions. Improve from within existing architecture
unless strong reason to refactor.

**Do deep current research** before finalizing: official docs + mature design systems (Phoenix/
LiveView, PhoenixStorybook, W3C/WAI WCAG 2.2/APG, GOV.UK Design System + Service Manual, Carbon/
Polaris/Atlassian, Storybook/Playwright/axe, Emil Kowalski). Research comparable admin/operator UIs:
Phoenix LiveDashboard, Oban Web, Backpex, Kaffy, AshAdmin, Django admin, Rails ActiveAdmin, Sidekiq
Web, Laravel Nova, Retool-like tools, cloud/observability dashboards. For each decision capture
options/pros/cons/tradeoffs/examples/idioms/footguns + why-chosen. Don't cargo-cult; synthesize
project-specific. Research is not theater — pull wisdom into concrete choices.

**Subagent research roles:** (1) Repository Cartographer; (2) Brand + Visual Design Auditor; (3)
Elixir/Phoenix/LiveView Ecosystem Researcher; (4) Accessibility Specialist (WCAG 2.2 AA + APG); (5)
Motion + Interaction Designer; (6) Admin/Operator UX Researcher (real users + JTBD: dev evaluating,
dev integrating, maintainer debugging, operator monitoring/filtering/investigating/retrying, SRE
on-call under stress, security reviewer, contributor); (7) UX Writing/Microcopy Reviewer; (8) QA/
Visual-Regression/Testing Engineer; (9) OSS/DX Reviewer; (10) Adversarial Judge (regression check).

**Decision brief format** for every significant decision: decision/problem; user/job affected;
current state; options; pros/cons/tradeoffs; what's idiomatic for Elixir/Phoenix/LiveView and why;
what mature comparable systems do well/poorly; a11y implications; DX/maintainability; performance/
security where relevant; recommendation; rejected alternatives + why; implementation notes;
tests/fixtures/docs to lock it in.

**Audit scope (fractal):**
- **A. Foundations:** color (semantic tokens incl. surfaces/elevated/borders/dividers/accent/info/
  success/warning/danger/destructive/overlays/focus-rings/charts/code-log/selected; no one-off hex;
  light/dark/system; system default; contrast everywhere); typography (scale, hierarchy, line-height,
  mono/code, long identifiers readable); spacing/layout (consistent scale, breathing room, no
  accidental flush/chopped edges, admin density, mobile-first); shape/radius (consistent, brand-
  matched, nested cards not over-boxed); shadows/elevation (subtle, theme-aware, clear layering);
  borders/dividers (clarify not noise); icons (semantic, consistent, readable, not sole meaning-
  carrier); motion tokens (durations/easings, reduced-motion, rules for micro-interactions/overlays/
  lists/loading/toasts/destructive); z-index/layers (formal: base/sticky/dropdown/popover/overlay/
  modal/toast; no modal behind scrim; no floating cover); breakpoints/density (320/375/768/1024/1280-
  1440/wide; no unreadable mobile tables → cards/lists/disclosure); content/voice (direct/consistent/
  useful/on-brand).
- **B. Primitives** (each in isolation + every state): button, icon-button, link, badge/tag/pill/
  status, tooltip, popover, dropdown/menu, tabs, segmented control, accordion/disclosure, modal/
  dialog, drawer/sheet, toast/flash, alert/banner/callout, spinner/progress/skeleton, empty state,
  error state, code/log/JSON inspector, divider, card/panel, stat/KPI tile, avatar/entity icon.
  Per primitive: clear purpose+variants (semantic names); light/dark/system; hover/focus/active/
  pressed/disabled/loading/selected/current; accessible name/role/keyboard; looks-clickable-only-when-
  clickable; no hover on non-interactive heroes; correct motion + reduced-motion; examples/stories/
  fixtures for normal/long-text/empty/error/disabled/loading/high-count/narrow.
- **C. Form components:** inputs/textarea/select/combobox/checkbox/radio/switch/number/date/search/
  filters/field-groups/error-summary/inline-validation/help/required-optional/disabled-readonly.
  Visible associated labels; programmatic help+error; recovery-oriented error copy; disabled looks
  disabled; read-only distinct from disabled; responsive; validation not color-alone; focus never
  hidden after LiveView patch; clear submit/loading/success/failure; destructive confirmation.
- **D. Navigation + app shell:** sidebar/topbar/header, breadcrumbs, titles/subtitles, tabs, search/
  filter toolbar, pagination, back/cancel, theme selector, account/menu, mobile nav, active/current.
  Users always know where they are; active item obvious in light+dark; labels match domain language;
  keyboard/SR nav; sticky doesn't cover content; no unusable nested mobile scroll; pagination
  de-emphasizes when nothing to paginate; clear filter affordances not wasting space.
- **E. Data display / operator patterns:** tables/grids, card/list alternatives, detail views,
  key-value metadata, timeline/event-log, metrics/charts, status summaries, filter chips, bulk/row
  actions, empty/zero states, error/loading/stale states, pagination/streams. Operators scan what
  matters fast; status/severity/entity/time/next-action clear; no squashed columns; graceful long
  IDs/names/paths/emails/URLs/traces/atoms/modules/queues/nodes/timestamps; copy/truncation +
  tooltip/expand; obvious sort/filter; dangerous actions separated+confirmed; bulk discoverable not
  accidental; empty states explain next; error distinguishes no-data vs unavailable vs permission-
  denied; charts readable not color-alone; clear timezones/relative-absolute.
- **F. Component groups / meta-components:** page-header+actions+breadcrumbs; toolbar+search+filter+
  sort+view; table/list+empty/loading/error/pagination; stat-cards+chart+table; detail-header+
  metadata+action-menu; modal-confirm+destructive; drawer+form; toast+state-update; tabs+detail;
  empty+CTA; permission-denied; reconnect/offline+disabled-actions; onboarding callout. Per group:
  intentional spacing; hierarchy makes next action obvious; repeated patterns implemented once;
  holds together narrow/wide; states line up across children; motion clarifies transitions; usable
  with long/ugly real data.
- **G. Pages and flows:** per page identify persona/hat, JTBD, top 1-3 actions, happy/empty/loading/
  error/permission-denied/boundary/advanced paths; inspect mobile/tablet/desktop/wide, light/dark/
  system, keyboard-only, reduced-motion, slow/disconnected-reconnecting LiveView, realistic + ugly
  fixtures. Special attention to the full footgun list (scroll bugs, nested scroll traps, modals
  behind overlays, screen-dark-inaccessible-modal, focus not entering/returning, escape/click-outside
  inconsistencies, awkward scrollbars, hover/focus on non-interactive, floating-wrong-spot,
  misalignment, chopped content, inconsistent spacing, unreadable dark text, button-text=bg, tabs
  without selected state, card-in-card box prison, weird pagination, squished columns, table overuse,
  inconsistent stat cards, non-semantic icons, layout-jump loading, misleading skeletons, toasts
  obscuring controls, disabled-looks-enabled, enabled-looks-disabled, dangerous-near-safe, blaming
  copy, perfect-seed-data-only states).

**Fixtures/seed stress tests:** no-data, one, many, very-long names, long UUIDs/IDs, long module/
function names, long URLs/paths, non-ASCII names, high counts, zero counts, null/missing optionals,
failed/error, warning, mixed severity, permission-denied, disabled feature, slow/stale,
disconnected/reconnecting, multi-tenant/scoped, timezone edges, boundary pagination, dense-operator +
sparse-onboarding.

**Elixir/Phoenix guidance:** reusable function components w/ documented attrs+slots; boring/explicit/
stable APIs; push repeatable decisions into components/tokens (no class-soup); LiveComponents only for
stateful reuse; LiveView.JS for simple show/hide/toggle/focus/transition; hooks only when browser
APIs truly needed; no assumptions about host auth/Repo/layout/theme/routes/assets; no global CSS/JS
collisions (namespace); customize Tailwind/daisyUI via semantic tokens so it isn't generic; account
for Phoenix 1.8+/Tailwind v4/daisyUI; runtime host choices not compile-time; clear route mounting/
security/telemetry/Repo/assets; no single-Repo/tenant/node assumption; friendly Ecto errors; avoid
N+1 + heavy assigns; streams/pagination for growing data; respect CSRF/auth; destructive actions
explicit/audited/hard-to-trigger; copy-pasteable OSS docs.

**Theming:** semantic tokens not raw colors; primitive palette separate from semantic roles; every
role has light+dark; system follows prefers-color-scheme unless user chose; persist only where app
owns the preference; no hard-coded color breaks dark mode; verify charts/code/scrollbars/focus-rings/
overlays/disabled in dark; CSS variables as runtime layer; token-driven Tailwind theme vars; strong
brand without losing legibility.

**Acceptance criteria:** WCAG 2.2 AA (keyboard completes every flow; visible/unobscured/restored
focus; comfortable touch targets; dialogs trap+name+predictable-close+restore; tabs ARIA/keyboard;
honest menu/popover semantics; tooltips not sole access; never color-alone; errors connected to
fields; explicit labels; icon labels/decorative-hidden; reduced motion; landmarks/headings; manual
checks too). Motion: subtle/useful/brand-consistent; immediate feedback; right easing/duration;
responsive enter, non-lingering exit; origin-aware popovers/menus; subtle pressed feedback; no
scale(0); restrained spring; no parallax/big-motion in admin unless it helps; reduced motion; motion
never hides/delays/obstructs operator feedback. Content: clear>clever; specific>generic; domain
language>jargon (unless devs + useful term); errors say how to recover; empty states teach next step;
non-anxious loading; destructive confirms name object+consequence; success confirms what changed;
warning explains risk+next; avoid "oops/invalid/forbidden/please/sorry/failed" unless useful; same
term for same concept everywhere.

**Information architecture:** organize by operator mental model (not module structure, unless users
are devs expecting it); top tasks visible/low-friction; advanced tools discoverable not
overwhelming; nav matches domain nouns/workflows; critical status visible early; progressive
disclosure over walls of controls; preserve power-user efficiency (keyboard, dense views, filters,
stable URLs, copyable IDs, direct links).

**Idempotent loop:** establish current state + conventions → inventory components/groups/pages →
research+decide before foundations → improve foundations/tokens → primitives → groups → pages/flows →
fixtures/stories/tests → run checks → adversarially review for regressions → document decisions+next.
Fix systemic root causes not symptoms; prefer shared components/tokens over per-page patches; cohesive
reviewable diffs; no unnecessary deps; don't rewrite whole UI unless architecture blocks quality;
preserve public APIs unless justified+documented; run formatters/tests/builds; add smallest high-
leverage tests or recommend; manual visual QA matrix + stress route/stories where visual testing not
feasible; explain blockers + best practical alternative.

**Checks to run/recommend:** mix format; mix test; assets.build/deploy; credo/dialyzer; LiveView
tests; browser tests (modals/drawers/dropdowns/keyboard/focus/theme/responsive); a11y scans
(opened dialogs too); manual keyboard + light/dark/system + reduced-motion walkthroughs; visual
snapshots if feasible; component story/stress review across viewport matrix.

**Viewport/theme/state matrix (minimum):** 320/375/768/1024/1440/wide × light/dark/system × empty/
loading/error/permission-denied/long/dense/keyboard-focus/hover-active-pressed/disabled-readonly/
LiveView-reconnect.

**Expected output:** expert synthesis (not shallow checklist): (1) executive summary (changed/
recommended, biggest wins, biggest risks, do-first-if-limited); (2) research synthesis (Phoenix/
LiveView + mature design systems + admin UIs + a11y/motion/content lessons, applied to this project);
(3) component/design-system inventory (foundations/components/groups/pages/missing); (4) decision
briefs; (5) issues by severity (Critical/High/Medium/Low + files + fix); (6) implementation plan or
summary (cohesive); (7) testing evidence (commands, manual checks, pass/fail, untested+why); (8)
regression guardrails (new tests/stories/fixtures/checklists; how future runs avoid reintroducing
problems); (9) final adversarial review (what could be wrong, tradeoffs accepted, alternatives
rejected, what a skeptical maintainer/operator/a11y-reviewer/OSS-contributor would criticize).

**Quality bar:** polished, professional, cohesive admin/operator UI for a serious OSS Elixir/Phoenix
library — NOT disconnected Tailwind snippets / generic daisyUI / random cards/tables / demo screen
that only works with perfect data. On-brand; accessible; fast enough; responsive; stable under ugly
real data; clear under operator stress; easy to integrate; easy to extend; boring where boring is
good; beautiful where beauty improves trust+clarity; principle-of-least-surprise throughout;
idempotently improving each pass.

**Hard rule: only move forward / improve — no regressions.**

## User's focusing addendum (verbatim intent)

Focus **page-by-page**; within each, identify groups of components / interaction modules and fix the
biggest usability + visual issues (overcrowding etc). **Clean up one page at a time, starting with the
biggest-impact one**, then roll through the remaining pages/sections making them consistent with the
cleaned-up ones. Identify the **1-3 most important** surfaces and really nail the cleanup from a
JTBD/user-flow perspective — all language nice, streamlined, no redundant UI elements, insanely
polished award-winning graphic design (still responsive mobile-first). Many obvious issues today read
as an **info-dump instead of a streamlined focused interaction model** — clunky/verbose. Want an
**Apple-like** elegant, deliberate, purposeful experience; nothing should feel accidental. Comb every
level of UI granularity; IA must be user-flow-focused and bespoke/designed, never verbose/dry/
unintentional; industrial-design-award-winning; intuitive; polished; everything fits together.
Catching these issues may require **showing the user** each component/group/page — possibly via
**Phoenix LiveView Storybook** as a "preview" with fictional test data more versatile than the seeded
click-around demo. Consider **adversarial persona/JTBD agents** to evaluate everything. Do it as a
**proper GSD milestone** ending coherent/consistent/intuitive/least-surprise/elegant/intentional.
