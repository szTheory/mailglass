---
phase: 46-mailgun-ses-inbound-ingress
plan: 01
subsystem: api
tags: [inbound, webhook, signature, ses, sns, s3, plug, error-contract, behaviour]

# Dependency graph
requires:
  - phase: 45-inbound-telemetry-idempotency-foundation
    provides: MailglassInbound.MIME parser + MIMEError closed-type error template + ingress telemetry spans
  - phase: 16-ses-webhook-provider-sns-cache
    provides: core SES SNS X.509 verify, CertCache, TrustPolicy (the reuse seam source)
provides:
  - "MailglassInbound.SignatureError — net-new package-local, no-recovery, closed-type inbound signature error (D-46-19)"
  - "MailglassInbound.S3FetchError — net-new package-local closed-type S3-fetch error (D-46-17)"
  - "MailglassInbound.S3Fetcher — fetch/3 behaviour contract (D-46-13)"
  - "Ingress.Provider.verify!/2 widened to the 3-variant union {:ok, facts} | {:replay} | {:control_plane, status}"
  - "Ingress.Plug: four-provider allowlist (one switch), 3-variant do_call result case, dual SignatureError rescue"
  - "Mailglass.Webhook.Providers.SES.verify_envelope!/2 — cross-package crypto reuse seam (D-46-01)"
affects: [46-02-mailgun-ingress, 46-03-ses-ingress, phase-50-inbound-setup-docs]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Mixed-arity behaviour transition via @optional_callbacks (legacy verify!/3 + struct verify!/2)"
    - "Forward-referenced intra-phase modules guarded with @compile no_warn_undefined"
    - "Cross-package crypto seam: extract verify_envelope!/2 so inbound reuses outbound X.509 verify"
    - ":provider_module opts test seam to exercise widened verify-result branches without real providers"

key-files:
  created:
    - mailglass_inbound/lib/mailglass_inbound/signature_error.ex
    - mailglass_inbound/lib/mailglass_inbound/s3_fetch_error.ex
    - mailglass_inbound/lib/mailglass_inbound/s3_fetcher.ex
    - mailglass_inbound/test/mailglass_inbound/signature_error_test.exs
    - mailglass_inbound/test/mailglass_inbound/s3_fetch_error_test.exs
  modified:
    - mailglass_inbound/lib/mailglass_inbound/ingress/provider.ex
    - mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex
    - mailglass_inbound/lib/mailglass_inbound/ingress/providers/sendgrid.ex
    - lib/mailglass/webhook/providers/ses.ex
    - mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs
    - test/mailglass/webhook/providers/ses_test.exs
    - mailglass_inbound/docs/api_stability.md
    - mailglass_inbound/CHANGELOG.md

key-decisions:
  - "api_stability.md path: plan said docs/api_stability.md, but inbound errors live in mailglass_inbound/docs/api_stability.md (the real location); documented there"
  - "Widened do_call case also handles legacy bare-map verify returns (Postmark/SendGrid) so those providers stay unedited"
  - "@optional_callbacks for both verify! arities — the canonical mixed-arity transition idiom; zero edits to Postmark"

patterns-established:
  - "Closed-type package-local error: @types + @derive excluding :cause (+ :provider) + __types__/0 + docs cross-check test"
  - "Three-variant verify result contract: replay/control-plane = 200 no-op no-record; verified = persist; forgery = raise -> 401"

requirements-completed: [MGUN-04, SESI-03]

# Metrics
duration: 32min
completed: 2026-05-23
---

# Phase 46 Plan 01: Mailgun + SES Inbound Foundation Summary

**Two net-new closed-type inbound errors, the S3Fetcher behaviour, a widened four-provider ingress plug with a three-variant verify-result contract + dual SignatureError rescue, and an extracted core SES `verify_envelope!/2` crypto-reuse seam — the shared surface both Plans 02 (Mailgun) and 03 (SES) build on.**

## Performance

- **Duration:** ~32 min
- **Started:** 2026-05-23T15:34:00Z
- **Completed:** 2026-05-23T15:42:00Z
- **Tasks:** 3
- **Files modified:** 14 (5 created, 9 modified)

## Accomplishments
- `MailglassInbound.SignatureError` (no-recovery, closed types `[:bad_signature, :missing_header, :malformed_header, :timestamp_skew, :subscribe_url_untrusted]`, `:provider` field, `new/2` builder) and `MailglassInbound.S3FetchError` (closed types `[:s3_object_not_ready, :s3_fetch_failed]`) — both package-local, PII/secret-safe `Jason.Encoder`, contract-tested against `api_stability.md`.
- `MailglassInbound.S3Fetcher` behaviour: `@callback fetch/3` contract (implementations deferred to Plan 03 by design).
- `Ingress.Provider.verify!/2` widened to express `{:ok, facts} | {:replay} | {:control_plane, status}`; legacy `verify!/3` retained, both `@optional_callbacks` for the mixed-arity transition.
- `Ingress.Plug`: allowlist now `[:postmark, :sendgrid, :mailgun, :ses]` (one `init/1` guard + one `provider_module/1` switch); `do_call/2` dispatches the three-variant result (replay + control-plane are 200 no-ops with no `InboundRecord`); rescues both `Mailglass.SignatureError` and `MailglassInbound.SignatureError` to 401.
- Core `Mailglass.Webhook.Providers.SES.verify_envelope!/2` extracted as the inbound-reuse crypto seam; outbound `verify!/3` return + behavior unchanged (217 core webhook tests green).

## Task Commits

1. **Task 1: Net-new closed-type errors (TDD)** - `9178d3d` (feat) — RED/GREEN within one commit (failing tests written first, then modules)
2. **Task 2: S3Fetcher behaviour + widened Provider callback** - `ea3ce7d` (feat)
3. **Task 3: Widen plug (4-provider + 3-variant + dual rescue) + SES verify_envelope!/2** - `79cf565` (feat)

## Files Created/Modified
- `mailglass_inbound/lib/mailglass_inbound/signature_error.ex` - No-recovery inbound signature error (created)
- `mailglass_inbound/lib/mailglass_inbound/s3_fetch_error.ex` - S3 fetch error, closed-type (created)
- `mailglass_inbound/lib/mailglass_inbound/s3_fetcher.ex` - `fetch/3` behaviour (created)
- `mailglass_inbound/lib/mailglass_inbound/ingress/provider.ex` - Widened `verify!/2` union + `@optional_callbacks`
- `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` - Allowlist, 3-variant `do_call` case, `persist_and_respond/5` extract, dual rescue, `:provider_module` test seam, `no_warn_undefined` forward refs
- `mailglass_inbound/lib/mailglass_inbound/ingress/providers/sendgrid.ex` - `@impl false -> @impl Provider` annotation only (no logic change)
- `lib/mailglass/webhook/providers/ses.ex` - Extracted `verify_envelope!/2` seam; `verify!/3` calls it then dispatches
- `test/mailglass/webhook/providers/ses_test.exs` - `verify_envelope!/2` seam contract tests
- `mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs` - Allowlist + widened-branch + dual-rescue tests via stub provider
- `mailglass_inbound/docs/api_stability.md` - Both new closed-type sets, `@since 0.2.0`
- `mailglass_inbound/CHANGELOG.md` - Both new errors documented

## Decisions Made
- **api_stability.md location:** the plan referenced `docs/api_stability.md`, but inbound errors are documented in `mailglass_inbound/docs/api_stability.md` (where `MIMEError` lives). Documented both new type sets there; the contract tests read that file.
- **Legacy bare-map handling:** the widened `do_call` `case` keeps a `facts when is_map(facts)` clause so the unchanged Postmark/SendGrid `verify!` (which return a bare `%{auth: ...}` map) continue to persist. This honored the plan's "do NOT edit Postmark/SendGrid source" constraint while supporting the new tuple variants.
- **`@optional_callbacks`:** marked both `verify!/2` and `verify!/3` optional so each provider implements exactly the one arity it uses (Postmark `/3`, SendGrid/Mailgun/SES `/2`) without unmet-callback warnings.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fetched package dependencies (not present in worktree)**
- **Found during:** Task 1 (RED phase could not compile)
- **Issue:** `deps/` was empty in the fresh worktree; `mix test` failed with "dependency is not available".
- **Fix:** Ran `mix deps.get` (declared deps, already pinned in committed `mix.lock` — not a new package install).
- **Verification:** Tests compile and run.
- **Committed in:** N/A (environment setup, no source change)

**2. [Rule 3 - Blocking] Mixed-arity callback warnings under --warnings-as-errors**
- **Found during:** Task 2 (widening `verify!` callback to arity 2)
- **Issue:** Changing the `verify!` callback arity made Postmark's `verify!/3` and SendGrid's `@impl false verify!/2` annotations warn (stale `@impl`), breaking `mix compile --warnings-as-errors`.
- **Fix:** Declared BOTH `verify!/2` (widened union) and legacy `verify!/3` callbacks and marked both `@optional_callbacks`; changed SendGrid's `verify!/2` annotation from `@impl false` to `@impl MailglassInbound.Ingress.Provider` (annotation only, no logic).
- **Files modified:** `ingress/provider.ex`, `ingress/providers/sendgrid.ex`
- **Verification:** `mix compile --warnings-as-errors` clean; SendGrid provider tests green.
- **Committed in:** `ea3ce7d` (Task 2 commit)

**3. [Rule 3 - Blocking] Forward-referenced Mailgun/SES provider modules**
- **Found during:** Task 3 (adding `:mailgun`/`:ses` `provider_module/1` clauses)
- **Issue:** The Mailgun/SES provider modules land in Plans 02/03; referencing them broke `--warnings-as-errors` (undefined module).
- **Fix:** Added `@compile {:no_warn_undefined, [...Mailgun, ...SES]}` to the plug (narrowly scoped, intra-phase forward references).
- **Files modified:** `ingress/plug.ex`
- **Verification:** Both compile lanes clean; the modules are only resolved when a `:mailgun`/`:ses` request is dispatched (Wave 2).
- **Committed in:** `79cf565` (Task 3 commit)

**4. [Rule 2 - Missing Critical] `:provider_module` opts test seam**
- **Found during:** Task 3 (testing the widened verify-result branches)
- **Issue:** The plan asked to "inject a stub provider via the opts seam," but no provider-module override existed; the widened `{:replay}`/`{:control_plane}`/dual-rescue branches were otherwise untestable without the real (not-yet-built) providers.
- **Fix:** Added an optional `:provider_module` opts override consulted by `verify_request!`/`normalize_request!` (defaults to the hardcoded `provider_module/1` in production). Threaded `opts` through both helpers.
- **Files modified:** `ingress/plug.ex`, `ingress/plug_test.exs`
- **Verification:** New plug tests exercise all widened branches; production path unchanged (no `:provider_module` in real opts).
- **Committed in:** `79cf565` (Task 3 commit)

**5. [Rule 1 - Bug] `new/2` raised FunctionClauseError instead of ArgumentError**
- **Found during:** Task 1 (GREEN phase)
- **Issue:** Plan behavior Test 4 requires `SignatureError.new(:not_a_type, [])` to raise `ArgumentError`; the `when type in @types` guard alone raised `FunctionClauseError`.
- **Fix:** Added an explicit fallthrough `new/2` clause that raises `ArgumentError` with the valid-types list.
- **Files modified:** `signature_error.ex`
- **Verification:** Test 4 passes.
- **Committed in:** `9178d3d` (Task 1 commit)

---

**Total deviations:** 5 (2 environment/blocking compile, 1 forward-ref, 1 missing test seam, 1 bug)
**Impact on plan:** All deviations were necessary for correctness, clean compilation, or testability. No scope creep — no provider-specific logic was added (that is Plans 02/03). Postmark stayed completely unedited; SendGrid changed by one annotation only.

## Issues Encountered
- **mix.lock environmental drift:** `mix deps.get` in this worktree upgraded several unrelated transitive deps (castore, decimal, ecto, finch, telemetry, …) because the locked versions were not in the local hex cache. These lock changes are out of plan scope, so `mix.lock` was intentionally excluded from all commits. The orchestrator/merge should resolve the lock normally on the integration branch.
- No active git hooks exist in this repo (samples only), so commits ran with hooks effectively no-op.

## Threat Model Coverage
- **T-46-01 (Spoofing):** dual `SignatureError` rescue -> 401 no-recovery, tested (both error structs).
- **T-46-02 (Tampering):** replay/control-plane are 200 no-ops with NO `InboundRecord`, asserted in plug tests.
- **T-46-03 (Repudiation/DoS):** replay + control-plane return 200 (never 401/500), so providers don't retry-storm.
- **T-46-04 (Info Disclosure):** both error structs `@derive Jason.Encoder only [:type, :message, :context]` (exclude `:cause`/`:provider`); plug stop-meta stays PII-free, tested.
- **T-46-05 (Tampering on the seam):** `verify_envelope!/2` extraction kept outbound `verify!/3` identical — 217 core webhook tests green.

## Next Phase Readiness
- Plan 02 (Mailgun) and Plan 03 (SES) are unblocked: the result contract expresses `{:replay}`/`{:control_plane, _}`, the plug rescues the inbound `SignatureError`, the SES X.509 verify is reusable via `verify_envelope!/2`, and the `S3Fetcher` behaviour exists for Plan 03's `Fake`/`ExAwsS3` adapters.
- The Mailgun/SES `provider_module/1` clauses reference modules that Plans 02/03 must create (currently guarded by `no_warn_undefined`).

## Self-Check: PASSED

All created files verified on disk; all task commits (`9178d3d`, `ea3ce7d`, `79cf565`) plus the SUMMARY commit (`675059f`) present in git history.
