# Phase 25: deliverability-doctor - Pattern Map

**Mapped:** 2026-05-01
**Files analyzed:** 21
**Analogs found:** 21 / 21

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mix/tasks/mail.doctor.ex` | controller | request-response | `lib/mix/tasks/mailglass.suppressions.resync.ex` | exact |
| `lib/mailglass/deliverability.ex` | service | request-response | `lib/mailglass/suppression/resync.ex` | role-match |
| `lib/mailglass/deliverability/resolver.ex` | service | request-response | `lib/mailglass/webhook/provider.ex` | role-match |
| `lib/mailglass/deliverability/result.ex` | utility | transform | `lib/mailglass/error.ex` | partial |
| `lib/mailglass/deliverability/spf.ex` | service | transform | `lib/mailglass/webhook/providers/postmark.ex` | role-match |
| `lib/mailglass/deliverability/dkim.ex` | service | transform | `lib/mailglass/webhook/providers/postmark.ex` | role-match |
| `lib/mailglass/deliverability/dmarc.ex` | service | transform | `lib/mailglass/webhook/providers/postmark.ex` | role-match |
| `lib/mailglass/deliverability/mx.ex` | service | transform | `lib/mailglass/webhook/providers/postmark.ex` | role-match |
| `lib/mailglass/deliverability/bimi.ex` | service | transform | `lib/mailglass/webhook/providers/postmark.ex` | role-match |
| `lib/mailglass/deliverability/formatter.ex` | utility | transform | `lib/mix/tasks/mailglass.gen.unsubscribe.ex` | partial |
| `test/mix/tasks/mail_doctor_task_test.exs` | test | request-response | `test/mix/tasks/mailglass.gen.unsubscribe_test.exs` | role-match |
| `test/mailglass/deliverability/result_test.exs` | test | transform | `test/mailglass/error_test.exs` | role-match |
| `test/mailglass/deliverability/spf_test.exs` | test | transform | `test/mix/tasks/mailglass.suppressions.resync_test.exs` | partial |
| `test/mailglass/deliverability/dkim_test.exs` | test | transform | `test/mix/tasks/mailglass.suppressions.resync_test.exs` | partial |
| `test/mailglass/deliverability/dmarc_test.exs` | test | transform | `test/mix/tasks/mailglass.suppressions.resync_test.exs` | partial |
| `test/mailglass/deliverability/mx_test.exs` | test | transform | `test/mix/tasks/mailglass.suppressions.resync_test.exs` | partial |
| `test/mailglass/deliverability/bimi_test.exs` | test | transform | `test/mix/tasks/mailglass.suppressions.resync_test.exs` | partial |
| `test/mailglass/deliverability/formatter_test.exs` | test | transform | `test/mix/tasks/mailglass.gen.unsubscribe_test.exs` | role-match |
| `test/mailglass/properties/deliverability_status_property_test.exs` | test | transform | `test/mailglass/properties/unsubscribe_property_test.exs` | role-match |
| `test/mailglass/properties/deliverability_spf_property_test.exs` | test | transform | `test/mailglass/properties/unsubscribe_property_test.exs` | role-match |
| `test/support/deliverability_resolver_stub.ex` | utility | request-response | `test/support/citext_probe.ex` | partial |

## Pattern Assignments

### `lib/mix/tasks/mail.doctor.ex` (controller, request-response)

**Primary analog:** `lib/mix/tasks/mailglass.suppressions.resync.ex`

**Use this import/alias shape** (`lib/mix/tasks/mailglass.suppressions.resync.ex:1-6`):
```elixir
defmodule Mix.Tasks.Mailglass.Suppressions.Resync do
  use Boundary, classify_to: Mailglass

  use Mix.Task

  alias Mailglass.Suppression.Resync
```

**Copy the strict `OptionParser.parse/2` + thin-wrapper flow** (`lib/mix/tasks/mailglass.suppressions.resync.ex:18-57`):
```elixir
@impl Mix.Task
def run(argv) do
  {opts, rest, invalid} =
    OptionParser.parse(argv,
      strict: [
        tenant_id: :string,
        dry_run: :boolean,
        verbose: :boolean,
        from: :string,
        to: :string
      ]
    )

  validate_cli!(opts, rest, invalid)
  Mix.Task.run("app.start")

  case Resync.run(service_opts(opts)) do
    {:ok, result} ->
      Mix.shell().info(summary_line(result))

      if opts[:verbose] do
        Enum.each(result.candidates, fn candidate ->
          Mix.shell().info(verbose_line(candidate))
        end)
      end

    {:error, :tenant_id_required} ->
      Mix.raise("Suppression resync blocked: --tenant-id is required")

    {:error, {:invalid_datetime, field, value}} ->
      Mix.raise("Suppression resync blocked: --#{field} must be ISO-8601, got #{inspect(value)}")

    {:error, {:invalid_window, from, to}} ->
      Mix.raise(
        "Suppression resync blocked: --from must be before or equal to --to (#{from} > #{to})"
      )

    {:error, reason} ->
      Mix.raise("Suppression resync failed: #{inspect(reason)}")
  end
end
```

**Copy the CLI rejection pattern exactly** (`lib/mix/tasks/mailglass.suppressions.resync.ex:60-80`):
```elixir
defp validate_cli!(opts, rest, invalid) do
  if rest != [] do
    Mix.raise(
      "Suppression resync blocked: unexpected positional arguments #{Enum.join(rest, " ")}"
    )
  end

  if invalid != [] do
    invalid_flags =
      invalid
      |> Enum.map(fn {key, _value} -> "--#{key}" end)
      |> Enum.join(", ")

    Mix.raise("Suppression resync blocked: unknown option(s) #{invalid_flags}")
  end

  unless is_binary(opts[:tenant_id]) and opts[:tenant_id] != "" do
    Mix.raise("Suppression resync blocked: --tenant-id is required")
  end

  :ok
end
```

**Secondary analog for human-first multi-section output:** `lib/mix/tasks/mailglass.gen.unsubscribe.ex`

**Copy the assembled text-section pattern for default human output** (`lib/mix/tasks/mailglass.gen.unsubscribe.ex:25-36`):
```elixir
output =
  [
    heading(),
    config_section(),
    router_section(),
    preflight_section(),
    uat_section(),
    dkim_section()
  ]
  |> Enum.join("\n\n")

Mix.shell().info(output)
```

Planner note: `mail.doctor` should follow the `Suppressions.Resync` task for argv parsing and runtime delegation, and follow `Gen.Unsubscribe` only for grouped operator-facing text assembly.

---

### `lib/mailglass/deliverability.ex` (service, request-response)

**Analog:** `lib/mailglass/suppression/resync.ex`

**Copy the top-of-file alias + typed result posture** (`lib/mailglass/suppression/resync.ex:1-28`):
```elixir
defmodule Mailglass.Suppression.Resync do
  @moduledoc """
  Tenant-scoped suppression rebuild from the append-only event ledger.
  """

  import Ecto.Query

  alias Mailglass.{Clock, Repo, Tenancy}
  alias Mailglass.Events.Event
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Suppression.AutoSuppress
  alias Mailglass.Suppression.Entry

  @default_window_days 90

  @type result :: %{
          scanned: non_neg_integer(),
          would_insert: non_neg_integer(),
          inserted: non_neg_integer(),
          existing: non_neg_integer(),
          dry_run: boolean(),
          tenant_id: String.t(),
          from: DateTime.t(),
          to: DateTime.t(),
          candidates: [map()]
        }

  @spec run(keyword()) :: {:ok, result()} | {:error, term()}
```

**Copy the `with`-driven orchestration pattern** (`lib/mailglass/suppression/resync.ex:29-49`):
```elixir
def run(opts) when is_list(opts) do
  with {:ok, tenant_id} <- fetch_tenant_id(opts),
       {:ok, window} <- parse_window(opts),
       candidates <- select_candidates(tenant_id, window),
       {:ok, inserted} <- maybe_apply(candidates, Keyword.get(opts, :dry_run, false)) do
    would_insert = count_status(candidates, :missing)
    existing = count_status(candidates, :existing)

    {:ok,
     %{
       scanned: length(candidates),
       would_insert: would_insert,
       inserted: inserted,
       existing: existing,
       dry_run: Keyword.get(opts, :dry_run, false),
       tenant_id: tenant_id,
       from: window.from,
       to: window.to,
       candidates: Enum.map(candidates, &candidate_summary/1)
     }}
  end
end
```

**Copy the validate-then-normalize helper style** (`lib/mailglass/suppression/resync.ex:52-84`):
```elixir
defp fetch_tenant_id(opts) do
  case Keyword.get(opts, :tenant_id) do
    tenant_id when is_binary(tenant_id) and tenant_id != "" -> {:ok, tenant_id}
    _ -> {:error, :tenant_id_required}
  end
end

defp parse_window(opts) do
  now = Clock.utc_now()
  default_from = DateTime.add(now, -@default_window_days, :day)

  with {:ok, from} <- parse_datetime(Keyword.get(opts, :from, default_from), :from),
       {:ok, to} <- parse_datetime(Keyword.get(opts, :to, now), :to),
       :ok <- validate_window(from, to) do
    {:ok, %{from: from, to: to}}
  end
end
```

Planner note: `Mailglass.Deliverability.run/1` should be the only orchestrator entrypoint in the runtime tree, mirroring `Resync.run/1`, but it must stay pure and persistence-free.

---

### `lib/mailglass/deliverability/resolver.ex` (service, request-response)

**Primary analog:** `lib/mailglass/webhook/provider.ex`

**Copy the behaviour-first seam** (`lib/mailglass/webhook/provider.ex:14-48`):
```elixir
@doc """
Verify a webhook request's authenticity. Receives a 3-tuple of
(raw_body, headers, config) — NOT a `%Plug.Conn{}` — per CONTEXT D-02
so the contract is portable to v0.5 inbound + SES SQS polling contexts.
"""
@callback verify!(
            raw_body :: binary(),
            headers :: [{String.t(), String.t()}],
            config :: map()
          ) :: :ok | {:ok, :replay}

@doc """
Normalize a verified webhook body into a list of `%Mailglass.Events.Event{}`
structs in the Anymail taxonomy verbatim (PROJECT D-14 + amendment).
"""
@callback normalize(
            raw_body :: binary(),
            headers :: [{String.t(), String.t()}]
          ) :: [Mailglass.Events.Event.t()]
```

**Secondary analog:** `lib/mailglass/webhook/providers/postmark.ex`

**Copy the native-OTP helper style and normalization boundary** (`lib/mailglass/webhook/providers/postmark.ex:25-46`):
```elixir
@behaviour Mailglass.Webhook.Provider

import Bitwise

require Logger

alias Mailglass.{ConfigError, SignatureError}
alias Mailglass.Events.Event

@impl Mailglass.Webhook.Provider
@spec verify!(binary(), [{String.t(), String.t()}], map()) :: :ok
def verify!(_raw_body, headers, %{} = config) when is_list(headers) do
  {user, pass} = fetch_basic_auth!(config)
  verify_basic_auth!(headers, user, pass)
  verify_ip_allowlist!(config)
  :ok
end
```

**Copy the no-new-dependency Erlang helper pattern** (`lib/mailglass/webhook/providers/postmark.ex:122-152`):
```elixir
defp cidr_match?(remote_ip, cidr) do
  case String.split(cidr, "/", parts: 2) do
    [single] ->
      case :inet.parse_address(String.to_charlist(single)) do
        {:ok, parsed} -> remote_ip == parsed
        _ -> false
      end

    [base, mask] ->
      with {:ok, base_ip} <- :inet.parse_address(String.to_charlist(base)),
           {mask_int, ""} <- Integer.parse(mask),
           true <- ip_in_cidr?(remote_ip, base_ip, mask_int) do
        true
      else
        _ -> false
      end
  end
end
```

Planner note: `resolver.ex` should define a behaviour plus OTP-backed adapter in the same house style as webhook providers, but the public contract must return normalized DNS facts and transient resolver errors, not raise task-facing exceptions.

---

### `lib/mailglass/deliverability/result.ex` (utility, transform)

**Primary analog:** `lib/mailglass/error.ex`

**Copy the closed-contract documentation style** (`lib/mailglass/error.ex:21-37`):
```elixir
## Pattern Matching

Always match on the struct module and `:type` field — never on `:message`.
Message strings are a presentation concern; the closed `:type` atom set is
the stable contract:

## Serialization

Every error struct derives `Jason.Encoder` on `[:type, :message, :context]`
only. The `:cause` field is deliberately excluded to prevent recursive
emission of adapter structs that may carry provider payloads with PII.
```

**Copy the helper-module contract shape** (`lib/mailglass/error.ex:47-63`):
```elixir
@type t ::
        Mailglass.SendError.t()
        | Mailglass.TemplateError.t()
        | Mailglass.SignatureError.t()
        | Mailglass.SuppressedError.t()
        | Mailglass.RateLimitError.t()
        | Mailglass.ConfigError.t()
        | Mailglass.EventLedgerImmutableError.t()
        | Mailglass.TenancyError.t()
        | Mailglass.StreamPolicyError.t()
        | Mailglass.PublishError.t()

@doc "Returns the error's closed `:type` atom."
@callback type(t()) :: atom()
```

**Secondary analog:** `lib/mailglass/errors/config_error.ex`

**Copy the explicit constructor + JSON-safe shape** (`lib/mailglass/errors/config_error.ex:50-104`):
```elixir
@derive {Jason.Encoder, only: [:type, :message, :context]}
defexception [:type, :message, :cause, :context]

@doc since: "0.1.0"
@spec new(atom(), keyword()) :: t()
def new(type, opts \\ []) when type in @types do
  ctx = opts[:context] || %{}

  %__MODULE__{
    type: type,
    message: format_message(type, ctx),
    cause: opts[:cause],
    context: ctx
  }
end
```

Planner note: `result.ex` should not become an exception module, but it should copy the same closed-status discipline, JSON-safe surface, and small helper-constructor approach.

---

### `lib/mailglass/deliverability/spf.ex`, `dkim.ex`, `dmarc.ex`, `mx.ex`, `bimi.ex` (service, transform)

**Primary analog:** `lib/mailglass/webhook/providers/postmark.ex`

**Copy the protocol-module layout** (`lib/mailglass/webhook/providers/postmark.ex:25-33`):
```elixir
@behaviour Mailglass.Webhook.Provider

import Bitwise

require Logger

alias Mailglass.{ConfigError, SignatureError}
alias Mailglass.Events.Event
```

**Copy the pure transform entrypoint pattern** (`lib/mailglass/webhook/providers/postmark.ex:156-170`):
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

**Copy the small private helpers + exhaustive branching style** (`lib/mailglass/webhook/providers/postmark.ex:173-220`):
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

defp map_record_type(%{"RecordType" => "Delivery"}), do: {:delivered, nil}
defp map_record_type(%{"RecordType" => "Bounce", "TypeCode" => 1}), do: {:bounced, :bounced}
```

Planner note: each analyzer should stay pure, accept normalized DNS facts plus options, and emit result-model findings rather than task strings. `dkim.ex` is the one analyzer that should also borrow the explicit uncertainty posture from the context: selector absence maps to `cannot_verify`, not guessed failure.

---

### `lib/mailglass/deliverability/formatter.ex` (utility, transform)

**Primary analog:** `lib/mix/tasks/mailglass.gen.unsubscribe.ex`

**Copy the section-assembly pattern** (`lib/mix/tasks/mailglass.gen.unsubscribe.ex:25-36`):
```elixir
output =
  [
    heading(),
    config_section(),
    router_section(),
    preflight_section(),
    uat_section(),
    dkim_section()
  ]
  |> Enum.join("\n\n")
```

**Copy the concise per-section helper style** (`lib/mix/tasks/mailglass.gen.unsubscribe.ex:39-119`):
```elixir
defp heading do
  """
  Mailglass unsubscribe checklist

  This task intentionally copies zero files. Wire the config and router manually, then run the UAT steps below.
  """
end

defp uat_section do
  route_path = canonical_route_path()

  """
  4. UAT recipe

  - Browser GET check: visit GET #{route_path} with a signed token and confirm the confirmation page renders.
  - One-click POST check: POST #{route_path} with the same token and confirm the endpoint returns 200 without redirecting.
  - Replay POST check: repeat the POST and confirm it stays idempotent.
  - No-copy check: rerun `mix mailglass.gen.unsubscribe` and confirm it still copies zero files.
  """
end
```

**Secondary analog for JSON-safe output constraints:** `lib/mailglass/error.ex:33-37` and `lib/mailglass/errors/config_error.ex:50-51`

```elixir
Every error struct derives `Jason.Encoder` on `[:type, :message, :context]`
only.
```

```elixir
@derive {Jason.Encoder, only: [:type, :message, :context]}
```

Planner note: `formatter.ex` should own both human rendering and JSON rendering. Keep the task itself free of formatting logic beyond dispatching to this module.

---

### `test/mix/tasks/mail_doctor_task_test.exs` (test, request-response)

**Primary analog:** `test/mix/tasks/mailglass.gen.unsubscribe_test.exs`

**Copy the `capture_io` output-contract test shape** (`test/mix/tasks/mailglass.gen.unsubscribe_test.exs:31-58`):
```elixir
test "prints the install checklist without mutating files" do
  output = capture_io(fn -> Mix.Tasks.Mailglass.Gen.Unsubscribe.run([]) end)

  assert output =~ "mix mailglass.gen.unsubscribe"
  assert output =~ "config :mailglass, :compliance"
  assert output =~ "GET /mailglass/unsubscribe/:token"
  assert output =~ "POST /mailglass/unsubscribe/:token"
end

test "rejects unknown options loudly" do
  assert_raise Mix.Error, ~r/unknown option/, fn ->
    Mix.Tasks.Mailglass.Gen.Unsubscribe.run(["--wat"])
  end
end

test "rejects positional arguments loudly" do
  assert_raise Mix.Error, ~r/positional arguments/, fn ->
    Mix.Tasks.Mailglass.Gen.Unsubscribe.run(["extra"])
  end
end
```

**Secondary analog:** `test/mix/tasks/mailglass.suppressions.resync_test.exs`

**Copy the run-twice / output-assert style for CLI success paths** (`test/mix/tasks/mailglass.suppressions.resync_test.exs:94-129`):
```elixir
output =
  capture_io(fn ->
    Mix.Tasks.Mailglass.Suppressions.Resync.run(["--tenant-id", @tenant_id, "--dry-run"])
  end)

assert output =~ "tenant=#{@tenant_id}"
assert output =~ "scanned=1"
assert output =~ "would_insert=1"
assert output =~ "inserted=0"
assert output =~ "existing=0"
```

Planner note: `mail_doctor_task_test.exs` should assert strict flag validation, grouped default output, and JSON output. Keep it as a CLI contract test, not protocol logic coverage.

---

### `test/mailglass/deliverability/result_test.exs` (test, transform)

**Analog:** `test/mailglass/error_test.exs`

**Copy the closed-set assertions** (`test/mailglass/error_test.exs:54-111`):
```elixir
test "__types__/0 returns the closed atom set for ConfigError" do
  assert Mailglass.ConfigError.__types__() ==
           [
             :missing,
             :invalid,
             :conflicting,
             :optional_dep_missing,
             :tracking_on_auth_stream,
             :tracking_host_missing,
             :tracking_endpoint_missing,
             :webhook_verification_key_missing,
             :webhook_caching_body_reader_missing
           ]
end
```

**Copy the JSON-shape assertions** (`test/mailglass/error_test.exs:113-127`):
```elixir
json = Jason.encode!(err)
decoded = Jason.decode!(json)

assert Map.has_key?(decoded, "type")
assert Map.has_key?(decoded, "message")
assert Map.has_key?(decoded, "context")
refute Map.has_key?(decoded, "cause")
```

Planner note: replace `__types__/0` with whatever status helper `result.ex` exposes, but keep the same explicit assertions for allowed statuses and serialized keys.

---

### `test/mailglass/deliverability/spf_test.exs`, `dkim_test.exs`, `dmarc_test.exs`, `mx_test.exs`, `bimi_test.exs` (test, transform)

**Analog:** `test/mix/tasks/mailglass.suppressions.resync_test.exs`

**Copy the local fixture-builder style** (`test/mix/tasks/mailglass.suppressions.resync_test.exs:133-185`):
```elixir
defp insert_delivery!(attrs) do
  attrs
  |> Enum.into(%{
    tenant_id: @tenant_id,
    mailable: "MyApp.Mailers.WelcomeMailer.welcome/1",
    stream: :transactional,
    recipient: "to@example.com",
    provider: "postmark",
    provider_message_id: "msg-#{System.unique_integer([:positive])}",
    last_event_type: :queued,
    last_event_at: Clock.utc_now(),
    status: :sent
  })
  |> Delivery.changeset()
  |> TestRepo.insert!()
end
```

**Copy the single-file example-driven assertion style** (`test/mix/tasks/mailglass.suppressions.resync_test.exs:15-84`):
```elixir
describe "Mailglass.Suppression.Resync.run/1" do
  test "uses one tenant-scoped candidate path for dry-run and apply" do
    ...
    assert {:ok, dry_run} = Resync.run(tenant_id: @tenant_id, dry_run: true)
    assert dry_run.scanned == 3
    assert dry_run.would_insert == 2
    ...
  end

  test "defaults to the last 90 days when no window overrides are given" do
    ...
    assert {:ok, result} = Resync.run(tenant_id: @tenant_id, dry_run: true)
    assert result.scanned == 1
    assert result.would_insert == 1
  end
end
```

Planner note: deliverability analyzer tests should stay pure and resolver-stub-driven. Use helper builders local to each test file unless a shared stub file materially reduces duplication.

---

### `test/mailglass/deliverability/formatter_test.exs` (test, transform)

**Analog:** `test/mix/tasks/mailglass.gen.unsubscribe_test.exs`

**Copy the human-output token assertions** (`test/mix/tasks/mailglass.gen.unsubscribe_test.exs:31-45`):
```elixir
assert output =~ "mix mailglass.gen.unsubscribe"
assert output =~ "config :mailglass, :compliance"
assert output =~ "/mailglass/unsubscribe/:token"
assert output =~ "GET /mailglass/unsubscribe/:token"
assert output =~ "POST /mailglass/unsubscribe/:token"
assert output =~ "DKIM"
```

Planner note: `formatter_test.exs` should assert section grouping (`SPF`, `DKIM`, `DMARC`, `MX`, `BIMI`), concise default output, verbose evidence expansion, and a stable top-level JSON schema key set.

---

### `test/mailglass/properties/deliverability_status_property_test.exs` and `deliverability_spf_property_test.exs` (test, transform)

**Primary analog:** `test/mailglass/properties/unsubscribe_property_test.exs`

**Copy the property-test module setup** (`test/mailglass/properties/unsubscribe_property_test.exs:1-10`):
```elixir
defmodule Mailglass.Properties.UnsubscribePropertyTest do
  use ExUnit.Case, async: false
  use ExUnitProperties

  alias Mailglass.Compliance.Unsubscribe
  alias Mailglass.ConfigError
  alias Mailglass.Message
  alias Mailglass.Tenancy

  @moduletag :property
```

**Copy the `check all` style and bounded run counts** (`test/mailglass/properties/unsubscribe_property_test.exs:59-91`):
```elixir
property "verify_token succeeds across current-secret rotation when legacy secret remains configured" do
  check all(
          delivery_id <- string(:alphanumeric, min_length: 1, max_length: 64),
          legacy_secret <- string(:alphanumeric, min_length: 20, max_length: 48),
          rotated_secret <- string(:alphanumeric, min_length: 20, max_length: 48),
          max_runs: 50
        ) do
    ...
    assert {:ok, %{delivery_id: ^delivery_id}} = Unsubscribe.verify_token(token)
  end
end
```

**Secondary analog:** `test/support/generators.ex`

**Copy the shared generator helper style if needed** (`test/support/generators.ex:20-44`):
```elixir
@doc "Generates `Mailglass.Events.Event.changeset/1`-compatible attr maps."
def event_attrs(opts \\ []) do
  tenant_id = Keyword.get(opts, :tenant_id, "test-tenant")

  gen all(
        type <- member_of(@anymail_event_types),
        occurred_at_offset_sec <- integer(-60..60),
        ...
      ) do
    %{...}
  end
end
```

Planner note: keep property tests focused on combinatorial cases only: status normalization, SPF lookup recursion/void-lookup bounds, and uncertainty classification under transient resolver outcomes.

---

### `test/support/deliverability_resolver_stub.ex` (utility, request-response)

**Primary analog:** `test/support/citext_probe.ex`

**Copy the small support-module shape** (`test/support/citext_probe.ex:24-43`):
```elixir
import Ecto.Query

alias Mailglass.Suppression.Entry
alias Mailglass.SuppressionStore.Ecto, as: SuppressionStore

@spec run(keyword()) :: :ok
def run(opts \\ []) do
  repo = Keyword.get(opts, :repo, Mailglass.TestRepo)

  max_attempts =
    Keyword.get_lazy(opts, :max_attempts, fn ->
      ...
    end)

  do_probe(repo, max_attempts)
end
```

**Secondary analog:** `test/support/mocks.ex`

**Copy the `TestSupport` namespace placement** (`test/support/mocks.ex:1-7`):
```elixir
defmodule Mailglass.Test.Mocks do
  @moduledoc """
  Mox mock declarations live here alongside the `Mox.defmock` calls in
  `test/test_helper.exs`.
  """
end
```

Planner note: the resolver stub is a good candidate for `Mailglass.TestSupport.DeliverabilityResolverStub` rather than a Mox declaration if the tests just need deterministic TXT/MX/CNAME answer maps keyed by domain/query type.

## Shared Patterns

### Strict CLI validation
**Sources:** `lib/mix/tasks/mailglass.suppressions.resync.ex:18-31`, `:60-80`; `lib/mix/tasks/mailglass.gen.unsubscribe.ex:18-23`

Apply to `lib/mix/tasks/mail.doctor.ex`.

```elixir
{opts, rest, invalid} =
  OptionParser.parse(argv,
    strict: [...]
  )

validate_cli!(opts, rest, invalid)
Mix.Task.run("app.start")
```

The repo’s task pattern is explicit flags only, unknown flags rejected, positional args rejected, and core work delegated to a runtime module.

### Closed status and JSON-safe result surface
**Sources:** `lib/mailglass/error.ex:21-37`; `lib/mailglass/errors/config_error.ex:50-104`; `test/mailglass/error_test.exs:94-127`

Apply to `lib/mailglass/deliverability/result.ex`, `formatter.ex`, and `result_test.exs`.

```elixir
@derive {Jason.Encoder, only: [:type, :message, :context]}
defexception [:type, :message, :cause, :context]
```

Use the same discipline for deliverability findings/results: stable status atoms, explicit constructor helpers, and tests that lock serialized keys.

### Behaviour seam over framework-specific or OTP-specific details
**Sources:** `lib/mailglass/webhook/provider.ex:14-48`; `lib/mailglass/webhook/providers/postmark.ex:122-152`

Apply to `lib/mailglass/deliverability/resolver.ex` and all protocol analyzers.

```elixir
@callback ...
```

Keep analyzers ignorant of raw `:inet_res` output shapes. Normalize resolver answers once, then analyze plain data.

### Human output assembled from small section helpers
**Source:** `lib/mix/tasks/mailglass.gen.unsubscribe.ex:25-119`

Apply to `lib/mailglass/deliverability/formatter.ex`.

```elixir
[
  heading(),
  ...,
  dkim_section()
]
|> Enum.join("\n\n")
```

Default output should be grouped, readable, and operator-facing. Verbose evidence should be appended by helper sections rather than mixed into the analyzer logic.

### Property-test shape with bounded generators
**Sources:** `test/mailglass/properties/unsubscribe_property_test.exs:1-10`, `:59-175`; `test/support/generators.ex:20-44`

Apply to `deliverability_status_property_test.exs` and `deliverability_spf_property_test.exs`.

```elixir
use ExUnit.Case, async: false
use ExUnitProperties

check all(..., max_runs: 50) do
  ...
end
```

## No Analog Found

None. All planned files have at least a usable role-match or partial analog in the current codebase.

## Metadata

**Analog search scope:** `lib/mix/tasks`, `lib/mailglass`, `lib/mailglass/webhook`, `test/mix/tasks`, `test/mailglass`, `test/support`
**Files scanned:** 324
**Pattern extraction date:** 2026-05-01
