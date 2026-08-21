# Phase 159: Raise and Simplify Engineering Gates — Context

## Decisions

- Autonomously raise the engineering bar significantly.
- Protected merge proof must be deterministic and fail closed.
- Do not perform CI churn or a topology rewrite for its own sake; make the smallest coherent changes that make the protected signal honest.
- Browser, demo, preview, and admin-visual evidence stays advisory and must be visibly unable to masquerade as merge proof.
- Do not change admin/operator UI behavior.
- Keep core, admin, and inbound independently released packages.
- Optimize for one-maintainer simplicity: centralize repeated setup and policy rules only when it preserves required check identity and makes the contract easier to audit.

## the agent's Discretion

- Choose the exact protected-lane inventory, provided it covers every QUAL-03 required behavior and remains explicitly tested.
- Choose the smallest reusable CI setup mechanism and policy-manifest format that preserve sibling package isolation.
- Establish coverage floors only after measuring the canonical suites on the pinned CI toolchain.
- Define expiry formats, owners, and deterministic acknowledgement mechanisms for skips, flakes, and asynchronous tests.
- Sequence quality debt cleanup and gate promotion to keep each plan slice independently verifiable.

## Deferred Ideas (OUT OF SCOPE)

- Product features, public API changes, provider expansion, data migrations, and release publication.
- Admin/operator UI behavior, browser UX, preview visuals, or design-system work.
- Promoting browser/demo/preview/provider-live/next-toolchain/clean-baseline/publish-only evidence into merge requirements.
- Recombining sibling packages, introducing a monorepo build system, or wholesale CI topology redesign.
- Optimizing CI duration beyond repeated unsafe setup and cache/key duplication necessary for correctness.
