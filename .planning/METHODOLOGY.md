# Project Methodology

## Decisive-By-Default Research Posture

**Diagnoses:** Workflows that repeatedly surface routine implementation tradeoffs to the user even when the codebase, ecosystem norms, and project goals already point to a coherent default.

**Recommends:** Research first, synthesize tradeoffs, and recommend a single coherent default that aligns with mailglass's Phoenix-first architecture, maintainer budget, principle of least surprise, and strong developer ergonomics. Escalate only when a decision would materially alter public API, route/config contract, tenant trust boundaries, retention or audit semantics, long-term maintainer burden, or a user-visible workflow default the project owner is likely to care about directly.

**Apply when:** Any discuss, assumptions, research, or planning workflow encounters gray areas with strong ecosystem priors, existing repo patterns, or narrow contract-drift fixes where the main risk is indecision or unnecessary option sprawl rather than lack of information.

## Honest Surface Area

**Diagnoses:** Public examples, config schemas, or docs that imply a broader default behavior than runtime actually provides, or that expose speculative knobs before semantics are real and stable.

**Recommends:** Keep generated examples, config validation, and docs tightly aligned with actual runtime behavior. Prefer small honest surfaces over brochure-style comprehensiveness. Expand only when the new surface is real, documented, testable, and supportable.

**Apply when:** Working on installer output, public docs, config schemas, router macros, or any adopter-facing integration seam.

## Recommendation-First Synthesis

**Diagnoses:** Workflows that gather enough context to see the tradeoffs, but still hand the decision burden back to the user too early instead of synthesizing a coherent recommendation set.

**Recommends:** Research across local code, official docs, and strong ecosystem precedents; compare alternatives internally; then present one cohesive recommendation set that fits the project vision, maintainer budget, least-surprise UX, and long-term architecture. Escalate only if the choice is likely to materially change public contract, user trust semantics, major maintainer burden, or high-visibility workflow behavior the project owner is especially likely to care about.

**Apply when:** Discuss, assumptions, research, and planning workflows encounter multiple plausible approaches and enough evidence exists to recommend one without another interview round.
