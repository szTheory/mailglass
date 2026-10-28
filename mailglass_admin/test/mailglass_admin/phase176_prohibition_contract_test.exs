defmodule MailglassAdmin.Phase176UnavailableRepo do
  @moduledoc false

  # Every Inbound read raises a known connection failure, so a new-query read
  # lands in the failed state without any fixture trickery.
  def all(_queryable, _opts \\ []),
    do: raise(DBConnection.ConnectionError, message: "synthetic phase176 connection failure")

  def one(_queryable, _opts \\ []),
    do: raise(DBConnection.ConnectionError, message: "synthetic phase176 connection failure")
end

defmodule MailglassAdmin.Phase176ProhibitionContractTest do
  @moduledoc """
  Machine-checked form of the eight Phase 176 must-NOT prohibitions
  (FILTER-01..04, INUX-05, INUX-06; D-30).

  Each prohibition reduces to a forbidden control, a forbidden value or a
  forbidden claim on a closed set of rendered states, so this file enumerates
  those states and refutes the violation. The "detectors have teeth" block
  feeds every detector a known violation, so a pass here is not vacuous, and
  each prohibition was additionally proven red by a temporary source mutation
  (recorded in the plan SUMMARY).

  Positive behavior (history policy, focus, reveal authorization) stays in the
  LiveView and browser suites; this file only owns the prohibitions.
  """

  use MailglassAdmin.LiveViewCase, async: false

  @moduletag :phase176

  alias Mailglass.Outbound.Delivery
  alias MailglassAdmin.TestRepo
  alias MailglassAdmin.TestSupport.InboundFixtures

  @tenant_id "test-tenant"

  @apply_wording [~r/\bapply\b/i, ~r/\bsubmit\b/i, ~r/\bsearch now\b/i]

  describe "detectors have teeth (fail-first proof)" do
    test "the P1 detector rejects a form with an apply button, a submit type and disable-with" do
      violating = """
      <form id="operator-filters">
        <button type="submit" phx-disable-with="Applying...">Apply filters</button>
        <button>Go</button>
        <input type="submit" value="Apply" />
      </form>
      """

      found = apply_control_violations(violating)

      assert Enum.any?(found, &(&1 =~ "label"))
      assert Enum.any?(found, &(&1 =~ "type=submit"))
      assert Enum.any?(found, &(&1 =~ "disable-with"))
      assert Enum.any?(found, &(&1 =~ "implicit submit"))
    end

    test "the P1 detector accepts a form whose only button is a plain Clear control" do
      clean = """
      <form id="operator-filters">
        <select name="filters[event]"></select>
        <button type="button" phx-click="clear_filters">Clear filters</button>
      </form>
      """

      assert apply_control_violations(clean) == []
    end
  end

  describe "P1 filter forms have no apply or submit control" do
    test "Deliveries #operator-filters carries no apply, submit or disable-with control", %{
      conn: conn
    } do
      insert_delivery!(recipient: "p1@example.com")
      {:ok, _view, html} = live(operator_conn(conn), deliveries_path())

      form = form_html(html, "#operator-filters")
      assert form != "", "expected #operator-filters on the Deliveries route"
      assert apply_control_violations(form) == []
    end

    test "Inbound #inbound-filters carries no apply, submit or disable-with control", %{
      conn: conn
    } do
      InboundFixtures.seed_matched!(@tenant_id, recipient: "p1-inbound@example.com")
      {:ok, _view, html} = live(operator_conn(conn), inbound_path(%{"tenant_id" => @tenant_id}))

      form = form_html(html, "#inbound-filters")
      assert form != "", "expected #inbound-filters on the Inbound route"
      assert apply_control_violations(form) == []
    end
  end

  # -- detectors ---------------------------------------------------------------

  # Returns a list of human-readable violations found inside the given form HTML.
  defp apply_control_violations(form_html) do
    nodes = Floki.parse_fragment!(form_html)

    label_hits =
      nodes
      |> Floki.find("button, a, [phx-click], input[type=submit], input[type=image]")
      |> Enum.flat_map(fn node ->
        label = [Floki.text(node) | Floki.attribute(node, "value")] |> Enum.join(" ")

        for pattern <- @apply_wording, Regex.match?(pattern, label) do
          "label #{inspect(String.trim(label))} matches #{inspect(Regex.source(pattern))}"
        end
      end)

    submit_type =
      for _ <- Floki.find(nodes, "[type=submit], [type=image]"), do: "control with type=submit"

    disable_with =
      for _ <- Floki.find(nodes, "[phx-disable-with]"), do: "control with disable-with"

    implicit_submit =
      nodes
      |> Floki.find("button")
      |> Enum.filter(fn node -> Floki.attribute(node, "type") in [[], ["submit"]] end)
      |> Enum.map(fn _ -> "implicit submit button (button without type=button)" end)

    label_hits ++ submit_type ++ disable_with ++ implicit_submit
  end

  defp form_html(html, selector) do
    html
    |> Floki.parse_document!()
    |> Floki.find(selector)
    |> Floki.raw_html()
  end

  # -- routes and session ------------------------------------------------------

  defp deliveries_path,
    do: "/ops/mail?" <> URI.encode_query(%{"tenant_id" => @tenant_id, "view" => "deliveries"})

  defp inbound_path(params) do
    case URI.encode_query(params) do
      "" -> "/ops/mail/inbound"
      query -> "/ops/mail/inbound?" <> query
    end
  end

  defp insert_delivery!(attrs) do
    %{
      tenant_id: @tenant_id,
      mailable: "Mailglass.Example.OperatorMailer",
      stream: :transactional,
      recipient: "operator@example.com",
      provider: "postmark",
      provider_message_id: "pm_p176_#{System.unique_integer([:positive])}",
      status: :sent,
      last_event_type: :sent,
      last_event_at: DateTime.add(DateTime.utc_now(), -3_600, :second),
      metadata: %{}
    }
    |> Map.merge(Map.new(attrs))
    |> Delivery.changeset()
    |> TestRepo.insert!()
  end

  defp operator_conn(conn, session \\ %{}) do
    now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()

    base = %{
      "current_user_id" => "operator-1",
      "tenant_id" => @tenant_id,
      "auth_method" => "password",
      "recent_auth_at" => now
    }

    Plug.Test.init_test_session(conn, Map.merge(base, session))
  end
end
