defmodule MailglassAdmin.HealthPopulationTest do
  @moduledoc """
  Phase 177 gate G5 / D-16: the Health population is frozen before Health is
  recomposed.

  Every literal below was captured from the pre-refactor HealthOverview markup.
  Recomposing Health is presentation only, so a later plan may retarget the
  private extractor helpers (`row_count/1`, `stale_tag?/1`) but must never edit
  the literal lists.
  """

  use MailglassAdmin.LiveViewCase, async: false

  @moduletag :phase177

  alias MailglassAdmin.TestSupport.OperatorFixtures

  @tenant_id "browser-tenant"

  @issue_testids ~w(
    operator-health-deliveries-failed
    operator-health-deliveries-bounced
    operator-health-deliveries-rejected
    operator-health-deliveries-deferred
    operator-health-inbound-failed
    operator-health-inbound-no_match
    operator-overview-health-failures
    operator-overview-health-orphans
  )

  @activity_testids ~w(operator-health-outbound-activity operator-health-inbound-activity)

  # Captured from the pre-refactor markup. `{<key>}` stands for the random id the
  # seed returned under that key; everything else is the literal rendered text.
  @default_golden [
    issues: [
      {"operator-overview-health-failures", "1",
       "/ops/mail?support_focus=failed_ingest&support_webhook_event_id={webhook_event_id}&tenant_id=browser-tenant&view=deliveries&window_hours=168",
       false}
    ],
    activity: [
      {"operator-health-outbound-activity", "21",
       "/ops/mail?tenant_id=browser-tenant&view=deliveries&window_hours=168"},
      {"operator-health-inbound-activity", "0",
       "/ops/mail/inbound?tenant_id=browser-tenant&window_hours=168"}
    ]
  ]

  # All eight categories, counts 1..8 in taxonomy order.
  @all_golden [
    issues: [
      {"operator-health-deliveries-failed", "1",
       "/ops/mail?event=failed&tenant_id=browser-tenant&view=deliveries&window_hours=168", false},
      {"operator-health-deliveries-bounced", "2",
       "/ops/mail?event=bounced&tenant_id=browser-tenant&view=deliveries&window_hours=168",
       false},
      {"operator-health-deliveries-rejected", "3",
       "/ops/mail?event=rejected&tenant_id=browser-tenant&view=deliveries&window_hours=168",
       false},
      {"operator-health-deliveries-deferred", "4",
       "/ops/mail?event=deferred&tenant_id=browser-tenant&view=deliveries&window_hours=168",
       false},
      {"operator-health-inbound-failed", "5",
       "/ops/mail/inbound?outcome=failed&tenant_id=browser-tenant&window_hours=168", false},
      {"operator-health-inbound-no_match", "6",
       "/ops/mail/inbound?outcome=no_match&tenant_id=browser-tenant&window_hours=168", false},
      {"operator-overview-health-failures", "7",
       "/ops/mail?support_focus=failed_ingest&support_webhook_event_id={newest_webhook_event_id}&tenant_id=browser-tenant&view=deliveries&window_hours=168",
       false},
      {"operator-overview-health-orphans", "8",
       "/ops/mail?support_event_id={oldest_unmatched_event_id}&support_focus=orphan_backlog&tenant_id=browser-tenant&view=deliveries&window_hours=168",
       false}
    ],
    activity: [
      {"operator-health-outbound-activity", "10",
       "/ops/mail?tenant_id=browser-tenant&view=deliveries&window_hours=168"},
      {"operator-health-inbound-activity", "11",
       "/ops/mail/inbound?tenant_id=browser-tenant&window_hours=168"}
    ]
  ]

  # The same seed with the counts reversed (8..1): row order must not move.
  @reversed_golden [
    issues: [
      {"operator-health-deliveries-failed", "8",
       "/ops/mail?event=failed&tenant_id=browser-tenant&view=deliveries&window_hours=168", false},
      {"operator-health-deliveries-bounced", "7",
       "/ops/mail?event=bounced&tenant_id=browser-tenant&view=deliveries&window_hours=168",
       false},
      {"operator-health-deliveries-rejected", "6",
       "/ops/mail?event=rejected&tenant_id=browser-tenant&view=deliveries&window_hours=168",
       false},
      {"operator-health-deliveries-deferred", "5",
       "/ops/mail?event=deferred&tenant_id=browser-tenant&view=deliveries&window_hours=168",
       false},
      {"operator-health-inbound-failed", "4",
       "/ops/mail/inbound?outcome=failed&tenant_id=browser-tenant&window_hours=168", false},
      {"operator-health-inbound-no_match", "3",
       "/ops/mail/inbound?outcome=no_match&tenant_id=browser-tenant&window_hours=168", false},
      {"operator-overview-health-failures", "2",
       "/ops/mail?support_focus=failed_ingest&support_webhook_event_id={newest_webhook_event_id}&tenant_id=browser-tenant&view=deliveries&window_hours=168",
       false},
      {"operator-overview-health-orphans", "1",
       "/ops/mail?support_event_id={oldest_unmatched_event_id}&support_focus=orphan_backlog&tenant_id=browser-tenant&view=deliveries&window_hours=168",
       false}
    ],
    activity: [
      {"operator-health-outbound-activity", "26",
       "/ops/mail?tenant_id=browser-tenant&view=deliveries&window_hours=168"},
      {"operator-health-inbound-activity", "7",
       "/ops/mail/inbound?tenant_id=browser-tenant&window_hours=168"}
    ]
  ]

  # Partial refresh: the failed-webhook read faults after a successful first read.
  @stale_golden [
    issues: [
      {"operator-overview-health-failures", "1",
       "/ops/mail?support_focus=failed_ingest&support_webhook_event_id={failed_webhook_event_id}&tenant_id=browser-tenant&view=deliveries&window_hours=168",
       true},
      {"operator-overview-health-orphans", "1",
       "/ops/mail?support_event_id={unmatched_event_id}&support_focus=orphan_backlog&tenant_id=browser-tenant&view=deliveries&window_hours=168",
       false}
    ],
    activity: [
      {"operator-health-outbound-activity", "0",
       "/ops/mail?tenant_id=browser-tenant&view=deliveries&window_hours=168"},
      {"operator-health-inbound-activity", "0",
       "/ops/mail/inbound?tenant_id=browser-tenant&window_hours=168"}
    ]
  ]

  # A quiet account: no issue rows, activity links still present.
  @empty_golden [
    issues: [],
    activity: [
      {"operator-health-outbound-activity", "1",
       "/ops/mail?tenant_id=browser-tenant&view=deliveries&window_hours=168"},
      {"operator-health-inbound-activity", "0",
       "/ops/mail/inbound?tenant_id=browser-tenant&window_hours=168"}
    ]
  ]

  describe "Phase 177 Health population" do
    test "Phase 177 Health population: default seeded overview", %{conn: conn} do
      seed = OperatorFixtures.seed_phase169_scenario!()
      {:ok, _view, html} = live(operator_conn(conn), health_path())

      assert snapshot(html, seed) == @default_golden
    end

    test "Phase 177 Health population: all eight categories", %{conn: conn} do
      seed = OperatorFixtures.seed_phase177_health_all!()
      {:ok, _view, html} = live(operator_conn(conn), health_path())

      assert snapshot(html, seed) == @all_golden
    end

    test "Phase 177 Health population: reversed counts", %{conn: conn} do
      seed = OperatorFixtures.seed_phase177_health_all!(counts: :reversed)
      {:ok, _view, html} = live(operator_conn(conn), health_path())

      assert snapshot(html, seed) == @reversed_golden
    end

    test "Phase 177 Health population: row order is the taxonomy order, never count order" do
      all = Keyword.fetch!(@all_golden, :issues) |> Enum.map(&elem(&1, 0))
      reversed = Keyword.fetch!(@reversed_golden, :issues) |> Enum.map(&elem(&1, 0))

      assert all == @issue_testids
      assert reversed == @issue_testids

      assert Keyword.fetch!(@all_golden, :issues) |> Enum.map(&elem(&1, 1)) ==
               ~w(1 2 3 4 5 6 7 8)

      assert Keyword.fetch!(@reversed_golden, :issues) |> Enum.map(&elem(&1, 1)) ==
               ~w(8 7 6 5 4 3 2 1)
    end

    test "Phase 177 Health population: every issue row has a deep link and no row is empty" do
      for golden <- [@default_golden, @all_golden, @reversed_golden, @stale_golden],
          {testid, count, href, _stale?} <- Keyword.fetch!(golden, :issues) do
        assert testid in @issue_testids
        assert is_binary(href) and href != "", "#{testid} has no deep link"
        assert String.to_integer(count) > 0, "#{testid} rendered with count #{count}"
      end

      for golden <- [@default_golden, @all_golden, @reversed_golden, @stale_golden, @empty_golden],
          {testid, _count, href} <- Keyword.fetch!(golden, :activity) do
        assert testid in @activity_testids
        assert is_binary(href) and href != "", "#{testid} has no link"
      end
    end

    test "Phase 177 Health population: stale marker sits on the failed-webhook row only", %{
      conn: conn
    } do
      seed = OperatorFixtures.seed_phase169_health_partial!()
      {:ok, view, _html} = live(operator_conn(conn), health_path())

      OperatorFixtures.arm_reader_fault!("operator-1", "failed_ingest", :known)
      render_patch(view, health_path(%{"event" => "opened", "window_hours" => "168"}))

      assert snapshot(render(view), seed) == @stale_golden
    end

    test "Phase 177 Health population: a quiet account renders no issue rows", %{conn: conn} do
      seed = OperatorFixtures.seed_phase177_health_quiet!()
      {:ok, _view, html} = live(operator_conn(conn), health_path())

      assert snapshot(html, seed) == @empty_golden
    end
  end

  # -- extractors -----------------------------------------------------------------

  defp snapshot(html, seed),
    do: [issues: fingerprint(html, seed), activity: activity_fingerprint(html)]

  # Ordered {testid, count, href, stale?} for every rendered issue row. Exact
  # testid membership only: `-link` and `-help` share the row prefix.
  #
  # Seeded record ids are random UUIDs, so each id the seed returned is replaced
  # in the href by `{<seed key>}`. Nothing else in an href is normalised, and a
  # UUID that is not a known seeded id fails the extraction.
  defp fingerprint(html, seed) do
    html
    |> health_region()
    |> Floki.find("[data-testid]")
    |> Enum.filter(fn node -> testid(node) in @issue_testids end)
    |> Enum.map(fn row ->
      id = testid(row)
      [link | _] = Floki.find(row, "[data-testid='#{id}-link']")
      {id, row_count(row), mask_ids(href(link), seed), stale_tag?(row)}
    end)
  end

  # Ordered {testid, count, href} for each Recent activity link present.
  defp activity_fingerprint(html) do
    region = health_region(html)

    for id <- @activity_testids,
        [node | _] <- [Floki.find(region, "[data-testid='#{id}']")] do
      {id, first_integer(Floki.text(node)), href(node)}
    end
  end

  defp mask_ids(href, seed) do
    masked =
      Enum.reduce(seed, href, fn
        {key, id}, acc when is_binary(id) and byte_size(id) == 36 ->
          String.replace(acc, id, "{#{key}}")

        _other, acc ->
          acc
      end)

    refute masked =~ ~r/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/,
           "href carries an unmasked UUID: #{masked}"

    masked
  end

  defp health_region(html) do
    html
    |> Floki.parse_document!()
    |> Floki.find("[data-testid='operator-overview-health']")
  end

  defp row_count(row), do: row |> Floki.find("p.mono") |> hd() |> Floki.text() |> String.trim()

  defp stale_tag?(row), do: Floki.text(row) =~ "Last retrieved"

  defp first_integer(text) do
    case Regex.run(~r/\d+/, text) do
      [digits] -> digits
      nil -> nil
    end
  end

  defp testid(node), do: node |> Floki.attribute("data-testid") |> List.first()
  defp href(node), do: node |> Floki.attribute("href") |> List.first()

  # -- routes and session -----------------------------------------------------------

  defp health_path(params \\ %{}) do
    "/ops/mail?" <> URI.encode_query(Map.merge(%{"tenant_id" => @tenant_id}, params))
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
end
