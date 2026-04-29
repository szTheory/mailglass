---
phase: 15-mailgun-webhook-provider
verified: 2026-04-29T01:26:22Z
status: passed
score: 13/13 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 11/11 must-haves verified
  gaps_closed:
    - "Mailgun runtime config is validated centrally with safe replay and timestamp defaults."
  gaps_remaining: []
  regressions: []
---

# Phase 15: Mailgun Webhook Provider Verification Report

**Phase Goal:** System securely ingests and normalizes Mailgun webhooks while preventing replay attacks  
**Verified:** 2026-04-29T01:26:22Z  
**Status:** passed  
**Re-verification:** Yes - refreshed after follow-up commit `31e5a85`

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Valid Mailgun HMAC-SHA256 signatures are accepted. | ✓ VERIFIED | `Mailglass.Webhook.Providers.Mailgun.verify!/3` computes HMAC over `timestamp <> token` and returns `:ok` on success in [lib/mailglass/webhook/providers/mailgun.ex](lib/mailglass/webhook/providers/mailgun.ex:19). Covered by [test/mailglass/webhook/providers/mailgun_test.exs](test/mailglass/webhook/providers/mailgun_test.exs:23). |
| 2 | Invalid or expired Mailgun signatures are rejected. | ✓ VERIFIED | Bad signatures raise `%SignatureError{type: :bad_signature}` and skewed timestamps raise `%SignatureError{type: :timestamp_skew}` in [lib/mailglass/webhook/providers/mailgun.ex](lib/mailglass/webhook/providers/mailgun.ex:33) and [lib/mailglass/webhook/providers/mailgun.ex](lib/mailglass/webhook/providers/mailgun.ex:131). Negative cases are covered in [test/mailglass/webhook/providers/mailgun_test.exs](test/mailglass/webhook/providers/mailgun_test.exs:29). |
| 3 | Replayed Mailgun tokens are rejected via token caching. | ✓ VERIFIED | `verify!/3` claims tokens through `MailgunReplayCache.check_and_put/2` and converts duplicates to `{:ok, :replay}` in [lib/mailglass/webhook/providers/mailgun.ex](lib/mailglass/webhook/providers/mailgun.ex:39). The ETS cache uses `:ets.insert_new/2` for the claim path in [lib/mailglass/webhook/providers/mailgun_replay_cache.ex](lib/mailglass/webhook/providers/mailgun_replay_cache.ex:8), with sequential and concurrent replay tests in [test/mailglass/webhook/providers/mailgun_test.exs](test/mailglass/webhook/providers/mailgun_test.exs:72). |
| 4 | Mailgun events are correctly mapped to the internal normalized taxonomy. | ✓ VERIFIED | `normalize/2` maps accepted, delivered, temporary failed, permanent failed, opened, clicked, complained, and unsubscribed events in [lib/mailglass/webhook/providers/mailgun.ex](lib/mailglass/webhook/providers/mailgun.ex:181). Lifecycle mapping coverage is in [test/mailglass/webhook/providers/mailgun_test.exs](test/mailglass/webhook/providers/mailgun_test.exs:95). |
| 5 | Mailgun replay-safe verification work can start immediately because the phase establishes on-disk provider and plug test targets before behavior-level checks depend on them. | ✓ VERIFIED | Both phase test targets exist and are substantive: [test/mailglass/webhook/providers/mailgun_test.exs](test/mailglass/webhook/providers/mailgun_test.exs:1) and [test/mailglass/webhook/plug_mailgun_test.exs](test/mailglass/webhook/plug_mailgun_test.exs:1). |
| 6 | Mailgun replay detection has an in-memory fast path before any webhook event is persisted. | ✓ VERIFIED | Replay is decided in `verify!/3` before normalization or ingest, and the duplicate branch exits early in the plug without writing events in [lib/mailglass/webhook/plug.ex](lib/mailglass/webhook/plug.ex:125). The replay cache itself is in-memory ETS in [lib/mailglass/webhook/providers/mailgun_replay_cache.ex](lib/mailglass/webhook/providers/mailgun_replay_cache.ex:1). |
| 7 | A replay-aware verify contract exists so Mailgun replay can converge to a non-error outcome instead of 401 per D-05. | ✓ VERIFIED | The provider behaviour allows `:ok | {:ok, :replay}` in [lib/mailglass/webhook/provider.ex](lib/mailglass/webhook/provider.ex:24), and the plug translates replay to HTTP 200 in [lib/mailglass/webhook/plug.ex](lib/mailglass/webhook/plug.ex:125). |
| 8 | The replay cache is started under application supervision so replay defense is available before provider verification and later persistence wiring run. | ✓ VERIFIED | `Mailglass.Application` conditionally starts `MailgunReplayCache.Supervisor` in [lib/mailglass/application.ex](lib/mailglass/application.ex:20), which owns the named ETS table through [lib/mailglass/webhook/providers/mailgun_replay_cache/supervisor.ex](lib/mailglass/webhook/providers/mailgun_replay_cache/supervisor.ex:1) and [lib/mailglass/webhook/providers/mailgun_replay_cache/table_owner.ex](lib/mailglass/webhook/providers/mailgun_replay_cache/table_owner.ex:1). |
| 9 | A previously accepted Mailgun token is recognized as replay on the provider fast path per D-02 and D-05. | ✓ VERIFIED | Duplicate tokens return `{:ok, :replay}` from provider verification in [lib/mailglass/webhook/providers/mailgun.ex](lib/mailglass/webhook/providers/mailgun.ex:41), and provider tests cover both sequential and concurrent first-claim races in [test/mailglass/webhook/providers/mailgun_test.exs](test/mailglass/webhook/providers/mailgun_test.exs:73). |
| 10 | Mailgun lifecycle events normalize into the existing Mailglass taxonomy while preserving ambiguous provider details per D-08 through D-10. | ✓ VERIFIED | Normalized events include `"provider"`, `"provider_event_id"`, `"severity"`, `"reason"`, and `"delivery-status"` metadata in [lib/mailglass/webhook/providers/mailgun.ex](lib/mailglass/webhook/providers/mailgun.ex:159). Tests assert preserved raw details for temporary and permanent failures in [test/mailglass/webhook/providers/mailgun_test.exs](test/mailglass/webhook/providers/mailgun_test.exs:112). |
| 11 | Mailgun routes can be mounted explicitly without changing the default webhook surface. | ✓ VERIFIED | Router defaults remain `[:postmark, :sendgrid]`, while `:mailgun` is only accepted through explicit `providers:` opt-in in [lib/mailglass/webhook/router.ex](lib/mailglass/webhook/router.ex:71). Route tests confirm both the default surface and explicit Mailgun mount in [test/mailglass/webhook/router_test.exs](test/mailglass/webhook/router_test.exs:7) and [test/mailglass/webhook/router_test.exs](test/mailglass/webhook/router_test.exs:86). |
| 12 | A replayed Mailgun webhook returns a successful non-retrying outcome instead of 401. | ✓ VERIFIED | The replay branch sends HTTP 200 with `duplicate: true` and zero events in [lib/mailglass/webhook/plug.ex](lib/mailglass/webhook/plug.ex:125). Plug coverage confirms first and second calls both return 200 while only one webhook event row is persisted in [test/mailglass/webhook/plug_mailgun_test.exs](test/mailglass/webhook/plug_mailgun_test.exs:41). |
| 13 | Mailgun runtime config is validated centrally with safe defaults for replay and timestamp handling. | ✓ VERIFIED | `Mailglass.Config` defines the Mailgun subtree and, after commit `31e5a85`, validates `replay_cache_ttl_seconds >= timestamp_tolerance_seconds` in [lib/mailglass/config.ex](lib/mailglass/config.ex:417) and [lib/mailglass/config.ex](lib/mailglass/config.ex:595). The rejection case is covered in [test/mailglass/config_test.exs](test/mailglass/config_test.exs:76). |

**Score:** 13/13 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `test/mailglass/webhook/providers/mailgun_test.exs` | Provider verification and normalization coverage | ✓ VERIFIED | 184-line substantive test module covering verify, replay, concurrency, normalization, and malformed JSON handling. |
| `test/mailglass/webhook/plug_mailgun_test.exs` | Replay-aware plug/runtime coverage | ✓ VERIFIED | 119-line test module covering valid 200, replay 200, invalid signature 401, and missing-config 500 paths. |
| `lib/mailglass/webhook/provider.ex` | Replay-aware provider contract | ✓ VERIFIED | Behaviour declares `verify!/3 :: :ok | {:ok, :replay}` and keeps the contract Conn-free. |
| `lib/mailglass/webhook/providers/mailgun_replay_cache.ex` | ETS-backed replay cache API keyed by Mailgun token | ✓ VERIFIED | Exposes `check_and_put/2`, `reset/0`, and `table/0`, with atomic claim behavior via `:ets.insert_new/2`. |
| `lib/mailglass/webhook/providers/mailgun_replay_cache/supervisor.ex` | Replay cache supervisor | ✓ VERIFIED | Single-child supervisor for the replay-cache table owner. |
| `lib/mailglass/webhook/providers/mailgun_replay_cache/table_owner.ex` | Replay cache table owner | ✓ VERIFIED | Creates the named ETS table `:mailglass_webhook_mailgun_replay_cache`. |
| `lib/mailglass/application.ex` | Application child wiring for Mailgun replay cache | ✓ VERIFIED | Adds the replay-cache supervisor into the main child pipeline via `maybe_add/3`. |
| `lib/mailglass/webhook/providers/mailgun.ex` | Mailgun verify!/3 and normalize/2 implementation | ✓ VERIFIED | Substantive provider implementation with HMAC verification, skew checks, replay cache use, and lifecycle mapping. |
| `test/support/webhook_fixtures.ex` | Fixture helpers for Mailgun signature payload generation | ✓ VERIFIED | Provides payload loading and runtime signing used by provider and plug tests. |
| `lib/mailglass/webhook/plug.ex` | Replay-aware Mailgun request orchestration and response matrix | ✓ VERIFIED | Verifies first, returns HTTP 200 on replay, and only ingests after successful verification. |
| `lib/mailglass/webhook/router.ex` | Explicit `:mailgun` opt-in route validation | ✓ VERIFIED | Keeps default routes stable while validating explicit provider lists at compile time. |
| `lib/mailglass/config.ex` | Validated Mailgun runtime config subtree | ✓ VERIFIED | Central schema covers signing key, timestamp tolerance, future skew, replay TTL, and the replay-window invariant. |
| `lib/mailglass/installer/templates.ex` | Installer webhook snippet showing explicit Mailgun opt-in | ✓ VERIFIED | Emits `providers: [:postmark, :sendgrid, :mailgun]` in the installer router snippet. |
| `guides/webhooks.md` | Published Mailgun setup and replay semantics guide | ✓ VERIFIED | Documents explicit route mounting, config, JSON signature fields, and replay HTTP 200 semantics. |
| `test/example/README.md` | Golden installer snapshots updated for webhook snippet changes | ✓ VERIFIED | Snapshot content includes the explicit Mailgun route snippet used by installer tests. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `lib/mailglass/webhook/provider.ex` | `lib/mailglass/webhook/providers/mailgun.ex` | `verify!/3` return contract allowing `{:ok, :replay}` | ✓ WIRED | Behaviour and implementation both expose the replay-aware return contract in [provider.ex](lib/mailglass/webhook/provider.ex:24) and [mailgun.ex](lib/mailglass/webhook/providers/mailgun.ex:19). |
| `lib/mailglass/application.ex` | `lib/mailglass/webhook/providers/mailgun_replay_cache/supervisor.ex` | application child spec | ✓ WIRED | The application child list references `MailgunReplayCache.Supervisor` in [lib/mailglass/application.ex](lib/mailglass/application.ex:31). |
| `lib/mailglass/webhook/providers/mailgun.ex` | `lib/mailglass/webhook/providers/mailgun_replay_cache.ex` | replay token insert/check during `verify!/3` | ✓ WIRED | `Mailgun.verify!/3` calls `MailgunReplayCache.check_and_put/2` in [lib/mailglass/webhook/providers/mailgun.ex](lib/mailglass/webhook/providers/mailgun.ex:41). |
| `lib/mailglass/webhook/providers/mailgun.ex` | `test/support/webhook_fixtures.ex` | fixture-generated signature payloads | ✓ WIRED | Provider tests sign raw Mailgun fixtures at runtime via `sign_mailgun_payload/3` in [test/mailglass/webhook/providers/mailgun_test.exs](test/mailglass/webhook/providers/mailgun_test.exs:170). |
| `lib/mailglass/webhook/plug.ex` | `lib/mailglass/webhook/providers/mailgun.ex` | `verify_with_telemetry!` and `provider_module(:mailgun)` | ✓ WIRED | The plug routes `:mailgun` to the Mailgun provider and invokes verification before tenant resolution in [lib/mailglass/webhook/plug.ex](lib/mailglass/webhook/plug.ex:125). |
| `lib/mailglass/webhook/router.ex` | `lib/mailglass/webhook/plug.ex` | POST route with `[provider: :mailgun]` | ✓ WIRED | The router macro generates `post ... Mailglass.Webhook.Plug, [provider: provider]` in [lib/mailglass/webhook/router.ex](lib/mailglass/webhook/router.ex:103), and tests confirm the explicit Mailgun route in [test/mailglass/webhook/router_test.exs](test/mailglass/webhook/router_test.exs:86). |
| `test/support/webhook_case.ex` | `lib/mailglass/config.ex` | Mailgun test config env keys | ✓ WIRED | Test support installs `signing_key`, `timestamp_tolerance_seconds`, `future_skew_seconds`, and `replay_cache_ttl_seconds` matching the config schema in [test/support/webhook_case.ex](test/support/webhook_case.ex:102). |
| `lib/mailglass/webhook/providers/mailgun.ex` | `lib/mailglass/webhook/ingest.ex` | token-backed `provider_event_id` flowing into persistence | ✓ WIRED | Mailgun normalization writes `"provider_event_id" => token` in [lib/mailglass/webhook/providers/mailgun.ex](lib/mailglass/webhook/providers/mailgun.ex:167), and ingest derives the Mailgun webhook event id from that metadata in [lib/mailglass/webhook/ingest.ex](lib/mailglass/webhook/ingest.ex:364). |
| `lib/mailglass/installer/templates.ex` | `test/example/README.md` | installer golden snapshot content | ✓ WIRED | The installer snippet and committed goldens both contain `mailglass_webhook_routes "/webhooks", providers: [:postmark, :sendgrid, :mailgun]` in [lib/mailglass/installer/templates.ex](lib/mailglass/installer/templates.ex:49) and [test/example/README.md](test/example/README.md:114). |
| `guides/webhooks.md` | `lib/mailglass/webhook/plug.ex` | documented Mailgun replay 200 response semantics | ✓ WIRED | The guide documents replay HTTP 200 behavior in [guides/webhooks.md](guides/webhooks.md:111), matching the replay branch in [lib/mailglass/webhook/plug.ex](lib/mailglass/webhook/plug.ex:126). |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `lib/mailglass/webhook/providers/mailgun.ex` | `timestamp`, `token`, `signature` | Decoded JSON payload via `Jason.decode/1` and `payload["signature"]` | Yes | ✓ FLOWING |
| `lib/mailglass/webhook/providers/mailgun.ex` | `event_data` / `metadata["provider_event_id"]` | Decoded JSON payload via `payload["event-data"]` and `payload["signature"]["token"]` | Yes | ✓ FLOWING |
| `lib/mailglass/webhook/plug.ex` | `events` | `provider_module(provider).normalize(raw_body, headers)` after successful verification | Yes | ✓ FLOWING |
| `lib/mailglass/webhook/ingest.ex` | `provider_event_id` | `Event.metadata["provider_event_id"]` from Mailgun normalization | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Provider verification, replay handling, router wiring, config validation, and installer goldens all behave as expected | `mix test test/mailglass/webhook/providers/mailgun_test.exs test/mailglass/webhook/plug_mailgun_test.exs test/mailglass/webhook/router_test.exs test/mailglass/config_test.exs test/mailglass/install/install_golden_test.exs --warnings-as-errors` | `46 tests, 0 failures` | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `MAILGUN-01` | `15-02`, `15-03`, `15-04` | Webhook plug verifies HMAC-SHA256 signature using `timestamp`, `token`, and webhook signing key. | ✓ SATISFIED | Provider HMAC verification in [lib/mailglass/webhook/providers/mailgun.ex](lib/mailglass/webhook/providers/mailgun.ex:29); plug routing and negative-path coverage in [test/mailglass/webhook/plug_mailgun_test.exs](test/mailglass/webhook/plug_mailgun_test.exs:60). |
| `MAILGUN-02` | `15-01`, `15-02`, `15-03` | Token caching mechanism prevents replay attacks for previously verified tokens. | ✓ SATISFIED | ETS replay cache in [lib/mailglass/webhook/providers/mailgun_replay_cache.ex](lib/mailglass/webhook/providers/mailgun_replay_cache.ex:8); replay 200 short-circuit in [lib/mailglass/webhook/plug.ex](lib/mailglass/webhook/plug.ex:125); replay-window invariant added in [lib/mailglass/config.ex](lib/mailglass/config.ex:595); provider replay tests in [test/mailglass/webhook/providers/mailgun_test.exs](test/mailglass/webhook/providers/mailgun_test.exs:72). |
| `MAILGUN-03` | `15-02`, `15-03`, `15-04` | Webhook maps Mailgun events to `mailglass` normalized taxonomy. | ✓ SATISFIED | Mapping logic in [lib/mailglass/webhook/providers/mailgun.ex](lib/mailglass/webhook/providers/mailgun.ex:181); persistence identity wiring in [lib/mailglass/webhook/ingest.ex](lib/mailglass/webhook/ingest.ex:364); normalization tests in [test/mailglass/webhook/providers/mailgun_test.exs](test/mailglass/webhook/providers/mailgun_test.exs:95). |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| None | - | No TODO/FIXME/placeholder, hollow implementation, or orphaned-wire patterns found in the verified phase files. | - | No blocker or warning-level anti-patterns detected. |

### Gaps Summary

No functional gaps remain against the phase goal, roadmap success criteria, or the merged plan must-haves. The prior review warning about a replay cache TTL shorter than the accepted timestamp window is closed by commit `31e5a85`, which now rejects that invalid Mailgun config during validation.

---

_Verified: 2026-04-29T01:26:22Z_  
_Verifier: Claude (gsd-verifier)_
