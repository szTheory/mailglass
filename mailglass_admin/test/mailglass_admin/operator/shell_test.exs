defmodule MailglassAdmin.Operator.ShellTest do
  @moduledoc """
  Tests for Shell.orientation_strip/1 and aria-current nav resolution.
  """

  use MailglassAdmin.LiveViewCase, async: false

  import Phoenix.Component

  alias MailglassAdmin.Operator.Shell

  describe "orientation_strip/1" do
    test "renders deliveries-orientation testid with frozen copy" do
      html = render_component(&Shell.orientation_strip/1, surface: :deliveries)

      assert html =~ ~s(data-testid="deliveries-orientation")
      assert html =~ "Delivery never arrived? Start here."
    end

    test "renders inbound-orientation testid with frozen copy" do
      html = render_component(&Shell.orientation_strip/1, surface: :inbound)

      assert html =~ ~s(data-testid="inbound-orientation")
      assert html =~ "InboundMessage didn&#39;t route as expected? Inspect the routing trace."
    end

    test "renders preview-orientation testid with frozen copy" do
      html = render_component(&Shell.orientation_strip/1, surface: :preview)

      assert html =~ ~s(data-testid="preview-orientation")
      assert html =~ "No mailables found? Define a mailable module in your app."
    end

    test "uses text-label not text-sm for bullet list" do
      html = render_component(&Shell.orientation_strip/1, surface: :deliveries)

      assert html =~ "text-label"
      refute html =~ ~r/class="[^"]*text-sm/
    end
  end

  describe "surface_paths/4" do
    test "carries tenant_id across surfaces so nav preserves scope" do
      paths = Shell.surface_paths("/ops/mail", :deliveries, false, "northstar")

      assert paths.overview == "/ops/mail?tenant_id=northstar"
      assert paths.deliveries == "/ops/mail?tenant_id=northstar&view=deliveries"
      assert paths.inbound == "/ops/mail/inbound?tenant_id=northstar"
    end

    test "does not carry theme in cross-surface navigation" do
      paths = Shell.surface_paths("/ops/mail/inbound", :inbound, true, "northstar")

      assert paths.deliveries == "/ops/mail?tenant_id=northstar&view=deliveries"
      assert paths.inbound == "/ops/mail/inbound?tenant_id=northstar"
    end

    test "omits tenant_id when blank" do
      assert Shell.surface_paths("/ops/mail", :deliveries, true, nil).deliveries ==
               "/ops/mail?view=deliveries"

      assert Shell.surface_paths("/ops/mail", :deliveries, true, "").deliveries ==
               "/ops/mail?view=deliveries"
    end

    test "no query when neither tenant nor dark theme is set" do
      paths = Shell.surface_paths("/ops/mail", :deliveries, false, nil)

      assert paths.overview == "/ops/mail"
      assert paths.deliveries == "/ops/mail?view=deliveries"
      assert paths.inbound == "/ops/mail/inbound"
    end

    test "recovers the operator root from the inbound base_path" do
      paths = Shell.surface_paths("/ops/mail/inbound", :inbound, false, "northstar")

      assert paths.deliveries == "/ops/mail?tenant_id=northstar&view=deliveries"
    end
  end

  describe "tenant_switch_path/3" do
    test "keeps the deliveries surface and drops selected delivery ids when switching tenants" do
      assert Shell.tenant_switch_path(
               "/ops/mail?tenant_id=alpha&delivery_id=old-id&provider=postmark&theme=dark",
               "beta"
             ) == "/ops/mail?tenant_id=beta&provider=postmark"
    end

    test "keeps the inbound surface and drops selected inbound ids when switching tenants" do
      assert Shell.tenant_switch_path(
               "/ops/mail/inbound?tenant_id=alpha&inbound_id=old-id&provider=mailgun",
               "beta"
             ) == "/ops/mail/inbound?tenant_id=beta&provider=mailgun"
    end
  end

  describe "theme_choice/1" do
    test "maps explicit dark cookie values to :dark" do
      assert Shell.theme_choice(%{}, "dark") == :dark
      assert Shell.theme_choice(%{}, "mailglass-dark") == :dark
    end

    test "maps explicit light cookie values to :light" do
      assert Shell.theme_choice(%{}, "light") == :light
      assert Shell.theme_choice(%{}, "mailglass-light") == :light
    end

    test "defaults absent, query-only, or unknown values to :system" do
      assert Shell.theme_choice(%{}) == :system
      assert Shell.theme_choice(%{"theme" => "dark"}) == :system
      assert Shell.theme_choice(%{}, "sepia") == :system
    end
  end

  describe "set_theme_path/2" do
    test "routes system through persistence and removes explicit theme from return path" do
      assert Shell.set_theme_path("/ops/mail?tenant_id=acme&theme=dark", "system") ==
               "/ops/mail/theme/system?return_to=%2Fops%2Fmail%3Ftenant_id%3Dacme"
    end

    test "routes light and dark through persistence while preserving URL state" do
      assert Shell.set_theme_path("/ops/mail?tenant_id=acme&filter=failed&theme=dark", "light") ==
               "/ops/mail/theme/light?return_to=%2Fops%2Fmail%3Ftenant_id%3Dacme%26filter%3Dfailed"

      assert Shell.set_theme_path(
               "/ops/mail/inbound?tenant_id=acme&outcome=accept&inbound_id=rec-1",
               "dark"
             ) ==
               "/ops/mail/theme/dark?return_to=%2Fops%2Fmail%2Finbound%3Ftenant_id%3Dacme%26outcome%3Daccept%26inbound_id%3Drec-1"
    end

    test "derives the persistence route from mounted operator path" do
      assert Shell.set_theme_path("/custom/admin/mail/inbound?tenant_id=acme", "dark") ==
               "/custom/admin/mail/theme/dark?return_to=%2Fcustom%2Fadmin%2Fmail%2Finbound%3Ftenant_id%3Dacme"
    end
  end

  describe "shell/1 header chrome" do
    test "renders theme control without the passive tenant context chip" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Shell.shell
          active={:inbound}
          preview_path="/dev/mail"
          overview_path="/ops/mail?tenant_id=northstar"
          deliveries_path="/ops/mail?tenant_id=northstar&view=deliveries"
          inbound_path="/ops/mail/inbound?tenant_id=northstar"
          inbound_available?={true}
          title="Inbound records"
        >
          body
        </Shell.shell>
        """)

      assert html =~ ~s(data-testid="admin-shell-topbar")
      assert html =~ ~s(data-testid="admin-shell-sidebar")
      assert html =~ ~s(data-testid="admin-shell-mobile-nav")
      assert html =~ ~s(name="theme")
      assert html =~ ~s(aria-label="Dark")
      assert html =~ "hero-moon"
      refute html =~ "Tenant currently in view"
      refute html =~ "No tenant selected"
      refute html =~ "hero-building-office-2"
      assert html =~ ~s(href="/dev/mail")
      assert html =~ "Health"
      assert html =~ "Preview"
    end

    test "orders shared surface nav with Health first and Preview second" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Shell.shell
          active={:overview}
          preview_path="/dev/mail"
          overview_path="/ops/mail?tenant_id=northstar"
          deliveries_path="/ops/mail?tenant_id=northstar&view=deliveries"
          inbound_path="/ops/mail/inbound?tenant_id=northstar"
          inbound_available?={true}
          title="Email health"
        >
          body
        </Shell.shell>
        """)

      {:ok, doc} = Floki.parse_fragment(html)

      labels =
        doc
        |> Floki.find(~s([data-testid="surface-nav-sidebar"] a))
        |> Enum.map(&Floki.text/1)
        |> Enum.map(&String.trim/1)

      assert labels == ["Health", "Preview", "Deliveries", "Inbound"]
    end
  end

  describe "aria-current nav resolution" do
    # Collect the visible text of every element carrying aria-current="page".
    defp current_nav_labels(html) do
      {:ok, doc} = Floki.parse_fragment(html)

      doc
      |> Floki.find(~s([aria-current="page"]))
      |> Enum.map(&Floki.text/1)
      |> Enum.map(&String.trim/1)
    end

    defp current_nav_classes(html) do
      {:ok, doc} = Floki.parse_fragment(html)

      doc
      |> Floki.find(~s([aria-current="page"]))
      |> Enum.map(fn node ->
        node
        |> Floki.attribute("class")
        |> List.first()
        |> to_string()
      end)
    end

    test "active={:deliveries} marks only Deliveries nav items aria-current=page" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Shell.shell
          active={:deliveries}
          overview_path="/operator"
          deliveries_path="/operator?view=deliveries"
          inbound_path="/operator/inbound"
          inbound_available?={true}
          title="Deliveries"
        >
          body
        </Shell.shell>
        """)

      current = current_nav_labels(html)

      # Sidebar nav_link + mobile nav_pill both flip on -> at least two.
      assert current != [], "expected at least one aria-current=page nav item"

      assert Enum.all?(current, &(&1 =~ "Deliveries")),
             "expected every aria-current nav item to be Deliveries, got: #{inspect(current)}"

      refute Enum.any?(current, &(&1 =~ "Inbound")),
             "Inbound must never carry aria-current when active is :deliveries, got: #{inspect(current)}"
    end

    test "active shell nav renders desktop and mobile structural current cues" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Shell.shell
          active={:deliveries}
          overview_path="/operator"
          deliveries_path="/operator?view=deliveries"
          inbound_path="/operator/inbound"
          inbound_available?={true}
          title="Deliveries"
        >
          body
        </Shell.shell>
        """)

      classes = current_nav_classes(html)

      assert Enum.any?(classes, &String.contains?(&1, "border-l-2")),
             "desktop nav_link should expose a border-left current cue, got: #{inspect(classes)}"

      assert Enum.any?(classes, &String.contains?(&1, "border-b-2")),
             "mobile nav_pill should expose a border-bottom current cue, got: #{inspect(classes)}"

      assert Enum.all?(classes, &String.contains?(&1, "border-primary")),
             "all active shell nav cues should use the active border token, got: #{inspect(classes)}"

      assert Enum.all?(classes, &String.contains?(&1, "font-bold")),
             "all active shell nav cues should keep bold active text, got: #{inspect(classes)}"
    end

    test "active={:inbound} flips aria-current=page to the Inbound nav items" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Shell.shell
          active={:inbound}
          overview_path="/operator"
          deliveries_path="/operator?view=deliveries"
          inbound_path="/operator/inbound"
          inbound_available?={true}
          title="Inbound"
        >
          body
        </Shell.shell>
        """)

      current = current_nav_labels(html)

      assert current != [], "expected at least one aria-current=page nav item"

      assert Enum.all?(current, &(&1 =~ "Inbound")),
             "expected every aria-current nav item to be Inbound, got: #{inspect(current)}"

      refute Enum.any?(current, &(&1 =~ "Deliveries")),
             "Deliveries must never carry aria-current when active is :inbound, got: #{inspect(current)}"

      refute Enum.any?(current, &(&1 =~ "Health")),
             "Health must never carry aria-current when active is :inbound, got: #{inspect(current)}"
    end

    test "active={:overview} marks only Health nav items aria-current=page" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Shell.shell
          active={:overview}
          overview_path="/operator"
          deliveries_path="/operator?view=deliveries"
          inbound_path="/operator/inbound"
          inbound_available?={true}
          title="Email health"
        >
          body
        </Shell.shell>
        """)

      current = current_nav_labels(html)

      assert current != [], "expected at least one aria-current=page nav item"

      assert Enum.all?(current, &(&1 =~ "Health")),
             "expected every aria-current nav item to be Health, got: #{inspect(current)}"

      refute Enum.any?(current, &(&1 =~ "Deliveries")),
             "Deliveries must never carry aria-current when active is :overview, got: #{inspect(current)}"

      refute Enum.any?(current, &(&1 =~ "Inbound")),
             "Inbound must never carry aria-current when active is :overview, got: #{inspect(current)}"
    end

    test "Health nav_link and nav_pill are always rendered (no :if gate), href equals overview_path" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Shell.shell
          active={:deliveries}
          overview_path="/operator"
          deliveries_path="/operator?view=deliveries"
          inbound_path="/operator/inbound"
          inbound_available?={false}
          title="Deliveries"
        >
          body
        </Shell.shell>
        """)

      {:ok, doc} = Floki.parse_fragment(html)

      # Health nav items must be present even when inbound_available?=false (always-shown, no gate)
      health_links =
        doc
        |> Floki.find("a")
        |> Enum.filter(fn node -> Floki.text(node) |> String.trim() =~ "Health" end)

      assert length(health_links) >= 2,
             "expected at least 2 Health nav items (sidebar + mobile), got: #{length(health_links)}"

      Enum.each(health_links, fn link ->
        href = link |> Floki.attribute("href") |> List.first()

        assert href == "/operator",
               "expected Health nav item href to be /operator (bare root), got: #{inspect(href)}"
      end)
    end

    test "surface_paths/4 returns :overview key with bare root (no view= param)" do
      paths = Shell.surface_paths("/ops/mail", :deliveries, false, "acme")

      assert Map.has_key?(paths, :overview),
             "expected surface_paths to return :overview key, got: #{inspect(Map.keys(paths))}"

      assert paths.overview == "/ops/mail?tenant_id=acme",
             "expected :overview to be bare root with tenant, got: #{inspect(paths.overview)}"

      refute paths.overview =~ "view=",
             "expected :overview path to have no view= param, got: #{inspect(paths.overview)}"
    end
  end

  describe "theme picker rendering" do
    test "renders public radio primitive labels and set_theme values" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Shell.shell
          active={:deliveries}
          overview_path="/operator"
          deliveries_path="/operator?view=deliveries"
          inbound_path="/operator/inbound"
          inbound_available?={true}
          theme_choice={:light}
          title="Deliveries"
        >
          body
        </Shell.shell>
        """)

      assert html =~ "System"
      assert html =~ "Light"
      assert html =~ "Dark"
      assert html =~ "hero-window"
      assert html =~ "hero-sun"
      assert html =~ "hero-moon"
      assert html =~ ~s(data-testid="admin-shell-actions")
      assert html =~ "ml-auto"
      assert html =~ ~s(phx-click="set_theme")
      assert html =~ ~s(phx-value-theme="system")
      assert html =~ ~s(phx-value-theme="light")
      assert html =~ ~s(phx-value-theme="dark")
      refute html =~ "aria-pressed"
    end
  end
end
