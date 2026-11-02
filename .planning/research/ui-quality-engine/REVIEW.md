# Bounded adversarial cross-review

Date: 2026-10-26. Scope: `INVENTORY.md`, `RECOMMENDATIONS.md`, `MILESTONE-PROPOSAL.md`, `PERSONAS-DESIGN.md`, `AUTOMATION.md`. One independent contradiction/factual-risk pass; no product implementation or active milestone review.

**Final verdict: no open blockers.** The independent pass found two documentation corrections; both were applied and re-read on 2026-10-26 as recorded below. No architectural or strategic decision blocks the proposed next milestone. Main `RECOMMENDATIONS.md` is the authority where specialist alternatives differ.

## Required corrections

| ID | Finding and evidence | Concrete resolution |
|---|---|---|
| R1 — inconsistent pilot budget | `RECOMMENDATIONS.md:105` proposes five additional PR wall minutes; `AUTOMATION.md:50` proposes ≤3 minutes plus ≤10 additional runner-minutes. Future executors could claim different acceptance from the same proposal. Neither target is measured. | Use **≤5 minutes added PR wall time and ≤10 added runner-minutes for the initial story gate** consistently. Include cold/warm startup and check execution in pilot measurements; describe both as provisional targets requiring actual-runner measurement, not promises or permission to drop coverage. Reassess the full vs change-affected split from evidence. |
| R2 — current Admin font distribution misdescribed | `PERSONAS-DESIGN.md:87` uses the brand book's no-font-files statement to conclude fallback type is the everyday Admin interface. Current `mailglass_admin/mix.exs:222–234` includes `priv/static` expressly including fonts; `controllers/assets.ex:491–498` serves six bundled WOFF2 faces: Inter, Inter Tight and IBM Plex Mono at 400/700; the committed CSS declares the font faces. The brandbook's asset-distribution statement cannot substitute for current Admin runtime evidence. | Preserve brand font roles but state that **Admin currently ships font files**. Require intended bundled-face loading, network success and computed font roles on Storybook and real routes before accepting visual fidelity. Test system fallback separately for failure/resilience; do not accept Storybook's observed serif as an intended fallback. Record the narrower brand-assets versus Admin-distribution distinction, and treat any broader brand prose as stale relative to runtime source. |

The authoring agent should apply these changes in the owned synthesis/specialist files. This reviewer intentionally edits only this review record.

## Checks with no blocking finding

- **Inventory:** 5 primitive stories, 35 variations with zero description fields; Gallery 119 states/32 families/357 light-dark-System cells; LiveView line counts and the distinction between reference lines and test counts match static source. Live browser observations are appropriately qualified rather than used as conformance certification.
- **State realism:** The proposal avoids invented universal queued→sent→delivered chronology, preserves partial/late provider facts and current-suppression/historical-event distinctions, requires real linkage for replay and keeps fixture permission flags separate from actual authorization.
- **Fixture/package boundary:** Pure scenarios and persistence adapters are separated; no admin→demo dependency, production Storybook route, package fixture inclusion or new runtime dependency is proposed. The automation note correctly distinguishes DB-free rendering from a demo application that still starts Ecto.
- **Story fidelity:** Mount-prefix, typography/CSS, native data-theme support and production hook sharing are first delivery gates. Static Storybook success does not replace URL/auth/account/replay/connected-focus integration proof.
- **Compatibility:** Storybook becomes the maintainer inventory without silently removing the documented shipped Gallery route. No redirect into a dependency adopters do not have is proposed. Final route retirement remains a later explicit compatibility decision.
- **Cost and scope:** State equivalence classes, risk-based expensive checks, no Cartesian screenshots, no generic schema engine, no CI model keys, bounded critique and job-based stopping rules keep the plan finite. Full coverage and change-affected coverage must remain separately labelled and count expected/attempted cells.
- **Standards adaptation:** The plan correctly distinguishes actual zoom from root-font scaling, axe incomplete from proved violations, WCAG target-size exceptions from the product's stricter control floor, semantic navigation consistency from identical ARIA trees, and two-dimensional accessible scrolling from page overflow.
- **Sequencing:** One complete Delivery investigation slice precedes Inbound/Preview expansion; fixture/manifest work is connected to user-visible jobs rather than becoming an infrastructure-only program. Owner replay and live-filter feedback remains attached to implementation slices.
- **Methodology boundary:** Artifacts are research and a rolling proposal only. Official ROADMAP/REQUIREMENTS are not rewritten, no milestone is opened, and no product or dependency edit is included. Starting a local existing Storybook for inspection does not change that planning-only boundary.

## Closure

| Finding | Resolution verified by the synthesizing agent |
|---|---|
| R1 | `RECOMMENDATIONS.md` and `AUTOMATION.md` now agree on provisional **≤5 added wall minutes / ≤10 added runner-minutes**, including cold/warm setup measurement; no measured performance claim. |
| R2 | `PERSONAS-DESIGN.md` now identifies the six shipped WOFF2 faces and separates intended-font fidelity from fallback stress. Re-read against `priv/static/fonts/`, `controllers/assets.ex` and `assets/css/app.css`. |

The review has no remaining blockers. Preserve this record as the explanation for the corrections; do not spin up another open-ended review round. Implementation planning should use the reconciled synthesis, not conflicting historical specialist options. This is documentary review closure, not evidence that the future UI implementation or tests pass.
