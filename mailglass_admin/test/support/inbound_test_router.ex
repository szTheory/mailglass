defmodule MailglassAdmin.TestSupport.InboundTestMailbox do
  @moduledoc false
  # Minimal inbound mailbox so the test inbound router below can declare routes.
  # Only loaded in :test, where mailglass_inbound is present via the path dep.
  @behaviour MailglassInbound.Mailbox

  @impl true
  def process(_message), do: :accept
end

defmodule MailglassAdmin.TestSupport.InboundTestRouter do
  @moduledoc false
  # Synthetic adopter inbound router threaded into the operator dashboard via the
  # `:inbound_router` opt (CONTEXT D-48-07). Declares one route of each matcher
  # kind (recipient / subject / header) so Wave 2's routing-trace card has real
  # routes to reflect through `__mailglass_inbound_routes__/0`. Loaded only in
  # :test, where mailglass_inbound is present via the path dep.
  use MailglassInbound.Router

  alias MailglassAdmin.TestSupport.InboundTestMailbox

  route InboundTestMailbox, recipient: "support@example.com"
  route InboundTestMailbox, subject: ~r/^\[billing\]/
  route InboundTestMailbox, headers: [{"x-priority", "high"}]
end
