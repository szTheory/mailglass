# Phase 171: Developer Preview - Discussion Log (Assumptions Mode)

> **Audit trail only.** Decisions captured in 171-CONTEXT.md. This log preserves the analysis and source trail; downstream planning should use CONTEXT.md.

**Date:** 2026-10-09
**Phase:** 171-developer-preview
**Mode:** assumptions, expanded recommendation synthesis at the owner's request
**Areas analyzed:** scenario discovery and author recovery; LiveView editing and input fidelity; rendering/output truth; accessibility and responsive design; security and host boundary; shift-left verification and dependency posture.

## Assumptions Presented and Evidence

### Scenario discovery and author orientation
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Keep the existing Mailable/preview_props scenario contract and improve orientation/empty setup states within the existing picker. | Confident | mailglass_admin/lib/mailglass_admin/preview/discovery.ex; mailglass_admin/lib/mailglass_admin/preview/sidebar.ex; mailglass_admin/lib/mailglass_admin/preview_live.ex; Phase 171 requirements |
| Fix the preview guide example to match the supported named-scenario assigns map. | Confident | guides/preview.md; lib/mailglass/mailable.ex; reference/demo_app/lib/mailglass_demo_web/mailers/account_mailer.ex |

### Live editing and failure recovery
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Retain live-on-change feedback but keep the editor available on error and distinguish the last successful output from the failed attempt. | Confident | mailglass_admin/lib/mailglass_admin/preview_live.ex retains output assigns but replaces the scenario view with an error branch; mailglass_admin/test/mailglass_admin/preview_live_test.exs asserts live change behavior |
| Edit only values that can be parsed without losing type or semantics; do not call inspect output JSON. | Confident | mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex field rendering; mailglass_admin/lib/mailglass_admin/preview_live.ex merge/coercion; no matching decoder for submitted map/struct strings |

### Rendering and output truth
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Use Mailglass.Renderer for HTML/text, but do not claim the view is the exact provider-bound message. | Confident | mailglass_admin/lib/mailglass_admin/preview_live.ex calls Renderer.render; lib/mailglass/outbound/preflight.ex performs additional preparation |
| Keep Raw as a best-effort preview envelope and label generated headers. | Confident | mailglass_admin/lib/mailglass_admin/preview_live.ex constructs a fixed-boundary MIME-shaped string and synthetic Message-ID/Date values |

### Accessibility, visual design, security, and validation
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Complete the horizontal tab keyboard/focus pattern and preserve valid panel relationships. | Confident | mailglass_admin/lib/mailglass_admin/preview/tabs.ex; official W3C APG Tabs and WAI-ARIA 1.2 guidance |
| Keep the current compact picker, 168 responsive/theme/accessibility contract, and brand system. | Confident | preview/sidebar.ex; Phase 168 UI-SPEC; current brandbook and design-system.md |
| Preserve the adopter-owned dev-only mount boundary and do not claim sandboxing blocks scripts/resources beyond its actual permissions. | Confident | router.ex, preview/mount.ex, tabs.ex, README.md; Phoenix LiveView security guide and MDN iframe/srcdoc references |
| Automate observable behavior in current suites and report CI gating honestly. | Confident | preview_live_test.exs; .github/workflows/ci.yml; Phase 170 validation report; D-52 |

## Corrections Made

No individual assumption was corrected. The owner requested broader cross-discipline/source research and directed that the synthesized recommendation set be followed. Final decisions are consolidated in 171-CONTEXT.md.

## External Research

- **W3C APG Tabs and manual activation:** one tab stop, arrow-key movement, focus/selection semantics, and manual activation where automatic panel switching could have noticeable latency. The APG is informative; WCAG keyboard access and WAI-ARIA role relationships are normative. https://www.w3.org/WAI/ARIA/apg/patterns/tabs/ ; https://www.w3.org/TR/wai-aria/#tab ; https://www.w3.org/TR/wai-aria/#tablist
- **WCAG 2.2:** keyboard access/no trap, reflow, target size, and status-message guidance. https://www.w3.org/WAI/WCAG22/quickref/
- **Phoenix LiveView 1.1.33:** event/process behavior, form bindings, and the security model. https://hexdocs.pm/phoenix_live_view/1.1.33/Phoenix.LiveView.html ; https://phoenix-live-view.hexdocs.pm/form-bindings.html ; https://phoenix-live-view.hexdocs.pm/security-model.html
- **Swoosh and Rails:** Swoosh.Email fields and named Action Mailer previews were reviewed as primary ecosystem references; Rails' separate preview classes are not adopted. https://swoosh.hexdocs.pm/Swoosh.Email.html ; https://guides.rubyonrails.org/action_mailer_basics.html#previewing-emails
- **MDN iframe/srcdoc:** sandbox permission and external resource limits were checked. https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/iframe ; https://developer.mozilla.org/en-US/docs/Web/API/HTMLIFrameElement/srcdoc

## Cross-Discipline Synthesis

- **Author/product:** keep named scenarios and fast feedback; make setup and selected state obvious and keep a correction path after failures.
- **Phoenix/Elixir architecture:** reuse Mailable, LiveView, function components, and the core Renderer; avoid a new schema or dependency.
- **Rendering/trust:** distinguish renderer output, illustrative envelope/header values, outbound preflight, and recipient delivery.
- **Accessibility/design:** use conventional keyboard tabs, valid focus/ARIA relationships, readable long content, narrow reflow, current brand tokens, and no color-only states.
- **Security:** rely on the documented host dev-route guard; use synthetic data; preserve script-disabled sandboxing without claiming sanitization or network blocking.
- **DevOps/verification:** add deterministic seam/browser assertions only for demonstrated gaps; keep browser/capture checks advisory as currently configured and do not turn their green state into merge-gating proof.

No app boot, live visual inspection, test run, implementation change, or CI run was performed during discussion.
