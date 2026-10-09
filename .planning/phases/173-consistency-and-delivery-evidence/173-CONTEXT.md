# Phase 173: Consistency and Delivery Evidence - Context

**Gathered:** 2026-10-09 (assumptions mode)
**Status:** Ready for planning
**Direction:** Apply the user's recommendation-first and shift-left preferences: synthesize from repository evidence and primary sources, make routine choices, automate observable acceptance, and escalate only for a material contract or delivery decision.

<domain>
## Phase Boundary

Make the v2.9 delivered UI coherent across the existing Admin Gallery, demo Storybook, current brand/token guidance, and delivered patterns; make a bounded set of focused checks and source-identified before/after renders reproducible; and prepare a documented working milestone preview with required CI, current generated assets, committed task-owned changes, and explicitly handled temporary services/artifacts.

Phase 173 owns UIQ-01 through UIQ-03. It does not authorize a merge, package publication, new required CI lane, paid visual judge, email-client certification, new UI/catalog framework, or unrelated redesign. The exact exit criteria are `.planning/ROADMAP.md` Phase 173 and `.planning/REQUIREMENTS.md`.
</domain>

<decisions>
## Implementation Decisions

### Shared patterns, token ownership, and review surfaces
- **D-01:** Treat `brandbook/brand-book.md` as the identity and voice master and `brandbook/tokens.css` as the canonical brand-value source. Keep `mailglass_admin/docs/design-system.md` focused on current implementation mechanics and map its examples to the values actually shipped by `mailglass_admin/assets/css/app.css`; remove contradictions, stale sizes/colors, and historical visual-score instructions that could be mistaken for current acceptance.
- **D-02:** Keep `MailglassAdmin.GalleryLive` as the comprehensive, interactive inventory of shared components and relevant states. Keep PhoenixStorybook in the demo app as a curated primitive/story explorer, consistent for overlapping patterns and themes, without duplicating every Gallery state. Explain each surface's purpose and route maintainers from the guidance to both.
- **D-03:** Reuse existing CSS, HEEx, Gallery and Storybook mechanisms. Do not add a shared specimen framework, mirror a second stylesheet, move Gallery coverage into the demo package, or add a dependency unless implementation proves an existing maintenance problem that cannot be solved with a focused documentation/parity check.

### Repeatable checks and rendered evidence
- **D-04:** Extend the current Playwright/browser path and existing manifests rather than adding visual-test infrastructure. Pair a small representative before/after capture set for changed primary flows and adverse states with focused DOM, accessibility, interaction, and layout assertions. Prefer semantic and geometry assertions for behavior; use screenshots for human-readable rendered comparison, not as a substitute for interaction or accessibility checks.
- **D-05:** Make each evidence record identify the candidate source/revision (and dirty-tree state when applicable), route, synthetic scenario/fixture, theme, viewport, interaction/adverse state, browser, before/after relationship, capture path/hash, and the relevant source/build/served asset identity. Reuse existing asset-byte proof where it already establishes source-to-built-to-served parity. Capture the baseline before changing the evidence target and identify its source; historical screenshots and scores remain historical evidence, not current acceptance.
- **D-06:** Keep browser-rendered email preview evidence distinct from delivered email-client evidence. Do not claim Gmail, Outlook, Apple Mail, image-loading, or dark-mode client compatibility without direct client evidence. Use synthetic fixtures and do not capture real recipient/message data in retained artifacts.

### Candidate preview, CI, and operational cleanup
- **D-07:** Use the existing demo as the working feedback preview and document how to open it, which checkout/source it serves, and which generated assets are loaded. Preserve the owner's retained feedback preview and unrelated services while collecting evidence; isolate Compose project/service names and cleanup to the evidence run rather than stopping the default project.
- **D-08:** Keep required CI status distinct from existing advisory browser/capture jobs. Require the already-defined required CI aggregation to pass for the candidate; run focused existing browser/evidence jobs and the generated-asset drift check where applicable, accurately labeling advisory results. Reuse current lanes first; do not promote a lane or change branch protection as part of this phase.
- **D-09:** Treat temporary services and artifacts as owned resources: evidence commands must clean up only what they create, and the final walkthrough must say which evidence is retained and where. Commit only phase-owned changes through the established GSD process; preserve unrelated pre-existing workspace changes and never claim a candidate is committed or CI-green without matching evidence.

### Shift-left acceptance and decision posture
- **D-10:** Convert all machine-observable Phase 173 acceptance into deterministic checks in the existing stack before any owner checkpoint. Per D-52, passing automation closes the corresponding acceptance row; only irreducible visual judgment or external delivery proof may remain human-needed, and it must be narrowly named. A rendered review can be automated for collection/provenance and still be presented for human visual judgment only if the criterion itself is subjective.
- **D-11:** Use a single coherent implementation plan, bounded to Phase 173's success criteria. Do not churn through alternatives already resolved by repo architecture and source evidence. Escalate only if a decision changes a public or trust contract, retention semantics, branch-protection/release posture, or major maintainer burden.

### Agent's Discretion
- Select representative changed flows, adverse states, viewport/theme combinations, and the smallest truthful capture matrix after inventorying current phase artifacts and current source.
- Choose manifest fields and validation at the least complex existing boundary that prevents stale or misattributed evidence.
- Select the smallest guide, story, evidence-script, and CI-documentation edits that make the delivered state discoverable and repeatable.
- Reconcile baseline and candidate identities using the actual available checkout/preview setup; disclose limitations instead of inferring identity from a URL or historical screenshot.

### Folded Todos
None. The Phase 173 todo matcher returned zero relevant items.
</decisions>

<specifics>
## Specific Ideas

- Repository analysis found an existing architecture worth preserving: the brandbook and token stylesheet define brand truth; Admin CSS maps those tokens to component roles; Admin Gallery owns broad state coverage; demo-only PhoenixStorybook presents selected primitives. PhoenixStorybook's own component variation docs support curated examples; its separate stylesheet-mirroring setup would add a parity burden here.
- The current Admin design-system guide conflicts with the shipped mapping and size guidance, so planning should identify exact stale claims and add a narrow drift guard only if a robust check fits the current test stack.
- The preview capture manifest already records scenario, width, theme, path and hash, and the Playwright suite can cover user-visible browser states. Add provenance only where absent; avoid a second manifest or a custom cross-app catalog.
- `scripts/run_demo_browser_evidence.sh` currently tears down its default Compose project. Isolate project identity and target cleanup to resources created by that run; preserve the long-lived feedback preview.
- CI already separates required `CI Green` from advisory browser and preview-capture jobs. `mix verify.preview` checks generated Admin asset drift, and existing browser proof compares served CSS with the built bundle in relevant flows. Planning should reuse these contracts and be precise about which job is blocking.
- Official primary sources consulted: [PhoenixStorybook setup](https://github.com/phenixdigital/phoenix_storybook/blob/main/guides/setup.md), [PhoenixStorybook component variations](https://github.com/phenixdigital/phoenix_storybook/blob/main/guides/components.md), [Phoenix LiveView render callback](https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html#render/1), [Playwright screenshot assertions](https://playwright.dev/docs/test-snapshots), [Playwright web assertions](https://playwright.dev/docs/test-assertions), [GitHub Actions artifact storage and retention](https://docs.github.com/en/actions/tutorials/store-and-share-data), and [GitHub protected branch checks](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches). These support reuse and honest boundaries; none justify a new dependency or required lane.
- Security/operations review: screenshot artifacts can expose message content; use synthetic data and scoped artifact retention. Compose cleanup must never target the default feedback-preview project. Hashes establish identity/integrity only for the bytes actually hashed and do not establish correct rendering or email-client compatibility.
</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.** Paths are relative to the repository root.

### Scope and acceptance
- `.planning/PROJECT.md` — milestone scope, D-52 owner preference, phase status.
- `.planning/ROADMAP.md` §Phase 173 and acceptance carried through every slice — fixed boundary and exit criteria.
- `.planning/REQUIREMENTS.md` — UIQ-01 through UIQ-03.
- `.planning/METHODOLOGY.md` — shift-left verification, decisive research posture, dependency restraint, honest surface area.
- `.planning/research/v2.9/SCOPE.md` — approved milestone limits and deferred work.
- `PRODUCT.md` — durable product context and package boundaries.

### Inherited phase decisions and evidence
- `.planning/phases/168-shared-workspace-and-usable-baseline/168-CONTEXT.md` and `168-UI-SPEC.md` — shared interaction, accessibility, typography, theme, and baseline rules.
- `.planning/phases/169-outbound-investigation-and-recovery/169-CONTEXT.md` — operator flows, exact evidence, and state preservation.
- `.planning/phases/170-inbound-investigation-and-recovery/170-CONTEXT.md` — inbound context and trust boundaries.
- `.planning/phases/171-developer-preview/171-CONTEXT.md` and `171-RENDERED-REVIEW.md` — preview architecture and prior provenance example.
- `.planning/phases/172-recipient-output-and-built-in-pages/172-CONTEXT.md` and `172-VERIFICATION.md` — current recipient evidence boundaries and completed verification.

### Brand, patterns, and review surfaces
- `brandbook/brand-book.md`, `brandbook/tokens.css`, and `brandbook/copy/microcopy.md` — current identity, values, and voice; these supersede older prompt drafts.
- `mailglass_admin/docs/design-system.md` — design guidance to reconcile.
- `mailglass_admin/assets/css/app.css` — shipped token mapping.
- `mailglass_admin/lib/mailglass_admin/gallery_live.ex` — Admin shared-pattern/state gallery.
- `reference/demo_app/dev/mailglass_demo_web/storybook.ex` and `reference/demo_app/storybook/` — demo-only curated Storybook.

### Evidence, assets, services, and CI
- `mailglass_admin/dev/mailglass_admin/preview/capture_manifest.ex` and `mailglass_admin/dev/mix/tasks/mailglass_admin.preview.capture.ex` — existing preview evidence contract.
- `reference/demo_app/assets/e2e/persona-screenshots.spec.js` and related Playwright specs — current browser capture and assertions.
- `scripts/run_demo_browser_evidence.sh` — demo browser evidence lifecycle and cleanup.
- `.github/workflows/ci.yml` — required `CI Green` and advisory evidence job topology.
- `scripts/gsd-regression-gate.sh` and `mailglass_admin/mix.exs` — focused checks and generated-asset verification.
- `README.md` and `reference/demo_app/README.md` — documented working preview.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `brandbook/tokens.css` is imported by Admin `app.css`; current app CSS defines the actual semantic mapping, while the Admin guide contains outdated mappings and typography claims.
- Admin Gallery already demonstrates the wider shared component/state/theme matrix. PhoenixStorybook is a dev-only dependency in the reference demo and uses the committed Admin stylesheet.
- Existing Playwright, browser capture, preview manifest/checkpoint, artifact upload, and asset drift checks cover most of the evidence path; add provenance and missing scenarios to these surfaces rather than replacing them.
- `mix verify.preview` and the existing browser asset proof can establish generated and served bundle identity when run against the candidate.

### Established Patterns
- Keep Phoenix/LiveView and HEEx as the implementation surface; keep demo-only dependencies in the demo app. Minimize dependency depth and avoid a shared abstraction until duplicate maintenance is demonstrated.
- Use DOM/accessibility/interaction and layout geometry assertions for observable behavior; use images for bounded visual comparison and artifacts, not as the sole regression gate.
- Report required checks and advisory browser/capture evidence separately. Historical scores and screenshots never substitute for current source-identified evidence.
- D-52 applies: automate machine-verifiable acceptance and reserve human review for irreducible judgment.

### Integration Points
- Admin CSS changes must update committed/generated assets and preserve the actual stylesheet served by the working demo.
- Browser evidence is tied to a running Compose/demo candidate; lifecycle isolation must preserve the user's feedback preview and unrelated containers.
- The final walkthrough connects current phase artifacts to the existing demo routes, checkout revision, served bundle, required CI result, and retained/cleaned services/artifacts.
- `git` and workspace status may include unrelated pre-existing user changes; scope commits and cleanup strictly to Phase 173 ownership.
</code_context>

<deferred>
## Deferred Ideas

- A generalized shared Storybook/Gallery catalog, moving one review surface into the other, or expanding the demo dependency boundary.
- Committed pixel-baseline enforcement or a new/promoted required visual CI lane.
- Paid visual judging, cross-browser matrix expansion without a concrete gap, or exhaustive viewport/theme/client combinations.
- Gmail/Outlook/Apple Mail certification and claims about delivered-message rendering.
- Automatic merge, branch-protection changes, package release/publication, or broad CI redesign.
- Changes to unrelated product flows or package contracts.
</deferred>

---

*Phase: 173-consistency-and-delivery-evidence*
*Context gathered: 2026-10-09*
