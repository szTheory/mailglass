defmodule Mailglass.Outbound.EnvelopeTest do
  use ExUnit.Case, async: true

  alias Mailglass.Message
  alias Mailglass.Outbound.Envelope

  @tag phase_150_task: "t150_01_01"
  test "a prepared message has a deterministic private envelope round trip" do
    message =
      Swoosh.Email.new()
      |> Swoosh.Email.from({"Mailglass", "sender@example.com"})
      |> Swoosh.Email.to({"Recipient", "recipient@example.com"})
      |> Swoosh.Email.subject("Private subject")
      |> Swoosh.Email.text_body("plain body")
      |> Swoosh.Email.html_body("<p>html body</p>")
      |> then(&Message.build(&1,
        tenant_id: "tenant-150",
        mailable: __MODULE__,
        tags: ["welcome", "welcome"],
        metadata: %{source: "test"}
      ))

    assert {:ok, envelope} = Envelope.dump(message, adapter_ref: "primary")
    assert Envelope.digest(envelope) == Envelope.digest(envelope)
    assert {:ok, restored} = Envelope.load(envelope)
    assert restored.swoosh_email.subject == "Private subject"
    assert restored.swoosh_email.to == [{"Recipient", "recipient@example.com"}]
    assert restored.tags == ["welcome", "welcome"]
  end
end
