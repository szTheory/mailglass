# Phase 171 Rendered Review

## Source and capture setup

- **Checkout source revision:** `7fd442ab1a53eeb98885821a620d190dd0c555b0`
- **Host:** `http://127.0.0.1:4103`
- **Route:** `/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_überraschung_東京__with_a_deliberately_long_name`
- **Fixture:** synthetic `MailglassAdmin.Fixtures.HappyMailer` long-name scenario
- **Served stylesheet:** `/priv/static/app.css`, SHA-256 `91c0b80fd5d2d9dd42d6501b615f3167b5f25a13beed92894e11fdfa1b6abff1`
- **Temporary output:** `mailglass_admin/tmp/mailglass_admin_preview_capture/` (ignored; synthetic fixture only)

## Rendered observations

| State | Viewport and appearance | Observation | Temporary screenshot |
| --- | --- | --- | --- |
| Narrow light | 390 × 900 CSS px, Admin Light, preview backdrop light | The complete non-ASCII scenario remains visible across wrapped identity lines. Width controls, backdrop control, limitation copy, tabs, long textual output, and assigns remain reachable without page-level horizontal overflow. | `phase171-390-light.png` |
| Narrow system dark | 390 × 900 CSS px, Admin System following dark OS preference | Admin chrome changes to dark while the preview retains its independent browser backdrop. The long identity and output remain readable, and no horizontal overflow is reported. | `phase171-390-system-dark.png` |
| Wide dark | 1024 × 900 CSS px, Admin Dark | The selected module and long scenario identity fit on a single line; frame controls, browser backdrop, and preview limitation remain visible above the output tabs. | `phase171-1024-dark.png` |
| Actual browser zoom | 320 CSS px effective width at 200% Chromium zoom | Machine assertions confirm the long identity, all three 44 px frame controls, backdrop control, and focus states remain in bounds. The screenshot is magnified at the browser's device-pixel scale and is not used as a pixel-comparison artifact. | `phase171-320-actual-200-percent.png` |

## Correction and confirmation

The first 1024 px rendered review showed the selected identity squeezed into a 16 px-wide menu. The `sm:max-w-md` utility compiled against this project's spacing token as `max-width: var(--spacing-md)`, which resolved to 16 px. Removing that max-width and keeping the header controls stacked until the extra-wide breakpoint restored the full identity and kept the controls organized. Compact visible width labels (`375 px`, `768 px`, `1024 px`) retain full accessible names in CSS pixels and removed a 320 px gallery specimen overflow. Shared focus-ring styling gives all width buttons a visible keyboard indicator.

The confirmation round passed the Plan 171 framing, responsive journey, and actual 200% zoom browser cases, plus both gallery matrix overflow checks (5 focused browser tests passed). The selected identity is one line at 1024 CSS px and readable over multiple lines at 390 CSS px. The Admin preview fixture and capture command use synthetic data.

## Machine evidence and boundaries

- Required `mix verify.support_contract.admin`: **589 tests, 0 failures, 1 excluded**.
- Asset parity/bundle checks: **10 tests, 0 failures**.
- `mix mailglass_admin.preview.capture --dry-run --base-url http://localhost:4000/dev/mail --output-dir tmp/mailglass_admin_preview_capture`: **30 deterministic entries** (5 synthetic scenarios × 3 widths × 2 themes), with 2 intentional skips (`BrokenMailer` discovery error and `StubMailer` without previews); manifest and checkpoint were written under `tmp/`.
- Advisory full `npm run test:operator-browser`: **207 passed, 1 skipped, 3 failed** on the pre-correction working tree. One failure was the long width labels overflowing the gallery at 320 px and is covered by the passing post-correction gallery checks. Two older journey assertions remain stale: the flow test looks for a `.btn-primary` render button that is absent, and the mobile picker assertion expects the module name to be omitted. These are recorded in `deferred-items.md`; the full advisory suite was not rerun after the compact-label correction.

These browser images and deterministic checks demonstrate only the Mailglass preview pipeline. They do not certify Gmail, Outlook, Apple Mail, any other recipient client, or email dark-mode behavior. The iframe and browser backdrop are presentation aids; they are not sanitization or network-isolation guarantees. Temporary captures may contain scenario data and should stay in the controlled `tmp/` path.
