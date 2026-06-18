# Phase 100: Preview Surface - Context

**Gathered:** 2026-06-15 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 100 uplifts the existing `mailglass_admin` Preview surface at `/dev/mail`.
The work brings the Preview page, groups, responsive behavior, flow validation,
and accessibility up to the same cross-surface bar already applied to Operator
and Inbound. The headline requirement is full dark-mode support for the Preview
chrome at parity with Operator and Inbound, while the previewed Message frame
keeps its own independent theme/chrome state.

This phase does not add a product feature, public API, production operator route,
provider behavior, core email-template component change, or brandbook change. The
work stays inside `mailglass_admin` Preview UI code, tests, audit capture wiring,
and the committed CSS bundle required by class changes.
</domain>

<decisions>
## Implementation Decisions

### Scope / Surface Contract

- **D-01:** Build on the existing `MailglassAdmin.PreviewLive` mounted by
  `mailglass_admin_routes/2` at `/dev/mail` plus the existing
  `mailglass_admin/lib/mailglass_admin/preview/*` components. Do not add a
  sibling LiveView, new route, production operator surface, auth path, public API,
  or core `mailglass` recipient-facing email component change.
- **D-02:** Treat Phase 97 Preview component work as settled. `DeviceFrame`,
  `Tabs`, `Sidebar`, and shared `orientation_strip` should be composed into the
  page-level Preview IA instead of being re-uplifted from scratch. Fix only the
  component details that are necessary for Phase 100 acceptance, such as touch
  target parity, mobile reachability, group hooks, and dark-mode inheritance.

### Dark-Mode Model

- **D-03:** `?theme=dark|light` is the Preview **admin chrome** theme, matching
  Operator and Inbound URL-state semantics. Preview must apply this theme on both
  `:index` and `:show` routes; the current show-route behavior is insufficient
  because the audit script captures `/dev/mail/?theme=dark` as a Preview cell.
- **D-04:** Do not conflate admin chrome dark mode with the previewed Message's
  own dark/frame state. If implementation needs a separate previewed-message
  theme or frame toggle, it must use a distinct assign/param name and affect only
  the preview pane/frame, not the sidebar, page background, form controls, or
  route shell. The admin chrome state continues to drive the page-level
  `data-theme`.
- **D-05:** Fix the root-layout and inner-wrapper theme interaction so there is
  no split-brain state. `root.html.heex` currently falls back to
  `mailglass-light` when no root `:dark_chrome` assign exists, and
  `PreviewLive` currently assigns `dark_chrome: false` on mount. Phase 100 must
  ensure explicit `?theme=dark` produces a dark root/page, and OS dark preference
  is not defeated by an unconditional light theme when no explicit theme param is
  present. Prefer the CSS/daisyUI `prefersdark: true` path over a client JS hook.
- **D-06:** No child Preview component may set its own unrelated `data-theme`
  wrapper. Children inherit the page-level admin chrome theme unless they are
  explicitly rendering the independent previewed-message/frame theme from D-04.

### Responsive IA / Group Composition

- **D-07:** Preserve `Preview.Sidebar`'s native `<details>/<summary>` mailable to
  scenario hierarchy from `IA-LD-08`. Do not replace it with a flat list or custom
  JavaScript accordion.
- **D-08:** Make the Mailables/scenario navigation reachable at 390px. The current
  sidebar is `hidden md:block`, so mobile Preview cannot complete the
  preview-a-message-before-send JTBD. Add a mobile-first disclosure, inline panel,
  or equivalent responsive placement that reuses the same sidebar semantics and
  links. Avoid a new route; use CSS and LiveView.JS only if interaction is needed.
- **D-09:** Add stable Preview group test ids following the existing kebab pattern
  so the structural layer can assert the page shape without pixel diffing. At
  minimum, cover the Preview shell/root, mobile Mailables navigation, start/empty
  state, header controls, assigns form, tab strip, and preview pane.
- **D-10:** The Preview page should use the same token rhythm as Phases 98 and 99:
  outer page padding on `px-md/py-lg` to `md:px-lg/md:py-xl`, inter-group
  `gap-lg`, in-group `gap-md/gap-sm`, flat elevation (`bg-base-200 border
  border-base-300 rounded-box`), semantic tokens only, and no arbitrary spacing,
  raw hex, or off-scale type.

### Preview Copy / Empty / Touch States

- **D-11:** Apply the Preview-specific Phase 96 copy locks now:
  - Start heading: "Render a real Message before you send it" (`COPY-LD-04`).
  - Start sub-copy: "Pick a Mailable from the sidebar to render it through the
    same pipeline your production sends use." (`COPY-LD-04`).
  - Start CTA: "Preview the first Mailable" (`COPY-LD-05`).
  - No-Mailables heading/sub-copy: "No Mailables discovered" and the locked
    `COPY-LD-06` explanation.
  This is not the global Phase 101 copy pass; it is the Preview requirement work
  already named by `COPY-LD-04..06` and `GAP-02`.
- **D-12:** Close `GAP-02` by ensuring the Preview index is keyboard-actionable in
  both branches. When mailables exist, render the first-previewable CTA as a
  real focusable link. When no Mailables exist, keep a real focusable setup/help
  action; do not render a bogus first-Mailable link when no previewable target
  exists. All CTA controls need visible focus rings and `min-h-11` or equivalent
  44px touch target.
- **D-13:** Bring Preview action controls up to the same touch-target floor:
  the header theme button and `AssignsForm` action buttons should use `min-h-11`
  or drop `btn-sm` where compiled CSS proves it suppresses the 44px floor. This
  mirrors the Phase 97 resolution for `DeviceFrame` and `theme_toggle`.
- **D-14:** Keep explicit loading UI out of scope unless implementation adopts
  async assigns. Preview discovery and rendering are synchronous today; adding
  loading skeletons belongs to Phase 102 unless needed to represent a real async
  state introduced by Phase 100.

### Verification / Ratchet Integration

- **D-15:** Extend existing ExUnit and Playwright lanes rather than adding a new
  harness. Direct `/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default`
  scenario URLs are already available in the synthetic test router; use them for
  real Preview JTBD coverage instead of relying only on `/ops/browser-preview-empty`.
- **D-16:** Structural browser coverage for Preview must include light and dark
  themes at 390, 768, and 1440 widths; exactly one `h1`; mobile Mailables
  navigation; scenario selection; header controls; assigns form; tab/pane
  visibility; focus rings; >=44px target checks for primary controls; and WCAG AA
  text/non-text contrast on real Preview groups.
- **D-17:** Update `mailglass_admin/scripts/ui-audit.sh` so its Preview comments
  and capture behavior no longer document dark mode as absent. The `preview-*-dark`
  cells must use a URL with `?theme=dark` and produce visibly dark Preview chrome
  (Ink background, Ice accent, Mist text), distinct from `preview-*-light`.
- **D-18:** Rebuild and commit `mailglass_admin/priv/static/app.css` after any
  class changes. `mix verify.preview` includes the bundle-clean gate, so an
  uncommitted CSS rebuild is a CI failure.

### Codex's Discretion

- Exact internal assign names for separating admin chrome theme from previewed
  Message/frame theme, provided `?theme=` remains admin chrome and the two states
  do not couple.
- Exact mobile placement for Mailables navigation, provided the native
  `<details>/<summary>` hierarchy remains the core IA and the navigation is
  reachable at 390px.
- Exact set of `data-testid` names, provided they follow the Preview kebab
  convention and cover the groups named in D-09.
- Exact Playwright assertion layout, provided D-16 is covered in the existing
  `operator_browser_gate` lane.

### Folded Todos

None folded into Phase 100.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md` - Phase 100 goal and success criteria.
- `.planning/REQUIREMENTS.md` - PAGE-03 plus the cross-cutting GROUP/PAGE/RESP/FLOW/A11Y requirements re-applied to Preview.
- `.planning/STATE.md` - v1.11 scope locks, hard design constraints, and current Phase 100 position.
- `.planning/METHODOLOGY.md` - decisive-by-default and recommendation-first synthesis posture.
- `.planning/research/v1.11/SUMMARY.md` - canonical locked decisions: `MOTION-LD-12`, `IA-LD-07`, `IA-LD-08`, `STATE-LD-20..22`, `DARK-LD-06`, `DARK-LD-08`, `COPY-LD-04..06`.
- `.planning/RATCHET-GAP-REGISTER.md` - `GAP-02` and `GAP-03` are Preview sev-3 rows that Phase 100 must close or materially advance.
- `.planning/phases/97-cross-surface-component-layer/97-CONTEXT.md` - settled Preview component work and gallery/test conventions.
- `.planning/phases/98-operator-deliveries-surface/98-CONTEXT.md` - responsive/group/test pattern for the first per-surface uplift.
- `.planning/phases/99-inbound-surface/99-CONTEXT.md` - second per-surface application of the responsive/group/test pattern.
- `mailglass_admin/lib/mailglass_admin/preview_live.ex` - Preview page, URL state, theme state, render branches, and current start/empty/scenario layout.
- `mailglass_admin/lib/mailglass_admin/preview/sidebar.ex` - native mailable/scenario details hierarchy to preserve and make mobile-reachable.
- `mailglass_admin/lib/mailglass_admin/preview/device_frame.ex` - device segmented control, already partially resolved by Phase 97.
- `mailglass_admin/lib/mailglass_admin/preview/tabs.ex` - Preview tab strip and pane rendering.
- `mailglass_admin/lib/mailglass_admin/preview/assigns_form.ex` - assigns form and action buttons needing touch-target parity.
- `mailglass_admin/lib/mailglass_admin/operator/shell.ex` - shared orientation strip and existing theme-toggle/touch-target patterns.
- `mailglass_admin/lib/mailglass_admin/layouts/root.html.heex` - root `data-theme` fallback that must not force light against Preview dark/OS-dark behavior.
- `mailglass_admin/e2e/structural.spec.js` - structural assertions to extend for real Preview scenario coverage.
- `mailglass_admin/test/mailglass_admin/preview_live_test.exs` - existing ExUnit Preview URL/theme/toggle/assigns tests to update.
- `mailglass_admin/test/support/endpoint_case.ex` - synthetic router/session helpers, including `/ops/browser-preview-empty`.
- `mailglass_admin/test/support/fixtures/mailables.ex` - deterministic fixture Mailables for Preview scenario tests.
- `mailglass_admin/dev/mailglass_admin/preview/capture_matrix.ex` and `mailglass_admin/dev/mailglass_admin/preview/capture_state.ex` - existing deterministic preview scenario/width/theme URL matrix.
- `mailglass_admin/scripts/ui-audit.sh` - 18-cell audit matrix that must stop documenting Preview dark as absent.
- `mailglass_admin/mix.exs` - `verify.preview` bundle-clean gate.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `MailglassAdmin.PreviewLive` already owns mailable discovery, scenario URL
  state, `width=` and `theme=` params on scenario routes, device selection,
  dark toggle, tab state, assigns editing, and render error handling.
- `Preview.Sidebar` already renders the locked `<details>/<summary>` hierarchy
  and scenario links with theme/width query params.
- `Preview.DeviceFrame` and `Preview.Tabs` already implement much of
  `STATE-LD-20..22`: ARIA pressed/selected state, tabpanels, focus rings, and
  empty HTML placeholder.
- `CaptureMatrix` / `CaptureState` already generate deterministic URLs for
  `width in [375, 768, 1024]` and `theme in [:light, :dark]`; no new screenshot
  model is needed for Preview scenario URLs.
- The test router already mounts fixture Mailables at `/dev/mail`, so structural
  browser tests can navigate directly to real Preview scenario URLs.

### Established Patterns

- Route state is URL state. Operator and Inbound use `?theme=dark`; Preview
  should align with that instead of introducing a separate admin-theme route
  mechanism.
- Responsive surface work should follow the Phase 98/99 pattern: semantic tokens,
  stable `data-testid` hooks, Playwright structure assertions, and no new route.
- The UI ratchet uses structural assertions and LLM-score PNG cells, not
  pixel-diff visual regression.
- `priv/static/app.css` is committed generated output; any class changes require
  `mix mailglass_admin.assets.build` and a clean bundle diff.

### Integration Points

- Preview dark-mode correctness spans `PreviewLive` and `root.html.heex`; fixing
  only the inner `data-theme` wrapper is not enough if the root forces light.
- Mobile navigation connects `PreviewLive` layout to the existing `Sidebar`
  component. Preserve the component's relative scenario paths so custom adopter
  mount paths continue to work.
- Browser proof connects `structural.spec.js` to fixture scenario URLs and to the
  existing `/ops/browser-preview-empty` path for no-Mailables coverage.
- Audit proof connects `ui-audit.sh` to the same `?theme=dark` contract that
  `CaptureState` already emits for scenario captures.
</code_context>

<specifics>
## Specific Ideas

- Keep `<details>/<summary>` as the Preview navigation primitive; add mobile
  placement/disclosure around it rather than replacing it.
- Use `?theme=` only for admin chrome. Use a separate state if the previewed
  Message/frame needs a dark toggle.
- Treat `GAP-02` as a keyboard-actionability requirement for Preview index
  branches, not permission to render a broken "first Mailable" link when no
  Mailable exists.
- Update the audit-script comments as well as behavior; stale comments currently
  encode the old gap and would mislead Phase 103.
</specifics>

<deferred>
## Deferred Ideas

- Global microcopy sweep across Operator, Inbound, and Preview remains Phase 101.
  Phase 100 only applies Preview-specific locked copy needed for PAGE-03/GAP-02.
- Global motion and micro-interaction upgrades remain Phase 102. Phase 100 should
  not add decorative motion beyond what is necessary to preserve existing locked
  state/motion behavior.
- Brandbook/token authoring remains out of scope. Phase 100 consumes the existing
  token system.

### Reviewed Todos (not folded)

No matching pending todos were found for Phase 100.
</deferred>
