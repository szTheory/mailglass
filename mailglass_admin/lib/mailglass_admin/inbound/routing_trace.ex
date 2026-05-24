defmodule MailglassAdmin.Inbound.RoutingTrace do
  @moduledoc """
  Routing-trace card (IADM-04) — the one novel inbound surface.

  Answers "why did this message not match any mailbox?" without an `iex` session,
  by rendering a per-route clause diff for a `:no_match` record. This component is
  NET-NEW, but reuses ONLY existing card/badge/marker chrome (no charts, no JS).

  The verdicts are computed upstream by `MailglassInbound.Router.Matcher.explain/2`
  (reached through the runtime gateway, D-48-06), so the rendered pass/fail equals
  real matcher behavior — this view NEVER re-implements equality/regex/wildcard
  semantics. The `trace` assign is a list (declared route order) of
  `%{mailbox: String.t(), verdicts: [tuple()]}`; each verdict tuple's LAST element
  is the clause `pass?` boolean (per `Matcher.clause_verdict`):

    - `{:recipient, matcher, actual, pass?}`
    - `{:subject, matcher, actual, pass?}`
    - `{:header, name, matcher, actual_list, pass?}`

  Recipient actuals are masked via `Components.mask_recipient/1` (PII discipline,
  T-48-13). A `nil` matcher renders the literal `any` (wildcard); a `%Regex{}`
  renders `~r/.../`; an exact string renders verbatim — all in `.mono`.
  """

  use Phoenix.Component

  alias MailglassAdmin.Components

  attr :trace, :list, required: true

  def routing_trace(assigns) do
    ~H"""
    <article
      data-testid="inbound-routing-trace"
      class="card rounded-box border border-base-300 bg-base-200 p-6"
    >
      <div class="mb-4 space-y-1">
        <h3 class="text-base font-bold text-base-content">Routing trace</h3>
        <p class="text-xs text-secondary">Why this message did not match</p>
      </div>

      <%= if @trace == [] do %>
        <p class="text-sm text-secondary">
          No inbound routes are declared, so there is nothing to trace.
        </p>
      <% else %>
        <div class="space-y-4">
          <%= for route <- @trace do %>
            <section
              data-testid="inbound-route-card"
              class="rounded-box border border-base-300 bg-base-100 p-4"
            >
              <div class="mb-3 flex flex-wrap items-center justify-between gap-2">
                <p class="mono text-sm text-base-content">{route.mailbox}</p>
                <span class="badge badge-outline badge-error">No match</span>
              </div>

              <ul class="space-y-3">
                <%= for verdict <- annotate(route.verdicts) do %>
                  <li
                    data-testid="inbound-trace-clause"
                    class={[
                      "space-y-1 rounded-box",
                      verdict.first_failing? && "border-l-4 border-error px-3"
                    ]}
                  >
                    <span class="text-xs font-bold uppercase tracking-[0.08em] text-secondary">
                      {verdict.dimension}
                    </span>

                    <div class="flex flex-wrap items-center gap-2">
                      <Components.icon
                        name={if verdict.pass?, do: "hero-check-circle", else: "hero-x-circle"}
                        class={[
                          "h-4 w-4",
                          if(verdict.pass?, do: "text-success", else: "text-error")
                        ]}
                      />
                      <span class="text-xs text-secondary">Expected:</span>
                      {expected_markup(assigns, verdict)}
                      <span class="text-xs text-secondary">Actual:</span>
                      <span class="mono text-xs text-base-content">{verdict.actual}</span>
                    </div>

                    <p :if={verdict.first_failing?} class="text-sm text-secondary">
                      {verdict.reason}
                    </p>
                  </li>
                <% end %>
              </ul>
            </section>
          <% end %>
        </div>

        <p class="mt-4 text-xs text-secondary">
          Each route matches by AND across its clauses: any = no constraint, an exact value matches by string equality, and ~r/…/ matches by regular expression.
        </p>
      <% end %>
    </article>
    """
  end

  # Renders the Expected matcher: nil → "any" (text-secondary), regex → ~r/.../,
  # exact string verbatim — all wrapped so the test can assert ">any<".
  defp expected_markup(assigns, %{matcher_kind: :wildcard}) do
    ~H"""
    <span class="mono text-xs text-secondary">any</span>
    """
  end

  defp expected_markup(assigns, %{matcher_kind: _other} = verdict) do
    assigns = Phoenix.Component.assign(assigns, :expected, verdict.expected)

    ~H"""
    <span class="mono text-xs text-base-content">{@expected}</span>
    """
  end

  # Decorate each verdict with: dimension label, rendered Expected/Actual strings,
  # pass?, matcher_kind, the first-failing flag, and the composed reason copy.
  defp annotate(verdicts) do
    first_failing_index =
      Enum.find_index(verdicts, fn verdict -> not pass?(verdict) end)

    verdicts
    |> Enum.with_index()
    |> Enum.map(fn {verdict, index} ->
      pass = pass?(verdict)

      base = %{
        pass?: pass,
        first_failing?: index == first_failing_index,
        matcher_kind: matcher_kind(matcher_of(verdict))
      }

      verdict
      |> decorate(base)
    end)
  end

  defp decorate({:recipient, matcher, actual, _pass?}, base) do
    base
    |> Map.put(:dimension, "Recipient")
    |> Map.put(:expected, render_matcher(matcher))
    |> Map.put(:actual, Components.mask_recipient(actual))
    |> Map.put(:reason, recipient_reason(matcher, actual))
  end

  defp decorate({:subject, matcher, actual, _pass?}, base) do
    base
    |> Map.put(:dimension, "Subject")
    |> Map.put(:expected, render_matcher(matcher))
    |> Map.put(:actual, present(actual))
    |> Map.put(:reason, subject_reason(matcher, actual))
  end

  defp decorate({:header, name, matcher, actual_list, _pass?}, base) do
    base
    |> Map.put(:dimension, "Header: " <> name)
    |> Map.put(:expected, render_matcher(matcher))
    |> Map.put(:actual, render_header_actual(actual_list))
    |> Map.put(:reason, header_reason(name, matcher, actual_list))
  end

  # The clause pass? is always the LAST element of the tuple, regardless of arity.
  defp pass?(verdict), do: elem(verdict, tuple_size(verdict) - 1)

  defp matcher_of({:recipient, matcher, _actual, _pass?}), do: matcher
  defp matcher_of({:subject, matcher, _actual, _pass?}), do: matcher
  defp matcher_of({:header, _name, matcher, _actual, _pass?}), do: matcher

  defp matcher_kind(nil), do: :wildcard
  defp matcher_kind(%Regex{}), do: :regex
  defp matcher_kind(_matcher), do: :exact

  defp render_matcher(nil), do: "any"
  defp render_matcher(%Regex{} = regex), do: "~r/" <> regex.source <> "/"
  defp render_matcher(matcher) when is_binary(matcher), do: matcher

  defp render_header_actual([]), do: "(no such header)"
  defp render_header_actual(list) when is_list(list), do: Enum.join(list, ", ")

  defp present(nil), do: "—"
  defp present(""), do: "—"
  defp present(value), do: value

  # Composed, specific failing-clause reasons (UI-SPEC Copywriting Contract).
  defp recipient_reason(matcher, actual) do
    "Recipient did not match: expected #{render_matcher(matcher)}, message envelope was #{Components.mask_recipient(actual)}."
  end

  defp subject_reason(matcher, actual) do
    "Subject did not match: expected #{render_matcher(matcher)}, message subject was #{present(actual)}."
  end

  defp header_reason(name, _matcher, []) do
    "Header #{name} was required by this route but the message had no such header."
  end

  defp header_reason(name, matcher, actual_list) do
    "Header #{name} did not match: expected #{render_matcher(matcher)}, message had #{render_header_actual(actual_list)}."
  end
end
