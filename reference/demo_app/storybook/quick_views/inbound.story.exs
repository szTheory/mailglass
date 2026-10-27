defmodule Storybook.QuickViews.Inbound do
  @moduledoc false
  # Keep the production overlay in an isolated document so its fixed panel
  # covers the full Storybook example viewport.
  use PhoenixStorybook.Story, :component

  def function, do: &MailglassAdmin.Inbound.QuickView.quick_view/1
  def container, do: :iframe

  def template do
    """
    <div data-theme="mailglass-light" style="min-height: 600px" class="mg-admin-root bg-base-100 text-base-content p-md">
      <.psb-variation/>
    </div>
    """
  end

  def variations do
    [
      %Variation{
        id: :northstar_normal,
        attributes: MailglassDemo.QuickViewScenarios.inbound(:northstar_normal)
      },
      %Variation{
        id: :northstar_first,
        attributes: MailglassDemo.QuickViewScenarios.inbound(:northstar_first)
      },
      %Variation{
        id: :northstar_last,
        attributes: MailglassDemo.QuickViewScenarios.inbound(:northstar_last)
      },
      %Variation{
        id: :fjordline_single_unicode,
        attributes: MailglassDemo.QuickViewScenarios.inbound(:fjordline_single_unicode)
      },
      %Variation{
        id: :selected_unavailable,
        attributes: MailglassDemo.QuickViewScenarios.inbound(:selected_unavailable)
      }
    ]
  end
end
