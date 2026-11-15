---
phase: 182-admin-words-and-layout-one-job-first
plan: 03
subsystem: admin-time-and-status-everywhere
tags: [compact-zoned-time, copy-control-name, screen-registry, render-scan, source-scan, static-js, mutation-proof]

requires:
  - phase: 182-02
    provides: Components.delivery_badge/1 and status_badge delivery context, the zone-keeping localizer, seed_phase182_journey!/0, Copy.class_labels/0
  - phase: 182-01
    provides: Components.status_mark/1, the true-or-nil lifecycle flags in outcome_groups
provides:
  - Components.display_time/1 and the compact zoned server form "Mon D, YYYY, H:MM AM UTC" for every Components.timestamp/1
  - timestamp/1 with the zone in its own span (a line below sm, inline from sm), no title, no aria-label on a plain time, a copy name that contains the visible time and the exact value
  - the timeline provider time, the support-card recorded time and the stale-results title routed through the one formatter
  - MailglassAdmin.TestSupport.ScreenRegistry (registry, known component modules, states, visible_text) for every later whole-admin contract
  - OperatorFixtures.seed_phase182_status_grid!/0
  - phase182_time_status_contract_test.exs (35 tests): registry equality, reverse checks, render scan, source scan, static JS, teeth
affects: [182-04 words contract reuses ScreenRegistry, 182-05 e2e pins, 182-06 advisory browser zone run and after-catalog]

actuals:
  tokens: 21068
  tasks: 2
  commits: 4
plan_head_before: 91c9f1e6ed863e35dc3d3efa373e858f41645771
plan_head_after: 642adc2bbade6824dbc636d566dcc855d247a803

tech-stack:
  added: []
  patterns:
    - "one display formatter returns {date-time text, zone}; the template and display_time/1 both read it, so a formatter that loses the zone shows on every screen"
    - "a separator that must survive whitespace-dropping readers is real text inside a node, not formatter whitespace between tags"
    - "whole-admin scan = router-derived route registry + per-state render scan + source scan + static JS check, each detector a pure function with planted-violation teeth"
    - "a producer contract (no false lifecycle flag) beside a consumer scan, because the consumer is self-consistent over a false flag"

key-files:
  created:
    - mailglass_admin/test/mailglass_admin/phase182_time_status_contract_test.exs
    - mailglass_admin/test/support/screen_registry.ex
    - mailglass_admin/test/mailglass_admin/operator/timeline_provider_time_test.exs
  modified:
    - mailglass_admin/lib/mailglass_admin/components.ex
    - mailglass_admin/lib/mailglass_admin/controllers/assets.ex
    - mailglass_admin/lib/mailglass_admin/operator/timeline.ex
    - mailglass_admin/lib/mailglass_admin/operator/support_cards.ex
    - mailglass_admin/lib/mailglass_admin/operator/results_status.ex
    - mailglass_admin/priv/static/app.css
    - mailglass_admin/test/support/operator_fixtures.ex
    - mailglass_admin/test/mailglass_admin/components_test.exs
    - mailglass_admin/test/mailglass_admin/operator/health_overview_test.exs
    - mailglass_admin/test/mailglass_admin/operator/results_status_test.exs
    - mailglass_admin/test/mailglass_admin/inbound/evidence_card_test.exs
    - mailglass_admin/test/mailglass_admin/inbound_live_test.exs
    - mailglass_admin/test/mailglass_admin/operator_live_test.exs
    - mailglass_admin/test/mailglass_admin/phase182_journey_test.exs
    - mailglass_admin/e2e/flows.spec.js
    - mailglass_admin/e2e/inbound-layout.spec.js
    - mailglass_admin/e2e/operator.spec.js
    - mailglass_admin/e2e/phase168-plan03-acceptance.spec.js
    - .planning/research/brand-v2-adoption/before-catalog/before-9eb9dee-20261115T022124Z/superseded.json
    - .planning/phases/182-admin-words-and-layout-one-job-first/182-02-SUMMARY.md

key-decisions:
  - "The persisted status grid is 160 rows, not 170: last_event_type is NOT NULL and required by Delivery.changeset/1, so the nil cells cannot be stored. The 10 nil cells (5 statuses x 2 confirmed) render in memory through the list, Quick view and detail header, and the test asserts persisted + in-memory = statuses x (events + 1) x 2 = 170 from the live enums."
  - "A timestamp's copy control is named 'Copy <visible time> (copies the exact UTC value <exact>)'. The plan's 'Copy <visible time> (copies the exact UTC value)' broke Phase 176 P10, which requires a copy control's name to contain the value it copies; the longer name keeps the visible text for WCAG 2.5.3 and adds the value. The localizer writes the same shape from data-copy-value."
  - "The space between the date-time text and the zone is real text ending the first span, because Floki drops whitespace-only nodes between tags and every Floki-based reader saw 'PMUTC'. A browser collapses it at the line end below sm and keeps it from sm up."
  - "The zone comes from display_parts/1, not a literal in the template, so dropping the zone from the formatter reddens every screen (mutation M1 is otherwise unobservable)."
  - "A source rule pins the <time> element to Components.timestamp/1 (including inside components.ex), because a render scan cannot see a new component no screen renders yet."
  - "The Gallery is scanned as a dead render: it repeats a few element ids across specimens by design (the existing 39-id floor), which LiveViewTest rejects on re-render."
  - "The proximity zone token needs three letters, so a two-letter word such as ID is not mistaken for a zone; AM and PM are never zones."
  - "A false lifecycle flag is guarded at the producer (an admin-lane read-model test), not by the screen scan: the screen renders a false flag consistently as Failed."

requirements-completed: [BRADM-02]

coverage:
  - id: D1
    description: "Every server-rendered <time> shows 'Mon D, YYYY, H:MM AM UTC' as visible text, keeps datetime in ISO 8601, and keeps the full-precision UTC value in data-utc, data-copy-value and the tooltip"
    requirement: BRADM-02
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/components_test.exs#timestamp/1 (compact zoned time, display_time/1, precise value)"
        status: pass
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/phase182_time_status_contract_test.exs#render scan over every registered state (D-18)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The zone is its own span, block below sm and inline from sm, written by the server and by the localizer in the same two parts"
    requirement: BRADM-02
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/components_test.exs#the zone is its own span (D-08), plus mix mailglass_admin.assets.build --check for the sm:inline utility"
        status: pass
      - kind: other
        ref: "stub-DOM run of the served localize() under UTC, America/New_York and Pacific/Auckland (one-off, not committed); the rendered line break at 375px is the advisory 182-06 journey"
        status: pass
    human_judgment: false
  - id: D3
    description: "The timeline provider time, the support-card recorded time and the stale-results title go through the one formatter; an unparseable provider value is labelled as the provider's raw text and escaped"
    requirement: BRADM-02
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/operator/timeline_provider_time_test.exs (6 tests)"
        status: pass
    human_judgment: false
  - id: D4
    description: "No title on a timestamp or copy control, no aria-label on a plain <time>, a copy control's name contains the visible time and the exact value, on every registered screen"
    requirement: BRADM-02
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/phase182_time_status_contract_test.exs#a title on a timestamp, an aria-label on a time, or a copy name that omits the time or the value is flagged, and the render scan"
        status: pass
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/phase176_prohibition_contract_test.exs#P10 copy controls name the value they copy"
        status: pass
    human_judgment: false
  - id: D5
    description: "The LiveView routes of the test adopter router equal the registry; a module exporting __live__/0 or __components__/0 is registered or listed; every registry kind has a state"
    requirement: BRADM-02
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/phase182_time_status_contract_test.exs#screen registry (D-18)"
        status: pass
    human_judgment: false
  - id: D6
    description: "Across every registered state every <time> ends in a zone token, other timestamp-shaped text has a zone within 12 characters, every [data-mg-status] is one aria-hidden svg beside a class word, every .badge has text and a class-word badge without the mark fails unless inbound"
    requirement: BRADM-02
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/phase182_time_status_contract_test.exs#render scan over every registered state (D-18), floors: 170-cell grid, marks >= 170, times >= 100, states >= 10"
        status: pass
    human_judgment: false
  - id: D7
    description: "strftime, to_iso8601, DateTime.to_string, hand-written badges, <time> elements and raw HTML stay in their owners; the Mix task is the only formatter outside lib/mailglass_admin"
    requirement: BRADM-02
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/phase182_time_status_contract_test.exs#source scan (D-18)"
        status: pass
    human_judgment: false
  - id: D8
    description: "The browser localizer's FMT keeps timeZoneName and the call keeps en-US (closes 182-02 coverage item D6)"
    requirement: BRADM-02
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/phase182_time_status_contract_test.exs#static JS (D-18), mutation M5"
        status: pass
    human_judgment: false
  - id: D9
    description: "Components.timestamp(at: nil) renders the word Unavailable and no <time>, and the scan counts it as zero times"
    requirement: BRADM-02
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/phase182_time_status_contract_test.exs#an unavailable time is the word Unavailable and no <time> element"
        status: pass
    human_judgment: false
  - id: D10
    description: "No operator read model sends a false lifecycle flag (a producer would flip every class to Failed)"
    requirement: BRADM-02
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/phase182_time_status_contract_test.exs#no operator read model sends a false lifecycle flag (C-4), producer mutation recorded below"
        status: pass
    human_judgment: false

duration: 26min
completed: 2026-11-15
status: complete
---

# Phase 182 Plan 03: Every time with its zone, every status a mark and a word, and a contract no new screen escapes

**Every admin time renders from one component as `Nov 15, 2026, 2:05 PM UTC` (zone on its own line below `sm`, exact UTC value kept for copying), the D-09 offenders went through it, and a 35-test contract scans 160 DB rows, 10 in-memory rows, 18 journey states, the Gallery, Preview and Inbound for zoneless times and word-less statuses, with nine recorded mutations that turn it red.**

## Performance

- **Duration:** about 26 min (start 2026-11-15T22:34:55Z, end 23:00Z)
- **Execute-start SHA:** `91c9f1e6ed863e35dc3d3efa373e858f41645771`
- **Tasks:** 2 (1 tracer, 1 TDD-flagged auto)
- **Commits:** 4 production commits, measured by `git rev-list --count 91c9f1e6..HEAD` = 4 (this summary and the state update come after)
- **Files changed:** 21 outside `.planning`
- **Tokens (chars/4 over the realized diff, bundle excluded):** about 21,100 against the plan's 96,000 estimate (low confidence; about 4.6x high)

## Accomplishments

- A time is one thing everywhere. `Components.timestamp/1` renders the compact zoned form, keeps `datetime` in ISO 8601, and keeps the exact value (`2026-11-15 14:05:09.123456 UTC`) in `data-utc`, `data-copy-value` and the tooltip. The zone is a child span, `block sm:inline`; the localizer rewrites both parts, so 375px keeps the zone under the time after JS runs.
- `title` and the plain `<time>`'s `aria-label` are gone. The copy control's name is `Copy <visible time> (copies the exact UTC value <exact>)`, so it contains what a reader sees (WCAG 2.5.3) and what it copies (Phase 176 P10).
- The three D-09 offenders go through the formatter: the timeline provider time is parsed with `DateTime.from_iso8601/1` and drawn by `timestamp/1` (an unparseable value is labelled as the provider's raw text inside `data-raw-provider-time`, escaped), the support card's recorded time is a `timestamp/1`, and the stale-results title uses `display_time/1`.
- `ScreenRegistry` lists the five `{LiveView, action}` pairs the router mounts, the 32 component modules with the state that renders each, and the concrete states for whatever fixtures a caller seeded. 182-04 reads the same list.
- `phase182_time_status_contract_test.exs` enforces D-18 in the required admin lane in about 3 seconds.

## Task Commits

1. **Task 1 (tracer)**: `a604880c` feat(admin): show every time with its zone in a compact form. Tracer gate: no `gate="blocking-human"`, `HUMAN_VERIFY_MODE` end-of-phase with an automated-only `<verify>`; the verify was re-run after the commit (433 tests, 0 failures, bundle and conformance clean) and logged "Tracer verified end-to-end, expanding".
2. `fd6a042c` refactor(admin): derive the visible zone from the one display formatter (needed so mutation M1 is observable; output unchanged)
3. **Task 2**: `1b56b599` test(admin): contract every admin time and status across a screen registry
4. `642adc2b` fix(admin): name the exact value in a timestamp's copy control (Deviation 2)

## Mutation proofs

All nine run on real source with the named required-lane test going red, then the source restored from a backup copy (`git diff --stat -- lib priv` empty after each). Test names are the contract's; "contract" below means `phase182_time_status_contract_test.exs`.

| # | Mutation | Result |
|---|---|---|
| M1 | `display_parts/1` returns an empty zone (drops the zone from the formatter; the plan's "drop the zone from display_time/1", see Deviation 4) | 7 red: render scan x6 (Preview and the Gallery; the Operator over the 170-cell grid; the journey histories; the replay modal; a provider time; the Inbound list and detail) and "a real status badge and a real timestamp are clean" |
| M2 | a new function component with a bare `<time datetime={@at}>` in `components.ex` | 2 red: "source scan: time formatting, hand-written badges and raw HTML stay in their owners" and "source scan: Components.timestamp/1 is the only `<time>` emitter" |
| M3 | `delivery_badge` renders `word=""` | 6 red: render scan x5 (Preview and Gallery, the grid, the journey, replay, a provider time) and "a false lifecycle flag reads as a recorded fact" |
| M4 | `@mutant_badge ~S\|<span class="badge">Failed</span>\|` in `operator_live.ex` | 1 red: "source scan: time formatting, hand-written badges and raw HTML stay in their owners" |
| M5 | remove `timeZoneName` from `FMT` in `assets.ex` | 1 red: "static JS (D-18): the localizer keeps a zone token and a fixed locale" (closes 182-02's open M6) |
| M6 | a stub `use Phoenix.LiveView` module under `lib/`, unregistered | 1 red: "screen registry: every loaded admin module that exports __live__/0 or __components__/0 is registered" |
| M7 | `aria-label="mark"` on the `status_mark` svg | 7 red: render scan x5, "a real status badge and a real timestamp are clean", "a false lifecycle flag reads as a recorded fact" |
| M8 | `bounced_at: false` on every in-memory grid row | **0 red, by design.** The screen renders the false flag consistently as `Failed` (mark and word agree), so a consumer scan cannot see it; the teeth test "a false lifecycle flag reads as a recorded fact" pins the flip (`delivery_class/1` is `:failed` for `false`, `:sent` for `nil`). The guard is the producer: mutating core `outcome_groups` to emit `not is_nil(bounced_at)` (then restored) turns "no operator read model sends a false lifecycle flag (C-4)" red, and nothing else in the file |
| M9 | `@mark_atoms` loses `:delivered` (the delivered status badge draws its heroicon again) | 2 red: "render scan: Preview and the Gallery show every time with a zone and every status with a word" (the Gallery's delivered specimen reads a class word with no mark) and "a real status badge and a real timestamp are clean" |

## Changed pins (D-14)

Only assertions on the long visible time, a removed `title`, or the copy name changed. Assertions on `data-utc`, `data-copy-value` and the tooltip stay exact.

- `components_test.exs`: the `timestamp/1` describe is rewritten into six tests (compact zoned time and exact attributes; the zone span with `block sm:inline`; a plain time with no `title` and no `aria-label`; `display_time/1` including 12 AM, 12 PM and an unpadded day; a precise value shows compact and copies fractional seconds). The `copy_value` attribute-name list drops `title`.
- `inbound/evidence_card_test.exs:137`: the Received fact reads `Oct 1, 2026, 12:30 PM UTC` and keeps the exact value in the tooltip (the old assertion would have passed on the tooltip alone).
- `operator/health_overview_test.exs`: four stale notices read `Showing results from Oct 28, 2026, 12:00 PM UTC.`
- `operator/results_status_test.exs`: three titles read `Oct 28, 2026, 2:05 PM UTC` and `Oct 28, 2026, 9:01 AM UTC`.
- `operator_live_test.exs`: the stale-title literal and two regexes. `inbound_live_test.exs`: the stale-title literal and one regex.
- `phase182_journey_test.exs`: "Delivered at" now allows a month name.
- Advisory e2e (each `node --check` clean, none run in a browser): `flows.spec.js` (the provider line begins `Provider time`), `inbound-layout.spec.js`, `phase168-plan03-acceptance.spec.js` and `operator.spec.js` (the copy name carries the exact value).
- Unchanged on purpose: `operator_live_test.exs:851` (`data-utc` exact) and `inbound_live_test.exs:581` (`data-copy-value` equals `timestamp_value/1`).
- New file beyond the plan's list: `operator/timeline_provider_time_test.exs` (6 tests) pins the provider-time branches (T-182-07).

## Scan floors observed

`PHASE182_REPORT=1 mix test ... phase182_time_status_contract_test.exs --seed 0` prints these per world.

| World | States | `<time>` | `[data-mg-status]` | `.badge` |
|---|---|---|---|---|
| Preview index and show, Gallery | 3 | 32 | 26 | 65 |
| Status grid (160 DB rows) and the 10 nil cells | 72 (51 mounted + 21 component renders) | 1275 | 1242 | 1284 |
| Journey histories (9 Quick views, 9 Full details) | 18 | 197 | 180 | 198 |
| Replay modal | 1 | 5 | 3 | 3 |
| 101-event timeline with a provider time | 1 | 101 | 1 | 3 |
| Inbound list and 7 records, Quick and Full | 15 | 148 | 0 | 145 |
| **Total** | **110** | **1758** | **1452** | **1698** |

Floors asserted: grid universe 170 (computed from `Ecto.Enum.values(Delivery, :status)` and `Delivery.__event_types__/0`: persisted 5 x 16 x 2 = 160 plus 5 x 2 = 10 nil cells), `[data-mg-status]` at least 170 (observed 1242), `<time>` at least 100 (observed 1275), registered states at least 10 (observed 110), Activity pages 8, Quick view and Full detail at least one per last event type (21 each), at least one inbound class-word badge exercising the exemption.

## Verification

Plan-end order (D-24), all with the ASDF exports:

| Step | Result |
|---|---|
| admin `mix format --check-formatted` | clean |
| admin `mix mailglass_admin.assets.build --check` | "Admin bundle matches a fresh build (138536 bytes)"; the bundle gained only `.sm\:inline{display:inline}` (+27 bytes), sha256 `fc2df1a7...c1f0`, `superseded.json` rebound in `a604880c` |
| Task 2 verify (contract, status marks, persona drift guard, `--warnings-as-errors --seed 0`) | 59 tests, 0 failures, 3.7 s wall (limit 60 s) |
| scoped contracts and the four Phase 182 files plus the provider-time test | 300 tests, 0 failures |
| `bash scripts/check-conformance.sh` | "OK: design-system conformance clean." |
| root `bash scripts/check_test_exceptions.sh` | "OK: test exception registry is complete and unexpired." |
| admin `mix verify.support_contract.admin` | 1649 tests, 0 failures, 1 excluded, exit 0 |

Core and inbound are untouched (`git diff 91c9f1e6..HEAD -- lib priv mailglass_inbound` is empty; the one core edit during M8 was restored before any commit), so their suites were not run.

## TDD notes

Plan type is `execute`, so no plan-level gate sequence applies. The detectors were written with their planted-violation tests in the same pass; the strength is the nine-mutation table above, each shown red on a real source edit, plus M8's producer variant.

The browser check of the localizer under `America/New_York` and `Pacific/Auckland` is advisory and lives in the 182-06 catalog journey spec; this plan's required proof is the SSR scan plus the static `FMT` check. A one-off stub-DOM run of the served `localize()` under UTC, America/New_York and Pacific/Auckland produced `Nov 15, 2026, 2:05 PM | UTC`, `9:05 AM | EST` and `Nov 16, 2026, 3:05 AM | GMT+13` with the matching copy names; it is not committed and is not cited as required proof.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug in plan] The nil last-event cell cannot be persisted**
- **Found during:** Task 2 (reading `Delivery`)
- **Issue:** the plan seeds 5 x 17 x 2 = 170 rows including `last_event_type: nil`, but the column is `NOT NULL` and `Delivery.changeset/1` requires it, so no persisted row can carry nil.
- **Fix:** `seed_phase182_status_grid!/0` seeds the 160 storable cells; the 10 nil cells render in memory through the list, Quick view and detail header. The test asserts persisted + in-memory equals the plan's computed product, so the 170 floor holds.
- **Files:** `mailglass_admin/test/support/operator_fixtures.ex`, the contract test. **Commit:** `1b56b599`

**2. [Rule 1 - Bug] The plan's copy-control name broke Phase 176 P10**
- **Found during:** plan-end `mix verify.support_contract.admin` (2 failures in `phase176_prohibition_contract_test.exs`)
- **Issue:** `Copy <visible time> (copies the exact UTC value)` contains the visible text but not the value the control copies, which P10 requires.
- **Fix:** the name is now `Copy <visible time> (copies the exact UTC value <exact>)`, server and localizer; the contract gained `copy_label_omits_value`; e2e pins follow.
- **Files:** `components.ex`, `controllers/assets.ex`, `components_test.exs`, the contract test, three e2e specs. **Commit:** `642adc2b`

**3. [Rule 2 - Missing critical] A whitespace-only node between the spans is dropped by Floki**
- **Found during:** Task 1 first run (`Oct 28, 2026, 12:00 PMUTC`)
- **Issue:** the HEEx formatter put the separator between tags as whitespace; Floki drops those nodes, so every Floki reader (including the D-18 scan) saw the zone glued to `PM`.
- **Fix:** the first span's text ends in a real space (`{@when_text <> " "}`), the localizer writes the same.
- **Commit:** `a604880c`

**4. [Rule 2 - Missing critical] Mutation 1 was unobservable as written**
- **Found during:** Task 2 design
- **Issue:** the zone was a literal `UTC` in the template, so dropping it from `display_time/1` changed only the stale title and an aria-label, neither on a scanned screen.
- **Fix:** `display_parts/1` returns `{text, zone}`; the span and `display_time/1` both read it. M1 above edits `display_parts/1`.
- **Commit:** `fd6a042c`

**5. [Rule 2 - Missing critical] A render scan cannot see an unrendered component**
- **Found during:** Task 2 design (mutation M2)
- **Issue:** a bare `<time>` in a component no screen renders passes every render scan.
- **Fix:** a source rule restricts `<time` elements to the body of `timestamp/1` (docs and comments excluded), with teeth inside `components.ex`.
- **Commit:** `1b56b599`

**6. [Rule 3 - Blocking] LiveViewTest rejects the Gallery's repeated ids on re-render**
- **Found during:** Task 2 first run
- **Fix:** states carry `mount: :dead | :live`; the Gallery is read once with `get/2`, as `root_theme_ownership_contract_test` does.
- **Commit:** `1b56b599`

**7. [Rule 2 - Missing critical] An in-contract producer guard for the false-flag case**
- **Found during:** M8 (the screen scan stays green over a false flag)
- **Fix:** "no operator read model sends a false lifecycle flag (C-4)" reads a real page and its `outcome_groups`; proven red by a core mutation, then restored.
- **Commit:** `1b56b599`

Smaller adjustments: `ScreenRegistry.states/1` returns maps (`label`, `kind`, `route`, `path`, `mount`, `hooks`, `expect`) instead of `{label, path}` pairs, because the replay modal needs events after mount and every state needs an `expect` selector against a vacuous pass; a `:journey` world was added (nine histories with events) so timelines are scanned; AM and PM are excluded from the `[A-Z]{2,5}` zone alternative, and the proximity token needs three letters; `Components.timestamp/1`'s `@doc` was rewritten as planned.

**Total deviations:** 7 (2 bugs, 4 missing-critical, 1 blocking). **Impact on plan:** none on scope; every plan truth holds, with the nil-cell and copy-name differences stated above.

## Issues Encountered

- `Phase164RepositoryTruthTest` "git runtime rules do not conceal the retired finalize-phase extension paths" fails in a root core run because of the untracked `.gsd/.gitignore` (logged in `deferred-items.md` by 182-01). It lives in the core suite, which this plan does not touch or run.
- The bundle needed `sm:inline`: rebuilt once, `superseded.json` rebound in the same commit as the plan's `<decisions_recorded>` said.

## Known Stubs

None. Every new function renders real data; the `report/2` helper in the contract only prints counts when `PHASE182_REPORT` is set.

## Threat Flags

None beyond the plan's threat model. T-182-07: a provider time is parsed with `DateTime.from_iso8601/1`; an unparseable value renders escaped inside `data-raw-provider-time` (`timeline_provider_time_test` plants `<img onerror>` and `<script>` and asserts they stay text), and the source scan bans `Phoenix.HTML.raw` outside the root layout. T-182-08: the zone is always visible and the exact UTC value stays in the tooltip, the copy value and the copy control's name.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- 182-04 (words) can scan the same screens with `ScreenRegistry.states/1` and `ScreenRegistry.visible_text/1`; the known-component list already names the state that renders each module.
- 182-05 inherits the e2e copy-name and provider-line pins updated here.
- 182-06 owns the advisory browser run under `America/New_York` and `Pacific/Auckland` and the 375px layout of the split zone. Any later change to `app.css` or the root layout needs another `superseded.json` rebind (current bundle sha256 `fc2df1a788e0089beb3c9778582917e0b5cbe10d231795ea05f23e757fadc1f0`).
- BRADM-02 is declared by sibling plans too; the shared-ID gate leaves REQUIREMENTS.md to the phase-complete step.

## Self-Check: PASSED

All created files exist (`phase182_time_status_contract_test.exs`, `screen_registry.ex`, `timeline_provider_time_test.exs`); `def display_time` is in `components.ex` and `def seed_phase182_status_grid!` in `operator_fixtures.ex`; all four commits (`a604880c`, `fd6a042c`, `1b56b599`, `642adc2b`) are ancestors of HEAD; the working tree has no uncommitted `lib` or `priv` change; `mix format --check-formatted` is clean.

---
*Phase: 182-admin-words-and-layout-one-job-first*
*Completed: 2026-11-15*
