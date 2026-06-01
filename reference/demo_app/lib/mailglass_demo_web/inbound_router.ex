defmodule MailglassDemoWeb.InboundRouter do
  use MailglassInbound.Router

  alias MailglassDemoWeb.Inbound.SupportMailbox

  route(SupportMailbox, recipient: "support@demo.mailglass.local")
  route(SupportMailbox, subject: ~r/\[(billing|support|refund)\]/i)
  route(SupportMailbox, headers: [{"x-demo-priority", "high"}])
end
