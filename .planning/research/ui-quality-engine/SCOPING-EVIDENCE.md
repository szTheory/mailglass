# Evidence and stopping rules for upstream UI scoping

2026-10-26. **Upstream research only.** This supplements `RECOMMENDATIONS.md`, `MILESTONE-PROPOSAL.md` and the new owner review note; OpenGSD still owns formal milestone scope, requirements, design spikes, phase plans and execution. No UI repair, test pass, runtime improvement or active milestone is claimed here.

## Recommendation: repairs create the review system

Make the first delivery a small, visible improvement with a trustworthy retained story and a real-route check. Repair Storybook's mount-path and typography fidelity alongside it. Quiet quick-view navigation or Preview action/identity cleanup is a good bounded first demonstration; both already have concrete owner feedback. Then complete one important investigation/recovery job, expanding fixtures and composition only as that job requires. Health layout deserves a bounded composition comparison, not an advance assumption that one column always wins.

The current proposal is directionally sound but risks front-loading five enabling systems before the owner sees a repaired screen. Prevent that with one stop line: **no infrastructure-only milestone and no new abstraction without a selected repair that uses it.** A minimal manifest, a handful of realistic scenarios and existing Playwright helpers are enough to start. Defer a comprehensive profile catalogue, generalized change-impact graph, findings database, automatic calibration service and wholesale LiveView extraction.

Existing evidence supports this priority: `storybook.ex` omits hook JavaScript; `ARCHITECTURE.md` records wrong sandbox typography and `/dev` navigation; `AUTOMATION.md` identifies fresh axe results that are not compared to the approved baseline during ordinary runs. Expanding story counts before correcting these would expand unreliable evidence.

## Minimum evidence by rolling horizon

| Horizon | Evidence needed to close it | Stop / carry forward |
|---|---|---|
| Trustworthy review + first repaired area | Exact production component and stylesheet; intended fonts; correct deep links/themes; before/after for the concrete feedback; representative realistic normal/boundary state; fresh accessibility comparison; real-route check for affected interaction | Stop when the first repair is useful and reproducible. Do not wait for every persona or every component |
| Complete the selected operator job | Entry → investigation → action/recovery → return with Account and selection intact; honest empty/failure/denied states; reachable fixture-to-read-model parity; narrow/wide/container and light/dark review; keyboard/focus; connected outcomes and authorization | Do not declare success from an isolated modal. Carry unrelated job expansion into the next horizon |
| Expand to Inbound/Preview/recipient jobs | Reuse proven patterns; preserve each job's actual semantics; specific owner findings resolved; scoped raw-evidence disclosure; author identity and renderer provenance retained; representative connected route parity | Choose the next job from remaining user harm, not catalogue symmetry. Recipient preview is not delivered-email-client proof |
| Consolidate sustainably | Disposition for migrated Gallery cases and dependent assertions; discoverable canonical stories; measured cost; short pruning/review note; explicit public-route compatibility decision if removal is proposed | Quiet maintenance is a valid outcome. No mandatory judge platform or Gallery removal to call the work valuable |

These are evidence boundaries for later scoping, not predetermined phase counts or commitments to all four horizons.

## Fix false confidence early, narrowly

Before accepting the first new story sweep as a ratchet, compare **fresh** axe output to approved findings. Today the producer checks result shape/overlay presence; the ExUnit comparator checks committed JSON. Reuse that machinery, but add the missing fresh comparison at the implementing boundary. Stable target/rule/state fingerprints prevent a new violation replacing an old one under an unchanged count. Fail on missing/blank/failed cases and incomplete expected coverage; review axe `incomplete` separately instead of calling it either a proved violation or a pass.

Do not make this a repo-wide accessibility cleanup prerequisite. Triage the current selected area; keep unrelated debt explicit. A future blocking claim requires evidence that the check actually feeds required CI: browser jobs currently sit outside `CI Green` dependencies, while live independent required checks remain unverified. OpenGSD should plan any necessary CI-policy lockstep. No weakening or quiet rebaselining of existing checks is justified.

## Fidelity before screenshots become design evidence

For each selected area, require a short fidelity receipt: source revision; actual story/routed URLs; resolved CSS response and digest; intended font family/weight and loaded face; theme/OS preference; hook behavior where applicable. An imported stylesheet may not appear as a `link` element. A declared Inter family or `document.fonts.ready` alone does not prove that Inter was used: inspect matching loaded faces and successful asset responses as well as computed roles. `FontFaceSet.check()` may return true for a nonexistent face, so it is not a sufficient font-availability assertion. [CSS Font Loading](https://drafts.csswg.org/css-font-loading/), [browser API caveat](https://developer.mozilla.org/en-US/docs/Web/API/FontFaceSet/check).

Production bundles currently ship six WOFF2 faces at 400/700. Keep fallback-font stress separate from intended-font acceptance. For hook-dependent quick views/modals, share the production implementation through the pinned Storybook adapter; test mount, update, close and focus return on a connected route. Do not load a second socket bootstrap or replace production behavior with story-only JavaScript. Hook lifecycle is part of LiveView behavior, not a property of static HTML. [Phoenix hooks](https://phoenix-live-view.hexdocs.pm/js-interop.html#client-hooks-via-phx-hook).

## Realistic fixtures, honest speed

Start from existing adopter facts and pure scenario builders; persist through separate adapters. Check enums, scope/linkage and contractually valid data. Compare representative scenario projections against actual persisted reads; do not invent universal event ordering or encode fake authorization in view flags. Shared facts need not mean one oversized map used everywhere.

The demo still starts Ecto. Therefore DB-free builders do not yet prove DB-free startup or faster CI. Pilot the selected primitive/group/area/screen including setup, cold/warm conditions, axe, geometry and artifact handling. **Provisional ceiling: ≤5 extra PR wall minutes / ≤10 extra runner-minutes, including setup.** These are budget targets, not measurements. If exceeded, eliminate duplication and partition safe independent work before proposing separate full/change-affected profiles. Report omitted coverage explicitly; don't lower the acceptance matrix to hit a number. An alternate host is a downstream experiment only if measured startup makes it necessary.

## Owner feedback: quiet controls and useful addresses

Borderless previous/next arrows can keep their current 44px hit boxes, names, focus treatment and disabled boundaries. The defect is visual weight; it does not require smaller targets. Keep position readable, distinguish hover/focus from the idle appearance and preserve keyboard/return behavior in both quick views. WCAG's 24px minimum has exceptions and is distinct from Mailglass's stricter control floor. [Target size](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html).

The owner explicitly requests complete From/To addresses in ordinary authorized evidence. Scope this as useful contact presentation; do not perpetuate masking there merely because screenshots exist. **Privacy-safe test evidence comes from synthetic data**, not an unhelpful production UI. Use fictional reserved-domain addresses and no live tokens/headers in fixtures or retained captures. Real routes continue to enforce account authorization. Raw source, routing/matcher values, telemetry and logs retain their separate sensitive-disclosure contracts. A reveal control remains authorized and clearly explained; unmasking ordinary addresses does not authorize blanket raw payload disclosure.

## Universal delivery obligations vs downstream experiments

Every delivered slice needs real caller/state provenance, truthful content, shared production rendering, synthetic retained evidence, light/dark results, applicable Account/security contracts and a reproducible normal plus failure/boundary case. Use 320/375/768/1280/1440 landmarks while retaining existing defect widths; inspect the actual pane/content container. System must follow both OS preferences where theme ownership occurs. Keep real zoom, reduced-motion and interaction checks at their owning boundaries. These are continuing obligations, not proof produced by this planning session.

OpenGSD should resolve **design/implementation experiments** downstream: Health primary/secondary grouping at actual widths; exact Preview scenario/module hierarchy and reset placement; compact Account presentation without inventing Account-scoped Preview; raw-source fact grouping; suppression refresh ownership; font/theme/hook adapter mechanics; smallest useful presentation extraction; measured runner profiles. Each experiment has a concrete acceptance question and finite alternatives. A generic taste judge cannot settle truth about scope, current facts or authorization.

## Compact review and pruning

Keep one scenario record with ID, role/job, real source, important state and why it survives. Keep findings in the existing research/review conventions with URL, width/container, theme, evidence and owning tier. Record `keep/merge/prune/defer` plus destination/reason when migrating Gallery cases. Link owner accept/reject notes to the same IDs; changed code/context invalidates an old suppression. Do not create a parallel finding database.

One design pass and one adversarial check are enough per slice unless a new material issue remains. Owner examples already calibrate priorities: breathing room, restrained controls, grouped evidence and readable identity. Treat numerical judge precision as unknown; no calibration product is needed to apply these clear preferences. Prune impossible, obsolete and redundant stories; retain reachable awkward states until repaired, and move useful domain-invalid input regressions to their proper lower-level test.

**Adversarial conclusion:** repairing only Storybook risks a polished fake; repairing only pages risks another short-lived UI pass; building every proposed layer risks a maintenance empire. The smallest coherent unit is a repaired real job with reusable production presentation, credible scenarios and fresh checks. Expand only when the next uncovered job or recurring defect pays for the added maintenance.
