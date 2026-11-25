defmodule MailglassAdmin.Phase182ReviewWordsTest do
  @moduledoc """
  The deterministic rebuttal to one finding of the BRADM-07 review (Phase 182, D-21).

  The first after-catalog review rejected delivery screens against rule R-WORDS-1 of the brand
  book (`voice.terms`: an email is an "email", and "message" is to be avoided on screens): the
  Sent card of the delivery timeline said "This message was handed to the provider", and the
  "Awaiting confirmation" tile on the Activity list said "Messages are queued or have been sent
  to the provider". Per the iteration rule the implementer answers a reviewer only with a code
  change and a new deterministic test, never by argument, so this file proves, for every
  delivery status and for every Activity summary tile, that the help text names an email.

  The check covers both outbound and inbound status help plus the evidence-bound support
  card copy, so the same screen-language rule holds across the operator surfaces.

  Lane: required (`mix verify.support_contract.admin`).
  """

  use MailglassAdmin.LiveViewCase, async: false

  alias MailglassAdmin.Components
  alias MailglassAdmin.Copy
  alias MailglassAdmin.TestSupport.OperatorFixtures

  @tenant_id "browser-tenant"
  @message_word ~r/\bmessages?\b/i
  @operator_live_source Path.expand("../../lib/mailglass_admin/operator_live.ex", __DIR__)

  describe "delivery outcome help" do
    test "names an email, never a message, for every status the product knows" do
      statuses = Copy.statuses() |> Map.keys() |> Enum.sort()
      assert length(statuses) > 20, "the status universe must be enumerated, not hand-copied"

      for status <- statuses do
        text = Components.outcome_description(:delivery, status)
        assert is_binary(text) and text != ""

        assert message_hits(text) == [],
               "the delivery help for #{inspect(status)} says #{inspect(message_hits(text))}: #{text}"
      end
    end

    test "a delivery status with no clause of its own falls back to a help text that names an email" do
      text = Components.outcome_description(:delivery, :a_status_no_clause_names)
      assert text == "Open the email to inspect its recorded history."
      assert message_hits(text) == []
    end

    test "names an inbound email, never a message, for every inbound outcome" do
      for status <- [
            :accepted,
            :no_match,
            :ignore,
            :no_change,
            :rejected,
            :bounced,
            :failed,
            :missing_history
          ] do
        text = Components.outcome_description(:inbound, status)

        assert message_hits(text) == [],
               "inbound #{status} help says #{inspect(message_hits(text))}: #{text}"
      end
    end

    test "the context-free processing fallback names an email" do
      assert Components.outcome_description(:other, :unknown) ==
               "Open the email to inspect its recorded processing history."
    end
  end

  describe "the Activity summary tiles" do
    test "no tile says message, and each tile still explains itself", %{conn: conn} do
      OperatorFixtures.seed_phase182_journey!()

      {:ok, view, _html} = live(operator_conn(conn), deliveries_path())
      html = render(view)

      for key <- [:delivered, :attention, :awaiting] do
        text = tile_text(html, key)
        assert String.length(text) > 40, "tile #{key} lost its help text: #{inspect(text)}"

        assert message_hits(text) == [],
               "tile #{key} says #{inspect(message_hits(text))}: #{text}"
      end

      assert tile_text(html, :awaiting) =~ "Emails are queued or have been sent to the provider"
    end
  end

  describe "support-card help" do
    test "delivery and inbound summary copy uses the approved email wording" do
      source = File.read!(@operator_live_source)

      for copy <- [
            "The provider reported that these emails could not be delivered.",
            "The provider rejected these emails.",
            "Mailbox processing ended in failure when these inbound emails were received. Open an email to inspect its error and any later recovery attempts.",
            "No mailbox routing rule matched these inbound emails when they were received."
          ] do
        assert source =~ copy
        assert message_hits(copy) == []
      end
    end
  end

  describe "detector has teeth" do
    test "the message detector flags the exact sentences the review rejected, and only those words" do
      assert message_hits("This message was handed to the provider.") == ["message"]
      assert message_hits("Messages are queued or have been sent.") == ["Messages"]
      assert message_hits("The provider rejected these messages.") == ["messages"]
      assert message_hits("This email was handed to the provider.") == []
      assert message_hits("Emails are queued or have been sent.") == []
      assert message_hits("A messenger is not the word.") == []
    end
  end

  defp message_hits(text), do: @message_word |> Regex.scan(text) |> Enum.map(&hd/1)

  # All text inside one summary stat card, hidden tooltip included.
  defp tile_text(html, key) do
    html
    |> Floki.parse_document!()
    |> Floki.find("#delivery-summary-#{key}")
    |> Floki.text()
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp deliveries_path do
    "/ops/mail?" <> URI.encode_query(%{"tenant_id" => @tenant_id, "view" => "deliveries"})
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
