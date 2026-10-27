defmodule Storybook.QuickViews.Delivery do
  @moduledoc false
  # Retain the real operator quick-view implementation in Storybook. The iframe
  # gives the fixed overlay its own document so it can cover the story viewport.
  use PhoenixStorybook.Story, :component

  def function, do: &MailglassAdmin.Operator.QuickView.quick_view/1
  def container, do: :iframe

  def template do
    """
    <div data-theme="mailglass-light" class="mg-admin-root bg-base-100 text-base-content p-md">
      <.psb-variation/>
    </div>
    """
  end

  @dark_template """
  <div data-theme="mailglass-dark" class="mg-admin-root bg-base-100 text-base-content p-md">
    <.psb-variation/>
  </div>
  """

  def variations do
    [
      %Variation{
        id: :northstar_normal,
        attributes: %{
          delivery: normal_delivery(),
          account_labels: %{"northstar" => "Northstar Logistics"},
          full_path:
            "/ops/mail?tenant_id=northstar&view=deliveries&delivery_id=phase174-normal&full=1",
          close_path: "/ops/mail?tenant_id=northstar&view=deliveries",
          previous_path:
            "/ops/mail?tenant_id=northstar&view=deliveries&delivery_id=phase174-previous",
          next_path:
            "/ops/mail?tenant_id=northstar&view=deliveries&delivery_id=phase174-next",
          position: %{index: 2, total: 16},
          keyboard?: false
        }
      }
    ]
  end

  defp normal_delivery do
    %{
      id: "phase174-normal-delivery",
      tenant_id: "northstar",
      recipient: "mira.chen@northstar.example",
      subject: "Sam Rivera invited you to Northstar Logistics",
      status: :sent,
      last_event_type: :delivered,
      last_event_at: ~U[2026-10-26 12:00:00Z],
      provider: "postmark"
    }
  end
end
