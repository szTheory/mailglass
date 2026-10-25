# Fractal Storybook: Research and Recommendations

**Status:** recommended, not yet scheduled. Seed: `.planning/seeds/SEED-009-fractal-storybook.md`.
**Raised by:** the owner, 2026-10-25, who called it "the next major opportunity" for mailglass UI quality.
**Inputs:**
- a codebase inventory;
- the phoenix_storybook 1.2.0 source, read under `reference/demo_app/deps/phoenix_storybook/`;
- ecosystem research: Storybook docs, Brad Frost's *Atomic Design* ch. 2, Chromatic, Playwright, Primer, Lookbook, GOV.UK, WCAG 2.2.

## The owner's intent

Build stories at every level of the UI:
- fine-grained primitives;
- small groups of components;
- each area within a section;
- whole sections;
- whole pages and JTBD flows.

The stories should cover every combination that actually happens in the UI: happy paths, error cases and boundary conditions, across every JTBD section. Scenarios that would never happen get pruned aggressively. Seed and fixture data gets sanity-checked for realism.

Each scenario should be easy to zoom into and scrutinise. Stories run much faster than e2e tests.

The quality bar is the review rubric below. Everything must be mobile-first and work at every realistic viewport width.

### Review rubric: every story and every UI review is judged against this

1. **Light and dark** both look good. Colors are never tacky.
2. **Typography** looks professionally designed, intentional rather than accidental.
3. **Information hierarchy** and content structure are easy to follow and elegant, not ham-fisted.
4. **Nothing is redundant.** No element repeats what another already says.
5. **Every JTBD's happy path** is great, and power users are well served too. The target is an iPhone-quality feel and an award-winning bar, never "AI slop".
6. **Microcopy** is consistent and uses user-facing domain language, never internal jargon. Check it against the CLAUDE.md domain nouns and the brand voice.
7. **Personas and JTBDs** are kept curated and sanity-checked. If a story contradicts a persona, either the story or the persona is wrong.
8. **The journey is coherent** across the whole UI and within each section. Navigation feels natural, and it is a joy to use.
9. **Mobile-first.** The UI works at 320 px with no page-level horizontal scroll (WCAG 1.4.10) and has touch targets of at least 24 px (WCAG 2.5.8; the project's own floor is 44 px for primary controls).
10. **Principle of least surprise.** Affordances look like what they do, and the design system pays off: one pattern per job.

## Where we are today (measured 2026-10-25)

- **Storybook** (`reference/demo_app/storybook/`, phoenix_storybook 1.2.0, dev-only) covers 5 primitives: nav_link, nav_pill, stat_card, tenant_chip and theme_picker. It also has one static Foundations page. There are no group, section or screen stories.
- **The gallery** (`mailglass_admin/lib/mailglass_admin/gallery_live.ex`, 1428 lines, static maps) is the real inventory today.
  - It covers about 30 specimens: primitives, groups, three "composed" stacks and the Fjordline stress set.
  - Each specimen renders in light, dark and system.
  - About 80 e2e references depend on its testids, mainly `gallery-matrix.spec.js` and `structural.spec.js`.
  - It ships inside the Hex package, under the preview mount.
- **Not covered by stories or the gallery:**
  - The shell, account context and tenant selector.
  - Both health overviews, both quick views, and the replay modals in their open, target and stale states.
  - The inbound filters, preview sidebar and assigns form.
  - The unsubscribe pages.
  - Every whole-section or whole-page composition.
- **Components are DB-free.** `mailglass_admin/lib` never touches the Repo; components take plain maps. Everything below the LiveView can be storied from fixtures.
- **The LiveViews are monoliths.** OperatorLive is 2710 lines, with about 450 lines of inline render markup. InboundLive is 1943 lines and PreviewLive 1144. Screen stories cannot render them, because they need session, params and DB reads.
- **Fixture data:**
  - `reference/persona_spec/personas.ex` defines three personas: northstar (high volume, errors), fjordline-aps (long IDs, non-ASCII, nil reject reason) and helios-void (no data).
  - The demo seeds (`demo_data.ex`) and test fixtures insert into the DB.
  - The gallery inlines persona literals, held to the spec by `persona_drift_guard_test.exs`.
- **Viewports drift.** Every spec picks its own widths: structural uses 8, gallery-matrix 4, phase173 2. Stories are visited at a single width.
- **Prior decisions this supersedes:**
  - v1.13 rejected phoenix_storybook.
  - v1.14 adopted it as dev-only.
  - Phase 173 D-02/D-03 kept the gallery as the complete inventory and storybook as a curated subset, and ruled out a shared specimen framework.

  The owner's 2026-10-25 direction supersedes D-02/D-03 for the next UI milestone. See Decision 1.

## What phoenix_storybook gives us (verified in source)

- **Story kinds** (`stories/story.ex`):
  - `:component`, for a function component with variations.
  - `:live_component`.
  - `:page`, free-form with no variations.
  - `:example`, a child LiveView with `mount/render/handle_event` but no `handle_params`. This is the kind for sections and screens.
- **Arbitrary folder depth.** `*.index.exs` sets folder names, icons and order, so the levels map directly onto folders.
- **Per-variation URL** `/dev/storybook/iframe/<path>?variation_id=<id>&theme=&color_mode=`. It renders one variation in a bare layout, which is the right target for Playwright, axe and screenshots.
  - Footgun: only top-level variation ids are addressable, so a variation inside a `VariationGroup` has no URL of its own.
- **Story enumeration API:** `Backend.leaves/0` → `load_story/1` → `variations/0`.
  - Footgun: the dep is dev-only, so the API does not exist under `MIX_ENV=test`. A dev-run manifest generator is needed.
- **No built-in viewport control** (issue #49 is open). The idiomatic approach is Playwright with `setViewportSize` on the iframe URL.
- **Themes and color mode** (`themes:`, `color_mode: true`) could replace the hand-duplicated `_light`/`_dark` variations, roughly halving the variation count. Check it against `TokenParityTest` first.
- **Costs:**
  - It pins phoenix and LiveView tightly, so every minor upgrade needs a storybook release.
  - 1.2.0 pulls `mdex` (a Rust NIF, precompiled).
  - `:eager` compile mode recompiles on any added or removed story file.

  All of this is dev-only and never reaches adopters.

## Recommendations (one coherent set)

### Decision 1: Storybook becomes the single, fractal review surface, and the gallery is retired into it

Two hand-maintained inventories is the antipattern every source flags. The gallery's matrix ships to adopters who never asked for it, while the storybook already has the tree, URLs and playground we need.

Migrate the gallery's specimens tier by tier, porting its e2e assertions to the story sweep (Decision 5). Delete `GalleryLive` and its route once nothing references them. This supersedes Phase 173 D-02/D-03. It adds no dependency: phoenix_storybook is already dev-only in the demo.

*Rejected: keeping the gallery as "complete" and storybook as "curated".* That is exactly the drift we keep paying for, such as the long-label specimen that existed in both.

### Decision 2: four tiers, foldered by product IA rather than atomic jargon

```
storybook/
  foundations        (tokens, type scale, color: page stories)
  primitives/        (nav_link, status_badge, stat_card, copy_value, timestamp, …)
  patterns/          (small groups: filter_section+fields, detail_header, timeline, routing_trace, evidence_card, pagination, …)
  operator/          (sections, then areas within them)
    overview/        health overview, orientation strip, stat row
    deliveries/      list, quick view, full detail, replay dialog
  inbound/           list, quick view, detail, routing evidence, replay
  preview/           sidebar, tabs (html/text/raw/headers), device frame, assigns form
  recipient/         unsubscribe valid / invalid / expired
  screens/           whole pages per JTBD (example stories)
```

- Tiers 1–2 use `:component` stories.
- Area stories use `:component` stories of the section's function components.
- `screens/` uses `:example` stories.
- Each screen composes the *same fixtures* as its areas, never extra mocks.

The folder names are the UI's own nouns, so the tree doubles as a map of the IA. A JTBD that has no folder is a gap.

### Decision 3: make screens storyable by extracting presentational page components

Move each LiveView's render body into a function component that takes plain assigns, for example `OperatorPage.deliveries(assigns)`. The LiveView keeps `mount`, `handle_params`, events and data loading, and calls the page component. Screen stories then render the page component from fixtures, with no session or DB.

This also pays down the 2710-line LiveView. Storybook's own guidance is to keep components "fully presentational up to the screen level".

If a screen can't be storied without heavy mocks, it is not presentational enough. Split it rather than mock it.

### Decision 4: one fixture source built from personas, checked for realism

- Extend `reference/persona_spec/` with a DB-free builders module, for example `PersonaSpec.Fixtures`. It returns exactly the maps the LiveViews pass to components: deliveries, events, timelines, inbound records, routing traces, evidence and health overviews. Stories and admin ExUnit tests share it, and the persona spec stays the root.
- Stop inlining literals in the gallery, then delete the gallery.
- **Realism invariants, enforced by a test:**
  - statuses come from the closed Anymail taxonomy;
  - `reject_reason` is only set where it is allowed;
  - timestamps are ordered (queued ≤ dispatched ≤ delivered);
  - `tenant_id` is always present;
  - no event appears without its prerequisite, so no `delivered` without dispatch;
  - no lorem ipsum, which a grep guard enforces.

  Where possible, build through core's real projection functions so that the shape cannot drift. Otherwise assert the shape against the read-model contract.
- **Boundary content comes from the domain:**
  - long and IDN recipients;
  - plus-addressing;
  - CJK, RTL and emoji subjects;
  - real-shaped provider bounce strings;
  - a delivery with 10k events;
  - a 0-row tenant.

### Decision 4a: personas are digital twins of real adopters

The owner added this on 2026-10-25. The persona set should feel like a digital twin of the kinds of software that adopt mailglass, so that every fixture, story and seed traces back to a believable product and user. Each twin specifies the following, and all fixtures derive from it:

- **Product and industry:** B2B or B2C, hosted multi-tenant or self-hosted single-tenant.
- **Mail mix:** which transactional mailables it sends. Marketing and newsletters are permanently out of scope, so twins never send them.
- **Shape:** tenant count, daily volume, locale and script mix, provider(s), and whether it uses inbound.
- **Failure profile:** typical bounces, deferrals, complaints and suppressions.
- **Operator:** who opens the admin and for which JTBD, including at least one power user.

The starting slate below extends today's northstar, fjordline-aps and helios-void rather than replacing them. Keep it to about six twins. More than that is sprawl, so each new twin must exercise a distinct equivalence class.

| Twin | Kind | Exercises |
|---|---|---|
| Northstar Logistics (existing) | B2B SaaS, multi-tenant | High volume, errors and deferrals; helpdesk inbound |
| Fjordline A/S (existing) | B2B, EU | Non-ASCII names, long IDs, nil reject reason |
| Helios (existing, void) | New tenant | Zero data: every empty state |
| A self-hosted team chat (Slack-clone) | Self-hosted, single tenant, low volume | Invites, magic links, mention digests; reply-by-email inbound; one admin who is also the operator |
| A language-learning app | B2C, global | CJK/RTL/emoji subjects and recipients, very high volume, password resets, account verification. Auth stream, so tracking is off |
| A personal-finance tool | B2C, regulated | Security alerts, 2FA codes and statements-ready mail; strict suppression and unsubscribe handling; the auth-stream no-tracking rule visible |

**Realism test for a twin:** would a real product of this kind send exactly these mailables, at this volume, with these failures? If not, fix the twin. When a JTBD has no twin that needs it, either the JTBD is wrong or a twin is missing (rubric item 7).

This is also what pushes the LiveViews toward being fully data-driven. A screen that cannot render any twin's data from fixtures alone, with no hardcoded strings or shapes, gets refactored rather than special-cased. Decision 3 depends on this.

### Decision 5: stories are the fastest test lane, via one generic sweep spec

- A dev-run task, for example `mix storybook.manifest` in `reference/demo_app`, writes `storybook-manifest.json` listing every story path and top-level variation id, with its description and screenshot flag. CI regenerates it and fails when it differs from the committed copy.
- One Playwright spec walks every manifest entry × `{320, 375, 768, 1280, 1440}` × `{light, dark}` on the iframe URL. For each, it asserts:
  - the story renders with no console errors;
  - no page-level horizontal overflow;
  - axe, reusing the existing `@axe-core/playwright` dev dependency in `mailglass_admin`;
  - interactive targets are at least 24 px.

  No code is written per story. Shard it, and run it on every PR.
- **Screenshots are opt-in.** About one key state per section per width, plus one worst case, flagged on the story. Pin the CI browser, disable animations, keep DPR fixed, mask timestamps, and use a small `maxDiffPixels`. Baselines are always reviewed and never auto-accepted.
- **Standardise the widths:** 320 (the reflow floor), 375 (phone), 768 (the `md` breakpoint edge), 1280 (laptop) and 1440 (wide). Add another width only when a breakpoint lives there. Converge the per-spec width lists onto this set.
- **Division of labour:**
  - Stories own visual states.
  - e2e owns flows and wiring: navigation, filters, LiveView events, replay submission.
  - Delete e2e assertions that only re-check a state a story already covers.

### Decision 6: a state vocabulary per component, with pruning rules

- **Each component's matrix is drawn from this vocabulary.** Every state is an equivalence class, never a raw prop permutation. Mark inapplicable states with a one-line reason, as the gallery comments already do.
  - **Content states:** happy, empty (zero rows), one, many, and page-boundary N/N+1.
  - **Async states:** loading (only if the component is async), error, permission-denied, stale or disconnected.
  - **Worst-case content:** a realistic worst-case length, non-ASCII, and a huge count.
- **Every variation's `description` names the real situation it represents,** as a persona plus JTBD, for example "northstar: a deferred delivery being retried". The manifest check fails any variation without one.
- **Prune a story when any of these is true:**
  - no caller passes that combination (grep the callers);
  - the domain forbids it;
  - it looks identical to another variation;
  - it maps to no situation;
  - it was a stress test for something the owner has ruled out, as with the nav_link long label.
- **First pruning candidates from the inventory:**
  - static "hover-ready" and "focus-visible" specimens, which render identically to inactive (test real hover and focus in the sweep instead);
  - `replay_modal` "closed", an empty frame;
  - the trivial `tabs`/`device_frame` single-button specimens;
  - duplicated `_light`/`_dark` variations, once color mode handles them;
  - `status_badge` phantom-nil, if nil is unreachable from the read model.

### Decision 7: a curation loop, not a one-time build

- **Refresh first.** `JTBD-COVERAGE.md` is marked stale. Refresh it and the personas before building the tree, because the tree is cut along JTBD lines.
- **Review every section.** At 375 and 1440, in light and dark, critique it against the rubric (the v1.14 adversarial persona-critic loop, now pointed at story URLs). Record findings and fix them at the lowest tier that owns them, following Frost: fix the pattern, not the page.
- **Prune on a schedule.** Run a pruning pass every milestone, and use stories-per-component as the sprawl signal.

### Decision 8: one design language, checked in layers from static lints up to the owner

The owner added this on 2026-10-25, alongside the cross-repo version of this methodology at `~/Documents/ui-storybook-stresstest-methodology-prompt.txt`. Visual tokens and verbal tokens are kept consistent and checked by machines wherever possible:

- **Visual tokens:** color (light and dark), type scale, spacing, radius, shadow and elevation, z-index layers, motion, focus ring.
- **Verbal tokens:** voice, microcopy patterns, and a user-facing glossary built from the CLAUDE.md domain nouns. Internal jargon never reaches the UI.

The checks run in layers, cheapest first. Existing violations go into a ratchet baseline that may only shrink.

- **L1, static (blocking):**
  - `brandbook/tokens.css` is the single source; `@theme` drift is tested against it.
  - Ban arbitrary Tailwind values, inline `style=`, raw hex, and `z-<n>`.
  - Run a static contrast matrix over every token pair in both themes.
  - Lint copy against the glossary.
  - Check that the story manifest is current.
  - The `TokenParityTest` and daisyUI vendoring constraints apply, so any namespace reset must be spiked first.
- **L2, story sweep (blocking):**
  - Everything in Decision 5.
  - Computed-style token membership: font-size, radius, shadow, z-index and duration must each resolve to a token.
  - A focus tab-walk (visible 3:1 ring, never obscured).
  - An identical navigation ARIA snapshot on every page.
  - A glossary and voice lint over rendered text and accessible names.
- **L3, screenshots:** opt-in only (Decision 5).
- **L4, LLM design judge (advisory, never gating):**
  - Run on demand by an agent, built on the `impeccable` and `ux-writing` skills, with no paid service.
  - Binary verdict per rubric item, with evidence.
  - Pairwise head-vs-main comparison in both orders, keeping only verdicts that agree.
  - Never reports anything L1–L3 already own.
  - Calibrated on owner-directed fix commits and decisions.
- **L5, owner:** the owner reviews triaged findings only. Every decision goes into a machine-readable decisions log. A decision made twice becomes an L1/L2 rule or a judge calibration example.

## Antipatterns to refuse

- Prop-permutation sprawl, meaning full Cartesian matrices.
- Stories that render data or slots the app never passes.
- Screens that need a DB, PubSub or router mocks. Split the screen instead.
- A second inventory next to the storybook.
- Snapshotting every story at every width, which causes snapshot fatigue.
- Visual assertions copied into e2e.
- Any new dependency for the sweep. The axe dependency already exists, and overflow and target-size checks are about 30 hand-written lines.

## Open questions for planning, not for the owner

- Can `themes:` or `color_mode` replace the `data-theme` templates without breaking `TokenParityTest`? Spike it.
- Manifest delivery: a dev `mix run` task that writes JSON, or a dev-only route? The task is preferred because it can be diffed in CI.
- Gallery removal touches about 80 e2e references and an adopter-visible dev route (`/dev/mail/gallery`). Plan it as the last migration step, with a CHANGELOG note.
