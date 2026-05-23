# SECURITY.md — Phase 46: Mailgun + SES Inbound Ingress

**Audit date:** 2026-05-23
**Auditor:** gsd-security-auditor (Claude)
**ASVS Level:** 1
**Block-on:** high
**Scope:** Mailgun (HMAC) + AWS SES (SNS X.509) inbound ingress in `mailglass_inbound`, plus the
`verify_envelope!/2` cross-package security primitive extracted in core. Threat register authored
at PLAN time across 3 plans (46-01/02/03).

**Verdict:** SECURED — all 18 declared threats verified CLOSED against actual implementation code
(not SUMMARY self-reports). 16 `mitigate` threats confirmed present in code; 2 `accept` threats
sound and logged below. The phase-46 register's `T-46-SC` appears once per plan with different
dispositions (Plan 01 `mitigate`/no-install, Plan 02 `accept`/no-install, Plan 03 `mitigate`/install);
the install actually happens in Plan 03 and is verified.

---

## Threat Verification

| Threat ID | Category | Disposition | Status | Evidence (file:line) |
|-----------|----------|-------------|--------|----------------------|
| T-46-01 | Spoofing | mitigate | CLOSED | `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex:130` — `rescue e in [SignatureError, InboundSignatureError] -> 401`; dual rescue covers both core and inbound signature errors, no 500 escape, no recovery path |
| T-46-02 | Tampering | mitigate | CLOSED | `.../ingress/plug.ex:108-114` — `{:replay}` and `{:control_plane, _}` are 200 no-ops that bypass `persist_and_respond`; only `{:ok, facts}`/bare-map (lines 116-122) reach persistence |
| T-46-03 | Repudiation/DoS | mitigate | CLOSED | `.../ingress/plug.ex:109,113` replay/control-plane → 200; `:131` forgery → 401; `:152` `:s3_object_not_ready` → 500; `:220` transient persist failure → 500. Non-200 only on retryable/forgery paths |
| T-46-04 | Info Disclosure | mitigate | CLOSED | `.../signature_error.ex:48` `@derive {Jason.Encoder, only: [:type, :message, :context]}` (excludes `:cause`+`:provider`); `.../s3_fetch_error.ex:33` same derive (excludes `:cause`); plug stop-meta carries only `provider/tenant_id/status/byte_size/error_kind` (`plug.ex:110,114,132,157,197-203,227-234`) |
| T-46-05 | Tampering (seam) | mitigate | CLOSED | `lib/mailglass/webhook/providers/ses.ex:88` public `verify_envelope!/2`; `:63-70` `verify!/3` calls seam then dispatches with unchanged `:ok \| {:ok, :control_plane, _}` return. 217 core webhook tests green (VERIFICATION.md) — regression guard on the primitive |
| T-46-10 | Spoofing | mitigate | CLOSED | `.../ingress/providers/mailgun.ex:36` `:crypto.mac(:hmac, :sha256, signing_key, timestamp <> token)`; `:316-321` `Plug.Crypto.secure_compare` with length pre-guard (constant-time); `:40` forgery → `SignatureError.new(:bad_signature, provider: :mailgun)` |
| T-46-11 | Replay/Tampering | mitigate | CLOSED | `.../ingress/providers/mailgun.ex:47` `MailgunReplayCache.check_and_put(token, expires_at)` → `{:replay}` no-op on replay; running core ETS cache reused — `mailglass_inbound/lib/mailglass_inbound/application.ex:13-14` starts only `Task.Supervisor` (no re-supervision, CLAUDE.md #8) |
| T-46-12 | Tampering | mitigate | CLOSED | `.../ingress/providers/mailgun.ex:43,323-348` `verify_timestamp!` raises `:timestamp_skew` on stale (`:331`) and future-skew (`:334`); malformed timestamp → `:malformed_header` (`:344`) |
| T-46-13 | Tampering (dup insert) | mitigate | CLOSED | `.../ingress/persist.ex:138-141` Mailgun Message-Id → `load_by_provider_message_id` (generic index); `:143-163` no-Message-Id → MD5(raw_mime) fingerprint (`:319-329`) via mailgun index. Token never used for dedupe |
| T-46-14 | DoS | mitigate | CLOSED | `.../ingress/providers/mailgun.ex:137-149` raw-MIME mode routes `MIME.parse/1`; `{:error, %MIMEError{}}` (`:144`) records `mime_parse_failed` parse_warning + falls back to flat fields — boundary-bomb degrades, never raises |
| T-46-15 | Info Disclosure | mitigate | CLOSED | PII (raw_payload/raw_headers/raw_mime/subject/bodies) persists only to tenant-scoped `inbound_records`/`inbound_evidence` (`persist.ex:219-279`, every row carries `tenant_id`); verify facts PII-free `%{auth: :hmac}` (`mailgun.ex:48`); telemetry whitelist enforced (`telemetry.ex:37-49`); `select_safe_headers` strips authorization (`mailgun.ex` / `ses.ex:482-488`) |
| T-46-20 | Spoofing (X.509) | mitigate | CLOSED | `lib/mailglass/webhook/providers/ses.ex:138` `:public_key.verify` (RSA-SHA1/256, `:113-114`); `.../ingress/providers/ses.ex:142-155` reuses `CoreSES.verify_envelope!/2`, re-raises core forgery as `MailglassInbound.SignatureError :bad_signature` → 401 |
| T-46-21 | SSRF | mitigate | CLOSED | `lib/mailglass/webhook/providers/ses.ex:97` `TrustPolicy.valid_cert_url?(cert_url)` runs BEFORE `fetch_public_key!` network I/O (`:105`); `.../ses/trust_policy.ex:37-54` https-only + SNS-host allowlist (`@cert_host_pattern :23`, blocks S3 namespace collision) |
| T-46-22 | Spoofing/SSRF | mitigate | CLOSED | `.../ingress/providers/ses.ex:166-179` `confirm_control_plane!` validates `TrustPolicy.valid_subscribe_url?/1` (`:169`); hijack → `SignatureError.new(:subscribe_url_untrusted)` (`:170`). Core builds ConfirmSubscription URL from signed TopicArn+Token (`ses.ex:186`), never raw SubscribeURL |
| T-46-23 | Tampering | mitigate | CLOSED | `.../ingress/providers/ses.ex:67-69` Subscription/Unsubscribe → `{:control_plane, 200}` with NO record; plug maps to 200 no-op (`plug.ex:112-114`) |
| T-46-24 | DoS | mitigate | CLOSED | `.../s3_fetcher/retry.ex:28` `@default_attempts 3`; `:67-72` exhaustion → `S3FetchError :s3_object_not_ready`; plug maps to 500 non-ack so SNS redelivers (`plug.ex:151-157`); non-retryable → `:s3_fetch_failed` (`:75-81`) |
| T-46-25 | DoS (oversized object) | accept | CLOSED | Logged below. `.../s3_fetcher/ex_aws_s3.ex:25-37` `get_object` into memory; SES caps inbound at 40 MB; streaming deferred |
| T-46-26 | Tampering (KMS ciphertext) | accept | CLOSED | Logged below. `.../ingress/providers/ses.ex:33-38,88-93` ciphertext parses as degraded record via never-raising `MIME.parse/1`; client-side KMS out of scope (D-46-18) |
| T-46-27 | Info Disclosure | mitigate | CLOSED | `.../s3_fetch_error.ex:33` derive excludes `:cause`; `.../signature_error.ex:48` derive excludes `:cause`+`:provider`; `retry.ex:85-91` constructs `%S3FetchError{}` with `:cause` carrying raw reason (excluded from JSON); SES verify facts `%{auth: :sns_x509}` (`ses.ex:65`); telemetry stop-meta PII-free |
| T-46-SC | Tampering (deps) | mitigate | CLOSED | `mailglass_inbound/mix.exs:86-87` `{:ex_aws, "~> 2.7", optional: true}` + `{:ex_aws_s3, "~> 2.5", optional: true}`; gateway-gated `.../optional_deps.ex:124` `@compile {:no_warn_undefined, [ExAws, ExAws.S3]}` (the only ExAws call site). Not in root `mix.exs` (inbound-local). `--no-optional-deps` lane green per VERIFICATION.md |

**Closed:** 18/18 (16 mitigate verified in code, 2 accept logged).

---

## Accepted Risks Log

### T-46-25 — Oversized S3 object loaded into memory (DoS)
- **Disposition:** accept
- **Component:** `mailglass_inbound/lib/mailglass_inbound/s3_fetcher/ex_aws_s3.ex`
- **Risk:** `get_object` reads the full S3 object body into memory; a large object inflates per-request memory.
- **Why acceptable:** AWS SES caps inbound message size at 40 MB, bounding the worst case. Object access
  only follows a verified SNS X.509 signature for the configured topic (verify-before-fetch, `plug.ex:75-94`),
  so this is not an unauthenticated amplification vector. Streaming is deferred.
- **Fallback verified in code:** `ex_aws_s3.ex:25-37` extracts `:body` and surfaces non-binary/error as
  `{:error, _}` rather than crashing; `retry.ex` bounds attempts.
- **Owner / revisit:** revisit if adopters report memory pressure or if SES raises the size cap.

### T-46-26 — SES client-side KMS ciphertext (Tampering / unreadable body)
- **Disposition:** accept
- **Component:** `mailglass_inbound/lib/mailglass_inbound/ingress/providers/ses.ex`
- **Risk:** A client-side KMS-encrypted S3 object returns ciphertext the Elixir gateway cannot decrypt.
- **Why acceptable:** Out of scope per D-46-18; adopters are directed to bucket-level SSE (Phase 50 setup
  doc). Ciphertext is not a crash vector.
- **Fallback verified in code:** `ses.ex:88-93` — `MIME.parse/1` never raises; on `{:error, _mime_error}`
  the body degrades to an empty-field record while the raw bytes still land in tenant-scoped evidence
  (`ses.ex:117-127`). Documented at `ses.ex:33-38`.
- **Owner / revisit:** revisit if client-side KMS support is requested (tracked for Phase 50+).

---

## Unregistered Flags

The phase SUMMARY files do not contain a `## Threat Flags` section. The code review (`46-REVIEW.md`)
surfaced 2 BLOCKER + 6 WARNING findings during implementation; all 8 are marked resolved and were
independently re-confirmed in code during this audit. Two intersect declared threats directly and were
checked as part of verification:

- **CR-02** (S3FetchError escaping the plug rescue) — strengthens T-46-03/T-46-24. Confirmed fixed:
  `plug.ex:151-157` adds the explicit `S3FetchError` rescue mapping `:s3_object_not_ready`→500 and
  `:s3_fetch_failed`→422 with PII-free stop-meta. Without this fix T-46-03's "no uncontrolled 500"
  guarantee would have a hole.
- **CR-01** (concurrent fingerprint dedupe race) — strengthens T-46-13. Confirmed fixed:
  `persist.ex:91-105` `resolve_fingerprint_race` + `:312-317` `fingerprint_constraint?` collapse a
  concurrent duplicate to a clean `:duplicate` instead of an unhandled `Postgrex.Error`.

No new attack surface appeared that lacks a threat mapping. No `unregistered_flag` recorded.

---

## Notes

- Implementation files were treated as READ-ONLY; this audit created only this SECURITY.md.
- The public-facing GitHub security policy at the repo-root `SECURITY.md` was NOT modified — this is the
  phase-scoped audit artifact and accepted-risks log.
- `T-46-22` register text says hijack → `:subscribe_url_untrusted`. Core `dispatch_message_type` (private)
  raises core `:bad_signature` for outbound; the inbound provider implements its own control-plane guard
  (`ses.ex:166-179`) that raises the inbound `:subscribe_url_untrusted` directly — so the inbound mitigation
  matches the register exactly.
