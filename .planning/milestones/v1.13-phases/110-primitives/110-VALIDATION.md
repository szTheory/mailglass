---
phase: 110
slug: primitives
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-18
---

# Phase 110 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Mix/ExUnit plus Playwright Test |
| **Config file** | `mailglass_admin/playwright.config.cjs`; Mix aliases in `mailglass_admin/mix.exs` |
| **Quick run command** | `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs test/mailglass_admin/operator/shell_test.exs --warnings-as-errors` |
| **Full suite command** | `bash mailglass_admin/scripts/check-conformance.sh && cd mailglass_admin && mix verify.support_contract.admin && mix verify.preview && npm run test:operator-browser` |
| **Estimated runtime** | ~90-300 seconds after deps and browsers are present |

---

## Sampling Rate

- **After every task commit:** Run `bash mailglass_admin/scripts/check-conformance.sh` plus focused ExUnit for the component or gate family touched.
- **After every plan wave:** Run `cd mailglass_admin && mix verify.support_contract.admin` and focused `npm run test:operator-browser -- --grep "gallery|touch targets|system|focus"`.
- **Before `/gsd:verify-work`:** Run `cd mailglass_admin && mix verify.preview && npm run test:operator-browser`; after any class or bundle change, also run `git diff --exit-code priv/static/` from `mailglass_admin`.
- **Max feedback latency:** Keep focused checks under 5 minutes; run full suite only at wave/phase gates.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 110-PRIM-01 | TBD | 1 | PRIM-01 | T-110-01 | Shell and gallery call public primitives from `MailglassAdmin.Components`; private/inlined primitive copies are rejected. | unit + grep | `bash mailglass_admin/scripts/check-conformance.sh`; `cd mailglass_admin && mix test test/mailglass_admin/operator/shell_test.exs --warnings-as-errors` | needs extension | pending |
| 110-PRIM-02 | TBD | 1 | PRIM-02 | T-110-02 | Gallery specimens render primitive interaction states across light/dark/system without relying on gallery-only APIs. | Playwright structural | `cd mailglass_admin && npm run test:operator-browser -- --grep "gallery"` | needs extension | pending |
| 110-PRIM-03 | TBD | 1 | PRIM-03 | T-110-03 | Disabled primitives are visibly and programmatically disabled; enabled controls do not look disabled. | unit + Playwright structural | `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs --warnings-as-errors`; focused disabled/enabled structural grep | needs extension | pending |
| 110-PRIM-04 | TBD | 1 | PRIM-04 | T-110-04 | `stat_card` is canonical; labels truncate with title, values use `tabular-nums` and do not wrap, and severity is icon + label + color. | unit + grep + Playwright overflow | `bash mailglass_admin/scripts/check-conformance.sh`; `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs --warnings-as-errors` | needs extension | pending |
| 110-PRIM-05 | TBD | 1 | PRIM-05 | T-110-05 | Theme picker is a three-choice radio group; `system` is absence of explicit theme and never writes `data-theme="system"`. | unit + Playwright structural | `cd mailglass_admin && mix test test/mailglass_admin/components_test.exs --warnings-as-errors`; focused Playwright system/default grep | needs extension | pending |
| 110-PRIM-06 | TBD | 2 | PRIM-06 | T-110-06 | Primitive pointer targets meet the 44px default floor or a documented 24px WCAG 2.2 exception; compiled bundle proves the final CSS. | Playwright structural + bundle-clean | `cd mailglass_admin && npm run test:operator-browser -- --grep "touch targets"`; `cd mailglass_admin && mix mailglass_admin.assets.build && git diff --exit-code priv/static/` | needs extension | pending |
| 110-PRIM-07 | TBD | 2 | PRIM-07 | T-110-07 | Every used `hero-*` icon exists in `heroicons-inline.js`; meaningful states are not represented by icon or color alone. | grep/script + unit | committed icon inventory guard plus component assertions for adjacent labels or accessible names | missing guard | pending |

*Status: pending, green, red, flaky.*

---

## Wave 0 Requirements

- [ ] `mailglass_admin/test/mailglass_admin/components_test.exs` - add focused component assertions for `nav_link`, `nav_pill`, `tenant_chip`, `theme_picker`, and `stat_card`.
- [ ] `mailglass_admin/scripts/check-conformance.sh` - add PRIMITIVE-DRIFT, STATCARD, and ICON-EXISTS gates while preserving the existing deterministic shell-script pattern.
- [ ] `mailglass_admin/e2e/structural.spec.js` - extend gallery/system/touch-target checks for the new public primitive specimens, disabled/enabled distinction, and stat-card overflow/no-wrap proof.
- [ ] `mailglass_admin/lib/mailglass_admin/gallery_live.ex` - add specimens for `stat_card` and 3-way theme picker and replace copied nav/tenant/theme specimens with public component calls.
- [ ] Local dependency readiness - run `cd mailglass_admin && mix deps.get` and `npm ci` only if local dependencies are stale or browser tests cannot start.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Dense-control WCAG 2.2 exceptions | PRIM-06 | A 24px exception is a product/design judgment; the automated gate can enforce either a 44px target or the presence of documented exception evidence, but cannot decide whether an exception is acceptable. | If a primitive intentionally uses a dense 24px target, record the WCAG SC 2.5.8 exception reason in the relevant plan summary and verify the structural gate still passes the 24px minimum. |

---

## Validation Sign-Off

- [x] All requirements have an automated verification path or an explicit manual checkpoint
- [x] Sampling continuity: no 3 consecutive tasks may proceed without an automated focused check
- [x] Wave 0 covers all missing gate/test extensions
- [x] No watch-mode flags
- [x] Feedback latency target is under 5 minutes for focused checks
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending planner/checker verification
