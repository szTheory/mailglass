defmodule Mailglass.Components.ContentTest do
  use ExUnit.Case, async: true

  alias Mailglass.Components

  setup do
    Mailglass.Config.validate_at_boot!()
    :ok
  end

  defp render(component, assigns) do
    assigns
    |> component.()
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end

  defp slot_assigns(content) do
    %{
      class: nil,
      rest: %{},
      __changed__: nil,
      inner_block: [
        %{__slot__: :inner_block, inner_block: fn _, _ -> content end}
      ]
    }
  end

  test "heading and body keep one readable semantic hierarchy" do
    long_name = String.duplicate("Zoë Fernández Sørensen ", 16)
    hostile_copy = "<script>Zoë & Søren</script> " <> long_name

    heading =
      render(&Components.heading/1, Map.merge(slot_assigns(hostile_copy), %{level: 1, align: "left", tone: "ink"}))

    body =
      render(&Components.text/1, Map.merge(slot_assigns(hostile_copy), %{size: "base", tone: "ink", align: "left"}))

    assert heading =~ "<h1"
    assert heading =~ "font-size:20px"
    assert heading =~ "font-weight:700"
    assert body =~ "<p"
    assert body =~ "font-size:16px"
    assert body =~ "line-height:1.5"
    assert body =~ "&lt;script&gt;Zoë &amp; Søren&lt;/script&gt;"
    assert body =~ long_name
    refute body =~ "<script>"
  end

  test "inline links use the readable theme-aware color and wrap long labels and destinations" do
    long_label = String.duplicate("monthly-invoice-review-", 12)
    destination = "https://billing.example.test/invoices/" <> String.duplicate("2026-06/", 18)

    html =
      render(
        &Components.link/1,
        Map.merge(slot_assigns(long_label), %{
          tone: "glass",
          rest: %{href: destination <> "?quoted=\"<script>"}
        })
      )

    assert html =~ "#1D637A"
    assert html =~ "overflow-wrap:anywhere"
    assert html =~ "word-break:break-word"
    assert html =~ "href=\"#{destination}&quot;&lt;script&gt;"
    assert html =~ long_label
    refute html =~ "href=\"#{destination}\""
  end

  test "informative images retain descriptive alternatives and fluid sizing" do
    html =
      render(&Components.img/1, %{
        src: "https://example.test/invoice.png",
        alt: "Invoice total for Northstar Logistics is 2,480 dollars",
        width: 560,
        height: nil,
        class: nil,
        rest: %{},
        __changed__: nil
      })

    assert html =~ "alt=\"Invoice total for Northstar Logistics is 2,480 dollars\""
    assert html =~ "width=\"560\""
    assert html =~ "max-width:100%"
    assert html =~ "height:auto"
  end

  test "outer container stays fluid with a 600px inner maximum" do
    html =
      render(
        &Components.container/1,
        Map.merge(slot_assigns("message"), %{bg: "paper", bg_hex: nil})
      )

    assert html =~ "role=\"presentation\" width=\"100%\""
    assert html =~ "width=\"600\""
    assert html =~ "max-width:600px;width:100%"
    assert html =~ "style=\"width:100%;"
  end

  test "link tones continue to resolve through the adopter theme" do
    html =
      render(
        &Components.link/1,
        Map.merge(slot_assigns("Billing details"), %{tone: "ink", rest: %{href: "https://example.test"}})
      )

    assert html =~ Mailglass.Components.Theme.color(:ink)
  end
end
