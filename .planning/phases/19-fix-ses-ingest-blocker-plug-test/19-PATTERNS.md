# Phase 19: Fix SES Ingest BLOCKER + Plug-level Integration Test — Pattern Map

**Mapped:** 2026-04-30
**Files analyzed:** 2 (1 modify, 1 create)
**Analogs found:** 2 / 2 (both exact-match)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/mailglass/webhook/ingest.ex` (MODIFY) | service / ingest seam | request-response (signed webhook → DB INSERT) | self — surgically extends existing `:mailgun` and `:resend` clauses in the same file | exact (in-file mirror) |
| `test/mailglass/webhook/plug_ses_test.exs` (CREATE) | test (plug-level integration) | request-response (Plug.call/2 → HTTP status + DB row) | `test/mailglass/webhook/plug_mailgun_test.exs` | exact (Mailgun = canonical plug-test convention) |

**Why both are exact-match:** Phase 16 already shipped every dependency (CertCache, generate_sns_keypair/0, sign_sns_canonical_string/3, mailglass_webhook_conn(:ses, _), 16 SES fixtures). The work is composition over creation — every excerpt below is copied verbatim from a passing-today file.

---

## Pattern Assignments

### `lib/mailglass/webhook/ingest.ex` (service / ingest seam, request-response)

**Analog:** Same file — the `:mailgun` clause (line 366-368) and the `:resend` clause (line 373-375) are the byte-for-byte template. The new `:ses` clause inserts between them; the guard at line 122 gains one atom.

#### Edit 1: Provider guard (line 122) — **VERBATIM CURRENT TEXT**

Source: `lib/mailglass/webhook/ingest.ex:121-123`

```elixir
  def ingest_multi(provider, raw_body, events)
      when provider in [:postmark, :sendgrid, :mailgun, :resend] and is_binary(raw_body) and
             is_list(events) do
```

**What changes vs. the analog:** Insert `:ses` between `:mailgun` and `:resend` to mirror `Mailglass.Webhook.Plug.@valid_providers` ordering at `plug.ex:84` (`[:postmark, :sendgrid, :mailgun, :ses, :resend]`). One-atom diff:

```elixir
  def ingest_multi(provider, raw_body, events)
      when provider in [:postmark, :sendgrid, :mailgun, :ses, :resend] and is_binary(raw_body) and
             is_list(events) do
```

#### Edit 2: `derive_webhook_provider_event_id/3` clause — **VERBATIM ANALOG (lines 358-377)**

Source: `lib/mailglass/webhook/ingest.ex:358-377`

```elixir
  # Postmark sends one event per webhook; provider_event_id from
  # Event.metadata["provider_event_id"] is canonical.
  defp derive_webhook_provider_event_id(:postmark, _raw_body, [first | _]) do
    extract_event_provider_id(first) || ""
  end

  # Mailgun replay and ingest both key off the webhook token surfaced in
  # Event.metadata["provider_event_id"].
  defp derive_webhook_provider_event_id(:mailgun, _raw_body, [first | _]) do
    extract_event_provider_id(first) || ""
  end

  # Resend (Svix) sends one event per webhook with a stable `id` like
  # "evt_..."; Phase 14 normalize/2 plumbs that into
  # Event.metadata["provider_event_id"], same convention as Postmark.
  defp derive_webhook_provider_event_id(:resend, _raw_body, [first | _]) do
    extract_event_provider_id(first) || ""
  end

  defp derive_webhook_provider_event_id(_provider, _raw_body, []), do: ""
```

**What changes vs. the analog:** Insert a new clause between `:mailgun` (line 366-368) and `:resend` (line 373-375). The body is byte-identical to the surrounding clauses; only the atom and comment differ.

```elixir
  # SES (SNS) populates `provider_event_id` as "#{sns_message_id}:#{email}" via
  # `Mailglass.Webhook.Providers.SES.build_provider_event_id/3`. Stable across SNS
  # retries because both fields come from the signed payload. Same dispatch as
  # Mailgun/Resend.
  defp derive_webhook_provider_event_id(:ses, _raw_body, [first | _]) do
    extract_event_provider_id(first) || ""
  end
```

#### Helper already in place (NO CHANGE)

Source: `lib/mailglass/webhook/ingest.ex:382-386` — the `extract_event_provider_id/1` helper reads `Event.metadata["provider_event_id"]` (string-keyed) with an atom-key fallback. SES `build_event/8` populates this metadata key; no helper changes needed.

```elixir
  defp extract_event_provider_id(%Event{metadata: meta}) when is_map(meta) do
    meta["provider_event_id"] || Map.get(meta, :provider_event_id)
  end

  defp extract_event_provider_id(_), do: nil
```

---

### `test/mailglass/webhook/plug_ses_test.exs` (test, plug-level integration)

**Analog:** `test/mailglass/webhook/plug_mailgun_test.exs` — the canonical plug-level webhook test convention.

#### Imports + aliases pattern (analog lines 1-9) — VERBATIM

Source: `test/mailglass/webhook/plug_mailgun_test.exs:1-9`

```elixir
defmodule Mailglass.Webhook.PlugMailgunTest do
  use Mailglass.WebhookCase, async: false

  import ExUnit.CaptureLog

  alias Mailglass.TestRepo
  alias Mailglass.Webhook.Plug, as: WebhookPlug
  alias Mailglass.Webhook.Providers.MailgunReplayCache
  alias Mailglass.Webhook.WebhookEvent
```

**What changes vs. the analog:** Module name → `Mailglass.Webhook.PlugSESTest`; replace `MailgunReplayCache` alias with `Mailglass.Webhook.Providers.SES.CertCache`. Everything else is verbatim.

#### Setup pattern — composes 2 analogs

**Analog 1 — truncate + cache reset (Mailgun setup, lines 11-16):**

```elixir
  setup do
    MailgunReplayCache.reset()
    TestRepo.query!("TRUNCATE TABLE mailglass_webhook_events CASCADE", [])
    TestRepo.query!("TRUNCATE TABLE mailglass_events CASCADE", [])
    :ok
  end
```

**Analog 2 — RSA keypair + cert pre-stuff (ses_test.exs, lines 71-73):**

Source: `test/mailglass/webhook/providers/ses_test.exs:71-73` (inside `verify!/3` test, but the same 3-line idiom is the SES setup primitive)

```elixir
      {public_key, private_key} = generate_sns_keypair()
      future = DateTime.add(Mailglass.Clock.utc_now(), 86_400, :second)
      CertCache.put(@cert_url, public_key, future)
```

**What changes vs. the analog:** Replace `MailgunReplayCache.reset()` with `CertCache.reset()`, lift the keypair-mint + cache-stuff out of the per-test body and into setup so every test inherits a fresh signing identity, and return `{:ok, private_key: private_key}` so tests destructure it from context.

```elixir
  @cert_url "https://sns.us-east-1.amazonaws.com/SimpleNotificationService-test.pem"

  setup do
    CertCache.reset()
    TestRepo.query!("TRUNCATE TABLE mailglass_webhook_events CASCADE", [])
    TestRepo.query!("TRUNCATE TABLE mailglass_events CASCADE", [])

    {public_key, private_key} = generate_sns_keypair()
    future = DateTime.add(Mailglass.Clock.utc_now(), 86_400, :second)
    CertCache.put(@cert_url, public_key, future)

    {:ok, private_key: private_key}
  end
```

#### Canonical-string + sign-fixture helpers — VERBATIM from `ses_test.exs:42-65`

Source: `test/mailglass/webhook/providers/ses_test.exs:42-65`

```elixir
  defp build_canonical_string(payload, "Notification") do
    keys = ~w(Message MessageId Subject Timestamp TopicArn Type)

    keys
    |> Enum.filter(&Map.has_key?(payload, &1))
    |> Enum.map_join(fn k -> "#{k}\n#{payload[k]}\n" end)
  end

  defp build_canonical_string(payload, type)
       when type in ["SubscriptionConfirmation", "UnsubscribeConfirmation"] do
    keys = ~w(Message MessageId SubscribeURL Timestamp Token TopicArn Type)

    keys
    |> Enum.filter(&Map.has_key?(payload, &1))
    |> Enum.map_join(fn k -> "#{k}\n#{payload[k]}\n" end)
  end

  defp sign_fixture(raw_fixture_json, private_key) do
    payload = Jason.decode!(raw_fixture_json)
    msg_type = payload["Type"]
    canonical = build_canonical_string(payload, msg_type)
    sig = sign_sns_canonical_string(canonical, private_key)
    payload |> Map.put("Signature", sig) |> Jason.encode!()
  end
```

**What changes vs. the analog:** Phase 19 success criterion is Notification-only — the `SubscriptionConfirmation`/`UnsubscribeConfirmation` clause may be omitted as dead code unless a control-plane test is added (research recommends skipping). Rename `sign_fixture/2` → `sign_ses_fixture/2` for clarity at call site (optional, non-load-bearing).

#### Core test pattern — happy path (analog lines 30-41)

Source: `test/mailglass/webhook/plug_mailgun_test.exs:30-41`

```elixir
  describe "call/2 Mailgun replay response" do
    test "returns 200 on a valid signed Mailgun request" do
      raw_body = Mailglass.WebhookCase.stub_mailgun_fixture("accepted")

      conn =
        Mailglass.WebhookCase.mailglass_webhook_conn(:mailgun, raw_body, token: "mailgun-valid-200")

      result = WebhookPlug.call(conn, WebhookPlug.init(provider: :mailgun))

      assert result.status == 200
      assert TestRepo.aggregate(WebhookEvent, :count) == 1
    end
```

**What changes vs. the analog:** SES signs at runtime by injecting `Signature` into a payload-only fixture (Mailgun signs by re-emitting a `signature` JSON object). Swap the `WebhookCase.stub_mailgun_fixture/1 → mailglass_webhook_conn(:mailgun, _, token: _)` chain for `stub_ses_fixture/1 → sign_ses_fixture/2 → mailglass_webhook_conn(:ses, signed_raw)`. Destructure `private_key` from setup context.

```elixir
  describe "call/2 SES Notification end-to-end" do
    test "returns 200 and persists WebhookEvent on a valid signed Notification",
         %{private_key: private_key} do
      raw = sign_ses_fixture(stub_ses_fixture("notification_delivery"), private_key)
      conn = mailglass_webhook_conn(:ses, raw)

      result = WebhookPlug.call(conn, WebhookPlug.init(provider: :ses))

      assert result.status == 200
      assert TestRepo.aggregate(WebhookEvent, :count) == 1
    end
  end
```

#### Replay test pattern (analog lines 43-59)

Source: `test/mailglass/webhook/plug_mailgun_test.exs:43-59` — second call to `WebhookPlug.call/2` with the same conn must return 200 and leave row count at 1 (idempotent dedup via `(provider, provider_event_id)` UNIQUE).

```elixir
    test "returns 200 on a replayed Mailgun request" do
      raw_body = Mailglass.WebhookCase.stub_mailgun_fixture("accepted")

      conn =
        Mailglass.WebhookCase.mailglass_webhook_conn(
          :mailgun,
          raw_body,
          token: "mailgun-replay-200"
        )

      first = WebhookPlug.call(conn, WebhookPlug.init(provider: :mailgun))
      second = WebhookPlug.call(conn, WebhookPlug.init(provider: :mailgun))

      assert first.status == 200
      assert second.status == 200
      assert TestRepo.aggregate(WebhookEvent, :count) == 1
    end
```

**What changes vs. the analog:** Same shape; substitute SES fixture loading and SNS signing. SES replay key is `"#{sns_message_id}:#{email}"` baked into the signed payload — replaying the same signed bytes hits the UNIQUE collision identically.

#### Bad-signature test pattern (analog lines 62-89)

Source: `test/mailglass/webhook/plug_mailgun_test.exs:62-89`

```elixir
  describe "call/2 Mailgun bad signature response" do
    test "returns 401 when the Mailgun signature is invalid" do
      raw_body = Mailglass.WebhookCase.stub_mailgun_fixture("accepted")

      conn =
        Mailglass.WebhookCase.mailglass_webhook_conn(:mailgun, raw_body,
          token: "mailgun-bad-signature"
        )

      tampered_body =
        String.replace(conn.private[:raw_body], "\"signature\":\"", "\"signature\":\"0",
          global: false
        )

      tampered_conn =
        conn
        |> Plug.Conn.put_private(:raw_body, tampered_body)

      {result, log} =
        with_log(fn ->
          WebhookPlug.call(tampered_conn, WebhookPlug.init(provider: :mailgun))
        end)

      assert result.status == 401
      assert log =~ "provider=mailgun"
      refute log =~ raw_body
    end
  end
```

**What changes vs. the analog:** Tamper the `Message` field of the signed payload (string-replace `"\"Message\":"` → `"\"Message\":\"TAMPERED\", \"X\":"` — same idiom as `ses_test.exs:87`). Build the conn from the tampered raw bytes directly (no `put_private` round-trip needed; `mailglass_webhook_conn(:ses, tampered)` already mirrors raw_body into `conn.private[:raw_body]` per `webhook_case.ex:227`). Assert `log =~ "provider=ses"` and `refute log =~ raw` (PII guard inherited from the analog).

```elixir
  describe "call/2 SES bad signature response" do
    test "returns 401 when the Message field is tampered",
         %{private_key: private_key} do
      raw = sign_ses_fixture(stub_ses_fixture("notification_delivery"), private_key)
      tampered =
        String.replace(raw, "\"Message\":", "\"Message\":\"TAMPERED\", \"X\":", global: false)
      conn = mailglass_webhook_conn(:ses, tampered)

      {result, log} =
        with_log(fn ->
          WebhookPlug.call(conn, WebhookPlug.init(provider: :ses))
        end)

      assert result.status == 401
      assert log =~ "provider=ses"
      refute log =~ raw
    end
  end
```

#### Explicit init/1 test pattern (analog lines 129-133) — VERBATIM template

Source: `test/mailglass/webhook/plug_mailgun_test.exs:129-133`

```elixir
  describe "call/2 Mailgun explicit route execution" do
    test "init/1 accepts :mailgun as an explicit provider" do
      assert Keyword.get(WebhookPlug.init(provider: :mailgun), :provider) == :mailgun
    end
  end
```

**What changes vs. the analog:** s/mailgun/ses/g.

#### Conn-construction (already shipped) — NO CHANGE

Source: `test/support/webhook_case.ex:222-228`

```elixir
  def mailglass_webhook_conn(:ses, raw_body, _opts) when is_binary(raw_body) do
    :post
    |> Plug.Test.conn("/webhooks/ses", raw_body)
    |> Plug.Conn.put_req_header("content-type", "text/plain")
    |> Plug.Conn.put_req_header("x-amz-sns-message-type", "Notification")
    |> Plug.Conn.put_private(:raw_body, raw_body)
  end
```

The new test file calls this helper unmodified — it's already wired for `text/plain` and the SNS message-type header. **Note:** Plug-level test for `SubscriptionConfirmation` flow would require this helper to accept an opts-driven `x-amz-sns-message-type` (currently hardcoded `"Notification"`). Phase 19 success criterion is Notification-only, so no helper change is needed; flag if scope expands.

#### Fixture loader (already shipped) — NO CHANGE

Source: `test/support/webhook_case.ex:336-338` re-exports `Mailglass.WebhookFixtures.load_ses_fixture/1`:

```elixir
  @doc "Loads an SES fixture and returns raw bytes ready for `mailglass_webhook_conn/2`."
  @spec stub_ses_fixture(String.t()) :: binary()
  def stub_ses_fixture(name), do: Mailglass.WebhookFixtures.load_ses_fixture(name)
```

Use `stub_ses_fixture("notification_delivery")` (verified to exist at `test/support/fixtures/webhooks/ses/notification_delivery.json`, 10 lines, payload-only with placeholder Signature ready for runtime injection).

#### RSA primitives (already shipped) — NO CHANGE

Source: `test/support/webhook_fixtures.ex:217-228` (`generate_sns_keypair/0`) and `:248-259` (`sign_sns_canonical_string/3`). Both helpers are imported via `use Mailglass.WebhookCase` (the case module exposes them at the test level). Call shape:

```elixir
{public_key, private_key} = generate_sns_keypair()
sig = sign_sns_canonical_string(canonical_string, private_key)
```

#### CertCache API (already shipped) — NO CHANGE

Source: `lib/mailglass/webhook/providers/ses/cert_cache.ex:60` and `:67`:

```elixir
def put(url, public_key, %DateTime{} = expires_at) when is_binary(url) do
def reset do
```

Call shape (same idiom as `ses_test.exs:71-73`):

```elixir
CertCache.reset()
CertCache.put(@cert_url, public_key, future)
```

---

## Shared Patterns

### Pattern A: `use Mailglass.WebhookCase, async: false`
**Source:** `test/mailglass/webhook/plug_mailgun_test.exs:2`
**Apply to:** New `plug_ses_test.exs` (the only new file in scope).
**Why `async: false`:** WebhookCase mutates `Application.put_env(:mailglass, :ses, ...)` at `webhook_case.ex:117-120` and concurrent async tests would clobber each other's env state. (Pitfall 3 in RESEARCH.md.)

```elixir
use Mailglass.WebhookCase, async: false
```

### Pattern B: Truncate ledger tables in setup
**Source:** `test/mailglass/webhook/plug_mailgun_test.exs:13-14`
**Apply to:** New `plug_ses_test.exs` setup block.
**Why:** Tests assert `TestRepo.aggregate(WebhookEvent, :count) == 1`; cross-test row leakage breaks the assertion.

```elixir
TestRepo.query!("TRUNCATE TABLE mailglass_webhook_events CASCADE", [])
TestRepo.query!("TRUNCATE TABLE mailglass_events CASCADE", [])
```

### Pattern C: `TestRepo.aggregate(WebhookEvent, :count)` row assertion
**Source:** `test/mailglass/webhook/plug_mailgun_test.exs:40, 58` — and `test/mailglass/webhook/providers/resend_webhook_plug_test.exs:35` (per research).
**Apply to:** Every "happy path" plug test in the new file.
**Why:** Counts the audit-table row without coupling tests to row content (which belongs in `ses_test.exs` unit tests). Both Mailgun and Resend plug tests use this idiom verbatim.

```elixir
assert TestRepo.aggregate(WebhookEvent, :count) == 1
```

### Pattern D: `with_log` + `log =~ "provider=<atom>"` assertion (PII guard)
**Source:** `test/mailglass/webhook/plug_mailgun_test.exs:80-87`
**Apply to:** Every "bad signature" / "missing config" plug test in the new file.
**Why:** CLAUDE.md rule "Don't pattern-match errors by message string" + audit lines 320-329 confirm `WebhookSignatureLogger` emits `provider=ses reason=bad_signature` with no PII. The `refute log =~ raw_body` assertion catches accidental PII regressions.

```elixir
{result, log} =
  with_log(fn ->
    WebhookPlug.call(conn, WebhookPlug.init(provider: :ses))
  end)

assert result.status == 401
assert log =~ "provider=ses"
refute log =~ raw
```

### Pattern E: Atom ordering across `@valid_providers` and `ingest_multi/3` guard
**Source:** `lib/mailglass/webhook/plug.ex:84` (`@valid_providers [:postmark, :sendgrid, :mailgun, :ses, :resend]`) is the canonical order; `ingest.ex:122` must mirror it.
**Apply to:** The line-122 guard edit.
**Why:** Reviewers scanning the seam see the same atom order in both lists; reduces cognitive load and prevents drift.

```elixir
# plug.ex:84 (already correct)
@valid_providers [:postmark, :sendgrid, :mailgun, :ses, :resend]

# ingest.ex:122 (after Phase 19 fix — must match the order above)
when provider in [:postmark, :sendgrid, :mailgun, :ses, :resend]
```

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| (none) | — | — | Both files-to-touch have exact analogs in tree. Phase 16 Wave 0 already shipped every test primitive Phase 19 needs. |

---

## Metadata

**Analog search scope:**
- `lib/mailglass/webhook/ingest.ex` (in-file mirror — `:mailgun` and `:resend` clauses)
- `test/mailglass/webhook/plug_mailgun_test.exs` (canonical plug-test convention)
- `test/mailglass/webhook/providers/resend_webhook_plug_test.exs` (second analog, simpler structure)
- `test/mailglass/webhook/providers/ses_test.exs` (canonical-string + sign-fixture helper)
- `test/support/webhook_case.ex` (mailglass_webhook_conn(:ses, _) + stub_ses_fixture/1)
- `test/support/webhook_fixtures.ex` (generate_sns_keypair/0 + sign_sns_canonical_string/3)
- `lib/mailglass/webhook/providers/ses/cert_cache.ex` (CertCache.put/3 + reset/0)
- `test/support/fixtures/webhooks/ses/notification_delivery.json` (verified payload shape)

**Files scanned:** 8 (per the list above)
**Pattern extraction date:** 2026-04-30

---

## PATTERN MAPPING COMPLETE

**Phase:** 19 — Fix SES Ingest BLOCKER + Plug-level Integration Test
**Files classified:** 2
**Analogs found:** 2 / 2 (both exact-match)

### Coverage
- Files with exact analog: 2
- Files with role-match analog: 0
- Files with no analog: 0

### Key Patterns Identified
- **In-file mirror for the ingest seam fix** — the new `:ses` clause and the `:ses` guard atom both have byte-for-byte templates already in `ingest.ex` (`:mailgun` lines 366-368, `:resend` lines 373-375, guard line 122). Diff is ~7 lines total.
- **`plug_mailgun_test.exs` is the canonical plug-test shape** — `use WebhookCase, async: false`, truncate tables in setup, `WebhookPlug.call(conn, init(provider: _))`, assert `result.status` + `TestRepo.aggregate(WebhookEvent, :count)`. SES adds one wrinkle: keypair-mint + `CertCache.put/3` in setup (mirrored from `ses_test.exs:71-73`) and runtime fixture signing via `sign_ses_fixture/2` (mirrored from `ses_test.exs:59-65`).
- **Atom-ordering symmetry** between `Mailglass.Webhook.Plug.@valid_providers` and `ingest_multi/3` guard is a load-bearing reviewer-hint convention; insert `:ses` between `:mailgun` and `:resend` in both lists.

### File Created
`/Users/jon/projects/mailglass/.planning/phases/19-fix-ses-ingest-blocker-plug-test/19-PATTERNS.md`

### Ready for Planning
Pattern mapping complete. Planner can reference exact code excerpts (with line numbers) for the in-file mirror in `ingest.ex` and the full plug-test scaffold in `plug_mailgun_test.exs`. No additional helpers, fixtures, or schema changes required — Phase 16 Wave 0 already shipped every primitive.
