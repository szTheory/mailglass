# Phase 170 Rendered Inspection

## Provenance

- **Source revision:** `7146f69c7a1c959a084a1bdafdefd1c78624d0b1`
- **Host and route:** local Playwright Chromium against `http://127.0.0.1:4102/ops/mail/inbound`, deterministic `browser-tenant` fixture, exact accepted record in Full detail.
- **Browser command:** `ASDF_ELIXIR_VERSION=1.18.4-otp-27 BROWSER_SERVER_PORT=4102 asdf exec npm run test:operator-browser -- --grep "Phase 170 rendered"`
- **Result:** 1 rendered case passed on the committed revision; the final full browser suite also passed.
- **Source CSS SHA-256:** `54d43a087779331b14cda9c1fa5e98a1cd436400c40208a9a1a5a7f63e6e15a2`
- **Generated CSS SHA-256:** `31afa97e9f49e46d7ffe8d356269f88a96ed56ca0a71e952bcac5e91c8c17b5a`
- **Served CSS:** `http://127.0.0.1:4102/ops/mail/css-3b6d315f0bad9a8607e1fbe8d8a5be34`, SHA-256 `31afa97e9f49e46d7ffe8d356269f88a96ed56ca0a71e952bcac5e91c8c17b5a` (matches generated CSS).
- **Inline JavaScript SHA-256:** `f28730111b93a5ca97c3d7a9af6a5dccbe3a3a372c300ff0f0a807236564b8ff`.

The machine-readable provenance is `mailglass_admin/test-results/phase170-rendered-provenance.json` (ignored test output). Its screenshots are also under ignored `mailglass_admin/test-results/` so they do not add binary artifacts to the source commit.

## Inspection and Automated Evidence

The rendered case captured Full detail at 320, 390, 768, and 1440 CSS pixels in Light, Dark, and System. At every capture the document width equaled the viewport, the automated overflow scan found no offenders, and every visible button/link measured at least 44×44 CSS pixels. The dedicated touch context used a 390×844 viewport and tapped the detail Back control; its measured height was at least 44 CSS pixels.

The test emulated a live operating-system color-scheme change while System remained selected, enabled reduced motion, and exercised the evidence disclosure with Tab and Enter. It verifies expanded/live status, re-redaction, and focus return. The connected journey separately covers replay review, command feedback, the timestamped history snapshot, and explicit Refresh history.

Actual Chromium tab zoom was set to 200% using the existing browser-zoom extension: a 1440-device-pixel viewport became 720 CSS pixels. The test confirmed the effective viewport and document stayed within 720 CSS pixels and rechecked all visible interactive targets against the 44×44 floor. The actual-zoom capture is `mailglass_admin/test-results/phase170-200pct-dark.png`.

Screenshots for the responsive/theme matrix are:

- `phase170-320-{light,dark,system}.png`
- `phase170-390-{light,dark,system}.png`
- `phase170-768-{light,dark,system}.png`
- `phase170-1440-{light,dark,system}.png`
- `phase170-200pct-dark.png`

The 320/light and actual-200%/dark screenshots were opened and visually reviewed. The detail reads as a single vertical investigation flow at narrow width, with masked evidence, replay and history separated into distinct cards. The first 200% capture exposed a clipped shell action group; the mobile-width rule now moves Account and Appearance controls below the logo and stacks them. The confirmation screenshot shows both groups within the viewport. A 44.1px evidence-disclosure minimum keeps its actual-zoom box above the strict 44px floor despite subpixel rounding. All other viewport/theme combinations had deterministic screenshot, geometry and target-size checks.

Connected browser cases also exercised empty and filtered-empty results, out-of-range selection, foreign-ID nondisclosure, optional package/read failures, denied reveal/replay, busy/duplicate confirmation, no-change, recorded failure, command failure, and failed history refresh. These states are checked through the live page and safe-copy assertions; they are not all retained as separate screenshot captures.

## Corrections

- Added `overflow-wrap: anywhere` for long mono values in the Admin source and generated CSS; source, built and served hashes match.
- At narrow CSS widths, including the 720px viewport produced by actual 200% zoom, moved and stacked the shell actions so Account and Appearance controls remain visible.
- Strengthened the rendered control assertion to require both width and height of at least 44 CSS pixels, including at actual 200% zoom; the dedicated touch height assertion uses 44 as well.
- Added a 44.1px minimum to the evidence disclosure because Chromium reported 43.99988px for a nominal 44px control after actual zoom scaling.
- Preserved the latest successful history snapshot and its read timestamp when replay command feedback arrives. The operator sees the new run after using Refresh history.
- Corrected the deterministic browser fixture so accepted/no-match records carry the same durable `mailglass_execution_route` binding required by replay.

## Evidence Limits

This is local Chromium evidence against the deterministic fixture and current served Admin assets. The full operator suite has one pre-existing guarded skip at `mailglass_admin/e2e/structural.spec.js:2852`: it covers the top-edge origin only when a header-anchored overlay exists; the current centered-modal outcome intentionally has no such overlay. No routine owner UAT remains for the machine-observable criteria in this plan.
