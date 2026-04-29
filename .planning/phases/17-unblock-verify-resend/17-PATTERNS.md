# Phase 17: Unblock & Verify Resend - Pattern Map

**Mapped:** 2026-04-29
**Files analyzed:** 7 (5 modified, 2 new)
**Analogs found:** 7 / 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/mailglass/webhook/plug.ex` | middleware | request-response | `lib/mailglass/webhook/plug.ex` (existing `:ses` / `:mailgun` clauses) | exact |
| `lib/mailglass/webhook/router.ex` | config | request-response | `lib/mailglass/webhook/router.ex` (existing `@valid_providers`) | exact |
| `test/mailglass/tracking/endpoint_resolution_test.exs` | test | request-response | Same file (every other tracking test using `Application.put_env`) | exact |
| `test/mailglass/webhook/plug_test.exs` | test | request-response | Same file (`:mailgun` / `:sendgrid` init success assertions) | exact |
| `test/support/webhook_case.ex` | test | request-response | Same file (`:mailgun` arm + `:ses` setup block) | exact |
| `test/mailglass/webhook/providers/resend_webhook_plug_test.exs` | test | request-response | `test/mailglass/webhook/plug_mailgun_test.exs` | role-match |
| `test/support/fixtures/webhooks/resend/delivered.json` | config | — | `test/mailglass/webhook/providers/resend_test.exs` `resend_payload/1` helper | exact |

---

## Pattern Assignments

### `lib/mailglass/webhook/plug.ex` (middleware, request-response)

**Analog:** Existing `:mailgun` and `:ses` entries in the same file.

**`@valid_providers` pattern** (`lib/mailglass/webhook/plug.ex` line 84):
```elixir
# Current — add :resend at the end
@valid_providers [:postmark, :sendgrid, :mailgun, :ses]
# After:
@valid_providers [:postmark, :sendgrid, :mailgun, :ses, :resend]
```

**`resolve_config!/2` — mailgun clause to mirror** (lines 249–258):
```elixir
defp resolve_config!(:mailgun, _conn) do
  env = Application.get_env(:mailglass, :mailgun, [])

  %{
    signing_key: env[:signing_key],
    timestamp_tolerance_seconds: env[:timestamp_tolerance_seconds] || 28_800,
    future_skew_seconds: env[:future_skew_seconds] || 300,
    replay_cache_ttl_seconds: env[:replay_cache_ttl_seconds] || 28_800
  }
end
```

**`resolve_config!/2` — new `:resend` clause (insert after `:ses` clause at line 266):**
```elixir
defp resolve_config!(:resend, _conn) do
  env = Application.get_env(:mailglass, :resend, [])

  %{
    secret: env[:secret],
    timestamp_tolerance_seconds: env[:timestamp_tolerance_seconds] || 300
  }
end
```
Config key names are dictated by `resend.ex verify!/3`: `Map.get(config, :secret)` and `Map.get(config, :timestamp_tolerance_seconds, 300)` (confirmed at `lib/mailglass/webhook/providers/resend.ex` lines 32–33).

**`provider_module/1` — exhaustive static dispatch** (lines 391–394):
```elixir
# Current — add :resend entry
defp provider_module(:postmark), do: Mailglass.Webhook.Providers.Postmark
defp provider_module(:sendgrid), do: Mailglass.Webhook.Providers.SendGrid
defp provider_module(:mailgun), do: Mailglass.Webhook.Providers.Mailgun
defp provider_module(:ses), do: Mailglass.Webhook.Providers.SES
# Add:
defp provider_module(:resend), do: Mailglass.Webhook.Providers.Resend
```

---

### `lib/mailglass/webhook/router.ex` (config, request-response)

**Analog:** Line 71 in the same file.

**One-atom addition pattern** (line 71):
```elixir
# Current:
@valid_providers [:postmark, :sendgrid, :mailgun, :ses]
# After:
@valid_providers [:postmark, :sendgrid, :mailgun, :ses, :resend]
```

**CRITICAL — do not touch** (line 72):
```elixir
# Leave unchanged — :resend is NOT a default provider
@default_providers [:postmark, :sendgrid]
```

---

### `test/mailglass/tracking/endpoint_resolution_test.exs` (test, request-response)

**Analog:** Every other tracking test file using `Application.put_env` (`config_validator_test`, `plug_test`, `rewriter_test`, `token_test`, `token_rotation_test`, `open_redirect_test`) — all use `async: false`.

**One-line fix pattern** (line 6):
```elixir
# Current:
use ExUnit.Case, async: true
# After:
use ExUnit.Case, async: false
```

---

### `test/mailglass/webhook/plug_test.exs` (test, request-response)

**Analog:** Existing `:mailgun` and `:sendgrid` init success assertions in the same file (lines 30–36).

**Existing pattern to mirror** (lines 30–36):
```elixir
test "valid :postmark provider opt survives init" do
  assert Keyword.get(WebhookPlug.init(provider: :postmark), :provider) == :postmark
end

test "valid :sendgrid provider opt survives init" do
  assert Keyword.get(WebhookPlug.init(provider: :sendgrid), :provider) == :sendgrid
end
```

**Current `:resend` test to REPLACE** (lines 38–41):
```elixir
# Remove this test entirely — it inverts after wiring:
test "raises ArgumentError on unknown provider" do
  assert_raise ArgumentError, ~r/unknown :provider/, fn ->
    WebhookPlug.init(provider: :resend)
  end
end
```

**Replacement test (copy success pattern above):**
```elixir
test "valid :resend provider opt survives init" do
  assert Keyword.get(WebhookPlug.init(provider: :resend), :provider) == :resend
end
```

---

### `test/support/webhook_case.ex` (test, request-response)

**Analog:** Existing `:mailgun` and `:ses` entries in the same file.

**`using` macro export list — add `stub_resend_fixture: 1`** (lines 58–67):
```elixir
import Mailglass.WebhookCase,
  only: [
    mailglass_webhook_conn: 2,
    mailglass_webhook_conn: 3,
    stub_postmark_fixture: 1,
    stub_mailgun_fixture: 1,
    stub_ses_fixture: 1,
    stub_sendgrid_fixture: 1,
    # Add:
    stub_resend_fixture: 1,
    freeze_timestamp: 1
  ]
```

**`setup` block — `prior_*` capture pattern** (lines 86–89):
```elixir
# Existing pattern for all providers:
prior_sendgrid = Application.get_env(:mailglass, :sendgrid)
prior_postmark = Application.get_env(:mailglass, :postmark)
prior_mailgun  = Application.get_env(:mailglass, :mailgun)
prior_ses      = Application.get_env(:mailglass, :ses)
# Add:
prior_resend   = Application.get_env(:mailglass, :resend)
```

**`setup` block — `Application.put_env` pattern** (lines 91–116). Mirror for `:resend`:
```elixir
Application.put_env(:mailglass, :mailgun,
  enabled: true,
  signing_key: "test-mailgun-signing-key",
  timestamp_tolerance_seconds: 28_800,
  future_skew_seconds: 300,
  replay_cache_ttl_seconds: 28_800
)
# Add for :resend (module-level constants @resend_secret_bytes / @resend_secret — see below):
Application.put_env(:mailglass, :resend,
  enabled: true,
  secret: @resend_secret,
  timestamp_tolerance_seconds: 300
)
```

**Module-level secret constants (add near top of module, outside any function):**
```elixir
@resend_secret_bytes :crypto.strong_rand_bytes(32)
@resend_secret "whsec_" <> Base.encode64(@resend_secret_bytes)
```
These are evaluated at compile time once per test run — safe because they are module attributes, not per-test values. The `svix_timestamp` MUST be generated at call time inside the function body (see pitfall note in RESEARCH.md).

**`on_exit` restore pattern** (lines 119–123):
```elixir
on_exit(fn ->
  restore_env(:sendgrid, prior_sendgrid)
  restore_env(:postmark, prior_postmark)
  restore_env(:mailgun, prior_mailgun)
  restore_env(:ses, prior_ses)
  # Add:
  restore_env(:resend, prior_resend)
end)
```

**`mailglass_webhook_conn/3` — `:mailgun` arm as structural template** (lines 194–204):
```elixir
def mailglass_webhook_conn(:mailgun, raw_body, opts) when is_binary(raw_body) do
  signing_key =
    case Application.fetch_env(:mailglass, :mailgun) do
      {:ok, cfg} -> Keyword.get(cfg, :signing_key, "test-mailgun-signing-key")
      :error -> "test-mailgun-signing-key"
    end

  signed_body = Mailglass.WebhookFixtures.sign_mailgun_payload(raw_body, signing_key, opts)

  base_conn(:mailgun, signed_body)
end
```

**New `:resend` arm (insert after `:ses` arm, line 212):**
```elixir
def mailglass_webhook_conn(:resend, raw_body, _opts) when is_binary(raw_body) do
  svix_id = "msg_test_#{System.unique_integer([:positive])}"
  svix_timestamp = Integer.to_string(System.system_time(:second))

  secret_bytes =
    case Application.fetch_env(:mailglass, :resend) do
      {:ok, cfg} ->
        "whsec_" <> encoded = Keyword.fetch!(cfg, :secret)
        Base.decode64!(encoded)
      :error ->
        :crypto.strong_rand_bytes(32)
    end

  sig = Mailglass.WebhookFixtures.sign_resend_payload(svix_id, svix_timestamp, raw_body, secret_bytes)

  base_conn(:resend, raw_body)
  |> Plug.Conn.put_req_header("svix-id", svix_id)
  |> Plug.Conn.put_req_header("svix-timestamp", svix_timestamp)
  |> Plug.Conn.put_req_header("svix-signature", "v1," <> sig)
end
```
Note: `sign_resend_payload/4` takes raw secret **bytes** (not the `whsec_` string). The arm decodes the prefix before passing. See `test/support/webhook_fixtures.ex` lines 167–175.

**`@spec` line for `mailglass_webhook_conn/3`** (line 153 — add `:resend` to the type union):
```elixir
@spec mailglass_webhook_conn(:postmark | :sendgrid | :mailgun | :ses | :resend, binary(), keyword()) ::
        Plug.Conn.t()
```

**`stub_resend_fixture/1` function (add after `stub_ses_fixture/1`):**
```elixir
@doc "Loads a Resend fixture and returns raw bytes ready for `mailglass_webhook_conn/2`."
@spec stub_resend_fixture(String.t()) :: binary()
def stub_resend_fixture(name), do: Mailglass.WebhookFixtures.load_resend_fixture(name)
```
`load_resend_fixture/1` already exists in `test/support/webhook_fixtures.ex` (lines 180–183) and reads from `test/support/fixtures/webhooks/resend/{name}.json`.

**`base_conn/2` helper** (lines 218–223 — no change needed, already handles any provider atom):
```elixir
defp base_conn(provider, raw_body) do
  :post
  |> Plug.Test.conn("/webhooks/#{provider}", raw_body)
  |> Plug.Conn.put_req_header("content-type", "application/json")
  |> Plug.Conn.put_private(:raw_body, raw_body)
end
```

---

### `test/mailglass/webhook/providers/resend_webhook_plug_test.exs` (test, request-response) — NEW

**Analog:** `test/mailglass/webhook/plug_mailgun_test.exs` (lines 1–119 — entire file).

**Module header + setup pattern** (lines 1–16 of plug_mailgun_test.exs):
```elixir
defmodule Mailglass.Webhook.PlugMailgunTest do
  use Mailglass.WebhookCase, async: false

  import ExUnit.CaptureLog

  alias Mailglass.TestRepo
  alias Mailglass.Webhook.Plug, as: WebhookPlug
  alias Mailglass.Webhook.Providers.MailgunReplayCache
  alias Mailglass.Webhook.WebhookEvent

  setup do
    MailgunReplayCache.reset()
    TestRepo.query!("TRUNCATE TABLE mailglass_webhook_events CASCADE", [])
    TestRepo.query!("TRUNCATE TABLE mailglass_events CASCADE", [])
    :ok
  end
```

**Differences for `:resend` version:**
- Module name: `Mailglass.Webhook.PlugResendTest`
- No `MailgunReplayCache` alias or reset — Resend has no replay cache
- Keep `TestRepo` + `WebhookEvent` aliases + TRUNCATE calls — the valid-signature → 200 path runs `ingest_multi/3` to completion (same as Mailgun)
- No `alias Mailglass.Webhook.Providers.MailgunReplayCache`

**Valid signature → 200 pattern** (lines 18–28 and 31–38 of plug_mailgun_test.exs):
```elixir
test "WebhookCase can build a signed Mailgun conn from raw bytes" do
  raw_body = Mailglass.WebhookCase.stub_mailgun_fixture("accepted")
  conn = Mailglass.WebhookCase.mailglass_webhook_conn(:mailgun, raw_body)
  # ...
  assert conn.request_path == "/webhooks/mailgun"
end

test "returns 200 on a valid signed Mailgun request" do
  raw_body = Mailglass.WebhookCase.stub_mailgun_fixture("accepted")
  conn = Mailglass.WebhookCase.mailglass_webhook_conn(:mailgun, raw_body, token: "mailgun-valid-200")

  result = WebhookPlug.call(conn, WebhookPlug.init(provider: :mailgun))

  assert result.status == 200
  assert TestRepo.aggregate(WebhookEvent, :count) == 1
end
```

**Adapted for Resend:**
```elixir
test "WebhookCase can build a signed Resend conn from raw bytes" do
  raw_body = stub_resend_fixture("delivered")
  conn = mailglass_webhook_conn(:resend, raw_body)

  assert conn.request_path == "/webhooks/resend"
  assert get_req_header(conn, "content-type") == ["application/json"]
  assert [_] = get_req_header(conn, "svix-id")
  assert [_] = get_req_header(conn, "svix-timestamp")
  assert [_] = get_req_header(conn, "svix-signature")
end

test "returns 200 on a valid signed Resend request" do
  raw_body = stub_resend_fixture("delivered")
  conn = mailglass_webhook_conn(:resend, raw_body)

  result = WebhookPlug.call(conn, WebhookPlug.init(provider: :resend))

  assert result.status == 200
  assert TestRepo.aggregate(WebhookEvent, :count) == 1
end
```

**Invalid/tampered signature → 401 pattern** (lines 61–78 of plug_mailgun_test.exs):
```elixir
test "returns 401 when the Mailgun signature is invalid" do
  raw_body = Mailglass.WebhookCase.stub_mailgun_fixture("accepted")
  conn = Mailglass.WebhookCase.mailglass_webhook_conn(:mailgun, raw_body, token: "mailgun-bad-signature")
  tampered_body = String.replace(conn.private[:raw_body], "\"signature\":\"", "\"signature\":\"0", global: false)

  tampered_conn = conn |> Plug.Conn.put_private(:raw_body, tampered_body)

  {result, log} =
    with_log(fn ->
      WebhookPlug.call(tampered_conn, WebhookPlug.init(provider: :mailgun))
    end)

  assert result.status == 401
  assert log =~ "provider=mailgun"
  refute log =~ raw_body
end
```

**Adapted for Resend (tamper the raw_body after signing):**
```elixir
test "returns 401 when the Resend body is tampered" do
  raw_body = stub_resend_fixture("delivered")
  conn = mailglass_webhook_conn(:resend, raw_body)
  tampered_conn = Plug.Conn.put_private(conn, :raw_body, raw_body <> "tampered")

  {result, log} = with_log(fn -> WebhookPlug.call(tampered_conn, WebhookPlug.init(provider: :resend)) end)

  assert result.status == 401
  assert log =~ "provider=resend"
  refute log =~ raw_body
end
```

**Stale timestamp → 401 pattern** (no direct Mailgun analog — Mailgun uses a different tolerance; use RESEARCH.md pattern):
```elixir
test "returns 401 when the Resend svix-timestamp is stale" do
  raw_body = stub_resend_fixture("delivered")
  stale_ts = Integer.to_string(System.system_time(:second) - 400)
  svix_id = "msg_stale_#{System.unique_integer([:positive])}"

  secret_bytes =
    "whsec_" <> encoded = Application.fetch_env!(:mailglass, :resend)[:secret]
    # extract just the encoded part:
    # use Base.decode64! on the encoded portion
    Base.decode64!(String.replace_prefix(Application.fetch_env!(:mailglass, :resend)[:secret], "whsec_", ""))

  sig = Mailglass.WebhookFixtures.sign_resend_payload(svix_id, stale_ts, raw_body, secret_bytes)

  conn =
    :post
    |> Plug.Test.conn("/webhooks/resend", raw_body)
    |> Plug.Conn.put_req_header("content-type", "application/json")
    |> Plug.Conn.put_private(:raw_body, raw_body)
    |> Plug.Conn.put_req_header("svix-id", svix_id)
    |> Plug.Conn.put_req_header("svix-timestamp", stale_ts)
    |> Plug.Conn.put_req_header("svix-signature", "v1," <> sig)

  {result, _log} = with_log(fn -> WebhookPlug.call(conn, WebhookPlug.init(provider: :resend)) end)
  assert result.status == 401
end
```
Note: The stale timestamp test accesses `@resend_secret_bytes` directly (the module attribute) rather than decoding the env string. Use `@resend_secret_bytes` from WebhookCase module attribute for clarity:
```elixir
sig = Mailglass.WebhookFixtures.sign_resend_payload(svix_id, stale_ts, raw_body, @resend_secret_bytes)
```
This requires `@resend_secret_bytes` to be accessible as a module attribute in the test module. Since WebhookCase is a separate module, pass the bytes via the `Application.get_env` decode path (shown in RESEARCH.md Code Examples section), or expose `@resend_secret_bytes` through a helper function.

**Missing `svix-id` header → 401 pattern:**
```elixir
test "returns 401 when svix-id header is missing" do
  raw_body = stub_resend_fixture("delivered")
  svix_timestamp = Integer.to_string(System.system_time(:second))

  conn =
    :post
    |> Plug.Test.conn("/webhooks/resend", raw_body)
    |> Plug.Conn.put_req_header("content-type", "application/json")
    |> Plug.Conn.put_private(:raw_body, raw_body)
    |> Plug.Conn.put_req_header("svix-timestamp", svix_timestamp)
    |> Plug.Conn.put_req_header("svix-signature", "v1,invalidsig")
    # Intentionally no svix-id header

  {result, _log} = with_log(fn -> WebhookPlug.call(conn, WebhookPlug.init(provider: :resend)) end)
  assert result.status == 401
end
```

**Init acceptance test pattern** (lines 115–118 of plug_mailgun_test.exs):
```elixir
describe "call/2 Mailgun explicit route execution" do
  test "init/1 accepts :mailgun as an explicit provider" do
    assert Keyword.get(WebhookPlug.init(provider: :mailgun), :provider) == :mailgun
  end
end
```

---

### `test/support/fixtures/webhooks/resend/delivered.json` (config) — NEW

**Analog:** Inline `resend_payload/1` helper in `test/mailglass/webhook/providers/resend_test.exs` (lines 205–215).

**Source payload shape** (lines 205–215 of resend_test.exs):
```elixir
defp resend_payload(type) do
  Jason.encode!(%{
    "id" => "evt_123",
    "type" => type,
    "created_at" => "2026-04-28T12:00:00Z",
    "data" => %{
      "email_id" => "email_123",
      "to" => ["person@example.com"]
    }
  })
end
```

**New `delivered.json` content:**
```json
{
  "id": "evt_delivered_001",
  "type": "email.delivered",
  "created_at": "2026-04-29T12:00:00Z",
  "data": {
    "email_id": "email_delivered_001",
    "to": ["test@example.com"]
  }
}
```
IMPORTANT: The fixture must be stable bytes (no extra whitespace added/removed at read time). `load_resend_fixture/1` uses `File.read!/1` which returns exact bytes. The signature is computed over exactly these bytes at test call time, not at compile time.

---

## Shared Patterns

### Provider Config Resolution Pattern
**Source:** `lib/mailglass/webhook/plug.ex` lines 249–266 (`:mailgun` and `:ses` `resolve_config!/2` clauses)
**Apply to:** New `resolve_config!(:resend, _conn)` clause
```elixir
# Per-provider shape: read Application env, return plain map with keys matching verify!/3's Map.get calls
defp resolve_config!(:mailgun, _conn) do
  env = Application.get_env(:mailglass, :mailgun, [])
  %{signing_key: env[:signing_key], timestamp_tolerance_seconds: env[:timestamp_tolerance_seconds] || 28_800, ...}
end
# :resend maps: secret + timestamp_tolerance_seconds only (verify!/3 reads exactly these two keys)
```

### Static Provider Dispatch Pattern
**Source:** `lib/mailglass/webhook/plug.ex` lines 388–394
**Apply to:** New `provider_module(:resend)` clause and `@valid_providers` in both plug.ex and router.ex
```elixir
# Exhaustive single-clause dispatch — init/1 validates at mount time, clauses are always reachable
defp provider_module(:ses), do: Mailglass.Webhook.Providers.SES
# Add after :ses:
defp provider_module(:resend), do: Mailglass.Webhook.Providers.Resend
```

### WebhookCase Env Lifecycle Pattern
**Source:** `test/support/webhook_case.ex` lines 86–123
**Apply to:** New `:resend` config setup in `WebhookCase` setup block
```elixir
# 1. Capture prior state
prior_X = Application.get_env(:mailglass, :X)
# 2. Install if install_config? is true
if install_config?, do: Application.put_env(:mailglass, :X, [...])
# 3. Restore on_exit (handles nil by deleting)
on_exit(fn -> restore_env(:X, prior_X) end)
```

### Plug Test 401 + Logger Discipline Pattern
**Source:** `test/mailglass/webhook/plug_test.exs` lines 62–79; `test/mailglass/webhook/plug_mailgun_test.exs` lines 61–78
**Apply to:** All 401-path assertions in `resend_webhook_plug_test.exs`
```elixir
{result, log} = with_log(fn -> WebhookPlug.call(conn, WebhookPlug.init(provider: :resend)) end)
assert result.status == 401
assert log =~ "provider=resend"
refute log =~ raw_body  # no PII leak
```

---

## No Analog Found

No files in this phase lack a codebase analog. All 7 files have exact or role-match analogs verified above.

---

## Metadata

**Analog search scope:** `lib/mailglass/webhook/`, `test/mailglass/webhook/`, `test/support/`
**Files scanned:** 9 source files read directly
**Pattern extraction date:** 2026-04-29
