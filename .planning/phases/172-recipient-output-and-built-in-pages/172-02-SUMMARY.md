---
phase: 172-recipient-output-and-built-in-pages
plan: "02"
subsystem: email-rendering
tags: [plaintext, floki, renderer, mailable-guides]

# Dependency graph
requires:
  - phase: 172-01
    provides: Public component link markers and the existing generated-text renderer path
provides:
  - Link-aware plaintext extraction for ordinary and nested anchors
  - Renderer coverage for ordered Unicode content, image alternatives, and generated-text replacement
  - Consistent generated-plaintext ownership guidance across five Mailable examples
affects: [MAILUX-03, renderer, authoring-guides]

# Actuals (#2632) — chars/4 over the realized plan diff; commits measured from the plan ledger.
actuals:
  tokens: 2862
  tasks: 3
  commits: 3
plan_head_before: 0ad57742554650409b771552bb66108bec991a6a
plan_head_after: b02b3c80dbb1dacbb5c96f1edfbe7e7674a9e3ff

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Traverse marked text children in source order so nested link destinations survive.
    - Keep link_pair terminal and derive rendered text before CSS inlining.

key-files:
  created: []
  modified:
    - lib/mailglass/renderer.ex
    - test/mailglass/renderer_test.exs
    - guides/authoring-mailables.md
    - guides/getting-started.md
    - guides/migration-from-swoosh.md
    - guides/jobs.md
    - guides/b2c-first-adopter.md
    - test/mailglass/docs_contract_test.exs

key-decisions:
  - "Keep Renderer.render/2 responsible for replacing text_body from rendered HTML, while retaining the public text_body/2 setter."
  - "Use the existing Floki traversal and central normalization; do not add a parser, dependency, or alternate MIME path."

patterns-established:
  - "Ordinary and marked anchors emit a meaningful label with each useful destination once."
  - "Unmarked paragraphs/headings retain reading order, and informative image alt text is included."

requirements-completed: [MAILUX-03]
coverage:
  - id: D1
    description: Generated plaintext keeps nested and ordinary link destinations, readable block order, Unicode text, and informative image alternatives.
    requirement: MAILUX-03
    verification:
      - kind: unit
        ref: test/mailglass/renderer_test.exs#to_plaintext/1
        status: pass
      - kind: integration
        ref: test/mailglass/renderer_test.exs#render replaces caller text with complete ordered Unicode plaintext
        status: pass
      - kind: integration
        ref: bash scripts/gsd-regression-gate.sh
        status: pass
    human_judgment: false
  - id: D2
    description: Five rendered Mailable examples accurately explain renderer-owned plaintext generation.
    requirement: MAILUX-03
    verification:
      - kind: unit
        ref: test/mailglass/docs_contract_test.exs#rendered Mailable guides use the generated-plaintext contract
        status: pass
    human_judgment: false

# Metrics
duration: 8min
completed: 2026-10-09
status: complete
---

# Phase 172 Plan 02: Recipient Output and Built-in Pages Summary

**Generated plaintext preserves actionable destinations, readable content order, Unicode, image alternatives, and the established renderer replacement contract.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-10-09T21:56:51Z
- **Completed:** 2026-10-09T22:02:58Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments

- Ordinary and nested anchors now retain readable labels and useful destinations once, including anchors inside `data-mg-plaintext="text"` elements.
- Plaintext preserves unmarked paragraph and heading boundaries, informative image alternatives, and long non-ASCII content. `Renderer.render/2` still replaces pre-set text with generated plaintext before CSS inlining and marker removal.
- The authoring, getting-started, Swoosh migration, jobs, and B2C guides now use the same documented generated-plaintext contract, with source HTML in the B2C example.

## Task Commits

Each task was committed atomically:

1. **Task 1: Retain ordinary and nested anchor destinations in plaintext** - `2b320406` (feat)
2. **Task 2: Guard message order, Unicode, image alternatives and renderer semantics** - `87ddeb30` (fix)
3. **Task 3: Align authoring guides with generated plaintext ownership** - `b02b3c80` (docs)

## Files Created/Modified

- `lib/mailglass/renderer.ex` - Link-aware traversal, ordinary image alt extraction, block separation, and punctuation whitespace normalization.
- `test/mailglass/renderer_test.exs` - Direct link cases and full render behavior assertions.
- `guides/authoring-mailables.md`, `guides/getting-started.md`, `guides/migration-from-swoosh.md`, `guides/jobs.md`, `guides/b2c-first-adopter.md` - Consistent generated-plaintext guidance and examples.
- `test/mailglass/docs_contract_test.exs` - Contract checks for canonical wording, guide links, and all five examples.

## Decisions Made

- Keep `Mailglass.Renderer.render/2` as the owner of generated `text_body`; retain `Mailglass.Message.text_body/2` as a public setter without presenting it as an override for rendered delivery.
- Reuse the existing Floki walker and normalization stage without adding a dependency or a second rendering path.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

- The first full regression-gate attempt could not launch Chromium within the sandbox. The same required gate was rerun with elevated execution and passed.
- **Review follow-up:** Code review found that `heading_block_*` flattened nested anchors before the link-aware walker could retain their destinations. The renderer now walks heading children, applies heading case to labels while preserving URL case, and has a regression case for a case-sensitive nested destination. The combined renderer and unsubscribe-guide contract suites pass (32 tests).

## Verification

- `ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix test test/mailglass/renderer_test.exs --warnings-as-errors --seed 1` - 25 tests, 0 failures.
- `ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix test test/mailglass/renderer_test.exs test/mailglass/components/vml_preservation_test.exs --warnings-as-errors --seed 1` - 30 tests, 0 failures.
- `ASDF_ERLANG_VERSION=27.3.4.13 ASDF_ELIXIR_VERSION=1.18.4-otp-27 asdf exec mix test test/mailglass/docs_contract_test.exs --warnings-as-errors --seed 1` - 61 tests, 0 failures, 1 skipped.
- `bash scripts/gsd-regression-gate.sh` - core 78 tests passed; Admin 593 tests passed with 1 excluded; inbound 3 properties and 480 tests passed with 3 excluded; connected browser suite 30 passed.

## Known Stubs

None found in files modified by this plan.

## Threat Flags

None. The changes add no network endpoints, authorization paths, file access, or schema changes.

## Next Phase Readiness

MAILUX-03 is covered by renderer and guide contracts. Plan 172-03 can proceed with the built-in unsubscribe pages.

## Self-Check: PASSED

All eight planned files and this summary exist. Task commits `2b320406`, `87ddeb30`, and `b02b3c80` are ancestors of HEAD.

---
*Phase: 172-recipient-output-and-built-in-pages*
*Completed: 2026-10-09*
