---
phase: 100
slug: preview-surface
status: verified
threats_open: 0
asvs_level: 1
created: 2026-06-15
---

# Phase 100 - Security

Per-phase security contract: threat register, accepted risks, and audit trail.

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Browser URL -> PreviewLive assigns | Untrusted `theme`, `width`, `mailable`, and `scenario` params cross into LiveView state. | Route params and query params |
| Browser URL -> root layout | Untrusted query string influences root `data-theme`. | Query string |
| PreviewLive -> Sidebar links | URL state is re-emitted into relative scenario links. | Relative patch URLs |
| PreviewLive -> iframe/pane | Previewed Message HTML remains isolated from admin chrome. | Rendered preview HTML |
| Preview navigation DOM -> LiveView patch URLs | Sidebar and CTA links emit route state back to PreviewLive. | Link href/patch state |
| Mobile disclosure/navigation -> page heading structure | Reused Sidebar content can duplicate headings if not demoted. | DOM hierarchy |
| Assigns form -> renderer | Existing form inputs update scenario assigns and trigger rendering. | Form params |
| HEEx class changes -> generated CSS | Tailwind scans source classes and writes committed static CSS. | Generated stylesheet |
| Browser tests -> dev Preview route | Playwright exercises dev-only `/dev/mail` and synthetic fixtures. | Browser session state |
| Audit script -> local browser capture | Local agent-browser capture writes gitignored PNG evidence. | Local screenshots |
| Verification evidence -> gap register | Automated gate results justify changing stable GAP row status. | Planning metadata |

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-100-01 | Tampering | `PreviewLive.handle_params/3` theme parsing | mitigate | `parse_admin_chrome_theme/1` allowlists `dark`, `mailglass-dark`, `light`, and `mailglass-light`; invalid or absent values map to `nil`. | closed |
| T-100-02 | Denial of Service | mailable/scenario params | mitigate | `safe_mailable_atom/1` and `safe_scenario_atom/1` preserve `String.to_existing_atom/1`; no unbounded atom creation from params. | closed |
| T-100-03 | Information Disclosure | `/dev/mail` route scope | mitigate | Phase implementation stayed inside the existing dev Preview surface; no sibling LiveView, production `/ops` route, public API, auth path, or core email component change was introduced. | closed |
| T-100-04 | Tampering | Preview iframe/pane | mitigate | `Tabs` retains the iframe sandbox contract while scoping frame theme to `data-preview-frame-theme` on the pane wrapper. | closed |
| T-100-05 | Repudiation | root/page theme behavior | mitigate | `preview_live_test.exs` records explicit light/dark, absent-theme, and theme-independence behavior. | closed |
| T-100-06 | Information Disclosure | Preview navigation route scope | mitigate | Sidebar and CTA navigation use existing relative `/dev/mail` links; no production route or public API was added. | closed |
| T-100-07 | Denial of Service | mobile Sidebar duplication | mitigate | Mobile Preview reuses existing Sidebar data and native links without adding discovery calls, socket events, or client hooks. | closed |
| T-100-08 | Repudiation | a11y/source hooks | mitigate | Stable `data-testid` hooks were added for Preview shell, mobile Mailables, header controls, assigns form, tab strip, pane, empty, and error states. | closed |
| T-100-09 | Tampering | assigns form buttons | accept | Existing `assigns_changed` safe-key coercion remained unchanged; this phase changed classes and test hooks only. | closed |
| T-100-10 | Repudiation | generated CSS bundle | mitigate | `mix mailglass_admin.assets.build` and `git diff --exit-code priv/static/` were run during execution; committed static CSS is clean. | closed |
| T-100-11 | Repudiation | `structural.spec.js` Preview assertions | mitigate | Named `Preview:` Playwright tests use stable hooks and direct fixture URLs for the JTBD path. | closed |
| T-100-12 | Information Disclosure | browser fixture Preview route | mitigate | Browser proof uses existing synthetic fixture modules and does not call production delivery paths. | closed |
| T-100-13 | Tampering | `ui-audit.sh` PNG capture | mitigate | Audit script changes are limited to comments and Preview light/dark URLs; PNGs remain under gitignored `tmp/ui-audit`. | closed |
| T-100-14 | Tampering | `.planning/RATCHET-GAP-REGISTER.md` | mitigate | Only `GAP-02` and `GAP-03` were changed to fixed with Phase 100 evidence. | closed |
| T-100-15 | Denial of Service | browser gate reset state | mitigate | Focused Playwright and full operator browser gates ran serialized with the existing harness. | closed |
| T-100-SC | Tampering | npm/pip/cargo installs | accept | No package-manager install or new dependency was planned or performed; existing Phoenix, LiveView, Tailwind, and Playwright stack was used. | closed |

## Evidence

| Threat Ref | Evidence |
|------------|----------|
| T-100-01 | `preview_live.ex` contains the explicit theme parser and `root.html.heex` uses `data-theme={root_theme(assigns)}`. |
| T-100-02 | `preview_live.ex` keeps `String.to_existing_atom/1` for mailable/scenario conversion. |
| T-100-03, T-100-06, T-100-12 | The modified files are limited to the dev Preview surface, tests, audit script, CSS bundle, and planning artifacts named by the plans. |
| T-100-04 | `tabs.ex` retains `sandbox="allow-same-origin"` and emits `data-preview-frame-theme` on the preview pane. |
| T-100-05, T-100-08, T-100-11 | `preview_live_test.exs` and `structural.spec.js` include Preview route, structural, one-h1, focus, touch, independent-toggle, and contrast assertions. |
| T-100-07 | `preview_live.ex` has `preview-mobile-mailables` and reuses `Sidebar.sidebar/1`; `sidebar.ex` retains native `details`/`summary`. |
| T-100-09 | No renderer or assign coercion change was required for the button class/test-hook work. |
| T-100-10 | Plan 100-02 summary records passing asset build and clean `priv/static/` diff. |
| T-100-13 | `ui-audit.sh` captures `$BASE/dev/mail/?theme=light` and `$BASE/dev/mail/?theme=dark` as `preview-${vp}-light` and `preview-${vp}-dark`. |
| T-100-14 | `.planning/RATCHET-GAP-REGISTER.md` rows `GAP-02` and `GAP-03` are fixed with run id `2026-06-15-phase-100`. |
| T-100-15 | Plan 100-03 summary records passing focused Playwright and full `npm run test:operator-browser` gates. |
| T-100-SC | Phase plans and summaries list no added dependencies; current git diff for this security pass contains only this security artifact. |

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-100-01 | T-100-09 | Assigns form button work changed only presentation classes/test hooks; existing safe-key coercion behavior remained out of scope and unchanged. | GSD secure-phase audit | 2026-06-15 |
| AR-100-02 | T-100-SC | No package-manager install or new dependency was needed for the phase, so supply-chain exposure did not increase. | GSD secure-phase audit | 2026-06-15 |

## Security Audit 2026-06-15

| Metric | Count |
|--------|-------|
| Threats found | 16 |
| Closed | 16 |
| Open | 0 |

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-06-15 | 16 | 16 | 0 | Codex `gsd-secure-phase` |

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-06-15
