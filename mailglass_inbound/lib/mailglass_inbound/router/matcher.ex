defmodule MailglassInbound.Router.Matcher do
  @moduledoc false

  alias MailglassInbound.InboundMessage
  alias MailglassInbound.Router.Route

  @spec match([Route.t()], InboundMessage.t()) :: {:ok, Route.t()} | :no_match
  def match(routes, %InboundMessage{} = message) when is_list(routes) do
    Enum.find_value(routes, :no_match, fn route ->
      if matches_route?(route, message), do: {:ok, route}, else: false
    end)
  end

  @spec matches_route?(Route.t(), InboundMessage.t()) :: boolean()
  def matches_route?(%Route{} = route, %InboundMessage{} = message) do
    matches_matcher?(route.recipient, message.envelope_recipient) and
      matches_matcher?(route.subject, message.subject) and
      matches_headers?(route.headers, message.headers)
  end

  defp matches_headers?(headers, normalized_headers) do
    Enum.all?(headers, fn {name, matcher} ->
      normalized_headers
      |> Map.get(name, [])
      |> Enum.any?(&matches_matcher?(matcher, &1))
    end)
  end

  defp matches_matcher?(nil, _value), do: true
  defp matches_matcher?(_matcher, nil), do: false
  defp matches_matcher?(%Regex{} = matcher, value) when is_binary(value), do: Regex.match?(matcher, value)
  defp matches_matcher?(matcher, value) when is_binary(matcher) and is_binary(value), do: matcher == value
end
