defmodule MailglassAdmin.AdminShellTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias MailglassAdmin.AdminShell

  describe "shell/1" do
    test "renders shared topbar, actions, sidebar, mobile nav, page header, and body" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <AdminShell.shell
          testid="example-shell"
          theme_attr="mailglass-dark"
          sidebar_width_class="md:grid-cols-[20rem_1fr]"
          main_max_width_class="max-w-none"
        >
          <:actions>
            <button type="button">Action</button>
          </:actions>
          <:sidebar>
            <nav aria-label="Desktop sections">Desktop nav</nav>
          </:sidebar>
          <:mobile_nav>
            <nav aria-label="Mobile sections">Mobile nav</nav>
          </:mobile_nav>
          <:page_header>
            <h1>Page title</h1>
          </:page_header>
          Body content
        </AdminShell.shell>
        """)

      assert html =~ ~s(data-testid="example-shell")
      assert html =~ ~s(data-theme="mailglass-dark")
      assert html =~ ~s(data-testid="admin-shell-topbar")
      assert html =~ ~s(aria-label="mailglass")
      refute html =~ ~s(class="text-label font-bold uppercase text-secondary")
      assert html =~ ~s(data-testid="admin-shell-actions")
      assert html =~ "Action"
      assert html =~ ~s(data-testid="admin-shell-sidebar")
      assert html =~ "Desktop nav"
      assert html =~ ~s(data-testid="admin-shell-mobile-nav")
      assert html =~ "Mobile nav"
      assert html =~ ~s(data-testid="admin-shell-page-header")
      assert html =~ "Page title"
      assert html =~ "Body content"
    end
  end
end
