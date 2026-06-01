defmodule MailglassDemoWeb.Mailers.BillingMailer do
  use Mailglass.Mailable, stream: :operational

  alias Mailglass.Message

  def preview_props do
    [
      receipt_paid: %{
        recipient: "billing@northstar-ops.example",
        workspace: "Northstar Ops",
        invoice_id: "INV-2026-0601",
        total: "$248.00",
        billing_period: "May 2026",
        plan: "Scale"
      },
      payment_failed: %{
        recipient: "billing@northstar-ops.example",
        workspace: "Northstar Ops",
        amount_due: "$248.00",
        card_last4: "4242",
        retry_at: "2026-06-02 09:00 ET"
      }
    ]
  end

  def receipt_paid(assigns) do
    new()
    |> Message.from({"Northstar Billing", "billing@demo.mailglass.local"})
    |> Message.to(assigns.recipient)
    |> Message.subject("Receipt INV-2026-0601 for Northstar Ops")
    |> Message.html_body("""
    <h1>Receipt #{assigns.invoice_id}</h1>
    <p>#{assigns.workspace} paid #{assigns.total} for #{assigns.billing_period} on the #{assigns.plan} plan.</p>
    <p>The invoice and audit trail are attached in your billing workspace.</p>
    """)
    |> Message.text_body(
      "#{assigns.workspace} paid #{assigns.total} for #{assigns.invoice_id} during #{assigns.billing_period} on the #{assigns.plan} plan."
    )
    |> Message.put_function(:receipt_paid)
  end

  def payment_failed(assigns) do
    new()
    |> Message.from({"Northstar Billing", "billing@demo.mailglass.local"})
    |> Message.to(assigns.recipient)
    |> Message.subject("Payment action needed for Northstar Ops")
    |> Message.html_body("""
    <h1>Payment action needed</h1>
    <p>Amount due: #{assigns.amount_due} (card ending #{assigns.card_last4}).</p>
    <p>The next automatic retry runs #{assigns.retry_at}. Update billing details to keep transactional email flowing.</p>
    """)
    |> Message.text_body(
      "Payment action needed. Amount due: #{assigns.amount_due} (card ending #{assigns.card_last4}). The next automatic retry runs #{assigns.retry_at}."
    )
    |> Message.put_function(:payment_failed)
  end
end
