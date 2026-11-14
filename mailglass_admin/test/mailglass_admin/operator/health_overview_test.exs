defmodule MailglassAdmin.Operator.HealthOverviewTest do
  @moduledoc """
  Phase 177 / OUTUX-06: structure, class-equality and help-tier proofs for the
  recomposed Health column, plus the copy-state proofs added by plan 177-05.
  """

  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, only: [render_component: 2]

  alias MailglassAdmin.Operator.HealthOverview

  @moduletag :phase177

  @source Path.expand("../../../lib/mailglass_admin/operator/health_overview.ex", __DIR__)
  @design_system Path.expand("../../../docs/design-system.md", __DIR__)
  @checked_at ~U[2026-10-28 12:00:00Z]

  defp issue(testid, count, opts \\ []) do
    label = Keyword.get(opts, :label, "Label #{testid}")

    %{
      count: count,
      label: label,
      help: "Help text for #{label}.",
      testid: testid,
      surface: Keyword.get(opts, :surface, :deliveries),
      path: Keyword.get(opts, :path, "/ops/mail?view=deliveries&#{testid}=1"),
      stale?: Keyword.get(opts, :stale?, false)
    }
  end

  defp ready_states do
    for key <- [:failed_ingest, :orphan_backlog, :delivery_activity, :inbound_activity],
        into: %{},
        do: {key, %{status: :ready, checked_at: @checked_at}}
  end

  defp render_overview(overrides \\ []) do
    assigns =
      Keyword.merge(
        [
          issues: [issue("health-a", 1), issue("health-b", 8, surface: :inbound)],
          activity: %{deliveries: %{total: 21}, inbound: %{total: 3}},
          states: ready_states(),
          deliveries_path: "/ops/mail?view=deliveries",
          inbound_path: "/ops/mail/inbound",
          window_copy: "Last 7 days",
          window_description: "Health looks at the last 7 days.",
          observed_at: @checked_at
        ],
        overrides
      )

    render_component(&HealthOverview.overview/1, assigns)
  end

  defp parse(html), do: Floki.parse_fragment!(html)

  defp find(tree, selector), do: Floki.find(tree, selector)

  defp classes(node), do: node |> Floki.attribute("class") |> List.first() |> String.split()

  defp attr(node, name), do: node |> Floki.attribute(name) |> List.first()

  defp testid(tid), do: "[data-testid='#{tid}']"

  defp row_classes(tree, testids) do
    for tid <- testids do
      [row] = find(tree, "li" <> testid(tid))
      [count] = find(row, testid(tid <> "-count"))
      [link] = find(row, testid(tid <> "-link"))
      {tid, classes(row), classes(count), classes(link)}
    end
  end

  test "Phase 177 Health renders one capped column with the observation group first" do
    tree = render_overview() |> parse()

    assert [layout] = find(tree, testid("operator-health-layout"))
    assert "operator-health-layout" in classes(layout)
    assert [column] = find(layout, testid("operator-health-column"))
    assert "operator-health-column" in classes(column)

    assert [observation] = find(column, testid("operator-health-observation"))
    assert attr(observation, "role") == "group"
    assert attr(observation, "aria-label") == "Health check period and freshness"
    refute "ml-auto" in classes(observation)
    refute "text-right" in classes(observation)

    [first | _] = Floki.children(column, include_text: false)
    assert attr(first, "data-testid") == "operator-health-observation"

    # DOM order equals visual order: observation, verdict, issues, activity.
    order =
      column
      |> Floki.find(
        "[data-testid='operator-health-observation'], [data-testid='operator-health-status'], [data-testid='operator-health-activity']"
      )
      |> Enum.map(&attr(&1, "data-testid"))

    assert order == [
             "operator-health-observation",
             "operator-health-status",
             "operator-health-activity"
           ]
  end

  test "Phase 177 Health observation group keeps period, freshness and Refresh together in order" do
    tree = render_overview() |> parse()
    [observation] = find(tree, testid("operator-health-observation"))

    ids =
      observation
      |> Floki.find(
        "[data-testid='operator-health-window'], #operator-health-window-help-trigger, [data-testid='operator-health-last-checked'], #operator-health-refresh"
      )
      |> Enum.map(&(attr(&1, "data-testid") || attr(&1, "id")))

    assert ids == [
             "operator-health-window",
             "operator-health-window-help-trigger",
             "operator-health-last-checked",
             "operator-health-refresh"
           ]

    [refresh] = find(observation, "#operator-health-refresh")
    assert attr(refresh, "phx-click") == "retry_health"
    refute attr(refresh, "aria-label")
    assert Floki.text(refresh) =~ "Refresh health"
    assert Floki.text(refresh) =~ "Refreshing…"

    # Both labels overlap in one grid cell so the width cannot jump; only the
    # loading label is hidden while idle.
    [idle, loading] = find(refresh, "span.grid > span")
    assert "[grid-area:1/1]" in classes(idle)
    assert "[grid-area:1/1]" in classes(loading)
    assert "invisible" in classes(loading)
    refute "invisible" in classes(idle)
  end

  test "Phase 177 Health freshness paragraph is not nested in a span (valid content model)" do
    tree = render_overview() |> parse()

    assert [_p] = find(tree, "div > p" <> testid("operator-health-last-checked"))
    assert find(tree, "span > p" <> testid("operator-health-last-checked")) == []
  end

  test "Phase 177 Health issue rows use one fixed count style with no mono and no heading size" do
    tree = render_overview() |> parse()

    assert [ul] = find(tree, "ul.divide-y")
    assert [_, _] = find(ul, "li")

    for tid <- ["health-a", "health-b"] do
      [count] = find(tree, testid(tid <> "-count"))
      cls = classes(count)

      for expected <- ["text-body", "font-bold", "tabular-nums", "text-base-content"] do
        assert expected in cls, "#{tid} count lacks #{expected}"
      end

      refute "mono" in cls
      refute "text-heading" in cls
    end
  end

  test "Phase 177 Health issue and activity links are 44px targets" do
    tree = render_overview() |> parse()

    for tid <- ["health-a-link", "health-b-link"] do
      [link] = find(tree, testid(tid))
      assert "inline-flex" in classes(link)
      assert "min-h-11" in classes(link)
    end

    for tid <- ["operator-health-outbound-activity", "operator-health-inbound-activity"] do
      [link] = find(tree, testid(tid))
      assert "inline-flex" in classes(link)
      assert "min-h-11" in classes(link)
    end
  end

  test "Phase 177 Health reversed counts render identical row classes and the same order" do
    ascending = [issue("health-a", 1), issue("health-b", 8, surface: :inbound)]
    reversed = [issue("health-a", 8), issue("health-b", 1, surface: :inbound)]

    asc_tree = render_overview(issues: ascending) |> parse()
    rev_tree = render_overview(issues: reversed) |> parse()

    order = fn tree ->
      tree |> find("ul.divide-y > li") |> Enum.map(&attr(&1, "data-testid"))
    end

    assert order.(asc_tree) == ["health-a", "health-b"]
    assert order.(rev_tree) == order.(asc_tree)

    ids = ["health-a", "health-b"]
    assert row_classes(asc_tree, ids) == row_classes(rev_tree, ids)
  end

  test "Phase 177 Health per-issue help is the tertiary element of each row" do
    tree = render_overview() |> parse()

    for tid <- ["health-a", "health-b"] do
      [row] = find(tree, "li" <> testid(tid))
      assert [help] = find(row, ".mg-field-help button")
      assert [link] = find(row, testid(tid <> "-link"))

      help_cls = classes(help)
      link_cls = classes(link)

      assert "text-secondary" in help_cls
      assert "h-6" in help_cls and "w-6" in help_cls
      refute "text-base-content" in help_cls
      refute "underline" in help_cls
      assert attr(help, "aria-label") == "Help for #{Floki.text(link) |> String.trim()}"

      assert "text-base-content" in link_cls
      assert "underline" in link_cls

      # The help comes after the label link in DOM order.
      flat = Floki.raw_html(row)
      {link_at, _} = :binary.match(flat, "data-testid=\"#{tid}-link\"")
      {help_at, _} = :binary.match(flat, "mg-field-help")
      assert link_at < help_at

      # The 16px glyph is the field_help default.
      assert [_] = find(help, "span.hero-information-circle, [class*='hero-information-circle']")
    end
  end

  test "Phase 177 Health persistent notices carry no live-region role and sit before activity" do
    states =
      Map.merge(ready_states(), %{
        orphan_backlog: %{status: :stale, checked_at: @checked_at},
        failed_ingest: %{status: :error, checked_at: nil}
      })

    html = render_overview(states: states)
    tree = parse(html)

    assert find(tree, "[role='status']") == []

    notices =
      find(
        tree,
        "[data-testid^='operator-health-stale-'], [data-testid^='operator-health-error-']"
      )

    assert length(notices) == 2

    for notice <- notices do
      assert {"p", _, _} = notice
      assert "mt-sm" in classes(notice)
    end

    {notice_at, _} = :binary.match(html, "operator-health-stale-orphan_backlog")
    {activity_at, _} = :binary.match(html, "data-testid=\"operator-health-activity\"")
    {ul_end, _} = :binary.match(html, "</ul>")
    assert ul_end < notice_at and notice_at < activity_at
  end

  test "Phase 177 Health Recent activity is a subordinate section below a hairline" do
    tree = render_overview() |> parse()

    assert [section] = find(tree, "section" <> testid("operator-health-activity"))

    for cls <- ["mt-lg", "border-t", "border-base-300", "pt-md"],
        do: assert(cls in classes(section))

    assert [h2] = find(section, "h2#operator-health-activity-title")
    for cls <- ["text-label", "font-bold", "text-secondary"], do: assert(cls in classes(h2))
    refute "text-base-content" in classes(h2)

    assert [wrapper] = find(section, "div.flex.flex-col")

    for cls <- ["gap-sm", "@[30rem]:flex-row", "@[30rem]:gap-xl"],
        do: assert(cls in classes(wrapper))

    for tid <- ["operator-health-outbound-activity", "operator-health-inbound-activity"] do
      [link] = find(section, testid(tid))
      [count] = find(link, "span.font-bold")
      assert "tabular-nums" in classes(count)
    end
  end

  test "Phase 177 Health shows no inbound row, notice or activity item without inbound states" do
    states = Map.delete(ready_states(), :inbound_activity)

    tree =
      render_overview(
        states: states,
        issues: [issue("health-a", 2)],
        activity: %{deliveries: %{total: 4}, inbound: nil}
      )
      |> parse()

    assert find(tree, testid("operator-health-inbound-activity")) == []
    assert find(tree, "[data-testid^='operator-health-stale-inbound']") == []
    assert find(tree, "[data-testid*='inbound_activity']") == []
    assert [_] = find(tree, testid("operator-health-outbound-activity"))
  end

  test "Phase 177 Health zero issues render no list" do
    tree = render_overview(issues: []) |> parse()

    assert find(tree, "ul") == []
    assert [_] = find(tree, testid("operator-health-status"))
  end

  test "Phase 177 Health a six digit count stays inside its own row count cell" do
    tree =
      render_overview(issues: [issue("health-a", 123_456), issue("health-b", 2)])
      |> parse()

    [big] = find(tree, testid("health-a-count"))
    assert Floki.text(big) |> String.trim() == "123456"
    assert "shrink-0" in classes(big)

    [row] = find(tree, "li" <> testid("health-a"))
    assert [_] = find(row, testid("health-a-count"))
    assert find(row, testid("health-b-count")) == []

    [label_cluster] = find(row, "div.min-w-0.flex-1")
    assert "flex-wrap" in classes(label_cluster)
  end

  defp text_of(html), do: html |> parse() |> Floki.text() |> String.replace(~r/\s+/, " ")

  # Visible sentence text: the timestamp tooltip is aria-hidden chrome, not copy,
  # and the <time> element's trailing source whitespace is not a rendered space.
  defp visible_text(node) do
    node
    |> Floki.filter_out("[role=tooltip]")
    |> Floki.text()
    |> String.replace(~r/\s+/, " ")
    |> String.replace(" .", ".")
    |> String.trim()
  end

  defp with_state(panel, status) do
    Map.put(ready_states(), panel, %{status: status, checked_at: @checked_at})
  end

  @stale_notices %{
    failed_ingest:
      "Webhook processing wasn't refreshed. Showing results from 2026-10-28 12:00:00 UTC.",
    orphan_backlog:
      "Unmatched events weren't refreshed. Showing results from 2026-10-28 12:00:00 UTC.",
    delivery_activity:
      "Outbound activity and delivery results weren't refreshed. Showing results from 2026-10-28 12:00:00 UTC.",
    inbound_activity:
      "Inbound activity and processing results weren't refreshed. Showing results from 2026-10-28 12:00:00 UTC."
  }

  @unavailable_notices %{
    failed_ingest: "Webhook processing couldn't be loaded.",
    orphan_backlog: "Unmatched events couldn't be loaded.",
    delivery_activity: "Outbound activity and delivery results couldn't be loaded.",
    inbound_activity: "Inbound activity and processing results couldn't be loaded."
  }

  test "Phase 177 Health copy: issues with an incomplete check say what to do" do
    text = render_overview(states: with_state(:orphan_backlog, :unavailable)) |> text_of()

    assert text =~ "Needs attention"
    assert text =~ "Some checks couldn't be updated. Refresh to try again."
    refute text =~ "could not be updated"
  end

  test "Phase 177 Health copy: an incomplete check with no issues is not an all-clear" do
    text =
      render_overview(issues: [], states: with_state(:failed_ingest, :unavailable)) |> text_of()

    assert text =~ "Health check incomplete"
    assert text =~ "Refresh to try again."
    refute text =~ "No issues found"
  end

  test "Phase 177 Health copy: a complete check with activity and no issues names the period" do
    text = render_overview(issues: []) |> text_of()

    assert text =~ "No issues found"
    assert text =~ "No recorded problems in this period."
  end

  test "Phase 177 Health copy: no activity is a single neutral line with the links kept" do
    tree =
      render_overview(
        issues: [],
        activity: %{deliveries: %{total: 0}, inbound: %{total: 0}}
      )
      |> parse()

    [status] = find(tree, testid("operator-health-status"))
    status_text = status |> Floki.text() |> String.replace(~r/\s+/, " ") |> String.trim()

    assert status_text == "No mail activity in this period"
    assert find(status, "p") == []
    refute Floki.text(tree) =~ "No recent mail activity"

    assert [_] = find(tree, testid("operator-health-outbound-activity"))

    linked = tree |> Floki.text() |> String.replace(~r/\s+/, " ")
    assert linked =~ "0 deliveries updated"
    assert linked =~ "0 messages received"
  end

  test "Phase 177 Health copy: a stale row is tagged Not refreshed" do
    text =
      render_overview(
        states: with_state(:orphan_backlog, :stale),
        issues: [issue("health-a", 1, stale?: true)]
      )
      |> text_of()

    assert text =~ "Not refreshed"
    refute text =~ "Last retrieved"
  end

  test "Phase 177 Health copy: each panel has its own stale notice with the timestamp" do
    for {panel, sentence} <- @stale_notices do
      html = render_overview(states: with_state(panel, :stale))
      [notice] = html |> parse() |> find(testid("operator-health-stale-#{panel}"))
      notice_text = visible_text(notice)

      assert notice_text == sentence
      refute notice_text =~ "last retrieved"
    end
  end

  test "Phase 177 Health copy: each panel has its own unavailable notice" do
    for {panel, sentence} <- @unavailable_notices do
      html = render_overview(states: with_state(panel, :unavailable))
      [notice] = html |> parse() |> find(testid("operator-health-unavailable-#{panel}"))
      notice_text = visible_text(notice)

      assert notice_text == sentence
    end
  end

  test "Phase 177 Health copy: stale or unavailable panels never read No issues found" do
    for panel <- Map.keys(@stale_notices), status <- [:stale, :unavailable] do
      text = render_overview(issues: [], states: with_state(panel, status)) |> text_of()

      refute text =~ "No issues found", "#{panel} #{status} rendered an all-clear"
      assert text =~ "Health check incomplete"
    end
  end

  test "Phase 177 Health copy: unavailable activity reads Outbound or Inbound activity unavailable" do
    text =
      render_overview(activity: %{deliveries: nil, inbound: nil}, issues: []) |> text_of()

    assert text =~ "Outbound activity unavailable"
    assert text =~ "Inbound activity unavailable"
    refute text =~ " Activity unavailable"
  end

  test "Phase 177 Health copy: notice text is a closed clause set, not interpolated panel names" do
    source = File.read!(@source)

    assert source =~ "defp notice_copy("
    refute source =~ ~S|panel_name(panel)}:|
    refute source =~ "Last retrieved"
  end

  test "Phase 177 Health design-system guide documents the observation group and the empty verdict" do
    guide = @design_system |> File.read!() |> String.replace(~r/\s+/, " ")

    assert guide =~ "period and the last-checked timestamp are both observation basis"
    assert guide =~ "with Refresh adjacent to the timestamp"
    assert guide =~ "No activity shows a neutral “No mail activity in this period”."

    refute guide =~ "stays separate"
    refute guide =~ "No recent mail activity"
  end

  test "Phase 177 Health markup has no order, row-reverse or viewport layout classes" do
    source = File.read!(@source)

    refute source =~ ~r/(^|[ "{])order-/m
    refute source =~ ~r/(^|[ "{])(sm|lg):/m
    refute source =~ "flex-row-reverse"
    refute source =~ ~s(role="status")
    refute source =~ "max-w-2xl"
  end
end
