---
phase: 1
slug: foundation
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-22
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in) |
| **Config file** | `test/test_helper.exs` (to be created in Wave 0) |
| **Quick run command** | `mix test test/mailglass/ --exclude integration` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Estimated runtime** | ~15 seconds (unit) / ~30 seconds (full) |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/mailglass/ --exclude integration`
- **After every plan wave:** Run `mix test --warnings-as-errors`
- **Before `/gsd-verify-work`:** Full suite green + `mix compile --no-optional-deps --warnings-as-errors` + `mix credo --strict`
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01-02-T2 | Plan 02 | Wave 1 | CORE-01 | — | Six error structs raisable and pattern-matchable by struct | unit | `mix test test/mailglass/error_test.exs` | ❌ W0 stub | ⬜ pending |
| 01-02-T2 | Plan 02 | Wave 1 | CORE-01 | — | `__types__/0` matches `api_stability.md` documented sets | unit | `mix test test/mailglass/error_test.exs::test_types_match_docs` | ❌ W0 stub | ⬜ pending |
| 01-02-T2 | Plan 02 | Wave 1 | CORE-01 | T-1-PII | `Jason.Encoder` on errors excludes `:cause` to prevent PII in serialized payloads | unit | `mix test test/mailglass/error_test.exs::test_json_encoding` | ❌ W0 stub | ⬜ pending |
| 01-03-T1 | Plan 03 | Wave 2 | CORE-02 | — | `Mailglass.Config.new!/1` validates required keys via NimbleOptions | unit | `mix test test/mailglass/config_test.exs` | ❌ W0 stub | ⬜ pending |
| 01-03-T1 | Plan 03 | Wave 2 | CORE-02 | — | Invalid config raises `NimbleOptions.ValidationError` | unit | `mix test test/mailglass/config_test.exs::test_validation_error` | ❌ W0 stub | ⬜ pending |
| 01-03-T1 | Plan 03 | Wave 2 | CORE-03 | T-1-PII | Telemetry stop events contain only whitelisted metadata keys (StreamData 1000 runs, varied metadata) | property | `mix test test/mailglass/telemetry_test.exs` | ❌ W0 stub | ⬜ pending |
| 01-03-T1 | Plan 03 | Wave 2 | CORE-03 | T-1-HandlerIsolation | Telemetry handler that raises does not break render pipeline | unit | `mix test test/mailglass/telemetry_test.exs::test_handler_isolation` | ❌ W0 stub | ⬜ pending |
| 01-03-T2 | Plan 03 | Wave 2 | CORE-04 | — | `Mailglass.Repo.transact/1` delegates to configured repo | unit (doctest) | `mix test test/mailglass/repo_test.exs` | ❌ W0 stub | ⬜ pending |
| 01-03-T2 | Plan 03 | Wave 2 | CORE-05 | — | `IdempotencyKey.for_webhook_event/2` produces deterministic keys | unit | `mix test test/mailglass/idempotency_key_test.exs` | ❌ W0 stub | ⬜ pending |
| 01-03-T2 | Plan 03 | Wave 2 | CORE-05 | T-1-Injection | Keys with control characters are sanitized | unit | `mix test test/mailglass/idempotency_key_test.exs::test_sanitization` | ❌ W0 stub | ⬜ pending |
| 01-01-T2 | Plan 01 | Wave 1 | CORE-06 | T-1-OptDepLeak | `mix compile --no-optional-deps --warnings-as-errors` passes (initial scaffold) | compile | `mix compile --no-optional-deps --warnings-as-errors` | ✅ W0 | ⬜ pending |
| 01-04-T2 | Plan 04 | Wave 3 | CORE-06 | T-1-OptDepLeak | `mix compile --no-optional-deps --warnings-as-errors` passes (after OptionalDeps modules) | compile | `mix compile --no-optional-deps --warnings-as-errors` | ❌ W0 stub | ⬜ pending |
| 01-01-T1 | Plan 01 | Wave 1 | CORE-07 | T-1-BoundaryLeak | `compilers: [:boundary \| Mix.compilers()]` declared (compiler wired) | compile | `mix compile` | ✅ W0 | ⬜ pending |
| 01-06-T2 | Plan 06 | Wave 4 | CORE-07 | T-1-BoundaryLeak | `Mailglass.Renderer` cannot depend on `Mailglass.Outbound` (Boundary enforced) | compile | `mix compile` | ❌ W0 stub | ⬜ pending |
| 01-05-T1 | Plan 05 | Wave 3 | AUTHOR-02 | — | Premailex preserves conditional comments after CSS inlining (golden fixture) | integration | `mix test test/mailglass/components/vml_preservation_test.exs` | ❌ W0 stub | ⬜ pending |
| 01-05-T2b | Plan 05 | Wave 3 | AUTHOR-02 | — | `<.button>` renders VML `<v:roundrect>` wrapper in final HTML | unit | `mix test test/mailglass/components/button_test.exs` | ❌ W0 stub | ⬜ pending |
| 01-01-T2 | Plan 01 | Wave 1 | AUTHOR-02 | — | `<.img>` without `alt` raises compile error (Wave 0 fixture stub) | compile | `mix compile test/mailglass/components/img_no_alt_test.exs` (verified in Plan 05 Task 2b) | ✅ W0 | ⬜ pending |
| 01-05-T2b | Plan 05 | Wave 3 | AUTHOR-02 | — | `<.row>` with non-column child emits Logger.warning | unit | `mix test test/mailglass/components/row_test.exs::test_non_column_warning` | ❌ W0 stub | ⬜ pending |
| 01-06-T2 | Plan 06 | Wave 4 | AUTHOR-03 | — | `Mailglass.Renderer.render/1` returns `{:ok, %Message{html_body: _, text_body: _}}` | unit | `mix test test/mailglass/renderer_test.exs` | ❌ W0 stub | ⬜ pending |
| 01-06-T2 | Plan 06 | Wave 4 | AUTHOR-03 | — | Plaintext excludes preheader text (D-15 — Floki walks pre-VML tree) | unit | `mix test test/mailglass/renderer_test.exs::test_plaintext_skips_preheader` | ❌ W0 stub | ⬜ pending |
| 01-06-T2 | Plan 06 | Wave 4 | AUTHOR-03 | — | Plaintext for `<.button>` produces `"Label (url)"` format | unit | `mix test test/mailglass/renderer_test.exs::test_plaintext_link_pair` | ❌ W0 stub | ⬜ pending |
| 01-06-T2 | Plan 06 | Wave 4 | AUTHOR-03 | — | `data-mg-*` attributes stripped from final HTML wire output | unit | `mix test test/mailglass/renderer_test.exs::test_data_attrs_stripped` | ❌ W0 stub | ⬜ pending |
| 01-06-T2 | Plan 06 | Wave 4 | AUTHOR-03 | — | Render completes in <50ms for 10-component template | performance | `mix test test/mailglass/renderer_test.exs::test_render_performance` | ❌ W0 stub | ⬜ pending |
| 01-06-T2 | Plan 06 | Wave 4 | AUTHOR-04 | — | Gettext backend defined with `use Gettext.Backend, otp_app: :mailglass` | compile | `mix compile` (loads `Mailglass.Gettext`) | ❌ W0 stub | ⬜ pending |
| 01-06-T1 | Plan 06 | Wave 4 | AUTHOR-05 | — | `Mailglass.TemplateEngine.HEEx.render/2` with missing assign returns `{:error, %TemplateError{type: :missing_assign}}` | unit | `mix test test/mailglass/template_engine/heex_test.exs` | ❌ W0 stub | ⬜ pending |
| 01-06-T2 | Plan 06 | Wave 4 | COMP-01 | — | `add_rfc_required_headers/1` adds Date, Message-ID, MIME-Version when absent | unit | `mix test test/mailglass/compliance_test.exs` | ❌ W0 stub | ⬜ pending |
| 01-06-T2 | Plan 06 | Wave 4 | COMP-01 | — | `add_rfc_required_headers/1` does not overwrite existing headers | unit | `mix test test/mailglass/compliance_test.exs::test_no_overwrite` | ❌ W0 stub | ⬜ pending |
| 01-06-T2 | Plan 06 | Wave 4 | COMP-02 | — | `Mailglass-Mailable` header has correct format (`"Module" v"version"`) | unit | `mix test test/mailglass/compliance_test.exs::test_mailable_header` | ❌ W0 stub | ⬜ pending |

*Task ID format: `01-NN-TM` where NN = plan number, M = task index (2a/2b for split tasks). Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `mix.exs` + `mix deps.get` — project scaffold (if no `mix.exs` yet)
- [x] `test/test_helper.exs` — ExUnit setup, Mox declarations for `Mailglass.TemplateEngine`, golden-fixture path configuration
- [x] `test/support/` — shared fixtures (sample HEEx templates, golden VML snapshots)
- [x] `test/mailglass/error_test.exs` — stub for CORE-01 (including `__types__/0` assertion)
- [x] `test/mailglass/config_test.exs` — stub for CORE-02
- [x] `test/mailglass/telemetry_test.exs` — stub for CORE-03 (property test via StreamData + handler-isolation case)
- [x] `test/mailglass/repo_test.exs` — stub for CORE-04 (doctest + Mox)
- [x] `test/mailglass/idempotency_key_test.exs` — stub for CORE-05
- [x] `test/mailglass/components/vml_preservation_test.exs` — **golden-fixture test for D-14, highest-risk, write first**
- [x] `test/mailglass/components/button_test.exs` — stub for AUTHOR-02 VML wrapper
- [x] `test/mailglass/components/row_test.exs` — stub for AUTHOR-02 non-column warning
- [x] `test/mailglass/components/img_no_alt_test.exs` — compile-time failure fixture (Plan 01 Task 2, @moduletag :skip)
- [x] `test/mailglass/renderer_test.exs` — stub for AUTHOR-03 (render, plaintext, performance)
- [x] `test/mailglass/template_engine/heex_test.exs` — stub for AUTHOR-05
- [x] `test/mailglass/compliance_test.exs` — stub for COMP-01, COMP-02

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Visual rendering in classic Outlook / Gmail / Apple Mail | AUTHOR-02 | Real MUA rendering cannot be automated in CI; Litmus/Email on Acid are paid services, deferred to Phase 4+ | Render the v0.1 example template via `iex -S mix`, inspect HTML, paste into Litmus/manual testing inbox. Record pass/fail in phase verification notes. |

---

## Validation Sign-Off

- ✅ All tasks have `<automated>` verify or Wave 0 dependencies
- ✅ Sampling continuity: no 3 consecutive tasks without automated verify
- ✅ Wave 0 covers all MISSING references (including img_no_alt_test.exs)
- ✅ No watch-mode flags (CI must be non-interactive)
- ✅ Feedback latency < 30s
- ✅ `nyquist_compliant: true` set in frontmatter

**Approval:** pending execution
