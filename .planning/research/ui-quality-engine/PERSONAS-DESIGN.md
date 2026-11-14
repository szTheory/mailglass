# UI quality engine: personas, scenarios, and design judgment

**Status:** researched proposal; no product implementation or milestone activation.

**Date:** 2026-10-26.

**Owner intent:** stories should be a fast, realistic way to inspect the actual interface from component through whole job, with deliberate typography, coherent navigation, clear copy, both themes, and mobile-first behavior.
**Evidence limits:** code and documentation inspected; this note does not claim a new rendered UI review, accessibility certification, customer research, or email-client compatibility test.

## Recommendation

Use one curated scenario catalogue rooted in the existing persona spec, with a story tree organized around Mailglass's user jobs. Reuse the production components at every level. Give each retained scenario a concrete user, trigger, observable evidence, next action, and outcome. A larger catalogue is useful only when it reveals a different reachable state, interaction, content risk, or composition problem.

The quality target is precision and restraint in an operator tool: clear hierarchy, readable exact evidence, familiar affordances, professional typography, a quiet semantic palette, and a natural next action. The current brand remains canonical. This is an extension of the existing UI work, not permission to invent a new identity or import a native Apple visual style.

This recommendation follows the current product's equal priority for engineers and support/on-call operators, the host application's ownership of authorization and sender identity, and the distinction between observed evidence and hoped-for outcomes. See [PRODUCT.md](../../../PRODUCT.md), [the current brand book](../../../brandbook/brand-book.md), and [D-52 methodology](../../METHODOLOGY.md).

## Local evidence and what to reuse

| Evidence | What it establishes | Consequence |
|---|---|---|
| [PRODUCT.md](../../../PRODUCT.md), Users / Operating Context / Product Principles | Three audiences: operators and engineers; developers/authors; recipients. Account/filter/object context and truthful results matter. | Build around jobs and role needs, not a directory of modules. |
| [Existing persona spec](../../../reference/persona_spec/personas.ex), `spec/0`, `account_labels/0`, `specimen_literals/0` | Three existing synthetic account fixtures: Northstar, Fjordline, Helios. The spec is declarative; the same module also contains database materializers. | Extend one catalogue and establish a pure fixture-data boundary. Do not add another unrelated persona factory. |
| Same spec, module documentation | Northstar covers many/high-count/error; Fjordline covers one/long provider identifier/non-ASCII/null; Helios has no deliveries and is deliberately absent from the derived switcher. | Retain these regression situations. Do not fabricate a selectable empty account to make a story look convenient. |
| [Persona cohort tests](../../../mailglass_admin/test/mailglass_admin/persona_cohort_test.exs) and [drift guard](../../../mailglass_admin/test/mailglass_admin/persona_drift_guard_test.exs) | Existing materialization and literal consistency checks already constrain seeds, test data and gallery specimens. | Extend these invariants; migrate their coverage when replacing gallery specimens. |
| [Persona screenshot suite](../../../reference/demo_app/assets/e2e/persona-screenshots.spec.js), anchor/spot-check declarations | Existing captures use 375/1440 in light/dark, with selected 320/768/system cells. Development preview surfaces are already deduplicated across persona-independent cases. | Adopt that equivalence-class discipline. A persona-independent primitive does not need six duplicate screenshots. |
| [Internal JTBD map](../JTBD-COVERAGE.md), staleness banner | The status/gap tables explicitly describe a historical product. | Refresh from current product and source. Do not reopen old provider or capability gaps by copying the stale tables. |
| [Public jobs guide](../../../guides/jobs.md) | Stable author/send/observe/operate/receive jobs and the dispatch-versus-delivered distinction. | Preserve the useful vocabulary; verify current claims before projecting a refreshed map. |
| [Owner feedback](../../todos/2026-10-25-owner-review-pr302-ui-feedback.md) | Preview and actionable Health links are praised; live filters, replay entry/error behavior, evidence hierarchy and masking have specific follow-ups. | Convert feedback into named scenarios and calibration examples; preserve what the owner already likes. |

## Separate adopter products, users, and scenarios

An adopter product is the application that embeds Mailglass. A role is the person using a Mailglass surface. A scenario is the situation in which that person has a job to complete. These axes must remain explicit:

`adopter profile → actor and authorization → job and trigger → scoped records → view state → expected next action and outcome`.

For example, "a support operator in a logistics account explains why an invoice did not arrive" is useful. "Northstar persona, 12 props" loses the user and the job. A site reliability engineer and a support operator may inspect the same Delivery but need different depths of evidence; both must use the same truthful data and authorization rules.

The following six profiles are **proposed synthetic evaluation hypotheses**, not descriptions of actual customers. Their volume bands are fixture-design inputs to validate, not measured adoption claims. The existing account names and IDs remain stable; the larger product context can be added as metadata without renaming fixtures or breaking deep links.

| Synthetic adopter profile | Actor, job, and why it uses Mailglass | Volume / deployment / content | Distinct failure and boundary situations |
|---|---|---|---|
| **AtlasDesk / Northstar Logistics** — existing B2B multi-tenant support/workflow example | Support explains a failed operational message; on-call engineer checks exact webhook evidence and permitted replay; author previews a receipt. | Established hosted SaaS; many deliveries and multiple accounts; English plus international contact names. | High-count lists and page boundaries, bounced/suppressed versus dispatched, exact selected Delivery outside current filters, missing exact webhook linkage, authorized replay and later history. Keep the existing full-lifecycle scenario. |
| **Fjordline A/S** — existing small B2B account | A small-team engineer finds the only message and reads exact identifiers without losing context. | Low-volume account with one Delivery; Latin-extended/CJK names; long provider identifier and Mailable name. | One-row navigation boundaries, long unbreakable values, legitimate missing reject reason, readable full values at narrow widths. Retain the existing contract literals rather than manufacturing impossible IDs. |
| **Helios Trial** — existing brand-new evaluation account | A new integrator understands what appears after the first send and how to take that first step. | No deliveries; empty evidence and no fabricated activity. | First use versus a filter producing no matches are distinct states. Helios remains absent from a switcher derived only from stored deliveries; use an actually supported direct scope or a data-only component story. |
| **LingoHarbor** — proposed B2C language-learning app | Support locates an account verification message; author checks localized transactional content and correct action links. | Hosted consumer product; burst of onboarding/auth messages; CJK, accented and mixed-direction contact content. | Long translated content where localization exists, mixed-script names, missing subject versus legitimate empty body section, renderer validation/error. Do not invent marketing campaigns or a complete RTL interface if the product does not support one. |
| **Cedar Rooms** — proposed self-hosted collaboration app | A maintainer who is also the operator investigates invite/reset mail and inbound replies from a phone. | Single-tenant self-hosted Phoenix app; small steady volume with occasional invite bursts; English plus Unicode user names. | No account picker when there is only one selectable account; restricted sensitive action, disconnected/reconnected shell, unknown historical evidence, current routing simulation versus recorded Mailbox execution. This is an email scenario, not a new chat integration. |
| **PocketLedger** — proposed B2C personal-finance tool | Support explains a receipt or security message without exposing more customer data than the surface permits; developer checks sender-branded output. | Consumer account alerts and receipts; long references, international names and currencies only where supported; wholly synthetic content. | Auth email tracking remains off, raw source locked versus authorized reveal versus denial, current suppression separate from historical events, exact time and record identity preserved. No bank integration, preference center or new finance-specific capability is implied. |

Role overlays are small and explicit: support reader, support/on-call with the existing recovery grant, engineer needing precise diagnostics, author/integrator, recipient. Do not create six copies of each role. Add a new profile only if it contributes a distinct supported deployment, job, data shape, content behavior or failure class; otherwise attach the needed scenario to an existing profile.

GOV.UK recommends understanding the whole user context, grounding needs in evidence, and keeping them connected to stories. Our synthetic profiles help test assumptions; they do not replace observation of real adopters. [Understand users and their needs](https://www.gov.uk/service-manual/service-standard/point-1-understand-user-needs), [Learning about users and their needs](https://www.gov.uk/service-manual/user-research/start-by-learning-user-needs).

## Fixture realism contract

The future fixture source should be plain data available only in development/test, with thin seed/test/story adapters. A story must not need a database, a mocked Repo, or another implementation of the business logic to obtain its presentational state. Tests that need persisted behavior can materialize the same data using existing supported paths. Validate the catalogue as a graph, not merely as a bag of maps.

1. **Scope and identity:** Account IDs and object IDs agree through Delivery, Event, webhook, inbound record, route binding and selected history. A provider's long external identifier is not substituted for a core UUID. Cross-account denial fixtures must deliberately express denial, never render another account's ordinary evidence.
2. **Closed vocabularies:** Event types, reject reasons, execution outcomes and eligibility reasons come from the actual domain contract. Do not invent `pending`, `failed-but-successful` or backend strings just because they make an attractive badge.
3. **Temporal truth:** Use a fixed anchor with explicit offsets and timezone. Check domain-specific time relationships. Provider events may arrive late or out of order; do not impose a simplistic universal monotonic order that excludes real supported evidence. Never fabricate a last-observed timestamp for unavailable data.
4. **Outcome provenance:** Dispatched is not delivered; replay accepted is not replay completed; current router simulation is not arrival-time routing; a past failure is not erased by a later success. Current suppression matches and historical event counts are different populations.
5. **Eligibility:** A replayable fixture has the exact stored linkage/binding and applicable grant. No-match, missing linkage, stale review and authorization denial are their own states. Presentational readiness does not prove the server will authorize or execute the operation; retain integration tests at that seam.
6. **Numbers and missingness:** Counts, selected page, page length and bounded history agree. Zero, unavailable, one and many are distinct. A valid nil reject reason remains nil. Do not add counts from independently defined Health populations and call the sum a total.
7. **Content realism:** No lorem ipsum, copied production payloads, real PII or secrets. Use reserved example domains and deterministic non-secret tokens; disable real external send/fetch side effects. Include normal sentences as well as long values, non-ASCII and multiline content. Fixture invariants should reject contradictions, not impose arbitrary UX limits the product has never promised.
8. **Minimal examples:** Each scenario explains its legitimate caller/state producer. Use normal content plus one targeted stressor where possible. A giant string in every field simultaneously is a diagnostic fuzz probe, not automatically a retained persona story.
9. **Packaging:** Prove fixture modules, Storybook routes and private scenario assets stay outside the shipped package/runtime surface. Do not let DB-free code become a hidden dependency from the public library back into the demo app.

## The fractal story tree and pruning rule

Use familiar product nouns in navigation and retain source ownership metadata separately. Recommended logical tree:

- **Foundations / shared patterns:** type, semantic colors, spacing, focus, feedback, account context, navigation, collection rows/cards, disclosure and dialog shell.
- **Email health:** population summary → actionable concern → overview area → complete investigate-from-health screen.
- **Deliveries:** filter controls → collection → quick view → timeline and suppression/webhook evidence → replay review → full investigation screen.
- **Inbound:** filters and collection → quick view → received-message facts and safe evidence → routing/history → replay review → full investigation screen.
- **Preview:** picker → editable inputs → render state/output tabs → complete authoring screen.
- **Recipient output:** real public email components and supported built-in page states, kept distinct from operator theme and browser-only evidence.

These are levels of composition, not a demand to split each existing component into five smaller ones. A meaningful area earns a story if context changes its hierarchy, width, keyboard behavior or user action. Whole-screen stories compose the same production pieces and exercise several areas together; a small set of real connected-route tests still proves params, events, focus restoration and authorization.

Each scenario records stable ID, product/role/job, trigger, domain state producer, essential input, expected evidence/action, real container context, and reason for retention. A story is retained when it witnesses a distinct reachable class: initial empty, filtered empty, one, many/page boundary, supported pending work, error/recovery, permission denial, stale/disconnected, or meaningful content boundary.

Prune when no current caller can produce it, the domain rejects it, a claimed async state does not exist, it duplicates the same rendered/interactive behavior, or it has no user job. Require a reason and replacement coverage when deleting a regression scenario. Prune obsolete product scenarios, not uncomfortable failures. Do not add an extra story for every combination of persona, count, color, nullability and flag; the combinations must follow the domain state graph.

## Visual and verbal direction

### Preserve the current brand; review actual compositions

The source of truth for identity is `brandbook/`, not the older `prompts/mailglass-brand-book.md`; current Admin source determines what actually ships. Keep the sealed-flap identity, semantic light/dark roles, Inter/system UI stack, Inter Tight/system display stack, and IBM Plex Mono/system monospace stack. **Admin ships six WOFF2 files** under `mailglass_admin/priv/static/fonts/` (400/700 weights for those three families), served through the exact allowlist in `controllers/assets.ex`; `assets/css/app.css` declares the faces and production font roles. The brand book's font-distribution wording must not be generalized into a claim that Admin ships no fonts. First prove those intended fonts load and the sandbox uses the production roles; inspect fallback typography separately as a degraded-state stress case. An accidental Storybook serif override is a fidelity defect, not the everyday production baseline.

Typography should communicate hierarchy through a small set of consistent size/weight/line-height roles and grouping. Use restrained headings, align labels and values intentionally, avoid all-bold metadata or using accent color for every important item, and keep long exact values readable. Heading semantics follow document structure rather than selecting an `h2` for its appearance. Primer's official guidance emphasizes reusable type tokens, accessible relative sizing and a clean hierarchy with color used cautiously. [Primer typography](https://primer.style/product/getting-started/foundations/typography/).

Light and dark are two designed expressions of the same semantic system, not literal inversions. Check foreground/background roles, muted metadata, borders, focus rings, disabled controls and layered dialogs in both. Retain the existing System/Light/Dark selector and persistence contract. Apple's native preference to avoid app-specific mode settings does not override this recorded web-product behavior. The transferable lesson is to respect appearance changes and evaluate assets and legibility in each expression. [Apple Dark Mode](https://developer.apple.com/design/human-interface-guidelines/dark-mode).

### Design for the available space and the actual job

Use 320/375/768/1280/1440 CSS-pixel sweep anchors, then inspect actual layout transition boundaries and narrow components inside a wide shell. The viewport is not the same as a quick-view panel's available content width. Keep key actions reachable without hover and make the mobile hierarchy explicit rather than shrinking the desktop layout. Cover keyboard, reduced motion and text enlargement; a new width token is not itself proof of responsiveness.

WCAG reflow addresses no-loss access at an equivalent 320 CSS pixels, with specific exceptions for genuinely two-dimensional content. It does not mean each data table should simply be squeezed into tiny cells. Preserve exact evidence through wrapping, useful cards or intentionally bounded inner scrolling where the content genuinely needs it. [W3C Reflow](https://www.w3.org/WAI/WCAG22/Understanding/reflow.html).

The existing source uses `min-h-11`/`min-w-11` for important controls. Preserve the project's 44px comfort target. WCAG's 24px minimum has spacing, inline and other exceptions; it is a floor with a precise definition, not a reason to reduce primary controls. [W3C Target Size Minimum](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html). Primer also treats responsiveness as adaptation to device affordances and user preferences, rather than viewport resizing alone. [Primer responsive guidance](https://primer.style/product/getting-started/foundations/responsive/).

### Copy and evidence should fit the reader

Keep Mailglass's seven domain nouns where they help orientation, but use ordinary phrases in visible copy: Account, received message, delivery, recorded Mailbox, provider and webhook. Do not turn a glossary linter into a blanket ban on technical terms; an engineer needs an exact Mailable name, provider message ID or raw header name in the appropriate diagnostic context. Routine tasks should not explain internal structs, projections, callbacks or audit implementation.

Make verbs describe actual actions. Replay is not resend. A concise replay sentence and an explicit statement that the email will not be resent are more useful than a paragraph of internal effects. Show the actual target and consequence before committing. Keep useful precision behind a deliberate hierarchy rather than stripping it out.

An empty state says what is missing and the supported next step. A failed action names a safe cause and usable recovery, inside the dialog if the dialog remains open. Never send the only error to a flash obscured by its overlay. Differentiate stale review (refresh and review again), denied action (permission issue), missing exact linkage (not replayable) and transient failure. Reuse [current voice guidance](../../../brandbook/copy/microcopy.md) as reference, validating every existing statement against current source before making it a hard copy rule.

Progressive disclosure must preserve context and serve a real need. The owner wants technical details visible on the full detail page; that is compatible with a quieter quick view and separate sensitive raw-source reveal. Primer recommends restrained disclosure that does not disorient the reader. [Primer progressive disclosure](https://primer.style/product/ui-patterns/progressive-disclosure/).

## Review ownership and rubric

**Machine** means repeatable deterministic assertions at the cheapest proving boundary. **Advisory** means one bounded evidence-backed design/copy review with pass/fail/not-applicable findings. **Owner** means irreducible preference or product judgment after routine checks are complete. The same finding should not be reported by all three layers.

| Rubric item | Machine owns | Advisory review owns | Owner owns |
|---|---|---|---|
| Light/dark/system | Correct theme/root/persistence, token pairing contrast, focus/status non-color cues | Balanced surfaces, restrained saturation, equal emphasis and hierarchy in both expressions | Exceptional subjective palette preference; identity changes |
| Typography | Token use where meaningful, semantic headings, no clipped essential text, zoom/fallback behavior | Intentional hierarchy, rhythm, readable labels/values, useful line length | Last-mile taste where compliant alternatives remain |
| Information structure | Presence of essential facts/actions and expected grouping contracts | Scan path, proximity, one primary task per area, sensible density | Product-level priority change |
| Redundancy | Exact repeated labels or controlled banned copy when a real rule exists | Repeated explanations, duplicate status blocks, needless cards | Decision to remove a meaningful visible fact |
| Happy path and power user | Existing URL/filter/back/selection contracts, keyboard behavior, copy values, exact IDs | Action discoverability and efficient progression without overwhelming routine support | Changes to familiar workflow defaults |
| Microcopy | Known approved terms/patterns, accessible names, safe error states | Plain domain language, tone, concise accurate consequence/recovery | Ambiguous business policy or new user promise |
| Persona coherence | Fixture invariants and scenario metadata completeness | Plausibility of workload, user goal and data relationships | Real-world insight validating/refuting synthetic hypotheses |
| Journey/navigation | Route/selection preservation, focus return, no keyboard traps, contextual active navigation | Coherent handoff among health/list/detail/replay/preview | Information architecture changes with adopter impact |
| Mobile/responsive | Overflow, control geometry, breakpoint boundary probes, resize/zoom/focus behaviors | Natural stacking and priority, comfortable interaction density | Device-specific preference after objective evidence |
| Least surprise | Native semantics, supported disabled/available states, truthful outcome assertions | Familiar motifs, consistent one-pattern-per-job interactions | A deliberately unconventional interaction |

A clean automated sweep cannot establish that the interface feels professionally designed. Conversely, a reviewer must not demand owner UAT for a measurable clipping bug. D-52 says: "A testable criterion must not be handed back to the owner for confirmation." Keep that rule intact.

## Calibration from the owner's actual feedback

Seed a bounded design-review rubric with paired examples from [the owner review](../../todos/2026-10-25-owner-review-pr302-ui-feedback.md):

- **Retain:** Preview's overall experience and Health's specific actionable links.
- **Find and fix at the shared pattern:** modal close convention, error placement, target description, confirmation labels, replay availability and focus.
- **Find and fix at the area:** Raw provider source's grouped heading/reveal/privacy note, compact facts, consistent type roles.
- **Find and fix at the page:** visible full-detail technical evidence, discoverable quick-view recovery, natural filter interaction.
- **Do not rediscover as an open defect:** the demo Auth adapter mismatch and missing replay e2e were addressed in Phase 173.1; use their regression tests as evidence. The owner's note explicitly distinguishes these covered items from remaining library UX work.

Store reviewer findings with scenario/URL, viewport, theme, reduced-motion setting, rubric item, evidence, severity and lowest owning layer. Deduplicate manifestations of the same shared defect. Use binary judgments and bounded passes; no aesthetic numeric score may substitute for observed task behavior. Preserve calibrated owner rejections rather than repeatedly rediscovering a preference they have already settled.

## Conflicts and their recommended resolution

| Recorded constraint or tension | Evidence | Resolution for this proposal |
|---|---|---|
| Generic prompt says every reachable combination; maintaining a Cartesian product is unbounded | Owner's current message; methodology file's explicit "equivalence classes rather than prop permutations" | Cover distinct reachable behavior/content risks and selected high-risk interactions. Keep the pruning ledger and require a user situation for each retained variation. |
| Generic prompts favor Apple-like polish; brand disallows literal glass styling | `CLAUDE.md`: "NO glassmorphism, bevels, lens flares"; canonical `brandbook/` | Transfer clarity, coherent affordances and physical interaction quality. Retain Mailglass's identity and web semantics. |
| Apple advises against app-specific theme settings; Mailglass explicitly supports them | Apple Dark Mode; PRODUCT and existing theme picker | Preserve System/Light/Dark. Native Apple advice is not a web contract override. |
| Owner asks to unmask inbound addresses; historical route-trace plan required masking | [Owner review item 3](../../todos/2026-10-25-owner-review-pr302-ui-feedback.md); [Phase 170 Plan 03](../../milestones/v2.9-phases/170-inbound-investigation-and-recovery/170-03-PLAN.md): "mask recipient and subject values, withhold header values and sensitive expected literals" | Scope review separately for authorized top-level contact display and diagnostic/raw evidence. Do not use this refactor to blanket-unmask subjects, header values, sensitive matcher literals or raw source. Preserve action-time `:reveal_raw` policy; document the exact proposed display change in the later implementation plan. |
| Some old copy recommends actions unavailable in the current product | Brand microcopy is a reference; PRODUCT requires supported actions and current evidence | Validate copy against current controls and capability contracts before linting/enforcing it. Do not canonize obsolete wording simply because it is in `brandbook/copy/`. |
| Recipient output is themed by the sender/client, while Admin has its own theme | PRODUCT's sender identity and browser-preview evidence boundaries | Separate operator surface themes, frame appearance and real email-client dark mode. Stories must not imply inbox compatibility certification. |
| Generic prompt asks to retire the gallery; it is an adopter-visible route | Prior Storybook recommendations and admin router/package source | Port internal review coverage first. Route removal requires a compatibility/product disposition, not routine story pruning. |

## Adversarial pass and stopping rules

| Objection | Why it is valid | Guard / decision |
|---|---|---|
| Six fictional products could become theatre | Colorful biographies do not prove usability or actual adoption | Keep compact hypotheses with unique test contributions; drop redundant profiles. No claim of a literal digital twin without observed evidence. |
| A fixture invariant suite can enshrine a false worldview | Strict builders can reject late events, nil fields or unusual valid content | Base invariants on current contracts; include adversarial valid examples and avoid universal event-order assumptions. |
| Storybook may look perfect while the real app fails | Static render cannot prove event semantics, routing, authorization or focus after LiveView patches | Share production components and retain connected-route tests for each job's critical transition. |
| Fractal extraction can make a simple template harder to read | Splitting every div adds APIs and indirection | Extract meaningful responsibility/interaction/width boundaries, with explicit assigns. No component exists solely to satisfy a hierarchy quota. |
| Token lint can become dogma | Browser-computed styles have valid state-dependent and semantic exceptions | Check authored scope and meaningful role contracts; keep narrow justified exceptions. Do not require every computed number to equal a raw token literal. |
| Professional polish may be lost in mechanical gate-chasing | Passing contrast/overflow does not establish elegant typography or understandable copy | Keep a bounded composed-screen review against owner examples after deterministic checks pass. |
| The test matrix can erase its speed advantage | Every persona × state × theme × width × motion × locale becomes expensive | Deduplicate equivalent scenarios, run small relevant PR slices plus mandatory sentinel cases, and reserve broad sweeps for an explicit measured budget. Never silently skip untested states and call the result full coverage. |
| Owner feedback may turn into a redesign campaign | Every pass finds another taste tweak | Fix demonstrated or calibrated findings at the lowest owning layer. Stop after agreed rubric coverage and real journey checks; file additional ideas for the next rolling milestone. |

Stop expanding when a new scenario contributes no distinct supported job/state/content failure, when a new persona contributes no new evaluation class, or when the next layer would duplicate existing integration proof. Refresh the catalogue and prune at each milestone boundary. The deliverable is faster, more trustworthy iteration on actual user work—not the largest story count.

## Recommended bounded sequence

1. Refresh the current user/job map from PRODUCT and source; classify historical research as history. Preserve the useful existing cohort and owner feedback.
2. Define the compact six-profile metadata and canonical reachable scenarios; separate pure fixture data from materializers, then add graph invariants.
3. Story one valuable vertical job first: Health → delivery selection → quick/full detail → exact replay review/outcome. Include normal, unavailable, stale and denied cases. This proves the fixture and composition choices before scaling.
4. Extend shared primitives/patterns and the corresponding Inbound job, keeping the same visual/verbal conventions and distinct domain semantics.
5. Expand Preview and recipient output only with their actual author/recipient roles and evidence boundaries. Preserve the already-praised Preview experience.
6. Add representative composed-screen reviews and calibrated advisory findings; prune duplicate/unreachable scenarios and migrate internal gallery coverage. Treat any public-route retirement as a separate compatibility decision.

No new dependency, rebrand, public authorization change, interactive unsubscribe submission flow or product-code edit is proposed for this research session.
