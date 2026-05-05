# Phase 9: Mailable API Redesign + Freeze - Pattern Map

**Mapped:** 2024-04-27
**Files analyzed:** 6
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/mailglass/message.ex` | model | transform | `lib/mailglass/message.ex` | exact |
| `lib/mailglass/mailable.ex` | component | transform | `lib/mailglass/mailable.ex` | exact |
| `lib/mix/tasks/mailglass.upgrade.v0_2.ex` | migration | transform | `lib/mix/tasks/mailglass.install.ex` | role-match |
| `docs/api_stability.md` | config | none | `docs/api_stability.md` | exact |
| `lib/mix/tasks/mailglass.stability.check.ex` | utility | batch | `lib/mix/tasks/mailglass.publish.check.ex` | role-match |
| `guides/upgrading-from-v0_1.md` | config | none | `guides/migration-from-swoosh.md` | role-match |

## Pattern Assignments

### `lib/mailglass/message.ex` (model, transform)

**Analog:** `lib/mailglass/message.ex`

**Native Setter Pattern** (lines 151-175):
```elixir
  @doc since: "0.1.0"
  @spec update_swoosh(t(), (Swoosh.Email.t() -> Swoosh.Email.t())) :: t()
  def update_swoosh(%__MODULE__{swoosh_email: email} = msg, fun) when is_function(fun, 1) do
    %{msg | swoosh_email: fun.(email)}
  end

  @doc since: "0.1.0"
  @spec put_function(t(), atom()) :: t()
  def put_function(%__MODULE__{} = msg, fun_name) when is_atom(fun_name) do
    %{msg | mailable_function: fun_name}
  end
```

### `lib/mailglass/mailable.ex` (component, transform)

**Analog:** `lib/mailglass/mailable.ex`

**Macro Injection Pattern (to be updated)** (lines 115-131):
```elixir
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @behaviour Mailglass.Mailable
      @before_compile Mailglass.Mailable
      @mailglass_opts opts
      @compile {:no_warn_undefined, Mailglass.Outbound}
      import Swoosh.Email, except: [new: 0] # <-- TO BE REMOVED
      import Mailglass.Components
      
      # Deprecated delegations can follow this pattern:
      # @deprecated "Use Mailglass.Message.to/2 instead"
```

### `lib/mix/tasks/mailglass.upgrade.v0_2.ex` (migration, transform)

**Analog:** `lib/mix/tasks/mailglass.install.ex`

**Mix Task Definition Pattern** (lines 1-15):
```elixir
defmodule Mix.Tasks.Mailglass.Install do
  use Boundary, classify_to: Mailglass

  @shortdoc "Install mailglass into a Phoenix host app"

  @moduledoc """
  Install mailglass into a Phoenix host app.
  """

  use Mix.Task

  alias Mailglass.Installer.Apply
```

### `docs/api_stability.md` (config, none)

**Analog:** `docs/api_stability.md`

**Documentation Structure Pattern** (lines 1-10):
```markdown
# API Stability — mailglass

> This file documents the closed sets of values that form part of the public
> API contract. Adding a value requires a CHANGELOG entry plus an `@since`
> annotation on the new atom (minor version bump). Removing a value requires
> a major version bump.

## Error Hierarchy
```

### `lib/mix/tasks/mailglass.stability.check.ex` (utility, batch)

**Analog:** `lib/mix/tasks/mailglass.publish.check.ex`

**Script/Task Execution Pattern** (lines 1-45):
```elixir
defmodule Mix.Tasks.Mailglass.Publish.Check do
  use Boundary, classify_to: Mailglass

  @shortdoc "Run the pre-publish Hex package checks"

  @moduledoc """
  Verify the published tarball before Hex.pm release.
  """

  use Mix.Task

  @impl Mix.Task
  def run(argv) do
    {opts, rest, invalid} = OptionParser.parse(argv, strict: [package: :string, keep: :boolean])
    validate_cli!(rest, invalid)
```

### `guides/upgrading-from-v0_1.md` (config, none)

**Analog:** `guides/migration-from-swoosh.md`

**Guide Structure Pattern** (lines 1-15):
```markdown
# Migration from raw Swoosh

This guide helps you migrate from a raw Swoosh setup to mailglass while preserving your existing templates and adapter credentials.

## Prerequisites

- An existing Phoenix app using Swoosh directly
- Your Swoosh adapter config (API keys, etc.)

## 1) Install mailglass
```

## Shared Patterns

### Error Handling / Mix Tasks
**Source:** `lib/mix/tasks/mailglass.install.ex`
**Apply to:** All Mix tasks
```elixir
    if rest != [] do
      Mix.raise("Installation blocked: unexpected positional arguments \#{Enum.join(rest, " ")}")
    end
```

## Metadata

**Analog search scope:** `lib/mailglass/`, `lib/mix/tasks/`, `docs/`, `guides/`
**Files scanned:** 6
**Pattern extraction date:** 2024-04-27
