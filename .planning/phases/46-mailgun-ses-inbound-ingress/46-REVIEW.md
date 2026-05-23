---
phase: 46-mailgun-ses-inbound-ingress
reviewed: 2026-05-23T00:00:00Z
depth: standard
files_reviewed: 26
files_reviewed_list:
  - lib/mailglass/webhook/providers/ses.ex
  - mailglass_inbound/CHANGELOG.md
  - mailglass_inbound/docs/api_stability.md
  - mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex
  - mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex
  - mailglass_inbound/lib/mailglass_inbound/ingress/provider.ex
  - mailglass_inbound/lib/mailglass_inbound/ingress/providers/mailgun.ex
  - mailglass_inbound/lib/mailglass_inbound/ingress/providers/sendgrid.ex
  - mailglass_inbound/lib/mailglass_inbound/ingress/providers/ses.ex
  - mailglass_inbound/lib/mailglass_inbound/optional_deps.ex
  - mailglass_inbound/lib/mailglass_inbound/s3_fetch_error.ex
  - mailglass_inbound/lib/mailglass_inbound/s3_fetcher.ex
  - mailglass_inbound/lib/mailglass_inbound/s3_fetcher/ex_aws_s3.ex
  - mailglass_inbound/lib/mailglass_inbound/s3_fetcher/fake.ex
  - mailglass_inbound/lib/mailglass_inbound/s3_fetcher/retry.ex
  - mailglass_inbound/lib/mailglass_inbound/signature_error.ex
  - mailglass_inbound/mix.exs
  - mailglass_inbound/priv/repo/migrations/20260523120000_add_mailgun_fingerprint_index.exs
  - mailglass_inbound/test/mailglass_inbound/ingress/mailgun_provider_test.exs
  - mailglass_inbound/test/mailglass_inbound/ingress/persist_test.exs
  - mailglass_inbound/test/mailglass_inbound/ingress/plug_test.exs
  - mailglass_inbound/test/mailglass_inbound/ingress/ses_provider_test.exs
  - mailglass_inbound/test/mailglass_inbound/s3_fetch_error_test.exs
  - mailglass_inbound/test/mailglass_inbound/s3_fetcher_test.exs
  - mailglass_inbound/test/mailglass_inbound/signature_error_test.exs
  - test/mailglass/webhook/providers/ses_test.exs
findings:
  critical: 2
  warning: 6
  info: 5
  total: 13
status: issues_found
---

# Phase 46: Code Review Report

**Reviewed:** 2026-05-23
**Depth:** standard
**Files Reviewed:** 26
**Status:** issues_found

## Summary

Reviewed the Mailgun + SES inbound ingress slice: two new provider modules, the
widened plug dispatch contract, the SES S3 fetcher seam (fake + ex_aws gateway +
bounded retry), two new package-local error structs, the Mailgun fingerprint
migration, and the verify-envelope reuse seam in core SES.

The crypto-reuse design is sound: SNS X.509 verification is genuinely shared (not
re-implemented), the SSRF/trust-policy guards are reused for both `SigningCertURL`
and `SubscribeURL`, Mailgun HMAC uses `Plug.Crypto.secure_compare` with a
length-equality pre-guard, error structs carry closed `:type` sets and exclude
`:cause`/`:provider` from JSON, and the telemetry metadata stays PII-free. The
PII-safe 500 egress on persist failure is well-handled and tested.

Two BLOCKERs concern dedupe correctness under concurrency — the exact scenario
idempotency exists to handle (SNS at-least-once redelivery, provider retry
storms). The Mailgun MD5 fingerprint unique index has no matching
`unique_constraint/3` on the evidence changeset, so a concurrent duplicate that
slips past the check-then-act window raises an unhandled `Postgrex.Error` instead
of collapsing cleanly; and an `S3FetchError` raised from `verify!` is not in the
plug's rescue allowlist, so it escapes the structured-response path. Several
WARNINGs concern the verify→normalize handoff fragility and an unguarded
`Jason.decode!` in the fallback.

## Critical Issues

### CR-01: Mailgun fingerprint dedupe has no `unique_constraint` — concurrent duplicate raises unhandled `Postgrex.Error`

**File:** `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex:193-214`
(insert path) and `mailglass_inbound/lib/mailglass_inbound/inbound_records/inbound_evidence.ex:50-56`
(changeset)

**Issue:** The Mailgun "no Message-Id" dedupe relies on the partial unique index
`mailglass_inbound_records_mailgun_fingerprint_idx` on
`mailglass_inbound_evidence(tenant_id, provider, raw_mime_fingerprint)`
(migration `20260523120000`). Dedup detection is a check-then-act
(`load_duplicate/5` → `insert_record` → `insert_evidence`) wrapped in
`repo.transact`. Under concurrency (two SNS/Mailgun redeliveries of the same
body arriving simultaneously — the precise case the index defends), both
transactions can pass `load_duplicate` (each sees `nil`), both insert the
canonical record (no unique key on it for the no-Message-Id case, since
`provider_message_id` is nil), and both attempt the evidence insert. The second
evidence insert violates the fingerprint unique index — but
`InboundEvidence.changeset/1` declares **no** `unique_constraint/3` for that
index name. Ecto therefore cannot translate the DB violation into
`{:error, changeset}`; `repo.insert/1` raises `Ecto.ConstraintError` /
`Postgrex.Error` instead. That exception is not an `%Ecto.Changeset{}`, so the
plug's `persist_and_respond` `{:error, reason}` branch never sees it — it escapes
the transaction as a 500-class crash, and the duplicate is NOT collapsed to a
clean `:duplicate`. The `insert_record/4` path does handle the
`provider_message_id` constraint via `duplicate_constraint?/1` + reload, but no
equivalent exists for the evidence-level fingerprint index. The Postgres-backed
test (`persist_test.exs:113-123`) only exercises the **sequential** path, where
`load_duplicate` catches the second call — so the race is untested.

**Fix:** Add the fingerprint constraint to the evidence changeset and handle it
in `insert_evidence` the same way `insert_record` handles `duplicate_constraint?`
(reload the existing record on violation):

```elixir
# inbound_evidence.ex
def changeset(attrs) when is_map(attrs) do
  %__MODULE__{}
  |> cast(attrs, @cast)
  |> validate_required(@required)
  |> foreign_key_constraint(:inbound_record_id)
  |> unique_constraint([:tenant_id, :provider, :raw_mime_fingerprint],
       name: :mailglass_inbound_records_mailgun_fingerprint_idx)
  |> unique_constraint([:tenant_id, :provider, :raw_mime_fingerprint],
       name: :mailglass_inbound_records_sendgrid_fingerprint_idx)
end
```

Then, in `persist.ex`, on an evidence-fingerprint violation inside the
`with`, reload via `load_duplicate/5` and return `{:ok, %{status: :duplicate,
...}}` (rolling back the just-inserted record). Add a concurrency test that drives
two simultaneous `persist/2` calls for the same fingerprint and asserts exactly
one `InboundRecord` plus a clean `:duplicate`, not a raised error.

### CR-02: `S3FetchError` raised from `verify!` escapes the plug's rescue allowlist — uncontrolled 500 / no telemetry stop-meta

**File:** `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex:98-121`
and `mailglass_inbound/lib/mailglass_inbound/ingress/providers/ses.ex:50-69, 197-210`

**Issue:** For SES `Notification`, `verify!/2` performs the S3 fetch inside
verification (`extract_raw_mime!` → `fetch_s3_body!` →
`S3Fetcher.Retry.fetch_with_retry`). On retry exhaustion or a non-retryable S3
error this raises `MailglassInbound.S3FetchError` (confirmed by
`ses_provider_test.exs:122-132`). The plug's `do_call/2` `rescue` only catches
`[SignatureError, InboundSignatureError]`, `TenancyError`, and `ConfigError`.
`S3FetchError` is none of these, so it propagates out of `do_call/2` and out of
`MailglassInbound.Telemetry.ingress_span/2`. Consequences: (1) the carefully
constructed PII-free telemetry stop-meta and status classification are bypassed —
the span sees an exception, not a tagged outcome; (2) the response is whatever the
host router's error handler produces (typically a generic 500), which is *only*
correct by accident — the design comment at plug.ex:154-167 argues a 500 is the
right retry signal, but that posture is reached deliberately for changeset
failures and entirely by luck for `S3FetchError`. The `:s3_object_not_ready`
(transient, "SNS should redeliver") vs `:s3_fetch_failed` (permanent, retry
won't help) distinction is lost — both become an identical opaque 500, so a
permanently-failing object triggers infinite SNS redelivery.

**Fix:** Add an explicit rescue clause for `S3FetchError` that maps it to a
controlled response with PII-free telemetry stop-meta. Map `:s3_object_not_ready`
to a 500 (retry desired) and `:s3_fetch_failed` to a non-retryable status (or a
200 ack-with-degraded-record), and surface `e.type` as the classified
`error_kind`:

```elixir
e in MailglassInbound.S3FetchError ->
  status = if e.type == :s3_object_not_ready, do: 500, else: 422
  resp = send_json(conn, status, %{status: "s3_fetch_error", reason: Atom.to_string(e.type)})
  {resp, %{provider: provider, status: :s3_fetch_error, error_kind: e.type}}
```

Add a plug-level test (not just the provider-level `assert_raise`) asserting the
status code and PII-free body for both `S3FetchError` types.

## Warnings

### WR-01: SES verify→normalize handoff via process dictionary is fragile and the fallback can raise

**File:** `mailglass_inbound/lib/mailglass_inbound/ingress/providers/ses.ex:259-279`

**Issue:** `verify!` stashes `{payload, raw_mime}` in the process dictionary and
`normalize/1` reads it back. This works because the plug runs both in the same
per-request process. But (1) if any step between `verify!` and `normalize/1`
raises (e.g. `resolve_tenant!` raises `TenancyError`), the stashed entry is never
`Process.delete`d — harmless under per-request processes (Cowboy/Bandit spawn
fresh), but a latent footgun if the plug is ever driven from a long-lived/pooled
process; and (2) the defensive fallback `fetch_verified/1` calls
`Jason.decode!(raw_body)`, which **raises** `Jason.DecodeError` on malformed JSON
— inconsistent with the never-raise posture the module documents for body parsing,
and that error is not caught by the plug rescue (same class of leak as CR-02).
The fallback also performs a **second** S3 fetch despite the module docstring
("no double fetch") and uses empty config `%{}`, silently ignoring the configured
`s3_fetcher`/retry opts — so the legacy `normalize/2` shim (line 127) would fetch
from the real `ExAwsS3` in production regardless of test config.

**Fix:** Wrap the fallback decode in a defensive case
(`case Jason.decode(raw_body) do {:ok, p} -> ...; _ -> raise SignatureError... end`)
or remove the fallback entirely and make `normalize/1` require a prior stash
(raising a clear internal error otherwise). Thread the real config into the
fallback rather than `%{}`. Add `Process.delete(@pd_key)` cleanup in a plug-level
`after`/rescue if pooled execution is ever a possibility.

### WR-02: SES messages with no `mail.messageId` and no Message-Id header never dedupe

**File:** `mailglass_inbound/lib/mailglass_inbound/ingress/persist.ex:135-139`
and `mailglass_inbound/lib/mailglass_inbound/ingress/providers/ses.ex:90-92, 233-235`

**Issue:** SES sets `provider_message_id` to `ses_message_id(payload)` (the inner
`mail.messageId`). If that is absent (e.g. an inline-content notification whose
inner JSON omits `mail.messageId`, or a degraded payload where `decode_inner_message`
returns `%{}`), `provider_message_id` is `nil`. `load_duplicate/5` then matches
the generic `provider_message_id: nil` clause (line 135) and returns `nil` — always
treated as new. Unlike Mailgun, SES has **no** MD5(raw_mime) fingerprint fallback,
so an SNS redelivery of such a message inserts a duplicate `InboundRecord` and
re-dispatches the mailbox. Given the module's own retry/redelivery design
("the dedupe layer is the real safety net"), this is a correctness gap for the
exact path that is supposed to be idempotent.

**Fix:** Add a `load_duplicate` clause for `"ses"` with `provider_message_id: nil`
that falls back to the MD5(raw_mime) fingerprint (mirroring the Mailgun clause at
lines 113-133) and add a `provider = 'ses'` partial unique index on the evidence
fingerprint. If SES is expected to always carry `mail.messageId`, document that
invariant and add a `parse_warning` when it is missing.

### WR-03: `verify_request!` runs the S3 network fetch before tenant resolution

**File:** `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex:81-97, 128-129`
and `ses.ex:50-58`

**Issue:** The plug verifies (which for SES includes the bounded S3 GetObject with
up to ~3.25s of backoff sleeps) **before** `resolve_tenant!`. Signature is checked
first inside `verify_envelope!`, so only authentic SNS messages reach the fetch —
but an authentic message destined for an unresolvable tenant still pays the full
S3 fetch + retry cost before being rejected with 422. More importantly, the
`Process.sleep` backoff in `S3Fetcher.Retry` blocks the request process
synchronously inside the verify phase, holding the acceptor/connection for
multiple seconds on the not-ready path. This is correctness-adjacent (it widens
the window for connection exhaustion under a redelivery storm) rather than a pure
perf issue.

**Fix:** Consider resolving the tenant before the S3 fetch (move tenant resolution
ahead of the body fetch for SES), or document that SES verify intentionally fetches
pre-tenant. At minimum, ensure the default backoff (`[250, 1_000, 2_000]`) is
acceptable to hold a request process for, and surface it as configurable per
deployment (it already is via `:s3_retry_opts`, but the plug never threads
`:s3_retry_opts` into the SES config map at `resolve_config!/3` lines 333-344 —
only `:s3_fetcher` and `:cert_cache_ttl_seconds` are passed, so adopters cannot
actually tune the retry from app config).

### WR-04: SES config drops `:s3_retry_opts` — documented tuning knob is unreachable in production

**File:** `mailglass_inbound/lib/mailglass_inbound/ingress/plug.ex:333-344`
and `ses.ex:197-202`

**Issue:** `fetch_s3_body!` reads `Map.get(config, :s3_retry_opts, [])`, but
`resolve_config!(:ses, ...)` only builds `%{s3_fetcher:, cert_cache_ttl_seconds:}`
— it never copies `:s3_retry_opts` from app env / opts into the config map. So in
the real plug path the retry is **always** the hardcoded default (3 attempts,
`[250, 1_000, 2_000]` backoff); the `:s3_retry_opts` seam only works when a test
calls the provider directly with a hand-built config. This is dead configuration
surface: adopters who set retry opts get silently ignored behavior.

**Fix:** Add `s3_retry_opts: config[:s3_retry_opts] || []` to the map returned by
`resolve_config!(:ses, _conn, opts)`.

### WR-05: SES inline-content base64 heuristic can mis-decode legitimately base64-looking MIME

**File:** `mailglass_inbound/lib/mailglass_inbound/ingress/providers/ses.ex:214-224`

**Issue:** `decode_inline_content/1` tries `Base.decode64(content)` first and, if
it succeeds and `looks_like_mime?(decoded)`, returns the decoded bytes; otherwise
returns the raw `content`. Two edge cases produce wrong bodies: (1) raw
(non-base64-encoded) MIME that happens to be valid base64 AND whose decoded form
still contains `:` in the first 64 printable bytes would be silently mangled —
unlikely with CRLF-laden MIME but not impossible for terse single-line content;
(2) `looks_like_mime?` only checks for a `:` in the printable prefix, which is a
weak signal (any `Key: value`-ish text passes). The result is a corrupted
`raw_mime` persisted as evidence and fed to `MIME.parse/1`. `MIME.parse/1` never
raises, so this degrades silently rather than failing loudly.

**Fix:** Prefer an explicit signal from the SES payload over a content heuristic.
SES inline notifications do not base64-encode by default; if base64 is in play it
is deterministic per receipt-rule config. If a heuristic must remain, tighten
`looks_like_mime?` to require a header line matching `^[A-Za-z-]+:\s` before the
first blank line, and record a `parse_warning` whenever the base64 branch is
taken so the ambiguity is auditable.

### WR-06: `MailglassInbound.OptionalDeps.ExAwsS3` gateway not gated by `available?/0` — relies solely on `:undef` rescue

**File:** `mailglass_inbound/lib/mailglass_inbound/optional_deps.ex:142-148`

**Issue:** The module documents `available?/0` as "the normal degraded path" and
the `try/rescue`/`catch` as "the defensive backstop," but `get_object/2` itself
never calls `available?/0` — it unconditionally calls `ExAws.S3.get_object/2 |>
ExAws.request/1` and depends entirely on the `:undef` rescue when the dep is
absent. That works (the rescue catches `UndefinedFunctionError`), but it means
the "normal degraded path" is never actually exercised at this layer; every
dep-absent call goes through the exception machinery. More subtly, the
`rescue e -> {:error, {:error, e}}` clause tags an absent-dep `:undef` identically
to a genuine `ExAws` exception (bad creds, network), so callers cannot distinguish
"AWS not installed" (config error) from "AWS call failed" (transient). The retry
layer treats both as unknown→transient (`S3Fetcher.Retry.retryable?/1` line 99),
so a dep-absent deployment would burn the full retry budget and 3 backoff sleeps
on every SES message before raising `:s3_fetch_failed`.

**Fix:** Short-circuit on `available?/0` and tag the absent-dep case distinctly so
the retry layer can classify it as non-retryable:

```elixir
def get_object(bucket, key) when is_binary(bucket) and is_binary(key) do
  if available?() do
    ExAws.S3.get_object(bucket, key) |> ExAws.request()
  else
    {:error, {:s3_fetch_failed, :ex_aws_unavailable}}
  end
rescue
  e -> {:error, {:error, e}}
catch
  :exit, reason -> {:error, {:exit, reason}}
end
```

## Info

### IN-01: `MailglassInbound.InboundMessage` type/docs not widened for new providers

**File:** `mailglass_inbound/lib/mailglass_inbound/inbound_message.ex:26`

**Issue:** `@type provider :: :postmark | :sendgrid | String.t()` and the
module/`api_stability.md` docs still enumerate only Postmark and SendGrid, but
this phase ships `:mailgun` and `:ses` providers that populate `provider:` on the
struct. `api_stability.md:84` even lists "providers beyond Postmark and SendGrid"
under `deferred`, which now contradicts the shipped Mailgun/SES providers.

**Fix:** Add `:mailgun | :ses` to the `@type provider` union and reconcile the
`deferred` section of `docs/api_stability.md` (move Mailgun/SES out of deferred,
or scope the deferred line to "providers beyond Postmark, SendGrid, Mailgun, and
SES").

### IN-02: `received_at` uses `DateTime.utc_now()` directly instead of the injectable `Clock`

**File:** `mailglass_inbound/lib/mailglass_inbound/ingress/providers/mailgun.ex:115, 166`,
`ses.ex:103`, and `persist.ex:169`

**Issue:** The verify paths use `Mailglass.Clock.utc_now()` (injectable for tests),
but `received_at` in the normalizers and `persist.ex` uses `DateTime.utc_now()`
directly. Minor inconsistency that makes the received timestamp non-deterministic
in tests and diverges from the project's Clock convention used elsewhere.

**Fix:** Use `Mailglass.Clock.utc_now()` for `received_at` for consistency and
testability.

### IN-03: `mix.exs` `@version` is `0.1.0` but new surfaces are annotated `@since "0.2.0"`

**File:** `mailglass_inbound/mix.exs:4` vs `signature_error.ex:65`,
`s3_fetch_error.ex:44`, `optional_deps.ex:127`, CHANGELOG `[Unreleased]`

**Issue:** All new error structs and the gateway carry `@since "0.2.0"` and the
CHANGELOG documents them under `[Unreleased]` as a "minor bump," but `mix.exs`
still declares `@version "0.1.0"`. The version has not yet been bumped to match the
`@since` annotations. If released as-is the published version would be 0.1.0 while
docs claim 0.2.0.

**Fix:** Confirm the release ceremony bumps `@version` to `0.2.0` before publish
(or adjust `@since` to match the actual release version). Likely intentional
pre-release state, flagged for the release gate.

### IN-04: `docs` extras omit a Mailgun/SES ingress guide

**File:** `mailglass_inbound/mix.exs:122-132`

**Issue:** `docs` extras list `postmark_ingress.md` and `sendgrid_ingress.md` but
no Mailgun or SES guide, despite shipping both providers (and the SES path having
non-trivial adopter setup: `ex_aws` deps, S3 receipt rule, IAM, SSE-vs-KMS caveat
documented at `ses.ex:33-38`). Adopters get a provider with no mounting guide.

**Fix:** Add `docs/mailgun_ingress.md` and `docs/ses_ingress.md` (the latter
covering the optional-dep install + receipt-rule + S3 setup) before release, or
confirm they land in the referenced Phase 50 setup guide.

### IN-05: Duplicated RFC-5322 helper blocks across three providers

**File:** `mailgun.ex:409-477`, `sendgrid.ex:307-374`, `ses.ex:350-414`

**Issue:** `normalize_address_header/1`, `parse_address/1`, `parse_datetime/1`,
`month_number/1`, `utc_offset_seconds/1`, and `select_safe_headers/1` are
copy-pasted near-verbatim across all three providers. The code comments
acknowledge this is intentional ("duplicating them here keeps the provider
self-contained"), but it triples the surface for a parsing-bug fix (e.g. the
`utc_offset_seconds` clause has no fallback for a malformed offset and would
`MatchError` on `Integer.parse` returning `:error` — though `parse_datetime`'s
regex guards the shape first, so it is currently unreachable). Maintainability
risk if one copy is fixed and the others drift.

**Fix:** Extract the pure RFC-5322 helpers into a shared internal module
(`MailglassInbound.Ingress.AddressParsing` or similar) once a third consumer
exists, which is now the case. Not blocking, but the duplication threshold has
been crossed.

---

_Reviewed: 2026-05-23_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
