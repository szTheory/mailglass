defmodule MailglassDemoWeb.Mailers.OperationsMailer do
  use Mailglass.Mailable, stream: :operational

  alias Mailglass.Message

  def preview_props do
    [
      usage_alert: %{
        recipient: "ops@northstar-ops.example",
        workspace: "Northstar Ops",
        threshold: "85%",
        period: "June"
      },
      incident_update: %{
        recipient: "ops@northstar-ops.example",
        incident_id: "INC-4421",
        status: "monitoring"
      }
    ]
  end

  def usage_alert(assigns) do
    new()
    |> Message.from({"Northstar Ops", "ops@demo.mailglass.local"})
    |> Message.to(assigns.recipient)
    |> Message.subject("#{assigns.workspace} email usage reached #{assigns.threshold}")
    |> Message.html_body("""
    <h1>Usage threshold reached</h1>
    <p>#{assigns.workspace} has used #{assigns.threshold} of its #{assigns.period} transactional email allowance.</p>
    """)
    |> Message.text_body(
      "#{assigns.workspace} used #{assigns.threshold} of #{assigns.period} email allowance."
    )
    |> Message.put_function(:usage_alert)
  end

  def incident_update(assigns) do
    new()
    |> Message.from({"Northstar Status", "status@demo.mailglass.local"})
    |> Message.to(assigns.recipient)
    |> Message.subject("#{assigns.incident_id} is #{assigns.status}")
    |> Message.html_body("""
    <h1>Incident #{assigns.status}</h1>
    <p>#{assigns.incident_id} is now #{assigns.status}. Delivery monitoring remains active.</p>
    """)
    |> Message.text_body("#{assigns.incident_id} is now #{assigns.status}.")
    |> Message.put_function(:incident_update)
  end
end
