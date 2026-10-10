defmodule MailglassAdmin.Inbound.Timeline do
  @moduledoc """
  Read-only execution-lineage timeline for one inbound record, chronological.

  Sibling of `MailglassAdmin.Operator.Timeline`. Rows are
  `ExecutionRun` projections (Pitfall 7 — the lineage schema, NOT the replay-run
  schema) from the internal inbound timeline gateway, each carrying
  `source` (`:fresh`/`:replay`), `mailbox`, and `outcome`,
  `executed_at`, and the run `id`.

  Free-form `outcome_reason` and failure metadata are intentionally omitted so
  provider exception details cannot leak into the operator timeline.
  """

  use Phoenix.Component

  alias MailglassAdmin.Components
  import MailglassAdmin.Components, only: [card: 1, timestamp: 1]

  attr(:runs, :list, required: true)
  attr(:read_state, :atom, default: :ok)
  attr(:read_at, :any, default: nil)

  def timeline(assigns) do
    ~H"""
    <.card
      padding={:lg}
      data-testid="inbound-timeline"
      data-group-card="inbound-timeline"
    >
      <div class="mb-md flex min-w-0 flex-wrap items-center justify-between gap-sm">
        <div class="min-w-0 space-y-xs">
          <h3 class="text-body font-bold text-base-content">Execution timeline</h3>
          <p :if={@read_at} data-testid="inbound-timeline-snapshot" class="text-label text-secondary">
            {if @read_state == :ok, do: "Updated", else: "Last updated"} <.timestamp at={@read_at} />
          </p>
        </div>
        <button
          type="button"
          phx-click="refresh_inbound_timeline"
          phx-disable-with="Refreshing history…"
          data-testid="inbound-timeline-refresh"
          class="btn btn-ghost min-h-11 px-md"
        >
          Refresh history
        </button>
      </div>
      <%= if @read_state != :ok do %>
        <div data-testid="inbound-timeline-unavailable">
          <Components.data_state
            kind={:error}
            title="Timeline unavailable"
            body="Execution history could not be loaded. Refresh history to try again."
          />
        </div>
      <% else %>
        <%= if @runs == [] do %>
          <p class="text-body text-secondary">
            No execution runs have been recorded for this message yet.
          </p>
        <% else %>
          <ol class="motion-timeline space-y-lg">
            <%= for {run, index} <- Enum.with_index(@runs) do %>
              <li
                data-testid="inbound-timeline-run"
                data-run-id={run.id}
                class="flex gap-sm"
              >
                <div class="mt-xs flex flex-col items-center">
                  <span class={["h-3 w-3 rounded-full", outcome_dot_class(run.outcome)]}></span>
                  <span :if={index < length(@runs) - 1} class="mt-sm h-full w-px bg-base-300"></span>
                </div>
                <div class="min-w-0 flex-1 rounded-box border border-base-300 bg-base-100 p-md">
                  <div class="flex flex-wrap items-start justify-between gap-sm">
                    <div class="min-w-0 space-y-xs">
                      <div class="flex flex-wrap items-center gap-sm">
                        <Components.outcome_badge
                          id={"inbound-run-outcome-#{run.id}"}
                          context={:inbound}
                          status={Components.normalize_inbound_outcome(run.outcome)}
                        />
                        <span class="badge badge-outline">{source_label(run.source)}</span>
                      </div>
                      <Components.module_identity
                        :if={present?(run.mailbox)}
                        value={run.mailbox}
                        id={"inbound-run-mailbox-#{run.id}"}
                      />
                      <Components.technical_details
                        collapsible={false}
                        divider?={false}
                        id={"inbound-run-technical-#{run.id}"}
                      >
                        <div>
                          <dt class="text-label font-bold text-secondary">Run ID</dt>
                          <dd class="mt-xs">
                            <Components.copy_value value={run.id} label="Run ID" />
                          </dd>
                        </div>
                      </Components.technical_details>
                    </div>
                    <p class="text-label text-secondary"><.timestamp at={run.executed_at} /></p>
                  </div>
                </div>
              </li>
            <% end %>
          </ol>
        <% end %>
      <% end %>
    </.card>
    """
  end

  defp source_label(:replay), do: "Replay"
  defp source_label(_source), do: "Initial processing"

  defp outcome_dot_class(:accept), do: "bg-success"
  defp outcome_dot_class(:no_match), do: "bg-warning"
  defp outcome_dot_class(outcome) when outcome in [:reject, :bounce, :failed], do: "bg-error"
  defp outcome_dot_class(:ignore), do: "bg-secondary"
  defp outcome_dot_class(_outcome), do: "bg-secondary"

  defp present?(value), do: is_binary(value) and value != ""
end
