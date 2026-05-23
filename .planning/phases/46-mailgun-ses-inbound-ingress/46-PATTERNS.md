# Phase 46: Mailgun + SES Inbound Ingress - Pattern Map

**Mapped:** 2026-05-23
**Files analyzed:** 13 (7 new, 6 modified) + 5 reuse-only cross-package anchors
**Analogs found:** 13 / 13 (every new/modified file has a strong in-repo analog)

This phase is almost entirely *plumbing existing tested security primitives into a
second entry point* (RESEARCH "Don't Hand-Roll" key insight). Every new file copies
an established in-repo pattern; the genuinely-new code is flat-field Mailgun HMAC
extraction, the S3Fetcher behaviour+adapter+gateway, two closed-type errors, one
migration, and the widened plug `case`.

> **Anchor drifts the analogs must reflect (from RESEARCH §"Anchor DRIFT"):**
> 1. There is **no** `optional_deps/oban.ex` file — `MailglassInbound.OptionalDeps.Oban`
>    lives *inside* `optional_deps.ex` (second module, lines 12-71). New `ExAwsS3`
>    gateway: same file or a new file, both fine.
> 2. The dedupe index `mailglass_inbound_records_postmark_idempotency_idx` is
>    **provider-agnostic columns** despite its name — Mailgun Message-Id rows dedupe
>    through it with **no new migration**. `persist.ex:194-199` already matches it.
> 3. The MD5-fingerprint index is **SendGrid-scoped** (`WHERE provider = 'sendgrid'`)
>    — Mailgun's MD5 fallback needs a **new sibling migration** + a `load_duplicate/5`
>    Mailgun clause.
> 4. The inbound plug rescues **core's** `Mailglass.SignatureError` only (`plug.ex:115`).
>    The new `MailglassInbound.SignatureError` requires the rescue to catch **both**.
> 5. `plug.ex:241-247` does **not** discard `verify!`'s return — it threads it into
>    `verification_facts`. The widening is about *adding variants* (`{:replay}` /
>    `{:control_plane, _}`), not about consuming a discarded value.

---

## File Classification

### NEW files

| New File | Role | Data Flow | Closest Analog | Match Quality |
|----------|------|-----------|----------------|---------------|
| `mailglass_inbound/lib/mailglass_inbound/ingress/providers/mailgun.ex` | provider (verify+normalize) | request-response + transform | `ingress/providers/sendgrid.ex` (struct-based `verify!/normalize`, raw-MIME) + core `webhook/providers/mailgun.ex` (HMAC math, replay) | exact (role) + role-match (crypto) |
| `mailglass_inbound/lib/mailglass_inbound/ingress/providers/ses.ex` | provider (verify+normalize) | request-response + file-I/O (S3) | `ingress/providers/sendgrid.ex` (shape) + core `webhook/providers/ses.ex` (X.509 verify, control-plane dispatch) | exact (role) + role-match (crypto/control-plane) |
| `mailglass_inbound/lib/mailglass_inbound/s3_fetcher.ex` | behaviour | file-I/O | `ingress/provider.ex` (behaviour `@callback` shape) | role-match |
| `mailglass_inbound/lib/mailglass_inbound/s3_fetcher/fake.ex` | adapter (test default) | file-I/O | fake-adapter-first DNA (D-13); config-seam from `ses.ex:351-362` `httpc_client/1` | role-match (no exact fake fetcher exists yet) |
| `mailglass_inbound/lib/mailglass_inbound/s3_fetcher/ex_aws_s3.ex` | adapter (real, gated) | file-I/O | `MailglassInbound.OptionalDeps.Oban.enqueue_*` (gated-call wrapper); `Mailglass.OptionalDeps.GenSmtp.decode/2` (never-raise gateway) | role-match |
| `mailglass_inbound/lib/mailglass_inbound/optional_deps/ex_aws_s3.ex` *(or add to `optional_deps.ex`)* | gateway | event-driven (avail probe) | `lib/mailglass/optional_deps/gen_smtp.ex` (gateway shape) + `MailglassInbound.OptionalDeps.Oban` (inbound-local precedent) | exact |
| `mailglass_inbound/lib/mailglass_inbound/signature_error.ex` | error (closed-type) | — | `mailglass_inbound/lib/mailglass_inbound/mime_error.ex` (closed `@types` + `__types__/0`) + core `lib/mailglass/errors/signature_error.ex` (no-recovery `:provider` field, message format) | exact |
| `mailglass_inbound/lib/mailglass_inbound/s3_fetch_error.ex` | error (closed-type) | — | `mailglass_inbound/lib/mailglass_inbound/mime_error.ex` | exact |
| `mailglass_inbound/priv/repo/migrations/<ts>_add_mailgun_fingerprint_index.exs` | migration | — | `priv/repo/migrations/20260506220000_add_sendgrid_fingerprint_and_replay_contract_fields.exs` | exact |

### MODIFIED files

| Modified File | Role | Data Flow | Change Shape | Analog for the change |
|---------------|------|-----------|--------------|----------------------|
| `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex` | plug (orchestration) | request-response | allowlist `→ [:postmark,:sendgrid,:mailgun,:ses]` (one switch); widen `do_call/2` to a 3-variant result `case`; rescue BOTH SignatureError structs | core `lib/mailglass/webhook/plug.ex:119-161` (proven 3-variant case) |
| `mailglass_inbound/lib/mailglass_inbound/ingress/provider.ex` | behaviour | — | widen `verify!` `@callback` return type to the 3-variant union | core `webhook/provider.ex` callback typespecs |
| `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex` | persistence | CRUD | add Mailgun clause to `load_duplicate/5` (Message-Id via generic index + MD5 fallback) | existing `load_duplicate(repo, _, "sendgrid", …)` at `persist.ex:81-101` |
| `mailglass_inbound/mix.exs` | config | — | add `{:ex_aws, "~> 2.7", optional: true}` + `{:ex_aws_s3, "~> 2.5", optional: true}` | existing `{:gen_smtp, "~> 1.3", optional: true}` (`mix.exs:76`); `no_warn_undefined` list (`mix.exs:57`) |
| `.credo.exs` | config | — | add `ExAws => MailglassInbound.OptionalDeps.ExAwsS3` (+ `ExAws.S3`) to `gated_modules` | existing `gated_modules` entries (`.credo.exs:48-56`) |
| core `lib/mailglass/webhook/providers/ses.ex` *(optional extract)* | provider | — | extract `verify_envelope!/2` seam; refactor `verify!/3` to call it then `dispatch_message_type` | self (Pattern 2 below) — **smallest-blast-radius split, see Open Question 2** |

---

## Pattern Assignments

### `ingress/providers/mailgun.ex` (provider, request-response + transform) — NEW

**Primary analog:** `mailglass_inbound/lib/mailglass_inbound/ingress/providers/sendgrid.ex`
(struct-based `verify!(%Request{}, config)` + `normalize(%Request{})` shape, raw-MIME handling, evidence map).
**Crypto analog:** `lib/mailglass/webhook/providers/mailgun.ex` (HMAC math + skew + replay).

**Decision (RESEARCH Pattern 1 — the override wins):** **reimplement** the ~15-line HMAC
in inbound over **flat form fields** (`request.params["timestamp"]/["token"]/["signature"]`).
Do NOT call core `Mailgun.verify!/3` — it runs `Jason.decode` first (`mailgun.ex:26,83-94`)
and expects a nested `%{"signature" => %{...}}` object, so it `SignatureError`s every
authentic *inbound* request.

**Module/behaviour skeleton to copy** (from `sendgrid.ex:1-21`):
```elixir
defmodule MailglassInbound.Ingress.Providers.Mailgun do
  @moduledoc false
  @behaviour MailglassInbound.Ingress.Provider
  alias Mailglass.ConfigError
  alias MailglassInbound.{InboundMessage, SignatureError}   # NEW inbound SignatureError (D-46-19)
  alias MailglassInbound.Ingress.Request
  alias Mailglass.Webhook.Providers.MailgunReplayCache       # REUSE running cache (D-46-02)

  @impl MailglassInbound.Ingress.Provider
  def verify!(%Request{params: params}, %{} = config) when is_map(params), do: ...
```

**HMAC core to reimplement** (the shared math, lifted from core `mailgun.ex:29-37,124-129,131-157,39-44`):
```elixir
# expected signature
expected = :crypto.mac(:hmac, :sha256, signing_key, timestamp <> token) |> Base.encode16(case: :lower)
# constant-time, length-guarded compare (mailgun.ex:124-129)
Plug.Crypto.secure_compare(expected, String.downcase(provided))   # raise SignatureError(:bad_signature, provider: :mailgun) on false
# then verify_timestamp! (port mailgun.ex:131-157: Integer.parse → DateTime.from_unix → tolerance/future_skew)
# then replay guard:
case MailgunReplayCache.check_and_put(token, expires_at) do  # mailgun_replay_cache.ex:8-9, returns :ok | {:error, :replay}
  :ok           -> {:ok, facts}     # facts map e.g. %{auth: :hmac}
  {:error, :replay} -> {:replay}    # 200 no-op (D-46-06) — NEVER raise/401
end
```
Config resolution mirrors core `fetch_signing_key!` (`mailgun.ex:64-81`): `config[:signing_key]`
binary; raise `ConfigError.new(:webhook_verification_key_missing, ...)` when absent.

**Normalize — two modes** (D-46-09; branch on presence of `params["body-mime"]`, per Open Question 3):
- **Raw-MIME mode** (`body-mime` present): feed into `MailglassInbound.MIME.parse/1`
  (`mime.ex:108` — `{:ok, repr} | {:error, MIMEError.t()}`, never raises). This is the
  parser's intended first consumer.
- **Parsed mode** (default): normalize from `body-plain`/`body-html`/`stripped-*` +
  `message-headers` + attachment fields, building the same `%InboundMessage{}` shape
  `sendgrid.ex:32-49` and `postmark.ex:28-45` build. **Reuse the address/datetime/header
  helpers** from `sendgrid.ex` (`normalize_address_header/1` :307, `parse_address/1` :316,
  `parse_datetime/1` :333, `normalize_headers/1` :157, `first_header/2` :164) — they are
  RFC-5322-shaped and copy cleanly.

**Message-Id extraction** (D-46-10, RESEARCH Code Examples) — from `message-headers` JSON
ordered `[name, value]` pairs, case-insensitive; `nil` → MD5(raw) fallback. **NEVER use `token`
for dedupe** (it is the replay nonce).
```elixir
with raw when is_binary(raw) <- params["message-headers"], {:ok, pairs} <- Jason.decode(raw) do
  Enum.find_value(pairs, fn [name, value] -> if String.downcase(name) == "message-id", do: value end)
else _ -> nil end
```

**Evidence map** (copy `sendgrid.ex:51-61` shape): `%{raw_payload:, raw_headers:, raw_mime:,
verification_facts: %{}, parse_warnings:, attachment_blobs:}`. Persist raw provider source
to evidence (MGUN-03). Attachment blobs follow the `"index:filename" => bytes` convention
(`sendgrid.ex:233`, `postmark.ex:208-220`).

---

### `ingress/providers/ses.ex` (provider, request-response + file-I/O) — NEW

**Primary analog:** `ingress/providers/sendgrid.ex` (provider shape).
**Crypto/control-plane analog:** `lib/mailglass/webhook/providers/ses.ex` (X.509 verify
`ses.ex:55-110`, `dispatch_message_type/3` `ses.ex:137-188`, `CertCache`, `TrustPolicy`).

**Decision (RESEARCH Pattern 2 — extract/reuse for SES):** the SNS envelope is
byte-identical inbound vs outbound, so reuse core's X.509 verify. Recommended seam:
add `Mailglass.Webhook.Providers.SES.verify_envelope!/2 :: {:ok, sns_payload}` to core
(refactor `verify!/3` to call it then `dispatch_message_type`). Inbound calls the seam,
then drives its own dispatch (Open Question 2; falls back to calling existing `verify!/3`
if the core refactor is judged too risky at plan time).

**Three-way dispatch the inbound provider drives** (mirrors core `ses.ex:137-188`):
- `Type == "Notification"` → continue to S3-fetch / inline-content → `{:ok, facts}`.
- `Type in ["SubscriptionConfirmation","UnsubscribeConfirmation"]` → **reuse**
  `dispatch_message_type` (it auto-confirms via `TrustPolicy.valid_subscribe_url?/1` and
  constructs ConfirmSubscription from signed TopicArn+Token, `ses.ex:139-174`) → return
  `{:control_plane, 200}` (NOT a raise/401 — D-46-06).
- forged signature / failed TrustPolicy → raise `MailglassInbound.SignatureError`.

**Reuse-only calls (do NOT reimplement, do NOT re-supervise — D-46-02):**
```elixir
alias Mailglass.Webhook.Providers.SES.{CertCache, TrustPolicy}
TrustPolicy.valid_cert_url?(cert_url)        # trust_policy.ex:37 — pure SSRF guard
TrustPolicy.valid_subscribe_url?(url)        # trust_policy.ex:72
CertCache.fetch_public_key(cert_url)         # cert_cache.ex:35 — {:ok, key} | :miss (ETS, global)
# :public_key.verify/4 for the RSA check (ses.ex:104)
```

**Notification → S3 fetch** (D-46-12, primary path): from the verified SES payload,
`receipt.action.type == "S3"` carries `bucketName` + `objectKey` (`== mail.messageId`).
Call the `S3Fetcher` behaviour (config-resolved module, see below) with bounded retry
(Pattern 5), feed the returned binary into `MailglassInbound.MIME.parse/1`. SNS-inline
`content` (UTF-8/Base64, ≤150 KB) is the secondary small-message path — decode and feed
to the same `MIME.parse/1`.

**Config resolution seam** (mirror `ses.ex:351-362` `httpc_client/1` config-map-then-app-env):
```elixir
defp s3_fetcher(config) do
  case Map.get(config, :s3_fetcher) do
    mod when is_atom(mod) and not is_nil(mod) -> mod
    _ -> :mailglass_inbound |> Application.get_env(:ses, []) |> Keyword.get(:s3_fetcher, default_fetcher())
  end
end
# default_fetcher/0 → S3Fetcher.Fake in :test (fake-first D-13), S3Fetcher.ExAwsS3 otherwise
```

---

### `s3_fetcher.ex` (behaviour, file-I/O) — NEW

**Analog:** `ingress/provider.ex` (the `@behaviour` + `@callback` idiom).
```elixir
defmodule MailglassInbound.S3Fetcher do
  @moduledoc false
  @callback fetch(bucket :: String.t(), key :: String.t(), opts :: keyword()) ::
              {:ok, binary()} | {:error, term()}
end
```
Provider behaviour skeleton it copies (`provider.ex:1-24`): module attribute aliases at
top, `@type`s, `@callback`. Keep `@moduledoc false` (package-internal).

---

### `s3_fetcher/fake.ex` (adapter, test default) — NEW

**Analog:** fake-adapter-first DNA (D-13, CLAUDE.md "Fake adapter is the merge-blocking
release gate"). No existing fake *fetcher* exists — closest precedent for a configurable
test stub is the config-map seam in `ses.ex:351-362`.

Surface (Claude's discretion per D-46-13): implement `@behaviour MailglassInbound.S3Fetcher`;
return canned `{:ok, binary}` from a configured map, and support returning `{:error, _}`
for the first N calls to exercise the SESI-05 bounded-retry path (RESEARCH test map line 508:
"Fake returns :error first N"). Keep it dependency-free so it is the safe default in `:test`.

---

### `s3_fetcher/ex_aws_s3.ex` (adapter, real, gated) — NEW

**Analogs:** `MailglassInbound.OptionalDeps.Oban.enqueue_inbound_execution/3`
(`optional_deps.ex:60-70` — gated-call wrapper that checks availability then applies) and
`Mailglass.OptionalDeps.GenSmtp.decode/2` (`gen_smtp.ex:81-89` — never-raise wrapper).

```elixir
defmodule MailglassInbound.S3Fetcher.ExAwsS3 do
  @behaviour MailglassInbound.S3Fetcher
  @impl true
  def fetch(bucket, key, _opts) do
    case MailglassInbound.OptionalDeps.ExAwsS3.get_object(bucket, key) do
      {:ok, %{body: body}} when is_binary(body) -> {:ok, body}   # D-46-15
      {:error, reason} -> {:error, reason}
    end
  end
end
```
**CRITICAL:** all `ExAws`/`ExAws.S3` references go through the gateway only (Pitfall 5);
this adapter must NOT name `ExAws` directly or the `--no-optional-deps --warnings-as-errors`
lane breaks.

---

### `optional_deps/ex_aws_s3.ex` (gateway, event-driven) — NEW *(or append to `optional_deps.ex`)*

**Analog (shape):** `lib/mailglass/optional_deps/gen_smtp.ex` — `@compile {:no_warn_undefined, ...}`
+ `available?/0` (`Code.ensure_loaded?`) + never-raise wrapper.
**Analog (inbound-local precedent):** `MailglassInbound.OptionalDeps.Oban` (`optional_deps.ex:12-71`).

> **DRIFT #1:** there is no `optional_deps/oban.ex` to mirror as a *file* — `Oban` lives
> inside `optional_deps.ex`. Put `ExAwsS3` either in the same `optional_deps.ex` or a new
> `optional_deps/ex_aws_s3.ex`; both are fine.

**Gateway template** (lift `gen_smtp.ex:44-57,81-89` exactly, swap the dep):
```elixir
defmodule MailglassInbound.OptionalDeps.ExAwsS3 do
  @moduledoc "Gateway for the optional ex_aws/ex_aws_s3 deps. ..."
  @compile {:no_warn_undefined, [ExAws, ExAws.S3]}

  @spec available?() :: boolean()
  def available?, do: Code.ensure_loaded?(ExAws.S3)

  # never-raise wrapper around: ExAws.S3.get_object(bucket, key) |> ExAws.request()
  @spec get_object(String.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def get_object(bucket, key) do
    ExAws.S3.get_object(bucket, key) |> ExAws.request()    # => {:ok, %{body: binary, ...}} (A1 — verify key in test)
  rescue
    e -> {:error, {:error, e}}
  catch
    :exit, reason -> {:error, {:exit, reason}}
  end
end
```
**Inbound-local placement (D-46-14)** — NOT core. SESI-04's literal
`Mailglass.OptionalDeps.ExAwsS3` is an erratum (consumer lives in inbound; core's
`NoBareOptionalDepReference` is `lib/mailglass/`-scoped). The `MailglassInbound.OptionalDeps`
moduledoc (`optional_deps.ex:6-8`) already states the inbound-gateway contract.

---

### `signature_error.ex` (error, closed-type) — NEW

**Analog (shape):** `mailglass_inbound/lib/mailglass_inbound/mime_error.ex` — closed `@types`,
`@derive {Jason.Encoder, only: [:type, :message, :context]}` (excludes `:cause`), `__types__/0`
with `@doc since:`, package-local (does NOT implement core `Mailglass.Error` behaviour).
**Analog (semantics/fields):** core `lib/mailglass/errors/signature_error.ex` — no-recovery
contract, `:provider` field, atom-aligned `format_message/2`.

**Hybrid to write:** MIMEError's *package-local closed-type discipline* + SignatureError's
*`:provider` field + per-type messages*. Closed `:type` set covers the inbound failure modes
from D-46-19 (forged Mailgun HMAC, forged SES SNS signature, hijacked/failed-TrustPolicy
SubscribeURL). It does NOT implement `Mailglass.Error` callbacks (mirror `mime_error_test.exs:50-55`).

```elixir
defmodule MailglassInbound.SignatureError do
  @moduledoc "..."   # mirror mime_error.ex moduledoc structure + api_stability.md pointer
  @types [:bad_signature, :missing_header, :malformed_header, :timestamp_skew, :subscribe_url_untrusted]  # planner-final set
  @derive {Jason.Encoder, only: [:type, :message, :context]}
  defexception [:type, :message, :cause, :context, :provider]   # :provider like core signature_error.ex:59

  @doc since: "0.2.0"
  def __types__, do: @types
  @impl true
  def message(%__MODULE__{message: m}), do: m
  # new/2 builder mirroring core signature_error.ex:105-115 (validates type in @types, formats message)
end
```
**Test analog:** `mime_error_test.exs` (`__types__/0` closed set, field set, `:cause` JSON
exclusion, package-local assertion). Add a `__types__/0`-vs-`api_stability.md` contract test
(D-46-19) + CHANGELOG entry.

---

### `s3_fetch_error.ex` (error, closed-type) — NEW

**Analog:** `mailglass_inbound/lib/mailglass_inbound/mime_error.ex` (verbatim shape).
Closed `:type` set `[:s3_object_not_ready, :s3_fetch_failed]` (D-46-17). Do NOT bolt an
atom onto core `Mailglass.Error`/`SignatureError` or `MailglassInbound.MIMEError`.
Mirror `mime_error.ex:30-48` exactly (only `@types`, moduledoc per-type docs, and
`@doc since:` differ). Test analog: `mime_error_test.exs`.

---

### Migration `<ts>_add_mailgun_fingerprint_index.exs` (migration) — NEW

**Analog:** `priv/repo/migrations/20260506220000_add_sendgrid_fingerprint_and_replay_contract_fields.exs`.

> **DRIFT #3:** the existing fingerprint unique index is `WHERE provider = 'sendgrid'`.
> The `raw_mime_fingerprint` *generated column already exists* (created in 20260506220000),
> so this migration adds **only** the Mailgun-scoped (or generalized) partial unique index.

Copy the `create unique_index(:mailglass_inbound_evidence, [:tenant_id, :provider, :raw_mime_fingerprint], ...)`
form from `20260506220000:11-16`, changing the `where:` predicate to
`"provider = 'mailgun' AND raw_mime_fingerprint IS NOT NULL"` and a new `name:`
(e.g. `:mailglass_inbound_records_mailgun_fingerprint_idx`). Pair with `down/0` that
`drop_if_exists`. **No migration needed for the Mailgun Message-Id path** (DRIFT #2 — the
generic `_postmark_idempotency_idx` already covers it).

---

### `ingress/plug.ex` (plug, request-response) — MODIFIED

**Analog for the change:** core `lib/mailglass/webhook/plug.ex:119-161` (the proven
3-variant `verify!`-return `case`).

**Change 1 — allowlist (one switch, D-46-05, MGUN-04):** `plug.ex:36`
`unless provider in [:postmark, :sendgrid]` → `[:postmark, :sendgrid, :mailgun, :ses]`,
and extend `provider_module/1` (`plug.ex:372-373`) with `:mailgun`/`:ses` clauses. Extend
`build_request!/2` (`plug.ex:178-201`), `resolve_config!/3` (`plug.ex:217-239`),
`verify_request!/3` (`plug.ex:241-247`), `normalize_request!/2` (`plug.ex:249-255`) with
`:mailgun`/`:ses` clauses — follow the existing per-provider clause style.

**Change 2 — widen `do_call/2` result contract (D-46-06).** Today `do_call/2` (`plug.ex:53-61`)
calls `verify_request!` and threads the return into `verification_facts` (a single
persist-or-error path). Add a `case` on the widened return, copying core's shape:
```elixir
# Source: lib/mailglass/webhook/plug.ex:125-161 (core ALREADY does this)
case verify_request!(provider, request, config) do
  {:replay}             -> send_json(conn, 200, %{status: "replay"}); {resp, %{status: :replay, ...}}        # no InboundRecord
  {:control_plane, _st} -> send_json(conn, 200, %{status: "control_plane"}); {resp, %{status: :control_plane, ...}}  # no InboundRecord
  {:ok, facts}          -> # existing tenant → normalize → build_handoff(.., facts) → persist → dispatch flow (plug.ex:58-65)
end
```
Keep PII-free telemetry stop-meta (`status: :replay` / `:control_plane`). Replay and
control-plane MUST be 200 no-ops — never `SignatureError`/401 (providers retry-storm,
RESEARCH Pitfall 2 + Anti-Patterns).

**Change 3 — rescue BOTH SignatureError structs (DRIFT #4, RESEARCH Open Question 1 rec).**
`plug.ex:28` aliases `Mailglass.{ConfigError, SignatureError, ...}` and `plug.ex:115`
`rescue e in SignatureError` catches core's only. Mailgun/SES raise the NEW
`MailglassInbound.SignatureError`. Change to:
```elixir
rescue
  e in [Mailglass.SignatureError, MailglassInbound.SignatureError] ->   # both → 401
    resp = send_json(conn, 401, %{status: "rejected", reason: Atom.to_string(e.type)})
    {resp, %{provider: provider, status: :rejected}}
```
Leave Postmark/SendGrid raising core's error untouched (smallest blast radius). Both
structs expose `.type` (atom), so the existing `Atom.to_string(e.type)` body still works.

---

### `ingress/provider.ex` (behaviour) — MODIFIED

**Change:** widen the `verify!` `@callback` return from `:: map()` (`provider.ex:14-18`) to
the 3-variant union (D-46-07). Trend all four providers toward the single
`verify!(%Request{}, config)` arity (SendGrid already uses it; `sendgrid.ex:11`,
`provider.ex` currently types the legacy `verify!(raw_body, headers, config)` arity — both
the struct arity and the new return need to be expressible).
```elixir
@callback verify!(Request.t(), config :: map()) ::
            {:ok, verification_facts :: map()}      # persist
          | {:replay}                               # Mailgun replay → 200 no-op
          | {:control_plane, http_status :: pos_integer()}   # SES control → 200 no-op
          # forged input RAISES SignatureError — not a tuple variant
```
Postmark/SendGrid wrap their current `%{auth: :basic_auth, ...}` map as `{:ok, facts}`.

---

### `ingress/persist.ex` (persistence, CRUD) — MODIFIED

**Analog for the change:** the existing `load_duplicate(repo, tenant_id, "sendgrid", _message, evidence)`
clause at `persist.ex:81-101` (MD5-fingerprint fallback) and the generic
`load_duplicate(repo, tenant_id, provider, %InboundMessage{provider_message_id: ...})` at
`persist.ex:105-116` (Message-Id dedupe).

**Change (DRIFT #3):** add a Mailgun fingerprint clause mirroring `persist.ex:81-101`
(or generalize to "no provider_message_id → fingerprint"), querying with the new Mailgun
`where: "provider = 'mailgun' AND raw_mime_fingerprint IS NOT NULL"` index. Mailgun rows
*with* a Message-Id already dedupe via the generic clause `persist.ex:105-116` + the generic
`_postmark_idempotency_idx` (DRIFT #2) — `duplicate_constraint?/1` (`persist.ex:194-199`)
already matches that constraint name for any provider. The fingerprint clause is only for
the no-Message-Id fallback.

```elixir
# add alongside persist.ex:81 (SendGrid clause), same query shape, provider = "mailgun"
defp load_duplicate(repo, tenant_id, "mailgun", _message, evidence) do
  case evidence_raw_mime_fingerprint(evidence) do   # persist.ex:201-211 reused as-is
    nil -> nil
    fingerprint -> repo.one(from r in InboundRecord, join: e in InboundEvidence, ...
                              where: ... and e.provider == ^"mailgun" and fragment("md5(?)", e.raw_mime) == ^fingerprint)
  end
end
```

---

### `mix.exs` (config) — MODIFIED

**Analog:** the existing `{:gen_smtp, "~> 1.3", optional: true}` line (`mix.exs:76`) and
the `no_warn_undefined` list (`mix.exs:57`).
**Change (D-46-15, D-46-20):** add `{:ex_aws, "~> 2.7", optional: true}` +
`{:ex_aws_s3, "~> 2.5", optional: true}` to `deps/0` (`mix.exs:65-82`). Because all access
is gateway-mediated (no bare references in inbound code), **do NOT** add `ExAws`/`ExAws.S3`
to the project-level `no_warn_undefined` (`mix.exs:57`) — the gateway's own
`@compile {:no_warn_undefined, [ExAws, ExAws.S3]}` covers it (same rationale as the
gen_smtp comment at `mix.exs:72-75`). Record the STACK-lock departure in CHANGELOG (D-46-20).

---

### `.credo.exs` (config) — MODIFIED

**Analog:** existing `gated_modules` map (`.credo.exs:48-56`).
**Change (Pitfall 5):** add `ExAws => MailglassInbound.OptionalDeps.ExAwsS3` (and
`ExAws.S3 => MailglassInbound.OptionalDeps.ExAwsS3` if the check keys on the call root) so
`NoBareOptionalDepReference` flags any stray ExAws reference outside the gateway. The
`included_path_prefixes` already covers `mailglass_inbound/lib/` (`.credo.exs:60`).

---

### core `lib/mailglass/webhook/providers/ses.ex` (provider) — MODIFIED *(optional extract)*

**Analog:** self (Pattern 2). Recommended: factor `verify!/3`'s steps 1-5
(decode → `TrustPolicy.valid_cert_url?` → `fetch_public_key!` → `build_canonical_string`
→ `:public_key.verify`) into a public `verify_envelope!(raw_body, config) :: {:ok, sns_payload}`
(`ses.ex:55-106` becomes the seam body), then have `verify!/3` call `verify_envelope!` then
`dispatch_message_type` (`ses.ex:109`). This is the only change to v1.x-stable outbound code
in the phase; it touches the JSON-identical SNS path (no Mailgun-style JSON coupling), so the
blast radius is small. **Fallback** (if plan-time review judges it too risky): inbound calls
existing `verify!/3` and re-decodes the Notification body (acceptable but re-decodes once).

---

## Shared Patterns

### Closed-type error discipline
**Source:** `mailglass_inbound/lib/mailglass_inbound/mime_error.ex` (+ test
`mime_error_test.exs`); semantics from core `lib/mailglass/errors/signature_error.ex`.
**Apply to:** `signature_error.ex`, `s3_fetch_error.ex`.
```elixir
@types [...]                                            # closed atom set
@derive {Jason.Encoder, only: [:type, :message, :context]}   # :cause excluded → no PII leak
defexception [:type, :message, :cause, :context]       # + :provider for SignatureError
@doc since: "0.2.0"
def __types__, do: @types                              # tested vs docs/api_stability.md
```
Package-local (no `Mailglass.Error` behaviour); CHANGELOG + `@since` per add (D-46-17, D-46-19).

### Optional-dep gateway (no bare references)
**Source:** `lib/mailglass/optional_deps/gen_smtp.ex` (shape) +
`MailglassInbound.OptionalDeps.Oban` (`optional_deps.ex:12-71`, inbound-local precedent).
**Apply to:** `optional_deps/ex_aws_s3.ex`, and (transitively) all ExAws access in
`s3_fetcher/ex_aws_s3.ex`.
```elixir
@compile {:no_warn_undefined, [ExAws, ExAws.S3]}
def available?, do: Code.ensure_loaded?(ExAws.S3)
# never-raise wrapper; bare ExAws refs banned everywhere else (NoBareOptionalDepReference)
```
Keeps `mix compile --no-optional-deps --warnings-as-errors` green (D-46-14).

### Verify-first ingress + widened result dispatch
**Source:** core `lib/mailglass/webhook/plug.ex:119-161` (proven 3-variant `case`).
**Apply to:** `ingress/plug.ex` `do_call/2`, `ingress/provider.ex` `@callback`, both new
providers' `verify!`. Replay (`{:replay}`) and control-plane (`{:control_plane, _}`) are
**200 no-ops** with no `InboundRecord`; only `{:ok, facts}` persists; forgery RAISES → 401.

### Reuse running core caches (do NOT re-supervise — CLAUDE.md #8)
**Source:** `lib/mailglass/application.ex` supervises both caches; inbound deps
`{:mailglass, path: ".."}` so they boot.
**Apply to:** both new providers. Call `MailgunReplayCache.check_and_put/2`
(`mailgun_replay_cache.ex:9`), `CertCache.fetch_public_key/1` (`cert_cache.ex:35`),
`TrustPolicy.valid_*_url?/1` (`trust_policy.ex:37,72`) directly. `MailglassInbound.Application`
(`application.ex:13-14` — only `Task.Supervisor`) must NOT add these supervisors (D-46-02).

### Config-resolution seam (config-map then app-env)
**Source:** core `ses.ex:351-362` `httpc_client/1`.
**Apply to:** `S3Fetcher` module resolution in `ses.ex` (inbound), defaulting to
`S3Fetcher.Fake` in `:test` and `S3Fetcher.ExAwsS3` in prod (D-46-13).

### Canonical `%InboundMessage{}` normalize + evidence map
**Source:** `ingress/providers/sendgrid.ex:32-61` and `postmark.ex:28-58`.
**Apply to:** both new providers. Do NOT widen the public `%InboundMessage{}` struct
(`inbound_message.ex:60-78`) for provider quirks — provider-specific data goes in the
evidence map (`%{raw_payload, raw_headers, raw_mime, verification_facts, parse_warnings,
attachment_blobs}`).

### Test structure
**Source:** `test/mailglass_inbound/ingress/sendgrid_provider_test.exs` (provider verify +
normalize), `test/mailglass_inbound/mime_error_test.exs` (`__types__/0` contract).
**Apply to:** `mailgun_provider_test.exs`, `ses_provider_test.exs`, `signature_error_test.exs`,
`s3_fetch_error_test.exs`, `s3_fetcher_test.exs`, and `plug_test.exs` extensions
(RESEARCH Wave 0 Gaps, lines 520-527).

---

## No Analog Found

None. Every new/modified file has a strong in-repo analog. The two areas with the
*weakest* analog (still role-matched, flagged for planner attention):

| File | Role | Data Flow | Note |
|------|------|-----------|------|
| `s3_fetcher/fake.ex` | adapter (test default) | file-I/O | No existing *fake fetcher* in inbound; the fake-first DNA (D-13) + the `ses.ex:351` config seam are the patterns to compose. Surface is Claude's discretion (D-46-13). |
| `s3_fetcher.ex` bounded-retry loop | behaviour caller | file-I/O | RESEARCH Pattern 5 (~2-3 attempts, 250ms→1s→2s). No existing retry-loop analog in the codebase; keep it small, raise/return `S3FetchError(:s3_object_not_ready)` on exhaustion, do NOT ack so SNS redelivers (D-46-16). |

---

## Reuse-Only Cross-Package Anchors (CALL, do not modify)

The planner must wire calls to these correctly; none are modified by this phase (except the
optional SES `verify_envelope!/2` extract, listed in MODIFIED above).

| Anchor | What inbound calls | Signature (verified) |
|--------|-------------------|----------------------|
| `lib/mailglass/webhook/providers/mailgun_replay_cache.ex` | `check_and_put/2` | `(binary, %DateTime{}) :: :ok \| {:error, :replay}` (`:9`); also `reset/0`, `table/0` |
| `lib/mailglass/webhook/providers/ses/cert_cache.ex` | `fetch_public_key/1` | `(binary) :: {:ok, term} \| :miss` (`:35`); `put/3`, `reset/0`, `table/0` |
| `lib/mailglass/webhook/providers/ses/trust_policy.ex` | `valid_cert_url?/1`, `valid_subscribe_url?/1` | pure predicates `(binary) :: boolean` (`:37`, `:72`) |
| `lib/mailglass/webhook/providers/ses.ex` | `dispatch_message_type/3` (for control-plane) + new `verify_envelope!/2` seam | control-plane returns `{:ok, :control_plane, :subscription_confirmed \| :unsubscribe_confirmed}` (`:139-181`) |
| `lib/mailglass/webhook/providers/mailgun.ex` | reference ONLY (HMAC math `:29-37`, skew `:131-157`) — reimplement over flat fields, do NOT call `verify!/3` | `verify!/3 :: :ok \| {:ok, :replay}` (`:19`) — JSON-coupled, wrong for inbound |
| `lib/mailglass/application.ex` | nothing (caches boot here) | `maybe_add` + `Code.ensure_loaded?` (`:31-38`) — inbound must NOT re-supervise |

---

## Metadata

**Analog search scope:** `mailglass_inbound/lib/mailglass_inbound/` (ingress, errors,
optional_deps, models, MIME), `lib/mailglass/webhook/` (providers, plug, caches, trust),
`lib/mailglass/optional_deps/`, `lib/mailglass/errors/`, both `mix.exs` + `.credo.exs`,
`mailglass_inbound/priv/repo/migrations/`, `mailglass_inbound/test/`.
**Files scanned:** ~25 (all CONTEXT.md/RESEARCH.md anchors read against the live tree).
**Pattern extraction date:** 2026-05-23
