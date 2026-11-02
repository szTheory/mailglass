# Upstream scope: useful UI repairs and a trustworthy fractal Storybook

2026-10-26. **Discovery and scope recommendations for OpenGSD, not an activated milestone, formal requirements, phase plan or implementation.** Reader: the maintainer and the next OpenGSD discovery/planning session. Post-read action: choose a bounded milestone from current evidence, then let OpenGSD reconcile and formalize it without reconstructing this conversation.

This is the current scope authority. [Rolling proposal](MILESTONE-PROPOSAL.md) is its short projection; earlier research supplies rationale, not competing schedules. Inputs: [inventory](INVENTORY.md), [current owner review](../../todos/2026-10-26-owner-review-health-preview-controls.md), [original feedback](../../todos/2026-10-25-owner-review-pr302-ui-feedback.md), and the [product](SCOPING-PRODUCT.md), [engineering](SCOPING-ENGINEERING.md) and [evidence](SCOPING-EVIDENCE.md) scoping reviews.

## Recommendation and what changed

**Deliver the known UI repairs through small integrated slices; retain realistic stories and real-route proof alongside each repair.** Make Storybook trustworthy early, then expand coverage around useful jobs. Do not delay already-reported Inbound/Preview problems behind two more cataloguing milestones.

The useful delivery unit is **a repaired real situation + shared production presentation + a retained scenario + the cheapest proof of actual behavior**. A static story proves rendering; URL, authorization, replay and persistence need the connected boundary. This follows D-52 and the one-person-maintainer budget.

| Approach | Benefit | Main cost / decision |
|---|---|---|
| Repair pages, add stories later | Visible progress quickly | Another UI pass without retained scenario coverage; reject as the overall strategy |
| Build the complete quality engine first | Uniform infrastructure | Known problems wait behind catalogues, extraction and CI machinery; reject |
| **Integrated repairs with retained scenarios** | Immediate value plus reusable feedback | Requires discipline against broad extraction; recommend, bounded by named feedback and real jobs |

Preserve the current brand, useful diagnostic depth and the owner's high craft bar. Elegance does not imply an iOS imitation, a new design system or infinite critic passes.

## Rolling milestone envelopes

These are candidate outcomes, not assigned versions or phase counts. Only the next envelope should be formalized; reassess the rest from what actually ships.

### Next: recorded friction resolved, faithful review established

**Outcome:** operators can understand Health, filter both collections, read useful ordinary evidence and perform permitted recovery with clear outcomes. Authors can choose/edit a preview coherently. Repaired areas are inspectable in a Storybook matching production rendering.

**Scope:** all unresolved feedback in the table below; mount/font/theme/hook fidelity; only the pure scenarios, metadata/manifest and checks needed to retain these repairs. Start with existing normal, empty and long/Unicode cohorts. Complete one Delivery investigation path as an early integration proof while addressing shared controls across both operator surfaces.

**Acceptance direction:** every feedback item has a current-source disposition and evidence. Repaired areas share production rendering; key interactions work on real routes; ordinary addresses are useful; auth and exact evidence remain truthful. Check representative light/dark, narrow/wide/container layouts, keyboard/focus and meaningful failure/boundary states. Correct fresh axe comparison before calling the new sweep a ratchet. Advisory evidence stays labelled advisory.

**Exclude:** exhaustive Gallery migration, fully storied app, six materialized adopter products, capability/provider growth, custom date ranges, account-aware Preview, public Gallery removal, rebrand, generic view/fixture framework, CI-wide redesign and judge service.

**If oversized:** OpenGSD may split by real job/dependency after sizing. Keep every feedback row visible with an explicit destination and rationale. Trim speculative breadth before deferring known repairs. Formal scope admission/exclusion remains normal owner/OpenGSD work; this research does not preapprove requirements.

### Following: deeper whole-job scenario coverage

**Outcome:** maintainers can move from complete supported jobs into areas, patterns and components, reproducing distinct real states without reconstructing a database incident.

Expand high-value Delivery/Inbound/Preview cases using proven seams. Treat author/recipient output and unsubscribe GET states as distinct contexts. Add self-hosted/global/B2C profiles only for a unique supported risk; six is a candidate ceiling, not a quota. F7 demo token-route mounting is an explicit integration candidate, not an inferred interactive unsubscribe feature.

**Acceptance direction:** current job/state map; representative pure-to-persisted projection agreement; connected critical transitions; useful review hierarchy; measured runtime and review cost. Stop when another persona, component split or state adds no distinct supported job/interaction/content/layout risk.

### Conditional later: consolidate and maintain

**Outcome:** one canonical maintainer inventory, little duplicate upkeep and reproducible, triaged findings.

Account for Gallery cases/assertions with keep/merge/prune/defer decisions as migration occurs. Finish remaining consolidation only if its payoff justifies it. Reuse scenario metadata and normal findings notes; no database/calibration platform. Keep the published Gallery route pending an explicit compatibility disposition. Bounded advisory critique can reuse owner examples without becoming a mandatory service.

This may be ordinary closeout/maintenance instead of another milestone. Quiet maintenance is a valid final state.

## Feedback disposition: firm direction vs design hypotheses

All unresolved rows feed the next envelope. Completed demo-auth/browser fixes stay completed. Current screenshots/source are indexed in the [owner review register](../../todos/2026-10-26-owner-review-health-preview-controls.md).

| Area | Established direction | Treatment / downstream validation |
|---|---|---|
| Health | Improve crowding; preserve specific issues/deep links | Group period/freshness/Refresh, subordinate activity, constrain reading width. Compare one-column and deliberately grouped alternatives at real widths. Count alone is not severity. |
| Preview sample form | Fix reset alignment/weight and repetitive helpers | Shared secondary-action treatment; recommend “Restore defaults.” Keep meaningful parsing, validation and read-only guidance. |
| Preview selector | Intentional, readable selected identity | Scenario primary, module secondary; retain exact identity and disambiguate duplicate humanized names. Dot removal follows owner preference, not a universal law. |
| Account context | Compact control, coherent navigation | Account scopes Health/Deliveries/Inbound; Preview renders defaults. No fake picker. Dynamic same-account return is a distinct navigation question; current static host links do not provide it. |
| Both collection filters | Auto-apply selects, debounce text, remove Apply | Existing form → canonical URL → handle_params flow, preserving focus, meaningful Back, pagination reset, errors and scope. Custom dates separate. |
| Quick view | Quieter previous/next arrows on both surfaces | Retain 44px hit areas, names, focus/hover, disabled boundaries, position and coherent Close. |
| Raw provider source | Group title/action/privacy and compact facts | Consistent hierarchy, less redundant explanation; preserve reveal auth and safe projections. |
| Suppression | Consistent Refresh/Retry, clearer language | Retain real scoped reads while complete invalidation is unproved. Explain removal support without inventing a UI action. Unknown expiry is not “never.” |
| Ordinary Inbound From/To | Complete addresses in authorized evidence | Concrete masked defect is From in detail header; inspected ordinary To displays are already full. Audit contact displays; raw/diagnostic/telemetry policies remain separate. |
| Replay | Quick-view entry, truthful availability, concise review, X-close and requested success toast | Share dialog structure, preserve distinct commands/exact revalidation. Keep errors visible inside an open dialog and explain retry; no hidden error or unexplained consumed-review dead end. Preserve the owner's toast request in formal scope rather than silently substituting existing inline feedback. |
| Full detail | Useful technical evidence visible by default | Group below primary facts; ordinary technical disclosure is distinct from raw-source access. |
| Storybook | Correct navigation/serif mismatch, grow beyond primitives | Fidelity first; retained pattern/area/job stories invoke production components. |

## Consequential scope guardrails

**Auto-apply is agreed behavior.** Current validate_filters updates draft validation only; deleting Apply alone breaks filtering. Reuse normalization and URL-backed reads; don't invent cancellation machinery unless async work is actually introduced. Avoid per-keystroke history while retaining useful Back. A 300ms debounce is an engineering starting point, not a locked requirement. Announce settled results without moving focus or flooding messages. W3C distinguishes in-place content updates from disruptive context changes. [W3C On Input](https://www.w3.org/WAI/WCAG22/Understanding/on-input).

**Useful addresses and private evidence are separate contracts.** Fulfil ordinary From/To display without rewriting raw-source/trace policy. Preserve missing-value truth and account authorization. Privacy-safe retained captures come from synthetic data, not a deliberately unhelpful production UI.

**Controls share visual rules, not semantics.** Reset changes sample inputs; Refresh rereads evidence; Retry repeats a failed read. Place each in the scope it affects and distinguish outcomes. Restrained controls still need alignment, wording and interactive states. [Primer Button](https://primer.style/product/components/button/) and [GOV.UK Button](https://design-system.service.gov.uk/components/button/) support differentiated action emphasis; their styling is not a rebrand brief.

**Preview stays account-independent.** The current host navigation is static; demo destinations hardcode Northstar. Shared styling does not establish dynamic return context. Browser Back remains available; if same-account cross-navigation is accepted downstream, design a narrow validated navigation-only seam. Don't widen auth/session whitelists or imply Account changes sample data.

**Composition earns boundaries.** LiveViews keep loading/params/commands/auth; meaningful presentation components accept plain data. Extract incrementally for actual repaired areas. Share hook implementation while Storybook owns its socket. Admin/demo currently lock different LiveView versions (1.2.13/1.1.33); verify adapters against both without requiring an upgrade. Pinned Storybook 1.2.0 governs its APIs.

**Small dependencies, no duplicate engines.** Hand-write small repository glue; reuse axe, production components and focus hooks. Discovery establishes no need for a new dependency.

## Scenarios and trustworthy evidence

Start with Northstar/Fjordline/Helios facts; distinguish product profile, customer Account, UI actor and scenario. Helios is empty by absence, not automatically selectable. Separate pure declarations/builders from persistence materializers and check representative projections. Accept legitimate partial/late/out-of-order provider facts. Large aggregate counts don't justify rendering unbounded history.

Retained cases need a real state producer, role/job and reason to survive. Cover normal, empty/filtered-empty, one/many/boundary, unknown/read-failure, permitted/denied, stale and extreme content only where reachable. State equivalence classes avoid Cartesian explosion. Grouping variants supports comparison but does not replace an actual composed area/page. [Lookbook guidance](https://lookbook.build/guide/previews/groups) is precedent, not a dependency proposal.

A fidelity receipt identifies source revision, actual URLs, CSS bytes, loaded font faces/weights, computed roles, theme and relevant hook behavior. Fonts-ready or document.fonts.check alone is insufficient; check can report true even for an absent face. Combine matching loaded faces, successful assets and rendered style evidence. [CSS Font Loading](https://drafts.csswg.org/css-font-loading/), [FontFaceSet.check caveat](https://developer.mozilla.org/en-US/docs/Web/API/FontFaceSet/check).

Reuse ExUnit/Playwright/axe at the cheapest proving boundary. Keep 320/375/768/1280/1440 landmarks, defect widths and actual pane/content boundaries. Light/dark cover repaired states; System, reduced motion and real zoom have explicit owners. Avoid screenshots of every equivalent combination. Fresh comparisons and expected/executed counts underpin any ratchet claim; old JSON/score totals cannot close current acceptance.

**Cost is unmeasured.** Pilot provisional ≤5 extra PR wall minutes / ≤10 extra runner-minutes including cold/warm setup. DB-free fixtures don't mean the current Ecto demo starts without Postgres. Gate placement and full/change-affected profiles follow measurement; no silent coverage omissions or weakened gates. No aesthetic judge precision claim is justified here.

## OpenGSD handoff and research stopping rule

| Supplied upstream | OpenGSD/downstream owns |
|---|---|
| Intent, unresolved feedback, current facts, outcome envelopes | Checkout reconciliation, milestone choice/admission and formal requirements |
| Product/privacy/compatibility guardrails and tradeoffs | Design validation, phase/plan decomposition, estimates and tests |
| Acceptance direction and evidence limits | Required/advisory placement, actual cost measurement, execution and verification |
| Finite hypotheses: Health grouping, selector/action hierarchy, minimum seams and return context | Bounded comparisons and connected evidence; no interview to reconfirm settled directions |

No strategic owner question blocks repair scoping. Rebrand, account-aware Preview, broader sensitive disclosure, documented Gallery-route removal or a weakened gate require separate concrete decisions; none follows routinely from UI polish.

Stop upstream research when no unresolved issue changes the next envelope, trust boundary, evidence feasibility or meaningful cost. Three focused reviews plus one bounded adversarial/cold-reader pass are enough. Implementation research belongs in OpenGSD when an actual design uncertainty is reached. No milestone, official ROADMAP/REQUIREMENTS, product/dependency files, release or deployment changed by this packet.
