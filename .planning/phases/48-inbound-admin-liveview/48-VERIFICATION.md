---
phase: 48-inbound-admin-liveview
verified: 2026-05-24T20:24:00Z
status: passed
score: 5/5 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 3/5
  gaps_closed:
    - "SC#1 — list reflects each record's real disposition (latest-fresh ExecutionRun outcome + mailbox projected; WR-01)"
    - "SC#1 — search filter narrows results (ILIKE over subject/envelope_recipient/provider_message_id, threaded end-to-end; WR-03)"
    - "SC#2 — detail 'From' cell shows the masked SENDER from @record.from, not the recipient (WR-02)"
  gaps_remaining: []
  regressions: []
gaps: []
deferred: []
---

# Phase 48: Inbound Admin LiveView Verification Report

**Phase Goal:** An operator opens `/admin/inbound` in `mailglass_admin` and gets the same observability they already have for outbound: a tenant-scoped master/detail of inbound records with provider/mailbox/outcome filters, an evidence card showing canonical message + raw provider source, a timeline of execution runs (fresh + replay), a routing-trace card answering "why didn't this match?", a confirmation-gated replay modal, and live updates via PubSub.

**Verified:** 2026-05-24T20:24:00Z
**Status:** passed
**Re-verification:** Yes — after gap closure (WR-01, WR-02, WR-03)

## Re-Verification Summary

The prior verification (2026-05-24T20:10:00Z) scored this phase 3/5 (`gaps_found`) with two partial truths blocking SC#1 and SC#2. The three underlying defects (WR-01 list disposition projection, WR-03 dead search filter, WR-02 wrong "From" field) were closed in commits `f4f86dd`, `75540c3`, `f7f15f4` (all present on `main`, all `fix(48):`). Each fix was verified against the ACTUAL code — not the SUMMARY — and confirmed behaviorally by the test suites. No regressions in the previously-passing truths (SC#3/4/5 and IADM-06/07). **All 5 success criteria now hold; phase goal achieved.**

## Goal Achievement

### Observable Truths

| #   | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| 1 | Operator sees a paginated list filterable by provider, **mailbox/outcome**, time window, and **search**; the list reflects each record's REAL disposition (outcome badge + matched mailbox); empty/missing tenant returns [] (no cross-tenant leak). | ✓ VERIFIED | **WR-01 FIXED:** `Records.list_records/2` now projects `outcome` + `mailbox` of each record's latest-FRESH `ExecutionRun` via correlated subqueries `latest_fresh_run_field/2` (records.ex:66-67, 82-92) — `where: source == :fresh and inbound_record_id == parent_as(:rec).id`, `order_by: [desc: inserted_at]`, each subquery itself tenant-scoped (`run.tenant_id == ^tenant_id`). The subquery's `Ecto.Enum` raw-string return is restored to the atom via `cast_projected_outcome/1` against the closed `ExecutionRun.__outcomes__/0` allow-list (records.ex:100-111), so `records_list.ex` `record_outcome/1` (line 88) and `matched_mailbox_label/1` (line 90) now read REAL values: matched → its mailbox + outcome badge; `:no_match`/run-less → nil mailbox → "no match"/"Pending". Ordering + `source: :fresh` shape exactly mirrors `Detail.latest_fresh_run/2` (detail.ex:132-144) — single source of truth; `@sources [:fresh, :replay]` confirms replay runs are excluded. **WR-03 FIXED:** `search` threaded `load_inbound_records/1` (inbound_live.ex:466, `search: blank_to_nil(...)`) → gateway → `maybe_filter_search/2` (records.ex:146-164) case-insensitive `ilike` over subject/envelope_recipient/provider_message_id, LIKE metachars escaped (`escape_like/1`, lines 168-173), blank = no-op. Tenant gate intact (records.ex:45 explicit `tenant_id` where + `Tenancy.scope/2` line 69; blank tenant → []). Read-model suite green (27/0); admin LiveView+component suites green (48/0) including new assertions: distinct rows show distinct dispositions, search narrows + is tenant-scoped + blank no-op. |
| 2 | Selecting a record shows the canonical %InboundMessage{} including the SENDER (masked), raw provider source (redacted, :reveal_raw gated), matched mailbox + execution outcome, full ExecutionRun timeline (fresh + replay). | ✓ VERIFIED | **WR-02 FIXED:** detail_header.ex "From" cell (line 65) now renders `sender_display(@record)` (lines 112-127) which reads `@record.from` (`InboundRecord.from`, `{:array, :map}`, schema line 46 — previously never read), extracts each address (atom-key `:address`, string-key `"address"`, or bare binary), masks each via the one audited `Components.mask_recipient/1` (components.ex:130), and degrades to "Unavailable" on empty/malformed `from`. It is now the SENDER, masked, distinct from the H2 recipient title. Component test asserts masked sender for both atom- and string-keyed `from`, no raw leak, "Unavailable" fallback. The rest of SC#2 remains solid (re-confirmed): matched mailbox + outcome from tenant-scoped `Detail` read-model; full `ExecutionRun` timeline (fresh + replay) via `Timeline.list_runs`; default-redacted `EvidenceCard` with working `:reveal_raw` gate. |
| 3 | Replay → confirmation modal, tenant-bound + :replay_inbound capability; on confirm a new ExecutionRun source: :replay appears (append-only, no UPDATE). | ✓ VERIFIED (re-confirmed) | `confirm_replay` gate order correct: `verify_tenant/2` (inbound_live.ex:14 of the handler) BEFORE the un-scoped gateway replay, then `:replay_inbound` via `DestructiveAction.authorize` (lines 16-20), then `replay_record` (line 21). Structured-error tuple → composed copy. `:no_match` button disabled (detail_header.ex:130). Append-only `ExecutionRun source: :replay` preserved (reads only in this phase). |
| 4 | For a :no_match row, routing-trace card renders a matcher diff against `__mailglass_inbound_routes__/0` showing every route tried + which clause failed. | ✓ VERIFIED (re-confirmed) | `RoutingTrace` renders verdicts computed by `Router.Matcher.explain/2` (routing_trace.ex:9) via the gateway `explain_routes/2`, reusing the in-module matcher predicates (single source of truth). |
| 5 | New inbound records appear without manual refresh (per-tenant subscribe to inbound_record_inserted/1); error messages composed + specific (no "Oops!"). | ✓ VERIFIED (re-confirmed) | `Phoenix.PubSub.subscribe` on connected mount via `Topics.inbound_record_inserted(tenant_id)` (inbound_live.ex:61-63); `handle_info({:inbound_record_inserted, record_id, _meta}, ...)` (line 215) re-fetches tenant-scoped + prepends. Brand-voice: no banned words in any phase-48 rendered surface (the single suite "oops" failure is a pre-existing inlined Phoenix dep JS artifact, NOT phase-48 copy — see Anti-Patterns). |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `mailglass_inbound/.../internal/operator/records.ex` | Tenant-required-or-empty list read-model carrying real disposition + search | ✓ VERIFIED | Projection now carries `outcome`+`mailbox` via tenant-scoped correlated subqueries (lines 66-92) with enum re-cast (100-111); `maybe_filter_search/2` ILIKE + escape (146-173). Tenant where + `Tenancy.scope/2` on every query; blank tenant → []. |
| `mailglass_inbound/.../internal/operator/timeline.ex` | All-runs chronological lineage | ✓ VERIFIED | ExecutionRun, tenant-scoped, ascending, fresh + replay (re-confirmed). |
| `mailglass_inbound/.../internal/operator/detail.ex` | Record + evidence + matched outcome, tenant-gated | ✓ VERIFIED | `latest_fresh_run/2` (132-144) is the shape the list projection reuses; tenant-gated; blank/foreign → nil (re-confirmed). |
| `mailglass_inbound/.../router/matcher.ex` (explain/2) | Reflection reusing predicates | ✓ VERIFIED | Reuses in-module predicates; V3 property green (re-confirmed). |
| `mailglass_admin/.../optional_deps/mailglass_inbound.ex` | Runtime gateway (available?/0 + apply/3) | ✓ VERIFIED | `--no-optional-deps --warnings-as-errors` exit 0 (39 files); new `search`/projected fields flow through `apply/3`, no new direct `MailglassInbound.*` in admin lib. |
| `mailglass_admin/.../inbound_live.ex` | Master/detail shell; search threaded | ✓ VERIFIED | `load_inbound_records/1` now threads `search` (line 466); was the dead-plumbing source, now wired. Tenant gate, URL-as-state, gateway-only data calls all intact. |
| `mailglass_admin/.../inbound/records_list.ex` | List component showing real disposition | ✓ VERIFIED | `record_outcome/1`/`matched_mailbox_label/1` defensive `Map.get` reads now resolve to real projected values; no consumer change needed. |
| `mailglass_admin/.../inbound/detail_header.ex` | Detail header; "From" shows masked sender | ✓ VERIFIED | `sender_display/1` reads `@record.from`, masks via `mask_recipient/1`, "Unavailable" fallback (112-127). Suppression read still defensive (line 103). |
| `mailglass_admin/.../inbound/routing_trace.ex` | Per-route clause diff | ✓ VERIFIED | From `explain/2` verdicts (re-confirmed). |
| `mailglass_admin/.../inbound/evidence_card.ex` | Default-redacted raw source | ✓ VERIFIED | Default redacted, `:reveal_raw` gate (re-confirmed). |
| `mailglass_admin/.../inbound/replay_modal.ex` | Single-target confirm modal | ✓ VERIFIED | Re-confirmed. |
| `mailglass_admin/.../inbound/destructive_action.ex` | :replay_inbound guard | ✓ VERIFIED | Passes `:inbound_record`; rides `Auth.authorize/3`. (WR-04 nil-adapter Info note carried below — non-blocking, shielded in prod.) |
| `mailglass_admin/.../router.ex` | /inbound route in operator live_session, available?/0-gated | ✓ VERIFIED | `live "/inbound"` inside operator live_session (router.ex:270), gated by `Code.ensure_loaded?` + `available?()` (268-269); `:inbound_router` opt threaded. |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| inbound_live.ex | OptionalDeps.MailglassInbound | apply/3 gateway | ✓ WIRED | All data calls (incl. new `search`) cross the gateway; no bare `MailglassInbound.*`. |
| inbound_live.ex | Internal.Replay.replay/2 | gateway after tenant verify | ✓ WIRED | `verify_tenant/2` precedes the un-scoped replay (D-48-05). |
| inbound_live.ex | inbound_record_inserted/1 | subscribe on mount + handle_info | ✓ WIRED | Topic builder; tenant-scoped re-fetch + prepend. |
| routing_trace.ex | Router.Matcher.explain/2 | gateway explain_routes per route | ✓ WIRED | Verdicts equal real matcher behavior. |
| router.ex | MailglassAdmin.InboundLive | live "/inbound" in operator live_session | ✓ WIRED | Auth-gated, available?/0-gated. |
| **filters_form (search) → records.ex query** | **maybe_filter_search/2** | **search filter application** | ✓ **WIRED (was NOT_WIRED)** | search threaded inbound_live.ex:466 → gateway → ILIKE clause records.ex:146-164. Test asserts narrowing + tenant scoping + blank no-op. |
| **records_list (outcome/mailbox) → records.ex projection** | **latest_fresh_run_field/2** | **per-record disposition** | ✓ **WIRED (was NOT_WIRED)** | List badge/mailbox read fields the projection now supplies (records.ex:66-67); enum re-cast to atom (100-111). Test asserts distinct real dispositions per row. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| records_list.ex | `record.outcome` / `record.mailbox` | `Records.list_records/2` correlated subquery on latest-fresh `ExecutionRun` | Yes — real per-record disposition (matched → outcome+mailbox; no_match/run-less → nil → "no match"/"Pending") | ✓ FLOWING |
| records_list.ex (search-filtered list) | `@records` | `load_inbound_records/1` → gateway → `maybe_filter_search/2` ILIKE | Yes — search narrows the DB query | ✓ FLOWING |
| detail_header.ex | `sender_display(@record)` | `@record.from` ({:array,:map}) on the full `%InboundRecord{}` from `Detail.fetch/2` | Yes — masked real sender; "Unavailable" only when `from` is genuinely empty | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Inbound operator read-model (disposition projection + search clause + tenant scoping) | `mix test test/mailglass_inbound/internal/operator/ --seed 0` | 27 tests, 0 failures | ✓ PASS |
| Admin inbound LiveView + components (list disposition, search narrowing, masked-sender From cell) | `mix test inbound_live_test.exs inbound/components_test.exs --seed 0` | 48 tests, 0 failures | ✓ PASS |
| Full admin suite | `mix test --seed 0` | 131 tests, 1 failure (ONLY pre-existing voice_test "oops" in inlined Phoenix dep JS — NOT phase 48) | ✓ PASS (phase-48 green) |
| Optional-dep boundary (D-48-02) | `mix compile --no-optional-deps --warnings-as-errors` | exit 0 (39 files) | ✓ PASS |

### Probe Execution

No conventional `scripts/*/tests/probe-*.sh` declared for this phase; verification ran the phase's test commands directly (above). N/A.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| IADM-01 | 48-01, 48-02 | Master/detail list with URL-param filters (provider, mailbox/outcome, time window, search), tenant-required gate | ✓ SATISFIED | Tenant gate + provider/outcome/window + **real disposition projection (WR-01 fixed)** + **working search (WR-03 fixed)** all verified. |
| IADM-02 | 48-02, 48-03 | Detail shows canonical %InboundMessage{}, raw provider source (PII handling), matched mailbox + result, timeline of runs | ✓ SATISFIED | Raw source, matched mailbox/outcome, full timeline + **masked SENDER in "From" cell (WR-02 fixed)** verified. |
| IADM-03 | 48-03 | Replay modal, destructive-action confirmation, tenant-bound, single target | ✓ SATISFIED | Tenant-gated + capability-gated + append-only replay. |
| IADM-04 | 48-01, 48-03 | Routing-trace card — matcher diff against `__mailglass_inbound_routes__/0` | ✓ SATISFIED | Per-route clause diff from `explain/2`; equivalence proven. |
| IADM-05 | 48-01, 48-03 | InboundLive subscribes to PubSub for live updates | ✓ SATISFIED | Per-tenant subscribe via builder; tenant-scoped prepend. |
| IADM-06 | 48-03 | Brand voice: composed, specific errors; no "Oops!" | ✓ SATISFIED | No banned words in phase-48 rendered surfaces; suite failure is pre-existing dep JS, not phase 48. |
| IADM-07 | 48-02 | Inbound surface reachable from admin, gated by existing Auth plug | ✓ SATISFIED | `/inbound` in operator live_session (Auth gate), available?/0-gated; no new auth surface. |

All 7 phase requirement IDs (IADM-01..07) satisfied. None orphaned. REQUIREMENTS.md maps exactly IADM-01..07 to Phase 48.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| destructive_action.ex | ~22 | `when is_atom(adapter)` matches `nil` (nil is an atom) — latent crash if adapter ever nil | ℹ️ Info | WR-04, carried from prior. Shielded in production (operator Mount always sets adapter). Out of scope for this gap closure; left for future hardening. |
| inbound_live.ex / auth.ex | error-tuple normalize | Non-standard adopter error tuple could raise before catch-all | ℹ️ Info | WR-05, carried from prior. Default test/grant adapters use `:unauthorized`; never trips today. Out of scope. |

No debt markers (TBD/FIXME/XXX/HACK/PLACEHOLDER) in any of the four modified files. No secrets, no PII in telemetry, no UPDATE/DELETE on append-only tables. Tenant isolation, replay gate order, and optional-dep gateway discipline all sound. The single full-suite test failure (`voice_test.exs` "oops") is a pre-existing artifact in inlined Phoenix dependency JS, explicitly out of scope for phase 48 and NOT counted against it.

### Human Verification Required

None. All five success criteria are observable in code and confirmed by passing test suites (read-model 27/0; admin inbound LiveView + components 48/0, including the new gap-closure assertions for list disposition, search narrowing, and the masked-sender From cell) plus a clean optional-dep compile lane. The two carried Info-level notes (WR-04/WR-05) are latent paths shielded in production, not gating.

### Gaps Summary

No gaps. All three previously-failing items are genuinely fixed in the actual code on `main`:

1. **WR-01 (SC#1/IADM-01) — list disposition:** `Records.list_records/2` projects each record's latest-FRESH `ExecutionRun` `outcome` + `mailbox` via tenant-scoped correlated subqueries (`parent_as(:rec)`), with `cast_projected_outcome/1` restoring the `Ecto.Enum` atom from the raw DB string. The list now shows real per-record disposition; the projection subqueries are themselves tenant-scoped (no cross-tenant leak). Verified against records.ex:44-111 and confirmed by read-model + LiveView tests.

2. **WR-03 (SC#1/IADM-01) — search:** threaded `load_inbound_records/1` (inbound_live.ex:466) → gateway → `maybe_filter_search/2` case-insensitive ILIKE over subject/envelope_recipient/provider_message_id, with LIKE wildcards escaped and blank = no-op. Verified against records.ex:146-173 and confirmed by tests asserting narrowing, tenant scoping, and blank no-op.

3. **WR-02 (SC#2/IADM-02) — From cell:** detail_header.ex:65 now renders `sender_display(@record)` from `@record.from` ({:array,:map}), masked via the audited `Components.mask_recipient/1`, degrading to "Unavailable" on empty. It shows the masked SENDER, not the recipient. Verified against detail_header.ex:112-127 and confirmed by component tests.

The security-critical and novel spine (tenant isolation, append-only tenant+capability-gated replay, matcher-reflection routing trace, default-redacted evidence card, per-tenant live PubSub, optional-dep gateway) remains intact with no regressions. **All 5 success criteria met; the phase goal — outbound-parity inbound observability — is achieved.**

---

_Verified: 2026-05-24T20:24:00Z (re-verification after gap closure)_
_Verifier: Claude (gsd-verifier)_
