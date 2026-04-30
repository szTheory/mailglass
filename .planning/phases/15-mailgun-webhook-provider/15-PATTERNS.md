# Phase 15: mailgun-webhook-provider - Pattern Map

**Mapped:** 2026-04-28
**Files analyzed:** 17
**Analogs found:** 17 / 17

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mailglass/webhook/providers/mailgun.ex` | provider | request-response | `lib/mailglass/webhook/providers/resend.ex` | exact |
| `lib/mailglass/webhook/providers/mailgun_replay_cache.ex` | store | event-driven | `lib/mailglass/suppression_store/ets.ex` | role-match |
| `lib/mailglass/webhook/providers/mailgun_replay_cache/supervisor.ex` | store | event-driven | `lib/mailglass/suppression_store/ets/supervisor.ex` | exact |
| `lib/mailglass/webhook/providers/mailgun_replay_cache/table_owner.ex` | store | event-driven | `lib/mailglass/suppression_store/ets/table_owner.ex` | exact |
| `lib/mailglass/application.ex` | utility | event-driven | `lib/mailglass/application.ex` | exact |
| `lib/mailglass/webhook/plug.ex` | middleware | request-response | `lib/mailglass/webhook/plug.ex` | exact |
| `lib/mailglass/webhook/router.ex` | route | request-response | `lib/mailglass/webhook/router.ex` | exact |
| `lib/mailglass/config.ex` | config | request-response | `lib/mailglass/config.ex` | exact |
| `lib/mailglass/installer/templates.ex` | utility | transform | `lib/mailglass/installer/templates.ex` | exact |
| `guides/webhooks.md` | config | request-response | `guides/webhooks.md` | exact |
| `test/mailglass/webhook/providers/mailgun_test.exs` | test | request-response | `test/mailglass/webhook/providers/resend_test.exs` | exact |
| `test/mailglass/webhook/plug_mailgun_test.exs` | test | request-response | `test/mailglass/webhook/plug_test.exs` | exact |
| `test/mailglass/webhook/router_test.exs` | test | request-response | `test/mailglass/webhook/router_test.exs` | exact |
| `test/support/webhook_case.ex` | test | request-response | `test/support/webhook_case.ex` | exact |
| `test/support/fixtures/webhooks/mailgun/*.json` | test | file-I/O | `test/support/fixtures/webhooks/postmark/*.json` | role-match |
| `test/mailglass/config_test.exs` | test | request-response | `test/mailglass/config_test.exs` | exact |
| `test/mailglass/install/install_golden_test.exs` | test | file-I/O | `test/mailglass/install/install_golden_test.exs` | exact |

## Pattern Assignments

### `lib/mailglass/webhook/providers/mailgun.ex` (provider, request-response)

**Primary analog:** `lib/mailglass/webhook/providers/resend.ex`
**Secondary analog:** `lib/mailglass/webhook/providers/sendgrid.ex`

**Imports / behaviour pattern** (`resend.ex` lines 16-24):
```elixir
@behaviour Mailglass.Webhook.Provider

require Logger

alias Mailglass.{ConfigError, SignatureError}
alias Mailglass.Events.Event
```

**Verifier shape** (`resend.ex` lines 28-60):
```elixir
def verify!(raw_body, headers, %{} = config)
    when is_binary(raw_body) and is_list(headers) do
  tolerance = Map.get(config, :timestamp_tolerance_seconds, @default_tolerance_seconds)
  secret = fetch_secret!(config)

  with {:ok, svix_id} <- fetch_header(headers, @id_header),
       {:ok, svix_timestamp} <- fetch_header(headers, @timestamp_header),
       {:ok, svix_signature} <- fetch_header(headers, @signature_header),
       :ok <- verify_timestamp(svix_timestamp, tolerance) do
    ...
  else
    {:error, :missing_header} -> raise SignatureError.new(:missing_header, provider: :resend)
    {:error, :timestamp_skew} -> raise SignatureError.new(:timestamp_skew, provider: :resend)
    {:error, :malformed_timestamp} -> raise SignatureError.new(:malformed_header, ...)
  end
end
```

**Clock-backed timestamp check** (`sendgrid.ex` lines 99-107):
```elixir
with {ts_int, ""} <- Integer.parse(ts_str),
     {:ok, sent_at} <- DateTime.from_unix(ts_int, :second) do
  diff = abs(DateTime.diff(Clock.utc_now(), sent_at, :second))
  if diff <= tolerance, do: :ok, else: {:error, :timestamp_skew}
else
  _ -> {:error, :malformed_timestamp}
end
```

**Config error pattern** (`resend.ex` lines 81-105):
```elixir
case Map.get(config, :secret) do
  nil ->
    raise ConfigError.new(:webhook_verification_key_missing,
            context: %{
              provider: :resend,
              hint: "configure {:resend, secret: \"whsec_<base64-secret>\"} in your :mailglass config"
            }
          )

  _other ->
    raise ConfigError.new(:invalid, context: %{key: :secret, provider: :resend})
end
```

**Normalizer shape + metadata strings** (`resend.ex` lines 122-157):
```elixir
def normalize(raw_body, _headers) when is_binary(raw_body) do
  case Jason.decode(raw_body) do
    {:ok, payload} when is_map(payload) ->
      [build_event(payload)]

    _ ->
      Logger.warning("[mailglass] Resend normalize: malformed JSON body")
      []
  end
end

%Event{
  type: type,
  reject_reason: reject_reason,
  metadata: %{
    "provider" => "resend",
    "provider_event_id" => to_string_or_nil(payload["id"]),
    "record_type" => payload["type"],
    "message_id" => extract_message_id(payload)
  }
}
```

**Mapping breadth pattern** (`sendgrid.ex` lines 265-309):
```elixir
defp map_event(%{"event" => "processed"}), do: {:queued, nil}
defp map_event(%{"event" => "deferred"}), do: {:deferred, nil}
defp map_event(%{"event" => "delivered"}), do: {:delivered, nil}
...
defp map_event(%{"event" => other}) do
  Logger.warning("[mailglass] Unmapped SendGrid event: #{inspect(other)}")
  {:unknown, nil}
end
```

**What to copy:** native crypto verifier, typed `SignatureError` branches, JSON decode in `normalize/2`, and string-key metadata. Use `Mailglass.Clock.utc_now/0` from `sendgrid.ex`, not `System.system_time/1` from the older `resend.ex` timestamp helper.

---

### `lib/mailglass/webhook/providers/mailgun_replay_cache.ex` (store, event-driven)

**Analog:** `lib/mailglass/suppression_store/ets.ex`

**Public API shape** (`ets.ex` lines 42-88):
```elixir
@table :mailglass_suppression_store

def check(key, opts \\ [])
def record(attrs, opts \\ [])

def reset do
  :ets.delete_all_objects(@table)
  :ok
end
```

**ETS access pattern** (`ets.ex` lines 47-76):
```elixir
case :ets.lookup(@table, lookup_key) do
  [{^lookup_key, %Entry{} = entry}] ->
    ...

  _ ->
    nil
end

:ets.insert(@table, {key, entry})
```

**What to copy:** a tiny facade module around a named ETS table with `put_new`/`replay?`/`reset` style functions, no direct supervisor logic inside the API module.

---

### `lib/mailglass/webhook/providers/mailgun_replay_cache/supervisor.ex` (store, event-driven)

**Analog:** `lib/mailglass/suppression_store/ets/supervisor.ex`

**Supervisor pattern** (`supervisor.ex` lines 5-16):
```elixir
def start_link(opts) do
  {name, init_opts} = Keyword.pop(opts, :name, __MODULE__)
  Supervisor.start_link(__MODULE__, init_opts, name: name)
end

def init(_opts) do
  children = [
    {Mailglass.SuppressionStore.ETS.TableOwner, [name: Mailglass.SuppressionStore.ETS.TableOwner]}
  ]

  Supervisor.init(children, strategy: :one_for_one)
end
```

**What to copy:** single-child wrapper supervisor with overridable `:name`.

---

### `lib/mailglass/webhook/providers/mailgun_replay_cache/table_owner.ex` (store, event-driven)

**Analog:** `lib/mailglass/suppression_store/ets/table_owner.ex`

**GenServer owner pattern** (`table_owner.ex` lines 35-56):
```elixir
def start_link(opts \\ []) when is_list(opts) do
  {name, _init_opts} = Keyword.pop(opts, :name)
  start_opts = if is_nil(name), do: [], else: [name: name]
  GenServer.start_link(__MODULE__, :ok, start_opts)
end

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
```

**What to copy:** named-table owner process with explicit concurrency flags and a public `table/0` helper for tests.

---

### `lib/mailglass/application.ex` (utility, event-driven)

**Analog:** `lib/mailglass/application.ex`

**Conditional child wiring pattern** (`application.ex` lines 20-32, 39-41):
```elixir
children =
  [
    {Phoenix.PubSub, name: Mailglass.PubSub, adapter: Phoenix.PubSub.PG2},
    {Task.Supervisor, name: Mailglass.TaskSupervisor}
  ]
  |> maybe_add(Mailglass.Adapters.Fake.Supervisor, {Mailglass.Adapters.Fake.Supervisor, []})
  |> maybe_add(Mailglass.RateLimiter.Supervisor, {Mailglass.RateLimiter.Supervisor, []})
  |> maybe_add(
    Mailglass.SuppressionStore.ETS.Supervisor,
    {Mailglass.SuppressionStore.ETS.Supervisor, []}
  )

defp maybe_add(children, module, child_spec) do
  if Code.ensure_loaded?(module), do: children ++ [child_spec], else: children
end
```

**What to copy:** add the Mailgun replay cache supervisor using the same `maybe_add/3` pattern instead of hard-wiring it unconditionally.

---

### `lib/mailglass/webhook/plug.ex` (middleware, request-response)

**Analog:** `lib/mailglass/webhook/plug.ex`

**Provider validation + dispatch pattern** (lines 84-112):
```elixir
@valid_providers [:postmark, :sendgrid]

def init(opts) when is_list(opts) do
  provider = Keyword.fetch!(opts, :provider)

  unless provider in @valid_providers do
    raise ArgumentError, "Mailglass.Webhook.Plug: unknown :provider ..."
  end

  Keyword.put(opts, :provider, provider)
end

def call(conn, opts) do
  provider = Keyword.fetch!(opts, :provider)
  WebhookTelemetry.ingest_span(%{provider: provider, status: :pending}, fn ->
    do_call(conn, provider, opts)
  end)
end
```

**Main orchestration + rescue matrix** (lines 119-176):
```elixir
try do
  {raw_body, headers} = extract_headers_and_raw_body!(conn)
  config = resolve_config!(provider, conn)
  verify_with_telemetry!(provider, raw_body, headers, config)
  tenant_id = resolve_tenant!(provider, conn, raw_body, headers)
  ...
rescue
  e in SignatureError ->
    Logger.warning("Webhook signature failed: provider=#{provider} reason=#{e.type}")
    conn = send_resp(conn, 401, "")
    {conn, %{provider: provider, status: :signature_failed, failure_reason: e.type}}

  e in TenancyError ->
    conn = send_resp(conn, 422, "")
    ...

  e in ConfigError ->
    conn = send_resp(conn, 500, "")
    ...
end
```

**Config shaping pattern** (lines 188-223):
```elixir
defp extract_headers_and_raw_body!(conn) do
  case conn.private[:raw_body] do
    binary when is_binary(binary) -> {binary, conn.req_headers}
    nil -> raise ConfigError.new(:webhook_caching_body_reader_missing, ...)
  end
end

defp resolve_config!(:postmark, conn) do
  env = Application.get_env(:mailglass, :postmark, [])

  %{
    basic_auth: env[:basic_auth],
    ip_allowlist: env[:ip_allowlist] || [],
    remote_ip: conn.remote_ip
  }
end
```

**Success / duplicate response pattern** (lines 277-317):
```elixir
case Mailglass.Webhook.Ingest.ingest_multi(provider, raw_body, events) do
  {:ok, %{duplicate: true} = result} ->
    broadcast_post_commit(result)
    conn = send_resp(conn, 200, "")
    {conn, %{provider: provider, tenant_id: tenant_id, status: :duplicate, ...}}

  {:ok, result} ->
    broadcast_post_commit(result)
    conn = send_resp(conn, 200, "")
    {conn, %{provider: provider, tenant_id: tenant_id, status: :ok, ...}}
```

**What to copy:** preserve the current `try/rescue` structure and add a replay-specific non-401 path beside the duplicate `200` branch. Also extend `@valid_providers`, `resolve_config!/2`, and `provider_module/1` consistently.

---

### `lib/mailglass/webhook/router.ex` (route, request-response)

**Analog:** `lib/mailglass/webhook/router.ex`

**Compile-time provider validation** (lines 71-108):
```elixir
@valid_providers [:postmark, :sendgrid]
@default_providers @valid_providers
@default_as :mailglass_webhook

defmacro mailglass_webhook_routes(path, opts \\ []) do
  providers = Keyword.get(opts, :providers, @default_providers)
  as = Keyword.get(opts, :as, @default_as)

  Enum.each(providers, fn p ->
    unless p in @valid_providers do
      raise ArgumentError, "Mailglass.Webhook.Router: unknown provider #{inspect(p)} ..."
    end
  end)

  quote bind_quoted: [path: path, providers: providers, as: as] do
    for provider <- providers do
      post("#{path}/#{provider}", Mailglass.Webhook.Plug, [provider: provider], as: :"#{as}_#{provider}")
    end
  end
end
```

**What to copy:** keep zero-arg default behavior stable; only extend the validated provider list so `providers: [:mailgun]` is explicit opt-in.

---

### `lib/mailglass/config.ex` (config, request-response)

**Analog:** `lib/mailglass/config.ex`

**Provider subtree pattern** (`postmark` lines 223-248, `sendgrid` lines 255-281):
```elixir
postmark: [
  type: :keyword_list,
  default: [],
  doc: "Postmark webhook configuration (HOOK-03).",
  keys: [
    enabled: [type: :boolean, default: true, ...],
    basic_auth: [type: {:or, [{:tuple, [:string, :string]}, nil]}, default: nil, ...],
    ip_allowlist: [type: {:list, :string}, default: [], ...]
  ]
],
sendgrid: [
  type: :keyword_list,
  default: [],
  doc: "SendGrid webhook configuration (HOOK-04).",
  keys: [
    enabled: [type: :boolean, default: true, ...],
    public_key: [type: {:or, [:string, nil]}, default: nil, ...],
    timestamp_tolerance_seconds: [type: :pos_integer, default: 300, ...]
  ]
]
```

**Validation entrypoint pattern** (lines 393-416):
```elixir
def validate_at_boot! do
  known_keys = Keyword.keys(@schema)

  opts =
    :mailglass
    |> Application.get_all_env()
    |> Keyword.take(known_keys)
    |> normalize_optional_keyword_subtrees()

  validated = NimbleOptions.validate!(opts, @schema)
  ...
  :ok
end
```

**What to copy:** add a `mailgun:` subtree here, not in provider code. Keep all key-shape validation inside `Mailglass.Config`.

---

### `lib/mailglass/installer/templates.ex` (utility, transform)

**Analog:** `lib/mailglass/installer/templates.ex`

**Router snippet pattern** (lines 49-63):
```elixir
def webhook_mount_snippet(_opts \\ []) do
  """
      # Mailglass webhook routes (Postmark + SendGrid).
      import Mailglass.Webhook.Router

      pipeline :mailglass_webhooks do
        plug :accepts, ["json"]
      end

      scope "/" do
        pipe_through :mailglass_webhooks
        mailglass_webhook_routes "/webhooks"
      end
  """
end
```

**Endpoint parser snippet** (lines 84-91):
```elixir
def endpoint_webhook_parser_body do
  """
  plug Plug.Parsers,
    parsers: [:json],
    pass: ["*/*"],
    json_decoder: Jason,
    body_reader: {Mailglass.Webhook.CachingBodyReader, :read_body, []},
    length: 10_000_000
  """
end
```

**What to copy:** keep installer snippets declarative and explicit. For Mailgun support, emit an explicit `providers: [...]` example rather than silently changing the default snippet.

---

### `guides/webhooks.md` (config, request-response)

**Analog:** `guides/webhooks.md`

**Intro / provider list pattern** (lines 1-8, 43-72):
```md
Mailglass ships first-party verifiers for Postmark ... and SendGrid ...

scope "/", MyAppWeb do
  pipe_through :mailglass_webhooks
  mailglass_webhook_routes "/webhooks"
end

This generates two POST routes:
  * `POST /webhooks/postmark`
  * `POST /webhooks/sendgrid`

config :mailglass, :postmark, ...
config :mailglass, :sendgrid, ...
```

**Response matrix doc pattern** (lines 385-394):
```md
| 200 | Event persisted (or replay-duplicate structural no-op) |
| 401 | `%Mailglass.SignatureError{}` ... |
| 422 | `%Mailglass.TenancyError{...}` |
| 500 | `%Mailglass.ConfigError{}` ... |
```

**Test helper doc pattern** (lines 406-429):
```md
body = Mailglass.WebhookFixtures.load_postmark_fixture("delivered")
conn = Mailglass.WebhookCase.mailglass_webhook_conn(:postmark, body)
...
* `mailglass_webhook_conn/2,3`
* `stub_postmark_fixture/1` + `stub_sendgrid_fixture/1`
```

**What to copy:** preserve the step-by-step guide shape and update examples to show explicit Mailgun opt-in plus its config snippet and replay `200` semantics.

---

### `test/mailglass/webhook/providers/mailgun_test.exs` (test, request-response)

**Primary analog:** `test/mailglass/webhook/providers/resend_test.exs`
**Secondary analog:** `test/mailglass/webhook/providers/sendgrid_test.exs`

**Verifier test structure** (`resend_test.exs` lines 11-49):
```elixir
describe "verify!/3 ... happy path" do
  test "returns :ok for valid signature and timestamp" do
    ...
    assert :ok = Resend.verify!(body, headers, @config)
  end
end
```

**Failure-mode pattern** (`resend_test.exs` lines 51-147):
```elixir
err = catch_raised(fn -> Resend.verify!(body, headers, @config) end)
assert %SignatureError{type: :missing_header, provider: :resend} = err
...
assert %ConfigError{type: :webhook_verification_key_missing} = err
```

**Breadth mapping pattern** (`sendgrid_test.exs` lines 227-386):
```elixir
describe "normalize/2 ... event mapping" do
  test "single delivered event" do
    [event] = SendGrid.normalize(body, [])
    assert event.type == :delivered
    assert event.metadata["provider"] == "sendgrid"
  end

  test "unmapped event string -> :unknown + Logger.warning" do
    {events, log} = with_log(fn -> SendGrid.normalize(body, []) end)
    ...
  end
end
```

**What to copy:** use fixture-driven verify and normalize tests, a local `catch_raised/1` helper, and `with_log/1` for ambiguous/unmapped reason coverage.

---

### `test/mailglass/webhook/plug_mailgun_test.exs` (test, request-response)

**Analog:** `test/mailglass/webhook/plug_test.exs`

**Response-matrix test shape** (`plug_test.exs` lines 29-205):
```elixir
describe "init/1" do
  test "valid :postmark provider opt survives init" do
    assert Keyword.get(WebhookPlug.init(provider: :postmark), :provider) == :postmark
  end
end

describe "call/2 response code matrix ..." do
  test "401 on Postmark Basic Auth mismatch + Logger.warning discipline" do
    ...
    assert result.status == 401
    assert log =~ "provider=postmark"
    assert log =~ "reason=bad_credentials"
  end
end
```

**Telemetry whitelist pattern** (`plug_test.exs` lines 240-280):
```elixir
:telemetry.attach_many(handler_id, [[:mailglass, :webhook, :ingest, :start], [:mailglass, :webhook, :ingest, :stop]], ...)
...
for meta <- [start_meta, stop_meta] do
  refute Map.has_key?(meta, :ip)
  refute Map.has_key?(meta, :raw_body)
  refute Map.has_key?(meta, :headers)
end
```

**What to copy:** add Mailgun-specific tests for valid `200`, replay `200`, bad signature `401`, and missing-config `500` without weakening the existing log/telemetry discipline.

---

### `test/mailglass/webhook/router_test.exs` (test, request-response)

**Analog:** `test/mailglass/webhook/router_test.exs`

**Macro-expansion assertion pattern** (lines 6-33):
```elixir
defmodule DefaultRouter do
  use Phoenix.Router
  import Mailglass.Webhook.Router

  scope "/" do
    mailglass_webhook_routes("/webhooks")
  end
end

routes = DefaultRouter.__routes__()
assert length(routes) == 2
```

**Compile-failure pattern** (lines 87-105):
```elixir
assert_raise ArgumentError, ~r/unknown provider/, fn ->
  Code.compile_string("""
  ...
  mailglass_webhook_routes "/webhooks", providers: [:mailgun]
  ...
  """)
end
```

**What to copy:** keep the default route-count assertion, then replace the old `:mailgun` compile-failure case with positive explicit-opt-in coverage while preserving the zero-arg default assertions.

---

### `test/support/webhook_case.ex` (test, request-response)

**Analog:** `test/support/webhook_case.ex`

**Per-test env install pattern** (lines 72-101):
```elixir
prior_sendgrid = Application.get_env(:mailglass, :sendgrid)
prior_postmark = Application.get_env(:mailglass, :postmark)

if install_config? do
  Application.put_env(:mailglass, :sendgrid, ...)
  Application.put_env(:mailglass, :postmark, ...)
end

on_exit(fn ->
  restore_env(:sendgrid, prior_sendgrid)
  restore_env(:postmark, prior_postmark)
end)
```

**Conn-builder pattern** (lines 134-180):
```elixir
def mailglass_webhook_conn(:postmark, raw_body, _opts) when is_binary(raw_body) do
  ...
  base_conn(:postmark, raw_body)
  |> Plug.Conn.put_req_header(h, v)
end

def mailglass_webhook_conn(:sendgrid, raw_body, opts) when is_binary(raw_body) do
  ...
  base_conn(:sendgrid, raw_body)
  |> Plug.Conn.put_req_header("x-twilio-email-event-webhook-signature", sig_b64)
  |> Plug.Conn.put_req_header("x-twilio-email-event-webhook-timestamp", timestamp)
end
```

**What to copy:** extend the helper with a Mailgun branch that signs from JSON-body fields and keeps `conn.private[:raw_body]` mirrored exactly.

---

### `test/support/fixtures/webhooks/mailgun/*.json` (test, file-I/O)

**Analog:** `test/support/fixtures/webhooks/postmark/*.json`

**What to copy:** keep raw provider payloads on disk, one event shape per file, and leave signatures out of the fixture files. Signature material should be generated in test helpers, following the current SendGrid/WebhookCase discipline described in `guides/webhooks.md` lines 406-429 and `test/support/webhook_case.ex` lines 134-180.

---

### `test/mailglass/config_test.exs` (test, request-response)

**Analog:** `test/mailglass/config_test.exs`

**Schema-validation test pattern** (lines 9-31):
```elixir
describe "new!/1" do
  test "accepts empty opts and uses all defaults" do
    assert config = Mailglass.Config.new!([])
  end

  test "invalid key raises NimbleOptions.ValidationError" do
    assert_raise NimbleOptions.ValidationError, fn ->
      Mailglass.Config.new!(unknown_garbage_key: "value")
    end
  end
end
```

**Boot-validation pattern** (lines 35-45):
```elixir
describe "validate_at_boot!/0" do
  test "returns :ok with valid Application env" do
    assert :ok = Mailglass.Config.validate_at_boot!()
  end
end
```

**What to copy:** add direct schema tests for the Mailgun subtree and any new tolerance keys here.

---

### `test/mailglass/install/install_golden_test.exs` (test, file-I/O)

**Analog:** `test/mailglass/install/install_golden_test.exs`

**Golden snapshot pattern** (lines 9-29):
```elixir
test "fresh install snapshot stays stable" do
  fixture_root = new_fixture_root!("golden-fresh")
  run_install!(fixture_root, [])
  ...
  assert_snapshot_matches_or_refresh!("GOLDEN_FRESH", actual_snapshot)
end
```

**What to copy:** if installer webhook snippets change, keep snapshot-based assertions rather than ad hoc string assertions.

## Shared Patterns

### Provider contract
**Source:** `lib/mailglass/webhook/provider.ex` lines 13-48
**Apply to:** `mailgun.ex`
```elixir
@callback verify!(raw_body :: binary(), headers :: [{String.t(), String.t()}], config :: map()) :: :ok

@callback normalize(raw_body :: binary(), headers :: [{String.t(), String.t()}]) ::
            [Mailglass.Events.Event.t()]
```

### Typed webhook error handling
**Source:** `lib/mailglass/webhook/plug.ex` lines 139-176
**Apply to:** `plug.ex`, `plug_mailgun_test.exs`
```elixir
rescue
  e in SignatureError -> send_resp(conn, 401, "")
  e in TenancyError -> send_resp(conn, 422, "")
  e in ConfigError -> send_resp(conn, 500, "")
end
```

### Config lives in `Mailglass.Config`
**Source:** `CLAUDE.md`; `lib/mailglass/config.ex` lines 223-281
**Apply to:** `config.ex`, `mailgun.ex`, docs, installer
```elixir
mailgun: [
  type: :keyword_list,
  default: [],
  keys: [...]
]
```

### Supervised ETS owner
**Source:** `lib/mailglass/suppression_store/ets/supervisor.ex` lines 5-16; `lib/mailglass/suppression_store/ets/table_owner.ex` lines 35-56; `lib/mailglass/application.ex` lines 20-32
**Apply to:** replay cache modules and app wiring
```elixir
children = [
  {Mailglass....TableOwner, [name: Mailglass....TableOwner]}
]
```

### Webhook test harness
**Source:** `test/support/webhook_case.ex` lines 134-180
**Apply to:** `mailgun_test.exs`, `plug_mailgun_test.exs`
```elixir
base_conn(:provider, raw_body)
|> Plug.Conn.put_req_header(...)
|> Plug.Conn.put_private(:raw_body, raw_body)
```

### Installer/docs must stay explicit
**Source:** `lib/mailglass/installer/templates.ex` lines 49-63; `guides/webhooks.md` lines 43-72
**Apply to:** installer snippets and guide updates
```elixir
mailglass_webhook_routes "/webhooks"
```

## No Analog Found

None. Every planned file has a strong in-repo analog. The weakest match is the new Mailgun fixture directory, which should still follow the existing raw-JSON fixture pattern used by current webhook providers.

## Metadata

**Analog search scope:** `lib/mailglass/webhook/`, `lib/mailglass/suppression_store/`, `lib/mailglass/installer/`, `lib/mailglass/application.ex`, `guides/`, `test/mailglass/webhook/`, `test/support/`, `test/mailglass/install/`, `test/mailglass/config_test.exs`
**Files scanned:** 20
**Pattern extraction date:** 2026-04-28
