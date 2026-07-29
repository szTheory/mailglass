defmodule MailglassDemoWeb.Mailers.OperationsMailer do
  use Mailglass.Mailable, stream: :operational

  alias Mailglass.Message
  alias MailglassDemoWeb.Mailers.AtlasDeskEmail

  def preview_props do
    [
      usage_alert: %{
        recipient: AtlasDeskEmail.account_address("ops"),
        workspace: AtlasDeskEmail.demo_account(),
        threshold: "85%",
        period: "June",
        projected_overage: "$38.00"
      },
      incident_update: %{
        recipient: AtlasDeskEmail.account_address("ops"),
        workspace: AtlasDeskEmail.demo_account(),
        incident_id: "INC-4421",
        status: "monitoring",
        impacted_feature: "Inbound routing trace",
        next_update: "15 minutes"
      }
    ]
  end

  def usage_alert(assigns) do
    new()
    |> Message.from({AtlasDeskEmail.brand(), "ops@atlasdesk.example"})
    |> Message.to(assigns.recipient)
    |> Message.subject("#{assigns.workspace} email usage reached #{assigns.threshold}")
    |> Message.html_body(
      AtlasDeskEmail.html(%{
        eyebrow: "Usage alert",
        preheader: "#{assigns.workspace} has used #{assigns.threshold} of its email allowance.",
        title: "Usage threshold reached",
        paragraphs: [
          "#{assigns.workspace} has used #{assigns.threshold} of its #{assigns.period} transactional email allowance.",
          "Review the current pace before the account crosses its included email volume."
        ],
        metrics: [
          {"Allowance used", assigns.threshold},
          {"Period", assigns.period},
          {"Projected overage", assigns.projected_overage}
        ],
        cta: {"Review usage", "https://app.atlasdesk.example/settings/usage"},
        note:
          "You can review recent message volume or adjust your plan before the end of the cycle."
      })
    )
    |> Message.text_body(
      "#{assigns.workspace} used #{assigns.threshold} of #{assigns.period} email allowance.\n\nProjected overage this cycle: #{assigns.projected_overage}."
    )
    |> Message.put_function(:usage_alert)
  end

  def incident_update(assigns) do
    new()
    |> Message.from({"AtlasDesk Status", "status@atlasdesk.example"})
    |> Message.to(assigns.recipient)
    |> Message.subject("INC-4421 is monitoring")
    |> Message.html_body(
      AtlasDeskEmail.html(%{
        eyebrow: "Incident update",
        preheader: "#{assigns.incident_id} is now #{assigns.status}.",
        title: "Incident #{assigns.status}",
        paragraphs: [
          "#{assigns.incident_id} is now #{assigns.status} for #{assigns.workspace}. Delivery monitoring remains active.",
          "Our team is watching #{assigns.impacted_feature} and will post another update in #{assigns.next_update}."
        ],
        metrics: [
          {"Incident", assigns.incident_id},
          {"Account", assigns.workspace},
          {"Status", assigns.status},
          {"Impacted feature", assigns.impacted_feature},
          {"Next update", assigns.next_update}
        ],
        cta:
          {"Open status page", "https://status.atlasdesk.example/incidents/#{assigns.incident_id}"}
      })
    )
    |> Message.text_body(
      "#{assigns.incident_id} is now #{assigns.status} for #{assigns.workspace}. Impacted feature: #{assigns.impacted_feature}. Next update in #{assigns.next_update}."
    )
    |> Message.put_function(:incident_update)
  end
end
