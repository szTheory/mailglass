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

  # Captured from the pre-refactor markup. `{webhook_event_id}` stands for the
  # random id returned by the seed.
  @default_golden [
    {"operator-overview-health-failures", "1",
     "/ops/mail?support_focus=failed_ingest&support_webhook_event_id={webhook_event_id}&tenant_id=browser-tenant&view=deliveries&window_hours=168",
     false}
  ]

  @default_activity_golden [
    {"operator-health-outbound-activity", "21",
     "/ops/mail?tenant_id=browser-tenant&view=deliveries&window_hours=168"},
    {"operator-health-inbound-activity", "0",
     "/ops/mail/inbound?tenant_id=browser-tenant&window_hours=168"}
  ]

  describe "Phase 177 Health population" do
    test "Phase 177 Health population: default seeded overview", %{conn: conn} do
      seed = OperatorFixtures.seed_phase169_scenario!()
      {:ok, _view, html} = live(operator_conn(conn), health_path())

      assert fingerprint(html, seed) == @default_golden
      assert activity_fingerprint(html) == @default_activity_golden
    end
  end

  # -- extractors -----------------------------------------------------------------

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
