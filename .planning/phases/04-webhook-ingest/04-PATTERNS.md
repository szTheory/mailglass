# Phase 4: Webhook Ingest — Pattern Map

**Mapped:** 2026-04-23
**Files analyzed:** 32 new + 7 modified = 39
**Analogs found:** 33 / 39 (the 6 without analogs are mechanical glue files — mix tasks, fixture JSON, error-extension shims — for which RESEARCH.md code examples suffice)

**Prior-art libraries crawled (all four exist on disk):**

| Library | Path | Coverage |
|---------|------|----------|
| `lattice_stripe` | `~/projects/lattice_stripe/lib/lattice_stripe/webhook/` | THE primary analog — single-provider HMAC verifier + plug + CacheBodyReader + closed-atom SignatureVerificationError |
| `accrue` | `~/projects/accrue/accrue/lib/accrue/` | Multi-table webhook ingest (webhook_events + ledger), Oban cron Reconciler + Pruner, mix tasks, router macro, retention config |
| `sigra` | `~/projects/sigra/lib/sigra/admin/` | NO router macro analog — sigra uses installer-injected routes, not a macro. Phase 5 admin will be a macro per D-08; the accrue pattern below stands in. |
| `scrypath` | `~/projects/scrypath/lib/` | No webhook surface — not used as analog. |

**Within-repo prior phases crawled:** Phase 1 errors + telemetry + idempotency + application + config + adapter; Phase 2 events + reconciler + repo + migrations + tenancy + projector; Phase 3 outbound + projector PubSub + mailer_case + test_assertions.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/mailglass/webhook/provider.ex` | behaviour | request-response | `lib/mailglass/adapter.ex` (mailglass shipped) | exact (sealed callback module, same `@moduledoc false` shape, same closed-atom contract) |
| `lib/mailglass/webhook/providers/postmark.ex` | provider impl (verify+normalize) | request-response | `~/projects/lattice_stripe/lib/lattice_stripe/webhook.ex` (Stripe verifier) | role-match (different crypto: Postmark = Basic Auth, Stripe = HMAC) |
| `lib/mailglass/webhook/providers/sendgrid.ex` | provider impl (verify+normalize) | request-response | `~/projects/lattice_stripe/lib/lattice_stripe/webhook.ex` + RESEARCH §Pattern 2 | role-match (lattice_stripe is HMAC-SHA256 hex; SendGrid is ECDSA P-256 over DER — pattern shape identical, primitive different) |
| `lib/mailglass/webhook/caching_body_reader.ex` | utility (Plug body reader) | streaming | `~/projects/lattice_stripe/lib/lattice_stripe/webhook/cache_body_reader.ex` + `~/projects/accrue/accrue/lib/accrue/webhook/caching_body_reader.ex` | exact (mailglass = lattice_stripe storage location `conn.private[:raw_body]` + accrue's iodata accumulation across `{:more, _, _}` chunks) |
| `lib/mailglass/webhook/plug.ex` | controller (Plug) | request-response | `~/projects/accrue/accrue/lib/accrue/webhook/plug.ex` (accrue's plug → ingest pattern) | exact (call → verify → ingest_multi → 200/40x; same telemetry span + Logger.warning policy) |
| `lib/mailglass/webhook/router.ex` | route (defmacro) | configuration | `~/projects/accrue/accrue/lib/accrue/router.ex` | exact (defmacro inside scope + pipe_through; mailglass extends to multi-provider list per D-06/D-08) |
| `lib/mailglass/webhook/ingest.ex` | service (transactional write) | CRUD | `~/projects/accrue/accrue/lib/accrue/webhook/ingest.ex` + `lib/mailglass/outbound.ex` (mailglass shipped) | exact (Repo.transact wrapping Ecto.Multi composition; same 2-tuple collapse pattern Phase 3 D-20 standardized) |
| `lib/mailglass/webhook/reconciler.ex` | service (Oban worker) | event-driven (cron) | `~/projects/accrue/accrue/lib/accrue/jobs/meter_events_reconciler.ex` | exact (60s grace + 1000-row batch + cron-driven; CONTEXT D-17 names it as the verbatim port) |
| `lib/mailglass/webhook/pruner.ex` | service (Oban worker) | event-driven (cron) | `~/projects/accrue/accrue/lib/accrue/webhook/pruner.ex` + `~/projects/accrue/accrue/lib/accrue/webhooks/dlq.ex:206-236` | exact (status-aware retention + `:infinity` bypass + telemetry stop-emit) |
| `lib/mailglass/webhook/telemetry.ex` | utility (span helpers) | event-driven | `lib/mailglass/telemetry.ex` (mailglass shipped — `send_span/2`, `dispatch_span/2`, `events_append_span/2`) | exact (co-located span helpers per Phase 3 D-26 convention) |
| `lib/mailglass/tenancy/resolve_from_path.ex` | utility (behaviour impl) | request-response | `lib/mailglass/tenancy/single_tenant.ex` (mailglass shipped) | exact (one-line impl of an optional callback; mirrors SingleTenant) |
| `lib/mailglass/migrations/postgres/v02.ex` | migration (DDL) | batch | `lib/mailglass/migrations/postgres/v01.ex` (mailglass shipped) + `~/projects/accrue/accrue/priv/repo/migrations/20260412100003_create_accrue_webhook_events.exs` | exact (V01 = the dispatcher convention; accrue migration = the table shape) |
| `priv/repo/migrations/00000000000003_mailglass_webhook_events.exs` | migration (wrapper) | batch | `priv/repo/migrations/00000000000001_mailglass_init.exs` (mailglass shipped) | exact (8-line wrapper calling `Mailglass.Migration.up()`) |
| `lib/mix/tasks/mailglass.reconcile.ex` | mix task | request-response | `~/projects/accrue/accrue/lib/mix/tasks/accrue.webhooks.prune.ex` | role-match (different action — reconcile vs prune — but same OptionParser/`Mix.Task.run("app.start")`/worker.perform shape) |
| `lib/mix/tasks/mailglass.webhooks.prune.ex` | mix task | request-response | `~/projects/accrue/accrue/lib/mix/tasks/accrue.webhooks.prune.ex` | exact (verbatim port — same 30-line shape) |
| `test/support/webhook_case.ex` | test (case template) | configuration | `test/support/mailer_case.ex` (mailglass shipped) + `test/support/webhook_case.ex` (Phase 3 stub) | exact (extend the stub by `use Mailglass.MailerCase` + add Plug.Test imports) |
| `test/support/webhook_fixtures.ex` | test (fixture helpers) | configuration | RESEARCH §Code Examples + `test/support/fake_fixtures.ex` (mailglass shipped) | role-match (RESEARCH gives the exact `:crypto.generate_key/2` recipe; FakeFixtures is the file-shape analog) |
| `test/support/fixtures/webhooks/postmark/*.json` | test (data) | static | (none — provider docs) | no analog (verbatim from Postmark docs) |
| `test/support/fixtures/webhooks/sendgrid/*.json` | test (data) | static | (none — provider docs) | no analog (verbatim from Twilio SendGrid docs) |
| `test/mailglass/webhook/caching_body_reader_test.exs` | test (unit) | streaming | `test/mailglass/repo_test.exs` (mailglass shipped — tests Plug-adjacent infra) | role-match |
| `test/mailglass/webhook/router_test.exs` | test (unit) | configuration | (none in mailglass) — accrue has no router test | no analog (synthesize from Phoenix.Router conventions) |
| `test/mailglass/webhook/plug_test.exs` | test (integration) | request-response | `~/projects/accrue/accrue/test/accrue/webhook/plug_test.exs` (accrue) — confirmed via `find` | role-match (mailglass parallels but uses Mailglass.WebhookCase) |
| `test/mailglass/webhook/ingest_test.exs` | test (integration) | CRUD | `test/mailglass/events_append_multi_fn_test.exs` (mailglass shipped) | role-match (Multi composition test pattern) |
| `test/mailglass/webhook/reconciler_test.exs` | test (integration) | event-driven | `~/projects/accrue/accrue/test/accrue/jobs/meter_events_reconciler_test.exs` | role-match |
| `test/mailglass/webhook/pruner_test.exs` | test (integration) | event-driven | `~/projects/accrue/accrue/test/accrue/webhook/pruner_test.exs` (presumed; same shape) | role-match |
| `test/mailglass/webhook/providers/postmark_test.exs` | test (unit) | request-response | `test/mailglass/adapter_test.exs` (mailglass shipped) | role-match (behaviour-impl test pattern) |
| `test/mailglass/webhook/providers/sendgrid_test.exs` | test (unit) | request-response | `test/mailglass/adapter_test.exs` (mailglass shipped) | role-match |
| `test/mailglass/properties/webhook_idempotency_convergence_test.exs` | test (property) | CRUD | `test/mailglass/properties/idempotency_convergence_test.exs` (mailglass shipped) | exact (HOOK-07 mirrors PERSIST-03 — same TRUNCATE between iterations + sandbox `:auto` mode) |
| `test/mailglass/properties/webhook_signature_failure_test.exs` | test (property) | request-response | `test/mailglass/properties/idempotency_convergence_test.exs` (shape only) + RESEARCH §Property test shape | role-match |
| `test/mailglass/properties/webhook_tenant_resolution_test.exs` | test (property) | request-response | `test/mailglass/properties/idempotency_convergence_test.exs` (shape only) + RESEARCH §Property test shape | role-match |
| `test/mailglass/webhook/core_webhook_integration_test.exs` | test (UAT gate) | request-response | `test/mailglass/core_send_integration_test.exs` (mailglass shipped) | exact (`@moduletag :phase_04_uat` mirrors `:phase_03_uat`; verbatim shape) |
| `guides/webhooks.md` | docs | static | `~/projects/accrue/accrue/guides/*.md` (presumed — accrue ships guides dir; sample not loaded but file shape is generic markdown) | no analog (synthesize from CONTEXT D-12 + D-29 + D-25 outline in <specifics>) |
| `mix.exs` | config (modify) | configuration | `mix.exs` (mailglass shipped — `verify.phase_03` alias) | exact (additive `:public_key` to extra_applications + `verify.phase_04` alias mirroring `verify.phase_03`) |
| `lib/mailglass/repo.ex` | facade (modify) | CRUD | `lib/mailglass/repo.ex` (mailglass shipped — pattern of one-line passthrough delegates) | exact (add `query!/2` passthrough delegate, no SQLSTATE rescue) |
| `lib/mailglass/events/event.ex` | schema (modify) | CRUD | `lib/mailglass/events/event.ex:56` (mailglass shipped — `@mailglass_internal_types` list) | exact (add `:reconciled` to the list — one-line change) |
| `lib/mailglass/migrations/postgres.ex` | dispatcher (modify) | configuration | `lib/mailglass/migrations/postgres.ex:7` (mailglass shipped — `@current_version` constant) | exact (bump 1 → 2) |
| `lib/mailglass/errors/signature_error.ex` | error (modify) | configuration | `lib/mailglass/errors/signature_error.ex` (mailglass shipped — `@types` list + `format_message/2` clauses) | exact (extend `@types` from 4 to 7 atoms; add 3 new `format_message/2` clauses) |
| `lib/mailglass/errors/tenancy_error.ex` | error (modify) | configuration | `lib/mailglass/errors/tenancy_error.ex` (mailglass shipped) | exact (extend `@types` from `[:unstamped]` to `[:unstamped, :webhook_tenant_unresolved]`) |
| `lib/mailglass/errors/config_error.ex` | error (modify) | configuration | `lib/mailglass/errors/config_error.ex` (mailglass shipped) | exact (add `:webhook_verification_key_missing` to `@types`) |
| `lib/mailglass/tenancy.ex` | behaviour (modify) | configuration | `lib/mailglass/tenancy.ex:42` (mailglass shipped — `@optional_callbacks tracking_host: 1`) | exact (add `resolve_webhook_tenant: 1` to `@optional_callbacks`) |
| `docs/api_stability.md` | docs (modify) | static | `docs/api_stability.md` (mailglass shipped) | exact (additive section extensions) |

---

## Pattern Assignments

### `lib/mailglass/webhook/provider.ex` (behaviour, request-response)

**Analog:** `lib/mailglass/adapter.ex` (mailglass shipped — proves the sealed-callback pattern is in-house convention)

**Sealed-behaviour pattern with closed contract** (`lib/mailglass/adapter.ex:1-35`):
```elixir
defmodule Mailglass.Adapter do
  @moduledoc """
  Behaviour every mailglass adapter implements (TRANS-01).

  Return shape is locked in `docs/api_stability.md` §Adapter. Changes to
  the callback signature are semver-breaking.
  """

  @type deliver_ok :: %{required(:message_id) => String.t(), required(:provider_response) => term()}

  @callback deliver(Mailglass.Message.t(), keyword()) ::
              {:ok, deliver_ok()} | {:error, Mailglass.Error.t()}
end
```

**For Phase 4:** Same shape but with `@moduledoc false` (sealed per D-01 — adopters cannot implement at v0.1 because PROJECT D-10 defers Mailgun/SES/Resend to v0.5):

```elixir
defmodule Mailglass.Webhook.Provider do
  @moduledoc false  # SEALED — see api_stability.md §Webhook

  @callback verify!(raw_body :: binary(), headers :: [{String.t(), String.t()}], config :: map()) :: :ok
  @callback normalize(raw_body :: binary(), headers :: [{String.t(), String.t()}]) :: [Mailglass.Events.Event.t()]
end
```

---

### `lib/mailglass/webhook/providers/sendgrid.ex` (provider impl, request-response)

**Analog:** `~/projects/lattice_stripe/lib/lattice_stripe/webhook.ex` (different crypto primitive, identical shape)

**Imports + module-attribute constant** (`~/projects/lattice_stripe/lib/lattice_stripe/webhook.ex:56-64`):
```elixir
alias LatticeStripe.Event
alias LatticeStripe.Webhook.SignatureVerificationError

@type secret :: String.t() | [String.t(), ...]
@type verify_error ::
        :missing_header | :invalid_header | :no_matching_signature | :timestamp_expired

# Default replay attack protection window in seconds (matches Stripe's default).
@default_tolerance 300
```

**Verify-bang pattern wrapping verify** (`~/projects/lattice_stripe/lib/lattice_stripe/webhook.ex:117-124`):
```elixir
@spec construct_event!(String.t(), String.t() | nil, secret(), keyword()) :: Event.t()
def construct_event!(payload, sig_header, secret, opts \\ []) when is_binary(payload) do
  case construct_event(payload, sig_header, secret, opts) do
    {:ok, event} -> event
    {:error, reason} -> raise SignatureVerificationError, reason: reason
  end
end
```

**`with`-chain verification pipeline** (`~/projects/lattice_stripe/lib/lattice_stripe/webhook.ex:148-165`):
```elixir
def verify_signature(payload, sig_header, secret, opts \\ []) when is_binary(payload) do
  tolerance = Keyword.get(opts, :tolerance, @default_tolerance)

  with {:ok, timestamp_str, signatures} <- parse_header(sig_header),
       {:ok, timestamp} <- parse_timestamp(timestamp_str),
       :ok <- check_tolerance(timestamp, tolerance) do
    secrets = normalize_secrets(secret)
    computed = Enum.map(secrets, &compute_signature(payload, timestamp_str, &1))

    if signatures_match?(computed, signatures) do
      {:ok, timestamp}
    else
      {:error, :no_matching_signature}
    end
  end
end
```

**Critical SendGrid-specific replacement:** lattice_stripe uses `:crypto.mac(:hmac, :sha256, secret, signed_payload)`. SendGrid uses `:public_key.der_decode/2 + :public_key.verify/4` per RESEARCH §Pattern 2 (lines 244-267 of 04-RESEARCH.md). The `with`-chain shape stays identical; only `compute_signature/3` is replaced with the DER-decode-and-verify block. **Pattern-match strictly on `true`** — `false`, `{:error, _}`, and DER-decode exceptions all collapse to `%SignatureError{type: :bad_signature}` per D-21.

**Test signature generator** (`~/projects/lattice_stripe/lib/lattice_stripe/webhook.ex:206-212`) — port shape verbatim for the `WebhookFixtures.sign_sendgrid_payload/3` helper:
```elixir
@spec generate_test_signature(String.t(), String.t(), keyword()) :: String.t()
def generate_test_signature(payload, secret, opts \\ []) when is_binary(payload) do
  timestamp = Keyword.get(opts, :timestamp, System.system_time(:second))
  timestamp_str = Integer.to_string(timestamp)
  signature = compute_signature(payload, timestamp_str, secret)
  "t=#{timestamp_str},v1=#{signature}"
end
```

---

### `lib/mailglass/webhook/providers/postmark.ex` (provider impl, request-response)

**Analog:** Same lattice_stripe `Webhook` module + RESEARCH §Pattern 3 (lines 286-311 of 04-RESEARCH.md).

**Constant-time compare via Plug.Crypto.secure_compare/2** — pattern lifted directly from RESEARCH (already `Plug.Crypto.secure_compare/2`-based per `lattice_stripe/webhook.ex:294-298`):

```elixir
defp signatures_match?(computed, signatures) do
  Enum.any?(computed, fn computed_sig ->
    Enum.any?(signatures, &Plug.Crypto.secure_compare(computed_sig, &1))
  end)
end
```

**Postmark adapts this to:** parse `Authorization: Basic <b64>` header, decode, split on `:` into `{user, pass}`, then run two independent `Plug.Crypto.secure_compare/2` calls. RESEARCH lines 297-310 give the exact Elixir.

---

### `lib/mailglass/webhook/caching_body_reader.ex` (utility, streaming)

**Analog:** `~/projects/lattice_stripe/lib/lattice_stripe/webhook/cache_body_reader.ex` (storage location) + `~/projects/accrue/accrue/lib/accrue/webhook/caching_body_reader.ex` (iodata accumulation)

**Storage location pattern (lattice_stripe `cache_body_reader.ex:1-33`):**
```elixir
if Code.ensure_loaded?(Plug) do
  defmodule LatticeStripe.Webhook.CacheBodyReader do
    @moduledoc false

    @spec read_body(Plug.Conn.t(), keyword()) ::
            {:ok, binary(), Plug.Conn.t()}
            | {:more, binary(), Plug.Conn.t()}
            | {:error, term()}
    def read_body(conn, opts) do
      case Plug.Conn.read_body(conn, opts) do
        {:ok, body, conn} ->
          conn = Plug.Conn.put_private(conn, :raw_body, body)
          {:ok, body, conn}

        {:more, body, conn} ->
          conn = Plug.Conn.put_private(conn, :raw_body, body)
          {:more, body, conn}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end
end
```

**Mailglass extends this with iodata accumulation** (per CONTEXT D-09; the lattice_stripe version overwrites on `{:more, _, _}` chunks — fine for Stripe's bounded payloads, broken for SendGrid batches up to 128 events). Verbatim from RESEARCH §Pattern 4 (lines 332-365 of 04-RESEARCH.md):

```elixir
def read_body(conn, opts) do
  case Plug.Conn.read_body(conn, opts) do
    {:ok, body, conn} ->
      raw = IO.iodata_to_binary([conn.private[:raw_body] || <<>>, body])
      {:ok, body, Plug.Conn.put_private(conn, :raw_body, raw)}

    {:more, body, conn} ->
      raw = [conn.private[:raw_body] || <<>>, body]
      {:more, body, Plug.Conn.put_private(conn, :raw_body, raw)}

    {:error, reason} ->
      {:error, reason}
  end
end
```

**Storage convention diverges from accrue:** accrue stores in `conn.assigns[:raw_body]` (cons-list). Mailglass uses `conn.private[:raw_body]` (lattice_stripe convention) per CONTEXT D-09 — `conn.private` is library-reserved, off the adopter `assigns` contract. The accrue cons-list-with-reverse trick is replaced with the iodata `IO.iodata_to_binary/1` pattern that flattens at each `{:ok, _, _}` boundary.

---

### `lib/mailglass/webhook/plug.ex` (controller, request-response)

**Analog:** `~/projects/accrue/accrue/lib/accrue/webhook/plug.ex` (closest direct match)

**Behaviour declaration + telemetry-wrapped call** (`~/projects/accrue/accrue/lib/accrue/webhook/plug.ex:1-62`):
```elixir
defmodule Accrue.Webhook.Plug do
  @behaviour Plug

  import Plug.Conn

  require Logger

  alias Accrue.Webhook.Signature

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, opts) do
    processor = Keyword.fetch!(opts, :processor)
    endpoint = Keyword.get(opts, :endpoint)

    :telemetry.span(
      [:accrue, :webhook, :receive],
      %{processor: processor, endpoint: endpoint},
      fn ->
        result = do_call(conn, processor, endpoint)
        {result, %{processor: processor, endpoint: endpoint}}
      end
    )
  rescue
    e in Accrue.SignatureError ->
      Logger.warning("Webhook signature verification failed: #{e.reason}")

      conn
      |> send_resp(400, Jason.encode!(%{error: "signature_verification_failed"}))
      |> halt()

    e in Accrue.ConfigError ->
      Logger.error("Webhook setup error:\n" <> Exception.message(e))

      conn
      |> send_resp(500, Jason.encode!(%{error: "internal_server_error"}))
      |> halt()
  end
```

**Mailglass extensions** (per CONTEXT D-10 + D-13 + D-14 + D-22 + RESEARCH §Code Examples lines 696-768):
- Status codes diverge: `:signature_failed → 401` (not 400), `:config_error → 500`, `:tenant_unresolved → 422` (NEW — D-14), success `200`.
- Add a third rescue clause for `Mailglass.TenancyError → 422`.
- Use `Mailglass.Webhook.Telemetry.ingest_span/2` (named helper) instead of inline `:telemetry.span/3` per Phase 1 D-27 convention.
- Logger format per CONTEXT D-24: `"Webhook signature failed: provider=#{provider} reason=#{e.type}"` — atom only, no IP/headers/payload.

**Raw-body extraction with diagnostic on missing CachingBodyReader** (`~/projects/accrue/accrue/lib/accrue/webhook/plug.ex:114-132`):
```elixir
@doc false
def flatten_raw_body(conn) do
  case conn.assigns[:raw_body] do
    nil ->
      diagnostic =
        Accrue.SetupDiagnostic.webhook_raw_body(
          details:
            "Expected conn.assigns[:raw_body]; configure body_reader: {Accrue.Webhook.CachingBodyReader, :read_body, []}"
        )

      raise Accrue.ConfigError, key: :webhook_signing_secrets, diagnostic: diagnostic

    chunks when is_list(chunks) ->
      chunks |> Enum.reverse() |> IO.iodata_to_binary()

    binary when is_binary(binary) ->
      binary
  end
end
```

**Mailglass adaptation:** read from `conn.private[:raw_body]` (not assigns), raise `Mailglass.ConfigError.new(:webhook_verification_key_missing, context: %{detail: "..."})` (D-21 rationale closes the new atom). Already iodata-flattened by CachingBodyReader → no `Enum.reverse` needed; direct binary read.

---

### `lib/mailglass/webhook/router.ex` (route, defmacro)

**Analog:** `~/projects/accrue/accrue/lib/accrue/router.ex`

**Defmacro inside scope/pipe_through pattern** (`~/projects/accrue/accrue/lib/accrue/router.ex:45-50`):
```elixir
defmacro accrue_webhook(path, processor) do
  quote do
    forward(unquote(path), Accrue.Webhook.Plug, processor: unquote(processor))
  end
end
```

**Mailglass extends this** to a multi-provider macro per CONTEXT D-06 + D-08 (verbatim from RESEARCH §Code Examples lines 797-810):
```elixir
defmacro mailglass_webhook_routes(path, opts \\ []) do
  providers = Keyword.get(opts, :providers, [:postmark, :sendgrid])
  as = Keyword.get(opts, :as, :mailglass_webhook)

  quote bind_quoted: [path: path, providers: providers, as: as] do
    for provider <- providers do
      post "#{path}/#{provider}",
        Mailglass.Webhook.Plug,
        [provider: provider],
        as: :"#{as}_#{provider}"
    end
  end
end
```

Key differences from accrue: (a) generates N `post` routes (one per provider) rather than `forward`, (b) opts validated via NimbleOptions per `:providers` whitelist (`[:postmark, :sendgrid]` at v0.1; v0.5 adds Mailgun/SES/Resend), (c) defaults `:as` to `:mailglass_webhook` to lock the convention before Phase 5's `mailglass_admin_routes` macro lands.

---

### `lib/mailglass/webhook/ingest.ex` (service, CRUD)

**Analog:** `~/projects/accrue/accrue/lib/accrue/webhook/ingest.ex` + `lib/mailglass/events.ex` (mailglass shipped)

**Transactional ingest pattern** (`~/projects/accrue/accrue/lib/accrue/webhook/ingest.ex:50-84`):
```elixir
def run(conn, processor, stripe_event, raw_body, endpoint \\ nil) do
  processor_str = to_string(processor)
  endpoint_atom = normalize_endpoint(endpoint)

  result =
    Accrue.Repo.transact(fn repo ->
      case persist_event(repo, processor_str, stripe_event, raw_body, endpoint_atom) do
        {:ok, {:duplicate, _} = duplicate} ->
          {:ok, duplicate}

        {:ok, {:new, row} = persisted} ->
          with {:ok, _job} <- repo.insert(DispatchWorker.new(%{webhook_event_id: row.id})),
               {:ok, _event} <- record_received_event(processor_str, stripe_event, row) do
            {:ok, persisted}
          else
            {:error, reason} -> {:error, reason}
          end

        {:error, reason} ->
          {:error, reason}
      end
    end)

  case result do
    {:ok, {:new, _}} ->
      conn |> send_resp(200, Jason.encode!(%{ok: true})) |> halt()

    {:ok, {:duplicate, _}} ->
      conn |> send_resp(200, Jason.encode!(%{ok: true})) |> halt()

    {:error, reason} ->
      Logger.error("Webhook ingest failed: #{inspect(reason, limit: 200)}")
      conn |> send_resp(500, Jason.encode!(%{ok: false})) |> halt()
  end
end
```

**Mailglass diverges on shape:**
- Returns `{:ok, changes}` / `{:error, reason}` (not a Plug.Conn) — the plug owns response codes.
- Uses `Repo.transact(fn -> Repo.multi(multi) end)` composition per RESEARCH §Pattern 5 (mailglass-shipped pattern from Phase 3 D-20 — `Repo.transact/1` for SQLSTATE 45A01 translation + `Repo.multi/1` for canonical 4-tuple → 2-tuple collapse).
- Adds `SET LOCAL statement_timeout = '2s'; SET LOCAL lock_timeout = '500ms'` inside the transact closure per CONTEXT D-29 (mailglass `Repo` will gain `query!/2` passthrough delegate in Wave 0 — see `lib/mailglass/repo.ex` modification).
- No DispatchWorker (Phase 4 is sync per CONTEXT D-11 — accrue's async hop is removed).

**Multi composition uses Phase 2 shipped writers** (`lib/mailglass/events.ex:128-152`):
```elixir
@spec append_multi(Ecto.Multi.t(), atom(), attrs() | (map() -> attrs())) :: Ecto.Multi.t()
def append_multi(multi, name, attrs) when is_atom(name) and is_map(attrs) do
  normalized = normalize(attrs)
  changeset = Event.changeset(normalized)
  Ecto.Multi.insert(multi, name, changeset, insert_opts(normalized))
end

def append_multi(multi, name, attrs) when is_atom(name) and is_function(attrs, 1) do
  # Function form (Phase 3): compose via a Multi.run step that produces
  # the attrs map from prior Multi changes, then feeds it into the insert.
  attrs_name = String.to_atom(Atom.to_string(name) <> "_attrs")

  multi
  |> Ecto.Multi.run(attrs_name, fn _repo, changes -> {:ok, attrs.(changes)} end)
  |> Ecto.Multi.run(name, fn repo, changes ->
    raw = Map.fetch!(changes, attrs_name)
    normalized = normalize(raw)
    changeset = Event.changeset(normalized)
    opts = insert_opts(normalized)
    repo.insert(changeset, opts)
  end)
end
```

**Use the function form** in Phase 4 ingest_multi/3 to chain `Events.append_multi(:event_<i>, fn %{webhook_event: w} -> %{idempotency_key: "#{provider}:#{w.provider_event_id}:#{i}", ...} end)` so each event's idempotency key references the just-inserted webhook_event row.

**Idempotency key format extension** (`lib/mailglass/idempotency_key.ex:43-48`):
```elixir
@spec for_webhook_event(atom(), String.t()) :: String.t()
def for_webhook_event(provider, event_id)
    when is_atom(provider) and is_binary(event_id) do
  sanitize("#{provider}:#{event_id}")
end
```

Phase 4 uses an extended form `"#{provider}:#{event_id}:#{index}"` for SendGrid batches (per CONTEXT line 343). Add a new arity-3 `for_webhook_event/3` to `IdempotencyKey` rather than building strings inline.

---

### `lib/mailglass/webhook/reconciler.ex` (Oban worker, event-driven)

**Analog:** `~/projects/accrue/accrue/lib/accrue/jobs/meter_events_reconciler.ex` (CONTEXT D-17 names this verbatim port)

**Worker shape** (`~/projects/accrue/accrue/lib/accrue/jobs/meter_events_reconciler.ex:35-86`):
```elixir
use Oban.Worker, queue: :accrue_meters, max_attempts: 3

import Ecto.Query

alias Accrue.Billing.{MeterEvent, MeterEvents}
alias Accrue.Clock
alias Accrue.Processor
alias Accrue.Repo

@limit 1_000
@grace_seconds 60

@impl Oban.Worker
def perform(%Oban.Job{} = job) do
  _ = Accrue.Oban.Middleware.put(job)
  {:ok, _count} = reconcile()
  :ok
end

@spec reconcile() :: {:ok, non_neg_integer()}
def reconcile do
  cutoff = DateTime.add(Clock.utc_now(), -@grace_seconds, :second)

  pending =
    from(m in MeterEvent,
      where: m.stripe_status == "pending" and m.inserted_at < ^cutoff,
      order_by: [asc: m.inserted_at],
      limit: @limit
    )
    |> Repo.all()

  for row <- pending do
    case Processor.__impl__().report_meter_event(row) do
      {:ok, stripe_event} ->
        # ...
      {:error, err} ->
        # ...
    end
  end

  {:ok, length(pending)}
end
```

**Mailglass adaptations:**
- Wrap inside `if Code.ensure_loaded?(Oban.Worker) do ... end` per the mailglass OptionalDeps pattern (`lib/mailglass/optional_deps/oban.ex:59`).
- Queue name: `:mailglass_reconcile` (CONTEXT D-17).
- `unique: [period: 60]` to dedupe overlapping cron runs (CONTEXT does not lock this; recommend per Oban convention).
- Use `Mailglass.Oban.TenancyMiddleware.wrap_perform/2` instead of `Accrue.Oban.Middleware.put/1` (mailglass shipped equivalent — `lib/mailglass/optional_deps/oban.ex:124-133`).
- Replace inner work with `Mailglass.Events.Reconciler.find_orphans/1` + `attempt_link/1` (mailglass shipped — `lib/mailglass/events/reconciler.ex:56-133`).
- For matched orphans, append `:reconciled` event + projector update inside one Multi per CONTEXT D-18 + RESEARCH §Pattern 6 lines 446-498.

---

### `lib/mailglass/webhook/pruner.ex` (Oban worker, event-driven)

**Analog:** `~/projects/accrue/accrue/lib/accrue/webhook/pruner.ex` (verbatim port per CONTEXT D-16)

**Pruner worker shape** (`~/projects/accrue/accrue/lib/accrue/webhook/pruner.ex:30-51`):
```elixir
use Oban.Worker, queue: :accrue_maintenance

@impl Oban.Worker
def perform(_job) do
  succeeded_days = Accrue.Config.succeeded_retention_days()
  dead_days = Accrue.Config.dead_retention_days()

  {:ok, dead_deleted} = Accrue.Webhooks.DLQ.prune(dead_days)
  {:ok, succeeded_deleted} = Accrue.Webhooks.DLQ.prune_succeeded(succeeded_days)

  :telemetry.execute(
    [:accrue, :ops, :webhook_dlq, :prune],
    %{dead_deleted: dead_deleted, succeeded_deleted: succeeded_deleted},
    %{
      dead_retention_days: dead_days,
      succeeded_retention_days: succeeded_days
    }
  )

  :ok
end
```

**`prune` body with `:infinity` bypass** (`~/projects/accrue/accrue/lib/accrue/webhooks/dlq.ex:208-236`):
```elixir
@spec prune(pos_integer() | :infinity) :: {:ok, non_neg_integer()}
def prune(:infinity), do: {:ok, 0}

def prune(days) when is_integer(days) and days > 0 do
  cutoff = DateTime.add(DateTime.utc_now(), -days * 86_400, :second)

  {count, _} =
    from(w in WebhookEvent,
      where: w.status == :dead and w.inserted_at < ^cutoff
    )
    |> Repo.repo().delete_all()

  {:ok, count}
end

@spec prune_succeeded(pos_integer() | :infinity) :: {:ok, non_neg_integer()}
def prune_succeeded(:infinity), do: {:ok, 0}

def prune_succeeded(days) when is_integer(days) and days > 0 do
  cutoff = DateTime.add(DateTime.utc_now(), -days * 86_400, :second)

  {count, _} =
    from(w in WebhookEvent,
      where: w.status == :succeeded and w.inserted_at < ^cutoff
    )
    |> Repo.repo().delete_all()

  {:ok, count}
end
```

**Mailglass adaptations:**
- Conditional compile: `if Code.ensure_loaded?(Oban.Worker) do ... end` per OptionalDeps gateway.
- Three retention knobs (CONTEXT D-16): `succeeded_days: 14`, `dead_days: 90`, `failed_days: :infinity` (mailglass adds the third — `failed` is non-terminal investigatable state).
- Telemetry path renames per Phase 1 4-level convention: `[:mailglass, :webhook, :prune, :stop]` (not `[:accrue, :ops, :webhook_dlq, :prune]`) per CONTEXT D-22.
- Use `Mailglass.Clock.utc_now/0` (Phase 1 shipped) not `DateTime.utc_now/0` for consistency with `Mailglass.Events.Reconciler` (`lib/mailglass/events/reconciler.ex:67`).

**Retention config keys** (`~/projects/accrue/accrue/lib/accrue/config.ex:133-147`):
```elixir
succeeded_retention_days: [
  type: {:or, [:pos_integer, {:in, [:infinity]}]},
  default: 14,
  doc:
    "Number of days to retain `:succeeded` webhook events before the " <>
      "Pruner deletes them. Set to `:infinity` to disable pruning. Default: 14."
],
dead_retention_days: [
  type: {:or, [:pos_integer, {:in, [:infinity]}]},
  default: 90,
  doc:
    "Number of days to retain `:dead` webhook events before the " <>
      "Pruner deletes them. Set to `:infinity` to disable pruning. Default: 90."
],
```

Port verbatim into `Mailglass.Config` `@schema` under a `:webhook_retention` keyword sub-tree.

---

### `lib/mailglass/webhook/telemetry.ex` (utility, span helpers)

**Analog:** `lib/mailglass/telemetry.ex` (mailglass shipped — Phase 3 added `send_span/2`, `dispatch_span/2`, `persist_outbound_multi_span/2` co-located on the central module; Phase 4 follows the precedent that newer phases co-locate per-domain spans on a separate module)

**Span helper pattern** (`lib/mailglass/telemetry.ex:124-180`):
```elixir
@doc """
Named span helper for the events-append write path. Phase 2 surface.

Equivalent to `span([:mailglass, :events, :append], metadata, fun)`.
`:stop` metadata SHOULD include `inserted?: boolean` and
`idempotency_key_present?: boolean` per D-04.
"""
@doc since: "0.1.0"
@spec events_append_span(map(), (-> result)) :: result when result: term()
def events_append_span(metadata, fun) when is_map(metadata) and is_function(fun, 0) do
  span([:mailglass, :events, :append], metadata, fun)
end

@doc """
Named span helper wrapping the adapter.deliver/2 call (Phase 3, D-26).

Emits `[:mailglass, :outbound, :dispatch, :start | :stop | :exception]`.
Provider latency is the fat tail — this span captures it.
"""
@doc since: "0.1.0"
@spec dispatch_span(map(), (-> any())) :: any()
def dispatch_span(metadata, fun) when is_map(metadata) and is_function(fun, 0) do
  span([:mailglass, :outbound, :dispatch], metadata, fun)
end
```

**For Phase 4** (per CONTEXT D-22): five span helpers — `ingest_span/2`, `verify_span/2`, `normalize_emit/2`, `orphan_emit/2`, `duplicate_emit/2`, `reconcile_span/2`. The full-span helpers wrap `:telemetry.span/3` via `Mailglass.Telemetry.span/3`; the single-emit helpers wrap `:telemetry.execute/3` via `Mailglass.Telemetry.execute/3`. Co-located in a NEW module `lib/mailglass/webhook/telemetry.ex` per Phase 3 convention (mirrors the `lib/mailglass/outbound.ex` placement of `send_span/2`).

**Telemetry stop metadata whitelist enforcement** (`lib/mailglass/telemetry.ex:24-37`):
```
**Whitelisted keys:** `:tenant_id, :mailable, :provider, :status,
:message_id, :delivery_id, :event_id, :latency_ms, :recipient_count,
:bytes, :retry_count`.

**Forbidden (PII):** `:to, :from, :body, :html_body, :subject, :headers,
:recipient, :email`.
```

Phase 4 extends the whitelist additively per CONTEXT D-23: `:event_type, :failure_reason, :mapped, :duplicate, :delivery_id_matched, :event_count, :age_seconds, :scanned_count, :linked_count, :remaining_orphan_count`. **Explicitly excluded:** `:ip`, `:user_agent`, header values, raw body.

---

### `lib/mailglass/tenancy/resolve_from_path.ex` (utility, behaviour impl)

**Analog:** `lib/mailglass/tenancy/single_tenant.ex` (mailglass shipped — minimal `@behaviour` impl)

**Minimal behaviour impl** (`lib/mailglass/tenancy/single_tenant.ex:1-20`):
```elixir
defmodule Mailglass.Tenancy.SingleTenant do
  @moduledoc """
  Default `Mailglass.Tenancy` resolver: `scope/2` is a no-op.

  Single-tenant adopters need zero configuration — this is the
  `Mailglass.Config`-resolved default when `:tenancy` is `nil`.
  """
  @behaviour Mailglass.Tenancy

  @impl Mailglass.Tenancy
  def scope(query, _context), do: query
end
```

**For Phase 4 ResolveFromPath** (per CONTEXT D-12): same shape, implements only the new `c:resolve_webhook_tenant/1` callback (optional — adopter is not required to implement). Reads `context.path_params["tenant_id"]`; returns `{:ok, tid}` or `{:error, :missing_path_param}`. Does NOT implement `c:scope/2` because it's a sugar resolver, not a full Tenancy module — adopters compose it alongside their own `scope/2` impl.

---

### `lib/mailglass/migrations/postgres/v02.ex` (migration, batch DDL)

**Analog:** `lib/mailglass/migrations/postgres/v01.ex` (mailglass shipped — V01 dispatcher convention) + `~/projects/accrue/accrue/priv/repo/migrations/20260412100003_create_accrue_webhook_events.exs` (table shape)

**V01 dispatcher convention with prefix-aware DDL** (`lib/mailglass/migrations/postgres/v01.ex:1-83`):
```elixir
defmodule Mailglass.Migrations.Postgres.V01 do
  @moduledoc false
  use Ecto.Migration

  def up(opts \\ []) do
    prefix = opts[:prefix]

    # citext extension FIRST — Pitfall 8: ordering matters
    execute("CREATE EXTENSION IF NOT EXISTS citext")

    # Table 1: mailglass_deliveries
    create table(:mailglass_deliveries, primary_key: false, prefix: prefix) do
      add(:id, :uuid, primary_key: true)
      add(:tenant_id, :text, null: false)
      # ... columns ...
      timestamps(type: :utc_datetime_usec)
    end

    create(
      unique_index(:mailglass_deliveries, [:provider, :provider_message_id],
        where: "provider_message_id IS NOT NULL",
        name: :mailglass_deliveries_provider_msg_id_idx,
        prefix: prefix
      )
    )
    # ...
  end

  def down(_opts \\ []) do
    # Reverse order
    drop(table(:mailglass_suppressions))
    # ...
  end
end
```

**Table-shape pattern** (`~/projects/accrue/accrue/priv/repo/migrations/20260412100003_create_accrue_webhook_events.exs:13-40`):
```elixir
def change do
  create table(:accrue_webhook_events, primary_key: false) do
    add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")
    add :processor, :string, null: false
    add :processor_event_id, :string, null: false
    add :type, :string, null: false
    add :livemode, :boolean, default: false, null: false
    add :status, :string, default: "received", null: false
    add :raw_body, :binary
    add :received_at, :utc_datetime_usec
    add :processed_at, :utc_datetime_usec
    add :data, :map, default: %{}

    timestamps(type: :utc_datetime_usec)
  end

  create unique_index(:accrue_webhook_events, [:processor, :processor_event_id],
           name: :accrue_webhook_events_processor_event_id_index
         )

  create index(:accrue_webhook_events, [:type])
  create index(:accrue_webhook_events, [:livemode])

  create index(:accrue_webhook_events, [:status],
           where: "status IN ('failed', 'dead')",
           name: :accrue_webhook_events_failed_dead_index
         )
end
```

**Mailglass V02 combines both shapes** (per CONTEXT D-15):
- Use `up(opts \\ [])` + `down(opts \\ [])` (V01 dispatcher convention) not `change/0`.
- Add `:prefix` threading on every `create table` / `create index` per V01 line 13 / line 40.
- Column types match CONTEXT D-15 verbatim (lines 113-131 of 04-CONTEXT.md): `provider_event_id TEXT NOT NULL`, `event_type_raw TEXT NOT NULL`, `event_type_normalized TEXT`, `status TEXT NOT NULL`, `raw_payload JSONB NOT NULL`, `received_at TIMESTAMP WITH TIME ZONE NOT NULL`, `processed_at TIMESTAMP WITH TIME ZONE`.
- Use UUIDv7 primary key (CONTEXT discretion bullet — defaults YES; consistent with Phase 1 project-wide convention via `Mailglass.Schema`). Generate client-side via the schema, not via `gen_random_uuid()` DB default.
- Add `redact: true` on the `:raw_payload` field in the Ecto schema (matches accrue webhook_event.ex:48 — for `Inspect` safety).
- Drop `mailglass_events.raw_payload` column (CONTEXT line 132 — the V01 `add(:raw_payload, :map)` at v01.ex:77 is verified nullable + unused in shipped writers, safe drop).
- Bump `lib/mailglass/migrations/postgres.ex` `@current_version` from `1` to `2` (line 7) — the dispatcher's `change/3` already does the rest via `Module.concat([__MODULE__, "V02"])`.

---

### `priv/repo/migrations/00000000000003_mailglass_webhook_events.exs` (migration wrapper)

**Analog:** `priv/repo/migrations/00000000000001_mailglass_init.exs` (mailglass shipped — single-line wrapper convention)

The shipped V01 wrapper presumably calls `Mailglass.Migrations.Postgres.up(version: 1, prefix: "public")`. Phase 4 V02 wrapper calls the dispatcher with `version: 2`. The dispatcher sees `migrated_version` returns 1, runs `change(2..2, :up, opts)` which dispatches to `Mailglass.Migrations.Postgres.V02.up/1`, then records `COMMENT ON TABLE public.mailglass_events IS '2'`.

---

### `lib/mix/tasks/mailglass.webhooks.prune.ex` (mix task, request-response)

**Analog:** `~/projects/accrue/accrue/lib/mix/tasks/accrue.webhooks.prune.ex` (verbatim port)

**Mix task shape** (`~/projects/accrue/accrue/lib/mix/tasks/accrue.webhooks.prune.ex:1-29`):
```elixir
defmodule Mix.Tasks.Accrue.Webhooks.Prune do
  @shortdoc "Run the webhook event retention sweep on demand"
  @moduledoc """
  Manually trigger the same retention sweep that `Accrue.Webhook.Pruner`
  runs on its Oban cron schedule. Useful for ops engineers who want to
  reclaim DB space without waiting for the next scheduled run.

  ## Usage

      mix accrue.webhooks.prune

  Configuration is read from `Accrue.Config`:

    * `:succeeded_retention_days` (default `14`)
    * `:dead_retention_days` (default `90`)
  """

  use Mix.Task

  @impl Mix.Task
  def run(_argv) do
    Mix.Task.run("app.start")

    case Accrue.Webhook.Pruner.perform(%Oban.Job{}) do
      :ok ->
        Mix.shell().info("Webhook event retention sweep complete.")
    end
  end
end
```

**Mailglass extension:** add OptionParser arg parsing per CONTEXT discretion bullet — `--status :succeeded --older-than-days 7`. Otherwise verbatim.

`lib/mix/tasks/mailglass.reconcile.ex` follows the same shape but calls `Mailglass.Webhook.Reconciler.perform(%Oban.Job{args: %{...}})` with `--tenant-id`, `--max-age-minutes`, `--batch-size` args.

---

### `test/support/webhook_case.ex` (test case template)

**Analog:** `test/support/mailer_case.ex` (mailglass shipped — sets up sandbox + Fake + tenancy + PubSub) + `test/support/webhook_case.ex` (Phase 3 stub at lines 1-36)

**Existing stub** (`test/support/webhook_case.ex:1-36`):
```elixir
defmodule Mailglass.WebhookCase do
  @moduledoc """
  Test case template for webhook ingest tests (TEST-02).

  Phase 3 ships this skeleton. Phase 4 (HOOK-01..07) extends with:
  - `Plug.Test` helpers for HTTP request building
  - HMAC signature fixtures (Postmark Basic Auth + SendGrid ECDSA)
  - Body-preservation setup for `CachingBodyReader`
  - Provider-specific assertion helpers
  """
  use ExUnit.CaseTemplate

  using opts do
    quote do
      use Mailglass.MailerCase, unquote(opts)
      # Phase 4 will add:
      #   import Plug.Test
      #   import Mailglass.WebhookCase.Helpers
    end
  end
end
```

**Phase 4 extends per CONTEXT D-26:** add `import Plug.Test`, `import Mailglass.WebhookFixtures`, `mailglass_webhook_conn/3`, `assert_webhook_ingested/3` (mirrors `Mailglass.TestAssertions.assert_mail_delivered/2` shape — `lib/mailglass/test_assertions.ex:32-38`), `stub_postmark_fixture/1`, `stub_sendgrid_fixture/1`, `freeze_timestamp/1` (re-exports Phase 3 D-07 `Mailglass.Clock.Frozen.freeze/1`).

---

### `test/mailglass/properties/webhook_idempotency_convergence_test.exs` (property test, CRUD)

**Analog:** `test/mailglass/properties/idempotency_convergence_test.exs` (mailglass shipped — exact shape match for HOOK-07 vs PERSIST-03)

**Sandbox-mode + TRUNCATE pattern** (`test/mailglass/properties/idempotency_convergence_test.exs:31-72`):
```elixir
use ExUnit.Case, async: false
use ExUnitProperties

import Ecto.Query

alias Ecto.Adapters.SQL.Sandbox
alias Mailglass.Events
alias Mailglass.Events.Event
alias Mailglass.TestRepo

setup do
  Sandbox.mode(TestRepo, :auto)

  # Wipe any residue from other tests so this property starts clean.
  TestRepo.query!("TRUNCATE TABLE mailglass_events", [])

  on_exit(fn ->
    TestRepo.query!("TRUNCATE TABLE mailglass_events", [])
    Sandbox.mode(TestRepo, :manual)
  end)

  :ok
end

@event_types [:queued, :dispatched, :delivered, :bounced, :complained, :opened]

@tag timeout: :infinity
property "convergence: apply_all(events) == apply_all(replays_shuffled)" do
  check all(
          events <- list_of(event_attrs_gen(), min_length: 1, max_length: 20),
          replay_count <- integer(1..10),
          max_runs: 1000
        ) do
    # Wipe events table between iterations to isolate state.
    TestRepo.query!("TRUNCATE TABLE mailglass_events", [])
    # ...
  end
end
```

**Phase 4 webhook variant** (per HOOK-07): TRUNCATE both `mailglass_events` AND `mailglass_webhook_events`. Use `Mailglass.Webhook.Plug.call/2` (or directly `Mailglass.Webhook.Ingest.ingest_multi/3`) as the unit-of-work instead of `Events.append/1`. Generator produces `(provider, event_payload, replay_count ∈ 1..10)` tuples. Snapshot compares both tables by `(provider, provider_event_id)` and per-event `idempotency_key`.

---

### `test/mailglass/webhook/core_webhook_integration_test.exs` (UAT gate)

**Analog:** `test/mailglass/core_send_integration_test.exs` (mailglass shipped — Phase 3 UAT gate)

**UAT gate shape** (`test/mailglass/core_send_integration_test.exs:1-26`):
```elixir
defmodule Mailglass.CoreSendIntegrationTest do
  @moduledoc """
  Phase 3 phase-wide UAT gate. Runs via `mix verify.phase_03` alias.

  Every test in this file maps 1:1 to a ROADMAP §Phase 3 success
  criterion. When all 5 criteria pass, Phase 3 is shipped.

  Success criteria from ROADMAP §Phase 3:
    1. ...
    2. ...
  """
  use Mailglass.MailerCase, async: false

  @moduletag :phase_03_uat
```

**Phase 4 mirror:** `use Mailglass.WebhookCase, async: false`, `@moduletag :phase_04_uat`, one `describe` block per ROADMAP §Phase 4 success criterion (5 checks per CONTEXT canonical_refs line 251).

---

### `mix.exs` (modify — additive)

**Analog:** `mix.exs` (mailglass shipped — `verify.phase_03` alias at lines 116-121)

**Additions per CONTEXT spec_lock + RESEARCH §Wave 0 Gaps:**

1. Add `:public_key` to `extra_applications` (currently line 30: `extra_applications: [:logger, :crypto]`). Without it, releases strip the OTP app and SendGrid verification fails at runtime with `:undef`.

2. Add `verify.phase_04` alias mirroring `verify.phase_03` shape:
```elixir
"verify.phase_04": [
  "ecto.drop -r Mailglass.TestRepo --quiet",
  "ecto.create -r Mailglass.TestRepo --quiet",
  "test --warnings-as-errors --only phase_04_uat --exclude flaky",
  "compile --no-optional-deps --warnings-as-errors"
],
```

---

### `lib/mailglass/repo.ex` (modify — additive)

**Analog:** `lib/mailglass/repo.ex` (mailglass shipped — `one/2` and `all/2` are one-line passthrough delegates without SQLSTATE rescue)

**Existing one-line delegate pattern** (`lib/mailglass/repo.ex:113-127`):
```elixir
@doc "Delegates to the host Repo's `one/2`."
@doc since: "0.1.0"
@spec one(Ecto.Queryable.t(), keyword()) :: struct() | nil
def one(queryable, opts \\ []), do: repo().one(queryable, opts)

@doc "Delegates to the host Repo's `all/2`."
@doc since: "0.1.0"
@spec all(Ecto.Queryable.t(), keyword()) :: [struct()]
def all(queryable, opts \\ []), do: repo().all(queryable, opts)

@doc "Delegates to the host Repo's `get/3`."
@doc since: "0.1.0"
@spec get(Ecto.Queryable.t(), term(), keyword()) :: struct() | nil
def get(queryable, id, opts \\ []), do: repo().get(queryable, id, opts)
```

**Add `query!/2` in the same shape** (no SQLSTATE rescue — raw query passthrough used inside the `Repo.transact/1` closure for `SET LOCAL statement_timeout`):
```elixir
@doc "Delegates to the host Repo's `query!/2`. Raw passthrough — no SQLSTATE translation."
@doc since: "0.1.0"
@spec query!(String.t(), [term()]) :: %Postgrex.Result{}
def query!(sql, params \\ []), do: repo().query!(sql, params)
```

---

### `lib/mailglass/events/event.ex` (modify — extend `@mailglass_internal_types`)

**Analog:** `lib/mailglass/events/event.ex:56` (mailglass shipped)

**Existing closed atom set** (`lib/mailglass/events/event.ex:39-57`):
```elixir
@anymail_event_types [
  :queued,
  :sent,
  :rejected,
  :failed,
  :bounced,
  :deferred,
  :delivered,
  :autoresponded,
  :opened,
  :clicked,
  :complained,
  :unsubscribed,
  :subscribed,
  :unknown
]

@mailglass_internal_types [:dispatched, :suppressed]
@event_types @anymail_event_types ++ @mailglass_internal_types
```

**Phase 4 change** (one-line, per CONTEXT spec_lock §Anymail amendment + RESEARCH §Pattern 6 line 442):
```elixir
@mailglass_internal_types [:dispatched, :suppressed, :reconciled]
```

**No DB migration needed:** the column is `:text` at the DB level (V01:73 `add(:type, :text, null: false)`) — only the `Ecto.Enum` `values:` list is closed. Adding to `@mailglass_internal_types` extends the list automatically via the `++ @mailglass_internal_types` concat at line 57.

---

### `lib/mailglass/migrations/postgres.ex` (modify — bump version)

**Analog:** `lib/mailglass/migrations/postgres.ex:7` (mailglass shipped)

**Existing constant** (`lib/mailglass/migrations/postgres.ex:6-7`):
```elixir
@initial_version 1
@current_version 1
```

**Phase 4 change** (one-line):
```elixir
@current_version 2
```

The dispatcher's `change/3` (lines 73-88) automatically picks up `Mailglass.Migrations.Postgres.V02` via `Module.concat([__MODULE__, "V02"])` — no other code change in this file.

---

### `lib/mailglass/errors/signature_error.ex` (modify — extend `@types` 4 → 7)

**Analog:** `lib/mailglass/errors/signature_error.ex` (mailglass shipped — closed atom set + `format_message/2` clause-per-atom convention)

**Existing closed-set extension shape** (`lib/mailglass/errors/signature_error.ex:25-90`):
```elixir
@behaviour Mailglass.Error

@types [:missing, :malformed, :mismatch, :timestamp_skew]

@derive {Jason.Encoder, only: [:type, :message, :context]}
defexception [:type, :message, :cause, :context, :provider]

@type t :: %__MODULE__{
        type: :missing | :malformed | :mismatch | :timestamp_skew,
        message: String.t(),
        cause: Exception.t() | nil,
        context: %{atom() => term()},
        provider: atom() | nil
      }

@doc "Returns the closed set of valid `:type` atoms. Tested against `docs/api_stability.md`."
@doc since: "0.1.0"
@spec __types__() :: [atom()]
def __types__, do: @types

# ...

@doc since: "0.1.0"
@spec new(atom(), keyword()) :: t()
def new(type, opts \\ []) when type in @types do
  ctx = opts[:context] || %{}

  %__MODULE__{
    type: type,
    message: format_message(type, ctx),
    cause: opts[:cause],
    context: ctx,
    provider: opts[:provider]
  }
end

defp format_message(:missing, _ctx),
  do: "Webhook signature verification failed: signature header is missing"

defp format_message(:malformed, _ctx),
  do: "Webhook signature verification failed: signature is malformed"

defp format_message(:mismatch, _ctx),
  do: "Webhook signature verification failed: signature does not match"

defp format_message(:timestamp_skew, _ctx),
  do: "Webhook signature verification failed: timestamp is outside acceptable window"
```

**Phase 4 extension** (CONTEXT D-21 — atom set 4 → 7):

```elixir
@types [
  :missing_header,        # was :missing — RENAME (CONTEXT D-21 reads `:missing_header`)
  :malformed_header,      # was :malformed — RENAME
  :bad_credentials,       # NEW — Postmark Basic Auth secure_compare false
  :ip_disallowed,         # NEW — Postmark IP allowlist (opt-in) mismatch
  :bad_signature,         # was :mismatch — RENAME (collapses :tampered_body)
  :timestamp_skew,        # unchanged
  :malformed_key          # NEW — PEM/DER decode at config validate-at-boot
]
```

⚠️ **Two name renames** (`:missing → :missing_header`, `:malformed → :malformed_header`, `:mismatch → :bad_signature`) — verify with planner whether existing call sites in mailglass need migration. Phase 1 + 2 + 3 likely use `:missing`/`:malformed`/`:mismatch` — these are not yet wired into shipped raise sites in mailglass code (no Phase 1-3 webhook code exists), so rename is internally safe. Add three new `format_message/2` clauses with brand-voice messages per CONTEXT canonical_refs line 291 ("Mailglass webhook verification key missing: configure :webhook_verification_key in your :mailglass config" — note that key-missing belongs on `%ConfigError{}`, not `%SignatureError{}`).

Identical 5-line additive pattern for `tenancy_error.ex` (`:unstamped` → `[:unstamped, :webhook_tenant_unresolved]`) and `config_error.ex` (add `:webhook_verification_key_missing` to existing 7-atom set per `lib/mailglass/errors/config_error.ex:30`).

---

### `lib/mailglass/tenancy.ex` (modify — additive @optional_callbacks)

**Analog:** `lib/mailglass/tenancy.ex:42-52` (mailglass shipped — already has one optional callback `tracking_host: 1`)

**Existing optional-callback pattern** (`lib/mailglass/tenancy.ex:42-52`):
```elixir
@optional_callbacks tracking_host: 1

@doc """
Optional: return a per-tenant tracking host override (D-32).

Default adopter resolution: `:default` (use the global
`config :mailglass, :tracking, host:` value). Adopters returning
`{:ok, host}` get per-tenant subdomains (`track.tenant-a.example.com`)
for strict cookie/origin isolation.
"""
@callback tracking_host(context :: term()) :: {:ok, String.t()} | :default
```

**Phase 4 extension per CONTEXT D-12** — additive only, no breaking change for Phase 2 adopters:
```elixir
@optional_callbacks tracking_host: 1, resolve_webhook_tenant: 1

@doc """
Optional: resolve the tenant from a verified webhook context (D-12).

Called by `Mailglass.Webhook.Plug` AFTER `Provider.verify!/3` returns `:ok`
(D-13 — closes the Stripe-Connect chicken-and-egg trap). Adopters returning
`{:ok, tenant_id}` stamp tenant context for the rest of the ingest pipeline.
"""
@callback resolve_webhook_tenant(context :: %{
            provider: atom(),
            conn: Plug.Conn.t(),
            raw_body: binary(),
            headers: [{String.t(), String.t()}],
            path_params: map(),
            verified_payload: map() | nil
          }) :: {:ok, String.t()} | {:error, term()}
```

`Mailglass.Tenancy.SingleTenant` gains a default impl `def resolve_webhook_tenant(_), do: {:ok, "default"}`.

---

## Shared Patterns

### Optional-dep gating (Oban-conditional compile)

**Source:** `lib/mailglass/optional_deps/oban.ex:36, 59` (mailglass shipped pattern)
**Apply to:** `lib/mailglass/webhook/reconciler.ex`, `lib/mailglass/webhook/pruner.ex`

```elixir
@compile {:no_warn_undefined, [Oban, Oban.Worker, Oban.Job]}

# ... earlier code ...

if Code.ensure_loaded?(Oban.Worker) do
  defmodule Mailglass.Webhook.Reconciler do
    use Oban.Worker, queue: :mailglass_reconcile, unique: [period: 60]

    @impl Oban.Worker
    def perform(%Oban.Job{} = job) do
      Mailglass.Oban.TenancyMiddleware.wrap_perform(job, fn ->
        # ... worker body ...
      end)
    end
  end
end
```

The entire `defmodule` is elided when Oban is absent — `mix compile --no-optional-deps --warnings-as-errors` passes cleanly. Callers must check `Code.ensure_loaded?(Mailglass.Webhook.Reconciler)` before referencing.

### Boot-warning for missing optional dep

**Source:** `lib/mailglass/application.ex:42-67` (mailglass shipped — `:persistent_term`-gated single warning)
**Apply to:** `lib/mailglass/application.ex` (extend with `maybe_warn_missing_oban_for_reconciler/0` per CONTEXT D-20)

```elixir
defp maybe_warn_missing_oban do
  configured = Application.get_env(:mailglass, :async_adapter)
  already_warned? = :persistent_term.get({:mailglass, :oban_warning_emitted}, false)

  cond do
    already_warned? ->
      :ok

    configured == :task_supervisor ->
      :ok

    Code.ensure_loaded?(Oban) ->
      :ok

    true ->
      Logger.warning("""
      [mailglass] Oban not loaded; deliver_later/2 will use Task.Supervisor (non-durable).
      Set `config :mailglass, async_adapter: :task_supervisor` to silence this warning,
      or add `{:oban, "~> 2.21"}` to your deps for durable async delivery.
      """)

      :persistent_term.put({:mailglass, :oban_warning_emitted}, true)
      :ok
  end
end
```

**Phase 4 extension:** add a sibling `maybe_warn_missing_oban_for_webhook_reconciler/0` with its own `:persistent_term` key `{:mailglass, :oban_warning_webhook_reconciler}` and the brand-voiced message per CONTEXT D-20 lines 156-160. **Reuse the `:persistent_term` gating idiom verbatim** — the warning fires exactly once per BEAM lifetime regardless of supervisor restart count.

### Repo.transact/1 wrapping Repo.multi/1 for SQLSTATE-translated Multi composition

**Source:** `lib/mailglass/repo.ex:50-55, 106-111` (mailglass shipped) + `lib/mailglass/outbound.ex` (mailglass shipped — Phase 3 D-20 standardizes the composition)
**Apply to:** `lib/mailglass/webhook/ingest.ex`, `lib/mailglass/webhook/reconciler.ex`

```elixir
def transact(fun, opts \\ []) when is_function(fun, 0) and is_list(opts) do
  repo().transact(fun, opts)
rescue
  err in Postgrex.Error ->
    translate_postgrex_error(err, __STACKTRACE__)
end

def multi(multi, opts \\ []) when is_list(opts) do
  repo().transaction(multi, opts)
rescue
  err in Postgrex.Error ->
    translate_postgrex_error(err, __STACKTRACE__)
end
```

**Composition pattern for Phase 4** (per RESEARCH §Pattern 5 line 387):
```elixir
Mailglass.Repo.transact(fn ->
  _ = Mailglass.Repo.query!("SET LOCAL statement_timeout = '2s'", [])
  _ = Mailglass.Repo.query!("SET LOCAL lock_timeout = '500ms'", [])

  case Mailglass.Repo.multi(multi) do
    {:ok, changes} -> {:ok, changes}
    {:error, _step, reason, _changes} -> {:error, reason}
  end
end)
```

`Repo.transact/1` provides SQLSTATE 45A01 translation; `Repo.multi/1` collapses Multi 4-tuple to canonical 2-tuple. Both already shipped — Phase 4 reuses verbatim.

### Post-commit PubSub broadcast

**Source:** `lib/mailglass/outbound/projector.ex:158-178` (mailglass shipped — Phase 3 D-04)
**Apply to:** `lib/mailglass/webhook/plug.ex` (after `ingest_multi/3` returns `{:ok, _}`), `lib/mailglass/webhook/reconciler.ex` (after `:reconciled` event committed)

```elixir
@doc since: "0.1.0"
@spec broadcast_delivery_updated(Delivery.t(), atom(), map()) :: :ok
def broadcast_delivery_updated(
      %Delivery{id: delivery_id, tenant_id: tenant_id},
      event_type,
      meta
    )
    when is_atom(event_type) and is_map(meta) and is_binary(delivery_id) do
  payload = {:delivery_updated, delivery_id, event_type, meta}

  _ = safe_broadcast(Mailglass.PubSub.Topics.events(tenant_id), payload)
  _ = safe_broadcast(Mailglass.PubSub.Topics.events(tenant_id, delivery_id), payload)

  :ok
end
```

**Critical invariant** (Phase 3 D-04 + projector.ex:142-145): PubSub broadcast runs AFTER `Repo.transact/1` returns `{:ok, _}`. Broadcasting INSIDE the transaction couples PubSub availability to DB commit success. `safe_broadcast/2` rescues `ArgumentError`/`RuntimeError` and catches `:exit` per `lib/mailglass/outbound/projector.ex:180-204`. Phase 4 plug calls this once per event-with-matched-delivery in the post-commit batch loop.

### Telemetry span via `:telemetry.span/3` wrapper

**Source:** `lib/mailglass/telemetry.ex:96-104` (mailglass shipped — Phase 1 D-27)
**Apply to:** `lib/mailglass/webhook/telemetry.ex` (every span helper), `lib/mailglass/webhook/plug.ex`, `lib/mailglass/webhook/reconciler.ex`

```elixir
@spec span([atom()], map(), (-> result)) :: result when result: term()
def span(event_prefix, metadata, fun)
    when is_list(event_prefix) and is_map(metadata) and is_function(fun, 0) do
  :telemetry.span(event_prefix, metadata, fn ->
    result = fun.()
    {result, metadata}
  end)
end
```

The `:telemetry.span/3` wrapper auto-detaches handlers that raise (Phase 1 D-27 guarantee). **Never add a parallel try/rescue** — would duplicate or swallow the meta-event operators rely on.

### Closed-atom error struct extension (Mailglass.Error contract)

**Source:** `lib/mailglass/errors/signature_error.ex` + `tenancy_error.ex` + `config_error.ex` (all mailglass shipped — same shape across all 7 error structs in the hierarchy)
**Apply to:** every error-struct modification in Phase 4

```elixir
@behaviour Mailglass.Error
@types [...]
@derive {Jason.Encoder, only: [:type, :message, :context]}
defexception [:type, :message, :cause, :context, ...optional_field]

@spec __types__() :: [atom()]
def __types__, do: @types

@impl Mailglass.Error
def type(%__MODULE__{type: t}), do: t

@impl Mailglass.Error
def retryable?(%__MODULE__{}), do: false  # webhook errors NEVER retryable per engineering DNA

@spec new(atom(), keyword()) :: t()
def new(type, opts \\ []) when type in @types do
  # ...
end

defp format_message(<atom>, ctx), do: "<brand-voiced message>"
```

**Discipline:** Field name stays `:type` across every error in the hierarchy (CONTEXT D-21 explicitly rejects rename to `:reason` for lattice_stripe alignment). Pattern-match by struct + `:type` atom; never by message string. JSON encoding excludes `:cause` (keeps stack traces internal).

### Tenancy.with_tenant/2 wrap during ingest

**Source:** `lib/mailglass/tenancy.ex:101-114` (mailglass shipped — block-form tenant wrap that restores prior on raise)
**Apply to:** `lib/mailglass/webhook/plug.ex` (wrap entire ingest body after `resolve_webhook_tenant/1` succeeds)

```elixir
@spec with_tenant(String.t(), (-> any())) :: any()
def with_tenant(tenant_id, fun) when is_binary(tenant_id) and is_function(fun, 0) do
  prior = Process.get(@process_dict_key)
  put_current(tenant_id)

  try do
    fun.()
  after
    if is_nil(prior) do
      Process.delete(@process_dict_key)
    else
      put_current(prior)
    end
  end
end
```

**Critical for Phase 4:** the request process is reused across requests in BEAM (cowboy/bandit). Without `with_tenant/2` block-scoping, the `put_current/1` from request N leaks into request N+1's tenant context. RESEARCH §Pitfall 7 line 615-630 documents this footgun explicitly.

### Mailglass.Schema for client-side UUIDv7 PK

**Source:** `lib/mailglass/events/event.ex:36` (mailglass shipped — `use Mailglass.Schema`)
**Apply to:** Phase 4 webhook_event schema (CONTEXT discretion bullet — UUIDv7 is project-wide convention)

```elixir
use Mailglass.Schema
```

Generates UUIDv7 client-side via the macro — IDs are populated before insert hits the DB. The `mailglass_webhook_events` table inherits the project-wide PK convention; do NOT use accrue's `gen_random_uuid()` DB default.

---

## No Analog Found

Files with no close match in the codebase or prior-art libs (planner falls back to RESEARCH.md code examples):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `test/support/fixtures/webhooks/postmark/*.json` | test data | static | Verbatim from Postmark webhook docs (no synthesis needed; copy-paste) |
| `test/support/fixtures/webhooks/sendgrid/*.json` | test data | static | Verbatim from Twilio SendGrid webhook docs (copy-paste) |
| `test/mailglass/webhook/router_test.exs` | test (unit) | configuration | Phoenix router macro tests are unusual; no in-repo or prior-art analog. Synthesize from Phoenix.Router conventions + accrue/lattice_stripe absence noted. |
| `test/mailglass/properties/webhook_signature_failure_test.exs` | property test | request-response | Shape mirrors `idempotency_convergence_test.exs` but content (signature bit-flip generators) is novel. RESEARCH §D-27 line 207 gives the property statement. |
| `test/mailglass/properties/webhook_tenant_resolution_test.exs` | property test | request-response | Same — RESEARCH §D-27 line 208 gives the property statement; no shape analog. |
| `guides/webhooks.md` | docs | static | New adopter-facing guide. Synthesize from CONTEXT specs §Specifics + D-25 auto-suppression recipe + D-12 multi-tenant patterns + D-29 timeout runbook. |

---

## Metadata

**Analog search scope:**
- `lib/mailglass/**/*.ex` (all 39 modules)
- `test/mailglass/**/*.exs` (all 38 test files)
- `test/support/**/*.ex` (all 11 test-support files)
- `~/projects/lattice_stripe/lib/lattice_stripe/**/*.ex` (40 modules)
- `~/projects/accrue/accrue/lib/accrue/**/*.ex` (40+ modules)
- `~/projects/sigra/lib/sigra/**/*.ex` (router macro absent — accrue stands in)

**Files scanned:** 22 files read in full or substantially (lattice_stripe webhook trio + accrue webhook quintet + accrue reconciler + 12 mailglass modules)

**Pattern extraction date:** 2026-04-23

**Confidence:** Phase 4 is ~85% composition of Phase 1-3 mailglass primitives + verbatim ports of accrue's two Oban workers + lattice_stripe's plug/body-reader/verify shape. The remaining ~15% (SendGrid ECDSA crypto, append-based reconciliation, multi-provider router macro, tenant-resolution callback) is documented in RESEARCH §Patterns 1-6 + §Code Examples with concrete Elixir.

## PATTERN MAPPING COMPLETE
