# Fractal Storybook as Mailglass's UI quality engine

Date: 2026-10-26. Status: researched design/engineering recommendations; **no milestone opened, no product code or dependencies changed**. The current scope/sequencing authority is [UPSTREAM-SCOPE.md](UPSTREAM-SCOPE.md), refined after the owner's live feedback; [MILESTONE-PROPOSAL.md](MILESTONE-PROPOSAL.md) is its short projection. This file preserves the baseline rationale. Known Inbound/Preview repairs now belong in the next envelope alongside Delivery repairs; six profiles and broad extraction are not prerequisites. Inventory and specialist evidence live beside this file.

## Owner intent and scope

Make realistic UI situations easy to inspect at every useful scale: **components → small groups → areas within a section → whole sections → whole pages per job**. Use the exact production components and believable, synthetic adopter scenarios. Cover happy paths, failures and boundaries; actively remove impossible or redundant scenarios. Turn routine correctness into cheap checks so owner review concentrates on coherent journeys and design judgment.

The quality target is intentional, restrained and professionally designed: clear typography and hierarchy, appropriate density, consistent language, useful affordances, excellent mobile behavior, light/dark/System fidelity, accessible interaction and efficient power-user paths. “iPhone-designed” is a craft target, not a direction to mimic iOS chrome or change the Mailglass brand. No story or numeric score can certify award-winning design.

The owner explicitly requests a rolling sequence of milestones and research across architecture, product, design, accessibility, security and CI cost. Their referenced methodology says:

> “THIS SESSION ENDS AT A REVIEWED PLAN”
>
> “Do NOT … change product code … add dependencies … open or modify a milestone … edit REQUIREMENTS or ROADMAP files.”

Accordingly, `MILESTONE-PROPOSAL.md` is a **proposal**, not an active GSD roadmap. The source is `/Users/jon/Documents/ui-storybook-stresstest-methodology-prompt.txt`; the relevant intent and decisions are captured here so future sessions need not depend on that external file.

## Decisions and alternatives

| Decision | Recommendation and why | Rejected alternative / cost |
|---|---|---|
| First deliverable | Pair a visible recorded repair with a faithful retained story and real-route proof; complete one Delivery job early while resolving the named cross-surface feedback in the next scope candidate. | An infrastructure-only milestone postpones user value; blanket extraction of every LiveView is expensive before the seam is proved. |
| Review inventory | Evolve existing demo-hosted PhoenixStorybook into the canonical maintainer inventory, grouped by product areas/jobs. Migrate useful Gallery cases with a disposition map. | Two permanent catalogues drift; instantly deleting the published Gallery route creates unnecessary compatibility risk. |
| Composition | Function components accept explicit view data/slots/paths; LiveViews keep mount, params, loading, authorization and commands. Stories and pages invoke identical components. Extract only independently useful boundaries. | Duplicated story markup looks good while production regresses. A generic page-schema engine or socket-shaped component interface hides dependencies. One module per tiny wrapper adds ceremony. |
| Scenarios | Pure scenario definitions + pure read-model builders + separate DB materializers, extending existing persona support. Share facts, with thin adapters for persistence and presentation. | A copied persona catalogue drifts. One giant map cannot honestly serve every database/read-model/view contract. A database behind every story defeats cheap isolation. |
| Coverage | Review reachable state equivalence classes, with documented omissions and selective interaction coverage. | Cartesian products of props, personas, widths, themes and motion settings create unreviewable test volume and impossible records. |
| Dependencies | Keep pinned Storybook; reuse current Playwright, axe, tokens and assets. Write small repository-specific manifest/layout helpers. | Another framework, design system, screenshot SaaS or dependency for trivial glue conflicts with the maintainer budget. Do not hand-roll complex accessibility analysis already provided by axe. |
| Evidence | Deterministic checks own observable facts; bounded advisory critique owns design observations; owner resolves taste and material product/compatibility choices. | An LLM score cannot gate correctness. Repeated generic owner confirmations waste review time and conflict with D-52. |

These choices align with [Phoenix's component contracts](https://phoenix-live-view.hexdocs.pm/Phoenix.Component.html) and the [Storybook practice of composing real screens from smaller components](https://storybook.js.org/docs/9/writing-stories/build-pages-with-storybook). The implementation API is **PhoenixStorybook 1.2.0**, not JavaScript Storybook's APIs; the latter is architectural precedent only.

## 1. Establish that stories render the actual UI

Live browser inspection found real blockers to trustworthy review:

1. `/dev/storybook` redirects to `/storybook/foundations`, and sidebar links omit `/dev`. The pinned router explicitly warns against a non-root enclosing scope. Plan a full mount path inside a root browser scope, keeping routes dev-only.
2. Stat-card stories compute a serif font, while production uses Inter. The explorer sandbox sets its own font; the app's body font does not override it. Prove font roles, loaded font assets, CSS import/cascade and representative computed styles against the actual route. Keep explorer chrome isolated from the sandbox.
3. The current backend omits `js_path`; static modal markup does not run the production focus hook. Export/reuse the production hook implementation through the supported Storybook adapter. Do not copy hook logic or load a second LiveSocket bootstrap.
4. Native `themes_strategies: [data_attribute: "theme"]` exists in the **pinned source**. Use named Mailglass themes, then verify computed tokens before deleting hardcoded light/dark wrappers. Explorer color mode is a different concern. Test System preference resolution and persisted choice separately.

Keep the shipped admin asset bundle as the source. A missing link element is not enough to diagnose absent CSS: this version also imports app CSS inline, and its optional asset-hash warning is not proof that the import failed. Do not create a second Tailwind theme to make stories pass. `ARCHITECTURE.md` records exact source paths and live evidence.

## 2. Build the tree around real jobs

Use useful depth, not mandatory taxonomy at every node. Foundations are reference material; a primitive can be shared across jobs. Everything above that level follows the UI's nouns:

```text
Foundations
Shared components and patterns
Deliveries
  Email health
  Find a delivery
  Inspect a delivery: summary → evidence → whole detail
  Replay a webhook: action → review → result
Inbound
  Find a received message
  Inspect routing and history
  Review raw source / replay safely
Preview
  Choose a Mailable and scenario
  Edit inputs / inspect output
Recipient pages
  Unsubscribe: valid / invalid / expired
```

The review graph is primitive → pattern → area → section/page. Do not create copies of the same page under a second “screens” inventory. Cross-link a whole-job story from its areas. Use component stories for static screen states; a small example LiveView is appropriate for local interaction, but cannot prove full routing/authorization behavior.

Start with existing frequent operator jobs and owner feedback: find an exact Delivery, explain its evidence, discover a permitted replay, understand the review and its outcome. Then Inbound, Preview, and recipient GET states. Carry the live-filter and replay feedback into the owning slices; do not let it disappear behind cataloguing work. Recipient output uses the sender's identity, and preview snapshots never certify Gmail/Outlook/Apple Mail behavior.

## 3. Curate believable synthetic adopters

Keep approximately six profiles, each covering a distinct situation, not six skins for the same data. Preserve Northstar/Fjordline/Helios IDs and their current meaning. Distinguish **the adopting product**, **its customer Account**, and **the engineer/support operator using Mailglass**. A logistics customer of AtlasDesk is not itself proof that AtlasDesk is a logistics SaaS.

The proposed extensions are a self-hosted team chat, a global language-learning service and a personal-finance service. These are fictional product contexts for existing transactional email capabilities, not claims about actual customers, regulatory certification or new product support. `PERSONAS-DESIGN.md` defines roles, volume, locale, failures and jobs.

Each scenario declares a stable ID, product profile, role, job, expected view, source caller/read model, important invariants, fixed clock/IDs and why it exists. Synthetic addresses use reserved example domains. Never use real recipients, scraped messages, secrets or production database dumps. Freeze render inputs rather than masking meaningful timestamp/state differences in screenshots.

Validate enums, account/object linkage, valid calendar values and facts supported by the actual contracts. **Do not impose a universal queued → sent → delivered chain:** provider observations can be partial, delayed or out of order. A historical delivered event can coexist with current suppression. Model unknown/missing evidence truthfully. Use huge aggregate counts without constructing or rendering 10,000 rows when the real UI bounds history to 100.

Test representative pure scenarios against actual persisted read-model projections, separately from DB-free rendering. Scope, authorization and mutation semantics remain integration tests. The existing demo host still starts its Repo and needs Postgres: DB-free scenario construction does not yet mean DB-free server startup. Measure host setup in the pilot; don't introduce a second host merely to make an unmeasured speed claim. Do not encode new business rules merely to make fixtures look tidy.

## 4. Cover states and prune with evidence

For each real job identify happy, empty, one/many, filtered-empty, page boundary, unavailable evidence, permitted/denied action, expired/stale review, command failure and disconnected behavior **where the real caller can produce them**. Loading is included only where async/loading is real. Distinguish an empty account from a filter with no results.

Boundary content includes actual user-supplied names, subjects, addresses and IDs: realistic long values, Unicode/CJK/RTL/emoji, varying counts and dates. Mixed-direction text should remain readable without turning this into an unsupported full RTL-localization project. Fixed navigation labels should be improved when their wording is wrong; arbitrary identifiers must remain accessible. Do not prune a reachable defect simply because it looks awkward.

Every story has a situation description and a reason to survive. Prune when the state is contract-impossible, obsolete, genuinely redundant or a forbidden fixed-label pattern. Record `keep | merge | prune | defer`, destination ID and rationale for all 119 old Gallery specimens. Interaction-only checks such as hover/focus exercise real controls rather than duplicating a visually identical “hover-ready” state. Keep a regression test for a previously real defect even if its input cannot occur anymore; its boundary determines whether it belongs in a story or a lower-level test.

## 5. Automate in layers with honest cost and coverage

`AUTOMATION.md` is the detailed contract. Reuse before extending:

| Layer | Ownership and gate |
|---|---|
| L1: pure/static | Scenario invariants; compiled story/manifest agreement; reachable situation metadata; token and glossary rules with narrow exceptions. Blocking once implemented and wired to an existing required check. |
| L2: browser | Fail on missing/invalid/blank stories, unexpected page/console errors, page overflow, new axe violations, hidden essential content, broken interactions or focus. Compare **fresh** evidence to approved fingerprints. Coverage counts make a zero-run or omitted cell fail. |
| L3: selected screenshots | Representative key/worst-case states, stable fonts/browser/DPR/clock, animations settled. Review diffs deliberately; no auto-acceptance. Preserve existing semantic DOM/geometry checks. |
| L4: bounded critique | One evidence-based rubric pass and one contradiction/adversarial pass. Reuse Impeccable, archived reviews and owner examples. Advisory findings with stable fingerprints; model/prompt version recorded. No new API-key or paid-CI requirement. |
| L5: owner judgment | Present only unresolved design/product choices, representative comparisons and genuinely subjective findings. Record accept/reject reasons; repeated preferences become scoped rules where deterministic. |

Use 320/375/768/1280/1440 CSS px as the common starting matrix, retain existing 390 coverage until disposition, and add actual container/breakpoint ±1 checks where needed. All retained states get core layout checks in both themes; expensive axe/focus/zoom/screenshot work uses explicit semantic/risk coverage groups. System and reduced motion get focused independent checks. Preserve deep-link mount and connected-route parity, including page/quick-view container widths. Do not silently drop cells to meet a timing target.

Set **provisional targets of ≤5 minutes added PR wall time and ≤10 added runner-minutes**, including host setup, for the pilot; measure cold/warm runtime and story counts on the actual CI runner before making commitments. These are budget targets, not measured claims. If over budget, shard appropriately or split full vs change-affected checks with a declared dependency map, scheduled/manual full coverage and invalidation for global token/fixture changes. Reuse the existing lane first; promote only justified deterministic coverage. Repo CI currently places relevant browser jobs outside `CI Green` dependencies; that is not evidence of remote branch-protection settings.

Important adaptations to the generic prompt:

- Root font scaling is useful stress, **not real browser zoom**. Retain the existing actual-zoom helper and distinguish 200% resize from 320px reflow.
- Axe `incomplete` is a review-required finding, not automatically a WCAG failure or an invisible pass. Every item needs a disposition, owner and evidence. A test cannot claim full accessibility certification.
- WCAG 2.2 target minimum is 24px **with defined exceptions**; retain the project's stricter 44px primary controls. Do not assert that every inline link must be a 44px button.
- Permit deliberate accessible overflow for genuinely two-dimensional content; prevent page-level overflow and loss of essential information. Never fix overflow with blanket clipping.
- Compare navigation semantics and account/job context; do not demand identical entire ARIA trees when selection, permissions or optional inbound availability legitimately differ.
- Check meaningful foreground/background combinations, not every mathematical token pairing. Scope runtime token checks to authored roles; browser rounding, inherited styles and content dimensions are not off-token defects.
- No blanket ban on all inline styles/arbitrary values across emails and admin. Email rendering needs inline styles and frames need dynamic dimensions. Extend existing narrowly scoped gates and justified exceptions.
- The current axe flow's fresh-vs-baseline gap must be fixed before treating it as a ratchet. Old JSON and old visual scores are history, not a fresh green.

Primary standards: [WCAG reflow](https://www.w3.org/WAI/WCAG22/Understanding/reflow.html), [resize text](https://www.w3.org/WAI/WCAG22/Understanding/resize-text.html), [target size](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html), and [Playwright accessibility testing limits](https://playwright.dev/docs/accessibility-testing). Interpret them with the actual UI and declared project floors.

## 6. Review rubric and accountability

| Criterion | Machine evidence | Advisory / owner judgment |
|---|---|---|
| Light/dark/System | Actual applied theme, contrast pairs, persisted selection, stable assets | Restrained, intentional palette; no muddy dark hierarchy |
| Typography | Correct loaded font/role/scale, wrapping, resize | Professional rhythm, appropriate density and emphasis |
| Hierarchy | Landmarks/headings, order and visibility, readable exact values | Clear dominant task and progressive detail |
| No redundancy | Flag repeated known labels/copy patterns narrowly | Remove content that contributes no decision value |
| Routine and power jobs | Critical routed flow, context retention, keyboard actions | Efficient common path without hiding diagnostic depth |
| User-facing copy | Approved term/pattern lint over visible and accessible names | Clear consequence and recovery; engineering details only where useful |
| Realistic scenarios | Domain/read-model invariants and reachability mapping | Believable user/product situation, not invented support |
| Coherent journey | Navigation/account/selection continuity tests | Natural entry, orientation, next action and return path |
| Mobile and accessibility | Reflow, target rules, focus, zoom, axe, reduced motion | Comfortable density and touch/keyboard use |
| Least surprise | Shared component contracts and parity tests | Familiar affordances, consistent patterns, purposeful motion |

Binary `pass | finding | not-applicable` per item with evidence; don't replace the old historical score ledger with another universal aesthetic number. A rejected critique suppresses the same finding in the same context, not an unrelated regression or changed implementation. Calibration starts with owner-labelled examples; precision is measurable only once labels and sufficient examples exist. Do not invent a false-positive rate.

## Recorded constraints and conflicts

| Quoted authority | Tension | Resolution |
|---|---|---|
| Phase 173 D-02: “Keep … GalleryLive as the comprehensive … inventory”; Storybook a “curated primitive/story explorer” | Current owner asks for complete fractal Storybook and pruning duplicate catalogues. | Current direction changes future inventory policy. Preserve archived decisions as history; migrate coverage explicitly. |
| Phase 173 D-03: “Do not add a shared specimen framework … move Gallery coverage into the demo package” | Shared pure scenario data and migration need a common source. | Narrowly supersede inventory allocation for the proposed work; retain no duplicate CSS/no gratuitous dependency/no generic framework rules. |
| `.planning/METHODOLOGY.md` D-52: “A testable criterion must not be handed back to the owner for confirmation.” | Generic method describes multiple review tiers. | Machines close observable rows; only taste/material compatibility decisions reach the owner. |
| `CLAUDE.md`: “no Node toolchain anywhere”; PROJECT clarification: “Zero-Node stays adopter-facing” | Existing browser tooling uses Node. | Later scoped clarification governs: current dev-only Node is fine, no adopter build requirement. |
| Current feedback: “Unmask addresses in inbound”; Phase 170 evidence rules mask raw routing/header material | A visual refactor could accidentally broaden sensitive disclosure. | Top-level contact presentation and sensitive raw diagnostic evidence are distinct. Preserve reveal/auth boundaries; adjudicate exact fields before implementation, never blanket-unmask trace data. |
| Generic method: “any second inventory … ported, then retired”; it also reserves removal of an “adopter-visible surface” | Gallery is documented and shipped. | Make Storybook canonical; keep the route through migration. Final route removal/deprecation policy is a separate owner decision, not a prerequisite for useful stories. |
| Existing convergence posture defaults to quiet maintenance | This is another UI investment. | Current owner explicitly selects it. Bound milestones by useful jobs and stopping criteria, not infinite aesthetic perfection. |

No strategic question blocks this proposal. Eventual Gallery route removal needs a concrete compatibility disposition when that step is reached; choose coexistence during migration now.

## Adversarial synthesis and stopping rule

The strongest objection is that another UI pass could become an expensive catalogue with little adopter benefit. Counter it with a complete job in the first milestone, shared production rendering, fixtures that expose current defects, measured execution costs and a finite coverage map. A beautiful isolated dialog that fails on a real replay is not acceptance. A broad green screenshot matrix over wrong typography is not acceptance either.

At each milestone: deliver the chosen real jobs; reconcile all reached state classes and known findings; run required machine checks; review representative narrow/wide light/dark results; update the next recommendation from evidence. Advance only if the next uncovered job or recurring defect justifies maintenance. Stop adding layers/profiles when they add no distinct reachable state, interaction, layout boundary or adopter job. No open-ended critic loop, generic component framework, new product capability, provider expansion or automatic release is implied.
