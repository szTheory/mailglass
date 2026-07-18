defmodule MailglassDemoWeb.Mailers.BillingMailer do
  use Mailglass.Mailable, stream: :operational

  alias Mailglass.Message
  alias MailglassDemoWeb.Mailers.AtlasDeskEmail

  def preview_props do
    [
      receipt_paid: %{
        recipient: AtlasDeskEmail.account_address("billing"),
        workspace: AtlasDeskEmail.demo_account(),
        invoice_id: "INV-2026-0601",
        total: "$248.00",
        billing_period: "May 2026",
        plan: "Scale"
      },
      payment_failed: %{
        recipient: AtlasDeskEmail.account_address("billing"),
        workspace: AtlasDeskEmail.demo_account(),
        amount_due: "$248.00",
        card_last4: "4242",
        retry_at: "2026-06-02 09:00 ET"
      }
    ]
  end

  def receipt_paid(assigns) do
    new()
    |> Message.from({"AtlasDesk Billing", "billing@atlasdesk.example"})
    |> Message.to(assigns.recipient)
    |> Message.subject("Receipt #{assigns.invoice_id} for #{assigns.workspace}")
    |> Message.html_body(
      AtlasDeskEmail.html(%{
        eyebrow: "Receipt",
        preheader: "#{assigns.workspace} paid #{assigns.total} for #{assigns.billing_period}.",
        title: "Receipt #{assigns.invoice_id}",
        paragraphs: [
          "#{assigns.workspace} paid #{assigns.total} for #{assigns.billing_period} on the #{assigns.plan} plan.",
          "The invoice and audit trail are available in your billing workspace."
        ],
        metrics: [
          {"Invoice", assigns.invoice_id},
          {"Billing period", assigns.billing_period},
          {"Plan", assigns.plan},
          {"Total", assigns.total}
        ],
        cta: {"Open billing", "https://app.atlasdesk.example/billing"}
      })
    )
    |> Message.text_body(
      "#{assigns.workspace} paid #{assigns.total} for #{assigns.invoice_id} during #{assigns.billing_period} on the #{assigns.plan} plan."
    )
    |> Message.put_function(:receipt_paid)
  end

  def payment_failed(assigns) do
    new()
    |> Message.from({"AtlasDesk Billing", "billing@atlasdesk.example"})
    |> Message.to(assigns.recipient)
    |> Message.subject("Payment action needed for #{assigns.workspace}")
    |> Message.html_body(
      AtlasDeskEmail.html(%{
        eyebrow: "Billing action needed",
        preheader: "Update billing to keep #{assigns.workspace} transactional email flowing.",
        title: "Payment action needed",
        paragraphs: [
          "We could not process the latest payment for #{assigns.workspace}.",
          "Update the billing details before the next retry to keep transactional email flowing."
        ],
        metrics: [
          {"Amount due", assigns.amount_due},
          {"Card", "Ending #{assigns.card_last4}"},
          {"Next retry", assigns.retry_at}
        ],
        cta: {"Update billing", "https://app.atlasdesk.example/billing/payment-methods"},
        note:
          "Your workspace remains active during the retry window. Some outbound notifications may pause if the balance remains unpaid."
      })
    )
    |> Message.text_body(
      "Payment action needed. Amount due: #{assigns.amount_due} (card ending #{assigns.card_last4}). The next automatic retry runs #{assigns.retry_at}."
    )
    |> Message.put_function(:payment_failed)
  end
end
