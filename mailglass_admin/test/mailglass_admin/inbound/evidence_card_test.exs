defmodule MailglassAdmin.Inbound.EvidenceCardTest do
  @moduledoc """
  Component tests for the EvidenceCard reveal disclosure a11y hardening (D-11).

  Asserts the reveal control is a true ARIA disclosure (aria-expanded/aria-controls),
  that ONE persistent toggle reads "Reveal raw source" when collapsed and "Hide raw
  source" when revealed (no second inner hide button), an aria-live="polite"
  role="status" region announces the state change in TEXT (WCAG 1.4.1, never border
  color alone), the "May contain personal information." caption is always present,
  and the denied copy is frozen with the raw payload absent in every non-revealed
  state (D-10 redacted-by-default).
  """

  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MailglassAdmin.Inbound.EvidenceCard

  @evidence %{
    provider: "mailgun",
    raw_payload: %{"body" => "secret-raw-payload-121-02"},
    raw_headers: %{"x-mailglass-signature" => "ok"},
    verification_facts: %{"signature" => "verified", "dkim" => true}
  }

  defp render_state(state) do
    render_component(&EvidenceCard.evidence_card/1, evidence: @evidence, reveal_state: state)
  end

  describe "reveal disclosure ARIA (D-11)" do
    test "the :redacted reveal button is a true ARIA disclosure with the secondary PII line" do
      html = render_state(:redacted)

      assert html =~ ~s(data-testid="inbound-evidence-reveal")
      assert html =~ ~s(aria-expanded="false")
      assert html =~ ~s(aria-controls="inbound-evidence-raw")
      assert html =~ ~s(type="button")
      assert html =~ "min-h-11"
      assert html =~ "mg-focus-ring"
      # Reveal label unchanged + NEW secondary line.
      assert html =~ "Reveal raw source"
      assert html =~ "May contain personal information."
      # Redacted-by-default: raw bytes absent.
      refute html =~ ~s(data-testid="inbound-evidence-raw")
      refute html =~ "secret-raw-payload-121-02"
    end

    test "the :revealed state reflects aria-expanded=true on the single toggle that collapses it" do
      html = render_state(:revealed)
      doc = Floki.parse_document!(html)

      # One persistent toggle: same id, label flipped, collapse event.
      assert [toggle] = Floki.find(doc, "[data-testid='inbound-evidence-reveal']")
      assert Floki.attribute(toggle, "id") == ["inbound-evidence-reveal-btn"]
      assert Floki.attribute(toggle, "aria-expanded") == ["true"]
      assert Floki.attribute(toggle, "aria-controls") == ["inbound-evidence-raw"]
      assert Floki.attribute(toggle, "aria-describedby") == ["inbound-evidence-caption"]
      assert Floki.attribute(toggle, "phx-click") == ["re_redact_raw"]
      assert Floki.text(toggle) =~ "Hide raw source"

      # No second inner hide control.
      refute html =~ ~s(data-testid="inbound-evidence-re-redact")
      assert length(Floki.find(doc, "button")) == 1

      # Raw payload present only here, in a keyboard-scrollable read-only region.
      assert [pre] = Floki.find(doc, "pre#inbound-evidence-raw")
      assert Floki.attribute(pre, "tabindex") == ["0"]
      assert Floki.attribute(pre, "aria-label") == ["Raw provider source, read-only"]
      assert html =~ "secret-raw-payload-121-02"
    end

    @tag :phase176
    test "the :redacted toggle dispatches reveal_raw and the caption is always visible" do
      for state <- [:redacted, :denied, :revealed] do
        html = render_state(state)

        assert html =~ ~s(data-testid="inbound-evidence-caption")
        assert html =~ "May contain personal information."
      end

      html = render_state(:redacted)
      doc = Floki.parse_document!(html)
      assert [toggle] = Floki.find(doc, "[data-testid='inbound-evidence-reveal']")
      assert Floki.attribute(toggle, "phx-click") == ["reveal_raw"]
      assert Floki.attribute(toggle, "aria-expanded") == ["false"]
      refute html =~ "Raw source locked"
    end
  end

  describe "facts list (INUX-06, D-25/D-26)" do
    defp facts_doc(evidence, extra \\ []) do
      assigns = Keyword.merge([evidence: evidence, reveal_state: :redacted], extra)

      (&EvidenceCard.evidence_card/1)
      |> render_component(assigns)
      |> Floki.parse_document!()
    end

    defp fact_pairs(doc) do
      assert [dl] = Floki.find(doc, "dl[data-testid='inbound-evidence-facts']")

      dl
      |> Floki.find("div")
      |> Enum.map(fn cell ->
        {cell |> Floki.find("dt") |> Floki.text() |> String.trim(),
         cell |> Floki.find("dd") |> Floki.text() |> String.trim()}
      end)
    end

    @tag :phase176
    test "Phase 176 facts: one list with five facts in order and the shared grid classes" do
      received_at = ~U[2026-10-01 12:30:00Z]
      doc = facts_doc(@evidence, received_at: received_at)

      assert [dl] = Floki.find(doc, "dl")
      [classes] = Floki.attribute(dl, "class")
      assert classes =~ "grid gap-md sm:grid-cols-2 lg:grid-cols-4"

      assert Enum.map(Floki.find(doc, "dt"), &(&1 |> Floki.text() |> String.trim())) == [
               "Provider",
               "Received",
               "Payload size",
               "Header count",
               "Provider authentication"
             ]

      assert Floki.find(doc, "[data-testid='inbound-evidence-verification']") != []
      refute Floki.raw_html(doc) =~ "Verification facts"
      refute Floki.raw_html(doc) =~ "checksum"

      # D-25: no fact cell is monospace.
      assert Floki.find(dl, ".mono") == []

      pairs = fact_pairs(doc)
      assert {"Received", received} = Enum.at(pairs, 1)
      assert received =~ "2026-10-01 12:30:00 UTC"
    end

    @tag :phase176
    test "Phase 176 facts: raw_mime backs the payload size (3 bytes, not 2)" do
      evidence = %{@evidence | raw_payload: %{}} |> Map.put(:raw_mime, "abc")
      assert {"Payload size", "3 bytes"} = doc_pair(evidence, "Payload size")
    end

    @tag :phase176
    test "Phase 176 facts: unknown size, count and received time render Unavailable, never 0" do
      evidence = %{provider: "mailgun", verification_facts: nil}
      doc = facts_doc(evidence, received_at: nil)
      pairs = fact_pairs(doc)

      assert {"Payload size", "Unavailable"} in pairs
      assert {"Header count", "Unavailable"} in pairs
      assert {"Received", "Unavailable"} in pairs

      for {_label, value} <- pairs do
        refute value in ["0", "0 bytes"]
      end

      # nil / non-map fields are unknown too, not empty.
      for evidence <- [
            %{provider: "mailgun", raw_payload: nil, raw_mime: nil, raw_headers: nil},
            %{provider: "mailgun", raw_payload: "not-a-map", raw_headers: "nope"}
          ] do
        pairs = fact_pairs(facts_doc(evidence))
        assert {"Payload size", "Unavailable"} in pairs
        assert {"Header count", "Unavailable"} in pairs
      end
    end

    defp doc_pair(evidence, label) do
      pairs = fact_pairs(facts_doc(evidence))
      assert {^label, _value} = pair = Enum.find(pairs, &(elem(&1, 0) == label))
      pair
    end
  end

  describe "aria-live status region (WCAG 1.4.1, D-11)" do
    test "a role=status aria-live=polite region announces the reveal grant in text" do
      html = render_state(:revealed)

      assert html =~ ~s(role="status")
      assert html =~ ~s(aria-live="polite")
      assert html =~ "Raw source revealed. It may contain personal information."
    end

    test "the status region is present in :redacted without announcing a reveal" do
      html = render_state(:redacted)

      assert html =~ ~s(role="status")
      assert html =~ ~s(aria-live="polite")
      refute html =~ "Raw source revealed. It may contain personal information."
    end
  end

  describe "frozen denied/redacted copy + redacted-by-default (D-10)" do
    test "the :denied body is byte-frozen, role=status, and the raw payload is absent" do
      html = render_state(:denied)

      assert html =~ "You don&#39;t have permission to reveal raw source." or
               html =~ "You don't have permission to reveal raw source."

      assert [denied] =
               html
               |> Floki.parse_document!()
               |> Floki.find("[data-testid='inbound-evidence-denied']")

      assert Floki.attribute(denied, "role") == ["status"]

      refute html =~ ~s(data-testid="inbound-evidence-raw")
      refute html =~ "secret-raw-payload-121-02"
    end

    test "the :redacted body has no hidden-by-default paragraph and renders NO inbound-evidence-raw" do
      html = render_state(:redacted)

      refute html =~ "Raw source is hidden by default"
      refute html =~ ~s(data-testid="inbound-evidence-redacted")
      assert html =~ ~s(data-testid="inbound-evidence-caption")
      refute html =~ ~s(data-testid="inbound-evidence-raw")
      refute html =~ "secret-raw-payload-121-02"
    end
  end

  describe "safe verification projection (D-05/D-06)" do
    test "ordinary evidence shows only the fixed SES authentication fact and withholds untrusted data" do
      evidence = %{
        provider: "ses",
        raw_payload: %{"body" => "raw-body-secret-170-03"},
        raw_mime: "raw-mime-secret-170-03",
        raw_headers: %{"x-api-key" => "header-secret-170-03"},
        verification_facts: %{
          auth: :sns_x509,
          api_key: "verification-secret-170-03",
          durable_route_binding: "binding-secret-170-03",
          exception: "exception-secret-170-03",
          markup: "<img src=x onerror=alert(1)>"
        }
      }

      html =
        render_component(&EvidenceCard.evidence_card/1,
          evidence: evidence,
          reveal_state: :redacted
        )

      assert html =~ "SNS X.509 authentication verified"
      assert html =~ "SES"

      for secret <- [
            "raw-body-secret-170-03",
            "raw-mime-secret-170-03",
            "header-secret-170-03",
            "verification-secret-170-03",
            "binding-secret-170-03",
            "exception-secret-170-03",
            "onerror=alert(1)",
            "durable_route_binding",
            "api_key"
          ] do
        refute html =~ secret
      end
    end

    test "absent or unrecognized SES authentication renders unavailable without raw values" do
      for facts <- [nil, %{}, %{auth: :unrecognized_secret_auth, token: "unknown-secret-170-03"}] do
        html =
          render_component(&EvidenceCard.evidence_card/1,
            evidence: %{provider: "ses", verification_facts: facts},
            reveal_state: :redacted
          )

        assert html =~ "Unavailable"
        refute html =~ "unrecognized_secret_auth"
        refute html =~ "unknown-secret-170-03"
      end
    end
  end
end
