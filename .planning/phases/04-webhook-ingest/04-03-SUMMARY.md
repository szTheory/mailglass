---
phase: 04-webhook-ingest
plan: 03
subsystem: webhook
tags: [sendgrid, ecdsa, p256, public_key, otp27, anymail_taxonomy, nimble_options, timestamp_tolerance]

# Dependency graph
requires:
  - phase: 04-webhook-ingest
    plan: 01
    provides: ":public_key in extra_applications (release safety), Mailglass.WebhookCase + WebhookFixtures.generate_sendgrid_keypair/0 + sign_sendgrid_payload/3, 2 SendGrid fixture JSONs, Mailglass.Clock.utc_now/0"
  - phase: 04-webhook-ingest
    plan: 02
    provides: "Sealed Mailglass.Webhook.Provider @behaviour (verify!/3 + normalize/2), :postmark NimbleOptions sub-tree shape to mirror, extended SignatureError atom set (:missing_header, :malformed_header, :bad_signature, :timestamp_skew, :malformed_key), extended ConfigError :webhook_verification_key_missing"
provides:
  - "Mailglass.Webhook.Providers.SendGrid — ECDSA P-256 verifier + Anymail batch-array normalizer (HOOK-04 + HOOK-05 completion)"
  - ":sendgrid NimbleOptions sub-tree in Mailglass.Config (enabled, public_key, timestamp_tolerance_seconds)"
  - "32-test coverage across 4 describe blocks exercising verify!/3 + normalize/2 surface"
  - "Confirmed pattern: OTP 27 :public_key.der_decode(:SubjectPublicKeyInfo, _) returns already-decoded {:namedCurve, oid} in the AlgorithmIdentifier params slot — no second der_decode(:EcpkParameters, _) pass needed"
affects: [04-04, 04-05, 04-06, 04-07, 04-08, 04-09]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "OTP 27 ECDSA verify chain: Base.decode64! -> :public_key.der_decode(:SubjectPublicKeyInfo, _) -> {:AlgorithmIdentifier, _oid, params_tuple} -> {{:ECPoint, bits}, params} -> :public_key.verify(_, :sha256, _, _)"
    - "Pattern-match strictly on `true` — `false`, MatchError, ArgumentError, FunctionClauseError, ErlangError all collapse to %SignatureError{:bad_signature | :malformed_key, provider: :sendgrid}"
    - "Nested rescue with explicit SignatureError clause preserves inner-raised :bad_signature from reclassification by the catch-all"
    - "Pitfall 9 timestamp tolerance: Integer.parse/1 -> DateTime.from_unix/2 -> abs(DateTime.diff(Clock.utc_now(), sent_at, :second)) <= tolerance"
    - "Batch normalizer Enum.with_index/1 gives every event a unique provider_event_id fallback (sg_event_id -> smtp-id:idx -> sg_message_id:idx -> sendgrid_unknown_id:idx)"
    - "Provider identity in Event.metadata STRING keys (revision W9) — mirrors Postmark pattern shipped in Plan 04-02; ledger ceiling stays append-only pristine"
    - ":sendgrid NimbleOptions sub-tree shape matches :postmark (enabled + key material + optional tuning knob)"

key-files:
  created:
    - "lib/mailglass/webhook/providers/sendgrid.ex"
    - "test/mailglass/webhook/providers/sendgrid_test.exs"
  modified:
    - "lib/mailglass/config.ex (added :sendgrid keyword sub-tree alongside :postmark)"

key-decisions:
  - "OTP 27 :public_key.der_decode(:SubjectPublicKeyInfo, _) returns already-materialized params tuple in the AlgorithmIdentifier — no second der_decode(:EcpkParameters, _) pass needed. CONTEXT D-03's verbatim recipe was written against an earlier OTP release where :EcpkParameters came back as opaque DER bytes; Plan 04-03 discovers and documents the current behaviour. Rule 1 + Rule 3 deviation."
  - "Explicit SignatureError rescue clause BEFORE the catch-all rescue — the false branch of :public_key.verify/4 raises SignatureError with :bad_signature, which would otherwise be caught by the [ArgumentError, MatchError, FunctionClauseError, ErlangError] rescue and reclassified. The [SignatureError] clause reraises unchanged."
  - "Bad base64 on EITHER the public_key blob OR the signature maps to :malformed_key. Base.decode64! ArgumentError does not distinguish the source from the message alone, and :malformed_key is the safer disclosure (never leaks `your signature was wrong` to a forged request). The bit-flipped signature test accepts `err.type in [:bad_signature, :malformed_key]` — both are correct fail-closed behavior."
  - "Timestamp tolerance uses Mailglass.Clock.utc_now/0 NOT DateTime.utc_now/0 per Pitfall 9 / LINT-12 discipline. Test-time freezing via Mailglass.Clock.Frozen.freeze/1 is available but unused — tolerance tests exercise real wall-clock deltas (System.system_time(:second) - 250 / -600 / -120) which is simpler and proves the real Clock.utc_now/0 path."
  - "16 defp map_event/1 clauses (plan required ≥12). Exhaustive: processed, deferred, delivered, open, click, bounce (3 type variants + fallthrough), dropped (5 reason variants + fallthrough), spamreport, unsubscribe, group_unsubscribe, group_resubscribe, `event -> other` fallthrough, non-map fallthrough — each fallthrough emits Logger.warning NEVER a silent catch-all to a non-:unknown atom (D-05)."
  - "provider_event_id extraction fallback chain sg_event_id (canonical) -> smtp-id+idx -> sg_message_id+idx -> `sendgrid_unknown_id:idx` — ensures UNIQUE(provider, provider_event_id) on mailglass_webhook_events (V02) never silently collides even on malformed SendGrid payloads."
  - "Non-map element in the events array gets a synthetic :unknown Event with provider_event_id = `sendgrid_invalid_element:idx` — preserves batch-level count semantics; Plan 06 Ingest will still insert it (the Reconciler can later link if a matching Delivery surfaces, though in practice this path should be unreachable)."
  - "SendGrid processed -> :queued interpretation: SendGrid's `processed` state means `SendGrid has received the message and will attempt to deliver it` which maps cleanly to Anymail's `:queued` (provider has accepted for later delivery). Not `:sent` which would imply the upstream SMTP handshake completed."
  - "`enabled: true` default for :sendgrid matches :postmark shape — the router macro (Plan 04-04) wires the route without explicit opt-in; adopters disable a provider by setting `enabled: false` OR by omitting it from the `:providers` list passed to `mailglass_webhook_routes/2`."

patterns-established:
  - "Two-provider parity: :postmark + :sendgrid NimbleOptions sub-trees share shape (enabled flag + key material + provider-specific tuning knob). v0.5's Mailgun/SES/Resend follow the same convention."
  - "Nested rescue for multi-layered crypto errors: explicit same-type clause first (preserve internal raises), catch-all heuristic second (classify base64 vs DER vs EC math)"
  - "OTP 27 `:public_key` SPKI decode — AlgorithmIdentifier params arrive materialized, NOT as opaque DER bytes"
  - "Test-signing parity: production verifier (:public_key.verify) + fixture signer (:crypto.sign) roundtrip verified against freshly-minted per-test keypair; no shared fixtures with baked-in signatures (Pitfall 10)"

requirements-completed: [HOOK-04, HOOK-05]

# Metrics
duration: 9min
completed: 2026-04-23
---

# Phase 4 Plan 3: Webhook Ingest Wave 1B — SendGrid verifier + normalizer + :sendgrid config Summary

**SendGrid Event Webhook verifier (ECDSA P-256 over `timestamp <> raw_body`) + exhaustive Anymail batch normalizer (1..128 events per request) + :sendgrid NimbleOptions sub-tree — HOOK-04 + HOOK-05 now fully green; the Plan 04 Plug (Wave 2) can dispatch to both Postmark and SendGrid through the sealed Mailglass.Webhook.Provider contract.**

## Performance

- **Duration:** ~9 min
- **Started:** 2026-04-23T20:58:27Z
- **Completed:** 2026-04-23T21:06:59Z
- **Tasks:** 2 (plus 1 deviation-fix commit for OTP 27 der_decode behaviour)
- **Commits:** 3 task/fix commits (plus 1 metadata commit after this SUMMARY lands)
- **Files created:** 2
- **Files modified:** 1

## Accomplishments

- **SendGrid Provider (`lib/mailglass/webhook/providers/sendgrid.ex`):** Implements `@behaviour Mailglass.Webhook.Provider`. `verify!/3` runs the ECDSA P-256 chain per CONTEXT D-03 using OTP 27 `:public_key.der_decode/2` (NOT `:pem_decode/1` per Pitfall 1) + `:public_key.verify/4`. Pattern-matches strictly on `true` — `false`, MatchError, ArgumentError, FunctionClauseError, ErlangError all collapse to `%SignatureError{type: :bad_signature | :malformed_key, provider: :sendgrid}` (closes the "wrong algo silently returns false" footgun). 300s timestamp tolerance enforced via `Mailglass.Clock.utc_now/0` (Pitfall 9 discipline — parses string Unix int via `Integer.parse/1 |> DateTime.from_unix/2`). `normalize/2` decodes the JSON array (1..128 events per request) and maps each event via 16 explicit `defp map_event/1` clauses to Anymail atoms verbatim; unmapped falls through to `:unknown` + `Logger.warning` (NEVER silent catch-all per D-05).
- **:sendgrid NimbleOptions sub-tree (`lib/mailglass/config.ex`):** Additive schema entry alongside `:postmark` with `enabled: true` default, `public_key: nil` default (base64 SPKI DER — not PEM), `timestamp_tolerance_seconds: 300` default. Mirrors `:postmark` shape — one consistent config surface across mailglass providers.
- **Test coverage (32 tests, 0 failures):** 4 describe blocks. 2 happy-path tests (single event + batch of 5 — both roundtrip-sign-then-verify against the per-test P-256 keypair). 7 failure-mode tests (missing signature/timestamp headers, bit-flipped body, bit-flipped signature, malformed timestamp string, missing public_key config → `%ConfigError{}`, malformed base64 public_key). 3 timestamp-tolerance tests (within default 300s, beyond default, custom 60s config). 20 normalize/2 tests covering the 12 explicit Anymail mappings + fallthroughs (bounce/dropped subtypes, unmapped event, malformed JSON, non-array root) + provider_event_id fallback chain + STRING-keys-in-metadata revision-W9 assertion.
- **Two-provider parity:** Postmark + SendGrid now both implement `Mailglass.Webhook.Provider` with zero conn leakage. Plan 04-04's Plug can dispatch via a `case provider do :postmark -> ... ; :sendgrid -> ... end` exhaustive match; there is no third provider at v0.1 (Mailgun/SES/Resend deferred to v0.5 per PROJECT D-10).

## Task Commits

Each task was committed atomically (plus a separate fix commit for the OTP 27 discovery):

1. **Task 1: SendGrid provider module + :sendgrid NimbleOptions sub-tree** — `f3c48e5` (feat) — 2 files, 329 insertions.
2. **Deviation fix: OTP 27 `:EcpkParameters` second der_decode pass is wrong** — `9ab8bcc` (fix — Rule 1 + Rule 3) — 1 file, 15 insertions, 5 deletions.
3. **Task 2: SendGrid provider test suite (32 tests / 4 describe blocks)** — `996510a` (feat) — 1 file, 417 insertions.

**Plan metadata:** _pending final commit after SUMMARY.md + STATE.md + ROADMAP.md updates_.

## Files Created/Modified

### Created

- `lib/mailglass/webhook/providers/sendgrid.ex` — ECDSA P-256 verifier + Anymail batch-array normalizer + provider_event_id fallback chain + 16-clause exhaustive event mapping
- `test/mailglass/webhook/providers/sendgrid_test.exs` — 32 tests across 4 describe blocks covering verify!/3 happy path, verify!/3 failure modes, verify!/3 timestamp tolerance, normalize/2 Anymail mapping

### Modified

- `lib/mailglass/config.ex` — `:sendgrid` keyword sub-tree added to `@schema` between `:postmark` and the trailing bracket; shape matches `:postmark` (enabled + key material + tuning knob)

## Decisions Made

- **OTP 27 `:public_key` SPKI decoding: `AlgorithmIdentifier` params arrive already materialized.** The plan's verbatim recipe (quoted from CONTEXT D-03) called for a second `:public_key.der_decode(:EcpkParameters, ec_params_der)` pass after destructuring the AlgorithmIdentifier. Running this against freshly-generated P-256 keypairs showed that OTP 27's `:public_key.der_decode(:SubjectPublicKeyInfo, _)` ALREADY decodes the params slot — element 3 of the AlgorithmIdentifier tuple comes back as `{:namedCurve, {1,2,840,10045,3,1,7}}` directly, NOT raw DER bytes. The second decode call raises inside `:public_key` (observed in OTP 27.3.x / public_key 1.20.2). The fix is to use the params tuple directly: `{:AlgorithmIdentifier, _oid, ecc_params} = alg_id` then `pk = {{:ECPoint, pk_bits}, ecc_params}`. Documented inline with a comment citing the OTP-version-dependent behaviour. Rule 1 + Rule 3 deviation.
- **Explicit SignatureError rescue clause before the catch-all.** The `false` branch of `:public_key.verify/4` raises `%SignatureError{type: :bad_signature}`. Without the explicit `e in [SignatureError]` rescue clause, the subsequent `e in [ArgumentError, MatchError, FunctionClauseError, ErlangError]` catch-all would never match (SignatureError is not in that list), so the error would propagate unchanged. But when more error classes get added to the catch-all in future, the explicit SignatureError guard protects against accidental reclassification. Defense-in-depth.
- **Bad base64 → `:malformed_key` (not `:bad_signature`).** `Base.decode64!/1` raises `ArgumentError` for invalid input. It's called twice inside `verify_ecdsa!/4` — once on the public_key, once on the signature. The rescue classifier can't distinguish the source from the message alone (both say "non-alphabet characters"). Mapping both to `:malformed_key` is the safer disclosure posture: it never hints to a forgery attempt that the signature was wrong. Tests assert `err.type in [:bad_signature, :malformed_key]` for bit-flipped signature and bit-flipped base64 public_key — either classification is correct fail-closed behavior.
- **`processed` → `:queued` (mailglass interpretation).** SendGrid's `processed` state means "SendGrid has received the message and will attempt to delivery it to the MTA." Anymail's `:queued` is the semantic match ("provider has accepted for later delivery"). `:sent` would imply the upstream SMTP handshake completed, which is what `delivered` corresponds to. Documented in the moduledoc.
- **Non-map element in events array → synthetic `:unknown` Event.** JSON arrays could theoretically contain non-object elements (SendGrid never sends these, but defensive coding is Rule 2 territory). The fallthrough `build_event/2` clause emits `%Event{type: :unknown}` with `provider_event_id = "sendgrid_invalid_element:#{idx}"` — preserves batch-count semantics; Plan 06 Ingest will insert it and the Reconciler stays idle. Logger.warning explicitly notes the offending index.
- **Test file uses `System.system_time(:second)` deltas rather than `Clock.Frozen`.** The tolerance tests pass `ts_int = System.system_time(:second) - 250` / `-600` / `-120` directly to the signer. This exercises the real `Clock.utc_now/0` path without per-test setup overhead, proving that the default three-tier resolution (no freeze → System clock) is what ships in production. Clock.Frozen is still available via `freeze_timestamp/1` for future tests that need deterministic edge-case timestamps.
- **`enabled: true` default for :sendgrid matches :postmark.** Router macro (Plan 04-04) wires both routes by default. Adopters opt out by setting `enabled: false` OR by explicitly excluding from `:providers`. Mirrors the LiveDashboard + Oban Web convention.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug + Rule 3 — Blocking] OTP 27 `:public_key.der_decode/2` returns already-decoded params in AlgorithmIdentifier**

- **Found during:** First test run of Task 2 — 3 happy-path tests (2 verify-with-fixture + 1 tolerance-within-window) failed with `Mailglass.SignatureError: signature does not verify against the configured key`. Stack trace showed the failure at line 125 of sendgrid.ex: `:public_key.der_decode(:EcpkParameters, ec_params_der)`.
- **Issue:** CONTEXT D-03 specifies the verbatim verification chain as:
  ```elixir
  {:AlgorithmIdentifier, _oid, ec_params_der} = alg_id
  ecc_params = :public_key.der_decode(:EcpkParameters, ec_params_der)
  ```
  But running `:public_key.der_decode(:SubjectPublicKeyInfo, _)` on OTP 27 / public_key 1.20.2 against a keypair generated by `WebhookFixtures.generate_sendgrid_keypair/0` produces `{:AlgorithmIdentifier, {1, 2, 840, 10045, 2, 1}, {:namedCurve, {1, 2, 840, 10045, 3, 1, 7}}}` — the third element is ALREADY the materialized `{:namedCurve, oid}` tuple, not raw DER bytes. Forcing `der_decode/2` to parse this as `:EcpkParameters` raises inside `:public_key`, and our rescue classifier reclassified it as `:bad_signature`.
- **Fix:** Removed the redundant second `der_decode/2` call. New chain:
  ```elixir
  {:SubjectPublicKeyInfo, alg_id, pk_bits} = :public_key.der_decode(:SubjectPublicKeyInfo, decoded)
  {:AlgorithmIdentifier, _oid, ecc_params} = alg_id
  pk = {{:ECPoint, pk_bits}, ecc_params}
  ```
  Inline comment documents the OTP-version-dependent behaviour so future maintainers don't re-add the phantom decode pass. Also added an explicit `e in [SignatureError] -> reraise e, __STACKTRACE__` rescue clause before the catch-all so the `false`-branch `:bad_signature` raise is not reclassified.
- **Files modified:** `lib/mailglass/webhook/providers/sendgrid.ex` (the rescue clause addition and the EcpkParameters decode removal)
- **Verification:** `mix test test/mailglass/webhook/providers/sendgrid_test.exs` → 32 tests, 0 failures (was 29/3 before the fix). All 3 previously-failing happy-path tests now pass; all failure-mode tests still correctly raise.
- **Committed in:** `9ab8bcc` (separate fix commit — distinguished from Task 2's feat commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 + Rule 3 combo).

**Impact on plan:** Single deviation represents a live discovery against the CONTEXT D-03 recipe's OTP-version assumption — does NOT represent scope creep. The verbatim chain in D-03 was written with an older OTP release's `:public_key` behaviour in mind; OTP 27's `:public_key` module pre-decodes the AlgorithmIdentifier's params slot. The fix is one line (remove the second decode), plus a structural reorder of the rescue clauses. Plan's 8 acceptance criteria all still hold; the internal shape of the crypto chain is slightly different from the verbatim recipe.

## Threat Flags

None. The threat surface introduced by Plan 04-03 matches the plan's `<threat_model>` exactly:

- **T-04-01** (Spoofing) — mitigated by `:public_key.verify/4` with pattern-match-strictly-on-`true` discipline. Verified by 7 failure-mode tests all asserting closed-atom raises.
- **T-04-02** (Replay) — mitigated by 300s timestamp tolerance via `Clock.utc_now/0`. Verified by 3 tolerance-window tests.
- **T-04-03** (Body tampering) — mitigated by ECDSA signature over `timestamp <> raw_body` (raw bytes). Verified by the bit-flipped-body test with explicit single-word mutation.
- **T-04-04** (Info disclosure) — mitigated by atom-only error messages + `@derive {Jason.Encoder, only: [:type, :message, :context]}` on the SignatureError struct. Cause is captured for internal debugging but excluded from JSON. Verified by grep — no raw_body, sig_b64, public_key, or timestamp_str references in any format_message/raise path.

## Issues Encountered

- **OTP 27 der_decode behavioural drift vs CONTEXT D-03's verbatim recipe** — documented above as Deviation #1. The RESEARCH file's Pattern 2 (lines 244-280) and CONTEXT D-03 (lines 31-42) both quote the same recipe including the `:EcpkParameters` decode; future plans should update the reference text to match Plan 04-03's working chain (and note that the reference OTP version matters for `:public_key` DER shapes).
- **Pre-existing citext OID staleness continues to cause ~2 transient full-suite failures** on 20+ second runs — the `deliver_later_test.exs` file's 4 tests hit `ERROR XX000 (internal_error) cache lookup failed for type 634413` when `migration_test.exs` has run its down/up citext-dropping round-trip first. Tests pass in isolation. Tracked in `.planning/phases/02-persistence-tenancy/deferred-items.md` with 4 Phase 6 candidate fixes. Unchanged by this plan's work.
- **`verify.phase_04` requires MIX_ENV=test** — matches Plan 04-01 + Plan 04-02 behaviour; documented in those SUMMARY files.

## User Setup Required

None. Phase 4 Wave 1B is library-only code. Adopter-facing config shape (`config :mailglass, :sendgrid, public_key: "<base64-DER>", timestamp_tolerance_seconds: 300`) will be documented in `guides/webhooks.md` (Phase 7 DOCS-02).

## Next Phase Readiness

Plan 04-03 completes Wave 1B and unblocks every remaining Phase 4 plan:

- **Plan 04-04 (Webhook.Plug + Mailglass.Webhook.Router)** — can dispatch through the sealed `Mailglass.Webhook.Provider` contract via a `case provider do :postmark -> Postmark; :sendgrid -> SendGrid end` exhaustive match. Both providers now implement `verify!/3` + `normalize/2` with identical signatures; the Plug is the conn-to-tuple adapter (D-02) and does not need provider-specific code paths.
- **Plan 04-05 (SignatureError api_stability.md lock)** — the SignatureError atom set is now proven across BOTH providers' runtime raise paths. Plan 05 can consolidate the 10 atoms down to 7 (remove legacy `:missing`, `:malformed`, `:mismatch`) by migrating the Phase 1 reference sites identified in Plan 04-02's SUMMARY.
- **Plan 04-06 (Ingest Multi)** — will read `Event.metadata["provider"]` (string "sendgrid" or "postmark") and `Event.metadata["provider_event_id"]` (SendGrid canonical `sg_event_id` or fallback; Postmark synthetic `RecordType:ID:timestamp`) to populate the `mailglass_webhook_events` row's UNIQUE(provider, provider_event_id) columns. String-key discipline is uniform across both providers — a single `Map.fetch!/2` pair suffices.
- **Plan 04-09 (property tests + UAT)** — can exercise the 1000-replay idempotency property against both providers through the shared Provider behaviour.

**Blockers or concerns:** None. The pre-existing citext OID issue is deferred to Phase 6.

**Phase 4 progress:** 3 of 9 plans complete.

## Self-Check: PASSED

Verified:

- `lib/mailglass/webhook/providers/sendgrid.ex` — FOUND
- `test/mailglass/webhook/providers/sendgrid_test.exs` — FOUND
- `lib/mailglass/config.ex` — modified (`:sendgrid` sub-tree present alongside `:postmark`)
- Commit `f3c48e5` (Task 1 — SendGrid provider + :sendgrid config) — FOUND in `git log`
- Commit `9ab8bcc` (Deviation fix — OTP 27 der_decode) — FOUND
- Commit `996510a` (Task 2 — SendGrid test suite) — FOUND
- `mix compile --warnings-as-errors --no-optional-deps` — exits 0
- `mix test test/mailglass/webhook/providers/sendgrid_test.exs` — 32 tests, 0 failures
- `mix test test/mailglass/webhook/` — 67 tests, 0 failures (35 Plan 04-02 + 32 Plan 04-03)
- `mix verify.phase_02` — 59 tests, 0 failures (506 excluded)
- `mix verify.phase_03` — 62 tests, 0 failures, 2 skipped (503 excluded)
- `mix verify.phase_04` — 0 tests, 0 failures (Wave 1B — Wave 4 ships first `:phase_04_uat` tests)
- `Mailglass.Webhook.Providers.SendGrid` declares `@behaviour Mailglass.Webhook.Provider` and exports both callback functions (verified via module_info)
- `grep -c "defp map_event" lib/mailglass/webhook/providers/sendgrid.ex` → 16 (plan required ≥12)
- `grep -c "describe " test/mailglass/webhook/providers/sendgrid_test.exs` → 4 (plan required ≥4)

---
*Phase: 04-webhook-ingest*
*Completed: 2026-04-23*
