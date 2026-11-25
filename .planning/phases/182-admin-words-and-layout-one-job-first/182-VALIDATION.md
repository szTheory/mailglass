---
phase: "182"
slug: "admin-words-and-layout-one-job-first"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-11-15"
---

# Phase 182 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Source: `182-RESEARCH.md` § Validation Architecture. Required-lane proof only; advisory Playwright is never cited as required proof (180 D-04/D-13). Audited against the final tree (HEAD `cabd412d`, after both code-review fix iterations) by running the scoped commands below.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.18.4 / OTP 27), `Phoenix.LiveViewTest`, Floki 0.38.5; Playwright 1.60.0 (advisory only) |
| **Config file** | `mailglass_admin/mix.exs` aliases (`verify.support_contract.admin`); `config/test_exceptions.exs` (core and inbound only, file:line keyed) |
| **Quick run command** | `cd /Users/jon/projects/mailglass/mailglass_admin && export ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 && mix test test/mailglass_admin/<file>.exs --seed 0` |
| **Full suite command** | `mix verify.support_contract.admin` (in `mailglass_admin`); core: `mix test` at repo root |
| **Estimated runtime** | scoped file ~2-6 s; scoped contract set ~2 s; full admin lane several minutes |

### Where each lane runs (checked against `.github/workflows/ci.yml`)

| Files | CI job | Blocks merge? |
|-------|--------|---------------|
| every file under `mailglass_admin/test/` (the alias is plain `test --warnings-as-errors`, no allow-list) | `support_contract_admin` | Yes, a required leaf of `ci_green` |
| `test/mailglass/operator/deliveries_projection_test.exs`, `test/scripts/brand_status_marks_test.exs`, `test/scripts/brand_pin_test.exs` | `core_deterministic_suite` (full root `mix test --warnings-as-errors`) | Yes, a required leaf of `ci_green` |
| `mailglass_admin/e2e/*.spec.js`, `reference/demo_app/assets/{e2e,catalog}/*.spec.js` | `operator_browser_gate`, `demo_browser_evidence` | No, neither is in the `ci_green` needs list (advisory) |

---

## Sampling Rate

- **After every task commit:** the one scoped test file for that task (`mix test <file> --seed 0`)
- **After every plan wave:** D-24 pre-flight order in `mailglass_admin`: `mix format --check-formatted`; `mix mailglass_admin.assets.build --check`; scoped existing contracts (`root_theme_ownership`, `copy_contract`, `status_map`, `glyph_contract`, `font_assets_contract`, `before_catalog_manifest`, `persona_drift_guard`); new Phase 182 files; `bash scripts/check_test_exceptions.sh` (repo root); if core changed `mix compile --warnings-as-errors` + `mix credo --strict`
- **Before `/gsd-verify-work`:** `mix verify.support_contract.admin` and core `mix test` green (baseline is zero failures)
- **Max feedback latency:** 30 seconds per task

---

## Per-Task Verification Map

Task IDs are `182-<plan>-T<task>` (assigned at planning, 2026-11-15). Regrouping versus D-22 is recorded in each plan's `<decisions_recorded>`: pane-mark provenance moved to 182-01, JourneySeed and the advisory browser journey moved to 182-06, the SSR time format stays in 182-03; the words plan was split by surface at plan check (182-04 lib + ExUnit pins, 182-05 advisory e2e pins), so the after-catalog plan is 182-06.

Counts are the tests that ran, per file, under `--warnings-as-errors --seed 0` at HEAD `cabd412d` plus the one gap-fill file below.

| Requirement | Task IDs | Test Type | Required-lane file | Automated Command | File Exists | Status |
|-------------|----------|-----------|--------------------|-------------------|-------------|--------|
| BRADM-01 | 182-01-T1, 182-01-T2 | core DB-backed + LiveViewTest summary | `test/mailglass/operator/deliveries_projection_test.exs` (core); `mailglass_admin/test/mailglass_admin/phase182_journey_test.exs` | `mix test test/mailglass/operator/deliveries_projection_test.exs --warnings-as-errors --seed 0` (root); `mix test test/mailglass_admin/phase182_journey_test.exs --warnings-as-errors --seed 0` | ✅ | ✅ green (10 core, 48 admin) |
| BRADM-01 | 182-02-T1, 182-02-T2 | LiveViewTest journey (row, Quick view, detail order, search patch, theme dead render) | `phase182_journey_test.exs` | `mix test test/mailglass_admin/phase182_journey_test.exs --warnings-as-errors --seed 0` | ✅ | ✅ green (48) |
| BRADM-01 (advisory only) | 182-06-T1 | Playwright catalog journey 375/1440 x light/dark x UTC/New_York/Auckland | `reference/demo_app/assets/catalog/phase182-journey.spec.js` (never cited as required proof) | `node reference/demo_app/assets/catalog/capture-before-catalog.cjs --mode after --catalog-root "$SCRATCH/after-smoke"` | ✅ | advisory: `node --check` ok; browser run reported green in the 182-06 summary, not re-run here; the required proof for the 375/1440 light/dark screens is the committed after-catalog bound by `after_catalog_manifest_test.exs` (see BRADM-07) |
| BRADM-02 | 182-01-T3 | component equals pinned JSON + 3:1 contrast, light and dark | `phase182_status_marks_test.exs`; `test/scripts/brand_status_marks_test.exs` (core, hermetic) | `mix test test/mailglass_admin/phase182_status_marks_test.exs --warnings-as-errors --seed 0`; root `mix test test/scripts/brand_status_marks_test.exs test/scripts/brand_pin_test.exs --seed 0` | ✅ | ✅ green (16 admin; 95 core across both script files) |
| BRADM-02 | 182-02-T1 | row class badge mark + word | `phase182_journey_test.exs`, `copy_contract_test.exs` (Part B rewrite) | `mix test test/mailglass_admin/phase182_journey_test.exs test/mailglass_admin/copy_contract_test.exs --warnings-as-errors --seed 0` | ✅ | ✅ green (48 + 26) |
| BRADM-02 | 182-03-T1, 182-03-T2 | render + source + static scan over the screen registry; provider time through `timestamp/1` | `phase182_time_status_contract_test.exs`; `operator/timeline_provider_time_test.exs`; `test/support/screen_registry.ex` | `mix test test/mailglass_admin/phase182_time_status_contract_test.exs test/mailglass_admin/operator/timeline_provider_time_test.exs --warnings-as-errors --seed 0` | ✅ | ✅ green (35 + 6) |
| BRADM-02 (client-side zone, runtime) | 182-02-T2, 182-03-T1 | executes the served browser localizer in Node under `UTC`, `America/New_York`, `Pacific/Auckland`; in-memory mutants prove each check can fail | `phase182_localizer_runtime_test.exs` (added by this audit) | `mix test test/mailglass_admin/phase182_localizer_runtime_test.exs --warnings-as-errors --seed 0` | ✅ | ✅ green (15) |
| BRADM-03 | 182-04-T1, 182-04-T2 | render scan + vocabulary binding; nav link keeps `view=deliveries`; `router_test.exs` and `stability_contract_test.exs` unedited | `phase182_words_contract_test.exs`, `copy_contract_test.exs` | `mix test test/mailglass_admin/phase182_words_contract_test.exs test/mailglass_admin/copy_contract_test.exs --warnings-as-errors --seed 0` | ✅ | ✅ green (27 + 26) |
| BRADM-04 | 182-04-T1, 182-04-T2 | render scan | `phase182_words_contract_test.exs` | same as BRADM-03 | ✅ | ✅ green (27) |
| BRADM-05 | 182-04-T3 | unit + a11y render | `phase182_words_contract_test.exs`, `operator/mailer_name_test.exs`, `phase178_prohibition_contract_test.exs` | `mix test test/mailglass_admin/operator/mailer_name_test.exs test/mailglass_admin/phase182_words_contract_test.exs test/mailglass_admin/phase178_prohibition_contract_test.exs --warnings-as-errors --seed 0` | ✅ | ✅ green (16 + 27 + 21) |
| BRADM-03/04/05 (advisory only) | 182-05-T1, 182-05-T2, 182-05-T3 | e2e pin sweep run in the operator browser lane and the demo evidence lane; demo navigation ExUnit test | `mailglass_admin/e2e/*.spec.js`, `reference/demo_app/assets/e2e/*.spec.js`, `reference/demo_app/test/mailglass_demo_web/phase177_navigation_test.exs` (never cited as required proof) | `npm run test:operator-browser -- <specs>` (in `mailglass_admin`); `bash scripts/run_demo_browser_evidence.sh`; demo `mix test test/mailglass_demo_web/phase177_navigation_test.exs --seed 0` | ✅ | advisory: `node --check` ok on the sampled specs; browser and demo runs reported green in the 182-05 summary, not re-run here |
| BRADM-06 | 182-02-T3 | structural + forbidden-phrase matrix | `phase182_cause_contract_test.exs` | `mix test test/mailglass_admin/phase182_cause_contract_test.exs --warnings-as-errors --seed 0` | ✅ | ✅ green (41) |
| BRADM-07 | 182-06-T2, 182-06-T3 | manifest + verdict schema + `gate/1`; reviewer-finding rebuttal for R-WORDS-1 | `after_catalog_manifest_test.exs`; `phase182_review_words_test.exs`; `test/support/{catalog_validators,review_gate}.ex` | `mix test test/mailglass_admin/after_catalog_manifest_test.exs test/mailglass_admin/before_catalog_manifest_test.exs test/mailglass_admin/phase182_review_words_test.exs --warnings-as-errors --seed 0` | ✅ | ✅ green (61 + 48 + 5) |

All admin commands run from `/Users/jon/projects/mailglass/mailglass_admin` with `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27`; the two root commands run from `/Users/jon/projects/mailglass`.

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky. "advisory" rows are not merge-blocking and are not counted as proof.*

### Whole-lane evidence (final tree)

| Command | Result |
|---------|--------|
| `mix verify.support_contract.admin` (in `mailglass_admin`) | 1802 tests, 0 failures, 1 excluded (the pre-existing `:skip`); 1787 before the gap-fill file, 15 added |
| `mix mailglass_admin.assets.build --check` | "Admin bundle matches a fresh build (138536 bytes)" |
| `mix format --check-formatted` (admin and root) | exit 0 |
| `bash scripts/check_test_exceptions.sh` | OK; `config/test_exceptions.exs` has an empty diff since the phase start |
| `bash mailglass_admin/scripts/check-conformance.sh` | OK, design-system conformance clean |
| root `mix test test/mailglass/operator test/mailglass/docs_contract_test.exs --warnings-as-errors --seed 0` | 115 tests, 0 failures, 1 skipped |
| 22 cited guard files (operator_live, status_map, stability, brand_v2_compat_policy, operator_trust_doc, components, voice, phase175/176/177 prohibitions, root_theme_ownership, persona_drift_guard, glyph, contrast, font_assets, assets, router, quick_view_projection, shell, health_overview, results_status, scenario_label) | 754 tests, 0 failures, 1 excluded |
| `mix compile --warnings-as-errors` in `reference/demo_app` (compiles `JourneySeed`) | clean; `mix.lock` unchanged |

The root core full suite was not run in this audit (one known environmental failure from an untracked local `.gsd/.gitignore`, unrelated to this phase); the core rows above are the scoped files.

### Coverage classification (requirement to required-lane proof)

| Requirement | Class | Basis | Caveat |
|-------------|-------|-------|--------|
| BRADM-01 | COVERED | the real LiveView journey (`live/2` to `render_change` to `assert_patch` with `search=` to a row reading "Failed" with one `aria-hidden` mark, `attention == 1`, Quick view one-line verdict, Full detail verdict before the timeline with "Next step" and "sent is not delivered" for a Sent row); the theme dead render pins exactly one `data-theme` owner for dark, light and no cookie; the search and the verdict are never behind a hidden or closed ancestor; 44px targets; the committed after-catalog covers 375 and 1440 in light and dark with 28 two-judge pass verdicts, bound live to the current `app.css` | pixel geometry at 375px and dark colour rendering is proven in the required lane only by DOM and class contracts plus the committed, judged after-catalog; the real-browser Playwright journey is advisory |
| BRADM-02 | COVERED (one PARTIAL closed) | server side: render scan over the screen registry, source scan, static `FMT` check, marks equal the pinned JSON with 3:1 contrast in light and dark. The client-side localizer was PARTIAL (source scanned, never executed in the required lane); closed by `phase182_localizer_runtime_test.exs` | the new test runs Node; see Honest limits |
| BRADM-03 | COVERED | Activity in nav, title, h1 and gloss over every registered screen; the nav link href still carries `view=deliveries`; `router.ex`, `router_test.exs` and `stability_contract_test.exs` are untouched and green | none |
| BRADM-04 | COVERED | Admin and Account over every registered screen, with identifiers (`tenant_id`, `deliveries_path`) refused as words; modules and public names untouched | none |
| BRADM-05 | COVERED | `OrphanCount.label/1` for 0, 1, 2 and 11; the mailer plain name derived on binaries only (atom-count test with a control); tooltip through `field_help` with the stored identity also visible and no `title` | none |
| BRADM-06 | COVERED | cause sentences generated from the enums with no nil clause; forbidden-phrase matrix ("next try", "will retry", automatic retry) over every cell; `last_error` seeded and asserted never rendered | none |
| BRADM-07 | COVERED | schema-closed verdicts, evidence quote must be a literal substring of the aria sidecar, calibration known-bad and known-good enforced, unique `after-<sha>-<stamp>` path, `server.started_at` later than `script_started_at`, served asset sha equals disk and git blob | the catalog predates the review-fix edits (see Honest limits) |

### Honest limits (warnings, none blocking)

- The new `phase182_localizer_runtime_test.exs` makes `node` a required-lane dependency. It is preinstalled on GitHub's Ubuntu runners but this audit could not confirm that for `support_contract_admin`. Where `node` is missing the module skips locally and fails closed when `CI` is set, so the lane cannot go green without running the localizer. Both branches were exercised with a PATH that has no `node`.
- The committed after-catalog was captured before the review-fix edits (`a7f843a2` to `4417b105`). `app.css` and the root layout are byte-identical, and the changed paths need data the 14 captured scenarios do not contain (recorded in `182-VERIFICATION.md` note 1). A fresh catalog is needed only if evidence at HEAD is wanted.
- The Health "Delayed emails" link can open a wider list than the card counts when a confirmed or bounced email has a later deferral; it then drops the event filter rather than mislabel the list. Isolating the counted rows needs a delivery-class filter in core, deferred by D-07 (`182-REVIEW-FIX.md`, WR-02). This is adjacent to BRADM-01, not part of its wording.

---

## Wave 0 Requirements

All Wave 0 artifacts exist in the final tree and are exercised green.

- [x] `mailglass_admin/test/support/catalog_validators.ex` — extracted pure validators (C-11), created in 182-06-T2; exercised by `after_catalog_manifest_test` (61) and `before_catalog_manifest_test` (48), both green
- [x] `mailglass_admin/test/support/operator_fixtures.ex` rows — `seed_phase182_journey!/0` (line 241) read by `phase182_journey_test` (48); `seed_phase182_status_grid!/0` (line 382) read by `phase182_time_status_contract_test` (35); both green
- [x] `JourneySeed` (`reference/demo_app/lib/mailglass_demo/journey_seed.ex`, outside `DemoData` and `reference/persona_spec/personas.ex`) compiles clean under `--warnings-as-errors`; the six rows it seeds are what the committed after-catalog's `cases` carry, bound by `after_catalog_manifest_test`. `brandbook/status-marks.json` and `scripts/brand_status_marks.exs` exist and are green under `brand_status_marks_test` and `brand_pin_test` (95) and `phase182_status_marks_test` (16)
- [x] New test files listed in the map above exist and are green (new files only; `config/test_exceptions.exs` has an empty diff since the phase start). Files added after planning: `phase182_review_words_test.exs` (5), `operator/timeline_provider_time_test.exs` (6), `phase182_localizer_runtime_test.exs` (15, this audit)

Framework install: none (existing infrastructure).

---

## Manual-Only Verifications

All phase behaviors have automated verification (D-52 shift-left); nothing was converted to manual. The BRADM-07 reviewer is an automated fresh-agent gate whose committed verdicts are bound in the required lane; the owner only vetoes ship/no-ship. The advisory Playwright journey (375/1440, light/dark, `timezoneId` UTC / America/New_York / Pacific/Auckland) supplements but never replaces the required lane; the same three zones are now also executed in the required lane by `phase182_localizer_runtime_test.exs`.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s (scoped files run in 0.6 to 7 s)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-11-15 against HEAD `cabd412d` plus `phase182_localizer_runtime_test.exs` (uncommitted at audit time)

## Validation Audit 2026-11-16

| Metric | Count |
|---|---|
| Gaps found | 1 |
| Resolved | 1 |
| Escalated | 0 |
