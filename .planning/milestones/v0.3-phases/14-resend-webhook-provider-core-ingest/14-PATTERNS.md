# Phase 14: Resend Webhook Provider & Core Ingest - Pattern Map

**Mapped:** 2026-04-28
**Files analyzed:** 3
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/mailglass/webhook/providers/resend.ex` | provider | request-response | `lib/mailglass/webhook/providers/postmark.ex` | exact |
| `test/mailglass/webhook/providers/resend_test.exs` | test | request-response | `test/mailglass/webhook/providers/postmark_test.exs` | exact |
| `test/support/webhook_fixtures.ex` | test | transform | `test/support/webhook_fixtures.ex` | exact |

## Pattern Assignments

### `lib/mailglass/webhook/providers/resend.ex` (provider, request-response)

**Analog:** `lib/mailglass/webhook/providers/postmark.ex`

**Imports pattern** (lines 20-25):
```elixir
  @behaviour Mailglass.Webhook.Provider

  require Logger

  alias Mailglass.{ConfigError, SignatureError}
  alias Mailglass.Events.Event
```

**Core Verification pattern** (lines 29-31):
```elixir
  @impl Mailglass.Webhook.Provider
  @spec verify!(binary(), [{String.t(), String.t()}], map()) :: :ok
  def verify!(_raw_body, headers, %{} = config) when is_list(headers) do
```

**Normalization pattern** (lines 106-117):
```elixir
  @impl Mailglass.Webhook.Provider
  @spec normalize(binary(), [{String.t(), String.t()}]) :: [Event.t()]
  def normalize(raw_body, _headers) when is_binary(raw_body) do
    case Jason.decode(raw_body) do
      {:ok, payload} when is_map(payload) ->
        [build_event(payload)]

      _ ->
        Logger.warning("[mailglass] Postmark normalize: malformed JSON body")
        []
    end
  end
```

**Event Building/Taxonomy mapping pattern** (lines 119-133):
```elixir
  defp build_event(payload) do
    {type, reject_reason} = map_record_type(payload)
    provider_event_id = extract_event_id(payload)

    %Event{
      type: type,
      reject_reason: reject_reason,
      metadata: %{
        "provider" => "postmark",
        "provider_event_id" => provider_event_id,
        "record_type" => payload["RecordType"],
        "message_id" => payload["MessageID"] || to_string_or_nil(payload["ID"])
      }
    }
  end
```

---

### `test/mailglass/webhook/providers/resend_test.exs` (test, request-response)

**Analog:** `test/mailglass/webhook/providers/postmark_test.exs`

**Imports pattern** (lines 1-8):
```elixir
defmodule Mailglass.Webhook.Providers.PostmarkTest do
  use Mailglass.WebhookCase, async: false

  import ExUnit.CaptureLog

  alias Mailglass.{ConfigError, SignatureError}
  alias Mailglass.Webhook.Providers.Postmark
```

**Verification test pattern** (lines 15-20):
```elixir
  describe "verify!/3 Basic Auth happy path" do
    test "returns :ok with valid Basic Auth header" do
      {h, v} = Mailglass.WebhookFixtures.postmark_basic_auth_header(@user, @pass)
      assert :ok = Postmark.verify!("{}", [{h, v}], @config)
    end
  end
```

**Normalization test pattern** (lines 122-130):
```elixir
    test "Delivery -> :delivered" do
      body = Mailglass.WebhookFixtures.load_postmark_fixture("delivered")
      [event] = Postmark.normalize(body, [])

      assert event.type == :delivered
      assert event.reject_reason == nil
      assert event.metadata["provider"] == "postmark"
      assert event.metadata["record_type"] == "Delivery"
      assert is_binary(event.metadata["provider_event_id"])
    end
```

---

### `test/support/webhook_fixtures.ex` (test, transform)

**Analog:** `test/support/webhook_fixtures.ex`

**Fixture generation and crypto usage pattern (for HMAC/Svix equivalent)** (lines 75-84):
```elixir
  @doc """
  Signs `timestamp <> raw_body` with the given P-256 private key.
  """
  @spec sign_sendgrid_payload(String.t(), binary(), binary()) :: String.t()
  def sign_sendgrid_payload(timestamp, raw_body, priv_key)
      when is_binary(timestamp) and is_binary(raw_body) and is_binary(priv_key) do
    payload = timestamp <> raw_body
    sig = :crypto.sign(:ecdsa, :sha256, payload, [priv_key, :secp256r1])
    Base.encode64(sig)
  end
```

**Fixture loading pattern** (lines 112-115):
```elixir
  @spec load_postmark_fixture(String.t()) :: binary()
  def load_postmark_fixture(name) when is_binary(name) do
    File.read!(Path.join([@fixture_root, "postmark", name <> ".json"]))
  end
```

## Shared Patterns

### Cryptographic Verification
**Source:** `lib/mailglass/webhook/providers/postmark.ex`
**Apply to:** `lib/mailglass/webhook/providers/resend.ex`
```elixir
Plug.Crypto.secure_compare(sig, expected_sig)
```

## Metadata

**Analog search scope:** `lib/mailglass/webhook/providers/**/*.ex`, `test/mailglass/webhook/providers/**/*.exs`, `test/support/**/*.ex`
**Files scanned:** 3
**Pattern extraction date:** 2026-04-28