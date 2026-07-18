defmodule MailglassAdmin.Inbound.Timeline do
  @moduledoc """
  Read-only execution-lineage timeline for one inbound record, chronological.

  Sibling of `MailglassAdmin.Operator.Timeline`. Rows are
  `ExecutionRun` projections (Pitfall 7 — the lineage schema, NOT the replay-run
  schema) from the internal inbound timeline gateway, each carrying
  `source` (`:fresh`/`:replay`), `mailbox`, `outcome`, `outcome_reason`,
  `executed_at`, and the run `id`.
  """

  use Phoenix.Component

  import MailglassAdmin.Components, only: [card: 1, timestamp: 1]

  attr :runs, :list, required: true

  def timeline(assigns) do
    ~H"""
    <.card
      padding={:lg}
      data-testid="inbound-timeline"
      data-group-card="inbound-timeline"
    >
      <div class="mb-md flex items-center justify-between gap-sm">
        <h3 class="text-body font-bold text-base-content">Execution timeline</h3>
        <span class="text-label text-secondary">Chronological order</span>
      </div>

      <%= if @runs == [] do %>
        <p class="text-body text-secondary">
          No execution runs have been recorded for this message yet.
        </p>
      <% else %>
        <% last_index = length(@runs) - 1 %>
        <ol class="motion-timeline -mb-lg">
          <%= for {run, index} <- Enum.with_index(@runs) do %>
            <li
              data-testid="inbound-timeline-run"
              data-run-id={run.id}
            >
              <div class="relative pb-lg">
                <%!-- Continuous rail (see MailglassAdmin.Operator.Timeline): the
                      connector spans this padding-inclusive box so h-full reaches
                      the next dot. Omitted on the last (most recent) run. --%>
                <span
                  :if={index < last_index}
                  aria-hidden="true"
                  class="absolute left-1.5 top-4 -ml-px h-full w-px bg-base-300"
                >
                </span>
                <div class="relative flex gap-md">
                  <span class={[
                    "z-10 mt-1.5 h-3 w-3 shrink-0 rounded-full border-2 border-base-100",
                    outcome_dot_class(run.outcome),
                    latest_ring_class(run.outcome, index == last_index)
                  ]}>
                  </span>
                  <div class="min-w-0 flex-1 rounded-box border border-base-300 bg-base-100 p-md">
                    <div class="flex flex-wrap items-start justify-between gap-sm">
                      <div class="space-y-xs">
                        <div class="flex flex-wrap items-center gap-sm">
                          <p class="text-body font-bold text-base-content">{outcome_label(run.outcome)}</p>
                          <span class="badge badge-outline">{source_label(run.source)}</span>
                          <span
                            :if={index == last_index}
                            class="text-label font-bold uppercase text-secondary"
                          >
                            Latest
                          </span>
                        </div>
                        <p :if={present?(run.mailbox)} class="text-label text-secondary">{run.mailbox}</p>
                        <p :if={present?(run.outcome_reason)} class="text-body text-secondary">
                          Reason: {run.outcome_reason}
                        </p>
                        <p class="mono text-label text-secondary">{run.id}</p>
                      </div>
                      <p class="text-label text-secondary"><.timestamp at={run.executed_at} /></p>
                    </div>
                  </div>
                </div>
              </div>
            </li>
          <% end %>
        </ol>
      <% end %>
    </.card>
    """
  end

  defp source_label(:replay), do: "Replay"
  defp source_label(_source), do: "Fresh"

  defp outcome_dot_class(:accept), do: "bg-success"
  defp outcome_dot_class(:no_match), do: "bg-warning"
  defp outcome_dot_class(outcome) when outcome in [:reject, :bounce, :failed], do: "bg-error"
  defp outcome_dot_class(:ignore), do: "bg-secondary"
  defp outcome_dot_class(_outcome), do: "bg-secondary"

  # The most recent run carries a tone-matched halo (mirrors the operator timeline).
  defp latest_ring_class(_outcome, false), do: nil
  defp latest_ring_class(:accept, true), do: "ring-2 ring-success/40"
  defp latest_ring_class(:no_match, true), do: "ring-2 ring-warning/40"

  defp latest_ring_class(outcome, true) when outcome in [:reject, :bounce, :failed],
    do: "ring-2 ring-error/40"

  defp latest_ring_class(_outcome, true), do: "ring-2 ring-secondary/40"

  defp outcome_label(nil), do: "Unknown"

  defp outcome_label(value) do
    value
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp present?(value), do: is_binary(value) and value != ""
end
