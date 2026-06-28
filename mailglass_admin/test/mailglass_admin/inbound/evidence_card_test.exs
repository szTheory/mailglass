defmodule MailglassAdmin.Inbound.EvidenceCardTest do
  @moduledoc """
  Component tests for the EvidenceCard reveal disclosure a11y hardening (D-11).

  Asserts the reveal control is a true ARIA disclosure (aria-expanded/aria-controls),
  the :revealed branch carries a "Re-redact raw source" collapse button, an
  aria-live="polite" role="status" region announces the state change in TEXT
  (WCAG 1.4.1, never border color alone), the secondary "Contains unredacted PII."
  line is present, and the denied/redacted body copy is byte-frozen with the raw
  payload absent in every non-revealed state (D-10 redacted-by-default).
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
      assert html =~ "Contains unredacted PII."
      # Redacted-by-default: raw bytes absent.
      refute html =~ ~s(data-testid="inbound-evidence-raw")
      refute html =~ "secret-raw-payload-121-02"
    end

    test "the :revealed state reflects aria-expanded=true and renders the re-redact collapse" do
      html = render_state(:revealed)

      # Disclosure is expanded.
      assert html =~ ~s(aria-expanded="true") or
               not (html =~ ~s(data-testid="inbound-evidence-reveal"))

      # Re-redact collapse button — NEW, routes back to :redacted via re_redact_raw.
      assert html =~ ~s(data-testid="inbound-evidence-re-redact")
      assert html =~ ~s(phx-click="re_redact_raw")
      assert html =~ "Re-redact raw source"

      # Raw payload present only here.
      assert html =~ ~s(data-testid="inbound-evidence-raw")
      assert html =~ "secret-raw-payload-121-02"
    end
  end

  describe "aria-live status region (WCAG 1.4.1, D-11)" do
    test "a role=status aria-live=polite region announces the reveal grant in text" do
      html = render_state(:revealed)

      assert html =~ ~s(role="status")
      assert html =~ ~s(aria-live="polite")
      assert html =~ "Raw source revealed. This payload contains unredacted PII."
    end

    test "the status region is present in :redacted without announcing a reveal" do
      html = render_state(:redacted)

      assert html =~ ~s(role="status")
      assert html =~ ~s(aria-live="polite")
      refute html =~ "Raw source revealed. This payload contains unredacted PII."
    end
  end

  describe "frozen denied/redacted copy + redacted-by-default (D-10)" do
    test "the :denied body is byte-frozen and the raw payload is absent" do
      html = render_state(:denied)

      assert html =~
               "Raw source not revealed: the reveal_raw capability is not granted for this operator."

      refute html =~ ~s(data-testid="inbound-evidence-raw")
      refute html =~ "secret-raw-payload-121-02"
    end

    test "the :redacted body is byte-frozen and renders NO inbound-evidence-raw" do
      html = render_state(:redacted)

      assert html =~
               "Raw source redacted. Revealing the raw provider payload requires the reveal_raw capability."

      refute html =~ ~s(data-testid="inbound-evidence-raw")
      refute html =~ "secret-raw-payload-121-02"
    end
  end
end
