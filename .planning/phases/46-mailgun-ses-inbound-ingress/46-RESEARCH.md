# Phase 46: Mailgun + SES Inbound Ingress - Research

**Researched:** 2026-05-23
**Domain:** Cross-package webhook verifier reuse (Elixir/Phoenix) — Mailgun HMAC multipart + SES SNS X.509 + S3 MIME fetch, normalized into `%MailglassInbound.InboundMessage{}`
**Confidence:** HIGH (all code anchors read against live tree; all external versions verified on Hex; the one remaining LOW is the precise `ExAws.request` body-map key set, mitigated below)

## Summary

This is a **gap-fill + anchor-verification** research pass on top of an unusually complete CONTEXT.md (20 locked decisions, assumptions mode). I read every code anchor CONTEXT.md cites in both packages. **Verdict: the architecture in CONTEXT.md is sound and the anchors are accurate, with three drifts the planner must account for** (a Postmark-suffixed-but-generic dedupe index, the SendGrid-scoped fingerprint index, and the `optional_deps/oban.ex` anchor that is actually inside `optional_deps.ex`). The single most consequential finding flips the calculus on two CONTEXT discretion points in the planner's favor:

1. **The widened result contract already exists, verbatim, in core's webhook plug.** `lib/mailglass/webhook/plug.ex` (lines 125-161) already dispatches a three-variant `verify!` return — `{:ok, :replay}` → 200 no-op, `{:ok, :control_plane, outcome}` → 200 no-op, `:ok` → proceed. Core's `Mailgun.verify!/3` returns `:ok | {:ok, :replay}`; core's `SES.verify!/3` returns `:ok | {:ok, :control_plane, :subscription_confirmed | :unsubscribe_confirmed}`. **The inbound plug is the one that lags** — it treats `verify!`'s return as a `verification_facts` map merged into evidence and has NO replay/control-plane branch. The recommended widened tuple is therefore not invented — it is the core shape, extended with a facts-carrying success variant: `{:ok, facts} | {:replay} | {:control_plane, status}`.

2. **The shared-primitive extraction (D-46-01) vs. reimplement-in-inbound (the override) is decided by reading the two `verify!` bodies.** Core's Mailgun `verify!/3` is structurally inseparable from `Jason.decode` (line 26 `decode_payload!` runs first, then `fetch_signature_fields!` expects a nested `%{"signature" => %{...}}` object — the exact shape Mailgun *inbound* does NOT send). Core's SES `verify!/3` is the opposite: the SNS envelope is byte-identical inbound vs outbound, so the X.509 path is reusable nearly whole — only the post-verify `dispatch_message_type` (which auto-confirms / no-ops) is what inbound needs to drive differently. **Recommendation: extract for SES (the envelope-verify is genuinely shared), reimplement the ~15-line HMAC for Mailgun (the JSON-coupled core path resists clean extraction without churning v1.x-stable outbound code).** This is a split decision, justified per-provider below.

The phase ships two providers, two new closed-type errors (`MailglassInbound.SignatureError`, `MailglassInbound.S3FetchError`), one new optional-dep gateway (`MailglassInbound.OptionalDeps.ExAwsS3`), and `:ex_aws`/`:ex_aws_s3` as the first optional runtime deps since the v1.0 STACK lock.

**Primary recommendation:** Mirror core's three-variant `verify!`-return `case` in the inbound plug's `do_call/2`; reuse SES's `CertCache`/`TrustPolicy`/X.509-verify by extracting an envelope-verify seam; reimplement Mailgun's flat-field HMAC + `MailgunReplayCache.check_and_put/2` directly in the inbound Mailgun provider; route S3 fetch through a new inbound-local `OptionalDeps.ExAwsS3` gateway mirroring `Mailglass.OptionalDeps.GenSmtp` exactly.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions (D-46-01 .. D-46-20)
- **D-46-01:** Reuse core webhook verification; extract shape-agnostic primitives. Mailgun = HMAC-SHA256 over `timestamp <> token` + `MailgunReplayCache.check_and_put/2` + timestamp-skew. SES = SNS X.509 verify path returning verified `Message`.
- **D-46-02:** Reuse already-running GenServers (`MailgunReplayCache`, `SES.CertCache`) owned by **core's** supervision tree. Inbound deps `{:mailglass, path: ".."}` so the OTP app boots them; `:ets` ops are global. **Inbound must NOT add these supervisors to `MailglassInbound.Application`** (CLAUDE.md #8 — no second singleton). `CertCache` + `TrustPolicy` are pure/URL-keyed, called directly.
- **D-46-03:** Leave outbound's `Jason.decode` + `%Event{}` normalization untouched (v1.x-stable). Only crypto/cache primitives factored out; inbound supplies its own payload extraction (multipart for Mailgun, SNS-envelope for SES).
- **D-46-04:** Boundary Credo check (`NoBareOptionalDepReference`) is path-scoped; inbound aliasing `Mailglass.Webhook.Providers.*` is not flagged. Keep cross-package calls explicit; confirm no compile-time cycle.
- *Override (D-46-01):* reuse caches + `TrustPolicy` and **reimplement ~15-line HMAC inside inbound**, leaving core `verify!/3` intact. Default is extraction.
- **D-46-05:** Extend `ingress/plug.ex` allowlist to `[:postmark, :sendgrid, :mailgun, :ses]` as ONE `init/1` guard + ONE `provider_module/1` switch — not two parallel pipelines.
- **D-46-06:** Widen the provider/plug result contract. Three-variant return in one `do_call/2` `case`: `{:ok, verification_facts}` → persist; `{:control_plane, http_status}` → SES `SubscriptionConfirmation`/`UnsubscribeConfirmation` → 200 no-op, no `InboundRecord`; `{:replay}` → Mailgun replay → 200 no-op, no second `InboundRecord`. Replay/control-plane are **200 no-ops, never `SignatureError`/401** (providers retry-storm on non-200; mirrors outbound D-15-05).
- **D-46-07:** The `Ingress.Provider` behaviour `verify!` callback widens. Trend toward one `verify!(%Request{}, config)` shape all four migrate to; exact tuple is planner discretion provided the three outcomes are expressible and `verify!`'s return is consumed (not discarded at `plug.ex:241-247`).
- **D-46-08:** Mailgun inbound routes POST `application/x-www-form-urlencoded` (multipart only with attachments). HMAC triple = **top-level form fields** `timestamp`, `token`, `signature` (NOT the nested JSON object outbound uses). Same HMAC algorithm.
- **D-46-09:** Support both modes; raw-MIME opt-in by **route URL suffix** (`…/mime` or `…/raw-mime`), not action type. Raw-MIME (`body-mime` present): route through `MailglassInbound.MIME.parse/1`. Parsed (default): normalize from `body-plain`/`body-html`/`stripped-*` + `message-headers` + attachments.
- **D-46-10:** Dedupe `provider_message_id` = RFC `Message-Id` header. Mailgun has no flat `Message-Id` field — extract from `message-headers` JSON ordered list (case-insensitive) in parsed mode, or raw headers in MIME mode. `token` is the **replay nonce**, never dedupe. No `Message-Id` → MD5(raw) fingerprint fallback (mirror SendGrid `persist.ex:81-101`). Dedupe anchor `(tenant_id, provider, provider_message_id)`.
- **D-46-11:** Persist raw source to `inbound_evidence` (MGUN-03); attachments follow existing pattern. Raw capture via existing `CachingBodyReader`.
- **D-46-12:** S3 action is the **primary path**. `receipt.action.type == "S3"` → `bucketName` + `objectKey` (`objectKey == mail.messageId`). SNS-inline `content` (≤150 KB) is a secondary small-message path.
- **D-46-13:** New behaviour `MailglassInbound.S3Fetcher`: `@callback fetch(bucket, key, opts) :: {:ok, binary()} | {:error, term()}`. `.Fake` ships in inbound core as test default (config-seam resolved, mirror SES `httpc_client`). `.ExAwsS3` gates through new inbound-local `OptionalDeps.ExAwsS3`.
- **D-46-14:** Gateway placement **inbound-local**, NOT core. `MailglassInbound.OptionalDeps` is the precedent; `OptionalDeps.Oban` is working precedent. **SESI-04's literal "`Mailglass.OptionalDeps.ExAwsS3`" is an erratum** — consumer lives in inbound; core's `NoBareOptionalDepReference` is `lib/mailglass/`-scoped. Mirror GenSmtp: `@compile {:no_warn_undefined, [ExAws, ExAws.S3]}` + `available?/0` + degraded fallback; keep `--no-optional-deps --warnings-as-errors` green.
  - *Override:* place in core per literal REQ — only as a documented reversal. Default inbound-local.
- **D-46-15:** Fetch = `ExAws.S3.get_object(bucket, key) |> ExAws.request/1` → `{:ok, %{body: binary}}`; feed `body` into `MIME.parse/1`. Deps `{:ex_aws, "~> 2.7"}` + `{:ex_aws_s3, "~> 2.5"}`. Adopters also add `:sweet_xml`, an HTTP client (`:hackney ~> 4.0` or `:req`), `:jason`. Creds via ex_aws standard chain (env → pod-identity → instance/task role), no mailglass-specific config.
- **D-46-16:** SESI-05 reframed: S3 has strong read-after-write since Dec 2020; SES publishes SNS after PutObject. Real driver = **idempotency on `objectKey`/`messageId` + SNS at-least-once redelivery**, NOT eventual consistency. Implement only a **small bounded GetObject retry** (~2-3 attempts, 250ms→1s→2s); on exhaustion **do not ack** so SNS redelivers; dedupe is the safety net.
- **D-46-17:** Surface S3-fetch failure as new inbound-local closed-type `MailglassInbound.S3FetchError` with `:type` set `[:s3_object_not_ready, :s3_fetch_failed]`, following `MailglassInbound.MIMEError` shape + `__types__/0` discipline. Do NOT bolt onto core errors.
- **D-46-18:** Scope-out — document, don't solve: SES client-side KMS encryption (a plain `GetObject` returns ciphertext). Document: use S3 action **without** SES client-side KMS (bucket-level SSE instead).
- **D-46-19:** `MailglassInbound.SignatureError` is net-new. Mirrors outbound no-recovery contract (CLAUDE.md #5 / D-22). Raises on forged Mailgun HMAC, forged SES SNS signature, hijacked/failed-`TrustPolicy` `SubscribeURL`. Closed `:type` set + `@since` + CHANGELOG + `__types__/0` test.
- **D-46-20:** `:ex_aws` / `:ex_aws_s3` is the first new optional runtime dep since the v1.0 STACK lock ("Optional deps: Add none"). Deliberate, noted departure recorded in phase decision record / CHANGELOG.

### Claude's Discretion
- Exact module names/signatures of extracted shared verification primitives; whether they live in a new neutral core module vs reused `Webhook.Providers.*`.
- Exact widened-result tuple shape (provided three outcomes expressible + return consumed).
- Exact `S3Fetcher` config-resolution key + `Fake` behavior surface.
- Exact bounded-retry counts/backoff for D-46-16 within "small".
- Exact internal representation of normalized Mailgun parsed-mode fields.

### Deferred Ideas (OUT OF SCOPE)
- Mailgun + SES setup guides (route URL, key rotation, SNS topic, IAM, S3 bucket, dep snippet) → MGUN-05 / SESI-06 → Phase 50.
- SES client-side KMS-encrypted object decryption → documented constraint, not built.
- Streaming very large S3 objects (`ExAws.S3.download_file/3`) — `get_object` into memory fine for the SES cap; revisit on scale.
- Cloudflare Email Routing, `gen_smtp` SMTP listener — different transport class; future milestone.
- Ingress rate limiting, `inbound.doctor`, admin LiveView → Phases 48/49.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description (REQUIREMENTS.md) | Research Support |
|----|------------------------------|------------------|
| MGUN-01 | `MailglassInbound.Ingress.Providers.Mailgun` plug verifies HMAC-SHA256 timestamp+token and rejects forged by raising `MailglassInbound.SignatureError` (no recovery) | Core HMAC math (`mailgun.ex:29-31`) reimplemented over flat form fields; new inbound error (D-46-19); plug rescue must catch the new error — see Anchor Drift #4. |
| MGUN-02 | Mailgun ingress reuses existing `MailgunReplayCache` ETS table (or aliases its supervisor/owner) to prevent replay | `MailgunReplayCache.check_and_put/2` (`mailgun_replay_cache.ex:9`) is a module fn over a global ETS table booted by core's supervisor — call directly, do NOT re-supervise (D-46-02). Returns `:ok | {:error, :replay}`. |
| MGUN-03 | Mailgun ingress normalizes multipart into `%InboundMessage{}` and persists raw source to `inbound_evidence` | Parsed-mode field map (D-46-09) + raw via `CachingBodyReader`; evidence row schema confirmed (`inbound_evidence.ex`). |
| MGUN-04 | `ingress/plug.ex` allowlist extended to recognize Mailgun provider key | `init/1` guard `plug.ex:36`, `provider_module/1` `plug.ex:372-373` — one switch (D-46-05). |
| SESI-01 | `MailglassInbound.Ingress.Providers.SES` verifies SNS X.509 via existing `CertCache` + `TrustPolicy` (URL allowlist prevents hijack) | `SES.verify!/3` X.509 path (`ses.ex:55-110`) + `CertCache.fetch_public_key/1` + `TrustPolicy.valid_cert_url?/1` reusable as-is. |
| SESI-02 | SES auto-confirms `SubscriptionConfirmation` when SubscribeURL passes TrustPolicy | `dispatch_message_type("SubscriptionConfirmation",...)` (`ses.ex:139-174`) reusable; control-plane outcome surfaced via widened contract (D-46-06). |
| SESI-03 | `MailglassInbound.S3Fetcher` behaviour defines S3 MIME-fetch contract for `Action: S3` | New behaviour (D-46-13). |
| SESI-04 | `S3Fetcher.Fake` in core; `S3Fetcher.ExAwsS3` behind `Mailglass.OptionalDeps.ExAwsS3` (new gateway, mirror `OptionalDeps.GenSmtp`) | **Erratum** — gateway is inbound-local `MailglassInbound.OptionalDeps.ExAwsS3` (D-46-14). |
| SESI-05 | SES handles message-id race (SNS before S3 consistency) with bounded retry + structured error | Reframed (D-46-16): bounded GetObject retry + `S3FetchError`; idempotency on messageId is the real safety net. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Mailgun HMAC verify | API/Backend (inbound provider) | core crypto (`:crypto.mac`) | Signature math is backend; flat-field extraction is inbound-specific. |
| Mailgun replay guard | core ETS GenServer (running) | inbound caller | Singleton owned by core's supervision tree (D-46-02); inbound calls the module fn only. |
| SES SNS X.509 verify | core (`SES` envelope-verify) | inbound caller | Envelope byte-identical inbound/outbound; reuse the verify, drive dispatch differently. |
| SES cert cache + trust policy | core ETS / pure module (running) | inbound caller | URL-keyed, process-global; call directly. |
| SES S3 MIME fetch | inbound `S3Fetcher` behaviour | `OptionalDeps.ExAwsS3` → ExAws | Network I/O to adopter's bucket; optional dep, fake-first. |
| MIME parse (raw → repr) | inbound `MailglassInbound.MIME` (Phase 45) | `OptionalDeps.GenSmtp` (core gateway) | First consumer of Phase-45 producer; never-raises seam. |
| Normalize → `%InboundMessage{}` | inbound provider | — | Provider-specific, package-internal & sealed. |
| Dedupe + persist | inbound `Ingress.Persist` | Postgres unique index | `(tenant_id, provider, provider_message_id)` anchor + MD5 fallback. |
| Result-contract dispatch (persist/replay/control-plane) | inbound `Ingress.Plug.do_call/2` | — | Widened `case` mirrors core webhook plug. |

## Standard Stack

### Core (already present — reuse, do not re-add)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `:crypto` (OTP) | OTP 27 | `:crypto.mac(:hmac, :sha256, key, ts<>token)` | Native; outbound already uses it (`mailgun.ex:30`). [VERIFIED: codebase] |
| `:public_key` (OTP) | OTP 27 | SES X.509 cert decode + `verify/4` | Native; outbound SES uses it (`ses.ex:104,294-304`). [VERIFIED: codebase] |
| `Plug.Crypto` | (Plug 1.18) | `secure_compare/2` constant-time HMAC compare | Outbound uses it (`mailgun.ex:126`). [VERIFIED: codebase] |
| `:gen_smtp` (`:mimemail`) | ~> 1.3, optional | MIME decode behind `MailglassInbound.MIME.parse/1` | Already optional dep + gateway (`mix.exs:76`). [VERIFIED: codebase] |

### Supporting (NEW optional deps — the v1.0 STACK departure, D-46-20)
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `:ex_aws` | ~> 2.7 (latest 2.7.0, 2026-05-06) | AWS request signing + credential chain | `S3Fetcher.ExAwsS3` only. [VERIFIED: Hex registry] |
| `:ex_aws_s3` | ~> 2.5 (latest 2.5.9, 2025-12-09) | `ExAws.S3.get_object/3` operation builder | `S3Fetcher.ExAwsS3` only. [VERIFIED: Hex registry] |
| `:sweet_xml` | ~> 0.7 (latest 0.7.5) | XML parsing ex_aws_s3 needs at runtime | **Adopter installs** — the non-obvious one. [VERIFIED: Hex registry] [CITED: hexdocs.pm/ex_aws_s3] |
| `:hackney` | ~> 4.0 (latest 4.0.0, 2026-04-16) **or** `:req` | HTTP client ex_aws needs at runtime | **Adopter installs** — ex_aws has no default client. [VERIFIED: Hex registry] [CITED: github.com/ex-aws/ex_aws] |
| `:jason` | (already present) | ex_aws JSON codec + SNS/`message-headers` decode | Already a transitive dep. [VERIFIED: codebase] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| extract Mailgun HMAC from core | reimplement ~15 lines in inbound | **Recommended** — core path is JSON-coupled (see Architecture Pattern 1). |
| extract SES verify from core | reimplement X.509 in inbound | Reject — duplicates ~60 lines of security-critical crypto; envelope is identical. |
| `:hackney` | `:req` | Either works; `:req` is more modern but adopter's choice. Document both. |
| `get_object` into memory | `ExAws.S3.download_file/3` streaming | Deferred (D-46 deferred) — `get_object` fine for the 40 MB SES cap. |

**Installation (inbound `mix.exs`, optional):**
```elixir
{:ex_aws, "~> 2.7", optional: true},
{:ex_aws_s3, "~> 2.5", optional: true}
```
Adopters using the real `S3Fetcher.ExAwsS3` additionally add `:sweet_xml`, an HTTP client (`:hackney` or `:req`), and `:jason` to **their** deps (Phase-50 setup doc; captured here for the gateway + `no_warn_undefined` list).

**Version verification (run at plan time to confirm currency):**
```bash
# all verified 2026-05-23 against Hex:
# ex_aws 2.7.0 | ex_aws_s3 2.5.9 | sweet_xml 0.7.5 | hackney 4.0.0
```

## Package Legitimacy Audit

| Package | Registry | Age | Source Repo | Disposition |
|---------|----------|-----|-------------|-------------|
| `ex_aws` | Hex (hex.pm/packages/ex_aws) | mature (2.7.0, 2026-05-06) | github.com/ex-aws/ex_aws | Approved [VERIFIED: Hex] |
| `ex_aws_s3` | Hex | mature (2.5.9, 2025-12-09) | github.com/ex-aws/ex_aws_s3 | Approved [VERIFIED: Hex] |
| `sweet_xml` | Hex | mature (0.7.5, 2025-01-07) | github.com/kbrw/sweet_xml | Approved [VERIFIED: Hex] |
| `hackney` | Hex | mature (4.0.0, 2026-04-16) | github.com/benoitc/hackney | Approved [VERIFIED: Hex] |

**Packages removed due to slopcheck [SLOP] verdict:** none.
**Packages flagged as suspicious [SUS]:** none.

> slopcheck CLI was not available in this Elixir/Hex environment (it targets npm/PyPI). All four packages are long-established, widely-used Hex packages with active GitHub repos and were verified directly against the Hex registry API (versions + publish dates above). They are part of the canonical Elixir AWS toolchain; risk is minimal. The planner may still gate the optional-dep additions behind a normal review since they are the first STACK-lock departure (D-46-20).

## Anchor Verification Report (the verify-the-anchors deliverable)

All CONTEXT.md code anchors were read against the live tree. Results:

### Accurate anchors (confirmed exist with assumed signatures)
| Anchor | Confirmed |
|--------|-----------|
| `lib/mailglass/webhook/providers/mailgun.ex` `verify!/3` | ✅ `verify!(raw_body, _headers, %{}=config) :: :ok \| {:ok, :replay}`. **Confirms the central trap**: `decode_payload!` (line 26) runs `Jason.decode` FIRST, then `fetch_signature_fields!` (line 96) expects nested `%{"signature" => %{...}}` — the outbound shape, NOT inbound's flat fields. Calling this wholesale on a Mailgun *inbound* multipart body raises `SignatureError(:malformed_header)` on every authentic request. |
| `mailgun_replay_cache.ex` | ✅ `check_and_put(token, %DateTime{}) :: :ok \| {:error, :replay}` over global ETS `:mailglass_webhook_mailgun_replay_cache`. Also `reset/0`, `table/0`. |
| `ses.ex` | ✅ `verify!/3 :: :ok \| {:ok, :control_plane, :subscription_confirmed \| :unsubscribe_confirmed}`. `dispatch_message_type/3` (line 137) handles all three SNS types. `httpc_client/1` config-resolution (line 351) is the config-map-then-app-env pattern to mirror for `S3Fetcher`. |
| `ses/cert_cache.ex` | ✅ `fetch_public_key(url) :: {:ok, term} \| :miss`, `put/3`, `reset/0`, `table/0`. |
| `ses/cert_cache/supervisor.ex` + `table_owner.ex` | ✅ exist, supervise the ETS owner. |
| `ses/trust_policy.ex` | ✅ pure `valid_cert_url?/1`, `valid_subscribe_url?/1` (https-only, SNS-host regex). |
| `lib/mailglass/application.ex` | ✅ supervises both caches via `maybe_add` + `Code.ensure_loaded?` (lines 31-38). Confirms D-46-02: caches boot when the `:mailglass` OTP app starts. |
| `lib/mailglass/errors/signature_error.ex` | ✅ no-recovery (`retryable?/0 → false`), closed `@types` (7 + 3 legacy), `__types__/0`, `@derive Jason.Encoder only [:type,:message,:context]`. The exact template for `MailglassInbound.SignatureError`. |
| `lib/mailglass/optional_deps/gen_smtp.ex` | ✅ `@compile {:no_warn_undefined, [:gen_smtp_client, :mimemail]}` + `available?/0` (`Code.ensure_loaded?`) + never-raise `decode/2`. The exact gateway template for `ExAwsS3`. |
| inbound `ingress/{plug,provider,request,caching_body_reader}.ex` | ✅ all exist. |
| inbound `ingress/persist.ex` | ✅ dedupe + fingerprint fallback at lines 81-116, 201-217. |
| inbound `ingress/providers/{postmark,sendgrid}.ex` | ✅ SendGrid is the raw-MIME precedent. |
| inbound `inbound_message.ex`, `inbound_records/{inbound_record,inbound_evidence,replay_run,execution_run}.ex` | ✅ all exist. |
| inbound `mime.ex`, `mime_error.ex` | ✅ `MIME.parse/1 :: {:ok, repr} \| {:error, MIMEError.t()}` (never raises); `MIMEError` closed `@types [:inbound_mime_invalid, :gen_smtp_unavailable]` + `__types__/0`. |
| inbound `application.ex` | ✅ only `Task.Supervisor` child — confirms caches are NOT (and must not be) re-supervised here. |
| inbound `mix.exs` | ✅ `{:mailglass, path: ".."}` (line 88), gen_smtp optional, project-level `no_warn_undefined` list (line 57). |
| `.credo.exs` | ✅ `NoBareOptionalDepReference` `included_path_prefixes` widened to `["lib/mailglass/", "mailglass_inbound/lib/"]` (line 60). |

### Anchor DRIFT the planner MUST account for
1. **`optional_deps/oban.ex` anchor is wrong.** CONTEXT.md cites `mailglass_inbound/lib/mailglass_inbound/optional_deps/oban.ex` — that file does NOT exist. `MailglassInbound.OptionalDeps.Oban` lives **inside** `optional_deps.ex` (same file, second module, lines 12-71). The planner should create `MailglassInbound.OptionalDeps.ExAwsS3` either in the same `optional_deps.ex` file or a new `optional_deps/ex_aws_s3.ex` — both are fine; just don't expect an existing `oban.ex` to mirror.
2. **The dedupe index is generic despite its name.** Migration `20260506180000` creates `unique_index(:mailglass_inbound_records, [:tenant_id, :provider, :provider_message_id], where: "provider_message_id IS NOT NULL", name: :mailglass_inbound_records_postmark_idempotency_idx)`. The **columns are provider-agnostic** — Mailgun records with a non-nil `provider_message_id` (the Message-Id) dedupe automatically through this same index. **No new migration is needed for the Mailgun Message-Id dedupe path.** `persist.ex:194-199` `duplicate_constraint?/1` already matches this exact constraint name, so a Mailgun unique-violation on insert is caught and converted to a `:duplicate` (the constraint-name check works for any provider hitting this index).
3. **The fingerprint fallback index is SendGrid-scoped — needs a Mailgun sibling.** Migration `20260506220000` creates the MD5 fingerprint unique index with `where: "provider = 'sendgrid' AND raw_mime_fingerprint IS NOT NULL"`. Mailgun's MD5(raw) fallback (D-46-10) is NOT covered. **The planner needs a new migration** adding either (a) a Mailgun-scoped partial unique index `where: "provider = 'mailgun' AND raw_mime_fingerprint IS NOT NULL"`, or (b) a generalized predicate. Also note `persist.ex:81` `load_duplicate/5` only special-cases `"sendgrid"` for the fingerprint path — a Mailgun clause (or a generalized "no provider_message_id → fingerprint" clause) must be added.
4. **The inbound plug rescues CORE's `Mailglass.SignatureError`, not a `MailglassInbound.SignatureError`.** `plug.ex:28` aliases `Mailglass.{ConfigError, SignatureError, ...}` and `plug.ex:115` `rescue e in SignatureError` catches core's. Existing inbound providers (Postmark/SendGrid) raise **core's** `Mailglass.SignatureError` (`postmark.ex:8,79`; `sendgrid.ex:6,88`). D-46-19 introduces a **net-new** `MailglassInbound.SignatureError`. **This is a real decision the planner must make** (see Open Question 1): either (a) Mailgun/SES raise the new inbound error and the plug rescues BOTH error structs, or (b) the plug rescues only the new inbound error and Mailgun/SES raise it while Postmark/SendGrid keep raising core's (plug rescues both anyway), or (c) migrate all four to the new error. Recommendation in Open Question 1.
5. **`plug.ex:241-247` does NOT discard `verify!`'s return.** CONTEXT.md says the return "is currently discarded." Actually `verify_request!/3` (lines 241-247) returns the provider's `verify!` value into `verification_facts` (line 57), which is merged into evidence (line 286). The accurate framing: **the current contract can only express a facts-map; it cannot express replay/control-plane no-ops.** The widening is about adding variants, not about consuming a discarded value.

## Architecture Patterns

### System Architecture Diagram

```
                         POST /inbound/:tenant/:provider[/mime]
                                       │
                          CachingBodyReader captures raw bytes
                          → conn.private[:raw_body]; Plug.Parsers
                          sets conn.params (urlencoded/multipart)
                                       │
                       ┌──────── Ingress.Plug.do_call/2 ────────┐
                       │   build_request! (per-provider seam)    │
                       │   resolve_config! (per-provider seam)   │
                       └────────────────┬───────────────────────┘
                                        │  verify!(%Request{}, config)   ← ONE switch (D-46-05)
                  ┌─────────────────────┼─────────────────────────────┐
            :mailgun                 :ses                     :postmark/:sendgrid
                  │                     │                              │
   flat-field HMAC over            decode SNS envelope          basic-auth (unchanged)
   timestamp<>token                → TrustPolicy.valid_cert_url? → returns {:ok, facts}
   secure_compare + skew           → CertCache.fetch_public_key
                  │                 → :public_key.verify (REUSE core seam)
   MailgunReplayCache              → dispatch on MessageType:
   .check_and_put/2                   Notification → continue
                  │                   Subscription/Unsubscribe →
        ┌─────────┴────────┐            auto-confirm via TrustPolicy
   :ok →{:ok,facts}  {:error,:replay}   → {:control_plane, 200}
        │             →{:replay}
        │                                Notification:
        │                              ┌─ Action S3 → S3Fetcher.fetch
        │                              │   (OptionalDeps.ExAwsS3 → ExAws,
        │                              │    bounded retry, S3FetchError)
        │                              └─ inline content (≤150KB) → use directly
        │                                        │
                              ┌────────── widened result case (D-46-06) ──────────┐
                              │ {:ok, facts}      → normalize → persist → dispatch │
                              │ {:replay}         → 200 no-op (no InboundRecord)   │
                              │ {:control_plane,s}→ 200 no-op (no InboundRecord)   │
                              │ raise SignatureError → 401, no recovery            │
                              └────────────────────────┬──────────────────────────┘
                                                       │ {:ok, facts} branch
                       raw-MIME mode (…/mime suffix): MailglassInbound.MIME.parse/1
                       parsed mode: field map from body-plain/html + message-headers
                                                       │
                       normalize → %InboundMessage{}; dedupe (tenant,provider,Message-Id)
                       or MD5(raw) fallback → Persist (canonical row + evidence row,
                       one transaction) → mailbox dispatch → 200
```

### Recommended Project Structure (new/changed files)
```
mailglass_inbound/lib/mailglass_inbound/
├── ingress/
│   ├── plug.ex                      # WIDEN: allowlist + do_call/2 result case
│   ├── provider.ex                  # WIDEN: verify! callback return type
│   └── providers/
│       ├── mailgun.ex               # NEW: flat-field HMAC + replay + multipart normalize
│       └── ses.ex                   # NEW: SNS envelope verify (reuse core seam) + S3 fetch
│   └── persist.ex                   # EDIT: add Mailgun dedupe/fingerprint clause
├── signature_error.ex              # NEW: closed-type, no-recovery (mirror MIMEError)
├── s3_fetch_error.ex               # NEW: closed-type [:s3_object_not_ready, :s3_fetch_failed]
├── s3_fetcher.ex                   # NEW: behaviour @callback fetch/3
├── s3_fetcher/
│   ├── fake.ex                      # NEW: test default (fake-first)
│   └── ex_aws_s3.ex                 # NEW: real adapter via gateway
├── optional_deps.ex                # EDIT: add OptionalDeps.ExAwsS3 module (or new file)
mailglass_inbound/priv/repo/migrations/
└── <ts>_add_mailgun_fingerprint_index.exs   # NEW: Mailgun MD5 fallback dedupe
.credo.exs                          # EDIT: add ExAws => MailglassInbound.OptionalDeps.ExAwsS3 to gated_modules
```

### Pattern 1: Mailgun HMAC — reimplement, do NOT extract (the override wins here)
**What:** Reimplement the ~15-line HMAC verify in the inbound Mailgun provider over flat form fields.
**Why this over D-46-01 extraction:** Core's `Mailgun.verify!/3` interleaves three concerns that cannot be separated without churning v1.x-stable code: (1) `decode_payload!` (`Jason.decode` of the raw body), (2) `fetch_signature_fields!` (expects nested `%{"signature" => %{"timestamp"=>,"token"=>,"signature"=>}}`), (3) the actual HMAC math + skew + replay. Inbound's signature triple arrives as **flat form fields** (`conn.params["timestamp"]` etc., D-46-08), so concerns (1) and (2) are wrong for inbound. Only concern (3) is shared — and it is 6 lines. Extracting a `verify_hmac!(timestamp, token, signature, signing_key, opts)` neutral function from core *would* be clean, but it requires editing core's `verify!/3` to call the extracted fn — touching stable outbound. The override (reimplement in inbound, leave core untouched) has the smaller blast radius and is explicitly sanctioned by D-46-01's override clause.
**Example (the reusable core math, to reimplement over flat fields):**
```elixir
# Source: lib/mailglass/webhook/providers/mailgun.ex:29-37 (the shared math)
expected =
  :crypto.mac(:hmac, :sha256, signing_key, timestamp <> token)
  |> Base.encode16(case: :lower)

# constant-time, length-guarded:
Plug.Crypto.secure_compare(expected, String.downcase(provided))  # see mailgun.ex:124-129
# then verify_timestamp! (mailgun.ex:131-157) and:
MailgunReplayCache.check_and_put(token, expires_at)  # :ok | {:error, :replay}
```
Inbound provider extracts `timestamp`/`token`/`signature` from `request.params` (NOT from JSON), then runs the same three steps. On `{:error, :replay}` return `{:replay}` (200 no-op); on success return `{:ok, facts}`.

### Pattern 2: SES envelope verify — extract/reuse the core seam (D-46-01 holds here)
**What:** Reuse core's SNS X.509 verify, but drive the post-verify dispatch from inbound.
**Why this over reimplement:** The SNS envelope is byte-identical inbound vs outbound (`ses.ex` builds the canonical string from `Type/MessageId/Message/Timestamp/TopicArn` + control fields — `ses.ex:46-47,220-231`), and the verify is ~60 lines of security-critical crypto (cert URL trust-policy → `CertCache` → `:public_key.verify`). Reimplementing duplicates a security boundary. **Cleanest seam:** factor a function out of core's `verify!/3` that does steps 1-5 (decode → trust-policy → fetch key → canonical → `:public_key.verify`) and returns the verified payload `{:ok, payload}` WITHOUT calling `dispatch_message_type`. Inbound calls that seam, then drives its own dispatch:
- `Type == "Notification"` → continue to S3-fetch/inline-content extraction → `{:ok, facts}`.
- `Type in ["SubscriptionConfirmation","UnsubscribeConfirmation"]` → reuse `dispatch_message_type` (it already auto-confirms via `TrustPolicy` + constructs ConfirmSubscription from signed TopicArn+Token, `ses.ex:139-174`) → `{:control_plane, 200}`.

**Recommended seam shape (Claude's discretion per D-46-01):** add to `Mailglass.Webhook.Providers.SES` a public `verify_envelope!(raw_body, config) :: {:ok, sns_payload} | (raises SignatureError)` that core's own `verify!/3` also calls (refactor `verify!` to `verify_envelope!` then `dispatch_message_type`). This is a smaller, safer extraction than Mailgun's because it does NOT touch the JSON-coupled decode (the SNS body IS JSON, identically, both directions). If a plan-time read shows the refactor risks outbound regressions, fall back to inbound calling the existing `verify!/3` and inspecting its 3-tuple return — but that loses the `Notification`-payload (verify!`s `:ok` for Notification discards the decoded payload, so inbound would re-decode). The seam is the better path.

### Pattern 3: Widened result contract — mirror core webhook plug verbatim
**What:** Inbound `do_call/2` gets a `case` over the widened `verify!` return, exactly like core's plug.
**Source (the proven shape):**
```elixir
# Source: lib/mailglass/webhook/plug.ex:125-161 (core ALREADY does this)
case verify_with_telemetry!(provider, raw_body, headers, config) do
  {:ok, :replay}            -> send_resp(conn, 200, "")            # no-op
  {:ok, :control_plane, o}  -> send_resp(conn, 200, "")            # no-op
  :ok                       -> resolve_tenant! → normalize → ingest
end
```
**Recommended inbound widened tuple (Claude's discretion, D-46-07):**
```elixir
@callback verify!(Request.t(), config :: map()) ::
            {:ok, verification_facts :: map()}   # persist (carries facts for evidence)
          | {:replay}                            # Mailgun replay → 200 no-op
          | {:control_plane, http_status :: pos_integer()}  # SES control → 200 no-op
          # (forged input still RAISES SignatureError — not a tuple variant)
```
All four providers migrate to `verify!(%Request{}, config)`:
- Postmark/SendGrid: wrap their current `%{auth: :basic_auth, ...}` map return as `{:ok, facts}`.
- Mailgun: `{:ok, facts}` on success, `{:replay}` on cache hit.
- SES: `{:ok, facts}` on Notification, `{:control_plane, 200}` on Subscription/Unsubscribe.
The plug's `{:ok, facts}` branch keeps the existing tenant→normalize→persist→dispatch flow (with `facts` merged into evidence as today). `{:replay}` and `{:control_plane, _}` short-circuit to a 200 JSON no-op with PII-free telemetry stop-meta (`status: :replay` / `status: :control_plane`).

### Pattern 4: S3Fetcher behaviour + fake-first + gateway
**What:** Behaviour with a fake test default and a real adapter behind an inbound-local gateway.
```elixir
# Behaviour (D-46-13)
@callback fetch(bucket :: String.t(), key :: String.t(), opts :: keyword()) ::
            {:ok, binary()} | {:error, term()}

# Gateway — mirror Mailglass.OptionalDeps.GenSmtp EXACTLY (gen_smtp.ex:44-57)
defmodule MailglassInbound.OptionalDeps.ExAwsS3 do
  @compile {:no_warn_undefined, [ExAws, ExAws.S3]}
  def available?, do: Code.ensure_loaded?(ExAws.S3)
  # never-raise wrapper around: ExAws.S3.get_object(bucket, key) |> ExAws.request()
end

# Real adapter
def fetch(bucket, key, _opts) do
  case ExAwsS3Gateway.get_object(bucket, key) do
    {:ok, %{body: body}} when is_binary(body) -> {:ok, body}
    {:error, reason} -> {:error, reason}
  end
end
```
**Config seam (mirror SES `httpc_client/1`, `ses.ex:351-362):** resolve the fetcher module config-map-first then app-env, defaulting to `S3Fetcher.Fake` in test and `S3Fetcher.ExAwsS3` in prod.

### Pattern 5: Bounded S3 retry (D-46-16, SESI-05) — small, not a budget
```elixir
# ~2-3 attempts, short backoff; on exhaustion DO NOT ack (return error → 5xx → SNS redelivers)
defp fetch_with_retry(fetcher, bucket, key, attempts \\ [250, 1000, 2000])
# {:ok, body} on success; on exhaustion raise/return S3FetchError(:s3_object_not_ready)
# Real safety net is the dedupe layer on messageId — SNS at-least-once is the threat, not consistency.
```

### Anti-Patterns to Avoid
- **Calling core `Mailgun.verify!/3` wholesale on a multipart body.** It runs `Jason.decode` first and `SignatureError`s every authentic inbound request. (CONTEXT specifics, confirmed at `mailgun.ex:26,83-94`.)
- **Returning 401/`SignatureError` for replay or control-plane.** Providers retry-storm on non-200. Replay and SubscriptionConfirmation MUST be 200 no-ops (D-46-06; core does this at `plug.ex:126-146`).
- **Re-supervising `MailgunReplayCache`/`CertCache` in `MailglassInbound.Application`.** Second singleton (CLAUDE.md #8). The caches boot with core's OTP app.
- **Using the Mailgun `token` for dedupe.** It is the replay nonce, conceptually distinct from message identity (D-46-10). Use Message-Id (from `message-headers`).
- **Bolting `:inbound_s3_consistency_lag` onto core `Mailglass.Error`** (as ROADMAP line 101 loosely suggests). D-46-17 overrides: use net-new `MailglassInbound.S3FetchError`.
- **Adding `ex_aws` as a hard dep.** Optional only; gateway + `--no-optional-deps` lane must stay green.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| SNS X.509 verify | new RSA verify | extract/reuse core SES seam | 60 lines of security crypto already shipped + tested. |
| SNS cert caching | new ETS cache | running `SES.CertCache` (D-46-02) | Supervised, URL-keyed, process-global. |
| Mailgun replay guard | new ETS table | running `MailgunReplayCache.check_and_put/2` | Supervised, TTL-aware, returns `{:error, :replay}`. |
| SubscribeURL trust | new URL allowlist | `TrustPolicy.valid_subscribe_url?/1` | SSRF/hijack guard with the AWS-PHP-SDK host regex already written. |
| MIME decode | new parser | `MailglassInbound.MIME.parse/1` (Phase 45) | Never-raises, three-escape-mechanism gateway; this phase is its intended first consumer (`mime.ex:60-61`). |
| Constant-time compare | `==` on HMAC | `Plug.Crypto.secure_compare/2` | Timing-attack safe; outbound uses it. |
| AWS request signing | new signer | `ExAws.request/1` | Credential chain + SigV4 handled. |
| Result-contract dispatch | new pattern | mirror core `plug.ex:125-161` | The 3-variant `case` is proven in outbound. |

**Key insight:** This phase is almost entirely *plumbing existing, tested security primitives into a second entry point*. The only genuinely new code is: flat-field Mailgun extraction, the S3Fetcher behaviour+adapter+gateway, two closed-type errors, one migration, and the widened plug `case`. Everything cryptographic already exists.

## Runtime State Inventory

> This is a feature-addition phase (new providers), not a rename/refactor. No stored data, OS-registered state, or secrets are renamed. The only runtime-state-adjacent concerns:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | New `mailglass_inbound_records` / `_evidence` rows for `provider = 'mailgun'`/`'ses'`. Dedupe index `(tenant_id, provider, provider_message_id)` already covers them. | New migration for Mailgun MD5-fingerprint fallback index only (Anchor Drift #3). |
| Live service config | None added by this phase. (Adopter-side: SES SNS topic + receipt rule + S3 bucket — Phase 50 docs, not this phase.) | None — verified: inbound adds no external service config. |
| OS-registered state | None — verified: no scheduled tasks, no daemons added. | None. |
| Secrets/env vars | NEW config keys: `:mailglass_inbound, :mailgun, signing_key:` and `:mailglass_inbound, :ses, ...`; adopter AWS creds via ex_aws standard chain (no mailglass key). | Document in code; resolve via `resolve_config!` per-provider clauses. |
| Build artifacts | `:ex_aws`/`:ex_aws_s3` added to `mix.lock` (optional). | `mix deps.get` after mix.exs edit; verify `--no-optional-deps` lane. |

## Common Pitfalls

### Pitfall 1: Reusing the JSON-decode path for Mailgun inbound
**What goes wrong:** Authentic Mailgun inbound requests fail signature verification 100% of the time.
**Why it happens:** Core `Mailgun.verify!/3` decodes JSON and reads a nested `signature` object; inbound sends flat form fields with no JSON envelope.
**How to avoid:** Reimplement the HMAC over `conn.params["timestamp"]`/`["token"]`/`["signature"]` (Pattern 1).
**Warning signs:** Every test with a valid signature raises `:malformed_header`.

### Pitfall 2: Missing the control-plane no-op makes SES inbound silently never work
**What goes wrong:** SES sends `SubscriptionConfirmation` first; without a `{:control_plane, 200}` path the topic never activates and no email ever arrives.
**Why it happens:** The current inbound contract can only express persist-or-error.
**How to avoid:** Widen the contract (Pattern 3); auto-confirm via `TrustPolicy` then return `{:control_plane, 200}`.
**Warning signs:** SES console shows the subscription stuck "PendingConfirmation."

### Pitfall 3: Mailgun fingerprint dedupe has no index
**What goes wrong:** Mailgun messages without a Message-Id (rare but real) insert duplicates on SNS-style retries because the MD5 fallback has no unique constraint for `provider='mailgun'`.
**Why it happens:** The fingerprint index is `WHERE provider = 'sendgrid'` only (Anchor Drift #3).
**How to avoid:** Add a Mailgun-scoped (or generalized) partial unique index migration + a `load_duplicate/5` Mailgun clause.
**Warning signs:** Replayed no-Message-Id Mailgun payloads create two `InboundRecord`s.

### Pitfall 4: Two SignatureError structs, one rescue clause
**What goes wrong:** Mailgun/SES raise `MailglassInbound.SignatureError` but the plug only rescues `Mailglass.SignatureError` → the new error escapes as a 500 instead of a 401.
**Why it happens:** Existing providers raise core's error; the new error is a different struct (Anchor Drift #4).
**How to avoid:** Decide the error strategy (Open Question 1) and ensure the plug rescue covers whatever Mailgun/SES raise.
**Warning signs:** Forged Mailgun/SES → 500, not 401; `__types__/0` test passes but plug integration test fails.

### Pitfall 5: `--no-optional-deps --warnings-as-errors` lane breaks on bare ExAws ref
**What goes wrong:** CI's no-optional-deps lane fails because inbound code references `ExAws.S3` outside the gateway.
**Why it happens:** ExAws is optional; only the gateway may name it (with `@compile {:no_warn_undefined,...}`).
**How to avoid:** All ExAws access through `MailglassInbound.OptionalDeps.ExAwsS3`; add `ExAws`/`ExAws.S3` to the `.credo.exs` `gated_modules` map so `NoBareOptionalDepReference` flags strays.
**Warning signs:** `mix compile --no-optional-deps --warnings-as-errors` non-zero exit.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| S3 eventual consistency requires polling | S3 strong read-after-write | Dec 2020 (AWS) | D-46-16: don't build a consistency-retry budget; the threat is SNS at-least-once redelivery, not consistency. [CITED: AWS S3 consistency announcement] |
| ROADMAP: `Mailglass.Error{type: :inbound_s3_consistency_lag}` | `MailglassInbound.S3FetchError [:s3_object_not_ready, :s3_fetch_failed]` | CONTEXT D-46-17 | The CONTEXT decision supersedes the looser ROADMAP wording. |
| SESI-04 literal `Mailglass.OptionalDeps.ExAwsS3` | inbound-local `MailglassInbound.OptionalDeps.ExAwsS3` | CONTEXT D-46-14 | Documented erratum; planner uses inbound-local. |

**Deprecated/outdated:** none relevant to this phase's stack.

## Code Examples

### Mailgun inbound flat-field extraction
```elixir
# Inbound provider — extract from form params, NOT JSON
%{"timestamp" => ts, "token" => token, "signature" => sig} = request.params
expected = :crypto.mac(:hmac, :sha256, signing_key, ts <> token) |> Base.encode16(case: :lower)
unless Plug.Crypto.secure_compare(expected, String.downcase(sig)),
  do: raise MailglassInbound.SignatureError.new(:bad_signature, provider: :mailgun)
# ... verify_timestamp!, then MailgunReplayCache.check_and_put(token, expires_at)
```

### Message-Id from message-headers (parsed mode, D-46-10)
```elixir
# message-headers is a JSON-encoded ordered list: [["Message-Id","<...>"], ["From","..."], ...]
def extract_message_id(params) do
  with raw when is_binary(raw) <- params["message-headers"],
       {:ok, pairs} <- Jason.decode(raw) do
    Enum.find_value(pairs, fn [name, value] ->
      if String.downcase(name) == "message-id", do: value
    end)
  else
    _ -> nil  # → MD5(raw) fingerprint fallback
  end
end
```

### ExAws S3 fetch (via gateway)
```elixir
# Source: hexdocs.pm/ex_aws_s3 + github.com/ex-aws/ex_aws
ExAws.S3.get_object(bucket, key) |> ExAws.request()
# => {:ok, %{body: binary, headers: [...], status_code: 200}}  (extract :body)
```

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `ExAws.request` success map has key `:body` (binary) for `get_object` | Stack / D-46-15 | LOW — confirmed by community sources + module docs; verify in the Fake-vs-real test. If the key set differs, only `S3Fetcher.ExAwsS3` adapter changes (one line). [ASSUMED — docs vague on exact map] |
| A2 | Mailgun `message-headers` is a JSON array of `[name, value]` pairs | Code Examples / D-46-10 | MEDIUM — per Mailgun docs; the exact JSON shape (array-of-pairs vs object) should be confirmed against a real payload or the Mailgun receive-http doc when building fixtures. [ASSUMED] |
| A3 | Adopters must add `:sweet_xml` + HTTP client to THEIR deps (not transitively pulled) | Stack / D-46-15 | LOW — ex_aws explicitly leaves HTTP client + XML to the user; matches CONTEXT. [CITED: github.com/ex-aws/ex_aws] |
| A4 | The generic `_postmark_idempotency_idx` dedupes Mailgun Message-Id rows without a new migration | Anchor Drift #2 | LOW — verified columns are provider-agnostic; confirm with a Mailgun dedupe integration test. [VERIFIED: migration source] |

## Open Questions

1. **Which SignatureError struct do Mailgun/SES raise, and what does the plug rescue?**
   - What we know: existing inbound providers raise **core's** `Mailglass.SignatureError`; the plug rescues core's; D-46-19 mandates a **net-new** `MailglassInbound.SignatureError`.
   - What's unclear: whether to migrate all four providers or run two error structs.
   - **Recommendation:** Mailgun + SES raise the new `MailglassInbound.SignatureError` (satisfies D-46-19, MGUN-01, SESI-01 verbatim). The plug rescues **both** structs (`rescue e in [Mailglass.SignatureError, MailglassInbound.SignatureError]`) → both map to 401. Leave Postmark/SendGrid raising core's error untouched (smallest blast radius, no behavior change to shipped v1.1 providers). Document in `api_stability.md` that inbound now has its own signature error for inbound-specific failure modes. Do NOT migrate Postmark/SendGrid in this phase (out of scope, churns stable code).

2. **Where does the SES envelope-verify seam live — new core fn or inbound reimplementation?**
   - What we know: the SNS envelope is identical inbound/outbound; reimplementing duplicates security crypto.
   - **Recommendation:** Add `Mailglass.Webhook.Providers.SES.verify_envelope!/2` to core (returns `{:ok, sns_payload}`), refactor core's own `verify!/3` to call it then `dispatch_message_type`. Inbound calls `verify_envelope!` then drives its own dispatch. This is the D-46-01 "extract" path for SES (justified — see Pattern 2). If plan-time review judges the core refactor too risky for stable outbound, fall back to inbound calling existing `verify!/3` and re-decoding the Notification body (acceptable but slightly wasteful).

3. **Does the Mailgun `body-mime` route suffix need router-level wiring or plug-opt detection?**
   - What we know: D-46-09 routes raw-MIME by URL suffix (`…/mime`).
   - What's unclear: whether the plug detects the suffix from `conn.path_info` or the adopter passes `mode: :raw_mime` as a plug opt.
   - **Recommendation:** Detect presence of `params["body-mime"]` (the documented Mailgun signal) rather than relying on URL suffix parsing — more robust and aligns with the SendGrid `params["email"]` precedent (`plug.ex:198`). The URL-suffix is the adopter's *Mailgun-side* route config; mailglass should branch on the payload field. Confirm with the planner.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Erlang/OTP `:crypto` | Mailgun HMAC | ✓ | OTP 27 | — (mandatory, present) |
| Erlang/OTP `:public_key` | SES X.509 | ✓ | OTP 27 | — (mandatory, present) |
| `:gen_smtp`/`:mimemail` | `MIME.parse/1` (raw mode) | ✓ (optional, in lock) | ~> 1.3 | `MIMEError{:gen_smtp_unavailable}` degraded path already exists |
| `:ex_aws` + `:ex_aws_s3` | `S3Fetcher.ExAwsS3` (real S3 fetch) | ✗ (to be added optional) | 2.7 / 2.5 | `S3Fetcher.Fake` (test default) + SNS-inline `content` path for small msgs |
| `:sweet_xml`, HTTP client | adopter-side ex_aws runtime | ✗ (adopter installs) | 0.7 / hackney 4.0 | documented Phase-50 setup gap |
| Postgres (TestRepo) | dedupe index integration tests | ✓ | (CI Postgres job) | — |

**Missing dependencies with no fallback:** none block the phase — the real S3 path is gated optional; `S3Fetcher.Fake` + SNS-inline cover test + small-message paths.
**Missing dependencies with fallback:** `:ex_aws`/`:ex_aws_s3` (fallback: Fake adapter + inline-content path; real fetch is adopter-opt-in).

## Validation Architecture

> nyquist_validation is enabled (`config.json workflow.nyquist_validation: true`). This section feeds VALIDATION.md generation.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (Elixir 1.18) + StreamData (property) [VERIFIED: codebase] |
| Config file | `mailglass_inbound/test/test_helper.exs` (runs inbound migrations, starts `MailglassInbound.TestRepo` Sandbox `:manual`) |
| Quick run command | `cd mailglass_inbound && mix test test/mailglass_inbound/ingress/mailgun_provider_test.exs` (per-provider, fast) |
| Full suite command | `cd mailglass_inbound && mix test` (note: bare `mix test` in core worktree has ~57 unrelated Oban failures — scope to inbound) |
| Lint gate | `mix credo --strict` + `mix test test/mailglass/credo/` (run actual credo, not grep — per project memory) |
| Compile gate | `mix compile --no-optional-deps --warnings-as-errors` (MUST stay green — D-46-14) |

### Phase Requirements → Test Map (the critical signals to validate)
| Req | Behavior | Test Type | Automated Command | File Exists? |
|-----|----------|-----------|-------------------|--------------|
| MGUN-01 | authentic Mailgun → `{:ok,facts}` → persisted | integration | `mix test .../ingress/mailgun_provider_test.exs` | ❌ Wave 0 |
| MGUN-01 | **forged** Mailgun HMAC → `MailglassInbound.SignatureError` → 401, no record | integration | same file | ❌ Wave 0 |
| MGUN-01 | new error `__types__/0` matches `api_stability.md` | unit | `mix test .../signature_error_test.exs` | ❌ Wave 0 |
| MGUN-02 | **replayed** token → `{:replay}` → 200, no 2nd record; GenServer reused not duplicated | integration | mailgun_provider + plug_test | ❌ Wave 0 |
| MGUN-03 | multipart → `%InboundMessage{}` + raw in `inbound_evidence` | integration | mailgun_provider_test | ❌ Wave 0 |
| MGUN-03 | dedupe on Message-Id (parsed) AND MD5 fallback (no Message-Id) | integration (Postgres) | persist_test | ❌ Wave 0 |
| MGUN-04 | plug allowlist accepts `:mailgun` (one switch) | unit | plug_test | (extend existing) |
| SESI-01 | authentic SNS X.509 → verified; **forged** → SignatureError → 401 | integration | `.../ingress/ses_provider_test.exs` | ❌ Wave 0 |
| SESI-02 | `SubscriptionConfirmation` w/ valid SubscribeURL → `{:control_plane,200}`, no record; **hijacked URL** → rejected | integration | ses_provider_test | ❌ Wave 0 |
| SESI-03/04 | `S3Fetcher.Fake` is test default; `.ExAwsS3` gated; `available?/0` false w/o dep | unit | s3_fetcher_test + optional_deps_test | ❌ Wave 0 |
| SESI-05 | S3 fetch retry-then-`S3FetchError`; on exhaustion non-2xx (SNS redelivers); idempotency on messageId | integration | ses_provider_test (Fake returns :error first N) | ❌ Wave 0 |
| SESI-05 | `S3FetchError.__types__/0` matches `api_stability.md` | unit | s3_fetch_error_test | ❌ Wave 0 |
| (cross) | `mix compile --no-optional-deps --warnings-as-errors` green | CI gate | compile command above | (existing lane) |
| (cross) | `NoBareOptionalDepReference` flags bare ExAws refs | credo | `mix credo --strict` | (extend `.credo.exs`) |

### Sampling Rate (Nyquist)
- **Per task commit:** the touched provider's test file (`mix test .../mailgun_provider_test.exs` or `ses_provider_test.exs`) + `mix compile --no-optional-deps --warnings-as-errors`.
- **Per wave merge:** `cd mailglass_inbound && mix test` (full inbound suite, Postgres-backed) + `mix credo --strict`.
- **Phase gate:** full inbound suite green + both compile lanes green + credo strict clean before `/gsd:verify-work`.
- **Critical observability points to sample (the highest-information signals):** (1) forged-vs-authentic for BOTH providers, (2) replay no-op, (3) control-plane no-op, (4) S3-fetch-retry-then-error, (5) dedupe on Message-Id AND fingerprint fallback. These five paths carry the security + idempotency guarantees; under-sampling any one risks shipping a silent forgery-accept or duplicate-insert.

### Wave 0 Gaps
- [ ] `test/mailglass_inbound/ingress/mailgun_provider_test.exs` — MGUN-01..03 (code-built multipart fixtures, no `.eml`)
- [ ] `test/mailglass_inbound/ingress/ses_provider_test.exs` — SESI-01..05 (code-built SNS envelopes)
- [ ] `test/mailglass_inbound/signature_error_test.exs` — `__types__/0` contract
- [ ] `test/mailglass_inbound/s3_fetch_error_test.exs` — `__types__/0` contract
- [ ] `test/mailglass_inbound/s3_fetcher_test.exs` — Fake + gateway `available?/0`
- [ ] Mailgun + SES code-built payload builders in test support (ROADMAP Phase-47 will formalize `MailglassInbound.Fixtures`; this phase needs ad-hoc builders now)
- [ ] Extend `plug_test.exs` for `:mailgun`/`:ses` allowlist + widened-result branches
- [ ] New migration test coverage for the Mailgun fingerprint index

## Security Domain

> `security_enforcement` not set to false → enabled.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | webhook verify is signature-based, not user auth |
| V3 Session Management | no | stateless ingress |
| V5 Input Validation | yes | multipart/SNS payload parsing; never-raise MIME parser; closed-type errors |
| V6 Cryptography | yes | HMAC-SHA256 (`:crypto`), RSA X.509 verify (`:public_key`), `Plug.Crypto.secure_compare` — **never hand-roll** (reuse core seams) |
| V10 Malicious Code / SSRF | yes | `TrustPolicy` host allowlist for `SigningCertURL`/`SubscribeURL`; S3 fetch scoped to provider-declared bucket/key |
| V13 API/Webhook | yes | verify-first ordering; no-recovery on forgery; 200-no-op on replay/control-plane |

### Known Threat Patterns for {Mailgun/SES inbound}
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Forged Mailgun HMAC | Spoofing | `:crypto.mac` + `secure_compare`; `SignatureError` no-recovery → 401 |
| Mailgun replay | Repudiation/Tampering | `MailgunReplayCache.check_and_put/2` token guard → `{:replay}` 200 no-op |
| Forged SNS signature | Spoofing | core SES X.509 verify (RSA-SHA1/256) reused |
| SubscribeURL hijack / S3 namespace collision | Spoofing/SSRF | `TrustPolicy.valid_subscribe_url?/1` host regex (AWS-PHP-SDK reference) |
| SSRF via SigningCertURL | SSRF | `TrustPolicy.valid_cert_url?/1` validated BEFORE network I/O (`ses.ex:63`) |
| MIME boundary-bomb (deep nesting DoS) | DoS | `MIME.parse/1` `:max_depth` guard (note: representation-walk bound, not decoder-recursion — see `mime.ex` moduledoc; decoder-level limit is flagged as a Phase-46 concern) |
| Oversized S3 object | DoS | SES caps at 40 MB; `get_object` into memory acceptable; streaming deferred |
| PII leak in telemetry/response | Info Disclosure | existing `NoPiiInResponseBody` + `NoPiiInTelemetryMeta` credo checks cover inbound ingress paths; new providers flow through them |
| SES client-side KMS ciphertext | (out of scope) | documented: use bucket-level SSE, not client-side KMS (D-46-18) |

## Sources

### Primary (HIGH confidence)
- Live codebase reads (all anchors): `lib/mailglass/webhook/providers/{mailgun,mailgun_replay_cache,ses}.ex`, `ses/{cert_cache,trust_policy}.ex`, `lib/mailglass/webhook/plug.ex`, `lib/mailglass/application.ex`, `lib/mailglass/errors/signature_error.ex`, `lib/mailglass/optional_deps/gen_smtp.ex`; inbound `ingress/{plug,provider,persist,request,caching_body_reader}.ex`, `ingress/providers/{postmark,sendgrid}.ex`, `mime.ex`, `mime_error.ex`, `optional_deps.ex`, `application.ex`, `inbound_message.ex`, `inbound_records/{inbound_record,inbound_evidence}.ex`, `mix.exs`; `.credo.exs`, `credo_checks/no_bare_optional_dep_reference.ex`; migrations `20260506180000`, `20260506220000`.
- Hex registry API (versions + publish dates): ex_aws 2.7.0, ex_aws_s3 2.5.9, sweet_xml 0.7.5, hackney 4.0.0 (verified 2026-05-23).
- `.planning/{ROADMAP,STATE,REQUIREMENTS}.md`, `.planning/research/{STACK,PITFALLS}.md`, `46-CONTEXT.md`.

### Secondary (MEDIUM confidence)
- hexdocs.pm/ex_aws_s3/ExAws.S3.html — `get_object/3` signature + runtime-deps (sweet_xml optional, user-supplied HTTP client).
- github.com/ex-aws/ex_aws README — credential chain (env → pod-identity → ECS task role → instance role).

### Tertiary (LOW confidence)
- Community/WebSearch on `ExAws.request` exact body-map key set — confirms `:body` binary but exact key list to be verified in the Fake-vs-real adapter test (A1).

## Metadata

**Confidence breakdown:**
- Anchor accuracy: HIGH — every anchor read; drifts enumerated.
- Standard stack: HIGH — versions verified on Hex registry.
- Architecture (widened contract / verify seams): HIGH — core already implements the target pattern; recommendations are "do what core does."
- Pitfalls: HIGH — derived from read code, not inference.
- ExAws response shape (A1): MEDIUM-LOW — verify in test.

**Research date:** 2026-05-23
**Valid until:** ~2026-06-22 (stable; codebase anchors won't drift unless Phase 45 follow-ups land; re-verify ex_aws versions if planning slips past 30 days)

Sources:
- [ExAws.S3 v2.5.9 docs](https://hexdocs.pm/ex_aws_s3/ExAws.S3.html)
- [ex-aws/ex_aws GitHub](https://github.com/ex-aws/ex_aws)
- [Hex: ex_aws](https://hex.pm/packages/ex_aws)
- [Hex: ex_aws_s3](https://hex.pm/packages/ex_aws_s3)
