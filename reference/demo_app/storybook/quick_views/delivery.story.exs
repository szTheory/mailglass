defmodule Storybook.QuickViews.Delivery do
  @moduledoc false
  # Retain the real operator quick-view implementation in Storybook. The iframe
  # gives the fixed overlay its own document so it can cover the story viewport.
  use PhoenixStorybook.Story, :component

  def function, do: &MailglassAdmin.Operator.QuickView.quick_view/1
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
        attributes: MailglassDemo.QuickViewScenarios.delivery(:northstar_normal)
      },
      %Variation{
        id: :northstar_first,
        attributes: MailglassDemo.QuickViewScenarios.delivery(:northstar_first)
      },
      %Variation{
        id: :northstar_last,
        attributes: MailglassDemo.QuickViewScenarios.delivery(:northstar_last)
      },
      %Variation{
        id: :fjordline_single_unicode,
        attributes: MailglassDemo.QuickViewScenarios.delivery(:fjordline_single_unicode)
      }
    ]
  end
end
