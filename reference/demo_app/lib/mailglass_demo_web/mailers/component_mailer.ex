defmodule MailglassDemoWeb.Mailers.ComponentMailer do
  @moduledoc false

  use Mailglass.Mailable, stream: :transactional

  import Phoenix.Component, except: [link: 1]

  alias Mailglass.Message

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
    props = assigns

    html = fn assigns ->
      assigns = Map.merge(props, assigns)

      ~H"""
      <.container>
        <.section>
          <.heading>Invoice {@invoice_id} is ready</.heading>
          <.text>Hello {@recipient_name},</.text>
          <.text>
            The {@billing_period} invoice for {@workspace} is ready. The total is {@amount}.
            You can review the details at any time.
          </.text>
          <.img
            src="https://app.atlasdesk.example/assets/invoice-summary.png"
            alt={"Invoice summary for #{@workspace}: #{@amount} for #{@billing_period}"}
            width={560}
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
