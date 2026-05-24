---
phase: 48-inbound-admin-liveview
plan: 03
subsystem: admin-ui
tags: [liveview, inbound, routing-trace, evidence, replay, pubsub, tenancy, pii, brand-voice]

# Dependency graph
requires:
  - phase: 48-inbound-admin-liveview (plan 01, Wave 0)
    provides: "OptionalDeps.MailglassInbound gateway (available?/0 + apply/3 wrappers + explain/2), Router.Matcher.explain/2 reflection, Internal.Operator.{Records,Timeline,Detail} read-models, Internal.Replay.replay/2, Components.mask_recipient/1, PubSub.Topics.inbound_record_inserted/1 builder, :inbound_router opt threaded through __operator_session__"
  - phase: 48-inbound-admin-liveview (plan 02, Wave 1)
    provides: "InboundLive master/detail shell with the two Wave-2 detail-pane slots, Inbound.* sibling components (records_list, detail_header, timeline, filters_form, replay_modal, destructive_action), /admin/inbound route, InboundFixtures"
provides:
  - "MailglassAdmin.Inbound.RoutingTrace — per-route clause-diff card from Router.Matcher.explain/2 verdicts (IADM-04); rendered only on :no_match; masked recipient actuals, nil->any/regex->~r//exact-verbatim, first-failing-clause emphasis + composed reason copy"
  - "MailglassAdmin.Inbound.EvidenceCard — default-redacted raw provider source with the :reveal_raw capability gate (IADM-02 raw half); raw_payload/raw_mime bytes absent from HTML until granted"
  - "InboundLive replay confirm flow — tenant-gated (D-48-05) + :replay_inbound capability-gated (V6) + :no_match-blocked (V11); appends an append-only :replay ExecutionRun on success (V2)"
  - "InboundLive live updates (IADM-05) — subscribe via the topic builder (LINT-06), handle_info re-fetches tenant-scoped + prepends without stealing selection/filters (V7)"
  - "OptionalDeps.MailglassInbound.explain_routes/2 — reflect adopter routes + build message + per-route explain in the gateway (no MailglassInbound.* in the LiveView/components)"
affects: [inbound-admin-liveview, operator-dashboard, routing-trace-card, evidence-card, phase-49]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Routing-trace verdict rendering reuses Router.Matcher.explain/2 (single source of truth, D-48-06) — the view computes pass/fail from the gateway, never re-implements equality/regex/wildcard"
    - "Default-redacted capability-gated raw-source card driven by the schema redact: true fields; reveal rides Auth.authorize/3 :reveal_raw with no new auth surface (D-48-09)"
    - "Replay confirm gate order: tenant check (D-48-05) BEFORE the un-scoped gateway replay/2, then capability gate, then structured-error -> UI-SPEC copy by tuple match (never message string, CLAUDE.md rule 7)"
    - "id-only PubSub payload re-fetched tenant-scoped before prepend (Pitfall 6); foreign/filtered id resolves to nil and is dropped"
    - "Gateway-owned cross-package helper (explain_routes/2) keeps the consumer free of compile-time MailglassInbound references so --no-optional-deps stays green"

key-files:
  created:
    - mailglass_admin/lib/mailglass_admin/inbound/routing_trace.ex
    - mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex
  modified:
    - mailglass_admin/lib/mailglass_admin/inbound_live.ex
    - mailglass_admin/lib/mailglass_admin/optional_deps/mailglass_inbound.ex
    - mailglass_admin/test/mailglass_admin/inbound_live_test.exs
    - mailglass_admin/test/support/inbound_fixtures.ex
    - mailglass_admin/test/support/endpoint_case.ex
    - mailglass_admin/priv/static/app.css

key-decisions:
  - "Gateway explain_routes/2 (NEW) owns the route reflection + InboundMessage construction + per-route explain so the LiveView/components never reference MailglassInbound.* — keeps the --no-optional-deps lane clean (the existing explain/2 wrapper alone would have forced the LiveView to build the message itself, leaking Execution.message_from_record/1 into the consumer)."
  - "Cross-tenant replay (D-48-05) is enforced at TWO layers: the detail read-model already tenant-gates the load (a foreign id resolves to nil -> detail_error), and confirm_replay treats a selected-but-unresolved id (detail_error set) as a not-authorized block before any replay call. The verify_tenant/2 record.tenant_id == active check is the belt-and-suspenders directly before the un-scoped replay/2."
  - "The committed priv/static/app.css was STALE from Waves 0/1 — it never reflected Wave-1 classes (text-warning, bg-secondary, btn-disabled, mask, sticky). Verified by rebuilding with my new components removed: the bundle still drifted. Rebuilt the full phase-48 bundle (Rule 1 fix) so CI git diff --exit-code passes (CLAUDE.md rule 6)."
  - "Net-new utility classes in the two new cards were swapped for primitives already in the bundle (max-h-96->max-h-80, sm:grid-cols-3->sm:grid-cols-2, items-baseline->items-center, dropped the sm:w-40/sm:shrink-0/sm:flex-row clause split) to honor UI-SPEC zero-new-tokens; text-success is kept as the spec-mandated pass-marker semantic color."
  - "TestOperatorAuth gained :replay_inbound + :reveal_raw clauses (grant by default, deny via a sentinel subject_id) so denial-path tests drive the gate through the session-controlled current_user_id without swapping the fixed router-bound adapter."

patterns-established:
  - "Routing-trace as a per-route clause table built ENTIRELY from explain/2 output — the only inbound observability surface with no outbound analog, reusing card/badge/heroicon chrome."
  - "Capability-gated reveal of redact:true schema fields: default-redacted, :reveal_raw over the existing Auth seam, raw bytes provably absent from HTML until granted."

requirements-completed: [IADM-02, IADM-03, IADM-04, IADM-05, IADM-06]

# Metrics
duration: ~35min
completed: 2026-05-24
---

# Phase 48 Plan 03: Inbound Admin LiveView — Wave 2 Routing-Trace, Evidence, Replay + Live Updates Summary

**Shipped the two NET-NEW inbound cards and the live behavior that completes the surface: the routing-trace card (IADM-04) renders a per-route clause diff computed from `Router.Matcher.explain/2` (verdict = real matcher behavior, no re-implementation, masked actuals, composed reasons, only on `:no_match`); the evidence card (IADM-02) is default-redacted with a `:reveal_raw` capability gate; the replay confirm flow is tenant-gated (D-48-05) + capability-gated (V6) + `:no_match`-blocked (V11) and appends an append-only `:replay` `ExecutionRun` on success (V2); live PubSub updates (IADM-05) prepend tenant-scoped without stealing selection (V7); and a full brand-voice (V10) + PII (V5) sweep is green — all behind the runtime gateway so `--no-optional-deps` stays clean.**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-05-24T17:20:00Z
- **Completed:** 2026-05-24T17:54:51Z
- **Tasks:** 3
- **Files modified:** 8 (2 created, 6 modified)

## Accomplishments

- Routing-trace card (IADM-04) renders one bordered sub-card per declared inbound route (declared order via `__mailglass_inbound_routes__/0`), each with a Dimension / Expected / Actual clause table whose check/x markers come straight from `Router.Matcher.explain/2` — so the displayed verdict equals real matcher behavior. The card appears ONLY when the displayed outcome is `:no_match`, masks the recipient actual via `Components.mask_recipient/1`, renders `nil → any` / `%Regex{} → ~r/.../` / exact verbatim, and emphasizes the first failing clause (`border-l-4 border-error`) with a composed reason line + the UI-SPEC legend.
- Evidence card (IADM-02 raw half) is default-redacted: `raw_payload`/`raw_mime` bytes are absent from the HTML until `:reveal_raw` is granted; `verification_facts` + a redacted summary (provider, payload byte size, header count) always render; reveal rides `Auth.authorize/3` `:reveal_raw` (no new auth surface), granting a read-only `<pre>` scroll region, denying with the brand-voice line.
- Replay confirm flow (IADM-03): the tenant gate (D-48-05) precedes the un-scoped gateway `replay/2`; the `:replay_inbound` capability gate (V6) changes no state on denial; a `:no_match` record surfaces "Replay blocked: mailbox module not found." (mapped on the `{:replay_mailbox_missing, ...}` tuple, never the string — V11); a matched record appends exactly one `:replay` `ExecutionRun` (append-only, no UPDATE — V2) + the success flash.
- Live updates (IADM-05): the LiveView subscribes on the connected mount via `MailglassAdmin.PubSub.Topics.inbound_record_inserted/1` (the builder, never a literal — LINT-06 / V9); `handle_info` re-fetches the id-only payload tenant-scoped and prepends without stealing the selection or resetting filters (V7), dropping a foreign/filtered id.
- Brand-voice (V10) + PII (V5) sweep is green: every empty/error/blocked/success state asserts verbatim UI-SPEC copy and refutes "Oops/Whoops/Uh oh/Something went wrong"; the recipient is masked across list + detail header + routing-trace actual; raw bytes are absent until `:reveal_raw`.
- `--no-optional-deps --warnings-as-errors` stays green (39 files) — the new `explain_routes/2` and the reveal/replay paths all cross the runtime `apply/3` gateway, so the admin still compiles with inbound stripped (V4).

## Task Commits

Each task was committed atomically (TDD tasks committed test + impl together after reaching green):

1. **Task 1: Routing-trace + evidence cards wired into the detail pane** — `68f90b6` (feat)
2. **Task 2: Tenant-gated replay confirm flow + live PubSub updates** — `9b76dab` (feat)
3. **Task 3: Brand-voice + PII sweep; rebuild admin bundle (drift fix)** — `2f31c26` (test)

## Files Created/Modified

**Created:**
- `mailglass_admin/lib/mailglass_admin/inbound/routing_trace.ex` — per-route clause-diff card from `explain/2` verdicts; masked recipient actual; nil/regex/exact rendering; first-failing emphasis + composed reasons + legend.
- `mailglass_admin/lib/mailglass_admin/inbound/evidence_card.ex` — default-redacted raw provider source; `:reveal_raw` gate; redacted summary + verification_facts always shown; read-only `<pre>` on grant.

**Modified:**
- `mailglass_admin/lib/mailglass_admin/inbound_live.ex` — thread `:inbound_router` + tenant from session; compute `routing_trace` for `:no_match`; `reveal_raw` handler (Auth `:reveal_raw`); `confirm_replay` (tenant gate -> capability gate -> replay -> tuple-mapped UI-SPEC copy); subscribe via the builder; `handle_info` tenant-scoped prepend; render both cards in the detail slot.
- `mailglass_admin/lib/mailglass_admin/optional_deps/mailglass_inbound.ex` — `explain_routes/2` (reflect routes + build message + per-route explain) + `MailglassInbound.Execution` in `@compile no_warn_undefined`.
- `mailglass_admin/test/mailglass_admin/inbound_live_test.exs` — Task-1/2/3 coverage (routing-trace, evidence-default, V2/V6/V7/V11/cross-tenant replay, live-update prepend/drop, V10 voice sweep, V5 full PII).
- `mailglass_admin/test/support/inbound_fixtures.ex` — pass through `headers` on records and `evidence:` opts (raw_payload/verification_facts) so trace/evidence seeds work.
- `mailglass_admin/test/support/endpoint_case.ex` — `TestOperatorAuth` `:replay_inbound` + `:reveal_raw` clauses (grant default, deny via sentinel subject).
- `mailglass_admin/priv/static/app.css` — rebuilt bundle reflecting the full phase-48 class set (resolves pre-existing Wave-0/1 staleness + Task-1 additions).

## Decisions Made

- **`explain_routes/2` lives in the gateway, not the component.** The Wave-0 `explain/2` wrapper takes a `(route, message)` pair, but the InboundMessage must be reconstructed from the stored record via `Execution.message_from_record/1` — an inbound-package call. Putting the reflection-plus-message-build behind a single gateway function keeps every `MailglassInbound.*` reference inside the conditionally-compiled gateway, so the routing-trace component and the LiveView stay free of compile-time inbound references (the `--no-optional-deps` lane requirement).
- **Cross-tenant replay is blocked at the read-model AND the confirm handler.** A tenant-A operator selecting a guessed tenant-B id can't even load the detail (the read-model tenant-gates it to `nil`, surfacing `detail_error`); `confirm_replay` maps a selected-but-unresolved id to the not-authorized copy before any replay. The explicit `record.tenant_id == active_tenant` check (`verify_tenant/2`) is the belt-and-suspenders directly before the un-scoped `replay/2` (D-48-05).
- **The bundle drift is a pre-existing Wave-0/1 bug, fixed here.** Rebuilding with my new components removed still drifted the bundle (it was missing Wave-1's `text-warning`/`bg-secondary`/`btn-disabled`/`mask`/`sticky`). The committed bundle was never rebuilt after Waves 0/1, which would fail CI's `git diff --exit-code` (CLAUDE.md rule 6). Rebuilt the full phase-48 bundle (Rule 1).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Rebuilt the stale `priv/static/app.css` bundle**
- **Found during:** Task 3 (bundle-drift gate)
- **Issue:** `mix mailglass_admin.assets.build` produced a diff against the committed `app.css`. Verified by rebuilding with my two new components removed: the bundle STILL drifted, adding `text-warning`/`bg-secondary`/`btn-disabled`/`mask`/`sticky` — all Wave-0/1 classes. The committed bundle was never rebuilt after Waves 0/1 and would fail CI's `git diff --exit-code priv/static/` (CLAUDE.md rule 6).
- **Fix:** Minimized my own net-new tokens (swapped `max-h-96`→`max-h-80`, `sm:grid-cols-3`→`sm:grid-cols-2`, `items-baseline`→`items-center`, dropped the `sm:w-40`/`sm:shrink-0`/`sm:flex-row` clause split) and rebuilt the full bundle so it reflects the complete phase-48 class set. The rebuilt bundle only ADDS phase-48 selectors (no removals).
- **Files modified:** `mailglass_admin/priv/static/app.css`, `routing_trace.ex`, `evidence_card.ex`
- **Verification:** `git diff --exit-code mailglass_admin/priv/static/` exits 0 after the commit.
- **Committed in:** `2f31c26` (Task 3 commit)

**2. [Rule 3 - Blocking] Extended `TestOperatorAuth` with `:replay_inbound` + `:reveal_raw`**
- **Found during:** Task 2 (replay/reveal authorization tests)
- **Issue:** The router-bound test Auth adapter only handled `:operator_access` + `:destructive_action`; the new `:replay_inbound`/`:reveal_raw` actions raised `FunctionClauseError` at the authorize call, blocking the capability tests.
- **Fix:** Added the two action clauses (grant by default, deny for a sentinel `subject_id`) so denial-path tests drive the gate via the session-controlled `current_user_id`. This rides the existing `atom()` action type — no new auth module/plug/behaviour (D-48-09). It is test-support only.
- **Files modified:** `mailglass_admin/test/support/endpoint_case.ex`
- **Verification:** V6 (replay deny) + the evidence reveal-denied test go green.
- **Committed in:** `9b76dab` (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (1 pre-existing bundle-staleness bug, 1 blocking test-Auth gap)
**Impact on plan:** Both were necessary to complete the planned work. The bundle rebuild resolves a pre-existing CI gate failure inherited from Waves 0/1; the test-Auth extension is the exact seam D-48-09 calls for (no new auth surface).

## Authentication Gates

None — no external service auth required. The `:replay_inbound` and `:reveal_raw` capability gates ride the existing operator `Auth.authorize/3` seam; denials are normal flow (brand-voice flash / redacted placeholder), not auth gates.

## Issues Encountered

- **HEEx HTML-escapes apostrophes.** The replay-success copy ("…this message's timeline.") renders as `&#39;` in the HTML. Added a small `unescape/1` helper in the test to decode the handful of entities Phoenix emits so copy assertions can use the verbatim UI-SPEC string. (The rendered copy is correct — this is a test-assertion concern only.)
- **The committed `app.css` was stale (see Deviation 1).** Surfaced at the bundle-drift gate; resolved by rebuilding.

## Deferred Issues

- **Pre-existing `voice_test.exs` failure (NOT phase 48).** `mailglass_admin/test/mailglass_admin/voice_test.exs` "banned exclamations" fails because `=~ "oops"` matches "n**oops**" inside the inlined Phoenix dependency JS surfaced via the PreviewLive `/dev/mail` page. This is unrelated to the inbound surface, the dep version is being bumped separately by the user, and the executor was explicitly instructed not to touch it. Everything phase-48 added is green; this is the only admin-wide failure (1 of 118).
- **Pre-existing `citext_probe.ex` Boundary/reraise warnings** (test-support file, untouched) make `mix test --warnings-as-errors` (the `verify.preview` test step) abort at compile, and `mix credo --strict` exit 16. Logged in Wave 0's `deferred-items.md`; out of scope (SCOPE BOUNDARY). All warnings in the `verify.preview` run come exclusively from `test/support/citext_probe.ex` — none from any file this plan added.
- **Custom `Mailglass.Credo.*` checks report "undefined" in the admin worktree** (Wave 0 deferred item) — they live in the core package and aren't compiled into the admin's credo run here. LINT-06 (PrefixedPubSubTopics) compliance is verified by the grep gate (0 literal topic strings; the builder is the single source).

## Known Stubs

None. The evidence card's "redacted placeholder" is an intentional, fully-wired feature (the `:reveal_raw` gate), not a stub; the gateway "inbound package is not available" copy is the legitimate degraded-mode fallback when `mailglass_inbound` is absent.

## Verification

- `cd mailglass_admin && mix test test/mailglass_admin/inbound_live_test.exs --warnings-as-errors` — 25 inbound LiveView tests green (V2, V5, V6, V7, V10, V11).
- `cd mailglass_admin && mix test test/mailglass_admin/inbound_live_test.exs test/mailglass_admin/inbound/components_test.exs --warnings-as-errors` — 35 inbound tests green.
- `cd mailglass_admin && mix compile --no-optional-deps --warnings-as-errors` — green (V4; 39 files).
- `cd mailglass_admin && mix mailglass_admin.assets.build` then `git diff --exit-code priv/static/` — exits 0 after the rebuilt bundle is committed.
- `cd mailglass_admin && mix credo --strict <new/modified lib files>` — no issues.
- `cd mailglass_admin && mix test --exclude flaky` — 118 tests, 1 failure (only the pre-existing/unrelated `voice_test`).
- `cd mailglass_inbound && mix test --seed 0` — 239 tests + 3 properties, 0 failures (phase gate, deterministic).

## Acceptance Greps (all pass)

- `grep -c 'explain' .../routing_trace.ex` ≥ 1 AND `grep -c 'Regex.match?' .../routing_trace.ex` == 0 (no matcher re-implementation in the view).
- `grep -c 'reveal_raw' .../evidence_card.ex` == 4 (≥ 1).
- `grep -c '{:replay_mailbox_missing' .../inbound_live.ex` == 1 (tuple match, not string).
- `grep -c 'inbound_record_inserted' .../inbound_live.ex` == 2 AND `grep -c '"mailglass:inbound:' .../inbound_live.ex` == 0 (LINT-06 / V9 — builder, no literal).

## Threat Surface

No new security-relevant surface beyond the plan's `<threat_model>`. All registered mitigations are implemented and test-covered:
- T-48-10 (cross-tenant replay): `verify_tenant/2` before the un-scoped `replay/2` + the read-model tenant gate; cross-tenant test asserts no run appended for a foreign id.
- T-48-11 (replay authorization): `:replay_inbound` via `Auth.authorize/3`; denial changes no state (V6).
- T-48-12 (evidence raw bytes): default-redacted; `:reveal_raw` gate; bytes absent until granted (V5).
- T-48-13 (routing-trace recipient): masked via `Components.mask_recipient/1`; `refute html =~ raw_recipient` in the trace (V5).
- T-48-14 (live-update payload): id-only re-fetched tenant-scoped; foreign/filtered id dropped (V7).
- T-48-15 (LiveView telemetry): the LiveView emits no telemetry; the broadcast payload is already PII-free.
- T-48-SC (no package installs): holds — zero new packages this plan.

No `## Threat Flags` — no new endpoints, auth paths, file access, or schema changes at trust boundaries were introduced.

## Self-Check: PASSED

Both created source files verified present on disk; all 3 task commits verified in git log; the rebuilt `priv/static/app.css` is committed (`git diff --exit-code` exits 0); 35 inbound tests green at `--warnings-as-errors`; inbound suite green at `--seed 0`. `mix.lock` was not changed by this plan (no new dependency) — nothing for the orchestrator to reconcile.

---
*Phase: 48-inbound-admin-liveview*
*Completed: 2026-05-24*
