defmodule MailglassDemoWeb.Mailers.BillingMailer do
  use Mailglass.Mailable, stream: :operational

  alias Mailglass.Message

  def preview_props do
    [
      receipt_paid: %{
        recipient: "billing@northstar-ops.example",
        workspace: "Northstar Ops",
        invoice_id: "INV-2026-0601",
        total: "$248.00"
      },
      payment_failed: %{
        recipient: "billing@northstar-ops.example",
        workspace: "Northstar Ops",
        retry_at: "tomorrow at 09:00 ET"
      }
    ]
  end

  def receipt_paid(assigns) do
    new()
    |> Message.from({"Northstar Billing", "billing@demo.mailglass.local"})
    |> Message.to(assigns.recipient)
    |> Message.subject("Receipt #{assigns.invoice_id} for #{assigns.workspace}")
    |> Message.html_body("""
    <h1>Receipt #{assigns.invoice_id}</h1>
    <p>#{assigns.workspace} paid #{assigns.total}. The invoice and audit trail are attached in your billing workspace.</p>
    """)
    |> Message.text_body("#{assigns.workspace} paid #{assigns.total} for #{assigns.invoice_id}.")
    |> Message.put_function(:receipt_paid)
  end

  def payment_failed(assigns) do
    new()
    |> Message.from({"Northstar Billing", "billing@demo.mailglass.local"})
    |> Message.to(assigns.recipient)
    |> Message.subject("Payment action needed for #{assigns.workspace}")
    |> Message.html_body("""
    <h1>Payment action needed</h1>
    <p>The next automatic retry runs #{assigns.retry_at}. Update billing details to keep transactional email flowing.</p>
    """)
    |> Message.text_body(
      "Payment action needed. The next automatic retry runs #{assigns.retry_at}."
    )
    |> Message.put_function(:payment_failed)
  end
end
