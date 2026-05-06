# Project Methodology

## Decisive-By-Default Research Posture

**Diagnoses:** Workflows that repeatedly surface routine implementation tradeoffs to the user even when the codebase, ecosystem norms, and project goals already point to a coherent default.

**Recommends:** Research first, synthesize tradeoffs, and recommend a single coherent default that aligns with mailglass's Phoenix-first architecture, maintainer budget, principle of least surprise, and strong developer ergonomics. Default to writing the recommendation into phase context and planning artifacts without asking the user to choose among routine alternatives. Escalate only when a decision would materially alter public API, route/config contract, tenant trust boundaries, retention or audit semantics, long-term maintainer burden, or a user-visible workflow default the project owner is likely to care about directly.

**Apply when:** Any discuss, assumptions, research, or planning workflow encounters gray areas with strong ecosystem priors, existing repo patterns, or narrow contract-drift fixes where the main risk is indecision or unnecessary option sprawl rather than lack of information.

## Honest Surface Area

**Diagnoses:** Public examples, config schemas, or docs that imply a broader default behavior than runtime actually provides, or that expose speculative knobs before semantics are real and stable.

**Recommends:** Keep generated examples, config validation, and docs tightly aligned with actual runtime behavior. Prefer small honest surfaces over brochure-style comprehensiveness. Expand only when the new surface is real, documented, testable, and supportable.

**Apply when:** Working on installer output, public docs, config schemas, router macros, or any adopter-facing integration seam.

## Recommendation-First Synthesis

**Diagnoses:** Workflows that gather enough context to see the tradeoffs, but still hand the decision burden back to the user too early instead of synthesizing a coherent recommendation set.

**Recommends:** Research across local code, official docs, and strong ecosystem precedents; compare alternatives internally; then present one cohesive recommendation set that fits the project vision, maintainer budget, least-surprise UX, and long-term architecture. Prefer a single decisive recommendation over broad option menus. Shift this left in downstream workflows: default to one-shot synthesis and escalate only if the choice is likely to materially change public contract, user trust semantics, major maintainer burden, tenant-boundary guarantees, secret-handling posture, branch-protection/release posture, or other very impactful workflow behavior the project owner is especially likely to care about. When a workflow still needs to surface choices, it should present a recommended set first and treat the alternatives as exceptions to override, not as the default shape of the conversation.

**Apply when:** Discuss, assumptions, research, and planning workflows encounter multiple plausible approaches and enough evidence exists to recommend one without another interview round.

For release, upgrade, compatibility, and trust-contract phases, push this even
further left: default to one cohesive recommendation set and escalate only when
the choice is likely to materially change the public contract, irreversible
publish posture, security/trust semantics, or long-term maintainer burden.

## Compatibility Contract Ergonomics

**Diagnoses:** Compatibility, deprecation, and upgrade phases that discover
warnings-as-errors fallout, silent legacy aliases, or support-horizon ambiguity
too late, after docs and CI already disagree.

**Recommends:** For any phase that changes public contract, deprecations,
upgrade guides, release policy, or support matrix, planning should produce a
small deprecation-DX inventory before implementation starts:
- surface
- replacement
- warning channel
- `--warnings-as-errors` impact
- support-until version
- proof artifact

Prefer one canonical compatibility story, explicit support horizons, and the
narrowest honest promise that preserves a smooth upgrade path. Default to
decisive synthesis; escalate only if a choice materially changes the public
contract, long-term maintainer burden, or user trust semantics.

**Apply when:** Stability, compatibility, trust-doc, release, and upgrade
phases, especially in library work where strict CI adopters are part of the
intended audience.
