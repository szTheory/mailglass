---
phase: 48-inbound-admin-liveview
verified: 2026-05-24T20:10:00Z
status: gaps_found
score: 3/5 must-haves verified
overrides_applied: 0
gaps:
  - truth: "SC#1 — Operator sees a list of inbound records filterable by provider, mailbox, outcome, time window, AND search; the list reflects each record's real disposition (outcome badge + matched mailbox)."
    status: partial
    reason: >
      Two of the named filters/displays do not work. (a) The list projection never carries
      outcome or mailbox, so every row renders a constant "Pending" badge and "no match"
      mailbox regardless of actual disposition (WR-01). (b) The "search" filter is collected
      by the form and round-tripped through the URL but never applied by any query — dead UI
      (WR-03). Provider, outcome, and time-window filters DO work; tenant isolation is correct.
    artifacts:
      - path: "mailglass_inbound/lib/mailglass_inbound/internal/operator/records.ex"
        issue: "list_records/2 select/3 (lines 47-57) projects only id/tenant_id/provider/provider_message_id/message_id/envelope_recipient/subject/received_at/inserted_at — no outcome, no mailbox, no search clause."
      - path: "mailglass_admin/lib/mailglass_admin/inbound/records_list.ex"
        issue: "record_outcome/1 (line 88) = Map.get(record, :outcome) -> always nil -> 'Pending'; matched_mailbox_label/1 (line 91) = Map.get(record, :mailbox) -> always nil -> 'no match'."
      - path: "mailglass_admin/lib/mailglass_admin/inbound_live.ex"
        issue: "default_filter_params/0 (line 547) and normalize_filter_params/1 (line 559) carry a 'search' key and FiltersForm renders the input, but load_inbound_records/1 (lines 457-472) never threads search to the gateway."
    missing:
      - "Join/subquery the latest fresh ExecutionRun outcome + mailbox into the Records.list_records projection so the list badge/mailbox reflect real disposition (or remove the badge/mailbox label until the projection carries them)."
      - "Implement the search filter (ILIKE on subject/envelope_recipient, cast safely) and thread it through load_inbound_records/1, OR remove the search field from default_filter_params/normalize_filter_params/FiltersForm until implemented."
  - truth: "SC#2 — Selecting a record shows the canonical %InboundMessage{} (including the sender) plus matched mailbox + execution outcome and the raw provider source."
    status: partial
    reason: >
      The detail header's 'From' cell renders the masked RECIPIENT (envelope_recipient), not
      the sender (WR-02). InboundRecord has a dedicated `from` field that is never read, so the
      operator is shown a labelled falsehood and the actual sender ('who sent this?') is never
      displayed. The UI-SPEC (line 70) specifies a masked 'From' cell, and the outbound analog
      has no From cell at all — this is a fresh cell wired to the wrong field, not a faithful
      clone. The rest of SC#2 is correctly met: matched mailbox + execution outcome come from the
      tenant-scoped Detail read-model, the full ExecutionRun timeline (fresh + replay) renders,
      and the raw provider source (EvidenceCard) is default-redacted with a working :reveal_raw
      gate.
    artifacts:
      - path: "mailglass_admin/lib/mailglass_admin/inbound/detail_header.ex"
        issue: "Line 65 'From' cell renders Components.mask_recipient(@record.envelope_recipient) — the recipient, not @record.from. Duplicates the H2 title (line 38)."
    missing:
      - "Render the sender from @record.from (masking each address) in the 'From' cell, OR relabel the cell 'Recipient' so the label is not a falsehood."
deferred: []
---

# Phase 48: Inbound Admin LiveView Verification Report

**Phase Goal:** An operator opens `/admin/inbound` in `mailglass_admin` and gets the same observability they already have for outbound: a tenant-scoped master/detail of inbound records with provider/mailbox/outcome filters, an evidence card showing canonical message + raw provider source, a timeline of execution runs (fresh + replay), a routing-trace card answering "why didn't this match?", a confirmation-gated replay modal, and live updates via PubSub.

**Verified:** 2026-05-24T20:10:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| #   | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| 1 | Operator sees a paginated list filterable by provider, **mailbox/outcome**, time window, and **search**; empty/missing tenant returns [] (no cross-tenant leak). | ✗ FAILED | Tenant gate + provider/outcome/window filters work and tenant isolation is proven (SQL shows `tenant_id` where + `Tenancy.scope/2` on every query; records_test green). BUT (a) the list always renders constant "Pending" outcome + "no match" mailbox — `Records.list_records/2` never projects outcome/mailbox (records.ex:47-57; consumed nil via Map.get in records_list.ex:88,91); (b) the **search** filter is dead UI — collected + URL-round-tripped but never applied (inbound_live.ex:457-472 omits it; records.ex has no search clause). |
| 2 | Selecting a record shows canonical %InboundMessage{} + raw source (redacted, :reveal_raw gated) + matched mailbox/outcome + full ExecutionRun timeline (fresh + replay). | ✗ FAILED | Matched mailbox/outcome (Detail read-model, tenant-scoped), the full ExecutionRun timeline (Timeline.list_runs, fresh+replay chronological), and the default-redacted EvidenceCard with a working :reveal_raw gate are all correct. BUT the detail header "From" cell renders the masked **recipient** (detail_header.ex:65 `envelope_recipient`), not the sender — `InboundRecord.from` is never read. The labelled "From" is a falsehood; the actual sender is never shown. |
| 3 | Replay → confirmation modal, tenant-bound + :replay_inbound capability; on confirm a new ExecutionRun source: :replay appears (append-only, no UPDATE). | ✓ VERIFIED | confirm_replay gate order is correct: tenant gate (verify_tenant/2, inbound_live.ex:392) BEFORE the un-scoped gateway replay/2, then :replay_inbound via DestructiveAction.authorize (context :inbound_record), then tuple-matched structured-error → copy. V2/V6/cross-tenant tests green. Append-only ExecutionRun source: :replay confirmed. |
| 4 | For a :no_match row, routing-trace card renders a matcher diff against `__mailglass_inbound_routes__/0` showing every route tried + which clause failed. | ✓ VERIFIED | RoutingTrace renders one sub-card per declared route via the gateway `explain_routes/2`; verdicts come from `Router.Matcher.explain/2` which REUSES the in-module `matches_matcher?/2` predicates (single source of truth, no re-implementation — matcher.ex:58-76). V3 equivalence property green (Enum.all?(explain) == matches_route?). Card renders only on :no_match; recipient actual masked; nil→any / regex→~r// / exact verbatim; first-failing clause emphasized + composed reason. |
| 5 | New inbound records appear without manual refresh (per-tenant subscribe to inbound_record_inserted/1); error messages composed + specific (no "Oops!"). | ✓ VERIFIED | InboundLive subscribes on connected mount via the topic builder (inbound_live.ex:60-65), handle_info re-fetches tenant-scoped + prepends without stealing selection/filters. Topic parity exact + tested (V8). Brand-voice sweep green: composed copy throughout; no banned words in any phase-48 rendered state. |

**Score:** 3/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `mailglass_inbound/.../internal/operator/records.ex` | Tenant-required-or-empty list read-model | ⚠️ HOLLOW | Exists, substantive, wired, tenant-safe — but projection omits outcome/mailbox + has no search clause, so the consuming list card cannot show real disposition (WR-01/WR-03). |
| `mailglass_inbound/.../internal/operator/timeline.ex` | All-runs chronological lineage | ✓ VERIFIED | Reads ExecutionRun (not ReplayRun), tenant where + Tenancy.scope, ascending executed_at, fresh + replay. |
| `mailglass_inbound/.../internal/operator/detail.ex` | Record + evidence + matched outcome, tenant-gated | ✓ VERIFIED | Loads record/evidence/latest-fresh-run all tenant-scoped; returns nil for blank/foreign tenant. |
| `mailglass_inbound/.../router/matcher.ex` (explain/2) | Reflection reusing predicates | ✓ VERIFIED | Reuses matches_matcher?/2 in-module; V3 property green. |
| `mailglass_admin/.../optional_deps/mailglass_inbound.ex` | Runtime gateway (available?/0 + apply/3) | ✓ VERIFIED | Conditionally compiled, @compile no_warn_undefined, available?/0; explain_routes/2 keeps consumer free of compile-time inbound refs. |
| `mailglass_admin/.../inbound_live.ex` | Master/detail shell | ⚠️ ORPHANED-FIELD | Exists (615 lines), wired through gateway only, tenant-gated, URL-as-state — but carries dead `search` filter plumbing (collected, never applied). |
| `mailglass_admin/.../inbound/records_list.ex` | List component | ⚠️ HOLLOW | Renders constant outcome badge + mailbox label because upstream projection lacks the fields. |
| `mailglass_admin/.../inbound/detail_header.ex` | Detail header, defensive suppression read | ⚠️ WRONG-DATA | suppression_flagged read is defensive (Map.get, correct); but "From" cell shows recipient, not sender (WR-02). |
| `mailglass_admin/.../inbound/routing_trace.ex` | Per-route clause diff | ✓ VERIFIED | Net-new, from explain/2 verdicts, no matcher re-implementation. |
| `mailglass_admin/.../inbound/evidence_card.ex` | Default-redacted raw source | ✓ VERIFIED | Default redacted, :reveal_raw gate, raw bytes absent until granted. |
| `mailglass_admin/.../inbound/replay_modal.ex` | Single-target confirm modal | ✓ VERIFIED | Simplified, no multi-target branch. |
| `mailglass_admin/.../inbound/destructive_action.ex` | :replay_inbound guard | ✓ VERIFIED (latent crash on nil adapter — see WR-04 below) | Passes :inbound_record; rides Auth.authorize/3. |
| `mailglass_admin/.../router.ex` | /inbound route in operator live_session, available?/0-gated | ✓ VERIFIED | live "/inbound" inside operator live_session; gated by Code.ensure_loaded? + available?/0; :inbound_router opt threaded. |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| inbound_live.ex | OptionalDeps.MailglassInbound | apply/3 gateway | ✓ WIRED | All data calls cross the gateway; no bare MailglassInbound.* in the LiveView. |
| inbound_live.ex | Internal.Replay.replay/2 | gateway after tenant verify | ✓ WIRED | verify_tenant/2 precedes the un-scoped replay/2 (D-48-05). |
| inbound_live.ex | inbound_record_inserted/1 | subscribe on mount + handle_info | ✓ WIRED | Builder used (no literal); tenant-scoped re-fetch + prepend. |
| routing_trace.ex | Router.Matcher.explain/2 | gateway explain_routes per route | ✓ WIRED | Verdicts equal real matcher behavior. |
| router.ex | MailglassAdmin.InboundLive | live "/inbound" in operator live_session | ✓ WIRED | Auth-gated, available?/0-gated. |
| filters_form (search) → records.ex query | n/a | search filter application | ✗ NOT_WIRED | Search input rendered + URL-round-tripped but never reaches any query (WR-03). |
| records_list (outcome/mailbox) → records.ex projection | n/a | per-record disposition | ✗ NOT_WIRED | List badge/mailbox read fields the projection never supplies (WR-01). |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Admin inbound LiveView + component + topics tests | `mix test inbound_live_test.exs inbound/components_test.exs pub_sub/topics_test.exs` | 39 tests, 0 failures | ✓ PASS |
| Inbound matcher (V3) + read-model (V1) | `mix test matcher_test.exs records_test.exs --seed 0` | 2 properties, 22 tests, 0 failures | ✓ PASS |
| Full admin suite | `mix test` | 118 tests, 1 failure (only pre-existing voice_test "n**oops**" in inlined Phoenix dep JS — NOT phase 48) | ✓ PASS (phase-48 green) |
| Optional-dep contract (V4) | `mix compile --no-optional-deps --warnings-as-errors` | exit 0 (39 files) | ✓ PASS |
| List-level disposition correctness | grep tests for outcome/mailbox row assertions | No test asserts list outcome/mailbox reflects real disposition | ✗ FAIL (untested behavior masks WR-01) |

### Probe Execution

No conventional `scripts/*/tests/probe-*.sh` declared for this phase; verification used the phase's `<verify>` test commands directly (run independently above). N/A.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| IADM-01 | 48-01, 48-02 | Master/detail list with URL-param filters (provider, mailbox outcome, time window, search), tenant-required gate | ⚠️ PARTIAL | Tenant gate + provider/outcome/window verified; **mailbox/outcome display always constant (WR-01)** and **search filter dead (WR-03)**. |
| IADM-02 | 48-02, 48-03 | Detail shows canonical %InboundMessage{}, raw provider source (PII handling), matched mailbox + result, timeline of runs | ⚠️ PARTIAL | Raw source, matched mailbox/outcome, full timeline verified; **"From" cell shows recipient not sender (WR-02)**. |
| IADM-03 | 48-03 | Replay modal, destructive-action confirmation, tenant-bound, single target | ✓ SATISFIED | Tenant-gated + capability-gated + append-only replay (V2/V6/cross-tenant green). |
| IADM-04 | 48-01, 48-03 | Routing-trace card — matcher diff against `__mailglass_inbound_routes__/0` | ✓ SATISFIED | Per-route clause diff from explain/2; V3 equivalence proven. |
| IADM-05 | 48-01, 48-03 | InboundLive subscribes to PubSub for live updates | ✓ SATISFIED | Per-tenant subscribe via builder; tenant-scoped prepend (V7). |
| IADM-06 | 48-03 | Brand voice: composed, specific errors; no "Oops!" | ✓ SATISFIED | Voice sweep green; composed copy throughout phase-48 surfaces. |
| IADM-07 | 48-02 | Inbound surface reachable from admin, gated by existing Auth plug | ✓ SATISFIED | /inbound in operator live_session (Auth gate), available?/0-gated; no new auth surface. |

All 7 phase requirement IDs (IADM-01..07) are claimed across the three plans and accounted for. None orphaned. REQUIREMENTS.md maps exactly IADM-01..07 to Phase 48; no additional unclaimed IDs.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| records.ex | 47-57 | Projection missing outcome/mailbox; consumer renders constant via Map.get | ⚠️ Warning | List disposition is a constant falsehood (WR-01) — blocks SC#1 list display. |
| inbound_live.ex | 547,559,463 | `search` filter param collected + URL-routed but never applied to any query | ⚠️ Warning | Dead UI control (WR-03) — search is a named SC#1 filter that no-ops. |
| detail_header.ex | 65 | "From" cell wired to envelope_recipient, not @record.from | ⚠️ Warning | Labelled falsehood (WR-02) — sender never shown; blocks SC#2 canonical-message display. |
| destructive_action.ex | 22 | `when is_atom(adapter)` matches `nil` (nil is an atom) → Auth.authorize(nil,...) raises outside the with/else mapping | ℹ️ Info | Latent crash (WR-04). Shielded in production (operator Mount always sets adapter); inconsistent with authorize_reveal/1 which guards `not is_nil`. |
| inbound_live.ex / auth.ex | 521-534 / 85-92 | Non-standard adopter error tuple (e.g. {:error, :forbidden, %{}}) for :reveal_raw/:replay_inbound raises in normalize_result before the catch-all | ℹ️ Info | Latent crash on misbehaving adopter (WR-05). Default test/grant adapters use :unauthorized so it never trips today. |

No debt markers (TBD/FIXME/XXX), no secrets, no PII in telemetry, no UPDATE/DELETE on append-only tables. Tenant isolation, replay gate order, and the optional-dep gateway discipline are all sound.

### Human Verification Required

None. All checkable behaviors were verified programmatically (tests + grep + compile lanes). The two BLOCKER gaps are observable in code without running the UI.

### Gaps Summary

The security-critical and novel spine of Phase 48 is solid: tenant isolation (explicit `tenant_id` where + `Tenancy.scope/2` on every read-model query, blank/foreign tenant → []/nil), the tenant-gated + capability-gated append-only replay flow, the routing-trace card computed from real matcher reflection (V3 equivalence proven), the default-redacted evidence card with a working :reveal_raw gate, per-tenant live PubSub updates, and the optional-dep gateway (--no-optional-deps compiles clean). IADM-03/04/05/06/07 are fully met.

Two functional-correctness defects in the read/display layer keep the phase from achieving its stated goal of giving operators "the same observability they have for outbound":

1. **The list card is misleading (SC#1, IADM-01).** The list read-model never projects `outcome` or `mailbox`, so every row shows a constant "Pending" badge and "no match" mailbox — an operator filtering to `:accept` still sees every row as "Pending". Separately, the **search** filter (named explicitly in SC#1 and the requirement) is collected by the form and routed through the URL but never applied by any query: typing a search does nothing. These two are independent root causes (one a projection gap, one missing query wiring).

2. **The detail "From" is wrong (SC#2, IADM-02).** The "From" cell renders the masked recipient, not the sender. `InboundRecord.from` exists and is never read, so the operator triaging "who sent this?" is shown a labelled falsehood (a duplicate of the recipient already in the title).

These match the independent code review's WR-01/WR-02/WR-03 exactly; verifying against the code confirms all three. Each is a small, well-scoped fix (project the latest-fresh-run outcome/mailbox into the list; thread + implement search; read `from` in the From cell). They are display/query gaps, not architectural ones — no re-plan of the phase is required, but they must be closed for the goal ("same observability as outbound", filterable by mailbox/outcome/search, canonical message with sender) to hold.

Also flagged (Info, non-blocking): two latent crash paths (WR-04 nil-adapter guard, WR-05 non-standard adopter error tuple) that are shielded in production today but should be hardened.

---

_Verified: 2026-05-24T20:10:00Z_
_Verifier: Claude (gsd-verifier)_
