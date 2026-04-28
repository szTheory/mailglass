# Phase 10: Stream Policy Implementation - Pattern Map

**Mapped:** 2024-04-28
**Files analyzed:** 6
**Analogs found:** 5 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/mailglass/stream.ex` | component | policy check | `lib/mailglass/rate_limiter.ex` | role-match |
| `lib/mailglass/message.ex` | model | struct manipulation | `lib/mailglass/message.ex` | exact |
| `credo_checks/stream_policy_consistent.ex` | utility/lint | AST analysis | `credo_checks/no_tracking_on_auth_stream.ex` | exact |
| `lib/mailglass/compliance.ex` | component | header injection | `lib/mailglass/compliance.ex` | exact |
| `lib/mailglass/errors/stream_policy_error.ex` | utility | struct definition | `lib/mailglass/errors/rate_limit_error.ex` | role-match |
| `test/credo_checks/stream_policy_consistent_test.exs` | test | AST analysis | None | none |

## Pattern Assignments

### `lib/mailglass/stream.ex` (component, policy check)
**Analog:** `lib/mailglass/rate_limiter.ex`

**Core Pattern (Policy Check & Telemetry)** (lines 40-47):
```elixir
  def check(_tenant_id, _domain, :transactional) do
    emit_telemetry(0, true, nil)
    :ok
  end
```

**Error Return Pattern** (lines 89-96):
```elixir
      _ ->
        emit_telemetry(duration_us, false, tenant_id)
        ms = retry_after_ms(refill_per_ms)

        {:error,
         RateLimitError.new(:per_domain,
           retry_after_ms: ms,
           context: %{tenant_id: tenant_id, domain: domain, retry_after_ms: ms}
         )}
```

### `lib/mailglass/message.ex` (model, struct manipulation)
**Analog:** `lib/mailglass/message.ex`

**Core Pattern (`new_from_use/2` stamping)** (lines 90-111):
```elixir
  def new_from_use(mailable, use_opts) when is_atom(mailable) and is_list(use_opts) do
    email = Swoosh.Email.new()

    email =
      case Keyword.get(use_opts, :from_default) do
        nil -> email
        from -> Swoosh.Email.from(email, from)
      end

    stream = Keyword.get(use_opts, :stream, :transactional)

    %__MODULE__{
      swoosh_email: email,
      mailable: mailable,
      tenant_id: Mailglass.Tenancy.current(),
      stream: stream,
      tags: [],
      metadata: %{}
    }
  end
```

### `credo_checks/stream_policy_consistent.ex` (utility/lint, AST analysis)
**Analog:** `credo_checks/no_tracking_on_auth_stream.ex`

**Imports and Setup pattern** (lines 1-19):
```elixir
defmodule Mailglass.Credo.NoTrackingOnAuthStream do
  use Credo.Check,
    category: :warning,
    base_priority: :high,
    param_defaults: [
      # ...
    ],
    explanations: [
      check: """
      Auth-context mailable functions must not enable open/click tracking.
      """,
      params: [
        # ...
      ]
    ]
```

**AST Traversal Pattern** (lines 28-34):
```elixir
    {_ast, state} =
      Macro.traverse(
        ast,
        %{issues: [], module_stack: []},
        &prewalk(&1, &2, issue_meta, heuristics, mailable_tail),
        &postwalk/2
      )
```

**Issue Formatting Pattern** (lines 62-70):
```elixir
      issue =
        format_issue(
          issue_meta,
          message:
            "Auth-context mailable function `#{function_name}` must not enable tracking (`tracking:`).",
          trigger: function_name,
          line_no: meta[:line],
          column: meta[:column]
        )
```

### `lib/mailglass/compliance.ex` (component, header injection)
**Analog:** `lib/mailglass/compliance.ex`

**Header Injection Pattern** (lines 33-39):
```elixir
  def add_rfc_required_headers(%Swoosh.Email{} = email) do
    email
    |> maybe_add_date()
    |> maybe_add_message_id()
    |> maybe_add_mime_version()
    |> maybe_add_default_mailable_header()
  end
```

**Put Header If Absent Pattern** (lines 115-117):
```elixir
  defp put_header_if_absent(%Swoosh.Email{} = email, key, value) do
    if has_header?(email, key), do: email, else: put_header(email, key, value)
  end
```

### `lib/mailglass/errors/stream_policy_error.ex` (utility, struct definition)
**Analog:** `lib/mailglass/errors/rate_limit_error.ex`

**Error Struct Definition Pattern** (lines 21-34):
```elixir
  @behaviour Mailglass.Error

  @types [:per_domain, :per_tenant, :per_stream]

  @derive {Jason.Encoder, only: [:type, :message, :context]}
  defexception [:type, :message, :cause, :context, retry_after_ms: 0]

  @type t :: %__MODULE__{
          type: :per_domain | :per_tenant | :per_stream,
          message: String.t(),
          cause: Exception.t() | nil,
          context: %{atom() => term()},
          retry_after_ms: non_neg_integer()
        }
```

**Error Constructor Pattern** (lines 53-62):
```elixir
  def new(type, opts \\ []) when type in @types do
    ctx = opts[:context] || %{}

    %__MODULE__{
      type: type,
      message: format_message(type, ctx),
      cause: opts[:cause],
      context: ctx,
      retry_after_ms: opts[:retry_after_ms] || 0
    }
  end
```

## Shared Patterns

### Error Handling
**Source:** `lib/mailglass/error.ex`
**Apply to:** All component files validating streams
Error constructors return structured exceptions that implement the `Mailglass.Error` behaviour and define a closed set of `:type` atoms, avoiding stringly-typed matching.

### Telemetry
**Source:** `lib/mailglass/stream.ex` and `lib/mailglass/rate_limiter.ex`
**Apply to:** `lib/mailglass/stream.ex`
Policy checks must emit standard telemetry events `[:mailglass, :outbound, :stream_policy, :stop]` with duration measurements and relevant metadata (tenant, allowed/violation status).

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md patterns instead if applicable):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `test/credo_checks/stream_policy_consistent_test.exs` | test | AST analysis | No existing tests for credo checks were found in the codebase. |

## Metadata

**Analog search scope:** `lib/`, `credo_checks/`, `test/`
**Files scanned:** ~30
**Pattern extraction date:** 2024-04-28
