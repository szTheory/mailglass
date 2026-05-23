# Phase 46: Mailgun + SES Inbound Ingress - Context

**Gathered:** 2026-05-23 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Adopters running **Mailgun** or **AWS SES** inbound webhooks can install Mailglass
and have authentic provider payloads **verified → normalized into the canonical
`%MailglassInbound.InboundMessage{}` → persisted with raw evidence → dispatched to
the matched mailbox** — without Mailglass inventing new cryptography. Everything
**lifts from the outbound webhook verifiers** at
`lib/mailglass/webhook/providers/{mailgun,ses}.ex` and consumes the Phase-45
`MailglassInbound.MIME` parser (Phase 46 is its first consumer).

**In scope:** MGUN-01..04, SESI-01..05 (9 REQs).

**Out of scope (later phases):**
- Mailgun + SES *setup guides* (`docs/inbound-mailgun.md`, `docs/inbound-ses.md`) →
  MGUN-05 / SESI-06 → **Phase 50**.
- Cloudflare Email Routing, `gen_smtp` SMTP listener → deferred (different
  transport class / no first-party contract).
- Admin LiveView, operator tooling (`inbound.doctor`/`replay`/`prune`), rate
  limiting → Phases 48/49.

This phase ships **two production-grade inbound providers**, not docs and not UI.
</domain>

<decisions>
## Implementation Decisions

### A1 · Cross-package verifier reuse (the central architectural choice)
- **D-46-01:** Reuse `mailglass` core's webhook verification rather than reinventing
  cryptography. Extract the **shape-agnostic verification primitives** into thin
  functions both packages call:
  - **Mailgun:** HMAC-SHA256 over `timestamp <> token` (no separator) keyed by the
    signing key + the `MailgunReplayCache.check_and_put/2` replay guard + the
    timestamp-skew check. These are payload-shape-agnostic and reusable as-is.
  - **SES:** the SNS X.509 signature-verification path (the SNS JSON envelope is
    byte-identical inbound vs outbound) returning the verified `Message` payload.
- **D-46-02:** **Reuse the already-running GenServers** — the supervised
  `Mailglass.Webhook.Providers.MailgunReplayCache` and SES
  `Mailglass.Webhook.Providers.SES.CertCache` are owned by **core's** supervision
  tree (`lib/mailglass/application.ex`). Because `mailglass_inbound` declares
  `{:mailglass, path: ".."}`, the `:mailglass` OTP app boots and starts those
  supervisors, so the ETS tables exist at runtime; inbound calls the module
  functions only (`:ets` ops are global, not process-pinned). **Inbound must NOT add
  these supervisors to `MailglassInbound.Application`** — doing so would register a
  second singleton (CLAUDE.md "Things Not To Do" #8). `CertCache` + `TrustPolicy`
  are pure / URL-keyed and called directly.
- **D-46-03:** Leave outbound's JSON decoding (`Jason.decode` of the webhook body)
  and `%Event{}` normalization **untouched** — those are v1.x-stable. Only the
  shared crypto/cache primitives are factored out; the inbound providers supply
  their own payload extraction (multipart for Mailgun, SNS-envelope for SES).
- **D-46-04:** The boundary Credo check (`NoBareOptionalDepReference`) is path-scoped
  to `lib/mailglass/` and there is **no inbound-local `.credo.exs`**, so inbound
  aliasing `Mailglass.Webhook.Providers.*` is not flagged. Planner must still keep
  cross-package calls explicit and confirm no compile-time cycle is introduced.
- *Override option (only if a plan-time read shows it's cleaner):* reuse the caches +
  `TrustPolicy` and **reimplement the ~15-line HMAC/verify inside inbound**, leaving
  core's `verify!/3` bodies fully intact (smallest blast radius on stable outbound
  code). Default remains D-46-01 extraction.

### A2 · Provider dispatch unification + result-contract widening
- **D-46-05:** Extend `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex`
  allowlist to `[:postmark, :sendgrid, :mailgun, :ses]` as **one** `init/1` guard +
  **one** `provider_module/1` switch — not two parallel pipelines (success
  criterion 5).
- **D-46-06:** **Widen the provider/plug result contract** to carry non-persisting
  verified outcomes the current contract cannot express. Recommended three-variant
  return handled by one `case` in `do_call/2`:
  - `{:ok, verification_facts}` → persist normally (existing path).
  - `{:control_plane, http_status}` → SES `SubscriptionConfirmation` (auto-confirm
    via `TrustPolicy` first) and `UnsubscribeConfirmation` → **200 no-op, no
    `InboundRecord`**.
  - `{:replay}` → Mailgun replay hit → **200 no-op, no second `InboundRecord`**
    (success criterion 2). Replay is a 200 no-op, **never** a `SignatureError`/401
    (providers retry-storm on non-200; mirrors outbound D-15-05).
- **D-46-07:** The `MailglassInbound.Ingress.Provider` behaviour's `verify!` callback
  return type widens accordingly. The plug already dispatches per-provider (Postmark
  `verify!/3`+`normalize/2` vs SendGrid `verify!/2`+`normalize/1`), so unification
  trends toward a single `verify!(%Request{}, config)` shape all four migrate to —
  exact tuple shape is the planner's discretion provided the three outcomes above
  are expressible and `verify!`'s return is no longer discarded at `plug.ex:241-247`.

### A3 · Mailgun multipart normalization + MIME routing + dedupe
- **D-46-08:** Mailgun **inbound routes** POST `application/x-www-form-urlencoded`
  (and `multipart/form-data` only when attachments are present). The HMAC signature
  triple arrives as **top-level form fields** `timestamp`, `token`, `signature`
  (NOT the nested JSON `signature` object outbound webhooks use). Same HMAC algorithm
  as outbound.
- **D-46-09:** Support **both** Mailgun delivery modes; raw-MIME is opt-in **by route
  URL suffix** (`…/mime` or `…/raw-mime`), not by action type:
  - **Raw-MIME mode** (`body-mime` present): route `body-mime` through
    **`MailglassInbound.MIME.parse/1`** — Phase 46 is the parser's intended first
    consumer (`mime.ex:60-61`). This is the documented-default path to honor.
  - **Parsed mode** (default): normalize from `body-plain`/`body-html`/`stripped-*`
    + `message-headers` + attachment fields.
- **D-46-10:** Dedupe `provider_message_id` = the RFC **`Message-Id`** header. Mailgun
  inbound has **no flat `Message-Id` form field** — extract it from the
  `message-headers` field (a JSON-encoded ordered header list; match header name
  **case-insensitively**) in parsed mode, or from raw headers in MIME mode. The
  `token` is the **replay nonce**, conceptually distinct from message identity — never
  use it for dedupe. When no usable `Message-Id` exists, fall back to an
  **MD5(raw) fingerprint** dedupe, mirroring SendGrid (`persist.ex:81-101`). Dedupe
  anchor stays `(tenant_id, provider, provider_message_id)` (`persist.ex:103-116`).
- **D-46-11:** Persist raw provider source to `inbound_evidence` (MGUN-03); attachments
  follow the existing evidence pattern (`attachment-count`/`attachment-N`/
  `content-id-map`). Raw-body capture works through the existing content-type-agnostic
  `CachingBodyReader` exactly as SendGrid does today.

### A4 · SES delivery modes · S3Fetcher · OptionalDeps placement · S3 error
- **D-46-12:** **S3 action is the primary path.** The SES `"Received"` notification's
  `receipt.action.type == "S3"` carries `bucketName` + `objectKey` (where
  `objectKey == mail.messageId`; `objectKeyPrefix` is rule-config only, already baked
  into `objectKey`). Fetch `s3://{bucketName}/{objectKey}`. The **SNS-inline `content`**
  path (raw MIME embedded in the notification, UTF-8 or Base64, **≤150 KB or SES
  bounces**) is a **secondary small-message path** — handle it but design around S3.
- **D-46-13:** New behaviour **`MailglassInbound.S3Fetcher`**:
  `@callback fetch(bucket :: String.t(), key :: String.t(), opts :: keyword()) :: {:ok, binary()} | {:error, term()}`.
  - **`MailglassInbound.S3Fetcher.Fake`** ships in inbound core as the **test default**
    (fake-adapter-first DNA, D-13), resolved via a config seam (mirror the
    config-map-then-app-env resolution SES `httpc_client` uses).
  - **`MailglassInbound.S3Fetcher.ExAwsS3`** (real adapter) gates through a **new
    inbound-local `MailglassInbound.OptionalDeps.ExAwsS3`** gateway.
- **D-46-14:** **Gateway placement is inbound-local**, NOT core. `MailglassInbound.OptionalDeps`
  explicitly "keeps optional runtime integrations behind its own gateway surface
  instead of reusing `Mailglass.OptionalDeps.*` across package boundaries"
  (`optional_deps.ex:6`), with `MailglassInbound.OptionalDeps.Oban` as the working
  precedent. **SESI-04's literal wording "`Mailglass.OptionalDeps.ExAwsS3`" is an
  erratum** — the consumer (`S3Fetcher.ExAwsS3`) lives in inbound, and core's
  `NoBareOptionalDepReference` is scoped to `lib/mailglass/` only. Mirror the GenSmtp
  gateway shape: `@compile {:no_warn_undefined, [ExAws, ExAws.S3]}` + `available?/0`
  (`Code.ensure_loaded?(ExAws.S3)`) + degraded fallback. The gateway must keep the
  `mix compile --no-optional-deps --warnings-as-errors` lane green.
  - *Override option:* place in core `Mailglass.OptionalDeps.ExAwsS3` per the literal
    REQ — but only as a deliberate, documented reversal of the inbound-gateway
    contract. Default remains inbound-local.
- **D-46-15:** Fetch implementation = `ExAws.S3.get_object(bucket, key) |> ExAws.request/1`
  → `{:ok, %{body: binary}}`; feed `body` into `MailglassInbound.MIME.parse/1`. Deps:
  `{:ex_aws, "~> 2.7"}` + `{:ex_aws_s3, "~> 2.5"}`. Adopters **also** add `:sweet_xml`
  (required at runtime for S3 XML — the non-obvious one), an HTTP client
  (`:hackney ~> 4.0` or `:req`), and `:jason`. Credentials resolve via ex_aws's
  **standard chain** (env → pod-identity → instance/task role) with **no
  mailglass-specific config** — adopters wire their own AWS creds. (These belong in
  the Phase-50 setup doc, captured here for the gateway + `no_warn_undefined` list.)
- **D-46-16:** **SESI-05 reframed.** S3 has had strong read-after-write consistency
  since Dec 2020, and SES publishes the SNS notification **after** the PutObject — so
  the real design driver is **idempotency on `objectKey`/`messageId` + SNS
  at-least-once redelivery**, NOT eventual consistency. Implement only a **small
  bounded GetObject retry** (≈2–3 attempts, short backoff e.g. 250 ms → 1 s → 2 s);
  on exhaustion **do not ack** so SNS redelivers, with the dedupe layer as the real
  safety net. Do not build a large retry budget around an unconfirmed timing gap.
- **D-46-17:** Surface S3-fetch failure as a **new inbound-local closed-type error**
  `MailglassInbound.S3FetchError` with `:type` set `[:s3_object_not_ready,
  :s3_fetch_failed]`, following the canonical error shape + `__types__/0`-style test
  discipline of `MailglassInbound.MIMEError`. Do **not** bolt a new atom onto core
  `Mailglass.Error`, `Mailglass.SignatureError`, or `MailglassInbound.MIMEError`
  (each has a closed `@types` set tested against `api_stability.md`).
- **D-46-18:** **Scope-out — document, don't solve:** SES receipt-rule **client-side
  KMS encryption** encrypts the object with the S3 *client-side* encryption client
  before upload; a plain `GetObject` returns ciphertext that an Elixir gateway cannot
  transparently decrypt. Document that adopters should use the S3 action **without**
  SES client-side KMS encryption (use bucket-level SSE instead). Not a Phase-46
  deliverable.

### A5 · New inbound errors, scope boundary, dependency departure
- **D-46-19:** **`MailglassInbound.SignatureError` is net-new** (today the only inbound
  error is `mime_error.ex`). It mirrors outbound `Mailglass.Errors.SignatureError`'s
  **no-recovery** contract (CLAUDE.md #5 / D-22) and raises on: forged Mailgun HMAC,
  forged SES SNS signature, or a hijacked/failed-`TrustPolicy` `SubscribeURL`. Closed
  `:type` set + `@since` + CHANGELOG entry + `__types__/0` test, per the established
  inbound error discipline.
- **D-46-20:** Adding `:ex_aws` / `:ex_aws_s3` is the **first new optional runtime dep
  since the v1.0 STACK lock** (STACK.md: "Optional deps: Add none"). This is a
  deliberate, noted departure recorded in the phase decision record / CHANGELOG.

### Claude's Discretion
- Exact module names/signatures of the extracted shared verification primitives and
  whether they live in a new neutral core module vs reused from `Webhook.Providers.*`.
- Exact widened-result tuple shape (D-46-06/07) provided the three outcomes are
  expressible and `verify!`'s return is consumed.
- Exact `S3Fetcher` config-resolution key + `Fake` behavior surface.
- Exact bounded-retry counts/backoff for D-46-16 within the "small" envelope.
- Exact internal representation of normalized Mailgun parsed-mode fields.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and locked posture
- `.planning/ROADMAP.md` — Phase 46 goal, success criteria, hardest sub-tasks.
- `.planning/REQUIREMENTS.md` — MGUN-01..04, SESI-01..05 exact wording (note SESI-04
  `Mailglass.OptionalDeps.ExAwsS3` erratum → use inbound-local per D-46-14).
- `.planning/PROJECT.md` — optional-dep gateway pattern, no-PII telemetry, append-only
  events, fake-adapter-first, one-maintainer honesty.
- `.planning/METHODOLOGY.md` — decisive-by-default, honest-surface, recommendation-first.
- `.planning/STATE.md` — current v1.2 milestone position.

### Inherited decisions (the lift sources + mirrors)
- `.planning/milestones/v0.3-phases/15-mailgun-webhook-provider/15-CONTEXT.md` — outbound
  Mailgun: native HMAC, ETS replay cache keyed on token, replay = 200 no-op.
- `.planning/milestones/v0.3-phases/16-ses-webhook-provider-sns-cache/16-CONTEXT.md` —
  outbound SES: SNS control-plane handling, auto-confirm, TrustPolicy, CertCache.
- `.planning/milestones/v1.1-phases/40-postmark-ingress-and-replayable-persistence/40-CONTEXT.md`
  — inbound ingress house pattern, canonical+evidence transaction, dedupe anchor.
- `.planning/milestones/v1.1-phases/41-sendgrid-ingress-and-mailbox-routing/41-CONTEXT.md`
  — raw-MIME→`%InboundMessage{}` precedent + fingerprint dedupe fallback.
- `.planning/phases/45-inbound-telemetry-idempotency-foundation/45-CONTEXT.md` — the
  `MailglassInbound.MIME` parser + `MIMEError` + telemetry spans Phase 46 consumes.

### Code anchors — lift sources (mailglass core)
- `lib/mailglass/webhook/providers/mailgun.ex` — `verify!/3` (conn-free; `Jason.decode`s
  the body — DO NOT call wholesale on multipart), HMAC math, replay-cache call.
- `lib/mailglass/webhook/providers/mailgun_replay_cache.ex` — supervised ETS replay
  cache to REUSE (do not duplicate the GenServer).
- `lib/mailglass/webhook/providers/ses.ex` — SNS X.509 verify + `dispatch_message_type/3`
  (control-plane), `httpc_client` config-resolution pattern.
- `lib/mailglass/webhook/providers/ses/cert_cache.ex`,
  `.../ses/cert_cache/{supervisor,table_owner}.ex` — supervised cert cache to REUSE.
- `lib/mailglass/webhook/providers/ses/trust_policy.ex` — URL allowlist (https-only,
  exact-SNS-host-from-signed-TopicArn) — call directly.
- `lib/mailglass/webhook/{provider,plug,ingest,caching_body_reader}.ex` — verify-first
  ingress orchestration + raw-body capture precedents.
- `lib/mailglass/application.ex` — where the caches are supervised (inbound must NOT
  re-supervise them).
- `lib/mailglass/errors/signature_error.ex` — the no-recovery error shape the new
  `MailglassInbound.SignatureError` mirrors.
- `lib/mailglass/optional_deps/gen_smtp.ex`, `lib/mailglass/optional_deps.ex` — gateway
  shape to mirror.

### Code anchors — inbound targets (mailglass_inbound)
- `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` — allowlist + `do_call/2`
  (widen result contract); `verify_request!/3` currently discards `verify!`'s return.
- `mailglass_inbound/lib/mailglass_inbound/ingress/provider.ex` — behaviour to widen.
- `mailglass_inbound/lib/mailglass_inbound/ingress/{persist,request,caching_body_reader}.ex`
  — dedupe anchor + fingerprint fallback + raw-body capture.
- `mailglass_inbound/lib/mailglass_inbound/ingress/providers/{postmark,sendgrid}.ex` —
  the two existing providers to mirror (SendGrid = raw-MIME precedent).
- `mailglass_inbound/lib/mailglass_inbound/inbound_message.ex`,
  `inbound_records/{inbound_record,inbound_evidence,replay_run,execution_run}.ex` —
  canonical model + storage (do not widen the public struct for provider quirks).
- `mailglass_inbound/lib/mailglass_inbound/mime.ex`, `mime_error.ex` — Phase-45 parser
  (first consumer) + the closed-type error pattern the new errors follow.
- `mailglass_inbound/lib/mailglass_inbound/optional_deps.ex` (+ `.../optional_deps/oban.ex`)
  — inbound-local gateway contract + precedent for `OptionalDeps.ExAwsS3`.
- `mailglass_inbound/lib/mailglass_inbound/application.ex` — do NOT add core's caches here.
- `mailglass_inbound/mix.exs` — `{:mailglass, path: ".."}` dep; add `ex_aws`/`ex_aws_s3`
  as optional.
- `.credo.exs` — confirms core checks are path-scoped to `lib/mailglass/`.

### External provider + dependency references (verified 2026-05-23)
- Mailgun inbound routes: `https://documentation.mailgun.com/docs/mailgun/user-manual/receive-forward-store/receive-http`
  (multipart fields, `body-mime` via `…/mime` URL suffix, `message-headers`,
  `content-id-map`).
- Mailgun signing: `https://documentation.mailgun.com/docs/mailgun/user-manual/webhooks/securing-webhooks`
  (HMAC-SHA256 of `timestamp <> token`).
- SES inbound notification contents: `https://docs.aws.amazon.com/ses/latest/dg/receiving-email-notifications-contents.html`.
- SES S3 action: `https://docs.aws.amazon.com/ses/latest/dg/receiving-email-action-s3.html`
  (`bucketName`/`objectKey`; `objectKey == messageId`; client-side KMS gotcha).
- SES SNS action: `https://docs.aws.amazon.com/ses/latest/dg/receiving-email-action-sns.html`
  (inline `content`, UTF-8/Base64, ≤150 KB else bounce).
- ex_aws_s3: `https://hexdocs.pm/ex_aws_s3/ExAws.S3.html` ; `https://hex.pm/packages/ex_aws`
  (2.7.0) ; `https://hex.pm/packages/ex_aws_s3` (2.5.9) — `get_object |> ExAws.request →
  {:ok, %{body: binary}}`; runtime deps incl. `sweet_xml`; standard credential chain.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Core `Mailgun.verify!/3` HMAC math + `MailgunReplayCache` + timestamp-skew check are
  payload-shape-agnostic and reusable; only the body decode differs (multipart vs JSON).
- Core SES X.509 verification + `CertCache` + `TrustPolicy` are reusable as-is (SNS
  envelope identical inbound/outbound; caches URL-keyed and process-global via ETS).
- Both caches are already supervised by `mailglass` core — inbound reuses the running
  processes (no second singleton) because it deps `{:mailglass, path: ".."}`.
- `MailglassInbound.MIME.parse/1` (Phase 45) is the never-raise MIME parser purpose-built
  for this phase; `MailglassInbound.MIMEError` is the closed-type error template.
- SendGrid inbound provider (`sendgrid.ex` + `persist.ex:81-101`) is the raw-MIME →
  `%InboundMessage{}` + MD5-fingerprint-fallback precedent to mirror for Mailgun.
- `MailglassInbound.OptionalDeps.Oban` is the inbound-local gateway precedent for
  `OptionalDeps.ExAwsS3`. `Mailglass.OptionalDeps.GenSmtp` is the shape template.
- `CachingBodyReader` is content-type-agnostic — multipart raw capture already works.

### Established Patterns
- Verify-first ingress: verify → tenant → normalize → one transaction (canonical row +
  evidence row) → dispatch; provider seam package-internal & sealed.
- Optional deps gated through a single `OptionalDeps.*` module + `available?/0` + degraded
  fallback; bare references banned (`NoBareOptionalDepReference`).
- Inbound-local errors (closed `:type` set + `@since` + `__types__/0` test + CHANGELOG),
  not reaching into core's error structs.
- Fake-adapter-first (D-13): `S3Fetcher.Fake` is the test default; real adapter optional.
- Dedupe anchor `(tenant_id, provider, provider_message_id)` with MD5(raw) fingerprint
  fallback when no provider id exists.

### Integration Points
- Inbound providers → extracted core verification primitives + running core caches.
- SES `Action: S3` → `S3Fetcher` behaviour → `OptionalDeps.ExAwsS3` → `ExAws.S3` →
  `MailglassInbound.MIME.parse/1`.
- Mailgun `body-mime` (raw mode) → `MailglassInbound.MIME.parse/1`; parsed mode →
  field normalization.
- `plug.ex` `do_call/2` → widened result contract (persist / control-plane 200 / replay 200).
- Telemetry spans (Phase 45) already wrap ingress/route/persist/execution — new providers
  flow through them automatically.
</code_context>

<specifics>
## Specific Ideas

- Mental model: Mailgun + SES inbound are the **inbound siblings** of the shipped
  outbound webhook verifiers — same crypto, same caches, same trust policy, same
  idempotent-200 posture for replay/control-plane. Reuse, don't reinvent.
- The single highest-risk trap: calling core's `verify!/3` wholesale on a Mailgun
  multipart body feeds it into `Jason.decode` and `SignatureError`s every authentic
  request. Extract the shape-agnostic primitive; don't reuse the JSON decode.
- The second trap: SES `SubscriptionConfirmation` has no message to persist — without
  the widened result contract the topic never activates and SES inbound silently never
  works.
- Two contract calls are public API and locked here to recommended defaults: the
  inbound-local `MailglassInbound.OptionalDeps.ExAwsS3` gateway (D-46-14, overriding
  SESI-04's literal wording) and the net-new closed-type errors
  `MailglassInbound.SignatureError` + `MailglassInbound.S3FetchError`.
- Honest-surface lens: design SES around the **S3 action** (the real-world path);
  treat SNS-inline `content` as a small-message convenience, and scope out SES
  client-side KMS encryption rather than half-supporting it.
</specifics>

<deferred>
## Deferred Ideas

- Mailgun + SES **setup guides** (route URL convention, signing-key rotation, SNS topic
  config, IAM policy, S3 bucket setup, dependency snippet) → MGUN-05 / SESI-06 → **Phase 50**.
- SES **client-side KMS-encrypted** object decryption (no Elixir S3-encryption-client) →
  documented constraint, not built.
- Streaming very large S3 objects (`ExAws.S3.download_file/3`) — `get_object` into memory
  is fine for the 40 MB SES cap; revisit only on scale evidence.
- Cloudflare Email Routing, `gen_smtp` SMTP listener — different transport class / no
  first-party contract; deferred to a future milestone.
- Ingress-stage rate limiting, `inbound.doctor` MIME/dep reporting, admin LiveView —
  Phases 48/49.

### Reviewed Todos (not folded)
None — no pending todos matched Phase 46 scope.
</deferred>

---

*Phase: 46-mailgun-ses-inbound-ingress*
*Context gathered: 2026-05-23 (assumptions mode)*
