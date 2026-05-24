defmodule MailglassAdmin.Inbound.Timeline do
  @moduledoc """
  Read-only execution-lineage timeline for one inbound record, chronological.

  Sibling of `MailglassAdmin.Operator.Timeline` (D-48-13). Rows are
  `ExecutionRun` projections (Pitfall 7 — the lineage schema, NOT the replay-run
  schema) from `MailglassInbound.Internal.Operator.Timeline`, each carrying
  `source` (`:fresh`/`:replay`), `mailbox`, `outcome`, `outcome_reason`,
  `executed_at`, and the run `id`.
  """

  use Phoenix.Component

  attr :runs, :list, required: true

  def timeline(assigns) do
    ~H"""
    <article
      data-testid="inbound-timeline"
      class="card rounded-box border border-base-300 bg-base-200 p-6"
    >
      <div class="mb-4 flex items-center justify-between gap-3">
        <h3 class="text-base font-bold text-base-content">Execution timeline</h3>
        <span class="text-xs text-secondary">Chronological order</span>
      </div>

      <%= if @runs == [] do %>
        <p class="text-sm text-secondary">
          No execution runs have been recorded for this message yet.
        </p>
      <% else %>
        <ol class="space-y-4">
          <%= for {run, index} <- Enum.with_index(@runs) do %>
            <li
              data-testid="inbound-timeline-run"
              data-run-id={run.id}
              class="flex gap-3"
            >
              <div class="mt-1 flex flex-col items-center">
                <span class={["h-3 w-3 rounded-full", outcome_dot_class(run.outcome)]}></span>
                <span :if={index < length(@runs) - 1} class="mt-2 h-full w-px bg-base-300"></span>
              </div>
              <div class="min-w-0 flex-1 rounded-box border border-base-300 bg-base-100 p-4">
                <div class="flex flex-wrap items-start justify-between gap-3">
                  <div class="space-y-1">
                    <div class="flex flex-wrap items-center gap-2">
                      <p class="text-sm font-bold text-base-content">{outcome_label(run.outcome)}</p>
                      <span class="badge badge-outline">{source_label(run.source)}</span>
                    </div>
                    <p :if={present?(run.mailbox)} class="text-xs text-secondary">{run.mailbox}</p>
                    <p :if={present?(run.outcome_reason)} class="text-sm text-secondary">
                      Reason: {run.outcome_reason}
                    </p>
                    <p class="mono text-xs text-secondary">{run.id}</p>
                  </div>
                  <p class="mono text-xs text-secondary">{format_datetime(run.executed_at)}</p>
                </div>
              </div>
            </li>
          <% end %>
        </ol>
      <% end %>
    </article>
    """
  end

  defp source_label(:replay), do: "Replay"
  defp source_label(_source), do: "Fresh"

  defp outcome_dot_class(:accept), do: "bg-success"
  defp outcome_dot_class(:no_match), do: "bg-warning"
  defp outcome_dot_class(outcome) when outcome in [:reject, :bounce, :failed], do: "bg-error"
  defp outcome_dot_class(:ignore), do: "bg-secondary"
  defp outcome_dot_class(_outcome), do: "bg-secondary"

  defp outcome_label(nil), do: "Unknown"

  defp outcome_label(value) do
    value
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp present?(value), do: is_binary(value) and value != ""

  defp format_datetime(nil), do: "Pending"

  defp format_datetime(%DateTime{} = datetime),
    do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S UTC")
end
