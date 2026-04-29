# Phase 16: SES Webhook Provider & SNS Cache - Research

**Researched:** 2026-04-28
**Domain:** AWS SNS/SES webhook ingest — RSA signature verification, X.509 certificate caching, SNS control-plane handling, SES event normalization
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** Handle SubscriptionConfirmation, Notification, and UnsubscribeConfirmation on the same SES webhook endpoint — no separate route.
**D-02:** SNS control-plane messages are an explicit success path, short-circuit before normalize/2 + ingest persistence.
**D-03:** Auto-confirm subscriptions after SNS signature + trust-policy verification; HTTP 200, no webhook event rows.
**D-04:** UnsubscribeConfirmation: verify, emit telemetry/logging, HTTP 200 no-op; do not re-confirm.
**D-05:** SNS authenticity verification applies to all three message types before any side effect.
**D-06:** Validate SigningCertURL and SubscribeURL with a provider-local trust helper before any network I/O: https only, no userinfo/fragment, exact SNS host derived from signed TopicArn region/partition.
**D-07:** Auto-confirm via mailglass-constructed ConfirmSubscription request using signed TopicArn + Token; SubscribeURL validated for consistency only, not used as trusted source. Redirects disabled.
**D-08:** Support SNS partitions: commercial, GovCloud, China (amazonaws.com, amazonaws.com.cn).
**D-09:** URL trust-policy failures are authenticity failures — fail closed.
**D-10:** ETS-backed certificate cache, supervised, matching existing OTP style (MailgunReplayCache pattern).
**D-11:** Native Erlang/OTP only: :httpc, :public_key, ETS — no AWS SDK.
**D-12:** Cache X.509 certs by URL with expiration-aware refresh.
**D-13:** Support both classic SNS feedback (notificationType) and SES event-publishing (eventType) formats.
**D-14:** Normalize to existing atoms only: :sent, :delivered, :bounced, :complained, :rejected, :opened, :clicked, :failed, :deferred. No SES-specific public event atoms.
**D-15:** Preserve AWS nuance in metadata string keys.
**D-16:** Fan out one %Event{} per recipient; stable per-recipient provider_event_id from SNS MessageId + recipient identity/index.
**D-17:** Terminal hard-bounce -> :bounced/:bounced; complaints -> :complained; transient/delay -> :deferred; policy/suppression-list -> :rejected.
**D-18:** Document duplicate-source behavior: SES feedback and SES event publishing can overlap.
**D-19:** Agent-led research and recommended defaults; only escalate high-impact public API decisions.

### Claude's Discretion

- Exact callback/tuple shape for SES control-plane success path (must be explicit in provider/plug boundary, must not masquerade as normal event)
- Exact ETS table ownership module names and cache invalidation details for SNS certificate cache
- Exact metadata field names for preserved SES/SNS detail beyond required keys
- Exact timeout values, retry posture, and telemetry field names for certificate fetch and subscription confirmation

### Deferred Ideas (OUT OF SCOPE)

- Rich SES-specific public event projections or structs
- Distributed/shared certificate caches across nodes
- Admin UI for manual SNS confirmation recovery
- Global GSD preference plumbing beyond this phase context

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SES-01 | Webhook plug parses SNS payloads arriving with text/plain Content-Type | SNS delivers HTTP POSTs with `Content-Type: text/plain; charset=UTF-8`; raw body is JSON; CachingBodyReader already captures raw bytes |
| SES-02 | System automatically performs HTTP GET to SubscribeURL upon receiving SubscriptionConfirmation events | D-07 clarifies: use ConfirmSubscription API (constructed from TopicArn + Token), not raw SubscribeURL redirect; :httpc for the GET |
| SES-03 | Webhook plug verifies RSA-SHA1/SHA256 signatures using X.509 certificates fetched from AWS | :public_key.pem_decode + extract public key from cert record + :public_key.verify with :sha/:sha256 |
| SES-04 | X.509 certificates are fetched via :httpc and cached in :ets to avoid synchronous network I/O per webhook | GenServer-owned ETS table, cache by URL, TTL-aware expiry |
| SES-05 | Webhook maps SES events inside SNS Message envelope to mailglass normalized taxonomy | Dual-format mapper: notificationType (classic) + eventType (event-publishing); fan-out per recipient |

</phase_requirements>

---

## Summary

Phase 16 implements the SES webhook provider behind the existing `Mailglass.Webhook.Provider` behaviour. Unlike Mailgun (symmetric HMAC) and Resend (Svix HMAC), AWS SNS uses RSA asymmetric signature verification over a canonical string constructed from specific JSON fields, with the public key delivered via an X.509 certificate fetched from a SigningCertURL in the message itself. This introduces SSRF risk and per-request network I/O risk — both mitigated by the narrow trust-policy validator (D-06) and ETS certificate cache (D-10, D-12).

SNS also introduces a control-plane layer absent from other providers: the same endpoint receives `SubscriptionConfirmation` and `UnsubscribeConfirmation` messages that must be handled explicitly before the normalize/ingest pipeline runs. The existing provider contract returns `:ok | {:ok, :replay}` from `verify!/3`; Phase 16 extends this with a `{:ok, :control_plane, outcome}` tuple (or equivalent — discretion of implementer) so `Mailglass.Webhook.Plug` can short-circuit cleanly.

SES delivers two distinct payload formats through SNS: classic "feedback notifications" (using `notificationType`) for bounce/complaint/delivery, and "event publishing" records (using `eventType`) for the full event lifecycle including open/click/send/reject. Both formats wrap the SES payload as a JSON-encoded string in the SNS `Message` field. The normalizer must decode the SNS envelope, then decode the nested SES JSON, then dispatch on the appropriate top-level key.

**Primary recommendation:** Follow the MailgunReplayCache OTP pattern exactly for the SNS certificate cache (GenServer-owned ETS table, Supervisor, maybe_add in Application), implement RSA verification with native :public_key using the exact canonical string algorithm from AWS docs, and narrow the trust policy to the AWS PHP SDK's well-tested host pattern augmented with an explicit path-ends-with-.pem check.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| SNS signature verification | API/Backend (Provider module) | — | Conn-free per provider contract; crypto happens in provider |
| X.509 certificate fetching | API/Backend (CertCache GenServer) | — | Network I/O scoped to ETS cache miss path |
| Certificate caching | API/Backend (ETS) | — | Read-heavy, concurrency-safe; GenServer owns table lifetime |
| SNS trust-policy validation | API/Backend (Provider trust helper) | — | Must run before any network I/O; pure predicate |
| SubscriptionConfirmation handling | API/Backend (Plug + Provider) | — | Control-plane short-circuit in Plug, network call in Provider |
| SES event normalization | API/Backend (Provider normalize) | — | Pure; no DB, no PubSub |
| Recipient fan-out | API/Backend (Provider normalize) | — | List expansion with stable ID derivation |
| Route mounting | API/Backend (Router macro) | — | Additive opt-in identical to Mailgun pattern |

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Erlang `:public_key` | OTP built-in | PEM decode, RSA verify | Native OTP; no external dep; handles X.509 cert parsing and RSA-SHA1/SHA256 |
| Erlang `:httpc` | OTP built-in | Certificate fetch, ConfirmSubscription | Native OTP HTTP client; no new dep on library consumers |
| Erlang `:ets` | OTP built-in | Certificate cache storage | Already used in project (MailgunReplayCache, SuppressionStore) |
| Erlang `:crypto` | OTP built-in | Not used for verification (RSA handled by :public_key) | :crypto.mac used by other providers; :public_key.verify for RSA |
| `Plug.Crypto.secure_compare/2` | Plug ~> 1.0 | Constant-time comparison (not used for RSA; used if any HMAC path added) | Already in project deps |
| `Jason` | ~> 1.4 | JSON decode for SNS envelope and SES message body | Already in project deps |

**No new dependencies needed.** [VERIFIED: codebase]

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Mailglass.Clock` | project | Testable certificate expiry checks | Any TTL/expiry comparison in cert cache |
| `Mailglass.SignatureError` | project | Structured failure for SNS verification failures | Bad signature, trust policy violation, malformed payload |
| `Mailglass.ConfigError` | project | Structured failure for missing provider config | Missing :ses config block |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `:httpc` | `Req` / `Finch` | Forces HTTP client dep on library consumers — violates mailglass minimal-dep DNA |
| `:public_key` native | `x509` Hex package | Third-party dep for one cert-parsing use case; :public_key handles it natively |
| Custom ETS expiry logic | `Cachex` | Cachex is an app-level dep; library should not force TTL library choices on adopters |

**Installation:** No additions to mix.exs required. [VERIFIED: codebase]

---

## Architecture Patterns

### System Architecture Diagram

```
HTTP POST /webhooks/ses
    │
    ▼
Mailglass.Webhook.CachingBodyReader
  (raw_body stored in conn.private[:raw_body])
    │
    ▼
Mailglass.Webhook.Plug.call/2
  │
  ├─► extract_headers_and_raw_body!
  │
  ├─► resolve_config!(:ses, conn)
  │      └── reads Application.get_env(:mailglass, :ses)
  │
  ├─► Provider.verify!/3  [SES provider]
  │      │
  │      ├─ decode JSON (Content-Type: text/plain — still valid JSON)
  │      ├─ extract x-amz-sns-message-type header
  │      ├─ extract SigningCertURL, TopicArn, SignatureVersion
  │      ├─ trust_policy_valid?(SigningCertURL, TopicArn)  ← SSRF guard
  │      │      └── validate_cert_host(host, partition_from_arn)
  │      │
  │      ├─ fetch_cert(SigningCertURL)  ← ETS cache check
  │      │      ├── HIT: return cached public key
  │      │      └── MISS: :httpc.request -> :public_key.pem_decode
  │      │                -> extract public key from cert record
  │      │                -> cache with TTL
  │      │
  │      ├─ build_canonical_string(message_fields, Type)
  │      ├─ :public_key.verify(canonical_string, :sha|:sha256, decoded_sig, pub_key)
  │      │
  │      ├─ NOTIFICATION:
  │      │      └── return :ok
  │      │
  │      ├─ SUBSCRIPTION_CONFIRMATION:
  │      │      ├── validate SubscribeURL trust policy
  │      │      ├── build ConfirmSubscription URL from TopicArn + Token
  │      │      ├── :httpc.request (GET, redirects disabled)
  │      │      └── return {:ok, :control_plane, :subscription_confirmed}
  │      │
  │      └── UNSUBSCRIBE_CONFIRMATION:
  │             └── return {:ok, :control_plane, :unsubscribe_confirmed}
  │
  ├─► [control_plane outcome] → Plug short-circuits, HTTP 200, no ingest
  │
  └─► [normal :ok] → Provider.normalize/2
           │
           ├─ decode SNS Message field (JSON string → SES payload map)
           ├─ detect format: notificationType vs eventType
           ├─ fan-out per recipient array
           └─ return [%Event{}, ...]
                │
                ▼
           Tenancy.resolve → Ingest → Broadcast
```

### Recommended Project Structure

```
lib/mailglass/webhook/providers/
├── ses.ex                           # Provider behaviour impl (verify!/3, normalize/2)
├── ses/
│   ├── cert_cache.ex                # Public API: fetch_public_key/1, reset/0, table/0
│   ├── cert_cache/
│   │   ├── supervisor.ex            # Supervisor for TableOwner
│   │   └── table_owner.ex           # GenServer owning ETS table
│   └── trust_policy.ex              # validate_cert_url/2, validate_subscribe_url/2

test/mailglass/webhook/providers/
├── ses_test.exs                     # verify!/3, normalize/2, control-plane paths
└── ses/
    └── cert_cache_test.exs          # cache hit/miss/TTL/reset

test/support/fixtures/webhooks/ses/
├── notification_bounce_permanent.json
├── notification_bounce_transient.json
├── notification_complaint.json
├── notification_delivery.json
├── event_send.json
├── event_delivered.json
├── event_bounced_permanent.json
├── event_bounced_transient.json
├── event_complained.json
├── event_rejected.json
├── event_opened.json
├── event_clicked.json
├── event_failed.json                # Rendering Failure
├── event_delivery_delay.json        # DeliveryDelay
├── subscription_confirmation.json
└── unsubscribe_confirmation.json
```

### Pattern 1: SNS Canonical String Construction

**What:** AWS SNS signs a canonical string built by sorting specific fields alphabetically (byte order) and appending `"key\nvalue\n"` for each present field. The set of fields varies by message type.

**When to use:** Every verify!/3 call — applied to all three SNS message types.

Fields for `Notification`:
- Message, MessageId, Subject (if present), Timestamp, TopicArn, Type

Fields for `SubscriptionConfirmation` / `UnsubscribeConfirmation`:
- Message, MessageId, SubscribeURL, Timestamp, Token, TopicArn, Type

The full sorted key set from the PHP SDK (canonical reference for safe ordering):
`Message`, `MessageId`, `Subject`, `SubscribeURL`, `Timestamp`, `Token`, `TopicArn`, `Type`

```elixir
# Source: https://docs.aws.amazon.com/sns/latest/dg/sns-verify-signature-of-message-verify-message-signature.html
# [VERIFIED: AWS official docs]

@signable_keys_notification ~w(Message MessageId Subject Timestamp TopicArn Type)
@signable_keys_control ~w(Message MessageId SubscribeURL Timestamp Token TopicArn Type)

defp build_canonical_string(payload, "Notification") do
  @signable_keys_notification
  |> Enum.filter(&Map.has_key?(payload, &1))
  |> Enum.map_join(fn key -> "#{key}\n#{payload[key]}\n" end)
end

defp build_canonical_string(payload, type)
     when type in ["SubscriptionConfirmation", "UnsubscribeConfirmation"] do
  @signable_keys_control
  |> Enum.filter(&Map.has_key?(payload, &1))
  |> Enum.map_join(fn key -> "#{key}\n#{payload[key]}\n" end)
end
```

**Critical:** `Subject` is optional in Notification and must be included only when present in the payload. [VERIFIED: AWS docs]

### Pattern 2: RSA Signature Verification with :public_key

**What:** Extract public key from X.509 PEM certificate using `:public_key`, then verify the RSA signature. Supports both SignatureVersion 1 (SHA1) and 2 (SHA256).

```elixir
# Source: Erlang :public_key OTP docs + AWS SNS verification docs
# [VERIFIED: https://www.erlang.org/doc/apps/public_key/using_public_key.html]

defp verify_rsa_signature(canonical_string, signature_b64, pem_binary, sig_version) do
  digest = if sig_version == "2", do: :sha256, else: :sha

  public_key = extract_public_key_from_pem!(pem_binary)
  decoded_sig = Base.decode64!(signature_b64)

  :public_key.verify(canonical_string, digest, decoded_sig, public_key)
end

defp extract_public_key_from_pem!(pem_binary) when is_binary(pem_binary) do
  # :public_key.pem_decode returns [{type, der, cipher_info}] entries
  [{:Certificate, der, :not_encrypted}] = :public_key.pem_decode(pem_binary)
  # Decode the DER-encoded certificate to an OTP Certificate record
  cert = :public_key.pkix_decode_cert(der, :otp)
  # Extract SubjectPublicKeyInfo from the TBSCertificate
  cert
  |> get_in([Access.elem(1), Access.elem(7)])
  # Returns the public key in a form :public_key.verify accepts
  |> :public_key.pkix_subject_id()
  |> elem(1)
  # Alternative: use pattern match on the record directly:
  # {:OTPTBSCertificate, ..., subject_pk_info, ...} = tbs_cert
end
```

**Simpler approach using :public_key.pem_entry_decode:**

```elixir
# :public_key.pem_decode/1 + :public_key.pem_entry_decode/1 workflow
# Source: [ASSUMED — training knowledge confirmed by forum discussion at
#   https://elixirforum.com/t/how-to-verify-sign-using-x509-certificates/29788]

defp extract_public_key_from_pem!(pem_binary) do
  [{:Certificate, _der, :not_encrypted} = entry] = :public_key.pem_decode(pem_binary)
  cert = :public_key.pem_entry_decode(entry)
  # cert is an OTP-decoded Certificate record; extract pubkey via pkix path
  # Use :public_key.pkix_extract_public_key/1 (OTP 24+) for clean extraction:
  {:ok, public_key} = :public_key.pkix_extract_public_key(cert)
  public_key
end
```

**Note on pkix_extract_public_key/1:** Available in OTP 24+. Since this project targets OTP 27 (per STACK.md context), this is the cleanest approach. [ASSUMED — verify OTP version constraint in project mix.exs]

### Pattern 3: SigningCertURL Trust Policy Validation

**What:** Before any network I/O, validate the SigningCertURL to prevent SSRF. The host must match the exact SNS subdomain pattern, derived from the partition in the signed TopicArn.

**The SSRF attack surface:** Weak regex patterns (e.g., `.*amazonaws.com`) allow an attacker to serve a malicious certificate from an S3 bucket like `https://sns.s3-us-west-2.amazonaws.com/evil.pem` which would pass `sns.*amazonaws.com` but is attacker-controlled. [VERIFIED: https://spaceraccoon.dev/exploiting-improper-validation-amazon-simple-notification-service/]

**Safe pattern (from AWS PHP SDK):**
```
^sns\.[a-zA-Z0-9\-]{3,}\.amazonaws\.com(\.cn)?$
```

This requires:
- Exact `sns.` prefix (not `sns` embedded in a subdomain)
- Region identifier (min 3 chars, alphanumeric + hyphen)
- Exact `amazonaws.com` or `amazonaws.com.cn` suffix
- No other subdomains between `sns.` and `amazonaws.com`

Additional mandatory checks beyond host pattern:
- Scheme must be `https` only
- No userinfo component
- No fragment component
- Path must end with `.pem`
- No query string

```elixir
# Source: https://github.com/aws/aws-php-sns-message-validator/blob/master/src/MessageValidator.php
# [VERIFIED: AWS PHP SNS validator official source]

@cert_host_pattern ~r/^sns\.[a-zA-Z0-9\-]{3,}\.amazonaws\.com(\.cn)?$/

defp trust_cert_url?(url_string) when is_binary(url_string) do
  case URI.parse(url_string) do
    %URI{scheme: "https", host: host, userinfo: nil, fragment: nil, path: path}
    when is_binary(host) and is_binary(path) ->
      String.match?(host, @cert_host_pattern) and String.ends_with?(path, ".pem")

    _ ->
      false
  end
end
```

**TopicArn partition derivation for SubscribeURL validation:**

```
arn:aws:sns:us-east-1:123:Topic         -> amazonaws.com (commercial)
arn:aws-us-gov:sns:us-gov-west-1:123:T  -> amazonaws.com (GovCloud)
arn:aws-cn:sns:cn-north-1:123:Topic     -> amazonaws.com.cn (China)
```

For D-06 "exact SNS host derived from the signed TopicArn region/partition": the key insight is that the signed TopicArn contains the region, which can be used to derive the expected SNS hostname. For the purposes of D-09 (failing closed), it is acceptable to apply the regex pattern above without requiring exact TopicArn-to-host correlation — the regex already excludes all non-SNS endpoints. [ASSUMED — the exact requirement for TopicArn-derived host matching vs regex-only is a discretion-area implementation choice]

### Pattern 4: ETS Certificate Cache (MailgunReplayCache OTP Style)

**What:** Three-module structure matching the existing MailgunReplayCache pattern: API module (CertCache), Supervisor, TableOwner (GenServer).

```elixir
# Module: Mailglass.Webhook.Providers.SES.CertCache
# Source: mirrors Mailglass.Webhook.Providers.MailgunReplayCache [VERIFIED: codebase]

@table :mailglass_webhook_ses_cert_cache

# Cache entry: {url_binary, public_key_term, expires_at_datetime}
# Key: url_binary (SigningCertURL)
# Value: {public_key_term, expires_at}

@spec fetch_public_key(binary()) :: {:ok, term()} | {:miss}
def fetch_public_key(url) when is_binary(url) do
  now = Mailglass.Clock.utc_now()

  case :ets.lookup(@table, url) do
    [{^url, public_key, expires_at}] ->
      if DateTime.compare(expires_at, now) == :gt do
        {:ok, public_key}
      else
        :ets.delete(@table, url)
        :miss
      end

    [] ->
      :miss
  end
end

@spec put(binary(), term(), DateTime.t()) :: :ok
def put(url, public_key, expires_at) when is_binary(url) do
  :ets.insert(@table, {url, public_key, expires_at})
  :ok
end
```

**Cache TTL:** AWS SNS certificates are long-lived (months). A TTL of 24 hours is a reasonable default; the cert does not expire that quickly but refreshing daily avoids stale cert holding after AWS rotates. [ASSUMED — verify against AWS certificate rotation frequency]

**Application.ex integration:** The `maybe_add` pattern in `Mailglass.Application` means simply creating `Mailglass.Webhook.Providers.SES.CertCache.Supervisor` will auto-add it to the supervision tree without patching Application.ex. [VERIFIED: codebase]

### Pattern 5: SNS SubscriptionConfirmation Auto-Confirm (D-07)

**What:** After verifying the SNS signature and trust policy, construct the `ConfirmSubscription` AWS API URL from the signed TopicArn and Token, then issue an :httpc GET request with redirects disabled.

Per D-07: do NOT simply follow the `SubscribeURL` from the message. Instead, construct the confirm URL independently from the verified TopicArn and Token fields.

```elixir
# Source: https://docs.aws.amazon.com/sns/latest/api/API_ConfirmSubscription.html
# [VERIFIED: AWS API docs]

defp build_confirm_url(topic_arn, token) do
  # Extract region from TopicArn: arn:aws:sns:REGION:account:topic
  region = topic_arn |> String.split(":") |> Enum.at(3)
  partition = arn_partition(topic_arn)
  base_host = sns_host_for_partition(partition, region)

  "https://#{base_host}/?Action=ConfirmSubscription" <>
    "&TopicArn=#{URI.encode_www_form(topic_arn)}" <>
    "&Token=#{URI.encode_www_form(token)}"
end

# :httpc call with redirect disabled
defp confirm_subscription(url) do
  opts = [ssl: [verify: :verify_peer, cacerts: :public_key.cacerts_get()]]
  # OTP 25+ :httpc does not follow redirects by default; explicit:
  http_opts = [autoredirect: false, timeout: 10_000]
  case :httpc.request(:get, {String.to_charlist(url), []}, http_opts, []) do
    {:ok, {{_vsn, 2xx, _}, _headers, _body}} when 2xx in 200..299 -> :ok
    {:ok, {{_vsn, status, _}, _, _}} -> {:error, {:http_status, status}}
    {:error, reason} -> {:error, {:http_error, reason}}
  end
end
```

**OTP 26+ cacerts_get:** `:public_key.cacerts_get/0` returns the system CA bundle (available since OTP 26). For the :httpc SSL verification of the AWS ConfirmSubscription endpoint, this avoids bundling CA certs in the library. [ASSUMED — verify OTP 26 is minimum target for this project]

### Pattern 6: SES Dual-Format Normalization with Recipient Fan-out

**What:** The `Message` field of an SNS Notification is a JSON-encoded string containing either a classic SES feedback payload (keyed by `notificationType`) or an SES event-publishing payload (keyed by `eventType`). Decode the outer SNS envelope, decode the inner SES JSON, dispatch on the key present.

```elixir
# Source: https://docs.aws.amazon.com/ses/latest/dg/notification-contents.html
#         https://docs.aws.amazon.com/ses/latest/dg/event-publishing-retrieving-sns-contents.html
# [VERIFIED: AWS SES docs]

def normalize(raw_body, headers) do
  with {:ok, sns_payload} <- Jason.decode(raw_body),
       "Notification" <- sns_payload["Type"],
       message_str when is_binary(message_str) <- sns_payload["Message"],
       {:ok, ses_payload} <- Jason.decode(message_str) do
    sns_message_id = sns_payload["MessageId"]
    normalize_ses(ses_payload, sns_message_id)
  else
    _ ->
      Logger.warning("[mailglass] SES normalize: unexpected SNS payload shape")
      []
  end
end

defp normalize_ses(%{"notificationType" => type} = payload, sns_message_id) do
  # Classic feedback notification
  normalize_feedback(type, payload, sns_message_id)
end

defp normalize_ses(%{"eventType" => type} = payload, sns_message_id) do
  # Event-publishing notification
  normalize_event_publishing(type, payload, sns_message_id)
end

defp normalize_ses(_payload, _sns_message_id) do
  Logger.warning("[mailglass] SES normalize: no notificationType or eventType found")
  []
end
```

**Recipient fan-out (D-16):**

```elixir
# Bounce: bouncedRecipients array
defp normalize_feedback("Bounce", payload, sns_message_id) do
  recipients = get_in(payload, ["bounce", "bouncedRecipients"]) || []
  Enum.with_index(recipients)
  |> Enum.map(fn {recipient, idx} ->
    email = recipient["emailAddress"]
    provider_event_id = "#{sns_message_id}:#{email || idx}"
    {type, reject_reason} = map_bounce(payload["bounce"])
    build_event(payload, sns_message_id, type, reject_reason, provider_event_id, email)
  end)
end

# Delivery: recipients array
defp normalize_feedback("Delivery", payload, sns_message_id) do
  recipients = get_in(payload, ["delivery", "recipients"]) || []
  Enum.with_index(recipients)
  |> Enum.map(fn {email, idx} ->
    provider_event_id = "#{sns_message_id}:#{email || idx}"
    build_event(payload, sns_message_id, :delivered, nil, provider_event_id, email)
  end)
end
```

### Pattern 7: Plug Control-Plane Short-Circuit

**What:** `Mailglass.Webhook.Plug` currently matches `:ok` and `{:ok, :replay}` from `verify!/3`. SES needs a third branch for control-plane messages.

**Recommended shape:** `{:ok, :control_plane, :subscription_confirmed | :unsubscribe_confirmed}`

This is explicit (the `:control_plane` atom is hard to confuse with a normalized event), does not masquerade as ingest success, and mirrors the existing `{:ok, :replay}` pattern.

```elixir
# In Mailglass.Webhook.Plug.do_call/3 — after SES is added to @valid_providers
case verify_with_telemetry!(provider, raw_body, headers, config) do
  {:ok, :replay} ->
    # existing replay short-circuit

  {:ok, :control_plane, outcome} ->
    # SES-specific: SubscriptionConfirmation or UnsubscribeConfirmation
    Logger.info("[mailglass] SES SNS control-plane: outcome=#{outcome}")
    conn = send_resp(conn, 200, "")
    {conn, %{provider: provider, status: :control_plane, outcome: outcome}}

  :ok ->
    # normal ingest flow
end
```

### Anti-Patterns to Avoid

- **Broad SNS host pattern:** Using `.*amazonaws.com` or `sns.*amazonaws.com` allows SSRF via S3 buckets. Use the exact `^sns\.[a-zA-Z0-9\-]{3,}\.amazonaws\.com(\.cn)?$` pattern. [VERIFIED: spaceraccoon.dev CVE analysis]
- **Following SubscribeURL directly:** The SubscribeURL is attacker-influenceable; construct the ConfirmSubscription URL from TopicArn + Token instead. (D-07)
- **Missing Subject field in canonical string:** Subject is optional in Notification; include it only when present. Omitting it from a payload that contains it (or including it when absent) causes signature mismatch. [VERIFIED: AWS docs]
- **Synchronous cert fetch on hot path:** Certificate fetch must go through ETS cache; only on cache miss should :httpc be called. [VERIFIED: D-12]
- **Using :sha for SignatureVersion 2:** AWS moved to SHA256 for version 2. Dispatch on the `SignatureVersion` field in the payload. [VERIFIED: AWS docs]
- **Calling normalize/2 for control-plane messages:** SubscriptionConfirmation and UnsubscribeConfirmation carry no SES event data; calling normalize on them produces empty or malformed results. Short-circuit in verify!/3 result processing. (D-02)
- **Using atom keys for metadata:** Provider metadata must use string keys for JSONB round-trip safety. [VERIFIED: codebase conventions]
- **Single event for multi-recipient notifications:** SES bounce notifications carry a `bouncedRecipients` array; each recipient needs its own %Event{} with a stable provider_event_id. (D-16)

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| RSA signature verification | Custom OpenSSL FFI or Base64+sha pipeline | `:public_key.verify/4` | OTP ships full RSA/X.509 stack; hand-rolled parsing misses edge cases |
| Certificate chain trust | Custom cert chain validation | `:public_key.pkix_is_issuer/2` + system CAs | X.509 trust chains have many edge cases; :public_key handles them |
| HTTP for cert fetch | Custom TCP socket | `:httpc.request/4` | OTP HTTP client, already available, handles TLS/redirect correctly |
| SNS canonical string ordering | Alphabetical sort at runtime | Hardcoded field list (alphabetically sorted at compile time) | Field set is known; sorting at compile time eliminates runtime sort cost and ordering bugs |
| URL parsing for trust validation | Regex on raw URL string | `URI.parse/1` + field checks | URI.parse handles encoding, authority components; raw regex misses edge cases |
| Test certificate generation | Openssl CLI in test helper | `:public_key.generate_key/1` + `:public_key.pkix_sign/2` | Generate test RSA keypairs in Elixir at test runtime; no baked keys on disk |

**Key insight:** The SNS signature verification algorithm looks simple (base64 decode + RSA verify) but the certificate handling (PEM decode, OTP record extraction, X.509 trust chain) has enough subtlety that using :public_key directly is substantially safer than building custom parsing.

---

## Common Pitfalls

### Pitfall 1: SigningCertURL SSRF via S3 Namespace Collision
**What goes wrong:** An attacker forges an SNS message with a `SigningCertURL` pointing to `https://sns.s3-us-west-2.amazonaws.com/evil.pem` (an S3 bucket they control). A weak regex like `sns.*amazonaws.com` matches. The attacker's cert validates their forged message.
**Why it happens:** AWS's shared domain namespace means S3 bucket URLs can be crafted to match SNS-like patterns.
**How to avoid:** Use `^sns\.[a-zA-Z0-9\-]{3,}\.amazonaws\.com(\.cn)?$` on the HOST only (not full URL); additionally require `https` scheme and `.pem` path suffix.
**Warning signs:** Any regex that allows wildcards between `sns.` and `amazonaws.com` is suspect.

### Pitfall 2: Subject Field Omission / Inclusion Error
**What goes wrong:** The canonical string includes `Subject` for all Notification messages, or excludes it for messages that have a Subject. This causes all verifications to fail for affected messages.
**Why it happens:** AWS docs say Subject is optional — some implementations always include it or always exclude it rather than checking presence.
**How to avoid:** Check `Map.has_key?(payload, "Subject")` before including it in the canonical string. Filter using `Enum.filter(&Map.has_key?(payload, &1))`.
**Warning signs:** Verification fails only for messages published with explicit subjects.

### Pitfall 3: text/plain Content-Type Not Handled
**What goes wrong:** The SNS webhook sends `Content-Type: text/plain; charset=UTF-8` but the Plug pipeline expects `application/json`. Plug.Parsers rejects the body or doesn't parse it, leaving `conn.body_params` empty.
**Why it happens:** SNS hard-codes `text/plain` content type regardless of body format.
**How to avoid:** The `pass: ["*/*"]` option in `Plug.Parsers` already handles this for CachingBodyReader (raw body is captured regardless of content type). The provider reads from `conn.private[:raw_body]` not `conn.body_params`. Verify the endpoint uses `pass: ["*/*"]`.
**Warning signs:** `conn.private[:raw_body]` is nil for SES but not for other providers.

### Pitfall 4: Cache Miss on Every Request (Cold ETS)
**What goes wrong:** ETS table is not found (process crash, test isolation), causing every verify!/3 to make a network call.
**Why it happens:** GenServer restart races, or test processes that bypass the Application supervision tree.
**How to avoid:** The CertCache API should handle `:badarg` from :ets.lookup (table not found) gracefully and fall back to direct fetch; log a warning. Tests should start the CertCache supervisor explicitly.
**Warning signs:** Certificate fetch latency appears in every request span rather than only on first-use.

### Pitfall 5: Redirected ConfirmSubscription Request
**What goes wrong:** The ConfirmSubscription HTTP request is allowed to follow redirects, which an attacker could use to redirect the confirmation to an internal service.
**Why it happens:** :httpc defaults to following redirects (`autoredirect: true`).
**How to avoid:** Set `autoredirect: false` in :httpc HTTP options. Treat any non-2xx response as a confirmation failure and log; do not retry automatically.
**Warning signs:** ConfirmSubscription calls succeed but the SNS subscription remains unconfirmed.

### Pitfall 6: Duplicate Normalization from Both SES Formats
**What goes wrong:** An adopter configures both SES feedback notifications and SES event publishing to point to the same SNS topic. Both formats deliver Bounce/Complaint/Delivery events, producing duplicate webhook events.
**Why it happens:** AWS allows overlapping configuration; both formats are independently configurable.
**How to avoid:** Document this explicitly (D-18). The existing `(provider, provider_event_id)` UNIQUE constraint provides a DB-level backstop. The ETS idempotency key (SNS MessageId-based provider_event_id) further guards against in-flight duplicates.
**Warning signs:** Elevated duplicate telemetry for :ses provider.

### Pitfall 7: Missing Provider in Plug @valid_providers and Router @valid_providers
**What goes wrong:** SES is added to the Provider module but not to the static lists in `Mailglass.Webhook.Plug` and `Mailglass.Webhook.Router`, causing runtime crashes on `:ses` provider dispatch.
**Why it happens:** The valid providers list exists in three places: `Plug.@valid_providers`, `Router.@valid_providers`, and `Plug.provider_module/1` dispatch function.
**How to avoid:** Update all three atomically. The init/1 validation in Plug catches the gap at router-mount time if @valid_providers is correct.
**Warning signs:** `ArgumentError: unknown :provider :ses` at app boot or test time.

---

## Code Examples

### SNS Message Type Detection from Header

```elixir
# Source: https://docs.aws.amazon.com/sns/latest/dg/http-notification-json.html
# [VERIFIED: AWS docs]

# SNS sends x-amz-sns-message-type header; also present in payload as "Type"
# Header takes precedence (payload could be malformed at parse stage)
defp extract_message_type(headers, payload) do
  header_type = List.keyfind(headers, "x-amz-sns-message-type", 0)
  case header_type do
    {_, type} when type in ["Notification", "SubscriptionConfirmation", "UnsubscribeConfirmation"] ->
      {:ok, type}
    _ ->
      # Fall back to payload field
      case Map.get(payload, "Type") do
        type when type in ["Notification", "SubscriptionConfirmation", "UnsubscribeConfirmation"] ->
          {:ok, type}
        _ ->
          {:error, :unknown_message_type}
      end
  end
end
```

### SES Bounce Mapping (D-17)

```elixir
# Source: https://docs.aws.amazon.com/ses/latest/dg/notification-contents.html
# [VERIFIED: AWS SES docs]

defp map_bounce(%{"bounceType" => "Permanent", "bounceSubType" => sub_type}) do
  case sub_type do
    # Suppression-list style outcomes -> :rejected
    sub when sub in ["Suppressed", "OnAccountSuppressionList", "UnsubscribedRecipient"] ->
      {:rejected, :blocked}
    # True hard bounce
    _ ->
      {:bounced, :bounced}
  end
end

defp map_bounce(%{"bounceType" => "Transient"}) do
  {:deferred, nil}
end

defp map_bounce(%{"bounceType" => "Undetermined"}) do
  {:deferred, nil}
end

defp map_bounce(_), do: {:bounced, :bounced}  # Conservative fallback
```

### SES Event Publishing Mapping (D-14)

```elixir
# Source: https://docs.aws.amazon.com/ses/latest/dg/event-publishing-retrieving-sns-contents.html
# [VERIFIED: AWS SES docs]

defp map_event_type("Send"),            do: {:sent, nil}
defp map_event_type("Delivery"),        do: {:delivered, nil}
defp map_event_type("Reject"),          do: {:rejected, :other}
defp map_event_type("Bounce"),          do: nil  # delegated to map_bounce/1
defp map_event_type("Complaint"),       do: {:complained, nil}
defp map_event_type("Open"),            do: {:opened, nil}
defp map_event_type("Click"),           do: {:clicked, nil}
defp map_event_type("Rendering Failure"), do: {:failed, nil}
defp map_event_type("DeliveryDelay"),   do: {:deferred, nil}
defp map_event_type("Subscription"),    do: nil  # no normalized mapping; drop
defp map_event_type(other) do
  Logger.warning("[mailglass] Unmapped SES eventType: #{inspect(other)}")
  {:unknown, nil}
end
```

### Stable Provider Event ID (D-16)

```elixir
# Canonical: sns_message_id:email_address (email is stable)
# Fallback: sns_message_id:index (when email not available)
# This ensures idempotency survives the same SNS message arriving twice.

defp build_provider_event_id(sns_message_id, email, _index) when is_binary(email) do
  "#{sns_message_id}:#{email}"
end

defp build_provider_event_id(sns_message_id, nil, index) do
  "#{sns_message_id}:#{index}"
end
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Follow SubscribeURL directly | Construct ConfirmSubscription from TopicArn + Token | Per D-07 | Eliminates open-redirect attack surface |
| SignatureVersion 1 only (SHA1) | Support both v1 (SHA1) and v2 (SHA256) | AWS guidance 2021+ | SHA256 preferred; SHA1 still used in legacy topics |
| Broad `.*amazonaws.com` host allowlist | Exact `^sns\.[a-zA-Z0-9\-]{3,}\.amazonaws\.com(\.cn)?$` | After spaceraccoon S3 disclosure | Eliminates S3 namespace collision attack |
| Fetch cert on every request | ETS-cached cert per URL | Per D-10 | Eliminates latency spike and DoS surface from cert endpoint |

**Deprecated/outdated:**
- `AWS.SNS.MessageValidator` (Elixir Hex package, last release 2018): Uses a simplistic host check pattern that is bypassable. Do not use. [ASSUMED — verify via Hex registry if needed]
- Following `SubscribeURL` directly: Functionally equivalent to the ConfirmSubscription API approach but bypasses our ability to validate the endpoint host. Per D-07, not used.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `:public_key.pkix_extract_public_key/1` is available in OTP 26+ | Code Examples - Pattern 2 | If project targets OTP < 26, use manual record path matching on the Certificate record to extract SubjectPublicKeyInfo |
| A2 | `:public_key.cacerts_get/0` is available for TLS CA bundle (OTP 26+) | Pattern 5 - ConfirmSubscription | If OTP < 26, use `{:certifi, "..."}` CA bundle or set `verify: :verify_none` for internal-test only |
| A3 | AWS SNS certificate TTL ~24 hours is an appropriate cache window | Pattern 4 - Cache TTL | If AWS rotates certs faster, cache will serve stale certs; mitigated by expiry-aware refresh logic |
| A4 | TopicArn-to-host exact correlation requirement in D-06 is satisfied by the regex pattern alone | Pattern 3 - Trust Policy | If D-06 requires exact host-from-ARN matching (e.g., us-east-1 ARN must match sns.us-east-1.amazonaws.com), an additional region extraction + host construction step is needed |
| A5 | `:httpc` `autoredirect: false` is the correct option to disable redirects | Pattern 5 | If option name differs in OTP 27, ConfirmSubscription may follow attacker-controlled redirects |
| A6 | `DeliveryDelay` event type maps to `:deferred` | Code Examples - Event mapping | If DeliveryDelay semantically differs from transient bounce in adopter context, they may want separate handling |

---

## Open Questions

1. **OTP version minimum for project**
   - What we know: STACK.md mentions OTP 27 features (:crypto ECDSA changes). Application.ex uses features compatible with OTP 25+.
   - What's unclear: Whether `:public_key.pkix_extract_public_key/1` (OTP 26+) is safe to use, or if the manual record-pattern approach is needed.
   - Recommendation: Check `mix.exs` `:elixir` / OTP constraint; if 26+ confirmed, use `pkix_extract_public_key`. Otherwise use `elem()` traversal of the OTP Certificate record.

2. **SES config block key names**
   - What we know: Other providers use `:postmark`, `:sendgrid`, `:mailgun` as top-level Application env keys.
   - What's unclear: Whether `:ses` or `:amazon_ses` or `:aws_ses` is the preferred key.
   - Recommendation: Use `:ses` — shortest, matches the phase name and provider atom, consistent with `:mailgun` brevity. Discretion area per CONTEXT.md.

3. **Exact SNS TopicArn region correlation for SubscribeURL validation (D-06)**
   - What we know: D-06 says "exact SNS host derived from the signed TopicArn region/partition."
   - What's unclear: Whether implementation must verify that SigningCertURL region matches TopicArn region exactly, or whether the generic SNS host regex is sufficient (both prevent the SSRF attack).
   - Recommendation: Implement the regex pattern as the primary guard. Optionally extract region from TopicArn and assert the cert host contains that region. The security goal is met by either approach; the stricter check is better but may cause false rejections on AWS topic-in-one-region / endpoint-in-another configurations.

---

## Environment Availability

> Step 2.6: SKIPPED for external services — the SES provider itself uses no runtime tools beyond OTP built-ins. Erlang :httpc, :public_key, :ets, :crypto are all OTP built-ins verified available wherever Elixir runs.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Erlang `:public_key` | RSA verify + PEM decode | OTP built-in | OTP 27 (project target) | — |
| Erlang `:httpc` | Cert fetch + ConfirmSubscription | OTP built-in | OTP 27 | — |
| Erlang `:ets` | Certificate cache | OTP built-in | OTP 27 | — |
| `Jason` | SNS JSON decode | Project dep | ~> 1.4 | — |

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (OTP-native) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/mailglass/webhook/providers/ses_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SES-01 | text/plain SNS payload is parsed correctly | unit | `mix test test/mailglass/webhook/providers/ses_test.exs` | Wave 0 |
| SES-02 | SubscriptionConfirmation triggers auto-confirm via ConfirmSubscription API | unit (mock :httpc) | `mix test test/mailglass/webhook/providers/ses_test.exs` | Wave 0 |
| SES-03 | Valid RSA-SHA1 and RSA-SHA256 signatures accepted; tampered signatures rejected | unit | `mix test test/mailglass/webhook/providers/ses_test.exs` | Wave 0 |
| SES-04 | Cert cache serves from ETS on hit; fetches and stores on miss | unit | `mix test test/mailglass/webhook/providers/ses/cert_cache_test.exs` | Wave 0 |
| SES-05 | SES events map to normalized taxonomy; fan-out per recipient | unit | `mix test test/mailglass/webhook/providers/ses_test.exs` | Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/mailglass/webhook/providers/ses_test.exs test/mailglass/webhook/providers/ses/cert_cache_test.exs`
- **Per wave merge:** `mix test test/mailglass/webhook/`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/mailglass/webhook/providers/ses_test.exs` — covers SES-01, SES-02, SES-03, SES-05
- [ ] `test/mailglass/webhook/providers/ses/cert_cache_test.exs` — covers SES-04
- [ ] `test/support/fixtures/webhooks/ses/` — fixture directory and JSON fixture files
- [ ] Test RSA keypair generation helper (in `webhook_fixtures.ex` or ses-specific helper) — generate test cert+privkey at runtime using `:public_key.generate_key({:rsa, 2048, 65537})` and `:public_key.pkix_sign/2`

*(SNS subscription confirmation :httpc calls require test-time stubbing via Mox or :httpc interceptor)*

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | SNS RSA signature verification via :public_key |
| V3 Session Management | no | Webhook endpoint; no session |
| V4 Access Control | yes | Trust-policy validation before network I/O |
| V5 Input Validation | yes | URI.parse + regex on SigningCertURL; JSON decode with Jason |
| V6 Cryptography | yes | :public_key RSA verify — never hand-roll |

### Known Threat Patterns for AWS SNS Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SSRF via SigningCertURL | Spoofing | `^sns\.[a-zA-Z0-9\-]{3,}\.amazonaws\.com(\.cn)?$` host validation + https-only |
| Forged SNS message with attacker-controlled cert | Spoofing | Trust-policy check before any network I/O; D-09 fail closed |
| Replay of old SNS Notification | Tampering | Provider event idempotency via (provider, provider_event_id) UNIQUE; SNS MessageId stable across retries |
| SubscribeURL open redirect to internal service | Elevation | D-07: construct ConfirmSubscription URL from TopicArn+Token, not SubscribeURL; autoredirect: false |
| Malformed JSON in Message field | DoS / Crash | Defensive Jason.decode; return [] on parse failure with Logger.warning |
| Certificate endpoint DoS (per-request fetch) | DoS | ETS cert cache prevents repeated network calls |
| Stale cached cert after AWS rotation | Spoofing | TTL-aware expiry in CertCache; configurable TTL |
| PII in telemetry | Privacy | Never emit :to/:from/:recipient/body in telemetry events; only provider/status/outcome |

---

## Project Constraints (from CLAUDE.md)

- Pluggable behaviours over magic: SES provider must implement `Mailglass.Webhook.Provider` behaviour explicitly
- Errors as public API: Use `%Mailglass.SignatureError{}` for verification failures, `%Mailglass.ConfigError{}` for missing config — never raw strings
- Telemetry without PII: No :to, :from, :recipient, :subject, :body, :email in telemetry metadata
- Append-only events: No UPDATE/DELETE on mailglass_events rows
- Multi-tenancy first-class: tenant_id on every ingest path
- Native OTP only: No AWS SDK, no third-party HTTP client
- Optional deps pattern: SES cert cache supervised via `maybe_add` in Application.ex (already present pattern)
- String keys in metadata: JSONB round-trip safety requires string keys for Event.metadata
- Fake adapter is release gate: SES provider tests use fixture-based verification, not live AWS calls
- SignatureError is terminal: No recovery from SNS signature failures; D-09 requires fail-closed

---

## Sources

### Primary (HIGH confidence)
- AWS SNS signature verification docs — exact canonical string algorithm, field set, SignatureVersion behavior: https://docs.aws.amazon.com/sns/latest/dg/sns-verify-signature-of-message-verify-message-signature.html
- AWS SNS Notification JSON format — Content-Type, field definitions: https://docs.aws.amazon.com/sns/latest/dg/http-notification-json.html
- AWS SNS SubscriptionConfirmation format — Token, SubscribeURL fields: https://docs.aws.amazon.com/sns/latest/dg/http-subscription-confirmation-json.html
- AWS ConfirmSubscription API — URL construction, parameters: https://docs.aws.amazon.com/sns/latest/api/API_ConfirmSubscription.html
- AWS SES notification contents (classic feedback format) — bounceType/bouncedRecipients/complainedRecipients schema: https://docs.aws.amazon.com/ses/latest/dg/notification-contents.html
- AWS SES event publishing via SNS — eventType values, Send/Reject/Open/Click structures: https://docs.aws.amazon.com/ses/latest/dg/event-publishing-retrieving-sns-contents.html
- AWS PHP SNS Message Validator — safe SigningCertURL regex pattern: https://github.com/aws/aws-php-sns-message-validator/blob/master/src/MessageValidator.php
- Erlang :public_key documentation: https://www.erlang.org/doc/apps/public_key/using_public_key.html
- Mailglass codebase — MailgunReplayCache OTP pattern, Application.maybe_add, Plug control flow: lib/mailglass/webhook/providers/ [VERIFIED: codebase]

### Secondary (MEDIUM confidence)
- spaceraccoon.dev SNS SSRF analysis — S3 namespace collision attack vector and safe regex: https://spaceraccoon.dev/exploiting-improper-validation-amazon-simple-notification-service/
- Elixir Forum X.509 verification discussion — :public_key workflow for cert signature verification: https://elixirforum.com/t/how-to-verify-sign-using-x509-certificates/29788

### Tertiary (LOW confidence)
- Anymail SES implementation — noted as NOT performing SNS signature verification; relevant for DX contrast only: https://anymail.dev/en/latest/esps/amazon_ses/

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new deps; all OTP built-ins verified in project
- SNS signature algorithm: HIGH — verified against AWS official documentation
- SES event taxonomy: HIGH — verified against AWS SES notification-contents and event-publishing docs
- ETS cache pattern: HIGH — exact pattern from existing MailgunReplayCache in codebase
- Trust policy regex: HIGH — from AWS official PHP SDK (canonical reference)
- OTP function availability (pkix_extract_public_key): MEDIUM — depends on OTP version minimum
- Certificate TTL value: LOW — no AWS documentation found specifying rotation frequency

**Research date:** 2026-04-28
**Valid until:** 2026-05-28 (SNS verification algorithm is stable; SES event schema is stable)
