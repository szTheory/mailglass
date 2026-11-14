defmodule Storybook.QuickViews.Delivery do
  @moduledoc false
  # Retain the real operator quick-view implementation in Storybook. The iframe
  # gives the fixed overlay its own document so it can cover the story viewport.
  use PhoenixStorybook.Story, :component

  def function, do: &MailglassAdmin.Operator.QuickView.quick_view/1
  def container, do: :iframe

  def template do
    """
    <div data-theme-owner="quick-view-story" data-theme-preference="system" data-theme-resolved="light" data-theme-os="light" data-theme="mailglass-light" style="min-height: 600px" class="mg-admin-root bg-base-100 text-base-content p-md">
      <style>
        [data-theme-owner="quick-view-story"] .mg-detail-panel {
          inset-block-start: 96px;
          height: calc(100% - 96px);
          max-height: calc(100% - 96px);
        }
        [data-theme-owner="quick-view-story"] .mg-overlay-scrim { top: 96px; }
      </style>
      <fieldset aria-label="Review theme" data-testid="quick-view-review-theme" style="position: fixed; top: 8px; left: 8px; z-index: 1000; display: flex; flex-wrap: wrap; max-width: calc(100% - 16px); gap: 4px; margin: 0; padding: 4px; border: 1px solid var(--color-base-300); border-radius: 8px; background: var(--color-base-100); color: var(--color-base-content); box-shadow: 0 2px 8px rgb(13 27 42 / 18%);">
        <legend style="padding: 0 4px;">Review theme</legend>
        <label style="display: flex; align-items: center; gap: 4px; min-width: 64px; min-height: 44px; padding: 0 6px; cursor: pointer;"><input type="radio" name="quick-view-review-theme" value="light" style="width: 16px; height: 16px;">Light</label>
        <label style="display: flex; align-items: center; gap: 4px; min-width: 64px; min-height: 44px; padding: 0 6px; cursor: pointer;"><input type="radio" name="quick-view-review-theme" value="dark" style="width: 16px; height: 16px;">Dark</label>
        <label style="display: flex; align-items: center; gap: 4px; min-width: 64px; min-height: 44px; padding: 0 6px; cursor: pointer;"><input type="radio" name="quick-view-review-theme" value="system" checked style="width: 16px; height: 16px;">System</label>
      </fieldset>
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
