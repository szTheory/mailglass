# UI baseline consistency pass — 2026-10-10

Completed in the isolated phase-173 candidate checkout. Used the installed
Impeccable guidance and existing shared components; added no application dependencies.

## Changes

- Health: readable observation period, precise UTC interval in contextual help,
  local last-checked timestamp with UTC hover/copy, and Refresh health action.
- Preview: removed redundant HTML/text explanations, simplified raw/header caveats,
  and gave empty HTML/plain-text content a clear message.
- Inbound: consistent message-oriented empty states; unavailable detail has a short
  heading and returns directly to records when no quick view exists.
- Mobile: matching vertical summary layouts for Deliveries and Inbound; bundled
  icons replace text arrows; long module triggers and routing badges wrap.
- Help placement: tooltip-bearing reveal/overlay/timeline containers fade without
  transform, keeping fixed help viewport anchored during entry as well as afterward.
- Quick-view keyboard behavior: Enter on native controls does not also invoke the
  global full-detail shortcut. New desktop/mobile browser checks cover ID copying,
  toast feedback, remaining in quick view, and previous/next navigation.
- Updated existing UI assertions for the previously committed Subject labels,
  readable recipients, short module names, copy controls, and disclosure structure.
  Browser screenshots now go to ignored test-results instead of rewriting historical
  phase artifacts. Shared rules recorded in docs/design-system.md.

## Verification

- Final LiveView/component/voice run: **392 tests, 0 failures, 1 excluded** across
  operator_live, inbound_live, preview_live, components, inbound/components, voice.
- Final targeted Playwright run: **69 passed** across flows, operator,
  health-tooltips, inbound-layout, excluding names matching edge/stress/zoom.
- Separately verified the 320px inbound edge overflow case. Delivery module wrapping
  covers 320–1440px and actual 200% browser zoom within the selected wrapping test.
- Inbound layout checks include scoped axe scans with no violations for filters
  and overview at 1440, 1024, 390, and 320px. This is not a full-product axe audit.
- Manual desktop/mobile checks covered Health, Preview, Deliveries, Inbound,
  populated/filtered-empty views and missing inbound detail. No root overflow at 390px;
  intentional email-frame/table scrolling stays within its container.
- Rebuilt pinned Tailwind 4.1.12 bundle; git diff --check passed.
- Broader structural/phase-169 suites were not run; their affected copy assertions
  were aligned. This is a bounded baseline pass, not a claim that every repo test ran.

## Test infrastructure repair

Fresh admin test databases were missing core tables because the harness still
looked for a core priv/repo/migrations directory that is no longer shipped.
The test harness now uses the public Mailglass.Migration installer in its own
version slot, alongside the existing inbound installer. Migration uses a normal
connection pool, then restores the requested runtime pool before starting the repo.
Verified with isolated fresh test databases; production migration code is unchanged.
Committed separately as ebf92ba7.

## Deferred

Custom date ranges, automatic filter application, and debounced search remain in
SEED-261010-gad-operator-date-range-and-live-filters.md for later planning. The
pre-existing demo mix.lock runtime change is excluded from this pass.
