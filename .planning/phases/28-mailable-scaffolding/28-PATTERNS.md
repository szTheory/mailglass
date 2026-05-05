# Phase 28: Mailable Scaffolding - Pattern Map

**Mapped:** `date`
**Files analyzed:** 3 (Generator task, generated mailable, generated template)
**Analogs found:** 2 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/mix/tasks/mailglass.gen.mailable.ex` | utility (mix task) | file-I/O | `lib/mix/tasks/mailglass.upgrade.v0_2.ex` | role-match |
| Generated Mailable Module (`lib/my_app/mailables/name.ex`) | mailable | templating | `test/support/fake_fixtures.ex` | exact |
| Generated HEEx Template (`lib/my_app/mailables/name.html.heex`) | template | templating | N/A | no-analog |

## Pattern Assignments

### `lib/mix/tasks/mailglass.gen.mailable.ex` (utility, file-I/O)

**Analog:** `lib/mix/tasks/mailglass.upgrade.v0_2.ex` & `test_igniter.exs`

**Imports and Core Pattern** (`lib/mix/tasks/mailglass.upgrade.v0_2.ex` lines 18-35):
```elixir
  use Igniter.Mix.Task

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      schema: [],
      aliases: []
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    # File creation logic using Igniter
  end
```

**File Creation Pattern** (`test_igniter.exs` lines 5-6):
```elixir
    igniter = test_project()
      |> Igniter.Project.Module.create_module(MyApp.Dummy, "def m(), do: :ok")
```
(For the HEEx template, use standard `Igniter.create_new_file/3` or equivalent to output the text file, e.g., `Igniter.create_new_file(igniter, path, template_content)`).

---

### Generated Mailable Module (mailable, templating)

**Analog:** `test/support/fake_fixtures.ex` (lines 20-30)

**Mailable Definition Pattern**:
```elixir
  defmodule MyApp.MyMailer do
    use Mailglass.Mailable, stream: :transactional

    def welcome(email) do
      new()
      |> Mailglass.Message.update_swoosh(fn e ->
        e
        |> Swoosh.Email.from({"Test", "test@example.com"})
        |> Swoosh.Email.to(email)
        |> Swoosh.Email.subject("Welcome")
      end)
      |> Mailglass.Message.put_function(:welcome)
    end
  end
```

**HEEx Template Association**:
The mailable should likely render its template either via standard `embed_templates` (if utilizing Phoenix standard patterns or `Mailglass.Components`) or directly define the `.html.heex` companion alongside the module. `Mailglass.Message.put_function(:welcome)` and subsequent `Outbound` pipeline logic normally relies on conventional callbacks, but standard templates should just be generated alongside the mailable code.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| Generated HEEx Template | template | templating | No standalone HEEx template explicitly identified in the read examples, but standard Phoenix HEEx semantics apply. Can just generate a simple boilerplate with `<p>Welcome!</p>`. |

## Shared Patterns

### Mailable Definition
**Source:** `lib/mailglass/mailable.ex`
**Apply to:** The scaffolding task output
```elixir
use Mailglass.Mailable, stream: :transactional
```

## Metadata

**Analog search scope:** `lib/mix/tasks/**/*.ex`, `test/support/fake_fixtures.ex`, `test_igniter.exs`
**Files scanned:** 12
**Pattern extraction date:** 2024
