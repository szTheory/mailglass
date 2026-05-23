---
phase: 45-inbound-telemetry-idempotency-foundation
verified: 2026-05-23T10:31:51Z
status: gaps_found
score: 6/8 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 5/7
  gaps_closed:
    - "CR-01: NoBareOptionalDepReference now keys gated_modules on the real Erlang call-site atoms :mimemail / :gen_smtp_client (verified in .credo.exs:45-46), with an Erlang-atom regression test + default-params negative control. The atom-keyed guard now fires on a bare :mimemail.decode(...) outside the gateway."
    - "WR-02 (clause): TelemetryEventConvention now has a :telemetry.span/3 walk clause with the min_segments-1 threshold (telemetry_event_convention.ex:52-63). The clause is correct in isolation. (But see gaps — it never fires on REAL inbound code.)"
    - "WR-03: a dedicated inbound_compile_no_optional_deps CI lane exists (ci.yml:239-278), and Mailglass.Oban.TenancyMiddleware was added to inbound mix.exs no_warn_undefined (mix.exs:57)."
    - "PII egress: inbound plug.ex no longer interpolates inspect(reason) of a changeset into the 500 body — it returns a static %{status: \"error\", reason: \"persist_failed\"} (plug.ex:98) and logs only field names via Ecto.Changeset.traverse_errors (plug.ex:149-154). A NoPiiInResponseBody egress check + test were added and registered (.credo.exs:79)."
    - "DOC honesty: gen_smtp.ex moduledoc now correctly attributes :undef to rescue (gen_smtp.ex:24,27-30); mime.ex moduledoc now states :max_depth does NOT defend against boundary-bomb DoS (mime.ex:29-35)."
  gaps_remaining:
    - "WR-02 charter (cover :telemetry.span/3 on REAL inbound code) — the new clause only matches a literal :telemetry.span([...], ...) call, but every real inbound emission routes a VARIABLE prefix through the private span/3 wrapper, so the clause never fires on the package it was widened to cover."
  regressions:
    - "A NEW instance of the exact defect class this phase exists to eliminate shipped IN this gap-closure cycle: Mailglass.Credo.StreamPolicyConsistent is defined + (newly) tested but NOT registered in .credo.exs, so mix credo never runs it. The recurrence backstop (checks_have_tests_test.exs) cannot detect it because it only checks test-FILE existence, not registration."
gaps:
  - truth: >-
      The "claimed-but-inert custom Credo guard" defect class is SELF-DETECTING:
      every custom check in credo_checks/*.ex is both REGISTERED in .credo.exs AND
      covered by a test, with a meta-test that fails CI if either is missing.
    status: failed
    reason: >-
      This is the phase's defining goal, and it is NOT met on two counts. (1) The
      meta-test checks_have_tests_test.exs verifies ONLY test-file existence
      (`File.exists?("test/mailglass/credo/#{base}_test.exs")`, line 18) — it
      globs credo_checks/*.ex and asserts a matching *_test.exs for each. It NEVER
      opens .credo.exs and NEVER asserts registration. So the "or registration is
      missing" half of the goal has no enforcement at all. (2) A live instance of
      exactly the inert-guard defect proves the blind spot: Mailglass.Credo.
      StreamPolicyConsistent (credo_checks/stream_policy_consistent.ex) is a real,
      substantive safety check (it enforces the CLAUDE.md open/click-tracking
      discipline — tracking-enabled mailables MUST declare an explicit :bulk /
      :operational stream) that is DEFINED, has a test (added THIS phase by 45-09),
      but appears 0 times in .credo.exs (`requires:` only LOADS it; the `checks`
      list never includes it). git log -S "StreamPolicyConsistent" -- .credo.exs is
      empty — it was never registered. So `mix credo` never runs it, and the
      meta-test passes green (the test file exists) while the guard is inert. The
      45-09 SUMMARY claim "This meta-test would have caught CR-01, WR-02, and the
      two checks Task 1 just covered" is true only for the test-existence dimension;
      it would NOT have caught (and does not catch) an unregistered check — which is
      the precise defect that shipped here. The config sentinel
      (credo_config_sentinel_test.exs) also only pins two load-bearing keys
      (:mimemail/:gen_smtp_client, :mailglass_inbound); it does not assert
      full-check registration.
    artifacts:
      - path: "credo_checks/stream_policy_consistent.ex"
        issue: "Defines Mailglass.Credo.StreamPolicyConsistent (a real tracking-stream safety guard) but the module is absent from .credo.exs checks — it never runs under mix credo. Inert guard."
      - path: ".credo.exs"
        issue: "extra_checks registers 16 of the 17 credo_checks/*.ex modules; Mailglass.Credo.StreamPolicyConsistent is the one omitted (grep count 0). requires: ['./credo_checks/*.ex'] loads it but does not register it."
      - path: "test/mailglass/credo/checks_have_tests_test.exs"
        issue: "Meta-test asserts only File.exists? of the matching *_test.exs (line 18). It does not load .credo.exs and does not verify registration, so it cannot detect a defined-but-unregistered (inert) check — the exact defect class the phase is chartered to make self-detecting."
    missing:
      - "Register the inert guard: add {Mailglass.Credo.StreamPolicyConsistent, []} to .credo.exs extra_checks so mix credo actually runs it (then confirm mix credo --strict stays green or fix any findings it surfaces in lib/)."
      - "Close the meta-test blind spot: extend checks_have_tests_test.exs (or add a companion to credo_config_sentinel_test.exs) to load .credo.exs via Code.eval_file, build the registered-module set from the checks list, and assert every credo_checks/*.ex module is registered — failing CI loudly when a check is defined but not wired in. The goal requires detecting BOTH a missing test AND a missing registration."
  - truth: >-
      TelemetryEventConvention covers :telemetry.span/3 on REAL inbound code (WR-02
      charter): an under-segmented or non-mailglass inbound span event is caught at
      lint time.
    status: partial
    reason: >-
      The new span-aware walk clause (telemetry_event_convention.ex:52-63) is
      correct in isolation — a literal :telemetry.span([:wrong_app, :x], ...) is
      flagged and a 3-segment [:mailglass_inbound, :ingress, :request] prefix
      passes (locked by fixture tests). BUT every real inbound emission routes the
      literal event name through the package's named helpers (ingress_span/2 etc.,
      telemetry.ex:73-122), which call the PRIVATE span/3 (telemetry.ex:135), which
      calls :telemetry.span(event_prefix, ...) with a VARIABLE event_prefix
      (telemetry.ex:136). The check's literal_atom_list/1 returns :error for a
      variable, so the clause is a no-op against production: grep for a literal-list
      :telemetry.span/:execute call across lib/ + mailglass_inbound/lib/ returns
      ZERO matches. So the widened required_root: [:mailglass, :mailglass_inbound]
      is still inert for the inbound span events it was meant to cover. WR-02's
      literal requirement (add a span clause + fixtures) is satisfied; WR-02's
      CHARTER (validate the inbound sibling package's actual event names) is not.
      The check's own moduledoc claims the 4-level convention "is enforced for BOTH
      :telemetry.execute/3 and :telemetry.span/3" — true for direct literal call
      sites, untrue for the wrapper-routed names that are the only ones inbound
      emits.
    artifacts:
      - path: "credo_checks/telemetry_event_convention.ex"
        issue: "The :telemetry.span/3 clause only matches a literal-prefix call. The only real :telemetry.span call site (mailglass_inbound telemetry.ex:136) passes a variable prefix, so the clause never fires on real inbound code."
      - path: "mailglass_inbound/lib/mailglass_inbound/telemetry.ex"
        issue: "Literal event lists live in the named span helpers (lines 74,89,104,122) and are passed to the private span/3 (line 135), which calls :telemetry.span with a variable — invisible to the AST check."
    missing:
      - "Either (a) extend the check to validate the literal atom-list arguments at the package's own *_span helper definition sites (where the event name IS a literal), which is the only option that actually covers inbound; or (b) explicitly downgrade the moduledoc/charter claim to 'guards direct literal :telemetry.* call sites only' and accept that wrapper-routed names are out of scope (a doc-honesty fix, not a coverage fix)."
deferred:
  - truth: "Admin LiveView subscribes to inbound updates via MailglassAdmin.PubSub.Topics (admin-side consumer wiring)"
    addressed_in: "Phase 48"
    evidence: "REQUIREMENTS.md IADM-05 maps the InboundLive subscription to the Phase 48 admin LiveView; Phase 45 delivers only the broadcast surface (MailglassInbound.PubSub.Topics.inbound_record_inserted/1), which is present."
  - truth: "Boundary-bomb / deep-nesting DoS is mitigated by a real MIME decoder-level recursion limit (WR-01)"
    addressed_in: "Phase 46"
    evidence: "The :max_depth guard bounds the internal representation only, not :mimemail decoder recursion; full provider-fed DoS hardening is a Phase 46 transport-wiring concern. The never-raise contract (MIME-04) holds, and the moduledoc was corrected this phase (45-08) to stop overclaiming the protection."
human_verification:
---

# Phase 45: Inbound Telemetry + Idempotency Foundation Verification Report

**Phase Goal:** Establish the inbound telemetry + idempotency foundation for mailglass_inbound (v1.2), AND — via a gap-closure cycle (plans 45-05..09) — close the prior gaps_found findings (CR-01, WR-02, WR-03, PII egress, DOC honesty) plus the DEFINING goal: make the "claimed-but-inert custom Credo guard" defect class SELF-DETECTING — every custom check both REGISTERED in `.credo.exs` AND covered by a test, with a meta-test that fails CI if either is missing.

**Verified:** 2026-05-23T10:31:51Z
**Status:** gaps_found
**Re-verification:** Yes — after gap-closure cycle (plans 45-05..09) following the prior gaps_found verification (2026-05-22)

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | CR-01 closed: a bare `:mimemail.decode(...)` / `:gen_smtp_client` outside the gateway is caught by NoBareOptionalDepReference | ✓ VERIFIED | `.credo.exs:45-46` now keys gated_modules on the real Erlang atoms `:mimemail => Mailglass.OptionalDeps.GenSmtp` and `:gen_smtp_client => ...`. The check's `root_module/1` returns `{:ok, :mimemail}` for a bare-atom call, which now hits a map key. Regression test in no_bare_optional_dep_reference_test.exs threads the explicit atom-key param + a default-params negative control. The `GenSmtp` alias key is retained for the aliased `OptionalGenSmtp.decode` path. |
| 2 | WR-03 closed: an inbound `mix compile --no-optional-deps --warnings-as-errors` CI lane exists | ✓ VERIFIED | `inbound_compile_no_optional_deps` job at ci.yml:239-278 (compile-only, 1.18/OTP 27, two-step deps.get, working-directory mailglass_inbound). `Mailglass.Oban.TenancyMiddleware` added to inbound mix.exs no_warn_undefined (mix.exs:57) so the static-xref warning that made the compile exit 1 is suppressed. CI is the source of truth (local toolchain caveat); the lane + fix ship together. |
| 3 | PII egress closed: inbound plug.ex does not leak recipient PII (no inspect(reason) of a changeset) into the response body | ✓ VERIFIED | plug.ex:98 returns a STATIC `%{status: "error", reason: "persist_failed"}` 500 body; `log_persist_failure/1` (plug.ex:149-154) logs only changeset FIELD NAMES via `Ecto.Changeset.traverse_errors`, never `changes` values. The remaining `inspect(reason)` (plug.ex:359) is a Logger.debug for a PubSub broadcast exit — not a response body. NoPiiInResponseBody egress check + test added and registered (.credo.exs:79). Status stays 500 (correct retry signal). |
| 4 | DOC honesty closed: moduledocs do not overclaim protections the code does not deliver | ✓ VERIFIED | gen_smtp.ex moduledoc now correctly attributes `:undef` to `rescue` (a class-:error), not `catch :exit` (gen_smtp.ex:24,27-30). mime.ex moduledoc now explicitly states `:max_depth` "does NOT by itself defend against provider-fed deep-nesting (boundary-bomb) DoS" and defers real hardening to a future phase (mime.ex:29-37). |
| 5 | Two previously-uncovered checks each have a positive+negative regression test | ✓ VERIFIED | require_atomic_unsubscribe_headers_test.exs and stream_policy_consistent_test.exs both exist in test/mailglass/credo/ with the documented positive (one issue) + negative (==[]) cases. (Note: covering StreamPolicyConsistent with a test while leaving it UNREGISTERED is precisely what masks the truth #7 failure.) |
| 6 | The load-bearing .credo.exs keys for CR-01 and WR-02 are pinned by a config sentinel | ✓ VERIFIED | credo_config_sentinel_test.exs loads `.credo.exs` via Code.eval_file and asserts `:mimemail` + `:gen_smtp_client` in NoBareOptionalDepReference gated_modules and `:mailglass_inbound` in TelemetryEventConvention required_root. Pins the two load-bearing keys against drift. (Does NOT pin full-check registration — see truth #7.) |
| 7 | DEFINING GOAL: the inert-guard defect class is SELF-DETECTING — every check is both REGISTERED in .credo.exs AND tested, with a meta-test that fails CI if either is missing | ✗ FAILED | The meta-test (checks_have_tests_test.exs:18) checks ONLY `File.exists?` of the matching test file — it never reads .credo.exs and never asserts registration. The "or registration missing" half of the goal has zero enforcement. Live proof of the blind spot: `Mailglass.Credo.StreamPolicyConsistent` is defined + tested but appears 0 times in .credo.exs (`requires:` loads it; the `checks` list omits it), so `mix credo` never runs it. 17 check files, 16 registered modules. The meta-test passes green while a real safety guard is inert — the exact defect class the phase exists to eliminate, recurring INSIDE the gap-closure cycle. |
| 8 | WR-02 charter: TelemetryEventConvention covers :telemetry.span/3 on REAL inbound code | ⚠ PARTIAL | The new span clause (telemetry_event_convention.ex:52-63) is correct in isolation and tested, but matches only literal-prefix `:telemetry.span([...], ...)` calls. Every real inbound emission routes a VARIABLE prefix through the private span/3 wrapper (telemetry.ex:135-136), so the clause is a no-op against production (grep: zero literal-list :telemetry.span/.execute calls in either package). The widened required_root remains inert for inbound spans. WR-02's literal task is done; its charter is not. |

**Score:** 6/8 truths verified (truth #7 FAILED — the defining goal; truth #8 PARTIAL — clause added but inert on real code)

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Admin-side inbound subscription wiring (MailglassAdmin.PubSub.Topics consumer) | Phase 48 | IADM-05 maps the InboundLive subscription to Phase 48; Phase 45 delivers only the broadcast surface (present). |
| 2 | Boundary-bomb / deep-nesting DoS mitigation (real decoder recursion limit, WR-01) | Phase 46 | :max_depth bounds the internal repr only; full DoS hardening is a Phase 46 transport concern. Never-raise (MIME-04) holds; moduledoc corrected this phase. |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `.credo.exs` | gated_modules keyed on :mimemail/:gen_smtp_client; span-aware convention entry; all custom checks registered | ⚠ VERIFIED-WITH-DEFECT | CR-01 atom keys present (45-46); convention entry widened (66-67); NoPiiInResponseBody registered (79). BUT StreamPolicyConsistent (1 of 17 check modules) is NOT registered — inert guard. |
| `credo_checks/telemetry_event_convention.ex` | :telemetry.span/3 walk clause, min_segments-1 threshold, shared validate helper | ⚠ ORPHANED (against real code) | Clause exists (52-63) with the correct threshold and shared validate/8. Correct in isolation; never fires on the variable-prefix wrapper that is the only real inbound span call site. |
| `credo_checks/stream_policy_consistent.ex` | a real tracking-stream guard, registered + tested | ✗ UNREGISTERED | Substantive guard (enforces CLAUDE.md tracking discipline). Has a test (45-09) but is absent from .credo.exs checks — never run by mix credo. |
| `credo_checks/no_pii_in_response_body.ex` | egress PII guard, registered + tested | ✓ VERIFIED | Registered (.credo.exs:79, path-scoped to webhook+ingress), test present. (Code review WR-02/03 note real false negatives for differently-named error vars / two-step payload construction — latent, not an active leak.) |
| `test/mailglass/credo/checks_have_tests_test.exs` | meta-test asserting registration AND test for every check | ✗ INCOMPLETE | Asserts only test-file existence (File.exists?, line 18). Does not verify registration. Cannot detect an inert (unregistered) check. |
| `test/mailglass/credo/credo_config_sentinel_test.exs` | pins load-bearing keys | ✓ VERIFIED | Pins :mimemail/:gen_smtp_client + :mailglass_inbound. Does not assert full registration (by design — but that leaves the registration gap uncovered). |
| `mailglass_inbound/mix.exs` | no_warn_undefined includes Mailglass.Oban.TenancyMiddleware | ✓ VERIFIED | Line 57: `[Oban, Oban.Job, Oban.Worker, Mailglass.Oban.TenancyMiddleware]`. |
| `.github/workflows/ci.yml` | inbound --no-optional-deps lane | ✓ VERIFIED | inbound_compile_no_optional_deps job (239-278). |
| `mailglass_inbound/lib/.../ingress/plug.ex` | PII-free static error body + field-name-only logging | ✓ VERIFIED | Static body (98); traverse_errors field-names only (149-154). |
| `lib/mailglass/optional_deps/gen_smtp.ex` + `mailglass_inbound/lib/.../mime.ex` | corrected moduledocs | ✓ VERIFIED | :undef-under-rescue (gen_smtp.ex:24-30); :max_depth-not-a-DoS-defense (mime.ex:29-37). |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `.credo.exs` gated_modules | bare `:mimemail` / `:gen_smtp_client` call sites | NoBareOptionalDepReference Map.fetch on the Erlang atom | ✓ WIRED | Atom keys present (.credo.exs:45-46); CR-01 closed. |
| `.credo.exs` checks list | `credo_checks/stream_policy_consistent.ex` | registration in extra_checks | ✗ NOT_WIRED | Module absent from .credo.exs (grep count 0); guard never runs. |
| `checks_have_tests_test.exs` | `.credo.exs` registration | Code.eval_file + registered-set assertion | ✗ NOT_WIRED | Meta-test never opens .credo.exs; only File.exists? on test paths. |
| `.credo.exs` TelemetryEventConvention | real inbound `:telemetry.span/3` events | span-aware walk clause on a literal prefix | ✗ NOT_WIRED | Real call site passes a variable prefix (telemetry.ex:136); literal_atom_list returns :error; clause never fires. |
| `mailglass_inbound/mix.exs` no_warn_undefined | worker.ex cross-package Oban ref | static-xref suppression | ✓ WIRED | mix.exs:57. |
| `ci.yml inbound_compile_no_optional_deps` | inbound --no-optional-deps build | two-step deps.get + compile --warnings-as-errors | ✓ WIRED | ci.yml:239-278. |
| inbound plug.ex {:error} branch | static persist_failed body | no interpolation of reason | ✓ WIRED | plug.ex:98. |

### Data-Flow Trace (Level 4)

Phase deliverables under re-verification are lint/CI/config mechanisms and a static error body, not dynamic-data-rendering artifacts. The functional telemetry/MIME/convergence data flows were VERIFIED FLOWING in the prior verification (2026-05-22) and are unchanged by the gap-closure cycle (45-05..09 touch only .credo.exs, credo_checks, tests, ci.yml, mix.exs, plug.ex error path, and moduledocs). No regression to those flows is observable. N/A for the gap-closure artifacts.

### Behavioral Spot-Checks

Static/grep verification only. Per the phase toolchain caveat, no `mix` was run: the inbound package's deps are not fetched in the working tree, and local Elixir 1.19/OTP 28 differs from CI's pinned 1.18/OTP 27, so a local run is not a reliable signal. CI is the authoritative green-proof channel for the test assertions; the registration/coverage defects below are observable in source independent of any run.

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Custom check files count | `ls credo_checks/*.ex \| wc -l` | 17 | ✓ PASS |
| Registered Mailglass.Credo.* modules in .credo.exs | `grep -oE "Mailglass\.Credo\.[A-Za-z]+" .credo.exs \| sort -u \| wc -l` | 16 | ✗ FAIL (1 unregistered) |
| Unregistered check | per-file defmodule vs .credo.exs grep | `Mailglass.Credo.StreamPolicyConsistent` | ✗ FAIL (inert guard) |
| StreamPolicyConsistent ever registered | `git log -S StreamPolicyConsistent -- .credo.exs` | empty | ✗ FAIL (never registered) |
| Meta-test inspects registration | `grep -E "eval_file\|:checks\|register" checks_have_tests_test.exs` | none (only a comment) | ✗ FAIL (test-existence only) |
| Literal-list :telemetry.span/.execute calls (real code) | `grep -rn ':telemetry\.\(span\|execute\)(\[:' lib/ mailglass_inbound/lib/` | 0 matches | ✗ FAIL (span clause inert on real code) |
| CR-01 atom keys present | `grep -n ':mimemail\|:gen_smtp_client' .credo.exs` | lines 45-46 | ✓ PASS |
| Inbound no-optional-deps CI lane | `grep -n inbound_compile_no_optional_deps ci.yml` | line 239 | ✓ PASS |
| plug.ex static error body | `grep -n persist_failed plug.ex` | line 98 | ✓ PASS |
| integration_test.exs stale duplicate (WR-05) | `grep -n '@extra_checks\|required_root: :mailglass' integration_test.exs` | lines 6, 48 (singular root, length==13) | ℹ stale (drift risk) |

### Probe Execution

No project probes apply to this phase (no `scripts/*/tests/probe-*.sh`; phase verification is test/lint/config-based). The phase's own accepted proof channel is CI green on the credo-check test lane — not a local run. N/A.

### Requirements Coverage

All 11 declared IDs map cleanly across the plans; REQUIREMENTS.md line 230 expects exactly `TELE-01..08, MIME-01, MIME-02, MIME-04` for Phase 45. The gap-closure plans (45-05..09) re-declare MIME-02 / TELE-06 (the lint-enforcement requirements). No orphaned requirements (IADM-05 is Phase 48; MIME-03 is Phase 49). The functional requirement implementations were VERIFIED in the prior verification and are unchanged.

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| TELE-01 | 45-02 | ingress span, PII-free | ✓ SATISFIED | plug.ex ingress span; PII-free asserts (prior verification) |
| TELE-02 | 45-02 | route span | ✓ SATISFIED | matcher.ex span (prior) |
| TELE-03 | 45-02 | execution span (wraps execute/2) | ✓ SATISFIED | execution.ex span (prior) |
| TELE-04 | 45-02 | persist span | ✓ SATISFIED | persist.ex span (prior) |
| TELE-05 | 45-02 | raising handler does not break business logic | ✓ SATISFIED | telemetry_test raising-handler case (prior) |
| TELE-06 | 45-01, 45-05, 45-07, 45-09 | NoPIIInTelemetry extended to inbound; egress PII guard; convention coverage | ⚠ PARTIAL | NoPiiInTelemetryMeta covers inbound + NoPiiInResponseBody egress guard registered — both satisfied. BUT the convention-check arm (TelemetryEventConvention span clause) is inert on real inbound code (truth #8), and the recurrence-backstop meta-mechanism (the lint self-detection this requirement's gap-closure was about) does not detect unregistered checks (truth #7). |
| TELE-07 | 45-02 | events surfaced for admin live updates | ✓ SATISFIED (surface) | topics.ex + post-commit broadcast (prior); admin consumption is Phase 48 |
| TELE-08 | 45-04 | 1000-replay convergence property | ✓ SATISFIED | convergence test, max_runs: 1000, real Postgres (prior) |
| MIME-01 | 45-03, 45-08 | RFC 5322 → stable repr; honest moduledoc | ✓ SATISFIED | parse/1,2 + corrected :max_depth moduledoc |
| MIME-02 | 45-03, 45-05, 45-06, 45-09 | gated through GenSmtp; lint guard enforces it; degraded fallback | ✓ SATISFIED | Runtime gating correct; CR-01 lint guard now fires on bare atoms; --no-optional-deps lane added. (StreamPolicyConsistent is unrelated to MIME-02 — its inertness is a separate, defining-goal failure.) |
| MIME-04 | 45-03, 45-08 | malformed never raises; structured error; honest moduledoc | ✓ SATISFIED | gateway absorbs throw/exit/error; corrected :undef moduledoc |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `.credo.exs` | (omission) | Mailglass.Credo.StreamPolicyConsistent defined but not in the checks list — inert custom guard | 🛑 Blocker | A real safety check (tracking-stream discipline) never runs; this is the exact "claimed-but-inert guard" defect class the phase exists to eliminate, recurring inside the gap-closure cycle. |
| `test/mailglass/credo/checks_have_tests_test.exs` | 18 | Meta-test asserts only test-file existence, not registration | 🛑 Blocker | The recurrence backstop cannot detect an inert (unregistered) check — the defining-goal mechanism is itself incomplete and falsely certifies coverage (StreamPolicyConsistent passes it while inert). |
| `credo_checks/telemetry_event_convention.ex` | 52-63 | span clause matches only literal prefixes; real inbound spans route a variable prefix | ⚠ Warning | Widened required_root inert for inbound spans; moduledoc "enforced for BOTH" overclaims for wrapper-routed names. |
| `test/mailglass/credo/integration_test.exs` | 6, 48 | Stale, hand-maintained duplicate of .credo.exs check params (required_root: :mailglass singular, no :mimemail atom key, asserts length==13) | ⚠ Warning | Cannot detect/protect against .credo.exs drift; exercises params that no longer match production; would not have caught CR-01/WR-02. (Out of this phase's direct file scope but undermines verification of the in-scope config.) |
| `credo_checks/no_pii_in_response_body.ex` | 105-183 | Real false negatives: a changeset bound to a non-reason/changeset-named var, or a payload built in a prior assignment, escapes the guard | ⚠ Warning | Latent — current plug.ex code is clean (static body), so no active leak; but the obvious future refactor would silently bypass the egress guard. |
| `.credo.exs` | 36-39 | Rationale comment for the retained GenSmtp alias key is factually wrong (Credo does not resolve aliases; OptionalGenSmtp.decode passes by missing the map, not by matching GenSmtp) | ℹ Info | A maintainer trusting it could re-introduce the inert-key bug; CR-01 coverage actually rides entirely on the :mimemail/:gen_smtp_client atom keys. |

No `TBD`/`FIXME`/`XXX` debt markers found in the phase-modified files.

### Human Verification Required

None. All gap-closure deliverables are verifiable statically. The two blocking gaps (unregistered StreamPolicyConsistent; meta-test that checks only test existence) are source-observable and do not require human or runtime confirmation. CI execution of the credo/test lanes is the normal gate, not a manual-UAT item.

### Gaps Summary

The functional foundation (truths #1-#6) and the four "ordinary" gap-closure items are genuinely closed and substantive: CR-01's atom-keyed guard now fires, the inbound `--no-optional-deps` CI lane exists with its compile fix, the inbound plug no longer leaks changeset PII into the 500 body, and the two doc-honesty corrections are accurate. All 11 requirement IDs remain accounted for; the functional telemetry/MIME/convergence work verified previously is intact.

But the phase's **defining goal** — making the "claimed-but-inert custom Credo guard" defect class self-detecting via REGISTRATION + TEST coverage with a meta-test that fails CI if either is missing — is **not met**, and the failure is demonstrated by a live recurrence of that exact defect inside this very gap-closure cycle:

1. **Inert guard shipped (BLOCKER):** `Mailglass.Credo.StreamPolicyConsistent` is a real safety check that is defined and (now) tested but is NOT registered in `.credo.exs` (0 occurrences; never registered per git history). `mix credo` never runs it. 17 check files, 16 registered.

2. **The recurrence backstop has the matching blind spot (BLOCKER):** `checks_have_tests_test.exs` asserts only `File.exists?` of a `*_test.exs` — it never reads `.credo.exs` and never verifies registration. So it both (a) fails to catch the unregistered StreamPolicyConsistent and (b) is structurally incapable of detecting the "registration missing" half the goal explicitly names. The 45-09 SUMMARY's claim that the meta-test "would have caught CR-01, WR-02, and the two checks" holds only for test-existence; an unregistered check is invisible to it. The config sentinel pins two keys but not full registration.

3. **WR-02 charter not met (WARNING/PARTIAL):** the new `:telemetry.span/3` clause is correct in isolation but never fires on real inbound code, because every real emission routes a variable prefix through the private span wrapper. The widened root stays inert for inbound spans, and the moduledoc overclaims enforcement.

The fix is small and well-scoped: register `StreamPolicyConsistent` in `.credo.exs`, and extend the meta-test to load `.credo.exs` and assert every `credo_checks/*.ex` module is in the checks list (failing CI on a defined-but-unregistered check). Recommend `/gsd:plan-phase --gaps`. Also recommend (non-blocking) deciding WR-02 charter (extend the check to the span-helper definition sites OR downgrade the moduledoc claim) and de-duplicating `integration_test.exs` against the live config.

---

_Verified: 2026-05-23T10:31:51Z_
_Verifier: Claude (gsd-verifier)_
