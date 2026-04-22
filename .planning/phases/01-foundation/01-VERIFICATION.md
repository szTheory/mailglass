---
phase: 01-foundation
verified: 2026-04-22T12:00:00Z
status: passed
score: 5/5 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: null
  note: "Initial verification — no prior VERIFICATION.md"
---

# Phase 1: Foundation Verification Report

**Phase Goal:** Zero-dep modules every later layer depends on are in place, and a pure-function HEEx renderer pipeline can render `MyApp.UserMailer.welcome(user)` to inlined-CSS HTML + plaintext without persistence or transport.
**Verified:** 2026-04-22T12:00:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP.md Phase 1 Success Criteria)

| #   | Truth                                                                                                                                                                                          | Status     | Evidence                                                                                                                                                                                                                                                                                                                 |
| --- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1   | `Mailglass.Renderer.render(message)` on a HEEx mailable returns html_body + text_body with CSS inlined + plaintext auto-generated, <50ms for typical template.                                  | ✓ VERIFIED | `lib/mailglass/renderer.ex:63-85` drives the `render_html → to_plaintext → Premailex.to_inline_css → strip_mg_attributes` pipeline. `test/mailglass/renderer_test.exs:16-24` asserts `{:ok, %Message{}}` with `html_body` + `text_body` populated; `:132-143` asserts <50ms after warm-up. All 12 renderer tests pass.   |
| 2   | `Mailglass.Components` ships all 11 components with MSO/VML fallbacks, zero Node toolchain.                                                                                                     | ✓ VERIFIED | `lib/mailglass/components.ex` declares `preheader/1` (L59), `container/1` (L80), `section/1` (L115), `row/1` (L146 — MSO ghost-table), `column/1` (L186 — MSO ghost-td), `heading/1` (L238), `text/1` (L288), `button/1` (L327 — `<v:roundrect>` VML flagship), `img/1` (L421), `link/1` (L448), `hr/1` (L484). No Node — pure Elixir. Tests: `button_test.exs` (5/5), `row_test.exs` (5/5), `vml_preservation_test.exs` (4/4 golden-fixture). |
| 3   | `mix compile --no-optional-deps --warnings-as-errors` passes against required-deps-only; 5 optional deps gated through `Mailglass.OptionalDeps.*`.                                             | ✓ VERIFIED | `mix compile --no-optional-deps --warnings-as-errors --force` → compiled 29 files, exit 0. All 5 gateways present with `@compile {:no_warn_undefined, …}` + `available?/0`: `Oban` (L20), `OpenTelemetry` (L20), `Mjml` (L16), `GenSmtp` (L14), `Sigra` (conditionally compiled L5). `mix.exs:42-56` elixirc_options covers project-wide no-warn list. |
| 4   | Every v0.1 error is pattern-matchable by struct (6 modules); closed `:type` atom set documented in `docs/api_stability.md`.                                                                    | ✓ VERIFIED | Six modules under `lib/mailglass/errors/`: `SendError`, `TemplateError`, `SignatureError`, `SuppressedError`, `RateLimitError`, `ConfigError`. Each is `defexception` with `@types` attr + `__types__/0` accessor, `@derive {Jason.Encoder, only: [:type, :message, :context]}`. `docs/api_stability.md:11-124` documents every closed atom set. `error_test.exs:52-78` asserts per-module `__types__/0` parity. Jason-encoder PII-exclusion test passes (L82-94). All 18 assertions pass. |
| 5   | Every `:telemetry.execute/3` / `:telemetry.span/3` uses 4-level path with whitelist metadata; handler that raises does not break the pipeline.                                                  | ✓ VERIFIED | `lib/mailglass/telemetry.ex:84` span uses `[:mailglass, :render, :message]` + auto-suffixed `:start\|:stop\|:exception`. `render_span/2` (L97) + `span/3` (L82) + `execute/3` (L108). `telemetry_test.exs:85-119` (T-HANDLER-001) captures handler-raise → library auto-detaches → caller pipeline unaffected; `:152-207` StreamData property test runs 1000 generated metadata maps, asserts keys ⊆ the 11-key whitelist. Passes. |

**Score:** 5/5 truths verified

### Required Artifacts (Level 1-3)

| Artifact                                     | Expected                              | Status     | Details                                                                                                                                             |
| -------------------------------------------- | ------------------------------------- | ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `lib/mailglass/error.ex`                     | Behaviour + namespace module           | ✓ VERIFIED | `@callback type/1`, `@callback retryable?/1`, helpers `is_error?/1`, `kind/1`, `retryable?/1`, `root_cause/1`. Wired from all 6 error structs via `@behaviour Mailglass.Error`. |
| `lib/mailglass/errors/*.ex` (6 modules)       | Six defexception structs              | ✓ VERIFIED | All 6 present, each with `@types`, `__types__/0`, `new/2`, brand-voice `format_message/2`, `@derive {Jason.Encoder, only: [:type, :message, :context]}`. |
| `lib/mailglass/config.ex`                    | NimbleOptions schema + validate_at_boot!/0 | ✓ VERIFIED | Schema (L4-85) covers repo/adapter/theme/telemetry/renderer/tenancy/suppression_store. `validate_at_boot!/0` caches theme in `:persistent_term`. Sole caller of `Application.get_all_env` (no `compile_env` calls in lib/). |
| `lib/mailglass/telemetry.ex`                 | 4-level span helpers + whitelist doc  | ✓ VERIFIED | `render_span/2` delegates to `:telemetry.span/3` with `[:mailglass, :render, :message]` prefix. Metadata policy + whitelist documented in moduledoc (L26-45). |
| `lib/mailglass/repo.ex`                      | `transact/1` facade                   | ✓ VERIFIED | Delegates to `repo().transact/2`; resolver raises `Mailglass.ConfigError.new(:missing, context: %{key: :repo})` when unset. Phase 2 SQLSTATE 45A01 translator documented as stub. |
| `lib/mailglass/idempotency_key.ex`           | `provider:event_id` format + sanitization | ✓ VERIFIED | `for_webhook_event/2` + `for_provider_message_id/2` apply ASCII-printable filter + 512-byte cap (T-IDEMP-001). Doctest covers 0x00 case. |
| `lib/mailglass/message.ex`                   | Struct wrapping %Swoosh.Email{}       | ✓ VERIFIED | Fields: `:swoosh_email`, `:mailable`, `:tenant_id`, `:stream`, `:tags`, `:metadata`. Default `stream: :transactional`. `new/2` builder. |
| `lib/mailglass/optional_deps/*.ex` (5)        | Gateway modules with available?/0     | ✓ VERIFIED | Oban, OpenTelemetry, Mjml, GenSmtp (all `@compile {:no_warn_undefined, …}` + `Code.ensure_loaded?/1`), Sigra (conditionally compiled). |
| `lib/mailglass/components.ex`                 | 11 HEEx components + VML              | ✓ VERIFIED | All 11 components declared with `attr`/`slot` + `data-mg-plaintext` markers. `button` uses `<v:roundrect>`, `row`/`column` use MSO ghost-table conditional comments. |
| `lib/mailglass/components/theme.ex`           | `:persistent_term` brand-token reader | ✓ VERIFIED | `color/1` + `font/1` read from `{Mailglass.Config, :theme}` key populated by `validate_at_boot!/0` (D-19). |
| `lib/mailglass/components/css.ex`             | `merge_style/2` helper                | ✓ VERIFIED | Used across all 11 components. No external class-composition lib per D-20. |
| `lib/mailglass/components/layout.ex`          | Layout with OfficeDocumentSettings + light-only meta | ✓ VERIFIED | D-12 emits `<!--[if gte mso 9]><xml><o:OfficeDocumentSettings>` + `color-scheme:light` metas in the `<head>`. |
| `lib/mailglass/template_engine.ex`            | Pluggable behaviour                   | ✓ VERIFIED | `@callback compile/2` + `@callback render/3`. HEEx is default; MJML opt-in (AUTHOR-05). |
| `lib/mailglass/template_engine/heex.ex`       | Default impl rendering function components | ✓ VERIFIED | `@behaviour Mailglass.TemplateEngine`. Renders via `Phoenix.HTML.Safe.to_iodata/1`. KeyError → `:missing_assign`, other → `:heex_compile`. |
| `lib/mailglass/renderer.ex`                   | Pure-function render pipeline         | ✓ VERIFIED | `use Boundary, deps: [Mailglass]` declares sub-boundary. Pipeline wrapped in `Telemetry.render_span/2`. No process/Repo dependencies. |
| `lib/mailglass/compliance.ex`                 | RFC header injection                  | ✓ VERIFIED | `add_rfc_required_headers/1` injects Date/Message-ID/MIME-Version/Mailglass-Mailable if absent. Supports both map and list `headers` shapes. Dual-shape pattern-match (L123-132). `Elixir.` prefix stripped (L107). |
| `lib/mailglass/gettext.ex`                    | Gettext.Backend with otp_app: :mailglass | ✓ VERIFIED | `use Gettext.Backend, otp_app: :mailglass`. `priv/gettext/emails.pot` + `en/LC_MESSAGES/emails.po` present. |
| `docs/api_stability.md`                       | Closed-atom-set contract              | ✓ VERIFIED | Every `:type` atom set appears verbatim in both the struct's `@types` and the doc. `ErrorTest` asserts parity. |
| `test/fixtures/vml_golden.html`               | VML regression-guard fixture          | ✓ VERIFIED | 45-line fixture with OfficeDocumentSettings + ghost-table + `v:roundrect` + `<!--[if !mso]><!-->`. Asserted by `vml_preservation_test.exs`. |

All artifacts exist (Level 1), are substantive (Level 2 — none are empty placeholders), and are wired into callers (Level 3 — Renderer calls Telemetry.render_span, Premailex.to_inline_css, Phoenix.HTML.Safe; Theme reads Config; 5 gateways are the only touch-points for their optional deps).

### Key Link Verification

| From                                        | To                                    | Via                                                      | Status  | Details                                                                                           |
| ------------------------------------------- | ------------------------------------- | -------------------------------------------------------- | ------- | ------------------------------------------------------------------------------------------------- |
| `lib/mailglass/renderer.ex`                 | `Mailglass.Telemetry.render_span/2`   | Pipeline body wrapped in `Telemetry.render_span/2`        | ✓ WIRED | L69. Test `emits render telemetry span (start + stop)` passes (renderer_test L154-180).           |
| `lib/mailglass/renderer.ex`                 | `Premailex.to_inline_css/1`           | Step 3 inline_css/1 private fn                           | ✓ WIRED | L239. VML-preservation golden test (`vml_preservation_test.exs`) confirms the call produces inlined HTML while preserving MSO conditionals. |
| `lib/mailglass/renderer.ex`                 | `Floki.parse_document/1`              | `to_plaintext/1` walker                                  | ✓ WIRED | L129. Replaced the originally-planned `Floki.traverse_and_update/2` with a custom recursive walker that supports `{:comment, _}` nodes (see renderer_test `<script>/<style>` stripping + `data-mg-plaintext` strategy tests — 8 standalone tests pass). |
| `lib/mailglass/renderer.ex`                 | `Mailglass.TemplateEngine.HEEx.render/3` | `render_html/2` delegates to HEEx engine                  | ✓ WIRED | L91 → `HEEx.render(fun, %{}, opts)`. heex_test.exs drives compile/2 + render/3 with function component, runtime crashes, missing-assign.           |
| `lib/mailglass/components.ex`               | `Mailglass.Components.Theme.color/1` / `.font/1` | Resolves brand tokens (`:tone`, `:variant`, `:bg`) at render time | ✓ WIRED | `heading/1 L267`, `text/1 L293`, `link/1 L449`, `hr/1 L485`. Theme reads from `:persistent_term` populated by `Mailglass.Config.validate_at_boot!/0` (test setup calls this). |
| `lib/mailglass/config.ex`                   | `:persistent_term.put({Config, :theme}, …)` | `validate_at_boot!/0` caches theme                       | ✓ WIRED | L157. Components read via `get_theme/0` L177. |
| `lib/mailglass/application.ex`              | `Mailglass.Config.validate_at_boot!/0` | Application.start/2 boot sequence                         | ✓ WIRED | L12-15 with `Code.ensure_loaded?` guard (defensive; always true in Phase 1). |
| 6 error modules                             | `docs/api_stability.md`               | `__types__/0` ↔ documented atom set                       | ✓ WIRED | `error_test.exs` has 6 assertions, one per module, asserting exact list parity. |
| `lib/mailglass/renderer.ex`                 | `use Boundary, deps: [Mailglass]`     | CORE-07 sub-boundary enforcement                         | ✓ WIRED | L33. Root `Mailglass` only exports `[Message, Telemetry, Config, TemplateEngine, TemplateEngine.HEEx, TemplateError]` (mailglass.ex:32-40) — Renderer cannot reach Outbound/Repo/processes. `mix compile` (with `compilers: [:boundary | Mix.compilers()]`) enforces at build time. |

### Data-Flow Trace (Level 4)

| Artifact                            | Data Variable        | Source                                                       | Produces Real Data | Status     |
| ----------------------------------- | -------------------- | ------------------------------------------------------------ | ------------------ | ---------- |
| `Mailglass.Renderer.render/2`       | rendered `%Message{}`| HEEx function component → Phoenix.HTML.Safe → Premailex → strip | Yes               | ✓ FLOWING  |
| `Mailglass.Renderer.to_plaintext/1` | text string          | Floki parse + custom walker on `data-mg-plaintext` attrs     | Yes               | ✓ FLOWING  |
| `Mailglass.Components.Theme.color/1`| hex color            | `:persistent_term.get({Config, :theme}, [])`                 | Yes (when `validate_at_boot!/0` ran; empty-cache fallback is a known LO-02) | ⚠️ STATIC (when boot skipped) |
| `Mailglass.Compliance.add_rfc_required_headers/1` | updated `%Swoosh.Email{}` | `DateTime.utc_now/0` + `:crypto.strong_rand_bytes/1` + Map.put | Yes               | ✓ FLOWING  |
| `Mailglass.IdempotencyKey.for_*/2`  | sanitized key string | `"#{provider}:…"` → sanitize/1                               | Yes               | ✓ FLOWING  |
| `Mailglass.Telemetry.render_span/2` | event metadata map   | caller-supplied; emitted via `:telemetry.span/3`             | Yes               | ✓ FLOWING  |

The Theme-cache-unset edge case is flagged in `01-REVIEW.md` as LO-02 (silent Glass fallback when validator not called). Not a phase blocker — every production path + every test setup calls `validate_at_boot!/0`.

### Behavioral Spot-Checks

| Behavior                                                       | Command                                                     | Result                                                    | Status  |
| -------------------------------------------------------------- | ----------------------------------------------------------- | --------------------------------------------------------- | ------- |
| `mix compile --no-optional-deps --warnings-as-errors` succeeds | `mix compile --no-optional-deps --warnings-as-errors --force` | Compiled 29 files. Generated mailglass app. Exit 0.       | ✓ PASS  |
| Test suite passes                                              | `mix test`                                                  | 1 property, 95 tests, 0 failures, 1 skipped (compile-fail fixture). Exit 0. | ✓ PASS  |
| `mix verify.phase01` alias runs                                | `MIX_ENV=test mix verify.phase01`                           | Compile + test + credo all run to completion. Exit 0. Credo emits 1 readability + 3 design suggestions (cosmetic — known deferred to Phase 6). | ✓ PASS (with deferred warnings)  |
| Render pipeline < 50ms                                         | `Mailglass.Renderer.render/2` timed via `:timer.tc` after 5 warmup iterations | Sub-50ms for 10-component template (asserted in renderer_test L141).   | ✓ PASS  |
| Golden-fixture VML survives Premailex inlining                 | vml_preservation_test.exs assertions                        | MSO conditional comments + `v:roundrect` + `w:anchorlock` + `OfficeDocumentSettings` all preserved. | ✓ PASS  |

### Requirements Coverage

| Requirement | Source Plan | Description                                                                              | Status      | Evidence                                                                                            |
| ----------- | ----------- | ---------------------------------------------------------------------------------------- | ----------- | --------------------------------------------------------------------------------------------------- |
| CORE-01     | 01-02       | Error hierarchy with 6 defexception structs + closed `:type` atom sets                   | ✓ SATISFIED | 6 modules under `lib/mailglass/errors/`. `error_test.exs` 18 assertions pass. `api_stability.md` locks atom sets. |
| CORE-02     | 01-03       | `Mailglass.Config` via NimbleOptions; sole `compile_env` caller                          | ✓ SATISFIED | `config.ex` schema + `validate_at_boot!/0`. `grep compile_env lib/` returns only doc reference in `config.ex:90`. |
| CORE-03     | 01-03       | Telemetry 4-level convention + whitelist metadata + handler-raise isolation              | ✓ SATISFIED | `telemetry.ex:84` span prefix; `telemetry_test.exs:85-119` T-HANDLER-001; `:152-207` StreamData property (1000 runs). |
| CORE-04     | 01-03       | `Mailglass.Repo.transact/1` Ecto.Multi wrapper                                            | ✓ SATISFIED | `repo.ex:46-48` delegates to host repo's `transact/2`. `repo_test.exs` passes.                       |
| CORE-05     | 01-03       | `Mailglass.IdempotencyKey` → `"provider:event_id"`                                        | ✓ SATISFIED | `idempotency_key.ex:45-63` format matches. Sanitization + 512-byte cap implemented. 10 tests pass.   |
| CORE-06     | 01-01, 01-04 | 5 optional-dep gateways with `@compile {:no_warn_undefined, ...}` + `available?/0`         | ✓ SATISFIED | Oban, OpenTelemetry, Mjml, GenSmtp (always compiled), Sigra (conditional). All match the pattern.    |
| CORE-07     | 01-01       | `boundary` library adopted; Renderer cannot depend on Outbound/Repo/process               | ✓ SATISFIED | `mix.exs:14` `compilers: [:boundary | Mix.compilers()]`. Root boundary (`lib/mailglass.ex:32`) + Renderer sub-boundary (`lib/mailglass/renderer.ex:33`) with explicit export list. `mix compile` passes without boundary violations. |
| AUTHOR-02   | 01-05       | 11 HEEx components with MSO/VML fallbacks, zero Node                                      | ✓ SATISFIED | All 11 present; button VML, row/column MSO ghost-table, golden fixture regression test.              |
| AUTHOR-03   | 01-06       | `Mailglass.Renderer.render/1` → HEEx → Premailex → minify → Floki plaintext < 50ms        | ✓ SATISFIED | `renderer.ex:63-85` pipeline. `renderer_test:132-143` asserts <50ms for 10-component template.       |
| AUTHOR-04   | 01-06       | Gettext `dgettext("emails", ...)` in templates + pot extraction                           | ✓ SATISFIED | `gettext.ex` backend. `priv/gettext/emails.pot` + `en/LC_MESSAGES/emails.po` present.                |
| AUTHOR-05   | 01-04, 01-06 | `Mailglass.TemplateEngine` pluggable behaviour; HEEx default; MJML gateway-gated opt-in  | ✓ SATISFIED | `template_engine.ex` behaviour, `template_engine/heex.ex` default impl, `OptionalDeps.Mjml` gateway. |
| COMP-01     | 01-06       | `Mailglass.Compliance.add_rfc_required_headers/1` injects Date, Message-ID, MIME-Version | ✓ SATISFIED | `compliance.ex:39-45`. Never overwrites existing. 6 of 11 assertions specifically test injection + no-overwrite. |
| COMP-02     | 01-06       | Auto-injects `Mailglass-Mailable: <module>.<function>/<arity>`; Feedback-ID deferred      | ✓ SATISFIED | `compliance.ex:64-68` `add_mailable_header/4`. `Elixir.` prefix stripped (L107). Default placeholder when mailable unknown. 3 mailable-header tests pass. |

All 13 requirement IDs assigned to Phase 1 are SATISFIED. No orphaned requirements — every phase-1 ID in REQUIREMENTS.md traceability table (CORE-01..07, AUTHOR-02..05, COMP-01..02) is claimed by at least one plan's `requirements:` frontmatter.

REQUIREMENTS.md traceability table shows CORE-07 and AUTHOR-02/03/04 still marked `Pending` (the other 9 show `Complete`). This is a documentation-bookkeeping lag — the code genuinely implements all 13 — but the table should be refreshed when STATE.md advances. Flagged as an informational gap (not a phase blocker).

### Anti-Patterns Found

| File                                         | Line  | Pattern                                                                            | Severity  | Impact                                                                                           |
| -------------------------------------------- | ----- | ---------------------------------------------------------------------------------- | --------- | ------------------------------------------------------------------------------------------------ |
| `lib/mailglass/error.ex`                     | 75-76 | `is_error?/1` combines `is_`-prefix and `?`-suffix (violates credo `PredicateFunctionNames`) | ℹ️ Info  | Acknowledged in prompt as deferred to Phase 6 (LINT-06 touchup + rename to `error?/1` with deprecated alias). Not a phase blocker. |
| `lib/mailglass/components.ex`                | 388   | Credo `Design.AliasUsage` suggests aliasing `Phoenix.Component` at top of module     | ℹ️ Info  | Cosmetic. Also flagged in row_test.exs:19 and button_test.exs:24. Deferred to Phase 6 when custom LINT-01..LINT-12 replace default credo design checks. |
| `lib/mailglass/components.ex`                | 386-390 | Uses `Phoenix.Component.__render_slot__/3` (private Phoenix internal) | ℹ️ Info  | Acknowledged in `01-REVIEW.md` as LO-03. Needed to inject slot content into a raw VML HTML string (HEEx doesn't interpolate inside HTML comments). Suggested hardening: compile-time `function_exported?/3` guard to catch Phoenix upgrade breakage. Not a phase blocker. |
| `lib/mailglass/renderer.ex`                  | 69-85 | Error-tuple returns don't emit `:exception` telemetry (only raise does)             | ⚠️ Warning | Flagged in `01-REVIEW.md` as MD-02. Operators monitoring `[:mailglass, :render, :message, :exception]` miss `{:error, %TemplateError{}}` returns. Workaround: monitor `:stop` with `:status` in metadata (requires whitelist extension that D-31 already permits). Not a phase blocker but worth a follow-up. |
| `lib/mailglass/application.ex`               | 26-34 | `maybe_warn_missing_oban/0` fires `Logger.warning` at boot for a function that won't exist until Phase 3 | ℹ️ Info  | Flagged in `01-REVIEW.md` as LO-06. Phase 3 should align the warning with the actual `deliver_later/2` introduction. Not a phase blocker. |

**Zero critical / high-severity anti-patterns.** All flagged items are cosmetic, documentation-drift, or known-deferred to Phase 6. None block goal achievement.

### Human Verification Required

Phase 1 delivers pure-function code with extensive automated test coverage — goal achievement is fully verifiable programmatically. The remaining human checks below are **optional polish** (not phase blockers): the automated pipeline already verifies structural correctness; a human eye on real-world email clients is only needed before adopters consume v0.1.

Because these items are optional polish (not prerequisites for goal achievement), phase status is `passed`. If the maintainer prefers to hold the phase until these are confirmed, they can manually flip status to `human_needed`.

1. **Render a sample HEEx mailable in IEx and inspect output manually**
   - **Test:** Start IEx with `iex -S mix`, call `Mailglass.Config.validate_at_boot!()`, construct a `%Swoosh.Email{}` with a HEEx function component using the 11 components, call `Mailglass.Renderer.render/2`, copy the returned `swoosh_email.html_body` to a file and open in a browser.
   - **Expected:** Layout matches intent: container is 600px centered, colors match Ink/Glass/Ice/Mist/Paper/Slate, button renders as a filled bulletproof shape, text is legible, horizontal rules divide sections.
   - **Why human:** Visual verification across email rendering variance; automated tests cover structural HTML but not visual correctness.

2. **Send rendered sample through Outlook + Gmail + Apple Mail preview**
   - **Test:** Paste the inlined HTML into Postmark's ESP dashboard HTML preview tool (or equivalent), or send to a throwaway Outlook/Gmail/Apple Mail inbox.
   - **Expected:** Classic Outlook shows VML `<v:roundrect>` button as a filled rectangle with the label, not a broken image. Columns render side-by-side in Outlook (ghost-table works). Preheader text appears in inbox preview then hidden in body.
   - **Why human:** Email-client rendering cannot be automated without a full Litmus/Email-on-Acid harness (future v0.5 investment).

3. **Confirm brand-voice error messages read as intended**
   - **Test:** In IEx, run `raise Mailglass.SuppressedError.new(:address)` and `raise Mailglass.SignatureError.new(:mismatch, provider: :postmark)`; read the resulting messages.
   - **Expected:** Messages match brand voice (clear, exact, confident, warm not cute). No "Oops!" or "Something went wrong." Already tested programmatically (`error_test.exs:146-151`) against negative patterns — a human read confirms the positive.
   - **Why human:** Tone judgement is qualitative.

### Known-Deferred Observations

The following observations are flagged in `01-REVIEW.md` and explicitly deferred — they do not block Phase 1:

- **Credo --strict emits 4 cosmetic findings** (1 `Predicate` for `is_error?/1`, 3 `Design.AliasUsage`): per prompt, `.credo.exs` is an intentional minimal stub. Custom `LINT-01..LINT-12` checks land Phase 6 and will supersede the default checks. `mix verify.phase01` alias still completes (exit 0 observed on this machine; prompt mentioned exit 6 on other environments where credo is configured to fail-on-warnings).
- **`IdempotencyKey` namespace disjointness precondition** (MD-01 in 01-REVIEW.md): moduledoc claim is stronger than the implementation for pathological `event_id` values containing `msg:` prefix. Real-world risk zero today — Postmark/SendGrid/Mailgun all use opaque alphanumeric IDs. Documented to tighten in Phase 4 or open a FUTURE.md entry.
- **Renderer error-tuple path skips `:exception` telemetry** (MD-02): error-returns surface as `:stop` events without a `:status` discriminator. Addressable in a follow-up by adding `:status` to span metadata (the whitelist already permits it).
- **REQUIREMENTS.md traceability table still shows CORE-07 + AUTHOR-02..04 as Pending.** Needs a documentation pass after STATE.md advances — a post-verification bookkeeping fix, not a code gap.

---

## Gaps Summary

**No goal-blocking gaps.** All 5 ROADMAP success criteria pass. All 13 requirement IDs satisfied. All 19 artifacts exist, are substantive, wired, and produce real data. All 9 key links verified. 95 tests + 1 property pass (1 compile-fail fixture intentionally skipped). `mix compile --no-optional-deps --warnings-as-errors` succeeds in 29 files. Anti-patterns found are cosmetic and known-deferred to Phase 6.

Phase 1 closed its goal: a developer can call `Mailglass.Renderer.render(message)` on a HEEx-based mailable and receive inlined-CSS HTML + auto-generated plaintext in under 50ms with four-level whitelist-guarded telemetry, pattern-matchable errors, and compiler-enforced boundary purity — all without persistence or transport.

Ready for Phase 2 (Persistence + Tenancy).

---

_Verified: 2026-04-22T12:00:00Z_
_Verifier: Claude (gsd-verifier)_
