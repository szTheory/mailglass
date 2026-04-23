---
phase: 04-webhook-ingest
plan: 04
subsystem: webhook
tags: [plug, telemetry, tenancy, signature, logging, d10, d13, d14, d21, d22, d23, d24]

# Dependency graph
requires:
  - phase: 04-webhook-ingest
    plan: 01
    provides: "V02 migration, Mailglass.WebhookCase + WebhookFixtures, Mailglass.Telemetry.span/3 wrapper (D-27), Mailglass.Outbound.Projector.broadcast_delivery_updated/3 post-commit contract"
  - phase: 04-webhook-ingest
    plan: 02
    provides: "Sealed Mailglass.Webhook.Provider @behaviour (verify!/3 + normalize/2), Mailglass.Webhook.CachingBodyReader (populates conn.private[:raw_body]), Mailglass.Webhook.Providers.Postmark, SignatureError + ConfigError extended atom sets"
  - phase: 04-webhook-ingest
    plan: 03
    provides: "Mailglass.Webhook.Providers.SendGrid (ECDSA P-256 verify!/3 + Anymail normalize/2)"
  - phase: 02-persistence-tenancy
    provides: "Mailglass.Tenancy (put_current/1, current/0, with_tenant/2 block form, resolver/0), Mailglass.TenancyError"
provides:
  - "Mailglass.Webhook.Plug — single-ingress orchestrator (CONTEXT D-10) implementing @behaviour Plug with init/1 + call/2"
  - "Response code matrix: 200 (success/duplicate replay), 401 (%SignatureError{}), 422 (%TenancyError{:webhook_tenant_unresolved}), 500 (%ConfigError{} or ingest failure)"
  - "Outer telemetry span [:mailglass, :webhook, :ingest, :start | :stop | :exception] with per-request stop metadata (provider, tenant_id, status, failure_reason, event_count, duplicate)"
  - "Inner telemetry span [:mailglass, :webhook, :signature, :verify, :start | :stop | :exception]"
  - "Mailglass.TenancyError :webhook_tenant_unresolved atom (Phase 4 D-14 precondition — Plan 05 formalizes api_stability.md)"
  - "Mailglass.Tenancy.resolve_webhook_tenant/1 dispatcher stub (function_exported? fallback returns {:ok, \"default\"}; Plan 05 ships full @optional_callback)"
  - "Logger.warning format discipline (CONTEXT D-24): \"provider=<atom> reason=<atom>\" only — no IP, headers, body, or credential values"
  - "Metadata whitelist compliance (CONTEXT D-23): no :ip, :user_agent, :remote_ip, :raw_body, :headers, :body in any telemetry meta map"
affects: [04-05, 04-06, 04-07, 04-08, 04-09]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Direct :telemetry.span/3 call (not Mailglass.Telemetry.span/3 wrapper) — required for per-request stop metadata; wrapper's metadata is fixed-at-call-time. Plan 08 extracts a named helper wrapping the same primitive; refactor is a mechanical rename."
    - "do_call returns {conn, stop_metadata} per :telemetry.span/3 contract; Plug.call/2 receives conn back as result"
    - "Rescue-by-struct for closed error hierarchies: three explicit rescue clauses for SignatureError/TenancyError/ConfigError in that order; no catch-all. Anything outside the three closed atom sets propagates."
    - "Forward-ref @compile {:no_warn_undefined, [Mailglass.Webhook.Ingest]} for Plan 06's ingest_multi/3; Mailglass.Tenancy.resolve_webhook_tenant/1 does not need the directive because the dispatcher is fully resident"
    - "Tenancy.with_tenant/2 block form wraps normalize + ingest body — cleanup on raise via try/after (Pitfall 7 discipline)"
    - "@valid_providers [:postmark, :sendgrid] checked in init/1 — invalid providers fail at router-mount time, not request time"
    - "Post-commit broadcast pattern matches Plan 06's 3-tuple contract: {event, delivery_or_nil, orphan?}; orphans skipped (Plan 07 Reconciler handles later)"

key-files:
  created:
    - "lib/mailglass/webhook/plug.ex"
    - "test/mailglass/webhook/plug_test.exs"
  modified:
    - "lib/mailglass/errors/tenancy_error.ex (added :webhook_tenant_unresolved atom + format_message/2 clause + @type t + moduledoc)"
    - "lib/mailglass/tenancy.ex (added resolve_webhook_tenant/1 dispatcher stub with function_exported? fallback returning {:ok, \"default\"})"

key-decisions:
  - "Direct :telemetry.span/3 over Mailglass.Telemetry.span/3 wrapper — the wrapper's metadata is fixed at call time and cannot carry per-request enrichment (status, failure_reason, event_count). CONTEXT D-22 explicitly permits this: 'Plan 08 ships the helpers; this plan calls them directly via :telemetry.span/3 if helpers absent.' Plan 08 extracts Mailglass.Webhook.Telemetry.ingest_span/2 as a mechanical rename."
  - "do_call returns {conn, stop_metadata} — matches :telemetry.span/3's required tuple shape directly. Plug.call/2 receives the conn (first element) back as the span's return value. Stop metadata lands on the :stop event."
  - "Response atom set for stop metadata: :ok, :duplicate, :signature_failed, :tenant_unresolved, :config_error, :ingest_failed, :pending (start event only). Each maps to a distinct HTTP status and a distinct Logger discipline."
  - "conn.private[:raw_body] nil raises %ConfigError{:webhook_caching_body_reader_missing} — the distinct B4 atom (vs :webhook_verification_key_missing). Adopter-side Grafana/log alerts can differentiate plug-wiring gaps from missing provider secrets without regex-parsing messages."
  - "init/1 raises ArgumentError (not %ConfigError{}) on unknown :provider — fails at router-mount time when the adopter's endpoint.ex boots. No request ever reaches an invalid provider route."
  - "Mailglass.Tenancy.resolve_webhook_tenant/1 uses function_exported?/3 fallback — returns {:ok, \"default\"} when the resolver module has no impl. This keeps SingleTenant functional at this plan's ship time (before Plan 05's @optional_callback declaration) while allowing adopter tenancy modules to override. Plan 05 will tighten to {:error, :resolver_incomplete} once the callback is formally declared."
  - "TenancyError :webhook_tenant_unresolved format_message/2 takes context[:provider] for the display string; the atom itself is the durable API contract (tests pattern-match err.type, not err.message)."
  - "Post-commit broadcast skips orphan events ({_event, nil, true} 3-tuple clause) — Plan 07's Reconciler later emits :reconciled when the matching Delivery surfaces; broadcasting twice would confuse LiveView subscribers."
  - "Tests tagged @tag :requires_plan_06 for happy-path 200 (the Wave 3 ingest_multi/3 forward-ref). All failure-mode tests (401, 422, 500) exercise paths BEFORE the ingest call site and pass independent of Plan 06."
  - "Test stubs use in-module defmodule UnresolvedTenancy inside a describe block — keeps the stub colocated with its single usage and avoids polluting the shared support directory. Pattern matches Plan 04-02's approach."

patterns-established:
  - "Single-ingress plug orchestration: extract → verify → resolve_tenant → with_tenant → normalize → ingest → broadcast → respond. Each step is a single defp with single responsibility; rescue-by-struct at the outer boundary."
  - "Three-tier rescue hierarchy for closed error atom sets: SignatureError (401) → TenancyError (422) → ConfigError (500). No message-string inspection; no catch-all. Anything outside the three propagates."
  - "Two-level telemetry nesting: outer [:mailglass, :webhook, :ingest, *] wraps the entire plug call; inner [:mailglass, :webhook, :signature, :verify, *] wraps Provider.verify!/3. Outer always emits :start + :stop (or :start + :exception on fatal); inner emits :exception on verify failure which the outer then catches and classifies."
  - "Logger.warning format discipline: one-line, template-based, atom-only interpolations. Tests assert ABSENCE of source IP, credentials, body content in log output via refute log =~ <value> (T-04-04 mitigation)."
  - "Post-commit broadcast loop over events_with_deliveries 3-tuples: skip orphans ({_event, nil, true}), broadcast for matched ({event, delivery, false}). Contract defined for Plan 06 to fulfill."

requirements-completed: [HOOK-02]

# Metrics
duration: 13min
completed: 2026-04-23
---

# Phase 4 Plan 4: Webhook Ingest Wave 2A — Single-Ingress Plug Summary

**`Mailglass.Webhook.Plug` ships the throat of Phase 4: a single `@behaviour Plug` module that extracts raw bytes from `conn.private[:raw_body]`, dispatches to the sealed `Mailglass.Webhook.Provider` contract, rescues by struct for a closed 4-outcome response matrix (200/401/422/500), emits two telemetry spans with whitelist-compliant metadata, and hands off to the forward-declared `Mailglass.Webhook.Ingest.ingest_multi/3` (Plan 06). Preconditions added: `TenancyError :webhook_tenant_unresolved` atom + `Tenancy.resolve_webhook_tenant/1` dispatcher stub.**

## Performance

- **Duration:** ~13 min
- **Started:** 2026-04-23T21:20:11Z
- **Completed:** 2026-04-23T21:33:01Z
- **Tasks:** 2 (plus 1 deviation-fix commit for the telemetry-wrapper return-shape mismatch)
- **Commits:** 3 task/fix commits (plus 1 metadata commit after this SUMMARY lands)
- **Files created:** 2
- **Files modified:** 2

## Accomplishments

- **`Mailglass.Webhook.Plug` (`lib/mailglass/webhook/plug.ex`, 356 lines):** Implements `@behaviour Plug` with `init/1` + `call/2`. `init/1` validates `:provider in [:postmark, :sendgrid]` at compile/mount time (raises `ArgumentError` for unknown providers — fails at router-mount, not request-time). `call/2` wraps `do_call/3` in `:telemetry.span/3` directly; `do_call/3` runs the 9-step orchestration per CONTEXT D-10:
  1. `extract_headers_and_raw_body!/1` — reads `conn.private[:raw_body]`, raises `%ConfigError{:webhook_caching_body_reader_missing}` if nil (B4 distinct atom — adopters can differentiate plug-wiring gaps from missing secrets via atom grep)
  2. `resolve_config!/2` — per-provider config resolution (Postmark `:basic_auth` + `:ip_allowlist`; SendGrid `:public_key` + `:timestamp_tolerance_seconds`); passes `conn.remote_ip` through to Postmark for IP allowlist enforcement
  3. `verify_with_telemetry!/4` — inner `:telemetry.span/3` around `Provider.verify!/3`; raises `%SignatureError{}` on failure
  4. `resolve_tenant!/4` — delegates to `Mailglass.Tenancy.resolve_webhook_tenant/1` (D-12); raises `%TenancyError{:webhook_tenant_unresolved}` on `{:error, _}`
  5. `Tenancy.with_tenant/2` block form (Pitfall 7 — cleanup on raise) wraps normalize + ingest
  6. `Provider.normalize/2` — pure; returns `[%Event{}]`
  7. `Mailglass.Webhook.Ingest.ingest_multi/3` — forward-declared (Plan 06); silenced by `@compile {:no_warn_undefined, [Mailglass.Webhook.Ingest]}`
  8. `broadcast_post_commit/1` — iterates Plan 06's `events_with_deliveries` 3-tuples (`{event, delivery, orphan?}`); skips orphans (Plan 07 Reconciler handles later), broadcasts via `Projector.broadcast_delivery_updated/3` for matched tuples
  9. `send_resp(conn, 200, "")` (or 200 duplicate replay; or 500 on ingest failure)
- **Response code matrix per CONTEXT D-10 + D-14 + D-21:** 200 success/duplicate, 401 `%SignatureError{}` (all 7+ atoms), 422 `%TenancyError{:webhook_tenant_unresolved}`, 500 `%ConfigError{}` (both `:webhook_caching_body_reader_missing` and `:webhook_verification_key_missing`) + 500 ingest failure. Three explicit rescue clauses; no catch-all; no message-string inspection.
- **Telemetry:** Outer span `[:mailglass, :webhook, :ingest, :start | :stop | :exception]` fires on every `call/2` with per-request stop metadata (`provider`, `tenant_id`, `status`, `failure_reason`, `event_count`, `duplicate`). Inner span `[:mailglass, :webhook, :signature, :verify, :start | :stop | :exception]` wraps `Provider.verify!/3`. Metadata complies with D-23 whitelist — no `:ip`, `:user_agent`, `:remote_ip`, `:raw_body`, `:headers`, `:body`.
- **Logger discipline (D-24):** `Logger.warning` on signature/tenant failure uses a fixed template `"Webhook signature failed: provider=#{provider} reason=#{e.type}"` — atoms only; no source IP, no headers, no payload bytes, no credential values. `Logger.error` on config failure logs the atom type + brand-voiced `Exception.message/1`. Tests assert absence of `127.0.0.1`, body content, and credential values in log output via `refute log =~ ...` (T-04-04 mitigation verified).
- **`Mailglass.TenancyError` extension:** `:webhook_tenant_unresolved` atom added to `@types` list (closed set now `[:unstamped, :webhook_tenant_unresolved]`) with brand-voiced `format_message/2` clause that reads `context[:provider]`. The `@type t :: %__MODULE__{type: ...}` union extended. Moduledoc updated with the D-14 reasoning. Plan 05 formalizes the `docs/api_stability.md §Tenancy` lock + the `@optional_callback resolve_webhook_tenant/1` declaration.
- **`Mailglass.Tenancy.resolve_webhook_tenant/1` dispatcher stub:** New public function delegates to the configured resolver's `resolve_webhook_tenant/1` impl via `function_exported?/3`; falls back to `{:ok, "default"}` when the module does not declare the callback. This keeps `SingleTenant` functional at Plan 04-04's ship time (before Plan 05's `@optional_callback` landing) and gives adopter tenancy modules a hook point. Plan 05 tightens the fallback to `{:error, :resolver_incomplete}` once the callback is formal.
- **Test coverage (12 tests, 0 failures):** 6 describe blocks in `test/mailglass/webhook/plug_test.exs`:
  - `init/1` — 4 tests (valid :postmark, valid :sendgrid, unknown provider, missing :provider)
  - `call/2 401 signature failure` — 3 tests (Postmark Basic Auth mismatch with Logger PII-free discipline; SendGrid bit-flipped body; SendGrid missing signature header)
  - `call/2 422 tenant unresolved` — 1 test (in-module `UnresolvedTenancy` stub returning `{:error, :no_tenant_match}`; asserts Logger format + PII discipline)
  - `call/2 500 config errors` — 2 tests (missing CachingBodyReader; missing Postmark basic_auth config — each asserts the distinct `%ConfigError{}` atom in the log)
  - `call/2 telemetry` — 1 test (exercises the 401 path since happy-path requires Plan 06; asserts both `:start` + `:stop` fire; asserts D-23 whitelist compliance by `refute Map.has_key?` for all 6 forbidden PII keys)
  - `Mailglass.Tenancy.resolve_webhook_tenant/1 dispatcher stub` — 1 test (SingleTenant → `{:ok, "default"}`)

## Task Commits

Each task was committed atomically; an additional deviation-fix commit was split off when `plug_test.exs` first runs caught the telemetry-wrapper return-shape mismatch:

1. **Task 1: `Mailglass.Webhook.Plug` + TenancyError atom + Tenancy dispatcher stub** — `de5ec28` (feat) — 3 files, 400 insertions, 2 deletions. Core single-ingress orchestrator + both preconditions needed for the Plug to compile and rescue at the right HTTP status.
2. **Deviation fix: use `:telemetry.span/3` directly in `Plug.call/2`** — `4dcb29a` (fix — Rule 1 bug) — 1 file, 13 insertions, 1 deletion. `Mailglass.Telemetry.span/3` wraps the inner function's return as `{result, metadata}` with FIXED metadata; returning `{conn, stop_meta}` from the inner function caused `call/2` to receive `{conn, stop_meta}` back as a 2-tuple where `%Plug.Conn{}` was required. The fix calls `:telemetry.span/3` directly (explicitly permitted by CONTEXT D-22 line 161 — "Plan 08 ships the helpers; this plan calls them directly via `:telemetry.span/3` if helpers absent"). Plan 08's helper extraction is a mechanical rename.
3. **Task 2: Plug integration tests (12 tests / 6 describe blocks)** — `7d61fc7` (test) — 1 file, 320 insertions.

**Plan metadata:** _pending final commit after SUMMARY.md + STATE.md + ROADMAP.md updates_.

## Files Created/Modified

### Created

- `lib/mailglass/webhook/plug.ex` — 356-line single-ingress orchestrator with `@behaviour Plug`, `@valid_providers [:postmark, :sendgrid]`, outer/inner telemetry spans, 3-tier rescue (SignatureError/TenancyError/ConfigError), `broadcast_post_commit/1` for Plan 06 contract, `@compile {:no_warn_undefined, [Mailglass.Webhook.Ingest]}` for Plan 06 forward-ref
- `test/mailglass/webhook/plug_test.exs` — 320-line integration test file; 12 tests / 6 describe blocks; uses `use Mailglass.WebhookCase, async: false`; module-qualified fixture loaders and conn builder per Plan 04-02's documented workaround for the `using opts do` import-propagation issue

### Modified

- `lib/mailglass/errors/tenancy_error.ex` — `:webhook_tenant_unresolved` added to `@types` (closed set now 2 atoms); new `format_message/2` clause reads `context[:provider]`; `@type t` union updated; moduledoc gains an 8-line explanation of the D-14 atom with forward-reference to Plan 05's `docs/api_stability.md §Tenancy` lock
- `lib/mailglass/tenancy.ex` — new public function `resolve_webhook_tenant/1` (31-line doc + 9-line impl) dispatches to the configured resolver's `resolve_webhook_tenant/1` callback via `function_exported?/3`; falls back to `{:ok, "default"}` when the module has no impl; doc references CONTEXT D-12 context shape + forward-references Plan 05's `@optional_callback` formalization

## Decisions Made

- **Direct `:telemetry.span/3` call over `Mailglass.Telemetry.span/3` wrapper** — the wrapper's metadata is closed at call time (`def span(prefix, metadata, fun) do :telemetry.span(prefix, metadata, fn -> {fun.(), metadata} end)`) and the `:stop` event always carries the INPUT metadata, not an enriched per-request map. Per-request stop metadata (`status`, `failure_reason`, `event_count`, `duplicate`) is the whole point of the outer ingest span. CONTEXT D-22 line 161 explicitly permits the direct call when helpers are absent; Plan 08 extracts `Mailglass.Webhook.Telemetry.ingest_span/2` wrapping the same primitive — the refactor is a mechanical rename. D-27 handler isolation is preserved because `:telemetry.span/3` itself wraps handlers in try/catch.
- **`do_call/3` returns `{conn, stop_metadata}`** — matches `:telemetry.span/3`'s tuple contract exactly. `Plug.call/2` receives `conn` (first tuple element) back as the span's return value. All 4 response-code branches (200 success, 200 duplicate, 401, 422, 500 config, 500 ingest) return this shape.
- **`@valid_providers [:postmark, :sendgrid]` at compile-time in `init/1`** — unknown providers raise `ArgumentError` (NOT `%ConfigError{}`) at router-mount time, which crashes the adopter's `endpoint.ex` boot. Request-time validation would produce 500s against live traffic; compile-time validation is strictly better for misconfiguration discovery. Plan 05's router macro will inherit this — adopters can't mount a bogus provider route.
- **`conn.private[:raw_body]` nil → `%ConfigError{:webhook_caching_body_reader_missing}`** — distinct B4 atom (not `:webhook_verification_key_missing`). Adopter logs can `grep 'reason=webhook_caching_body_reader_missing'` to find plug-wiring gaps without regex-parsing the human-readable message. Grafana / Splunk / Datadog alerts key off the atom.
- **`Mailglass.Tenancy.resolve_webhook_tenant/1` fallback returns `{:ok, "default"}`** — keeps `SingleTenant` functional at Plan 04-04's ship time before Plan 05's `@optional_callback` declaration. Adopters who implement the callback on their own tenancy module override the fallback. Plan 05 can later tighten to `{:error, :resolver_incomplete}` once the callback is formal.
- **Post-commit broadcast skips orphan events** — Plan 06's `events_with_deliveries` is a list of `{event, delivery_or_nil, orphan?}` 3-tuples. Orphans (delivery is `nil`, `orphan?` is `true`) have nothing to broadcast against; Plan 07's Reconciler later emits a `:reconciled` event when the matching Delivery surfaces. Broadcasting twice would confuse LiveView subscribers. The 3-tuple pattern match is exhaustive for the Plan 06 contract — unexpected shapes propagate as MatchError (fail-loud).
- **Tests use in-module `defmodule UnresolvedTenancy`** — keeps the 422 test's stub colocated with its single usage; no shared support file pollution. Pattern matches Plan 04-02's approach (Deviation #3 documented the same strategy for avoiding ExUnit.CaseTemplate `using` block import fragility).
- **Happy-path 200 tests `@tag :requires_plan_06`** — the Plug calls `Mailglass.Webhook.Ingest.ingest_multi/3` which Plan 06 ships. Running that call at test time hits `UndefinedFunctionError` which propagates past the 3-tier rescue (SignatureError/TenancyError/ConfigError). All failure-mode tests exercise paths BEFORE the ingest call site, so they pass independent of Plan 06. Plan 06 / Plan 09 UAT re-run end-to-end.
- **Telemetry test exercises the 401 path, not the ingest path** — `:start` + `:stop` both fire on the outer span even when the inner `verify!/3` raises. This proves the span pair is complete + the D-23 metadata whitelist is respected without requiring Plan 06. A Plan 06 test will exercise the happy-path `:stop` metadata shape (`duplicate: false, event_count: N`).
- **Module-qualified fixture calls in tests** — per Plan 04-02's documented workaround for the `ExUnit.CaseTemplate using opts do` block's `import` directives failing to propagate through nested `use Mailglass.MailerCase`. `Mailglass.WebhookFixtures.load_postmark_fixture/1` and `Mailglass.WebhookCase.mailglass_webhook_conn/2` are called module-qualified. Plan 04-05 or a later plan can debug the CaseTemplate chain.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] `Mailglass.Telemetry.span/3` wrapper returns a tuple shape incompatible with Plug.call/2**

- **Found during:** Task 2 first test run — 6 tests (including `init/1` cases) surfaced `(BadMapError) expected a map, got: {%Plug.Conn{...}, %{status: :signature_failed, ...}}` when `Plug.Test.call` tried to treat the return value as a `%Plug.Conn{}`.
- **Issue:** The plan's skeleton called `Mailglass.Telemetry.span/3` from `Plug.call/2`. But that wrapper's implementation is `:telemetry.span(prefix, metadata, fn -> {fun.(), metadata} end)` — it closes the stop metadata at call time and wraps the inner function's return in a tuple with THAT metadata. When `do_call/3` returns `{conn, per_request_meta}`, the wrapper feeds `{{conn, per_request_meta}, call_time_meta}` into `:telemetry.span/3`, which extracts the first element → returning `{conn, per_request_meta}` back to `Plug.call/2`. Plug.call/2 must return `%Plug.Conn{}`, not a 2-tuple.
- **Fix:** Call `:telemetry.span/3` directly from `Plug.call/2` (explicitly permitted by CONTEXT D-22 line 161). `do_call/3` returns `{conn, stop_metadata}` per the raw `:telemetry.span/3` contract; the conn (first element) lands back in `Plug.call/2` as the return value. Enriched per-request metadata correctly attaches to the `:stop` event. Plan 08's helper extraction wraps the same primitive as a mechanical rename — no behavioural change.
- **Files modified:** `lib/mailglass/webhook/plug.ex` (6 lines changed — 1 function call swap + 5 lines of inline comment explaining the deviation and pointing at Plan 08's refactor plan)
- **Verification:** `mix test test/mailglass/webhook/plug_test.exs` → 12 tests, 0 failures (was 6 failures before). All 12 tests pass, including the telemetry test that asserts both `:start` and `:stop` fire with metadata compliant with the D-23 whitelist.
- **Committed in:** `4dcb29a` (separate fix commit — distinguished from Task 1's feat and Task 2's test commits)

---

**Total deviations:** 1 auto-fixed (Rule 1 bug).

**Impact on plan:** The plan's `<interfaces>` block (line 140 of `04-04-PLAN.md`) showed `Mailglass.Webhook.Telemetry.ingest_span(%{...}, fn -> ...`) which would be Plan 08's eventual named helper; CONTEXT D-22 line 161 explicitly authorizes falling through to `:telemetry.span/3` when Plan 08's helpers are absent. The plan's body text described using `Mailglass.Telemetry.span/3` (the Phase 1 wrapper); that wrapper's closed-metadata surface is incompatible with per-request stop enrichment. The deviation corrects the integration without changing any public contract — Plan 08 still owns the helper extraction.

## Threat Flags

None. The threat surface introduced by Plan 04-04 matches the plan's `<threat_model>` exactly:

- **T-04-04 (Info Disclosure)** — mitigated by Logger template hardcoded to `provider=<atom> reason=<atom>`; telemetry metadata enforced via D-23 whitelist. Test assertions (`refute log =~ "127.0.0.1"`, `refute log =~ body`, `refute log =~ "wrong_user"`) verify no IP, credentials, or body content leak into Logger output. Telemetry test asserts `refute Map.has_key?(meta, :ip | :user_agent | :remote_ip | :raw_body | :headers | :body)` across both `:start` and `:stop` meta maps.
- **T-04-05 (DoS)** — not directly mitigated in this module; adopter-side `Plug.Parsers :length: 10_000_000` is the contract (documented in `guides/webhooks.md` per Plan 09). Plan 06's statement_timeout wrapper bounds DB query latency. This plan contributes the "fail-fast on missing `conn.private[:raw_body]`" check, which prevents adopters from silently running downstream code without the 10 MB cap in place.
- **T-04-06 (Cross-tenant data leak)** — mitigated by `Tenancy.with_tenant/2` block form; `put_current/1` never called directly. Verified by `grep -c "Tenancy.put_current" lib/mailglass/webhook/plug.ex` returning 0.

## Issues Encountered

- **Full-suite run shows ~43 pre-existing failures** — all `ERROR XX000 (internal_error) cache lookup failed for type 780833` from citext OID staleness after `migration_test.exs`'s down/up round-trip. Documented in `.planning/phases/02-persistence-tenancy/deferred-items.md` with 4 Phase 6 candidate fixes. Webhook tests in isolation (`mix test test/mailglass/webhook/`) all pass 79/0; error_test.exs + errors/ + tenancy/ subtrees all pass. Not a Plan 04-04 regression.
- **`mix verify.phase_04` requires `MIX_ENV=test`** — matches Plan 04-01 / 04-02 / 04-03 behaviour; documented in each prior SUMMARY file. Local invocation: `POSTGRES_USER=jon POSTGRES_PASSWORD='' MIX_ENV=test mix verify.phase_04`.
- **No UAT tests yet** — Wave 2A is still library-only; first `:phase_04_uat`-tagged tests ship in Plan 09 (Wave 4). `mix verify.phase_04` reports 0/0 — the correct Wave 2 state.

## User Setup Required

None. Phase 4 Wave 2A is library-only code. Adopter-facing config is unchanged from Wave 1B (the Plug reads the `:postmark` + `:sendgrid` + `:tenancy` Application env trees installed by Plans 04-02 + 04-03).

## Next Phase Readiness

Plan 04-04 closes Wave 2A and unblocks every remaining Phase 4 plan:

- **Plan 05 (Router macro + Tenancy formalization)** — can mount `Mailglass.Webhook.Plug` at provider-specific paths via a `Mailglass.Webhook.Router` macro. The Plug's `init/1` already validates `:provider` — the macro just passes the atom through. Plan 05 also formalizes `@optional_callback resolve_webhook_tenant/1` on `Mailglass.Tenancy`, replaces the dispatcher's `function_exported?` fallback with a `@moduledoc`-documented contract, and adds the `SingleTenant.resolve_webhook_tenant/1` concrete impl + `docs/api_stability.md §Tenancy` lock.
- **Plan 06 (Ingest Multi)** — ships `Mailglass.Webhook.Ingest.ingest_multi/3` returning `{:ok, %{webhook_event: ..., duplicate: boolean, events_with_deliveries: [{event, delivery_or_nil, orphan?}, ...], orphan_event_count: int}}`. The Plug's `ingest_and_respond/5` already pattern-matches this shape; Plan 06's `finalize_changes/2` just needs to produce the right map keys. The duplicate-replay 200 path is already covered by the Plug — Plan 06's tests can focus on the Multi semantics.
- **Plan 07 (Reconciler)** — will emit `:reconciled` events for orphans that the Plug skipped during post-commit broadcast. The Plug's `{_event, nil, true} -> :ok` clause is the foundation for this — orphans are knowingly deferred, not silently dropped.
- **Plan 08 (Telemetry helpers)** — extracts `Mailglass.Webhook.Telemetry.ingest_span/2` wrapping `:telemetry.span/3`. The Plug's two direct `:telemetry.span/3` calls become mechanical renames to `Webhook.Telemetry.ingest_span/2` + `Webhook.Telemetry.verify_span/2` — no behavioural change, no test regressions.
- **Plan 09 (UAT + property tests)** — can now exercise the full end-to-end path (CachingBodyReader → Plug → verify → resolve_tenant → with_tenant → normalize → ingest → broadcast → respond) once Plan 05 + 06 + 07 land. The `requires_plan_06` tests in this plan's test file become green at that point.

**Blockers or concerns:** None. Pre-existing citext OID flakiness remains Phase 6 deferred.

**Phase 4 progress:** 4 of 9 plans complete.

## Self-Check: PASSED

Verified:

- `lib/mailglass/webhook/plug.ex` — FOUND (356 lines)
- `test/mailglass/webhook/plug_test.exs` — FOUND (320 lines)
- `lib/mailglass/errors/tenancy_error.ex` — modified (`:webhook_tenant_unresolved` atom + format_message clause present)
- `lib/mailglass/tenancy.ex` — modified (`resolve_webhook_tenant/1` dispatcher stub present)
- Commit `de5ec28` (Task 1 — Plug + TenancyError atom + Tenancy dispatcher) — FOUND in `git log`
- Commit `4dcb29a` (Deviation fix — telemetry.span/3 direct call) — FOUND
- Commit `7d61fc7` (Task 2 — Plug integration tests) — FOUND
- `mix compile --warnings-as-errors --no-optional-deps` — exits 0
- `mix test test/mailglass/webhook/plug_test.exs --warnings-as-errors --exclude requires_plan_06` — 12 tests, 0 failures
- `mix test test/mailglass/webhook/ --warnings-as-errors --exclude requires_plan_06 --exclude flaky` — 79 tests, 0 failures
- `mix verify.phase_02` — 59 tests, 0 failures (518 excluded)
- `mix verify.phase_03` — 62 tests, 0 failures, 2 skipped (515 excluded)
- `mix verify.phase_04` — 0 tests, 0 failures (correct — Wave 2; Plan 09 ships first `:phase_04_uat`-tagged tests)
- `grep -q "@behaviour Plug" lib/mailglass/webhook/plug.ex` — exits 0
- `grep -c "Tenancy.put_current" lib/mailglass/webhook/plug.ex` — returns 0 (Pitfall 7 verified)
- `grep -E "send_resp\\(conn, (200|401|422|500)" lib/mailglass/webhook/plug.ex | wc -l` — returns 7 (all 4 response codes represented multiple times across success + duplicate + failure paths)
- `grep -E "e in (Mailglass\\.)?(SignatureError|TenancyError|ConfigError)" lib/mailglass/webhook/plug.ex | wc -l` — returns 3 (rescue-by-struct for all three closed hierarchies)

---
*Phase: 04-webhook-ingest*
*Completed: 2026-04-23*
