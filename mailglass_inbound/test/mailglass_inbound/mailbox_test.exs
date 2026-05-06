defmodule MailglassInbound.MailboxTest do
  use ExUnit.Case, async: true

  alias MailglassInbound.InboundMessage
  alias MailglassInbound.Mailbox

  defmodule AcceptMailbox do
    @behaviour MailglassInbound.Mailbox

    @impl true
    def process(_message), do: :accept
  end

  defmodule IgnoreMailbox do
    @behaviour MailglassInbound.Mailbox

    @impl true
    def process(_message), do: :ignore
  end

  defmodule RejectMailbox do
    @behaviour MailglassInbound.Mailbox

    @impl true
    def process(_message), do: {:reject, :invalid_sender}
  end

  defmodule BounceMailbox do
    @behaviour MailglassInbound.Mailbox

    @impl true
    def process(_message), do: {:bounce, :mailbox_full}
  end

  test "mailbox contract exposes one process callback over the inbound message struct" do
    message = %InboundMessage{tenant_id: "tenant_123"}

    assert :accept = AcceptMailbox.process(message)
    assert :ignore = IgnoreMailbox.process(message)
    assert {:reject, :invalid_sender} = RejectMailbox.process(message)
    assert {:bounce, :mailbox_full} = BounceMailbox.process(message)
  end

  test "only the locked mailbox outcomes are treated as valid results" do
    assert Mailbox.valid_outcome?(:accept)
    assert Mailbox.valid_outcome?(:ignore)
    assert Mailbox.valid_outcome?({:reject, :invalid_sender})
    assert Mailbox.valid_outcome?({:bounce, :mailbox_full})

    refute Mailbox.valid_outcome?(:retry)
    refute Mailbox.valid_outcome?({:accept, :later})
    refute Mailbox.valid_outcome?({:reject})
    refute Mailbox.valid_outcome?(%{status: :accept})
  end
end
