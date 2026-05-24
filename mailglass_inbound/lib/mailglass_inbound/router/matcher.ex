defmodule MailglassInbound.Router.Matcher do
  @moduledoc false

  alias MailglassInbound.InboundMessage
  alias MailglassInbound.Router.Route

  @spec match([Route.t()], InboundMessage.t()) :: {:ok, Route.t()} | :no_match
  def match(routes, %InboundMessage{} = message) when is_list(routes) do
    candidate_count = length(routes)

    MailglassInbound.Telemetry.route_span(
      %{candidate_count: candidate_count},
      fn ->
        result =
          Enum.find_value(routes, :no_match, fn route ->
            if matches_route?(route, message), do: {:ok, route}, else: false
          end)

        {result, route_stop_metadata(result, candidate_count)}
      end
    )
  end

  defp route_stop_metadata({:ok, %Route{mailbox: mailbox}}, candidate_count),
    do: %{mailbox: mailbox, candidate_count: candidate_count}

  defp route_stop_metadata(:no_match, candidate_count),
    do: %{status: :no_match, candidate_count: candidate_count}

  @spec matches_route?(Route.t(), InboundMessage.t()) :: boolean()
  def matches_route?(%Route{} = route, %InboundMessage{} = message) do
    matches_matcher?(route.recipient, message.envelope_recipient) and
      matches_matcher?(route.subject, message.subject) and
      matches_headers?(route.headers, message.headers)
  end

  @typedoc """
  A per-clause routing-trace verdict. The LAST element of every tuple is the
  clause's `pass?` boolean, regardless of tuple arity:

  - `{:recipient, matcher, actual, pass?}` — `actual` is `envelope_recipient`.
  - `{:subject, matcher, actual, pass?}` — `actual` is the subject.
  - `{:header, name, matcher, actual, pass?}` — `actual` is the normalized header
    value LIST (`Map.get(headers, name, [])`); a missing header is `[]`.
  """
  @type clause_verdict ::
          {:recipient, Route.matcher() | nil, String.t() | nil, boolean()}
          | {:subject, Route.matcher() | nil, String.t() | nil, boolean()}
          | {:header, String.t(), Route.matcher(), [String.t()], boolean()}

  @doc false
  # IADM-04 routing-trace reflection (D-48-06). Returns the per-clause verdict
  # list whose AND equals `matches_route?/2`. It REUSES the in-module
  # `matches_matcher?/2` predicates and the same header default/AND-any logic as
  # `matches_headers?/2` — there is a SINGLE source of truth for match semantics;
  # this never re-implements equality / regex / wildcard rules.
  @spec explain(Route.t(), InboundMessage.t()) :: [clause_verdict()]
  def explain(%Route{} = route, %InboundMessage{} = message) do
    recipient_actual = message.envelope_recipient
    subject_actual = message.subject

    recipient_verdict =
      {:recipient, route.recipient, recipient_actual,
       matches_matcher?(route.recipient, recipient_actual)}

    subject_verdict =
      {:subject, route.subject, subject_actual, matches_matcher?(route.subject, subject_actual)}

    header_verdicts =
      Enum.map(route.headers, fn {name, matcher} ->
        actual = Map.get(message.headers, name, [])
        {:header, name, matcher, actual, Enum.any?(actual, &matches_matcher?(matcher, &1))}
      end)

    [recipient_verdict, subject_verdict | header_verdicts]
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
