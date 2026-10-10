defmodule MailglassAdmin.Inbound.RoutingTrace do
  @moduledoc """
  Routing-trace card — a current-router simulation for inbound no-match records.

  Verdicts come from the internal matcher explanation function. This component
  preserves those pass/fail results while applying a field-specific display
  policy before any matcher or message value reaches ordinary HTML. A native
  `details` disclosure owns its expanded state so browser and assistive
  technology state cannot drift from the visible content.
  """

  use Phoenix.Component

  alias MailglassAdmin.Components

  attr :trace, :list, required: true

  def routing_trace(assigns) do
    ~H"""
    <Components.card
      padding={:lg}
      data-testid="inbound-routing-trace"
      data-group-card="inbound-routing-trace"
    >
      <details data-testid="inbound-routing-disclosure">
        <summary
          aria-controls="inbound-routing-trace-content"
          class="mg-focus-ring block min-h-11 cursor-pointer rounded-box"
        >
          <span class="text-body font-bold text-base-content">Current router simulation</span>
          <span class="block text-label text-secondary">How current route rules compare</span>
        </summary>

        <div id="inbound-routing-trace-content" class="mt-md space-y-md">
          <p class="text-label text-secondary">
            This evaluates the router configured now; it does not prove which route was selected when the message arrived. Recorded execution runs and durable route bindings are historical evidence.
          </p>

          <%= if @trace == [] do %>
            <p class="text-body text-secondary">
              No inbound routes are declared, so there is nothing to trace.
            </p>
          <% else %>
            <div class="space-y-lg">
              <%= for route <- @trace do %>
                <section
                  data-testid="inbound-route-card"
                  class="min-w-0 rounded-box border border-base-300 bg-base-100 p-md"
                >
                  <div class="mb-sm flex flex-wrap items-center justify-between gap-sm">
                    <p class="mono min-w-0 break-all text-body text-base-content">{route.mailbox}</p>
                    <span
                      data-testid="inbound-route-result"
                      class={[
                        "badge badge-outline",
                        if(route_matches_current_rules?(route.verdicts),
                          do: "badge-success",
                          else: "badge-error"
                        )
                      ]}
                    >
                      {if route_matches_current_rules?(route.verdicts),
                        do: "Matches current clauses",
                        else: "Does not match current clauses"}
                    </span>
                  </div>

                  <ul class="min-w-0 space-y-md">
                    <%= for verdict <- annotate(route.verdicts) do %>
                      <li
                        data-testid="inbound-trace-clause"
                        class={[
                          "min-w-0 rounded-box",
                          verdict.first_failing? && "border-l-4 border-error px-sm"
                        ]}
                      >
                        <div class="grid min-w-0 gap-sm sm:grid-cols-[minmax(7rem,10rem)_1fr_1fr]">
                          <div class="min-w-0 space-y-xs">
                            <span class="text-label uppercase font-bold text-secondary">Dimension</span>
                            <div class="flex items-center gap-sm">
                              <Components.icon
                                name={
                                  if verdict.pass?, do: "hero-check-circle", else: "hero-x-circle"
                                }
                                class={[
                                  "h-4 w-4",
                                  if(verdict.pass?, do: "text-success", else: "text-error")
                                ]}
                              />
                              <span class="text-body text-base-content">{verdict.dimension}</span>
                            </div>
                          </div>

                          <div class="min-w-0 space-y-xs">
                            <span class="text-label uppercase font-bold text-secondary">Expected</span>
                            {expected_markup(assigns, verdict)}
                          </div>

                          <div class="min-w-0 space-y-xs">
                            <span class="text-label uppercase font-bold text-secondary">Actual</span>
                            <span class="mono block min-w-0 break-all rounded-box border border-base-300 bg-base-100 px-sm py-xs text-label text-base-content">
                              {verdict.actual}
                            </span>
                          </div>
                        </div>

                        <p
                          :if={verdict.first_failing?}
                          class="min-w-0 break-words text-body text-secondary"
                        >
                          {verdict.reason}
                        </p>
                      </li>
                    <% end %>
                  </ul>
                </section>
              <% end %>
            </div>

            <p class="text-label text-secondary">
              Each route matches by AND across its clauses: any = no constraint, an exact value matches by string equality, and a regular-expression matcher uses its configured expression.
            </p>
          <% end %>
        </div>
      </details>
    </Components.card>
    """
  end

  defp expected_markup(assigns, %{matcher_kind: :wildcard}) do
    ~H"""
    <span class="mono block min-w-0 break-all rounded-box border border-base-300 bg-base-100 px-sm py-xs text-label text-secondary">
      any
    </span>
    """
  end

  defp expected_markup(assigns, verdict) do
    assigns = Phoenix.Component.assign(assigns, :expected, verdict.expected)

    ~H"""
    <span class="mono block min-w-0 break-all rounded-box border border-base-300 bg-base-100 px-sm py-xs text-label text-base-content">
      {@expected}
    </span>
    """
  end

  defp annotate(verdicts) do
    first_failing_index = Enum.find_index(verdicts, fn verdict -> not pass?(verdict) end)

    verdicts
    |> Enum.with_index()
    |> Enum.map(fn {verdict, index} ->
      base = %{
        pass?: pass?(verdict),
        first_failing?: index == first_failing_index,
        matcher_kind: matcher_kind(matcher_of(verdict))
      }

      decorate(verdict, base)
    end)
  end

  defp decorate({:recipient, matcher, actual, _pass?}, base) do
    base
    |> Map.put(:dimension, "Recipient")
    |> Map.put(:expected, render_matcher(matcher, :recipient))
    |> Map.put(:actual, masked_recipient(actual))
    |> Map.put(:reason, "Recipient did not match the current route.")
  end

  defp decorate({:subject, matcher, actual, _pass?}, base) do
    base
    |> Map.put(:dimension, "Subject")
    |> Map.put(:expected, render_matcher(matcher, :subject))
    |> Map.put(:actual, masked_subject(actual))
    |> Map.put(:reason, "Subject did not match the current route.")
  end

  defp decorate({:header, _name, matcher, actual_list, _pass?}, base) do
    base
    |> Map.put(:dimension, "Header")
    |> Map.put(:expected, render_matcher(matcher, :header))
    |> Map.put(:actual, render_header_actual(actual_list))
    |> Map.put(:reason, header_reason(actual_list))
  end

  defp decorate(_unsupported_clause, base) do
    base
    |> Map.put(:dimension, "Other condition")
    |> Map.put(:expected, "Matcher details withheld")
    |> Map.put(:actual, "Value withheld")
    |> Map.put(:reason, "This route condition did not match.")
  end

  defp pass?(verdict) when is_tuple(verdict) and tuple_size(verdict) > 0,
    do: elem(verdict, tuple_size(verdict) - 1)

  defp pass?(_verdict), do: false

  defp route_matches_current_rules?(verdicts) when is_list(verdicts),
    do: Enum.all?(verdicts, &(pass?(&1) === true))

  defp route_matches_current_rules?(_verdicts), do: false

  defp matcher_of({:recipient, matcher, _actual, _pass?}), do: matcher
  defp matcher_of({:subject, matcher, _actual, _pass?}), do: matcher
  defp matcher_of({:header, _name, matcher, _actual_list, _pass?}), do: matcher
  defp matcher_of(_unsupported_clause), do: :unsupported

  defp matcher_kind(nil), do: :wildcard
  defp matcher_kind(%Regex{}), do: :regex
  defp matcher_kind(:unsupported), do: :unsupported
  defp matcher_kind(matcher) when is_binary(matcher), do: :exact
  defp matcher_kind(_matcher), do: :unsupported

  defp render_matcher(nil, _dimension), do: "any"
  defp render_matcher(%Regex{}, _dimension), do: "Regular expression matcher"

  defp render_matcher(matcher, :recipient) when is_binary(matcher),
    do: masked_recipient(matcher)

  defp render_matcher(matcher, :subject) when is_binary(matcher),
    do: masked_subject(matcher)

  defp render_matcher(_matcher, :header), do: "Exact value matcher"
  defp render_matcher(_matcher, _dimension), do: "Matcher details withheld"

  defp masked_recipient(nil), do: "Unavailable"

  defp masked_recipient(value) when is_binary(value) and value != "",
    do: Components.mask_recipient(value)

  defp masked_recipient(_value), do: "Unavailable"

  defp masked_subject(nil), do: "Unavailable"
  defp masked_subject(""), do: "Unavailable"

  defp masked_subject(value) when is_binary(value),
    do: Components.mask_value(value)

  defp masked_subject(_value), do: "Unavailable"

  defp render_header_actual([]), do: "Not present"
  defp render_header_actual(values) when is_list(values), do: "Value withheld"
  defp render_header_actual(_values), do: "Unavailable"

  defp header_reason([]), do: "Required header was not present on the current message."
  defp header_reason(_values), do: "Header did not match the current route."
end
