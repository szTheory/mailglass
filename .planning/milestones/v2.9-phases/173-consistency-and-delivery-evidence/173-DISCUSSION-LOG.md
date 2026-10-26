# Phase 173: Consistency and Delivery Evidence - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in `173-CONTEXT.md`; this log preserves the analysis and tradeoffs.

**Date:** 2026-10-09
**Phase:** 173-consistency-and-delivery-evidence
**Mode:** assumptions, autonomous recommendation synthesis
**Areas analyzed:** token and guidance ownership; Gallery and Storybook roles; reproducible visual evidence; delivery candidate and CI gates

## Assumptions Presented

### Token and guidance ownership
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| The brandbook owns identity/voice, `tokens.css` owns brand values, and Admin CSS maps them to component roles. Reconcile the Admin guide to the shipped mapping and remove obsolete rules. | Confident | `brandbook/brand-book.md`; `brandbook/tokens.css`; `mailglass_admin/assets/css/app.css`; `mailglass_admin/docs/design-system.md` |

### Gallery and Storybook roles
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| The Admin Gallery is the comprehensive state inventory; the demo-only PhoenixStorybook is a curated primitive explorer. Keep overlaps consistent without one-for-one duplication. | Likely | `mailglass_admin/lib/mailglass_admin/gallery_live.ex`; `reference/demo_app/storybook/`; `reference/demo_app/dev/mailglass_demo_web/storybook.ex`; `reference/demo_app/mix.exs` |

### Reproducible visual evidence
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Extend existing browser captures and manifests with candidate/source and served asset provenance, route, fixture, theme, viewport, state, before/after relation, and byte identity. Keep claims bounded to browser output. | Confident | `mailglass_admin/dev/mailglass_admin/preview/capture_manifest.ex`; Phase 171 rendered review; demo Playwright screenshot specs; `.planning/ROADMAP.md` acceptance rules |

### Delivery candidate and gates
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Use the existing demo as the working preview; run required CI and generated-asset drift checks; label existing browser/capture jobs as advisory; isolate Compose cleanup from the retained feedback preview. | Confident | `README.md`; `reference/demo_app/README.md`; `.github/workflows/ci.yml`; `mailglass_admin/mix.exs`; `scripts/run_demo_browser_evidence.sh`; `.planning/ROADMAP.md` |

## Corrections Made

No corrections. The user asked for autonomous, evidence-based synthesis and to follow recommendations without routine clarification. Phase scope, prior decisions, and current source resolved the routine choices.

## Auto-Resolved

- Kept Admin Gallery and demo PhoenixStorybook as complementary surfaces. Rejected one-for-one duplication because it increases drift and doesn't improve state coverage; rejected moving all coverage to Storybook because it is demo-only and would erode the Admin gallery's state matrix; rejected a shared specimen catalog because the duplication problem is not demonstrated and it adds a new abstraction across two rendering surfaces.
- Clarified ownership in existing brand and Admin docs instead of changing the token architecture or introducing a design-system package.
- Extended existing Playwright and manifest evidence rather than adding a pixel-testing dependency or mandatory CI lane. DOM, accessibility, interaction, and geometry checks remain the primary automation; screenshots provide bounded, inspectable rendered evidence.
- Preserved the distinction between required `CI Green` and advisory browser/capture jobs. No branch-protection change, merge, release, or publication is authorized by Phase 173.
- Required evidence-run isolation because the current demo browser script tears down the default Compose project. Evidence must use synthetic fixtures and identify the source/build/served asset bytes before making a provenance claim.
- Applied D-52 to close machine-observable acceptance through automation and limit owner review to any irreducible visual judgment or external delivery fact.

## Stakeholder and Adversarial Pass

- **Maintainer and product:** One clear source per concern reduces contradictory guidance and prevents the walkthrough from promising unsupported delivery behavior.
- **Design and accessibility:** Gallery covers applicable component states; Storybook remains easy to browse; interaction, keyboard, accessible semantics, and geometry checks complement screenshots.
- **Elixir/Phoenix architecture and DX:** Continue with LiveView/HEEx, existing demo-only PhoenixStorybook, current Playwright tooling, and current manifests. Avoid new runtime dependencies and cross-package specimen abstractions without proven reuse value.
- **QA and test engineering:** Link every capture to candidate, route, fixture, state, viewport, browser, assets, and baseline relationship; verify behavior with retrying semantic assertions rather than screenshot-only gates.
- **DevOps/SRE:** Do not conflate required with advisory checks. Keep evidence service lifecycle scoped to an isolated Compose project and make artifact retention explicit.
- **Security/privacy:** Use synthetic message data; do not retain real recipient content. Cleanup cannot stop the feedback-preview service. A hash does not prove rendering semantics or client compatibility.
- **Evidence integrity:** Identify the exact source and generated/served assets, distinguish current renders from historical scores, and never infer delivery-client support from Chromium output.

## External Research

- PhoenixStorybook's setup and component guides support a curated component/story surface and show the stylesheet setup costs of mirroring styling; Phoenix LiveView owns rendering through LiveView callbacks. This supports the existing package/surface split. [Setup](https://github.com/phenixdigital/phoenix_storybook/blob/main/guides/setup.md), [component variations](https://github.com/phenixdigital/phoenix_storybook/blob/main/guides/components.md), [LiveView render/1](https://phoenix-live-view.hexdocs.pm/Phoenix.LiveView.html#render/1).
- Playwright distinguishes screenshot snapshot comparison from web-first assertions; use both according to what they prove, without claiming snapshots validate interactive or accessible behavior. [Screenshot snapshots](https://playwright.dev/docs/test-snapshots), [web assertions](https://playwright.dev/docs/test-assertions).
- GitHub documents required protected-branch status checks separately from workflow artifact storage and retention. This supports reporting blocking CI and retained evidence as distinct signals. [Protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches), [workflow artifacts](https://docs.github.com/en/actions/tutorials/store-and-share-data).
- No ecosystem finding justified adding a dependency, test framework, visual judge, or required CI job. Live candidate CI, branch-protection state, and served preview identity remain delivery-time facts and must be checked at that time.

---

*Phase: 173-consistency-and-delivery-evidence*
*Discussion captured: 2026-10-09*
