---
phase: 46-mailgun-ses-inbound-ingress
verified: 2026-05-23T16:40:00Z
status: passed
score: 13/13 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: none
  note: "Initial verification (no prior VERIFICATION.md)."
---

# Phase 46: Mailgun + SES Inbound Ingress Verification Report

**Phase Goal:** Lift outbound verifiers into inbound; ship Mailgun (HMAC) and SES (SNS X.509 + S3 fetch) provider plugs — adopters running Mailgun or SES inbound webhooks can install Mailglass and have authentic payloads verified, normalized into `%InboundMessage{}`, persisted with raw evidence, and dispatched to the matched mailbox, without inventing new cryptography.
**Verified:** 2026-05-23T16:40:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

Truths merge the 5 ROADMAP Success Criteria (the contract) with the plan-frontmatter must-haves (deduplicated). All verified against the live source, not SUMMARY claims.

| #  | Truth | Status | Evidence |
| -- | ----- | ------ | -------- |
| 1  | (SC1) Authentic Mailgun multipart POST verifies HMAC-SHA256 over `timestamp<>token`, normalizes into `%InboundMessage{}`, persists raw evidence, dispatches matched mailbox; forged payload raises `MailglassInbound.SignatureError` (no recovery) | ✓ VERIFIED | `mailgun.ex:35-41` `:crypto.mac(:hmac,:sha256,…)` + `Plug.Crypto.secure_compare` (length-guarded `:316-321`); forgery `raise SignatureError.new(:bad_signature, provider: :mailgun)` `:40`; normalize two-mode `:74-183`; plug `maybe_execute → execution.dispatch` `plug.ex:503-504`. Tests: `mailgun_provider_test.exs:23-38`, plug dispatch order `plug_test.exs:205-213`. |
| 2  | (SC2) Replayed Mailgun token dropped at the existing `MailgunReplayCache` ETS table — no second `InboundRecord`; the running GenServer is reused, not duplicated | ✓ VERIFIED | `mailgun.ex:47-51` `MailgunReplayCache.check_and_put` → `{:replay}`; plug `{:replay}` → 200 no-op, no `persist_and_respond` `plug.ex:108-110`. Test reuses running core cache (no re-supervise) `mailgun_provider_test.exs:13-18,97-111`. No supervisor added to `MailglassInbound.Application` (grep clean). |
| 3  | (SC3) Authentic SES SNS verifies X.509 via core `CertCache`+`TrustPolicy` (URL allowlist); `SubscriptionConfirmation` auto-confirms only when SubscribeURL passes `TrustPolicy`; forged/hijacked URLs rejected | ✓ VERIFIED | `ses.ex:142` calls `CoreSES.verify_envelope!/2` (which runs `TrustPolicy.valid_cert_url?` before network I/O, core `ses.ex:97-102`); control-plane `confirm_control_plane!` uses `TrustPolicy.valid_subscribe_url?/1` `ses.ex:166-179`; hijack → `:subscribe_url_untrusted`. Tests `ses_provider_test.exs:53-97`. |
| 4  | (SC4) SES `Action: S3` fetches MIME via `MailglassInbound.S3Fetcher`; `S3Fetcher.Fake` ships as test default; `S3Fetcher.ExAwsS3` behind the new optional-dep gateway; SNS-before-S3 races recover with bounded retry + structured error | ✓ VERIFIED | `ses.ex:187-217` S3 primary + inline secondary → `MIME.parse/1`; `s3_fetcher/fake.ex` (test default, `default_fetcher/0` `ses.ex:277-283`); `s3_fetcher/ex_aws_s3.ex` routes only through `OptionalDeps.ExAwsS3`; `s3_fetcher/retry.ex:67-72` exhaustion → `S3FetchError :s3_object_not_ready`. Tests `s3_fetcher_test.exs`, `ses_provider_test.exs:37-51`. NOTE: gateway is inbound-local (`MailglassInbound.OptionalDeps.ExAwsS3`) per D-46-14 — SESI-04's literal `Mailglass.OptionalDeps.ExAwsS3` is a documented erratum (see Requirements). |
| 5  | (SC5 / MGUN-04) Plug allowlist accepts `:mailgun` and `:ses` alongside `:postmark`/`:sendgrid`; dispatch is ONE switch, not two parallel pipelines | ✓ VERIFIED | `plug.ex:53` single `init/1` guard `[:postmark,:sendgrid,:mailgun,:ses]`; single `provider_module/1` switch `:564-569`; per-provider `build_request!`/`resolve_config!`/`verify_request!`/`normalize_request!` clauses share one `do_call/2`. Test `plug_test.exs` init cases. |
| 6  | `MailglassInbound.SignatureError` raises no-recovery on forged signatures + exposes closed `:type` set | ✓ VERIFIED | `signature_error.ex:46` closed `@types [:bad_signature,:missing_header,:malformed_header,:timestamp_skew,:subscribe_url_untrusted]`; `__types__/0 :66`; `new/2` validates + raises `ArgumentError` on bad type `:100-104`; no `retryable?` affordance. Contract test green. |
| 7  | `MailglassInbound.S3FetchError` exposes closed set `[:s3_object_not_ready, :s3_fetch_failed]` | ✓ VERIFIED | `s3_fetch_error.ex:31` `@types`; `__types__/0 :45`; `@derive Jason.Encoder only [:type,:message,:context]` excludes `:cause`. Contract test green. |
| 8  | Inbound plug `do_call/2` dispatches the 3-variant verify result: `{:ok, facts}` persists, `{:replay}` = 200 no-op, `{:control_plane, _}` = 200 no-op | ✓ VERIFIED | `plug.ex:107-123` `case verify_request!/4` with all three branches + legacy bare-map. Replay/control-plane skip `persist_and_respond`. Tests `plug_test.exs:236,259` assert no dispatch + no record. |
| 9  | Plug rescues BOTH `Mailglass.SignatureError` and `MailglassInbound.SignatureError`, both → 401 | ✓ VERIFIED | `plug.ex:130` `rescue e in [SignatureError, InboundSignatureError] -> 401`. Test `plug_test.exs:305-315`. |
| 10 | Core `Mailglass.Webhook.Providers.SES.verify_envelope!/2` returns the verified SNS payload; outbound `verify!/3` keeps its return + outbound tests stay green | ✓ VERIFIED | core `ses.ex:88-143` public `verify_envelope!/2` (`@spec`, `@since "1.2.0"`); `verify!/3 :63-70` calls seam then dispatches, unchanged return. Core webhook suite **217 tests, 0 failures**. |
| 11 | Mailgun normalizes into `%InboundMessage{}` + raw provider source persists to `inbound_evidence`; dedupe on RFC `Message-Id` (case-insensitive) when present, MD5(raw) fingerprint when absent | ✓ VERIFIED | `mailgun.ex` `extract_message_id/1 :261-274` (case-insensitive from `message-headers`); evidence map `:121-131,:172-182`; persist split clause Message-Id + fingerprint `persist.ex:138-163`; `mailgun` fingerprint migration `20260523120000`. Postgres-backed dedupe tests green. |
| 12 | `MailglassInbound.S3Fetcher` behaviour defines `@callback fetch/3`; `S3Fetcher.ExAwsS3` gates all access through `OptionalDeps.ExAwsS3` | ✓ VERIFIED | `s3_fetcher.ex:21-22` `@callback fetch/3`; `ex_aws_s3.ex:16` alias-only gateway use; no bare `ExAws` runtime ref in inbound lib (grep: only comments/`@compile`/the gateway body). |
| 13 | `mix compile --no-optional-deps --warnings-as-errors` stays green; no bare ExAws outside the gateway | ✓ VERIFIED | Lane exits 0 (37 files compiled clean). Gateway `@compile {:no_warn_undefined, [ExAws, ExAws.S3]}` `optional_deps.ex:124`; `.credo.exs` gates both `ExAws`/`ExAws.S3` to the gateway `:61-62`; `mix credo --strict` no issues (389 files). |

**Score:** 13/13 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `mailglass_inbound/lib/.../signature_error.ex` | No-recovery closed-type inbound signature error | ✓ VERIFIED | 126L; `__types__/0`, `new/2`, PII-safe `@derive` excluding `:cause`+`:provider`. Package-local (no `Mailglass.Error` behaviour). |
| `mailglass_inbound/lib/.../s3_fetch_error.ex` | Closed-type S3 fetch error | ✓ VERIFIED | 49L; `__types__/0`; `@derive` excludes `:cause`. |
| `mailglass_inbound/lib/.../s3_fetcher.ex` | `@callback fetch/3` behaviour | ✓ VERIFIED | 23L; behaviour-only contract. |
| `mailglass_inbound/lib/.../s3_fetcher/fake.ex` | Test-default fetcher (fake-first D-13) | ✓ VERIFIED | 100L; `@behaviour`, canned/error/error-then-ok modes, call counts; process-dict-isolated for async. |
| `mailglass_inbound/lib/.../s3_fetcher/ex_aws_s3.ex` | Real fetcher behind gateway | ✓ VERIFIED | 39L; all access via `OptionalDeps.ExAwsS3`; no bare ExAws. |
| `mailglass_inbound/lib/.../s3_fetcher/retry.ex` | Bounded retry → S3FetchError | ✓ VERIFIED | 108L; ≤3 attempts, transient/non-retryable classification, exhaustion → `:s3_object_not_ready`. (Net-new module beyond plan; supports SESI-05.) |
| `mailglass_inbound/lib/.../optional_deps.ex` | `OptionalDeps.ExAwsS3` gateway (D-46-14) | ✓ VERIFIED | 168L; mirrors GenSmtp; `available?/0` gate (WR-06), never-raise wrapper, distinct absent-dep tag. |
| `mailglass_inbound/lib/.../ingress/provider.ex` | Widened `verify!/2` 3-variant union | ✓ VERIFIED | 68L; `@callback verify!/2` union + legacy `/3`; `@optional_callbacks verify!: 2, verify!: 3`. |
| `mailglass_inbound/lib/.../ingress/plug.ex` | 4-provider allowlist + 3-variant case + dual rescue | ✓ VERIFIED | 570L; all wiring present incl. CR-02 `S3FetchError` rescue (`:151-157`). |
| `mailglass_inbound/lib/.../ingress/persist.ex` | Mailgun + SES dedupe clauses + race resolution | ✓ VERIFIED | 339L; split clauses + `resolve_fingerprint_race` (CR-01). |
| `mailglass_inbound/lib/.../ingress/providers/mailgun.ex` | Mailgun provider | ✓ VERIFIED | 498L; flat-field HMAC, replay no-op, two-mode normalize, Message-Id extraction. |
| `mailglass_inbound/lib/.../ingress/providers/ses.ex` | SES provider | ✓ VERIFIED | 491L; seam reuse, control-plane no-op, S3/inline extraction, all 6 WARNINGs resolved in code. |
| `mailglass_inbound/priv/repo/migrations/20260523120000_*` | Mailgun fingerprint partial unique index | ✓ VERIFIED | `where: "provider = 'mailgun' AND raw_mime_fingerprint IS NOT NULL"`; does not recreate column. |
| `mailglass_inbound/priv/repo/migrations/20260523130000_*` | SES fingerprint partial unique index (WR-02) | ✓ VERIFIED | `where: "provider = 'ses' AND raw_mime_fingerprint IS NOT NULL"`. (Net-new from review fix.) |
| `lib/mailglass/webhook/providers/ses.ex` | `verify_envelope!/2` core seam | ✓ VERIFIED | 686L; public seam extracted, outbound `verify!/3` unchanged. |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| `ingress/plug.ex` | `MailglassInbound.SignatureError` | dual rescue clause | ✓ WIRED | `plug.ex:130` `rescue e in [SignatureError, InboundSignatureError]`. |
| `ingress/plug.ex` | `MailglassInbound.S3FetchError` | rescue clause (CR-02) | ✓ WIRED | `plug.ex:151-157` maps `:s3_object_not_ready`→500, `:s3_fetch_failed`→422. |
| `core ses.ex verify!/3` | `verify_envelope!/2` | refactored call | ✓ WIRED | core `ses.ex:65` `{:ok, payload} = verify_envelope!(raw_body, config)`. |
| `mailgun.ex` | `MailgunReplayCache.check_and_put` | running core ETS cache | ✓ WIRED | `mailgun.ex:47`; no re-supervise. |
| `mailgun.ex` | `MailglassInbound.MIME.parse/1` | raw-MIME mode | ✓ WIRED | `mailgun.ex:137`. |
| `ses.ex` | `CoreSES.verify_envelope!/2` | seam reuse | ✓ WIRED | `ses.ex:142`. |
| `s3_fetcher/ex_aws_s3.ex` | `OptionalDeps.ExAwsS3.get_object` | gateway-only access | ✓ WIRED | `ex_aws_s3.ex:23` `&Gateway.get_object/2`. |
| `ses.ex` | `S3Fetcher.Retry.fetch_with_retry` | bounded retry | ✓ WIRED | `ses.ex:215`. |
| `plug.ex` | `execution.dispatch` (mailbox) | `maybe_execute` on `:inserted` | ✓ WIRED | `plug.ex:503-504`; test asserts `[:persist, :dispatch]`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| `mailgun.ex` normalize | `%InboundMessage{}` fields | `request.params` (form fields) + `message-headers` JSON | Yes — populated from real payload, persisted to `inbound_records`/`inbound_evidence` | ✓ FLOWING |
| `ses.ex` normalize | `%InboundMessage{}` fields | parsed MIME repr from S3/inline body via `MIME.parse/1` | Yes — fetched body → parsed → record; verify→normalize handoff via process dict | ✓ FLOWING |
| `persist.ex` dedupe | `load_duplicate/5` result | Postgres queries on real fingerprint/Message-Id indexes | Yes — Postgres-backed tests prove convergence to 1 record | ✓ FLOWING |
| `verify_facts` | `%{auth: :hmac}` / `%{auth: :sns_x509}` | provider verify | Yes — PII-free, threaded into evidence | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Inbound full suite | `mix test` (mailglass_inbound) | 1 property, 176 tests, 0 failures | ✓ PASS |
| Core webhook regression (seam guard) | `mix test test/mailglass/webhook/` | 217 tests, 0 failures | ✓ PASS |
| Phase-46 provider/error/plug/persist tests | `mix test <7 phase files>` | 97 tests, 0 failures | ✓ PASS |
| Compile (optional deps) | `mix compile --warnings-as-errors` | exit 0 | ✓ PASS |
| Compile (no optional deps) | `mix compile --no-optional-deps --warnings-as-errors` | exit 0 (37 files) | ✓ PASS |
| Lint (custom checks + opt-dep gating) | `mix credo --strict` | no issues, 389 files | ✓ PASS |

### Probe Execution

No project probe scripts (`scripts/*/tests/probe-*.sh`) exist; phase verification is test-suite-driven (Elixir/ExUnit). Step 7c: not applicable — no probes declared in PLAN/SUMMARY.

### Requirements Coverage

All 9 phase requirement IDs from PLAN frontmatter cross-referenced against REQUIREMENTS.md. Every ID accounted for.

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| MGUN-01 | 46-02 | Mailgun verifies HMAC-SHA256 timestamp+token, forged → `SignatureError` (no recovery) | ✓ SATISFIED | `mailgun.ex:35-41`; tests pass. |
| MGUN-02 | 46-02 | Reuses existing `MailgunReplayCache` ETS table for replay protection | ✓ SATISFIED | `mailgun.ex:47-51`; running cache reused (no re-supervise). |
| MGUN-03 | 46-02 | Normalizes multipart → `%InboundMessage{}` + persists raw to `inbound_evidence` | ✓ SATISFIED | `mailgun.ex:94-183`; evidence map; persist tests. |
| MGUN-04 | 46-01 | Plug allowlist extended to recognize Mailgun | ✓ SATISFIED | `plug.ex:53` + `:568`. |
| SESI-01 | 46-03 | SES verifies SNS X.509 via core `CertCache`+`TrustPolicy` (URL allowlist) | ✓ SATISFIED | `ses.ex:142` → core seam; cert-URL trust before I/O. |
| SESI-02 | 46-03 | Auto-confirms `SubscriptionConfirmation` when SubscribeURL passes TrustPolicy | ✓ SATISFIED | `ses.ex:166-179` → `{:control_plane, 200}`; hijack rejected. |
| SESI-03 | 46-01 | `MailglassInbound.S3Fetcher` behaviour defines the S3-fetch contract | ✓ SATISFIED | `s3_fetcher.ex:21-22` `@callback fetch/3`. |
| SESI-04 | 46-03 | `S3Fetcher.Fake` ships in core (test default); real `S3Fetcher.ExAwsS3` behind a new optional-dep gateway mirroring `OptionalDeps.GenSmtp` | ✓ SATISFIED (with documented erratum) | `fake.ex` + `ex_aws_s3.ex` + `OptionalDeps.ExAwsS3`. The literal `Mailglass.OptionalDeps.ExAwsS3` in REQUIREMENTS.md is a known erratum (D-46-14, CONTEXT.md): the consumer lives in inbound, and core's `NoBareOptionalDepReference` is scoped to `lib/mailglass/`, so the gateway is correctly inbound-local. Intent (fake-first + gated real adapter mirroring GenSmtp) is fully met. |
| SESI-05 | 46-03 | Handles SNS-before-S3 race with bounded retry + structured error | ✓ SATISFIED | `s3_fetcher/retry.ex` (≤3 attempts) → `S3FetchError :s3_object_not_ready`; non-ack so SNS redelivers. |

**Orphaned requirements:** None. MGUN-05 / SESI-06 (setup guides) are explicitly Phase 50 per REQUIREMENTS.md (lines 178, 184) and CONTEXT.md out-of-scope — not orphaned.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| — | — | No `TBD`/`FIXME`/`XXX` debt markers in any phase-46 source file | — | None |
| — | — | No `TODO`/`HACK`/`PLACEHOLDER`/"not implemented" in provider/fetcher/gateway code | — | None |
| `mailgun.ex`, `ses.ex`, `persist.ex` | 115/166, 111, 234 | `DateTime.utc_now()` for `received_at` instead of injectable `Clock` | ℹ️ Info (IN-02) | Cosmetic test-determinism nit; intentionally deferred in 46-REVIEW.md. Not goal-affecting. |

No blocker or warning anti-patterns. The `S3Fetcher.Fake` is the intended fake-adapter-first test default (D-13), not a stub — the real `ExAwsS3` path is the wired production fetcher resolved by the config seam outside `:test`.

### Code Review Cross-Check

46-REVIEW.md (status: resolved) reported 2 BLOCKER + 6 WARNING + 5 INFO. Verified against live code:

- **CR-01** (Mailgun fingerprint race) — RESOLVED in code: `InboundEvidence.changeset/1` declares all 3 fingerprint `unique_constraint`s (`:64-71`); `persist.ex:91-105` `resolve_fingerprint_race` reloads the survivor. Commit `d7d1c61` present.
- **CR-02** (S3FetchError escapes rescue) — RESOLVED: `plug.ex:151-157` explicit rescue, `:s3_object_not_ready`→500 / `:s3_fetch_failed`→422, PII-free stop-meta. Commit `b87512e` present.
- **WR-01..WR-06** — all RESOLVED in code (verified: WR-01 `Jason.decode` fallback + stash clear `ses.ex:57,307`; WR-02 SES fingerprint clause + migration `20260523130000`; WR-03 documented; WR-04 `s3_retry_opts` threaded `plug.ex:399`; WR-05 `looks_like_mime?` header-line regex + audit warning `ses.ex:245-250`; WR-06 gateway `available?/0` short-circuit `optional_deps.ex:156-162`).
- **IN-01..IN-05** — deferred (info only); none goal-affecting.

### Human Verification Required

None. The phase ships runnable, fully-tested Elixir code with no external-service or visual dependencies in the verification path (the SES test default is `S3Fetcher.Fake`; CI needs no AWS). All observable truths are programmatically verified via passing test suites, compile lanes, lint, and source inspection. Real-AWS sandbox testing is an adopter/Phase-50 concern, not a phase-46 deliverable.

### Gaps Summary

No gaps. All 5 ROADMAP success criteria and all 13 merged must-haves are VERIFIED in the live codebase — not merely claimed in SUMMARY. Every artifact exists, is substantive, is wired, and has real data flowing through it. All 9 requirement IDs are satisfied (SESI-04 with a documented, pre-approved erratum on gateway placement that fully preserves intent). Both BLOCKER and all 6 WARNING review findings are confirmed fixed in source with regression tests. Production-confidence invariants from CLAUDE.md hold: closed-type no-recovery signature errors, PII-free telemetry/evidence separation, the `:ex_aws` optional-dep gateway with an intact `--no-optional-deps` lane, SSRF-guarded SNS trust (cert + subscribe URL allowlists), and replay/dedupe idempotency (running ETS cache + Message-Id/fingerprint partial unique indexes).

---

_Verified: 2026-05-23T16:40:00Z_
_Verifier: Claude (gsd-verifier)_
