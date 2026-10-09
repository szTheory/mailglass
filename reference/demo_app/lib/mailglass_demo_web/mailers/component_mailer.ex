defmodule MailglassDemoWeb.Mailers.ComponentMailer do
  @moduledoc false

  use Mailglass.Mailable, stream: :transactional

  import Phoenix.Component, except: [link: 1]

  alias Mailglass.Message

  @invoice_preview_image_src "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 560 160'%3E" <>
                               "%3Crect width='560' height='160' rx='12' fill='%23EAF6FB'/%3E" <>
                               "%3Cpath d='M36 36h488' stroke='%23C7DCE5' stroke-width='2'/%3E" <>
                               "%3Cpath d='M36 62h140M36 84h220M36 124h140M350 62h140M350 84h110M350 124h140' stroke='%231D637A' stroke-width='8' stroke-linecap='round'/%3E%3C/svg%3E"

  def preview_props do
    [
      invoice_ready: %{
        recipient: "mira.chen@northstar.example",
        recipient_name: "Élodie Fernández-Sørensen",
        workspace: "Northstar Logistics",
        invoice_id: "INV-2026-0601",
        amount: "$2,480.00",
        billing_period: "May 2026"
      }
    ]
  end

  def invoice_ready(assigns) do
    props = Map.put(assigns, :invoice_preview_image_src, @invoice_preview_image_src)

    html = fn assigns ->
      assigns = Map.merge(props, assigns)

      ~H"""
      <.container>
        <.section>
          <.text size="sm" tone="slate">AtlasDesk</.text>
          <.heading>Invoice {@invoice_id} is ready</.heading>
          <.text>Hello {@recipient_name},</.text>
          <.text>
            The {@billing_period} invoice for {@workspace} is ready. The total is {@amount}.
            You can review the details at any time.
          </.text>
          <.img
            src={@invoice_preview_image_src}
            alt={"Illustration of the #{@billing_period} invoice summary for #{@workspace}"}
          />
          <.text>
            The invoice total is {@amount}. This amount is also shown here so you can read it
            when images are unavailable.
          </.text>
          <.button href={"https://app.atlasdesk.example/invoices/#{@invoice_id}"}>
            Review invoice {@invoice_id}
          </.button>
          <.text>
            <.link href={"https://app.atlasdesk.example/invoices/#{@invoice_id}/download"}>
              Download the itemized invoice
            </.link>
          </.text>
        </.section>
      </.container>
      """
    end

    new()
    |> Message.from({"AtlasDesk", "notify@atlasdesk.example"})
    |> Message.to(assigns.recipient)
    |> Message.subject("Invoice #{assigns.invoice_id} is ready for #{assigns.workspace}")
    |> Message.html_body(html)
    |> Message.put_function(:invoice_ready)
  end
end
