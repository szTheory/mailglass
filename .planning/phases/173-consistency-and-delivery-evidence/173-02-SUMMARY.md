---
phase: 173-consistency-and-delivery-evidence
plan: 02
subsystem: ui
tags: [elixir, phoenix-storybook, playwright, css-tokens, preview-evidence]
requires:
  - phase: 173-01
    provides: Isolated synthetic browser evidence and the phase-wide provenance contract
provides:
  - Fail-closed Admin screenshot manifest with actual-byte and candidate provenance
  - Source-aligned design-system guide and token parity assertions
  - Browser proof for Gallery and curated Storybook overlap at a 768px viewport
affects: [173-03, design-system, admin-preview, browser-evidence]
actuals:
  tokens: 10145
  tasks: 3
  commits: 3
plan_head_before: ecdcd9b85f1c627e09a89193bd112eddbe9a62eb
plan_head_after: 9cd4ec71f3e056e8e5adca3112473ebc41bf12f2
commits: 3
tech-stack:
  added: []
  patterns: [actual screenshot-byte provenance, identity-only dry-run manifests, source-checked design guidance, isolated Storybook radio groups]
key-files:
  created: []
  modified:
    - mailglass_admin/dev/mailglass_admin/preview/capture_manifest.ex
    - mailglass_admin/dev/mix/tasks/mailglass_admin.preview.capture.ex
    - mailglass_admin/test/mailglass_admin/preview/capture_manifest_test.exs
    - mailglass_admin/docs/design-system.md
    - mailglass_admin/test/mailglass_admin/token_parity_test.exs
    - reference/demo_app/assets/e2e/persona-screenshots.spec.js
    - reference/demo_app/storybook/primitives/theme_picker.story.exs
key-decisions:
  - "Only actual PNG bytes can support a rendered-capture claim; dry runs remain identity-only."
  - "The brandbook owns identity and token values, while Admin CSS owns semantic implementation roles."
  - "Each ThemePicker Storybook variation has an isolated radio-group name; shared component defaults remain unchanged."
patterns-established:
  - "Capture manifests validate owned relative paths and hash actual screenshot bytes alongside candidate and asset provenance."
  - "Gallery is the broad state inventory; Storybook is a curated primitive explorer using the shared versioned Admin CSS."
requirements-completed: [UIQ-01, UIQ-02]
coverage:
  - id: D1
    description: "Admin preview evidence distinguishes actual screenshot-byte proof from deterministic identity-only dry runs and rejects incomplete evidence."
    requirement: UIQ-02
    verification:
      - kind: unit
        ref: "mix test test/mailglass_admin/preview/capture_manifest_test.exs test/mix/tasks/mailglass_admin.preview.capture_test.exs --warnings-as-errors --seed 1"
        status: pass
    human_judgment: false
  - id: D2
    description: "Design guidance matches token ownership and shipped Admin CSS roles, with focused drift assertions."
    requirement: UIQ-01
    verification:
      - kind: unit
        ref: "mix test test/mailglass_admin/token_parity_test.exs --warnings-as-errors --seed 1"
        status: pass
    human_judgment: false
  - id: D3
    description: "Gallery and Storybook render overlapping review examples with independent theme state and the same served versioned Admin stylesheet at 768px."
    requirement: UIQ-01
    verification:
      - kind: e2e
        ref: "npm --prefix reference/demo_app/assets run test:e2e -- e2e/persona-screenshots.spec.js --grep \"review surfaces\" (isolated disposable demo; 768px viewport)"
        status: pass
    human_judgment: false
duration: 37min
completed: 2026-10-10
status: complete
---

# Phase 173 Plan 02: Consistent Review Surfaces and Capture Provenance Summary

**Admin captures now prove actual screenshot bytes and candidate assets, while the design guide and Gallery/Storybook review paths agree with the shipped tokens and styles.**

## Performance

- **Duration:** approximately 37 minutes, reconstructed from the execution record and task commit timeline
- **Started:** 2026-10-10 (exact start time not recorded)
- **Completed:** 2026-10-10
- **Tasks:** 3/3
- **Files modified:** 7

## Accomplishments

- Actual Admin captures record candidate revision and dirty state, route and scenario, browser/version, source/build/served asset identity, output path, and SHA-256 of the PNG bytes. Missing or unsafe image files and incomplete actual provenance fail closed; dry-run output is labeled identity-only.
- The Admin design guide now reflects brandbook ownership, shipped semantic CSS mapping and type/control scales, the broad Gallery inventory, and the curated Storybook explorer. Token parity tests guard stable source-to-guide facts.
- The Gallery and curated Storybook smoke passed against the same versioned Admin CSS. Storybook ThemePicker variations use independent radio names so their selected states remain checked together.
- Browser evidence was verified at **768px**. This does not claim the Gallery passes at 320px: the observed fixed-width logo and expanded Gallery card overflow at 320px are pre-existing layout issues outside this plan's docs/evidence scope and remain deferred.

## Verification

- `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix test test/mailglass_admin/preview/capture_manifest_test.exs test/mix/tasks/mailglass_admin.preview.capture_test.exs --warnings-as-errors --seed 1` — 13 passed, 0 failed.
- `cd mailglass_admin && ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix test test/mailglass_admin/token_parity_test.exs --warnings-as-errors --seed 1` — 5 passed, 0 failed.
- `npm --silent --prefix assets run test:e2e -- e2e/persona-screenshots.spec.js --grep "review surfaces"` inside the isolated disposable demo — passed at 768px; route, independent theme state, and served Admin CSS assertions passed.
- `node --check reference/demo_app/assets/e2e/persona-screenshots.spec.js` — passed.
- `git diff --check` over the plan-owned implementation files — passed.

These checks concern browser rendering and preview evidence only. They do not certify Gmail, Outlook, Apple Mail, or delivered-email rendering. The dirty `reference/demo_app/assets/e2e/demo.spec.js` was not read, staged, imported, or executed. The disposable browser project was removed after the run.

## Task Commits

1. **Task 1: Validate actual Admin preview capture provenance** — `3143202c` (`fix`).
2. **Task 2: Reconcile current design guidance with the canonical brand and shipped CSS** — `e3ea43c3` (`docs`).
3. **Task 3: Verify Gallery and curated Storybook overlap in the served demo** — `9cd4ec71` (`fix`).

**Plan metadata:** this summary is committed separately using GSD tooling.

## Decisions Made

- Actual capture claims depend on actual PNG bytes and complete current-candidate provenance; deterministic dry-run identity is not visual proof.
- The brandbook owns identity and token values; the Admin stylesheet owns semantic role mapping.
- Storybook examples isolate radio group names while production ThemePicker instances retain the shared component default.
- The browser review target is 768px for this evidence slice. The 320px Gallery overflow is deferred and is not represented as passing.

## Deviations from Plan

None. Task 3 included the plan-declared fixture radio-name adjustment established by the browser failure and verified in the passing isolated run.

## Issues Encountered

- The first commit attempt during the original execution could not write `.git/index.lock`. After repository write access was resolved, the three plan task commits were created through GSD tooling and verified as ancestors of the current `HEAD`.
- At 320px, existing Gallery content expands beyond the viewport because of a fixed-width logo and long-label card sizing. The plan's review smoke was verified at 768px; the 320px issue remains deferred.

## Deferred Issues

- The pre-existing fixed-width Gallery logo and expanded long-label card can create horizontal overflow at 320px. No Gallery layout implementation change was in this plan's scoped files; this behavior must not be treated as passing narrow-phone validation.
- Delivered-email client compatibility is outside browser preview evidence.

## Next Phase Readiness

- Plan 02 outputs are ready for Plan 03 to consume. Plan 03 should continue to use explicit browser spec selection and the shared Admin stylesheet; it should not infer 320px Gallery success from this 768px check.

## Self-Check: PASSED

- Summary file exists at the required phase path.
- Task commits `3143202c`, `e3ea43c3`, and `9cd4ec71` are ancestors of `HEAD`.
- The three commits measured from `plan_head_before` `ecdcd9b85f1c627e09a89193bd112eddbe9a62eb` through `plan_head_after` `9cd4ec71f3e056e8e5adca3112473ebc41bf12f2` match the recorded count of 3.
- The plan-owned changed files contain no newly introduced TODO, FIXME, placeholder, or coming-soon stubs.

---
*Phase: 173-consistency-and-delivery-evidence*
*Completed: 2026-10-10*
