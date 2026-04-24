---
phase: 5
slug: dev-preview-liveview
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-24
---

# Phase 5 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `05-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (stdlib) + Phoenix.LiveViewTest (phoenix_live_view `~> 1.1`) |
| **Config file** | `mailglass_admin/test/test_helper.exs` (new — Wave 0) |
| **Quick run command** | `mix test test/mailglass_admin/ --stale` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~5 s (stale) / ~30 s (full admin suite) |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/mailglass_admin/ --stale`
- **After every plan wave:** Run `mix test` (full admin suite)
- **Before `/gsd-verify-work`:** Full core + admin suite green, plus `mix mailglass_admin.assets.build && git diff --exit-code priv/static/` passing
- **Max feedback latency:** ~5 seconds (stale) / ~30 seconds (full wave)

---

## Per-Task Verification Map

> Tasks are placeholders until the planner emits concrete `{N}-{plan}-{task}` IDs.
> The requirement-to-behavior-to-command mapping below is the contract the planner MUST satisfy when assigning `<automated>` commands.

| Req ID  | Behavior                                                                                                     | Test Type                             | Automated Command                                                          | File Exists |
|---------|--------------------------------------------------------------------------------------------------------------|---------------------------------------|----------------------------------------------------------------------------|-------------|
| PREV-01 | `mailglass_admin/mix.exs` has `{:mailglass, "== <pinned>"}` in Hex-published config                          | unit (mix.exs parse)                  | `mix test test/mailglass_admin/mix_config_test.exs -x`                     | ❌ W0       |
| PREV-02 | `mailglass_admin_routes/2` macro expands to valid route block with asset + live routes                        | unit (macro expansion)                | `mix test test/mailglass_admin/router_test.exs -x`                         | ❌ W0       |
| PREV-02 | `__session__/N` returns whitelisted map, never adopter session keys                                           | unit                                   | `mix test test/mailglass_admin/router_test.exs --only session_isolation -x` | ❌ W0       |
| PREV-03 | Sidebar renders discovered mailables (scenarios + no-previews + error states)                                 | integration (Phoenix.LiveViewTest)    | `mix test test/mailglass_admin/preview_live_test.exs --only sidebar -x`    | ❌ W0       |
| PREV-03 | HTML / Text / Raw / Headers tabs render correct Renderer output                                               | integration                            | `mix test test/mailglass_admin/preview_live_test.exs --only tabs -x`       | ❌ W0       |
| PREV-03 | Device width toggle updates iframe width CSS                                                                  | integration                            | `mix test test/mailglass_admin/preview_live_test.exs --only device_toggle -x` | ❌ W0    |
| PREV-03 | Dark chrome toggle flips `data-theme` attribute                                                               | integration                            | `mix test test/mailglass_admin/preview_live_test.exs --only dark_toggle -x`  | ❌ W0     |
| PREV-03 | Assigns form re-renders preview on change                                                                     | integration                            | `mix test test/mailglass_admin/preview_live_test.exs --only assigns_form -x` | ❌ W0     |
| PREV-04 | PreviewLive subscribes to `mailglass:admin:reload` and refreshes on broadcast                                 | integration (simulated broadcast)      | `mix test test/mailglass_admin/preview_live_test.exs --only live_reload -x`  | ❌ W0     |
| PREV-05 | Brand palette applied via `data-theme` light/dark via daisyUI                                                 | visual/unit (Floki parse compiled CSS) | `mix test test/mailglass_admin/brand_test.exs -x`                          | ❌ W0       |
| PREV-05 | WCAG AA contrast for Ink/Slate on Paper/Mist                                                                  | unit (contrast ratio)                  | `mix test test/mailglass_admin/accessibility_test.exs -x`                  | ❌ W0       |
| PREV-06 | `priv/static/app.css` exists, size < 150KB                                                                    | unit (File.stat)                       | `mix test test/mailglass_admin/bundle_test.exs -x`                         | ❌ W0       |
| PREV-06 | `git diff --exit-code priv/static/` after `mix mailglass_admin.assets.build`                                   | CI integration                         | GitHub Actions workflow check                                              | ❌ W0       |
| PREV-06 | Hex tarball size < 2 MB                                                                                       | CI integration                         | `mix hex.build && du -h mailglass_admin-*.tar`                             | ❌ W0       |
| BRAND-01| All UI copy uses brand voice (no "Oops!", no passive phrases)                                                 | unit (Floki parse + lexicon match)     | `mix test test/mailglass_admin/voice_test.exs -x`                          | ❌ W0       |

*Status legend: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky · W0 = produced in Wave 0*

---

## Wave 0 Requirements

Wave 0 of the Phase 5 plan set **MUST** produce these files (the planner is responsible for mapping them to concrete tasks):

- [ ] `mailglass_admin/test/test_helper.exs` — ExUnit config + Mox setup
- [ ] `mailglass_admin/test/support/endpoint_case.ex` — `ConnTest` harness with a synthetic adopter Endpoint (exercises `mailglass_admin_routes/2` + `__session__/N`)
- [ ] `mailglass_admin/test/support/live_view_case.ex` — `Phoenix.LiveViewTest` wrapper around the same synthetic endpoint
- [ ] `mailglass_admin/test/support/fixtures/mailables.ex` — fixture modules `use Mailglass.Mailable` with: valid `preview_props/1`, no `preview_props/1`, `preview_props/1` that raises
- [ ] `mailglass_admin/test/mailglass_admin/mix_config_test.exs` — asserts `{:mailglass, "== ..."}` pin (PREV-01)
- [ ] `mailglass_admin/test/mailglass_admin/router_test.exs` — macro expansion + `__session__/N` isolation (PREV-02)
- [ ] `mailglass_admin/test/mailglass_admin/preview_live_test.exs` — sidebar / tabs / device toggle / dark toggle / assigns form / live_reload (PREV-03, PREV-04)
- [ ] `mailglass_admin/test/mailglass_admin/discovery_test.exs` — auto-scan + explicit list + graceful failure (PREV-03)
- [ ] `mailglass_admin/test/mailglass_admin/assets_test.exs` — controller serves correct bytes, hash matches, cache headers (PREV-06)
- [ ] `mailglass_admin/test/mailglass_admin/brand_test.exs` — palette mapping, WCAG AA contrast (PREV-05)
- [ ] `mailglass_admin/test/mailglass_admin/accessibility_test.exs` — contrast ratio checks for Ink/Slate on Paper/Mist (PREV-05)
- [ ] `mailglass_admin/test/mailglass_admin/bundle_test.exs` — `priv/static/app.css` size budget < 150 KB (PREV-06)
- [ ] `mailglass_admin/test/mailglass_admin/voice_test.exs` — brand voice lexicon (BRAND-01)

**Framework install:** ExUnit + Mox already present in `mailglass`. `phoenix_live_view` ships `Phoenix.LiveViewTest`. No new dep install — `mailglass_admin/test/` directory is net-new.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Browser refresh on mailable file edit triggers LiveReload broadcast and preview reflows without full page reload | PREV-04 | Requires a running Phoenix dev server with `:phoenix_live_reload` listening on real filesystem events; CI harness only simulates the broadcast. | 1. In a Phoenix 1.8 adopter app: mount `mailglass_admin_routes "/dev/mail"` in `:dev` pipeline. 2. `mix phx.server`. 3. Open `/dev/mail/<module>/<preview>`. 4. Edit the corresponding mailable `.ex` file and save. 5. Confirm preview pane updates within ~500 ms without full page reload (Network tab shows only WebSocket frames, no fresh HTML request). |
| Visual brand audit (no glassmorphism / bevels / lens flares / literal broken glass anywhere in admin UI) | PREV-05 / BRAND-01 | Subjective visual review; Floki parse of compiled CSS catches class usage but not visual intent. | Load `/dev/mail` in light + dark mode. Scroll every screen. Reject any effect that uses `backdrop-blur`, `box-shadow: inset`, bevels, or decorative broken-glass / shattered imagery. |
| Mobile responsiveness (≤ 480 px) of preview LiveView | PREV-05 | Responsive behavior depends on real viewport + touch; tests assert breakpoint CSS but not UX. | Open `/dev/mail` in browser DevTools device mode at 375 × 812 (iPhone SE) and 768 × 1024 (iPad). Sidebar collapses to drawer, tabs remain reachable, device width toggle still works. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all ❌ W0 references above
- [ ] No watch-mode flags in any automated command
- [ ] Feedback latency < 30 s (full admin suite)
- [ ] `nyquist_compliant: true` set in frontmatter once planner + checker both pass

**Approval:** pending
