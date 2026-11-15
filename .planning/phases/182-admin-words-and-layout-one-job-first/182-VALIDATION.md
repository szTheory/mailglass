---
phase: "182"
slug: "admin-words-and-layout-one-job-first"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-11-15"
---

# Phase 182 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Source: `182-RESEARCH.md` § Validation Architecture. Required-lane proof only; advisory Playwright is never cited as required proof (180 D-04/D-13).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.18.4 / OTP 27), `Phoenix.LiveViewTest`, Floki 0.38.5; Playwright 1.60.0 (advisory only) |
| **Config file** | `mailglass_admin/mix.exs` aliases (`verify.support_contract.admin`); `config/test_exceptions.exs` (core and inbound only, file:line keyed) |
| **Quick run command** | `cd /Users/jon/projects/mailglass/mailglass_admin && export ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.18.4-otp-27 && mix test test/mailglass_admin/<file>.exs --seed 0` |
| **Full suite command** | `mix verify.support_contract.admin` (in `mailglass_admin`); core: `mix test` at repo root |
| **Estimated runtime** | scoped file ~2-6 s; scoped contract set ~2 s; full suites several minutes |

---

## Sampling Rate

- **After every task commit:** the one scoped test file for that task (`mix test <file> --seed 0`)
- **After every plan wave:** D-24 pre-flight order in `mailglass_admin`: `mix format --check-formatted`; `mix mailglass_admin.assets.build --check`; scoped existing contracts (`root_theme_ownership`, `copy_contract`, `status_map`, `glyph_contract`, `font_assets_contract`, `before_catalog_manifest`, `persona_drift_guard`); new Phase 182 files; `bash scripts/check_test_exceptions.sh` (repo root); if core changed `mix compile --warnings-as-errors` + `mix credo --strict`
- **Before `/gsd-verify-work`:** `mix verify.support_contract.admin` and core `mix test` green (baseline is zero failures)
- **Max feedback latency:** 30 seconds per task

---

## Per-Task Verification Map

Task IDs are assigned by the planner; the requirement-to-test map is fixed here.

| Requirement | Plan (D-22) | Test Type | Required-lane file | Automated Command | File Exists | Status |
|-------------|-------------|-----------|--------------------|-------------------|-------------|--------|
| BRADM-01 | 1, 2 | core DB-backed + LiveViewTest | `test/mailglass/operator/deliveries_projection_test.exs` (core, new); `mailglass_admin/test/mailglass_admin/phase182_journey_test.exs` | `mix test test/mailglass/operator/deliveries_projection_test.exs` (root); `mix test test/mailglass_admin/phase182_journey_test.exs --seed 0` | ❌ W0 | ⬜ pending |
| BRADM-02 | 2, 3 | render + source + static scan | `phase182_time_status_contract_test.exs` | `mix test test/mailglass_admin/phase182_time_status_contract_test.exs --seed 0` | ❌ W0 | ⬜ pending |
| BRADM-03 | 4 | render scan + vocabulary binding | `phase182_words_contract_test.exs`, `copy_contract_test.exs` | `mix test test/mailglass_admin/phase182_words_contract_test.exs test/mailglass_admin/copy_contract_test.exs --seed 0` | ❌ W0 | ⬜ pending |
| BRADM-04 | 4 | render scan | `phase182_words_contract_test.exs` | same as BRADM-03 | ❌ W0 | ⬜ pending |
| BRADM-05 | 4 | unit + a11y render | `phase182_words_contract_test.exs`, `phase178_prohibition_contract_test.exs` | `mix test test/mailglass_admin/phase182_words_contract_test.exs test/mailglass_admin/phase178_prohibition_contract_test.exs --seed 0` | ❌ W0 | ⬜ pending |
| BRADM-06 | 2 | structural + forbidden-phrase matrix | `phase182_cause_contract_test.exs` | `mix test test/mailglass_admin/phase182_cause_contract_test.exs --seed 0` | ❌ W0 | ⬜ pending |
| BRADM-07 | 5 | manifest + verdict schema + `gate/1` | `after_catalog_manifest_test.exs` | `mix test test/mailglass_admin/after_catalog_manifest_test.exs test/mailglass_admin/before_catalog_manifest_test.exs --seed 0` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

### Mutation proofs (each recorded in the owning plan summary, per METHODOLOGY)

- **BRADM-01:** delete the Sent rule line; drop `bounced_at`, then `terminal`, from the projection select (each fails the core contract); put the timeline above the verdict (DOM-order assert); omit the search patch; emit `bounced_at: false` from `outcome_groups`.
- **BRADM-02:** drop " UTC" from `utc_string`; bare `<time>` in a new component; icon-only badge; hand-coded `<span class="badge">` in a LiveView; remove `timeZoneName` from `FMT`; LiveView module absent from the registry; mark with `aria-label`; `false` flag value.
- **BRADM-03/04:** reintroduce "Deliveries" in nav, `<title>` or `aria-label`; revert `operator_live.ex` "Operator"; revert one C-12 site.
- **BRADM-05:** revert to "Unmatched events"; use `title=` for the mailer identity; hide the full module on detail.
- **BRADM-06:** interpolate a nil reason; add "will retry" to Delayed copy; delete an enum clause; skip a reason in the matrix; render the fallback on Quick view.
- **BRADM-07:** flip a verdict to pass; add an unlisted file; plant a hallucinated quote; drop the calibration set; make a known-bad calibration pass.

---

## Wave 0 Requirements

- [ ] `mailglass_admin/test/support/catalog_validators.ex` — extracted pure validators (before-catalog validators are `defp`, C-11)
- [ ] `mailglass_admin/test/support/operator_fixtures.ex` rows — password-reset Sent-no-report, bounce, bounce-then-open, nil-reason bounce, deferred, suppressed, complained (module-only `mailable`, reserved `.example` recipients)
- [ ] `JourneySeed` (new seed module outside `DemoData`/`personas.ex`), `brandbook/v2/status-marks.json`, `scripts/brand_status_marks.exs`
- [ ] New test files listed in the map above (new files only; never edit `config/test_exceptions.exs` entries)

Framework install: none (existing infrastructure).

---

## Manual-Only Verifications

All phase behaviors have automated verification (D-52 shift-left). The BRADM-07 reviewer is an automated fresh-agent gate; the owner only vetoes ship/no-ship. Advisory Playwright journey (375/1440, light/dark, `timezoneId` UTC / America/New_York / Pacific/Auckland) supplements but never replaces the required lane.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
