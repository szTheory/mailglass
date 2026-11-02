# Project Methodology

## Shift-Left Verification by Default

**Owner decision (D-52, 2026-10-08):** Treat human UAT as a last resort. Before presenting a GSD verification checkpoint, convert every machine-observable acceptance criterion into a deterministic test and run it. A testable criterion must not be handed back to the owner for confirmation. Record passing automation as verification evidence and do not reopen it unless the implementation or acceptance contract changes.

**Recommends:** Put each assertion at the cheapest boundary that proves the user-visible contract: unit/property tests for pure rules, ExUnit or integration tests for LiveView/server seams, Playwright for browser behavior and layout, and smoke or contract tests for host and provider boundaries. Use real controls and user-observable outcomes; include adversarial values, scope isolation, failure/empty/loading states, keyboard behavior, and relevant viewport/theme/motion variants. Prefer DOM, accessibility, layout, and geometry assertions over brittle pixel snapshots unless pixel rendering itself is the contract. Reuse the existing test stack and CI job first; add or promote a required CI lane only when recurring regression risk justifies its runtime and maintenance cost. Do not add a dependency or duplicate a test harness when the existing stack can cover the behavior.

**Apply when:** Planning, executing, reviewing, or verifying any phase. For recurring acceptance, ensure the test runs in CI and report whether that job is a blocking required check or an advisory check; do not present an advisory green as merge-blocking proof. Keep `human_needed` only for a criterion that remains irreducibly subjective or requires physical-device, legal, policy, or otherwise unavailable human judgment after reasonable automation. If a GSD workflow proposes a generic confirmation summary for criteria already covered by passing tests, record the evidence and continue without an owner checkpoint.

**Reaffirmed by the owner, 2026-10-27 (Phase 174):** Target zero human verification/UAT. Finish the automated verification and routine repairs rather than asking the owner to inspect deterministic receipts, supply a missing test descriptor, or accept avoidable UI defects. Agent visual inspection plus explicit layout/contrast/keyboard assertions can settle bounded UI review; an axe `incomplete` remains an axe `incomplete`, with supplemental proof recorded separately. A missing enforcement check is engineering work, not an owner decision.

**Prevent repeated UAT loops:** Each completed phase records the acceptance-to-test mapping, exact commands, current source identity, retained evidence, CI placement and any real limitations in its UAT/verification artifacts. Close covered rows with `source: automated`, clear stale human-needed state and route GSD to the next phase. Reopen only for a changed relevant implementation/acceptance contract or fresh failing evidence; do not rerun subjective sign-off for already-proved behavior or confuse historical evidence with current-source proof. Add recurring checks to existing CI lanes when their regression value justifies the cost; use one-time agent checks for one-time judgments. Preserve unrelated workspace edits.

**Judgment-tier prohibitions are not an owner hand-off (2026-10-27, Phase 175):** The GSD verifier routes every `verification: judgment` must-NOT prohibition to `human_needed` with "unverified-prohibition — human review recommended". This was the one remaining path that produced owner UAT after D-52, with eight rows in Phase 175. Copy, framing, and control prohibitions (no resend or receipt claims, no blame or policy-bypass wording, no all-clear or permanence claims, no retry pressure, no invented controls) reduce to forbidden wording or controls over a closed set of copy branches and rendered states. Author them as `verification: test` at spec/plan time. If judgment rows still appear, write a contract test that enumerates every branch and refutes each violation. Include a detector self-test against known-bad strings, and prove each prohibition red with a source mutation, then restore the source. The mutation step is required: in Phase 175 it caught a state the first pass never rendered. Template: `mailglass_admin/test/mailglass_admin/phase175_prohibition_contract_test.exs`. Then close the rows `source: automated`, run `phase uat-passed --uat-only`, and set VERIFICATION `status: passed`. Keep `judgment` only for a truly non-mechanizable constraint, and say why.

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
