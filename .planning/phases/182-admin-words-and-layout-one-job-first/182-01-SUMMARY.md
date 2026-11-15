---
phase: 182-admin-words-and-layout-one-job-first
plan: 01
subsystem: admin-operator-read-model
tags: [operator-projection, delivery-class, status-marks, brand-pin, contract-tests, mutation-proof]

requires:
  - phase: 179-compatibility-policy-status-map-and-brand-pin
    provides: StatusMap.delivery_class/1, the operator-projection limitation hand-off, the brand pin
  - phase: 181-brand-v2-tokens-fonts-and-logo
    provides: brandbook/tokens.json, the mg color roles the marks paint with, Contrast test helper
provides:
  - Mailglass.Operator.Deliveries rows carry bounced_at, terminal, delivered_at, complained_at, suppressed_at
  - outcome_groups carry true-or-nil bounced_at, terminal, complained_at, suppressed_at flags
  - Summary on /ops/mail bucketed by StatusMap.delivery_class/1 with an honest undetermined fallback
  - brandbook/status-marks.json (five pane-mark geometries pinned to the book zip) and its extractor
  - MailglassAdmin.Components.status_mark/1 (attribute-only SVG, aria-hidden) plus gallery specimens
  - OperatorFixtures.seed_phase182_journey!/0 (nine password-reset histories)
affects: [182-02 verdict and cause, 182-03 time and status everywhere, 182-04 words, 182-05 after-catalog]

actuals:
  tokens: 20861
  tasks: 3
  commits: 7
plan_head_before: 78dcb7d0435ebe75c12f11d46d3a71faeb852daf
plan_head_after: 92e18c3cd1fda643e65689926dba660347e3f245

tech-stack:
  added: []
  patterns:
    - "true-or-nil lifecycle flags in grouped read models (a false reads as a recorded fact)"
    - "pinned geometry JSON outside the pin-owned directory, component carries a literal copy, test compares the two"
    - "extractor reads the brand zip in memory after the sha256 check, never writes the book HTML"

key-files:
  created:
    - test/mailglass/operator/deliveries_projection_test.exs
    - mailglass_admin/test/mailglass_admin/phase182_journey_test.exs
    - mailglass_admin/test/mailglass_admin/phase182_status_marks_test.exs
    - brandbook/status-marks.json
    - scripts/brand_status_marks.exs
    - test/scripts/brand_status_marks_test.exs
    - .planning/phases/182-admin-words-and-layout-one-job-first/deferred-items.md
  modified:
    - lib/mailglass/operator/deliveries.ex
    - docs/api_stability.md
    - mailglass_admin/docs/api_stability.md
    - mailglass_admin/lib/mailglass_admin/status_map.ex
    - mailglass_admin/lib/mailglass_admin/operator_live.ex
    - mailglass_admin/lib/mailglass_admin/components.ex
    - mailglass_admin/lib/mailglass_admin/gallery_live.ex
    - mailglass_admin/test/support/operator_fixtures.ex
    - mailglass_admin/test/mailglass_admin/status_map_test.exs
    - mailglass_admin/test/mailglass_admin/copy_contract_test.exs

key-decisions:
  - "outcome_groups flags use CASE ... THEN true END in both group_by and select, so a bounced-then-opened row is its own group and no flag is ever false (A1 proven by the DB test, no fallback form needed)"
  - "Marks colour with var(--mg-color-<token>) attributes and no CSS class, so mailglass_admin/priv/static/app.css and superseded.json did not change"
  - "Extractor copies sha256_hex and the in-memory zip read instead of loading brand_pin.exs in library mode, which would race brand_pin_test over the shared script_library_mode application env"
  - "copy_contract @status_phrases drops from 23 to 22 entries: the rewritten Needs attention help is lowercase prose and no longer carries a status word"
  - "The shared-ID gate held BRADM-01 and BRADM-02 incomplete in REQUIREMENTS.md; sibling plans 182-02..05 also declare them"

patterns-established:
  - "Mutation protocol: edit real source, watch the named test go red, restore; a mutation that breaks SQL instead of the guard is invalid and is redone in lockstep"
  - "Hermetic script test: planted HTML, in-memory :zip.create/3, no network, no tree writes"

requirements-completed: [BRADM-01, BRADM-02]

coverage:
  - id: D1
    description: "Operator list rows and get_delivery return bounced_at, terminal, delivered_at, complained_at, suppressed_at; every pre-existing key stays present; histories bounce-open, bounce-click, rejected-open, delivered-bounce keep the failure evidence"
    requirement: BRADM-01
    verification:
      - kind: integration
        ref: "test/mailglass/operator/deliveries_projection_test.exs (10 tests, DB-backed, real Projector histories)"
        status: pass
    human_judgment: false
  - id: D2
    description: "outcome_groups carry true-or-nil flags and keep a bounced-then-opened row apart from ordinary opened rows"
    requirement: BRADM-01
    verification:
      - kind: integration
        ref: "test/mailglass/operator/deliveries_projection_test.exs#outcome group flags are true or nil, never false"
        status: pass
    human_judgment: false
  - id: D3
    description: "Summary on /ops/mail counts by delivery class: Needs attention = failed + delayed + not sent, Delivered, Awaiting = sent (queued included); a bounce then open counts under Needs attention"
    requirement: BRADM-01
    verification:
      - kind: integration
        ref: "mailglass_admin/test/mailglass_admin/phase182_journey_test.exs#summary (D-07) and #summary re-bucket (C-16)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Summary renders 'Status cannot be fully determined with this mailglass version.' instead of counts when any outcome group lacks the lifecycle keys"
    requirement: BRADM-01
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/phase182_journey_test.exs#summary without lifecycle keys (D-06)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Five pane-mark geometries pinned with zip and member sha256, extracted in memory, JSON outside brandbook/v2"
    requirement: BRADM-02
    verification:
      - kind: unit
        ref: "test/scripts/brand_status_marks_test.exs (19 tests) and test/scripts/brand_pin_test.exs"
        status: pass
    human_judgment: false
  - id: D6
    description: "Components.status_mark/1 renders each mark aria-hidden with no aria-label, title or class, equal to the pin, 3:1 against the surface in light and dark, pairwise distinct in shape"
    requirement: BRADM-02
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/phase182_status_marks_test.exs (16 tests)"
        status: pass
    human_judgment: false
  - id: D7
    description: "api_stability pages state operator read-model maps may gain keys in a minor release"
    verification:
      - kind: unit
        ref: "mailglass_admin/test/mailglass_admin/stability_contract_test.exs, brand_v2_compat_policy_test.exs, test/mailglass/docs_contract_test.exs (unedited, green)"
        status: pass
    human_judgment: false

duration: 20min
completed: 2026-11-15
status: complete
---

# Phase 182 Plan 01: Operator read model tells the truth, summary re-bucketed, pane marks pinned

**Additive core projection (bounced_at, terminal, delivered_at, complained_at, suppressed_at) so a bounce followed by an open is Failed and counted under Needs attention, plus the five brand pane marks pinned from the book zip and rendered by an attribute-only `Components.status_mark/1`.**

## Performance

- **Duration:** about 20 min (the executor did not record a start timestamp; first command at about 16:49 EST, SUMMARY written at 17:10 EST, 2026-11-15)
- **Execute-start SHA:** `78dcb7d0435ebe75c12f11d46d3a71faeb852daf`
- **Tasks:** 3 (1 tracer, 2 TDD-flagged auto)
- **Commits:** 7 production commits, measured by `git rev-list --count 78dcb7d0..92e18c3c` = 7
- **Files changed:** 16 (excluding `.planning`)
- **Tokens (chars/4 over the realized diff):** 20,861 against the plan's 118,000 estimate. The estimate was low-confidence with zero samples and ran about 5.6x high.

## Accomplishments

- A bounce followed by an open no longer reads Delivered. The operator projection now returns the lifecycle fields, `StatusMap.delivery_class/1` reads them, and the summary counts that row under Needs attention (core `6b1e8016`, admin `2f312ef7`).
- Core contract is mutation-proven (below) and documented as additive in both `api_stability` pages (`1d89e59b`, `aa09c066`).
- The summary help text now describes the class rule truthfully, and an older core that returns the three-field shape yields "Status cannot be fully determined with this mailglass version." instead of confident counts (`de298525`).
- The five brand pane marks are pinned in `brandbook/status-marks.json` with the zip and member sha256, extracted by a script that reads the book HTML from the pinned zip in memory and never writes it (`3e67bdd9`).
- `Components.status_mark/1` draws them as `aria-hidden` SVG with no label, title or class, so the compiled bundle did not change; one row-size specimen per class and one detail specimen are in the gallery (`92e18c3c`).

## Task Commits

1. **Task 1 (tracer)**: `6b1e8016` feat(core) projection and flags with its core test; `2f312ef7` feat(admin) summary by delivery class, `seed_phase182_journey!/0`, first journey describe
2. **Task 2**: `1d89e59b` test(core) four-history matrix and additive-only guard; `aa09c066` docs sentence in both api_stability pages; `de298525` feat(admin) truthful help, D-06 fallback, StatusMap cleanup, re-bucket coverage
3. **Task 3**: `3e67bdd9` chore(brand) extractor, its hermetic test and the JSON; `92e18c3c` feat(admin) component, gallery specimens, marks contract test

Tracer gate: the tracer carried no `gate="blocking-human"`; both `<verify>` commands were re-run end to end after the tracer commits (13 core tests, 176 admin tests, 0 failures) before expansion.

## Mutation proofs

All run by hand against real source, with the named test going red, then the source restored (`git diff` empty after each).

**Core projection (Task 2, file `test/mailglass/operator/deliveries_projection_test.exs`)**

| # | Mutation | Result |
|---|---|---|
| M1 | delete `bounced_at` from `delivery_projection/1` | 7 red, first: "bounce then open both read functions return the stored lifecycle fields" (KeyError `:bounced_at`), plus the four failure-history tests, complaint and suppression tests |
| M2 | delete `terminal` from `delivery_projection/1` | 7 red, same names (KeyError `:terminal`) |
| M3 | emit `false` from a timestamp flag: `bounced_at` as `not is_nil(...)` in both `group_by` and `select` | 2 red: "outcome group flags are true or nil, never false, for every flag and every history" and "outcome groups keep a bounced then opened row apart from an ordinary opened row". Repeated for `suppressed_at`: 1 red, the no-false test |
| M4 | replace the terminal fragment with the bare `delivery.terminal` in both places | 2 red: the no-false test (`:terminal must be true or nil, got false`) and the groups-apart test |

A first attempt at M3 changed only the `select`, which broke the SQL (Postgres requires the expression in `GROUP BY`) and failed 8 tests for the wrong reason. It was discarded and redone with `group_by` and `select` in lockstep, as above.

**Summary (admin, `phase182_journey_test.exs`)**

| # | Mutation | Result |
|---|---|---|
| S0 | restore the pre-plan `delivery_display_status` bucketing | both summary tests red |
| S1 | skip the missing-key check in `delivery_summary/1` | 2 red: both D-06 "undetermined" tests |
| S2 | bucket `:not_sent` as awaiting | 3 red: "counts every seeded delivery under the bucket its class names", "not sent lands in attention", "Needs attention is exactly failed, delayed and not sent" |
| S3 | count a complained row as attention | 3 red: the seeded-count test, "complained with no delivery problem lands in awaiting", the exactly-three test |

**Marks (admin, `phase182_status_marks_test.exs`)**

| # | Mutation | Result |
|---|---|---|
| T1 | planted `aria-label` on the rendered mark in `components.ex` | 3 red: "every class and size renders shape-for-shape what the JSON pins", "a status mark adds no CSS class and no title", "the render check rejects a planted aria-label, title, class and wrong size" |
| T2 | changed one `d` (check mark) in the component copy | 2 red: "the literal copy in components.ex equals brandbook/status-marks.json", the render test |
| T3 | swapped the `ok` and `bad` roles in the component | 4 red including "the role map equals the JSON roles" |
| T4 | `not_sent` shape list made identical to `delayed` in the pinned JSON | 5 red including "the five marks differ in shape, not in colour alone" and "two identical shape lists are flagged" |
| T5 | compile-time `File.read!` of the JSON in `components.ex` (guard mutation: the `grep -rc 'status-marks.json' mailglass_admin/lib` count goes 0 to 1) | 1 red: "lib never reads or names the pinned JSON" |

**Extractor (`test/scripts/brand_status_marks_test.exs`)**: skipping the zip sha256 check turns 2 tests red ("a zip whose sha256 differs from the pin is refused", "the hash is checked before any member is read"); classifying the filled-half frame as `delayed` turns 7 red.

## Advisory online verify

`mix run --no-start scripts/brand_status_marks.exs verify` (downloaded the pinned URL, no `--zip`): `status marks match the pinned book`. A local `--zip` verify matched; a one-digit tamper of the committed JSON made `verify` fail with "the committed JSON differs". The book HTML was never written to disk; the zip sha256 `ed96bb25...f87b` and member sha256 `1699d693...4db8` match the pin.

## TDD notes

The plan type is `execute`, so the plan-level gate sequence does not apply. Task 1's core test was genuinely RED first: 3 failures against the unmodified read model (KeyError `:bounced_at`; one merged group with `count: 2`; missing key in the group), then GREEN after the core change. Tasks 2 and 3 pin behavior Task 1 already implemented or generated data from the book, so their tests could not go RED against absent code; they were not written RED-first. Their strength is the mutation proofs above, which is the project's contract-test standard (METHODOLOGY). The D-06 fallback was implemented before its test and is covered by S1.

## Files Created/Modified

See `key-files` above. Notable: `mailglass_admin/test/support/operator_fixtures.ex` gained public `seed_phase182_journey!/0` (tenant `browser-tenant`, nine `pw-<case>@example.com` rows, one `AccountMailer.password_reset` row for the plain-name case, a `:hard_bounce` suppression for the suppressed row).

## Decisions Made

- `true`-or-`nil` flags (C-4) via `CASE ... THEN true END`; A1 (the fragment compiles inside `group_by`) is proven by the DB test, no alternative form needed.
- `brandbook/status-marks.json`, not `brandbook/v2/`: `brand_pin_test` treats `brandbook/v2` as pin-owned and would report an unlisted file. `brand_pin_test` stays green.
- The extractor does not load `brand_pin.exs` in library mode: two async tests toggling `:script_library_mode` could let the CLI run and halt the VM. It copies the 3-line `sha256_hex/1` and the in-memory zip read.
- `delivery_summary/1` is now `@doc false def` and returns `{:undetermined, sentence}` or the three-tuple list; the template renders the sentence in `data-testid="operator-delivery-summary"` with no stat cards.
- A complained-only or unsubscribed-only row has no delivery problem, so `delivery_class/1` returns `:sent` and the summary counts it under Awaiting confirmation (R2 in RESEARCH). It leaves Needs attention as D-07 requires.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Re-ran the false-flag mutation in lockstep**
- **Found during:** Task 2 mutation proofs
- **Issue:** mutating only the `select` of `outcome_groups` broke the SQL (`GROUP BY` mismatch) and failed 8 tests for the wrong reason, which is not proof the no-false guard has teeth.
- **Fix:** mutated `group_by` and `select` together; only the no-false and groups-apart tests went red.
- **Files modified:** none (mutation only, restored)
- **Committed in:** n/a

**2. [Rule 2 - Missing critical] Plain-language packaging guard instead of a blanket `brandbook/` ban**
- **Found during:** Task 3 test authoring
- **Issue:** the plan's packaging guard said lib has "no `brandbook/` path", but `lib/mix/tasks/mailglass_admin.assets.build.ex` and `components.ex` (logo doc) legitimately mention `brandbook/` in comments and docs.
- **Fix:** the test forbids `status-marks.json` anywhere in `lib` outside `mix/tasks/` and forbids `File.read`, `File.stream`, `@external_resource`, `Code.compile_file` in `components.ex` and `gallery_live.ex`. The acceptance grep (`status-marks.json` in admin lib = 0) holds.
- **Files modified:** `mailglass_admin/test/mailglass_admin/phase182_status_marks_test.exs`
- **Committed in:** `92e18c3c`

**3. [Rule 2 - Missing critical] copy_contract phrase set 23 to 22**
- **Found during:** Task 2
- **Issue:** rewriting the Needs attention help to lowercase prose removed its capitalised status word, so the "stale entry" rule would fail.
- **Fix:** removed that `@status_phrases` entry, renamed the count test to 22 with a comment stating why (the plan anticipated this).
- **Files modified:** `mailglass_admin/test/mailglass_admin/copy_contract_test.exs`
- **Committed in:** `de298525`

---

**Total deviations:** 3 (1 bug-in-proof, 2 missing-critical/anticipated). **Impact on plan:** none on scope; all within the plan's intent.

## Issues Encountered

- One test fails in this working tree and not in a clean checkout: `Mailglass.Scripts.Phase164RepositoryTruthTest` "git runtime rules do not conceal the retired finalize-phase extension paths". Cause is a local untracked `.gsd/.gitignore` containing `*`. In a fresh `git clone --local` at `92e18c3c` all five of its assertions hold. Logged in `deferred-items.md`; not touched. All other scoped runs: 752 tests, 1 failure (this one), 1 skipped, 27 excluded.

## Verification

Plan-end order (D-24), all with the ASDF exports:

| Step | Result |
|---|---|
| admin `mix format --check-formatted` | clean |
| admin `mix mailglass_admin.assets.build --check` | "Admin bundle matches a fresh build (138509 bytes)" (bundle and `superseded.json` unchanged) |
| scoped admin contracts + phase182 files (`--seed 0 --warnings-as-errors`) | 210 tests, 0 failures |
| `bash scripts/check-conformance.sh` | "OK: design-system conformance clean." |
| root `scripts/check_test_exceptions.sh` | "OK: test exception registry is complete and unexpired." |
| root `mix format --check-formatted`, `mix compile --warnings-as-errors`, `mix credo --strict` | clean, clean, "found no issues" |
| root `mix test test/mailglass/operator test/scripts test/mailglass/docs_contract_test.exs --seed 0` | 752 tests, 1 failure (the environment test above), 1 skipped |
| admin `mix verify.support_contract.admin` | 1551 tests, 0 failures, exit 0 |

Plan acceptance: `git diff --stat 78dcb7d0..HEAD -- priv/repo lib/mailglass/outbound lib/mailglass/events` is empty; `git diff --name-only 78dcb7d0..HEAD -- lib/` lists only `lib/mailglass/operator/deliveries.ex`; `stability_contract_test.exs`, `operator_trust_doc_test.exs` and `test/mailglass/docs_contract_test.exs` have an empty diff; the core commit `6b1e8016` lists only the two core files and has a `feat(core):` subject; no `.planning/release-target.json` change.

## Known Stubs

None. `seed_phase182_journey!/0` and the pinned marks are real data, and every mark is rendered by a component with a contract test. The gallery specimens are static by design.

## Threat Flags

None beyond the plan's threat model: the five new projection keys are same-row, tenant-scoped timestamps and booleans (T-182-01); the extractor checks the zip sha256 before reading any member and never writes the book HTML (T-182-02); no release ledger edit (T-182-03).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- 182-02 can read `bounced_at`, `terminal`, `delivered_at`, `complained_at`, `suppressed_at` on both `list_recent_deliveries_page/2` rows and `get_delivery/2`, render `Components.status_mark/1` inside the status badge, and gate the verdict on `Map.has_key?(row, :bounced_at)` (D-06 verdict half). `seed_phase182_journey!/0` and the first describes of `phase182_journey_test.exs` are in place.
- The core change rides release PR #325 as one shippable `feat(core):` line; no ledger interaction. The squash title of a PR carrying this plan must be `feat(core): ...`.
- BRADM-01 and BRADM-02 stay open in REQUIREMENTS.md until the sibling plans that declare them finish (shared-ID gate).

## Self-Check: PASSED

All created files exist (`deliveries_projection_test.exs`, `phase182_journey_test.exs`, `phase182_status_marks_test.exs`, `status-marks.json`, `brand_status_marks.exs`, `brand_status_marks_test.exs`); all seven commits (`6b1e8016`, `2f312ef7`, `1d89e59b`, `aa09c066`, `de298525`, `3e67bdd9`, `92e18c3c`) are ancestors of HEAD; `def status_mark(` count 1; gallery `:status_mark` count 8; `status-marks.json` in admin lib 0; no change under `mailglass_admin/priv/static` or `.planning/research`.

---
*Phase: 182-admin-words-and-layout-one-job-first*
*Completed: 2026-11-15*
