# Phase 11: RFC 8058 List-Unsubscribe - Pattern Map

**Mapped:** 2026-04-28
**Files analyzed:** 12
**Analogs found:** 11 / 12

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/mailglass/compliance/unsubscribe.ex` | service | request-response | `lib/mailglass/tracking/token.ex` | exact |
| `lib/mailglass/compliance.ex` | service | transform | `lib/mailglass/compliance.ex` | exact |
| `lib/mailglass/compliance/unsubscribe_controller.ex` | controller | request-response | `lib/mailglass/webhook/plug.ex` + `lib/mailglass/tracking/plug.ex` | role-match |
| `lib/mailglass/router.ex` | route | request-response | `lib/mailglass/webhook/router.ex` + `mailglass_admin/lib/mailglass_admin/router.ex` | role-match |
| `lib/mix/tasks/mailglass.gen.unsubscribe.ex` | config | request-response | `lib/mix/tasks/mailglass.install.ex` + `lib/mix/tasks/mailglass.publish.check.ex` | role-match |
| `credo_checks/require_atomic_unsubscribe_headers.ex` | config | transform | `credo_checks/stream_policy_consistent.ex` | exact |
| `lib/mailglass/lifecycle.ex` | provider | event-driven | no close analog | none |
| `lib/mailglass/config.ex` | config | transform | `lib/mailglass/config.ex` | exact |
| `lib/mailglass/tenancy.ex` | provider | request-response | `lib/mailglass/tenancy.ex` | exact |
| `test/mailglass/compliance/unsubscribe*_test.exs` | test | request-response | `test/mailglass/tracking/token_test.exs` + `test/mailglass/tracking/open_redirect_test.exs` | exact |
| `test/mailglass/properties/unsubscribe*_property_test.exs` | test | event-driven | `test/mailglass/properties/webhook_idempotency_convergence_test.exs` | exact |
| `test/credo_checks/require_atomic_unsubscribe_headers_test.exs` | test | transform | `test/credo_checks/stream_policy_consistent_test.exs` | exact |

## Pattern Assignments

### `lib/mailglass/compliance/unsubscribe.ex`

**Primary analog:** [lib/mailglass/tracking/token.ex](/Users/jon/projects/mailglass/lib/mailglass/tracking/token.ex:1)

**Token sign/verify shape** ([tracking/token.ex:43-71](/Users/jon/projects/mailglass/lib/mailglass/tracking/token.ex:43), [74-117](/Users/jon/projects/mailglass/lib/mailglass/tracking/token.ex:74)):

```elixir
@sign_opts [key_iterations: 1000, key_length: 32, digest: :sha256]

def sign_open(endpoint, delivery_id, tenant_id) do
  Phoenix.Token.sign(endpoint, head_salt!(), {:open, delivery_id, tenant_id}, @sign_opts)
end

def verify_open(endpoint, token) when is_binary(token) do
  iterate_salts(salts(), fn salt ->
    case Phoenix.Token.verify(endpoint, salt, token, verify_opts()) do
      {:ok, {:open, d, t}} when is_binary(d) and is_binary(t) ->
        {:halt, {:ok, %{delivery_id: d, tenant_id: t}}}
      _ ->
        :cont
    end
  end)
end
```

**Resolution/config pattern** ([tracking.ex:101-119](/Users/jon/projects/mailglass/lib/mailglass/tracking.ex:101)):

```elixir
def endpoint do
  Application.get_env(:mailglass, :tracking, [])[:endpoint] ||
    Application.get_env(:mailglass, :adapter_endpoint) ||
    raise Mailglass.ConfigError.new(:tracking_endpoint_missing,
            context: %{hint: "config :mailglass, :tracking, endpoint: MyApp.Endpoint"}
          )
end
```

**Planner constraint**
- Reuse the `Phoenix.Token` facade shape and early-return iteration helper pattern.
- Do not copy the tracking salt model blindly: Phase 11 context requires current endpoint secret plus `previous_secrets`, not salt-list rotation only.
- Keep payload minimal. Requirements lock it to `delivery_id` only.

### `lib/mailglass/compliance.ex`

**Primary analog:** [lib/mailglass/compliance.ex](/Users/jon/projects/mailglass/lib/mailglass/compliance.ex:1)

**Header injection pattern** ([compliance.ex:27-36](/Users/jon/projects/mailglass/lib/mailglass/compliance.ex:27), [107-124](/Users/jon/projects/mailglass/lib/mailglass/compliance.ex:107)):

```elixir
def add_rfc_required_headers(%Swoosh.Email{} = email) do
  email
  |> maybe_add_date()
  |> maybe_add_message_id()
  |> maybe_add_mime_version()
  |> maybe_add_default_mailable_header()
end

defp put_header_if_absent(%Swoosh.Email{} = email, key, value) do
  if has_header?(email, key), do: email, else: put_header(email, key, value)
end
```

**Message-aware wrapper pattern** ([compliance.ex:61-75](/Users/jon/projects/mailglass/lib/mailglass/compliance.ex:61)):

```elixir
@spec maybe_add_feedback_id(Mailglass.Message.t()) :: Mailglass.Message.t()
def maybe_add_feedback_id(%Mailglass.Message{} = message) do
  if feedback_id = Application.get_env(:mailglass, :feedback_id) do
    ...
    %{message | swoosh_email: updated_email}
  else
    message
  end
end
```

**Planner constraint**
- `inject_unsubscribe_headers/2` should be the only function that ever sets either unsubscribe header.
- Preserve the existing “never overwrite if already present” helper style unless Phase 11 explicitly needs a hard failure when already set.

### `lib/mailglass/compliance/unsubscribe_controller.ex`

**Primary analogs:** [lib/mailglass/webhook/plug.ex](/Users/jon/projects/mailglass/lib/mailglass/webhook/plug.ex:120), [lib/mailglass/tracking/plug.ex](/Users/jon/projects/mailglass/lib/mailglass/tracking/plug.ex:1)

**Tenant-scoped request handling** ([webhook/plug.ex:124-138](/Users/jon/projects/mailglass/lib/mailglass/webhook/plug.ex:124)):

```elixir
verify_with_telemetry!(provider, raw_body, headers, config)
tenant_id = resolve_tenant!(provider, conn, raw_body, headers)

Tenancy.with_tenant(tenant_id, fn ->
  events =
    provider
    |> provider_module()
    |> apply(:normalize, [raw_body, headers])

  ingest_and_respond(conn, provider, raw_body, events, tenant_id)
end)
```

**Idempotent POST / always-200 response style** ([webhook/plug.ex:277-321](/Users/jon/projects/mailglass/lib/mailglass/webhook/plug.ex:277), [tracking/plug.ex:42-65](/Users/jon/projects/mailglass/lib/mailglass/tracking/plug.ex:42)):

```elixir
case Mailglass.Webhook.Ingest.ingest_multi(provider, raw_body, events) do
  {:ok, %{duplicate: true} = result} ->
    broadcast_post_commit(result)
    conn = send_resp(conn, 200, "")
    ...

  {:ok, result} ->
    broadcast_post_commit(result)
    conn = send_resp(conn, 200, "")
    ...
end
```

**Event append inside tenant context** ([tracking/plug.ex:88-123](/Users/jon/projects/mailglass/lib/mailglass/tracking/plug.ex:88)):

```elixir
Mailglass.Tenancy.with_tenant(tenant_id, fn ->
  result =
    Mailglass.Events.append(%{
      tenant_id: tenant_id,
      delivery_id: delivery_id,
      type: :opened,
      occurred_at: Mailglass.Clock.utc_now(),
      normalized_payload: %{source: :pixel}
    })
  ...
end)
```

**Planner constraint**
- POST must follow the webhook-style “acknowledge success with 200 in both first-write and replay paths”.
- For the durable write path, prefer `Ecto.Multi` + `Events.append_multi/3` over standalone `Events.append/1` because Phase 11 needs lifecycle hook composition in the same transaction.
- The controller belongs in `mailglass` core, not `mailglass_admin`.

### `lib/mailglass/router.ex`

**Primary analogs:** [lib/mailglass/webhook/router.ex](/Users/jon/projects/mailglass/lib/mailglass/webhook/router.ex:75), [mailglass_admin/lib/mailglass_admin/router.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/router.ex:91)

**Simple route-macro pattern** ([webhook/router.ex:89-114](/Users/jon/projects/mailglass/lib/mailglass/webhook/router.ex:89)):

```elixir
defmacro mailglass_webhook_routes(path, opts \\ []) do
  providers = Keyword.get(opts, :providers, @default_providers)
  as = Keyword.get(opts, :as, @default_as)

  Enum.each(providers, fn p ->
    unless p in @valid_providers do
      raise ArgumentError, "..."
    end
  end)

  quote bind_quoted: [path: path, providers: providers, as: as] do
    for provider <- providers do
      post("#{path}/#{provider}", Mailglass.Webhook.Plug, [provider: provider], as: :"#{as}_#{provider}")
    end
  end
end
```

**Option validation pattern** ([mailglass_admin/router.ex:68-89](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/router.ex:68), [155-163](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/router.ex:155)):

```elixir
@opts_schema [...]

defmacro mailglass_admin_routes(path, opts \\ []) do
  opts = validate_opts!(opts)
  ...
end

defp validate_opts!(opts) do
  case NimbleOptions.validate(opts, @opts_schema) do
    {:ok, validated} -> validated
    {:error, %NimbleOptions.ValidationError{message: msg}} ->
      raise ArgumentError, "invalid opts for mailglass_admin_routes/2: " <> msg
  end
end
```

**Planner constraint**
- Match `MailglassAdmin.Router` for the public macro surface and compile-time opt validation.
- Do not read compile env directly in the macro body from a `lib/mailglass/...` module; project lint rules reserve `Application.compile_env*` for `Mailglass.Config` only. If the phase wants compile-time mount-path coupling, route that through `Mailglass.Config` or accept a runtime `path` argument at the macro callsite.
- Add router tests in the same `__routes__/0` reflection style as [test/mailglass/webhook/router_test.exs](/Users/jon/projects/mailglass/test/mailglass/webhook/router_test.exs:1).

### `lib/mix/tasks/mailglass.gen.unsubscribe.ex`

**Primary analogs:** [lib/mix/tasks/mailglass.install.ex](/Users/jon/projects/mailglass/lib/mix/tasks/mailglass.install.ex:29), [lib/mix/tasks/mailglass.publish.check.ex](/Users/jon/projects/mailglass/lib/mix/tasks/mailglass.publish.check.ex:44)

**CLI parsing + fail-loud pattern** ([install.ex:30-69](/Users/jon/projects/mailglass/lib/mix/tasks/mailglass.install.ex:30), [publish.check.ex:71-82](/Users/jon/projects/mailglass/lib/mix/tasks/mailglass.publish.check.ex:71)):

```elixir
{opts, rest, invalid} = OptionParser.parse(argv, strict: [dry_run: :boolean, no_admin: :boolean, force: :boolean])
validate_cli!(rest, invalid)
...
if invalid != [] do
  flags = invalid |> Enum.map(fn {key, _} -> "--#{key}" end) |> Enum.join(", ")
  Mix.raise("Delivery blocked: unknown args #{flags}")
end
```

**Terminal checklist/status print pattern** ([install.ex:71-99](/Users/jon/projects/mailglass/lib/mix/tasks/mailglass.install.ex:71), [publish.check.ex:163-176](/Users/jon/projects/mailglass/lib/mix/tasks/mailglass.publish.check.ex:163)):

```elixir
Mix.shell().info("#{status_label(status)} #{render_path(path)}")

Mix.shell().info("#{status_label(status)} #{label} for #{package}")

defp fail_step(label, message) do
  Mix.shell().info("[conflict] #{label}")
  Mix.shell().error(message)
  exit({:shutdown, 1})
end
```

**Planner constraint**
- Phase 11 explicitly says this task prints instructions and copies zero files. Do not model it after `mailglass.gen.migration`, which writes a file directly.
- Best fit is a read-only checklist task: strict arg parsing, `Mix.shell().info/1` sections, warnings for route collisions, and no mutations.

### `credo_checks/require_atomic_unsubscribe_headers.ex`

**Primary analogs:** [credo_checks/stream_policy_consistent.ex](/Users/jon/projects/mailglass/credo_checks/stream_policy_consistent.ex:1), [credo_checks/no_tracking_on_auth_stream.ex](/Users/jon/projects/mailglass/credo_checks/no_tracking_on_auth_stream.ex:29), [.credo.exs](/Users/jon/projects/mailglass/.credo.exs:1)

**Check module skeleton** ([stream_policy_consistent.ex:1-33](/Users/jon/projects/mailglass/credo_checks/stream_policy_consistent.ex:1)):

```elixir
defmodule Mailglass.Credo.StreamPolicyConsistent do
  use Credo.Check,
    category: :warning,
    base_priority: :high,
    param_defaults: [...],
    explanations: [...]

  def run(%SourceFile{} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    ast = SourceFile.ast(source_file)
    {_ast, issues} = Macro.traverse(ast, [], &prewalk(&1, &2, issue_meta, mailable_tail), fn ast, state -> {ast, state} end)
    Enum.reverse(issues)
  end
end
```

**Stateful AST traversal pattern** ([no_tracking_on_auth_stream.ex:39-47](/Users/jon/projects/mailglass/credo_checks/no_tracking_on_auth_stream.ex:39), [50-95](/Users/jon/projects/mailglass/credo_checks/no_tracking_on_auth_stream.ex:50)):

```elixir
{_ast, state} =
  Macro.traverse(ast, %{issues: [], module_stack: []}, &prewalk(&1, &2, issue_meta, heuristics, mailable_tail), &postwalk/2)
```

**Credo registration pattern** ([.credo.exs:53-57](/Users/jon/projects/mailglass/.credo.exs:53), [.credo.exs:71-75](/Users/jon/projects/mailglass/.credo.exs:71)):

```elixir
{Mailglass.Credo.NoTrackingOnAuthStream, [...]}
...
requires: ["./credo_checks/*.ex"],
checks: extra_checks ++ [...]
```

**Planner constraint**
- Put the new check under `credo_checks/`, not `lib/`.
- Add a focused `Credo.Test.Case` file under `test/credo_checks/`, mirroring [test/credo_checks/stream_policy_consistent_test.exs](/Users/jon/projects/mailglass/test/credo_checks/stream_policy_consistent_test.exs:1).
- The check should flag raw `Swoosh.Email.header/3` or `Mailglass.Message.header/3` calls for `"List-Unsubscribe"` / `"List-Unsubscribe-Post"` outside the atomic helper.

### `lib/mailglass/lifecycle.ex`

**No close analog found**

**Closest transaction-composition analogs:** [lib/mailglass/adapters/fake.ex:174-193](/Users/jon/projects/mailglass/lib/mailglass/adapters/fake.ex:174), [lib/mailglass/webhook/reconciler.ex:201-224](/Users/jon/projects/mailglass/lib/mailglass/webhook/reconciler.ex:201)

```elixir
multi =
  Ecto.Multi.new()
  |> Mailglass.Events.append_multi(:event, attrs)
  |> Ecto.Multi.update(:delivery, fn %{event: event} ->
    Projector.update_projections(delivery, event)
  end)
  |> Mailglass.Repo.multi()
```

```elixir
multi =
  Multi.new()
  |> Events.append_multi(:reconciled_event, reconciled_attrs)
  |> Multi.update(:projection, fn _changes ->
    Projector.update_projections(delivery, orphan)
  end)
```

**Planner constraint**
- There is no existing behaviour module that takes an `Ecto.Multi` and returns an enriched `Ecto.Multi`.
- The planner should treat this as a new seam but reuse existing `Multi` composition style: append event first, then domain mutation/projector/lifecycle steps, then post-commit broadcast outside the transaction.

### `lib/mailglass/config.ex` and `lib/mailglass/tenancy.ex`

**Primary analogs:** [lib/mailglass/config.ex](/Users/jon/projects/mailglass/lib/mailglass/config.ex:4), [lib/mailglass/tenancy.ex](/Users/jon/projects/mailglass/lib/mailglass/tenancy.ex:40)

**NimbleOptions schema pattern** ([config.ex:4-18](/Users/jon/projects/mailglass/lib/mailglass/config.ex:4), [115-145](/Users/jon/projects/mailglass/lib/mailglass/config.ex:115)):

```elixir
@schema [
  tracking: [
    type: :keyword_list,
    default: [],
    keys: [
      host: [type: {:or, [:string, nil]}, default: nil],
      scheme: [type: {:in, ["http", "https"]}, default: "https"],
      salts: [type: {:list, :string}, default: []],
      max_age: [type: :pos_integer, default: 2 * 365 * 86_400]
    ]
  ]
]
```

**Optional callback pattern** ([tenancy.ex:42-52](/Users/jon/projects/mailglass/lib/mailglass/tenancy.ex:42), [104-113](/Users/jon/projects/mailglass/lib/mailglass/tenancy.ex:104)):

```elixir
@optional_callbacks tracking_host: 1, resolve_webhook_tenant: 1

@callback tracking_host(context :: term()) :: {:ok, String.t()} | :default
@callback resolve_webhook_tenant(context :: %{...}) :: {:ok, String.t()} | {:error, term()}
```

**Planner constraint**
- `:compliance` config should be added to `Mailglass.Config` in the same nested NimbleOptions style as `:tracking`, `:postmark`, and `:sendgrid`.
- `compliance_host/1` should be added to `Mailglass.Tenancy` the same way `tracking_host/1` was: optional callback plus a resolver fallback.

### Test layout

**Primary analogs:** [test/mailglass/tracking/token_test.exs](/Users/jon/projects/mailglass/test/mailglass/tracking/token_test.exs:1), [test/mailglass/tracking/open_redirect_test.exs](/Users/jon/projects/mailglass/test/mailglass/tracking/open_redirect_test.exs:1), [test/mailglass/properties/webhook_idempotency_convergence_test.exs](/Users/jon/projects/mailglass/test/mailglass/properties/webhook_idempotency_convergence_test.exs:1), [test/mailglass/webhook/router_test.exs](/Users/jon/projects/mailglass/test/mailglass/webhook/router_test.exs:1)

**Per-module config restore pattern** ([token_test.exs:9-27](/Users/jon/projects/mailglass/test/mailglass/tracking/token_test.exs:9)):

```elixir
setup do
  original = Application.get_env(:mailglass, :tracking)
  Application.put_env(:mailglass, :tracking, ...)

  on_exit(fn ->
    if original do
      Application.put_env(:mailglass, :tracking, original)
    else
      Application.delete_env(:mailglass, :tracking)
    end
  end)

  :ok
end
```

**Property-test structure** ([webhook_idempotency_convergence_test.exs:37-47](/Users/jon/projects/mailglass/test/mailglass/properties/webhook_idempotency_convergence_test.exs:37), [94-147](/Users/jon/projects/mailglass/test/mailglass/properties/webhook_idempotency_convergence_test.exs:94)):

```elixir
use ExUnit.Case, async: false
use ExUnitProperties

@moduletag :property
@moduletag timeout: :infinity

property "..." do
  check all(..., max_runs: 1000) do
    ...
  end
end
```

**Open-redirect property shape** ([open_redirect_test.exs:31-79](/Users/jon/projects/mailglass/test/mailglass/tracking/open_redirect_test.exs:31)):

```elixir
property "verify_click never returns target_url with scheme outside [http, https]" do
  check all(...) do
    token = Token.sign_click(...)
    {:ok, %{target_url: decoded}} = Token.verify_click(@endpoint, token)
    assert URI.parse(decoded).scheme in ["http", "https"]
  end
end
```

**Router macro test shape** ([webhook/router_test.exs:16-38](/Users/jon/projects/mailglass/test/mailglass/webhook/router_test.exs:16), [87-109](/Users/jon/projects/mailglass/test/mailglass/webhook/router_test.exs:87)):

```elixir
routes = DefaultRouter.__routes__()
assert route.path == "/webhooks/postmark"
...
assert_raise ArgumentError, ~r/unknown provider/, fn ->
  Code.compile_string(...)
end
```

## Shared Patterns

### Token security
**Sources:** [lib/mailglass/tracking/token.ex](/Users/jon/projects/mailglass/lib/mailglass/tracking/token.ex:39), [test/mailglass/tracking/open_redirect_test.exs](/Users/jon/projects/mailglass/test/mailglass/tracking/open_redirect_test.exs:67)

- Sign opaque tokens with `Phoenix.Token`.
- Verify via bounded fallback iteration with early return.
- Keep security properties structural: token contains the authoritative payload; tampering fails HMAC, not a post-hoc string check.

### Append-event-first transaction composition
**Sources:** [lib/mailglass/events.ex](/Users/jon/projects/mailglass/lib/mailglass/events.ex:105), [lib/mailglass/webhook/ingest.ex](/Users/jon/projects/mailglass/lib/mailglass/webhook/ingest.ex:229), [lib/mailglass/adapters/fake.ex](/Users/jon/projects/mailglass/lib/mailglass/adapters/fake.ex:174)

- Use `Events.append_multi/3` as the ledger write surface inside `Ecto.Multi`.
- Compose follow-up projector/lifecycle steps after the event append step.
- Keep broadcasts outside the transaction.

### Phoenix router macro style
**Sources:** [lib/mailglass/webhook/router.ex](/Users/jon/projects/mailglass/lib/mailglass/webhook/router.ex:89), [mailglass_admin/lib/mailglass_admin/router.ex](/Users/jon/projects/mailglass/mailglass_admin/lib/mailglass_admin/router.ex:112)

- Public macro with compile-time option validation.
- `quote bind_quoted:` style.
- Test via `__routes__/0` reflection and compile-time failure assertions.

### Config resolution
**Sources:** [lib/mailglass/config.ex](/Users/jon/projects/mailglass/lib/mailglass/config.ex:4), [lib/mailglass/tracking.ex](/Users/jon/projects/mailglass/lib/mailglass/tracking.ex:101), [lib/mailglass/tenancy.ex](/Users/jon/projects/mailglass/lib/mailglass/tenancy.ex:42)

- Schema lives in `Mailglass.Config`.
- Operational readers outside `Mailglass.Config` use narrow facades like `Tracking.endpoint/0`.
- Tenancy-specific host override belongs on `Mailglass.Tenancy` as an optional callback.

### Custom Credo wiring
**Sources:** [credo_checks/stream_policy_consistent.ex](/Users/jon/projects/mailglass/credo_checks/stream_policy_consistent.ex:1), [.credo.exs](/Users/jon/projects/mailglass/.credo.exs:1)

- Checks live under `credo_checks/`.
- `.credo.exs` loads them with `requires: ["./credo_checks/*.ex"]`.
- Tests live under `test/credo_checks/` and use `Credo.Test.Case`.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/mailglass/lifecycle.ex` | provider | event-driven | No existing behaviour passes an `Ecto.Multi` through an adopter callback before commit. Planner should synthesize this seam from the existing event-first `Multi` composition patterns. |

## Planner-Critical Constraints

- `mix mailglass.gen.unsubscribe` must not mutate adopter files. The closest task analogs here are CLI printers, not `mailglass.gen.migration`.
- Do not introduce `Application.compile_env*` directly in a new `lib/mailglass/...` router macro. The repo’s lint contract reserves compile-time env reads for `Mailglass.Config`.
- The durable unsubscribe write path should use `Events.append_multi/3` with an idempotency key derived from the token or a stable token hash, not just `delivery_id`.
- Post-commit fan-out stays non-durable and best-effort, matching `Projector.broadcast_delivery_updated/3`.
- Tenant-aware URL generation should mirror tracking’s endpoint/host resolution plus `Mailglass.Tenancy` optional override style.
- Property tests in this repo are deliberately `async: false`, restore app env in `on_exit`, and use explicit DB cleanup when they need convergence loops.

## Metadata

**Analog search scope:** `lib/`, `mailglass_admin/lib/`, `credo_checks/`, `test/`
**Files scanned:** 24
**Pattern extraction date:** 2026-04-28
