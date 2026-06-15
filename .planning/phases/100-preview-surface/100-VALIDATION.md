---
phase: 100
slug: preview-surface
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-15
---

# Phase 100 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Phoenix.LiveViewTest; Playwright Test |
| **Config file** | `mailglass_admin/mix.exs`; `mailglass_admin/package.json`; `mailglass_admin/playwright.config.cjs` |
| **Quick run command** | `cd mailglass_admin && mix test test/mailglass_admin/preview_live_test.exs --warnings-as-errors` |
| **Browser run command** | `cd mailglass_admin && mix mailglass_admin.assets.build && npx playwright test --config=playwright.config.cjs --workers=1 e2e/structural.spec.js --grep "Preview"` |
| **Full suite command** | `cd mailglass_admin && mix verify.preview` |
| **Estimated runtime** | ~60-600 seconds depending on browser setup |

---

## Sampling Rate

- **After every task commit:** Run `cd mailglass_admin && mix test test/mailglass_admin/preview_live_test.exs --warnings-as-errors` for LiveView-only changes.
- **After browser-facing layout/theme changes:** Run `cd mailglass_admin && mix mailglass_admin.assets.build && npx playwright test --config=playwright.config.cjs --workers=1 e2e/structural.spec.js --grep "Preview"`.
- **After every plan wave:** Run `cd mailglass_admin && mix verify.preview`.
- **Before `$gsd-verify-work`:** Run `cd mailglass_admin && mix verify.preview`, then ensure regenerated static assets are committed or `git diff --exit-code mailglass_admin/priv/static/` is clean.
- **Max feedback latency:** 600 seconds for the browser gate; keep the focused ExUnit lane under 120 seconds.

---

## Phase Requirement Verification Map

| Requirement / Decision | Behavior | Test Type | Automated Command | Current File Status |
|------------------------|----------|-----------|-------------------|---------------------|
| PAGE-03 / D-01 / D-05 | `/dev/mail?theme=dark` and scenario routes apply the admin chrome theme consistently from URL state. | ExUnit + Playwright | `cd mailglass_admin && mix test test/mailglass_admin/preview_live_test.exs --warnings-as-errors`; browser command above | Existing file needs index-route and root-layout extension |
| PAGE-03 / D-02 / D-07 | The previewed email/message frame keeps an independent dark-chrome toggle that does not mutate the admin chrome theme. | ExUnit + Playwright | `cd mailglass_admin && mix test test/mailglass_admin/preview_live_test.exs --warnings-as-errors`; browser command above | Existing tests cover one theme toggle path; independence coverage needed |
| PAGE-03 / D-03 / D-04 | Preview landing composes component groups with one `h1`, reachable mailable navigation at 390px, and least-surprise IA. | Playwright + source assertions | Browser command above | Structural spec currently only checks `preview-orientation`; needs real preview scenario path |
| PAGE-03 / D-06 / D-09 | Empty/loading states, focus rings, >=44px primary controls, and WCAG-AA light/dark contrast pass at 390/768/1440. | Playwright | Browser command above | Needs explicit Preview matrix extension |
| PAGE-03 / D-08 | Tailwind/static bundle is rebuilt after class changes and left clean. | Mix/source gate | `cd mailglass_admin && mix mailglass_admin.assets.build && git diff --exit-code mailglass_admin/priv/static/` | Existing asset build command is available |

---

## Wave 0 Requirements

- [ ] Extend `mailglass_admin/test/mailglass_admin/preview_live_test.exs` to cover the index route `?theme=dark`, scenario route admin chrome theme, and admin/message theme separation.
- [ ] Extend `mailglass_admin/e2e/structural.spec.js` with a real Preview scenario helper, not only the empty-preview route.
- [ ] Add 390/768/1440 light/dark structural assertions for Preview chrome groups, one `h1`, primary controls, focus rings, and text/non-text contrast.
- [ ] Preserve existing preview capture tests under `mailglass_admin/test/mailglass_admin/preview/` unless the planner explicitly assigns a related update.
- [ ] Keep `mailglass_admin/priv/static/app.css` regenerated and clean after any class changes.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Final preview visual rhythm against Operator and Inbound surfaces | PAGE-03 | Automated checks can prove structure, contrast, and viewport behavior; final design parity still needs maintainer judgment | Inspect `/dev/mail` and one real scenario route at 390, 768, and 1440 in both admin themes after the browser gate passes. |

---

## Validation Sign-Off

- [ ] All planned tasks have automated verification or a Wave 0 dependency.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [ ] Wave 0 covers all missing Preview route, theme, responsive, and contrast references.
- [ ] No watch-mode flags.
- [ ] Feedback latency < 600 seconds.
- [ ] `nyquist_compliant: true` set in frontmatter after Wave 0 coverage is planned.

**Approval:** pending
