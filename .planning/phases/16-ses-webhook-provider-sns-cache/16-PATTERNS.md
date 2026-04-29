# Phase 16: SES Webhook Provider & SNS Cache - Pattern Map

**Mapped:** 2026-04-28
**Files analyzed:** 10 new/modified files
**Analogs found:** 10 / 10

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mailglass/webhook/providers/ses.ex` | provider | request-response | `lib/mailglass/webhook/providers/mailgun.ex` | exact |
| `lib/mailglass/webhook/providers/ses/cert_cache.ex` | utility/cache | request-response | `lib/mailglass/webhook/providers/mailgun_replay_cache.ex` | exact |
| `lib/mailglass/webhook/providers/ses/cert_cache/supervisor.ex` | supervisor | — | `lib/mailglass/webhook/providers/mailgun_replay_cache/supervisor.ex` | exact |
| `lib/mailglass/webhook/providers/ses/cert_cache/table_owner.ex` | genserver | — | `lib/mailglass/webhook/providers/mailgun_replay_cache/table_owner.ex` | exact |
| `lib/mailglass/webhook/providers/ses/trust_policy.ex` | utility | request-response | `lib/mailglass/webhook/providers/mailgun.ex` (inline `signatures_match?`) | role-match |
| `lib/mailglass/webhook/plug.ex` (modified) | middleware | request-response | self | exact |
| `lib/mailglass/webhook/router.ex` (modified) | route | request-response | self | exact |
| `lib/mailglass/application.ex` (modified) | config | — | self | exact |
| `test/mailglass/webhook/providers/ses_test.exs` | test | request-response | `test/mailglass/webhook/providers/mailgun_test.exs` | exact |
| `test/mailglass/webhook/providers/ses/cert_cache_test.exs` | test | — | `test/mailglass/webhook/providers/mailgun_test.exs` (replay tests) | role-match |

---

## Pattern Assignments

### `lib/mailglass/webhook/providers/ses.ex` (provider, request-response)

**Analog:** `lib/mailglass/webhook/providers/mailgun.ex`

**Imports pattern** (lines 1-13):
```elixir
defmodule Mailglass.Webhook.Providers.SES do
  @moduledoc """
  AWS SES webhook verifier + normalizer via SNS.
  """

  @behaviour Mailglass.Webhook.Provider

  require Logger

  alias Mailglass.{Clock, ConfigError, SignatureError}
  alias Mailglass.Events.Event
  alias Mailglass.Webhook.Providers.SES.{CertCache, TrustPolicy}
end
```

**Behaviour + typespec pattern** (mailgun.ex lines 18-20):
```elixir
@impl Mailglass.Webhook.Provider
@spec verify!(binary(), [{String.t(), String.t()}], map()) :: :ok | {:ok, :replay}
def verify!(raw_body, _headers, %{} = config) when is_binary(raw_body) do
```
SES extends the return type to include `{:ok, :control_plane, atom()}` for control-plane short-circuit. The `@behaviour` declaration and `@impl` annotations are non-negotiable (see provider.ex contract).

**Config resolution pattern** (mailgun.ex lines 20-25):
```elixir
signing_key = fetch_signing_key!(config)
tolerance = Map.get(config, :timestamp_tolerance_seconds, @default_tolerance_seconds)
```
SES reads from `Application.get_env(:mailglass, :ses)` via the same pattern used in `plug.ex` `resolve_config!/2` — see `lib/mailglass/webhook/plug.ex` lines 238-247 for the `:mailgun` resolver shape to copy for `:ses`.

**ConfigError raise pattern** (mailgun.ex lines 64-81):
```elixir
defp fetch_signing_key!(config) do
  case Map.get(config, :signing_key) do
    key when is_binary(key) and byte_size(key) > 0 ->
      key

    nil ->
      raise ConfigError.new(:webhook_verification_key_missing,
              context: %{
                provider: :mailgun,
                hint:
                  "configure {:mailgun, signing_key: \"..\"} in your :mailglass config"
              }
            )

    _other ->
      raise ConfigError.new(:invalid, context: %{key: :signing_key, provider: :mailgun})
  end
end
```
SES has no signing key (RSA is cert-based), but if SES config block is nil/empty raise `ConfigError.new(:webhook_verification_key_missing, context: %{provider: :ses, hint: "..."})`.

**SignatureError raise pattern** (mailgun.ex lines 33-35, 83-94):
```elixir
unless signatures_match?(expected_signature, signature) do
  raise SignatureError.new(:bad_signature, provider: :mailgun)
end
```
```elixir
raise SignatureError.new(:malformed_header,
        provider: :mailgun,
        context: %{detail: "signature payload is not valid Mailgun webhook JSON"}
      )
```
SES uses the same struct and same atoms (`:bad_signature`, `:malformed_header`, `:missing_header`). Always pass `provider: :ses`.

**Normalize/2 pattern** (mailgun.ex lines 47-62):
```elixir
@impl Mailglass.Webhook.Provider
@spec normalize(binary(), [{String.t(), String.t()}]) :: [Event.t()]
def normalize(raw_body, _headers) when is_binary(raw_body) do
  case Jason.decode(raw_body) do
    {:ok, %{} = payload} ->
      [build_event(payload)]

    {:ok, _other} ->
      Logger.warning("[mailglass] Mailgun normalize: expected JSON object payload")
      []

    {:error, _reason} ->
      Logger.warning("[mailglass] Mailgun normalize: malformed JSON body")
      []
  end
end
```
SES normalize returns `[Event.t()]` (a list; fan-out per recipient makes this naturally `[%Event{}, ...]`). Defensive `Jason.decode` with `Logger.warning` + `[]` fallback is mandatory.

**Event struct build pattern** (mailgun.ex lines 159-179):
```elixir
%Event{
  type: type,
  reject_reason: reject_reason,
  metadata: %{
    "provider" => "mailgun",
    "provider_event_id" => token,
    "record_type" => to_string_or_nil(event_data["event"]),
    "message_id" => get_in(event_data, ["message", "headers", "message-id"]),
    "mailgun_event_id" => to_string_or_nil(event_data["id"]),
    ...
  }
}
```
String keys in `metadata` are mandatory for JSONB round-trip safety. Required keys: `"provider"`, `"provider_event_id"`, `"record_type"`, `"message_id"`. SES adds: `"sns_message_id"`, `"ses_message_id"`, `"notification_type"` or `"event_type"`, `"bounce_type"`, `"bounce_subtype"`, `"complaint_feedback_type"` as applicable. All values must be strings or nil — no atom values in metadata.

**Unknown event fallthrough pattern** (mailgun.ex lines 198-203):
```elixir
defp map_event(%{"event" => other}) do
  Logger.warning("[mailglass] Unmapped Mailgun event: #{inspect(other)}")
  {:unknown, nil}
end

defp map_event(_other), do: {:unknown, nil}
```
SES must have the same shape: `Logger.warning("[mailglass] Unmapped SES eventType: #{inspect(other)}")` and fall to `{:unknown, nil}`. Never a silent catch-all that maps to `:hard_bounce`.

**Helper guards** (mailgun.ex lines 211-220):
```elixir
defp to_string_or_nil(nil), do: nil
defp to_string_or_nil(value), do: to_string(value)
```
Copy verbatim — all providers use this pattern.

---

### `lib/mailglass/webhook/providers/ses/cert_cache.ex` (utility/cache, request-response)

**Analog:** `lib/mailglass/webhook/providers/mailgun_replay_cache.ex`

**Module structure** (mailgun_replay_cache.ex lines 1-45):
```elixir
defmodule Mailglass.Webhook.Providers.MailgunReplayCache do
  @moduledoc "ETS-backed replay cache for Mailgun webhook tokens."

  @table :mailglass_webhook_mailgun_replay_cache

  @spec check_and_put(binary(), DateTime.t()) :: :ok | {:error, :replay}
  def check_and_put(token, %DateTime{} = expires_at) when is_binary(token) do
    now = Mailglass.Clock.utc_now()

    case :ets.lookup(@table, token) do
      [{^token, %DateTime{} = existing_expires_at}] ->
        if DateTime.compare(existing_expires_at, now) == :lt do
          :ets.take(@table, token)
          if :ets.insert_new(@table, {token, expires_at}) do
            :ok
          else
            {:error, :replay}
          end
        else
          {:error, :replay}
        end

      _ ->
        if :ets.insert_new(@table, {token, expires_at}) do
          :ok
        else
          {:error, :replay}
        end
    end
  end

  @doc since: "0.2.1"
  @spec reset() :: :ok
  def reset do
    :ets.delete_all_objects(@table)
    :ok
  end

  @doc since: "0.2.1"
  @spec table() :: atom()
  def table, do: @table
end
```

SES CertCache replaces `check_and_put/2` with `fetch_public_key/1` and `put/3` since the cert cache is a read-through cache, not an idempotency cache. Retain the `@table` atom, `reset/0`, and `table/0` functions verbatim. Use `Mailglass.Clock.utc_now()` for all TTL comparisons — never `DateTime.utc_now()` directly.

**Table name:** `@table :mailglass_webhook_ses_cert_cache` (follow the naming convention: `mailglass_webhook_{provider}_{purpose}`).

**Cache entry shape:** `{url_binary, public_key_term, expires_at_datetime}` stored as a 3-tuple.

**Clock usage** (mailgun_replay_cache.ex line 10):
```elixir
now = Mailglass.Clock.utc_now()
```
Copy verbatim — all TTL logic uses `Mailglass.Clock.utc_now()` not `DateTime.utc_now()` so tests can freeze time.

---

### `lib/mailglass/webhook/providers/ses/cert_cache/supervisor.ex` (supervisor)

**Analog:** `lib/mailglass/webhook/providers/mailgun_replay_cache/supervisor.ex` (exact copy, change module names)

**Full pattern** (mailgun_replay_cache/supervisor.ex lines 1-19):
```elixir
defmodule Mailglass.Webhook.Providers.MailgunReplayCache.Supervisor do
  @moduledoc "Supervises `Mailglass.Webhook.Providers.MailgunReplayCache.TableOwner`."
  use Supervisor

  def start_link(opts) do
    {name, init_opts} = Keyword.pop(opts, :name, __MODULE__)
    Supervisor.start_link(__MODULE__, init_opts, name: name)
  end

  @impl Supervisor
  def init(_opts) do
    children = [
      {Mailglass.Webhook.Providers.MailgunReplayCache.TableOwner,
       [name: Mailglass.Webhook.Providers.MailgunReplayCache.TableOwner]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
```
Replace `MailgunReplayCache` with `SES.CertCache` throughout. The `Keyword.pop(opts, :name, __MODULE__)` pattern allows test-time name injection so multiple test processes can start their own supervisor without name collision.

---

### `lib/mailglass/webhook/providers/ses/cert_cache/table_owner.ex` (genserver)

**Analog:** `lib/mailglass/webhook/providers/mailgun_replay_cache/table_owner.ex` (exact copy, change module names and table atom)

**Full pattern** (mailgun_replay_cache/table_owner.ex lines 1-32):
```elixir
defmodule Mailglass.Webhook.Providers.MailgunReplayCache.TableOwner do
  @moduledoc "Owns the Mailgun replay cache ETS table."
  use GenServer

  @table :mailglass_webhook_mailgun_replay_cache

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) when is_list(opts) do
    {name, _init_opts} = Keyword.pop(opts, :name)
    start_opts = if is_nil(name), do: [], else: [name: name]
    GenServer.start_link(__MODULE__, :ok, start_opts)
  end

  @impl GenServer
  def init(:ok) do
    :ets.new(@table, [
      :set,
      :public,
      :named_table,
      read_concurrency: true,
      write_concurrency: :auto
    ])

    {:ok, %{}}
  end

  @doc since: "0.2.1"
  @spec table() :: atom()
  def table, do: @table
end
```
Replace `@table` atom and module name. The ETS options (`:set`, `:public`, `:named_table`, `read_concurrency: true`, `write_concurrency: :auto`) are the project's established pattern — copy verbatim.

---

### `lib/mailglass/webhook/providers/ses/trust_policy.ex` (utility, request-response)

**Analog:** `lib/mailglass/webhook/providers/mailgun.ex` (inline guard helpers `signatures_match?/2`, `fetch_binary_field/2`) — same role (pure predicate helpers extracted into a helper module)

No exact multi-clause predicate module exists yet; this is a new sub-module pattern. The closest structural analog is the inline private helpers in mailgun.ex. Copy the private-helper style into a small `defmodule` with only `@spec` and `def` (no `@impl`).

**Module shape to follow:**
```elixir
defmodule Mailglass.Webhook.Providers.SES.TrustPolicy do
  @moduledoc "SNS URL trust-policy validation — SSRF guard for cert and subscribe URLs."

  @cert_host_pattern ~r/^sns\.[a-zA-Z0-9\-]{3,}\.amazonaws\.com(\.cn)?$/

  @spec valid_cert_url?(binary()) :: boolean()
  def valid_cert_url?(url) when is_binary(url) do
    # URI.parse/1 for structured decomposition — never raw regex on full URL
    case URI.parse(url) do
      %URI{scheme: "https", host: host, userinfo: nil, fragment: nil, path: path}
      when is_binary(host) and is_binary(path) ->
        String.match?(host, @cert_host_pattern) and String.ends_with?(path, ".pem")
      _ ->
        false
    end
  end

  @spec valid_subscribe_url?(binary()) :: boolean()
  def valid_subscribe_url?(url) when is_binary(url) do
    case URI.parse(url) do
      %URI{scheme: "https", host: host, userinfo: nil, fragment: nil}
      when is_binary(host) ->
        String.match?(host, @cert_host_pattern)
      _ ->
        false
    end
  end
end
```

**Pure-predicate pattern:** No `Logger`, no `raise`, no side effects. Callers in `ses.ex` raise `SignatureError` on `false`. This matches the separation of concerns visible in `signatures_match?/2` in mailgun.ex (line 124-129).

---

### `lib/mailglass/webhook/plug.ex` (modified — add `:ses` provider)

**Analog:** self (`lib/mailglass/webhook/plug.ex`)

**Three locations to update:**

**1. @valid_providers** (plug.ex line 84):
```elixir
# Before:
@valid_providers [:postmark, :sendgrid, :mailgun]

# After:
@valid_providers [:postmark, :sendgrid, :mailgun, :ses]
```

**2. resolve_config!/2 — add :ses clause** (plug.ex lines 238-247, following `:mailgun` clause pattern):
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
Add after this clause:
```elixir
defp resolve_config!(:ses, _conn) do
  env = Application.get_env(:mailglass, :ses, [])

  %{
    cert_cache_ttl_seconds: env[:cert_cache_ttl_seconds] || 86_400
  }
end
```

**3. provider_module/1 dispatch** (plug.ex lines 372-374):
```elixir
# Before (add :ses to the exhaustive list):
defp provider_module(:postmark), do: Mailglass.Webhook.Providers.Postmark
defp provider_module(:sendgrid), do: Mailglass.Webhook.Providers.SendGrid
defp provider_module(:mailgun), do: Mailglass.Webhook.Providers.Mailgun
```
Add: `defp provider_module(:ses), do: Mailglass.Webhook.Providers.SES`

**4. Control-plane short-circuit — add branch in do_call/3** (plug.ex lines 124-148):
```elixir
# Existing pattern:
case verify_with_telemetry!(provider, raw_body, headers, config) do
  {:ok, :replay} ->
    conn = send_resp(conn, 200, "")
    {conn, %{provider: provider, status: :replay, duplicate: true, event_count: 0}}

  :ok ->
    # ... normal ingest flow
end
```
Add new branch between `{:ok, :replay}` and `:ok`:
```elixir
  {:ok, :control_plane, outcome} ->
    Logger.info("[mailglass] SES SNS control-plane: provider=#{provider} outcome=#{outcome}")
    conn = send_resp(conn, 200, "")
    {conn, %{provider: provider, status: :control_plane, outcome: outcome}}
```

---

### `lib/mailglass/webhook/router.ex` (modified — add `:ses` to @valid_providers)

**Analog:** self (`lib/mailglass/webhook/router.ex`)

**Two constants to update** (router.ex lines 71-73):
```elixir
# Before:
@valid_providers [:postmark, :sendgrid, :mailgun]
@default_providers [:postmark, :sendgrid]

# After:
@valid_providers [:postmark, :sendgrid, :mailgun, :ses]
@default_providers [:postmark, :sendgrid]
```
`:ses` is added to `@valid_providers` (so adopters can opt in) but NOT to `@default_providers` (explicit opt-in required, matching the `:mailgun` precedent). The `@moduledoc` route list should be updated to mention `:ses` is available but not default.

---

### `lib/mailglass/application.ex` (modified — supervise SES CertCache)

**Analog:** self (`lib/mailglass/application.ex`)

**maybe_add pattern** (application.ex lines 25-34):
```elixir
|> maybe_add(
  Mailglass.Webhook.Providers.MailgunReplayCache.Supervisor,
  {Mailglass.Webhook.Providers.MailgunReplayCache.Supervisor, []}
)
```
Add after the MailgunReplayCache entry:
```elixir
|> maybe_add(
  Mailglass.Webhook.Providers.SES.CertCache.Supervisor,
  {Mailglass.Webhook.Providers.SES.CertCache.Supervisor, []}
)
```
No other changes to Application.ex. The `maybe_add/3` helper (lines 42-44) automatically gates on `Code.ensure_loaded?(module)` — the supervisor is added to the tree only once `ses/cert_cache/supervisor.ex` exists.

---

### `test/mailglass/webhook/providers/ses_test.exs` (test, request-response)

**Analog:** `test/mailglass/webhook/providers/mailgun_test.exs`

**Test module shell** (mailgun_test.exs lines 1-19):
```elixir
defmodule Mailglass.Webhook.Providers.MailgunTest do
  use Mailglass.WebhookCase, async: false

  import ExUnit.CaptureLog

  alias Mailglass.{ConfigError, SignatureError}
  alias Mailglass.Webhook.Providers.{Mailgun, MailgunReplayCache}

  @signing_key "mailgun-signing-key"
  @config %{
    signing_key: @signing_key,
    timestamp_tolerance_seconds: 300,
    future_skew_seconds: 60,
    replay_cache_ttl_seconds: 900
  }

  setup do
    MailgunReplayCache.reset()
    :ok
  end
```
SES equivalent: `use Mailglass.WebhookCase, async: false`, no `MailgunReplayCache.reset()` in `setup`. Instead, `setup` starts the CertCache supervisor for test isolation (or stubs `:httpc` via Mox). Config map is `%{}` (no signing key — RSA is cert-based).

**describe block structure** (mailgun_test.exs lines 22-93):
- `describe "verify!/3 {provider} verification"` — valid payload, malformed, bad signature, missing config
- `describe "verify!/3 {provider} replay handling"` — for SES: control-plane path (subscription confirmation, unsubscribe confirmation)
- `describe "normalize/2 {provider} event mapping"` — one test per event type

**catch_raised helper** (mailgun_test.exs lines 176-183):
```elixir
defp catch_raised(fun) do
  try do
    fun.()
    flunk("expected exception to be raised, but function returned normally")
  rescue
    error -> error
  end
end
```
Copy verbatim — this is the established pattern for testing `raise` in provider verify!/3.

**Assertion pattern** (mailgun_test.exs lines 97-103):
```elixir
test "accepted -> :queued" do
  [event] = Mailgun.normalize(signed_fixture("accepted", token: "token-accepted"), [])

  assert event.type == :queued
  assert event.reject_reason == nil
  assert event.metadata["provider"] == "mailgun"
  assert event.metadata["provider_event_id"] == "token-accepted"
end
```
SES tests assert `event.metadata["provider"] == "ses"` and check `provider_event_id` follows the `"#{sns_message_id}:#{email}"` stable derivation pattern (D-16).

**WebhookCase addition needed:** Add `stub_ses_fixture/1`, `load_ses_fixture/1`, and `sign_sns_payload/2` helpers to `WebhookFixtures` (analog of `sign_mailgun_payload/3` and `load_mailgun_fixture/1`). The RSA signing helper uses `:public_key.generate_key({:rsa, 2048, 65537})` at test runtime — never baked keys on disk.

---

### `test/mailglass/webhook/providers/ses/cert_cache_test.exs` (test, cache)

**Analog:** `test/mailglass/webhook/providers/mailgun_test.exs` replay describe block (lines 73-93) and table_owner.ex for direct ETS inspection

**Test structure:**
```elixir
defmodule Mailglass.Webhook.Providers.SES.CertCacheTest do
  use ExUnit.Case, async: false   # ETS named table; not safe async

  alias Mailglass.Webhook.Providers.SES.CertCache

  setup do
    # Start the supervisor to own the ETS table
    start_supervised!(Mailglass.Webhook.Providers.SES.CertCache.Supervisor)
    CertCache.reset()
    :ok
  end
```

**Cache hit/miss describe pattern** (mirrors mailgun_test.exs replay pattern lines 73-93):
```elixir
describe "verify!/3 Mailgun replay handling" do
  test "returns {:ok, :replay} when the token has already been accepted" do
    body = signed_fixture("accepted", token: "mailgun-replay-token")

    assert :ok = Mailgun.verify!(body, [], @config)
    assert {:ok, :replay} = Mailgun.verify!(body, [], @config)
  end
```
CertCache equivalent tests:
- `test "returns {:ok, key} on cache hit within TTL"` — put then fetch
- `test "returns :miss on empty cache"` — fetch with nothing stored
- `test "returns :miss on expired entry"` — put with past `expires_at`, then fetch
- `test "evicts expired entry on miss path"` — verify ETS table is cleaned up on expiry

**`start_supervised!/1` pattern:** Use ExUnit's `start_supervised!/1` (not manual `GenServer.start_link`) to ensure the process lifecycle is tied to the test. This is the standard OTP test pattern and allows `async: false` tests to share the supervisor safely.

---

## Shared Patterns

### SignatureError / ConfigError Raise Pattern
**Source:** `lib/mailglass/webhook/providers/mailgun.ex` lines 33-35, 64-81, 83-94
**Apply to:** `ses.ex` verify!/3, trust_policy validation in ses.ex
```elixir
raise SignatureError.new(:bad_signature, provider: :ses)
raise SignatureError.new(:malformed_header, provider: :ses, context: %{detail: "..."})
raise ConfigError.new(:webhook_verification_key_missing, context: %{provider: :ses, hint: "..."})
```
Always use struct constructors (`SignatureError.new/2`, `ConfigError.new/2`). Never raise `RuntimeError` or raw strings. Match errors by struct in tests with `assert %SignatureError{type: :bad_signature} = err`.

### Telemetry / Logger Discipline
**Source:** `lib/mailglass/webhook/plug.ex` moduledoc and `lib/mailglass/webhook/providers/mailgun.ex` lines 199-201
**Apply to:** `ses.ex` verify!/3 path, cert fetch path
```elixir
Logger.warning("[mailglass] SES normalize: unexpected SNS payload shape")
Logger.warning("[mailglass] Unmapped SES eventType: #{inspect(other)}")
```
Log prefix is always `[mailglass]`. Never log `:to`, `:from`, `:recipient`, `:subject`, `:body`, `:email` — only provider atom, outcome atom, and count/status integers.

### Clock.utc_now() for TTL
**Source:** `lib/mailglass/webhook/providers/mailgun_replay_cache.ex` line 10
**Apply to:** `ses/cert_cache.ex` TTL comparison
```elixir
now = Mailglass.Clock.utc_now()
```
Mandatory for testability. `DateTime.utc_now()` is banned in any TTL path.

### String keys in Event.metadata
**Source:** `lib/mailglass/webhook/providers/mailgun.ex` lines 164-178
**Apply to:** `ses.ex` build_event and all fan-out helpers
```elixir
metadata: %{
  "provider" => "ses",
  "provider_event_id" => "#{sns_message_id}:#{email}",
  "record_type" => ses_event_type_string,
  "message_id" => ses_message_id,
  "sns_message_id" => sns_message_id,
  ...
}
```
All metadata keys are strings. All metadata values are strings or nil — no atoms, no integers (use `to_string_or_nil/1`).

### ETS Table Options
**Source:** `lib/mailglass/webhook/providers/mailgun_replay_cache/table_owner.ex` lines 18-24
**Apply to:** `ses/cert_cache/table_owner.ex`
```elixir
:ets.new(@table, [
  :set,
  :public,
  :named_table,
  read_concurrency: true,
  write_concurrency: :auto
])
```
Copy verbatim. `:public` is required because the API module (cert_cache.ex) reads/writes the table directly without going through the GenServer.

### maybe_add Supervision
**Source:** `lib/mailglass/application.ex` lines 42-44
**Apply to:** new `maybe_add` call for SES CertCache Supervisor
```elixir
defp maybe_add(children, module, child_spec) do
  if Code.ensure_loaded?(module), do: children ++ [child_spec], else: children
end
```
This function is already defined — do not duplicate it. Just add a new `|> maybe_add(...)` call.

### Provider Dispatch Exhaustiveness
**Source:** `lib/mailglass/webhook/plug.ex` lines 371-374 + moduledoc note
**Apply to:** all three updates to plug.ex
```elixir
# init/1 validates at mount time — all provider_module/1 clauses must match
defp provider_module(:postmark), do: Mailglass.Webhook.Providers.Postmark
defp provider_module(:sendgrid), do: Mailglass.Webhook.Providers.SendGrid
defp provider_module(:mailgun), do: Mailglass.Webhook.Providers.Mailgun
```
`@valid_providers` in Plug, `@valid_providers` in Router, and `provider_module/1` clauses in Plug must all be updated atomically. The `init/1` check fires at router-mount time (compile-time in practice) if `@valid_providers` is correct — this is the safety net.

---

## No Analog Found

All files have close analogs. No RESEARCH.md fallback patterns needed.

---

## Metadata

**Analog search scope:** `lib/mailglass/webhook/`, `lib/mailglass/application.ex`, `test/mailglass/webhook/`, `test/support/`
**Files scanned:** 14
**Pattern extraction date:** 2026-04-28
