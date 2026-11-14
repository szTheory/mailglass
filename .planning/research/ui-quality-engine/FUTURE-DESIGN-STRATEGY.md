# Future Mailglass design direction

**Recorded:** 2026-11-02  
**Authority:** Owner instruction in the 2026-11-02 session; prior-art observations are supporting research, not a new milestone admission.

## Owner direction

- Finish the current v2.10 milestone. When it is complete, pause before starting another milestone until the new Mailglass brand book is ready.
- Treat the accepted UI work in v2.10 as useful progress, but do not treat its current visual direction as the final long-term brand baseline.
- When work resumes, use the new brand book to guide a coherent design-system and JTBD/user-flow pass. Continue with `phoenix_storybook` while it serves the work; consider switching to Fablebook only after its readiness evidence is complete and the owner wants the switch.
- Keep implementation light while that pause is pending. Prefer existing tools and focused local code over new dependencies when they meet the need.

## Recommendations for the future brand-led pass

1. Ground the brand in observed product facts. Record what to keep, evolve, or retire; label proposals, inferences, and unknowns so design copy does not claim product behavior the code cannot support.
2. Make the handoff useful to both people and code: a readable brand book, concise `BRAND.md`, structured brand/token data, generated CSS where appropriate, and an asset manifest that states each asset's role, placement, minimum size, and provenance.
3. Keep broad brand principles separate from Mailglass-specific implementation guidance. Map any semantic tokens to the actual Phoenix components and current admin styles; do not assume a token layer is consumed merely because it exists.
4. Check light and dark themes, small sizes, contrast, responsive layouts, keyboard/focus behavior, and real product copy before calling a direction finished. Include screenshots or another inspectable receipt for generated or corrected assets.
5. Carry actual Mailglass jobs, personas, and support/operator vocabulary into composed stories. Keep assumptions visible and distinguish adopter-product users from the engineers and support operators using Mailglass.
6. Keep dependency trees small. Prefer a short local implementation when that is enough; add a dependency only when its continuing value is clear.

## Readiness posture for Fablebook

The supplied Fablebook worktree is still an early, unreleased workbench. At commit `047e554a6f57fe0f1996ddaa8c4568234d9c4b2c` (2026-11-02), the route is a development placeholder, while catalog/rendering, workbench UI, design canon, and LLM-assisted review remain roadmap work. The worktree has local planning/test changes, so its state should be checked again before relying on it.

Its research and architecture offer useful principles, but are not evidence that the product is ready:

- Keep the library's own users separate from each adopter's personas and jobs. For Mailglass, derive stories from Mailglass research rather than borrowing example personas. Source: `docs/research/PERSONAS-JTBD.md`.
- Keep an imported brand canon read-only and hash-pinned, with tokens, voice, glossary, personas, jobs, and themes kept as distinct inputs. Source: `docs/adr/0012-canon-format.md`.
- Build any future model context from only the relevant tokens, voice, persona/job context, rendered markup, screenshots, ARIA information, and checks. Label stale input, redact sensitive content, and avoid adding an LLM API dependency by default. These are design plans, not shipped Fablebook features. Source: `docs/adr/0010-llm-context-bundle.md`.
- Keep using `phoenix_storybook` until the Fablebook clearance criteria are actually met and the owner chooses to switch. The reviewed `CLEARANCE.md` still had open criteria for product parity, production fidelity, dogfood stability, and owner approval.

## Provenance

These references support the recommendations above. They do not prescribe who or what produces the future Mailglass brand book.

- ExifCleaner v1.4 delivery at commit `97f4aed1ec2dff729e9dff20a7eabfe14431e63f` (2026-10-30): `brand/BRAND.md`, `brand/brand.json`, `brand/tokens.json`, and `brand/assets/**`. The handoff separates the readable book, structured rules, tokens, and mapped assets. The related direction notes distinguish product evidence from proposals and unknowns; the self-review caught responsive, contrast, and asset issues.
- Accrue brandbook asset manifest: `brandbook/README.md` at `4cd4b6c6e`; assembled book `brandbook/index.html` at `8cf4fe13f`, with visual corrections at `c73e18649`; voice at `c8eda5502`; source/generated token files at `e3896ce97` and `739b4f940`; token contract at `2ade7481c`.
- Fablebook snapshot reviewed at `/private/tmp/fablebook-resume.s7Ay0g/fablebook`, commit `047e554a6f57fe0f1996ddaa8c4568234d9c4b2c`; sources: `docs/research/PERSONAS-JTBD.md`, `docs/adr/0010-llm-context-bundle.md`, `docs/adr/0012-canon-format.md`, and `.planning/intent/CLEARANCE.md`.
- Current milestone completion and review state: `.planning/phases/178-preview-authoring-and-milestone-review/178-24-SUMMARY.md`, `178-38-SUMMARY.md`, and `178-RECOVERY-CYCLE-09.json`.

## Phase 178 UI review findings to carry forward

The 2026-11-02 six-pillar review scored the current Preview work 19/24. It identified three changes for the next brand-led pass:

- Include the Mailable context in scenario links' accessible names.
- Keep Preview directory labels readable at narrow widths.
- Keep disambiguating Mailable labels visible without relying on a tooltip.

The review could not produce fresh Playwright screenshots and checked one retained 375px capture against the current source. These are review findings, not evidence that the accepted preview failed. Preserve them as design backlog for the next milestone, when the new brand book can guide the resulting visual treatment. Source: `.planning/phases/178-preview-authoring-and-milestone-review/178-UI-REVIEW.md`.
