defmodule MailglassDemoWeb.Mailers.OperationsMailer do
  use Mailglass.Mailable, stream: :operational

  alias Mailglass.Message

  def preview_props do
    [
      usage_alert: %{
        recipient: "ops@northstar-ops.example",
        workspace: "Northstar Ops",
        threshold: "85%",
        period: "June",
        projected_overage: "$38.00"
      },
      incident_update: %{
        recipient: "ops@northstar-ops.example",
        incident_id: "INC-4421",
        status: "monitoring",
        impacted_feature: "Inbound routing trace",
        next_update: "15 minutes"
      }
    ]
  end

  def usage_alert(assigns) do
    new()
    |> Message.from({"Northstar Ops", "ops@demo.mailglass.local"})
    |> Message.to(assigns.recipient)
    |> Message.subject("Northstar Ops email usage reached 85%")
    |> Message.html_body("""
    <h1>Usage threshold reached</h1>
    <p>#{assigns.workspace} has used #{assigns.threshold} of its #{assigns.period} transactional email allowance.</p>
    <p>Projected overage this cycle: #{assigns.projected_overage}.</p>
    """)
    |> Message.text_body(
      "#{assigns.workspace} used #{assigns.threshold} of #{assigns.period} email allowance. Projected overage this cycle: #{assigns.projected_overage}."
    )
    |> Message.put_function(:usage_alert)
  end

  def incident_update(assigns) do
    new()
    |> Message.from({"Northstar Status", "status@demo.mailglass.local"})
    |> Message.to(assigns.recipient)
    |> Message.subject("INC-4421 is monitoring")
    |> Message.html_body("""
    <h1>Incident #{assigns.status}</h1>
    <p>#{assigns.incident_id} is now #{assigns.status}. Delivery monitoring remains active.</p>
    <p>Impacted feature: #{assigns.impacted_feature}. Next update in #{assigns.next_update}.</p>
    """)
    |> Message.text_body(
      "#{assigns.incident_id} is now #{assigns.status}. Impacted feature: #{assigns.impacted_feature}. Next update in #{assigns.next_update}."
    )
    |> Message.put_function(:incident_update)
  end
end
