defmodule MailglassInbound.Router do
  @moduledoc """
  Thin router DSL for compiling inbound mailbox routes into pure route data.

  A router module declares ordered `route/2` entries and exposes the compiled
  routes through `__mailglass_inbound_routes__/0`. Runtime matching is handled
  by `MailglassInbound.Router.Matcher`, which preserves top-to-bottom,
  first-match-wins semantics.

  this milestone phase intentionally keeps the public matcher surface narrow:

  - `:recipient` accepts an exact string or regex and matches the envelope recipient.
  - `:subject` accepts an exact string or regex.
  - `:headers` accepts `{header_name, exact_string_or_regex}` tuples.
  """

  alias MailglassInbound.Router.Route

  @matcher_type {:custom, __MODULE__, :validate_matcher, []}

  @route_schema [
    recipient: [
      type: {:or, [@matcher_type, nil]},
      default: nil,
      doc: "Exact string or regex matched against envelope_recipient."
    ],
    subject: [
      type: {:or, [@matcher_type, nil]},
      default: nil,
      doc: "Exact string or regex matched against subject."
    ],
    headers: [
      type: {:list, {:tuple, [:string, @matcher_type]}},
      default: [],
      doc: "Header clauses matched with AND semantics."
    ]
  ]

  defmacro __using__(_opts) do
    quote do
      import MailglassInbound.Router, only: [route: 2]

      Module.register_attribute(__MODULE__, :mailglass_inbound_routes, accumulate: true)
      @before_compile MailglassInbound.Router
    end
  end

  defmacro route(mailbox, opts) do
    expanded_mailbox = Macro.expand(mailbox, __CALLER__)
    {evaluated_opts, _binding} = Code.eval_quoted(opts, [], __CALLER__)
    validated = validate_route_opts!(expanded_mailbox, evaluated_opts)
    # Capture the declaration site at compile time so the doctor can name
    # `router.ex:LINE` in route-conflict findings (the design contract).
    route = %Route{
      mailbox: expanded_mailbox,
      recipient: validated[:recipient],
      subject: validated[:subject],
      headers: validated[:headers],
      source: {__CALLER__.file, __CALLER__.line}
    }

    quote bind_quoted: [route: Macro.escape(route)] do
      @mailglass_inbound_routes route
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @doc false
      @spec __mailglass_inbound_routes__() :: [MailglassInbound.Router.Route.t()]
      def __mailglass_inbound_routes__ do
        @mailglass_inbound_routes |> Enum.reverse()
      end
    end
  end

  defp validate_route_opts!(mailbox, opts) when is_atom(mailbox) and is_list(opts) do
    case NimbleOptions.validate(opts, @route_schema) do
      {:ok, validated} ->
        validated

      {:error, %NimbleOptions.ValidationError{message: message}} ->
        raise ArgumentError, "invalid route options for #{inspect(mailbox)}: " <> message
    end
  end

  defp validate_route_opts!(mailbox, _opts) do
    raise ArgumentError,
          "route/2 expects a mailbox module and keyword options, got: #{inspect(mailbox)}"
  end

  @doc false
  @spec validate_matcher(term()) :: {:ok, String.t() | Regex.t()} | {:error, String.t()}
  def validate_matcher(value) when is_binary(value), do: {:ok, value}
  def validate_matcher(%Regex{} = value), do: {:ok, value}

  def validate_matcher(value) do
    {:error, "expected an exact string or regex, got: #{inspect(value)}"}
  end
end
