defmodule MailglassAdmin.Phase182JourneyTest do
  @moduledoc """
  Required-lane proof of the "password reset never arrived" journey (Phase 182,
  BRADM-01, D-20). This file grows one describe per step of the journey across the
  Phase 182 plans; this plan owns the summary.

  The summary buckets every delivery by `MailglassAdmin.StatusMap.delivery_class/1`
  (D-07): Needs attention is failed + delayed + not sent, Delivered is delivered,
  Awaiting confirmation is sent (queued included). A bounce followed by an open is
  Failed, so it is counted under Needs attention and never under Delivered.
  """

  use MailglassAdmin.LiveViewCase, async: false

  alias Mailglass.Operator.Deliveries
  alias Mailglass.Outbound.Delivery
  alias MailglassAdmin.OperatorLive
  alias MailglassAdmin.StatusMap
  alias MailglassAdmin.TestSupport.OperatorFixtures

  @tenant_id "browser-tenant"
  @base_path "/ops/mail"
  @attention_classes [:failed, :delayed, :not_sent]
  @undetermined "Status cannot be fully determined with this mailglass version."
  @theme_cookie MailglassAdmin.Theme.cookie_name()

  # {label, delivery attrs, bucket the single row must land in}. One row per class,
  # plus the rows D-07 says leave Needs attention (a complaint or an unsubscribe with
  # no delivery problem behind it) and queued, which is Awaiting.
  @bucket_rows [
    {"sent", %{last_event_type: :sent}, :awaiting},
    {"queued", %{status: :queued, last_event_type: :queued}, :awaiting},
    {"delivered", %{last_event_type: :delivered, delivered_at: :hours_ago_2, terminal: true},
     :delivered},
    {"delayed", %{last_event_type: :deferred}, :attention},
    {"failed", %{last_event_type: :bounced, bounced_at: :hours_ago_2, terminal: true},
     :attention},
    {"not sent", %{last_event_type: :suppressed, suppressed_at: :hours_ago_2, terminal: true},
     :attention},
    {"complained with no delivery problem",
     %{last_event_type: :complained, complained_at: :hours_ago_2, terminal: true}, :awaiting},
    {"unsubscribed with no delivery problem", %{last_event_type: :unsubscribed}, :awaiting}
  ]

  describe "summary (D-07)" do
    test "counts every seeded delivery under the bucket its class names", %{conn: conn} do
      %{ids: ids} = OperatorFixtures.seed_phase182_journey!()

      classes =
        Map.new(ids, fn {case_id, id} ->
          row = Deliveries.get_delivery(%{tenant_id: @tenant_id, delivery_id: id}, [])
          {case_id, StatusMap.delivery_class(row)}
        end)

      expected_attention =
        Enum.count(classes, fn {_case, class} -> class in @attention_classes end)

      expected_delivered = Enum.count(classes, fn {_case, class} -> class == :delivered end)
      expected_awaiting = Enum.count(classes, fn {_case, class} -> class == :sent end)

      # Non-vacuity: the seed spans every bucket, and the bounce then open row is Failed.
      assert expected_attention > 0 and expected_delivered > 0 and expected_awaiting > 0
      assert classes.bounce_then_open == :failed
      assert expected_attention + expected_delivered + expected_awaiting == map_size(ids)

      {:ok, view, _html} = live(operator_conn(conn), deliveries_path())
      html = render(view)

      assert summary_count(html, :attention) == expected_attention
      assert summary_count(html, :delivered) == expected_delivered
      assert summary_count(html, :awaiting) == expected_awaiting
    end

    test "a bounce followed by an open is Needs attention, not Delivered", %{conn: conn} do
      OperatorFixtures.reset!()

      insert_delivery!(%{
        recipient: "pw-bounce-then-open@example.com",
        status: :sent,
        last_event_type: :opened,
        bounced_at: DateTime.add(DateTime.utc_now(), -5, :hour),
        terminal: true
      })

      {:ok, view, _html} = live(operator_conn(conn), deliveries_path())
      html = render(view)

      assert summary_count(html, :attention) == 1
      assert summary_count(html, :delivered) == 0
      assert summary_count(html, :awaiting) == 0
    end
  end

  describe "summary re-bucket (C-16)" do
    for {label, attrs, bucket} <- @bucket_rows do
      test "#{label} lands in #{bucket} and nowhere else", %{conn: conn} do
        OperatorFixtures.reset!()
        insert_delivery!(resolve_times(unquote(Macro.escape(attrs))))

        {:ok, view, _html} = live(operator_conn(conn), deliveries_path())
        html = render(view)

        counts = Map.new([:attention, :delivered, :awaiting], &{&1, summary_count(html, &1)})

        assert counts ==
                 Map.merge(%{attention: 0, delivered: 0, awaiting: 0}, %{unquote(bucket) => 1}),
               "#{unquote(label)} should count once under #{unquote(bucket)}, got #{inspect(counts)}"
      end
    end

    test "Needs attention is exactly failed, delayed and not sent", %{conn: conn} do
      OperatorFixtures.reset!()

      for {label, attrs, _bucket} <- @bucket_rows do
        slug = label |> String.replace(~r/[^a-z]+/, "-") |> String.trim("-")

        insert_delivery!(
          attrs
          |> resolve_times()
          |> Map.merge(%{
            recipient: "bucket-#{slug}@example.com",
            provider_message_id: "pm_bucket_#{slug}"
          })
        )
      end

      {:ok, view, _html} = live(operator_conn(conn), deliveries_path())
      html = render(view)

      assert summary_count(html, :attention) == 3
      assert summary_count(html, :delivered) == 1
      assert summary_count(html, :awaiting) == 4
    end
  end

  describe "summary without lifecycle keys (D-06)" do
    test "an outcome group from an older core reads undetermined, never a count" do
      three_field_group = %{
        status: :sent,
        last_event_type: :opened,
        delivery_confirmed: false,
        count: 1
      }

      assert {:undetermined, @undetermined} =
               OperatorLive.delivery_summary(%{outcome_groups: [three_field_group]})
    end

    test "one group missing the key makes the whole summary undetermined" do
      complete = %{
        status: :sent,
        last_event_type: :sent,
        delivery_confirmed: false,
        bounced_at: nil,
        terminal: nil,
        complained_at: nil,
        suppressed_at: nil,
        count: 2
      }

      old = Map.drop(complete, [:bounced_at, :terminal, :complained_at, :suppressed_at])

      assert {:undetermined, @undetermined} =
               OperatorLive.delivery_summary(%{outcome_groups: [complete, old]})
    end

    test "groups that carry the keys, and an empty page, keep the three counts" do
      complete = %{
        status: :sent,
        last_event_type: :opened,
        delivery_confirmed: false,
        bounced_at: true,
        terminal: true,
        complained_at: nil,
        suppressed_at: nil,
        count: 3
      }

      for page <- [%{outcome_groups: [complete]}, %{outcome_groups: []}, %{}] do
        assert [{:delivered, _, _, _}, {:attention, _, _, _}, {:awaiting, _, _, _}] =
                 OperatorLive.delivery_summary(page)
      end

      assert [{:delivered, _, 0, _}, {:attention, _, 3, _}, {:awaiting, _, 0, _}] =
               OperatorLive.delivery_summary(%{outcome_groups: [complete]})
    end
  end

  describe "row, Quick view and Full detail (BRADM-01)" do
    test "a bounce then open row reads Failed with one aria-hidden mark", %{conn: conn} do
      %{ids: ids} = OperatorFixtures.seed_phase182_journey!()

      {:ok, view, _html} = live(operator_conn(conn), deliveries_path())
      html = render(view)

      for layout <- [:mobile, :desktop] do
        [badge] = row_badges(html, layout, ids.bounce_then_open)

        assert Floki.attribute(badge, "data-mg-status") == ["failed"]
        assert badge |> Floki.text() |> String.trim() == "Failed"
        assert [svg] = Floki.find(badge, "svg")
        assert Floki.attribute(svg, "aria-hidden") == ["true"]
      end
    end

    test "every seeded row shows the word of its class", %{conn: conn} do
      %{ids: ids} = OperatorFixtures.seed_phase182_journey!()

      {:ok, view, _html} = live(operator_conn(conn), deliveries_path())
      html = render(view)

      expected = %{
        sent_no_report: "Sent",
        bounce: "Failed",
        bounce_then_open: "Failed",
        nil_reason_bounce: "Failed",
        deferred: "Delayed",
        suppressed: "Not sent",
        complained: "Sent",
        delivered: "Delivered",
        queued: "Queued"
      }

      assert map_size(expected) == map_size(ids)

      for {case_id, word} <- expected do
        assert [badge] = row_badges(html, :mobile, Map.fetch!(ids, case_id))
        assert badge |> Floki.text() |> String.trim() == word, "#{case_id} should read #{word}"
      end
    end

    test "Quick view shows the one-line verdict and no next step", %{conn: conn} do
      %{ids: ids} = OperatorFixtures.seed_phase182_journey!()

      {:ok, view, _html} = live(operator_conn(conn), deliveries_path())

      view
      |> element("#operator-delivery-mobile-#{ids.bounce_then_open}")
      |> render_click()

      html = render(view)
      [quick] = html |> Floki.parse_document!() |> Floki.find("[data-testid=operator-quick-view]")
      [line] = Floki.find(quick, "[data-testid=delivery-verdict-line]")

      assert Floki.attribute(line, "data-verdict-class") == ["failed"]
      assert line |> Floki.text() |> String.contains?("Failed")
      assert [_] = Floki.find(line, "svg[aria-hidden=true]")
      refute Floki.text(quick) =~ "Next step"
    end

    test "Full detail leads with the verdict, then the timeline, with a next step", %{conn: conn} do
      %{ids: ids} = OperatorFixtures.seed_phase182_journey!()

      {:ok, _view, html} = live(operator_conn(conn), detail_path(ids.bounce_then_open))

      {verdict_at, _} = :binary.match(html, ~s(id="delivery-detail-verdict"))
      {timeline_at, _} = :binary.match(html, ~s(data-testid="operator-timeline"))
      assert verdict_at < timeline_at

      [verdict] =
        html |> Floki.parse_document!() |> Floki.find("#delivery-detail-verdict")

      assert Floki.attribute(verdict, "data-verdict-class") == ["failed"]
      assert [_] = Floki.find(verdict, "h4")
      assert verdict |> Floki.find("h4") |> Floki.text() == "Next step"
      assert Floki.text(verdict) =~ "Check the address for a typo."
    end

    test "a bounce shows the recorded cause and a nil-reason bounce shows exactly the fallback",
         %{
           conn: conn
         } do
      %{ids: ids} = OperatorFixtures.seed_phase182_journey!()

      {:ok, _view, with_reason} = live(operator_conn(conn), detail_path(ids.bounce))
      {:ok, _view, after_open} = live(operator_conn(conn), detail_path(ids.bounce_then_open))
      {:ok, _view, without_reason} = live(operator_conn(conn), detail_path(ids.nil_reason_bounce))

      # A recorded reason shows its own sentence, also after a later open.
      for html <- [with_reason, after_open] do
        assert verdict_cause(html) == "The provider reported: invalid address."
      end

      # No reason was recorded, so the verdict says exactly that and invents no cause.
      assert verdict_cause(without_reason) == "No reason was recorded for this email."
      refute verdict_text(without_reason) =~ "The provider reported"
    end

    test "Technical details is a collapsed native details element", %{conn: conn} do
      %{ids: ids} = OperatorFixtures.seed_phase182_journey!()

      {:ok, _view, html} = live(operator_conn(conn), detail_path(ids.sent_no_report))

      [details] =
        html |> Floki.parse_document!() |> Floki.find("details#delivery-detail-technical")

      assert Floki.attribute(details, "open") == []
      assert details |> Floki.find("summary") |> Floki.text() =~ "Technical details"
    end

    test "a Sent row says sent is not delivered, with the provider and a next step", %{conn: conn} do
      %{ids: ids} = OperatorFixtures.seed_phase182_journey!()

      {:ok, _view, html} = live(operator_conn(conn), detail_path(ids.sent_no_report))
      text = verdict_text(html)

      assert text =~ "Sent is not delivered"
      assert text =~ "Sent with Postmark. Mailglass has recorded no delivery report"
      assert text =~ "Next step"
    end

    test "a queued row says it was not handed to the provider and never claims a handoff", %{
      conn: conn
    } do
      %{ids: ids} = OperatorFixtures.seed_phase182_journey!()

      {:ok, _view, html} = live(operator_conn(conn), detail_path(ids.queued))
      text = verdict_text(html)

      assert text =~ "Not handed to the provider yet."
      refute text =~ "Sent with"
      assert String.downcase(text) =~ "sent is not delivered"
    end

    test "a delivered row names its time with a zone", %{conn: conn} do
      %{ids: ids} = OperatorFixtures.seed_phase182_journey!()

      {:ok, _view, html} = live(operator_conn(conn), detail_path(ids.delivered))
      text = verdict_text(html)

      assert text =~ "Delivered at"
      # The timestamp renders its zoned value, then the sentence resumes after it.
      assert text =~
               ~r/Delivered at [A-Z][a-z]{2} \d.* UTC.*: the receiving server accepted this email\./

      assert text =~ "Delivered is not the same as read."
    end

    test "a verdict component given a three-field row shows the D-06 sentence and no next step" do
      row = %{
        id: "d1",
        status: :sent,
        last_event_type: :opened,
        delivery_confirmed: false,
        provider: "postmark"
      }

      verdict = MailglassAdmin.Copy.delivery_verdict(row, %{})

      for form <- [:full, :line] do
        html =
          render_component(&MailglassAdmin.Components.delivery_verdict/1,
            verdict: verdict,
            form: form,
            id: "three-field-#{form}"
          )

        assert html =~ @undetermined
        refute html =~ "Next step"
        refute html =~ "data-mg-status"
        refute html =~ "<svg"
      end

      badge =
        render_component(&MailglassAdmin.Components.delivery_badge/1, row: row)

      assert badge =~ "Unknown"
      refute badge =~ "data-mg-status"
    end
  end

  describe "search to verdict (BRADM-01)" do
    test "the labelled email search leads the page and sits outside the filter panel", %{
      conn: conn
    } do
      OperatorFixtures.seed_phase182_journey!()

      {:ok, _view, html} = live(operator_conn(conn), deliveries_path())
      doc = Floki.parse_document!(html)

      assert [input] = Floki.find(doc, "form#operator-filters input#filters_search")
      assert Floki.attribute(input, "type") == ["search"]
      assert Floki.attribute(input, "name") == ["filters[search]"]

      assert [label] = Floki.find(doc, "label[for=filters_search]")
      assert label |> Floki.text() |> String.trim() == "Email address"
      assert doc |> Floki.find("#filters_search-help") |> Floki.text() =~ "Also matches subjects."

      # DOM order: the search comes before the collapsible panel, and not inside it.
      {search_at, _} = :binary.match(html, ~s(id="filters_search"))
      {panel_at, _} = :binary.match(html, ~s(id="operator-filter-panel"))
      assert search_at < panel_at
      assert Floki.find(doc, "#operator-filter-panel #filters_search") == []

      # The panel stays collapsed below md through a class, never an inline display.
      assert [panel] = Floki.find(doc, "#operator-filter-panel")
      assert class_tokens(panel) == ["hidden", "md:block"]
      assert Floki.attribute(panel, "style") == []
    end

    test "typing the customer's address patches ?search= and narrows to one delivery", %{
      conn: conn
    } do
      %{ids: ids} = OperatorFixtures.seed_phase182_journey!()
      address = "pw-bounce-then-open@example.com"

      {:ok, view, html} = live(operator_conn(conn), deliveries_path())
      assert row_count(html, :cards) == map_size(ids)
      assert row_count(html, :table) == map_size(ids)

      view
      |> form("#operator-filters", filters: %{"search" => address})
      |> render_change()

      path = assert_patch(view)

      assert %{"search" => ^address} =
               path |> URI.parse() |> Map.fetch!(:query) |> URI.decode_query()

      html = render(view)
      assert row_count(html, :cards) == 1
      assert row_count(html, :table) == 1
      assert [badge] = row_badges(html, :mobile, ids.bounce_then_open)
      assert badge |> Floki.text() |> String.trim() == "Failed"

      # The attention count reads 1: a bounce then an open is Needs attention.
      assert summary_count(html, :attention) == 1
      assert summary_count(html, :delivered) == 0
      assert summary_count(html, :awaiting) == 0
    end

    test "search, row, Quick view and Full detail reach the verdict with a zone on every time", %{
      conn: conn
    } do
      %{ids: ids} = OperatorFixtures.seed_phase182_journey!()
      id = ids.bounce_then_open

      {:ok, view, _html} = live(operator_conn(conn), deliveries_path())

      view
      |> form("#operator-filters", filters: %{"search" => "pw-bounce-then-open@example.com"})
      |> render_change()

      assert_patch(view)

      view |> element("#operator-delivery-mobile-#{id}") |> render_click()
      html = render(view)
      [quick] = html |> Floki.parse_document!() |> Floki.find("[data-testid=operator-quick-view]")
      assert [line] = Floki.find(quick, "[data-testid=delivery-verdict-line]")
      assert Floki.attribute(line, "data-verdict-class") == ["failed"]
      refute Floki.text(quick) =~ "Next step"

      view |> element("[data-testid=operator-quick-view-full]") |> render_click()
      html = render(view)

      {verdict_at, _} = :binary.match(html, ~s(id="delivery-detail-verdict"))
      {timeline_at, _} = :binary.match(html, ~s(data-testid="operator-timeline"))
      assert verdict_at < timeline_at
      assert verdict_text(html) =~ "Next step"

      times = html |> Floki.parse_document!() |> Floki.find("time")
      assert length(times) >= 3

      for time <- times do
        visible = time |> Floki.text() |> String.trim()
        assert String.ends_with?(visible, " UTC"), "time #{inspect(visible)} lost its zone"
      end
    end

    test "the search and the verdict are never behind a hidden or closed ancestor", %{conn: conn} do
      %{ids: ids} = OperatorFixtures.seed_phase182_journey!()

      {:ok, _view, list_html} = live(operator_conn(conn), deliveries_path())
      list = Floki.parse_document!(list_html)

      assert [] = hidden_ancestors(list, "filters_search")
      assert {:ok, _trail} = ancestor_trail(list, "filters_search")

      {:ok, _view, detail_html} = live(operator_conn(conn), detail_path(ids.bounce_then_open))
      detail = Floki.parse_document!(detail_html)

      assert {:ok, _trail} = ancestor_trail(detail, "delivery-detail-verdict")
      assert [] = hidden_ancestors(detail, "delivery-detail-verdict")

      # 44px touch targets: the search field and every row's open control.
      assert [search] = Floki.find(list, "#filters_search")
      assert "min-h-11" in class_tokens(search)

      for layout <- [:mobile, :desktop], {_case, id} <- ids do
        assert [control] = Floki.find(list, "#operator-delivery-#{layout}-#{id}")
        assert "min-h-11" in class_tokens(control), "#{layout} open control for #{id}"
      end
    end

    test "the detector flags a hidden ancestor and a closed details element", %{} do
      hidden = Floki.parse_document!(~s(<div class="hidden md:block"><p id="x">a</p></div>))
      attr = Floki.parse_document!(~s(<div hidden><p id="x">a</p></div>))
      closed = Floki.parse_document!(~s(<details><summary>s</summary><p id="x">a</p></details>))

      open =
        Floki.parse_document!(~s(<details open><summary>s</summary><p id="x">a</p></details>))

      clean = Floki.parse_document!(~s(<div class="md:hidden"><p id="x">a</p></div>))

      assert [_] = hidden_ancestors(hidden, "x")
      assert [_] = hidden_ancestors(attr, "x")
      assert [_] = hidden_ancestors(closed, "x")
      assert [] = hidden_ancestors(open, "x")
      assert [] = hidden_ancestors(clean, "x")
    end
  end

  describe "theme dead render (D-20)" do
    # The LiveViewTest HTML omits the root layout, so the document is read with get/2.
    for {cookie, count, value} <- [
          {"dark", 1, "mailglass-dark"},
          {"light", 1, "mailglass-light"},
          {nil, 0, nil}
        ] do
      mode = cookie || "system"

      test "the detail document carries #{count} theme owner on <html> for #{mode}", %{conn: conn} do
        %{ids: ids} = OperatorFixtures.seed_phase182_journey!()

        response =
          conn
          |> operator_conn()
          |> with_theme(unquote(cookie))
          |> get(detail_path(ids.bounce_then_open))
          |> html_response(200)

        assert_root_only(response, unquote(count), unquote(value))
        # The document is the operator shell, not an error page: the surface is live.
        assert response =~ ~s(data-phx-main)
      end
    end
  end

  # -- helpers (only what this file calls: the admin lane is --warnings-as-errors) --

  defp class_tokens(node) do
    node |> Floki.attribute("class") |> Enum.flat_map(&String.split/1)
  end

  defp row_count(html, :cards) do
    html
    |> Floki.parse_document!()
    |> Floki.find("[data-testid=operator-deliveries-cards] [data-testid=operator-delivery-row]")
    |> length()
  end

  defp row_count(html, :table) do
    html
    |> Floki.parse_document!()
    |> Floki.find("[data-testid=operator-deliveries-table] tr[data-testid=operator-delivery-row]")
    |> length()
  end

  # The {tag, attrs} of every element from the document root down to, not including, the
  # element with `id`. {:ok, trail} when found, :error otherwise, so a vanished element
  # cannot pass as "nothing hidden above it".
  defp ancestor_trail(nodes, id) when is_list(nodes) do
    Enum.find_value(nodes, :error, fn node ->
      case ancestor_trail(node, id, []) do
        {:ok, _trail} = found -> found
        :error -> nil
      end
    end)
  end

  defp ancestor_trail({tag, attrs, children}, id, trail) do
    if {"id", id} in attrs do
      {:ok, Enum.reverse(trail)}
    else
      Enum.find_value(children, :error, fn child ->
        case ancestor_trail(child, id, [{tag, attrs} | trail]) do
          {:ok, _trail} = found -> found
          :error -> nil
        end
      end)
    end
  end

  defp ancestor_trail(_text_or_comment, _id, _trail), do: :error

  # Ancestors of `id` that hide it: a `hidden` class token, the `hidden` attribute, or a
  # `<details>` without `open`. `md:hidden` is not hidden at 375px, so it is not flagged.
  defp hidden_ancestors(nodes, id) do
    case ancestor_trail(nodes, id) do
      {:ok, trail} -> for {tag, attrs} <- trail, hidden?(tag, attrs), do: {tag, attrs}
      :error -> [:missing_element]
    end
  end

  defp hidden?(tag, attrs) do
    tokens = attrs |> List.keyfind("class", 0, {"class", ""}) |> elem(1) |> String.split()

    "hidden" in tokens or List.keymember?(attrs, "hidden", 0) or
      (tag == "details" and not List.keymember?(attrs, "open", 0))
  end

  defp with_theme(conn, nil), do: conn

  defp with_theme(conn, cookie),
    do: Plug.Conn.put_req_header(conn, "cookie", "#{@theme_cookie}=#{cookie}")

  # Only the root <html> may own the theme: one attribute for an explicit cookie, none
  # for system.
  defp assert_root_only(html, count, value) do
    owners = html |> Floki.parse_document!() |> Floki.find("[data-theme]")
    occurrences = length(Regex.scan(~r/\sdata-theme=/, html))

    assert length(owners) == count and occurrences == count,
           "expected #{count} data-theme owner(s), found #{length(owners)} element(s) and " <>
             "#{occurrences} attribute occurrence(s)"

    case owners do
      [] ->
        :ok

      [{tag, attrs, _children}] ->
        assert tag == "html", "the single theme owner is <#{tag}>, expected <html>"
        assert List.keyfind(attrs, "data-theme", 0) == {"data-theme", value}
    end
  end

  # The badges inside one row of the list, in the mobile card or the desktop table.
  defp row_badges(html, layout, id) do
    document = Floki.parse_document!(html)
    open_control = "#operator-delivery-#{layout}-#{id}"

    row_selector = if layout == :mobile, do: "li", else: "tr"

    document
    |> Floki.find(row_selector)
    |> Enum.filter(&(Floki.find(&1, open_control) != []))
    |> Enum.flat_map(&Floki.find(&1, "[data-mg-status]"))
  end

  defp detail_path(id) do
    @base_path <>
      "?" <>
      URI.encode_query(%{
        "tenant_id" => @tenant_id,
        "view" => "deliveries",
        "delivery_id" => id,
        "full" => "1"
      })
  end

  # The cause line of the verdict block, trimmed.
  defp verdict_cause(html) do
    [cause] =
      html |> Floki.parse_document!() |> Floki.find("[data-testid=delivery-verdict-cause]")

    cause |> Floki.text() |> String.trim()
  end

  # Visible text of the verdict block, whitespace collapsed.
  defp verdict_text(html) do
    [verdict] = html |> Floki.parse_document!() |> Floki.find("#delivery-detail-verdict")
    verdict |> Floki.text(sep: " ") |> String.replace(~r/\s+/, " ")
  end

  # Rows are declared at compile time, so a timestamp is a marker resolved at runtime.
  defp resolve_times(attrs) do
    Map.new(attrs, fn
      {key, :hours_ago_2} -> {key, DateTime.add(DateTime.utc_now(), -2, :hour)}
      pair -> pair
    end)
  end

  defp deliveries_path do
    @base_path <> "?" <> URI.encode_query(%{"tenant_id" => @tenant_id, "view" => "deliveries"})
  end

  # The integer inside the summary stat card `#delivery-summary-<key>`.
  defp summary_count(html, key) do
    [value] =
      html
      |> Floki.parse_document!()
      |> Floki.find("#delivery-summary-#{key} p.tabular-nums")
      |> Enum.map(&(&1 |> Floki.text() |> String.trim()))

    value |> String.replace(",", "") |> String.to_integer()
  end

  defp operator_conn(conn) do
    now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

    Plug.Test.init_test_session(conn, %{
      "current_user_id" => "operator-1",
      "tenant_id" => @tenant_id,
      "auth_method" => "password",
      "recent_auth_at" => now
    })
  end

  defp insert_delivery!(attrs) do
    defaults = %{
      tenant_id: @tenant_id,
      mailable: "MailglassAdmin.Fixtures.AccountMailer",
      stream: :transactional,
      recipient: "operator@example.com",
      provider: "postmark",
      provider_message_id: "pm_default",
      status: :sent,
      last_event_type: :sent,
      last_event_at: DateTime.add(DateTime.utc_now(), -1, :hour),
      metadata: %{"subject" => "Reset your password"}
    }

    attrs
    |> Enum.into(defaults)
    |> Delivery.changeset()
    |> MailglassAdmin.TestRepo.insert!()
  end
end
