defmodule MailglassAdmin.Operator.HealthOverview do
  @moduledoc false
  use Phoenix.Component

  alias MailglassAdmin.Components

  attr(:issues, :list, required: true)
  attr(:activity, :map, required: true)
  attr(:states, :map, required: true)
  attr(:deliveries_path, :string, required: true)
  attr(:inbound_path, :string, required: true)
  attr(:window_copy, :string, required: true)
  attr(:window_description, :string, required: true)
  attr(:observed_at, :any, required: true)

  def overview(assigns) do
    complete? = Enum.all?(assigns.states, fn {_, state} -> state.status == :ready end)
    active? = Enum.any?(assigns.activity, fn {_, value} -> value && value.total > 0 end)

    {title, icon, color, detail} =
      cond do
        assigns.issues != [] ->
          {"Needs attention", "hero-exclamation-triangle", "text-warning",
           if(complete?, do: nil, else: "Some checks could not be updated.")}

        not complete? ->
          {"Health check incomplete", "hero-exclamation-triangle", "text-warning",
           "Refresh to try again."}

        not active? ->
          {"No recent mail activity", "hero-minus-circle", "text-secondary", nil}

        true ->
          {"No issues found", "hero-check-circle", "text-success",
           "No recorded problems in this period."}
      end

    assigns = assign(assigns, title: title, icon: icon, color: color, detail: detail)

    ~H"""
    <div data-testid="operator-health-layout" class="operator-health-layout">
      <div data-testid="operator-health-column" class="operator-health-column">
        <.observation
          window_copy={@window_copy}
          window_description={@window_description}
          observed_at={@observed_at}
        />
        <section data-testid="operator-health-status" class="mt-md min-w-0">
          <.verdict title={@title} icon={@icon} color={@color} detail={@detail} />
          <.issue_list issues={@issues} />
          <.notices states={@states} />
        </section>
        <.activity
          activity={@activity}
          states={@states}
          deliveries_path={@deliveries_path}
          inbound_path={@inbound_path}
        />
      </div>
    </div>
    """
  end

  attr(:title, :string, required: true)
  attr(:icon, :string, required: true)
  attr(:color, :string, required: true)
  attr(:detail, :string, default: nil)

  def verdict(assigns) do
    ~H"""
    <div class="flex items-start gap-sm">
      <Components.icon name={@icon} class={["mt-xs h-5 w-5 shrink-0", @color]} />
      <div class="min-w-0">
        <h2 class="text-heading font-bold text-base-content">{@title}</h2>
        <p :if={@detail} class="mt-xs max-w-prose text-body text-secondary">{@detail}</p>
      </div>
    </div>
    """
  end

  attr(:issues, :list, required: true)

  def issue_list(assigns) do
    ~H"""
    <ul :if={@issues != []} class="mt-md divide-y divide-base-300 border-y border-base-300">
      <li :for={issue <- @issues} data-testid={issue.testid} class="flex min-w-0 items-center gap-sm">
        <p
          data-testid={issue.testid <> "-count"}
          class="min-w-10 shrink-0 text-right text-body font-bold tabular-nums text-base-content"
        >
          {issue.count}
        </p>
        <div class="flex min-w-0 flex-1 flex-wrap items-center gap-xs">
          <.link
            :if={issue.surface == :deliveries}
            patch={issue.path}
            data-testid={issue.testid <> "-link"}
            class="mg-focus-ring inline-flex min-h-11 min-w-0 items-center rounded-field text-body text-base-content underline decoration-base-300 underline-offset-4 hover:decoration-current"
          >
            {issue.label}
          </.link>
          <.link
            :if={issue.surface == :inbound}
            navigate={issue.path}
            data-testid={issue.testid <> "-link"}
            class="mg-focus-ring inline-flex min-h-11 min-w-0 items-center rounded-field text-body text-base-content underline decoration-base-300 underline-offset-4 hover:decoration-current"
          >
            {issue.label}
          </.link>
          <Components.field_help
            id={issue.testid <> "-help"}
            label={issue.label}
            text={issue.help}
          />
          <span :if={issue.stale?} class="text-label text-secondary">Last retrieved</span>
        </div>
      </li>
    </ul>
    """
  end

  attr(:states, :map, required: true)

  def notices(assigns) do
    ~H"""
    <p
      :for={{panel, state} <- @states}
      :if={state.status != :ready}
      data-testid={"operator-health-#{state.status}-#{panel}"}
      class="mt-sm text-body text-secondary"
    >
      {panel_name(panel)}:
      <%= if state.status == :stale do %>
        last retrieved <Components.timestamp at={state.checked_at} />.
      <% else %>
        could not be loaded.
      <% end %>
    </p>
    """
  end

  attr(:activity, :map, required: true)
  attr(:states, :map, required: true)
  attr(:deliveries_path, :string, required: true)
  attr(:inbound_path, :string, required: true)

  def activity(assigns) do
    ~H"""
    <section
      class="mt-lg min-w-0 border-t border-base-300 pt-md"
      data-testid="operator-health-activity"
      aria-labelledby="operator-health-activity-title"
    >
      <h2 id="operator-health-activity-title" class="text-label font-bold text-secondary">
        Recent activity
      </h2>
      <div class="mt-sm flex flex-col gap-sm @[30rem]:flex-row @[30rem]:gap-xl">
        <div>
          <div class="flex items-center gap-xs text-label text-secondary">
            <span>Outbound</span>
            <Components.field_help
              id="operator-health-outbound-activity-help"
              label="outbound activity"
              text="Deliveries with a recorded event in this period, including pending and failed deliveries. Activity alone does not confirm successful delivery."
            />
          </div>
          <.link
            patch={@deliveries_path}
            data-testid="operator-health-outbound-activity"
            class="mg-focus-ring inline-flex min-h-11 items-center gap-xs rounded-field text-body text-base-content underline decoration-base-300 underline-offset-4 hover:decoration-current"
          >
            <span :if={@activity.deliveries} class="font-bold tabular-nums">
              {@activity.deliveries.total}
            </span>
            <span>
              {if @activity.deliveries,
                do:
                  if(@activity.deliveries.total == 1,
                    do: "delivery updated",
                    else: "deliveries updated"
                  ),
                else: "Activity unavailable"}
            </span>
          </.link>
        </div>
        <div :if={Map.has_key?(@states, :inbound_activity)}>
          <div class="flex items-center gap-xs text-label text-secondary">
            <span>Inbound</span>
            <Components.field_help
              id="operator-health-inbound-activity-help"
              label="inbound activity"
              text="Messages received in this period, across all mailbox outcomes."
            />
          </div>
          <.link
            navigate={@inbound_path}
            data-testid="operator-health-inbound-activity"
            class="mg-focus-ring inline-flex min-h-11 items-center gap-xs rounded-field text-body text-base-content underline decoration-base-300 underline-offset-4 hover:decoration-current"
          >
            <span :if={@activity.inbound} class="font-bold tabular-nums">
              {@activity.inbound.total}
            </span>
            <span>
              {if @activity.inbound,
                do:
                  if(@activity.inbound.total == 1,
                    do: "message received",
                    else: "messages received"
                  ),
                else: "Activity unavailable"}
            </span>
          </.link>
        </div>
      </div>
    </section>
    """
  end

  attr(:window_copy, :string, required: true)
  attr(:window_description, :string, required: true)
  attr(:observed_at, :any, required: true)

  def observation(assigns) do
    ~H"""
    <div
      data-testid="operator-health-observation"
      role="group"
      aria-label="Health check period and freshness"
      class="flex flex-wrap items-center gap-x-sm gap-y-xs text-label text-secondary"
    >
      <div class="inline-flex items-center gap-xs">
        <p data-testid="operator-health-window">{@window_copy}</p>
        <Components.field_help
          id="operator-health-window-help"
          label="observation period"
          text={@window_description}
        />
      </div>
      <span class="inline-flex flex-wrap items-center gap-x-sm gap-y-xs">
        <p data-testid="operator-health-last-checked">
          Last checked <Components.timestamp at={@observed_at} />
        </p>
        <button
          id="operator-health-refresh"
          type="button"
          phx-click="retry_health"
          class="btn btn-ghost min-h-11"
        >
          <Components.icon name="hero-arrow-path" class="h-4 w-4" />
          <span class="grid">
            <span class="[grid-area:1/1] [.phx-click-loading_&]:invisible">Refresh health</span>
            <span class="invisible [grid-area:1/1] [.phx-click-loading_&]:visible">
              Refreshing…
            </span>
          </span>
        </button>
      </span>
    </div>
    """
  end

  defp panel_name(:failed_ingest), do: "Webhook processing"
  defp panel_name(:orphan_backlog), do: "Unmatched events"
  defp panel_name(:delivery_activity), do: "Outbound activity and delivery results"
  defp panel_name(:inbound_activity), do: "Inbound activity and processing results"
end
