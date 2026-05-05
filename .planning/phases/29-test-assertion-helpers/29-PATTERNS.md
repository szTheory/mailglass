# Phase 29: Test Assertion Helpers - Pattern Map

**Mapped:** 2024-05-24
**Files analyzed:** 4
**Analogs found:** 4 / 4

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/mailglass/message.ex` | model | transform | `lib/mailglass/message.ex` | exact |
| `lib/mailglass/mailable.ex` | utility | transform | `lib/mailglass/mailable.ex` | exact |
| `lib/mailglass/test_assertions.ex` | utility | request-response | `lib/mailglass/test_assertions.ex` | exact |
| `test/support/webhook_case.ex` | utility | event-driven | `test/support/webhook_case.ex` | exact |

## Pattern Assignments

### `lib/mailglass/message.ex` (model, transform)

**Analog:** `lib/mailglass/message.ex`

**Struct Definition Pattern** (lines 48-57):
```elixir
  defstruct [
    :swoosh_email,
    :mailable,
    :mailable_function,
    :tenant_id,
    stream: :transactional,
    tags: [],
    metadata: %{}
  ]
```
*(Pattern: Define default values for new fields like `assigns: %{}` here to support TEST-01).*

**Constructor Pattern** (lines 98-120):
```elixir
  def new_from_use(mailable, use_opts) when is_atom(mailable) and is_list(use_opts) do
    email = Swoosh.Email.new()
    # ...
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
*(Pattern: Extend `new_from_use` to accept assigns or create a new internal builder to initialize `%Message{assigns: %{}}`.)*

---

### `lib/mailglass/mailable.ex` (utility, transform)

**Analog:** `lib/mailglass/mailable.ex`

**Constructor Injection Pattern** (lines 104-106):
```elixir
      @doc false
      def __mailglass_opts__, do: @mailglass_opts

      def new, do: Mailglass.Message.new_from_use(__MODULE__, @mailglass_opts)
```
*(Pattern: We need to inject `def new(assigns \\ [])` to capture keyword lists or maps directly in the `use Mailglass.Mailable` macro, providing frictionless assignment.)*

---

### `lib/mailglass/test_assertions.ex` (utility, request-response)

**Analog:** `lib/mailglass/test_assertions.ex`

**Assertion Keyword Matcher Pattern** (lines 96-128):
```elixir
  def __match_keyword__(%Message{} = msg, params) when is_list(params) do
    Enum.each(params, fn
      {:subject, v} ->
        assert msg.swoosh_email.subject == v,
               "subject mismatch: expected #{inspect(v)}, got #{inspect(msg.swoosh_email.subject)}"
      # ...
      {:mailable, v} ->
        assert msg.mailable == v,
               "mailable mismatch: expected #{inspect(v)}, got #{inspect(msg.mailable)}"
      # ...
      {key, _} ->
        flunk(
          "Unsupported matcher key: #{inspect(key)}. " <>
            "Supported: :subject, :to, :mailable, :stream, :tenant"
        )
    end)
  end
```
*(Pattern: Add `:assigns`, `:mailable_function`, `:html_body`, and `:text_body` matches to this keyword evaluator to satisfy TEST-01 content matchers).*

---

### `test/support/webhook_case.ex` (utility, event-driven)

**Analog:** `test/support/webhook_case.ex`

**PubSub Assertion Pattern** (lines 201-236):
```elixir
  defmacro assert_webhook_ingested(pattern_or_type \\ nil, timeout \\ 100) do
    quote do
      pattern = unquote(pattern_or_type)
      timeout = unquote(timeout)

      case pattern do
        nil ->
          # Presence check — any broadcast within timeout.
          ExUnit.Assertions.assert_receive(
            {:delivery_updated, _delivery_id, _event_type, _meta},
            timeout,
            "assert_webhook_ingested: no broadcast within #{timeout}ms"
          )
        # ...
      end
    end
  end
```
*(Pattern: The new `assert_webhook_processed` and `assert_webhook_idempotent` helpers should follow this macro structure. They will abstract away the Plug layer (`mailglass_webhook_conn/3`) by dispatching the fixture request and leveraging `assert_receive` for PubSub events, or make DB calls for `assert_delivery_state`).*

## Shared Patterns

### Elixir Ast/Macro matching
**Source:** `lib/mailglass/test_assertions.ex`
**Apply to:** `test_assertions.ex` and `webhook_case.ex` extensions
Macros that extend `assert_mail_sent` or `assert_webhook_ingested` should preserve the `quote do ... end` pattern calling `assert_receive` and binding caller arguments.

### ExUnit.Assertions `flunk` for clear developer feedback
**Source:** `lib/mailglass/test_assertions.ex`
**Apply to:** All test assertion helpers
All custom assertions provide clear failure feedback either using explicit `assert expr, "message"` forms or calling `flunk/1` on unsupported parameters. Error messages should clearly explain mismatch values (e.g. `expected X, got Y`).

## Metadata

**Analog search scope:** `lib/mailglass/**/*.ex`, `test/support/**/*.ex`
**Files scanned:** 4
**Pattern extraction date:** 2024-05-24
