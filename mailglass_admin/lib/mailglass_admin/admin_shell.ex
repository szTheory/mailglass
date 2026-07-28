defmodule MailglassAdmin.AdminShell do
  @moduledoc """
  Shared admin chrome for mailglass preview and operator surfaces.

  This component owns only the application frame: global topbar, optional
  contextual sidebar, optional mobile nav row, and the main content wrapper.
  Surface-specific navigation, controls, headings, and content remain with the
  calling LiveView/component.
  """

  use Phoenix.Component

  alias MailglassAdmin.Components

  attr(:testid, :string, default: "admin-shell")
  attr(:theme_attr, :string, default: nil)
  attr(:sidebar_width_class, :string, default: "md:grid-cols-[15rem_1fr]")
  attr(:main_max_width_class, :string, default: "max-w-7xl")

  slot(:actions)
  slot(:sidebar)
  slot(:mobile_nav)
  slot(:page_header)
  slot(:inner_block, required: true)

  @doc """
  Renders consistent mailglass admin chrome around a surface.
  """
  def shell(assigns) do
    ~H"""
    <div
      data-testid={@testid}
      data-theme={@theme_attr}
      class="mg-admin-root min-h-screen bg-base-100 text-base-content"
    >
      <header
        data-testid="admin-shell-topbar"
        class="flex min-h-20 flex-wrap items-center justify-between gap-sm border-b border-base-300 bg-base-100 px-md py-sm md:px-lg"
      >
        <div class="flex min-w-0 items-center gap-sm">
          <Components.logo class="h-6 w-auto shrink-0" />
        </div>

        <div
          :if={@actions != []}
          data-testid="admin-shell-actions"
          class="ml-auto flex min-w-0 flex-wrap items-center justify-end gap-sm"
        >
          {render_slot(@actions)}
        </div>
      </header>

      <div class={["grid mg-shell-min-h", @sidebar != [] && @sidebar_width_class]}>
        <aside
          :if={@sidebar != []}
          data-testid="admin-shell-sidebar"
          class="hidden min-w-0 border-r border-base-300 bg-base-200 md:block"
        >
          <div class="p-sm md:p-md">
            {render_slot(@sidebar)}
          </div>
        </aside>

        <div class="min-w-0">
          <div
            :if={@mobile_nav != []}
            data-testid="admin-shell-mobile-nav"
            class="border-b border-base-300 bg-base-200 px-md py-sm md:hidden"
          >
            {render_slot(@mobile_nav)}
          </div>

          <main class="min-w-0 px-md py-lg md:px-lg md:py-xl">
            <div class={["mx-auto min-w-0", @main_max_width_class]}>
              <div
                :if={@page_header != []}
                data-testid="admin-shell-page-header"
                class="mb-lg flex flex-col gap-xs"
              >
                {render_slot(@page_header)}
              </div>

              {render_slot(@inner_block)}
            </div>
          </main>
        </div>
      </div>
    </div>
    """
  end
end
