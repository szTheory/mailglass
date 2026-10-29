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

  describe "Phase 177 Account header variants" do
    test "Phase 177 Account zero options renders static No Accounts yet" do
      doc = render_shell(%{tenant_options: [], selected_tenant_id: nil, tenant_state: :none})

      for layout <- ["sidebar", "mobile"] do
        header = header(doc, layout)
        assert text(header) =~ "Account"
        assert text(header) =~ "No Accounts yet"
        assert_no_picker(header)
      end
    end

    test "Phase 177 Account one option renders static text with no picker" do
      one = [%{id: "acme", label: "Acme"}]
      doc = render_shell(%{tenant_options: one})

      for layout <- ["sidebar", "mobile"] do
        header = header(doc, layout)
        assert text(header) =~ "Acme"
        refute text(header) =~ "No Accounts yet"
        assert_no_picker(header)
      end
    end

    test "Phase 177 Account one option and none selected shows that option as static text" do
      one = [%{id: "acme", label: "Acme"}]
      doc = render_shell(%{tenant_options: one, selected_tenant_id: nil})

      header = header(doc, "sidebar")
      assert text(header) =~ "Acme"
      assert_no_picker(header)
    end

    test "Phase 177 Account one option with select_required prompts instead of naming it" do
      one = [%{id: "acme", label: "Acme"}]

      doc =
        render_shell(%{
          tenant_options: one,
          selected_tenant_id: nil,
          tenant_state: :select_required
        })

      for layout <- ["sidebar", "mobile"] do
        header = header(doc, layout)
        [summary] = Floki.find(header, ~s([data-testid="operator-account-switcher"]))
        assert Floki.attribute(summary, "aria-label") == ["Choose an Account"]

        [label] = Floki.find(header, ~s([data-testid="operator-account-label"]))
        assert text(label) == "Choose an Account"
        refute hd(Floki.attribute(label, "class")) =~ "font-bold"

        # The sole Account stays reachable as a menu item, never as the scope.
        assert [option] = Floki.find(header, ~s([data-testid="operator-account-option"]))
        assert Floki.attribute(option, "data-account-id") == ["acme"]
        assert Floki.find(header, ~s([data-testid="operator-account-id"])) == []
      end
    end

    test "Phase 177 Account selected Account missing from the sole option keeps the picker" do
      listed = [%{id: "busy-account", label: "Busy Account"}]

      doc =
        render_shell(%{
          tenant_options: listed,
          selected_tenant_id: "quiet-account",
          account_labels: %{},
          tenant_state: :selected
        })

      for layout <- ["sidebar", "mobile"] do
        header = header(doc, layout)
        [summary] = Floki.find(header, ~s([data-testid="operator-account-switcher"]))
        assert Floki.attribute(summary, "aria-label") == ["Change Account: quiet-account"]

        assert [option] = Floki.find(header, ~s([data-testid="operator-account-option"]))
        assert Floki.attribute(option, "data-account-id") == ["busy-account"]
        assert Floki.attribute(option, "aria-current") == []
      end
    end

    test "Phase 177 Account one option that is the selected Account stays static" do
      one = [%{id: "acme", label: "Acme"}]
      doc = render_shell(%{tenant_options: one, tenant_state: :selected})

      header = header(doc, "sidebar")
      assert text(header) =~ "Acme"
      assert_no_picker(header)
    end

    test "Phase 177 Account two options with one selected renders the switcher" do
      doc = render_shell(%{})

      for layout <- ["sidebar", "mobile"] do
        header = header(doc, layout)

        [summary] = Floki.find(header, ~s([data-testid="operator-account-switcher"]))
        assert Floki.attribute(summary, "aria-label") == ["Change Account: Acme"]

        assert [_] = Floki.find(header, "details > summary")
        assert [list] = Floki.find(header, ~s(ul[aria-label="Available Accounts"]))
        assert Floki.attribute(list, "aria-label") == ["Available Accounts"]
        assert Floki.find(header, ".hero-chevron-down") != []

        options = Floki.find(header, ~s([data-testid="operator-account-option"]))

        assert Enum.map(options, &(&1 |> Floki.attribute("data-account-id") |> hd())) ==
                 ["acme", "fjordline-aps"]

        for option <- options do
          [id] = Floki.attribute(option, "data-account-id")

          assert [Shell.tenant_switch_path("/ops/mail?tenant_id=acme", id)] ==
                   Floki.attribute(option, "href")

          assert hd(Floki.attribute(option, "class")) =~ "min-h-11"
        end
      end
    end

    test "Phase 177 Account two options with none selected prompts Choose an Account" do
      doc =
        render_shell(%{selected_tenant_id: nil, tenant_state: :select_required})

      for layout <- ["sidebar", "mobile"] do
        header = header(doc, layout)
        [summary] = Floki.find(header, ~s([data-testid="operator-account-switcher"]))
        assert Floki.attribute(summary, "aria-label") == ["Choose an Account"]

        assert text(Floki.find(header, ~s([data-testid="operator-account-label"]))) =~
                 "Choose an Account"
      end
    end

    test "Phase 177 Account Inbound unavailable never reads No Accounts yet" do
      unavailable = %{tenant_options: [], tenant_state: :unavailable}

      doc = render_shell(Map.merge(unavailable, %{selected_tenant_id: nil}))
      header = header(doc, "sidebar")
      refute text(header) =~ "No Accounts yet"
      assert text(header) =~ "Choose an Account"
      assert_no_picker(header)

      doc = render_shell(unavailable)
      header = header(doc, "sidebar")
      refute text(header) =~ "No Accounts yet"
      assert text(header) =~ "Acme"
      assert_no_picker(header)
    end

    test "Phase 177 Account long Unicode HTML-looking label wraps and is escaped" do
      label = "Fjordline A/S — ܐܒܓ 日本語 🚢 <b>x</b> Logistics International Holdings"
      options = [%{id: "fjordline-aps", label: label}, %{id: "acme", label: "Acme"}]

      doc =
        render_shell(%{
          tenant_options: options,
          selected_tenant_id: "fjordline-aps",
          account_labels: %{"fjordline-aps" => label}
        })

      for layout <- ["sidebar", "mobile"] do
        header = header(doc, layout)
        [name] = Floki.find(header, ~s([data-testid="operator-account-label"]))
        assert text(name) == label
        assert Floki.find(header, "b") == []

        classes = hd(Floki.attribute(name, "class"))
        assert classes =~ "break-words"
        refute classes =~ "truncate"
        refute classes =~ "mg-scope-identity"
      end
    end

    test "Phase 177 Account every id in a full operator page is unique" do
      doc = render_shell(%{})
      ids = doc |> Floki.find("[id]") |> Enum.flat_map(&Floki.attribute(&1, "id"))

      assert ids != []
      assert ids == Enum.uniq(ids), "duplicate ids: #{inspect(ids -- Enum.uniq(ids))}"
    end

    test "Phase 177 Account switch status ids and JS targets carry the layout" do
      doc = render_shell(%{})

      for layout <- ["sidebar", "mobile"] do
        header = header(doc, layout)

        statuses = Floki.find(header, ~s([data-testid="operator-account-switch-status"]))
        assert [status] = statuses
        assert Floki.attribute(status, "id") == ["operator-account-switch-status-#{layout}-1"]
        assert text(status) == "Switching to Fjordline…"
        assert Floki.attribute(status, "aria-live") == ["polite"]

        options = Floki.find(header, ~s([data-testid="operator-account-option"]))

        for option <- options, id <- Floki.attribute(option, "phx-click") do
          assert id =~ "operator-account-switch-status-#{layout}-"
        end
      end
    end

    test "Phase 177 Account scope description is derived from the rendered items" do
      full = render_shell(%{})
      assert description(full, "sidebar") == "Applies to Health, Deliveries and Inbound."
      assert description(full, "mobile") == "Applies to Health, Deliveries and Inbound."

      no_inbound = render_shell(%{inbound_available?: false})

      for layout <- ["sidebar", "mobile"] do
        assert description(no_inbound, layout) == "Applies to Health and Deliveries."
        refute description(no_inbound, layout) =~ "Inbound"
        refute nav(no_inbound, layout) |> text() =~ "Inbound"
      end
    end

    test "Phase 177 Account group is described by the description span" do
      doc = render_shell(%{})
      [group] = doc |> nav("sidebar") |> Floki.find("[data-account-scope]")
      [desc_id] = Floki.attribute(group, "aria-describedby")
      assert desc_id == "surface-nav-scope-desc-sidebar"
      assert [span] = Floki.find(group, ~s([id="#{desc_id}"]))
      assert hd(Floki.attribute(span, "class")) =~ "sr-only"
    end

    test "Phase 177 Account control is neutral and never disabled" do
      for overrides <- [
            %{},
            %{tenant_options: [], selected_tenant_id: nil, tenant_state: :none},
            %{tenant_options: [%{id: "acme", label: "Acme"}]},
            %{selected_tenant_id: nil}
          ] do
        doc = render_shell(overrides)

        for layout <- ["sidebar", "mobile"] do
          header = header(doc, layout)
          html = Floki.raw_html(header)

          refute html =~ "primary"
          refute html =~ "disabled"
          refute html =~ "aria-disabled"
        end
      end
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

  defp header(doc, layout) do
    Floki.find(doc, ~s([id="surface-nav-scope-header-#{layout}"]))
  end

  defp text(nodes),
    do: nodes |> Floki.text(sep: " ") |> String.replace(~r/\s+/, " ") |> String.trim()

  defp description(doc, layout) do
    doc
    |> nav(layout)
    |> Floki.find(~s([data-testid="surface-nav-scope-description"]))
    |> text()
  end

  defp assert_no_picker(header) do
    assert Floki.find(header, "details") == []
    assert Floki.find(header, ".hero-chevron-down") == []
    assert Floki.find(header, ~s([data-testid="operator-account-option"])) == []
    assert Floki.find(header, ~s([data-testid="operator-account-switcher"])) == []
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
