---
phase: 45-inbound-telemetry-idempotency-foundation
verified: 2026-05-22T23:16:09Z
status: gaps_found
score: 5/7 must-haves verified (2 partial)
overrides_applied: 0
re_verification:
gaps:
  - truth: "Optional-dep gating for gen_smtp is enforced at lint time — a bare :mimemail / :gen_smtp_client reference outside the gateway is caught by NoBareOptionalDepReference (the guard MIME-02's gating invariant relies on, asserted in .credo.exs:36-39 and the gateway moduledoc)"
    status: failed
    reason: >-
      gen_smtp is an Erlang library with NO Elixir `GenSmtp` module (confirmed:
      grep for `defmodule GenSmtp` returns nothing in lib/, mailglass_inbound/lib/,
      or deps/; the gateway moduledoc itself states "There is no GenSmtp Elixir
      module"). Call sites reach it via the atoms `:mimemail` (gen_smtp.ex:72) and
      `:gen_smtp_client` (gen_smtp.ex:46). But `.credo.exs:33` keys `gated_modules`
      on the alias `GenSmtp` (= atom `:"Elixir.GenSmtp"`). At a bare call
      `:mimemail.decode(raw)`, the check's `root_module/1` returns `{:ok, :mimemail}`,
      then `Map.fetch(gated_modules, :mimemail)` MISSES (the map has no `:mimemail`
      key), the `with` short-circuits to `nil`, and NO issue is raised. The guard is
      therefore inert for gen_smtp: a bare `:mimemail.decode(...)` anywhere in inbound
      would pass `mix credo --strict`. The 45-01 SUMMARY's "verified by probe" probed
      `Oban.insert` (a real Elixir module the check DOES catch) — the `:mimemail`
      atom path was never probed, and gen_smtp_test.exs has no Credo regression test.
      This contradicts the SUMMARY claim "NoBareOptionalDepReference will catch any
      bare :mimemail reference" and a CLAUDE.md non-negotiable ("Optional deps gated
      through Mailglass.OptionalDeps.* ... NoBareOptionalDepReference Credo check").
      Runtime gating today is correct (no bare reference exists), so MIME-02 itself
      still holds — but the documented protective control does not function.
    artifacts:
      - path: ".credo.exs"
        issue: "gated_modules keys gen_smtp on the phantom `GenSmtp` alias (line 33); call sites use the atoms `:mimemail` / `:gen_smtp_client`, so Map.fetch never matches and no issue is raised"
      - path: "credo_checks/no_bare_optional_dep_reference.ex"
        issue: "root_module/1 returns `:mimemail` for a bare Erlang-atom call (line 105), which is never a key in the gen_smtp-keyed-on-`GenSmtp` map (line 63 Map.fetch misses)"
    missing:
      - "Key gen_smtp on the actual call-site atoms: `:mimemail => [Mailglass.OptionalDeps.GenSmtp, MailglassInbound.OptionalDeps.GenSmtp]` and `:gen_smtp_client => [...]` in .credo.exs gated_modules"
      - "A Credo regression test asserting a fixture module with a bare `:mimemail.decode/1` outside the gateway produces a NoBareOptionalDepReference issue (the Erlang-atom path the existing Oban probe did not cover)"
  - truth: "The lint mechanism that 'now lints mailglass_inbound' actually enforces the telemetry-event convention on the inbound span events (criterion #3 / TELE-06 — the check is extended to cover inbound)"
    status: partial
    reason: >-
      The NoPIIInTelemetry check named in TELE-06 IS correctly extended (`.credo.exs`
      `files.included` widened to `mailglass_inbound/lib/` + `mailglass_inbound/test/`)
      and the telemetry tests assert PII-free metadata across all four spans — so
      TELE-06's literal requirement (NoPIIInTelemetry covers inbound) is satisfied.
      However, the SEPARATE TelemetryEventConvention check, whose `required_root` was
      widened to `[:mailglass, :mailglass_inbound]` (.credo.exs:53-54) to "lint" the
      inbound package, only matches `{{:., _, [:telemetry, :execute]}, ...}`
      (telemetry_event_convention.ex:31). It never matches `:telemetry.span/3`. Every
      inbound event is emitted via `:telemetry.span/3` (telemetry.ex:136), so the
      widened root list is inert: no inbound (or core) span event is ever checked for
      the 4-segment / inbound-root convention. The check's own docstring claims the
      "4-level convention [is enforced] at lint time," which is untrue for span-based
      events. Net: the headline "now lints inbound" guarantee is partially inert for
      the convention check (NoPIIInTelemetry works; TelemetryEventConvention does not).
    artifacts:
      - path: "credo_checks/telemetry_event_convention.ex"
        issue: "walk/5 only matches :telemetry.execute (line 31); :telemetry.span/3 is never inspected, so the widened required_root is inert for all inbound span events"
    missing:
      - "Extend walk/5 to match :telemetry.span/3 prefixes (length(prefix) >= min_segments - 1, since the runtime appends :start/:stop/:exception)"
      - "Add a fixture test covering both :telemetry.execute and :telemetry.span to lock the behavior"
deferred:
  - truth: "Admin LiveView subscribes to inbound updates via MailglassAdmin.PubSub.Topics (the admin-side consumer wiring)"
    addressed_in: "Phase 48"
    evidence: >-
      Criterion #4 requires Phase 45 to deliver the enabling broadcast surface, which
      is present (MailglassInbound.PubSub.Topics.inbound_record_inserted/1 broadcasting
      on the shared Mailglass.PubSub). The admin-side subscription (REQUIREMENTS.md
      IADM-05: "InboundLive subscribes to MailglassAdmin.PubSub.Topics for live updates
      from TELE-07 events") is mapped to the Phase 48 inbound admin LiveView, not Phase
      45. MailglassAdmin.PubSub.Topics currently exposes only admin_reload/0 by design.
  - truth: "Boundary-bomb / deep-nesting DoS is mitigated by the MIME max-depth guard (WR-01)"
    addressed_in: "Phase 46"
    evidence: >-
      The max-depth guard re-walks an ALREADY-decoded tree (decode_and_build calls
      OptionalGenSmtp.decode FIRST at mime.ex:128, which fully parses to any depth via
      :mimemail.decode/2 — no recursion limit in the dep — before collect_leaves runs
      the guard). It bounds the internal representation only, not decoder recursion, so
      it does not stop the boundary-bomb it is documented (mime.ex:100-102) to defend.
      The never-raise contract (MIME-04) still holds, and MIME-01/02/04 do not mandate
      DoS hardening. 45-03 SUMMARY + plan note full provider-fed hardening is a Phase 46
      concern when MIME is wired to a transport. NOTE: the protective claim in the
      moduledoc/test should be corrected even though the threat is deferred.
human_verification:
---

# Phase 45: Inbound Telemetry + Idempotency Foundation Verification Report

**Phase Goal:** Inbound emits 4-level `:telemetry` spans across every stage (ingress, route, execute, persist), the shared MIME parser is in place, and a StreamData property proves 1000-replay convergence — making the rest of v1.2 observable, debuggable, and idempotent by construction.
**Verified:** 2026-05-22T23:16:09Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (from ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Ingress request emits start/stop/exception spans at `[:mailglass_inbound, :ingress, :request, *]` with PII-free metadata (provider, tenant_id, status, byte_size — never PII) | ✓ VERIFIED | `ingress_span` wired at plug.ex:48 wrapping `do_call/3`; stop metadata `{provider, tenant_id, status, byte_size}` (plug.ex:75-92) — no PII keys; latency from `:telemetry.span`. telemetry_test.exs asserts `assert_pii_free` on ingress stop meta (6 sites). Span surface telemetry.ex:73-75. |
| 2 | Route/execution/persist span coverage across the pipeline; a deliberately-raising handler does not break business logic | ✓ VERIFIED | All four spans wired: route_span (matcher.ex:11), persist_span (persist.ex:26), execution_span wraps `execute/2` not `dispatch/2` (execution.ex:52), `:duplicate` short-circuit intact (execution.ex:62). TELE-05 raising-handler test (telemetry_test.exs:250-266) attaches `raise "handler boom"` and asserts the pipeline still returns its success result. Handler isolation is structural via `:telemetry.span/3`. |
| 3 | `mix credo` passes `NoPIIInTelemetry` across both packages (check extended to inbound) | ⚠ PARTIAL | NoPIIInTelemetry (the check NAMED in criterion #3 / TELE-06) IS extended: `.credo.exs` `files.included` widened to `mailglass_inbound/lib/` + `/test/` (line 93); tests assert PII-free metadata. The check is package-agnostic and now reads inbound. HOWEVER the separate TelemetryEventConvention check (also widened, .credo.exs:53-54) is inert for span events (WR-02 — see gaps). NoPIIInTelemetry: satisfied. Convention check: inert. |
| 4 | Admin LiveView (Phase 48) can subscribe to inbound updates because TELE-07 surfaces events into the topic registry | ✓ VERIFIED (enabling surface) | `MailglassInbound.PubSub.Topics.inbound_record_inserted/1` → `"mailglass:inbound:<tenant>"` (topics.ex:33-34); plug.ex:277-292 broadcasts `{:inbound_record_inserted, record_id, %{provider:, record_type:}}` on shared `Mailglass.PubSub` post-commit on `:inserted` only, via the typed builder (not a literal), with copied `safe_broadcast/2`. Admin-side consumption is a Phase 48 task (deferred). |
| 5 | StreamData property replays a payload 1000× through the real persist+route+execute path; asserts exactly one InboundRecord + one fresh ExecutionRun | ✓ VERIFIED | inbound_idempotency_convergence_test.exs: `max_runs: 1000` (line 91), drives real `Persist.persist/2` + `Execution.execute/2` sync not dispatch (lines 100-101), asserts `aggregate(InboundRecord) == |unique|` (line 113) and `aggregate(ExecutionRun where source == :fresh) == |unique|` (lines 124-130), TRUNCATE CASCADE + `start_owner!(shared: true)` against real `MailglassInbound.TestRepo` Postgres. |
| 6 | `MailglassInbound.MIME` parses RFC 5322 into a stable repr; malformed never raises (structured MIME error); backend gating goes through `Mailglass.OptionalDeps.GenSmtp` with documented degraded fallback | ⚠ PARTIAL | RUNTIME: VERIFIED — mime.ex returns `{:ok, %{headers, parts, attachments, inline}}`; never-raise via gateway `decode/2` (try/rescue + catch :throw + catch :exit, gen_smtp.ex:70-78); degraded `:gen_smtp_unavailable` fallback documented + tested; routes through gateway (no bare `:mimemail` anywhere — grep confirms). ENFORCEMENT: the lint guard protecting this gating (NoBareOptionalDepReference) is INERT for gen_smtp (CR-01 — see gaps). Boundary-bomb guard is non-protective (WR-01, deferred). |

**Score:** 5/7 truths verified (truths #3 and #6 PARTIAL — runtime claims hold, enforcement/lint guarantees broken)

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | Admin-side inbound subscription wiring (`MailglassAdmin.PubSub.Topics` consumer) | Phase 48 | IADM-05 maps the InboundLive subscription to the Phase 48 admin LiveView; Phase 45 delivers the broadcast surface only. |
| 2 | Boundary-bomb / deep-nesting DoS mitigation (WR-01) | Phase 46 | Guard re-walks an already-decoded tree; full hardening is a Phase 46 transport-wiring concern. Never-raise (MIME-04) holds. Moduledoc claim should still be corrected. |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `mailglass_inbound/lib/.../telemetry.ex` | 4 named span helpers, spans only | ✓ VERIFIED | `ingress_span/2`, `route_span/2`, `persist_span/2`, `execution_span/2`; private `span/3` via `:telemetry.span/3`; zero `:telemetry.execute`; full whitelist + handler-isolation moduledoc. |
| `mailglass_inbound/lib/.../pub_sub/topics.ex` | typed per-tenant builder | ✓ VERIFIED | `inbound_record_inserted/1` → `"mailglass:inbound:" <> tenant_id`, is_binary guard, @since. |
| `mailglass_inbound/lib/.../mime.ex` | never-raising RFC 5322 parser | ✓ VERIFIED | `parse/1,2` via `OptionalGenSmtp` gateway alias; classifies attachments/inline; recurses multipart + message/rfc822; depth guard (bounds repr only — WR-01). |
| `mailglass_inbound/lib/.../mime_error.ex` | defexception, closed :type set | ✓ VERIFIED | `[:type, :message, :cause, :context]`; `@types [:inbound_mime_invalid, :gen_smtp_unavailable]`; `@derive Jason.Encoder only:` excludes `:cause`; package-local (no `@behaviour Mailglass.Error`). |
| `lib/mailglass/optional_deps/gen_smtp.ex` | never-raising decode/2 seam | ✓ VERIFIED | `decode/2` with `{:allow_missing_version, true}` + mandatory `{:encoding, :none}`; `:mimemail` in `@compile` no-warn list; rescue + catch :throw + catch :exit. |
| `mailglass_inbound/test/.../properties/inbound_idempotency_convergence_test.exs` | max_runs: 1000 | ✓ VERIFIED | Confirmed `max_runs: 1000`, real DB, source==:fresh filter. |
| `mailglass_inbound/test/support/test_repo.ex` + config/test.exs + test_helper.exs | Postgres test infra | ✓ VERIFIED | TestRepo (Postgres adapter), `config :mailglass_inbound, :repo, MailglassInbound.TestRepo`, migration runner (all 4 migrations, pool override, sandbox :manual). |
| `.credo.exs` | path scope widened to inbound | ⚠ VERIFIED-WITH-DEFECT | `files.included` widened (line 93) — NoPIIInTelemetry now reads inbound. But gated_modules keys gen_smtp on phantom `GenSmtp` (CR-01) and the convention check is span-blind (WR-02). |
| `.github/workflows/ci.yml` | inbound Postgres job + property gate | ⚠ VERIFIED-WITH-GAP | `inbound_test` job (postgres:16-alpine, `mix test --exclude property` then `--only property`). Missing: an inbound `--no-optional-deps` compile lane (WR-03). |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| plug.ex | `Telemetry.ingress_span/2` | wraps `do_call/3` | ✓ WIRED | plug.ex:48 |
| matcher.ex | `Telemetry.route_span/2` | wraps `match/2` | ✓ WIRED | matcher.ex:11 |
| persist.ex | `Telemetry.persist_span/2` | wraps `repo.transact` | ✓ WIRED | persist.ex:26 |
| execution.ex | `Telemetry.execution_span/2` | wraps `execute/2` body (not dispatch/2) | ✓ WIRED | execution.ex:52; duplicate short-circuit at :62 untouched |
| plug.ex | `Topics.inbound_record_inserted/1` | post-commit `safe_broadcast` on `Mailglass.PubSub`, :inserted only | ✓ WIRED | plug.ex:277-292 |
| mime.ex | `OptionalGenSmtp.decode/2` | gateway parse seam (alias, never bare `:mimemail`) | ✓ WIRED | mime.ex:61, 128 |
| gen_smtp.ex | `:mimemail.decode/2` | try/rescue + catch :throw + catch :exit | ✓ WIRED | gen_smtp.ex:72 |
| convergence test | `Execution.execute/2` (sync) | drives real write path, not dispatch/2 | ✓ WIRED | test line 101 |
| `.credo.exs` gen_smtp gate | bare `:mimemail` call sites | NoBareOptionalDepReference | ✗ NOT_WIRED | keyed on phantom `GenSmtp` alias; `:mimemail` atom never matched (CR-01) |
| `.credo.exs` convention gate | inbound `:telemetry.span/3` events | TelemetryEventConvention | ✗ NOT_WIRED | check only inspects `:telemetry.execute` (WR-02) |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| convergence test | InboundRecord / ExecutionRun counts | real `Persist.persist` + `Execution.execute` against `MailglassInbound.TestRepo` Postgres (unique index `..._postmark_idempotency_idx`) | ✓ Yes | ✓ FLOWING |
| ingress broadcast | record_id + provider payload | real committed `InboundRecord` (post-commit, outside transact) | ✓ Yes | ✓ FLOWING |
| MIME repr | headers/parts/attachments/inline | real `:mimemail.decode/2` output via gateway (not placeholder) | ✓ Yes | ✓ FLOWING |

### Behavioral Spot-Checks

Static-verification only. Per the task's toolchain caveat, no `mix` commands were run: the inbound package's deps are NOT fetched in the main working tree (`mailglass_inbound/deps` and `_build` absent), and `mix deps.get` re-resolves core deps under the local Elixir 1.19/OTP 28 toolchain (CI pins 1.18/OTP 27), so a local run is not a reliable signal. All checks below are source/grep based.

| Behavior | Check | Result | Status |
|----------|-------|--------|--------|
| No bare `:mimemail` outside gateway | `grep -rn ":mimemail" lib/ mailglass_inbound/lib/ \| grep -v gen_smtp.ex` | NONE | ✓ PASS |
| No bare `:gen_smtp_client` outside gateway | same grep for `:gen_smtp_client` | NONE | ✓ PASS |
| `GenSmtp` is not a real Elixir module | `grep -rn "defmodule GenSmtp" lib/ mailglass_inbound/lib/ deps/` | NONE (confirms CR-01 root cause) | ✓ PASS (defect-confirming) |
| Convergence property `max_runs: 1000` | grep test file | line 91 | ✓ PASS |
| ExecutionRun count filters `source == :fresh` | grep test file | line 126 | ✓ PASS |
| gen_smtp + stream_data pinned in inbound lock | grep mix.lock | gen_smtp 1.3.0, stream_data 1.3.0 (checksums match core) | ✓ PASS |
| `:telemetry.execute` count in telemetry.ex (spans only) | grep | 0 | ✓ PASS |

### Probe Execution

No project probes apply to this phase (no `scripts/*/tests/probe-*.sh`; phase verification is test/lint-based, not probe-based). N/A.

### Requirements Coverage

All 11 declared IDs map cleanly across the four plans; REQUIREMENTS.md line 230 expects exactly `TELE-01..08, MIME-01, MIME-02, MIME-04` for Phase 45 (MIME-03 → Phase 49). No orphaned requirements.

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| TELE-01 | 45-02 | ingress span, PII-free | ✓ SATISFIED | plug.ex:48; telemetry_test PII-free asserts |
| TELE-02 | 45-02 | route span, matched/no_match/candidate_count | ✓ SATISFIED | matcher.ex:11 |
| TELE-03 | 45-02 | execution span (wraps execute/2, both async paths) | ✓ SATISFIED | execution.ex:52 |
| TELE-04 | 45-02 | persist span, operation insert/dedup_skip | ✓ SATISFIED | persist.ex:26 (no `:update` — table is append-only, correct) |
| TELE-05 | 45-02 | raising handler does not break business logic | ✓ SATISFIED | telemetry_test.exs:250-266 |
| TELE-06 | 45-01 | NoPIIInTelemetry extended to inbound | ✓ SATISFIED | `.credo.exs:93` files.included widened; NoPIIInTelemetry is package-agnostic. (Adjacent convention check is inert — WR-02, separate concern.) |
| TELE-07 | 45-02 | events surfaced for admin live updates | ✓ SATISFIED (surface) | topics.ex + plug.ex broadcast on Mailglass.PubSub; admin consumption is Phase 48 (IADM-05) |
| TELE-08 | 45-04 | 1000-replay convergence property | ✓ SATISFIED | convergence test, max_runs: 1000, real Postgres |
| MIME-01 | 45-03 | RFC 5322 → stable repr | ✓ SATISFIED | mime.ex parse/1,2 + repr |
| MIME-02 | 45-03 | gated through GenSmtp; degraded fallback documented | ✓ SATISFIED (runtime) | runtime gating correct; degraded fallback documented + tested. NOTE: the lint GUARD enforcing this (NoBareOptionalDepReference) is inert — CR-01 |
| MIME-04 | 45-03 | malformed never raises; structured error | ✓ SATISFIED | gateway absorbs all 3 escape mechanisms; gen_smtp_test + mime_test |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `.credo.exs` | 33 | gated_modules keys gen_smtp on phantom `GenSmtp` alias; guard never fires for `:mimemail` | 🛑 Blocker | Documented non-negotiable enforcement control (CLAUDE.md; .credo.exs:36-39; gateway moduledoc) is silently inert; SUMMARY claim is false |
| `credo_checks/telemetry_event_convention.ex` | 31 | check inspects only `:telemetry.execute`, never `:telemetry.span/3` | ⚠ Warning | Widened `required_root` is inert for all inbound span events; docstring claim untrue |
| `.github/workflows/ci.yml` | 166-237 | no `mix compile --no-optional-deps` lane for inbound | ⚠ Warning | CLAUDE.md mandates it; plans' acceptance criteria assert it green; deferred-items.md shows it actually FAILS (exits 1) in the worktree, unverified in CI |
| `mailglass_inbound/lib/.../ingress/plug.ex` | 84 | `inspect(reason)` on 500 response can render Ecto changeset `changes` (subject/from/to/body) | ⚠ Warning | PII leak to the provider on a DB error path; contradicts the strict no-PII posture (telemetry metadata itself is clean) |
| `mailglass_inbound/lib/.../mime.ex` | 100-102 | depth guard documented as boundary-bomb protection but re-walks already-decoded tree | ℹ Info | Control not protective as documented; deferred to Phase 46, but moduledoc/test claim should be corrected |
| `lib/mailglass/optional_deps/gen_smtp.ex` | 30-33 | moduledoc attributes `:undef` to `catch :exit` (it is an error caught by `rescue`) | ℹ Info | Documentation accuracy only; never-raise contract holds |

No `TBD`/`FIXME`/`XXX` debt markers found in the phase-modified files.

### Human Verification Required

None. All deliverables are verifiable statically. CI execution of the inbound test/property jobs (which require a live Postgres) is the normal CI gate and is not a manual-UAT item; the gaps above are code-level defects observable in source.

### Gaps Summary

The headline functional deliverables of Phase 45 are genuinely present and substantive: the four inbound spans are wired at their fixed sites with PII-free metadata, the raising-handler isolation is tested, the never-raising MIME parser routes through the gateway and is exercised against the real `:mimemail` decoder, the per-tenant broadcast fires post-commit on the shared PubSub, and the 1000-run convergence property drives a real Postgres write path with the correct `source == :fresh` filter. All 11 requirement IDs are accounted for with implementation evidence, and no orphaned requirements exist.

Two phase-level guarantees, however, do not hold and contradict explicit claims in the SUMMARYs, code comments, and project conventions:

1. **CR-01 (BLOCKER):** The `NoBareOptionalDepReference` guard is inert for gen_smtp. It keys on the phantom Elixir alias `GenSmtp` while gen_smtp is reached only through the Erlang atoms `:mimemail` / `:gen_smtp_client`, so `Map.fetch(gated_modules, :mimemail)` always misses and no issue is ever raised. A bare `:mimemail.decode(...)` anywhere in inbound would pass `mix credo --strict`. This is a CLAUDE.md non-negotiable enforcement convention and is asserted-as-working in `.credo.exs:36-39`, the gateway moduledoc, and the 45-01 SUMMARY ("will catch any bare :mimemail reference") — the latter "verified by probe" only probed `Oban` (a real module the check catches), never the `:mimemail` atom path. Current runtime behavior is correct (no bare reference exists today), so MIME-02's runtime gating still holds — but the protective control guarding it going forward does not function and has no regression test.

2. **WR-02 (WARNING):** `TelemetryEventConvention` inspects only `:telemetry.execute`, never `:telemetry.span/3`. Since every inbound event is a span, the `required_root: [:mailglass, :mailglass_inbound]` widening is inert. The NoPIIInTelemetry check named in TELE-06 IS correctly extended, so TELE-06 itself is satisfied — but the broader "now lints inbound" convention enforcement is partially inert.

3. **WR-03 (WARNING):** There is no `mix compile --no-optional-deps --warnings-as-errors` lane for `mailglass_inbound`, despite CLAUDE.md mandating it and the plans' acceptance criteria asserting it green. deferred-items.md records that this compile actually FAILS (exits 1) in the worktree (`Mailglass.Oban.TenancyMiddleware.wrap_perform/2 is undefined`). Whether this is a genuine inbound degraded-path break or a local-toolchain artifact is unverified precisely because no CI lane exercises it.

These are root-caused in one concern (lint/CI enforcement mechanisms claimed to cover inbound but partially or wholly inert), distinct from the functional telemetry/MIME/convergence work which is sound. Recommend `/gsd:plan-phase --gaps` to fix CR-01 (with the Erlang-atom regression test) and decide on WR-02 / WR-03.

---

_Verified: 2026-05-22T23:16:09Z_
_Verifier: Claude (gsd-verifier)_
