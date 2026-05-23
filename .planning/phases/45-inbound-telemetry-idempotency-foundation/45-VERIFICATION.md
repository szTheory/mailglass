---
phase: 45-inbound-telemetry-idempotency-foundation
verified: 2026-05-23T14:25:00Z
status: passed
score: 8/8 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 6/8
  gaps_closed:
    - "DEFINING GOAL (prior truth #7): StreamPolicyConsistent is now REGISTERED in .credo.exs (grep count 1; 17/17 Mailglass.Credo.* modules present) and runs under mix credo. mix credo --strict exits 0 with it active (verified live, 73 checks / 376 files / 0 issues). The meta-test checks_have_tests_test.exs now has a SECOND test asserting .credo.exs registration via Code.eval_file (no allowlist). TEETH independently proven: removing StreamPolicyConsistent from a .credo.exs copy makes the meta-test's `unregistered` list == [Mailglass.Credo.StreamPolicyConsistent], failing `assert unregistered == []` by name. The exact inert-guard defect class is now self-detecting on BOTH dimensions."
    - "WR-02 CHARTER (prior truth #8, was PARTIAL): TelemetryEventConvention now validates literal event names at the span-WRAPPER call sites (span / span_with_enrichment), where the real inbound literals actually live. Independently proven against the LIVE mailglass_inbound/lib/mailglass_inbound/telemetry.ex: unmodified -> 0 issues; mutating one real prefix root ([:mailglass_inbound,:ingress,:request] -> [:wrong_app,...]) -> exactly 1 issue (trigger=span, line 74). The check fires on REAL inbound code, no longer inert."
    - "WR-04: the false GenSmtp-alias-key comment in .credo.exs is corrected (the phrase 'resolves to the GenSmtp alias' is gone; the comment now states Credo does not resolve aliases and CR-01 coverage rides on the :mimemail/:gen_smtp_client atom keys)."
    - "WR-05: integration_test.exs no longer carries a stale @extra_checks literal (count 0), no singular `required_root: :mailglass` (count 0), no hardcoded `== 13` (count 0); it sources params from the live .credo.exs via Code.eval_file (count 2) and preserves @check_cases. Runs green (3 tests, 0 failures)."
    - "WR-03 egress false negative: NoPiiInResponseBody now catches the err-bound differently-named error variable (WR-02 leak shape) AND the two-step `payload = ...; send_json(conn, 500, payload)` construction (WR-03) via the mandated bare-variable body-arg rule, while preserving the static-map and Jason-encoded-body carve-outs. Two new regression tests pass (8 tests, 0 failures)."
    - "IN-01: gen_smtp.ex available?/0 @doc note added (proxy probe + :mimemail-via-decode/2-rescue); behavior unchanged (Code.ensure_loaded?(:gen_smtp_client))."
  gaps_remaining: []
  regressions: []
deferred:
  - truth: "Admin LiveView subscribes to inbound updates via MailglassAdmin.PubSub.Topics (admin-side consumer wiring)"
    addressed_in: "Phase 48"
    evidence: "REQUIREMENTS.md IADM-05 maps the InboundLive subscription to the Phase 48 admin LiveView; Phase 45 delivers only the broadcast surface (present, verified prior round)."
  - truth: "Boundary-bomb / deep-nesting DoS is mitigated by a real MIME decoder-level recursion limit (WR-01 round-1)"
    addressed_in: "Phase 46"
    evidence: "The :max_depth guard bounds the internal representation only; full provider-fed DoS hardening is a Phase 46 transport-wiring concern. The never-raise contract (MIME-04) holds; moduledoc corrected in 45-08."
---

# Phase 45: Inbound Telemetry + Idempotency Foundation Verification Report

**Phase Goal:** Bring mailglass_inbound to outbound-equivalent observability/correctness maturity: a single telemetry span surface with fixed event names + per-tenant PubSub, a never-raise MIME parser, idempotent replay convergence, and cross-package Credo lint coverage that actually runs (no inert/unregistered guards). This run is **gap-closure round 2** (plans 45-10, 45-11, 45-12; all REQ TELE-06), closing the two BLOCKERS the prior verification (2026-05-23 06:31) left open: the inert-guard / meta-test blind spot, and the WR-02 charter.

**Verified:** 2026-05-23T14:25:00Z
**Status:** passed
**Re-verification:** Yes — after gap-closure round 2 (plans 45-10/11/12) following the prior gaps_found verification (score 6/8)

## Goal Achievement

### Observable Truths

The two truths that previously FAILED/PARTIAL (#7, #8) are the focus of this re-verification; the six previously-VERIFIED truths get a regression check.

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | CR-01: a bare `:mimemail.decode(...)` / `:gen_smtp_client` outside the gateway is caught by NoBareOptionalDepReference (atom keys live) | ✓ VERIFIED (regression) | `.credo.exs:53-54` keys gated_modules on `:mimemail`/`:gen_smtp_client`. grep counts: `:mimemail` 5, `:gen_smtp_client` 3. credo_config_sentinel_test still pins them (10 key references). Unchanged this round. |
| 2 | WR-03: inbound `--no-optional-deps` CI lane exists; TenancyMiddleware in no_warn_undefined | ✓ VERIFIED (regression) | `inbound_compile_no_optional_deps` present in ci.yml (count 1); `Mailglass.Oban.TenancyMiddleware` in mailglass_inbound/mix.exs (count 2). Unchanged this round. |
| 3 | PII egress: inbound plug.ex returns a STATIC `persist_failed` 500 body (no inspect(reason) of a changeset) | ✓ VERIFIED (regression) | `persist_failed` static body present in ingress plug.ex (count 1, line 98). All gated-surface sink calls use inline literals or the Jason-encoded `body` carve-out (grep of webhook/+ingress/ confirms; no bare-var leak). |
| 4 | DOC honesty: moduledocs do not overclaim; gen_smtp `:undef`-under-rescue; mime `:max_depth` not a DoS defense | ✓ VERIFIED (regression) | Carried from prior round (45-08); not touched by round-2 except the additive IN-01 `available?/0` proxy note. |
| 5 | The previously-uncovered checks each have a positive+negative regression test | ✓ VERIFIED | stream_policy_consistent_test.exs passes 4/4 in isolation; require_atomic_unsubscribe_headers covered. Full credo dir = 93 tests, 0 failures. |
| 6 | The load-bearing .credo.exs keys are pinned by a config sentinel | ✓ VERIFIED (regression) | credo_config_sentinel_test.exs pins `:mimemail`/`:gen_smtp_client`/`:mailglass_inbound` (10 references); part of the 93/0 credo suite. |
| 7 | DEFINING GOAL: the inert-guard defect class is SELF-DETECTING — every check is both REGISTERED in .credo.exs AND tested, with a meta-test that fails CI if EITHER is missing | ✓ VERIFIED (was FAILED) | (a) StreamPolicyConsistent registered in `.credo.exs` extra_checks (line 129-130, count 1); 17 check files == 17 registered `Mailglass.Credo.*` modules. (b) `mix credo --strict` run live: exit 0, 73 checks / 376 files / "found no issues" with StreamPolicyConsistent ACTIVE. (c) checks_have_tests_test.exs now has TWO tests: test-existence (preserved) + registration (NEW, Code.eval_file + flatten_checks + Module.concat/Macro.camelize, no allowlist). (d) TEETH proven independently: removing StreamPolicyConsistent from a copy of `.credo.exs` and running the meta-test's exact normalization yields `unregistered == [Mailglass.Credo.StreamPolicyConsistent]` → `assert unregistered == []` would FAIL by name. With the live config the suite passes 93/0. |
| 8 | WR-02 CHARTER: TelemetryEventConvention covers `:telemetry.span/3` on REAL inbound code — an under-segmented/non-mailglass inbound event name is caught at lint time | ✓ VERIFIED (was PARTIAL) | The new span-wrapper `walk/5` clauses (telemetry_event_convention.ex:126-160) validate the literal first-arg prefix at `span([...], ...)` / `Mod.span([...], ...)` wrapper call sites — where the real inbound literals live (telemetry.ex:74,89,104,122). Proven INDEPENDENTLY against the live mailglass_inbound/lib/mailglass_inbound/telemetry.ex with Credo started: unmodified → 0 issues; mutated ingress root → exactly 1 issue (trigger=span, line 74). The private `defp span` variable forward yields `:error` from literal_atom_list (no false positive). The "enforced for BOTH" overclaim is removed (count 0); the test file's real-inbound proof is part of the 17/0 convention test pass. |

**Score:** 8/8 truths verified (both prior gaps closed; no regressions)

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Admin-side inbound subscription wiring (MailglassAdmin.PubSub.Topics consumer) | Phase 48 | IADM-05 maps InboundLive subscription to Phase 48; Phase 45 ships only the broadcast surface (present). |
| 2 | Boundary-bomb / deep-nesting DoS mitigation (real decoder recursion limit) | Phase 46 | :max_depth bounds internal repr only; full DoS hardening is a Phase 46 transport concern. Never-raise (MIME-04) holds. |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `.credo.exs` | StreamPolicyConsistent registered; corrected GenSmtp comment; all 17 checks registered; CR-01 atom keys intact | ✓ VERIFIED | StreamPolicyConsistent registered in extra_checks (129-130, path-scoped to lib/mailglass/ + mailglass_inbound/lib/ per the post-merge fix); 17/17 modules registered; WR-04 comment corrected (false phrase gone, atom-key truth stated); `:mimemail`/`:gen_smtp_client` keys unchanged. |
| `test/mailglass/credo/checks_have_tests_test.exs` | meta-test asserting BOTH test existence AND .credo.exs registration; no allowlist | ✓ VERIFIED | Two tests; registration test uses Code.eval_file/flatten_checks/Module.concat with "Defined-but-unregistered:" enumerating message; allowlist/known_uncovered count 0; runs 2/0; TEETH independently confirmed. |
| `test/mailglass/credo/integration_test.exs` | sources live .credo.exs params; no @extra_checks literal, no `== 13` count | ✓ VERIFIED | @extra_checks 0, `required_root: :mailglass` 0, `== 13` 0, Code.eval_file 2, @check_cases preserved (6); runs 3/0. |
| `credo_checks/telemetry_event_convention.ex` | span-wrapper call-site clause validating literal event names; precise moduledoc | ✓ VERIFIED | Two additive walk/5 clauses (bare-local + qualified) gated by span_wrapper_name?; reuses validate/8 + literal_atom_list/1 + root_issue/5 unchanged; threshold min_segments-1; moduledoc enumerates the three covered forms; "enforced for BOTH" overclaim removed. Fires on real inbound (proven). |
| `test/mailglass/credo/telemetry_event_convention_test.exs` | fire/refute fixtures + real-inbound proof | ✓ VERIFIED | 17 tests / 0 failures; real-inbound proof reads the live inbound telemetry.ex and asserts unmodified→0, mutated→1. |
| `credo_checks/no_pii_in_response_body.ex` | mandated bare-variable body-arg rule; Jason + static carve-outs; def-head exclusion; documented boundary | ✓ VERIFIED | bare_body_variable_leak?/collect_jason_encoded_vars/collect_def_head_sigs/def_head? all present; suspicious_fragments `["reason","changeset","err"]` (no body/resp/payload); multi-hop boundary documented (8 non-comment doc matches); included_path_prefixes unchanged. |
| `test/mailglass/credo/no_pii_in_response_body_test.exs` | err-bound (WR-02) + two-step (WR-03) regression tests; preserved carve-outs | ✓ VERIFIED | 8 tests / 0 failures; WR-02 test (`detail: err`, ==1), WR-03 test (`payload = ...; send_json(...,payload)`, ==1), static-body (==[]), Jason-body (==[]), path-gating (==[]) all present. |
| `lib/mailglass/optional_deps/gen_smtp.ex` | IN-01 available?/0 doc note; behavior unchanged | ✓ VERIFIED | proxy/:mimemail note present (9 matches); available?/0 still `Code.ensure_loaded?(:gen_smtp_client)` (line 57). Doc-only. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `.credo.exs` checks list | `credo_checks/stream_policy_consistent.ex` | `{Mailglass.Credo.StreamPolicyConsistent, [...]}` in extra_checks → spliced into :checks | ✓ WIRED | Registered (count 1); `mix credo --strict` runs it (exit 0, active). |
| `checks_have_tests_test.exs` | `.credo.exs` registration | Code.eval_file + registered-module set + reject-unregistered | ✓ WIRED | Independently proven to fail by name when a check is unregistered. |
| `TelemetryEventConvention` span-wrapper clause | real inbound `span([...], ...)` call sites | bare-atom/qualified walk clause gated by span_wrapper_name?, validate at min_segments-1 | ✓ WIRED | Live proof: mutated real inbound prefix → 1 issue (trigger=span, line 74). |
| `integration_test.exs` | `.credo.exs` | Code.eval_file sourcing live params (no duplicate) | ✓ WIRED | @extra_checks removed; live params exercised; 3/0. |
| `NoPiiInResponseBody` bare-variable rule | err-bound + two-step payload egress shapes | last-positional-arg bare-var rule (minus Jason carve-out) | ✓ WIRED | Both regression tests fire (==1); carve-outs stay clean (==[]). |
| `.credo.exs` gated_modules | bare `:mimemail`/`:gen_smtp_client` call sites | atom-keyed Map.fetch (CR-01) | ✓ WIRED (regression) | Atom keys present; pinned by config sentinel. |

### Data-Flow Trace (Level 4)

The round-2 deliverables are lint/test/config mechanisms and a doc-only change — not dynamic-data-rendering artifacts. The functional telemetry/MIME/convergence data flows were VERIFIED FLOWING in the original verification (2026-05-22) and are untouched by round-2 (which modified only .credo.exs, three credo_checks, two credo test files, and a doc-only gen_smtp.ex — confirmed via git name-only on the round-2 commits). No regression to those flows is observable. N/A for the gap-closure artifacts.

### Behavioral Spot-Checks

Run live in this worktree (Elixir 1.19.5 / OTP 28, deps fetched, _build present). Per-command results:

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Custom check files == registered modules | `ls credo_checks/*.ex \| wc -l` vs distinct `Mailglass.Credo.*` in .credo.exs | 17 == 17 | ✓ PASS |
| StreamPolicyConsistent registered | `grep -c StreamPolicyConsistent .credo.exs` | 1 | ✓ PASS |
| `mix credo --strict` green with guard active | `mix credo --strict` | exit 0; 73 checks / 376 files / found no issues | ✓ PASS |
| Credo test suite | `mix test test/mailglass/credo/` | 93 tests, 0 failures | ✓ PASS |
| Meta-test (both dimensions) | `mix test .../checks_have_tests_test.exs` | 2 tests, 0 failures | ✓ PASS |
| Meta-test registration TEETH | eval mutated .credo.exs (StreamPolicyConsistent removed) through the test's exact normalization | `unregistered == [Mailglass.Credo.StreamPolicyConsistent]` (assertion would fail by name) | ✓ PASS |
| Convention real-inbound coverage | run check on live mailglass_inbound/telemetry.ex (Credo started) + mutated copy | unmodified 0 issues; mutated 1 issue (trigger=span, line 74) | ✓ PASS |
| Convention test file | `mix test .../telemetry_event_convention_test.exs` | 17 tests, 0 failures | ✓ PASS |
| Egress PII test file | `mix test .../no_pii_in_response_body_test.exs` | 8 tests, 0 failures | ✓ PASS |
| Integration test (live config) | `mix test .../integration_test.exs` | 3 tests, 0 failures | ✓ PASS |
| WR-04 comment corrected | `grep -c "resolves to the GenSmtp alias" .credo.exs` | 0 (false phrase gone) | ✓ PASS |
| Egress carve-out preserved | `grep suspicious_fragments` | `["reason","changeset","err"]` (no body/resp/payload) | ✓ PASS |
| Full suite (regression sweep) | `mix test` | 1093 tests, 57 failures, 7 skipped | ℹ ENV — all 57 are Oban-migration / test-DB `RuntimeError`s (oban_jobs table does not exist), unrelated to phase-45 files (see Anti-Patterns / Info) |

### Probe Execution

No project probes apply to this phase (no `scripts/*/tests/probe-*.sh`; the phase's verification surface is the credo test lane + `mix credo --strict`, both run live above). N/A.

### Requirements Coverage

The three round-2 plans (45-10, 45-11, 45-12) each declare exactly `requirements: [TELE-06]`. REQUIREMENTS.md line 230 expects Phase 45 to satisfy `TELE-01..08, MIME-01, MIME-02, MIME-04` (11 IDs). The functional IDs were verified in the original round; round-2 closes the TELE-06 lint-enforcement gaps. No orphaned IDs (IADM-05 → Phase 48; MIME-03 → Phase 49, both correctly out of Phase 45).

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| TELE-01..05 | 45-02 | inbound spans + raising-handler isolation | ✓ SATISFIED (regression) | Verified original round; telemetry.ex single span surface unchanged. |
| TELE-06 | 45-10, 45-11, 45-12 (+ round-1 45-01/05/07/09) | NoPIIInTelemetry extended to inbound; egress PII guard; convention coverage; self-detecting lint | ✓ SATISFIED | All three TELE-06 arms now hold: (a) registration self-detection has teeth (45-10); (b) convention covers REAL inbound spans (45-11, proven live); (c) egress PII guard catches WR-02/WR-03 leak shapes (45-12). 93/0 credo suite + `mix credo --strict` exit 0. |
| TELE-07 | 45-02 | events surfaced for admin live updates | ✓ SATISFIED (surface) | Broadcast surface present (prior); admin consumption is Phase 48 (deferred). |
| TELE-08 | 45-04 | 1000-replay convergence property | ✓ SATISFIED (regression) | Verified original round (unchanged). |
| MIME-01 | 45-03, 45-08 | RFC 5322 → stable repr; honest moduledoc | ✓ SATISFIED (regression) | Unchanged this round. |
| MIME-02 | 45-03/05/06/09 | gated through GenSmtp; lint enforces it; degraded fallback | ✓ SATISFIED | CR-01 lint guard fires on bare atoms; --no-optional-deps lane present; runtime gating correct. |
| MIME-04 | 45-03, 45-08 | malformed never raises; structured error | ✓ SATISFIED (regression) | Unchanged this round. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| credo_checks/telemetry_event_convention.ex | 168-170 | `span_wrapper_name?` matches any `"span"`-prefixed name (e.g. would match `spanish_words`, `spanner`) | ℹ Info | LATENT only — no such function exists in the linted tree (only `span(` and `span_with_enrichment(`); `mix credo --strict` exits 0. Review WR-02 (WARNING). Does not undermine plan-11 must_haves (real-inbound coverage proven, no false positive on real code). Follow-up polish: tighten to `name == "span" or starts_with(name, "span_")`. |
| credo_checks/no_pii_in_response_body.ex | 186-208 | bare-variable body-arg rule flags ANY non-Jason bare body var (would fire on a hoisted static map or a `message_id` string in body position) | ℹ Info | LATENT only — every gated-surface sink call today uses an inline literal or the Jason-encoded `body` carve-out; `mix credo --strict` exits 0. Review WR-01 (WARNING). Inverse risk (over-firing on future safe shapes); does not undermine plan-12 must_haves (WR-02/WR-03 caught, carve-outs preserved). Follow-up polish: narrow to suspicious-fragment names + add `payload`, or widen carve-out to literal-map-bound vars. |
| credo_checks/no_pii_in_response_body.ex | 210-212 | `def_head?` keys exclusion on `{name, line}`; a single-line def-head that also calls the same-named sink suppresses the real call | ℹ Info | LATENT only — edge case (a local fn shadowing a Plug sink, defined+called on one physical line); no such site exists. Review WR-03 (WARNING). Soundness hole but does not undermine any must_have. Follow-up polish: distinguish def head by AST node identity. |
| (full test suite) | — | 57 `mix test` failures, all `Oban migrations have not been run / oban_jobs table does not exist` RuntimeErrors | ℹ Info | ENVIRONMENT, not a phase regression. The test DB in this verification worktree lacks the Oban/Ecto migrations (Mailglass.TestRepo is a test-support repo bootstrapped by the project's own test setup, absent here). Round-2 commits touched only .credo.exs, credo_checks, credo test files, and a doc-only gen_smtp.ex — none touch Oban/Repo/migrations. The credo test surface (the phase deliverable) passes 93/0 in isolation; StreamPolicyConsistentTest passes 4/0 in isolation (its full-suite failures are cascade artifacts of the shared Oban-startup failure). The phase's accepted proof channel is CI (DB properly migrated). |

No 🛑 Blocker anti-patterns. No unreferenced TBD/FIXME/XXX debt markers introduced by this phase.

### Human Verification Required

None. Every round-2 must-have is programmatically verifiable and was confirmed live (credo suite, `mix credo --strict`, independent real-inbound proof, independent meta-test teeth proof). No visual/real-time/external-service behavior is in scope for this lint/config/test phase.

### Gaps Summary

No gaps. Both BLOCKERS from the prior verification (the inert-guard / meta-test blind spot, and the WR-02 charter) are closed and independently confirmed:

1. **Inert-guard defect class is now self-detecting (was the defining-goal FAILURE).** StreamPolicyConsistent is registered and active under `mix credo --strict` (exit 0); the meta-test asserts BOTH a matching test AND `.credo.exs` registration, and I proved by construction that an unregistered check fails the registration assertion by name. The post-merge path-scoping fix (StreamPolicyConsistent scoped to `lib/mailglass/` + `mailglass_inbound/lib/`, matching the sibling checks) keeps `mix credo --strict` green against the two deliberately-bad test fixtures.

2. **WR-02 charter met (was PARTIAL).** TelemetryEventConvention validates literal event names at the span-wrapper call sites where real inbound literals live; proven live against `mailglass_inbound/telemetry.ex` (correct → clean, mutated → flagged).

The three WARNING-level review findings (WR-01/02/03) and the three INFO items (IN-01/02/03) are latent robustness/maintainability gaps that do not fire on today's code and do not undermine any must-have — correctly classified as follow-up polish, not blockers. The full-suite DB failures are an environment setup gap, not a phase-45 regression.

---

_Verified: 2026-05-23T14:25:00Z_
_Verifier: Claude (gsd-verifier)_
