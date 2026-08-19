defmodule MailglassInbound.Router do
  @moduledoc since: "0.1.0"
  @moduledoc """
  Thin router DSL for compiling inbound mailbox routes into pure route data.

  A router module declares ordered `route/2` entries and exposes the compiled
  routes through `__mailglass_inbound_routes__/0`. Runtime matching is handled
  by `MailglassInbound.Router.Matcher`, which preserves top-to-bottom,
  first-match-wins semantics.

  This router intentionally keeps the public matcher surface narrow:

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

  @doc since: "0.1.0"
  defmacro __using__(_opts) do
    quote do
      import MailglassInbound.Router, only: [route: 2]

      Module.register_attribute(__MODULE__, :mailglass_inbound_routes, accumulate: true)
      @before_compile MailglassInbound.Router
    end
  end

  @doc since: "0.1.0"
  defmacro route(mailbox, opts) do
    expanded_mailbox = expand_mailbox!(mailbox, __CALLER__)
    validated = validate_route_opts!(expanded_mailbox, decode_literal!(opts))
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

  defp expand_mailbox!(mailbox, _caller) when is_atom(mailbox), do: mailbox

  defp expand_mailbox!({:__aliases__, _meta, _parts} = mailbox, caller) do
    case Macro.expand(mailbox, caller) do
      expanded when is_atom(expanded) -> expanded
      _other -> mailbox_error!(mailbox)
    end
  end

  defp expand_mailbox!(mailbox, _caller), do: mailbox_error!(mailbox)

  @spec mailbox_error!(Macro.t()) :: no_return()
  defp mailbox_error!(mailbox) do
    raise ArgumentError,
          "route/2 expects a literal mailbox module alias, got: #{Macro.to_string(mailbox)}"
  end

  # Route declarations are configuration data. Decode their quoted form without
  # evaluating caller code so a malformed declaration cannot run at compile time.
  defp decode_literal!(value)
       when is_atom(value) or is_binary(value) or is_number(value),
       do: value

  defp decode_literal!(values) when is_list(values), do: Enum.map(values, &decode_literal!/1)

  defp decode_literal!({:sigil_r, _meta, [{:<<>>, _binary_meta, parts}, modifiers]} = ast)
       when is_list(parts) and is_list(modifiers) do
    if Enum.all?(parts, &is_binary/1) and Enum.all?(modifiers, &is_integer/1) do
      pattern = IO.iodata_to_binary(parts)

      case Regex.compile(pattern, List.to_string(modifiers)) do
        {:ok, regex} -> regex
        {:error, reason} -> literal_error!(ast, "invalid regex: #{reason}")
      end
    else
      literal_error!(ast, "regex interpolation is not allowed")
    end
  end

  defp decode_literal!({:{}, _meta, values}) when is_list(values) do
    values |> Enum.map(&decode_literal!/1) |> List.to_tuple()
  end

  # Two-element tuples (including keyword entries and header matchers) are
  # already represented as literal tuples in quoted Elixir.
  defp decode_literal!({left, right}) do
    {decode_literal!(left), decode_literal!(right)}
  end

  defp decode_literal!(ast), do: literal_error!(ast, "executable expressions are not allowed")

  @spec literal_error!(Macro.t(), String.t()) :: no_return()
  defp literal_error!(ast, reason) do
    raise ArgumentError,
          "route/2 accepts only literal options (strings, nil, lists, tuples, and regex sigils); " <>
            "#{reason}: #{Macro.to_string(ast)}"
  end

  @doc false
  @spec validate_matcher(term()) :: {:ok, String.t() | Regex.t()} | {:error, String.t()}
  def validate_matcher(value) when is_binary(value), do: {:ok, value}
  def validate_matcher(%Regex{} = value), do: {:ok, value}

  def validate_matcher(value) do
    {:error, "expected an exact string or regex, got: #{inspect(value)}"}
  end
end
