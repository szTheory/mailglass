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

      assert paths.deliveries == "/ops/mail?tenant_id=northstar"
      assert paths.inbound == "/ops/mail/inbound?tenant_id=northstar"
    end

    test "carries tenant_id AND theme together (tenant first, deterministic)" do
      paths = Shell.surface_paths("/ops/mail/inbound", :inbound, true, "northstar")

      assert paths.deliveries == "/ops/mail?tenant_id=northstar&theme=dark"
      assert paths.inbound == "/ops/mail/inbound?tenant_id=northstar&theme=dark"
    end

    test "omits tenant_id when blank, keeping theme-only behavior" do
      assert Shell.surface_paths("/ops/mail", :deliveries, true, nil).deliveries ==
               "/ops/mail?theme=dark"

      assert Shell.surface_paths("/ops/mail", :deliveries, true, "").deliveries ==
               "/ops/mail?theme=dark"
    end

    test "no query when neither tenant nor dark theme is set" do
      paths = Shell.surface_paths("/ops/mail", :deliveries, false, nil)

      assert paths.deliveries == "/ops/mail"
      assert paths.inbound == "/ops/mail/inbound"
    end

    test "recovers the operator root from the inbound base_path" do
      paths = Shell.surface_paths("/ops/mail/inbound", :inbound, false, "northstar")

      assert paths.deliveries == "/ops/mail?tenant_id=northstar"
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

    test "active={:deliveries} marks only Deliveries nav items aria-current=page" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Shell.shell
          active={:deliveries}
          deliveries_path="/operator"
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

    test "active={:inbound} flips aria-current=page to the Inbound nav items" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <Shell.shell
          active={:inbound}
          deliveries_path="/operator"
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
    end
  end
end
