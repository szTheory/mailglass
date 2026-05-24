defmodule Mix.Tasks.Mailglass.Gen.InboundRoute do
  @shortdoc "Appends an inbound route/2 to an existing MailglassInbound.Router"

  @moduledoc """
  Appends a `route/2` clause to an existing `MailglassInbound.Router` module.

  The edit is idempotent: running the task twice for the same mailbox is a
  no-op. The route is appended as the last statement inside the router's
  `do`-block.

  ## Examples

      mix mailglass.gen.inbound_route support@example.com MyApp.SupportMailbox
      mix mailglass.gen.inbound_route support@example.com MyApp.SupportMailbox --router MyApp.InboundRouter

  ## Positional arguments

    * `pattern` - the envelope recipient to match (becomes `recipient: "<pattern>"`).
    * `mailbox` - the mailbox module that handles the matched message.

  ## Options

    * `--router` - the router module to edit. Defaults to `<App>.InboundRouter`.
    * `--recipient` - override the recipient matcher (defaults to `pattern`).
    * `--subject` - add a `subject:` matcher to the generated route.

  `--dry-run` is supported as the framework-provided global switch (it is *not*
  in this task's option schema); it previews the diff and writes nothing.
  """

  use Boundary, classify_to: Mailglass
  use Igniter.Mix.Task

  alias Igniter.Code.Common
  alias Igniter.Code.Function

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      schema: [router: :string, recipient: :string, subject: :string],
      positional: [:pattern, :mailbox]
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    %{pattern: pattern, mailbox: mailbox_arg} = igniter.args.positional
    options = igniter.args.options

    mailbox = parse_module(mailbox_arg)
    recipient = options[:recipient] || pattern
    subject = options[:subject]

    router = router_module(igniter, options[:router])

    add_route(igniter, router, mailbox, recipient: recipient, subject: subject)
  end

  @doc """
  Resolves the router module to edit, honoring an explicit `--router` value and
  otherwise defaulting to `<App>.InboundRouter`.
  """
  @spec router_module(Igniter.t(), String.t() | nil) :: module()
  def router_module(_igniter, router_arg) when is_binary(router_arg), do: parse_module(router_arg)

  def router_module(igniter, _nil) do
    app_module = Igniter.Project.Application.app_module(igniter) || Test
    Module.concat([app_module, "InboundRouter"])
  end

  @doc """
  Idempotently appends a `route/2` for `mailbox` to `router`'s `do`-block.

  Reused by `mix mailglass.gen.mailbox` so the route-stub insertion shares the
  exact same dup-scan + add-route logic. When the router module is not found in
  the project, an actionable notice is emitted (no module is auto-created).

  `opts` accepts:

    * `:recipient` - the recipient matcher string (required for a useful route).
    * `:subject` - an optional subject matcher string.
  """
  @spec add_route(Igniter.t(), module(), module(), keyword()) :: Igniter.t()
  def add_route(igniter, router, mailbox, opts) do
    route_code = route_code(mailbox, opts)

    case Igniter.Project.Module.find_and_update_module(igniter, router, fn zipper ->
           if route_already_present?(zipper, mailbox) do
             # Idempotent no-op: the route is already declared for this mailbox.
             {:ok, zipper}
           else
             {:ok, Common.add_code(zipper, route_code, placement: :after)}
           end
         end) do
      {:ok, igniter} ->
        igniter

      {:error, igniter} ->
        Igniter.add_notice(igniter, """
        Could not find router #{inspect(router)}.

        Run `mix mailglass.gen.inbound_router #{inspect(router)}` first, then re-run this task.
        """)
    end
  end

  @doc """
  Returns true when the router's `do`-block already declares a `route/2` whose
  first argument is `mailbox`.

  The zipper must be positioned at the router's `do`-block (as provided by
  `Igniter.Project.Module.find_and_update_module/3`). Idempotency hinges on
  `argument_equals?/3` resolving the `{:__aliases__, ...}` mailbox AST against
  the module atom.
  """
  @spec route_already_present?(Sourceror.Zipper.t(), module()) :: boolean()
  def route_already_present?(zipper, mailbox) do
    case Function.move_to_function_call_in_current_scope(zipper, :route, 2, fn call_zipper ->
           Function.argument_equals?(call_zipper, 0, mailbox)
         end) do
      {:ok, _zipper} -> true
      :error -> false
    end
  end

  @doc false
  @spec route_code(module(), keyword()) :: String.t()
  def route_code(mailbox, opts) do
    matchers =
      [recipient: opts[:recipient], subject: opts[:subject]]
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Enum.map_join(", ", fn {key, value} -> "#{key}: #{inspect(value)}" end)

    "route(#{inspect(mailbox)}, #{matchers})"
  end

  # A well-formed Elixir module name: dot-separated CamelCase segments.
  @module_name_re ~r/^[A-Z]\w*(\.[A-Z]\w*)*$/

  @doc false
  @spec parse_module(String.t()) :: module()
  def parse_module(arg) do
    unless Regex.match?(@module_name_re, arg) do
      # Bare `Module.concat(["support@example.com"])` would mint an odd atom like
      # :"Elixir.support@example.com" that renders badly in the generated route.
      # Fail fast with an actionable message instead (IN-02).
      Mix.raise("""
      Expected a module name like `MyApp.Inbound.Support`, got: #{inspect(arg)}.

      The mailbox/router argument must be dot-separated CamelCase segments
      (e.g. `MyApp.SupportMailbox`), not an email address or arbitrary string.
      """)
    end

    Module.concat([arg])
  end
end
