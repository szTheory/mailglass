---
phase: 172-recipient-output-and-built-in-pages
verified: 2026-10-09T23:21:06Z
status: passed
score: 9/9 must-haves verified
covered_files:
  - .planning/phases/172-recipient-output-and-built-in-pages/172-01-PLAN.md
  - .planning/phases/172-recipient-output-and-built-in-pages/172-01-SUMMARY.md
  - .planning/phases/172-recipient-output-and-built-in-pages/172-02-PLAN.md
  - .planning/phases/172-recipient-output-and-built-in-pages/172-02-SUMMARY.md
  - .planning/phases/172-recipient-output-and-built-in-pages/172-03-PLAN.md
  - .planning/phases/172-recipient-output-and-built-in-pages/172-03-SUMMARY.md
  - .planning/phases/172-recipient-output-and-built-in-pages/172-REVIEW.md
  - .planning/phases/172-recipient-output-and-built-in-pages/172-SECURITY.md
  - .planning/phases/172-recipient-output-and-built-in-pages/172-UI-REVIEW.md
  - .planning/phases/172-recipient-output-and-built-in-pages/172-VALIDATION.md
  - .planning/phases/172-recipient-output-and-built-in-pages/artifacts/browser-evidence/invoice-preview-320.png
  - .planning/phases/172-recipient-output-and-built-in-pages/artifacts/browser-evidence/invoice-preview-375.png
  - .planning/phases/172-recipient-output-and-built-in-pages/artifacts/browser-evidence/unsubscribe-expired-1280.png
  - .planning/phases/172-recipient-output-and-built-in-pages/artifacts/browser-evidence/unsubscribe-expired-320.png
  - .planning/phases/172-recipient-output-and-built-in-pages/artifacts/browser-evidence/unsubscribe-invalid-1280.png
  - .planning/phases/172-recipient-output-and-built-in-pages/artifacts/browser-evidence/unsubscribe-invalid-320.png
  - .planning/phases/172-recipient-output-and-built-in-pages/artifacts/browser-evidence/unsubscribe-valid-1280.png
  - .planning/phases/172-recipient-output-and-built-in-pages/artifacts/browser-evidence/unsubscribe-valid-320.png
  - guides/authoring-mailables.md
  - guides/b2c-first-adopter.md
  - guides/getting-started.md
  - guides/jobs.md
  - guides/migration-from-swoosh.md
  - guides/unsubscribe.md
  - lib/mailglass/compliance/unsubscribe_controller.ex
  - lib/mailglass/compliance/unsubscribe_html/state.html.heex
  - lib/mailglass/components.ex
  - lib/mailglass/components/theme.ex
  - lib/mailglass/config.ex
  - lib/mailglass/renderer.ex
  - reference/demo_app/assets/e2e/demo.spec.js
  - reference/demo_app/lib/mailglass_demo_web/controllers/page_controller.ex
  - reference/demo_app/lib/mailglass_demo_web/mailers/component_mailer.ex
  - reference/demo_app/lib/mailglass_demo_web/router.ex
  - reference/demo_app/test/mailglass_demo/mailer_preview_scenarios_test.exs
  - test/mailglass/compliance/unsubscribe_controller_test.exs
  - test/mailglass/components/button_test.exs
  - test/mailglass/components/content_test.exs
  - test/mailglass/config_test.exs
  - test/mailglass/docs/unsubscribe_guide_test.exs
  - test/mailglass/docs_contract_test.exs
  - test/mailglass/renderer_test.exs
covered_digest: "v3:sha256:eeb5f348fa25659f8566364d431147bff8d6d9b70f3a166a5619f27e7ef8ee80"
behavior_unverified: 0
overrides_applied: 0
decision_coverage:
  honored: 11
  total: 11
  not_honored: []
---

# Phase 172: Recipient Output and Built-in Pages Verification Report

**Phase Goal:** Authors can produce readable supported transactional output, and recipients can understand its content and the existing unsubscribe page's actual state.
**Verified:** 2026-10-09T23:21:06Z
**Status:** passed
**Re-verification:** No — the earlier report had a human-verification item but no `gaps:` section. This pass rechecked the roadmap and plans, current implementation, and the new screenshot evidence.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | Public components produce a coherent live-text heading/body/action hierarchy, long and non-ASCII content, fluid narrow layout, useful link wrapping, and image-fallback context. | ✓ VERIFIED | `component_mailer.ex` keeps invoice meaning and amount in live text alongside the image and describes the image with alt text. The 375px and 320px email-only captures show the hierarchy and fallback explanation; `demo.spec.js` asserts it remains ordered and the iframe has no horizontal overflow. Component tests cover escaping, long content, links, alt text, widths, and styling. |
| 2 | Email-specific support survives: HEEx escaping, adopter theme resolution, inline styles, presentation tables, MSO/VML and HTML fallback. | ✓ VERIFIED | Current `components.ex`, `components/theme.ex`, and `config.ex` retain those paths. Component, theme/config, row, and VML preservation tests are recorded passing; the browser assertion checks the final presentation table, width fallback, and VML output. |
| 3 | Evaluators can inspect a registered AtlasDesk-branded public-component Mailable beside the separate bespoke AtlasDesk scenarios, with the authoring paths distinguishable. | ✓ VERIFIED | `router.ex` registers `ComponentMailer` beside Account/Billing/Operations. The Mailable uses HEEx components and the same AtlasDesk sender; the demo test renders and distinguishes it from the bespoke helper. The 375px/320px preview evidence captures the component output. |
| 4 | Generated plaintext preserves readable heading/paragraph order, action context, useful destinations, Unicode, image alternatives, and nested/ordinary links. | ✓ VERIFIED | `renderer.ex` walks the logical pre-inliner HTML, handles ordinary anchors and image alternatives, and normalizes output. The renderer tests include ordered Unicode content, link destinations, image alt, nested/unmarked anchors, and generated-text replacement. The focused renderer suite is recorded passing. |
| 5 | Marked links include a useful destination once, and empty or destination-free anchors do not invent action text. | ✓ VERIFIED | `renderer.ex` separates `link_pair` from default anchor handling; `renderer_test.exs` asserts exact-once marked destinations and empty/destination-free anchors. Focused renderer tests are recorded passing. |
| 6 | The renderer still owns generated `text_body`, extracts before CSS inlining, and strips internal markers from final HTML. | ✓ VERIFIED | `Renderer.render/2` calls `to_plaintext/1` on rendered HTML before `inline_css/1`, then strips `data-mg-*` and assigns the generated value to `text_body`. Tests cover replacement and marker removal; the focused renderer suite is recorded passing. |
| 7 | A valid built-in unsubscribe GET truthfully states it did not unsubscribe the recipient and offers only supported next steps without mutating state. | ✓ VERIFIED | Controller GET renders the valid state template and has no event-write call; POST calls `append_unsubscribe_event/1`. The named controller test checks event and suppression counts before and after GET. The valid desktop and 320px captures show the read-only explanation and supported next steps. |
| 8 | Invalid and expired GETs show distinct private recovery pages with 404/410, while configured GET redirects and the existing POST response, event, and replay idempotency remain intact. | ✓ VERIFIED | Controller dispatch keeps 404/410 separate and the valid GET redirect configuration intact; tests cover privacy, status, redirect, POST event, and replay behavior. Distinct invalid/expired states are visible in desktop and 320px screenshots. Focused controller tests are recorded passing. |
| 9 | The actual embedded unsubscribe pages are semantic and readable at required narrow and zoom-equivalent widths, with browser evidence using fixed synthetic state. | ✓ VERIFIED | `PageController` accepts only valid/invalid/expired state paths, supplies a synthetic recipient only for valid state, and renders the embedded template. Playwright checks all three states at 320px and 160px and captures them at 1280px/320px. `state.html.heex` has a semantic document, viewport metadata, wrapped headings/copy, and distinct explicit state text. |

**Score:** 9/9 truths verified (0 present, behavior-unverified)

### Why the prior human-verification item is closed

The earlier item was limited to visual inspection because screenshots were missing. That evidence gap is now closed: the stored images are present at the stated dimensions, and direct inspection shows the invoice's heading, live copy, image, fallback explanation, CTA, and secondary link remain readable at 375px and 320px. The valid, invalid, and expired pages each show distinct copy at 1280px and 320px without visible clipping or overlap. The fresh UI review documents its inspection of these same artifacts and scores 24/24. The changed Playwright path also asserts iframe width, image-to-copy and block spacing, and CTA size (at least 44px and no more than 52px high). The phase validation records the focused browser checks passing 2/2.

This closes the browser-output review without owner UAT, consistent with the phase validation contract. It does not establish Gmail, Outlook, Apple Mail, delivered-email, image-blocking, or recipient-client dark-mode rendering.

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `reference/demo_app/lib/mailglass_demo_web/mailers/component_mailer.ex` | Registered branded public-component Mailable | ✓ VERIFIED | Substantive invoice example; escaped HEEx values, live text, CTA, secondary link, useful image alt and fallback copy. |
| `lib/mailglass/components.ex` | Fluid, escaped, email-safe components | ✓ VERIFIED | Real component implementations retain presentation tables, inline styles, theme resolution, plaintext markers, and VML fallback. |
| `reference/demo_app/test/mailglass_demo/mailer_preview_scenarios_test.exs` | Sender, render, and authoring-path proof | ✓ VERIFIED | Integration assertions render the public-component path and compare it with the bespoke AtlasDesk path. |
| `test/mailglass/components/content_test.exs` | Semantics, fallback, escaping, and width contracts | ✓ VERIFIED | Assertions cover long/non-ASCII content, alt, escaping, and fluid widths. |
| `reference/demo_app/assets/e2e/demo.spec.js` | Connected browser preview and unsubscribe checks | ✓ VERIFIED | Current path asserts source identities, output content, iframe geometry, CTA bounds, spacing, overflow and screenshots. |
| `lib/mailglass/renderer.ex` | Link-aware plaintext walker and render pipeline | ✓ VERIFIED | Substantive walker handles marked/unmarked/nested links and images; render assigns generated plaintext before final HTML cleanup. |
| `test/mailglass/renderer_test.exs` | Plaintext content and compatibility assertions | ✓ VERIFIED | Exact destinations, ordering, Unicode, alt, replacement, and marker assertions. |
| `lib/mailglass/compliance/unsubscribe_html/state.html.heex` | Shared semantic state page | ✓ VERIFIED | Escaped recipient, truthful state-specific copy, responsive wrapping, semantic document shell. |
| `lib/mailglass/compliance/unsubscribe_controller.ex` | GET state routing and unchanged POST mutation path | ✓ VERIFIED | Valid GET read-only page; invalid/expired recovery responses; configured redirect and POST event/idempotency paths preserved. |
| `test/mailglass/compliance/unsubscribe_controller_test.exs` | Status, privacy, no-mutation, redirect and POST proof | ✓ VERIFIED | Assertions cover both GET no-mutation and POST/replay behavior. |
| `artifacts/browser-evidence/*` | Current visual captures for output and page states | ✓ VERIFIED | Eight non-empty PNG captures exist at the required invoice and unsubscribe dimensions and were inspected. |

All listed plan artifacts passed `query verify.artifacts` (14/14 across the three plans). The generic key-link query reported text-match misses for Elixir/HEEx relationships; manual source tracing below verifies the connections.

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `reference/demo_app/lib/mailglass_demo_web/router.ex` | `ComponentMailer` | Development preview Mailable registry | WIRED | The router's mailables list registers `ComponentMailer`. |
| `ComponentMailer` | `Mailglass.Components` | HEEx function component and Mailable macro import | WIRED | `use Mailglass.Mailable` imports components; the example's HEEx body calls `container`, `section`, `heading`, `text`, `img`, `button`, and `link`. Preview tests render the result through `Mailglass.Renderer`. |
| `lib/mailglass/components.ex` | `lib/mailglass/renderer.ex` | Plaintext markers and logical HTML | WIRED | Component markers are consumed by renderer strategy clauses; rendered tests assert extracted plaintext and stripped markers. |
| `lib/mailglass/renderer.ex` | `Message.swoosh_email.text_body` | Assignment in `render/2` | WIRED | `render/2` assigns the result of `to_plaintext/1` into the returned Swoosh email. |
| `unsubscribe_controller.ex` | `unsubscribe_html/state.html.heex` | `UnsubscribeHTML` embedded view and explicit state assigns | WIRED | Valid GET uses `render(:state, state: :valid, recipient: ...)`; failures render their state without recipient/token assigns. |
| `unsubscribe_controller.ex` | Events and Compliance | POST-only durable mutation and idempotent path | WIRED | Only POST calls `append_unsubscribe_event/1`; its event and replay path remain covered by controller tests. |
| `PageController` | `UnsubscribeHTML.state/1` | Fixed-state synthetic demo route | WIRED | Route has only three fixed states and renders the actual embedded template; no delivery lookup occurs. |

### Data-Flow Trace (Level 4)

| Artifact | Data variable | Source | Produces real data | Status |
|---|---|---|---|---|
| `ComponentMailer.invoice_ready/1` | recipient, invoice, workspace, amount | Deterministic named `preview_props/0` fixture used by the registered preview | Yes; non-empty synthetic values flow into HEEx and the renderer. | ✓ FLOWING |
| `Mailglass.Renderer` | `html_body`, `text_body` | HEEx output and Floki traversal of rendered HTML | Yes; actual copy, alternatives, and href destinations are extracted and assigned. | ✓ FLOWING |
| Unsubscribe state template | state, recipient | Verified delivery for valid controller GET; fixed error-state atoms for invalid/expired | Yes; valid recipient is escaped; error states receive no recipient/token. | ✓ FLOWING |
| Demo unsubscribe evidence route | state, recipient | Fixed route segment and `.example.test` synthetic recipient | Yes for template evidence; isolated from actual delivery state. | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command/evidence | Result | Status |
|---|---|---|---|
| Generated text retains ordered Unicode, links and image alt while replacing caller text | Named renderer test `render replaces caller text with complete ordered Unicode plaintext`; focused renderer suite | Recorded pass in the previous verification and current validation history. | ✓ PASS |
| Valid GET does not mutate state and POST replay stays idempotent | Named controller tests for valid GET no mutation and replay; focused controller suite | Recorded pass; GET compares event/suppression counts, replay checks durable event count. | ✓ PASS |
| Registered public Mailable renders alongside the bespoke authoring path | `mailer_preview_scenarios_test.exs` focused suite | Current phase summary records 11/11 passing. | ✓ PASS |
| Current component preview and unsubscribe states render at target widths | Focused Playwright tests for invoice preview and unsubscribe states | Current validation records 2/2 passing; screenshots and exact browser assertions inspected. | ✓ PASS |
| Required regression gate | `bash scripts/gsd-regression-gate.sh` | Current validation records core 79, Admin 593 (1 excluded), inbound 3 properties + 480 (3 excluded), connected browser 30; all passed. | ✓ PASS |
| Mailable preview suite | Focused demo Mailable suite | Current validation records 11/11 passing. | ✓ PASS |

The full advisory demo browser lane previously reported two unrelated existing failures (Helios empty-state heading and inbound detail header). These are outside the phase paths and are not blockers; focused changed-path checks and the required regression gate pass.

### Probe Execution

No migration/tooling probe is declared or applicable to this phase.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| MAILUX-01 | 172-01 | Public components produce readable transactional output while preserving email-specific markup support. | ✓ SATISFIED | Source, component contracts, browser assertions, and inspected 375/320px captures verify hierarchy, content, CTA, alt/fallback, and fluid output. |
| MAILUX-02 | 172-01 | Sender-branded examples demonstrate both authoring paths accurately. | ✓ SATISFIED | Registered Mailable, router list, renderer integration test, and browser preview distinguish public components from bespoke AtlasDesk HTML. |
| MAILUX-03 | 172-02 | Plaintext retains message meaning, essential action, and meaningful links. | ✓ SATISFIED | Renderer source/tests and guide contracts cover order, destinations, Unicode, image alternatives, and generated `text_body`. |
| MAILUX-04 | 172-03 | Built-in unsubscribe states are truthful/readable and preserve redirects and POST protocol behavior. | ✓ SATISFIED | Controller tests, embedded template, updated guide, and inspected screenshots verify states; status/redirect/no-mutation/POST coverage remains wired. |

No additional requirements are mapped to Phase 172 outside these four. Phase 173 does not defer any uncovered phase-172 item. Decision coverage check honored 11/11 trackable CONTEXT decisions.

### Test Quality Audit

| Test File | Linked Requirement | Active | Skipped | Circular | Assertion Level | Verdict |
|---|---|---:|---:|---|---|---|
| `test/mailglass/components/content_test.exs`, `button_test.exs`, `vml_preservation_test.exs` | MAILUX-01 | Yes | No linked disabled tests found | No writer/import cycle found | Rendered value and markup | Adequate |
| `reference/demo_app/test/mailglass_demo/mailer_preview_scenarios_test.exs` | MAILUX-02 | Yes | No linked disabled tests found | No writer/import cycle found | Rendered behavior | Adequate |
| `test/mailglass/renderer_test.exs`, `test/mailglass/docs_contract_test.exs` | MAILUX-03 | Yes | No linked disabled tests found | No writer/import cycle found | Value and behavior | Adequate |
| `test/mailglass/compliance/unsubscribe_controller_test.exs`, `test/mailglass/docs/unsubscribe_guide_test.exs` | MAILUX-04 | Yes | No linked disabled tests found | No writer/import cycle found | Status, state, and mutation behavior | Adequate |

One unrelated historical Phase 38 release-proof test remains skipped in the documentation contract suite; no Phase 172 requirement relies on it. No circular expected-value generation or insufficient assertion-only coverage was found.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| — | — | No blocking debt marker or implementation stub found in the phase's changed source/test files. The `JTBD` matches in documentation tests are domain terms, not TODO markers. | — | — |

### Decision Coverage

All 11 trackable decisions in `172-CONTEXT.md` are honored by the plans, implementation, and evidence. The coverage check is advisory and does not affect status.

### Human Verification Required

None. The previous visual item is closed by current screenshot artifacts, direct visual inspection recorded by the fresh 24/24 UI review, and the current automated geometry checks. Recipient-client rendering remains outside this phase's verification claim.

### Gaps Summary

No must-have gaps remain. All nine merged roadmap/plan truths are verified, all plan artifacts pass existence/substance checks, key links are manually confirmed despite unsupported generic matcher misses, and data flows reach rendered output. The saved visual evidence and fresh UI review resolve the earlier missing-screenshot item without owner UAT, as the phase's validation contract allows. No Gmail/Outlook/Apple Mail rendering is claimed.

---

_Verified: 2026-10-09T23:21:06Z_  
_Verifier: the agent (gsd-verifier)_
