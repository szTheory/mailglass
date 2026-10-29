defmodule MailglassAdmin.Phase177AccountScopeTest do
  @moduledoc """
  Phase 177 UXF-09: the Account control heads the group it scopes (D-09), offers
  a picker only when there is a real choice (D-10), and Preview shows no Account
  identity (D-11).

  Component rows render `Shell.shell/1` directly with `rendered_to_string/1`;
  Preview rows are connected `live/2` tests against the synthetic adopter router.
  """

  use MailglassAdmin.LiveViewCase, async: false

  @moduletag :phase177

  import Phoenix.Component, only: [sigil_H: 2]

  alias MailglassAdmin.Fixtures.{BrokenMailer, HappyMailer, StubMailer}
  alias MailglassAdmin.Operator.Shell

  @fixture_mailables [HappyMailer, StubMailer, BrokenMailer]
  @two_options [%{id: "acme", label: "Acme"}, %{id: "fjordline-aps", label: "Fjordline"}]

  @base_attrs %{
    active: :overview,
    preview_path: "/dev/mail",
    overview_path: "/ops/mail?tenant_id=acme",
    deliveries_path: "/ops/mail?tenant_id=acme&view=deliveries",
    inbound_path: "/ops/mail/inbound?tenant_id=acme",
    inbound_available?: true,
    selected_tenant_id: "acme",
    tenant_options: @two_options,
    account_labels: %{"acme" => "Acme", "fjordline-aps" => "Fjordline"},
    page_uri: "/ops/mail?tenant_id=acme",
    title: "Email health"
  }

  describe "Phase 177 Account scope group on operator pages" do
    test "Phase 177 Account header heads a group of Health, Deliveries and Inbound in each layout" do
      doc = render_shell(%{})

      for layout <- ["sidebar", "mobile"] do
        nav = nav(doc, layout)
        groups = Floki.find(nav, ~s([data-account-scope][role="group"]))
        assert length(groups) == 1, "#{layout}: expected exactly one scope group"
        [group] = groups

        assert Floki.attribute(group, "data-testid") == ["surface-nav-scope-group"]
        assert Floki.attribute(group, "data-layout") == [layout]

        header_id = hd(Floki.attribute(group, "aria-labelledby"))
        [header] = Floki.find(group, ~s([id="#{header_id}"]))
        assert Floki.find(header, ~s([data-testid="operator-account-switcher"])) != []

        assert group
               |> Floki.find(~s([data-testid="surface-nav-scope-items"] a))
               |> link_labels() == ["Health", "Deliveries", "Inbound"]
      end
    end

    test "Phase 177 Preview sits after the group in its own block with the caption" do
      doc = render_shell(%{})

      for layout <- ["sidebar", "mobile"] do
        nav = nav(doc, layout)

        assert Floki.find(
                 nav,
                 ~s([data-account-scope] [data-testid="surface-nav-preview-block"])
               ) == []

        [block] = Floki.find(nav, ~s([data-testid="surface-nav-preview-block"]))

        [preview] = Floki.find(block, "a")
        assert Floki.text(preview) |> String.trim() == "Preview"

        [caption] = Floki.find(block, ~s([data-testid="surface-nav-preview-caption"]))
        assert Floki.text(caption) |> String.trim() == "Not tied to an Account"

        assert Floki.attribute(preview, "aria-describedby") == Floki.attribute(caption, "id")
        assert [id] = Floki.attribute(caption, "id")
        assert id == "surface-nav-preview-caption-#{layout}"
      end
    end

    test "Phase 177 sidebar nav order is Health, Deliveries, Inbound, Preview" do
      doc = render_shell(%{tenant_options: [], selected_tenant_id: nil})

      labels = doc |> nav("sidebar") |> Floki.find("a") |> link_labels()
      assert labels == ["Health", "Deliveries", "Inbound", "Preview"]
    end

    test "Phase 177 the topbar actions hold only the theme picker" do
      doc = render_shell(%{})

      [actions] = Floki.find(doc, ~s([data-testid="admin-shell-actions"]))
      assert Floki.find(actions, ~s([data-testid^="operator-account"])) == []
      assert Floki.find(actions, ~s(input[name="theme"])) != []
    end

    test "Phase 177 the group header is outside the topbar and inside the nav landmark" do
      doc = render_shell(%{})

      for layout <- ["sidebar", "mobile"] do
        assert [_] =
                 Floki.find(
                   nav(doc, layout),
                   ~s([data-testid="operator-account-switcher"])
                 )
      end

      [topbar] = Floki.find(doc, ~s([data-testid="admin-shell-topbar"]))
      assert Floki.find(topbar, ~s([data-testid="operator-account-context"])) == []
    end
  end

  describe "Phase 177 Preview scope chrome" do
    test "Phase 177 Preview direct entry shows the static scope label and no Account control",
         %{conn: conn} do
      {:ok, _view, html} = live(preview_conn(conn), scenario_path("?width=768"))
      {:ok, doc} = Floki.parse_fragment(html)

      for layout <- ["sidebar", "mobile"] do
        nav = nav(doc, layout)
        [label] = Floki.find(nav, ~s([data-testid="preview-scope-label"]))
        assert Floki.text(label) |> String.trim() == "Scoped to an Account"
        assert Floki.attribute(label, "tabindex") == []

        [group] = Floki.find(nav, ~s([data-account-scope][role="group"]))
        assert Floki.attribute(group, "aria-describedby") == []

        assert group
               |> Floki.find(~s([data-testid="surface-nav-scope-items"] a))
               |> link_labels() == ["Health", "Deliveries", "Inbound"]

        assert Floki.find(nav, ~s([data-testid="surface-nav-preview-block"])) != []
        assert Floki.find(nav, "details") == []
      end

      refute html =~ ~s(data-testid="operator-account)
    end

    test "Phase 177 Preview with a valid return context keeps Back first above the group", %{
      conn: conn
    } do
      {:ok, _view, html} =
        live(
          preview_conn(conn),
          scenario_path("?width=768&return_surface=overview&return_tenant_id=tenant-b")
        )

      {:ok, doc} = Floki.parse_fragment(html)
      nav = nav(doc, "sidebar")

      [first | _] = Floki.find(nav, "a")
      assert Floki.attribute(first, "data-testid") == ["preview-return-link"]

      back_position = position_in(nav, ~s([data-testid="preview-return-link"]))
      group_position = position_in(nav, ~s([data-account-scope]))
      assert back_position < group_position

      assert Floki.find(nav, ~s([data-testid="preview-scope-label"])) != []
      refute strip_hrefs(html) =~ "tenant-b"
    end
  end

  # -- helpers ---------------------------------------------------------------

  defp render_shell(overrides) do
    assigns = %{attrs: Map.merge(@base_attrs, overrides)}

    html =
      rendered_to_string(~H"""
      <Shell.shell {@attrs}>
        body
      </Shell.shell>
      """)

    {:ok, doc} = Floki.parse_fragment(html)
    doc
  end

  defp nav(doc, layout), do: Floki.find(doc, ~s([data-testid="surface-nav-#{layout}"]))

  defp link_labels(links), do: Enum.map(links, &(&1 |> Floki.text() |> String.trim()))

  defp preview_conn(conn),
    do: Plug.Test.init_test_session(conn, %{"mailables" => @fixture_mailables})

  defp scenario_path(query),
    do: "/dev/mail/MailglassAdmin.Fixtures.HappyMailer/welcome_default" <> query

  # Index of the first node matching `selector` in a depth-first walk of the
  # nav, so two selectors can be ordered by DOM position.
  defp position_in(nav, selector) do
    target = nav |> Floki.find(selector) |> List.first()

    nav
    |> flatten()
    |> Enum.find_index(&(&1 == target))
  end

  defp flatten(nodes) when is_list(nodes), do: Enum.flat_map(nodes, &flatten/1)

  defp flatten({_tag, _attrs, children} = node), do: [node | flatten(children)]

  defp flatten(_text), do: []

  defp strip_hrefs(html), do: Regex.replace(~r/href="[^"]*"/, html, ~s(href=""))
end
