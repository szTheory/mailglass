defmodule MailglassDemoWeb.Inbound.SupportMailbox do
  @behaviour MailglassInbound.Mailbox

  @impl true
  def process(message) do
    cond do
      String.contains?(String.downcase(message.subject || ""), "refund") ->
        {:bounce, :mailbox_full}

      String.contains?(String.downcase(message.subject || ""), "spam") ->
        {:reject, :spam}

      true ->
        :accept
    end
  end
end
